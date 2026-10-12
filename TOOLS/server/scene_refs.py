"""Liệt kê lời gọi LuaFnSetSceneLoad trong Public/Data/Script.

    python TOOLS/server/scene_refs.py <thư mục tlbb> <thư mục bảng máy chủ> [--check]

Mỗi lời gọi một dòng scene_load_refs.tsv, thêm số tệp trên đĩa. Cùng lượt ghi
scene_level_files.tsv. Lời gọi sau dấu -- không thành dòng, chỉ đếm.
Chuỗi dài [[ ]] là literal. format gán vào biến, và bảng chuỗi nối bằng .., vẫn là mẫu.
Không đoán: không ra tên tệp hay mẫu tên thì how là unresolved.
"""
from __future__ import annotations

import fnmatch
import re
import sys
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

import scene_classify as kinds
import scene_read
import tsv_file

TOOL = "scene_refs.py"
HELP = """\
cách dùng: python TOOLS/server/scene_refs.py <thư mục tlbb> <thư mục bảng máy chủ> [--check]

Ghi scene_load_refs.tsv và scene_level_files.tsv. --check không ghi. Thoát 0 khi sạch, 1 khi có lỗi.
"""
COLUMNS = ("script", "line", "kind", "argument", "resolved", "how", "files_on_disk")
TYPES = ("text", "int", "text", "text", "text", "text", "int")
LEVEL_COLUMNS = ("file", "scene_by_name", "script_scenes", "verdict")
LEVEL_TYPES = ("text", "text", "text", "text")
_LEVEL_VERDICTS = ("same", "mismatch", "unpointed", "map_unknown")
HOWS = frozenset({"literal", "constant", "format", "unresolved"})
_CALL = re.compile(r"LuaFnSetSceneLoad_([A-Za-z0-9_]+)\s*\(")
_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
_NAME_EQ = re.compile(r"(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)")
_NAME_HEAD = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
_FORMAT_TOKEN = re.compile(r"%[-+0-9.]*[sdif]")
_MAX_ALTERNATIVES = 64
_LEVEL_KINDS = frozenset({kinds.MONSTER_BY_LEVEL, kinds.MONSTER_GROUP, kinds.MONSTER_BARE, kinds.MONSTER_ENTRANCE})
NameSets = dict[str, set[str]]


@dataclass(frozen=True)
class Bound:
    kind: str
    values: tuple[str, ...]


Bindings = dict[str, Bound]


@dataclass(frozen=True)
class LoadCall:
    script: str
    line: int
    kind: str
    argument: str
    resolved: str
    how: str
    commented: bool


@dataclass(frozen=True)
class LevelRow:
    filename: str
    name_scenes: tuple[str, ...]
    script_scenes: tuple[str, ...]
    pointed: bool
    map_known: bool


def _in_string(char: str, quote: str, escaped: bool) -> tuple[str, bool]:
    if escaped:
        return quote, False
    if char == "\\":
        return quote, True
    if char == quote:
        return "", False
    return quote, False


def _long_open(text: str, index: int) -> int | None:
    """Mức dấu = của ngoặc dài Lua bắt đầu tại [, hoặc None."""
    if index >= len(text) or text[index] != "[":
        return None
    cursor = index + 1
    while cursor < len(text) and text[cursor] == "=":
        cursor += 1
    if cursor < len(text) and text[cursor] == "[":
        return cursor - index - 1
    return None


def _mark(marks: list[str], text: str, start: int, end: int, kind: str) -> None:
    for index in range(start, end):
        if text[index] != "\n":
            marks[index] = kind


def _take_long(text: str, bracket: int, level: int, marks: list[str], kind: str) -> int:
    token = "]" + ("=" * level) + "]"
    body = bracket + len(token)
    close = text.find(token, body)
    end = len(text) if close < 0 else close + len(token)
    _mark(marks, text, bracket, end, kind)
    return end


def _take_comment(text: str, index: int, marks: list[str]) -> int:
    level = _long_open(text, index + 2)
    if level is None:
        end = text.find("\n", index)
        end = len(text) if end < 0 else end
        _mark(marks, text, index, end, "m")
        return end
    _mark(marks, text, index, index + 2, "m")
    return _take_long(text, index + 2, level, marks, "m")


