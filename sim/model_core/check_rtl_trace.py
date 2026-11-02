"""Validate the optional simulator trace against the independently computed Python values."""
import json
from pathlib import Path
import numpy as np
from reference_model import load_parameters, fixed_reference

HERE = Path(__file__).resolve().parent


def validate():
    path = HERE / 'simulation/rtl_trace.csv'
    if not path.exists():
        raise FileNotFoundError('rtl_trace.csv is absent: RTL simulation has not completed')
    trace = np.genfromtxt(path, delimiter=',', names=True, dtype=np.int64)
    x = np.loadtxt(HERE / 'input/tx_delay_1024.csv', delimiter=',', skiprows=1, dtype=np.int64)
    p = load_parameters(HERE / 'input/model_0216_0.json')
    expected = fixed_reference(x, p)
    centres = np.arange(24, 1000)
    best = []
    for delay in range(60, 71):
        rows = 80 + centres + delay
        actual = np.column_stack((trace['output_i'][rows], trace['output_q'][rows]))
        best.append((int(np.abs(actual - expected['output'][centres]).max()), delay))
    error, delay = min(best)
    assert error == 0, f'RTL/Python mismatch; best max error and latency: {error}, {delay}'
    assert delay == 64, f'Unexpected centre-to-output pipeline delay: {delay}'
    rows = 80 + centres + delay
    accumulator = np.column_stack((trace['acc_i'][rows], trace['acc_q'][rows]))
    np.testing.assert_array_equal(accumulator, expected['accumulator'][centres])
    assert np.all(trace['valid'][rows] == 1)
    for key, offset in (('l1', 23), ('l2', 60)):
        rows = 80 + centres + offset
        actual = np.stack([np.column_stack((trace[f'{key}_i{ch}'][rows], trace[f'{key}_q{ch}'][rows]))
                           for ch in range(7)], axis=1)
        np.testing.assert_array_equal(actual, expected[key][centres])
    report = dict(status='PASS', comparable_samples=len(centres), maximum_output_error=error,
                  centre_to_output_clock_index_difference=delay,
                  l1_l2_and_final_accumulator_match=True)
    (HERE / 'rtl_validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    return report


if __name__ == '__main__':
    print(json.dumps(validate(), indent=2))
