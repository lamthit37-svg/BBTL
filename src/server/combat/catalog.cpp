// Bộ nạp bảng luật chiến đấu (xem catalog.hpp).
#include "combat/catalog.hpp"

#include "actor/numeric.hpp"
#include "actor/sheet.hpp"
#include "combat/types.hpp"
#include "core/number.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::combat {
namespace {

using actor::Failure;
using actor::Sheet;
using actor::fail;
using actor::parse_table;
using actor::round_ratio32;

constexpr std::int32_t kIntLow = -2'000'000'000;
constexpr std::int32_t kIntHigh = 2'000'000'000;

// Chỉ số cột của skills.tsv (client 2026). Đã đối chiếu với bố cục SkillTemplateData_T::InitFromDB của
// GameServer 2008: cột 14..18 là hiệu ứng hình/âm (bỏ), 19 là cờ trạng thái mục tiêu, 33 logic nhắm, 35 tầm
// xa nhất (một số, bản 2008 có thêm tầm gần nhất), 36 đứng phe của kỹ năng, 37 đứng phe của mục tiêu.
namespace sk {
constexpr std::size_t kId = 0;
constexpr std::size_t kSect = 1;
constexpr std::size_t kMustUseWeapon = 6;
constexpr std::size_t kDisabled1 = 7;
constexpr std::size_t kDisabled2 = 8;
constexpr std::size_t kDisabledTransform = 9;
constexpr std::size_t kInnerArt = 10;
constexpr std::size_t kType = 12;
constexpr std::size_t kCooldownId = 13;
constexpr std::size_t kTargetState = 19;
constexpr std::size_t kUserClass = 20;
constexpr std::size_t kPassive = 21;
constexpr std::size_t kSelect = 22;
constexpr std::size_t kGroup = 27;
constexpr std::size_t kTargeting = 33;
constexpr std::size_t kActionTime = 34;
constexpr std::size_t kRange = 35;
constexpr std::size_t kStand = 36;
constexpr std::size_t kTargetByStand = 37;
constexpr std::size_t kTargetByKind = 38;
constexpr std::size_t kAutoShot = 41;
constexpr std::size_t kRadius = 43;
constexpr std::size_t kMaxTargets = 44;
constexpr std::size_t kInterruptAuto = 46;
constexpr std::size_t kDelay = 47;
constexpr std::size_t kFirstInstance = 48;
constexpr std::size_t kDisruptTime = 81;
constexpr std::size_t kCharges = 96;
constexpr std::size_t kAccuracy = 97;
constexpr std::size_t kDisruptChance = 99;
constexpr std::size_t kColumns = 102;
} // namespace sk

// Chỉ số cột của skill_levels.tsv (client 2026, 54 cột).
namespace lv {
constexpr std::size_t kId = 0;
constexpr std::size_t kLogic = 5;
constexpr std::size_t kCooldown = 6;
constexpr std::size_t kCharge = 7;
constexpr std::size_t kChannel = 8;
constexpr std::size_t kFirstTerm = 10;  // mỗi điều kiện: loại, tham số 0, tham số 1, rồi một cột mô tả
constexpr std::size_t kTermStride = 4;
constexpr std::size_t kTargetLevel = 21;
constexpr std::size_t kFirstParam = 25; // mỗi tham số: mô tả, giá trị
constexpr std::size_t kColumns = 54;
} // namespace lv

// Chỉ số cột của effects.tsv (StandardImpact 76 cột).
namespace ef {
constexpr std::size_t kId = 0;
constexpr std::size_t kLogic = 2;
constexpr std::size_t kOverTimed = 4;
constexpr std::size_t kImpactId = 5;
constexpr std::size_t kMutex = 7;
constexpr std::size_t kLevel = 8;
constexpr std::size_t kStand = 9;
constexpr std::size_t kKeepCorpse = 10;
constexpr std::size_t kDispellable = 11;
constexpr std::size_t kCancellable = 12;
constexpr std::size_t kNeedsChannel = 13;
constexpr std::size_t kIgnoreFilter = 14;
constexpr std::size_t kFadeDamage = 15;
constexpr std::size_t kFadeAction = 16;
constexpr std::size_t kFadeOffline = 17;
constexpr std::size_t kTimingOffline = 18;
constexpr std::size_t kContinuance = 20;
constexpr std::size_t kInterval = 21;
constexpr std::size_t kMutexByCaster = 22;
constexpr std::size_t kFirstParam = 28; // mỗi tham số: mô tả, giá trị, bước
constexpr std::size_t kParamStride = 3;
constexpr std::size_t kColumns = 76;
} // namespace ef

// Điều kiện đầu bảng: đủ số cột, cột đầu đúng tên, và (nếu có) một cột mốc thứ hai đúng tên.
struct HeaderSpec {
    std::string_view name;
    std::size_t columns = 0;
    std::size_t first_col = 0;
    std::string_view first_name;
    std::string_view marker_name;
    std::size_t marker_col = 0;
};

[[nodiscard]] Failure require_header(const Sheet& sheet, const HeaderSpec& spec, const table::Tsv& tsv) {
    if (sheet.columns() < spec.columns) {
        return fail(spec.name, std::format("cần ít nhất {} cột, có {}", spec.columns, sheet.columns()));
    }
    if (tsv.header.at(spec.first_col) != spec.first_name) {
        return fail(spec.name, std::format("cột {} phải tên {}, có {}", spec.first_col, spec.first_name, tsv.header.at(spec.first_col)));
    }
    if (!spec.marker_name.empty() && tsv.header.at(spec.marker_col) != spec.marker_name) {
        return fail(spec.name, std::format("cột {} phải tên {}, có {}", spec.marker_col, spec.marker_name, tsv.header.at(spec.marker_col)));
    }
    return std::nullopt;
}

[[nodiscard]] bool flag(Sheet& sheet, std::size_t row, std::size_t col) { return sheet.integer(row, col, kIntLow, kIntHigh) > 0; }

Failure load_skills(std::string_view text, std::vector<SkillTemplate>& out) {
    constexpr std::string_view kName = "skills.tsv";
    auto tsv = parse_table(kName, text);
    if (!tsv) return tsv.error();
    Sheet sheet(kName, *tsv);
    const HeaderSpec header{.name = kName, .columns = sk::kColumns, .first_col = sk::kId, .first_name = "skill_id",
        .marker_name = "column_96", .marker_col = sk::kCharges};
    if (Failure bad = require_header(sheet, header, *tsv)) return bad;
    if (sheet.rows() > kMaxSkillRows) return fail(kName, "quá nhiều dòng");
    out.reserve(sheet.rows());
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        SkillTemplate t;
        const std::int32_t id = sheet.integer(row, sk::kId, 0, kIntHigh);
        t.id = static_cast<std::uint32_t>(id);
        t.sect = sheet.integer(row, sk::kSect, -1, 100);
        t.skill_class = sheet.integer(row, sk::kInnerArt, kIntLow, kIntHigh);
        t.must_use_weapon = flag(sheet, row, sk::kMustUseWeapon);
        t.disabled_by_control_1 = flag(sheet, row, sk::kDisabled1);
        t.disabled_by_control_2 = flag(sheet, row, sk::kDisabled2);
        t.disabled_by_transform = flag(sheet, row, sk::kDisabledTransform);
        t.type = static_cast<SkillType>(sheet.integer(row, sk::kType, 0, 3));
        t.cooldown_id = sheet.integer(row, sk::kCooldownId, kIntLow, kIntHigh);
        t.target_state = sheet.integer(row, sk::kTargetState, -1, 1);
        t.user_class = sheet.integer(row, sk::kUserClass, 0, 9);
        t.passive = flag(sheet, row, sk::kPassive);
        t.select = static_cast<SelectType>(sheet.integer(row, sk::kSelect, 0, 9));
        t.skill_group = sheet.integer(row, sk::kGroup, kIntLow, kIntHigh);
        t.targeting = static_cast<TargetLogic>(sheet.integer(row, sk::kTargeting, 0, 20));
        // -1 là "không có thời gian ra chiêu" (kỹ năng 3296, 3325 của bảng thật): coi như 0.
        t.action_time_ms = std::max(0, sheet.integer(row, sk::kActionTime, -1, 3'600'000));
        t.range_cm = round_ratio32(sheet.scaled(row, sk::kRange, 100), 1);
        t.stand = sheet.integer(row, sk::kStand, -1, 1);
        t.target_by_stand = sheet.integer(row, sk::kTargetByStand, -1, 1);
        t.target_by_kind = sheet.integer(row, sk::kTargetByKind, -1, 2);
        t.auto_shot = flag(sheet, row, sk::kAutoShot);
        t.radius_cm = round_ratio32(sheet.scaled(row, sk::kRadius, 100), 1);
        t.max_targets = sheet.integer(row, sk::kMaxTargets, -1, 100'000);
        t.interrupt_auto_shot = flag(sheet, row, sk::kInterruptAuto);
        t.delay_ms = std::max(0, sheet.integer(row, sk::kDelay, -3'600'000, 3'600'000));
        t.charges_or_interval = sheet.integer(row, sk::kCharges, kIntLow, kIntHigh);
        t.accuracy = sheet.integer(row, sk::kAccuracy, -1, 100'000);
        t.disrupt_chance = sheet.integer(row, sk::kDisruptChance, 0, 100'000);
        t.disrupt_time_permille = round_ratio32(sheet.scaled(row, sk::kDisruptTime, 1000), 1);
        for (std::size_t k = 0; k < kInnerArtSlots; ++k) {
            const std::int32_t instance = sheet.integer(row, sk::kFirstInstance + k, kIntLow, kIntHigh);
            t.instance.at(k) = instance > 0 ? static_cast<std::uint32_t>(instance) : 0U;
        }
        if (sheet.error()) return sheet.error();
        out.push_back(t);
    }
    std::ranges::sort(out, {}, &SkillTemplate::id);
    const auto dup = std::ranges::adjacent_find(out, {}, &SkillTemplate::id);
    if (dup != out.end()) return fail(kName, std::format("id kỹ năng {} lặp", dup->id));
    return std::nullopt;
}

Failure load_levels(std::string_view text, std::vector<SkillLevel>& out) {
    constexpr std::string_view kName = "skill_levels.tsv";
    auto tsv = parse_table(kName, text);
    if (!tsv) return tsv.error();
    Sheet sheet(kName, *tsv);
    const HeaderSpec header{.name = kName, .columns = lv::kColumns, .first_col = lv::kId, .first_name = "id",
        .marker_name = "logic_id", .marker_col = lv::kLogic};
    if (Failure bad = require_header(sheet, header, *tsv)) return bad;
    if (sheet.rows() > kMaxLevelRows) return fail(kName, "quá nhiều dòng");
    out.reserve(sheet.rows());
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        SkillLevel l;
        l.id = static_cast<std::uint32_t>(sheet.integer(row, lv::kId, 0, kIntHigh));
        l.logic = sheet.integer(row, lv::kLogic, -1, kIntHigh);
        l.cooldown_ms = sheet.integer(row, lv::kCooldown, kIntLow, kIntHigh);
        l.charge_ms = sheet.integer(row, lv::kCharge, kIntLow, kIntHigh);
        l.channel_ms = sheet.integer(row, lv::kChannel, kIntLow, kIntHigh);
        for (std::size_t t = 0; t < kConditionTerms; ++t) {
            const std::size_t base = lv::kFirstTerm + (t * lv::kTermStride);
            l.terms.at(t).kind = sheet.integer(row, base, kIntLow, kIntHigh);
            l.terms.at(t).first = sheet.integer(row, base + 1, kIntLow, kIntHigh);
            l.terms.at(t).second = sheet.integer(row, base + 2, kIntLow, kIntHigh);
        }
        l.target_level = sheet.integer(row, lv::kTargetLevel, kIntLow, kIntHigh);
        for (std::size_t k = 0; k < kSkillParamCount; ++k) {
            l.param.at(k) = sheet.integer(row, lv::kFirstParam + (2 * k), kIntLow, kIntHigh);
        }
        if (sheet.error()) return sheet.error();
        out.push_back(l);
    }
    std::ranges::sort(out, {}, &SkillLevel::id);
    const auto dup = std::ranges::adjacent_find(out, {}, &SkillLevel::id);
    if (dup != out.end()) return fail(kName, std::format("id dòng cấp {} lặp", dup->id));
    return std::nullopt;
}

Failure load_effects(std::string_view text, std::vector<Effect>& out) {
    constexpr std::string_view kName = "effects.tsv";
    auto tsv = parse_table(kName, text);
    if (!tsv) return tsv.error();
    Sheet sheet(kName, *tsv);
    const HeaderSpec header{.name = kName, .columns = ef::kColumns, .first_col = ef::kId, .first_name = "data_index",
        .marker_name = "logic_id", .marker_col = ef::kLogic};
    if (Failure bad = require_header(sheet, header, *tsv)) return bad;
    if (sheet.rows() > kMaxEffectRows) return fail(kName, "quá nhiều dòng");
    out.reserve(sheet.rows());
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        Effect e;
        e.id = static_cast<std::uint32_t>(sheet.integer(row, ef::kId, 0, kIntHigh));
        e.logic = sheet.integer(row, ef::kLogic, -1, kIntHigh);
        e.over_timed = flag(sheet, row, ef::kOverTimed);
        e.impact_id = sheet.integer(row, ef::kImpactId, kIntLow, kIntHigh);
        e.mutex_id = sheet.integer(row, ef::kMutex, kIntLow, kIntHigh);
        e.level = sheet.integer(row, ef::kLevel, kIntLow, kIntHigh);
        e.stand = std::clamp(sheet.integer(row, ef::kStand, kIntLow, kIntHigh), -1, 1);
        e.keep_on_corpse = flag(sheet, row, ef::kKeepCorpse);
        e.dispellable = flag(sheet, row, ef::kDispellable);
        e.cancellable = flag(sheet, row, ef::kCancellable);
        e.needs_channel = flag(sheet, row, ef::kNeedsChannel);
        e.ignore_filter = flag(sheet, row, ef::kIgnoreFilter);
        e.fade_on_damage = flag(sheet, row, ef::kFadeDamage);
        e.fade_on_action = flag(sheet, row, ef::kFadeAction);
        e.fade_on_offline = flag(sheet, row, ef::kFadeOffline);
        e.timing_offline = flag(sheet, row, ef::kTimingOffline);
        e.continuance_ms = sheet.integer(row, ef::kContinuance, -1, kIntHigh);
        e.interval_ms = std::max(0, sheet.integer(row, ef::kInterval, kIntLow, kIntHigh));
        e.mutex_by_caster = flag(sheet, row, ef::kMutexByCaster);
        for (std::size_t k = 0; k < kEffectParamCount; ++k) {
            e.param.at(k) = sheet.integer(row, ef::kFirstParam + (ef::kParamStride * k), kIntLow, kIntHigh);
        }
        if (sheet.error()) return sheet.error();
        out.push_back(e);
    }
    std::ranges::sort(out, {}, &Effect::id);
    const auto dup = std::ranges::adjacent_find(out, {}, &Effect::id);
    if (dup != out.end()) return fail(kName, std::format("id hiệu ứng {} lặp", dup->id));
    return std::nullopt;
}

constexpr std::size_t kCollectionMaxIds = 30;
constexpr std::size_t kCollectionFirstId = 4;

Failure load_collections(std::string_view text, std::vector<Collection>& out) {
    constexpr std::string_view kName = "id_collections.tsv";
    auto tsv = parse_table(kName, text);
    if (!tsv) return tsv.error();
    Sheet sheet(kName, *tsv);
    if (sheet.columns() < kCollectionFirstId) return fail(kName, "thiếu cột");
    if (sheet.rows() > kMaxCollections) return fail(kName, "quá nhiều dòng");
    out.reserve(sheet.rows());
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        Collection c;
        c.id = sheet.integer(row, 0, 0, kIntHigh);
        c.kind = sheet.integer(row, 2, -1, 1000);
        const auto count = static_cast<std::size_t>(sheet.integer(row, 3, 0, 1000));
        const std::size_t usable = std::min({count, kCollectionMaxIds, sheet.columns() - kCollectionFirstId});
        c.ids.reserve(usable);
        for (std::size_t k = 0; k < usable; ++k) {
            c.ids.push_back(sheet.integer(row, kCollectionFirstId + k, kIntLow, kIntHigh));
        }
        if (sheet.error()) return sheet.error();
        out.push_back(std::move(c));
    }
    std::ranges::sort(out, {}, &Collection::id);
    const auto dup = std::ranges::adjacent_find(out, {}, &Collection::id);
    if (dup != out.end()) return fail(kName, std::format("id tập {} lặp", dup->id));
    return std::nullopt;
}

