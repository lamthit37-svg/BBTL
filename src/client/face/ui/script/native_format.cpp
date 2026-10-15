#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/message_format.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <cstddef>
#include <expected>
#include <optional>
#include <span>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

constexpr std::string_view kDebugMessageEvent = "NEW_DEBUGMESSAGE";

// Đọc đối số thứ hai trở đi vào args; đối số đầu tiên không phải chuỗi hay số là lỗi với số thứ tự của nó (từ 1).
[[nodiscard]] std::optional<NativeError> read_args(lua_State* lua, std::string_view pattern, std::span<std::string_view> args) {
    for (std::size_t at = 0; at < args.size(); ++at) {
        const std::optional<std::string_view> arg = native::text_arg(lua, static_cast<int>(at) + 2);
        if (!arg) return NativeError::format("LUA: Lua_ScriptGlobal_Format Wrong Param{}! Param0={}", at + 1, pattern);
        args[at] = *arg;
    }
    return std::nullopt;
}

// ScriptGlobal_Format(mẫu[, đối số...]) (Game.exe 0x140233f50): không đối số thì chính chuỗi mẫu thành lời nhắn NEW_DEBUGMESSAGE
// (0x85) và hàm không trả gì; có đối số thì trả chuỗi đã đóng gói (message_format.hpp) mà script đưa cho PushDebugMessage hay hàm
// chat. Mẫu và đối số là chuỗi hay số (lua_isstring); tối đa 15 đối số.
// Khác gốc: chuỗi mẫu rỗng hay lời nhắn quá 1024 byte là lỗi Lua (gốc chết hoặc ghi tràn ngăn xếp).
NativeResult script_global_format(lua_State* lua) {
    const std::optional<std::string_view> raw_pattern = native::text_arg(lua, 1);
    if (!raw_pattern) return std::unexpected(NativeError::of("LUA: Lua_ScriptGlobal_Format Wrong Param0!"));
    const std::string_view pattern = native::c_string(*raw_pattern);
    const auto given = static_cast<std::size_t>(lua_gettop(lua) - 1);
    if (given == 0) {
        const std::array<std::string_view, 1> text = {pattern};
        native::context_of(lua).push_event(kDebugMessageEvent, text);
        return 0;
    }
    if (given > kMessageArgLimit) {
        return std::unexpected(NativeError::format("LUA: Lua_ScriptGlobal_Format too many Params! Param0={}", pattern));
    }
    std::array<std::string_view, kMessageArgLimit> args;
    const std::span<std::string_view> used = std::span(args).first(given);
    if (const std::optional<NativeError> bad = read_args(lua, pattern, used)) return std::unexpected(*bad);
    std::array<char, kMessageBufferSize> buffer{};
    const std::optional<std::size_t> length = pack_message(pattern, used, buffer);
    if (!length) return std::unexpected(NativeError::format("LUA: Lua_ScriptGlobal_Format message too long or empty! Param0={}", pattern));
    lua_pushlstring(lua, buffer.data(), *length);
    return 1;
}

constexpr std::array<native::Entry, 1> kGlobals = {{{.name = "ScriptGlobal_Format", .function = &lua::adapt<script_global_format>}}};

} // namespace

void register_format(lua_State* lua) { native::register_globals(lua, kGlobals); }

} // namespace game::ui::script
