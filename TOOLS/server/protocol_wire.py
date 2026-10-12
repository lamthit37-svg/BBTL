# Bộ mã hoá Python độc lập với mã C++ sinh ra, và ba mẫu cho mỗi tin (DE-BAI §3.5): byte mong đợi của
# tests/protocol_samples.hpp tính ở đây nên test C++ so được hai bản cài đặt với nhau.
"""Giá trị Python: số nguyên, bool, float, str, bytes, list, None (optional rỗng), dict (record)."""

from __future__ import annotations

import struct

from protocol_model import Catalog, Field, Message, TypeRef

Value = object
SIGNED = {"i8": 8, "i16": 16, "i32": 32, "i64": 64}
UNSIGNED = {"u8": 8, "u16": 16, "u32": 32, "u64": 64, "seconds16": 16, "millis32": 32}
# milliseconds của C++ có rep là int64, nên millis64 lớn nhất là 2^63 - 1 chứ không phải 2^64 - 1.
DURATION_MAX = {"seconds16": 0xFFFF, "millis32": 0xFFFFFFFF, "millis64": 0x7FFFFFFFFFFFFFFF}
FLOAT_MAX = struct.unpack("<f", bytes.fromhex("ffff7f7f"))[0]
# Chữ 1, 2, 3 và 4 byte UTF-8 xen nhau cho mẫu lớn nhất.
WIDE_TEXT = ("A", "é", "ệ", "\U00020000")
TYPICAL_TEXT = "Thiên Long Bát Bộ"
VARIANTS = ("min", "max", "typical")


def put_unsigned(out: bytearray, value: int, width: int) -> None:
    """Ghi width byte của value, byte thấp trước."""
    out.extend(value.to_bytes(width, "little", signed=False))


def encode_scalar(name: str, value: Value, out: bytearray) -> None:
    """Số, bool, f32 và thời lượng."""
    if name == "bool":
        out.append(1 if value else 0)
    elif name == "f32":
        out.extend(struct.pack("<f", value))
    elif name in SIGNED:
        out.extend(int(str(value)).to_bytes(SIGNED[name] // 8, "little", signed=True))
    else:
        width = 8 if name == "millis64" else UNSIGNED[name] // 8
        put_unsigned(out, int(str(value)), width)


def encode_value(catalog: Catalog, ref: TypeRef, value: Value, out: bytearray) -> None:
    """Một giá trị theo kiểu của nó."""
    if ref.kind == "scalar":
        encode_scalar(ref.name, value, out)
    elif ref.kind == "enum":
        width = 1 if catalog.enum(ref.name).underlying == "u8" else 2
        put_unsigned(out, int(str(value)), width)
    elif ref.kind == "text":
        data = str(value).encode("utf-8")
        put_unsigned(out, len(data), 2)
        out.extend(data)
    elif ref.kind == "bytes":
        out.extend(bytes(value))
    elif ref.kind == "list":
        items = list(value)
        put_unsigned(out, len(items), 2)
        for item in items:
            encode_value(catalog, ref.element(), item, out)
    elif ref.kind == "optional":
        out.append(0 if value is None else 1)
        if value is not None:
            encode_value(catalog, ref.element(), value, out)
    else:
        encode_fields(catalog, catalog.record(ref.name), value, out)


def encode_fields(catalog: Catalog, owner: Message, value: Value, out: bytearray) -> None:
    """Các trường của tin hoặc record theo order."""
    values = dict(value)
    for item in owner.fields:
        encode_value(catalog, item.type, values[item.name], out)


def encode_frame(catalog: Catalog, message: Message, value: Value) -> bytes:
    """Cả khung: u32 số byte thân, u16 kind, u16 flags bằng 0, rồi thân."""
    body = bytearray()
    encode_fields(catalog, message, value, body)
    frame = bytearray()
    put_unsigned(frame, len(body), 4)
    put_unsigned(frame, message.kind or 0, 2)
    put_unsigned(frame, 0, 2)
    return bytes(frame + body)


def fill_text(limit: int) -> str:
    """Chữ đúng limit byte UTF-8, xen chữ 1 đến 4 byte; phần lẻ cuối bù bằng chữ 1 byte."""
    parts: list[str] = []
    used = 0
    index = 0
    while used + len(WIDE_TEXT[index % 4].encode("utf-8")) <= limit:
        parts.append(WIDE_TEXT[index % 4])
        used += len(WIDE_TEXT[index % 4].encode("utf-8"))
        index += 1
    return "".join(parts) + "a" * (limit - used)


def cut_text(text: str, limit: int) -> str:
    """Phần đầu của text vừa limit byte, không cắt giữa một chữ."""
    out = ""
    for char in text:
        if len((out + char).encode("utf-8")) > limit:
            break
        out += char
    return out


def scalar_sample(name: str, variant: str, order: int) -> Value:
    """Mẫu của số, bool, f32, thời lượng."""
    if name == "bool":
        return {"min": False, "max": True}.get(variant, order % 2 == 1)
    if name == "f32":
        return {"min": -FLOAT_MAX, "max": FLOAT_MAX}.get(variant, order + 0.25)
    if name in SIGNED:
        bits = SIGNED[name]
        return {"min": -(1 << (bits - 1)), "max": (1 << (bits - 1)) - 1}.get(variant, -((order * 13) % 100 + 1))
    if name in DURATION_MAX:
        return {"min": 0, "max": DURATION_MAX[name]}.get(variant, order * 30)
    bits = UNSIGNED[name]
    return {"min": 0, "max": (1 << bits) - 1}.get(variant, (order * 1009) % (1 << bits) or 1)


def value_sample(catalog: Catalog, ref: TypeRef, limit: int | None, variant: str, order: int) -> Value:
    """Mẫu của một giá trị: nhỏ nhất, lớn nhất theo mọi trần, hoặc giá trị thường gặp."""
    if ref.kind == "scalar":
        return scalar_sample(ref.name, variant, order)
    if ref.kind == "enum":
        values = [item.value for item in catalog.enum(ref.name).values]
        return {"min": values[0], "max": values[-1]}.get(variant, values[min(1, len(values) - 1)])
    if ref.kind == "text":
        size = limit or 0
        return {"min": "", "max": fill_text(size)}.get(variant, cut_text(TYPICAL_TEXT, size))
    if ref.kind == "bytes":
        size = limit or 0
        typical = bytes((i * 7 + order) & 0xFF for i in range(size))
        return {"min": bytes(size), "max": b"\xff" * size}.get(variant, typical)
    if ref.kind == "list":
        count = {"min": 0, "max": limit or 0}.get(variant, min(2, limit or 0))
        return [value_sample(catalog, ref.element(), None, variant, order) for _ in range(count)]
    if ref.kind == "optional":
        return None if variant == "min" else value_sample(catalog, ref.element(), limit, variant, order)
    return owner_sample(catalog, catalog.record(ref.name), variant)


def owner_sample(catalog: Catalog, owner: Message, variant: str) -> dict[str, Value]:
    """Mẫu của mọi trường của một tin hoặc record."""
    return {item.name: field_sample(catalog, item, variant) for item in owner.fields}


def field_sample(catalog: Catalog, item: Field, variant: str) -> Value:
    return value_sample(catalog, item.type, item.limit, variant, item.order)
