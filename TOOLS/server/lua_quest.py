"""Rút một script nhiệm vụ (khối MisDescBegin) thành bản ghi nhiệm vụ có kiểu.

Không dịch từng dòng Lua: ta chạy bộ đánh giá từng phần trên CheckAccept, CheckSubmit, OnAccept, OnSubmit,
OnAbandon rồi nhận ra "đường vui" (người chơi đủ điều kiện, túi còn chỗ) để lấy điều kiện nhận, điều kiện
trả (tiến độ mục tiêu), hiệu ứng lúc nhận, thưởng và hiệu ứng thêm lúc trả. Chỗ nào không qui về dạng
chuẩn thì ghi vào `issues` kèm lý do; nhiệm vụ có issue thành "cần handler", không bị bỏ im.
"""
from __future__ import annotations

from dataclasses import dataclass, field

import lua_bool as B
import lua_flow as F
import lua_values as V
from lua_flow import Step
from lua_values import Unsupported

BOOKKEEPING = ("quest_accept", "quest_remove", "quest_mark_done")
STATE_ATOMS = ("quest_active", "quest_done")


@dataclass
class Reward:
    group: str  # fixed, choice
    kind: str  # money, bound_money, exp, item
    ref: int
    count: int
    cond: frozenset = B.TRUE


@dataclass
class Page:
    kind: str  # accept, demand, continue
    lines: list = field(default_factory=list)  # (loại, text, a, b)


@dataclass
class QuestRec:
    quest: int
    script: int
    path: str
    declared: dict
    issues: list = field(default_factory=list)
    accept_cond: frozenset = B.TRUE
    ready_cond: frozenset = B.TRUE
    accept_fx: list = field(default_factory=list)
    abandon_fx: list = field(default_factory=list)
    turn_in_fx: list = field(default_factory=list)
    rewards: list = field(default_factory=list)
    objectives: list = field(default_factory=list)  # (idx, kind, target, count)
    repeat: str = "once"
    offers_next: list = field(default_factory=list)
    giver_names: set = field(default_factory=set)
    giver_excluded: set = field(default_factory=set)
    turn_in_names: set = field(default_factory=set)
    turn_in_excluded: set = field(default_factory=set)
    hooks: list = field(default_factory=list)  # (sự kiện, [(điều kiện, bước hiệu ứng)])


def short(name: str) -> str:
    return name.split("_", 1)[1] if "_" in name else name


def declared_of(unit: F.Unit) -> dict:
    """Biến g_* của script, bỏ tiền tố xNNNNNN_."""
    found: dict = {}
    for name, value in unit.globals.items():
        if name.startswith("x") and "_g_" in name:
            found[name.split("_", 1)[1]] = value
    return found


def func_of(unit: F.Unit, name: str) -> object:
    for key, func in unit.funcs.items():
        if short(key) == name:
            return func
    return None


def make_known(quest: int, ready_atoms: set) -> object:
    def known(item: B.Atom) -> bool | None:
        if item.op == "quest_active" and item.args == (quest,):
            return not item.neg
        if item.op == "quest_done" and item.args == (quest,):
            return item.neg
        if item.op == "bag_space_at_least":
            return not item.neg
        if item.op == "quest_slots_free_at_least":
            return not item.neg
        if item in ready_atoms:
            return True
        return None

    return known


def reduce_cond(cond: frozenset, known: object) -> frozenset:
    """Rút gọn điều kiện khi biết trước một số nguyên tử; known(atom) trả True, False hoặc None (chưa biết)."""
    out: set = set()
    for clause in cond:
        kept = []
        dead = False
        for item in clause:
            value = known(item)
            if value is False:
                dead = True
                break
            if value is None:
                kept.append(item)
        if not dead:
            out.add(frozenset(kept))
    return B._absorb(out)


def walk_effects(low: F.Lowerer, steps: list, known: object, out: list, guard: frozenset, issues: list) -> None:
    """Đi theo đường vui của dòng bước: gom hiệu ứng kèm điều kiện còn lại (guard).

    Khối nối sau một chuỗi if (goto) được đi MỘT lần với điều kiện là HOẶC của các nhánh chạy tới nó, không đi
    lại cho từng nhánh:
    nếu không thì thưởng và hiệu ứng nằm sau vòng `for ... if` mang theo điều kiện của từng nhánh vòng (hàng
    trăm dòng thừa,
    sai nghĩa vì sau chỗ nối các nhánh đó không còn phân biệt)."""
    exits, _falls, _guard = _walk(low, steps, known, out, guard, issues)
    _drain(low, exits, known, out, issues)


