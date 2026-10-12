# Làm ảnh nút tiếng Việt cho bảng đăng nhập: đặt chữ Việt lên đúng NỀN NÚT GỐC của client. Nút gốc
# có chữ Hán vẽ sẵn trong ảnh; thay cả nút bằng một nút vẽ kiểu khác thì nút lệch khung (góc bo, lề
# trong, viền khác), nên ở đây chỉ thay phần chữ: nền, viền và cỡ ô giữ nguyên từng điểm ảnh.
# Nguồn chữ là tấm nút chủ dự án vẽ (assets/i18n/vi/source/button_sheet.png, 1888x833): mỗi nút trên
# tấm đó cho một dòng chữ, tách khỏi nền của nó theo kênh xanh lục (chữ vàng kem, nền đỏ hay cam);
# vệt bóng sáng của nền nằm tách khỏi dòng chữ bị bỏ. Các nút cùng nhóm (ba thẻ, nút vào game) thu
# chữ theo cùng một tỉ lệ, là tỉ lệ của dòng dài nhất, để cỡ chữ các thẻ bằng nhau.
# Nền trống của nút gốc dựng lại từ atlas gốc (build/i18n/base, do build_i18n.py giữ): mỗi hàng của
# nền đều theo chiều ngang, nên lấy trung vị của các cột không có nét chữ rồi tô lại phần giữa.
# Ba thẻ dùng chung nền của thẻ mã QR (chữ ngắn nhất, hai đầu còn cột trống). Toạ độ trong bảng JOBS
# là ô THẬT của nút trong atlas; ô của bộ ảnh Logon_Erweima_Pushed khai lệch lên một hàng (118 thay
# vì 119), nên ảnh xuất cắt lại theo đúng ô của bộ ảnh từ atlas đã ghép: hàng chung của hai ô khớp
# nhau. Ghi các PNG mà assets/i18n/vi.tsv nêu.
# Chạy ở gốc dự án, sau khi đã dựng i18n ít nhất một lần:
#   python -B TOOLS/content/letter_buttons.py assets/i18n/vi/source/button_sheet.png build/i18n/base
#       assets/i18n/vi
# Mã thoát: 0 xong, 1 khi thiếu tệp hay một nút trên tấm nguồn không tách được chữ.
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

Box = tuple[int, int, int, int]

# Ngưỡng kênh xanh lục tách chữ khỏi nền của nút trên tấm nguồn: dưới low là nền, trên high là chữ.
MAROON = (80, 170)
ORANGE = (150, 215)
RED = (70, 160)
OUTLINE = (45, 12, 4)
OUTLINE_STRENGTH = 0.6
# Hai hàng có nét chữ cách nhau không quá chừng này hàng trống thì còn thuộc một dòng chữ (dấu thanh,
# dấu nặng nằm rời nét chính).
ROW_GAP = 6


# Nền trống của một nút gốc: ô trong atlas, các cột không có nét chữ, và vùng phải tô lại.
@dataclass(frozen=True)
class Plate:
    atlas: str
    box: Box
    clean_columns: tuple[int, ...]
    fill: Box


# Một ảnh nút cần làm: ô thật của nút, ô của bộ ảnh để cắt ra tệp, nền, nút nguồn trên tấm chữ.
@dataclass(frozen=True)
class Job:
    file: str
    true_top: int
    region_top: int
    plate: str
    sheet_box: Box
    key: tuple[int, int]


TAB_CLEAN = (3, 4, 5, 6, 7, 8, 80, 81, 82, 83, 84)
GAME_CLEAN = tuple(range(13, 26))
TAB_ATLAS = "Common/CommonFrame28.tga.png"
GAME_ATLAS = "Common/CommonFrame18.tga.png"
TAB_LEFT = 298
GAME_LEFT = 306
TAB_SIZE = (88, 17)
GAME_SIZE = (132, 54)
# Chữ nằm trong ô này của nút (trái, trên, rộng, cao), canh giữa.
TAB_TEXT: Box = (2, 1, 84, 15)
GAME_TEXT: Box = (18, 17, 96, 20)

PLATES = {
    "tab_normal": Plate(TAB_ATLAS, (TAB_LEFT, 102, *TAB_SIZE), TAB_CLEAN, (3, 0, 82, 17)),
    "tab_pushed": Plate(TAB_ATLAS, (TAB_LEFT, 119, *TAB_SIZE), TAB_CLEAN, (3, 0, 82, 17)),
    "tab_hover": Plate(TAB_ATLAS, (TAB_LEFT, 136, *TAB_SIZE), TAB_CLEAN, (3, 0, 82, 17)),
    "game_normal": Plate(GAME_ATLAS, (GAME_LEFT, 0, *GAME_SIZE), GAME_CLEAN, (13, 15, 107, 23)),
    "game_hover": Plate(GAME_ATLAS, (GAME_LEFT, 54, *GAME_SIZE), GAME_CLEAN, (13, 15, 107, 23)),
    "game_pushed": Plate(GAME_ATLAS, (GAME_LEFT, 108, *GAME_SIZE), GAME_CLEAN, (13, 15, 107, 23)),
}

