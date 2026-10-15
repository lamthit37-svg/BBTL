# Test của bộ dịch Lua → C++ (luagen): bộ tách từ, bộ phân tích và phân giải phạm vi cho phương ngữ LuaPlus 5.0.1.
# Ca biên của phương ngữ đã đo trên LuaPlus.dll ngày 2026-10-15; khi có DLL (D:/XTLBB/Bin64) mỗi ca nhận/từ chối được đối
# chiếu lại với luaL_loadbuffer, nên bảng ca không thể lệch khỏi DLL mà không bị bắt.
# Chạy: python -B -m unittest discover -s TOOLS/port/luagen -p "test_luagen.py"
from __future__ import annotations

import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))

from luagen import tree  # noqa: E402
from luagen.dll import DEFAULT_BIN, LuaDll, LuaDllError  # noqa: E402
from luagen.lexer import EOS, NAME, NUMBER, STRING, Lexer, LuaSyntaxError  # noqa: E402
from luagen.parser import parse  # noqa: E402

REPO = ROOT.parents[2]
SCRIPT_ROOT = REPO / "src/client/script/Interface"
DLL_AVAILABLE = (DEFAULT_BIN / "LuaPlus.dll").is_file()


def tokens(source: bytes) -> list[tuple[str, object]]:
    lexer = Lexer(source, "t")
    out = []
    while True:
        token = lexer.lex()
        if token.kind == EOS:
            return out
        out.append((token.kind, token.value))


def first_error(source: str) -> LuaSyntaxError | None:
    try:
        parse(source, "t")
    except LuaSyntaxError as error:
        return error
    return None


class LexerTests(unittest.TestCase):
    def test_numbers(self) -> None:
        self.assertEqual(tokens(b"1 .5 5. 5.e1 1e+2 1E-1 010 09"),
                         [(NUMBER, 1.0), (NUMBER, 0.5), (NUMBER, 5.0), (NUMBER, 50.0), (NUMBER, 100.0), (NUMBER, 0.1),
                          (NUMBER, 10.0), (NUMBER, 9.0)])

    def test_hex_follows_luaplus(self) -> None:
        self.assertEqual(tokens(b"0x10 0xFF 0xfF 0x7fffffff 0xffffffff"),
                         [(NUMBER, 16.0), (NUMBER, 255.0), (NUMBER, 255.0), (NUMBER, 2147483647.0), (NUMBER, -1.0)])
        # Tối đa 8 chữ số hex: phần còn lại thành số kế tiếp.
        self.assertEqual(tokens(b"0x100000000"), [(NUMBER, float(0x10000000)), (NUMBER, 0.0)])
        # Chữ X hoa không phải hệ 16: `0` rồi tên `X10`.
        self.assertEqual(tokens(b"0X10"), [(NUMBER, 0.0), (NAME, "X10")])

    def test_malformed_numbers(self) -> None:
        for source in (b"1e", b"1e+", b"1..2", b"0x"):
            with self.assertRaises(LuaSyntaxError, msg=source):
                tokens(source)

    def test_strings_and_escapes(self) -> None:
        self.assertEqual(tokens(rb'"a\65\066\0670\n\\\"" ' + rb"'\''"),
                         [(STRING, b"aABC0\n\\\""), (STRING, b"'")])
        self.assertEqual(tokens(b'"a\\\nb"'), [(STRING, b"a\nb")])
        self.assertEqual(tokens(rb'"\0\255"'), [(STRING, b"\x00\xff")])
        for source in (rb'"\256"', b'"abc', b'"abc\n"'):
            with self.assertRaises(LuaSyntaxError, msg=source):
                tokens(source)

    def test_long_strings_nest(self) -> None:
        self.assertEqual(tokens(b"[[a[[b]]c]]"), [(STRING, b"a[[b]]c")])
        self.assertEqual(tokens(b"[[\nx]]"), [(STRING, b"x")])
        self.assertEqual(tokens(b"[[a]]]"), [(STRING, b"a"), ("]", None)])
        self.assertEqual(tokens(b"[[a\r\nb]]"), [(STRING, b"a\r\nb")])

    def test_comments(self) -> None:
        self.assertEqual(tokens(b"a --x\nb --[[ y [[ z ]] w ]] c --[ d\ne"),
                         [(NAME, "a"), (NAME, "b"), (NAME, "c"), (NAME, "e")])
        self.assertEqual(tokens(b"#!lua\nx"), [(NAME, "x")])
        with self.assertRaises(LuaSyntaxError):
            tokens("--[[ chưa đóng".encode("utf-8"))

    def test_operators_and_keywords(self) -> None:
        kinds = [kind for kind, _ in tokens(b".. ... == ~= <= >= < > = ~ continue elseif x")]
        self.assertEqual(kinds, ["..", "...", "==", "~=", "<=", ">=", "<", ">", "=", "~", "continue", "elseif", NAME])

    def test_control_and_high_bytes_rejected(self) -> None:
        for source in (b"\x01", b"a\x7f", b"\xef\xbb\xbfx"):
            with self.assertRaises(LuaSyntaxError, msg=source):
                tokens(source)
        # Trong chuỗi và chú thích thì byte cao hợp lệ.
        self.assertEqual(tokens("\"Đại Lý\" --中文".encode("utf-8")), [(STRING, "Đại Lý".encode("utf-8"))])

    def test_line_numbers(self) -> None:
        lexer = Lexer(b"a\n\nb --c\n[[x\ny]] z", "t")
        seen = []
        while lexer.lex().kind != EOS:
            seen.append(lexer.linenumber)
        self.assertEqual(seen, [1, 3, 5, 5])


