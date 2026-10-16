# Làm ảnh nút, tiêu đề và nhãn tiếng Việt bằng PHÔNG CHỮ: xoá chữ Hán vẽ sẵn trong ảnh gốc của client
# rồi vẽ chữ Việt lên đúng nền đó, mọi ảnh cùng một phông, một bảng màu và một cách viền. Nền, viền,
# khung và cỡ ô giữ nguyên từng điểm ảnh ngoài vùng chữ. Khác letter_buttons.py (lấy chữ từ tấm nút
# chủ dự án vẽ, chỉ có các dòng của bảng đăng nhập): ở đây chữ dựng từ phông Merienda Bold, phông có
# nét trùng với chữ của tấm nút đó (assets/i18n/vi/source/NGUON.txt), nên nhãn mới nào cũng làm được.
# Bảng việc là labels.tsv cạnh tệp phông: mỗi dòng "bộ ảnh<tab>tên ảnh<tab>loại<tab>chữ". Chữ có dấu
# "|" là hai dòng (câu đối); chữ "@<khoá>" lấy câu đầu của chuỗi <khoá> trong tệp i18n (phần trước
# "#r", bỏ thẻ màu), tách hai vế ở dấu phẩy, để câu đối chỉ viết một nơi.
# Loại (bảng KINDS) nói cách xoá chữ cũ, ô chữ mới và nhóm cỡ chữ:
#   span  tô lại cả ô xoá, mỗi hàng nối thẳng màu của hai mép ô (nền nút đều theo chiều ngang);
#   mask  chỉ tô lại điểm ảnh chữ (kênh lục cao) và viền quanh nó, nối theo hàng (vệt mực môn phái);
#         có ô thì chỉ xét điểm ảnh trong ô đó, để hoa văn sáng màu ở ngoài không bị coi là chữ;
#   wipe  xoá sạch thành trong suốt (nhãn và câu đối không có nền).
# Mọi ảnh cùng nhóm dùng chung một cỡ chữ: cỡ lớn nhất mà mọi dòng của nhóm còn vừa ô của nó. Thân
# chữ hoa nằm giữa ô; dòng nào có dấu chồng hay nét thòng chạm mép ô thì riêng dòng đó dời vừa đủ.
# Màu chữ theo đuôi tên ảnh (_Normal, _Hover, _Pushed, _Disabled).
# Ảnh gốc đọc từ <state>/base (bản build_i18n.py giữ khi atlas đã bị thay) rồi mới tới CLIENT/data:
# chạy lại bao nhiêu lần cũng xoá chữ từ nền gốc, không từ ảnh đã có chữ Việt.
# Chạy ở gốc dự án:
#   python -B TOOLS/content/letter_labels.py assets/i18n/vi/source/labels.tsv CLIENT/data build/i18n
#       assets/i18n/vi [--sheet <tệp.png>] [--sync]
# Ghi <out>/labels/<bộ ảnh>.<tên ảnh>.png. --sheet ghi tấm so từng cặp ảnh gốc và ảnh mới (phóng 2 lần).
# Tệp i18n (<out>.tsv) phải có dòng "image/..." cho từng ảnh, nằm giữa hai dòng mốc ROWS_OPEN và
# ROWS_CLOSE: --sync ghi lại khối đó theo bảng việc; không có --sync thì khối lệch bảng việc là lỗi.
# Mã thoát: 0 xong, 1 khi thiếu tệp, sai bảng việc, chữ không vừa ô hay khối dòng của tệp i18n lệch.
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

import export_layout_images

Box = tuple[int, int, int, int]

FONT_FILE = "Merienda-Bold.ttf"
OUT_FOLDER = "labels"
# Hai dòng mốc trong tệp i18n; các dòng giữa chúng do công cụ này ghi.
ROWS_OPEN = "# >>> letter_labels: khối dưới do TOOLS/content/letter_labels.py --sync ghi theo source/labels.tsv, không sửa tay."
ROWS_CLOSE = "# <<< letter_labels"
# Chữ vẽ ở cỡ gấp SCALE lần rồi thu về, để nét và viền mịn ở cỡ 10 đến 17 điểm ảnh.
SCALE = 4
SIZE_STEP = 0.25
# Nút la bàn và nút 17 điểm chỉ còn chỗ cho cỡ 6; nhóm khác vẫn đứng ở cỡ trần của nhóm.
SMALLEST_SIZE = 6.0
# Viền sẫm quanh nét (điểm ảnh cuối) và bóng đổ xuống dưới.
OUTLINE_REACH = 1.0
SHADOW_DROP = 1.0
SHADOW_BLUR = 0.7
SHADOW_STRENGTH = 0.55
# Điểm ảnh chữ của ảnh gốc loại mask: kênh lục cao (chữ vàng), mực đen và mực đỏ đều có lục thấp.
MASK_GREEN = 70
MASK_ALPHA = 48
MASK_GROW = 2
# Bóng đổ của chữ gốc trên mực đỏ: điểm tối (kênh đỏ thấp) cách nét chữ không quá SHADOW_REACH điểm.
SHADOW_RED = 78
SHADOW_REACH = 5
# Số cột ngoài mỗi mép ô xoá lấy làm màu của mép (trung vị, cho khỏi dính một điểm ảnh lạ).
EDGE_COLUMNS = 3
# Thẻ màu của chuỗi giao diện. "#r" (chữ thường) là xuống dòng, không phải thẻ màu.
TAG = re.compile(r"#c[0-9a-fA-F]{6}|#[GYWRBgywb]")


