"""Đối chiếu P1 đợt 1 bằng đường riêng, không sửa mã A/B/C/L.

Đọc DBC bằng TOOLS/content/dbc.py. Tách TSV bằng split("\\t").
Bộ đọc bảng chữ và ini ở dưới viết theo TLBB_DBC.cpp và Ini.cpp, không gọi
import_legacy, export_tables, export_scene.

    python docs/giao-viec/P1-DOT-1/kiem/kiem_doc_lap.py
"""
from __future__ import annotations

import hashlib
import random
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
LEGACY = Path(r"C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb")
RAW = Path(r"F:\tl 2026\_raw")
sys.path.insert(0, str(ROOT / "TOOLS" / "content"))
import dbc  # noqa: E402

SEED = 20261006
SCENE = LEGACY / "Public" / "Scene"
TABLES = ROOT / "dev" / "server" / "tables"
SCENES = ROOT / "dev" / "server" / "scenes"
NAMES = ROOT / "TOOLS" / "server" / "table_names.tsv"


def files_under(folder: Path) -> list[str]:
    found = []
    for path in folder.rglob("*"):
        if path.is_file():
            found.append(path.relative_to(folder).as_posix())
    found.sort()
    return found


def read_names() -> list[list[str]]:
    rows = []
    for line in NAMES.read_text(encoding="utf-8").splitlines():
        if line == "" or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] == "tree":
            continue
        rows.append(cells)
    return rows


def load_tsv(path: Path) -> tuple[dict[str, str], list[str], list[str], list[list[str]], list[str]]:
    data = path.read_bytes()
    problems = []
    if data.startswith(b"\xef\xbb\xbf"):
        problems.append("BOM")
    if b"\r" in data:
        problems.append("CR")
    if b"\\" in data[:400] or b":\\" in data:
        problems.append("có dấu gạch ngược trong đầu tệp")
    text = data.decode("utf-8")
    if not text.endswith("\n"):
        problems.append("thiếu LF cuối")
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    meta: dict[str, str] = {}
    types: list[str] = []
    header: list[str] | None = None
    rows: list[list[str]] = []
    for line in lines:
        if line == "" or line.startswith("#"):
            if line.startswith("# source: "):
                meta["source"] = line[len("# source: ") :]
            elif line.startswith("# types: "):
                types = line[len("# types: ") :].split("\t")
            elif line.startswith("# tool: "):
                meta["tool"] = line
            continue
        cells = line.split("\t")
        if header is None:
            header = cells
            continue
        rows.append(cells)
    return meta, types, header or [], rows, problems


def c_atoi(cell: str) -> int | None:
    index = 0
    size = len(cell)
    while index < size and cell[index] in " \t\n\v\f\r":
        index += 1
    sign = 1
    if index < size and cell[index] in "+-":
        if cell[index] == "-":
            sign = -1
        index += 1
    if index >= size or not cell[index].isdigit():
        return 0
    limit = 2147483648 if sign < 0 else 2147483647
    value = 0
    while index < size and cell[index].isdigit():
        digit = ord(cell[index]) - 48
        if value > (limit - digit) // 10:
            return None
        value = value * 10 + digit
        index += 1
    if sign < 0:
        value = -value
    return value


def read_text_server(path: Path) -> tuple[list[str], list[list[str]], int]:
    """OpenFromMemoryImpl_Text: bỏ ô kiểu rỗng, chỉ lấy đúng số cột còn lại."""
    text = path.read_bytes().decode("utf-8")
    lines = text.splitlines()
    raw_types = lines[0].split("\t")
    kinds = [kind for kind in raw_types if kind != ""]
    max_line = 0
    body = []
    for line in lines[2:]:
        encoded = len(line.encode("utf-8"))
        if encoded > max_line:
            max_line = encoded
        if line == "" or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] == "":
            continue
        while len(cells) < len(kinds):
            cells.append("")
        body.append(cells[: len(kinds)])
    return kinds, body, max_line


