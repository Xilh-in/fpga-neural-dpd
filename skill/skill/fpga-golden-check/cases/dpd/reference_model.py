"""Float and integer references reconstructed from the supplied dpd_ip_v1 RTL."""
from pathlib import Path
import json
import numpy as np

HERE = Path(__file__).resolve().parent


def signed(value, width):
    return (np.asarray(value, dtype=np.int64) + (1 << (width - 1))) % (1 << width) - (1 << (width - 1))


def cut(value, shift, width):
    return np.clip(np.asarray(value, dtype=np.int64) >> shift, -(1 << (width - 1)), (1 << (width - 1)) - 1)


def load_parameters(path):
    p = np.array(json.loads(Path(path).read_text(encoding='utf-8')), dtype=np.int64)
    if p.shape != (576,) or p.min() < -32768 or p.max() > 32767:
        raise ValueError('576 signed 16-bit parameters required')
    a = p[:308].reshape(7, 44)
    b = p[308:560].reshape(7, 36)
    c = p[560:].reshape(8, 2)
    return dict(raw=p, w1i=a[:, :21], b1i=a[:, 21], w1q=a[:, 22:43], b1q=a[:, 43],
                centers=b[:, :9], theta=b[:, 9:18], w2i=b[:, 18:27], w2q=b[:, 27:36],
                w3i=c[:7, 0], w3q=c[:7, 1], b3i=c[7, 0], b3q=c[7, 1])


def delayed_taps(l1):
    # Training and grad_0_[iq]_L: centre j uses L1[n+j-4].
    extended = np.pad(l1, ((4, 4), (0, 0), (0, 0)))
    return np.stack([extended[j:j + len(l1)] for j in range(9)], axis=2)


def cordic_abs(x, y):
    # DW=16, EPC=9: x[0] plus eight vectoring iterations, shifts 0..7.
    x = signed(np.abs(x), 16) * 19898
    y = signed(np.abs(y), 16) * 19898
    for shift in range(8):
        old_x, old_y = x, y
        direction = np.where(old_y < 0, -1, 1)
        x = signed(old_x + direction * (old_y >> shift), 32)
        y = signed(old_y - direction * (old_x >> shift), 32)
    return x >> 15


def cordic_exp(value):
    # Constants and all register widths are copied from cordic_exp.v (DW25/NW7).
    product = value * int('01011100010101010001', 2)
    magnitude = np.abs(product) >> 36
    integer_part = ((magnitude * int('01011000101110010000', 2)) >> 1) & ((1 << 25) - 1)
    integer_part = signed(integer_part, 25)
    remainder = signed(np.where(value < 0, value + integer_part, value - integer_part), 25)
    x = np.full(value.shape, int('0000001001101010001111010', 2), dtype=np.int64)
    y = np.zeros(value.shape, dtype=np.int64)
    z = remainder
    angles = [int(a, 2) for a in (
        '100011001001111101', '010000010110001010', '001000000010101100',
        '000100000000010101', '000100000000010101', '000010000000000010',
        '000001000000000000', '000000100000000000', '000000010000000000',
        '000000001000000000', '000000000100000000', '000000000010000000',
        '000000000001000000', '000000000000100000', '000000000000100000',
        '000000000000010000', '000000000000001000')]
    shifts = [1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 13, 14, 15]
    for shift, angle in zip(shifts, angles):
        direction = np.where(z < 0, -1, 1)
        old_x, old_y = x, y
        x = signed(old_x + direction * (old_y >> shift), 25)
        y = signed(old_y + direction * (old_x >> shift), 25)
        z = signed(z - direction * angle, 25)
    result = signed(x + y, 25)
    # All NL exponents are nonpositive; retain the positive branch for completeness.
    return signed(np.where(value < 0, result >> magnitude, result << magnitude), 25)


def fixed_reference(iq, p):
    n = len(iq)
    extended = np.pad(iq, ((20, 20), (0, 0)))
    windows = np.stack([extended[2 * j:2 * j + n] for j in range(21)], axis=1)
    l1_long_i = windows[:, :, 0] @ p['w1i'].T - windows[:, :, 1] @ p['w1q'].T + (p['b1i'] << 15)
    l1_long_q = windows[:, :, 0] @ p['w1q'].T + windows[:, :, 1] @ p['w1i'].T + (p['b1q'] << 15)
    l1_long = np.stack((l1_long_i, l1_long_q), axis=-1)
    l1 = cut(l1_long, 15, 16)
    radius = cordic_abs(l1[:, :, 0], l1[:, :, 1])
    distance = radius[:, :, None] - p['centers']
    square = cut(distance * distance, 7, 25)
    exp_input = cut(-square * np.abs(p['theta']), 13, 25)
    radial = cordic_exp(exp_input)
    taps = delayed_taps(l1)
    grad_i = cut(taps[:, :, :, 0] * p['w2i'], 5, 25)
    grad_q = cut(taps[:, :, :, 1] * p['w2q'], 5, 25)
    product_i = cut(radial * grad_i, 16, 25)
    product_q = cut(radial * grad_q, 16, 25)
    l2_long = np.stack((product_i.sum(axis=2), product_q.sum(axis=2)), axis=-1)
    l2 = cut(l2_long, 9, 16)
    l3_i = l2[:, :, 0] @ p['w3i'] - l2[:, :, 1] @ p['w3q'] + (p['b3i'] << 14)
    l3_q = l2[:, :, 0] @ p['w3q'] + l2[:, :, 1] @ p['w3i'] + (p['b3q'] << 14)
    l3_long = np.stack((l3_i, l3_q), axis=-1)
    return dict(output=cut(l3_long, 12, 16), preclip=l3_long >> 12, accumulator=l3_long,
                l1=l1, l1_long=l1_long, radius=radius, square=square, exp_input=exp_input,
                radial=radial, grad=np.stack((grad_i, grad_q), axis=-1),
                products=np.stack((product_i, product_q), axis=-1), l2=l2, l2_long=l2_long)


def float_reference(iq, p):
    x = (iq[:, 0] + 1j * iq[:, 1]) / 32768
    extended = np.pad(x, (20, 20))
    windows = np.stack([extended[2 * j:2 * j + len(iq)] for j in range(21)], axis=1)
    l1 = windows @ ((p['w1i'] + 1j * p['w1q']) / 8192).T + (p['b1i'] + 1j * p['b1q']) / 8192
    radial = np.exp(-np.abs(p['theta'] / 4096) * (np.abs(l1[:, :, None]) - p['centers'] / 8192)**2)
    taps = delayed_taps(np.stack((l1.real, l1.imag), axis=-1))
    l2 = np.sum(radial * (taps[:, :, :, 0] * p['w2i'] / 8192 +
                          1j * taps[:, :, :, 1] * p['w2q'] / 8192), axis=2)
    l3 = l2 @ ((p['w3i'] + 1j * p['w3q']) / 8192) + (p['b3i'] + 1j * p['b3q']) / 8192
    return dict(output=np.stack((l3.real, l3.imag), axis=-1) * 32768,
                l1=l1, l2=l2)


