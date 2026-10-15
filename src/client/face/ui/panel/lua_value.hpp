// Chuyển số và chuỗi của script cho các bảng port tay. Phần thật nằm ở module lua (lua/number.hpp) để runtime Lua
// dùng chung; tệp này chỉ giữ tên cũ cho các bảng đã port.
#pragma once

#include "lua/number.hpp"

#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {

// tonumber(text) của script; nullopt là nil.
[[nodiscard]] inline std::optional<double> lua_tonumber(std::string_view text) {
    return lua::string_to_number(text);
}

// tostring(value) và phép nối `"" .. value` của script (lua_Number2str, "%.14g").
[[nodiscard]] inline std::string lua_tostring(double value) {
    return lua::number_to_string(value);
}

} // namespace game::ui::panel
