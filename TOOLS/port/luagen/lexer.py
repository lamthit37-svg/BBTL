"""Bộ tách từ của phương ngữ LuaPlus 5.0.1 (client 2026): port từ llex.c của Lua 5.0.1, cộng hai chỗ LuaPlus thêm,
đã đo trên LuaPlus.dll ngày 2026-10-15:

- `continue` là từ khoá (báo "<name> expected" khi dùng làm tên).
- Số nguyên hệ 16 `0x...` (chỉ chữ `x` thường; tối đa 8 chữ số hex, giá trị cắt về int32: 0xffffffff ra -1;
  `0x100000000` tách thành 0x10000000 rồi số `0`).
Các điểm giữ nguyên của Lua 5.0.1: không có `#`, `%`, `!=`, `+=`, `;` đứng riêng; chuỗi dài `[[ ]]` lồng nhau;
`1..2` là lỗi mơ hồ; mã thập phân `\\ddd` tối đa ba chữ số, lớn hơn 255 là lỗi; dòng đầu bắt đầu bằng `#` bị bỏ.

Nguồn là byte (UTF-8 của tệp script). Byte >= 0x80 ngoài chuỗi và chú thích: LuaPlus.dll tra bảng ctype bằng chỉ số âm nên
kết quả lung tung theo từng byte (có byte làm văn bản đổ vỡ), không có nghĩa xác định; bộ tách từ báo lỗi thay vì đoán.
"""

from __future__ import annotations

from dataclasses import dataclass