Failure load_camps(std::string_view text, std::vector<std::vector<std::uint8_t>>& out) {
    constexpr std::string_view kName = "camp_relations.tsv";
    auto tsv = parse_table(kName, text);
    if (!tsv) return tsv.error();
    Sheet sheet(kName, *tsv);
    constexpr std::size_t kMaxCamps = 256;
    if (sheet.rows() > kMaxCamps || sheet.columns() < 2) return fail(kName, "sai kích thước");
    const std::size_t camps = sheet.columns() - 1;
    out.assign(sheet.rows(), std::vector<std::uint8_t>(camps, 1));
    std::vector<bool> seen(sheet.rows(), false);
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        const auto id = static_cast<std::size_t>(sheet.integer(row, 0, 0, static_cast<std::int32_t>(kMaxCamps)));
        if (sheet.error()) return sheet.error();
        if (id >= out.size()) return fail(kName, std::format("dòng {}: id phe {} ngoài 0..{}", row, id, out.size() - 1));
        if (seen[id]) return fail(kName, std::format("id phe {} lặp", id));
        seen[id] = true;
        for (std::size_t other = 0; other < camps; ++other) {
            out[id][other] = sheet.integer(row, other + 1, 0, 1) != 0 ? 1 : 0;
        }
        if (sheet.error()) return sheet.error();
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<Fidelity> parse_fidelity(std::string_view text) noexcept {
    if (text == "full") return Fidelity::kFull;
    if (text == "core") return Fidelity::kCore;
    if (text == "event") return Fidelity::kEvent;
    return std::nullopt;
}

Failure load_logics(std::string_view name, std::string_view text, bool skill, std::vector<LogicSpec>& out) {
    if (text.empty()) return std::nullopt;
    auto tsv = parse_table(name, text);
    if (!tsv) return tsv.error();
    Sheet sheet(name, *tsv);
    const std::size_t c_logic = sheet.column("logic_id");
    const std::size_t c_handler = sheet.column("handler");
    const std::size_t c_roles = sheet.column("roles");
    const std::size_t c_fidelity = sheet.column("fidelity");
    const std::size_t c_note = sheet.column("note");
    if (sheet.error()) return sheet.error();
    out.reserve(sheet.rows());
    for (std::size_t row = 0; row < sheet.rows(); ++row) {
        LogicSpec spec;
        spec.logic = sheet.integer(row, c_logic, 0, kMaxLogicId);
        spec.handler = std::string(sheet.text(row, c_handler));
        spec.note = std::string(sheet.text(row, c_note));
        if (sheet.error()) return sheet.error();
        const std::string_view roles_text = sheet.text(row, c_roles);
        const auto roles = parse_roles(roles_text);
        if (!roles) return fail(name, std::format("logic {}: roles \"{}\" sai cú pháp", spec.logic, roles_text));
        spec.roles = *roles;
        const auto fidelity = parse_fidelity(sheet.text(row, c_fidelity));
        if (!fidelity) return fail(name, std::format("logic {}: fidelity \"{}\" lạ", spec.logic, sheet.text(row, c_fidelity)));
        spec.fidelity = *fidelity;
        const bool known = skill ? known_skill_handler(spec.handler) : known_effect_handler(spec.handler);
        if (!known) return fail(name, std::format("logic {}: handler \"{}\" không có trong mã", spec.logic, spec.handler));
        out.push_back(std::move(spec));
    }
    std::ranges::sort(out, {}, &LogicSpec::logic);
    const auto dup = std::ranges::adjacent_find(out, {}, &LogicSpec::logic);
    if (dup != out.end()) return fail(name, std::format("logic {} lặp", dup->logic));
    return std::nullopt;
}

template <typename T, typename Key>
[[nodiscard]] const T* find_sorted(const std::vector<T>& rows, Key key, Key T::*member) noexcept {
    const auto it = std::ranges::lower_bound(rows, key, {}, member);
    return it != rows.end() && (*it).*member == key ? &*it : nullptr;
}

} // namespace

