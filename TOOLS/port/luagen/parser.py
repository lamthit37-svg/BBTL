"""Bộ phân tích cú pháp phương ngữ LuaPlus 5.0.1: port cấu trúc điều khiển của lparser.c 5.0.1 (cùng thứ tự đọc token,
cùng chỗ nhìn trước một token, cùng cách theo dõi dòng `linenumber`/`lastline` cho lỗi "ambiguous syntax", cùng phạm vi của biến:
vế `until` của `repeat` đứng NGOÀI phạm vi thân vòng; biến vòng `for` nằm ở khối ngoài thân), cộng `continue` của LuaPlus.
Phân giải tên (cục bộ, upvalue, toàn cục) làm ngay lúc dựng cây như singlevaraux.

Điểm đã đo trên LuaPlus.dll: `break` và `continue` phải là câu lệnh cuối của khối (như `return`); `continue` ngoài vòng là lỗi
"no loop to continue"; `...` không phải biểu thức (chỉ có bảng `arg`); dấu `;` đứng riêng là lỗi.
"""

from __future__ import annotations

import sys

from . import tree
from .lexer import (
    CONCAT,
    DOTS,
    EOS,
    EQ,
    GE,
    LE,
    NAME,
    NE,
    NUMBER,
    STRING,
    Lexer,
    LuaSyntaxError,
    Token,
)

# LUA_MAXPARSERLEVEL của llimits.h.
MAX_PARSER_LEVEL = 200

BINARY_OPS = {
    "+": "+", "-": "-", "*": "*", "/": "/", "^": "^", CONCAT: "..", NE: "~=", EQ: "==", "<": "<", LE: "<=", ">": ">",
    GE: ">=", "and": "and", "or": "or",
}
# (ưu tiên trái, ưu tiên phải) của lparser.c.
PRIORITY = {
    "+": (6, 6), "-": (6, 6), "*": (7, 7), "/": (7, 7), "^": (10, 9), "..": (5, 4), "==": (3, 3), "~=": (3, 3), "<": (3, 3),
    "<=": (3, 3), ">": (3, 3), ">=": (3, 3), "and": (2, 2), "or": (1, 1),
}
UNARY_PRIORITY = 8
BLOCK_FOLLOW = frozenset({"else", "elseif", "end", "until", EOS})


class _Block:
    __slots__ = ("nactvar", "breakable")

    def __init__(self, nactvar: int, breakable: bool) -> None:
        self.nactvar = nactvar
        self.breakable = breakable


class _FuncState:
    """FuncState của lparser.c: biến đang hoạt động, các khối, upvalue của một hàm."""

    def __init__(self, func: tree.Func, prev: "_FuncState | None") -> None:
        self.func = func
        self.prev = prev
        self.actvar: list[tree.Var] = []
        self.pending: dict[int, tree.Var] = {}
        self.blocks: list[_Block] = []
        # Khoá ('local', id biến) hay ('upval', chỉ số của hàm cha) sang chỉ số upvalue.
        self.upvalue_index: dict[tuple[str, int], int] = {}


