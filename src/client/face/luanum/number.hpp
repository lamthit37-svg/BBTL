// Chuyển số và chuỗi như hai hàm của Lua 5.0 trong LuaPlus.dll của client 2026 (luaO_str2d của tonumber và
// ép chuỗi sang số, lua_number2str của phép nối số vào chuỗi và tostring). Dùng chung cho LuaPlus (qua luanum.h), cho các
// bảng port tay từ script (ui/panel/lua_value.hpp chuyển tiếp về đây) và cho runtime Lua tự viết cũ (TOOLS/port/luagen/ref_cpp).
// Đo trên chính LuaPlus.dll của D:\XTLBB\Bin64 bằng TOOLS/port/lua_oracle.py (kịch bản
// TOOLS/port/oracle/lua_number_cases.lua, số vàng Test/golden/panel/lua_number_cases.tsv):
// - tonumber nhận khoảng trắng hai đầu, dấu +/-, "5.", ".5", số mũ e hoặc d; không nhận số thập lục
//   phân, "inf", "nan", chuỗi rỗng; chuỗi dừng ở byte NUL đầu tiên như chuỗi C.
// - số tràn thành vô cực, số quá nhỏ thành +0 kể cả khi âm (strtod của MSVCR110); chuỗi "-0" ra -0.
// - nối số vào chuỗi theo "%.14g" của MSVCR110: số mũ luôn có ba chữ số ("1e+015"), vô cực là
//   "1.#INF", NaN là "1.#QNAN" hay "-1.#IND" theo dấu.
#pragma once

#include "luanum/luanum.h"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::luanum {

// (int)n của C trên x86, nhưng không UB: ngoài miền int32 và NaN cho INT32_MIN như cvttsd2si, chỗ LuaPlus.dll dựng
// bằng MSVC x64 ép số sang int (lua_number2int, luaL_checkint). Phần lẻ bị cắt về 0.
[[nodiscard]] constexpr std::int32_t truncate_to_int32(double n) noexcept {
    return luanum_to_int32(n);
}

// n có phải số nguyên nằm trong int32 không (ép sang int rồi ép ngược về bằng chính n, như ltable.c). -0.0 là 0.
[[nodiscard]] constexpr std::optional<std::int32_t> exact_int32(double n) noexcept {
    // Điều kiện miền viết theo chiều "phải đúng" để NaN rơi ra ngoài (UB-05).
    if (n >= -2147483648.0 && n <= 2147483647.0) {
        const auto whole = static_cast<std::int32_t>(n);
        if (static_cast<double>(whole) == n) return whole;
    }
    return std::nullopt;
}

// tonumber(text) của script (luaO_str2d); nullopt là nil.
[[nodiscard]] std::optional<double> string_to_number(std::string_view text);

// tostring(value) và phép nối `"" .. value` của script (lua_Number2str, "%.14g").
[[nodiscard]] std::string number_to_string(double value);

// Phần số ở đầu một chuỗi như strtod của MSVCR110 thấy (luanum_strtod): [begin, end) là khoảng đã nhận, kể cả dấu; found
// là false khi không có chữ số nào. Chỉ dành cho luanum.cpp và string_to_number.
struct NumberPrefix {
    std::size_t begin = 0;
    std::size_t end = 0;
    bool found = false;
};
[[nodiscard]] NumberPrefix scan_number(std::string_view text) noexcept;
// Giá trị của khoảng prefix đã quét (số tràn thành vô cực, số âm quá nhỏ thành +0).
[[nodiscard]] double convert_number(std::string_view text, const NumberPrefix& prefix);

} // namespace game::luanum
