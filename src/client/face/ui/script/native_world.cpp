#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <cstdint>
#include <optional>

namespace game::ui::script {
namespace {

using lua::NativeResult;

// Cảnh Võ Lâm Chi Điên: ba id liền nhau từ 0x2f1 (Game.exe 0x1404e3f50 và 0x1404e4a10 cùng một thân).
constexpr std::int32_t kWuLinFirstScene = 0x2f1;
constexpr std::int32_t kWuLinSceneCount = 3;

void push_scene_or_missing(lua_State* lua, const Context& context) {
    lua_pushnumber(lua, context.facts.scene_id.value_or(-1));
}

// DataPool:GetCurDialogNpcId() (0x1402ccea0): id máy chủ của NPC đang hội thoại, -1 khi không có.
NativeResult get_cur_dialog_npc_id(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.dialog_npc_id.value_or(-1));
    return 1;
}

// DataPool:LuaFnGetGMVisibleType() (0x14031b6b0): byte ở DataPool + 0x632bd8.
NativeResult get_gm_visible_type(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.gm_visible_type);
    return 1;
}

// SystemSetup:IsClassic() (0x140460770): luôn 1 (bản 3.71.9509 chỉ còn chế độ classic).
NativeResult is_classic(lua_State* lua) {
    lua_pushnumber(lua, 1);
    return 1;
}

// WuLinZhiDian:IsWuLinZhiDianScene() (0x1404e3f50) và JueZhanWuLinZhiDian:IsJueZhanWuLinZhiDianScene() (0x1404e4a10): 1 khi cảnh
// hiện tại có id trong [0x2f1, 0x2f1 + 3), -1 khi khác hay chưa vào cảnh.
NativeResult is_wulin_scene(lua_State* lua) {
    const std::optional<std::int32_t> scene = native::context_of(lua).facts.scene_id;
    const bool is_wulin = scene && *scene >= kWuLinFirstScene && *scene < kWuLinFirstScene + kWuLinSceneCount;
    lua_pushnumber(lua, is_wulin ? 1 : -1);
    return 1;
}

// CSongliaoWarData:TSLGetLocalSceneID() (0x1403b71f0): id cảnh hiện tại, -1 khi chưa vào cảnh.
NativeResult tsl_get_local_scene_id(lua_State* lua) {
    push_scene_or_missing(lua, native::context_of(lua));
    return 1;
}

// GetSceneID() (0x140239030): id cảnh hiện tại; chưa vào cảnh thì không trả gì (script nhận nil).
NativeResult get_scene_id(lua_State* lua) {
    const std::optional<std::int32_t> scene = native::context_of(lua).facts.scene_id;
    if (!scene) return 0;
    lua_pushnumber(lua, *scene);
    return 1;
}

// IsZbs2018SpeicalServer() (0x14026ab00; chính tả của gốc): số ở DataPool + 0x632c0c, khác 0 là máy chủ đặc biệt 2018.
NativeResult is_zbs2018_special_server(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.zbs2018_server);
    return 1;
}

constexpr std::array<native::Entry, 2> kDataPool = {{
    {.name = "GetCurDialogNpcId", .function = &lua::adapt<get_cur_dialog_npc_id>},
    {.name = "LuaFnGetGMVisibleType", .function = &lua::adapt<get_gm_visible_type>},
}};
constexpr std::array<native::Entry, 1> kSystemSetup = {{{.name = "IsClassic", .function = &lua::adapt<is_classic>}}};
constexpr std::array<native::Entry, 1> kWuLin = {{{.name = "IsWuLinZhiDianScene", .function = &lua::adapt<is_wulin_scene>}}};
constexpr std::array<native::Entry, 1> kJueZhan = {{{.name = "IsJueZhanWuLinZhiDianScene", .function = &lua::adapt<is_wulin_scene>}}};
constexpr std::array<native::Entry, 1> kSongliao = {{{.name = "TSLGetLocalSceneID", .function = &lua::adapt<tsl_get_local_scene_id>}}};
constexpr std::array<native::Entry, 2> kGlobals = {{
    {.name = "GetSceneID", .function = &lua::adapt<get_scene_id>},
    {.name = "IsZbs2018SpeicalServer", .function = &lua::adapt<is_zbs2018_special_server>},
}};

} // namespace

void register_world(lua_State* lua) {
    native::register_table(lua, "DataPool", kDataPool);
    native::register_table(lua, "SystemSetup", kSystemSetup);
    native::register_table(lua, "WuLinZhiDian", kWuLin);
    native::register_table(lua, "JueZhanWuLinZhiDian", kJueZhan);
    native::register_table(lua, "CSongliaoWarData", kSongliao);
    native::register_globals(lua, kGlobals);
}

} // namespace game::ui::script
