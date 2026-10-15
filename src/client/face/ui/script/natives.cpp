#include "ui/script/natives.hpp"

#include "ui/panel/data_pool.hpp"
#include "ui/script/raise.hpp"

#include <array>
#include <string_view>

extern "C" {
#include "lua.h"
}

namespace game::ui::script {
namespace {

// DataPool:GetUIColor(id) (Game.exe 0x1402e7710): màu chữ và màu viền của dòng id trong SystemColour. Khác gốc: chưa nạp bảng
// nên mọi id trả "-1" "-1" (ui/panel/data_pool.hpp); script đã có màu mặc định cho "-1".
int datapool_get_ui_colour(lua_State* lua) {
    lua_pushlstring(lua, panel::kUiColourMissing.font.data(), panel::kUiColourMissing.font.size());
    lua_pushlstring(lua, panel::kUiColourMissing.extent.data(), panel::kUiColourMissing.extent.size());
    return 2;
}

// DataPool:Check_StringCode(chuỗi) (Game.exe 0x1402e5db0, UI_CEGUI.dll 0x180055430): 1 khi chuỗi hợp lệ, 0 khi kết thúc giữa một
// ký tự hay có byte sai (kiểm theo UTF-8, ui/panel/data_pool.hpp).
// Khác gốc: tham số không phải chuỗi là lỗi Lua (chưa đo hành vi gốc, kho script luôn đưa chuỗi).
int datapool_check_string_code(lua_State* lua) {
    if (lua_isstring(lua, 2) == 0) return raise(lua, "DataPool:Check_StringCode: tham số 1 phải là chuỗi");
    const std::string_view text(lua_tostring(lua, 2), lua_strlen(lua, 2));
    lua_pushnumber(lua, panel::check_string_code(text) ? 1 : 0);
    return 1;
}

struct Method {
    const char* name;
    lua_CFunction function;
};

constexpr std::array<Method, 2> kDataPool = {{
    {.name = "GetUIColor", .function = &datapool_get_ui_colour},
    {.name = "Check_StringCode", .function = &datapool_check_string_code},
}};

} // namespace

void open_natives(lua_State* lua) {
    lua_pushliteral(lua, "DataPool");
    lua_newtable(lua);
    for (const Method& method : kDataPool) {
        lua_pushstring(lua, method.name);
        lua_pushcfunction(lua, method.function);
        lua_rawset(lua, -3);
    }
    lua_settable(lua, LUA_GLOBALSINDEX);
}

} // namespace game::ui::script
