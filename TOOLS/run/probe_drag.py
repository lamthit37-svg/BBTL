# Đo hành vi cửa sổ của thienlong_client dưới thao tác thật: (1) độ trễ phản hồi của luồng UI qua
# SendMessageTimeout(WM_NULL), (2) CPU tiến trình giữa hai lần lấy, (3) kéo cửa sổ bằng SendInput
# đúng như người dùng (nhấn thanh tiêu đề, dời, nhả) rồi đọc vị trí khung trước/sau. Dùng để chuẩn
# đoán "cửa sổ không kéo được, hình giật". Chạy ở gốc dự án (chỉ Windows, cần desktop tương tác):
#   python TOOLS/run/probe_drag.py <exe> [đối số của exe...]
import ctypes
import ctypes.wintypes as wintypes
import pathlib
import subprocess
import sys
import tempfile
import threading
import time

PROJECT = pathlib.Path(__file__).resolve().parent.parent.parent
WINDOW_CLASS = "ThienLongWindow"
WM_NULL = 0x0000
WM_CLOSE = 0x0010
SM_CXSCREEN = 0
SM_CYSCREEN = 1
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_ABSOLUTE = 0x8000
INPUT_MOUSE = 0

user32 = ctypes.WinDLL("user32", use_last_error=True)
kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
EnumProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

class MOUSEINPUT(ctypes.Structure):
    _fields_ = [("dx", wintypes.LONG), ("dy", wintypes.LONG),
                ("mouseData", wintypes.DWORD), ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD), ("dwExtraInfo", ctypes.POINTER(wintypes.ULONG))]

class KEYBDINPUT(ctypes.Structure):
    _fields_ = [("wVk", wintypes.WORD), ("wScan", wintypes.WORD), ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD), ("dwExtraInfo", ctypes.POINTER(wintypes.ULONG))]

class INPUT(ctypes.Structure):
    class _U(ctypes.Union):
        _fields_ = [("mi", MOUSEINPUT), ("ki", KEYBDINPUT)]
    _anonymous_ = ["u"]
    _fields_ = [("type", wintypes.DWORD), ("u", _U)]

user32.EnumWindows.argtypes = [EnumProc, wintypes.LPARAM]
user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
user32.GetClassNameW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
user32.SendMessageTimeoutW.argtypes = [wintypes.HWND, wintypes.UINT, wintypes.WPARAM,
                                       wintypes.LPARAM, wintypes.UINT, wintypes.UINT,
                                       ctypes.POINTER(ctypes.c_size_t)]
user32.SendInput.argtypes = [wintypes.UINT, ctypes.POINTER(INPUT), ctypes.c_int]
user32.SetCursorPos.argtypes = [ctypes.c_int, ctypes.c_int]
user32.SetForegroundWindow.argtypes = [wintypes.HWND]
user32.GetCursorPos.argtypes = [ctypes.POINTER(wintypes.POINT)]
user32.GetSystemMetrics.argtypes = [ctypes.c_int]
user32.PostMessageW.argtypes = [wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM]
user32.GetForegroundWindow.argtypes = []
user32.GetForegroundWindow.restype = wintypes.HWND
user32.GetWindowThreadProcessId.restype = wintypes.DWORD
user32.AttachThreadInput.argtypes = [wintypes.DWORD, wintypes.DWORD, wintypes.BOOL]
user32.AttachThreadInput.restype = wintypes.BOOL
kernel32.GetCurrentThreadId.argtypes = []
kernel32.GetCurrentThreadId.restype = wintypes.DWORD
kernel32.GetProcessTimes.argtypes = [wintypes.HANDLE, ctypes.POINTER(wintypes.FILETIME),
                                     ctypes.POINTER(wintypes.FILETIME),
                                     ctypes.POINTER(wintypes.FILETIME),
                                     ctypes.POINTER(wintypes.FILETIME)]


def release_alt() -> None:
    """Nhả ALT: Windows cấp cho tiến trình vừa nhận input quyền gọi SetForegroundWindow."""
    event = INPUT()
    event.type = 1  # INPUT_KEYBOARD
    event.ki.wVk = 0x12  # VK_MENU
    event.ki.dwFlags = 0x0002  # KEYEVENTF_KEYUP
    user32.SendInput(1, ctypes.byref(event), ctypes.sizeof(INPUT))


def force_foreground(window: int) -> bool:
    """Đưa cửa sổ lên trước đúng thật: nhả ALT để được cấp quyền, AttachThreadInput rồi
    SetForegroundWindow, chờ tới khi GetForegroundWindow trỏ đúng nó. SetForegroundWindow từ
    tiến trình nền hay thất bại im lặng, và click khi chưa foreground chỉ kích hoạt cửa sổ thay vì
    bắt đầu kéo."""
    release_alt()
    owner = wintypes.DWORD(0)
    user32.GetWindowThreadProcessId(window, ctypes.byref(owner))
    target_thread = owner.value
    mine = kernel32.GetCurrentThreadId()
    attached = user32.AttachThreadInput(mine, target_thread, True)
    try:
        deadline = time.monotonic() + 2.0
        while time.monotonic() < deadline:
            user32.SetForegroundWindow(window)
            if user32.GetForegroundWindow() == window:
                return True
            time.sleep(0.1)
        return user32.GetForegroundWindow() == window
    finally:
        if attached:
            user32.AttachThreadInput(mine, target_thread, False)


