# Mô hình danh mục tin của protocol: kiểu trường, tin, record, enum và cỡ thân tối đa (DE-BAI §3).
"""Kiểu dữ liệu chung của gen_protocol.py; không đọc tệp, không in gì."""

from __future__ import annotations

from dataclasses import dataclass

# Kiểu số và thời lượng: số byte trên dây.
SCALAR_BYTES: dict[str, int] = {
    "u8": 1, "u16": 2, "u32": 4, "u64": 8,
    "i8": 1, "i16": 2, "i32": 4, "i64": 8,
    "bool": 1, "f32": 4,
    "seconds16": 2, "millis32": 4, "millis64": 8,
}
UNDERLYING_BYTES: dict[str, int] = {"u8": 1, "u16": 2}
UNDERLYING_MAX: dict[str, int] = {"u8": 0xFF, "u16": 0xFFFF}
# Tiền tố u16 của text và list giới hạn trần ở 65.535.
MAX_PREFIX_LIMIT = 0xFFFF
CLIENT_BODY_BYTES = 4 * 1024
MAX_BODY_BYTES = 64 * 1024
SERVER_BIT = 0x8000
PORTS = ("game", "auth", "both")


@dataclass(frozen=True)
class TypeRef:
    """Một kiểu trường. kind là scalar, enum, record, text, bytes, list hoặc optional."""

    kind: str
    name: str = ""
    inner: TypeRef | None = None

    def spell(self) -> str:
        """Viết lại kiểu đúng như trong fields.tsv."""
        if self.kind in ("list", "optional") and self.inner is not None:
            return f"{self.kind}:{self.inner.spell()}"
        if self.kind in ("enum", "record"):
            return f"{self.kind}:{self.name}"
        return self.name if self.kind == "scalar" else self.kind

    def element(self) -> TypeRef:
        """Kiểu bên trong của list hoặc optional."""
        if self.inner is None:
            raise ValueError(f"kiểu {self.spell()} không bọc kiểu nào")
        return self.inner

    def needs_limit(self) -> bool:
        """Kiểu cần cột limit: text, bytes, list, hoặc optional bọc text/bytes."""
        if self.kind == "optional":
            return self.element().needs_limit()
        return self.kind in ("text", "bytes", "list")


def parse_type(text: str) -> TypeRef | None:
    """Đọc một ô type; sai ngữ pháp trả None."""
    if text in SCALAR_BYTES:
        return TypeRef("scalar", text)
    if text in ("text", "bytes"):
        return TypeRef(text)
    head, sep, rest = text.partition(":")
    if not sep or not rest:
        return None
    if head in ("enum", "record"):
        return TypeRef(head, rest) if rest.isidentifier() else None
    if head in ("list", "optional"):
        inner = parse_type(rest)
        return None if inner is None else TypeRef(head, "", inner)
    return None


@dataclass(frozen=True)
class Field:
    """Một dòng của fields.tsv."""

    owner: str
    order: int
    name: str
    type: TypeRef
    limit: int | None
    note: str
    line: int


@dataclass(frozen=True)
class Message:
    """Một tin (kind là số) hoặc một record (kind là None)."""

    kind: int | None
    name: str
    port: str
    since: int
    summary: str
    fields: tuple[Field, ...]
    line: int

    @property
    def is_record(self) -> bool:
        return self.kind is None

    @property
    def is_server(self) -> bool:
        return self.kind is not None and bool(self.kind & SERVER_BIT)

    @property
    def group(self) -> int:
        return ((self.kind or 0) & ~SERVER_BIT) >> 8

    def kind_text(self) -> str:
        return "record" if self.kind is None else f"0x{self.kind:04X}"


@dataclass(frozen=True)
class EnumValue:
    value: int
    name: str
    note: str


@dataclass(frozen=True)
class Enum:
    name: str
    underlying: str
    values: tuple[EnumValue, ...]


@dataclass(frozen=True)
class Group:
    id: int
    name: str
    summary: str


@dataclass(frozen=True)
class Catalog:
    """Danh mục đã qua G1–G11: tin xếp theo kind, record xếp để kiểu dùng đứng sau kiểu được dùng."""

    version: int
    groups: tuple[Group, ...]
    messages: tuple[Message, ...]
    records: tuple[Message, ...]
    enums: tuple[Enum, ...]

    def record(self, name: str) -> Message:
        for item in self.records:
            if item.name == name:
                return item
        raise KeyError(name)

    def enum(self, name: str) -> Enum:
        for item in self.enums:
            if item.name == name:
                return item
        raise KeyError(name)

    def port_messages(self, port: str, server: bool) -> tuple[Message, ...]:
        """Tin của một cổng (game hoặc auth) và một chiều, theo kind."""
        return tuple(m for m in self.messages if m.is_server == server and m.port in (port, "both"))


def type_max_bytes(catalog: Catalog, ref: TypeRef, limit: int | None) -> int:
    """Số byte tối đa của một giá trị trên dây (G9)."""
    if ref.kind == "scalar":
        return SCALAR_BYTES[ref.name]
    if ref.kind == "enum":
        return UNDERLYING_BYTES[catalog.enum(ref.name).underlying]
    if ref.kind == "record":
        return body_max_bytes(catalog, catalog.record(ref.name))
    if ref.kind == "text":
        return 2 + (limit or 0)
    if ref.kind == "bytes":
        return limit or 0
    if ref.kind == "list":
        return 2 + (limit or 0) * type_max_bytes(catalog, ref.element(), None)
    return 1 + type_max_bytes(catalog, ref.element(), limit)


def body_max_bytes(catalog: Catalog, owner: Message) -> int:
    """Cỡ thân tối đa của một tin hoặc record."""
    return sum(type_max_bytes(catalog, f.type, f.limit) for f in owner.fields)


def camel_to_snake(name: str) -> str:
    """CharacterSummary thành character_summary."""
    out: list[str] = []
    for index, char in enumerate(name):
        if char.isupper() and index > 0:
            out.append("_")
        out.append(char.lower())
    return "".join(out)


def snake_to_camel(name: str) -> str:
    """client_time thành ClientTime."""
    return "".join(part[:1].upper() + part[1:] for part in name.split("_"))
