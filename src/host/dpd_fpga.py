"""DPD 最终联调入口（PC Python + Zynq 裸机 UART）。

依赖：numpy、scipy、matplotlib、pyserial。四个 .py 放在同一目录。
Spyder / VS Code 可按 # %% 从上到下逐块运行，变量保留在交互窗口。
先运行 00、01，再逐块运行 02～12。F5 整文件会执行完整上板和训练流程。
只想接收现有板上波形：运行 00、01、03、06；无需先发送 TX。
只想验证已有 MAT 模型：TRAIN_NEW_MODEL=False，填写 MODEL_FILE。

所有波形变量都是原始 IQ 计数；不自动修改发射衰减/接收增益。
寄存器用索引，不乘 4；二进制小端；命令只用 LF，不能用 CRLF。
本文件导入时不打开串口、不训练、不下发、不保存文件。

故障恢复：关闭其他串口软件，先复位/重启 PS，等启动结束。
若仍在同一个 Spyder 内核，重新运行 00、01 后，单独设置
CONFIRM_PS_RESET=True，再运行 03。故障状态不会因重定义类自动清除。
board.history、board.last_error 和 PORT_FAULTS 只保存在内存，便于直接查看。
"""
# %% 00 导入与配置——首先修改串口，确认已经进入 PS 串口命令循环
from pathlib import Path
import numbers
import struct
import sys
import time
from collections import deque
import numpy as np
import serial
from serial.tools.list_ports import comports
from scipy.io import savemat
# 从项目外的工作目录启动或执行交互代码块时，也能找到同目录模块。
HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
from data_process import (RAM_DEPTH, PARAM_COUNT, load_tx, complex_vector,
                          iq_bytes, bytes_iq, align_signals, nmse_db, acpr_db,
                          plot_signals, saturation_counts, pack_parameters,
                          unpack_parameters, quantize_iq)
from expcnn_final import expcnn, predict_fixed, CONTEXT
from expcnn_bp_adam import train_model

PORT = 'COM5'                 # 本次已确认的调试口；运行时先关闭其他串口软件
BAUD = 115200
IO_TIMEOUT = 2.0              # 秒；收发另按包长自动增加线速时间预算
REPLY_QUIET = 0.04            # 已收齐响应后的尾部检查窗口，不是扩大命令执行超时
CONFIRM_PS_RESET = False      # 故障后先复位/重启 PS，再设 True，仅用于重新执行第 03 块
CAPTURE_TIMEOUT = 10.0        # CAP_DONE 每次跳变的最大等待时间
SOURCE_FILE = HERE / 'source.mat'
SOURCE_KEY = 'source'
SOURCE_UNITS = 'counts'       # 本工程 source.mat 已是原始计数
TX_GAIN = 0.6                 # 与旧上位机发数幅度对应，不做峰值归一化
TAPER_POINTS = 0              # 如需旧版首尾加窗，可改成 256
TRANSFER_SAMPLES = 1024       # 每次 UART 写/读的点数；全部写满 17536 点
CAPTURE_LENGTH = 16384     # 可先用 1024 检查收发，再增加点数训练
TRIGGER_POINT = 0
FS = 122.88e6
BANDWIDTH = 20e6
MAX_ALIGN_LAG = 256
DO_DATA_ALIGN = False         # PS 用编译进 ELF 的 OFDM 作参考；仅波形完全相同时才可启用
TX_ATTEN = None               # None 保持板上值；如设置，直接传 PS API 原始参数
RX_GAIN = None                # None 保持板上值；沿用 PS 的 gain+195 语义
TRAIN_NEW_MODEL = True
MODEL_FILE = HERE / 'model_mat' / 'ad9371_dpd_0216_0.mat'
WARM_START_FILE = None        # None 从头训练；或填写一个已有 MAT 模型路径
TRAIN_ITERS = 300            # 首次检查训练链路可设 5，再改成 300
TRAIN_LR = 0.005
TRAIN_GAMMA = 0.995
TRAIN_BATCH = 1024
VALIDATION_FRACTION = 0.2
# 当前修改后的 RTL：实测 model_out[n] 对应 tx_delay[n] 的参考输出。
# 若 A 改过流水线，必须重新核对该偏移，不能用它掩盖其他错误。
MODEL_REFERENCE_OFFSET = 0
PLOT = True
SAVE_SESSION = False         # 默认不生成文件；True 才在第 13 块保存一个 MAT
SESSION_FILE = HERE / 'dpd_session.mat'
STOP_TX_AT_END = False        # 默认关闭串口后仍保持板卡发射，便于频谱仪观察

