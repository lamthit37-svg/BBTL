"""Đổi bảng chữ và ini của bản 0859602 thành TSV máy chủ.

  python TOOLS/server/import_legacy.py <thư mục tlbb> <thư mục bảng>
  python TOOLS/server/import_legacy.py <thư mục tlbb> <thư mục bảng> --check

Bảng chữ theo OpenFromMemoryImpl_Text: dòng kiểu, dòng tên, rồi bản ghi. INT đi qua
atoi và ghi dạng chính tắc; FLOAT bỏ khoảng trắng hai đầu, chữ số giữ nguyên.
STRING giữ nguyên văn. Dòng bắt đầu bằng # và ô đầu rỗng bị bỏ; dòng
thiếu ô được đệm. Token kiểu rỗng bị bỏ, không thành cột. Ô nằm sau số token còn lại
được đếm. Ini theo Ini.cpp: dòng `#khoá=giá trị` là khoá, không phải chú thích.
Dòng trong section mà không có dấu bằng là lỗi. Khoá mã 2008 không đọc vẫn xuất.

--check kiểm hết và không ghi tệp nào. Thoát 0 khi sạch, 1 khi có lỗi.
"""
from __future__ import annotations

import re
import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path

import column_names
import tsv_file

TOOL = "import_legacy.py"
KEEP_TABLE_TOOLS = ("scene_refs.py",)
LINE_LIMIT = 10239
NUMBER_TEXT = re.compile(r"^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$")
HELP = """\
cách dùng: python TOOLS/server/import_legacy.py <thư mục tlbb> <thư mục bảng> [--check]

Đọc bảng chữ và ini của bản 0859602, ghi TSV vào thư mục bảng và tệp cột vào
TOOLS/server/columns/server. --check kiểm hết và không ghi tệp nào.
Thoát 0 khi sạch, 1 khi có lỗi. Mỗi lỗi một dòng tệp:dòng: nội dung.
"""
CHANGE_LABELS = (
    ("int_cells", "int khác nguyên văn"),
    ("float_strip", "float bỏ khoảng trắng"),
    ("pad_cells", "ô đệm"),
    ("dropped_comment", "dòng bỏ vì #"),
    ("dropped_empty_id", "dòng bỏ vì ô đầu rỗng"),
    ("dropped_blank", "dòng bỏ vì trống"),
    ("empty_extra", "ô thừa rỗng bỏ"),
    ("ini_cut", "cắt chú thích ini"),
    ("slash_cells", "đổi gạch chéo"),
    ("space_cut", "cắt tại dấu cách"),
    ("beyond_declared", "dòng ngoài số khai báo"),
    ("dropped_script", "dòng script bỏ"),
    ("unread_after_type", "ô sau kiểu bị bỏ"),
)
TYPE_MAP = {"INT": "int", "FLOAT": "float", "STRING": "text"}
_DROP_CODE_INDEXES = (2, 4, 200, 202)
_DROP_CODE_NOTE = "mã InitDropBoxTable bắt đầu ở cột 2, 100 cặp; item_100_id nằm ngoài vòng"
TREE_DIR = {
    "server_config": "Server/Config",
    "public_config": "Public/Config",
    "public_data": "Public/Data",
}


class LegacyError(Exception):
    """Lỗi có vị trí tệp:dòng: nội dung."""


@dataclass
class BuiltTable:
    filename: str
    source: str
    columns: tuple[str, ...]
    types: tuple[str, ...]
    rows: tuple[tuple[str, ...], ...]
    originals: tuple[str, ...]
    notes: tuple[str, ...]
    changes: dict[str, int] = field(default_factory=dict)


@dataclass
class RawRow:
    line: int
    cells: list[str]


@dataclass
class Section:
    line: int
    values: dict[str, tuple[int, str, str]]


@dataclass
class IniFile:
    sections: dict[str, Section]
    order: list[str]


def _fail(location: str, line: int, message: str) -> LegacyError:
    return LegacyError(f"{location}:{line}: {message}")


def _snake(name: str) -> str:
    return column_names.snake(name)


def _named_columns(originals: list[str], source: str) -> tuple[list[str], list[str]]:
    try:
        return column_names.named_columns(originals, Path(source).name)
    except ValueError as exc:
        raise LegacyError(str(exc)) from exc


def _c_atoi(cell: str) -> int | None:
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


def _float_bits(cell: str) -> int:
    index = 0
    size = len(cell)
    while index < size and cell[index] in " \t\n\v\f\r":
        index += 1
    match = re.match(r"[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?", cell[index:])
    value = float(match.group(0)) if match else 0.0
    return struct.unpack("<I", struct.pack("<f", value))[0]


def _read_bytes(path: Path, location: str) -> bytes:
    if not path.is_file():
        raise _fail(location, 1, "không thấy tệp")
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise _fail(location, 1, "có BOM")
    if len(data) >= 4 and data[:4] == b"\x00\xcc\xbb\xdd":
        raise _fail(location, 1, "sai magic")
    if b"\x00" in data:
        raise _fail(location, 1, "gặp byte 0")
    return data


def _decode(data: bytes, location: str) -> str:
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise _fail(location, 1, "byte UTF-8 hỏng") from exc


def _logical_lines(text: str, location: str) -> list[tuple[int, str]]:
    lines = []
    for number, line in enumerate(text.splitlines(), start=1):
        if len(line.encode("utf-8")) > LINE_LIMIT:
            raise _fail(location, number, "dòng dài hơn bộ đệm 10239 byte")
        lines.append((number, line))
    return lines


def _index_key(cell: str, kind: str) -> str:
    if kind == "int":
        number = _c_atoi(cell)
        return "" if number is None else str(number)
    if kind == "float":
        return str(_float_bits(cell))
    return cell


def _convert_cell(cell: str, kind: str, location: str, line: int) -> tuple[str, bool]:
    if kind == "float":
        stripped = cell.strip()
        return stripped, stripped != cell
    if kind != "int":
        return cell, False
    number = _c_atoi(cell)
    if number is None:
        raise _fail(location, line, "số vượt int32")
    written = str(number)
    return written, written != cell


def _middle_types(raw_types: list[str]) -> list[str] | None:
    """Token kiểu rỗng xen giữa: bộ đọc gốc bỏ token rỗng, chỉ còn danh sách đặc."""
    last = -1
    for index, cell in enumerate(raw_types):
        if cell != "":
            last = index
    if last < 0:
        return None
    if not any(raw_types[index] == "" for index in range(last)):
        return None
    return [cell for cell in raw_types if cell != ""]


