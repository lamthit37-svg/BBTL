"""Đổi khoá ini luật chơi thành TOML trong dev/server/config/rules.

    python TOOLS/server/import_rules.py <thư mục tlbb> <thư mục rules> [--check]

Đọc TOOLS/server/legacy_rules.tsv. Khoá fate=rule được ghi bằng config_style.
Khoá fate=process_config chỉ so với dev/server/config, không sửa mười một tệp đó.
--check không ghi tệp. Thoát 0 khi hết lỗi chuyển đổi; lệch giá trị tiến trình
được in, không làm lệnh thất bại. Dòng ini `#khoá=giá trị` là khoá, không phải chú thích.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path

import config_style

TOOL_DIR = Path(__file__).resolve().parent
PROJECT = TOOL_DIR.parents[1]
HEADER = (
    "source",
    "section",
    "key",
    "fate",
    "target_file",
    "target_table",
    "target_key",
    "index",
    "convert",
    "note_vi",
    "basis",
    "reason",
)
FATES = frozenset({"rule", "process_config", "dropped", "unknown"})
CONVERTS = frozenset({"int", "bool", "text", "permille", "ppm", "decimal", "window", ""})
SOURCES = (
    ("Server/Config/ConfigInfo.ini", "ini"),
    ("Server/Config/DefaultChar.ini", "ini"),
    ("Server/Config/PetConfigTable.ini", "ini"),
    ("Server/Config/DarkConfigTable.ini", "ini"),
    ("Server/Config/CopyScene.ini", "ini"),
    ("Public/Config/CombatLimits.ini", "bare"),
    ("Server/Config/SystemInfo.ini", "info"),
    ("Server/Config/MergeConfig.txt", "merge"),
)
CODE_BASIS = re.compile(r"code:[A-Za-z0-9_./-]+:\d+")
IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
HELP = """\
cách dùng: python TOOLS/server/import_rules.py <thư mục tlbb> <thư mục rules> [--check]

