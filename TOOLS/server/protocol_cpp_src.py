# Sinh SRC/protocol/messages.cpp: mỗi tin và record một hàm ghi và một hàm đọc từng trường theo order,
# mọi byte đi qua Writer và Reader của wire.hpp (DE-BAI §3.5). Hàm sinh ra dưới 40 dòng, lồng tối đa 1.
"""render_source(catalog) trả nội dung messages.cpp, LF, kết thúc bằng một LF."""

from __future__ import annotations

from dataclasses import dataclass, field

from protocol_cpp_hpp import DECODERS, decoder_name, walk_types
from protocol_cxx import (
    DURATIONS, NOTICE, WIRE_METHOD, chunk_units, chunks, enum_ranges, limit_name, one_line_or_wrapped, pack,
    part_name, range_test, snake, value_type, wrap_comment,
)
from protocol_model import UNDERLYING_MAX, Catalog, Enum, Field, Message, TypeRef

PART = 30
DURATION_HELPERS = {
    "seconds16": ("std::chrono::seconds", "u16", "std::uint16_t", "value.count() > 0xFFFF"),
    "millis32": ("std::chrono::milliseconds", "u32", "std::uint32_t", "value.count() > 0xFFFF'FFFF"),
}


@dataclass
class Helpers:
    """Hàm phụ của list và optional, đặt tên theo số thứ tự lần gặp đầu để bảng nào cũng sinh tất định."""

    names: dict[tuple[str, str], str] = field(default_factory=dict)
    lines: list[str] = field(default_factory=list)

    def name(self, ref: TypeRef, limit: str) -> tuple[str, bool]:
        key = (ref.spell(), limit)
        if key in self.names:
            return self.names[key], False
        self.names[key] = f"{ref.kind}_{len(self.names) + 1}"
        return self.names[key], True


def put_element(ref: TypeRef, expr: str, limit: str, helpers: Helpers) -> str:
    """Câu lệnh ghi một giá trị."""
    if ref.kind == "scalar" and ref.name not in DURATIONS:
        return f"writer.{WIRE_METHOD[ref.name]}({expr});"
    if ref.kind == "text":
        return f"writer.text({expr}, {limit});"
    if ref.kind == "bytes":
        return f"writer.bytes({expr});"
    if ref.kind in ("list", "optional"):
        return f"put_{use_helper(ref, limit, helpers)}(writer, {expr});"
    return f"put_{ref.name if ref.kind == 'scalar' else snake(ref.name)}(writer, {expr});"


def get_element(ref: TypeRef, limit: str, helpers: Helpers) -> str:
    """Biểu thức đọc một giá trị (không dùng cho bytes, vốn đọc vào mảng có sẵn)."""
    if ref.kind == "scalar" and ref.name not in DURATIONS:
        return f"reader.{WIRE_METHOD[ref.name]}()"
    if ref.kind == "text":
        return f"reader.text({limit})"
    if ref.kind in ("list", "optional"):
        return f"get_{use_helper(ref, limit, helpers)}(reader)"
    return f"get_{ref.name if ref.kind == 'scalar' else snake(ref.name)}(reader)"


def use_helper(ref: TypeRef, limit: str, helpers: Helpers) -> str:
    """Tên hàm phụ của một kiểu list hoặc optional; lần đầu gặp thì sinh luôn thân hàm."""
    name, fresh = helpers.name(ref, limit)
    if fresh:
        body = list_helper(ref, limit, name, helpers) if ref.kind == "list" else optional_helper(
            ref, limit, name, helpers)
        helpers.lines.extend(body)
    return name


def list_helper(ref: TypeRef, limit: str, name: str, helpers: Helpers) -> list[str]:
    """Ghi số phần tử rồi từng phần tử; đọc thì dừng ngay khi reader lỗi, không cấp phát theo số khai."""
    element = ref.element()
    inner = value_type(element, limit)
    put = put_element(element, "value", limit, helpers)
    get = get_element(element, limit, helpers)
    return [
        *wrap_comment(f"{ref.spell()}, tối đa {limit} phần tử.", 0),
        *pack(f"void put_{name}(", ["Writer& writer", f"const std::vector<{inner}>& values"], ") {", 0),
        f"    writer.count(values.size(), {limit});",
        "    for (const auto& value : values) {", f"        {put}", "    }", "}", "",
        *pack(f"[[nodiscard]] std::vector<{inner}> get_{name}(", ["Reader& reader"], ") {", 0),
        f"    const std::size_t count = reader.count({limit});",
        f"    std::vector<{inner}> values;", "    values.reserve(count);",
        "    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {",
        f"        values.push_back({get});", "    }", "    return values;", "}", "",
    ]