# Màu chữ của một trạng thái: trên và dưới của dải màu dọc thân chữ, và màu viền.
@dataclass(frozen=True)
class Tone:
    top: tuple[int, int, int]
    bottom: tuple[int, int, int]
    edge: tuple[int, int, int]
    edge_strength: float


TONES = {
    "normal": Tone((255, 241, 188), (238, 186, 88), (45, 12, 4), 0.9),
    "hover": Tone((255, 251, 222), (255, 216, 124), (45, 12, 4), 0.9),
    "pushed": Tone((228, 203, 146), (192, 143, 64), (30, 8, 3), 0.9),
    "disabled": Tone((206, 206, 206), (142, 142, 142), (16, 16, 16), 0.9),
    # Nhãn chữ trần nằm thẳng trên cảnh 3D, cỡ chỉ chừng 10 điểm: gần trắng và viền đặc cho khỏi chìm.
    "label": Tone((255, 252, 232), (255, 232, 160), (18, 5, 2), 1.0),
}
STATE_OF_SUFFIX = {"Normal": "normal", "Hover": "hover", "Pushed": "pushed", "Disabled": "disabled", "Disable": "disabled"}


# Một loại ảnh: cách xoá chữ cũ, ô xoá (span), các ô chữ mới (một ô mỗi dòng) kèm cách canh, nhóm cỡ
# chữ và cỡ lớn nhất. selected_tone: màu của ảnh _Pushed khi nó là "đang chọn" chứ không phải "đang
# nhấn". pad: khoảng chừa trên và dưới chữ cho viền; nhãn cao 13 điểm ảnh không còn chỗ nên để 0.
# tone: màu cố định của loại, thắng màu theo đuôi tên ảnh. green: ngưỡng kênh lục của điểm ảnh chữ
# gốc cho cách xoá mask (nền càng sáng thì ngưỡng càng cao).
@dataclass(frozen=True)
class Kind:
    clean: str
    box: Box | None
    rooms: tuple[Box, ...]
    aligns: tuple[str, ...]
    group: str
    size: float
    selected_tone: str = "pushed"
    pad: float = OUTLINE_REACH
    tone: str = ""
    green: int = MASK_GREEN


