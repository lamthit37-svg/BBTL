/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/sky.cpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt sky.hpp. Thứ tự phép tính theo mã máy của Render.dll: pha trăng và
 *    mặt trời 0x180235780 / 0x180237050, mây vòng 0x18023bf50, mây 0x18023a9b0,
 *    nội suy TimeNode 0x1802087a0 / 0x180208a50 / 0x180207570.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ensky/sky.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <numbers>
#include <span>

namespace game::ensky {
namespace {

constexpr float kPi = std::numbers::pi_v<float>;
constexpr float kDegToRad = kPi / 180.0F;
constexpr float kHoursInDay = 24.0F;
// Nút trăng và mặt trời nằm ở trục z cục bộ của nút gốc: trăng ở -z, mặt trời ở +z.
constexpr ogre::Vec3 kMoonLocal{.x = 0.0F, .y = 0.0F, .z = -1.0F};
constexpr ogre::Vec3 kSunLocal{.x = 0.0F, .y = 0.0F, .z = 1.0F};
constexpr ogre::Vec3 kUnitY{.x = 0.0F, .y = 1.0F, .z = 0.0F};
constexpr ogre::Vec3 kUnitZ{.x = 0.0F, .y = 0.0F, .z = 1.0F};
constexpr ogre::Vec3 kBelowY{.x = 0.0F, .y = -1.0F, .z = 0.0F};
constexpr ogre::Vec3 kBelowX{.x = -1.0F, .y = 0.0F, .z = 0.0F};

[[nodiscard]] constexpr float mix(float from, float upper, float ratio) noexcept {
    return from + ((upper - from) * ratio);
}

[[nodiscard]] Colour mix(const Colour& from, const Colour& upper, float ratio) noexcept {
    return Colour{.red = mix(from.red, upper.red, ratio),
        .green = mix(from.green, upper.green, ratio),
        .blue = mix(from.blue, upper.blue, ratio)};
}

using ogre::Vec3;

[[nodiscard]] Vec3 mix(const Vec3& from, const Vec3& upper, float ratio) noexcept {
    return Vec3{.x = mix(from.x, upper.x, ratio),
        .y = mix(from.y, upper.y, ratio),
        .z = mix(from.z, upper.z, ratio)};
}

// Hai nút kề nhau quanh giờ hiện tại và tỉ lệ giữa chúng. Bảng tuần hoàn 24 giờ: trước nút đầu
// là nút cuối lùi 24 giờ, sau nút cuối là nút đầu cộng 24 giờ.
template <class Key>
struct Bracket {
    const Key* from = nullptr;
    const Key* upper = nullptr;
    float ratio = 0.0F;
};

template <class Key>
[[nodiscard]] Bracket<Key> bracket_of(std::span<const Key> keys, float hour) noexcept {
    const auto after = [hour](const Key& key) { return key.time > hour; };
    const auto next = std::ranges::find_if(keys, after);
    const bool is_first = next == keys.begin();
    const bool is_past_last = next == keys.end();
    const Key* upper = is_past_last ? &keys.front() : &*next;
    const Key* from = is_first ? &keys.back() : &*(next - 1);
    const float from_time = is_first ? from->time - kHoursInDay : from->time;
    const float upper_time = is_past_last ? upper->time + kHoursInDay : upper->time;
    const float span = upper_time - from_time;
    const float ratio = span > 0.0F ? (hour - from_time) / span : 0.0F;
    return Bracket<Key>{.from = from, .upper = upper, .ratio = ratio};
}

[[nodiscard]] CloudKey mix(const CloudKey& from, const CloudKey& upper, float ratio) noexcept {
    CloudKey key;
    key.time = mix(from.time, upper.time, ratio);
    key.fog = mix(from.fog, upper.fog, ratio);
    key.alpha = mix(from.alpha, upper.alpha, ratio);
    key.speed = mix(from.speed, upper.speed, ratio);
    key.ambient_blend = mix(from.ambient_blend, upper.ambient_blend, ratio);
    return key;
}

[[nodiscard]] RingKey mix(const RingKey& from, const RingKey& upper, float ratio) noexcept {
    RingKey key;
    key.time = mix(from.time, upper.time, ratio);
    key.fog_blend = mix(from.fog_blend, upper.fog_blend, ratio);
    key.ambient_blend = mix(from.ambient_blend, upper.ambient_blend, ratio);
    key.alpha = mix(from.alpha, upper.alpha, ratio);
    key.roll_speed = mix(from.roll_speed, upper.roll_speed, ratio);
    key.vertical_speed = mix(from.vertical_speed, upper.vertical_speed, ratio);
    key.fade_range = mix(from.fade_range, upper.fade_range, ratio);
    return key;
}

[[nodiscard]] EnvKey mix(const EnvKey& from, const EnvKey& upper, float ratio) noexcept {
    EnvKey key;
    key.time = mix(from.time, upper.time, ratio);
    key.ambient = mix(from.ambient, upper.ambient, ratio);
    key.fog = mix(from.fog, upper.fog, ratio);
    key.fog_near = mix(from.fog_near, upper.fog_near, ratio);
    key.fog_far = mix(from.fog_far, upper.fog_far, ratio);
    key.light_one = mix(from.light_one, upper.light_one, ratio);
    key.light_one_specular = mix(from.light_one_specular, upper.light_one_specular, ratio);
    key.light_one_direction = mix(from.light_one_direction, upper.light_one_direction, ratio);
    key.light_one_intensity = mix(from.light_one_intensity, upper.light_one_intensity, ratio);
    key.light_two = mix(from.light_two, upper.light_two, ratio);
    key.light_two_specular = mix(from.light_two_specular, upper.light_two_specular, ratio);
    key.light_two_direction = mix(from.light_two_direction, upper.light_two_direction, ratio);
    key.light_two_intensity = mix(from.light_two_intensity, upper.light_two_intensity, ratio);
    key.actor_one = mix(from.actor_one, upper.actor_one, ratio);
    key.actor_one_intensity = mix(from.actor_one_intensity, upper.actor_one_intensity, ratio);
    key.actor_two = mix(from.actor_two, upper.actor_two, ratio);
    key.actor_two_intensity = mix(from.actor_two_intensity, upper.actor_two_intensity, ratio);
    key.actor_ambient = mix(from.actor_ambient, upper.actor_ambient, ratio);
    key.dome_ambient = mix(from.dome_ambient, upper.dome_ambient, ratio);
    key.dome_strength = mix(from.dome_strength, upper.dome_strength, ratio);
    return key;
}

template <class Key>
[[nodiscard]] Key blend_at(std::span<const Key> keys, float hour) noexcept {
    const Bracket<Key> pair = bracket_of(keys, hour);
    return mix(*pair.from, *pair.upper, pair.ratio);
}

// Quaternion xoay degrees độ quanh trục, như Node::rotate(..., TS_LOCAL) đã chuẩn hoá.
[[nodiscard]] ogre::Quat turn_of(float radians, ogre::Vec3 axis) {
    return ogre::quat_normalize(ogre::quat_from_angle_axis(radians, axis));
}

struct Aim {
    float orient = 0.0F;
    float angle = 0.0F;
};

// Nút gốc của trăng và mặt trời sau resetOrientation: q1 = (orient + 180) độ quanh -Y, q2 = -angle
// độ quanh -X, đều nhân sau (TS_LOCAL). Cộng 180 làm bằng double như mã máy (ADDSD).
[[nodiscard]] ogre::Quat base_orientation(Aim aim) {
    const double shifted = static_cast<double>(aim.orient) + 180.0;
    const float yaw = static_cast<float>(shifted) * kDegToRad;
    const float pitch = -aim.angle * kDegToRad;
    const ogre::Quat identity{};
    const ogre::Quat first = ogre::quat_multiply(identity, turn_of(yaw, kBelowY));
    return ogre::quat_multiply(first, turn_of(pitch, kBelowX));
}

// q3: p vòng quanh -Y. 360 nhân bằng double như mã máy.
[[nodiscard]] ogre::Quat spin_of(float phase) {
    const double turns = static_cast<double>(phase) * 360.0;
    return turn_of(static_cast<float>(turns) * kDegToRad, kBelowY);
}

// Quaternion tuyệt đối của mây vòng khi không quay: yaw `offset` độ quanh +Y, cos/sin của nửa góc
// tính theo đúng thứ tự phép tính của 0x18023bf50.
[[nodiscard]] ogre::Quat ring_rest(float offset) noexcept {
    const float half = ((((offset * 2.0F) * kPi) / 360.0F) * 0.5F);
    return ogre::Quat{.x = 0.0F, .y = std::sin(half), .z = 0.0F, .w = std::cos(half)};
}

[[nodiscard]] ogre::Quat roll_of(float radians) {
    return turn_of(radians, kUnitZ);
}

// Một bước của mây vòng quay: cộng dồn yaw cục bộ, rồi khớp trạng thái lật với cờ của lớp.
[[nodiscard]] ogre::Quat ring_spin(const RingLive& live, float seconds) {
    const float radians = (live.roll_speed * seconds) * kDegToRad;
    return ogre::quat_multiply(live.orientation, turn_of(radians, kUnitY));
}

void match_flip(RingLive& live, bool is_flipped) {
    if (is_flipped == live.is_flipped) return;
    const float radians = is_flipped ? kPi : -kPi;
    live.orientation = ogre::quat_multiply(live.orientation, roll_of(radians));
    live.is_flipped = is_flipped;
}

void turn_ring(RingLive& live, const RingLayer& layer, float seconds) {
    if (live.roll_speed != 0.0F) {
        live.orientation = ring_spin(live, seconds);
        match_flip(live, layer.is_flipped);
        return;
    }
    live.orientation = ring_rest(layer.offset);
    live.is_flipped = false;
    match_flip(live, layer.is_flipped);
}

// v quấn một vòng khi vượt biên [-1, 1], như mã máy (trừ hay cộng đúng 1).
[[nodiscard]] float wrap_offset(float value) noexcept {
    if (value > 1.0F) return value - 1.0F;
    if (-1.0F > value) return value + 1.0F;
    return value;
}

void load_cloud(CloudLive& live, const CloudKey& key) noexcept {
    live.fog = key.fog;
    live.alpha = key.alpha;
    live.speed = key.speed;
    live.ambient_blend = key.ambient_blend;
}

void load_ring(RingLive& live, const RingKey& key) noexcept {
    live.fog_blend = key.fog_blend;
    live.ambient_blend = key.ambient_blend;
    live.alpha = key.alpha;
    live.fade_range = key.fade_range;
    live.roll_speed = key.roll_speed;
    live.vertical_speed = key.vertical_speed;
}

} // namespace

void DayClock::advance(float seconds) noexcept {
    if (is_pinned_) return;
    fraction_ += seconds / kDaySeconds;
    if (fraction_ > 1.0F) fraction_ -= 1.0F;
}

void DayClock::pin(float fraction) noexcept {
    is_pinned_ = true;
    fraction_ = fraction;
}

float DayClock::hour() const noexcept {
    const float hour = fraction_ * kHoursInDay;
    return hour >= kLastHour ? kLastHour : hour;
}

float phase_of(float hour, float start, float end) noexcept {
    const float rest = (kHoursInDay - end) + start;
    if (end >= start) {
        if (hour > end) return ((hour - end) / (rest * 2.0F)) + 0.75F;
        if (hour < start) return (((hour + kHoursInDay) - end) / (rest * 2.0F)) + 0.75F;
        return ((hour - start) / ((end - start) * 2.0F)) + 0.25F;
    }
    const float wrap = (end + kHoursInDay) - start;
    if (hour > start) return ((hour - start) / (wrap * 2.0F)) + 0.25F;
    if (hour < end) return (((hour + kHoursInDay) - start) / (wrap * 2.0F)) + 0.25F;
    return ((hour - end) / ((start - end) * 2.0F)) + 0.75F;
}

Pose moon_pose(const Moon& moon, float hour) noexcept {
    ogre::Quat orientation = base_orientation({.orient = moon.orient, .angle = moon.angle});
    if (!moon.is_fixed) {
        const float phase = phase_of(hour, moon.down_time, moon.up_time);
        orientation = ogre::quat_multiply(orientation, spin_of(phase));
    }
    const ogre::Vec3 toward = ogre::quat_rotate(orientation, kMoonLocal);
    return Pose{.orientation = orientation, .toward = toward};
}

Pose sun_pose(const Sun& sun, float hour) noexcept {
    constexpr float kNoon = 0.5F;
    ogre::Quat orientation = base_orientation({.orient = sun.orient, .angle = sun.angle});
    const float phase = sun.is_fixed ? kNoon : phase_of(hour, sun.up_time, sun.down_time);
    orientation = ogre::quat_multiply(orientation, spin_of(phase));
    const ogre::Vec3 toward = ogre::quat_rotate(orientation, kSunLocal);
    return Pose{.orientation = orientation, .toward = toward};
}

EnvKey env_at(std::span<const EnvKey> keys, float hour) noexcept {
    return blend_at(keys, hour);
}

Playback::Playback(const Sky& sky) : sky_(&sky) {
    clouds_.resize(sky.clouds.size());
    rings_.resize(sky.rings.size());
    star_.apply(sky.star);
}

void Playback::retime(float hour) {
    timed_hour_ = hour;
    ++retimes_;
    for (std::size_t index = 0; index < clouds_.size(); ++index) {
        const std::span<const CloudKey> keys = sky_->clouds.at(index).keys;
        if (!keys.empty()) load_cloud(clouds_.at(index), blend_at(keys, hour));
    }
    for (std::size_t index = 0; index < rings_.size(); ++index) {
        const std::span<const RingKey> keys = sky_->rings.at(index).keys;
        if (!keys.empty()) load_ring(rings_.at(index), blend_at(keys, hour));
    }
    if (!sky_->env.empty()) env_ = env_at(sky_->env, hour);
}

void Playback::turn_rings(float seconds) {
    for (std::size_t index = 0; index < rings_.size(); ++index) {
        RingLive& live = rings_.at(index);
        turn_ring(live, sky_->rings.at(index), seconds);
        live.v_offset = wrap_offset((seconds * live.vertical_speed) + live.v_offset);
    }
}

void Playback::update(Tick tick) {
    const float seconds = tick.seconds;
    const float hour = tick.hour;
    hour_ = hour;
    const bool is_due = std::fabs(hour - timed_hour_) > kHourStep;
    if (is_due) retime(hour);
    for (CloudLive& live : clouds_) {
        const double drift = static_cast<double>(live.speed * seconds) * 0.1;
        live.wind = static_cast<float>(drift + static_cast<double>(live.wind));
    }
    turn_rings(seconds);
    moon_ = moon_pose(sky_->moon, hour);
    sun_ = sun_pose(sky_->sun, hour);
    star_.set_hour(hour);
    star_.advance(seconds);
}

} // namespace game::ensky
