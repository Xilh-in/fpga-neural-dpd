"""DPD 上位机数据处理：复数波形统一使用 ADC/DAC 原始计数。
依赖 numpy、scipy；仅画图时需要 matplotlib。导入时不读写文件。
"""
from pathlib import Path
import numpy as np
from scipy import signal
from scipy.io import loadmat

RAM_DEPTH = 17536
IQ_SCALE = 32768.0
PARAM_COUNT = 576


def complex_vector(values):
    x = np.asarray(values, dtype=np.complex128).reshape(-1)
    if not x.size or not np.isfinite(x).all():
        raise ValueError('波形必须是非空、有限的复数数组')
    return x


def quantize_iq(values):
    """实、虚部分别向下取整并限幅；返回复数形式的 int16 计数。"""
    x = complex_vector(values)
    return (np.clip(np.floor(x.real), -32768, 32767)
            + 1j * np.clip(np.floor(x.imag), -32768, 32767))


def iq_bytes(values):
    x = complex_vector(values)
    if np.any(x != quantize_iq(x)):
        raise ValueError('发送值必须已量化为 int16 计数，请先调用 quantize_iq')
    return np.column_stack((x.real, x.imag)).astype('<i2').tobytes()


def bytes_iq(payload):
    if len(payload) % 4:
        raise ValueError('IQ 字节数必须是 4 的整数倍')
    a = np.frombuffer(payload, dtype='<i2').reshape(-1, 2).astype(np.float64)
    return a[:, 0] + 1j * a[:, 1]


def load_tx(path, key='source', gain=0.6, units='counts', taper=0):
    """填满当前 RTL 的 17536 点循环 RAM，不按峰值归一化。
    本工程 source.mat 已是 int16 量级，units='counts'。
    只有文件确为 Q1.15 浮点时才选 units='normalized'。
    taper=0 不改首尾；taper=256 则用 Hann 窗处理首尾各 256 点。
    """
    path = Path(path)
    data = loadmat(path)
    if key not in data:
        raise KeyError(f'{path.name} 没有变量 {key!r}')
    x = complex_vector(data[key])
    if len(x) < RAM_DEPTH:
        raise ValueError(f'当前 RTL 循环长度固定 {RAM_DEPTH}，输入点数不足')
    if units not in ('counts', 'normalized') or not np.isfinite(gain) or gain <= 0:
        raise ValueError('检查 units 和正数 gain')
    x = x[:RAM_DEPTH].copy() * gain * (IQ_SCALE if units == 'normalized' else 1)
    if not isinstance(taper, int) or not 0 <= taper <= RAM_DEPTH // 2:
        raise ValueError('taper 必须为有效的窗沿点数')
    if taper:
        window = signal.windows.hann(2 * taper)
        x[:taper] *= window[:taper]
        x[-taper:] *= window[taper:]
    clipped = np.count_nonzero((x.real < -32768) | (x.real >= 32768))
    clipped += np.count_nonzero((x.imag < -32768) | (x.imag >= 32768))
    if clipped:
        raise ValueError(f'TX 有 {clipped} 个分量超量程，请降低 gain')
    return quantize_iq(x)


def align_signals(reference, received, max_lag=256, compensate_gain=True):
    """FFT 相关后裁去不重叠边缘，不用 roll 伪造环绕样本。
    lag>0 表示 received 晚到；gain 乘在 received 上。
    返回 reference_valid, received_valid, lag, gain。
    """
    x, y = complex_vector(reference), complex_vector(received)
    if x.size != y.size or max_lag < 0 or x.size < 64:
        raise ValueError('对齐信号须等长且至少 64 点；max_lag 须非负')
    if not np.any(abs(x)) or not np.any(abs(y)):
        raise ValueError('采样全零，先检查 TX_VLD、通道和接收链路')
    cor = signal.correlate(y - y.mean(), x - x.mean(), method='fft')
    lags = signal.correlation_lags(y.size, x.size)
    candidates = np.flatnonzero(abs(lags) <= max_lag)
    lag = int(lags[candidates[np.argmax(abs(cor[candidates]))]])
    if max_lag and abs(lag) == max_lag:
        raise ValueError('相关峰落在搜索边界，请增大 MAX_ALIGN_LAG')
    if lag >= 0:
        xa, ya = x[:x.size - lag], y[lag:]
    else:
        xa, ya = x[-lag:], y[:y.size + lag]
    if len(xa) < 64:
        raise ValueError('对齐后有效数据不足')
    gain = np.vdot(ya, xa) / np.vdot(ya, ya) if compensate_gain else 1 + 0j
    return xa.copy(), ya * gain, lag, gain


def nmse_db(predicted, target):
    a, b = complex_vector(predicted), complex_vector(target)
    if a.shape != b.shape:
        raise ValueError('NMSE 两个数组长度不一致')
    return float(10 * np.log10(max(np.mean(abs(a - b)**2), 1e-30)
                              / max(np.mean(abs(b)**2), 1e-30)))


