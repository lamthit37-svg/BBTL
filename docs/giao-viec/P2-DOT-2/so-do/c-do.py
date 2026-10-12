"""Đo và đếm của vai C (P2 đợt 2). Chạy ở gốc worktree: python -B docs/giao-viec/P2-DOT-2/so-do/c-do.py.

Ghi c-t3.log, c-t4.log, c-t8-mau.log, c-dem-tin.log, c-d4-gen.log, c-d6-dong.log vào cùng thư mục.
Chỉ đọc G:\\TLBB\\Dev; mọi thứ sinh ra khi đo nằm dưới build/p2-c.
"""

from __future__ import annotations

import datetime
import hashlib
import re
import shutil
import statistics
import subprocess
import sys
import time
import tracemalloc
import unittest
from pathlib import Path

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent
WORK = ROOT / "build" / "p2-c" / "do"
DEV = Path(r"G:\TLBB\Dev\src\protocol\protocol.hpp")
GEN = ROOT / "TOOLS" / "server" / "gen_protocol.py"
GENERATED = ("SRC/protocol/messages.hpp", "SRC/protocol/messages.cpp", "tests/protocol_samples.hpp",
             "docs/PROTOCOL-TIN.md")
sys.path.insert(0, str(ROOT / "TOOLS" / "server"))

import gen_protocol  # noqa: E402
from protocol_model import body_max_bytes  # noqa: E402


def stamp() -> str:
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def head() -> list[str]:
    commit = subprocess.run(["git", "-c", "safe.directory=*", "rev-parse", "HEAD"], capture_output=True,
                            text=True, check=False).stdout.strip()
    free = shutil.disk_usage(ROOT).free
    return [f"# lệnh: python -B docs/giao-viec/P2-DOT-2/so-do/c-do.py (cwd {ROOT})", f"# giờ: {stamp()}",
            f"# commit: {commit}", f"# ổ F còn trống: {free} byte ({free / 2**30:.2f} GiB)",
            f"# python: {sys.version.split()[0]}", ""]


def write(name: str, lines: list[str]) -> None:
    (OUT / name).write_text("\n".join([*head(), *lines, f"# xong: {stamp()}", ""]), encoding="utf-8")
    print(f"đã ghi so-do/{name}")


def run(args: list[str]) -> tuple[int, str]:
    done = subprocess.run([sys.executable, "-B", *args], capture_output=True, text=True, encoding="utf-8",
                          check=False)
    return done.returncode, (done.stdout + done.stderr).rstrip()


def digests(tree: Path) -> dict[str, str]:
    return {name: hashlib.sha256((tree / name).read_bytes()).hexdigest() for name in GENERATED}


def t3() -> None:
    lines = ["## T3", "", "$ python -B TOOLS/server/gen_protocol.py --check"]
    code, text = run([str(GEN), "--check"])
    lines += [text, f"mã thoát: {code}", ""]
    trees = [WORK / "t3-a", WORK / "t3-b"]
    for tree in trees:
        shutil.rmtree(tree, ignore_errors=True)
        rel = tree.relative_to(ROOT).as_posix()
        code, text = run([str(GEN), "--out", str(tree)])
        lines += [f"$ python -B TOOLS/server/gen_protocol.py --out {rel}", text, f"mã thoát: {code}", ""]
    first, second, repo = digests(trees[0]), digests(trees[1]), digests(ROOT)
    lines += ["tệp\tSHA-256 t3-a\tSHA-256 t3-b\ttrùng a-b\ttrùng tệp trong cây"]
    same = 0
    for name in GENERATED:
        both = first[name] == second[name]
        same += both and first[name] == repo[name]
        lines.append(f"{name}\t{first[name]}\t{second[name]}\t{both}\t{first[name] == repo[name]}")
    lines += ["", f"trùng cả ba: {same}/{len(GENERATED)}", ""]
    write("c-t3.log", lines)


def t4() -> None:
    copy = WORK / "t4-catalog"
    shutil.rmtree(copy, ignore_errors=True)
    shutil.copytree(ROOT / "SRC" / "protocol" / "catalog", copy)
    path = copy / "fields.tsv"
    rows = path.read_text(encoding="utf-8").split("\n")
    index = next(i for i, row in enumerate(rows) if row.split("\t")[4:5] and row.split("\t")[4].isdigit())
    cells = rows[index].split("\t")
    before = cells[4]
    cells[4] = str(int(before) + 1)
    rows[index] = "\t".join(cells)
    path.write_bytes("\n".join(rows).encode("utf-8"))  # giữ LF như bảng gốc (G1)
    rel = copy.relative_to(ROOT).as_posix()
    code, text = run([str(GEN), "--catalog", str(copy), "--check"])
    write("c-t4.log", ["## T4", "", f"chép SRC/protocol/catalog sang {rel}",
                       f"sửa fields.tsv dòng {index + 1}, cột limit: {before} thành {cells[4]} "
                       f"(trường {cells[0]}.{cells[2]})", "",
                       f"$ python -B TOOLS/server/gen_protocol.py --catalog {rel} --check", text, f"mã thoát: {code}", ""])


