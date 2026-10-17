/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/combat/arena_buff.cpp
 *  PHÂN HỆ   : Server / Combat / Arena Buff
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Danh sách buff, hàng đợi hiệu ứng và các hook của Arena (xem arena.hpp).
 *  - Nguồn: GameServer 2008 Obj_Character_Impact.cpp (danh sách _IMPACT_LIST,
 *    thay thế loại trừ, gỡ, hook), Impact_Core.cpp (dựng hiệu ứng từ dữ liệu,
 *    tra cứu tập id), ImpactLogic.cpp (nhịp buff).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "combat/arena.hpp"

#include "actor/body.hpp"
#include "actor/numeric.hpp"
#include "actor/rules.hpp"
#include "combat/catalog.hpp"
#include "combat/detail/effects.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>

namespace game::combat {
namespace {

using actor::round_ratio;
using actor::saturate32;

// Chỉ số buff có thể đi qua kiểm tra "thay thế": người tạo ra hai buff là một khi cùng loại (người chơi hay
// không) và cùng định danh.
[[nodiscard]] bool same_caster(const Buff& a, const Buff& b) noexcept {
    if (a.by_player != b.by_player) return false;
    return a.by_player ? a.caster_character == b.caster_character : a.caster == b.caster;
}

} // namespace

const detail::EffectLogic* Arena::effect_handler(std::int32_t logic) const noexcept {
    if (logic < 0) return nullptr;
    const auto index = static_cast<std::size_t>(logic);
    return index < effect_table_.size() ? effect_table_[index] : nullptr;
}

Arena::Resolved Arena::resolve(const Buff& buff) const noexcept {
    Resolved out;
    out.effect = catalog_->effect(buff.effect);
    if (out.effect == nullptr) return out;
    out.spec = catalog_->effect_logic(out.effect->logic);
    out.logic = effect_handler(out.effect->logic);
    if (out.spec == nullptr || out.logic == nullptr) {
        out.logic = nullptr;
        return out;
    }
    return out;
}

template <typename Fn>
void Arena::for_each_buff(Fighter& unit, const Fn& fn) {
    // Buff thêm vào trong lúc duyệt được duyệt luôn (bản gốc đọc lại số đếm mỗi vòng); buff chỉ bị gỡ khỏi mảng ở
    // cleanup_faded nên chỉ số không xê dịch giữa chừng.
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        Buff& buff = unit.buffs.at(i);
        const Resolved r = resolve(buff);
        if (!r) {
            fade_out(unit, buff);
            continue;
        }
        if (buff.fade_out || !r.effect->over_timed) continue;
        detail::HookCtx ctx{.arena = *this, .me = unit, .buff = buff, .effect = *r.effect, .spec = *r.spec};
        fn(*r.logic, ctx);
    }
}

// ---------------------------------------------------------------------------------------------------------
// Tra cứu tập id

bool Arena::buff_in_collection(const Buff& buff, std::int32_t collection) const {
    const Collection* set = catalog_->collection(collection);
    if (set == nullptr || set->ids.empty()) return false;
    const Effect* effect = catalog_->effect(buff.effect);
    if (effect == nullptr) return false;
    std::int32_t id = kInvalidId;
    if (set->is_buff_kind()) {
        if (effect->over_timed) id = effect->impact_id;
    } else {
        switch (static_cast<CollectionKind>(set->kind)) {
        case CollectionKind::kMutex: id = effect->mutex_id; break;
        case CollectionKind::kLogic: id = effect->logic; break;
        case CollectionKind::kSkill: id = static_cast<std::int32_t>(buff.skill); break;
        case CollectionKind::kDirect:
            if (effect->over_timed) id = effect->impact_id;
            break;
        default: break;
        }
    }
    return id != kInvalidId && set->contains(id);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): id kỹ năng rồi id tập, hai kiểu có dấu khác nhau, nơi gọi nêu tên (HP-07)
