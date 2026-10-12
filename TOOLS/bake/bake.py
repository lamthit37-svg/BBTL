# Thiên Long — niêm asset và cook âm thanh, ngoài tiến trình game.
#   python bake.py
#   python bake.py new-key --out <khoá>
#   python bake.py seal --key <khoá> --from <thư mục> --out <tệp.tlpak>
#   python bake.py open --key <khoá> --from <tệp.tlpak> --out <thư mục>
#   python bake.py verify --key <khoá> --from <tệp.tlpak>
#   python bake.py cook-audio --from <thư mục sound> --out <thư mục>
#   python bake.py cook-map --from <tệp.glb> --out <tệp.vnmap>
# Không đối số thì mở cửa sổ. Có lệnh, hoặc --headless, thì chạy không cửa sổ.
# Cụm mật khẩu không đi trên dòng lệnh: biến BAKE_PASSPHRASE hoặc hỏi khi có máy gõ.
# Mã thoát: 0 xong, 1 dữ liệu, 2 cách dùng.

from __future__ import annotations

import getpass
import os
import sys
from dataclasses import dataclass
from pathlib import Path

from audio_cook import CookRefusal, cook_tree
from errors import MISMATCH_TEXT, BakeError, KdfLevel, KdfMemory, NeedPassphrase, PassphraseTooLong
from keyfile import key_is_wrapped, limits_for_choice
from map_cook import MapCookRefusal, cook_map
from tlpak import random_key
from tree import load_key, open_folder, seal_folder, store_key, verify_folder, wipe_key

USAGE = (
    "cách dùng:\n"
    "  python bake.py\n"
    "  python bake.py new-key --out <khoá>\n"
    "  python bake.py seal --key <khoá> --from <thư mục> --out <tệp.tlpak>\n"
    "  python bake.py open --key <khoá> --from <tệp.tlpak> --out <thư mục>\n"
    "  python bake.py verify --key <khoá> --from <tệp.tlpak>\n"
    "  python bake.py cook-audio --from <thư mục sound> --out <thư mục>\n"
    "  python bake.py cook-map --from <tệp.glb> --out <tệp.vnmap>\n"
    "  python bake.py --headless <lệnh> ...\n"
    "Khoá không nằm trong client. Game không đọc gói này nên tốc độ nạp và khung hình không đổi.\n"
    "Ảnh chụp GPU lúc game đang chạy vẫn thấy asset đã đưa lên bộ nhớ hình.\n"
    "Có cụm mật khẩu thì Argon2id bọc file khoá, mặc định 1 GiB. BAKE_KDF=moderate chọn 256 MiB.\n"
    "Thiếu bộ nhớ thì dừng, không hạ mức. Để trống thì chính file khoá là bí mật.\n"
    "Đặt BAKE_PASSPHRASE hoặc gõ khi được hỏi. Không đưa cụm mật khẩu lên dòng lệnh.\n"
    "Cook âm thanh ghi .tla ra thư mục riêng, không đặt cạnh tệp gốc và không chép vào client.\n"
    "Cook bản đồ chạy map_cook của VnNet: đặt BAKE_MAP_COOK hoặc đưa map_cook vào PATH.\n"
)


class _Usage(Exception):
    pass


class _Stop(Exception):
    pass


def _tty() -> bool:
    try:
        return bool(sys.stdin.isatty())
    except Exception:
        return False


def _ask(prompt: str) -> str:
    try:
        return getpass.getpass(prompt)
    except EOFError as error:
        raise NeedPassphrase() from error


def _passphrase(path: Path | None, creating: bool) -> str:
    if path is not None and not creating and not key_is_wrapped(path):
        return ""
    env = os.environ.get("BAKE_PASSPHRASE")
    if env is not None:
        return env
    if not _tty():
        if creating:
            return ""
        raise NeedPassphrase()
    if not creating:
        return _ask("Cụm mật khẩu: ")
    first = _ask("Cụm mật khẩu (để trống thì chính file khoá là bí mật): ")
    if first == "":
        return ""
    second = _ask("Nhập lại cụm mật khẩu: ")
    if first != second:
        raise _Stop(MISMATCH_TEXT)
    return first


@dataclass
class _Request:
    command: str
    key: str = ""
    source: str = ""
    destination: str = ""


def _utf8() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is None:
            continue
        try:
            reconfigure(encoding="utf-8")
        except Exception:
            continue


