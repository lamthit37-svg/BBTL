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

Playing Gait::update(Clock::time_point now, bool is_moving, const ClipLengths& lengths) {
    enter(now, is_moving);
    if (stance_ == Stance::kRun) return running(now, lengths);
    if (elapsed(now) >= length_of(stance_, lengths)) fresh(now, lengths);
    return Playing{.stance = stance_, .time = elapsed(now)};
}

// Đổi trạng thái theo chuyển động: bắt đầu đi thì phát clip chạy từ đầu, dừng (hay lần đầu) thì
// Start_Idle.
void Gait::enter(Clock::time_point now, bool is_moving) {
    const bool was_running = is_started_ && stance_ == Stance::kRun;
    const bool starts_run = is_moving && !was_running;
    if (starts_run) clip_started_ = now;
    if (starts_run) stance_ = Stance::kRun;
    const bool stops = !is_moving && (!is_started_ || was_running);
    if (stops) start_idle(now);
    is_started_ = true;
}

// Clip chạy lặp; không có clip chạy thì đứng ở đầu clip.
Playing Gait::running(Clock::time_point now, const ClipLengths& lengths) const {
    if (!(lengths.run > 0.0F)) return Playing{.stance = Stance::kRun, .time = 0.0F};
    return Playing{.stance = Stance::kRun, .time = anim::loop_time(elapsed(now), lengths.run)};
}

// Start_Idle: clip đứng, mốc động tác nghỉ là lúc này, khoảng mới.
void Gait::start_idle(Clock::time_point now) {
    stance_ = Stance::kIdle;
    clip_started_ = now;
    last_motion_ = now;
    interval_ = idle_interval(random_(), idle_ms_);
}

// FreshAnimation khi clip đứng hay động tác nghỉ vừa hết: rand() % 2 là 0 thì N_IDLE_EX0, 1 thì
// N_IDLE_EX1; động tác đã chọn không có clip thì phát clip đứng.
void Gait::fresh(Clock::time_point now, const ClipLengths& lengths) {
    clip_started_ = now;
    stance_ = Stance::kIdle;
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
    }
    return lengths.idle;
}

} // namespace game::avatar
