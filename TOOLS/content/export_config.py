# Xuất các bảng Config nhị phân (DBC) của client 2026 mà client tự viết cần đọc lúc chạy thành bảng
# TSV UTF-8 trong <dữ liệu client>/Table: bảng nhiệm vụ nhận được, loại nhiệm vụ, và các bảng của
# sách võ công. Mỗi bảng giữ MỌI cột của bảng gốc theo đúng thứ tự (cột chưa rõ nghĩa mang tên
# column_<số>), thêm sau cùng các cột nối sẵn từ bảng khác mà client gốc tra lúc chạy (tên cảnh).
# Một thư mục bảng cùng hình dạng (bảng lên cấp của kỹ năng sống) gộp thành một tệp, cột đầu là tên
# tệp gốc của từng dòng.
# Nội dung không đổi một byte nào: số nguyên in thập phân, số thực in dạng thập phân ngắn nhất đọc lại
# ra đúng mẫu bit float32, chuỗi GBK đổi sang UTF-8 (đổi ngược lại phải ra đúng các byte gốc).
# Ô không viết được như thế là lỗi của bảng, nêu bảng, dòng và cột, và bảng đó không được ghi: số thực
# NaN hay vô cực, chuỗi có tab hay xuống dòng, dòng mở đầu bằng # hay dòng rỗng (bộ đọc TSV bỏ qua).
# Sau khi ghi, công cụ đọc lại từng tệp và so từng ô với bảng gốc; lệch một ô là lỗi.
# Nghĩa của cột đọc từ mã máy Game.exe 2026: docs/NHIEM-VU-VO-CONG-2026.md.
# Chạy ở gốc dự án:
#   python -B TOOLS/content/export_config.py <_raw> <dữ liệu client>            ghi rồi kiểm
#   python -B TOOLS/content/export_config.py <_raw> <dữ liệu client> --check    chỉ kiểm, không ghi
# --check còn đòi tệp đang có trùng từng byte với tệp sẽ sinh (bảng cũ hơn công cụ hay hơn kho gốc
# là lỗi). Tệp không đổi nội dung thì không ghi lại. Mã thoát: 0 khi mọi bảng khớp, 1 khi có bảng
# hỏng hay lệch, 2 khi sai cách dùng. Một bảng hỏng (kể cả vì lỗi đĩa: không đọc, không ghi được) in
# một dòng LỖI và không cản các bảng đứng sau.
from __future__ import annotations

import argparse
import contextlib
import hashlib
import math
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

import dbc

KINDS = {dbc.INT: "int", dbc.FLOAT: "float", dbc.STRING: "text"}
NOTE = "Sinh bằng TOOLS/content/export_config.py từ Config của client 2026; sửa tay sẽ mất ở lượt sau"
# Số chữ số có nghĩa đủ để mọi float32 đọc lại ra đúng mẫu bit.
FLOAT_DIGITS = 9


class ExportError(Exception):
    """Bảng gốc hỏng, ô không viết được thành TSV, tệp đích không ghi hay đọc lại được, hay tệp đã
    ghi lệch bảng gốc."""


# Một cột nối sẵn: giá trị là ô chuỗi value của dòng trong bảng other có cột 0 bằng ô key của dòng
# đang xuất; không có dòng đó thì rỗng (client gốc cũng để chuỗi rỗng).
@dataclass(frozen=True)
class Join:
    name: str
    key: int
    other: str
    value: int


# Một bảng xuất: tệp gốc trong Config, tên tệp đích trong Table, tên của các cột đã rõ nghĩa (chỉ số
# cột sang tên) và các cột nối sẵn.
@dataclass(frozen=True)
class Spec:
    source: str
    target: str
    names: dict[int, str]
    joins: tuple[Join, ...] = ()


# Một bảng gộp: mọi tệp DBC nằm thẳng trong thư mục con folder của Config (trừ các tên trong skip),
# cùng số cột và kiểu cột, nối thành một tệp đích theo thứ tự tên tệp. Cột đầu của tệp đích (tên key)
# mang tên tệp gốc của dòng, đúng như bảng khác gọi nó; các cột sau là mọi cột của bảng gốc.
@dataclass(frozen=True)
class Bundle:
    folder: str
    target: str
    key: str
    names: dict[int, str]
    skip: tuple[str, ...] = ()


