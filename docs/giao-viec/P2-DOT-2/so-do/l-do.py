"""Phép đo Đ1 tới Đ4 của L, P2 đợt 2, trên msvc-release; mỗi phép 5 lượt, giữ NANG.lock.

Lượt lớn nhất quá 1,5 lần lượt nhỏ nhất ở đại lượng có ngưỡng lệch thì đo lại cả phép (tối đa 3
vòng); mỗi vòng có log riêng l-<phép>-vong<N>.log, không ghi đè log nào. Đ4 dùng run, GEN và
one_render của c-do.py, đo lại như d4() nhưng ghi log của L (không ghi đè c-d4-gen.log).
"""
from __future__ import annotations

import importlib.util
import statistics
import subprocess
import sys
import time
import tracemalloc
from collections.abc import Callable
from datetime import datetime
from pathlib import Path
from types import ModuleType

ROOT = Path("F:/tl 2026/THIENLONG/build/p2-dot-2")
SO_DO = ROOT / "docs/giao-viec/P2-DOT-2/so-do"
LOCK = ROOT / "build/NANG.lock"
TSV = ROOT / "build/lich-nang.tsv"
TREE = ROOT / "build/msvc-release"
RUNS = 5
ROUNDS = 3
SPREAD = 1.5
D1_COLUMNS = ["mau", "tin_ma_hoa", "giay_ma_hoa", "ma_hoa_moi_giay", "tin_giai_ma", "giay_giai_ma",
              "giai_ma_moi_giay", "loi"]
D2_COLUMNS = ["p50_us", "p99_us", "max_us", "mib_moi_giay", "ket_qua"]


def stamp() -> str:
    """Giờ máy, đến giây."""
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def head(label: str, command: str) -> list[str]:
    """Hai dòng đầu bắt buộc của log đo."""
    return [f"# {stamp()}  {label}: không có bản dựng nào khác đang chạy (giữ NANG.lock)",
            f"> {command}", ""]


def save(name: str, lines: list[str]) -> None:
    """Ghi một log mới; tệp đã có thì dừng, không ghi đè."""
    path = SO_DO / name
    if path.exists():
        raise SystemExit(f"đã có {name}, không ghi đè")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"đã ghi so-do/{name}", flush=True)


def spread_line(name: str, values: list[float]) -> tuple[str, bool]:
    """Trung vị, nhỏ nhất, lớn nhất, tỉ số lớn/nhỏ; True khi tỉ số không quá SPREAD."""
    low, high = min(values), max(values)
    ratio = high / low if low > 0 else float("inf")
    good = ratio <= SPREAD
    verdict = "đạt" if good else "quá 1,5: đo lại"
    return (f"{name}: trung vị {statistics.median(values):.4f}, nhỏ nhất {low:.4f}, "
            f"lớn nhất {high:.4f}, lớn/nhỏ {ratio:.3f} ({verdict})"), good


def gate(lines: list[str], series: dict[str, list[float]]) -> bool:
    """Thêm dòng tóm tắt của từng đại lượng vào lines; True khi mọi đại lượng đạt."""
    good = True
    for name, values in series.items():
        text, fine = spread_line(name, values)
        lines.append(text)
        good = good and fine
    return good


def bench_rows(exe: Path) -> list[list[str]]:
    """Chạy exe RUNS lần, mỗi lần một dòng TSV kèm số lượt và mã thoát."""
    rows = []
    for index in range(RUNS):
        done = subprocess.run([str(exe)], capture_output=True, text=True, cwd=ROOT, check=False)
        rows.append([str(index + 1), *done.stdout.strip().split("\t"), str(done.returncode)])
    return rows


