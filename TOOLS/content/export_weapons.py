# Xuất bảng vũ khí cho client từ Config nhị phân của client 2026 (_raw) và cây GLB (_glb), ghi vào
# <dữ liệu client>/Table/: weapons.tsv, weapon_items.tsv, objects.tsv, locators.tsv.
# Logic port từ TLBB Dev tools/export/weapons.cpp @e0d89a6 (đọc lại bằng Python) và
# CObject_PlayerOther::EquipItem_BodyLocator của ref 2008; cột của client 2026 đối chiếu bằng mã máy
# FUN_140604720 (Obj_PlayerNPC.cpp, Game.exe 2026) qua Ghidra: byte = 8 x cột của ItemVisualLocator.
# Khác gốc (TLBB Dev):
# - 2026 có thêm sáu khe ngoài hai tay: KFSObj (cột 9, võ hồn), FootWeaponObj (13, vòng chân/toy),
#   NewBackWeaponObj (17), WaistWeaponObj1 (21), WaistWeaponObj2 (25); cột 19, 23, 27 là cờ đá quý
#   của ba khe sau. Khe nào cũng là một mẫu .obj gắn vào Slot cùng tên của locator trong mẫu nhân vật.
# - Cột material (1 cho tay phải, 6 cho tay trái) rỗng ở cả 3331 mẫu nên bảng không có cột material.
# - Loại vũ khí lấy từ nType (EquipBase cột 3) của vật phẩm khe 0, như GetWeaponType: 0 đao (blade),
#   1 thương, 2 kiếm đơn, 3 song, 4 quạt, 5 vòng; 30 tới 35 quy về 0 tới 5 (cùng nhóm theo tên vật
#   phẩm, đo ở TLBB Dev); giá trị khác (12 ...) là none.
# - Loại vũ khí thuộc VẬT PHẨM chứ không thuộc hình: hình 410 do vật phẩm đao, kiếm, quạt, vòng dùng chung
#   (ở TLBB Dev chỉ 2 hình bị hai loại dùng, ở 2026 là nhiều hình), nên loại nằm ở weapon_items.tsv.
# Quyết định:
# - Tên mẫu trong all.obj không phân biệt hoa thường theo ASCII (ItemVisualLocator ghi "Dweapon_...",
#   all.obj ghi "dweapon_..."), như tra tài nguyên của Ogre; bảng ghi tên đúng như all.obj.
# - Hình có mẫu .obj không có trong all.obj bị bỏ và nêu trong báo cáo (mẫu tạo lỗi nạp khi mặc).
# - Locator có số không hữu hạn ("1.#QNAN" ở 主角火把.obj/武器特效点: góc quay NaN) bị bỏ và nêu trong báo cáo;
#   client gốc đặt nút với hướng NaN, tức một điểm hiệu ứng hỏng, không có gì để chép.
# - locators.tsv giữ MỌI locator của mẫu nhân vật (hai giới) và của mẫu vũ khí: điểm hiệu ứng
#   ("武器特效点"...) dùng cho hiệu ứng đồ; số giữ nguyên chữ của all.obj. Góc quay là trục và góc
#   (qx qy qz = trục, qw = góc radian), chưa thành quaternion.
# - weapon_effects.tsv: hiệu ứng đồ (đá quý gắn vũ khí). Mã máy FUN_140604720 (EquipItem_BodyLocator của 2026): đá quý gắn
#   vũ khí (GemInfo, id 117) cho màu (cột 75, chuỗi RRGGBBAA hex) và chỉ số hiệu ứng nEffectIndex (cột 77, từ 1); hiệu ứng
#   là ô cột 29 + chỉ số - 1 của ItemVisualLocator (34 cột, 29 tới 62), gắn vào mẫu vũ khí tay phải, tay trái và
#   (khi cờ cột 19, 23, 27 là 1) lưng, hông 1, hông 2. Chuỗi hiệu ứng là các ô cách nhau bằng ';' đúng thứ tự cột.
#   Cặp màu - hiệu ứng áp cho client ở look::weapon_effect; bảng giữ nguyên dữ liệu, kể cả chỉ số quá 34 (hơn 100 đá quý
#   khác) mà mã máy sẽ đọc ngoài hàng.
# Cách dùng: python export_weapons.py <_raw> <_glb> <thư mục dữ liệu client>
# Mã thoát 1 khi có lỗi dữ liệu.

from __future__ import annotations

import math
import os
import sys

