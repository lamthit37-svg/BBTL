// Lò xo chọn nhân vật, hướng đi theo yaw, và rung kính của hiệu ứng.
#include "camera/motion.hpp"

#include "camera/basis.hpp"
#include "math/vector.hpp"

#include <limits>

namespace game::camera {
namespace {

using Point = math::Point3;
using Vec3 = math::Vector3;

constexpr float kSpring = 4.6F;
constexpr float kRest = 20.0F;
constexpr float kStop = 0.05F;
constexpr float kStep = 1000.0F;
constexpr float kEpsilon = std::numeric_limits<float>::epsilon();

[[nodiscard]] Vec3 diagonal(Vec3 first, Vec3 second) noexcept {
    return normalize(first + second);
}

[[nodiscard]] float swing_factor(const Shake& shake) noexcept {
    const float swing_length = length(shake.swing);
    if (swing_length <= kEpsilon) return 1.0F;
    const Vec3 from_node = shake.eye - shake.node;
    const float span = length(from_node);
    const float raw = span * shake.attenuation / swing_length;
    if (raw > 1.0F) return 1.0F;
    return raw;
}

// Mốc mở rồi mốc đóng, không đổi chỗ (API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] bool reverses(float state_time, float last_time) noexcept {
    const float open = last_time * 0.25F;
    const float close = last_time * 0.75F;
    if (state_time <= open) return false;
    if (state_time >= close) return false;
    return true;
}

[[nodiscard]] Vec3 velocity_of(Vec3 swing, float last_time, float delta, bool reverse) noexcept {
    if (last_time <= kEpsilon) return {};
    const float scale = (2.0F / last_time) * delta;
    Vec3 velocity = swing * scale;
    if (reverse) velocity = -velocity;
    return velocity;
}

} // namespace

math::Point3 spring_look_at(LookPair ends, float delta_seconds) noexcept {
    const Vec3 displacement = ends.current - ends.target;
    const float span = length(displacement);
    if (span <= kStop) return ends.current;
    const float force = kSpring * (kRest - span);
    const Vec3 direction = displacement / span;
    const Point moved = ends.current + (direction * (force * delta_seconds));
    const Vec3 after = moved - ends.target;
    const float after_span = length(after);
    if (after_span <= kEpsilon) return ends.target;
    const float same_way = dot(direction, after / after_span);
    if (same_way <= 0.0F) return ends.target;
    return moved;
}

math::Vector3 walk_direction(WalkDir direction, float camera_yaw) noexcept {
    Euler euler;
    euler.yaw = camera_yaw;
    const Basis basis = basis_of(euler);
    const Vec3 forward = basis.forward;
    const Vec3 left = basis.side;
    const Vec3 right = -left;
    const Vec3 back = -forward;
    switch (direction) {
    case WalkDir::kFront: return forward;
    case WalkDir::kBack: return back;
    case WalkDir::kLeft: return left;
    case WalkDir::kRight: return right;
    case WalkDir::kRightFront: return diagonal(forward, right);
    case WalkDir::kRightBack: return diagonal(back, right);
    case WalkDir::kLeftFront: return diagonal(forward, left);
    case WalkDir::kLeftBack: return diagonal(back, left);
    default: return forward;
    }
}

math::Point3 walk_destination(WalkQuery query) noexcept {
    const Vec3 step = walk_direction(query.direction, query.camera_yaw) * kStep;
    return query.start + step;
}

ShakeResult effect_shake(const Shake& shake) noexcept {
    const float remain = 1.0F - swing_factor(shake);
    const Vec3 swung = shake.swing * remain;
    const bool reverse = reverses(shake.state_time, shake.last_time);
    const Vec3 velocity = velocity_of(swung, shake.last_time, shake.delta_seconds, reverse);
    ShakeResult result;
    result.eye = shake.eye + velocity;
    result.look_at = shake.look_at + velocity;
    return result;
}

} // namespace game::camera
