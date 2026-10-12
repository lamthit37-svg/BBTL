# Luật G2–G11 của danh mục tin (DE-BAI §3.4) và dựng Catalog từ bốn bảng đã qua G1.
"""Mỗi lỗi ghi `tệp:dòng: [Gx] câu`; chỉ trả Catalog khi không còn lỗi nào."""

from __future__ import annotations

import re
from dataclasses import dataclass

from protocol_model import (
    CLIENT_BODY_BYTES, MAX_BODY_BYTES, MAX_PREFIX_LIMIT, PORTS, SCALAR_BYTES, SERVER_BIT, UNDERLYING_BYTES,
    UNDERLYING_MAX,
    Catalog, Enum, EnumValue, Field, Group, Message, TypeRef, body_max_bytes, parse_type,
)
from protocol_cxx import DURATIONS, limit_name, snake
from protocol_tsv import Problems, Row, Table

CAMEL = re.compile(r"[A-Z][A-Za-z0-9]*")
SNAKE = re.compile(r"[a-z][a-z0-9]*(?:_[a-z0-9]+)*")
KIND = re.compile(r"0x[0-9A-F]{4}")
GROUP_ID = re.compile(r"[0-9A-F]{2}")
NUMBER = re.compile(r"0|[1-9][0-9]*")
CPP_KEYWORDS = frozenset(
    "alignas alignof and and_eq asm auto bitand bitor bool break case catch char char8_t char16_t char32_t"
    " class compl concept const consteval constexpr constinit const_cast continue co_await co_return"
    " co_yield decltype default delete do double dynamic_cast else enum explicit export extern false float"
    " for friend goto if inline int long mutable namespace new noexcept not not_eq nullptr operator or"
    " or_eq private protected public register reinterpret_cast requires return short signed sizeof static"
    " static_assert static_cast struct switch template this thread_local throw true try typedef typeid"
    " typename union unsigned using virtual void volatile wchar_t while xor xor_eq".split()
)
# Tên đã có trong wire.hpp, channel.hpp hoặc do mã sinh dùng: trùng thì mã sinh không dịch được.
RESERVED_TYPES = frozenset(
    "Writer Reader Frame FrameResult WireError WireStatus ByteView GameClientMessage GameServerMessage"
    " AuthClientMessage AuthServerMessage GameClientResult GameServerResult AuthClientResult AuthServerResult"
    " Channel ChannelError ChannelLimits ChannelStatus InFrame NextFrame Sample Check Buffer".split()
)


@dataclass
class Draft:
    """Tin hoặc record đã đọc ở messages.tsv, chưa gắn trường."""

    row: Row
    kind: int | None
    name: str
    port: str
    since: int


Names = tuple[dict[str, Draft], dict[str, Enum]]
Owners = dict[str, list[Field]]


def parse_number(text: str) -> int | None:
    """Số thập phân không dấu, không số 0 thừa ở đầu."""
    return int(text) if NUMBER.fullmatch(text) else None


def check_type_name(name: str, display: str, line: int, problems: Problems) -> None:
    """Tên tin, record, enum: CamelCase, không phải từ khoá, không trùng tên của wire.hpp (G3)."""
    if not CAMEL.fullmatch(name):
        problems.add(display, line, "G3", f"tên `{name}` phải viết CamelCase")
    if name.lower() in CPP_KEYWORDS or name in RESERVED_TYPES:
        problems.add(display, line, "G3", f"tên `{name}` trùng từ khoá C++ hoặc tên có sẵn của protocol")


def read_version(table: Table, problems: Problems) -> int:
    """Dòng `# version N` của messages.tsv (G4)."""
    version = parse_number(table.meta.get("version", ""))
    if version is None or version < 1:
        problems.add(table.display, 1, "G4", "`# version` phải là số nguyên từ 1")
        return 1
    return version


