"""Kê mọi tệp trong Config của client 2026 và ghi lược đồ từng bảng DBC.

  python TOOLS/server/table_census.py <_raw>
  python TOOLS/server/table_census.py <_raw> --check

Đọc DBC bằng TOOLS/content/dbc.py. Tệp .txt là bảng; tệp khác chỉ được phân loại theo
table_names.tsv. --check không ghi. Thoát 0 khi sạch, 1 khi có lỗi; mỗi lỗi một dòng
"tệp:dòng: nội dung".
"""
from __future__ import annotations

import argparse
import hashlib
import struct
import sys
import time
from dataclasses import dataclass
from pathlib import Path

CONTENT = Path(__file__).resolve().parents[1] / "content"
if str(CONTENT) not in sys.path:
    sys.path.insert(0, str(CONTENT))

import dbc
import tsv_file

MAGIC = 0xDDBBCC00
KIND = {dbc.INT: "int", dbc.FLOAT: "float", dbc.STRING: "text"}
CENSUS_COLUMNS = ("source", "column_count", "row_count", "types", "sha256")
CENSUS_TYPES = ("text", "int", "int", "text", "text")


@dataclass(frozen=True)
class CensusRow:
    source: str
    column_count: int
    row_count: int
    types: str
    sha256: str


@dataclass(frozen=True)
class CensusResult:
    rows: tuple[CensusRow, ...]
    counts: dict[str, int]
    errors: tuple[str, ...]
    directories: int
    unclassified_directories: int
    records: int


def _fail(source: str, line: int, message: str) -> ValueError:
    return ValueError(f"{source}:{line}: {message}")


def read_dbc(path: Path, source: str) -> dbc.Dbc:
    """Đọc một DBC. Sai magic, cụt hoặc đuôi thừa thì lỗi, không cắt bớt."""
    data = path.read_bytes()
    if len(data) < 16 or struct.unpack_from("<I", data, 0)[0] != MAGIC:
        raise _fail(source, 1, "sai magic")
    columns, rows, strings = struct.unpack_from("<III", data, 4)
    need = 16 + 4 * columns + 4 * columns * rows + strings
    if columns == 0 or strings == 0 or need > len(data):
        raise _fail(source, 1, "tệp cụt")
    if len(data) != need:
        extra = len(data) - need
        raise _fail(source, 1, f"còn {extra} byte ngoài bảng")
    if data[-1] != 0:
        raise _fail(source, 1, "byte cuối khối chuỗi không phải NUL")
    try:
        return dbc.read(str(path), source)
    except dbc.DbcError as exc:
        raise _fail(source, 1, str(exc)) from exc


def _client_rows(names_path: Path) -> tuple[tsv_file.NameRow, ...]:
    rows = [row for row in tsv_file.read_name_map(names_path) if row.tree == "client_2026"]
    return tuple(sorted(rows, key=lambda row: row.source))


def _disk_files(config: Path) -> tuple[str, ...]:
    found = [path.relative_to(config).as_posix() for path in config.rglob("*") if path.is_file()]
    return tuple(sorted(found))


def _empty_directories(config: Path) -> tuple[str, ...]:
    found = []
    for path in sorted(item for item in config.rglob("*") if item.is_dir()):
        if not any(child.is_file() for child in path.rglob("*")):
            found.append(path.relative_to(config).as_posix())
    return tuple(found)


def _coverage(config: Path, listed: tuple[tsv_file.NameRow, ...]) -> tuple[dict[str, int], tuple[str, ...], int, int]:
    disk = set(_disk_files(config))
    errors = []
    seen: set[str] = set()
    counts: dict[str, int] = {}
    for row in listed:
        if row.source in seen:
            errors.append(f"{row.source}:1: phân loại trùng")
        seen.add(row.source)
        if row.source not in disk:
            errors.append(f"{row.source}:1: không có trên đĩa")
            continue
        counts[row.fate] = counts.get(row.fate, 0) + 1
    for source in sorted(disk - seen):
        errors.append(f"{source}:1: chưa phân loại")
    empty = _empty_directories(config)
    for source in empty:
        errors.append(f"{source}:1: thư mục trống, chưa phân loại")
    directories = sum(1 for item in config.rglob("*") if item.is_dir())
    return counts, tuple(errors), directories, len(empty)


