#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/phone_wireframe.py
#  PHÂN HỆ   : Content / Phone Wireframe
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Bản phác thảo giao diện điện thoại: tính cỡ tối thiểu từ số đo vật lý,
#    kiểm bố cục, vẽ khung SVG và PNG.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Bản phác thảo giao diện điện thoại: tính cỡ tối thiểu từ số đo vật lý, kiểm bố cục, vẽ khung SVG và PNG.

Mọi số của bản phác thảo nằm ở đây, một chỗ; docs/UI-DIEN-THOAI.md giải thích và trỏ về tệp này.
Đơn vị là điểm thiết kế (dp thiết kế): khung cao 1080, khít theo chiều cao màn (tỉ lệ = cao màn / 1080),
rộng 1920 ở 16:9 và dãn tới 2400 ở 20:9. Khung là vùng an toàn: tai thỏ, Dynamic Island, thanh cử chỉ
nằm ngoài nó.

  python -B TOOLS/content/phone_wireframe.py                 in bảng số và kiểm bố cục
  python -B TOOLS/content/phone_wireframe.py --out docs/ui-dien-thoai   ghi thêm SVG và PNG
"""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from pathlib import Path

DESIGN_HEIGHT = 1080
CORE_WIDTH = 1920
WIDE_WIDTH = 2400

# Máy tham chiếu nằm ngang: tên, đường chéo (inch), điểm ảnh dài, điểm ảnh ngắn.
DEVICES = (
    ("iPhone 15 6,1\" 19,5:9", 6.1, 2556, 1179),
    ("Android 6,7\" 20:9", 6.7, 2400, 1080),
    ("Android rẻ 6,5\" 20:9", 6.5, 1600, 720),
    ("Máy cũ 5,5\" 16:9", 5.5, 1920, 1080),
    ("Lenovo TB-X306F 10,1\" 16:10 (máy tính bảng)", 10.1, 1280, 800),
)

# Ngưỡng vật lý. Ô bấm: Android 48 dp ~ 7,6 mm, Apple 44 pt ~ 6,9 mm. Chữ: Android 12 sp ~ 1,9 mm là nhỏ nhất,
# chữ Hán cần lớn hơn chữ Latinh nên chữ thường lấy 2,2 mm.
TOUCH_MIN_MM = 7.0
GAP_MIN_MM = 1.9
TEXT_BODY_MM = 2.2
TEXT_SMALL_MM = 1.8
TEXT_TITLE_MM = 2.6

# Số đo của giao diện PC (layout của client 2026, điểm ảnh): ô hành động 40, nút kênh chat 17, nút minimap 25,
# nút khung nhân vật 22, phông 12, thanh máu cao 6. HUD PC cần khung tối thiểu 800 x 640.
PC_PARTS = (("ô hành động", 40), ("nút minimap", 25), ("nút khung nhân vật", 22), ("nút kênh chat", 17),
            ("chữ (phông 12)", 12), ("thanh máu", 6))
PC_FRAME_HEIGHT = 640


@dataclass(frozen=True)
class Part:
    key: str
    label: str
    anchor: str  # tl tc tr bl bc br: neo theo góc hay giữa của vùng an toàn
    x: float
    y: float
    w: float
    h: float
    kind: str  # touch: ô bấm; view: chỉ hiện; zone: vùng chạm động (cần gạt)
    round: bool = False


def short_edge_mm(diagonal: float, long_px: int, short_px: int) -> float:
    return diagonal * 25.4 * short_px / math.hypot(long_px, short_px)


def worst_mm_per_unit() -> float:
    # Điện thoại nhỏ nhất (cạnh ngắn ngắn nhất) quyết định: cùng số điểm thiết kế ra ít mm nhất ở đó.
    phones = [d for d in DEVICES if d[1] < 8.0]
    return min(short_edge_mm(d[1], d[2], d[3]) for d in phones) / DESIGN_HEIGHT


def units(mm: float, per_unit: float, step: int = 2) -> int:
    return int(math.ceil(mm / per_unit / step) * step)


def build_hud(touch: int) -> list[Part]:
    # Cụm phải: nút đánh ở giữa, bốn kỹ năng trên cung bán kính r. Dây cung giữa hai kỹ năng kề nhau
    # (2 r sin 15°) phải hơn đường kính kỹ năng cộng khe tối thiểu.
    attack_x, attack_y, attack_d, skill_d, radius = 1740.0, 880.0, 190.0, 140.0, 340.0
    parts = [
        Part("portrait", "Chân dung", "tl", 24, 24, 140, 140, "touch", True),
        Part("name", "Tên, cấp", "tl", 180, 28, 340, 44, "view"),
        Part("hp", "Máu", "tl", 180, 80, 340, 24, "view"),
        Part("mp", "Nội lực", "tl", 180, 112, 340, 18, "view"),
        Part("buff", "Trạng thái", "tl", 180, 138, 340, 36, "view"),
        Part("quest", "Nhiệm vụ (3 dòng)", "tl", 24, 210, 460, 3 * touch, "touch"),
        Part("quest_fold", "Thu gọn", "tl", 516, 210, touch, touch, "touch"),
        Part("target", "Mục tiêu", "tc", (CORE_WIDTH - 520) / 2, 24, 520, 130, "touch"),
        Part("menu", "Menu", "tr", 1504, 24, touch, touch, "touch"),
        Part("shop", "Shop", "tr", 1352, 24, touch, touch, "touch"),
        Part("minimap", "Bản đồ nhỏ", "tr", 1656, 24, 240, 240, "touch", True),
        Part("scene", "Tên cảnh, toạ độ", "tr", 1656, 272, 240, 40, "view"),
        Part("stick_zone", "Vùng cần gạt", "bl", 0, 602, 598, 478, "zone"),
        Part("stick", "Đế cần gạt", "bl", 140, 660, 320, 320, "view", True),
        Part("auto", "Tự đánh", "bl", 520, 640, touch, touch, "touch", True),
        Part("chat", "Chat", "bc", (CORE_WIDTH - 660) / 2, 820, 660, 200, "touch"),
        Part("exp", "Kinh nghiệm", "bc", 0, 1062, CORE_WIDTH, 12, "view"),
        Part("attack", "Đánh", "br", attack_x - attack_d / 2, attack_y - attack_d / 2, attack_d, attack_d, "touch",
             True),
        Part("jump", "Nhảy", "br", 1510, 930, touch, touch, "touch", True),
    ]
    for index, degrees in enumerate((180, 210, 240, 270)):
        angle = math.radians(degrees)
        cx = attack_x + radius * math.cos(angle)
        cy = attack_y + radius * math.sin(angle)
        parts.append(Part(f"skill{index + 1}", f"Kỹ năng {index + 1}", "br", round(cx - skill_d / 2, 1),
                          round(cy - skill_d / 2, 1), skill_d, skill_d, "touch", True))
    return parts


def build_panel(touch: int, spacing: int) -> list[Part]:
    # Bảng toàn màn (túi đồ làm mẫu): đầu bảng, cột thẻ bên trái, lưới ô 8 x 5. Ô cách nhau đúng khe tối thiểu.
    left, top, width, height = 160.0, 60.0, 1600.0, 960.0
    parts = [
        Part("panel", "Bảng mẫu: túi đồ", "tc", left, top, width, height, "view"),
        Part("title", "Tiêu đề", "tc", left + 32, top + 24, 600, 72, "view"),
        Part("close", "Đóng", "tc", left + width - 16 - touch, top + 8, touch, touch, "touch"),
    ]
    for row in range(5):
        parts.append(Part(f"tab{row + 1}", f"Thẻ {row + 1}", "tc", left + 24, top + 136 + row * (touch + spacing), 240,
                          touch, "touch"))
    slot, gap = float(touch), float(spacing)
    grid_left, grid_top = left + 24 + 240 + 48, top + 160
    for row in range(5):
        for col in range(8):
            parts.append(Part(f"slot{row}_{col}", "", "tc", grid_left + col * (slot + gap),
                              grid_top + row * (slot + gap), slot, slot, "touch"))
    return parts


def shifted(part: Part, frame_width: float) -> Part:
    extra = frame_width - CORE_WIDTH
    dx = {"tl": 0.0, "bl": 0.0, "tc": extra / 2, "bc": extra / 2, "tr": extra, "br": extra}[part.anchor]
    width = frame_width if part.key == "exp" else part.w
    x = 0.0 if part.key == "exp" else part.x + dx
    return Part(part.key, part.label, part.anchor, x, part.y, width, part.h, part.kind, part.round)


def gap_between(a: Part, b: Part) -> float:
    # Khoảng trống nhỏ nhất giữa hai hình; âm là chồng nhau. Tròn với tròn đo theo tâm, còn lại theo hộp bao.
    if a.round and b.round:
        distance = math.hypot((a.x + a.w / 2) - (b.x + b.w / 2), (a.y + a.h / 2) - (b.y + b.h / 2))
        return distance - a.w / 2 - b.w / 2
    dx = max(b.x - (a.x + a.w), a.x - (b.x + b.w))
    dy = max(b.y - (a.y + a.h), a.y - (b.y + b.h))
    if dx < 0 and dy < 0: return max(dx, dy)
    return math.hypot(max(dx, 0.0), max(dy, 0.0))


def check(parts: list[Part], frame_width: float, touch: int, gap: int, nested: set[tuple[str, str]]) -> list[str]:
    problems = []
    for part in parts:
        inside = part.x >= 0 and part.y >= 0 and part.x + part.w <= frame_width + 0.01
        inside = inside and part.y + part.h <= DESIGN_HEIGHT + 0.01
        if not inside: problems.append(f"{part.key}: ra ngoài khung {frame_width:.0f} x {DESIGN_HEIGHT}")
        if part.kind == "touch" and min(part.w, part.h) < touch:
            problems.append(f"{part.key}: ô bấm {part.w:.0f} x {part.h:.0f} nhỏ hơn {touch}")
    touches = [p for p in parts if p.kind == "touch"]
    for i, a in enumerate(touches):
        for b in touches[i + 1:]:
            if (a.key, b.key) in nested or (b.key, a.key) in nested: continue
            between = gap_between(a, b)
            if between < gap: problems.append(f"{a.key} và {b.key}: khe {between:.1f} < {gap}")
    return problems


def label_lines(part: Part) -> list[tuple[float, float, int, str]]:
    # Tên và cỡ, căn giữa hình. Ô thấp (thanh máu) ghi một dòng; còn lại tên một dòng, cỡ dòng dưới.
    if not part.label: return []
    size = 22
    cx = part.x + part.w / 2
    cy = part.y + part.h / 2
    dims = f"{part.w:.0f}x{part.h:.0f}"
    if part.h < 60: return [(cx, cy, size, f"{part.label} {dims}")]
    return [(cx, cy - 14, size, part.label), (cx, cy + 14, size, dims)]


COLOURS = {"touch": ("#2d6cdf", "#dbe7ff"), "view": ("#555555", "#eeeeee"), "zone": ("#2a9d55", "#e3f6e9")}


def svg_of(parts: list[Part], frame_width: float, caption: str) -> str:
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{frame_width:.0f}" height="{DESIGN_HEIGHT}" '
             f'viewBox="0 0 {frame_width:.0f} {DESIGN_HEIGHT}" font-family="Arial, sans-serif">',
             f'<rect width="{frame_width:.0f}" height="{DESIGN_HEIGHT}" fill="#fafafa" stroke="#000" stroke-width="4"/>',
             f'<text x="{frame_width / 2:.0f}" y="560" font-size="40" fill="#bbb" text-anchor="middle">{caption}</text>']
    order = sorted(parts, key=lambda p: {"zone": 0, "view": 1, "touch": 2}[p.kind])
    for part in order:
        stroke, fill = COLOURS[part.kind]
        dash = ' stroke-dasharray="16 10"' if part.kind == "zone" else ""
        if part.round:
            lines.append(f'<circle cx="{part.x + part.w / 2:.1f}" cy="{part.y + part.h / 2:.1f}" r="{part.w / 2:.1f}" '
                         f'fill="{fill}" fill-opacity="0.85" stroke="{stroke}" stroke-width="3"{dash}/>')
        else:
            lines.append(f'<rect x="{part.x:.1f}" y="{part.y:.1f}" width="{part.w:.1f}" height="{part.h:.1f}" '
                         f'fill="{fill}" fill-opacity="0.85" stroke="{stroke}" stroke-width="3"{dash}/>')
        for x, y, size, text in label_lines(part):
            lines.append(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{stroke}" text-anchor="middle" '
                         f'dominant-baseline="middle">{text}</text>')
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def png_of(parts: list[Part], frame_width: float, caption: str, path: Path) -> None:
    from PIL import Image, ImageDraw, ImageFont  # Pillow chỉ cần khi ghi PNG

    image = Image.new("RGB", (int(frame_width), DESIGN_HEIGHT), "#fafafa")
    draw = ImageDraw.Draw(image)
    font_file = Path("C:/Windows/Fonts/arial.ttf")
    big = ImageFont.truetype(str(font_file), 40) if font_file.is_file() else ImageFont.load_default()
    small = ImageFont.truetype(str(font_file), 22) if font_file.is_file() else ImageFont.load_default()
    draw.rectangle([0, 0, frame_width - 1, DESIGN_HEIGHT - 1], outline="#000", width=4)
    draw.text((frame_width / 2, 560), caption, fill="#bbb", font=big, anchor="mm")
    for part in sorted(parts, key=lambda p: {"zone": 0, "view": 1, "touch": 2}[p.kind]):
        stroke, fill = COLOURS[part.kind]
        box = [part.x, part.y, part.x + part.w, part.y + part.h]
        if part.round: draw.ellipse(box, fill=fill, outline=stroke, width=3)
        else: draw.rectangle(box, fill=fill, outline=stroke, width=3)
        for x, y, _, text in label_lines(part):
            draw.text((x, y), text, fill=stroke, font=small, anchor="mm")
    image.save(path)


def report(per_unit: float, touch: int, gap: int, sizes: dict[str, int]) -> None:
    print(f"1 điểm thiết kế = {per_unit:.4f} mm trên điện thoại nhỏ nhất (cạnh ngắn {per_unit * DESIGN_HEIGHT:.1f} mm)")
    print(f"ô bấm tối thiểu {touch}, khe tối thiểu {gap}; chữ: nhỏ {sizes['small']}, thường {sizes['body']}, "
          f"tiêu đề {sizes['title']}")
    print("Máy tham chiếu: cạnh ngắn mm, tỉ lệ điểm ảnh / điểm thiết kế")
    for name, diagonal, long_px, short_px in DEVICES:
        print(f"  {name}: {short_edge_mm(diagonal, long_px, short_px):.1f} mm, {short_px / DESIGN_HEIGHT:.3f}")
    print(f"Giao diện PC trên điện thoại, khít khung PC cao {PC_FRAME_HEIGHT} vào màn (lớn nhất có thể):")
    phone_mm = min(short_edge_mm(d[1], d[2], d[3]) for d in DEVICES if d[1] < 8.0) / PC_FRAME_HEIGHT
    tablet = DEVICES[-1]
    tablet_mm = short_edge_mm(tablet[1], tablet[2], tablet[3]) / tablet[3]
    for name, pixels in PC_PARTS:
        print(f"  {name} {pixels} px: điện thoại {pixels * phone_mm:.2f} mm, máy tính bảng 1:1 {pixels * tablet_mm:.2f} mm")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, help="thư mục ghi SVG và PNG")
    args = parser.parse_args()
    per_unit = worst_mm_per_unit()
    touch = units(TOUCH_MIN_MM, per_unit, 8)
    gap = units(GAP_MIN_MM, per_unit, 2)
    sizes = {"small": units(TEXT_SMALL_MM, per_unit), "body": units(TEXT_BODY_MM, per_unit),
             "title": units(TEXT_TITLE_MM, per_unit)}
    report(per_unit, touch, gap, sizes)
    hud = build_hud(touch)
    panel = build_panel(touch, gap)
    nested: set[tuple[str, str]] = set()
    sheets = {
        "hud-1920x1080": ([shifted(p, CORE_WIDTH) for p in hud], CORE_WIDTH, "HUD 16:9 - 1920 x 1080 (vùng an toàn)"),
        "hud-2400x1080": ([shifted(p, WIDE_WIDTH) for p in hud], WIDE_WIDTH, "HUD 20:9 - 2400 x 1080 (vùng an toàn)"),
        "panel-1920x1080": (panel, CORE_WIDTH, "Bảng toàn màn - mẫu túi đồ 8 x 5"),
    }
    failed = False
    for name, (parts, width, _) in sheets.items():
        problems = check(parts, width, touch, gap, nested)
        print(f"{name}: {'đạt' if not problems else str(len(problems)) + ' lỗi'}")
        for line in problems: print(f"  {line}")
        failed = failed or bool(problems)
    if args.out is not None:
        args.out.mkdir(parents=True, exist_ok=True)
        for name, (parts, width, caption) in sheets.items():
            (args.out / f"{name}.svg").write_text(svg_of(parts, width, caption), encoding="utf-8", newline="\n")
            png_of(parts, width, caption, args.out / f"{name}.png")
        print(f"đã ghi {len(sheets)} SVG và {len(sheets)} PNG vào {args.out}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
