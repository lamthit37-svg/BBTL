"""Khảo sát lớp B của LUA-GEN (docs/giao-viec/LUA-GEN/TANG-B.md): các số mà tài liệu ấy trích, đo lại từ bản trích
Game.exe 2026 (docs/TAILIEU/GAME-EXE-2026) và từ script của client. Mỗi mục in ra một nhóm số; không ghi tệp.

cách dùng (ở gốc dự án):
    python -B TOOLS/port/luagen/api_survey.py [--layouts <thư mục Interface của layout>]

Hàm game của Lua nằm trong decompile.zip theo địa chỉ `impl` của lua_api.tsv. Hàm "chuyển tiếp ô ảo N" của Player, Target,
CachedTarget (lớp SCRIPT_SANDBOX::*) nhảy tới ô ảo N của đối tượng; ô đó là hàm thật, đọc từ classes.tsv.
"""

from __future__ import annotations

import argparse
import collections
import csv
import pathlib
import re
import sys
import zipfile

import api_frequency
import mass_units

DUMP = mass_units.PROJECT / "docs/TAILIEU/GAME-EXE-2026"
HEADER = re.compile(r"^// ==== (0x[0-9a-f]+) ", re.M)
FORWARD = re.compile(r"ô ảo (\d+)")
LUA_CALL = re.compile(r"\b(lua_\w+|luaL_\w+|tThrow\w+|LuaPlus::[\w:~]+)\s*\(")
FUN_CALL = re.compile(r"\bFUN_[0-9a-f]+\s*\(")
DATA = re.compile(r"\bDAT_[0-9a-f]{8,9}\b")
# Biến toàn cục có thể ghi (vùng .data 0x141...) ngoài cookie bảo vệ ngăn xếp.
MUTABLE = re.compile(r"\bDAT_141(?!032290)[0-9a-f]{6}\b")
# Chủ của từng biến toàn cục, suy ra từ hàm gán nó (vftable của lớp trong hàm khởi tạo): đo 2026-10-15.
SINGLETONS = {
    "DAT_141034c40": "CDataPool",
    "DAT_14103db40": "CObjectManager",
    "DAT_141035fd8": "CEventSystem",
    "DAT_14103e690": "CUISystem",
    "DAT_14103d490": "CNetManager",
    "DAT_141034678": "CActionSystem",
    "DAT_14103f8b8": "CScriptSystem",
}
SCRIPT_CLASS = {
    "Player": "SCRIPT_SANDBOX::PlayerMySelf",
    "Target": "SCRIPT_SANDBOX::Character",
    "CachedTarget": "SCRIPT_SANDBOX::CachedCharacter",
}


