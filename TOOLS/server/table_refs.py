"""Đọc và kiểm hình dạng TOOLS/server/refs/*.tsv.

Bảng soạn tay, không có dòng # tool:. Cột child, child_column, parent,
parent_column, absent, known_missing, basis, note.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

_COLUMNS = (
    "child",
    "child_column",
    "parent",
    "parent_column",
    "absent",
    "known_missing",
    "basis",
    "note",
)
_COLUMN_NAME = re.compile(r"^[a-z][a-z0-9_]*$")
_FALLBACK = re.compile(r"^column_\d+")
_BASIS = re.compile(r"^(?:code:[A-Za-z0-9_./-]+:\d+|label|data)$")
_STAR = re.compile(r"\*")


@dataclass(frozen=True)
class RefRow:
    child: str
    child_column: str
    parent: str
    parent_column: str
    absent: str
    known_missing: int
    basis: str
    note: str
    line: int
    source: str


def _fail(path: Path, line: int, message: str) -> ValueError:
    return ValueError(f"{path}:{line}: {message}")


def _read(path: Path) -> str:
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


def _comment(path: Path, number: int, line: str, found: dict[str, str]) -> None:
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


def _star_ok(pattern: str) -> bool:
    if "?" in pattern or "[" in pattern or "]" in pattern:
        return False
    for part in pattern.split("/"):
        if part.count("*") > 1:
            return False
    return True


def _check_pattern(path: Path, line: int, pattern: str, label: str) -> None:
    if not pattern or not _star_ok(pattern):
        raise _fail(path, line, f"{label} sai mẫu")
    if pattern.startswith("/") or ".." in pattern.split("/"):
        raise _fail(path, line, f"{label} không phải đường dẫn tương đối")


def _check_column(path: Path, line: int, name: str, label: str) -> None:
    if not _COLUMN_NAME.fullmatch(name) or _FALLBACK.match(name):
        raise _fail(path, line, f"{label} không phải tên cột")


def _one(path: Path, number: int, cells: list[str]) -> RefRow:
    if len(cells) != len(_COLUMNS):
        raise _fail(path, number, "sai số cột")
    child, child_column, parent, parent_column, absent, missing, basis, note = cells
    _check_pattern(path, number, child, "child")
    _check_pattern(path, number, parent, "parent")
    if parent.count("*") > 1 or (parent.count("*") == 1 and "*" not in child):
        raise _fail(path, number, "parent có * thì child cũng phải có *")
    _check_column(path, number, child_column, "child_column")
    _check_column(path, number, parent_column, "parent_column")
    if not missing.isdigit():
        raise _fail(path, number, "known_missing không phải số nguyên")
    if not _BASIS.fullmatch(basis):
        raise _fail(path, number, "basis không hợp lệ")
    if basis == "data" and not note:
        raise _fail(path, number, "basis data thì note không được rỗng")
    if "\t" in note or "\t" in absent:
        raise _fail(path, number, "ô chứa tab")
    return RefRow(
        child,
        child_column,
        parent,
        parent_column,
        absent,
        int(missing),
        basis,
        note,
        number,
        path.name,
    )


def read_ref_file(path: Path) -> tuple[RefRow, ...]:
    """Đọc một tệp refs. Sai hình dạng thì lỗi."""
    text = _read(path)
    found: dict[str, str] = {}
    header = False
    rows: list[RefRow] = []
    for number, line in enumerate(text.split("\n")[:-1], start=1):
        if line == "":
            continue
        if not header and line.startswith("#"):
            _comment(path, number, line, found)
            continue
        if not header:
            if tuple(line.split("\t")) != _COLUMNS:
                raise _fail(path, number, "thiếu cột của bảng tham chiếu")
            header = True
            continue
        rows.append(_one(path, number, line.split("\t")))
    if found.get("schema") != "1" or not header:
        raise _fail(path, 1, "thiếu schema hoặc dòng tên cột")
    types = "\t".join(("text", "text", "text", "text", "text", "int", "text", "text"))
    if found.get("types") != types:
        raise _fail(path, 1, "dòng types sai")
    return tuple(rows)


def read_refs(directory: Path) -> tuple[RefRow, ...]:
    """Đọc mọi refs/*.tsv theo tên tệp, rồi theo thứ tự dòng."""
    rows: list[RefRow] = []
    seen: set[tuple[str, str, str, str]] = set()
    for path in sorted(directory.glob("*.tsv")):
        for row in read_ref_file(path):
            key = (row.child, row.child_column, row.parent, row.parent_column)
            if key in seen:
                raise _fail(path, row.line, "bộ cột con và cột cha bị lặp")
            seen.add(key)
            rows.append(row)
    return tuple(rows)
