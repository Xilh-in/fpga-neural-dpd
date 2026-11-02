"""Transport-independent exact binary transfer and polling with bounded waits."""
import json
import math
import time


class SessionError(RuntimeError):
    pass


class Session:
    def __init__(self, transport, clock=time.monotonic, log=None):
        """transport.read/write must themselves have finite blocking timeouts."""
        self.transport, self.clock, self.log = transport, clock, log
        self.invalid = False

    def event(self, direction, data=b'', **extra):
        if self.log:
            self.log.write(json.dumps(dict(event=direction, hex=data.hex(), bytes=len(data), **extra)) + '\n')
            self.log.flush()

    def transfer(self, packet, response_bytes, timeout, trailer=b'', ack_only=False):
        if self.invalid:
            raise SessionError('session invalid after a prior failure; protocol-specific recovery required')
        if not math.isfinite(timeout) or timeout <= 0 or type(response_bytes) is not int or response_bytes < 0:
            raise ValueError('positive finite timeout and nonnegative response length required')
        deadline = self.clock() + timeout
        try:
            index = 0
            while index < len(packet):
                if self.clock() >= deadline:
                    raise TimeoutError('transmit deadline expired')
                count = self.transport.write(packet[index:])
                if type(count) is not int or not 0 < count <= len(packet) - index:
                    raise SessionError('transport write made invalid/no progress')
                self.event('tx', packet[index:index + count])
                index += count
            def exact(size):
                data = bytearray()
                while len(data) < size:
                    if self.clock() >= deadline:
                        raise TimeoutError(f'receive deadline expired at {len(data)}/{size} bytes')
                    part = self.transport.read(size - len(data))
                    if len(part) > size - len(data):
                        raise SessionError('transport returned more than requested')
                    self.event('rx', part)
                    data.extend(part)
                return bytes(data)
            if ack_only:
                if not trailer:
                    raise ValueError('ACK delimiter is required')
                line = bytearray()
                while len(line) < 128:
                    line.extend(exact(1))
                    if line.endswith(trailer):
                        if bytes(line) != trailer:
                            raise SessionError(f'error ACK: {bytes(line)!r}')
                        return b''
                raise SessionError('ACK exceeds 128 bytes')
            payload = exact(response_bytes)
            if trailer and exact(len(trailer)) != trailer:
                raise SessionError('invalid trailer after fixed-size payload')
            return payload
        except Exception as error:
            self.invalid = True
            self.event('error', message=str(error))
            raise


def poll(read_value, expected, timeout, clock=time.monotonic, sleep=time.sleep, interval=0.001):
    """Cannot interrupt a hardware bus read that never returns."""
    if not math.isfinite(timeout) or timeout <= 0 or interval < 0:
        raise ValueError('invalid poll deadline/interval')
    deadline = clock() + timeout
    while True:
        if clock() >= deadline:
            raise TimeoutError(f'status did not become {expected!r}')
        value = read_value()
        if value == expected:
            return value
        sleep(interval)
