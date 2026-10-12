"""Xuất Public/Scene của bản 0859602 thành scene.toml, bảng TSV và walk.nav.

    python TOOLS/server/export_scene.py <thư mục tlbb> <thư mục đích> [--check]

--check kiểm hết và không ghi tệp nào. Có lỗi thì cũng không ghi. Đọc ini theo Ini.cpp, bảng chữ theo
OpenFromMemoryImpl_Text, lưới đi theo PathFinder::ReadNavMap. Khoá mã 2008 không
đọc vẫn thành cột và được ghi trong tệp cột. .path, .stall, .ObjRegion chỉ phân loại.
"""
from __future__ import annotations

import os
import struct
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

import config_style
import scene_classify as kinds
import scene_read
import tsv_file

FieldRow = tuple[str, str, str, str, bool]
ShortField = tuple[str, str, str]
ColumnSpec = tuple[tuple[str, ...], tuple[str, ...], list[tuple[str, ...]]]
IniSection = scene_read.IniSection
IniSections = dict[int, scene_read.IniSection]
ValueSeries = dict[int, list[list[str]]]
IniKey = scene_read.IniKey
GroupMap = dict[str, dict[int, IniSection]]
Claimed = tuple[dict[str, IniSection], GroupMap]
_ATTACH_FATES = frozenset({"scene_set", "client_only"})
_ATTACH_HEADER = ("file", "fate", "scene", "evidence")

TOOL = "export_scene.py"
TOOL_LINE = "# tool: TOOLS/server/export_scene.py; sửa tay sẽ mất ở lượt xuất sau"
HELP = """\
Xuất dữ liệu cảnh từ Public/Scene của bản 0859602.

python TOOLS/server/export_scene.py <thư mục tlbb> <thư mục đích> [--check]

--check kiểm hết và không ghi tệp nào. Thoát 0 khi sạch, 1 khi có lỗi.
Có lỗi thì không ghi tệp nào, kể cả cảnh đã gắn được.
"""

SPAWN_FIELDS = (
    ("guid", "guid", "int", "mã 2008 đọc bằng atoi", True),
    ("type", "type", "int", "mã loại quái, đọc bằng atoi", True),
    ("name", "name", "text", "tên, mã cắt còn 31 byte khi nạp", False),
    ("title", "title", "text", "danh hiệu, mã cắt còn 31 byte khi nạp", False),
    ("pos_x", "position_x", "float", "hoành độ, giữ nguyên văn", True),
    ("pos_z", "position_z", "float", "tung độ, giữ nguyên văn", True),
    ("dir", "direction", "int", "hướng nguyên văn; mã nhân pi/18 rồi cộng pi/2", True),
    ("script_id", "script_id", "int", "mã 2008 đọc bằng atoi", True),
    ("respawn_time", "respawn_time", "int", "thời gian sinh lại, mili giây", True),
    ("group_id", "group_id", "int", "nhóm quái", True),
    ("team_id", "team_id", "int", "tổ quái", True),
    ("base_ai", "base_ai", "int", "khi vắng thì lấy từ bảng quái", False),
    ("ai_file", "ai_file", "int", "kịch bản AI, khi vắng thì lấy từ bảng quái", False),
    ("patrol_id", "patrol_id", "int", "tuyến tuần", True),
    ("shop0", "shop_0", "int", "cửa hàng 0, khi vắng thì -1", False),
    ("shop1", "shop_1", "int", "cửa hàng 1, khi vắng thì -1", False),
    ("shop2", "shop_2", "int", "cửa hàng 2, khi vắng thì -1", False),
    ("shop3", "shop_3", "int", "cửa hàng 3, khi vắng thì -1", False),
    ("level", "level", "int", "cấp trong tệp quái, khi vắng thì 0; monster_level không áp vào", False),
    ("ispet", "is_pet", "int", "khi vắng thì 0", False),
    ("scripttimer", "script_timer", "int", "khi vắng thì 0", False),
    ("ReputationID", "reputation_id", "int", "mã 2008 không đọc", False),
    ("cshop", "cshop", "text", "mã 2008 không đọc ?", False),
    ("leaderid", "leader_id", "int", "mã 2008 đọc nếu có, mặc định -1", False),
    ("npc", "is_npc", "int", "mã 2008 đọc nếu có, mặc định 0", False),
    ("camp", "camp", "int", "mã 2008 đọc nếu có, khi vắng thì gán phe người chơi", False),
)
AREA_FIELDS = (
    ("guid", "guid", "int", "mã vùng, đọc bằng atoi", True),
    ("script_id", "script_id", "int", "script của vùng", True),
    ("left", "left", "float", "cạnh trái, giữ nguyên văn", True),
    ("top", "top", "float", "cạnh trên, giữ nguyên văn", True),
    ("right", "right", "float", "cạnh phải, giữ nguyên văn", True),
    ("bottom", "bottom", "float", "cạnh dưới, giữ nguyên văn", True),
)
PLATFORM_FIELDS = (
    ("index", "type_id", "int", "số hiệu loại bàn, khoá gốc index", True),
    ("class", "class_id", "int", "hạng bàn chế tác", True),
    ("pos_X", "position_x", "float", "hoành độ, giữ nguyên văn", True),
    ("pos_Z", "position_z", "float", "tung độ, giữ nguyên văn", True),
    ("dir", "direction", "int", "hướng nguyên văn; mã đổi sang radian", True),
    ("script_id", "script_id", "int", "khi vắng thì mã gán -1", False),
    ("Tip", "tip", "text", "mã 2008 không đọc", False),
)
PET_FIELDS = (
    ("guid", "guid", "int", "cùng khoá với quái; mã 2008 không nạp tệp pet", True),
    ("type", "type", "int", "mã 2008 không nạp tệp pet", True),
    ("name", "name", "text", "mã 2008 không nạp tệp pet", True),
    ("pos_x", "position_x", "float", "mã 2008 không nạp tệp pet", True),
    ("pos_z", "position_z", "float", "mã 2008 không nạp tệp pet", True),
    ("respawn_time", "respawn_time", "int", "mã 2008 không nạp tệp pet", True),
    ("ai_file", "ai_file", "int", "mã 2008 không nạp tệp pet", True),
)
PORTAL_FIELDS = (
    ("type", "type", "int", "mã 2008 không đọc", True),
    ("sceneid", "scene_id", "int", "mã 2008 không đọc", True),
    ("pos_X", "position_x", "float", "mã 2008 không đọc", True),
    ("pos_Z", "position_z", "float", "mã 2008 không đọc", True),
    ("targetsceneid", "target_scene_id", "int", "mã 2008 không đọc", True),
    ("targetpos_X", "target_position_x", "float", "mã 2008 không đọc", True),
    ("targetpos_Z", "target_position_z", "float", "mã 2008 không đọc", True),
    ("targetdir", "target_direction", "int", "mã 2008 không đọc", True),
)
BUS_FIELDS = (
    ("guid", "guid", "int", "mã 2008 không đọc", True),
    ("dataId", "data_id", "int", "loại xe, mã 2008 không đọc", True),
    ("patrolPathID", "patrol_id", "int", "tuyến tuần, mã 2008 không đọc", True),
    ("athwart", "reverse", "int", "chiều chạy, mã 2008 không đọc", True),
)
OPERATE_FIELDS = (
    ("selecttype", "select_type", "int", "kiểu chọn quái", True),
    ("selectvalue", "select_value", "text", "giá trị chọn, giữ nguyên văn", True),
    ("data_def", "data_def", "int", "chỉ số vùng dữ liệu", True),
    ("maxleft", "max_left", "int", "số quái giữ lại", True),
)
GROW_FIELDS = (
    ("point_id", "int", "cột 0, mã lập chỉ mục, không lưu vào điểm"),
    ("grow_point_type", "int", "cột 1, mã lưu loại điểm"),
    ("position_x", "float", "cột 2, hoành độ, giữ nguyên văn"),
    ("position_y", "float", "cột 3, tung độ trong tệp; mã gán vào trục Z"),
)
RULE_ORIGINAL = ("类型", "数量", "每次生成数量", "生成函数", "种子补充的间隔时间", "补充时间随机增量")
RULE_FIELDS = (
    ("grow_point_type", "int", "cột 0, mã đọc là loại"),
    ("max_count", "int", "cột 1, mã đọc là số lượng tối đa"),
    ("column_2", "int", "mã 2008 không đọc ?"),
    ("column_3", "text", "mã đọc bằng atoi vào khoảng bổ sung; tên gốc là hàm sinh ?"),
    ("column_4", "int", "mã 2008 không đọc ?"),
    ("column_5", "int", "mã 2008 không đọc ?"),
)
PATROL_BASE = (
    ("patrol_index", "int", "", "chỉ số tuyến, section PATROL"),
    ("point_index", "int", "", "chỉ số điểm trong tuyến"),
    ("position_x", "float", "POSX", "hoành độ, mã đọc"),
    ("position_y", "float", "POSY", "tung độ, mã 2008 không đọc"),
    ("position_z", "float", "POSZ", "trục còn lại, mã đọc"),
    ("settle_time", "int", "settletime", "thời gian đứng, mã đọc nếu có"),
    ("point_script_id", "text", "scriptidN", "mã 2008 đọc scriptid kèm chỉ số điểm"),
    ("route_script_id", "text", "scriptid", "khoá scriptid trần, mã 2008 không đọc"),
    ("turns_back", "int", "isturnback", "mã 2008 không đọc"),
    ("teleport_to_respawn", "int", "isTeleportToRespawnPos", "mã 2008 không đọc"),
    ("speech_unread", "text", "", "giá trị paopao lặp, mã 2008 chỉ đọc giá trị đầu"),
)
SCN_KEYS = {
    "navmapname": kinds.NAV,
    "monsterfile": "monster",
    "eventfile": kinds.AREA,
    "patrolpoint": kinds.PATROL,
    "platformfile": kinds.PLATFORM,
    "growpointdata": kinds.GROWPOINT,
    "growpointsetup": kinds.GROWPOINT_SETUP,
    "stallinfodata": kinds.STALL,
    "petfile": kinds.PET,
    "portalfile": kinds.PORTAL,
    "busfile": kinds.BUS,
}
MONSTER_KINDS = {
    kinds.MONSTER,
    kinds.MONSTER_BY_LEVEL,
    kinds.MONSTER_GROUP,
    kinds.MONSTER_BARE,
    kinds.MONSTER_ENTRANCE,
}
OPTIONAL_MISSING = {"petfile", "portalfile", "busfile"}
REQUIRED_SCN = ("navmapname", "monsterfile", "eventfile", "patrolpoint")
KIND_RANK = {
    kinds.MONSTER: 0,
    kinds.MONSTER_BY_LEVEL: 1,
    kinds.MONSTER_GROUP: 2,
    kinds.MONSTER_ENTRANCE: 3,
    kinds.MONSTER_BARE: 4,
}
COMMENTS = {
    "schema": "phiên bản dữ liệu của cảnh",
    "scene_file": "không có tệp scn, máy chủ không nạp cảnh này",
    "grid_width": "số ô ngang của lưới đi",
    "grid_height": "số ô dọc của lưới đi",
    "walk": "lưới đi, chép nguyên byte",
    "spawns": "quái và NPC của cảnh",
    "areas": "vùng sự kiện hình chữ nhật",
    "patrols": "tuyến tuần và các điểm",
    "grow_points": "điểm thu thập trên mặt đất",
    "grow_point_rules": "nhịp bổ sung điểm thu thập",
    "wild_pets": "trân thú hoang, mã 2008 không nạp tệp này",
    "platforms": "bàn chế tác trong cảnh",
    "portals": "cổng dịch chuyển, mã 2008 không đọc",
    "buses": "xe chạy theo tuyến, mã 2008 không đọc",
    "spawn_operates": "luật chọn và sinh quái trong tệp",
    "spawn_operate_values": "giá trị thay của luật sinh quái",
    "spawn_levels": "cấp trong tệp monster_level, mã không đọc",
    "path_file": "chưa đọc định dạng, không chép",
    "stall_file": "chưa đọc định dạng, không chép",
    "object_region_file": "chưa đọc định dạng, không chép",
    "pet_file": "không có tệp trên đĩa, mã 2008 không đọc",
    "portal_file": "không có tệp trên đĩa, mã 2008 không đọc",
    "bus_file": "không có tệp trên đĩa, mã 2008 không đọc",
}


