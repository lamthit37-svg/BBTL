// Hàm game của nhân vật và mục tiêu cho khung nhân vật, khung mục tiêu và khung hiệu ứng (làn B của đợt UI-FULL): số buff, tra buff theo
// hiệu ứng, chế độ biến hình, Target:GetData. Bảng Target và CachedTarget dùng lớp SCRIPT_SANDBOX::Character (vtable ở classes.tsv), bảng
// Player dùng SCRIPT_SANDBOX::PlayerMySelf; phương thức gọi qua ô ảo (thunk 0x140687a1c.. của Game.exe 2026), địa chỉ thân ghi ở từng hàm.
// Client chưa có đối tượng đang chọn nên mọi hàm của Target đi đúng nhánh "không có đối tượng" của gốc.
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/combat_facts.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <optional>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// Hiệu ứng biến hình mà IsTransferMode xét (0x1402b9b20: bốn lần FUN_1405dfc60 với 0x755..0x758).
constexpr std::array<std::int32_t, 4> kTransferImpacts = {0x755, 0x756, 0x757, 0x758};

// Target:GetBuffNumber() (SCRIPT_SANDBOX::Character ô 4, 0x1402b9af0): luôn 0, không xét đối tượng.
NativeResult target_get_buff_number(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

// Target:IsTransferMode() (Character ô 5, 0x1402b9b20): 1 khi đối tượng (ô ảo 0x98) mang một trong 0x755..0x758, 0 khi không mang hay
// không có đối tượng. Client chưa có đối tượng đang chọn: nhánh "không có" của gốc, 0.
NativeResult target_is_transfer_mode(lua_State* lua) {
    lua_pushnumber(lua, 0);
    return 1;
}

// Target:CheckBuffImpactExist(id) (Character ô 14, 0x1402be450): id số nghiêm và có đối tượng thì 1 khi mang hiệu ứng id, 2 khi hệ
// quan hệ (DAT_141036068 ô 0x2b8) báo khác, không mang thì không trả gì. Không phải số hay không có đối tượng: không trả gì (đúng nhánh
// "không có đối tượng" mà client đang ở).
NativeResult target_check_buff_impact_exist(lua_State* /*lua*/) {
    return 0;
}

// Target:GetData(khoá [, số]) (0x1402b9d70): khoá không phải chuỗi hay số thì ném câu của gốc; có đối số 3 là số thì tìm đối tượng theo id
// ở DataPool + 0x13ae0 qua ObjectManager ô 0x88, không thì lấy đối tượng đang chọn (ô 0x98); không có đối tượng thì không trả gì. Client
// chưa có đối tượng nào nên luôn không trả gì sau phép kiểm khoá; nhánh có đối tượng (LEVEL, NPCID, HP...) chờ khi có mục tiêu.
NativeResult target_get_data(lua_State* lua) {
    if (!native::text_arg(lua, 2)) return std::unexpected(NativeError::of("LUA:GetData param parameter error"));
    return 0;
}

// Player:GetBuffNumber() (SCRIPT_SANDBOX::PlayerMySelf ô 4, 0x140392980): cỡ map buff ở CDataPool + 0x5b94e8 (Facts::combat.self_buffs).
NativeResult player_get_buff_number(lua_State* lua) {
    lua_pushnumber(lua, static_cast<double>(native::context_of(lua).facts.combat.self_buffs.items().size()));
    return 1;
}

// Player:CheckBuffImpactExist(id) (PlayerMySelf ô 14, 0x140393360): id số nghiêm, ép (int); duyệt buff theo thứ tự map, buff đầu tiên có id
// hiệu ứng (short, so sau khi nới sang int) bằng id thì trả thời gian còn lại / 1000 (chia nguyên, cắt về 0). Không có hay đối số không phải
// số: không trả gì.
NativeResult player_check_buff_impact_exist(lua_State* lua) {
    const std::optional<double> value = native::strict_number(lua, 2);
    if (!value) return 0;
    const std::int32_t impact = native::to_int(*value);
    for (const SelfBuff& buff : native::context_of(lua).facts.combat.self_buffs.items()) {
        if (static_cast<std::int32_t>(buff.impact) != impact) continue;
        const std::int32_t seconds = buff.remain_ms / 1000;
        lua_pushnumber(lua, seconds);
        return 1;
    }
    return 0;
}

// Player:IsTransferMode() (PlayerMySelf ô 5 cũng là 0x1402b9b20, đối tượng là nhân vật người chơi): 1 khi có nhân vật và nó mang một trong
// 0x755..0x758 (Facts::combat.self_impacts), còn không 0.
NativeResult player_is_transfer_mode(lua_State* lua) {
    const Facts& facts = native::context_of(lua).facts;
    bool transfer = false;
    if (facts.hero != nullptr) {
        for (const std::int32_t id : kTransferImpacts)
            transfer = transfer || facts.combat.self_impacts.contains(id);
    }
    lua_pushnumber(lua, transfer ? 1 : 0);
    return 1;
}

constexpr std::array<native::Entry, 4> kCharacter = {{
    {.name = "GetBuffNumber", .function = &lua::adapt<target_get_buff_number>},
    {.name = "IsTransferMode", .function = &lua::adapt<target_is_transfer_mode>},
    {.name = "CheckBuffImpactExist", .function = &lua::adapt<target_check_buff_impact_exist>},
    {.name = "GetData", .function = &lua::adapt<target_get_data>},
}};
constexpr std::array<native::Entry, 3> kPlayer = {{
    {.name = "GetBuffNumber", .function = &lua::adapt<player_get_buff_number>},
    {.name = "CheckBuffImpactExist", .function = &lua::adapt<player_check_buff_impact_exist>},
    {.name = "IsTransferMode", .function = &lua::adapt<player_is_transfer_mode>},
}};

} // namespace

void register_character(lua_State* lua) {
    native::register_table(lua, "Target", kCharacter);
    native::register_table(lua, "CachedTarget", kCharacter);
    native::register_table(lua, "Player", kPlayer);
}

} // namespace game::ui::script