# (nguồn, nhận?) — mỗi ca đã đo trên LuaPlus.dll.
ACCEPT_REJECT = [
    ("local a = 1", True),
    ("x = 0x10", True),
    ("for i=1,5 do if i==3 then continue end end", True),
    ("while true do continue end", True),
    ("repeat if x then continue end until y", True),
    ("function f() while true do break end end", True),
    ("f\"abc\" f[[x]] f{1} (f)(1)", True),
    ("local s = (\"x\"):rep(3)", True),
    ("function t.a.b:c() return self end", True),
    ("local function f(a, ...) return arg.n end", True),
    ("t = {1, 2; 3, x = 1, [2] = 3, f(), }", True),
    ("t = {;}", True),
    ("a, b.c, d[1] = 1, 2", True),
    ("return", True),
    ("return;", True),
    ("do return 1 end", True),
    ("a = 2^3^2 .. 'x' .. 4 == 5 and not 6 or -7", True),
    ("local a <const> = 1", False),
    ("a += 1", False),
    ("a != b", False),
    ("x = 7 % 3", False),
    ("x = #t", False),
    (";", False),
    ("f();;", False),
    ("for i=1,3 do continue f() end", False),
    ("for i=1,3 do break f() end", False),
    ("do return 1 f() end", False),
    ("continue", False),
    ("if x then continue end", False),
    ("break", False),
    ("local continue = 1", False),
    ("function f() return ... end", False),
    ("function f(..., a) end", False),
    ("function t:a.b() end", False),
    ("goto x", False),
    ("(1)", False),
    ("(f())", False),
    ("(a) = 1", False),
    ("f() = 1", False),
    ("local f = print\n(f)(1)", False),
    ("x = y\n\n(f)(1)", False),
    ("x = 1\n\n(f)(1)", True),
    ("x = 3x", False),
    ("x = 1..2", False),
    ("x = [[abc", False),
    ("x = 'abc", False),
    ("while true do local function g() break end end", False),
]


