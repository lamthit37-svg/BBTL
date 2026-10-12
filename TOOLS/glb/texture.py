# Giải ảnh texture của kho gốc (DDS nén DXT1/DXT3/DXT5 hoặc không nén, TGA) thành PNG không mất dữ
# liệu, để GLB tham chiếu (glTF chuẩn chỉ nhận PNG và JPEG). Chỉ mức mip 0 được giải; mip nhỏ hơn
# sinh lại được, tệp DDS gốc vẫn nằm trong kho gốc.
# Quyết định:
# - Giải khối BC theo định nghĩa của Direct3D 10: màu 5:6:5 đổi sang 8 bit bằng làm tròn chính xác,
#   màu nội suy là (2a + b) / 3 và (a + 2b) / 3 làm tròn chính xác trên phân số, không dùng công thức
#   xấp xỉ nguyên. Alpha DXT5 nội suy theo mẫu số 7 hoặc 5, cũng làm tròn chính xác.
# - DXT1 có texel trong suốt (chế độ 3 màu, chỉ số 3) thì ra RGBA, không thì ra RGB. DXT3 và DXT5
#   luôn ra RGBA, kể cả khi alpha toàn 255, để giữ đúng kênh mà tệp gốc có.
# - Cubemap và texture khối: chỉ giải mặt hay lát đầu tiên, có báo trong kết quả.

import struct
from dataclasses import dataclass

import numpy as np
from PIL import Image

DDS_MAGIC = b"DDS "
HEADER_BYTES = 128
FOURCC_FLAG = 0x4
LUMINANCE_FLAG = 0x20000
CUBEMAP_CAPS = 0x200
VOLUME_CAPS = 0x200000


class TextureError(Exception):
    pass


@dataclass
class Decoded:
    pixels: np.ndarray
    mode: str
    format: str
    has_mips: bool
    note: str = ""


