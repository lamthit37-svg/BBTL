"""Quét thư mục script của máy chủ: nạp Unit cho mọi tệp trong phạm vi, phân loại, ghi lỗi cú pháp.

Phạm vi là phần thuộc bản gốc. Thư mục do nhà phát hành riêng thêm (XYJ*, XiaoXiang_*, JiuFeng, ...) bị
loại, trừ script nhiệm vụ mà id nhiệm vụ cũng có ở client 2026 và chưa có script nào của phần gốc phủ.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

import lua_api as A
import lua_flow as F
import lua_syntax as S
import lua_units as U
from lua_values import Unsupported

ADDON_DIRS = frozenset(
    {
        "XYJ",
        "XYJ_Fuben",
        "XiaoXiang_",
        "JiuFeng",
        "RuMeng",
        "GMTools",
        "MyNew",
        "NewLua",
        "JMjiaoben",
        "axiao",
        "CSWL",
        "repair",
        "sanshen",
        "WukongTxt",
        "GuildCity",
    }
)
ENGINE_DIR = "event/EventScript"


@dataclass
class Scan:
    root: Path
    low: F.Lowerer
    dat: dict
    categories: dict = field(default_factory=dict)  # id -> loại
    syntax_errors: dict = field(default_factory=dict)  # id -> lý do
    missing_files: list = field(default_factory=list)
    addon: dict = field(default_factory=dict)  # id -> thư mục add-on
    global_notes: dict = field(default_factory=dict)


def build_lowerer(script_dir: Path) -> F.Lowerer:
    """Lowerer có sẵn hằng MD_/MF_ của ScriptGlobal.lua."""
    low = F.Lowerer({}, {}, A.API)
    unit = F.Unit(0, "ScriptGlobal.lua", {}, {})
    env = F.Env(unit)
    tree = S.parse(U.read_text(script_dir / "ScriptGlobal.lua"))
    for node in tree:
        low.steps = 0
        U._top_level(node, unit, env, low)
    for key, value in unit.globals.items():
        if isinstance(value, (int, float, str)):
            low.consts[key] = value
    low.consts["SCENE_SCRIPT_ID"] = A.SCENE_SCRIPT_ID
    low.consts["MSG2PLAYER_PARA"] = 0
    return low


def folder_of(path: str) -> str:
    parts = path.split("/")
    return parts[0] if len(parts) > 1 else ""


def classify(path: str, text: str, unit: F.Unit | None) -> str:
    """Loại script theo thư mục và nội dung (không chạy gì)."""
    lowered = path.replace("\\", "/")
    if lowered.startswith(ENGINE_DIR):
        return "engine"
    if "OnCopySceneTimer" in text and "MakeCopyScene" in text:
        return "copy_scene"
    if "MisDescBegin" in text and unit is not None and _has_mission_id(unit):
        return "quest"
    if lowered.startswith("obj/commonitem") or lowered.startswith("obj/item") or lowered.startswith("obj/pet"):
        return "item_use"
    if lowered.startswith("obj/growpoint"):
        return "gather"
    if lowered.startswith("event/peifang"):
        return "recipe"
    if lowered.startswith("event/chuansong") or "OnEnterArea" in text and "TransferFunc" in text:
        return "area_transfer"
    if lowered.startswith("obj/"):
        return "npc"
    if lowered.startswith("event/"):
        return "event"
    return "root"


def _has_mission_id(unit: F.Unit) -> bool:
    return any(key.endswith("_g_MissionId") and isinstance(value, int) for key, value in unit.globals.items())


def load_all(root: Path, dat: dict, low: F.Lowerer, client_quests: set) -> Scan:
    """Nạp mọi script trong phạm vi vào low.units. Add-on chỉ nhận khi là nhiệm vụ có id ở client."""
    scan = Scan(root, low, dat)
    script_dir = root / "Script"
    pending_addon: list = []
    for script_id, path in sorted(dat.items()):
        folder = folder_of(path)
        if folder in ADDON_DIRS:
            pending_addon.append((script_id, path))
            scan.addon[script_id] = folder
            continue
        _load_one(scan, script_dir, script_id, path)
    for script_id, path in pending_addon:
        _load_addon(scan, script_dir, script_id, path, client_quests)
    return scan


def _load_addon(scan: Scan, script_dir: Path, script_id: int, path: str, client_quests: set) -> None:
    file = script_dir / path
    if not file.is_file():
        return
    text = U.read_text(file)
    if "MisDescBegin" not in text:
        return
    try:
        unit = U.load_unit(script_id, path, text, scan.low)
    except (S.LuaSyntaxError, RecursionError):
        return
    quest = A.quest_of_unit(unit)
    if quest is None or quest not in client_quests:
        return
    if any(A.quest_of_unit(other) == quest for other in scan.low.units.values()):
        return
    scan.low.units[script_id] = unit
    scan.categories[script_id] = "quest"


def _load_one(scan: Scan, script_dir: Path, script_id: int, path: str) -> None:
    file = script_dir / path
    if not file.is_file():
        scan.missing_files.append((script_id, path))
        return
    text = U.read_text(file)
    try:
        unit = U.load_unit(script_id, path, text, scan.low)
    except (S.LuaSyntaxError, RecursionError, Unsupported) as exc:
        scan.syntax_errors[script_id] = str(exc)[:120]
        scan.categories[script_id] = classify(path, text, None) + "_unparsed"
        return
    scan.low.units[script_id] = unit
    scan.categories[script_id] = classify(path, text, unit)
