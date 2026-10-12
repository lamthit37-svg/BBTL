"""Cố phá công cụ P1 bằng dữ liệu giả trong build/p1-r. Không đụng cây xuất thật."""
from __future__ import annotations

import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SERVER = ROOT / "TOOLS" / "server"
sys.path.insert(0, str(SERVER))
import export_scene  # noqa: E402
import import_legacy  # noqa: E402
import tsv_file  # noqa: E402

MAGIC = 0xDDBBCC00
OUT = ROOT / "build" / "p1-r" / "pha"
PY = sys.executable


def write_dbc(path: Path, types: list[int], rows: list[list[int]], strings: bytes = b"\0") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    columns = len(types)
    body = struct.pack("<IIII", MAGIC, columns, len(rows), len(strings))
    body += struct.pack("<" + "I" * columns, *types)
    for row in rows:
        body += struct.pack("<" + "I" * columns, *row)
    body += strings
    path.write_bytes(body)


def names_file(path: Path, rows: list[tuple[str, str, str]]) -> None:
    lines = [
        "# schema 1",
        "# source: pha",
        "# tool: TOOLS/server/pha.py; sửa tay sẽ mất ở lượt xuất sau",
        "# types: text\ttext\ttext\ttext\ttext\ttext\ttext\ttext\ttext",
        "tree\tsource\tfate\ttarget\tkey_field\tkey\towner\tunresolved\tnote",
    ]
    for source, fate, target in rows:
        owner = "A" if fate == "table" else ""
        lines.append(f"client_2026\t{source}\t{fate}\t{target}\t\t\t{owner}\t0\t")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def run_export(raw: Path, dest: Path, names: Path, columns: Path) -> subprocess.CompletedProcess[str]:
    legacy = raw.parent / "legacy-trong"
    (legacy / "Public" / "Config").mkdir(parents=True, exist_ok=True)
    return subprocess.run(
        [
            PY, "-W", "error", str(SERVER / "export_tables.py"),
            str(raw), str(legacy), str(dest),
            "--names", str(names), "--columns", str(columns),
        ],
        cwd=ROOT, check=False, capture_output=True, text=True, encoding="utf-8",
    )


def show(title: str, result: subprocess.CompletedProcess[str]) -> None:
    print(f"## {title}")
    print(f"exit {result.returncode}")
    text = (result.stdout or "") + (result.stderr or "")
    for line in text.splitlines()[:12]:
        print(line)


def break_partial_write() -> None:
    root = OUT / "mot-bang-loi"
    raw = root / "raw"
    config = raw / "Config"
    dest = root / "tables"
    columns = root / "columns"
    names = root / "names.tsv"
    write_dbc(config / "Good.txt", [0], [[1]])
    write_dbc(config / "Also.txt", [0], [[2]])
    names_file(names, [
        ("Good.txt", "table", "tables/shared/good.tsv"),
        ("Also.txt", "table", "tables/shared/also.tsv"),
    ])
    first = run_export(raw, dest, names, columns)
    show("lượt đầu hai bảng tốt", first)
    print(f"also.tsv trước khi phá: {(dest / 'shared' / 'also.tsv').is_file()}")
    write_dbc(config / "Bad.txt", [2], [[0]], b"a\tb\0")
    names_file(names, [
        ("Good.txt", "table", "tables/shared/good.tsv"),
        ("Bad.txt", "table", "tables/shared/bad.tsv"),
        ("Also.txt", "client_only", ""),
    ])
    second = run_export(raw, dest, names, columns)
    show("một bảng có tab, bảng Also không còn trong danh sách xuất", second)
    print(f"good.tsv còn: {(dest / 'shared' / 'good.tsv').is_file()}")
    print(f"bad.tsv còn: {(dest / 'shared' / 'bad.tsv').is_file()}")
    print(f"also.tsv còn: {(dest / 'shared' / 'also.tsv').is_file()}")