# SkillTemplate_V1: 31 cột id dòng số liệu theo bậc tâm pháp, từ cột 48 (Game.exe đọc def + 0xe4 + 4k).
SKILL_DATA_COLUMN = 48
SKILL_DATA_TIERS = 31
# XinFaStudySpend_V1: 121 cặp (tiền, kinh nghiệm) sau hai cột đầu, tâm pháp id 0..120.
INNER_ART_COSTS = 121

SPECS = (
    Spec(
        source="MissionKind.txt",
        target="mission_kinds.tsv",
        names={0: "id", 1: "name"},
    ),
    Spec(
        source="MissionOutline.txt",
        target="mission_outline.tsv",
        names={
            0: "id", 1: "mission", 2: "kind", 3: "sect", 6: "level", 7: "min_level", 8: "max_level",
            9: "scene", 10: "npc", 12: "name", 13: "requires_1", 14: "requires_2", 15: "requires_3",
            16: "x", 17: "z", 18: "hidden", 19: "hidden_original", 20: "name_original",
            21: "hidden_light", 22: "name_light", 23: "x_text", 24: "z_text",
        },
        joins=(Join(name="scene_name", key=9, other="SceneDefineEx.txt", value=1),),
    ),
    # Chữ theo dõi nhiệm vụ (s_pMissionTrackDBC của Game.exe, đọc ở GetLuaMissionTrackInfo 0x1402d2670): id script,
    # chữ gốc (cột 1, +8 của bản ghi) và chữ dịch (cột 2, +0x10; client gốc dùng khi bật chế độ dịch và cột không rỗng).
    Spec(
        source="MissionTrack.txt",
        target="mission_track.tsv",
        names={0: "id", 1: "text", 2: "text_translated"},
    ),
    # Sách võ công. Tên tệp đích trùng tên bảng tương ứng của máy chủ (docs/SERVER-TEP-CAU-HINH.md).
    # Kỹ năng: cột 48..78 là id dòng skill_levels.tsv theo bậc tâm pháp (bậc = cấp tâm pháp / 10);
    # cột 11 cộng vào cấp tâm pháp trước khi tính bậc; cột 101 (mới ở 2026, nghĩa chưa rõ) bằng 2 thì
    # nhân vật nào cũng coi như đã học.
    Spec(
        source="SkillTemplate_V1.txt",
        target="skills.tsv",
        names={
            0: "id", 1: "sect", 2: "name", 3: "icon", 4: "inner_art_level", 5: "move_type",
            10: "inner_art", 11: "level_offset", 20: "user_class", 21: "passivity", 30: "must_learn",
            79: "explain",
        } | {SKILL_DATA_COLUMN + tier: f"data_{tier}" for tier in range(SKILL_DATA_TIERS)},
    ),
    Spec(
        source="SkillData_V1.txt",
        target="skill_levels.tsv",
        names={0: "id", 2: "description"},
    ),
    Spec(
        source="XinFa_V1.txt",
        target="inner_arts.tsv",
        names={0: "id", 1: "sect", 2: "name", 3: "explain", 4: "icon", 8: "need_level"},
    ),
    # Tiền và kinh nghiệm lên từng cấp tâm pháp: tâm pháp id k đọc cột money_k và exp_k của dòng có
    # level bằng cấp muốn lên.
    Spec(
        source="XinFaStudySpend_V1.txt",
        target="inner_art_learn_costs.tsv",
        names={0: "id", 1: "level"}
        | {2 + 2 * art: f"money_{art}" for art in range(INNER_ART_COSTS)}
        | {3 + 2 * art: f"exp_{art}" for art in range(INNER_ART_COSTS)},
    ),
    Spec(
        source="Ability.txt",
        target="life_skills.tsv",
        names={
            0: "id", 1: "name", 3: "max_level", 4: "level_table", 11: "icon", 13: "explain",
            14: "popup", 16: "consume",
        },
    ),
    # Số liệu mà mô tả của bốn trận pháp điền ở từng cấp (Player:GetStrZhenfaSkill của Game.exe): trận
    # 1 lấy cột 1 và 2, trận 2 cột 3 và 4, trận 3 cột 5 và 6, trận 4 cột 7 tới 10 (từ điển chỉ dùng
    # ba cột đầu của trận 4; nghĩa cột 10 chưa rõ).
    Spec(
        source="ZhenFaStr.txt",
        target="formation_levels.tsv",
        names={
            0: "level", 1: "life_low", 2: "life_high", 3: "pierce_attack_low", 4: "pierce_attack_high",
            5: "pierce_defence_low", 6: "pierce_defence_high", 7: "hit_low", 8: "hit_high", 9: "critical",
        },
    ),
    # Bộ đồ tân thủ của màn tạo nhân vật (docs/TAO-NHAN-VAT-2026.md). Ba cột sau tên là id hình
    # trang phục (ItemVisualChar) của áo, giày, bao tay: tên lưới của các dòng đó là "...衣服",
    # "...靴子", "...护腕", trùng ba lưới gắn sẵn trong mẫu 女新手套装<n>.obj và 男新手套装<n>.obj
    # của Model/all.obj. Chân dung, mặt và tóc của màn tạo nằm ở portraits.tsv (collect_ui.py),
    # faces.tsv và hairs.tsv (export_look.py).
    Spec(
        source="NewRoleEquipset.txt",
        target="newbie_outfits.tsv",
        names={0: "id", 1: "name", 2: "body", 3: "foot", 4: "arm"},
    ),
    # Vật phẩm, nguồn chữ của khoá table/<bảng>/<id>/<cột> trong assets/i18n (build_i18n.py): tên,
    # mô tả và tên loại hiện ở ô tooltip. Vật phẩm thường (CommonItem), trang bị (EquipBase), bảo
    # thạch (GemInfo), vật phẩm hoạt động (CampaignItem); các cột khác giữ tên column_<k>.
    Spec(
        source="CommonItem.txt",
        target="items.tsv",
        names={0: "id", 5: "icon", 6: "name", 7: "description", 19: "type_name"},
    ),
    Spec(
        source="EquipBase.txt",
        target="equips.tsv",
        names={0: "id", 10: "name", 13: "description", 18: "icon", 19: "type_name"},
    ),
    Spec(
        source="GemInfo.txt",
        target="gems.tsv",
        names={0: "id", 5: "icon", 7: "name", 8: "description"},
    ),
    Spec(
        source="CampaignItem.txt",
        target="campaign_items.tsv",
        names={0: "id", 2: "icon", 3: "name", 4: "description", 6: "type_name"},
    ),
)

