# Phần chung của bộ sinh C++ cho danh mục tin: tên kiểu, tên hằng trần, comment và ngắt dòng theo đúng
# .clang-format của dự án (trần cột đọc từ chính tệp đó, thụt 4, phần tràn thụt thêm 4) để clang-format
# không đổi byte nào; test_gen_protocol.py chạy clang-format thật trên đầu ra để canh điều đó.
"""Hàm thuần: nhận Catalog, trả chuỗi C++."""

from __future__ import annotations

import re
from pathlib import Path

from protocol_model import Catalog, Enum, Field, Message, TypeRef, camel_to_snake, snake_to_camel


def column_limit() -> int:
    """Trần cột của dự án: dòng ColumnLimit của .clang-format ở gốc repo, không chép số sang đây."""
    text = (Path(__file__).resolve().parents[2] / ".clang-format").read_text(encoding="utf-8")
    found = re.search(r"^ColumnLimit:[ \t]*(\d+)[ \t]*$", text, re.MULTILINE)
    if found is None:
        raise ValueError(".clang-format thiếu dòng ColumnLimit")
    return int(found.group(1))


COLUMNS = column_limit()
COMMAND = "python -B TOOLS/server/gen_protocol.py"
NOTICE = (
    "// Tệp sinh bởi TOOLS/server/gen_protocol.py từ SRC/protocol/catalog/*.tsv; không sửa tay.",
    f"// Sửa bảng rồi chạy lại: {COMMAND}",
)
CPP_SCALARS = {
    "u8": "std::uint8_t", "u16": "std::uint16_t", "u32": "std::uint32_t", "u64": "std::uint64_t",
    "i8": "std::int8_t", "i16": "std::int16_t", "i32": "std::int32_t", "i64": "std::int64_t",
    "bool": "bool", "f32": "float",
    "seconds16": "std::chrono::seconds", "millis32": "std::chrono::milliseconds",
    "millis64": "std::chrono::milliseconds",
}
# Hàm của Writer và Reader cho từng kiểu số.
WIRE_METHOD = {
    "u8": "u8", "u16": "u16", "u32": "u32", "u64": "u64", "i8": "i8", "i16": "i16", "i32": "i32",
    "i64": "i64", "bool": "boolean", "f32": "f32",
}
DURATIONS = ("seconds16", "millis32", "millis64")


def wrap_comment(text: str, indent: int) -> list[str]:
    """Comment `//` ngắt theo từ, mỗi dòng không quá trần cột."""
    lines: list[str] = []
    current = ""
    for word in text.split():
        candidate = f"{current} {word}" if current else word
        if current and indent + 3 + len(candidate) > COLUMNS:
            lines.append(" " * indent + "// " + current)
            candidate = word
        current = candidate
    if current:
        lines.append(" " * indent + "// " + current)
    return lines


def pack(prefix: str, items: list[str], suffix: str, indent: int,
         open_break: bool = True) -> list[str]:
    """Danh sách cách nhau bằng dấu phẩy, ngắt như clang-format.

    Vừa một dòng thì giữ; cả danh sách vừa dòng sau thì ngắt ngay sau dấu mở (trừ đối số template,
    open_break=False); không thì dồn đầy từng dòng (BinPack), dòng sau thụt thêm 4.
    """
    single = " " * indent + prefix + ", ".join(items) + suffix
    after = " " * (indent + 4) + ", ".join(items) + suffix
    if len(single) <= COLUMNS:
        return [single]
    if open_break and items and prefix.strip() and len(after) <= COLUMNS:
        return [(" " * indent + prefix).rstrip(), after]
    lines: list[str] = []
    current = " " * indent + prefix
    for index, item in enumerate(items):
        tail = suffix if index == len(items) - 1 else ","
        joiner = "" if current.endswith(("(", "<", "{")) or current.strip() == "" else " "
        if len(current) + len(joiner) + len(item) + len(tail) > COLUMNS and current.strip():
            lines.append(current.rstrip())
            current = " " * (indent + 4)
            joiner = ""
        current += joiner + item + tail
    if not items:
        current += suffix
    lines.append(current)
    return lines


