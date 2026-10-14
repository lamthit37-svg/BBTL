// Mã logic kỹ năng: mã xử lý theo vai (standard, dash), kỹ năng bị động chỉnh trang bị (passive_armor, passive_weapon) và
// logic chưa có mã (unsupported). Arena làm phần chung của một lượt ra chiêu; ở đây chỉ quyết định hiệu ứng nào đi
// tới ai (xem skills.hpp).
//
// Nguồn: GameServer 2008 SkillLogic.cpp, ImpactsToTarget.cpp, ImpactsToTargetAndSelf.cpp, GaiBangSkill001.cpp,
// ArmorMastery.cpp, WeaponMastery.cpp. Khác gốc ghi tại chỗ.
#include "combat/detail/skills.hpp"

#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/numeric.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/detail/effects_impl.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <span>
#include <string_view>

namespace game::combat {
namespace detail {

CastOutcome SkillHandler::on_start(SkillRun& /*run*/) const { return CastOutcome::kOk; }

void SkillHandler::on_interrupt(SkillRun& /*run*/) const {}

void SkillHandler::contribute_passive(const Fighter& /*me*/, const SkillLevel& /*level*/, const LogicSpec& /*spec*/,
    actor::Modifiers& /*out*/) const {}

namespace {

using actor::saturate32;

constexpr std::int32_t kMaxRepeat = 16;  // trần số lần lặp một hiệu ứng trong một lượt (dữ liệu sai không được lặp vô hạn)

[[nodiscard]] std::int32_t param_at(const CastInfo& info, std::int8_t index) noexcept {
    return index < 0 || static_cast<std::size_t>(index) >= info.param.size() ? 0 : info.param.at(static_cast<std::size_t>(index));
}

// Hiệu ứng sát thương công thức (damage_attack): chỉ loại này nhận cường hóa uy lực của kỹ năng và tính từ chỉ số hai
// bên (bản gốc: `DI_DamagesByValue_T::ID == Impact_GetLogicID(impact)`).
[[nodiscard]] bool is_attack_damage(const Arena& arena, std::uint32_t effect_id) {
    const Effect* effect = arena.catalog().effect(effect_id);
    const LogicSpec* spec = effect == nullptr ? nullptr : arena.catalog().effect_logic(effect->logic);
    return spec != nullptr && spec->handler == "damage_attack";
}

// Đoạn liên kích theo số điểm đã tiêu: 1..3 đoạn là chỉ số 0..2; không tiêu điểm nào là chỉ số 3 ("không liên kích").
[[nodiscard]] std::int32_t combo_index(std::int32_t spent) noexcept {
    const std::int32_t segments = std::min(spent / kStrikeSegment, kMaxStrikeSegment);
    return segments <= 0 ? kMaxStrikeSegment : segments - 1;
}

[[nodiscard]] bool is_self_side(RoleKind kind) noexcept {
    switch (kind) {
    case RoleKind::kSelf:
    case RoleKind::kSelfTick:
    case RoleKind::kSelfMale:
    case RoleKind::kSelfFemale:
    case RoleKind::kTrap:
    case RoleKind::kTrapTick:
    case RoleKind::kSummon:
    case RoleKind::kTotem:
    case RoleKind::kDispelSelf:
    case RoleKind::kCutCooldown: return true;
    case RoleKind::kTarget:
    case RoleKind::kTargetTick:
    case RoleKind::kFriend:
    case RoleKind::kEnemy:
    case RoleKind::kRank:
    case RoleKind::kRest:
    case RoleKind::kFriendRank:
    case RoleKind::kEnemyRank:
    case RoleKind::kFriendRest:
    case RoleKind::kEnemyRest:
    case RoleKind::kCombo:
    case RoleKind::kSub: return false;
    }
    return false;
}

// Vai kind có tác dụng ở lượt phát này không (một lần hay nhịp dẫn).
[[nodiscard]] bool phase_matches(RoleKind kind, bool tick) noexcept {
    switch (kind) {
    case RoleKind::kTargetTick:
    case RoleKind::kSelfTick:
    case RoleKind::kTrapTick: return tick;
    case RoleKind::kSub: return false;
    default: return !tick;
    }
}

// Vị trí thứ `index` trong dãy các mục tiêu thoả `pick` (đếm từ 0); -1 nếu mục tiêu `at` không thoả.
template <typename Pick>
[[nodiscard]] std::int32_t ordinal(std::span<const Hit> hits, std::size_t at, Pick pick) {
    if (!pick(hits[at])) return -1;
    std::int32_t index = 0;
    for (std::size_t i = 0; i < at; ++i) {
        if (pick(hits[i])) ++index;
    }
    return index;
}

[[nodiscard]] bool target_role_matches(const Role& role, const SkillRun& run, std::span<const Hit> hits, std::size_t at) {
    const auto is_friend = [](const Hit& hit) { return hit.relation == Relation::kFriend; };
    const auto is_enemy = [](const Hit& hit) { return hit.relation == Relation::kEnemy; };
    switch (role.kind) {
    case RoleKind::kTarget:
    case RoleKind::kTargetTick: return true;
    case RoleKind::kFriend: return is_friend(hits[at]);
    case RoleKind::kEnemy: return is_enemy(hits[at]);
    case RoleKind::kRank: return at == role.arg;
    case RoleKind::kRest: return at >= 1;
    case RoleKind::kFriendRank: return ordinal(hits, at, is_friend) == static_cast<std::int32_t>(role.arg);
    case RoleKind::kEnemyRank: return ordinal(hits, at, is_enemy) == static_cast<std::int32_t>(role.arg);
    case RoleKind::kFriendRest: return ordinal(hits, at, is_friend) >= 1;
    case RoleKind::kEnemyRest: return ordinal(hits, at, is_enemy) >= 1;
    case RoleKind::kCombo: return combo_index(run.info.strike_spent) == static_cast<std::int32_t>(role.arg);
    default: return false;
    }
}

// Gửi hiệu ứng của một vai tới `receiver`, qua xác suất (`@`) và số lần lặp (`*`) khai trong vai.
void send_role_effect(SkillRun& run, const Role& role, const Fighter& receiver, bool critical, bool attack_side) {
    const std::int32_t effect_id = param_at(run.info, role.param);
    if (effect_id <= 0) return;  // -1 là ô trống; 0 là dòng sát thương mặc định, không bao giờ được kỹ năng gửi
    const std::int32_t times = role.repeat < 0 ? 1 : std::clamp(param_at(run.info, role.repeat), 0, kMaxRepeat);
    const bool damage = attack_side && is_attack_damage(run.arena, static_cast<std::uint32_t>(effect_id));
    for (std::int32_t i = 0; i < times; ++i) {
        if (role.chance >= 0 && !roll_chance(run.arena, param_at(run.info, role.chance))) continue;
        EffectOrigin origin;
        origin.caster = run.me.handle;
        origin.skill = run.tmpl.id;
        origin.critical = critical;
        origin.computed = damage;
        origin.power_percent = damage ? run.info.power_rate : 0;
        origin.time_percent = run.info.time_rate;
        origin.time_ms = run.info.time_value;
        origin.delay_ticks = run.delay_ticks;
        static_cast<void>(run.arena.send_effect(receiver.handle, static_cast<std::uint32_t>(effect_id), origin));
    }
}

// Vị trí sinh vật đặc biệt: chọn theo điểm thì tại điểm ấy, còn lại dưới chân người ra chiêu.
[[nodiscard]] Position spawn_position(const SkillRun& run) noexcept {
    return run.tmpl.select == SelectType::kPosition ? run.target.position : run.me.position;
}

void emit_spawn(SkillRun& run, const Role& role, SpawnKind kind) {
    const std::int32_t data_id = param_at(run.info, role.param);
    if (data_id <= 0) return;
    if (role.chance >= 0 && !roll_chance(run.arena, param_at(run.info, role.chance))) return;
    run.arena.emit(EventKind::kSpawn, run.me.handle, run.target.unit, static_cast<std::uint32_t>(data_id),
        static_cast<std::int32_t>(kind), static_cast<std::int32_t>(run.tmpl.id), spawn_position(run));
}

void apply_self_role(SkillRun& run, const Role& role) {
    Fighter& me = run.me;
    switch (role.kind) {
    case RoleKind::kSelfMale:
        if (me.female) return;
        send_role_effect(run, role, me, false, false);
        break;
    case RoleKind::kSelfFemale:
        if (!me.female) return;
        send_role_effect(run, role, me, false, false);
        break;
    case RoleKind::kSelf:
    case RoleKind::kSelfTick: send_role_effect(run, role, me, false, false); break;
    case RoleKind::kTrap:
    case RoleKind::kTrapTick: emit_spawn(run, role, SpawnKind::kTrap); break;
    case RoleKind::kSummon: emit_spawn(run, role, SpawnKind::kSummon); break;
    case RoleKind::kTotem: emit_spawn(run, role, SpawnKind::kTotem); break;
    case RoleKind::kDispelSelf: {
        const std::int32_t collection = param_at(run.info, role.param);
        if (collection != kInvalidId) static_cast<void>(run.arena.dispel_collection(me, collection, std::numeric_limits<std::int32_t>::max(), 0));
        break;
    }
    case RoleKind::kCutCooldown: {
        // Giảm hồi chiêu của một nhóm đi `aux` mili giây (không âm).
        const std::int32_t group = param_at(run.info, role.param);
        const std::int64_t cut = ms_to_ticks(std::max(0, param_at(run.info, role.aux)));
        const std::int64_t remaining = group < 0 ? 0 : run.arena.cooldown_remaining(me, group);
        if (remaining > 0 && cut > 0) {
            run.arena.set_cooldown(me, group, std::max<std::int64_t>(0, remaining - cut));
            if (run.arena.cooldown_remaining(me, group) == 0) {
                run.arena.emit(EventKind::kCooldownCleared, me.handle, me.handle, static_cast<std::uint32_t>(group));
            }
        }
        break;
    }
    default: break;
    }
}

// Mã xử lý chuẩn: mọi việc do cột `roles` của bảng quyết định (xem catalog.hpp, RoleKind). Với mỗi mục tiêu bị trúng,
// theo thứ tự quét, gửi các hiệu ứng thuộc vai phía mục tiêu; sau cùng gửi các hiệu ứng phía bản thân một lần.
// Khác gốc: bản 2008 gửi hiệu ứng bản thân lặp theo từng mục tiêu (ImpactsToTargetAndSelf); ở đây một lần cho mỗi lượt phát
// có ít nhất một mục tiêu bị trúng, để buff bản thân không chồng theo số mục tiêu.
class StandardSkill : public SkillHandler {
public:
    void apply(SkillRun& run, std::span<const Hit> hits) const override {
        for (std::size_t at = 0; at < hits.size(); ++at) {
            const Fighter* target = run.arena.find(hits[at].unit);
            if (target == nullptr) continue;
            for (const Role& role : run.spec.roles) {
                if (is_self_side(role.kind) || !phase_matches(role.kind, run.tick)) continue;
                if (target_role_matches(role, run, hits, at)) send_role_effect(run, role, *target, hits[at].critical, true);
            }
        }
        if (hits.empty()) return;
        for (const Role& role : run.spec.roles) {
            if (is_self_side(role.kind) && phase_matches(role.kind, run.tick)) apply_self_role(run, role);
        }
    }
};

// Kỹ năng lướt (khinh công): chạy các vai như standard rồi dời người ra chiêu tới điểm chọn, kẹp trong tầm xa của kỹ
// năng. Vị trí do lõi đặt; nơi gọi nhận sự kiện kMove để đồng bộ và kiểm đường đi (lõi không biết địa hình).
class DashSkill final : public StandardSkill {
public:
    void apply(SkillRun& run, std::span<const Hit> hits) const override {
        StandardSkill::apply(run, hits);
        if (run.tick || !run.me.alive()) return;
        const Position from = run.me.position;
        Position to = run.tmpl.select == SelectType::kPosition ? run.target.position : from;
        if (run.tmpl.select != SelectType::kPosition) {
            if (const Fighter* other = run.arena.find(run.target.unit)) to = other->position;
        }
        const std::int64_t range = run.tmpl.range_cm;
        const std::int64_t dist_sq = distance_sq_cm(from, to);
        if (range > 0 && dist_sq > range * range) {
            const std::int64_t dist = std::llround(std::sqrt(static_cast<double>(dist_sq)));
            to.x_cm = static_cast<std::int32_t>(from.x_cm + ((static_cast<std::int64_t>(to.x_cm) - from.x_cm) * range / dist));
            to.z_cm = static_cast<std::int32_t>(from.z_cm + ((static_cast<std::int64_t>(to.z_cm) - from.z_cm) * range / dist));
        }
        run.me.position = to;
        run.arena.emit(EventKind::kMove, run.me.handle, run.me.handle, run.tmpl.id, 0, 0, to);
    }
};

// Kỹ năng bị động chỉnh điểm gốc phòng ngự của giáp (logic 8): tham số 0 là % điểm phòng thủ ngoại gốc, 1 là nội.
class PassiveArmor final : public SkillHandler {
public:
    [[nodiscard]] bool passive() const noexcept override { return true; }

