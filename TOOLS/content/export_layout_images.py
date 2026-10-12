# Xuất ảnh mà các cửa sổ của một layout dùng (thuộc tính có giá trị "set:<bộ ảnh> image:<tên>") ra
# từng tệp PNG, để người vẽ thấy đúng mảnh ảnh của từng nút và làm bản thay thế cùng cỡ. Ảnh cắt từ
# các tệp PNG đã gom của CLIENT/data/Interface theo ô ghi trong Schema/all.imageset.xml.
# Chạy ở gốc dự án:
#   python TOOLS/content/export_layout_images.py CLIENT/data Logon/LogOn.layout.xml <thư mục ra>
#       [--windows A,B,...] [--sheet <tệp.png>]
# Mỗi ảnh ra một tệp <cửa sổ>.<thuộc tính>.png; danh-sach.tsv ghi cửa sổ, thuộc tính, bộ ảnh, tên
# ảnh, tệp atlas và ô (x, y, rộng, cao) để đặt bản thay thế về đúng chỗ. --windows chỉ xuất các cửa
# sổ được kê. --sheet ghi thêm một tấm ghép mọi ảnh kèm tên, để xem nhanh. Mã thoát: 0 xong, 1 khi
# thiếu tệp hay không ảnh nào xuất được, 2 khi sai cách dùng.
import argparse
import pathlib
import re
import sys
import xml.etree.ElementTree as ElementTree
from dataclasses import dataclass

from PIL import Image, ImageDraw

WINDOW = re.compile(r'<Window Type="([^"]*)" Name="([^"]*)"|<Property Name="([^"]*)" Value="set:(\S+) image:([^"]+)"')
# Tấm ghép: khoảng cách giữa các ô và tới mép, khoảng từ đáy ảnh tới tên, chiều cao dòng tên.
SHEET_GAP = 32
LABEL_GAP = 10
LABEL_HEIGHT = 12
SHEET_COLOUR = (64, 72, 84, 255)
LABEL_COLOUR = (255, 255, 255, 255)
SIZE_COLOUR = (255, 214, 102, 255)
STATE_ORDER = ("NormalImage", "HoverImage", "PushedImage", "DisabledImage")


@dataclass
class Use:
    window: str
    kind: str
    property: str
    imageset: str
    image: str


@dataclass
class Region:
    atlas: str
    left: int
    top: int
    width: int
    height: int


def uses_of(layout_text: str) -> list[Use]:
    uses: list[Use] = []
    window = ""
    kind = ""
    for match in WINDOW.finditer(layout_text):
        if match.group(2):
            kind, window = match.group(1), match.group(2)
            continue
        uses.append(Use(window, kind, match.group(3), match.group(4), match.group(5)))
    return uses


def regions_of(imagesets: pathlib.Path, wanted: set[str]) -> dict[tuple[str, str], Region]:
    regions: dict[tuple[str, str], Region] = {}
    for element in ElementTree.parse(imagesets).getroot().iter("Imageset"):
        name = element.get("Name", "")
        if name not in wanted:
            continue
        atlas = element.get("Imagefile", "")
        for image in element.iter("Image"):
            box = [int(float(image.get(key, "0"))) for key in ("XPos", "YPos", "Width", "Height")]
            regions[(name, image.get("Name", ""))] = Region(atlas, box[0], box[1], box[2], box[3])
    return regions


def crop(interface: pathlib.Path, region: Region) -> Image.Image | None:
    atlas = interface / (region.atlas + ".png")
    if not atlas.is_file():
        return None
    with Image.open(atlas) as picture:
        box = (region.left, region.top, region.left + region.width, region.top + region.height)
        return picture.convert("RGBA").crop(box)


# Thứ tự cột của một trạng thái trong tấm ghép; thuộc tính khác đứng sau, giữ thứ tự của layout.
def state_rank(name: str) -> int:
    state = name.rsplit(".", 1)[-1]
    return STATE_ORDER.index(state) if state in STATE_ORDER else len(STATE_ORDER)


