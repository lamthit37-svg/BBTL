"""Đếm lại số trong báo cáo A, B, C. Không gọi hàm căn cột hay hàm xuất."""
from __future__ import annotations

import os
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TOOLS = ROOT / "TOOLS" / "server"
SERVER = ROOT / "dev" / "server"
LEGACY = Path(os.environ["THIENLONG_LEGACY_ROOT"])
OUT = Path(__file__).resolve().parent / "phu-ra.txt"


def rows_of(path: Path) -> tuple[list[str], list[list[str]]]:
    header: list[str] = []
    body = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        cells = line.split("\t")
        if not header:
            header = cells
            continue
        body.append(cells)
    return header, body


def ini_keys(path: Path) -> list[tuple[str, str, int]]:
    found = []
    section = ""
    text = path.read_text(encoding="utf-8")
    for number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("[") and "]" in stripped:
            section = stripped[1 : stripped.index("]")]
            continue
        if stripped == "" or stripped.startswith(";") or stripped.startswith("#"):
            continue
        if "=" not in line:
            found.append((section, f"<không khoá:{number}>", number))
            continue
        key = line.split("=", 1)[0].strip()
        found.append((section, key, number))
    return found


def bare_keys(path: Path) -> list[tuple[str, str, int]]:
    found = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.strip()
        if stripped == "" or stripped.startswith(";") or stripped.startswith("#"):
            continue
        if "=" not in line:
            found.append(("", f"<không khoá:{number}>", number))
            continue
        found.append(("", line.split("=", 1)[0].strip(), number))
    return found


def merge_keys(path: Path) -> list[tuple[str, str, int]]:
    rows = [
        (number, line)
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1)
        if line.strip() and not line.startswith("#")
    ]
    found = []
    for number, line in rows[2:]:
        cells = line.split("\t")
        key = cells[1] if len(cells) > 1 else ""
        found.append(("", key, number))
    return found


def info_keys(path: Path) -> list[tuple[str, str, int]]:
    return [item for item in ini_keys(path) if item[0] == "info"]


def hand_shape(path: Path, lines: list[str]) -> None:
    text = path.read_text(encoding="utf-8")
    tool = "# tool:" in text
    schema = text.startswith("# schema 1\n")
    lines.append(f"{path.name}: schema1={schema} có tool={tool}")


def repeated_headers(lines: list[str]) -> None:
    bad_dup = 0
    half = 0
    question = 0
    named = 0
    columns = 0
    tables = 0
    for folder in (SERVER / "tables" / "shared", SERVER / "tables" / "variants"):
        for path in sorted(folder.rglob("*.tsv")):
            header, body = rows_of(path)
            tables += 1
            columns += len(header)
            if len(header) != len(set(header)):
                bad_dup += 1
                lines.append(f"  tên trùng: {path.relative_to(ROOT)}")
            stems: dict[str, list[str]] = {}
            for name in header:
                match = re.fullmatch(r"(.+)_(\d+)", name)
                stem = match.group(1) if match else name
                stems.setdefault(stem, []).append(name)
            for stem, names in stems.items():
                if len(names) < 2:
                    continue
                expected = [f"{stem}_{index}" for index in range(1, len(names) + 1)]
                if names != expected:
                    half += 1
                    lines.append(f"  đánh số lệch {path.name}: {names} kỳ vọng {expected}")
    for folder_name in ("shared", "variants"):
        for path in (TOOLS / "columns" / folder_name).rglob("*.tsv"):
            _header, body = rows_of(path)
            for row in body:
                note = row[-1] if row else ""
                if "?" in note:
                    question += 1
                elif row[2] != "" and not row[2].startswith("column_"):
                    named += 1
    lines.append(
        f"bảng shared+variants {tables}, cột header {columns},"
        f" header trùng {bad_dup}, đánh số không từ 1 {half}"
    )
    lines.append(f"spec shared+variants có ? {question}, tên không column_ và không ? {named}")


def within(lines: list[str]) -> None:
    scene_ini = LEGACY / "Server" / "Config" / "SceneInfo.ini"
    declared = ""
    for _section, key, _number in ini_keys(scene_ini):
        if key == "scenenumber":
            text = scene_ini.read_text(encoding="utf-8")
            for line in text.splitlines():
                if line.strip().startswith("scenenumber="):
                    declared = line.split("=", 1)[1].split(";")[0].strip()
            break
    header, body = rows_of(SERVER / "tables" / "server" / "scenes.tsv")
    index = header.index("within_declared_count")
    ones = sum(1 for row in body if row[index] == "1")
    zeros = sum(1 for row in body if row[index] == "0")
    lines.append(f"scenes within=1 {ones} within=0 {zeros} scenenumber={declared} cột {header}")
    for name in (
        "scene_hosting.tsv",
        "rolling_announcements.tsv",
        "scheduled_events.tsv",
        "random_shop_goods.tsv",
    ):
        header, body = rows_of(SERVER / "tables" / "server" / name)
        index = header.index("within_declared_count")
        count = Counter(row[index] for row in body)
        banned = [item for item in ("broadtime", "broadcount", "huodongcount") if item in header]
        lines.append(f"{name}: {len(body)} dòng within {dict(count)} cột cấm {banned}")


