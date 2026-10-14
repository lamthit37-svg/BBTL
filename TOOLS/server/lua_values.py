"""Giá trị của bộ đánh giá từng phần (partial evaluation) cho lua_flow.py.

Script Lua của máy chủ đọc trạng thái người chơi (cấp, túi, nhiệm vụ). Bộ đánh giá không có người chơi
thật, nên trạng thái là giá trị tượng trưng: NumSym (đại lượng số), Dom01 (kết quả 0/1 của một vị từ),
Choice (giá trị phụ thuộc điều kiện). So sánh một giá trị tượng trưng với hằng cho ra điều kiện DNF
(lua_bool). Mọi thứ không mô hình hoá được thành Unsupported kèm lý do, không bao giờ đoán.
"""
from __future__ import annotations

from dataclasses import dataclass

import lua_bool as B


class Unsupported(Exception):
    """Cấu trúc hay API chưa mô hình hoá; lý do đi vào báo cáo độ phủ."""


@dataclass(frozen=True)
class Param:
    kind: str


@dataclass(frozen=True)
class Tpl:
    parts: tuple


@dataclass(frozen=True)
class NumSym:
    kind: str
    args: tuple = ()


@dataclass(frozen=True)
class Dom01:
    cond: frozenset


@dataclass(frozen=True)
class Inc:
    """Đại lượng số tượng trưng cộng một hằng số nguyên (ví dụ objective + 1)."""

    sym: "NumSym"
    delta: int


@dataclass(frozen=True)
class Choice:
    cond: frozenset
    then: object
    other: object


@dataclass(frozen=True)
class RandIdx:
    """Kết quả của random(n) với n hằng: chỉ số 1..n chọn lúc chạy. Chỉ được dùng để chọn phần tử bảng chữ (Pick)."""

    count: int


@dataclass(frozen=True)
class Pick:
    """Một trong các chữ, chọn ngẫu nhiên đều lúc chạy (bảng chữ lời chào được chỉ mục bằng random)."""

    options: tuple


@dataclass(frozen=True)
class NameSym:
    who: str


@dataclass(frozen=True)
class HeldScript:
    """GetScriptIDByMissionID(quest): script của nhiệm vụ nhân vật đang giữ, -1 khi không giữ. Chỉ so với -1 hoặc
    đưa vào
    TGetMissionName: các dùng khác cần số thật của script nên không trích được."""

    quest: int


@dataclass(frozen=True)
class Marker:
    """Giá trị đánh dấu: sceneId, selfId, targetId, chỉ số ô nhiệm vụ."""

    kind: str
    arg: object = None


class LTable:
    """Bảng Lua; khoá số hoặc chuỗi. Tham chiếu chung như Lua."""

    def __init__(self, items: dict | None = None) -> None:
        self.items: dict = items if items is not None else {}

    def length(self) -> int:
        count = 0
        while (count + 1) in self.items:
            count += 1
        return count


def key_of(value: object) -> object:
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return value


SYMBOLIC = (NumSym, Dom01, NameSym, HeldScript, Choice, Inc)
RANDOM = (RandIdx, Pick)  # giá trị chọn lúc chạy: không so sánh, không nối


# nguyên tử tương ứng với đại lượng số: kind -> (op "ít nhất", op "bằng" hoặc None)
NUM_ATOMS = {
    "level": ("level_at_least", None),
    "item_count": ("item_count_at_least", None),
    "bag_space": ("bag_space_at_least", None),
    "money": ("money_at_least", None),
    "objective": ("objective_at_least", None),
    "counter": ("counter_at_least", "counter_is"),
    "sect": ("sect_at_least", "sect_is"),
    "gender": ("gender_at_least", "gender_is"),
    "team_size": ("team_size_at_least", None),
    "quest_count": ("quest_count_at_least", None),
    "hour": ("hour_at_least", None),
    "weekday": ("weekday_at_least", "weekday_is"),
    "minute": ("minute_at_least", None),
    "radio": ("radio_at_least", "radio_is"),
    "ability": ("ability_at_least", "ability_is"),
    "guild": ("guild_at_least", "guild_is"),
    "clock": ("clock_at_least", "clock_is"),
    "monster": ("monster_at_least", "monster_is"),
    "area": ("area_at_least", "area_is"),
    "event_item": ("event_item_at_least", "event_item_is"),
}


def _num(value: object) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return None


def _cmp_const(op: str, left: float, right: float) -> bool:
    return {
        "==": left == right,
        "~=": left != right,
        "<": left < right,
        "<=": left <= right,
        ">": left > right,
        ">=": left >= right,
    }[op]


_FLIP = {"<": ">", ">": "<", "<=": ">=", ">=": "<=", "==": "==", "~=": "~="}


