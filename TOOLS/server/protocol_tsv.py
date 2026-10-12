# Đọc bốn bảng TSV của danh mục tin và kiểm hình dạng tệp (luật G1 của DE-BAI §3.4).
"""Đọc SRC/protocol/catalog/*.tsv thành dòng có số dòng; lỗi ghi dạng `tệp:dòng: [Gx] câu`."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


@dataclass(frozen=True)
class TableSpec:
    """Hình dạng bắt buộc của một bảng: tên cột, dòng `# types:` và các dòng meta riêng."""

    columns: tuple[str, ...]
    types: tuple[str, ...]
    meta: tuple[str, ...] = ()


SPECS: dict[str, TableSpec] = {
    "groups.tsv": TableSpec(("id", "name", "summary"), ("hex8", "ident", "text")),
    "messages.tsv": TableSpec(
        ("kind", "name", "port", "since", "summary"), ("kind", "ident", "port", "int", "text"), ("version",)
    ),
    "fields.tsv": TableSpec(
        ("owner", "order", "name", "type", "limit", "note"), ("ident", "int", "ident", "type", "int", "text")
    ),
    "enums.tsv": TableSpec(
        ("enum", "underlying", "value", "name", "note"), ("ident", "u8|u16", "int", "ident", "text")
    ),
}


@dataclass(frozen=True)
class Row:
    line: int
    cells: dict[str, str]


@dataclass
class Table:
    display: str
    meta: dict[str, str] = field(default_factory=dict)
    rows: list[Row] = field(default_factory=list)


@dataclass
class Problems:
    """Gom lỗi theo thứ tự phát hiện; in ra đã xếp theo tệp rồi dòng."""

    items: list[tuple[str, int, str, str]] = field(default_factory=list)

    def add(self, display: str, line: int, rule: str, text: str) -> None:
        self.items.append((display, line, rule, text))

    def lines(self) -> list[str]:
        ordered = sorted(self.items, key=lambda item: (item[0], item[1]))
        return [f"{name}:{line}: [{rule}] {text}" for name, line, rule, text in ordered]

    def __bool__(self) -> bool:
        return bool(self.items)


def decode_text(path: Path, display: str, problems: Problems) -> str | None:
    """Nội dung UTF-8 không BOM, xuống dòng LF; sai là lỗi G1."""
    if not path.is_file():
        problems.add(display, 0, "G1", "thiếu tệp")
        return None
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        problems.add(display, 1, "G1", "tệp có BOM; phải là UTF-8 không BOM")
        return None
    if b"\r" in data:
        problems.add(display, 1, "G1", "tệp có CR; chỉ dùng LF")
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as error:
        problems.add(display, 1, "G1", f"không phải UTF-8 hợp lệ ({error.reason})")
        return None


def read_meta(table: Table, spec: TableSpec, lines: list[str], problems: Problems) -> int:
    """Đọc các dòng `#` ở đầu tệp; trả chỉ số dòng tiêu đề cột."""
    index = 0
    while index < len(lines) and lines[index].startswith("#"):
        key, _, value = lines[index][1:].strip().partition(" ")
        table.meta[key.rstrip(":")] = value.strip()
        index += 1
    wanted = {"schema": "1", "types": "\t".join(spec.types)}
    if not lines or lines[0] != "# schema 1":
        problems.add(table.display, 1, "G1", "dòng đầu phải là `# schema 1`")
    if "source" not in table.meta:
        problems.add(table.display, 1, "G1", "thiếu dòng `# source: ...`")
    if table.meta.get("types") != wanted["types"]:
        problems.add(table.display, index, "G1", f"dòng `# types:` phải là `{wanted['types']}`")
    for key in spec.meta:
        if key not in table.meta:
            problems.add(table.display, 1, "G1", f"thiếu dòng `# {key} ...`")
    return index


def read_rows(table: Table, spec: TableSpec, lines: list[str], start: int, problems: Problems) -> None:
    """Kiểm dòng tiêu đề cột rồi đọc từng dòng dữ liệu đủ số ô."""
    header = lines[start] if start < len(lines) else ""
    if tuple(header.split("\t")) != spec.columns:
        problems.add(table.display, start + 1, "G1", f"tiêu đề cột phải là `{chr(9).join(spec.columns)}`")
        return
    for offset, text in enumerate(lines[start + 1:], start + 2):
        if text == "":
            problems.add(table.display, offset, "G1", "dòng trống giữa bảng")
            continue
        cells = text.split("\t")
        if len(cells) != len(spec.columns):
            problems.add(table.display, offset, "G1", f"có {len(cells)} ô, phải có {len(spec.columns)}")
            continue
        table.rows.append(Row(offset, dict(zip(spec.columns, cells))))


def read_table(path: Path, display: str, problems: Problems) -> Table:
    """Đọc một bảng; hình dạng sai thì bảng trả về không có dòng nào."""
    spec = SPECS[path.name]
    table = Table(display)
    text = decode_text(path, display, problems)
    if text is None:
        return table
    if not text.endswith("\n"):
        problems.add(display, text.count("\n") + 1, "G1", "dòng cuối phải kết thúc bằng LF")
    lines = text.split("\n")[:-1] if text.endswith("\n") else text.split("\n")
    start = read_meta(table, spec, lines, problems)
    read_rows(table, spec, lines, start, problems)
    return table


def read_catalog_tables(directory: Path, root: Path, problems: Problems) -> dict[str, Table]:
    """Đọc cả bốn bảng của một thư mục danh mục."""
    tables: dict[str, Table] = {}
    for name in SPECS:
        path = directory / name
        tables[name] = read_table(path, display_path(path, root), problems)
    return tables


def display_path(path: Path, root: Path) -> str:
    """Đường dẫn in trong lỗi: tương đối với gốc repo nếu nằm trong đó."""
    resolved = path.resolve()
    try:
        return resolved.relative_to(root.resolve()).as_posix()
    except ValueError:
        return resolved.as_posix()
