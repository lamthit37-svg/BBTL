"""Đo lại Đ2 và Đ3 của L với tiến trình ghim vào 12 luồng logic 0..11 (6 nhân P của i5-14600KF).

Lý do: ba vòng l-d2-d3-vong1..3.log không ghim nhân, MiB/giây chia hai cụm (khoảng 760 tới 1.900
và 3.200 tới 5.200), lớn/nhỏ 6,7; 3,7; 1,8. Nghi lịch của Windows đặt luồng lên nhân E. Tiến
trình con thừa hưởng affinity của python. Dùng lại bench_round của l-do.py; log mới
l-d2-d3-p-vong<N>.log, không ghi đè log nào.
"""
from __future__ import annotations

import importlib.util
import sys
from types import ModuleType

import psutil

P_THREADS = list(range(12))


def load_l() -> ModuleType:
    """Nạp so-do/l-do.py làm module."""
    here = __file__.rsplit("/", 1)[0].rsplit("\\", 1)[0]
    spec = importlib.util.spec_from_file_location("l_do", f"{here}/l-do.py")
    if spec is None or spec.loader is None:
        raise SystemExit("không nạp được l-do.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    """Ghim nhân, lấy khoá, chạy tối đa 3 vòng Đ2 cùng Đ3."""
    psutil.Process().cpu_affinity(P_THREADS)
    module = load_l()
    plain_head = module.head
    note = f"; affinity luồng logic {P_THREADS[0]}..{P_THREADS[-1]} (nhân P), kiểm: {psutil.Process().cpu_affinity()}"
    module.head = lambda label, command: plain_head(label, command + note)
    start = module.take_lock()
    columns, gated = module.D2_COLUMNS, {"p50 µs": 0, "p99 µs": 1, "MiB/giây": 3}
    try:
        module.repeat(lambda n: module.bench_round("D2-D3-P", "net_bench.exe", columns, gated, n))
    finally:
        with module.TSV.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(f"{start}\t{module.stamp()}\tL\tđo lại Đ2, Đ3 ghim nhân P (so-do/l-do-ghim.py)\n")
        module.LOCK.unlink()
    return 0


if __name__ == "__main__":
    sys.exit(main())