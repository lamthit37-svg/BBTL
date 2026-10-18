# Gom tài nguyên của người chơi vào thư mục dữ liệu client: với mỗi giới trong Table/player_bodies.tsv,
# lưới của bộ mặc định (mặt, tóc và phụ kiện tóc, áo, tay, giày), các tệp skeleton chứa clip của
# anim_sets theo loại vũ khí đã chọn, mọi mặt và tóc chọn được lúc tạo nhân vật (creatable = 1, kèm
# bản cao mô id + 10000 mà màn tạo dùng cho người mẫu), ba bộ đồ tân thủ của newbie_outfits.tsv,
# 30 người mẫu xem trước môn phái của sect_models.tsv cùng lưới đồ gắn khe của sect_held.tsv (do
# export_sect_held.py sinh), lưới của mọi mẫu vũ khí trong objects.tsv (do
# export_weapons.py sinh), tệp skeleton chứa clip đòn đánh và tuyệt chiêu của skill_clips.tsv (do export_skills.py
# sinh), và ảnh mà GLB của chúng trỏ tới. Giữ nguyên bố cục tương đối
# (Model/<tên>.glb, Material/<ảnh>.png) để URI ảnh trong GLB vẫn đúng. Chỉ chép, không đổi nội dung.
# Dựa trên Collector của collect_map.py. Đọc Table/*.tsv do export_look.py sinh ra.
# Cách dùng: python collect_avatar.py <_raw> <_glb> <thư mục dữ liệu client> [loại vũ khí ...]
# Mặc định đủ bảy loại (tay không và sáu loại cầm tay). Ghi Table/avatar.files.tsv; mã thoát 1 khi có thứ thiếu.

import csv
import os
import sys
from collections import Counter

from collect_map import Collector, copy_files

TABLE_FOLDER = "Table"
DEFAULT_WEAPONS = ("none", "spear", "blade", "dual_short", "short", "fan", "ring")


def read_table(path: str) -> list:
    with open(path, encoding="utf-8", newline="") as stream:
        lines = [line for line in stream if not line.startswith("#")]
    return list(csv.DictReader(lines, delimiter="\t"))


def add_default_parts(collector: Collector, table_dir: str, body: dict) -> None:
    race = body["race"]
    faces = {(row["id"], row["race"]): row for row in read_table(os.path.join(table_dir, "faces.tsv"))}
    hairs = {(row["id"], row["race"]): row for row in read_table(os.path.join(table_dir, "hairs.tsv"))}
    outfits = {(row["id"], row["race"]): row for row in read_table(os.path.join(table_dir, "outfits.tsv"))}
    collector.add_mesh(faces[(body["face"], race)]["mesh"])
    hair = hairs[(body["hair"], race)]
    for name in (hair["mesh"], hair["accessory"]):
        if name:
            collector.add_mesh(name)
    for key in ("body", "arm", "foot"):
        collector.add_mesh(outfits[(body[key], race)]["mesh"])


HIGH_POLY_STEP = 10000
# choice 1 hoặc 3 của faces.tsv và hairs.tsv là chọn được lúc tạo nhân vật (export_look.py chỉ ghi cột choice).
CREATABLE_CHOICES = frozenset({"1", "3"})


def creation_ids(rows: dict, race: str) -> list[str]:
    """Id chọn được lúc tạo của một giới, mỗi id kèm bản cao mô id + 10000; theo thứ tự id, không lặp."""
    chosen = sorted(int(ident) for (ident, row_race), row in rows.items()
                    if row_race == race and row["choice"] in CREATABLE_CHOICES)
    ordered: list[str] = []
    for ident in chosen:
        for wanted in (str(ident), str(ident + HIGH_POLY_STEP)):
            if wanted not in ordered:
                ordered.append(wanted)
    return ordered


def add_creation_parts(collector: Collector, table_dir: str) -> None:
    """Mặt, tóc chọn được lúc tạo (và bản cao mô nếu bảng có) và ba bộ đồ tân thủ của mỗi giới."""
    faces = read_table(os.path.join(table_dir, "faces.tsv"))
    hairs = read_table(os.path.join(table_dir, "hairs.tsv"))
    outfits = {(row["id"], row["race"]): row for row in read_table(os.path.join(table_dir, "outfits.tsv"))}
    newbie = read_table(os.path.join(table_dir, "newbie_outfits.tsv"))
    face_rows = {(row["id"], row["race"]): row for row in faces}
    hair_rows = {(row["id"], row["race"]): row for row in hairs}

    def add_row(rows: dict, key: tuple, columns: tuple) -> None:
        row = rows.get(key)
        if row is None:
            return
        for column in columns:
            if row[column]:
                collector.add_mesh(row[column])

    for rows, columns in ((face_rows, ("mesh",)), (hair_rows, ("mesh", "accessory"))):
        for race in ("0", "1"):
            for ident in creation_ids(rows, race):
                add_row(rows, (ident, race), columns)
    for suit in newbie:
        for race in ("0", "1"):
            for key in ("body", "arm", "foot"):
                add_row(outfits, (suit[key], race), ("mesh",))


