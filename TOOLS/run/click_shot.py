# Chạy thienlong_client, làm từng thao tác chuột được nêu trên vùng chơi, và sau mỗi bước chụp vùng
# chơi ra một tệp PNG. Dùng để nhìn giao diện và camera sau một chuỗi thao tác mà không cần người
# bấm: nút mở bảng, nút đóng, thẻ; kéo phải xoay camera, kéo nút giữa ngẩng cúi, lăn chuột zoom.
# Cửa sổ của client được dời ra ngoài màn hình ảo và chụp bằng PrintWindow, thông điệp chuột gửi
# thẳng cho cửa sổ (PostMessage). Lý do, đã đo ngày 2026-10-08 với bản để cửa sổ trên màn hình và
# chụp từ màn hình: con trỏ thật nằm trên vùng chơi thì thông điệp di chuyển của nó (kể cả thông
# điệp Windows tự sinh khi một cửa sổ khác hiện lên gần đó) chen vào giữa lúc nhấn và lúc nhả,
# client dời điểm bấm theo nên lần bấm trượt; ảnh chụp còn dính cửa sổ của chương trình khác.
# Chạy ở gốc dự án (chỉ Windows):
#   python TOOLS/run/click_shot.py <exe> --out <thư mục> [--click X,Y | --drop X,Y |
#       --turn X,Y,DX,DY | --tilt X,Y,DX,DY | --wheel X,Y,N]... [--settle giây] [--pause giây]
#       [-- đối số của exe]
# --click bấm rồi nhả tại chỗ. --drop nhấn rồi gửi một thông điệp di chuyển không mang cờ nút và
# không nhả, như khi nút được nhả ngoài cửa sổ: client phải coi lần nhấn là đã huỷ, và lần bấm kế
# tiếp vẫn phải ăn. --turn nhấn phải ở X,Y, kéo đi DX,DY điểm ảnh qua nhiều thông điệp rồi nhả;
# --tilt làm vậy với nút giữa. --wheel lăn N nấc ở X,Y, dương là lăn ra trước. Cửa sổ không có focus
# nên client không giữ con trỏ thật khi kéo. Các bước chạy theo thứ tự viết trên dòng lệnh.
# Ảnh: 00-start.png trước bước đầu, rồi NN-X-Y.png sau bước thứ NN. Mã thoát: mã thoát của exe; 100
# khi không thấy cửa sổ; 101 khi exe không tự thoát sau WM_CLOSE; 102 khi cửa sổ không ra được
# ngoài màn hình; 103 khi một lần chụp hỏng.
import argparse
import ctypes
import ctypes.wintypes as wintypes
import pathlib
import struct
import subprocess
import sys
import time
import zlib

HANDLE = ctypes.c_void_p
WM_CLOSE = 0x0010
WM_MOUSEMOVE = 0x0200
WM_LBUTTONDOWN = 0x0201
WM_LBUTTONUP = 0x0202
WM_RBUTTONDOWN = 0x0204
WM_RBUTTONUP = 0x0205
WM_MBUTTONDOWN = 0x0207
WM_MBUTTONUP = 0x0208
WM_MOUSEWHEEL = 0x020A
MK_LBUTTON = 0x0001
MK_RBUTTON = 0x0002
MK_MBUTTON = 0x0010
WHEEL_DELTA = 120
# Số thông điệp di chuyển của một lần kéo, và giây nghỉ giữa hai thông điệp: dài hơn một khung của
# client để mỗi thông điệp rơi vào một khung riêng.
DRAG_MOVES = 8
DRAG_PAUSE_SECONDS = 0.04
# SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE
MOVE_ONLY = 0x0001 | 0x0004 | 0x0010
# PW_CLIENTONLY | PW_RENDERFULLCONTENT: lấy cả nội dung do GPU vẽ, không cần cửa sổ lộ ra.
PRINT_CLIENT = 0x0001 | 0x0002
# SM_XVIRTUALSCREEN, SM_YVIRTUALSCREEN, SM_CXVIRTUALSCREEN, SM_CYVIRTUALSCREEN
VIRTUAL_SCREEN = (76, 77, 78, 79)
# Khoảng hở giữa mép màn hình ảo và cửa sổ đã dời.
OFFSCREEN_GAP = 64
# Số lần chụp tối đa cho một ảnh và giây chờ giữa hai lần. Đã đo ngày 2026-10-08: PrintWindow đôi
# lúc báo thành công mà ảnh toàn đen, hoặc vùng chơi đọc ra cỡ 0x0, rồi lần chụp sau lại đúng.
SHOT_TRIES = 5
# Số lần chụp tối đa cho một ảnh và giây chờ giữa hai lần. Đã đo ngày 2026-10-08: PrintWindow đôi
# lúc báo thành công mà ảnh toàn đen, hoặc vùng chơi đọc ra cỡ 0x0, rồi lần chụp sau lại đúng.
SHOT_TRIES = 5
SHOT_RETRY_SECONDS = 0.2
CREATE_NO_WINDOW = 0x08000000
# SW_SHOWNOACTIVATE
SHOW_NO_ACTIVATE = 4
CLICK = "bấm"
DROP = "nhấn rồi bỏ"
TURN = "kéo phải"
TILT = "kéo giữa"
WHEEL = "lăn"
TYPE = "gõ"
# Cách viết phím điều khiển trong CHỮ của --type.
TYPED_KEYS = {"\\t": "\t", "\\r": "\r", "\\b": "\b"}
# Thông điệp nhấn, nhả và cờ nút của hai kiểu kéo.
DRAG_BUTTONS = {
    TURN: (WM_RBUTTONDOWN, WM_RBUTTONUP, MK_RBUTTON),
    TILT: (WM_MBUTTONDOWN, WM_MBUTTONUP, MK_MBUTTON),
}
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


