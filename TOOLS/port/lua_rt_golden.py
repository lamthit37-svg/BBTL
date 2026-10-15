# Sinh số vàng cho ctest lua_golden (Test/Lua/lua_golden_tests.cpp): chạy các lời gọi thư viện chuẩn (base, string, table,
# math) và phép toán của máy ảo trên CHÍNH LuaPlus.dll của client 2026, ghi kết quả thành Test/golden/lua/lib_cases.tsv và
# ghi đúng chương trình Lua đã chạy thành lib_cases.lua cạnh nó. Test C++ chạy lib_cases.lua trên game_luaplus (LuaPlus dựng
# từ third_party/luaplus) bằng C API và so từng dòng __emit với cột kết quả của .tsv.
# Chạy ở gốc dự án:
#   python -B TOOLS/port/lua_rt_golden.py <Bin64> Test/golden/lua/lib_cases.tsv
# Không sửa tay hai tệp số vàng: sửa danh sách ca ở đây rồi sinh lại.
#
# lib_cases.lua gồm hai đoạn cách nhau một dòng MARKER: đoạn thứ nhất chụp thứ tự duyệt của _G trước mọi định nghĩa khác (tên
# đoạn "golden-first"), đoạn thứ hai là PRELUDE và mọi lời gọi `case(...)` (tên đoạn "golden", để câu lỗi có tiền tố
# `golden:DÒNG:` mà PRELUDE gỡ đi). Mỗi đoạn nạp bằng luaL_loadbuffer rồi lua_pcall trên cùng một máy Lua.
#
# Mỗi dòng tệp ra: id <tab> đường dẫn hàm <tab> danh sách đối số <tab> kết quả. Các ca chạy theo thứ tự, CÙNG MỘT máy Lua
# (hạt math.random, bảng __log của hàm gọi lại là trạng thái chung); ca đầu (globals-order) chụp thứ tự duyệt của _G, string,
# math, table trước khi có thứ gì khác.
#
# Cột đối số của .tsv (để người đọc, test C++ không phân tích) viết theo văn phạm (mỗi giá trị cách nhau một dấu cách):
#   nil | true | false | n:SỐ (inf, -inf, nan, -0 hoặc thập phân) | s:"CHUỖI" (byte ngoài 0x20..0x7E, '"' và '\' là \xNN)
#   | @tên (hàm gọi lại có sẵn) | $tên (biến toàn cục) | { khoá giá trị khoá giá trị ... } (bảng dựng bằng gán lần lượt,
#   giá trị nil được gán thật nên khoá chết vẫn còn như khi script gán nil).
# Kết quả: "(giá trị,...)" hoặc error:s:"câu lỗi" (đã bỏ phần "tệp:dòng: " đầu câu), rồi " | " và mọi đối số sau lời gọi,
# rồi " | " và vết của hàm gọi lại.
import argparse
import math
import pathlib
import random
import struct
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import lua_oracle  # noqa: E402

INF = float("inf")
NAN = object()  # nan của máy x86: 0/0, dấu âm (xem number_of ở test)


class Fn:
    def __init__(self, name):
        self.name = name


class Glob:
    def __init__(self, name):
        self.name = name


class Tab:
    """Bảng dựng bằng gán lần lượt: danh sách (khoá, giá trị)."""

    def __init__(self, pairs):
        self.pairs = list(pairs)


def lst(*items):
    return Tab([(float(i + 1), item) for i, item in enumerate(items)])


def seq(items):
    return Tab([(float(i + 1), item) for i, item in enumerate(items)])


def printable(byte):
    return 0x20 <= byte <= 0x7E and byte not in (0x22, 0x5C)


def token_string(data):
    out = ['s:"']
    for byte in data:
        out.append(chr(byte) if printable(byte) else "\\x%02X" % byte)
    out.append('"')
    return "".join(out)


def as_bytes(text):
    return text if isinstance(text, bytes) else text.encode("latin-1")


def number_token(value):
    if value is NAN:
        return "n:nan"
    if value != value:
        raise ValueError("dùng NAN")
    if value == INF:
        return "n:inf"
    if value == -INF:
        return "n:-inf"
    if value == 0 and math.copysign(1.0, value) < 0:
        return "n:-0"
    return "n:" + repr(float(value))


def token(value):
    if value is None:
        return "nil"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (int, float)) or value is NAN:
        return number_token(value)
    if isinstance(value, (str, bytes)):
        return token_string(as_bytes(value))
    if isinstance(value, Fn):
        return "@" + value.name
    if isinstance(value, Glob):
        return "$" + value.name
    if isinstance(value, Tab):
        return "{ " + " ".join(token(part) for pair in value.pairs for part in pair) + " }" if value.pairs else "{ }"
    raise TypeError(value)


def lua_string(data):
    out = ['"']
    for byte in data:
        out.append(chr(byte) if printable(byte) else "\\%03d" % byte)
    out.append('"')
    return "".join(out)


def lua_number(value):
    if value is NAN:
        return "(0/0)"
    if value == INF:
        return "(1/0)"
    if value == -INF:
        return "(-1/0)"
    if value == 0 and math.copysign(1.0, value) < 0:
        return "(-ZERO)"
    return "%.17g" % value if value >= 0 else "(%.17g)" % value


def lua_value(value):
    """Biểu thức Lua của một giá trị không phải bảng."""
    if value is None:
        return "nil"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (int, float)) or value is NAN:
        return lua_number(value)
    if isinstance(value, (str, bytes)):
        return lua_string(as_bytes(value))
    if isinstance(value, Fn):
        return "F." + value.name
    if isinstance(value, Glob):
        return value.name
    raise TypeError(value)


# Hàm gọi lại có sẵn (bảng F của PRELUDE) và hàm giúp việc.
HELPERS = ("gfind_all", "id", "setup_ops")

