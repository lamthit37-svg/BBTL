# Dựng bản địa hoá của client. Ngôn ngữ chọn lúc dựng game (GAME_LANGUAGE của CMake): công cụ này
# lấy đúng MỘT tệp nguồn assets/i18n/<ngôn ngữ>.tsv và đưa nó vào bản triển khai. Bản triển khai
# (thư mục dữ liệu client) chỉ chứa một bộ chữ dịch và một bộ ảnh; client không biết và không chọn
# ngôn ngữ lúc chạy. CMake chạy công cụ ở mỗi lượt dựng (target thienlong_i18n), nên sửa chữ hay ảnh
# rồi dựng lại là client thấy. Tệp nguồn có năm loại dòng "khoá<tab>giá trị":
#   khoá chuỗi (#{...} của StrDictionary, hoặc mở đầu bằng = là nguyên văn chữ của layout)
#   scene/<tên gốc của cảnh>
#   image/<bộ ảnh>/<tên ảnh>     giá trị là tệp PNG trong assets/i18n/<ngôn ngữ>/
#   file/<đường dẫn trong thư mục dữ liệu>     giá trị là tệp trong assets/i18n/<ngôn ngữ>/, chép nguyên
#   table/<bảng>/<id>/<cột>     chữ dịch của một ô của Table/<bảng>.tsv: <bảng> là tên tệp bảng không
#     đuôi (skills, items...), <id> là giá trị cột id của dòng, <cột> là tên cột trong dòng tên cột
#     của bảng; ô không có khoá giữ chữ gốc tiếng Trung (table/localize.hpp của client).
# Ghi vào thư mục dữ liệu client:
#   Table/ui_strings.lang.tsv và Table/scene_names.lang.tsv: chữ của ngôn ngữ đã chọn.
#   Interface/<atlas>.png: atlas của bộ ảnh với mảnh ảnh đã thay, ghi đè lên atlas bộ gom đã đặt.
#   Table/<bảng>.lang.tsv (ba cột id, column, text): bản dịch ô của từng bảng có dòng table/; bảng
#   thôi được nêu thì tệp bản dịch của nó bị xoá (sổ tables.tsv của thư mục --state).
#   các tệp của dòng file/ (trang web mở từ nút, ...); tệp thôi được nêu thì bị xoá khỏi thư mục dữ
#   liệu (sổ files.tsv của thư mục --state nhớ các tệp đã chép).
# Hai ô ảnh của cùng một atlas có thể chồng nhau (bộ ảnh gốc khai lệch một hàng): hai ảnh thay phải
# giống nhau ở phần chung, không thì công cụ từ chối thay vì để kết quả tuỳ thứ tự dán.
# Thư mục --state (build/i18n, không triển khai) giữ atlas gốc ở base/ để dựng lại từ đó khi ảnh thay
# đổi và để trả atlas về bản gốc khi một ảnh thôi được thay, cùng sổ atlases.tsv ghi băm của bản đã
# ghi, và mốc deployed.stamp: băm của mọi thứ đã đưa vào thư mục dữ liệu, chỉ ghi lại khi băm đổi, để
# hệ dựng đóng gói lại (APK) đúng lúc bản triển khai đổi. Atlas trong thư mục dữ liệu khác băm đã ghi
# nghĩa là bộ gom vừa đặt lại bản gốc: nó thành gốc mới. Thư mục --state nằm trong build/ nên có thể
# bị xoá bất cứ lúc nào; vì vậy thư mục dữ liệu giữ dấu Table/i18n.applied.tsv (atlas đang mang ảnh
# thay, băm của bản đã ghi). Atlas còn đúng băm của dấu mà sổ hay bản gốc đã mất thì công cụ dừng với
# mã 1 và nêu lệnh gom lại (collect_ui.py --force), không coi ảnh đã thay là bản gốc. Ảnh
# thay phải đúng cỡ điểm ảnh của mảnh gốc (xem bằng export_layout_images.py). Thư mục dữ liệu chưa
# gom giao diện (không có Schema/all.imageset.xml) thì chỉ dựng chữ, in một dòng nhắc.
# Chạy ở gốc dự án:
#   python -B TOOLS/content/build_i18n.py assets/i18n/vi.tsv CLIENT/data --state build/i18n
# Tệp không đổi nội dung thì không ghi lại. Mã thoát: 0 xong, 1 khi tệp nguồn sai dạng, thiếu ảnh
# thay, ảnh lệch cỡ, bộ ảnh không có mảnh được nêu, hay bản gốc của một atlas đã thay bị mất; 2 khi
# sai cách dùng.
from __future__ import annotations

