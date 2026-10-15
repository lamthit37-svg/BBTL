// Player:GetData của script giao diện (ui/script/native_player): ánh xạ từng khoá sang trường của hero::Hero, phép tách tiền thành
// vàng/bạc/đồng, hai khoá chuỗi và các ca không trả gì. Sai ở đây hỏng thầm (hai khoá đọc nhầm trường cho cùng một số khi nhân vật
// mới, tiền tách lệch đơn vị) nên có test; mỗi trường được đặt một số riêng để đọc nhầm lộ ra.
#include "hero/hero.hpp"
#include "support/script_rig.hpp"
#include "ui/script/context.hpp"

#include "test.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

hero::Hero distinct_hero() {
    hero::Hero who = hero::newcomer();
    who.level = 71;
    who.health = {.now = 1001, .top = 1002};
    who.mana = {.now = 1003, .top = 1004};
    who.rage = {.now = 1005, .top = 1006};
    who.strike_points = 7;
    who.sect = static_cast<hero::Sect>(5);
    who.roots = {.strength = 21, .spirit = 22, .constitution = 23, .stability = 24, .agility = 25};
    who.spare_points = 26;
    who.combat = {.attack_physical = 31, .attack_magic = 32, .defence_physical = 33, .defence_magic = 34, .hit = 35, .miss = 36,
        .critical_attack = 37, .critical_defence = 38};
    who.vigor = {.now = 41, .top = 42};
    who.energy = {.now = 43, .top = 44};
    who.battle_score = 45;
    who.purse = {.money = 987654, .money_voucher = 51, .yuanbao = 52, .bind_yuanbao = 53, .gift_token = 54, .bonus_point = 55, .cash_gift = 56};
    return who;
}

void every_key_reads_its_own_field(Context& context) {
    const hero::Hero who = distinct_hero();
    ui::script::Context script;
    script.facts.hero = &who;
    script.facts.server = {.pk_jd = 61, .original_jd = 62, .s2606 = 63};
    ScriptRig rig(script);
    context.expect(rig.ok(), "mở được máy Lua");
    if (!rig.ok()) return;
    const std::array<std::pair<std::string_view, std::string_view>, 36> wanted = {{
        {"LEVEL", "71"}, {"HP", "1001"}, {"MAXHP", "1002"}, {"MP", "1003"}, {"MAXMP", "1004"}, {"RAGE", "1005"}, {"MAXRAGE", "1000"},
        {"STRIKEPOINT", "7"}, {"MEMPAI", "5"}, {"STR", "21"}, {"SPR", "22"}, {"CON", "23"}, {"INT", "24"}, {"DEX", "25"},
        {"POINT_REMAIN", "26"}, {"ATT_PHYSICS", "31"}, {"ATT_MAGIC", "32"}, {"DEF_PHYSICS", "33"}, {"DEF_MAGIC", "34"}, {"HIT", "35"},
        {"MISS", "36"}, {"CRITICALATTACK", "37"}, {"CRITICALDEFENCE", "38"}, {"VIGOR", "41"}, {"MAXVIGOR", "42"}, {"ENERGY", "43"},
        {"MAXENERGY", "44"}, {"BATTLESCORE", "45"}, {"MONEY_JZ", "51"}, {"YUANBAO", "52"}, {"BIND_YUANBAO", "53"}, {"GIFTTOKEN", "54"},
        {"ZENGDIAN", "55"}, {"LIJIN", "56"}, {"IsPKServer_JD", "61"}, {"IsOriginalJD", "62"},
    }};
    for (const auto& [key, value] : wanted) {
        const std::string code = "return Player:GetData('" + std::string(key) + "')";
        context.expect(rig.eval(code) == value, key);
    }
    context.expect(rig.eval("return Player:GetData('Is2606S')") == "63", "Is2606S");
    context.expect(rig.eval("return type(Player:GetData('LEVEL'))") == "number", "khoá số trả số Lua");
}

void money_splits_into_gold_silver_copper(Context& context) {
    hero::Hero who = hero::newcomer();
    ui::script::Context script;
    script.facts.hero = &who;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // {tiền, "tổng|vàng|bạc|đồng"}: ranh giới 99/100 và 9999/10000, số lớn, rồi tiền âm (gốc không tách vàng bạc dưới một đơn vị).
    const std::array<std::pair<std::int32_t, std::string_view>, 9> cases = {{
        {0, "0|0|0|0"},
        {99, "99|0|0|99"},
        {100, "100|0|1|0"},
        {9999, "9999|0|99|99"},
        {10000, "10000|1|0|0"},
        {10101, "10101|1|1|1"},
        {987654, "987654|98|76|54"},
        {2147483647, "2147483647|214748|36|47"},
        {-5, "-5|0|0|-5"},
    }};
    for (const auto& [money, text] : cases) {
        who.purse.money = money;
        const std::string got = rig.eval("local total, gold, silver, copper = Player:GetData('MONEY') return total .. '|' .. gold .. '|' .. silver .. '|' .. copper");
        context.expect(got == text, "MONEY " + std::to_string(money) + " ra " + got);
    }
}

void experience_is_decimal_text(Context& context) {
    hero::Hero who = hero::newcomer();
    who.experience = {.now = 5'000'000'000, .top = 9'000'000'000};
    ui::script::Context script;
    script.facts.hero = &who;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return type(Player:GetData('EXP'))") == "string", "EXP là chuỗi");
    context.expect(rig.eval("return Player:GetData('EXP')") == "5000000000", "EXP vượt int32");
    context.expect(rig.eval("return Player:GetData('NEEDEXP')") == "9000000000", "NEEDEXP vượt int32");
    who.experience = {.now = -1, .top = -1};
    context.expect(rig.eval("return Player:GetData('EXP')") == "0", "kinh nghiệm âm in 0");
    context.expect(rig.eval("return Player:GetData('NEEDEXP')") == "-1", "NEEDEXP giữ nguyên số âm");
}

