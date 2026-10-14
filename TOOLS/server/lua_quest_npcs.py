"""NPC giao/trả nhiệm vụ suy từ OnEnumerate của script nhiệm vụ.

Chỉ dùng để đối chiếu với NPC trong bảng client và để báo cáo: gắn nhiệm vụ vào NPC thật dựa vào danh sách
`g_eventList` của script NPC (lua_npc.py). Giao/trả suy từ các nguyên tử target_name trên đường dẫn tới lựa
chọn biểu tượng 1, 3 (nhận) hoặc 2, 4 (đang làm / trả) của OnEnumerate.
"""
from __future__ import annotations

from collections.abc import Callable, Iterator

import lua_bool as B
import lua_flow as F
import lua_quest as Q
from lua_values import Unsupported

MAX_PATHS = 400


def iter_paths(low: F.Lowerer, steps: list, path: frozenset, budget: list) -> Iterator:
    """Duyệt sâu mọi bước của danh sách, kèm điều kiện đường đi; theo cả khối call/goto."""
    for step in steps:
        budget[0] -= 1
        if budget[0] < 0:
            raise Unsupported("duyệt luồng quá dài")
        yield path, step
        if step.kind == "branch":
            yield from iter_paths(low, step.then or [], B.b_and(path, step.cond), budget)
            yield from iter_paths(low, step.other or [], B.b_and(path, B.b_not(step.cond)), budget)
        elif step.kind in ("call", "goto"):
            yield from iter_paths(low, low.flow.blocks[step.data[0]], path, budget)


def extract_npcs(low: F.Lowerer, unit: F.Unit, rec: Q.QuestRec) -> None:
    """Từ OnEnumerate: tên NPC nhận (biểu tượng 1, 3) và NPC trả (biểu tượng 2, 4)."""
    func = Q.func_of(unit, "OnEnumerate")
    if func is None:
        rec.issues.append("thiếu OnEnumerate")
        return
    try:
        flow = low.lower(unit, func.name, low.entry_args(func))
    except Unsupported as exc:
        rec.issues.append(f"OnEnumerate: {exc}")
        return
    for path, step in iter_paths(low, flow.root, B.TRUE, [20000]):
        if step.kind != "option":
            continue
        _record_npc(rec, step.data[1], Q.reduce_cond(path, _enumerate_known(rec, step.data[1])))


def _enumerate_known(rec: Q.QuestRec, icon: int) -> Callable:
    """Biết trước: trạng thái nhiệm vụ của lựa chọn này, và điều kiện nhận (cho biểu tượng nhận)."""
    quest = rec.quest
    accept_atoms = B.atoms_of(rec.accept_cond)

    def known(item: B.Atom) -> bool | None:
        if item.op == "quest_done" and item.args == (quest,):
            return item.neg
        if item.op == "quest_active" and item.args == (quest,):
            return not item.neg if icon in (2, 4) else item.neg
        if item.op == "target_name":
            return None
        if icon in (1, 3) and item in accept_atoms:
            return True
        return None

    return known


def _record_npc(rec: Q.QuestRec, icon: int, residual: frozenset) -> None:
    positive: set = set()
    negative: set = set()
    for clause in residual:
        for item in clause:
            if item.op != "target_name":
                continue
            (positive if not item.neg else negative).add(item.args[0])
    if icon in (1, 3):
        rec.giver_names |= positive
        rec.giver_excluded |= negative
    elif icon in (2, 4):
        rec.turn_in_names |= positive
        rec.turn_in_excluded |= negative