class Parser:
    def __init__(self, source: bytes, chunk: str) -> None:
        self.chunk = chunk
        self.lexer = Lexer(source, chunk)
        self.t: Token = Token(EOS, None, EOS)
        self.lookahead_token: Token | None = None
        self.lastline = 1
        self.nestlevel = 0
        self.fs: _FuncState | None = None
        self.funcs: list[tree.Func] = []

    # ---------------- token ----------------
    def next(self) -> None:
        self.lastline = self.lexer.linenumber
        if self.lookahead_token is not None:
            self.t = self.lookahead_token
            self.lookahead_token = None
        else:
            self.t = self.lexer.lex()

    def lookahead(self) -> Token:
        assert self.lookahead_token is None
        self.lookahead_token = self.lexer.lex()
        return self.lookahead_token

    def syntax_error(self, message: str) -> LuaSyntaxError:
        return LuaSyntaxError(self.chunk, self.lexer.linenumber, message, self.t.text)

    def error_expected(self, kind: str) -> LuaSyntaxError:
        return self.syntax_error(f"`{kind}' expected")

    def testnext(self, kind: str) -> bool:
        if self.t.kind == kind:
            self.next()
            return True
        return False

    def check(self, kind: str) -> None:
        if not self.testnext(kind):
            raise self.error_expected(kind)

    def check_match(self, what: str, who: str, where: int) -> None:
        if not self.testnext(what):
            if where == self.lexer.linenumber:
                raise self.error_expected(what)
            raise self.syntax_error(f"`{what}' expected (to close `{who}' at line {where})")

    def str_checkname(self) -> str:
        if self.t.kind != NAME:
            raise self.syntax_error("<name> expected")
        name = self.t.value
        assert isinstance(name, str)
        self.next()
        return name

    def enterlevel(self) -> None:
        self.nestlevel += 1
        if self.nestlevel > MAX_PARSER_LEVEL:
            raise self.syntax_error("too many syntax levels")

    def leavelevel(self) -> None:
        self.nestlevel -= 1

    # ---------------- biến và phạm vi ----------------
    def new_localvar(self, name: str, n: int) -> None:
        fs = self.fs
        assert fs is not None
        var = tree.Var(name, fs.func, len(fs.func.locals))
        fs.func.locals.append(var)
        fs.pending[n] = var

    def adjustlocalvars(self, nvars: int) -> None:
        fs = self.fs
        assert fs is not None
        for n in range(nvars):
            fs.actvar.append(fs.pending[n])

    def create_local(self, name: str) -> tree.Var:
        self.new_localvar(name, 0)
        self.adjustlocalvars(1)
        fs = self.fs
        assert fs is not None
        return fs.actvar[-1]

    def enterblock(self, breakable: bool) -> None:
        fs = self.fs
        assert fs is not None
        fs.blocks.append(_Block(len(fs.actvar), breakable))

    def leaveblock(self) -> None:
        fs = self.fs
        assert fs is not None
        block = fs.blocks.pop()
        del fs.actvar[block.nactvar:]

    def _search_var(self, fs: _FuncState, name: str) -> tree.Var | None:
        for var in reversed(fs.actvar):
            if var.name == name:
                return var
        return None

    def _index_upvalue(self, fs: _FuncState, name: str, var: tree.Var, parent_var: tree.Var | None,
                       parent_index: int | None) -> int:
        key = ("local", id(parent_var)) if parent_var is not None else ("upval", parent_index if parent_index is not None else -1)
        found = fs.upvalue_index.get(key)
        if found is not None:
            return found
        index = len(fs.func.upvalues)
        fs.func.upvalues.append(tree.Upvalue(name, var, parent_var, parent_index))
        fs.upvalue_index[key] = index
        return index

    def _single_var_aux(self, fs: _FuncState | None, name: str, base: bool):
        """singlevaraux: ('local', var) | ('upval', index, var) | ('global',)."""
        if fs is None:
            return ("global",)
        var = self._search_var(fs, name)
        if var is not None:
            if not base:
                var.captured = True
            return ("local", var)
        found = self._single_var_aux(fs.prev, name, False)
        if found[0] == "global":
            return found
        if found[0] == "local":
            index = self._index_upvalue(fs, name, found[1], found[1], None)
            return ("upval", index, found[1])
        index = self._index_upvalue(fs, name, found[2], None, found[1])
        return ("upval", index, found[2])

    def single_var(self) -> tree.LocalRef | tree.UpvalRef | tree.GlobalRef:
        name = self.str_checkname()
        found = self._single_var_aux(self.fs, name, True)
        if found[0] == "local":
            return tree.LocalRef(found[1])
        if found[0] == "upval":
            return tree.UpvalRef(found[1], found[2])
        return tree.GlobalRef(name)

    # ---------------- hàm ----------------
    def open_func(self, line: int) -> _FuncState:
        parent = self.fs.func if self.fs is not None else None
        func = tree.Func(self.chunk, line, parent, len(self.funcs))
        self.funcs.append(func)
        if parent is not None:
            parent.children.append(func)
        fs = _FuncState(func, self.fs)
        self.fs = fs
        return fs

    def close_func(self) -> None:
        fs = self.fs
        assert fs is not None
        self.fs = fs.prev

    def parlist(self, func: tree.Func) -> None:
        nparams = 0
        dots = False
        if self.t.kind != ")":
            while True:
                if self.t.kind == DOTS:
                    dots = True
                    self.next()
                elif self.t.kind == NAME:
                    self.new_localvar(self.str_checkname(), nparams)
                    nparams += 1
                else:
                    raise self.syntax_error("<name> or `...' expected")
                if dots or not self.testnext(","):
                    break
        # code_params
        fs = self.fs
        assert fs is not None
        self.adjustlocalvars(nparams)
        func.params.extend(fs.actvar[len(fs.actvar) - nparams:] if nparams else [])
        func.is_vararg = dots
        if dots:
            func.arg_var = self.create_local("arg")

    def body(self, needself: bool, line: int) -> tree.Func:
        fs = self.open_func(line)
        func = fs.func
        self.check("(")
        if needself:
            func.params.append(self.create_local("self"))
        self.parlist(func)
        self.check(")")
        func.body = self.chunk_block(open_scope=False)
        self.check_match("end", "function", line)
        self.close_func()
        return func

    # ---------------- biểu thức ----------------
    def explist1(self) -> list[tree.Expr]:
        exprs = [self.expr()]
        while self.testnext(","):
            exprs.append(self.expr())
        return exprs

    def funcargs(self) -> tuple[list[tree.Expr], int]:
        line = self.lexer.linenumber
        kind = self.t.kind
        if kind == "(":
            if line != self.lastline:
                raise self.syntax_error("ambiguous syntax (function call x new statement)")
            self.next()
            args: list[tree.Expr] = []
            if self.t.kind != ")":
                args = self.explist1()
            self.check_match(")", "(", line)
        elif kind == "{":
            args = [self.constructor()]
        elif kind == STRING:
            value = self.t.value
            assert isinstance(value, bytes)
            args = [tree.Str(value)]
            self.next()
        else:
            raise self.syntax_error("function arguments expected")
        return args, line

    def prefixexp(self) -> tree.Expr:
        kind = self.t.kind
        if kind == "(":
            line = self.lexer.linenumber
            self.next()
            inner = self.expr()
            self.check_match(")", "(", line)
            return tree.Paren(inner)
        if kind == NAME:
            return self.single_var()
        raise self.syntax_error("unexpected symbol")

    def primaryexp(self) -> tree.Expr:
        value = self.prefixexp()
        while True:
            kind = self.t.kind
            if kind == ".":
                self.next()
                key = self.str_checkname()
                value = tree.Index(value, tree.Str(key.encode("utf-8")), self.lexer.linenumber)
            elif kind == "[":
                self.next()
                key_expr = self.expr()
                self.check("]")
                value = tree.Index(value, key_expr, self.lexer.linenumber)
            elif kind == ":":
                self.next()
                name = self.str_checkname()
                args, line = self.funcargs()
                value = tree.Method(value, name, args, line)
            elif kind in ("(", STRING, "{"):
                args, line = self.funcargs()
                value = tree.Call(value, args, line)
            else:
                return value

    def simpleexp(self) -> tree.Expr:
        kind = self.t.kind
        if kind == NUMBER:
            number = self.t.value
            assert isinstance(number, float)
            self.next()
            return tree.Num(number)
        if kind == STRING:
            text = self.t.value
            assert isinstance(text, bytes)
            self.next()
            return tree.Str(text)
        if kind == "nil":
            self.next()
            return tree.Nil()
        if kind == "true":
            self.next()
            return tree.TrueE()
        if kind == "false":
            self.next()
            return tree.FalseE()
        if kind == "{":
            return self.constructor()
        if kind == "function":
            self.next()
            return tree.FuncExpr(self.body(False, self.lexer.linenumber))
        return self.primaryexp()

    def subexpr(self, limit: int) -> tuple[tree.Expr, str | None]:
        self.enterlevel()
        kind = self.t.kind
        if kind in ("not", "-"):
            line = self.lexer.linenumber
            self.next()
            operand, _ = self.subexpr(UNARY_PRIORITY)
            left = self._prefix(kind, operand, line)
        else:
            left = self.simpleexp()
        op = BINARY_OPS.get(self.t.kind)
        while op is not None and PRIORITY[op][0] > limit:
            line = self.lexer.linenumber
            self.next()
            right, nextop = self.subexpr(PRIORITY[op][1])
            left = tree.Bin(op, left, right, line)
            op = nextop
        self.leavelevel()
        return left, op

    def _prefix(self, op: str, operand: tree.Expr, line: int) -> tree.Expr:
        """luaK_prefix: `-` trên hằng số gấp ngay lúc dịch (số không giữ dấu dương: 0 - 0 ra +0, đã đo `1/-0` ra +inf)."""
        if op == "-":
            inner = operand
            while isinstance(inner, tree.Paren):
                inner = inner.expr
            if isinstance(inner, tree.Num):
                return tree.Num(0.0 - inner.value if inner.value != 0.0 else 0.0)
        return tree.Un(op, operand, line)

    def expr(self) -> tree.Expr:
        return self.subexpr(-1)[0]

    # ---------------- hàm dựng bảng ----------------
    def constructor(self) -> tree.TableCons:
        line = self.lexer.linenumber
        self.check("{")
        items: list[tree.ListItem | tree.RecordItem] = []
        while True:
            self.testnext(";")
            if self.t.kind == "}":
                break
            kind = self.t.kind
            if kind == NAME:
                if self.lookahead().kind != "=":
                    items.append(tree.ListItem(self.expr()))
                else:
                    name = self.str_checkname()
                    self.check("=")
                    items.append(tree.RecordItem(tree.Str(name.encode("utf-8")), self.expr(), True))
            elif kind == "[":
                self.next()
                key = self.expr()
                self.check("]")
                self.check("=")
                items.append(tree.RecordItem(key, self.expr()))
            else:
                items.append(tree.ListItem(self.expr()))
            if not (self.testnext(",") or self.testnext(";")):
                break
        self.check_match("}", "{", line)
        return tree.TableCons(items, line)

    # ---------------- câu lệnh ----------------
    def block_follow(self) -> bool:
        return self.t.kind in BLOCK_FOLLOW

    def chunk_block(self, open_scope: bool = True) -> tree.Block:
        """chunk -> { stat [`;'] }; open_scope=True là `block` (có khối mới), False là thân hàm (khối do hàm giữ)."""
        if open_scope:
            self.enterblock(False)
        self.enterlevel()
        block = tree.Block()
        islast = False
        while not islast and not self.block_follow():
            statement, islast = self.statement()
            block.stmts.append(statement)
            self.testnext(";")
        self.leavelevel()
        if open_scope:
            self.leaveblock()
        return block

    def block(self) -> tree.Block:
        return self.chunk_block(True)

    def statement(self) -> tuple[tree.Stmt, bool]:
        line = self.lexer.linenumber
        kind = self.t.kind
        if kind == "if":
            return self.ifstat(), False
        if kind == "while":
            return self.whilestat(line), False
        if kind == "do":
            self.next()
            body = self.block()
            self.check_match("end", "do", line)
            return tree.DoStat(body), False
        if kind == "for":
            return self.forstat(line), False
        if kind == "repeat":
            return self.repeatstat(line), False
        if kind == "function":
            return self.funcstat(line), False
        if kind == "local":
            self.next()
            if self.testnext("function"):
                return self.localfunc(), False
            return self.localstat(), False
        if kind == "return":
            return self.retstat(), True
        if kind in ("break", "continue"):
            return self.breakstat(kind), True
        return self.exprstat(), False

    def cond(self) -> tree.Expr:
        return self.expr()

    def whilestat(self, line: int) -> tree.WhileStat:
        self.next()
        cond = self.expr()
        self.enterblock(True)
        self.check("do")
        body = self.block()
        self.check_match("end", "while", line)
        self.leaveblock()
        return tree.WhileStat(cond, body, line)

    def repeatstat(self, line: int) -> tree.RepeatStat:
        self.enterblock(True)
        self.next()
        body = self.block()
        self.check_match("until", "repeat", line)
        cond = self.cond()
        self.leaveblock()
        return tree.RepeatStat(body, cond, line)

    def forbody(self, nvars: int) -> tree.Block:
        self.adjustlocalvars(nvars)
        self.check("do")
        self.enterblock(True)
        body = self.block()
        self.leaveblock()
        return body

    def forstat(self, line: int) -> tree.Stmt:
        self.enterblock(False)
        self.next()
        varname = self.str_checkname()
        kind = self.t.kind
        if kind == "=":
            result: tree.Stmt = self.fornum(varname, line)
        elif kind in (",", "in"):
            result = self.forlist(varname, line)
        else:
            raise self.syntax_error("`=' or `in' expected")
        self.check_match("end", "for", line)
        self.leaveblock()
        return result

    def fornum(self, varname: str, line: int) -> tree.NumFor:
        self.new_localvar(varname, 0)
        var = self.fs.pending[0]  # type: ignore[union-attr]
        self.check("=")
        start = self.expr()
        self.check(",")
        limit = self.expr()
        step = self.expr() if self.testnext(",") else None
        body = self.forbody_num()
        return tree.NumFor(var, start, limit, step, body, line)

    def forbody_num(self) -> tree.Block:
        # Ba biến ẩn của fornum (chỉ số, giới hạn, bước) không bao giờ được gọi tên: chỉ biến chỉ số vào phạm vi.
        return self.forbody(1)

    def forlist(self, indexname: str, line: int) -> tree.GenFor:
        count = 1
        self.new_localvar(indexname, 0)
        while self.testnext(","):
            self.new_localvar(self.str_checkname(), count)
            count += 1
        self.check("in")
        fs = self.fs
        assert fs is not None
        loop_vars = [fs.pending[n] for n in range(count)]
        exprs = self.explist1()
        body = self.forbody(len(loop_vars))
        return tree.GenFor(loop_vars, exprs, body, line)

    def ifstat(self) -> tree.IfStat:
        line = self.lexer.linenumber
        tests: list[tuple[tree.Expr, tree.Block]] = []
        self.next()
        condition = self.cond()
        self.check("then")
        tests.append((condition, self.block()))
        while self.t.kind == "elseif":
            self.next()
            condition = self.cond()
            self.check("then")
            tests.append((condition, self.block()))
        orelse = None
        if self.t.kind == "else":
            self.next()
            orelse = self.block()
        self.check_match("end", "if", line)
        return tree.IfStat(tests, orelse)

    def localfunc(self) -> tree.LocalFunc:
        self.new_localvar(self.str_checkname(), 0)
        fs = self.fs
        assert fs is not None
        var = fs.pending[0]
        self.adjustlocalvars(1)
        func = self.body(False, self.lexer.linenumber)
        return tree.LocalFunc(var, func)

    def localstat(self) -> tree.LocalStat:
        names = 0
        while True:
            self.new_localvar(self.str_checkname(), names)
            names += 1
            if not self.testnext(","):
                break
        exprs = self.explist1() if self.testnext("=") else []
        fs = self.fs
        assert fs is not None
        declared = [fs.pending[n] for n in range(names)]
        self.adjustlocalvars(names)
        return tree.LocalStat(declared, exprs)

    def funcstat(self, line: int) -> tree.AssignStat:
        self.next()
        target: tree.Expr = self.single_var()
        needself = False
        while self.t.kind == ".":
            self.next()
            key = self.str_checkname()
            target = tree.Index(target, tree.Str(key.encode("utf-8")), self.lexer.linenumber)
        if self.t.kind == ":":
            needself = True
            self.next()
            key = self.str_checkname()
            target = tree.Index(target, tree.Str(key.encode("utf-8")), self.lexer.linenumber)
        func = self.body(needself, line)
        assert isinstance(target, (tree.LocalRef, tree.UpvalRef, tree.GlobalRef, tree.Index))
        return tree.AssignStat([target], [tree.FuncExpr(func)], line)

    def exprstat(self) -> tree.Stmt:
        line = self.lexer.linenumber
        first = self.primaryexp()
        if isinstance(first, (tree.Call, tree.Method)):
            return tree.CallStat(first)
        targets = [self._check_variable(first)]
        while self.testnext(","):
            targets.append(self._check_variable(self.primaryexp()))
        self.check("=")
        exprs = self.explist1()
        return tree.AssignStat(targets, exprs, line)

    def _check_variable(self, expr: tree.Expr) -> tree.LocalRef | tree.UpvalRef | tree.GlobalRef | tree.Index:
        if not isinstance(expr, (tree.LocalRef, tree.UpvalRef, tree.GlobalRef, tree.Index)):
            raise self.syntax_error("syntax error")
        return expr

    def retstat(self) -> tree.ReturnStat:
        self.next()
        if self.block_follow() or self.t.kind == ";":
            return tree.ReturnStat([])
        return tree.ReturnStat(self.explist1())

    def breakstat(self, kind: str) -> tree.Stmt:
        fs = self.fs
        assert fs is not None
        self.next()
        if not any(block.breakable for block in fs.blocks):
            raise self.syntax_error(f"no loop to {kind}")
        return tree.BreakStat() if kind == "break" else tree.ContinueStat()

    # ---------------- chunk ----------------
    def parse_chunk(self) -> tree.ChunkTree:
        fs = self.open_func(0)
        self.next()
        main_body = self.chunk_block(open_scope=False)
        if self.t.kind != EOS:
            raise self.syntax_error("<eof> expected")
        fs.func.body = main_body
        self.close_func()
        return tree.ChunkTree(self.chunk, fs.func, self.funcs)


def parse(source: bytes | str, name: str) -> tree.ChunkTree:
    """Phân tích một chunk; lỗi cú pháp là LuaSyntaxError. Hàm chạy được cả với thân hàm lồng sâu."""
    if isinstance(source, str):
        source = source.encode("utf-8")
    limit = sys.getrecursionlimit()
    if limit < 20000:
        sys.setrecursionlimit(20000)
    return Parser(source, name).parse_chunk()
