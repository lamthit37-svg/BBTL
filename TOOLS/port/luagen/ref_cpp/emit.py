"""Bộ phát C++ của bộ dịch Lua → C++: từ cây đã phân giải (tree.py) sang mã gọi bề mặt `lua/vm.hpp`.

Thứ tự đánh giá lấy từ lparser.c và lcode.c 5.0.1 (đọc mã, không đoán). Mã sinh là dạng "mỗi phép một câu lệnh": mọi
phép có tác dụng phụ hay có thể lỗi viết thành câu lệnh riêng, nên thứ tự C++ (không xác định giữa các đối số) không bao giờ
quyết định thứ tự Lua. Các điểm khác Lua "thông thường" mà mã sinh giữ đúng của bản 5.0.1:

- Biến cục bộ nằm trong thanh ghi nên toán hạng là biến cục bộ được ĐỌC LÚC LỆNH CHẠY, không lúc biểu thức được duyệt:
  `x + f()` mà f sửa x (x bị hàm con bắt) dùng x mới. Mã sinh giữ đúng bằng cách đọc ô (`Cell`) đúng lúc dùng cho toán hạng
  của phép số học, so sánh, chỉ mục, và SAO CHÉP ngay lúc duyệt ở những chỗ lcode.c sao chép (đối số, hàm được gọi, vế nối,
  mục danh sách của hàm dựng bảng, giá trị trả về, vế phải của gán nhiều đích).
- Hàm dựng bảng: `nh` chỉ đếm khoá viết bằng tên; mục danh sách xả theo lô 32 ở đầu vòng của mục kế (closelistfield).
- Gán nhiều đích: tính đích, tính vế phải, rồi gán từ phải sang trái; trùng biến cục bộ thì sao chép trước (check_conflict).
- Vế `until` của `repeat` nằm ngoài phạm vi thân vòng; biến vòng `for` là MỘT biến dùng chung mọi lượt (khối ngoài thân).
- `a > b` là less(b, a), `a >= b` là less_equal(b, a); `a .. b .. c` là một concat; `x .. (y .. z)` cũng gộp (posfix nối).

`continue` của LuaPlus không đóng upvalue (đo trên DLL: closure tạo trước `continue` dùng chung ô với lượt sau). Tổ hợp ấy
không có trong 24 942 chunk; gặp thì bộ phát dừng với EmitError thay vì phát sai.
"""

from __future__ import annotations

import contextlib
import math
import re
from dataclasses import dataclass, field

from .. import tree

# Mọi giới hạn của lô xả SETLIST: LFIELDS_PER_FLUSH của lopcodes.h.
LFIELDS_PER_FLUSH = 32
# Chuỗi if/elseif dài hơn ngưỡng này phát dạng "chọn nhánh" phẳng thay vì lồng else (MSVC giới hạn 128 khối lồng nhau).
NESTED_IF_LIMIT = 6
# MSVC không nhận một literal chuỗi dài hơn ~16 KB: cắt thành các mảnh nối nhau.
STRING_PIECE = 4000

CONST, TEMP, LOCAL, CELL = "const", "temp", "local", "cell"

ARITHMETIC = {"+": "add", "-": "sub", "*": "mul", "/": "div", "^": "pow"}
COMPARISON = {"==", "~=", "<", "<=", ">", ">="}


class EmitError(Exception):
    """Cây có thứ bộ phát không (hay chưa) dịch được; câu lỗi nêu chỗ."""


@dataclass(slots=True)
class Opd:
    """Toán hạng đã sẵn sàng: một biểu thức C++ cho một Value mà mọi tác dụng phụ đã được phát thành câu lệnh.

    kind: CONST, TEMP (biến tạm, không bao giờ gán lại), LOCAL (biến cục bộ không bị bắt: không đổi trong một biểu thức),
    CELL (biến cục bộ bị bắt: có thể bị hàm con sửa giữa chừng, nên đọc đúng lúc dùng)."""

    code: str
    kind: str
    var: tree.Var | None = None


def number_literal(value: float) -> str:
    if math.isinf(value):
        return "std::numeric_limits<double>::infinity()" if value > 0 else "-std::numeric_limits<double>::infinity()"
    if math.isnan(value):
        return "std::numeric_limits<double>::quiet_NaN()"
    if value == 0.0:
        return "0.0"
    if value == int(value) and abs(value) < 2.0**53:
        return f"{int(value)}.0"
    return value.hex()


def string_literal(data: bytes) -> str:
    """Thân của một literal chuỗi C++ (các mảnh nối nhau) mang đúng các byte (kể cả byte 0). UTF-8 hợp lệ giữ nguyên; byte khác thành escape bát phân."""
    try:
        text = data.decode("utf-8")
        raw_ok = True
    except UnicodeDecodeError:
        text = ""
        raw_ok = False
    pieces: list[str] = []
    current: list[str] = []
    size = 0

    def flush() -> None:
        nonlocal size
        pieces.append("".join(current))
        current.clear()
        size = 0

    def add(token: str, weight: int) -> None:
        nonlocal size
        if size + weight > STRING_PIECE:
            flush()
        current.append(token)
        size += weight

    if raw_ok:
        previous_question = False
        for char in text:
            code = ord(char)
            if char in ('"', "\\") or code < 0x20 or code == 0x7F:
                add(f"\\{code:03o}", 4)
            elif 0x80 <= code <= 0x9F or code in (0x2028, 0x2029, 0xFEFF):
                for byte in char.encode("utf-8"):
                    add(f"\\{byte:03o}", 4)
            elif char == "?" and previous_question:
                add("\\077", 4)
            else:
                add(char, len(char.encode("utf-8")))
            previous_question = char == "?"
    else:
        for byte in data:
            if 0x20 <= byte < 0x7F and byte not in (0x22, 0x3F, 0x5C):
                add(chr(byte), 1)
            else:
                add(f"\\{byte:03o}", 4)
    flush()
    return " ".join(f'"{piece}"' for piece in pieces)


def string_view_literal(data: bytes) -> str:
    """`std::string_view("...", N)` với N tường minh (chuỗi có thể chứa byte 0)."""
    if not data:
        return "std::string_view{}"  # bugprone-string-constructor từ chối ("", 0)
    return f"std::string_view({string_literal(data)}, {len(data)})"


