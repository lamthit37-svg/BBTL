# Rút những thứ cấu tạo 36 layout mà client đang nạp, từ Interface của client gốc.
# Mỗi màn một tệp assets/ui/screen/<tên>.tsv. Mỗi atlas một tệp assets/ui/sheet/<tên>.tsv
# để lần cắt tấm ảnh biết ô. Chạy:
#   python -B TOOLS/content/collect_ui_face.py "F:/tl 2026/_goc/Interface" assets/ui
from __future__ import annotations

import argparse
import re
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

# Cùng danh sách kLayouts của src/client/face/ui/hud.cpp, kèm nhóm để tệp nằm đúng chỗ.
SCREENS: list[tuple[str, str]] = [
    ("hud", "PlayerFrame/PlayerFrame.layout.xml"),
    ("hud", "MiniMap/MiniMap.layout.xml"),
    ("hud", "MainMenuBar/MainMenuBar.layout.xml"),
    ("hud", "MainMenuBar_2/MainMenuBar_2.layout.xml"),
    ("hud", "MainMenuBar_3/MainMenuBar_3.layout.xml"),
    ("hud", "MainMenuBar_4/MainMenuBar_4.layout.xml"),
    ("hud", "ChatFrame/ChatFrame.layout.xml"),
    ("hud", "PlayerImpactFrame/PlayerImpactFrame.layout.xml"),
    ("hud", "AutoAttack_Button/AutoAttack_Button.layout.xml"),
    ("hud", "FunctionBarRight/FunctionBarRight.layout.xml"),
    ("hud", "FunctionBarRight_2/FunctionBarRight_2.layout.xml"),
    ("hud", "ProgressBar/ProgressBar.layout.xml"),
    ("bag", "SelfEquip/SelfEquip.layout.xml"),
    ("bag", "Packet/Packet.layout.xml"),
    ("quest", "QuestLog/QuestLog.layout.xml"),
    ("shop", "YuanbaoShop/YuanbaoShop.layout.xml"),
    ("system", "Operation/Operation.layout.xml"),
    ("system", "ViewSetup/ViewSetup.layout.xml"),
    ("system", "SoundSetup/SoundSetup.layout.xml"),
    ("system", "GameSetup/GameSetup.layout.xml"),
    ("system", "AcceSetup/AcceSetup.layout.xml"),
    ("skill", "ActionSkill/ActionSkill.layout.xml"),
    ("skill", "CommonSkill/CommonSkill.layout.xml"),
    ("skill", "LifeSkill/LifeSkill.layout.xml"),
    ("skill", "ZhenfaSkill/ZhenfaSkill.layout.xml"),
    ("skill", "AutoAttackSkill/AutoAttackSkill.layout.xml"),
    ("skill", "ZongMenSkill/ZongMenSkill.layout.xml"),
    ("social", "Pet/Pet.layout.xml"),
    ("social", "Friend/Friend.layout.xml"),
    ("social", "TeamFrame/TeamFrame.layout.xml"),
    ("hud", "DebugListBox/DebugListBox.layout.xml"),
    ("enter", "Logon/LogOn.layout.xml"),
    ("enter", "SelectRole/SelectRole.layout.xml"),
    ("enter", "CreateRole/CreateRole.layout.xml"),
    ("enter", "SoftKeyBoard/SoftKeyBoard.layout.xml"),
    ("enter", "SceneTrans/SceneTrans.layout.xml"),
]

SET_IMAGE = re.compile(r"set:(\S+)\s+image:(\S+)")
POS = re.compile(r"x:([-\d.]+)\s+y:([-\d.]+)")
SIZE = re.compile(r"w:([-\d.]+)\s+h:([-\d.]+)")


def prop(window: ET.Element, name: str) -> str:
    for child in window:
        if child.tag == "Property" and child.attrib.get("Name") == name:
            return child.attrib.get("Value", "")
    return ""


def place_of(window: ET.Element) -> tuple[str, str, str, str]:
    position = POS.search(prop(window, "AbsolutePosition"))
    size = SIZE.search(prop(window, "AbsoluteSize"))
    x = position.group(1) if position else ""
    y = position.group(2) if position else ""
    w = size.group(1) if size else ""
    h = size.group(2) if size else ""
    return x, y, w, h


