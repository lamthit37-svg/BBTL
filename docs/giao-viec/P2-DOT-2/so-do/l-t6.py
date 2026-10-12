"""T14 (hai lệnh NDK trên SRC/net/socket_posix.cpp) và T6 (check.py đủ bộ trên mọi tệp C++ mới của
đợt, kể cả tệp sinh, tests/fuzz/, tests/bench/) của L. Giữ NANG.lock vì T6 có tidy trên hơn 5 tệp.
Log mới l-t14.log, l-t6.log; tệp đã có thì dừng."""
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

ROOT = Path.cwd()
SO_DO = ROOT / "docs/giao-viec/P2-DOT-2/so-do"
LOCK = ROOT / "build/NANG.lock"
TSV = ROOT / "build/lich-nang.tsv"
NDK = Path(os.environ["LOCALAPPDATA"]) / "Android/Sdk/ndk/30.0.16248370/toolchains/llvm/prebuilt/windows-x86_64/bin"
CHECK = Path(os.environ["USERPROFILE"]) / ".claude/cpp23/tools/check.py"


def stamp() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def save(name: str, lines: list[str]) -> None:
    path = SO_DO / name
    if path.exists():
        raise SystemExit(f"đã có {name}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"đã ghi so-do/{name}", flush=True)


def run(args: list[str], shown: str) -> list[str]:
    start = stamp()
    done = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace", cwd=ROOT,
                          check=False)
    return [f"# {start} -> {stamp()}", f"$ {shown}", (done.stdout + done.stderr).rstrip(), f"mã thoát: {done.returncode}", ""]


def new_cpp() -> list[str]:
    done = subprocess.run(["git", "-c", "safe.directory=*", "status", "--short", "--untracked-files=all"],
                          capture_output=True, text=True, cwd=ROOT, check=True)
    names = [line[3:].strip() for line in done.stdout.splitlines()]
    return [name for name in names if name.endswith((".cpp", ".hpp")) and name.startswith(("SRC/", "tests/"))]


def t14() -> None:
    lines = [f"# {stamp()}  T14: hai lệnh NDK của mục 2 trên SRC/net/socket_posix.cpp (NDK {NDK})", ""]
    for abi in ("aarch64", "x86_64"):
        tool = NDK / f"{abi}-linux-android29-clang++.cmd"
        args = ["cmd", "/c", str(tool), "-std=c++23", "-fsyntax-only", "-Wall", "-Wextra", "-Werror", "-I", "SRC",
                "SRC/net/socket_posix.cpp"]
        lines += run(args, f'"%LOCALAPPDATA%\\...\\{tool.name}" -std=c++23 -fsyntax-only -Wall -Wextra -Werror -I SRC SRC/net/socket_posix.cpp')
    save("l-t14.log", lines)


def t6() -> None:
    files = new_cpp()
    head = [f"# {stamp()}  T6: check.py đủ bộ (clang-format, độ lồng, g14, c20, clang-tidy) trên {len(files)} tệp;"
            " giữ NANG.lock, không có bản dựng nào khác đang chạy", ""]
    save("l-t6.log", head + run([sys.executable, "-B", str(CHECK), *files],
                                "python -B ~/.claude/cpp23/tools/check.py " + " ".join(files)))


def main() -> int:
    while LOCK.exists():
        time.sleep(20)
    start = stamp()
    LOCK.write_text(f"L T6 check.py đủ bộ trên mọi tệp C++ mới, kèm T14 {start}", encoding="utf-8")
    try:
        t14()
        t6()
    finally:
        with TSV.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(f"{start}\t{stamp()}\tL\tT6 check.py đủ bộ trên mọi tệp C++ mới, kèm T14 (so-do/l-t6.py)\n")
        LOCK.unlink()
    return 0


if __name__ == "__main__":
    sys.exit(main())