import argparse
import unicodedata
import hashlib
import io
import sys
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image

import export_layout_images

SCENE = "scene/"
IMAGE = "image/"
FILE = "file/"
TABLE = "table/"
# Tên bảng và tên cột của khoá table/: chữ thường, số, gạch dưới (như tên tệp do export_config.py đặt).
# Hai tên của bảng chữ giao diện bị cấm: Table/<bảng>.lang.tsv của chúng là hai bảng chữ ở trên.
TABLE_RESERVED = frozenset({"ui_strings", "scene_names"})
TABLE_LISTING = "tables.tsv"
STRINGS_TABLE = "Table/ui_strings.lang.tsv"
SCENES_TABLE = "Table/scene_names.lang.tsv"
LEDGER = "atlases.tsv"
COPIED = "files.tsv"
STAMP = "deployed.stamp"
# Dấu trong thư mục dữ liệu: mỗi dòng một atlas đang mang ảnh thay và băm của bản đã ghi.
APPLIED = "Table/i18n.applied.tsv"
NOTE = "Sinh bằng TOOLS/content/build_i18n.py từ assets/i18n; sửa tay sẽ mất ở lượt dựng sau"


class ManifestError(Exception):
    """Tệp i18n sai dạng, hoặc ảnh thay không dùng được; câu lỗi nêu dòng hay tên ảnh."""


@dataclass(frozen=True)
class ImageRow:
    imageset: str
    image: str
    file: str


# Một tệp chép nguyên: target là đường dẫn trong thư mục dữ liệu, file là tệp nguồn của ngôn ngữ.
@dataclass(frozen=True)
class FileRow:
    target: str
    file: str


@dataclass
class Manifest:
    strings: list[tuple[str, str]] = field(default_factory=list)
    scenes: list[tuple[str, str]] = field(default_factory=list)
    images: list[ImageRow] = field(default_factory=list)
    files: list[FileRow] = field(default_factory=list)
    # Bảng -> các ô dịch (id, cột, chữ) theo thứ tự của tệp nguồn.
    tables: dict[str, list[tuple[str, str, str]]] = field(default_factory=dict)


@dataclass(frozen=True)
class Paste:
    region: export_layout_images.Region
    file: Path
    row: ImageRow


# Băm của bản atlas đã ghi và của những thứ làm ra nó (atlas gốc, các ảnh thay và ô của chúng).
@dataclass(frozen=True)
class Record:
    written: str
    inputs: str


@dataclass
class Store:
    data: Path
    folder: Path
    records: dict[str, Record]

    def deployed(self, atlas: str) -> Path:
        return self.data / "Interface" / (atlas + ".png")

    def base(self, atlas: str) -> Path:
        return self.folder / "base" / (atlas + ".png")


# Đích của dòng file/ phải nằm trong thư mục dữ liệu: đường dẫn tương đối, gạch xuôi, không "..".
def add_file(manifest: Manifest, target: str, value: str, where: str) -> None:
    parts = target.split("/")
    is_inside = bool(target) and "" not in parts and ".." not in parts and "." not in parts
    if not is_inside or "\\" in target or ":" in target:
        raise ManifestError(f"{where}: đích của {FILE} phải là đường dẫn tương đối trong thư mục dữ liệu")
    manifest.files.append(FileRow(target, value))


def is_name(text: str) -> bool:
    return bool(text) and all(char.isascii() and (char.islower() or char.isdigit() or char == "_") for char in text)


def is_id(text: str) -> bool:
    digits = text[1:] if text.startswith("-") else text
    return digits.isascii() and digits.isdigit()