def _num_atom_cmp(sym: NumSym, op: str, const: float) -> frozenset:
    if sym.kind not in NUM_ATOMS:
        raise Unsupported(f"đại lượng {sym.kind} chưa có nguyên tử")
    ge_op, eq_op = NUM_ATOMS[sym.kind]
    bound = int(const)
    if const != bound:
        raise Unsupported("so sánh số thực với đại lượng nguyên")

    def ge(n: int) -> frozenset:
        return B.atom(ge_op, *sym.args, n)

    if op == ">=":
        return ge(bound)
    if op == ">":
        return ge(bound + 1)
    if op == "<":
        return B.b_not(ge(bound))
    if op == "<=":
        return B.b_not(ge(bound + 1))
    equal = B.atom(eq_op, *sym.args, bound) if eq_op else B.b_and(ge(bound), B.b_not(ge(bound + 1)))
    return equal if op == "==" else B.b_not(equal)


def _dom_cmp(dom: Dom01, op: str, const: float) -> frozenset:
    when_one = _cmp_const(op, 1.0, const)
    when_zero = _cmp_const(op, 0.0, const)
    if when_one and when_zero:
        return B.TRUE
    if when_one:
        return dom.cond
    if when_zero:
        return B.b_not(dom.cond)
    return B.FALSE


def compare(op: str, left: object, right: object) -> object:
    """Kết quả so sánh: bool Python khi cả hai hằng, ngược lại điều kiện DNF."""
    if isinstance(left, RANDOM) or isinstance(right, RANDOM):
        raise Unsupported("giá trị ngẫu nhiên chỉ dùng để chọn chữ, không so sánh được")
    if isinstance(left, SYMBOLIC) and not isinstance(right, SYMBOLIC):
        return _compare_sym(op, left, right)
    if isinstance(right, SYMBOLIC) and not isinstance(left, SYMBOLIC):
        return _compare_sym(_FLIP[op], right, left)
    if isinstance(left, SYMBOLIC) or isinstance(right, SYMBOLIC):
        return _counter_vs_clock(op, left, right)
    return _compare_const(op, left, right)


CLOCK_RELATIONS = {"<": (-1,), "<=": (-1, 0), "==": (0,), ">=": (0, 1), ">": (1,), "~=": (-1, 1)}


def _counter_vs_clock(op: str, left: object, right: object) -> frozenset:
    """Bộ đếm nhiệm vụ so với đồng hồ lịch (ngày, giờ...), lịch là ĐẦU VÀO của máy chủ chứ không đọc đồng hồ thật."""
    if isinstance(right, NumSym) and right.kind == "counter" and isinstance(left, NumSym) and left.kind == "clock":
        return _counter_vs_clock(_FLIP[op], right, left)
    ok = isinstance(left, NumSym) and left.kind == "counter" and isinstance(right, NumSym) and right.kind == "clock"
    if not ok:
        raise Unsupported("so sánh hai giá trị tượng trưng")
    result = B.FALSE
    for relation in CLOCK_RELATIONS[op]:
        result = B.b_or(result, B.atom("counter_vs_clock", left.args[0], right.args[0], relation))
    return result


def _compare_const(op: str, left: object, right: object) -> bool:
    lnum, rnum = _num(left), _num(right)
    if lnum is not None and rnum is not None:
        return _cmp_const(op, lnum, rnum)
    if op in ("==", "~="):
        same = left == right and type(left) is type(right)
        return same if op == "==" else not same
    raise Unsupported("so sánh hai kiểu khác nhau")


def _compare_sym(op: str, sym: object, const: object) -> object:
    if isinstance(sym, Inc):
        number = _num(const)
        if number is None:
            raise Unsupported("so sánh đại lượng số với phi số")
        return _num_atom_cmp(sym.sym, op, number - sym.delta)
    if isinstance(sym, NumSym):
        number = _num(const)
        if number is None:
            raise Unsupported("so sánh đại lượng số với phi số")
        return _num_atom_cmp(sym, op, number)
    if isinstance(sym, Dom01):
        number = _num(const)
        if number is None:
            raise Unsupported("so sánh vị từ với phi số")
        return _dom_cmp(sym, op, number)
    if isinstance(sym, NameSym):
        return _name_cmp(sym, op, const)
    if isinstance(sym, HeldScript):
        return _held_cmp(sym, op, const)
    assert isinstance(sym, Choice)
    return _choice_cmp(sym, op, const)


def _held_cmp(sym: HeldScript, op: str, const: object) -> frozenset:
    """`GetScriptIDByMissionID(q) ~= -1` là đang giữ nhiệm vụ q (script thật không bao giờ âm)."""
    if op not in ("==", "~=") or _num(const) != -1:
        raise Unsupported("script nhiệm vụ đang giữ chỉ so với -1")
    held = B.atom("quest_active", sym.quest)
    return held if op == "~=" else B.b_not(held)


