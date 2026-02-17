#!/usr/bin/env python3
"""Create a complete .tap file with BASIC loader + machine code for ZX Spectrum."""

import struct

def xor_checksum(data):
    cs = 0
    for b in data:
        cs ^= b
    return cs

def make_tap_block(flag, data):
    """Create a TAP block: length(2) + flag(1) + data + checksum(1)"""
    block = bytearray()
    block.append(flag)
    block.extend(data)
    cs = xor_checksum(block)
    block.append(cs)
    result = struct.pack('<H', len(block))
    return result + bytes(block)

def make_basic_line(line_num, tokens):
    """Create a BASIC line: line_num(2BE) + length(2LE) + tokens + 0x0D"""
    line = bytearray()
    line.extend(tokens)
    line.append(0x0D)
    header = struct.pack('>H', line_num) + struct.pack('<H', len(line))
    return header + line

def number_encoding(n):
    """Encode a number for ZX Spectrum BASIC (ASCII digits + 5-byte float)"""
    result = bytearray()
    result.extend(str(n).encode('ascii'))
    result.append(0x0E)  # Number marker
    # 5-byte floating point encoding for integers
    if n == 0:
        result.extend(b'\x00\x00\x00\x00\x00')
    elif n < 65536:
        result.append(0x00)
        result.append(0x00)
        result.append(n & 0xFF)
        result.append((n >> 8) & 0xFF)
        result.append(0x00)
    return result

def make_loader_tap(code_bin_file, output_tap, name="TicTacToe", start=0x8000):
    with open(code_bin_file, 'rb') as f:
        code_data = f.read()

    code_len = len(code_data)
    tap = bytearray()

    # === BASIC Loader ===
    # 10 CLEAR 32767
    # 20 LOAD ""CODE
    # 30 RANDOMIZE USR 32768

    basic = bytearray()

    # Line 10: CLEAR 32767
    line10 = bytearray()
    line10.append(0xFD)  # CLEAR token
    line10.extend(number_encoding(start - 1))
    basic.extend(make_basic_line(10, line10))

    # Line 20: LOAD ""CODE
    line20 = bytearray()
    line20.append(0xEF)  # LOAD token
    line20.append(0x22)  # "
    line20.append(0x22)  # "
    line20.append(0xAF)  # CODE token
    basic.extend(make_basic_line(20, line20))

    # Line 30: RANDOMIZE USR 32768
    line30 = bytearray()
    line30.append(0xF9)  # RANDOMIZE token
    line30.append(0xC0)  # USR token
    line30.extend(number_encoding(start))
    basic.extend(make_basic_line(30, line30))

    basic_len = len(basic)

    # BASIC header (type 0 = Program)
    header_data = bytearray()
    header_data.append(0x00)  # Type: Program
    header_data.extend(name.ljust(10)[:10].encode('ascii'))
    header_data.extend(struct.pack('<H', basic_len))  # Data length
    header_data.extend(struct.pack('<H', 10))          # Autostart line
    header_data.extend(struct.pack('<H', basic_len))   # Length of program area

    tap.extend(make_tap_block(0x00, header_data))

    # BASIC data block
    tap.extend(make_tap_block(0xFF, basic))

    # === Code block ===
    # Code header (type 3 = Code)
    code_header = bytearray()
    code_header.append(0x03)  # Type: Code
    code_header.extend(name.ljust(10)[:10].encode('ascii'))
    code_header.extend(struct.pack('<H', code_len))
    code_header.extend(struct.pack('<H', start))
    code_header.extend(struct.pack('<H', 0x8000))

    tap.extend(make_tap_block(0x00, code_header))

    # Code data block
    tap.extend(make_tap_block(0xFF, code_data))

    with open(output_tap, 'wb') as f:
        f.write(tap)

    print(f"Created {output_tap}")
    print(f"  BASIC loader: {basic_len} bytes (autostart line 10)")
    print(f"  Machine code: {code_len} bytes at ${start:04X}")
    print(f"  Total TAP size: {len(tap)} bytes")

if __name__ == '__main__':
    make_loader_tap('tictactoe.bin', 'tictactoe.tap')
