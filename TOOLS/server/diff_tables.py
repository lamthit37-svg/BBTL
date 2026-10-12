"""Đo hiệu id và độ phủ tham chiếu của bảng đã sinh.

So id theo kiểu của cột đầu, cùng cách export_tables ghép dòng. Mẫu có *
chỉ trong một đoạn đường dẫn. * của cột cha lấy chuỗi * đầu tiên của cột con.
Ô rỗng không trỏ. first_missing nối bằng dấu chấm phẩy, không thêm dấu cách.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

import export_tables
import table_refs
import tsv_file

_KIND = {"INT": "int", "FLOAT": "float", "STRING": "text"}
HELP = """\
cách dùng: python TOOLS/server/diff_tables.py <tlbb> <gốc SERVER> [--refs <thư mục>]
[--output <thư mục>] [--names <tsv>] [--check]

Ghi table_id_diff.tsv và table_ref_coverage.tsv. --check không ghi tệp.
Thoát 0 khi sạch, 1 khi có lỗi.
"""
_DIFF_COLUMNS = (
    "source",
    "target",
    "ids_2026",
    "ids_legacy",
    "common",
    "only_2026",
    "only_legacy",
)
_DIFF_TYPES = ("text", "text", "int", "int", "int", "int", "int")
_COVER_COLUMNS = (
    "child",
    "child_column",
    "parent",
    "parent_column",
    "child_files",
    "child_rows",
    "references",
    "distinct_values",
    "missing_values",
    "missing_rows",
    "first_missing",
)
_COVER_TYPES = ("text", "text", "text", "text", "int", "int", "int", "int", "int", "int", "text")
_Rows = list[tuple[str, ...]]


@dataclass(frozen=True)
class _Options:
    legacy: Path
    server: Path
    refs: Path
    output: Path
    names: Path
    check: bool


@dataclass(frozen=True)
class _Cover:
    files: int
    rows: int
    references: int
    distinct: int
    missing_values: int
    missing_rows: int
    first_missing: str


def id_key(kind: str, cell: str) -> object | None:
    """Khoá id theo kiểu cột. Ô rỗng không phải id."""
    if cell == "":
        return None
    if kind == "int":
        return _number_key(cell)
    if kind == "float":
        return _float_key(cell)
    if export_tables._INT.fullmatch(cell):
        return _number_key(cell)
    return cell


def _number_key(cell: str) -> object:
    number = export_tables._atoi(cell)
    if number is None:
        return ("overflow", cell)
    return number


def _float_key(cell: str) -> object:
    bits = export_tables._float_bits(cell)
    if bits is None:
        return ("float", cell)
    return ("bits", bits)


def paired_sources(rows: tuple[tsv_file.NameRow, ...]) -> tuple[tuple[str, str], ...]:
    """Cặp public_config reference với bảng client cùng đường dẫn nguồn."""
    client = {row.source: row.target for row in rows if row.tree == "client_2026" and row.fate == "table"}
    found: list[tuple[str, str]] = []
    for row in rows:
        if row.tree != "public_config" or row.fate != "reference":
            continue
        target = client.get(row.source)
        if target is None:
            raise ValueError(f"{row.source}:1: không có bảng client cùng tên")
        found.append((row.source, target))
    return tuple(sorted(found))


def _under_project(path: Path) -> str:
    root = Path(__file__).resolve().parents[2]
    resolved = path.resolve()
    try:
        return resolved.relative_to(root).as_posix()
    except ValueError:
        return resolved.name


def _decode_legacy(path: Path, source: str) -> str:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise ValueError(f"{source}:1: bản đối chiếu có BOM")
    data = data.replace(b"\r\n", b"\n")
    if b"\r" in data:
        raise ValueError(f"{source}:1: bản đối chiếu có CR không thuộc CRLF")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        line = data[: exc.start].count(b"\n") + 1
        raise ValueError(f"{source}:{line}: byte UTF-8 hỏng") from exc


def _content_lines(text: str) -> list[tuple[int, str]]:
    numbered = enumerate(text.split("\n"), start=1)
    return [(number, line) for number, line in numbered if line]


def _legacy_kind(text: str, source: str) -> tuple[str, list[tuple[int, str]]]:
    lines = _content_lines(text)
    if len(lines) < 2:
        raise ValueError(f"{source}:1: bản đối chiếu thiếu dòng tên cột")
    token = lines[0][1].split("\t")[0]
    kind = _KIND.get(token, token)
    body = []
    for number, line in lines[2:]:
        if line.startswith("#"):
            continue
        body.append((number, line.split("\t")[0]))
    return kind, body


def _remember_id(keys: set[object], kind: str, cell: str, source: str, number: int) -> None:
    try:
        key = id_key(kind, cell)
    except ValueError as exc:
        raise ValueError(f"{source}:{number}: {exc}") from exc
    if key is not None:
        keys.add(key)


def _legacy_ids(path: Path, source: str) -> set[object]:
    kind, body = _legacy_kind(_decode_legacy(path, source), source)
    keys: set[object] = set()
    for number, cell in body:
        _remember_id(keys, kind, cell, source, number)
    return keys


def _table_line(path: Path, index: int) -> int:
    text = path.read_text(encoding="utf-8")
    header = False
    seen = 0
    for number, line in enumerate(text.split("\n"), start=1):
        if line == "" or (not header and line.startswith("#")):
            continue
        if not header:
            header = True
            continue
        seen += 1
        if seen == index:
            return number
    return index


def _table_ids(path: Path) -> set[object]:
    table = tsv_file.read_table(path)
    shown = _under_project(path)
    keys: set[object] = set()
    for index, row in enumerate(table.rows, start=1):
        try:
            key = id_key(table.types[0], row[0])
        except ValueError as exc:
            raise ValueError(f"{shown}:{_table_line(path, index)}: {exc}") from exc
        if key is not None:
            keys.add(key)
    return keys


def _diff_row(server: Path, legacy_root: Path, source: str, target: str) -> tuple[str, ...]:
    new_ids = _table_ids(server / target)
    old_ids = _legacy_ids(legacy_root / "Public" / "Config" / source, source)
    common = len(new_ids & old_ids)
    cells = (
        source,
        target,
        str(len(new_ids)),
        str(len(old_ids)),
        str(common),
        str(len(new_ids) - common),
        str(len(old_ids) - common),
    )
    return cells


def _compile(pattern: str) -> re.Pattern[str]:
    parts: list[str] = []
    for segment in pattern.split("/"):
        if "*" not in segment:
            parts.append(re.escape(segment))
            continue
        left, right = segment.split("*", 1)
        parts.append(re.escape(left) + "([^/]*)" + re.escape(right))
    return re.compile("^" + "/".join(parts) + "$")


def _matched_files(root: Path, pattern: str) -> list[tuple[str, Path]]:
    regex = _compile(pattern)
    first = pattern.split("/", 1)[0]
    base = root / first if "*" not in first else root
    if not base.is_dir():
        return []
    found: list[tuple[str, Path]] = []
    for path in sorted(base.rglob("*.tsv")):
        relative = path.relative_to(root).as_posix()
        if regex.fullmatch(relative):
            found.append((relative, path))
    return found


def _parent_of(child: str, child_pattern: str, parent_pattern: str) -> str:
    if "*" not in parent_pattern:
        return parent_pattern
    matched = _compile(child_pattern).fullmatch(child)
    if matched is None:
        raise ValueError(f"{child}:1: không khớp mẫu cột con")
    return parent_pattern.replace("*", matched.group(1), 1)


class _Store:
    def __init__(self) -> None:
        self.tables: dict[Path, tsv_file.Table] = {}
        self.files: dict[str, list[tuple[str, Path]]] = {}

    def table(self, path: Path) -> tsv_file.Table:
        """Đọc mỗi tệp một lần. Cùng đường dẫn trả lại bảng đã nhớ."""
        found = self.tables.get(path)
        if found is not None:
            return found
        loaded = tsv_file.read_table(path)
        self.tables[path] = loaded
        return loaded

    def matched(self, root: Path, pattern: str) -> list[tuple[str, Path]]:
        """Tệp khớp mẫu, nhớ theo nguyên văn mẫu."""
        found = self.files.get(pattern)
        if found is not None:
            return found
        loaded = _matched_files(root, pattern)
        self.files[pattern] = loaded
        return loaded


def _column(table: tsv_file.Table, name: str) -> tuple[str, list[str]] | None:
    if name not in table.columns:
        return None
    index = table.columns.index(name)
    values = [row[index] for row in table.rows]
    return table.types[index], values


def _key_problem(values: list[str]) -> str:
    counts: dict[str, int] = {}
    empty = False
    for value in values:
        if value == "":
            empty = True
            continue
        counts[value] = counts.get(value, 0) + 1
    repeated = sum(1 for count in counts.values() if count > 1)
    if empty:
        return "có ô rỗng"
    if repeated:
        return f"lặp {repeated} giá trị"
    return ""


def _value_key(kind: str, value: str) -> tuple[object, ...]:
    if kind != "int":
        return (value.encode("utf-8"),)
    number = export_tables._atoi(value)
    if number is None:
        return (1, value.encode("utf-8"))
    return (0, number, value.encode("utf-8"))


def _sort_missing(kind: str, starred: bool, missing: set[tuple[str, str]]) -> str:
    if starred:
        ordered = sorted(missing, key=lambda item: (item[0].encode("utf-8"), _value_key(kind, item[1])))
        shown = [f"{capture}:{value}" for capture, value in ordered[:5]]
        return ";".join(shown)
    ordered_values = sorted((item[1] for item in missing), key=lambda value: _value_key(kind, value))
    return ";".join(ordered_values[:5])


def _absent_set(text: str) -> set[str]:
    if text == "":
        return set()
    return set(text.split(";"))


def _measure_one(
    kind: str,
    values: list[str],
    capture: str,
    keys: set[str] | None,
    absent: set[str],
    bag: dict[str, int],
    distinct: set[tuple[str, str]],
    missing: set[tuple[str, str]],
) -> None:
    bag["rows"] += len(values)
    for value in values:
        if value == "" or value in absent:
            continue
        bag["references"] += 1
        pair = (capture, value)
        distinct.add(pair)
        if keys is None or value not in keys:
            missing.add(pair)
            bag["missing_rows"] += 1


def _parent_keys(
    store: _Store,
    server: Path,
    relative: str,
    column: str,
    where: str,
    errors: list[str],
) -> set[str] | None:
    path = server / relative
    if not path.is_file():
        return None
    table = store.table(path)
    found = _column(table, column)
    if found is None:
        errors.append(f"{relative}:1: không có cột {column}")
        return set()
    kind, values = found
    if kind == "float":
        errors.append(f"{where}: cột cha {column} là float")
        return set()
    problem = _key_problem(values)
    if problem:
        errors.append(f"{where}: cột cha {column} {problem}")
    return {value for value in values if value != ""}


def _capture(pattern: str, relative: str, starred: bool) -> str:
    """Chuỗi * đầu tiên. Mẫu không có * thì chuỗi rỗng."""
    if not starred:
        return ""
    matched = _compile(pattern).fullmatch(relative)
    if matched is None:
        return ""
    return matched.group(1)


def _child_kind(
    store: _Store, path: Path, column: str, relative: str, errors: list[str]
) -> tuple[str, list[str]] | None:
    table = store.table(path)
    found = _column(table, column)
    if found is None:
        errors.append(f"{relative}:1: không có cột {column}")
        return None
    kind, values = found
    if kind == "float":
        errors.append(f"{relative}:1: cột {column} là float")
        return None
    return kind, values


def _cover_row(store: _Store, server: Path, row: table_refs.RefRow, errors: list[str]) -> tuple[str, ...] | None:
    children = store.matched(server, row.child)
    if not children:
        errors.append(f"refs/{row.source}:{row.line}: mẫu không khớp tệp nào")
        return None
    if not store.matched(server, row.parent):
        errors.append(f"refs/{row.source}:{row.line}: mẫu không khớp tệp nào")
        return None
    where = f"refs/{row.source}:{row.line}"
    bag = {"rows": 0, "references": 0, "missing_rows": 0}
    distinct: set[tuple[str, str]] = set()
    missing: set[tuple[str, str]] = set()
    absent = _absent_set(row.absent)
    kind = ""
    starred = "*" in row.parent
    for relative, path in children:
        loaded = _child_kind(store, path, row.child_column, relative, errors)
        if loaded is None:
            continue
        child_kind, values = loaded
        if kind == "":
            kind = child_kind
        parent = _parent_of(relative, row.child, row.parent)
        keys = _parent_keys(store, server, parent, row.parent_column, where, errors)
        capture = _capture(row.child, relative, starred)
        _measure_one(kind, values, capture, keys, absent, bag, distinct, missing)
    if kind == "":
        return None
    first = _sort_missing(kind, starred, missing)
    return (
        row.child,
        row.child_column,
        row.parent,
        row.parent_column,
        str(len(children)),
        str(bag["rows"]),
        str(bag["references"]),
        str(len(distinct)),
        str(len(missing)),
        str(bag["missing_rows"]),
        first,
    )


def _type_error(store: _Store, server: Path, row: table_refs.RefRow) -> str:
    children = store.matched(server, row.child)
    child_kind = ""
    parent_kind = ""
    for relative, path in children:
        child = _column(store.table(path), row.child_column)
        if child is None:
            continue
        child_kind = child[0]
        parent_path = server / _parent_of(relative, row.child, row.parent)
        if not parent_path.is_file():
            continue
        parent = _column(store.table(parent_path), row.parent_column)
        if parent is None:
            continue
        parent_kind = parent[0]
        if child_kind != parent_kind:
            return f"refs/{row.source}:{row.line}: hai cột khác kiểu"
    if child_kind == "float" or parent_kind == "float":
        return f"refs/{row.source}:{row.line}: cột float không được tham chiếu"
    return ""


def _mismatch(row: table_refs.RefRow, measured: str) -> str:
    if measured == str(row.known_missing):
        return ""
    return f"refs/{row.source}:{row.line}: missing_values {measured} khác known_missing {row.known_missing}"


def _type_clash(message: str) -> bool:
    return message.endswith("hai cột khác kiểu")


def _one_cover(
    store: _Store,
    server: Path,
    row: table_refs.RefRow,
    check: bool,
    built: _Rows,
    errors: list[str],
) -> None:
    typed = _type_error(store, server, row)
    if typed:
        errors.append(typed)
    if typed and not _type_clash(typed):
        return
    covered = _cover_row(store, server, row, errors)
    if covered is None:
        return
    built.append(covered)
    if not check:
        return
    mismatch = _mismatch(row, covered[8])
    if mismatch:
        errors.append(mismatch)


def _cover_rows(server: Path, refs: tuple[table_refs.RefRow, ...], check: bool) -> tuple[_Rows, list[str]]:
    built: _Rows = []
    errors: list[str] = []
    store = _Store()
    for row in refs:
        _one_cover(store, server, row, check, built, errors)
    return built, errors


def _diff_rows(options: _Options, pairs: tuple[tuple[str, str], ...]) -> list[tuple[str, ...]]:
    rows = []
    for source, target in pairs:
        rows.append(_diff_row(options.server, options.legacy, source, target))
    return rows


def _print_summary(diff_rows: list[tuple[str, ...]], cover_rows: list[tuple[str, ...]]) -> None:
    totals = [0, 0, 0, 0, 0]
    for row in diff_rows:
        for index in range(5):
            totals[index] += int(row[index + 2])
    missing_lines = sum(1 for row in cover_rows if row[8] != "0")
    print(f"cặp: {len(diff_rows)}")
    print(f"ids_2026: {totals[0]}")
    print(f"ids_legacy: {totals[1]}")
    print(f"common: {totals[2]}")
    print(f"only_2026: {totals[3]}")
    print(f"only_legacy: {totals[4]}")
    print(f"dòng tham chiếu: {len(cover_rows)}")
    print(f"dòng có giá trị thiếu: {missing_lines}")


def _diff_source(rows: list[tuple[str, ...]]) -> str:
    count = len(rows)
    if count == 1:
        return f"public_config/{rows[0][0]} (1 tệp)"
    return f"public_config/* ({count} tệp)"


def _cover_source(directory: Path) -> str:
    count = len(list(directory.glob("*.tsv")))
    return f"{_under_project(directory)}/*.tsv ({count} tệp)"


def _write(options: _Options, diff_rows: list[tuple[str, ...]], cover_rows: list[tuple[str, ...]]) -> None:
    options.output.mkdir(parents=True, exist_ok=True)
    tsv_file.write_table(
        options.output / "table_id_diff.tsv",
        _diff_source(diff_rows),
        "diff_tables.py",
        _DIFF_TYPES,
        _DIFF_COLUMNS,
        diff_rows,
    )
    tsv_file.write_table(
        options.output / "table_ref_coverage.tsv",
        _cover_source(options.refs),
        "diff_tables.py",
        _COVER_TYPES,
        _COVER_COLUMNS,
        cover_rows,
    )


def _need(args: list[str], index: int) -> str:
    if index + 1 >= len(args) or args[index + 1].startswith("-"):
        raise ValueError(f"diff_tables.py:1: thiếu giá trị cho {args[index]}")
    return args[index + 1]


def _parse(args: list[str]) -> _Options:
    check = False
    refs = ""
    output = ""
    names = ""
    positionals: list[str] = []
    index = 0
    while index < len(args):
        arg = args[index]
        if arg == "--check":
            check = True
            index += 1
            continue
        if arg in ("--refs", "--output", "--names"):
            value = _need(args, index)
            if arg == "--refs":
                refs = value
            elif arg == "--output":
                output = value
            else:
                names = value
            index += 2
            continue
        if arg.startswith("-"):
            raise ValueError(f"diff_tables.py:1: không rõ đối số: {arg}")
        positionals.append(arg)
        index += 1
    if len(positionals) != 2:
        raise ValueError("diff_tables.py:1: cần thư mục tlbb và gốc SERVER")
    here = Path(__file__).resolve().parent
    return _Options(
        Path(positionals[0]),
        Path(positionals[1]),
        Path(refs) if refs else here / "refs",
        Path(output) if output else here,
        Path(names) if names else here / "table_names.tsv",
        check,
    )


def _utf8_stdout() -> None:
    reconfigure = getattr(sys.stdout, "reconfigure", None)
    if reconfigure is None:
        return
    try:
        reconfigure(encoding="utf-8")
    except (OSError, ValueError):
        return


def _require_refs(directory: Path) -> None:
    if directory.is_dir():
        return
    raise ValueError(f"{_under_project(directory)}:1: thư mục refs không tồn tại")


def main(argv: list[str] | None = None) -> int:
    """Đo và, nếu không --check, ghi hai bảng. Lỗi hình dạng thì không ghi thiếu dòng."""
    _utf8_stdout()
    arguments = list(sys.argv[1:] if argv is None else argv)
    if "--help" in arguments or "-h" in arguments:
        print(HELP)
        return 0
    try:
        options = _parse(arguments)
        _require_refs(options.refs)
        pairs = paired_sources(tsv_file.read_name_map(options.names))
        diff_rows = _diff_rows(options, pairs)
        refs = table_refs.read_refs(options.refs)
        cover_rows, errors = _cover_rows(options.server, refs, options.check)
    except (ValueError, tsv_file.TsvError, OSError) as exc:
        print(exc)
        return 1
    _print_summary(diff_rows, cover_rows)
    for error in errors:
        print(error)
    complete = len(cover_rows) == len(refs)
    if not options.check and complete:
        _write(options, diff_rows, cover_rows)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
