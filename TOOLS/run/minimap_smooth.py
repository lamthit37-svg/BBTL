# Đo độ mượt của minimap lúc nhân vật đi (NGHI-NGO 63j): đọc các ảnh chụp liên tiếp của client chạy offline với --walk
# và đo hai thứ chủ dự án đòi ở minimap (2026-10-18).
#   1. Độ nét không "thở": với mỗi cặp ảnh kề nhau, nền trong vành tròn quanh tâm được căn theo tịnh tiến nguyên rồi so
#      tổng |Laplacian| của cùng một vùng nội dung ở hai ảnh. Tỉ số khác 1 nghĩa là độ nét đổi chỉ vì pha lấy mẫu dưới
#      điểm ảnh đổi (nội dung đã loại bằng phép căn). Đạt khi mọi cặp lệch dưới --limit (mặc định 2%).
#   2. Nền chỉ tịnh tiến: sai khác trung bình còn lại sau khi căn (phần nào nhảy hay đổi hình sẽ làm nó vọt lên).
# Chỉ xét vành INNER..OUTER điểm ảnh quanh tâm để bỏ phần giữa nơi mũi tên và chùm sáng (64 x 64) nằm.
# Chế độ --map-snap (nền nhích nguyên điểm ảnh) cho tỉ số đúng 1: nền chỉ tịnh tiến nguyên.
# Cách chụp: client offline, nhân vật tự đi (--walk), kịch bản chỉ có chuỗi `shot` (k-minimap-smooth.script):
#   thienlong_client --scene-id 2 --walk --script <kịch bản> --shot-dir <thư mục> [--map-snap]
# Chạy: py -X utf8 TOOLS/run/minimap_smooth.py <thư mục ảnh> [--centre x,y] [--limit 0.02] [--quiet]
# Mã thoát: 0 khi đạt, 1 khi có cặp lệch quá giới hạn, 2 khi thiếu ảnh.
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
# Tầm tìm tịnh tiến nguyên giữa hai ảnh kề nhau (điểm ảnh).
REACH = 5


def load(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)


def grey(image: np.ndarray) -> np.ndarray:
    return (0.299 * image[..., 0]) + (0.587 * image[..., 1]) + (0.114 * image[..., 2])


def laplacian(plane: np.ndarray) -> np.ndarray:
    out = np.zeros_like(plane)
    out[1:-1, 1:-1] = (4.0 * plane[1:-1, 1:-1]) - plane[:-2, 1:-1] - plane[2:, 1:-1] - plane[1:-1, :-2] - plane[1:-1, 2:]
    return out


def ring_mask(shape: tuple[int, int], centre: tuple[int, int]) -> np.ndarray:
    ys, xs = np.ogrid[: shape[0], : shape[1]]
    dist = np.hypot(xs - centre[0], ys - centre[1])
    return (dist >= INNER) & (dist <= OUTER)


def shifted(plane: np.ndarray, dx: int, dy: int) -> np.ndarray:
    return np.roll(np.roll(plane, dy, axis=0), dx, axis=1)


def best_shift(before: np.ndarray, after: np.ndarray, mask: np.ndarray) -> tuple[int, int, float]:
    """Tịnh tiến nguyên (dx, dy) làm trung bình |sau - trước dời| trên vành nhỏ nhất, kèm sai khác đó."""
    best = (0, 0, float("inf"))
    for dy in range(-REACH, REACH + 1):
        for dx in range(-REACH, REACH + 1):
            valid = mask & shifted(mask, dx, dy)
            diff = np.abs(after - shifted(before, dx, dy))[valid]
            mean = float(diff.mean())
            if mean < best[2]:
                best = (dx, dy, mean)
    return best


def sharp_ratio(before: np.ndarray, after: np.ndarray, mask: np.ndarray, dx: int, dy: int) -> float:
    """Tổng |Laplacian| của ảnh sau chia ảnh trước, cùng vùng nội dung sau khi dời ảnh trước (dx, dy)."""
    valid = mask & shifted(mask, dx, dy)
    left = np.abs(laplacian(shifted(before, dx, dy)))[valid].sum()
    right = np.abs(laplacian(after))[valid].sum()
    return float(right / left) if left > 0.0 else 1.0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Đo độ mượt của minimap trên các ảnh chụp liên tiếp")
    parser.add_argument("folder", help="thư mục ảnh png (theo thứ tự tên)")
    parser.add_argument("--centre", default="", help="x,y tâm minimap trên màn (mặc định 1184,103)")
    parser.add_argument("--limit", type=float, default=0.02, help="lệch độ nét tối đa giữa hai ảnh kề nhau (mặc định 2%%)")
    parser.add_argument("--quiet", action="store_true", help="chỉ in tổng kết")
    chosen = parser.parse_args(argv)
    paths = sorted(Path(chosen.folder).glob("*.png"))
    if len(paths) < 3:
        print(f"cần ít nhất ba ảnh trong {chosen.folder}")
        return 2
    centre = DEFAULT_CENTRE
    if chosen.centre:
        across, down = chosen.centre.split(",")
        centre = (int(across), int(down))
    planes = [grey(load(path)) for path in paths]
    mask = ring_mask(planes[0].shape, centre)
    deviations = []
    residuals = []
    still = 0
    for index in range(len(planes) - 1):
        dx, dy, residual = best_shift(planes[index], planes[index + 1], mask)
        if (dx, dy) == (0, 0):
            still += 1
        ratio = sharp_ratio(planes[index], planes[index + 1], mask, dx, dy)
        deviations.append(abs(ratio - 1.0))
        residuals.append(residual)
        if not chosen.quiet:
            print(f"{paths[index].name} -> {paths[index + 1].name}: dời ({dx},{dy}) sai khác tb {residual:.2f} độ nét x{ratio:.4f}")
    worst = max(deviations)
    mean = float(np.mean(deviations))
    p95 = float(np.percentile(deviations, 95))
    rms = float(np.sqrt(np.mean(np.square(deviations))))
    print(f"ảnh {len(paths)}, cặp đứng yên {still}, sai khác dư tb {np.mean(residuals):.2f} lớn nhất {max(residuals):.2f}")
    print(f"độ nét giữa hai ảnh kề nhau lệch: tb {mean * 100.0:.2f}%, rms {rms * 100.0:.2f}%, p95 {p95 * 100.0:.2f}%, lớn nhất {worst * 100.0:.2f}% (giới hạn {chosen.limit * 100.0:.1f}%)")
    is_sharp = worst <= chosen.limit
    print(f"độ nét không thở: {'ĐẠT' if is_sharp else 'KHÔNG ĐẠT'}")
    return 0 if is_sharp else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