def read_tsv(path: pathlib.Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def read_decompile() -> dict[int, str]:
    functions: dict[int, str] = {}
    with zipfile.ZipFile(DUMP / "decompile.zip") as archive:
        for name in archive.namelist():
            if not name.endswith(".c"):
                continue
            text = archive.read(name).decode("utf-8", "replace")
            marks = list(HEADER.finditer(text))
            for index, mark in enumerate(marks):
                end = marks[index + 1].start() if index + 1 < len(marks) else len(text)
                functions[int(mark.group(1), 16)] = text[mark.start():end]
    return functions


class Natives:
    """Mỗi hàm Lua của Game.exe với thân decompile của hàm thật (đã qua ô ảo nếu là hàm chuyển tiếp)."""

    def __init__(self) -> None:
        self.functions = read_decompile()
        classes = {row["class"]: row["slots"].split(",") for row in read_tsv(DUMP / "classes.tsv")}
        self.rows = read_tsv(DUMP / "lua_api.tsv")
        self.body: dict[tuple[str, str], str | None] = {}
        self.forwarded = 0
        for row in self.rows:
            address = int(row["impl"], 16)
            slot = FORWARD.search(row["impl_kind"])
            owner = row["lua_globals"].split(",")[0]
            if slot and row["table"] != "(globals)" and owner in SCRIPT_CLASS:
                address = int(classes[SCRIPT_CLASS[owner]][int(slot.group(1))], 16)
                self.forwarded += 1
            self.body[(row["table"], row["name"])] = self.functions.get(address)


def report_natives(natives: Natives) -> None:
    print(f"== hàm Lua của Game.exe: {len(natives.rows)} dòng, {len(natives.body)} hàm duy nhất, "
          f"{natives.forwarded} chuyển tiếp ô ảo đã giải, "
          f"{sum(1 for text in natives.body.values() if text is None)} không có decompile")
    calls: collections.Counter[str] = collections.Counter()
    touches: collections.Counter[str] = collections.Counter()
    pure = sends = 0
    for text in natives.body.values():
        if text is None:
            continue
        calls.update(set(LUA_CALL.findall(text)))
        owners = sorted({SINGLETONS[name] for name in DATA.findall(text) if name in SINGLETONS})
        touches["+".join(owners) or "không chạm singleton nào"] += 1
        if "Packets::CG" in text or "DAT_14103d490" in text:
            sends += 1
        # Trừ dòng đầu: tên hàm tự nó khớp FUN_.
        if not MUTABLE.search(text) and len(FUN_CALL.findall(text)) <= 1:
            pure += 1
    print("-- hàm Lua C API mà thân native gọi (số native gọi nó):")
    for name, count in calls.most_common(14):
        print(f"   {count:5d}  {name}")
    print("-- singleton mà native chạm (nhóm lớn nhất):")
    for name, count in touches.most_common(10):
        print(f"   {count:5d}  {name}")
    print(f"-- native gửi gói CG* hay chạm CNetManager: {sends}")
    print(f"-- native không chạm biến toàn cục ghi được và không gọi hàm nào khác: {pure}")


def report_events() -> None:
    strings = {row[0]: row[2] for row in csv.reader((DUMP / "strings.tsv").open(encoding="utf-8"), delimiter="\t")
               if len(row) > 2}
    pending = None
    events: dict[int, str] = {}
    set_id = re.compile(r"^0x[0-9a-f]+: MOV dword ptr \[0x140[0-9a-f]{6}\], (0x[0-9a-f]+)$")
    set_name = re.compile(r"^0x[0-9a-f]+: LEA RAX, \[(0x[0-9a-f]+)\]$")
    for line in (DUMP / "disasm/0x140a10cd0.asm").read_text(encoding="utf-8").splitlines():
        if match := set_id.match(line):
            pending = int(match.group(1), 16)
        elif (match := set_name.match(line)) and pending is not None:
            if name := strings.get(match.group(1)):
                events[pending] = name
            pending = None
    print(f"== tên sự kiện của CEventSystem (hàm khởi tạo tĩnh 0x140a10cd0): {len(events)} tên")
    for event_id in (0x85, 0x176, 0x177):
        print(f"   {event_id:#x} {events.get(event_id)}")


def report_coverage(layouts: pathlib.Path) -> None:
    lines = [line for line in (mass_units.PROJECT / "docs/giao-viec/LUA-GEN/API-TAN-SUAT.tsv").read_text(
        encoding="utf-8").splitlines() if not line.startswith("#")]
    ranked = [row["name"] for row in csv.DictReader(lines, delimiter="\t") if row["kind"] in ("game", "global")]
    tally = api_frequency.Tally(api_frequency.Api(api_frequency.API), api_frequency.window_names(layouts))
    units = [unit.name for unit in mass_units.units(layout_root=layouts)]
    for unit in mass_units.units(layout_root=layouts):
        for chunk in unit.chunks:
            tally.scan(unit.name, chunk.source)
    need: dict[str, set[str]] = collections.defaultdict(set)
    for (kind, name), owners in tally.units.items():
        if kind in ("game", "global"):
            for unit in owners:
                need[unit].add(name)
    order = {name: index + 1 for index, name in enumerate(ranked)}
    total = len(units)
    print(f"== đường cong phủ: {total} đơn vị, {len(ranked)} tên game/global, "
          f"{total - len(need)} đơn vị không cần hàm game/global nào")
    print("-- port N hàm đầu bảng tần suất thì bao nhiêu đơn vị chạy trọn (không kể widget):")
    for top in (10, 20, 40, 60, 100, 200, 400, 800, 1600):
        done = sum(1 for unit in units if unit not in need or max(order[n] for n in need[unit] if n in order) <= top)
        print(f"   top {top:5d}: {done:5d}/{total} ({100.0 * done / total:.1f}%)")
    print("-- thứ tự tham lam (đơn vị cần ít hàm mới nhất trước): bao nhiêu hàm để phủ tỉ lệ đơn vị:")
    have: set[str] = set()
    left = {unit: set(names) for unit, names in need.items()}
    completed = total - len(need)
    marks = [int(total * fraction) for fraction in (0.25, 0.5, 0.75, 0.9, 1.0)]
    while left:
        unit = min(left, key=lambda item: len(left[item] - have))
        have |= left.pop(unit)
        completed += 1
        for other in [item for item, names in left.items() if names <= have]:
            del left[other]
            completed += 1
        while marks and completed >= marks[0]:
            print(f"   {marks[0]:5d} đơn vị ({100.0 * marks[0] / total:.0f}%): {len(have)} hàm")
            marks.pop(0)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--layouts", type=pathlib.Path, default=mass_units.LAYOUT_ROOT)
    args = parser.parse_args(argv)
    if not args.layouts.is_dir():
        print(f"không thấy {args.layouts}: layout là dữ liệu gitignore, đưa thư mục của cây chính qua --layouts",
              file=sys.stderr)
        return 2
    report_natives(Natives())
    report_events()
    report_coverage(args.layouts)
    return 0


if __name__ == "__main__":
    sys.exit(main())