REGISTERS = dict(enumerate((
    'ALIGN_EN', 'DELAY', 'APC_K_I', 'APC_K_Q', 'CAP_DATA_CMD', 'CAP_LEN',
    'TRIGGER_POINT', 'CAP_RD_ADDR', 'CAP_DATA_RDATA', 'TX_VLD', 'TX_DATA_EN',
    'TX_DATA_WR', 'TX_DATA_ADDR', 'TX_DATA_WDATA', 'TX_DATA_RDATA', 'CH_SEL',
    'DPD_EN', 'DPD_COE_EN', 'DPD_COE_WR', 'DPD_COE_ADDR', 'DPD_COE_WDATA',
    'DPD_COE_RDATA', 'DPD_OUT', 'CYCLIC_EN', 'CYCLIC_DATA_EN', 'CYCLIC_DATA_WR',
    'CYCLIC_DATA_ADDR', 'CYCLIC_DATA_WDATA', 'CYCLIC_DATA_RDATA', 'CAP_DONE')))
# 节点定义：0 TX RAM；1 原始 RX；2 相位对齐 RX；3 时间对齐 TX；4 RX-TX；
#           5 模型输入的延迟 TX；6 CH_SEL 相关输出；7 最终发射 TX。
# CH_SEL=0:旁路；1:TX-model；2:model；3:TX-cyclic；4:cyclic。


# %% 01 串口与协议工具——只定义函数，不打开端口
# 保留跨 Spyder 单元格重跑的故障状态，重定义类不能解除失效连接。
PORT_FAULTS = globals().get('PORT_FAULTS', {})


class protocol_error(RuntimeError):
    pass


def _integer(value, low, high):
    if isinstance(value, bool) or not isinstance(value, numbers.Integral) or not low <= value <= high:
        raise ValueError(f'应为 [{low}, {high}] 范围整数，实际为 {value!r}')
    return int(value)


def _interval(start, stop, limit):
    start = _integer(start, 0, limit - 1)
    stop = _integer(stop, start + 1, limit)
    return stop - start