RESERVED = frozenset(
    "and break continue do else elseif end false for function if in local nil not or repeat return then true until while".split()
)
WHITESPACE = frozenset(b"\t\n\v\f\r ")
DIGITS = frozenset(b"0123456789")
HEX_DIGITS = frozenset(b"0123456789abcdefABCDEF")
NAME_START = frozenset(b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
NAME_BODY = NAME_START | DIGITS
# Các escape một ký tự trong chuỗi: a b f n r t v (BEL, BS, FF, LF, CR, TAB, VT).
SIMPLE_ESCAPES = {0x61: 7, 0x62: 8, 0x66: 12, 0x6E: 10, 0x72: 13, 0x74: 9, 0x76: 11}
# Số chữ số hex LuaPlus đọc sau `0x`.
MAX_HEX_DIGITS = 8

# Loại token: tên từ khoá, ký tự đơn, hoặc một trong các loại dưới.
NAME = "<name>"
NUMBER = "<number>"
STRING = "<string>"
EOS = "<eof>"
CONCAT = ".."
DOTS = "..."
EQ = "=="
GE = ">="
LE = "<="
NE = "~="


class LuaSyntaxError(Exception):
    """Lỗi cú pháp: câu lỗi có dạng của Lua ("chunk:dòng: lỗi near `token'")."""

    def __init__(self, chunk: str, line: int, message: str, near: str) -> None:
        super().__init__(f"{chunk}:{line}: {message} near `{near}'")
        self.chunk = chunk
        self.line = line
        self.message = message
        self.near = near


@dataclass(slots=True)
class Token:
    kind: str
    # NAME: str; NUMBER: float; STRING: bytes; còn lại None.
    value: object
    # Văn bản nguồn của token (cho câu lỗi "near").
    text: str


def _text(data: bytes) -> str:
    return data.decode("utf-8", errors="replace")


class Lexer:
    def __init__(self, source: bytes, chunk: str) -> None:
        self.src = source
        self.chunk = chunk
        self.pos = 0
        self.linenumber = 1
        # Như luaX_setinput: dòng đầu bắt đầu bằng `#` bị bỏ qua.
        if source[:1] == b"#":
            while self.pos < len(source) and source[self.pos] != 0x0A:
                self.pos += 1

    # ---- tiện ích ----
    def error(self, message: str, near: str, line: int | None = None) -> LuaSyntaxError:
        return LuaSyntaxError(self.chunk, self.linenumber if line is None else line, message, near)

    def _current(self) -> int:
        """Byte hiện tại, -1 ở hết dữ liệu (EOZ)."""
        return self.src[self.pos] if self.pos < len(self.src) else -1

    def _peek(self, offset: int) -> int:
        index = self.pos + offset
        return self.src[index] if index < len(self.src) else -1

    # ---- chuỗi dài và chú thích dài ----
    def _read_long(self, is_string: bool) -> bytes | None:
        """Đọc thân `[[ ... ]]` (đã ở sau cặp `[[` đầu). Trả nội dung nếu là chuỗi. Lồng nhau theo cặp `[[` và `]]`."""
        src = self.src
        pos = self.pos
        if pos < len(src) and src[pos] == 0x0A:
            self.linenumber += 1
            pos += 1
        begin = pos
        nesting = 0
        size = len(src)
        while True:
            if pos >= size:
                self.pos = pos
                raise self.error("unfinished long string" if is_string else "unfinished long comment", EOS)
            byte = src[pos]
            if byte == 0x5B:  # [
                pos += 1
                if pos < size and src[pos] == 0x5B:
                    nesting += 1
                    pos += 1
                continue
            if byte == 0x5D:  # ]
                pos += 1
                if pos < size and src[pos] == 0x5D:
                    if nesting == 0:
                        end = pos - 1
                        self.pos = pos + 1
                        return src[begin:end] if is_string else None
                    nesting -= 1
                    pos += 1
                continue
            if byte == 0x0A:
                self.linenumber += 1
            pos += 1

    # ---- chuỗi ngắn ----
    def _read_string(self, delimiter: int) -> bytes:
        src = self.src
        size = len(src)
        pos = self.pos + 1
        start = self.pos
        out = bytearray()
        while True:
            if pos >= size:
                self.pos = pos
                raise self.error("unfinished string", EOS)
            byte = src[pos]
            if byte == delimiter:
                pos += 1
                break
            if byte == 0x0A:
                self.pos = pos
                raise self.error("unfinished string", _text(src[start:pos]))
            if byte == 0x5C:  # backslash
                pos += 1
                if pos >= size:
                    continue  # EOZ: vòng sau báo lỗi chưa đóng chuỗi
                escape = src[pos]
                if escape in SIMPLE_ESCAPES:
                    out.append(SIMPLE_ESCAPES[escape])
                    pos += 1
                elif escape == 0x0A:
                    out.append(0x0A)
                    self.linenumber += 1
                    pos += 1
                elif escape not in DIGITS:
                    out.append(escape)  # \\, \", \', \? và mọi ký tự khác
                    pos += 1
                else:
                    code = 0
                    count = 0
                    while True:
                        code = 10 * code + (src[pos] - 0x30)
                        pos += 1
                        count += 1
                        if not (count < 3 and pos < size and src[pos] in DIGITS):
                            break
                    if code > 255:
                        self.pos = pos
                        raise self.error("escape sequence too large", _text(src[start:pos]))
                    out.append(code)
                continue
            out.append(byte)
            pos += 1
        self.pos = pos
        return bytes(out)

    # ---- số ----
    def _read_number(self, leading_dot: bool) -> float:
        src = self.src
        size = len(src)
        start = self.pos - 1 if leading_dot else self.pos
        pos = self.pos
        # Hệ 16 của LuaPlus.
        if not leading_dot and src[pos] == 0x30 and pos + 1 < size and src[pos + 1] == 0x78:
            pos += 2
            digits_start = pos
            while pos < size and pos - digits_start < MAX_HEX_DIGITS and src[pos] in HEX_DIGITS:
                pos += 1
            self.pos = pos
            if pos == digits_start:
                raise self.error("malformed integer", _text(src[start:pos]))
            value = int(src[digits_start:pos], 16) & 0xFFFFFFFF
            if value >= 0x80000000:
                value -= 0x100000000
            return float(value)
        while pos < size and src[pos] in DIGITS:
            pos += 1
        if pos < size and src[pos] == 0x2E:  # .
            pos += 1
            if pos < size and src[pos] == 0x2E:
                pos += 1
                self.pos = pos
                raise self.error("ambiguous syntax (decimal point x string concatenation)", _text(src[start:pos]))
        while pos < size and src[pos] in DIGITS:
            pos += 1
        if pos < size and src[pos] in (0x65, 0x45):  # e E
            pos += 1
            if pos < size and src[pos] in (0x2B, 0x2D):
                pos += 1
            while pos < size and src[pos] in DIGITS:
                pos += 1
        self.pos = pos
        text = _text(src[start:pos])
        try:
            return float(text)
        except ValueError:
            raise self.error("malformed number", text) from None

    # ---- token kế ----
    def lex(self) -> Token:
        src = self.src
        size = len(src)
        while True:
            if self.pos >= size:
                return Token(EOS, None, EOS)
            byte = src[self.pos]
            if byte == 0x0A:
                self.linenumber += 1
                self.pos += 1
                continue
            if byte in WHITESPACE:
                self.pos += 1
                continue
            if byte == 0x2D:  # -
                if self._peek(1) != 0x2D:
                    self.pos += 1
                    return Token("-", None, "-")
                self.pos += 2
                if self._current() == 0x5B and self._peek(1) == 0x5B:
                    self.pos += 2
                    self._read_long(False)
                else:
                    # `--[` rồi không phải `[`: llex.c đã nuốt `[`, nhưng đó cũng là chú thích ngắn nên không khác.
                    while self.pos < size and src[self.pos] != 0x0A:
                        self.pos += 1
                continue
            if byte == 0x5B:  # [
                if self._peek(1) != 0x5B:
                    self.pos += 1
                    return Token("[", None, "[")
                begin = self.pos
                self.pos += 2
                text = self._read_long(True)
                assert text is not None
                return Token(STRING, text, _text(src[begin:self.pos]))
            if byte in (0x3D, 0x3C, 0x3E, 0x7E):  # = < > ~
                two = {0x3D: EQ, 0x3C: LE, 0x3E: GE, 0x7E: NE}[byte]
                if self._peek(1) == 0x3D:
                    self.pos += 2
                    return Token(two, None, two)
                self.pos += 1
                char = chr(byte)
                return Token(char, None, char)
            if byte in (0x22, 0x27):  # " '
                begin = self.pos
                value = self._read_string(byte)
                return Token(STRING, value, _text(src[begin:self.pos]))
            if byte == 0x2E:  # .
                following = self._peek(1)
                if following == 0x2E:
                    if self._peek(2) == 0x2E:
                        self.pos += 3
                        return Token(DOTS, None, DOTS)
                    self.pos += 2
                    return Token(CONCAT, None, CONCAT)
                if following not in DIGITS:
                    self.pos += 1
                    return Token(".", None, ".")
                begin = self.pos
                self.pos += 1
                number = self._read_number(True)
                return Token(NUMBER, number, _text(src[begin:self.pos]))
            if byte in DIGITS:
                begin = self.pos
                number = self._read_number(False)
                return Token(NUMBER, number, _text(src[begin:self.pos]))
            if byte in NAME_START:
                begin = self.pos
                self.pos += 1
                while self.pos < size and src[self.pos] in NAME_BODY:
                    self.pos += 1
                word = _text(src[begin:self.pos])
                if word in RESERVED:
                    return Token(word, None, word)
                return Token(NAME, word, word)
            if byte < 0x20 or byte >= 0x7F:
                self.pos += 1
                if byte >= 0x80:
                    raise self.error("invalid byte outside string or comment", f"byte({byte})")
                raise self.error("invalid control char", f"char({byte})")
            self.pos += 1
            char = chr(byte)
            return Token(char, None, char)
