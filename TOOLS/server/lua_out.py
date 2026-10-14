"""Ghi bảng TSV của lua_extract.py vào dev/server/tables/server qua tsv_file.write_table.

Mỗi bảng khai báo bằng một dòng "cột:kiểu ..." để tên cột và kiểu nằm cạnh nhau. Ô văn bản bị làm sạch
tab và xuống dòng (script gốc có chuỗi nhiều dòng); mất ký tự đó là chủ ý, không đổi nghĩa nội dung hiển thị.
Bảng ghi theo bố cục căn cột (tsv_file.py, chủ dự án giao 2026-10-15): mở bằng trình soạn thì cột thẳng hàng.
"""
from __future__ import annotations

from pathlib import Path

import tsv_file

TOOL = "TOOLS/server/lua_extract.py"

SPECS = {
    "mission_quests": "script:int quest:int source:text status:text reason:text in_client:int kind:int level:int "
    "repeat:text elite:int name:text detail:text continue_text:text complete_text:text "
    "accept_scene:int accept_guid:int turn_scene:int turn_guid:int accept_cond:int ready_cond:int "
    "accept_fx:int submit_fx:int abandon_fx:int "
    "next_quest:int next_script:int penalty:int ban_slot:int ban_seconds:int path:text",
    "mission_objectives": "script:int seq:int kind:text index:int target:int count:int item:int rate:int "
    "scene:int flag:int name:text",
    "mission_rewards": "script:int seq:int group:text kind:text ref:int count:int cond:int",
    "mission_prereqs": "script:int prereq:int",
    "mission_hooks": "script:int seq:int event:text effects:int",
    "mission_npcs": "script:int role:text guid:int scene:int name:text how:text",
    "mission_auto": "level:int quest:int script:int pre_quest:int event:int full_level:int complete_idx:int "
    "record_idx:int message:text",
    "mission_name_groups": "group:int template:int name:text",
    "ops_conditions": "set:int clause:int seq:int op:text neg:int a1:int a2:int a3:int word:text",
    "ops_effects": "set:int seq:int op:text a1:int a2:int a3:int text:text args:text cond:int",
    "talk_blocks": "block:int seq:int kind:text cond:int a:int b:int c:int text:text args:text",
    "talk_entries": "script:int num:int block:int status:text reason:text",
    "talk_npc_roles": "script:int path:text events:int",
    "talk_npc_events": "script:int seq:int event:int",
    "mission_strings": "key:text id:text text:text owner:text",  # id là fnv1a32 (u32): vượt miền int32 của bộ kiểm bảng
}


def clean(cell: object) -> str:
    text = str(cell)
    return text.replace("\t", " ").replace("\r", " ").replace("\n", " ")


def emit(out_dir: Path, name: str, rows: list) -> int:
    pairs = [item.split(":") for item in SPECS[name].split()]
    columns = [column for column, _ in pairs]
    types = [kind for _, kind in pairs]
    cells = [tuple(clean(cell) for cell in row) for row in rows]
    tsv_file.write_table(out_dir / f"{name}.tsv", "Public/Data/Script", TOOL, types, columns, cells, layout="aligned")
    return len(rows)


def quest_rows(quests: list) -> list:
    return [
        (q.script, q.quest, q.source, q.status, q.reason, q.in_client, q.kind, q.level, q.repeat, q.elite, q.name,
         q.detail,
         q.cont, q.done, q.accept_scene, q.accept_guid, q.turn_scene, q.turn_guid, q.accept_cond, q.ready_cond,
         q.accept_fx, q.submit_fx, q.abandon_fx, q.next_quest, q.next_script, q.penalty, q.ban_slot, q.ban_seconds,
         q.path)
        for q in quests
    ]


def objective_rows(quests: list) -> list:
    return [
        (q.script, seq, o.kind, o.index, o.target, o.count, o.item, o.rate, o.scene, o.flag, o.name)
        for q in quests
        for seq, o in enumerate(q.objectives)
    ]


def reward_rows(quests: list) -> list:
    return [
        (q.script, seq, r.group, r.kind, r.ref, r.count, r.cond)
        for q in quests
        for seq, r in enumerate(q.rewards)
    ]


def link_rows(quests: list) -> list:
    return [(q.script, role, guid, scene, name, how) for q in quests for role, guid, scene, name, how in q.npc_links]


def hook_rows(quests: list) -> list:
    return [(q.script, seq, event, effects) for q in quests for seq, (event, effects) in enumerate(q.hooks)]


def prereq_rows(quests: list) -> list:
    return [(q.script, prereq) for q in quests for prereq in q.prereqs]
