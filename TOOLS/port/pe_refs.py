# Soi một tệp PE x64 của client 2026 (Game.exe, Render.dll...) để port hành vi theo đúng mã máy:
# tìm chuỗi, tìm nơi mã trỏ tới một địa chỉ, tìm biên hàm, đọc vtable theo RTTI, và tháo một hàm kèm
# chú thích (chuỗi, hằng số thực, tên hàm import, đích của lệnh gọi). Tệp PE chỉ đọc.
# Biên hàm lấy từ bảng .pdata (mỗi hàm x64 có khung ngăn xếp có một dòng RUNTIME_FUNCTION), nên
# không phải đoán chỗ hàm bắt đầu. Hàm lá không có dòng .pdata: func tháo từ địa chỉ được nêu tới
# lệnh ret hay jmp đứng trước byte đệm int3. Tham chiếu tìm bằng cách thử mọi vị trí trong .text
# như một độ dời 32 bit tính từ RIP, với 0, 1 hoặc 4 byte hằng theo sau, rồi tháo hàm chứa nó để
# chỉ giữ chỗ có đúng một lệnh trỏ tới đích; chỗ nằm ngoài mọi dòng .pdata không tháo được nên in
# kèm chữ "chưa kiểm".
# Chạy ở gốc dự án (cần numpy và capstone):
#   python TOOLS/port/pe_refs.py <pe> text <chuỗi con>       chuỗi ASCII chứa chuỗi con, kèm địa chỉ
#   python TOOLS/port/pe_refs.py <pe> refs <địa chỉ|=chuỗi>  lệnh trỏ tới địa chỉ, kèm hàm chứa
#   python TOOLS/port/pe_refs.py <pe> calls <địa chỉ>        nơi gọi (call, jmp rel32) tới địa chỉ
#   python TOOLS/port/pe_refs.py <pe> func <địa chỉ>         tháo cả hàm chứa địa chỉ
#   python TOOLS/port/pe_refs.py <pe> func <đầu>..<cuối>     tháo một khoảng (hàm bị .pdata chia mảnh)
#   python TOOLS/port/pe_refs.py <pe> rtti <tên lớp>         vtable của lớp và các hàm ảo
#   python TOOLS/port/pe_refs.py <pe> floats <số thực>       nơi mã đọc một hằng float hay double
#   python TOOLS/port/pe_refs.py <pe> imports <tên hàm>      hàm gọi một hàm import (GetAsyncKeyState)
#   python TOOLS/port/pe_refs.py <pe> exports <chuỗi con>    hàm và biến export có tên chứa chuỗi con,
#       kèm địa chỉ; DLL của client xuất hàm thành viên theo tên đã trang trí (FalagardSoftKeyBoard@)
#   python TOOLS/port/pe_refs.py <pe> vcalls <biến>:<độ dời> hàm vừa nạp con trỏ ở biến toàn cục vừa
#       gọi hàm ảo ở độ dời đó (14103d668:190): nơi gọi một hàm ảo của một hệ thống
#   python TOOLS/port/pe_refs.py <pe> uses <độ dời>:<đầu>..<cuối>  lệnh trong khoảng mã đụng thành
#       viên [thanh ghi + độ dời] (164:140640000..140652000)
#   python TOOLS/port/pe_refs.py <pe> imm <hằng>:<đầu>..<cuối>     lệnh trong khoảng mã có hằng tức
#       thời bằng hằng (1f4:140613000..14061b000)
#   python TOOLS/port/pe_refs.py <pe> jump <bảng>:<số ô>[:<bảng byte>:<số ô>:<giá trị đầu>]  bảng
#       nhảy của một switch; bảng là độ dời tính từ gốc ảnh như trong lệnh mov của switch
#       (64da38:17, hay 64d948:9:64d96c:67:10 khi switch đi qua bảng chỉ số một byte)
# Địa chỉ viết dạng hex (0x140013a70). "=chuỗi" là đúng nguyên chuỗi đó (kết thúc bằng byte 0).
import argparse
from collections.abc import Callable, Iterator
import pathlib
import struct
import sys

import capstone
import numpy

