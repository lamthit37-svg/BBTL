// Hàm game của nhóm chiến đấu và thanh hành động (làn B của đợt UI-FULL): đếm ô hành động theo loại, cảnh chiến trường XRZPVP và
// FYPVE, cờ trợ chiến, nhắc quái hằng ngày của MaritialSys, phương án tông môn, mục hướng dẫn tân thủ, âm thanh giao diện. Mỗi hàm ghi
// địa chỉ thân trong Game.exe 2026 (bản 9001) và Khác gốc. Dữ liệu đọc từ Context::facts (scene_id, hero, pool, combat).
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/action_type.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/pool_image.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <optional>
#include <span>
#include <string_view>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// Cảnh chiến trường XRZPVP (0x3f3 ở ba hàm XRZPVP), FYPVE (0x417, 0x418) và Thiên Hạ Hùng Bá (0x28a, FUN_1406cb230 của WorldManager).
constexpr std::int32_t kXrzPvpScene = 0x3f3;
constexpr std::int32_t kFyPveSceneA = 0x417;
constexpr std::int32_t kFyPveSceneB = 0x418;
constexpr std::int32_t kTXiongBaScene = 0x28a;
// Dải hiệu ứng "biến hình" của chiến trường XRZPVP: vòng lặp 0x24b9 <= id < 0x24c4 ở 0x1403add70 và 0x1403ade30.
constexpr std::int32_t kTransferImpactFirst = 0x24b9;
constexpr std::int32_t kTransferImpactEnd = 0x24c4;

// Trường CDataPool (DAT_141034c40) mà nhóm này đọc; hàm dựng 0x1400dec40 không đặt (hay đặt 0) cả sáu, nên chưa ghi là 0
// (đo bằng ConstructorImage của TOOLS/port/luagen/gen_pool_natives.py).
constexpr PoolField kNeiGuaFlag{.offset = 0x6b6988, .width = Width::kI32};
constexpr PoolField kMonsterTipLocked{.offset = 0x649e10, .width = Width::kI32};
constexpr PoolField kMonsterTip{.offset = 0x649e80, .width = Width::kI32};
constexpr PoolField kSectPlanIndex{.offset = 0x5c0318, .width = Width::kI32};
constexpr PoolField kSectPlanCount{.offset = 0x5c031c, .width = Width::kI32};
constexpr PoolField kGuideItemValue{.offset = 0x5f9b18, .width = Width::kI32};

[[nodiscard]] std::int64_t pool_read(lua_State* lua, const PoolField field) {
    return native::context_of(lua).facts.pool.read(field, std::span<const PoolInitial>{});
}

[[nodiscard]] bool in_scene(lua_State* lua, const std::int32_t scene) {
    const std::optional<std::int32_t>& now = native::context_of(lua).facts.scene_id;
    return now && *now == scene;
}

// GetActionNum(tên) (0x140234160 gọi CActionSystem ô ảo 22, 0x140017190): số ô hành động của loại `tên`; "packageitem" (mã 3) là cỡ túi
// cố định 240. Tên lạ có mã 0 và đếm ô mã 0. Đối số không phải chuỗi hay số: câu lỗi của gốc. Số đếm lấy từ Facts::combat.action_counts.
NativeResult get_action_num(lua_State* lua) {
    const std::optional<std::string_view> text = native::text_arg(lua, 1);
    if (!text) return std::unexpected(NativeError::of("LUA: GetActionNum Wrong Param"));
    const std::int32_t type = action_type_of(native::c_string(*text)).value_or(0);
    const auto& counts = native::context_of(lua).facts.combat.action_counts;
    std::int32_t count = 0;
    if (type == kPackageItemType) {
        count = kPackageItemCount;
    } else if (type >= 0 && static_cast<std::size_t>(type) < counts.size()) {
        count = *std::next(counts.begin(), type);
    }
    lua_pushnumber(lua, count);
    return 1;
}

// XRZPVP:IsInBattleScene() (0x1403adcf0): 1 khi đang ở cảnh 0x3f3, còn không 0.
NativeResult xrz_is_in_battle_scene(lua_State* lua) {
    lua_pushnumber(lua, in_scene(lua, kXrzPvpScene) ? 1 : 0);
    return 1;
}

