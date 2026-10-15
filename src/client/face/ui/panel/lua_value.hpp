// Chuyển số và chuỗi của script cho các bảng port tay. Phần thật nằm ở module luanum (luanum/number.hpp) để runtime Lua
// dùng chung; tệp này chỉ giữ tên cũ cho các bảng đã port.
#pragma once

#include "luanum/number.hpp"

#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {

// tonumber(text) của script; nullopt là nil.
[[nodiscard]] inline std::optional<double> lua_tonumber(std::string_view text) {
    return luanum::string_to_number(text);
}

// tostring(value) và phép nối `"" .. value` của script (lua_Number2str, "%.14g").
[[nodiscard]] inline std::string lua_tostring(double value) {
    return luanum::number_to_string(value);
}

} // namespace game::ui::panel