MIN_TEXT = 4
TEXT_LIMIT = 200
# Tên đã trang trí của hàm C++ dài hơn chuỗi thường; quá mức này thì cắt.
EXPORT_NAME_LIMIT = 1024
VTABLE_LIMIT = 400
# Hàm lá dài nhất được tháo khi không có dòng .pdata nào chỉ chỗ kết thúc.
LEAF_LIMIT = 0x400
INT3 = 0xCC
# Số byte hằng có thể đứng sau độ dời của một lệnh trỏ theo RIP.
TAILS = (0, 1, 4)
FLOAT_OPS = {"movss", "addss", "subss", "mulss", "divss", "comiss", "ucomiss", "maxss", "minss",
             "cvtss2sd", "sqrtss", "andps", "xorps", "movaps", "movups"}
DOUBLE_OPS = {"movsd", "addsd", "subsd", "mulsd", "divsd", "comisd", "ucomisd", "maxsd", "minsd",
              "cvtsd2ss", "sqrtsd", "andpd", "xorpd"}


class Image:
    """Tệp PE x64: section, bảng hàm .pdata, bảng import."""

    def __init__(self, path: pathlib.Path) -> None:
        self.data = path.read_bytes()
        header = struct.unpack_from("<I", self.data, 0x3C)[0]
        count = struct.unpack_from("<H", self.data, header + 6)[0]
        optional_size = struct.unpack_from("<H", self.data, header + 20)[0]
        self.optional = header + 24
        self.base = struct.unpack_from("<Q", self.data, self.optional + 24)[0]
        self.sections = []
        for index in range(count):
            at = self.optional + optional_size + index * 40
            name = self.data[at:at + 8].rstrip(b"\0").decode("ascii", errors="replace")
            size, address, raw_size, raw_at = struct.unpack_from("<IIII", self.data, at + 8)
            self.sections.append((name, address, size, raw_at, raw_size))
        self.functions = self._functions()
        self.imports = self._imports()

    def directory(self, index: int) -> tuple[int, int]:
        return struct.unpack_from("<II", self.data, self.optional + 112 + index * 8)

    def offset_of(self, rva: int) -> int | None:
        for _, address, _, raw_at, raw_size in self.sections:
            if address <= rva < address + raw_size:
                return raw_at + rva - address
        return None

    def rva_of(self, offset: int) -> int | None:
        for _, address, _, raw_at, raw_size in self.sections:
            if raw_at <= offset < raw_at + raw_size:
                return address + offset - raw_at
        return None

    def section_of(self, rva: int) -> str:
        for name, address, size, _, raw_size in self.sections:
            if address <= rva < address + max(size, raw_size):
                return name
        return ""

    def bytes_at(self, rva: int, length: int) -> bytes:
        offset = self.offset_of(rva)
        return b"" if offset is None else self.data[offset:offset + length]

    def code(self) -> tuple[int, bytes]:
        for name, address, _, raw_at, raw_size in self.sections:
            if name == ".text":
                return address, self.data[raw_at:raw_at + raw_size]
        raise SystemExit("tệp không có section .text")

    def _functions(self) -> numpy.ndarray:
        rva, size = self.directory(3)
        offset = self.offset_of(rva)
        if offset is None or size == 0:
            return numpy.zeros((0, 3), dtype=numpy.uint32)
        table = numpy.frombuffer(self.data, dtype="<u4", count=size // 4, offset=offset)
        return table.reshape(-1, 3)

    def function_of(self, rva: int) -> tuple[int, int] | None:
        """Biên [đầu, cuối) của dòng .pdata chứa rva."""
        starts = self.functions[:, 0]
        index = int(numpy.searchsorted(starts, rva, side="right")) - 1
        if index < 0:
            return None
        begin, end = int(self.functions[index, 0]), int(self.functions[index, 1])
        return (begin, end) if begin <= rva < end else None

    def _imports(self) -> dict[int, str]:
        names: dict[int, str] = {}
        rva, _ = self.directory(1)
        at = self.offset_of(rva)
        while at is not None:
            lookup, _, _, name_rva, first = struct.unpack_from("<IIIII", self.data, at)
            if name_rva == 0:
                break
            library = self.text_at(name_rva) or "?"
            self._thunks(names, library, lookup or first, first)
            at += 20
        return names

    def _thunks(self, names: dict[int, str], library: str, lookup: int, first: int) -> None:
        index = 0
        while True:
            entry = self.bytes_at(lookup + index * 8, 8)
            value = struct.unpack("<Q", entry)[0] if len(entry) == 8 else 0
            if value == 0:
                return
            by_number = value >> 63
            label = f"#{value & 0xFFFF}" if by_number else (self.text_at((value & 0x7FFFFFFF) + 2) or "?")
            names[first + index * 8] = f"{library}!{label}"
            index += 1

    def text_at(self, rva: int) -> str | None:
        """Chuỗi ASCII in được, kết thúc bằng 0, bắt đầu ở rva; None khi không phải chuỗi."""
        raw = self.bytes_at(rva, TEXT_LIMIT)
        end = raw.find(b"\0")
        chunk = raw[:end] if end >= 0 else raw
        is_text = len(chunk) >= MIN_TEXT and all(32 <= byte < 127 for byte in chunk)
        return chunk.decode("ascii") if is_text else None


def address_of(image: Image, word: str) -> list[int]:
    """Địa chỉ ảo tương đối mà một đối số dòng lệnh chỉ tới: số hex, hay "=chuỗi"."""
    if not word.startswith("="):
        return [int(word, 16) - image.base]
    needle = b"\0" + word[1:].encode("ascii") + b"\0"
    spots = []
    at = image.data.find(needle)
    while at >= 0:
        rva = image.rva_of(at + 1)
        spots.extend([] if rva is None else [rva])
        at = image.data.find(needle, at + 1)
    return spots


def candidates_of(image: Image, target: int) -> list[int]:
    """Địa chỉ ảo tương đối của mọi độ dời 32 bit trong .text có thể trỏ theo RIP tới target."""
    base, code = image.code()
    raw = numpy.frombuffer(code, dtype=numpy.uint8).astype(numpy.int64)
    low = raw[:-3] | (raw[1:-2] << 8) | (raw[2:-1] << 16) | (raw[3:] << 24)
    signed = numpy.where(low >= 2**31, low - 2**32, low)
    spots = numpy.arange(len(signed), dtype=numpy.int64) + base + 4
    found: set[int] = set()
    for tail in TAILS:
        hits = numpy.nonzero(spots + tail + signed == target)[0]
        found.update(int(hit) + base for hit in hits)
    return sorted(found)


def engine_of() -> capstone.Cs:
    engine = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_64)
    engine.detail = True
    return engine


