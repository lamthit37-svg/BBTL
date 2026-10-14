// Chuỗi sát thương, hồi phục, chết và hồi sinh của Arena (xem arena.hpp).
//
// Nguồn: GameServer 2008 Obj_Character_Event.cpp (OnDamages, OnDamage, OnDamageTarget, OnDie, OnHealTarget),
// Obj_Character_Skill.cpp (HealthIncrement, ManaIncrement, RageIncrement, StrikePointIncrement).
#include "combat/arena.hpp"

#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/numeric.hpp"
#include "actor/rules.hpp"
#include "combat/damage.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace game::combat {
namespace {

using actor::Stat;
using actor::saturate32;

} // namespace

AttackerView Arena::attacker_view(const Fighter& unit) const {
    const actor::Body& body = unit.body;
    AttackerView view;
    view.attack_phy = body.stat(Stat::kAttackPhy);
    view.attack_magic = body.stat(Stat::kAttackMagic);
    view.attack_element[Element::kCold] = body.stat(Stat::kAttackCold);
    view.attack_element[Element::kFire] = body.stat(Stat::kAttackFire);
    view.attack_element[Element::kLight] = body.stat(Stat::kAttackLight);
    view.attack_element[Element::kPoison] = body.stat(Stat::kAttackPoison);
    view.resist_reduce = unit.aggregates.resist_reduce;
    if (const actor::MonsterRow* row = body.monster_row()) {
        // Quái mang sẵn phần giảm kháng trong dòng bảng quái (cùng thứ tự lạnh, lửa, điện, độc).
        const std::array<Element, kElementCount> order{Element::kCold, Element::kFire, Element::kLight, Element::kPoison};
        for (std::size_t i = 0; i < order.size(); ++i) {
            view.resist_reduce[order.at(i)] = saturate32(static_cast<std::int64_t>(view.resist_reduce[order.at(i)]) + row->resist_reduce.at(i));
        }
    }
    view.hit = body.stat(Stat::kHit);
    view.critical = body.stat(Stat::kCritical);
    view.fluctuation = body.fluctuation();
    return view;
}

DefenderView Arena::defender_view(const Fighter& unit) const {
    const actor::Body& body = unit.body;
    DefenderView view;
    view.defence_phy = body.stat(Stat::kDefencePhy);
    view.defence_magic = body.stat(Stat::kDefenceMagic);
    view.resist_element[Element::kCold] = body.stat(Stat::kResistCold);
    view.resist_element[Element::kFire] = body.stat(Stat::kResistFire);
    view.resist_element[Element::kLight] = body.stat(Stat::kResistLight);
    view.resist_element[Element::kPoison] = body.stat(Stat::kResistPoison);
    view.miss = body.stat(Stat::kMiss);
    view.immunity_phy = body.immunity_phy();
    view.immunity_magic = body.immunity_magic();
    return view;
}

// ---------------------------------------------------------------------------------------------------------
// HP / MP / nộ khí / liên kích

actor::HpChange Arena::change_hp(Fighter& unit, ids::EntityHandle source, std::int64_t delta, bool critical) {
    if (!unit.alive()) return {};
    if (delta >= 0) {
        const actor::HpChange change = unit.body.change_hp(delta);
        if (delta > 0) emit(EventKind::kHealed, source, unit.handle, 0, saturate32(delta));
        return change;
    }
    // Mất máu làm gián đoạn gom khí/dẫn; hồi máu hay sát thương đã bị khiên hấp thụ hết (delta == 0) thì không.
    disturb_action(unit);
    const actor::HpChange change = unit.body.change_hp(delta);
    emit(EventKind::kDamaged, source, unit.handle, 0, saturate32(-delta), critical ? 1 : 0);
    if (change.died) handle_death(unit, source);
    return change;
}

std::int32_t Arena::change_mp(Fighter& unit, ids::EntityHandle source, std::int64_t delta) {
    const std::int32_t applied = unit.body.change_mp(delta);
    if (applied != 0) emit(EventKind::kManaChanged, source, unit.handle, 0, applied);
    return applied;
}

std::int32_t Arena::change_rage(Fighter& unit, ids::EntityHandle source, std::int64_t delta) {
    if (!unit.body.is_human()) return 0;  // chỉ người có nộ khí (bản gốc: OBJ_TYPE_HUMAN)
    const std::int32_t applied = unit.body.change_rage(delta);
    if (applied != 0) emit(EventKind::kRageChanged, source, unit.handle, 0, applied);
    return applied;
}

std::int32_t Arena::change_strike(Fighter& unit, ids::EntityHandle source, std::int64_t delta) {
    if (!unit.body.is_human()) return 0;
    const std::int32_t applied = unit.body.change_strike(delta);
    if (applied != 0) emit(EventKind::kStrikeChanged, source, unit.handle, 0, applied);
    return applied;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): lượng hồi và id kỹ năng khác nghĩa, nơi gọi nêu tên (HP-07)
