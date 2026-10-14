-- Số vàng cho ui/panel/lua_value (tonumber và tostring của LuaPlus.dll trong client 2026). Mượn
-- ProgressBar.lua làm script nền chỉ vì trọng tài cần một script; kịch bản không đụng cửa sổ nào.
-- Toán tử ^ của LuaPlus là xor chứ không phải luỹ thừa (2 ^ 53 ra 55): kịch bản không dùng nó.
-- Dòng ra: "tonumber<tab>các byte của chuỗi dạng hex<tab>kết quả" (kết quả là "nil" hay số theo
-- tostring) và "tostring<tab>số theo %.17g (hay inf, -inf, nan)<tab>kết quả".
--@steps
local function hex(text)
    local out = ""
    for index = 1, string.len(text) do
        out = out .. string.format("%02x", string.byte(text, index))
    end
    return out
end

local texts = {
    "0.25", "  7  ", "\t7\n", "7\v", "\f7", "5d-1", "1D2", "1e2", "1E2", "1e+2", "+5", "-5", "5.", ".5", "-.5",
    ".", "", "-", "+", "+-5", "1e", "1e+", "1e-", "1ee2", "1e2.5", "0x1", "0x", "0X1F", "abc", "1,5", "1.5.5",
    "5 5", "5 x", "inf", "-inf", "nan", "infinity", "1.#INF", "1e999", "-1e999", "1e-400", "-1e-400",
    "123456789012345678901234567890", "-0", "0", "00012", "1_000", "5\0", "\0005", "1d", "1d+", "1.e3",
    "1.5e+3", "  -  5", "- 5", "0.1e1", "100", "1e14", "1e15", "1e16", "0.000001", "0.00001", "12345678901234567",
    string.rep("9", 400), "0." .. string.rep("0", 400) .. "1",
}
for _, text in ipairs(texts) do
    __emit("tonumber\t" .. hex(text) .. "\t" .. tostring(tonumber(text)))
end

local huge = 1e999
local numbers = {
    0, -0, 1, -1, 0.1, 0.5, 100, 1e5, 99999999999999, 1e14, 1e15, 1e16, 1e21, 123456789012345.6, 1 / 3, 2 / 3,
    1e-4, 1e-5, 1.5e-7, 1e100, 1e300, -1e-300, 5e-324, 9007199254740992, 9223372036854775808, 0.30000000000000004, 12345678901234567890,
    0.1 + 0.2, 1e-5 * 3, 123456.789e3, -123456.789e-3,
}
for _, number in ipairs(numbers) do
    __emit("tostring\t" .. string.format("%.17g", number) .. "\t" .. tostring(number))
end
__emit("tostring\tinf\t" .. tostring(huge))
__emit("tostring\t-inf\t" .. tostring(-huge))
__emit("tostring\tnan\t" .. tostring(huge - huge))
