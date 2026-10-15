#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/source_headers/source_frame.py
#  PHÂN HỆ   : Source Headers / Source Frame
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Khung đầu tệp theo mẫu EngineHP của chủ dự án (chốt ngày 2026-10-15, thay
#    khung hộp `// +---` cũ).
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Khung đầu tệp theo mẫu EngineHP của chủ dự án (chốt ngày 2026-10-15, thay khung hộp `// +---` cũ).

    /*==============================================================================
     *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
     *------------------------------------------------------------------------------
     *  TỆP       : engine/core/clock.cpp
     *  PHÂN HỆ   : Core / Clock
     *  CHUẨN     : C++23
     *------------------------------------------------------------------------------
     *  CHỨC NĂNG
     *  - Một ý một dòng, tiếng Việt có dấu.
     *------------------------------------------------------------------------------
     *  TÁC GIẢ   : HiepHoon
     *  TELEGRAM  : @Hoon9xx
     *============================================================================*/

- Rộng COLUMNS (80) cột, mọi dòng không đệm cuối. Tệp dùng `//` (C, C++, Slang, GLSL, Java, JS, Obj-C++, rc) mang khung
  dạng comment khối như trên; tệp dùng `#`, `--`, `::` mang cùng bố cục nhưng mỗi dòng mở đầu bằng ký hiệu comment.
- Tối đa MAX_LINES (18, theo mẫu) dòng; phần chữ vào "CHỨC NĂNG" tối đa MAX_BULLET_LINES dòng, dòng nối tiếp của một ý thụt
  hai dấu cách. Không có chữ Hán trong khung; chữ chuẩn NFC.
- PHÂN HỆ do người viết sửa tay được (công cụ giữ nguyên khi khung đã có); khi tạo mới thì suy từ đường dẫn.
- Tên sản phẩm (dòng 2) theo thư mục: engine/ là ENGINEHP, còn lại là THIENLONG kèm phần của dự án (client, server...).

Bộ sinh mã (gen_protocol.py, config_style.py) gọi render_frame() để tệp sinh ra đã đúng khung.
"""
from __future__ import annotations

import re
import textwrap
import unicodedata
from dataclasses import dataclass
from pathlib import PurePosixPath

AUTHOR = "HiepHoon"
TELEGRAM = "@Hoon9xx"
COLUMNS = 80
# Dòng nội dung: ký hiệu (hay " *") rồi hai dấu cách; chữ vào được COLUMNS trừ 4 cột ở mọi kiểu khung (kiểu `#` dư một cột).
TEXT = COLUMNS - 4
LABEL_WIDTH = 10
BULLET = "- "
CONTINUATION = "  "
# Mười hai dòng cố định: viền trên, tên, kẻ, TỆP, PHÂN HỆ, CHUẨN, kẻ, CHỨC NĂNG, kẻ, TÁC GIẢ, TELEGRAM, viền dưới.
FIXED_LINES = 12
MAX_LINES = 18
MAX_BULLET_LINES = MAX_LINES - FIXED_LINES
BULLET_ROOM = TEXT - len(BULLET)
FILE_LABEL = "TỆP"
SUBSYSTEM_LABEL = "PHÂN HỆ"
STANDARD_LABEL = "CHUẨN"
FEATURES_LABEL = "CHỨC NĂNG"
AUTHOR_LABEL = "TÁC GIẢ"
TELEGRAM_LABEL = "TELEGRAM"
CJK = re.compile("[⺀-〿㐀-鿿豈-﫿＀-￯]")


class FrameError(ValueError):
    """Chữ không vào được khung (chữ Hán, từ dài hơn dòng, quá số dòng)."""


@dataclass(frozen=True)
class ParsedFrame:
    """Một khung đã đọc từ đầu tệp: các dòng [start, stop) và nội dung của nó."""

    start: int
    stop: int
    path: str
    # Các ý đã nối lại: mỗi phần tử là chữ của một ý (bỏ "- " và thụt), theo thứ tự.
    items: list[str]
    subsystem: str
    problems: list[str]


@dataclass(frozen=True)
class Style:
    """Các dòng cố định của khung theo ký hiệu comment của tệp."""

    open: str
    sep: str
    close: str
    # Phần đứng trước chữ của một dòng nội dung.
    lead: str

    def row(self, text: str) -> str:
        return (self.lead + text).rstrip()


def style_for(prefix: str) -> Style:
    if prefix == "//":
        return Style("/*" + "=" * (COLUMNS - 2), " *" + "-" * (COLUMNS - 2), " *" + "=" * (COLUMNS - 4) + "*/", " *  ")
    line = prefix + "=" * (COLUMNS - len(prefix))
    return Style(line, prefix + "-" * (COLUMNS - len(prefix)), line, prefix + "  ")


def border(prefix: str) -> str:
    """Dòng viền trên của khung: nơi công cụ nhận ra khung đã có."""
    return style_for(prefix).open


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def has_cjk(text: str) -> bool:
    return CJK.search(text) is not None


STANDARDS = {
    ".cpp": "C++23", ".hpp": "C++23", ".h": "C++23", ".inc": "C++23", ".c": "C11", ".mm": "Objective-C++",
    ".m": "Objective-C", ".slang": "Slang", ".glsl": "GLSL", ".java": "Java 21", ".kt": "Kotlin", ".js": "JavaScript",
    ".mjs": "JavaScript", ".ts": "TypeScript", ".tsx": "TypeScript", ".rc": "Win32 RC", ".py": "Python 3.13",
    ".cmake": "CMake", ".toml": "TOML", ".sh": "POSIX sh", ".ps1": "PowerShell", ".lua": "Lua 5.0", ".bat": "Batch",
    ".cmd": "Batch",
}
BRANDS = (
    ("engine/", "ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE"),
    ("src/client/", "THIENLONG  |  GAME CLIENT"),
    ("src/server/", "THIENLONG  |  GAME SERVER"),
    ("src/shared/", "THIENLONG  |  SHARED"),
    ("Test/", "THIENLONG  |  TEST"),
    ("TOOLS/", "THIENLONG  |  TOOLS"),
    ("android/", "THIENLONG  |  ANDROID SHELL"),
    ("apple/", "THIENLONG  |  APPLE SHELL"),
    ("cmake/", "THIENLONG  |  BUILD"),
    ("dev/", "THIENLONG  |  DEPLOY"),
)
DEFAULT_BRAND = "THIENLONG  |  GAME"
# Tên thư mục chỉ để gom, không mang nghĩa phân hệ.
GENERIC_PARTS = frozenset({"src", "engine", "app", "TOOLS", "Test", "android", "apple", "cmake", "dev"})


def standard_of(path: str) -> str:
    pure = PurePosixPath(path)
    if pure.name == "CMakeLists.txt":
        return "CMake"
    return STANDARDS.get(pure.suffix.lower(), "")


def brand_of(path: str) -> str:
    for head, brand in BRANDS:
        if path.startswith(head):
            return brand
    return DEFAULT_BRAND


def _title(part: str) -> str:
    return " ".join(word.capitalize() for word in re.split(r"[_\-\s]+", part) if word)


def subsystem_of(path: str) -> str:
    """Phân hệ suy từ đường dẫn: các thư mục có nghĩa (tối đa ba, lấy phần cuối) rồi tên tệp; người viết sửa tay được."""
    pure = PurePosixPath(path)
    dirs = [part for part in pure.parts[:-1] if part not in GENERIC_PARTS]
    if pure.name == "CMakeLists.txt":
        parts = [_title(part) for part in [*(dirs[-2:] or ["build"]), "cmake"]]
        return " / ".join(parts)
    parts = [_title(part) for part in [*dirs[-2:], pure.stem]]
    return " / ".join(part for part in parts if part) or _title(pure.stem)


def wrap_item(text: str) -> list[str]:
    """Một ý thành các dòng "- ..." đã bẻ theo độ rộng khung; từ dài hơn dòng là lỗi (không cắt giữa từ)."""
    # Dấu cách giữa chữ giữ nguyên: mẫu căn cột nhãn trong ý ("Windows : ...", "POSIX   : ..."); chỉ tab và xuống dòng thành dấu cách.
    text = " ".join(nfc(text).replace("\t", " ").splitlines()).strip()
    if not text:
        raise FrameError("ý trống")
    if has_cjk(text):
        raise FrameError(f"khung không chứa chữ Hán: {text!r}")
    if any(len(word) > BULLET_ROOM for word in text.split()):
        raise FrameError(f"từ dài hơn {BULLET_ROOM} ký tự: {text!r}")
    lines = textwrap.wrap(text, width=BULLET_ROOM, break_long_words=False, break_on_hyphens=False)
    return [(BULLET if at == 0 else CONTINUATION) + line for at, line in enumerate(lines)]


def wrapped_height(text: str) -> int:
    """Số dòng của một ý sau khi bẻ; FrameError khi ý không vào được khung."""
    return len(wrap_item(text))


def field(label: str, value: str) -> str:
    return f"{label.ljust(LABEL_WIDTH)}: {value}"


def render_frame(prefix: str, path: str, items: list[str], subsystem: str | None = None) -> list[str]:
    """Các dòng của khung (chưa có ký tự xuống dòng) cho tệp path với các ý items."""
    standard = standard_of(path)
    if not standard:
        raise FrameError(f"{path}: loại tệp không có trong bảng CHUẨN")
    if has_cjk(path):
        raise FrameError(f"đường dẫn có chữ Hán: {path}")
    body: list[str] = []
    for item in items:
        body += wrap_item(item)
    if not body:
        raise FrameError(f"{path}: khung không có ý nào")
    if len(body) > MAX_BULLET_LINES:
        raise FrameError(f"{path}: {len(body)} dòng ý, khung chứa tối đa {MAX_BULLET_LINES}")
    style = style_for(prefix)
    where = nfc(subsystem or subsystem_of(path))
    if has_cjk(where):
        raise FrameError(f"phân hệ có chữ Hán: {where}")
    rows = [
        style.open,
        style.row(brand_of(path)),
        style.sep,
        style.row(field(FILE_LABEL, path)),
        style.row(field(SUBSYSTEM_LABEL, where)),
        style.row(field(STANDARD_LABEL, standard)),
        style.sep,
        style.row(FEATURES_LABEL),
        *[style.row(text) for text in body],
        style.sep,
        style.row(field(AUTHOR_LABEL, AUTHOR)),
        style.row(field(TELEGRAM_LABEL, TELEGRAM)),
        style.close,
    ]
    if len(rows) > MAX_LINES:
        raise FrameError(f"{path}: khung dài {len(rows)} dòng, tối đa {MAX_LINES}")
    return rows


def join_items(rows: list[str]) -> list[str]:
    """Các dòng ý (đã bỏ phần dẫn đầu) thành các ý: dòng "- " mở ý mới, dòng thụt nối vào ý trước."""
    items: list[str] = []
    for text in rows:
        text = text.rstrip()
        if text.startswith(BULLET):
            items.append(text[len(BULLET) :])
        elif text.startswith(CONTINUATION) and items:
            items[-1] += " " + text.strip()
        elif text.strip():
            items.append(text.strip())
    return items


def _row_text(line: str, style: Style, problems: list[str], number: int) -> str:
    if line == style.lead.rstrip():
        return ""
    if not line.startswith(style.lead):
        problems.append(f"dòng {number} không mở đầu bằng \"{style.lead}\"")
        return line.strip()
    return line[len(style.lead) :]


def _split_sections(rows: list[tuple[int, str]], sep: str) -> list[list[tuple[int, str]]]:
    sections: list[list[tuple[int, str]]] = [[]]
    for number, line in rows:
        if line == sep:
            sections.append([])
        else:
            sections[-1].append((number, line))
    return sections


def _value(text: str, label: str) -> str | None:
    head = field(label, "")
    return text[len(head) :] if text.startswith(head) else None


def parse_frame(lines: list[str], start: int, prefix: str, path: str) -> ParsedFrame | None:
    """Đọc khung bắt đầu ở dòng start; None khi dòng start không phải viền trên. Mọi sai lệch ghi vào problems."""
    style = style_for(prefix)
    if start >= len(lines) or lines[start] != style.open:
        return None
    stop = start + 1
    while stop < len(lines) and lines[stop] != style.close and stop - start <= MAX_LINES:
        stop += 1
    if stop >= len(lines) or lines[stop] != style.close:
        return ParsedFrame(start, min(stop, len(lines)), path, [], "", [f"khung không có viền dưới trong {MAX_LINES} dòng"])
    problems: list[str] = []
    rows = [(index + 1, lines[index]) for index in range(start + 1, stop)]
    sections = _split_sections(rows, style.sep)
    if len(sections) != 4:
        return ParsedFrame(start, stop + 1, path, [], "", [f"khung phải có 4 phần cách nhau bằng dòng kẻ, đang có {len(sections)}"])
    texts = [[_row_text(line, style, problems, number) for number, line in section] for section in sections]
    items, subsystem = _check_sections(texts, path, problems)
    for number, line in rows:
        if len(line) > COLUMNS:
            problems.append(f"dòng {number} dài {len(line)} cột, khung rộng {COLUMNS}")
    if any(has_cjk(line) for _, line in rows):
        problems.append("khung có chữ Hán")
    if any(line != nfc(line) for _, line in rows):
        problems.append("khung có chữ chưa chuẩn NFC")
    return ParsedFrame(start, stop + 1, path, items, subsystem, problems)


def _check_sections(texts: list[list[str]], path: str, problems: list[str]) -> tuple[list[str], str]:
    brand, identity, features, authors = texts
    if brand != [brand_of(path)]:
        problems.append(f"dòng tên phải là \"{brand_of(path)}\"")
    standard = standard_of(path)
    subsystem = ""
    if len(identity) != 3:
        problems.append("phần định danh phải có ba dòng TỆP, PHÂN HỆ, CHUẨN")
    else:
        if _value(identity[0], FILE_LABEL) != path:
            problems.append(f"dòng TỆP phải là \"{field(FILE_LABEL, path)}\"")
        value = _value(identity[1], SUBSYSTEM_LABEL)
        if value is None or not value.strip() or value != value.strip():
            problems.append("dòng PHÂN HỆ phải có nội dung, không thừa dấu cách")
        else:
            subsystem = value
        if _value(identity[2], STANDARD_LABEL) != standard:
            problems.append(f"dòng CHUẨN phải là \"{field(STANDARD_LABEL, standard)}\"")
    items: list[str] = []
    if len(features) < 2 or features[0] != FEATURES_LABEL:
        problems.append(f"phần chức năng phải mở bằng \"{FEATURES_LABEL}\" rồi ít nhất một ý")
    else:
        items = join_items(features[1:])
        if not features[1].startswith(BULLET):
            problems.append("dòng ý đầu tiên phải mở bằng \"- \"")
        if len(features) - 1 > MAX_BULLET_LINES:
            problems.append(f"khung có {len(features) - 1} dòng ý, tối đa {MAX_BULLET_LINES}")
    if authors != [field(AUTHOR_LABEL, AUTHOR), field(TELEGRAM_LABEL, TELEGRAM)]:
        problems.append(f"hai dòng cuối phải là TÁC GIẢ : {AUTHOR} và TELEGRAM : {TELEGRAM}")
    return items, subsystem
