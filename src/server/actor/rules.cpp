// Nạp các bảng luật của thân thể (xem rules.hpp).
#include "actor/rules.hpp"

#include "actor/attr.hpp"
#include "actor/numeric.hpp"
#include "actor/sheet.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <optional>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::actor {
namespace {

constexpr std::int32_t kScaleMilli = 1000;
constexpr std::int32_t kScalePpm = 1'000'000;
constexpr std::int32_t kBig = 100'000'000;
constexpr std::int32_t kLow = std::numeric_limits<std::int32_t>::min();
constexpr std::int32_t kHigh = std::numeric_limits<std::int32_t>::max();

Failure load_base(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "sect_base_values";
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t id_column = sheet.column("sect_id");
    std::array<std::size_t, kBaseInfoCount> columns{};
    for (std::size_t i = 0; i < kBaseInfoCount; ++i) slot(columns, i) = sheet.column(std::format("ainfotype{}", i));
    if (sheet.error()) return sheet.error();
    std::array<bool, kBaseTableSects> seen{};
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const std::int32_t sect = sheet.integer(row, id_column, 0, static_cast<std::int32_t>(kBaseTableSects) - 1);
        if (sheet.error()) return sheet.error();
        bool& present = slot(seen, static_cast<std::size_t>(sect));
        if (present) {
            sheet.raise(row, "sect_id", "phái lặp");
            return sheet.error();
        }
        present = true;
        BaseRow& target = slot(out.base, static_cast<std::size_t>(sect));
        for (std::size_t i = 0; i < kBaseInfoCount; ++i) {
            target[static_cast<BaseInfo>(i)] = sheet.integer(row, slot(columns, i), -kBig, kBig);
        }
    }
    if (sheet.error()) return sheet.error();
    if (!std::ranges::all_of(seen, [](bool one) { return one; })) {
        return fail(kName, std::format("thiếu phái trong 0..{}", kBaseTableSects - 1));
    }
    return std::nullopt;
}

Failure load_growth(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "sect_attribute_growth";
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t rank = sheet.column("rank");
    if (sheet.error()) return sheet.error();
    constexpr std::size_t kValues = kBaseTableSects * kPrimaryCount;
    if (parsed->header.size() != kValues + 1) {
        return fail(kName, std::format("cần {} cột, bảng có {}", kValues + 1, parsed->header.size()));
    }
    if (sheet.rows() == 0 || sheet.rows() > kMaxLevelRows) return fail(kName, "số hàng ngoài 1..trần");
    out.growth.assign(sheet.rows() * kValues, 0);
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const std::int32_t level = sheet.integer(row, rank, 0, std::numeric_limits<std::int16_t>::max());
        if (!sheet.error() && !std::cmp_equal(level, row)) sheet.raise(row, "rank", "cấp phải liền từ 0");
        for (std::size_t i = 0; i < kValues; ++i) {
            out.growth[(row * kValues) + i] = static_cast<std::int16_t>(sheet.integer(row, i + 1, -30000, 30000));
        }
        if (sheet.error()) return sheet.error();
    }
    out.growth_levels = static_cast<std::uint16_t>(sheet.rows());
    return std::nullopt;
}

Failure load_templates(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "sect_templates";
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t sect_column = sheet.column("sect_id");
    const std::size_t template_column = sheet.column("template_sect");
    if (sheet.error()) return sheet.error();
    for (std::size_t sect = 0; sect < kSectSlots; ++sect) {
        slot(out.template_of, sect) = sect < kBaseTableSects ? static_cast<std::uint8_t>(sect) : std::uint8_t{9};
    }
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const std::int32_t sect = sheet.integer(row, sect_column, 0, static_cast<std::int32_t>(kSectSlots) - 1);
        const std::int32_t source = sheet.integer(row, template_column, 0, static_cast<std::int32_t>(kBaseTableSects) - 1);
        if (sheet.error()) return sheet.error();
        slot(out.template_of, static_cast<std::size_t>(sect)) = static_cast<std::uint8_t>(source);
    }
    return std::nullopt;
}