def instructions_of(image: Image, owner: tuple[int, int]) -> Iterator[capstone.CsInsn]:
    begin, end = owner
    return engine_of().disasm(image.bytes_at(begin, end - begin), image.base + begin)


def refs_to(image: Image, target: int) -> list[int]:
    """Địa chỉ ảo tương đối của mọi lệnh trỏ theo RIP tới target; chỗ ngoài .pdata giữ nguyên."""
    owners: set[tuple[int, int]] = set()
    loose = []
    for spot in candidates_of(image, target):
        owner = image.function_of(spot)
        if owner is None:
            loose.append(spot)
        else:
            owners.add(owner)
    found = set(loose)
    for owner in owners:
        for instruction in instructions_of(image, owner):
            if rip_target(instruction) == image.base + target:
                found.add(instruction.address - image.base)
    return sorted(found)


def describe(image: Image, rva: int) -> str:
    owner = image.function_of(rva)
    if owner is None:
        return f"{image.base + rva:#x} (ngoài mọi hàm, chưa kiểm)"
    return f"{image.base + rva:#x} trong hàm {image.base + owner[0]:#x}..{image.base + owner[1]:#x}"


def note_of(image: Image, instruction: capstone.CsInsn, target: int) -> str:
    """Chú thích cho một lệnh trỏ tới target: tên import, chuỗi, hay hằng số thực."""
    if target in image.imports:
        return image.imports[target]
    text = image.text_at(target)
    if text is not None:
        return f'"{text}"'
    if instruction.mnemonic in FLOAT_OPS:
        raw = image.bytes_at(target, 4)
        return f"float {struct.unpack('<f', raw)[0]:.9g}" if len(raw) == 4 else ""
    if instruction.mnemonic in DOUBLE_OPS:
        raw = image.bytes_at(target, 8)
        return f"double {struct.unpack('<d', raw)[0]:.17g}" if len(raw) == 8 else ""
    return image.section_of(target)