@dataclass
class Report:
    ok: bool = False
    errors: list[str] = field(default_factory=list)
    kinds: dict[str, int] = field(default_factory=dict)
    scene_count: int = 0
    orphan_scene_count: int = 0
    records: dict[str, int] = field(default_factory=dict)
    changes: dict[str, int] = field(default_factory=dict)
    int_places: list[str] = field(default_factory=list)
    show_summary: bool = False
    scenes: list[Scene] = field(default_factory=list)


@dataclass
class Item:
    path: Path
    kind: str
    set_stem: str = ""


Items = dict[str, Item]
Users = dict[str, set[str]]
AttachMap = dict[str, tuple[str, str]]


@dataclass
class Table:
    relative: str
    source: str
    types: tuple[str, ...]
    columns: tuple[str, ...]
    rows: list[tuple[str, ...]]
    cell_lines: list[tuple[int, ...]] = field(default_factory=list)


@dataclass
class Scene:
    name: str
    has_scn: bool
    items: list[Item] = field(default_factory=list)
    missing: dict[str, str] = field(default_factory=dict)
    tables: list[Table] = field(default_factory=list)
    nav: Path | None = None
    grid: tuple[int, int] | None = None
    sidecars: dict[str, str] = field(default_factory=dict)
    patrol_points: list[dict[str, str]] | None = None
    patrol_source: str = ""


class Exporter:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.unattached: list[str] = []
        self.changes: Counter[str] = Counter()
        self.speech: set[int] = set()
        self.int_places: list[str] = []

    def note_int(self, path: Path, line: int, column: str, text: str) -> None:
        """Ô int không phải dạng thập phân thuần thì đếm và nhớ vị trí."""
        if text == "" or _canonical_int(text):
            return
        self.changes["int_not_canonical"] += 1
        self.int_places.append(f"{_show(path)}:{line}:{column}")

    def fail(self, message: str) -> None:
        if len(self.errors) < 100:
            self.errors.append(message)
        elif len(self.errors) == 100:
            self.errors.append("export_scene.py:1: dừng sau 100 lỗi")

    def stopped(self) -> bool:
        return len(self.errors) > 100


def _source(path: Path) -> str:
    return "Public/Scene/" + path.name


def _show(path: Path) -> str:
    return _source(path)


def case_conflict(names: set[str]) -> str | None:
    """Hai thân cảnh chỉ khác chữ hoa thì không được cùng tồn tại."""
    folded: dict[str, str] = {}
    for name in sorted(names):
        key = name.casefold()
        if key in folded:
            return f"{name}:1: hai cảnh chỉ khác chữ hoa chữ thường: {folded[key]}, {name}"
        folded[key] = name
    return None


def _toml_key(filename: str) -> str:
    if filename == "walk.nav":
        return "walk"
    stem = filename.rsplit(".", 1)[0]
    return stem.replace(".", "_")


def _comment(key: str) -> str:
    if key in COMMENTS:
        return COMMENTS[key]
    if key.startswith("spawns_level_") and key.endswith("_alt"):
        return "quái từ tên tệp thiếu dấu gạch dưới"
    if key.startswith("spawns_n"):
        return "quái theo nhóm và mốc cấp"
    if key.startswith("spawns_level_"):
        return "quái theo mốc cấp người chơi"
    if key.startswith("spawns_"):
        return "quái theo lối vào"
    if key.startswith("spawns_set_"):
        return "quái do script nạp thêm"
    if key.startswith("areas_set_"):
        return "vùng do script nạp thêm"
    if key.startswith("spawn_operates"):
        return "luật chọn quái"
    if key.startswith("spawn_operate_values"):
        return "giá trị luật quái"
    if key.startswith("path_file") or key.startswith("stall_file") or key.startswith("object_region_file"):
        return "chưa đọc định dạng, không chép"
    return "tệp xuất của cảnh"


