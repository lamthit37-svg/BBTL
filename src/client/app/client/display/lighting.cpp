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
#include "render/shade.hpp"
#include "scene/placement.hpp"
#include "scene/transform.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <numbers>
#include <optional>
#include <utility>
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

[[nodiscard]] render::Lamp lamp_of(const Lamp& lamp) noexcept {
    render::Lamp made;
    made.position = math::Vector3(lamp.position.x, lamp.position.y, lamp.position.z);
    made.color = vector_of(lamp.colour) * lamp.power;
    made.range = lamp.range;
    made.falloff = lamp.falloff;
    return made;
}

// unitbox.mesh có nửa cạnh 50 (Render.dll 0x18010db90).
constexpr float kBoxHalf = 50.0F;
// Độ sáng cảnh của FakeLight: 0x1800db690 chia 3, 0x18010d780 chia 3 lần nữa; tổng chín kênh của
// ambient và hai đèn chính chia 9.
constexpr float kBrightnessDivisor = 9.0F;

[[nodiscard]] float sum_of(const math::Vector3& colour) noexcept {
    return colour.x() + colour.y() + colour.z();
}

// Khác gốc: bản gốc đọc diffuse thô của hai Ogre::Light; ở đây là màu đã nhân cường độ.
[[nodiscard]] float scene_brightness(const render::Lighting& lighting) noexcept {
    const float ambient = sum_of(lighting.ambient);
    const float one = sum_of(lighting.suns[0].color);
    const float two = sum_of(lighting.suns[1].color);
    return (ambient + one + two) / kBrightnessDivisor;
}

[[nodiscard]] float widest_scale(const scene::Vector3& scale) noexcept {
    return std::max({std::fabs(scale.x), std::fabs(scale.y), std::fabs(scale.z)});
}

// Đèn giả của stage thành dữ liệu cho Forward; nullopt khi scale suy biến. gain nhân vào màu.
[[nodiscard]] std::optional<render::FakeLight> fake_of(const FakeLight& fake, float gain) noexcept {
    const scene::Transform placed = scene::world_transform(fake.placement);
    const auto rows = render::fake_box_rows(placed.rows);
    if (!rows) return std::nullopt;
    render::FakeLight made;
    const scene::Vector3& origin = fake.placement.position;
    made.centre = math::Vector3(origin.x, origin.y, origin.z);
    made.radius = kBoxHalf * widest_scale(fake.placement.scale) * std::numbers::sqrt3_v<float>;
    made.rows = *rows;
    const float power = fake.intensity * gain;
    made.color = {.x = fake.colour.red * power, .y = fake.colour.green * power,
        .z = fake.colour.blue * power, .w = fake.size};
    return made;
}

[[nodiscard]] render::FogKind fog_kind_of(FogMode mode) noexcept {
    switch (mode) {
    case FogMode::kExp: return render::FogKind::kExp;
    case FogMode::kExp2: return render::FogKind::kExp2;
    case FogMode::kLinear: return render::FogKind::kLinear;
    case FogMode::kNone: return render::FogKind::kNone;
    }
    std::unreachable();
}

