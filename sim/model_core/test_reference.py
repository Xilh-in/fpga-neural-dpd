import unittest
from pathlib import Path
import numpy as np
from reference_model import load_parameters, fixed_reference, cut, signed

HERE = Path(__file__).resolve().parent


class ReferenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.x = np.loadtxt(HERE / 'input/tx_delay_1024.csv', delimiter=',', skiprows=1, dtype=np.int64)
        cls.y = np.loadtxt(HERE / 'input/model_out_1024.csv', delimiter=',', skiprows=1, dtype=np.int64)
        cls.z = np.loadtxt(HERE / 'input/tx_final_1024.csv', delimiter=',', skiprows=1, dtype=np.int64)
        cls.parameters = load_parameters(HERE / 'input/model_0216_0.json')
        cls.reference = fixed_reference(cls.x, cls.parameters)

    def test_full_valid_window_bit_exact(self):
        np.testing.assert_array_equal(self.reference['output'][24:1000], self.y[23:999])

    def test_clipping_is_actual_accumulator_overflow(self):
        actual = np.where(self.y[:, 1] == -32768)[0]
        expected = np.where(self.reference['accumulator'][24:1000, 1] < -(1 << 27))[0] + 23
        self.assertEqual(actual.tolist(), [120,121,348,548,549,550,551,590,591,592,593,594,608,707,708,709])
        np.testing.assert_array_equal(actual, expected)

    def test_final_output_identity(self):
        np.testing.assert_array_equal(self.x - self.y, self.z)

    def test_signed_cut_and_parameter_boundaries(self):
        np.testing.assert_array_equal(signed(np.array([32767,32768,65535]),16), [32767,-32768,-1])
        np.testing.assert_array_equal(cut(np.array([-134217729,-134217728,-1,0,134217727,134217728]),12,16),
                                      [-32768,-32768,-1,0,32767,32767])
        self.assertEqual(self.parameters['raw'].shape, (576,))
        self.assertEqual(int(self.parameters['w3i'][4]), -2613)
        self.assertEqual(int(self.parameters['w3q'][4]), 2392)


if __name__ == '__main__':
    unittest.main(verbosity=2)