class dpd_host:
    """单连接串行执行命令；任何收发错误后关闭连接，禁止带残包继续操作。
    io 必须为有 timeout/write_timeout 的 pyserial 兼容接口。
    """
    def __init__(self, io, baud=115200, timeout=2.0, capture_timeout=10.0,
                 reply_quiet=0.04):
        if not np.isfinite([baud, timeout, capture_timeout]).all() or min(baud, timeout, capture_timeout) <= 0:
            raise ValueError('波特率和超时必须为正数')
        self.io, self.baud = io, baud
        self.timeout, self.capture_timeout = timeout, capture_timeout
        if not np.isfinite(reply_quiet) or reply_quiet <= 0:
            raise ValueError('reply_quiet 必须为正数')
        self.reply_quiet = reply_quiet
        self.broken = False
        self.last_rx = b''
        self.last_exchange = None
        self.last_error = None
        self.history = deque(maxlen=32)  # 内存记录，不生成文件
        self.io.timeout = min(.01, reply_quiet)

    @property
    def port_key(self):
        return str(getattr(self.io, 'port', '') or '').upper()

    @classmethod
    def open(cls, name, baud=115200, timeout=2.0, capture_timeout=10.0,
             reply_quiet=0.04, after_ps_reset=False):
        key = str(name).upper()
        if key in PORT_FAULTS and not after_ps_reset:
            raise protocol_error(
                f'{name} 上次协议失败，不能仅清空主机缓冲区后继续。'
                '先复位/重启 PS，等初始化结束，再设 CONFIRM_PS_RESET=True 运行第 03 块。')
        io = serial.Serial(name, baudrate=baud, bytesize=8, parity='N', stopbits=1,
                           timeout=.05, write_timeout=timeout,
                           xonxoff=False, rtscts=False, dsrdtr=False)
        board = cls(io, baud, timeout, capture_timeout, reply_quiet)
        try:
            # 只在建立会话时读取启动文本，不在每条命令前清空缓冲区。
            boot = bytearray()
            quiet_until, deadline = time.monotonic() + .3, time.monotonic() + 15
            while time.monotonic() < quiet_until:
                if time.monotonic() >= deadline:
                    raise TimeoutError('PS 持续输出，请等启动结束后重新连接')
                data = io.read(io.in_waiting or 1)
                if data:
                    boot.extend(data)
                    quiet_until = time.monotonic() + .3
            if boot:
                print('PS 启动输出：', boot.decode('utf-8', errors='replace'))
            board.startup_rx = bytes(boot)
            # 只读探测：每次应答都验证数据长度、后续完成标记和残留字节。
            status = {a: board.reg_read(a) for a in (9, 29, 15, 16, 5)}
            PORT_FAULTS.pop(key, None)
            print(f'{name} 协议探测通过：', {REGISTERS[a]: v for a, v in status.items()})
            return board
        except BaseException as exc:
            if not board.broken:
                board._invalidate(f'建立会话失败：{exc}')
            board.close()
            raise

    def close(self):
        self.io.close()

    def _invalidate(self, reason):
        self.broken = True
        entry = dict(self.last_exchange or {})
        entry.update(reason=str(reason), rx=self.last_rx)
        self.last_error = entry
        if self.port_key:
            PORT_FAULTS[self.port_key] = entry
        try:
            self.close()
        except Exception:
            pass  # 保留原始故障，不能被 close 的异常覆盖

    def _diagnostic(self, reason):
        entry = self.last_exchange or {}
        raw = self.last_rx
        display = repr(raw) if len(raw) <= 160 else repr(raw[:80]) + ' ... ' + repr(raw[-80:])
        return (f'{reason}\nport={self.port_key or "<unknown>"}, '
                f'command={entry.get("command")!r}, '
                f'TX={entry.get("sent_bytes", 0)}/{entry.get("wire_bytes", 0)} 字节, '
                f'RX={len(raw)} 字节 {display}\n'
                '本会话已失效，不自动重发。检查 PORT/波特率/PS 运行状态，'
                '复位或重启 PS 后重新建立会话；不要靠连续读寄存器或清空主机缓冲区恢复。')

    def _receive_frame(self, minimum, deadline, variable=False):
        """完整收帧再解释内容；二进制里的 LF/ERR/COMMAND 不作为分隔符。
        minimum 包括原响应及三个 Reg_Read 的 12 字节完成标记。
        """
        raw = bytearray()
        last_byte = None
        while True:
            now = time.monotonic()
            waiting = self.io.in_waiting
            if waiting:
                part = self.io.read(min(waiting, 65536))
            else:
                # 必须先观察完整响应后的安静间隔，不能收到前 4 字节就返回。
                if last_byte is not None and now - last_byte >= self.reply_quiet:
                    if len(raw) >= minimum or variable:
                        self.last_rx = bytes(raw)
                        return self.last_rx
                    # 不完整的二进制帧继续等到整体期限；其中即使出现完整的
                    # ERR/COMMAND 文本和零字节，也不能据此把合法采样当成错误行。
                if now >= deadline:
                    self.last_rx = bytes(raw)
                    raise TimeoutError(f'等待完整响应超时：收到 {len(raw)}/{minimum} 字节（含完成标记）')
                part = self.io.read(1)
            if part:
                raw.extend(part)
                self.last_rx = bytes(raw)
                last_byte = time.monotonic()
                if len(raw) > max(minimum + 4096, 8192):
                    raise protocol_error('应答超长或 PS 持续输出非协议数据')
            if time.monotonic() >= deadline:
                self.last_rx = bytes(raw)
                raise TimeoutError(f'等待完整响应超时：收到 {len(raw)}/{minimum} 字节（含完成标记）')

    @staticmethod
    def _valid_completion(raw):
        # PS 依次执行三个只读命令，保证之前的无 ACK 写入/读出已经执行完。
        # 三个寄存器都只可能是 0/1，不能把任意 4 字节当成该标记。
        return len(raw) == 12 and all(x in (0, 1) for x in struct.unpack('<III', raw))

    def request(self, command, payload=b'', size=0, trailer=False, ack=False, line=False, extra_wait=0):
        if self.broken or not self.io.is_open:
            raise protocol_error('串口已关闭或上次收发失败；排除问题后重启 PS 并重新建立会话')
        if '\n' in command or '\r' in command:
            raise ValueError('命令不应包含换行')
        # 不新增 PS 命令：把三个只读命令排在原事务之后。
        # PS 的命令循环依序执行，末尾的三个 u32 是该事务的完成确认。
        # 写命令的二进制长度不变；这些 ASCII 必须在完整 payload 之后。
        # 旧协议仍没有帧号/CRC；完成确认不能替代故障后的 PS 复位。
        completion = b'Reg_Read 29\nReg_Read 9\nReg_Read 16\n'
        packet = command.encode('ascii') + b'\n' + payload + completion
        expected = (1 if ack or line else size + int(trailer)) + 12
        budget = self.timeout + extra_wait + 3 * (len(packet) + expected) * 10 / self.baud
        deadline = time.monotonic() + budget
        self.last_rx = b''
        self.last_exchange = dict(command=command, payload_bytes=len(payload),
                                  wire_bytes=len(packet), sent_bytes=0, expected_bytes=expected,
                                  tx_head=packet[:96], tx_tail=packet[-48:], rx=b'')
        self.history.append(self.last_exchange)
        try:
            self.io.write_timeout = budget
            if self.io.in_waiting:
                # 非启动阶段出现残留就是协议错位；记录后关闭，不能悄悄清空再发。
                self.last_rx = self._receive_frame(0, deadline, variable=True)
                raise protocol_error('发送前存在未归属的串口残留数据')
            offset = 0
            while offset < len(packet):
                if time.monotonic() >= deadline:
                    raise TimeoutError('串口发送超时')
                count = self.io.write(packet[offset:])
                if not count:
                    raise protocol_error('串口写入无进展')
                offset += count
                self.last_exchange['sent_bytes'] = offset
            raw = self._receive_frame(expected, deadline, variable=ack or line)
            self.last_exchange['rx'] = raw
            if len(raw) < 12 or not self._valid_completion(raw[-12:]):
                raise protocol_error('末尾三个只读完成标记缺失/异常，响应可能混入错误文本或已经错位')
            result = raw[:-12]
            if ack or line:
                if ack and result != b'\n':
                    raise protocol_error(f'PS 未返回单个 LF 成功应答：{result!r}')
                if line and (not result.endswith(b'\n') or result.startswith(b'ERR')):
                    raise protocol_error(f'PS 文本应答异常：{result!r}')
                return result
            if len(result) != size + int(trailer):
                raise protocol_error(f'响应长度异常：预期 {size + int(trailer)} 字节，'
                                    f'实际 {len(result)} 字节（不含完成标记）')
            if trailer and result[-1:] != b'\n':
                raise protocol_error('固定长度二进制数据后缺少 LF')
            return result[:size]
        except BaseException as exc:
            self.last_exchange['rx'] = self.last_rx
            message = self._diagnostic(str(exc))
            self._invalidate(message)
            if isinstance(exc, TimeoutError):
                raise TimeoutError(message) from exc
            if isinstance(exc, Exception):
                raise protocol_error(message) from exc
            raise

    def reg_read(self, address):
        address = _integer(address, 0, 29)
        raw = self.request(f'Reg_Read {address}', size=4)
        value = struct.unpack('<I', raw)[0]
        # 依据当前 axi_lite_dpd.v 的位宽进一步校验；32 位数据寄存器不按 ASCII 猜测。
        bits = {0: 1, 1: 10, 4: 6, 5: 16, 7: 16, 9: 1, 10: 1,
                11: 1, 12: 16, 15: 3, 16: 1, 17: 1, 18: 1, 19: 10, 20: 16, 21: 16,
                23: 1, 24: 1, 25: 1, 26: 16, 29: 1}.get(address, 32)
        if value >= 2**bits:
            message = self._diagnostic(f'{REGISTERS[address]} 超出 {bits} 位范围：{value} (0x{value:08X})')
            self._invalidate(message)
            raise protocol_error(message)
        return value

    def reg_write(self, address, value, verify=False):
        address, value = _integer(address, 0, 29), _integer(value, 0, 0xffffffff)
        self.request(f'Reg_Write {address} {value}')  # 用后续只读完成标记确认无 ACK 命令
        if verify:
            actual = self.reg_read(address)
            if actual != value:
                message = self._diagnostic(
                    f'{REGISTERS[address]} 回读不一致：写入 {value} (0x{value:08X})，'
                    f'读回 {actual} (0x{actual:08X})；完整响应已通过边界检查，'
                    '请进一步检查 PS 寄存器地址和板上 RTL，而不是继续忽略错误')
                self._invalidate(message)
                raise protocol_error(message)

    def set_path(self, channel=0, dpd=False):
        channel = _integer(channel, 0, 4)
        if channel in (1, 2) and not dpd:
            raise ValueError('模型通道需要 dpd=True')
        # 先旁路，再改模型使能，避免参数更新时使用不完整模型。
        self.reg_write(15, 0, verify=True)
        self.reg_write(16, int(dpd), verify=True)
        self.reg_write(23, int(channel in (3, 4)), verify=True)
        if dpd:
            time.sleep(.05)
        self.reg_write(15, channel, verify=True)

    def para_write(self, values, start=0):
        a = np.asarray(values)
        if a.ndim != 1 or not a.size or not np.isfinite(a).all() or np.any(a != np.floor(a)):
            raise ValueError('参数必须是一维整数数组')
        if np.any((a < -32768) | (a > 32767)):
            raise ValueError('参数超出 int16 范围')
        _interval(start, start + len(a), PARAM_COUNT)
        self.request(f'Para_Write {start} {start + len(a)}', a.astype('<i2').tobytes(), ack=True)

    def para_read(self, start=0, stop=PARAM_COUNT):
        n = _interval(start, stop, PARAM_COUNT)
        return np.frombuffer(self.request(f'Para_Read {start} {stop}', size=2*n, trailer=True), dtype='<i2').copy()

    def wave_write(self, values, start=0, memory='tx'):
        name = {'tx': 'Tx_Write', 'cyclic': 'Cyclic_Write'}[memory]
        x = complex_vector(values)
        _interval(start, start + len(x), RAM_DEPTH)
        self.request(f'{name} {start} {start + len(x)}', iq_bytes(x), ack=True)

    def wave_read(self, start, stop, memory='tx'):
        name = {'tx': 'Tx_Read', 'cyclic': 'Cyclic_Read'}[memory]
        n = _interval(start, stop, RAM_DEPTH)
        return bytes_iq(self.request(f'{name} {start} {stop}', size=4*n, trailer=True))

    def upload_wave(self, values, memory='tx', chunk=1024):
        """停止发数后分包写满 RAM，并逐包回读验证；成功后仍保持 TX_VLD=0。"""
        x = complex_vector(values)
        iq_bytes(x)  # 在修改寄存器前检查整个波形
        if len(x) != RAM_DEPTH:
            raise ValueError(f'循环 RAM 必须完整写入 {RAM_DEPTH} 点')
        chunk = _integer(chunk, 1, RAM_DEPTH)
        self.reg_write(9, 0, verify=True)
        self.set_path(0, False)
        readback = np.empty_like(x)
        for start in range(0, len(x), chunk):
            stop = min(start + chunk, len(x))
            self.wave_write(x[start:stop], start, memory)
            readback[start:stop] = self.wave_read(start, stop, memory)
            if not np.array_equal(x[start:stop], readback[start:stop]):
                bad = start + np.flatnonzero(x[start:stop] != readback[start:stop])[0]
                message = self._diagnostic(f'{memory} RAM 第 {bad} 点回读不一致，TX 保持关闭')
                self._invalidate(message)
                raise protocol_error(message)
            print(f'{memory}: {stop}/{len(x)} 点，回读一致')
        return readback

    def _wait_capture(self, desired):
        deadline = time.monotonic() + self.capture_timeout
        while self.reg_read(29) != desired:
            if time.monotonic() >= deadline:
                raise TimeoutError(f'CAP_DONE 未变为 {desired}，停止本次采集，不读取旧数据')
            time.sleep(.01)

    def capture_read(self, node, start, stop):
        node = _integer(node, 0, 7)
        n = _interval(start, stop, RAM_DEPTH)
        return bytes_iq(self.request(f'Cap_Read {node} {start} {stop}', size=4*n, trailer=True))

    def capture(self, nodes=(0, 1, 2, 3, 5, 7), length=RAM_DEPTH, trigger=0):
        length = _integer(length, 2, RAM_DEPTH)  # 长度 1 会让当前 RTL 的完成条件立即成立
        trigger = _integer(trigger, 0, RAM_DEPTH - 1)
        nodes = tuple(_integer(n, 0, 7) for n in nodes)
        if self.reg_read(9) != 1:
            raise RuntimeError('TX_VLD 不是 1，先启动发数再采集')
        if self.reg_read(29):  # 清除上次尚未确认的完成状态
            self.reg_write(4, 1 << 5)
            self.reg_write(4, 0)
            self._wait_capture(0)
        self.reg_write(5, length - 1, verify=True)
        self.reg_write(6, trigger, verify=True)
        self.reg_write(4, 1 << 4)
        self.reg_write(4, 0)
        self._wait_capture(1)
        self.reg_write(4, 1 << 5)
        self.reg_write(4, 0)
        self._wait_capture(0)
        result = {}
        for node in nodes:
            result[node] = self.capture_read(node, 0, length)
            print(f'node {node}: {length} 点；触及 int16 边界 {saturation_counts(result[node])}')
        return result

    def data_align(self):
        """旧 PS 校准命令：参考是 ELF 内置 OFDM，并非刚写入 TX RAM 的波形。
        换过波形时不要调用；上位机第 07 块会用当前捕获数据再对齐。
        """
        reply = self.request('Data_Align', line=True, extra_wait=30)
        if reply != b'RF System Initial Successful\n':
            message = self._diagnostic(f'Data_Align 未返回预期成功应答：{reply!r}')
            self._invalidate(message)
            raise protocol_error(message)
        print(reply.decode().strip())

    def tx_atten(self, value):
        self.request(f'Tx_Atten {_integer(value, 0, 0xffffffff)}')

    def rx_gain(self, value):
        self.request(f'Rx_Gain {_integer(value, 0, 60)}')


