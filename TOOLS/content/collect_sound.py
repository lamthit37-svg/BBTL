# Gom âm thanh và bảng cấp của client 2026 vào thư mục dữ liệu client, để máy khác và APK có đủ:
# - <gốc>/Sound/** chép sang <client>/sound/** giữ nguyên đường dẫn tương đối;
# - <gốc>/Config/SoundInfo.txt và PlayerExpLevel.txt chép sang <client>/Config/;
# - sinh <client>/sound/sound_table.xml từ SoundInfo.txt (cột 0 id, cột 1 đường dẫn dưới Sound),
#   đúng định dạng audio::Catalog đọc: <item name="id" value="sound/..."/>.
# Chỉ đọc thư mục gốc. Mỗi tệp được so SHA256 nguồn và đích; id trỏ tới tệp không có thì ghi vào
# danh sách thiếu, không bỏ im lặng.
# Cách dùng: python collect_sound.py <thư mục gốc _goc> <thư mục dữ liệu client>
# Mã thoát 0 khi đủ, 1 khi có tệp lệch hay thiếu, 2 khi sai tham số.

import hashlib
import os
import shutil
import sys
from xml.sax.saxutils import quoteattr

import dbc

SOUND_SOURCE = "Sound"
SOUND_TARGET = "sound"
CONFIG = "Config"
TABLES = ("SoundInfo.txt", "PlayerExpLevel.txt")
TABLE_NAME = "sound_table.xml"


def digest(path: str) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1 << 20), b""):
            sha.update(block)
    return sha.hexdigest()


def copy_checked(source: str, target: str) -> bool:
    os.makedirs(os.path.dirname(target), exist_ok=True)
    wanted = digest(source)
    if not (os.path.isfile(target) and digest(target) == wanted):
        shutil.copy2(source, target)
    return digest(target) == wanted


def copy_tree(source_root: str, target_root: str) -> tuple[int, list[str]]:
    copied = 0
    bad = []
    for folder, _, names in os.walk(source_root):
        for name in names:
            source = os.path.join(folder, name)
            relative = os.path.relpath(source, source_root)
            if copy_checked(source, os.path.join(target_root, relative)):
                copied += 1
            else:
                bad.append(relative)
    return copied, bad


def sound_rows(table: dbc.Dbc, sound_root: str) -> tuple[list[tuple[int, str]], list[str]]:
    rows = []
    missing = []
    for row in range(table.rows):
        key = table.integer(row, 0)
        relative = table.text(row, 1).replace("\\", "/").strip()
        if not relative:
            missing.append(f"{key}: đường dẫn rỗng")
            continue
        if not os.path.isfile(os.path.join(sound_root, relative)):
            missing.append(f"{key}: {relative}")
            continue
        rows.append((key, f"{SOUND_TARGET}/{relative}"))
    return rows, missing


def write_table(path: str, rows: list[tuple[int, str]]) -> None:
    lines = ['<?xml version="1.0" encoding="utf-8"?>', "<sound_table>"]
    lines += [f"  <item name={quoteattr(str(key))} value={quoteattr(value)}/>" for key, value in rows]
    lines.append("</sound_table>")
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        stream.write("\n".join(lines) + "\n")


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("cách dùng: python collect_sound.py <thư mục gốc _goc> <thư mục dữ liệu client>", file=sys.stderr)
        return 2
    origin, client = argv[1], argv[2]
    sound_source = os.path.join(origin, SOUND_SOURCE)
    sound_target = os.path.join(client, SOUND_TARGET)
    if not os.path.isdir(sound_source):
        print(f"không có thư mục {sound_source}", file=sys.stderr)
        return 2
    copied, bad = copy_tree(sound_source, sound_target)
    for name in TABLES:
        if not copy_checked(os.path.join(origin, CONFIG, name), os.path.join(client, CONFIG, name)):
            bad.append(f"{CONFIG}/{name}")
    table = dbc.read(os.path.join(client, CONFIG, "SoundInfo.txt"), "SoundInfo")
    rows, missing = sound_rows(table, sound_target)
    write_table(os.path.join(sound_target, TABLE_NAME), rows)
    print(f"âm thanh: {copied} tệp khớp SHA256, {len(bad)} lệch; bảng {len(rows)}/{table.rows} id, {len(missing)} thiếu")
    for line in bad + missing:
        print(f"  {line}")
    return 1 if bad or missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))