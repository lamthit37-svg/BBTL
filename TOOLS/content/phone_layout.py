"""Sinh layout điện thoại từ layout PC của client gốc.

Giữ nguyên tên cửa sổ, kiểu, ảnh, chữ và sự kiện. Chỉ nhân phần điểm ảnh của
vị trí và cỡ: số sau dấu phẩy trong Unified*, và x y w h của Absolute*.
Phần tỉ lệ (số trước dấu phẩy) giữ nguyên, nên cửa sổ vẫn neo trái, phải,
giữa hay đáy như bản PC. Hệ số 1.4 đưa nút 36 điểm ảnh lên 50, đủ để bấm tạm
trên điện thoại nằm ngang. Sau này thay từng tệp trong Interface/phone.

  python -B TOOLS/content/phone_layout.py
  python -B TOOLS/content/phone_layout.py "F:/tl 2026/_goc/Interface" dev/client/assets/Interface/phone
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Cùng danh sách hud.cpp nạp. Thiếu tệp gốc thì bỏ qua và in tên.
LAYOUTS = (
    "PlayerFrame/PlayerFrame.layout.xml",
    "MiniMap/MiniMap.layout.xml",
    "MainMenuBar/MainMenuBar.layout.xml",
    "MainMenuBar_2/MainMenuBar_2.layout.xml",
    "MainMenuBar_3/MainMenuBar_3.layout.xml",
    "MainMenuBar_4/MainMenuBar_4.layout.xml",
    "ChatFrame/ChatFrame.layout.xml",
    "PlayerImpactFrame/PlayerImpactFrame.layout.xml",
    "AutoAttack_Button/AutoAttack_Button.layout.xml",
    "FunctionBarRight/FunctionBarRight.layout.xml",
    "FunctionBarRight_2/FunctionBarRight_2.layout.xml",
    "ProgressBar/ProgressBar.layout.xml",
    "SelfEquip/SelfEquip.layout.xml",
    "Packet/Packet.layout.xml",
    "QuestLog/QuestLog.layout.xml",
    "YuanbaoShop/YuanbaoShop.layout.xml",
    "Operation/Operation.layout.xml",
    "ViewSetup/ViewSetup.layout.xml",
    "SoundSetup/SoundSetup.layout.xml",
    "GameSetup/GameSetup.layout.xml",
    "AcceSetup/AcceSetup.layout.xml",
    "ActionSkill/ActionSkill.layout.xml",
    "CommonSkill/CommonSkill.layout.xml",
    "LifeSkill/LifeSkill.layout.xml",
    "ZhenfaSkill/ZhenfaSkill.layout.xml",
    "AutoAttackSkill/AutoAttackSkill.layout.xml",
    "ZongMenSkill/ZongMenSkill.layout.xml",
    "Pet/Pet.layout.xml",
    "Friend/Friend.layout.xml",
    "TeamFrame/TeamFrame.layout.xml",
    "DebugListBox/DebugListBox.layout.xml",
    "Logon/LogOn.layout.xml",
    "SelectRole/SelectRole.layout.xml",
    "CreateRole/CreateRole.layout.xml",
    "SoftKeyBoard/SoftKeyBoard.layout.xml",
    "SceneTrans/SceneTrans.layout.xml",
)

FACTOR = 1.4
NOTE = (
    "<!-- Bản điện thoại tạm: cùng ảnh và kiểu PC, điểm ảnh nhân 1.4 cho ngón tay. -->\n"
)

PROPERTY = re.compile(
    r'(Name="(?:Unified(?:Position|Size|MaxSize|MinSize|AreaRect)|Absolute(?:Size|Position))"\s+Value=")([^"]*)(")'
)
PAIR = re.compile(r"\{([+-]?\d+(?:\.\d+)?),([+-]?\d+(?:\.\d+)?)\}")
ABSOLUTE = re.compile(r"\b([xywh]):([+-]?\d+(?:\.\d+)?)")
NAME = re.compile(r'\bName="([^"]+)"')


def scale_text(text: str) -> str:
    """Nhân một số, giữ số chữ số thập phân của bản gốc."""
    value = float(text) * FACTOR
    if "." not in text:
        rounded = round(value)
        if abs(value - rounded) < 1e-6:
            return str(int(rounded))
        return f"{value:.1f}"
    places = len(text.split(".", 1)[1])
    return f"{value:.{places}f}"


def scale_value(value: str) -> str:
    """Nhân offset và cỡ điểm ảnh. Không đụng hệ số tỉ lệ đứng trước dấu phẩy."""
    scaled = PAIR.sub(lambda match: "{" + match.group(1) + "," + scale_text(match.group(2)) + "}", value)
    return ABSOLUTE.sub(lambda match: match.group(1) + ":" + scale_text(match.group(2)), scaled)


def scale_layout(text: str) -> str:
    """Trả layout đã phóng cỡ, thêm một dòng chú thích ngay sau khai báo XML."""
    body = PROPERTY.sub(lambda match: match.group(1) + scale_value(match.group(2)) + match.group(3), text)
    marker = "?>"
    at = body.find(marker)
    if at < 0:
        return NOTE + body
    insert = at + len(marker)
    newline = 1 if body[insert : insert + 1] == "\n" else 0
    return body[: insert + newline] + NOTE + body[insert + newline :]


def window_names(text: str) -> list[str]:
    """Tên cửa sổ, theo thứ tự trong tệp."""
    return [match.group(1) for match in re.finditer(r'<Window\b[^>]*\bName="([^"]+)"', text)]


def write_one(source: Path, dest: Path) -> tuple[int, int]:
    """Ghi một layout. Trả số cửa sổ và số thuộc tính đã phóng."""
    original = source.read_text(encoding="utf-8-sig")
    scaled = scale_layout(original)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(scaled, encoding="utf-8", newline="\n")
    names = window_names(original)
    if names != window_names(scaled):
        raise SystemExit(f"lệch tên cửa sổ: {source}")
    changed = len(PROPERTY.findall(original))
    return len(names), changed


def main() -> int:
    source_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(r"F:\tl 2026\_goc\Interface")
    dest_root = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("dev/client/assets/Interface/phone")
    written = 0
    missing: list[str] = []
    windows = 0
    props = 0
    for relative in LAYOUTS:
        source = source_root / relative
        if not source.is_file():
            missing.append(relative)
            continue
        count, changed = write_one(source, dest_root / relative)
        windows += count
        props += changed
        written += 1
    print(f"ghi {written} layout, {windows} cửa sổ, {props} thuộc tính phóng {FACTOR}")
    for relative in missing:
        print(f"thiếu gốc: {relative}")
    return 0 if written else 1


if __name__ == "__main__":
    raise SystemExit(main())
