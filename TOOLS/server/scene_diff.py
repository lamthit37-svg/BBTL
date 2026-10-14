"""So dữ liệu cảnh bản 0859602 (đã có trong dev/server/scenes) với cùng cảnh ở XJL7457.

    python TOOLS/server/scene_diff.py <gốc dev/server> <gốc tlbb của XJL7457> [--check]

Ghi <gốc dev/server>/tables/server/scene_xjl_diff.tsv: mỗi dòng một cảnh dùng chung và một loại bảng, với số
bản ghi giống hệt, số bản ghi cùng khoá nhưng khác ô, và số bản ghi chỉ có một bên. Công cụ không đổi dữ
liệu cảnh: nguồn 0859602 vào trước và client 2026 mới là chuẩn (client không có spawn nên không phân xử
được chuỗi bản ghi; chênh lệch ở đây là việc của người duyệt nội dung).
"""
from __future__ import annotations

import sys
import tempfile
from collections import Counter
from pathlib import Path

import import_scene_xjl as importer
import scene_classify as kinds
import tsv_file

TOOL = "scene_diff.py"
HELP = __doc__ or ""
COLUMNS = ("scene_dir", "table", "rows_0859", "rows_xjl", "same", "changed", "only_0859", "only_xjl")
TYPES = ("text", "text", "int", "int", "int", "int", "int", "int")
# Loại bảng -> tên tệp (tiền tố) và các cột làm khoá khi ghép bản ghi cùng khoá.
FAMILIES = {
    "spawns": ("spawns", ("guid",)),
    "areas": ("areas", ("guid",)),
    "patrols": ("patrols", ("patrol_index", "point_index")),
    "grow_points": ("grow_points", ("point_id",)),
    "platforms": ("platforms", ("type_id", "position_x", "position_z")),
    "wild_pets": ("wild_pets", ("guid",)),
}


Keyed = list[tuple[tuple[str, ...], tuple[str, ...]]]


def family_rows(folder: Path, prefix: str, key_columns: tuple[str, ...]) -> Keyed:
    """(khoá, cả dòng) của mọi bảng thuộc họ prefix trong một thư mục cảnh."""
    rows: Keyed = []
    for path in sorted(folder.glob(f"{prefix}*.tsv")):
        if path.name.startswith(("spawn_operate", "spawn_levels")):
            continue
        table = tsv_file.read_table(path)
        for row in table.rows:
            cells = dict(zip(table.columns, row, strict=True))
            key = tuple(cells.get(name, "") for name in key_columns)
            # Bảng patrols có số cột speech_N tuỳ cảnh: so theo tên cột, bỏ ô rỗng.
            filled = tuple(sorted((name, value) for name, value in cells.items() if value != ""))
            rows.append((key, (path.name, *(item for pair in filled for item in pair))))
    return rows


def compare(left: list, right: list) -> tuple[int, int, int, int]:
    """(giống hệt, cùng khoá khác ô, chỉ trái, chỉ phải). Ghép theo đa tập; phần dư ghép tiếp theo khoá."""
    left_count = Counter(row for _key, row in left)
    right_count = Counter(row for _key, row in right)
    same = sum((left_count & right_count).values())
    key_of = {row: key for key, row in [*left, *right]}
    rest_left = Counter()
    rest_right = Counter()
    for row, count in (left_count - right_count).items():
        rest_left[key_of[row]] += count
    for row, count in (right_count - left_count).items():
        rest_right[key_of[row]] += count
    changed = sum((rest_left & rest_right).values())
    return same, changed, sum(rest_left.values()) - changed, sum(rest_right.values()) - changed


def scene_rows(folder_0859: Path, folder_xjl: Path, scene_dir: str) -> list[tuple[str, ...]]:
    out = []
    for family, (prefix, keys) in FAMILIES.items():
        left = family_rows(folder_0859, prefix, keys)
        right = family_rows(folder_xjl, prefix, keys)
        if not left and not right:
            continue
        same, changed, only_left, only_right = compare(left, right)
        counts = (len(left), len(right), same, changed, only_left, only_right)
        out.append((scene_dir, family, *(str(count) for count in counts)))
    return out


def run(server_root: Path, xjl_root: Path) -> tuple[list[tuple[str, ...]], list[str]]:
    scenes = server_root / "scenes"
    source = importer.scene_root(xjl_root)
    kind_of = importer.classify_dir(source)
    stems = {name[: -len(".scn")] for name, kind in kind_of.items() if kind == kinds.SCN}
    rows: list[tuple[str, ...]] = []
    errors: list[str] = []
    with tempfile.TemporaryDirectory(prefix="scene_diff_") as temporary:
        for folder in sorted(entry for entry in scenes.iterdir() if entry.is_dir()):
            if tsv_file.owned_tool(folder / "scene.toml") != "TOOLS/server/export_scene.py" or folder.name not in stems:
                continue
            report, out = importer.import_one(source, kind_of, folder.name, stems, Path(temporary))
            if not report.ok:
                errors.extend(f"{folder.name}: {line}" for line in report.errors)
                rows.append((folder.name, "unreadable_xjl", "0", "0", "0", "0", "0", "0"))
                continue
            rows.extend(scene_rows(folder, out / folder.name, folder.name))
    return rows, errors


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    positional = [arg for arg in args if not arg.startswith("--")]
    if len(positional) != 2:
        print("scene_diff.py:1: cần hai tham số: gốc dev/server và gốc XJL7457")
        return 1
    server_root = Path(positional[0])
    rows, errors = run(server_root, Path(positional[1]))
    for line in errors:
        print(line)
    if "--check" not in args:
        target = server_root / "tables" / "server" / "scene_xjl_diff.tsv"
        tsv_file.write_table(target, "scenes/*/ + XJL7457/Public/Scene", TOOL, TYPES, COLUMNS, rows)
    print(f"dòng {len(rows)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
