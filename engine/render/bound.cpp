/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/bound.cpp
 *  PHÂN HỆ   : Render / Bound
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt render/bound.hpp. Hộp qua ma trận dùng tâm và nửa cạnh với trị
 *    tuyệt đối của phần tuyến tính: đúng hộp của tám góc, kể cả ma trận xiên.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
#include "render/bound.hpp"

#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <span>

namespace game::render {
namespace {

[[nodiscard]] math::Vector3 position_of(const resource::Vertex& vertex) noexcept {
    return {vertex.position.x, vertex.position.y, vertex.position.z};
}

void add_point(math::Aabb& box, const math::Vector3& point) noexcept {
    box.min = math::min(box.min, point);
    box.max = math::max(box.max, point);
}

void add_box(math::Aabb& box, const math::Aabb& other) noexcept {
    if (is_empty(other)) return;
    box.min = math::min(box.min, other.min);
    box.max = math::max(box.max, other.max);
}

[[nodiscard]] bool is_weight(float weight) noexcept {
    return std::isfinite(weight) && weight >= 0.0F;
}

[[nodiscard]] bool is_finite(const resource::Vertex& vertex) noexcept {
    const math::Float3& place = vertex.position;
    return std::isfinite(place.x) && std::isfinite(place.y) && std::isfinite(place.z);
}

// Gộp đỉnh vào hộp của các khớp nó có trọng số dương. Sai khi đỉnh làm mất tính lồi.
[[nodiscard]] bool add_vertex(SkinBox& bound, const resource::Vertex& vertex) noexcept {
    const math::Float4& raw = vertex.weights;
    const std::array<float, 4> weights{raw.x, raw.y, raw.z, raw.w};
    if (!is_finite(vertex)) return false;
    if (!std::ranges::all_of(weights, is_weight)) return false;
    const math::Vector3 point = position_of(vertex);
    const float total = weights[0] + weights[1] + weights[2] + weights[3];
    // Tổng là số subnormal: GPU xả về 0 thì shader để yên đỉnh, nên đỉnh vào cả hộp đứng yên.
    if (total < std::numeric_limits<float>::min()) add_point(bound.still, point);
    const auto last = static_cast<std::uint16_t>(bound.joints.size() - 1);
    for (std::size_t slot = 0; slot < weights.size(); ++slot) {
        if (weights.at(slot) <= 0.0F) continue;
        const std::uint16_t joint = std::min(vertex.joints.at(slot), last);
        add_point(bound.joints.at(joint), point);
    }
    return true;
}

[[nodiscard]] bool add_part(SkinBox& bound, const resource::Primitive& part) noexcept {
    for (const resource::Vertex& vertex : part.vertices) {
        if (!add_vertex(bound, vertex)) return false;
    }
    return true;
}

// Mặt (a, b, c, d) có phía trong ax + by + cz + d >= 0. Góc gần mặt nhất cách tâm |n| · half theo
// pháp tuyến, nên hộp nằm hẳn ngoài khi cả góc ấy còn ở phía ngoài. Sai số làm tròn float (cỡ 1e-7
// tương đối) không đủ đẩy một đỉnh qua tâm điểm ảnh ở mép, vốn cách mặt nửa điểm ảnh.
[[nodiscard]] bool is_outside(const math::Vector4& plane, const math::Aabb& box) noexcept {
    const math::Vector3 centre = (box.min + box.max) * 0.5F;
    const math::Vector3 half = (box.max - box.min) * 0.5F;
    const math::Vector3 normal = plane.xyz();
    const float reach = math::dot(math::abs(normal), half);
    return math::dot(normal, centre) + plane.w() < -reach;
}

} // namespace

bool is_empty(const math::Aabb& box) noexcept {
    const bool is_flipped_x = box.min.x() > box.max.x();
    const bool is_flipped_y = box.min.y() > box.max.y();
    return is_flipped_x || is_flipped_y || box.min.z() > box.max.z();
}

math::Aabb box_of(std::span<const resource::Vertex> vertices) noexcept {
    math::Aabb box;
    for (const resource::Vertex& vertex : vertices) {
        add_point(box, position_of(vertex));
    }
    return box;
}

math::Aabb moved_box(const math::Aabb& box, const math::Matrix4& matrix) noexcept {
    if (is_empty(box)) return box;
    const math::Vector3 centre = (box.min + box.max) * 0.5F;
    const math::Vector3 half = (box.max - box.min) * 0.5F;
    const math::Vector3 moved = (matrix * math::Point3(centre)).xyz();
    const math::Matrix3 stretch = math::abs(matrix.upper3x3());
    const math::Vector3 reach = stretch * half;
    return {.min = moved - reach, .max = moved + reach};
}

SkinBox skin_box(std::span<const resource::Primitive> parts, std::uint32_t joint_count) {
    SkinBox bound;
    if (joint_count == 0 || joint_count > std::numeric_limits<std::uint16_t>::max()) return bound;
    bound.joints.assign(joint_count, math::Aabb{});
    for (const resource::Primitive& part : parts) {
        if (!add_part(bound, part)) return {};
    }
    bound.is_bounded = true;
    return bound;
}

std::optional<math::Aabb> posed_box(const SkinBox& bound,
    std::span<const math::Matrix4> joints) noexcept {
    const bool is_usable = bound.is_bounded && joints.size() == bound.joints.size();
    if (!is_usable) return std::nullopt;
    math::Aabb posed = bound.still;
    for (std::size_t joint = 0; joint < joints.size(); ++joint) {
        const math::Aabb moved = moved_box(bound.joints[joint], joints[joint]);
        add_box(posed, moved);
    }
    return posed;
}

bool box_seen(const Frustum& frustum, const math::Aabb& box) noexcept {
    if (is_empty(box)) return false;
    const auto outside = [&box](const math::Vector4& plane) { return is_outside(plane, box); };
    return std::ranges::none_of(frustum.planes, outside);
}

} // namespace game::render

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