def _drain(low: F.Lowerer, exits: list, known: object, out: list, issues: list) -> None:
    """Đi các khối nối còn chờ; mỗi khối một lần, theo thứ tự xuất hiện đầu tiên."""
    pending = list(exits)
    while pending:
        block = pending[0][0]
        merged = B.FALSE
        rest = []
        for target, when in pending:
            if target == block:
                merged = _join(merged, when)
            else:
                rest.append((target, when))
        pending = rest
        if B.is_false(merged):
            continue
        more, _falls, _guard = _walk(low, low.flow.blocks[block], known, out, merged, issues)
        pending += more


def _walk(low: F.Lowerer, steps: list, known: object, out: list, guard: frozenset, issues: list) -> tuple:
    """(các khối nối chờ đi, còn chạy hết danh sách không, điều kiện lúc chạy hết). Hiệu ứng ghi vào out."""
    exits: list = []
    for step in steps:
        if step.kind == "effect":
            if not B.is_false(guard):
                out.append((guard, step))
        elif step.kind == "branch":
            more, falls, guard = _walk_branch(low, step, known, out, guard, issues)
            exits += more
            if not falls:
                return exits, False, B.FALSE
        elif step.kind == "call":
            walk_effects(low, low.flow.blocks[step.data[0]], known, out, guard, issues)
        elif step.kind == "goto":
            return [*exits, (step.data[0], guard)], False, B.FALSE
        elif step.kind == "ret":
            return exits, False, B.FALSE
    return exits, True, guard


def _walk_branch(low: F.Lowerer, step: Step, known: object, out: list, guard: frozenset, issues: list) -> tuple:
    cond = reduce_cond(step.cond, known)
    if B.is_true(cond):
        return _walk(low, step.then or [], known, out, guard, issues)
    if B.is_false(cond):
        return _walk(low, step.other or [], known, out, guard, issues)
    then_exits, then_falls, then_guard = _walk(low, step.then or [], known, out, _meet(guard, cond), issues)
    other_exits, other_falls, other_guard = _walk(low, step.other or [], known, out, _meet(guard, _flip(cond)), issues)
    after = B.FALSE
    if then_falls:
        after = _join(after, then_guard)
    if other_falls:
        after = _join(after, other_guard)
    return then_exits + other_exits, then_falls or other_falls, after


def _meet(left: frozenset, right: frozenset) -> frozenset:
    try:
        return B.b_and(left, right)
    except B.TooComplex:
        raise Unsupported("điều kiện đường đi quá phức tạp") from None


def _flip(cond: frozenset) -> frozenset:
    try:
        return B.b_not(cond)
    except B.TooComplex:
        raise Unsupported("điều kiện đường đi quá phức tạp") from None


def _join(left: frozenset, right: frozenset) -> frozenset:
    """HOẶC có gộp hai mệnh đề chỉ khác nhau đúng một nguyên tử đối nhau (A.c + A.!c = A)."""
    try:
        return B.b_or_merged(left, right)
    except B.TooComplex:
        raise Unsupported("điều kiện đường đi quá phức tạp") from None


def classify_rewards(effects: list, quest: int, rec: QuestRec) -> list:
    """Tách thưởng khỏi hiệu ứng thường. Trả phần hiệu ứng còn lại (guard, step)."""
    rest = []
    for guard, step in effects:
        op = step.data[0]
        if op in BOOKKEEPING and step.data[1] == quest:
            continue
        reward = _as_reward(guard, step)
        if reward is None:
            rest.append((guard, step))
        else:
            rec.rewards.append(reward)
    return rest


