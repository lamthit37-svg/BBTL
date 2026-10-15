"""Đơn vị đối soát hàng loạt của LUA-GEN (docs/giao-viec/LUA-GEN/THIET-KE.md): mỗi thư mục cửa sổ của
src/client/script/Interface hay của dev/client/assets/Interface là một đơn vị. Đơn vị gồm các chunk nạp theo thứ tự:
mọi tệp .lua của thư mục (theo đường dẫn tương đối, chữ thường trước khi so), rồi mỗi đoạn Lua mà layout nối vào một sự
kiện (<Event Name=... Function=...>), theo tên tệp layout rồi theo thứ tự trong tệp. Phía gốc (mass_oracle.py) và bộ
dịch dùng chung mô-đun này để hai phía nạp đúng một danh sách chunk với đúng một mã nguồn.

Đoạn Lua của layout thành chunk:
    __handler("<cửa sổ>", "<sự kiện>", function()
    <đoạn>
    end)
xuống dòng trước `end` để chú thích `--` cuối đoạn không nuốt mất nó.
"""

from __future__ import annotations

import dataclasses
import pathlib
import xml.etree.ElementTree as ElementTree

PROJECT = pathlib.Path(__file__).resolve().parents[3]
SCRIPT_ROOT = PROJECT / "src/client/script/Interface"
# Layout là dữ liệu gitignore: worktree không có, người gọi đưa thư mục layout của cây chính qua đối số.
LAYOUT_ROOT = PROJECT / "dev/client/assets/Interface"


class UnitError(Exception):
    """Không đọc được một tệp của đơn vị; câu lỗi nêu tệp."""


def lua_text(value: str) -> str:
    """Chuỗi Lua trong nháy kép mang đúng các byte của value (UTF-8)."""
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\r", "\\r").replace("\n", "\\n")
    return '"' + escaped.replace("\0", "\\0") + '"'


@dataclasses.dataclass(frozen=True)
class Chunk:
    """Một chunk Lua của đơn vị: tên (để báo lỗi và đặt tên tệp sinh) và mã nguồn UTF-8."""

    name: str
    source: str


@dataclasses.dataclass(frozen=True)
class Unit:
    name: str
    chunks: tuple[Chunk, ...]


def handler_source(window: str, event: str, code: str) -> str:
    return f"__handler({lua_text(window)}, {lua_text(event)}, function()\n{code}\nend)\n"


def _layout_chunks(layout: pathlib.Path) -> list[Chunk]:
    try:
        root = ElementTree.parse(layout).getroot()
    except (OSError, ElementTree.ParseError) as error:
        raise UnitError(f"{layout}: không đọc được layout: {error}") from error
    chunks = []
    for window in root.iter("Window"):
        for event in window.findall("Event"):
            code = event.get("Function", "")
            if not code.strip():
                continue
            name = f"{layout.parent.name}/{layout.name}#{len(chunks) + 1}"
            chunks.append(Chunk(name, handler_source(window.get("Name", ""), event.get("Name", ""), code)))
    return chunks


def _script_chunks(folder: pathlib.Path) -> list[Chunk]:
    chunks = []
    for path in sorted(folder.rglob("*.lua"), key=lambda item: item.relative_to(folder).as_posix().lower()):
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            raise UnitError(f"{path}: không đọc được script: {error}") from error
        chunks.append(Chunk(f"{folder.name}/{path.relative_to(folder).as_posix()}", text))
    return chunks


def units(script_root: pathlib.Path = SCRIPT_ROOT, layout_root: pathlib.Path = LAYOUT_ROOT) -> list[Unit]:
    """Mọi đơn vị, theo tên thư mục (chữ thường trước khi so). Thư mục không có script lẫn đoạn Lua nào thì bỏ."""
    names = {path.name for path in script_root.iterdir() if path.is_dir()}
    if layout_root.is_dir():
        names |= {path.name for path in layout_root.iterdir() if path.is_dir()}
    found = []
    for name in sorted(names, key=str.lower):
        chunks = _script_chunks(script_root / name) if (script_root / name).is_dir() else []
        layouts = sorted((layout_root / name).glob("*.layout.xml"), key=lambda item: item.name.lower())
        for layout in layouts:
            chunks.extend(_layout_chunks(layout))
        if chunks:
            found.append(Unit(name, tuple(chunks)))
    return found