bool Arena::skill_in_collection(std::uint32_t skill, std::int32_t collection) const {
    const Collection* set = catalog_->collection(collection);
    if (set == nullptr || set->ids.empty()) return false;
    if (set->kind != static_cast<std::int32_t>(CollectionKind::kSkill)) return false;
    return set->contains(static_cast<std::int32_t>(skill));
}

const Buff* Arena::first_buff_in_collection(const Fighter& unit, std::int32_t collection) const {
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        const Buff& buff = unit.buffs.at(i);
        if (!buff.fade_out && buff_in_collection(buff, collection)) return &buff;
    }
    return nullptr;
}

// ---------------------------------------------------------------------------------------------------------
// Gỡ buff

void Arena::fade_out(Fighter& unit, Buff& buff) {
    if (buff.fade_out) return;
    buff.fade_out = true;  // đánh dấu trước, như bản gốc, để hook không gọi lại chính nó
    const Resolved r = resolve(buff);
    if (!r) return;
    detail::HookCtx ctx{.arena = *this, .me = unit, .buff = buff, .effect = *r.effect, .spec = *r.spec};
    r.logic->on_fade_out(ctx);
    if (!r.effect->over_timed) return;
    recompute(unit);
    emit(EventKind::kBuffRemoved, buff.caster, unit.handle, buff.effect, 0, buff.sn);
    if (r.effect->needs_channel) {
        // Buff do dẫn khí duy trì: tan thì ngắt đòn dẫn đã sinh ra nó (nếu người dẫn vẫn đang dẫn đúng kỹ năng ấy).
        Fighter* caster = find(buff.caster);
        if (caster != nullptr && caster->action.phase == ActionState::Phase::kChanneling && caster->action.info.skill == buff.skill) {
            interrupt_action(*caster);
        }
    }
}

std::int32_t Arena::dispel_where(Fighter& unit, const BuffMatcher& matcher, std::int32_t count, bool require_dispellable) {
    std::int32_t dispelled = 0;
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        if (count > 0 && dispelled >= count) break;
        Buff& buff = unit.buffs.at(i);
        const Resolved r = resolve(buff);
        if (!r) {
            fade_out(unit, buff);
            continue;
        }
        if (!r.effect->over_timed || buff.fade_out) continue;
        if (require_dispellable && !r.effect->dispellable) continue;
        if (!matcher(buff, *r.effect)) continue;
        fade_out(unit, buff);
        ++dispelled;
    }
    return dispelled;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tập, cấp tối đa, số lượng khác nghĩa, nơi gọi nêu tên (HP-07)
std::int32_t Arena::dispel_collection(Fighter& unit, std::int32_t collection, std::int32_t level, std::int32_t count) {
    return dispel_where(
        unit, [this, collection, level](const Buff& buff, const Effect& effect) {
            return effect.level <= level && buff_in_collection(buff, collection);
        },
        count, true);
}

void Arena::cancel_collection(Fighter& unit, std::int32_t collection) {
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        Buff& buff = unit.buffs.at(i);
        const Resolved r = resolve(buff);
        if (!r || buff.fade_out) continue;
        if (r.effect->cancellable && buff_in_collection(buff, collection)) fade_out(unit, buff);
    }
}

void Arena::cleanup_faded(Fighter& unit) {
    for (std::size_t i = unit.buff_count; i-- > 0;) {
        if (!unit.buffs.at(i).fade_out) continue;
        const std::size_t last = unit.buff_count - 1;
        if (i < last) unit.buffs.at(i) = unit.buffs.at(last);
        unit.buffs.at(last) = Buff{};
        --unit.buff_count;
    }
}

// ---------------------------------------------------------------------------------------------------------
// Thêm / thay buff

void Arena::recompute(Fighter& unit) {
    actor::Modifiers mods = unit.passive_modifiers;
    Aggregates agg;
    std::uint8_t claimed = 0;
    detail::Contribution out{.mods = mods, .agg = agg, .claimed = claimed};
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        const Buff& buff = unit.buffs.at(i);
        if (buff.fade_out) continue;
        const Resolved r = resolve(buff);
        if (!r || !r.effect->over_timed) continue;
        r.logic->contribute(*this, unit, buff, *r.effect, out);
    }
    unit.aggregates = std::move(agg);
    unit.body.set_buffs(mods);
}