def _take_short_string(text: str, index: int, marks: list[str]) -> int:
    quote = text[index]
    cursor = index + 1
    length = len(text)
    while cursor < length and text[cursor] != "\n":
        if text[cursor] == "\\":
            cursor += 2
            continue
        if text[cursor] == quote:
            cursor += 1
            break
        cursor += 1
    _mark(marks, text, index, min(cursor, length), "s")
    return min(cursor, length)


def _take_region(text: str, index: int, marks: list[str]) -> int:
    if text.startswith("--", index):
        return _take_comment(text, index, marks)
    if text[index] in "\"'":
        return _take_short_string(text, index, marks)
    level = _long_open(text, index)
    if level is None:
        return index
    return _take_long(text, index, level, marks, "s")


def _classify(text: str) -> str:
    """Mỗi ký tự: c mã, m chú thích, s chuỗi. Xuống dòng không đổi."""
    marks = ["c"] * len(text)
    index = 0
    length = len(text)
    while index < length:
        if text[index] == "\n":
            index += 1
            continue
        nxt = _take_region(text, index, marks)
        if nxt == index:
            index += 1
            continue
        index = nxt
    return "".join(marks)


def _paired_lines(text: str, marks: str) -> Iterator[tuple[str, str]]:
    start = 0
    index = 0
    length = len(text)
    while index < length:
        if text[index] != "\n":
            index += 1
            continue
        yield _drop_cr(text[start:index], marks[start:index])
        index += 1
        start = index
    if start < length:
        yield _drop_cr(text[start:], marks[start:])


def _drop_cr(line: str, marks: str) -> tuple[str, str]:
    if line.endswith("\r"):
        return line[:-1], marks[:-1]
    return line, marks


def _project(line: str, marks: str, kinds: str) -> str:
    chars = []
    for char, kind in zip(line, marks, strict=True):
        if kind in kinds:
            chars.append(char)
            continue
        chars.append(" ")
    return "".join(chars)


def _close_arg(char: str, depth: int) -> int | None:
    if char in "([{":
        return depth + 1
    if char not in ")]}":
        return depth
    if depth == 1:
        return 0
    return depth - 1


def _split_args(text: str, open_at: int) -> list[str] | None:
    depth = 1
    quote = ""
    escaped = False
    buf: list[str] = []
    args: list[str] = []
    for char in text[open_at + 1 :]:
        if quote:
            buf.append(char)
            quote, escaped = _in_string(char, quote, escaped)
            continue
        if char in "\"'":
            quote = char
            buf.append(char)
            continue
        depth = _close_arg(char, depth)
        if depth == 0:
            args.append("".join(buf))
            return args
        if char == "," and depth == 1:
            args.append("".join(buf))
            buf = []
            continue
        buf.append(char)
    return None


def _second_argument(text: str, open_at: int) -> str | None:
    args = _split_args(text, open_at)
    if args is None or len(args) < 2:
        return None
    return args[1].strip()


def _decode_quoted(text: str) -> str | None:
    """Chỉ nhận đúng một chuỗi trích dẫn. Phần thừa sau dấu đóng thì không phải literal."""
    if not text or text[0] not in "\"'":
        return None
    quote = text[0]
    out: list[str] = []
    escaped = False
    for index, char in enumerate(text[1:], start=1):
        if escaped:
            out.append(char)
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if char != quote:
            out.append(char)
            continue
        if text[index + 1 :].strip():
            return None
        return "".join(out)
    return None


def _decode_long(text: str) -> str | None:
    """Chuỗi dài Lua [[...]] hoặc [=[...]=], không phần thừa sau dấu đóng."""
    matched = re.fullmatch(r"\[(=*)\[(.*)\]\1\]", text, flags=re.DOTALL)
    if matched is None:
        return None
    return matched.group(2)


def _decode_any_string(text: str) -> str | None:
    quoted = _decode_quoted(text)
    if quoted is not None:
        return quoted
    return _decode_long(text)


def _skip_short_string(text: str, index: int) -> int:
    quote = text[index]
    cursor = index + 1
    length = len(text)
    while cursor < length:
        if text[cursor] == "\\":
            cursor += 2
            continue
        if text[cursor] == quote:
            return cursor + 1
        if text[cursor] == "\n":
            return cursor
        cursor += 1
    return length