def add_sect_models(collector: Collector, table_dir: str) -> None:
    """Skeleton (chứa idle và demo) và mọi lưới của người mẫu môn phái."""
    for row in read_table(os.path.join(table_dir, "sect_models.tsv")):
        collector.want("skeleton", collector.glb_root, os.path.join("Model", row["skeleton"] + ".glb"))
        for mesh in row["meshes"].split("|"):
            if mesh:
                collector.add_mesh(mesh)


def add_sect_held(collector: Collector, table_dir: str) -> None:
    """Lưới của đồ gắn khe trên người mẫu môn phái (鬼谷 cầm gậy bằng khe).

    Thiếu sect_held.tsv là THIẾU, không bỏ qua: client đọc bảng này cùng sect_models.tsv, thiếu thì
    cả màn tạo nhân vật mất người mẫu (player.cpp), nên lỗi phải hiện ở bước gom này."""
    path = os.path.join(table_dir, "sect_held.tsv")
    if not os.path.isfile(path):
        collector.missing.append(("table", "sect_held.tsv (chạy export_sect_held.py)"))
        return
    for row in read_table(path):
        for mesh in row["meshes"].split("|"):
            if mesh:
                collector.add_mesh(mesh)


def add_weapons(collector: Collector, table_dir: str) -> None:
    """Lưới của mọi mẫu vũ khí (mọi khe) mà weapons.tsv dẫn tới; chưa có objects.tsv thì không gom gì."""
    path = os.path.join(table_dir, "objects.tsv")
    if not os.path.isfile(path):
        return
    for row in read_table(path):
        for mesh in row["meshes"].split("|"):
            if mesh:
                collector.add_mesh(mesh)


def add_skill_clips(collector: Collector, table_dir: str) -> None:
    """Tệp skeleton chứa clip của đòn đánh và tuyệt chiêu; chưa có skill_clips.tsv thì không gom gì."""
    path = os.path.join(table_dir, "skill_clips.tsv")
    if not os.path.isfile(path):
        return
    for row in read_table(path):
        collector.want("clip", collector.glb_root, os.path.join("Model", row["anim"] + ".glb"))


def add_clips(collector: Collector, table_dir: str, body: dict, weapons: tuple) -> None:
    for row in read_table(os.path.join(table_dir, "anim_sets.tsv")):
        if row["set"] == body["anim_set"] and row["weapon"] in weapons:
            collector.want("clip", collector.glb_root, os.path.join("Model", row["anim"] + ".glb"))


def main() -> int:
    if len(sys.argv) < 4:
        print("Cách dùng: python collect_avatar.py <_raw> <_glb> <dữ liệu client> [loại vũ khí ...]",
              file=sys.stderr)
        return 2
    raw_root, glb_root, target = (os.path.abspath(path) for path in sys.argv[1:4])
    weapons = tuple(sys.argv[4:]) or DEFAULT_WEAPONS
    table_dir = os.path.join(target, TABLE_FOLDER)
    collector = Collector(raw_root, glb_root, target)
    for body in read_table(os.path.join(table_dir, "player_bodies.tsv")):
        collector.want("skeleton", glb_root, os.path.join("Model", body["skeleton"] + ".glb"))
        add_default_parts(collector, table_dir, body)
        add_clips(collector, table_dir, body, weapons)
    add_creation_parts(collector, table_dir)
    add_sect_models(collector, table_dir)
    add_sect_held(collector, table_dir)
    add_weapons(collector, table_dir)
    add_skill_clips(collector, table_dir)
    sizes = copy_files(collector)
    kinds = Counter(kind for kind, _ in collector.files.values())
    list_path = os.path.join(table_dir, "avatar.files.tsv")
    with open(list_path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("kind\tpath\n")
        for relative, (kind, _) in sorted(collector.files.items()):
            stream.write(f"{kind}\t{relative.replace(os.sep, '/')}\n")
    for kind in sorted(kinds):
        print(f"  {kind}: {kinds[kind]} tệp, {sizes[kind]} byte")
    print(f"  tổng: {len(collector.files)} tệp, {sum(sizes.values())} byte vào {target}")
    for kind, name in collector.missing:
        print(f"  THIẾU {kind}: {name}")
    return 1 if collector.missing else 0


if __name__ == "__main__":
    sys.exit(main())
