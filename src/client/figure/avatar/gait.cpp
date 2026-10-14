// Chọn clip của một nhân vật; luật và nguồn ở gait.hpp. Thứ tự hai lần rand() khi tới lượt động
// tác nghỉ giữ như FreshAnimation: rút khoảng mới trước, rồi mới chọn động tác.
// Nguồn: TLBB Dev src/client_app/gait.cpp@e0d89a6. Khác gốc: namespace game::avatar; core::Clock;
// loop_time của anim/pose; enumerator mang tiền tố k.
#include "avatar/gait.hpp"

#include "anim/pose.hpp"
#include "core/clock.hpp"

#include <chrono>
#include <cstdint>

namespace game::avatar {

using core::Clock;

// (UINT)((FLOAT)interval * ((FLOAT)(64 - rand() % 16)) / 64.f). Nhánh UINT_MAX của ref (không có
// mẫu) không có ở đây: bảng không ghi được khoảng âm.
std::chrono::milliseconds idle_interval(unsigned roll, std::chrono::milliseconds interval) {
    const auto base = static_cast<float>(interval.count());
    const float scaled = base * static_cast<float>(64 - (roll % 16)) / 64.0F;
    return std::chrono::milliseconds{static_cast<std::uint32_t>(scaled)};
}

Gait::Gait(std::uint32_t seed, std::chrono::milliseconds interval) : random_(seed), idle_ms_(interval) {}

void Gait::cue(Stance stance) noexcept {
    cued_ = stance;
}

void Gait::set_fidget(bool enabled) noexcept {
    fidget_ = enabled;
}

void Gait::take_cue(Clock::time_point now) {
    if (!cued_ || is_moving_ || is_jumping_) return;
    stance_ = *cued_;
    clip_started_ = now;
    cued_.reset();
}

Playing Gait::update(Clock::time_point now, bool is_moving, const ClipLengths& lengths) {
    enter(now, is_moving);
    take_cue(now);
    const bool is_jump_clip = stance_ == Stance::kJumpStand || stance_ == Stance::kJumpRun;
    if (is_jump_clip && elapsed(now) >= length_of(stance_, lengths)) fresh_logic(now, lengths);
    if (stance_ == Stance::kJumpStand || stance_ == Stance::kJumpRun) {
        return Playing{.stance = stance_, .time = elapsed(now)};
    }
    if (stance_ == Stance::kRun) return running(now, lengths);
    if (elapsed(now) >= length_of(stance_, lengths)) fresh(now, lengths);
    return Playing{.stance = stance_, .time = elapsed(now)};
}

// Đổi logic theo chuyển động: bắt đầu đi thì Start_Move (clip chạy từ đầu), dừng (hay lần đầu) thì
// Start_Idle. Đang nhảy thì cả hai giữ clip nhảy.
void Gait::enter(Clock::time_point now, bool is_moving) {
    const bool was_moving = is_started_ && is_moving_;
    const bool starts_run = is_moving && !was_moving;
    const bool stops = !is_moving && (!is_started_ || was_moving);
    is_moving_ = is_moving;
    is_started_ = true;
    if (starts_run && !is_jumping_) {
        stance_ = Stance::kRun;
        clip_started_ = now;
    }
    if (stops) start_idle(now);
}

void Gait::jump(Clock::time_point now, Stance stance, const ClipLengths& lengths) {
    const bool is_stand = stance == Stance::kJumpStand;
    if (!is_stand && stance != Stance::kJumpRun) return;
    is_jumping_ = true;
    const bool has_clip = is_stand ? lengths.jump_stand.has_value() : lengths.jump_run.has_value();
    if (!has_clip) return;
    stance_ = stance;
    clip_started_ = now;
}

void Gait::land(Clock::time_point now, const ClipLengths& lengths) {
    if (!is_jumping_) return;
    is_jumping_ = false;
    fresh_logic(now, lengths);
}

// FreshAnimation theo logic: MOVE thì ChangeAction(N_RUN, ..., TRUE) phát chạy lại từ đầu, IDLE thì
// như lúc hết clip đứng.
void Gait::fresh_logic(Clock::time_point now, const ClipLengths& lengths) {
    if (!is_moving_) {
        fresh(now, lengths);
        return;
    }
    stance_ = Stance::kRun;
    clip_started_ = now;
}

// Clip chạy lặp; không có clip chạy thì đứng ở đầu clip.
Playing Gait::running(Clock::time_point now, const ClipLengths& lengths) const {
    if (!(lengths.run > 0.0F)) return Playing{.stance = Stance::kRun, .time = 0.0F};
    return Playing{.stance = Stance::kRun, .time = anim::loop_time(elapsed(now), lengths.run)};
}

// Start_Idle: clip đứng (trừ khi đang nhảy), mốc động tác nghỉ là lúc này, khoảng mới.
void Gait::start_idle(Clock::time_point now) {
    if (!is_jumping_) {
        stance_ = Stance::kIdle;
        clip_started_ = now;
    }
    last_motion_ = now;
    interval_ = idle_interval(random_(), idle_ms_);
}

// FreshAnimation khi clip đứng hay động tác nghỉ vừa hết: rand() % 2 là 0 thì N_IDLE_EX0, 1 thì
// N_IDLE_EX1; động tác đã chọn không có clip thì phát clip đứng.
void Gait::fresh(Clock::time_point now, const ClipLengths& lengths) {
    clip_started_ = now;
    stance_ = Stance::kIdle;
    if (!fidget_) return;
    const bool is_due = last_motion_ + interval_ < now;
    if (!is_due) return;
    last_motion_ = now;
    interval_ = idle_interval(random_(), idle_ms_);
    const bool picks_first = random_() % 2U == 0;
    const bool has_clip = picks_first ? lengths.idle_alt.has_value() : lengths.idle_alt2.has_value();
    if (has_clip) stance_ = picks_first ? Stance::kIdleAlt : Stance::kIdleAlt2;
}

float Gait::elapsed(Clock::time_point now) const {
    return std::chrono::duration<float>(now - clip_started_).count();
}

float Gait::length_of(Stance stance, const ClipLengths& lengths) {
    switch (stance) {
    case Stance::kIdle: return lengths.idle;
    case Stance::kIdleAlt: return lengths.idle_alt.value_or(lengths.idle);
    case Stance::kIdleAlt2: return lengths.idle_alt2.value_or(lengths.idle);
    case Stance::kRun: return lengths.run;
    case Stance::kJumpStand: return lengths.jump_stand.value_or(lengths.idle);
    case Stance::kJumpRun: return lengths.jump_run.value_or(lengths.idle);
    }
    return lengths.idle;
}

} // namespace game::avatar
