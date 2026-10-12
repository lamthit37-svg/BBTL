"""Kiểm độc lập kết quả P1 đợt 3 (Claude, 2026-10-07). Không gọi mã của A, B, C, L, R.

    python -B docs/giao-viec/P1-DOT-3/kiem-claude/verify_p3.py [H] [J] [L] [N]

Cần THIENLONG_LEGACY_ROOT cho phần L. H: đếm lại từng dòng của TOOLS/server/refs theo mục 5.2 và
5.3 của đề bài đợt 3, so với table_ref_coverage.tsv và known_missing. J: mọi ô int và float của
SERVER/tables và SERVER/scenes ở dạng chính tắc. L: files_on_disk của scene_load_refs.tsv và số
dòng theo verdict của scene_level_files.tsv. N: độ nhất quán của hai bảng thuật ngữ tên cột.
"""
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve()
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / "docs/giao-viec/P1-DOT-1/kiem-claude"))
from verify_p1 import parse_like_cpp  # noqa: E402

sys.stdout.reconfigure(encoding="utf-8")
SERVER = ROOT / "SERVER"
TOOLS = ROOT / "TOOLS/server"
PARTS = set(sys.argv[1:]) or {"H", "J", "L", "N"}
INT = re.compile(r"-?(0|[1-9][0-9]*)")
FLOAT = re.compile(r"-?([0-9]+(\.[0-9]+)?|\.[0-9]+)([eE][+-]?[0-9]+)?")


def table(path: Path):
    header, types, rows, problems, _ = parse_like_cpp(path)
    assert not problems, (path, problems)
    return header, types, rows


def data_files():
    found = {}
    for base in ("tables", "scenes"):
        for path in (SERVER / base).rglob("*.tsv"):
            found[path.relative_to(SERVER).as_posix()] = path
    return dict(sorted(found.items()))


# ---------------------------------------------------------------- H: tham chiếu
def pattern_of(text: str):
    parts = []
    for segment in text.split("/"):
        parts.append("([^/]*)".join(re.escape(piece) for piece in segment.split("*")))
    return re.compile("/".join(parts))


def sort_key(kind: str, starred: bool):
    def value_key(value: str):
        return (int(value), value.encode()) if kind == "int" and INT.fullmatch(value) else (0, value.encode())

    if starred:
        return lambda pair: (pair[0].encode(), value_key(pair[1]))
    return lambda pair: value_key(pair[1])


def measure(row, files, cache):
    child_pattern = pattern_of(row["child"])
    absent = set(row["absent"].split(";")) if row["absent"] else set()
    starred = "*" in row["parent"]
    child_files = child_rows = references = 0
    pairs = Counter()
    kinds = set()
    for name, path in files.items():
        match = child_pattern.fullmatch(name)
        if not match:
            continue
        if name not in cache:
            cache[name] = table(path)
        header, types, rows = cache[name]
        child_files += 1
        child_rows += len(rows)
        column = header.index(row["child_column"])
        kinds.add(types[column])
        capture = match.group(1) if starred and match.groups() else ""
        for cells in rows:
            cell = cells[column]
            if cell == "" or cell in absent:
                continue
            references += 1
            pairs[(capture, cell)] += 1
    missing = {}
    parents = {}
    duplicate_keys = 0
    for (capture, value), count in pairs.items():
        parent_name = row["parent"].replace("*", capture, 1) if starred else row["parent"]
        if parent_name not in parents:
            keys = None
            if parent_name in files:
                if parent_name not in cache:
                    cache[parent_name] = table(files[parent_name])
                header, types, rows = cache[parent_name]
                column = header.index(row["parent_column"])
                values = [cells[column] for cells in rows]
                keys = set(values)
                duplicate_keys += len(values) - len(keys) + values.count("")
                kinds.add(types[column])
            parents[parent_name] = keys
        keys = parents[parent_name]
        if keys is None or value not in keys:
            missing[(capture, value)] = count
    kind = "int" if kinds == {"int"} else "text"
    ordered = sorted(missing, key=sort_key(kind, starred))[:5]
    first = ";".join(f"{capture}:{value}" if starred else value for capture, value in ordered)
    return [child_files, child_rows, references, len(pairs), len(missing), sum(missing.values()), first], kinds, duplicate_keys