def read_groups(table: Table, problems: Problems) -> dict[int, Group]:
    """Nhóm: id hai chữ số hex hoa, không có bit 15, không trùng (G2)."""
    groups: dict[int, Group] = {}
    for row in table.rows:
        text = row.cells["id"]
        if not GROUP_ID.fullmatch(text) or int(text, 16) > 0x7F:
            problems.add(table.display, row.line, "G2", f"id nhóm `{text}` phải là hai chữ số hex hoa từ 00 đến 7F")
            continue
        if int(text, 16) in groups:
            problems.add(table.display, row.line, "G2", f"id nhóm `{text}` bị trùng")
            continue
        groups[int(text, 16)] = Group(int(text, 16), row.cells["name"], row.cells["summary"])
    return groups


def read_kind(row: Row, display: str, groups: dict[int, Group], problems: Problems) -> int | None:
    """Ô kind của một tin: `0x` cộng 4 chữ số hex hoa, nhóm phải có trong groups.tsv (G2)."""
    text = row.cells["kind"]
    if not KIND.fullmatch(text):
        problems.add(display, row.line, "G2", f"kind `{text}` phải là `record` hoặc `0x` cộng 4 chữ số hex hoa")
        return None
    kind = int(text, 16)
    if ((kind & ~SERVER_BIT) >> 8) not in groups:
        problems.add(display, row.line, "G2", f"kind `{text}` thuộc nhóm không có trong groups.tsv")
    return kind


def read_port(row: Row, display: str, version: int, problems: Problems) -> tuple[str, int]:
    """Cổng và since của một tin (G4)."""
    port = row.cells["port"]
    since = parse_number(row.cells["since"])
    if port not in PORTS:
        problems.add(display, row.line, "G4", f"port `{port}` phải là game, auth hoặc both")
    if since is None or not 1 <= since <= version:
        problems.add(display, row.line, "G4", f"since `{row.cells['since']}` phải từ 1 đến {version}")
        since = 1
    return port, since


def read_draft(row: Row, display: str, context: tuple[dict[int, Group], int], problems: Problems) -> Draft:
    """Một dòng messages.tsv thành Draft."""
    groups, version = context
    check_type_name(row.cells["name"], display, row.line, problems)
    if row.cells["kind"] == "record":
        if row.cells["port"] or row.cells["since"]:
            problems.add(display, row.line, "G4", "record phải để trống port và since")
        return Draft(row, None, row.cells["name"], "", 0)
    kind = read_kind(row, display, groups, problems)
    port, since = read_port(row, display, version, problems)
    return Draft(row, kind, row.cells["name"], port, since)


def read_drafts(table: Table, groups: dict[int, Group], version: int, problems: Problems) -> dict[str, Draft]:
    """Mọi tin và record; kind và tên không trùng (G2, G3)."""
    drafts: dict[str, Draft] = {}
    kinds: set[int] = set()
    for row in table.rows:
        draft = read_draft(row, table.display, (groups, version), problems)
        if draft.kind is not None and draft.kind in kinds:
            problems.add(table.display, row.line, "G2", f"kind `{row.cells['kind']}` bị trùng")
        if draft.name in drafts:
            problems.add(table.display, row.line, "G3", f"tên `{draft.name}` bị trùng")
            continue
        if draft.kind is not None:
            kinds.add(draft.kind)
        drafts[draft.name] = draft
    return drafts


def read_enum_row(row: Row, display: str, enums: dict[str, list[EnumValue]], problems: Problems) -> None:
    """Một giá trị enum: từ 1, vừa kiểu nền, không trùng giá trị hay tên (G8)."""
    name = row.cells["enum"]
    value = parse_number(row.cells["value"])
    limit = UNDERLYING_MAX.get(row.cells["underlying"])
    values = enums.setdefault(name, [])
    if limit is None:
        problems.add(display, row.line, "G8", f"underlying `{row.cells['underlying']}` phải là u8 hoặc u16")
    elif value is None or not 1 <= value <= limit:
        problems.add(display, row.line, "G8", f"giá trị `{row.cells['value']}` phải từ 1 đến {limit}")
    if not CAMEL.fullmatch(row.cells["name"]):
        problems.add(display, row.line, "G8", f"tên giá trị `{row.cells['name']}` phải viết CamelCase")
    if any(item.value == value for item in values) or any(item.name == row.cells["name"] for item in values):
        problems.add(display, row.line, "G8", f"giá trị hoặc tên `{row.cells['name']}` bị trùng trong `{name}`")
        return
    values.append(EnumValue(value or 0, row.cells["name"], row.cells["note"]))


