#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/source_headers/extract.py
#  PHÂN HỆ   : Source Headers / Extract
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Tìm comment đầu tệp cũ và tách thành các ý để đưa vào khung.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Tìm comment đầu tệp cũ và tách thành các ý để đưa vào khung.

Một tệp mở đầu bằng: [BOM] [shebang] [khai bảng mã] rồi (theo thứ tự cũ hoặc mới) khung, `#pragma once`, comment đầu tệp cũ.
Mô-đun này chỉ đọc cấu trúc; việc ghép tệp mới ở rewrite.py.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from profiles import CODING, Profile

# Dòng comment là chỉ thị cho công cụ, không phải chữ cho người đọc: dừng đoạn comment đầu tệp ở đó và giữ nguyên chỗ.
DIRECTIVES = {
    "//": re.compile(r"^(NOLINT|clang-format|IWYU|TODO\(|NOLINTBEGIN|NOLINTEND)"),
    "#": re.compile(r"^(pylint:|noqa|type:|fmt:|-\*-|vim:|shellcheck|mypy:|pyright:)"),
    "--": re.compile(r"^@"),
    "::": re.compile(r"^@"),
}
DECORATION = re.compile(r"^[\s=\-*#~_+|/\\.]+$")
BULLET_START = re.compile(r"^(?:[-*•]|\d+[.)])\s+")
BLOCK_BODY = re.compile(r"^\s*\*{1,2}\s?")
REM = re.compile(r"^rem(?:\s|$)", re.IGNORECASE)
SENTENCE_END = re.compile(r"(?<=[.!?])\s+(?=[A-ZÀ-ỸĐ\"`(\[])")


@dataclass(frozen=True)
class Run:
    """Đoạn comment liền nhau: các dòng [start, stop) của tệp."""

    start: int
    stop: int
    raw: list[str]
    content: list[str]


@dataclass
class Item:
    """Một ý của comment: chữ đã nối các dòng văn xuôi, nằm ở các dòng [first, last] của Run.content."""

    text: str
    paragraph: int
    first: int
    last: int
    # Dòng có thụt hay mở đầu bằng dấu liệt kê (lệnh mẫu, danh sách): không nối với dòng khác.
    literal: bool = False


@dataclass
class Layout:
    """Vị trí các phần ở đầu tệp (chỉ số dòng)."""

    preamble: int = 0
    lead: int | None = None
    frame_at: int | None = None
    # Khung hộp cũ (legacy_box) đang đứng ở đầu tệp, chờ đổi sang khung mới.
    legacy_at: int | None = None
    run: Run | None = None
    docstring: list[str] = field(default_factory=list)
    # Dòng đầu tiên của mã (sau mọi comment đầu tệp và dòng lead).
    code: int = 0


def skip_blank(lines: list[str], at: int) -> int:
    while at < len(lines) and not lines[at].strip():
        at += 1
    return at


def preamble_end(lines: list[str], profile: Profile) -> int:
    """Số dòng mở đầu đứng trước khung: shebang và dòng khai bảng mã."""
    at = 0
    if profile.shebang and lines and lines[0].startswith("#!"):
        at = 1
    if profile.coding:
        for step in range(at, min(at + 2, len(lines))):
            if CODING.match(lines[step]):
                at = step + 1
    return at


def is_comment(line: str, profile: Profile) -> bool:
    if profile.prefix == "::":
        return line.startswith("::") or REM.match(line) is not None
    return line.startswith(profile.prefix)


def _marker_length(line: str, profile: Profile) -> int:
    if profile.prefix == "::" and not line.startswith("::"):
        return 3
    return len(profile.prefix)


def strip_marker(line: str, profile: Profile) -> str:
    """Chữ của một dòng comment: bỏ ký hiệu và đúng một dấu cách theo sau."""
    text = line[_marker_length(line, profile) :]
    return text[1:] if text.startswith(" ") else text.rstrip("\r")


def is_directive(line: str, profile: Profile) -> bool:
    pattern = DIRECTIVES.get(profile.prefix)
    return pattern is not None and pattern.match(strip_marker(line, profile).strip()) is not None