Đọc legacy_rules.tsv, ghi các tệp luật fate=rule, so khoá fate=process_config
với dev/server/config. --check không ghi. Thoát 0 khi sạch, 1 khi có lỗi.
"""
FILE_TEXT = {
    "global.toml": (
        "LUẬT CHUNG",
        "Hệ số rơi đồ, hồi sinh quái, cấp hồi sinh tại chỗ, ngôn ngữ và trân thú lỗi.",
    ),
    "combat.toml": (
        "LUẬT CHIẾN ĐẤU",
        "Dao động sát thương, hằng số trúng đích và chí mạng, giảm sát thương khi PK, trần thuộc tính.",
    ),
    "character.toml": (
        "LUẬT NHÂN VẬT",
        "Tầm kinh nghiệm, hồn ma, tốc độ, cấp tối đa, hồi hoạt lực và hệ số kinh nghiệm.",
    ),
    "new_character.toml": (
        "NHÂN VẬT MỚI",
        "Cảnh, toạ độ, chỉ số, kỹ năng, công thức và thiết lập lúc tạo nhân vật.",
    ),
    "monster.toml": (
        "LUẬT QUÁI",
        "Tầm sinh lại, thời gian giữ xác, đổi mục tiêu, cấp tối đa và ngưỡng giảm thu nhập.",
    ),
    "instances.toml": (
        "PHÓ BẢN",
        "Số nhóm phó bản và số cảnh tối đa mỗi nhóm.",
    ),
    "pet.toml": (
        "LUẬT TRÂN THÚ",
        "Xác suất sinh, tăng trưởng, cốt cách, tư chất, tốc độ và phí của trân thú.",
    ),
    "hidden_weapon.toml": (
        "LUẬT ÁM KHÍ",
        "Tỉ lệ năm bậc tăng trưởng của ám khí theo ba hạng. Mẫu số của mỗi hạng là 1000.",
    ),
    "pvp.toml": (
        "LUẬT ĐỐI KHÁNG",
        "Thách đấu, tuyên chiến, cờ PK, phản kích, điểm thiện ác và điểm cốt truyện.",
    ),
    "guild.toml": (
        "LUẬT BANG HỘI",
        "Thành viên, nha môn, tiền trang, sương phòng, phồn vinh và liên minh.",
    ),
    "social.toml": (
        "LUẬT XÃ HỘI",
        "Theo đội, độ thân thiết và mật khẩu cấp hai.",
    ),
    "economy.toml": (
        "LUẬT KINH TẾ",
        "Giá bán, phiếu ingot, ký gửi, cửa hàng người chơi và mốc đóng mở khi gộp máy.",
    ),
    "fatigue.toml": (
        "LUẬT CHỐNG NGHIỆN",
        "Ngưỡng giờ chơi mệt và câu hỏi chống treo máy.",
    ),
}
TABLE_TITLE = {
    ("global.toml", "drop"): "Rơi đồ",
    ("global.toml", "durability"): "Độ bền",
    ("global.toml", "respawn"): "Hồi sinh quái",
    ("global.toml", "revive"): "Hồi sinh tại chỗ",
    ("global.toml", "pet_guard"): "Trân thú lỗi",
    ("global.toml", "language"): "Ngôn ngữ",
    ("global.toml", "rolling_notice"): "Thông báo luân phiên",
    ("global.toml", "scheduled_event"): "Sự kiện theo giờ",
    ("combat.toml", "damage"): "Sát thương",
    ("combat.toml", "hit"): "Trúng đích",
    ("combat.toml", "critical"): "Chí mạng",
    ("combat.toml", "limit"): "Trần chiến đấu",
    ("character.toml", "human"): "Nhân vật",
    ("character.toml", "exp"): "Kinh nghiệm",
    ("character.toml", "life_skill"): "Kỹ năng sống",
    ("new_character.toml", "profile"): "Hồ sơ ban đầu",
    ("new_character.toml", "vigor"): "Hoạt lực",
    ("new_character.toml", "energy"): "Tinh lực",
    ("new_character.toml", "skill"): "Kỹ năng",
    ("new_character.toml", "attribute"): "Chỉ số gốc",
    ("new_character.toml", "life_skill"): "Kỹ năng sống",
    ("new_character.toml", "inner_art"): "Tâm pháp",
    ("new_character.toml", "recipe"): "Công thức",
    ("new_character.toml", "setting"): "Thiết lập",
    ("new_character.toml", "start_position"): "Vị trí xuất phát thêm",
    ("monster.toml", "monster"): "Quái",
    ("monster.toml", "income"): "Thu nhập khi cày quái",
    ("instances.toml", "copy"): "Phó bản",
    ("instances.toml", "instance"): "Phó bản",
    ("pet.toml", "life"): "Tuổi thọ và vui vẻ",
    ("pet.toml", "friend_ad"): "Tin tìm bạn",
    ("pet.toml", "level"): "Cấp",
    ("pet.toml", "death"): "Chết",
    ("pet.toml", "birth"): "Sinh ra",
    ("pet.toml", "wild_level"): "Cấp thú dại",
    ("pet.toml", "growth"): "Tăng trưởng",
    ("pet.toml", "bone"): "Cốt cách",
    ("pet.toml", "mutant_level"): "Cấp đột biến",
    ("pet.toml", "aptitude_range"): "Biên độ tư chất",
    ("pet.toml", "speed"): "Tốc độ",
    ("pet.toml", "ai"): "Phép của AI",
    ("pet.toml", "base"): "Chỉ số gốc",
    ("pet.toml", "factor"): "Hệ số chỉ số",
    ("pet.toml", "level_factor"): "Hệ số theo cấp",
    ("pet.toml", "carry"): "Số lượng mang",
    ("pet.toml", "study"): "Học kỹ năng",
    ("pet.toml", "bone_level"): "Cốt cách theo cấp",
    ("pet.toml", "savvy"): "Ngộ tính",
    ("pet.toml", "compound"): "Ghép thú",
    ("pet.toml", "bone_pill"): "Đan cốt cách",
    ("pet.toml", "rejuvenation"): "Hoàn đồng",
    ("pet.toml", "aptitude"): "Tư chất",
    ("pet.toml", "aptitude_factor"): "Hệ số tư chất",
    ("pet.toml", "aptitude_formula"): "Công thức bậc tư chất",
    ("pet.toml", "skill_slot"): "Ô kỹ năng",
    ("hidden_weapon.toml", "quality"): "Phẩm chất",
    ("pvp.toml", "duel"): "Thách đấu",
    ("pvp.toml", "warfare"): "Tuyên chiến",
    ("pvp.toml", "pk"): "Cờ PK",
    ("pvp.toml", "fight_back"): "Phản kích",
    ("pvp.toml", "morality"): "Thiện ác",
    ("pvp.toml", "story"): "Điểm cốt truyện",
    ("guild.toml", "guild"): "Bang",
    ("guild.toml", "county_office"): "Nha môn",
    ("guild.toml", "bank"): "Tiền trang",
    ("guild.toml", "guest_wing"): "Sương phòng",
    ("guild.toml", "prosperity"): "Phồn vinh",
    ("guild.toml", "league"): "Liên minh",
    ("social.toml", "team"): "Tổ đội",
    ("social.toml", "relation"): "Quan hệ",
    ("social.toml", "secondary_password"): "Mật khẩu cấp hai",
    ("economy.toml", "price"): "Giá bán",
    ("economy.toml", "voucher"): "Phiếu ingot",
    ("economy.toml", "exchange"): "Giao dịch",
    ("economy.toml", "consignment"): "Ký gửi",
    ("economy.toml", "player_shop"): "Cửa hàng người chơi",
    ("economy.toml", "card"): "Thẻ tài phú",
    ("economy.toml", "closure"): "Đóng mở khi gộp máy",
    ("fatigue.toml", "fatigue"): "Mệt",
    ("fatigue.toml", "captcha"): "Chống treo máy",
}


# Khác gốc: giá trị ta cố ý đổi so với ini gốc. Lượt nhập sau giữ chúng và nối lý do vào chú thích, để
# không ai chép lại số gốc vào account/starter.hpp. Khoá là (tệp, bảng, khoá) như ở legacy_rules.tsv.
# G1-M D4: (165; 169) của DefaultChar.ini là tam giác vật cản của lưới đi 2026, nhân vật mới bị kéo về;
# (165,00; 169,71) là điểm đi được gần nhất, cách mọi cạnh ràng buộc ít nhất 20 cm. Chỉ cảnh 2 có lưới.
SPAWN_NOTE = "Khác gốc (cảnh 2), xem G1-M D4."
DEVIATIONS = {
    ("new_character.toml", "profile", "position_z"): ("169.71", SPAWN_NOTE),
    ("new_character.toml", "start_position", "position_z"): ("[169.71, 169.0, 169.0]", SPAWN_NOTE),
}


class RulesError(Exception):
    """Lỗi có vị trí tệp:dòng: nội dung."""


@dataclass(frozen=True)
class HandRow:
    source: str
    section: str
    key: str
    fate: str
    target_file: str
    target_table: str
    target_key: str
    index: str
    convert: str
    note_vi: str
    basis: str
    reason: str
    line: int


@dataclass(frozen=True)
class SourceKey:
    source: str
    section: str
    key: str
    value: str
    line: int


def _fail(location: str, line: int, message: str) -> RulesError:
    return RulesError(f"{location}:{line}: {message}")


def _default_rules() -> Path:
    return TOOL_DIR / "legacy_rules.tsv"


def _read_text(path: Path) -> str:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise _fail(path.as_posix(), 1, "có BOM")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise _fail(path.as_posix(), 1, "byte UTF-8 hỏng") from exc


def _basis_ok(text: str) -> bool:
    parts = [part.strip() for part in text.split(";")]
    if not parts or len(parts) > 2:
        return False
    for part in parts:
        if part in {"comment", "name"}:
            continue
        if CODE_BASIS.fullmatch(part):
            continue
        return False
    return True


def _need(row: HandRow, field: str, label: str) -> None:
    if field == "":
        raise _fail("legacy_rules.tsv", row.line, f"{label} rỗng")


def _check_row(row: HandRow) -> None:
    if row.fate not in FATES:
        raise _fail("legacy_rules.tsv", row.line, f"fate lạ: {row.fate}")
    if row.convert not in CONVERTS:
        raise _fail("legacy_rules.tsv", row.line, f"convert lạ: {row.convert}")
    if row.index != "" and not row.index.isdigit():
        raise _fail("legacy_rules.tsv", row.line, "index không phải số")
    if row.fate == "rule":
        _need(row, row.target_file, "target_file")
        _need(row, row.target_table, "target_table")
        _need(row, row.target_key, "target_key")
        _need(row, row.convert, "convert")
        _need(row, row.note_vi, "note_vi")
        _need(row, row.basis, "basis")
        if not _basis_ok(row.basis):
            raise _fail("legacy_rules.tsv", row.line, "basis không đúng dạng")
        if not IDENT.fullmatch(row.target_key):
            raise _fail("legacy_rules.tsv", row.line, "target_key không phải định danh")
    if row.fate == "process_config":
        _need(row, row.target_file, "target_file")
        _need(row, row.target_key, "target_key")
    if row.fate in {"dropped", "unknown"} and row.reason == "":
        raise _fail("legacy_rules.tsv", row.line, "thiếu reason")


def _hand_rows(path: Path) -> tuple[HandRow, ...]:
    """Đọc bảng soạn tay. Không có dòng # tool:."""
    text = _read_text(path)
    if "# tool:" in text:
        raise _fail(path.as_posix(), 1, "bảng soạn tay không được có dòng tool")
    if "# schema 1" not in text.splitlines():
        raise _fail(path.as_posix(), 1, "thiếu dòng schema")
    types = "# types: " + "\t".join(["text"] * len(HEADER))
    if types not in text.splitlines():
        raise _fail(path.as_posix(), 1, "thiếu hoặc sai dòng types")
    header: tuple[str, ...] | None = None
    rows: list[HandRow] = []
    seen: set[tuple[str, str, str]] = set()
    for number, line in enumerate(text.splitlines(), start=1):
        if line == "" or line.startswith("#"):
            continue
        cells = line.split("\t")
        if header is None:
            header = tuple(cells)
            if header != HEADER:
                raise _fail(path.as_posix(), number, "sai dòng tên cột")
            continue
        if len(cells) != len(HEADER):
            raise _fail(path.as_posix(), number, f"{len(cells)} ô, cần {len(HEADER)}")
        row = HandRow(*cells, number)
        _check_row(row)
        identity = (row.source, row.section, row.key)
        if identity in seen:
            raise _fail(path.as_posix(), number, "cặp section và khoá trùng")
        seen.add(identity)
        rows.append(row)
    if header is None:
        raise _fail(path.as_posix(), 1, "không có dòng tên cột")
    return tuple(rows)


