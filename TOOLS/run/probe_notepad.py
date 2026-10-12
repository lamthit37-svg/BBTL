# Đối chứng cho probe_drag: dùng đúng thủ thuật kéo (WM_NCLBUTTONDOWN gửi thẳng + SendInput dời +
# WM_LBUTTONUP đóng) lên một cửa sổ ngoài — Notepad — để tách "probe sai" khỏi "app của ta sai".
#   python TOOLS/run/probe_notepad.py
import ctypes
import ctypes.wintypes as wintypes
import subprocess
import time

WM_NCLBUTTONDOWN = 0x00A1
WM_LBUTTONUP = 0x0202
HTCAPTION = 2
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_ABSOLUTE = 0x8000
INPUT_MOUSE = 0
SM_CXSCREEN = 0
SM_CYSCREEN = 1

user32 = ctypes.WinDLL("user32", use_last_error=True)


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [("dx", wintypes.LONG), ("dy", wintypes.LONG),
                ("mouseData", wintypes.DWORD), ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD), ("dwExtraInfo", ctypes.POINTER(wintypes.ULONG))]


class INPUT(ctypes.Structure):
    class _U(ctypes.Union):
        _fields_ = [("mi", MOUSEINPUT)]
    _anonymous_ = ["u"]
    _fields_ = [("type", wintypes.DWORD), ("u", _U)]


user32.FindWindowW.argtypes = [wintypes.LPCWSTR, wintypes.LPCWSTR]
user32.FindWindowW.restype = wintypes.HWND
user32.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
user32.SetCursorPos.argtypes = [ctypes.c_int, ctypes.c_int]
user32.SendInput.argtypes = [wintypes.UINT, ctypes.POINTER(INPUT), ctypes.c_int]
user32.PostMessageW.argtypes = [wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM]
user32.GetSystemMetrics.argtypes = [ctypes.c_int]


def move_mouse(x: int, y: int) -> None:
    screen_w = user32.GetSystemMetrics(SM_CXSCREEN)
    screen_h = user32.GetSystemMetrics(SM_CYSCREEN)
    event = INPUT()
    event.type = INPUT_MOUSE
    event.mi.dx = int(x * 65535 / (screen_w - 1))
    event.mi.dy = int(y * 65535 / (screen_h - 1))
    event.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE
    user32.SendInput(1, ctypes.byref(event), ctypes.sizeof(INPUT))


def frame_rect(window) -> tuple[int, int]:
    rect = wintypes.RECT()
    user32.GetWindowRect(window, ctypes.byref(rect))
    return rect.left, rect.top


def main() -> int:
    subprocess.Popen(["notepad.exe"])
    time.sleep(1.5)
    window = user32.FindWindowW("Notepad", None)
    if not window:
        print("không thấy Notepad")
        return 100
    rect = wintypes.RECT()
    user32.GetWindowRect(window, ctypes.byref(rect))
    start_x = (rect.left + rect.right) // 2
    start_y = rect.top + 10
    before = frame_rect(window)
    user32.SetCursorPos(start_x, start_y)
    time.sleep(0.2)
    pressed = (start_y << 16) | (start_x & 0xFFFF)
    user32.PostMessageW(window, WM_NCLBUTTONDOWN, HTCAPTION, pressed)
    time.sleep(0.3)
    for index in range(1, 21):
        move_mouse(start_x + (160 * index // 20), start_y + (90 * index // 20))
        time.sleep(0.010)
    time.sleep(0.2)
    user32.PostMessageW(window, WM_LBUTTONUP, 0, pressed)
    time.sleep(0.3)
    after = frame_rect(window)
    moved = (after[0] - before[0], after[1] - before[1])
    print(f"Notepad kéo (+160,+90): dời được {moved[0]:+d},{moved[1]:+d} px")
    user32.PostMessageW(window, 0x0010, 0, 0)  # WM_CLOSE
    return 0


if __name__ == "__main__":
    sys_code = main()
    raise SystemExit(sys_code)