def rip_target(instruction: capstone.CsInsn) -> int | None:
    for operand in instruction.operands:
        is_memory = operand.type == capstone.x86.X86_OP_MEM
        if is_memory and operand.mem.base == capstone.x86.X86_REG_RIP:
            return instruction.address + instruction.size + operand.mem.disp
    return None


def branch_target(instruction: capstone.CsInsn) -> int | None:
    is_branch = instruction.mnemonic == "call" or instruction.mnemonic.startswith("j")
    if not is_branch or not instruction.operands:
        return None
    operand = instruction.operands[0]
    return operand.imm if operand.type == capstone.x86.X86_OP_IMM else None


def leaf_end(image: Image, rva: int) -> int:
    """Hết hàm lá bắt đầu ở rva: sau lệnh ret hay jmp đứng trước byte đệm int3, hay ở hàm kế."""
    starts = image.functions[:, 0]
    index = int(numpy.searchsorted(starts, rva, side="right"))
    limit = int(starts[index]) if index < len(starts) else rva + LEAF_LIMIT
    limit = min(limit, rva + LEAF_LIMIT)
    for instruction in instructions_of(image, (rva, limit)):
        after = instruction.address + instruction.size - image.base
        is_exit = instruction.mnemonic in ("ret", "jmp")
        if is_exit and image.bytes_at(after, 1) in (bytes([INT3]), b""):
            return after
    return limit


def dump_function(image: Image, rva: int, stop: int | None = None) -> None:
    owner = (rva, stop) if stop is not None else image.function_of(rva)
    kind = "hàm"
    if owner is None:
        owner = (rva, leaf_end(image, rva))
        kind = "hàm lá (không có trong .pdata)"
    begin, end = owner
    print(f"; {kind} {image.base + begin:#x}..{image.base + end:#x} ({end - begin} byte)")
    for instruction in instructions_of(image, owner):
        target = rip_target(instruction)
        jump = branch_target(instruction)
        note = ""
        if target is not None:
            note = f"  ; {target:#x} {note_of(image, instruction, target - image.base)}"
        elif jump is not None and instruction.mnemonic == "call":
            note = f"  ; gọi {jump:#x}"
        print(f"{instruction.address:#x}: {instruction.mnemonic} {instruction.op_str}{note}")


def show_text(image: Image, part: str) -> None:
    needle = part.encode("ascii")
    at = image.data.find(needle)
    seen = 0
    while at >= 0 and seen < TEXT_LIMIT:
        start = image.data.rfind(b"\0", 0, at) + 1
        rva = image.rva_of(start)
        text = None if rva is None else image.text_at(rva)
        if text is not None:
            print(f"{image.base + rva:#x} {image.section_of(rva)} {text}")
            seen += 1
        at = image.data.find(needle, max(at + 1, start + len(text or b"") + 1))


def show_refs(image: Image, word: str) -> None:
    for target in address_of(image, word):
        spots = refs_to(image, target)
        print(f"đích {image.base + target:#x}: {len(spots)} chỗ trỏ tới")
        for spot in spots:
            print("  " + describe(image, spot))


def show_calls(image: Image, word: str) -> None:
    target = int(word, 16) - image.base
    base, code = image.code()
    for spot in candidates_of(image, target):
        opcode = code[spot - base - 1]
        if opcode in (0xE8, 0xE9):
            kind = "call" if opcode == 0xE8 else "jmp"
            print(f"{kind} từ " + describe(image, spot - 1))


def show_rtti(image: Image, name: str) -> None:
    decorated = f".?AV{name}@@"
    for spot in address_of(image, "=" + decorated):
        descriptor = spot - 16
        for locator in locators_of(image, descriptor):
            show_vtable(image, name, locator)


def locators_of(image: Image, descriptor: int) -> list[int]:
    """RTTICompleteObjectLocator (chữ ký 1) trỏ tới bộ mô tả kiểu ở descriptor."""
    needle = struct.pack("<I", descriptor)
    found = []
    at = image.data.find(needle)
    while at >= 0:
        rva = image.rva_of(at - 12)
        head = image.data[at - 12:at + 12]
        is_locator = rva is not None and len(head) == 24 and struct.unpack_from("<I", head, 0)[0] == 1
        if is_locator and struct.unpack_from("<I", head, 20)[0] == rva:
            found.append(rva)
        at = image.data.find(needle, at + 1)
    return found


