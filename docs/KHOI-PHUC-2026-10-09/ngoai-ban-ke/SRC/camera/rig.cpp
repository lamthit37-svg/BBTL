// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
#if defined(__clang__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__)
#pragma GCC target("sse4.1")
#endif
// Kính chơi: thứ tự Update của ClientCamera, hằng số giữ nguyên.
// Bay 40 mỗi lần gọi. Lò xo occult 1000 cm/s. Tia mặt đất bước 10 cm.
// Ma trận cuối là SetLookAt sau khi nâng look, không dựng lại Euler.
#include "camera/rig.hpp"

#include "camera/basis.hpp"
#include "camera/lens.hpp"
#include "math/scalar.hpp"
#include "math/vector.hpp"

#include <algorithm>
#include <cstdint>
#include <limits>
#include <optional>

namespace game::camera {
namespace {

using Point = math::Point3;
using Vec3 = math::Vector3;

constexpr float kMinDistance = 200.0F;
constexpr float kMinExpect = 220.0F;
constexpr float kMaxExpect = 1800.0F;
constexpr float kYawRate = 0.6F * 0.006545F;
constexpr float kPitchRate = 0.006545F;
constexpr float kFlyStep = 40.0F;
constexpr float kEyeHeight = 130.0F;
constexpr float kWaterGap = 10.0F;
constexpr float kMarchGap = 30.0F;
constexpr float kEyeGap = 10.0F;
constexpr float kSceneGap = 80.0F;
constexpr float kSpringSpeed = 1000.0F;
constexpr float kMarchStep = 10.0F;
constexpr float kRaiseCap = 140.0F;
constexpr float kNearPlane = 20.0F;
constexpr float kPitchMin = -math::kPi * 0.45F;
constexpr float kPitchMax = math::radians(80.0F);
constexpr float kOpacitySpeed = 4.0F;
constexpr float kDefaultYaw = 0.39793599F;
constexpr float kDefaultPitch = -0.18762225F;
constexpr float kDefaultDistance = 660.0F;
constexpr float kSpringSlack = 1.0F;
constexpr float kStoredFar = 25600.0F;
constexpr float kEpsilon = std::numeric_limits<float>::epsilon();
constexpr std::uint32_t kQuakeMs = 300;
constexpr std::uint32_t kQuakeFrames = 10;

struct Shift {
    float along_x = 0.0F;
    float along_y = 0.0F;
};

struct SpringSpan {
    float current = 0.0F;
    float expect = 0.0F;
    float delta_seconds = 0.0F;
};

struct MarchSample {
    const Probe* probe = nullptr;
    Point look{};
    Vec3 direction;
    float cursor = 0.0F;
};

struct March {
    Point look{};
    Vec3 direction;
    float cursor = 0.0F;
    float reach = 0.0F;
    bool blocked = false;
};

struct RayStep {
    Point look{};
    Vec3 direction;
    float reach = 0.0F;
};

struct HitClock {
    const Probe* probe = nullptr;
    std::uint32_t wall_ms = 0;
};

void apply_euler(Rig& rig) noexcept {
    rig.basis = basis_of(rig.euler);
    Pose pose;
    pose.eye = rig.basis.eye;
    pose.target = rig.euler.look_at;
    pose.up = rig.basis.up;
    set_look_at(rig.lens, pose);
}

void clamp_expect(float& expect) noexcept {
    expect = std::min(expect, kMaxExpect);
    expect = std::max(expect, kMinExpect);
}

void apply_wheel(Rig& rig, const PointerInput& pointer) noexcept {
    if (pointer.wheel == 0) return;
    if (!pointer.over_desktop) return;
    const float delta = -static_cast<float>(pointer.wheel) / 2.0F;
    rig.expect_distance += delta;
    clamp_expect(rig.expect_distance);
    rig.last_occult_ms = 0;
}

void note_press(Rig& rig, RigOutput& output, const PointerInput& pointer) noexcept {
    if (!pointer.right_pressed) return;
    output.capture = true;
    rig.locked_x = pointer.cursor_x;
    rig.locked_y = pointer.cursor_y;
}

void note_release(RigOutput& output, const PointerInput& pointer) noexcept {
    if (!pointer.right_released) return;
    output.release = true;
}

[[nodiscard]] float clamped_pitch(float pitch) noexcept {
    return std::clamp(pitch, kPitchMin, kPitchMax);
}

// Khoảng cách và delta chuột là hai cổng độc lập (API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] bool may_pitch(float distance, std::int32_t relative_y) noexcept {
    if (distance > kMinDistance) return true;
    return relative_y > 0;
}

void steer_drag(Rig& rig, RigOutput& output, const PointerInput& pointer) noexcept {
    if (!pointer.right_held) return;
    if (!pointer.moved) return;
    const float yaw_delta = static_cast<float>(pointer.relative_x) * kYawRate;
    rig.euler.yaw += yaw_delta;
    const float raw = rig.euler.pitch - (static_cast<float>(pointer.relative_y) * kPitchRate);
    const float limited = clamped_pitch(raw);
    if (may_pitch(rig.euler.distance, pointer.relative_y)) rig.euler.pitch = limited;
    output.warp = true;
    output.warp_x = rig.locked_x;
    output.warp_y = rig.locked_y;
    if (pointer.relative_x != 0) output.yaw_turned = true;
}

void fly_axis(Point& look, Vec3 axis, float scale) noexcept {
    look += axis * scale;
}

void fly_move(Rig& rig, const FlyKeys& keys) noexcept {
    const Vec3 forward = rig.basis.forward;
    const Vec3 side = rig.basis.side;
    if (keys.forward) fly_axis(rig.euler.look_at, forward, kFlyStep);
    if (keys.back) fly_axis(rig.euler.look_at, forward, -kFlyStep);
    if (keys.left) fly_axis(rig.euler.look_at, side, kFlyStep);
    if (keys.right) fly_axis(rig.euler.look_at, side, -kFlyStep);
}

[[nodiscard]] Shift quake_shift(std::uint32_t frame) noexcept {
    switch (frame) {
    case 0: return {.along_x = 0.0F, .along_y = 5.0F};
    case 1: return {.along_x = 0.0F, .along_y = -5.0F};
    case 2: return {.along_x = 0.0F, .along_y = 5.0F};
    case 3: return {.along_x = 0.0F, .along_y = -5.0F};
    case 4: return {.along_x = 0.0F, .along_y = 5.0F};
    case 5: return {.along_x = 0.0F, .along_y = -5.0F};
    case 6: return {.along_x = 0.0F, .along_y = 4.0F};
    case 7: return {.along_x = 0.0F, .along_y = -4.0F};
    case 8: return {.along_x = 0.0F, .along_y = 4.0F};
    case 9: return {.along_x = 0.0F, .along_y = -4.0F};
    default: return {};
    }
}

[[nodiscard]] std::uint32_t quake_frame(std::uint32_t elapsed) noexcept {
    const std::uint32_t frame = (kQuakeFrames * elapsed) / kQuakeMs;
    if (frame >= kQuakeFrames) return kQuakeFrames - 1U;
    return frame;
}

void add_quake(Rig& rig, Point& look, std::uint32_t accum_ms) noexcept {
    if (!rig.is_quaking) return;
    const std::uint32_t elapsed = accum_ms - rig.quake_start_ms;
    if (elapsed > kQuakeMs) {
        rig.is_quaking = false;
        return;
    }
    const std::uint32_t frame = quake_frame(elapsed);
    const Shift shift = quake_shift(frame);
    look.set_x(look.x() + shift.along_x);
    look.set_y(look.y() + shift.along_y);
}

void lift_water(Point& point, const Probe& probe) noexcept {
    if (probe.water_height == nullptr) return;
    const std::optional<float> height = probe.water_height(probe.user, point);
    if (!height.has_value()) return;
    const float surface = *height + kWaterGap;
    point.set_y(std::max(point.y(), surface));
}

void lift_ground(Point& eye, const Probe& probe) noexcept {
    if (probe.ground == nullptr) return;
    Planar place;
    place.x = eye.x();
    place.z = eye.z();
    const float floor = probe.ground(probe.user, place) + kEyeGap;
    eye.set_y(std::max(eye.y(), floor));
}

[[nodiscard]] float spring_out(SpringSpan span) noexcept {
    if (span.current >= span.expect - kSpringSlack) return span.current;
    const float grown = span.current + (kSpringSpeed * span.delta_seconds);
    return std::min(grown, span.expect);
}

[[nodiscard]] bool under_ground(const MarchSample& sample) noexcept {
    if (sample.probe == nullptr) return false;
    if (sample.probe->ground == nullptr) return false;
    const Point place = sample.look + (sample.direction * sample.cursor);
    Planar planar;
    planar.x = place.x();
    planar.z = place.z();
    const float roof = sample.probe->ground(sample.probe->user, planar) + kMarchGap;
    return place.y() < roof;
}

void march_one(March& march, const Probe& probe) noexcept {
    MarchSample sample;
    sample.probe = &probe;
    sample.look = march.look;
    sample.direction = march.direction;
    sample.cursor = march.cursor;
    if (under_ground(sample)) march.blocked = true;
    if (!march.blocked) march.cursor += kMarchStep;
}

void settle_march(March& march) noexcept {
    if (march.blocked) return;
    march.cursor = std::min(march.cursor, march.reach);
}

void march_ground(March& march, const Probe& probe) noexcept {
    march.cursor = 0.0F;
    march.blocked = false;
    while (march.cursor <= march.reach && !march.blocked) {
        march_one(march, probe);
    }
    settle_march(march);
}

[[nodiscard]] float pull_water(Rig& rig, RayStep step, HitClock clock) noexcept {
    if (clock.probe == nullptr || clock.probe->water_ray == nullptr) return step.reach;
    WaterQuery query;
    query.origin = step.look;
    query.direction = step.direction;
    query.reach = step.reach;
    const std::optional<Point> hit = clock.probe->water_ray(clock.probe->user, query);
    if (!hit.has_value()) return step.reach;
    Point lifted = *hit;
    lifted.set_y(lifted.y() + kMarchGap);
    rig.last_occult_ms = clock.wall_ms;
    const Vec3 offset = lifted - step.look;
    return length(offset);
}

[[nodiscard]] float pull_scene(Rig& rig, RayStep step, HitClock clock) noexcept {
    if (clock.probe == nullptr || clock.probe->scene_ray == nullptr) return step.reach;
    SceneQuery query;
    query.origin = step.look;
    query.direction = step.direction;
    const std::optional<float> hit = clock.probe->scene_ray(clock.probe->user, query);
    if (!hit.has_value()) return step.reach;
    const float pulled = *hit - kSceneGap;
    if (pulled >= step.reach) return step.reach;
    rig.last_occult_ms = clock.wall_ms;
    return pulled;
}

void finish_dist(Rig& rig, float distance) noexcept {
    rig.is_fading = distance < kMinDistance;
    rig.euler.distance = std::max(distance, kMinDistance);
}

[[nodiscard]] float march_reach(Rig& rig, RayStep step, const FrameInput& frame) noexcept {
    if (frame.probe.ground == nullptr) return step.reach;
    March march;
    march.look = step.look;
    march.direction = step.direction;
    march.reach = step.reach;
    march_ground(march, frame.probe);
    if (march.blocked) rig.last_occult_ms = frame.clock.wall_ms;
    return march.cursor;
}

// NavMap null thì gốc bỏ cả hàm. Thiếu từng callback thì bỏ đúng phép thử đó.
void occult(Rig& rig, Point look, const FrameInput& frame) noexcept {
    const bool has_ground = frame.probe.ground != nullptr;
    const bool has_water = frame.probe.water_ray != nullptr;
    const bool has_scene = frame.probe.scene_ray != nullptr;
    if (!has_ground && !has_water && !has_scene) return;
    Vec3 direction = rig.lens.eye - look;
    const float span = length(direction);
    if (span <= kEpsilon) return;
    direction = direction / span;
    SpringSpan spring;
    spring.current = span;
    spring.expect = rig.expect_distance;
    spring.delta_seconds = frame.clock.delta_seconds;
    const float sprung = spring_out(spring);
    const float capped = std::min(sprung, rig.expect_distance);
    RayStep step;
    step.look = look;
    step.direction = direction;
    step.reach = capped;
    step.reach = march_reach(rig, step, frame);
    HitClock clock;
    clock.probe = &frame.probe;
    clock.wall_ms = frame.clock.wall_ms;
    const float watered = pull_water(rig, step, clock);
    step.reach = watered;
    const float pulled = pull_scene(rig, step, clock);
    finish_dist(rig, pulled);
}

[[nodiscard]] Point aimed_look(const Rig& rig, const Subject& subject) noexcept {
    Point look = subject.position;
    look.set_y(look.y() + (kEyeHeight * rig.height_scale));
    return look;
}

void raise_look(Point& look, float distance) noexcept {
    const float lift = (distance - kMinDistance) / 10.0F;
    look.set_y(look.y() + std::min(lift, kRaiseCap));
}

void finish_view(Rig& rig, Point eye) noexcept {
    Pose pose;
    pose.eye = eye;
    pose.target = rig.euler.look_at;
    pose.up = rig.basis.up;
    set_look_at(rig.lens, pose);
}

void follow_subject(Rig& rig, const FrameInput& frame) noexcept {
    Point look = aimed_look(rig, frame.subject);
    add_quake(rig, look, frame.clock.accum_ms);
    lift_water(look, frame.probe);
    rig.euler.look_at = look;
    occult(rig, look, frame);
    apply_euler(rig);
    raise_look(rig.euler.look_at, rig.euler.distance);
    Point eye = rig.lens.eye;
    lift_water(eye, frame.probe);
    lift_ground(eye, frame.probe);
    finish_view(rig, eye);
}

void follow_or_stop(Rig& rig, const FrameInput& frame) noexcept {
    if (!frame.subject.present) return;
    follow_subject(rig, frame);
}

void fade_down(Rig& rig, float delta_seconds) noexcept {
    if (!rig.is_fading) return;
    if (rig.role_opacity <= 0.0F) return;
    rig.role_opacity -= kOpacitySpeed * delta_seconds;
    rig.role_opacity = std::max(rig.role_opacity, 0.0F);
}

void fade_up(Rig& rig, float delta_seconds) noexcept {
    if (rig.is_fading) return;
    if (rig.role_opacity >= 1.0F) return;
    rig.role_opacity += kOpacitySpeed * delta_seconds;
    rig.role_opacity = std::min(rig.role_opacity, 1.0F);
}

} // namespace