def _rows_of_width(location: str, lines: list[tuple[int, str]], width: int, changes: dict[str, int]) -> list[RawRow]:
    rows: list[RawRow] = []
    for number, line in lines:
        if line == "":
            changes["dropped_blank"] = changes.get("dropped_blank", 0) + 1
            continue
        if line.startswith("#"):
            changes["dropped_comment"] = changes.get("dropped_comment", 0) + 1
            continue
        cells = line.split("\t")
        if cells[0] == "":
            changes["dropped_empty_id"] = changes.get("dropped_empty_id", 0) + 1
            continue
        if len(cells) > width:
            for cell in cells[width:]:
                key = "empty_extra" if cell == "" else "unread_after_type"
                changes[key] = changes.get(key, 0) + 1
        rows.append(RawRow(number, cells[:width]))
    return rows


def _trim_declared(raw_types: list[str], location: str) -> list[str]:
    declared = list(raw_types)
    while declared and declared[-1] == "":
        declared.pop()
    if any(cell == "" for cell in declared):
        raise _fail(location, 1, "ô kiểu rỗng xen giữa")
    if not declared:
        raise _fail(location, 1, "tệp cụt")
    for kind in declared:
        if kind not in TYPE_MAP:
            raise _fail(location, 1, f"kiểu cột không hợp lệ: {kind}")
    return declared


def _reject_extra_names(names: list[str], raw_types: list[str], location: str) -> None:
    if len(names) <= len(raw_types):
        return
    for index in range(len(raw_types), len(names)):
        if names[index] != "":
            raise _fail(location, 2, "tên cột thừa")


def _text_rows(lines: list[tuple[int, str]], changes: dict[str, int]) -> list[RawRow]:
    rows: list[RawRow] = []
    for number, line in lines:
        if line == "":
            changes["dropped_blank"] = changes.get("dropped_blank", 0) + 1
            continue
        if line.startswith("#"):
            changes["dropped_comment"] = changes.get("dropped_comment", 0) + 1
            continue
        cells = line.split("\t")
        if cells[0] == "":
            changes["dropped_empty_id"] = changes.get("dropped_empty_id", 0) + 1
            continue
        rows.append(RawRow(number, cells))
    return rows


def _tail_cell(location: str, row: RawRow, index: int, raw_width: int, changes: dict[str, int]) -> None:
    cell = row.cells[index]
    if index >= raw_width and cell != "":
        raise _fail(location, row.line, "dòng thừa ô")
    if cell == "":
        changes["empty_extra"] = changes.get("empty_extra", 0) + 1
        return
    changes["unread_after_type"] = changes.get("unread_after_type", 0) + 1


def _count_tail(rows: list[RawRow], width: int, raw_width: int, location: str, changes: dict[str, int]) -> None:
    """Token kiểu đã bị cắt ở đuôi. Ô phía sau không thành cột."""
    for row in rows:
        if len(row.cells) <= width:
            continue
        for index in range(width, len(row.cells)):
            _tail_cell(location, row, index, raw_width, changes)


def _cell_text(row: RawRow, index: int, kind: str, width: int, location: str, changes: dict[str, int]) -> str:
    if index >= width:
        if index < len(row.cells):
            return row.cells[index]
        return ""
    existed = index < len(row.cells)
    cell = row.cells[index] if existed else ""
    text, changed = _convert_cell(cell, kind, location, row.line)
    if existed and changed and kind == "int":
        changes["int_cells"] = changes.get("int_cells", 0) + 1
    if existed and changed and kind == "float":
        changes["float_strip"] = changes.get("float_strip", 0) + 1
    return text


def _written_row(row: RawRow, kinds: list[str], width: int, location: str, changes: dict[str, int]) -> tuple[str, ...]:
    if len(row.cells) < width:
        changes["pad_cells"] = changes.get("pad_cells", 0) + (width - len(row.cells))
    written: list[str] = []
    for index, kind in enumerate(kinds):
        written.append(_cell_text(row, index, kind, width, location, changes))
    return tuple(written)


def _body_rows(
    rows: list[RawRow],
    kinds: list[str],
    width: int,
    location: str,
    changes: dict[str, int],
) -> list[tuple[str, ...]]:
    seen: dict[str, int] = {}
    body: list[tuple[str, ...]] = []
    id_kind = kinds[0]
    for row in rows:
        written = _written_row(row, kinds, width, location, changes)
        key = _index_key(written[0], id_kind)
        if key in seen:
            raise _fail(location, row.line, f"id trùng {written[0]}")
        seen[key] = row.line
        body.append(written)
    return body


def _parse_text(path: Path, location: str, source: str, filename: str) -> BuiltTable:
    data = _read_bytes(path, location)
    lines = _logical_lines(_decode(data, location), location)
    if len(lines) < 2:
        raise _fail(location, 1, "tệp cụt")
    raw_types = lines[0][1].split("\t")
    names = lines[1][1].split("\t")
    shifted = _middle_types(raw_types)
    if shifted is not None:
        return _parse_shifted(location, source, filename, lines[2:], shifted, names)
    declared = _trim_declared(raw_types, location)
    _reject_extra_names(names, raw_types, location)
    changes: dict[str, int] = {}
    rows = _text_rows(lines[2:], changes)
    width = len(declared)
    _count_tail(rows, width, len(raw_types), location, changes)
    kinds = [TYPE_MAP[kind] for kind in declared]
    originals = [names[index] if index < len(names) else "" for index in range(width)]
    columns, notes = _named_columns(originals, source)
    notes = _annotate_drop_code(source, notes)
    body = _body_rows(rows, kinds, width, location, changes)
    return BuiltTable(
        filename,
        source,
        tuple(columns),
        tuple(kinds),
        tuple(body),
        tuple(originals),
        tuple(notes),
        changes,
    )


def _attach_drop_note(notes: list[str], index: int) -> None:
    if index >= len(notes):
        return
    notes[index] = f"{notes[index]}; {_DROP_CODE_NOTE}"


def _annotate_drop_code(source: str, notes: list[str]) -> list[str]:
    """Ghi chỉ số cột mà InitDropBoxTable đọc. Không đổi tên nhãn của tệp."""
    if Path(source).name != "DropBoxContent.txt":
        return notes
    updated = list(notes)
    for index in _DROP_CODE_INDEXES:
        _attach_drop_note(updated, index)
    return updated


