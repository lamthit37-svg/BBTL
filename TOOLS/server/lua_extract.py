"""Trích nhiệm vụ, hội thoại và vai NPC từ script Lua 4.0 của máy chủ 14 môn phái thành bảng TSV cho máy chủ mới.

cách dùng:
    python TOOLS/server/lua_extract.py --lua <Public/Data> [--tables dev/server/tables]
        [--scenes dev/server/scenes] [--out dev/server/tables/server] [--report tệp.txt] [--check]

Không bao giờ chạy Lua: đọc tĩnh bằng bộ phân tích riêng (lua_syntax.py) rồi hạ từng hàm bằng bộ đánh giá từng phần
(lua_flow.py) với trạng thái người chơi tượng trưng. Kết quả là điều kiện và hiệu ứng thuộc tập op đóng của module C++
`ops`; mọi thứ không qui được về tập đó bị ghi `unsupported` kèm lý do, không bỏ im. Danh bạ nhiệm vụ của client 2026
là thẩm quyền cao nhất với script 14 môn: tên, cấp, NPC giao/trả lấy từ đó; Lua chỉ quyết định logic.
Ngoại lệ `edali_newquest`: tệp MisDesc của client không có thân hàm, ô NPC danh bạ là "-1", nên
`newquest.append_quests` dựng dòng bảng từ chính script và không gọi `fill_from_client`.
`--check` chạy hết nhưng không ghi bảng (in báo cáo).
"""
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from pathlib import Path

import dialogue_text as DT
import lua_auto
import lua_build as BU
import lua_dialog as D
import lua_emit as E
import lua_npc as N
import lua_out as O
import newquest
import lua_quest as Q
import lua_quest_npcs as QN
import lua_report
import lua_scan as L
import lua_tables as T
import lua_units as U
import lua_world as W

PROJECT = Path(__file__).resolve().parents[2]


@dataclass
class Context:
    world: W.World
    scan: L.Scan
    regs: BU.Registries
    walker: N.Walker
    quests: list = field(default_factory=list)
    roles: list = field(default_factory=list)
    auto: list = field(default_factory=list)


def load_context(lua_dir: Path, tables: Path, scenes: Path) -> Context:
    world = W.World(tables, scenes).load()
    script_dir = lua_dir / "Script"
    dat = U.read_script_dat(U.read_text(lua_dir / "Script.dat"))
    low = L.build_lowerer(script_dir)
    scan = L.load_all(lua_dir, dat, low, set(world.client_quests))
    regs = BU.Registries(E.Strings(world.dictionary))
    serializer = D.Serializer(regs.blocks, regs.conds, regs.effects, regs.strings)
    npc_scripts = frozenset(script for script, category in scan.categories.items() if category == "npc")
    return Context(world, scan, regs, N.Walker(low, serializer, npc_scripts))


def extract_script_quests(ctx: Context) -> None:
    low = ctx.scan.low
    for script, category in sorted(ctx.scan.categories.items()):
        if category != "quest":
            continue
        unit = low.units[script]
        rec = Q.extract(low, unit, ctx.scan.dat[script])
        QN.extract_npcs(low, unit, rec)
        ctx.quests.append(BU.script_quest(ctx.world, ctx.regs, rec))


def extract_table_quests(ctx: Context, tables: Path) -> None:
    for row in T.read_all(tables):
        ctx.quests.append(BU.table_quest(ctx.world, ctx.regs, row))


def extract_dialogs(ctx: Context) -> None:
    for script, category in sorted(ctx.scan.categories.items()):
        if category in ("npc", "event", "quest"):
            ctx.walker.seed(script, -1)
    ctx.walker.run()
    ctx.roles = N.npc_roles(ctx.scan.low, ctx.scan.categories, ctx.scan.dat)


def extract_auto(ctx: Context, lua_dir: Path) -> None:
    unit = lua_auto.load_scene_unit(ctx.scan.low, lua_dir / "Script")
    ctx.auto = lua_auto.auto_rows(unit)


def build(lua_dir: Path, tables: Path, scenes: Path) -> Context:
    ctx = load_context(lua_dir, tables, scenes)
    extract_script_quests(ctx)
    extract_table_quests(ctx, tables)
    newquest.append_quests(ctx)
    BU.resolve_next(ctx.quests)
    extract_dialogs(ctx)
    extract_auto(ctx, lua_dir)
    return ctx


def group_rows(ctx: Context) -> list:
    rows = []
    for group, norm in sorted(ctx.regs.groups.items()):
        name = ctx.regs.group_names.get(norm, norm)
        templates = ctx.world.monster_by_name.get(norm, []) or [-1]
        rows.extend((group, template, name) for template in templates)
    return rows


def string_entries(ctx: Context) -> list:
    strings = ctx.regs.strings
    return [DT.Entry(key, O.clean(text), strings.owners.get(key, "")) for key, text in sorted(strings.literal.items())]


def role_rows(ctx: Context) -> tuple[list, list]:
    roles = [(r.script, r.path, len(r.events)) for r in ctx.roles]
    events = [(r.script, seq, event) for r in ctx.roles for seq, event in enumerate(r.events)]
    return roles, events


def write_tables(ctx: Context, out_dir: Path) -> dict:
    regs = ctx.regs
    roles, events = role_rows(ctx)
    entries = [(e.script, e.num, e.block, e.status, e.reason) for e in ctx.walker.entries.values()]
    tables = {
        "mission_quests": O.quest_rows(ctx.quests),
        "mission_objectives": O.objective_rows(ctx.quests),
        "mission_rewards": O.reward_rows(ctx.quests),
        "mission_prereqs": O.prereq_rows(ctx.quests),
        "mission_hooks": O.hook_rows(ctx.quests),
        "mission_npcs": O.link_rows(ctx.quests),
        "mission_auto": ctx.auto,
        "mission_name_groups": group_rows(ctx),
        "ops_conditions": sorted(regs.conds.rows),
        "ops_effects": regs.effects.rows,
        "talk_blocks": sorted(regs.blocks.rows, key=lambda row: (row[0], row[1])),
        "talk_entries": sorted(entries),
        "talk_npc_roles": roles,
        "talk_npc_events": events,
    }
    written = {name: O.emit(out_dir, name, rows) for name, rows in tables.items()}
    # Chữ thoại là tệp văn bản riêng (dialogue_text.py); nhãn nhóm đọc từ bảng vừa ghi ở trên.
    strings = string_entries(ctx)
    DT.write(out_dir / DT.FILE_NAME, strings, DT.labels_of(strings, out_dir))
    written["dialogue"] = len(strings)
    return written


def parse_args(argv: list) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--lua", type=Path, required=True, help="thư mục Public/Data của máy chủ gốc")
    parser.add_argument("--tables", type=Path, default=PROJECT / "dev/server/tables")
    parser.add_argument("--scenes", type=Path, default=PROJECT / "dev/server/scenes")
    parser.add_argument("--out", type=Path, default=None)
    parser.add_argument("--report", type=Path, default=None)
    parser.add_argument("--check", action="store_true", help="không ghi bảng")
    return parser.parse_args(argv)


def main(argv: list) -> int:
    args = parse_args(argv)
    ctx = build(args.lua, args.tables, args.scenes)
    report = lua_report.render(ctx)
    if not args.check:
        written = write_tables(ctx, args.out or args.tables / "server")
        report += "\nbảng đã ghi: " + ", ".join(f"{name}={count}" for name, count in written.items())
    if args.report:
        args.report.write_text(report, encoding="utf-8")
    sys.stdout.buffer.write((report + "\n").encode("utf-8"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
