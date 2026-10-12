"""T13 của P2 đợt 1 (Claude, 2026-10-07): chạy thienlong_lint trên cây thật, đo đỉnh bộ nhớ và so báo cáo.

    python -B docs/giao-viec/P2-DOT-1/kiem-claude/lint_peak.py <thienlong_lint.exe> [số lần chạy]

Đỉnh bộ nhớ là PeakWorkingSetSize do Windows tự ghi cho tiến trình, đọc sau khi nó thoát: không lấy
mẫu nên không sót đỉnh ngắn. Báo cáo so với TOOLS/server/table_ref_coverage.tsv sau khi bỏ dòng #.
Mã thoát 0 khi mọi lần chạy đều thoát 0, lỗi 0, báo cáo trùng và đỉnh không quá 120 MiB.
"""
import ctypes
import subprocess
import sys
import time
from ctypes import wintypes
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
ROOT = Path(__file__).resolve().parents[4]
REPORT = ROOT / "build" / "p2-claude-coverage.tsv"
REFERENCE = ROOT / "TOOLS" / "server" / "table_ref_coverage.tsv"
CEILING_MIB = 120.0


class Counters(ctypes.Structure):
    _fields_ = [("cb", wintypes.DWORD), ("PageFaultCount", wintypes.DWORD),
                ("PeakWorkingSetSize", ctypes.c_size_t), ("WorkingSetSize", ctypes.c_size_t),
                ("QuotaPeakPagedPoolUsage", ctypes.c_size_t), ("QuotaPagedPoolUsage", ctypes.c_size_t),
                ("QuotaPeakNonPagedPoolUsage", ctypes.c_size_t), ("QuotaNonPagedPoolUsage", ctypes.c_size_t),
                ("PagefileUsage", ctypes.c_size_t), ("PeakPagefileUsage", ctypes.c_size_t)]


def peaks_of(process: subprocess.Popen):
    """(đỉnh working set, đỉnh commit) tính bằng MiB của một tiến trình đã thoát."""
    counters = Counters()
    counters.cb = ctypes.sizeof(Counters)
    psapi = ctypes.WinDLL("psapi", use_last_error=True)
    handle = wintypes.HANDLE(int(process._handle))
    if not psapi.GetProcessMemoryInfo(handle, ctypes.byref(counters), counters.cb):
        raise ctypes.WinError(ctypes.get_last_error())
    return counters.PeakWorkingSetSize / 2**20, counters.PeakPagefileUsage / 2**20


def data_lines(path: Path):
    return [line for line in path.read_text(encoding="utf-8").splitlines() if not line.startswith("#")]


def run_once(exe: Path) -> bool:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.unlink(missing_ok=True)
    command = [str(exe), "--root", "SERVER", "--refs", "TOOLS/server/refs", "--report", str(REPORT)]
    started = time.perf_counter()
    process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = process.communicate()
    seconds = time.perf_counter() - started
    working, commit = peaks_of(process)
    text = out.decode("utf-8", "replace").strip()
    print(text)
    if err.strip():
        print("stderr:", err.decode("utf-8", "replace").strip()[:2000])
    same = REPORT.exists() and data_lines(REPORT) == data_lines(REFERENCE)
    clean = any(line.replace(" ", "") == "lỗi:0" for line in text.splitlines())
    print(f"    thoát {process.returncode}; {seconds:.2f} giây; đỉnh working set {working:.1f} MiB; "
          f"đỉnh commit {commit:.1f} MiB; báo cáo {'trùng' if same else 'KHÁC'} bảng tham chiếu "
          f"({len(data_lines(REPORT)) if REPORT.exists() else 0} dòng dữ liệu)")
    return process.returncode == 0 and clean and same and working <= CEILING_MIB


def main() -> int:
    exe = Path(sys.argv[1]).resolve()
    runs = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    results = [run_once(exe) for _ in range(runs)]
    REPORT.unlink(missing_ok=True)
    print("kết quả:", "đạt" if all(results) else "HỎNG")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
