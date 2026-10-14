"""Kiểm kê script giao diện của client 2026 để xếp hàng port sang C++ (docs/giao-viec/UI-PORT).

cách dùng:
    python -B TOOLS/port/ui_inventory.py [--script src/client/script/Interface] [--hud src/client/face/ui/hud.cpp]
        [--panel src/client/face/ui/panel] [--api TAILIEU/GAME-EXE-2026/lua_api.tsv] [--out tệp.tsv]

Mỗi dòng một cửa sổ (thư mục con của Interface): số dòng Lua, số hàm, sự kiện đăng ký (this:RegisterEvent),
sự kiện tự đẩy (PushEvent), đối tượng API của Game.exe được gọi (Tên:Hàm), đã có bản port trong ui/panel chưa.
Thứ tự port: khoảng cách từ các cửa sổ HUD đang nạp (kLayouts của hud.cpp) trên đồ thị "A đẩy sự kiện mà B
đăng ký" (bỏ sự kiện phát chung, xem BROADCAST_LISTENERS); cửa sổ chỉ nhận sự kiện mà không script nào đẩy thì sự
kiện đến từ Game.exe (trạng thái game hoặc gói tin máy chủ) và được đánh dấu game_events. server_opened: đăng ký
UI_COMMAND, tức script máy chủ bật cửa sổ bằng DispatchUICommand; npc_bound: đăng ký OBJECT_CARED_EVENT (cửa sổ
gắn một NPC, đi xa thì đóng). Chỉ đọc tĩnh bằng biểu thức chính quy, không chạy Lua.
"""

from __future__ import annotations

import argparse
import collections
import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
REGISTER = re.compile(r"""this\s*:\s*RegisterEvent\s*\(\s*["']([A-Za-z0-9_]+)["']""")
PUSH = re.compile(r"""PushEvent\s*\(\s*["']([A-Za-z0-9_]+)["']""")
OPEN = re.compile(r"""(?:OpenWindow|CloseWindow|ToggleWindow)\s*\(\s*["']([A-Za-z0-9_]+)["']""")
CALL = re.compile(r"\b([A-Z][A-Za-z0-9_]*)\s*:\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(")
FUNCTION = re.compile(r"^\s*(?:local\s+)?function\s+([A-Za-z0-9_.:]+)", re.M)
LAYOUT = re.compile(r'"([A-Za-z0-9_]+)/[A-Za-z0-9_]+\.layout\.xml"')
COLUMNS = ("order", "window", "depth", "server_opened", "npc_bound", "lua_lines", "functions", "events_in",
           "game_events", "events_out", "opens", "api_objects", "api_calls", "ported", "files")
# Sự kiện có quá chừng này cửa sổ đăng ký là sự kiện phát chung, không tính là cạnh của đồ thị mở cửa sổ.
BROADCAST_LISTENERS = 20


def strip_comments(text: str) -> str:
    text = re.sub(r"--\[(=*)\[.*?\]\1\]", "", text, flags=re.S)
    return re.sub(r"--[^\n]*", "", text)


def scan_window(folder: Path, api_tables: set[str]) -> dict:
    files = sorted(folder.rglob("*.lua"))
    raw = "\n".join(path.read_text(encoding="utf-8", errors="replace") for path in files)
    body = strip_comments(raw)
    calls = collections.Counter(f"{obj}:{name}" for obj, name in CALL.findall(body) if obj in api_tables)
    return {
        "window": folder.name,
        "lua_lines": raw.count("\n") + 1 if raw else 0,
        "functions": len(FUNCTION.findall(body)),
        "events_in": sorted(set(REGISTER.findall(body))),
        "events_out": sorted(set(PUSH.findall(body))),
        "opens": sorted(set(OPEN.findall(body))),
        "api_objects": sorted({key.split(":")[0] for key in calls}),
        "api_calls": len(calls),
        "files": len(files),
    }


def api_table_names(api: Path) -> set[str]:
    names = set()
    for line in api.read_text(encoding="utf-8").splitlines()[1:]:
        table = line.split("\t", 1)[0]
        if table and not table.startswith("("):
            names.add(table)
    return names