def is_multi(expr: tree.Expr) -> bool:
    return isinstance(expr, (tree.Call, tree.Method))


def constant_truth(node: tree.Expr) -> bool | None:
    """Điều kiện hằng: nil/false là sai; true, số, chuỗi là đúng; `not` của hằng đảo lại. None khi phụ thuộc lúc chạy.
    Hằng không có tác dụng phụ nên bỏ nhánh chết không đổi hành vi (lcode.c cũng bỏ nhảy cho hằng)."""
    if isinstance(node, tree.Paren):
        return constant_truth(node.expr)
    if isinstance(node, (tree.Nil, tree.FalseE)):
        return False
    if isinstance(node, (tree.TrueE, tree.Num, tree.Str)):
        return True
    if isinstance(node, tree.Un) and node.op == "not":
        inner = constant_truth(node.operand)
        return None if inner is None else not inner
    return None


def fold_constant_tests(stmt: tree.IfStat) -> tuple[list[tuple[tree.Expr, tree.Block]], tree.Block | None]:
    """(các nhánh có điều kiện thật, nhánh `else`). Nhánh điều kiện hằng sai bị bỏ; nhánh điều kiện hằng đúng thành `else` và
    mọi nhánh sau nó bị cắt. Mã chết mà không bỏ thì Clang báo -Wunreachable-code (`if (true) { return; }` rồi mã nối tiếp)."""
    tests: list[tuple[tree.Expr, tree.Block]] = []
    orelse = stmt.orelse
    for condition, body in stmt.tests:
        truth = constant_truth(condition)
        if truth is False:
            continue
        if truth is True:
            return tests, body
        tests.append((condition, body))
    return tests, orelse


def block_terminates(block: tree.Block) -> bool:
    return any(terminates(stmt) for stmt in block.stmts)


def terminates(stmt: tree.Stmt) -> bool:
    """Câu lệnh chắc chắn rời khối chứa nó (return, break, continue, hoặc mọi nhánh đều thế): mã sau nó là mã chết."""
    if isinstance(stmt, (tree.ReturnStat, tree.BreakStat, tree.ContinueStat)):
        return True
    if isinstance(stmt, tree.DoStat):
        return block_terminates(stmt.block)
    if isinstance(stmt, tree.IfStat):
        tests, orelse = fold_constant_tests(stmt)
        if orelse is None or not block_terminates(orelse):
            return False
        # Chuỗi dài phát dạng bộ chọn (if_flat): trình dịch không chứng minh được nó đầy đủ nên mã sau nó vẫn tới được.
        if len(tests) > NESTED_IF_LIMIT:
            return False
        return all(block_terminates(body) for _, body in tests)
    return False


@dataclass
class _LoopContext:
    break_code: str = "break;"
    continue_code: str = "continue;"
    # Số khung khối đang mở lúc vào thân vòng (để tìm biến bị bắt đã khai báo trong thân, cho kiểm tra `continue`).
    frame_depth: int = 0


@dataclass
class ChunkOutput:
    """Mã C++ của một chunk: phần thân (hàm, proto, bảng chuỗi) trong namespace ẩn danh và định nghĩa `Chunk`."""

    name: str
    prefix: str
    body: str
    chunk_symbol: str
    line_count: int
    function_count: int
    string_count: int


class ChunkEmitter:
    """Phát một chunk. `prefix` (ví dụ "c17") làm tiền tố mọi tên có liên kết nội bộ trong TU."""

    def __init__(self, chunk: tree.ChunkTree, prefix: str) -> None:
        self.chunk = chunk
        self.prefix = prefix
        self.strings: dict[bytes, int] = {}

    def string_index(self, data: bytes) -> int:
        index = self.strings.get(data)
        if index is None:
            index = len(self.strings)
            self.strings[data] = index
        return index

    def function_name(self, func: tree.Func) -> str:
        return f"{self.prefix}_f{func.index}"

    def emit(self) -> ChunkOutput:
        bodies = [FunctionEmitter(self, func).emit() for func in self.chunk.funcs]
        out: list[str] = []
        for func in self.chunk.funcs:
            out.append(f"Results {self.function_name(func)}(State& L, const Function& self, Args args);")
        # Chữ ký đã khai báo trước: proto cần con trỏ hàm, thân hàm cần proto của hàm con.
        out.append(f"constexpr std::array<Proto, {len(self.chunk.funcs)}> {self.prefix}_protos{{{{")
        for func in self.chunk.funcs:
            out.append(
                f"    Proto{{.body = &{self.function_name(func)}, .name = {string_view_literal(func.proto_name.encode('utf-8'))}, "
                f".parameters = {len(func.params)}, .upvalues = {len(func.upvalues)}, "
                f".is_vararg = {'true' if func.is_vararg else 'false'}}},"
            )
        out.append("}};")
        out.extend(bodies)
        table = ", ".join(string_view_literal(data) for data in self.strings)
        strings_decl = (
            f"constexpr std::array<std::string_view, {len(self.strings)}> {self.prefix}_strings{{{table}}};"
        )
        text = "\n".join(out)
        # Bảng chuỗi phải đứng trước thân hàm? Không: hàm chỉ đọc qua self.constant(i); bảng chỉ cần trước định nghĩa Chunk.
        body = text + "\n" + strings_decl + "\n"
        return ChunkOutput(
            self.chunk.name, self.prefix, body, f"{self.prefix}_chunk", body.count("\n"), len(self.chunk.funcs), len(self.strings)
        )