// Chỉ ba sự kiện lấy luật từ bảng; kDamaged và kDealDamage lấy từ cột hệ số gốc của phái.
std::optional<RageTrigger> trigger_of(std::string_view name) noexcept {
    if (name == "strike_spent") return RageTrigger::kStrikeSpent;
    if (name == "heal_done") return RageTrigger::kHealDone;
    if (name == "trap_triggered") return RageTrigger::kTrapTriggered;
    return std::nullopt;
}

Failure load_rage(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "sect_rage_rules";
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t sect_column = sheet.column("sect_id");
    const std::size_t trigger_column = sheet.column("trigger");
    const std::size_t multiplier_column = sheet.column("multiplier");
    const std::size_t divisor_column = sheet.column("divisor");
    if (sheet.error()) return sheet.error();
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const std::int32_t sect = sheet.integer(row, sect_column, 0, static_cast<std::int32_t>(kSectSlots) - 1);
        const std::optional<RageTrigger> trigger = trigger_of(sheet.text(row, trigger_column));
        if (!trigger) {
            sheet.raise(row, "trigger", "tên sự kiện lạ");
            return sheet.error();
        }
        const std::int32_t multiplier = sheet.integer(row, multiplier_column, 0, kBig);
        const std::int32_t divisor = sheet.integer(row, divisor_column, 1, kBig);
        if (sheet.error()) return sheet.error();
        slot(out.rage, static_cast<std::size_t>(sect))[*trigger] = RageRule{.multiplier = multiplier, .divisor = divisor};
    }
    return std::nullopt;
}

Failure load_exp(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "player_exp_levels";
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t level_column = sheet.column("level");
    const std::size_t exp_column = sheet.column("exp");
    if (sheet.error()) return sheet.error();
    if (sheet.rows() == 0 || sheet.rows() > kMaxLevelRows) return fail(kName, "số hàng ngoài 1..trần");
    out.exp_need.clear();
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const std::int32_t level = sheet.integer(row, level_column, 1, std::numeric_limits<std::int16_t>::max());
        if (!sheet.error() && !std::cmp_equal(level, row + 1)) sheet.raise(row, "level", "cấp phải liền từ 1");
        const std::int64_t need = sheet.scaled(row, exp_column, 1);
        if (!sheet.error() && need <= 0) sheet.raise(row, "exp", "kinh nghiệm phải dương");
        if (sheet.error()) return sheet.error();
        out.exp_need.push_back(static_cast<std::uint64_t>(need));
    }
    return std::nullopt;
}

Failure load_gap(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "exp_level_gap_factors";
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t delta_column = sheet.column("level_delta");
    const std::size_t rate_column = sheet.column("rate");
    if (sheet.error()) return sheet.error();
    if (sheet.rows() == 0 || sheet.rows() > kMaxLevelRows) return fail(kName, "số hàng ngoài 1..trần");
    out.gap_ppm.clear();
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const std::int32_t delta = sheet.integer(row, delta_column, -static_cast<std::int32_t>(kMaxLevelRows), static_cast<std::int32_t>(kMaxLevelRows));
        const std::int64_t rate = sheet.scaled(row, rate_column, kScalePpm);
        if (sheet.error()) return sheet.error();
        if (row == 0) out.gap_first = delta;
        if (delta != out.gap_first + static_cast<std::int32_t>(row)) {
            sheet.raise(row, "level_delta", "chênh cấp phải liền nhau");
            return sheet.error();
        }
        if (rate < 0 || rate > 100LL * kScalePpm) {
            sheet.raise(row, "rate", "hệ số ngoài 0..100");
            return sheet.error();
        }
        out.gap_ppm.push_back(static_cast<std::uint32_t>(rate));
    }
    return std::nullopt;
}