// Số của tệp cảnh: nhân vật nhận cùng ambient và cùng màu đèn với cảnh.
void take_scene(render::Lighting& lighting, const Stage& stage) noexcept {
    lighting.ambient = vector_of(stage.ambient);
    lighting.actor_ambient = lighting.ambient;
    lighting.fog.kind = fog_kind_of(stage.fog.mode);
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
    if (!stage.height_fog) return;
    const HeightFog& fog = *stage.height_fog;
    lighting.hfog = {fog.density, fog.height, fog.height_falloff, fog.pow_factor};
    lighting.dfog = {fog.depth_density, fog.depth_falloff, fog.depth_start, 0.0F};
    lighting.hfog_color = {fog.color_r, fog.color_g, fog.color_b, 1.0F};
    lighting.hfog_scatter = {fog.scatter_r, fog.scatter_g, fog.scatter_b, fog.inscatter};
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

[[nodiscard]] Rgb rgb_of(const ensky::Colour& colour) noexcept {
    return {.red = colour.red, .green = colour.green, .blue = colour.blue};
}

// Mốc EnvKey của EnScene thành DayKey: cùng các trường ánh sáng mà take_day áp.
[[nodiscard]] DayKey day_of(const ensky::EnvKey& env) noexcept {
    DayKey day;
    day.time = env.time;
    day.ambient = rgb_of(env.ambient);
    day.fog = rgb_of(env.fog);
    day.fog_near = env.fog_near;
    day.fog_far = env.fog_far;
    day.light_one = rgb_of(env.light_one);
    day.light_one_specular = rgb_of(env.light_one_specular);
    day.light_two = rgb_of(env.light_two);
    day.light_two_specular = rgb_of(env.light_two_specular);
    day.actor_one = rgb_of(env.actor_one);
    day.actor_two = rgb_of(env.actor_two);
    day.actor_ambient = rgb_of(env.actor_ambient);
    day.light_one_power = env.light_one_intensity;
    day.light_two_power = env.light_two_intensity;
    day.actor_one_power = env.actor_one_intensity;
    day.actor_two_power = env.actor_two_intensity;
    return day;
}

// Sương chiều cao của EnvKey thay cho tệp .hfog: cùng bộ số, thứ tự khác (xem ensky::EnvKey).
void take_height_fog(render::Lighting& lighting, const ensky::EnvKey& env) noexcept {
    const std::array<float, 16>& param = env.height_fog;
    const float is_on = env.has_height_fog ? 1.0F : 0.0F;
    lighting.hfog = {param[8], param[9], param[10], param[11]};
    lighting.dfog = {param[12], param[13], param[14], 0.0F};
    lighting.hfog_color = {param[0], param[1], param[2], is_on};
    lighting.hfog_scatter = {param[4], param[5], param[6], param[15]};
}

[[nodiscard]] bool is_aimed(const ogre::Vec3& ray) noexcept {
    return ray.x != 0.0F || ray.y != 0.0F || ray.z != 0.0F;
}

// Hướng đèn của EnvKey chỉ áp khi khác (0 0 0); không thì giữ hướng của tệp .Scene (0x1801e8130).
void take_aim(render::Lighting& lighting, const ensky::EnvKey& env) noexcept {
    const scene::Vector3 one{.x = env.light_one_direction.x, .y = env.light_one_direction.y,
        .z = env.light_one_direction.z};
    const scene::Vector3 two{.x = env.light_two_direction.x, .y = env.light_two_direction.y,
        .z = env.light_two_direction.z};
    if (is_aimed(env.light_one_direction)) lighting.suns[0].toward = toward_of(one);
    if (is_aimed(env.light_two_direction)) lighting.suns[1].toward = toward_of(two);
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
    finish(stage, 1.0F);
}

SceneLight::SceneLight(const Stage& stage, const ensky::EnvKey& env) {
    take_scene(base_, stage);
    take_day(base_, day_of(env));
    take_aim(base_, env);
    take_height_fog(base_, env);
    finish(stage, env.fake_light_intensity);
}

void SceneLight::finish(const Stage& stage, float fake_gain) {
    lamps_.reserve(stage.lamps.size());
    for (const Lamp& lamp : stage.lamps) {
        lamps_.push_back(lamp_of(lamp));
    }
    // FakeLight (0x18010d780): chỉ sáng khi độ sáng cảnh nằm trong [begin, end] của từng đèn.
    const float brightness = scene_brightness(base_);
    for (const FakeLight& fake : stage.fakes) {
        const bool is_on = fake.begin_brightness <= brightness && brightness <= fake.end_brightness;
        if (!is_on) continue;
        const std::optional<render::FakeLight> made = fake_of(fake, fake_gain);
        if (made) fakes_.push_back(*made);
    }
    const bool has_colour = stage.fog.mode != FogMode::kNone;
    backdrop_ = has_colour ? vector_of(stage.fog.colour) : vector_of(stage.background);
}

render::Lighting SceneLight::view() const noexcept {
    render::Lighting lighting = base_;
    lighting.lamps = lamps_;
    lighting.fakes = fakes_;
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
