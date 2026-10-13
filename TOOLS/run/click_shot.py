# Chạy thienlong_client, làm từng thao tác chuột được nêu trên vùng chơi, và sau mỗi bước chụp vùng
# chơi ra một tệp PNG. Dùng để nhìn giao diện và camera sau một chuỗi thao tác mà không cần người
# bấm: nút mở bảng, nút đóng, thẻ; kéo phải xoay camera, kéo nút giữa ngẩng cúi, lăn chuột zoom.
# Cửa sổ của client chụp bằng PrintWindow, thông điệp chuột gửi thẳng cho cửa sổ (PostMessage), nên
# ảnh không dính cửa sổ của chương trình khác. Cửa sổ nằm nguyên ở chỗ client mở nó: giữa màn hình
# chính (chủ dự án dặn 2026-10-13: không đẩy cửa sổ ra màn phụ hay ngoài màn hình).
# Đã đo ngày 2026-10-13 (log DBG ở sdl_input.cpp): ngay trước mỗi lần nhấn, SDL phát thêm hai sự kiện
# di chuyển lấy từ vị trí CON TRỎ THẬT chứ không từ thông điệp của công cụ này, nên lần nhấn rơi vào
# chỗ con trỏ thật đang đứng (cả khi cửa sổ bị khoá EnableWindow, cả khi cửa sổ nằm ngoài màn hình).
# Vì vậy công cụ đặt con trỏ thật lên đúng điểm sắp bấm (SetCursorPos) trước mỗi thông điệp và trả con
# trỏ về chỗ cũ khi xong; trong lúc chạy tay người dùng không nên chạm chuột.
# CẢNH BÁO: công cụ này đặt con trỏ thật và gửi nút chuột thật, tức cướp chuột của người đang dùng máy. Chủ dự án cấm agent chạy nó
# với bước chuột (2026-10-13); chỉ người dùng tự chạy khi muốn.
# Chạy ở gốc dự án (chỉ Windows):
#   python TOOLS/run/click_shot.py <exe> --out <thư mục> [--click X,Y | --drop X,Y |
#       --hold X,Y,MS | --turn X,Y,DX,DY | --tilt X,Y,DX,DY | --wheel X,Y,N | --type X,Y,CHỮ]...
#       [--settle giây] [--pause giây] [-- đối số của exe]
# --click bấm rồi nhả tại chỗ. --drop nhấn rồi gửi một thông điệp di chuyển không mang cờ nút và
# không nhả, như khi nút được nhả ngoài cửa sổ: client phải coi lần nhấn là đã huỷ, và lần bấm kế
# tiếp vẫn phải ăn. --turn nhấn phải ở X,Y, kéo đi DX,DY điểm ảnh rồi nhả; --tilt làm vậy với
# nút giữa. --hold giữ nút trái ở X,Y trong MS mili giây rồi nhả (nút xoay người mẫu, nút cuộn bản
# đồ). --wheel lăn N nấc ở X,Y, dương là lăn ra trước. Ba lệnh giữ và kéo dùng nút THẬT
# (mouse_event): SDL gặp thông điệp di chuyển thì hỏi GetAsyncKeyState, thấy nút không giữ là tự
# phát lệnh nhả (đo 2026-10-13: kéo bằng PostMessage bị nhả ngay sau lần di chuyển đầu). Trong
# lúc kéo cửa sổ được mở khoá và đưa lên trên cùng để nút thật rơi vào nó, xong thì trả lại. Các
# bước chạy theo thứ tự viết trên dòng lệnh.
# Ảnh: 00-start.png trước bước đầu, rồi NN-X-Y.png sau bước thứ NN. Mã thoát: mã thoát của exe; 100
# khi không thấy cửa sổ; 101 khi exe không tự thoát sau WM_CLOSE; 103 khi một lần chụp hỏng.
import argparse
import contextlib
import ctypes
import ctypes.wintypes as wintypes
import os
import pathlib
import struct
import subprocess
import sys
import time
import zlib