Failure load_penalties(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "death_penalties";
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t id_column = sheet.column("id");
    constexpr std::array<std::string_view, 10> kNames{"money_min", "money_max", "exp_min", "exp_max",
        "equip_dur_min", "equip_dur_max", "item_min", "item_max", "equip_min", "equip_max"};
    std::array<std::size_t, 10> columns{};
    for (std::size_t i = 0; i < kNames.size(); ++i) slot(columns, i) = sheet.column(slot(kNames, i));
    if (sheet.error()) return sheet.error();
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const std::int32_t id = sheet.integer(row, id_column, 0, 1'000'000);
        std::array<Amount, 10> amounts{};
        for (std::size_t i = 0; i < kNames.size(); ++i) {
            const std::optional<Amount> amount = parse_amount(sheet.text(row, slot(columns, i)));
            if (!amount) {
                sheet.raise(row, slot(kNames, i), "không phải số hay phần trăm");
                return sheet.error();
            }
            slot(amounts, i) = *amount;
        }
        PenaltyRow penalty;
        penalty.money = {.min = amounts.at(0), .max = amounts.at(1)};
        penalty.exp = {.min = amounts.at(2), .max = amounts.at(3)};
        penalty.equip_durability = {.min = amounts.at(4), .max = amounts.at(5)};
        penalty.item_drop = {.min = amounts.at(6), .max = amounts.at(7)};
        penalty.equip_drop = {.min = amounts.at(8), .max = amounts.at(9)};
        if (!out.penalties.emplace(static_cast<std::uint32_t>(id), penalty).second) {
            sheet.raise(row, "id", "id lặp");
            return sheet.error();
        }
    }
    return std::nullopt;
}

Failure load_monsters(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "monsters";
    if (text.empty()) return std::nullopt;
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    if (sheet.rows() > kMaxMonsterRows) return fail(kName, "quá nhiều hàng");
    const std::size_t c_id = sheet.column("monster_id");
    const std::size_t c_gender = sheet.column("gender");
    const std::size_t c_level = sheet.column("level");
    const std::size_t c_min_damage = sheet.column("min_damage_percent");
    const std::size_t c_interact = sheet.column("can_interact");
    const std::size_t c_boss = sheet.column("is_boss");
    const std::size_t c_attack_phy = sheet.column("physical_attack");
    const std::size_t c_defence_phy = sheet.column("physical_defence");
    const std::size_t c_attack_magic = sheet.column("magic_attack");
    const std::size_t c_defence_magic = sheet.column("magic_defence");
    const std::size_t c_hp = sheet.column("max_hp_1");
    const std::size_t c_mp = sheet.column("max_mp");
    const std::size_t c_hp_restore = sheet.column("hp_restore");
    const std::size_t c_mp_restore = sheet.column("mp_restore");
    const std::size_t c_hit = sheet.column("accuracy");
    const std::size_t c_miss = sheet.column("miss");
    const std::size_t c_crit = sheet.column("critical_rate");
    const std::size_t c_crit_defence = sheet.column("critical_defence");
    const std::size_t c_move = sheet.column("move_speed");
    const std::size_t c_walk = sheet.column("walk_speed");
    const std::size_t c_attack_speed = sheet.column("attack_speed");
    constexpr std::array<std::string_view, 4> kAttack{"cold_attack", "fire_attack", "lightning_attack", "poison_attack"};
    constexpr std::array<std::string_view, 4> kDefence{"cold_defence", "fire_defence", "lightning_defence", "poison_defence"};
    constexpr std::array<std::string_view, 4> kReduce{"cold_resist_reduction", "fire_resist_reduction",
        "lightning_resist_reduction", "poison_resist_reduction"};
    std::array<std::size_t, 4> c_attack{};
    std::array<std::size_t, 4> c_defence{};
    std::array<std::size_t, 4> c_reduce{};
    for (std::size_t i = 0; i < 4; ++i) {
        slot(c_attack, i) = sheet.column(slot(kAttack, i));
        slot(c_defence, i) = sheet.column(slot(kDefence, i));
        slot(c_reduce, i) = sheet.column(slot(kReduce, i));
    }
    const std::size_t c_instant = sheet.column("instant_immunity_id");
    const std::size_t c_duration = sheet.column("duration_immunity_id");
    const std::size_t c_anim = sheet.column("attack_animation_time");
    const std::size_t c_cooldown = sheet.column("attack_cooldown_time");
    const std::size_t c_base_ai = sheet.column("base_ai");
    const std::size_t c_ext_ai = sheet.column("extended_ai");
    const std::size_t c_camp = sheet.column("camp");
    // Kinh nghiệm cơ bản nằm ở cột chưa đặt tên số 66 của bảng client (đối chiếu XJL7457: khớp 16063/19452
    // quái chung; bản client thắng khi lệch).
    const std::size_t c_exp = sheet.column("column_66");
    if (sheet.error()) return sheet.error();
    out.monsters.clear();
    out.monsters.reserve(sheet.rows());
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const auto num = [&](std::size_t column, std::int32_t low = kLow, std::int32_t high = kHigh) {
            return sheet.integer(row, column, low, high);
        };
        MonsterRow m;
        m.id = static_cast<std::uint32_t>(num(c_id, 0));
        m.gender = num(c_gender, 0, 10);
        m.level = num(c_level, 1, 100'000);
        m.min_damage_ppm = static_cast<std::int32_t>(sheet.scaled(row, c_min_damage, kScalePpm));
        m.can_interact = num(c_interact, -1, 10);
        m.boss = num(c_boss, 0, 1) != 0;
        m.attack_phy = num(c_attack_phy, 0);
        m.defence_phy = num(c_defence_phy, 0);
        m.attack_magic = num(c_attack_magic, 0);
        m.defence_magic = num(c_defence_magic, 0);
        m.max_hp = num(c_hp, 1);
        m.max_mp = num(c_mp, 0);
        m.hp_restore = num(c_hp_restore, 0);
        m.mp_restore = num(c_mp_restore, 0);
        m.hit = num(c_hit, 0);
        m.miss = num(c_miss, 0);
        m.critical = num(c_crit, 0);
        m.critical_defence = num(c_crit_defence, 0);
        m.move_speed = num(c_move, 0);
        m.walk_speed = num(c_walk, 0);
        m.attack_speed = num(c_attack_speed, 0);
        for (std::size_t i = 0; i < 4; ++i) {
            slot(m.attack_element, i) = num(slot(c_attack, i));
            slot(m.resist_element, i) = num(slot(c_defence, i));
            slot(m.resist_reduce, i) = num(slot(c_reduce, i));
        }
        m.instant_immunity_set = num(c_instant, -1);
        m.duration_immunity_set = num(c_duration, -1);
        m.attack_animation_ms = num(c_anim, 0);
        m.attack_cooldown_ms = num(c_cooldown, 0);
        m.base_ai = num(c_base_ai, 0);
        m.extended_ai = num(c_ext_ai, -1);
        m.camp = num(c_camp, -1);
        m.base_exp = num(c_exp, 0);
        if (sheet.error()) return sheet.error();
        out.monsters.push_back(m);
    }
    std::ranges::sort(out.monsters, {}, &MonsterRow::id);
    const auto dup = std::ranges::adjacent_find(out.monsters, {}, &MonsterRow::id);
    if (dup != out.monsters.end()) return fail(kName, std::format("id {} lặp", dup->id));
    return std::nullopt;
}

