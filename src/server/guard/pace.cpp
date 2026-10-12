#include "guard/pace.hpp"

#include <cmath>

namespace game::guard {
namespace {

constexpr float kRunCmPerSec = 465.0F;
constexpr float kTickSeconds = 1.0F / 30.0F;
constexpr float kSlack = 1.05F;
constexpr float kSlackCm = 5.0F;
constexpr float kTeleportMinCm = 1600.0F;
constexpr std::uint32_t kTeleportSustain = 2;
constexpr std::uint32_t kSpeedSustain = 3;

struct Bound {
    float distance_cm = 0;
    float limit_cm = 0;
    bool over_speed = false;
    bool over_teleport = false;
};

[[nodiscard]] Bound measure(Step step, float from_x, float from_z, std::uint32_t from_tick) noexcept {
    Bound bound;
    const float dx = step.x_cm - from_x;
    const float dz = step.z_cm - from_z;
    bound.distance_cm = std::sqrt(dx * dx + dz * dz);
    const float seconds = static_cast<float>(step.tick - from_tick) * kTickSeconds;
    bound.limit_cm = kRunCmPerSec * seconds * kSlack + kSlackCm;
    bound.over_speed = bound.distance_cm > bound.limit_cm;
    const float teleport_floor = bound.limit_cm * 4.0F;
    const float floor_cm = teleport_floor > kTeleportMinCm ? teleport_floor : kTeleportMinCm;
    bound.over_teleport = bound.distance_cm > floor_cm;
    return bound;
}

} // namespace

void Pace::reset() noexcept {
    has_step_ = false;
    speed_streak_ = 0;
    teleport_streak_ = 0;
}

Verdict Pace::observe(Step step) noexcept {
    if (!has_step_ || step.tick <= tick_) {
        has_step_ = true;
        x_cm_ = step.x_cm;
        z_cm_ = step.z_cm;
        tick_ = step.tick;
        return Verdict::kOk;
    }
    const Bound bound = measure(step, x_cm_, z_cm_, tick_);
    if (bound.over_speed) ++speed_streak_;
    if (!bound.over_speed) speed_streak_ = 0;
    if (bound.over_teleport) ++teleport_streak_;
    if (!bound.over_teleport) teleport_streak_ = 0;
    Verdict verdict = Verdict::kOk;
    if (speed_streak_ >= kSpeedSustain) verdict = Verdict::kSpeed;
    if (teleport_streak_ >= kTeleportSustain) verdict = Verdict::kTeleport;
    if (verdict != Verdict::kOk) return verdict;
    x_cm_ = step.x_cm;
    z_cm_ = step.z_cm;
    tick_ = step.tick;
    return Verdict::kOk;
}

} // namespace game::guard