bool Collection::contains(std::int32_t value) const noexcept { return std::ranges::find(ids, value) != ids.end(); }

bool Collection::is_buff_kind() const noexcept {
    return kind == static_cast<std::int32_t>(CollectionKind::kBuff) || (kind >= 7 && kind <= 10);
}

const SkillTemplate* Catalog::skill(std::uint32_t id) const noexcept { return find_sorted(skills_, id, &SkillTemplate::id); }
const SkillLevel* Catalog::level(std::uint32_t instance_id) const noexcept { return find_sorted(levels_, instance_id, &SkillLevel::id); }
const Effect* Catalog::effect(std::uint32_t id) const noexcept { return find_sorted(effects_, id, &Effect::id); }
const Collection* Catalog::collection(std::int32_t id) const noexcept { return find_sorted(collections_, id, &Collection::id); }
const LogicSpec* Catalog::skill_logic(std::int32_t logic) const noexcept { return find_sorted(skill_logics_, logic, &LogicSpec::logic); }
const LogicSpec* Catalog::effect_logic(std::int32_t logic) const noexcept { return find_sorted(effect_logics_, logic, &LogicSpec::logic); }

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): id kỹ năng và cấp khác vai, nơi gọi đặt tên (HP-07)
const SkillLevel* Catalog::level_of(std::uint32_t skill_id, std::uint8_t level_number) const noexcept {
    const SkillTemplate* tmpl = skill(skill_id);
    if (tmpl == nullptr || level_number == 0 || level_number > kInnerArtSlots) return nullptr;
    const std::uint32_t instance = tmpl->instance.at(static_cast<std::size_t>(level_number) - 1U);
    return instance == 0 ? nullptr : level(instance);
}