def read_enums(table: Table, drafts: dict[str, Draft], problems: Problems) -> dict[str, Enum]:
    """Mọi enum; một enum chỉ có một kiểu nền, tên không trùng tin hay record (G3, G8)."""
    values: dict[str, list[EnumValue]] = {}
    underlying: dict[str, str] = {}
    for row in table.rows:
        name = row.cells["enum"]
        if name not in underlying:
            check_type_name(name, table.display, row.line, problems)
            if name in drafts:
                problems.add(table.display, row.line, "G3", f"tên enum `{name}` trùng tên tin hoặc record")
        elif underlying[name] != row.cells["underlying"]:
            problems.add(table.display, row.line, "G8", f"enum `{name}` có hai kiểu nền khác nhau")
        underlying.setdefault(name, row.cells["underlying"])
        read_enum_row(row, table.display, values, problems)
    return {
        name: Enum(name, underlying[name], tuple(sorted(items, key=lambda item: item.value)))
        for name, items in values.items()
    }


def check_reference(ref: TypeRef, names: Names) -> str | None:
    """Kiểu tham chiếu enum hoặc record có tồn tại, list và optional không bọc list (G6)."""
    drafts, enums = names
    if ref.kind in ("list", "optional"):
        if ref.element().kind == "list":
            return f"`{ref.spell()}`: list và optional không được bọc list"
        return check_reference(ref.element(), names)
    if ref.kind == "enum" and ref.name not in enums:
        return f"enum `{ref.name}` không có trong enums.tsv"
    if ref.kind == "record" and (ref.name not in drafts or drafts[ref.name].kind is not None):
        return f"record `{ref.name}` không có trong messages.tsv"
    return None


def check_limit(ref: TypeRef, limit_text: str) -> tuple[int | None, str | None]:
    """Trần của trường: text, bytes, list cần trần từ 1 đến 65.535, kiểu khác để trống (G7)."""
    if ref.kind == "list" and ref.element().needs_limit():
        return None, f"`{ref.spell()}` cần hai trần; bọc phần tử trong một record"
    if not ref.needs_limit():
        return None, None if limit_text == "" else f"kiểu `{ref.spell()}` không có limit"
    limit = parse_number(limit_text)
    if limit is None or not 1 <= limit <= MAX_PREFIX_LIMIT:
        return None, f"kiểu `{ref.spell()}` cần limit từ 1 đến {MAX_PREFIX_LIMIT}"
    return limit, None


def read_field(row: Row, display: str, names: Names, problems: Problems) -> Field | None:
    """Một dòng fields.tsv: tên snake_case, kiểu đúng ngữ pháp, trần đúng kiểu (G3, G6, G7)."""
    name = row.cells["name"]
    if not SNAKE.fullmatch(name) or name in CPP_KEYWORDS:
        problems.add(display, row.line, "G3", f"tên trường `{name}` phải viết snake_case, không là từ khoá")
    ref = parse_type(row.cells["type"])
    if ref is None:
        problems.add(display, row.line, "G6", f"kiểu `{row.cells['type']}` sai ngữ pháp")
        return None
    error = check_reference(ref, names)
    if error is not None:
        problems.add(display, row.line, "G6", error)
        return None
    limit, error = check_limit(ref, row.cells["limit"])
    if error is not None:
        problems.add(display, row.line, "G7", error)
    order = parse_number(row.cells["order"]) or 0
    return Field(row.cells["owner"], order, name, ref, limit, row.cells["note"], row.line)


def check_orders(owner: str, fields: list[Field], display: str, problems: Problems) -> None:
    """order liền từ 1, không trùng tên trường trong một chủ (G5)."""
    ordered = sorted(fields, key=lambda item: (item.order, item.line))
    seen: set[str] = set()
    for expected, item in enumerate(ordered, 1):
        if item.order != expected:
            text = f"`{owner}`: order phải liền từ 1, gặp {item.order} ở chỗ {expected}"
            problems.add(display, item.line, "G5", text)
            break
    for item in ordered:
        if item.name in seen:
            problems.add(display, item.line, "G5", f"`{owner}`: tên trường `{item.name}` bị trùng")
        seen.add(item.name)