def optional_helper(ref: TypeRef, limit: str, name: str, helpers: Helpers) -> list[str]:
    """Byte cờ 0 hoặc 1 (giá trị khác là kBadEnum, do Reader::boolean kiểm) rồi giá trị nếu có."""
    element = ref.element()
    inner = value_type(element, limit)
    if element.kind == "bytes":
        read = [f"    {inner} value{{}};", "    reader.bytes(value);", "    return value;"]
    else:
        read = [f"    return {get_element(element, limit, helpers)};"]
    return [
        *wrap_comment(f"{ref.spell()}.", 0),
        *pack(f"void put_{name}(", ["Writer& writer", f"const std::optional<{inner}>& value"], ") {", 0),
        "    writer.boolean(value.has_value());",
        *one_line_or_wrapped("if (value.has_value())", put_element(element, "*value", limit, helpers), 4),
        "}", "",
        *pack(f"[[nodiscard]] std::optional<{inner}> get_{name}(", ["Reader& reader"], ") {", 0),
        "    if (!reader.boolean()) return std::nullopt;", *read, "}", "",
    ]


def duration_helpers(catalog: Catalog) -> list[str]:
    """Thời lượng: âm hoặc quá cỡ kiểu trên dây là kOutOfRange (hợp đồng không có require như Dev)."""
    used = sorted({ref.name for ref in walk_types(catalog) if ref.kind == "scalar" and ref.name in DURATIONS})
    lines: list[str] = []
    for name in used:
        if name == "millis64":
            lines.extend(millis64_helpers())
            continue
        cpp, method, wire, too_big = DURATION_HELPERS[name]
        lines.extend([
            f"void put_{name}(Writer& writer, {cpp} value) {{",
            f"    if (value.count() < 0 || {too_big}) writer.fail(WireError::kOutOfRange);",
            f"    writer.{method}(static_cast<{wire}>(value.count()));", "}", "",
            f"[[nodiscard]] {cpp} get_{name}(Reader& reader) {{",
            f"    return {cpp}{{reader.{method}()}};", "}", "",
        ])
    return lines


def millis64_helpers() -> list[str]:
    """milliseconds có rep là int64, nên số u64 trên 2^63 - 1 không biểu diễn được: kOutOfRange."""
    return [
        "void put_millis64(Writer& writer, std::chrono::milliseconds value) {",
        "    if (value.count() < 0) writer.fail(WireError::kOutOfRange);",
        "    writer.u64(static_cast<std::uint64_t>(value.count()));", "}", "",
        *wrap_comment("Số u64 trên 2^63 - 1 không vừa rep int64 của milliseconds: kOutOfRange.", 0),
        "[[nodiscard]] std::chrono::milliseconds get_millis64(Reader& reader) {",
        "    const std::uint64_t raw = reader.u64();",
        "    const bool fits = std::cmp_less_equal(raw, std::numeric_limits<std::int64_t>::max());",
        "    if (!fits) reader.fail(WireError::kOutOfRange);",
        "    return std::chrono::milliseconds{fits ? static_cast<std::int64_t>(raw) : 0};", "}", "",
    ]


def enum_helpers(item: Enum) -> list[str]:
    """Ghi và đọc một enum; giá trị ngoài bảng là kBadEnum ở cả hai chiều."""
    method = item.underlying
    name = snake(item.name)
    return [
        f"void put_{name}(Writer& writer, {item.name} value) {{",
        "    if (!is_valid(value)) writer.fail(WireError::kBadEnum);",
        f"    writer.{method}(std::to_underlying(value));", "}", "",
        f"[[nodiscard]] {item.name} get_{name}(Reader& reader) {{",
        f"    const auto value = static_cast<{item.name}>(reader.{method}());",
        "    if (!is_valid(value)) reader.fail(WireError::kBadEnum);", "    return value;", "}", "",
    ]


def field_put(owner: Message, item: Field, helpers: Helpers) -> str:
    limit = limit_name(owner, item) if item.limit is not None else ""
    return put_element(item.type, f"message.{item.name}", limit, helpers)


def field_get(owner: Message, item: Field, helpers: Helpers) -> str:
    limit = limit_name(owner, item) if item.limit is not None else ""
    if item.type.kind == "bytes":
        return f"reader.bytes(message.{item.name});"
    return f"message.{item.name} = {get_element(item.type, limit, helpers)};"