FRAME = re.compile(r"inline constexpr std::array<std::uint8_t, (\d+)> k(\w+)Frame\{([^}]*)\}", re.S)


def t8() -> None:
    text = (ROOT / "tests" / "protocol_samples.hpp").read_text(encoding="utf-8")
    lines = ["## T8: số ca cắt và ca thêm byte", "", "mẫu\tbyte khung\tbyte thân\tthân khai ở đầu khung\tca cắt"]
    total = 0
    frames = FRAME.findall(text)
    for size, name, body in frames:
        data = [int(token, 16) for token in re.findall(r"0x[0-9A-Fa-f]{2}", body)]
        declared = int.from_bytes(bytes(data[:4]), "little")
        length = int(size) - 8
        assert len(data) == int(size) and declared == length, name
        total += length
        lines.append(f"{name}\t{size}\t{length}\t{declared}\t{length}")
    lines += ["", f"số mẫu: {len(frames)}", f"tổng ca cắt (mỗi mẫu cắt ở 0..thân-1 byte): {total}",
              f"tổng ca thêm một byte: {len(frames)}", f"tổng hai loại: {total + len(frames)}", ""]
    write("c-t8-mau.log", lines)


DEV_KIND = re.compile(r"^\s+(\w+) = 0x([08][125])\w\w,", re.M)
DEV_STRUCT = re.compile(r"^struct (\w+) \{\n(.*?)^\};", re.M | re.S)
DEV_ENUM = re.compile(r"^enum class (\w+) : [\w:]+ \{([^}]*)\};", re.M)
DEV_MEMBER = re.compile(r"^    ([\w:<>]+) \w+(?: = [^;]*|\{[^;]*\})?;$", re.M)


def dev_counts() -> list[str]:
    source = DEV.read_text(encoding="utf-8")
    kinds = DEV_KIND.findall(source)
    structs = {name: body for name, body in DEV_STRUCT.findall(source)}
    enums = {name for name, body in DEV_ENUM.findall(source) if body.strip()}
    messages = [name for name, _ in kinds]
    records: set[str] = set()
    used: set[str] = set()
    fields = 0
    pending = list(messages)
    while pending:
        name = pending.pop()
        body = structs[name]
        count = len(re.findall(r"io\.\w+\(self\.", body))
        fields += count
        for kind in DEV_MEMBER.findall(body):
            for word in re.findall(r"\w+", kind):
                if word in structs and word not in records and word not in messages:
                    records.add(word)
                    pending.append(word)
                if word in enums:
                    used.add(word)
    return ["### Dev: G:\\TLBB\\Dev\\src\\protocol\\protocol.hpp (chỉ đọc)",
            "cách đếm: tin là tên trong ClientKind/ServerKind có mã 0x01xx, 0x02xx, 0x05xx (cả 0x81, 0x82, 0x85);",
            "trường là số lời gọi io.<hàm>(self. trong struct; record là struct được tin dùng tới (đệ quy);",
            "enum là enum class có giá trị được dùng làm kiểu trường (không tính id rỗng kiểu EntityId).",
            f"tin: {len(messages)} ({', '.join(messages)})",
            f"trường của tin và record: {fields}", f"record: {len(records)} ({', '.join(sorted(records))})",
            f"enum: {len(used)} ({', '.join(sorted(used))})", ""]


def dem_tin() -> None:
    catalog = gen_protocol.load_catalog(ROOT / "SRC" / "protocol" / "catalog")
    owners = (*catalog.messages, *catalog.records)
    lines = ["## Số tin, trường, enum, record; cỡ thân lớn nhất", "", *dev_counts(),
             "### Bảng của ta: SRC/protocol/catalog (gen_protocol.load_catalog)",
             f"tin: {len(catalog.messages)}", f"trường của tin và record: {sum(len(o.fields) for o in owners)}",
             f"record: {len(catalog.records)} ({', '.join(r.name for r in catalog.records)})",
             f"enum: {len(catalog.enums)} ({', '.join(e.name for e in catalog.enums)})",
             f"tin client: {sum(not m.is_server for m in catalog.messages)}, "
             f"tin server: {sum(m.is_server for m in catalog.messages)}", "",
             "### Cỡ thân lớn nhất (protocol_model.body_max_bytes)", "kind\ttin\tcổng\ttrường\tthân tối đa (byte)"]
    for message in catalog.messages:
        lines.append(f"{message.kind_text()}\t{message.name}\t{message.port}\t{len(message.fields)}\t"
                     f"{body_max_bytes(catalog, message)}")
    lines += ["", "record\ttrường\tthân tối đa (byte)"]
    lines += [f"{r.name}\t{len(r.fields)}\t{body_max_bytes(catalog, r)}" for r in catalog.records]
    write("c-dem-tin.log", [*lines, ""])


