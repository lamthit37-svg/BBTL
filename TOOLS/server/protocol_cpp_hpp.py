# Sinh SRC/protocol/messages.hpp từ danh mục tin: kVersion, enum, hằng trần, struct, variant theo cổng và
# chiều, khai báo encode và bốn bộ giải mã (DE-BAI §3.5).
"""render_header(catalog) trả nội dung messages.hpp, LF, kết thúc bằng một LF."""

from __future__ import annotations

from protocol_cxx import (
    COLUMNS, NOTICE, default_init, enum_constant, limit_name, pack, value_type, wrap_comment,
)
from protocol_model import Catalog, Message, TypeRef

DECODERS = (("game", False, "GameClient"), ("game", True, "GameServer"), ("auth", False, "AuthClient"),
            ("auth", True, "AuthServer"))


def walk_types(catalog: Catalog) -> list[TypeRef]:
    """Mọi kiểu xuất hiện trong bảng, kể cả kiểu bên trong list và optional."""
    found: list[TypeRef] = []
    pending = [f.type for owner in (*catalog.records, *catalog.messages) for f in owner.fields]
    while pending:
        ref = pending.pop()
        found.append(ref)
        if ref.inner is not None:
            pending.append(ref.inner)
    return found


def header_includes(catalog: Catalog) -> list[str]:
    """Header chuẩn mà messages.hpp thật sự dùng (misc-include-cleaner)."""
    kinds = {ref.kind for ref in walk_types(catalog)}
    names = {ref.name for ref in walk_types(catalog)}
    wanted = {"cstddef", "cstdint", "expected", "variant", "vector"}
    optional = {"array": "bytes" in kinds, "optional": "optional" in kinds, "string": "text" in kinds,
                "chrono": bool(names & {"seconds16", "millis32", "millis64"})}
    wanted |= {name for name, used in optional.items() if used}
    return [f"#include <{name}>" for name in sorted(wanted)]


# Bảng khai u16 mà mọi giá trị vừa u8: cỡ trên dây theo bảng (byte của Dev), không theo tập giá trị.
WIDE_ENUM = "// NOLINTNEXTLINE(performance-enum-size): cỡ trên dây theo bảng, giữ byte của Dev (HP-07)"


def render_enums(catalog: Catalog) -> list[str]:
    """enum class có kiểu nền cố định, giá trị viết tường minh để số trên dây đọc được ngay."""
    lines: list[str] = []
    for item in catalog.enums:
        if item.underlying == "u16" and max(entry.value for entry in item.values) <= 0xFF:
            lines.append(WIDE_ENUM)
        lines.append(f"enum class {item.name} : std::{item.underlying.replace('u', 'uint')}_t {{")
        for entry in item.values:
            lines.extend(wrap_comment(entry.note, 4))
            lines.append(f"    {enum_constant(entry.name)} = {entry.value},")
        lines.extend(["};", ""])
    lines.append("// Giá trị có trong bảng enum; giải mã gặp giá trị lạ là kBadEnum, mã hoá cũng vậy.")
    lines.extend(f"[[nodiscard]] bool is_valid({item.name} value) noexcept;" for item in catalog.enums)
    return lines


def render_limits(catalog: Catalog) -> list[str]:
    """Hằng trần của từng trường: số byte của text và bytes, số phần tử của list."""
    lines = ["// Trần của từng trường: số byte của text và bytes, số phần tử của list."]
    for owner in (*catalog.records, *catalog.messages):
        for item in owner.fields:
            if item.limit is not None:
                lines.append(f"inline constexpr std::size_t {limit_name(owner, item)} = {item.limit};")
    return lines if len(lines) > 1 else []


def struct_comment(owner: Message) -> list[str]:
    if owner.is_record:
        return wrap_comment(f"Record: {owner.summary}", 0)
    direction = "server gửi" if owner.is_server else "client gửi"
    text = f"{owner.kind_text()}, {direction}, cổng {owner.port}, từ bản {owner.since}: {owner.summary}"
    return wrap_comment(text, 0)


