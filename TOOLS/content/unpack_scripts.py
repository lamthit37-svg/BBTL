# Tách MỌI script Lua của client 2026 ra khỏi gói Data/Config.axp và Data/Interface.axp, đã gỡ vỏ CryptBox và đã
# giải mã script, ghi theo đúng đường dẫn trong gói:
#   <đích>/Config/<tên trong gói>, <đích>/Interface/<tên trong gói>, kèm MANIFEST.tsv (đường dẫn, cỡ và sha256 của tệp
#   ghi ra, sha256 của byte gốc, cách lưu trong gói, số dòng hỏng, kết quả kiểm). Phép giải ở axp_pack.py, cryptbox.py,
#   script_crypt.py. Mặc định ghi byte nguyên (GBK, CRLF của gốc); --utf8 đổi văn bản sang UTF-8 từng dòng (script_charset.py)
#   để trình soạn mở đọc được, CRLF giữ nguyên. Cột source_sha256 luôn là sha256 của byte gốc để đối chiếu lại với gói.
# Kiểm: mọi script mã hoá phải qua CRC đầu tệp (script_crypt.py); thêm --luaplus <thư mục Bin64 của client> thì mỗi
# script được biên dịch (không chạy) bằng LuaPlus.dll chính của client, chỉ ghi nhận lỗi cú pháp của script đó.
# Chạy ở gốc dự án:
#   python TOOLS/content/unpack_scripts.py <thư mục Data của client> src/client/script [--utf8] [--luaplus <Bin64>]
import argparse
import ctypes
import hashlib
import os
import sys
from pathlib import Path

import cryptbox
import script_charset
import script_crypt
from axp_pack import Axp

PACKS = (("Config.axp", "Config"), ("Interface.axp", "Interface"))
# lua_Chunkwriter của Lua 5.0: int (*)(lua_State*, const void* mảnh, size_t cỡ, void* dữ liệu người dùng)
_WRITER = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p)


class Compiler:
    """Biên dịch (không chạy) một đoạn Lua bằng LuaPlus.dll của client; mỗi lần gọi trả "" khi qua, hoặc lời lỗi."""

    def __init__(self, bin_dir: Path) -> None:
        os.add_dll_directory(str(bin_dir))
        self.lib = ctypes.CDLL(str(bin_dir / "LuaPlus.dll"))
        self.lib.lua_open.restype = ctypes.c_void_p
        self.lib.luaL_loadbuffer.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p]
        self.lib.luaL_loadbuffer.restype = ctypes.c_int
        self.lib.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.lib.lua_tostring.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.lib.lua_tostring.restype = ctypes.c_char_p
        self.lib.lua_dump.argtypes = [ctypes.c_void_p, _WRITER, ctypes.c_void_p]
        self.lib.lua_dump.restype = ctypes.c_int
        self.state = self.lib.lua_open()
        if not self.state:
            raise RuntimeError("lua_open trả null")

    def compile(self, name: str, text: bytes) -> str:
        code = self.lib.luaL_loadbuffer(self.state, text, len(text), b"@" + name.encode("utf-8"))
        message = "" if code == 0 else (self.lib.lua_tostring(self.state, -1) or b"?").decode("gbk", "replace")
        self.lib.lua_settop(self.state, 0)
        return message

    def dump(self, name: str, text: bytes) -> bytes | str:
        """Mã trung gian (kèm số dòng, hằng số, chuỗi) của đoạn Lua đã biên dịch, hoặc lời lỗi (str) khi biên dịch hỏng.
        Hai đoạn có cùng tên và cho cùng mã trung gian thì chạy y hệt nhau."""
        code = self.lib.luaL_loadbuffer(self.state, text, len(text), b"@" + name.encode("utf-8"))
        if code != 0:
            message = (self.lib.lua_tostring(self.state, -1) or b"?").decode("gbk", "replace")
            self.lib.lua_settop(self.state, 0)
            return message
        chunks: list[bytes] = []

        def write(_state: int, data: int, size: int, _user: int) -> int:
            chunks.append(ctypes.string_at(data, size))
            return 0

        status = self.lib.lua_dump(self.state, _WRITER(write), None)
        self.lib.lua_settop(self.state, 0)
        blob = b"".join(chunks)
        # Lua 5.0: lua_dump trả 1 khi dump được (0 khi đỉnh ngăn xếp không phải hàm Lua). Đầu dump của LuaPlus là
        # "\x1b~..." chứ không phải "\x1bLua" (đo 2026-10-15), chỉ cần byte ESC mở đầu.
        if status != 1 or not blob.startswith(b"\x1b"):
            return f"lua_dump trả {status}, {len(blob)} byte"
        return blob


