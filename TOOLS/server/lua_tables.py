"""Nhiệm vụ điều khiển bằng bảng của client 2026 (Mission_KillMonster, Delivery, LootItem, EnterArea, Husong).

Bản cũ của máy chủ chạy các bảng này bằng bộ script chung (event/EventScript/event_*.lua, id 6666..6672); ở
đây bộ chạy là C++ (module mission), Python chỉ đọc bảng thành hàng quest/mục tiêu/thưởng. Giá trị của client 2026
thắng: bảng client là bản cân bằng lại của bảng XJL7457 và có cột kim ngân "tiền khoá" chèn sau cột tiền.

Bố cục cột đo ngày 2026-10-14 bằng cách so tiêu đề `Public/Config/Mission_*.txt` của XJL7457 với dữ liệu client:
mọi cột trước cột tiền giống nhau; từ cột tiền là [tiền, tiền khoá, kinh nghiệm, ...] và các cột sau lệch +1 so
với XJL7457; giữa nhóm thưởng ẩn và chỉ số nhiệm vụ kế tiếp client chèn thêm cột mới (chưa dùng, luôn 0).
Test `test_lua_tables.py` đối chiếu từng số này với dữ liệu thật.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from lua_world import norm_name, rows_of, to_int

ITEM_GROUPS = (("fixed", 5), ("choice", 5), ("hidden", 3))


@dataclass(frozen=True)
class Layout:
    """Chỉ số cột (theo client 2026) của một bảng nhiệm vụ."""

    kind: str  # kill, loot, deliver, area, escort
    table: str
    name: int
    accept_scene: int
    accept_name: int
    accept_guid: int
    complete_scene: int
    complete_name: int
    complete_guid: int
    level: int
    prereq: int
    money: int
    objective_start: int
    next_index: int
    objective_count: int = -1  # cột số lượng mục tiêu (-1: cố định theo bảng)
    stride: int = 0
    fields: tuple = ()
    max_objectives: int = 0
    repeat: int = -1
    detail: int = -1
    continue_text: int = -1
    complete_text: int = -1
    target_scene: int = -1
    target_name: int = -1


LAYOUTS = (
    Layout("kill", "quests_kill", 9, 14, 15, 16, 17, 18, 19, 20, 21, 40, 25, 83, 24, 3,
           ("name", "mark", "count"), 5, 6, 11, 12, 13),
    Layout("loot", "quests_loot", 9, 14, 15, 16, 17, 18, 19, 20, 21, 50, 25, 93, 24, 5,
           ("name", "flag", "item", "rate", "count"), 5, 6, 11, 12, 13),
    Layout("deliver", "quests_delivery", 9, 15, 16, -1, 17, 18, -1, 23, 24, 27, 69, 84, 68, 3,
           ("item", "count", "gives"), 5, 6, 11, 13, 14, 19, 20),
    Layout("area", "quests_enter_area", 8, 16, 17, 18, 19, 20, 21, 22, 23, 33, 27, 62, 26, 2,
           ("scene", "area"), 3, -1, 10, 11, 12),
    Layout("escort", "quests_escort", 8, 13, 14, -1, 15, 16, -1, 20, 21, 25, 17, 54, -1, 3,
           ("scene", "name", "route"), 1, -1, 10, 11, 12),
)


@dataclass
class Objective:
    kind: str
    name: str = ""
    count: int = 0
    mark: int = 0
    item: int = 0
    rate: int = 0
    scene: int = 0
    area: int = 0
    gives: int = 0
    flag: int = 0


@dataclass
class Reward:
    group: str
    kind: str
    ref: int
    count: int


@dataclass
class TableQuest:
    quest: int
    index: int
    kind: str
    client_kind: int
    elite: int
    repeat: int
    level: int
    prereq: list
    name: str
    detail: str
    continue_text: str
    complete_text: str
    accept_scene: int
    accept_name: str
    accept_guid: int
    complete_scene: int
    complete_name: str
    complete_guid: int
    target_scene: int
    target_name: str
    next_index: int
    penalty: int = 0
    ban_slot: int = -1
    ban_seconds: int = 0
    objectives: list = field(default_factory=list)
    rewards: list = field(default_factory=list)
    issues: list = field(default_factory=list)


def cell(row: list, position: int, default: str = "") -> str:
    return row[position] if 0 <= position < len(row) else default


def number(row: list, position: int, default: int = 0) -> int:
    return to_int(cell(row, position), default)


def read_layout(path: object, layout: Layout) -> list:
    """Mọi dòng của bảng thành TableQuest (kèm issues cho dòng hỏng)."""
    _, rows = rows_of(path / "shared" / f"{layout.table}.tsv")
    return [quest_of_row(row, layout) for row in rows if len(row) > layout.next_index]


def quest_of_row(row: list, layout: Layout) -> TableQuest:
    quest = TableQuest(
        quest=number(row, 1, -1),
        index=number(row, 0, -1),
        kind=layout.kind,
        client_kind=number(row, 2),
        elite=number(row, 3),
        repeat=number(row, layout.repeat) if layout.repeat >= 0 else 0,
        level=number(row, layout.level),
        prereq=[v for v in (number(row, layout.prereq + i, -1) for i in range(3)) if v >= 0],
        name=cell(row, layout.name),
        detail=cell(row, layout.detail),
        continue_text=cell(row, layout.continue_text),
        complete_text=cell(row, layout.complete_text),
        accept_scene=number(row, layout.accept_scene, -1),
        accept_name=cell(row, layout.accept_name),
        accept_guid=number(row, layout.accept_guid, 0) if layout.accept_guid >= 0 else 0,
        complete_scene=number(row, layout.complete_scene, -1),
        complete_name=cell(row, layout.complete_name),
        complete_guid=number(row, layout.complete_guid, 0) if layout.complete_guid >= 0 else 0,
        target_scene=number(row, layout.target_scene, -1) if layout.target_scene >= 0 else -1,
        target_name=cell(row, layout.target_name),
        next_index=number(row, layout.next_index, -1),
    )
    quest.objectives = objectives_of(row, layout)
    quest.rewards = rewards_of(row, layout)
    if _RELATION_GAP[layout.kind]:
        quest.penalty = number(row, layout.money + 6)
        quest.ban_slot = number(row, layout.money + 8, -1)
        quest.ban_seconds = number(row, layout.money + 9)
    return quest


def objectives_of(row: list, layout: Layout) -> list:
    if layout.kind == "escort":
        return [Objective("escort", cell(row, 18), 1, scene=number(row, 17), area=number(row, 19))]
    count = number(row, layout.objective_count, 0) if layout.objective_count >= 0 else layout.max_objectives
    found = []
    if layout.kind == "deliver":
        found.append(Objective("talk", cell(row, layout.target_name), 1, scene=number(row, layout.target_scene)))
    for slot in range(min(max(count, 0), layout.max_objectives)):
        base = layout.objective_start + slot * layout.stride
        values = dict(zip(layout.fields, (cell(row, base + i) for i in range(layout.stride))))
        found.append(objective_of(layout.kind, values))
    return [item for item in found if item is not None]


def objective_of(kind: str, values: dict) -> Objective | None:
    def num(key: str) -> int:
        return to_int(values.get(key, "0"), 0)

    if kind == "kill":
        return Objective("kill", values["name"], num("count"), mark=num("mark"))
    if kind == "loot":
        return Objective("loot", values["name"], num("count"), item=num("item"), rate=num("rate"),
                         flag=num("flag"))
    if kind == "deliver":
        return Objective("deliver", "", num("count"), item=num("item"), gives=num("gives"))
    return Objective("area", "", 1, scene=num("scene"), area=num("area"))


def rewards_of(row: list, layout: Layout) -> list:
    money, bound, exp = (number(row, layout.money + i) for i in range(3))
    found = []
    for kind, amount in (("money", money), ("bound_money", bound), ("exp", exp)):
        if amount > 0:
            found.append(Reward("fixed", kind, 0, amount))
    if _RELATION_GAP[layout.kind] and number(row, layout.money + 4) != 0 and number(row, layout.money + 3) >= 0:
        found.append(Reward("fixed", "relation", number(row, layout.money + 3), number(row, layout.money + 4)))
    start = layout.money + 3 + _RELATION_GAP[layout.kind]
    for group, size in ITEM_GROUPS:
        for slot in range(size):
            item = number(row, start + slot * 2)
            amount = number(row, start + slot * 2 + 1)
            if item > 0 and amount > 0:
                found.append(Reward(group, "item", item, amount))
        start += size * 2
    return found


# Số cột nằm giữa kinh nghiệm và nhóm vật phẩm: vị trí lưu quan hệ, thưởng, nhắc, phạt, nhắc, vị trí cấm, thời
# gian cấm, nhắc (8 cột). Bảng EnterArea và Husong không có các cột này.
_RELATION_GAP = {"kill": 8, "loot": 8, "deliver": 8, "area": 0, "escort": 0}


def read_all(tables_dir: object) -> list:
    quests: list = []
    for layout in LAYOUTS:
        quests.extend(read_layout(tables_dir, layout))
    return quests


def monster_names(quests: list) -> set:
    return {norm_name(item.name) for quest in quests for item in quest.objectives if item.name}
