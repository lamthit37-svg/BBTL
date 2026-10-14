"""Dòng bước (Flow) của bộ đánh giá từng phần thành dòng bảng dialog_steps.

Mỗi danh sách bước (gốc, nhánh then/else, khối gọi hàm, khối nối) là một khối có id toàn cục. Các bước hiệu
ứng liền nhau gộp thành một bộ hiệu ứng nguyên tử (effects.tsv): đúng ý ledger "một bước hội thoại là một
giao dịch". Bước thuần hiển thị (note) bị bỏ.
"""
from __future__ import annotations

import lua_emit as E
from lua_flow import Flow, Step
from lua_values import Unsupported

KINDS_WITH_TEXT = ("text", "option")


class Serializer:
    def __init__(self, blocks: E.BlockTable, conds: E.CondRegistry, effects: E.EffectRegistry,
                 strings: E.Strings) -> None:
        self.blocks = blocks
        self.conds = conds
        self.effects = effects
        self.strings = strings
        self.map: dict = {}
        self.flow: Flow | None = None
        self.owner = ""

    def flow_root(self, flow: Flow, owner: str) -> int:
        self.flow = flow
        self.owner = owner
        self.map = {}
        return self.list_block(flow.root)

    def block_of_local(self, local_id: int) -> int:
        assert self.flow is not None
        if local_id in self.map:
            return self.map[local_id]
        target = self.blocks.alloc()
        self.map[local_id] = target
        self.fill(target, self.flow.blocks[local_id])
        return target

    def list_block(self, steps: list) -> int:
        block_id = self.blocks.alloc()
        self.fill(block_id, steps)
        return block_id

    def fill(self, block_id: int, steps: list) -> None:
        seq = 0
        run: list = []
        for step in steps:
            if step.kind == "effect":
                run.append(E.effect_tuple(step, self.strings, self.owner))
                continue
            seq = self.flush(block_id, seq, run)
            run = []
            seq = self.emit(block_id, seq, step)
        self.flush(block_id, seq, run)

    def flush(self, block_id: int, seq: int, run: list) -> int:
        if not run:
            return seq
        set_id = self.effects.add(run)
        self.blocks.rows.append((block_id, seq, "effects", -1, set_id, 0, 0, "", ""))
        return seq + 1

    def emit(self, block_id: int, seq: int, step: Step) -> int:
        row = self.row_of(block_id, seq, step)
        if row is None:
            return seq
        self.blocks.rows.append(row)
        return seq + 1

    def row_of(self, block_id: int, seq: int, step: Step) -> tuple | None:
        kind = step.kind
        if kind == "note":
            return None
        if kind in KINDS_WITH_TEXT:
            key, args = self.strings.key_of(step.text, self.owner)
            numbers = (*step.data, 0, 0, 0)[:3] if kind == "option" else (0, 0, 0)
            return (block_id, seq, kind, -1, numbers[0], numbers[1], numbers[2], key, args)
        if kind == "branch":
            then_id = self.list_block(step.then or [])
            other_id = self.list_block(step.other) if step.other else 0
            return (block_id, seq, "branch", self.conds.add(step.cond), then_id, other_id, 0, "", "")
        if kind in ("goto", "call"):
            return (block_id, seq, kind, -1, self.block_of_local(step.data[0]), 0, 0, "", "")
        if kind == "dispatch":
            return (block_id, seq, "dispatch", -1, 0, 0, 0, step.data[0], "")
        if kind == "bonus":
            numbers = (*step.data[1:], 0, 0, 0)[:3]
            return (block_id, seq, "bonus", -1, numbers[0], numbers[1], numbers[2], step.data[0], "")
        if kind == "pick":
            return (block_id, seq, "pick", -1, step.data[0], 0, 0, "", "")
        if kind in ("begin", "ret"):
            return (block_id, seq, kind, -1, 0, 0, 0, "", "")
        raise Unsupported(f"bước {kind} không xuất được")