def read_text_cut(raw: str) -> str:
    """Ini::ReadText: dừng tại ; tab hoặc ]."""
    for index, char in enumerate(raw):
        if char in ";\t]":
            return raw[:index]
    return raw


def canonical_int(text: str) -> bool:
    if text == "0":
        return True
    if text.startswith("-"):
        return text[1:].isdigit() and not text.startswith("-0")
    return text.isdigit() and not (len(text) > 1 and text.startswith("0"))


def section_coverage() -> None:
    print("== phủ nguồn ==")
    rows = read_names()
    trees = {
        "server_config": LEGACY / "Server" / "Config",
        "public_config": LEGACY / "Public" / "Config",
        "client_2026": RAW / "Config",
    }
    for tree, folder in trees.items():
        disk = files_under(folder)
        listed = [row[1] for row in rows if row[0] == tree]
        missing = sorted(set(disk) - set(listed))
        extra = sorted(set(listed) - set(disk))
        print(f"{tree}: đĩa {len(disk)}, bảng tên {len(set(listed))}, thiếu {len(missing)}, thừa {len(extra)}")
        for name in missing[:8]:
            print(f"  thiếu {name}")
        for name in extra[:8]:
            print(f"  thừa {name}")
    scene_files = [path for path in SCENE.iterdir() if path.is_file()]
    dirs = [path.name for path in SCENE.iterdir() if path.is_dir()]
    print(f"Public/Scene: tệp {len(scene_files)}, thư mục con {len(dirs)}")
    folded: dict[str, str] = {}
    case_hit = []
    for path in scene_files:
        key = path.name.casefold()
        if key in folded:
            case_hit.append(f"{folded[key]} / {path.name}")
        else:
            folded[key] = path.name
    print(f"tên cảnh chỉ khác hoa thường: {len(case_hit)}")
    for item in case_hit[:8]:
        print(f"  {item}")


def section_contract() -> None:
    print("== hợp đồng TSV đã xuất ==")
    bad_name = 0
    bad_file = 0
    samples = []
    absolute = 0
    counted = 0
    for path in list(TABLES.rglob("*.tsv")) + list(SCENES.rglob("*.tsv")):
        counted += 1
        meta, types, header, rows, problems = load_tsv(path)
        if problems or len(types) != len(header):
            bad_file += 1
            if len(samples) < 12:
                samples.append(f"{path.relative_to(ROOT).as_posix()}: {problems} kiểu {len(types)} cột {len(header)}")
        seen = set()
        for name in header:
            if name in seen or not name or name[0] < "a" or name[0] > "z":
                bad_name += 1
                if len(samples) < 12:
                    samples.append(f"{path.name}: tên cột {name!r}")
                break
            for char in name:
                if char not in "abcdefghijklmnopqrstuvwxyz0123456789_":
                    bad_name += 1
                    if len(samples) < 12:
                        samples.append(f"{path.name}: tên cột {name!r}")
                    break
            seen.add(name)
        source = meta.get("source", "")
        if ":\\" in source or source.startswith("/") or source.startswith("\\"):
            absolute += 1
        for row in rows:
            if len(row) != len(header):
                bad_file += 1
                if len(samples) < 12:
                    samples.append(f"{path.name}: lệch số ô")
                break
            if row and row[0].startswith("#"):
                bad_file += 1
                if len(samples) < 12:
                    samples.append(f"{path.name}: ô đầu bắt đầu bằng #")
                break
    print(f"tsv {counted}, tệp lệch hợp đồng {bad_file}, tên cột lệch {bad_name}, source tuyệt đối {absolute}")
    for line in samples:
        print(f"  {line}")