# Bảng lên cấp của kỹ năng sống: ô level_table của life_skills.tsv là tên một tệp trong thư mục này;
# dòng tra theo cấp (cột 0), cột 6 là trần độ thuần thục nhân 100. XinFaStudySpend_V1.txt nằm lạc ở
# đây là bản cũ (130 cột) của bảng cùng tên ở thư mục cha, client gốc không mở nó theo đường này.
BUNDLES = (
    Bundle(
        folder="AbilityLevelUp",
        target="life_skill_levels.tsv",
        key="table",
        names={0: "level", 1: "name", 6: "limit_exp"},
        skip=("XinFaStudySpend_V1.txt",),
    ),
)


def column_names(spec: Spec, columns: int) -> list[str]:
    """Tên cột của tệp đích: tên đã đặt, cột chưa rõ nghĩa là column_<số>, rồi các cột nối."""
    stray = [index for index in spec.names if not 0 <= index < columns]
    if stray:
        raise ExportError(f"{spec.source}: không có cột {stray[0]} (bảng có {columns} cột)")
    names = [spec.names.get(index, f"column_{index}") for index in range(columns)]
    names += [join.name for join in spec.joins]
    if len(set(names)) != len(names):
        raise ExportError(f"{spec.source}: tên cột lặp trong {names}")
    return names


