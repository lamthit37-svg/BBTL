#include "actor/body.hpp"

#include "actor/attr.hpp"
#include "actor/numeric.hpp"
#include "actor/rules.hpp"
#include "dice/dice.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <utility>
#include <vector>

namespace game::actor {
namespace {

constexpr std::int64_t kPercent = 100;
constexpr std::size_t kMaxInnerArts = 64;
// Mili giây trôi qua tối đa mỗi lần gọi advance: 1 giờ. Chặn đầu vào thù địch làm tràn bộ cộng dồn.
constexpr std::int64_t kMaxAdvanceMs = 3'600'000;

std::int32_t add32(std::int32_t left, std::int64_t right) noexcept {
    return saturate32(static_cast<std::int64_t>(left) + right);
}

// current + delta kẹp vào [0, high] mà không tràn int64 (delta đến từ dữ liệu ngoài, có thể là cực trị).
std::int64_t clamp_sum(std::int64_t current, std::int64_t delta, std::int64_t high) noexcept {
    if (delta >= 0) return delta > high - current ? high : current + delta;
    return delta < -current ? 0 : current + delta;
}

// Phần của Amount trên một mức tối đa: phần trăm thì cắt xuống, điểm tuyệt đối thì giữ nguyên.
std::int64_t resolve(Amount amount, std::int64_t whole) noexcept {
    if (amount.percent) return (whole * std::clamp<std::int64_t>(amount.value, 0, 100)) / kPercent;
    return std::max<std::int64_t>(amount.value, 0);
}

// Giá trị một khoảng rút ngẫu nhiên trong [min, max).
Amount pick(const AmountRange& range, dice::Dice& dice) noexcept {
    Amount result;
    result.percent = range.max.value != 0 ? range.max.percent : range.min.percent;
    if (range.max.value <= range.min.value) {
        result.value = range.min.value;
    } else {
        result.value = static_cast<std::int32_t>(dice.between(range.min.value, static_cast<std::int64_t>(range.max.value) - 1));
    }
    return result;
}

std::optional<Stat> inner_art_stat(std::int32_t logic) noexcept {
    switch (logic) {
    case 0: return Stat::kMaxHp;
    case 1: return Stat::kMaxMp;
    case 2: return Stat::kAttackPhy;
    case 3: return Stat::kAttackMagic;
    case 4: return Stat::kDefencePhy;
    case 5: return Stat::kDefenceMagic;
    case 6: return Stat::kHit;
    case 7: return Stat::kMiss;
    case 8: return Stat::kCritical;
    default: return std::nullopt;
    }
}

// base + cộng thẳng + % của base.
std::int32_t finish_plain(std::int32_t base, const Modifiers& mods, Stat which) noexcept {
    const std::int64_t part = round_ratio(static_cast<std::int64_t>(base) * mods.rate[which], kPercent);
    return saturate32(static_cast<std::int64_t>(base) + mods.point[which] + part);
}

// Như trên, thêm điểm gốc của trang bị và % của điểm gốc ấy (ngoại/nội công, phòng thủ, né).
std::int32_t finish_equipped(std::int32_t base, const Modifiers& mods, Stat which) noexcept {
    const std::int64_t equip_part = round_ratio(static_cast<std::int64_t>(mods.equip_base[which]) * mods.equip_rate[which], kPercent);
    return saturate32(static_cast<std::int64_t>(finish_plain(base, mods, which)) + mods.equip_base[which] + equip_part);
}

} // namespace

bool Modifiers::add_item(const AttrEntry& entry) noexcept {
    const std::optional<AttrId> id = attr_id_of(entry.attr_id);
    if (!id) return false;
    raw[*id] = add32(raw[*id], entry.value);
    if (*id == AttrId::kAllBase) {
        for (const Stat stat : kPrimaryStats) add_point(stat, entry.value);
        return true;
    }
    if (*id == AttrId::kResistAll) {
        for (const Stat stat : {Stat::kResistCold, Stat::kResistFire, Stat::kResistLight, Stat::kResistPoison}) {
            add_point(stat, entry.value);
        }
        return true;
    }
    const AttrInfo info = info_of(*id);
    switch (info.kind) {
    case AttrKind::kNone: break;
    case AttrKind::kPoint: point[info.stat] = add32(point[info.stat], entry.value); break;
    case AttrKind::kRateOfBase: rate[info.stat] = add32(rate[info.stat], entry.value); break;
    case AttrKind::kRateOfEquip: equip_rate[info.stat] = add32(equip_rate[info.stat], entry.value); break;
    case AttrKind::kEquipBase: equip_base[info.stat] = add32(equip_base[info.stat], entry.value); break;
    }
    return true;
}

void Modifiers::add_point(Stat stat, std::int32_t value) noexcept { point[stat] = add32(point[stat], value); }

void Modifiers::add_rate(Stat stat, std::int32_t value) noexcept { rate[stat] = add32(rate[stat], value); }

void Modifiers::merge(const Modifiers& other) noexcept {
    for (std::size_t i = 0; i < kStatCount; ++i) {
        const auto stat = static_cast<Stat>(i);
        point[stat] = add32(point[stat], other.point[stat]);
        rate[stat] = add32(rate[stat], other.rate[stat]);
        equip_base[stat] = add32(equip_base[stat], other.equip_base[stat]);
        equip_rate[stat] = add32(equip_rate[stat], other.equip_rate[stat]);
    }
    for (std::size_t i = 0; i < kAttrIdCount; ++i) {
        const auto id = static_cast<AttrId>(i);
        raw[id] = add32(raw[id], other.raw[id]);
    }
    rage_gain_percent = add32(rage_gain_percent, other.rage_gain_percent);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): cảnh, cấp, sát khí khác vai, nơi gọi nêu tên (HP-07)
std::uint32_t penalty_id(std::uint32_t scene_type, std::uint16_t level, std::int32_t pk_value, DieType die_type) noexcept {
    std::uint32_t pk_index = 0;
    if (level >= 10) {
        if (pk_value < 1) pk_index = 1;
        else if (pk_value < 20) pk_index = 2;
        else if (pk_value < 40) pk_index = 3;
        else if (pk_value < 60) pk_index = 4;
        else if (pk_value < 80) pk_index = 5;
        else pk_index = 6;
    }
    return (scene_type * 100U) + (pk_index * 10U) + static_cast<std::uint32_t>(die_type);
}

std::optional<PenaltyOutcome> roll_penalty(const Rules& rules, std::uint32_t id, dice::Dice& dice) {
    const PenaltyRow* row = rules.penalty(id);
    if (row == nullptr) return std::nullopt;
    PenaltyOutcome outcome;
    outcome.money = pick(row->money, dice);
    outcome.exp = pick(row->exp, dice);
    outcome.equip_durability = pick(row->equip_durability, dice);
    outcome.item_drop = pick(row->item_drop, dice);
    outcome.equip_drop = pick(row->equip_drop, dice);
    return outcome;
}

std::uint64_t monster_exp(const Rules& rules, const BodyLimits& limits, std::uint16_t killer_level,
    const MonsterRow& monster, std::int32_t exp_refix) noexcept {
    if (monster.base_exp <= 0) return 0;
    const std::int32_t gap = monster.level - static_cast<std::int32_t>(killer_level);
    std::uint64_t exp = static_cast<std::uint64_t>(monster.base_exp) * rules.exp_gap_ppm(gap) / 1'000'000U;
    exp = exp * static_cast<std::uint64_t>(std::max(limits.exp_factor_permille, 0)) / 1000U;
    const auto percent = static_cast<std::uint64_t>(std::clamp<std::int32_t>(exp_refix, -100, 10'000) + 100);
    return exp * percent / 100U;
}

// Float2Int((gốc + thuộc tính * hệ số + cấp * hệ số cấp) / 100), tối thiểu 0. Ba cột liền nhau của bảng.
std::int32_t Body::derived(BaseInfo first, std::int32_t attribute) const noexcept {
    const BaseRow& table = rules_->base(record_.sect);
    const auto at = static_cast<std::size_t>(first);
    const std::int64_t sum = static_cast<std::int64_t>(table[first]) +
        (static_cast<std::int64_t>(attribute) * table[static_cast<BaseInfo>(at + 1)]) +
        (static_cast<std::int64_t>(record_.level) * table[static_cast<BaseInfo>(at + 2)]);
    return std::max(0, round_ratio32(sum, kPercent));
}

Record Body::new_record(const Rules& rules, const BodyLimits& limits, std::uint8_t sect) {
    Record record;
    record.sect = sect < kSectSlots ? sect : static_cast<std::uint8_t>(9);
    record.level = 1;
    for (std::size_t k = 0; k < kPrimaryCount; ++k) {
        slot(record.points, k) = add32(rules.growth(record.sect, 0, k), rules.growth(record.sect, 1, k));
    }
    const Body body = human(rules, limits, record);
    record.hp = body.stat(Stat::kMaxHp);
    record.mp = body.stat(Stat::kMaxMp);
    return record;
}

Body Body::human(const Rules& rules, const BodyLimits& limits, Record record) {
    Body body;
    body.rules_ = &rules;
    body.limits_ = limits;
    body.human_ = true;
    body.record_ = std::move(record);
    if (body.record_.sect >= kSectSlots) body.record_.sect = 9;
    body.base_camp_ = rules.base(body.record_.sect)[BaseInfo::kCamp];
    body.rebuild_inner();
    body.recalc();
    return body;
}

Body Body::monster(const Rules& rules, const BodyLimits& limits, const MonsterRow& row) {
    Body body;
    body.rules_ = &rules;
    body.limits_ = limits;
    body.human_ = false;
    body.monster_ = row;
    body.record_.sect = 9;
    body.record_.level = static_cast<std::uint16_t>(std::clamp(row.level, 1, 65535));
    body.base_camp_ = row.camp;
    body.record_.hp = std::numeric_limits<std::int32_t>::max();
    body.record_.mp = std::numeric_limits<std::int32_t>::max();
    body.recalc();
    return body;
}

void Body::set_base_camp(std::int32_t camp) noexcept {
    base_camp_ = camp;
    recalc();
}

void Body::set_equipment(const Modifiers& modifiers) noexcept {
    equip_ = modifiers;
    recalc();
}

void Body::set_buffs(const Modifiers& modifiers) noexcept {
    buff_ = modifiers;
    recalc();
}

void Body::rebuild_inner() noexcept {
    inner_ = Modifiers{};
    for (const auto& [id, level] : record_.inner_arts) {
        const InnerArtRow* art = rules_->inner_art(id);
        if (art == nullptr) continue;
        const std::optional<Stat> stat = inner_art_stat(art->logic);
        if (!stat) continue;
        // Mốc cao nhất có ngưỡng không vượt cấp tâm pháp (suy luận: bảng chỉ có cặp ngưỡng/giá trị).
        std::int64_t milli = 0;
        for (const auto& [threshold, value] : art->steps) {
            if (std::cmp_less_equal(threshold, level)) milli = value;
        }
        inner_.add_point(*stat, saturate32(round_ratio(milli, 1000)));
    }
}

// Chỉ số cơ sở trước khi cộng nguồn ngoài: người tính từ bảng phái, quái đọc thẳng từ dòng bảng.
struct Body::Base {
    std::int32_t hp = 0;
    std::int32_t hp_regen = 0;
    std::int32_t mp = 0;
    std::int32_t mp_regen = 0;
    std::int32_t attack_p = 0;
    std::int32_t attack_m = 0;
    std::int32_t defence_p = 0;
    std::int32_t defence_m = 0;
    std::int32_t hit = 0;
    std::int32_t miss = 0;
    std::int32_t crit = 0;
    std::int32_t crit_defence = 0;
    std::int32_t move = 0;
};

Body::Base Body::human_base(const std::array<std::int32_t, kPrimaryCount>& primary) const noexcept {
    const std::int32_t str = primary.at(0);
    const std::int32_t spr = primary.at(1);
    const std::int32_t con = primary.at(2);
    const std::int32_t intel = primary.at(3);
    const std::int32_t dex = primary.at(4);
    Base base;
    base.hp = derived(BaseInfo::kBaseHp, con);
    base.hp_regen = derived(BaseInfo::kBaseHpRestore, con);
    base.mp = derived(BaseInfo::kBaseMp, intel);
    base.mp_regen = derived(BaseInfo::kBaseMpRestore, intel);
    base.attack_p = derived(BaseInfo::kBaseAttackP, str);
    base.attack_m = derived(BaseInfo::kBaseAttackM, spr);
    base.defence_p = derived(BaseInfo::kBaseDefenceP, con);
    base.defence_m = derived(BaseInfo::kBaseDefenceM, intel);
    base.hit = derived(BaseInfo::kBaseHit, dex);
    base.miss = derived(BaseInfo::kBaseMiss, dex);
    base.crit = derived(BaseInfo::kBaseCrit, dex);
    base.crit_defence = derived(BaseInfo::kBaseCritDefence, dex);
    base.move = limits_.move_speed;
    return base;
}

Body::Base Body::monster_base(const MonsterRow& row) const noexcept {
    Base base;
    base.hp = row.max_hp;
    base.hp_regen = row.hp_restore;
    base.mp = row.max_mp;
    base.mp_regen = row.mp_restore;
    base.attack_p = row.attack_phy;
    base.attack_m = row.attack_magic;
    base.defence_p = row.defence_phy;
    base.defence_m = row.defence_magic;
    base.hit = row.hit;
    base.miss = row.miss;
    base.crit = row.critical;
    base.crit_defence = row.critical_defence;
    base.move = row.move_speed > 0 ? row.move_speed : limits_.move_speed;
    return base;
}

void Body::recalc() noexcept {
    total_ = Modifiers{};
    total_.merge(equip_);
    total_.merge(buff_);
    total_.merge(inner_);
    const Modifiers& mods = total_;

    EnumArray<Stat, std::int32_t, kStatCount> out;
    std::array<std::int32_t, kPrimaryCount> primary{};
    if (human_) {
        for (std::size_t k = 0; k < kPrimaryCount; ++k) {
            const Stat stat = slot(kPrimaryStats, k);
            slot(primary, k) = std::max(0, add32(slot(record_.points, k), mods.point[stat]));
            out[stat] = slot(primary, k);
        }
    }

    Base base;
    if (human_) {
        base = human_base(primary);
        fluctuation_ = rules_->base(record_.sect)[BaseInfo::kAttackFluctuation];
    } else if (monster_) {
        base = monster_base(*monster_);
        fluctuation_ = limits_.default_fluctuation;
        constexpr std::array<std::pair<Stat, Stat>, 4> kElements{{{Stat::kAttackCold, Stat::kResistCold},
            {Stat::kAttackFire, Stat::kResistFire}, {Stat::kAttackLight, Stat::kResistLight},
            {Stat::kAttackPoison, Stat::kResistPoison}}};
        for (std::size_t e = 0; e < kElements.size(); ++e) {
            out[slot(kElements, e).first] = slot(monster_->attack_element, e);
            out[slot(kElements, e).second] = slot(monster_->resist_element, e);
        }
    }

    out[Stat::kMaxHp] = std::max(1, finish_plain(base.hp, mods, Stat::kMaxHp));
    out[Stat::kHpRegen] = std::max(0, finish_plain(base.hp_regen, mods, Stat::kHpRegen));
    out[Stat::kMaxMp] = std::max(0, finish_plain(base.mp, mods, Stat::kMaxMp));
    out[Stat::kMpRegen] = std::max(0, finish_plain(base.mp_regen, mods, Stat::kMpRegen));
    out[Stat::kAttackPhy] = std::max(0, finish_equipped(base.attack_p, mods, Stat::kAttackPhy));
    out[Stat::kAttackMagic] = std::max(0, finish_equipped(base.attack_m, mods, Stat::kAttackMagic));
    out[Stat::kDefencePhy] = std::max(0, finish_equipped(base.defence_p, mods, Stat::kDefencePhy));
    out[Stat::kDefenceMagic] = std::max(0, finish_equipped(base.defence_m, mods, Stat::kDefenceMagic));
    out[Stat::kMiss] = std::max(0, finish_equipped(base.miss, mods, Stat::kMiss));
    out[Stat::kHit] = std::max(0, finish_plain(base.hit, mods, Stat::kHit));
    out[Stat::kCritical] = std::max(0, finish_plain(base.crit, mods, Stat::kCritical));
    out[Stat::kCriticalDefence] = std::max(0, finish_plain(base.crit_defence, mods, Stat::kCriticalDefence));
    out[Stat::kMoveSpeed] = std::max(0, finish_plain(base.move, mods, Stat::kMoveSpeed));

    // Hệ nguyên tố: quái có điểm gốc từ bảng, người chỉ có điểm cộng.
    for (const Stat stat : {Stat::kAttackCold, Stat::kResistCold, Stat::kAttackFire, Stat::kResistFire,
             Stat::kAttackLight, Stat::kResistLight, Stat::kAttackPoison, Stat::kResistPoison}) {
        out[stat] = finish_plain(out[stat], mods, stat);
    }

    // Tốc độ đánh: 100 trừ phần giảm, kẹp [25, 400] (bản gốc: <= 25 thành 25, > 400 thành 400).
    out[Stat::kAttackSpeed] = clamp32(static_cast<std::int64_t>(100) - mods.point[Stat::kAttackSpeed],
        limits_.attack_speed_min, limits_.attack_speed_max);
    // Nộ khí và điểm liên kích chỉ người mới có.
    if (human_) {
        out[Stat::kMaxRage] = clamp32(static_cast<std::int64_t>(limits_.base_max_rage) + mods.point[Stat::kMaxRage], 0,
            limits_.max_rage_cap);
        out[Stat::kMaxStrikePoint] = clamp32(static_cast<std::int64_t>(limits_.base_max_strike) +
                mods.point[Stat::kMaxStrikePoint], 0, limits_.max_strike_cap);
    }
    out[Stat::kVisionRange] = add32(limits_.vision_range, mods.point[Stat::kVisionRange]);
    out[Stat::kCamp] = add32(base_camp_, mods.point[Stat::kCamp]);
    for (const Stat stat : {Stat::kModelId, Stat::kMountId, Stat::kExpRefix, Stat::kStealthLevel, Stat::kDetectLevel}) {
        out[stat] = mods.point[stat];
    }
    for (const Stat stat : {Stat::kReduceSlowerDuration, Stat::kReduceWeakenDuration, Stat::kReduceFaintDuration,
             Stat::kReducePoisonedDuration}) {
        out[stat] = clamp32(mods.point[stat], 0, 100);
    }
    stats_ = out;
    clamp_resources();
}

void Body::clamp_resources() noexcept {
    if (record_.alive && record_.hp <= 0) {
        record_.alive = false;
    }
    if (!record_.alive) {
        record_.hp = 0;
        record_.rage = 0;
        record_.strike_points = 0;
    } else {
        record_.hp = std::min(record_.hp, stat(Stat::kMaxHp));
    }
    record_.mp = clamp32(record_.mp, 0, stat(Stat::kMaxMp));
    record_.rage = clamp32(record_.rage, 0, stat(Stat::kMaxRage));
    record_.strike_points = clamp32(record_.strike_points, 0, stat(Stat::kMaxStrikePoint));
}

HpChange Body::change_hp(std::int64_t delta) noexcept {
    if (!record_.alive) return {};
    const std::int64_t target = clamp_sum(record_.hp, delta, stat(Stat::kMaxHp));
    HpChange change;
    change.applied = saturate32(target - record_.hp);
    record_.hp = static_cast<std::int32_t>(target);
    if (record_.hp == 0) change.died = kill();
    return change;
}

std::int32_t Body::change_mp(std::int64_t delta) noexcept {
    if (!record_.alive) return 0;
    const std::int64_t target = clamp_sum(record_.mp, delta, stat(Stat::kMaxMp));
    const std::int32_t applied = saturate32(target - record_.mp);
    record_.mp = static_cast<std::int32_t>(target);
    return applied;
}

std::int32_t Body::change_rage(std::int64_t delta) noexcept {
    if (!record_.alive) return 0;
    const std::int64_t target = clamp_sum(record_.rage, delta, stat(Stat::kMaxRage));
    const std::int32_t applied = saturate32(target - record_.rage);
    record_.rage = static_cast<std::int32_t>(target);
    return applied;
}

std::int32_t Body::gain_rage(RageTrigger trigger, std::int64_t value) noexcept {
    if (!record_.alive || !human_ || value <= 0) return 0;
    const BaseRow& base = rules_->base(record_.sect);
    const std::int64_t capped = std::min<std::int64_t>(value, std::numeric_limits<std::int32_t>::max());
    std::int64_t amount = 0;
    // Sát thương nhận/gây ra: tỉ lệ nằm ở cột hệ số gốc (nộ khí mỗi 1000 điểm sát thương). Các sự kiện còn lại
    // theo bảng luật của phái.
    if (trigger == RageTrigger::kDamaged) {
        amount = (capped * base[BaseInfo::kRageWhenDamaged]) / 1000;
    } else if (trigger == RageTrigger::kDealDamage) {
        amount = (capped * base[BaseInfo::kRageWhenDealing]) / 1000;
    } else {
        const RageRule rule = rules_->rage(record_.sect, trigger);
        if (rule.multiplier <= 0 || rule.divisor <= 0) return 0;
        amount = (capped * rule.multiplier) / rule.divisor;
    }
    if (amount <= 0) return 0;
    const std::int64_t refix = std::clamp<std::int64_t>(total_.rage_gain_percent, -100, 1000);
    amount = (amount * (kPercent + refix)) / kPercent;
    return change_rage(amount);
}

bool Body::spend_strike(std::int32_t points) noexcept {
    if (!record_.alive || points <= 0 || record_.strike_points < points) return false;
    record_.strike_points -= points;
    static_cast<void>(gain_rage(RageTrigger::kStrikeSpent, points));
    return true;
}

void Body::gain_strike(std::int32_t points) noexcept {
    if (!record_.alive || points <= 0) return;
    record_.strike_points = clamp32(static_cast<std::int64_t>(record_.strike_points) + points, 0, stat(Stat::kMaxStrikePoint));
}

std::int32_t Body::change_strike(std::int64_t delta) noexcept {
    if (!record_.alive) return 0;
    const std::int64_t target = clamp_sum(record_.strike_points, delta, stat(Stat::kMaxStrikePoint));
    const std::int32_t applied = saturate32(target - record_.strike_points);
    record_.strike_points = static_cast<std::int32_t>(target);
    return applied;
}

std::int32_t Body::advance(std::int64_t elapsed_ms) noexcept {
    if (!record_.alive || elapsed_ms <= 0 || limits_.recover_interval_ms <= 0) return 0;
    regen_elapsed_ms_ += std::min(elapsed_ms, kMaxAdvanceMs);
    const std::int64_t beats = regen_elapsed_ms_ / limits_.recover_interval_ms;
    regen_elapsed_ms_ %= limits_.recover_interval_ms;
    if (beats == 0) return 0;
    static_cast<void>(change_hp(beats * stat(Stat::kHpRegen)));
    static_cast<void>(change_mp(beats * stat(Stat::kMpRegen)));
    if (human_) static_cast<void>(change_rage(beats * rules_->base(record_.sect)[BaseInfo::kRageRegen]));
    return saturate32(beats);
}

bool Body::kill() noexcept {
    if (!record_.alive) return false;
    record_.alive = false;
    record_.hp = 0;
    record_.rage = 0;
    record_.strike_points = 0;
    regen_elapsed_ms_ = 0;
    return true;
}

bool Body::revive(const Revival& revival) noexcept {
    if (record_.alive) return false;
    record_.alive = true;
    record_.hp = clamp32(resolve(revival.hp, stat(Stat::kMaxHp)), 1, stat(Stat::kMaxHp));
    record_.mp = clamp32(resolve(revival.mp, stat(Stat::kMaxMp)), 0, stat(Stat::kMaxMp));
    record_.rage = clamp32(resolve(revival.rage, stat(Stat::kMaxRage)), 0, stat(Stat::kMaxRage));
    record_.strike_points = 0;
    regen_elapsed_ms_ = 0;
    return true;
}

std::uint64_t Body::lose_exp(Amount amount) noexcept {
    if (!human_) return 0;
    std::uint64_t lost = 0;
    if (amount.percent) {
        lost = record_.exp / 100U * static_cast<std::uint64_t>(std::clamp(amount.value, 0, 100)) +
            (record_.exp % 100U) * static_cast<std::uint64_t>(std::clamp(amount.value, 0, 100)) / 100U;
    } else {
        lost = static_cast<std::uint64_t>(std::max(amount.value, 0));
    }
    lost = std::min(lost, record_.exp);
    record_.exp -= lost;
    return lost;
}

void Body::apply_growth(std::uint16_t level) noexcept {
    for (std::size_t k = 0; k < kPrimaryCount; ++k) {
        const std::int32_t gain = rules_->growth(record_.sect, level, k);
        if (level < kWashPointLevel) {
            slot(record_.points, k) = add32(slot(record_.points, k), gain);
        } else {
            record_.remain_points = add32(record_.remain_points, gain);
        }
    }
}

LevelUp Body::add_exp(std::uint64_t amount) noexcept {
    LevelUp result;
    if (!human_) return result;
    constexpr std::uint64_t kMax = std::numeric_limits<std::uint64_t>::max();
    record_.exp = amount > kMax - record_.exp ? kMax : record_.exp + amount;
    while (record_.level < rules_->max_level()) {
        const std::uint64_t need = rules_->exp_need(record_.level);
        if (need == 0 || record_.exp < need) break;
        record_.exp -= need;
        ++record_.level;
        ++result.levels_gained;
        apply_growth(record_.level);
    }
    const std::uint64_t need = rules_->exp_need(record_.level);
    const auto multiple = static_cast<std::uint64_t>(std::max(limits_.exp_cap_multiple, 1));
    if (need != 0) record_.exp = std::min(record_.exp, need > kMax / multiple ? kMax : need * multiple);
    if (result.levels_gained > 0) {
        recalc();
        if (record_.alive) {
            record_.hp = stat(Stat::kMaxHp);
            record_.mp = stat(Stat::kMaxMp);
        }
    }
    result.exp_after = record_.exp;
    return result;
}

bool Body::spend_point(std::size_t primary, std::int32_t amount) noexcept {
    if (!human_ || primary >= kPrimaryCount || amount <= 0 || amount > record_.remain_points) return false;
    slot(record_.points, primary) = add32(slot(record_.points, primary), amount);
    record_.remain_points -= amount;
    recalc();
    return true;
}

void Body::rebuild_points(std::uint8_t sect) noexcept {
    record_.sect = sect;
    record_.points = {};
    record_.remain_points = 0;
    for (std::uint16_t level = 0; level <= record_.level; ++level) apply_growth(level);
}

bool Body::change_sect(std::uint8_t sect) noexcept {
    if (!human_ || sect >= kSectSlots) return false;
    rebuild_points(sect);
    recalc();
    return true;
}

bool Body::wash_points() noexcept {
    if (!human_) return false;
    rebuild_points(record_.sect);
    recalc();
    return true;
}

bool Body::set_inner_art(std::uint32_t id, std::uint16_t level) {
    if (!human_ || rules_->inner_art(id) == nullptr) return false;
    auto& arts = record_.inner_arts;
    const auto found = std::ranges::lower_bound(arts, id, {}, &std::pair<std::uint32_t, std::uint16_t>::first);
    const bool present = found != arts.end() && found->first == id;
    if (level == 0) {
        if (present) arts.erase(found);
    } else if (present) {
        found->second = level;
    } else {
        if (arts.size() >= kMaxInnerArts) return false;
        arts.insert(found, {id, level});
    }
    rebuild_inner();
    recalc();
    return true;
}

} // namespace game::actor
