#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/run/trace_assets.py
#  PHÂN HỆ   : Run / Trace Assets
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Chạy client PC qua các kịch bản (đăng nhập, màn chơi ở cảnh khởi đầu) với
#    THIENLONG_TRACE_FILES, gom các tệp dữ liệu mà client thật sự mở thành bao
#    đóng của gói điện thoại: Table/mobile.files.tsv (kind, path).
#  - package_apk.py đóng đúng bao đóng này vào APK và bundle iOS; thiếu tệp
#    trong danh sách là lỗi đóng gói, không bỏ qua lặng lẽ.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# Cách dùng: python -B TOOLS/run/trace_assets.py [--exe build/msvc-release/thienlong_client.exe]
#            [--data dev/client/assets] [--frames 600]
# Bao đóng chỉ đủ cho những gì kịch bản đi qua (mỗi bảng giao diện mở bằng chuột sẽ lộ ra nếu kịch bản chạm tới nó). Tệp
# thiếu trên thiết bị hiện ở logcat dưới dạng lỗi "không mở được"; thêm kịch bản ở đây, hoặc thư mục mang nguyên ở
# WHOLE_FOLDERS của android/package_apk.py (Table, Config, Script, effect, Web: quét lúc đóng gói, không ghi vào đây).
# Chạy client thật: cửa sổ thu nhỏ không giành focus, không đụng chuột hay bàn phím của người đang dùng máy.

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

# Chỉ những phần này của dữ liệu đi vào gói; vết có cả tệp sinh lúc chạy và tệp của người chơi.
SKIPPED_PREFIXES = ("Save/", "cache/pipeline-", "dev/")
# cache/mesh/*.tlms là mesh đã nấu; client thấy cache mà không thấy .mesh thì dùng cache (resource/ogre_mesh.cpp).
KEPT_CACHE_PREFIX = "cache/mesh/"

CREATE_NO_ACTIVATE = 7  # SW_SHOWMINNOACTIVE


def scenarios(data: Path, frames: int) -> list[tuple[str, list[str]]]:
    startup = (data / "Config" / "startup.id").read_text(encoding="utf-8").strip()
    if not startup.isdigit():
        raise SystemExit(f"trace: Config/startup.id không phải resid ({startup})")
    return [
        ("đăng nhập", ["--login", "--frames", str(frames)]),
        ("màn chơi", ["--scene-id", startup, "--frames", str(frames)]),
    ]


def minimized_startup() -> subprocess.STARTUPINFO | None:
    if os.name != "nt":
        return None
    info = subprocess.STARTUPINFO()
    info.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    info.wShowWindow = CREATE_NO_ACTIVATE
    return info


def run_one(exe: Path, data: Path, name: str, arguments: list[str], trace: Path) -> None:
    environment = dict(os.environ, THIENLONG_TRACE_FILES=str(trace))
    command = [str(exe), "--data", str(data), *arguments]
    print(f"trace: {name}: {' '.join(command)}")
    result = subprocess.run(
        command, env=environment, startupinfo=minimized_startup(), check=False, capture_output=True, timeout=300
    )
    if result.returncode != 0:
        sys.stderr.buffer.write(result.stderr[-2000:])
        raise SystemExit(f"trace: kịch bản {name} thoát với mã {result.returncode}")


def relative_to_data(line: str, data: Path) -> str | None:
    path = Path(line)
    if not path.is_absolute():
        path = Path.cwd() / path
    try:
        relative = path.resolve().relative_to(data.resolve())
    except ValueError:
        return None
    return relative.as_posix()


def kept(relative: str) -> bool:
    if relative.startswith(KEPT_CACHE_PREFIX):
        return True
    return not relative.startswith("cache/") and not relative.startswith(SKIPPED_PREFIXES)


def traced_paths(trace: Path, data: Path) -> set[str]:
    found: set[str] = set()
    for line in trace.read_text(encoding="utf-8").splitlines():
        relative = relative_to_data(line, data)
        if relative is None or not kept(relative):
            continue
        if (data / relative).is_file():
            found.add(relative)
    return found


def write_list(out: Path, paths: set[str]) -> None:
    rows = ["kind\tpath"]
    for relative in sorted(paths):
        kind = relative.split("/", 1)[0].lower()
        rows.append(f"{kind}\t{relative}")
    out.write_text("\n".join(rows) + "\n", encoding="utf-8", newline="\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--exe", default="build/msvc-release/thienlong_client.exe")
    parser.add_argument("--data", default="dev/client/assets")
    parser.add_argument("--frames", type=int, default=600)
    parser.add_argument("--out", default="")
    args = parser.parse_args()
    exe = Path(args.exe)
    data = Path(args.data)
    if not exe.is_file():
        raise SystemExit(f"trace: không thấy {exe}")
    out = Path(args.out) if args.out else data / "Table" / "mobile.files.tsv"
    paths: set[str] = set()
    with tempfile.TemporaryDirectory() as scratch:
        for name, arguments in scenarios(data, args.frames):
            trace = Path(scratch) / "trace.txt"
            trace.unlink(missing_ok=True)
            run_one(exe, data, name, arguments, trace)
            if not trace.is_file():
                raise SystemExit(f"trace: kịch bản {name} không ghi vết (client thiếu core/trace?)")
            found = traced_paths(trace, data)
            print(f"trace: {name}: {len(found)} tệp")
            paths |= found
    write_list(out, paths)
    print(f"trace: ghi {len(paths)} tệp vào {out}")


if __name__ == "__main__":
    main()