def check_model_capture(capture, parameter_values, offset=1):
    """比较 node5/6 定点结果；排除缺失上下文，明确打印偏移，不自动搜索最佳值。"""
    offset = _integer(offset, -128, 128)
    reference = predict_fixed(capture[5], parameter_values)
    n = len(capture[5])
    indices = np.arange(max(0, CONTEXT - offset), min(n, n - CONTEXT - offset))
    if not len(indices):
        raise ValueError('采样太短，无法排除模型上下文边缘')
    expected, actual = reference['output'][indices + offset], capture[6][indices]
    error = actual - expected
    mismatches = (actual.real != expected.real) | (actual.imag != expected.imag)
    print(f'定点核对：reference[n{offset:+d}] vs node6[n]，有效 {len(indices)} 点')
    print(f'不一致 {mismatches.sum()} 点，最大分量误差 '
          f'{max(abs(error.real).max(), abs(error.imag).max()):.0f} LSB')
    print('实测限幅：', saturation_counts(actual), '预期限幅：', saturation_counts(expected))
    print('L2 参考触边分量数：', int(np.count_nonzero(np.isin(reference['l2'], (-32768, 32767)))))
    difference = capture[5] - capture[6]
    expected_tx = quantize_iq(difference)  # 当前 RTL 的 17 -> 16 位饱和减法
    tx_error = capture[7] - expected_tx
    print('最终 TX = sat16(tx_delay - model_out) 的最大误差：', float(abs(tx_error).max()), 'counts')
    return dict(reference=reference, indices=indices, error=error,
                mismatch_indices=indices[mismatches], tx_error=tx_error)


