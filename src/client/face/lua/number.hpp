// Chuyển tiếp về module luanum (số của script theo MSVCR110): runtime tự viết cũ vẫn gọi tên cũ trong namespace game::lua.
// Tệp tạm cho tới khi runtime ấy dời vào TOOLS/port/luagen/ref_cpp.
#pragma once

#include "luanum/number.hpp"

namespace game::lua {

using luanum::exact_int32;
using luanum::number_to_string;
using luanum::string_to_number;
using luanum::truncate_to_int32;

} // namespace game::lua