KINDS = {
    # Vệt mực của nút môn phái (150 x 40, 163 x 40): chữ bắt đầu ở cùng một cột như một danh sách.
    "ink": Kind("mask", None, ((22, 3, 112, 34),), ("left",), "ink", 17.0, "hover"),
    # Nút khung vàng nền đỏ 132 x 54 và 132 x 55.
    "big": Kind("span", (16, 18, 100, 19), ((15, 17, 102, 21),), ("centre",), "big", 14.0),
    # Nút dẹt 111 x 18 và 53 x 18.
    # Nền đỏ của chúng chỉ cao 11 điểm, không chứa nổi dấu chồng: ô chữ lấy cả chiều cao ảnh, dấu và
    # nét thòng được phép lấn lên viền nút.
    "random": Kind("span", (8, 3, 95, 11), ((6, 0, 99, 18),), ("centre",), "small", 11.5, pad=0.5),
    "page": Kind("span", (6, 3, 41, 11), ((5, 0, 43, 18),), ("centre",), "small", 11.5, pad=0.5),
    # Dải tiêu đề đỏ 207 x 46 (cả phần đầu của nền bảng tạo) và 219 x 44.
    "ribbon": Kind("span", (62, 12, 84, 23), ((30, 11, 147, 25),), ("centre",), "ribbon", 14.5),
    "ribbon_wide": Kind("span", (70, 12, 84, 23), ((30, 11, 159, 25),), ("centre",), "ribbon", 14.5),
    # Dải tên 120 x 20.
    "name": Kind("span", (22, 0, 78, 20), ((4, 0, 112, 17),), ("centre",), "name", 12.0),
    # Nhãn chữ trần 59 x 13 và 89 x 13.
    # Nhãn 59 x 13 đứng đầu một hàng nút nên sát trái; nhãn 89 x 13 nằm giữa, trên hai nút giới.
    "label": Kind("wipe", None, ((0, 0, 59, 13),), ("left",), "label", 10.5, pad=0.0, tone="label"),
    "label_wide": Kind("wipe", None, ((0, 0, 89, 13),), ("centre",), "label", 10.5, pad=0.0, tone="label"),
    # Câu đối 184 x 44, hai vế canh giữa. Khác gốc: ảnh gốc để vế trên sát trái, vế dưới sát phải (hai
    # vế bảy chữ dài bằng nhau); hai vế tiếng Việt dài ngắn khác nhau, so le thì trông như lệch.
    "verse": Kind("wipe", None, ((4, 1, 176, 21), (4, 22, 176, 21)), ("centre", "centre"), "verse", 13.5),
    # Dòng chú dưới ô tên cảnh của tấm chuyển cảnh 256 x 256: chữ trắng trên dải đồng.
    "trans": Kind("mask", (66, 212, 124, 17), ((60, 210, 136, 19),), ("centre",), "trans", 12.0, green=105),
    # Thẻ đăng nhập 88 x 17 (chọn hậu tố, tự nhập, mã QR).
    "tab": Kind("span", (4, 2, 76, 13), ((2, 0, 84, 17),), ("centre",), "tab", 9.0, pad=0.0),
    # Thẻ đăng nhập cũ 130 x 22.
    "mail": Kind("span", (6, 3, 114, 15), ((4, 1, 122, 20),), ("centre",), "mail", 11.0, pad=0.2),
    # Nút quà 103 x 29 và 90 x 28 trên khung nhân vật.
    "gift": Kind("span", (8, 5, 84, 18), ((4, 2, 95, 24),), ("centre",), "gift", 11.0, pad=0.2),
    "card": Kind("span", (6, 4, 76, 18), ((4, 2, 82, 24),), ("centre",), "card", 11.0, pad=0.2),
    # Nút an toàn 50 x 25, nạp/đổi 43 x 21, tự tìm đường 70 x 23.
    "safe": Kind("span", (4, 4, 40, 16), ((2, 2, 46, 21),), ("centre",), "safe", 9.0, pad=0.0),
    "pay": Kind("span", (4, 3, 33, 14), ((2, 1, 39, 19),), ("centre",), "pay", 9.0, pad=0.0),
    "seek": Kind("span", (4, 3, 60, 16), ((2, 1, 66, 21),), ("centre",), "seek", 10.0, pad=0.0),
    # Nút tròn một chữ. Ô mask nằm trong lòng để viền vàng còn nguyên; ô chữ rộng hơn cho từ Việt.
    "comm": Kind("mask", (6, 6, 13, 14), ((3, 2, 19, 22),), ("centre",), "comm", 10.0, pad=0.0, green=160),
    "shortcut": Kind("mask", (5, 5, 12, 12), ((2, 2, 18, 18),), ("centre",), "shortcut", 9.0, pad=0.0, green=160),
    "board": Kind("mask", (6, 6, 15, 16), ((2, 3, 23, 22),), ("centre",), "board", 9.0, pad=0.0, green=160),
    "fight": Kind("mask", (8, 6, 16, 18), ((2, 2, 28, 26),), ("centre",), "fight", 10.0, pad=0.0, green=210),
    "north": Kind("mask", (2, 3, 11, 16), ((0, 1, 15, 20),), ("centre",), "north", 8.0, pad=0.0, green=140),
    "line": Kind("mask", (6, 6, 15, 16), ((2, 3, 23, 22),), ("centre",), "line", 9.0, pad=0.0, green=200),
    "near": Kind("mask", (3, 3, 11, 11), ((1, 1, 15, 15),), ("centre",), "near", 7.0, pad=0.0, green=160),
    # Áp phích nút: chỉ xoá dải chữ vàng ở đáy, giữ hình túi và bộ bài.
    "poster": Kind("mask", (8, 48, 62, 26), ((4, 46, 70, 28),), ("centre",), "poster", 12.0, pad=0.0, green=200),
    "reward": Kind("mask", (4, 40, 51, 22), ((2, 40, 55, 22),), ("centre",), "reward", 11.0, pad=0.0, green=170),
    # Biển gỗ 86 x 27 của sổ môn phái: xoá chữ giữa, giữ mép gỗ.
    "plaque": Kind("span", (12, 6, 62, 15), ((8, 1, 70, 25),), ("centre",), "plaque", 11.0, pad=0.0),
    # Áp phích 62 x 78, chữ nằm ở đáy.
    "fair": Kind("mask", (4, 50, 54, 24), ((2, 48, 58, 26),), ("centre",), "fair", 11.0, pad=0.0, green=200),
    # Khiên chữ 帮 64 x 64. Chỉ xoá lòng khiên.
    "crest": Kind("mask", (20, 16, 24, 28), ((14, 14, 36, 34),), ("centre",), "crest", 12.0, pad=0.0, green=150),
}


