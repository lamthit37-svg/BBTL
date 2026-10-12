# Chép MỘT tệp từ Forge2 (chỉ đọc) sang THIENLONG và đo phải sửa bao nhiêu dòng mới qua cổng.
# Chạy ở gốc dự án:
#   python TOOLS/port/forge2_port.py copy <nguồn trong Forge2> <đích trong dự án>
#   python TOOLS/port/forge2_port.py measure [<đích>...]      không nêu đích: mọi tệp đã chép
#   python TOOLS/port/forge2_port.py apply <đích>...          áp lại tiền tố k cho enum ghi nhớ sau
#   python TOOLS/port/forge2_port.py includes <đích>...       include mà clang-tidy muốn thêm, bỏ
# copy: đổi namespace forge2 thành game, thêm tiền tố k cho enumerator của mọi enum class đã gặp
# (ghi nhớ ở enums.json), ghi cặp đích/nguồn vào copied.tsv; không ghi đè tệp đã có.
# measure: so tệp đích với hai bản dựng lại từ nguồn — bản chỉ đổi namespace ("tổng đổi") và bản đã
# thêm tiền tố k rồi qua clang-format của dự án ("sửa tay", tức phần không phải đổi cơ học).
# includes: chạy misc-include-cleaner có --fix trên một bản chép tạm rồi in khác biệt; không sửa tệp.
# Thư mục Forge2 lấy từ biến môi trường FORGE2_ROOT, mặc định D:/The-Forge/Forge2.
import contextlib
import difflib
import json
import os
import pathlib
import re
import shlex
import subprocess
import sys
import tempfile
import time

HERE = pathlib.Path(__file__).resolve().parent
PROJECT = HERE.parent.parent
FORGE2 = pathlib.Path(os.environ.get("FORGE2_ROOT", "D:/The-Forge/Forge2"))
ENUMS = HERE / "enums.json"
COPIED = HERE / "copied.tsv"
LOCK = HERE / "records.lock"
ENUM_BLOCK = re.compile(r"enum class (\w+)\b[^{;]*\{(.*?)\}", re.S)
ENUMERATOR = re.compile(r"(?:^|,|\{)\s*([A-Z][A-Za-z0-9]*)\s*(?==|,|$)", re.M)


def load_enums() -> dict[str, list[str]]:
    if not ENUMS.exists():
        return {}
    return json.loads(ENUMS.read_text(encoding="utf-8"))


def load_copied() -> dict[str, str]:
    if not COPIED.exists():
        return {}
    rows = [line.split("\t") for line in COPIED.read_text(encoding="utf-8").splitlines() if line]
    return {target: source for target, source in rows}


# Khoá giữa các tiến trình cho hai tệp ghi nhớ: nhiều phiên chép song song cùng đọc, sửa rồi ghi
# enums.json và copied.tsv, thiếu khoá thì phiên ghi sau xoá mất mục của phiên ghi trước.
@contextlib.contextmanager
def records_locked():
    for _ in range(600):
        try:
            handle = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            break
        except FileExistsError:
            time.sleep(0.1)
    else:
        raise SystemExit(f"không lấy được khoá {LOCK} sau 60 giây; xoá tệp này nếu nó bị bỏ lại")
    try:
        yield
    finally:
        os.close(handle)
        LOCK.unlink()


def remember_enum(kind: str, names: list[str]) -> None:
    with records_locked():
        enums = load_enums()
        enums[kind] = sorted(set(enums.get(kind, [])) | set(names))
        text = json.dumps(enums, indent=1, sort_keys=True) + "\n"
        ENUMS.write_text(text, encoding="utf-8", newline="\n")


def remember_copy(target: str, source: str) -> None:
    with records_locked():
        copied = load_copied()
        copied[target] = source
        text = "".join(f"{key}\t{value}\n" for key, value in sorted(copied.items()))
        COPIED.write_text(text, encoding="utf-8", newline="\n")


def scan_enums(text: str) -> None:
    for kind, body in ENUM_BLOCK.findall(text):
        code = "\n".join(line.split("//")[0] for line in body.split("\n"))
        names = [name for name in ENUMERATOR.findall(code) if not re.match(r"k[A-Z]", name)]
        if names:
            remember_enum(kind, names)


def renamed_namespace(text: str) -> str:
    return text.replace("forge2::", "game::").replace("namespace forge2", "namespace game")


def prefix_line(line: str, word: re.Pattern[str]) -> str:
    cut = line.find("//")
    code, note = (line, "") if cut < 0 else (line[:cut], line[cut:])
    return word.sub(lambda match: "k" + match.group(1), code) + note


def prefix_definition(text: str, kind: str, word: re.Pattern[str]) -> str:
    block = re.compile(r"(enum class " + re.escape(kind) + r"\b[^{;]*\{)(.*?)(\})", re.S)

    def fix(match: re.Match[str]) -> str:
        lines = [prefix_line(line, word) for line in match.group(2).split("\n")]
        return match.group(1) + "\n".join(lines) + match.group(3)

    return block.sub(fix, text)


