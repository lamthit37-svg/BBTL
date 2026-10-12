# Sinh tests/protocol_samples.hpp: ba mẫu cho mỗi tin (nhỏ nhất, lớn nhất theo mọi trần với chữ nhiều
# byte, thường gặp), mỗi mẫu có giá trị C++ và byte mong đợi do protocol_wire.py tính (DE-BAI §3.5).
"""render_samples(catalog) trả nội dung protocol_samples.hpp, LF, kết thúc bằng một LF."""

from __future__ import annotations

import struct

from protocol_cpp_hpp import walk_types
from protocol_cxx import COLUMNS, CPP_SCALARS, NOTICE, chunks, limit_name, pack, part_name, snake, wrap_comment
from protocol_model import Catalog, Field, Message, TypeRef
from protocol_wire import SIGNED, TYPICAL_TEXT, VARIANTS, Value, encode_frame, owner_sample

PART = 30
DECODER_BITS = (("game", False, "kGameClient"), ("game", True, "kGameServer"), ("auth", False, "kAuthClient"),
                ("auth", True, "kAuthServer"))
PRELUDE = r"""// Bộ giải mã nào nhận tin: mỗi bit một bộ.
inline constexpr std::uint8_t kGameClient = 1;
inline constexpr std::uint8_t kGameServer = 2;
inline constexpr std::uint8_t kAuthClient = 4;
inline constexpr std::uint8_t kAuthServer = 8;

using Check = std::expected<bool, protocol::WireError>;
// Bộ đệm ghi của hàm mã hoá mẫu; tên ngắn để chữ ký nằm trọn một dòng (AGENTS.md mục 7).
using Buffer = std::vector<std::byte>;

// Một mẫu: khung đầy đủ do Python tính, hàm mã hoá giá trị C++ của mẫu, hàm giải mã thân bằng bộ
// giải mã đầu tiên nhận tin rồi so với giá trị mẫu.
struct Sample {
    std::string_view name;
    std::span<const std::uint8_t> frame;
    protocol::WireStatus (*encode)(Buffer& out) = nullptr;
    Check (*decode)(protocol::ByteView body) = nullptr;
    std::uint8_t decoders = 0;
};

// Mảng N byte, byte thứ i là (start + i * step) mod 256; cùng công thức với protocol_wire.py.
template <std::size_t N>
[[nodiscard]] std::array<std::byte, N> pattern(std::uint8_t start, std::uint8_t step) {
    std::array<std::byte, N> out{};
    for (std::size_t i = 0; i < N; ++i) {
        out.at(i) = static_cast<std::byte>((start + (i * step)) & 0xFFU);
    }
    return out;
}

// Chữ đúng bytes byte UTF-8, xen chữ 1, 2, 3, 4 byte rồi bù bằng 'a'; cùng thuật toán với
// fill_text của protocol_wire.py, nên mẫu lớn nhất chạm đúng trần.
[[nodiscard]] inline std::string wide_text(std::size_t bytes) {
    $kParts
    std::string out;
    std::size_t index = 0;
    while (out.size() + kParts.at(index % 4).size() <= bytes) {
        out += kParts.at(index++ % 4);
    }
    out.append(bytes - out.size(), 'a');
    return out;
}

// Kết quả giải mã giữ đúng kiểu Message và bằng giá trị mong đợi.
template <class Message, class Result>
[[nodiscard]] Check holds(const Result& result, const Message& wanted) {
    if (!result) return std::unexpected(result.error());
    const auto* message = std::get_if<Message>(&*result);
    return message != nullptr && *message == wanted;
}
"""
# Bốn chữ 1, 2, 3, 4 byte của wide_text. Dòng khai báo vừa hay không vừa một dòng là tuỳ trần cột, nên
# nó không nằm bẻ sẵn trong PRELUDE mà đi qua pack.
PARTS_MARK = "    $kParts"
PARTS = ('"A"', r'"\xC3\xA9"', r'"\xE1\xBB\x87"', r'"\xF0\xA0\x80\x80"')


def prelude_lines() -> list[str]:
    """PRELUDE với bảng kParts bẻ theo trần cột của dự án."""
    parts = pack("constexpr std::array<std::string_view, 4> kParts{", list(PARTS), "};", 4)
    return PRELUDE.replace(PARTS_MARK, "\n".join(parts)).splitlines()