def text_of(reader, window: int) -> str:
    buffer = ctypes.create_unicode_buffer(256)
    reader(window, buffer, len(buffer))
    return buffer.value


def windows_of(process_id: int) -> list[int]:
    found: list[int] = []

    def visit(window: int, _: int) -> bool:
        owner = wintypes.DWORD(0)
        user32.GetWindowThreadProcessId(window, ctypes.byref(owner))
        if owner.value == process_id and text_of(user32.GetClassNameW, window) == WINDOW_CLASS:
            found.append(window)
        return True

    user32.EnumWindows(EnumProc(visit), 0)
    return found


def wait_for_window(process: subprocess.Popen, seconds: float) -> int | None:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline and process.poll() is None:
        found = windows_of(process.pid)
        if found:
            return found[0]
        time.sleep(0.1)
    return None


def frame_rect(window: int) -> tuple[int, int]:
    rect = wintypes.RECT()
    user32.GetWindowRect(window, ctypes.byref(rect))
    return rect.left, rect.top


def ping_ms(window: int, timeout_ms: int = 2000) -> float:
    """Độ trễ một lượt SendMessageTimeout(WM_NULL), ms."""
    start = time.perf_counter()
    result = ctypes.c_size_t(0)
    user32.SendMessageTimeoutW(window, WM_NULL, 0, 0, 0x0008, timeout_ms,
                               ctypes.byref(result))
    return (time.perf_counter() - start) * 1000.0


def cpu_seconds(handle) -> float:
    empty = wintypes.FILETIME()
    creation, exit_, kernel, user = (wintypes.FILETIME(), wintypes.FILETIME(),
                                     wintypes.FILETIME(), wintypes.FILETIME())
    kernel32.GetProcessTimes(handle, ctypes.byref(creation), ctypes.byref(exit_),
                             ctypes.byref(kernel), ctypes.byref(user))
    def seconds(ft: wintypes.FILETIME) -> float:
        value = (ft.dwHighDateTime << 32) | ft.dwLowDateTime
        return value / 10_000_000.0
    return seconds(kernel) + seconds(user)


def move_mouse(x: int, y: int) -> None:
    screen_w = user32.GetSystemMetrics(SM_CXSCREEN)
    screen_h = user32.GetSystemMetrics(SM_CYSCREEN)
    event = INPUT()
    event.type = INPUT_MOUSE
    event.mi.dx = int(x * 65535 / (screen_w - 1))
    event.mi.dy = int(y * 65535 / (screen_h - 1))
    event.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE
    user32.SendInput(1, ctypes.byref(event), ctypes.sizeof(INPUT))


def click(button_flag: int) -> None:
    event = INPUT()
    event.type = INPUT_MOUSE
    event.mi.dwFlags = button_flag
    user32.SendInput(1, ctypes.byref(event), ctypes.sizeof(INPUT))


