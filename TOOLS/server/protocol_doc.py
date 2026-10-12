# Sinh docs/PROTOCOL-TIN.md: bảng tin theo nhóm, trường của từng tin, record và enum, cùng cỡ thân lớn
# nhất tính từ trần của bảng, để người đọc không phải mở TSV.
"""render_doc(catalog) trả nội dung PROTOCOL-TIN.md, LF, kết thúc bằng một LF."""

from __future__ import annotations

from protocol_cxx import COMMAND
from protocol_model import CLIENT_BODY_BYTES, MAX_BODY_BYTES, Catalog, Message, body_max_bytes

PORT_TEXT = {"game": "game", "auth": "auth", "both": "game, auth"}


def cell(text: str) -> str:
    """Ô bảng Markdown: thoát dấu `|`, ô rỗng ghi gạch ngang."""
    return text.replace("|", "\\|") if text else "–"


def number(value: int) -> str:
    return f"{value:,}".replace(",", " ")


def field_table(owner: Message) -> list[str]:
    if not owner.fields:
        return ["Tin không có trường: thân rỗng.", ""]
    lines = ["| Thứ tự | Trường | Kiểu | Trần | Ghi chú |", "|---|---|---|---|---|"]
    for item in owner.fields:
        limit = "" if item.limit is None else str(item.limit)
        lines.append(f"| {item.order} | `{item.name}` | `{item.type.spell()}` | {cell(limit)} | {cell(item.note)} |")
    return [*lines, ""]


def owner_section(catalog: Catalog, owner: Message) -> list[str]:
    title = owner.name if owner.is_record else f"{owner.name} ({owner.kind_text()})"
    facts = f"Thân tối đa {number(body_max_bytes(catalog, owner))} byte."
    if not owner.is_record:
        side = "server gửi" if owner.is_server else "client gửi"
        facts = f"Cổng {PORT_TEXT[owner.port]}, {side}, có từ bản {owner.since}. " + facts
    return [f"### {title}", "", cell(owner.summary), "", facts, "", *field_table(owner)]


def group_sections(catalog: Catalog) -> list[str]:
    lines: list[str] = []
    for group in catalog.groups:
        members = [message for message in catalog.messages if message.group == group.id]
        lines.extend([f"## Nhóm {group.id:02X}: {group.name}", "", cell(group.summary), "",
                      "| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |", "|---|---|---|---|---|---|"])
        for message in members:
            side = "server" if message.is_server else "client"
            lines.append(f"| `{message.kind_text()}` | {message.name} | {PORT_TEXT[message.port]} | {side} "
                         f"| {message.since} | {number(body_max_bytes(catalog, message))} |")
        lines.append("")
        for message in members:
            lines.extend(owner_section(catalog, message))
    return lines


def enum_sections(catalog: Catalog) -> list[str]:
    lines = ["## Enum", "", "Giá trị ngoài bảng là lỗi kBadEnum ở cả hai chiều.", ""]
    for item in catalog.enums:
        lines.extend([f"### {item.name} ({item.underlying})", "", "| Giá trị | Tên | Ghi chú |", "|---|---|---|"])
        lines.extend(f"| {value.value} | `k{value.name}` | {cell(value.note)} |" for value in item.values)
        lines.append("")
    return lines


def render_doc(catalog: Catalog) -> str:
    """Nội dung docs/PROTOCOL-TIN.md."""
    lines = [
        f"<!-- Tệp sinh bởi TOOLS/server/gen_protocol.py từ SRC/protocol/catalog/*.tsv; không sửa tay."
        f" Sửa bảng rồi chạy lại: {COMMAND} -->",
        "", "# Danh mục tin của giao thức", "",
        f"Bản danh mục {catalog.version}: {len(catalog.messages)} tin, {len(catalog.records)} record,"
        f" {len(catalog.enums)} enum.",
        f"Khung có 8 byte đầu (u32 số byte thân, u16 kind, u16 flags bằng 0), little-endian; thân tối đa"
        f" {number(MAX_BODY_BYTES)} byte, tin client gửi tối đa {number(CLIENT_BODY_BYTES)} byte.",
        "Byte cao của kind là nhóm, bit 15 bật là tin server gửi. Trần của text tính bằng byte UTF-8,"
        " trần của list tính bằng số phần tử.", "",
        *group_sections(catalog),
    ]
    if catalog.records:
        lines.extend(["## Record", ""])
        for record in catalog.records:
            lines.extend(owner_section(catalog, record))
    lines.extend(enum_sections(catalog))
    while lines[-1] == "":
        lines.pop()
    return "\n".join(lines) + "\n"
