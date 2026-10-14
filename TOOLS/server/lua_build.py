"""Dựng bản ghi nhiệm vụ cuối cùng (QuestOut) từ ba nguồn: script Lua đã hạ, bảng client, và danh bạ client.

Quy tắc ưu tiên (chủ dự án: client 2026 là thẩm quyền cao nhất): tên, cấp, NPC giao/trả, loại lấy từ bảng client khi có;
script Lua chỉ quyết định LOGIC (điều kiện, hiệu ứng, thưởng, bắt sự kiện). Nhiệm vụ không có trong danh bạ client
không hiện được ở nhật ký nhiệm vụ của client nên bị đánh dấu `not_in_client` và máy chủ từ chối nhận.
"""
from __future__ import annotations

from dataclasses import dataclass, field

import lua_bool as B
import lua_emit as E
import lua_quest as Q
import lua_tables as T
from lua_world import World, client_quest_summary, norm_name, to_int

STATUS_OK = "ok"
STATUS_UNSUPPORTED = "unsupported"

# mod_event.lua: tiền đề đầu tiên bằng 800 nghĩa là "nhiệm vụ sư môn", tiền đề thứ hai là môn phái bắt buộc.
MENPAI_MISSION = 800
# mod_event.lua: dải nhiệm vụ sư môn cấp 30..50 chỉ nhận ở cảnh môn phái của mình; ô thứ k là cảnh của môn k.
SECT_SCENES = (9, 11, 10, 12, 15, 16, 13, 17, 14)
SECT_SCENE_RANGE = range(1018729, 1018819)


@dataclass
class Obj:
    kind: str
    target: int = 0
    count: int = 0
    item: int = 0
    rate: int = 0
    scene: int = 0
    flag: int = 0
    name: str = ""
    index: int = 0


@dataclass
class RewardOut:
    group: str
    kind: str
    ref: int
    count: int
    cond: int = -1


@dataclass
class QuestOut:
    script: int
    quest: int
    source: str
    kind: int = 0
    level: int = 0
    repeat: str = "once"
    elite: int = 0
    name: str = ""
    detail: str = ""
    cont: str = ""
    done: str = ""
    accept_scene: int = -1
    accept_guid: int = 0
    accept_name: str = ""
    turn_scene: int = -1
    turn_guid: int = 0
    turn_name: str = ""
    accept_cond: int = -1
    ready_cond: int = -1
    accept_fx: int = -1
    submit_fx: int = -1
    abandon_fx: int = -1
    next_quest: int = -1
    next_script: int = 0  # dòng bảng kế tiếp (chỉ nhiệm vụ bảng); 0 là chọn theo next_quest
    penalty: int = 0
    ban_slot: int = -1
    ban_seconds: int = 0
    status: str = STATUS_OK
    in_client: int = 1
    reason: str = ""
    path: str = ""
    objectives: list = field(default_factory=list)
    rewards: list = field(default_factory=list)
    prereqs: list = field(default_factory=list)
    hooks: list = field(default_factory=list)  # (sự kiện, id bộ hiệu ứng)
    npc_links: list = field(default_factory=list)  # (vai, guid, cảnh, tên, cách)


@dataclass
class Registries:
    strings: E.Strings
    conds: E.CondRegistry = field(default_factory=E.CondRegistry)
    effects: E.EffectRegistry = field(default_factory=E.EffectRegistry)
    blocks: E.BlockTable = field(default_factory=E.BlockTable)
    groups: dict = field(default_factory=dict)  # id nhóm tên -> tên chuẩn hoá
    group_names: dict = field(default_factory=dict)  # tên chuẩn hoá -> tên gốc


def effect_set(regs: Registries, guarded: list, owner: str) -> int:
    """Danh sách (điều kiện, bước hiệu ứng) thành id bộ hiệu ứng; mỗi hiệu ứng mang id điều kiện riêng."""
    rows = [E.effect_tuple(step, regs.strings, owner, regs.conds.add(guard)) for guard, step in guarded]
    return regs.effects.add(rows)