def _quote(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _note_text(kind: str, text: str, changes: Counter[str]) -> None:
    if kind == "text" and len(text.encode("utf-8")) > 31:
        changes["name_over_31_bytes"] += 1


def _canonical_int(text: str) -> bool:
    if text in {"0", "-0"}:
        return text == "0"
    if text.startswith("-"):
        return text[1:].isdigit() and not text.startswith("-0")
    return text.isdigit() and not (len(text) > 1 and text.startswith("0"))


def _column_rows(fields: tuple[tuple[str, str, str, str], ...]) -> ColumnSpec:
    columns = ("index", "original", "name", "type", "note")
    types = ("text", "text", "text", "text", "text")
    rows = []
    for index, field in enumerate(fields):
        original, name, kind, note = field
        rows.append((str(index), original, name, kind, note))
    return columns, types, rows


def _named(section: scene_read.IniSection | None) -> dict[str, str]:
    """Giá trị đầu của mỗi khoá, đúng FindData của mã 2008."""
    if section is None:
        return {}
    values: dict[str, str] = {}
    for key in section.keys:
        if key.name not in values:
            values[key.name] = key.value
    return values


def _claim(
    book: Exporter,
    path: Path,
    parsed: scene_read.IniFile,
    named: set[str],
    prefixes: tuple[str, ...],
) -> Claimed | None:
    info: dict[str, scene_read.IniSection] = {}
    groups = {prefix: {} for prefix in prefixes}
    ordered = tuple(sorted(prefixes, key=len, reverse=True))
    for section in parsed.sections:
        if section.name in named:
            if section.name in info:
                book.fail(f"{_show(path)}:{section.line}: section {section.name} lặp")
                return None
            info[section.name] = section
            continue
        owner = ""
        for prefix in ordered:
            tail = section.name[len(prefix) :]
            if section.name.startswith(prefix) and tail.isdigit():
                owner = prefix
                break
        if not owner:
            book.fail(f"{_show(path)}:{section.line}: section lạ {section.name}")
            return None
        index = int(section.name[len(owner) :])
        if index in groups[owner]:
            book.fail(f"{_show(path)}:{section.line}: section {section.name} lặp")
            return None
        groups[owner][index] = section
    book.changes["same_key_repeats"] += parsed.same_key_repeats
    book.changes["distinct_duplicate_key"] += parsed.distinct_repeats
    book.changes["trailing_lf"] += parsed.trailing_lf
    return info, groups


def _atoi_count(text: str) -> int | None:
    stripped = text.strip()
    if stripped.isdigit():
        return int(stripped)
    return None


def _key_line(section: scene_read.IniSection, key: str) -> int:
    for item in section.keys:
        if item.name == key:
            return item.line
    return section.line


def _count(book: Exporter, path: Path, section: scene_read.IniSection | None, key: str) -> int | None:
    if section is None:
        book.fail(f"{_show(path)}:1: thiếu section chứa {key}")
        return None
    values = _named(section)
    if key not in values:
        book.fail(f"{_show(path)}:{section.line}: thiếu khoá {key}")
        return None
    text = values[key]
    count = _atoi_count(text)
    if count is None:
        book.fail(f"{_show(path)}:{section.line}: {key} không phải số đếm")
        return None
    if text != str(count):
        book.changes["padded_count"] += 1
        book.note_int(path, _key_line(section, key), key, text)
    return count


def _only_keys(book: Exporter, path: Path, section: scene_read.IniSection, allowed: set[str]) -> dict[str, str] | None:
    values = _named(section)
    for name in values:
        if name not in allowed:
            book.fail(f"{_show(path)}:{section.line}: khoá lạ: {name}")
            return None
    return values


def _rows_from_fields(
    book: Exporter,
    path: Path,
    sections: IniSections,
    count: int,
    fields: tuple[FieldRow, ...],
    label: str,
) -> tuple[list[tuple[str, ...]], list[tuple[int, ...]]] | None:
    if set(sections) != set(range(count)):
        book.fail(f"{_show(path)}:1: {label}={count} nhưng có {len(sections)} mục")
        return None
    allowed = {field[0] for field in fields}
    required = {field[0] for field in fields if field[4]}
    rows: list[tuple[str, ...]] = []
    row_lines: list[tuple[int, ...]] = []
    for index in range(count):
        section = sections[index]
        values = _only_keys(book, path, section, allowed)
        if values is None:
            return None
        missing = required.difference(values)
        if missing:
            book.fail(f"{_show(path)}:{section.line}: thiếu khoá {sorted(missing)[0]}")
            return None
        key_lines: dict[str, int] = {}
        for key in section.keys:
            if key.name not in key_lines:
                key_lines[key.name] = key.line
        cells: list[str] = []
        cell_lines: list[int] = []
        for source, name, kind, _note, _required in fields:
            text = values.get(source, "")
            line = key_lines.get(source, section.line)
            if kind == "text" and source in {"name", "title"}:
                _note_text("text", text, book.changes)
            elif kind == "int":
                book.note_int(path, line, name, text)
            if source == "dir" and text != "":
                book.changes["direction_kept_as_integer"] += 1
            cells.append(text)
            cell_lines.append(line)
        if cells and cells[0].startswith("#"):
            book.fail(f"{_show(path)}:{section.line}: ô đầu bắt đầu bằng #")
            return None
        rows.append(tuple(cells))
        row_lines.append(tuple(cell_lines))
    return rows, row_lines


def _record_bucket(relative: str) -> str:
    if relative == "spawns.tsv":
        return "spawns"
    if ".alt.tsv" in relative:
        return "spawns_alt"
    if ".n" in relative and "_level_" in relative:
        return "spawns_group"
    if relative.startswith("spawns.set_"):
        return "spawns_set"
    if relative.startswith("spawns.level_"):
        return "spawns_level"
    if relative.startswith("spawns."):
        return "spawns_entrance"
    if relative.startswith("areas.set_"):
        return "areas_set"
    if relative.startswith("spawn_operate_values"):
        return "spawn_operate_values"
    if relative.startswith("spawn_operates"):
        return "spawn_operates"
    return relative.replace(".tsv", "").replace(".", "_")


def _read_nav(book: Exporter, path: Path) -> tuple[int, int] | None:
    data = path.read_bytes()
    if len(data) < 4:
        book.fail(f"{_show(path)}:1: tệp nav cụt")
        return None
    width, height = struct.unpack_from("<HH", data, 0)
    expect = 4 + width * height * 4
    if expect != len(data):
        book.fail(f"{_show(path)}:1: cỡ tệp không khớp đầu tệp")
        return None
    return width, height


def _monster_tables(book: Exporter, path: Path, relative: str) -> tuple[Table | None, Table | None, Table | None]:
    parsed = scene_read.parse_ini(path)
    claimed = _claim(book, path, parsed, {"info", "setting"}, ("monster", "operate", "data_def"))
    if claimed is None:
        return None, None, None
    info, groups = claimed
    count = _count(book, path, info.get("info"), "monstercount")
    if count is None:
        return None, None, None
    info_values = _only_keys(book, path, info["info"], {"monstercount"})
    if info_values is None:
        return None, None, None
    built = _rows_from_fields(book, path, groups["monster"], count, SPAWN_FIELDS, "monstercount")
    if built is None:
        return None, None, None
    rows, cell_lines = built
    seen: set[str] = set()
    for row in rows:
        if row[0] in seen:
            book.changes["duplicate_guid"] += 1
        seen.add(row[0])
    types = tuple(field[2] for field in SPAWN_FIELDS)
    columns = tuple(field[1] for field in SPAWN_FIELDS)
    spawns = Table(relative, _source(path), types, columns, rows, cell_lines)
    operates, values = _operate_tables(book, path, relative, info.get("setting"), groups)
    return spawns, operates, values


def _operate_names(spawn_file: str) -> tuple[str, str]:
    if spawn_file == "spawns.tsv":
        return "spawn_operates.tsv", "spawn_operate_values.tsv"
    suffix = spawn_file[len("spawns.") :]
    return f"spawn_operates.{suffix}", f"spawn_operate_values.{suffix}"


def _operate_tables(
    book: Exporter,
    path: Path,
    spawn_file: str,
    setting: IniSection | None,
    groups: GroupMap,
) -> tuple[Table | None, Table | None]:
    if setting is None:
        if groups["operate"] or groups["data_def"]:
            book.fail(f"{_show(path)}:1: có operate nhưng thiếu setting")
            return None, None
        return None, None
    values = _only_keys(book, path, setting, {"operatecount", "datacount"})
    if values is None:
        return None, None
    operate_count = _count(book, path, setting, "operatecount")
    data_count = _count(book, path, setting, "datacount")
    if operate_count is None or data_count is None:
        return None, None
    operate_count = _relaxed_count(book, path, operate_count, groups["operate"], "operatecount")
    data_count = _relaxed_count(book, path, data_count, groups["data_def"], "datacount")
    if operate_count is None or data_count is None:
        return None, None
    operate_fields = _rows_from_fields(book, path, groups["operate"], operate_count, OPERATE_FIELDS, "operatecount")
    if operate_fields is None:
        return None, None
    value_built = _value_rows(book, path, groups["data_def"], data_count)
    if value_built is None:
        return None, None
    operate_rows, operate_lines = operate_fields
    value_rows, value_lines = value_built
    prefixed = [(spawn_file, *row) for row in operate_rows]
    value_prefixed = [(spawn_file, *row) for row in value_rows]
    operate_name, value_name = _operate_names(spawn_file)
    operate_types = ("text",) + tuple(field[2] for field in OPERATE_FIELDS)
    operate_columns = ("spawn_file",) + tuple(field[1] for field in OPERATE_FIELDS)
    value_types = ("text", "int", "int", "int", "text", "text")
    value_columns = ("spawn_file", "data_index", "data_type", "value_index", "value", "value_extra")
    operate_marked = _prefix_lines(operate_lines)
    value_marked = _prefix_lines(value_lines)
    source = _source(path)
    operates = Table(operate_name, source, operate_types, operate_columns, prefixed, operate_marked)
    extras = Table(value_name, source, value_types, value_columns, value_prefixed, value_marked)
    return operates, extras


def _relaxed_count(book: Exporter, path: Path, declared: int, sections: IniSections, label: str) -> int | None:
    """count=0 mà vẫn có section: mã không đọc, ta vẫn xuất."""
    if set(sections) == set(range(declared)):
        return declared
    if declared == 0 and sections and set(sections) == set(range(max(sections) + 1)):
        book.changes["zero_count_but_sections"] += len(sections)
        return max(sections) + 1
    book.fail(f"{_show(path)}:1: {label}={declared} nhưng có {len(sections)} mục")
    return None


def _prefix_lines(row_lines: list[tuple[int, ...]]) -> list[tuple[int, ...]]:
    """Cột spawn_file thêm vào đầu không có khoá riêng: lấy dòng ô đầu của dòng."""
    prefixed: list[tuple[int, ...]] = []
    for lines in row_lines:
        anchor = lines[0] if lines else 1
        prefixed.append((anchor, *lines))
    return prefixed


def _value_rows(
    book: Exporter, path: Path, sections: IniSections, count: int
) -> tuple[list[tuple[str, ...]], list[tuple[int, ...]]] | None:
    if set(sections) != set(range(count)):
        book.fail(f"{_show(path)}:1: datacount={count} nhưng có {len(sections)} mục data_def")
        return None
    rows: list[tuple[str, ...]] = []
    row_lines: list[tuple[int, ...]] = []
    for index in range(count):
        section = sections[index]
        built = _value_section(book, path, index, section)
        if built is None:
            return None
        for row in built:
            rows.append(row)
            row_lines.append(tuple(section.line for _cell in row))
    return rows, row_lines


def _value_section(book: Exporter, path: Path, index: int, section: IniSection) -> list[tuple[str, ...]] | None:
    values = _named(section)
    if "datatype" not in values or "count" not in values:
        book.fail(f"{_show(path)}:{section.line}: thiếu datatype hoặc count")
        return None
    if not values["count"].isdigit():
        book.fail(f"{_show(path)}:{section.line}: count không phải số")
        return None
    series = _value_keys(book, path, section)
    if series is None:
        return None
    total = int(values["count"])
    datatype = values["datatype"]
    built: list[tuple[str, ...]] = []
    for item in range(total):
        pairs = series.get(item)
        if not pairs or pairs[0][0] == "":
            book.fail(f"{_show(path)}:{section.line}: thiếu khoá value{item}")
            return None
        for pair in pairs:
            built.append((str(index), datatype, str(item), pair[0], pair[1]))
    extra = [slot for slot in series if slot >= total or slot < 0]
    if not extra:
        return built
    book.fail(f"{_show(path)}:{section.line}: khoá lạ: value{extra[0]}")
    return None


def _value_keys(book: Exporter, path: Path, section: IniSection) -> ValueSeries | None:
    series: ValueSeries = {}
    for key in section.keys:
        unknown = _value_key(series, key.name, key.value)
        if unknown is None:
            continue
        book.fail(f"{_show(path)}:{section.line}: khoá lạ: {unknown}")
        return None
    return series


def _value_key(series: ValueSeries, name: str, text: str) -> str | None:
    if name in {"datatype", "count"}:
        return None
    if name.startswith("valueex") and name[7:].isdigit():
        _value_extra(series, int(name[7:]), text)
        return None
    if name.startswith("value") and name[5:].isdigit():
        series.setdefault(int(name[5:]), []).append([text, ""])
        return None
    return name


def _value_extra(series: ValueSeries, slot: int, text: str) -> None:
    bucket = series.setdefault(slot, [])
    if bucket and bucket[-1][1] == "":
        bucket[-1][1] = text
        return
    bucket.append(["", text])


def _simple_table(
    book: Exporter,
    path: Path,
    relative: str,
    info_name: str,
    count_key: str,
    prefix: str,
    fields: tuple[FieldRow, ...],
) -> Table | None:
    parsed = scene_read.parse_ini(path)
    claimed = _claim(book, path, parsed, {info_name}, (prefix,))
    if claimed is None:
        return None
    info, groups = claimed
    count = _count(book, path, info.get(info_name), count_key)
    if count is None:
        return None
    if _only_keys(book, path, info[info_name], {count_key}) is None:
        return None
    built = _rows_from_fields(book, path, groups[prefix], count, fields, count_key)
    if built is None:
        return None
    rows, cell_lines = built
    types = tuple(field[2] for field in fields)
    columns = tuple(field[1] for field in fields)
    return Table(relative, _source(path), types, columns, rows, cell_lines)


def _level_table(book: Exporter, path: Path) -> Table | None:
    """Tệp monster_level không được LoadMonster đọc, nên không ghi đè spawns."""
    parsed = scene_read.parse_ini(path)
    claimed = _claim(book, path, parsed, set(), ("monster",))
    if claimed is None:
        return None
    _info, groups = claimed
    rows: list[tuple[str, ...]] = []
    cell_lines: list[tuple[int, ...]] = []
    for index, section in sorted(groups["monster"].items()):
        values = _only_keys(book, path, section, {"level"})
        if values is None:
            return None
        if "level" not in values:
            book.fail(f"{_show(path)}:{section.line}: thiếu khoá level")
            return None
        line = section.line
        for key in section.keys:
            if key.name == "level":
                line = key.line
                break
        book.note_int(path, line, "level", values["level"])
        rows.append((str(index), values["level"]))
        cell_lines.append((line, line))
    return Table("spawn_levels.tsv", _source(path), ("int", "int"), ("monster_index", "level"), rows, cell_lines)


def _patrol(book: Exporter, path: Path) -> list[dict[str, str]] | None:
    parsed = scene_read.parse_ini(path)
    claimed = _claim(book, path, parsed, {"INFO"}, ("PATROL",))
    if claimed is None:
        return None
    info, groups = claimed
    count = _count(book, path, info.get("INFO"), "PATROLNUMBER")
    if count is None:
        return None
    if _only_keys(book, path, info["INFO"], {"PATROLNUMBER"}) is None:
        return None
    if set(groups["PATROL"]) != set(range(count)):
        book.fail(f"{_show(path)}:1: PATROLNUMBER={count} nhưng có {len(groups['PATROL'])} mục")
        return None
    points = []
    for index in range(count):
        section = groups["PATROL"][index]
        built = _patrol_section(book, path, index, section)
        if built is None:
            return None
        points.extend(built)
    return points


@dataclass
class _PatrolWalk:
    points: dict[int, dict[str, str]]
    route_lines: dict[str, int]
    slot_lines: dict[tuple[int, str], int]


_PATROL_ROUTE = frozenset({"PATROLPOINTNUM", "isturnback", "isTeleportToRespawnPos", "scriptid"})


def _patrol_section(book: Exporter, path: Path, index: int, section: IniSection) -> list[dict[str, str]] | None:
    values = _named(section)
    total = _patrol_total(book, path, section, values)
    if total is None:
        return None
    walk = _patrol_walk(book, path, section, total)
    if walk is None:
        return None
    missing = _missing_patrol_pos(walk.points, total)
    if missing is not None:
        book.fail(f"{_show(path)}:{section.line}: thiếu POSX{missing} hoặc POSZ{missing}")
        return None
    extra = sorted(point for point in walk.points if point >= total)
    rows: list[dict[str, str]] = []
    for point in list(range(total)) + extra:
        row = _patrol_row(index, point, walk.points[point], values)
        _patrol_notes(book, path, point, row, walk)
        _stamp_patrol_lines(row, point, walk)
        rows.append(row)
    return rows


def _patrol_total(book: Exporter, path: Path, section: IniSection, values: dict[str, str]) -> int | None:
    if "PATROLPOINTNUM" not in values:
        book.fail(f"{_show(path)}:{section.line}: thiếu PATROLPOINTNUM")
        return None
    total = _atoi_count(values["PATROLPOINTNUM"])
    if total is None:
        book.fail(f"{_show(path)}:{section.line}: PATROLPOINTNUM không phải số")
        return None
    if values["PATROLPOINTNUM"] == str(total):
        return total
    book.changes["padded_count"] += 1
    line = _key_line(section, "PATROLPOINTNUM")
    book.note_int(path, line, "PATROLPOINTNUM", values["PATROLPOINTNUM"])
    return total


def _patrol_walk(book: Exporter, path: Path, section: IniSection, total: int) -> _PatrolWalk | None:
    walk = _PatrolWalk(
        points={item: {} for item in range(total)},
        route_lines={},
        slot_lines={},
    )
    for key in section.keys:
        if _patrol_route(walk.route_lines, key):
            continue
        if _patrol_point(book, path, section, walk, key):
            continue
        return None
    return walk


def _patrol_route(route_lines: dict[str, int], key: IniKey) -> bool:
    if key.name not in _PATROL_ROUTE:
        return False
    if key.name not in route_lines:
        route_lines[key.name] = key.line
    return True


def _patrol_point(book: Exporter, path: Path, section: IniSection, walk: _PatrolWalk, key: IniKey) -> bool:
    point, slot = _patrol_slot(key.name)
    if point is None or point < 0:
        book.fail(f"{_show(path)}:{section.line}: khoá lạ: {key.name}")
        return False
    if point not in walk.points:
        walk.points[point] = {}
        book.changes["point_outside_declared"] += 1
    slots = walk.points[point]
    previous = slots.get(slot)
    if previous not in (None, key.value):
        if not _patrol_unread(book, path, section.line, slots, key.name, key.value):
            return False
    else:
        slots[slot] = key.value
        walk.slot_lines[(point, slot)] = key.line
    if slot.startswith("speech_"):
        book.speech.add(int(slot.split("_", 1)[1]))
    return True


# Khoá lặp với giá trị khác: lần hai vào speech_unread, lần ba là lỗi.
def _patrol_unread(book: Exporter, path: Path, line: int, slots: dict[str, str], name: str, text: str) -> bool:
    if slots.get("speech_unread") not in (None, ""):
        book.fail(f"{_show(path)}:{line}: khoá {name} lặp quá hai lần")
        return False
    slots["speech_unread"] = text
    return True


def _missing_patrol_pos(points: dict[int, dict[str, str]], total: int) -> int | None:
    for point in range(total):
        slots = points[point]
        if "position_x" not in slots or "position_z" not in slots:
            return point
    return None


def _patrol_row(index: int, point: int, slots: dict[str, str], values: dict[str, str]) -> dict[str, str]:
    row = {
        "patrol_index": str(index),
        "point_index": str(point),
        "position_x": slots.get("position_x", ""),
        "position_y": slots.get("position_y", ""),
        "position_z": slots.get("position_z", ""),
        "settle_time": slots.get("settle_time", ""),
        "point_script_id": slots.get("point_script_id", ""),
        "route_script_id": values.get("scriptid", ""),
        "turns_back": values.get("isturnback", ""),
        "teleport_to_respawn": values.get("isTeleportToRespawnPos", ""),
        "speech_unread": slots.get("speech_unread", ""),
    }
    for slot, text in slots.items():
        if slot.startswith("speech_"):
            row[slot] = text
    return row


def _stamp_one_line(row: dict[str, str], name: str, line: int | None) -> None:
    if line is None:
        return
    row[f"__line_{name}"] = str(line)


def _stamp_patrol_lines(row: dict[str, str], point: int, walk: _PatrolWalk) -> None:
    for name in ("position_x", "position_y", "position_z", "settle_time", "point_script_id"):
        _stamp_one_line(row, name, walk.slot_lines.get((point, name)))
    _stamp_one_line(row, "turns_back", walk.route_lines.get("isturnback"))
    _stamp_one_line(row, "teleport_to_respawn", walk.route_lines.get("isTeleportToRespawnPos"))
    _stamp_one_line(row, "route_script_id", walk.route_lines.get("scriptid"))


def _stored_line(point: dict[str, str], name: str) -> int:
    text = point.get(f"__line_{name}", "")
    if text.isdigit():
        return int(text)
    return 1


def _patrol_notes(book: Exporter, path: Path, point: int, row: dict[str, str], walk: _PatrolWalk) -> None:
    if "isturnback" in walk.route_lines:
        line = walk.route_lines["isturnback"]
        book.note_int(path, line, "turns_back", row["turns_back"])
    if "isTeleportToRespawnPos" in walk.route_lines:
        line = walk.route_lines["isTeleportToRespawnPos"]
        book.note_int(path, line, "teleport_to_respawn", row["teleport_to_respawn"])
    marker = (point, "settle_time")
    if marker not in walk.slot_lines:
        return
    book.note_int(path, walk.slot_lines[marker], "settle_time", row["settle_time"])


def _patrol_slot(name: str) -> tuple[int | None, str]:
    pairs = (
        ("POSX", "position_x"),
        ("POSY", "position_y"),
        ("POSZ", "position_z"),
        ("settletime", "settle_time"),
        ("scriptid", "point_script_id"),
    )
    for prefix, slot in pairs:
        tail = name[len(prefix) :]
        if name.startswith(prefix) and tail.isdigit():
            return int(tail), slot
    if name.startswith("paopao") and "_" in name:
        head, sentence = name[len("paopao") :].split("_", 1)
        if head.isdigit() and sentence.isdigit():
            return int(head), f"speech_{sentence}"
    return None, ""


def _grow(
    book: Exporter,
    path: Path,
    relative: str,
    expected: tuple[str, ...],
    fields: tuple[ShortField, ...],
) -> Table | None:
    table = scene_read.parse_text_table(path)
    if table.types != expected:
        book.fail(f"{_show(path)}:1: dòng kiểu khác mẫu đã biết")
        return None
    columns = tuple(field[0] for field in fields)
    types = tuple(field[1] for field in fields)
    rows = [row for row in table.rows]
    for row in rows:
        if row[0].startswith("#"):
            book.fail(f"{_show(path)}:1: ô đầu bắt đầu bằng #")
            return None
    # Dòng 1 là kiểu, dòng 2 là tên. Bộ đọc không bỏ dòng dữ liệu.
    cell_lines = [tuple(number for _cell in row) for number, row in enumerate(rows, start=3)]
    return Table(relative, _source(path), types, columns, rows, cell_lines)


def _one(book: Exporter, scene: Scene, kind: str) -> Item | None:
    found = [item for item in scene.items if item.kind == kind and not item.set_stem]
    if len(found) > 1:
        book.fail(f"{scene.name}:1: hai tệp loại {kind}")
        return None
    if not found:
        return None
    return found[0]


def _assign_monsters(book: Exporter, scene: Scene) -> None:
    chosen: dict[str, Item] = {}
    plain = [item for item in scene.items if item.kind in MONSTER_KINDS and not item.set_stem]
    ranked = sorted(plain, key=lambda item: KIND_RANK[item.kind])
    for item in ranked:
        output = kinds.monster_output(item.path.name)
        if output is None:
            continue
        if output in chosen and item.kind == kinds.MONSTER_BARE:
            output = output.replace(".tsv", ".alt.tsv")
        if output in chosen:
            book.fail(f"{_show(item.path)}:1: trùng tệp đích {output}")
            return
        chosen[output] = item
    tables: dict[str, Table] = {}
    for output, item in chosen.items():
        spawns, operates, values = _monster_tables(book, item.path, output)
        if spawns is None:
            return
        tables[output] = spawns
        scene.tables.append(spawns)
        if operates is not None and values is not None:
            scene.tables.append(operates)
            scene.tables.append(values)
    for item in scene.items:
        if item.kind != kinds.MONSTER_LEVEL or item.set_stem:
            continue
        extra = _level_table(book, item.path)
        if extra is not None:
            scene.tables.append(extra)


def _set_relative(kind: str, stem: str) -> str | None:
    if kind in MONSTER_KINDS:
        return f"spawns.set_{stem}.tsv"
    if kind == kinds.AREA:
        return f"areas.set_{stem}.tsv"
    return None


def _assign_one_set(book: Exporter, scene: Scene, item: Item) -> None:
    relative = _set_relative(item.kind, item.set_stem)
    if relative is None:
        book.fail(f"{_show(item.path)}:1: scene_set không phải quái hoặc vùng")
        return
    if item.kind == kinds.AREA:
        table = _simple_table(book, item.path, relative, "area_info", "area_count", "area", AREA_FIELDS)
        if table is not None:
            scene.tables.append(table)
        return
    spawns, operates, values = _monster_tables(book, item.path, relative)
    if spawns is None:
        return
    scene.tables.append(spawns)
    if operates is not None and values is not None:
        scene.tables.append(operates)
        scene.tables.append(values)


def _assign_sets(book: Exporter, scene: Scene) -> None:
    for item in scene.items:
        if item.set_stem:
            _assign_one_set(book, scene, item)


def _fill_scene(book: Exporter, scene: Scene) -> None:
    _assign_monsters(book, scene)
    _assign_sets(book, scene)
    nav = _one(book, scene, kinds.NAV)
    if nav is not None:
        grid = _read_nav(book, nav.path)
        if grid is None:
            return
        scene.nav = nav.path
        scene.grid = grid
    area = _one(book, scene, kinds.AREA)
    if area is not None:
        table = _simple_table(book, area.path, "areas.tsv", "area_info", "area_count", "area", AREA_FIELDS)
        if table is not None:
            scene.tables.append(table)
    patrol = _one(book, scene, kinds.PATROL)
    if patrol is not None:
        points = _patrol(book, patrol.path)
        if points is not None:
            scene.patrol_points = points
            scene.patrol_source = _source(patrol.path)
    grow = _one(book, scene, kinds.GROWPOINT)
    if grow is not None:
        table = _grow(book, grow.path, "grow_points.tsv", ("int", "int", "float", "float"), GROW_FIELDS)
        if table is not None and not _grow_names(book, grow.path, ("INT", "INT", "FLOAT", "FLOAT")):
            return
        if table is not None:
            scene.tables.append(table)
    rules = _one(book, scene, kinds.GROWPOINT_SETUP)
    if rules is not None:
        if not _grow_names(book, rules.path, RULE_ORIGINAL):
            return
        rule_types = ("int", "int", "int", "text", "int", "int")
        table = _grow(book, rules.path, "grow_point_rules.tsv", rule_types, RULE_FIELDS)
        if table is not None:
            scene.tables.append(table)
    _optional_table(book, scene, kinds.PET, "wild_pets.tsv", "info", "petcount", "pet", PET_FIELDS)
    _optional_table(book, scene, kinds.PLATFORM, "platforms.tsv", "info", "platformcount", "platform", PLATFORM_FIELDS)
    _optional_table(book, scene, kinds.PORTAL, "portals.tsv", "info", "portalcount", "portal", PORTAL_FIELDS)
    _optional_table(book, scene, kinds.BUS, "buses.tsv", "info", "buscount", "bus", BUS_FIELDS)
    sidecars = ((kinds.PATH, "path_file"), (kinds.STALL, "stall_file"), (kinds.OBJECT_REGION, "object_region_file"))
    for kind, key in sidecars:
        found = sorted((item for item in scene.items if item.kind == kind), key=lambda item: item.path.name)
        for index, item in enumerate(found):
            sidecar = key if index == 0 else f"{key}_{index + 1}"
            scene.sidecars[sidecar] = item.path.name


def _grow_names(book: Exporter, path: Path, expected: tuple[str, ...]) -> bool:
    table = scene_read.parse_text_table(path)
    if table.names != expected:
        book.fail(f"{_show(path)}:2: dòng tên cột lạ")
        return False
    return True


def _optional_table(
    book: Exporter,
    scene: Scene,
    kind: str,
    relative: str,
    info: str,
    count_key: str,
    prefix: str,
    fields: tuple[FieldRow, ...],
) -> None:
    item = _one(book, scene, kind)
    if item is None:
        return
    table = _simple_table(book, item.path, relative, info, count_key, prefix, fields)
    if table is not None:
        scene.tables.append(table)


def _finalize_patrols(scenes: list[Scene], speech: set[int]) -> None:
    speech_names = tuple(f"speech_{index}" for index in sorted(speech))
    columns = tuple(field[0] for field in PATROL_BASE) + speech_names
    types = tuple(field[1] for field in PATROL_BASE) + tuple("text" for _name in speech_names)
    for scene in scenes:
        if scene.patrol_points is None:
            continue
        rows = []
        cell_lines = []
        for point in scene.patrol_points:
            rows.append(tuple(point.get(name, "") for name in columns))
            cell_lines.append(tuple(_stored_line(point, name) for name in columns))
        scene.tables.append(Table("patrols.tsv", scene.patrol_source, types, columns, rows, cell_lines))


def _render_toml(scene: Scene) -> str:
    version = [("schema", "1", COMMENTS["schema"])]
    if not scene.has_scn:
        version.append(("scene_file", "0", COMMENTS["scene_file"]))
    sections = [("Phiên bản", None, ["Mỗi cảnh một thư mục, tên giữ nguyên thân tệp scn."], version)]
    if scene.grid is not None:
        width, height = scene.grid
        grids = [
            ("grid_width", str(width), COMMENTS["grid_width"]),
            ("grid_height", str(height), COMMENTS["grid_height"]),
        ]
        sections.append(("Lưới đi", None, ["Hai số u16 đầu tệp nav, mỗi ô bốn byte."], grids))
    files = []
    if scene.nav is not None:
        files.append(("walk", _quote("walk.nav"), COMMENTS["walk"]))
    for table in scene.tables:
        key = _toml_key(table.relative)
        files.append((key, _quote(table.relative), _comment(key)))
    files.sort(key=lambda item: item[0])
    if files:
        sections.append(("Tệp đã xuất", None, ["Sinh lại bằng export_scene.py, không sửa tay."], files))
    if scene.sidecars:
        side = [(key, _quote(name), _comment(key)) for key, name in sorted(scene.sidecars.items())]
        sections.append(("Chỉ phân loại", None, ["Ba định dạng này chưa đọc, không chép byte."], side))
    if scene.missing:
        missing = []
        for key, name in sorted(scene.missing.items()):
            toml_key = key.replace("file", "_file") if not key.endswith("_file") else key
            if key == "petfile":
                toml_key = "pet_file"
            elif key == "portalfile":
                toml_key = "portal_file"
            elif key == "busfile":
                toml_key = "bus_file"
            missing.append((toml_key, _quote(name), COMMENTS[toml_key]))
        sections.append(("Khoá scn không có tệp", None, ["Mã 2008 không đọc các khoá này."], missing))
    intro = ["Dữ liệu cảnh bản 0859602 do công cụ sinh, sửa tay sẽ mất khi xuất lại."]
    text = config_style.render(f"CẢNH {scene.name.upper()}", intro, sections)
    lines = text.splitlines()
    lines.insert(3, TOOL_LINE)
    return _fit_toml(lines)


def _write_text(path: Path, text: str) -> None:
    _write_bytes(path, text.encode("utf-8"))


def _write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(prefix=f"{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(handle, "wb") as stream:
            stream.write(data)
        os.replace(temporary, path)
    except Exception:
        if os.path.exists(temporary):
            os.unlink(temporary)
        raise


def _rule_column_rows() -> tuple[tuple[str, str, str, str], ...]:
    paired = zip(RULE_ORIGINAL, RULE_FIELDS, strict=True)
    return tuple((original, field[0], field[1], field[2]) for original, field in paired)


def _column_specs(speech: set[int]) -> dict[str, ColumnSpec]:
    def pack(rows_fields: tuple[tuple[str, str, str, str], ...]) -> ColumnSpec:
        return _column_rows(rows_fields)

    spawn = tuple((field[0], field[1], field[2], field[3]) for field in SPAWN_FIELDS)
    specs = {
        "spawns.tsv": pack(spawn),
        "areas.tsv": pack(tuple((field[0], field[1], field[2], field[3]) for field in AREA_FIELDS)),
        "platforms.tsv": pack(tuple((field[0], field[1], field[2], field[3]) for field in PLATFORM_FIELDS)),
        "wild_pets.tsv": pack(tuple((field[0], field[1], field[2], field[3]) for field in PET_FIELDS)),
        "portals.tsv": pack(tuple((field[0], field[1], field[2], field[3]) for field in PORTAL_FIELDS)),
        "buses.tsv": pack(tuple((field[0], field[1], field[2], field[3]) for field in BUS_FIELDS)),
        "grow_points.tsv": pack(tuple(("", field[0], field[1], field[2]) for field in GROW_FIELDS)),
        "grow_point_rules.tsv": pack(_rule_column_rows()),
        "spawn_operates.tsv": pack(
            (
                ("", "spawn_file", "text", "bảng quái mà luật áp vào"),
                ("selecttype", "select_type", "int", "kiểu chọn quái"),
                ("selectvalue", "select_value", "text", "giá trị chọn, giữ nguyên văn"),
                ("data_def", "data_def", "int", "chỉ số vùng dữ liệu"),
                ("maxleft", "max_left", "int", "số quái giữ lại"),
            )
        ),
        "spawn_levels.tsv": pack(
            (
                ("", "monster_index", "int", "chỉ số monster trong tệp level"),
                ("level", "level", "int", "nguyên văn tệp monster_level; mã 2008 không đọc"),
            )
        ),
        "spawn_operate_values.tsv": pack(
            (
                ("", "spawn_file", "text", "bảng quái mà giá trị thuộc về"),
                ("", "data_index", "int", "chỉ số data_def"),
                ("datatype", "data_type", "int", "kiểu dữ liệu của vùng"),
                ("", "value_index", "int", "chỉ số value"),
                ("value", "value", "text", "mã 2008 đọc khoá value"),
                ("valueex", "value_extra", "text", "mã 2008 không đọc; với toạ độ thì đây là trục còn lại"),
            )
        ),
    }
    patrol_fields = tuple((field[2], field[0], field[1], field[3]) for field in PATROL_BASE)
    unread = "mã 2008 không đọc"
    speech_fields = tuple((f"paopao<điểm>_{index}", f"speech_{index}", "text", unread) for index in sorted(speech))
    specs["patrols.tsv"] = pack(patrol_fields + speech_fields)
    return specs


def _attach_file(given: Path | None) -> Path:
    if given is not None:
        return given
    return Path(__file__).resolve().with_name("scene_attach.tsv")


def _attach_cells(path: Path, number: int, cells: list[str]) -> tuple[str, str, str]:
    if len(cells) != 4:
        raise ValueError(f"{path.name}:{number}: thiếu cột")
    filename, fate, scene, evidence = cells
    if not filename or fate not in _ATTACH_FATES or not evidence:
        raise ValueError(f"{path.name}:{number}: dòng không hợp lệ")
    if fate == "scene_set" and not scene:
        raise ValueError(f"{path.name}:{number}: scene_set thiếu cảnh")
    if fate == "client_only" and scene:
        raise ValueError(f"{path.name}:{number}: client_only không có cảnh")
    return filename, fate, scene


def _read_attach(path: Path) -> AttachMap:
    if not path.is_file():
        raise ValueError(f"{path.name}:1: thiếu scene_attach.tsv")
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "# schema 1":
        raise ValueError(f"{path.name}:1: thiếu schema")
    if not any(line.startswith("# types: ") for line in lines):
        raise ValueError(f"{path.name}:1: thiếu types")
    header: list[str] | None = None
    rows: AttachMap = {}
    for number, line in enumerate(lines, start=1):
        if line.startswith("# tool:"):
            raise ValueError(f"{path.name}:{number}: không được có dòng tool")
        if line.startswith("#") or line == "":
            continue
        cells = line.split("\t")
        if header is None:
            header = cells
            if tuple(header) != _ATTACH_HEADER:
                raise ValueError(f"{path.name}:{number}: sai cột")
            continue
        filename, fate, scene = _attach_cells(path, number, cells)
        if filename in rows:
            raise ValueError(f"{path.name}:{number}: lặp {filename}")
        rows[filename] = (fate, scene)
    if not rows:
        raise ValueError(f"{path.name}:1: scene_attach rỗng")
    return rows


def _place_loose(book: Exporter, scenes: dict[str, Scene], item: Item, attach: AttachMap) -> None:
    row = attach.get(item.path.name)
    if row is None:
        book.unattached.append(f"{_show(item.path)}:1: không gắn được vào cảnh nào")
        return
    fate, scene_name = row
    if fate == "client_only":
        book.changes["client_only"] += 1
        return
    scene = scenes.get(scene_name)
    if scene is None:
        book.fail(f"{_show(item.path)}:1: scene_attach trỏ cảnh không có {scene_name}")
        return
    stem = kinds.stem_of(item.path.name)
    if stem is None:
        book.fail(f"{_show(item.path)}:1: không có thân tên để xuất bộ script")
        return
    _add_item(scene, Item(item.path, item.kind, stem))


def _note_above(line: str) -> tuple[str, str] | None:
    if len(line) <= config_style.LINE_LIMIT or not config_style.KEY.match(line):
        return None
    key, value, note = config_style.split_setting(line)
    if not note:
        return None
    return f"# {note}", f"{key} = {value}"


def _lift_once(lines: list[str]) -> tuple[list[str], bool]:
    lifted: list[str] = []
    changed = False
    for line in lines:
        pair = _note_above(line)
        if pair is None:
            lifted.append(line)
            continue
        changed = True
        lifted.append(pair[0])
        lifted.append(pair[1])
    return lifted, changed


def _fit_toml(lines: list[str]) -> str:
    """Chú thích làm dòng quá 110 cột thì đưa lên dòng trên, rồi căn lại."""
    current = lines
    for _turn in range(4):
        aligned = config_style.align_lines(current)
        current, changed = _lift_once(aligned)
        if not changed:
            return "\n".join(aligned) + "\n"
    return "\n".join(config_style.align_lines(current)) + "\n"


def _collect(legacy_root: Path, book: Exporter, attach: AttachMap) -> tuple[dict[str, int], list[Scene]]:
    scene_root = Path(legacy_root) / "Public" / "Scene"
    if not scene_root.is_dir():
        book.fail(f"{scene_root}:1: không thấy Public/Scene")
        return {}, []
    paths = sorted(path for path in scene_root.iterdir() if path.is_file())
    for child in scene_root.iterdir():
        if child.is_dir():
            book.fail(f"Public/Scene/{child.name}:1: thư mục lạ")
    counts: Counter[str] = Counter()
    items: list[Item] = []
    for path in paths:
        kind = kinds.classify_name(path.name)
        if kind is None:
            book.fail(f"{_show(path)}:1: chưa phân loại")
            continue
        counts[kind] += 1
        items.append(Item(path, kind))
    stems = {item.path.name[: -len(".scn")] for item in items if item.kind == kinds.SCN}
    by_name = {item.path.name: item for item in items}
    scenes = {stem: Scene(stem, True) for stem in stems}
    referenced: dict[str, set[str]] = {}
    for item in items:
        if item.kind != kinds.SCN:
            continue
        _read_scn(book, item.path, scenes[item.path.name[: -len(".scn")]], by_name, referenced)
    for item in items:
        if item.kind in {kinds.DROPPED, kinds.SCN}:
            continue
        owners = referenced.get(item.path.name)
        if owners:
            for owner in owners:
                _add_item(scenes[owner], item)
            continue
        owner = kinds.longest_stem(item.path.name, stems)
        if owner is not None:
            _add_item(scenes[owner], item)
            continue
        _place_loose(book, scenes, item, attach)
    conflict = case_conflict(set(scenes))
    if conflict is not None:
        book.fail(conflict)
    return dict(counts), [scenes[name] for name in sorted(scenes)]


def _add_item(scene: Scene, item: Item) -> None:
    if any(have.path == item.path for have in scene.items):
        return
    scene.items.append(item)


def _read_scn(book: Exporter, path: Path, scene: Scene, by_name: Items, referenced: Users) -> None:
    try:
        parsed = scene_read.parse_ini(path)
    except scene_read.SceneError as exc:
        book.fail(str(exc))
        return
    book.changes["same_key_repeats"] += parsed.same_key_repeats
    book.changes["trailing_lf"] += parsed.trailing_lf
    book.changes["distinct_duplicate_key"] += parsed.distinct_repeats
    claimed = _claim(book, path, scene_read.IniFile(parsed.sections, 0, 0, 0), {"System"}, ())
    if claimed is None:
        return
    info, _groups = claimed
    system = info.get("System")
    if system is None:
        book.fail(f"{_show(path)}:1: thiếu section System")
        return
    values = _named(system)
    for name in values:
        if name not in SCN_KEYS:
            book.fail(f"{_show(path)}:{system.line}: khoá lạ: {name}")
            return
    for key in REQUIRED_SCN:
        if key not in values:
            book.fail(f"{_show(path)}:{system.line}: thiếu khoá {key}")
            return
    if "growpointdata" in values and "growpointsetup" not in values:
        book.fail(f"{_show(path)}:{system.line}: thiếu growpointsetup")
        return
    for key, filename in values.items():
        item = by_name.get(filename)
        expected = SCN_KEYS[key]
        if item is None:
            if key in OPTIONAL_MISSING:
                scene.missing[key] = filename
                continue
            book.fail(f"{_show(path)}:{system.line}: không thấy tệp {filename}")
            return
        if expected != "monster" and item.kind != expected:
            book.fail(f"{_show(path)}:{system.line}: {filename} không phải {expected}")
            return
        if expected == "monster" and item.kind not in MONSTER_KINDS:
            book.fail(f"{_show(path)}:{system.line}: {filename} không phải tệp quái")
            return
        referenced.setdefault(filename, set()).add(scene.name)


def _c_atoi(text: str) -> int | None:
    """atoi của C trên ô int. Tràn int32 thì None, không bọc số."""
    index = 0
    size = len(text)
    while index < size and text[index] in " \t\n\v\f\r":
        index += 1
    sign = 1
    if index < size and text[index] in "+-":
        if text[index] == "-":
            sign = -1
        index += 1
    if index >= size or not text[index].isdigit():
        return 0
    limit = 2147483648 if sign < 0 else 2147483647
    value = 0
    while index < size and text[index].isdigit():
        digit = ord(text[index]) - 48
        if value > (limit - digit) // 10:
            return None
        value = value * 10 + digit
        index += 1
    if sign < 0:
        value = -value
    return value


def _canonical_cell(kind: str, text: str) -> str | None:
    """Ô int theo atoi, ô float bỏ trắng hai đầu. Rỗng giữ rỗng."""
    if text == "" or kind == "text":
        return text
    if kind == "float":
        return text.strip()
    if kind != "int":
        return text
    number = _c_atoi(text)
    if number is None:
        return None
    return str(number)


def _store_cell(book: Exporter, kind: str, text: str) -> str | None:
    written = _canonical_cell(kind, text)
    if written is None:
        return None
    if written != text:
        book.changes["cells_rewritten"] += 1
    return written


def _source_line(table: Table, row_index: int, column: int) -> int:
    if row_index >= len(table.cell_lines):
        return 1
    lines = table.cell_lines[row_index]
    if column >= len(lines):
        return 1
    return lines[column]


def _rewrite_row(
    book: Exporter, scene_name: str, table: Table, row: tuple[str, ...], row_index: int
) -> tuple[str, ...] | None:
    if len(row) != len(table.types):
        book.fail(f"{scene_name}/{table.relative}:1: sai số ô")
        return None
    cells: list[str] = []
    for index, text in enumerate(row):
        written = _store_cell(book, table.types[index], text)
        if written is None:
            line = _source_line(table, row_index, index)
            book.fail(f"{scene_name}/{table.relative}:{line}: số vượt int32")
            return None
        cells.append(written)
    return tuple(cells)


def _rewrite_table(book: Exporter, scene_name: str, table: Table) -> None:
    rewritten: list[tuple[str, ...]] = []
    for row_index, row in enumerate(table.rows):
        cells = _rewrite_row(book, scene_name, table, row, row_index)
        if cells is None:
            return
        rewritten.append(cells)
    table.rows = rewritten


def _rewrite_tables(book: Exporter, scenes: list[Scene]) -> None:
    """Ghi ô số về dạng chính tắc sau khi đã đếm dạng gốc."""
    for scene in scenes:
        for table in scene.tables:
            _rewrite_table(book, scene.name, table)


def _build(book: Exporter, scenes: list[Scene]) -> None:
    for scene in scenes:
        if book.stopped():
            return
        try:
            _fill_scene(book, scene)
        except scene_read.SceneError as exc:
            book.fail(str(exc))
    _finalize_patrols(scenes, book.speech)
    if not book.errors:
        _rewrite_tables(book, scenes)


def _records_of(scenes: list[Scene]) -> dict[str, int]:
    totals: Counter[str] = Counter()
    for scene in scenes:
        for table in scene.tables:
            totals[_record_bucket(table.relative)] += len(table.rows)
    return dict(totals)


def _column_dir(columns: Path | None) -> Path:
    if columns is not None:
        return Path(columns)
    here = Path(__file__).resolve().parent
    return here / "columns" / "scenes"


def _scene_binaries(scene: Scene) -> tuple[str, ...]:
    if scene.nav is None:
        return ()
    return ("walk.nav",)


def _owned_file(path: Path, folder: Path, claimed: set[str], tool_id: str) -> bool:
    relative = path.relative_to(folder).as_posix()
    if relative in claimed:
        return True
    return tsv_file._owned_tool(path) == tool_id


def _foreign_file(folder: Path, binaries: tuple[str, ...]) -> str | None:
    """Tệp lạ trong thư mục đã có. Không tạo, không xoá."""
    if not folder.exists():
        return None
    if not folder.is_dir():
        return f"{folder}:1: tệp lạ, không xoá"
    tool_id = tsv_file.canonical_tool(TOOL)
    claimed = {tsv_file._relative_name(name) for name in binaries}
    paths = [item for item in folder.rglob("*") if item.is_file()]
    for path in sorted(paths):
        if _owned_file(path, folder, claimed, tool_id):
            continue
        return f"{path}:1: tệp lạ, không xoá"
    return None


def _check_child(child: Path, scene: Scene | None) -> str | None:
    if scene is None and child.is_file():
        return f"{child}:1: tệp lạ, không xoá"
    if scene is None:
        return _foreign_file(child, ("walk.nav",))
    return _foreign_file(child, _scene_binaries(scene))


def _check_destination(destination: Path, scenes: list[Scene]) -> str | None:
    if not destination.exists():
        return None
    if not destination.is_dir():
        return f"{destination}:1: tệp lạ, không xoá"
    by_name = {scene.name: scene for scene in scenes}
    for child in sorted(destination.iterdir()):
        message = _check_child(child, by_name.get(child.name))
        if message is not None:
            return message
    return None


def _check_output(destination: Path, columns: Path, scenes: list[Scene]) -> str | None:
    message = _check_destination(destination, scenes)
    if message is not None:
        return message
    return _foreign_file(columns, ())


def _finish_check(report: Report, destination: Path, columns: Path, scenes: list[Scene]) -> Report:
    try:
        message = _check_output(destination, columns, scenes)
    except tsv_file.TsvError as exc:
        message = str(exc)
    if message is None:
        return report
    report.ok = False
    report.show_summary = False
    report.errors = [message, *report.errors]
    return report


def _write_scenes(destination: Path, columns: Path, scenes: list[Scene], speech: set[int]) -> None:
    expected = {scene.name for scene in scenes}
    destination.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        for child in sorted(destination.iterdir()):
            if child.name in expected:
                continue
            if child.is_file():
                raise tsv_file.TsvError(f"{child.name}:1: tệp lạ, không xoá")
            tsv_file.prepare_directory(child, TOOL, ["walk.nav"])
            if not any(child.iterdir()):
                child.rmdir()
    for scene in scenes:
        folder = destination / scene.name
        tsv_file.prepare_directory(folder, TOOL, ["walk.nav"] if scene.nav is not None else [])
        if scene.nav is not None:
            _write_bytes(folder / "walk.nav", scene.nav.read_bytes())
        for table in scene.tables:
            target = folder / table.relative
            column_types = list(table.types)
            column_names = list(table.columns)
            tsv_file.write_table(target, table.source, TOOL, column_types, column_names, table.rows)
        _write_text(folder / "scene.toml", _render_toml(scene))
    used = {_column_name(table.relative) for scene in scenes for table in scene.tables}
    specs = _column_specs(speech)
    tsv_file.prepare_directory(columns, TOOL)
    for name in sorted(used):
        columns_of, types, rows = specs[name]
        tsv_file.write_table(columns / name, "Public/Scene", TOOL, list(types), list(columns_of), rows)


def _column_name(relative: str) -> str:
    if relative.startswith("spawn_operate_values"):
        return "spawn_operate_values.tsv"
    if relative.startswith("spawn_operates"):
        return "spawn_operates.tsv"
    if relative.startswith("spawns"):
        return "spawns.tsv"
    if relative.startswith("areas"):
        return "areas.tsv"
    return relative


def export_scenes(
    legacy_root: Path,
    destination: Path,
    columns: Path | None = None,
    check_only: bool = False,
    attach_path: Path | None = None,
) -> Report:
    """Đọc cả cây. Có lỗi, kể cả tệp không gắn được, thì không ghi tệp nào."""
    book = Exporter()
    try:
        attach = _read_attach(_attach_file(attach_path))
    except ValueError as exc:
        book.fail(str(exc))
        attach = {}
    counts, scenes = _collect(Path(legacy_root), book, attach)
    if not book.errors:
        _build(book, scenes)
    blocked = bool(book.errors or book.unattached)
    report = Report(
        ok=not blocked,
        errors=list(book.errors) + list(book.unattached),
        kinds=dict(sorted(counts.items())),
        scene_count=len(scenes),
        orphan_scene_count=sum(1 for scene in scenes if not scene.has_scn),
        records=_records_of(scenes),
        changes=dict(sorted(book.changes.items())),
        int_places=list(book.int_places),
        show_summary=not book.errors,
        scenes=scenes,
    )
    if blocked:
        return report
    column_dir = _column_dir(columns)
    if check_only:
        return _finish_check(report, Path(destination), column_dir, scenes)
    try:
        _write_scenes(Path(destination), column_dir, scenes, book.speech)
    except tsv_file.TsvError as exc:
        report.ok = False
        report.show_summary = False
        report.errors = [str(exc), *report.errors]
    return report


def _print_report(report: Report) -> None:
    for error in report.errors:
        print(error)
    for place in report.int_places:
        print(place)
    if not report.show_summary:
        return
    print(f"cảnh: {report.scene_count}")
    print(f"cảnh không scn: {report.orphan_scene_count}")
    print("tệp nguồn:")
    for name, count in report.kinds.items():
        print(f"  {name} {count}")
    print("bản ghi:")
    for name, count in report.records.items():
        print(f"  {name} {count}")
    print("biến đổi:")
    for name, count in report.changes.items():
        print(f"  {name} {count}")


def main(argv: list[str] | None = None) -> int:
    """Điểm vào dòng lệnh. In một dòng lỗi theo dạng tệp:dòng: nội dung."""
    sys.stdout.reconfigure(encoding="utf-8")
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    check_only = "--check" in args
    positional = [arg for arg in args if arg != "--check"]
    if len(positional) != 2:
        print("export_scene.py:1: cần hai tham số, thư mục tlbb và thư mục đích")
        return 1
    report = export_scenes(Path(positional[0]), Path(positional[1]), None, check_only)
    _print_report(report)
    return 0 if report.ok else 1


if __name__ == "__main__":
    sys.exit(main())