def _split_value(raw: str) -> str:
    if "\t" in raw:
        value, _tail = raw.split("\t", 1)
        return value.strip()
    if ";" in raw:
        value, _tail = raw.split(";", 1)
        return value.strip()
    return raw.strip()


def _skipped_ini_line(stripped: str) -> bool:
    """Dòng trống, chú thích chấm phẩy, hoặc dòng # không có dấu bằng."""
    if stripped == "" or stripped.startswith(";"):
        return True
    return stripped.startswith("#") and "=" not in stripped


def _ini_entries(source: str, text: str) -> list[SourceKey]:
    section = ""
    found: list[SourceKey] = []
    for number, line in enumerate(text.splitlines(), start=1):
        if line.startswith("[") and "]" in line:
            section = line[1 : line.index("]")]
            continue
        stripped = line.strip()
        if _skipped_ini_line(stripped):
            continue
        if "=" not in line:
            raise _fail(source, number, "dòng không phải khoá")
        left, right = line.split("=", 1)
        found.append(SourceKey(source, section, left.strip(), _split_value(right), number))
    return found


def _bare_entries(source: str, text: str) -> list[SourceKey]:
    found: list[SourceKey] = []
    for number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if _skipped_ini_line(stripped):
            continue
        if stripped.startswith("["):
            raise _fail(source, number, "tệp này không có section")
        if "=" not in line:
            raise _fail(source, number, "dòng không phải khoá")
        left, right = line.split("=", 1)
        found.append(SourceKey(source, "", left.strip(), _split_value(right), number))
    return found