Rig make_rig(std::uint32_t wall_ms) noexcept {
    Rig rig;
    rig.lens.depth.z_far = kStoredFar;
    rig.last_occult_ms = wall_ms;
    return rig;
}

void place(Rig& rig, const Euler& euler) noexcept {
    rig.euler = euler;
    apply_euler(rig);
}

void set_default(Rig& rig, Viewport viewport, float z_far) noexcept {
    DepthRange depth;
    depth.z_near = kNearPlane;
    depth.z_far = z_far;
    set_perspective(rig.lens, viewport, math::radians(45.0F), depth);
    Euler euler;
    euler.look_at = {0.0F, 500.0F, 0.0F};
    euler.yaw = kDefaultYaw;
    euler.pitch = kDefaultPitch;
    euler.roll = 0.0F;
    euler.distance = kDefaultDistance;
    place(rig, euler);
    rig.expect_distance = rig.euler.distance;
}

void set_fov(Rig& rig, Viewport viewport, float degrees) noexcept {
    DepthRange depth;
    depth.z_near = kNearPlane;
    depth.z_far = rig.lens.depth.z_far;
    set_perspective(rig.lens, viewport, math::radians(degrees), depth);
    rig.expect_distance = rig.euler.distance;
}

void resize(Rig& rig, Viewport viewport) noexcept {
    if (rig.lens.fov_y <= 0.0F) return;
    set_perspective(rig.lens, viewport, rig.lens.fov_y, rig.lens.depth);
}

