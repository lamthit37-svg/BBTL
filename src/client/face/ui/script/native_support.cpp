#include "ui/script/native_support.hpp"

#include "core/check.hpp"
#include "lua/capi.hpp"
#include "luanum/luanum.h"
#include "ui/script/context.hpp"

#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

namespace game::ui::script::native {
namespace {

// Địa chỉ của biến này làm khoá lightuserdata trong registry.
[[nodiscard]] void* context_key() noexcept {
    static char key = 0;
    return &key;
}

void set_field(lua_State* lua, const Entry& entry, int table_index) {
    lua_pushstring(lua, entry.name);
    lua_pushcfunction(lua, entry.function);
    lua_rawset(lua, table_index);
}

} // namespace

void register_globals(lua_State* lua, std::span<const Entry> entries) {
    for (const Entry& entry : entries) set_field(lua, entry, LUA_GLOBALSINDEX);
}

void register_table(lua_State* lua, const char* table, std::span<const Entry> entries) {
    lua_pushstring(lua, table);
    lua_rawget(lua, LUA_GLOBALSINDEX);
    if (lua_istable(lua, -1) == 0) {
        lua_pop(lua, 1);
        lua_newtable(lua);
        lua_pushstring(lua, table);
        lua_pushvalue(lua, -2);
        lua_rawset(lua, LUA_GLOBALSINDEX);
    }
    for (const Entry& entry : entries) set_field(lua, entry, -3);
    lua_pop(lua, 1);
}

void attach(lua_State* lua, Context& context) {
    lua_pushlightuserdata(lua, context_key());
    lua_pushlightuserdata(lua, &context);
    lua_rawset(lua, LUA_REGISTRYINDEX);
}

Context& context_of(lua_State* lua) {
    lua_pushlightuserdata(lua, context_key());
    lua_rawget(lua, LUA_REGISTRYINDEX);
    auto* const context = static_cast<Context*>(lua_touserdata(lua, -1));
    lua_pop(lua, 1);
    core::check(context != nullptr, "ui/script: state chưa được attach Context (open_natives)");
    return *context;
}

std::optional<double> strict_number(lua_State* lua, int index) {
    if (lua_type(lua, index) != LUA_TNUMBER) return std::nullopt;
    return lua_tonumber(lua, index);
}

std::optional<std::string_view> text_arg(lua_State* lua, int index) {
    if (lua_isstring(lua, index) == 0) return std::nullopt;
    const char* const text = lua_tostring(lua, index);
    return std::string_view(text, lua_strlen(lua, index));
}

std::int32_t to_int(double value) noexcept { return luanum_to_int32(value); }

int type_at(lua_State* lua, int index) { return lua_type(lua, index); }

} // namespace game::ui::script::native
