# Chạy thienlong_client như một người dùng rồi báo kết quả: chờ cửa sổ hiện, đọc màu điểm ảnh giữa
# vùng vẽ từ màn hình, đổi cỡ nó hai lần, thu nhỏ rồi khôi phục, gửi yêu cầu đóng (WM_CLOSE), chờ
# tiến trình thoát và in mã thoát cùng phần cuối stdout, stderr. Dùng để kiểm bước "cửa sổ đổi cỡ
# không lỗi, đóng sạch" mà không cần người bấm. Màu đọc từ màn hình chỉ đúng khi cửa sổ không bị
# cửa sổ khác che ở điểm giữa.
# Chạy ở gốc dự án (chỉ Windows):
#   python TOOLS/run/drive_window.py <exe> [đối số của exe...]
# Mã thoát của công cụ: mã thoát của exe; 100 khi không thấy cửa sổ; 101 khi exe không tự thoát.
import ctypes
import ctypes.wintypes as wintypes
import pathlib
import subprocess
import sys
import tempfile
import time

PROJECT = pathlib.Path(__file__).resolve().parent.parent.parent
WINDOW_CLASS = "ThienLongWindow"
WM_CLOSE = 0x0010
SW_MINIMIZE = 6
SW_RESTORE = 9
# SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
SIZE_ONLY = 0x0002 | 0x0004 | 0x0010
FRAME_SIZES = ((900, 600), (1000, 700))
PAUSE = 0.4

user32 = ctypes.WinDLL("user32", use_last_error=True)
EnumProc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
user32.EnumWindows.argtypes = [EnumProc, wintypes.LPARAM]
user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
user32.GetClassNameW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetClientRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
user32.SetWindowPos.argtypes = [wintypes.HWND, wintypes.HWND, ctypes.c_int, ctypes.c_int,
                                ctypes.c_int, ctypes.c_int, wintypes.UINT]
user32.ShowWindow.argtypes = [wintypes.HWND, ctypes.c_int]
user32.PostMessageW.argtypes = [wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM]
user32.IsWindow.argtypes = [wintypes.HWND]
user32.ClientToScreen.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.POINT)]
user32.GetDC.argtypes = [wintypes.HWND]
user32.GetDC.restype = wintypes.HDC
user32.ReleaseDC.argtypes = [wintypes.HWND, wintypes.HDC]
user32.SetForegroundWindow.argtypes = [wintypes.HWND]
gdi32 = ctypes.WinDLL("gdi32", use_last_error=True)
gdi32.GetPixel.argtypes = [wintypes.HDC, ctypes.c_int, ctypes.c_int]
gdi32.GetPixel.restype = wintypes.COLORREF


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


def client_size(window: int) -> str:
    rect = wintypes.RECT()
    user32.GetClientRect(window, ctypes.byref(rect))
    return f"{rect.right}x{rect.bottom}"


# Màu (đỏ, lục, lam) của điểm ảnh giữa vùng vẽ, đọc từ màn hình.
def center_color(window: int) -> tuple[int, int, int]:
    rect = wintypes.RECT()
    user32.GetClientRect(window, ctypes.byref(rect))
    point = wintypes.POINT(rect.right // 2, rect.bottom // 2)
    user32.ClientToScreen(window, ctypes.byref(point))
    screen = user32.GetDC(None)
    color = gdi32.GetPixel(screen, point.x, point.y)
    user32.ReleaseDC(None, screen)
    return color & 0xFF, (color >> 8) & 0xFF, (color >> 16) & 0xFF


def drive(window: int) -> None:
    print(f"cửa sổ hiện: tiêu đề '{text_of(user32.GetWindowTextW, window)}'")
    print(f"vùng vẽ lúc mở: {client_size(window)}")
    user32.SetForegroundWindow(window)
    time.sleep(PAUSE)
    print(f"màu điểm ảnh giữa vùng vẽ (đỏ, lục, lam): {center_color(window)}")
    for width, height in FRAME_SIZES:
        user32.SetWindowPos(window, None, 0, 0, width, height, SIZE_ONLY)
        time.sleep(PAUSE)
        print(f"đổi cỡ khung thành {width}x{height}: vùng vẽ {client_size(window)}")
    user32.ShowWindow(window, SW_MINIMIZE)
    time.sleep(PAUSE)
    print(f"thu nhỏ: vùng vẽ {client_size(window)}")
    user32.ShowWindow(window, SW_RESTORE)
    time.sleep(PAUSE)
    print(f"khôi phục: vùng vẽ {client_size(window)}")
    # Đọc lại sau khi khôi phục: lúc này cửa sổ vừa được đưa lên trên và đã vẽ nhiều khung.
    user32.SetForegroundWindow(window)
    time.sleep(PAUSE)
    print(f"màu điểm ảnh giữa vùng vẽ sau khi khôi phục: {center_color(window)}")
    sent = user32.PostMessageW(window, WM_CLOSE, 0, 0)
    print(f"đã gửi yêu cầu đóng: {bool(sent)}")


def tail(path: pathlib.Path, count: int) -> list[str]:
    return path.read_text(encoding="utf-8", errors="replace").splitlines()[-count:]


def main() -> int:
    if len(sys.argv) < 2:
        print("drive_window.py <exe> [đối số của exe...]")
        return 2
    (PROJECT / "build").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=PROJECT / "build") as work:
        out_path = pathlib.Path(work) / "stdout.txt"
        err_path = pathlib.Path(work) / "stderr.txt"
        # CreateProcess không tìm ra exe khi đường dẫn tương đối viết bằng dấu "/": đổi sang tuyệt đối.
        command = [str(pathlib.Path(sys.argv[1]).resolve()), *sys.argv[2:]]
        with out_path.open("wb") as out, err_path.open("wb") as err:
            process = subprocess.Popen(command, stdout=out, stderr=err,
                                       creationflags=subprocess.CREATE_NO_WINDOW)
            window = wait_for_window(process, 15.0)
            if window is None:
                process.kill()
                print("KHÔNG thấy cửa sổ sau 15 giây")
                return 100
            drive(window)
            try:
                code = process.wait(timeout=15.0)
            except subprocess.TimeoutExpired:
                process.kill()
                print("tiến trình KHÔNG thoát trong 15 giây sau khi đóng cửa sổ")
                return 101
        print(f"cửa sổ còn tồn tại sau khi thoát: {bool(user32.IsWindow(window))}")
        print(f"mã thoát của exe: {code}")
        print("--- ba dòng cuối stdout ---")
        print("\n".join(tail(out_path, 3)))
        print(f"--- stderr: {err_path.stat().st_size} byte ---")
        print("\n".join(tail(err_path, 10)))
        return code


if __name__ == "__main__":
    sys.exit(main())
