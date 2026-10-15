#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/collect_creatures.py
#  PHÂN HỆ   : Content / Collect Creatures
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Gom tài nguyên của quái và NPC vào thư mục dữ liệu client theo
#    Table/creatures.tsv, creature_clips.tsv, creature_materials.tsv: skeleton,
#    lưới, ảnh, tệp clip, ảnh của material chồng.
#  - Ghi danh sách Table/creature.files.tsv cho gói APK; --check chỉ so.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

from __future__ import annotations

# Đọc Table/creatures.tsv, creature_clips.tsv và creature_materials.tsv (do export_creatures.py sinh) rồi gom đúng thứ
# chúng nêu vào thư mục dữ liệu client, giữ bố cục tương đối (Model/<tên>.glb, Material/<ảnh>.png) để URI ảnh trong GLB
# vẫn đúng: skeleton chính của mỗi mô hình, mọi lưới (kèm ảnh mà GLB của lưới trỏ tới, theo Collector của collect_map.py),
# tệp skeleton chứa clip, và ảnh nền của material chồng. Quyết định:
# - Danh sách riêng Table/creature.files.tsv (cùng dạng kind/path với avatar.files.tsv), không nối vào avatar.files.tsv:
#   người chơi luôn có trong APK còn quái và NPC chỉ theo các cảnh đã xuất, nên hai tập đi hai đường đóng gói.
# - Chỉ chép, không đổi nội dung; tệp đích đã có và cùng cỡ thì bỏ qua (như copy_files). Thứ tự dòng danh sách theo đường dẫn.
# - Ảnh GLB của lưới nạp nguyên dù mọi entity chồng material khác: GLB vẫn trỏ tới ảnh mặc định và bộ nạp có thể mở nó.
# Cách dùng: python collect_creatures.py <_raw> <_glb> <thư mục dữ liệu client> [--check]
# --check chỉ so (mã thoát 1 khi còn thiếu tệp nguồn, thiếu tệp đích hoặc danh sách lệch); mã thoát 1 khi có thứ thiếu.

import argparse
import csv
import os
import sys
from collections import Counter

from collect_map import Collector, copy_files

TABLE_FOLDER = "Table"
LIST_NAME = "creature.files.tsv"


def read_table(path: str) -> list:
    with open(path, encoding="utf-8", newline="") as stream:
        lines = [line for line in stream if not line.startswith("#")]
    return list(csv.DictReader(lines, delimiter="\t"))


def want_all(collector: Collector, table_dir: str) -> None:
    for row in read_table(os.path.join(table_dir, "creatures.tsv")):
        if row["skeleton"]:
            collector.want("skeleton", collector.glb_root, os.path.join("Model", row["skeleton"] + ".glb"))
        for mesh in row["meshes"].split("|"):
            if mesh:
                collector.add_mesh(mesh)
    clips = os.path.join(table_dir, "creature_clips.tsv")
    for anim in sorted({row["anim"] for row in read_table(clips)}):
        collector.want("clip", collector.glb_root, os.path.join("Model", anim + ".glb"))
    for row in read_table(os.path.join(table_dir, "creature_materials.tsv")):
        collector.want("texture", collector.glb_root, row["texture"])


def list_text(collector: Collector) -> str:
    lines = ["kind\tpath"]
    lines.extend(f"{kind}\t{relative.replace(os.sep, '/')}" for relative, (kind, _) in sorted(collector.files.items()))
    return "\n".join(lines) + "\n"


def run(raw_root: str, glb_root: str, target: str, check: bool) -> int:
    table_dir = os.path.join(target, TABLE_FOLDER)
    collector = Collector(raw_root, glb_root, target)
    want_all(collector, table_dir)
    text = list_text(collector)
    list_path = os.path.join(table_dir, LIST_NAME)
    kinds = Counter(kind for kind, _ in collector.files.values())
    stale = []
    if check:
        for relative, (kind, source_root) in sorted(collector.files.items()):
            output = os.path.join(target, relative)
            source = os.path.join(source_root, relative)
            if not os.path.isfile(output) or os.path.getsize(output) != os.path.getsize(source):
                stale.append(relative)
        current = open(list_path, encoding="utf-8", newline="").read() if os.path.isfile(list_path) else None
        if current != text:
            stale.append(os.path.join(TABLE_FOLDER, LIST_NAME))
    else:
        sizes = copy_files(collector)
        with open(list_path, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(text)
        for kind in sorted(kinds):
            print(f"  {kind}: {kinds[kind]} tệp, {sizes[kind]} byte")
        print(f"  tổng: {len(collector.files)} tệp, {sum(sizes.values())} byte vào {target}")
    for kind, name in collector.missing:
        print(f"  THIẾU {kind}: {name}")
    for relative in stale:
        print(f"  LỆCH: {relative.replace(os.sep, '/')}")
    return 1 if collector.missing or stale else 0


def main(argv: list | None = None) -> int:
    parser = argparse.ArgumentParser(description="Gom tài nguyên của quái và NPC theo bảng Table/creature*.tsv.")
    parser.add_argument("raw")
    parser.add_argument("glb")
    parser.add_argument("target")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    raw_root, glb_root, target = (os.path.abspath(path) for path in (args.raw, args.glb, args.target))
    return run(raw_root, glb_root, target, args.check)


if __name__ == "__main__":
    sys.exit(main())
