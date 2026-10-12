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
#include "resource/classic.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <cstdint>
#include <limits>
#include <span>
#include <vector>

namespace game::render {
namespace {

[[nodiscard]] math::Float4 rgb_and(const math::Vector3& color, float last) noexcept {
    return math::store(math::Vector4(color, last));
}

// Hệ số nhân màu texture của BLEND_OP_0 (Diffuse.inc của bản gốc).
[[nodiscard]] float scale_of(resource::TexOp combine) noexcept {
    if (combine == resource::TexOp::kModulate2) return 2.0F;
    if (combine == resource::TexOp::kModulate4) return 4.0F;
    return 1.0F;
}

[[nodiscard]] bool has_color(const math::Vector3& color) noexcept {
    return color.x() > 0.0F || color.y() > 0.0F || color.z() > 0.0F;
}

// Bit của chất liệu OGRE; chất liệu không mang Classic giữ cách vẽ cũ (nhân màu đỉnh).
[[nodiscard]] std::uint32_t classic_flags(const resource::Classic& classic) noexcept {
    std::uint32_t flags = 0;
    const bool is_terrain = classic.lit == resource::Lit::kTerrain;
    if (classic.lit == resource::Lit::kPixel || is_terrain) flags |= kPixelLit;
    if (is_terrain) flags |= kRawSum;
    if (!classic.has_fog) flags |= kNoFog;
    if (classic.combine == resource::TexOp::kAdd) flags |= kAddLight;
    if (classic.tracks_vertex) flags |= kVertexColor;
    return flags;
}

// Màu nền, ngưỡng alpha và cờ unlit của glTF. Chất liệu mang Classic thì theo luật của OGRE: bộ
// chuyển ghi "lighting off" thành unlit, nhưng shader gốc vẫn nhân ánh sáng ở đỉnh cho pass ấy.
void take_gltf(Shade& shade, const resource::Material& material) noexcept {
    const bool is_specular = material.shading == resource::Shading::kSpecular;
    const bool is_masked = material.alpha == resource::Alpha::kMask;
    shade.base_color = is_specular ? material.diffuse : material.base_color;
    shade.diffuse.w = is_masked ? material.alpha_cutoff : 0.0F;
    if (material.unlit && !material.classic) shade.flags |= kUnlit;
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
    const resource::Classic plain;
    const resource::Material* material = ask.material;
    const bool has_classic = material != nullptr && material->classic.has_value();
    const resource::Classic& classic = has_classic ? *material->classic : plain;
    const Lighting& lighting = *ask.lighting;
    Shade shade;
    if (material != nullptr) take_gltf(shade, *material);
    const math::Vector3 ambient = ask.is_actor ? lighting.actor_ambient : lighting.ambient;
    const math::Vector3 glow = math::mul(ambient, math::load(classic.ambient));
    const math::Vector3 shine = math::mul(math::load(classic.specular), lighting.specular);
    const bool is_shiny = classic.lit != resource::Lit::kOff && has_color(shine);
    const float scale = scale_of(classic.combine);
    shade.glow = rgb_and(glow + math::load(classic.emissive), classic.shininess);
    shade.diffuse.x = classic.diffuse.x;
    shade.diffuse.y = classic.diffuse.y;
    shade.diffuse.z = classic.diffuse.z;
    shade.specular = rgb_and(shine, 0.0F);
    shade.base_color.x *= scale;
    shade.base_color.y *= scale;
    shade.base_color.z *= scale;
    shade.base_color.w *= classic.diffuse.w;
    shade.flags |= has_classic ? classic_flags(classic) : kVertexColor;
    if (is_shiny) shade.flags |= kSpecular;
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

} // namespace game::render

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