HANDLE = ctypes.c_void_p
WM_CLOSE = 0x0010
WM_KEYDOWN = 0x0100
WM_KEYUP = 0x0101
WM_CHAR = 0x0102
WM_MOUSEMOVE = 0x0200
WM_LBUTTONDOWN = 0x0201
WM_LBUTTONUP = 0x0202
WM_MOUSEWHEEL = 0x020A
MK_LBUTTON = 0x0001
WHEEL_DELTA = 120
# Số thông điệp di chuyển của một lần kéo, và giây nghỉ giữa hai thông điệp: dài hơn một khung của
# client để mỗi thông điệp rơi vào một khung riêng.
DRAG_MOVES = 8
DRAG_PAUSE_SECONDS = 0.04
# PW_CLIENTONLY | PW_RENDERFULLCONTENT: lấy cả nội dung do GPU vẽ, không cần cửa sổ lộ ra.
PRINT_CLIENT = 0x0001 | 0x0002
# Số lần chụp tối đa cho một ảnh và giây chờ giữa hai lần. Đã đo ngày 2026-10-08: PrintWindow đôi
# lúc báo thành công mà ảnh toàn đen, hoặc vùng chơi đọc ra cỡ 0x0, rồi lần chụp sau lại đúng.
SHOT_TRIES = 5
SHOT_RETRY_SECONDS = 0.2
CREATE_NO_WINDOW = 0x08000000
# SW_SHOWNOACTIVATE
SHOW_NO_ACTIVATE = 4
CLICK = "bấm"
DROP = "nhấn rồi bỏ"
HOLD = "giữ trái"
TURN = "kéo phải"
TILT = "kéo giữa"
WHEEL = "lăn"
TYPE = "gõ"
# Cách viết phím điều khiển trong CHỮ của --type, và mã phím ảo Win32 của chúng.
TYPED_KEYS = {"\\t": "\t", "\\r": "\r", "\\b": "\b", "\\e": "\x1b"}
CONTROL_KEYS = {"\t": 0x09, "\r": 0x0D, "\b": 0x08, "\x1b": 0x1B}
MAPVK_VK_TO_VSC = 0
SPI_GETWORKAREA = 0x0030
# Cờ mouse_event nhấn và nhả của hai kiểu kéo.
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_MIDDLEDOWN = 0x0020
MOUSEEVENTF_MIDDLEUP = 0x0040
DRAG_BUTTONS = {
    TURN: (MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP),
    TILT: (MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_MIDDLEUP),
}
# Đưa cửa sổ lên trên cùng / trả lại: SetWindowPos không đổi chỗ, cỡ, focus.
HWND_TOPMOST = -1
HWND_NOTOPMOST = -2
SWP_NOSIZE_NOMOVE_NOACTIVATE = 0x0001 | 0x0002 | 0x0010
# Một bước: loại thao tác, điểm của vùng chơi, và các số thêm (độ dời của kéo, số nấc của lăn, mã
# từng ký tự của gõ).
Step = tuple[str, int, int, tuple[int, ...]]

user32 = ctypes.WinDLL("user32", use_last_error=True)
gdi32 = ctypes.WinDLL("gdi32", use_last_error=True)
EnumProc = ctypes.WINFUNCTYPE(wintypes.BOOL, HANDLE, wintypes.LPARAM)


class BitmapHeader(ctypes.Structure):
    _fields_ = [
        ("size", wintypes.DWORD),
        ("width", wintypes.LONG),
        ("height", wintypes.LONG),
        ("planes", wintypes.WORD),
        ("bits", wintypes.WORD),
        ("compression", wintypes.DWORD),
        ("image_size", wintypes.DWORD),
        ("x_per_meter", wintypes.LONG),
        ("y_per_meter", wintypes.LONG),
        ("used", wintypes.DWORD),
        ("important", wintypes.DWORD),
    ]


