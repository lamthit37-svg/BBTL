// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
#include "client/display/lighting.hpp"

#include "client/stage/sky.hpp"
#include "client/stage/stage.hpp"
#include "gpu/types.hpp"
#include "math/vector.hpp"
#include "render/forward.hpp"
#include "scene/placement.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <vector>

namespace game::client {
namespace {

[[nodiscard]] math::Vector3 vector_of(const Rgb& colour) noexcept {
    return {colour.red, colour.green, colour.blue};
}

// Ogre ghi hướng tia sáng đi; render::Sun ghi hướng TỚI đèn.
[[nodiscard]] math::Vector3 toward_of(const scene::Vector3& ray) noexcept {
    return {-ray.x, -ray.y, -ray.z};
}

[[nodiscard]] render::FogKind kind_of(FogMode mode) noexcept {
    if (mode == FogMode::kExp) return render::FogKind::kExp;
    if (mode == FogMode::kExp2) return render::FogKind::kExp2;
    if (mode == FogMode::kLinear) return render::FogKind::kLinear;
    return render::FogKind::kNone;
}

[[nodiscard]] render::Lamp lamp_of(const Lamp& lamp) noexcept {
    render::Lamp made;
    made.position = math::Vector3(lamp.position.x, lamp.position.y, lamp.position.z);
    made.color = vector_of(lamp.colour) * lamp.power;
    made.range = lamp.range;
    made.falloff = lamp.falloff;
    return made;
}

// Số của tệp cảnh: nhân vật nhận cùng ambient và cùng màu đèn với cảnh.
void take_scene(render::Lighting& lighting, const Stage& stage) noexcept {
    lighting.ambient = vector_of(stage.ambient);
    lighting.actor_ambient = lighting.ambient;
    lighting.fog.kind = kind_of(stage.fog.mode);
    lighting.fog.color = vector_of(stage.fog.colour);
    lighting.fog.density = stage.fog.density;
    lighting.fog.start = stage.fog.start;
    lighting.fog.end = stage.fog.end;
    lighting.suns = {};
    const std::size_t count = std::min(stage.suns.size(), lighting.suns.size());
    for (std::size_t index = 0; index < count; ++index) {
        const Sun& sun = stage.suns[index];
        lighting.suns.at(index).toward = toward_of(sun.direction);
        lighting.suns.at(index).color = vector_of(sun.colour) * sun.power;
        lighting.suns.at(index).actor = lighting.suns.at(index).color;
    }
    lighting.specular = stage.suns.empty() ? math::Vector3(0.0F) : vector_of(stage.suns[0].specular);
}

// Mốc theo giờ của bầu trời đè lên số của tệp cảnh; kiểu sương và hướng đèn giữ của cảnh.
void take_day(render::Lighting& lighting, const DayKey& day) noexcept {
    lighting.ambient = vector_of(day.ambient);
    lighting.actor_ambient = vector_of(day.actor_ambient);
    lighting.fog.color = vector_of(day.fog);
    lighting.fog.start = day.fog_near;
    lighting.fog.end = day.fog_far;
    lighting.suns[0].color = vector_of(day.light_one) * day.light_one_power;
    lighting.suns[0].actor = vector_of(day.actor_one) * day.actor_one_power;
    lighting.suns[1].color = vector_of(day.light_two) * day.light_two_power;
    lighting.suns[1].actor = vector_of(day.actor_two) * day.actor_two_power;
    lighting.specular = vector_of(day.light_one_specular);
}

// Giải mã sRGB chính xác của một kênh.
[[nodiscard]] float to_linear(float encoded) noexcept {
    const float value = std::clamp(encoded, 0.0F, 1.0F);
    if (value <= 0.04045F) return value / 12.92F;
    return std::pow((value + 0.055F) / 1.055F, 2.4F);
}

} // namespace

SceneLight::SceneLight(const Stage& stage, float time) {
    take_scene(base_, stage);
    if (!stage.days.empty()) take_day(base_, day_at(stage.days, time));
    lamps_.reserve(stage.lamps.size());
    for (const Lamp& lamp : stage.lamps) {
        lamps_.push_back(lamp_of(lamp));
    }
    const bool has_fog = base_.fog.kind != render::FogKind::kNone;
    backdrop_ = has_fog ? base_.fog.color : vector_of(stage.background);
}

render::Lighting SceneLight::view() const noexcept {
    render::Lighting lighting = base_;
    lighting.lamps = lamps_;
    return lighting;
}

gpu::ClearColor SceneLight::clear_color() const noexcept {
    gpu::ClearColor clear;
    clear.red = to_linear(backdrop_.x());
    clear.green = to_linear(backdrop_.y());
    clear.blue = to_linear(backdrop_.z());
    clear.alpha = 1.0F;
    return clear;
}

SceneLight light_of(const Stage& stage) {
    return {stage, kOfflineDayTime};
}

} // namespace game::client

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