def _as_reward(guard: frozenset, step: Step) -> Reward | None:
    op = step.data[0]
    split = _reward_group(guard)
    if split is None:
        return None
    group, cond = split
    if op == "give_money":
        return Reward(group, "money" if step.data[2] == 0 else "bound_money", 0, step.data[1], cond)
    if op == "give_exp":
        return Reward(group, "exp", 0, step.data[1], cond)
    if op == "give_item":
        return Reward(group, "item", step.data[1], step.data[2], cond)
    return None


def _reward_group(guard: frozenset) -> tuple | None:
    """(nhóm, điều kiện còn lại). Lựa chọn thưởng (radio_is) là nhóm choice; còn lại là fixed có điều kiện."""
    radios = [any(item.op == "radio_is" for item in clause) for clause in guard]
    if not any(radios):
        return "fixed", guard
    if len(guard) != 1:
        return None
    clause = next(iter(guard))
    picked = [item for item in clause if item.op == "radio_is" and not item.neg]
    if len(picked) != 1 or any(item.op == "radio_is" for item in clause if item not in picked):
        return None
    return "choice", frozenset({frozenset(item for item in clause if item not in picked)})


def strip_state(cond: frozenset, quest: int) -> frozenset:
    return reduce_cond(cond, make_known(quest, set()))


def objectives_of(ready: frozenset, rec: QuestRec) -> None:
    """Mục tiêu từ điều kiện trả. Một mệnh đề duy nhất mới là mục tiêu tuần tự; nhiều mệnh đề là HOẶC."""
    if len(ready) > 1:
        rec.issues.append("điều kiện trả có HOẶC")
        return
    clause = next(iter(ready)) if ready else frozenset()
    for item in sorted(clause, key=lambda a: (a.op, a.args)):
        if item.neg:
            continue
        if item.op == "objective_at_least":
            rec.objectives.append((item.args[1], "progress", 0, item.args[2]))
        elif item.op == "item_count_at_least":
            rec.objectives.append((0, "collect", item.args[0], item.args[1]))
        elif item.op not in ("quest_active", "quest_done"):
            rec.issues.append(f"điều kiện trả có {item.op}")


def lower_value(low: F.Lowerer, unit: F.Unit, name: str) -> object:
    """Giá trị trả về của hàm một tham số vào kiểu (sceneId, selfId, ...)."""
    func = func_of(unit, name)
    if func is None:
        raise Unsupported(f"thiếu hàm {name}")
    args = low.entry_args(func)
    return low.call_value(unit, func, args)


def bool_of_result(value: object, truth: int) -> frozenset:
    return V.as_bool(V.compare("==", value, truth))


def extract(low: F.Lowerer, unit: F.Unit, path: str) -> QuestRec:
    decl = declared_of(unit)
    quest = decl.get("g_MissionId")
    if not isinstance(quest, int):
        raise Unsupported("không có g_MissionId số")
    rec = QuestRec(quest, unit.script_id, path, decl)
    _accept_cond(low, unit, rec)
    _ready_cond(low, unit, rec)
    _accept_fx(low, unit, rec)
    _submit(low, unit, rec)
    _abandon(low, unit, rec)
    _hooks(low, unit, rec)
    return rec


def _guard(rec: QuestRec, what: str, action: object) -> None:
    try:
        action()
    except (Unsupported, B.TooComplex, KeyError, IndexError, TypeError) as exc:
        rec.issues.append(f"{what}: {exc}")


def _accept_cond(low: F.Lowerer, unit: F.Unit, rec: QuestRec) -> None:
    def run() -> None:
        value = lower_value(low, unit, "CheckAccept")
        rec.accept_cond = reduce_cond(V.as_bool(V.compare(">", value, 0)), make_known(rec.quest, set()))

    _guard(rec, "CheckAccept", run)


def _ready_cond(low: F.Lowerer, unit: F.Unit, rec: QuestRec) -> None:
    def run() -> None:
        value = lower_value(low, unit, "CheckSubmit")
        full = V.as_bool(V.compare("==", value, 1))
        rec.ready_cond = strip_state(full, rec.quest)
        objectives_of(rec.ready_cond, rec)

    _guard(rec, "CheckSubmit", run)


def _flow_effects(low: F.Lowerer, unit: F.Unit, name: str, rec: QuestRec, known: object) -> list:
    func = func_of(unit, name)
    if func is None:
        raise Unsupported(f"thiếu hàm {name}")
    flow = low.lower(unit, func.name, low.entry_args(func))
    effects: list = []
    walk_effects(low, flow.root, known, effects, B.TRUE, rec.issues)
    return effects


