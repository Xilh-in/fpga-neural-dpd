#!/usr/bin/env python3
"""Check a declared no-OS/BSP SPI mapping; never patch code or access hardware."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


class InputError(ValueError):
    """An input is malformed or beyond this checker's supported syntax."""


def integer(value: object, field: str) -> int:
    if isinstance(value, bool):
        raise InputError(f"{field}: boolean is not an integer")
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        text = value.strip()
        if re.fullmatch(r"0[xX][0-9a-fA-F]+", text):
            return int(text, 16)
        if re.fullmatch(r"[0-9]+", text):
            return int(text, 10)
    raise InputError(f"{field}: expected an integer or a decimal/hex integer string")


def required(obj: dict, name: str) -> object:
    if name not in obj:
        raise InputError(f"missing field: {name}")
    return obj[name]


def read_defines(path: Path) -> dict[str, list[str]]:
    """Read object-like defines without selecting C preprocessor branches."""
    text = path.read_text(encoding="utf-8-sig")
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    result: dict[str, list[str]] = {}
    for line in text.splitlines():
        match = re.match(r"\s*#\s*define\s+([A-Za-z_]\w*)[ \t]+(.+)", line)
        if match:
            value = match[2].split("//", 1)[0].strip()
            if value not in result.setdefault(match[1], []):
                result[match[1]].append(value)
    return result


def resolve_define(defines: dict[str, list[str]], name: str,
                   trail: frozenset[str] = frozenset()) -> int:
    if name in trail:
        raise InputError(f"cyclic macro alias: {name}")
    values = defines.get(name, [])
    if not values:
        raise InputError(f"macro not found: {name}")
    if len(values) != 1:
        raise InputError(f"macro has conflicting definitions; preprocess it first: {name}")
    value = values[0].strip()
    while value.startswith("(") and value.endswith(")"):
        value = value[1:-1].strip()
    if re.fullmatch(r"[A-Za-z_]\w*", value):
        return resolve_define(defines, value, trail | {name})
    match = re.fullmatch(r"(0[xX][0-9a-fA-F]+|[0-9]+)[uUlL]*", value)
    if not match:
        raise InputError(f"unsupported macro expression; use the C preprocessor: {name}={values[0]}")
    if len(match[1]) > 1 and match[1].startswith("0") and not match[1].lower().startswith("0x"):
        raise InputError(f"octal macro syntax is unsupported: {name}={values[0]}")
    return integer(match[1], name)


def validate_contract(config: object, bsp_defines: dict | None = None,
                      no_os_defines: dict | None = None) -> dict:
    if not isinstance(config, dict):
        raise InputError("config must be a JSON object")
    if integer(required(config, "schema_version"), "schema_version") != 1:
        raise InputError("unsupported schema_version")
    sdt = required(config, "sdt")
    if not isinstance(sdt, bool):
        raise InputError("sdt must be true or false, checked against the actual compiler command")
    limit = integer(required(config, "max_bus_id"), "max_bus_id")
    selected = integer(required(config, "selected_bus_id"), "selected_bus_id")
    kind = required(config, "lookup_argument_kind")
    if limit < 0:
        raise InputError("max_bus_id must be nonnegative")
    buses = required(config, "buses")
    if not isinstance(buses, list) or not buses:
        raise InputError("buses must be a nonempty list")
    issues: list[dict] = []

    def issue(code: str, message: str) -> None:
        issues.append({"code": code, "message": message})

    expected_kind = "base_address" if sdt else "device_id"
    if kind != expected_kind:
        issue("LOOKUP_KIND_MISMATCH", f"declared BSP branch expects {expected_kind}, got {kind}")
    if not 0 <= selected <= limit:
        issue("BUS_ID_OUT_OF_RANGE", f"no-OS bus index {selected} is outside 0..{limit}; do not pass an MMIO address here")
    if no_os_defines is not None:
        actual_limit = resolve_define(no_os_defines, "SPI_MAX_BUS_NUMBER")
        if actual_limit != limit:
            issue("NO_OS_BUS_LIMIT_MISMATCH", f"config limit {limit} differs from header limit {actual_limit}")
    by_id: dict[int, dict] = {}
    addresses: set[int] = set()
    for index, bus in enumerate(buses):
        if not isinstance(bus, dict):
            raise InputError(f"buses[{index}] must be an object")
        bus_id = integer(required(bus, "logical_id"), f"buses[{index}].logical_id")
        address = integer(required(bus, "base_address"), f"buses[{index}].base_address")
        clock = integer(required(bus, "input_clock_hz"), f"buses[{index}].input_clock_hz")
        if not 0 <= bus_id <= limit:
            issue("MAPPING_ID_OUT_OF_RANGE", f"mapped bus index {bus_id} is outside 0..{limit}")
        if bus_id in by_id:
            issue("DUPLICATE_BUS_ID", f"bus index {bus_id} has more than one mapping")
        if not 0 < address <= 0xFFFFFFFF:
            issue("INVALID_BASE_ADDRESS", f"bus {bus_id}: expected an explicit nonzero 32-bit MMIO address")
        elif address % 4:
            issue("UNALIGNED_BASE_ADDRESS", f"bus {bus_id}: base address is not 32-bit aligned")
        if address in addresses:
            issue("DUPLICATE_BASE_ADDRESS", f"multiple logical buses map to {address:#x}; review the declared PS-controller mapping")
        if clock <= 0:
            issue("INVALID_INPUT_CLOCK", f"bus {bus_id}: input clock must be positive")
        if bsp_defines is not None:
            macro = required(bus, "base_address_macro")
            if not isinstance(macro, str) or not re.fullmatch(r"[A-Za-z_]\w*", macro):
                raise InputError("base_address_macro must be a C identifier")
            actual = resolve_define(bsp_defines, macro)
            if actual != address:
                issue("BSP_BASEADDR_MISMATCH", f"bus {bus_id}: config {address:#x} differs from {macro}={actual:#x}")
        addresses.add(address)
        by_id[bus_id] = {"logical_id": bus_id, "base_address": hex(address),
                         "input_clock_hz": clock}
    if selected not in by_id:
        issue("UNMAPPED_BUS_ID", f"no declared controller for bus index {selected}")
    return {"schema_version": 1, "status": "FAIL" if issues else "PASS",
            "scope": "declared_configuration_only", "hardware_access": False,
            "source_call_path_verified": False, "sdt": sdt,
            "selected_mapping": by_id.get(selected), "issues": issues}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--bsp-header", type=Path)
    parser.add_argument("--no-os-spi-header", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(argv)
    try:
        config = json.loads(args.config.read_text(encoding="utf-8-sig"))
        bsp = read_defines(args.bsp_header) if args.bsp_header else None
        no_os = read_defines(args.no_os_spi_header) if args.no_os_spi_header else None
        result = validate_contract(config, bsp, no_os)
        text = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
        if args.report:
            args.report.write_text(text, encoding="utf-8")
        print(text, end="")
        return int(result["status"] != "PASS")
    except (OSError, UnicodeError, ValueError) as exc:
        print(json.dumps({"status": "INPUT_ERROR", "message": str(exc)},
                         ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
