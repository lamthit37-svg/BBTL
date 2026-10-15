#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeResult;

// Sự kiện MESSAGEBOX_COMMON_CLOSE (id 0x23a) mà CloseMessageBoxCommon đẩy (TAILIEU/SU-KIEN-GAME.tsv).
constexpr std::string_view kMessageBoxCommonClose = "MESSAGEBOX_COMMON_CLOSE";
// Số cờ nhắc cập nhật của Lua_GetUpdateTipsFlag (Game.exe 0x14028cb90 so chỉ số không dấu với 100).
constexpr std::size_t kUpdateTipCount = 100;
// Infant:GetMaxSkillNum trả hằng 4.0 (Game.exe 0x14043b980).
constexpr std::int32_t kInfantMaxSkills = 4;

// OSAPI:GetTickCount() (Game.exe 0x14035e8b0): số mili giây của đồng hồ hệ thống, ép (int) nên quấn sang âm sau 2^31 ms.
NativeResult os_get_tick_count(lua_State* lua) {
    const auto ticks = static_cast<std::uint32_t>(native::context_of(lua).facts.clock.count());
    lua_pushnumber(lua, static_cast<std::int32_t>(ticks));
    return 1;
}

// ZBS:IsViewerWatching() (Game.exe 0x1403ca720).
NativeResult zbs_is_viewer_watching(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.viewer_watching);
    return 1;
}

// IsDfsSpeicalServer() (Game.exe 0x14026ab80; chính tả của gốc).
NativeResult is_dfs_special_server(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.dfs_server);
    return 1;
}

NativeResult infant_get_max_skill_num(lua_State* lua) {
    lua_pushnumber(lua, kInfantMaxSkills);
    return 1;
}

// KaJi:LuaFnIsKaJiServer() (Game.exe 0x140346490 -> 0x14050a7c0): 1 khi cảnh hiện tại có dòng trong bảng máy chủ KaJi
// (KaJi_Client_C.cpp, DBC 0x225). Khác gốc: client chưa nạp bảng đó, tức bảng rỗng, nên mọi cảnh đều không phải máy chủ KaJi.
NativeResult kaji_is_server(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

// KaJi:LuaFnGetKaJiType(số) (Game.exe 0x140346410 -> 0x14050a6b0): loại KaJi của dòng khớp cảnh hiện tại, 0 khi không có. Cùng
// Khác gốc với kaji_is_server (bảng rỗng nên luôn 0); phần kiểm đối số giữ nguyên.
NativeResult kaji_get_type(lua_State* lua) {
    if (!native::strict_number(lua, 2)) return std::unexpected(lua::NativeError::of("LUA:LuaFnGetKaJiType param parameter1 error"));
    lua_pushnumber(lua, 0);
    return 1;
}

// CloseMessageBoxCommon() (Game.exe 0x1402567a0): đẩy sự kiện MESSAGEBOX_COMMON_CLOSE, không đối số.
NativeResult close_message_box_common(lua_State* lua) {
    native::context_of(lua).push_event(kMessageBoxCommonClose, std::span<const std::string_view>{});
    return 0;
}

// DataPool:SetCanUseHotKey(số) (Game.exe 0x1402ea380): cất số (int); đối số không phải số nghiêm thì bỏ qua, không báo lỗi.
NativeResult datapool_set_can_use_hot_key(lua_State* lua) {
    if (const std::optional<double> value = native::strict_number(lua, 2)) native::context_of(lua).can_use_hotkey = native::to_int(*value);
    return 0;
}

// DataPool:Lua_GetUpdateTipsFlag(chỉ số) (Game.exe 0x14028cb90): cờ thứ chỉ số trong 100 cờ; ngoài 0..99 (kể cả âm: gốc so không dấu)
// thì 0.
NativeResult datapool_get_update_tips_flag(lua_State* lua) {
    const std::optional<double> index = native::strict_number(lua, 2);
    if (!index) return std::unexpected(lua::NativeError::of("Lua_GetUpdateTipsFlag parameter error!"));
    const auto slot = static_cast<std::uint32_t>(native::to_int(*index));
    const Facts& facts = native::context_of(lua).facts;
    lua_pushnumber(lua, slot < kUpdateTipCount ? facts.update_tips.at(slot) : 0);
    return 1;
}

constexpr std::array<native::Entry, 1> kOsApi = {{{.name = "GetTickCount", .function = &lua::adapt<os_get_tick_count>}}};
constexpr std::array<native::Entry, 1> kZbs = {{{.name = "IsViewerWatching", .function = &lua::adapt<zbs_is_viewer_watching>}}};
constexpr std::array<native::Entry, 1> kInfant = {{{.name = "GetMaxSkillNum", .function = &lua::adapt<infant_get_max_skill_num>}}};
constexpr std::array<native::Entry, 2> kKaJi = {{
    {.name = "LuaFnIsKaJiServer", .function = &lua::adapt<kaji_is_server>},
    {.name = "LuaFnGetKaJiType", .function = &lua::adapt<kaji_get_type>},
}};
constexpr std::array<native::Entry, 2> kDataPool = {{
    {.name = "SetCanUseHotKey", .function = &lua::adapt<datapool_set_can_use_hot_key>},
    {.name = "Lua_GetUpdateTipsFlag", .function = &lua::adapt<datapool_get_update_tips_flag>},
}};
constexpr std::array<native::Entry, 2> kGlobals = {{
    {.name = "IsDfsSpeicalServer", .function = &lua::adapt<is_dfs_special_server>},
    {.name = "CloseMessageBoxCommon", .function = &lua::adapt<close_message_box_common>},
}};

} // namespace

void register_system(lua_State* lua) {
    native::register_table(lua, "OSAPI", kOsApi);
    native::register_table(lua, "ZBS", kZbs);
    native::register_table(lua, "Infant", kInfant);
    native::register_table(lua, "KaJi", kKaJi);
    native::register_table(lua, "DataPool", kDataPool);
    native::register_globals(lua, kGlobals);
}

} // namespace game::ui::script