def break_reference_still_writes() -> None:
    root = OUT / "doi-chieu-hong"
    raw = root / "raw"
    config = raw / "Config"
    dest = root / "tables"
    names = root / "names.tsv"
    write_dbc(config / "Pet.txt", [0], [[1]])
    legacy = raw.parent / "legacy-trong"
    ref = legacy / "Public" / "Config" / "Pet.txt"
    ref.parent.mkdir(parents=True, exist_ok=True)
    ref.write_bytes(b"INT\n\xff\n")
    names_file(names, [("Pet.txt", "table", "tables/shared/pets.tsv")])
    result = run_export(raw, dest, names, root / "columns")
    show("bản đối chiếu UTF-8 hỏng", result)
    print(f"pets.tsv đã ghi: {(dest / 'shared' / 'pets.tsv').is_file()}")


def name_row(source: str, target: str) -> tsv_file.NameRow:
    filename = Path(target).name
    return tsv_file.NameRow("server_config", source, "table", f"tables/server/{filename}", "", "", "B", "0", "")


def break_legacy() -> None:
    print("## import_legacy đầu vào hỏng")
    cases = {
        "thua-o": "INT\tINT\nid\tname\n1\ta\tthừa\n",
        "utf8": b"INT\nid\n\xff\n",
        "trung-id": "INT\nid\n1\n1\n",
        "tab-ini": "[system]\nscenenumber=1\n[scene0]\nname=a\tb\nfile=a\ntype=1\n",
        "tran": "INT\nid\n9999999999\n",
        "khoa-la": "[system]\nscenenumber=1\n[scene0]\nname=a\nfile=a\ntype=1\nlạ=1\n",
    }
    for label, payload in cases.items():
        root = OUT / "legacy" / label
        folder = root / "Server" / "Config"
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / "sample.txt"
        if label == "tab-ini" or label == "khoa-la":
            path = folder / "SceneInfo.ini"
            source = "SceneInfo.ini"
        else:
            source = "sample.txt"
        if isinstance(payload, bytes):
            path.write_bytes(payload)
        else:
            path.write_text(payload, encoding="utf-8", newline="\n")
        try:
            errors, _summary = import_legacy.export_legacy(
                root, root / "out", [name_row(source, source)], column_dir=root / "columns",
            )
        except Exception as exc:
            print(f"{label}: ngoại lệ {exc}")
            continue
        print(f"{label}: lỗi {len(errors)}")
        for line in errors[:3]:
            print(f"  {line}")
        written = list((root / "out").glob("*.tsv")) if (root / "out").exists() else []
        print(f"  tệp đã ghi: {len(written)}")


def scene_tree(root: Path, files: dict[str, str]) -> None:
    folder = root / "Public" / "Scene"
    folder.mkdir(parents=True, exist_ok=True)
    for name, text in files.items():
        (folder / name).write_text(text, encoding="utf-8", newline="")


def nav_bytes(width: int, height: int, extra: int = 0) -> bytes:
    return struct.pack("<HH", width, height) + b"\0" * (width * height * 4 + extra)


def minimal_scene() -> dict[str, str]:
    nav = OUT / "nav-bin" / "one.nav"
    nav.parent.mkdir(parents=True, exist_ok=True)
    return {
        "demo.scn": "[System]\r\nnavmapname=demo.nav\r\nmonsterfile=demo_monster.ini\r\neventfile=demo_area.ini\r\npatrolpoint=demo_patrolpoint.ini\r\n",
        "demo_monster.ini": "[info]\r\nmonstercount=1\r\n[monster0]\r\nguid=1\r\ntype=2\r\npos_x=1\r\npos_z=2\r\ndir=3\r\nscript_id=4\r\nrespawn_time=5\r\ngroup_id=6\r\nteam_id=7\r\npatrol_id=8\r\n",
        "demo_area.ini": "[area_info]\r\narea_count=0\r\n",
        "demo_patrolpoint.ini": "[INFO]\r\nPATROLNUMBER=0\r\n",
    }


def write_nav(folder: Path, name: str, width: int, height: int, extra: int = 0) -> None:
    (folder / name).write_bytes(nav_bytes(width, height, extra))