# %% 02 准备 TX——结果 tx_iq 可在变量窗口直接检查，尚未发送
if __name__ == '__main__':
    tx_iq = load_tx(SOURCE_FILE, SOURCE_KEY, TX_GAIN, SOURCE_UNITS, TAPER_POINTS)
    print(f'TX: {len(tx_iq)} 点，I 峰值 {abs(tx_iq.real).max():.0f}，Q 峰值 {abs(tx_iq.imag).max():.0f}')
    if PLOT:
        plot_signals({'tx_file': tx_iq}, FS, 'TX waveform before upload')

# %% 03 打开串口——只接收现有波形时可跳过 02/04/05
if __name__ == '__main__':
    if 'board' in globals():
        board.close()
    print('可用串口：', [(p.device, p.description) for p in comports()])
    _reset_confirmed = CONFIRM_PS_RESET
    CONFIRM_PS_RESET = False  # 确认仅消费一次；连接失败后需再次实际复位再确认
    board = dpd_host.open(PORT, BAUD, IO_TIMEOUT, CAPTURE_TIMEOUT,
                        REPLY_QUIET, after_ps_reset=_reset_confirmed)
    
# %% 04 发送 TX -> 分块回读 -> 旁路发数
if __name__ == '__main__':
    tx_readback = board.upload_wave(tx_iq, chunk=TRANSFER_SAMPLES)
    if TX_ATTEN is not None:
        board.tx_atten(TX_ATTEN)
    if RX_GAIN is not None:
        board.rx_gain(RX_GAIN)
    board.set_path(0, False)
    board.reg_write(9, 1, verify=True)
    time.sleep(.1)
    print('TX 全部回读一致，已开启旁路发数')

