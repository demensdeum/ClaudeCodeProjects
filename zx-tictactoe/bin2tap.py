#!/usr/bin/env python3
"""Convert a raw Z80 binary to ZX Spectrum .tap file format."""

import struct
import sys

def make_tap(binfile, tapfile, start_addr=0x8000, name="TicTacToe"):
    with open(binfile, 'rb') as f:
        data = f.read()

    code_length = len(data)
    name = name.ljust(10)[:10]  # Pad/truncate to 10 chars

    tap = bytearray()

    # === Header block ===
    header = bytearray()
    header.append(0x00)         # Flag: 0x00 = header
    header.append(0x03)         # Type: 3 = Code
    header.extend(name.encode('ascii'))  # 10-char filename
    header.extend(struct.pack('<H', code_length))   # Data length
    header.extend(struct.pack('<H', start_addr))    # Start address (param1)
    header.extend(struct.pack('<H', 0x8000))        # param2 (unused for code, set to 32768)

    # Calculate checksum for header
    checksum = 0
    for b in header:
        checksum ^= b
    header.append(checksum)

    # TAP block: 2-byte length prefix + data
    tap.extend(struct.pack('<H', len(header)))
    tap.extend(header)

    # === Data block ===
    datablock = bytearray()
    datablock.append(0xFF)      # Flag: 0xFF = data
    datablock.extend(data)

    # Calculate checksum for data block
    checksum = 0
    for b in datablock:
        checksum ^= b
    datablock.append(checksum)

    # TAP block: 2-byte length prefix + data
    tap.extend(struct.pack('<H', len(datablock)))
    tap.extend(datablock)

    with open(tapfile, 'wb') as f:
        f.write(tap)

    print(f"Created {tapfile}: {code_length} bytes of code at ${start_addr:04X}")

if __name__ == '__main__':
    make_tap('tictactoe.bin', 'tictactoe.tap')