def section_level() -> None:
    print("== level spawns so với tệp quái và tệp level ==")
    shown = 0
    replaced = 0
    filled = 0
    checked = 0
    hidden_source = 0
    for path in SCENES.glob("*/spawns.tsv"):
        if path.name != "spawns.tsv":
            continue
        meta, _types, header, rows, _problems = load_tsv(path)
        level_file = SCENE / f"{path.parent.name}_monster_level.ini"
        if not level_file.is_file():
            continue
        source = meta.get("source", "")
        monster = SCENE / Path(source.split(" + ", 1)[0]).name
        if not monster.is_file():
            print(f"không thấy tệp quái {source}")
            continue
        mentioned = "_monster_level.ini" in source
        if not mentioned:
            hidden_source += 1
            print(f"{path.parent.name}: source không nêu tệp level: {source}")
        level_at = header.index("level")
        monster_levels = _ini_levels(monster)
        file_levels = _ini_levels(level_file)
        checked += 1
        for index, row in enumerate(rows):
            original = monster_levels.get(index)
            override = file_levels.get(index)
            cell = row[level_at]
            if original is None and override is not None and cell == override and cell != "":
                filled += 1
                if shown < 8:
                    shown += 1
                    print(f"{path.parent.name}: dòng {index} tệp quái không có level, tệp level {override!r} tsv {cell!r}")
            if original is not None and cell != original:
                replaced += 1
                if shown < 8:
                    shown += 1
                    print(f"{path.parent.name}: dòng {index} tệp quái {original!r} tệp level {override!r} tsv {cell!r}")
    print(f"cặp đã so {checked}, ô level khác tệp quái {replaced}, ô trống bị điền {filled}, source không ghi tệp level {hidden_source}")


def _ini_levels(path: Path) -> dict[int, str]:
    found = {}
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            name = stripped[1:-1]
            current = int(name[len("monster") :]) if name.startswith("monster") and name[len("monster") :].isdigit() else None
            continue
        if current is None or not line.startswith("level="):
            continue
        found[current] = read_text_cut(line.split("=", 1)[1])
    return found


def section_dbc() -> None:
    print("== DBC so từng ô ==")
    rows = read_names()
    targets = [(row[1], row[3]) for row in rows if row[0] == "client_2026" and row[2] == "table" and row[6] == "A"]
    mismatches = 0
    tables = 0
    records = 0
    sample_pool: list[tuple[str, int, int]] = []
    for source, target in targets:
        binary = dbc.read(str(RAW / "Config" / source), source)
        destination = TABLES / target[len("tables/") :]
        _meta, types, header, body, problems = load_tsv(destination)
        tables += 1
        records += len(body)
        if problems or len(body) != binary.rows or len(header) != binary.columns or len(types) != binary.columns:
            mismatches += 1
            print(f"lệch khung {source}: tsv {len(body)}x{len(header)} dbc {binary.rows}x{binary.columns} {problems}")
            continue
        seen: set[int] = set()
        for index in range(binary.rows):
            key = binary.raw(index, 0)
            if key in seen:
                mismatches += 1
                print(f"id cột 0 trùng {source} dòng {index}")
                break
            seen.add(key)
            for column, kind in enumerate(binary.types):
                cell = body[index][column]
                if kind == dbc.INT:
                    expect = str(binary.integer(index, column))
                    if cell != expect:
                        mismatches += 1
                        if mismatches <= 8:
                            print(f"{source}:{index}:{column} int tsv {cell!r} dbc {expect!r}")
                elif kind == dbc.FLOAT:
                    bits = binary.raw(index, column)
                    try:
                        packed = struct.unpack("<I", struct.pack("<f", float(cell)))[0]
                    except ValueError:
                        packed = None
                    if packed != bits:
                        mismatches += 1
                        if mismatches <= 8:
                            print(f"{source}:{index}:{column} float tsv {cell!r} bits {bits}")
                else:
                    if cell != binary.text(index, column):
                        mismatches += 1
                        if mismatches <= 8:
                            print(f"{source}:{index}:{column} chuỗi lệch")
        if binary.rows and binary.columns:
            sample_pool.append((source, binary.rows, binary.columns))
    print(f"bảng {tables}, bản ghi {records}, lệch {mismatches}")
    picker = random.Random(SEED)
    print(f"mẫu hạt {SEED}:")
    picks = picker.sample(sample_pool, k=min(12, len(sample_pool)))
    for source, row_count, column_count in picks:
        binary = dbc.read(str(RAW / "Config" / source), source)
        target = next(item[1] for item in targets if item[0] == source)
        _meta, _types, _header, body, _problems = load_tsv(TABLES / target[len("tables/") :])
        row = picker.randrange(row_count)
        column = picker.randrange(column_count)
        kind = binary.types[column]
        if kind == dbc.INT:
            expect = str(binary.integer(row, column))
        elif kind == dbc.FLOAT:
            expect = str(binary.raw(row, column))
            got_bits = struct.unpack("<I", struct.pack("<f", float(body[row][column])))[0]
            same = got_bits == binary.raw(row, column)
            print(f"  {source} dòng {row} cột {column} bits dbc {expect} bits tsv {got_bits} khớp {same}")
            continue
        else:
            expect = binary.text(row, column)
        same = body[row][column] == expect
        print(f"  {source} dòng {row} cột {column} khớp {same}")