def one_line_or_wrapped(head: str, body: str, indent: int) -> list[str]:
    """`case X: return y;` một dòng nếu vừa trần cột, không thì return xuống dòng thụt thêm 4."""
    line = " " * indent + head + " " + body
    if len(line) <= COLUMNS:
        return [line]
    return [" " * indent + head, " " * (indent + 4) + body]


def snake(name: str) -> str:
    return camel_to_snake(name)


def enum_constant(name: str) -> str:
    return "k" + name


def limit_name(owner: Message, item: Field) -> str:
    """Hằng trần của một trường: kLoginAccountBytes, kCharacterListCharactersCount."""
    unit = "Count" if item.type.kind == "list" else "Bytes"
    return f"k{owner.name}{snake_to_camel(item.name)}{unit}"


def value_type(ref: TypeRef, limit: str) -> str:
    """Kiểu C++ của một giá trị; limit là tên hằng trần dùng cho std::array của bytes."""
    if ref.kind == "scalar":
        return CPP_SCALARS[ref.name]
    if ref.kind in ("enum", "record"):
        return ref.name
    if ref.kind == "text":
        return "std::string"
    if ref.kind == "bytes":
        return f"std::array<std::byte, {limit}>"
    if ref.kind == "list":
        return f"std::vector<{value_type(ref.element(), limit)}>"
    return f"std::optional<{value_type(ref.element(), limit)}>"


def default_init(catalog: Catalog, ref: TypeRef) -> str:
    """Giá trị mặc định của thành viên; kiểu lớp có hàm dựng mặc định thì để trống."""
    if ref.kind == "scalar":
        if ref.name in DURATIONS:
            return f" = {CPP_SCALARS[ref.name]}::zero()"
        return {"bool": " = false", "f32": " = 0.0F"}.get(ref.name, " = 0")
    if ref.kind == "enum":
        first = catalog.enum(ref.name).values[0]
        return f" = {ref.name}::{enum_constant(first.name)}"
    return "{}" if ref.kind == "bytes" else ""


def enum_ranges(item: Enum) -> list[tuple[int, int]]:
    """Các đoạn giá trị liền nhau của một enum, theo thứ tự tăng."""
    ranges: list[tuple[int, int]] = []
    for entry in item.values:
        if ranges and ranges[-1][1] + 1 == entry.value:
            ranges[-1] = (ranges[-1][0], entry.value)
        else:
            ranges.append((entry.value, entry.value))
    return ranges


def range_test(low: int, high: int, top: int) -> str:
    """Điều kiện `raw` nằm trong [low, high]; bỏ vế luôn đúng để GCC không báo -Wtype-limits."""
    if low == high:
        return f"raw == {low}"
    if high == top:
        return f"raw >= {low}"
    return f"raw >= {low} && raw <= {high}"


def chunks(lines: list[str], size: int) -> list[list[str]]:
    """Cắt thân hàm dài thành nhiều phần để mỗi hàm sinh ra dưới 40 dòng."""
    return [lines[start:start + size] for start in range(0, len(lines), size)] or [[]]


def chunk_units(units: list[list[str]], size: int) -> list[list[str]]:
    """Như chunks nhưng mỗi đơn vị (một `case` có thể bẻ hai dòng) nằm trọn trong một phần."""
    parts: list[list[str]] = [[]]
    for unit in units:
        if parts[-1] and len(parts[-1]) + len(unit) > size:
            parts.append([])
        parts[-1].extend(unit)
    return parts


def part_name(base: str, index: int, total: int) -> str:
    """Tên hàm phần thứ index; `_<số>_of_<số>` không trùng được với tên snake_case nào của bảng."""
    return base if total == 1 or index == 0 else f"{base}_{index + 1}_of_{total}"
