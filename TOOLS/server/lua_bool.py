"""Đại số điều kiện cho lua_extract.py: biểu thức logic ở dạng tuyển chuẩn (DNF).

Một điều kiện là tập các mệnh đề (clause); điều kiện đúng khi có ít nhất một mệnh đề mà mọi nguyên tử
đều đúng. Nguyên tử là (op, neg, đối số số nguyên) và đúng khớp với tập op đóng của module C++ `ops`
(src/server/ops). DNF cho phép biểu diễn VÀ, HOẶC và PHỦ ĐỊNH của script gốc mà không cần ngôn ngữ biểu
thức ở lúc chạy. Số mệnh đề có trần để script thù địch không làm nổ bộ nhớ.
"""
from __future__ import annotations

from dataclasses import dataclass

MAX_CLAUSES = 24
# Nguyên tử của đại lượng chỉ có MỘT giá trị tại một thời điểm (NPC đang nói chuyện chỉ có một tên): hai nguyên
# tử dương khác
# giá trị loại nhau, một nguyên tử dương làm mọi nguyên tử âm khác thừa. Giống _is nhưng đối số là chữ.
SINGLE_VALUED = frozenset({"target_name", "event_monster_name"})


class TooComplex(ValueError):
    """Điều kiện vượt trần số mệnh đề."""


@dataclass(frozen=True, order=True)
class Atom:
    op: str
    neg: bool
    args: tuple

    def negated(self) -> "Atom":
        return Atom(self.op, not self.neg, self.args)


Clause = frozenset
Bool = frozenset  # frozenset[Clause]

TRUE: Bool = frozenset({frozenset()})
FALSE: Bool = frozenset()


def atom(op: str, *args: int | str, neg: bool = False) -> Bool:
    return frozenset({frozenset({Atom(op, neg, tuple(args))})})


def _normalize(clause: Clause) -> Clause | None:
    """Mệnh đề rút gọn theo thứ tự số học; None nếu tự mâu thuẫn.

    X_at_least(a) dương kéo theo X_at_least(b) với b <= a; X_at_least(b) âm kéo theo âm của mọi ngưỡng lớn hơn.
    X_is(a) dương loại mọi X_is(b) khác a và làm thừa X_is(b) âm.
    """
    if any(item.negated() in clause for item in clause):
        return None
    floors: dict = {}
    ceilings: dict = {}
    exact: dict = {}
    for item in clause:
        if item.op.endswith("_at_least") and item.args and isinstance(item.args[-1], int):
            table = ceilings if item.neg else floors
            key = (item.op, item.args[:-1])
            table.setdefault(key, []).append(item.args[-1])
        elif (item.op.endswith("_is") or item.op in SINGLE_VALUED) and item.args and not item.neg:
            exact.setdefault((item.op, item.args[:-1]), set()).add(item.args[-1])
    if any(len(values) > 1 for values in exact.values()):
        return None
    for key, lows in floors.items():
        highs = ceilings.get(key)
        if highs and max(lows) >= min(highs):
            return None
    kept = set()
    for item in clause:
        if _redundant(item, floors, ceilings, exact):
            continue
        kept.add(item)
    return frozenset(kept)


def _redundant(item: Atom, floors: dict, ceilings: dict, exact: dict) -> bool:
    if item.op.endswith("_at_least") and item.args and isinstance(item.args[-1], int):
        key = (item.op, item.args[:-1])
        if item.neg:
            return item.args[-1] != min(ceilings[key])
        return item.args[-1] != max(floors[key])
    if (item.op.endswith("_is") or item.op in SINGLE_VALUED) and item.neg and item.args:
        return (item.op, item.args[:-1]) in exact
    return False


def _absorb(clauses: set) -> Bool:
    kept = []
    for clause in clauses:
        normal = _normalize(clause)
        if normal is not None:
            kept.append(normal)
    kept.sort(key=len)
    result: list[Clause] = []
    for clause in kept:
        if not any(smaller <= clause for smaller in result):
            result.append(clause)
    return frozenset(result)


def b_or(left: Bool, right: Bool) -> Bool:
    merged = _absorb(set(left) | set(right))
    if len(merged) > MAX_CLAUSES:
        raise TooComplex("điều kiện quá nhiều mệnh đề")
    return merged


def _complementary_pair(clauses: set) -> tuple | None:
    """Cặp mệnh đề chỉ khác nhau đúng một nguyên tử đối nhau, hoặc None."""
    ordered = sorted(clauses, key=lambda clause: (len(clause), sorted(map(repr, clause))))
    for position, first in enumerate(ordered):
        for second in ordered[position + 1:]:
            if len(first) != len(second):
                continue
            only_first, only_second = first - second, second - first
            if len(only_first) == 1 and len(only_second) == 1 and next(iter(only_first)).negated() in only_second:
                return first, second
    return None


def b_or_merged(left: Bool, right: Bool) -> Bool:
    """HOẶC rồi gộp mọi cặp mệnh đề chỉ khác nhau một nguyên tử đối nhau (A.c + A.!c = A) tới khi hết gộp được."""
    clauses = set(_absorb(set(left) | set(right)))
    while (pair := _complementary_pair(clauses)) is not None:
        first, second = pair
        clauses.discard(first)
        clauses.discard(second)
        clauses.add(first & second)
        clauses = set(_absorb(clauses))
    if len(clauses) > MAX_CLAUSES:
        raise TooComplex("điều kiện quá nhiều mệnh đề")
    return frozenset(clauses)


def b_and(left: Bool, right: Bool) -> Bool:
    if not left or not right:
        return FALSE
    if len(left) * len(right) > MAX_CLAUSES * 8:
        raise TooComplex("điều kiện quá nhiều mệnh đề")
    product = {a | b for a in left for b in right}
    merged = _absorb(product)
    if len(merged) > MAX_CLAUSES:
        raise TooComplex("điều kiện quá nhiều mệnh đề")
    return merged


def b_not(value: Bool) -> Bool:
    result = TRUE
    for clause in value:
        flipped = frozenset(frozenset({item.negated()}) for item in clause)
        result = b_and(result, flipped)
    return result


def is_true(value: Bool) -> bool:
    return frozenset() in value


def is_false(value: Bool) -> bool:
    return not value


def assume(value: Bool, facts: set) -> Bool:
    """Rút gọn khi biết trước một số nguyên tử đúng (facts) hoặc sai (nghịch đảo của chúng nằm trong facts)."""
    out: set = set()
    for clause in value:
        if any(item.negated() in facts for item in clause):
            continue
        out.add(frozenset(item for item in clause if item not in facts))
    return _absorb(out)


def atoms_of(value: Bool) -> set:
    return {item for clause in value for item in clause}