def render_struct(catalog: Catalog, owner: Message) -> list[str]:
    """Một struct: mọi thành viên có giá trị mặc định, operator== mặc định."""
    lines = [*struct_comment(owner), f"struct {owner.name} {{"]
    if not owner.is_record:
        lines.append(f"    static constexpr std::uint16_t kKind = {owner.kind_text()};")
    for item in owner.fields:
        limit = limit_name(owner, item) if item.limit is not None else ""
        lines.extend(wrap_comment(item.note, 4))
        lines.append(f"    {value_type(item.type, limit)} {item.name}{default_init(catalog, item.type)};")
    lines.append(f"    friend bool operator==(const {owner.name}&, const {owner.name}&) = default;")
    lines.extend(["};", ""])
    return lines


def variant_lines(catalog: Catalog) -> list[str]:
    """Kiểu kết quả của bốn bộ giải mã; cổng không có tin nào thì variant chỉ có std::monostate."""
    lines: list[str] = []
    for port, server, prefix in DECODERS:
        names = [m.name for m in catalog.port_messages(port, server)] or ["std::monostate"]
        variant = pack("std::variant<", names, ">;", 4, open_break=False)
        head = f"using {prefix}Message = "
        if len(variant) == 1 and len(head) + len(variant[0]) - 4 <= COLUMNS:
            lines.append(head + variant[0].lstrip())
        elif len(variant) == 1:
            lines.extend([head.rstrip(), variant[0]])
        else:
            lines.extend(pack(head + "std::variant<", names, ">;", 0, open_break=False))
        lines.append(f"using {prefix}Result = std::expected<{prefix}Message, WireError>;")
    return lines


def decoder_name(prefix: str) -> str:
    return "decode_" + ("game_" if prefix.startswith("Game") else "auth_") + (
        "server" if prefix.endswith("Server") else "client")


def render_api(catalog: Catalog) -> list[str]:
    """Khai báo encode cho mọi tin và bốn bộ giải mã."""
    lines = ["// Ghi một khung (đầu khung 8 byte cộng thân) vào cuối out; lỗi thì out giữ nguyên cỡ cũ."]
    for message in catalog.messages:
        lines.extend(pack("[[nodiscard]] WireStatus encode(", ["std::vector<std::byte>& out",
                     f"const {message.name}& message"], ");", 0))
    lines.extend(["", *wrap_comment(
        "Giải mã thân của một khung đã tách bằng peek_frame. Kind không thuộc cổng hoặc chiều của bộ"
        " giải mã là kUnknownKind; còn byte sau trường cuối là kTrailingBytes.", 0)])
    for _, _, prefix in DECODERS:
        lines.extend(pack(f"[[nodiscard]] {prefix}Result {decoder_name(prefix)}(",
                          ["const Frame& frame", "ByteView body"], ");", 0))
    return lines


def render_header(catalog: Catalog) -> str:
    """Nội dung SRC/protocol/messages.hpp."""
    lines = [*NOTICE, *wrap_comment(
        "Danh mục tin của protocol (DE-BAI P2 đợt 2 §3): enum, hằng trần, struct của từng tin, encode"
        " và bốn bộ giải mã theo cổng (game, auth) và chiều (client gửi, server gửi).", 0),
        "#pragma once", "", '#include "protocol/wire.hpp"', "", *header_includes(catalog), "",
        "namespace game::protocol {", "",
        "// Bản của danh mục; tin có since lớn hơn bản bên kia đang chạy thì bên kia chưa hiểu.",
        f"inline constexpr std::uint16_t kVersion = {catalog.version};", ""]
    if catalog.enums:
        lines.extend([*render_enums(catalog), ""])
    limits = render_limits(catalog)
    if limits:
        lines.extend([*limits, ""])
    for owner in (*catalog.records, *catalog.messages):
        lines.extend(render_struct(catalog, owner))
    lines.extend([*variant_lines(catalog), "", *render_api(catalog), "", "} // namespace game::protocol"])
    return "\n".join(lines) + "\n"
