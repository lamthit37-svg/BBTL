// Hàm chiến đấu và thanh hành động của script (native_battle.cpp, action_type.cpp): mã loại của CActionSystem, GetActionNum, cảnh chiến
// trường XRZPVP/FYPVE/Thiên Hạ Hùng Bá, cờ trợ chiến, nhắc quái hằng ngày, phương án tông môn, mục hướng dẫn, âm thanh. Số so sánh lấy từ
// decompile Game.exe 2026 (địa chỉ ghi ở native_battle.cpp).
#include "hero/hero.hpp"
#include "support/script_rig.hpp"
#include "ui/script/action_type.hpp"
#include "ui/script/combat_facts.hpp"
#include "ui/script/context.hpp"

#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>

namespace game::test {
namespace {

void action_types_follow_the_constructor(Context& context) {
    using ui::script::action_type_of;
    context.expect(action_type_of("skill") == 1 && action_type_of("life") == 2 && action_type_of("packageitem") == 3, "ba mã đầu của hàm dựng");
    context.expect(action_type_of("petskill") == 10 && action_type_of("virtual_item") == 35, "petskill 10, virtual_item 0x23");
    context.expect(action_type_of("cangpin_qual_reset") == 203, "mã cuối 203");
    context.expect(action_type_of("Skill") == std::nullopt && action_type_of("") == std::nullopt && action_type_of("skil") == std::nullopt,
        "so khớp đúng, phân biệt hoa thường");
}

void get_action_num_counts_by_type(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return GetActionNum('skill') .. '|' .. GetActionNum('life')") == "0|0", "chưa có ô nào");
    script.facts.combat.action_counts[1] = 7;
    script.facts.combat.action_counts[2] = 3;
    script.facts.combat.action_counts[3] = 5;
    script.facts.combat.action_counts[0] = 4;
    context.expect(rig.eval("return GetActionNum('skill') .. '|' .. GetActionNum('life')") == "7|3", "đếm theo mã loại");
    context.expect(rig.eval("return GetActionNum('packageitem')") == "240", "packageitem luôn 240 (0xf0), không đếm");
    context.expect(rig.eval("return GetActionNum('khong_co')") == "4", "tên lạ có mã 0 nên đếm ô mã 0");
    context.expect(rig.eval("return GetActionNum(1)") == "4", "số được nhận như chuỗi \"1\" (lua_isstring) và là tên lạ");
    context.expect(rig.eval("return GetActionNum()").contains("LUA: GetActionNum Wrong Param"), "thiếu đối số bị ném");
    context.expect(rig.eval("return GetActionNum({})").contains("LUA: GetActionNum Wrong Param"), "bảng bị ném");
}

void battle_scenes_follow_scene_ids(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    const std::string all = "return XRZPVP:IsInBattleScene() .. FYPVE:IsInFYPVEScene() .. Lua_IsInTXiongBa()";
    context.expect(rig.eval(all) == "000", "chưa vào cảnh");
    script.facts.scene_id = 0x3f3;
    context.expect(rig.eval(all) == "100", "0x3f3 là chiến trường XRZPVP");
    script.facts.scene_id = 0x417;
    context.expect(rig.eval(all) == "010", "0x417 là FYPVE");
    script.facts.scene_id = 0x418;
    context.expect(rig.eval(all) == "010", "0x418 là FYPVE");
    script.facts.scene_id = 0x28a;
    context.expect(rig.eval(all) == "001", "0x28a là Thiên Hạ Hùng Bá");
    script.facts.scene_id = 0x3f4;
    context.expect(rig.eval(all) == "000", "cảnh khác");
}

void transfer_needs_scene_hero_and_impact(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    const std::string both = "return XRZPVP:IsInBattleSceneAndTransfer() .. XRZPVP:IsInBattleSceneAndTransfer_TargetID()";
    const hero::Hero who = hero::newcomer();
    script.facts.scene_id = 0x3f3;
    context.expect(script.facts.combat.self_impacts.add(0x24b9), "thêm hiệu ứng đầu dải");
    context.expect(rig.eval(both) == "00", "chưa có nhân vật thì không");
    script.facts.hero = &who;
    context.expect(rig.eval(both) == "10", "có nhân vật mang 0x24b9; mục tiêu chưa có nên 0");
    script.facts.combat.self_impacts.clear();
    static_cast<void>(script.facts.combat.self_impacts.add(0x24c3));
    context.expect(rig.eval(both) == "10", "0x24c3 là id cuối của dải");
    script.facts.combat.self_impacts.clear();
    static_cast<void>(script.facts.combat.self_impacts.add(0x24c4));
    static_cast<void>(script.facts.combat.self_impacts.add(0x24b8));
    context.expect(rig.eval(both) == "00", "0x24b8 và 0x24c4 ngoài dải");
    static_cast<void>(script.facts.combat.self_impacts.add(0x24c0));
    script.facts.scene_id = 0x3f2;
    context.expect(rig.eval(both) == "00", "đúng hiệu ứng nhưng sai cảnh");
}

void impact_set_has_a_ceiling(Context& context) {
    ui::script::ImpactSet impacts;
    bool all_added = true;
    for (std::size_t id = 0; id < ui::script::kImpactLimit; ++id)
        all_added = impacts.add(static_cast<std::int32_t>(id)) && all_added;
    context.expect(all_added && impacts.size() == ui::script::kImpactLimit, "đủ trần");
    context.expect(!impacts.add(100000) && !impacts.contains(100000), "quá trần thì không thêm");
    context.expect(impacts.add(5) && impacts.size() == ui::script::kImpactLimit, "id đã có vẫn đúng");
    impacts.remove(5);
    context.expect(!impacts.contains(5) && impacts.add(100000), "bỏ một thì thêm được");
}

void nei_gua_flag_needs_more_than_one(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return table.getn({BattleAssist:AskIsNeiGuaOpen()})") == "0", "không có đối số chuỗi thì không trả gì");
    context.expect(rig.eval("return tostring(BattleAssist:AskIsNeiGuaOpen('x'))") == "false", "cờ chưa ghi là 0");
    static_cast<void>(script.facts.pool.write(0x6b6988, 1));
    context.expect(rig.eval("return tostring(BattleAssist:AskIsNeiGuaOpen('x'))") == "false", "cờ 1 chưa đủ (1 < cờ)");
    static_cast<void>(script.facts.pool.write(0x6b6988, 2));
    context.expect(rig.eval("return tostring(BattleAssist:AskIsNeiGuaOpen(5))") == "true", "cờ 2 là mở; số cũng là chuỗi");
}

void monster_tip_round_trip(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return MaritialSys:GetLastDayMonsterTip()") == "0", "chưa ghi");
    context.expect(rig.eval("MaritialSys:SetLastDayMonsterTip(1) return MaritialSys:GetLastDayMonsterTip()") == "1", "ghi 1");
    context.expect(rig.eval("MaritialSys:SetLastDayMonsterTip(2) return MaritialSys:GetLastDayMonsterTip()") == "1", "2 không < 2 nên bỏ");
    context.expect(rig.eval("MaritialSys:SetLastDayMonsterTip(-1) return MaritialSys:GetLastDayMonsterTip()") == "1", "-1 so không dấu nên bỏ");
    context.expect(rig.eval("MaritialSys:SetLastDayMonsterTip(0.7) return MaritialSys:GetLastDayMonsterTip()") == "0", "0,7 cắt về 0");
    context.expect(rig.eval("MaritialSys:SetLastDayMonsterTip('1')").contains("LUA: MaritialSys::SetLastDayMonsterTip Wrong Param[1]"),
        "chuỗi bị ném");
    static_cast<void>(script.facts.pool.write(0x649e80, 1));
    static_cast<void>(script.facts.pool.write(0x649e10, 1));
    context.expect(rig.eval("return MaritialSys:GetLastDayMonsterTip()") == "0", "cờ 0x649e10 bằng 1 thì luôn 0");
}

void data_pool_reads(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("local a, b = DataPool:GetZMSectUsePlanIndex() return a .. '|' .. b") == "0|0", "hai số chưa ghi");
    static_cast<void>(script.facts.pool.write(0x5c0318, 2));
    static_cast<void>(script.facts.pool.write(0x5c031c, 3));
    context.expect(rig.eval("local a, b = DataPool:GetZMSectUsePlanIndex() return a .. '|' .. b") == "2|3", "đúng thứ tự 0x5c0318 rồi 0x5c031c");
    context.expect(rig.eval("return DataPool:GetCurrentFreshManGuideItemValue()") == "-1", "0 thì -1");
    static_cast<void>(script.facts.pool.write(0x5f9b18, 5));
    context.expect(rig.eval("return DataPool:GetCurrentFreshManGuideItemValue()") == "5", "dương thì chính nó");
    static_cast<void>(script.facts.pool.write(0x5f9b18, -3));
    context.expect(rig.eval("return DataPool:GetCurrentFreshManGuideItemValue()") == "-1", "âm thì -1");
}

void play_ui_sound_checks_argument(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return table.getn({Sound:PlayUISound(3)})") == "0", "số thì không trả gì");
    context.expect(rig.eval("return Sound:PlayUISound('3')").contains("LUA: Lua_PlayUISound Wrong Param"), "chuỗi bị ném");
}

constexpr std::array<Case, 9> kCases = {{
    {.name = "mã loại theo hàm dựng CActionSystem", .body = action_types_follow_the_constructor},
    {.name = "GetActionNum đếm theo loại", .body = get_action_num_counts_by_type},
    {.name = "cảnh chiến trường", .body = battle_scenes_follow_scene_ids},
    {.name = "biến hình cần cảnh, nhân vật và hiệu ứng", .body = transfer_needs_scene_hero_and_impact},
    {.name = "tập hiệu ứng có trần", .body = impact_set_has_a_ceiling},
    {.name = "cờ trợ chiến phải lớn hơn 1", .body = nei_gua_flag_needs_more_than_one},
    {.name = "nhắc quái hằng ngày", .body = monster_tip_round_trip},
    {.name = "phương án tông môn và mục hướng dẫn", .body = data_pool_reads},
    {.name = "âm thanh giao diện kiểm đối số", .body = play_ui_sound_checks_argument},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