def _parse_shifted(
    location: str,
    source: str,
    filename: str,
    lines: list[tuple[int, str]],
    type_tokens: list[str],
    names: list[str],
) -> BuiltTable:
    """Kiểu rỗng xen giữa: N token còn lại ăn đúng N ô đầu của mỗi dòng dữ liệu."""
    for kind in type_tokens:
        if kind not in TYPE_MAP:
            raise _fail(location, 1, f"kiểu cột không hợp lệ: {kind}")
    width = len(type_tokens)
    changes: dict[str, int] = {}
    rows = _rows_of_width(location, lines, width, changes)
    kinds = [TYPE_MAP[kind] for kind in type_tokens]
    originals = [names[index] if index < len(names) else "" for index in range(width)]
    columns, notes = _named_columns(originals, source)
    notes = _annotate_drop_code(source, notes)
    body = _body_rows(rows, kinds, width, location, changes)
    return BuiltTable(
        filename,
        source,
        tuple(columns),
        tuple(kinds),
        tuple(body),
        tuple(originals),
        tuple(notes),
        changes,
    )


def _read_ini_value(raw: str) -> tuple[str, bool]:
    for index, char in enumerate(raw):
        if char not in ";\t]":
            continue
        if char == "\t":
            tail = raw[index + 1 :].strip()
            if tail and not tail.startswith(";"):
                return raw[:index], True
        return raw[:index], False
    return raw, False


def _ini_noise(line: str) -> bool:
    """Dòng trống hoặc chú thích. Ini.cpp không bỏ dòng #khoá=giá trị."""
    stripped = line.strip()
    if stripped == "" or stripped.startswith(";"):
        return True
    return stripped.startswith("#") and "=" not in stripped


def _read_key(line: str) -> tuple[str, str | None]:
    for index, char in enumerate(line):
        if char in ";=":
            key = line[:index]
            if char == ";":
                return key, None
            return key, line[index + 1 :]
    return line, None


def _parse_ini(path: Path, location: str) -> IniFile:
    text = _decode(_read_bytes(path, location), location)
    sections: dict[str, Section] = {}
    order: list[str] = []
    current: Section | None = None
    for number, line in _logical_lines(text, location):
        if line.startswith("[") and "]" in line:
            name, bad_tab = _read_ini_value(line[1:])
            if bad_tab:
                raise _fail(location, number, "ô chứa tab")
            if not name:
                raise _fail(location, number, "section rỗng")
            if name in sections:
                raise _fail(location, number, f"section trùng {name}")
            current = Section(number, {})
            sections[name] = current
            order.append(name)
            continue
        if current is None:
            if _ini_noise(line):
                continue
            raise _fail(location, number, "dòng lạ trước section")
        key, raw = _read_key(line)
        if _ini_noise(line):
            continue
        if raw is None:
            raise _fail(location, number, "dòng không có dấu bằng")
        if key.strip() == "":
            raise _fail(location, number, "khoá rỗng")
        if len(key) >= 64:
            raise _fail(location, number, "tên khoá dài hơn bộ đệm 64")
        value, bad_tab = _read_ini_value(raw)
        if bad_tab:
            raise _fail(location, number, "ô chứa tab")
        if key in current.values:
            raise _fail(location, number, f"khoá trùng {key}")
        current.values[key] = (number, raw, value)
    return IniFile(sections, order)


def _check_keys(section: Section, allowed: set[str], location: str) -> None:
    for key, (number, _raw, _value) in section.values.items():
        if key not in allowed:
            raise _fail(location, number, f"khoá lạ {key}")


def _as_int(raw: str, value: str, changes: dict[str, int], location: str, line: int) -> str:
    if raw != value:
        changes["ini_cut"] = changes.get("ini_cut", 0) + 1
    number = _c_atoi(value)
    if number is None:
        raise _fail(location, line, "số vượt int32")
    written = str(number)
    if written != value:
        changes["int_cells"] = changes.get("int_cells", 0) + 1
    return written


def _as_text(raw: str, value: str, changes: dict[str, int]) -> str:
    if raw != value:
        changes["ini_cut"] = changes.get("ini_cut", 0) + 1
    return value


def _field(section: Section, key: str, location: str, changes: dict[str, int], mode: str) -> str:
    if key not in section.values:
        if mode.startswith("optional"):
            return ""
        raise _fail(location, section.line, f"thiếu khoá {key}")
    number, raw, value = section.values[key]
    if mode.endswith("int"):
        return _as_int(raw, value, changes, location, number)
    return _as_text(raw, value, changes)


def _numbered(ini: IniFile, prefix: str) -> list[tuple[int, Section]]:
    found = []
    for name in ini.order:
        if not name.startswith(prefix):
            continue
        suffix = name[len(prefix) :]
        if not suffix.isdigit():
            continue
        found.append((int(suffix), ini.sections[name]))
    found.sort(key=lambda item: item[0])
    return found


def _contiguous(found: list[tuple[int, Section]], location: str, label: str) -> None:
    if not found:
        return
    numbers = [number for number, _section in found]
    missing = [value for value in range(numbers[-1] + 1) if value not in set(numbers)]
    if missing:
        raise _fail(location, found[0][1].line, f"thiếu {label}{missing[0]}")


def _table(
    filename: str,
    source: str,
    columns: list[str],
    types: list[str],
    rows: list[tuple[str, ...]],
    originals: list[str],
    notes: list[str],
    changes: dict[str, int],
) -> BuiltTable:
    return BuiltTable(
        filename,
        source,
        tuple(columns),
        tuple(types),
        tuple(rows),
        tuple(originals),
        tuple(notes),
        changes,
    )


def _scene_allowed() -> set[str]:
    return {
        "threadindex",
        "clientres",
        "name",
        "active",
        "file",
        "serverid",
        "type",
        "PvpRuler",
        "IsReLive",
        "BeginPlus",
        "EndPlus",
        "_clientres",
    }


def _within(number: int, declared: int) -> str:
    if number < declared:
        return "1"
    return "0"


def _scene_row(
    number: int, section: Section, location: str, changes: dict[str, int], declared: int
) -> tuple[str, ...]:
    fields = (
        ("clientres", "optional-text"),
        ("name", "text"),
        ("file", "text"),
        ("type", "int"),
        ("PvpRuler", "optional-text"),
        ("IsReLive", "optional-text"),
        ("BeginPlus", "optional-text"),
        ("EndPlus", "optional-text"),
        ("_clientres", "optional-text"),
    )
    values = [str(number)]
    for key, mode in fields:
        values.append(_field(section, key, location, changes, mode))
    values.append(_within(number, declared))
    return tuple(values)


def _host_row(
    number: int, section: Section, location: str, changes: dict[str, int], declared: int
) -> tuple[str, ...]:
    return (
        str(number),
        _field(section, "active", location, changes, "int"),
        _field(section, "serverid", location, changes, "int"),
        _field(section, "threadindex", location, changes, "int"),
        _within(number, declared),
    )


