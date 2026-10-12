"""Căn cột bản 2026 với bản 0859602, giữ thứ tự thêm hoặc bớt cột.

Neo là cặp cùng kiểu, khớp ít nhất 95% id chung, mỗi bên từ 3 giá trị trở lên.
Giữa hai neo liền mà số cột bằng nhau thì nội suy cột ít thông tin. Cột mà cả
hai bên có từ 3 giá trị và khớp dưới 95% thì để mới, không mượn tên cột gốc.
Kiểu khác nhưng nội dung khớp từ 99% thì ghi đổi kiểu. Cặp chéo chỉ khi mỗi
bên chỉ còn đúng một ứng viên.
"""
from __future__ import annotations

import math
import re
import struct
from dataclasses import dataclass
from pathlib import Path

Cell = tuple[str, int | str]
Rows = tuple[tuple[Cell, ...], ...]
_INT = re.compile(r"[+-]?\d+")
_FLOAT = re.compile(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?")
_NAME = re.compile(r"^[a-z][a-z0-9_]*$")
_BASIS = re.compile(r"^(?:glossary|direct|code:[^:]+:[0-9]+)$")
_TERM_COLUMNS = ("original", "scope", "name", "basis", "note")
_TERM_TYPES = "text\ttext\ttext\ttext\ttext"
_KINDS = ("neo", "cross", "interpolated", "retyped", "new")
_LABEL = {"neo": "neo", "cross": "chéo", "interpolated": "nội suy", "retyped": "đổi kiểu"}


@dataclass(frozen=True)
class TablePair:
    kinds_new: tuple[str, ...]
    rows_new: Rows
    kinds_old: tuple[str, ...]
    names_old: tuple[str, ...]
    rows_old: Rows


@dataclass(frozen=True)
class Link:
    """Một cột 2026 đã ghép, hoặc cột mới khi legacy_index là None."""

    legacy_index: int | None
    legacy_name: str
    kind: str
    matched: int
    total: int


@dataclass(frozen=True)
class Summary:
    source: str
    columns_2026: int
    columns_legacy: int
    anchors: int
    interpolated: int
    retyped: int
    new_in_2026: int
    lost: int
    lost_list: str


@dataclass(frozen=True)
class Term:
    original: str
    name: str
    basis: str
    note: str
    scope: str = ""


@dataclass(frozen=True)
class _Hit:
    left: int
    right: int
    matched: int
    total: int


@dataclass(frozen=True)
class _Bar:
    same_type: bool
    ratio: int
    distinct_min: int
    content: bool


@dataclass(frozen=True)
class _Node:
    count: int
    matched: int
    pairs: tuple[tuple[int, int], ...]


_NEO = _Bar(True, 95, 3, False)
_RETYPE = _Bar(False, 99, 3, True)
_Distincts = tuple[tuple[int, ...], tuple[int, ...]]


def link_note(link: Link) -> str:
    """Câu ghi vào cột note: loại ghép, chỉ số cột gốc và tỉ lệ."""
    if link.kind == "new":
        return "mới ở 2026"
    label = _LABEL[link.kind]
    if link.total == 0:
        percent = "không có id chung"
    else:
        ratio = link.matched * 100 / link.total
        percent = f"khớp {ratio:.1f}% ({link.matched}/{link.total} id)"
    return f"{label}: cột gốc {link.legacy_index}, {percent}"


def _check_width(rows: Rows, width: int, label: str) -> None:
    for row in rows:
        if len(row) != width:
            raise ValueError(f"dòng {label} sai số cột")


def _check_pair(pair: TablePair) -> None:
    if len(pair.rows_new) != len(pair.rows_old):
        raise ValueError("hai bên không cùng số dòng đã ghép")
    _check_width(pair.rows_new, len(pair.kinds_new), "2026")
    _check_width(pair.rows_old, len(pair.kinds_old), "0859602")


def _all_new(width: int) -> tuple[Link, ...]:
    return tuple(Link(None, "", "new", 0, 0) for _ in range(width))


def _distincts(rows: Rows, width: int) -> tuple[int, ...]:
    found = []
    for column in range(width):
        seen = {row[column] for row in rows}
        found.append(len(seen))
    return tuple(found)


def _text_of(cell: Cell) -> str | None:
    kind, value = cell
    if kind == "int" and isinstance(value, int):
        return str(value)
    if kind == "text" and isinstance(value, str):
        return value
    return None


def _float_as_int(bits: int) -> int | None:
    value = struct.unpack("<f", struct.pack("<I", bits & 0xFFFFFFFF))[0]
    if not math.isfinite(value) or value != int(value):
        return None
    packed = struct.pack("<f", float(int(value)))
    if struct.unpack("<I", packed)[0] != (bits & 0xFFFFFFFF):
        return None
    return int(value)


def _number(cell: Cell) -> int | None:
    kind, value = cell
    if kind == "int" and isinstance(value, int):
        return value
    if kind == "text" and isinstance(value, str) and _INT.fullmatch(value):
        return int(value)
    if kind == "float" and isinstance(value, int):
        return _float_as_int(value)
    return None


def _text_is_float(text: str, bits: int) -> bool:
    if not _FLOAT.fullmatch(text):
        return False
    value = float(text)
    if not math.isfinite(value):
        return False
    packed = struct.pack("<f", value)
    return struct.unpack("<I", packed)[0] == (bits & 0xFFFFFFFF)


def _float_text(cell: Cell, other: Cell) -> bool:
    if cell[0] == "float" and other[0] == "text" and isinstance(cell[1], int) and isinstance(other[1], str):
        return _text_is_float(other[1], cell[1])
    if other[0] == "float" and cell[0] == "text" and isinstance(other[1], int) and isinstance(cell[1], str):
        return _text_is_float(cell[1], other[1])
    return False


def _content_equal(cell: Cell, other: Cell) -> bool:
    left = _text_of(cell)
    right = _text_of(other)
    if left is not None and left == right:
        return True
    left_number = _number(cell)
    right_number = _number(other)
    if left_number is not None and left_number == right_number:
        return True
    return _float_text(cell, other)


def _matches(cell: Cell, other: Cell, content: bool) -> bool:
    if cell[0] == "invalid" or other[0] == "invalid":
        return False
    if cell[0] == other[0]:
        return cell[1] == other[1]
    if not content:
        return False
    return _content_equal(cell, other)


def _matched(rows_new: Rows, rows_old: Rows, left: int, right: int, content: bool) -> int:
    matched = 0
    for index, row in enumerate(rows_new):
        if _matches(row[left], rows_old[index][right], content):
            matched += 1
    return matched


def _kind_ok(pair: TablePair, left: int, right: int, same_type: bool) -> bool:
    equal = pair.kinds_new[left] == pair.kinds_old[right]
    if same_type:
        return equal
    return not equal


def _one_hit(pair: TablePair, left: int, right: int, bar: _Bar, distincts: _Distincts) -> _Hit | None:
    if not _kind_ok(pair, left, right, bar.same_type):
        return None
    if distincts[0][left] < bar.distinct_min or distincts[1][right] < bar.distinct_min:
        return None
    total = len(pair.rows_new)
    matched = _matched(pair.rows_new, pair.rows_old, left, right, bar.content)
    if total == 0 or matched * 100 < bar.ratio * total:
        return None
    return _Hit(left, right, matched, total)


def _row_hits(found: list[_Hit], pair: TablePair, bar: _Bar, distincts: _Distincts, left: int) -> None:
    for right in range(len(pair.kinds_old)):
        hit = _one_hit(pair, left, right, bar, distincts)
        if hit is not None:
            found.append(hit)


def _hits(pair: TablePair, bar: _Bar) -> tuple[_Hit, ...]:
    distincts = (_distincts(pair.rows_new, len(pair.kinds_new)), _distincts(pair.rows_old, len(pair.kinds_old)))
    found: list[_Hit] = []
    for left in range(len(pair.kinds_new)):
        _row_hits(found, pair, bar, distincts, left)
    return tuple(found)


def _beats(left: _Node, right: _Node) -> bool:
    if left.count != right.count:
        return left.count > right.count
    if left.matched != right.matched:
        return left.matched > right.matched
    return left.pairs < right.pairs


def _extend(node: _Node, hit: _Hit) -> _Node:
    pairs = node.pairs + ((hit.left, hit.right),)
    return _Node(node.count + 1, node.matched + hit.matched, pairs)


def _best_end(nodes: list[_Node], hit: _Hit) -> _Node:
    chosen = _Node(1, hit.matched, ((hit.left, hit.right),))
    for node in nodes:
        if node.pairs[-1][0] >= hit.left or node.pairs[-1][1] >= hit.right:
            continue
        candidate = _extend(node, hit)
        if _beats(candidate, chosen):
            chosen = candidate
    return chosen


def _restore(node: _Node, ordered: tuple[_Hit, ...]) -> tuple[_Hit, ...]:
    index = {(hit.left, hit.right): hit for hit in ordered}
    return tuple(index[pair] for pair in node.pairs)


def _chain(hits: tuple[_Hit, ...]) -> tuple[_Hit, ...]:
    ordered = tuple(sorted(hits, key=lambda hit: (hit.left, hit.right, -hit.matched)))
    nodes: list[_Node] = []
    for hit in ordered:
        nodes.append(_best_end(nodes, hit))
    if not nodes:
        return ()
    winner = nodes[0]
    for node in nodes[1:]:
        if _beats(node, winner):
            winner = node
    return _restore(winner, ordered)


def _place(links: list[Link | None], used: set[int], hits: tuple[_Hit, ...], names: tuple[str, ...], kind: str) -> None:
    for hit in hits:
        links[hit.left] = Link(hit.right, names[hit.right], kind, hit.matched, hit.total)
        used.add(hit.right)


def _bounds(anchors: tuple[_Hit, ...], width_new: int, width_old: int) -> tuple[tuple[int, int], ...]:
    points = [(-1, -1)]
    for hit in anchors:
        points.append((hit.left, hit.right))
    points.append((width_new, width_old))
    return tuple(points)


def _between_anchors(start: tuple[int, int], end: tuple[int, int], width_new: int, width_old: int) -> bool:
    if start[0] < 0 or end[0] >= width_new:
        return False
    return start[1] >= 0 and end[1] < width_old


def _free_left(links: list[Link | None], start: int, end: int) -> tuple[int, ...]:
    found = []
    for index in range(start + 1, end):
        if links[index] is None:
            found.append(index)
    return tuple(found)


def _free_right(used: set[int], start: int, end: int) -> tuple[int, ...]:
    found = []
    for index in range(start + 1, end):
        if index not in used:
            found.append(index)
    return tuple(found)


def _gap_kind(kind_new: str, kind_old: str, matched: int, total: int) -> str:
    if kind_new == kind_old:
        return "interpolated"
    if total and matched * 100 >= 99 * total:
        return "retyped"
    return "interpolated"


def _value_count(rows: Rows, column: int) -> int:
    return len({row[column] for row in rows})


def _varied_low_match(pair: TablePair, left: int, right: int, matched: int, total: int) -> bool:
    """Cả hai bên nhiều giá trị mà khớp dưới 95% thì không được mượn tên."""
    if total == 0 or matched * 100 >= 95 * total:
        return False
    if _value_count(pair.rows_new, left) < 3:
        return False
    return _value_count(pair.rows_old, right) >= 3


def _place_positional(
    links: list[Link | None],
    used: set[int],
    pair: TablePair,
    lefts: tuple[int, ...],
    rights: tuple[int, ...],
) -> None:
    total = len(pair.rows_new)
    for left, right in zip(lefts, rights, strict=True):
        matched = _matched(pair.rows_new, pair.rows_old, left, right, True)
        if _varied_low_match(pair, left, right, matched, total):
            continue
        kind = _gap_kind(pair.kinds_new[left], pair.kinds_old[right], matched, total)
        links[left] = Link(right, pair.names_old[right], kind, matched, total)
        used.add(right)


def _hits_in(hits: tuple[_Hit, ...], lefts: set[int], rights: set[int]) -> tuple[_Hit, ...]:
    chosen = []
    for hit in hits:
        if hit.left in lefts and hit.right in rights:
            chosen.append(hit)
    return tuple(chosen)


def _fill_one(
    links: list[Link | None],
    used: set[int],
    pair: TablePair,
    start: tuple[int, int],
    end: tuple[int, int],
    retype_hits: tuple[_Hit, ...],
) -> None:
    lefts = _free_left(links, start[0], end[0])
    rights = _free_right(used, start[1], end[1])
    width_new = len(pair.kinds_new)
    width_old = len(pair.kinds_old)
    if _between_anchors(start, end, width_new, width_old) and len(lefts) == len(rights):
        _place_positional(links, used, pair, lefts, rights)
        lefts = _free_left(links, start[0], end[0])
        rights = _free_right(used, start[1], end[1])
    chosen = _chain(_hits_in(retype_hits, set(lefts), set(rights)))
    _place(links, used, chosen, pair.names_old, "retyped")


def _fill_gaps(
    links: list[Link | None],
    used: set[int],
    pair: TablePair,
    anchors: tuple[_Hit, ...],
    retype_hits: tuple[_Hit, ...],
) -> None:
    bounds = _bounds(anchors, len(pair.kinds_new), len(pair.kinds_old))
    for index in range(len(bounds) - 1):
        _fill_one(links, used, pair, bounds[index], bounds[index + 1], retype_hits)


def _mutual(hits: tuple[_Hit, ...], free_left: set[int], free_right: set[int]) -> tuple[_Hit, ...]:
    by_left: dict[int, list[_Hit]] = {}
    by_right: dict[int, list[_Hit]] = {}
    for hit in hits:
        if hit.left not in free_left or hit.right not in free_right:
            continue
        by_left.setdefault(hit.left, []).append(hit)
        by_right.setdefault(hit.right, []).append(hit)
    chosen = []
    for left in sorted(by_left):
        options = by_left[left]
        if len(options) != 1:
            continue
        hit = options[0]
        if len(by_right[hit.right]) != 1:
            continue
        chosen.append(hit)
    return tuple(chosen)


def _place_cross(links: list[Link | None], used: set[int], pair: TablePair, neo_hits: tuple[_Hit, ...]) -> None:
    free_left = {index for index, link in enumerate(links) if link is None}
    free_right = {index for index in range(len(pair.kinds_old)) if index not in used}
    chosen = _mutual(neo_hits, free_left, free_right)
    _place(links, used, chosen, pair.names_old, "cross")


def _fill_new(links: list[Link | None]) -> tuple[Link, ...]:
    done = []
    for link in links:
        if link is None:
            done.append(Link(None, "", "new", 0, 0))
            continue
        if link.kind not in _KINDS:
            raise ValueError(f"loại ghép lạ: {link.kind}")
        done.append(link)
    return tuple(done)


def align(pair: TablePair) -> tuple[Link, ...]:
    """Ghép từng cột 2026 với một cột gốc, hoặc đánh dấu cột mới."""
    _check_pair(pair)
    if not pair.rows_new:
        return _all_new(len(pair.kinds_new))
    neo_hits = _hits(pair, _NEO)
    retype_hits = _hits(pair, _RETYPE)
    anchors = _chain(neo_hits)
    links: list[Link | None] = [None] * len(pair.kinds_new)
    used: set[int] = set()
    _place(links, used, anchors, pair.names_old, "neo")
    _fill_gaps(links, used, pair, anchors, retype_hits)
    _place_cross(links, used, pair, neo_hits)
    return _fill_new(links)


def _count(links: tuple[Link, ...], kind: str) -> int:
    found = 0
    for link in links:
        if link.kind == kind:
            found += 1
    return found


def _lost_list(names_old: tuple[str, ...], used: set[int]) -> tuple[int, str]:
    lost = []
    parts = []
    for index, name in enumerate(names_old):
        if index in used:
            continue
        lost.append(index)
        parts.append(f"{index}:{name}")
    return len(lost), ";".join(parts)


def summarize(source: str, links: tuple[Link, ...], names_old: tuple[str, ...]) -> Summary:
    """Một dòng báo cáo cho một cặp bảng."""
    used = {link.legacy_index for link in links if link.legacy_index is not None}
    lost, lost_list = _lost_list(names_old, used)
    anchors = _count(links, "neo") + _count(links, "cross")
    return Summary(
        source,
        len(links),
        len(names_old),
        anchors,
        _count(links, "interpolated"),
        _count(links, "retyped"),
        _count(links, "new"),
        lost,
        lost_list,
    )


def _fail(path: Path, line: int, message: str) -> ValueError:
    return ValueError(f"{path}:{line}: {message}")


def _read_term_text(path: Path) -> str:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise _fail(path, 1, "có BOM")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise _fail(path, 1, "byte UTF-8 hỏng") from exc
    if "\r" in text:
        raise _fail(path, 1, "xuống dòng CRLF")
    if not text.endswith("\n"):
        raise _fail(path, 1, "tệp cụt, thiếu xuống dòng cuối")
    return text


def _take_term_comment(path: Path, number: int, line: str, found: dict[str, str]) -> None:
    if line.startswith("# tool:"):
        raise _fail(path, number, "bảng soạn tay không có dòng tool")
    if line.startswith("# schema "):
        found["schema"] = line[len("# schema ") :]
        return
    if line.startswith("# types: "):
        found["types"] = line[len("# types: ") :]
        return
    if line.startswith("# "):
        return
    raise _fail(path, number, "dòng chú thích không thuộc hợp đồng")


def _term_header(path: Path, line: str, number: int) -> None:
    if tuple(line.split("\t")) != _TERM_COLUMNS:
        raise _fail(path, number, "thiếu cột original, scope, name, basis, note")


def _scope_ok(scope: str) -> bool:
    if scope == "":
        return True
    if "/" in scope or "\\" in scope or scope in (".", ".."):
        return False
    return True


def _term_name_ok(name: str) -> bool:
    if name.count("{") != name.count("{n}") or name.count("}") != name.count("{n}"):
        return False
    sample = name.replace("{n}", "1")
    if not _NAME.fullmatch(sample):
        return False
    return "__" not in sample and not sample.endswith("_")


def _one_term(path: Path, number: int, cells: list[str], seen: set[tuple[str, str]]) -> Term:
    if len(cells) != 5:
        raise _fail(path, number, "sai số cột")
    original, scope, name, basis, note = cells
    key = (original, scope)
    if not original or key in seen:
        raise _fail(path, number, "original rỗng hoặc lặp")
    if not _scope_ok(scope):
        raise _fail(path, number, f"scope không hợp lệ: {scope}")
    if original.count("{n}") != name.count("{n}") or not _term_name_ok(name):
        raise _fail(path, number, f"tên không hợp lệ: {name}")
    if not _BASIS.fullmatch(basis):
        raise _fail(path, number, f"basis không hợp lệ: {basis}")
    if "\t" in note:
        raise _fail(path, number, "note chứa tab")
    seen.add(key)
    return Term(original, name, basis, note, scope)


def read_terms(path: Path) -> tuple[Term, ...]:
    """Đọc bảng thuật ngữ. Sai hình dạng, khoá lặp hoặc basis lạ thì lỗi."""
    text = _read_term_text(path)
    found: dict[str, str] = {}
    header = False
    seen: set[tuple[str, str]] = set()
    terms: list[Term] = []
    for number, line in enumerate(text.split("\n")[:-1], start=1):
        if line == "":
            continue
        if not header and line.startswith("#"):
            _take_term_comment(path, number, line, found)
            continue
        if not header:
            _term_header(path, line, number)
            header = True
            continue
        terms.append(_one_term(path, number, line.split("\t"), seen))
    if found.get("schema") != "1" or found.get("types") != _TERM_TYPES or not header:
        raise _fail(path, 1, "thiếu schema, types hoặc dòng tên cột")
    return tuple(terms)