def section_legacy() -> None:
    print("== bảng chữ máy chủ so với bộ đọc gốc ==")
    rows = read_names()
    groups: dict[str, list[list[str]]] = {}
    order: list[str] = []
    for row in rows:
        if row[6] != "B" or row[2] != "table":
            continue
        if row[3] not in groups:
            order.append(row[3])
            groups[row[3]] = []
        groups[row[3]].append(row)
    mismatches = 0
    compared = 0
    max_line = 0
    for target in order:
        group = groups[target]
        source_name = group[0][1]
        if not source_name.endswith(".txt") or source_name.startswith("RandShop/") or source_name == "MountFlightMaps.txt":
            continue
        kinds: list[str] | None = None
        expect: list[list[str]] = []
        for row in group:
            folder = "Server/Config" if row[0] == "server_config" else "Public/Config"
            path = LEGACY / folder / row[1]
            file_kinds, body, longest = read_text_server(path)
            if longest > max_line:
                max_line = longest
            if kinds is None:
                kinds = file_kinds
            elif file_kinds != kinds:
                mismatches += 1
                print(f"khác kiểu {row[1]}")
                continue
            prefix = [row[5]] if row[4] else []
            for record in body:
                written = []
                for kind, cell in zip(kinds, record, strict=True):
                    if kind == "INT":
                        number = c_atoi(cell)
                        written.append("" if number is None else str(number))
                        if number is None:
                            mismatches += 1
                            print(f"tràn {row[1]} {cell!r}")
                    else:
                        written.append(cell)
                expect.append(prefix + written)
        destination = ROOT / "dev" / "server" / target
        _meta, _types, header, got, _problems = load_tsv(destination)
        compared += 1
        width = len(expect[0]) if expect else len(header)
        if len(got) != len(expect):
            mismatches += 1
            print(f"lệch số dòng {target}: tsv {len(got)} gốc {len(expect)}")
            continue
        for index, (left, right) in enumerate(zip(expect, got, strict=True)):
            if right[:width] != left:
                mismatches += 1
                if mismatches <= 10:
                    print(f"{target} dòng {index} lệch")
                    print(f"  gốc {left[:6]}")
                    print(f"  tsv  {right[:6]}")
                break
    print(f"bảng chữ đã so {compared}, lệch {mismatches}, dòng dài nhất {max_line} byte")


