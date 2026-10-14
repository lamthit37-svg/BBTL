# Trọng tài cho các bảng giao diện port từ script Lua: chạy CHÍNH script gốc của client 2026 trên
# chính LuaPlus.dll của nó (Lua 5.0.1 có thêm `continue`), với cửa sổ và hàm của game là đồ giả, rồi
# ghi trạng thái cửa sổ mà script để lại thành tệp số vàng. Bản port ở SRC/ui/panel phải ghi ra
# đúng những dòng đó cho cùng kịch bản (test C++ so từng byte).
# Script gốc là nguồn sự thật cho phần logic viết bằng Lua; phần C++ mà script gọi (DataPool,
# Player, EnumAction...) do kịch bản định nghĩa theo điều đã đọc từ mã máy
# (docs/NHIEM-VU-VO-CONG-2026.md). Cần Python 64 bit trên Windows và thư mục Bin64 của client.
# Chạy ở gốc dự án:
#   python -B TOOLS/port/lua_oracle.py <Bin64> <script.lua> <layout.xml> <kịch bản.lua> <tệp ra.tsv>
#       [--name TÊN] [--words bảng.tsv] [--lib hàm.lua]... [--table tên=bảng.tsv]...
# - --name: tên cửa sổ mà client gốc đăng ký cho script, tức tiền tố của ba hàm <tên>_PreLoad,
#   <tên>_OnLoad, <tên>_OnEvent, khi nó khác tên tệp (CreateRole.lua dùng LoginCreateRole).
# - script.lua là bản đã giải bằng TOOLS/content/lua_plain.py (giải đủ cả 24 byte đầu từ 2026-10-15;
#   trước đó phải đưa phần đầu đoán được qua cờ --head, nay đã gỡ).
# - layout.xml là bản UTF-8 đã gom (CLIENT/data/Interface/<Tên>/<Tên>.layout.xml): mỗi <Window>
#   thành một biến toàn cục mang các thuộc tính của nó. Thư mục Schema cạnh thư mục của layout (hay
#   --schema) cho biết kiểu cửa sổ nào là nút đánh dấu và CheckMode mặc định của nó, để trọng tài
#   làm đúng luật "bật một nút CheckMode 1 thì tắt các nút đánh dấu cùng cha" của CEGUI.
# - kịch bản.lua có hai phần ngăn bằng một dòng `--@steps`: phần đầu chạy trước script (định nghĩa
#   hàm của game), phần sau chạy sau <Tên>_PreLoad và <Tên>_OnLoad: bắn sự kiện của game bằng
#   __event(tên, arg0...), bấm nút bằng __fire(cửa sổ[, sự kiện]) (chạy đúng đoạn Lua mà layout
#   nối vào sự kiện đó), bấm nút đánh dấu bằng __check, chọn mục danh sách bằng __pick(cửa sổ, id),
#   ghi trạng thái bằng __dump("nhãn").
# - --lib: tệp Lua nạp trước kịch bản (hàm của game dùng chung cho nhiều kịch bản, như
#   TOOLS/port/oracle/quest_api.lua); nêu nhiều lần được.
# - --table: một bảng TSV của CLIENT/data/Table (dòng # là chú thích, dòng kế là tên cột) thành
#   biến __tables[tên]: dãy các dòng, mỗi dòng là một bảng Lua từ tên cột sang chữ của ô. Hàm của
#   game trong --lib đọc dữ liệu thật ở đó thay vì chép số vào kịch bản; nêu nhiều lần được.
# - --words: bảng hai cột (nguyên văn, bản dịch): mọi chuỗi trong nháy kép của script trùng nguyên
#   văn được thay bằng bản dịch trước khi chạy, để số vàng mang đúng chữ tiếng Việt mà bản port viết.
# Tệp ra: mỗi lượt __dump một khối, dòng đầu "# nhãn", rồi "cửa sổ<tab>thuộc tính<tab>giá trị"
# cho mọi thứ script đã đụng tới kể từ lúc nạp, rồi "!callN<tab>..." cho các việc script nhờ game
# làm kể từ lượt ghi trước.
# Mã thoát: 0 khi ghi xong, 1 khi script hay kịch bản báo lỗi, 2 khi đối số sai hay không nạp được
# thư viện.
import argparse
import ctypes
import os
import pathlib
import re
import sys
import xml.etree.ElementTree as ElementTree