def count_reads(func: tree.Func) -> tuple[dict[tree.Var, int], set[tree.Var]]:
    """(số lần mỗi biến cục bộ được ĐỌC trong hàm, tập biến bị GÁN lại sau khai báo). Đích gán trực tiếp không tính là đọc."""
    reads: dict[tree.Var, int] = {}
    assigned: set[tree.Var] = set()

    def expr(node: tree.Expr) -> None:
        if isinstance(node, tree.LocalRef):
            reads[node.var] = reads.get(node.var, 0) + 1
        elif isinstance(node, tree.Index):
            expr(node.obj)
            expr(node.key)
        elif isinstance(node, tree.Call):
            expr(node.func)
            for arg in node.args:
                expr(arg)
        elif isinstance(node, tree.Method):
            expr(node.obj)
            for arg in node.args:
                expr(arg)
        elif isinstance(node, tree.Bin):
            expr(node.left)
            expr(node.right)
        elif isinstance(node, tree.Un):
            expr(node.operand)
        elif isinstance(node, tree.Paren):
            expr(node.expr)
        elif isinstance(node, tree.TableCons):
            for item in node.items:
                if isinstance(item, tree.RecordItem):
                    expr(item.key)
                expr(item.value)

    def target(node: tree.Expr) -> None:
        if isinstance(node, tree.Index):
            expr(node.obj)
            expr(node.key)
        elif isinstance(node, tree.LocalRef):
            assigned.add(node.var)

    def block(node: tree.Block) -> None:
        for stmt in node.stmts:
            statement(stmt)
            if terminates(stmt):
                break

    def statement(stmt: tree.Stmt) -> None:
        if isinstance(stmt, tree.LocalStat):
            for item in stmt.exprs:
                expr(item)
        elif isinstance(stmt, tree.AssignStat):
            for item in stmt.targets:
                target(item)
            for item in stmt.exprs:
                expr(item)
        elif isinstance(stmt, tree.CallStat):
            expr(stmt.call)
        elif isinstance(stmt, tree.DoStat):
            block(stmt.block)
        elif isinstance(stmt, tree.WhileStat):
            expr(stmt.cond)
            block(stmt.block)
        elif isinstance(stmt, tree.RepeatStat):
            block(stmt.block)
            expr(stmt.cond)
        elif isinstance(stmt, tree.IfStat):
            tests, orelse = fold_constant_tests(stmt)
            for condition, body in tests:
                expr(condition)
                block(body)
            if orelse is not None:
                block(orelse)
        elif isinstance(stmt, tree.NumFor):
            expr(stmt.start)
            expr(stmt.limit)
            if stmt.step is not None:
                expr(stmt.step)
            reads[stmt.var] = reads.get(stmt.var, 0) + 1
            block(stmt.block)
        elif isinstance(stmt, tree.GenFor):
            for item in stmt.exprs:
                expr(item)
            block(stmt.block)
        elif isinstance(stmt, tree.ReturnStat):
            for item in stmt.exprs:
                expr(item)

    block(func.body)
    return reads, assigned


