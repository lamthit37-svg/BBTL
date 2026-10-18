// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
#include "render/shade.hpp"

#include "core/check.hpp"
#include "math/matrix.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "render/forward.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <span>
#include <vector>

namespace game::render {
namespace {

// Shader gốc nhân vị trí trong hộp (nửa cạnh 50) với 0,01.
constexpr double kBoxToUnit = 0.01;

[[nodiscard]] float unit_of(double value) noexcept {
    return static_cast<float>(value * kBoxToUnit);
}

// Một hàng của nghịch đảo kèm phần dịch -A^-1 t, đã nhân 0,01.
[[nodiscard]] math::Float4 box_row(const std::array<double, 4>& line,
    const WorldRows& world) noexcept {
    const double along_x = line[0] * world[0][3];
    const double along_y = line[1] * world[1][3];
    const double along_z = line[2] * world[2][3];
    return {.x = unit_of(line[0]), .y = unit_of(line[1]), .z = unit_of(line[2]),
        .w = unit_of(-(along_x + along_y + along_z))};
}

[[nodiscard]] math::Float4 rgb_and(const math::Vector3& color, float last) noexcept {
    return math::store(math::Vector4(color, last));
}

[[nodiscard]] bool has_color(const math::Vector3& color) noexcept {
    return color.x() > 0.0F || color.y() > 0.0F || color.z() > 0.0F;
}

// Tấm scene_blend add hay zero one_minus_src_colour có ảnh mặt nạ: shader nhân ảnh thứ hai.
[[nodiscard]] bool is_add_sheet(const resource::Material& material) noexcept {
    const bool is_add = material.alpha == resource::Alpha::kAdd;
    const bool is_dark = material.alpha == resource::Alpha::kDarken;
    const bool is_sheet = is_add || is_dark;
    return is_sheet && material.surface.image.has_value();
}

// Màu nền và ngưỡng alpha của glTF. Pass do người gọi điền thì unlit của glTF không áp.
void take_gltf(Shade& shade, const resource::Material& material) noexcept {
    const bool is_specular = material.shading == resource::Shading::kSpecular;
    const bool is_masked = material.alpha == resource::Alpha::kMask;
    shade.base_color = is_specular ? material.diffuse : material.base_color;
    shade.diffuse.w = is_masked ? material.alpha_cutoff : 0.0F;
    if (material.unlit && !material.pass) shade.flags |= kUnlit;
    if (is_add_sheet(material)) shade.flags |= kMaskTex;
    if (material.suppress_fog) shade.flags |= kNoFog;
}

// Thác OGRE không đèn: emissive.xy là tốc độ scroll_anim, shader trừ khỏi UV theo giây của khung
// như Ogre (ScaleControllerFunction(-speed)).
void take_scroll(Shade& shade, const resource::Material& material) noexcept {
    if ((shade.flags & kUnlit) == 0) return;
    shade.specular.x = material.emissive.x;
    shade.specular.y = material.emissive.y;
}

void take_pass(Shade& shade, const resource::Material::Pass& pass, const Lighting& lighting,
    const math::Vector3& ambient) noexcept {
    const math::Vector3 glow = math::mul(ambient, math::load(pass.ambient));
    const math::Vector3 shine = math::mul(math::load(pass.specular), lighting.specular);
    const bool is_shiny = pass.lit && has_color(shine);
    shade.glow = rgb_and(glow + math::load(pass.emissive), pass.shininess);
    shade.diffuse.x = pass.diffuse.x;
    shade.diffuse.y = pass.diffuse.y;
    shade.diffuse.z = pass.diffuse.z;
    shade.specular = rgb_and(shine, 0.0F);
    shade.base_color.x *= pass.color_scale;
    shade.base_color.y *= pass.color_scale;
    shade.base_color.z *= pass.color_scale;
    shade.base_color.w *= pass.diffuse.w;
    shade.flags |= pass.flags;
    if (is_shiny) shade.flags |= kSpecular;
}

struct Nearest {
    std::uint32_t lamp = kNoLamp;
    float squared = std::numeric_limits<float>::max();
};

struct Candidate {
    const Lamp* lamp = nullptr;
    std::uint32_t index = 0;
};

// Đèn còn với tới vật thể và gần hơn đèn đang giữ thì thay.
void consider_lamp(Nearest& nearest, Candidate candidate, const Reach& reach) noexcept {
    const Lamp& lamp = *candidate.lamp;
    if (lamp.range <= 0.0F) return;
    const math::Vector3 gap = lamp.position - reach.centre;
    const float squared = math::dot(gap, gap);
    const float limit = lamp.range + reach.radius;
    if (squared > limit * limit || squared >= nearest.squared) return;
    nearest.lamp = candidate.index;
    nearest.squared = squared;
}

} // namespace

Shade shade_of(const ShadeAsk& ask) noexcept {
    core::check(ask.lighting != nullptr, "shade_of cần ánh sáng của khung");
    const resource::Material* material = ask.material;
    const Lighting& lighting = *ask.lighting;
    Shade shade;
    if (material != nullptr) take_gltf(shade, *material);
    const math::Vector3 ambient = ask.is_actor ? lighting.actor_ambient : lighting.ambient;
    const bool has_pass = material != nullptr && material->pass.has_value();
    if (has_pass) take_pass(shade, *material->pass, lighting, ambient);
    if (!has_pass) shade.glow = rgb_and(ambient, 0.0F);
    if (!has_pass) shade.flags |= kVertexColor;
    if (material != nullptr) take_scroll(shade, *material);
    if (ask.is_actor) shade.flags |= kActor;
    return shade;
}

std::uint32_t nearest_lamp(std::span<const Lamp> lamps, const Reach& reach) noexcept {
    Nearest nearest;
    for (std::uint32_t index = 0; index < lamps.size(); ++index) {
        const Candidate candidate{.lamp = &lamps[index], .index = index};
        consider_lamp(nearest, candidate, reach);
    }
    return nearest.lamp;
}

Reach reach_at(const math::Matrix4& world, float radius) noexcept {
    const float along_x = math::length(world.col0().xyz());
    const float along_y = math::length(world.col1().xyz());
    const float along_z = math::length(world.col2().xyz());
    return {.centre = world.col3().xyz(), .radius = radius * std::max({along_x, along_y, along_z})};
}

void see_copies(const CopyAsk& ask, const Frustum& frustum, std::vector<SeenCopy>& seen) {
    seen.clear();
    for (std::uint32_t index = 0; index < ask.copies.size(); ++index) {
        const Reach reach = reach_at(ask.copies[index], ask.radius);
        if (!sphere_in_view(frustum, reach.centre, reach.radius)) continue;
        seen.push_back(SeenCopy{.index = index, .lamp = nearest_lamp(ask.lamps, reach)});
    }
}

std::optional<BoxRows> fake_box_rows(const WorldRows& world) noexcept {
    const double a = world[0][0];
    const double b = world[0][1];
    const double c = world[0][2];
    const double d = world[1][0];
    const double e = world[1][1];
    const double f = world[1][2];
    const double g = world[2][0];
    const double h = world[2][1];
    const double i = world[2][2];
    const double cof00 = (e * i) - (f * h);
    const double cof01 = (f * g) - (d * i);
    const double cof02 = (d * h) - (e * g);
    const double det = (a * cof00) + (b * cof01) + (c * cof02);
    if (det == 0.0 || !std::isfinite(det)) return std::nullopt;
    const double scale = 1.0 / det;
    WorldRows inverse{};
    inverse[0] = {cof00 * scale, ((c * h) - (b * i)) * scale, ((b * f) - (c * e)) * scale, 0.0};
    inverse[1] = {cof01 * scale, ((a * i) - (c * g)) * scale, ((c * d) - (a * f)) * scale, 0.0};
    inverse[2] = {cof02 * scale, ((b * g) - (a * h)) * scale, ((a * e) - (b * d)) * scale, 0.0};
    BoxRows rows{};
    for (std::size_t row = 0; row < 3; ++row)
        rows[row] = box_row(inverse[row], world);
    return rows;
}

} // namespace game::render

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
