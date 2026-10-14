// Ra chiêu: kiểm điều kiện, tiêu hao, nhắm mục tiêu, trúng/né, hội tâm, gom khí, dẫn khí, hồi chiêu (xem arena.hpp).
//
// Nguồn: GameServer 2008 Skill_Core.cpp (ProcessSkillRequest, ActiveSkillNow, InstanceSkill), SkillLogic.cpp
// (StartCharging, StartChanneling, Action_ActivateOnceHandler, ActivateOnce, CalculateTargetList, HitThisTarget,
// CriticalHitThisTarget, TargetCheck*), ConditionAndDeplete_Core.cpp, Action/*.cpp (gom/dẫn/gián đoạn).
#include "combat/arena.hpp"

#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/numeric.hpp"
#include "actor/rules.hpp"
#include "combat/catalog.hpp"
#include "combat/damage.hpp"
#include "combat/detail/skills.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <string_view>
#include <utility>
#include <vector>

namespace game::combat {
namespace {

using actor::round_ratio;

constexpr std::uint32_t kMeleeAttackSkill = 0;       // MELEE_ATTACK: đòn thường dùng giờ của dòng quái
constexpr std::int32_t kMinActionTimeMs = 500;       // MIN_ACTION_TIME: hành động không ngắn hơn
constexpr std::int32_t kMaxActivations = 32;         // trần số lần phát một lượt (bảng sai không được lặp vô hạn)
constexpr std::int32_t kPercent = 100;

[[nodiscard]] const actor::MonsterRow* monster_row_of(const Fighter& unit) noexcept { return unit.body.monster_row(); }

} // namespace

std::string_view describe(CastOutcome outcome) noexcept {
    switch (outcome) {
    case CastOutcome::kOk: return "đã nhận lệnh";
    case CastOutcome::kNoCaster: return "không có người ra chiêu";
    case CastOutcome::kDead: return "người ra chiêu đã chết";
    case CastOutcome::kUnknownSkill: return "kỹ năng hoặc cấp kỹ năng không có trong bảng";
    case CastOutcome::kNotLearned: return "chưa học kỹ năng này";
    case CastOutcome::kCooldown: return "kỹ năng đang hồi chiêu";
    case CastOutcome::kBusy: return "đang bận hành động khác";
    case CastOutcome::kNoWeapon: return "kỹ năng cần vũ khí";
    case CastOutcome::kForbidden: return "trạng thái hiện tại không cho dùng kỹ năng này";
    case CastOutcome::kInvalidTarget: return "mục tiêu không hợp lệ";
    case CastOutcome::kTargetDead: return "mục tiêu đã chết";
    case CastOutcome::kOutOfRange: return "mục tiêu ngoài tầm";
    case CastOutcome::kLackMana: return "thiếu nội lực";
    case CastOutcome::kLackRage: return "thiếu nộ khí";
    case CastOutcome::kLackStrike: return "thiếu điểm liên kích";
    case CastOutcome::kLackHp: return "thiếu sinh lực";
    case CastOutcome::kConditionFailed: return "không thoả điều kiện dùng kỹ năng";
    case CastOutcome::kUnsupported: return "logic kỹ năng chưa có mã";
    }
    return "kết quả ra chiêu lạ";
}

const detail::SkillHandler* Arena::skill_handler(std::int32_t logic) const noexcept {
    if (logic < 0) return nullptr;
    const auto index = static_cast<std::size_t>(logic);
    return index < skill_table_.size() ? skill_table_[index] : nullptr;
}

// ---------------------------------------------------------------------------------------------------------
// Hồi chiêu

std::int64_t Arena::cooldown_remaining(const Fighter& unit, std::int32_t id) const noexcept {
    for (const Cooldown& cooldown : unit.cooldowns) {
        if (cooldown.id != id) continue;
        return cooldown.until.value() > now_.value() ? static_cast<std::int64_t>(cooldown.until.value() - now_.value()) : 0;
    }
    return 0;
}

void Arena::clear_cooldown(Fighter& unit, std::int32_t id) {
    std::erase_if(unit.cooldowns, [id](const Cooldown& cooldown) { return cooldown.id == id; });
}

void Arena::set_cooldown(Fighter& unit, std::int32_t id, std::int64_t ticks) {
    if (id < 0) return;  // INVALID_ID: kỹ năng không thuộc nhóm hồi chiêu nào
    clear_cooldown(unit, id);
    if (ticks <= 0) return;
    if (unit.cooldowns.size() >= kMaxCooldowns) {
        // Đầy: bỏ nhóm sắp hết hạn nhất (nhóm hết hạn đã được dọn mỗi nhịp, nên hiếm khi tới đây).
        const auto soonest = std::ranges::min_element(unit.cooldowns, {}, [](const Cooldown& cooldown) { return cooldown.until.value(); });
        unit.cooldowns.erase(soonest);
    }
    unit.cooldowns.push_back(Cooldown{.id = id, .until = ids::advance(now_, ids::TickSpan{ticks})});
}

bool Arena::cooldown_ready(const Fighter& unit, const SkillTemplate& tmpl) const noexcept {
    // Kỹ năng không có nhóm hồi chiêu hoặc là đòn tự lặp dùng chung đồng hồ đòn tự lặp (Skill_IsSkillCooldowned).
    if (tmpl.cooldown_id < 0 || tmpl.auto_shot) return now_.value() >= unit.auto_repeat_until.value();
    return cooldown_remaining(unit, tmpl.cooldown_id) == 0;
}

void Arena::apply_cooldown(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info) {
    std::int64_t cooldown_ms = info.cooldown_ms;
    std::int64_t action_ms = tmpl.action_time_ms;
    const actor::MonsterRow* row = monster_row_of(unit);
    if (tmpl.id == kMeleeAttackSkill && row != nullptr) {
        cooldown_ms = row->attack_cooldown_ms;
        action_ms = row->attack_animation_ms;
    }
    cooldown_ms = std::max(cooldown_ms, action_ms);  // hồi chiêu không ngắn hơn thời gian diễn hoạt
    const std::int64_t ticks = ms_to_ticks(cooldown_ms);
    if (tmpl.auto_shot) {
        // Khác gốc: bản 2008 cộng dồn phần còn lại của đồng hồ đòn tự lặp vào lần đặt mới; ở đây chỉ đặt lại.
        unit.auto_repeat_until = ids::advance(now_, ids::TickSpan{ticks});
    } else {
        set_cooldown(unit, tmpl.cooldown_id, ticks);
    }
}

bool Arena::busy(const Fighter& unit) const noexcept {
    return unit.action.phase != ActionState::Phase::kIdle || now_.value() < unit.action_lock_until.value();
}

// ---------------------------------------------------------------------------------------------------------
// Kiểm tra trước khi ra chiêu

bool Arena::filtered_out(const Fighter& unit, const SkillTemplate& tmpl) const {
    for (const SkillFilter& filter : unit.aggregates.filters) {
        if (filter.skill_collection == kInvalidId) continue;
        const bool listed = skill_in_collection(tmpl.id, filter.skill_collection);
        if (filter.allow != listed) return true;
    }
    return false;
}

bool Arena::can_use_in_status(const Fighter& unit, const SkillTemplate& tmpl) const {
    if (tmpl.disabled_by_control_1 && !unit.aggregates.can_action1) return false;
    if (tmpl.disabled_by_control_2 && !unit.aggregates.can_action2) return false;
    if (tmpl.disabled_by_transform && unit.aggregates.mount != kInvalidId) return false;
    return !filtered_out(unit, tmpl);
}

bool Arena::skill_known(const Fighter& unit, const SkillTemplate& tmpl, std::uint8_t level) const noexcept {
    if (unit.kind != FighterKind::kHuman || tmpl.user_class != 0) return true;
    if (tmpl.sect < 0 && tmpl.skill_class < 0) return true;  // kỹ năng chung (đòn thường, cưỡi...) ai cũng có
    return std::ranges::any_of(unit.skills, [&tmpl, level](const SkillEntry& entry) { return entry.id == tmpl.id && entry.level >= level; });
}

bool Arena::visible_to(const Fighter& viewer, const Fighter& subject) const noexcept {
    // CalcIsTargetStealth: bị giấu khi (ẩn thân + cấp) vượt (dò thân + cấp) của người nhìn.
    const std::int32_t stealth = subject.aggregates.stealth;
    if (stealth <= 0 || &viewer == &subject) return true;
    const std::int64_t seeing = static_cast<std::int64_t>(viewer.aggregates.detect) + viewer.body.level();
    const std::int64_t hidden = static_cast<std::int64_t>(stealth) + subject.body.level();
    return hidden <= seeing;
}

bool Arena::out_of_range(const Fighter& unit, const SkillTemplate& tmpl, Position where) const noexcept {
    if (tmpl.range_cm <= 0) return false;
    const std::int64_t reach = static_cast<std::int64_t>(tmpl.range_cm) + limits_.range_tolerance_cm;
    return distance_sq_cm(unit.position, where) > reach * reach;
}

bool Arena::wanted_target(const Fighter& unit, const Fighter& other, const SkillTemplate& tmpl) const {
    const FighterKind kind = other.kind;
    if (tmpl.target_by_kind == 0 && kind != FighterKind::kHuman) return false;
    if (tmpl.target_by_kind == 2 && kind != FighterKind::kMonster) return false;
    if (tmpl.target_by_kind == 1) return false;  // thú: chưa có trong lõi
    if (tmpl.target_state == 1) {
        if (other.alive()) return false;
    } else if (!other.alive()) {
        // Khác gốc: quét vùng bỏ xác trừ khi kỹ năng nói rõ cần xác (bản 2008 trả lời bởi ScanOperator_AESkill không có
        // trong mã nguồn đã đọc).
        return false;
    }
    if (tmpl.target_by_stand == 0 && !is_friend(unit, other)) return false;
    if (tmpl.target_by_stand == 1 && is_friend(unit, other)) return false;
    return visible_to(unit, other);
}

CastOutcome Arena::check_terms(const Fighter& unit, const CastInfo& info, const Target& target) const {
    const bool human = unit.kind == FighterKind::kHuman;
    const actor::Body& body = unit.body;
    for (const Term& term : info.terms) {
        switch (static_cast<TermKind>(term.kind)) {
        case TermKind::kManaByValue:
        case TermKind::kManaByRate: {
            if (!human) break;
            std::int64_t mana = 0;
            if (term.kind == static_cast<std::int32_t>(TermKind::kManaByValue)) {
                mana = round_ratio(static_cast<std::int64_t>(term.first) * (kPercent + info.deplete_rate), kPercent) + info.deplete_value;
            } else {
                const std::int64_t rate = round_ratio(static_cast<std::int64_t>(term.first) * (kPercent + info.deplete_rate), kPercent);
                mana = round_ratio(static_cast<std::int64_t>(body.stat(actor::Stat::kMaxMp)) * rate, kPercent) + info.deplete_value;
            }
            if (body.mp() < std::max<std::int64_t>(0, mana)) return CastOutcome::kLackMana;
            break;
        }
        case TermKind::kRageByRate: {
            if (!human) break;
            const std::int64_t rage = round_ratio(static_cast<std::int64_t>(term.first) * body.stat(actor::Stat::kMaxRage), kPercent);
            if (body.rage() < rage) return CastOutcome::kLackRage;
            break;
        }
        case TermKind::kStrikeBySegment:
            if (human && body.strike_points() < static_cast<std::int64_t>(term.first) * kStrikeSegment) return CastOutcome::kLackStrike;
            break;
        case TermKind::kUnitHaveBuff:
            if (first_buff_in_collection(unit, term.first) == nullptr) return CastOutcome::kConditionFailed;
            break;
        case TermKind::kTargetHaveBuff: {
            const Fighter* other = find(target.unit);
            if (other == nullptr || first_buff_in_collection(*other, term.first) == nullptr) return CastOutcome::kInvalidTarget;
            break;
        }
        case TermKind::kUnitHpAtMost:
            if (unit.kind == FighterKind::kMonster) break;
            if (body.hp() > round_ratio(static_cast<std::int64_t>(body.stat(actor::Stat::kMaxHp)) * term.first, kPercent)) {
                return CastOutcome::kConditionFailed;
            }
            break;
        case TermKind::kTargetIsSpouse: {
            const Fighter* other = find(target.unit);
            if (!human || other == nullptr || other->kind != FighterKind::kHuman) return CastOutcome::kInvalidTarget;
            if (!spouse_policy_ || !spouse_policy_(unit, *other) || !spouse_policy_(*other, unit)) return CastOutcome::kInvalidTarget;
            break;
        }
        case TermKind::kHpByRate:
        case TermKind::kHpAtLeast: {
            if (unit.kind == FighterKind::kMonster) break;
            const std::int64_t hp = round_ratio(static_cast<std::int64_t>(term.first) * body.stat(actor::Stat::kMaxHp), kPercent);
            if (body.hp() < hp) return CastOutcome::kLackHp;
            break;
        }
        case TermKind::kTargetLevelAtMost:  // mã 2008 không có thân hàm: luôn qua
        case TermKind::kAllRage:
        case TermKind::kCancelBuffs:
            break;
        }
        // Không có nhãn default: loại lạ của dữ liệu 2026 (13, 15..21) rơi ra khỏi switch, mà logic gốc cũng trả đúng cho
        // loại lạ. Clang cấm default trên switch đã phủ hết enum (-Wcovered-switch-default).
    }
    return CastOutcome::kOk;
}

bool Arena::deplete(Fighter& unit, CastInfo& info) {
    const bool human = unit.kind == FighterKind::kHuman;
    for (const Term& term : info.terms) {
        switch (static_cast<TermKind>(term.kind)) {
        case TermKind::kManaByValue:
        case TermKind::kManaByRate: {
            if (!human) break;
            std::int64_t mana = 0;
            const std::int64_t rate = round_ratio(static_cast<std::int64_t>(term.first) * (kPercent + info.deplete_rate), kPercent);
            if (term.kind == static_cast<std::int32_t>(TermKind::kManaByValue)) {
                mana = rate + info.deplete_value;
            } else {
                mana = round_ratio(static_cast<std::int64_t>(unit.body.stat(actor::Stat::kMaxMp)) * rate, kPercent) + info.deplete_value;
            }
            change_mp(unit, unit.handle, -std::max<std::int64_t>(0, mana));
            break;
        }
        case TermKind::kRageByRate: {
            if (!human) break;
            // Tham số 1 bằng 0: trừ theo phần trăm của mức tối đa; khác 0: trừ hết nộ khí đang có.
            const std::int64_t amount = term.second == 0 ? round_ratio(static_cast<std::int64_t>(term.first) * unit.body.stat(actor::Stat::kMaxRage), kPercent)
                                                          : unit.body.rage();
            change_rage(unit, unit.handle, -amount);
            break;
        }
        case TermKind::kAllRage: {
            if (!human) break;
            change_rage(unit, unit.handle, -round_ratio(static_cast<std::int64_t>(term.first) * unit.body.stat(actor::Stat::kMaxRage), kPercent));
            break;
        }
        case TermKind::kStrikeBySegment: {
            if (!human) break;
            const std::int32_t points = (unit.body.strike_points() / kStrikeSegment) * kStrikeSegment;
            const std::int32_t rage_before = unit.body.rage();
            if (points > 0 && unit.body.spend_strike(points)) {
                info.strike_spent += points;
                emit(EventKind::kStrikeChanged, unit.handle, unit.handle, 0, -points);
                // Tiêu liên kích sinh nộ khí theo luật phái (MenPai OnStrikeSpent).
                if (unit.body.rage() != rage_before) emit(EventKind::kRageChanged, unit.handle, unit.handle, 0, unit.body.rage() - rage_before);
            }
            break;
        }
        case TermKind::kCancelBuffs: cancel_collection(unit, term.first); break;
        case TermKind::kHpByRate:
            if (human) change_hp(unit, unit.handle, -round_ratio(static_cast<std::int64_t>(term.first) * unit.body.stat(actor::Stat::kMaxHp), kPercent));
            break;
        default: break;
        }
    }
    return true;
}

CastOutcome Arena::check_target(const Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target,
    bool for_tick) const {
    // Chiêu quanh bản thân hoặc tự thân không cần mục tiêu (client vẫn gửi chính mình làm mục tiêu).
    if (tmpl.targeting == TargetLogic::kSelf || tmpl.targeting == TargetLogic::kAroundSelf) return CastOutcome::kOk;
    if (tmpl.select == SelectType::kPosition) {
        return !for_tick && out_of_range(unit, tmpl, target.position) ? CastOutcome::kOutOfRange : CastOutcome::kOk;
    }
    if (tmpl.select != SelectType::kCharacter) return CastOutcome::kOk;

    const Fighter* other = find(target.unit);
    if (other == nullptr) return CastOutcome::kInvalidTarget;
    if (!visible_to(unit, *other)) return CastOutcome::kInvalidTarget;
    if (tmpl.target_state == 0 && !other->alive()) return CastOutcome::kTargetDead;
    if (tmpl.target_state == 1 && other->alive()) return CastOutcome::kInvalidTarget;
    if (!for_tick) {
        if (tmpl.target_by_kind == 0 && other->kind != FighterKind::kHuman) return CastOutcome::kInvalidTarget;
        if (tmpl.target_by_kind == 2 && other->kind != FighterKind::kMonster) return CastOutcome::kInvalidTarget;
        if (tmpl.target_by_kind == 1) return CastOutcome::kInvalidTarget;
        const bool mine_hostile = !is_friend(unit, *other);
        const bool theirs_hostile = !is_friend(*other, unit);
        if (tmpl.target_by_stand == 0 && mine_hostile && theirs_hostile) return CastOutcome::kInvalidTarget;
        if (tmpl.target_by_stand == 1 && !mine_hostile && !theirs_hostile) return CastOutcome::kInvalidTarget;
    }
    if (out_of_range(unit, tmpl, other->position)) return CastOutcome::kOutOfRange;
    if (!for_tick && info.target_level != -1) {
        const std::int32_t level = other->body.level();
        if (is_friend(unit, *other) ? info.target_level > level : info.target_level < level) return CastOutcome::kInvalidTarget;
    }
    return CastOutcome::kOk;
}

// ---------------------------------------------------------------------------------------------------------
// Dựng bản kỹ năng

CastInfo Arena::instance(const SkillTemplate& tmpl, const SkillLevel& level, std::uint8_t level_number) const {
    CastInfo info;
    info.skill = tmpl.id;
    info.level = level_number;
    info.logic = level.logic;
    info.cooldown_ms = std::max(0, level.cooldown_ms);
    info.charge_ms = std::max(0, level.charge_ms);
    info.channel_ms = std::max(0, level.channel_ms);
    info.accuracy = tmpl.accuracy;
    info.critical = -1;
    info.target_level = level.target_level;
    info.terms = level.terms;
    info.param = level.param;
    return info;
}

// ---------------------------------------------------------------------------------------------------------
// Mục tiêu

void Arena::scan(const Fighter& unit, const SkillTemplate& tmpl, Position centre, std::vector<ids::EntityHandle>& out) const {
    // max_targets <= 0 là không giới hạn: units_around hiểu 0 là trần kMaxScanTargets.
    const std::size_t limit = tmpl.max_targets > 0 ? static_cast<std::size_t>(tmpl.max_targets) : 0;
    const std::vector<ids::EntityHandle> found = units_around(centre, tmpl.radius_cm, limit,
        [this, &unit, &tmpl](const Fighter& other) { return wanted_target(unit, other, tmpl); });
    out.insert(out.end(), found.begin(), found.end());
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): bán kính và số lượng khác nghĩa, nơi gọi nêu tên (HP-07)
std::vector<ids::EntityHandle> Arena::units_around(Position centre, std::int32_t radius_cm, std::size_t max_count,
    const std::function<bool(const Fighter&)>& accept) const {
    struct Candidate {
        std::int64_t distance = 0;
        ids::EntityHandle handle;
    };
    std::vector<Candidate> found;
    const std::int64_t radius = std::max<std::int32_t>(0, radius_cm);
    for (const auto& [handle, other] : fighters_) {
        const std::int64_t distance = distance_sq_cm(centre, other.position);
        if (distance > radius * radius || !accept(other)) continue;
        found.push_back(Candidate{.distance = distance, .handle = handle});
    }
    std::ranges::sort(found, [](const Candidate& a, const Candidate& b) {
        return a.distance != b.distance ? a.distance < b.distance : a.handle < b.handle;
    });
    const std::size_t limit = max_count == 0 ? kMaxScanTargets : std::min(max_count, kMaxScanTargets);
    std::vector<ids::EntityHandle> out;
    for (std::size_t i = 0; i < found.size() && i < limit; ++i) out.push_back(found.at(i).handle);
    return out;
}

std::vector<ids::EntityHandle> Arena::collect_targets(Fighter& unit, const SkillTemplate& tmpl, const Target& target) {
    std::vector<ids::EntityHandle> out;
    switch (tmpl.targeting) {
    case TargetLogic::kSelf: out.push_back(unit.handle); break;
    case TargetLogic::kAroundSelf: scan(unit, tmpl, unit.position, out); break;
    case TargetLogic::kSpecificUnit:
        if (find(target.unit) != nullptr) out.push_back(target.unit);
        break;
    case TargetLogic::kAroundUnit:
        if (const Fighter* centre = find(target.unit)) scan(unit, tmpl, centre->position, out);
        break;
    case TargetLogic::kAroundPosition: scan(unit, tmpl, target.position, out); break;
    case TargetLogic::kPet:          // lõi chưa có thú
    case TargetLogic::kShadowGuard:  // chưa có ảnh vệ
    case TargetLogic::kMaster:
        break;
    }
    // Không có nhãn default (Clang cấm trên switch phủ hết enum): logic nhắm lạ 8..11 của dữ liệu 2026 không chọn ai.
    return out;
}

bool Arena::hit_roll(Fighter& unit, const Fighter& other, const CastInfo& info) {
    if (is_friend(unit, other)) return true;  // chiêu cho phe mình luôn trúng
    std::int32_t accuracy = info.accuracy;
    if (accuracy == -1) accuracy = hit_rate(unit.body.stat(actor::Stat::kHit), other.body.stat(actor::Stat::kMiss));
    const bool hit = is_hit(accuracy, roll100());
    if (!hit) emit(EventKind::kMissed, unit.handle, other.handle, info.skill, static_cast<std::int32_t>(MissKind::kMiss));
    return hit;
}

bool Arena::critical_roll(Fighter& unit, const Fighter& other, const CastInfo& info) {
    if (is_friend(unit, other)) return false;  // chỉ chiêu tấn công mới có hội tâm
    const std::int32_t rate = info.critical == -1 ? unit.body.stat(actor::Stat::kCritical) : info.critical;
    return is_critical(rate, roll100());
}

void Arena::register_threat(Fighter& unit, Fighter& other, const SkillTemplate& tmpl) {
    emit(EventKind::kThreat, unit.handle, other.handle, tmpl.id, std::clamp(tmpl.stand, kStandHostile, kStandAmity));
}

void Arena::activate(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target, bool tick,
    std::int64_t delay_ticks) {
    const detail::SkillHandler* handler = skill_handler(info.logic);
    const LogicSpec* spec = catalog_->skill_logic(info.logic);
    if (handler == nullptr || spec == nullptr) return;
    const std::vector<ids::EntityHandle> targets = collect_targets(unit, tmpl, target);

    // Vòng một: trúng/né cho mọi mục tiêu (rút xúc xắc theo thứ tự quét).
    std::vector<ids::EntityHandle> landed;
    landed.reserve(targets.size());
    for (const ids::EntityHandle handle : targets) {
        Fighter* other = find(handle);
        if (other == nullptr) continue;
        if (!tick) register_threat(unit, *other, tmpl);
        if (hit_roll(unit, *other, info)) landed.push_back(handle);
    }
    // Vòng hai: hook trúng, hội tâm cho từng mục tiêu bị trúng.
    std::vector<Hit> hits;
    hits.reserve(landed.size());
    for (const ids::EntityHandle handle : landed) {
        Fighter* other = find(handle);
        if (other == nullptr) continue;
        Hit hit;
        hit.unit = handle;
        hit.relation = relation(unit, *other);
        run_on_be_hit(*other, unit);
        run_on_hit_target(unit, *other);
        hit.critical = critical_roll(unit, *other, info);
        if (hit.critical) run_on_critical(unit, *other);
        hits.push_back(hit);
    }
    detail::SkillRun run{.arena = *this, .me = unit, .tmpl = tmpl, .info = info, .target = target, .spec = *spec, .tick = tick,
        .delay_ticks = delay_ticks};
    handler->apply(run, hits);
}

bool Arena::cast_borrowed(Fighter& unit, std::uint32_t skill, const Target& target) {
    if (borrow_depth_ > 0 || !unit.alive()) return false;
    const SkillTemplate* tmpl = catalog_->skill(skill);
    if (tmpl == nullptr) return false;
    std::uint8_t level_number = 0;
    const SkillLevel* data = nullptr;
    for (std::size_t n = kInnerArtSlots; n >= 1 && data == nullptr; --n) {
        data = catalog_->level_of(skill, static_cast<std::uint8_t>(n));
        if (data != nullptr) level_number = static_cast<std::uint8_t>(n);
    }
    if (data == nullptr) return false;
    const detail::SkillHandler* handler = skill_handler(data->logic);
    const LogicSpec* spec = catalog_->skill_logic(data->logic);
    if (handler == nullptr || spec == nullptr || handler->passive()) return false;
    const CastInfo info = instance(*tmpl, *data, level_number);
    detail::SkillRun run{.arena = *this, .me = unit, .tmpl = *tmpl, .info = info, .target = target, .spec = *spec};
    if (handler->on_start(run) != CastOutcome::kOk) return false;
    ++borrow_depth_;
    activate(unit, *tmpl, info, target, false, ms_to_ticks(tmpl->delay_ms));
    --borrow_depth_;
    return true;
}

// ---------------------------------------------------------------------------------------------------------
// Hành động kéo dài

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tổng thời gian rồi chu kỳ, cả hai nơi gọi đều nêu tên (HP-07)
void Arena::start_action(Fighter& unit, ActionState::Phase phase, const CastInfo& info, const Target& target, std::int64_t duration,
    std::int64_t interval) {
    ActionState& action = unit.action;
    action = ActionState{};
    action.phase = phase;
    action.info = info;
    action.target = target;
    action.remaining = duration;
    action.charge_total = duration;
    action.interval = interval;
    ++unit.logic_count;
    action.logic_count = unit.logic_count;
    run_on_action_started(unit);
}

void Arena::finish_action(Fighter& unit) {
    if (unit.action.phase == ActionState::Phase::kIdle) return;
    const std::uint32_t skill = unit.action.info.skill;
    unit.action = ActionState{};
    emit(EventKind::kCastFinished, unit.handle, unit.handle, skill);
}

bool Arena::interrupt_action(Fighter& unit) {
    if (unit.action.phase == ActionState::Phase::kIdle) return false;
    const CastInfo info = unit.action.info;
    const Target target = unit.action.target;
    unit.action = ActionState{};
    const SkillTemplate* tmpl = catalog_->skill(info.skill);
    const detail::SkillHandler* handler = skill_handler(info.logic);
    const LogicSpec* spec = catalog_->skill_logic(info.logic);
    if (tmpl != nullptr && handler != nullptr && spec != nullptr) {
        detail::SkillRun run{.arena = *this, .me = unit, .tmpl = *tmpl, .info = info, .target = target, .spec = *spec};
        handler->on_interrupt(run);
    }
    emit(EventKind::kCastInterrupted, unit.handle, unit.handle, info.skill);
    return true;
}

void Arena::disturb_action(Fighter& unit) {
    ActionState& action = unit.action;
    if (action.phase == ActionState::Phase::kIdle || unit.aggregates.ignore_disturb) return;
    const SkillTemplate* tmpl = catalog_->skill(action.info.skill);
    if (tmpl == nullptr) return;
    // Khác gốc: bản 2008 không có xác suất gián đoạn; cột 2026 `disrupt_chance` quyết định có bị đánh lùi lần này không.
    if (roll100() >= tmpl->disrupt_chance) return;
    if (action.phase == ActionState::Phase::kCharging) {
        // Đẩy lùi gom khí: cộng thêm thời gian đã gom, tối đa 500 ms (và tối đa tỉ lệ `disrupt_time` của tổng thời gian gom
        // nếu cột ấy có giá trị); không bao giờ vượt tổng thời gian gom.
        std::int64_t cap = ms_to_ticks(kMaxDisturbChargeMs);
        if (tmpl->disrupt_time_permille > 0) cap = std::min(cap, (action.charge_total * tmpl->disrupt_time_permille + 999) / 1000);
        const std::int64_t gathered = action.charge_total - action.remaining;
        action.remaining += std::min(gathered, cap);
    } else {
        // Dẫn khí: mất một nhịp; hết thời gian dẫn thì ngắt (ChannelAction OnDisturbForChanneling).
        action.remaining -= std::min(action.interval, action.remaining);
        if (action.remaining <= 0) interrupt_action(unit);
    }
}

bool Arena::run_activation(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target, bool recheck) {
    if (recheck) {
        if (check_terms(unit, info, target) != CastOutcome::kOk) return false;
        if (check_target(unit, tmpl, info, target, false) != CastOutcome::kOk) return false;
    }
    CastInfo working = info;
    if (!deplete(unit, working)) return false;
    run_on_use_skill(unit, working);
    ++unit.logic_count;
    run_on_action_started(unit);

    std::int64_t action_ms = tmpl.action_time_ms;
    if (tmpl.id == kMeleeAttackSkill) {
        if (const actor::MonsterRow* row = monster_row_of(unit)) action_ms = row->attack_animation_ms;
    }
    action_ms = std::max<std::int64_t>(action_ms, kMinActionTimeMs);
    unit.action_lock_until = ids::advance(now_, ids::TickSpan{ms_to_ticks(action_ms)});
    apply_cooldown(unit, tmpl, working);

    const std::int32_t times = std::clamp(tmpl.charges_or_interval, 1, kMaxActivations);
    const std::int64_t delay = ms_to_ticks(tmpl.delay_ms);
    for (std::int32_t k = 1; k <= times; ++k) {
        // Mỗi lần phát sau trễ thêm một khoảng `delay` (bản gốc cộng dồn DelayTime qua các lần phát).
        activate(unit, tmpl, working, target, false, delay * k);
        if (!unit.alive()) break;
    }
    emit(EventKind::kCastFinished, unit.handle, unit.handle, tmpl.id);
    return true;
}

CastOutcome Arena::begin_instant(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target) {
    emit(EventKind::kCastStarted, unit.handle, target.unit, tmpl.id, 0, info.level, target.position);
    if (!run_activation(unit, tmpl, info, target, false)) return CastOutcome::kConditionFailed;
    return CastOutcome::kOk;
}

CastOutcome Arena::begin_charge(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target) {
    if (info.charge_ms <= 0) return begin_instant(unit, tmpl, info, target);
    emit(EventKind::kCastStarted, unit.handle, target.unit, tmpl.id, 1, info.level, target.position);
    start_action(unit, ActionState::Phase::kCharging, info, target, ms_to_ticks(info.charge_ms), 0);
    unit.action_lock_until = ids::advance(now_, ids::TickSpan{ms_to_ticks(kMinActionTimeMs)});
    return CastOutcome::kOk;
}

CastOutcome Arena::begin_channel(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target) {
    if (info.channel_ms <= 0) return CastOutcome::kConditionFailed;
    // ChannelAction: thời gian hoặc chu kỳ dưới 500 ms là dữ liệu sai, bản gốc thay bằng 2000 ms.
    const std::int32_t total_ms = info.channel_ms < kMinChannelMs ? kDefaultChannelIntervalMs : info.channel_ms;
    std::int32_t interval_ms = tmpl.charges_or_interval;
    if (interval_ms < kMinChannelMs) interval_ms = kDefaultChannelIntervalMs;
    CastInfo working = info;
    if (!deplete(unit, working)) return CastOutcome::kConditionFailed;
    run_on_use_skill(unit, working);
    emit(EventKind::kCastStarted, unit.handle, target.unit, tmpl.id, 2, info.level, target.position);
    start_action(unit, ActionState::Phase::kChanneling, working, target, ms_to_ticks(total_ms), ms_to_ticks(interval_ms));
    unit.action_lock_until = ids::advance(now_, ids::TickSpan{ms_to_ticks(kMinActionTimeMs)});
    apply_cooldown(unit, tmpl, working);
    activate(unit, tmpl, working, target, false, 0);
    return CastOutcome::kOk;
}

void Arena::action_heartbeat(Fighter& unit) {
    ActionState& action = unit.action;
    if (action.phase == ActionState::Phase::kIdle) return;
    const SkillTemplate* tmpl = catalog_->skill(action.info.skill);
    if (!unit.alive() || tmpl == nullptr || !can_use_in_status(unit, *tmpl)) {
        interrupt_action(unit);
        return;
    }
    if (action.phase == ActionState::Phase::kCharging) {
        action.remaining -= 1;
        if (action.remaining > 0) return;
        // Gom xong: kiểm lại điều kiện, tiêu hao rồi phát như chiêu tức thời (bản gốc: Action_ActivateOnceHandler).
        const CastInfo info = action.info;
        const Target target = action.target;
        unit.action = ActionState{};
        if (!run_activation(unit, *tmpl, info, target, true)) {
            emit(EventKind::kCastInterrupted, unit.handle, unit.handle, info.skill);
        }
        return;
    }
    action.interval_elapsed += 1;
    action.remaining -= 1;
    while (unit.action.phase == ActionState::Phase::kChanneling && unit.action.interval_elapsed >= unit.action.interval) {
        unit.action.interval_elapsed -= unit.action.interval;
        const CastInfo info = unit.action.info;
        const Target target = unit.action.target;
        if (check_target(unit, *tmpl, info, target, true) != CastOutcome::kOk) {
            interrupt_action(unit);
            return;
        }
        activate(unit, *tmpl, info, target, true, ms_to_ticks(tmpl->delay_ms));
    }
    if (unit.action.phase == ActionState::Phase::kChanneling && unit.action.remaining <= 0) finish_action(unit);
}

// ---------------------------------------------------------------------------------------------------------
// Lệnh

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): id kỹ năng và cấp khác vai, nơi gọi nêu tên (HP-07)
CastOutcome Arena::cast(ids::EntityHandle caster, std::uint32_t skill, std::uint8_t level, const Target& target) {
    Fighter* unit = find(caster);
    if (unit == nullptr) return CastOutcome::kNoCaster;
    if (!unit->alive()) return CastOutcome::kDead;
    const SkillTemplate* tmpl = catalog_->skill(skill);
    if (tmpl == nullptr) return CastOutcome::kUnknownSkill;
    if (!can_use_in_status(*unit, *tmpl)) return CastOutcome::kForbidden;

    // Cấp: 0 nghĩa là dùng cấp đã học; kỹ năng chung (không phái, không tâm pháp) luôn cấp 1.
    std::uint8_t use_level = level;
    if (tmpl->sect < 0 && tmpl->skill_class < 0) {
        use_level = 1;
    } else if (use_level == 0) {
        for (const SkillEntry& entry : unit->skills) {
            if (entry.id == skill) use_level = entry.level;
        }
        if (use_level == 0) use_level = 1;
    }
    if (!skill_known(*unit, *tmpl, use_level)) return CastOutcome::kNotLearned;
    if (!cooldown_ready(*unit, *tmpl)) return CastOutcome::kCooldown;
    if (busy(*unit)) return CastOutcome::kBusy;

    const SkillLevel* data = catalog_->level_of(skill, use_level);
    if (data == nullptr) return CastOutcome::kUnknownSkill;
    CastInfo info = instance(*tmpl, *data, use_level);
    run_refix_skill(*unit, info);
    const detail::SkillHandler* handler = skill_handler(info.logic);
    const LogicSpec* spec = catalog_->skill_logic(info.logic);
    if (handler == nullptr || spec == nullptr) return CastOutcome::kUnsupported;
    if (handler->passive() || tmpl->type == SkillType::kPassive) return CastOutcome::kForbidden;
    if (tmpl->must_use_weapon && unit->kind == FighterKind::kHuman && unit->weapon_type < 0) return CastOutcome::kNoWeapon;

    if (const CastOutcome terms = check_terms(*unit, info, target); terms != CastOutcome::kOk) return terms;
    if (const CastOutcome checked = check_target(*unit, *tmpl, info, target, false); checked != CastOutcome::kOk) return checked;
    detail::SkillRun run{.arena = *this, .me = *unit, .tmpl = *tmpl, .info = info, .target = target, .spec = *spec};
    if (const CastOutcome started = handler->on_start(run); started != CastOutcome::kOk) return started;

    switch (tmpl->type) {
    case SkillType::kInstant: return begin_instant(*unit, *tmpl, info, target);
    case SkillType::kCharge: return begin_charge(*unit, *tmpl, info, target);
    case SkillType::kChannel: return begin_channel(*unit, *tmpl, info, target);
    case SkillType::kPassive: break;
    }
    return CastOutcome::kForbidden;
}