# Khoá table/<bảng>/<id>/<cột>: đúng ba phần, id là số nguyên thập phân như cột id của bảng.
def add_table_cell(manifest: Manifest, key: str, value: str, where: str) -> None:
    parts = key[len(TABLE):].split("/")
    if len(parts) != 3 or not is_name(parts[0]) or not is_id(parts[1]) or not is_name(parts[2]):
        raise ManifestError(f"{where}: khoá bảng phải là {TABLE}<bảng>/<id>/<cột>, bảng và cột viết [a-z0-9_]")
    table, row, column = parts
    if table in TABLE_RESERVED:
        raise ManifestError(f"{where}: bảng {table} là bảng chữ giao diện, không dịch theo ô")
    manifest.tables.setdefault(table, []).append((row, column, value))


def add_row(manifest: Manifest, key: str, value: str, where: str) -> None:
    value = unicodedata.normalize("NFC", value)
    if key.startswith(TABLE):
        add_table_cell(manifest, key, value, where)
        return
    if key.startswith(FILE):
        add_file(manifest, key[len(FILE):], value, where)
        return
    if key.startswith(SCENE):
        name = key[len(SCENE):]
        if not name:
            raise ManifestError(f"{where}: thiếu tên cảnh sau {SCENE}")
        manifest.scenes.append((name, value))
        return
    if not key.startswith(IMAGE):
        manifest.strings.append((key, value))
        return
    imageset, slash, image = key[len(IMAGE):].partition("/")
    if not slash or not imageset or not image:
        raise ManifestError(f"{where}: khoá ảnh phải là {IMAGE}<bộ ảnh>/<tên ảnh>")
    manifest.images.append(ImageRow(imageset, image, value))


def read_manifest(text: str) -> Manifest:
    manifest = Manifest()
    seen: set[str] = set()
    for number, line in enumerate(text.split("\n"), 1):
        if not line or line.startswith("#"):
            continue
        where = f"dòng {number}"
        key, tab, value = line.partition("\t")
        if not tab or not key or "\t" in value:
            raise ManifestError(f"{where}: cần khoá, đúng một dấu tab, rồi giá trị")
        if key in seen:
            raise ManifestError(f"{where}: khoá lặp {key}")
        seen.add(key)
        add_row(manifest, key, value, where)
    return manifest


def table_bytes(rows: list[tuple[str, str]]) -> bytes:
    lines = [f"# {NOTE}", "key\ttext"] + [f"{key}\t{text}" for key, text in rows]
    return ("\n".join(lines) + "\n").encode("utf-8")


def cells_bytes(rows: list[tuple[str, str, str]]) -> bytes:
    lines = [f"# {NOTE}", "id\tcolumn\ttext"] + ["\t".join(row) for row in rows]
    return ("\n".join(lines) + "\n").encode("utf-8")


# Ghi Table/<bảng>.lang.tsv của từng bảng có ô dịch, xoá bản dịch của bảng lượt trước có mà nay
# không còn; trả số tệp đã ghi và nội dung từng tệp (để băm vào mốc).
def deploy_tables(manifest: Manifest, data: Path, state: Path) -> tuple[int, dict[str, bytes]]:
    contents = {f"Table/{table}.lang.tsv": cells_bytes(rows) for table, rows in sorted(manifest.tables.items())}
    listing = state / TABLE_LISTING
    before = listing.read_text(encoding="utf-8").split("\n") if listing.is_file() else []
    for target in sorted(set(filter(None, before)) - set(contents)):
        (data / target).unlink(missing_ok=True)
    written = sum(int(write_changed(data / target, content)) for target, content in contents.items())
    write_changed(listing, "".join(target + "\n" for target in sorted(contents)).encode("utf-8"))
    return written, contents


def digest(*parts: bytes) -> str:
    worker = hashlib.sha256()
    for part in parts:
        worker.update(len(part).to_bytes(8, "little"))
        worker.update(part)
    return worker.hexdigest()