def declare() -> None:
    rect_out = ctypes.POINTER(wintypes.RECT)
    user32.EnumWindows.argtypes = [EnumProc, wintypes.LPARAM]
    user32.GetWindowThreadProcessId.argtypes = [HANDLE, ctypes.POINTER(wintypes.DWORD)]
    user32.IsWindowVisible.argtypes = [HANDLE]
    user32.GetDC.argtypes = [HANDLE]
    user32.GetDC.restype = HANDLE
    user32.ReleaseDC.argtypes = [HANDLE, HANDLE]
    user32.SetProcessDpiAwarenessContext.argtypes = [HANDLE]
    user32.PrintWindow.argtypes = [HANDLE, HANDLE, wintypes.UINT]
    user32.GetClientRect.argtypes = [HANDLE, rect_out]
    user32.GetWindowRect.argtypes = [HANDLE, rect_out]
    user32.EnableWindow.argtypes = [HANDLE, wintypes.BOOL]
    user32.ClientToScreen.argtypes = [HANDLE, ctypes.POINTER(wintypes.POINT)]
    user32.GetCursorPos.argtypes = [ctypes.POINTER(wintypes.POINT)]
    user32.SetCursorPos.argtypes = [ctypes.c_int, ctypes.c_int]
    user32.mouse_event.argtypes = [wintypes.DWORD, wintypes.DWORD, wintypes.DWORD, wintypes.DWORD, ctypes.c_size_t]
    user32.SetWindowPos.argtypes = [
        HANDLE, HANDLE, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int, wintypes.UINT]
    gdi32.CreateCompatibleDC.argtypes = [HANDLE]
    gdi32.CreateCompatibleDC.restype = HANDLE
    bits_out = ctypes.POINTER(ctypes.c_void_p)
    gdi32.CreateDIBSection.argtypes = [
        HANDLE, ctypes.POINTER(BitmapHeader), wintypes.UINT, bits_out, HANDLE, wintypes.DWORD]
    gdi32.CreateDIBSection.restype = HANDLE
    gdi32.SelectObject.argtypes = [HANDLE, HANDLE]
    gdi32.SelectObject.restype = HANDLE
    gdi32.DeleteObject.argtypes = [HANDLE]
    gdi32.DeleteDC.argtypes = [HANDLE]


def window_of(process_id: int) -> int | None:
    found: list[int] = []

    @EnumProc
    def visit(window: int, _: int) -> bool:
        owner = wintypes.DWORD()
        user32.GetWindowThreadProcessId(window, ctypes.byref(owner))
        if owner.value != process_id or not user32.IsWindowVisible(window):
            return True
        found.append(window)
        return False

    user32.EnumWindows(visit, 0)
    return found[0] if found else None


def wait_for_window(process: subprocess.Popen, seconds: float) -> int | None:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline and process.poll() is None:
        window = window_of(process.pid)
        if window is not None:
            return window
        time.sleep(0.01)
    return None


def ignore_hardware_input(window: int) -> None:
    """Khoá cửa sổ khỏi chuột và bàn phím thật. Cửa sổ nằm giữa màn hình chính nên con trỏ của người
    đang dùng máy lướt qua nó: thông điệp di chuyển thật chen vào giữa lúc nhấn và lúc nhả, SDL dời
    điểm bấm theo và lần bấm giả trượt sang nút khác (đo 2026-10-13). Cửa sổ bị khoá (EnableWindow)
    không nhận thông điệp phần cứng, còn thông điệp PostMessage của công cụ này vẫn tới nơi."""
    user32.EnableWindow(window, False)


def aim(window: int, across: int, down: int) -> None:
    """Đặt con trỏ thật lên điểm (across, down) của vùng chơi: SDL lấy vị trí nhấn từ con trỏ thật."""
    spot = wintypes.POINT(across, down)
    user32.ClientToScreen(window, ctypes.byref(spot))
    user32.SetCursorPos(spot.x, spot.y)


def report_placement(window: int) -> None:
    """In khung cửa sổ và vùng làm việc của màn hình chính (SPI_GETWORKAREA) để so cách căn giữa."""
    frame = wintypes.RECT()
    work = wintypes.RECT()
    user32.GetWindowRect(window, ctypes.byref(frame))
    user32.SystemParametersInfoW(SPI_GETWORKAREA, 0, ctypes.byref(work), 0)
    print(f"khung cửa sổ {frame.left},{frame.top}-{frame.right},{frame.bottom}; "
          f"vùng làm việc {work.left},{work.top}-{work.right},{work.bottom}")