# Ô của từng nút trên tấm nguồn (trái, trên, rộng, cao), đo bằng vùng alpha liền nhau.
JOBS = (
    Job("Logon_Houzhui_Normal.png", 0, 0, "tab_normal", (176, 95, 294, 64), MAROON),
    Job("Logon_Houzhui_Pushed.png", 17, 17, "tab_pushed", (1086, 95, 307, 64), ORANGE),
    Job("Logon_Houzhui_Hover.png", 34, 34, "tab_hover", (630, 95, 305, 64), MAROON),
    Job("Logon_EnterHouzhui_Normal.png", 51, 51, "tab_normal", (181, 357, 326, 65), MAROON),
    Job("Logon_EnterHouzhui_Pushed.png", 68, 68, "tab_pushed", (1089, 357, 332, 65), ORANGE),
    Job("Logon_EnterHouzhui_Hover.png", 85, 85, "tab_hover", (640, 357, 326, 65), MAROON),
    Job("Logon_Erweima_Normal.png", 102, 102, "tab_normal", (176, 223, 294, 63), MAROON),
    Job("Logon_Erweima_Pushed.png", 119, 118, "tab_pushed", (1088, 223, 306, 63), ORANGE),
    Job("Logon_Erweima_Hover.png", 136, 136, "tab_hover", (631, 223, 301, 63), MAROON),
    Job("EnterGame_Normal.png", 0, 0, "game_normal", (91, 607, 402, 162), RED),
    Job("EnterGame_Hover.png", 54, 54, "game_hover", (527, 607, 400, 162), RED),
    Job("EnterGame_Pushed.png", 108, 108, "game_pushed", (958, 607, 401, 162), RED),
)


class LetterError(Exception):
    """Thiếu tệp nguồn hoặc không tách được chữ của một nút."""


def crop(pixels: np.ndarray, box: Box) -> np.ndarray:
    left, top, width, height = box
    return pixels[top:top + height, left:left + width]


# Nền trống: giữ nguyên ô gốc, riêng vùng fill tô lại mỗi hàng bằng trung vị của các cột sạch.
def blank_plate(atlas: np.ndarray, plate: Plate) -> np.ndarray:
    cell = crop(atlas, plate.box).copy()
    left, top, width, height = plate.fill
    rows = cell[top:top + height]
    clean = rows[:, list(plate.clean_columns)].astype(np.float32)
    row_colour = np.median(clean, axis=1).round().astype(np.uint8)
    rows[:, left:left + width] = row_colour[:, None, :]
    return cell


# Dải hàng của dòng chữ: dải cao nhất trong các dải hàng có nét, hai dải cách nhau quá ROW_GAP hàng
# trống là hai thứ khác nhau (dòng chữ và vệt bóng của nền).
def text_rows(rows: np.ndarray) -> tuple[int, int]:
    marks = np.unique(rows)
    breaks = np.where(np.diff(marks) > ROW_GAP)[0]
    starts = np.concatenate(([0], breaks + 1))
    ends = np.concatenate((breaks, [marks.size - 1]))
    tallest = int(np.argmax(marks[ends] - marks[starts]))
    return int(marks[starts[tallest]]), int(marks[ends[tallest]])


# Chữ của một nút trên tấm nguồn: lớp RGBA cắt sát chữ. Nút vào game có khung vàng cùng tông với chữ
# nên chỉ xét phần lõi của nút.
def lettering(sheet: np.ndarray, job: Job) -> Image.Image:
    cell = crop(sheet, job.sheet_box).astype(np.float32)
    height, width = cell.shape[:2]
    is_framed = job.key == RED
    margin_x = width // 6 if is_framed else width // 20
    margin_y = height // 4 if is_framed else height // 8
    core = cell[margin_y:height - margin_y, margin_x:width - margin_x]
    low, high = job.key
    cover = np.clip((core[:, :, 1] - low) / (high - low), 0.0, 1.0)
    cover = cover * cover * (3.0 - 2.0 * cover)
    solid = np.argwhere(cover > 0.5)
    if solid.size == 0:
        raise LetterError(f"{job.file}: không thấy chữ trong ô {job.sheet_box} của tấm nguồn")
    top, bottom = text_rows(solid[:, 0])
    in_line = solid[(solid[:, 0] >= top) & (solid[:, 0] <= bottom)]
    left, right = int(in_line[:, 1].min()), int(in_line[:, 1].max())
    layer = np.dstack([core[:, :, :3], cover * 255.0])[top:bottom + 1, left:right + 1]
    return Image.fromarray(layer.round().astype(np.uint8))