def read_records(folder: Path) -> dict[str, Record]:
    path = folder / LEDGER
    if not path.is_file():
        return {}
    rows = [line.split("\t") for line in path.read_text(encoding="utf-8").split("\n") if line]
    return {row[0]: Record(row[1], row[2]) for row in rows if len(row) == 3}


def ledger_bytes(records: dict[str, Record]) -> bytes:
    lines = [f"{atlas}\t{record.written}\t{record.inputs}" for atlas, record in sorted(records.items())]
    return "".join(line + "\n" for line in lines).encode("utf-8")


def read_applied(data: Path) -> dict[str, str]:
    path = data / APPLIED
    if not path.is_file():
        return {}
    rows = [line.split("\t") for line in path.read_text(encoding="utf-8").split("\n") if line]
    return {row[0]: row[1] for row in rows if len(row) == 2}


def applied_bytes(records: dict[str, Record]) -> bytes:
    lines = [f"{atlas}\t{record.written}" for atlas, record in sorted(records.items())]
    return "".join(line + "\n" for line in lines).encode("utf-8")


def write_changed(path: Path, content: bytes) -> bool:
    if path.is_file() and path.read_bytes() == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)
    return True


# Các ảnh thay của tệp nguồn, gom theo atlas của bộ ảnh chứa chúng.
def pastes_by_atlas(manifest: Manifest, folder: Path, imagesets: Path) -> dict[str, list[Paste]]:
    regions = export_layout_images.regions_of(imagesets, {row.imageset for row in manifest.images})
    found: dict[str, list[Paste]] = {}
    for row in manifest.images:
        region = regions.get((row.imageset, row.image))
        if region is None:
            raise ManifestError(f"ảnh {row.imageset}/{row.image}: bộ ảnh đã gom không có mảnh này")
        check_patch(row, folder / row.file, region)
        found.setdefault(region.atlas, []).append(Paste(region, folder / row.file, row))
    for pastes in found.values():
        check_overlaps(pastes)
    return found


# Phần của ảnh thay nằm trong ô chung (toạ độ atlas), để so hai ảnh có ô chồng nhau.
def shared_part(paste: Paste, box: tuple[int, int, int, int]) -> bytes:
    left, top = paste.region.left, paste.region.top
    with Image.open(paste.file) as picture:
        part = picture.convert("RGBA").crop((box[0] - left, box[1] - top, box[2] - left, box[3] - top))
    return part.tobytes()


def check_pair(first: Paste, second: Paste) -> None:
    left = max(first.region.left, second.region.left)
    top = max(first.region.top, second.region.top)
    right = min(first.region.left + first.region.width, second.region.left + second.region.width)
    bottom = min(first.region.top + first.region.height, second.region.top + second.region.height)
    if left >= right or top >= bottom:
        return
    box = (left, top, right, bottom)
    if shared_part(first, box) != shared_part(second, box):
        names = f"{first.row.imageset}/{first.row.image} và {second.row.imageset}/{second.row.image}"
        raise ManifestError(f"ảnh {names}: hai ô chồng nhau trong atlas mà phần chung khác nhau")


# Ô của bộ ảnh gốc có khi chồng nhau; hai ảnh thay khi đó phải giống nhau ở phần chung.
def check_overlaps(pastes: list[Paste]) -> None:
    for index, first in enumerate(pastes):
        for second in pastes[index + 1:]:
            check_pair(first, second)


# Ảnh thay phải có và đúng cỡ mảnh gốc; kiểm hết trước khi đụng tới atlas nào.
def check_patch(row: ImageRow, file: Path, region: export_layout_images.Region) -> None:
    name = f"{row.imageset}/{row.image}"
    if not file.is_file():
        raise ManifestError(f"ảnh {name}: không có tệp {file}")
    with Image.open(file) as picture:
        size = picture.size
    wanted = (region.width, region.height)
    if size != wanted:
        raise ManifestError(f"ảnh {name}: {file.name} cỡ {size}, mảnh gốc cỡ {wanted}")


