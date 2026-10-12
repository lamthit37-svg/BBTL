# Cook bản đồ .glb thành .vnmap bằng map_cook, chương trình C++ của dự án VnNet: chia mảnh,
# ba mức chi tiết, nén meshoptimizer, nướng độ che khuất. Tệp này chỉ tìm chương trình, kiểm
# đường dẫn, chạy và chuyển lời của nó ra. Định dạng .vnmap do map_cook quyết.
# Tìm map_cook theo biến BAKE_MAP_COOK, không có thì theo PATH. Không ghi cứng đường dẫn nào.
# map_cook ghi vào <đích>.partial. Xong mới đổi tên, hỏng thì xoá bản dở và giữ tệp cũ.

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path
from typing import Callable

from paths import hits_client, partial_path, same_place

TOOL_ENV = "BAKE_MAP_COOK"
TOOL_NAME = "map_cook"


class MapCookRefusal(Exception):
    pass


def find_tool() -> Path:
    chosen = os.environ.get(TOOL_ENV)
    if chosen:
        path = Path(chosen)
        if not path.is_file():
            raise MapCookRefusal(f"Lỗi: {TOOL_ENV} không trỏ tới tệp nào")
        return path
    found = shutil.which(TOOL_NAME)
    if found is None:
        raise MapCookRefusal(f"Lỗi: không thấy {TOOL_NAME}. Đặt {TOOL_ENV} hoặc đưa {TOOL_NAME} vào PATH")
    return Path(found)


def _check(source: Path, destination: Path) -> None:
    if not source.is_file():
        raise MapCookRefusal(f"Lỗi: không thấy tệp {source.as_posix()}")
    if hits_client(destination):
        raise MapCookRefusal("Lỗi: không ghi vào thư mục client")
    if same_place(source, destination):
        raise MapCookRefusal("Lỗi: không cook đè lên tệp nguồn")
    if destination.is_dir():
        raise MapCookRefusal("Lỗi: đích phải là tệp .vnmap, không phải thư mục")


def _launch(command: list[str]) -> tuple[int, str]:
    # map_cook in UTF-8. Gom cả stderr để lời báo lỗi đi cùng thứ tự với lời thường.
    try:
        done = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            encoding="utf-8",
            errors="replace",
            check=False,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )
    except OSError as error:
        raise MapCookRefusal(f"Lỗi: không chạy được {command[0]}") from error
    return done.returncode, done.stdout


def cook_map(source: Path, destination: Path, on_line: Callable[[str], None]) -> int:
    # Trả mã thoát của map_cook: 0 xong, 1 dữ liệu, 2 cách dùng.
    _check(source, destination)
    tool = find_tool()
    partial = partial_path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    code, text = _launch([str(tool), str(source), str(partial)])
    for line in text.splitlines():
        on_line(line)
    if code == 0 and partial.is_file():
        os.replace(partial, destination)
        return 0
    partial.unlink(missing_ok=True)
    if code == 0:
        return 1
    return code