void Arena::activate_impact(Fighter& unit, Buff& buff) {
    const Resolved r = resolve(buff);
    if (!r) return;
    detail::HookCtx ctx{.arena = *this, .me = unit, .buff = buff, .effect = *r.effect, .spec = *r.spec};
    r.logic->on_active(ctx);
    if (r.effect->over_timed) {
        recompute(unit);
        emit(EventKind::kBuffAdded, buff.caster, unit.handle, buff.effect, saturate32(buff.continuance), buff.sn);
    } else {
        emit(EventKind::kImpact, buff.caster, unit.handle, buff.effect, buff.critical ? 1 : 0);
    }
}

void Arena::replace_slot(Fighter& unit, Buff& dest, Buff src) {
    src.sn = next_sn(unit);
    fade_out(unit, dest);
    dest = src;  // Buff là kiểu sao chép tầm thường: di chuyển cũng là sao chép
    activate_impact(unit, dest);
}

std::int32_t Arena::next_sn(Fighter& unit) noexcept {
    // Số thứ tự buff chỉ cần khác nhau trong danh sách của một người; quấn về 1 khi tràn thay vì tràn số có dấu.
    unit.sn_seed = unit.sn_seed >= kMaxSn ? 1 : unit.sn_seed + 1;
    return unit.sn_seed;
}

bool Arena::replace_mutex(Fighter& unit, Buff impact) {
    const Resolved incoming = resolve(impact);
    if (!incoming || incoming.effect->mutex_id == kInvalidId) return false;
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        Buff& current = unit.buffs.at(i);
        const Resolved r = resolve(current);
        if (!r) {
            fade_out(unit, current);
            continue;
        }
        if (current.fade_out || !r.effect->over_timed) continue;
        if (r.effect->mutex_id != incoming.effect->mutex_id) continue;
        // Loại trừ theo người tạo: chỉ khi cả hai cùng đánh dấu mới tách theo người; khác người thì không loại trừ nhau.
        if (incoming.effect->mutex_by_caster && r.effect->mutex_by_caster && !same_caster(impact, current)) continue;
        const bool lower_level = impact.skill != 0 && current.skill != 0 && impact.skill == current.skill &&
            incoming.effect->level < r.effect->level;
        if (!lower_level) {
            replace_slot(unit, current, impact);
        } else {
            emit(EventKind::kBuffRefused, impact.caster, unit.handle, impact.effect, static_cast<std::int32_t>(MissKind::kImmune));
        }
        return true;
    }
    return false;
}

void Arena::replace_last_good(Fighter& unit, Buff impact) {
    // Khác gốc: bản 2008 duyệt `for (i = count-1; 0 <= i; ++i)` (tăng mà bắt đầu từ cuối nên chạy ra ngoài mảng); ở đây
    // duyệt giảm, từ buff mới nhất về cũ nhất, đúng ý định của mã.
    for (std::size_t i = unit.buff_count; i-- > 0;) {
        Buff& current = unit.buffs.at(i);
        const Resolved r = resolve(current);
        if (!r) {
            fade_out(unit, current);
            continue;
        }
        if (current.fade_out || !r.effect->over_timed) continue;
        if (r.effect->stand != kStandHostile && r.effect->dispellable) {
            replace_slot(unit, current, impact);
            return;
        }
    }
}

void Arena::add_new(Fighter& unit, Buff impact) {
    if (unit.buff_count >= kMaxBuffs) {
        replace_last_good(unit, impact);
        return;
    }
    impact.sn = next_sn(unit);
    Buff& slot = unit.buffs.at(unit.buff_count);
    slot = impact;
    ++unit.buff_count;
    activate_impact(unit, slot);
}

