// Xem gain.hpp. Doppler dùng tốc độ âm 34300 cm/s và kẹp tỷ lệ trong [0.25, 4].
#include "audio/gain.hpp"

#include "audio/limits.hpp"

#include <cmath>

namespace game::audio {
namespace {

constexpr float kMinRate = 0.25F;
constexpr float kMaxRate = 4.F;
constexpr float kMinDenominator = 1000.F;

struct Vec3 {
    float x = 0.F;
    float y = 0.F;
    float z = 0.F;
};

struct Range {
    float low = 0.F;
    float high = 0.F;
};

struct VecPair {
    Vec3 left;
    Vec3 right;
};

float clampf(float value, Range range) noexcept {
    if (value < range.low) return range.low;
    if (value > range.high) return range.high;
    return value;
}

float length_of(Vec3 value) noexcept {
    const float square_x = value.x * value.x;
    const float square_y = value.y * value.y;
    const float square_z = value.z * value.z;
    return std::sqrt((square_x + square_y) + square_z);
}

float dot_pair(VecPair pair) noexcept {
    const float along_x = pair.left.x * pair.right.x;
    const float along_y = pair.left.y * pair.right.y;
    const float along_z = pair.left.z * pair.right.z;
    return along_x + along_y + along_z;
}

Vec3 toward(const Ear& ear, const Place& place) noexcept {
    const float offset_x = place.x - ear.x;
    const float offset_y = place.y - ear.y;
    const float offset_z = place.z - ear.z;
    return Vec3{.x = offset_x, .y = offset_y, .z = offset_z};
}

Vec3 right_of(const Ear& ear) noexcept {
    const float right_x = (ear.forward_y * ear.up_z) - (ear.forward_z * ear.up_y);
    const float right_y = (ear.forward_z * ear.up_x) - (ear.forward_x * ear.up_z);
    const float right_z = (ear.forward_x * ear.up_y) - (ear.forward_y * ear.up_x);
    return Vec3{.x = right_x, .y = right_y, .z = right_z};
}

Vec3 velocity_of(const Ear& ear) noexcept {
    return Vec3{.x = ear.velocity_x, .y = ear.velocity_y, .z = ear.velocity_z};
}

Vec3 velocity_of_place(const Place& place) noexcept {
    return Vec3{.x = place.velocity_x, .y = place.velocity_y, .z = place.velocity_z};
}

float side_of(const Ear& ear, const Place& place) noexcept {
    const Vec3 offset = toward(ear, place);
    const float distance = length_of(offset);
    if (distance < 1.F) return 0.F;
    const float inv = 1.F / distance;
    const Vec3 direction{.x = offset.x * inv, .y = offset.y * inv, .z = offset.z * inv};
    const Vec3 right = right_of(ear);
    const VecPair pair{.left = direction, .right = right};
    const Range unit{.low = -1.F, .high = 1.F};
    return clampf(dot_pair(pair), unit);
}

} // namespace

float distance_gain(float distance, DistanceSpan span) noexcept {
    float far_distance = span.far_distance;
    const float near_distance = span.near_distance;
    if (near_distance >= far_distance) far_distance = near_distance + 1.F;
    if (distance <= near_distance) return 1.F;
    if (distance >= far_distance) return 0.F;
    const float width = far_distance - near_distance;
    return (far_distance - distance) / width;
}

float fade_in(FadeSpan span) noexcept {
    if (span.duration_seconds <= 0.F) return 1.F;
    if (span.elapsed_seconds <= 0.F) return 0.F;
    if (span.elapsed_seconds >= span.duration_seconds) return 1.F;
    return span.elapsed_seconds / span.duration_seconds;
}

float fade_out(FadeSpan span) noexcept {
    const float rising = fade_in(span);
    return 1.F - rising;
}

Stereo pan_of(const Ear& ear, const Place& place) noexcept {
    const float side = side_of(ear, place);
    const float left_power = 0.5F * (1.F - side);
    const float right_power = 0.5F * (1.F + side);
    const float left = std::sqrt(left_power);
    const float right = std::sqrt(right_power);
    return Stereo{.left = left, .right = right};
}

float doppler_rate(const Ear& ear, const Place& place) noexcept {
    const Vec3 offset = toward(ear, place);
    const float distance = length_of(offset);
    if (distance < 1.F) return 1.F;
    const float inv = 1.F / distance;
    const Vec3 direction{.x = offset.x * inv, .y = offset.y * inv, .z = offset.z * inv};
    const Vec3 listener_velocity = velocity_of(ear);
    const VecPair listener_pair{.left = listener_velocity, .right = direction};
    const float listener = dot_pair(listener_pair);
    const Vec3 source_velocity = velocity_of_place(place);
    const VecPair source_pair{.left = source_velocity, .right = direction};
    const float source = dot_pair(source_pair);
    const float denominator = kSoundSpeed + source;
    if (denominator < kMinDenominator) return kMaxRate;
    const float numerator = kSoundSpeed + listener;
    const Range rate_range{.low = kMinRate, .high = kMaxRate};
    return clampf(numerator / denominator, rate_range);
}

} // namespace game::audio
