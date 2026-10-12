# Chạy một lệnh đúng một lượt và ghi mọi thứ thay đổi trên desktop của người đang dùng máy trong
# lúc lệnh chạy. Dùng TRƯỚC khi nói một test hay công cụ "không đụng màn hình": con trỏ chuột là
# của cả phiên đăng nhập, nên một tiến trình nằm trên desktop hay window station khác vẫn đổi được
# hình con trỏ, vùng giam con trỏ và vị trí con trỏ (đo ngày 2026-10-08 với các ca vòng kéo của
# window_modal_tests).
# Ghi năm thứ: vùng giam con trỏ (GetClipCursor) đổi; con trỏ nhảy hơn 80 px giữa hai lần soi; cửa
# sổ đang ở trước đổi; cửa sổ nhìn thấy mới xuất hiện; hình con trỏ hoặc cờ hiện/ẩn đổi
# (GetCursorInfo). Bốn thứ đầu là tín hiệu đáng tin. Hình con trỏ thì chính người dùng cũng làm đổi
# khi rê chuột: lấy mẫu nền bằng một lệnh chỉ ngủ rồi so số lần đổi.
# Chạy ở gốc dự án (chỉ Windows):
#   python TOOLS/run/desk_watch.py <lệnh> [đối số]...
#   python TOOLS/run/desk_watch.py python -c "import time; time.sleep(10)"
# Mã thoát: mã thoát của lệnh. Không chạy lặp công cụ này quanh một test đụng con trỏ: mỗi lượt là
# một lần con trỏ của người dùng nháy.
import ctypes
import ctypes.wintypes as wintypes
import subprocess
import sys
import time

# Hai lần soi liền nhau cách quá số này thì coi là con trỏ bị dời chứ không phải được rê.
JUMP_PIXELS = 80
# Soi thêm chừng này giây sau khi lệnh thoát, để thấy desktop có được trả lại như cũ không.
TAIL_SECONDS = 0.3
# Số lần soi giữa hai lượt liệt kê cửa sổ (liệt kê tốn hơn các phép soi khác).
WINDOW_SCAN_EVERY = 16
EVENT_LIMIT = 120
# Nhãn của từng loại sự kiện trong dòng tổng kết, theo thứ tự in.
KINDS = ("vùng giam", "nhảy vị trí", "cửa sổ ở trước", "cửa sổ mới hiện", "hình con trỏ")

user32 = ctypes.WinDLL("user32", use_last_error=True)
ENUM_PROC = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)


class CursorInfo(ctypes.Structure):
    _fields_ = [("size", wintypes.DWORD), ("flags", wintypes.DWORD),
                ("cursor", wintypes.HANDLE), ("spot", wintypes.POINT)]


def declare() -> None:
    user32.GetForegroundWindow.restype = wintypes.HWND
    user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
    user32.IsWindowVisible.argtypes = [wintypes.HWND]
    user32.EnumWindows.argtypes = [ENUM_PROC, wintypes.LPARAM]
    user32.GetCursorInfo.argtypes = [ctypes.POINTER(CursorInfo)]
    user32.GetClipCursor.argtypes = [ctypes.POINTER(wintypes.RECT)]


def title_of(window) -> str:
    text = ctypes.create_unicode_buffer(80)
    user32.GetWindowTextW(window, text, len(text))
    return text.value


def pointer_now() -> tuple[int, int, tuple[int, int, int, int], tuple[int, int]]:
    """Hình con trỏ, cờ hiện/ẩn, vùng giam và vị trí lúc này."""
    info = CursorInfo()
    info.size = ctypes.sizeof(CursorInfo)
    user32.GetCursorInfo(ctypes.byref(info))
    clip = wintypes.RECT()
    user32.GetClipCursor(ctypes.byref(clip))
    area = (clip.left, clip.top, clip.right, clip.bottom)
    return info.cursor or 0, info.flags, area, (info.spot.x, info.spot.y)


def visible_windows() -> set[int]:
    found: set[int] = set()

    def visit(window, _) -> bool:
        if user32.IsWindowVisible(window):
            found.add(int(window))
        return True

    user32.EnumWindows(ENUM_PROC(visit), 0)
    return found


class Watch:
    """Trạng thái lần soi trước và các sự kiện đã thấy."""

    def __init__(self) -> None:
        self.shape, self.flags, self.clip, self.spot = pointer_now()
        self.front = user32.GetForegroundWindow()
        self.windows = visible_windows()
        self.events: list[tuple[str, float, str]] = []

    def note(self, kind: str, stamp: float, text: str) -> None:
        self.events.append((kind, stamp, text))

    def look(self, stamp: float, scans_windows: bool) -> None:
        shape, flags, clip, spot = pointer_now()
        if clip != self.clip:
            self.note("vùng giam", stamp, f"{self.clip} -> {clip}")
        if abs(spot[0] - self.spot[0]) + abs(spot[1] - self.spot[1]) > JUMP_PIXELS:
            self.note("nhảy vị trí", stamp, f"{self.spot} -> {spot}")
        if (shape, flags) != (self.shape, self.flags):
            was = f"{self.shape:#x} cờ {self.flags}"
            self.note("hình con trỏ", stamp, f"{was} -> {shape:#x} cờ {flags}")
        self.shape, self.flags, self.clip, self.spot = shape, flags, clip, spot
        front = user32.GetForegroundWindow()
        if front != self.front:
            self.note("cửa sổ ở trước", stamp, f"sang '{title_of(front)}'")
            self.front = front
        if scans_windows:
            self.scan_windows(stamp)

    def scan_windows(self, stamp: float) -> None:
        now = visible_windows()
        for window in sorted(now - self.windows):
            self.note("cửa sổ mới hiện", stamp, f"'{title_of(window)}'")
        self.windows |= now


def report(watch: Watch, polls: int, code: int) -> None:
    counts = ", ".join(f"{kind} {sum(1 for event in watch.events if event[0] == kind)}"
                       for kind in KINDS)
    print(f"mã thoát {code & 0xFFFFFFFF:#x}; {polls} lần soi; {counts}")
    for kind, stamp, text in watch.events[:EVENT_LIMIT]:
        print(f"{stamp:9.1f} ms {kind}: {text}")
    rest = len(watch.events) - EVENT_LIMIT
    if rest > 0:
        print(f"... còn {rest} sự kiện")


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    command = sys.argv[1:]
    if not command:
        print("cách dùng: python TOOLS/run/desk_watch.py <lệnh> [đối số]...")
        return 2
    declare()
    watch = Watch()
    print(f"lúc đầu: hình {watch.shape:#x}, cờ {watch.flags}, vùng giam {watch.clip}, "
          f"vị trí {watch.spot}, ở trước '{title_of(watch.front)}'")
    start = time.perf_counter()
    child = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
    polls = 0
    ended = None
    while ended is None or time.perf_counter() - ended < TAIL_SECONDS:
        if ended is None and child.poll() is not None:
            ended = time.perf_counter()
        polls += 1
        stamp = (time.perf_counter() - start) * 1000.0
        watch.look(stamp, polls % WINDOW_SCAN_EVERY == 0)
    report(watch, polls, child.returncode)
    return child.returncode


if __name__ == "__main__":
    sys.exit(main())