import dbc
from export_look import ExportError, ObjectBook, Sources, write_table

# EquipBase: nType, điểm mang (0 là vũ khí), id hình.
EQUIP_TYPE, EQUIP_POINT, EQUIP_VISUAL = 3, 5, 6
WEAPON_POINT = 0
# ItemVisualLocator: cột hiệu ứng đá quý và cờ đá quý của ba khe sau (byte / 8 của mã máy FUN_140604720).
EFFECT_FIRST, EFFECT_COUNT = 29, 34
GEM_FLAGS = (19, 23, 27)
# GemInfo: id vật phẩm, màu (chuỗi RRGGBBAA hay -1) và chỉ số hiệu ứng.
GEM_COLOUR, GEM_EFFECT = 75, 77
# ItemVisualLocator: cột .obj của từng khe, theo mã máy FUN_140604720 (byte / 8).
VISUAL_SLOTS = (("right", 2, "RightWeaponObj"), ("left", 5, "LeftWeaponObj"), ("kfs", 9, "KFSObj"),
                ("foot", 13, "FootWeaponObj"), ("back", 17, "NewBackWeaponObj"),
                ("waist1", 21, "WaistWeaponObj1"), ("waist2", 25, "WaistWeaponObj2"))
# Tên loại như cột weapon của anim_sets, theo nType 0 tới 5.
CLASSES = ("blade", "spear", "short", "dual_short", "fan", "ring")
MAX_SHORT = 65535
# Mẫu nhân vật mang các slot vũ khí: lấy từ player_bodies.tsv của cùng lượt xuất.
BODY_TABLE = "player_bodies.tsv"


def fold(name: str) -> str:
    """Tên mẫu để so: chỉ chữ ASCII hạ thường, mọi ký tự khác giữ nguyên."""
    return "".join(char.lower() if char.isascii() else char for char in name)


def class_of(kind: int) -> str:
    """Loại vũ khí của nType; 30 tới 35 cùng nhóm với 0 tới 5, giá trị khác là none."""
    base = kind - 30 if 30 <= kind <= 35 else kind
    return CLASSES[base] if 0 <= base < len(CLASSES) else "none"


def read_items(sources: Sources) -> list:
    """(vật phẩm, hình, loại) của mọi vật phẩm khe 0, theo thứ tự tệp."""
    table = sources.table("EquipBase.txt")
    items = []
    for row in range(table.rows):
        if table.integer(row, EQUIP_POINT) == WEAPON_POINT:
            items.append((table.integer(row, 0), table.integer(row, EQUIP_VISUAL),
                          class_of(table.integer(row, EQUIP_TYPE))))
    return items


class Templates:
    """Mẫu của all.obj tra theo tên không phân biệt hoa thường ASCII. Tên lặp thì mẫu đầu thắng: client gốc
    nạp bằng std::map::insert (mLogicModelTemplateMap) nên mẫu sau không đè mẫu trước."""

    def __init__(self, book: ObjectBook):
        self.by_fold: dict = {}
        for name, items in book.by_name.items():
            self.by_fold.setdefault(fold(name), []).extend(items)

    def find(self, name: str):
        found = self.by_fold.get(fold(name), [])
        return found[0] if found else None


def clean(text: str) -> str:
    if any(char in text for char in "\t\r\n"):
        raise ExportError(f"ô bảng mang tab hay xuống dòng: {text!r}")
    return text


def mesh_files(template) -> list:
    return [item.get("file") for item in template.iter("Entity") if item.get("file")]


def scale_of(template) -> tuple:
    """Thuộc tính Scale của mẫu thành ba ô chữ; không có thì 1 1 1."""
    values = [item.get("value") for item in template.iter("Attribute") if item.get("name") == "Scale"]
    if not values:
        return ("1", "1", "1")
    parts = values[0].split()
    if len(parts) != 3 or any(float(part) <= 0 for part in parts):
        raise ExportError(f"Scale của mẫu {template.get('name')} sai dạng: {values[0]!r}")
    return tuple(parts)


def is_finite_text(text: str | None) -> bool:
    """Ô số của locator đọc được và hữu hạn; "1.#QNAN" (atof của MSVC cho NaN) và ô thiếu thì không."""
    try:
        return text is not None and math.isfinite(float(text))
    except ValueError:
        return False