def coverage(
    config: Path, listed: tuple[tsv_file.NameRow, ...]
) -> tuple[dict[str, int], tuple[str, ...], int, int]:
    """Đếm phủ tệp Config: số theo fate, lỗi, số thư mục và số thư mục trống."""
    return _coverage(config, listed)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        chunk = handle.read(1024 * 1024)
        while chunk:
            digest.update(chunk)
            chunk = handle.read(1024 * 1024)
    return digest.hexdigest()


def _census_row(config: Path, source: str) -> CensusRow:
    table = read_dbc(config / source, source)
    kinds = []
    for kind in table.types:
        if kind not in KIND:
            raise _fail(source, 1, "kiểu cột lạ")
        kinds.append(KIND[kind])
    return CensusRow(source, table.columns, table.rows, ",".join(kinds), _sha256(config / source))


def collect(raw_root: Path, names_path: Path) -> CensusResult:
    """Kê Config. Có lỗi thì không trả dòng bảng, để khỏi ghi một bảng kê thiếu."""
    config = Path(raw_root) / "Config"
    if not config.is_dir():
        return CensusResult((), {}, (f"{raw_root}:1: không có thư mục Config",), 0, 0, 0)
    listed = _client_rows(Path(names_path))
    counts, errors, directories, unclassified = _coverage(config, listed)
    if errors:
        return CensusResult((), counts, errors, directories, unclassified, 0)
    rows = []
    read_errors = []
    for row in listed:
        if not row.source.endswith(".txt"):
            continue
        try:
            rows.append(_census_row(config, row.source))
        except ValueError as exc:
            read_errors.append(str(exc))
    if read_errors:
        return CensusResult((), counts, tuple(read_errors), directories, unclassified, 0)
    records = sum(row.row_count for row in rows)
    return CensusResult(tuple(rows), counts, (), directories, unclassified, records)


def _parser() -> argparse.ArgumentParser:
    tool = argparse.ArgumentParser(
        prog="table_census.py",
        description="Kê bảng DBC của client 2026 và phân loại mọi tệp trong Config.",
    )
    tool.add_argument("raw_root", help="Thư mục _raw, có thư mục con Config")
    tool.add_argument("--check", action="store_true", help="Kiểm hết, không ghi tệp nào")
    tool.add_argument("--output", help="Tệp TSV ghi ra. Mặc định là TOOLS/server/table_census.tsv")
    tool.add_argument("--names", help="Bảng tên. Mặc định là TOOLS/server/table_names.tsv")
    return tool


def _print_result(result: CensusResult) -> None:
    for error in result.errors:
        print(error)
    print(f"tệp: {sum(result.counts.values())}")
    print(f"chưa phân loại: {sum(1 for error in result.errors if 'chưa phân loại' in error)}")
    for fate in sorted(result.counts):
        print(f"{fate}: {result.counts[fate]}")
    print(f"bảng: {len(result.rows)}")
    print(f"bản ghi: {result.records}")
    print(f"thư mục: {result.directories}")
    print(f"thư mục chưa phân loại: {result.unclassified_directories}")


def _write(result: CensusResult, output: Path) -> None:
    source = f"client_2026/Config ({len(result.rows)} tệp .txt)"
    body = [(row.source, str(row.column_count), str(row.row_count), row.types, row.sha256) for row in result.rows]
    tsv_file.write_table(output, source, "table_census.py", CENSUS_TYPES, CENSUS_COLUMNS, body)


def _utf8_stdout() -> None:
    reconfigure = getattr(sys.stdout, "reconfigure", None)
    if reconfigure is None:
        return
    try:
        reconfigure(encoding="utf-8")
    except (OSError, ValueError):
        return


def main(argv: list[str] | None = None) -> int:
    """Kê bảng. Có lỗi thì không ghi tệp kê."""
    _utf8_stdout()
    arguments = list(sys.argv[1:] if argv is None else argv)
    if "--help" in arguments or "-h" in arguments:
        _parser().print_help()
        return 0
    args = _parser().parse_args(arguments)
    names = Path(args.names) if args.names else Path(__file__).with_name("table_names.tsv")
    output = Path(args.output) if args.output else Path(__file__).with_name("table_census.tsv")
    started = time.perf_counter()
    result = collect(Path(args.raw_root), names)
    _print_result(result)
    if result.errors:
        print(f"thời gian: {time.perf_counter() - started:.1f} giây")
        return 1
    if not args.check:
        _write(result, output)
        print(f"đã ghi {output.name}")
    print(f"thời gian: {time.perf_counter() - started:.1f} giây")
    return 0


if __name__ == "__main__":
    sys.exit(main())