def float_text(bits: int) -> str:
    """Dạng thập phân ngắn nhất mà đọc lại thành float32 ra đúng mẫu bit; NaN và vô cực thì từ chối
    (không có dạng thập phân, và bộ đọc của client không nhận số không hữu hạn)."""
    value = struct.unpack("<f", struct.pack("<I", bits))[0]
    if not math.isfinite(value):
        kind = "NaN" if math.isnan(value) else "vô cực"
        raise ExportError(f"số thực {kind} (mẫu bit {bits:08x}) không viết được thành thập phân")
    for digits in range(1, FLOAT_DIGITS + 1):
        text = f"{value:.{digits}g}"
        if reads_back(text, bits):
            return text
    raise ExportError(f"mẫu bit {bits:08x} không đọc lại được từ {FLOAT_DIGITS} chữ số")


def float_bits(text: str) -> int:
    """Mẫu bit float32 của một số thập phân, làm tròn như bộ đọc của client (double rồi về float)."""
    try:
        return struct.unpack("<I", struct.pack("<f", float(text)))[0]
    except (ValueError, OverflowError) as error:
        raise ExportError(f"\"{text}\" không phải số thực float32") from error


def reads_back(text: str, bits: int) -> bool:
    """text đọc lại thành float32 có ra đúng mẫu bit không. Chữ không phải số là không; số vượt miền
    float32 cũng là không (một số sát FLT_MAX in ít chữ số thì làm tròn lên quá miền)."""
    try:
        return float_bits(text) == bits
    except ExportError:
        return False


def raw_string(table: dbc.Dbc, row: int, column: int) -> bytes:
    """Các byte GBK của một ô chuỗi, tới byte 0 đầu tiên."""
    offset = table.raw(row, column)
    if offset >= len(table.strings):
        raise ExportError(f"{table.name}: dòng {row} cột {column}: offset chuỗi {offset} ngoài khối")
    return table.strings[offset:table.strings.index(b"\0", offset)]


def string_text(table: dbc.Dbc, row: int, column: int) -> str:
    """Ô chuỗi đổi sang UTF-8; byte không phải GBK, tab hay xuống dòng trong ô là lỗi."""
    raw = raw_string(table, row, column)
    where = f"{table.name}: dòng {row} cột {column}"
    try:
        text = raw.decode("gb18030")
    except UnicodeDecodeError as error:
        raise ExportError(f"{where}: chuỗi không phải GBK ({raw[:16].hex()})") from error
    if text.encode("gb18030") != raw:
        raise ExportError(f"{where}: chuỗi không đổi ngược lại được đúng byte gốc")
    if any(mark in text for mark in "\t\n\r"):
        raise ExportError(f"{where}: chuỗi có tab hay xuống dòng, không viết được thành một ô TSV")
    return text


def cell_text(table: dbc.Dbc, row: int, column: int) -> str:
    kind = table.types[column]
    if kind == dbc.INT:
        return str(table.integer(row, column))
    if kind == dbc.FLOAT:
        try:
            return float_text(table.raw(row, column))
        except ExportError as error:
            raise ExportError(f"{table.name}: dòng {row} cột {column}: {error}") from error
    return string_text(table, row, column)


def index_first_column(table: dbc.Dbc) -> dict[int, int]:
    """Cột 0 (số nguyên) sang số dòng; khoá lặp thì giữ dòng gặp trước."""
    if table.types[0] != dbc.INT:
        raise ExportError(f"{table.name}: cột 0 không phải số nguyên, không tra theo khoá được")
    rows: dict[int, int] = {}
    for row in range(table.rows):
        rows.setdefault(table.integer(row, 0), row)
    return rows


@dataclass(frozen=True)
class Loaded:
    table: dbc.Dbc
    digest: str