def read_fields(table: Table, names: Names, problems: Problems) -> Owners:
    """Trường theo chủ; chủ có trường mà không có dòng khai là lỗi (G11)."""
    owners: dict[str, list[Field]] = {}
    for row in table.rows:
        if row.cells["owner"] not in names[0]:
            text = f"chủ `{row.cells['owner']}` không có dòng khai trong messages.tsv"
            problems.add(table.display, row.line, "G11", text)
            continue
        item = read_field(row, table.display, names, problems)
        if item is not None:
            owners.setdefault(item.owner, []).append(item)
    for owner, items in owners.items():
        check_orders(owner, items, table.display, problems)
    return owners


def record_refs(ref: TypeRef) -> list[str]:
    """Tên record mà một kiểu dùng, kể cả bên trong list và optional."""
    if ref.kind in ("list", "optional"):
        return record_refs(ref.element())
    return [ref.name] if ref.kind == "record" else []


def order_records(drafts: dict[str, Draft], owners: Owners, display: str, problems: Problems) -> list[str]:
    """Record xếp theo tên nhưng kiểu được dùng đứng trước; vòng lặp là lỗi G6."""
    done: list[str] = []
    visiting: list[str] = []

    def visit(name: str) -> None:
        if name in done:
            return
        if name in visiting:
            line = drafts[name].row.line
            problems.add(display, line, "G6", f"record `{name}` tự chứa mình qua {' > '.join(visiting)}")
            return
        visiting.append(name)
        for item in sorted(owners.get(name, []), key=lambda field: field.order):
            for used in record_refs(item.type):
                visit(used)
        visiting.pop()
        done.append(name)

    for name in sorted(n for n, d in drafts.items() if d.kind is None):
        visit(name)
    return done


def least_bytes(ref: TypeRef, limit: int | None, names: tuple[Owners, dict[str, Enum]], seen: frozenset[str]) -> int:
    """Số byte ít nhất của một giá trị trên dây; record đi đệ quy, vòng lặp đã là lỗi G6 riêng."""
    owners, enums = names
    if ref.kind == "scalar":
        return SCALAR_BYTES[ref.name]
    if ref.kind == "enum":
        # Nền sai (vd `U8`) đã là lỗi ở enums.tsv; ở đây chỉ cần một số an toàn để không văng KeyError.
        return UNDERLYING_BYTES.get(enums[ref.name].underlying, 1) if ref.name in enums else 1
    if ref.kind == "bytes":
        return limit or 1
    if ref.kind in ("text", "list"):
        return 2
    if ref.kind == "optional":
        return 1
    if ref.name in seen:
        return 1
    inner = seen | {ref.name}
    return sum(least_bytes(item.type, item.limit, names, inner) for item in owners.get(ref.name, []))


def check_list_elements(owners: Owners, enums: dict[str, Enum], display: str, problems: Problems) -> None:
    """Phần tử của list chiếm ít nhất 1 byte (G6): Reader::count chặn số khai lớn hơn số byte còn lại."""
    for items in owners.values():
        for item in items:
            if item.type.kind == "list" and least_bytes(item.type.element(), None, (owners, enums), frozenset()) == 0:
                text = f"`{item.type.spell()}`: phần tử chiếm 0 byte trên dây; list cần phần tử ít nhất 1 byte"
                problems.add(display, item.line, "G6", text)


def assemble(drafts: dict[str, Draft], owners: Owners, record_order: list[str]) -> tuple[list[Message], list[Message]]:
    """Gắn trường vào tin và record theo order."""
    def build(draft: Draft) -> Message:
        fields = tuple(sorted(owners.get(draft.name, []), key=lambda item: item.order))
        summary = draft.row.cells["summary"]
        return Message(draft.kind, draft.name, draft.port, draft.since, summary, fields, draft.row.line)

    messages = sorted((build(d) for d in drafts.values() if d.kind is not None), key=lambda m: m.kind or 0)
    records = [build(drafts[name]) for name in record_order]
    return messages, records


