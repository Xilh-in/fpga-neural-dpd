import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from check_spi_contract import InputError, read_defines, resolve_define, validate_contract


class SpiContractTests(unittest.TestCase):
    def setUp(self):
        self.config = json.loads((ROOT / "examples/spi_mapping_valid.json").read_text())

    def codes(self, config=None, **kwargs):
        result = validate_contract(self.config if config is None else config, **kwargs)
        return {issue["code"] for issue in result["issues"]}

    def test_valid_sdt_mapping(self):
        result = validate_contract(self.config)
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(result["selected_mapping"]["base_address"], "0xe0006000")
        self.assertFalse(result["hardware_access"])
        self.assertFalse(result["source_call_path_verified"])

    def test_base_address_cannot_be_bus_index(self):
        self.config["selected_bus_id"] = "0xe0006000"
        self.assertIn("BUS_ID_OUT_OF_RANGE", self.codes())

    def test_unmapped_bus(self):
        self.config["selected_bus_id"] = 1
        self.assertEqual(self.codes(), {"UNMAPPED_BUS_ID"})

    def test_negative_bus_index(self):
        self.config["selected_bus_id"] = -1
        self.assertIn("BUS_ID_OUT_OF_RANGE", self.codes())

    def test_multiple_controllers(self):
        second = copy.deepcopy(self.config["buses"][0])
        second.update(logical_id=1, base_address="0xe0007000")
        self.config["buses"].append(second)
        self.config["selected_bus_id"] = 1
        self.assertFalse(self.codes())

    def test_duplicate_logical_index(self):
        second = copy.deepcopy(self.config["buses"][0])
        second["base_address"] = "0xe0007000"
        self.config["buses"].append(second)
        self.assertIn("DUPLICATE_BUS_ID", self.codes())

    def test_duplicate_base_address(self):
        second = copy.deepcopy(self.config["buses"][0])
        second["logical_id"] = 1
        self.config["buses"].append(second)
        self.assertIn("DUPLICATE_BASE_ADDRESS", self.codes())

    def test_base_address_range_and_alignment(self):
        for address, code in [(0, "INVALID_BASE_ADDRESS"),
                              (0x100000000, "INVALID_BASE_ADDRESS"),
                              (0xe0006001, "UNALIGNED_BASE_ADDRESS")]:
            with self.subTest(address=address):
                self.config["buses"][0]["base_address"] = address
                self.assertIn(code, self.codes())

    def test_input_clock_must_be_positive(self):
        self.config["buses"][0]["input_clock_hz"] = 0
        self.assertIn("INVALID_INPUT_CLOCK", self.codes())

    def test_boolean_is_not_bus_index(self):
        self.config["selected_bus_id"] = True
        with self.assertRaises(InputError):
            validate_contract(self.config)

    def test_sdt_flag_must_be_boolean(self):
        self.config["sdt"] = "true"
        with self.assertRaises(InputError):
            validate_contract(self.config)

    def test_lookup_kind_tracks_bsp_mode(self):
        self.config["lookup_argument_kind"] = "device_id"
        self.assertIn("LOOKUP_KIND_MISMATCH", self.codes())
        self.config["sdt"] = False
        self.assertFalse(self.codes())

    def test_missing_fields_and_empty_buses(self):
        for config in [{}, {**self.config, "buses": []}]:
            with self.subTest(config=config):
                with self.assertRaises(InputError):
                    validate_contract(config)

    def test_bsp_alias_and_no_os_header(self):
        bsp = read_defines(ROOT / "examples/example_bsp.h")
        no_os = read_defines(ROOT / "examples/example_no_os_spi.h")
        self.assertFalse(self.codes(bsp_defines=bsp, no_os_defines=no_os))

    def test_bsp_and_no_os_mismatches(self):
        bsp = {"XPAR_XSPIPS_0_BASEADDR": ["0xe0007000"]}
        no_os = {"SPI_MAX_BUS_NUMBER": ["4"]}
        self.assertEqual(self.codes(bsp_defines=bsp, no_os_defines=no_os),
                         {"BSP_BASEADDR_MISMATCH", "NO_OS_BUS_LIMIT_MISMATCH"})

    def test_unsupported_and_ambiguous_macros(self):
        cases = [{"A": ["0x10 + 0x20"]}, {"A": ["1", "2"]},
                 {"A": ["B"], "B": ["A"]}, {"A": ["010"]}, {}]
        for defines in cases:
            with self.subTest(defines=defines):
                with self.assertRaises(InputError):
                    resolve_define(defines, "A")

    def test_integer_macro_parentheses_suffix_and_comments(self):
        with tempfile.TemporaryDirectory() as directory:
            header = Path(directory) / "header.h"
            header.write_text("#define A (0xe0006000UL) /* example */\n#define B A // alias\n")
            self.assertEqual(resolve_define(read_defines(header), "B"), 0xe0006000)


if __name__ == "__main__":
    unittest.main()
