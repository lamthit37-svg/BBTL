"""Nạp script Lua của máy chủ thành Unit (hằng toàn cục + hàm) cho bộ đánh giá từng phần.

Hằng cấp tệp (g_MissionId, bảng thưởng...) được tính ngay khi nạp bằng chính bộ đánh giá; giá trị nào không
tính được (gọi API ở mức tệp) thì bỏ qua và được ghi nhận là thiếu, không đoán. Số hiệu script lấy từ
Script.dat (id = số trước dấu =) chứ không từ tên hàm, vì nhiều tệp đặt tiền tố hàm khác id.
"""
from __future__ import annotations

import re
from pathlib import Path

import lua_flow as F
import lua_syntax as S
from lua_values import Unsupported

PREFIX = re.compile(r"^x0*(\d+)_")


def read_script_dat(text: str) -> dict:
    """Script.dat: các dòng 'id=đường dẫn' (từ dấu ; trở đi là chú thích). Trả {id: đường dẫn}."""
    found: dict = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith(";") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        path = value.partition(";")[0].strip()
        if key.strip().isdigit() and path:
            found[int(key.strip())] = path.replace("\\", "/").lstrip("/")
    return found


def load_unit(script_id: int, path: str, text: str, low: F.Lowerer) -> F.Unit:
    """Cây cú pháp -> Unit. Lỗi cú pháp là LuaSyntaxError cho bên gọi quyết định."""
    tree = S.parse(text)
    unit = F.Unit(script_id, path, {}, {})
    env = F.Env(unit)
    for node in tree:
        low.steps = 0
        _top_level(node, unit, env, low)
    return unit


def _top_level(node: object, unit: F.Unit, env: F.Env, low: F.Lowerer) -> None:
    if isinstance(node, S.FuncDef):
        unit.funcs[node.name] = node
        return
    if isinstance(node, (S.Assign, S.Local)):
        targets = node.targets if isinstance(node, S.Assign) else tuple(S.Name(n) for n in node.names)
        for position, target in enumerate(targets):
            _assign_global(target, node.values, position, unit, env, low)


def _assign_global(target: object, values: tuple, position: int, unit: F.Unit, env: F.Env, low: F.Lowerer) -> None:
    if position >= len(values):
        value = None
    else:
        try:
            value = low.eval(values[position], env)
        except Unsupported as exc:
            value = F.Poison()
            unit.globals.setdefault("__missing__", []).append(str(exc))
    if isinstance(target, S.Name):
        unit.globals[target.id] = value
    elif isinstance(target, S.Index):
        _assign_index(target, value, env, low)


def _assign_index(target: S.Index, value: object, env: F.Env, low: F.Lowerer) -> None:
    try:
        table = low.eval(target.obj, env)
        key = low.eval(target.key, env)
    except Unsupported:
        return
    if hasattr(table, "items") and isinstance(table.items, dict):
        from lua_values import key_of

        table.items[key_of(key)] = value


def script_prefix_id(name: str) -> int | None:
    match = PREFIX.match(name)
    return int(match.group(1)) if match else None


def read_text(path: Path) -> str:
    return S.decode(path.read_bytes())