def _skip_any_string(text: str, index: int) -> int | None:
    if index < len(text) and text[index] in "\"'":
        return _skip_short_string(text, index)
    level = _long_open(text, index)
    if level is None:
        return None
    token = "]" + ("=" * level) + "]"
    close = text.find(token, index + len(token))
    if close < 0:
        return len(text)
    return close + len(token)


def _token_start(text: str, index: int) -> bool:
    if index == 0:
        return True
    previous = text[index - 1]
    return not (previous.isalnum() or previous in "_.")


def _blank_marks(text: str, marks: str) -> str:
    chars = [" " if kind == "m" else char for char, kind in zip(text, marks, strict=True)]
    return "".join(chars).strip()


def _statement_end(text: str, marks: str, start: int) -> int:
    index = start
    depth = 0
    length = len(text)
    while index < length:
        stepped, depth, done = _end_at(text, marks, index, depth)
        if done:
            return stepped
        index = stepped
    return length


def _end_at(text: str, marks: str, index: int, depth: int) -> tuple[int, int, bool]:
    if marks[index] == "m" and depth == 0:
        return index, depth, True
    if marks[index] == "m":
        return index + 1, depth, False
    if marks[index] == "s":
        skipped = _skip_any_string(text, index)
        return (len(text) if skipped is None else skipped), depth, False
    char = text[index]
    if char in "([{":
        return index + 1, depth + 1, False
    if char in ")]}":
        return index + 1, max(0, depth - 1), False
    if depth == 0 and char in ";\n":
        return index, depth, True
    return index + 1, depth, False


def _assignment_spans(text: str, marks: str) -> list[tuple[str, str]]:
    spans: list[tuple[str, str]] = []
    for matched in _NAME_EQ.finditer(text):
        start = matched.start()
        if marks[start] != "c" or not _token_start(text, start):
            continue
        end = _statement_end(text, marks, matched.end())
        expr = _blank_marks(text[matched.end() : end], marks[matched.end() : end])
        spans.append((matched.group(1), expr))
    return spans


def _note_binding(found: dict[str, Bound], name: str, kind: str, values: tuple[str, ...] | None) -> None:
    """Hai giá trị khác nhau cho một tên thì bỏ, không chọn hộ."""
    if values is None:
        found[name] = Bound("conflict", ())
        return
    fresh = Bound(kind, values)
    previous = found.get(name)
    if previous is None or previous == fresh:
        found[name] = fresh
        return
    found[name] = Bound("conflict", ())


def _literal_binding(text: str) -> tuple[str, tuple[str, ...]] | None:
    quoted = _decode_quoted(text)
    if quoted is not None:
        return "constant", (quoted,)
    long = _decode_long(text)
    if long is not None:
        return "constant", (long,)
    return None


def _format_open(text: str) -> int | None:
    if text.startswith("format(") or text.startswith("string.format("):
        return text.index("(")
    return None


def _covers_call(text: str, open_at: int) -> bool:
    depth = 0
    index = open_at
    while index < len(text):
        skipped = _skip_any_string(text, index)
        if skipped is not None:
            index = skipped
            continue
        depth, closed = _paren_at(text, index, depth)
        if closed:
            return text[index + 1 :].strip() == ""
        index += 1
    return False


def _paren_at(text: str, index: int, depth: int) -> tuple[int, bool]:
    if text[index] == "(":
        return depth + 1, False
    if text[index] == ")":
        nxt = depth - 1
        return nxt, nxt == 0
    return depth, False


def _template_of(raw: str, found: dict[str, Bound]) -> str | None:
    text = raw.strip()
    literal = _decode_any_string(text)
    if literal is not None:
        return literal
    if not _IDENT.fullmatch(text):
        return None
    bound = found.get(text)
    if bound is None or bound.kind not in {"constant", "format"} or len(bound.values) != 1:
        return None
    return bound.values[0]


def _format_template(text: str, found: dict[str, Bound]) -> tuple[bool, str | None]:
    stripped = text.strip()
    open_at = _format_open(stripped)
    if open_at is None or not _covers_call(stripped, open_at):
        return False, None
    args = _split_args(stripped, open_at)
    if not args:
        return True, None
    return True, _template_of(args[0], found)