def name_group(regs: Registries, name: str) -> int:
    """Id nhóm tên: băm tên chuẩn hoá. Tên trùng băm với tên khác là lỗi cứng, không đoán."""
    norm = norm_name(name)
    group = E.fnv1a32(norm) & 0x7FFFFFFF
    if regs.groups.setdefault(group, norm) != norm:
        raise ValueError(f"va chạm băm tên {norm!r} và {regs.groups[group]!r}")
    regs.group_names.setdefault(norm, name)
    return group


def npc_guid(world: World, scene: int, name: str) -> tuple[int, str]:
    """(guid, cách) cho NPC theo cảnh và tên; chỉ nhận khi duy nhất, không chọn thay con người."""
    found = [spawn for spawn in world.by_name.get(norm_name(name), []) if spawn.script >= 0]
    here = [spawn for spawn in found if spawn.scene == scene]
    if len(here) == 1:
        return here[0].guid, "name"
    if len(here) > 1:
        return 0, f"ambiguous:{len(here)}"
    return 0, "none" if not found else "other_scene"


def link_npc(world: World, out: QuestOut, role: str, scene: int, name: str, guid: int) -> int:
    """Ghi liên kết NPC của nhiệm vụ; guid của client được ưu tiên."""
    if guid > 0:
        how = "client" if guid in world.spawns else "client_unplaced"
        out.npc_links.append((role, guid, scene, name, how))
        return guid
    found, how = npc_guid(world, scene, name) if name else (0, "unnamed")
    out.npc_links.append((role, found, scene, name, how))
    return found


def fill_from_client(world: World, out: QuestOut) -> None:
    row = world.client_quests.get(out.quest)
    if row is None:
        return
    info = client_quest_summary(row)
    out.name = info["name"]
    out.kind = info["kind"]
    out.level = max(info["level_min"], 0)
    out.accept_guid = link_npc(world, out, "give", info["scene"], info["giver_name"], info["giver_guid"])
    out.turn_guid = link_npc(world, out, "turn", info["scene"], info["turn_in_name"], info["turn_in_guid"])
    out.accept_name, out.turn_name = info["giver_name"], info["turn_in_name"]
    out.accept_scene = out.turn_scene = info["scene"]
    out.prereqs = [item for item in info["prereq"] if item >= 0]


def declared_text(rec: Q.QuestRec, key: str) -> str:
    value = rec.declared.get(key)
    return value if isinstance(value, str) else ""


def script_quest(world: World, regs: Registries, rec: Q.QuestRec) -> QuestOut:
    out = QuestOut(rec.script, rec.quest, "script", path=rec.path)
    level = rec.declared.get("g_MissionLevel")
    out.level = level if isinstance(level, int) else 0
    out.name = declared_text(rec, "g_MissionName")
    out.detail = declared_text(rec, "g_MissionInfo")
    out.cont = declared_text(rec, "g_ContinueInfo")
    out.done = declared_text(rec, "g_MissionComplete")
    out.repeat = rec.repeat
    fill_from_client(world, out)
    out.in_client = 1 if rec.quest in world.client_quests else 0
    if rec.issues:
        out.status, out.reason = STATUS_UNSUPPORTED, rec.issues[0]
    return fill_logic(regs, rec, out)


def fill_logic(regs: Registries, rec: Q.QuestRec, out: QuestOut) -> QuestOut:
    owner = f"quest:{rec.script}"
    out.accept_cond = regs.conds.add(rec.accept_cond)
    out.ready_cond = regs.conds.add(rec.ready_cond)
    out.accept_fx = effect_set(regs, rec.accept_fx, owner)
    out.submit_fx = effect_set(regs, rec.turn_in_fx, owner)
    out.abandon_fx = effect_set(regs, rec.abandon_fx, owner)
    out.next_quest = rec.offers_next[0][1] if rec.offers_next else -1
    out.objectives = [Obj(kind, item, count, item, index=index) for index, kind, item, count in rec.objectives]
    out.rewards = [RewardOut(r.group, r.kind, r.ref, r.count, regs.conds.add(r.cond)) for r in rec.rewards]
    out.hooks = [(event, effect_set(regs, effects, owner)) for event, effects in rec.hooks]
    return out