# %% 05 可选：旧 PS 对齐——仅 TX 波形与 ELF 内置 OFDM 完全一致时使用
if __name__ == '__main__':
    if DO_DATA_ALIGN:
        board.data_align()
    # 改过 TX 波形或幅度时跳过本块，不能用旧 OFDM 校准新波形。

# %% 06 接收旁路基线——一次触发后读取各节点，全部保留为原始计数
if __name__ == '__main__':
    if board.reg_read(15) != 0:
        raise RuntimeError('基线采集要求 CH_SEL=0；先执行 board.set_path(0, False)')
    baseline = board.capture((0, 1, 3, 5, 7), CAPTURE_LENGTH, TRIGGER_POINT)
    tx_raw, rx_raw = baseline[0], baseline[1]
    if PLOT:
        plot_signals({'tx_raw': tx_raw, 'rx_raw': rx_raw}, FS, 'Bypass capture')

# %% 07 上位机再对齐，准备误差目标——不要把原始 RX 直接作为失真目标
if __name__ == '__main__':
    x_train, rx_train, rx_lag, rx_coefficient = align_signals(
        tx_raw, rx_raw, MAX_ALIGN_LAG)
    err_train = rx_train - x_train
    print(f'软件对齐：RX lag={rx_lag}，RX 乘系数={rx_coefficient}，有效 {len(x_train)} 点')
    print('旁路 RX 相对 TX NMSE：', nmse_db(rx_train, x_train), 'dB')
    baseline_acpr = acpr_db(rx_raw, FS, BANDWIDTH)
    print('旁路 RX ACPR 左/右：', baseline_acpr, 'dBc')
    if PLOT:
        plot_signals({'tx_train': x_train, 'rx_train': rx_train, 'target_error': err_train}, FS, 'Training data')

# %% 08 训练模型——可单独重跑；模型和 history 留在内存，不自动保存
if __name__ == '__main__':
    if TRAIN_NEW_MODEL:
        initial_model = None if WARM_START_FILE is None else expcnn.load(WARM_START_FILE)
        model, history = train_model(x_train, err_train, model=initial_model,
                                     iters=TRAIN_ITERS, lr=TRAIN_LR, gamma=TRAIN_GAMMA,
                                     batch_size=TRAIN_BATCH,
                                     validation_fraction=VALIDATION_FRACTION)
    else:
        model, history = expcnn.load(MODEL_FILE), []
        print('已加载模型：', MODEL_FILE)
        
