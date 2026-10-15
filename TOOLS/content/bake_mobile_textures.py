#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/bake_mobile_textures.py
#  PHÂN HỆ   : Content / Bake Mobile Textures
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Nấu texture DDS (BC1/BC2/BC3) của vật liệu thành TLTX cho điện thoại: ASTC
#    4x4 (mobile/astc/<đường dẫn>) và ETC2 (mobile/etc2/<đường dẫn>), đúng
#    định dạng engine/resource/tier.cpp đọc.
#  - Đọc danh sách Table/mobile.files.tsv (trace_assets.py), ghi vào thư mục
#    ra (mặc định build/mobile-textures); chỉ nấu lại tệp nguồn mới hơn bản đã
#    nấu hoặc khi phiên bản nấu đổi.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# Cách dùng: python -B TOOLS/content/bake_mobile_textures.py [--data dev/client/assets] [--out build/mobile-textures]
# TLTX v1: "TLTX", u16 phiên bản = 1, u16 loại (1 ASTC 4x4, 2 ETC2 RGBA, 3 ETC2 RGB), u32 rộng, u32 cao, u32 số mip, rồi
# từng mip từ lớn tới nhỏ, mỗi mip ceil(w/4)*ceil(h/4) khối (16 byte; ETC2 RGB 8 byte). Mọi trường little-endian.
# Thư viện: Pillow (đọc DDS, đổi cỡ), astc-encoder-py, etcpak. Texture có alpha thật (một điểm ảnh dưới 255) lấy ETC2 RGBA;
# không thì ETC2 RGB (nửa dung lượng). Mip tạo lại bằng lọc hộp từ mức 0 vì Pillow chỉ đọc mức 0 của DDS.
# Tệp Pillow không đọc được (định dạng DDS lạ) được liệt kê cuối, không nấu: gói giữ DDS gốc cho tệp ấy (GPU không hỗ trợ BC
# sẽ không vẽ được nó) nên báo lỗi cuối cùng để người dựng biết.

from __future__ import annotations

import argparse
import os
import struct
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import astc_encoder as astc
import etcpak
from PIL import Image

BAKE_VERSION = 1
MAGIC = b"TLTX"
KIND_ASTC = 1
KIND_ETC2_RGBA = 2
KIND_ETC2_RGB = 3
MAX_MIPS = 16
# Tên thư mục dưới thư mục dữ liệu mà engine/resource/tier.cpp tìm (tier_relative).
ASTC_ROOT = "mobile/astc"
ETC2_ROOT = "mobile/etc2"
STAMP_NAME = "bake.version"


