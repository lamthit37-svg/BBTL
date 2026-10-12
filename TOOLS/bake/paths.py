# Đường dẫn của công cụ niêm và cook. Khớp SRC/seal/tree.cpp: dấu /, chỉ hạ A–Z,
# từ chối đích có chuỗi "thienlong/client". Game không import tệp này.

from pathlib import Path

CLIENT_MARK = "thienlong/client"


def fold_ascii(text: str) -> str:
    folded = []
    for unit in text:
        code = ord(unit)
        if 65 <= code <= 90:
            folded.append(chr(code - 65 + 97))
        else:
            folded.append(unit)
    return "".join(folded)


def canonical_text(path: Path) -> str | None:
    try:
        full = path.resolve(strict=False)
    except OSError:
        return None
    return fold_ascii(full.as_posix())


def hits_client(path: Path) -> bool:
    # Không chuẩn hoá được thì từ chối ghi. Đọc nguồn mang dấu này vẫn được.
    text = canonical_text(path)
    if text is None:
        return True
    return CLIENT_MARK in text


def covers(parent: Path, child: Path) -> bool:
    parent_text = canonical_text(parent)
    child_text = canonical_text(child)
    if parent_text is None or child_text is None:
        return False
    if child_text == parent_text:
        return True
    if not child_text.startswith(parent_text):
        return False
    return len(child_text) > len(parent_text) and child_text[len(parent_text)] == "/"


def same_place(left: Path, right: Path) -> bool:
    left_text = canonical_text(left)
    right_text = canonical_text(right)
    if left_text is None or right_text is None:
        return True
    return left_text == right_text


def path_blocks(path: Path) -> bool:
    try:
        return path.exists()
    except OSError:
        return True


def partial_path(path: Path) -> Path:
    # Khớp C++: path += ".partial", không đổi đuôi .tlpak thành .partial.
    return Path(str(path) + ".partial")