# %% 08A 绘制训练曲线
if __name__ == '__main__':
    import matplotlib.pyplot as plt

    if not history:
        raise RuntimeError(
            'history 为空。请确认 TRAIN_NEW_MODEL=True，'
            '并先运行第 08 块训练模型。'
        )

    iterations = [item['iteration'] for item in history]
    train_nmse = [item['train_nmse'] for item in history]
    val_nmse = [item['val_nmse'] for item in history]

    plt.figure(figsize=(8, 5))

    plt.plot(iterations, train_nmse, label='Train')
    plt.plot(iterations, val_nmse, label='Validation')

    plt.xlabel('Iteration')
    plt.ylabel('Error-model NMSE (dB)')
    plt.title('Training and validation')
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.show()

# %% 09 查看训练预测与量化结果——model_para 为后续真正下发的 576 个整数
if __name__ == '__main__':
    y_pred = model.predict(x_train)
    model_para = pack_parameters(model.parameters)
    model_quantized = expcnn(unpack_parameters(model_para))
    y_pred_quantized = model_quantized.predict(x_train)
    y_fixed_train = predict_fixed(x_train, model_para)['output']
    valid = slice(CONTEXT, len(x_train) - CONTEXT)
    print('误差模型整体 NMSE（非独立验证集）：', nmse_db(y_pred[valid], err_train[valid]), 'dB')
    print('定点模型整体 NMSE：', nmse_db(y_fixed_train[valid], err_train[valid]), 'dB')
    print('参数个数：', len(model_para), '；定点输出限幅：', saturation_counts(y_fixed_train))
    if PLOT:
        plot_signals({'target_error': err_train, 'float_prediction': y_pred,
                      'fixed_prediction': y_fixed_train}, FS, 'Model before upload')

# %% 10 下发模型参数 -> 回读 576 项逐项比较——保持旁路，尚未开启 DPD
if __name__ == '__main__':
    board.set_path(0, False)
    board.para_write(model_para)
    parameter_readback = board.para_read()
    if not np.array_equal(model_para, parameter_readback):
        bad = np.flatnonzero(model_para != parameter_readback)
        message = board._diagnostic(f'模型参数回读失败，索引 {bad[:20].tolist()}；DPD 保持关闭')
        board._invalidate(message)
        raise protocol_error(message)
    print('576 个模型参数全部回读一致')

# %% 11 开启 DPD -> 接收模型输出和最终 TX/RX——此时可观察频谱仪
if __name__ == '__main__':
    if not np.array_equal(board.para_read(), model_para):
        raise protocol_error('板上参数与当前模型不同，请先重新执行第 10 块')
    board.set_path(1, True)
    time.sleep(.1)
    dpd_capture = board.capture((0, 1, 3, 5, 6, 7), CAPTURE_LENGTH, TRIGGER_POINT)
    model_out_fpga, tx_final_fpga, rx_dpd = dpd_capture[6], dpd_capture[7], dpd_capture[1]

# %% 12 分别检查数字模型、TX 减法和射频 RX 的效果
if __name__ == '__main__':
    model_check = check_model_capture(dpd_capture, parameter_readback, MODEL_REFERENCE_OFFSET)
    tx_after, rx_after, lag_after, coefficient_after = align_signals(
        dpd_capture[0], rx_dpd, MAX_ALIGN_LAG)
    dpd_acpr = acpr_db(rx_dpd, FS, BANDWIDTH)
    print('DPD RX 相对 TX NMSE：', nmse_db(rx_after, tx_after), 'dB')
    print('DPD RX ACPR 左/右：', dpd_acpr, 'dBc')
    print('ACPR 改善（正值为改善）左右：', np.asarray(baseline_acpr) - np.asarray(dpd_acpr), 'dB')
    if PLOT:
        plot_signals({'rx_bypass': rx_raw * rx_coefficient,
                      'rx_dpd': rx_dpd * rx_coefficient}, FS, 'RF comparison (same baseline gain)')
        plot_signals({'tx_delay': dpd_capture[5], 'model_fpga': model_out_fpga,
                      'tx_final': tx_final_fpga}, FS, 'Digital DPD nodes')