class LabelError(Exception):
    """Bảng việc sai, thiếu tệp, chữ không vừa ô hay tệp i18n thiếu dòng."""


@dataclass(frozen=True)
class Job:
    imageset: str
    image: str
    kind: str
    lines: tuple[str, ...]

    @property
    def file(self) -> str:
        return f"{OUT_FOLDER}/{self.imageset}.{self.image}.png"

    @property
    def row_key(self) -> str:
        return f"image/{self.imageset}/{self.image}"


def read_table(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise LabelError(f"không có tệp {path}")
    rows: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").split("\n"):
        key, tab, value = line.partition("\t")
        if tab and not key.startswith("# "):
            rows[key] = value
    return rows


# Câu đầu của một chuỗi i18n thành hai vế: bỏ thẻ màu, lấy phần trước "#r", bỏ dấu chấm cuối.
def verse_lines(words: dict[str, str], key: str, where: str) -> tuple[str, ...]:
    if key not in words:
        raise LabelError(f"{where}: tệp i18n không có khoá {key}")
    first = TAG.sub("", words[key]).split("#r", 1)[0].strip().rstrip(".")
    halves = [half.strip() for half in first.split(",", 1)]
    if len(halves) != 2 or not all(halves):
        raise LabelError(f"{where}: chuỗi {key} không tách được hai vế ở dấu phẩy: {first!r}")
    return halves[0][:1].upper() + halves[0][1:], halves[1][:1].upper() + halves[1][1:]


def read_jobs(path: Path, words: dict[str, str]) -> list[Job]:
    if not path.is_file():
        raise LabelError(f"không có tệp {path}")
    jobs: list[Job] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").split("\n"), 1):
        if not line.strip() or line.startswith("#"):
            continue
        where = f"{path.name}:{number}"
        fields = line.split("\t")
        if len(fields) != 4 or not all(fields):
            raise LabelError(f"{where}: cần bốn cột bộ ảnh, tên ảnh, loại, chữ")
        imageset, image, kind, text = fields
        if kind not in KINDS:
            raise LabelError(f"{where}: loại {kind!r} không có trong KINDS")
        lines = verse_lines(words, text[1:], where) if text.startswith("@") else tuple(text.split("|"))
        if len(lines) != len(KINDS[kind].rooms):
            raise LabelError(f"{where}: loại {kind} cần {len(KINDS[kind].rooms)} dòng chữ, có {len(lines)}")
        jobs.append(Job(imageset, image, kind, lines))
    if not jobs:
        raise LabelError(f"{path}: không có việc nào")
    return jobs


def tone_of(job: Job) -> Tone:
    if KINDS[job.kind].tone:
        return TONES[KINDS[job.kind].tone]
    suffix = job.image.rsplit("_", 1)[-1]
    state = STATE_OF_SUFFIX.get(suffix, "normal")
    if state == "pushed":
        state = KINDS[job.kind].selected_tone
    return TONES[state]


# Ảnh gốc của một atlas: bản build_i18n.py giữ nếu có, không thì bản đang triển khai (chưa bị thay).
def read_atlas(data: Path, state: Path, atlas: str) -> np.ndarray:
    kept = state / "base" / (atlas + ".png")
    path = kept if kept.is_file() else data / "Interface" / (atlas + ".png")
    if not path.is_file():
        source = data / "Interface" / atlas
        if not source.is_file():
            raise LabelError(f"không có atlas {path}")
        # collect_ui chưa giải atlas này. Giải một lần để vá chữ và để client đọc PNG.
        sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "glb"))
        import texture
        path.parent.mkdir(parents=True, exist_ok=True)
        texture.convert_to_png(str(source), str(path))
    with Image.open(path) as picture:
        return np.asarray(picture.convert("RGBA")).astype(np.float32)


def premultiplied(pixels: np.ndarray) -> np.ndarray:
    out = pixels.copy()
    out[:, :, :3] *= out[:, :, 3:4] / 255.0
    return out


def straight(pixels: np.ndarray) -> np.ndarray:
    out = pixels.copy()
    alpha = out[:, :, 3:4] / 255.0
    np.divide(out[:, :, :3], alpha, out=out[:, :, :3], where=alpha > 0.0)
    return out