STEPS_MARK = "--@steps"
# lua.h của Lua 5.0: chỉ số giả của bảng toàn cục.
LUA_GLOBALSINDEX = -10001
# Trong bảng --words, ký tự này là một dấu cách (để dấu cách đầu, cuối không bị trình soạn cắt).
SPACE_MARK = "␣"
PRELUDE = pathlib.Path(__file__).with_name("lua_oracle.lua")
# Kiểu widget của nút đánh dấu TLBB (lớp FalagardCheckButton của CEGUIFalagard.dll).
CHECK_TARGET = "Falagard/CheckBox"
LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"')


class OracleError(Exception):
    """Script, kịch bản hay layout không chạy được; câu lỗi nêu chỗ hỏng."""


class Machine:
    """Một máy Lua của LuaPlus.dll; chuỗi vào và ra là UTF-8."""

    def __init__(self, bin_folder: pathlib.Path) -> None:
        os.add_dll_directory(str(bin_folder))
        self.dll = ctypes.CDLL(str(bin_folder / "LuaPlus.dll"))
        self.dll.lua_open.restype = ctypes.c_void_p
        self.dll.lua_tostring.restype = ctypes.c_char_p
        self.dll.lua_tostring.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.dll.luaL_loadbuffer.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p]
        self.dll.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
        self.dll.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.dll.lua_pushstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        self.dll.lua_settable.argtypes = [ctypes.c_void_p, ctypes.c_int]
        self.state = ctypes.c_void_p(self.dll.lua_open())
        for library in ("luaopen_base", "luaopen_string", "luaopen_table", "luaopen_math"):
            opener = getattr(self.dll, library)
            opener.argtypes = [ctypes.c_void_p]
            opener(self.state)
        self.dll.lua_settop(self.state, 0)
        self.lines: list[str] = []
        callback = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p)
        self.emit = callback(self._emit)
        self.dll.lua_pushcclosure.argtypes = [ctypes.c_void_p, callback, ctypes.c_int]
        self.dll.lua_pushstring(self.state, b"__emit")
        self.dll.lua_pushcclosure(self.state, self.emit, 0)
        self.dll.lua_settable(self.state, LUA_GLOBALSINDEX)

    def _emit(self, state: int) -> int:
        text = self.dll.lua_tostring(ctypes.c_void_p(state), 1)
        self.lines.append((text or b"").decode("utf-8"))
        return 0

    def run(self, code: str, name: str) -> None:
        """Chạy một đoạn Lua; lỗi cú pháp hay lỗi lúc chạy thành OracleError kèm tên đoạn."""
        data = code.encode("utf-8")
        failed = self.dll.luaL_loadbuffer(self.state, data, len(data), ("=" + name).encode("utf-8"))
        failed = failed or self.dll.lua_pcall(self.state, 0, 0, 0)
        if failed:
            message = (self.dll.lua_tostring(self.state, -1) or b"?").decode("utf-8", errors="replace")
            self.dll.lua_settop(self.state, 0)
            raise OracleError(message)


def lua_text(value: str) -> str:
    """Một chuỗi Lua trong nháy kép mang đúng các byte của value."""
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\r", "\\r").replace("\n", "\\n")
    return '"' + escaped + '"'


def parsed(path: pathlib.Path) -> ElementTree.Element:
    try:
        return ElementTree.parse(path).getroot()
    except (OSError, ElementTree.ParseError) as error:
        raise OracleError(f"{path}: không đọc được: {error}") from error