def owner_functions(owner: Message, helpers: Helpers) -> list[str]:
    """put_<tên> và get_<tên> của một tin hoặc record, cắt phần khi quá 30 trường."""
    base = snake(owner.name)
    puts = chunks(["    " + field_put(owner, item, helpers) for item in owner.fields], PART)
    gets = chunks(["    " + field_get(owner, item, helpers) for item in owner.fields], PART)
    lines: list[str] = []
    total = len(puts)
    for index in reversed(range(total)):
        follow = [] if index + 1 == total else [f"    {part_name('put_' + base, index + 1, total)}(writer, message);"]
        head = part_name("put_" + base, index, total)
        lines.extend([*pack(f"void {head}(", ["Writer& writer", f"const {owner.name}& message"], ") {", 0),
                      *puts[index], *follow, "}", ""])
    for index in reversed(range(1, total)):
        head = part_name("get_" + base, index, total)
        follow = [] if index + 1 == total else [f"    {part_name('get_' + base, index + 1, total)}(reader, message);"]
        lines.extend([*pack(f"void {head}(", ["Reader& reader", f"{owner.name}& message"], ") {", 0),
                      *gets[index], *follow, "}", ""])
    rest = [] if total == 1 else [f"    {part_name('get_' + base, 1, total)}(reader, message);"]
    lines.extend([f"[[nodiscard]] {owner.name} get_{base}(Reader& reader) {{", f"    {owner.name} message;",
                  *gets[0], *rest, "    return message;", "}", ""])
    return lines


def is_valid_function(item: Enum) -> list[str]:
    """is_valid: mỗi đoạn giá trị liền nhau một câu bảo vệ."""
    top = UNDERLYING_MAX[item.underlying]
    tests = [range_test(low, high, top) for low, high in enum_ranges(item)]
    body = [f"    if ({test}) return true;" for test in tests[:-1]] + [f"    return {tests[-1]};"]
    return [f"bool is_valid({item.name} value) noexcept {{", "    const auto raw = std::to_underlying(value);",
            *body, "}", ""]


def decode_case(message: Message) -> list[str]:
    read = f"get_{snake(message.name)}(reader)" if message.fields else f"{message.name}{{}}"
    return one_line_or_wrapped(f"case {message.name}::kKind:", f"return checked(reader, {read});", 4)


def single_decoder(prefix: str, name: str, message: Message) -> list[str]:
    """Cổng chỉ có một tin: dùng if thay switch một nhánh (readability-trivial-switch)."""
    read = f"get_{snake(message.name)}(reader)" if message.fields else f"{message.name}{{}}"
    return [*pack(f"{prefix}Result {name}(", ["const Frame& frame", "ByteView body"], ") {", 0),
            f"    if (frame.kind != {message.name}::kKind) {{",
            "        return std::unexpected(WireError::kUnknownKind);", "    }",
            "    Reader reader{body};",
            f"    return checked(reader, {read});", "}", ""]


def decoder_functions(catalog: Catalog, prefix: str, port: str, server: bool) -> tuple[list[str], list[str]]:
    """Bộ giải mã của một cổng và một chiều: (phần phụ trong namespace ẩn danh, hàm công khai)."""
    name = decoder_name(prefix)
    messages = catalog.port_messages(port, server)
    if not messages:
        return [], [*pack(f"{prefix}Result {name}(", ["[[maybe_unused]] const Frame& frame",
                                                       "[[maybe_unused]] ByteView body"], ") {", 0),
                    "    return std::unexpected(WireError::kUnknownKind);", "}", ""]
    if len(messages) == 1:
        return [], single_decoder(prefix, name, messages[0])
    parts = chunk_units([decode_case(message) for message in messages], PART)
    total = len(parts)
    hidden: list[str] = []
    for index in reversed(range(1, total)):
        follow = (f"    default: return {part_name(name, index + 1, total)}(kind, reader);"
                  if index + 1 < total else "    default: return std::unexpected(WireError::kUnknownKind);")
        hidden.extend([*pack(f"[[nodiscard]] {prefix}Result {part_name(name, index, total)}(",
                             ["std::uint16_t kind", "Reader& reader"], ") {", 0),
                       "    switch (kind) {", *parts[index], follow, "    }", "}", ""])
    follow = (f"    default: return {part_name(name, 1, total)}(frame.kind, reader);" if total > 1
              else "    default: return std::unexpected(WireError::kUnknownKind);")
    public = [*pack(f"{prefix}Result {name}(", ["const Frame& frame", "ByteView body"], ") {", 0),
              "    Reader reader{body};", "    switch (frame.kind) {", *parts[0], follow, "    }", "}", ""]
    return hidden, public