# Tô lại cả ô box: mỗi hàng chạy thẳng từ màu mép trái sang màu mép phải (trung vị của EDGE_COLUMNS
# cột ngay ngoài ô). Nền nút và dải tiêu đề đều theo chiều ngang nên vân dọc của chúng còn nguyên.
def clean_span(cell: np.ndarray, box: Box) -> np.ndarray:
    left, top, width, height = box
    if left < EDGE_COLUMNS or left + width + EDGE_COLUMNS > cell.shape[1] or top + height > cell.shape[0]:
        raise LabelError(f"ô xoá {box} không nằm trọn trong ảnh {cell.shape[1]} x {cell.shape[0]}")
    work = premultiplied(cell)
    rows = work[top:top + height]
    start = np.median(rows[:, left - EDGE_COLUMNS:left], axis=1)
    finish = np.median(rows[:, left + width:left + width + EDGE_COLUMNS], axis=1)
    blend = ((np.arange(width, dtype=np.float32) + 1.0) / (width + 1.0))[None, :, None]
    rows[:, left:left + width] = start[:, None, :] * (1.0 - blend) + finish[:, None, :] * blend
    return straight(work)


# Tô lại riêng điểm ảnh chữ của vệt mực: mặt nạ là điểm có kênh lục cao, nở MASK_GROW điểm để gồm cả
# viền chữ, cộng các điểm tối quanh chữ (bóng đổ; trên mực đen là chính mực, tô lại vẫn ra mực). Mỗi
# đoạn mặt nạ trên một hàng nối thẳng màu của hai điểm sạch kề nó (một đầu chạm mép ảnh thì lấy màu
# đầu kia). Làm trên màu đã nhân alpha nên hình vệt mực cũng liền lại.
def clean_mask(cell: np.ndarray, kind: Kind) -> np.ndarray:
    is_text = (cell[:, :, 1] > kind.green) & (cell[:, :, 3] > MASK_ALPHA)
    if kind.box is not None:
        left, top, width, height = kind.box
        inside = np.zeros_like(is_text)
        inside[top:top + height, left:left + width] = True
        is_text &= inside
    drawn = Image.fromarray((is_text * 255).astype(np.uint8))
    near = np.asarray(drawn.filter(ImageFilter.MaxFilter(2 * SHADOW_REACH + 1))) > 0
    is_shadow = near & (cell[:, :, 0] < SHADOW_RED) & (cell[:, :, 3] > MASK_ALPHA)
    mask = (np.asarray(drawn.filter(ImageFilter.MaxFilter(2 * MASK_GROW + 1))) > 0) | is_shadow
    work = premultiplied(cell)
    width = cell.shape[1]
    for row, flags in zip(work, mask):
        column = 0
        while column < width:
            if not flags[column]:
                column += 1
                continue
            end = column
            while end < width and flags[end]:
                end += 1
            before = row[column - 1] if column > 0 else None
            after = row[end] if end < width else None
            if before is None and after is None:
                row[column:end] = 0.0
            else:
                first = before if before is not None else after
                last = after if after is not None else before
                blend = ((np.arange(end - column, dtype=np.float32) + 1.0) / (end - column + 1.0))[:, None]
                row[column:end] = first * (1.0 - blend) + last * blend
            column = end
    return straight(work)


def cleaned(cell: np.ndarray, kind: Kind) -> np.ndarray:
    if kind.clean == "span":
        return clean_span(cell, kind.box)
    if kind.clean == "mask":
        return clean_mask(cell, kind)
    return np.zeros_like(cell)


def font_at(font_path: Path, size: float) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(font_path), round(size * SCALE))


# Cỡ chữ của một nhóm và cao chữ hoa ở cỡ đó, điểm ảnh cuối.
@dataclass(frozen=True)
class Metrics:
    size: float
    cap: float


# Mép trên và mép dưới của một dòng so với đường chân chữ (dấu thanh chồng, nét thòng), điểm ảnh cuối.
def reach_of(font: ImageFont.FreeTypeFont, text: str) -> tuple[float, float]:
    box = font.getbbox(text, anchor="ls")
    return -box[1] / SCALE, box[3] / SCALE


# Một dòng của nhóm: chữ, ô của nó và khoảng chừa trên dưới.
@dataclass(frozen=True)
class Member:
    text: str
    room: Box
    pad: float


def fits(font_path: Path, size: float, members: list[Member]) -> bool:
    font = font_at(font_path, size)
    for member in members:
        rise, drop = reach_of(font, member.text)
        if font.getlength(member.text) / SCALE + 2.0 * OUTLINE_REACH > member.room[2]:
            return False
        if rise + drop + 2.0 * member.pad > member.room[3]:
            return False
    return True


