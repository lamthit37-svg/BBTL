"""Đo lại Đ1 tới Đ4 của L khi chắc không có tiến trình nào khác của dự án chạy cùng.

Lý do: ctest net_tests lặp 20 lần của R (build/p2-r, 09:45:11 tới 09:46:01, không cần khoá vì là
lệnh nhẹ) chạy chồng lên l-d1-vong1, l-d2-d3-vong1..3 và l-d4-vong1. Script này dùng lại l-do.py,
thêm một luồng lấy mẫu tiến trình mỗi 0,1 giây trong mỗi vòng: tiến trình nào chạy từ worktree
mà không phải con của script, hay là trình dựng (ninja, cl, clang, lld-link, link, cmake, ctest),
đều ghi vào log và làm vòng đó không đạt. Log mới l-<phép>-sach-vong<N>.log, không ghi đè.
"""
from __future__ import annotations

import importlib.util
import os
import sys
import threading
from types import ModuleType

import psutil

TOOLS = {"ninja.exe", "cl.exe", "clang.exe", "clang++.exe", "clang-cl.exe", "lld-link.exe", "link.exe",
         "cmake.exe", "ctest.exe", "gcc.exe", "g++.exe", "cc1plus.exe"}
MARK = "p2-dot-2"


def load_l() -> ModuleType:
    """Nạp so-do/l-do.py làm module."""
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location("l_do", os.path.join(here, "l-do.py"))
    if spec is None or spec.loader is None:
        raise SystemExit("không nạp được l-do.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def others() -> set[str]:
    """Tiến trình lạ lúc này: chạy từ worktree hoặc là trình dựng, trừ chính script và con của nó."""
    mine = os.getpid()
    found = set()
    for proc in psutil.process_iter(["pid", "ppid", "name", "exe"]):
        info = proc.info
        if info["pid"] == mine or info["ppid"] == mine:
            continue
        exe = (info["exe"] or "").replace("\\", "/")
        # GCC.exe ở Program Files/GIGABYTE là GIGABYTE Control Center, không phải trình dịch
        tool = "/GIGABYTE/" not in exe and (info["name"] or "").lower() in TOOLS
        if tool or MARK in exe:
            found.add(f"{info['name']} (pid {info['pid']})")
    return found


class Watch:
    """Luồng lấy mẫu tiến trình mỗi 0,1 giây cho tới khi stop()."""

    def __init__(self) -> None:
        self.seen: set[str] = set()
        self.halt = threading.Event()
        self.thread = threading.Thread(target=self.loop, daemon=True)

    def loop(self) -> None:
        """Lấy mẫu tới khi được dừng."""
        while not self.halt.is_set():
            self.seen |= others()
            self.halt.wait(0.1)

    def stop(self) -> set[str]:
        """Dừng luồng, trả tập tiến trình lạ đã thấy."""
        self.halt.set()
        self.thread.join()
        return self.seen


def watched(module: ModuleType, task, *args) -> bool:
    """Chạy một vòng dưới Watch; thấy tiến trình lạ thì vòng không đạt."""
    watch = Watch()
    plain_save = module.save
    watch.thread.start()
    verdict: list[bool] = []

    def save(name: str, lines: list[str]) -> None:
        seen = watch.stop()
        text = "không có" if not seen else ", ".join(sorted(seen)) + " (vòng không đạt)"
        verdict.append(not seen)
        note = f"tiến trình khác của dự án hay trình dựng trong vòng (psutil, mỗi 0,1 giây): {text}"
        plain_save(name.replace("-vong", "-sach-vong"), [*lines[:3], note, "", *lines[3:]])

    module.save = save
    good = task(*args)
    module.save = plain_save
    return good and all(verdict)


def main() -> int:
    """Đ1, Đ2 cùng Đ3, rồi Đ4, dưới một khoá, mỗi vòng có kiểm tiến trình."""
    module = load_l()
    start = module.take_lock()
    d1 = {"mã hoá/giây": 3, "giải mã/giây": 6}
    d2 = {"p50 µs": 0, "p99 µs": 1, "MiB/giây": 3}
    try:
        module.repeat(lambda n: watched(module, module.bench_round, "D1", "protocol_bench.exe",
                                        module.D1_COLUMNS, d1, n))
        module.repeat(lambda n: watched(module, module.bench_round, "D2-D3", "net_bench.exe",
                                        module.D2_COLUMNS, d2, n))
        module.repeat(lambda n: watched(module, module.d4_round, n))
    finally:
        with module.TSV.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(f"{start}\t{module.stamp()}\tL\tđo lại Đ1 tới Đ4, có kiểm tiến trình (so-do/l-do-sach.py)\n")
        module.LOCK.unlink()
    return 0


if __name__ == "__main__":
    sys.exit(main())