def check_sizes(catalog: Catalog, display: str, problems: Problems) -> None:
    """Thân tối đa: tin client tới 4.096 byte, tin server tới 65.536 byte (G9)."""
    for message in catalog.messages:
        limit = MAX_BODY_BYTES if message.is_server else CLIENT_BODY_BYTES
        size = body_max_bytes(catalog, message)
        if size > limit:
            problems.add(display, message.line, "G9", f"`{message.name}` có thân tối đa {size} byte, vượt {limit}")


def used_names(catalog: Catalog) -> set[str]:
    """Tên enum và record dùng được từ một tin nào đó, đi qua record lồng nhau."""
    used: set[str] = set()
    pending = [f.type for m in catalog.messages for f in m.fields]
    while pending:
        ref = pending.pop()
        if ref.kind in ("list", "optional"):
            pending.append(ref.element())
            continue
        if ref.kind not in ("enum", "record") or ref.name in used:
            continue
        used.add(ref.name)
        if ref.kind == "record":
            pending.extend(f.type for f in catalog.record(ref.name).fields)
    return used


def check_usage(catalog: Catalog, tables: dict[str, Table], problems: Problems) -> None:
    """Record và enum nào cũng phải có tin dùng tới (G10)."""
    used = used_names(catalog)
    for record in catalog.records:
        if record.name not in used:
            text = f"record `{record.name}` không có tin nào dùng"
            problems.add(tables["messages.tsv"].display, record.line, "G10", text)
    first_line = {row.cells["enum"]: row.line for row in reversed(tables["enums.tsv"].rows)}
    for item in catalog.enums:
        if item.name not in used:
            text = f"enum `{item.name}` không có tin nào dùng"
            problems.add(tables["enums.tsv"].display, first_line[item.name], "G10", text)


def check_generated_names(catalog: Catalog, tables: dict[str, Table], problems: Problems) -> None:
    """Tên C++ mà mã sinh sẽ khai (hằng trần, put_/get_ của record, tin, enum) không được trùng nhau (G3)."""
    seen: dict[str, str] = {f"put_{name}": f"hàm phụ thời lượng `{name}`" for name in DURATIONS}
    enum_line = {row.cells["enum"]: row.line for row in reversed(tables["enums.tsv"].rows)}
    spots: list[tuple[str, str, str, int]] = [
        (f"put_{snake(item.name)}", f"enum `{item.name}`", "enums.tsv", enum_line[item.name]) for item in catalog.enums
    ]
    for owner in (*catalog.records, *catalog.messages):
        if owner.fields or owner.kind is None:
            spots.append((f"put_{snake(owner.name)}", f"`{owner.name}`", "messages.tsv", owner.line))
        spots.extend(
            (limit_name(owner, item), f"`{owner.name}.{item.name}`", "fields.tsv", item.line)
            for item in owner.fields if item.limit is not None
        )
    for name, who, table, line in spots:
        if name in seen:
            text = f"{who} sinh ra tên C++ `{name}`, trùng với {seen[name]}"
            problems.add(tables[table].display, line, "G3", text)
            continue
        seen[name] = who


def build_catalog(tables: dict[str, Table], problems: Problems) -> Catalog | None:
    """Dựng Catalog từ bốn bảng; có lỗi G1–G11 nào thì trả None."""
    messages_table = tables["messages.tsv"]
    version = read_version(messages_table, problems)
    groups = read_groups(tables["groups.tsv"], problems)
    drafts = read_drafts(messages_table, groups, version, problems)
    enums = read_enums(tables["enums.tsv"], drafts, problems)
    owners = read_fields(tables["fields.tsv"], (drafts, enums), problems)
    record_order = order_records(drafts, owners, messages_table.display, problems)
    check_list_elements(owners, enums, tables["fields.tsv"].display, problems)
    if problems:
        return None
    messages, records = assemble(drafts, owners, record_order)
    catalog = Catalog(
        version, tuple(sorted(groups.values(), key=lambda g: g.id)), tuple(messages), tuple(records),
        tuple(sorted(enums.values(), key=lambda e: e.name)),
    )
    check_sizes(catalog, messages_table.display, problems)
    check_usage(catalog, tables, problems)
    check_generated_names(catalog, tables, problems)
    return None if problems else catalog