bool Arena::cancel_cast(ids::EntityHandle caster) {
    Fighter* unit = find(caster);
    if (unit == nullptr || unit->action.phase == ActionState::Phase::kIdle) return false;
    return interrupt_action(*unit);
}

bool Arena::interrupt(ids::EntityHandle unit_handle) {
    Fighter* unit = find(unit_handle);
    return unit != nullptr && interrupt_action(*unit);
}

bool Arena::learn(ids::EntityHandle unit_handle, std::uint32_t skill, std::uint8_t level) {
    Fighter* unit = find(unit_handle);
    if (unit == nullptr || level == 0) return false;
    const auto it = std::ranges::lower_bound(unit->skills, skill, {}, &SkillEntry::id);
    if (it != unit->skills.end() && it->id == skill) {
        it->level = level;
        return true;
    }
    if (unit->skills.size() >= kMaxSkills) return false;
    unit->skills.insert(it, SkillEntry{.id = skill, .level = level});
    return true;
}

void Arena::refresh(ids::EntityHandle unit_handle) {
    if (Fighter* unit = find(unit_handle)) refresh_unit(*unit);
}

void Arena::refresh_unit(Fighter& unit) {
    actor::Modifiers passive;
    for (const SkillEntry& entry : unit.skills) {
        const SkillLevel* data = catalog_->level_of(entry.id, entry.level);
        if (data == nullptr) continue;
        const detail::SkillHandler* handler = skill_handler(data->logic);
        const LogicSpec* spec = catalog_->skill_logic(data->logic);
        if (handler == nullptr || spec == nullptr || !handler->passive()) continue;
        handler->contribute_passive(unit, *data, *spec, passive);
    }
    unit.passive_modifiers = passive;
    recompute(unit);
}

} // namespace game::combat