# Dán các ảnh thay vào atlas gốc; trả PNG của atlas mới.
def pasted_bytes(base: bytes, pastes: list[Paste]) -> bytes:
    with Image.open(io.BytesIO(base)) as picture:
        atlas = picture.convert("RGBA")
    for paste in pastes:
        with Image.open(paste.file) as picture:
            patch = picture.convert("RGBA")
        atlas.paste(patch, (paste.region.left, paste.region.top))
    packed = io.BytesIO()
    atlas.save(packed, format="PNG")
    return packed.getvalue()


# Đưa một atlas của thư mục dữ liệu về bản có ảnh thay; True khi có ghi.
def localize(store: Store, atlas: str, pastes: list[Paste]) -> bool:
    deployed = store.deployed(atlas)
    if not deployed.is_file():
        raise ManifestError(f"atlas {atlas}: không có tệp {deployed}")
    current = deployed.read_bytes()
    record = store.records.get(atlas)
    is_ours = record is not None and digest(current) == record.written and store.base(atlas).is_file()
    if not is_ours:
        write_changed(store.base(atlas), current)
    base = store.base(atlas).read_bytes()
    parts = [str(paste.region).encode("utf-8") + paste.file.read_bytes() for paste in pastes]
    inputs = digest(base, *parts)
    if is_ours and record is not None and record.inputs == inputs:
        return False
    made = pasted_bytes(base, pastes)
    store.records[atlas] = Record(digest(made), inputs)
    return write_changed(deployed, made)


# Atlas đã từng được thay ảnh mà nay tệp nguồn không còn nêu: trả về bản gốc. Atlas mà bộ gom đã đặt
# lại (băm khác bản đã ghi) thì vốn là bản gốc, chỉ bỏ dòng sổ.
def restore_dropped(store: Store, kept: set[str]) -> int:
    restored = 0
    for atlas in sorted(set(store.records) - kept):
        record = store.records.pop(atlas)
        deployed = store.deployed(atlas)
        is_ours = deployed.is_file() and digest(deployed.read_bytes()) == record.written
        if is_ours and store.base(atlas).is_file():
            restored += int(write_changed(deployed, store.base(atlas).read_bytes()))
    return restored


# Atlas mà dấu của thư mục dữ liệu nói đang mang ảnh thay (băm còn khớp) nhưng sổ hay bản gốc của nó
# đã mất, vì thư mục --state bị xoá: dừng trước khi ghi gì. Đi tiếp thì ảnh đã thay thành "bản gốc",
# ảnh thôi được nêu không bao giờ trả về được, và nền nút lấy từ base/ là nền đã có chữ.
def check_state_kept(store: Store) -> None:
    for atlas, written in sorted(read_applied(store.data).items()):
        deployed = store.deployed(atlas)
        is_replaced = deployed.is_file() and digest(deployed.read_bytes()) == written
        has_state = atlas in store.records and store.base(atlas).is_file()
        if is_replaced and not has_state:
            fix = f"python -B TOOLS/content/collect_ui.py <_raw> {store.data} --force"
            raise ManifestError(f"atlas {atlas} đang mang ảnh thay nhưng {store.folder} không còn bản gốc: {fix}")


# Thay ảnh trong các atlas của thư mục dữ liệu theo tệp nguồn; trả số atlas đã ghi.
def build_images(manifest: Manifest, folder: Path, store: Store) -> int:
    imagesets = store.data / "Interface" / "Schema" / "all.imageset.xml"
    if not imagesets.is_file():
        if manifest.images:
            print(f"i18n: {store.data} chưa gom giao diện, bỏ qua {len(manifest.images)} ảnh thay")
        return 0
    check_state_kept(store)
    wanted = pastes_by_atlas(manifest, folder, imagesets) if manifest.images else {}
    try:
        written = sum(int(localize(store, atlas, pastes)) for atlas, pastes in wanted.items())
        written += restore_dropped(store, set(wanted))
    finally:
        # Sổ và dấu phải khớp với thứ đã ghi dù lượt này dừng giữa chừng: thiếu dòng thì lượt sau
        # coi atlas đã thay ảnh là bản gốc.
        write_changed(store.folder / LEDGER, ledger_bytes(store.records))
        write_changed(store.data / APPLIED, applied_bytes(store.records))
    return written