def _format_binding(text: str, found: dict[str, Bound]) -> tuple[str, tuple[str, ...] | None] | None:
    is_format, template = _format_template(text, found)
    if not is_format:
        return None
    if template is None:
        return "conflict", None
    return "format", (template,)


def _table_strings(text: str) -> tuple[str, ...] | None:
    if len(text) < 2 or text[0] != "{" or text[-1] != "}":
        return None
    values: list[str] = []
    index = 0
    inner = text[1:-1]
    while index < len(inner):
        if inner[index] in " \t\r\n,":
            index += 1
            continue
        skipped = _skip_any_string(inner, index)
        if skipped is None:
            return None
        decoded = _decode_any_string(inner[index:skipped])
        if decoded is None or len(values) >= _MAX_ALTERNATIVES:
            return None
        values.append(decoded)
        index = skipped
    if not values:
        return None
    return tuple(values)


def _table_binding(text: str) -> tuple[str, tuple[str, ...] | None]:
    values = _table_strings(text)
    if values is None:
        return "conflict", None
    return "table", values


def _closing(text: str) -> int | None:
    if not text.startswith("["):
        return None
    depth = 0
    index = 0
    while index < len(text):
        skipped = _skip_any_string(text, index)
        if skipped is not None:
            index = skipped
            continue
        depth, closed = _bracket_at(text, index, depth)
        if closed:
            return index + 1
        index += 1
    return None


def _bracket_at(text: str, index: int, depth: int) -> tuple[int, bool]:
    if text[index] == "[":
        return depth + 1, False
    if text[index] == "]":
        nxt = depth - 1
        return nxt, nxt == 0
    return depth, False


def _index_name(text: str) -> str | None:
    stripped = text.strip()
    matched = _NAME_HEAD.match(stripped)
    if matched is None:
        return None
    rest = stripped[matched.end() :].lstrip()
    if not rest.startswith("["):
        return None
    end = _closing(rest)
    if end is None or rest[end:].strip():
        return None
    return matched.group(0)


def _table_values(name: str, found: dict[str, Bound]) -> tuple[str, ...] | None:
    bound = found.get(name)
    if bound is None or bound.kind != "table":
        return None
    return bound.values


def _split_pieces(argument: str) -> list[str] | None:
    parts: list[str] = []
    buf: list[str] = []
    index = 0
    depth = 0
    while index < len(argument):
        index, depth, split = _piece_at(argument, index, depth, buf, parts)
        if split:
            buf = []
    if not parts:
        return None
    parts.append("".join(buf))
    return parts


def _piece_at(
    argument: str,
    index: int,
    depth: int,
    buf: list[str],
    parts: list[str],
) -> tuple[int, int, bool]:
    skipped = _skip_any_string(argument, index)
    if skipped is not None:
        buf.append(argument[index:skipped])
        return skipped, depth, False
    char = argument[index]
    if char in "([{":
        buf.append(char)
        return index + 1, depth + 1, False
    if char in ")]}":
        buf.append(char)
        return index + 1, max(0, depth - 1), False
    if depth == 0 and argument.startswith("..", index):
        parts.append("".join(buf))
        return index + 2, depth, True
    buf.append(char)
    return index + 1, depth, False


def _tostring_wild(text: str) -> bool:
    """tostring(tên) là phần biến của mẫu. Lời gọi khác không được thành dấu *."""
    open_at = text.find("(")
    if open_at < 0 or not text.endswith(")"):
        return False
    if text[:open_at].strip() != "tostring":
        return False
    inner = text[open_at + 1 : -1].strip()
    return inner == "" or _IDENT.fullmatch(inner) is not None


def _piece_patterns(piece: str, found: dict[str, Bound]) -> tuple[str, ...] | None:
    text = piece.strip()
    if not text:
        return None
    literal = _decode_any_string(text)
    if literal is not None:
        return (literal,)
    is_format, template = _format_template(text, found)
    if is_format:
        return ("*",) if template is None else (template,)
    indexed = _index_name(text)
    if indexed is not None:
        values = _table_values(indexed, found)
        return ("*",) if values is None else values
    if _tostring_wild(text):
        return ("*",)
    if not _IDENT.fullmatch(text):
        return None
    bound = found.get(text)
    if bound is None or bound.kind == "conflict":
        return ("*",)
    if bound.kind == "table" or not bound.values:
        return None
    return bound.values