// XRZPVP:IsInBattleSceneAndTransfer() (0x1403add70): 1 khi ở cảnh 0x3f3, có nhân vật người chơi và nó mang một hiệu ứng trong
// 0x24b9..0x24c3. Nhân vật là Facts::hero (gốc: ObjectManager + 0xb8), hiệu ứng là Facts::combat.self_impacts.
NativeResult xrz_is_in_battle_scene_and_transfer(lua_State* lua) {
    bool transfer = false;
    const Facts& facts = native::context_of(lua).facts;
    if (in_scene(lua, kXrzPvpScene) && facts.hero != nullptr) {
        for (std::int32_t id = kTransferImpactFirst; id < kTransferImpactEnd && !transfer; ++id)
            transfer = facts.combat.self_impacts.contains(id);
    }
    lua_pushnumber(lua, transfer ? 1 : 0);
    return 1;
}

// XRZPVP:IsInBattleSceneAndTransfer_TargetID() (0x1403ade30): như trên nhưng xét đối tượng đang chọn (ObjectManager ô ảo 0xa8) và
// thêm phép kiểm kiểu đối tượng (ô ảo 0x2a8 và trường +0x228 của nó). Khác gốc: client chưa có đối tượng đang chọn nên luôn 0 (đúng
// nhánh "không có mục tiêu" của gốc).
NativeResult xrz_is_in_battle_scene_and_transfer_target(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

// FYPVE:IsInFYPVEScene() (0x140298f50): 1 ở cảnh 0x417 hay 0x418.
NativeResult fypve_is_in_scene(lua_State* lua) {
    lua_pushnumber(lua, in_scene(lua, kFyPveSceneA) || in_scene(lua, kFyPveSceneB) ? 1 : 0);
    return 1;
}

// Lua_IsInTXiongBa() (0x140247340 -> WorldManager 0x1406cb230): 1 ở cảnh 0x28a.
NativeResult is_in_t_xiong_ba(lua_State* lua) {
    lua_pushnumber(lua, in_scene(lua, kTXiongBaScene) ? 1 : 0);
    return 1;
}

// BattleAssist:AskIsNeiGuaOpen(chuỗi) (0x1403cfa40): không có đối số chuỗi (hay số) thì không trả gì. Có thì đọc cờ ở CDataPool + 0x6b6988
// (máy chủ ghi `n % 10 + 1`, 0x1400d1120 vùng), trả true khi cờ > 1. Khác gốc: cờ còn 0 thì gốc gửi gói CGZdZdRequest (loại 0xc) hỏi máy
// chủ; client chưa có gói này (ghi ở docs/giao-viec/UI-FULL/B-CAN-MAY-CHU.md) nên chỉ trả false.
NativeResult battle_assist_ask_is_nei_gua_open(lua_State* lua) {
    if (!native::text_arg(lua, 2)) return 0;
    lua_pushboolean(lua, pool_read(lua, kNeiGuaFlag) > 1 ? 1 : 0);
    return 1;
}

// MaritialSys:GetLastDayMonsterTip() (0x140358c10, đọc bằng asm vì decompile mất đối số xmm1): 0 khi cờ ở CDataPool + 0x649e10 bằng 1,
// còn không là số ở + 0x649e80.
NativeResult maritial_get_last_day_monster_tip(lua_State* lua) {
    const std::int64_t tip = pool_read(lua, kMonsterTipLocked) == 1 ? 0 : pool_read(lua, kMonsterTip);
    lua_pushnumber(lua, static_cast<double>(tip));
    return 1;
}

// MaritialSys:SetLastDayMonsterTip(n) (0x140358c60): n số nghiêm, ép (int); ghi vào CDataPool + 0x649e80 khi (unsigned)n < 2, không thì
// bỏ qua. Không trả gì.
NativeResult maritial_set_last_day_monster_tip(lua_State* lua) {
    const std::optional<double> value = native::strict_number(lua, 2);
    if (!value) return std::unexpected(NativeError::of("LUA: MaritialSys::SetLastDayMonsterTip Wrong Param[1]"));
    const std::int32_t tip = native::to_int(*value);
    if (static_cast<std::uint32_t>(tip) < 2U) static_cast<void>(native::context_of(lua).facts.pool.write(kMonsterTip.offset, tip));
    return 0;
}

// DataPool:GetZMSectUsePlanIndex() (0x1402ff5e0): hai số ở CDataPool + 0x5c0318 (phương án đang dùng, máy chủ ghi) và + 0x5c031c.
NativeResult datapool_get_zm_sect_use_plan_index(lua_State* lua) {
    lua_pushnumber(lua, static_cast<double>(pool_read(lua, kSectPlanIndex)));
    lua_pushnumber(lua, static_cast<double>(pool_read(lua, kSectPlanCount)));
    return 2;
}

// DataPool:GetCurrentFreshManGuideItemValue() (0x1403067b0 -> 0x140105d00): số ở CDataPool + 0x5f9b18 khi dương, còn không -1 (hằng
// double ở 0x140a41ff0).
NativeResult datapool_get_current_fresh_man_guide_item_value(lua_State* lua) {
    const std::int64_t value = pool_read(lua, kGuideItemValue);
    lua_pushnumber(lua, value > 0 ? static_cast<double>(value) : -1.0);
    return 1;
}

// Sound:PlayUISound(id) (0x140688ab0): id số nghiêm, gốc phát âm thanh giao diện id (0x140688840). Khác gốc: client chưa có hệ âm
// thanh giao diện nên chỉ kiểm đối số. Không trả gì.
NativeResult sound_play_ui_sound(lua_State* lua) {
    if (!native::strict_number(lua, 2)) return std::unexpected(NativeError::of("LUA: Lua_PlayUISound Wrong Param"));
    return 0;
}

constexpr std::array<native::Entry, 2> kGlobals = {{
    {.name = "GetActionNum", .function = &lua::adapt<get_action_num>},
    {.name = "Lua_IsInTXiongBa", .function = &lua::adapt<is_in_t_xiong_ba>},
}};
constexpr std::array<native::Entry, 3> kXrzPvp = {{
    {.name = "IsInBattleScene", .function = &lua::adapt<xrz_is_in_battle_scene>},
    {.name = "IsInBattleSceneAndTransfer", .function = &lua::adapt<xrz_is_in_battle_scene_and_transfer>},
    {.name = "IsInBattleSceneAndTransfer_TargetID", .function = &lua::adapt<xrz_is_in_battle_scene_and_transfer_target>},
}};
constexpr std::array<native::Entry, 1> kFyPve = {{
    {.name = "IsInFYPVEScene", .function = &lua::adapt<fypve_is_in_scene>},
}};
constexpr std::array<native::Entry, 1> kBattleAssist = {{
    {.name = "AskIsNeiGuaOpen", .function = &lua::adapt<battle_assist_ask_is_nei_gua_open>},
}};
constexpr std::array<native::Entry, 2> kMaritial = {{
    {.name = "GetLastDayMonsterTip", .function = &lua::adapt<maritial_get_last_day_monster_tip>},
    {.name = "SetLastDayMonsterTip", .function = &lua::adapt<maritial_set_last_day_monster_tip>},
}};
constexpr std::array<native::Entry, 2> kDataPool = {{
    {.name = "GetZMSectUsePlanIndex", .function = &lua::adapt<datapool_get_zm_sect_use_plan_index>},
    {.name = "GetCurrentFreshManGuideItemValue", .function = &lua::adapt<datapool_get_current_fresh_man_guide_item_value>},
}};
constexpr std::array<native::Entry, 1> kSound = {{
    {.name = "PlayUISound", .function = &lua::adapt<sound_play_ui_sound>},
}};

} // namespace

void register_battle(lua_State* lua) {
    native::register_globals(lua, kGlobals);
    native::register_table(lua, "XRZPVP", kXrzPvp);
    native::register_table(lua, "FYPVE", kFyPve);
    native::register_table(lua, "BattleAssist", kBattleAssist);
    native::register_table(lua, "MaritialSys", kMaritial);
    native::register_table(lua, "DataPool", kDataPool);
    native::register_table(lua, "Sound", kSound);
}

} // namespace game::ui::script