def move_off_screen(window: int) -> bool:
    """Dời cửa sổ sang phải mép màn hình ảo; trả True khi nó đã nằm hẳn ngoài mọi màn hình."""
    left, top, width, _ = (user32.GetSystemMetrics(index) for index in VIRTUAL_SCREEN)
    edge = left + width
    user32.SetWindowPos(window, None, edge + OFFSCREEN_GAP, top, 0, 0, MOVE_ONLY)
    frame = wintypes.RECT()
    user32.GetWindowRect(window, ctypes.byref(frame))
    return frame.left >= edge


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
    user32.PostMessageW(window, WM_MOUSEMOVE, 0, place)
    time.sleep(0.05)
    user32.PostMessageW(window, WM_LBUTTONDOWN, MK_LBUTTON, place)
    time.sleep(0.08)
    ending = WM_MOUSEMOVE if kind == DROP else WM_LBUTTONUP
    user32.PostMessageW(window, ending, 0, place)


def drag(window: int, step: Step) -> None:
    kind, across, down, (shift_x, shift_y) = step
    pressing, releasing, flag = DRAG_BUTTONS[kind]
    start = place_of(across, down)
    user32.PostMessageW(window, WM_MOUSEMOVE, 0, start)
    time.sleep(0.05)
    user32.PostMessageW(window, pressing, flag, start)
    time.sleep(0.08)
    for move in range(1, DRAG_MOVES + 1):
        here = place_of(across + shift_x * move // DRAG_MOVES, down + shift_y * move // DRAG_MOVES)
        user32.PostMessageW(window, WM_MOUSEMOVE, flag, here)
        time.sleep(DRAG_PAUSE_SECONDS)
    user32.PostMessageW(window, releasing, 0, place_of(across + shift_x, down + shift_y))


def roll(window: int, step: Step) -> None:
    _, across, down, (notches,) = step
    turn = WHEEL_DELTA if notches > 0 else -WHEEL_DELTA
    for _ in range(abs(notches)):
        user32.PostMessageW(window, WM_MOUSEWHEEL, (turn & 0xFFFF) << 16, place_of(across, down))
        time.sleep(DRAG_PAUSE_SECONDS)


ACTIONS = {CLICK: press, DROP: press, TURN: drag, TILT: drag, WHEEL: roll}


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


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bấm vào vùng chơi của client rồi chụp ảnh")
    parser.add_argument("exe")
    parser.add_argument("--out", required=True, help="thư mục nhận ảnh PNG")
    steps = {"dest": "steps", "action": "append", "default": []}
    parser.add_argument("--click", type=step_of(CLICK), help="bấm trái ở điểm X,Y", **steps)
    parser.add_argument("--drop", type=step_of(DROP), help="nhấn ở X,Y rồi bỏ, không nhả", **steps)
    parser.add_argument("--turn", type=step_of(TURN, 2), help="kéo phải từ X,Y đi DX,DY", **steps)
    parser.add_argument("--tilt", type=step_of(TILT, 2), help="kéo nút giữa từ X,Y đi DX,DY", **steps)
    parser.add_argument("--wheel", type=step_of(WHEEL, 1), help="lăn N nấc ở X,Y", **steps)
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
    parser.add_argument("--click", type=step_of(CLICK), help="bấm trái ở điểm X,Y", **steps)
    parser.add_argument("--drop", type=step_of(DROP), help="nhấn ở X,Y rồi bỏ, không nhả", **steps)
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
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=CREATE_NO_WINDOW, startupinfo=quiet)
        window = wait_for_window(process, 20.0)
        if window is None:
            process.kill()
            print("không thấy cửa sổ của client")
            return 100
        if not move_off_screen(window):
            process.kill()
            print("cửa sổ của client không ra được ngoài màn hình")
            return 102
        is_shot = play(window, chosen, out)
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