def _fail_usage(message: str) -> int:
    print(f"bake: {message}", file=sys.stderr)
    print(USAGE, file=sys.stderr)
    return 2


def _parse(args: list[str]) -> _Request:
    if not args:
        raise _Usage("thiếu lệnh")
    request = _Request(args[0])
    index = 1
    while index < len(args):
        flag = args[index]
        if not flag.startswith("--") or index + 1 >= len(args):
            raise _Usage("đối số không hợp lệ")
        value = args[index + 1]
        if flag == "--key":
            request.key = value
        elif flag == "--from":
            request.source = value
        elif flag == "--out":
            request.destination = value
        else:
            raise _Usage("đối số không hợp lệ")
        index += 2
    return request


def _require(request: _Request, need: str, sentence: str) -> None:
    present = {"k": request.key, "f": request.source, "o": request.destination}
    for mark, value in present.items():
        wanted = mark in need
        filled = bool(value)
        if wanted != filled:
            raise _Usage(sentence)


def _run_new_key(request: _Request) -> int:
    _require(request, "o", "new-key chỉ nhận --out")
    opslimit, memlimit = limits_for_choice(os.environ.get("BAKE_KDF"))
    phrase = _passphrase(None, creating=True)
    key = random_key()
    try:
        if phrase:
            store_key(key, Path(request.destination), phrase, opslimit, memlimit)
        else:
            store_key(key, Path(request.destination))
    finally:
        wipe_key(key)
    print("đã ghi khoá")
    if phrase:
        print("Chép file không đủ để mở.")
    else:
        print("Chính file khoá là bí mật.")
    return 0


def _load(path: Path) -> bytearray:
    return load_key(path, _passphrase(path, creating=False))


def _run_seal(request: _Request) -> int:
    _require(request, "kfo", "seal cần --key, --from và --out")
    key = _load(Path(request.key))
    try:
        saved = seal_folder(key, Path(request.source), Path(request.destination))
    finally:
        wipe_key(key)
    print(f"đã niêm {saved.files} tệp, {saved.raw_bytes} byte")
    return 0


def _run_open(request: _Request) -> int:
    _require(request, "kfo", "open cần --key, --from và --out")
    key = _load(Path(request.key))
    try:
        saved = open_folder(key, Path(request.source), Path(request.destination))
    finally:
        wipe_key(key)
    print(f"đã mở {saved.files} tệp, {saved.raw_bytes} byte")
    return 0


def _run_verify(request: _Request) -> int:
    _require(request, "kf", "verify cần --key và --from")
    key = _load(Path(request.key))
    try:
        saved = verify_folder(key, Path(request.source))
    finally:
        wipe_key(key)
    print(f"gói nguyên, {saved.files} tệp, {saved.raw_bytes} byte")
    return 0


def _run_cook(request: _Request) -> int:
    _require(request, "fo", "cook-audio cần --from và --out")

    def on_error(line: str) -> None:
        print(line, file=sys.stderr)

    report = cook_tree(Path(request.source), Path(request.destination), on_error=on_error)
    for line in report.lines():
        print(line)
    if report.failed:
        return 1
    return 0


def _run_cook_map(request: _Request) -> int:
    _require(request, "fo", "cook-map cần --from và --out")
    return cook_map(Path(request.source), Path(request.destination), on_line=print)


def _run(request: _Request) -> int:
    if request.command == "new-key":
        return _run_new_key(request)
    if request.command == "seal":
        return _run_seal(request)
    if request.command == "open":
        return _run_open(request)
    if request.command == "verify":
        return _run_verify(request)
    if request.command == "cook-audio":
        return _run_cook(request)
    if request.command == "cook-map":
        return _run_cook_map(request)
    raise _Usage("lệnh không rõ")


def main(argv: list[str] | None = None) -> int:
    _utf8()
    args = list(sys.argv[1:] if argv is None else argv)
    if not args or args == ["--gui"]:
        from gui import run_gui

        return run_gui()
    if args[0] == "--headless":
        args = args[1:]
    try:
        request = _parse(args)
        return _run(request)
    except _Usage as error:
        return _fail_usage(str(error))
    except (BakeError, NeedPassphrase, KdfMemory, KdfLevel, PassphraseTooLong, _Stop) as error:
        print(f"bake: {error}", file=sys.stderr)
        return 1
    except (CookRefusal, MapCookRefusal) as error:
        print(str(error), file=sys.stderr)
        return 1
    except Exception as error:
        print(f"bake: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
