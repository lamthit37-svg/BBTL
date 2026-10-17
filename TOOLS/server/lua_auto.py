"""Nhiệm vụ tự nhận và tự hoàn thành theo cấp, đọc từ scene.lua (g_AutoAccept_MissionList, g_FullLevel_MissionList).

scene.lua có hai bảng theo cấp: danh sách "lên cấp thì tự nhận" và danh sách "lên cấp thì đánh dấu đã hoàn thành".
Hai bảng gộp theo cấp; máy chủ đọc bảng quest_auto và xử lý sự kiện lên cấp (module mission), không gọi script.
"""
from __future__ import annotations

from pathlib import Path

import lua_flow as F
import lua_syntax as S
import lua_units as U

ACCEPT = "x888888_g_AutoAccept_MissionList"
FULL = "x888888_g_FullLevel_MissionList"

# Khác gốc: 1400 初涉江湖 được cấp ngay khi nhân vật vào game lần đầu. Máy chủ XJL7457 làm việc đó trong
# x888888_OnScenePlayerFirstLogin (scene.lua) bằng AddMission(718, 210238), id 2008 đã thay bằng id 2026.
# Bằng chứng id 2026: danh bạ client ghi người giao -1 (không NPC giao) và MisDesc edali_newquest_001.lua nói mục
# tiêu "已找到赵天师". Hàng nhận theo cấp 1: nơi gọi phát sự kiện lên cấp 0 -> cấp hiện tại ở lần vào đầu tiên.
# (cấp nhận, quest, script, tiền đề, mã sự kiện, cấp hoàn thành, chỉ số, chỉ số ghi, tin)
FIRST_ENTRY_2026 = ((1, 1400, 210262, 0, 0, -1, -1, -1, ""),)


def load_scene_unit(low: F.Lowerer, script_dir: Path) -> F.Unit:
    unit = F.Unit(888888, "scene.lua", {}, {})
    env = F.Env(unit)
    for node in S.parse(U.read_text(script_dir / "scene.lua")):
        low.steps = 0
        U._top_level(node, unit, env, low)
    return unit


def table_rows(unit: F.Unit, name: str) -> dict:
    """{cấp: {trường: giá trị}} của bảng theo cấp; trường không phải số/chuỗi hằng bị bỏ."""
    table = unit.globals.get(name)
    if table is None or not hasattr(table, "items"):
        return {}
    found: dict = {}
    for level, row in table.items.items():
        if isinstance(level, int) and hasattr(row, "items"):
            found[level] = {key: value for key, value in row.items.items() if isinstance(value, (int, str))}
    return found


def auto_rows(unit: F.Unit) -> list:
    """Hàng mission_auto: (cấp nhận, quest, script, tiền đề, mã sự kiện, cấp hoàn thành, chỉ số, chỉ số ghi, tin)."""
    accept = table_rows(unit, ACCEPT)
    full = table_rows(unit, FULL)
    rows = []
    for level in sorted(set(accept) | set(full)):
        take = accept.get(level, {})
        done = full.get(level, {})
        quest = take.get("MissionId", done.get("MissionId", -1))
        script = take.get("MissionIndex", done.get("MissionIndex", -1))
        rows.append((level if take else -1, quest, script, take.get("PreMissionId", 0), take.get("EventId", 0),
                     done.get("LevelLimit", -1), done.get("CompleteIdx", -1), done.get("RecordIdx", -1),
                     done.get("MsgStr", "")))
    return [*FIRST_ENTRY_2026, *rows]