def locator_rows(template, dropped: list) -> list:
    rows = []
    for locator in template.iter("Locator"):
        numbers = [locator.get(key) for key in ("x", "y", "z", "qx", "qy", "qz", "qw")]
        if not all(is_finite_text(number) for number in numbers):
            dropped.append(f"{template.get('name')}/{locator.get('name')}")
            continue
        slots = [slot.get("name") for slot in locator.iter("Slot")]
        rows.append((clean(locator.get("name")), clean(locator.get("bonename") or ""),
                     locator.get("x"), locator.get("y"), locator.get("z"),
                     locator.get("qx"), locator.get("qy"), locator.get("qz"), locator.get("qw"),
                     1 if locator.get("translateFirst", "false").lower() == "true" else 0,
                     slots[0] if slots else ""))
    return rows


def effects_of(visuals, row: int) -> tuple:
    """(cờ đá quý của lưng, hông 1, hông 2; chuỗi tên hiệu ứng) của một hàng ItemVisualLocator."""
    flags = tuple(1 if str(visuals.cell(row, column)) == "1" else 0 for column in GEM_FLAGS)
    names = []
    for column in range(EFFECT_FIRST, EFFECT_FIRST + EFFECT_COUNT):
        cell = visuals.cell(row, column)
        names.append(clean(cell) if isinstance(cell, str) and cell not in ("0", "-1") else "")
    return flags, ";".join(names)


def read_gems(sources: Sources) -> list:
    """(đá quý, màu, chỉ số hiệu ứng) của mọi đá quý có màu chuỗi; màu -1 (số) không có hiệu ứng nên bỏ."""
    table = sources.table("GemInfo.txt")
    gems = []
    for row in range(table.rows):
        colour = table.cell(row, GEM_COLOUR)
        if not isinstance(colour, str):
            continue
        gems.append((table.integer(row, 0), clean(colour), table.integer(row, GEM_EFFECT)))
    return gems


def build(sources: Sources, templates: Templates, body_templates: list, report: dict) -> tuple:
    visuals = sources.table("ItemVisualLocator.txt")
    weapons, objects, locators, effects = [], {}, [], []
    for row in range(visuals.rows):
        visual = visuals.integer(row, 0)
        names: dict = {}
        for slot, column, _ in VISUAL_SLOTS:
            names[slot] = visuals.text(row, column)
        if not any(names.values()):
            continue
        if not 0 < visual <= MAX_SHORT:
            raise ExportError(f"ItemVisualLocator: id hình {visual} ngoài 1..{MAX_SHORT}")
        resolved, lost = {}, ""
        for slot, name in names.items():
            if not name:
                resolved[slot] = ""
                continue
            template = templates.find(name)
            if template is None:
                lost = name
                break
            resolved[slot] = template.get("name")
            objects.setdefault(template.get("name"), template)
        if lost:
            report["lost"].append(f"{visual}: {lost}")
            continue
        weapons.append((visual, *(resolved[slot] for slot, _, _ in VISUAL_SLOTS)))
        flags, joined = effects_of(visuals, row)
        if joined.strip(";"):
            effects.append((visual, *flags, joined))
    for name in sorted(objects):
        locators.extend((name, *item) for item in locator_rows(objects[name], report["dropped"]))
    for name in body_templates:
        template = templates.find(name)
        if template is None:
            raise ExportError(f"all.obj không có mẫu nhân vật {name}")
        locators.extend((template.get("name"), *item) for item in locator_rows(template, report["dropped"]))
    return weapons, objects, locators, effects


def read_body_templates(target: str) -> list:
    path = os.path.join(target, "Table", BODY_TABLE)
    if not os.path.isfile(path):
        raise ExportError(f"chưa có {path}: chạy export_look.py trước")
    with open(path, encoding="utf-8", newline="") as stream:
        lines = [line.rstrip("\n").split("\t") for line in stream if not line.startswith("#")]
    header, rows = lines[0], lines[1:]
    return [row[header.index("template")] for row in rows]


