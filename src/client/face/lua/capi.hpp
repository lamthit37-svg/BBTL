// Cửa vào duy nhất của C API của LuaPlus 5.0.1 (third_party/luaplus) cho mã C++ của dự án. Header của LuaPlus là mã C không có
// extern "C"; bọc ở đây một lần để mọi nơi khác include "lua/capi.hpp" thay vì tự bọc.
//
// LuaPlus báo lỗi bằng longjmp (không phải ngoại lệ C++). Hệ quả cho mã C++ gọi API: một lời gọi API có thể cấp phát hay kiểm
// kiểu (lua_pushstring, lua_newtable, luaL_checknumber, lua_error...) nhảy thẳng tới lua_pcall gần nhất, bỏ qua mọi destructor của
// các khung C++ ở giữa. Quy tắc viết hàm C++ gọi API: xem lua/native.hpp.
#pragma once

// IWYU pragma: export — để misc-include-cleaner coi các ký hiệu Lua là do "lua/capi.hpp" cung cấp.
extern "C" {
#include "lauxlib.h"       // IWYU pragma: export
#include "lua.h"           // IWYU pragma: export
#include "LuaPlusAddons.h" // IWYU pragma: export — sau lua.h, vì dùng LUA_API của nó
#include "lualib.h"        // IWYU pragma: export
}
