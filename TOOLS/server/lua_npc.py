"""Lối vào hội thoại (script, num) của mọi script có OnDefaultEvent, và vai của script NPC.

Một lối vào là kết quả hạ OnDefaultEvent của một script với GetNumText() = num. Lựa chọn (AddNumText) của một
luồng trỏ tới lối vào khác: bộ làm việc đi từ hạt giống tới khi hết lối vào mới. Máy chủ giữ phiên và chỉ nhận
ý định "chọn lựa chọn k" của client (ADR-005), nên mọi lối vào đều là dữ liệu, không có tên hàm Lua nào đi ra ngoài.
"""
from __future__ import annotations

from collections.abc import Iterator
from dataclasses import dataclass, field

import lua_dialog as D
import lua_flow as F
import lua_quest as Q
from lua_values import Unsupported

MAX_ENTRIES = 40000
MAX_NUMS_PER_SCRIPT = 96


@dataclass
class Entry:
    script: int
    num: int
    block: int = 0
    status: str = "ok"
    reason: str = ""


@dataclass
class NpcRole:
    script: int
    path: str
    events: list = field(default_factory=list)
    entries: int = 0


def all_steps(flow: F.Flow) -> Iterator:
    """Mọi bước của luồng, kể cả khối con và nhánh lồng."""
    pending = [flow.root, *flow.blocks.values()]
    for steps in pending:
        yield from F._walk(steps)


def options_of(flow: F.Flow) -> list:
    return [step.data for step in all_steps(flow) if step.kind == "option"]


def event_list_of(unit: F.Unit) -> list:
    """Danh sách g_eventList của script NPC (các script sự kiện NPC liệt kê); rỗng nếu không có."""
    for name, value in unit.globals.items():
        if name.lower().endswith("_g_eventlist") and hasattr(value, "items"):
            return [item for _, item in sorted(value.items.items()) if isinstance(item, int)]
    return []


ROOT_NUM = -1  # GetNumText() của lần bấm vào NPC (OnDefaultEvent); mọi số khác là một mục của danh sách


class Walker:
    def __init__(self, low: F.Lowerer, serializer: D.Serializer, npc_scripts: frozenset = frozenset()) -> None:
        self.low = low
        self.serializer = serializer
        self.npc_scripts = npc_scripts
        self.entries: dict = {}
        self.queue: list = []
        self.per_script: dict = {}
        self.root_collisions: list = []  # mục của chính NPC có số -1: trùng khoá với lần bấm vào NPC

    def seed(self, script: int, num: int) -> None:
        key = (script, num)
        if key in self.entries or len(self.entries) >= MAX_ENTRIES:
            return
        count = self.per_script.get(script, 0)
        if count >= MAX_NUMS_PER_SCRIPT:
            self.entries[key] = Entry(script, num, status="unsupported", reason="quá nhiều giá trị lựa chọn")
            return
        self.per_script[script] = count + 1
        self.entries[key] = Entry(script, num)
        self.queue.append(key)

    def run(self) -> None:
        while self.queue:
            script, num = self.queue.pop()
            self.lower_entry(self.entries[(script, num)])

    def lower_entry(self, entry: Entry) -> None:
        unit = self.low.units.get(entry.script)
        # Máy chủ gốc gọi OnEventRequest của chính NPC khi người chơi chọn một mục của danh sách (eventId là
        # script của mục,
        # GetNumText() là chỉ số mục); mục của chính NPC (cửa hàng, dạy nghề, nhận nhiệm vụ vòng...) chỉ nằm ở hàm đó.
        # Mục của script sự kiện thì NPC chuyển tiếp sang OnDefaultEvent của script ấy, nên khoá (script sự kiện, số)
        # lấy thẳng OnDefaultEvent của nó. Lần bấm vào NPC (số -1) luôn là OnDefaultEvent.
        request = unit is not None and entry.script in self.npc_scripts and entry.num != ROOT_NUM
        func = Q.func_of(unit, "OnEventRequest") if request else None
        if func is None:
            request = False
            func = Q.func_of(unit, "OnDefaultEvent") if unit is not None else None
        if func is None:
            entry.status, entry.reason = "no_dialog", "thiếu OnDefaultEvent"
            return
        try:
            args = self.low.entry_args(func, entry.num)
            if request and len(args) >= 4:
                args[3] = entry.script
            flow = self.low.lower(unit, func.name, args)
            entry.block = self.serializer.flow_root(flow, f"{entry.script}:{entry.num}")
        except Unsupported as exc:
            entry.status, entry.reason = "unsupported", str(exc)[:120]
            return
        for script, _icon, value in options_of(flow):
            if script == entry.script and value == ROOT_NUM and script in self.npc_scripts:
                self.root_collisions.append(script)
            if script in self.low.units:
                self.seed(script, value)


def npc_roles(low: F.Lowerer, categories: dict, paths: dict) -> list:
    """Vai của từng script NPC: danh sách sự kiện nó liệt kê."""
    roles = []
    for script, category in sorted(categories.items()):
        if category != "npc":
            continue
        unit = low.units[script]
        roles.append(NpcRole(script, paths[script], event_list_of(unit)))
    return roles