def text_literal(text: str) -> str:
    """Chuỗi C++ chỉ có ASCII; byte ngoài ASCII viết \\xHH, tách chuỗi khi chữ sau là chữ số hex."""
    out = '"'
    after_escape = False
    for char in text:
        data = char.encode("utf-8")
        if len(data) == 1 and 0x20 <= data[0] < 0x7F and char not in '"\\':
            out += ('" "' if after_escape and char in "0123456789abcdefABCDEF" else "") + char
            after_escape = False
            continue
        out += "".join(f"\\x{byte:02X}" for byte in data)
        after_escape = True
    return out + '"'


def scalar_literal(name: str, value: Value) -> str:
    """Hằng C++ của số, bool, f32, thời lượng."""
    if name == "bool":
        return "true" if value else "false"
    if name == "f32":
        bits = struct.unpack("<I", struct.pack("<f", value))[0]
        return f"std::bit_cast<float>(0x{bits:08X}U)"
    if name in ("seconds16", "millis32", "millis64"):
        return f"{CPP_SCALARS[name]}{{{value}}}"
    number = int(str(value))
    if name in SIGNED and number == -(1 << (SIGNED[name] - 1)):
        return f"std::numeric_limits<{CPP_SCALARS[name]}>::min()"
    return str(number) if name in SIGNED else f"{number}U"


def literal(catalog: Catalog, ref: TypeRef, value: Value, limit: str, variant: str) -> str:
    """Biểu thức C++ cho một giá trị mẫu khác rỗng."""
    if ref.kind == "scalar":
        return scalar_literal(ref.name, value)
    if ref.kind == "enum":
        return f"protocol::{ref.name}::k{enum_name(catalog, ref, value)}"
    if ref.kind == "record":
        return f"{snake(ref.name)}_{variant}()"
    if ref.kind == "text":
        return f"wide_text(protocol::{limit})" if variant == "max" else text_literal(str(value))
    if ref.kind == "bytes":
        data = bytes(value)
        start, step = (data[0], (data[1] - data[0]) & 0xFF) if len(data) > 1 else (data[0] if data else 0, 0)
        return f"pattern<protocol::{limit}>({start}, {step})"
    return literal(catalog, ref.element(), value, limit, variant)


def enum_name(catalog: Catalog, ref: TypeRef, value: Value) -> str:
    return next(item.name for item in catalog.enum(ref.name).values if item.value == int(str(value)))


def element_literal(catalog: Catalog, ref: TypeRef, value: Value, limit: str, variant: str) -> str:
    """Phần tử của list: số nguyên bọc kiểu để assign(n, x) không phải đổi kiểu ngầm."""
    text = literal(catalog, ref, value, limit, variant)
    if ref.kind == "scalar" and ref.name.startswith(("u", "i")):
        return f"{CPP_SCALARS[ref.name]}{{{text}}}"
    return text


def field_statement(catalog: Catalog, owner: Message, item: Field, value: Value, variant: str) -> str | None:
    """Câu gán một trường; giá trị rỗng (text, list, optional) giữ mặc định nên không viết."""
    limit = limit_name(owner, item) if item.limit is not None else ""
    if value is None or value == "" or value == []:
        return None
    if item.type.kind == "list":
        items = list(value)  # mọi phần tử của một mẫu giống nhau
        first = element_literal(catalog, item.type.element(), items[0], limit, variant)
        return f"value.{item.name}.assign({len(items)}, {first});"
    return f"value.{item.name} = {literal(catalog, item.type, value, limit, variant)};"


def value_function(catalog: Catalog, owner: Message, values: dict[str, Value], variant: str) -> list[str]:
    """Hàm trả giá trị C++ của một mẫu; quá 30 trường thì tách phần fill_."""
    name = f"{snake(owner.name)}_{variant}"
    cpp = f"protocol::{owner.name}"
    body = [f"    {line}" for item in owner.fields
            if (line := field_statement(catalog, owner, item, values[item.name], variant)) is not None]
    if not owner.fields:
        return [f"[[nodiscard]] inline {cpp} {name}() {{", "    return {};", "}", ""]
    parts = chunks(body, PART)
    lines: list[str] = []
    for index in reversed(range(1, len(parts))):
        follow = [f"    {part_name('fill_' + name, index + 1, len(parts))}(value);"] if index + 1 < len(parts) else []
        lines.extend([f"inline void {part_name('fill_' + name, index, len(parts))}({cpp}& value) {{",
                      *parts[index], *follow, "}", ""])
    rest = [f"    {part_name('fill_' + name, 1, len(parts))}(value);"] if len(parts) > 1 else []
    return [*lines, f"[[nodiscard]] inline {cpp} {name}() {{", f"    {cpp} value;", *parts[0], *rest,
            "    return value;", "}", ""]


