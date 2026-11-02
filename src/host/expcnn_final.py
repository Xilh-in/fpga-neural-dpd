"""7 分支 / 21 点 dilation=2 / 9 中心 expcnn，保持原 MAT 参数格式。

使用 NumPy 实现，训练在 expcnn_bp_adam.py，不依赖 PyTorch/CUDA。
forward 接收 Q1.15 浮点；predict 接收/返回 ADC/DAC 原始计数。
L1 与 L2 总上下文各 24 点；浮点模型不模拟硬件内部限幅和 CORDIC。
"""
import numpy as np
from scipy.io import loadmat, savemat
from data_process import (complex_vector, validate_parameters, pack_parameters,
                          unpack_parameters, IQ_SCALE)

CONTEXT = 24


def input_windows(x):
    padded = np.pad(x, (20, 20))
    return np.stack([padded[2*j:2*j + len(x)] for j in range(21)], axis=1)


def branch_taps(l1):
    padded = np.pad(l1, ((4, 4), (0, 0)))
    return np.stack([padded[j:j + len(l1)] for j in range(9)], axis=2)


class expcnn:
    def __init__(self, parameters=None, seed=48):
        if parameters is None:
            rng = np.random.default_rng(seed)
            w1 = (rng.normal(0, .015, (7, 21)) + 1j*rng.normal(0, .015, (7, 21)))
            w1[:, 10] += np.linspace(.6, 1.2, 7)
            parameters = dict(L1_w=w1, L1_bias=np.zeros((1, 7), complex),
                              L2_c=np.tile(np.linspace(0, 1.5, 9), (7, 1)),
                              L2_theta=np.full((7, 9), 1.0),
                              L2_w=rng.normal(0, .025, (14, 9)),
                              L3_w=(rng.normal(0, .04, (7, 1))
                                    + 1j*rng.normal(0, .04, (7, 1))),
                              L3_bias=np.zeros((1, 1), complex))
        validate_parameters(parameters)
        complex_names = {'L1_w', 'L1_bias', 'L3_w', 'L3_bias'}
        self.parameters = {k: np.array(v, dtype=np.complex128 if k in complex_names
                                      else np.float64, copy=True)
                           for k, v in parameters.items() if k in complex_names
                           or k in ('L2_c', 'L2_theta', 'L2_w')}

    @classmethod
    def load(cls, path):
        return cls(loadmat(path))

    def save(self, path):
        """只有显式调用时才保存 MAT，不创建任何日志或图片。"""
        savemat(str(path), self.parameters)

    def forward(self, x, cache=False):
        x = complex_vector(x)
        p = self.parameters
        windows = input_windows(x)
        l1 = windows @ p['L1_w'].T + p['L1_bias']
        radius = abs(l1)
        delta = radius[:, :, None] - p['L2_c']
        radial = np.exp(-abs(p['L2_theta']) * delta**2)
        taps = branch_taps(l1)
        weighted = taps.real * p['L2_w'][::2] + 1j*taps.imag*p['L2_w'][1::2]
        l2 = np.sum(radial * weighted, axis=2)
        out = l2 @ p['L3_w'][:, 0] + p['L3_bias'][0, 0]
        if cache:
            return out, dict(windows=windows, l1=l1, radius=radius, delta=delta,
                             radial=radial, taps=taps, weighted=weighted, l2=l2)
        return out

    def predict(self, raw_iq, quantized_parameters=False):
        if quantized_parameters:
            model = expcnn(unpack_parameters(pack_parameters(self.parameters)))
            return model.predict(raw_iq)
        return self.forward(complex_vector(raw_iq) / IQ_SCALE) * IQ_SCALE

    def project_parameters(self):
        """将训练参数约束在可下发范围；此处不量化梯度。"""
        for name, a in self.parameters.items():
            bits = 12 if name == 'L2_theta' else 13
            low, high = -32768 / 2**bits, 32767 / 2**bits
            np.clip(a.real, low, high, out=a.real)
            if np.iscomplexobj(a):
                np.clip(a.imag, low, high, out=a.imag)


# %% 当前 dpd_ip_v1 定点前向，供接收 model_out 后逐点核对
# 对应项目现有 RTL；未来改位宽/CORDIC 常数/分支结构时应同步更新。
def _signed(value, width):
    return (np.asarray(value, dtype=np.int64) + (1 << (width - 1))) % (1 << width) - (1 << (width - 1))


