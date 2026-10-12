"""Đo khởi động của thienlong_client từ BÊN NGOÀI tiến trình, trên Windows: thứ người dùng thấy.

    python -B startup_probe.py <exe> [--backend vulkan|gles] [--runs 10] [--console none|new]
                               [--frames 500] [--out <tệp.tsv>] [--keep <thư mục log>] [--trace]
                               [-- <đối số thêm cho client>]

Mỗi lượt: tạo tiến trình, hỏi hệ điều hành cho tới khi cửa sổ của nó hiện, đưa cửa sổ lên trên
cùng (không lấy focus), rồi chụp liên tục ba hàng điểm ảnh của vùng chơi từ màn hình. Mốc, tính
bằng mili giây từ ngay trước lời gọi CreateProcess:

    window   cửa sổ hiện (IsWindowVisible)
    frame    khung đầu tiên có cảnh lên màn hình: hai hàng giữa có từ 64 màu trở lên và lệch ảnh
             ổn định dưới 30 mức mỗi kênh (lệch trung bình tuyệt đối)
    hud      hàng cắt qua thanh menu chính lệch ảnh ổn định dưới 2 mức: giao diện đã hiện
    settled  từ mẫu này trở đi hai hàng giữa lệch ảnh ổn định dưới 3 mức: mesh đã vào hết, kính
             đã đứng yên, hình không còn đổi

Ảnh ổn định là mẫu ở 3,5 giây sau khi cửa sổ hiện. Kèm theo, đọc tại mốc frame: MiB và số lần đọc
đĩa, thời gian CPU của tiến trình; đỉnh bộ nhớ; chu kỳ lấy mẫu; mã thoát. Ba dòng cuối là trung vị,
nhỏ nhất, lớn nhất. --trace ghi thêm một tệp vết từng mẫu cạnh log của mỗi lượt.

Chỉ đúng với vùng chơi 1280x720 (mặc định) và khi màn hình không khoá. Không cần thư viện ngoài.
Máy phải rảnh: một bản build hay một lượt đo khác đang chạy làm số vô nghĩa. Mã thoát 1 khi có
lượt hỏng.
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import pathlib
import statistics
import subprocess
import sys
import time

user32 = ctypes.WinDLL("user32", use_last_error=True)
gdi32 = ctypes.WinDLL("gdi32", use_last_error=True)
kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
psapi = ctypes.WinDLL("psapi", use_last_error=True)

HANDLE = ctypes.c_void_p
WNDENUMPROC = ctypes.WINFUNCTYPE(wt.BOOL, HANDLE, wt.LPARAM)

CLIENT_WIDTH = 1280
CLIENT_HEIGHT = 720
# (cột đầu, cột cuối, hàng) trong vùng chơi 1280x720. Hai hàng đầu chỉ cắt qua cảnh, tránh bảng số
# nhịp khung, khung chat và minimap; hàng thứ ba cắt qua thanh menu chính ở đáy.
SCENE_ROWS = ((300, 1000, 190), (330, 1280, 400))
HUD_ROW = (250, 1030, 690)
ROWS = (*SCENE_ROWS, HUD_ROW)
SCENE_INDEXES = tuple(range(len(SCENE_ROWS)))
HUD_INDEX = len(SCENE_ROWS)
DISTINCT_FOR_SCENE = 64
FRAME_GAP = 30.0
HUD_GAP = 2.0
SETTLED_GAP = 3.0
STEADY_AFTER_MS = 3500.0
WATCH_MS = 4000.0
CREATE_NEW_CONSOLE = 0x00000010
CREATE_NO_WINDOW = 0x08000000
TAB = chr(9)
LINE = chr(10)
TRACE_HEAD = TAB.join(("ms", "distinct", "scene_gap", "hud_gap", "read_mb", "read_ops", "cpu_ms"))
COLUMNS = ("window", "frame", "hud", "settled", "read_mb", "read_ops", "cpu_ms", "peak_mb", "sample_ms", "exit")


class BitmapHeader(ctypes.Structure):
    _fields_ = [
        ("size", wt.DWORD),
        ("width", wt.LONG),
        ("height", wt.LONG),
        ("planes", wt.WORD),
        ("bits", wt.WORD),
        ("compression", wt.DWORD),
        ("image_size", wt.DWORD),
        ("x_per_meter", wt.LONG),
        ("y_per_meter", wt.LONG),
        ("used", wt.DWORD),
        ("important", wt.DWORD),
    ]


class IoCounters(ctypes.Structure):
    _fields_ = [(name, ctypes.c_ulonglong) for name in (
        "read_ops", "write_ops", "other_ops", "read_bytes", "write_bytes", "other_bytes")]


class MemoryCounters(ctypes.Structure):
    _fields_ = [
        ("size", wt.DWORD),
        ("faults", wt.DWORD),
        ("peak_working_set", ctypes.c_size_t),
        ("working_set", ctypes.c_size_t),
        ("peak_paged", ctypes.c_size_t),
        ("paged", ctypes.c_size_t),
        ("peak_nonpaged", ctypes.c_size_t),
        ("nonpaged", ctypes.c_size_t),
        ("pagefile", ctypes.c_size_t),
        ("peak_pagefile", ctypes.c_size_t),
    ]


def declare():
    user32.EnumWindows.argtypes = [WNDENUMPROC, wt.LPARAM]
    user32.GetWindowThreadProcessId.argtypes = [HANDLE, ctypes.POINTER(wt.DWORD)]
    user32.IsWindowVisible.argtypes = [HANDLE]
    user32.GetClientRect.argtypes = [HANDLE, ctypes.POINTER(wt.RECT)]
    user32.ClientToScreen.argtypes = [HANDLE, ctypes.POINTER(wt.POINT)]
    user32.SetWindowPos.argtypes = [HANDLE, HANDLE, *([ctypes.c_int] * 4), wt.UINT]
    user32.GetDC.argtypes = [HANDLE]
    user32.GetDC.restype = HANDLE
    user32.SetProcessDpiAwarenessContext.argtypes = [HANDLE]
    gdi32.CreateCompatibleDC.argtypes = [HANDLE]
    gdi32.CreateCompatibleDC.restype = HANDLE
    gdi32.CreateDIBSection.argtypes = [
        HANDLE, ctypes.POINTER(BitmapHeader), wt.UINT, ctypes.POINTER(ctypes.c_void_p), HANDLE, wt.DWORD]
    gdi32.CreateDIBSection.restype = HANDLE
    gdi32.SelectObject.argtypes = [HANDLE, HANDLE]
    gdi32.SelectObject.restype = HANDLE
    gdi32.BitBlt.argtypes = [HANDLE, *([ctypes.c_int] * 4), HANDLE, ctypes.c_int, ctypes.c_int, wt.DWORD]
    kernel32.GetProcessIoCounters.argtypes = [HANDLE, ctypes.POINTER(IoCounters)]
    kernel32.GetProcessTimes.argtypes = [HANDLE, *([ctypes.POINTER(wt.FILETIME)] * 4)]
    psapi.GetProcessMemoryInfo.argtypes = [HANDLE, ctypes.POINTER(MemoryCounters), wt.DWORD]


class Grabber:
    """Chụp một dải của vùng chơi từ màn hình vào DIB 32 bit rồi rút ra các hàng của ROWS.

    Mỗi BitBlt từ màn hình chờ một nhịp ghép hình của DWM (16,7 ms ở 60 Hz), nên cả dải đi trong
    một lời gọi: chu kỳ lấy mẫu là một nhịp quét, và đó là độ phân giải của mọi mốc sau cửa sổ.
    """

    def __init__(self):
        self.top = min(row for _, _, row in ROWS)
        self.height = max(row for _, _, row in ROWS) - self.top + 1
        self.screen = user32.GetDC(None)
        self.memory = gdi32.CreateCompatibleDC(self.screen)
        header = BitmapHeader(ctypes.sizeof(BitmapHeader), CLIENT_WIDTH, -self.height, 1, 32, 0, 0, 0, 0, 0, 0)
        self.bits = ctypes.c_void_p()
        bitmap = gdi32.CreateDIBSection(self.screen, ctypes.byref(header), 0, ctypes.byref(self.bits), None, 0)
        if not bitmap or not self.bits:
            sys.exit("không tạo được DIB để chụp màn hình")
        gdi32.SelectObject(self.memory, bitmap)

    def grab(self, origin):
        gdi32.BitBlt(self.memory, 0, 0, CLIENT_WIDTH, self.height, self.screen,
                     origin.x, origin.y + self.top, 0x00CC0020)
        gdi32.GdiFlush()
        stride = CLIENT_WIDTH * 4
        rows = (ctypes.string_at(self.bits.value + (row - self.top) * stride, stride) for _, _, row in ROWS)
        return b"".join(rows)


def window_of(pid):
    found = []

    @WNDENUMPROC
    def visit(handle, _):
        owner = wt.DWORD()
        user32.GetWindowThreadProcessId(handle, ctypes.byref(owner))
        if owner.value != pid or not user32.IsWindowVisible(handle):
            return True
        found.append(handle)
        return False

    user32.EnumWindows(visit, 0)
    return found[0] if found else None


def row_bytes(sample, index):
    first, last, _ = ROWS[index]
    start = (index * CLIENT_WIDTH + first) * 4
    return sample[start:start + (last - first) * 4]


def distinct_colours(sample):
    seen = set()
    for index in SCENE_INDEXES:
        row = row_bytes(sample, index)
        seen.update(row[at:at + 3] for at in range(0, len(row), 4))
    return len(seen)


def row_gap(sample, steady, index):
    """Lệch trung bình tuyệt đối mỗi kênh màu giữa một hàng của mẫu và của ảnh ổn định."""
    ours = row_bytes(sample, index)
    theirs = row_bytes(steady, index)
    total = 0
    for at in range(0, len(ours), 4):
        total += abs(ours[at] - theirs[at]) + abs(ours[at + 1] - theirs[at + 1]) + abs(ours[at + 2] - theirs[at + 2])
    return total / (len(ours) // 4 * 3)


def scene_gap(sample, steady):
    return max(row_gap(sample, steady, index) for index in SCENE_INDEXES)


def process_numbers(handle):
    counters = IoCounters()
    kernel32.GetProcessIoCounters(handle, ctypes.byref(counters))
    made, gone, kernel, user = wt.FILETIME(), wt.FILETIME(), wt.FILETIME(), wt.FILETIME()
    kernel32.GetProcessTimes(handle, *(ctypes.byref(each) for each in (made, gone, kernel, user)))
    ticks = sum((each.dwHighDateTime << 32) | each.dwLowDateTime for each in (kernel, user))
    return counters.read_bytes / 1048576.0, counters.read_ops, ticks / 10000.0


def peak_memory(handle):
    counters = MemoryCounters()
    counters.size = ctypes.sizeof(MemoryCounters)
    psapi.GetProcessMemoryInfo(handle, ctypes.byref(counters), counters.size)
    return counters.peak_working_set


def watch(arguments, log_path, console):
    """Chạy client một lượt. Trả (mốc cửa sổ, cỡ vùng chơi, các mẫu, đỉnh bộ nhớ, mã thoát)."""
    grabber = Grabber()
    flags = CREATE_NEW_CONSOLE if console == "new" else CREATE_NO_WINDOW
    with open(log_path, "wb") as log:
        began = time.perf_counter_ns()
        child = subprocess.Popen(arguments, stdout=log, stderr=subprocess.STDOUT, creationflags=flags)
        handle = int(child._handle)

        def now_ms():
            return (time.perf_counter_ns() - began) / 1e6

        window = None
        while window is None and child.poll() is None:
            window = window_of(child.pid)
        shown_ms = now_ms()
        if window is None:
            return None, None, [], 0, child.returncode
        # Không chờ: luồng cửa sổ của client chưa đọc thông điệp cho tới khi phần hiển thị dựng xong,
        # lời gọi đồng bộ sẽ đứng ở đây đúng quãng đang cần đo.
        user32.SetWindowPos(window, HANDLE(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0010 | 0x4000)
        area = wt.RECT()
        user32.GetClientRect(window, ctypes.byref(area))
        origin = wt.POINT(0, 0)
        user32.ClientToScreen(window, ctypes.byref(origin))
        samples = []
        peak = 0
        while child.poll() is None and now_ms() - shown_ms < WATCH_MS:
            sample = grabber.grab(origin)
            samples.append((now_ms(), sample, process_numbers(handle)))
            peak = max(peak, peak_memory(handle))
        code = child.wait(timeout=60)
    size = (area.right - area.left, area.bottom - area.top)
    return shown_ms, size, samples, peak, code


def settled_time(notes):
    """Mốc của mẫu đầu tiên mà từ đó tới ảnh ổn định hình không còn lệch quá SETTLED_GAP."""
    settled = None
    for moment, _, gap, _, _ in notes:
        if gap >= SETTLED_GAP:
            settled = None
        elif settled is None:
            settled = moment
    return settled


def measure(arguments, log_path, console, trace_path=None):
    shown_ms, size, samples, peak, code = watch(arguments, log_path, console)
    if shown_ms is None:
        return {"error": f"tiến trình thoát mã {code} trước khi có cửa sổ"}
    if size != (CLIENT_WIDTH, CLIENT_HEIGHT):
        return {"error": f"vùng chơi {size[0]}x{size[1]}, bộ đo chỉ đúng với 1280x720"}
    steady = next((each[1] for each in samples if each[0] - shown_ms >= STEADY_AFTER_MS), None)
    if steady is None:
        return {"error": f"tiến trình thoát (mã {code}) trước mốc ảnh ổn định {STEADY_AFTER_MS:.0f} ms"}
    if distinct_colours(steady) < DISTINCT_FOR_SCENE:
        return {"error": "ảnh ổn định không có cảnh: màn hình khoá, cửa sổ bị che, hoặc client không vẽ"}
    notes = []
    for moment, sample, numbers in samples:
        if moment - shown_ms > STEADY_AFTER_MS:
            break
        gaps = (scene_gap(sample, steady), row_gap(sample, steady, HUD_INDEX))
        notes.append((moment, distinct_colours(sample), gaps[0], gaps[1], numbers))
    if trace_path:
        lines = [TRACE_HEAD]
        for moment, distinct, gap, hud_gap, numbers in notes:
            cells = (f"{moment:.1f}", str(distinct), f"{gap:.2f}", f"{hud_gap:.2f}",
                     f"{numbers[0]:.1f}", str(numbers[1]), f"{numbers[2]:.0f}")
            lines.append(TAB.join(cells))
        pathlib.Path(trace_path).write_text(LINE.join(lines) + LINE, encoding="utf-8")
    framed = next((note for note in notes if note[1] >= DISTINCT_FOR_SCENE and note[2] < FRAME_GAP), None)
    if framed is None:
        return {"error": "không mẫu nào có cảnh trước mốc ảnh ổn định"}
    hud = next((note[0] for note in notes if note[3] < HUD_GAP), None)
    periods = [later[0] - earlier[0] for earlier, later in zip(samples, samples[1:])]
    return {
        "window": shown_ms, "frame": framed[0], "hud": hud, "settled": settled_time(notes),
        "read_mb": framed[4][0], "read_ops": float(framed[4][1]), "cpu_ms": framed[4][2],
        "peak_mb": peak / 1048576.0, "sample_ms": statistics.median(periods), "exit": float(code),
    }


def text_of(value):
    return "-" if value is None else f"{value:.1f}"


def summary_line(title, pick, rows):
    cells = []
    for name in COLUMNS:
        values = [row[name] for row in rows if row[name] is not None]
        cells.append(text_of(pick(values)) if values else "-")
    return title + TAB + TAB.join(cells)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Đo khởi động của thienlong_client từ bên ngoài")
    parser.add_argument("exe")
    parser.add_argument("--backend")
    parser.add_argument("--runs", type=int, default=10)
    parser.add_argument("--console", choices=("none", "new"), default="none")
    parser.add_argument("--frames", type=int, default=500)
    parser.add_argument("--out")
    parser.add_argument("--keep", default=".")
    parser.add_argument("--trace", action="store_true")
    parser.add_argument("extra", nargs="*")
    chosen = parser.parse_args()
    declare()
    user32.SetProcessDpiAwarenessContext(HANDLE(-4))
    exe = pathlib.Path(chosen.exe).resolve()
    if not exe.is_file():
        sys.exit(f"không có exe: {exe}")
    arguments = [str(exe), "--frames", str(chosen.frames), *chosen.extra]
    if chosen.backend:
        arguments += ["--backend", chosen.backend]
    keep = pathlib.Path(chosen.keep)
    keep.mkdir(parents=True, exist_ok=True)
    lines = ["run" + TAB + TAB.join(COLUMNS)]
    print(lines[0], flush=True)
    rows = []
    failures = 0
    for run in range(1, chosen.runs + 1):
        stem = f"probe-{chosen.backend or 'auto'}-{run:02d}"
        trace = keep / f"{stem}.trace.tsv" if chosen.trace else None
        got = measure(arguments, keep / f"{stem}.log", chosen.console, trace)
        if "error" in got:
            failures += 1
            lines.append(f"{run}{TAB}LỖI: {got['error']}")
        else:
            rows.append(got)
            lines.append(str(run) + TAB + TAB.join(text_of(got[name]) for name in COLUMNS))
        print(lines[-1], flush=True)
        time.sleep(0.5)
    if rows:
        for title, pick in (("median", statistics.median), ("min", min), ("max", max)):
            lines.append(summary_line(title, pick, rows))
            print(lines[-1])
    if chosen.out:
        pathlib.Path(chosen.out).write_text(LINE.join(lines) + LINE, encoding="utf-8")
    return 1 if failures or not rows else 0


if __name__ == "__main__":
    sys.exit(main())