Failure load_inner_arts(std::string_view text, RulesData& out) {
    constexpr std::string_view kName = "inner_arts";
    if (text.empty()) return std::nullopt;
    Loaded<table::Tsv> parsed = parse_table(kName, text);
    if (!parsed) return parsed.error();
    Sheet sheet(kName, *parsed);
    const std::size_t c_id = sheet.column("inner_art_id");
    const std::size_t c_sect = sheet.column("sect_id");
    const std::size_t c_logic = sheet.column("attribute_logic");
    const std::size_t c_limit = sheet.column("upgrade_level_limit");
    if (sheet.error()) return sheet.error();
    constexpr std::size_t kFirstPair = 9; // cột chưa đặt tên số 9: cặp (cấp tâm pháp, giá trị) đầu tiên
    if (parsed->header.size() <= kFirstPair + 1) return fail(kName, "bảng quá ít cột");
    out.inner_arts.clear();
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        InnerArtRow art;
        art.id = static_cast<std::uint32_t>(sheet.integer(row, c_id, 0, kBig));
        art.sect = static_cast<std::uint8_t>(sheet.integer(row, c_sect, 0, static_cast<std::int32_t>(kSectSlots) - 1));
        art.logic = sheet.integer(row, c_logic, -1, 1000);
        art.learn_level = sheet.integer(row, c_limit, -1, 100'000);
        for (std::size_t col = kFirstPair; col + 1 < parsed->header.size(); col += 2) {
            const std::string_view level_cell = sheet.text(row, col);
            if (level_cell.empty()) break;
            const std::int32_t level = sheet.integer(row, col, 0, 100'000);
            const std::int64_t value = sheet.scaled(row, col + 1, kScaleMilli);
            if (sheet.error()) return sheet.error();
            art.steps.emplace_back(level, value);
        }
        if (sheet.error()) return sheet.error();
        out.inner_arts.push_back(std::move(art));
    }
    std::ranges::sort(out.inner_arts, {}, &InnerArtRow::id);
    const auto dup = std::ranges::adjacent_find(out.inner_arts, {}, &InnerArtRow::id);
    if (dup != out.inner_arts.end()) return fail(kName, std::format("id {} lặp", dup->id));
    return std::nullopt;
}

} // namespace

