/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/fight/combat.cpp
 *  PHÂN HỆ   : Client / Fight / Combat
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt Combat: bảng kỹ năng và hồi chiêu, mục tiêu, đánh tự động, chiêu
 *    chờ xác nhận, số bay.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/fight/combat.hpp"

#include "client/cast/note.hpp"
#include "ui/panel/talk.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <optional>
#include <vector>

namespace game::client::fight {
namespace {

namespace tk = ui::panel::talk;

// Số thứ tự chiêu không bao giờ là 0: 0 trong SkillCast nghĩa là chiêu của người khác.
[[nodiscard]] std::uint16_t after(std::uint16_t seq) noexcept {
    return seq == UINT16_MAX ? std::uint16_t{1} : static_cast<std::uint16_t>(seq + 1U);
}

[[nodiscard]] bool is_fatal(tk::Decline why) noexcept {
    switch (why) {
    case tk::Decline::kNotLearned:
    case tk::Decline::kNotEnoughMana:
    case tk::Decline::kNotEnoughRage:
    case tk::Decline::kBadTarget:
    case tk::Decline::kCannotAttack:
    case tk::Decline::kGone:
    case tk::Decline::kDead: return true;
    case tk::Decline::kCooldown:
    case tk::Decline::kOutOfRange:
    case tk::Decline::kNotDead:
    case tk::Decline::kNotYours:
    case tk::Decline::kBusy:
    case tk::Decline::kOther: return false;
    }
    return false;
}

} // namespace

void Combat::leave() noexcept {
    target_.reset();
    is_engaged_ = false;
    pending_.reset();
    retry_at_ = Time{};
    reach_ = kReach;
    floats_.clear();
}

Combat::Known* Combat::find(std::uint16_t skill) noexcept {
    const auto found = std::ranges::find(known_, skill, &Known::skill);
    return found == known_.end() ? nullptr : &*found;
}

const Combat::Known* Combat::find(std::uint16_t skill) const noexcept {
    const auto found = std::ranges::find(known_, skill, &Known::skill);
    return found == known_.end() ? nullptr : &*found;
}

void Combat::learn(const tk::Skills& list, Time now) {
    known_.clear();
    known_.reserve(std::min(list.learned.size(), kMaxKnown));
    for (const tk::Learned& entry : list.learned) {
        if (known_.size() >= kMaxKnown) break;
        if (find(entry.skill) != nullptr) continue;
        known_.push_back(Known{.skill = entry.skill, .level = entry.level, .ready_at = now + std::chrono::milliseconds{entry.cooldown_ms}});
    }
}

void Combat::cool(const tk::Cooldown& cooldown, Time now) {
    if (Known* known = find(cooldown.skill)) known->ready_at = now + std::chrono::milliseconds{cooldown.ms};
}

void Combat::vitals(const tk::Vitals& vitals) noexcept {
    // Trần bằng 0 là máy chủ chưa tính chỉ số: không đọc thành "đã chết".
    const bool is_down = vitals.hp_max > 0 && vitals.hp <= 0;
    if (is_down) {
        is_dead_ = true;
        is_engaged_ = false;
        return;
    }
    if (vitals.hp > 0) {
        is_dead_ = false;
        loss_.reset();
    }
}

void Combat::slain(const tk::Slain& notice) noexcept {
    is_dead_ = true;
    is_engaged_ = false;
    pending_.reset();
    loss_ = notice;
}

void Combat::declined(tk::Decline why, Time now) {
    pending_.reset();
    retry_at_ = now + kRetry;
    if (why == tk::Decline::kDead) {
        is_dead_ = true;
        is_engaged_ = false;
    }
    if (why == tk::Decline::kGone) target_.reset();
    if (why == tk::Decline::kOutOfRange) reach_ = std::max(kMinReach, std::min(reach_, last_distance_) - kReachStep);
    if (is_fatal(why)) is_engaged_ = false;
}

bool Combat::confirm(std::uint16_t seq) noexcept {
    if (seq == 0 || !pending_ || pending_->seq != seq) return false;
    pending_.reset();
    reach_ = kReach;
    return true;
}

void Combat::strike(const cast::Struck& blow, Time due) {
    if (floats_.size() >= kMaxFloats) floats_.erase(floats_.begin());
    floats_.push_back(Float{.target = blow.target, .kind = blow.kind, .value = blow.value, .is_critical = blow.is_critical, .due = due});
}

void Combat::died(const cast::Died& note, std::uint32_t self_id) noexcept {
    if (note.id == self_id) {
        is_dead_ = true;
        is_engaged_ = false;
        pending_.reset();
    }
    vanished(note.id);
}

void Combat::vanished(std::uint32_t id) noexcept {
    if (target_ != id) return;
    target_.reset();
    is_engaged_ = false;
}

void Combat::aim(std::uint32_t id) noexcept {
    if (target_ == id) return;
    target_ = id;
    is_engaged_ = false;
    reach_ = kReach;
}

void Combat::engage(std::uint32_t id) noexcept {
    aim(id);
    is_engaged_ = !is_dead_;
}

void Combat::clear_target() noexcept {
    target_.reset();
    is_engaged_ = false;
}

std::optional<tk::Cast> Combat::cast(std::uint16_t skill, Time now, Aim where) noexcept {
    if (is_dead_ || now < retry_at_) return std::nullopt;
    if (pending_ && now - pending_->sent < kCastWait) return std::nullopt;
    if (const Known* known = find(skill); known != nullptr && known->ready_at > now) return std::nullopt;
    const std::uint16_t seq = next_seq_;
    next_seq_ = after(next_seq_);
    pending_ = Pending{.seq = seq, .sent = now};
    return tk::Cast{.seq = seq, .skill = skill, .target = where.target, .x = where.x, .z = where.z};
}

Pursuit Combat::pursue(Time now, std::optional<float> distance, bool is_busy) noexcept {
    if (!is_engaged_ || !target_) return {};
    if (is_dead_ || !distance || !std::isfinite(*distance)) {
        clear_target();
        return {};
    }
    last_distance_ = *distance;
    if (*distance > reach_) return Pursuit{.is_approaching = true, .order = std::nullopt};
    if (is_busy) return {};
    return Pursuit{.is_approaching = false, .order = cast(basic(), now, Aim{.target = *target_})};
}

void Combat::expire(Time now) {
    std::erase_if(floats_, [now](const Float& shown) { return now > shown.due + kFloatLife; });
}

std::vector<std::uint32_t> Combat::learned() const {
    std::vector<std::uint32_t> ids;
    ids.reserve(known_.size());
    for (const Known& known : known_) ids.push_back(known.skill);
    return ids;
}

std::uint16_t Combat::basic() const noexcept {
    return known_.empty() ? std::uint16_t{0} : known_.front().skill;
}

std::chrono::milliseconds Combat::cooldown_left(std::uint16_t skill, Time now) const noexcept {
    const Known* known = find(skill);
    if (known == nullptr || known->ready_at <= now) return std::chrono::milliseconds{0};
    return std::chrono::duration_cast<std::chrono::milliseconds>(known->ready_at - now);
}

} // namespace game::client::fight