void gauges_saturate_instead_of_wrapping(Context& context) {
    hero::Hero who = hero::newcomer();
    who.health = {.now = 5'000'000'000, .top = -5'000'000'000};
    ui::script::Context script;
    script.facts.hero = &who;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return Player:GetData('HP')") == "2147483647", "HP kẹp ở trần int32");
    context.expect(rig.eval("return Player:GetData('MAXHP')") == "-2147483648", "MAXHP kẹp ở sàn int32");
}

void nothing_is_returned_without_data(Context& context) {
    const hero::Hero who = hero::newcomer();
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("local v = Player:GetData('LEVEL') return type(v)") == "nil", "chưa có nhân vật thì không trả gì");
    context.expect(rig.eval("local v = Player:GetData('MONEY') return type(v)") == "nil", "MONEY cũng vậy");
    script.facts.hero = &who;
    context.expect(rig.eval("local v = Player:GetData('LEVEL') return type(v)") == "number", "có nhân vật thì trả");
    context.expect(rig.eval("local v = Player:GetData({}) return type(v)") == "nil", "đối số không phải chuỗi hay số");
    context.expect(rig.eval("local v = Player:GetData() return type(v)") == "nil", "thiếu đối số");
    context.expect(rig.eval("local v = Player:GetData('NOSUCHKEY') return type(v)") == "nil", "khoá lạ");
    context.expect(rig.eval("local v = Player:GetData('level') return type(v)") == "nil", "khoá phân biệt hoa thường");
    context.expect(rig.eval("local v = Player:GetData('LEVEL ') return type(v)") == "nil", "khoá thừa dấu cách");
    context.expect(rig.eval("local v = Player:GetData('LEV') return type(v)") == "nil", "khoá chỉ là tiền tố");
    context.expect(rig.eval("local v = Player:GetData('TODAYACTIVEPOINT') return type(v)") == "nil", "khoá hero::Hero chưa có dữ liệu");
    // Chuỗi C: NUL cắt khoá, nên "LEVEL\0rác" vẫn là LEVEL.
    context.expect(rig.eval(R"(return Player:GetData("LEVEL\0rac"))") == "1", "NUL cắt khoá");
}

void level_and_name_follow_the_hero(Context& context) {
    hero::Hero who = hero::newcomer();
    who.level = 88;
    who.name = "Thiên Long";
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    // Chưa có nhân vật: tên rỗng, cấp là lỗi assert `pMyself` như gốc.
    context.expect(rig.eval("return Player:GetName()").empty(), "chưa có nhân vật thì tên rỗng");
    context.expect(rig.eval("return Player:GetLevel()").contains("pMyself"), "chưa có nhân vật thì GetLevel báo assert pMyself");
    script.facts.hero = &who;
    context.expect(rig.eval("return Player:GetLevel()") == "88", "GetLevel");
    context.expect(rig.eval("return Player:GetName()") == "Thiên Long", "GetName giữ nguyên byte UTF-8");
}

void leader_guild_and_zone_follow_their_facts(Context& context) {
    hero::Hero who = hero::newcomer();
    ui::script::Context script;
    ScriptRig rig(script);
    if (!rig.ok()) return;
    context.expect(rig.eval("return DataPool:GetSelfZoneWorldID()") == "-1", "chưa có nhân vật thì id vùng là -1");
    context.expect(rig.eval("local g, c = DataPool:GetGuildClanID() return g .. '|' .. c") == "-1|-1", "chưa có bang là -1 và -1");
    script.facts.hero = &who;
    context.expect(rig.eval("return Player:IsLeader()") == "0", "mặc định không phải đội trưởng");
    who.is_leader = true;
    context.expect(rig.eval("return Player:IsLeader()") == "1", "đội trưởng");
    context.expect(rig.eval("return Player:GetData('GUILD')") == "-1", "GUILD mặc định -1");
    context.expect(rig.eval("return Player:GetData('ZONEWORLDID')") == "0", "ZONEWORLDID mặc định 0");
    script.facts.guild_id = 12;
    script.facts.zone_world_id = 7;
    context.expect(rig.eval("return Player:GetData('GUILD')") == "12", "GUILD đọc Facts");
    context.expect(rig.eval("return Player:GetData('ZONEWORLDID')") == "7", "ZONEWORLDID đọc Facts");
    context.expect(rig.eval("return DataPool:GetSelfZoneWorldID()") == "7", "GetSelfZoneWorldID");
    context.expect(rig.eval("local g, c = DataPool:GetGuildClanID() return g .. '|' .. c") == "12|-1", "id bang rồi -1 cố định");
}

constexpr std::array<Case, 7> kCases = {{
    {.name = "mỗi khoá đọc đúng trường của nó", .body = every_key_reads_its_own_field},
    {.name = "MONEY tách vàng bạc đồng", .body = money_splits_into_gold_silver_copper},
    {.name = "EXP và NEEDEXP là chuỗi thập phân", .body = experience_is_decimal_text},
    {.name = "thanh máu vượt int32 kẹp biên", .body = gauges_saturate_instead_of_wrapping},
    {.name = "không có dữ liệu thì không trả gì", .body = nothing_is_returned_without_data},
    {.name = "GetLevel và GetName", .body = level_and_name_follow_the_hero},
    {.name = "đội trưởng, bang, vùng", .body = leader_guild_and_zone_follow_their_facts},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