std::optional<Amount> parse_amount(std::string_view text) noexcept {
    if (text.empty()) return std::nullopt;
    Amount amount;
    if (text.back() == '%') {
        amount.percent = true;
        text.remove_suffix(1);
    }
    const std::optional<std::int32_t> value = int_cell(text, -kBig, kBig);
    if (!value) return std::nullopt;
    amount.value = *value;
    return amount;
}

const BaseRow& Rules::base(std::uint8_t sect) const noexcept { return slot(d_.base, template_of(sect)); }

std::uint8_t Rules::template_of(std::uint8_t sect) const noexcept {
    return slot(d_.template_of, sect < kSectSlots ? sect : std::size_t{9});
}

std::int32_t Rules::growth(std::uint8_t sect, std::uint16_t level, std::size_t primary) const noexcept {
    if (level >= d_.growth_levels || primary >= kPrimaryCount) return 0;
    const std::size_t index = (((static_cast<std::size_t>(level) * kBaseTableSects) + template_of(sect)) * kPrimaryCount) + primary;
    return index < d_.growth.size() ? d_.growth[index] : 0;
}

std::uint64_t Rules::exp_need(std::uint16_t level) const noexcept {
    if (level == 0 || level > d_.exp_need.size()) return 0;
    return d_.exp_need[level - 1U];
}

std::uint32_t Rules::exp_gap_ppm(std::int32_t level_delta) const noexcept {
    if (d_.gap_ppm.empty()) return static_cast<std::uint32_t>(kScalePpm);
    const std::int64_t index = static_cast<std::int64_t>(level_delta) - d_.gap_first;
    const std::int64_t last = static_cast<std::int64_t>(d_.gap_ppm.size()) - 1;
    return d_.gap_ppm[static_cast<std::size_t>(std::clamp<std::int64_t>(index, 0, last))];
}

RageRule Rules::rage(std::uint8_t sect, RageTrigger trigger) const noexcept {
    if (sect >= kSectSlots) return RageRule{};
    return slot(d_.rage, sect)[trigger];
}

const PenaltyRow* Rules::penalty(std::uint32_t id) const noexcept {
    const auto found = d_.penalties.find(id);
    return found == d_.penalties.end() ? nullptr : &found->second;
}

const MonsterRow* Rules::monster(std::uint32_t id) const noexcept {
    const auto found = std::ranges::lower_bound(d_.monsters, id, {}, &MonsterRow::id);
    return (found != d_.monsters.end() && found->id == id) ? &*found : nullptr;
}

const InnerArtRow* Rules::inner_art(std::uint32_t id) const noexcept {
    const auto found = std::ranges::lower_bound(d_.inner_arts, id, {}, &InnerArtRow::id);
    return (found != d_.inner_arts.end() && found->id == id) ? &*found : nullptr;
}

Loaded<Rules> load_rules(const RulesText& text) {
    RulesData data;
    const std::array<Failure, 9> results{
        load_base(text.sect_base_values, data),
        load_growth(text.sect_growth, data),
        load_templates(text.sect_templates, data),
        load_rage(text.sect_rage_rules, data),
        load_exp(text.player_exp_levels, data),
        load_gap(text.exp_level_gap, data),
        load_penalties(text.death_penalties, data),
        load_monsters(text.monsters, data),
        load_inner_arts(text.inner_arts, data),
    };
    for (const Failure& one : results) {
        if (one) return std::unexpected(*one);
    }
    return Rules(std::move(data));
}

} // namespace game::actor