class Source:
    """Thư mục Config của kho gốc; mỗi bảng chỉ đọc một lần."""

    def __init__(self, raw_root: Path) -> None:
        self.config = raw_root / "Config"
        # Dòng đầu của tệp sinh: công cụ nào sinh, từ đâu.
        self.note = NOTE
        self.cache: dict[str, Loaded] = {}
        self.indexes: dict[str, dict[int, int]] = {}

    def load(self, name: str) -> Loaded:
        if name in self.cache:
            return self.cache[name]
        path = self.config / name
        try:
            data = path.read_bytes()
            table = dbc.read(str(path), name)
        except (OSError, dbc.DbcError) as error:
            raise ExportError(f"{name}: không đọc được bảng gốc: {error}") from error
        loaded = Loaded(table=table, digest=hashlib.sha256(data).hexdigest())
        self.cache[name] = loaded
        return loaded

    def joined(self, join: Join, table: dbc.Dbc, row: int) -> str:
        other = self.load(join.other).table
        if join.other not in self.indexes:
            self.indexes[join.other] = index_first_column(other)
        if not (0 <= join.key < table.columns and 0 <= join.value < other.columns):
            key = f"khoá cột {join.key}, bảng có {table.columns} cột"
            value = f"giá trị cột {join.value}, {join.other} có {other.columns} cột"
            raise ExportError(f"{table.name}: cột nối {join.name} trỏ ngoài bảng ({key}; {value})")
        if table.types[join.key] != dbc.INT or other.types[join.value] != dbc.STRING:
            raise ExportError(f"{table.name}: cột nối {join.name} sai kiểu (khoá phải nguyên, giá trị phải chuỗi)")
        found = self.indexes[join.other].get(table.integer(row, join.key))
        return "" if found is None else string_text(other, found, join.value)


def row_cells(source: Source, spec: Spec, table: dbc.Dbc, row: int) -> list[str]:
    cells = [cell_text(table, row, column) for column in range(table.columns)]
    cells += [source.joined(join, table, row) for join in spec.joins]
    if cells[0].startswith("#"):
        raise ExportError(f"{table.name}: dòng {row} mở đầu bằng #, bộ đọc TSV sẽ coi là chú thích")
    if cells == [""]:
        raise ExportError(f"{table.name}: dòng {row} là dòng rỗng (một cột, ô chuỗi rỗng), bộ đọc TSV sẽ bỏ qua")
    return cells


def table_text(source: Source, spec: Spec) -> str:
    """Nội dung tệp TSV của một bảng."""
    loaded = source.load(spec.source)
    table = loaded.table
    names = column_names(spec, table.columns)
    kinds = [KINDS[kind] for kind in table.types] + ["text"] * len(spec.joins)
    lines = [
        f"# {source.note}",
        f"# Nguồn: Config/{spec.source}, {table.rows} dòng x {table.columns} cột, sha256 {loaded.digest}",
        "# Kiểu: " + "\t".join(kinds),
        "\t".join(names),
    ]
    lines += ["\t".join(row_cells(source, spec, table, row)) for row in range(table.rows)]
    return "\n".join(lines) + "\n"


def bundle_files(source: Source, bundle: Bundle) -> list[str]:
    """Tên các tệp của một bảng gộp, theo thứ tự tên; thư mục thiếu, không liệt kê được, rỗng hay
    skip nêu tệp lạ là lỗi."""
    folder = source.config / bundle.folder
    if not folder.is_dir():
        raise ExportError(f"{bundle.folder}: không thấy thư mục {folder}")
    try:
        present = sorted(path.name for path in folder.iterdir() if path.is_file())
    except OSError as error:
        raise ExportError(f"{bundle.folder}: không đọc được thư mục {folder}: {error}") from error
    stray = [name for name in bundle.skip if name not in present]
    if stray:
        raise ExportError(f"{bundle.folder}: skip nêu tệp không có: {stray[0]}")
    files = [name for name in present if name not in bundle.skip]
    if not files:
        raise ExportError(f"{bundle.folder}: không có bảng nào")
    return files


