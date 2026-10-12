"""Kiểm độc lập kết quả P1 đợt 2 (Claude, 2026-10-07). Không gọi mã của A, B, C, L, R.

    python docs/giao-viec/P1-DOT-2/kiem-claude/verify_p2.py [E] [F] [G]

Cần THIENLONG_LEGACY_ROOT (thư mục tlbb). E: 578 khoá của legacy_rules.tsv so với bộ đọc ini viết
lại, giá trị từng khoá rule so với TOML luật, khoá process_config so với TOML tiến trình. F: lời gọi
LuaFnSetSceneLoad_* quét lại bằng biểu thức chính quy, so với scene_load_refs.tsv; scene_attach.tsv
so với đĩa. G: từng cột đã ghép của 76 cặp bảng tính lại tỉ lệ khớp; cột "mới ở 2026" tìm lại trong
các cột gốc bị ghi mất.
"""
import os
import re
import struct
import sys
import tomllib
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation
from pathlib import Path

HERE = Path(__file__).resolve()
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / "docs/giao-viec/P1-DOT-1/kiem-claude"))
from verify_p1 import atoi, parse_like_cpp, read_legacy_text  # noqa: E402

sys.stdout.reconfigure(encoding="utf-8")
TLBB = Path(os.environ.get("THIENLONG_LEGACY_ROOT", "thiếu THIENLONG_LEGACY_ROOT"))
SERVER = ROOT / "dev" / "server"
TOOLS = ROOT / "TOOLS/server"
PARTS = set(sys.argv[1:]) or {"E", "F", "G"}


def table(path: Path):
    header, types, rows, problems, meta = parse_like_cpp(path)
    assert not problems, (path, problems)
    return [dict(zip(header, row)) for row in rows]


# ---------------------------------------------------------------- E: luật
def ini_keys(path: Path):
    """Theo Ini.cpp, thêm section rỗng cho khoá đứng trước mọi section."""
    sections = {"": {}}
    current = sections[""]
    for line in path.read_bytes().decode("utf-8").split("\n"):
        if line.startswith("["):
            name = re.split(r"[;\r\t\]]", line[1:], maxsplit=1)[0]
            current = sections.setdefault(name, {})
            continue
        if line.startswith(("#", ";")):
            continue
        match = re.match(r"([^=;\r]*)=", line)
        if not match:
            continue
        value = re.split(r"[;\r\t\]]", line[match.end() :], maxsplit=1)[0]
        current.setdefault(match.group(1), value)
    return sections


def source_keys(source: str):
    path = TLBB / source
    if source.endswith(".txt"):
        _, rows, _ = read_legacy_text(path)
        names = path.read_bytes().decode("utf-8").split("\n")[1].rstrip("\r").split("\t")
        return {("", row[names.index("KEY")]): "" for row in rows}
    found = {}
    for section, pairs in ini_keys(path).items():
        if source.endswith("SystemInfo.ini") and section != "info":
            continue
        for key, value in pairs.items():
            found[(section, key)] = value
    return found


def convert(kind: str, raw: str):
    text = raw.strip()
    if kind == "int":
        return int(text) if re.fullmatch(r"[+-]?\d+", text) else ("không phải số nguyên", raw)
    if kind in ("permille", "ppm"):
        try:
            scaled = Decimal(text) * (1000 if kind == "permille" else 1000000)
        except InvalidOperation:
            return ("không phải số thập phân", raw)
        return int(scaled) if scaled == scaled.to_integral_value() else ("không chia hết", raw)
    if kind == "bool":
        return {"0": False, "1": True}.get(text, ("không phải 0/1", raw))
    if kind == "decimal":
        return float(Decimal(text))
    return raw


def toml_value(folder: Path, row):
    with (folder / row["target_file"]).open("rb") as handle:
        document = tomllib.load(handle)
    node = document[row["target_table"]] if row["target_table"] else document
    return node.get(row["target_key"], "<thiếu khoá>")


def leaves(document, prefix=()):
    for key, value in document.items():
        if isinstance(value, dict):
            yield from leaves(value, prefix + (key,))
        else:
            yield prefix + (key,), value