def _scene_label_name(original: str) -> str:
    """Tên M1 của một khoá SceneInfo. Mọi khoá trong bố cục này đều đặt được."""
    name, _uncertain = column_names.english_name(original)
    if name is None:
        raise ValueError(f"nhãn cảnh không đặt được tên: {original}")
    return name


def _scene_column_names(originals: list[str]) -> list[str]:
    """Cột không nhãn giữ tên cố định. Hai khoá cùng ra clientres thì đánh số từ 1."""
    fixed = ("scene_id", "within_declared_count")
    raw: list[str] = []
    fixed_at = 0
    for original in originals:
        if original == "":
            raw.append(fixed[fixed_at])
            fixed_at += 1
            continue
        raw.append(_scene_label_name(original))
    named, _clashes = column_names.number_repeated(raw)
    return named


def _scene_layout() -> tuple[list[str], list[str], list[str], list[str]]:
    types = ["int", "text", "text", "text", "int", "text", "text", "text", "text", "text", "int"]
    originals = [
        "",
        "clientres",
        "name",
        "file",
        "type",
        "PvpRuler",
        "IsReLive",
        "BeginPlus",
        "EndPlus",
        "_clientres",
        "",
    ]
    notes = [
        "chỉ số section sceneN, mã 2008 gán m_SceneID = i",
        "mã 2008 không đọc khoá này",
        "",
        "",
        "",
        "mã 2008 không đọc khoá này",
        "mã 2008 không đọc khoá này",
        "mã 2008 không đọc khoá này",
        "mã 2008 không đọc khoá này",
        "luật: M1",
        "1 khi chỉ số scene nhỏ hơn scenenumber",
    ]
    return _scene_column_names(originals), types, originals, notes


def _host_layout() -> tuple[list[str], list[str], list[str], list[str]]:
    columns = ["scene_id", "active", "serverid", "threadindex", "within_declared_count"]
    types = ["int", "int", "int", "int", "int"]
    originals = ["", "active", "serverid", "threadindex", ""]
    notes = [
        "chỉ số section sceneN",
        "",
        "tệp ghi serverid, mã 2008 đọc serverId",
        "",
        "1 khi chỉ số scene nhỏ hơn scenenumber",
    ]
    return columns, types, originals, notes


def _parse_scene(path: Path, location: str, source: str, filename: str) -> BuiltTable:
    ini = _parse_ini(path, location)
    if "system" not in ini.sections:
        raise _fail(location, 1, "thiếu section system")
    system = ini.sections["system"]
    _check_keys(system, {"scenenumber"}, location)
    count_changes: dict[str, int] = {}
    declared = int(_field(system, "scenenumber", location, count_changes, "int"))
    found = _numbered(ini, "scene")
    _contiguous(found, location, "scene")
    allowed = _scene_allowed()
    for _number, section in found:
        _check_keys(section, allowed, location)
    if declared > len(found):
        raise _fail(location, system.line, "thiếu scene theo scenenumber")
    scene_changes = dict(count_changes)
    host_changes: dict[str, int] = {}
    if len(found) > declared:
        extra = len(found) - declared
        scene_changes["beyond_declared"] = extra
        host_changes["beyond_declared"] = extra
    scene_rows: list[tuple[str, ...]] = []
    host_rows: list[tuple[str, ...]] = []
    for number, section in found:
        scene_rows.append(_scene_row(number, section, location, scene_changes, declared))
        host_rows.append(_host_row(number, section, location, host_changes, declared))
    if filename == "scene_hosting.tsv":
        columns, types, originals, notes = _host_layout()
        return _table(filename, source, columns, types, host_rows, originals, notes, host_changes)
    columns, types, originals, notes = _scene_layout()
    return _table(filename, source, columns, types, scene_rows, originals, notes, scene_changes)


_EVENT_KEYS = (
    "opt_type",
    "time_type",
    "time_start",
    "time_end",
    "scene",
    "scriptid",
    "param0",
    "param1",
    "param2",
    "param3",
    "param4",
    "param5",
)


def _check_system_sections(
    broads: list[tuple[int, Section]],
    events: list[tuple[int, Section]],
    location: str,
) -> None:
    for _number, section in broads:
        _check_keys(section, {"contex"}, location)
    allowed = set(_EVENT_KEYS)
    for _number, section in events:
        _check_keys(section, allowed, location)


def _announcement_table(
    filename: str,
    source: str,
    location: str,
    info_line: int,
    broads: list[tuple[int, Section]],
    declared: int,
    changes: dict[str, int],
) -> BuiltTable:
    if declared > len(broads):
        raise _fail(location, info_line, "thiếu broad theo broadcount")
    if len(broads) > declared:
        changes["beyond_declared"] = len(broads) - declared
    rows: list[tuple[str, ...]] = []
    for number, section in broads:
        text = _field(section, "contex", location, changes, "text")
        rows.append((str(number), text, _within(number, declared)))
    columns = ["announcement_id", "contex", "within_declared_count"]
    types = ["int", "text", "int"]
    originals = ["", "contex", ""]
    notes = [
        "chỉ số section broadN",
        "mã 2008 không có hàm nạp",
        "1 khi chỉ số broad nhỏ hơn broadcount",
    ]
    return _table(filename, source, columns, types, rows, originals, notes, changes)


def _event_table(
    filename: str,
    source: str,
    location: str,
    info_line: int,
    events: list[tuple[int, Section]],
    declared: int,
    changes: dict[str, int],
) -> BuiltTable:
    if declared > len(events):
        raise _fail(location, info_line, "thiếu huodong theo huodongcount")
    if len(events) > declared:
        changes["beyond_declared"] = len(events) - declared
    rows: list[tuple[str, ...]] = []
    for number, section in events:
        values = [str(number)]
        for key in _EVENT_KEYS:
            values.append(_field(section, key, location, changes, "text"))
        values.append(_within(number, declared))
        rows.append(tuple(values))
    columns = ["event_id", *_EVENT_KEYS, "within_declared_count"]
    originals = ["", *_EVENT_KEYS, ""]
    notes = ["chỉ số section huodongN"]
    notes.extend(["mã 2008 không có hàm nạp"] * 12)
    notes.append("1 khi chỉ số huodong nhỏ hơn huodongcount")
    types = ["int"] + ["text"] * 12 + ["int"]
    return _table(filename, source, columns, types, rows, originals, notes, changes)