def bundle_tables(source: Source, bundle: Bundle) -> list[tuple[str, Loaded]]:
    """(tên tệp, bảng) của một bảng gộp; bảng lệch số cột hay kiểu cột với bảng đầu là lỗi."""
    loaded = [(name, source.load(f"{bundle.folder}/{name}")) for name in bundle_files(source, bundle)]
    types = loaded[0][1].table.types
    for name, item in loaded:
        if item.table.types != types:
            raise ExportError(f"{bundle.folder}/{name}: kiểu cột khác {bundle.folder}/{loaded[0][0]}")
    return loaded


def bundle_names(bundle: Bundle, columns: int) -> list[str]:
    """Tên cột của tệp đích một bảng gộp: cột tên tệp rồi các cột của bảng gốc."""
    shown = Spec(source=bundle.folder, target=bundle.target, names=bundle.names)
    names = [bundle.key] + column_names(shown, columns)
    if bundle.key in names[1:]:
        raise ExportError(f"{bundle.folder}: tên cột lặp trong {names}")
    return names


def bundle_text(source: Source, bundle: Bundle) -> str:
    """Nội dung tệp TSV của một bảng gộp."""
    loaded = bundle_tables(source, bundle)
    first = loaded[0][1].table
    names = bundle_names(bundle, first.columns)
    kinds = ["text"] + [KINDS[kind] for kind in first.types]
    total = sum(item.table.rows for _, item in loaded)
    digest = hashlib.sha256("".join(item.digest for _, item in loaded).encode("ascii")).hexdigest()
    lines = [
        f"# {source.note}",
        f"# Nguồn: Config/{bundle.folder}, {len(loaded)} tệp, {total} dòng x {first.columns} cột, sha256 {digest}",
        "# Kiểu: " + "\t".join(kinds),
        "\t".join(names),
    ]
    for name, item in loaded:
        if name.startswith("#") or any(mark in name for mark in "\t\n\r"):
            raise ExportError(f"{bundle.folder}/{name}: tên tệp không viết được thành một ô TSV")
        table = item.table
        for row in range(table.rows):
            lines.append("\t".join([name] + [cell_text(table, row, column) for column in range(table.columns)]))
    return "\n".join(lines) + "\n"


def verify_bundle(source: Source, bundle: Bundle, text: str) -> int:
    """So từng ô của tệp TSV một bảng gộp với các bảng gốc; trả số ô đã so."""
    loaded = bundle_tables(source, bundle)
    rows = data_rows(text)
    total = sum(item.table.rows for _, item in loaded)
    if len(rows) != total:
        raise ExportError(f"{bundle.target}: {len(rows)} dòng, các bảng gốc có {total}")
    width = loaded[0][1].table.columns + 1
    at = 0
    for name, item in loaded:
        table = item.table
        for row in range(table.rows):
            cells = rows[at]
            where = f"{bundle.target}: dòng dữ liệu {at}"
            at += 1
            if len(cells) != width:
                raise ExportError(f"{where} có {len(cells)} ô, cần {width}")
            if cells[0] != name:
                raise ExportError(f"{where} mang tên bảng \"{cells[0]}\", cần \"{name}\"")
            for column in range(table.columns):
                if not same_cell(table, row, column, cells[column + 1]):
                    raise ExportError(f"{where} cột {column} lệch {bundle.folder}/{name}: \"{cells[column + 1]}\"")
    return total * width


def data_rows(text: str) -> list[list[str]]:
    """Các dòng dữ liệu của một tệp TSV theo luật của bộ đọc C++: bỏ dòng rỗng và dòng #, dòng đầu
    còn lại là tên cột."""
    kept = [line for line in text.split("\n") if line and not line.startswith("#")]
    return [line.split("\t") for line in kept[1:]]


def same_cell(table: dbc.Dbc, row: int, column: int, cell: str) -> bool:
    kind = table.types[column]
    if kind == dbc.INT:
        return cell == str(table.integer(row, column))
    if kind == dbc.FLOAT:
        return reads_back(cell, table.raw(row, column))
    return cell.encode("gb18030") == raw_string(table, row, column)