Relation Catalog::camp_relation(std::int32_t from_camp, std::int32_t to_camp) const noexcept {
    if (from_camp < 0 || to_camp < 0) return Relation::kFriend;
    const auto from = static_cast<std::size_t>(from_camp);
    const auto to = static_cast<std::size_t>(to_camp);
    if (from >= camp_friend_.size() || to >= camp_friend_[from].size()) return Relation::kFriend;
    return camp_friend_[from][to] != 0 ? Relation::kFriend : Relation::kEnemy;
}

std::optional<std::vector<Role>> parse_roles(std::string_view text) {
    std::vector<Role> roles;
    if (text.empty() || text == "-") return roles;
    struct Named {
        std::string_view name;
        RoleKind kind;
    };
    static constexpr std::array kNames = {
        Named{.name = "target", .kind = RoleKind::kTarget}, Named{.name = "self", .kind = RoleKind::kSelf},
        Named{.name = "target_tick", .kind = RoleKind::kTargetTick}, Named{.name = "self_tick", .kind = RoleKind::kSelfTick},
        Named{.name = "friend", .kind = RoleKind::kFriend}, Named{.name = "enemy", .kind = RoleKind::kEnemy},
        Named{.name = "rest", .kind = RoleKind::kRest}, Named{.name = "friend_rest", .kind = RoleKind::kFriendRest},
        Named{.name = "enemy_rest", .kind = RoleKind::kEnemyRest}, Named{.name = "self_male", .kind = RoleKind::kSelfMale},
        Named{.name = "self_female", .kind = RoleKind::kSelfFemale}, Named{.name = "trap", .kind = RoleKind::kTrap},
        Named{.name = "trap_tick", .kind = RoleKind::kTrapTick}, Named{.name = "summon", .kind = RoleKind::kSummon},
        Named{.name = "totem", .kind = RoleKind::kTotem}, Named{.name = "dispel_self", .kind = RoleKind::kDispelSelf},
        Named{.name = "cut_cooldown", .kind = RoleKind::kCutCooldown}, Named{.name = "sub", .kind = RoleKind::kSub},
    };
    struct Ranked {
        std::string_view prefix;
        RoleKind kind;
        std::int64_t max;
    };
    static constexpr std::array kRanked = {
        Ranked{.prefix = "rank", .kind = RoleKind::kRank, .max = 15},
        Ranked{.prefix = "friend", .kind = RoleKind::kFriendRank, .max = 15},
        Ranked{.prefix = "enemy", .kind = RoleKind::kEnemyRank, .max = 15},
        Ranked{.prefix = "combo", .kind = RoleKind::kCombo, .max = 3},
    };
    constexpr std::size_t kMaxRoles = 64;
    constexpr std::int64_t kMaxIndex = 63;
    constexpr std::string_view kMarks = "@*+";
    std::size_t pos = 0;
    while (pos <= text.size()) {
        const std::size_t end = std::min(text.find(';', pos), text.size());
        const std::string_view part = text.substr(pos, end - pos);
        pos = end + 1;
        if (part.empty() || roles.size() >= kMaxRoles) return std::nullopt;
        const std::size_t colon = part.find(':');
        if (colon == std::string_view::npos) return std::nullopt;
        const core::OptionalSigned index = core::parse_signed(part.substr(0, colon));
        if (!index || index->length != colon || index->value < 0 || index->value > kMaxIndex) return std::nullopt;
        const std::string_view rest = part.substr(colon + 1);
        Role role;
        role.param = static_cast<std::int8_t>(index->value);
        const auto take_suffix = [&rest, kMarks](char mark, std::int8_t& into) -> bool {
            const std::size_t at = rest.find(mark);
            if (at == std::string_view::npos) return true;
            const std::string_view number = rest.substr(at + 1);
            const std::string_view digits = number.substr(0, number.find_first_of(kMarks));
            const core::OptionalSigned value = core::parse_signed(digits);
            if (!value || value->length != digits.size() || digits.empty() || value->value < 0 || value->value > kMaxIndex) return false;
            into = static_cast<std::int8_t>(value->value);
            return true;
        };
        if (!take_suffix('@', role.chance) || !take_suffix('*', role.repeat) || !take_suffix('+', role.aux)) return std::nullopt;
        const std::string_view name = rest.substr(0, rest.find_first_of(kMarks));
        bool matched = false;
        for (const Named& named : kNames) {
            if (named.name == name) {
                role.kind = named.kind;
                matched = true;
                break;
            }
        }
        for (const Ranked& ranked : kRanked) {
            if (matched || !name.starts_with(ranked.prefix) || name.size() == ranked.prefix.size()) continue;
            const std::string_view digits = name.substr(ranked.prefix.size());
            const core::OptionalSigned n = core::parse_signed(digits);
            if (!n || n->length != digits.size() || n->value < 0 || n->value > ranked.max) continue;
            role.kind = ranked.kind;
            role.arg = static_cast<std::uint8_t>(n->value);
            matched = true;
        }
        if (!matched) return std::nullopt;
        if (role.kind == RoleKind::kCutCooldown && role.aux < 0) return std::nullopt;
        roles.push_back(role);
        if (end == text.size()) break;
    }
    return roles;
}

Loaded<Catalog> load_catalog(const CatalogText& text) {
    Catalog catalog;
    if (Failure bad = load_skills(text.skills, catalog.skills_)) return std::unexpected(*bad);
    if (Failure bad = load_levels(text.skill_levels, catalog.levels_)) return std::unexpected(*bad);
    if (Failure bad = load_effects(text.effects, catalog.effects_)) return std::unexpected(*bad);
    if (Failure bad = load_collections(text.id_collections, catalog.collections_)) return std::unexpected(*bad);
    if (Failure bad = load_camps(text.camp_relations, catalog.camp_friend_)) return std::unexpected(*bad);
    if (Failure bad = load_logics("skill_logics.tsv", text.skill_logics, true, catalog.skill_logics_)) return std::unexpected(*bad);
    if (Failure bad = load_logics("effect_logics.tsv", text.effect_logics, false, catalog.effect_logics_)) return std::unexpected(*bad);
    return catalog;
}

} // namespace game::combat