# round(255 * numerator / denominator) bằng số nguyên, không sai số dấu phẩy động.
def round_to_byte(numerator: np.ndarray, denominator: int) -> np.ndarray:
    return ((2 * 255 * numerator + denominator) // (2 * denominator)).astype(np.uint8)


def unpack_565(colour: np.ndarray) -> tuple:
    return (colour >> 11) & 31, (colour >> 5) & 63, colour & 31


# Bảng 4 màu của từng khối, dạng [khối, 4, 4] (RGBA). is_punch cho phép chế độ 3 màu của DXT1.
def colour_palette(blocks: np.ndarray, is_punch: bool) -> np.ndarray:
    first = blocks[:, 0].astype(np.int64) | (blocks[:, 1].astype(np.int64) << 8)
    second = blocks[:, 2].astype(np.int64) | (blocks[:, 3].astype(np.int64) << 8)
    palette = np.zeros((len(blocks), 4, 4), np.uint8)
    palette[:, :, 3] = 255
    three = (first <= second) if is_punch else np.zeros(len(blocks), bool)
    limits = (31, 63, 31)
    for channel, (low, high) in enumerate(zip(unpack_565(first), unpack_565(second))):
        limit = limits[channel]
        palette[:, 0, channel] = round_to_byte(low, limit)
        palette[:, 1, channel] = round_to_byte(high, limit)
        third = round_to_byte(2 * low + high, 3 * limit)
        fourth = round_to_byte(low + 2 * high, 3 * limit)
        middle = round_to_byte(low + high, 2 * limit)
        palette[:, 2, channel] = np.where(three, middle, third)
        palette[:, 3, channel] = np.where(three, 0, fourth)
    palette[three, 3, 3] = 0
    return palette


# Chỉ số 2 bit của 16 texel, texel 0 ở bit thấp nhất, theo hàng từ trên xuống.
def colour_indices(blocks: np.ndarray) -> np.ndarray:
    bits = blocks[:, 4:8].astype(np.uint32)
    packed = bits[:, 0] | (bits[:, 1] << 8) | (bits[:, 2] << 16) | (bits[:, 3] << 24)
    shifts = np.arange(16, dtype=np.uint32) * 2
    return (packed[:, None] >> shifts[None, :]) & 3


def decode_colour(blocks: np.ndarray, is_punch: bool) -> np.ndarray:
    palette = colour_palette(blocks, is_punch)
    indices = colour_indices(blocks)
    rows = np.arange(len(blocks))[:, None]
    return palette[rows, indices]


def explicit_alpha(blocks: np.ndarray) -> np.ndarray:
    nibbles = np.empty((len(blocks), 16), np.uint8)
    nibbles[:, 0::2] = blocks[:, :8] & 15
    nibbles[:, 1::2] = blocks[:, :8] >> 4
    return nibbles * 17


def interpolated_alpha(blocks: np.ndarray) -> np.ndarray:
    first = blocks[:, 0].astype(np.int64)
    second = blocks[:, 1].astype(np.int64)
    palette = np.zeros((len(blocks), 8), np.uint8)
    palette[:, 0] = first
    palette[:, 1] = second
    eight = first > second
    for step in range(1, 7):
        value = ((7 - step) * first + step * second) * 2 + 7
        palette[:, step + 1] = np.where(eight, value // 14, 0)
    for step in range(1, 5):
        value = ((5 - step) * first + step * second) * 2 + 5
        palette[:, step + 1] = np.where(eight, palette[:, step + 1], value // 10)
    palette[~eight, 6] = 0
    palette[~eight, 7] = 255
    bits = np.zeros(len(blocks), np.uint64)
    for byte in range(6):
        bits |= blocks[:, 2 + byte].astype(np.uint64) << np.uint64(8 * byte)
    shifts = (np.arange(16, dtype=np.uint64) * 3)[None, :]
    indices = ((bits[:, None] >> shifts) & np.uint64(7)).astype(np.int64)
    rows = np.arange(len(blocks))[:, None]
    return palette[rows, indices]


# Xếp các khối 4x4 thành ảnh rồi cắt về đúng cỡ.
def blocks_to_image(texels: np.ndarray, width: int, height: int) -> np.ndarray:
    block_columns = (width + 3) // 4
    block_rows = (height + 3) // 4
    grid = texels.reshape(block_rows, block_columns, 4, 4, 4)
    image = grid.transpose(0, 2, 1, 3, 4).reshape(block_rows * 4, block_columns * 4, 4)
    return np.ascontiguousarray(image[:height, :width])


def decode_compressed(data: bytes, fourcc: bytes, width: int, height: int) -> tuple:
    block_bytes = 8 if fourcc == b"DXT1" else 16
    count = ((width + 3) // 4) * ((height + 3) // 4)
    if len(data) < count * block_bytes:
        raise TextureError("thiếu dữ liệu khối")
    blocks = np.frombuffer(data, np.uint8, count * block_bytes).reshape(count, block_bytes)
    if fourcc == b"DXT1":
        image = blocks_to_image(decode_colour(blocks, True), width, height)
        if (image[:, :, 3] == 255).all():
            return np.ascontiguousarray(image[:, :, :3]), "RGB"
        return image, "RGBA"
    texels = decode_colour(blocks[:, 8:], False)
    alpha = explicit_alpha(blocks) if fourcc == b"DXT3" else interpolated_alpha(blocks)
    texels[:, :, 3] = alpha
    return blocks_to_image(texels, width, height), "RGBA"


def mask_channel(pixels: np.ndarray, mask: int) -> np.ndarray:
    shift = (mask & -mask).bit_length() - 1
    limit = mask >> shift
    values = (pixels & mask) >> shift
    if limit == 255:
        return values.astype(np.uint8)
    return round_to_byte(values.astype(np.int64), limit)


def read_pixels(data: bytes, width: int, height: int, bit_count: int) -> np.ndarray:
    pixel_bytes = bit_count // 8
    row_bytes = width * pixel_bytes
    aligned = (row_bytes + 3) // 4 * 4
    pitch = aligned if len(data) >= aligned * height else row_bytes
    if len(data) < pitch * height or pixel_bytes not in (1, 2, 3, 4):
        raise TextureError("thiếu dữ liệu điểm ảnh")
    rows = np.frombuffer(data, np.uint8, pitch * height).reshape(height, pitch)
    raw = rows[:, :row_bytes].reshape(height, width, pixel_bytes).astype(np.uint32)
    pixels = np.zeros((height, width), np.uint32)
    for index in range(pixel_bytes):
        pixels |= raw[:, :, index] << (8 * index)
    return pixels


def decode_plain(data: bytes, width: int, height: int, pixel_format: tuple) -> tuple:
    flags, _, bit_count, red, green, blue, alpha = pixel_format
    pixels = read_pixels(data, width, height, bit_count)
    if flags & LUMINANCE_FLAG or (red and not green and not blue):
        grey = mask_channel(pixels, red)
        if not alpha:
            return grey, "L"
        return np.dstack([grey, mask_channel(pixels, alpha)]), "LA"
    if not (red and green and blue):
        raise TextureError(f"mặt nạ màu lạ: {red:#x} {green:#x} {blue:#x}")
    channels = [mask_channel(pixels, mask) for mask in (red, green, blue)]
    if alpha:
        channels.append(mask_channel(pixels, alpha))
    return np.dstack(channels), "RGBA" if alpha else "RGB"


def decode_dds(data: bytes) -> Decoded:
    if len(data) < HEADER_BYTES or data[:4] != DDS_MAGIC:
        raise TextureError("không phải tệp DDS")
    height, width = struct.unpack_from("<2I", data, 12)
    mip_count = struct.unpack_from("<I", data, 28)[0]
    pixel_format = struct.unpack_from("<I4s5I", data, 80)
    caps2 = struct.unpack_from("<I", data, 112)[0]
    if width == 0 or height == 0:
        raise TextureError("ảnh cỡ 0")
    flags, fourcc = pixel_format[0], pixel_format[1]
    body = data[HEADER_BYTES:]
    note = "cubemap: chỉ mặt đầu" if caps2 & CUBEMAP_CAPS else ""
    note = "texture khối: chỉ lát đầu" if caps2 & VOLUME_CAPS else note
    if flags & FOURCC_FLAG:
        if fourcc not in (b"DXT1", b"DXT3", b"DXT5"):
            raise TextureError(f"FourCC không hỗ trợ: {fourcc!r}")
        pixels, mode = decode_compressed(body, fourcc, width, height)
        return Decoded(pixels, mode, fourcc.decode(), mip_count > 1, note)
    pixels, mode = decode_plain(body, width, height, pixel_format)
    return Decoded(pixels, mode, f"{mode}{pixel_format[2]}", mip_count > 1, note)


def save_png(pixels: np.ndarray, mode: str, path: str) -> None:
    Image.fromarray(pixels, mode).save(path, format="PNG", compress_level=6)


# Đổi một tệp ảnh nguồn thành PNG ở target; trả về (định dạng nguồn, chế độ, rộng, cao, ghi chú).
def convert_to_png(source: str, target: str) -> tuple:
    with open(source, "rb") as stream:
        data = stream.read()
    if data[:4] == DDS_MAGIC:
        decoded = decode_dds(data)
        save_png(decoded.pixels, decoded.mode, target)
        height, width = decoded.pixels.shape[:2]
        return decoded.format, decoded.mode, width, height, decoded.note
    with Image.open(source) as image:
        image.load()
        kind = image.format or "?"
        if image.mode not in ("L", "LA", "RGB", "RGBA"):
            image = image.convert("RGBA")
        image.save(target, format="PNG", compress_level=6)
        return kind, image.mode, image.width, image.height, ""