def ported_windows(panel: Path, windows: set[str]) -> set[str]:
    found = set()
    for path in panel.glob("*.?pp"):
        text = path.read_text(encoding="utf-8", errors="replace")
        found.update(name for name in LAYOUT.findall(text) if name in windows)
        found.update(name for name in re.findall(r"Interface/([A-Za-z0-9_]+)/", text) if name in windows)
    return found


def depths(rows: dict[str, dict], roots: set[str]) -> dict[str, int]:
    listeners = collections.defaultdict(set)
    for name, row in rows.items():
        for event in row["events_in"]:
            listeners[event].add(name)
    # Sự kiện phát chung (đổi độ phân giải, chuyển cảnh, UI_COMMAND của máy chủ...) không phải cạnh "mở cửa sổ":
    # để vào đồ thị thì mọi cửa sổ cách HUD một bước.
    narrow = {event for event, names in listeners.items() if len(names) <= BROADCAST_LISTENERS}
    edges = {name: {target for event in row["events_out"] if event in narrow for target in listeners[event]}
             | set(row["opens"])
             for name, row in rows.items()}
    depth = {name: 0 for name in roots if name in rows}
    frontier = list(depth)
    while frontier:
        following = []
        for name in frontier:
            for target in edges.get(name, ()):
                if target in rows and target not in depth:
                    depth[target] = depth[name] + 1
                    following.append(target)
        frontier = following
    return depth


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--script", type=Path, default=PROJECT / "src/client/script/Interface")
    parser.add_argument("--hud", type=Path, default=PROJECT / "src/client/face/ui/hud.cpp")
    parser.add_argument("--panel", type=Path, default=PROJECT / "src/client/face/ui/panel")
    parser.add_argument("--api", type=Path, default=PROJECT / "TAILIEU/GAME-EXE-2026/lua_api.tsv")
    parser.add_argument("--out", type=Path, default=PROJECT / "docs/giao-viec/UI-PORT/HANG-DOI.tsv")
    args = parser.parse_args()

    api_tables = api_table_names(args.api)
    rows = {folder.name: scan_window(folder, api_tables)
            for folder in sorted(p for p in args.script.iterdir() if p.is_dir())}
    pushed = {event for row in rows.values() for event in row["events_out"]}
    hud = set(LAYOUT.findall(args.hud.read_text(encoding="utf-8")))
    depth = depths(rows, hud)
    ported = ported_windows(args.panel, set(rows))
    unreachable = max(depth.values(), default=0) + 1

    def rank(name: str) -> tuple:
        row = rows[name]
        return (depth.get(name, unreachable), name in ported, row["lua_lines"], name)

    lines = ["\t".join(COLUMNS)]
    for order, name in enumerate(sorted(rows, key=rank), start=1):
        row = rows[name]
        game_events = [event for event in row["events_in"] if event not in pushed]
        cells = (order, name, depth.get(name, "-"), "x" if "UI_COMMAND" in row["events_in"] else "",
                 "x" if "OBJECT_CARED_EVENT" in row["events_in"] else "", row["lua_lines"], row["functions"],
                 " ".join(row["events_in"]),
                 " ".join(game_events), " ".join(row["events_out"]), " ".join(row["opens"]),
                 " ".join(row["api_objects"]), row["api_calls"], "x" if name in ported else "", row["files"])
        lines.append("\t".join(str(cell) for cell in cells))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    reach = collections.Counter(depth.get(name, "-") for name in rows)
    total = sum(row["lua_lines"] for row in rows.values())
    print(f"cửa sổ: {len(rows)}, dòng Lua: {total}, đã có bản port: {len(ported)}, HUD: {len(hud & set(rows))}")
    print("theo độ sâu từ HUD:", dict(sorted(reach.items(), key=lambda kv: (kv[0] == "-", str(kv[0]).zfill(3)))))
    for key in sorted(k for k in reach if k != "-"):
        lines_at = sum(rows[n]["lua_lines"] for n in rows if depth.get(n) == key)
        print(f"  độ sâu {key}: {reach[key]} cửa sổ, {lines_at} dòng")
    print(f"ghi {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