def _cartesian(options: list[tuple[str, ...]]) -> tuple[str, ...] | None:
    rows = [""]
    for choices in options:
        grown: list[str] = []
        for prefix in rows:
            for choice in choices:
                grown.append(prefix + choice)
        if not grown or len(grown) > _MAX_ALTERNATIVES:
            return None
        rows = grown
    return tuple(rows)


def _join_pieces(parts: list[str], found: dict[str, Bound]) -> tuple[str, ...] | None:
    options: list[tuple[str, ...]] = []
    for part in parts:
        patterns = _piece_patterns(part, found)
        if patterns is None:
            return None
        options.append(patterns)
    return _cartesian(options)


def _expression_patterns(text: str, found: dict[str, Bound]) -> tuple[str, ...] | None:
    is_format, template = _format_template(text, found)
    if is_format:
        if template is None:
            return None
        return (template,)
    parts = _split_pieces(text)
    if parts is not None:
        return _join_pieces(parts, found)
    name = _index_name(text)
    if name is None:
        return None
    return _table_values(name, found)


def _eval_expr(expr: str, found: dict[str, Bound]) -> tuple[str, tuple[str, ...] | None]:
    text = expr.strip()
    literal = _literal_binding(text)
    if literal is not None:
        return literal
    formatted = _format_binding(text, found)
    if formatted is not None:
        return formatted
    if text.startswith("{") and text.endswith("}"):
        return _table_binding(text)
    patterns = _expression_patterns(text, found)
    if patterns is None:
        return "conflict", None
    return "format", patterns


def _bindings(text: str, marks: str) -> dict[str, Bound]:
    found: dict[str, Bound] = {}
    for name, expr in _assignment_spans(text, marks):
        kind, values = _eval_expr(expr, found)
        _note_binding(found, name, kind, values)
    return found


def _resolve_name(name: str, found: dict[str, Bound]) -> tuple[str, str]:
    bound = found.get(name)
    if bound is None or bound.kind == "conflict" or not bound.values:
        return "unresolved", ""
    if bound.kind == "constant" and len(bound.values) == 1:
        return "constant", bound.values[0]
    if bound.kind == "format" and len(bound.values) <= _MAX_ALTERNATIVES:
        return "format", "|".join(bound.values)
    return "unresolved", ""


def _resolve(argument: str, found: dict[str, Bound]) -> tuple[str, str]:
    text = argument.strip()
    literal = _decode_any_string(text)
    if literal is not None and _decode_quoted(text) is not None:
        return "literal", literal
    if _decode_long(text) is not None:
        return "literal", literal or ""
    if _IDENT.fullmatch(text):
        return _resolve_name(text, found)
    patterns = _expression_patterns(text, found)
    if patterns is None or not patterns or len(patterns) > _MAX_ALTERNATIVES:
        return "unresolved", ""
    return "format", "|".join(patterns)


def _calls_in(
    script: str,
    number: int,
    source: str,
    visible: str,
    commented: bool,
    bindings: Bindings,
) -> list[LoadCall]:
    rows: list[LoadCall] = []
    for match in _CALL.finditer(visible):
        argument = _second_argument(source, match.end() - 1)
        if argument is None:
            argument = ""
        if not commented and "\t" in argument:
            raise ValueError(f"{script}:{number}: đối số có tab")
        how, resolved = ("unresolved", "") if commented else _resolve(argument, bindings)
        kind = match.group(1).lower()
        rows.append(LoadCall(script, number, kind, argument, resolved, how, commented))
    return rows


def _line_calls(script: str, number: int, line: str, mark: str, bindings: Bindings) -> list[LoadCall]:
    code = _project(line, mark, "c")
    comment = _project(line, mark, "m")
    rows = _calls_in(script, number, line, code, False, bindings)
    rows.extend(_calls_in(script, number, line, comment, True, bindings))
    return rows