def verify(source: Source, spec: Spec, text: str) -> int:
    """So từng ô của tệp TSV với bảng gốc; trả số ô đã so. Lệch thì ném ExportError nêu ô đầu tiên."""
    table = source.load(spec.source).table
    rows = data_rows(text)
    if len(rows) != table.rows:
        raise ExportError(f"{spec.target}: {len(rows)} dòng, bảng gốc có {table.rows}")
    width = table.columns + len(spec.joins)
    for row, cells in enumerate(rows):
        if len(cells) != width:
            raise ExportError(f"{spec.target}: dòng dữ liệu {row} có {len(cells)} ô, cần {width}")
        for column in range(table.columns):
            if not same_cell(table, row, column, cells[column]):
                raise ExportError(f"{spec.target}: dòng dữ liệu {row} cột {column} lệch bảng gốc: \"{cells[column]}\"")
        for offset, join in enumerate(spec.joins):
            if cells[table.columns + offset] != source.joined(join, table, row):
                raise ExportError(f"{spec.target}: dòng dữ liệu {row} cột nối {join.name} lệch bảng gốc")
    return table.rows * width


def write_changed(path: Path, content: bytes) -> bool:
    """Ghi qua tệp tạm rồi đổi tên; trả False khi tệp đã mang đúng nội dung đó. Ghi hay đổi tên hỏng
    thì dọn tệp tạm rồi để OSError đi tiếp cho bên gọi báo."""
    if path.is_file() and path.read_bytes() == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    spare = path.with_name(path.name + ".tmp")
    try:
        spare.write_bytes(content)
        spare.replace(path)
    except OSError:
        with contextlib.suppress(OSError):
            spare.unlink(missing_ok=True)
        raise
    return True


def export_one(source: Source, spec: Spec | Bundle, folder: Path, is_check: bool) -> str:
    """Xuất (hoặc chỉ kiểm) một bảng hay một bảng gộp; trả một dòng báo cáo. Tệp đích không ghi hay
    không đọc lại được (lỗi đĩa, hay đọc lại không còn là UTF-8) cũng là ExportError của bảng đó."""
    is_bundle = isinstance(spec, Bundle)
    origin = spec.folder if is_bundle else spec.source
    wanted = (bundle_text(source, spec) if is_bundle else table_text(source, spec)).encode("utf-8")
    path = folder / spec.target
    is_written = False
    try:
        if is_check:
            if not path.is_file():
                raise ExportError(f"{spec.target}: chưa có trong {folder}")
            if path.read_bytes() != wanted:
                raise ExportError(f"{spec.target}: khác tệp sẽ sinh từ kho gốc; chạy lại không có --check")
        else:
            is_written = write_changed(path, wanted)
        written = path.read_bytes().decode("utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise ExportError(f"{spec.target}: không ghi hay đọc lại được {path}: {error}") from error
    cells = verify_bundle(source, spec, written) if is_bundle else verify(source, spec, written)
    state = "ghi mới" if is_written else "giữ nguyên"
    return f"{spec.target}: {cells} ô khớp bảng gốc {origin} ({state})"


def run(raw_root: Path, data_root: Path, is_check: bool, specs: tuple[Spec | Bundle, ...] = SPECS + BUNDLES) -> int:
    source = Source(raw_root)
    folder = data_root / "Table"
    failures = 0
    for spec in specs:
        try:
            print(export_one(source, spec, folder, is_check))
        except ExportError as error:
            failures += 1
            print(f"LỖI {error}", file=sys.stderr)
    return 1 if failures else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Xuất bảng Config của client 2026 thành Table/*.tsv cho client.")
    parser.add_argument("raw", type=Path, help="kho gốc đã giải gói (_raw)")
    parser.add_argument("data", type=Path, help="thư mục dữ liệu client (CLIENT/data)")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm tệp đang có, không ghi")
    args = parser.parse_args(argv)
    if not (args.raw / "Config").is_dir():
        print(f"không thấy {args.raw / 'Config'}", file=sys.stderr)
        return 2
    return run(args.raw, args.data, args.check)


if __name__ == "__main__":
    sys.exit(main())