def room_of(job: Job) -> Box:
    return GAME_TEXT if PLATES[job.plate].atlas == GAME_ATLAS else TAB_TEXT


# Tỉ lệ thu chữ của mỗi nhóm nút (nhóm là các nút cùng ô chữ): dòng dài hay cao nhất của nhóm vừa ô.
def group_scales(cut: dict[str, Image.Image]) -> dict[Box, float]:
    scales: dict[Box, float] = {}
    for job in JOBS:
        room = room_of(job)
        letters = cut[job.file]
        fit = min(room[2] / letters.width, room[3] / letters.height)
        scales[room] = min(scales.get(room, fit), fit)
    return scales


# Thu chữ theo tỉ lệ của nhóm, qua alpha nhân sẵn để mép chữ không viền màu nền.
def shrunk(letters: Image.Image, scale: float) -> Image.Image:
    size = (max(round(letters.width * scale), 1), max(round(letters.height * scale), 1))
    return letters.convert("RGBa").resize(size, Image.LANCZOS).convert("RGBA")


def over(top: np.ndarray, under: np.ndarray) -> np.ndarray:
    top_alpha = top[:, :, 3:4] / 255.0
    under_alpha = under[:, :, 3:4] / 255.0
    alpha = top_alpha + under_alpha * (1.0 - top_alpha)
    colour = top[:, :, :3] * top_alpha + under[:, :, :3] * under_alpha * (1.0 - top_alpha)
    colour = np.divide(colour, alpha, out=np.zeros_like(colour), where=alpha > 0.0)
    return np.dstack([colour, alpha * 255.0])


# Đặt chữ đã thu vào giữa ô chữ của nền, có viền sẫm một điểm ảnh quanh nét cho dễ đọc.
def lettered(plate: np.ndarray, letters: Image.Image, room: Box) -> np.ndarray:
    height, width = plate.shape[:2]
    layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    left = room[0] + (room[2] - letters.width) // 2
    top = room[1] + (room[3] - letters.height) // 2
    layer.paste(letters, (left, top))
    spread = layer.getchannel("A").filter(ImageFilter.MaxFilter(3))
    edge = np.zeros((height, width, 4), dtype=np.float32)
    edge[:, :, :3] = OUTLINE
    edge[:, :, 3] = np.asarray(spread, dtype=np.float32) * OUTLINE_STRENGTH
    under = over(edge, plate.astype(np.float32))
    return over(np.asarray(layer, dtype=np.float32), under).round().astype(np.uint8)


def read_rgba(path: Path) -> np.ndarray:
    if not path.is_file():
        raise LetterError(f"không có tệp {path}")
    with Image.open(path) as picture:
        return np.asarray(picture.convert("RGBA")).copy()


def make(sheet_path: Path, base: Path, out: Path) -> int:
    sheet = read_rgba(sheet_path)
    atlases = {name: read_rgba(base / name) for name in (TAB_ATLAS, GAME_ATLAS)}
    blanks = {name: blank_plate(atlases[plate.atlas], plate) for name, plate in PLATES.items()}
    cut = {job.file: lettering(sheet, job) for job in JOBS}
    scales = group_scales(cut)
    for job in JOBS:
        plate = PLATES[job.plate]
        room = room_of(job)
        letters = shrunk(cut[job.file], scales[room])
        left, _, width, height = plate.box
        target = atlases[plate.atlas]
        target[job.true_top:job.true_top + height, left:left + width] = lettered(blanks[job.plate], letters, room)
    out.mkdir(parents=True, exist_ok=True)
    for job in JOBS:
        plate = PLATES[job.plate]
        left, _, width, height = plate.box
        region = crop(atlases[plate.atlas], (left, job.region_top, width, height))
        Image.fromarray(region).save(out / job.file)
    print(f"letter_buttons: ghi {len(JOBS)} ảnh nút vào {out}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Đặt chữ Việt lên nền nút gốc của bảng đăng nhập.")
    parser.add_argument("sheet", help="tấm nút tiếng Việt nguồn (button_sheet.png)")
    parser.add_argument("base", help="thư mục atlas gốc do build_i18n.py giữ (build/i18n/base)")
    parser.add_argument("out", help="thư mục ghi ảnh nút (assets/i18n/vi)")
    args = parser.parse_args(argv)
    try:
        return make(Path(args.sheet), Path(args.base), Path(args.out))
    except LetterError as error:
        print(f"Lỗi letter_buttons: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