def rules_cover(lines: list[str]) -> None:
    sources = {
        "Server/Config/ConfigInfo.ini": ini_keys,
        "Server/Config/DefaultChar.ini": ini_keys,
        "Server/Config/PetConfigTable.ini": ini_keys,
        "Server/Config/DarkConfigTable.ini": ini_keys,
        "Server/Config/CopyScene.ini": ini_keys,
        "Public/Config/CombatLimits.ini": bare_keys,
        "Server/Config/SystemInfo.ini": info_keys,
        "Server/Config/MergeConfig.txt": merge_keys,
    }
    found: list[tuple[str, str, str]] = []
    for relative, reader in sources.items():
        for section, key, _number in reader(LEGACY / relative):
            found.append((relative, section, key))
    header, body = rows_of(TOOLS / "legacy_rules.tsv")
    known = [(row[0], row[1], row[2]) for row in body]
    fate = Counter(row[3] for row in body)
    source_dup = [item for item, count in Counter(found).items() if count > 1]
    missing = [item for item in found if item not in set(known)]
    extra = [item for item in known if item not in set(found)]
    duplicate = [item for item, count in Counter(known).items() if count > 1]
    lines.append(
        f"khoá nguồn {len(found)} dòng luật {len(known)} fate {dict(fate)} nguồn trùng {len(source_dup)}"
    )
    lines.append(f"thiếu {len(missing)} thừa {len(extra)} trùng {len(duplicate)}")
    for item in missing[:8]:
        lines.append(f"  thiếu {item}")
    for item in extra[:8]:
        lines.append(f"  thừa {item}")
    unknown = [row for row in body if row[3] == "unknown" and row[11] != "chưa làm ở đợt 2"]
    lines.append(f"unknown lý do khác chưa làm: {len(unknown)}")
    for row in unknown:
        lines.append(f"  {row[1]}.{row[2]} reason={row[11]}")


def scene_files(lines: list[str]) -> None:
    folder = LEGACY / "Public" / "Scene"
    files = [path for path in folder.iterdir() if path.is_file()]
    dirs = [path for path in folder.iterdir() if path.is_dir()]
    header, body = rows_of(TOOLS / "scene_attach.tsv")
    names = [row[0] for row in body]
    fate = Counter(row[1] for row in body)
    missing = [name for name in names if not (folder / name).is_file()]
    lines.append(
        f"Public/Scene tệp {len(files)} thư mục {len(dirs)} attach {len(body)}"
        f" fate {dict(fate)} trùng tên {len(names) - len(set(names))} thiếu trên đĩa {missing}"
    )
    ops = list((SERVER / "scenes").rglob("ops.*.tsv"))
    vals = list((SERVER / "scenes").rglob("vals.*.tsv"))
    sets = list((SERVER / "scenes").rglob("spawns.set_*.tsv"))
    areas = list((SERVER / "scenes").rglob("areas.set_*.tsv"))
    scene_dirs = [path for path in (SERVER / "scenes").iterdir() if path.is_dir()]
    lines.append(
        f"cảnh xuất {len(scene_dirs)} ops {len(ops)} vals {len(vals)}"
        f" spawns.set {len(sets)} areas.set {len(areas)}"
    )
    header, refs = rows_of(SERVER / "tables" / "server" / "scene_load_refs.tsv")
    how = Counter(row[5] for row in refs)
    kind = Counter(row[2] for row in refs)
    lines.append(f"scene_load_refs {len(refs)} how {dict(how)} kind {dict(kind)} cột {header}")


def alignment_sum(lines: list[str]) -> None:
    header, body = rows_of(TOOLS / "column_alignment.tsv")
    totals = Counter()
    for row in body:
        for name, cell in zip(header, row):
            if name in ("source", "lost_list"):
                continue
            totals[name] += int(cell)
    lines.append(f"cặp căn {len(body)} tổng {dict(totals)}")
    header, terms = rows_of(TOOLS / "column_terms.tsv")
    basis = Counter()
    for row in terms:
        kind = row[2].split(":", 1)[0]
        basis[kind] += 1
    lines.append(f"thuật ngữ {len(terms)} basis {dict(basis)}")


def boundary(lines: list[str]) -> None:
    stamp = (ROOT / "docs" / "giao-viec" / "P1-DOT-2" / "moc" / "treehash.txt").stat().st_mtime
    watched = [
        TOOLS / "config_style.py",
        TOOLS / "lint_config.py",
        TOOLS / "setup_db.py",
    ]
    config = SERVER / "config"
    for path in sorted(config.rglob("*")):
        if path.is_file() and "rules" not in path.relative_to(config).parts:
            watched.append(path)
    for path in watched:
        if not path.is_file():
            lines.append(f"không có {path.relative_to(ROOT)}")
            continue
        newer = path.stat().st_mtime > stamp + 1
        if newer:
            lines.append(f"mtime sau mốc: {path.relative_to(ROOT)}")
    lines.append(f"tệp config ngoài rules đã xem {len(watched)}")


def secrets(lines: list[str]) -> None:
    roots = [SERVER / "tables", SERVER / "scenes", SERVER / "config" / "rules", ROOT / "docs" / "giao-viec" / "P1-DOT-2"]
    hits = []
    for root in roots:
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix.lower() not in {".tsv", ".toml", ".md", ".py", ".txt"}:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeError:
                continue
            if "Account.txt" in text or "password" in text.lower():
                hits.append(str(path.relative_to(ROOT)))
    lines.append(f"chỗ nhắc Account.txt hoặc password: {len(hits)}")
    for name in hits:
        if "secrets" in name.lower():
            lines.append(f"  BỎ QUA NỘI DUNG {name}")
            continue
        lines.append(f"  {name}")


def main() -> None:
    lines: list[str] = []
    for name in ("column_terms.tsv", "legacy_rules.tsv", "scene_attach.tsv", "column_alignment.tsv"):
        hand_shape(TOOLS / name, lines)
    repeated_headers(lines)
    within(lines)
    rules_cover(lines)
    scene_files(lines)
    alignment_sum(lines)
    boundary(lines)
    secrets(lines)
    text = "\n".join(lines) + "\n"
    OUT.write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