def _parse_system(path: Path, location: str, source: str, filename: str) -> BuiltTable:
    ini = _parse_ini(path, location)
    if "info" not in ini.sections:
        raise _fail(location, 1, "thiếu section info")
    info = ini.sections["info"]
    _check_keys(info, {"broadcount", "broadtime", "huodongcount"}, location)
    broad_info: dict[str, int] = {}
    event_info: dict[str, int] = {}
    broad_count = _field(info, "broadcount", location, broad_info, "text")
    _field(info, "broadtime", location, broad_info, "text")
    event_count = _field(info, "huodongcount", location, event_info, "text")
    broads = _numbered(ini, "broad")
    events = _numbered(ini, "huodong")
    _contiguous(broads, location, "broad")
    _contiguous(events, location, "huodong")
    _check_system_sections(broads, events, location)
    declared_broad = _c_atoi(broad_count)
    declared_event = _c_atoi(event_count)
    if declared_broad is None or declared_event is None:
        raise _fail(location, info.line, "số vượt int32")
    if filename == "rolling_announcements.tsv":
        copied = dict(broad_info)
        return _announcement_table(
            filename,
            source,
            location,
            info.line,
            broads,
            declared_broad,
            copied,
        )
    copied = dict(event_info)
    return _event_table(
        filename,
        source,
        location,
        info.line,
        events,
        declared_event,
        copied,
    )


@dataclass(frozen=True)
class _GridSpec:
    prefix: str
    count_section: str
    count_key: str
    fixed: int | None
    value_prefix: str
    value_count: int
    read_until: int
    id_name: str
    id_note: str


def _grid_spec(spec: str) -> _GridSpec:
    if spec == "base":
        return _GridSpec(
            "MENPAI",
            "",
            "",
            10,
            "AINFOTYPE",
            42,
            34,
            "sect_id",
            "chỉ số MENPAI, mã 2008 đọc 0 tới 9",
        )
    if spec == "monster":
        return _GridSpec("AI", "INFO", "AINUMBER", None, "AIPARAM", 11, 9, "ai_id", "chỉ số AI")
    return _GridSpec(
        "member_type",
        "info",
        "membertypecount",
        None,
        "access_type",
        23,
        8,
        "position_id",
        "chỉ số member_type",
    )


def _grid_header_count(ini: IniFile, layout: _GridSpec, location: str, changes: dict[str, int]) -> int | None:
    """Không có section đếm thì trả fixed, kể cả None, để caller vẫn đọc các section trước."""
    if not layout.count_section:
        return layout.fixed
    if layout.count_section not in ini.sections:
        raise _fail(location, 1, f"thiếu section {layout.count_section}")
    header = ini.sections[layout.count_section]
    _check_keys(header, {layout.count_key}, location)
    declared_text = _field(header, layout.count_key, location, changes, "int")
    return int(declared_text)


def _grid_rows(
    found: list[tuple[int, Section]],
    layout: _GridSpec,
    spec: str,
    location: str,
    changes: dict[str, int],
) -> list[tuple[str, ...]]:
    allowed = {f"{layout.value_prefix}{index}" for index in range(layout.value_count)}
    if spec == "monster":
        allowed.add("DESC")
    rows: list[tuple[str, ...]] = []
    for number, section in found:
        _check_keys(section, allowed, location)
        values = [str(number)]
        if spec == "monster":
            values.append(_field(section, "DESC", location, changes, "text"))
        for index in range(layout.value_count):
            mode = "int" if index < layout.read_until else "int"
            key = f"{layout.value_prefix}{index}"
            values.append(_field(section, key, location, changes, mode))
        rows.append(tuple(values))
    return rows


def _grid_columns(spec: str, layout: _GridSpec) -> tuple[list[str], list[str], list[str], list[str]]:
    columns = [layout.id_name]
    types = ["int"]
    originals = [""]
    notes = [layout.id_note]
    if spec == "monster":
        columns.append("desc")
        types.append("text")
        originals.append("DESC")
        notes.append("mã 2008 không đọc khoá này")
    for index in range(layout.value_count):
        columns.append(f"{layout.value_prefix.lower()}{index}")
        types.append("int")
        originals.append(f"{layout.value_prefix}{index}")
        if index < layout.read_until:
            notes.append("")
        else:
            notes.append("mã 2008 không đọc khoá này")
    return columns, types, originals, notes


def _grid(path: Path, location: str, source: str, filename: str, spec: str) -> BuiltTable:
    ini = _parse_ini(path, location)
    changes: dict[str, int] = {}
    layout = _grid_spec(spec)
    declared = _grid_header_count(ini, layout, location, changes)
    found = _numbered(ini, layout.prefix)
    _contiguous(found, location, layout.prefix)
    if declared is None:
        raise _fail(location, 1, "thiếu số lượng")
    if declared > len(found):
        raise _fail(location, 1, f"thiếu {layout.prefix} theo số khai báo")
    if len(found) > declared:
        changes["beyond_declared"] = len(found) - declared
    rows = _grid_rows(found, layout, spec, location, changes)
    columns, types, originals, notes = _grid_columns(spec, layout)
    return _table(filename, source, columns, types, rows, originals, notes, changes)


def _parse_shop_file(path: Path, location: str) -> tuple[list[tuple[str, ...]], dict[str, int]]:
    ini = _parse_ini(path, location)
    if "General" not in ini.sections:
        raise _fail(location, 1, "thiếu section General")
    general = ini.sections["General"]
    _check_keys(general, {"Total"}, location)
    changes: dict[str, int] = {}
    total = int(_field(general, "Total", location, changes, "int"))
    found = _numbered(ini, "Merchandise")
    _contiguous(found, location, "Merchandise")
    if len(found) < total or (found and found[0][0] != 0):
        raise _fail(location, general.line, "Total không khớp số section")
    if len(found) > total:
        changes["beyond_declared"] = len(found) - total
    allowed = {"ID", "Count", "CountPerUnit", "Odds", "odds", "Value", "Rebate"}
    rows = []
    for number, section in found:
        _check_keys(section, allowed, location)
        for key in ("ID", "Count", "CountPerUnit", "Value"):
            if key not in section.values:
                raise _fail(location, section.line, f"thiếu khoá {key}")
        values = [
            str(number),
            _field(section, "ID", location, changes, "text"),
            _field(section, "Count", location, changes, "text"),
            _field(section, "CountPerUnit", location, changes, "text"),
            _field(section, "Odds", location, changes, "optional-text"),
            _field(section, "odds", location, changes, "optional-text"),
            _field(section, "Value", location, changes, "text"),
            _field(section, "Rebate", location, changes, "optional-text"),
            _within(number, total),
        ]
        rows.append(tuple(values))
    return rows, changes