def _info_entries(source: str, text: str) -> list[SourceKey]:
    return [item for item in _ini_entries(source, text) if item.section == "info"]


def _merge_entries(source: str, text: str) -> list[SourceKey]:
    rows = [line for line in text.splitlines() if line.strip() != "" and not line.startswith("#")]
    if len(rows) < 3:
        raise _fail(source, 1, "bảng chữ cụt")
    found: list[SourceKey] = []
    for offset, line in enumerate(rows[2:], start=3):
        cells = line.split("\t")
        if len(cells) < 2 or cells[1] == "":
            raise _fail(source, offset, "thiếu cột KEY")
        found.append(SourceKey(source, "", cells[1], line, offset))
    return found


def _one_source(root: Path, relative: str, kind: str) -> list[SourceKey]:
    path = root.joinpath(*relative.split("/"))
    if not path.is_file():
        raise _fail(relative, 1, "không thấy tệp")
    text = _read_text(path)
    if kind == "ini":
        return _ini_entries(relative, text)
    if kind == "bare":
        return _bare_entries(relative, text)
    if kind == "info":
        return _info_entries(relative, text)
    if kind == "merge":
        return _merge_entries(relative, text)
    raise _fail(relative, 1, "không rõ kiểu tệp")


def _coverage(rows: tuple[HandRow, ...], found: list[SourceKey]) -> list[str]:
    known = {(row.source, row.section, row.key) for row in rows}
    present = {(item.source, item.section, item.key) for item in found}
    errors = []
    for item in found:
        if (item.source, item.section, item.key) not in known:
            errors.append(f"{item.source}:{item.line}: chưa có dòng cho [{item.section}] {item.key}")
    for row in rows:
        if (row.source, row.section, row.key) not in present:
            errors.append(f"legacy_rules.tsv:{row.line}: không thấy khoá {row.key}")
    return errors


