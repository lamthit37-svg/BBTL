-- Thế giới giả cho đối soát hàng loạt của LUA-GEN (docs/giao-viec/LUA-GEN/THIET-KE.md, mục "Đối soát hàng loạt").
-- Phía gốc: TOOLS/port/luagen/mass_oracle.py chạy nguyên văn tệp này trên LuaPlus.dll của client 2026. Phía C++:
-- thienlong_lua_mass chạy bản dịch của chính tệp này trên runtime `lua`. Hai phía dùng một thế giới, chỉ khác bản dịch
-- và runtime, nên vết khác nhau một byte là lỗi của bộ dịch hay runtime.
--
-- Viết bằng Lua 5.0.1 (không `#`, `%`, `select`). Vết tất định: không in địa chỉ, không duyệt bảng có khoá là bảng,
-- mọi số "ngẫu nhiên" từ một dãy Park-Miller trên số nguyên dưới 2^46 (đúng tuyệt đối trong double).
-- Chủ đưa vào một hàm toàn cục __emit(chuỗi): mỗi lần gọi là một dòng vết.
--
-- Dòng vết:
--   call<TAB>tên<TAB>giá trị...   một lời gọi vào thế giới (hàm hay phương thức của game, print)
--   step<TAB>nhãn                 bộ chạy bắt đầu một bước
--   !err                          bước (hay chunk) vừa chạy dừng vì lỗi; câu lỗi không so
-- Giá trị: nil, true, false, n<tostring của số>, s<số byte>:<byte>, p:<tên đối tượng giả>, table, function.

local emit = __emit
local raw_tostring = tostring
local insert = table.insert
local concat = table.concat
local find = string.find
local mod = math.mod
local floor = math.floor

-- Dãy tất định chung cho mọi giá trị thế giới trả về và mọi đối số bộ chạy đưa vào.
local seed = 20261015
local function roll()
    seed = mod(seed * 16807, 2147483647)
    return seed
end

-- Đối tượng giả: bảng rỗng có bảng meta; tên giữ ở bảng phụ (chỉ tra, không duyệt).
local names = {}
local proxy_meta = {}

local function make_proxy(name)
    local made = {}
    names[made] = name
    setmetatable(made, proxy_meta)
    return made
end

local function describe(value)
    local kind = type(value)
    if kind == "nil" then return "nil" end
    if kind == "boolean" then
        if value then return "true" end
        return "false"
    end
    if kind == "number" then return "n" .. raw_tostring(value) end
    if kind == "string" then return "s" .. string.len(value) .. ":" .. value end
    if kind == "table" then
        local name = names[value]
        if name then return "p:" .. name end
        return "table"
    end
    return kind
end

-- Giá trị một lời gọi vào thế giới trả về, theo tên (để script đi được sâu: hàm hỏi tên ra chuỗi, hàm hỏi Is/Has ra
-- 0 hay 1, hàm trả cửa sổ ra đối tượng giả), một phần hai mươi là nil.
local function answer(name)
    local pick = roll()
    if mod(pick, 20) == 0 then return nil end
    if find(name, "Window", 1, true) or find(name, "Wnd", 1, true) or find(name, "Ctrl", 1, true) then
        return make_proxy("ret:" .. name)
    end
    if find(name, "Name", 1, true) or find(name, "Text", 1, true) or find(name, "Str", 1, true)
        or find(name, "Desc", 1, true) or find(name, "Tip", 1, true) then
        return "s" .. mod(pick, 97), mod(roll(), 10)
    end
    if find(name, ".Is", 1, true) or find(name, ".Has", 1, true) or find(name, ".Can", 1, true) then
        return mod(pick, 2)
    end
    return mod(pick, 10), mod(roll(), 100)
end

-- Trần lời gọi vào thế giới của một bước: vòng lặp chờ giá trị giả làm điều kiện dừng đúng thì dừng ở đây bằng lỗi,
-- cùng một chỗ ở hai phía (logic Lua thuần), thay vì chạy tới trần lệnh của máy.
local kStepCalls = 5000
local step_calls = 0

local function record(name, values)
    step_calls = step_calls + 1
    if step_calls > kStepCalls then error("vượt trần lời gọi của một bước") end
    local parts = { "call", name }
    for index = 1, values.n do
        parts[index + 2] = describe(values[index])
    end
    emit(concat(parts, "\t"))
    return answer(name)