def prefix_enums(text: str) -> str:
    for kind, names in load_enums().items():
        choice = "|".join(map(re.escape, sorted(names, key=len, reverse=True)))
        text = prefix_definition(text, kind, re.compile(r"\b(" + choice + r")\b"))
        use = re.compile(r"\b(" + re.escape(kind) + r"::)(" + choice + r")\b")
        text = use.sub(lambda match: match.group(1) + "k" + match.group(2), text)
    return text


def formatted(text: str, target: str) -> str:
    style = "--style=file:" + str(PROJECT / ".clang-format")
    command = ["clang-format", style, "--assume-filename=" + target]
    done = subprocess.run(command, input=text, capture_output=True, text=True, encoding="utf-8",
                          check=True)
    return done.stdout


def copy(source: str, target: str) -> int:
    destination = PROJECT / target
    if destination.exists():
        print(f"ĐÃ CÓ, không ghi đè: {target}")
        return 1
    plain = renamed_namespace((FORGE2 / source).read_text(encoding="utf-8"))
    scan_enums(plain)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(prefix_enums(plain), encoding="utf-8", newline="\n")
    remember_copy(target, source)
    print(f"{source} -> {target}: {len(plain.splitlines())} dòng")
    return 0


# Áp lại tiền tố k lên tệp đích: dùng khi một enum được ghi nhớ SAU lúc tệp này đã chép (enum khai
# ở tệp chép sau). Chạy nhiều lần cho cùng kết quả.
def apply(target: str) -> None:
    path = PROJECT / target
    path.write_text(prefix_enums(path.read_text(encoding="utf-8")), encoding="utf-8", newline="\n")
    print(f"đã áp tiền tố k: {target}")


def touched(before: list[str], after: list[str]) -> int:
    matcher = difflib.SequenceMatcher(a=before, b=after, autojunk=False)
    changed = ("replace", "delete")
    return sum(high - low for tag, low, high, _, _ in matcher.get_opcodes() if tag in changed)


def measure(target: str, source: str) -> tuple[int, int]:
    plain = renamed_namespace((FORGE2 / source).read_text(encoding="utf-8"))
    mechanical = formatted(prefix_enums(plain), target).splitlines()
    after = (PROJECT / target).read_text(encoding="utf-8").splitlines()
    before = plain.splitlines()
    total = touched(before, after)
    manual = touched(mechanical, after)
    size = max(len(before), 1)
    print(f"{target}: gốc {len(before)} dòng | tổng đổi {total} ({100.0 * total / size:.1f}%) | "
          f"sửa tay {manual} ({100.0 * manual / size:.1f}%) | bản đích {len(after)} dòng")
    return len(before), len(after)


def measure_all(targets: list[str]) -> int:
    copied = load_copied()
    chosen = targets or sorted(copied)
    missing = [target for target in chosen if target not in copied]
    if missing:
        print("không có trong copied.tsv: " + ", ".join(missing))
        return 1
    sizes = [measure(target, copied[target]) for target in chosen]
    origin = sum(before for before, _ in sizes)
    result = sum(after for _, after in sizes)
    print(f"{len(sizes)} tệp: {origin} dòng gốc, {result} dòng bản đích")
    return 0


def includes_of(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.lstrip().startswith("#include")]


def probe_includes(target: str, work: pathlib.Path) -> None:
    before = (PROJECT / target).read_text(encoding="utf-8")
    probe = work / target
    probe.parent.mkdir(parents=True, exist_ok=True)
    probe.write_text(before, encoding="utf-8", newline="\n")
    # CPP23_TIDY_ARGS: cùng biến mà check.py đọc, để thêm thư mục include của thư viện ngoài
    # (ví dụ -isystem của Vulkan SDK).
    extra = shlex.split(os.environ.get("CPP23_TIDY_ARGS", ""))
    command = ["clang-tidy", f"--config-file={PROJECT / '.clang-tidy'}",
               "--checks=-*,misc-include-cleaner", "--fix", "--quiet", str(probe), "--",
               "-std=c++23", f"-I{PROJECT / 'SRC'}", f"-I{PROJECT / 'tests'}", *extra]
    subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace",
                   check=False)
    old, new = includes_of(before), includes_of(probe.read_text(encoding="utf-8"))
    print(f"{target}:")
    for line in [line for line in new if line not in old]:
        print(f"  thêm {line}")
    for line in [line for line in old if line not in new]:
        print(f"  bỏ   {line}")


def main() -> int:
    arguments = sys.argv[1:]
    if len(arguments) == 3 and arguments[0] == "copy":
        return copy(arguments[1], arguments[2])
    if arguments and arguments[0] == "measure":
        return measure_all(arguments[1:])
    if len(arguments) >= 2 and arguments[0] == "apply":
        for target in arguments[1:]:
            apply(target)
        return 0
    if len(arguments) >= 2 and arguments[0] == "includes":
        with tempfile.TemporaryDirectory(dir=PROJECT / "build") as work:
            for target in arguments[1:]:
                probe_includes(target, pathlib.Path(work))
        return 0
    print("forge2_port.py copy <nguồn> <đích> | measure [<đích>...] | apply <đích>... | "
          "includes <đích>...")
    return 2


if __name__ == "__main__":
    sys.exit(main())
