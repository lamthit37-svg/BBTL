# Xuất Table/sect_held.tsv: đồ gắn theo khe của người mẫu môn phái (màn tạo nhân vật), lấy từ
# Model/all.obj của client 2026 (_raw). Người mẫu môn phái của sect_models.tsv chỉ liệt kê EntityList của
# mẫu; 鬼谷 không cầm vũ khí bằng lưới trong EntityList mà bằng khe: Locator "武器特效点" của mẫu mang
# Slot object="主角高模鬼谷武器.obj", client gốc gắn mẫu .obj đó vào xương của locator. Bảng này giữ đúng
# phần ấy: mẫu .obj của khe, các lưới của nó và locator của mẫu nhân vật (xương, vị trí lệch, trục và
# góc radian, cờ thứ tự áp lệch), cùng quy ước với locators.tsv của export_weapons.py.
# Quyết định:
# - Mỗi mẫu môn phái có tối đa một khe mang mẫu .obj; hai khe trở lên là lỗi dữ liệu (client mới có một
#   Hold cho người mẫu) để lần xuất sau không lặng lẽ bỏ khe.
# - Locator có số không hữu hạn bị bỏ như export_weapons.py, kèm báo cáo.
# Cách dùng: python export_sect_held.py <_raw> <thư mục dữ liệu client>
# Mã thoát 1 khi có lỗi dữ liệu.

from __future__ import annotations

import os
import sys

from export_look import ExportError, ObjectBook, write_table
from export_weapons import clean, is_finite_text, mesh_files

SECT_TABLE = "sect_models.tsv"
HEADER = ["race", "sect", "object", "meshes", "bone", "x", "y", "z", "qx", "qy", "qz", "qw", "translate_first"]
NUMBERS = ("x", "y", "z", "qx", "qy", "qz", "qw")


def read_sects(target: str) -> list:
    """(race, sect, tên mẫu) của sect_models.tsv, theo thứ tự dòng."""
    path = os.path.join(target, "Table", SECT_TABLE)
    if not os.path.isfile(path):
        raise ExportError(f"chưa có {path}")
    with open(path, encoding="utf-8", newline="") as stream:
        lines = [line.rstrip("\n").split("\t") for line in stream if line.strip() and not line.startswith("#")]
    if not lines:
        raise ExportError(f"{path} rỗng")
    header, rows = lines[0], lines[1:]
    for column in ("race", "sect", "template"):
        if column not in header:
            raise ExportError(f"{path} thiếu cột {column}")
    for number, row in enumerate(rows, start=2):
        if len(row) != len(header):
            raise ExportError(f"{path} dòng {number}: {len(row)} cột, mong {len(header)}")
    return [(row[header.index("race")], row[header.index("sect")], row[header.index("template")]) for row in rows]


def held_slots(template) -> list:
    """(locator, tên mẫu .obj) của mọi khe có mẫu."""
    found = []
    for locator in template.iter("Locator"):
        for slot in locator.iter("Slot"):
            if slot.get("object"):
                found.append((locator, slot.get("object")))
    return found


def held_row(book: ObjectBook, race: str, sect: str, template, dropped: list) -> tuple | None:
    slots = held_slots(template)
    if not slots:
        return None
    if len(slots) > 1:
        raise ExportError(f"mẫu {template.get('name')} có {len(slots)} khe mang mẫu .obj, mong tối đa 1")
    locator, name = slots[0]
    numbers = [locator.get(key) for key in NUMBERS]
    if not all(is_finite_text(number) for number in numbers):
        dropped.append(f"{template.get('name')}/{locator.get('name')}")
        return None
    meshes = mesh_files(book.template(name))
    if not meshes:
        raise ExportError(f"mẫu {name} của {template.get('name')} không có lưới")
    first = 1 if locator.get("translateFirst", "false").lower() == "true" else 0
    return (race, sect, clean(name), clean("|".join(meshes)), clean(locator.get("bonename") or ""), *numbers, first)


def main() -> int:
    if len(sys.argv) != 3:
        print("Cách dùng: python export_sect_held.py <_raw> <dữ liệu client>", file=sys.stderr)
        return 2
    raw_root, target = (os.path.abspath(path) for path in sys.argv[1:3])
    dropped: list = []
    try:
        book = ObjectBook(os.path.join(raw_root, "Model", "all.obj"))
        rows = []
        for race, sect, name in read_sects(target):
            row = held_row(book, race, sect, book.template(name), dropped)
            if row is not None:
                rows.append(row)
    except (ExportError, OSError) as error:
        print(f"Lỗi: {error}", file=sys.stderr)
        return 1
    source = "Sinh bằng TOOLS/content/export_sect_held.py từ Model/all.obj; sửa tay sẽ mất ở lượt xuất sau."
    write_table(os.path.join(target, "Table", "sect_held.tsv"),
                ["Đồ gắn theo khe của người mẫu môn phái, khoá (race, sect); race 0 nữ, 1 nam. Môn không có dòng là không gắn gì.",
                 source,
                 "object là mẫu .obj của khe, meshes là lưới của nó (nối bằng |). bone, x y z, qx qy qz qw, translate_first là",
                 "locator của mẫu nhân vật giữ khe, như locators.tsv (qx qy qz là trục, qw là góc radian)."],
                HEADER, rows)
    print(f"sect_held {len(rows)} dòng")
    if dropped:
        print(f"Locator bỏ vì số không hữu hạn: {len(dropped)}: {', '.join(dropped[:10])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