# Nội dung các tệp chép nguyên, đọc hết trước khi ghi bất cứ thứ gì: thiếu một tệp là dừng sạch.
def read_files(manifest: Manifest, folder: Path) -> dict[str, bytes]:
    contents: dict[str, bytes] = {}
    for row in manifest.files:
        source = folder / row.file
        if not source.is_file():
            raise ManifestError(f"tệp {row.target}: không có tệp nguồn {source}")
        contents[row.target] = source.read_bytes()
    return contents


# Chép các tệp vào thư mục dữ liệu và xoá tệp lượt trước đã chép mà nay không còn nêu; trả số tệp ghi.
def deploy_files(contents: dict[str, bytes], data: Path, state: Path) -> int:
    listing = state / COPIED
    before = listing.read_text(encoding="utf-8").split("\n") if listing.is_file() else []
    for target in sorted(set(filter(None, before)) - set(contents)):
        (data / target).unlink(missing_ok=True)
    written = sum(int(write_changed(data / target, content)) for target, content in contents.items())
    write_changed(listing, "".join(target + "\n" for target in sorted(contents)).encode("utf-8"))
    return written


def check_glossary(path: Path) -> None:
    """Mỗi chữ zh đúng một dòng. Lặp là lỗi: bản dịch không biết theo dòng nào."""
    seen: dict[str, int] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        zh = line.split("\t", 1)[0]
        if zh in seen:
            raise ManifestError(f"glossary dòng {number}: {zh} lặp với dòng {seen[zh]}")
        seen[zh] = number


def build(source: Path, data: Path, state: Path) -> int:
    glossary = source.parent / "glossary.tsv"
    if glossary.is_file():
        check_glossary(glossary)
    language = source.stem
    manifest = read_manifest(source.read_text(encoding="utf-8"))
    contents = read_files(manifest, source.parent / language)
    store = Store(data, state, read_records(state))
    atlases = build_images(manifest, source.parent / language, store)
    strings = table_bytes(manifest.strings)
    scenes = table_bytes(manifest.scenes)
    tables = int(write_changed(data / STRINGS_TABLE, strings)) + int(write_changed(data / SCENES_TABLE, scenes))
    copied = deploy_files(contents, data, state)
    table_count, cells = deploy_tables(manifest, data, state)
    # Sổ mang băm của từng atlas đã ghi, nên các phần này phủ hết thứ lượt dựng đưa vào thư mục dữ liệu.
    names = "\n".join(sorted(contents)).encode("utf-8")
    files = [contents[key] for key in sorted(contents)]
    translated = [part for key in sorted(cells) for part in (key.encode("utf-8"), cells[key])]
    deployed = digest(strings, scenes, ledger_bytes(store.records), names, *files, *translated)
    write_changed(state / STAMP, (deployed + "\n").encode("utf-8"))
    counts = f"{len(manifest.strings)} chuỗi, {len(manifest.scenes)} tên cảnh, {len(manifest.images)} ảnh"
    cell_count = sum(len(rows) for rows in manifest.tables.values())
    counts += f", {cell_count} ô của {len(manifest.tables)} bảng"
    wrote = f"{tables} bảng chữ, {table_count} bản dịch bảng, {atlases} atlas, {copied} tệp"
    print(f"i18n {language}: {counts}, {len(contents)} tệp; ghi {wrote}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Dựng bản địa hoá của client từ một tệp i18n.")
    parser.add_argument("source", help="tệp i18n, tên tệp là mã ngôn ngữ (assets/i18n/vi.tsv)")
    parser.add_argument("data", help="thư mục dữ liệu client (CLIENT/data)")
    parser.add_argument("--state", required=True, help="thư mục giữ atlas gốc và sổ băm (build/i18n)")
    args = parser.parse_args(argv)
    source = Path(args.source)
    if not source.is_file():
        print(f"Lỗi i18n: không có tệp {source}", file=sys.stderr)
        return 1
    try:
        return build(source, Path(args.data), Path(args.state))
    except ManifestError as error:
        print(f"Lỗi i18n: {source}: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