def check_modes(schema: pathlib.Path) -> dict[str, str]:
    """Kiểu cửa sổ là nút đánh dấu (scheme nối nó vào Falagard/CheckBox) sang CheckMode mặc định
    mà looknfeel của kiểu đó đặt ("0" khi looknfeel không nêu)."""
    looks: dict[str, str] = {}
    for file in sorted(schema.glob("*.looknfeel.xml")):
        for look in parsed(file).iter("WidgetLook"):
            for item in list(look.findall("Property")) + list(look.findall("PropertyDefinition")):
                if item.get("name") == "CheckMode":
                    looks[look.get("name", "")] = item.get("value") or item.get("initialValue") or "0"
    modes: dict[str, str] = {}
    schemes = sorted(schema.glob("*.scheme.xml"))
    if not schemes:
        raise OracleError(f"{schema}: không có tệp scheme nào để biết kiểu cửa sổ nào là nút đánh dấu")
    for file in schemes:
        for mapping in parsed(file).iter("FalagardMapping"):
            if mapping.get("TargetType") == CHECK_TARGET:
                modes[mapping.get("WindowType", "")] = looks.get(mapping.get("LookNFeel", ""), "0")
    return modes


def windows_of(layout: pathlib.Path, modes: dict[str, str]) -> list[dict]:
    """Mọi <Window> có tên của layout, theo thứ tự trong tệp: tên, thuộc tính, sự kiện nối script,
    tên cửa sổ cha và có phải nút đánh dấu không. Nút đánh dấu mà layout không nêu CheckMode nhận
    CheckMode mặc định của looknfeel."""
    found = []

    def walk(window: ElementTree.Element, parent: str) -> None:
        name = window.get("Name", "")
        if name:
            props = {item.get("Name", ""): item.get("Value", "") for item in window.findall("Property")}
            events = {item.get("Name", ""): item.get("Function", "") for item in window.findall("Event")}
            kind = window.get("Type", "")
            if kind in modes:
                props.setdefault("CheckMode", modes[kind])
            found.append({"name": name, "props": props, "events": events, "parent": parent, "check": kind in modes})
        for child in window.findall("Window"):
            walk(child, name or parent)

    for top in parsed(layout).findall("Window"):
        walk(top, "")
    return found


def lua_table(pairs: dict[str, str]) -> str:
    return "{" + ", ".join(f"[{lua_text(key)}] = {lua_text(value)}" for key, value in pairs.items()) + "}"


def window_code(windows: list[dict]) -> str:
    made = [
        f"__window({lua_text(item['name'])}, {lua_table(item['props'])}, {lua_table(item['events'])}, "
        f"{lua_text(item['parent'])}, {'true' if item['check'] else 'false'})"
        for item in windows
    ]
    return "\n".join(made)


def table_code(spec: str) -> str:
    """Đoạn Lua gán __tables[tên] từ một đối số --table dạng tên=đường dẫn."""
    name, equals, file = spec.partition("=")
    if not equals or not name or not file:
        raise OracleError(f"--table {spec}: cần dạng tên=bảng.tsv")
    try:
        text = pathlib.Path(file).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise OracleError(f"{file}: không đọc được bảng: {error}") from error
    lines = [line for line in text.split("\n") if line and not line.startswith("#")]
    if not lines:
        raise OracleError(f"{file}: bảng không có dòng tên cột")
    header = lines[0].split("\t")
    rows = []
    for number, line in enumerate(lines[1:], 1):
        cells = line.split("\t")
        if len(cells) != len(header):
            raise OracleError(f"{file}: dòng dữ liệu {number} có {len(cells)} ô, bảng có {len(header)} cột")
        rows.append(lua_table(dict(zip(header, cells))))
    return f"__tables[{lua_text(name)}] = {{\n" + ",\n".join(rows) + "\n}"


def read_words(path: pathlib.Path | None) -> dict[str, str]:
    """Bảng nguyên văn sang bản dịch; dòng # và dòng trống bỏ."""
    if path is None:
        return {}
    words = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").split("\n"), 1):
        if not line or line.startswith("#"):
            continue
        original, tab, translated = line.partition("\t")
        if not tab or "\t" in translated:
            raise OracleError(f"{path}: dòng {number}: cần nguyên văn, một dấu tab, bản dịch")
        words[original.replace(SPACE_MARK, " ")] = translated.replace(SPACE_MARK, " ")
    return words


