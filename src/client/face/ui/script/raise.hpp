// Báo lỗi Lua từ hàm C mà script gọi (ui/script). LuaPlus 5.0.1 báo lỗi bằng longjmp: hàm gọi chúng không được giữ đối tượng
// C++ có destructor, nên không dùng luaL_error (hàm vararg của C, cũng không qua clang-tidy): thông điệp ghép bằng lua_concat từ
// các giá trị đã đẩy sẵn, vị trí trong script (luaL_where) đứng đầu như luaL_error.
// Chỉ C API của Lua, dựng được ở mọi nền tảng.
#pragma once

extern "C" {
#include "lauxlib.h"
#include "lua.h"
}

namespace game::ui::script {

// Thông điệp là pieces giá trị (chuỗi hay số) vừa đẩy lên đỉnh ngăn xếp. Không bao giờ trả về (longjmp), kiểu int để viết
// `return raise_pushed(...)` trong hàm lua_CFunction.
inline int raise_pushed(lua_State* lua, int pieces) {
    luaL_where(lua, 1);
    lua_insert(lua, -pieces - 1);
    lua_concat(lua, pieces + 1);
    return lua_error(lua);
}

// Thông điệp là một chuỗi C có sẵn.
inline int raise(lua_State* lua, const char* message) {
    lua_pushstring(lua, message);
    return raise_pushed(lua, 1);
}

} // namespace game::ui::script