def safe_relative(name: bytes) -> Path:
    """Đường dẫn ra từ tên GB18030 trong gói; tên là dữ liệu ngoài nên cấm tuyệt đối, '..', ':' và đoạn rỗng."""
    text = name.decode("gb18030")
    parts = text.split("/")
    if text.startswith("/") or ":" in text or "\\" in text or any(part in ("", ".", "..") for part in parts):
        raise ValueError(f"tên không an toàn: {text!r}")
    return Path(*parts)


def collect(data_dir: Path, out_dir: Path, compiler: Compiler | None, utf8: bool) -> list[list[str]]:
    rows: list[list[str]] = []
    seen: dict[str, str] = {}
    for pack_file, family in PACKS:
        with Axp(data_dir / pack_file) as pack:
            for name in sorted(pack.names()):
                if not name.lower().endswith(b".lua"):
                    continue
                relative = Path(family) / safe_relative(name)
                folded = relative.as_posix().lower()
                if folded in seen and seen[folded] != relative.as_posix():
                    raise ValueError(f"trùng tên khác hoa thường: {seen[folded]} và {relative.as_posix()}")
                seen[folded] = relative.as_posix()
                stored = pack.read(name)
                wrapped = cryptbox.is_wrapped(stored)
                inner = cryptbox.unwrap(stored) if wrapped else stored
                encoded = script_crypt.is_encoded(inner)
                original = script_crypt.decode(inner)
                text, damaged = script_charset.convert(original) if utf8 else (original, 0)
                compiled = "không kiểm" if compiler is None else (compiler.compile(relative.as_posix(), text) or "OK")
                target = out_dir / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(text)
                rows.append([
                    relative.as_posix(), str(len(text)), hashlib.sha256(text).hexdigest(), hashlib.sha256(original).hexdigest(),
                    pack_file, "bọc CryptBox" if wrapped else "thô", "Rijndael192+XOR" if encoded else "văn bản",
                    str(damaged), compiled,
                ])
    return rows


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Tách script Lua của client 2026 ra khỏi gói .axp")
    parser.add_argument("data", type=Path, help="thư mục Data của client (có Config.axp, Interface.axp)")
    parser.add_argument("out", type=Path, help="thư mục đích, ví dụ src/client/script")
    parser.add_argument("--utf8", action="store_true", help="đổi văn bản sang UTF-8 (mặc định: byte nguyên, GBK)")
    parser.add_argument("--luaplus", type=Path, help="thư mục Bin64 của client để biên dịch thử từng script")
    chosen = parser.parse_args()
    compiler = Compiler(chosen.luaplus) if chosen.luaplus else None
    rows = collect(chosen.data, chosen.out, compiler, chosen.utf8)
    rows.sort(key=lambda row: row[0])
    header = ["path", "bytes", "sha256", "source_sha256", "pack", "stored", "encoding", "damaged_lines", "compile"]
    manifest = "\n".join("\t".join(row) for row in [header] + rows) + "\n"
    (chosen.out / "MANIFEST.tsv").write_text(manifest, encoding="utf-8", newline="\n")
    bad = [row for row in rows if row[8] not in ("OK", "không kiểm")]
    print(f"{len(rows)} script, {sum(int(row[1]) for row in rows):,} byte -> {chosen.out}")
    for column, title in ((4, "gói"), (5, "cách lưu"), (6, "mã hoá"), (8, "biên dịch")):
        counts: dict[str, int] = {}
        for row in rows:
            key = row[column] if column != 8 or row[8] in ("OK", "không kiểm") else "LỖI"
            counts[key] = counts.get(key, 0) + 1
        print(f"  {title}: {counts}")
    damaged = [row for row in rows if row[7] != "0"]
    print(f"  dòng có byte hỏng sẵn trong gói gốc (thành U+FFFD): {sum(int(row[7]) for row in damaged)} dòng ở {len(damaged)} tệp")
    for row in bad[:20]:
        print(f"  LỖI BIÊN DỊCH {row[0]}: {row[8][:120]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
