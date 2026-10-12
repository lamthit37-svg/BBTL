# Ghép mọi ô giao diện đang dùng thành một PNG. Ô lấy từ assets/ui/sheet, ảnh từ Interface gốc.
#   python -B TOOLS/content/pack_ui_sheet.py "F:/tl 2026/_goc/Interface" assets/ui assets/ui/ui_parts.png
from __future__ import annotations

import argparse
import struct
from pathlib import Path

import numpy as np
from PIL import Image

GAP = 2
PAGE = 4096


def rgb565(value: int) -> tuple[int, int, int]:
    red = (value >> 11) & 31
    green = (value >> 5) & 63
    blue = value & 31
    return (red << 3) | (red >> 2), (green << 2) | (green >> 4), (blue << 3) | (blue >> 2)


def mix(left: tuple[int, int, int], right: tuple[int, int, int], numer: int, denom: int) -> tuple[int, int, int]:
    return tuple((left[i] * (denom - numer) + right[i] * numer) // denom for i in range(3))


def decode_dxt1_block(raw: bytes, opaque: bool) -> np.ndarray:
    color0, color1 = struct.unpack_from("<HH", raw, 0)
    bits = struct.unpack_from("<I", raw, 4)[0]
    c0 = rgb565(color0)
    c1 = rgb565(color1)
    if color0 > color1 or opaque:
        colors = [c0, c1, mix(c0, c1, 1, 3), mix(c0, c1, 2, 3)]
        alphas = [255, 255, 255, 255]
    else:
        colors = [c0, c1, mix(c0, c1, 1, 2), (0, 0, 0)]
        alphas = [255, 255, 255, 0]
    pixels = np.zeros((4, 4, 4), np.uint8)
    for index in range(16):
        choice = (bits >> (2 * index)) & 3
        y, x = divmod(index, 4)
        pixels[y, x, 0:3] = colors[choice]
        pixels[y, x, 3] = alphas[choice]
    return pixels


def decode_dxt3_block(raw: bytes) -> np.ndarray:
    pixels = decode_dxt1_block(raw[8:16], opaque=True)
    alpha_bits = struct.unpack_from("<Q", raw, 0)[0]
    for index in range(16):
        nibble = (alpha_bits >> (4 * index)) & 15
        y, x = divmod(index, 4)
        pixels[y, x, 3] = (nibble << 4) | nibble
    return pixels


def decode_dds(path: Path) -> np.ndarray:
    raw = path.read_bytes()
    if raw[:4] != b"DDS ":
        picture = Image.open(path).convert("RGBA")
        return np.asarray(picture)
    height = struct.unpack_from("<I", raw, 12)[0]
    width = struct.unpack_from("<I", raw, 16)[0]
    fourcc = raw[84:88]
    body = raw[128:]
    picture = np.zeros((height, width, 4), np.uint8)
    blocks_x = (width + 3) // 4
    if fourcc == b"DXT1":
        step = 8
        decoder = lambda block: decode_dxt1_block(block, opaque=False)
    elif fourcc == b"DXT3":
        step = 16
        decoder = decode_dxt3_block
    else:
        raise ValueError(f"{path.name}: fourcc {fourcc!r} chưa đọc")
    for block_y in range(0, height, 4):
        for block_x in range(0, width, 4):
            start = ((block_y // 4) * blocks_x + (block_x // 4)) * step
            block = decoder(body[start : start + step])
            picture[block_y : block_y + 4, block_x : block_x + 4] = block[: height - block_y, : width - block_x]
    return picture


def cells_of(folder: Path) -> list[tuple[str, str, int, int, int, int]]:
    found: list[tuple[str, str, int, int, int, int]] = []
    for sheet in sorted(folder.glob("*.tsv")):
        for line in sheet.read_text(encoding="utf-8").splitlines()[2:]:
            parts = line.split("\t")
            if len(parts) < 6 or parts[1] == "":
                continue
            found.append((parts[5], parts[0], int(parts[1]), int(parts[2]), int(parts[3]), int(parts[4])))
    return found


def crop(atlas: np.ndarray, x: int, y: int, w: int, h: int) -> np.ndarray:
    height, width = atlas.shape[:2]
    x0 = max(0, min(x, width))
    y0 = max(0, min(y, height))
    x1 = max(x0, min(x + w, width))
    y1 = max(y0, min(y + h, height))
    piece = atlas[y0:y1, x0:x1]
    if piece.shape[0] == h and piece.shape[1] == w:
        return piece
    canvas = np.zeros((h, w, 4), np.uint8)
    canvas[: piece.shape[0], : piece.shape[1]] = piece
    return canvas


def pack(pieces: list[np.ndarray]) -> np.ndarray:
    order = sorted(range(len(pieces)), key=lambda index: pieces[index].shape[0], reverse=True)
    shelves: list[tuple[int, int, int]] = []
    spots: dict[int, tuple[int, int]] = {}
    width = max(PAGE, max(piece.shape[1] for piece in pieces))
    used_h = 0
    for index in order:
        piece = pieces[index]
        h, w = piece.shape[:2]
        placed = False
        for shelf_i, (sy, sh, sx) in enumerate(shelves):
            if w <= width - sx and h <= sh:
                spots[index] = (sx, sy)
                shelves[shelf_i] = (sy, sh, sx + w + GAP)
                placed = True
                break
        if placed:
            continue
        spots[index] = (0, used_h)
        shelves.append((used_h, h, w + GAP))
        used_h += h + GAP
    canvas = np.zeros((max(used_h - GAP, 1), width, 4), np.uint8)
    for index, piece in enumerate(pieces):
        x, y = spots[index]
        h, w = piece.shape[:2]
        canvas[y : y + h, x : x + w] = piece
    # Cắt phần phải không dùng.
    used = 0
    for piece, (x, _y) in ((pieces[i], spots[i]) for i in range(len(pieces))):
        used = max(used, x + piece.shape[1])
    return canvas[:, : max(used, 1)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("interface", type=Path)
    parser.add_argument("sheets", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    cache: dict[str, np.ndarray] = {}
    pieces: list[np.ndarray] = []
    for rel, _name, x, y, w, h in cells_of(args.sheets):
        if w <= 0 or h <= 0:
            continue
        if rel not in cache:
            cache[rel] = decode_dds(args.interface / rel)
        pieces.append(crop(cache[rel], x, y, w, h))
    sheet = pack(pieces)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(sheet, "RGBA").save(args.out)
    print(f"{len(pieces)} ô, {sheet.shape[1]}x{sheet.shape[0]} -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