def section_scene_info() -> None:
    print("== SceneInfo.ini so với scenes.tsv ==")
    path = LEGACY / "Server" / "Config" / "SceneInfo.ini"
    sections: dict[str, dict[str, str]] = {}
    order: list[str] = []
    current = ""
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("[") and "]" in stripped:
            current = stripped[1 : stripped.index("]")]
            sections[current] = {}
            order.append(current)
            continue
        if current == "" or "=" not in line or line.lstrip().startswith(";"):
            continue
        key, raw = line.split("=", 1)
        if key not in sections[current]:
            sections[current][key] = read_text_cut(raw)
    found = []
    for name in order:
        if name.startswith("scene") and name[len("scene") :].isdigit():
            found.append((int(name[len("scene") :]), sections[name]))
    found.sort()
    _meta, _types, header, rows, _problems = load_tsv(TABLES / "server" / "scenes.tsv")
    index = {name: position for position, name in enumerate(header)}
    mismatches = 0
    if len(rows) != len(found):
        print(f"số dòng tsv {len(rows)} section {len(found)}")
        mismatches += 1
    for (number, values), row in zip(found, rows, strict=False):
        pairs = {
            "scene_id": str(number),
            "name": values.get("name", ""),
            "file": values.get("file", ""),
            "clientres": values.get("clientres", ""),
            "type": str(c_atoi(values.get("type", "")) or 0),
        }
        for key, expect in pairs.items():
            if row[index[key]] != expect:
                mismatches += 1
                if mismatches <= 6:
                    print(f"scene{number} {key}: tsv {row[index[key]]!r} gốc {expect!r}")
    declared = sections.get("system", {}).get("scenenumber", "")
    print(f"section {len(found)}, scenenumber {declared!r}, lệch {mismatches}")


def section_nav() -> None:
    print("== nav ==")
    bad = 0
    source_hash: dict[str, str] = {}
    for path in sorted(SCENE.glob("*.nav")):
        data = path.read_bytes()
        if len(data) < 4:
            bad += 1
            print(f"cụt {path.name}")
            continue
        width, height = struct.unpack_from("<HH", data, 0)
        expect = 4 + width * height * 4
        if expect != len(data):
            bad += 1
            print(f"lệch cỡ {path.name}: đầu {width}x{height} có {len(data)} cần {expect}")
        source_hash[hashlib.sha256(data).hexdigest()] = path.name
    copies = 0
    unknown = 0
    for path in SCENES.glob("*/walk.nav"):
        copies += 1
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest not in source_hash:
            unknown += 1
            print(f"walk.nav không khớp nav gốc: {path.parent.name}")
    luoyang = (SCENES / "luoyang" / "walk.nav").read_bytes()
    width, height = struct.unpack_from("<HH", luoyang, 0)
    print(f"nav gốc {len(source_hash)} hash, lệch cỡ {bad}, bản chép {copies}, bản lạ {unknown}")
    print(f"luoyang {len(luoyang)} byte, đầu {width}x{height}")


def section_counts() -> None:
    print("== số dòng quái và ô int không chuẩn ==")
    count_bad = 0
    checked = 0
    odd_total = 0
    odd_cells = []
    for folder in sorted(path for path in SCENES.iterdir() if path.is_dir()):
        for path in sorted(folder.glob("*.tsv")):
            meta, types, header, rows, _problems = load_tsv(path)
            for column, kind in enumerate(types):
                if kind != "int":
                    continue
                for row_index, row in enumerate(rows):
                    if row[column] != "" and not canonical_int(row[column]):
                        odd_total += 1
                        if len(odd_cells) < 15:
                            odd_cells.append(f"{folder.name}/{path.name}:{row_index}:{header[column]}={row[column]!r}")
            source = meta.get("source", "")
            monster_name = source.split(" + ", 1)[0]
            if not monster_name.endswith("_monster.ini") and "_monster" not in Path(monster_name).name:
                continue
            if not path.name.startswith("spawns"):
                continue
            monster = SCENE / Path(monster_name).name
            if not monster.is_file():
                continue
            declared = _monstercount(monster)
            if declared is None:
                continue
            checked += 1
            if declared != len(rows):
                count_bad += 1
                if count_bad <= 8:
                    print(f"{monster.name}: khai {declared} dòng tsv {len(rows)} tệp {path.name}")
    print(f"bảng quái đã so số dòng {checked}, lệch {count_bad}, ô int không chuẩn {odd_total}")
    for line in odd_cells:
        print(f"  {line}")


def _monstercount(path: Path) -> int | None:
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.lower().startswith("monstercount="):
            text = read_text_cut(line.split("=", 1)[1]).strip()
            if text.isdigit():
                return int(text)
            return None
    return None