def mip_chain(base: Image.Image) -> list[Image.Image]:
    levels = [base]
    while len(levels) < MAX_MIPS and (levels[-1].width > 1 or levels[-1].height > 1):
        last = levels[-1]
        size = (max(1, last.width // 2), max(1, last.height // 2))
        levels.append(last.resize(size, Image.Resampling.BOX))
    return levels


def padded(level: Image.Image) -> Image.Image:
    # ETC2 (etcpak) nhận cỡ chia hết cho 4: mức nhỏ được đệm bằng cách lặp điểm ảnh biên.
    width = (level.width + 3) // 4 * 4
    height = (level.height + 3) // 4 * 4
    if (width, height) == level.size:
        return level
    canvas = Image.new("RGBA", (width, height))
    canvas.paste(level, (0, 0))
    for x in range(level.width, width):
        canvas.paste(level.crop((level.width - 1, 0, level.width, level.height)), (x, 0))
    for y in range(level.height, height):
        canvas.paste(canvas.crop((0, level.height - 1, width, level.height)), (0, y))
    return canvas


def has_alpha(base: Image.Image) -> bool:
    low, _ = base.getchannel("A").getextrema()
    return low < 255


def astc_level(context: astc.ASTCContext, level: Image.Image) -> bytes:
    image = astc.ASTCImage(astc.ASTCType.U8, level.width, level.height, 1, level.tobytes())
    return context.compress(image, astc.ASTCSwizzle.from_str("RGBA"))


def etc2_level(level: Image.Image, is_alpha: bool) -> bytes:
    cell = padded(level)
    if is_alpha:
        return etcpak.compress_etc2_rgba(cell.tobytes(), cell.width, cell.height)
    return etcpak.compress_etc2_rgb(cell.tobytes(), cell.width, cell.height)


def header(kind: int, base: Image.Image, mips: int) -> bytes:
    return MAGIC + struct.pack("<HHIII", 1, kind, base.width, base.height, mips)


def bake_one(source: str, astc_out: str, etc2_out: str) -> str | None:
    # Trả None khi xong, câu lỗi khi không nấu được.
    try:
        with Image.open(source) as opened:
            base = opened.convert("RGBA")
    except (OSError, ValueError, NotImplementedError) as error:
        return f"{source}: {error}"
    levels = mip_chain(base)
    is_alpha = has_alpha(base)
    config = astc.ASTCConfig(astc.ASTCProfile.LDR, 4, 4, 1, astc.ASTCQualityPreset.MEDIUM)
    context = astc.ASTCContext(config)
    astc_blocks = b"".join(astc_level(context, level) for level in levels)
    etc2_blocks = b"".join(etc2_level(level, is_alpha) for level in levels)
    etc2_kind = KIND_ETC2_RGBA if is_alpha else KIND_ETC2_RGB
    for target, blob in (
        (astc_out, header(KIND_ASTC, base, len(levels)) + astc_blocks),
        (etc2_out, header(etc2_kind, base, len(levels)) + etc2_blocks),
    ):
        Path(target).parent.mkdir(parents=True, exist_ok=True)
        Path(target).write_bytes(blob)
    return None


def listed_textures(data: Path, listing: Path) -> list[str]:
    if not listing.is_file():
        raise SystemExit(f"nấu texture: thiếu {listing}. Chạy TOOLS/run/trace_assets.py trước.")
    found = []
    for line in listing.read_text(encoding="utf-8").splitlines()[1:]:
        cells = line.split("\t")
        if len(cells) < 2:
            continue
        relative = cells[1]
        if relative.startswith("Material/") and relative.lower().endswith(".dds"):
            found.append(relative)
    return found


def is_stale(source: Path, targets: list[Path]) -> bool:
    if not all(target.is_file() for target in targets):
        return True
    newest_source = source.stat().st_mtime_ns
    return any(target.stat().st_mtime_ns < newest_source for target in targets)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", default="dev/client/assets")
    parser.add_argument("--out", default="build/mobile-textures")
    parser.add_argument("--list", default="")
    parser.add_argument("--jobs", type=int, default=max(1, (os.cpu_count() or 2) - 2))
    args = parser.parse_args()
    data = Path(args.data)
    out = Path(args.out)
    listing = Path(args.list) if args.list else data / "Table" / "mobile.files.tsv"
    out.mkdir(parents=True, exist_ok=True)
    stamp = out / STAMP_NAME
    is_current = stamp.is_file() and stamp.read_text(encoding="utf-8").strip() == str(BAKE_VERSION)
    jobs = []
    for relative in listed_textures(data, listing):
        source = data / relative
        targets = [out / ASTC_ROOT / relative, out / ETC2_ROOT / relative]
        if not source.is_file():
            raise SystemExit(f"nấu texture: danh sách có {relative} mà dữ liệu không có")
        if is_current and not is_stale(source, targets):
            continue
        jobs.append((str(source), str(targets[0]), str(targets[1])))
    print(f"nấu texture: {len(jobs)} tệp cần nấu")
    failures = []
    if jobs:
        with ProcessPoolExecutor(max_workers=args.jobs) as pool:
            for result in pool.map(bake_one, *zip(*jobs, strict=True), chunksize=4):
                if result is not None:
                    failures.append(result)
    if not is_current:
        stamp.write_text(f"{BAKE_VERSION}\n", encoding="utf-8")
    for failure in failures:
        print(f"nấu texture: KHÔNG NẤU ĐƯỢC {failure}", file=sys.stderr)
    print(f"nấu texture: xong, {len(jobs) - len(failures)} tệp nấu, {len(failures)} lỗi")
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