def _shop_columns() -> tuple[list[str], list[str], list[str], list[str]]:
    raw_names = [
        "shop_key",
        "merchandise_id",
        "id",
        "count",
        "count_per_unit",
        "odds",
        "odds",
        "value",
        "rebate",
        "within_declared_count",
    ]
    columns, _clashes = column_names.number_repeated(raw_names)
    types = ["text", "int", "text", "text", "text", "text", "text", "text", "text", "int"]
    originals = ["", "", "ID", "Count", "CountPerUnit", "Odds", "odds", "Value", "Rebate", ""]
    notes = [
        "cột gộp",
        "chỉ số MerchandiseN",
        "mã 2008 không có hàm nạp",
        "mã 2008 không có hàm nạp",
        "mã 2008 không có hàm nạp",
        "mã 2008 không có hàm nạp",
        "mã 2008 không có hàm nạp",
        "mã 2008 không có hàm nạp",
        "mã 2008 không có hàm nạp",
        "1 khi chỉ số Merchandise nhỏ hơn Total",
    ]
    return columns, types, originals, notes


def _parse_flight(path: Path, location: str, source: str, filename: str) -> BuiltTable:
    lines = _logical_lines(_decode(_read_bytes(path, location), location), location)
    if not lines or lines[0][1] != "MountFlightMaps\t1":
        raise _fail(location, 1, "dòng đầu không phải MountFlightMaps")
    rows = []
    seen: dict[str, int] = {}
    for number, line in lines[1:]:
        if line == "":
            continue
        cells = line.split("\t")
        if len(cells) != 5:
            raise _fail(location, number, "dòng thừa ô" if len(cells) > 5 else "thiếu ô")
        if cells[0] in seen:
            raise _fail(location, number, f"id trùng {cells[0]}")
        seen[cells[0]] = number
        rows.append(tuple(cells))
    columns = [f"column_{index}" for index in range(5)]
    notes = ["? không có tên cột; dòng đầu tệp là MountFlightMaps và 1"] + ["? không có tên cột"] * 4
    return _table(filename, source, columns, ["text"] * 5, rows, [""] * 5, notes, {})


def _merge_changes(parts: list[dict[str, int]]) -> dict[str, int]:
    total: dict[str, int] = {}
    for part in parts:
        for key, value in part.items():
            total[key] = total.get(key, 0) + value
    return total



def _script_tables(legacy: Path) -> list[BuiltTable]:
    specs = (
        ("Script.dat", "script_index.tsv", "script_id", "id script, atoi theo CFileDataMgr::Init"),
        ("AIScript.dat", "monster_ai_scripts.tsv", "ai_id", "id AI, atoi theo CFileDataMgr::Init"),
    )
    built = []
    for source_name, filename, id_column, id_note in specs:
        path = legacy / "Public" / "Data" / source_name
        location = f"Public/Data/{source_name}"
        rows, changes = _load_mgr(path, location)
        built.append(
            _table(
                filename,
                f"Public/Data/{source_name}",
                [id_column, "path"],
                ["int", "text"],
                rows,
                ["", ""],
                [id_note, "đường dẫn sau khi đổi gạch chéo và cắt tại dấu cách"],
                changes,
            )
        )
    return built


def _mgr_payload(path: Path, location: str) -> tuple[str, str]:
    data = path.read_bytes() if path.is_file() else b""
    if not path.is_file() or len(data) < 8 or data[:7] != b"MGR_TXT":
        raise _fail(location, 1, "sai magic, cần MGR_TXT")
    if data[-1:] not in (b"\n", b"\r"):
        raise _fail(location, 1, "byte cuối không phải xuống dòng")
    try:
        full_text = data.decode("utf-8")
        text = data[7:-1].decode("utf-8")
    except UnicodeDecodeError as exc:
        raise _fail(location, 1, "byte UTF-8 hỏng") from exc
    return full_text, text


def _dropped_script_lines(full_text: str) -> int:
    dropped = 0
    for line in full_text.splitlines()[1:]:
        head = line.lstrip(" \t")
        if head == "" or head.startswith(";") or not head[:1].isdigit():
            dropped += 1
    return dropped


def _strip_mgr_comments(text: str) -> str:
    """Bỏ chú thích từ dấu ; nhưng giữ ký tự xuống dòng ngay sau."""
    filtered: list[str] = []
    index = 0
    size = len(text)
    while index < size:
        if text[index] != ";":
            filtered.append(text[index])
            index += 1
            continue
        while index < size and text[index] != "\n":
            index += 1
    return "".join(filtered)


def _scan_mgr_id(buffer: str, index: int, line: int) -> tuple[int, int, bool]:
    """Tìm dấu = trên cùng dòng. Hai nhánh xuống dòng giữ đúng thứ tự của bộ đọc gốc."""
    size = len(buffer)
    while index < size:
        char = buffer[index]
        if char == "\n":
            line += 1
        if char == "=":
            index += 1
            while index < size and buffer[index] in " \t":
                index += 1
            return index, line, True
        if char == "\n":
            index += 1
            return index, line, False
        index += 1
    return index, line, False


def _read_mgr_filename(buffer: str, index: int) -> tuple[int, str, bool, bool]:
    size = len(buffer)
    name_start = index
    while index < size and buffer[index] not in " \t\r\n":
        index += 1
    raw_name = buffer[name_start:index]
    had_space = index < size and buffer[index] in " \t"
    while index < size and buffer[index] != "\n":
        index += 1
    had_slash = "\\" in raw_name
    return index, raw_name.replace("\\", "/"), had_space, had_slash


def _take_digit_record(
    buffer: str,
    index: int,
    line: int,
    location: str,
    rows: list[tuple[str, ...]],
    seen: dict[str, int],
    changes: dict[str, int],
) -> tuple[int, int]:
    start = index
    start_line = line
    index, line, succeeded = _scan_mgr_id(buffer, index, line)
    if not succeeded:
        return index, line
    index, filename, had_space, had_slash = _read_mgr_filename(buffer, index)
    id_text = buffer[start:buffer.find("=", start)]
    if len(filename) >= 128:
        raise _fail(location, start_line, "đường dẫn dài hơn 127 ký tự")
    number = _c_atoi(id_text)
    if number is None or number < 0:
        raise _fail(location, start_line, "số vượt int32")
    written = str(number)
    if written != id_text:
        changes["int_cells"] = changes.get("int_cells", 0) + 1
    if had_slash:
        changes["slash_cells"] = changes.get("slash_cells", 0) + 1
    if had_space:
        changes["space_cut"] = changes.get("space_cut", 0) + 1
    if written in seen:
        raise _fail(location, start_line, f"id trùng {written}")
    seen[written] = start_line
    rows.append((written, filename))
    return index, line