def walk(window: ET.Element, rows: list[tuple[str, ...]]) -> None:
    name = window.attrib.get("Name", "")
    kind = window.attrib.get("Type", "")
    x, y, w, h = place_of(window)
    text = prop(window, "Text")
    if text:
        rows.append((name, kind, x, y, w, h, "Text", "", "", text))
    tip = prop(window, "Tooltip")
    if tip:
        rows.append((name, kind, x, y, w, h, "Tooltip", "", "", tip))
    for child in window:
        if child.tag != "Property":
            continue
        found = SET_IMAGE.search(child.attrib.get("Value", ""))
        if not found:
            continue
        rows.append((name, kind, x, y, w, h, child.attrib.get("Name", ""), found.group(1), found.group(2), ""))
    for child in window:
        if child.tag == "Window":
            walk(child, rows)


def read_imageset(path: Path) -> tuple[str, dict[str, tuple[str, str, str, str]]]:
    root = ET.parse(path).getroot()
    image_file = root.attrib.get("Imagefile", "")
    cells: dict[str, tuple[str, str, str, str]] = {}
    for image in root.findall("Image"):
        cells[image.attrib.get("Name", "")] = (
            image.attrib.get("XPos", ""),
            image.attrib.get("YPos", ""),
            image.attrib.get("Width", ""),
            image.attrib.get("Height", ""),
        )
    return image_file, cells


def load_atlases(interface: Path) -> dict[str, tuple[str, dict[str, tuple[str, str, str, str]]]]:
    # Client 2026 gom mọi bộ ảnh vào Schema/all.imageset.xml. File imageset lẻ chỉ là phần thêm.
    found: dict[str, tuple[str, dict[str, tuple[str, str, str, str]]]] = {}
    catalog = interface / "Schema" / "all.imageset.xml"
    if catalog.is_file():
        for imageset in ET.parse(catalog).getroot().findall("Imageset"):
            image_file = imageset.attrib.get("Imagefile", "")
            cells = {
                image.attrib.get("Name", ""): (
                    image.attrib.get("XPos", ""),
                    image.attrib.get("YPos", ""),
                    image.attrib.get("Width", ""),
                    image.attrib.get("Height", ""),
                )
                for image in imageset.findall("Image")
            }
            found[imageset.attrib.get("Name", "")] = (image_file, cells)
    for path in interface.rglob("*.imageset.xml"):
        if path.name == "all.imageset.xml":
            continue
        image_file, cells = read_imageset(path)
        name = path.name[: -len(".imageset.xml")]
        found.setdefault(name, (image_file, cells))
    return found


def write_tsv(path: Path, header: str, rows: list[tuple[str, ...]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [header, ""]
    for row in rows:
        lines.append("\t".join(row))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def collect(interface: Path, out: Path) -> tuple[int, int, int]:
    atlases = load_atlases(interface)
    used: dict[tuple[str, str], set[str]] = defaultdict(set)
    missing: list[str] = []
    screen_count = 0
    for group, relative in SCREENS:
        layout = interface / relative
        screen = Path(relative).name.removesuffix(".layout.xml")
        if not layout.is_file():
            missing.append(relative)
            continue
        rows: list[tuple[str, ...]] = []
        walk(ET.parse(layout).getroot(), rows)
        for row in rows:
            if row[7]:
                used[(row[7], row[8])].add(screen)
        write_tsv(
            out / "screen" / group / f"{screen}.tsv",
            "# cửa sổ, loại, x, y, w, h, thuộc tính, atlas, ảnh, chữ",
            rows,
        )
        screen_count += 1
    sheet_count = 0
    by_atlas: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for (imageset, image), screens in used.items():
        by_atlas[imageset].append((image, ",".join(sorted(screens))))
    for imageset, items in sorted(by_atlas.items()):
        image_file, cells = atlases.get(imageset, ("", {}))
        body: list[tuple[str, ...]] = []
        for image, screens in sorted(items):
            x, y, w, h = cells.get(image, ("", "", "", ""))
            body.append((image, x, y, w, h, image_file, screens))
        write_tsv(
            out / "sheet" / f"{imageset}.tsv",
            "# ảnh, x, y, w, h, tệp atlas, các màn dùng",
            body,
        )
        sheet_count += 1
    if missing:
        write_tsv(out / "missing.tsv", "# layout không thấy trong Interface gốc", [(item,) for item in missing])
    return screen_count, sheet_count, len(missing)


def main() -> int:
    parser = argparse.ArgumentParser(description="Gom thành phần 36 layout giao diện đang nạp.")
    parser.add_argument("interface", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    screens, sheets, missing = collect(args.interface, args.out)
    print(f"màn {screens}, atlas {sheets}, thiếu {missing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
