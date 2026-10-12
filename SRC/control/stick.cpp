// Cần gạt ảo; luật ghi ở stick.hpp.
#include "control/stick.hpp"

#include "core/ground_point.hpp"

#include <algorithm>
#include <cmath>
#include <numbers>
#include <optional>

namespace game::control {
namespace {

using core::GroundPoint;

[[nodiscard]] float length_of(GroundPoint value) noexcept {
    return std::hypot(value.x, value.z);
}

[[nodiscard]] std::optional<GroundPoint> unit(GroundPoint value) noexcept {
    const float length = length_of(value);
    if (length <= 1e-6F) return std::nullopt;
    return GroundPoint{.x = value.x / length, .z = value.z / length};
}

// Hướng đi trên mặt đất: đẩy lên (y âm) theo forward, đẩy phải theo bên phải của camera. Hệ tay
// phải, y hướng lên: bên phải của hướng nhìn (fx, fz) là (-fz, fx).
[[nodiscard]] std::optional<GroundPoint> heading_of(GroundPoint forward, Tilt tilt) noexcept {
    const auto ahead = unit(forward);
    if (!ahead) return std::nullopt;
    const GroundPoint right{.x = -ahead->z, .z = ahead->x};
    const float push = -tilt.y;
    const GroundPoint mixed{.x = (ahead->x * push) + (right.x * tilt.x), .z = (ahead->z * push) + (right.z * tilt.x)};
    return unit(mixed);
}

// Góc giữa hai hướng đơn vị, độ.
[[nodiscard]] float degrees_between(GroundPoint first, GroundPoint second) noexcept {
    const float dot = std::clamp((first.x * second.x) + (first.z * second.z), -1.0F, 1.0F);
    return std::acos(dot) * 180.0F / std::numbers::pi_v<float>;
}

} // namespace

// NOLINTBEGIN(bugprone-easily-swappable-parameters): chữ ký của TLBB Dev (HP-07)
StickStep StickMove::hold(GroundPoint self, GroundPoint forward, Tilt tilt, Clock::time_point now) noexcept {
    const bool is_resting = std::hypot(tilt.x, tilt.y) < kStickDeadZone;
    if (is_resting) return release();
    const auto heading = heading_of(forward, tilt);
    if (!heading) return {};
    const GroundPoint target{.x = self.x + (heading->x * kStickReach), .z = self.z + (heading->z * kStickReach)};
    const Aim aim{.heading = *heading, .target = target};
    if (is_moving_ && !is_due(aim, now)) return {};
    is_moving_ = true;
    sent_ = aim;
    sent_at_ = now;
    return StickStep{.order = StickOrder::kMove, .target = target};
}
// NOLINTEND(bugprone-easily-swappable-parameters)

StickStep StickMove::release() noexcept {
    if (!is_moving_) return {};
    is_moving_ = false;
    return StickStep{.order = StickOrder::kStop, .target = {}};
}

bool StickMove::is_due(const Aim& aim, Clock::time_point now) const noexcept {
    const Clock::duration since = now - sent_at_;
    const bool is_turned = degrees_between(sent_.heading, aim.heading) > kStickTurnDegrees;
    if (is_turned && since >= kStickGap) return true;
    const GroundPoint slide{.x = aim.target.x - sent_.target.x, .z = aim.target.z - sent_.target.z};
    const bool is_late = since >= kStickRepeat;
    return is_late && length_of(slide) >= kStickSlide;
}

} // namespace game::control