def write_all(target: str, weapons: list, items: list, objects: dict, locators: list, effects: list, gems: list) -> None:
    table_dir = os.path.join(target, "Table")
    source = "Sinh bằng TOOLS/content/export_weapons.py từ Config của client; sửa tay sẽ mất ở lượt xuất sau."
    write_table(os.path.join(table_dir, "weapons.tsv"),
                ["Hình vũ khí, khoá id (ItemVisualLocator; là id hình của vật phẩm khe 0).", source,
                 "Các cột sau id là mẫu .obj (tên trong objects.tsv) của từng khe: right, left (hai tay), kfs (võ hồn),",
                 "foot, back, waist1, waist2; khe rỗng là không có."],
                ["id", *(slot for slot, _, _ in VISUAL_SLOTS)], weapons)
    write_table(os.path.join(table_dir, "weapon_items.tsv"),
                ["Vật phẩm khe 0 (EquipBase điểm mang 0), khoá item; mọi vật phẩm, kể cả hình không có mẫu.", source,
                 "visual là id hình (cột 6), -1 là không có; class là loại cho cột weapon của anim_sets theo nType",
                 "(cột 3): none khi không phải sáu loại cầm tay. Loại thuộc vật phẩm vì nhiều vật phẩm khác loại dùng chung hình."],
                ["item", "visual", "class"], items)
    write_table(os.path.join(table_dir, "objects.tsv"),
                ["Mẫu .obj của vũ khí, khoá object (tên đúng như Model/all.obj).", source,
                 "meshes là các tệp .mesh dưới Model/ (nối bằng |, theo thứ tự entity); sx sy sz là thuộc tính Scale của mẫu",
                 "(1 1 1 khi mẫu không khai)."],
                ["object", "meshes", "sx", "sy", "sz"],
                [(name, clean("|".join(mesh_files(template))), *scale_of(template))
                 for name, template in sorted(objects.items())])
    write_table(os.path.join(table_dir, "locators.tsv"),
                ["Locator của mẫu nhân vật và của mẫu vũ khí, khoá (object, locator).", source,
                 "bone là tên xương (rỗng là không theo xương); x y z là vị trí lệch; qx qy qz là trục và qw là góc radian",
                 "của phép quay lệch (Quaternion::FromAngleAxis); translate_first là cờ thứ tự áp lệch; slot là tên",
                 "SlotCreate của khe mà locator giữ (rỗng khi không có)."],
                ["object", "locator", "bone", "x", "y", "z", "qx", "qy", "qz", "qw", "translate_first", "slot"], locators)
    write_table(os.path.join(table_dir, "weapon_effects.tsv"),
                ["Hiệu ứng đồ của hình vũ khí, khoá visual (ItemVisualLocator cột 29 tới 62, theo mã máy 2026).", source,
                 "effects là 34 tên effect (Effect/all.effect) cách nhau bằng ';' theo chỉ số hiệu ứng 1 tới 34 của đá quý, ô rỗng",
                 "là không có. back, waist1, waist2 là cờ đá quý của khe lưng và hai khe hông (khe tay luôn nhận)."],
                ["visual", "back", "waist1", "waist2", "effects"], effects)
    write_table(os.path.join(table_dir, "gems.tsv"),
                ["Đá quý có màu hiệu ứng, khoá gem (vật phẩm đá quý; GemInfo cột 0, 75, 77).", source,
                 "colour là chuỗi RRGGBBAA hex (client gốc đọc %8X); effect là chỉ số hiệu ứng từ 1 của weapon_effects."],
                ["gem", "colour", "effect"], gems)


def main() -> int:
    if len(sys.argv) != 4:
        print("Cách dùng: python export_weapons.py <_raw> <_glb> <dữ liệu client>", file=sys.stderr)
        return 2
    raw_root, glb_root, target = (os.path.abspath(path) for path in sys.argv[1:4])
    sources = Sources(raw_root, glb_root)
    report = {"lost": [], "dropped": []}
    try:
        templates = Templates(ObjectBook(os.path.join(raw_root, "Model", "all.obj")))
        weapons, objects, locators, effects = build(sources, templates, read_body_templates(target), report)
        items = read_items(sources)
        gems = read_gems(sources)
    except (ExportError, dbc.DbcError, OSError, KeyError) as error:
        print(f"Lỗi: {error}", file=sys.stderr)
        return 1
    write_all(target, weapons, items, objects, locators, effects, gems)
    typed = sum(1 for item in items if item[2] != "none")
    print(f"weapons {len(weapons)}, weapon_items {len(items)} (có loại {typed}), objects {len(objects)}, "
          f"locators {len(locators)}, weapon_effects {len(effects)}, gems {len(gems)}")
    if report["dropped"]:
        print(f"Locator bỏ vì số không hữu hạn (NaN trong all.obj): {len(report['dropped'])}: "
              f"{', '.join(report['dropped'][:10])}")
    if report["lost"]:
        print(f"Hình bỏ vì mẫu không có trong all.obj: {len(report['lost'])}: {', '.join(report['lost'][:10])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
