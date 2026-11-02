"""No serial port: demonstrate LF inside fixed-length binary data and a short transfer."""
import argparse
import json
from bounded_io import Session


class Transport:
    def __init__(self, response):
        self.response, self.sent = bytearray(response), bytearray()
    def read(self, size):
        part = bytes(self.response[:min(size, 1)])
        del self.response[:len(part)]
        return part
    def write(self, data):
        count = min(len(data), 3)
        self.sent.extend(data[:count])
        return count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--short', action='store_true')
    args = parser.parse_args()
    ticks = [0.0]
    def clock():
        ticks[0] += 0.001
        return ticks[0]
    io = Transport(b'\x0a\x00' if args.short else b'\x0a\x00\x00\x80\n')
    session = Session(io, clock=clock)
    try:
        payload = session.transfer(b'Read 0 2\n', 4, 0.05, trailer=b'\n')
        print(json.dumps(dict(mode='MOCK ONLY', payload_hex=payload.hex(), sent_hex=io.sent.hex())))
    except TimeoutError:
        print(json.dumps(dict(mode='MOCK ONLY', outcome='EXPECTED_SHORT_PACKET_TIMEOUT', invalid=session.invalid)))
        raise SystemExit(1)