def decoder_of(message: Message) -> tuple[str, list[tuple[str, str]]]:
    """Bộ giải mã đầu tiên nhận tin, và mặt nạ mọi bộ nhận tin."""
    accepted = [(port, bit) for port, server, bit in DECODER_BITS
                if server == message.is_server and message.port in (port, "both")]
    port = accepted[0][0]
    side = "server" if message.is_server else "client"
    return f"decode_{port}_{side}", accepted


def designated(prefix: str, items: list[str]) -> list[str]:
    """Khởi tạo chỉ định như clang-format: vừa một dòng thì giữ, không thì mỗi trường một dòng."""
    single = prefix + ", ".join(items) + "};"
    if len(single) <= COLUMNS:
        return [single]
    return [prefix + items[0] + ",", *(f"    {item}," for item in items[1:-1]), f"    {items[-1]}}};"]


def sample_functions(catalog: Catalog, message: Message, variant: str) -> list[str]:
    """Hàm mã hoá, hàm giải mã, khung và bản ghi Sample của một mẫu."""
    base = f"{snake(message.name)}_{variant}"
    decoder, accepted = decoder_of(message)
    frame = encode_frame(catalog, message, owner_sample(catalog, message, variant))
    title = "".join(part.capitalize() for part in base.split("_"))
    mask = " | ".join(bit for _, bit in accepted)
    return [
        *pack(f"[[nodiscard]] inline protocol::WireStatus encode_{base}(", ["Buffer& out"], ") {", 0),
        f"    return protocol::encode(out, {base}());", "}", "",
        *pack(f"[[nodiscard]] inline Check decode_{base}(", ["protocol::ByteView body"], ") {", 0),
        "    protocol::Frame frame;", f"    frame.kind = protocol::{message.name}::kKind;",
        "    frame.body_bytes = body.size();",
        f"    const auto result = protocol::{decoder}(frame, body);",
        f"    return holds(result, {base}());",
        "}", "",
        *pack(f"inline constexpr std::array<std::uint8_t, {len(frame)}> k{title}Frame{{",
              [f"0x{byte:02X}" for byte in frame], "};", 0), "",
        *designated(f"inline constexpr Sample k{title}{{", [
            f'.name = "{message.name}/{variant}"', f".frame = k{title}Frame", f".encode = &encode_{base}",
            f".decode = &decode_{base}", f".decoders = {mask}"]), "",
    ]


def sample_includes(catalog: Catalog) -> list[str]:
    names = {ref.name for ref in walk_types(catalog)}
    kinds = {ref.kind for ref in walk_types(catalog)}
    wanted = {"array", "cstddef", "cstdint", "expected", "span", "string", "string_view", "variant", "vector"}
    used = {"bit": "f32" in names, "chrono": bool(names & {"seconds16", "millis32", "millis64"}),
            "limits": bool(names & set(SIGNED)), "optional": "optional" in kinds}
    wanted |= {name for name, flag in used.items() if flag}
    return [f"#include <{name}>" for name in sorted(wanted)]


def render_samples(catalog: Catalog) -> str:
    """Nội dung tests/protocol_samples.hpp."""
    lines = [*NOTICE, *wrap_comment(
        "Mẫu của từng tin cho tests/protocol_catalog_tests.cpp: nhỏ nhất, lớn nhất theo mọi trần, thường gặp."
        " Giá trị C++ và byte mong đợi cùng sinh từ một mẫu Python, byte do bộ mã hoá Python độc lập tính.", 0),
        "#pragma once", "", '#include "protocol/messages.hpp"', '#include "protocol/wire.hpp"', "",
        *sample_includes(catalog), "", "namespace game::test::samples {", "", *prelude_lines(), ""]
    for owner in (*catalog.records, *catalog.messages):
        for variant in VARIANTS:
            lines.extend(value_function(catalog, owner, owner_sample(catalog, owner, variant), variant))
    titles: list[str] = []
    for message in catalog.messages:
        for variant in VARIANTS:
            lines.extend(sample_functions(catalog, message, variant))
            titles.append("k" + "".join(part.capitalize() for part in f"{snake(message.name)}_{variant}".split("_")))
    lines.extend([*pack(f"inline constexpr std::array<Sample, {len(titles)}> kSamples{{", titles, "};", 0), "",
                  "} // namespace game::test::samples"])
    return "\n".join(lines) + "\n"

