# Giải mã script Lua của client 2026 (Interface/**/*.lua). Đọc từ Game.exe 3.71 (bản dựng 9509, VA bản 9509 ghi
# cạnh từng bước; hàm kiểm dấu hiệu là FUN_1406df040 của bản 30/09, hàm giải là FUN_1406deb20):
#  - Tệp mang dấu hiệu D2 D1 E2 E1 B2 B1 C2 C1 ở byte 0 và dài hơn 0x100 byte. Đầu 0x100 byte là phần đầu của tệp:
#    byte 0xFC..0xFF là CRC-32 (bảng chuẩn 0xEDB88320, khởi đầu 0xFFFFFFFF, không đảo cuối, dịch phải CÓ DẤU nên
#    byte cao điền 1 khi bit 31 đặt) của 252 byte đầu. Mã đo: 222 trên 222 script có dấu hiệu của Interface.axp khớp.
#  - Văn bản bắt đầu ở 0x100. 24 byte đầu của văn bản là MỘT khối Rijndael 192 bit (cỡ khối 24 byte, khoá 24 byte,
#    12 vòng) giải bằng khoá "ASDRTFYUIOGHJKLm" cộng 8 byte 0: chuỗi khoá nằm ở VA 0x140fbad4f + 3 (16 byte), hàm đặt
#    khoá FUN_1406dfdc0 nhận độ dài 0x18. Phần còn lại của văn bản XOR với "AS" luân phiên, 'A' ở byte đầu tiên sau
#    24 byte đó (cùng chẵn lẻ với vị trí trong tệp, nên cũng là khoá "AS" theo vị trí tệp).
#  - Tệp không mang dấu hiệu là script chưa mã hoá: chép nguyên.
# Văn bản là GBK, giữ nguyên byte (xuống dòng CRLF của gốc).
import struct

MAGIC = bytes.fromhex("d2d1e2e1b2b1c2c1")
TEXT_AT = 0x100
CRC_AT = 0xFC
BLOCK = 24
KEY = b"ASDRTFYUIOGHJKLm" + bytes(8)
XOR_KEY = b"AS"
ROUNDS = 12
WORDS = 6


def _xtime(a: int) -> int:
    a <<= 1
    return (a ^ 0x11B) & 0xFF if a & 0x100 else a


def _gf_mul(a: int, b: int) -> int:
    out = 0
    while b:
        if b & 1:
            out ^= a
        a = _xtime(a)
        b >>= 1
    return out


def _make_sbox() -> tuple[list[int], list[int]]:
    # S-box chuẩn của Rijndael: nghịch đảo trong GF(2^8), rồi phép affine.
    sbox = [0] * 256
    for value in range(256):
        inv = 0
        if value:
            inv = next(candidate for candidate in range(1, 256) if _gf_mul(value, candidate) == 1)
        out = 0x63
        for shift in range(5):
            out ^= ((inv << shift) | (inv >> (8 - shift))) & 0xFF
        sbox[value] = out
    inverse = [0] * 256
    for value, mapped in enumerate(sbox):
        inverse[mapped] = value
    return sbox, inverse


SBOX, INV_SBOX = _make_sbox()
MUL = {factor: [_gf_mul(value, factor) for value in range(256)] for factor in (9, 11, 13, 14)}


def _expand_key(key: bytes) -> list[list[int]]:
    words = [list(key[4 * i:4 * i + 4]) for i in range(6)]
    rcon = 1
    for i in range(6, WORDS * (ROUNDS + 1)):
        temp = list(words[i - 1])
        if i % 6 == 0:
            temp = [SBOX[temp[1]] ^ rcon, SBOX[temp[2]], SBOX[temp[3]], SBOX[temp[0]]]
            rcon = _xtime(rcon)
        words.append([words[i - 6][j] ^ temp[j] for j in range(4)])
    return words


ROUND_KEYS = _expand_key(KEY)
# Rijndael cỡ khối 192 bit: hàng 1, 2, 3 lệch 1, 2, 3 cột.
SHIFTS = (0, 1, 2, 3)


def _add_round_key(state: list[int], round_number: int) -> None:
    for column in range(WORDS):
        word = ROUND_KEYS[round_number * WORDS + column]
        for row in range(4):
            state[4 * column + row] ^= word[row]


def _inv_shift_rows(state: list[int]) -> list[int]:
    out = [0] * 24
    for column in range(WORDS):
        for row in range(4):
            out[4 * ((column + SHIFTS[row]) % WORDS) + row] = state[4 * column + row]
    return out


def _inv_mix_columns(state: list[int]) -> None:
    for column in range(WORDS):
        a = state[4 * column:4 * column + 4]
        state[4 * column + 0] = MUL[14][a[0]] ^ MUL[11][a[1]] ^ MUL[13][a[2]] ^ MUL[9][a[3]]
        state[4 * column + 1] = MUL[9][a[0]] ^ MUL[14][a[1]] ^ MUL[11][a[2]] ^ MUL[13][a[3]]
        state[4 * column + 2] = MUL[13][a[0]] ^ MUL[9][a[1]] ^ MUL[14][a[2]] ^ MUL[11][a[3]]
        state[4 * column + 3] = MUL[11][a[0]] ^ MUL[13][a[1]] ^ MUL[9][a[2]] ^ MUL[14][a[3]]


def decrypt_block(block: bytes) -> bytes:
    """Giải một khối 24 byte (Rijndael cỡ khối 192, khoá 192, 12 vòng)."""
    if len(block) != BLOCK:
        raise ValueError("khối phải 24 byte")
    state = list(block)
    _add_round_key(state, ROUNDS)
    for round_number in range(ROUNDS - 1, 0, -1):
        state = _inv_shift_rows(state)
        state = [INV_SBOX[value] for value in state]
        _add_round_key(state, round_number)
        _inv_mix_columns(state)
    state = _inv_shift_rows(state)
    state = [INV_SBOX[value] for value in state]
    _add_round_key(state, 0)
    return bytes(state)


def _crc(head: bytes) -> int:
    table = []
    for i in range(256):
        c = i
        for _ in range(8):
            c = (c >> 1) ^ (0xEDB88320 if c & 1 else 0)
        table.append(c)
    crc = 0xFFFFFFFF
    for byte in head:
        shifted = (crc >> 8) | (0xFF000000 if crc & 0x80000000 else 0)
        crc = table[(byte ^ crc) & 0xFF] ^ shifted
    return crc


def is_encoded(data: bytes) -> bool:
    return len(data) > TEXT_AT and data.startswith(MAGIC)


def decode(data: bytes) -> bytes:
    """Văn bản script (GBK, byte nguyên). Tệp chưa mã hoá được trả nguyên; tệp mã hoá mà CRC đầu sai hay quá ngắn thì lỗi."""
    if not is_encoded(data):
        return data
    if len(data) < TEXT_AT + BLOCK:
        raise ValueError("script mã hoá nhưng ngắn hơn 0x100 + 24 byte")
    stored = struct.unpack_from("<I", data, CRC_AT)[0]
    if _crc(data[:CRC_AT]) != stored:
        raise ValueError("CRC đầu script sai")
    body = data[TEXT_AT:]
    head = decrypt_block(body[:BLOCK])
    tail = bytes(byte ^ XOR_KEY[index % 2] for index, byte in enumerate(body[BLOCK:]))
    return head + tail