def part_e():
    rows = table(TOOLS / "legacy_rules.tsv")
    by_source = defaultdict(dict)
    for row in rows:
        by_source[row["source"]][(row["section"], row["key"])] = row
    missing = extra = 0
    values = {}
    for source, listed in sorted(by_source.items()):
        real = source_keys(source)
        missing += len(set(real) - set(listed))
        extra += len(set(listed) - set(real))
        for key in sorted(set(real) ^ set(listed)):
            print("    khoá lệch:", source, key)
        values[source] = real
    fates = Counter(row["fate"] for row in rows)
    print(f"E: {len(rows)} dòng, {len(by_source)} nguồn; nguồn có mà bảng thiếu {missing}, bảng có mà nguồn thiếu {extra}; {dict(fates)}")

    bad = 0
    covered = defaultdict(set)
    for fate, folder in (("rule", SERVER / "config/rules"), ("process_config", SERVER / "config")):
        compared = 0
        for row in rows:
            if row["fate"] != fate:
                continue
            raw = values[row["source"]][(row["section"], row["key"])]
            want = convert(row["convert"], raw)
            got = toml_value(folder, row)
            if row["index"] != "":
                index = int(row["index"])
                if isinstance(got, list) and fate == "process_config" and index >= 1 and row["key"][-2:].isdigit():
                    index -= 1
                got = got[index] if isinstance(got, list) and index < len(got) else "<thiếu phần tử>"
                covered[(row["target_file"], row["target_table"], row["target_key"])].add(index)
            else:
                covered[(row["target_file"], row["target_table"], row["target_key"])].add(None)
            compared += 1
            if got != want or type(got) is not type(want):
                bad += 1
                print(f"    lệch {fate}: {row['source']} [{row['section']}] {row['key']}={raw!r} -> {want!r}, toml {got!r}")
        print(f"    {fate}: so {compared} khoá với TOML")
    orphan = 0
    for path in sorted((SERVER / "config/rules").glob("*.toml")):
        with path.open("rb") as handle:
            document = tomllib.load(handle)
        for keys, value in leaves(document):
            if keys == ("schema",):
                continue
            where = (path.name, ".".join(keys[:-1]), keys[-1])
            have = covered.get(where)
            size = len(value) if isinstance(value, list) else None
            full = have == ({None} if size is None else set(range(size)))
            if not full:
                orphan += 1
                print("    cài đặt TOML không khớp dòng nào hoặc mảng hở:", where, value, have)
    print(f"    giá trị lệch {bad}; cài đặt TOML không có dòng nguồn {orphan}")


# ---------------------------------------------------------------- F: lời gọi nạp cảnh
CALL = re.compile(r"LuaFnSetSceneLoad_(\w+)\s*\(")


def scan_calls():
    root = TLBB / "Public/Data/Script"
    found = {}
    commented = 0
    files = 0
    for path in sorted(root.rglob("*.lua")):
        files += 1
        text = path.read_bytes().decode("utf-8", errors="replace")
        for number, line in enumerate(text.split("\n"), start=1):
            for match in CALL.finditer(line):
                if "--" in line[: match.start()]:
                    commented += 1
                    continue
                script = path.relative_to(root).as_posix()
                found[(script, number, match.group(1).lower())] = line[match.end() :]
    return files, found, commented


