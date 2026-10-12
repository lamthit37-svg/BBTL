"""Đọc ini và bảng chữ của cảnh theo cách máy chủ 2008 đọc.

Ini.cpp: khoá và section so đúng từng ký tự; giá trị ngắt tại tab, chấm phẩy hoặc dấu đóng
ngoặc. Dòng bắt đầu bằng chấm phẩy là chú thích. Bảng chữ theo OpenFromMemoryImpl_Text:
dòng kiểu, dòng tên, rồi bản ghi cách nhau bằng tab.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path


class SceneError(ValueError):
    """Lỗi dữ liệu cảnh, đã kèm vị trí tệp."""


@dataclass
class IniKey:
    line: int
    name: str
    value: str


@dataclass
class IniSection:
    line: int
    name: str
    keys: list[IniKey] = field(default_factory=list)


@dataclass
class IniFile:
    sections: list[IniSection]
    same_key_repeats: int
    distinct_repeats: int
    trailing_lf: int


@dataclass
class TextTable:
    types: tuple[str, ...]
    names: tuple[str, ...]
    rows: tuple[tuple[str, ...], ...]


def _decode(path: Path, data: bytes) -> str:
    if data.startswith(b"\xef\xbb\xbf"):
        raise SceneError(f"{_show(path)}:1: có BOM")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        line = data[: exc.start].count(b"\n") + 1
        raise SceneError(f"{_show(path)}:{line}: byte UTF-8 hỏng") from exc


def _show(path: Path) -> str:
    text = path.as_posix()
    marker = "/Public/Scene/"
    if marker in text:
        return "Public/Scene/" + text.split(marker, 1)[1]
    return path.name


def require_crlf(path: Path, data: bytes) -> int:
    """Ini trên đĩa là CRLF. Chỉ dòng cuối thiếu CR thì vẫn đọc được; LF ở giữa thì lỗi."""
    bare = [index for index, byte in enumerate(data) if byte == 10 and (index == 0 or data[index - 1] != 13)]
    if not bare:
        return 0
    if bare == [len(data) - 1]:
        return 1
    raise SceneError(f"{_show(path)}:1: xuống dòng không phải CRLF")


def server_value(path: Path, line: int, raw: str, column: str) -> str:
    """Phần giá trị Ini::ReadText giữ lại. Tab chỉ được phép là đệm trước chú thích."""
    for index, char in enumerate(raw):
        if char == "\t":
            rest = raw[index + 1 :].lstrip("\t")
            if rest == "" or rest.startswith(";"):
                return raw[:index]
            raise SceneError(f"{_show(path)}:{line}:{column}: ô chứa tab")
        if char in ";]":
            return raw[:index]
    return raw


def parse_ini(path: Path) -> IniFile:
    """Các section theo thứ tự trong tệp. Khoá lặp cùng giá trị giữ bản đầu."""
    data = path.read_bytes()
    trailing = require_crlf(path, data)
    text = _decode(path, data)
    sections: list[IniSection] = []
    current: IniSection | None = None
    seen: dict[str, str] = {}
    repeats = 0
    distinct = 0
    for number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith(";"):
            continue
        if stripped.startswith("[") and "]" in stripped:
            name = stripped[1 : stripped.index("]")]
            current = IniSection(number, name)
            sections.append(current)
            seen = {}
            continue
        if current is None or "=" not in line:
            raise SceneError(f"{_show(path)}:{number}: dòng không thuộc section")
        key, raw = line.split("=", 1)
        if key == "" or key != key.strip():
            raise SceneError(f"{_show(path)}:{number}: tên khoá không hợp lệ")
        value = server_value(path, number, raw, key)
        previous = seen.get(key)
        if previous is None:
            seen[key] = value
            current.keys.append(IniKey(number, key, value))
            continue
        if previous == value:
            repeats += 1
            continue
        distinct += 1
        current.keys.append(IniKey(number, key, value))
    return IniFile(sections, repeats, distinct, trailing)


def _cells(path: Path, number: int, line: str, width: int | None) -> tuple[str, ...]:
    parts = tuple(line.split("\t"))
    if width is not None and len(parts) != width:
        raise SceneError(f"{_show(path)}:{number}: {len(parts)} ô, cần {width}")
    if any(not part or part != part.strip() for part in parts[:0]):
        return parts
    return parts


def parse_text_table(path: Path) -> TextTable:
    """Bảng chữ. Dòng dài hơn bộ đệm 10 KiB của mã 2008 là lỗi, không cắt."""
    data = path.read_bytes()
    text = _decode(path, data)
    lines = text.splitlines()
    if len(lines) < 2:
        raise SceneError(f"{_show(path)}:1: bảng chữ thiếu dòng kiểu hoặc dòng tên")
    for number, line in enumerate(lines, start=1):
        if len(line.encode("utf-8")) >= 1024 * 10:
            raise SceneError(f"{_show(path)}:{number}: dòng dài hơn bộ đệm 10 KiB")
    type_cells = _cells(path, 1, lines[0], None)
    allowed = {"INT": "int", "FLOAT": "float", "STRING": "text"}
    if not type_cells or any(cell not in allowed for cell in type_cells):
        raise SceneError(f"{_show(path)}:1: dòng kiểu không phải INT, FLOAT, STRING")
    names = _cells(path, 2, lines[1], len(type_cells))
    rows = []
    for number, line in enumerate(lines[2:], start=3):
        if line == "" or line.startswith("#"):
            raise SceneError(f"{_show(path)}:{number}: dòng bị bộ đọc gốc bỏ, không xuất im lặng")
        cells = _cells(path, number, line, len(type_cells))
        if cells[0] == "":
            raise SceneError(f"{_show(path)}:{number}: ô đầu rỗng, bộ đọc gốc bỏ dòng")
        rows.append(cells)
    mapped = tuple(allowed[cell] for cell in type_cells)
    return TextTable(mapped, names, tuple(rows))