def find_block(lines: list[str], at: int) -> Run | None:
    """Comment khối /* ... */ bắt đầu ở dòng at (cột 0) và kết thúc không kèm mã nào khác."""
    if at >= len(lines) or not lines[at].startswith("/*"):
        return None
    stop = at
    while stop < len(lines) and "*/" not in lines[stop]:
        stop += 1
    if stop >= len(lines) or lines[stop].split("*/", 1)[1].strip():
        return None
    content: list[str] = []
    for index in range(at, stop + 1):
        line = lines[index].split("*/", 1)[0] if index == stop else lines[index]
        if index == at:
            line = line[2:]
            line = line[1:] if line.startswith(" ") else line
        else:
            line = BLOCK_BODY.sub("", line, count=1)
        content.append(line.rstrip())
    return Run(at, stop + 1, lines[at : stop + 1], content)


def find_run(lines: list[str], at: int, profile: Profile) -> Run | None:
    """Đoạn comment đầu tệp bắt đầu ở dòng at, hoặc None."""
    if profile.block:
        block = find_block(lines, at)
        if block is not None:
            return block
    stop = at
    while stop < len(lines) and is_comment(lines[stop], profile) and not is_directive(lines[stop], profile):
        stop += 1
    if stop == at:
        return None
    raw = lines[at:stop]
    return Run(at, stop, raw, [strip_marker(line, profile) for line in raw])


def python_docstring(lines: list[str], at: int) -> tuple[list[str], int] | None:
    """Chuỗi tài liệu của mô-đun bắt đầu ở dòng at: (các dòng chữ, chỉ số dòng sau nó); None khi không có."""
    if at >= len(lines):
        return None
    match = re.match(r"^[rRuU]?(\"\"\"|''')", lines[at])
    if match is None:
        return None
    quote = match.group(1)
    first = lines[at][match.end() :]
    if quote in first:
        return [first.split(quote, 1)[0]], at + 1
    body = [first]
    for index in range(at + 1, len(lines)):
        if quote in lines[index]:
            body.append(lines[index].split(quote, 1)[0])
            return body, index + 1
        body.append(lines[index])
    return None


def locate(lines: list[str], profile: Profile, frame_start: str, legacy_start: str | None = None) -> Layout:
    """Bố cục đầu tệp. frame_start là dòng viền trên của khung theo ký hiệu comment của tệp; legacy_start là của khung cũ."""
    layout = Layout(preamble=preamble_end(lines, profile))
    at = skip_blank(lines, layout.preamble)
    if profile.lead is not None and at < len(lines) and profile.lead.match(lines[at]):
        layout.lead = at
        at = skip_blank(lines, at + 1)
    if at < len(lines) and lines[at] == frame_start:
        layout.frame_at = at
        layout.code = at
        return layout
    if legacy_start is not None and at < len(lines) and lines[at] == legacy_start:
        layout.legacy_at = at
        layout.code = at
        return layout
    layout.run = find_run(lines, at, profile)
    layout.code = layout.run.stop if layout.run else at
    if profile.docstring and layout.run is None:
        found = python_docstring(lines, at)
        if found is not None:
            layout.docstring = found[0]
    return layout


def _is_literal(text: str) -> bool:
    return text.startswith(" ") or BULLET_START.match(text) is not None


def _hang(item: Item, text: str, previous: Item | None) -> bool:
    """Dòng text nối vào ý trước (dòng nối tiếp có thụt của một mục liệt kê)."""
    return previous is not None and previous.literal and text.startswith(" ") and BULLET_START.match(previous.text) is not None


def to_items(content: list[str]) -> list[Item]:
    """Các ý của comment: văn xuôi liền nhau nối thành một ý; dòng thụt hay liệt kê là ý riêng; dòng trống đổi đoạn."""
    items: list[Item] = []
    paragraph = 0
    for index, text in enumerate(content):
        stripped = text.strip()
        if not stripped or DECORATION.match(stripped):
            paragraph += 1
            continue
        previous = items[-1] if items else None
        same = previous is not None and previous.paragraph == paragraph and previous.last == index - 1
        if same and previous is not None and not _is_literal(text) and not previous.literal:
            previous.text += " " + stripped
            previous.last = index
        elif same and previous is not None and _hang(previous, text, previous):
            previous.text += " " + stripped
            previous.last = index
        else:
            items.append(Item(stripped, paragraph, index, index, _is_literal(text)))
    return items


def words(text: str) -> list[str]:
    """Các từ có chữ hay số của text, để so hai bản chữ không phân biệt cách bẻ dòng và dấu liệt kê."""
    return [word for word in text.split() if re.search(r"\w", word)]


def sentences(text: str) -> list[str]:
    return SENTENCE_END.split(text)