PRELUDE = r'''
local ZERO = 0
local pack = function(...) return arg end
local log = {}
local function esc(s)
  return (string.gsub(s, '[%c"\\\128-\255]', function(c) return string.format("\\x%02X", string.byte(c)) end))
end
local function dump(v, seen)
  local t = type(v)
  if t == "nil" then return "nil"
  elseif t == "boolean" then if v then return "true" else return "false" end
  elseif t == "number" then return "n:" .. tostring(v) .. "~" .. string.format("%.17g", v)
  elseif t == "string" then return 's:"' .. esc(v) .. '"'
  elseif t == "function" then return "fn"
  elseif t == "table" then
    if seen[v] then return "#" .. seen[v] end
    seen.count = seen.count + 1
    seen[v] = seen.count
    local parts = {}
    for k, x in pairs(v) do parts[table.getn(parts) + 1] = dump(k, seen) .. "=" .. dump(x, seen) end
    return "{" .. table.concat(parts, ";") .. "}"
  end
  return "?" .. t
end
local function dump_all(values, count)
  local parts = {}
  for i = 1, count do parts[i] = dump(values[i], {count = 0}) end
  return table.concat(parts, ",")
end
local function tab(...)
  local t = {}
  for i = 1, arg.n, 2 do t[arg[i]] = arg[i + 1] end
  return t
end
local F = {}
F.id = function(...) return unpack(arg) end
F.lt = function(a, b) return a < b end
F.gt = function(a, b) return a > b end
F.le = function(a, b) return a <= b end
F.always = function() return true end
F.never = function() return false end
F.bylen = function(a, b) return string.len(a) < string.len(b) end
F.err = function() error("boom", 0) end
F.nilret = function() return nil end
F.numret = function() return 42 end
F.tabret = function() return {} end
F.upper = function(a) return string.upper(a) end
F.wrap = function(a, b) if b then return "<" .. a .. "," .. b .. ">" end return "<" .. a .. ">" end
F.rec = function(...) log[table.getn(log) + 1] = dump_all(arg, arg.n) end
F.rec_stop = function(...) log[table.getn(log) + 1] = dump_all(arg, arg.n) if arg[1] == 3 or arg[2] == 3 then return "stop" end end
F.gfind_all = function(s, p)
  local out = {}
  local f = string.gfind(s, p)
  while true do
    local r = pack(f())
    if r.n == 0 then break end
    out[table.getn(out) + 1] = tab(1, r[1], 2, r[2], 3, r[3], 4, r[4], "n", r.n)
  end
  return out
end
F.op_add = function(a, b) return a + b end
F.op_sub = function(a, b) return a - b end
F.op_mul = function(a, b) return a * b end
F.op_div = function(a, b) return a / b end
F.op_pow = function(a, b) return a ^ b end
F.op_unm = function(a) return -a end
F.op_concat = function(a, b) return a .. b end
F.op_concat3 = function(a, b, c) return a .. b .. c end
F.op_eq = function(a, b) return a == b end
F.op_ne = function(a, b) return a ~= b end
F.op_lt = function(a, b) return a < b end
F.op_le = function(a, b) return a <= b end
F.op_gt = function(a, b) return a > b end
F.op_ge = function(a, b) return a >= b end
F.op_index = function(o, k) return o[k] end
F.op_setget = function(o, k, v) o[k] = v return o[k] end
F.op_call = function(f, ...) return f(unpack(arg)) end
F.op_vararg = function(...) return arg end
F.op_for2 = function(a, b)
  local r, n = {}, 0
  for i = a, b do n = n + 1 r[n] = i if n >= 12 then break end end
  return r
end
F.op_for3 = function(a, b, c)
  local r, n = {}, 0
  for i = a, b, c do n = n + 1 r[n] = i if n >= 12 then break end end
  return r
end
local function note(name)
  return function(...)
    local text = name .. ":" .. dump_all(arg, arg.n)
    log[table.getn(log) + 1] = text
    return text
  end
end
F.setup_ops = function()
  local events = {"add", "sub", "mul", "div", "pow", "unm", "concat", "lt", "le", "eq", "index", "newindex", "call"}
  local function metatable()
    local mt = {}
    for i = 1, table.getn(events) do mt["__" .. events[i]] = note(events[i]) end
    return mt
  end
  obj = setmetatable({}, metatable())
  obj_b = setmetatable({}, getmetatable(obj))
  other = setmetatable({}, metatable())
  plain = {}
  base_t = {}
  base_t.x = 1
  base_t.y = 2
  via_table = setmetatable({}, {__index = base_t, __newindex = base_t})
  loop_t = {}
  setmetatable(loop_t, {__index = loop_t, __newindex = loop_t})
  fn_index = setmetatable({}, {__index = function(t, k) return "fi:" .. tostring(k) end})
end
local function strip(message)
  return (string.gsub(message, "golden:%d+: ", ""))
end
local function case(id, build, call_name)
  local args = pack(build())
  local res = pack(pcall(function() return pack(call_name(unpack(args))) end))
  local text
  if res[1] then
    text = "(" .. dump_all(res[2], res[2].n) .. ")"
  else
    local failure = res[2]
    if type(failure) == "string" then failure = strip(failure) end
    text = "error:" .. dump(failure, {count = 0})
  end
  local joined = table.concat(log, ";")
  log = {}
  __emit(id .. "\t" .. text .. " | [" .. dump_all(args, args.n) .. "] | [" .. joined .. "]")
end
'''


class Case:
    def __init__(self, ident, path, args, lua_function=None):
        self.ident = ident
        self.path = path
        self.args = list(args)
        # Hàm Lua thay cho đường dẫn: dùng cho ca mà mã nguồn (hình dạng hàm dựng bảng) là một phần của phép thử.
        self.lua_function = lua_function


def case_lua(case):
    if case.path.startswith("op."):
        callee = "F.op_" + case.path[3:]
    else:
        callee = "F." + case.path if case.path in HELPERS else case.path
    statements = []
    names = [0]

    def expression(value):
        # Bảng dựng bằng các câu gán lần lượt (một hàm gọi với hàng nghìn đối số vượt 250 thanh ghi của Lua 5.0).
        if isinstance(value, Tab):
            names[0] += 1
            name = "t%d" % names[0]
            statements.append("local %s = {}" % name)
            for key, item in value.pairs:
                statements.append("%s[%s] = %s" % (name, expression(key), expression(item)))
            return name
        return lua_value(value)

    arguments = [expression(arg) for arg in case.args]
    build = " ".join(statements) + " return " + ", ".join(arguments)
    # Gọi qua hàm bọc để tên hàm trong câu lỗi lấy từ nơi gọi (`find`, không phải `?`), như script gốc gọi.
    if case.lua_function is not None:
        return "case(%s, function() %s end, %s)" % (lua_string(case.ident.encode()), build, case.lua_function)
    return "case(%s, function() %s end, function(...) return %s(unpack(arg)) end)" % (
        lua_string(case.ident.encode()), build, callee)


CASES: list[Case] = []


def add(path, *args, ident=None, lua_function=None):
    ident = ident or "%s#%d" % (path, len(CASES))
    CASES.append(Case(ident, path, args, lua_function))


def format_arguments(fmt):
    """Đối số vừa kiểu cho từng đặc tả của một định dạng (đặc tả %% bỏ qua)."""
    result = []
    index = 0
    while index < len(fmt):
        if fmt[index] != "%":
            index += 1
            continue
        index += 1
        if index < len(fmt) and fmt[index] == "%":
            index += 1
            continue
        while index < len(fmt) and fmt[index] in "-+ #0123456789.":
            index += 1
        kind = fmt[index] if index < len(fmt) else ""
        index += 1
        if kind in "sq":
            result.append("str")
        elif kind in "cdiouxX":
            result.append(66.0)
        else:
            result.append(3.14159)
    return result