def spectrum(x, fs=122.88e6, nfft=2048):
    x = complex_vector(x)
    n = min(nfft, len(x))
    f, p = signal.welch(x, fs=fs, window='hann', nperseg=n,
                        noverlap=n // 2, return_onesided=False, scaling='density')
    return np.fft.fftshift(f), np.fft.fftshift(p)


def acpr_db(x, fs=122.88e6, bandwidth=20e6):
    if not 0 < 3 * bandwidth <= fs:
        raise ValueError('采样率必须覆盖主带及两侧邻带')
    f, p = spectrum(x, fs)
    def power(low, high):
        mask = (f >= low) & (f < high)
        if np.count_nonzero(mask) < 2:
            raise ValueError('频谱点数不足')
        return max(float(p[mask].sum()), 1e-30)
    main = power(-bandwidth / 2, bandwidth / 2)
    return (10 * np.log10(power(-1.5 * bandwidth, -0.5 * bandwidth) / main),
            10 * np.log10(power(0.5 * bandwidth, 1.5 * bandwidth) / main))


def plot_signals(signals, fs=122.88e6, title='DPD', time_points=256):
    """signals 为 {'名称': 复数波形}；只显示，不自动保存图片。"""
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(2, 1, figsize=(10, 7))
    fig.suptitle(title)
    for name, x in signals.items():
        x = complex_vector(x)
        f, p = spectrum(x, fs)
        axes[0].plot(f / 1e6, 10 * np.log10(np.maximum(p, 1e-30)), label=name)
        axes[1].plot(x.real[:time_points], label=f'{name} I')
    axes[0].set(xlabel='Frequency (MHz)', ylabel='PSD (dB/Hz)')
    axes[1].set(xlabel='Sample', ylabel='Raw IQ counts')
    for ax in axes:
        ax.grid(True)
        ax.legend()
    fig.tight_layout()
    plt.show()


def saturation_counts(x):
    x = complex_vector(x)
    return {'I': int(np.count_nonzero((x.real == -32768) | (x.real == 32767))),
            'Q': int(np.count_nonzero((x.imag == -32768) | (x.imag == 32767)))}


PARAM_SHAPES = {'L1_w': (7, 21), 'L1_bias': (1, 7), 'L2_c': (7, 9),
                'L2_theta': (7, 9), 'L2_w': (14, 9),
                'L3_w': (7, 1), 'L3_bias': (1, 1)}


def validate_parameters(p):
    for name, shape in PARAM_SHAPES.items():
        if name not in p or np.shape(p[name]) != shape or not np.isfinite(p[name]).all():
            raise ValueError(f'{name} 应为有限数组，形状 {shape}')
    for name in ('L2_c', 'L2_theta', 'L2_w'):
        if np.any(np.asarray(p[name]).imag):
            raise ValueError(f'{name} 必须是实数')


def pack_parameters(p, strict=True):
    """576 个 signed int16；theta Q4.12，其余 Q3.13，floor 后限幅。
    strict=True 时越界报错，避免悄悄截断训练结果。
    """
    validate_parameters(p)
    def q(a, bits=13):
        a = np.floor(np.asarray(a) * 2**bits)
        if strict and np.any((a < -32768) | (a > 32767)):
            raise ValueError('参数超出定点范围，请检查训练或显式选择 strict=False')
        return np.clip(a, -32768, 32767)
    w, b = p['L1_w'], p['L1_bias'].reshape(7, 1)
    l1 = np.concatenate((q(w.real), q(b.real), q(w.imag), q(b.imag)), axis=1)
    l2 = np.concatenate((q(p['L2_c'].real), q(p['L2_theta'].real, 12),
                         q(p['L2_w'][::2].real), q(p['L2_w'][1::2].real)), axis=1)
    last = np.concatenate((p['L3_w'], p['L3_bias']), axis=0)
    l3 = np.column_stack((q(last.real).ravel(), q(last.imag).ravel()))
    return np.concatenate((l1.ravel(), l2.ravel(), l3.ravel())).astype('<i2')


def unpack_parameters(values):
    a = np.asarray(values)
    if a.shape != (PARAM_COUNT,) or not np.isfinite(a).all() or np.any(a != np.floor(a)):
        raise ValueError('必须恰好提供 576 个 int16 整数')
    if np.any((a < -32768) | (a > 32767)):
        raise ValueError('参数不在 int16 范围')
    a = a.astype(np.float64)
    l1, l2, l3 = a[:308].reshape(7, 44), a[308:560].reshape(7, 36), a[560:].reshape(8, 2)
    w2 = np.empty((14, 9))
    w2[::2], w2[1::2] = l2[:, 18:27] / 8192, l2[:, 27:36] / 8192
    return {'L1_w': (l1[:, :21] + 1j * l1[:, 22:43]) / 8192,
            'L1_bias': ((l1[:, 21] + 1j * l1[:, 43]) / 8192).reshape(1, 7),
            'L2_c': l2[:, :9] / 8192, 'L2_theta': l2[:, 9:18] / 4096,
            'L2_w': w2, 'L3_w': ((l3[:7, 0] + 1j * l3[:7, 1]) / 8192).reshape(7, 1),
            'L3_bias': np.array([[(l3[7, 0] + 1j * l3[7, 1]) / 8192]])}