def _read_lua(path: Path, script_root: Path) -> tuple[str, str]:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise ValueError(f"{path.name}:1: có BOM")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ValueError(f"{path.name}:{exc.start}: byte UTF-8 hỏng") from exc
    relative = path.relative_to(script_root).as_posix()
    return relative, text


def _take_calls(rows: list[LoadCall], commented: int, found: list[LoadCall]) -> int:
    for call in found:
        rows.append(call)
        if call.commented:
            commented += 1
    return commented


def _calls_of_file(rows: list[LoadCall], commented: int, path: Path, script_root: Path) -> int:
    relative, text = _read_lua(path, script_root)
    marks = _classify(text)
    bindings = _bindings(text, marks)
    number = 0
    for line, mark in _paired_lines(text, marks):
        number += 1
        calls = _line_calls(relative, number, line, mark, bindings)
        commented = _take_calls(rows, commented, calls)
    return commented


def collect_calls(script_root: Path) -> tuple[list[LoadCall], int]:
    """Mọi lời gọi, kể cả chú thích. Số thứ hai là số lời gọi trong chú thích."""
    if not script_root.is_dir():
        raise ValueError(f"{script_root}:1: không thấy Public/Data/Script")
    rows: list[LoadCall] = []
    commented = 0
    for path in sorted(script_root.rglob("*.lua")):
        if not path.is_file():
            continue
        commented = _calls_of_file(rows, commented, path, script_root)
    rows.sort(key=lambda call: (call.script, call.line, call.kind, call.argument))
    return rows, commented


def _source_label(script_root: Path) -> str:
    count = sum(1 for path in script_root.rglob("*.lua") if path.is_file())
    return f"Public/Data/Script/*.lua ({count} tệp)"


def _compile_glob(pattern: str) -> re.Pattern[str]:
    pieces = _pattern_glob(pattern).casefold().split("*")
    body = ".*".join(re.escape(piece) for piece in pieces)
    return re.compile(body + r"\Z")


def _format_hits_name(resolved: str, name: str, cache: dict[str, re.Pattern[str]]) -> bool:
    folded = name.casefold()
    for part in resolved.split("|"):
        compiled = cache.get(part)
        if compiled is None:
            compiled = _compile_glob(part)
            cache[part] = compiled
        if compiled.fullmatch(folded):
            return True
    return False


def _count_format(resolved: str, names: tuple[str, ...], cache: dict[str, re.Pattern[str]]) -> int:
    total = 0
    for name in names:
        if _format_hits_name(resolved, name, cache):
            total += 1
    return total


def _files_on_disk(how: str, resolved: str, names: tuple[str, ...], cache: dict[str, re.Pattern[str]]) -> str:
    """Số tệp Public/Scene khớp resolved. unresolved để trống."""
    if how == "unresolved":
        return ""
    if how == "format":
        return str(_count_format(resolved, names, cache))
    target = resolved.casefold()
    return str(sum(1 for name in names if name.casefold() == target))


def _scene_filenames(scene_root: Path) -> tuple[str, ...]:
    if not scene_root.is_dir():
        return ()
    names = [path.name for path in scene_root.iterdir() if path.is_file()]
    names.sort()
    return tuple(names)


def _active_rows(calls: list[LoadCall], names: tuple[str, ...]) -> list[tuple[str, ...]]:
    rows = []
    cache: dict[str, re.Pattern[str]] = {}
    for call in calls:
        if call.commented:
            continue
        count = _files_on_disk(call.how, call.resolved, names, cache)
        rows.append((call.script, str(call.line), call.kind, call.argument, call.resolved, call.how, count))
    return rows


def _level_verdict(row: LevelRow) -> str:
    if not row.pointed:
        return "unpointed"
    if not row.map_known:
        return "map_unknown"
    if set(row.script_scenes) != set(row.name_scenes):
        return "mismatch"
    return "same"


def _level_body(rows: list[LevelRow]) -> list[tuple[str, ...]]:
    body = []
    for row in rows:
        name_scenes = ";".join(row.name_scenes)
        script_scenes = ";".join(row.script_scenes)
        body.append((row.filename, name_scenes, script_scenes, _level_verdict(row)))
    return body


