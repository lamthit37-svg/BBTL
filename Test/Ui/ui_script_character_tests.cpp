// Hàm nhân vật và mục tiêu của script (native_character.cpp): số buff và tra buff của nhân vật người chơi theo kho buff của gốc, chế độ biến
// hình theo bốn hiệu ứng 0x755..0x758, và các phương thức của Target/CachedTarget khi chưa chọn đối tượng. Giá trị so sánh lấy từ decompile
// Game.exe 2026 (0x140392980, 0x140393360, 0x1402b9af0, 0x1402b9b20, 0x1402be450, 0x1402b9d70).
#include "hero/hero.hpp"
#include "support/script_rig.hpp"
#include "ui/script/combat_facts.hpp"
#include "ui/script/context.hpp"

#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>

namespace game::test {
namespace {

void player_buffs_follow_the_buff_map(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return Player:GetBuffNumber()") == "0", "chưa có buff");
    context.expect(rig.eval("return table.getn({Player:CheckBuffImpactExist(10)})") == "0", "không có buff thì không trả gì");
    static_cast<void>(script.facts.combat.self_buffs.push({.impact = 10, .remain_ms = 5999}));
    static_cast<void>(script.facts.combat.self_buffs.push({.impact = 20, .remain_ms = 120000}));
    static_cast<void>(script.facts.combat.self_buffs.push({.impact = 10, .remain_ms = 90000}));
    static_cast<void>(script.facts.combat.self_buffs.push({.impact = -2, .remain_ms = 3000}));
    context.expect(rig.eval("return Player:GetBuffNumber()") == "4", "đếm đủ bốn buff");
    context.expect(rig.eval("return Player:CheckBuffImpactExist(10)") == "5", "buff đầu theo thứ tự map, 5999 ms chia nguyên còn 5");
    context.expect(rig.eval("return Player:CheckBuffImpactExist(20)") == "120", "120000 ms là 120");
    context.expect(rig.eval("return Player:CheckBuffImpactExist(20.9)") == "120", "id ép (int) cắt về 20");
    context.expect(rig.eval("return Player:CheckBuffImpactExist(-2)") == "3", "id short âm so sau khi nới sang int");
    context.expect(rig.eval("return table.getn({Player:CheckBuffImpactExist(65534)})") == "0", "65534 không bằng short -2");
    context.expect(rig.eval("return table.getn({Player:CheckBuffImpactExist('10')})") == "0", "chuỗi không phải số nghiêm: không trả gì");
}

void buff_list_has_a_ceiling(Context& context) {
    ui::script::BuffList buffs;
    bool all = true;
    for (std::size_t at = 0; at < ui::script::kBuffLimit; ++at)
        all = buffs.push({.impact = 1, .remain_ms = 0}) && all;
    context.expect(all && buffs.items().size() == ui::script::kBuffLimit, "đủ trần");
    context.expect(!buffs.push({.impact = 2, .remain_ms = 0}) && buffs.items().size() == ui::script::kBuffLimit, "quá trần thì bỏ");
}

void player_transfer_mode_needs_hero_and_impact(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    const hero::Hero who = hero::newcomer();
    static_cast<void>(script.facts.combat.self_impacts.add(0x755));
    context.expect(rig.eval("return Player:IsTransferMode()") == "0", "chưa có nhân vật");
    script.facts.hero = &who;
    for (const std::int32_t id : std::array<std::int32_t, 4>{0x755, 0x756, 0x757, 0x758}) {
        script.facts.combat.self_impacts.clear();
        static_cast<void>(script.facts.combat.self_impacts.add(id));
        context.expect(rig.eval("return Player:IsTransferMode()") == "1", "một trong bốn hiệu ứng biến hình");
    }
    script.facts.combat.self_impacts.clear();
    static_cast<void>(script.facts.combat.self_impacts.add(0x754));
    static_cast<void>(script.facts.combat.self_impacts.add(0x759));
    context.expect(rig.eval("return Player:IsTransferMode()") == "0", "0x754 và 0x759 không phải");
}

void target_without_selection(Context& context) {
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    static_cast<void>(script.facts.combat.self_buffs.push({.impact = 10, .remain_ms = 5000}));
    context.expect(rig.eval("return Target:GetBuffNumber() .. CachedTarget:GetBuffNumber()") == "00", "lớp Character luôn 0, không đọc buff của mình");
    context.expect(rig.eval("return Target:IsTransferMode() .. CachedTarget:IsTransferMode()") == "00", "không có đối tượng thì 0");
    context.expect(rig.eval("return table.getn({Target:CheckBuffImpactExist(10)})") == "0", "không có đối tượng thì không trả gì");
    context.expect(rig.eval("return table.getn({Target:GetData('LEVEL')}) .. table.getn({Target:GetData('HP', 1)})") == "00",
        "khoá hợp lệ nhưng không có đối tượng thì không trả gì");
    context.expect(rig.eval("return Target:GetData()").contains("LUA:GetData param parameter error"), "thiếu khoá bị ném");
    context.expect(rig.eval("return CachedTarget:GetData({})").contains("LUA:GetData param parameter error"), "khoá bảng bị ném");
}

constexpr std::array<Case, 4> kCases = {{
    {.name = "buff của nhân vật theo kho buff", .body = player_buffs_follow_the_buff_map},
    {.name = "danh sách buff có trần", .body = buff_list_has_a_ceiling},
    {.name = "biến hình của nhân vật", .body = player_transfer_mode_needs_hero_and_impact},
    {.name = "mục tiêu khi chưa chọn", .body = target_without_selection},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