def _decimal_text(value: str, location: str, line: int) -> str:
    """Giữ nguyên chữ số. Decimal chỉ để từ chối chuỗi không phải số hữu hạn."""
    try:
        number = Decimal(value)
    except InvalidOperation as exc:
        raise _fail(location, line, "không phải số") from exc
    if not number.is_finite():
        raise _fail(location, line, "không phải số hữu hạn")
    return value


def _scaled(value: str, places: int, location: str, line: int) -> str:
    try:
        number = Decimal(value)
    except InvalidOperation as exc:
        raise _fail(location, line, "không phải số") from exc
    quantum = Decimal(10) ** -places
    scaled = number / quantum
    if scaled != scaled.to_integral_value():
        raise _fail(location, line, "số thực không chia hết cho phần nghìn hoặc phần triệu")
    return str(int(scaled))


def _toml_literal(value: str, convert: str, location: str, line: int) -> str:
    if convert == "int":
        if not re.fullmatch(r"[+-]?\d+", value):
            raise _fail(location, line, "không phải số nguyên")
        return str(int(value))
    if convert == "bool":
        if value == "1":
            return "true"
        if value == "0":
            return "false"
        raise _fail(location, line, "bool chỉ nhận 0 hoặc 1")
    if convert == "text":
        escaped = value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if convert == "permille":
        return _scaled(value, 3, location, line)
    if convert == "ppm":
        return _scaled(value, 6, location, line)
    if convert == "decimal":
        return _decimal_text(value, location, line)
    if convert == "window":
        return _window(value, location, line)
    raise _fail(location, line, "thiếu convert")


def _window(value: str, location: str, line: int) -> str:
    """Hai mốc giờ cuối dòng MergeConfig, dạng [đóng, mở]."""
    cells = value.split("\t")
    if len(cells) < 5:
        raise _fail(location, line, "thiếu mốc đóng mở")
    closed = _toml_literal(cells[3].strip(), "int", location, line)
    opened = _toml_literal(cells[4].strip(), "int", location, line)
    return "[" + closed + ", " + opened + "]"


def _values_of(found: list[SourceKey]) -> dict[tuple[str, str, str], SourceKey]:
    return {(item.source, item.section, item.key): item for item in found}


