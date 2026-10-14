#include "ops/ops.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>
#include <vector>

namespace game::ops {
namespace {

constexpr std::array<std::size_t, kMetricCount> kArity = {
    0,  // kLevel
    1,  // kItemCount
    0,  // kBagSpace
    1,  // kMoney
    2,  // kObjective
    1,  // kCounter
    0,  // kSect
    0,  // kGender
    0,  // kTeamSize
    0,  // kQuestCount
    0,  // kHour
    0,  // kWeekday
    0,  // kMinute
    0,  // kRadio
    1,  // kAbility
    0,  // kGuild
    1,  // kClock
    0,  // kMonster
    0,  // kArea
    0,  // kEventItem
    0,  // kSlotsFree
};

[[nodiscard]] constexpr std::uint32_t unsigned_or_zero(std::int32_t value) noexcept {
    return value < 0 ? 0U : static_cast<std::uint32_t>(value);
}

[[nodiscard]] std::int64_t metric_value(Metric metric, const std::array<std::int32_t, 3>& arg,
    const Context& context) noexcept {
    const HeroView& hero = *context.hero;
    switch (metric) {
        case Metric::kLevel: return hero.level();
        case Metric::kItemCount: return arg[0] < 0 ? 0 : hero.item_count(unsigned_or_zero(arg[0]));
        case Metric::kBagSpace: return hero.bag_space();
        case Metric::kMoney: return hero.money(arg[0] != 0);
        case Metric::kObjective: return arg[0] < 0 ? 0 : hero.objective(unsigned_or_zero(arg[0]), arg[1]);
        case Metric::kCounter: return hero.counter(arg[0]);
        case Metric::kSect: return hero.sect();
        case Metric::kGender: return hero.gender();
        case Metric::kTeamSize: return hero.team_size();
        case Metric::kQuestCount: return hero.quest_count();
        case Metric::kHour: return context.calendar.hour;
        case Metric::kWeekday: return context.calendar.weekday;
        case Metric::kMinute: return context.calendar.minute;
        case Metric::kRadio: return context.radio;
        case Metric::kAbility: return hero.ability(arg[0]);
        case Metric::kGuild: return hero.guild();
        case Metric::kClock: return context.calendar.clock(arg[0]);
        case Metric::kMonster: return context.event.monster;
        case Metric::kArea: return context.event.area;
        case Metric::kEventItem: return context.event.item;
        case Metric::kSlotsFree: return hero.quest_slots_free();
    }
    return 0;
}

[[nodiscard]] constexpr int sign_of(std::int64_t value) noexcept {
    return value < 0 ? -1 : (value > 0 ? 1 : 0);
}

[[nodiscard]] bool raw_holds(const Atom& atom, const Context& context) noexcept {
    const HeroView& hero = *context.hero;
    switch (atom.op) {
        case Op::kNever: return false;
        case Op::kAtLeast:
            return metric_value(atom.metric, atom.arg, context) >= atom.arg.at(metric_arity(atom.metric));
        case Op::kIs:
            return metric_value(atom.metric, atom.arg, context) == atom.arg.at(metric_arity(atom.metric));
        case Op::kTeamLeader: return hero.team_leader();
        case Op::kSkillKnown: return hero.skill_known(atom.arg[0]);
        case Op::kQuestActive: return atom.arg[0] >= 0 && hero.quest_active(unsigned_or_zero(atom.arg[0]));
        case Op::kQuestDone: return atom.arg[0] >= 0 && hero.quest_done(unsigned_or_zero(atom.arg[0]));
        case Op::kFlagSet: return hero.flag(atom.arg[0]);
        case Op::kCounterVsClock:
            return sign_of(hero.counter(atom.arg[0]) - context.calendar.clock(atom.arg[1])) == atom.arg[2];
        case Op::kTargetName: return context.target_name == atom.name;
        case Op::kEventMonsterName: return context.event.monster_name == atom.name;
        case Op::kImpactActive: return hero.impact_active(atom.arg[0]);
        case Op::kQuestNamed: {
            if (atom.arg[0] < 0) return false;
            const std::uint32_t held = hero.quest_name(unsigned_or_zero(atom.arg[0]));
            return held != 0 && held == atom.name;
        }
    }
    return false;
}

// Mã Unicode của chuỗi UTF-8 bắt đầu ở `at`: số byte của ký tự trắng, 0 nếu không phải ký tự trắng.
// Danh sách trùng str.isspace của Python (nền của `\s` trong công cụ trích).
[[nodiscard]] std::size_t whitespace_bytes(std::string_view text, std::size_t at) noexcept {
    const auto byte = [&](std::size_t offset) -> unsigned {
        return at + offset < text.size() ? static_cast<std::uint8_t>(text[at + offset]) : 0U;
    };
    const unsigned first = byte(0);
    if ((first >= 0x09 && first <= 0x0D) || (first >= 0x1C && first <= 0x20)) return 1;
    if (first == 0xC2 && (byte(1) == 0x85 || byte(1) == 0xA0)) return 2;
    if (first == 0xE1 && byte(1) == 0x9A && byte(2) == 0x80) return 3;
    if (first == 0xE2 && byte(1) == 0x80 && ((byte(2) >= 0x80 && byte(2) <= 0x8A) || byte(2) == 0xA8 ||
                                                  byte(2) == 0xA9 || byte(2) == 0xAF)) {
        return 3;
    }
    if (first == 0xE2 && byte(1) == 0x81 && byte(2) == 0x9F) return 3;
    if (first == 0xE3 && byte(1) == 0x80 && byte(2) == 0x80) return 3;
    return 0;
}

[[nodiscard]] constexpr bool is_ascii_letter(char character) noexcept {
    return (character >= 'A' && character <= 'Z') || (character >= 'a' && character <= 'z');
}

}  // namespace

std::uint32_t name_id(std::string_view utf8) noexcept {
    std::uint32_t value = 0x811C9DC5U;
    std::size_t at = 0;
    while (at < utf8.size()) {
        if (utf8[at] == '#' && at + 1 < utf8.size() && is_ascii_letter(utf8[at + 1])) {
            at += 2;  // thẻ màu #R, #W...
            continue;
        }
        if (const std::size_t skip = whitespace_bytes(utf8, at); skip != 0) {
            at += skip;
            continue;
        }
        value ^= static_cast<std::uint8_t>(utf8[at]);
        value *= 0x01000193U;
        ++at;
    }
    return value & 0x7FFFFFFFU;
}

std::size_t metric_arity(Metric metric) noexcept {
    const auto index = static_cast<std::size_t>(metric);
    return index < kArity.size() ? kArity.at(index) : 0;
}

std::int64_t Calendar::clock(std::int32_t which) const noexcept {
    switch (which) {
        case 1: return day;
        case 2: return hour_time;
        case 3: return quarter_time;
        case 4: return week_time;
        case 5: return unix_seconds;
        default: return 0;
    }
}

bool holds(const Atom& atom, const Context& context) noexcept {
    core::check(context.hero != nullptr, "ops::holds cần HeroView");
    return raw_holds(atom, context) != atom.negated;
}

bool holds(const CondSet& set, const Context& context) noexcept {
    return std::ranges::any_of(set.clauses, [&](const std::vector<Atom>& clause) {
        return std::ranges::all_of(clause, [&](const Atom& atom) { return holds(atom, context); });
    });
}

std::int64_t param_value(const TextParam& param, const Context& context) noexcept {
    if (param.kind != TextParam::Kind::kMetric) return 0;
    core::check(context.hero != nullptr, "ops::param_value cần HeroView");
    const std::array<std::int32_t, 3> arg{param.arg[0], param.arg[1], 0};
    return metric_value(param.metric, arg, context);
}

std::string_view describe(LoadError error) noexcept {
    switch (error) {
        case LoadError::kNone: return "không lỗi";
        case LoadError::kMissingColumn: return "thiếu cột";
        case LoadError::kBadNumber: return "ô số không đọc được";
        case LoadError::kUnknownOp: return "op không thuộc tập đóng";
        case LoadError::kOutOfRange: return "giá trị ngoài miền";
        case LoadError::kSetIdGap: return "id bộ không liền hoặc không tăng";
        case LoadError::kTooLarge: return "bộ vượt trần kích thước";
        case LoadError::kBadReference: return "tham chiếu tới bộ điều kiện không có";
        case LoadError::kUnknownMetric: return "đại lượng không biết";
    }
    return "lỗi không rõ";
}

}  // namespace game::ops