def png_of(width: int, height: int, pixels: bytes) -> bytes:
    """PNG RGB 8 bit từ vùng BGRA xếp theo hàng, hàng trên cùng trước."""
    stride = width * 4
    rows = bytearray()
    for row in range(height):
        line = pixels[row * stride:(row + 1) * stride]
        colours = bytearray(width * 3)
        colours[0::3] = line[2::4]
        colours[1::3] = line[1::4]
        colours[2::3] = line[0::4]
        rows.append(0)
        rows.extend(colours)

    def chunk(kind: bytes, body: bytes) -> bytes:
        checksum = zlib.crc32(kind + body) & 0xFFFFFFFF
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", checksum)

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    packed = zlib.compress(bytes(rows), 6)
    chunks = chunk(b"IHDR", header) + chunk(b"IDAT", packed) + chunk(b"IEND", b"")
    return b"\x89PNG\r\n\x1a\n" + chunks


def print_client(window: int, width: int, height: int) -> bytes | None:
    """Điểm ảnh BGRA của vùng chơi do PrintWindow vẽ ra; None khi nó từ chối."""
    screen = user32.GetDC(None)
    memory = gdi32.CreateCompatibleDC(screen)
    header = BitmapHeader(ctypes.sizeof(BitmapHeader), width, -height, 1, 32, 0, 0, 0, 0, 0, 0)
    bits = ctypes.c_void_p()
    bitmap = gdi32.CreateDIBSection(screen, ctypes.byref(header), 0, ctypes.byref(bits), None, 0)
    previous = gdi32.SelectObject(memory, bitmap)
    is_drawn = bool(user32.PrintWindow(window, memory, PRINT_CLIENT))
    gdi32.GdiFlush()
    pixels = ctypes.string_at(bits, width * height * 4) if is_drawn else None
    gdi32.SelectObject(memory, previous)
    gdi32.DeleteObject(bitmap)
    gdi32.DeleteDC(memory)
    user32.ReleaseDC(None, screen)
    return pixels


def is_blank(pixels: bytes) -> bool:
    """Ảnh BGRA không có điểm nào khác đen."""
    return not (any(pixels[0::4]) or any(pixels[1::4]) or any(pixels[2::4]))


def grab(window: int) -> tuple[int, int, bytes] | None:
    """Một lần chụp vùng chơi: cỡ và điểm ảnh BGRA; None khi cỡ rỗng, bị từ chối hay ảnh đen."""
    area = wintypes.RECT()
    user32.GetClientRect(window, ctypes.byref(area))
    width, height = area.right - area.left, area.bottom - area.top
    if width <= 0 or height <= 0:
        return None
    pixels = print_client(window, width, height)
    if pixels is None or is_blank(pixels):
        return None
    return width, height, pixels


def shoot(window: int, path: pathlib.Path) -> tuple[int, int] | None:
    """Chụp vùng chơi của cửa sổ ra path; trả cỡ ảnh, None khi mọi lần chụp đều hỏng."""
    for attempt in range(1, SHOT_TRIES + 1):
        shot = grab(window)
        if shot is None:
            time.sleep(SHOT_RETRY_SECONDS)
            continue
        width, height, pixels = shot
        path.write_bytes(png_of(width, height, pixels))
        if attempt > 1:
            print(f"{path.name}: tới lần chụp thứ {attempt} mới ra ảnh")
        return width, height
    state = "đang thu nhỏ" if user32.IsIconic(window) else "không thu nhỏ"
    print(f"không chụp được {path.name} sau {SHOT_TRIES} lần; cửa sổ {state}")
    return None


def place_of(across: int, down: int) -> int:
    return ((down & 0xFFFF) << 16) | (across & 0xFFFF)


def press(window: int, step: Step) -> None:
    kind, across, down, _ = step
    place = place_of(across, down)
    aim(window, across, down)
    user32.PostMessageW(window, WM_MOUSEMOVE, 0, place)
    time.sleep(0.05)
    user32.PostMessageW(window, WM_LBUTTONDOWN, MK_LBUTTON, place)
    time.sleep(0.08)
    ending = WM_MOUSEMOVE if kind == DROP else WM_LBUTTONUP
    user32.PostMessageW(window, ending, 0, place)


@contextlib.contextmanager
def real_input(window: int):
    """Cho nút chuột THẬT rơi vào cửa sổ: mở khoá và đưa lên trên cùng trong lúc dùng, xong thì trả lại."""
    user32.EnableWindow(window, True)
    user32.SetWindowPos(window, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE_NOMOVE_NOACTIVATE)
    try:
        yield
    finally:
        user32.SetWindowPos(window, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE_NOMOVE_NOACTIVATE)
        ignore_hardware_input(window)


