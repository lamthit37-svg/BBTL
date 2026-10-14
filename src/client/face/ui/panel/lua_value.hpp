// Chuyển số và chuỗi như hai hàm của Lua 5.0 trong LuaPlus.dll của client 2026 (tonumber và phép
// nối số vào chuỗi), cho những bảng port từ script mà script đó nhận số dạng chuỗi từ sự kiện của
// game (arg0, arg1...) hay ghép số vào chữ.
// Đo trên chính LuaPlus.dll của D:\XTLBB\Bin64 bằng TOOLS/port/lua_oracle.py (kịch bản
// TOOLS/port/oracle/lua_number_cases.lua, số vàng Test/golden/panel/lua_number_cases.tsv):
// - tonumber nhận khoảng trắng hai đầu, dấu +/-, "5.", ".5", số mũ e hoặc d; không nhận số thập lục
//   phân, "inf", "nan", chuỗi rỗng; chuỗi dừng ở byte NUL đầu tiên như chuỗi C.
// - số tràn thành vô cực, số quá nhỏ thành +0 kể cả khi âm (strtod của MSVCR110); chuỗi "-0" ra -0.
// - nối số vào chuỗi theo "%.14g" của MSVCR110: số mũ luôn có ba chữ số ("1e+015"), vô cực là
//   "1.#INF", NaN là "1.#QNAN" hay "-1.#IND" theo dấu.
#pragma once

#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {

// tonumber(text) của script; nullopt là nil.
[[nodiscard]] std::optional<double> lua_tonumber(std::string_view text);

// tostring(value) và phép nối `"" .. value` của script (lua_Number2str, "%.14g").
[[nodiscard]] std::string lua_tostring(double value);

} // namespace game::ui::panel
