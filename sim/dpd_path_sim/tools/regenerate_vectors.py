"""Optional: regenerate the cyclic golden vector. Not required to run Vivado."""
from pathlib import Path
import sys
import json
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from reference_model import load_parameters, fixed_reference

def write_words(path, values, width):
    mask = (1 << width) - 1
    path.write_text(''.join(f'{int(v) & mask:0{width // 4}x}\n' for v in values), encoding='ascii')

def pack_iq(values):
    return ((values[:, 1] & 65535) << 16) | (values[:, 0] & 65535)

def main():
    x = np.loadtxt(ROOT / 'input/tx_delay_1024.csv', delimiter=',', skiprows=1, dtype=np.int64)
    if x.shape != (1024, 2) or np.any(x < -32768) or np.any(x > 32767):
        raise ValueError('Need exactly 1024 signed-16 I/Q pairs')
    if len(set(map(tuple, x))) != 1024:
        raise ValueError('This scoreboard requires unique I/Q pairs for sample identification')
    p = load_parameters(ROOT / 'input/model_0216_0.json')
    # The DUT repeats a 1024-word frame. Supply real context across BOTH boundaries.
    y = fixed_reference(np.tile(x, (3, 1)), p)['output'][1024:2048]
    write_words(ROOT / 'simulation/samples.mem', pack_iq(x), 32)
    write_words(ROOT / 'simulation/coefficients.mem', p['raw'], 16)
    write_words(ROOT / 'simulation/expected_model.mem', pack_iq(y), 32)
    np.savetxt(ROOT / 'input/expected_periodic_model.csv', y, fmt='%d', delimiter=',', header='i,q', comments='')
    print('Generated 1024 input words, 576 coefficients, and 1024 cyclic golden model words.')

if __name__ == '__main__':
    main()
