"""Dữ liệu tham chiếu của client 2026 và của cảnh máy chủ mà lua_extract.py đối chiếu.

Mọi thứ ở đây chỉ đọc: bảng TSV đã xuất ở dev/server/tables (shared, client) và dev/server/scenes. Tên NPC
và quái trong script Lua là chữ Hán (đôi khi thừa dấu cách hoặc khác cách viết); bảng giải mã chuẩn hoá tên
(cắt mọi khoảng trắng) rồi đối chiếu id của client; tên ứng với nhiều id thì ghi vào danh sách mơ hồ,
không chọn thay con người.
"""
from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

import tsv_file

_SPACES = re.compile(r"[\s　]+")


def norm_name(name: str) -> str:
    """Tên chuẩn hoá: NFC, bỏ khoảng trắng, bỏ thẻ màu #R #W #G... và dấu ngoặc đầu cuối."""
    text = unicodedata.normalize("NFC", name)
    text = re.sub(r"#[A-Za-z]", "", text)
    return _SPACES.sub("", text)


def rows_of(path: Path) -> tuple[list, list]:
    """Cột và các dòng của bảng TSV (bỏ dòng # và dòng rỗng). Thiếu tệp thì ([], [])."""
    if not path.is_file():
        return [], []
    rows = tsv_file.split_rows(path.read_text(encoding="utf-8"))
    if not rows:
        return [], []
    return rows[0], rows[1:]


def to_int(cell: str, default: int = -1) -> int:
    try:
        return int(cell)
    except ValueError:
        return default


@dataclass(frozen=True)
class Spawn:
    guid: int
    scene: int
    template: int
    name: str
    script: int


@dataclass
class World:
    tables: Path
    scenes: Path
    spawns: dict = field(default_factory=dict)
    by_name: dict = field(default_factory=dict)
    by_script: dict = field(default_factory=dict)
    scene_dirs: dict = field(default_factory=dict)
    monsters: dict = field(default_factory=dict)
    monster_by_name: dict = field(default_factory=dict)
    items: set = field(default_factory=set)
    dictionary: set = field(default_factory=set)
    dict_text: dict = field(default_factory=dict)
    client_quests: dict = field(default_factory=dict)

    def load(self) -> "World":
        self.load_monsters()
        self.load_scene_index()
        self.load_spawns()
        self.load_items()
        self.load_dictionary()
        self.load_client_quests()
        return self

    def load_monsters(self) -> None:
        _, rows = rows_of(self.tables / "shared" / "monsters.tsv")
        for row in rows:
            template = to_int(row[0])
            self.monsters[template] = row[1]
            self.monster_by_name.setdefault(norm_name(row[1]), []).append(template)

    def load_scene_index(self) -> None:
        _, rows = rows_of(self.tables / "server" / "scenes.tsv")
        for row in rows:
            scene_id = to_int(row[0])
            self.scene_dirs[scene_id] = row[3].removesuffix(".scn")

    def load_spawns(self) -> None:
        for scene_id, folder in sorted(self.scene_dirs.items()):
            _, rows = rows_of(self.scenes / folder / "spawns.tsv")
            for row in rows:
                self.add_spawn(scene_id, row)

    def add_spawn(self, scene_id: int, row: list) -> None:
        guid = to_int(row[0])
        template = to_int(row[1])
        name = row[2] or self.monsters.get(template, "")
        script = to_int(row[7])
        spawn = Spawn(guid, scene_id, template, name, script)
        self.spawns[guid] = spawn
        self.by_name.setdefault(norm_name(name), []).append(spawn)
        if script >= 0:
            self.by_script.setdefault(script, []).append(spawn)

    def load_items(self) -> None:
        for table in ("items_common", "equipment", "gems"):
            _, rows = rows_of(self.tables / "shared" / f"{table}.tsv")
            self.items.update(to_int(row[0]) for row in rows if row)

    def load_dictionary(self) -> None:
        _, rows = rows_of(self.tables / "client" / "StrDictionary.tsv")
        for row in rows:
            if len(row) >= 2:
                self.dictionary.add(row[0])
                self.dict_text[row[0]] = row[1]

    def load_client_quests(self) -> None:
        _, rows = rows_of(self.tables / "shared" / "mission_dictionary.tsv")
        for row in rows:
            if len(row) >= 18:
                self.client_quests[to_int(row[1])] = row


def client_quest_summary(row: list) -> dict:
    """Cột đã biết của MissionDictionary (suy từ dữ liệu: tên, loại, cảnh, cấp, tiền đề, NPC nhận và trả)."""
    return {
        "name": row[2],
        "kind": to_int(row[3]),
        "scene": to_int(row[5]),
        "level_min": to_int(row[6]),
        "level_max": to_int(row[7]),
        "prereq": [to_int(row[8]), to_int(row[9]), to_int(row[10]), to_int(row[11]), to_int(row[12])],
        "giver_name": row[13],
        "giver_guid": to_int(row[14]),
        "turn_in_name": row[15],
        "turn_in_guid": to_int(row[16]),
    }