void Arena::register_impact(Fighter& unit, const Buff& impact) {
    const Resolved r = resolve(impact);
    if (!r) return;
    if (unit.aggregates.unbreakable && r.effect->stand == kStandHostile) return;
    if (r.effect->over_timed) {
        if (!replace_mutex(unit, impact)) add_new(unit, impact);
        return;
    }
    Buff direct = impact;
    activate_impact(unit, direct);
}

// ---------------------------------------------------------------------------------------------------------
// Gửi và giao hiệu ứng

bool Arena::send_effect(ids::EntityHandle target, std::uint32_t effect_id, const EffectOrigin& origin) {
    Fighter* receiver = find(target);
    if (receiver == nullptr) return false;
    const Effect* effect = catalog_->effect(effect_id);
    if (effect == nullptr) {
        emit(EventKind::kUnsupported, origin.caster, target, effect_id, static_cast<std::int32_t>(UnsupportedReason::kMissingData));
        return false;
    }
    const detail::EffectLogic* logic = effect_handler(effect->logic);
    if (logic == nullptr) {
        emit(EventKind::kUnsupported, origin.caster, target, effect_id, static_cast<std::int32_t>(UnsupportedReason::kUnknownLogic));
        return false;
    }
    if (pending_.size() >= limits_.max_pending) return false;

    Buff impact;
    impact.effect = effect_id;
    impact.skill = origin.skill;
    impact.caster = origin.caster;
    Fighter* caster = find(origin.caster);
    if (caster != nullptr) {
        impact.caster_character = caster->character;
        impact.by_player = caster->kind == FighterKind::kHuman;
    }
    impact.critical = origin.critical;
    std::int64_t continuance_ms = effect->continuance_ms;
    if (continuance_ms > 0 && (origin.time_percent != 0 || origin.time_ms != 0)) {
        continuance_ms = std::max<std::int64_t>(0, round_ratio(continuance_ms * (100 + static_cast<std::int64_t>(origin.time_percent)), 100) + origin.time_ms);
    }
    const bool forever = effect->continuance_ms < 0;
    const std::int64_t steps = milliseconds_to_ticks(continuance_ms);
    impact.continuance = forever ? -1 : steps;
    logic->init(impact, *effect);
    if (origin.power_percent != 0) static_cast<void>(logic->refix_power(impact, *effect, origin.power_percent));
    if (origin.computed && caster != nullptr) logic->compute(*this, *caster, *receiver, impact, *effect);

    const std::uint64_t due = ids::advance(now_, ids::TickSpan{std::max<std::int64_t>(0, origin.delay_ticks)}).value();
    pending_.emplace(PendingKey{.due = due, .seq = pending_seq_++}, Pending{.receiver = target, .impact = impact});
    return true;
}

void Arena::refix_by_sender(Fighter& sender, Buff& impact, const Effect& effect) {
    for_each_buff(sender, [&impact, &effect](const detail::EffectLogic& logic, detail::HookCtx& ctx) {
        logic.refix_impact(ctx, impact, effect);
    });
}

std::optional<MissKind> Arena::filtrate(Fighter& unit, const Buff& incoming) {
    const Resolved in = resolve(incoming);
    if (!in) return std::nullopt;
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        Buff& buff = unit.buffs.at(i);
        const Resolved r = resolve(buff);
        if (!r) {
            fade_out(unit, buff);
            continue;
        }
        if (buff.fade_out || !r.effect->over_timed) continue;
        detail::HookCtx ctx{.arena = *this, .me = unit, .buff = buff, .effect = *r.effect, .spec = *r.spec};
        if (const std::optional<MissKind> verdict = r.logic->filtrate(ctx, incoming, *in.effect)) return verdict;
    }
    for (const SkillFilter& filter : unit.aggregates.filters) {
        if (filter.effect_collection == kInvalidId) continue;
        const bool listed = buff_in_collection(incoming, filter.effect_collection);
        if (filter.allow != listed) return MissKind::kImmune;
    }
    // Quái mang sẵn bộ miễn nhiễm theo loại hiệu ứng: tức thời hay kéo dài (MonsterRow, cột bộ miễn nhiễm).
    if (const actor::MonsterRow* row = unit.body.monster_row()) {
        const std::int32_t set = in.effect->over_timed ? row->duration_immunity_set : row->instant_immunity_set;
        if (set != kInvalidId && buff_in_collection(incoming, set)) return MissKind::kImmune;
    }
    return std::nullopt;
}