void Arena::heal(Fighter& unit, ids::EntityHandle healer_handle, std::int32_t amount, std::uint32_t skill) {
    static_cast<void>(skill);
    if (!unit.alive()) return;
    Fighter* healer = find(healer_handle);
    if (healer != nullptr) run_on_be_heal(unit, *healer, amount);
    change_hp(unit, healer_handle, amount);
    if (healer == nullptr) return;
    run_on_heal_target(*healer, unit, amount);
    const std::int32_t gained = healer->body.gain_rage(actor::RageTrigger::kHealDone, amount);
    if (gained != 0) emit(EventKind::kRageChanged, healer->handle, healer->handle, 0, gained);
}

// ---------------------------------------------------------------------------------------------------------
// Chuỗi sát thương

void Arena::deal(Fighter& unit, ids::EntityHandle attacker_handle, std::int32_t damage, bool critical, std::uint32_t skill) {
    Fighter* attacker = find(attacker_handle);
    // Sát thương tối thiểu 1 (bản gốc: `0 >= nDamage ? nDamage = 1`), rồi hook tổng của người chịu (khiên, giảm thương).
    if (damage <= 0) damage = 1;
    run_on_damage(unit, attacker, damage, skill);
    if (attacker != nullptr) {
        // Người đánh nhận nộ khí theo sát thương đã qua khiên, rồi hook OnDamageTarget (hút máu, khuếch đại...).
        const std::int32_t gained = attacker->body.gain_rage(actor::RageTrigger::kDealDamage, damage);
        if (gained != 0) emit(EventKind::kRageChanged, attacker->handle, attacker->handle, 0, gained);
        // Khác gốc: bản 2008 truyền sát thương cho OnDamageTarget theo giá trị nên hook chỉ đọc; dữ liệu 2026 có hiệu ứng
        // khuếch đại sát thương gây ra (logic 81, 88) nên con số sau hook là con số trừ vào máu.
        run_on_damage_target(*attacker, unit, damage, skill);
        damage = std::max(damage, 0);
    }
    change_hp(unit, attacker_handle, -static_cast<std::int64_t>(damage), critical);
    // Nộ khí người bị đánh (bản gốc: MenPai_OnDamage sau HealthIncrement; người đã chết thì Body không cộng nữa).
    const std::int32_t gained = unit.body.gain_rage(actor::RageTrigger::kDamaged, damage);
    if (gained != 0) emit(EventKind::kRageChanged, attacker_handle, unit.handle, 0, gained);
}

void Arena::damage_channels(Fighter& unit, ids::EntityHandle attacker_handle, ChannelDamage amounts, std::int32_t fixed,
    bool critical, std::uint32_t skill) {
    if (!unit.alive()) return;
    Fighter* attacker = find(attacker_handle);
    // Hook theo kênh (khiên chặn riêng ngoại/nội/băng...), rồi cộng sáu kênh và phần sát thương thẳng.
    run_on_damages(unit, attacker, amounts, skill);
    const std::int64_t sum = total(amounts) + static_cast<std::int64_t>(fixed);
    deal(unit, attacker_handle, saturate32(sum), critical, skill);
}

void Arena::damage_flat(Fighter& unit, ids::EntityHandle attacker_handle, std::int32_t amount, bool critical, std::uint32_t skill) {
    if (!unit.alive()) return;
    deal(unit, attacker_handle, amount, critical, skill);
}

// ---------------------------------------------------------------------------------------------------------
// Chết và hồi sinh

void Arena::handle_death(Fighter& unit, ids::EntityHandle killer) {
    emit(EventKind::kDied, killer, unit.handle);
    interrupt_action(unit);
    run_on_die(unit);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): nạn nhân rồi kẻ giết, nơi gọi nêu tên (HP-07)
bool Arena::kill(ids::EntityHandle unit_handle, ids::EntityHandle killer) {
    Fighter* unit = find(unit_handle);
    if (unit == nullptr || !unit->alive()) return false;
    change_hp(*unit, killer, -static_cast<std::int64_t>(unit->body.hp()));
    return !unit->alive();
}

bool Arena::revive_fighter(Fighter& unit, const actor::Revival& revival, ids::EntityHandle source) {
    if (unit.alive() || !unit.body.revive(revival)) return false;
    unit.relive.reset();
    recompute(unit);
    emit(EventKind::kRevived, source, unit.handle, 0, unit.body.hp());
    return true;
}

bool Arena::revive(ids::EntityHandle unit_handle, const actor::Revival& revival) {
    Fighter* unit = find(unit_handle);
    return unit != nullptr && revive_fighter(*unit, revival, unit_handle);
}

bool Arena::accept_relive(ids::EntityHandle unit_handle) {
    Fighter* unit = find(unit_handle);
    if (unit == nullptr || unit->alive() || !unit->relive.has_value()) return false;
    return revive_fighter(*unit, unit->relive->revival, unit_handle);
}

} // namespace game::combat