def _ready_atoms(rec: QuestRec) -> set:
    return {item for clause in rec.ready_cond for item in clause}


def _accept_fx(low: F.Lowerer, unit: F.Unit, rec: QuestRec) -> None:
    def run() -> None:
        effects = _flow_effects(low, unit, "OnAccept", rec, make_known(rec.quest, set()))
        saw_accept = any(s.data[0] == "quest_accept" and s.data[1] == rec.quest for _, s in effects)
        if not saw_accept:
            rec.issues.append("OnAccept không AddMission đúng nhiệm vụ")
        rec.accept_fx = _plain_effects(rec, classify_rewards_none(effects, rec.quest))

    _guard(rec, "OnAccept", run)


def classify_rewards_none(effects: list, quest: int) -> list:
    """Bỏ bước sổ sách (nhận) của chính nhiệm vụ này, giữ phần còn lại."""
    return [(g, s) for g, s in effects if not (s.data[0] in BOOKKEEPING and s.data[1] == quest)]


def _plain_effects(rec: QuestRec, effects: list) -> list:
    """Hiệu ứng còn lại kèm điều kiện (guard, step)."""
    return list(effects)


def _submit(low: F.Lowerer, unit: F.Unit, rec: QuestRec) -> None:
    def run() -> None:
        known = make_known(rec.quest, _ready_atoms(rec))
        effects = _flow_effects(low, unit, "OnSubmit", rec, known)
        has_done = any(s.data[0] == "quest_mark_done" and s.data[1] == rec.quest for _, s in effects)
        has_remove = any(s.data[0] == "quest_remove" and s.data[1] == rec.quest for _, s in effects)
        if not has_remove:
            rec.issues.append("OnSubmit không DelMission")
        rec.repeat = "once" if has_done else "loop"
        rest = classify_rewards(effects, rec.quest, rec)
        rec.turn_in_fx = _plain_effects(rec, rest)
        _collect_offers(rec)

    _guard(rec, "OnSubmit", run)


def _collect_offers(rec: QuestRec) -> None:
    kept = []
    for guard, step in rec.turn_in_fx:
        if step.data[0] == "offer_next":
            rec.offers_next.append((guard, step.data[1]))
        else:
            kept.append((guard, step))
    rec.turn_in_fx = kept


def _abandon(low: F.Lowerer, unit: F.Unit, rec: QuestRec) -> None:
    def run() -> None:
        effects = _flow_effects(low, unit, "OnAbandon", rec, make_known(rec.quest, set()))
        rec.abandon_fx = _plain_effects(rec, classify_rewards_none(effects, rec.quest))

    _guard(rec, "OnAbandon", run)


# Hàm bắt sự kiện của script nhiệm vụ: tên hàm -> (loại sự kiện, tham số mang ý nghĩa sự kiện).
HOOKS = {
    "OnKillObject": ("kill", {"objdataId": V.NumSym("monster"), "objId": V.Marker("monster")}),
    "OnEnterArea": ("enter_area", {"zoneId": V.NumSym("area")}),
    "OnEnterZone": ("enter_area", {"zoneId": V.NumSym("area")}),
    "OnItemChanged": ("item_changed", {"itemdataId": V.NumSym("event_item")}),
}


def hook_args(low: F.Lowerer, func: object, extra: dict) -> list:
    base = low.entry_args(func)
    return [extra.get(param, value) for param, value in zip(func.params, base)]


def _hooks(low: F.Lowerer, unit: F.Unit, rec: QuestRec) -> None:
    for name, (event, extra) in HOOKS.items():
        func = func_of(unit, name)
        if func is None or not func.body:
            continue

        def run(func: object = func, event: str = event, extra: dict = extra) -> None:
            flow = low.lower(unit, func.name, hook_args(low, func, extra))
            effects: list = []
            walk_effects(low, flow.root, make_known(rec.quest, set()), effects, B.TRUE, rec.issues)
            if effects:
                rec.hooks.append((event, effects))

        _guard(rec, name, run)
