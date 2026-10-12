"""Xuất bảng DBC của client 2026 thành TSV.

  python TOOLS/server/export_tables.py <_raw> <tlbb> dev/server/tables
  python TOOLS/server/export_tables.py <_raw> <tlbb> dev/server/tables --check

Bố cục khớp thì lấy tên cột thẳng. Bố cục khác thì căn theo dữ liệu. Tên ASCII đưa về
snake_case; tên lặp đánh số từ 1. Mười một bảng ưu tiên tra thêm column_terms.tsv.
Ô dữ liệu không đổi. Mission và task không đổi thành quest. Id trùng là 4 byte cột 0.
--check không ghi. Thoát 0 khi sạch, 1 khi có lỗi.
"""
from __future__ import annotations

import re
import struct
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

import align_columns
import column_names
import table_census
import tsv_file
import dbc

_INT = re.compile(r"[+-]?\d+")
_FLOAT = re.compile(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?")
_NUMBER = re.compile(r"^-?\d+(?:\.\d+)?$")
_FALLBACK = re.compile(r"column_\d+")
_KIND_OF = {"INT": "int", "FLOAT": "float", "STRING": "text"}
_COLUMN_COLUMNS = ("index", "original", "name", "type", "note")
_COLUMN_TYPES = ("int", "text", "text", "text", "text")


@dataclass(frozen=True)
class ExportResult:
    written: tuple[str, ...]
    errors: tuple[str, ...]
    named_columns: int
    question_columns: int
    total_columns: int
    records: int
    numeric_strings: tuple[str, ...]
    counts: dict[str, int]
    directories: int
    unclassified_directories: int
    notices: tuple[str, ...]
    will_write: int
    alignments: tuple[align_columns.Summary, ...]


@dataclass(frozen=True)
class _Spec:
    source: str
    target: str
    kinds: tuple[str, ...]
    names: tuple[str, ...]
    originals: tuple[str, ...]
    notes: tuple[str, ...]
    row_count: int


def english_name(original: str) -> tuple[str | None, bool]:
    """Tên cột tiếng Anh, hoặc None khi không dịch được. Bool là thuật ngữ còn dấu hỏi."""
    return column_names.english_name(original)


def _signed(bits: int) -> int:
    if bits >= 0x80000000:
        return bits - 0x100000000
    return bits


def _text_at(block: bytes, offset: int) -> str:
    if offset >= len(block):
        raise ValueError("offset chuỗi ngoài khối")
    end = block.find(b"\0", offset)
    if end < 0:
        end = len(block)
    return block[offset:end].decode("gb18030")


def _atoi(cell: str) -> int | None:
    """Phần đầu số của atoi trong bộ đọc bảng chữ. Tràn int32 thì None."""
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


def _float_bits(cell: str) -> int | None:
    if not _FLOAT.fullmatch(cell):
        return None
    value = float(cell)
    if value != value or value in (float("inf"), float("-inf")):
        return None
    try:
        packed = struct.pack("<f", value)
    except OverflowError as exc:
        raise ValueError("số thực không vừa float32") from exc
    return struct.unpack("<I", packed)[0]


def _duplicate_id(table: dbc.Dbc, source: str) -> str:
    seen: set[int] = set()
    for index in range(table.rows):
        key = table.raw(index, 0)
        if key in seen:
            return f"{source}:{index + 1}: id cột 0 trùng"
        seen.add(key)
    return ""


def _special_float(table: dbc.Dbc, source: str) -> str:
    for column, kind in enumerate(table.types):
        if kind != dbc.FLOAT:
            continue
        for index in range(table.rows):
            bits = table.raw(index, column)
            if (bits & 0x7F800000) == 0x7F800000:
                return f"{source}:{index + 1}: số thực đặc biệt ở cột {column}"
    return ""


def _string_columns(table: dbc.Dbc) -> tuple[int, ...]:
    return tuple(index for index, kind in enumerate(table.types) if kind == dbc.STRING)


def _row_strings(table: dbc.Dbc, source: str, index: int, columns: tuple[int, ...], dead: set[int]) -> str:
    for column in columns:
        try:
            text = _text_at(table.strings, table.raw(index, column))
        except UnicodeDecodeError:
            return f"{source}:{index + 1}: không giải mã được cột {column}"
        except ValueError as exc:
            return f"{source}:{index + 1}: {exc}"
        if any(char in text for char in "\t\r\n"):
            return f"{source}:{index + 1}: cột {column} chứa tab hoặc xuống dòng"
        if column == 0 and text.startswith("#"):
            return f"{source}:{index + 1}: ô đầu bắt đầu bằng #"
        if table.columns == 1 and text == "":
            return f"{source}:{index + 1}: bảng một cột có ô rỗng"
        if column in dead or not _NUMBER.fullmatch(text):
            dead.add(column)
    return ""


def _scan_table(table: dbc.Dbc, source: str) -> tuple[str, tuple[int, ...]]:
    duplicate = _duplicate_id(table, source)
    if duplicate:
        return duplicate, ()
    special = _special_float(table, source)
    if special:
        return special, ()
    columns = _string_columns(table)
    dead: set[int] = set()
    for index in range(table.rows):
        problem = _row_strings(table, source, index, columns, dead)
        if problem:
            return problem, ()
    if table.rows == 0:
        return "", ()
    return "", tuple(column for column in columns if column not in dead)


def _decode_legacy(path: Path, source: str) -> str:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise ValueError(f"{source}:1: bản đối chiếu có BOM")
    if b"\r\n" in data:
        data = data.replace(b"\r\n", b"\n")
    if b"\r" in data:
        raise ValueError(f"{source}:1: bản đối chiếu có CR không thuộc CRLF")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        line = data[: exc.start].count(b"\n") + 1
        raise ValueError(f"{source}:{line}: byte UTF-8 hỏng") from exc


def _legacy_header(text: str, source: str) -> tuple[tuple[str, ...], tuple[str, ...], list[tuple[int, str]]]:
    content = [(number, line) for number, line in enumerate(text.split("\n"), start=1) if line]
    if len(content) < 2:
        raise ValueError(f"{source}:1: bản đối chiếu thiếu dòng tên cột")
    kinds = tuple(_KIND_OF.get(token, token) for token in content[0][1].split("\t"))
    names = tuple(content[1][1].split("\t"))
    return kinds, names, content[2:]


def _legacy_notices(source: str, counts: tuple[int, int, int, int, int]) -> list[str]:
    skipped, empty, short, impure, extra = counts
    notices = []
    if skipped:
        notices.append(f"{source}:1: đối chiếu bỏ {skipped} dòng chú thích")
    if empty:
        notices.append(f"{source}:1: đối chiếu bỏ {empty} dòng ô đầu rỗng")
    if short:
        notices.append(f"{source}:1: đối chiếu đệm {short} dòng thiếu ô")
    if impure:
        notices.append(f"{source}:1: đối chiếu {impure} id không phải số nguyên thuần")
    if extra:
        notices.append(f"{source}:1: đối chiếu cắt {extra} dòng thừa ô")
    return notices


def _trim_cells(cells: list[str], width: int, source: str, number: int, keep_extra: bool) -> list[str]:
    if len(cells) > width:
        if not keep_extra:
            raise ValueError(f"{source}:{number}: dòng thừa ô")
        return cells[:width]
    if len(cells) < width:
        cells.extend("" for _ in range(width - len(cells)))
    return cells


def _legacy_rows(
    data_lines: list[tuple[int, str]],
    source: str,
    width: int,
    kinds: tuple[str, ...],
    keep_extra: bool = False,
) -> tuple[dict[object, tuple[str, ...]] | None, tuple[str, ...]]:
    rows: dict[object, tuple[str, ...]] = {}
    skipped_hash = 0
    short_rows = 0
    empty_ids = 0
    impure_ids = 0
    extra_rows = 0
    duplicate = False
    for number, line in data_lines:
        if line.startswith("#"):
            skipped_hash += 1
            continue
        cells = line.split("\t")
        if len(cells) > width:
            extra_rows += 1
        if len(cells) < width:
            short_rows += 1
        cells = _trim_cells(cells, width, source, number, keep_extra)
        if cells[0] == "":
            empty_ids += 1
            continue
        _reject_wide_float(cells, kinds, source, number)
        if kinds and kinds[0] == "int" and not _INT.fullmatch(cells[0]):
            impure_ids += 1
        key = cells[0]
        if key in rows:
            duplicate = True
        rows[key] = tuple(cells)
    counts = (skipped_hash, empty_ids, short_rows, impure_ids, extra_rows)
    notices = _legacy_notices(source, counts)
    if duplicate:
        return None, tuple(notices)
    return rows, tuple(notices)


def _reject_wide_float(cells: list[str], kinds: tuple[str, ...], source: str, number: int) -> None:
    for index, kind in enumerate(kinds):
        if kind != "float" or index >= len(cells):
            continue
        try:
            _float_bits(cells[index])
        except ValueError as exc:
            raise ValueError(f"{source}:{number}: {exc}") from exc


def _kind_name(kind: int) -> str:
    if kind not in table_census.KIND:
        raise ValueError("kiểu cột lạ")
    return table_census.KIND[kind]


def _same_layout(table: dbc.Dbc, kinds: tuple[str, ...], names: tuple[str, ...]) -> bool:
    pattern = tuple(_kind_name(kind) for kind in table.types)
    return kinds == pattern and len(names) == table.columns


def _id_key(kind: str, cell: str) -> object | None:
    if kind == "int":
        return _atoi(cell)
    if kind == "float":
        return _float_bits(cell)
    return cell


def _dbc_id(table: dbc.Dbc, index: int) -> object:
    kind = table.types[0]
    bits = table.raw(index, 0)
    if kind == dbc.INT:
        return _signed(bits)
    if kind == dbc.FLOAT:
        return bits
    return _text_at(table.strings, bits)


def _same_value(table: dbc.Dbc, index: int, column: int, legacy_cell: str) -> bool:
    kind = table.types[column]
    bits = table.raw(index, column)
    if kind == dbc.INT:
        number = _atoi(legacy_cell)
        return number is not None and number == _signed(bits)
    if kind == dbc.FLOAT:
        return _float_bits(legacy_cell) == bits
    return _text_at(table.strings, bits) == legacy_cell


def _percent(matched: int, total: int) -> str:
    if total == 0:
        return "không có id chung"
    ratio = matched / total * 100
    return f"khớp {ratio:.1f}% ({matched}/{total} id)"


def _match_notes(table: dbc.Dbc, rows: dict[str, tuple[str, ...]] | None, kind: str) -> tuple[str, ...]:
    if rows is None:
        return tuple("id bản đối chiếu không duy nhất" for _ in range(table.columns))
    keyed: dict[object, tuple[str, ...]] = {}
    duplicate = False
    for cell_row in rows.values():
        key = _id_key(kind, cell_row[0])
        if key is None:
            continue
        if key in keyed:
            duplicate = True
        keyed[key] = cell_row
    if duplicate:
        return tuple("id bản đối chiếu không duy nhất" for _ in range(table.columns))
    hits = [0] * table.columns
    paired = 0
    for index in range(table.rows):
        legacy = keyed.get(_dbc_id(table, index))
        if legacy is None:
            continue
        paired += 1
        for column in range(table.columns):
            if _same_value(table, index, column, legacy[column]):
                hits[column] += 1
    return tuple(_percent(hit, paired) for hit in hits)


_Kinds = tuple[str, ...]
_Texts = tuple[str, ...]
_Built = tuple[_Kinds, _Texts, _Texts, _Texts]
_TermMap = tuple[column_names.TermRow, ...]
_Ref = tuple[str, _Kinds, _Texts, _Texts, _Texts, tuple[str, ...], align_columns.Summary | None]
def _choose(
    originals: tuple[str, ...],
    translate: bool,
    scope: str,
    terms: _TermMap,
) -> tuple[tuple[str, str, str], ...]:
    chosen = []
    for index, original in enumerate(originals):
        fallback = f"column_{index}"
        if not translate or original == "":
            chosen.append((original, fallback, ""))
            continue
        name, flag = column_names.classify(original, scope, terms, index)
        chosen.append((original, name, flag))
    return tuple(chosen)


def _number_repeated(names: list[str]) -> tuple[list[str], set[int]]:
    return column_names.number_repeated(names)


def _apply_numbers(chosen: tuple[tuple[str, str, str], ...]) -> tuple[tuple[str, str, str], ...]:
    numbered, clashes = _number_repeated([item[1] for item in chosen])
    applied = []
    for index, item in enumerate(chosen):
        flag = "collision" if index in clashes else item[2]
        applied.append((item[0], numbered[index], flag))
    return tuple(applied)


def _note(flag: str, percent: str, layout: str) -> str:
    if layout:
        return layout
    parts = []
    rule = _flag_note(flag)
    if rule:
        parts.append(rule)
    if percent:
        parts.append(percent)
    return "; ".join(parts)


def _specs_from(
    table: dbc.Dbc,
    originals: tuple[str, ...],
    translate: bool,
    percents: tuple[str, ...],
    layout: str,
    scope: str = "",
    terms: _TermMap = (),
) -> _Built:
    chosen = _apply_numbers(_choose(originals, translate, scope, terms))
    names = []
    kept = []
    notes = []
    for index, (original, name, flag) in enumerate(chosen):
        percent = "" if layout or not percents else percents[index]
        names.append(name)
        kept.append(original if translate else "")
        notes.append(_note(flag, percent, layout))
    kinds = tuple(_kind_name(kind) for kind in table.types)
    return kinds, tuple(names), tuple(kept), tuple(notes)


def _blank_originals(table: dbc.Dbc) -> tuple[str, ...]:
    return tuple("" for _ in table.types)


def _rejected(table: dbc.Dbc, layout: str, error: str) -> _Ref:
    kinds, names, originals, notes = _specs_from(table, _blank_originals(table), False, (), layout)
    return error, kinds, names, originals, notes, (), None


def _dbc_cell(table: dbc.Dbc, index: int, column: int) -> align_columns.Cell:
    kind = table.types[column]
    bits = table.raw(index, column)
    if kind == dbc.INT:
        return ("int", _signed(bits))
    if kind == dbc.FLOAT:
        return ("float", bits)
    return ("text", _text_at(table.strings, bits))


def _legacy_cell(kind: str, text: str) -> align_columns.Cell:
    if kind == "int":
        number = _atoi(text)
        if number is None:
            return ("invalid", 0)
        return ("int", number)
    if kind == "float":
        bits = _float_bits(text)
        if bits is None:
            return ("invalid", 0)
        return ("float", bits)
    return ("text", text)


def _pair_legacy_id(kind: str, cell: str) -> object:
    if kind == "int":
        return _atoi(cell)
    if kind == "float":
        return _float_bits(cell)
    if _INT.fullmatch(cell):
        return _atoi(cell)
    return cell


def _pair_dbc_id(table: dbc.Dbc, index: int) -> object:
    kind = table.types[0]
    bits = table.raw(index, 0)
    if kind == dbc.INT:
        return _signed(bits)
    if kind == dbc.FLOAT:
        return bits
    text = _text_at(table.strings, bits)
    if _INT.fullmatch(text):
        return _atoi(text)
    return text


def _keyed_legacy(kind: str, rows: dict[str, tuple[str, ...]]) -> dict[object, tuple[str, ...]] | None:
    keyed: dict[object, tuple[str, ...]] = {}
    for row in rows.values():
        key = _pair_legacy_id(kind, row[0])
        if key in keyed:
            return None
        keyed[key] = row
    return keyed


def _old_row(kinds: tuple[str, ...], cells: tuple[str, ...]) -> tuple[align_columns.Cell, ...]:
    built = []
    for column, kind in enumerate(kinds):
        text = cells[column] if column < len(cells) else ""
        built.append(_legacy_cell(kind, text))
    return tuple(built)


def _pair_rows(
    table: dbc.Dbc,
    legacy_kinds: tuple[str, ...],
    rows: dict[str, tuple[str, ...]],
) -> tuple[align_columns.Rows, align_columns.Rows] | None:
    kind = legacy_kinds[0] if legacy_kinds else "text"
    keyed = _keyed_legacy(kind, rows)
    if keyed is None:
        return None
    new_rows = []
    old_rows = []
    for index in range(table.rows):
        old = keyed.get(_pair_dbc_id(table, index))
        if old is None:
            continue
        new_row = tuple(_dbc_cell(table, index, column) for column in range(table.columns))
        new_rows.append(new_row)
        old_rows.append(_old_row(legacy_kinds, old))
    return tuple(new_rows), tuple(old_rows)


def _translate(original: str, index: int, scope: str, terms: _TermMap) -> tuple[str, str]:
    if original == "":
        return f"column_{index}", ""
    return column_names.classify(original, scope, terms, index)


def _flag_note(flag: str) -> str:
    if flag == "failed":
        return "? chưa có tên tiếng Anh"
    if flag == "uncertain":
        return "? thuật ngữ chưa chốt; luật: M1"
    if flag == "collision":
        return "? trùng tên sau khi dịch"
    if flag == "exact":
        return "luật: nguyên văn"
    if flag == "pattern":
        return "luật: mẫu {n}"
    if flag == "m1":
        return "luật: M1"
    if flag == "m2":
        return "luật: M2"
    return ""


def _join_note(alignment: str, flag: str) -> str:
    extra = _flag_note(flag)
    if extra == "":
        return alignment
    if alignment == "":
        return extra
    return f"{alignment}; {extra}"


def _names_from_links(
    table: dbc.Dbc,
    links: tuple[align_columns.Link, ...],
    scope: str,
    terms: _TermMap,
) -> _Built:
    originals = []
    raw_names = []
    flags = []
    for index, link in enumerate(links):
        originals.append(link.legacy_name)
        name, flag = _translate(link.legacy_name, index, scope, terms)
        raw_names.append(name)
        flags.append(flag)
    numbered, clashes = _number_repeated(raw_names)
    names = []
    notes = []
    for index, link in enumerate(links):
        flag = "collision" if index in clashes else flags[index]
        names.append(numbered[index])
        notes.append(_join_note(align_columns.link_note(link), flag))
    kinds = tuple(_kind_name(kind) for kind in table.types)
    return kinds, tuple(names), tuple(originals), tuple(notes)


def _cells_equal(cell: align_columns.Cell, other: align_columns.Cell) -> bool:
    if cell[0] == "invalid" or other[0] == "invalid":
        return False
    return cell[0] == other[0] and cell[1] == other[1]


def _row_embedded(
    table: dbc.Dbc,
    kinds: tuple[str, ...],
    old: tuple[str, ...],
    index: int,
    offset: int,
) -> bool:
    for column, kind in enumerate(kinds):
        text = old[column] if column < len(old) else ""
        cell = _dbc_cell(table, index, offset + column)
        if not _cells_equal(cell, _legacy_cell(kind, text)):
            return False
    return True


def _slice_embedded(
    table: dbc.Dbc,
    kinds: tuple[str, ...],
    rows: tuple[tuple[str, ...], ...],
    offset: int,
) -> bool:
    for index, old in enumerate(rows):
        if not _row_embedded(table, kinds, old, index, offset):
            return False
    return True


def _only_offset(
    table: dbc.Dbc,
    kinds: tuple[str, ...],
    rows: tuple[tuple[str, ...], ...],
) -> int | None:
    """Một lát cột khớp hết thì trả độ lệch. Một dòng không đủ căn cứ."""
    if table.rows != len(rows) or table.rows < 2 or not kinds:
        return None
    if len(kinds) > table.columns:
        return None
    found: list[int] = []
    limit = table.columns - len(kinds)
    for offset in range(limit + 1):
        if _slice_embedded(table, kinds, rows, offset):
            found.append(offset)
    if len(found) != 1:
        return None
    return found[0]


def _shift_link(index: int, offset: int, names: tuple[str, ...], total: int) -> align_columns.Link:
    legacy_index = index - offset
    if legacy_index < 0 or legacy_index >= len(names):
        return align_columns.Link(None, "", "new", 0, 0)
    return align_columns.Link(legacy_index, names[legacy_index], "neo", total, total)


def _embedded_links(
    table: dbc.Dbc,
    kinds: tuple[str, ...],
    names: tuple[str, ...],
    rows: tuple[tuple[str, ...], ...],
) -> tuple[align_columns.Link, ...] | None:
    offset = _only_offset(table, kinds, rows)
    if offset is None:
        return None
    total = table.rows
    links = [_shift_link(index, offset, names, total) for index in range(table.columns)]
    return tuple(links)


def _unpaired_embedding(
    table: dbc.Dbc,
    kinds: tuple[str, ...],
    names: tuple[str, ...],
    body: dict[str, tuple[str, ...]] | None,
    paired: tuple[align_columns.Rows, align_columns.Rows] | None,
) -> tuple[align_columns.Link, ...] | None:
    """Id cột đầu không chung: giữ tên khi cả dòng gốc nằm nguyên trong một lát."""
    if body is None or paired is None or paired[0]:
        return None
    return _embedded_links(table, kinds, names, tuple(body.values()))


def _aligned_links(
    table: dbc.Dbc,
    legacy_kinds: tuple[str, ...],
    legacy_names: tuple[str, ...],
    body: dict[str, tuple[str, ...]] | None,
) -> tuple[align_columns.Link, ...]:
    paired = None if body is None else _pair_rows(table, legacy_kinds, body)
    embedded = _unpaired_embedding(table, legacy_kinds, legacy_names, body, paired)
    if embedded is not None:
        return embedded
    kinds = tuple(_kind_name(kind) for kind in table.types)
    rows_new: align_columns.Rows = ()
    rows_old: align_columns.Rows = ()
    if paired is not None:
        rows_new, rows_old = paired
    return align_columns.align(align_columns.TablePair(kinds, rows_new, legacy_kinds, legacy_names, rows_old))


def _from_alignment(
    table: dbc.Dbc,
    source: str,
    legacy_kinds: tuple[str, ...],
    legacy_names: tuple[str, ...],
    body: dict[str, tuple[str, ...]] | None,
    terms: _TermMap,
) -> tuple[_Built, align_columns.Summary]:
    links = _aligned_links(table, legacy_kinds, legacy_names, body)
    summary = align_columns.summarize(source, links, legacy_names)
    built = _names_from_links(table, links, Path(source).name, terms)
    return built, summary


def _same_reference(
    table: dbc.Dbc,
    source: str,
    legacy_kinds: tuple[str, ...],
    legacy_names: tuple[str, ...],
    data_lines: list[tuple[int, str]],
    terms: _TermMap,
) -> _Ref:
    try:
        body, notices = _legacy_rows(data_lines, source, table.columns, legacy_kinds)
        kind = legacy_kinds[0] if legacy_kinds else "text"
        percents = _match_notes(table, body, kind)
    except ValueError as exc:
        return _rejected(table, "bản đối chiếu bị từ chối", str(exc))
    scope = Path(source).name
    kinds, names, originals, notes = _specs_from(table, legacy_names, True, percents, "", scope, terms)
    return "", kinds, names, originals, notes, notices, None


def _legacy_key_clash(kind: str, body: dict[str, tuple[str, ...]] | None) -> str:
    """Cặp chữ id khác nhau nhưng cùng khóa, hoặc trùng nguyên văn khi mất cả bảng dòng."""
    if body is None:
        return "trùng nguyên văn"
    seen: dict[object, str] = {}
    for row in body.values():
        key = _pair_legacy_id(kind, row[0])
        previous = seen.get(key)
        if previous is None:
            seen[key] = row[0]
            continue
        return f"{previous}={key} và {row[0]}={key}"
    return ""


def _ambiguous_ids(table: dbc.Dbc, source: str, notices: tuple[str, ...], clash: str) -> _Ref:
    """Id đụng nhau thì không gắn nhãn mới ở 2026 cho mọi cột."""
    note = "id bản đối chiếu không duy nhất"
    built = _specs_from(table, _blank_originals(table), False, (), note)
    kinds, names, originals, notes = built
    heard = notices + (f"{source}:1: {note}: {clash}",)
    return "", kinds, names, originals, notes, heard, None


def _different_reference(
    table: dbc.Dbc,
    source: str,
    legacy_kinds: tuple[str, ...],
    legacy_names: tuple[str, ...],
    data_lines: list[tuple[int, str]],
    terms: _TermMap,
) -> _Ref:
    try:
        width = len(legacy_kinds)
        body, notices = _legacy_rows(data_lines, source, width, legacy_kinds, True)
    except ValueError as exc:
        return _rejected(table, "bản đối chiếu bị từ chối", str(exc))
    kind = legacy_kinds[0] if legacy_kinds else "text"
    clash = _legacy_key_clash(kind, body)
    if clash:
        return _ambiguous_ids(table, source, notices, clash)
    built, summary = _from_alignment(table, source, legacy_kinds, legacy_names, body, terms)
    kinds, names, originals, notes = built
    return "", kinds, names, originals, notes, notices, summary


def _reference(table: dbc.Dbc, path: Path | None, source: str, terms: _TermMap) -> _Ref:
    if path is None:
        return _rejected(table, "không có bản đối chiếu", "")
    try:
        text = _decode_legacy(path, source)
        legacy_kinds, legacy_names, data_lines = _legacy_header(text, source)
    except ValueError as exc:
        return _rejected(table, "bản đối chiếu bị từ chối", str(exc))
    if len(legacy_kinds) != len(legacy_names):
        message = f"{source}:2: số kiểu khác số tên cột"
        return _rejected(table, "bản đối chiếu bị từ chối", message)
    if _same_layout(table, legacy_kinds, legacy_names):
        return _same_reference(table, source, legacy_kinds, legacy_names, data_lines, terms)
    return _different_reference(table, source, legacy_kinds, legacy_names, data_lines, terms)


def _legacy_index(root: Path) -> dict[str, Path]:
    folder = root / "Public" / "Config"
    if not folder.is_dir():
        return {}
    return {path.relative_to(folder).as_posix().casefold(): path for path in folder.rglob("*") if path.is_file()}


def _plan_one(
    config: Path,
    source: str,
    legacy_root: Path,
    index: dict[str, Path],
    terms: _TermMap,
) -> tuple[_Spec | None, str, tuple[int, ...], tuple[str, ...], align_columns.Summary | None]:
    table = table_census.read_dbc(config / source, source)
    problem, numeric = _scan_table(table, source)
    if problem:
        return None, problem, (), (), None
    path = index.get(source.casefold())
    if path is None and (legacy_root / "Public" / "Config" / source).is_file():
        path = legacy_root / "Public" / "Config" / source
    referred = _reference(table, path, source, terms)
    error, kinds, names, originals, notes, notices, summary = referred
    spec = _Spec(source, "", kinds, names, originals, notes, table.rows)
    return spec, error, numeric, notices, summary


def _targets(listed: tuple[tsv_file.NameRow, ...]) -> dict[str, str]:
    return {row.source: row.target for row in listed if row.fate == "table" and row.owner == "A"}


def _column_counts(spec: _Spec) -> tuple[int, int, int]:
    named = 0
    questions = 0
    for name, note in zip(spec.names, spec.notes, strict=True):
        if "?" in note:
            questions += 1
        elif not _FALLBACK.fullmatch(name):
            named += 1
    return named, questions, len(spec.names)


def _foreign(folder: Path, tool_id: str) -> list[Path]:
    if not folder.exists():
        return []
    found = []
    for path in sorted(item for item in folder.rglob("*") if item.is_file()):
        if tsv_file.owned_tool(path) != tool_id:
            found.append(path)
    return found


def _output_file(tables_root: Path, target: str) -> Path:
    if not target.startswith("tables/"):
        raise ValueError(f"{target}:1: đích không nằm trong tables/")
    return tables_root / target[len("tables/") :]


def _column_file(columns_root: Path, target: str) -> Path:
    relative = target[len("tables/") :]
    if relative.startswith("shared/"):
        return columns_root / relative[len("shared/") :]
    return columns_root / relative


def _render_row(table: dbc.Dbc, index: int, cache: dict[int, str]) -> tuple[str, ...]:
    cells = []
    for column, kind in enumerate(table.types):
        bits = table.raw(index, column)
        if kind == dbc.INT:
            cells.append(str(_signed(bits)))
            continue
        if kind == dbc.FLOAT:
            text = cache.get(bits)
            if text is None:
                text = tsv_file.format_float32(bits)
                cache[bits] = text
            cells.append(text)
            continue
        cells.append(_text_at(table.strings, bits))
    return tuple(cells)


def _write_spec(config: Path, spec: _Spec, tables_root: Path, columns_root: Path) -> None:
    table = table_census.read_dbc(config / spec.source, spec.source)
    cache: dict[int, str] = {}
    rows = [_render_row(table, index, cache) for index in range(table.rows)]
    destination = _output_file(tables_root, spec.target)
    tsv_file.write_table(
        destination,
        f"client_2026/{spec.source}",
        "export_tables.py",
        spec.kinds,
        spec.names,
        rows,
    )
    column_rows = []
    for index, name in enumerate(spec.names):
        column_rows.append((str(index), spec.originals[index], name, spec.kinds[index], spec.notes[index]))
    tsv_file.write_table(
        _column_file(columns_root, spec.target),
        f"client_2026/{spec.source}",
        "export_tables.py",
        _COLUMN_TYPES,
        _COLUMN_COLUMNS,
        column_rows,
    )


_Census = tuple[dict[str, int], int, int]


@dataclass(frozen=True)
class _SourcePlan:
    spec: _Spec | None
    error: str
    notices: tuple[str, ...]
    numeric: tuple[str, ...]
    summary: align_columns.Summary | None


@dataclass(frozen=True)
class _Plan:
    specs: tuple[_Spec, ...]
    problems: tuple[str, ...]
    notices: tuple[str, ...]
    numeric: tuple[str, ...]
    named: int
    questions: int
    total: int
    records: int
    alignments: tuple[align_columns.Summary, ...]


def _client_listed(names_path: Path) -> tuple[tsv_file.NameRow, ...]:
    rows = tsv_file.read_name_map(names_path)
    selected = tuple(row for row in rows if row.tree == "client_2026")
    return tuple(sorted(selected, key=lambda row: row.source))


def _zero_plan() -> _Plan:
    return _Plan((), (), (), (), 0, 0, 0, 0, ())


def _one_source(
    config: Path,
    legacy_root: Path,
    index: dict[str, Path],
    targets: dict[str, str],
    source: str,
    terms: _TermMap,
) -> _SourcePlan:
    """Một bảng đã gắn đích. ValueError thành lỗi; không ghi tệp."""
    try:
        planned = _plan_one(config, source, legacy_root, index, terms)
    except ValueError as exc:
        return _SourcePlan(None, str(exc), (), (), None)
    spec, error, numeric_columns, notes, summary = planned
    if spec is None:
        return _SourcePlan(None, error, notes, (), summary)
    filled = _Spec(
        source,
        targets[source],
        spec.kinds,
        spec.names,
        spec.originals,
        spec.notes,
        spec.row_count,
    )
    cells = []
    for column in numeric_columns:
        cells.append(f"{source}\t{column}\t{filled.names[column]}")
    return _SourcePlan(filled, error, notes, tuple(cells), summary)


def _shared_base(target: str) -> str | None:
    marker = "tables/variants/"
    if not target.startswith(marker):
        return None
    name = target.rsplit("/", 1)[-1]
    return f"tables/shared/{name}"


def _copy_base_names(specs: list[_Spec]) -> list[_Spec]:
    by_target = {spec.target: spec for spec in specs}
    copied = []
    for spec in specs:
        base_target = _shared_base(spec.target)
        base = None if base_target is None else by_target.get(base_target)
        if base is None or base.kinds != spec.kinds:
            copied.append(spec)
            continue
        copied.append(
            _Spec(spec.source, spec.target, spec.kinds, base.names, base.originals, base.notes, spec.row_count)
        )
    return copied


def _totals(specs: list[_Spec]) -> tuple[int, int, int, int]:
    named = 0
    questions = 0
    total = 0
    records = 0
    for spec in specs:
        one_named, one_questions, one_total = _column_counts(spec)
        named += one_named
        questions += one_questions
        total += one_total
        records += spec.row_count
    return named, questions, total, records


def _plan_tables(config: Path, legacy_root: Path, listed: tuple[tsv_file.NameRow, ...], terms: _TermMap) -> _Plan:
    """Gom bảng fate=table. Có lỗi vẫn giữ phần đã đếm, chưa ghi."""
    targets = _targets(listed)
    index = _legacy_index(legacy_root)
    specs: list[_Spec] = []
    problems: list[str] = []
    notices: list[str] = []
    numeric: list[str] = []
    summaries: list[align_columns.Summary] = []
    for source in sorted(targets):
        item = _one_source(config, legacy_root, index, targets, source, terms)
        notices.extend(item.notices)
        if item.error:
            problems.append(item.error)
        if item.summary is not None:
            summaries.append(item.summary)
        if item.spec is None:
            continue
        numeric.extend(item.numeric)
        specs.append(item.spec)
    named_specs = _copy_base_names(specs)
    named, questions, total, records = _totals(named_specs)
    return _Plan(
        tuple(named_specs),
        tuple(problems),
        tuple(notices),
        tuple(numeric),
        named,
        questions,
        total,
        records,
        tuple(summaries),
    )


def _from_plan(
    plan: _Plan,
    errors: tuple[str, ...],
    census: _Census,
    written: tuple[str, ...],
    will_write: int,
) -> ExportResult:
    counts, directories, unclassified = census
    return ExportResult(
        written,
        errors,
        plan.named,
        plan.questions,
        plan.total,
        plan.records,
        plan.numeric,
        counts,
        directories,
        unclassified,
        plan.notices,
        will_write,
        plan.alignments,
    )


def _foreign_in(tables_root: Path, columns_root: Path, tool_id: str) -> list[Path]:
    shared = _foreign(tables_root / "shared", tool_id)
    variants = _foreign(tables_root / "variants", tool_id)
    columns = _foreign(columns_root, tool_id)
    return shared + variants + columns


def _write_planned(
    config: Path,
    tables_root: Path,
    columns_root: Path,
    plan: _Plan,
    census: _Census,
) -> ExportResult:
    """Ghi các bảng đã lên kế hoạch. Có tệp lạ thì không xoá và không ghi."""
    tool_id = tsv_file.canonical_tool("export_tables.py")
    foreign = _foreign_in(tables_root, columns_root, tool_id)
    if foreign:
        blocked = []
        for path in foreign:
            blocked.append(f"{path.as_posix()}:1: tệp lạ, không xoá")
        return _from_plan(plan, tuple(blocked), census, (), 0)
    shared = tables_root / "shared"
    variants = tables_root / "variants"
    tsv_file.prepare_directory(shared, "export_tables.py")
    tsv_file.prepare_directory(variants, "export_tables.py")
    tsv_file.prepare_directory(columns_root, "export_tables.py")
    for spec in plan.specs:
        _write_spec(config, spec, tables_root, columns_root)
    written = tuple(spec.target for spec in plan.specs)
    return _from_plan(plan, (), census, written, len(written))


def _load_terms() -> _TermMap | str:
    try:
        return column_names.load_terms()
    except ValueError as exc:
        return str(exc)


def collect(
    raw_root: Path,
    legacy_root: Path,
    tables_root: Path,
    names_path: Path,
    columns_root: Path,
    *,
    write: bool,
) -> ExportResult:
    """Xuất các bảng fate=table. Có lỗi thì không ghi và không xoá lượt trước."""
    config = Path(raw_root) / "Config"
    if not config.is_dir():
        missing = (f"{raw_root}:1: không có thư mục Config",)
        empty = _zero_plan()
        return _from_plan(empty, missing, ({}, 0, 0), (), 0)
    loaded = _load_terms()
    if isinstance(loaded, str):
        empty = _zero_plan()
        return _from_plan(empty, (loaded,), ({}, 0, 0), (), 0)
    names = Path(names_path)
    listed = _client_listed(names)
    covered = table_census.coverage(config, listed)
    counts, errors, directories, unclassified = covered
    census: _Census = (counts, directories, unclassified)
    if errors:
        empty = _zero_plan()
        return _from_plan(empty, errors, census, (), 0)
    legacy = Path(legacy_root)
    plan = _plan_tables(config, legacy, listed, loaded)
    if plan.problems:
        return _from_plan(plan, plan.problems, census, (), 0)
    if not write:
        return _from_plan(plan, (), census, (), len(plan.specs))
    tables = Path(tables_root)
    columns = Path(columns_root)
    return _write_planned(config, tables, columns, plan, census)


_ALIGN_COLUMNS = (
    "source",
    "columns_2026",
    "columns_legacy",
    "anchors",
    "interpolated",
    "retyped",
    "new_in_2026",
    "lost",
    "lost_list",
)
_ALIGN_TYPES = ("text", "int", "int", "int", "int", "int", "int", "int", "text")


def _alignment_row(row: align_columns.Summary) -> tuple[str, ...]:
    return (
        row.source,
        str(row.columns_2026),
        str(row.columns_legacy),
        str(row.anchors),
        str(row.interpolated),
        str(row.retyped),
        str(row.new_in_2026),
        str(row.lost),
        row.lost_list,
    )


def _write_alignment(path: Path, rows: tuple[align_columns.Summary, ...]) -> None:
    ordered = tuple(sorted(rows, key=lambda row: row.source))
    body = [_alignment_row(row) for row in ordered]
    tsv_file.write_table(path, "client_2026", "export_tables.py", _ALIGN_TYPES, _ALIGN_COLUMNS, body)


HELP = """\
cách dùng: python TOOLS/server/export_tables.py <_raw> <tlbb> <thư mục bảng> [--check]
[--names <tsv>] [--columns <thư mục>] [--alignment <tsv>]

Xuất DBC của client 2026 thành TSV. --check kiểm hết và không ghi tệp nào.
Thoát 0 khi sạch, 1 khi có lỗi. Mỗi lỗi một dòng tệp:dòng: nội dung.
"""
_OPTIONS = {"--names", "--columns", "--alignment"}


@dataclass
class _Parsed:
    check: bool = False
    names: str = ""
    columns: str = ""
    alignment: str = ""
    positionals: list[str] = field(default_factory=list)


def _need_value(args: list[str], index: int) -> str:
    if index + 1 >= len(args) or args[index + 1].startswith("-"):
        raise ValueError(f"export_tables.py:1: thiếu giá trị cho {args[index]}")
    return args[index + 1]


def _store_option(parsed: _Parsed, name: str, value: str) -> None:
    if name == "--names":
        parsed.names = value
        return
    if name == "--columns":
        parsed.columns = value
        return
    parsed.alignment = value


def _consume(args: list[str], index: int, parsed: _Parsed) -> int:
    arg = args[index]
    if arg == "--check":
        parsed.check = True
        return index + 1
    if arg in _OPTIONS:
        value = _need_value(args, index)
        _store_option(parsed, arg, value)
        return index + 2
    if arg.startswith("-"):
        raise ValueError(f"export_tables.py:1: không rõ đối số: {arg}")
    parsed.positionals.append(arg)
    return index + 1


def _parse_arguments(args: list[str]) -> _Parsed:
    parsed = _Parsed()
    index = 0
    while index < len(args):
        index = _consume(args, index, parsed)
    if len(parsed.positionals) != 3:
        raise ValueError("export_tables.py:1: cần thư mục _raw, tlbb và thư mục bảng")
    return parsed


def _print_result(result: ExportResult) -> None:
    for error in result.errors:
        print(error)
    for notice in result.notices:
        print(notice)
    print(f"tệp: {sum(result.counts.values())}")
    print(f"chưa phân loại: {sum(1 for error in result.errors if 'chưa phân loại' in error)}")
    for fate in sorted(result.counts):
        print(f"{fate}: {result.counts[fate]}")
    print(f"thư mục: {result.directories}")
    print(f"thư mục chưa phân loại: {result.unclassified_directories}")
    print(f"bảng sẽ ghi: {result.will_write}")
    print(f"bảng đã ghi: {len(result.written)}")
    print(f"bản ghi: {result.records}")
    print(f"cột: {result.total_columns}")
    print(f"cột có tên: {result.named_columns}")
    print(f"cột còn ?: {result.question_columns}")
    print(f"cặp căn: {len(result.alignments)}")
    print(f"cột chữ toàn số: {len(result.numeric_strings)}")
    for item in result.numeric_strings:
        print(f"cột chữ toàn số: {item}")


def _utf8_stdout() -> None:
    reconfigure = getattr(sys.stdout, "reconfigure", None)
    if reconfigure is None:
        return
    try:
        reconfigure(encoding="utf-8")
    except (OSError, ValueError):
        return


def main(argv: list[str] | None = None) -> int:
    """Xuất bảng. Có lỗi thì không ghi và không xoá tệp của lượt trước."""
    _utf8_stdout()
    arguments = list(sys.argv[1:] if argv is None else argv)
    if "--help" in arguments or "-h" in arguments:
        print(HELP)
        return 0
    try:
        parsed = _parse_arguments(arguments)
    except ValueError as exc:
        print(exc)
        return 1
    names = Path(parsed.names) if parsed.names else Path(__file__).with_name("table_names.tsv")
    columns_root = Path(__file__).resolve().parent / "columns" / "shared"
    columns = Path(parsed.columns) if parsed.columns else columns_root
    started = time.perf_counter()
    result = collect(
        Path(parsed.positionals[0]),
        Path(parsed.positionals[1]),
        Path(parsed.positionals[2]),
        names,
        columns,
        write=not parsed.check,
    )
    _print_result(result)
    print(f"thời gian: {time.perf_counter() - started:.1f} giây")
    if result.errors:
        return 1
    if parsed.check:
        return 0
    default_alignment = Path(__file__).with_name("column_alignment.tsv")
    alignment = Path(parsed.alignment) if parsed.alignment else default_alignment
    _write_alignment(alignment, result.alignments)
    return 0


if __name__ == "__main__":
    sys.exit(main())