def part_h():
    files = data_files()
    cache = {}
    refs = []
    for path in sorted((TOOLS / "refs").glob("*.tsv")):
        header, _, rows = table(path)
        refs += [dict(zip(header, row), file=path.name) for row in rows]
    cover_header, _, cover_rows = table(TOOLS / "table_ref_coverage.tsv")
    cover = [dict(zip(cover_header, row)) for row in cover_rows]
    bad = known_bad = type_bad = key_bad = 0
    distinct = set()
    for index, row in enumerate(refs):
        mine, kinds, duplicate_keys = measure(row, files, cache)
        theirs = cover[index] if index < len(cover) else {}
        names = ["child_files", "child_rows", "references", "distinct_values", "missing_values", "missing_rows", "first_missing"]
        got = [theirs.get(name, "?") for name in names]
        same_key = all(theirs.get(key) == row[key] for key in ("child", "child_column", "parent", "parent_column"))
        if [str(value) for value in mine] != got or not same_key:
            bad += 1
            print(f"    lệch bảng phủ: {row['child']}.{row['child_column']}: tôi {mine}, bảng {got}")
        if str(mine[4]) != row["known_missing"]:
            known_bad += 1
            print(f"    lệch known_missing: {row['child']}.{row['child_column']}: tôi {mine[4]}, refs {row['known_missing']}")
        if len(kinds) != 1 or "float" in kinds:
            type_bad += 1
            print(f"    kiểu: {row['child']}.{row['child_column']} -> {row['parent']}.{row['parent_column']}: {kinds}")
        if duplicate_keys:
            key_bad += 1
            print(f"    cột cha lặp hoặc rỗng: {row['parent']}.{row['parent_column']}: {duplicate_keys}")
        family = re.sub(r"\d+", "#", row["child_column"])
        distinct.add((row["child"], family, row["parent"], row["parent_column"]))
    per_file = Counter(row["file"] for row in refs)
    basis = Counter(row["basis"].split(":")[0] for row in refs)
    print(f"H: {len(refs)} dòng refs {dict(per_file)}, bảng phủ {len(cover)} dòng; lệch bảng phủ {bad}, lệch known_missing {known_bad}, sai kiểu {type_bad}, cột cha không là khoá {key_bad}")
    print(f"    quan hệ khác nhau sau khi gộp họ cột đánh số: {len(distinct)}; basis {dict(basis)}; dòng có giá trị thiếu {sum(1 for row in refs if row['known_missing'] != '0')}")


# ---------------------------------------------------------------- J: ô chính tắc
def part_j():
    stats = Counter()
    for name, path in data_files().items():
        header, types, rows = table(path)
        stats["tệp"] += 1
        stats["bản ghi"] += len(rows)
        for cells in rows:
            stats["ô"] += len(cells)
            for kind, cell in zip(types, cells):
                if cell == "" or kind == "text":
                    continue
                if kind == "int" and not (INT.fullmatch(cell) and -2147483648 <= int(cell) <= 2147483647):
                    stats["int sai"] += 1
                if kind == "float" and not FLOAT.fullmatch(cell):
                    stats["float sai"] += 1
    print(f"J: {dict(stats)}")


# ---------------------------------------------------------------- L: tệp cảnh
def part_l():
    legacy = Path(os.environ.get("THIENLONG_LEGACY_ROOT", "thiếu THIENLONG_LEGACY_ROOT"))
    names = [path.name.casefold() for path in (legacy / "Public/Scene").iterdir() if path.is_file()]
    header, _, rows = table(SERVER / "tables/server/scene_load_refs.tsv")
    bad = zero = 0
    for row in (dict(zip(header, cells)) for cells in rows):
        if row["how"] == "unresolved":
            bad += row["files_on_disk"] != ""
            continue
        options = [re.sub(r"%[ds]", "*", option.casefold()) for option in row["resolved"].split("|")]
        patterns = [re.compile(".*".join(re.escape(piece) for piece in option.split("*"))) for option in options]
        mine = sum(1 for name in names if any(pattern.fullmatch(name) for pattern in patterns))
        zero += mine == 0
        if str(mine) != row["files_on_disk"]:
            bad += 1
            if bad <= 8:
                print(f"    files_on_disk lệch: {row['script']}:{row['line']} {row['resolved'][:60]}: tôi {mine}, bảng {row['files_on_disk']}")
    header, _, level_rows = table(SERVER / "tables/server/scene_level_files.tsv")
    verdicts = Counter(dict(zip(header, cells))["verdict"] for cells in level_rows)
    print(f"L: scene_load_refs {len(rows)} dòng, files_on_disk lệch {bad}, dòng trỏ 0 tệp {zero}; scene_level_files {len(level_rows)} dòng {dict(verdicts)}")


# ---------------------------------------------------------------- N: nhất quán thuật ngữ
VARIANTS = (
    ("defence", "defense"),
    ("cold", "ice"),
    ("dodge", "miss"),
    ("chance", "odds"),
    ("dexterity", "agility"),
    ("intellect", "concentration"),
    ("mp", "mana"),
    ("restore", "regen"),
)


def part_n():
    terms = []
    for name in ("column_terms.tsv", "column_terms_server.tsv"):
        header, _, rows = table(TOOLS / name)
        terms += [dict(zip(header, row), file=name) for row in rows]
    names = defaultdict(set)
    for term in terms:
        names[term["original"]].add(term["name"])
    clash = {original: found for original, found in names.items() if len(found) > 1}
    tokens = Counter()
    for path in (TOOLS / "columns").rglob("*.tsv"):
        header, _, rows = table(path)
        for cells in rows:
            for token in dict(zip(header, cells))["name"].split("_"):
                tokens[token] += 1
    pairs = {f"{left}/{right}": (tokens[left], tokens[right]) for left, right in VARIANTS}
    print(f"N: {len(terms)} dòng thuật ngữ; nhãn nguyên văn có hơn một tên {len(clash)}; cặp từ cùng nghĩa trong tên cột đã sinh {pairs}")
    for original, found in sorted(clash.items())[:12]:
        print(f"    {original[:28]} -> {sorted(found)}")


if __name__ == "__main__":
    if "H" in PARTS:
        part_h()
    if "J" in PARTS:
        part_j()
    if "L" in PARTS:
        part_l()
    if "N" in PARTS:
        part_n()
