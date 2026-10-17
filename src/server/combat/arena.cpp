/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/combat/arena.cpp
 *  PHÂN HỆ   : Server / Combat / Arena
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Sổ thực thể, nhịp tick, hàng đợi sự kiện, quan hệ phe, lưu và khôi phục
 *    của Arena (xem arena.hpp).
 *  - Nguồn: GameServer 2008 Obj_Character.cpp (HeartBeat),
 *    Obj_Character_Impact.cpp (lưu/nạp danh sách buff).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "combat/arena.hpp"

#include "actor/body.hpp"
#include "combat/catalog.hpp"
#include "combat/detail/effects.hpp"
#include "combat/detail/skills.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <span>
#include <utility>
#include <vector>

namespace game::combat {
namespace {

// Bảng tra logic -> mã xử lý: mảng phẳng đủ lớn cho số logic cao nhất có trong bảng (đã chặn ở kMaxLogicId).
template <typename Handler, typename Finder>
[[nodiscard]] std::vector<const Handler*> build_table(std::span<const LogicSpec> specs, Finder find_handler) {
    std::int32_t highest = -1;
    for (const LogicSpec& spec : specs) highest = std::max(highest, spec.logic);
    std::vector<const Handler*> table(highest < 0 ? 0 : static_cast<std::size_t>(highest) + 1U, nullptr);
    for (const LogicSpec& spec : specs) {
        if (spec.logic < 0) continue;
        table.at(static_cast<std::size_t>(spec.logic)) = find_handler(spec.handler);
    }
    return table;
}

[[nodiscard]] std::uint32_t clamp_u32(std::int64_t value) noexcept {
    constexpr std::int64_t kU32Max = std::numeric_limits<std::uint32_t>::max();
    const std::int64_t capped = std::clamp(value, std::int64_t{0}, kU32Max);
    return static_cast<std::uint32_t>(capped);
}

[[nodiscard]] std::int64_t saved_rate(std::int64_t hz) noexcept {
    if (hz == 20) return hz;
    if (hz == 30) return hz;
    if (hz == 40) return hz;
    return kTicksPerSecond;
}

void retick_forever(std::int64_t& elapsed, std::int64_t from, std::int64_t to) noexcept {
    elapsed = ids::rescale_ticks_up(elapsed, from, to);
}

void retick_finite(std::int64_t& continuance, std::int64_t& elapsed, std::int64_t from,
    std::int64_t to) noexcept {
    const std::int64_t left = continuance - elapsed;
    const std::int64_t done = ids::rescale_ticks_down(elapsed, from, to);
    const std::int64_t remain = ids::rescale_ticks_up(left, from, to);
    elapsed = done;
    continuance = done + remain;
}

void retick_buff(std::int64_t& continuance, std::int64_t& elapsed, std::int64_t from,
    std::int64_t to) noexcept {
    if (from == to) return;
    if (continuance < 0) retick_forever(elapsed, from, to);
    if (continuance < 0) return;
    retick_finite(continuance, elapsed, from, to);
}

[[nodiscard]] bool has_cooldown(const std::vector<Cooldown>& cooldowns, std::int32_t id) noexcept {
    for (const Cooldown& cooldown : cooldowns)
        if (cooldown.id == id) return true;
    return false;
}

void keep_cooldown(std::vector<Cooldown>& cooldowns, const SavedCooldown& saved, std::int64_t from,
    std::int64_t to, ids::Tick now) {
    if (saved.remaining_ticks == 0) return;
    if (cooldowns.size() >= kMaxCooldowns) return;
    if (has_cooldown(cooldowns, saved.id)) return;
    const std::int64_t raw = static_cast<std::int64_t>(saved.remaining_ticks);
    const std::int64_t left = ids::rescale_ticks_up(raw, from, to);
    Cooldown cooled;
    cooled.id = saved.id;
    cooled.until = ids::advance(now, ids::TickSpan{left});
    cooldowns.push_back(cooled);
}

[[nodiscard]] std::vector<const detail::EffectLogic*> effect_rows(const Catalog& catalog) {
    const std::span<const LogicSpec> specs = catalog.effect_logics();
    return build_table<detail::EffectLogic>(specs, detail::find_effect_handler);
}

[[nodiscard]] std::vector<const detail::SkillHandler*> skill_rows(const Catalog& catalog) {
    const std::span<const LogicSpec> specs = catalog.skill_logics();
    return build_table<detail::SkillHandler>(specs, detail::find_skill_handler);
}

} // namespace

Arena::Arena(const Catalog& catalog, dice::Dice& dice, ArenaLimits limits, std::int64_t hz)
    : catalog_(&catalog), dice_(&dice), limits_(limits), hz_(hz) {
    effect_table_ = effect_rows(catalog);
    skill_table_ = skill_rows(catalog);
}

Arena::~Arena() = default;

// ---------------------------------------------------------------------------------------------------------
// Sổ thực thể

std::expected<void, ArenaError> Arena::add(Fighter&& fighter) {
    if (fighter.handle.generation == 0) return std::unexpected(ArenaError::kInvalid);  // thế hệ 0 là "không có thực thể"
    if (fighters_.size() >= limits_.max_fighters) return std::unexpected(ArenaError::kFull);
    const ids::EntityHandle handle = fighter.handle;
    const auto [it, inserted] = fighters_.try_emplace(handle, std::move(fighter));
    if (!inserted) return std::unexpected(ArenaError::kDuplicate);
    refresh_unit(it->second);
    return {};
}

bool Arena::remove(ids::EntityHandle handle) {
    if (fighters_.erase(handle) == 0) return false;
    // Hiệu ứng chưa giao tới người đã đi thì bỏ luôn để khỏi chiếm chỗ hàng đợi.
    std::erase_if(pending_, [handle](const auto& entry) { return entry.second.receiver == handle; });
    return true;
}

Fighter* Arena::find(ids::EntityHandle handle) noexcept {
    const auto it = fighters_.find(handle);
    return it == fighters_.end() ? nullptr : &it->second;
}

const Fighter* Arena::find(ids::EntityHandle handle) const noexcept {
    const auto it = fighters_.find(handle);
    return it == fighters_.end() ? nullptr : &it->second;
}

std::vector<ids::EntityHandle> Arena::handles() const {
    std::vector<ids::EntityHandle> out;
    out.reserve(fighters_.size());
    for (const auto& entry : fighters_) out.push_back(entry.first);
    return out;
}

// ---------------------------------------------------------------------------------------------------------
// Sự kiện và quan hệ

void Arena::emit(EventKind kind, ids::EntityHandle actor, ids::EntityHandle target, std::uint32_t id, std::int32_t value,
    std::int32_t extra, Position where) {
    if (events_.size() >= limits_.max_events) {
        ++dropped_events_;  // nơi gọi không rút sự kiện kịp: đếm số bị rơi thay vì phình bộ nhớ
        return;
    }
    events_.push_back(Event{.kind = kind, .tick = now_, .actor = actor, .target = target, .id = id, .value = value,
        .extra = extra, .where = where});
}

Relation Arena::relation(const Fighter& from, const Fighter& to) const {
    if (&from == &to) return Relation::kFriend;
    if (relation_policy_) return relation_policy_(from, to);
    return catalog_->camp_relation(from.body.camp(), to.body.camp());
}

// ---------------------------------------------------------------------------------------------------------
// Nhịp

void Arena::heartbeat(Fighter& unit) {
    buff_heartbeat(unit);
    action_heartbeat(unit);
    if (unit.alive()) {
        // Hồi tự nhiên theo nhịp RECOVER_INTERVAL của thân thể; sự kiện chỉ phát khi giá trị thật sự đổi.
        const std::uint64_t step = now_.value();
        const std::int64_t elapsed = ids::slice_ms(step, hz_);
        const std::int32_t hp = unit.body.hp();
        const std::int32_t mp = unit.body.mp();
        unit.body.advance(elapsed);
        if (unit.body.hp() != hp) emit(EventKind::kHealed, unit.handle, unit.handle, 0, unit.body.hp() - hp);
        if (unit.body.mp() != mp) emit(EventKind::kManaChanged, unit.handle, unit.handle, 0, unit.body.mp() - mp);
    }
    std::erase_if(unit.cooldowns, [this](const Cooldown& cooldown) { return cooldown.until.value() <= now_.value(); });
}

void Arena::tick() {
    now_ = ids::advance(now_, ids::TickSpan{1});
    for (auto& entry : fighters_) heartbeat(entry.second);
    deliver_due();
}

// ---------------------------------------------------------------------------------------------------------
// Lưu và khôi phục

CombatRecord Arena::snapshot(const Fighter& unit) const {
    CombatRecord record;
    record.hz = hz_;
    record.skills = unit.skills;
    for (const Cooldown& cooldown : unit.cooldowns) {
        const std::int64_t remaining = cooldown_remaining(unit, cooldown.id);
        if (remaining > 0) record.cooldowns.push_back(SavedCooldown{.id = cooldown.id, .remaining_ticks = clamp_u32(remaining)});
    }
    std::ranges::sort(record.cooldowns, {}, &SavedCooldown::id);  // dạng chuẩn cho bộ mã hoá
    for (std::size_t i = 0; i < unit.buff_count; ++i) {
        const Buff& buff = unit.buffs.at(i);
        if (buff.fade_out) continue;
        const Resolved r = resolve(buff);
        // Hiệu ứng mất khỏi bảng, hiệu ứng tức thời và buff tan khi ngoại tuyến thì không lưu.
        if (!r || !r.effect->over_timed || r.effect->fade_on_offline) continue;
        SavedBuff saved;
        saved.effect = buff.effect;
        saved.skill = buff.skill;
        saved.caster_character = buff.caster_character;
        saved.by_player = buff.by_player;
        saved.critical = buff.critical;
        saved.continuance = buff.continuance;
        saved.elapsed = buff.elapsed;
        saved.refix = buff.refix;
        saved.slot = buff.slot;
        record.buffs.push_back(saved);
    }
    return record;
}

void Arena::restore(Fighter& unit, const CombatRecord& record, std::int64_t offline_ticks) {
    // Sổ kỹ năng: sắp theo id, bỏ cấp 0 và id lặp, cắt ở trần (bản ghi đã qua bộ giải mã nhưng hàm này cũng gọi từ test).
    unit.skills.clear();
    for (const SkillEntry& entry : record.skills) {
        if (entry.level != 0) unit.skills.push_back(entry);
    }
    std::ranges::stable_sort(unit.skills, {}, &SkillEntry::id);
    const auto dup = std::ranges::unique(unit.skills, {}, &SkillEntry::id);
    unit.skills.erase(dup.begin(), dup.end());
    if (unit.skills.size() > kMaxSkills) unit.skills.resize(kMaxSkills);

    unit.cooldowns.clear();
    const std::int64_t from = saved_rate(record.hz);
    for (const SavedCooldown& saved : record.cooldowns)
        keep_cooldown(unit.cooldowns, saved, from, hz_, now_);

    // Buff: đặt thẳng vào danh sách, không chạy on_active (hiệu ứng một lần như hồi máu đã xảy ra trước khi lưu; trạng
    // thái còn lại nằm trong `slot`).
    unit.buffs = {};
    unit.buff_count = 0;
    unit.sn_seed = 0;
    for (const SavedBuff& saved : record.buffs) {
        if (unit.buff_count >= kMaxBuffs) break;
        const Effect* effect = catalog_->effect(saved.effect);
        if (effect == nullptr || !effect->over_timed || effect_handler(effect->logic) == nullptr) continue;
        Buff buff;
        buff.effect = saved.effect;
        buff.skill = saved.skill;
        buff.caster_character = saved.caster_character;
        buff.by_player = saved.by_player;
        buff.critical = saved.critical;
        std::int64_t continuance = saved.continuance;
        std::int64_t elapsed = saved.elapsed;
        retick_buff(continuance, elapsed, from, hz_);
        buff.continuance = continuance;
        buff.elapsed = elapsed;
        buff.refix = saved.refix;
        buff.slot = saved.slot;
        const bool count_offline = effect->timing_offline && buff.continuance >= 0;
        if (count_offline) buff.elapsed = elapsed + std::max<std::int64_t>(0, offline_ticks);
        if (buff.continuance >= 0 && buff.elapsed >= buff.continuance) continue;  // hết hạn trong lúc ngoại tuyến
        buff.sn = next_sn(unit);
        unit.buffs.at(unit.buff_count) = buff;
        ++unit.buff_count;
    }
    refresh_unit(unit);
}

} // namespace game::combat
