"""Optional independent audit of the CSVs emitted by the SystemVerilog TB."""
from pathlib import Path
import json
import sys
import numpy as np

ROOT = Path(__file__).resolve().parents[1]

def audit():
    t = np.genfromtxt(ROOT / 'simulation/path_trace.csv', names=True, delimiter=',', dtype=np.int64)
    c = np.genfromtxt(ROOT / 'simulation/cap_tx_model.csv', names=True, delimiter=',', dtype=np.int64)
    y = np.loadtxt(ROOT / 'input/expected_periodic_model.csv', skiprows=1, delimiter=',', dtype=np.int64)
    x = np.loadtxt(ROOT / 'input/tx_delay_1024.csv', skiprows=1, delimiter=',', dtype=np.int64)
    def pair(rows, prefix):
        value = np.column_stack((rows[prefix + '_i'], rows[prefix + '_q']))
        if np.any(value < -32768) or np.any(value > 32767):
            raise ValueError(prefix + ': CSV contains values outside signed16')
        return value
    if y.shape != (1024, 2) or x.shape != (1024, 2) or c.shape != (1024,):
        raise ValueError('Expected exactly 1024 vector and capture samples')
    counts = {}
    for phase in range(4):
        rows = t[t['phase'] == phase]
        counts[str(phase)] = len(rows)
        if len(rows) < (64 if phase == 3 else 1024):
            raise ValueError('Missing phase coverage: ' + str(phase))
        if phase == 3:
            np.testing.assert_array_equal(pair(rows, 'tx_final'), np.zeros((len(rows), 2), dtype=np.int64))
            continue
        k = rows['sample_index']
        if np.any(k < 0) or np.any(k >= 1024):
            raise ValueError('Invalid sample index')
        np.testing.assert_array_equal(pair(rows, 'tx_delay'), x[k])
        expected = x[k]
        if phase == 1:
            if len(set(k)) != 1024:
                raise ValueError('DPD phase does not cover all samples')
            np.testing.assert_array_equal(pair(rows, 'used_model'), y[k])
            expected = np.clip(x[k] - y[k], -32768, 32767)
        np.testing.assert_array_equal(pair(rows, 'tx_final'), expected)
    k = c['sample_index']
    if sorted(k.tolist()) != list(range(1024)):
        raise ValueError('Capture must cover the complete frame exactly once')
    np.testing.assert_array_equal(c['index'], np.arange(1024))
    np.testing.assert_array_equal(pair(c, 'tx'), x[k])
    np.testing.assert_array_equal(pair(c, 'model'), y[k])
    np.testing.assert_array_equal(pair(c, 'final'), np.clip(x[k] - y[k], -32768, 32767))
    return dict(status='PASS', phase_cycles=counts, captured_samples=1024, max_error_lsb=0)

if __name__ == '__main__':
    try:
        result = audit()
    except Exception as exc:
        result = dict(status='FAIL', error=str(exc))
    (ROOT / 'simulation/path_csv_validation.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result, indent=2))
    sys.exit(0 if result['status'] == 'PASS' else 1)