    void apply(SkillRun& /*run*/, std::span<const Hit> /*hits*/) const override {}

    void contribute_passive(const Fighter& /*me*/, const SkillLevel& level, const LogicSpec& /*spec*/,
        actor::Modifiers& out) const override {
        out.equip_rate[actor::Stat::kDefencePhy] = saturate32(static_cast<std::int64_t>(out.equip_rate[actor::Stat::kDefencePhy]) + level.param.at(0));
        out.equip_rate[actor::Stat::kDefenceMagic] = saturate32(static_cast<std::int64_t>(out.equip_rate[actor::Stat::kDefenceMagic]) + level.param.at(1));
    }
};

// Kỹ năng bị động chỉnh điểm gốc công của vũ khí (logic 9): tham số 0 là % công ngoại gốc, 1 là nội; 2 và 3 là hai
// loại vũ khí được áp dụng.
class PassiveWeapon final : public SkillHandler {
public:
    [[nodiscard]] bool passive() const noexcept override { return true; }

    void apply(SkillRun& /*run*/, std::span<const Hit> /*hits*/) const override {}

    void contribute_passive(const Fighter& me, const SkillLevel& level, const LogicSpec& /*spec*/,
        actor::Modifiers& out) const override {
        if (me.weapon_type < 0 || (me.weapon_type != level.param.at(2) && me.weapon_type != level.param.at(3))) return;
        out.equip_rate[actor::Stat::kAttackPhy] = saturate32(static_cast<std::int64_t>(out.equip_rate[actor::Stat::kAttackPhy]) + level.param.at(0));
        out.equip_rate[actor::Stat::kAttackMagic] = saturate32(static_cast<std::int64_t>(out.equip_rate[actor::Stat::kAttackMagic]) + level.param.at(1));
    }
};

// Hoá khí thức của Mộ Dung (logic 671): phát kỹ năng cùng chiêu thức của môn phái mục tiêu. Tham số 0..14 là id kỹ năng
// theo môn phái (0..9 là phái 0..9; 10..14 là phái 11..15, phái 10 là chính Mộ Dung nên không có ô); ô <= 0 là phái không có
// kỹ năng. Mục tiêu thuộc một phái có ô thì mượn kỹ năng ấy; còn lại (quái, vô phái, Mộ Dung) rút ngẫu nhiên một ô hợp lệ.
// Nguồn: mô tả kỹ năng 2026 ("...对该目标施放其门派的65级技能，...否则随机从十四大门派的65级技能中抽取一个施放"). Khác gốc:
// không có bản 2008; kỹ năng mượn phát ở cấp cao nhất có dữ liệu thay cho cấp 65 vì bảng cấp đánh số theo tâm pháp.
class SectMimic final : public SkillHandler {
public:
    void apply(SkillRun& run, std::span<const Hit> hits) const override {
        if (hits.empty()) return;
        const Fighter* target = run.arena.find(hits.front().unit);
        if (target == nullptr) return;
        std::array<std::uint32_t, 15> pool{};
        std::size_t count = 0;
        for (std::size_t i = 0; i < pool.size(); ++i) {
            const std::int32_t skill = param_at(run.info, static_cast<std::int8_t>(i));
            if (skill > 0) pool.at(count++) = static_cast<std::uint32_t>(skill);
        }
        if (count == 0) return;
        std::uint32_t chosen = 0;
        if (target->kind == FighterKind::kHuman) {
            const std::size_t sect = target->body.sect();
            const std::size_t slot = sect <= 9 ? sect : (sect >= 11 ? sect - 1 : pool.size());
            if (slot < pool.size()) chosen = static_cast<std::uint32_t>(std::max(0, param_at(run.info, static_cast<std::int8_t>(slot))));
        }
        if (chosen == 0) chosen = pool.at(run.arena.roll_below(static_cast<std::uint32_t>(count)));
        static_cast<void>(run.arena.cast_borrowed(run.me, chosen, run.target));
    }
};

// Logic chưa có mã: từ chối ra chiêu và báo cho nơi gọi. Không tính vào độ phủ.
class UnsupportedSkill final : public SkillHandler {
public:
    [[nodiscard]] CastOutcome on_start(SkillRun& run) const override {
        run.arena.emit(EventKind::kUnsupported, run.me.handle, run.target.unit, run.tmpl.id,
            static_cast<std::int32_t>(UnsupportedReason::kUnknownLogic));
        return CastOutcome::kUnsupported;
    }

    void apply(SkillRun& /*run*/, std::span<const Hit> /*hits*/) const override {}
};

struct Entry {
    std::string_view name;
    const SkillHandler* handler;
};

} // namespace

const SkillHandler* find_skill_handler(std::string_view name) noexcept {
    static const StandardSkill kStandard;
    static const DashSkill kDash;
    static const PassiveArmor kArmor;
    static const PassiveWeapon kWeapon;
    static const SectMimic kMimic;
    static const UnsupportedSkill kUnsupported;
    static const std::array<Entry, 6> kTable = {
        Entry{.name = "standard", .handler = &kStandard}, Entry{.name = "dash", .handler = &kDash},
        Entry{.name = "passive_armor", .handler = &kArmor}, Entry{.name = "passive_weapon", .handler = &kWeapon},
        Entry{.name = "sect_mimic", .handler = &kMimic}, Entry{.name = "unsupported", .handler = &kUnsupported},
    };
    for (const Entry& entry : kTable) {
        if (entry.name == name) return entry.handler;
    }
    return nullptr;
}

} // namespace detail

bool known_skill_handler(std::string_view name) noexcept { return detail::find_skill_handler(name) != nullptr; }

} // namespace game::combat