# %% 12A 绘制 DPD 前后的 AM/AM 和 AM/PM
if __name__ == '__main__':
    import numpy as np
    import matplotlib.pyplot as plt

    # -----------------------------
    # 1. 获取 DPD 前后的 TX/RX 数据
    # -----------------------------

    # DPD 旁路时，第 07 块已经完成对齐
    tx_off = np.asarray(x_train, dtype=np.complex128)
    rx_off = np.asarray(rx_train, dtype=np.complex128)

    # DPD 开启后，用原始 TX node 0 和原始 RX node 1 对齐
    tx_on, rx_on, lag_on, gain_on = align_signals(
        dpd_capture[0],
        dpd_capture[1],
        MAX_ALIGN_LAG
    )

    print('DPD 后软件对齐 lag =', lag_on)
    print('DPD 后 RX 对齐系数 =', gain_on)

    # -----------------------------
    # 2. 计算 AM/AM 和 AM/PM
    # -----------------------------
    def calculate_amam_ampm(tx, rx, threshold_ratio=0.05):
        tx = np.asarray(tx, dtype=np.complex128)
        rx = np.asarray(rx, dtype=np.complex128)

        tx_amplitude = np.abs(tx)
        rx_amplitude = np.abs(rx)

        # 避免输入幅度接近 0 时，相位受噪声影响过大
        threshold = threshold_ratio * np.max(tx_amplitude)
        valid = tx_amplitude > threshold

        # 使用 FPGA 的 16 位计数范围进行归一化
        input_amplitude = tx_amplitude[valid] / 32768.0
        output_amplitude = rx_amplitude[valid] / 32768.0

        # RX 相对于 TX 的相位差，范围为 -180° 到 180°
        phase_difference = np.angle(
            rx[valid] * np.conj(tx[valid]),
            deg=True
        )

        return input_amplitude, output_amplitude, phase_difference

    in_off, out_off, phase_off = calculate_amam_ampm(tx_off, rx_off)
    in_on, out_on, phase_on = calculate_amam_ampm(tx_on, rx_on)

    print('AM/AM、AM/PM 有效点数：')
    print('旁路：', len(in_off))
    print('DPD：', len(in_on))

    # -----------------------------
    # 3. 绘图
    # -----------------------------
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))

    # AM/AM
    axes[0].scatter(
        in_off, out_off,
        s=8, alpha=0.5, label='DPD off'
    )
    axes[0].scatter(
        in_on, out_on,
        s=8, alpha=0.5, label='DPD on'
    )

    axes[0].set_xlabel('Reference TX amplitude / 32768')
    axes[0].set_ylabel('Aligned RX amplitude / 32768')
    axes[0].set_title('AM/AM')
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()

    # AM/PM
    axes[1].scatter(
        in_off, phase_off,
        s=8, alpha=0.5, label='DPD off'
    )
    axes[1].scatter(
        in_on, phase_on,
        s=8, alpha=0.5, label='DPD on'
    )

    axes[1].set_xlabel('Reference TX amplitude / 32768')
    axes[1].set_ylabel('RX phase relative to TX (degrees)')
    axes[1].set_title('AM/PM')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()

    plt.tight_layout()
    plt.show()
# %% 13 可选保存——默认关闭；仅在需要时保存一个 MAT，不生成其他附件
if __name__ == '__main__' and SAVE_SESSION:
    savemat(str(SESSION_FILE), dict(
        x_train=x_train, rx_train=rx_train, err_train=err_train,
        y_pred=y_pred, y_fixed_train=y_fixed_train, model_para=model_para,
        model_out_fpga=model_out_fpga, tx_final_fpga=tx_final_fpga, rx_dpd=rx_dpd,
        rx_lag=rx_lag, rx_coefficient=rx_coefficient,
        baseline_acpr=baseline_acpr, dpd_acpr=dpd_acpr,
        **model.parameters))
    print('已保存：', SESSION_FILE)

# %% 14 结束串口会话——需要继续采集时重新运行 03；默认保持板卡当前发射
if __name__ == '__main__':
    if STOP_TX_AT_END:
        board.reg_write(9, 0, verify=True)
        board.set_path(0, False)
    board.close()
    print('串口已关闭')

# %% 可选手动操作（在控制台逐条执行；不包含在默认流程内）
# board.reg_read(29)                   # 读取 CAP_DONE
# board.set_path(0, False)             # 切回无 DPD 的旁路
# board.reg_write(9, 0, verify=True)    # 停止发数
# board.close()                       # 出错后先关闭，再检查 PS 状态
# model.save(HERE / 'model_para.mat')  # 显式保存模型，供下次直接加载
#
# 可选 cyclic 路径：RAM 固定 17536 点，不能只填入一段对齐裁短后的数据。
# cyclic_iq = quantize_iq(tx_iq - model.predict(tx_iq))
# cyclic_readback = board.upload_wave(cyclic_iq, memory='cyclic', chunk=TRANSFER_SAMPLES)
# board.set_path(4, False)
# board.reg_write(9, 1, verify=True)
# cyclic_capture = board.capture((2, 3, 5, 6, 7), CAPTURE_LENGTH, TRIGGER_POINT)
# 请在控制台按需执行手动操作，不在文件末尾自动更改板卡设置。

