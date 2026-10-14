// Điều kiện/hiệu ứng đóng: sai thì quest, hội thoại và thưởng lệch thầm (điều kiện nhận sai, hiệu ứng áp dụng sai chỗ)
// mà chạy và nhìn không lộ. Số vàng của mã tên và mã chuỗi tính độc lập bằng Python (công cụ trích dùng cùng công thức:
// TOOLS/server/lua_world.norm_name + lua_emit.fnv1a32), ghi ở từng ca; bảng thật chỉ đọc khi có GAME_SERVER_TABLES.
#include "ops/ops.hpp"
#include "support/ops_fakes.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>

#ifdef GAME_SERVER_TABLES
#include <algorithm>
#include <cstdio>
#include <fstream>
#include <ios>
#include <iterator>
#include <print>
#endif

namespace game::test {
namespace {

using ops::Atom;
using ops::CondSet;
using ops::Metric;
using ops::Op;
using ops::Program;

Atom at_least(Metric metric, std::int32_t a1, std::int32_t a2 = 0, std::int32_t a3 = 0, bool negated = false) {
    Atom atom;
    atom.op = Op::kAtLeast;
    atom.metric = metric;
    atom.negated = negated;
    atom.arg = {a1, a2, a3};
    return atom;
}

Atom predicate(Op op, std::int32_t a1, bool negated = false) {
    Atom atom;
    atom.op = op;
    atom.negated = negated;
    atom.arg = {a1, 0, 0};
    return atom;
}

table::Tsv parse(std::string_view text) {
    auto parsed = table::parse_tsv(text);
    return parsed ? *parsed : table::Tsv{};
}

constexpr std::string_view kCondHeader = "set\tclause\tseq\top\tneg\ta1\ta2\ta3\tword\n";
constexpr std::string_view kEffectHeader = "set\tseq\top\ta1\ta2\ta3\ttext\targs\tcond\n";

std::string conditions(std::string_view rows) { return std::string(kCondHeader) + std::string(rows); }
std::string effects(std::string_view rows) { return std::string(kEffectHeader) + std::string(rows); }

void golden_ids(Context& context) {
    // Python: norm_name rồi fnv1a32 & 0x7FFFFFFF; fnv1a32 của khoá chuỗi.
    context.expect(ops::name_id(" #R君 还珠 ") == 0x3363B19EU, "tên có thẻ màu và khoảng trắng");
    context.expect(ops::name_id("君还珠") == 0x3363B19EU, "tên đã sạch cho cùng mã");
    context.expect(ops::name_id("西北狼") == 0x6F0D019FU, "西北狼");
    context.expect(ops::name_id("周无畏") == 0x3AF9DFF3U, "周无畏");
    context.expect(ops::name_id("\xE3\x80\x80叶二娘 ") == 0x432E6404U, "khoảng trắng U+3000");
    context.expect(ops::name_id("#G段正淳（大理）#W") == 0x515481DCU, "ngoặc đầy đủ giữ nguyên");
    context.expect(ops::name_id("abc") == 0x1A47E90BU, "ASCII");
    context.expect(ops::name_id("") == (0x811C9DC5U & 0x7FFFFFFFU), "tên rỗng là hằng offset");
    context.expect(ops::string_id("MIS_TAR_ADD_036") == 523154822U, "string_id của khoá client");
    context.expect(ops::string_id("lua.147ac5d1") == 0x3C7ABD1FU, "string_id của khoá chữ hằng");
}

void dnf_semantics(Context& context) {
    FakeHero hero;
    hero.level_value = 25;
    hero.items[100] = 5;
    const ops::Context ctx{.hero = &hero};
    // (level>=20 AND NOT level>=30) OR item(100)>=9
    CondSet set;
    set.clauses.push_back({at_least(Metric::kLevel, 20), at_least(Metric::kLevel, 30, 0, 0, true)});
    set.clauses.push_back({at_least(Metric::kItemCount, 100, 9)});
    context.expect(ops::holds(set, ctx), "mệnh đề đầu đúng ở cấp 25");
    hero.level_value = 30;
    context.expect(!ops::holds(set, ctx), "cấp 30 phá mệnh đề đầu, mệnh đề hai thiếu đồ");
    hero.items[100] = 9;
    context.expect(ops::holds(set, ctx), "mệnh đề hai đúng khi đủ đồ");
    context.expect(!ops::holds(CondSet{}, ctx), "không có mệnh đề là luôn sai");
    CondSet empty_clause;
    empty_clause.clauses.emplace_back();
    context.expect(ops::holds(empty_clause, ctx), "mệnh đề rỗng là luôn đúng");
}

void metrics_and_predicates(Context& context) {
    FakeHero hero;
    hero.money_value = 700;
    hero.bound_money_value = 50;
    hero.objectives[{453U, 1}] = 4;
    hero.counters[63] = 12;
    hero.active.insert(7);
    hero.names[7] = ops::name_id("阿碧任务");
    hero.impacts.insert(25515);
    hero.done.insert(9);
    hero.abilities[10] = 3;
    hero.skills.insert(103);
    hero.flags.insert(5);
    hero.team_leader_value = true;
    const ops::Context ctx{.hero = &hero, .calendar = {.day = 100, .hour_time = 9, .quarter_time = 3, .hour = 14, .weekday = 2},
        .event = {.monster = 321, .monster_name = ops::name_id("西北狼"), .area = 8, .item = 77}, .radio = 555,
        .target_name = ops::name_id("周无畏")};
    context.expect(ops::holds(at_least(Metric::kMoney, 0, 700), ctx), "tiền thường 700");
    context.expect(!ops::holds(at_least(Metric::kMoney, 1, 51), ctx), "tiền khoá chưa tới 51");
    context.expect(ops::holds(at_least(Metric::kObjective, 453, 1, 4), ctx), "mục tiêu 453/1 >= 4");
    context.expect(!ops::holds(at_least(Metric::kObjective, 453, 1, 5), ctx), "mục tiêu 453/1 < 5");
    context.expect(ops::holds(at_least(Metric::kCounter, 63, 12), ctx), "bộ đếm 63");
    context.expect(ops::holds(at_least(Metric::kHour, 14), ctx), "giờ từ lịch");
    context.expect(ops::holds(at_least(Metric::kClock, 1, 100), ctx) && !ops::holds(at_least(Metric::kClock, 1, 101), ctx),
        "đồng hồ ngày");
    context.expect(ops::holds(at_least(Metric::kMonster, 321), ctx), "mẫu quái của sự kiện");
    context.expect(ops::holds(at_least(Metric::kRadio, 555), ctx), "lựa chọn thưởng");
    context.expect(ops::holds(at_least(Metric::kAbility, 10, 3), ctx), "kỹ năng sống 10 cấp 3");
    context.expect(ops::holds(predicate(Op::kQuestActive, 7), ctx) && !ops::holds(predicate(Op::kQuestActive, 8), ctx),
        "quest_active");
    context.expect(ops::holds(predicate(Op::kQuestDone, 9), ctx) && !ops::holds(predicate(Op::kQuestDone, 9, true), ctx),
        "quest_done và phủ định");
    context.expect(ops::holds(predicate(Op::kSkillKnown, 103), ctx), "skill_known");
    context.expect(ops::holds(predicate(Op::kFlagSet, 5), ctx), "flag_set");
    context.expect(ops::holds(predicate(Op::kImpactActive, 25515), ctx) && !ops::holds(predicate(Op::kImpactActive, 25516), ctx),
        "impact_active");
    context.expect(ops::holds(predicate(Op::kTeamLeader, 0), ctx), "team_leader");
    context.expect(!ops::holds(predicate(Op::kQuestActive, -3), ctx), "id nhiệm vụ âm không dùng làm chỉ số");
    Atom target;
    target.op = Op::kTargetName;
    target.name = ops::name_id("周无畏");
    context.expect(ops::holds(target, ctx), "target_name khớp");
    target.name = ops::name_id("他人");
    context.expect(!ops::holds(target, ctx), "target_name lệch");
    Atom kill;
    kill.op = Op::kEventMonsterName;
    kill.name = ops::name_id("西北狼");
    context.expect(ops::holds(kill, ctx), "event_monster_name khớp");
    Atom named;
    named.op = Op::kQuestNamed;
    named.arg = {7, 0, 0};
    named.name = ops::name_id("阿碧任务");
    context.expect(ops::holds(named, ctx), "quest_named: tên nhiệm vụ đang giữ khớp");
    named.name = ops::name_id("阿朱任务");
    context.expect(!ops::holds(named, ctx), "quest_named: tên khác");
    named.name = ops::name_id("阿碧任务");
    named.arg = {8, 0, 0};
    context.expect(!ops::holds(named, ctx), "quest_named: không giữ nhiệm vụ 8");
    named.arg = {-1, 0, 0};
    context.expect(!ops::holds(named, ctx), "quest_named: id âm");
    named.arg = {7, 0, 0};
    named.negated = true;
    context.expect(!ops::holds(named, ctx), "quest_named: phủ định");
}

void counter_versus_clock(Context& context) {
    FakeHero hero;
    hero.counters[40] = 99;
    const ops::Context ctx{.hero = &hero, .calendar = {.day = 100}};
    Atom atom;
    atom.op = Op::kCounterVsClock;
    atom.arg = {40, 1, -1};
    context.expect(ops::holds(atom, ctx), "bộ đếm 99 < ngày 100");
    atom.arg = {40, 1, 0};
    context.expect(!ops::holds(atom, ctx), "không bằng ngày");
    hero.counters[40] = 100;
    context.expect(ops::holds(atom, ctx), "đúng ngày hôm nay (giới hạn mỗi ngày)");
    atom.arg = {40, 1, 1};
    hero.counters[40] = 101;
    context.expect(ops::holds(atom, ctx), "bộ đếm ở tương lai");
    context.expect(ops::holds(predicate(Op::kNever, 0, true), ctx), "never phủ định là đúng");
    context.expect(!ops::holds(predicate(Op::kNever, 0), ctx), "never là sai");
}

void load_accepts_valid_tables(Context& context) {
    const auto cond_table = parse(conditions(
        "1\t0\t0\tlevel_at_least\t0\t10\t0\t0\t\n"
        "1\t0\t1\tquest_done\t1\t5\t0\t0\t\n"
        "2\t0\t0\ttarget_name\t0\t0\t0\t0\t周无畏\n"
        "2\t1\t0\tnever\t0\t0\t0\t0\t\n"));
    const auto effect_table = parse(effects(
        "1\t0\tgive_exp\t900\t0\t0\t\t\t1\n"
        "1\t1\tnotify\t0\t0\t0\tlua.147ac5d1\tplayer,counter:63,objective:453:1\t-1\n"
        "2\t0\tobjective_add\t453\t1\t1\t\t\t-1\n"));
    const auto program = Program::load(cond_table, effect_table);
    context.expect(program.has_value(), "bảng hợp lệ nạp được");
    if (!program) return;
    context.expect(program->condition_count() == 2 && program->effect_list_count() == 2, "đủ hai bộ mỗi loại");
    const ops::EffectList* list = program->effect_list(1);
    context.expect(list != nullptr && list->effects.size() == 2, "bộ 1 có hai hiệu ứng");
    if (list == nullptr || list->effects.size() != 2) return;
    context.expect(list->effects[0].op == ops::EffectOp::kGiveExp && list->effects[0].cond == 1, "give_exp có cond 1");
    const ops::TextRef& text = list->effects[1].text;
    context.expect(text.id == ops::string_id("lua.147ac5d1") && text.params.size() == 3, "chuỗi và ba tham số");
    if (text.params.size() == 3) {
        context.expect(text.params[0].kind == ops::TextParam::Kind::kPlayer, "tham số player");
        context.expect(text.params[1].kind == ops::TextParam::Kind::kMetric && text.params[1].metric == Metric::kCounter &&
                           text.params[1].arg[0] == 63,
            "tham số counter:63");
        context.expect(text.params[2].metric == Metric::kObjective && text.params[2].arg[0] == 453 && text.params[2].arg[1] == 1,
            "tham số objective:453:1");
    }
    context.expect(program->holds(-1, ops::Context{}), "id -1 luôn đúng, kể cả không có góc nhìn");
    context.expect(!program->has_effects(9) && program->has_effects(-1), "has_effects");
}

void load_rejects_hostile_tables(Context& context) {
    const auto good_effects = parse(effects("1\t0\tgive_exp\t1\t0\t0\t\t\t-1\n"));
    const auto good_conditions = parse(conditions("1\t0\t0\tlevel_at_least\t0\t1\t0\t0\t\n"));
    struct BadCondition {
        std::string_view rows;
        ops::LoadError expected;
        std::string_view what;
    };
    const std::array<BadCondition, 7> bad_conditions{{
        {.rows = "1\t0\t0\tfly_to_moon\t0\t1\t0\t0\t\n", .expected = ops::LoadError::kUnknownOp, .what = "op lạ"},
        {.rows = "1\t0\t0\tlevel_at_least\t0\tx\t0\t0\t\n", .expected = ops::LoadError::kBadNumber, .what = "ô số hỏng"},
        {.rows = "1\t0\t0\tlevel_at_least\t0\t99999999999\t0\t0\t\n", .expected = ops::LoadError::kBadNumber, .what = "số tràn int32"},
        {.rows = "1\t0\t0\tlevel_at_least\t2\t1\t0\t0\t\n", .expected = ops::LoadError::kOutOfRange, .what = "neg ngoài 0/1"},
        {.rows = "2\t0\t0\tlevel_at_least\t0\t1\t0\t0\t\n", .expected = ops::LoadError::kSetIdGap, .what = "id bộ nhảy cóc"},
        {.rows = "1\t1\t0\tlevel_at_least\t0\t1\t0\t0\t\n", .expected = ops::LoadError::kSetIdGap, .what = "clause nhảy cóc"},
        {.rows = "1\t0\t0\twarp_at_least\t0\t1\t0\t0\t\n", .expected = ops::LoadError::kUnknownOp, .what = "đại lượng lạ"},
    }};
    for (const BadCondition& bad : bad_conditions) {
        const auto result = Program::load(parse(conditions(bad.rows)), good_effects);
        context.expect(!result.has_value() && result.error().error == bad.expected, bad.what);
    }
    std::string huge;
    for (std::size_t clause = 0; clause <= ops::kMaxClauses; ++clause) {
        huge += "1\t" + std::to_string(clause) + "\t0\tlevel_at_least\t0\t1\t0\t0\t\n";
    }
    const auto too_many = Program::load(parse(conditions(huge)), good_effects);
    context.expect(!too_many.has_value() && too_many.error().error == ops::LoadError::kTooLarge, "quá nhiều mệnh đề");
    struct BadEffect {
        std::string_view rows;
        ops::LoadError expected;
        std::string_view what;
    };
    const std::array<BadEffect, 4> bad_effects{{
        {.rows = "1\t0\tdelete_world\t1\t0\t0\t\t\t-1\n", .expected = ops::LoadError::kUnknownOp, .what = "hiệu ứng lạ"},
        {.rows = "1\t0\tgive_exp\t1\t0\t0\t\t\t7\n", .expected = ops::LoadError::kBadReference, .what = "cond trỏ vào bộ không có"},
        {.rows = "1\t0\tnotify\t0\t0\t0\tlua.1\tmystery:1\t-1\n", .expected = ops::LoadError::kUnknownMetric, .what = "tham số chuỗi lạ"},
        {.rows = "1\t0\tgive_exp\t1\t0\t0\t\t\t0\n", .expected = ops::LoadError::kBadReference, .what = "cond 0 không hợp lệ"},
    }};
    for (const BadEffect& bad : bad_effects) {
        const auto result = Program::load(good_conditions, parse(effects(bad.rows)));
        context.expect(!result.has_value() && result.error().error == bad.expected, bad.what);
    }
    std::string many_effects;
    for (std::size_t index = 0; index <= ops::kMaxSetEffects; ++index) {
        many_effects += "1\t" + std::to_string(index) + "\tgive_exp\t1\t0\t0\t\t\t-1\n";
    }
    const auto crowded = Program::load(good_conditions, parse(effects(many_effects)));
    context.expect(!crowded.has_value() && crowded.error().error == ops::LoadError::kTooLarge, "quá nhiều hiệu ứng");
}

void plan_uses_snapshot(Context& context) {
    // Chuỗi if/elseif của script gốc: hai nhánh loại trừ theo cấp; đánh giá trên trạng thái TRƯỚC khi áp dụng.
    const auto cond_table = parse(conditions(
        "1\t0\t0\tlevel_at_least\t0\t20\t0\t0\t\n"
        "1\t0\t1\tlevel_at_least\t1\t30\t0\t0\t\n"
        "2\t0\t0\tlevel_at_least\t0\t30\t0\t0\t\n"));
    const auto effect_table = parse(effects(
        "1\t0\tgive_exp\t20000\t0\t0\t\t\t1\n"
        "1\t1\tgive_exp\t60000\t0\t0\t\t\t2\n"
        "1\t2\tquest_remove\t1450\t0\t0\t\t\t-1\n"));
    const auto program = Program::load(cond_table, effect_table);
    context.expect(program.has_value(), "nạp được");
    if (!program) return;
    FakeHero hero;
    hero.level_value = 25;
    const ops::Context ctx{.hero = &hero};
    const ops::Plan plan = program->plan(1, ctx);
    context.expect(plan.steps.size() == 2, "cấp 25: nhánh 20000 và quest_remove");
    if (plan.steps.size() == 2) {
        context.expect(plan.steps[0]->arg[0] == 20000 && plan.steps[1]->op == ops::EffectOp::kQuestRemove, "đúng thứ tự");
    }
    hero.level_value = 30;
    const ops::Plan high = program->plan(1, ctx);
    context.expect(high.steps.size() == 2 && high.steps[0]->arg[0] == 60000, "cấp 30: nhánh 60000");
    hero.level_value = 5;
    context.expect(program->plan(1, ctx).steps.size() == 1, "cấp 5: chỉ hiệu ứng vô điều kiện");
    context.expect(program->plan(99, ctx).steps.empty() && program->plan(-1, ctx).steps.empty(), "bộ không có là kế hoạch rỗng");
    context.expect(!program->holds(99, ctx), "id điều kiện không có là sai (dữ liệu hỏng không cho qua)");
}

#ifdef GAME_SERVER_TABLES
std::string read_file(const std::string& path) {
    std::ifstream stream(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>()};
}

void real_tables_load(Context& context) {
    const std::string root = GAME_SERVER_TABLES;
    const std::string cond_text = read_file(root + "/server/ops_conditions.tsv");
    const std::string effect_text = read_file(root + "/server/ops_effects.tsv");
    if (cond_text.empty() || effect_text.empty()) return;
    const auto cond_table = table::parse_tsv(cond_text);
    const auto effect_table = table::parse_tsv(effect_text);
    context.expect(cond_table.has_value() && effect_table.has_value(), "hai bảng TSV parse được");
    if (!cond_table || !effect_table) return;
    const auto program = Program::load(*cond_table, *effect_table);
    context.expect(program.has_value(), "bảng thật nạp được");
    if (!program) {
        std::print(stderr, "dòng {}: {} {}\n", program.error().line, ops::describe(program.error().error), program.error().detail);
        return;
    }
    // Số bộ = id lớn nhất trong tệp (Python gán id liền từ 1).
    std::int32_t max_cond = 0;
    for (const auto& row : cond_table->rows) max_cond = std::max<std::int32_t>(max_cond, std::stoi(row[0]));
    std::int32_t max_effect = 0;
    for (const auto& row : effect_table->rows) max_effect = std::max<std::int32_t>(max_effect, std::stoi(row[0]));
    context.expect(program->condition_count() == static_cast<std::size_t>(max_cond), "đủ bộ điều kiện");
    context.expect(program->effect_list_count() == static_cast<std::size_t>(max_effect), "đủ bộ hiệu ứng");
    // Mã tên do Python băm: mọi nhóm tên quái của bảng thật phải ra cùng mã khi băm bằng C++.
    const auto groups = table::parse_tsv(read_file(root + "/server/mission_name_groups.tsv"));
    context.expect(groups.has_value(), "bảng nhóm tên parse được");
    if (!groups) return;
    std::size_t mismatched = 0;
    for (const auto& row : groups->rows) {
        if (ops::name_id(row[2]) != static_cast<std::uint32_t>(std::stoul(row[0]))) ++mismatched;
    }
    context.expect(!groups->rows.empty() && mismatched == 0, "name_id C++ trùng Python trên mọi nhóm tên thật");
}
#else
void real_tables_load(Context&) {}
#endif

constexpr std::array kCases{
    Case{.name = "golden_ids", .body = golden_ids},
    Case{.name = "dnf_semantics", .body = dnf_semantics},
    Case{.name = "metrics_and_predicates", .body = metrics_and_predicates},
    Case{.name = "counter_versus_clock", .body = counter_versus_clock},
    Case{.name = "load_accepts_valid_tables", .body = load_accepts_valid_tables},
    Case{.name = "load_rejects_hostile_tables", .body = load_rejects_hostile_tables},
    Case{.name = "plan_uses_snapshot", .body = plan_uses_snapshot},
    Case{.name = "real_tables_load", .body = real_tables_load},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