void Arena::deliver(const Pending& pending) {
    Fighter* receiver = find(pending.receiver);
    if (receiver == nullptr) return;
    Buff impact = pending.impact;
    const Resolved r = resolve(impact);
    if (!r) return;
    if (!receiver->alive() && !r.effect->keep_on_corpse && !r.logic->works_on_corpse()) return;
    if (impact.critical) r.logic->critical_refix(impact, *r.effect);
    Fighter* sender = find(impact.caster);
    if (sender != nullptr && !r.effect->ignore_filter) refix_by_sender(*sender, impact, *r.effect);
    if (!r.effect->ignore_filter) {
        if (const std::optional<MissKind> miss = filtrate(*receiver, impact)) {
            emit(EventKind::kBuffRefused, impact.caster, receiver->handle, impact.effect, static_cast<std::int32_t>(*miss));
            return;
        }
    }
    register_impact(*receiver, impact);
}

void Arena::deliver_due() {
    // Một hiệu ứng giao trong lúc duyệt có thể xếp thêm hiệu ứng đến hạn ngay (trễ 0): chúng ra hàng sau cùng của
    // lượt này, đúng thứ tự gửi. Trần kMaxPending giữ vòng lặp hữu hạn.
    while (!pending_.empty()) {
        const auto first = pending_.begin();
        if (first->first.due > now_.value()) break;
        const Pending pending = first->second;
        pending_.erase(first);
        deliver(pending);
    }
}

// ---------------------------------------------------------------------------------------------------------
// Nhịp buff

bool Arena::support_still_on(const Fighter& unit, const Buff& buff) const noexcept {
    static_cast<void>(unit);
    const Fighter* caster = find(buff.caster);
    return caster != nullptr && caster->action.phase == ActionState::Phase::kChanneling;
}

void Arena::buff_heartbeat(Fighter& unit) {
    cleanup_faded(unit);
    for (std::size_t i = unit.buff_count; i-- > 0;) {
        if (i >= unit.buff_count) continue;
        Buff& buff = unit.buffs.at(i);
        const Resolved r = resolve(buff);
        if (!r) {
            fade_out(unit, buff);
            continue;
        }
        if (unit.aggregates.unbreakable && r.effect->stand == kStandHostile) {
            fade_out(unit, buff);
            continue;
        }
        if (buff.fade_out || !r.effect->over_timed) continue;
        detail::HookCtx ctx{.arena = *this, .me = unit, .buff = buff, .effect = *r.effect, .spec = *r.spec};
        bool keep = true;
        if (r.effect->needs_channel && !support_still_on(unit, buff)) keep = false;
        if (!unit.alive() && !r.effect->keep_on_corpse) keep = false;
        if (keep && !r.logic->alive_check(ctx)) keep = false;
        if (!keep) {
            fade_out(unit, buff);
            continue;
        }
        if (r.logic->intervaled()) {
            // Khác gốc: chu kỳ 0 (dữ liệu thiếu) bị bỏ qua; bản 2008 lặp vô hạn trong `while (elapsed >= interval)`.
            const std::int64_t interval = milliseconds_to_ticks(r.effect->interval_ms);
            if (interval > 0) {
                buff.interval_elapsed += 1;
                while (buff.interval_elapsed >= interval && !buff.fade_out) {
                    buff.interval_elapsed -= interval;
                    r.logic->on_interval(ctx);
                }
            }
        }
        if (!buff.fade_out && buff.continuance >= 0) {
            // Khác gốc: tan khi đã trôi đủ thời gian (elapsed >= continuance); bản 2008 chờ thêm
            // một nhịp. Số bước là ceil(ms * hz / 1000). Buff 1000 ms là 20 bước ở nhịp nền, không
            // sớm hơn hợp đồng.
            buff.elapsed += 1;
            if (buff.elapsed >= buff.continuance) fade_out(unit, buff);
        }
    }
}