def localized(script: str, words: dict[str, str]) -> str:
    """Thay chuỗi trong nháy kép trùng nguyên văn của words bằng bản dịch."""
    def swap(match: re.Match[str]) -> str:
        translated = words.get(match.group(1))
        return match.group(0) if translated is None else lua_text(translated)
    return LITERAL.sub(swap, script) if words else script


def script_code(path: pathlib.Path, words: dict[str, str]) -> str:
    return localized(path.read_text(encoding="utf-8"), words)


def run(args: argparse.Namespace) -> list[str]:
    machine = Machine(args.bin)
    scenario = args.scenario.read_text(encoding="utf-8")
    before, mark, after = scenario.partition(STEPS_MARK)
    if not mark:
        raise OracleError(f"{args.scenario}: thiếu dòng {STEPS_MARK}")
    name = args.name or args.script.stem
    machine.run(PRELUDE.read_text(encoding="utf-8"), PRELUDE.name)
    schema = args.schema if args.schema is not None else args.layout.parent.parent / "Schema"
    machine.run(window_code(windows_of(args.layout, check_modes(schema))), args.layout.name)
    for spec in args.table:
        machine.run(table_code(spec), "--table " + spec)
    for library in args.lib:
        machine.run(library.read_text(encoding="utf-8"), library.name)
    machine.run(before, args.scenario.name + " (hàm)")
    machine.run(script_code(args.script, read_words(args.words)), args.script.name)
    machine.run(f"{name}_PreLoad()\n{name}_OnLoad()", name + " (nạp)")
    # Như UI_CEGUI.dll 3.71.9509 0x18007b8e0: mỗi đối số thứ k của sự kiện thành chuỗi vào biến toàn cục
    # arg<k> và eventTable[k + 1]; đối số không có thì để nguyên giá trị của lần sự kiện trước, rồi gọi
    # <Tên>_OnEvent("<sự kiện>").
    event = (
        "eventTable = {}\n"
        "function __event(name, ...)\n"
        "    for index = 1, arg.n do\n"
        "        local text = tostring(arg[index])\n"
        "        rawset(_G, 'arg' .. (index - 1), text)\n"
        "        eventTable[index] = text\n"
        "    end\n"
        f"    {name}_OnEvent(name)\n"
        "end"
    )
    machine.run(event, "__event")
    machine.run(after, args.scenario.name + " (bước)")
    return machine.lines


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Chạy script giao diện gốc trên LuaPlus.dll và ghi số vàng.")
    parser.add_argument("bin", type=pathlib.Path, help="thư mục Bin64 của client 2026")
    parser.add_argument("script", type=pathlib.Path, help="script đã giải (build/lua-2026/...)")
    parser.add_argument("layout", type=pathlib.Path, help="layout UTF-8 đã gom")
    parser.add_argument("scenario", type=pathlib.Path, help="kịch bản Lua")
    parser.add_argument("out", type=pathlib.Path, help="tệp số vàng ghi ra")
    parser.add_argument("--name", help="tiền tố của _PreLoad, _OnLoad, _OnEvent (mặc định tên tệp script)")
    parser.add_argument("--words", type=pathlib.Path, help="bảng nguyên văn sang bản dịch")
    parser.add_argument("--lib", type=pathlib.Path, action="append", default=[], help="tệp Lua nạp trước kịch bản")
    parser.add_argument("--table", action="append", default=[], help="tên=bảng.tsv: bảng thật thành __tables[tên]")
    parser.add_argument("--schema", type=pathlib.Path, help="thư mục scheme và looknfeel (mặc định ../Schema của layout)")
    args = parser.parse_args(argv)
    if not (args.bin / "LuaPlus.dll").is_file():
        print(f"không thấy LuaPlus.dll trong {args.bin}", file=sys.stderr)
        return 2
    try:
        lines = run(args)
    except OracleError as error:
        print(f"trọng tài dừng: {error}", file=sys.stderr)
        return 1
    note = f"# Sinh bằng TOOLS/port/lua_oracle.py từ {args.script.name} và {args.scenario.name}; không sửa tay"
    args.out.write_text("\n".join([note] + lines) + "\n", encoding="utf-8", newline="\n")
    print(f"đã ghi {len(lines)} dòng vào {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