def hold(window: int, step: Step) -> None:
    _, across, down, (millis,) = step
    with real_input(window):
        aim(window, across, down)
        time.sleep(DRAG_PAUSE_SECONDS)
        user32.mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
        time.sleep(millis / 1000)
        user32.mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
        time.sleep(DRAG_PAUSE_SECONDS)


def drag(window: int, step: Step) -> None:
    kind, across, down, (shift_x, shift_y) = step
    pressing, releasing = DRAG_BUTTONS[kind]
    with real_input(window):
        aim(window, across, down)
        time.sleep(DRAG_PAUSE_SECONDS)
        user32.mouse_event(pressing, 0, 0, 0, 0)
        time.sleep(DRAG_PAUSE_SECONDS)
        for move in range(1, DRAG_MOVES + 1):
            aim(window, across + shift_x * move // DRAG_MOVES, down + shift_y * move // DRAG_MOVES)
            time.sleep(DRAG_PAUSE_SECONDS)
        user32.mouse_event(releasing, 0, 0, 0, 0)
        time.sleep(DRAG_PAUSE_SECONDS)


def roll(window: int, step: Step) -> None:
    _, across, down, (notches,) = step
    turn = WHEEL_DELTA if notches > 0 else -WHEEL_DELTA
    aim(window, across, down)
    for _ in range(abs(notches)):
        user32.PostMessageW(window, WM_MOUSEWHEEL, (turn & 0xFFFF) << 16, place_of(across, down))
        time.sleep(DRAG_PAUSE_SECONDS)


def tap_key(window: int, virtual_key: int) -> None:
    """Nhấn rồi nhả một phím điều khiển; SDL suy ra phím vật lý từ mã quét trong lParam."""
    scan = user32.MapVirtualKeyW(virtual_key, MAPVK_VK_TO_VSC)
    down = 1 | (scan << 16)
    up = down | (1 << 30) | (1 << 31)
    user32.PostMessageW(window, WM_KEYDOWN, virtual_key, down)
    time.sleep(0.03)
    user32.PostMessageW(window, WM_KEYUP, virtual_key, up)


def type_in(window: int, step: Step) -> None:
    """Bấm vào ô ở X,Y để lấy focus rồi gõ từng ký tự; Tab, Enter, Backspace đi như phím."""
    _, across, down, codes = step
    press(window, (CLICK, across, down, ()))
    time.sleep(0.2)
    for code in codes:
        key = CONTROL_KEYS.get(chr(code))
        if key is None:
            user32.PostMessageW(window, WM_CHAR, code, 1)
        else:
            tap_key(window, key)
        time.sleep(0.04)


ACTIONS = {CLICK: press, DROP: press, HOLD: hold, TURN: drag, TILT: drag, WHEEL: roll, TYPE: type_in}


def numbers_of(text: str, count: int) -> list[int]:
    parts = text.split(",")
    try:
        numbers = [int(part) for part in parts]
    except ValueError:
        numbers = []
    if len(numbers) != count or numbers[0] < 0 or numbers[1] < 0:
        raise argparse.ArgumentTypeError(f"cần {count} số nguyên cách nhau bằng dấu phẩy: {text}")
    return numbers


def step_of(kind: str, extras: int = 0):
    def parse(text: str) -> Step:
        numbers = numbers_of(text, 2 + extras)
        return kind, numbers[0], numbers[1], tuple(numbers[2:])

    return parse


def typed_step(text: str) -> Step:
    """X,Y,CHỮ: điểm bấm lấy focus và chữ gõ vào (\\t, \\r, \\b là Tab, Enter, Backspace)."""
    parts = text.split(",", 2)
    if len(parts) != 3 or not parts[2]:
        raise argparse.ArgumentTypeError(f"cần X,Y,CHỮ: {text}")
    numbers = numbers_of(",".join(parts[:2]), 2)
    typed = parts[2]
    for escape, key in TYPED_KEYS.items():
        typed = typed.replace(escape, key)
    if any(ord(letter) > 0xFFFF for letter in typed):
        raise argparse.ArgumentTypeError(f"chỉ nhận ký tự trong mặt phẳng cơ bản: {text}")
    return TYPE, numbers[0], numbers[1], tuple(ord(letter) for letter in typed)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bấm vào vùng chơi của client rồi chụp ảnh")
    parser.add_argument("exe")
    parser.add_argument("--out", required=True, help="thư mục nhận ảnh PNG")
    steps = {"dest": "steps", "action": "append", "default": []}
    parser.add_argument("--click", type=step_of(CLICK), help="bấm trái ở điểm X,Y", **steps)
    parser.add_argument("--drop", type=step_of(DROP), help="nhấn ở X,Y rồi bỏ, không nhả", **steps)
    parser.add_argument("--hold", type=step_of(HOLD, 1), help="giữ nút trái ở X,Y trong MS mili giây", **steps)
    parser.add_argument("--turn", type=step_of(TURN, 2), help="kéo phải từ X,Y đi DX,DY", **steps)
    parser.add_argument("--tilt", type=step_of(TILT, 2), help="kéo nút giữa từ X,Y đi DX,DY", **steps)
    parser.add_argument("--wheel", type=step_of(WHEEL, 1), help="lăn N nấc ở X,Y", **steps)
    parser.add_argument("--type", type=typed_step, help="bấm ô nhập ở X,Y rồi gõ CHỮ", **steps)
    parser.add_argument("--settle", type=float, default=2.5, help="giây chờ cảnh hiện rồi mới bấm")
    parser.add_argument("--pause", type=float, default=0.6, help="giây chờ sau mỗi bước")
    parser.add_argument("rest", nargs="*", help="đối số chuyển cho exe")
    return parser.parse_args(argv)


def play(window: int, chosen: argparse.Namespace, out: pathlib.Path) -> bool:
    """Chụp lúc đầu rồi làm từng bước; trả False khi có lần chụp hỏng."""
    time.sleep(chosen.settle)
    size = shoot(window, out / "00-start.png")
    if size is None:
        return False
    print(f"vùng chơi {size[0]}x{size[1]}; 00-start.png")
    for index, step in enumerate(chosen.steps, 1):
        kind, across, down, _ = step
        ACTIONS[kind](window, step)
        time.sleep(chosen.pause)
        name = f"{index:02d}-{across}-{down}.png"
        if shoot(window, out / name) is None:
            return False
        print(f"{kind} {across},{down}; {name}")
    return True


def run(chosen: argparse.Namespace) -> int:
    exe = pathlib.Path(chosen.exe).resolve()
    out = pathlib.Path(chosen.out)
    out.mkdir(parents=True, exist_ok=True)
    log_path = out / "client.log"
    with open(log_path, "wb") as log:
        command = [str(exe), *chosen.rest]
        # Cửa sổ hiện mà không lấy focus: người đang dùng máy không bị cướp bàn phím.
        quiet = subprocess.STARTUPINFO(
            dwFlags=subprocess.STARTF_USESHOWWINDOW, wShowWindow=SHOW_NO_ACTIVATE)
        # Cửa sổ không có focus: không có biến này SDL coi cú nhấn thật đầu tiên chỉ là cú kích hoạt cửa sổ
        # và bỏ nó (SDL_HINT_MOUSE_FOCUS_CLICKTHROUGH), nên lần kéo bằng nút thật mất đúng lần nhấn.
        environment = {**os.environ, "SDL_MOUSE_FOCUS_CLICKTHROUGH": "1"}
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, env=environment,
                                   creationflags=CREATE_NO_WINDOW, startupinfo=quiet)
        window = wait_for_window(process, 20.0)
        if window is None:
            process.kill()
            print("không thấy cửa sổ của client")
            return 100
        report_placement(window)
        ignore_hardware_input(window)
        home = wintypes.POINT()
        user32.GetCursorPos(ctypes.byref(home))
        is_shot = play(window, chosen, out)
        user32.SetCursorPos(home.x, home.y)
        user32.PostMessageW(window, WM_CLOSE, 0, 0)
        try:
            code = process.wait(timeout=20)
        except subprocess.TimeoutExpired:
            process.kill()
            print("client không tự thoát sau WM_CLOSE")
            return 101
    print(f"client thoát mã {code}; log ở {log_path}")
    return code if is_shot else 103


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    declare()
    user32.SetProcessDpiAwarenessContext(HANDLE(-4))
    return run(parse_args(sys.argv[1:]))


if __name__ == "__main__":
    sys.exit(main())
