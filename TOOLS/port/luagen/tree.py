"""Cây cú pháp đã phân giải phạm vi của bộ dịch Lua → C++. Bộ phân tích (parser.py) dựng cây này theo đúng thứ tự của
lparser.c 5.0.1 nên tên đã gắn với biến cục bộ, upvalue hay toàn cục ngay lúc dựng.

Biến cục bộ (`Var`) bị hàm con bắt thì `captured` thành True: mã sinh giữ nó trong một `Cell`, biến khác là `Value` thường.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(eq=False, slots=True)
class Var:
    """Một biến cục bộ (kể cả tham số, `self`, `arg`, biến vòng for). Mỗi lần khai báo là một đối tượng riêng."""

    name: str
    func: "Func"
    # Thứ tự khai báo trong hàm: dùng đặt tên C++.
    serial: int
    # Có hàm con nào dùng làm upvalue không.
    captured: bool = False


@dataclass(eq=False, slots=True)
class Upvalue:
    """Một upvalue của hàm con: lấy từ biến cục bộ của hàm cha (`parent_var`), hay từ upvalue của hàm cha (`parent_index`)."""

    name: str
    var: Var
    parent_var: Var | None
    parent_index: int | None


# ---------------- biểu thức ----------------


@dataclass(eq=False, slots=True)
class Nil:
    pass


@dataclass(eq=False, slots=True)
class TrueE:
    pass


@dataclass(eq=False, slots=True)
class FalseE:
    pass


@dataclass(eq=False, slots=True)
class Num:
    value: float


@dataclass(eq=False, slots=True)
class Str:
    value: bytes


@dataclass(eq=False, slots=True)
class LocalRef:
    var: Var


@dataclass(eq=False, slots=True)
class UpvalRef:
    index: int
    var: Var


@dataclass(eq=False, slots=True)
class GlobalRef:
    name: str


@dataclass(eq=False, slots=True)
class Index:
    obj: "Expr"
    key: "Expr"
    line: int


@dataclass(eq=False, slots=True)
class Call:
    func: "Expr"
    args: list["Expr"]
    line: int


@dataclass(eq=False, slots=True)
class Method:
    obj: "Expr"
    name: str
    args: list["Expr"]
    line: int


@dataclass(eq=False, slots=True)
class FuncExpr:
    func: "Func"


@dataclass(eq=False, slots=True)
class Bin:
    op: str  # + - * / ^ .. == ~= < <= > >= and or
    left: "Expr"
    right: "Expr"
    line: int


@dataclass(eq=False, slots=True)
class Un:
    op: str  # '-' hay 'not'
    operand: "Expr"
    line: int


@dataclass(eq=False, slots=True)
class Paren:
    """`(e)`: một giá trị (cắt kết quả nhiều giá trị của lời gọi), không gán được."""

    expr: "Expr"


@dataclass(eq=False, slots=True)
class ListItem:
    value: "Expr"


@dataclass(eq=False, slots=True)
class RecordItem:
    key: "Expr"
    value: "Expr"


@dataclass(eq=False, slots=True)
class TableCons:
    items: list[ListItem | RecordItem]
    line: int


Expr = (
    Nil | TrueE | FalseE | Num | Str | LocalRef | UpvalRef | GlobalRef | Index | Call | Method | FuncExpr | Bin | Un | Paren
    | TableCons
)


def is_multi(expr: Expr) -> bool:
    """Biểu thức có thể cho nhiều giá trị (lời gọi hàm không bọc ngoặc)."""
    return isinstance(expr, (Call, Method))


# ---------------- câu lệnh ----------------


@dataclass(eq=False, slots=True)
class Block:
    stmts: list["Stmt"] = field(default_factory=list)


@dataclass(eq=False, slots=True)
class LocalStat:
    vars: list[Var]
    exprs: list[Expr]


@dataclass(eq=False, slots=True)
class LocalFunc:
    var: Var
    func: "Func"


@dataclass(eq=False, slots=True)
class AssignStat:
    targets: list[LocalRef | UpvalRef | GlobalRef | Index]
    exprs: list[Expr]
    line: int


@dataclass(eq=False, slots=True)
class CallStat:
    call: Call | Method


@dataclass(eq=False, slots=True)
class DoStat:
    block: Block


@dataclass(eq=False, slots=True)
class WhileStat:
    cond: Expr
    block: Block
    line: int


@dataclass(eq=False, slots=True)
class RepeatStat:
    block: Block
    cond: Expr
    line: int


@dataclass(eq=False, slots=True)
class IfStat:
    tests: list[tuple[Expr, Block]]
    orelse: Block | None


@dataclass(eq=False, slots=True)
class NumFor:
    var: Var
    start: Expr
    limit: Expr
    step: Expr | None
    block: Block
    line: int


@dataclass(eq=False, slots=True)
class GenFor:
    vars: list[Var]
    exprs: list[Expr]
    block: Block
    line: int


@dataclass(eq=False, slots=True)
class ReturnStat:
    exprs: list[Expr]


@dataclass(eq=False, slots=True)
class BreakStat:
    pass


@dataclass(eq=False, slots=True)
class ContinueStat:
    pass


Stmt = (
    LocalStat | LocalFunc | AssignStat | CallStat | DoStat | WhileStat | RepeatStat | IfStat | NumFor | GenFor | ReturnStat
    | BreakStat | ContinueStat
)


@dataclass(eq=False, slots=True)
class Func:
    """Một hàm Lua: thân chunk (`parent` là None), hàm đặt tên, hàm vô danh."""

    chunk: str
    line: int
    parent: "Func | None"
    # Số thứ tự trong chunk theo thứ tự gặp `function` (thân chunk là 0).
    index: int
    params: list[Var] = field(default_factory=list)
    is_vararg: bool = False
    # Biến `arg` của hàm có `...`.
    arg_var: Var | None = None
    upvalues: list[Upvalue] = field(default_factory=list)
    body: Block = field(default_factory=Block)
    # Mọi biến cục bộ của hàm theo thứ tự khai báo.
    locals: list[Var] = field(default_factory=list)
    children: list["Func"] = field(default_factory=list)

    @property
    def proto_name(self) -> str:
        return f"{self.chunk}:{self.line}"


@dataclass(eq=False, slots=True)
class ChunkTree:
    name: str
    main: Func
    # Mọi hàm của chunk theo `index` (main là phần tử 0).
    funcs: list[Func]
