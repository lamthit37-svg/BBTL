#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/panel/scene_table.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

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

// Cảnh có id (client resid) này trong các hàm kiểm cảnh đặc biệt của gốc.
constexpr std::array<std::int32_t, 3> kTServerScenes = {0x28a, 0x2d8, 0x2d9};
constexpr std::array<std::int32_t, 2> kTlcjScenes = {0x3e0, 0x3f7};

[[nodiscard]] bool scene_is_one_of(const std::optional<std::int32_t>& scene, std::span<const std::int32_t> ids) noexcept {
    return scene && std::ranges::find(ids, *scene) != ids.end();
}

// Id cảnh ở đối số index theo lua_tonumber không nghiêm (chuỗi số cũng nhận, kiểu khác ra 0) rồi ép (int) như gốc.
std::int32_t scene_id_arg(lua_State* lua, int index) {
    return native::to_int(lua_tonumber(lua, index));
}

// Dòng của bảng cảnh có id ở đối số 1; nullptr khi chưa nạp bảng hay id lạ.
const panel::SceneRow* scene_row_arg(lua_State* lua) {
    const std::int32_t id = scene_id_arg(lua, 1);
    const panel::SceneTable* const table = native::context_of(lua).facts.scenes;
    return table == nullptr ? nullptr : table->find(id);
}

// GetSceneSize() (0x140238e00): rộng và sâu của cảnh đang đứng, đơn vị cảnh nguyên. Chưa vào cảnh thì 0 và 0 (Khác gốc: gốc
// đọc đối tượng cảnh không kiểm null).
NativeResult get_scene_size(lua_State* lua) {
    const std::optional<Facts::SceneSize> size = native::context_of(lua).facts.scene_size;
    lua_pushnumber(lua, size ? size->width : 0);
    lua_pushnumber(lua, size ? size->depth : 0);
    return 2;
}

// GetSceneSizeByID(id) (0x140238e80): rộng và sâu của cảnh có id trong bảng cảnh; id lạ thì 0 và 0.
NativeResult get_scene_size_by_id(lua_State* lua) {
    const panel::SceneRow* const row = scene_row_arg(lua);
    lua_pushnumber(lua, row == nullptr ? 0 : static_cast<std::int32_t>(row->width));
    lua_pushnumber(lua, row == nullptr ? 0 : static_cast<std::int32_t>(row->depth));
    return 2;
}

// GetSceneMapByID(id) (0x140238f70): token ảnh minimap (cột szSceneMap) của cảnh có id; id lạ thì chuỗi rỗng.
NativeResult get_scene_map_by_id(lua_State* lua) {
    const panel::SceneRow* const row = scene_row_arg(lua);
    lua_pushstring(lua, row == nullptr ? "" : row->token.c_str());
    return 1;
}

// IsInTServer() (0x14011e430): 1 khi biến IsTServer khác 0 (atoi) hoặc đang ở cảnh 0x28a, 0x2d8, 0x2d9; còn lại 0.
NativeResult is_in_t_server(lua_State* lua) {
    const Context& context = native::context_of(lua);
    const bool in_t_server = context.variables.get_int("IsTServer") != 0 || scene_is_one_of(context.facts.scene_id, kTServerScenes);
    lua_pushnumber(lua, in_t_server ? 1 : 0);
    return 1;
}

// IsTBFinalServer() (0x14026aa80): số nguyên ở đối tượng hệ thống.
NativeResult is_tb_final_server(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.tb_final_server);
    return 1;
}

// KVKInterface:IsInKVKServer() (0x140445940): atoi của biến IsKVKServer, 0 khi chưa đặt.
NativeResult kvk_is_in_server(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).variables.get_int("IsKVKServer"));
    return 1;
}

// TLCJ:IsInTLCJScene() (0x1403a83f0 và 0x1401ca210): 1 khi có nhân vật và đang ở cảnh 0x3e0 hay 0x3f7, còn lại 0.
NativeResult tlcj_is_in_scene(lua_State* lua) {
    const Facts& facts = native::context_of(lua).facts;
    lua_pushnumber(lua, facts.hero != nullptr && scene_is_one_of(facts.scene_id, kTlcjScenes) ? 1 : 0);
    return 1;
}

// IsInHell() (0x140232890): 1 khi đang ở cảnh địa ngục (Facts::in_hell), còn lại 0.
NativeResult is_in_hell(lua_State* lua) {
    lua_pushnumber(lua, native::context_of(lua).facts.in_hell() ? 1 : 0);
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
constexpr std::array<native::Entry, 1> kKvk = {{{.name = "IsInKVKServer", .function = &lua::adapt<kvk_is_in_server>}}};
constexpr std::array<native::Entry, 1> kTlcj = {{{.name = "IsInTLCJScene", .function = &lua::adapt<tlcj_is_in_scene>}}};
constexpr std::array<native::Entry, 8> kGlobals = {{
    {.name = "GetSceneID", .function = &lua::adapt<get_scene_id>},
    {.name = "IsZbs2018SpeicalServer", .function = &lua::adapt<is_zbs2018_special_server>},
    {.name = "GetSceneSize", .function = &lua::adapt<get_scene_size>},
    {.name = "GetSceneSizeByID", .function = &lua::adapt<get_scene_size_by_id>},
    {.name = "GetSceneMapByID", .function = &lua::adapt<get_scene_map_by_id>},
    {.name = "IsInTServer", .function = &lua::adapt<is_in_t_server>},
    {.name = "IsTBFinalServer", .function = &lua::adapt<is_tb_final_server>},
    {.name = "IsInHell", .function = &lua::adapt<is_in_hell>},
}};

} // namespace

void register_world(lua_State* lua) {
    native::register_table(lua, "DataPool", kDataPool);
    native::register_table(lua, "SystemSetup", kSystemSetup);
    native::register_table(lua, "WuLinZhiDian", kWuLin);
    native::register_table(lua, "JueZhanWuLinZhiDian", kJueZhan);
    native::register_table(lua, "CSongliaoWarData", kSongliao);
    native::register_table(lua, "KVKInterface", kKvk);
    native::register_table(lua, "TLCJ", kTlcj);
    native::register_globals(lua, kGlobals);
}

} // namespace game::ui::script