def break_scene() -> None:
    print("## export_scene đầu vào hỏng")
    base = minimal_scene()
    cases: list[tuple[str, dict[str, str], str | None]] = []
    bad_nav = dict(base)
    cases.append(("nav-lech", bad_nav, "extra"))
    unknown = dict(base)
    unknown["demo.scn"] = unknown["demo.scn"].replace("patrolpoint=demo_patrolpoint.ini\r\n", "patrolpoint=demo_patrolpoint.ini\r\nkhoala=1\r\n")
    cases.append(("khoa-la", unknown, None))
    mismatch = dict(base)
    mismatch["demo_monster.ini"] = mismatch["demo_monster.ini"].replace("monstercount=1", "monstercount=2")
    cases.append(("lech-so", mismatch, None))
    alien = dict(base)
    alien["la.xyz"] = "không biết\r\n"
    cases.append(("chua-phan-loai", alien, None))
    orphan = {
        "chuangjian.nav": "",
        "chuangjian_monster.ini": base["demo_monster.ini"],
    }
    cases.append(("khong-scn", orphan, "orphan-nav"))
    duplicate = dict(base)
    duplicate["demo_monster.ini"] = (
        "[info]\r\nmonstercount=2\r\n"
        "[monster0]\r\nguid=7\r\ntype=2\r\npos_x=1\r\npos_z=2\r\ndir=3\r\nscript_id=4\r\nrespawn_time=5\r\ngroup_id=6\r\nteam_id=7\r\npatrol_id=8\r\n"
        "[monster1]\r\nguid=7\r\ntype=2\r\npos_x=1\r\npos_z=2\r\ndir=3\r\nscript_id=4\r\nrespawn_time=5\r\ngroup_id=6\r\nteam_id=7\r\npatrol_id=8\r\n"
    )
    cases.append(("guid-trung", duplicate, None))
    for label, files, mode in cases:
        root = OUT / "scene" / label
        scene_tree(root, {name: text for name, text in files.items() if not name.endswith(".nav")})
        folder = root / "Public" / "Scene"
        if mode == "extra":
            write_nav(folder, "demo.nav", 1, 1, 3)
            write_nav(folder, "demo_area.ini", 1, 1)
        elif mode == "orphan-nav":
            write_nav(folder, "chuangjian.nav", 1, 1)
        elif label != "khong-scn":
            write_nav(folder, "demo.nav", 1, 1)
        if label == "nav-lech":
            folder.joinpath("demo_area.ini").write_text(base["demo_area.ini"], encoding="utf-8", newline="")
        report = export_scene.export_scenes(root, root / "out", root / "columns", False)
        print(f"{label}: ok {report.ok} lỗi {len(report.errors)} cảnh {report.scene_count}")
        for line in report.errors[:3]:
            print(f"  {line}")
        produced = list((root / "out").rglob("*")) if (root / "out").exists() else []
        print(f"  tệp đích: {len([path for path in produced if path.is_file()])}")


def break_tsv() -> None:
    print("## tsv_file từ chối")
    dest = OUT / "tsv"
    dest.mkdir(parents=True, exist_ok=True)
    probes = [
        ("tab", ["a\tb"]),
        ("xuong-dong", ["a\nb"]),
        ("thang", ["#an"]),
        ("cot-rong", [""]),
    ]
    for label, rows in probes:
        try:
            tsv_file.write_table(dest / f"{label}.tsv", "pha/x", "pha.py", ["text"], ["name"], [(cell,) for cell in rows])
            print(f"{label}: ghi được")
        except tsv_file.TsvError as exc:
            print(f"{label}: từ chối {exc}")
    bits = [0x00000001, 0x80000000, 0x7F7FFFFF, 0x00800000, 0x3DCCCCCD]
    for item in bits:
        try:
            text = tsv_file.format_float32(item)
            back = struct.unpack("<I", struct.pack("<f", float(text)))[0]
            print(f"float {item:08x}: {text!r} khớp {back == item}")
        except (tsv_file.TsvError, OverflowError, ValueError) as exc:
            print(f"float {item:08x}: {type(exc).__name__} {exc}")


def main() -> None:
    break_partial_write()
    break_reference_still_writes()
    break_legacy()
    break_scene()
    break_tsv()


if __name__ == "__main__":
    main()