def one_render() -> None:
    gen_protocol.render_all(gen_protocol.load_catalog(ROOT / "SRC" / "protocol" / "catalog"))


def summary(label: str, values: list[float], unit: str) -> list[str]:
    raw = ", ".join(f"{value:.6f}" for value in values)
    return [f"{label} ({unit}), 5 lượt: {raw}",
            f"  trung vị {statistics.median(values):.6f}, nhỏ nhất {min(values):.6f}, lớn nhất {max(values):.6f}"]


def d4() -> None:
    process, inner, peaks = [], [], []
    for _ in range(5):
        start = time.perf_counter()
        code, _text = run([str(GEN), "--check"])
        process.append(time.perf_counter() - start)
        assert code == 0
    for _ in range(5):
        start = time.perf_counter()
        one_render()
        inner.append(time.perf_counter() - start)
    for _ in range(5):
        tracemalloc.start()
        one_render()
        peaks.append(tracemalloc.get_traced_memory()[1] / 2**20)
        tracemalloc.stop()
    write("c-d4-gen.log", ["## Đ4: thời gian và đỉnh bộ nhớ của gen_protocol.py", "",
                           "A: cả tiến trình `python -B TOOLS/server/gen_protocol.py --check`, đo bằng time.perf_counter",
                           *summary("A", process, "giây"), "",
                           "B: trong tiến trình, load_catalog + render_all (4 tệp), time.perf_counter",
                           *summary("B", inner, "giây"), "",
                           "C: như B, đỉnh bộ nhớ Python theo tracemalloc (lượt riêng, không đo giờ)",
                           *summary("C", peaks, "MiB"), "",
                           "máy có bản dựng khác chạy cùng lúc hay không: không kiểm soát được (A, B và L dùng chung máy)", ""])


HAND = ("SRC/protocol/catalog/groups.tsv", "SRC/protocol/catalog/messages.tsv", "SRC/protocol/catalog/fields.tsv",
        "SRC/protocol/catalog/enums.tsv", "TOOLS/server/gen_protocol.py", "TOOLS/server/protocol_model.py",
        "TOOLS/server/protocol_tsv.py", "TOOLS/server/protocol_rules.py", "TOOLS/server/protocol_wire.py",
        "TOOLS/server/protocol_cxx.py", "TOOLS/server/protocol_cpp_hpp.py", "TOOLS/server/protocol_cpp_src.py",
        "TOOLS/server/protocol_samples.py", "TOOLS/server/protocol_doc.py", "TOOLS/server/test_gen_protocol.py",
        "tests/protocol_catalog_tests.cpp")


def line_count(name: str) -> int:
    return len((ROOT / name).read_text(encoding="utf-8").splitlines())


def d6() -> None:
    lines = ["## Đ6: số dòng (splitlines, như wc -l khi tệp kết thúc bằng xuống dòng)", "", "### viết tay"]
    lines += [f"{line_count(name)}\t{name}" for name in HAND]
    lines += ["", "### sinh"] + [f"{line_count(name)}\t{name}" for name in GENERATED]
    suite = unittest.defaultTestLoader.loadTestsFromName("test_gen_protocol")
    cases = len(re.findall(r"game::test::Case\{", (ROOT / "tests" / "protocol_catalog_tests.cpp").read_text(encoding="utf-8")))
    samples = len(FRAME.findall((ROOT / "tests" / "protocol_samples.hpp").read_text(encoding="utf-8")))
    lines += ["", "### ca test", f"TOOLS/server/test_gen_protocol.py: {suite.countTestCases()} test (unittest loader)",
              f"tests/protocol_catalog_tests.cpp: {cases} ca (đếm game::test::Case{{)",
              f"tests/protocol_samples.hpp: {samples} mẫu", ""]
    write("c-d6-dong.log", lines)


def main() -> int:
    WORK.mkdir(parents=True, exist_ok=True)
    for step in (t3, t4, t8, dem_tin, d4, d6):
        step()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