def _skip_mgr_gap(buffer: str, index: int, line: int) -> tuple[int, int]:
    if buffer[index] == "\n":
        return index + 1, line + 1
    if buffer[index] in " \t\r":
        return index + 1, line
    size = len(buffer)
    while index < size and buffer[index] != "\n":
        index += 1
    return index, line


def _load_mgr(path: Path, location: str) -> tuple[list[tuple[str, ...]], dict[str, int]]:
    full_text, text = _mgr_payload(path, location)
    dropped = _dropped_script_lines(full_text)
    buffer = _strip_mgr_comments(text)
    changes: dict[str, int] = {}
    if dropped:
        changes["dropped_script"] = dropped
    rows: list[tuple[str, ...]] = []
    seen: dict[str, int] = {}
    index = 0
    line = 1
    size = len(buffer)
    while index < size:
        if buffer[index].isdigit():
            index, line = _take_digit_record(buffer, index, line, location, rows, seen, changes)
            continue
        index, line = _skip_mgr_gap(buffer, index, line)
    return rows, changes


def _source_of(row: tsv_file.NameRow) -> str:
    return f"{row.tree}/{row.source}"


def _location_of(row: tsv_file.NameRow) -> str:
    return f"{TREE_DIR[row.tree]}/{row.source}"


def _path_of(legacy: Path, row: tsv_file.NameRow) -> Path:
    return legacy / TREE_DIR[row.tree] / row.source


def _kind(source: str) -> str:
    if source == "SceneInfo.ini":
        return "scene"
    if source == "SystemInfo.ini":
        return "system"
    if source == "BaseValueTable.ini":
        return "base"
    if source == "MonsterAITable.ini":
        return "monster"
    if source == "GuildMemberAccess.ini":
        return "guild"
    if source == "MountFlightMaps.txt":
        return "flight"
    if source.startswith("RandShop/") and source.endswith(".ini"):
        return "shop"
    if source in {"Script.dat", "AIScript.dat"}:
        return "mgr"
    if source.endswith(".txt"):
        return "text"
    raise _fail(source, 1, "không có bộ đọc")


def _same_kind(group: list[tsv_file.NameRow], kind: str) -> None:
    if any(_kind(row.source) != kind for row in group):
        raise _fail(_location_of(group[0]), 1, "nhóm bảng không cùng kiểu")


def _build_box(legacy: Path, group: list[tsv_file.NameRow], filename: str) -> BuiltTable:
    parts: list[BuiltTable] = []
    change_parts: list[dict[str, int]] = []
    for row in group:
        table = _parse_text(_path_of(legacy, row), _location_of(row), _source_of(row), filename)
        parts.append(table)
        change_parts.append(table.changes)
    first = parts[0]
    for other in parts[1:]:
        if other.types != first.types or other.originals != first.originals:
            raise _fail(_location_of(group[0]), 1, "khác cột với tệp đầu")
    rows: list[tuple[str, ...]] = []
    for row, table in zip(group, parts):
        for body in table.rows:
            rows.append((row.key, *body))
    source = f"{group[0].tree}/boxdroplist*.txt ({len(group)} tệp)"
    return _table(
        filename,
        source,
        ["box_key", *first.columns],
        ["text", *first.types],
        rows,
        ["", *first.originals],
        ["cột gộp", *first.notes],
        _merge_changes(change_parts),
    )


def _build_text(legacy: Path, group: list[tsv_file.NameRow], filename: str) -> BuiltTable:
    if len(group) != 1 or group[0].key_field:
        raise _fail(_location_of(group[0]), 1, "nhóm bảng không khớp")
    row = group[0]
    return _parse_text(_path_of(legacy, row), _location_of(row), _source_of(row), filename)


def _build_shop(legacy: Path, group: list[tsv_file.NameRow], filename: str) -> BuiltTable:
    rows: list[tuple[str, ...]] = []
    change_parts: list[dict[str, int]] = []
    for row in group:
        body, changes = _parse_shop_file(_path_of(legacy, row), _location_of(row))
        change_parts.append(changes)
        for item in body:
            rows.append((row.key, *item))
    columns, types, originals, notes = _shop_columns()
    source = f"{group[0].tree}/RandShop/*.ini ({len(group)} tệp)"
    return _table(filename, source, columns, types, rows, originals, notes, _merge_changes(change_parts))


def _mgr_columns(source: str) -> tuple[str, str]:
    if source == "Script.dat":
        return "script_id", "id script, atoi theo CFileDataMgr::Init"
    return "ai_id", "id AI, atoi theo CFileDataMgr::Init"


def _build_named(legacy: Path, row: tsv_file.NameRow, filename: str, kind: str) -> BuiltTable:
    path = _path_of(legacy, row)
    location = _location_of(row)
    source = _source_of(row)
    if kind == "scene":
        return _parse_scene(path, location, source, filename)
    if kind == "system":
        return _parse_system(path, location, source, filename)
    if kind == "flight":
        return _parse_flight(path, location, source, filename)
    if kind == "mgr":
        loaded, changes = _load_mgr(path, location)
        id_column, id_note = _mgr_columns(row.source)
        note = "đường dẫn sau khi đổi gạch chéo và cắt tại dấu cách"
        return _table(
            filename,
            source,
            [id_column, "path"],
            ["int", "text"],
            loaded,
            ["", ""],
            [id_note, note],
            changes,
        )
    spec = {"base": "base", "monster": "monster", "guild": "guild"}[kind]
    return _grid(path, location, source, filename, spec)


def _build_group(legacy: Path, group: list[tsv_file.NameRow]) -> BuiltTable:
    filename = Path(group[0].target).name
    kind = _kind(group[0].source)
    _same_kind(group, kind)
    if kind == "text" and group[0].key_field == "box_key":
        return _build_box(legacy, group, filename)
    if kind == "text":
        return _build_text(legacy, group, filename)
    if kind == "shop":
        return _build_shop(legacy, group, filename)
    return _build_named(legacy, group[0], filename, kind)


def _numeric_text(table: BuiltTable) -> list[str]:
    if not table.rows:
        return []
    found = []
    for index, kind in enumerate(table.types):
        if kind != "text":
            continue
        if all(NUMBER_TEXT.fullmatch(row[index]) for row in table.rows):
            found.append(table.columns[index])
    return found


def _summarize(table: BuiltTable) -> str:
    unknown = sum(1 for note in table.notes if "?" in note)
    real = len(table.columns) - unknown
    parts = [f"{table.filename}: bản ghi {len(table.rows)}, cột {len(table.columns)}, tên thật {real}, cột ? {unknown}"]
    for key, label in CHANGE_LABELS:
        value = table.changes.get(key, 0)
        if value:
            parts.append(f"{label} {value}")
    numeric = _numeric_text(table)
    if numeric:
        parts.append("cột text toàn số: " + ", ".join(numeric))
    return ", ".join(parts)