class FunctionEmitter:
    def __init__(self, parent: ChunkEmitter, func: tree.Func) -> None:
        self.chunk = parent
        self.func = func
        self.lines: list[list] = []  # [mức thụt, văn bản]
        self.indent = 1
        self.temp_counter = 0
        # Số biến tạm khai báo trực tiếp ở khối C++ hiện tại (khối lồng tự đếm riêng): quyết định bọc `{ }` cho câu lệnh.
        self.live_temps = 0
        self.reads, self.assigned = count_reads(func)
        self.loops: list[_LoopContext] = []
        # Khung khối đang mở: mỗi khung là danh sách biến bị bắt đã khai báo trong khối (để kiểm tra `continue`).
        self.frames: list[list[tree.Var]] = []

    # ---------------- tiện ích phát ----------------
    def line(self, text: str) -> None:
        self.lines.append([self.indent, text])

    def temp(self, prefix: str = "t") -> str:
        name = f"{prefix}{self.temp_counter}"
        self.temp_counter += 1
        self.live_temps += 1
        return name

    @contextlib.contextmanager
    def nested(self):
        """Khối C++ lồng: thụt vào một mức; biến tạm khai báo trong đó không tính cho khối ngoài."""
        saved = self.live_temps
        self.live_temps = 0
        self.indent += 1
        try:
            yield
        finally:
            self.indent -= 1
            self.live_temps = saved

    def check(self) -> None:
        self.line("if (failed(L)) return {};")

    def constant(self, data: bytes) -> str:
        return f"self.constant({self.chunk.string_index(data)})"

    def var_name(self, var: tree.Var) -> str:
        # Không lặp tên Lua: `value`, `object`... giống tên tham số của vm.hpp thì readability-suspicious-call-argument báo đối số
        # đặt lẫn chỗ, và `_x` thành tên có hai gạch dưới. Số thứ tự trong hàm đã đủ để tên không trùng.
        return f"l{var.serial}"

    def qualifiers(self, var: tree.Var) -> str:
        """Tiền tố khai báo: `[[maybe_unused]]` khi không bao giờ đọc, `const` khi không bao giờ gán lại."""
        text = "" if self.reads.get(var, 0) > 0 or var.captured else "[[maybe_unused]] "
        if var not in self.assigned:
            text += "const "
        return text

    def declared(self, var: tree.Var, init: str) -> str:
        """Câu khai báo biến cục bộ (Value hay Cell*) với giá trị đầu; không kèm kiểm lỗi."""
        name = self.var_name(var)
        if var.captured:
            return f"Cell* const {name} = new_cell(L, {init or 'Value{}'});"
        return f"{self.qualifiers(var)}Value {name}{{{init}}};"

    def local_operand(self, var: tree.Var) -> Opd:
        if var.captured:
            return Opd(f"{self.var_name(var)}->value", CELL, var)
        return Opd(self.var_name(var), LOCAL, var)

    def materialize(self, opd: Opd, copy_locals: bool = False) -> Opd:
        """Sao chép toán hạng thành giá trị ổn định (lcode.c exp2nextreg): ô bị bắt luôn sao chép, biến cục bộ thường chỉ khi
        copy_locals (gán nhiều đích)."""
        if opd.kind == CELL or (copy_locals and opd.kind == LOCAL):
            name = self.temp()
            self.line(f"const Value {name} = {opd.code};")
            return Opd(name, TEMP)
        return opd

    def wrap_scope(self, mark: int, temps_before: int) -> None:
        """Bọc các dòng từ mark trong `{ }` nếu từ đó có biến tạm mới ở khối này (để trình dịch tái dùng chỗ ngăn xếp)."""
        if self.live_temps == temps_before:
            return
        self.live_temps = temps_before
        for entry in self.lines[mark:]:
            entry[0] += 1
        self.lines.insert(mark, [self.indent, "{"])
        self.line("}")

    # ---------------- biểu thức ----------------
    def expr(self, node: tree.Expr) -> Opd:
        """Duyệt biểu thức, phát mọi tác dụng phụ, trả toán hạng mang MỘT giá trị."""
        if isinstance(node, tree.Nil):
            return Opd("Value{}", CONST)
        if isinstance(node, tree.TrueE):
            return Opd("Value::boolean(true)", CONST)
        if isinstance(node, tree.FalseE):
            return Opd("Value::boolean(false)", CONST)
        if isinstance(node, tree.Num):
            return Opd(f"Value::number({number_literal(node.value)})", CONST)
        if isinstance(node, tree.Str):
            return Opd(self.constant(node.value), CONST)
        if isinstance(node, tree.LocalRef):
            return self.local_operand(node.var)
        if isinstance(node, tree.UpvalRef):
            name = self.temp()
            self.line(f"const Value {name} = self.upvalue({node.index}).value;")
            return Opd(name, TEMP)
        if isinstance(node, tree.GlobalRef):
            name = self.temp()
            self.line(f"const Value {name} = get_global(L, {self.constant(node.name.encode('utf-8'))});")
            self.check()
            return Opd(name, TEMP)
        if isinstance(node, tree.Paren):
            return self.expr(node.expr)
        if isinstance(node, tree.Index):
            obj = self.expr(node.obj)
            key = self.expr(node.key)
            name = self.temp()
            self.line(f"const Value {name} = index(L, {obj.code}, {key.code});")
            self.check()
            return Opd(name, TEMP)
        if isinstance(node, (tree.Call, tree.Method)):
            code = self.call_expr(node)
            name = self.temp()
            self.line(f"const Value {name} = {code}.first();")
            self.check()
            return Opd(name, TEMP)
        if isinstance(node, tree.FuncExpr):
            return self.closure(node.func)
        if isinstance(node, tree.TableCons):
            return self.table(node)
        if isinstance(node, tree.Un):
            return self.unary(node)
        if isinstance(node, tree.Bin):
            return self.binary(node)
        raise EmitError(f"biểu thức chưa hỗ trợ: {type(node).__name__}")

    def unary(self, node: tree.Un) -> Opd:
        if node.op == "-":
            operand = self.expr(node.operand)
            name = self.temp()
            self.line(f"const Value {name} = unm(L, {operand.code});")
            self.check()
            return Opd(name, TEMP)
        flag = self.cond(node)
        return self.boolean_value(flag)

    def boolean_value(self, flag: str) -> Opd:
        """Giá trị boolean của một biểu thức điều kiện: tách ra biến tạm để không giữ lần đọc muộn."""
        if flag in ("true", "false"):
            return Opd(f"Value::boolean({flag})", CONST)
        if not re.fullmatch(r"!?t\d+", flag):
            name = self.temp()
            self.line(f"const bool {name} = {flag};")
            flag = name
        return Opd(f"Value::boolean({flag})", TEMP)

    def binary(self, node: tree.Bin) -> Opd:
        op = node.op
        if op in ARITHMETIC:
            left = self.expr(node.left)
            right = self.expr(node.right)
            name = self.temp()
            self.line(f"const Value {name} = {ARITHMETIC[op]}(L, {left.code}, {right.code});")
            self.check()
            return Opd(name, TEMP)
        if op == "..":
            return self.concat(node)
        if op in COMPARISON:
            return self.boolean_value(self.cond(node))
        # and / or: giá trị là toán hạng quyết định.
        name = self.temp()
        left = self.expr(node.left)
        self.line(f"Value {name} = {left.code};")
        self.line(f"if ({'' if op == 'and' else '!'}{name}.truthy()) {{")
        with self.nested():
            right = self.expr(node.right)
            self.line(f"{name} = {right.code};")
        self.line("}")
        return Opd(name, TEMP)

    def concat(self, node: tree.Bin) -> Opd:
        # lcode.c posfix CONCAT: vế phải là một phép nối (kể cả trong ngoặc) thì gộp vào cùng dải.
        parts: list[tree.Expr] = []
        current: tree.Expr = node
        while True:
            inner = current
            while isinstance(inner, tree.Paren):
                inner = inner.expr
            if isinstance(inner, tree.Bin) and inner.op == "..":
                parts.append(inner.left)
                current = inner.right
            else:
                parts.append(current)
                break
        codes = [self.materialize(self.expr(part)).code for part in parts]
        name = self.temp()
        self.line(f"const Value {name} = concat(L, std::to_array<Value>({{{', '.join(codes)}}}));")
        self.check()
        return Opd(name, TEMP)

    # ---------------- điều kiện ----------------
    def cond(self, node: tree.Expr) -> str:
        """Biểu thức C++ kiểu bool cho điều kiện; mọi tác dụng phụ đã phát. Chuỗi trả về phải được dùng ngay ở câu lệnh kế tiếp
        (có thể chứa lần đọc muộn của ô bị bắt)."""
        if isinstance(node, tree.Paren):
            return self.cond(node.expr)
        if isinstance(node, tree.Bin) and node.op in COMPARISON:
            left = self.expr(node.left)
            right = self.expr(node.right)
            op = node.op
            if op == "==":
                code = f"equal(L, {left.code}, {right.code})"
            elif op == "~=":
                code = f"!equal(L, {left.code}, {right.code})"
            elif op == "<":
                code = f"less(L, {left.code}, {right.code})"
            elif op == "<=":
                code = f"less_equal(L, {left.code}, {right.code})"
            elif op == ">":
                code = f"less(L, {right.code}, {left.code})"
            else:
                code = f"less_equal(L, {right.code}, {left.code})"
            name = self.temp()
            self.line(f"const bool {name} = {code};")
            self.check()
            return name
        if isinstance(node, tree.Un) and node.op == "not":
            inner = self.cond(node.operand)
            return inner[1:] if re.fullmatch(r"!t\d+", inner) else f"!{inner}"
        if isinstance(node, tree.Bin) and node.op in ("and", "or"):
            name = self.temp()
            self.line(f"bool {name} = {self.cond(node.left)};")
            self.line(f"if ({'' if node.op == 'and' else '!'}{name}) {{")
            with self.nested():
                self.line(f"{name} = {self.cond(node.right)};")
            self.line("}")
            return name
        if isinstance(node, (tree.Nil, tree.FalseE)):
            return "false"
        if isinstance(node, (tree.TrueE, tree.Num, tree.Str)):
            return "true"
        opd = self.expr(node)
        return f"{opd.code}.truthy()"

    # ---------------- lời gọi ----------------
    def args_list(self, args: list[tree.Expr], first: str | None = None) -> str:
        """Biểu thức C++ kiểu Args cho danh sách đối số; mọi đối số tính theo thứ tự và sao chép ngay (exp2nextreg)."""
        fixed = args[:-1] if args and is_multi(args[-1]) else args
        codes = [] if first is None else [first]
        for arg in fixed:
            codes.append(self.materialize(self.expr(arg)).code)
        if len(fixed) == len(args):
            if not codes:
                return "{}"
            return f"std::to_array<Value>({{{', '.join(codes)}}})"
        rest = self.temp("r")
        self.line(f"const Results {rest} = {self.call_expr(args[-1])};")
        self.check()
        if not codes:
            return f"{rest}.values()"
        joined = self.temp("a")
        self.line(f"Results {joined}{{{', '.join(codes)}}};")
        self.line(f"{joined}.append({rest});")
        return f"{joined}.values()"

    def call_expr(self, node: tree.Call | tree.Method) -> str:
        """Phát mọi thứ TRƯỚC lệnh gọi và trả biểu thức `call(...)` (kiểu Results) chưa chạy."""
        if isinstance(node, tree.Method):
            obj = self.materialize(self.expr(node.obj))
            method = self.temp()
            self.line(f"const Value {method} = method_of(L, {obj.code}, {self.constant(node.name.encode('utf-8'))});")
            self.check()
            return f"call(L, {method}, {self.args_list(node.args, first=obj.code)})"
        callee = self.materialize(self.expr(node.func))
        return f"call(L, {callee.code}, {self.args_list(node.args)})"

    # ---------------- closure và bảng ----------------
    def closure(self, child: tree.Func) -> Opd:
        cells: list[str] = []
        for upvalue in child.upvalues:
            if upvalue.parent_var is not None:
                cells.append(self.var_name(upvalue.parent_var))
            else:
                cells.append(f"&self.upvalue({upvalue.parent_index})")
        name = self.temp()
        cell_list = f"std::to_array<Cell*>({{{', '.join(cells)}}})" if cells else "{}"
        self.line(f"const Value {name} = closure(L, {self.chunk.prefix}_protos[{child.index}], self, {cell_list});")
        self.check()
        return Opd(name, TEMP)

    def table(self, node: tree.TableCons) -> Opd:
        list_items = sum(1 for item in node.items if isinstance(item, tree.ListItem))
        record_items = sum(1 for item in node.items if isinstance(item, tree.RecordItem) and item.named)
        name = self.temp()
        self.line(f"const Value {name} = new_table(L, {list_items}, {record_items});")
        self.check()
        pending: list[str] = []
        flushed = 0

        def flush() -> None:
            nonlocal flushed
            self.line(f"set_list(L, {name}, {flushed + 1}, std::to_array<Value>({{{', '.join(pending)}}}));")
            flushed += len(pending)
            pending.clear()

        last_index = len(node.items) - 1
        open_call: tree.Call | tree.Method | None = None
        for position, item in enumerate(node.items):
            if len(pending) == LFIELDS_PER_FLUSH:
                flush()
            if isinstance(item, tree.ListItem):
                if position == last_index and is_multi(item.value):
                    assert isinstance(item.value, (tree.Call, tree.Method))
                    open_call = item.value
                else:
                    pending.append(self.materialize(self.expr(item.value)).code)
            else:
                key = self.expr(item.key)
                value = self.expr(item.value)
                self.line(f"set_index(L, {name}, {key.code}, {value.code});")
                self.check()
        if open_call is not None:
            rest = self.temp("r")
            self.line(f"const Results {rest} = {self.call_expr(open_call)};")
            self.check()
            if pending:
                joined = self.temp("a")
                self.line(f"Results {joined}{{{', '.join(pending)}}};")
                self.line(f"{joined}.append({rest});")
                self.line(f"set_list(L, {name}, {flushed + 1}, {joined}.values());")
            else:
                self.line(f"set_list(L, {name}, {flushed + 1}, {rest}.values());")
        elif pending:
            flush()
        return Opd(name, TEMP)

    # ---------------- danh sách giá trị (gán, local, for) ----------------
    def eval_explist(self, exprs: list[tree.Expr], want: int, copy_locals: bool) -> list[str]:
        """Tính danh sách biểu thức theo explist1 + adjust_assign: trả đúng `want` mã giá trị ổn định."""
        values: list[str] = []
        count = len(exprs)
        for position, node in enumerate(exprs):
            last = position == count - 1
            if last and is_multi(node):
                assert isinstance(node, (tree.Call, tree.Method))
                needed = want - position
                code = self.call_expr(node)
                if needed <= 0:
                    self.line(f"static_cast<void>({code});")
                    self.check()
                elif needed == 1:
                    name = self.temp()
                    self.line(f"const Value {name} = {code}.first();")
                    self.check()
                    values.append(name)
                else:
                    name = self.temp("r")
                    self.line(f"const Results {name} = {code};")
                    self.check()
                    values.extend(f"{name}.at_or_nil({index})" for index in range(needed))
                continue
            opd = self.expr(node)
            keep_local = copy_locals and not last
            opd = self.materialize(opd, copy_locals=keep_local)
            if position < want:
                values.append(opd.code)
            elif opd.kind == TEMP:
                self.line(f"static_cast<void>({opd.code});")
        while len(values) < want:
            values.append("Value{}")
        return values[:want]

    # ---------------- câu lệnh ----------------
    def block(self, node: tree.Block) -> None:
        self.frames.append([])
        for stmt in node.stmts:
            self.statement(stmt)
            if terminates(stmt):
                # Mã sau câu lệnh luôn rời khối là mã chết: không phát (Clang -Wunreachable-code), hàm con trong đó vẫn có ở bảng proto.
                break
        self.frames.pop()

    def statement(self, stmt: tree.Stmt) -> None:
        if isinstance(stmt, tree.LocalStat):
            self.local_stat(stmt)
            return
        if isinstance(stmt, tree.LocalFunc):
            self.local_func(stmt)
            return
        mark = len(self.lines)
        temps_before = self.live_temps
        if isinstance(stmt, tree.AssignStat):
            self.assign_stat(stmt)
        elif isinstance(stmt, tree.CallStat):
            code = self.call_expr(stmt.call)
            self.line(f"static_cast<void>({code});")
            self.check()
        elif isinstance(stmt, tree.DoStat):
            self.line("{")
            with self.nested():
                self.block(stmt.block)
            self.line("}")
        elif isinstance(stmt, tree.WhileStat):
            self.while_stat(stmt)
        elif isinstance(stmt, tree.RepeatStat):
            self.repeat_stat(stmt)
        elif isinstance(stmt, tree.IfStat):
            self.if_stat(stmt)
        elif isinstance(stmt, tree.NumFor):
            self.num_for(stmt)
        elif isinstance(stmt, tree.GenFor):
            self.gen_for(stmt)
        elif isinstance(stmt, tree.ReturnStat):
            self.return_stat(stmt)
        elif isinstance(stmt, tree.BreakStat):
            self.line(self.loops[-1].break_code)
        elif isinstance(stmt, tree.ContinueStat):
            self.continue_stat()
        else:
            raise EmitError(f"câu lệnh chưa hỗ trợ: {type(stmt).__name__}")
        self.wrap_scope(mark, temps_before)

    def continue_stat(self) -> None:
        context = self.loops[-1]
        open_vars = [var for frame in self.frames[context.frame_depth:] for var in frame]
        if open_vars:
            names = ", ".join(var.name for var in open_vars)
            raise EmitError(
                f"{self.func.proto_name}: `continue` sau khi biến bị hàm con bắt đã khai báo trong thân vòng ({names}); "
                "LuaPlus không đóng upvalue ở continue (closure dùng chung ô với lượt sau), bộ phát chưa tái hiện"
            )
        self.line(context.continue_code)

    def declare_local(self, var: tree.Var, value: str, predeclared: bool) -> None:
        """Khai báo (hay gán, khi biến đã khai báo trước ở khối ngoài) một biến cục bộ với giá trị đầu."""
        name = self.var_name(var)
        if predeclared:
            self.line(f"{name} = new_cell(L, {value});" if var.captured else f"{name} = {value};")
        else:
            self.line(self.declared(var, value))
        if var.captured:
            self.check()
            self.frames[-1].append(var)

    def local_stat(self, stmt: tree.LocalStat) -> None:
        mark = len(self.lines)
        temps_before = self.live_temps
        values = self.eval_explist(stmt.exprs, len(stmt.vars), copy_locals=False) if stmt.exprs else ["Value{}"] * len(stmt.vars)
        if self.live_temps == temps_before:
            for var, value in zip(stmt.vars, values):
                self.declare_local(var, "" if value == "Value{}" and not var.captured else value, predeclared=False)
            return
        # Có biến tạm: khai báo biến Lua trước (ra ngoài khối), rồi tính và gán trong một khối.
        self.live_temps = temps_before
        declarations = []
        for var in stmt.vars:
            if var.captured:
                declarations.append(f"Cell* {self.var_name(var)} = nullptr;")
            else:
                marker = "" if self.reads.get(var, 0) > 0 else "[[maybe_unused]] "
                declarations.append(f"{marker}Value {self.var_name(var)};")
        for entry in self.lines[mark:]:
            entry[0] += 1
        self.lines[mark:mark] = [[self.indent, text] for text in declarations] + [[self.indent, "{"]]
        self.indent += 1
        for var, value in zip(stmt.vars, values):
            self.declare_local(var, value, predeclared=True)
        self.indent -= 1
        self.line("}")

    def local_func(self, stmt: tree.LocalFunc) -> None:
        """`local function f`: f vào phạm vi trước khi tạo closure (lparser.c localfunc), nên Cell của nó có trước closure."""
        var = stmt.var
        name = self.var_name(var)
        if var.captured:
            self.line(f"Cell* {name} = nullptr;")
        else:
            marker = "" if self.reads.get(var, 0) > 0 else "[[maybe_unused]] "
            self.line(f"{marker}Value {name};")
        self.line("{")
        with self.nested():
            if var.captured:
                self.line(f"{name} = new_cell(L, Value{{}});")
                self.check()
            closure = self.closure(stmt.func)
            self.line(f"{name}->value = {closure.code};" if var.captured else f"{name} = {closure.code};")
        self.line("}")
        if var.captured:
            self.frames[-1].append(var)

    # ---- gán ----
    def store(self, target: tuple, value: str) -> None:
        kind = target[0]
        if kind == "local":
            var = target[1]
            name = f"{self.var_name(var)}->value" if var.captured else self.var_name(var)
            # `x = x` là OP_MOVE cùng thanh ghi, không làm gì; phát ra thì Clang báo -Wself-assign-overloaded.
            if value != name:
                self.line(f"{name} = {value};")
        elif kind == "upval":
            self.line(f"self.upvalue({target[1]}).value = {value};")
        elif kind == "global":
            self.line(f"set_global(L, {target[1]}, {value});")
            self.check()
        else:
            self.line(f"set_index(L, {target[1].code}, {target[2].code}, {value});")
            self.check()

    def prepare_target(self, node: tree.Expr) -> list:
        if isinstance(node, tree.LocalRef):
            return ["local", node.var]
        if isinstance(node, tree.UpvalRef):
            return ["upval", node.index]
        if isinstance(node, tree.GlobalRef):
            return ["global", self.constant(node.name.encode("utf-8"))]
        assert isinstance(node, tree.Index)
        obj = self.expr(node.obj)
        key = self.expr(node.key)
        return ["index", obj, key]

    def assign_stat(self, stmt: tree.AssignStat) -> None:
        if len(stmt.targets) == 1 and len(stmt.exprs) == 1:
            target = self.prepare_target(stmt.targets[0])
            value = self.expr(stmt.exprs[0])
            self.store(tuple(target), value.code)
            return
        targets: list[list] = []
        for node in stmt.targets:
            target = self.prepare_target(node)
            if target[0] == "local":
                # check_conflict: đích trước là chỉ mục dùng chính biến cục bộ này (làm bảng hay khoá) thì sao chép giá trị cũ.
                copy: Opd | None = None
                for earlier in targets:
                    if earlier[0] != "index":
                        continue
                    for slot in (1, 2):
                        used = earlier[slot]
                        if used.var is target[1]:
                            if copy is None:
                                copied = self.temp()
                                self.line(f"const Value {copied} = {used.code};")
                                copy = Opd(copied, TEMP)
                            earlier[slot] = copy
            targets.append(target)
        values = self.eval_explist(stmt.exprs, len(targets), copy_locals=True)
        for target, value in zip(reversed(targets), reversed(values)):
            self.store(tuple(target), value)

    # ---- if ----
    def if_stat(self, stmt: tree.IfStat) -> None:
        tests, orelse = fold_constant_tests(stmt)
        if not tests:
            # Mọi điều kiện là hằng: chỉ còn nhánh luôn chạy (hoặc không có gì), không phát `if (true)`.
            if orelse is not None:
                self.line("{")
                with self.nested():
                    self.block(orelse)
                self.line("}")
            return
        if len(tests) > NESTED_IF_LIMIT:
            self.if_flat(tests, orelse)
            return

        def chain(position: int) -> None:
            condition = self.cond(tests[position][0])
            start = len(self.lines)
            with self.nested():
                self.block(tests[position][1])
            then_lines = self.lines[start:]
            del self.lines[start:]
            has_more = position + 1 < len(tests)
            else_lines: list[list] | None = None
            if has_more or orelse is not None:
                with self.nested():
                    if has_more:
                        chain(position + 1)
                    else:
                        assert orelse is not None
                        self.block(orelse)
                else_lines = self.lines[start:]
                del self.lines[start:]
            if else_lines is not None and then_lines == else_lines:
                # Hai nhánh giống hệt (script có thật): điều kiện vẫn được tính, thân chạy đúng một lần. Phát `if/else` hai nhánh giống nhau
                # thì clang-tidy báo bugprone-branch-clone.
                self.line(f"static_cast<void>({condition});")
                self.line("{")
                self.lines.extend([indent - 1, text] for indent, text in then_lines)
                self.line("}")
                return
            self.line(f"if ({condition}) {{")
            self.lines.extend(then_lines)
            if else_lines is not None:
                self.line("} else {")
                self.lines.extend(else_lines)
            self.line("}")

        chain(0)

    def if_flat(self, tests: list[tuple[tree.Expr, tree.Block]], orelse: tree.Block | None) -> None:
        """Chuỗi elseif dài: tính điều kiện lần lượt tới điều kiện đúng đầu tiên rồi chạy đúng một thân. Cùng thứ tự đánh giá
        và tác dụng phụ với dạng lồng (điều kiện sau nhánh đúng không bao giờ được tính)."""
        selector = self.temp("s")
        self.line(f"int {selector} = 0;")
        for position, (condition_node, _) in enumerate(tests, start=1):
            if position == 1:
                self.line("{")
            else:
                self.line(f"if ({selector} == 0) {{")
            with self.nested():
                condition = self.cond(condition_node)
                self.line(f"if ({condition}) {selector} = {position};")
            self.line("}")
        # Các thân là `if` rời nhau, không phải chuỗi `else if`: MSVC dừng ở 128 khối lồng (C1061), mà elseif của script giao diện dài
        # tới hàng trăm nhánh. Bộ chọn là biến riêng không thân nào ghi vào nên tối đa một thân chạy; `break` của Lua vẫn thoát
        # vòng ngoài vì không có `switch` chen vào.
        for position, (_, body) in enumerate(tests, start=1):
            self.line(f"if ({selector} == {position}) {{")
            with self.nested():
                self.block(body)
            self.line("}")
        if orelse is not None:
            self.line(f"if ({selector} == 0) {{")
            with self.nested():
                self.block(orelse)
            self.line("}")

    # ---- vòng lặp ----
    def loop_body(self, body: tree.Block, context: _LoopContext) -> None:
        context.frame_depth = len(self.frames)
        self.loops.append(context)
        self.block(body)
        self.loops.pop()

    @staticmethod
    def negate(condition: str) -> str:
        return condition[1:] if re.fullmatch(r"!t\d+", condition) else f"!{condition}"

    def while_stat(self, stmt: tree.WhileStat) -> None:
        self.line("for (;;) {")
        with self.nested():
            self.line("if (!tick(L)) return {};")
            condition = self.cond(stmt.cond)
            if condition == "false":
                self.line("break;")
            elif condition != "true":
                self.line(f"if ({self.negate(condition)}) break;")
            self.loop_body(stmt.block, _LoopContext())
        self.line("}")

    def repeat_stat(self, stmt: tree.RepeatStat) -> None:
        has_continue = self.contains_continue(stmt.block)
        self.line("for (;;) {")
        with self.nested():
            self.line("if (!tick(L)) return {};")
            if has_continue:
                # `continue` của repeat nhảy tới điều kiện `until`: thân chạy trong do { } while (false), `continue` thành
                # break của nó, còn `break` của Lua đặt cờ rồi thoát.
                flag = self.temp("b")
                self.line(f"bool {flag} = false;")
                self.line("do {")
                with self.nested():
                    self.loop_body(stmt.block, _LoopContext(break_code=f"{{ {flag} = true; break; }}", continue_code="break;"))
                self.line("} while (false);")
                self.line(f"if ({flag}) break;")
            else:
                self.line("{")
                with self.nested():
                    self.loop_body(stmt.block, _LoopContext())
                self.line("}")
            condition = self.cond(stmt.cond)
            if condition == "true":
                self.line("break;")
            elif condition != "false":
                self.line(f"if ({condition}) break;")
        self.line("}")

    def contains_continue(self, node: tree.Block) -> bool:
        """Có `continue` nhắm vào vòng này (không tính trong vòng con hay hàm con)."""
        for stmt in node.stmts:
            if isinstance(stmt, tree.ContinueStat):
                return True
            if isinstance(stmt, tree.IfStat):
                if any(self.contains_continue(body) for _, body in stmt.tests):
                    return True
                if stmt.orelse is not None and self.contains_continue(stmt.orelse):
                    return True
            elif isinstance(stmt, tree.DoStat) and self.contains_continue(stmt.block):
                return True
        return False

    def loop_variable(self, var: tree.Var, init: str) -> None:
        """Khai báo biến vòng for (một biến cho mọi lượt, nằm ngoài thân)."""
        if var.captured:
            self.line(f"Cell* const {self.var_name(var)} = new_cell(L, {init or 'Value{}'});")
            self.check()
        else:
            marker = "" if self.reads.get(var, 0) > 0 else "[[maybe_unused]] "
            self.line(f"{marker}Value {self.var_name(var)}{{{init}}};")

    def num_for(self, stmt: tree.NumFor) -> None:
        self.line("{")
        with self.nested():
            start = self.materialize(self.expr(stmt.start))
            limit = self.materialize(self.expr(stmt.limit))
            if stmt.step is None:
                step = Opd("Value::number(1.0)", CONST)
            else:
                step = self.materialize(self.expr(stmt.step))
            limit_name = self.temp("lim")
            step_name = self.temp("stp")
            self.line(f"Value {limit_name} = {limit.code};")
            self.line(f"Value {step_name} = {step.code};")
            initial = self.temp()
            self.line(f"const Value {initial} = sub(L, {start.code}, {step_name});")
            self.check()
            self.loop_variable(stmt.var, initial)
            index = f"{self.var_name(stmt.var)}->value" if stmt.var.captured else self.var_name(stmt.var)
            self.line("for (;;) {")
            with self.nested():
                self.line("if (!tick(L)) return {};")
                go = self.temp("go")
                self.line(f"const bool {go} = for_next(L, {index}, {limit_name}, {step_name});")
                self.check()
                self.line(f"if (!{go}) break;")
                self.loop_body(stmt.block, _LoopContext())
            self.line("}")
        self.line("}")

    def gen_for(self, stmt: tree.GenFor) -> None:
        self.line("{")
        with self.nested():
            count = len(stmt.vars)
            values = self.eval_explist(stmt.exprs, 2 + count, copy_locals=False)
            generator = self.temp("gen")
            invariant = self.temp("inv")
            self.line(f"Value {generator} = {values[0]};")
            self.line(f"Value {invariant} = {values[1]};")
            self.line(f"for_prep(L, {generator}, {invariant});")
            for var, value in zip(stmt.vars, values[2:]):
                self.loop_variable(var, "" if value == "Value{}" and not var.captured else value)
            names = [f"{self.var_name(var)}->value" if var.captured else self.var_name(var) for var in stmt.vars]
            self.line("for (;;) {")
            with self.nested():
                self.line("if (!tick(L)) return {};")
                result = self.temp("r")
                self.line(f"const Results {result} = call(L, {generator}, std::to_array<Value>({{{invariant}, {names[0]}}}));")
                self.check()
                for position, name in enumerate(names):
                    self.line(f"{name} = {result}.at_or_nil({position});")
                self.line(f"if ({names[0]}.is_nil()) break;")
                self.loop_body(stmt.block, _LoopContext())
            self.line("}")
        self.line("}")

    # ---- return ----
    def return_stat(self, stmt: tree.ReturnStat) -> None:
        exprs = stmt.exprs
        if not exprs:
            self.line("return {};")
            return
        if len(exprs) == 1 and is_multi(exprs[0]):
            assert isinstance(exprs[0], (tree.Call, tree.Method))
            self.line(f"return {self.call_expr(exprs[0])};")
            return
        if len(exprs) == 1:
            self.line(f"return Results{{{self.expr(exprs[0]).code}}};")
            return
        fixed = exprs[:-1] if is_multi(exprs[-1]) else exprs
        codes = [self.materialize(self.expr(node)).code for node in fixed]
        if len(fixed) == len(exprs):
            self.line(f"return Results{{{', '.join(codes)}}};")
            return
        joined = self.temp("a")
        self.line(f"Results {joined}{{{', '.join(codes)}}};")
        last = exprs[-1]
        assert isinstance(last, (tree.Call, tree.Method))
        self.line(f"{joined}.append({self.call_expr(last)});")
        self.line(f"return {joined};")

    # ---------------- hàm ----------------
    def emit(self) -> str:
        func = self.func
        self.frames.append([])
        # Tham số: giá trị thứ i của args, nil khi thiếu; tham số bị bắt vào một Cell.
        for position, var in enumerate(func.params):
            init = f"args.size() > {position} ? args[{position}] : Value{{}}"
            if var.captured:
                self.line(f"Cell* const {self.var_name(var)} = new_cell(L, {init});")
                self.check()
                self.frames[-1].append(var)
            else:
                self.line(f"{self.qualifiers(var)}Value {self.var_name(var)} = {init};")
        if func.is_vararg and func.arg_var is not None:
            var = func.arg_var
            if var.captured or self.reads.get(var, 0) > 0:
                extra = f"vararg_table(L, args.size() > {len(func.params)} ? args.subspan({len(func.params)}) : Args{{}})"
                if var.captured:
                    self.line(f"Cell* const {self.var_name(var)} = new_cell(L, {extra});")
                else:
                    self.line(f"{self.qualifiers(var)}Value {self.var_name(var)} = {extra};")
                self.check()
        terminated = False
        for stmt in func.body.stmts:
            self.statement(stmt)
            if terminates(stmt):
                terminated = True
                break
        if not terminated:
            self.line("return {};")
        self.frames.pop()
        text = "\n".join("  " * indent + content for indent, content in self.lines)
        uses_state = re.search(r"\bL\b", text) is not None
        uses_self = re.search(r"\bself\b", text) is not None
        uses_args = re.search(r"\bargs\b", text) is not None
        header = (
            f"Results {self.chunk.function_name(func)}({'State& L' if uses_state else 'State&'}, "
            f"{'const Function& self' if uses_self else 'const Function&'}, {'Args args' if uses_args else 'Args'}) {{"
        )
        return f"{header}\n{text}\n}}"


def emit_chunk(chunk: tree.ChunkTree, prefix: str) -> ChunkOutput:
    return ChunkEmitter(chunk, prefix).emit()