def _grouped(rows: list[HandRow]) -> list[tuple[tuple[str, str, str], list[HandRow]]]:
    order: list[tuple[str, str, str]] = []
    groups: dict[tuple[str, str, str], list[HandRow]] = {}
    for row in rows:
        ident = (row.target_file, row.target_table, row.target_key)
        if ident not in groups:
            order.append(ident)
            groups[ident] = []
        groups[ident].append(row)
    return [(ident, groups[ident]) for ident in order]


def _ordered_indexes(group: list[HandRow]) -> list[HandRow]:
    ordered = sorted(group, key=lambda row: int(row.index))
    previous = int(ordered[0].index)
    for row in ordered[1:]:
        current = int(row.index)
        if current != previous + 1:
            raise _fail("legacy_rules.tsv", row.line, f"index khuyết, cần {previous + 1}")
        previous = current
    return ordered


def _one_literal(group: list[HandRow], values: dict[tuple[str, str, str], SourceKey]) -> tuple[str, str]:
    first = group[0]
    if first.index == "":
        if len(group) != 1:
            raise _fail("legacy_rules.tsv", first.line, "khoá lặp nhưng không có index")
        item = values[(first.source, first.section, first.key)]
        literal = _toml_literal(item.value, first.convert, first.source, item.line)
        return literal, first.note_vi
    ordered = _ordered_indexes(group)
    parts = []
    for row in ordered:
        item = values[(row.source, row.section, row.key)]
        parts.append(_toml_literal(item.value, row.convert, row.source, item.line))
    return "[" + ", ".join(parts) + "]", ordered[0].note_vi


def _literals(
    rows: list[HandRow], values: dict[tuple[str, str, str], SourceKey]
) -> list[tuple[tuple[str, str, str], str, str]]:
    built = []
    for ident, group in _grouped(rows):
        literal, note = _one_literal(group, values)
        literal, note = _deviated(ident, literal, note)
        built.append((ident, literal, note))
    return built


def _deviated(ident: tuple[str, str, str], literal: str, note: str) -> tuple[str, str]:
    swap = DEVIATIONS.get(ident)
    if swap is None:
        return literal, note
    return swap[0], f"{note} {swap[1]}"


def _render_file(filename: str, literals: list[tuple[tuple[str, str, str], str, str]]) -> str:
    title, intro = FILE_TEXT[filename]
    seen: list[str] = []
    buckets: dict[str, list[tuple[str, str, str]]] = {}
    for (file_name, table, key), literal, note in literals:
        if file_name != filename:
            continue
        if table not in buckets:
            seen.append(table)
            buckets[table] = []
        buckets[table].append((key, literal, note))
    sections = [
        (
            "Chung",
            None,
            [],
            [("schema", "1", "Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu")],
        )
    ]
    for table in seen:
        heading = TABLE_TITLE[(filename, table)]
        sections.append((heading, f"[{table}]", [], buckets[table]))
    return config_style.render(title, [intro], sections)


def _rule_files(literals: list[tuple[tuple[str, str, str], str, str]]) -> list[str]:
    seen: list[str] = []
    for (filename, _table, _key), _literal, _note in literals:
        if filename not in seen:
            seen.append(filename)
    return seen


def _check_titles(literals: list[tuple[tuple[str, str, str], str, str]]) -> None:
    for (filename, table, _key), _literal, _note in literals:
        if filename not in FILE_TEXT:
            raise _fail(filename, 1, "chưa có lời giới thiệu của tệp luật")
        if (filename, table) not in TABLE_TITLE:
            raise _fail(filename, 1, f"chưa có tiêu đề nhóm {table}")


def _write_rules(output_dir: Path, literals: list[tuple[tuple[str, str, str], str, str]]) -> list[str]:
    output_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for filename in _rule_files(literals):
        text = _render_file(filename, literals)
        (output_dir / filename).write_text(text, encoding="utf-8", newline="\n")
        written.append(filename)
    return written