def _foreign(directory: Path, tool_id: str, keep_tools: tuple[str, ...] = ()) -> Path | None:
    kept = {tsv_file.canonical_tool(name) for name in keep_tools}
    if not directory.exists():
        return None
    for path in sorted(item for item in directory.rglob("*") if item.is_file()):
        owner = tsv_file.owned_tool(path)
        if owner == tool_id or owner in kept:
            continue
        return path
    return None


def _display(path: Path) -> str:
    try:
        return path.resolve().relative_to(Path.cwd().resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def _group_rows(rows: tuple[tsv_file.NameRow, ...] | list[tsv_file.NameRow]) -> list[list[tsv_file.NameRow]]:
    selected = [row for row in rows if row.owner == "B" and row.fate == "table"]
    groups: dict[str, list[tsv_file.NameRow]] = {}
    order: list[str] = []
    for row in selected:
        if row.target not in groups:
            order.append(row.target)
            groups[row.target] = []
        groups[row.target].append(row)
    return [groups[target] for target in order]


def _read_groups(legacy_root: Path, groups: list[list[tsv_file.NameRow]]) -> tuple[list[str], list[BuiltTable]]:
    errors: list[str] = []
    built: list[BuiltTable] = []
    for group in groups:
        try:
            built.append(_build_group(Path(legacy_root), group))
        except LegacyError as exc:
            errors.append(str(exc))
    return errors, built


def _append_script_tables(built: list[BuiltTable], legacy_root: Path) -> None:
    present = {table.filename for table in built}
    for table in _script_tables(Path(legacy_root)):
        if table.filename not in present:
            built.append(table)


def _column_rows(table: BuiltTable) -> list[tuple[str, ...]]:
    rows: list[tuple[str, ...]] = []
    for index in range(len(table.columns)):
        rows.append(
            (
                str(index),
                table.originals[index],
                table.columns[index],
                table.types[index],
                table.notes[index],
            )
        )
    return rows


_GENERIC_COLUMN = re.compile(r"column_\d+")


def _curated_names(path: Path) -> dict[int, tuple[str, str, str]]:
    """(nhãn gốc, tên, ghi chú) đã đặt (tên không phải column_N) của tệp cột cũ, theo chỉ số; tệp
    thiếu hay hỏng thì rỗng."""
    if not path.is_file():
        return {}
    try:
        table = tsv_file.read_table(path)
    except (tsv_file.TsvError, OSError, UnicodeDecodeError):
        return {}
    if table.columns != ("index", "original", "name", "type", "note"):
        return {}
    names: dict[int, tuple[str, str, str]] = {}
    for row in table.rows:
        if row[0].isdigit() and not _GENERIC_COLUMN.fullmatch(row[2]):
            names[int(row[0])] = (row[1], row[2], row[4])
    return names


def _keep_curated(columns_root: Path, table: BuiltTable) -> BuiltTable:
    """Xuất lại không được làm mất tên cột đã đặt: cột cùng chỉ số và cùng nhãn gốc với tệp cột cũ
    giữ tên và ghi chú cũ (trừ khi tên đó trùng một cột khác). Cột mới vẫn theo luật đặt tên."""
    curated = _curated_names(columns_root / table.filename)
    if not curated:
        return table
    columns = list(table.columns)
    notes = list(table.notes)
    for index, (original, name, note) in sorted(curated.items()):
        if index >= len(columns) or table.originals[index] != original or columns[index] == name:
            continue
        if name in columns:
            continue
        columns[index] = name
        notes[index] = note
    if tuple(columns) == table.columns and tuple(notes) == table.notes:
        return table
    return BuiltTable(
        filename=table.filename,
        source=table.source,
        columns=tuple(columns),
        types=table.types,
        rows=table.rows,
        originals=table.originals,
        notes=tuple(notes),
        changes=table.changes,
    )

def _write_built(output_dir: Path, columns_root: Path, built: list[BuiltTable]) -> None:
    built = [_keep_curated(columns_root, table) for table in built]
    tsv_file.prepare_directory(output_dir, TOOL, keep_tools=KEEP_TABLE_TOOLS)
    tsv_file.prepare_directory(columns_root, TOOL)
    for table in built:
        tsv_file.write_table(
            Path(output_dir) / table.filename,
            table.source,
            TOOL,
            list(table.types),
            list(table.columns),
            table.rows,
        )
        tsv_file.write_table(
            columns_root / table.filename,
            table.source,
            TOOL,
            ["int", "text", "text", "text", "text"],
            ["index", "original", "name", "type", "note"],
            _column_rows(table),
        )


def export_legacy(
    legacy_root: Path,
    output_dir: Path,
    rows: tuple[tsv_file.NameRow, ...] | list[tsv_file.NameRow],
    *,
    check_only: bool = False,
    column_dir: Path | None = None,
    include_script_index: bool = False,
) -> tuple[list[str], list[str]]:
    """Đọc các dòng owner B và ghi bảng. Có lỗi thì không ghi gì."""
    errors, built = _read_groups(legacy_root, _group_rows(rows))
    if include_script_index and not errors:
        try:
            _append_script_tables(built, legacy_root)
        except LegacyError as exc:
            errors.append(str(exc))
    if errors:
        return errors, []
    summaries = [_summarize(table) for table in built]
    if column_dir is None:
        columns_root = Path(__file__).resolve().parent / "columns" / "server"
    else:
        columns_root = column_dir
    tool_id = tsv_file.canonical_tool(TOOL)
    blocked = _foreign(Path(output_dir), tool_id, KEEP_TABLE_TOOLS)
    if blocked is None:
        blocked = _foreign(columns_root, tool_id)
    if blocked is not None:
        return [f"{_display(blocked)}:1: tệp lạ, không xoá"], []
    if check_only:
        return [], summaries
    _write_built(output_dir, columns_root, built)
    return [], summaries


def main(argv: list[str] | None = None) -> int:
    """Điểm vào dòng lệnh. In lỗi hoặc bảng tổng kết."""
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    check_only = False
    positionals: list[str] = []
    for arg in args:
        if arg == "--check":
            check_only = True
            continue
        if arg.startswith("-"):
            print(f"không rõ đối số: {arg}")
            return 1
        positionals.append(arg)
    if len(positionals) != 2:
        print(HELP)
        return 1
    errors, summary = export_legacy(
        Path(positionals[0]),
        Path(positionals[1]),
        tsv_file.read_name_map(),
        check_only=check_only,
        include_script_index=True,
    )
    if errors:
        for error in errors:
            print(error)
        return 1
    for line in summary:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
