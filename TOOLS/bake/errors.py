# Mã lỗi của gói TLBBPAK1. Lời tiếng Việt trùng describe() của SRC/seal để hai công cụ
# báo cùng một câu khi cùng một lỗi.

from enum import IntEnum


class Code(IntEnum):
    CRYPTO = 0
    BAD_MAGIC = 1
    BAD_VERSION = 2
    WRONG_KEY = 3
    CORRUPT = 4
    MISSING = 5
    DUPLICATE = 6
    NAME = 7
    IO = 8
    TOO_LARGE = 9


DESCRIBE = {
    Code.CRYPTO: "không khởi tạo được mật mã",
    Code.BAD_MAGIC: "không phải gói TLBBPAK1",
    Code.BAD_VERSION: "bản gói không được hỗ trợ",
    Code.WRONG_KEY: "sai khoá",
    Code.CORRUPT: "gói bị sửa hoặc cụt",
    Code.MISSING: "không có mục này",
    Code.DUPLICATE: "tên trùng hoặc cùng băm",
    Code.NAME: "tên tệp không hợp lệ",
    Code.IO: "không đọc hoặc ghi được tệp",
    Code.TOO_LARGE: "một tệp vượt 4 GiB",
}


class BakeError(Exception):
    def __init__(self, code: Code) -> None:
        self.code = code
        super().__init__(DESCRIBE[code])


class Cancelled(Exception):
    def __init__(self) -> None:
        super().__init__("đã huỷ")


class NeedPassphrase(Exception):
    def __init__(self) -> None:
        super().__init__("Cần cụm mật khẩu để mở file khoá.")


class KdfMemory(Exception):
    def __init__(self) -> None:
        super().__init__("Không đủ bộ nhớ cho Argon2id, không hạ mức.")


class KdfLevel(Exception):
    def __init__(self) -> None:
        super().__init__("Mức Argon2id không được hỗ trợ.")


class PassphraseTooLong(Exception):
    def __init__(self) -> None:
        super().__init__("Cụm mật khẩu dài quá 4096 byte.")


MISMATCH_TEXT = "Cụm mật khẩu nhập lại không khớp."