void play_quake(Rig& rig, std::uint32_t accum_ms) noexcept {
    if (rig.is_quaking) return;
    rig.quake_start_ms = accum_ms;
    rig.is_quaking = true;
}

void step_opacity(Rig& rig, float delta_seconds) noexcept {
    fade_down(rig, delta_seconds);
    fade_up(rig, delta_seconds);
}

void add_yaw(Rig& rig, float radians) noexcept {
    rig.euler.yaw += radians;
}

void add_expect(Rig& rig, float delta) noexcept {
    rig.expect_distance += delta;
    clamp_expect(rig.expect_distance);
}

void restore_aim(Rig& rig) noexcept {
    rig.euler.yaw = kDefaultYaw;
    rig.euler.pitch = kDefaultPitch;
    rig.euler.roll = 0.0F;
    rig.euler.distance = kDefaultDistance;
    rig.expect_distance = kDefaultDistance;
}

RigOutput steer(Rig& rig, const PointerInput& pointer, const FlyKeys& keys) noexcept {
    RigOutput output;
    apply_wheel(rig, pointer);
    note_press(rig, output, pointer);
    note_release(output, pointer);
    steer_drag(rig, output, pointer);
    if (!rig.is_fly) return output;
    fly_move(rig, keys);
    apply_euler(rig);
    return output;
}

void settle(Rig& rig, const FrameInput& frame) noexcept {
    if (rig.is_fly) return;
    follow_or_stop(rig, frame);
}

RigOutput update(Rig& rig, const FrameInput& frame) noexcept {
    const RigOutput output = steer(rig, frame.pointer, frame.keys);
    settle(rig, frame);
    return output;
}

} // namespace game::camera

#if defined(__clang__)
#pragma clang attribute pop
#endif