def part_f():
    files, found, commented = scan_calls()
    rows = table(SERVER / "tables/server/scene_load_refs.tsv")
    listed = {(row["script"], int(row["line"]), row["kind"]): row for row in rows}
    only_disk = sorted(set(found) - set(listed))
    only_table = sorted(set(listed) - set(found))
    print(f"F: {files} tệp lua, lời gọi sống {len(found)}, sau chú thích {commented}; bảng {len(rows)} dòng; chỉ đĩa {len(only_disk)}, chỉ bảng {len(only_table)}")
    for key in (only_disk + only_table)[:10]:
        print("    lệch:", key)
    scene_files = {path.name.casefold() for path in (TLBB / "Public/Scene").iterdir()}
    bad_literal = missing_file = 0
    for key, row in listed.items():
        tail = found.get(key, "")
        if row["how"] == "literal":
            quoted = re.search(r",\s*\"([^\"]*)\"\s*\)", tail)
            if not quoted or quoted.group(1) != row["resolved"]:
                bad_literal += 1
                print("    literal lệch:", key, row["resolved"], tail.strip()[:80])
        if row["how"] in ("literal", "constant") and row["resolved"].casefold() not in scene_files:
            missing_file += 1
            print("    tệp đã suy không có trên đĩa:", key, row["resolved"])
    print(f"    literal không trùng chuỗi trong mã {bad_literal}; literal/constant trỏ tệp không có {missing_file}; how {dict(Counter(row['how'] for row in rows))}")

    attach = table(TOOLS / "scene_attach.tsv")
    stems = {path.stem for path in (TLBB / "Public/Scene").glob("*.scn")}
    script_root = TLBB / "Public/Data/Script"
    problems = 0
    for row in attach:
        if row["file"].casefold() not in scene_files:
            problems += 1
            print("    scene_attach: tệp không có trên đĩa", row["file"])
        if row["fate"] != "scene_set":
            continue
        script, number = row["evidence"].rsplit(":", 1)
        line = (script_root / script).read_bytes().decode("utf-8", errors="replace").split("\n")[int(number) - 1]
        ok = row["scene"] in stems and "LuaFnSetSceneLoad_" in line
        named = row["file"] in line
        print(f"    {row['file']} -> {row['scene']}: dòng dẫn có lời gọi {ok}, ghi thẳng tên tệp {named}")
        problems += 0 if ok else 1
    print(f"    scene_attach {len(attach)} dòng {dict(Counter(row['fate'] for row in attach))}, vấn đề {problems}")


# ---------------------------------------------------------------- G: căn cột
NOTE = re.compile(r"^(neo|chéo|nội suy|đổi kiểu): cột gốc (\d+), (?:khớp [\d.]+% \((\d+)/(\d+) id\)|không có id chung)")
PACK = struct.Struct("<f")
NUMBER = re.compile(r"[+-]?\d+")


def bits(text: str):
    try:
        return PACK.pack(float(text))
    except (ValueError, OverflowError):
        return None


def cell(kind: str, text: str):
    if kind == "int":
        return ("int", atoi(text))
    if kind == "float":
        return ("float", bits(text))
    return ("text", text)


def same(left, right) -> bool:
    if left[0] == right[0]:
        return left[1] == right[1] and left[1] is not None
    whole = [value if kind == "int" else int(value) if kind == "text" and NUMBER.fullmatch(value) else None for kind, value in (left, right)]
    if whole[0] is not None and whole[1] is not None:
        return whole[0] == whole[1]
    numbers = []
    for kind, value in (left, right):
        if kind == "int":
            numbers.append(float(value))
        elif kind == "float":
            numbers.append(None if value is None else PACK.unpack(value)[0])
        else:
            packed = bits(value) if re.fullmatch(r"[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?", value) else None
            numbers.append(None if packed is None else PACK.unpack(packed)[0])
    return numbers[0] is not None and numbers[0] == numbers[1]


def id_key(kind: str, text: str):
    if kind == "int" or NUMBER.fullmatch(text):
        return atoi(text)
    return text


def load_pair(source: str, target: str):
    header, types, rows, _, _ = parse_like_cpp(SERVER / target)
    legacy_types, legacy_rows, _ = read_legacy_text(TLBB / "Public/Config" / source)
    kinds_old = [{"INT": "int", "FLOAT": "float"}.get(kind.upper(), "text") for kind in legacy_types]
    keyed = {}
    for row in legacy_rows:
        keyed.setdefault(id_key(kinds_old[0], row[0]), row)
    # Bản 2026 của vài bảng chèn thêm một cột số thứ tự ở đầu: khoá của nó nằm ở cột 1. Thử cột 0
    # trước; không dòng nào trùng khoá thì thử cột 1 (thêm ở P2 đợt 1, hai bảng cần tới).
    for key_column in (0, 1):
        new_rows, old_rows = [], []
        for row in rows:
            old = keyed.get(id_key(types[key_column], row[key_column])) if key_column < len(row) else None
            if old is None:
                continue
            new_rows.append([cell(kind, text) for kind, text in zip(types, row)])
            old_rows.append([cell(kind, text) for kind, text in zip(kinds_old, old)])
        if new_rows:
            break
    return types, kinds_old, new_rows, old_rows


