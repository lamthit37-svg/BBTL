"""Đo mốc thời gian nạp của một chương trình từ ngoài: chạy nó rồi ghi (ms tính từ lúc tạo tiến trình) hai loại mốc
mà không cần chương trình có đồng hồ riêng:
  --watch <thư mục>   thời điểm ghi của từng tệp mới xuất hiện ở đó (ảnh chụp do chính game ghi: mốc kèm bằng chứng
                      nhìn được, và là mốc duy nhất đo được ở chương trình xả stdout theo khối 4 KB);
  --mark <regex>      thời điểm dòng stdout khớp xuất hiện lần đầu (chỉ đúng khi chương trình xả theo dòng;
                      --probe in cả dòng kèm mốc để kiểm điều đó trước khi tin số).
Dừng khi hết --limit giây, khi chương trình thoát, hoặc khi gặp dòng khớp --stop-on, hoặc khi đủ --until-files tệp mới.
Dùng cho cả client này lẫn client tham chiếu (G:\\TLBB) để cùng một thước đo. Không đụng chuột, bàn phím hay cửa sổ.

Ví dụ:
  python TOOLS/run/launch_timeline.py --watch build/shots --until-files 2 --limit 60 -- exe --đối-số
In bảng mốc rồi một khối JSON tóm tắt (--json <tệp> thì ghi ra tệp).
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import threading
import time
from pathlib import Path


def read_lines(stream, sink: list[tuple[float, str]], started: float) -> None:
    # Đọc từng dòng thô rồi giải mã UTF-8; thời điểm lấy ngay khi dòng tới.
    for raw in iter(stream.readline, b""):
        sink.append(((time.perf_counter() - started) * 1000.0, raw.decode("utf-8", errors="replace").rstrip("\r\n")))


def parse_arguments() -> tuple[argparse.Namespace, list[str]]:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--stop-on", default="", help="regex: gặp dòng khớp thì dừng chương trình")
    parser.add_argument("--limit", type=float, default=60.0, help="số giây tối đa trước khi dừng")
    parser.add_argument("--mark", action="append", default=[], help="regex: in mốc đầu tiên của dòng khớp")
    parser.add_argument("--watch", default=None, help="thư mục theo dõi tệp mới")
    parser.add_argument("--until-files", type=int, default=0, help="dừng khi --watch có đủ ngần ấy tệp mới")
    parser.add_argument("--cwd", default=None, help="thư mục chạy (mặc định: thư mục hiện tại, để đường dẫn tương đối của đối số còn đúng)")
    parser.add_argument("--json", default=None, help="ghi tóm tắt ra tệp JSON này")
    parser.add_argument("--probe", action="store_true", help="in cả dòng log kèm mốc (kiểm bộ đệm stdout)")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    command = arguments.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("thiếu lệnh sau --")
    return arguments, command


def new_files(folder: Path, before: set[str]) -> list[Path]:
    if not folder.is_dir():
        return []
    return sorted(path for path in folder.iterdir() if path.is_file() and path.name not in before)


def stat_of(path: Path, start_ns: int) -> dict[str, float] | None:
    try:
        info = path.stat()
    except OSError:
        return None
    return {"ghi ms": (info.st_mtime_ns - start_ns) / 1e6, "tạo ms": (info.st_ctime_ns - start_ns) / 1e6,
            "byte": float(info.st_size)}


def main() -> int:
    arguments, command = parse_arguments()
    command[0] = str(Path(command[0]).resolve())
    stop = re.compile(arguments.stop_on) if arguments.stop_on else None
    marks = [(pattern, re.compile(pattern)) for pattern in arguments.mark]
    folder = Path(arguments.watch) if arguments.watch else None
    before = {path.name for path in folder.iterdir()} if folder and folder.is_dir() else set()
    lines: list[tuple[float, str]] = []
    start_ns = time.time_ns()
    started = time.perf_counter()
    process = subprocess.Popen(command, cwd=arguments.cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=0)
    reader = threading.Thread(target=read_lines, args=(process.stdout, lines, started), daemon=True)
    reader.start()
    seen = 0
    stopped_at = None
    reason = "hết giờ"
    while time.perf_counter() - started < arguments.limit:
        if process.poll() is not None:
            reason = f"thoát mã {process.returncode}"
            break
        while seen < len(lines):
            if stop is not None and stop.search(lines[seen][1]):
                stopped_at = lines[seen][0]
                reason = "gặp dòng dừng"
            seen += 1
        if folder and arguments.until_files and len(new_files(folder, before)) >= arguments.until_files:
            # Cho tệp cuối ghi xong trước khi dừng chương trình.
            time.sleep(0.3)
            reason = "đủ tệp"
            break
        if stopped_at is not None:
            break
        time.sleep(0.002)
    if process.poll() is None:
        process.kill()
    process.wait()
    reader.join(timeout=2.0)
    hits: dict[str, float | None] = {}
    for pattern, compiled in marks:
        hits[pattern] = next((at for at, text in lines if compiled.search(text)), None)
    files: dict[str, dict[str, float]] = {}
    if folder:
        for path in new_files(folder, before):
            found = stat_of(path, start_ns)
            if found:
                files[path.name] = found
    summary = {
        "lệnh": command[0],
        "lý do dừng": reason,
        "mốc dừng ms": stopped_at,
        "số dòng": len(lines),
        "mốc dòng ms": hits,
        "tệp mới": files,
        "tổng ms": (time.perf_counter() - started) * 1000.0,
    }
    if arguments.probe:
        for at, text in lines:
            print(f"{at:9.1f} ms  {text}")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    if arguments.json:
        Path(arguments.json).write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