def _name_cmp(sym: NameSym, op: str, const: object) -> frozenset:
    if op not in ("==", "~=") or not isinstance(const, str):
        raise Unsupported("so sánh tên với phi chuỗi")
    if sym.who.startswith("quest:"):
        named = B.atom("quest_named", int(sym.who.removeprefix("quest:")), const.strip())
        return named if op == "==" else B.b_not(named)
    ops = {"target": "target_name", "monster": "event_monster_name"}
    if sym.who not in ops:
        raise Unsupported(f"so sánh tên của {sym.who}")
    found = B.atom(ops[sym.who], const.strip())
    return found if op == "==" else B.b_not(found)


def _choice_cmp(sym: Choice, op: str, const: object) -> object:
    first = compare(op, sym.then, const)
    second = compare(op, sym.other, const)
    left = as_bool(first)
    right = as_bool(second)
    return B.b_or(B.b_and(sym.cond, left), B.b_and(B.b_not(sym.cond), right))


def as_bool(value: object) -> frozenset:
    """Chuyển kết quả so sánh (bool hoặc DNF) sang DNF."""
    if isinstance(value, bool):
        return B.TRUE if value else B.FALSE
    if isinstance(value, frozenset):
        return value
    raise Unsupported(f"không dùng được làm điều kiện: {type(value).__name__}")


def truthy(value: object) -> object:
    """Chân trị kiểu Lua 4: chỉ nil là sai. Vị từ tượng trưng luôn đúng (script gốc luôn so sánh)."""
    if isinstance(value, (frozenset, bool)):
        return as_bool(value)
    if isinstance(value, Choice):
        raise Unsupported("chân trị của giá trị theo điều kiện")
    return B.FALSE if value is None else B.TRUE


def _symbolic_step(op: str, left: object, right: object) -> object:
    """NumSym (hoặc Inc) cộng/trừ hằng nguyên thành Inc; None nếu không đúng dạng."""
    if op not in ("+", "-"):
        return None
    sign = 1 if op == "+" else -1
    if isinstance(left, (NumSym, Inc)) and _is_int(right):
        base = left if isinstance(left, Inc) else Inc(left, 0)
        return Inc(base.sym, base.delta + sign * int(right))
    if op == "+" and isinstance(right, (NumSym, Inc)) and _is_int(left):
        base = right if isinstance(right, Inc) else Inc(right, 0)
        return Inc(base.sym, base.delta + int(left))
    return None


def _is_int(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and float(value).is_integer()


def arith(op: str, left: object, right: object) -> object:
    stepped = _symbolic_step(op, left, right)
    if stepped is not None:
        return stepped
    lnum, rnum = _num(left), _num(right)
    if lnum is None or rnum is None:
        raise Unsupported(f"phép tính {op} trên giá trị không phải hằng số")
    if op == "+":
        result = lnum + rnum
    elif op == "-":
        result = lnum - rnum
    elif op == "*":
        result = lnum * rnum
    elif op == "/":
        if rnum == 0:
            raise Unsupported("chia cho 0")
        result = lnum / rnum
    else:
        if rnum == 0:
            raise Unsupported("luỹ thừa suy biến")
        result = lnum**rnum
    return int(result) if float(result).is_integer() and abs(result) < 2**53 else result


def number_text(value: float) -> str:
    return str(int(value)) if float(value).is_integer() else repr(value)


def concat(left: object, right: object) -> object:
    """Phép nối chuỗi của Lua; trả chuỗi hằng hay Tpl (có tham số) hay Choice."""
    if isinstance(left, RANDOM) or isinstance(right, RANDOM):
        raise Unsupported("chữ chọn ngẫu nhiên không nối được với chuỗi khác")
    if isinstance(left, Choice) or isinstance(right, Choice):
        return _concat_choice(left, right)
    lparts, rparts = _parts(left), _parts(right)
    merged: list = []
    for part in (*lparts, *rparts):
        if merged and isinstance(part, str) and isinstance(merged[-1], str):
            merged[-1] += part
        else:
            merged.append(part)
    if all(isinstance(part, str) for part in merged):
        return "".join(merged)
    return Tpl(tuple(merged))


def _concat_choice(left: object, right: object) -> object:
    if isinstance(left, Choice):
        return Choice(left.cond, concat(left.then, right), concat(left.other, right))
    assert isinstance(right, Choice)
    return Choice(right.cond, concat(left, right.then), concat(left, right.other))


def _parts(value: object) -> tuple:
    if isinstance(value, str):
        return (value,)
    if isinstance(value, Tpl):
        return value.parts
    if isinstance(value, Param):
        return (value,)
    number = _num(value)
    if number is not None:
        return (number_text(number),)
    raise Unsupported(f"nối chuỗi với {type(value).__name__}")