def _write_exports(legacy_root: Path, destination: Path, calls: list[LoadCall], source: str) -> None:
    names = _scene_filenames(legacy_root / "Public" / "Scene")
    rows = _active_rows(calls, names)
    level_rows = _level_body(compare_level_files(legacy_root, calls))
    tsv_file.prepare_directory(destination, TOOL, keep_tools=("import_legacy.py",))
    tsv_file.write_table(destination / "scene_load_refs.tsv", source, TOOL, TYPES, COLUMNS, rows)
    tsv_file.write_table(
        destination / "scene_level_files.tsv",
        "Public/Scene",
        TOOL,
        LEVEL_TYPES,
        LEVEL_COLUMNS,
        level_rows,
    )


def export_refs(legacy_root: Path, destination: Path, check_only: bool = False) -> tuple[list[LoadCall], int, str]:
    """Đọc script và ghi hai bảng cảnh. --check không đụng thư mục đích."""
    script_root = Path(legacy_root) / "Public" / "Data" / "Script"
    calls, commented = collect_calls(script_root)
    source = _source_label(script_root)
    if check_only:
        return calls, commented, source
    _write_exports(Path(legacy_root), destination, calls, source)
    return calls, commented, source


def _how_counts(calls: list[LoadCall]) -> dict[str, int]:
    counts = {how: 0 for how in sorted(HOWS)}
    for call in calls:
        if call.commented:
            continue
        counts[call.how] = counts.get(call.how, 0) + 1
    return counts


def _print_level(rows: list[LevelRow]) -> None:
    counts = {name: 0 for name in _LEVEL_VERDICTS}
    for row in rows:
        verdict = _level_verdict(row)
        counts[verdict] = counts.get(verdict, 0) + 1
    print(f"tệp cấp: {len(rows)}")
    for name in _LEVEL_VERDICTS:
        print(f"  {name} {counts[name]}")


def _print_summary(calls: list[LoadCall], commented: int) -> None:
    active = [call for call in calls if not call.commented]
    print(f"lời gọi: {len(active)}")
    print(f"chú thích bỏ qua: {commented}")
    print("how:")
    for how, count in _how_counts(calls).items():
        print(f"  {how} {count}")


def _pattern_glob(pattern: str) -> str:
    return _FORMAT_TOKEN.sub("*", pattern)


def _alternative_hits(pattern: str, name: str) -> bool:
    glob = _pattern_glob(pattern).casefold()
    folded = name.casefold()
    if "*" not in glob:
        return glob == folded
    pieces = [piece for piece in glob.split("*") if piece and piece != ".ini"]
    if not pieces or max(len(piece) for piece in pieces) < 8:
        return False
    return fnmatch.fnmatchcase(folded, glob)


def _pattern_hits(pattern: str, name: str) -> bool:
    return any(_alternative_hits(part, name) for part in pattern.split("|"))


def _points_at(call: LoadCall, filename: str) -> bool:
    if call.commented or call.kind == "map":
        return False
    if call.how in {"literal", "constant"}:
        return call.resolved.casefold() == filename.casefold()
    if call.how == "format":
        return _pattern_hits(call.resolved, filename)
    return False


def _take_system(section: scene_read.IniSection, stem: str, referenced: NameSets, nav_scenes: NameSets) -> None:
    if section.name != "System":
        return
    for key in section.keys:
        referenced.setdefault(key.value, set()).add(stem)
        if key.name == "navmapname":
            nav_scenes.setdefault(key.value, set()).add(stem)


def _scn_links(scene_root: Path) -> tuple[NameSets, NameSets, set[str]]:
    referenced: NameSets = {}
    nav_scenes: NameSets = {}
    stems: set[str] = set()
    for path in sorted(scene_root.glob("*.scn")):
        stem = path.name[: -len(".scn")]
        stems.add(stem)
        parsed = scene_read.parse_ini(path)
        for section in parsed.sections:
            _take_system(section, stem, referenced, nav_scenes)
    return referenced, nav_scenes, stems


def _name_scenes(filename: str, referenced: NameSets, stems: set[str]) -> tuple[str, ...]:
    owners = referenced.get(filename)
    if owners:
        return tuple(sorted(owners))
    owner = kinds.longest_stem(filename, stems)
    if owner is None:
        return ()
    return (owner,)


