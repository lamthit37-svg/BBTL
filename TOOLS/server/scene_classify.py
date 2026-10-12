"""Phân loại một tên tệp trong Public/Scene theo mục 7 của phụ lục.

Mỗi tên khớp đúng một loại. Hai mẫu `_monster_<cấp>` và `_<nhóm>monster_<cấp>` phải thử
nhóm dính trước, vì tên nhóm dính cũng kết thúc bằng `_monster_<cấp>`.
"""
from __future__ import annotations

import re

DROPPED = "dropped"
SCN = "scn"
NAV = "nav"
PATH = "path"
OBJECT_REGION = "object_region"
STALL = "stall"
MONSTER = "monster"
MONSTER_LEVEL = "monster_level"
MONSTER_BY_LEVEL = "monster_by_level"
MONSTER_GROUP = "monster_group"
MONSTER_BARE = "monster_bare"
MONSTER_ENTRANCE = "monster_entrance"
AREA = "area"
PATROL = "patrol"
GROWPOINT = "growpoint"
GROWPOINT_SETUP = "growpoint_setup"
PET = "pet"
PLATFORM = "platform"
PORTAL = "portal"
BUS = "bus"

_GLUED = re.compile(r"_(\d+)monster_(\d+)\.ini$", re.IGNORECASE)
_BY_LEVEL = re.compile(r"_monster_(\d+)\.ini$", re.IGNORECASE)
_BARE = re.compile(r"_monster(\d+)\.ini$", re.IGNORECASE)
_ENTRANCE = re.compile(r"_monster_([A-Za-z][A-Za-z0-9]*)\.ini$")
_SUFFIXES = (
    ("_monster_level.ini", MONSTER_LEVEL),
    ("_growpointsetup.txt", GROWPOINT_SETUP),
    ("_growpoint.txt", GROWPOINT),
    ("_patrolpoint.ini", PATROL),
    ("_stallinfo.stall", STALL),
    ("_monster.ini", MONSTER),
    ("_area.ini", AREA),
    ("_pet.ini", PET),
    ("_platform.ini", PLATFORM),
    ("_portal.ini", PORTAL),
    ("_bus.ini", BUS),
    (".objregion", OBJECT_REGION),
    (".nav", NAV),
    (".path", PATH),
    (".scn", SCN),
)


def classify_name(name: str) -> str | None:
    """Loại của một tên tệp, hoặc None khi chưa biết."""
    if name.lower() in {"testdata.txt", "testsetup.txt"}:
        return DROPPED
    if name.lower().endswith("_monster_level.ini"):
        return MONSTER_LEVEL
    if _GLUED.search(name):
        return MONSTER_GROUP
    if _BARE.search(name):
        return MONSTER_BARE
    if _BY_LEVEL.search(name):
        return MONSTER_BY_LEVEL
    if _ENTRANCE.search(name):
        return MONSTER_ENTRANCE
    lower = name.lower()
    for ending, kind in _SUFFIXES:
        if lower.endswith(ending):
            return kind
    return None


def monster_output(name: str) -> str | None:
    """Tên tsv của một tệp quái, chưa xử lý va chạm tên."""
    glued = _GLUED.search(name)
    if glued:
        return f"spawns.n{glued.group(1)}_level_{glued.group(2)}.tsv"
    bare = _BARE.search(name)
    if bare:
        return f"spawns.level_{bare.group(1)}.tsv"
    by_level = _BY_LEVEL.search(name)
    if by_level:
        return f"spawns.level_{by_level.group(1)}.tsv"
    entrance = _ENTRANCE.search(name)
    if entrance:
        return f"spawns.{entrance.group(1)}.tsv"
    if name.lower().endswith("_monster.ini"):
        return "spawns.tsv"
    return None


def stem_of(name: str) -> str | None:
    """Thân tên khi bỏ hậu tố đã biết. Dùng cho cụm không có tệp scn."""
    lower = name.lower()
    for ending, _kind in _SUFFIXES:
        if lower.endswith(ending):
            return name[: -len(ending)]
    for pattern in (_GLUED, _BARE, _BY_LEVEL, _ENTRANCE):
        found = pattern.search(name)
        if found:
            return name[: found.start()]
    return None


def longest_stem(name: str, stems: set[str]) -> str | None:
    """Cảnh có thân tên dài nhất mà tệp này thuộc về."""
    matches = [stem for stem in stems if name == stem or name.startswith(stem + "_") or name.startswith(stem + ".")]
    if not matches:
        return None
    return max(matches, key=len)
