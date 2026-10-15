#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/variable.hpp"

#include <array>
#include <expected>
#include <optional>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

constexpr std::string_view kChangedEvent = "VARIABLE_CHANGED";

// Variable:GetVariable(tên) (Game.exe 0x1406b0990): giá trị chuỗi của biến, hay nil khi tên không phải chuỗi hay chưa có biến đó.
NativeResult get_variable(lua_State* lua) {
    const std::optional<std::string_view> name = native::text_arg(lua, 2);
    if (!name) {
        lua_pushnil(lua);
        return 1;
    }
    const std::optional<std::string_view> value = native::context_of(lua).variables.get(native::c_string(*name));
    if (value) {
        lua_pushlstring(lua, value->data(), value->size());
    } else {
        lua_pushnil(lua);
    }
    return 1;
}

// Variable:SetVariable(tên, giá trị, cờ) (0x1406b0870): tên và giá trị là chuỗi hay số, cờ là số nghiêm. Cờ gốc lưu cạnh giá trị cho
// việc ghi cấu hình; chưa dùng. Giá trị đổi thì sự kiện VARIABLE_CHANGED (tên, giá trị mới).
NativeResult set_variable(lua_State* lua) {
    const std::optional<std::string_view> name = native::text_arg(lua, 2);
    if (!name) return std::unexpected(NativeError::of("LUA:CVariableSystem::Lua_SetGlobalVariable[2] param parameter error"));
    const std::optional<std::string_view> value = native::text_arg(lua, 3);
    if (!value) return std::unexpected(NativeError::of("LUA:CVariableSystem::Lua_SetGlobalVariable[3] param parameter error"));
    if (!native::strict_number(lua, 4)) {
        return std::unexpected(NativeError::of("LUA:CVariableSystem::Lua_SetGlobalVariable[4] param parameter error"));
    }
    Context& context = native::context_of(lua);
    if (const std::optional<VariableChange> change = context.variables.set(native::c_string(*name), native::c_string(*value))) {
        const std::array<std::string_view, 2> args = {change->name, change->value};
        context.push_event(kChangedEvent, args);
    }
    return 0;
}

constexpr std::array<native::Entry, 2> kVariable = {{
    {.name = "GetVariable", .function = &lua::adapt<get_variable>},
    {.name = "SetVariable", .function = &lua::adapt<set_variable>},
}};

} // namespace

void register_variable(lua_State* lua) { native::register_table(lua, "Variable", kVariable); }

} // namespace game::ui::script