# Cỡ chữ của từng nhóm: cỡ lớn nhất không quá cỡ trần của nhóm mà mọi dòng của nhóm vừa ô của nó.
def group_metrics(font_path: Path, jobs: list[Job]) -> dict[str, Metrics]:
    members: dict[str, list[Member]] = {}
    caps: dict[str, float] = {}
    for job in jobs:
        kind = KINDS[job.kind]
        caps[kind.group] = min(caps.get(kind.group, kind.size), kind.size)
        members.setdefault(kind.group, []).extend(Member(text, room, kind.pad) for text, room in zip(job.lines, kind.rooms))
    found: dict[str, Metrics] = {}
    for group, lines in members.items():
        size = caps[group]
        while size >= SMALLEST_SIZE and not fits(font_path, size, lines):
            size -= SIZE_STEP
        if size < SMALLEST_SIZE:
            longest = max(lines, key=lambda member: len(member.text)).text
            raise LabelError(f"nhóm {group}: chữ {longest!r} không vừa ô ngay ở cỡ {SMALLEST_SIZE}")
        found[group] = Metrics(size, -font_at(font_path, size).getbbox("H", anchor="ls")[1] / SCALE)
    return found


# Một dòng đã đặt chỗ: mép trái, đường chân chữ, và mép trên, mép dưới của nó so với đường chân chữ.
@dataclass(frozen=True)
class Placed:
    text: str
    left: float
    baseline: float
    rise: float
    drop: float


# Đường chân chữ trong ô room: thân chữ hoa nằm giữa ô; dấu chồng hay nét thòng của dòng chạm mép ô
# thì dời vừa đủ (ưu tiên giữ mép trên).
def baseline_in(room: Box, cap: float, reach: tuple[float, float], pad: float) -> float:
    top, height = float(room[1]), float(room[3])
    baseline = top + (height + cap) / 2.0
    lowest = top + height - pad - reach[1]
    highest = top + pad + reach[0]
    return max(min(baseline, lowest), highest)


def over(top: np.ndarray, under: np.ndarray) -> np.ndarray:
    top_alpha = top[:, :, 3:4] / 255.0
    under_alpha = under[:, :, 3:4] / 255.0
    alpha = top_alpha + under_alpha * (1.0 - top_alpha)
    colour = top[:, :, :3] * top_alpha + under[:, :, :3] * under_alpha * (1.0 - top_alpha)
    colour = np.divide(colour, alpha, out=np.zeros_like(colour), where=alpha > 0.0)
    return np.dstack([colour, alpha * 255.0])


def flat_layer(cover: np.ndarray, colour: tuple[int, int, int], strength: float) -> np.ndarray:
    layer = np.zeros((*cover.shape, 4), dtype=np.float32)
    layer[:, :, :3] = colour
    layer[:, :, 3] = cover * strength
    return layer


# Lớp chữ của một ảnh ở cỡ gấp SCALE: bóng, viền rồi thân chữ có dải màu dọc theo thân chữ hoa.
def lettering(size: tuple[int, int], placed: list[Placed], font: ImageFont.FreeTypeFont, metrics: Metrics,
              tone: Tone) -> np.ndarray:
    width, height = size[0] * SCALE, size[1] * SCALE
    mask = Image.new("L", (width, height), 0)
    pen = ImageDraw.Draw(mask)
    shade = np.zeros((height, width), dtype=np.float32)
    rows = np.arange(height, dtype=np.float32)[:, None]
    for line in placed:
        pen.text((line.left * SCALE, line.baseline * SCALE), line.text, font=font, fill=255, anchor="ls")
        band_top = (line.baseline - metrics.cap) * SCALE
        ramp = np.clip((rows - band_top) / (metrics.cap * SCALE), 0.0, 1.0)
        own_rows = (rows >= (line.baseline - line.rise - 1.0) * SCALE) & (rows < (line.baseline + line.drop + 1.0) * SCALE)
        shade = np.where(own_rows, ramp, shade)
    cover = np.asarray(mask, dtype=np.float32)
    reach = round(OUTLINE_REACH * SCALE)
    edge = np.asarray(mask.filter(ImageFilter.MaxFilter(2 * reach + 1)).filter(ImageFilter.GaussianBlur(SCALE * 0.3)),
                      dtype=np.float32)
    dropped = Image.new("L", (width, height), 0)
    dropped.paste(mask, (0, round(SHADOW_DROP * SCALE)))
    shadow = np.asarray(dropped.filter(ImageFilter.GaussianBlur(SHADOW_BLUR * SCALE)), dtype=np.float32)
    fill = np.zeros((height, width, 4), dtype=np.float32)
    top, bottom = np.array(tone.top, dtype=np.float32), np.array(tone.bottom, dtype=np.float32)
    fill[:, :, :3] = top + (bottom - top) * shade[:, :, None]
    fill[:, :, 3] = cover
    layer = over(flat_layer(edge, tone.edge, tone.edge_strength), flat_layer(shadow, (0, 0, 0), SHADOW_STRENGTH))
    return over(fill, layer)