end

-- Sự kiện mà this:RegisterEvent đã đăng ký, theo thứ tự.
local events = {}

proxy_meta.__index = function(proxy, key)
    local name = names[proxy] .. "." .. raw_tostring(key)
    local method
    if name == "this.RegisterEvent" then
        method = function(...)
            local values = arg
            if type(values[2]) == "string" then insert(events, values[2]) end
            return record(name, values)
        end
    else
        method = function(...) return record(name, arg) end
    end
    rawset(proxy, key, method)
    return method
end

-- Hàm cơ sở có kết quả không tất định hay ra ngoài máy: thay bằng bản tất định ghi vết.
print = function(...) record("print", arg) end
tostring = function(value)
    local kind = type(value)
    if kind == "table" then
        local name = names[value]
        if name then return "proxy:" .. name end
        return "table"
    end
    if kind == "function" then return "function" end
    return raw_tostring(value)
end
-- math.random của lmathlib 5.0 trên dãy của thế giới: không đối số ra [0,1), một đối số m ra [1,m], hai đối số ra [m,n].
math.random = function(low, high)
    local unit = (roll() - 1) / 2147483646
    if low == nil then return unit end
    if high == nil then return floor(unit * low) + 1 end
    return floor(unit * (high - low + 1)) + low
end
math.randomseed = function(...) record("math.randomseed", arg) end

-- Đoạn Lua nối sự kiện của layout: mỗi chunk của đoạn gọi __handler một lần lúc nạp.
local handlers = {}
function __handler(window, event, body)
    insert(handlers, { window, event, body })
end

-- Hàm toàn cục được định nghĩa (gán giá trị hàm vào tên chưa có), theo thứ tự.
local defined = {}

this = make_proxy("this")

local function step(label, callee, a, b)
    emit("step\t" .. label)
    step_calls = 0
    local ok = pcall(callee, a, b)
    if not ok then emit("!err") end
end

-- Đặt arg0..arg5 như UI_CEGUI.dll 0x18007b8e0: chuỗi, vào biến toàn cục.
local function set_event_args()
    for index = 0, 5 do
        rawset(_G, "arg" .. index, raw_tostring(mod(roll(), 50)))
    end
end

local function ends_with(text, tail)
    local size = string.len(tail)
    return string.len(text) >= size and string.sub(text, -size) == tail
end

-- Bộ chạy, gọi sau khi mọi chunk của cửa sổ đã nạp.
function __drive()
    local preload, onload, onevent = {}, {}, {}
    for index = 1, table.getn(defined) do
        local name = defined[index]
        if ends_with(name, "_PreLoad") then insert(preload, name) end
        if ends_with(name, "_OnLoad") then insert(onload, name) end
        if ends_with(name, "_OnEvent") then insert(onevent, name) end
    end
    for index = 1, table.getn(preload) do step(preload[index], rawget(_G, preload[index])) end
    for index = 1, table.getn(onload) do step(onload[index], rawget(_G, onload[index])) end
    for index = 1, table.getn(events) do
        for round = 1, 3 do
            set_event_args()
            for which = 1, table.getn(onevent) do
                step(onevent[which] .. " " .. events[index], rawget(_G, onevent[which]), events[index])
            end
        end
    end
    for index = 1, table.getn(handlers) do
        local item = handlers[index]
        set_event_args()
        step("handler " .. item[1] .. " " .. item[2], item[3])
    end
    for index = 1, table.getn(defined) do
        local name = defined[index]
        local callee = rawget(_G, name)
        if type(callee) == "function" then
            step("call " .. name, callee, mod(roll(), 10), mod(roll(), 10))
        end
    end
end

-- Cuối cùng mới gắn bảng meta cho _G, để các tên của chính tệp này không thành đối tượng giả hay hàm "định nghĩa".
setmetatable(_G, {
    __index = function(globals, key)
        if type(key) ~= "string" then return nil end
        local made = make_proxy(key)
        rawset(globals, key, made)
        return made
    end,
    __newindex = function(globals, key, value)
        if type(value) == "function" and type(key) == "string" then insert(defined, key) end
        rawset(globals, key, value)
    end,
})