def _toml_map(path: Path) -> dict[tuple[str, str], str]:
    current = ""
    found: dict[tuple[str, str], str] = {}
    for line in _read_text(path).splitlines():
        stripped = line.strip()
        if stripped.startswith("[["):
            continue
        if stripped.startswith("[") and stripped.endswith("]"):
            current = stripped[1:-1]
            continue
        if not config_style.KEY.match(line):
            continue
        key, value, _note = config_style.split_setting(line)
        found[(current, key)] = value
    return found


def _process_diffs(
    rows: list[HandRow], values: dict[tuple[str, str, str], SourceKey]
) -> list[str]:
    diffs = []
    config = PROJECT / "dev" / "server" / "config"
    cached: dict[str, dict[tuple[str, str], str]] = {}
    for (filename, table, key), literal, _note in _literals(rows, values):
        if filename not in cached:
            path = config / filename
            if not path.is_file():
                diffs.append(f"{filename}:1: không thấy tệp tiến trình")
                cached[filename] = {}
                continue
            cached[filename] = _toml_map(path)
        found = cached[filename].get((table, key))
        if found is None:
            diffs.append(f"{filename}:1: không thấy [{table}] {key}")
            continue
        if found != literal:
            diffs.append(f"{filename} [{table}] {key}: tệp {found}, ini {literal}")
    return diffs


def _counts(rows: tuple[HandRow, ...]) -> dict[str, int]:
    counts = {name: 0 for name in ("rule", "process_config", "dropped", "unknown")}
    for row in rows:
        counts[row.fate] = counts[row.fate] + 1
    return counts


def _summary(rows: tuple[HandRow, ...], diffs: list[str], written: list[str]) -> list[str]:
    counts = _counts(rows)
    lines = [
        f"luật: {counts['rule']}",
        f"tiến trình: {counts['process_config']}",
        f"bỏ: {counts['dropped']}",
        f"chưa rõ: {counts['unknown']}",
        f"lệch tiến trình: {len(diffs)}",
    ]
    lines.extend(diffs)
    if written:
        lines.append("đã ghi: " + ", ".join(written))
    else:
        lines.append("đã ghi: 0")
    return lines


def export_rules(
    legacy_root: Path,
    output_dir: Path,
    *,
    check_only: bool = False,
    rules_path: Path | None = None,
    sources: tuple[tuple[str, str], ...] | None = None,
) -> tuple[list[str], list[str]]:
    """Đọc bảng luật và nguồn. Có lỗi chuyển đổi thì không ghi."""
    hand = _hand_rows(_default_rules() if rules_path is None else rules_path)
    found: list[SourceKey] = []
    catalog = SOURCES if sources is None else sources
    for relative, kind in catalog:
        found.extend(_one_source(legacy_root, relative, kind))
    errors = _coverage(hand, found)
    if errors:
        return errors, []
    values = _values_of(found)
    rules = [row for row in hand if row.fate == "rule"]
    process = [row for row in hand if row.fate == "process_config"]
    try:
        literals = _literals(rules, values)
        _check_titles(literals)
        diffs = _process_diffs(process, values)
        written: list[str] = []
        if not check_only:
            written = _write_rules(output_dir, literals)
    except RulesError as exc:
        return [str(exc)], []
    return [], _summary(hand, diffs, written)


def _arguments(args: list[str]) -> tuple[Path, Path, bool]:
    check_only = False
    positionals: list[str] = []
    for arg in args:
        if arg == "--check":
            check_only = True
            continue
        if arg.startswith("-"):
            raise _fail("import_rules.py", 1, f"không rõ đối số: {arg}")
        positionals.append(arg)
    if len(positionals) != 2:
        raise _fail("import_rules.py", 1, "cần thư mục tlbb và thư mục rules")
    return Path(positionals[0]), Path(positionals[1]), check_only


def main(argv: list[str] | None = None) -> int:
    """Điểm vào dòng lệnh. In lỗi hoặc bảng tổng kết."""
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    try:
        legacy, output, check_only = _arguments(args)
        errors, summary = export_rules(legacy, output, check_only=check_only)
    except RulesError as exc:
        print(exc)
        return 1
    if errors:
        for error in errors:
            print(error)
        return 1
    for line in summary:
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