# Thu lớp chữ về cỡ thật qua alpha nhân sẵn, cho mép chữ không viền màu lạ.
def shrunk(layer: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    picture = Image.fromarray(layer.round().astype(np.uint8), "RGBA").convert("RGBa")
    return np.asarray(picture.resize(size, Image.LANCZOS).convert("RGBA")).astype(np.float32)


def left_of(text: str, room: Box, align: str, font: ImageFont.FreeTypeFont) -> float:
    length = font.getlength(text) / SCALE
    if align == "left":
        return float(room[0]) + OUTLINE_REACH
    if align == "right":
        return float(room[0] + room[2]) - OUTLINE_REACH - length
    return float(room[0]) + (room[2] - length) / 2.0


def lettered(cell: np.ndarray, job: Job, font_path: Path, metrics: Metrics) -> np.ndarray:
    kind = KINDS[job.kind]
    plate = cleaned(cell, kind)
    font = font_at(font_path, metrics.size)
    placed = []
    for text, room, align in zip(job.lines, kind.rooms, kind.aligns):
        reach = reach_of(font, text)
        baseline = baseline_in(room, metrics.cap, reach, kind.pad)
        placed.append(Placed(text, left_of(text, room, align, font), baseline, reach[0], reach[1]))
    size = (cell.shape[1], cell.shape[0])
    letters = shrunk(lettering(size, placed, font, metrics, tone_of(job)), size)
    return over(letters, plate).round().astype(np.uint8)


# Tấm so: mỗi ảnh một cặp gốc và mới đặt cạnh nhau, phóng SHEET_ZOOM lần, xếp tràn dòng. Ảnh cao hơn
# SHEET_TALL điểm chỉ hiện phần trên (nền bảng tạo cao 268 điểm mà chữ nằm ở đầu).
SHEET_ZOOM = 2
SHEET_TALL = 60
SHEET_WIDE = 1560
SHEET_GAP = 10


def write_sheet(path: Path, pairs: list[tuple[str, np.ndarray, np.ndarray]]) -> None:
    tiles: list[Image.Image] = []
    for _, before, after in pairs:
        tall = min(before.shape[0], SHEET_TALL)
        wide = before.shape[1]
        tile = Image.new("RGBA", ((2 * wide + 2) * SHEET_ZOOM, tall * SHEET_ZOOM), (64, 72, 84, 255))
        for offset, pixels in ((0, before), (wide + 2, after)):
            picture = Image.fromarray(pixels[:tall].round().astype(np.uint8), "RGBA")
            big = picture.resize((wide * SHEET_ZOOM, tall * SHEET_ZOOM), Image.NEAREST)
            tile.alpha_composite(big, (offset * SHEET_ZOOM, 0))
        tiles.append(tile)
    spots: list[tuple[int, int]] = []
    left, top, row_tall = SHEET_GAP, SHEET_GAP, 0
    for tile in tiles:
        if left + tile.width + SHEET_GAP > SHEET_WIDE and left > SHEET_GAP:
            left, top, row_tall = SHEET_GAP, top + row_tall + SHEET_GAP, 0
        spots.append((left, top))
        left += tile.width + SHEET_GAP
        row_tall = max(row_tall, tile.height)
    sheet = Image.new("RGBA", (SHEET_WIDE, top + row_tall + SHEET_GAP), (64, 72, 84, 255))
    for tile, spot in zip(tiles, spots):
        sheet.alpha_composite(tile, spot)
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


# Khối dòng "image/..." của tệp i18n ứng với bảng việc: is_sync thì ghi lại khối, không thì khối phải
# đã đúng từng dòng.
def settle_rows(jobs: list[Job], manifest: Path, is_sync: bool) -> None:
    lines = manifest.read_text(encoding="utf-8").split("\n")
    if lines.count(ROWS_OPEN) != 1 or lines.count(ROWS_CLOSE) != 1:
        raise LabelError(f"{manifest}: cần đúng một dòng mốc mở và một dòng mốc đóng của letter_labels")
    first, last = lines.index(ROWS_OPEN), lines.index(ROWS_CLOSE)
    if first > last:
        raise LabelError(f"{manifest}: dòng mốc đóng của letter_labels đứng trước dòng mốc mở")
    wanted = [f"{job.row_key}\t{job.file}" for job in jobs]
    if lines[first + 1:last] == wanted:
        return
    if not is_sync:
        raise LabelError(f"{manifest}: khối dòng của letter_labels lệch bảng việc; chạy lại với --sync")
    manifest.write_text("\n".join(lines[:first + 1] + wanted + lines[last:]), encoding="utf-8", newline="\n")


def restore_overlaps(jobs: list[Job], regions: dict, atlases: dict[str, np.ndarray], out: Path) -> None:
    placed = [(job, regions[(job.imageset, job.image)]) for job in jobs]
    for index, (job, region) in enumerate(placed):
        for other, second in placed[index + 1:]:
            if region.atlas != second.atlas:
                continue
            left = max(region.left, second.left)
            top = max(region.top, second.top)
            right = min(region.left + region.width, second.left + second.width)
            bottom = min(region.top + region.height, second.top + second.height)
            if left >= right or top >= bottom:
                continue
            source = atlases[region.atlas][top:bottom, left:right].round().astype(np.uint8)
            restore_shared(out / job.file, region, source, left, top)
            restore_shared(out / other.file, second, source, left, top)


def restore_shared(path: Path, region, source: np.ndarray, left: int, top: int) -> None:
    with Image.open(path) as picture:
        cell = np.asarray(picture.convert("RGBA")).copy()
    y0, x0 = top - region.top, left - region.left
    cell[y0:y0 + source.shape[0], x0:x0 + source.shape[1]] = source
    Image.fromarray(cell, "RGBA").save(path)


def make(args: argparse.Namespace) -> int:
    table, data, state, out = Path(args.table), Path(args.data), Path(args.state), Path(args.out)
    manifest = out.parent / (out.name + ".tsv")
    words = read_table(manifest)
    jobs = read_jobs(table, words)
    font_path = table.parent / FONT_FILE
    if not font_path.is_file():
        raise LabelError(f"không có phông {font_path}")
    regions = export_layout_images.regions_of(data / "Interface" / "Schema" / "all.imageset.xml",
                                               {job.imageset for job in jobs})
    seen: dict[tuple[str, int, int], str] = {}
    for job in jobs:
        region = regions.get((job.imageset, job.image))
        if region is None:
            raise LabelError(f"{job.imageset}/{job.image}: bộ ảnh đã gom không có mảnh này")
        spot = (region.atlas, region.left, region.top)
        if spot in seen:
            raise LabelError(f"{job.imageset}/{job.image}: cùng ô atlas với {seen[spot]}, chỉ kê một trong hai")
        seen[spot] = f"{job.imageset}/{job.image}"
    metrics = group_metrics(font_path, jobs)
    atlases: dict[str, np.ndarray] = {}
    pairs: list[tuple[str, np.ndarray, np.ndarray]] = []
    for job in jobs:
        region = regions[(job.imageset, job.image)]
        if region.atlas not in atlases:
            atlases[region.atlas] = read_atlas(data, state, region.atlas)
        cell = atlases[region.atlas][region.top:region.top + region.height, region.left:region.left + region.width]
        made = lettered(cell, job, font_path, metrics[KINDS[job.kind].group])
        target = out / job.file
        target.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(made, "RGBA").save(target)
        pairs.append((job.file, cell, made.astype(np.float32)))
    # Ô bộ ảnh gốc có khi đè nhau vài điểm. Hai ảnh thay phải giống nhau ở phần chung, nên phần ấy
    # giữ nguyên điểm ảnh gốc (chữ mới không được tràn vào đó).
    restore_overlaps(jobs, regions, atlases, out)
    if args.sheet:
        write_sheet(Path(args.sheet), pairs)
    sizes = ", ".join(f"{group} {found.size:g}" for group, found in sorted(metrics.items()))
    print(f"letter_labels: ghi {len(jobs)} ảnh vào {out / OUT_FOLDER}; cỡ chữ: {sizes}")
    settle_rows(jobs, manifest, args.sync)
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Vẽ chữ Việt bằng phông lên nền nút, tiêu đề, nhãn gốc.")
    parser.add_argument("table", help="bảng việc (assets/i18n/vi/source/labels.tsv); phông nằm cùng thư mục")
    parser.add_argument("data", help="thư mục dữ liệu client (CLIENT/data)")
    parser.add_argument("state", help="thư mục trạng thái của build_i18n.py (build/i18n), nơi giữ atlas gốc")
    parser.add_argument("out", help="thư mục ảnh của ngôn ngữ (assets/i18n/vi); tệp i18n là <out>.tsv")
    parser.add_argument("--sheet", help="ghi tấm so ảnh gốc với ảnh mới ra tệp PNG này")
    parser.add_argument("--sync", action="store_true", help="ghi lại khối dòng image/ của tệp i18n theo bảng việc")
    args = parser.parse_args(argv)
    try:
        return make(args)
    except LabelError as error:
        print(f"Lỗi letter_labels: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