def section_orphan() -> None:
    print("== cảnh không có scn ==")
    found = []
    for path in sorted(SCENES.glob("*/scene.toml")):
        text = path.read_text(encoding="utf-8")
        if "scene_file" in text and "= 0" in text.split("scene_file", 1)[1][:40]:
            found.append(path.parent.name)
    print(f"số cảnh scene_file = 0: {len(found)}")
    for name in found:
        print(f"  {name}")


def section_grid() -> None:
    print("== cột mã không đọc ở bảng lưới ==")
    path = LEGACY / "Public" / "Config" / "MonsterAITable.ini"
    raw_tail = []
    current = ""
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            current = stripped[1:-1]
            continue
        if not current.startswith("AI"):
            continue
        if line.startswith("AIPARAM9=") or line.startswith("AIPARAM10="):
            raw_tail.append((current, line.split("=", 1)[0], read_text_cut(line.split("=", 1)[1])))
    _meta, _types, header, rows, _problems = load_tsv(TABLES / "server" / "monster_ai_types.tsv")
    index = {name: position for position, name in enumerate(header)}
    mismatches = 0
    for section, key, raw in raw_tail:
        number = int(section[2:])
        column = key.lower()
        cell = rows[number][index[column]]
        number_text = c_atoi(raw)
        expect = "" if number_text is None else str(number_text)
        if cell != expect or cell != raw:
            mismatches += 1
            if mismatches <= 6:
                print(f"{section} {key}: gốc {raw!r} atoi {expect!r} tsv {cell!r}")
    print(f"ô AIPARAM9/10 {len(raw_tail)}, lệch hoặc khác nguyên văn {mismatches}")


def section_script() -> None:
    print("== Script.dat và AIScript.dat ==")
    for source, target in (("Script.dat", "script_index.tsv"), ("AIScript.dat", "monster_ai_scripts.tsv")):
        data = (LEGACY / "Public" / "Data" / source).read_bytes()
        text = data[7:-1].decode("utf-8")
        filtered = []
        index = 0
        while index < len(text):
            if text[index] == ";":
                while index < len(text) and text[index] != "\n":
                    index += 1
                continue
            filtered.append(text[index])
            index += 1
        buffer = "".join(filtered)
        expect = []
        index = 0
        size = len(buffer)
        while index < size:
            if buffer[index].isdigit():
                start = index
                while index < size and buffer[index] not in "=\n":
                    index += 1
                if index >= size or buffer[index] != "=":
                    continue
                id_text = buffer[start:index]
                index += 1
                while index < size and buffer[index] in " \t":
                    index += 1
                name_start = index
                while index < size and buffer[index] not in " \t\r\n":
                    index += 1
                filename = buffer[name_start:index].replace("\\", "/")
                while index < size and buffer[index] != "\n":
                    index += 1
                number = c_atoi(id_text)
                expect.append((str(number), filename))
                continue
            index += 1
        _meta, _types, _header, rows, _problems = load_tsv(TABLES / "server" / target)
        got = [(row[0], row[1]) for row in rows]
        print(f"{source}: gốc {len(expect)} tsv {len(got)} khớp {got == expect}")


def section_account() -> None:
    print("== Account.txt ==")
    hits = []
    roots = [TABLES, SCENES, ROOT / "docs" / "giao-viec" / "P1-DOT-1"]
    for folder in roots:
        for path in folder.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix.lower() not in {".tsv", ".toml", ".md", ".txt"}:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeError:
                continue
            if "Account.txt" in text or "account.txt" in text.casefold():
                hits.append(path.relative_to(ROOT).as_posix())
    print(f"tệp nhắc tên Account.txt: {len(hits)}")
    for name in hits:
        print(f"  {name}")


def main() -> None:
    section_coverage()
    section_contract()
    section_level()
    section_scene_info()
    section_grid()
    section_script()
    section_nav()
    section_counts()
    section_orphan()
    section_account()
    section_legacy()
    section_dbc()


if __name__ == "__main__":
    main()
