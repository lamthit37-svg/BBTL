"""Phán quyết bước 4: ca giả độc lập. Không ghi SERVER/tables hay SERVER/scenes."""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "TOOLS" / "server"))
import export_scene  # noqa: E402
import export_tables  # noqa: E402
import import_legacy  # noqa: E402
import tsv_file  # noqa: E402

spec = importlib.util.spec_from_file_location("pha", Path(__file__).with_name("pha.py"))
pha = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pha)

OUT = ROOT / "build" / "p1-r" / "buoc4"


def legacy_row(source: str) -> tsv_file.NameRow:
    return tsv_file.NameRow(
        "server_config", source, "table", "tables/server/sample.tsv", "", "", "B", "0", ""
    )


def middle_empty() -> None:
    root = OUT / "giua"
    folder = root / "Server" / "Config"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "shift.txt").write_text("INT\t\tSTRING\nid\tbo\tten\n1\t2\thello\n", encoding="utf-8", newline="\n")
    errors, summary = import_legacy.export_legacy(
        root, root / "out", [legacy_row("shift.txt")], column_dir=root / "columns"
    )
    print("## X-AB-03 kieu trong giua")
    print("errors", errors)
    print("summary", summary)
    path = root / "out" / "sample.tsv"
    print("wrote", path.is_file())
    if path.is_file():
        table = tsv_file.read_table(path)
        print("columns", table.columns)
        print("types", table.types)
        print("rows", table.rows)


def scene_keep_old() -> None:
    root = OUT / "canh"
    legacy = root / "legacy"
    dest = root / "out"
    pha.scene_tree(legacy, pha.minimal_scene())
    pha.write_nav(legacy / "Public" / "Scene", "demo.nav", 1, 1)
    first = export_scene.export_scenes(legacy, dest, root / "columns", False)
    marker = dest / "demo" / "spawns.tsv"
    before = marker.read_bytes() if marker.is_file() else b""
    (legacy / "Public" / "Scene" / "chuangjian.nav").write_bytes(pha.nav_bytes(1, 1))
    second = export_scene.export_scenes(legacy, dest, root / "columns", False)
    print("## X-BC-02 loi khong ghi de")
    print("first_ok", first.ok, "second_ok", second.ok)
    print("errors", second.errors[:4])
    print("marker_same", marker.is_file() and marker.read_bytes() == before)
    print("chuangjian", (dest / "chuangjian").exists())


def scene_tab() -> None:
    root = OUT / "tab"
    legacy = root / "legacy"
    files = pha.minimal_scene()
    files["demo_monster.ini"] = files["demo_monster.ini"].replace("type=2\r\n", "type=2\r\ntitle=a\tb\r\n")
    pha.scene_tree(legacy, files)
    pha.write_nav(legacy / "Public" / "Scene", "demo.nav", 1, 1)
    report = export_scene.export_scenes(legacy, root / "out", root / "columns", False)
    print("## X-BC-01 tab kem cot")
    print("ok", report.ok)
    print("errors", report.errors[:3])
    print("dest", (root / "out").exists())


def export_case(label: str, legacy_text: str, kinds: list[int], rows: list[list[int]], strings: bytes = b"\0") -> None:
    root = OUT / label
    raw = root / "raw"
    pha.write_dbc(raw / "Config" / "Pet.txt", kinds, rows, strings)
    ref = root / "legacy-trong" / "Public" / "Config" / "Pet.txt"
    ref.parent.mkdir(parents=True, exist_ok=True)
    ref.write_bytes(legacy_text.encode("utf-8"))
    names = root / "names.tsv"
    pha.names_file(names, [("Pet.txt", "table", "tables/shared/pets.tsv")])
    result = pha.run_export(raw, root / "tables", names, root / "columns")
    print(f"## {label}")
    print("exit", result.returncode)
    text = (result.stdout or "") + (result.stderr or "")
    for line in text.splitlines():
        if line.startswith("Pet.txt") or "ô đầu" in line or "id không" in line or "float32" in line or line.startswith("bảng"):
            print(line)
    print("pets", (root / "tables" / "shared" / "pets.tsv").is_file())
    column = root / "columns" / "pets.tsv"
    if column.is_file():
        table = tsv_file.read_table(column)
        for row in table.rows:
            print("note", row[4])


def main() -> None:
    middle_empty()
    scene_keep_old()
    scene_tab()
    export_case("id-rong", "INT\tINT\nID\tValue\n1\t10\n2\t20\n\t999\n", [0, 0], [[1, 10], [2, 20]])
    export_case("float-tran", "INT\tFLOAT\nID\tValue\n1\t1e308\n", [0, 1], [[1, 0]])
    export_case("id-thap-phan", "INT\tINT\nID\tValue\n1.0\t10\n", [0, 0], [[1, 10]])


if __name__ == "__main__":
    main()