def drag_title_bar(window: int, dx: int, dy: int, steps: int = 20, step_s: float = 0.010) -> None:
    """Kéo thanh tiêu đề theo đúng đường đi của Windows: mở vòng kéo bằng WM_NCLBUTTONDOWN gửi
    thẳng tới cửa sổ (vòng kéo modal của DefWindowProc bắt đầu tuyệt đối, không phụ thuộc cửa sổ
    nào đang đứng trước), dời chuột bằng SendInput — lúc vòng kéo đang chạy, chuột bị giữ nên
    thông điệp đi thẳng tới cửa sổ này — rồi đóng vòng bằng WM_LBUTTONUP. Cách đỉnh 10 px: trong
    thanh tiêu đề ở mọi DPI (thanh thấp nhất ~23 px ở 100%)."""
    rect = wintypes.RECT()
    user32.GetWindowRect(window, ctypes.byref(rect))
    start_x = (rect.left + rect.right) // 2
    start_y = rect.top + 10
    user32.SetCursorPos(start_x, start_y)
    time.sleep(0.2)
    print(f"chuột đặt tại {start_x},{start_y} (khung {rect.left},{rect.top} tới "
          f"{rect.right},{rect.bottom})")
    WM_NCLBUTTONDOWN = 0x00A1
    WM_LBUTTONUP = 0x0202
    HTCAPTION = 2
    pressed = (start_y << 16) | (start_x & 0xFFFF)
    user32.PostMessageW(window, WM_NCLBUTTONDOWN, HTCAPTION, pressed)
    time.sleep(0.3)
    for index in range(1, steps + 1):
        move_mouse(start_x + (dx * index // steps), start_y + (dy * index // steps))
        time.sleep(step_s)
    time.sleep(0.2)
    user32.PostMessageW(window, WM_LBUTTONUP, 0, pressed)
    time.sleep(0.2)


def main() -> int:
    if len(sys.argv) < 2:
        print("probe_drag.py <exe> [đối số của exe...]")
        return 2
    (PROJECT / "build").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=PROJECT / "build") as work:
        out_path = pathlib.Path(work) / "stdout.txt"
        err_path = pathlib.Path(work) / "stderr.txt"
        command = [str(pathlib.Path(sys.argv[1]).resolve()), *sys.argv[2:]]
        with out_path.open("wb") as out, err_path.open("wb") as err:
            process = subprocess.Popen(command, stdout=out, stderr=err,
                                       creationflags=subprocess.CREATE_NO_WINDOW)
            window = wait_for_window(process, 20.0)
            if window is None:
                process.kill()
                print("KHÔNG thấy cửa sổ sau 20 giây")
                return 100
            time.sleep(1.0)
            is_front = force_foreground(window)
            print(f"cửa sổ lên trước được: {is_front}")
            time.sleep(0.5)

            # (1) độ trễ phản hồi của luồng UI lúc đứng yên
            idle = [ping_ms(window) for _ in range(10)]
            idle_sorted = sorted(idle)
            print(f"ping WM_NULL lúc đứng yên: trung vị {idle_sorted[5]:.1f} ms, "
                  f"max {idle_sorted[-1]:.1f} ms")

            # (2) CPU tiến trình trong 2 giây đứng yên
            before = cpu_seconds(process._handle)
            time.sleep(2.0)
            used = cpu_seconds(process._handle) - before
            print(f"CPU dùng trong 2 giây đứng yên: {used:.2f} s "
                  f"({used / 2.0 * 100:.0f}% một lõi)")

            # (3) kéo thật: đo độ trễ khung-so-với-chuột và ping trong lúc kéo, rồi vị trí sau.
            before_rect = frame_rect(window)
            pings_during: list[float] = []
            lag_during: list[int] = []
            done = threading.Event()

            def drag_and_mark() -> None:
                drag_title_bar(window, 160, 90)
                done.set()

            def grab_delta() -> tuple[int, int] | None:
                """Vector từ góc khung tới chuột lúc này; None khi đọc hỏng."""
                rect = wintypes.RECT()
                if user32.GetWindowRect(window, ctypes.byref(rect)) == 0:
                    return None
                point = wintypes.POINT()
                if user32.GetCursorPos(ctypes.byref(point)) == 0:
                    return None
                return point.x - rect.left, point.y - rect.top

            mover = threading.Thread(target=drag_and_mark)
            mover.start()
            baseline = grab_delta()
            while not done.is_set():
                pings_during.append(ping_ms(window, 3000))
                delta = grab_delta()
                if baseline is not None and delta is not None:
                    lag_during.append(max(abs(delta[0] - baseline[0]),
                                          abs(delta[1] - baseline[1])))
            mover.join()
            after_rect = frame_rect(window)
            moved = (after_rect[0] - before_rect[0], after_rect[1] - before_rect[1])
            pings_sorted = sorted(pings_during)
            middle = pings_sorted[len(pings_sorted) // 2] if pings_sorted else -1.0
            print(f"kéo thanh tiêu đề (+160,+90): khung dời được {moved[0]:+d},{moved[1]:+d} px")
            print(f"ping WM_NULL trong lúc kéo ({len(pings_during)} mẫu): "
                  f"trung vị {middle:.1f} ms, max {pings_sorted[-1] if pings_sorted else -1:.1f} ms")
            if lag_during:
                lag_sorted = sorted(lag_during)
                print(f"độ trễ khung theo chuột khi kéo ({len(lag_during)} mẫu): "
                      f"trung vị {lag_sorted[len(lag_sorted) // 2]} px, "
                      f"max {lag_sorted[-1]} px")

            # (4) CPU trong 2 giây sau kéo
            before = cpu_seconds(process._handle)
            time.sleep(2.0)
            used = cpu_seconds(process._handle) - before
            print(f"CPU dùng trong 2 giây sau kéo: {used:.2f} s "
                  f"({used / 2.0 * 100:.0f}% một lõi)")

            user32.PostMessageW(window, WM_CLOSE, 0, 0)
            try:
                code = process.wait(timeout=20.0)
            except subprocess.TimeoutExpired:
                process.kill()
                print("tiến trình KHÔNG thoát trong 20 giây sau WM_CLOSE")
                return 101
        print(f"mã thoát của exe: {code}")
        print("--- ba dòng cuối stdout ---")
        lines = out_path.read_text(encoding="utf-8", errors="replace").splitlines()
        print("\n".join(lines[-3:]))
        print(f"--- stderr: {err_path.stat().st_size} byte ---")
        print("\n".join(err_path.read_text(encoding="utf-8", errors="replace").splitlines()[-10:]))
        return code


if __name__ == "__main__":
    sys.exit(main())