class AcceptRejectTests(unittest.TestCase):
    def test_table(self) -> None:
        for source, accepted in ACCEPT_REJECT:
            with self.subTest(source=source):
                self.assertEqual(first_error(source) is None, accepted)

    @unittest.skipUnless(DLL_AVAILABLE, "không có LuaPlus.dll")
    def test_table_agrees_with_luaplus_dll(self) -> None:
        dll = LuaDll()
        for source, accepted in ACCEPT_REJECT:
            with self.subTest(source=source):
                self.assertEqual(dll.syntax_error(source.encode("utf-8"), "t") is None, accepted)

    def test_lookahead_line_quirk_of_constructor(self) -> None:
        # llex.c: lookahead() của hàm dựng bảng đã đọc `(` ở dòng sau nên lastline == linenumber; không báo "ambiguous syntax".
        self.assertIsNone(first_error("t = { a\n(b) }"))
        self.assertIsNotNone(first_error("t = a\n(b)"))

    def test_nesting_limit(self) -> None:
        self.assertIsNone(first_error("x = " + "(" * 90 + "1" + ")" * 90))
        error = first_error("x = " + "(" * 250 + "1" + ")" * 250)
        self.assertIsNotNone(error)
        assert error is not None
        self.assertIn("too many syntax levels", error.message)

    def test_chunk_syntax_error_has_chunk_and_line(self) -> None:
        error = first_error("x = 1\ny = = 2")
        assert error is not None
        self.assertEqual((error.chunk, error.line), ("t", 2))


def only_func(source: str) -> tree.Func:
    return parse(source, "t").main