def bench_round(code: str, exe: str, columns: list[str], gated: dict[str, int], round_no: int) -> bool:
    """Một vòng 5 lượt của một exe đo; True khi mọi lượt thoát 0 và mọi đại lượng có ngưỡng đạt."""
    lines = head(f"{code} vòng {round_no}", f"build/msvc-release/{exe} (chạy {RUNS} lần)")
    rows = bench_rows(TREE / exe)
    lines += ["\t".join(["luot", *columns, "exit"]), *("\t".join(row) for row in rows), ""]
    exits_ok = all(row[-1] == "0" for row in rows) and all(len(row) == len(columns) + 2 for row in rows)
    if not exits_ok:
        lines.append("có lượt thoát khác 0 hoặc thiếu cột: không tính tóm tắt")
        save(f"l-{code.lower()}-vong{round_no}.log", lines)
        return False
    series = {name: [float(row[column + 1]) for row in rows] for name, column in gated.items()}
    good = gate(lines, series)
    save(f"l-{code.lower()}-vong{round_no}.log", lines)
    return good


def load_c() -> ModuleType:
    """Nạp so-do/c-do.py làm module (tên tệp có gạch ngang)."""
    spec = importlib.util.spec_from_file_location("c_do", SO_DO / "c-do.py")
    if spec is None or spec.loader is None:
        raise SystemExit("không nạp được c-do.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def d4_series(module: ModuleType) -> tuple[dict[str, list[float]], list[int]]:
    """A: cả tiến trình --check; B: render trong tiến trình; C: đỉnh tracemalloc (MiB)."""
    run, gen, render = module.run, module.GEN, module.one_render
    process, inner, peaks, codes = [], [], [], []
    for _ in range(RUNS):
        start = time.perf_counter()
        codes.append(run([str(gen), "--check"])[0])
        process.append(time.perf_counter() - start)
    for _ in range(RUNS):
        start = time.perf_counter()
        render()
        inner.append(time.perf_counter() - start)
    for _ in range(RUNS):
        tracemalloc.start()
        render()
        peaks.append(tracemalloc.get_traced_memory()[1] / 2**20)
        tracemalloc.stop()
    return {"A giây": process, "B giây": inner, "C MiB": peaks}, codes


def d4_round(round_no: int) -> bool:
    """Một vòng Đ4 bằng các hàm của c-do.py."""
    command = ("python -B TOOLS/server/gen_protocol.py --check (A); load_catalog + render_all trong "
               "tiến trình (B); đỉnh tracemalloc của B (C); mỗi phần 5 lượt")
    lines = head(f"Đ4 vòng {round_no}", command)
    series, codes = d4_series(load_c())
    lines.append("luot\t" + "\t".join(series))
    lines += [f"{index + 1}\t" + "\t".join(f"{values[index]:.4f}" for values in series.values())
              for index in range(RUNS)]
    lines += [f"mã thoát của A: {codes}", ""]
    good = gate(lines, series) and all(code == 0 for code in codes)
    save(f"l-d4-vong{round_no}.log", lines)
    return good


def repeat(task: Callable[[int], bool]) -> None:
    """Chạy tới khi một vòng đạt, tối đa ROUNDS vòng."""
    for round_no in range(1, ROUNDS + 1):
        if task(round_no):
            return


def take_lock() -> str:
    """Chờ khoá trống rồi lấy; trả giờ bắt đầu."""
    while LOCK.exists():
        time.sleep(20)
    start = stamp()
    LOCK.write_text(f"L đo Đ1 tới Đ4 trên msvc-release {start}", encoding="utf-8")
    return start


def main() -> int:
    """Đ1, Đ2 cùng Đ3, rồi Đ4, dưới một khoá."""
    start = take_lock()
    d1 = {"mã hoá/giây": 3, "giải mã/giây": 6}
    d2 = {"p50 µs": 0, "p99 µs": 1, "MiB/giây": 3}
    try:
        repeat(lambda n: bench_round("D1", "protocol_bench.exe", D1_COLUMNS, d1, n))
        repeat(lambda n: bench_round("D2-D3", "net_bench.exe", D2_COLUMNS, d2, n))
        repeat(d4_round)
    finally:
        with TSV.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(f"{start}\t{stamp()}\tL\tđo Đ1 tới Đ4 trên msvc-release (so-do/l-do.py)\n")
        LOCK.unlink()
    return 0


if __name__ == "__main__":
    sys.exit(main())