def show_vtable(image: Image, name: str, locator: int) -> None:
    needle = struct.pack("<Q", image.base + locator)
    at = image.data.find(needle)
    while at >= 0:
        table = image.rva_of(at + 8)
        if table is not None:
            print(f"vtable của {name} ở {image.base + table:#x}")
            show_slots(image, table)
        at = image.data.find(needle, at + 1)


def show_slots(image: Image, table: int) -> None:
    for index in range(VTABLE_LIMIT):
        raw = image.bytes_at(table + index * 8, 8)
        value = struct.unpack("<Q", raw)[0] if len(raw) == 8 else 0
        if image.section_of(value - image.base) != ".text":
            return
        print(f"  [{index:3d}] +{index * 8:#06x} {value:#x}")


def show_floats(image: Image, word: str) -> None:
    value = float(word)
    shown = 0
    for size, code in ((4, "<f"), (8, "<d")):
        needle = struct.pack(code, value)
        at = image.data.find(needle)
        while at >= 0:
            rva = image.rva_of(at)
            aligned = rva is not None and rva % size == 0 and image.section_of(rva) != ".text"
            spots = refs_to(image, rva) if aligned else []
            for spot in spots:
                print(f"{'float' if size == 4 else 'double'} ở {image.base + rva:#x}: "
                      + describe(image, spot))
            shown += len(spots)
            at = image.data.find(needle, at + 1)
    if shown == 0:
        print(f"không có lệnh nào đọc một hằng float hay double bằng {value!r}")


def show_imports(image: Image, name: str) -> None:
    slots = [slot for slot, label in image.imports.items() if label.endswith("!" + name)]
    if not slots:
        print(f"tệp không import hàm nào tên {name}")
    for slot in slots:
        owners: dict[int, list[int]] = {}
        for spot in refs_to(image, slot):
            owner = image.function_of(spot)
            owners.setdefault(owner[0] if owner else spot, []).append(spot)
        for begin, spots in sorted(owners.items()):
            places = " ".join(f"{image.base + spot:#x}" for spot in spots)
            print(f"{image.imports[slot]}: hàm {image.base + begin:#x}: {places}")


def export_rows(image: Image) -> Iterator[tuple[str, int]]:
    """Từng cặp (tên, rva) của bảng export, theo thứ tự bảng tên; rỗng khi tệp không export gì."""
    rva, size = image.directory(0)
    at = image.offset_of(rva) if size else None
    if at is None:
        return
    name_count, functions, names, ordinals = struct.unpack_from("<IIII", image.data, at + 24)
    for index in range(name_count):
        name_rva = struct.unpack("<I", image.bytes_at(names + index * 4, 4))[0]
        raw = image.bytes_at(name_rva, EXPORT_NAME_LIMIT)
        ordinal = struct.unpack("<H", image.bytes_at(ordinals + index * 2, 2))[0]
        target = struct.unpack("<I", image.bytes_at(functions + ordinal * 4, 4))[0]
        yield raw.split(b"\0", 1)[0].decode("ascii", errors="replace"), target


def show_exports(image: Image, part: str) -> None:
    rows = sorted((target, name) for name, target in export_rows(image) if part in name)
    if not rows:
        print(f"tệp không export tên nào chứa {part}")
    for target, name in rows:
        print(f"{image.base + target:#x} {image.section_of(target)} {name}")


def range_of(image: Image, word: str) -> tuple[int, int]:
    first, _, last = word.partition("..")
    return int(first, 16) - image.base, int(last, 16) - image.base


def owners_in(image: Image, span: tuple[int, int]) -> list[tuple[int, int]]:
    """Các dòng .pdata bắt đầu trong khoảng [đầu, cuối)."""
    rows = image.functions
    keep = (rows[:, 0] >= span[0]) & (rows[:, 0] < span[1])
    return [(int(begin), int(end)) for begin, end, _ in rows[keep]]


