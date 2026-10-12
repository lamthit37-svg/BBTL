"""Đếm lại missing_values và vài số nợ. Không import diff_tables hay chạy thienlong_lint."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SERVER = ROOT / "dev" / "server"
COLUMNS = ROOT / "TOOLS" / "server" / "columns"
INT_CELL = re.compile(r"-?(0|[1-9][0-9]*)")
COLUMN_N = re.compile(r"column_\d+(?:_\d+)?")
M1 = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
M2 = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)[(（].*[)）]$")
STEM = re.compile(r"(.*)\$\d+\$$")

CHOSEN = (
    ("shared.tsv", "tables/shared/monsters.tsv", "attack_trait_id", "tables/shared/attack_traits.tsv", "id", "-1"),
    ("shared.tsv", "tables/shared/items_common.tsv", "required_skill", "tables/shared/life_skills.tsv", "id", "-1;0"),
    ("server.tsv", "tables/server/monster_drops.tsv", "id", "tables/shared/monsters.tsv", "monster_id", ""),
    ("server.tsv", "tables/server/gacha_item_pools.tsv", "gacha_id", "tables/server/gacha_machines.tsv", "gacha_id", ""),
    ("scenes.tsv", "scenes/*/spawns*.tsv", "type", "tables/shared/monsters.tsv", "monster_id", ""),
    ("scenes.tsv", "scenes/*/spawns*.tsv", "script_id", "tables/server/script_index.tsv", "script_id", "-1"),
)


def match_segment(pattern: str, text: str) -> tuple[str, bool] | None:
    if pattern.count("*") > 1:
        return None
    if "*" not in pattern:
        if pattern != text:
            return None
        return "", False
    left, right = pattern.split("*", 1)
    if len(text) < len(left) + len(right):
        return None
    if not text.startswith(left):
        return None
    if right and not text.endswith(right):
        return None
    end = len(text) - len(right)
    return text[len(left) : end], True


def match_path(pattern: str, path: str) -> str | None:
    left = pattern.split("/")
    right = path.split("/")
    if len(left) != len(right):
        return None
    capture = ""
    taken = False
    for pattern_part, text_part in zip(left, right, strict=True):
        got = match_segment(pattern_part, text_part)
        if got is None:
            return None
        part, starred = got
        if starred and not taken:
            capture = part
            taken = True
    return capture


def load_table(path: Path) -> tuple[list[str], list[str], list[list[str]]]:
    lines = path.read_text(encoding="utf-8").split("\n")
    if lines and lines[-1] == "":
        lines = lines[:-1]
    types: list[str] = []
    header: list[str] = []
    body: list[list[str]] = []
    for line in lines:
        if line.startswith("# types: "):
            types = line[len("# types: ") :].split("\t")
            continue
        if not line or line.startswith("#"):
            continue
        cells = line.split("\t")
        if not header:
            header = cells
            continue
        body.append(cells)
    return types, header, body


def files_under(pattern: str) -> list[tuple[str, Path]]:
    first = pattern.split("/", 1)[0]
    base = SERVER / first if "*" not in first else SERVER
    found: list[tuple[str, Path]] = []
    if not base.is_dir():
        return found
    for path in sorted(base.rglob("*.tsv")):
        relative = path.relative_to(SERVER).as_posix()
        if match_path(pattern, relative) is not None:
            found.append((relative, path))
    return found


def parent_path(child: str, child_pattern: str, parent_pattern: str) -> str:
    if "*" not in parent_pattern:
        return parent_pattern
    capture = match_path(child_pattern, child)
    if capture is None:
        raise ValueError(child)
    return parent_pattern.replace("*", capture, 1)


def measure(child_pattern: str, child_column: str, parent_pattern: str, parent_column: str, absent_text: str) -> None:
    absent = set(absent_text.split(";")) if absent_text else set()
    starred = "*" in parent_pattern
    distinct: set[tuple[str, str]] = set()
    missing: set[tuple[str, str]] = set()
    missing_rows = 0
    references = 0
    row_count = 0
    children = files_under(child_pattern)
    cache: dict[str, set[str] | None] = {}
    for relative, path in children:
        _types, header, body = load_table(path)
        row_count += len(body)
        index = header.index(child_column)
        parent = parent_path(relative, child_pattern, parent_pattern)
        if parent not in cache:
            parent_file = SERVER / parent
            if not parent_file.is_file():
                cache[parent] = None
            else:
                _ptypes, pheader, pbody = load_table(parent_file)
                pindex = pheader.index(parent_column)
                cache[parent] = {row[pindex] for row in pbody if row[pindex] != ""}
        keys = cache[parent]
        capture = match_path(child_pattern, relative) if starred else ""
        if capture is None:
            capture = ""
        for row in body:
            value = row[index]
            if value == "" or value in absent:
                continue
            references += 1
            pair = (capture, value)
            distinct.add(pair)
            if keys is None or value not in keys:
                missing.add(pair)
                missing_rows += 1
    smallest = sorted(missing)[:8]
    print(
        f"{child_pattern} {child_column}: tệp {len(children)} dòng {row_count}"
        f" trỏ {references} khác {len(distinct)} thiếu {len(missing)} ô {missing_rows}"
    )
    print(f"  mẫu thiếu {smallest}")


def stem_of(original: str) -> str:
    matched = STEM.fullmatch(original)
    if matched is None:
        return original
    return matched.group(1)


def machine_label(original: str) -> str:
    body = stem_of(original.strip())
    if M2.fullmatch(original.strip()):
        return "M2"
    if M1.fullmatch(body):
        return "M1"
    return ""


def scan_machine_names() -> None:
    hits: list[str] = []
    for path in sorted(COLUMNS.rglob("*.tsv")):
        _types, header, body = load_table(path)
        name_at = header.index("name")
        original_at = header.index("original")
        for row in body:
            kind = machine_label(row[original_at])
            if kind and COLUMN_N.fullmatch(row[name_at]):
                relative = path.relative_to(COLUMNS).as_posix()
                hits.append(f"{relative}: {kind} {row[original_at]!r} -> {row[name_at]}")
    print(f"M1/M2 còn column_n: {len(hits)}")
    for line in hits:
        print(f"  {line}")


def scan_cells() -> None:
    bad_int = 0
    bad_float = 0
    files = 0
    records = 0
    cells = 0
    for folder in (SERVER / "tables", SERVER / "scenes"):
        for path in sorted(folder.rglob("*.tsv")):
            files += 1
            types, header, body = load_table(path)
            records += len(body)
            width = len(header)
            for row in body:
                cells += len(row)
                for index, value in enumerate(row):
                    if index >= len(types):
                        continue
                    if types[index] == "int" and value and INT_CELL.fullmatch(value) is None:
                        bad_int += 1
                    if types[index] == "float" and value != value.strip():
                        bad_float += 1
                    if types[index] == "int" and index >= width:
                        bad_int += 1
    print(f"tệp {files} bản ghi {records} ô {cells} int lệch {bad_int} float có trắng {bad_float}")


def level_files() -> None:
    _types, header, body = load_table(SERVER / "tables" / "server" / "scene_level_files.tsv")
    verdict_at = header.index("verdict")
    counts: dict[str, int] = {}
    for row in body:
        counts[row[verdict_at]] = counts.get(row[verdict_at], 0) + 1
    print(f"scene_level_files dòng {len(body)} {counts}")


def shuilao() -> None:
    path = SERVER / "tables" / "server" / "scene_load_refs.tsv"
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if "shuilao_monster_" in line and "efuben_3_shuilao" in line:
            print(f"scene_load_refs:{number}: {line}")


def patrol_repeats() -> None:
    files = 0
    repeated = 0
    for relative, path in files_under("scenes/*/patrols*.tsv"):
        files += 1
        _types, header, body = load_table(path)
        if "patrol_index" not in header:
            print(f"không có patrol_index: {relative}")
            continue
        index = header.index("patrol_index")
        counts: dict[str, int] = {}
        for row in body:
            value = row[index]
            counts[value] = counts.get(value, 0) + 1
        repeated += sum(1 for count in counts.values() if count > 1)
    print(f"patrols tệp {files} giá trị lặp cộng {repeated}")


def term_shape() -> None:
    for name in ("column_terms.tsv", "column_terms_server.tsv"):
        path = ROOT / "TOOLS" / "server" / name
        basis: dict[str, int] = {}
        keys: set[tuple[str, str]] = set()
        duplicate = 0
        brace = 0
        rows = 0
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if not line or line.startswith("#") or line.startswith("original\t"):
                continue
            cells = line.split("\t")
            rows += 1
            if len(cells) != 5:
                print(f"{name}:{number}: {len(cells)} cột")
                continue
            key = (cells[0], cells[1])
            if key in keys:
                duplicate += 1
            keys.add(key)
            kind = "code" if cells[3].startswith("code:") else cells[3]
            basis[kind] = basis.get(kind, 0) + 1
            if cells[0].count("{n}") != cells[2].count("{n}"):
                brace += 1
                print(f"{name}:{number}: số {{n}} lệch {cells[0]!r} -> {cells[2]!r}")
        print(f"{name}: dòng {rows} trùng khoá {duplicate} {{n}} lệch {brace} basis {basis}")


def main() -> None:
    for item in CHOSEN:
        measure(item[1], item[2], item[3], item[4], item[5])
    scan_machine_names()
    level_files()
    shuilao()
    patrol_repeats()
    term_shape()
    scan_cells()


if __name__ == "__main__":
    main()