def rate(new_rows, old_rows, left: int, right: int) -> int:
    return sum(1 for index, row in enumerate(new_rows) if same(row[left], old_rows[index][right]))


def distinct(rows, column: int) -> int:
    return len({row[column] for row in rows})


def part_g():
    names = {row["source"]: row["target"] for row in table(TOOLS / "table_names.tsv") if row["tree"] == "client_2026"}
    pairs = table(TOOLS / "column_alignment.tsv")
    totals = Counter()
    count_diff = weak = low_named = 0
    missed = []
    for pair in pairs:
        source = pair["source"]
        target = names[source]
        columns = table(TOOLS / "columns" / Path(target).relative_to("tables"))
        types, kinds_old, new_rows, old_rows = load_pair(source, target)
        used = set()
        fresh = []
        for column in columns:
            index = int(column["index"])
            note = column["note"]
            if note.startswith("mới ở 2026"):
                totals["mới"] += 1
                fresh.append(index)
                continue
            match = NOTE.match(note)
            if not match:
                totals["note lạ"] += 1
                print("    note lạ:", source, index, note[:70])
                continue
            kind, right = match.group(1), int(match.group(2))
            used.add(right)
            totals[kind] += 1
            mine = rate(new_rows, old_rows, index, right)
            theirs = int(match.group(3) or 0)
            if mine != theirs or len(new_rows) != int(match.group(4) or 0):
                count_diff += 1
                if count_diff <= 12:
                    print(f"    tỉ lệ khác: {source} cột {index}->{right} {kind}: tôi {mine}/{len(new_rows)}, bảng {match.group(3)}/{match.group(4)}")
            total = len(new_rows)
            varied = distinct(new_rows, index) >= 3 and distinct(old_rows, right) >= 3
            if kind in ("neo", "chéo") and total and mine * 100 < 95 * total:
                weak += 1
                print(f"    neo yếu: {source} cột {index}->{right} {mine}/{total}")
            if kind == "nội suy" and varied and mine * 100 < 95 * total:
                low_named += 1
                print(f"    nội suy nhiều giá trị dưới 95%: {source} cột {index}->{right} {mine}/{total}")
        lost = [right for right in range(len(kinds_old)) if right not in used]
        total = len(new_rows)
        for left in fresh:
            if not total or distinct(new_rows, left) < 3:
                continue
            for right in lost:
                if distinct(old_rows, right) < 3:
                    continue
                hit = rate(new_rows, old_rows, left, right)
                if hit * 100 >= 95 * total:
                    missed.append((source, left, right, hit, total))
    print(f"G: {len(pairs)} cặp; {dict(totals)}; tỉ lệ tôi tính khác bảng {count_diff}; neo dưới 95% {weak}; nội suy nhiều giá trị dưới 95% {low_named}")
    by_left = Counter((source, left) for source, left, _, _, _ in missed)
    by_right = Counter((source, right) for source, _, right, _, _ in missed)
    unique = [item for item in missed if by_left[(item[0], item[1])] == 1 and by_right[(item[0], item[2])] == 1]
    print(f"    cột 'mới ở 2026' khớp từ 95% với một cột gốc bị ghi mất: {len(by_left)} cột, trong đó ghép một-một rõ ràng {len(unique)}")
    for source, left, right, hit, total in unique[:40]:
        print(f"      {source}: cột 2026 {left} = cột gốc {right}, {hit}/{total}")


if __name__ == "__main__":
    if "E" in PARTS:
        part_e()
    if "F" in PARTS:
        part_f()
    if "G" in PARTS:
        part_g()