def encode_function(message: Message) -> list[str]:
    param = f"const {message.name}& message" if message.fields else f"[[maybe_unused]] const {message.name}& message"
    put = [f"    put_{snake(message.name)}(writer, message);"] if message.fields else []
    return [*pack("WireStatus encode(", ["std::vector<std::byte>& out", param], ") {", 0),
            "    Writer writer{out};", *put, f"    return writer.finish({message.name}::kKind);", "}", ""]


CHECKED = [
    *wrap_comment("Thân phải hết đúng lúc đọc xong trường cuối; lỗi đầu tiên của reader được giữ.", 0),
    "template <class Message>",
    "[[nodiscard]] std::expected<Message, WireError> checked(const Reader& reader, Message message) {",
    "    const WireStatus status = reader.finish();",
    "    if (!status) return std::unexpected(status.error());",
    "    return message;", "}", "",
]


def source_includes(catalog: Catalog) -> list[str]:
    """Header chuẩn mà messages.cpp gọi tên trực tiếp (misc-include-cleaner)."""
    refs = walk_types(catalog)
    kinds = {ref.kind for ref in refs}
    names = {ref.name for ref in refs}
    wanted = {"cstddef", "cstdint", "expected", "vector"}
    optional = {
        "array": any(r.kind == "optional" and r.element().kind == "bytes" for r in refs),
        "chrono": bool(names & set(DURATIONS)), "optional": "optional" in kinds,
        "limits": "millis64" in names, "utility": bool(catalog.enums) or "millis64" in names,
    }
    wanted |= {name for name, used in optional.items() if used}
    return [f"#include <{name}>" for name in sorted(wanted)]


def empty_record_functions(owner: Message) -> list[str]:
    """put_ và get_ của record không có trường: không ghi, không đọc byte nào (list của nó bị G6 chặn)."""
    base = snake(owner.name)
    params = ["[[maybe_unused]] const Writer& writer", f"[[maybe_unused]] const {owner.name}& message"]
    return [*pack(f"void put_{base}(", params, ") {", 0),
            "    // Record không có trường: không ghi byte nào.", "}", "",
            f"[[nodiscard]] {owner.name} get_{base}([[maybe_unused]] const Reader& reader) {{",
            "    // Record không có trường: không đọc byte nào.", f"    return {owner.name}{{}};", "}", ""]


def body_functions(catalog: Catalog) -> list[str]:
    """Hàm phụ của thời lượng, enum, record, list, optional và từng tin, theo thứ tự dùng."""
    lines = duration_helpers(catalog)
    for item in catalog.enums:
        lines.extend(enum_helpers(item))
    helpers = Helpers()
    for owner in (*catalog.records, *catalog.messages):
        if not owner.fields:
            lines.extend(empty_record_functions(owner) if owner.is_record else [])
            continue
        functions = owner_functions(owner, helpers)
        lines.extend(helpers.lines)
        helpers.lines.clear()
        lines.extend(functions)
    return lines


def render_source(catalog: Catalog) -> str:
    """Nội dung SRC/protocol/messages.cpp."""
    hidden: list[str] = []
    public: list[str] = []
    for port, server, prefix in DECODERS:
        part_hidden, part_public = decoder_functions(catalog, prefix, port, server)
        hidden.extend(part_hidden)
        public.extend(part_public)
    uses_checked = any(catalog.port_messages(port, server) for port, server, _ in DECODERS)
    lines = [*NOTICE, *wrap_comment(
        "Mã hoá và giải mã của danh mục tin: mỗi tin một hàm ghi và một hàm đọc từng trường theo order."
        " Mọi byte đi qua Writer và Reader của wire.hpp, nên trần, UTF-8 và byte thừa chỉ kiểm ở một chỗ.", 0),
        '#include "protocol/messages.hpp"', "", '#include "protocol/wire.hpp"', "", *source_includes(catalog), "",
        "namespace game::protocol {", "namespace {", "", *body_functions(catalog), *(CHECKED if uses_checked else []),
        *hidden, "} // namespace", ""]
    for item in catalog.enums:
        lines.extend(is_valid_function(item))
    for message in catalog.messages:
        lines.extend(encode_function(message))
    lines.extend([*public, "} // namespace game::protocol"])
    return "\n".join(lines) + "\n"
