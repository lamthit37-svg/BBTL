"""Bộ đăng ký kết quả của lua_extract.py: điều kiện, hiệu ứng, chuỗi và khối hội thoại thành dòng bảng.

Mỗi điều kiện DNF và mỗi danh sách hiệu ứng được đánh số một lần (trùng nội dung thì dùng lại id). Chuỗi
chữ hằng (không phải `#{KHOÁ}` của StrDictionary client) được ghi vào bảng lua_strings với khoá
`lua.<băm>` ổn định theo nội dung, để máy chủ gửi id chuỗi chứ không gửi văn bản (ADR-003 của TLBB Dev).
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

import lua_bool as B
import lua_values as V
from lua_flow import Step

DICT_REF = re.compile(r"^\s*#\{([A-Za-z0-9_]+)\}\s*$")
MAX_TEXT = 4000
MAX_SET_EFFECTS = 256  # trùng ops::kMaxSetEffects của module C++ ops


def fnv1a32(text: str) -> int:
    value = 0x811C9DC5
    for byte in text.encode("utf-8"):
        value = ((value ^ byte) * 0x01000193) & 0xFFFFFFFF
    return value


@dataclass
class Strings:
    """Khoá chuỗi: `#{KEY}` dùng khoá của client; chữ hằng thành khoá lua.<băm 8 hex>."""

    dictionary: set
    literal: dict = field(default_factory=dict)
    missing: set = field(default_factory=set)
    owners: dict = field(default_factory=dict)

    def key_of(self, text: object, owner: str = "") -> tuple[str, str]:
        """Trả (khoá, danh sách tham số cách nhau dấu phẩy)."""
        if isinstance(text, V.Tpl):
            body, args = _render(text)
        elif isinstance(text, str):
            body, args = text, ""
        else:
            raise V.Unsupported(f"chuỗi kiểu {type(text).__name__}")
        match = DICT_REF.match(body)
        if match and not args:
            key = match.group(1)
            if key not in self.dictionary:
                self.missing.add(key)
            return key, ""
        body = body[:MAX_TEXT]
        key = f"lua.{fnv1a32(body):08x}"
        if self.literal.setdefault(key, body) != body:
            raise V.Unsupported(f"va chạm băm chuỗi {key}")
        if owner:
            self.owners.setdefault(key, owner)
        return key, args


def _render(tpl: V.Tpl) -> tuple[str, str]:
    pieces: list[str] = []
    args: list[str] = []
    for part in tpl.parts:
        if isinstance(part, str):
            pieces.append(part.replace("{", "{{").replace("}", "}}"))
        else:
            pieces.append("{" + str(len(args)) + "}")
            args.append(part.kind)
    return "".join(pieces), ",".join(args)


@dataclass
class CondRegistry:
    ids: dict = field(default_factory=dict)
    rows: list = field(default_factory=list)

    def add(self, cond: frozenset) -> int:
        """Id bộ điều kiện; luôn đúng là -1. Luôn sai là bộ có op never."""
        if B.is_true(cond):
            return -1
        key = canonical(cond)
        if key in self.ids:
            return self.ids[key]
        set_id = len(self.ids) + 1
        self.ids[key] = set_id
        if not cond:
            self.rows.append((set_id, 0, 0, "never", 0, 0, 0, 0, ""))
            return set_id
        for clause_no, clause in enumerate(key):
            for seq, item in enumerate(clause):
                self.rows.append(_cond_row(set_id, clause_no, seq, item))
        return set_id


def canonical(cond: frozenset) -> tuple:
    clauses = [tuple(sorted(clause, key=_atom_key)) for clause in cond]
    clauses.sort(key=lambda clause: [_atom_key(item) for item in clause])
    return tuple(clauses)


def _atom_key(item: B.Atom) -> tuple:
    return (item.op, item.neg, tuple(str(arg) for arg in item.args))


def _cond_row(set_id: int, clause_no: int, seq: int, item: B.Atom) -> tuple:
    numbers = [arg for arg in item.args if isinstance(arg, int)]
    words = [arg for arg in item.args if isinstance(arg, str)]
    padded = (numbers + [0, 0, 0])[:3]
    return (set_id, clause_no, seq, item.op, 1 if item.neg else 0, padded[0], padded[1], padded[2],
            words[0] if words else "")


@dataclass
class EffectRegistry:
    ids: dict = field(default_factory=dict)
    rows: list = field(default_factory=list)

    def add(self, effects: list) -> int:
        """effects: danh sách (op, a1, a2, a3, khoá chuỗi, tham số chuỗi, id điều kiện). Trả id; rỗng là -1."""
        if not effects:
            return -1
        if len(effects) > MAX_SET_EFFECTS:
            raise V.Unsupported("bộ hiệu ứng quá dài")
        key = tuple(effects)
        if key in self.ids:
            return self.ids[key]
        set_id = len(self.ids) + 1
        self.ids[key] = set_id
        for seq, (op, a1, a2, a3, text, args, cond) in enumerate(effects):
            self.rows.append((set_id, seq, op, a1, a2, a3, text, args, cond))
        return set_id


def effect_tuple(step: Step, strings: Strings, owner: str = "", cond: int = -1) -> tuple:
    """Bước 'effect' thành bộ (op, a1, a2, a3, khoá chuỗi, tham số chuỗi, id điều kiện; -1 là luôn chạy)."""
    op = step.data[0]
    numbers = [item for item in step.data[1:] if isinstance(item, int)]
    padded = (numbers + [0, 0, 0])[:3]
    key = args = ""
    if step.text is not None:
        key, args = strings.key_of(step.text, owner)
    return (op, padded[0], padded[1], padded[2], key, args, cond)


@dataclass
class BlockTable:
    """Khối hội thoại: mỗi danh sách bước là một khối có id toàn cục."""

    rows: list = field(default_factory=list)
    entries: list = field(default_factory=list)
    next_id: int = 1

    def alloc(self) -> int:
        block_id = self.next_id
        self.next_id += 1
        return block_id