def show_matching(image: Image, span: tuple[int, int], matches: Callable[[capstone.CsInsn], bool]) -> None:
    shown = 0
    for owner in owners_in(image, span):
        for instruction in instructions_of(image, owner):
            if matches(instruction):
                print(f"hàm {image.base + owner[0]:#x}: {instruction.address:#x}: "
                      f"{instruction.mnemonic} {instruction.op_str}")
                shown += 1
    if shown == 0:
        print("không có lệnh nào khớp trong khoảng")


def show_uses(image: Image, word: str) -> None:
    offset, _, span = word.partition(":")
    wanted = int(offset, 16)

    def matches(instruction: capstone.CsInsn) -> bool:
        return any(operand.type == capstone.x86.X86_OP_MEM and operand.mem.disp == wanted
                   and operand.mem.base not in (0, capstone.x86.X86_REG_RIP,
                                                capstone.x86.X86_REG_RSP, capstone.x86.X86_REG_RBP)
                   for operand in instruction.operands)

    show_matching(image, range_of(image, span), matches)


def show_imm(image: Image, word: str) -> None:
    constant, _, span = word.partition(":")
    wanted = int(constant, 16)

    def matches(instruction: capstone.CsInsn) -> bool:
        return any(operand.type == capstone.x86.X86_OP_IMM and operand.imm == wanted
                   for operand in instruction.operands) and branch_target(instruction) is None

    show_matching(image, range_of(image, span), matches)


def show_vcalls(image: Image, word: str) -> None:
    holder_word, _, offset_word = word.partition(":")
    holder = int(holder_word, 16)
    offset = int(offset_word, 16)
    base, code = image.code()
    needle = struct.pack("<I", offset)
    owners: set[tuple[int, int]] = set()
    at = code.find(needle)
    while at >= 0:
        owner = image.function_of(base + at)
        owners.update([] if owner is None else [owner])
        at = code.find(needle, at + 1)
    shown = 0
    for owner in sorted(owners):
        loads = False
        calls = []
        for instruction in instructions_of(image, owner):
            loads = loads or rip_target(instruction) == holder
            is_call = instruction.mnemonic in ("call", "jmp")
            memory = [operand for operand in instruction.operands
                      if operand.type == capstone.x86.X86_OP_MEM]
            if is_call and memory and memory[0].mem.disp == offset and memory[0].mem.base != 0:
                calls.append(instruction.address)
        if loads and calls:
            print(f"hàm {image.base + owner[0]:#x}: " + " ".join(f"{call:#x}" for call in calls))
            shown += 1
    if shown == 0:
        print("không có hàm nào vừa nạp biến đó vừa gọi hàm ảo ở độ dời đó")


def show_jump(image: Image, word: str) -> None:
    parts = word.split(":")
    table, count = int(parts[0], 16), int(parts[1])
    targets = struct.unpack(f"<{count}I", image.bytes_at(table, 4 * count))
    if len(parts) == 2:
        for index, target in enumerate(targets):
            print(f"{index}: {image.base + target:#x}")
        return
    indices = image.bytes_at(int(parts[2], 16), int(parts[3]))
    first = int(parts[4])
    for value, slot in enumerate(indices):
        print(f"{value + first}: ô {slot} -> {image.base + targets[slot]:#x}")


ACTIONS = {"text": show_text, "refs": show_refs, "calls": show_calls, "rtti": show_rtti,
           "floats": show_floats, "imports": show_imports, "exports": show_exports, "uses": show_uses,
           "imm": show_imm,
           "vcalls": show_vcalls, "jump": show_jump}


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Soi một tệp PE x64 của client 2026")
    parser.add_argument("pe", help="Game.exe, Render.dll...")
    parser.add_argument("action", choices=[*ACTIONS, "func"])
    parser.add_argument("what", help="chuỗi con, địa chỉ hex, =chuỗi, tên lớp, số thực, hay bộ số")
    chosen = parser.parse_args()
    image = Image(pathlib.Path(chosen.pe))
    if chosen.action == "func":
        first, _, last = chosen.what.partition("..")
        stop = int(last, 16) - image.base if last else None
        dump_function(image, int(first, 16) - image.base, stop)
        return 0
    ACTIONS[chosen.action](image, chosen.what)
    return 0


if __name__ == "__main__":
    sys.exit(main())
