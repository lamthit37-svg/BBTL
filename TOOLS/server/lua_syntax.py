"""Bộ đọc cú pháp Lua 4.0 (chỉ đọc tĩnh, không chạy script).

Dùng cho lua_extract.py: biến script Lua của máy chủ 14 môn phái thành cây cú pháp để rút dữ liệu
thành bảng TSV. Lua 4.0 khác bản 5: vòng `for k, v in tbl do`, không có `%`, không có `goto`,
hàm không có dấu ba chấm. Bộ đọc nhận thêm `!=` vì script của nhà phát hành riêng có dùng.
Mọi lỗi cú pháp thành LuaSyntaxError kèm số dòng; không bao giờ đoán để đọc tiếp.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

KEYWORDS = frozenset(
    "and break do else elseif end for function if in local nil not or repeat return then until while".split()
)
_TOKEN = re.compile(
    r"""
    (?P<space>[ \t\r\f\v]+)
  | (?P<newline>\n)
  | (?P<longcomment>--\[\[.*?\]\])
  | (?P<comment>--[^\n]*)
  | (?P<longstring>\[\[.*?\]\])
  | (?P<number>0[xX][0-9a-fA-F]+|\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?)
  | (?P<name>[A-Za-z_][A-Za-z_0-9]*)
  | (?P<string>"(?:[^"\\\n]|\\.|\\\n)*"|'(?:[^'\\\n]|\\.|\\\n)*')
  | (?P<op>\.\.\.|\.\.|==|~=|!=|<=|>=|[-+*/^<>=(){}\[\];:,.%])
    """,
    re.VERBOSE | re.DOTALL,
)
_ESCAPES = {"a": "\a", "b": "\b", "f": "\f", "n": "\n", "r": "\r", "t": "\t", "v": "\v"}
_ESCAPE = re.compile(r"\\(\d{1,3}|\n|.)", re.DOTALL)


class LuaSyntaxError(ValueError):
    """Sai cú pháp; thông báo có số dòng."""


@dataclass(frozen=True)
class Token:
    kind: str
    value: str
    line: int


@dataclass(frozen=True)
class Num:
    value: float


@dataclass(frozen=True)
class Str:
    value: str


@dataclass(frozen=True)
class Nil:
    pass


@dataclass(frozen=True)
class Name:
    id: str


@dataclass(frozen=True)
class Index:
    obj: object
    key: object


@dataclass(frozen=True)
class Call:
    fn: object
    args: tuple
    line: int


@dataclass(frozen=True)
class BinOp:
    op: str
    left: object
    right: object


@dataclass(frozen=True)
class UnOp:
    op: str
    operand: object


@dataclass(frozen=True)
class Table:
    items: tuple  # mỗi phần tử (khoá hoặc None, giá trị)


@dataclass(frozen=True)
class Local:
    names: tuple
    values: tuple
    line: int


@dataclass(frozen=True)
class Assign:
    targets: tuple
    values: tuple
    line: int


@dataclass(frozen=True)
class CallStmt:
    call: Call


@dataclass(frozen=True)
class If:
    arms: tuple  # mỗi phần tử (điều kiện, khối)
    orelse: tuple | None
    line: int


@dataclass(frozen=True)
class While:
    cond: object
    body: tuple
    line: int


@dataclass(frozen=True)
class Repeat:
    body: tuple
    cond: object
    line: int


@dataclass(frozen=True)
class ForNum:
    var: str
    start: object
    stop: object
    step: object
    body: tuple
    line: int


@dataclass(frozen=True)
class ForIn:
    key: str
    value: str | None
    source: object
    body: tuple
    line: int


@dataclass(frozen=True)
class Return:
    values: tuple
    line: int


@dataclass(frozen=True)
class Break:
    line: int


@dataclass(frozen=True)
class Do:
    body: tuple


@dataclass(frozen=True)
class FuncDef:
    name: str
    params: tuple
    body: tuple
    line: int


def _unescape(raw: str) -> str:
    def swap(match: re.Match[str]) -> str:
        body = match.group(1)
        if body.isdigit():
            return chr(int(body))
        return _ESCAPES.get(body, body)

    return _ESCAPE.sub(swap, raw)


def tokenize(text: str) -> list[Token]:
    """Tách token. Chú thích và khoảng trắng bị bỏ; dòng đếm từ 1."""
    tokens: list[Token] = []
    position = 0
    line = 1
    end = len(text)
    while position < end:
        match = _TOKEN.match(text, position)
        if match is None:
            raise LuaSyntaxError(f"dòng {line}: ký tự lạ {text[position]!r}")
        kind = match.lastgroup or ""
        raw = match.group()
        position = match.end()
        if kind in ("space", "comment"):
            continue
        if kind in ("newline", "longcomment"):
            line += raw.count("\n")
            continue
        tokens.append(_make_token(kind, raw, line))
        line += raw.count("\n")
    tokens.append(Token("eof", "", line))
    return tokens


def _make_token(kind: str, raw: str, line: int) -> Token:
    if kind == "string":
        return Token("str", _unescape(raw[1:-1]), line)
    if kind == "longstring":
        return Token("str", raw[2:-2], line)
    if kind == "number":
        return Token("num", raw, line)
    if kind == "name" and raw in KEYWORDS:
        return Token("kw", raw, line)
    if kind == "op" and raw == "!=":
        return Token("op", "~=", line)
    return Token(kind, raw, line)


_BINARY = {
    "or": (1, 1),
    "and": (2, 2),
    "<": (3, 3),
    ">": (3, 3),
    "<=": (3, 3),
    ">=": (3, 3),
    "~=": (3, 3),
    "==": (3, 3),
    "..": (5, 4),
    "+": (6, 6),
    "-": (6, 6),
    "*": (7, 7),
    "/": (7, 7),
    "^": (10, 9),
}
_UNARY_PRIORITY = 8
_BLOCK_END = frozenset({"end", "else", "elseif", "until"})
MAX_DEPTH = 120


class Parser:
    """Phân tích đệ quy; độ sâu có trần để script thù địch không làm tràn ngăn xếp."""

    def __init__(self, tokens: list[Token]) -> None:
        self.tokens = tokens
        self.at = 0
        self.depth = 0

    def peek(self) -> Token:
        return self.tokens[self.at]

    def advance(self) -> Token:
        token = self.tokens[self.at]
        if token.kind != "eof":
            self.at += 1
        return token

    def is_word(self, value: str) -> bool:
        token = self.peek()
        return token.kind in ("kw", "op") and token.value == value

    def accept(self, value: str) -> bool:
        if self.is_word(value):
            self.advance()
            return True
        return False

    def expect(self, value: str) -> Token:
        token = self.peek()
        if not self.is_word(value):
            raise LuaSyntaxError(f"dòng {token.line}: cần '{value}', gặp '{token.value}'")
        return self.advance()

    def expect_name(self) -> Token:
        token = self.peek()
        if token.kind != "name":
            raise LuaSyntaxError(f"dòng {token.line}: cần tên, gặp '{token.value}'")
        return self.advance()

    def enter(self) -> None:
        self.depth += 1
        if self.depth > MAX_DEPTH:
            raise LuaSyntaxError(f"dòng {self.peek().line}: lồng quá {MAX_DEPTH} mức")

    def leave(self) -> None:
        self.depth -= 1

    # --- biểu thức ---
    def expression(self, limit: int = 0) -> object:
        self.enter()
        token = self.peek()
        if self.is_word("not") or self.is_word("-"):
            self.advance()
            node: object = UnOp(token.value, self.expression(_UNARY_PRIORITY))
        else:
            node = self.simple()
        while True:
            op = self.peek()
            rule = _BINARY.get(op.value) if op.kind in ("kw", "op") else None
            if rule is None or rule[0] <= limit:
                break
            self.advance()
            node = BinOp(op.value, node, self.expression(rule[1]))
        self.leave()
        return node

    def simple(self) -> object:
        token = self.peek()
        if token.kind == "num":
            self.advance()
            return Num(_number(token))
        if token.kind == "str":
            self.advance()
            return Str(token.value)
        if self.accept("nil"):
            return Nil()
        if self.is_word("{"):
            return self.table()
        if self.is_word("function"):
            raise LuaSyntaxError(f"dòng {token.line}: hàm vô danh không được hỗ trợ")
        return self.suffixed()

    def primary(self) -> object:
        token = self.peek()
        if token.kind == "op" and token.value == "%":
            # Lua 4.0: %tên là biến ngoài (upvalue); với bộ đánh giá từng phần nó chỉ là tên đó.
            self.advance()
            token = self.peek()
        if token.kind == "name":
            self.advance()
            return Name(token.value)
        if self.accept("("):
            inner = self.expression()
            self.expect(")")
            return inner
        raise LuaSyntaxError(f"dòng {token.line}: biểu thức lạ '{token.value}'")

    def suffixed(self) -> object:
        node = self.primary()
        while True:
            token = self.peek()
            if self.accept("."):
                node = Index(node, Str(self.expect_name().value))
            elif self.accept("["):
                key = self.expression()
                self.expect("]")
                node = Index(node, key)
            elif self.accept(":"):
                name = self.expect_name().value
                node = Call(Index(node, Str(name)), (node, *self.call_args()), token.line)
            elif self.is_word("(") or self.is_word("{") or token.kind == "str":
                node = Call(node, self.call_args(), token.line)
            else:
                return node

    def call_args(self) -> tuple:
        token = self.peek()
        if token.kind == "str":
            self.advance()
            return (Str(token.value),)
        if self.is_word("{"):
            return (self.table(),)
        self.expect("(")
        args: list[object] = []
        if not self.is_word(")"):
            args.append(self.expression())
            while self.accept(","):
                args.append(self.expression())
        self.expect(")")
        return tuple(args)

    def table(self) -> Table:
        self.expect("{")
        items: list[tuple[object, object]] = []
        while not self.is_word("}"):
            items.append(self.table_item())
            if not (self.accept(",") or self.accept(";")):
                break
        self.expect("}")
        return Table(tuple(items))

    def table_item(self) -> tuple[object, object]:
        token = self.peek()
        following = self.tokens[self.at + 1]
        if token.kind == "name" and following.value == "=" and following.kind == "op":
            self.advance()
            self.advance()
            return (Str(token.value), self.expression())
        if self.accept("["):
            key = self.expression()
            self.expect("]")
            self.expect("=")
            return (key, self.expression())
        return (None, self.expression())

    # --- câu lệnh ---
    def block(self) -> tuple:
        self.enter()
        body: list[object] = []
        while True:
            token = self.peek()
            if token.kind == "eof" or (token.kind == "kw" and token.value in _BLOCK_END):
                break
            if self.accept(";"):
                continue
            body.append(self.statement())
        self.leave()
        return tuple(body)

    def statement(self) -> object:
        token = self.peek()
        if token.kind == "kw":
            handler = _STATEMENTS.get(token.value)
            if handler is not None:
                return handler(self)
        return self.expression_statement()

    def expression_statement(self) -> object:
        line = self.peek().line
        first = self.suffixed()
        targets = [first]
        while self.accept(","):
            targets.append(self.suffixed())
        if self.accept("="):
            return Assign(tuple(targets), self.expression_list(), line)
        if len(targets) == 1 and isinstance(first, Call):
            return CallStmt(first)
        raise LuaSyntaxError(f"dòng {line}: câu lệnh không hợp lệ")

    def expression_list(self) -> tuple:
        values = [self.expression()]
        while self.accept(","):
            values.append(self.expression())
        return tuple(values)

    def st_local(self) -> Local:
        line = self.advance().line
        names = [self.expect_name().value]
        while self.accept(","):
            names.append(self.expect_name().value)
        values = self.expression_list() if self.accept("=") else ()
        return Local(tuple(names), values, line)

    def st_if(self) -> If:
        line = self.advance().line
        arms = []
        cond = self.expression()
        self.expect("then")
        arms.append((cond, self.block()))
        orelse = None
        while True:
            if self.accept("elseif"):
                cond = self.expression()
                self.expect("then")
                arms.append((cond, self.block()))
            elif self.accept("else"):
                orelse = self.block()
                self.expect("end")
                break
            else:
                self.expect("end")
                break
        return If(tuple(arms), orelse, line)

    def st_while(self) -> While:
        line = self.advance().line
        cond = self.expression()
        self.expect("do")
        body = self.block()
        self.expect("end")
        return While(cond, body, line)

    def st_repeat(self) -> Repeat:
        line = self.advance().line
        body = self.block()
        self.expect("until")
        return Repeat(body, self.expression(), line)

    def st_for(self) -> object:
        line = self.advance().line
        first = self.expect_name().value
        if self.accept("="):
            start = self.expression()
            self.expect(",")
            stop = self.expression()
            step = self.expression() if self.accept(",") else Num(1)
            self.expect("do")
            body = self.block()
            self.expect("end")
            return ForNum(first, start, stop, step, body, line)
        second = self.expect_name().value if self.accept(",") else None
        self.expect("in")
        source = self.expression()
        self.expect("do")
        body = self.block()
        self.expect("end")
        return ForIn(first, second, source, body, line)

    def st_function(self) -> FuncDef:
        line = self.advance().line
        name = self.expect_name().value
        while self.accept("."):
            name += "." + self.expect_name().value
        self.expect("(")
        params: list[str] = []
        if not self.is_word(")"):
            params.append(self.expect_name().value)
            while self.accept(","):
                params.append(self.expect_name().value)
        self.expect(")")
        body = self.block()
        self.expect("end")
        return FuncDef(name, tuple(params), body, line)

    def st_return(self) -> Return:
        line = self.advance().line
        token = self.peek()
        ends = token.kind == "eof" or (token.kind == "kw" and token.value in _BLOCK_END) or self.is_word(";")
        values = () if ends else self.expression_list()
        self.accept(";")
        return Return(values, line)

    def st_break(self) -> Break:
        line = self.advance().line
        self.accept(";")
        return Break(line)

    def st_do(self) -> Do:
        self.advance()
        body = self.block()
        self.expect("end")
        return Do(body)


_STATEMENTS = {
    "local": Parser.st_local,
    "if": Parser.st_if,
    "while": Parser.st_while,
    "repeat": Parser.st_repeat,
    "for": Parser.st_for,
    "function": Parser.st_function,
    "return": Parser.st_return,
    "break": Parser.st_break,
    "do": Parser.st_do,
}


def _number(token: Token) -> float:
    text = token.value
    try:
        if text[:2] in ("0x", "0X"):
            return float(int(text, 16))
        return float(text)
    except ValueError as exc:
        raise LuaSyntaxError(f"dòng {token.line}: số lạ {text}") from exc


def parse(text: str) -> tuple:
    """Cây cú pháp của cả tệp: một khối câu lệnh."""
    parser = Parser(tokenize(text))
    body = parser.block()
    token = parser.peek()
    if token.kind != "eof":
        raise LuaSyntaxError(f"dòng {token.line}: thừa '{token.value}' ở mức tệp")
    return body


def decode(data: bytes) -> str:
    """Script là GBK; byte hỏng thành dấu thay thế chứ không làm hỏng cả tệp."""
    return data.decode("gb18030", errors="replace").replace("\r\n", "\n").replace("\r", "\n").lstrip("\ufeff")