def _cut(value, shift, width):
    return np.clip(np.asarray(value, dtype=np.int64) >> shift,
                   -(1 << (width - 1)), (1 << (width - 1)) - 1)


def _cordic_abs(x, y):
    x, y = _signed(abs(x), 16) * 19898, _signed(abs(y), 16) * 19898
    for shift in range(8):
        old_x, old_y = x, y
        direction = np.where(old_y < 0, -1, 1)
        x = _signed(old_x + direction * (old_y >> shift), 32)
        y = _signed(old_y - direction * (old_x >> shift), 32)
    return x >> 15


def _cordic_exp(value):
    product = value * int('01011100010101010001', 2)
    magnitude = abs(product) >> 36
    integer_part = ((magnitude * int('01011000101110010000', 2)) >> 1) & ((1 << 25) - 1)
    integer_part = _signed(integer_part, 25)
    remainder = _signed(np.where(value < 0, value + integer_part, value - integer_part), 25)
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
    for shift, angle in zip([1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 13, 14, 15], angles):
        direction = np.where(z < 0, -1, 1)
        old_x, old_y = x, y
        x = _signed(old_x + direction * (old_y >> shift), 25)
        y = _signed(old_y + direction * (old_x >> shift), 25)
        z = _signed(z - direction * angle, 25)
    result = _signed(x + y, 25)
    return _signed(np.where(value < 0, result >> magnitude, result << magnitude), 25)


def predict_fixed(raw_iq, parameter_values):
    """输入原始 int16 计数及 576 个整数；返回计数输出、L1/L2 及限幅前输出。
    输出按中心样本编号，未附加时钟延迟；与捕获 node5/6 的偏移在上位机显式指定。
    """
    x = complex_vector(raw_iq)
    if np.any(x.real != np.floor(x.real)) or np.any(x.imag != np.floor(x.imag)):
        raise ValueError('定点参考输入必须是整数 IQ 计数')
    if np.any(abs(x.real) > 32768) or np.any(abs(x.imag) > 32768) or np.any(x.real > 32767) or np.any(x.imag > 32767):
        raise ValueError('定点参考输入超出 int16 范围')
    unpack_parameters(parameter_values)  # 验证长度和范围
    p = np.asarray(parameter_values, dtype=np.int64)
    a, b, c = p[:308].reshape(7, 44), p[308:560].reshape(7, 36), p[560:].reshape(8, 2)
    windows = input_windows(x)
    xi, xq = windows.real.astype(np.int64), windows.imag.astype(np.int64)
    l1i = xi @ a[:, :21].T - xq @ a[:, 22:43].T + (a[:, 21] << 15)
    l1q = xi @ a[:, 22:43].T + xq @ a[:, :21].T + (a[:, 43] << 15)
    l1 = np.stack((_cut(l1i, 15, 16), _cut(l1q, 15, 16)), axis=-1)
    radius = _cordic_abs(l1[:, :, 0], l1[:, :, 1])
    distance = radius[:, :, None] - b[:, :9]
    square = _cut(distance * distance, 7, 25)
    exp_input = _cut(-square * abs(b[:, 9:18]), 13, 25)
    radial = _cordic_exp(exp_input)
    taps = np.stack((branch_taps(l1[:, :, 0]), branch_taps(l1[:, :, 1])), axis=-1)
    gi = _cut(taps[:, :, :, 0] * b[:, 18:27], 5, 25)
    gq = _cut(taps[:, :, :, 1] * b[:, 27:36], 5, 25)
    long_i = _cut(radial * gi, 16, 25).sum(axis=2)
    long_q = _cut(radial * gq, 16, 25).sum(axis=2)
    l2 = np.stack((_cut(long_i, 9, 16), _cut(long_q, 9, 16)), axis=-1)
    l3i = l2[:, :, 0] @ c[:7, 0] - l2[:, :, 1] @ c[:7, 1] + (c[7, 0] << 14)
    l3q = l2[:, :, 0] @ c[:7, 1] + l2[:, :, 1] @ c[:7, 0] + (c[7, 1] << 14)
    out = _cut(l3i, 12, 16) + 1j * _cut(l3q, 12, 16)
    return dict(output=out, preclip=(l3i >> 12) + 1j*(l3q >> 12), l1=l1, l2=l2,
                l2_preclip=np.stack((long_i >> 9, long_q >> 9), axis=-1))