# Lưới đều: mỗi cửa sổ một hàng, mỗi ảnh của nó một ô; mọi ô rộng bằng nhau (ảnh hay tên dài nhất),
# cách nhau và cách mép SHEET_GAP. Ảnh canh giữa ô; dưới ảnh LABEL_GAP là tên rồi cỡ điểm ảnh.
def write_sheet(path: pathlib.Path, pictures: list[tuple[str, Image.Image]]) -> None:
    probe = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    rows: dict[str, list[tuple[str, Image.Image]]] = {}
    for name, picture in pictures:
        rows.setdefault(name.split(".", 1)[0], []).append((name, picture))
    for items in rows.values():
        items.sort(key=lambda item: state_rank(item[0]))
    cell = max(max(picture.width, int(probe.textlength(name)) + 1) for name, picture in pictures)
    columns = max(len(items) for items in rows.values())
    heights = [max(picture.height for _, picture in items) for items in rows.values()]
    label_tall = LABEL_GAP + 2 * LABEL_HEIGHT
    width = SHEET_GAP + columns * (cell + SHEET_GAP)
    height = SHEET_GAP + sum(tall + label_tall + SHEET_GAP for tall in heights)
    sheet = Image.new("RGBA", (width, height), SHEET_COLOUR)
    pen = ImageDraw.Draw(sheet)
    top = SHEET_GAP
    for items, tall in zip(rows.values(), heights):
        for column, (name, picture) in enumerate(items):
            left = SHEET_GAP + column * (cell + SHEET_GAP)
            sheet.alpha_composite(picture, (left + (cell - picture.width) // 2, top + tall - picture.height))
            write_label(pen, (left, top + tall + LABEL_GAP, cell), name, picture)
        top += tall + label_tall + SHEET_GAP
    sheet.save(path)


# Hai dòng canh giữa ô (trái, trên, rộng): tên ảnh, rồi cỡ điểm ảnh của nó.
def write_label(pen: ImageDraw.ImageDraw, slot: tuple[int, int, int], name: str, picture: Image.Image) -> None:
    left, top, cell = slot
    size = f"{picture.width} x {picture.height} px"
    pen.text((left + (cell - int(pen.textlength(name))) // 2, top), name, fill=LABEL_COLOUR)
    pen.text((left + (cell - int(pen.textlength(size))) // 2, top + LABEL_HEIGHT), size, fill=SIZE_COLOUR)


def export(args: argparse.Namespace) -> int:
    interface = pathlib.Path(args.data) / "Interface"
    layout = interface / args.layout
    imagesets = interface / "Schema" / "all.imageset.xml"
    if not layout.is_file() or not imagesets.is_file():
        print(f"Lỗi: thiếu {layout} hoặc {imagesets}", file=sys.stderr)
        return 1
    chosen = set(args.windows.split(",")) if args.windows else None
    uses = [use for use in uses_of(layout.read_text(encoding="utf-8")) if chosen is None or use.window in chosen]
    regions = regions_of(imagesets, {use.imageset for use in uses})
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rows = ["cửa sổ\tkiểu\tthuộc tính\tbộ ảnh\tảnh\ttệp atlas\tx\ty\trộng\tcao\ttệp xuất"]
    pictures: list[tuple[str, Image.Image]] = []
    for use in uses:
        region = regions.get((use.imageset, use.image))
        picture = crop(interface, region) if region else None
        if region is None or picture is None:
            print(f"bỏ qua {use.window}.{use.property}: không có ảnh {use.imageset}/{use.image}", file=sys.stderr)
            continue
        name = f"{use.window}.{use.property}.png"
        picture.save(out / name)
        pictures.append((f"{use.window}.{use.property}", picture))
        cells = [use.window, use.kind, use.property, use.imageset, use.image, region.atlas]
        cells += [str(region.left), str(region.top), str(region.width), str(region.height), name]
        rows.append("\t".join(cells))
    (out / "danh-sach.tsv").write_text("\n".join(rows) + "\n", encoding="utf-8", newline="\n")
    if args.sheet and pictures:
        write_sheet(pathlib.Path(args.sheet), pictures)
    print(f"xuất {len(pictures)} ảnh của {len({use.window for use in uses})} cửa sổ vào {out}")
    return 0 if pictures else 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Xuất ảnh mà các cửa sổ của một layout dùng.")
    parser.add_argument("data", help="thư mục dữ liệu client (CLIENT/data)")
    parser.add_argument("layout", help="layout, tương đối với Interface (Logon/LogOn.layout.xml)")
    parser.add_argument("out", help="thư mục ghi ảnh")
    parser.add_argument("--windows", help="chỉ các cửa sổ này, cách nhau bằng dấu phẩy")
    parser.add_argument("--sheet", help="ghi thêm một tấm ghép mọi ảnh ra tệp PNG này")
    return export(parser.parse_args())


if __name__ == "__main__":
    sys.exit(main())