class TreeTests(unittest.TestCase):
    def test_unary_minus_folds_numerals_and_keeps_positive_zero(self) -> None:
        func = only_func("x = -5 y = -0 z = - -3 w = -(2) v = -x")
        values = [stat.exprs[0] for stat in func.body.stmts]
        self.assertEqual([type(v).__name__ for v in values], ["Num", "Num", "Num", "Num", "Un"])
        self.assertEqual([v.value for v in values[:4]], [-5.0, 0.0, 3.0, -2.0])
        self.assertEqual(str(values[1].value), "0.0")

    def test_no_constant_folding_of_binary_operators(self) -> None:
        # Lua 5.0.1 không gấp phép nhị phân: 2^10 chạy ở runtime (và __pow của LuaPlus là XOR).
        func = only_func("x = 2^10")
        self.assertIsInstance(func.body.stmts[0].exprs[0], tree.Bin)

    def test_precedence_and_associativity(self) -> None:
        func = only_func("x = 1 + 2 * 3 .. 4 .. 5 == 6 or 7 and 8")
        top = func.body.stmts[0].exprs[0]
        self.assertEqual(top.op, "or")
        self.assertEqual(top.right.op, "and")
        eq = top.left
        self.assertEqual(eq.op, "==")
        concat = eq.left
        self.assertEqual(concat.op, "..")
        # Nối phải kết hợp phải: (1 + 2 * 3) .. (4 .. 5)
        self.assertEqual(concat.right.op, "..")
        self.assertEqual(concat.left.op, "+")
        pow_ = only_func("x = 2^3^2 + -2^2").body.stmts[0].exprs[0]
        self.assertEqual(pow_.left.op, "^")
        self.assertEqual(pow_.left.right.op, "^")
        # -2^2 là -(2^2): toán hạng của dấu trừ không phải hằng số nên không gấp.
        self.assertIsInstance(pow_.right, tree.Un)

    def test_scopes_locals_upvalues_globals(self) -> None:
        func = only_func("local a = 1 local function f() local b = a return function() return a + b + c end end")
        outer = func.children[0]
        inner = outer.children[0]
        a_var = func.locals[0]
        self.assertTrue(a_var.captured)
        self.assertEqual([u.name for u in outer.upvalues], ["a"])
        self.assertEqual([u.name for u in inner.upvalues], ["a", "b"])
        # a của inner lấy từ upvalue 0 của outer; b lấy từ biến cục bộ của outer.
        self.assertEqual((inner.upvalues[0].parent_var, inner.upvalues[0].parent_index), (None, 0))
        self.assertIs(inner.upvalues[1].parent_var, outer.locals[0])
        ret = inner.body.stmts[0]
        names = []

        def walk(expr: tree.Expr) -> None:
            if isinstance(expr, tree.Bin):
                walk(expr.left)
                walk(expr.right)
            else:
                names.append(type(expr).__name__)

        walk(ret.exprs[0])
        self.assertEqual(names, ["UpvalRef", "UpvalRef", "GlobalRef"])

    def test_local_scope_starts_after_the_statement(self) -> None:
        func = only_func("local x = x")
        self.assertIsInstance(func.body.stmts[0].exprs[0], tree.GlobalRef)
        func = only_func("local function f() return f end")
        ret = func.children[0].body.stmts[0]
        self.assertIsInstance(ret.exprs[0], tree.UpvalRef)

    def test_repeat_until_condition_is_outside_the_body_scope(self) -> None:
        # Lua 5.0.1 (lparser.c repeatstat): `until done` KHÔNG thấy biến cục bộ của thân vòng.
        func = only_func("repeat local done = true until done")
        stat = func.body.stmts[0]
        self.assertIsInstance(stat.cond, tree.GlobalRef)

    def test_for_variables_scope(self) -> None:
        func = only_func("local i = 9 for i = i, 3 do x = i end y = i")
        loop = func.body.stmts[1]
        self.assertIsInstance(loop.start, tree.LocalRef)
        self.assertIs(loop.start.var, func.locals[0])
        self.assertIs(loop.block.stmts[0].exprs[0].var, loop.var)
        self.assertIs(func.body.stmts[2].exprs[0].var, func.locals[0])

    def test_method_and_vararg_params(self) -> None:
        func = only_func("function a.b:c(x, ...) end").children[0]
        self.assertEqual([p.name for p in func.params], ["self", "x"])
        self.assertTrue(func.is_vararg)
        self.assertEqual(func.arg_var.name, "arg")

    def test_parenthesised_call_is_single_value(self) -> None:
        func = only_func("x = f((g()))")
        arg = func.body.stmts[0].exprs[0].args[0]
        self.assertIsInstance(arg, tree.Paren)

    def test_table_constructor_item_kinds_in_source_order(self) -> None:
        func = only_func("t = {1, a = 2, [3] = 4, f(), x}")
        items = func.body.stmts[0].exprs[0].items
        self.assertEqual([type(i).__name__ for i in items], ["ListItem", "RecordItem", "RecordItem", "ListItem", "ListItem"])
        self.assertEqual(items[1].key.value, b"a")

    def test_captured_flag_only_when_a_closure_uses_it(self) -> None:
        func = only_func("local a, b = 1, 2 local function f() return a end")
        self.assertEqual([v.captured for v in func.locals[:2]], [True, False])


class CorpusTests(unittest.TestCase):
    @unittest.skipUnless(SCRIPT_ROOT.is_dir(), "không có src/client/script")
    def test_every_interface_script_parses(self) -> None:
        failures = []
        count = 0
        for path in sorted(SCRIPT_ROOT.rglob("*.lua")):
            count += 1
            try:
                parse(path.read_bytes().replace(b"\r\n", b"\n"), path.name)
            except LuaSyntaxError as error:
                failures.append(str(error))
        self.assertGreater(count, 2000)
        self.assertEqual(failures, [])

    def test_world_lua_parses(self) -> None:
        parse((ROOT / "world.lua").read_bytes(), "world")


@unittest.skipUnless(DLL_AVAILABLE, "không có LuaPlus.dll")
class DllBridgeTests(unittest.TestCase):
    def test_run_returns_emitted_lines(self) -> None:
        self.assertEqual(LuaDll().run("__emit(1+1)", "t"), ["2"])

    def test_run_reports_errors(self) -> None:
        with self.assertRaises(LuaDllError):
            LuaDll().run("error('x')", "t")


if __name__ == "__main__":
    unittest.main()
