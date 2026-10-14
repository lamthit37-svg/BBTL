"""Đo thời gian nạp của một chương trình nhiều lần và tóm tắt (trung vị, nhỏ nhất, lớn nhất) — cùng một thước đo cho
client này và client tham chiếu (G:\\TLBB), để so số với số.

Mỗi lượt chạy chương trình từ đầu (đã tạo tiến trình mới), đo ba loại mốc, mọi mốc tính bằng ms từ lúc chạy lệnh:
  --mark <regex>        dòng stdout khớp đầu tiên có chữ "Mốc <ms> ms" (client này tự in, tính từ lúc hệ điều hành
                        tạo tiến trình: chính xác nhất; xem engine/core/timeline.hpp). Một mốc một metric.
  --watch <thư mục>     thời điểm GHI của từng tệp mới xuất hiện (ảnh do chính chương trình chụp: mốc có bằng chứng
                        nhìn được). Dừng khi đủ --until-files tệp hoặc hết --limit giây.
  --background R,G,B    với --watch: ảnh nào có phần giữa màn hình khác màu nền này quá --world-fraction thì tính là
                        "đã hiện thế giới"; metric 'thế giới hiện' là tệp sớm nhất như vậy. Cần Pillow.
  --stable-diff <số>    với --watch: metric 'khung ổn định' là tệp sớm nhất mà độ lệch trung bình (thang xám 0..255, ảnh
                        thu 320x180) so với tệp cuối không quá số này — tức lúc cảnh và giao diện đã đầy đủ như khung
                        cuối. Tệp cuối phải chụp sau khi mọi thứ đã nạp xong (kịch bản chụp đủ lâu). Cần Pillow.
Không đụng chuột, bàn phím hay cửa sổ. Chương trình bị kill khi đủ dữ liệu.

Ví dụ (client này, mốc trong tiến trình):
  python TOOLS/run/bench_load.py --runs 10 --mark "khung đầu đã trình" --cwd dev/client/bin -- \\
      ./thienlong_client.exe --scene-id 2 --size 1280x720 --frames 60
Ví dụ (client tham chiếu, ảnh do nó chụp theo kịch bản): xem docs/TIEN-DO.md mục "Tốc độ nạp".
Ghi toàn bộ số từng lượt ra --json <tệp> nếu cần.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import subprocess
import sys
import threading
import time
from pathlib import Path

MARK_VALUE = re.compile(r"Mốc\s+([0-9]+(?:\.[0-9]+)?)\s*ms")


def read_lines(stream, sink: list[str]) -> None:
    for raw in iter(stream.readline, b""):
        sink.append(raw.decode("utf-8", errors="replace").rstrip("\r\n"))


def parse_arguments() -> tuple[argparse.Namespace, list[str]]:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--runs", type=int, default=7, help="số lượt chạy (mặc định 7)")
    parser.add_argument("--label", default="", help="tên hiện trong bảng tóm tắt")
    parser.add_argument("--mark", action="append", default=[], help="regex của dòng stdout có 'Mốc <ms> ms' (lặp được)")
    parser.add_argument("--watch", default=None, help="thư mục theo dõi tệp mới (được xoá sạch trước mỗi lượt)")
    parser.add_argument("--until-files", type=int, default=0, help="với --watch: dừng khi đủ ngần ấy tệp mới")
    parser.add_argument("--limit", type=float, default=60.0, help="số giây tối đa mỗi lượt")
    parser.add_argument("--cwd", default=None, help="thư mục chạy lệnh")
    parser.add_argument("--env", action="append", default=[], help="KHOÁ=GIÁTRỊ đặt cho tiến trình (lặp được)")
    parser.add_argument("--background", default=None, help="R,G,B của màu nền lúc chưa có thế giới (dùng với --watch)")
    parser.add_argument("--world-fraction", type=float, default=0.2,
                        help="tỉ lệ điểm ảnh khác nền để tính là đã hiện thế giới (mặc định 0.2)")
    parser.add_argument("--stable-diff", type=float, default=None,
                        help="độ lệch trung bình tối đa so với tệp cuối để tính là khung ổn định (vd 1.0)")
    parser.add_argument("--settle", type=float, default=0.3, help="giây chờ sau tệp cuối cho nó ghi xong (mặc định 0.3)")
    parser.add_argument("--json", default=None, help="ghi số từng lượt và tóm tắt ra tệp JSON này")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    command = arguments.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("thiếu lệnh sau --")
    return arguments, command


def world_fraction(path: Path, background: tuple[int, int, int]) -> float:
    # Phần giữa màn hình (bỏ viền 1/8 hai bên và nửa dưới) khác màu nền bao nhiêu.
    from PIL import Image

    image = Image.open(path).convert("RGB")
    width, height = image.size
    box = image.crop((width // 8, height // 8, width * 7 // 8, height * 5 // 8)).resize((64, 32))
    pixels = list(box.get_flattened_data()) if hasattr(box, "get_flattened_data") else list(box.getdata())
    near = sum(1 for p in pixels if all(abs(p[i] - background[i]) < 7 for i in range(3)))
    return 1.0 - near / len(pixels)


def difference_to(path: Path, last: Path) -> float:
    # Độ lệch trung bình (thang xám) giữa hai ảnh sau khi thu về 320x180.
    from PIL import Image, ImageChops

    left = Image.open(path).convert("RGB").resize((320, 180))
    right = Image.open(last).convert("RGB").resize((320, 180))
    histogram = ImageChops.difference(left, right).convert("L").histogram()
    return sum(level * count for level, count in enumerate(histogram)) / sum(histogram)


def one_run(arguments: argparse.Namespace, command: list[str], environment: dict[str, str]) -> dict[str, float | None]:
    folder = Path(arguments.watch) if arguments.watch else None
    if folder:
        folder.mkdir(parents=True, exist_ok=True)
        for item in folder.iterdir():
            if item.is_file():
                item.unlink()
    lines: list[str] = []
    start_ns = time.time_ns()
    started = time.perf_counter()
    process = subprocess.Popen(command, cwd=arguments.cwd, env=environment, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, bufsize=0)
    reader = threading.Thread(target=read_lines, args=(process.stdout, lines), daemon=True)
    reader.start()
    expected = [re.compile(pattern) for pattern in arguments.mark]
    enough = False
    while time.perf_counter() - started < arguments.limit and not enough:
        if process.poll() is not None:
            break
        if folder and arguments.until_files and sum(1 for p in folder.iterdir() if p.is_file()) >= arguments.until_files:
            time.sleep(arguments.settle)
            enough = True
        elif expected and not folder and all(any(rule.search(text) for text in lines) for rule in expected):
            enough = True
        time.sleep(0.002)
    if process.poll() is None:
        process.kill()
    process.wait()
    reader.join(timeout=2.0)
    result: dict[str, float | None] = {}
    for pattern, rule in zip(arguments.mark, expected):
        value = None
        for text in lines:
            if rule.search(text):
                found = MARK_VALUE.search(text)
                value = float(found.group(1)) if found else None
                break
        result[f"mốc: {pattern}"] = value
    stamps: list[tuple[float, Path]] = []
    if folder:
        files = sorted((p for p in folder.iterdir() if p.is_file()), key=lambda p: p.stat().st_mtime_ns)
        stamps = [((p.stat().st_mtime_ns - start_ns) / 1e6, p) for p in files]
        result["tệp đầu tiên"] = stamps[0][0] if stamps else None
        if arguments.background:
            background = tuple(int(part) for part in arguments.background.split(","))
            result["thế giới hiện"] = next(
                (at for at, path in stamps if world_fraction(path, background) >= arguments.world_fraction), None)
    if folder and arguments.stable_diff is not None and stamps:
        last = stamps[-1][1]
        result["khung ổn định"] = next(
            (at for at, path in stamps if difference_to(path, last) <= arguments.stable_diff), None)
    return result


def summarise(rows: list[dict[str, float | None]]) -> dict[str, dict[str, float | int]]:
    names = sorted({key for row in rows for key in row})
    summary: dict[str, dict[str, float | int]] = {}
    for name in names:
        values = [row[name] for row in rows if row.get(name) is not None]
        if not values:
            summary[name] = {"n": 0}
            continue
        summary[name] = {"n": len(values), "trung vị": statistics.median(values), "nhỏ nhất": min(values),
                         "lớn nhất": max(values)}
    return summary


def main() -> int:
    arguments, command = parse_arguments()
    # CreateProcess tìm exe tương đối theo thư mục của tiến trình cha, không theo --cwd: đổi sang đường dẫn tuyệt đối.
    base = Path(arguments.cwd) if arguments.cwd else Path.cwd()
    exe = Path(command[0])
    command[0] = str((exe if exe.is_absolute() else base / exe).resolve())
    environment = dict(os.environ)
    for item in arguments.env:
        key, _, value = item.partition("=")
        environment[key] = value
    rows = []
    for index in range(arguments.runs):
        row = one_run(arguments, command, environment)
        rows.append(row)
        shown = ", ".join(f"{name} = {value:.1f}" if value is not None else f"{name} = (không có)" for name, value in row.items())
        print(f"lượt {index + 1}/{arguments.runs}: {shown}", flush=True)
    summary = summarise(rows)
    label = arguments.label or Path(command[0]).name
    print(f"\n== {label} — {arguments.runs} lượt ==")
    for name, stats in summary.items():
        if stats["n"] == 0:
            print(f"{name}: không đo được lượt nào")
            continue
        print(f"{name}: trung vị {stats['trung vị']:.1f} ms, nhỏ nhất {stats['nhỏ nhất']:.1f}, lớn nhất {stats['lớn nhất']:.1f}"
              f" (n = {stats['n']})")
    if arguments.json:
        Path(arguments.json).write_text(
            json.dumps({"nhãn": label, "lệnh": command, "từng lượt": rows, "tóm tắt": summary}, ensure_ascii=False, indent=2),
            encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