// ---------------------------------------------------------------------------------------------------------
// Hook

void Arena::run_on_damages(Fighter& unit, Fighter* attacker, ChannelDamage& amounts, std::uint32_t skill) {
    for_each_buff(unit, [attacker, &amounts, skill](const detail::EffectLogic& logic, detail::HookCtx& ctx) {
        logic.on_damages(ctx, attacker, amounts, skill);
    });
}

void Arena::run_on_damage(Fighter& unit, Fighter* attacker, std::int32_t& damage, std::uint32_t skill) {
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        Buff& buff = unit.buffs.at(i);
        const Resolved r = resolve(buff);
        if (!r) {
            fade_out(unit, buff);
            continue;
        }
        if (buff.fade_out) continue;
        if (r.effect->fade_on_damage) {
            fade_out(unit, buff);
            continue;
        }
        detail::HookCtx ctx{.arena = *this, .me = unit, .buff = buff, .effect = *r.effect, .spec = *r.spec};
        r.logic->on_damage(ctx, attacker, damage, skill);
    }
}

void Arena::run_on_damage_target(Fighter& unit, Fighter& target, std::int32_t& damage, std::uint32_t skill) {
    for_each_buff(unit, [&target, &damage, skill](const detail::EffectLogic& logic, detail::HookCtx& ctx) {
        logic.on_damage_target(ctx, target, damage, skill);
    });
}

void Arena::run_on_die(Fighter& unit) {
    for_each_buff(unit, [](const detail::EffectLogic& logic, detail::HookCtx& ctx) { logic.on_die(ctx); });
}

void Arena::run_on_be_hit(Fighter& unit, Fighter& attacker) {
    for_each_buff(unit, [&attacker](const detail::EffectLogic& logic, detail::HookCtx& ctx) { logic.on_be_hit(ctx, attacker); });
}

void Arena::run_on_hit_target(Fighter& unit, Fighter& target) {
    for_each_buff(unit, [&target](const detail::EffectLogic& logic, detail::HookCtx& ctx) { logic.on_hit_target(ctx, target); });
}

void Arena::run_on_critical(Fighter& attacker, Fighter& target) {
    for_each_buff(attacker, [&target](const detail::EffectLogic& logic, detail::HookCtx& ctx) {
        logic.on_critical_hit_target(ctx, target);
    });
    for_each_buff(target, [&attacker](const detail::EffectLogic& logic, detail::HookCtx& ctx) {
        logic.on_be_critical_hit(ctx, attacker);
    });
}

void Arena::run_on_heal_target(Fighter& healer, Fighter& target, std::int32_t& healed) {
    for_each_buff(healer, [&target, &healed](const detail::EffectLogic& logic, detail::HookCtx& ctx) {
        logic.on_heal_target(ctx, target, healed);
    });
}

void Arena::run_on_be_heal(Fighter& target, Fighter& healer, std::int32_t& healed) {
    for_each_buff(target, [&healer, &healed](const detail::EffectLogic& logic, detail::HookCtx& ctx) {
        logic.on_be_heal(ctx, healer, healed);
    });
}

void Arena::run_on_action_started(Fighter& unit) {
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        Buff& buff = unit.buffs.at(i);
        const Resolved r = resolve(buff);
        if (!r) {
            fade_out(unit, buff);
            continue;
        }
        if (!buff.fade_out && r.effect->over_timed && r.effect->fade_on_action) fade_out(unit, buff);
    }
}

void Arena::run_on_use_skill(Fighter& unit, CastInfo& info) {
    for_each_buff(unit, [&info](const detail::EffectLogic& logic, detail::HookCtx& ctx) { logic.on_use_skill(ctx, info); });
}

void Arena::run_refix_skill(Fighter& unit, CastInfo& info) {
    for_each_buff(unit, [&info](const detail::EffectLogic& logic, detail::HookCtx& ctx) { logic.refix_skill(ctx, info); });
}

} // namespace game::combat