def _scene_of_map(call: LoadCall, nav_scenes: NameSets) -> set[str]:
    if call.how not in {"literal", "constant"}:
        return set()
    return set(nav_scenes.get(call.resolved, ()))


def _script_scenes(
    filename: str,
    calls: list[LoadCall],
    maps: dict[str, list[LoadCall]],
    nav_scenes: NameSets,
) -> tuple[set[str], bool]:
    scripts = {call.script for call in calls if _points_at(call, filename)}
    if not scripts:
        return set(), False
    found: set[str] = set()
    known = False
    for script in scripts:
        for call in maps.get(script, []):
            scenes = _scene_of_map(call, nav_scenes)
            if scenes:
                known = True
                found.update(scenes)
    return found, known


def compare_level_files(legacy_root: Path, calls: list[LoadCall]) -> list[LevelRow]:
    """1344 tệp quái theo cấp, nhóm, lối vào: script có trỏ không, cảnh có trùng không."""
    scene_root = Path(legacy_root) / "Public" / "Scene"
    if not scene_root.is_dir():
        return []
    referenced, nav_scenes, stems = _scn_links(scene_root)
    maps: dict[str, list[LoadCall]] = {}
    for call in calls:
        if call.commented or call.kind != "map":
            continue
        maps.setdefault(call.script, []).append(call)
    rows: list[LevelRow] = []
    for path in sorted(scene_root.iterdir()):
        if not path.is_file() or kinds.classify_name(path.name) not in _LEVEL_KINDS:
            continue
        name_scenes = _name_scenes(path.name, referenced, stems)
        script_scenes, known = _script_scenes(path.name, calls, maps, nav_scenes)
        pointed = any(_points_at(call, path.name) for call in calls)
        rows.append(LevelRow(path.name, name_scenes, tuple(sorted(script_scenes)), pointed, known or not pointed))
    return rows


def _format_level_lines(rows: list[LevelRow]) -> list[str]:
    pointed = [row for row in rows if row.pointed]
    missing = [row.filename for row in rows if not row.pointed]
    unknown = [row.filename for row in pointed if not row.map_known]
    mismatch = []
    for row in pointed:
        if not row.map_known:
            continue
        if set(row.script_scenes) != set(row.name_scenes):
            left = ",".join(row.name_scenes) or "-"
            right = ",".join(row.script_scenes) or "-"
            mismatch.append(f"{row.filename} tên={left} script={right}")
    lines = [
        f"tệp quái theo cấp/nhóm/lối vào: {len(rows)}",
        f"script trỏ tới: {len(pointed)}",
        f"không script nào trỏ tới: {len(missing)}",
        f"có trỏ nhưng không suy được Map: {len(unknown)}",
        f"lệch cảnh: {len(mismatch)}",
    ]
    lines.extend(mismatch)
    lines.append("không trỏ:")
    lines.extend(missing)
    return lines


def _parse_args(arguments: list[str]) -> tuple[Path, Path, bool]:
    check_only = "--check" in arguments
    positional = [arg for arg in arguments if arg != "--check"]
    if len(positional) != 2:
        raise ValueError("cần thư mục tlbb và thư mục bảng máy chủ")
    return Path(positional[0]), Path(positional[1]), check_only


def _utf8_stdout() -> None:
    reconfigure = getattr(sys.stdout, "reconfigure", None)
    if reconfigure is None:
        return
    try:
        reconfigure(encoding="utf-8")
    except (OSError, ValueError):
        return


def main(argv: list[str] | None = None) -> int:
    """Điểm vào dòng lệnh. In số lời gọi theo how."""
    _utf8_stdout()
    arguments = list(sys.argv[1:] if argv is None else argv)
    if "--help" in arguments or "-h" in arguments:
        print(HELP)
        return 0
    try:
        legacy, destination, check_only = _parse_args(arguments)
        calls, commented, _source = export_refs(legacy, destination, check_only)
    except (ValueError, tsv_file.TsvError, scene_read.SceneError) as exc:
        print(f"scene_refs.py:1: {exc}")
        return 1
    _print_summary(calls, commented)
    _print_level(compare_level_files(legacy, calls))
    return 0


if __name__ == "__main__":
    sys.exit(main())
