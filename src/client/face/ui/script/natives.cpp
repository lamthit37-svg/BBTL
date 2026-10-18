#include "ui/script/natives.hpp"

#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/panel/data_pool.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <expected>
#include <functional>
#include <optional>
#include <string_view>

namespace game::ui::script {
namespace {

// DataPool:GetUIColor(id) (Game.exe 0x1402e7710): màu chữ và màu viền của dòng id trong SystemColour. Khác gốc: chưa nạp bảng
// nên mọi id trả "-1" "-1" (ui/panel/data_pool.hpp); script đã có màu mặc định cho "-1".
int datapool_get_ui_colour(lua_State* lua) {
    lua_pushlstring(lua, panel::kUiColourMissing.font.data(), panel::kUiColourMissing.font.size());
    lua_pushlstring(lua, panel::kUiColourMissing.extent.data(), panel::kUiColourMissing.extent.size());
    return 2;
}

// DataPool:Check_StringCode(chuỗi) (Game.exe 0x1402e6cd0 và 0x1402e5db0, UI_CEGUI.dll 0x180055430): 1 khi chuỗi hợp lệ, 0 khi
// kết thúc giữa một ký tự hay có byte sai (kiểm theo UTF-8, ui/panel/data_pool.hpp). Đối số không phải chuỗi hay số: câu lỗi của gốc.
lua::NativeResult datapool_check_string_code(lua_State* lua) {
    const std::optional<std::string_view> text = native::text_arg(lua, 2);
    if (!text) return std::unexpected(lua::NativeError::of("LUA:Check_StringCode Param error"));
    lua_pushnumber(lua, panel::check_string_code(*text) ? 1 : 0);
    return 1;
}

constexpr std::array<native::Entry, 2> kDataPool = {{
    {.name = "GetUIColor", .function = &datapool_get_ui_colour},
    {.name = "Check_StringCode", .function = &lua::adapt<datapool_check_string_code>},
}};

} // namespace

void open_natives(lua_State* lua) {
    native::register_table(lua, "DataPool", kDataPool);
    register_a_vcall(lua);
    register_a_trade(lua);
    register_xscript(lua);
    register_variable(lua);
    register_world(lua);
    register_format(lua);
    register_player(lua);
    register_system(lua);
    register_events(lua);
    register_pool(lua);
    register_state(lua);
    register_pet(lua);
    register_target(lua);
    register_battle(lua);
    register_character(lua);
    register_mission(lua);
    register_login(lua);
}

std::function<void(lua_State*)> make_natives(Context& context) {
    return [&context](lua_State* lua) {
        open_natives(lua);
        native::attach(lua, context);
    };
}

} // namespace game::ui::script
