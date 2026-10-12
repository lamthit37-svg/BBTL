# Tìm hàm C++ mà Game.exe của client 2026 đăng ký cho một tên hàm Lua, để đọc đúng điều script
# nhận được thay vì đoán theo tên (GetEquipDur, IsCanLevelup, GetBaseBag_Num...).
# Cách tìm, đã đối chiếu tay ngày 2026-10-08 trên GetEquipDur (0x140013a70) và IsCanLevelup
# (0x1403954d0): tên hàm là một chuỗi ASCII kết thúc bằng 0 trong .rdata; nơi đăng ký nạp địa chỉ
# hàm bằng "lea r8,[rip+...]" ngay trước "lea rdx,[rip+chuỗi tên]". Một tên có thể đăng ký ở
# nhiều bảng (Player, DataPool, Target...), nên in mọi chỗ khớp.
# Chạy ở gốc dự án:
#   python TOOLS/port/lua_native.py "F:/tl 2026/Bin64/Game.exe" <tên>... [--dump số_byte]
# --dump tháo ngần ấy byte đầu của từng hàm bằng llvm-objdump (cú pháp Intel). Game.exe chỉ đọc.
# Mã thoát: 0 khi mọi tên đều tìm thấy, 1 khi có tên không thấy.
import argparse
import pathlib
import struct
import subprocess
import sys

LEA_RDX = b"\x48\x8d\x15"
LEA_R8 = b"\x4c\x8d\x05"
LEA_BYTES = 7
# "lea r8" của hàm nằm trong chừng này byte trước "lea rdx" của tên.
LOOK_BACK = 24


class Image:
    """Phần đầu PE đủ dùng: địa chỉ gốc và bảng section."""

    def __init__(self, data: bytes) -> None:
        self.data = data
        header = struct.unpack_from("<I", data, 0x3C)[0]
        count = struct.unpack_from("<H", data, header + 6)[0]
        optional_size = struct.unpack_from("<H", data, header + 20)[0]
        optional = header + 24
        self.base = struct.unpack_from("<Q", data, optional + 24)[0]
        self.sections = []
        for index in range(count):
            at = optional + optional_size + index * 40
            name = data[at:at + 8].rstrip(b"\0").decode("ascii", errors="replace")
            size, address, raw_size, raw_at = struct.unpack_from("<IIII", data, at + 8)
            self.sections.append((name, address, max(size, raw_size), raw_at, raw_size))

    def section(self, wanted: str) -> tuple[int, int, int]:
        """Địa chỉ ảo tương đối, chỗ trong tệp và cỡ trong tệp của một section."""
        for name, address, _, raw_at, raw_size in self.sections:
            if name == wanted:
                return address, raw_at, raw_size
        raise SystemExit(f"Game.exe không có section {wanted}")

    def rva_of(self, offset: int) -> int | None:
        for _, address, _, raw_at, raw_size in self.sections:
            if raw_at <= offset < raw_at + raw_size:
                return address + offset - raw_at
        return None


def name_spots(image: Image, name: str) -> list[int]:
    """Địa chỉ ảo tương đối của mọi chuỗi đúng bằng name (có byte 0 ở hai đầu)."""
    needle = b"\0" + name.encode("ascii") + b"\0"
    spots = []
    at = image.data.find(needle)
    while at >= 0:
        rva = image.rva_of(at + 1)
        if rva is not None:
            spots.append(rva)
        at = image.data.find(needle, at + 1)
    return spots


def lea_target(code: bytes, at: int, code_rva: int) -> int:
    """Địa chỉ mà lệnh lea dài 7 byte ở code[at] trỏ tới."""
    displacement = struct.unpack_from("<i", code, at + 3)[0]
    return code_rva + at + LEA_BYTES + displacement


def function_before(code: bytes, at: int, code_rva: int) -> int | None:
    """Hàm nạp bằng lea r8 gần nhất phía trước lệnh lea rdx ở code[at]."""
    back = code.rfind(LEA_R8, max(at - LOOK_BACK, 0), at)
    return lea_target(code, back, code_rva) if back >= 0 else None


def natives_of(image: Image, name: str) -> list[int]:
    """Địa chỉ ảo của các hàm đăng ký dưới tên name."""
    spots = set(name_spots(image, name))
    code_rva, code_at, code_size = image.section(".text")
    code = image.data[code_at:code_at + code_size]
    found = []
    at = code.find(LEA_RDX)
    while at >= 0:
        if lea_target(code, at, code_rva) in spots:
            function = function_before(code, at, code_rva)
            if function is not None:
                found.append(image.base + function)
        at = code.find(LEA_RDX, at + 1)
    return sorted(set(found))


def dump(path: pathlib.Path, address: int, length: int) -> None:
    command = ["llvm-objdump", "-d", "--no-show-raw-insn", "--x86-asm-syntax=intel",
               f"--start-address={address:#x}", f"--stop-address={address + length:#x}", str(path)]
    done = subprocess.run(command, capture_output=True, text=True, check=False)
    lines = [line for line in done.stdout.splitlines() if line.startswith("1")]
    print("\n".join(lines) if lines else done.stderr.strip())


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Tìm hàm C++ của một tên hàm Lua trong Game.exe")
    parser.add_argument("exe", help="Game.exe của client 2026")
    parser.add_argument("names", nargs="+", help="tên hàm Lua, ví dụ GetBaseBag_Num")
    parser.add_argument("--dump", type=int, default=0, help="số byte đầu của hàm cần tháo")
    chosen = parser.parse_args()
    path = pathlib.Path(chosen.exe)
    image = Image(path.read_bytes())
    missing = 0
    for name in chosen.names:
        natives = natives_of(image, name)
        shown = ", ".join(f"{address:#x}" for address in natives) or "không thấy"
        print(f"{name}: {shown}")
        missing += not natives
        for address in natives if chosen.dump else []:
            dump(path, address, chosen.dump)
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
