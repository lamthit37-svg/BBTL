// Chuyển tiếp về module luanum (sprintf của MSVCR110): runtime tự viết cũ vẫn gọi tên cũ trong namespace game::lua.
// Tệp tạm cho tới khi runtime ấy dời vào TOOLS/port/luagen/ref_cpp.
#pragma once

#include "luanum/cformat.hpp"

namespace game::lua {

using luanum::format_char;
using luanum::format_double;
using luanum::format_signed;
using luanum::format_text;
using luanum::format_unsigned;
using luanum::FormatSpec;

} // namespace game::lua
