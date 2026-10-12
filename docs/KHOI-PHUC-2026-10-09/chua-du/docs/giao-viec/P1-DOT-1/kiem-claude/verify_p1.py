"""Kiểm độc lập kết quả P1 đợt 1 (Claude, 2026-10-07). Không gọi mã của A, B, C, L, R.

    python docs/giao-viec/P1-DOT-1/kiem-claude/verify_p1.py [A] [B] [C] [D]

Cần hai biến môi trường THIENLONG_LEGACY_ROOT (thư mục tlbb) và THIENLONG_RAW_ROOT (thư mục _raw).
A: từng ô của 635 bảng client so với DBC (đọc bằng TOOLS/content/dbc.py). B: bảng chữ và ini bản
0859602 so với bộ đọc viết lại theo OpenFromMemoryImpl_Text và Ini.cpp. C: mọi bảng spawns so với
tệp ini gốc, walk.nav so băm với .nav mà .scn trỏ tới. D: mọi TSV đọc được theo luật của parse_tsv.
"""
import hashlib
import os
import re
import struct
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TLBB = Path(os.environ.get("THIENLONG_LEGACY_ROOT", "thiếu THIENLONG_LEGACY_ROOT"))
RAW = Path(os.environ.get("THIENLONG_RAW_ROOT", "thiếu THIENLONG_RAW_ROOT"))
sys.path.insert(0, str(ROOT / "TOOLS" / "content"))
import dbc  # noqa: E402

sys.stdout.reconfigure(encoding="utf-8")
SERVER = ROOT / "SERVER"
PARTS = set(sys.argv[1:]) or {"A", "B", "C", "D"}


def parse_like_cpp(path: Path):
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫


def compare_text_table(source: Path, target_rows, target_types, offset: int, label: str, report):
    types, rows, stats = read_legacy_text(source)
    width = len(types)
    if len(rows) != len(target_rows):
        report.append(f"{label}: số bản ghi gốc {len(rows)} khác TSV {len(target_rows)}")
        return 0
    mismatch = 0
    float_text = 0
    for cells, written in zip(rows, target_rows):
        for column, kind in enumerate(types):
            cell = written[offset + column]
            raw = cells[column]
            if kind == "INT":
                same = cell == str(atoi(raw))
            elif kind == "FLOAT":
                same = cell == raw
                float_text += 0 if same else 1
            else:
                same = cell == raw
            if not same:
                mismatch += 1
                if mismatch <= 2:
                    report.append(f"{label}: cột {column} kiểu {kind} gốc {raw!r} TSV {cell!r}")
    if stats["ô thừa có chữ"]:
        report.append(f"{label}: {stats['ô thừa có chữ']} dòng có ô thừa có chữ sau {width} cột kiểu")
    return mismatch


INI_TABLES = {
    "tables/server/sect_base_values.tsv": ("MENPAI{}", "sect_id"),
    "tables/server/guild_position_permissions.tsv": ("member_type{}", "position_id"),
    "tables/server/monster_ai_types.tsv": ("AI{}", "ai_id"),
    "tables/server/scenes.tsv": ("scene{}", "scene_id"),
    "tables/server/scene_hosting.tsv": ("scene{}", "scene_id"),
    "tables/server/rolling_announcements.tsv": ("broad{}", "announcement_id"),
    "tables/server/scheduled_events.tsv": ("huodong{}", "event_id"),
    "tables/server/random_shop_goods.tsv": ("Merchandise{}", "merchandise_id"),
}


def compare_ini_table(source: Path, target: str, header, types, rows, report, label: str):
    pattern, id_column = INI_TABLES[target]
    sections, _ = parse_ini(source)
    columns = column_map("server", Path(target).name)
    at = {name: index for index, name in enumerate(header)}
    mismatch = 0
    absent = Counter()
    for written in rows:
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
            if key not in section:
                absent[(column["name"], cell)] += 1
                continue
            raw = section[key]
            expected = str(atoi(raw)) if column["type"] == "int" else raw
            if cell != expected:
                mismatch += 1
                if mismatch <= 3:
                    report.append(f"{label}: {column['name']} gốc {raw!r} TSV {cell!r}")
    return mismatch, absent


def part_b(rows):
    started = time.time()
    trees = {"server_config": TLBB / "Server/Config", "public_config": TLBB / "Public/Config"}
    by_target = defaultdict(list)
    for row in rows:
        if row["tree"] in trees and row["fate"] == "table":
            by_target[row["target"]].append(row)
    report = []
    checked_text = checked_ini = total_mismatch = records = 0
    absent_all = Counter()
    for target, sources in sorted(by_target.items()):
        header, types, data, problems, _ = parse_like_cpp(SERVER / target)
        if problems:
            report.append(f"{target}: {problems}")
        records += len(data)
        keyed = sources[0]["key_field"] != ""
        if not keyed and len(sources) > 1:
            report.append(f"{target}: nhiều nguồn mà không có khoá")
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
                    continue
                mismatch = compare_text_table(path, part, types, offset, label, report)
                checked_text += 1
            total_mismatch += mismatch
    print(f"B: {len(by_target)} bảng đích, {records} bản ghi; so {checked_text} tệp chữ và {checked_ini} tệp ini; ô lệch {total_mismatch}; {time.time() - started:.0f} giây")
    for line in report[:40]:
        print("   ", line)
    print("    khoá ini vắng -> ô ghi ra:", dict(Counter({pair[1]: 0 for pair in absent_all}) | Counter()), sum(absent_all.values()))
    by_cell = Counter()
    for (name, cell), count in absent_all.items():
        by_cell[cell] += count
    print("    phân bố ô khi khoá vắng:", dict(by_cell))


# ---------------------------------------------------------------- C: cảnh
def part_c():
    started = time.time()
    scenes = sorted(path for path in (SERVER / "scenes").iterdir() if path.is_dir())
    columns = column_map("scenes", "spawns.tsv")
    source_dir = TLBB / "Public/Scene"
    files = mismatch = rows_total = count_bad = 0
    report = []
    absent = Counter()
    for scene in scenes:
        for table in sorted(scene.glob("spawns*.tsv")):
            header, _, data, problems, meta = parse_like_cpp(table)
            if problems:
                report.append(f"{table.relative_to(SERVER)}: {problems}")
            source = meta.get("source", "")
            if " + " in source or not source.startswith("Public/Scene/"):
                report.append(f"{table.relative_to(SERVER)}: nguồn lạ {source!r}")
                continue
            sections, _ = parse_ini(source_dir / source.split("/", 2)[2])
            declared = atoi(sections.get("info", {}).get("monstercount", ""))
            if declared != len(data):
                count_bad += 1
                report.append(f"{table.relative_to(SERVER)}: monstercount {declared} khác {len(data)} dòng")
                continue
            at = {name: index for index, name in enumerate(header)}
            for index, written in enumerate(data):
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
                problems.append("tên cột sai luật hoặc trùng")
            if re.search(r"[A-Za-z]:[\\/]", meta.get("source", "")):
                problems.append("source có đường dẫn tuyệt đối")
            if problems:
                bad.append((str(path.relative_to(ROOT)), problems))
    print(f"D: {count} tệp TSV, có vấn đề {len(bad)}, {time.time() - started:.0f} giây; theo công cụ {dict(tools)}")
    for name, problems in bad[:20]:
        print("   ", name, problems)


if __name__ == "__main__":
    name_rows = names()
    if "D" in PARTS:
        part_d()
    if "B" in PARTS:
        part_b(name_rows)
    if "C" in PARTS:
        part_c()
    if "A" in PARTS:
        part_a(name_rows)
