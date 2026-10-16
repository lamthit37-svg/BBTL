// Thân thể chiến đấu: chỉ số theo môn phái và cấp, trang bị, lên cấp nhiều bậc, suy giảm kinh nghiệm, nộ khí,
// hồi sinh, hình phạt chết, bản ghi bền, bộ nạp bảng. Số vàng của chỉ số tính độc lập bằng Python từ chính các
// bảng (BaseValueTable, điểm mỗi cấp, PlayerExpLevel) theo công thức Float2Int của Obj_Human_Attributes.cpp,
// không lấy từ đầu ra của C++. Bảng thật nằm ở dev/server/tables (GAME_SERVER_TABLES).
#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/codec.hpp"
#include "actor/rules.hpp"
#include "actor/sheet.hpp"
#include "dice/dice.hpp"
#include "support/actor_rules.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

// Các thử nghiệm nằm trong namespace actor để gọi thẳng tên của module (google-build-using-namespace cấm using-directive).
namespace game::actor {
namespace {

using test::Case;
using test::Context;
using test::RuleTables;
using test::real_rules;
using test::rule_tables;

const RuleTables* tables() { return rule_tables(); }

const Rules* rules(Context& context) { return real_rules(context); }

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): phái, cấp, điểm, điểm tự do khác vai, nơi gọi nêu rõ (HP-07)
Record record_of(std::uint8_t sect, std::uint16_t level, std::array<std::int32_t, kPrimaryCount> points,
    std::int32_t remain) {
    Record record;
    record.sect = sect;
    record.level = level;
    record.points = points;
    record.remain_points = remain;
    record.hp = std::numeric_limits<std::int32_t>::max();
    record.mp = std::numeric_limits<std::int32_t>::max();
    return record;
}

// --- bộ nạp ---

void rules_load_real_tables(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    context.expect(r->max_level() == 150, "150 cấp");
    context.expect(r->exp_need(1) == 90 && r->exp_need(2) == 324 && r->exp_need(150) == 1707414660ULL,
        "kinh nghiệm cấp 1, 2, 150");
    context.expect(r->exp_need(0) == 0 && r->exp_need(151) == 0, "ngoài bảng thì 0");
    context.expect(r->monster_count() == 28969, "28969 quái");
    context.expect(r->growth(0, 0, 0) == 6 && r->growth(0, 1, 0) == 2 && r->growth(0, 1, 4) == 1,
        "điểm mỗi cấp phái 0 hàng 0 và 1");
    context.expect(r->growth(0, 151, 0) == 0 && r->growth(0, 1, 5) == 0, "ngoài bảng điểm thì 0");
    context.expect(r->template_of(12) == 3 && r->template_of(5) == 5 && r->template_of(9) == 9, "phái mẫu");
    context.expect(r->exp_gap_ppm(0) == 1'000'000 && r->exp_gap_ppm(10) == 950'000 && r->exp_gap_ppm(-55) == 100'000,
        "hệ số chênh cấp");
    context.expect(r->exp_gap_ppm(100000) == 100'000 && r->exp_gap_ppm(-100000) == 100'000, "kẹp hai đầu bảng");
    context.expect(r->rage(2, RageTrigger::kStrikeSpent).multiplier == 10, "Cái Bang tiêu liên kích");
    context.expect(r->rage(13, RageTrigger::kHealDone).divisor == 20, "phái 13 mượn Nga Mi");
    context.expect(r->rage(0, RageTrigger::kHealDone).multiplier == 0, "Thiếu Lâm không hồi máu sinh nộ");
    const PenaltyRow* row = r->penalty(21);
    context.expect(row != nullptr && row->money.min == Amount{.percent = true, .value = 11} && row->money.max == Amount{.percent = true, .value = 18} &&
            row->item_drop.max == Amount{.percent = true, .value = 20},
        "dòng phạt 21");
    context.expect(r->penalty(999'999) == nullptr, "dòng phạt lạ");
    const MonsterRow* mob = r->monster(100);
    context.expect(mob != nullptr && mob->level == 45 && mob->max_hp == 6876 && mob->base_exp == 529, "quái 100");
    context.expect(r->monster(1) != nullptr && r->monster(3) == nullptr && r->monster(4000000000U) == nullptr, "id quái rời rạc: tra id vắng trả null");
    const InnerArtRow* art = r->inner_art(1);
    context.expect(art != nullptr && art->logic == 6 && art->steps.size() >= 6 && art->steps[1].first == 60 &&
            art->steps[1].second == 4000,
        "tâm pháp 1");
}

void rules_reject_bad_tables(Context& context) {
    const RuleTables* loaded = tables();
    if (loaded == nullptr) {
        context.expect(false, "thiếu bảng thật");
        return;
    }
    const auto fails = [&](std::string RuleTables::*field, const std::string& replacement, std::string_view what) {
        RuleTables copy = *loaded;
        copy.*field = replacement;
        const Loaded<Rules> result = load_rules(copy.text());
        context.expect(!result.has_value(), what);
    };
    fails(&RuleTables::base, "", "bảng hệ số rỗng");
    fails(&RuleTables::base, "sect_id\tainfotype0\n0\t1\n", "bảng hệ số thiếu cột");
    fails(&RuleTables::base, loaded->base + "0\t" + std::string(42, ' ') + "\n", "dòng thừa");
    fails(&RuleTables::growth, "rank\tc\n0\t1\n", "bảng điểm mỗi cấp thiếu cột");
    fails(&RuleTables::exp, "level\texp\n1\t90\n3\t100\n", "cấp không liền");
    fails(&RuleTables::exp, "level\texp\n1\t0\n", "kinh nghiệm không dương");
    fails(&RuleTables::exp, "level\texp\n1\tabc\n", "kinh nghiệm không phải số");
    fails(&RuleTables::gap, "level_delta\trate\n-1\t1\n1\t1\n", "chênh cấp không liền");
    fails(&RuleTables::gap, "level_delta\trate\n0\t-1\n", "hệ số âm");
    fails(&RuleTables::rage, "sect_id\ttrigger\tmultiplier\tdivisor\n1\tdamaged\t1\t40\n", "sự kiện không đọc từ bảng luật");
    fails(&RuleTables::rage, "sect_id\ttrigger\tmultiplier\tdivisor\n1\theal_done\t1\t0\n", "chia cho 0");
    fails(&RuleTables::rage, "sect_id\ttrigger\tmultiplier\tdivisor\n99\theal_done\t1\t1\n", "phái ngoài miền");
    fails(&RuleTables::templates, "sect_id\ttemplate_sect\n10\t12\n", "phái mẫu ngoài 10 phái gốc");
    fails(&RuleTables::penalties, "id\tmoney_min\n1\t0\n", "bảng phạt thiếu cột");
    fails(&RuleTables::monsters, loaded->monsters + loaded->monsters.substr(loaded->monsters.find("\n0\t") + 1,
                                                    loaded->monsters.find('\n', loaded->monsters.find("\n0\t") + 1) -
                                                        loaded->monsters.find("\n0\t")) +
            "\n",
        "quái trùng id");
    fails(&RuleTables::inner, "inner_art_id\tsect_id\n1\t0\n", "tâm pháp thiếu cột");
    // Dòng phạt có ô phần trăm hỏng.
    std::string penalties = loaded->penalties;
    const std::size_t at = penalties.find("10%");
    if (at == std::string::npos) {
        context.expect(false, "không tìm thấy ô phần trăm mẫu");
    } else {
        penalties.replace(at, 3, "1x%");
        fails(&RuleTables::penalties, penalties, "ô phần trăm hỏng");
    }
    context.expect(parse_amount("10%") == Amount{.percent = true, .value = 10} && parse_amount("250") == Amount{.percent = false, .value = 250} &&
            !parse_amount("").has_value() && !parse_amount("%").has_value() && !parse_amount("1.5").has_value(),
        "parse_amount");
    context.expect(parse_scaled("1e+01", 1000) == 10000 && parse_scaled("0.2", 1000) == 200 &&
            !parse_scaled("abc", 1000).has_value() && !parse_scaled("1e300", 1000).has_value() &&
            !parse_scaled("nan", 1).has_value(),
        "parse_scaled");
}

// --- chỉ số ---

// str, spr, con, int, dex, HP tối đa, MP tối đa, công ngoại, công nội, thủ ngoại, thủ nội, trúng, né, hội tâm (cũng là
// hội tâm phòng).
using Expected = std::array<std::int32_t, 14>;

void expect_stats(Context& context, const Body& body, const Expected& want, std::string_view tag) {
    constexpr std::array<Stat, 14> kOrder{Stat::kStr, Stat::kSpr, Stat::kCon, Stat::kInt, Stat::kDex, Stat::kMaxHp,
        Stat::kMaxMp, Stat::kAttackPhy, Stat::kAttackMagic, Stat::kDefencePhy, Stat::kDefenceMagic, Stat::kHit,
        Stat::kMiss, Stat::kCritical};
    const auto same = [&](Stat stat, std::int32_t value) {
        if (body.stat(stat) == value) return;
        context.expect(false, std::format("{}: {} {} != {}", tag, stat_name(stat), body.stat(stat), value));
    };
    for (std::size_t i = 0; i < kOrder.size(); ++i) same(kOrder.at(i), want.at(i));
    same(Stat::kCriticalDefence, want.back());
}

void stats_golden(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    const BodyLimits limits;
    // Phái 0, cấp 1: điểm = hàng 0 + hàng 1 của bảng.
    const Body shaolin = Body::human(*r, limits, record_of(0, 1, {8, 1, 10, 2, 4}, 0));
    expect_stats(context, shaolin, {8, 1, 10, 2, 4, 1080, 175, 94, 20, 129, 36, 48, 15, 2}, "phái 0 cấp 1");
    context.expect(shaolin.hp() == 1080 && shaolin.mp() == 175, "đầy HP/MP");
    context.expect(shaolin.fluctuation() == 10 && shaolin.camp() == 1, "dao động và thế lực của Thiếu Lâm");
    // Phái 3, cấp 60 và phái 12 (mượn phái 3), cấp 150.
    const Body wudang = Body::human(*r, limits, record_of(3, 60, {13, 127, 75, 63, 37}, 5));
    expect_stats(context, wudang, {13, 127, 75, 63, 37, 6510, 4336, 337, 1692, 612, 961, 694, 248, 7}, "phái 3 cấp 60");
    context.expect(wudang.fluctuation() == 20, "dao động của Võ Đang");
    const Body guigu = Body::human(*r, limits, record_of(12, 150, {13, 127, 75, 63, 37}, 455));
    expect_stats(context, guigu, {13, 127, 75, 63, 37, 11010, 7576, 736, 2492, 1012, 1646, 1324, 473, 11}, "phái 12 cấp 150");
    // Không phái, cấp 1.
    const Body none = Body::human(*r, limits, record_of(9, 1, {7, 6, 5, 5, 2}, 0));
    expect_stats(context, none, {7, 6, 5, 5, 2, 585, 310, 56, 51, 46, 46, 38, 13, 1}, "phái 9 cấp 1");
    // new_record cho đúng điểm khởi đầu và đầy HP/MP.
    const Record fresh = Body::new_record(*r, limits, 0);
    context.expect(fresh.level == 1 && fresh.points == std::array<std::int32_t, 5>{8, 1, 10, 2, 4} && fresh.hp == 1080 &&
            fresh.mp == 175 && fresh.alive && fresh.exp == 0,
        "bản ghi mới phái 0");
    const Record unknown_sect = Body::new_record(*r, limits, 200);
    context.expect(unknown_sect.sect == 9 && unknown_sect.points == std::array<std::int32_t, 5>{7, 6, 5, 5, 2},
        "phái lạ thành không phái");
    // Cấp 0: không lỗi và vẫn tính được.
    const Body odd = Body::human(*r, limits, record_of(0, 0, {0, 0, 0, 0, 0}, 0));
    context.expect(odd.stat(Stat::kMaxHp) >= 1, "cấp 0 không làm MaxHP về 0");
}

void equipment_golden(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    Body body = Body::human(*r, BodyLimits{}, record_of(0, 1, {8, 1, 10, 2, 4}, 0));
    Modifiers equip;
    const std::array<AttrEntry, 11> entries{{
        AttrEntry{.attr_id = 0, .value = 100}, AttrEntry{.attr_id = 1, .value = 10},
        AttrEntry{.attr_id = 2, .value = 7}, AttrEntry{.attr_id = 54, .value = 50},
        AttrEntry{.attr_id = 21, .value = 20}, AttrEntry{.attr_id = 20, .value = 10},
        AttrEntry{.attr_id = 42, .value = 3}, AttrEntry{.attr_id = 25, .value = 30},
        AttrEntry{.attr_id = 33, .value = 90}, AttrEntry{.attr_id = 18, .value = 5},
        AttrEntry{.attr_id = 48, .value = 1}}};
    for (const AttrEntry& entry : entries) context.expect(equip.add_item(entry), "id thuộc tính hợp lệ");
    context.expect(!equip.add_item({.attr_id = 60, .value = 1}) && !equip.add_item({.attr_id = 65535, .value = 1}),
        "id lạ bị từ chối");
    body.set_equipment(equip);
    // Sau +1 cho cả 5 chỉ số và +3 sức mạnh: 12, 2, 11, 3, 5; các chỉ số dẫn xuất tính từ chỉ số mới.
    expect_stats(context, body, {12, 2, 11, 3, 5, 1365, 200, 196, 24, 137, 42, 54, 17, 2}, "trang bị");
    context.expect(body.stat(Stat::kHpRegen) == 7, "hồi HP cộng thẳng");
    context.expect(body.stat(Stat::kResistCold) == 5 && body.stat(Stat::kResistFire) == 5 &&
            body.stat(Stat::kResistLight) == 5 && body.stat(Stat::kResistPoison) == 5,
        "kháng cả bốn hệ");
    context.expect(body.stat(Stat::kAttackSpeed) == 25, "giảm 90 từ 100 kẹp ở 25");
    context.expect(body.immunity_phy() == 30 && body.raw(AttrId::kImmunityP) == 30 && body.immunity_magic() == 0,
        "miễn ngoại công");
    // Gỡ trang bị thì về chỉ số trần.
    body.set_equipment(Modifiers{});
    expect_stats(context, body, {8, 1, 10, 2, 4, 1080, 175, 94, 20, 129, 36, 48, 15, 2}, "gỡ trang bị");
    // Buff trừ vượt quá: chỉ số kẹp ở 0; nguồn trang bị và buff tách nhau.
    Modifiers curse;
    curse.add_point(Stat::kDefencePhy, -100000);
    curse.add_point(Stat::kAttackSpeed, -1000);
    body.set_buffs(curse);
    context.expect(body.stat(Stat::kDefencePhy) == 0 && body.stat(Stat::kAttackSpeed) == 400, "kẹp 0 và kẹp 400");
    // Cộng tràn int32 không quay vòng.
    Modifiers huge;
    huge.add_point(Stat::kMaxHp, std::numeric_limits<std::int32_t>::max());
    huge.add_point(Stat::kMaxHp, std::numeric_limits<std::int32_t>::max());
    context.expect(huge.point[Stat::kMaxHp] == std::numeric_limits<std::int32_t>::max(),
        "cộng bão hoà");
}

void monster_body(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    const MonsterRow* row = r->monster(100);
    if (row == nullptr) {
        context.expect(false, "quái 100");
        return;
    }
    Body mob = Body::monster(*r, BodyLimits{}, *row);
    context.expect(!mob.is_human() && mob.alive() && mob.hp() == 6876 && mob.mp() == 1432, "quái đầy HP/MP");
    context.expect(mob.stat(Stat::kAttackPhy) == 1260 && mob.stat(Stat::kDefencePhy) == 592 && mob.stat(Stat::kHit) == 551 &&
            mob.stat(Stat::kMiss) == 87 && mob.stat(Stat::kCritical) == 4 && mob.stat(Stat::kCriticalDefence) == 4,
        "chỉ số quái lấy từ bảng");
    context.expect(mob.stat(Stat::kMoveSpeed) == 1800 && mob.stat(Stat::kResistCold) == 60 && mob.camp() == 8 &&
            mob.stat(Stat::kMaxRage) == 0 && mob.stat(Stat::kStr) == 0,
        "tốc độ, kháng, thế lực, không có nộ khí");
    context.expect(mob.fluctuation() == 8 && mob.level() == 45, "dao động mặc định của quái");
    Modifiers buff;
    buff.add_rate(Stat::kDefencePhy, 10);
    buff.add_point(Stat::kDefencePhy, -92);
    mob.set_buffs(buff);
    context.expect(mob.stat(Stat::kDefencePhy) == 592 + 59 - 92, "buff phần trăm và điểm cùng lúc");
    // Quái không lên cấp, không nhận kinh nghiệm, không sinh nộ khí.
    context.expect(mob.add_exp(100000).levels_gained == 0 && mob.gain_rage(RageTrigger::kDamaged, 1000) == 0,
        "quái không có kinh nghiệm và nộ khí");
    const HpChange hit = mob.change_hp(-100000);
    context.expect(hit.died && hit.applied == -6876 && !mob.alive() && mob.hp() == 0, "quái chết");
}

// --- lên cấp, kinh nghiệm ---

void multi_level_up(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    const BodyLimits limits;
    Body body = Body::human(*r, limits, Body::new_record(*r, limits, 0));
    // 1000 = 90 (cấp 1) + 324 (cấp 2) + 586 còn lại, chưa đủ 630 của cấp 3: lên hai cấp trong một lượt.
    const LevelUp up = body.add_exp(1000);
    context.expect(up.levels_gained == 2 && up.exp_after == 1000 - 90 - 324 && body.level() == 3, "lên hai cấp một lượt");
    context.expect(body.record().points == std::array<std::int32_t, 5>{11, 2, 15, 3, 4} && body.record().remain_points == 0,
        "điểm sau cấp 3 = tổng hàng 0..3 của bảng");
    context.expect(body.hp() == body.stat(Stat::kMaxHp) && body.mp() == body.stat(Stat::kMaxMp), "lên cấp đầy HP/MP");
    context.expect(body.add_exp(0).levels_gained == 0, "không thêm kinh nghiệm thì không lên cấp");
}

void level_to_cap(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    const BodyLimits limits;
    Body body = Body::human(*r, limits, Body::new_record(*r, limits, 0));
    const LevelUp up = body.add_exp(std::numeric_limits<std::uint64_t>::max());
    // Tổng kinh nghiệm cấp 1..149 = 55580288205 (cộng bảng ngoài); dư bị kẹp ở 4 lần mức cấp 150.
    context.expect(up.levels_gained == 149 && body.level() == 150, "lên tới cấp tối đa");
    context.expect(up.exp_after == 4ULL * 1707414660ULL && body.record().exp == up.exp_after, "kinh nghiệm dư kẹp 4 lần");
    context.expect(body.record().points == std::array<std::int32_t, 5>{100, 13, 138, 26, 38} && body.record().remain_points == 455,
        "điểm cấp 150 của phái 0 (dưới 60 vào điểm cấp một, từ 60 vào điểm tự do)");
    expect_stats(context, body, {100, 13, 138, 26, 38, 21215, 4500, 1928, 632, 2414, 1024, 1237, 381, 10}, "phái 0 cấp 150");
    context.expect(body.add_exp(5).levels_gained == 0 && body.level() == 150, "ở cấp tối đa không lên nữa");
    // Mượn phái mẫu: phái 12 đi từ cấp 1 lên 150 ra đúng chỉ số của phái 3.
    const Record guigu = Body::new_record(*r, limits, 12);
    Body mudang = Body::human(*r, limits, guigu);
    static_cast<void>(mudang.add_exp(std::numeric_limits<std::uint64_t>::max()));
    expect_stats(context, mudang, {13, 127, 75, 63, 37, 11010, 7576, 736, 2492, 1012, 1646, 1324, 473, 11}, "phái 12 lên cấp 150");
}

void spend_wash_change(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    Body body = Body::human(*r, BodyLimits{}, record_of(3, 60, {13, 127, 75, 63, 37}, 5));
    context.expect(body.spend_point(1, 3) && body.record().points[1] == 130 && body.record().remain_points == 2, "cộng 3 điểm");
    context.expect(!body.spend_point(0, 3) && body.record().remain_points == 2, "hết điểm thì từ chối, không đổi gì");
    context.expect(!body.spend_point(5, 1) && !body.spend_point(0, 0) && !body.spend_point(0, -1), "chỉ số và số lượng lạ");
    context.expect(body.wash_points() && body.record().points == std::array<std::int32_t, 5>{13, 127, 75, 63, 37} &&
            body.record().remain_points == 5,
        "tẩy điểm trả về đúng bảng");
    context.expect(body.change_sect(5) && body.sect() == 5 && body.record().points == std::array<std::int32_t, 5>{13, 114, 100, 63, 25} &&
            body.record().remain_points == 5,
        "đổi sang phái 5");
    expect_stats(context, body, {13, 114, 100, 63, 25, 8930, 4848, 337, 1356, 723, 1124, 520, 260, 8}, "phái 5 cấp 60");
    context.expect(!body.change_sect(16), "phái ngoài miền");
}

void attenuated_exp(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    const MonsterRow* mob = r->monster(100); // cấp 45, kinh nghiệm cơ bản 529
    if (mob == nullptr) {
        context.expect(false, "quái 100");
        return;
    }
    const BodyLimits limits;
    context.expect(monster_exp(*r, limits, 45, *mob, 0) == 529, "cùng cấp: nguyên");
    context.expect(monster_exp(*r, limits, 35, *mob, 0) == 502, "quái hơn 10 cấp: 0,95 -> 502,55 cắt xuống 502");
    context.expect(monster_exp(*r, limits, 35, *mob, 50) == 753, "cộng 50%: 502 * 150 / 100");
    context.expect(monster_exp(*r, limits, 100, *mob, 0) == 52, "người hơn 55 cấp: 0,1 -> 52,9 cắt xuống 52");
    BodyLimits doubled;
    doubled.exp_factor_permille = 2000;
    context.expect(monster_exp(*r, doubled, 35, *mob, 0) == 1004, "hệ số toàn cục 2");
    context.expect(monster_exp(*r, limits, 35, *mob, -500) == 0, "giảm quá 100% thì về 0");
    MonsterRow empty = *mob;
    empty.base_exp = -1;
    context.expect(monster_exp(*r, limits, 35, empty, 0) == 0, "kinh nghiệm cơ bản âm thì 0");
}

// --- sống, chết, nộ khí ---

void regen_and_clamp(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    Body body = Body::human(*r, BodyLimits{}, record_of(0, 1, {8, 1, 10, 2, 4}, 0));
    Modifiers equip;
    static_cast<void>(equip.add_item({.attr_id = 2, .value = 7}));
    static_cast<void>(equip.add_item({.attr_id = 5, .value = 3}));
    body.set_equipment(equip);
    context.expect(body.change_hp(-500).applied == -500 && body.hp() == 580, "mất 500 HP");
    context.expect(body.change_mp(-100) == -100 && body.mp() == 75, "mất 100 MP");
    context.expect(body.advance(2999) == 0 && body.hp() == 580, "chưa đủ 3000 ms thì chưa hồi");
    context.expect(body.advance(1) == 1 && body.hp() == 587 && body.mp() == 78, "đủ 3000 ms: một nhịp");
    context.expect(body.rage() == 2, "nộ khí tự hồi 2 mỗi nhịp");
    context.expect(body.advance(6000) == 2 && body.hp() == 601 && body.mp() == 84, "6000 ms: hai nhịp");
    context.expect(body.advance(0) == 0 && body.advance(-5) == 0, "thời gian không dương thì không hồi");
    const HpChange full = body.change_hp(1'000'000);
    context.expect(full.applied == 1080 - 601 && body.hp() == 1080 && !full.died, "hồi không vượt tối đa");
    context.expect(body.change_mp(std::numeric_limits<std::int64_t>::min()) < 0 && body.mp() == 0, "MP về 0 khi trừ cực lớn");
    context.expect(body.change_mp(std::numeric_limits<std::int64_t>::max()) > 0 && body.mp() == body.stat(Stat::kMaxMp),
        "MP kẹp ở tối đa khi cộng cực lớn");
    context.expect(body.change_hp(std::numeric_limits<std::int64_t>::max()).applied == 0, "HP đầy cộng cực lớn không tràn");
    context.expect(body.advance(std::numeric_limits<std::int64_t>::max()) > 0, "thời gian cực lớn bị chặn, không tràn");
}

void death_and_revive(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    Body body = Body::human(*r, BodyLimits{}, record_of(0, 1, {8, 1, 10, 2, 4}, 0));
    static_cast<void>(body.change_rage(300));
    const HpChange fatal = body.change_hp(std::numeric_limits<std::int64_t>::min());
    context.expect(fatal.died && fatal.applied == -1080 && !body.alive() && body.hp() == 0 && body.rage() == 0, "chết");
    context.expect(body.change_hp(5).applied == 0 && body.change_mp(5) == 0 && body.advance(10000) == 0 && !body.kill(),
        "thân chết không đổi gì");
    context.expect(body.add_exp(0).levels_gained == 0 && body.gain_rage(RageTrigger::kDamaged, 1000) == 0, "chết không nhận nộ khí");
    context.expect(body.revive({.hp = Amount{.percent = true, .value = 50}, .mp = Amount{.percent = true, .value = 0},
        .rage = Amount{.percent = false, .value = 100}}), "hồi sinh");
    context.expect(body.alive() && body.hp() == 540 && body.mp() == 0 && body.rage() == 100, "hồi sinh 50% HP và 100 nộ khí");
    context.expect(!body.revive({.hp = Amount{.percent = true, .value = 100}, .mp = Amount{.percent = true, .value = 100},
                     .rage = Amount{.percent = true, .value = 100}}), "đang sống thì không hồi sinh");
    static_cast<void>(body.kill());
    context.expect(body.revive({.hp = Amount{.percent = false, .value = 0}, .mp = Amount{.percent = false, .value = -5},
                     .rage = Amount{.percent = true, .value = 500}}) && body.hp() == 1 && body.mp() == 0 &&
            body.rage() == 1000,
        "HP tối thiểu 1, MP âm thành 0, nộ khí kẹp ở tối đa");
}

void rage_rules(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    const BodyLimits limits;
    Body shaolin = Body::human(*r, limits, Body::new_record(*r, limits, 0));
    context.expect(shaolin.gain_rage(RageTrigger::kDamaged, 1000) == 8 && shaolin.gain_rage(RageTrigger::kDealDamage, 1000) == 4,
        "Thiếu Lâm: 8 và 4 trên 1000 điểm sát thương (bảng hệ số)");
    context.expect(shaolin.gain_rage(RageTrigger::kDamaged, 0) == 0 && shaolin.gain_rage(RageTrigger::kDamaged, -50) == 0 &&
            shaolin.gain_rage(RageTrigger::kHealDone, 1000) == 0 && shaolin.gain_rage(RageTrigger::kDamaged, 100) == 0,
        "giá trị không dương, sự kiện không có luật, phần lẻ cắt xuống");
    Body none = Body::human(*r, limits, Body::new_record(*r, limits, 9));
    context.expect(none.gain_rage(RageTrigger::kDamaged, 100000) == 0, "không phái không sinh nộ khí theo sát thương");
    Body gaibang = Body::human(*r, limits, Body::new_record(*r, limits, 2));
    gaibang.gain_strike(5);
    gaibang.gain_strike(5);
    context.expect(gaibang.strike_points() == 6, "điểm liên kích kẹp ở tối đa 6");
    context.expect(!gaibang.spend_strike(7) && !gaibang.spend_strike(0) && gaibang.strike_points() == 6, "không đủ thì từ chối");
    context.expect(gaibang.spend_strike(3) && gaibang.strike_points() == 3 && gaibang.rage() == 30, "tiêu 3 điểm: 30 nộ khí");
    Modifiers buff;
    buff.rage_gain_percent = 50;
    gaibang.set_buffs(buff);
    context.expect(gaibang.spend_strike(2) && gaibang.rage() == 30 + 30, "buff +50% nộ khí: 20 thành 30");
    Body emei = Body::human(*r, limits, Body::new_record(*r, limits, 4));
    context.expect(emei.gain_rage(RageTrigger::kHealDone, 400) == 20, "Nga Mi: hồi máu 400 thành 20 nộ khí");
    Body tangmen_like = Body::human(*r, limits, Body::new_record(*r, limits, 13));
    context.expect(tangmen_like.gain_rage(RageTrigger::kHealDone, 400) == 20, "phái 13 mượn luật Nga Mi");
    Body xiaoyao = Body::human(*r, limits, Body::new_record(*r, limits, 8));
    context.expect(xiaoyao.gain_rage(RageTrigger::kTrapTriggered, 1) == 10, "Tiêu Dao: bẫy nổ 10 nộ khí");
    static_cast<void>(xiaoyao.gain_rage(RageTrigger::kTrapTriggered, 100000));
    context.expect(xiaoyao.rage() == 1000, "nộ khí kẹp ở 1000");
}

void exp_loss(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    const BodyLimits limits;
    Body body = Body::human(*r, limits, Body::new_record(*r, limits, 0));
    static_cast<void>(body.add_exp(50));
    context.expect(body.lose_exp(Amount{.percent = true, .value = 10}) == 5 && body.record().exp == 45, "mất 10% của 50 = 5");
    context.expect(body.lose_exp(Amount{.percent = true, .value = 1000}) == 45 && body.record().exp == 0, "phần trăm quá 100 kẹp ở 100");
    context.expect(body.lose_exp(Amount{.percent = false, .value = -3}) == 0 && body.lose_exp(Amount{.percent = false, .value = 9}) == 0, "không có gì để mất");
    static_cast<void>(body.add_exp(50));
    context.expect(body.lose_exp(Amount{.percent = false, .value = 8}) == 8 && body.record().exp == 42, "mất số tuyệt đối");
}

void inner_arts(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    Body body = Body::human(*r, BodyLimits{}, record_of(0, 1, {8, 1, 10, 2, 4}, 0));
    context.expect(!body.set_inner_art(999999, 5), "tâm pháp không có trong bảng");
    context.expect(body.set_inner_art(1, 60) && body.stat(Stat::kHit) == 48 + 4, "tâm pháp 1 cấp 60: mốc 60 thêm 4 điểm trúng");
    context.expect(body.set_inner_art(1, 120) && body.stat(Stat::kHit) == 48 + 12 && body.record().inner_arts.size() == 1,
        "cấp 120: mốc 120");
    context.expect(body.set_inner_art(1, 50) && body.stat(Stat::kHit) == 48, "dưới mốc đầu có nghĩa: 0,2 làm tròn 0");
    context.expect(body.set_inner_art(1, 0) && body.record().inner_arts.empty(), "cấp 0 là gỡ");
    context.expect(body.set_inner_art(1, 0), "gỡ cái chưa có không lỗi");
}

// --- hình phạt chết ---

void penalty_ids_and_rolls(Context& context) {
    const Rules* r = rules(context);
    if (r == nullptr) return;
    context.expect(penalty_id(0, 5, 0, DieType::kMonster) == 1 && penalty_id(0, 30, 25, DieType::kPlayer) == 32 &&
            penalty_id(0, 30, -5, DieType::kDuel) == 10 && penalty_id(0, 10, 100, DieType::kMonster) == 61 &&
            penalty_id(1, 10, 0, DieType::kPlayer) == 112 && penalty_id(0, 10, 0, DieType::kMonster) == 11 &&
            penalty_id(0, 10, 79, DieType::kMonster) == 51 && penalty_id(0, 10, 80, DieType::kMonster) == 61,
        "id dòng phạt theo cảnh, sát khí và loại chết");
    dice::Dice dice(1);
    const std::optional<PenaltyOutcome> fixed = roll_penalty(*r, 11, dice);
    context.expect(fixed && fixed->money == Amount{.percent = true, .value = 10} && fixed->exp == Amount{.percent = false, .value = 0} &&
            fixed->equip_durability == Amount{.percent = true, .value = 1} && fixed->item_drop == Amount{.percent = false, .value = 0},
        "dòng phạt 11 không có khoảng ngẫu nhiên");
    context.expect(!roll_penalty(*r, 999'999, dice).has_value(), "dòng không có");
    std::array<bool, 7> money_seen{};
    for (std::uint64_t seed = 1; seed <= 400; ++seed) {
        dice::Dice a(seed);
        dice::Dice b(seed);
        const auto first = roll_penalty(*r, 21, a);
        const auto second = roll_penalty(*r, 21, b);
        context.expect(first && second && first->money == second->money && first->exp == second->exp, "cùng hạt giống cùng kết quả");
        if (!first) continue;
        const bool in_range = first->money.percent && first->money.value >= 11 && first->money.value < 18 &&
            first->exp.value >= 1 && first->exp.value < 10 && first->equip_durability.value >= 2 &&
            first->equip_durability.value < 20 && first->item_drop.value >= 0 && first->item_drop.value < 20;
        context.expect(in_range, "mỗi khoảng nằm trong [min, max)");
        if (first->money.value >= 11 && first->money.value < 18) money_seen.at(static_cast<std::size_t>(first->money.value - 11)) = true;
    }
    bool all = true;
    for (const bool seen : money_seen) all = all && seen;
    context.expect(all, "đủ 7 giá trị 11..17 xuất hiện");
}

// --- bản ghi bền ---

Record sample_record() {
    Record record = record_of(3, 77, {13, 127, 75, 63, 37}, 12);
    record.exp = 123456789012ULL;
    record.hp = 4000;
    record.mp = 99;
    record.rage = 250;
    record.strike_points = 4;
    record.inner_arts = {{1U, std::uint16_t{60}}, {7U, std::uint16_t{3}}, {9000U, std::uint16_t{65535}}};
    return record;
}

void codec_round_trip(Context& context) {
    const Record original = sample_record();
    Bytes bytes;
    context.expect(encode_record(original, bytes).has_value() && !bytes.empty(), "mã hoá");
    const auto decoded = decode_record(bytes, 150);
    context.expect(decoded && *decoded == original, "giải mã trả đúng bản ghi");
    // Gỡ nối thêm vào cuối vùng đệm có sẵn: Writer chỉ thêm, không ghi đè phần cũ.
    Bytes twice = bytes;
    context.expect(encode_record(original, twice).has_value() && twice.size() == 2 * bytes.size(), "ghi nối đuôi");
    // Bản ghi chết: HP 0, alive false.
    Record dead = original;
    dead.alive = false;
    dead.hp = 0;
    Bytes dead_bytes;
    context.expect(encode_record(dead, dead_bytes).has_value(), "mã hoá bản ghi chết");
    const auto dead_back = decode_record(dead_bytes, 150);
    context.expect(dead_back && *dead_back == dead, "bản ghi chết đi về nguyên vẹn");
}

void codec_rejects_bad_input(Context& context) {
    const Record original = sample_record();
    Bytes bytes;
    context.expect(encode_record(original, bytes).has_value(), "mã hoá để cắt ngắn");
    // Mọi tiền tố ngắn hơn đều là lỗi.
    bool all_truncated = true;
    for (std::size_t length = 0; length < bytes.size(); ++length) {
        all_truncated = all_truncated && !decode_record(std::span<const std::byte>(bytes).first(length), 150).has_value();
    }
    context.expect(all_truncated, "mọi tiền tố ngắn hơn bị từ chối");
    Bytes trailing = bytes;
    trailing.push_back(std::byte{0});
    context.expect(!decode_record(trailing, 150).has_value(), "byte thừa");
    context.expect(!decode_record(bytes, 76).has_value(), "cấp vượt cấp tối đa của bảng");
    // Lật từng bit: kết quả hoặc là lỗi hoặc là bản ghi hợp lệ, không bao giờ vi phạm bất biến.
    std::size_t accepted = 0;
    for (std::size_t at = 0; at < bytes.size(); ++at) {
        for (int bit = 0; bit < 8; ++bit) {
            Bytes mutated = bytes;
            mutated[at] = mutated[at] ^ static_cast<std::byte>(1U << bit);
            const auto result = decode_record(mutated, 150);
            if (!result) continue;
            ++accepted;
            const Record& got = *result;
            bool skills_hold = got.skills.size() <= kMaxLearnedSkills;
            for (std::size_t i = 0; i < got.skills.size(); ++i) {
                skills_hold = skills_hold && got.skills[i] != 0;
                if (i > 0) skills_hold = skills_hold && got.skills[i - 1] < got.skills[i];
            }
            context.expect(got.sect < kSectSlots && got.level >= 1 && got.level <= 150 && got.hp >= 0 && got.mp >= 0 &&
                    got.rage >= 0 && got.strike_points >= 0 && got.remain_points >= 0 && got.alive == (got.hp > 0) &&
                    got.inner_arts.size() <= kMaxInnerArtsPerRecord && skills_hold,
                "bản ghi chấp nhận luôn hợp lệ");
        }
    }
    context.expect(accepted > 0 && accepted < bytes.size() * 8, "có lật bit vẫn hợp lệ (số liệu) nhưng không phải tất cả");
    // Sai kind và sai phiên bản.
    Bytes wrong_kind = bytes;
    if (!wrong_kind.empty()) wrong_kind.front() = wrong_kind.front() ^ std::byte{1};
    const auto kind_result = decode_record(wrong_kind, 150);
    context.expect(!kind_result.has_value(), "đầu khung hỏng");
    // Bản ghi vi phạm bất biến không mã hoá được.
    Record bad = original;
    bad.sect = 16;
    Bytes sink;
    context.expect(!encode_record(bad, sink).has_value() && sink.empty(), "sect ngoài miền");
    bad = original;
    bad.alive = false;
    context.expect(!encode_record(bad, sink).has_value(), "chết mà HP dương");
    bad = original;
    bad.inner_arts = {{5U, std::uint16_t{1}}, {5U, std::uint16_t{2}}};
    context.expect(!encode_record(bad, sink).has_value(), "tâm pháp trùng id");
    bad = original;
    bad.inner_arts = {{5U, std::uint16_t{0}}};
    context.expect(!encode_record(bad, sink).has_value(), "tâm pháp cấp 0");
    bad = original;
    bad.points[2] = -1;
    context.expect(!encode_record(bad, sink).has_value() && sink.empty(), "điểm âm");
    context.expect(!describe(CodecError::kTruncated).empty() && !describe(static_cast<CodecError>(99)).empty(), "describe");
}

[[nodiscard]] std::uint16_t version_of(const Bytes& bytes) {
    const std::size_t at = protocol::kHeaderBytes;
    const auto low = static_cast<unsigned>(std::to_integer<unsigned char>(bytes.at(at)));
    const auto high = static_cast<unsigned>(std::to_integer<unsigned char>(bytes.at(at + 1)));
    return static_cast<std::uint16_t>(low | (high << 8));
}

void learned_skills_round_trip(Context& context) {
    const Rules* sheet = rules(context);
    if (sheet == nullptr) return;
    Body plain;
    context.expect(!plain.learn_skill(244), "thân chưa phải người không học");
    Body body = Body::human(*sheet, BodyLimits{}, record_of(3, 60, {13, 127, 75, 63, 37}, 5));
    context.expect(!body.learn_skill(0) && !body.skill_known(0), "mã 0 bị từ chối");
    context.expect(body.learn_skill(248) && body.learn_skill(244), "học hai kỹ năng");
    context.expect(body.record().skills == std::vector<std::uint32_t>{244U, 248U}, "giữ tăng dần");
    context.expect(body.learn_skill(244) && body.record().skills.size() == 2, "học lại không thêm dòng");
    context.expect(body.change_sect(5) && body.skill_known(244) && body.skill_known(248), "đổi phái không xoá kỹ năng");
    for (std::uint32_t id = 1; id <= kMaxLearnedSkills; ++id) static_cast<void>(body.learn_skill(id));
    context.expect(body.record().skills.size() == kMaxLearnedSkills, "đầy sổ");
    context.expect(!body.learn_skill(1000), "sổ đầy thì từ chối mã mới");
    context.expect(body.learn_skill(244), "mã đã biết vẫn đúng khi đầy");
    Record empty = sample_record();
    Bytes empty_bytes;
    context.expect(encode_record(empty, empty_bytes).has_value(), "mã hoá sổ rỗng");
    context.expect(version_of(empty_bytes) == kRecordVersion, "sổ rỗng là phiên bản 1");
    Record learned = empty;
    learned.skills = {244U, 248U};
    Bytes learned_bytes;
    context.expect(encode_record(learned, learned_bytes).has_value(), "mã hoá có kỹ năng");
    context.expect(version_of(learned_bytes) == kRecordVersionSkills, "có kỹ năng là phiên bản 2");
    const auto back = decode_record(learned_bytes, 150);
    context.expect(back && *back == learned, "giải mã trả đúng danh sách");
    Record messy = learned;
    messy.skills = {248U, 244U};
    Bytes sink;
    context.expect(!encode_record(messy, sink).has_value(), "không tăng dần thì không ghi");
    messy.skills = {0U};
    context.expect(!encode_record(messy, sink).has_value(), "mã 0 không ghi");
    messy.skills = {244U, 244U};
    context.expect(!encode_record(messy, sink).has_value(), "trùng id không ghi");
}

constexpr std::array<Case, 18> kCases{{
    {.name = "rules_load_real_tables", .body = rules_load_real_tables},
    {.name = "rules_reject_bad_tables", .body = rules_reject_bad_tables},
    {.name = "stats_golden", .body = stats_golden},
    {.name = "equipment_golden", .body = equipment_golden},
    {.name = "monster_body", .body = monster_body},
    {.name = "multi_level_up", .body = multi_level_up},
    {.name = "level_to_cap", .body = level_to_cap},
    {.name = "spend_wash_change", .body = spend_wash_change},
    {.name = "attenuated_exp", .body = attenuated_exp},
    {.name = "regen_and_clamp", .body = regen_and_clamp},
    {.name = "death_and_revive", .body = death_and_revive},
    {.name = "rage_rules", .body = rage_rules},
    {.name = "exp_loss", .body = exp_loss},
    {.name = "inner_arts", .body = inner_arts},
    {.name = "penalty_ids_and_rolls", .body = penalty_ids_and_rolls},
    {.name = "codec_round_trip", .body = codec_round_trip},
    {.name = "codec_rejects_bad_input", .body = codec_rejects_bad_input},
    {.name = "learned_skills_round_trip", .body = learned_skills_round_trip},
}};

} // namespace
} // namespace game::actor

int main() {
    return game::test::run_all(game::actor::kCases);
}
