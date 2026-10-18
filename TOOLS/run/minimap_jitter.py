# Đo độ rung của minimap (NGHI-NGO 63j, việc "khung minimap rung lắc"): đọc các ảnh chụp liên tiếp của client lúc nhân vật
# đang đi và so vùng minimap của từng cặp ảnh kề nhau. Gốc làm mới minimap theo nhịp UPDATE_MAP (khoảng 9 lần mỗi giây);
# giữa hai nhịp nền, mũi tên và chữ đứng yên, tại nhịp nền chỉ tịnh tiến nguyên điểm ảnh (CEGUI PixelAligned). Vậy mỗi cặp
# phải là "giống từng byte" hoặc "tịnh tiến nguyên điểm ảnh, sai khác gần 0"; cặp nào không rơi vào hai loại ấy là rung.
# Chỉ xét vành tròn quanh tâm minimap, bỏ phần giữa: mũi tên và chùm sáng (64 x 64) nằm ở đó và đổi theo hướng.
# Cách chụp: client chạy offline với --walk (nhân vật tự đi, camera xoay đều) và một kịch bản chỉ có chuỗi `shot`
# (mỗi `shot` khoảng 60 ms nên hai ảnh kề nhau nằm trong cùng một nhịp hoặc cách một nhịp).
#   thienlong_client --scene-id 2 --walk --script <kịch bản> --shot-dir <thư mục>
# Chạy: py -X utf8 TOOLS/run/minimap_jitter.py <thư mục ảnh> [--centre x,y] [--radius r]
# Mã thoát: 0 khi mọi cặp đều giống hệt hoặc tịnh tiến nguyên, 1 khi có cặp không giải thích được, 2 khi thiếu ảnh.
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# Tâm minimap ở màn 1280 x 720 (cửa sổ MiniMap_MapArea 119 x 121), vành xét từ INNER tới OUTER điểm ảnh.
DEFAULT_CENTRE = (1184, 103)
INNER = 36
OUTER = 52
REACH = 4
# Sai khác coi là bằng nhau khi tịnh tiến: lấy mẫu GPU có thể lệch một mức màu ở vài điểm ảnh.
TOLERANCE_MEAN = 0.5


def ring_mask(shape: tuple[int, int], centre: tuple[int, int], inner: int, outer: int) -> np.ndarray:
    ys, xs = np.ogrid[: shape[0], : shape[1]]
    dist = np.hypot(xs - centre[0], ys - centre[1])
    return (dist >= inner) & (dist <= outer)


def load(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.int16)


def best_shift(before: np.ndarray, after: np.ndarray, mask: np.ndarray) -> tuple[int, int, float, int]:
    """Tịnh tiến (dx, dy) nguyên làm trung bình |sau - trước dời| trên vành nhỏ nhất; trả cả sai khác lớn nhất."""
    best = (0, 0, float("inf"), 0)
    inner = np.roll(np.roll(mask, 0, axis=0), 0, axis=1)
    for dy in range(-REACH, REACH + 1):
        for dx in range(-REACH, REACH + 1):
            moved = np.roll(np.roll(before, dy, axis=0), dx, axis=1)
            valid = inner & np.roll(np.roll(inner, dy, axis=0), dx, axis=1)
            diff = np.abs(after - moved)[valid]
            mean = float(diff.mean())
            if mean < best[2]:
                best = (dx, dy, mean, int(diff.max()))
    return best


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Đo độ rung của minimap trên các ảnh chụp liên tiếp")
    parser.add_argument("folder", help="thư mục ảnh png (theo thứ tự tên)")
    parser.add_argument("--centre", default="", help="x,y tâm minimap trên màn (mặc định 1184,103)")
    parser.add_argument("--radius", type=int, default=OUTER, help="bán kính ngoài của vành xét")
    chosen = parser.parse_args(argv)
    paths = sorted(Path(chosen.folder).glob("*.png"))
    if len(paths) < 2:
        print(f"cần ít nhất hai ảnh trong {chosen.folder}")
        return 2
    centre = DEFAULT_CENTRE
    if chosen.centre:
        across, down = chosen.centre.split(",")
        centre = (int(across), int(down))
    images = [load(path) for path in paths]
    mask = ring_mask(images[0].shape[:2], centre, INNER, chosen.radius)
    same = 0
    shifted = 0
    bad = 0
    for index in range(len(images) - 1):
        before, after = images[index], images[index + 1]
        if np.array_equal(before[mask], after[mask]):
            same += 1
            print(f"{paths[index].name} -> {paths[index + 1].name}: giống từng byte")
            continue
        dx, dy, mean, peak = best_shift(before, after, mask)
        whole = (dx, dy) != (0, 0)
        if whole and mean <= TOLERANCE_MEAN:
            shifted += 1
            print(f"{paths[index].name} -> {paths[index + 1].name}: tịnh tiến ({dx},{dy}) điểm ảnh, sai khác tb {mean:.3f} max {peak}")
            continue
        bad += 1
        print(f"{paths[index].name} -> {paths[index + 1].name}: KHÔNG GIẢI THÍCH ĐƯỢC, tịnh tiến gần nhất ({dx},{dy}) sai khác tb {mean:.3f} max {peak}")
    total = len(images) - 1
    print(f"tổng {total} cặp: giống từng byte {same}, tịnh tiến nguyên {shifted}, không giải thích được {bad}")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