def table_quest(world: World, regs: Registries, row: T.TableQuest) -> QuestOut:
    out = QuestOut(row.index, row.quest, "table", kind=row.client_kind, level=row.level, elite=row.elite)
    out.repeat = "loop" if row.repeat else "once"
    out.name, out.detail, out.cont, out.done = row.name, row.detail, row.continue_text, row.complete_text
    out.accept_scene, out.turn_scene = row.accept_scene, row.complete_scene
    out.accept_name, out.turn_name = row.accept_name, row.complete_name
    out.prereqs, extra = menpai_rules(row)
    out.accept_cond = regs.conds.add(extra)
    out.penalty, out.ban_slot, out.ban_seconds = row.penalty, row.ban_slot, row.ban_seconds
    out.next_script = row.next_index if row.next_index > 0 else 0
    client = world.client_quests.get(row.quest)
    guid_give = to_int(client[14]) if client else row.accept_guid
    guid_turn = to_int(client[16]) if client else row.complete_guid
    out.accept_guid = link_npc(world, out, "give", row.accept_scene, row.accept_name, max(guid_give, 0))
    out.turn_guid = link_npc(world, out, "turn", row.complete_scene, row.complete_name, max(guid_turn, 0))
    out.objectives = [table_objective(world, regs, out, item, row) for item in row.objectives]
    for index, objective in enumerate(out.objectives):
        objective.index = index
    out.rewards = [RewardOut(r.group, r.kind, r.ref, r.count) for r in row.rewards]
    return out


def menpai_rules(row: T.TableQuest) -> tuple[list, frozenset]:
    """Tiền đề thật và điều kiện môn phái của một dòng bảng, theo CheckAccept/DoEnumerate của mod_event.lua."""
    extra = B.TRUE
    prereqs = list(row.prereq)
    if prereqs and prereqs[0] == MENPAI_MISSION:
        sect = prereqs[1] if len(prereqs) > 1 else -1
        extra, prereqs = B.atom("sect_is", sect), []
    if row.index in SECT_SCENE_RANGE:
        sect = SECT_SCENES.index(row.accept_scene) if row.accept_scene in SECT_SCENES else -1
        extra = B.b_and(extra, B.atom("sect_is", sect)) if sect >= 0 else B.FALSE
    return prereqs, extra


def resolve_next(quests: list) -> None:
    """Nhiệm vụ bảng trỏ tới DÒNG kế (script); đổi sang id nhiệm vụ của dòng ấy, dòng treo thì -1 và xoá liên kết."""
    quest_of = {out.script: out.quest for out in quests}
    for out in quests:
        if out.source != "table" or out.next_script == 0:
            continue
        out.next_quest = quest_of.get(out.next_script, -1)
        if out.next_quest < 0:
            out.next_script = 0


def table_objective(world: World, regs: Registries, out: QuestOut, item: T.Objective, row: T.TableQuest) -> Obj:
    if item.kind in ("kill", "loot"):
        flag = item.mark if item.kind == "kill" else item.flag
        return Obj(item.kind, name_group(regs, item.name), item.count, item.item, item.rate, 0, flag, item.name)
    if item.kind in ("talk", "escort"):
        scene = item.scene or row.complete_scene
        guid = link_npc(world, out, "target", scene, item.name, 0)
        return Obj(item.kind, guid, 1, 0, 0, scene, 0, item.name)
    if item.kind == "deliver":
        return Obj("deliver", item.item, item.count, item.item, 0, 0, item.gives)
    return Obj("area", item.area, 1, 0, 0, item.scene)