def build_cases():
    zero = 0.0
    negzero = -0.0
    values = [0.0, negzero, 0.5, 1.0, -1.0, 2.0, 10.0, 0.1, 255.0, -2.5, 7.0, 1.0 / 3.0, math.pi, -math.pi, 1e10, 1e-10, 1e15,
              1e300, 2147483647.0, 2147483648.0, -2147483648.0, -2147483649.0, 4294967296.0, 1e-300, 123456.789, 5e-324,
              INF, -INF, NAN]
    # --- thứ tự duyệt của bảng thư viện (chụp đầu tiên, trước mọi thứ khác) ---
    add("id", Glob("_G"), ident="order-G")
    add("id", Glob("string"), ident="order-string")
    add("id", Glob("math"), ident="order-math")
    add("id", Glob("table"), ident="order-table")
    add("id", Glob("coroutine"), ident="order-coroutine")
    # --- math ---
    one_arg = ["abs", "sin", "cos", "tan", "asin", "acos", "atan", "ceil", "floor", "sqrt", "log", "log10", "exp", "deg", "rad"]
    for name in one_arg:
        for v in values:
            add("math." + name, v)
    for v in values:
        add("math.frexp", v)
    for v, e in [(1.0, 5.0), (0.5, 4.0), (3.0, 2.9), (INF, 1.0), (1.0, -5000.0), (1.0, 5000.0), (1.0, 3e9), (NAN, 1.0), (0.0, 1e6)]:
        add("math.ldexp", v, e)
    for a, b in [(1.0, 0.0), (7.0, 3.0), (-7.0, 3.0), (7.0, -3.0), (5.5, 2.0), (INF, 2.0), (2.0, INF), (NAN, 1.0), (1.0, NAN), (0.0, 1.0),
                 (-6.0, 3.0), (6.0, -3.0)]:
        add("math.mod", a, b)
        add("math.pow", a, b)
        add("math.atan2", a, b)
    for args in [(3.0, 1.0, 2.0), (1.0,), (NAN, 1.0), (1.0, NAN), (-INF, INF), ("5", 4.0), ()]:
        add("math.min", *args)
        add("math.max", *args)
    add("math.abs", "-3")
    add("math.floor", "x")
    add("math.floor")
    add("math.sqrt", None)
    add("math.sqrt", True)
    add("__pow", 2.0, 10.0)
    add("__pow", "3", 2.0)
    # dãy math.random: chung một máy nên thứ tự là một phần của số vàng
    add("math.random")
    add("math.random", 10.0)
    add("math.random", 5.0, 8.0)
    add("math.randomseed", 42.0)
    for _ in range(3):
        add("math.random")
        add("math.random", 100.0)
        add("math.random", -5.0, 5.0)
    add("math.randomseed", 1.0)
    add("math.random")
    add("math.random", 100.0)
    for seed in (7.0, -1.0, 4294967296.0, 3.7, "9", 0.0, 2147483648.0):
        add("math.randomseed", seed)
        add("math.random", 1000.0)
        add("math.random", 1000.0)
    add("math.random", -2147483647.0, 2147483647.0)
    add("math.random", 1.0, 2147483647.0)
    add("math.random", -2147483648.0, -1.0)
    add("math.random", 0.0)
    add("math.random", 3.0, 1.0)
    add("math.random", 1.0, 2.0, 3.0)
    add("math.random", 3.9)
    add("math.random", 2.5, 7.9)
    add("math.random", "3")
    add("math.random", 5.0, None)
    add("math.randomseed")
    add("math.random", 4e9)
    # --- tostring, tonumber, type ---
    for v in values:
        add("tostring", v)
    for s in ["10", " 10 ", "0x10", "1e2", "1d2", "", "abc", "5.", ".5", "-0", "1e", "1 2", "inf", "nan", "9" * 30, "1e400", "-1e-400"]:
        add("tonumber", s)
    for s, base in [("ff", 16.0), ("FF", 16.0), ("0x1f", 16.0), ("777", 8.0), ("z", 36.0), ("102", 2.0), ("-1", 16.0), ("  12  ", 10.0),
                    ("1e1", 10.0), ("11", 1.0), ("11", 37.0), ("ffffffff", 16.0), ("100000000", 16.0), ("-ffffffff", 16.0), ("", 16.0),
                    (10.0, 16.0), (True, 10.0)]:
        add("tonumber", s, base)
    add("tonumber")
    add("tonumber", None)
    add("tonumber", lst(1.0))
    for v in [None, True, 1.0, "x", lst(), Fn("id")]:
        add("type", v)
    add("type")
    add("tostring", None)
    add("tostring", True)
    add("tostring", False)
    add("tostring", "str")
    add("tostring")
    # --- string.len, sub, lower, upper, rep, byte, char ---
    subjects = ["", "a", "hello", "hello world", "\0ab\0", "\xe9\xc9z", "x" * 120]
    for s in subjects:
        add("string.len", s)
        add("string.lower", s)
        add("string.upper", s)
    add("string.len", 12345.0)
    add("string.len")
    add("string.len", None)
    for s in ["hello", "", "x"]:
        for i in (1.0, 2.0, 3.0, -1.0, -3.0, -10.0, 0.0, 10.0, 2.7, -2.7):
            add("string.sub", s, i)
            for j in (1.0, 2.0, 5.0, -1.0, -2.0, 0.0, 100.0, -100.0, 3.9):
                add("string.sub", s, i, j)
    add("string.sub", "hello")
    add("string.sub", "hello", "x")
    add("string.sub", "hello", 2.0, "y")
    add("string.sub", 12345.0, 2.0, 3.0)
    add("string.sub", "hello", 2.0, None)
    add("string.sub", "hello", 4294967296.0, 5.0)
    for s in ["ab", "", "\0"]:
        for n in (0.0, 1.0, 3.0, -2.0, 2.5):
            add("string.rep", s, n)
    add("string.rep", "x")
    add("string.rep", 7.0, 3.0)
    for s in ["abc", "", "\xff\0"]:
        for p in (None, 1.0, 2.0, 3.0, 4.0, 0.0, -1.0, -3.0, -4.0, 1.5):
            add("string.byte", s, p)
    add("string.byte")
    add("string.char")
    add("string.char", 72.0, 105.0, 0.0, 255.0)
    add("string.char", 256.0)
    add("string.char", -1.0)
    add("string.char", 65.0, 300.0)
    add("string.char", "65")
    add("string.char", "x")
    add("string.char", 65.9)
    # --- string.format ---
    formats = ["%%", "a%%b", "%c", "%5c|", "%-5c|", "%05c|", "%c%c%c", "%d", "%i", "%5d|", "%-5d|", "%05d|", "%+d", "% d", "%.3d", "%+.3d",
               "%-+8.3d|", "%x", "%X", "%#x", "%#X", "%o", "%#o", "%u", "%08.3x|", "%.0d|", "%+u", "% x", "%5.3d|", "%e", "%E", "%.0e", "%#.0e",
               "%.3e", "%10.4e|", "%-14e|", "%+014.3e", "%f", "%.0f", "%#.0f", "%.2f", "%10.3f|", "%-10.3f|", "%+.2f", "% .2f", "%010.2f", "%g",
               "%G", "%.0g", "%.1g", "%.3g", "%#g", "%#.0g", "%#.3g", "%10.4g|", "%-12g|", "%012g|", "%+g", "%.14g", "%.17g", "%.20g", "%.30g",
               "%.20f", "%.99f", "%99.99f", "%s", "%5s|", "%-5s|", "%.2s", "%5.2s|", "%05s|", "%+5s|", "%q", "%10q", "%s%s", "%s %s %s",
               "%d %s", "%5.1f|%5.1f", "abc%dxyz", "%-5d|%5s|", "%3d|%-3d|%03d"]
    format_values = [0.0, 1.0, -1.0, 5.0, 65.0, 255.0, 0.5, 2.5, 1.5, 0.125, 2.675, 0.35, 1.25, 1.35, 3.9, -3.9, 100000.0, 1e6, 1e-4, 1e-5, 12345.6789,
                     123456789.0, 1e15, 1e22, 1e23, 1e100, 1e-100, 5e-324, 1.7976931348623157e308, 0.1, 1.0 / 3.0, 2147483647.0, 2147483648.0,
                     4294967295.0, 4294967296.0, 5e9, -5e9, 1e19, -2147483649.0, 99.5, 999999999999999.5, 0.05, 0.04999, 1.00000000000005,
                     INF, -INF, NAN]
    for f in formats:
        add("string.format", f, *format_arguments(f))
    # mỗi định dạng nhận mỗi giá trị: số lượng lớn nhưng là bằng chứng chính của cformat
    for f in ["%d", "%x", "%u", "%c", "%e", "%f", "%g", "%.3f", "%10.2e|", "%-12g|", "%+.5g", "%#g", "%.0f", "%.17g", "%.20f", "%5.1f", "%s", "%.14g",
              "%o", "%X", "%i", "%q"]:
        for v in format_values:
            add("string.format", f, v)
    # chuỗi cho %s, %q
    for s in ["abc", "", "tab\tcr\rnl\nnul\0end", 'q"uo\\te', "x" * 99, "x" * 100, "x" * 150, "\xe9\xff"]:
        for f in ["%s", "%q", "%.5s", "%5s|", "%-7s|", "%3.1s|", "[%s]", "%10s|"]:
            add("string.format", f, s)
    # nhiều đối số, đối số thiếu, sai kiểu, đặc tả sai
    add("string.format")
    add("string.format", None)
    add("string.format", 12.0)
    add("string.format", "%d")
    add("string.format", "%d", "x")
    add("string.format", "%d", "12")
    add("string.format", "%d", None)
    add("string.format", "%s")
    add("string.format", "%s", lst(1.0))
    add("string.format", "%s", None)
    add("string.format", "%s", True)
    add("string.format", "%s", Fn("id"))
    add("string.format", "%s %s", "a")
    add("string.format", "%s", 12.5)
    # Không có "%-" và "% ": định dạng kết thúc ngay sau cờ làm vòng quét cờ của gốc đọc quá NUL, nên kết quả của DLL phụ thuộc
    # byte nằm sau chuỗi (đo: "% " ra lỗi ở ba lần sinh và ra "" ở lần thứ tư).
    for f in ["%", "%5", "%ld", "%5%", "%z", "%1$d", "%100d", "%.100f", "%-------------------d", "%--------------------d", "%y", "%p", "%n",
              "%.", "%.f", "%.d", "%5.d", "%lf", "%h", "%a"]:
        add("string.format", f, 1.0)
    add("string.format", "%c%d%s%q", 65.0, 66.0, "s", "q")
    add("string.format", "%d", 2147483647.0)
    add("string.format", "%d", -2147483648.0)
    add("string.format", "x" * 300 + "%d", 1.0)
    add("string.format", "%s" * 40, *["ab"] * 40)
    # --- string.find ---
    plain_cases = [("hello world", "o w"), ("hello", "l"), ("hello", "xyz"), ("", ""), ("abc", ""), ("a.b", "."), ("a+b", "+"), ("a\0b", "\0"),
                   ("a\0b", "b"), ("aXb", "X"), ("hello", "hello"), ("hello", "hellox"), ("", "a"), ("abc", "abc"), ("abcabc", "c"),
                   ("\xe9\xe8", "\xe8")]
    for s, p in plain_cases:
        add("string.find", s, p)
        add("string.find", s, p, 1.0, True)
        add("string.find", s, p, 2.0)
        add("string.find", s, p, 4.0)
        add("string.find", s, p, -1.0)
        add("string.find", s, p, -2.0)
        add("string.find", s, p, -100.0)
        add("string.find", s, p, 100.0)
        add("string.find", s, p, 0.0)
        add("string.find", s, p, 1.0, 1.0)
        add("string.find", s, p, 1.0, False)
    add("string.find", "a.b", ".", 1.0, True)
    add("string.find", "a.b", "%.", 1.0, True)
    add("string.find", "a%b", "%", 1.0, True)
    add("string.find", 12345.0, 34.0)
    add("string.find", "12345", 34.0)
    add("string.find")
    add("string.find", "abc")
    add("string.find", "abc", None)
    add("string.find", "abc", "b", "x")
    patterns = [("hello world", "w%a+"), ("hello 123", "%d+"), ("hello", "(h)(e)"), ("hello", "()ll()"), ("hello", "^he"), ("hello", "^el"),
                ("hello", "lo$"), ("hello", "l$"), ("hello", "h.-l"), ("hello", "h.*l"), ("hello", "[a-f]"), ("hello", "[^a-f]+"),
                ("THE (quick) fox", "%((%a+)%)"), ("f(a(b)c)d", "%b()"), ("THE (quick) fox", "%f[%a]%a+%f[%A]"), ("hello hello", "(hel)lo %1"),
                ("abc", "a?b?c?d?"), ("aaa", "a-"), ("aaa", "^a-$"), ("x=1, y=2", "(%w+)=(%w+)"), ("abc", "()"), ("abc", "^"), ("abc", "$"),
                ("", "^$"), ("", ".*"), ("", "x*"), ("abc", ".-"), ("abc", "b*"), ("abc", "[abc]+"), ("abc", "[a-c]-c"), ("a-b", "[a%-]+"),
                ("a]b", "[]]"), ("a]b", "[^]]+"), ("a^b", "[%^]"), ("path/to/file.txt", "([^/]+)$"), ("key = value", "^(%w+)%s*=%s*(%w+)$"),
                ("2024-01-15", "(%d+)-(%d+)-(%d+)"), ("  trim  ", "^%s*(.-)%s*$"), ("a1b2c3", "%a%d"), ("ABC def", "%u+"), ("ABC def", "%l+"),
                ("a.b,c;d", "%p"), ("tab\there", "%c"), ("0x1F", "%x+"), ("zero\0byte", "%z"), ("zero\0byte", "e%zb"), ("abc", "%Z+"),
                ("abc123", "%W"), ("a b", "%S+"), ("a b", "%A"), ("abc", "%D+"), ("x", "x?"), ("xx", "x?x"), ("abab", "(ab)%1"), ("abcabc", "(abc)%1"),
                ("aaab", "a*b"), ("aaab", "a+b"), ("b", "a*b"), ("b", "a+b"), ("hello world from lua", "%s(%a+)%s"), ("[tag]", "%[(.-)%]"),
                ("$100", "%$(%d+)"), ("a(b", "%("), ("end.", "%.$"), ("end.", ".$"), ("f(x)", "%((.-)%)"), ("THE END", "%f[%a]%a+%f[%A]$"),
                ("one two", "%f[%w]%w+"), ("xaby", "%f[a]"), ("xaby", "%f[%z]"), ("(((", "%b()"), ("(()", "%b()"), ("{{}}", "%b{}"),
                ("hello", "(l)(l)(o)"), ("hello", "((h)(e))"), ("hello", "(h)()"), ("a,b", "^(.-),(.*)$"), ("\xe9a", "[\xe0-\xff]"), ("\xe9a", "%a"),
                ("\xe9", "%\xe9"), ("\xe9", "[%\xe9]"), ("A", "[a-z]"), ("-", "[a-]"), ("-", "[-a]"), ("b", "[a-c-e]"), ("d", "[a-c-e]"),
                ("abc", "[%a-z]"), ("-", "[%a-z]"), ("x", "[^%s]")]
    for s, p in patterns:
        add("string.find", s, p)
        add("string.find", s, p, 2.0)
        add("string.find", s, p, -2.0)
        add("string.find", s, p, 100.0)
    add("string.find", "a" * 40, "(a)" * 32)
    add("string.find", "a" * 40, "(a)" * 33)
    add("string.find", "a" * 40, "()" * 32)
    for p in ["(", ")", "%", "[a", "[", "%b", "%bx", "%f", "%fx", "(()", "())", "%1", "(a)%2", "(a%1)", "[%", "[a-", "a(", "(a", "%", "^%", "[^",
              "[]", "[^]", "(%a", "%a)", "x(%1)"]:
        add("string.find", "abc", p)
        add("string.find", "abc", p, 1.0, False)
    add("string.find", "abc", "a**")
    add("string.find", "abc", "*a")
    add("string.find", "a*c", "a*c")
    add("string.find", "a*c", "a%*c")
    add("string.find", "abc", "a+?")
    add("string.find", "abc", "^^a")
    add("string.find", "a^c", "a^c")
    add("string.find", "a$c", "a$c")
    add("string.find", "abc", "b\0c")
    add("string.find", "abc", "\0")
    add("string.find", "a\0c", "a\0c", 1.0, True)
    add("string.find", "a\0c", "a\0%a")
    add("string.find", "aaa", "a?a?a?a?a?a?a?a?a?a?b")
    # --- string.gsub ---
    gsubs = [("hello world", "o", "0"), ("hello", "l+", "L"), ("hello", "(l)(l)", "%2%1"), ("abc", "", "-"), ("abc", "x*", "-"), ("abc", "b*", "-"),
             ("hello world", "%w+", "<%1>"), ("hello world", "(%w+) (%w+)", "%2 %1"), ("abc", "b", "x%"), ("abc", "(b)", "%1%1"), ("abc", "b", 5.0),
             ("abc", "b", "%%"), ("abc", "b", "%a"), ("abc", "b", "a%"), ("abc", ".", "%0"), ("abc", "(.)", "%2"), ("abc", "(.)", "%9"),
             ("abc", ".", "%1"), ("abc", "()", "%1"), ("abc def", "%s", "_"), ("aaa", "^a", "b"), ("aaa", "a$", "b"), ("aaa", "^", "x"),
             ("aaa", "$", "x"), ("", "", "x"), ("", "x*", "y"), ("a b c", " ", ""), ("abc", "%w", "%0%0"), ("abc", "b", ""), ("x", "x", "%1"),
             ("hello", "(h)(e)(l)(l)(o)", "%5%4%3%2%1"), ("a.b", "%.", "%%"), ("path/a/b", "/", "\\"), ("abc", "[ac]", "%%1"), ("abcabc", "b", "[%0]"),
             ("one;two;;three", "([^;]*)", "<%1>"), ("abc", "(", "x"), ("abc", "%", "x"), ("abc", "[a", "x"), ("abc", "a", "%1")]
    for s, p, r in gsubs:
        add("string.gsub", s, p, r)
        add("string.gsub", s, p, r, 1.0)
        add("string.gsub", s, p, r, 0.0)
        add("string.gsub", s, p, r, -1.0)
        add("string.gsub", s, p, r, 2.0)
    for s, p in [("hello world", "%w+"), ("hello world", "(%w+) (%w+)"), ("abc", ""), ("abc", "()"), ("a1b2", "%d"), ("abc", "x")]:
        for f in ("upper", "wrap", "nilret", "numret", "tabret", "id", "err", "rec", "never", "always"):
            add("string.gsub", s, p, Fn(f))
    add("string.gsub", "hello", "l", lst("x"))
    add("string.gsub", "hello", "l")
    add("string.gsub", "hello", "l", None)
    add("string.gsub", "hello", "l", True)
    add("string.gsub", "hello")
    add("string.gsub", "hello", "l", "x", "y")
    add("string.gsub", "hello", "l", "x", 1.5)
    add("string.gsub", 12345.0, 3.0, 9.0)
    add("string.gsub", "abc", "b", "x", None)
    add("string.gsub", "abc", "^b", "x")
    add("string.gsub", "abc", "^a", "x")
    add("string.gsub", "abc", "^a", "x", 0.0)
    add("string.gsub", "a\0c", "\0", "z")
    add("string.gsub", "abc", "b", "\0")
    add("string.gsub", "x" * 200, "x", "yy")
    add("string.gsub", "abc", ".", Fn("rec"))
    # --- string.gfind (qua gfind_all) ---
    for s, p in [("one two three", "%a+"), ("abc", ""), ("a,b,,c", "([^,]*)"), ("k=v, k2=v2", "(%w+)=(%w+)"), ("abc", "()"), ("hello", "l*"),
                 ("abc", "x"), ("", ""), ("", "x*"), ("a b", "^a"), ("aXbXc", "X"), ("abab", "(a)(b)"), ("x", "(x)(x?)"), ("abc", "%"), ("abc", "(")]:
        add("gfind_all", s, p)
    add("string.gfind")
    add("string.gfind", "abc")
    add("string.gfind", "abc", "b")
    add("string.gfind", 123.0, 2.0)
    # --- table ---
    for items in [[], [1.0], [1.0, 2.0, 3.0], ["a", "b", "c"], [1.0, "x", 2.5], [1.0, None, 3.0], [True], [lst()], ["a", 1.0, "b"]]:
        add("table.concat", seq(items))
        add("table.concat", seq(items), ",")
        add("table.concat", seq(items), ", ", 2.0)
        add("table.concat", seq(items), ", ", 2.0, 3.0)
        add("table.concat", seq(items), "", 1.0, 2.0)
        add("table.concat", seq(items), ",", 3.0, 2.0)
        add("table.concat", seq(items), ",", 0.0, 2.0)
        add("table.concat", seq(items), ",", -1.0, 1.0)
        add("table.concat", seq(items), 7.0)
        add("table.concat", seq(items), None, None, None)
        add("table.getn", seq(items))
    add("table.concat")
    add("table.concat", "x")
    add("table.concat", lst("a"), lst("b"))
    add("table.concat", lst("a", "b"), ",", "x")
    add("table.concat", Tab([("n", 2.0), (1.0, "a"), (2.0, "b"), (3.0, "c")]), "-")
    add("table.concat", Tab([("n", 5.0), (1.0, "a")]), "-")
    add("table.concat", Tab([(1.0, "a"), (2.0, "b"), (4.0, "d")]), "-")
    add("table.getn")
    add("table.getn", "x")
    add("table.getn", Tab([("n", 7.0)]))
    add("table.getn", Tab([("n", "7")]))
    add("table.getn", Tab([("n", "x"), (1.0, 1.0), (2.0, 2.0)]))
    add("table.getn", Tab([("n", -1.0), (1.0, 1.0)]))
    add("table.getn", Tab([(1.0, 1.0), (2.0, 2.0), (4.0, 4.0)]))
    add("table.getn", Tab([(1.0, 1.0), (2.0, None), (3.0, 3.0)]))
    add("table.setn", Tab([]), 5.0)
    add("table.setn", Tab([("n", 1.0)]), 5.0)
    add("table.setn", Tab([("n", "x")]), 5.0)
    add("table.setn", Tab([(1.0, 1.0)]), -3.0)
    add("table.setn", "x", 1.0)
    add("table.setn", Tab([]))
    add("table.setn", Tab([]), "y")
    for items in [[], [1.0], [1.0, 2.0, 3.0]]:
        for pos in (None, 1.0, 2.0, 3.0, 4.0, 5.0, 0.0, -1.0, 1.5):
            args = [seq(items)]
            if pos is not None:
                args.append(pos)
            add("table.insert", *args, "v")
        add("table.insert", seq(items), "v")
        add("table.insert", seq(items), 1.0, "v", "extra")
        add("table.insert", seq(items), 1.0, None)
        add("table.insert", seq(items))
        add("table.insert", seq(items), "x", "v")
        for pos in (None, 1.0, 2.0, 3.0, 4.0, 0.0, -1.0, 1.5, 100.0):
            if pos is None:
                add("table.remove", seq(items))
            else:
                add("table.remove", seq(items), pos)
    add("table.insert")
    add("table.insert", "x", 1.0)
    add("table.insert", Tab([("n", 3.0), (1.0, "a")]), "z")
    add("table.insert", Tab([("n", 3.0), (1.0, "a")]), 2.0, "z")
    add("table.remove", Tab([("n", 3.0), (1.0, "a"), (2.0, "b"), (3.0, "c")]))
    add("table.remove", Tab([("n", 0.0)]))
    add("table.remove", Tab([("n", 3.0), (1.0, "a"), (2.0, "b"), (3.0, "c")]), 1.0)
    add("table.remove")
    add("table.remove", Tab([]), "x")
    # sort
    rng = random.Random(20261015)
    add("table.sort", seq([]))
    add("table.sort", seq([1.0]))
    add("table.sort", seq([2.0, 1.0]))
    add("table.sort", seq([1.0, 2.0]))
    add("table.sort", seq([3.0, 1.0, 2.0]))
    add("table.sort", seq([1.0, 1.0, 1.0, 1.0]))
    add("table.sort", seq([3.0, 1.0, 3.0, 2.0, 1.0, 2.0, 3.0, 1.0]))
    add("table.sort", seq(["b", "a", "c", "B", "A", "aa", "", "b"]))
    add("table.sort", seq(["b", "a", "c", "a"]), Fn("gt"))
    add("table.sort", seq([3.0, 1.0, 2.0]), Fn("lt"))
    add("table.sort", seq([3.0, 1.0, 2.0, 5.0, 4.0]), Fn("gt"))
    add("table.sort", seq([3.0, 1.0, 2.0, 5.0, 4.0]), Fn("always"))
    add("table.sort", seq([3.0, 1.0, 2.0, 5.0, 4.0]), Fn("never"))
    add("table.sort", seq([3.0, 1.0, 2.0, 5.0, 4.0, 1.0, 2.0, 3.0]), Fn("le"))
    add("table.sort", seq([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]), Fn("le"))
    add("table.sort", seq([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]), Fn("always"))
    add("table.sort", seq([3.0, 1.0, 2.0]), Fn("err"))
    add("table.sort", seq(["ccc", "a", "bb", "dd", "e"]), Fn("bylen"))
    add("table.sort", seq([3.0, "a", 1.0]))
    add("table.sort", seq([3.0, None, 1.0]))
    add("table.sort", seq([lst(1.0), lst(2.0)]))
    add("table.sort", seq([True, False]))
    add("table.sort", seq([3.0, 1.0, 2.0]), 5.0)
    add("table.sort", seq([3.0, 1.0, 2.0]), "x")
    add("table.sort", seq([3.0, 1.0, 2.0]), None)
    add("table.sort", seq([3.0, 1.0, 2.0]), False)
    add("table.sort")
    add("table.sort", "x")
    add("table.sort", Tab([("n", 3.0), (1.0, 3.0), (2.0, 1.0), (3.0, 2.0), (4.0, 0.0)]))
    add("table.sort", Tab([("n", 2.0), (1.0, 3.0), (2.0, 1.0), (3.0, 2.0)]))
    add("table.sort", Tab([(1.0, 5.0), (2.0, 4.0), (4.0, 1.0)]))
    for size in list(range(0, 21)) + [31, 32, 33, 50, 64, 100]:
        perm = [float(i) for i in range(size)]
        rng.shuffle(perm)
        add("table.sort", seq(perm))
        add("table.sort", seq(perm), Fn("gt"))
        dup = [float(rng.randrange(0, max(2, size // 3))) for _ in range(size)]
        add("table.sort", seq(dup))
        add("table.sort", seq(dup), Fn("gt"))
        add("table.sort", seq(dup), Fn("le"))
        words = ["w%d" % rng.randrange(0, max(2, size)) for _ in range(size)]
        add("table.sort", seq(words))
        add("table.sort", seq([float(i) for i in range(size)]))
        add("table.sort", seq([float(size - i) for i in range(size)]))
    # foreach, foreachi
    for items in [[], [10.0], [10.0, 20.0, 30.0], [10.0, None, 30.0], ["a", "b", "c", "d"]]:
        add("table.foreachi", seq(items), Fn("rec"))
        add("table.foreachi", seq(items), Fn("rec_stop"))
        add("table.foreachi", seq(items), Fn("nilret"))
        add("table.foreachi", seq(items), Fn("numret"))
    add("table.foreachi", Tab([("n", 3.0), (1.0, "a"), (3.0, "c")]), Fn("rec"))
    add("table.foreachi", seq([1.0]))
    add("table.foreachi", seq([1.0]), 5.0)
    add("table.foreachi", "x", Fn("rec"))
    add("table.foreachi", seq([1.0]), Fn("err"))
    add("table.foreach", Tab([]), Fn("rec"))
    add("table.foreach", Tab([(1.0, "a"), (2.0, "b"), (3.0, "c"), (4.0, "d")]), Fn("rec"))
    add("table.foreach", Tab([(1.0, "a"), (2.0, "b"), (3.0, "c"), (4.0, "d")]), Fn("rec_stop"))
    add("table.foreach", Tab([("b", 1.0), ("a", 2.0), (10.0, 3.0), ("zz", 4.0), (1.0, 5.0), (2.5, 6.0)]), Fn("rec"))
    add("table.foreach", Tab([("x", 1.0), ("y", 2.0)]), Fn("numret"))
    add("table.foreach", Tab([("x", 1.0)]))
    add("table.foreach", "x", Fn("rec"))
    add("table.foreach", Tab([("x", 1.0)]), Fn("err"))
    add("table.foreach", Glob("math"), Fn("rec"))
    # --- thứ tự duyệt của bảng (next / pairs / foreach / dump) ---
    add("id", Tab([("b", 1.0), ("a", 2.0), (10.0, 3.0), ("zz", 4.0), (1.0, 5.0), (2.5, 6.0)]), ident="order-mixed")
    add("id", Tab([("b", 1.0), ("a", 2.0), (10.0, 3.0), ("zz", 4.0), (1.0, 5.0), (2.5, 6.0), ("a", None), (3.0, 7.0)]), ident="order-delete")
    add("id", Tab([(float(k), float(k)) for k in (5, 3, 9, 1, 7, 2, 8, 4, 6, 10)]), ident="order-ints")
    add("id", Tab([(float(k), float(k)) for k in range(1, 40)]), ident="order-seq")
    add("id", Tab([(float(k), float(k)) for k in range(40, 0, -1)]), ident="order-rev")
    add("id", Tab([(float(k * 7 % 53), float(k)) for k in range(1, 50)]), ident="order-scatter")
    add("id", Tab([(-1.0, 1.0), (0.0, 2.0), (1.0, 3.0), (-2.0, 4.0), (2.0, 5.0), (1e10, 6.0), (-1e10, 7.0), (0.5, 8.0), (-0.5, 9.0)]), ident="order-neg")
    add("id", Tab([(True, 1.0), (False, 2.0), ("t", 3.0), (1.0, 4.0)]), ident="order-bool")
    add("id", Tab([(("k%d" % i), float(i)) for i in range(30)]), ident="order-strings")
    add("id", Tab([(("k%d" % i), float(i)) for i in range(30)] + [(("k%d" % i), None) for i in range(0, 30, 3)]), ident="order-strings-del")
    add("id", Tab([(("k%d" % i), float(i)) for i in range(30)] + [(("k%d" % i), None) for i in range(0, 30, 3)] + [(("m%d" % i), 1.0) for i in range(10)]),
        ident="order-strings-del-grow")
    for count in (1, 2, 3, 4, 5, 6, 7, 8, 9, 16, 17, 33, 64, 65):
        add("id", Tab([(("s%d" % i), float(i)) for i in range(count)]), ident="order-str-%d" % count)
        add("id", Tab([(float(i), float(i)) for i in range(count, 0, -1)]), ident="order-int-rev-%d" % count)
        mixed = []
        for i in range(count):
            mixed.append((("s%d" % i), float(i)))
            mixed.append((float(i + 1), float(i)))
        add("id", Tab(mixed), ident="order-int-str-%d" % count)
    # --- base ---
    add("next", Tab([("a", 1.0), ("b", 2.0)]))
    add("next", Tab([("a", 1.0), ("b", 2.0)]), "a")
    add("next", Tab([("a", 1.0), ("b", 2.0)]), "b")
    add("next", Tab([("a", 1.0), ("b", 2.0)]), "zzz")
    add("next", Tab([]))
    add("next", Tab([(1.0, "x")]), 1.0)
    add("next", Tab([(1.0, "x")]), 2.0)
    add("next")
    add("next", "x")
    add("pairs", Tab([("a", 1.0)]))
    add("pairs")
    add("pairs", "x")
    add("ipairs", Tab([(1.0, "a")]))
    add("ipairs", Tab([(1.0, "a")]), 0.0)
    add("ipairs", Tab([(1.0, "a"), (2.0, "b")]), 1.0)
    add("ipairs", Tab([(1.0, "a"), (2.0, "b")]), 2.0)
    add("ipairs", Tab([(1.0, "a"), (2.0, "b")]), "1")
    add("ipairs")
    add("ipairs", "x")
    add("rawget", Tab([("a", 1.0)]), "a")
    add("rawget", Tab([("a", 1.0)]), "b")
    add("rawget", Tab([("a", 1.0)]))
    add("rawget", Tab([("a", 1.0)]), None)
    add("rawget", "x", "a")
    add("rawset", Tab([("a", 1.0)]), "b", 2.0)
    add("rawset", Tab([("a", 1.0)]), "a", None)
    add("rawset", Tab([]), None, 1.0)
    add("rawset", Tab([]), NAN, 1.0)
    add("rawset", Tab([]), 1.0)
    add("rawset", Tab([]), 1.0, None)
    add("rawset", Tab([]))
    add("rawequal", 1.0, 1.0)
    add("rawequal", "a", "a")
    add("rawequal", 1.0, "1")
    add("rawequal", None, None)
    add("rawequal", NAN, NAN)
    add("rawequal", 1.0)
    add("rawequal")
    add("unpack", Tab([]))
    add("unpack", seq([1.0, 2.0, 3.0]))
    add("unpack", Tab([("n", 3.0), (1.0, "a")]))
    add("unpack", Tab([("n", 2.0), (1.0, "a"), (2.0, "b"), (3.0, "c")]))
    add("unpack", seq([1.0] * 2040))
    add("unpack", seq([1.0] * 2047))
    add("unpack", seq([1.0] * 2048))
    add("unpack", Tab([("n", 3000.0)]))
    add("unpack", Tab([("n", 2047.0)]))
    add("unpack", "x")
    add("unpack")
    add("assert", True)
    add("assert", 1.0, "m")
    add("assert", None)
    add("assert", False, "boom")
    add("assert", None, "boom", "extra")
    add("assert", False, lst())
    add("assert", False, 7.0)
    add("assert", False, None)
    add("assert")
    add("error", "msg")
    add("error", "msg", 0.0)
    add("error", "msg", 1.0)
    add("error", "msg", 2.0)
    add("error", 5.0)
    add("error", 5.0, 0.0)
    add("error", None)
    add("error", lst("t"))
    add("error")
    add("error", "m", "x")
    add("pcall", Fn("id"), 1.0, 2.0)
    add("pcall", Fn("err"))
    add("pcall", Fn("nilret"))
    add("pcall", 5.0)
    add("pcall", None)
    add("pcall", Tab([]))
    add("pcall")
    add("pcall", Glob("error"), "x")
    add("pcall", Glob("error"), lst(1.0))
    add("pcall", Glob("error"))
    add("xpcall", Fn("err"), Fn("id"))
    add("xpcall", Fn("id"), Fn("id"))
    add("xpcall", Fn("err"), Fn("err"))
    add("xpcall", Fn("err"))
    add("xpcall", Fn("err"), Fn("nilret"))
    add("setmetatable", Tab([]), None)
    add("setmetatable", Tab([]), Tab([("__index", 5.0)]))
    add("setmetatable", Tab([]), 5.0)
    add("setmetatable", Tab([]))
    add("setmetatable", 5.0, Tab([]))
    add("setmetatable")
    add("collectgarbage")
    add("collectgarbage", "collect")
    build_op_cases()
    # Ca thêm sau cùng (không làm lệch số thứ tự trong id của các ca trên): tonumber(chuỗi, cơ số) đi qua strtoul 32 bit của
    # MSVCR110 (luanum_strtoul), nên tràn 32 bit, số âm, tiền tố và cơ số ngoài miền int32 là chỗ CRT của máy dựng có thể lệch.
    for s, base in [("-100000000", 16.0), ("fffffffff", 16.0), ("zzzzzzzz", 36.0), ("4294967296", 10.0), ("-4294967295", 10.0),
                    ("+5", 10.0), ("-0", 10.0), ("0", 2.0), (" -ff", 16.0), ("7fffffff", 16.0), ("80000000", 16.0), ("ff", 16.5),
                    ("ff", -16.0), ("ff", 0.0), ("ff", 4294967312.0)]:
        add("tonumber", s, base)


def ctor_lua(items):
    """Hàm Lua dựng bảng đúng như `{...}` trong mã nguồn. items: danh sách (khoá, giá trị); khoá None là mục danh sách."""
    parts = []
    for key, value in items:
        text = lua_value(value)
        if key is None:
            parts.append(text)
        elif isinstance(key, str) and key.isidentifier():
            parts.append("%s = %s" % (key, text))
        else:
            parts.append("[%s] = %s" % (lua_value(key), text))
    return "function() return {%s} end" % ", ".join(parts)


def build_op_cases():
    """Phép toán của máy ảo (vm.hpp): mỗi ca chạy một hàm Lua nhỏ trên DLL; bản C++ gọi thẳng op tương ứng."""
    add("setup_ops")
    numbers = [0.0, -0.0, 1.0, -1.5, 2147483648.0, 4294967296.0, 1e308, INF, NAN]
    strings = ["10", " 0x1F ", "1e2", "abc", "", "0x", "5 ", "--1"]
    mixed = numbers + strings + [None, True, Tab([])]
    for name in ("add", "sub", "mul", "div", "pow"):
        for a in mixed:
            for b in mixed:
                add("op." + name, a, b)
    # `^` của hai số là XOR 32 bit (LuaPlus đổi OP_POW).
    for a, b in [(2.0, 10.0), (5.0, -1.0), (-1.0, 1.0), (4294967296.0, 1.0), (1.9, 1.9), (3e9, 5.0), (-2147483648.0, 1.0),
                 (1e10, 3.0), (255.0, 15.0), (-5.0, -7.0), (0.5, 0.5), (2147483647.0, 1.0)]:
        add("op.pow", a, b)
    for a in mixed:
        add("op.unm", a)
    objects = [Glob("obj"), Glob("obj_b"), Glob("other"), Glob("plain")]
    operands = objects + [1.0, "s", None]
    for name in ("add", "sub", "mul", "div", "pow", "concat", "eq", "ne", "lt", "le", "gt", "ge"):
        for a in operands:
            for b in operands:
                add("op." + name, a, b)
    add("op.unm", Glob("obj"))
    add("op.unm", Glob("plain"))
    for a in mixed:
        for b in mixed:
            add("op.concat", a, b)
    for a, b, c in [("a", "b", "c"), ("a", 1.0, "c"), (1.0, 2.0, 3.0), ("a", None, "c"), (Glob("obj"), "b", "c"), ("a", Glob("obj"), "c"),
                    ("a", "b", Glob("obj")), (Glob("obj"), Glob("obj_b"), Glob("other")), (1e15, 1e-5, -0.0), ("a", True, "c")]:
        add("op.concat3", a, b, c)
    compare = [0.0, -0.0, 1.0, -1.0, 1e308, INF, -INF, NAN, "", "a", "b", "A", "a\0b", "a\0c", "ab", "z\xff", "z", None, True, False,
               Tab([]), Fn("id"), "1", "10", "9"]
    for name in ("eq", "ne", "lt", "le", "gt", "ge"):
        for a in compare:
            for b in compare:
                add("op." + name, a, b)
    # index / set trên mọi kiểu (LuaPlus dùng bảng riêng của kiểu cho nil, boolean, số, hàm).
    subjects = [Glob("obj"), Glob("plain"), Glob("via_table"), Glob("loop_t"), Glob("fn_index"), "abc", 5.0, True, False, None, Fn("id"),
                Glob("string")]
    keys = ["x", "y", "len", "z", 1.0, "upper", None, 2.5]
    for subject in subjects:
        for key in keys:
            add("op.index", subject, key)
    for subject in [Glob("obj"), Glob("plain"), Glob("via_table"), Glob("loop_t"), "abc", 5.0, True, None, Fn("id")]:
        for key, value in [("x", 7.0), ("k", "v"), (1.0, 2.0), (None, 1.0), (NAN, 1.0), ("x", None)]:
            add("op.setget", subject, key, value)
    # call
    for callee, args in [(Fn("id"), (1.0, 2.0)), (Glob("obj"), (1.0, "x")), (Glob("plain"), ()), (5.0, ()), ("abc", ()), (None, ()),
                         (True, ()), (Fn("err"), ()), (Fn("wrap"), ("a", "b")), (Glob("other"), (Glob("obj"),))]:
        add("op.call", callee, *args)
    # for số
    for a, b in [(1.0, 5.0), (5.0, 1.0), (1.0, 1.0), (0.0, -1.0), (1.5, 4.0), (-2.0, 2.0), ("1", 3.0), (1.0, "3"), ("x", 3.0), (1.0, "x"),
                 (None, 3.0), (1.0, None), (1.0, INF), (-INF, 1.0), (NAN, 1.0), (1.0, NAN), (0.0, 0.3), (1e15, 1e15 + 3), (2147483646.0, 2147483650.0)]:
        add("op.for2", a, b)
    for a, b, c in [(1.0, 5.0, 2.0), (5.0, 1.0, -2.0), (1.0, 5.0, -1.0), (5.0, 1.0, 1.0), (0.0, 1.0, 0.1), (1.0, 0.0, -0.25), (1.0, 5.0, 0.0),
                    (1.0, 3.0, "1"), (1.0, 3.0, "x"), (1.0, 3.0, None), (0.0, 1.0, 0.3), (1.0, 2.0, 0.1), (1e16, 1e16 + 8, 2.0), (1.0, 1.0, INF),
                    (1.0, 100.0, 1e-300), (10.0, 1.0, -3.0), (-0.0, 1.0, 1.0)]:
        add("op.for3", a, b, c)
    # vararg
    add("op.vararg")
    add("op.vararg", 1.0)
    add("op.vararg", 1.0, None, 3.0)
    add("op.vararg", None, None)
    add("op.vararg", *[float(i) for i in range(1, 12)])
    # hàm dựng bảng: hình dạng mã nguồn quyết định cỡ NEWTABLE và thời điểm xả SETLIST, nên thứ tự duyệt
    shapes = {
        "empty": [],
        "list3": [(None, 1.0), (None, 2.0), (None, 3.0)],
        "record3": [("a", 1.0), ("b", 2.0), ("c", 3.0)],
        "list-record": [(None, 1.0), (None, 2.0), (None, 3.0), ("a", 1.0), ("b", 2.0)],
        "record-list": [("a", 1.0), ("b", 2.0), (None, 1.0), (None, 2.0), (None, 3.0)],
        "interleave": [("a", 1.0), (None, "x"), ("b", 2.0), (None, "y"), ("zz", 3.0), (None, "z")],
        "keys-mixed": [("n", 1.0), (None, "x"), (None, "y"), ("z", 2.0), (10.0, 3.0), (2.5, 4.0), ("w", 5.0)],
        "explicit-int": [(1.0, "a"), (2.0, "b"), (4.0, "d"), (3.0, "c")],
        "list-and-explicit": [(None, "a"), (None, "b"), (2.0, "B"), (3.0, "c")],
        "list7": [(None, float(i)) for i in range(1, 8)],
        "list8": [(None, float(i)) for i in range(1, 9)],
        "list9": [(None, float(i)) for i in range(1, 10)],
        "list31": [(None, float(i)) for i in range(1, 32)],
        "list32": [(None, float(i)) for i in range(1, 33)],
        "list33": [(None, float(i)) for i in range(1, 34)],
        "list70": [(None, float(i)) for i in range(1, 71)],
        "list33-record": [(None, float(i)) for i in range(1, 34)] + [("a", 1.0), ("b", 2.0)],
        "record-between-flush": [(None, float(i)) for i in range(1, 33)] + [("a", 1.0)] + [(None, float(i)) for i in range(33, 36)],
        "record5": [("k%d" % i, float(i)) for i in range(5)],
        "record9": [("k%d" % i, float(i)) for i in range(9)],
        "record17": [("k%d" % i, float(i)) for i in range(17)],
        "nil-values": [(None, None), (None, 2.0), ("a", None), ("b", 1.0)],
        # Mục `[khoá] = v` không tính vào cỡ phần băm của NEWTABLE (recfield chỉ tăng cc->nh ở nhánh TK_NAME).
        "bracket-strings": [("a b", 1.0), ("c d", 2.0), ("e f", 3.0), ("g h", 4.0), (None, "x"), (None, "y")],
        "bracket-numbers": [(10.0, 1.0), (11.0, 2.0), (12.0, 3.0), (13.0, 4.0), (None, "x"), (None, "y")],
        "names-and-brackets": [("a", 1.0), (10.0, 2.0), ("b", 3.0), (11.0, 4.0), ("c", 5.0), (None, "x"), (None, "y"), (None, "z")],
    }
    # Cỡ mảng của NEWTABLE (luaO_int2fb làm tròn lên) lộ ra khi khoá nguyên ngay sau mục danh sách được gán TRƯỚC SETLIST: có ô
    # mảng thì vào mảng, không thì vào phần băm.
    for count in (3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 20, 25, 33):
        explicit = [(float(count + 1 + i), "e%d" % i) for i in range(3)]
        listed = [(None, float(i)) for i in range(1, count + 1)]
        shapes["array-%d" % count] = explicit + listed
        shapes["array-%d-records" % count] = [("a", 1.0), ("b", 2.0), ("c", 3.0)] + explicit + listed
    for name, items in shapes.items():
        flat = []
        for key, value in items:
            flat.extend([key, value])
        add("op.ctor", *flat, ident="ctor-" + name, lua_function=ctor_lua(items))


def lua_chunk():
    parts = [PRELUDE]
    for case in CASES:
        parts.append(case_lua(case))
    return "\n".join(parts) + "\n"


# Thứ tự duyệt của _G chụp trước mọi định nghĩa khác (chỉ __emit đã có).
FIRST = r'''
local keys = {}
for k in pairs(_G) do keys[table.getn(keys) + 1] = k end
__emit("globals-order\t" .. table.concat(keys, " "))
'''
# Dòng ngăn hai đoạn trong lib_cases.lua; test C++ tách theo đúng chuỗi này.
MARKER = "-- ==== golden"


def run(bin_folder, output):
    build_cases()
    machine = lua_oracle.Machine(pathlib.Path(bin_folder))
    chunk = lua_chunk()
    machine.run(FIRST, "golden-first")
    machine.run(chunk, "golden")
    program = FIRST.lstrip("\n") + MARKER + "\n" + chunk
    pathlib.Path(output).with_suffix(".lua").write_text(program, encoding="utf-8", newline="\n")
    lines = machine.lines
    out = [
        "# Số vàng của runtime Lua (TOOLS/port/lua_rt_golden.py chạy lời gọi thư viện chuẩn trên LuaPlus.dll). Không sửa tay.",
        "# id\tđường dẫn\tđối số\tkết quả",
        lines[0],
    ]
    by_id = {}
    for line in lines[1:]:
        ident, _, result = line.partition("\t")
        by_id[ident] = result
    index = 0
    for case in CASES:
        result = by_id.pop(case.ident, None)
        if result is None:
            raise SystemExit("thiếu kết quả của ca " + case.ident)
        out.append("\t".join([case.ident, case.path, " ".join(token(arg) for arg in case.args), result]))
        index += 1
    if by_id:
        raise SystemExit("kết quả thừa: " + ", ".join(by_id))
    pathlib.Path(output).write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
    print("đã ghi %d ca vào %s" % (len(CASES), output))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("bin_folder")
    parser.add_argument("output")
    options = parser.parse_args()
    run(options.bin_folder, options.output)


if __name__ == "__main__":
    main()
