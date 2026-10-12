# Gom tài nguyên của người chơi vào thư mục dữ liệu client: với mỗi giới trong Table/player_bodies.tsv,
# lưới của bộ mặc định (mặt, tóc và phụ kiện tóc, áo, tay, giày), các tệp skeleton chứa clip của
# anim_sets theo loại vũ khí đã chọn, và ảnh mà GLB của chúng trỏ tới. Giữ nguyên bố cục tương đối
# (Model/<tên>.glb, Material/<ảnh>.png) để URI ảnh trong GLB vẫn đúng. Chỉ chép, không đổi nội dung.
# Dựa trên Collector của collect_map.py. Đọc Table/*.tsv do export_look.py sinh ra.
# Cách dùng: python collect_avatar.py <_raw> <_glb> <thư mục dữ liệu client> [loại vũ khí ...]
# Mặc định chỉ loại "none" (tay không). Ghi Table/avatar.files.tsv; mã thoát 1 khi có thứ thiếu.

import csv
import os
import sys
from collections import Counter

from collect_map import Collector, copy_files

TABLE_FOLDER = "Table"
DEFAULT_WEAPONS = ("none",)


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
⟪thiếu dòng này⟫
