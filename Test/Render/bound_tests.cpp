// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
// Test của render/bound: hộp qua ma trận xiên bằng hộp của tám góc, hộp theo khớp chứa mọi đỉnh mà
// model.vs đưa ra ở tư thế bất kỳ (kể cả đỉnh không trọng số và chỉ số khớp vượt skin), lưới có
// trọng số âm không có hộp, và phép loại hộp theo khung nhìn.
#include "core/check.hpp"
#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "render/bound.hpp"
#include "render/camera.hpp"
#include "render/view_size.hpp"
#include "resource/model.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <vector>

namespace game::test {
namespace {

using math::Matrix3;
using math::Matrix4;
using math::Point3;
using math::Vector3;

[[nodiscard]] bool near_value(float left, float right) noexcept {
    return std::abs(left - right) <= 1.0e-4F * (1.0F + std::abs(right));
}

[[nodiscard]] bool same_box(const math::Aabb& left, const math::Aabb& right) noexcept {
    const bool is_low = near_value(left.min.x(), right.min.x()) &&
        near_value(left.min.y(), right.min.y()) && near_value(left.min.z(), right.min.z());
    const bool is_high = near_value(left.max.x(), right.max.x()) &&
        near_value(left.max.y(), right.max.y()) && near_value(left.max.z(), right.max.z());
    return is_low && is_high;
}

// Điểm nằm trong hộp, cho phép sai số làm tròn tương đối.
[[nodiscard]] bool holds(const math::Aabb& box, const Vector3& point) noexcept {
    const Vector3 slack = (math::abs(box.min) + math::abs(box.max)) * 1.0e-5F;
    const Vector3 low = box.min - slack;
    const Vector3 high = box.max + slack;
    const bool is_above = point.x() >= low.x() && point.y() >= low.y() && point.z() >= low.z();
    return is_above && point.x() <= high.x() && point.y() <= high.y() && point.z() <= high.z();
}

// Ma trận affine có quay, tỉ lệ không đều và xiên: max độ dài cột không còn là hệ số giãn.
[[nodiscard]] Matrix4 sheared(float turn, const Vector3& offset) {
    const Matrix3 shear(Vector3(1.0F, 0.0F, 0.0F), Vector3(0.8F, 1.0F, 0.0F), Vector3(0.0F, -0.5F, 2.0F));
    const Matrix3 turned = Matrix3::rotation_zyx(Vector3(turn, 0.7F * turn, -0.3F * turn)) * shear;
    return Matrix4(turned, offset);
}

[[nodiscard]] resource::Vertex vertex_at(const Vector3& place, std::array<std::uint16_t, 4> joints,
    math::Float4 weights) {
    resource::Vertex vertex;
    vertex.position = {.x = place.x(), .y = place.y(), .z = place.z()};
    vertex.joints = joints;
    vertex.weights = weights;
    return vertex;
}

// Vị trí model.vs ra cho một đỉnh: tổng trọng số không dương thì đứng yên, chỉ số khớp kẹp vào skin.
[[nodiscard]] Vector3 skinned(const resource::Vertex& vertex, const std::vector<Matrix4>& joints) {
    const Point3 local(vertex.position.x, vertex.position.y, vertex.position.z);
    const std::array<float, 4> weights{vertex.weights.x, vertex.weights.y, vertex.weights.z, vertex.weights.w};
    const float total = weights[0] + weights[1] + weights[2] + weights[3];
    if (!(total > 0.0F)) return Vector3(local);
    Vector3 sum(0.0F);
    const std::size_t last = joints.size() - 1;
    for (std::size_t slot = 0; slot < weights.size(); ++slot) {
        const std::size_t joint = std::min<std::size_t>(vertex.joints.at(slot), last);
        const Vector3 moved = (joints.at(joint) * local).xyz();
        sum += moved * weights.at(slot);
    }
    return sum / total;
}

// Lưới hai primitive, ba khớp: đỉnh một khớp, đỉnh chia hai khớp, đỉnh không trọng số, và đỉnh mang
// chỉ số khớp 9 (shader kẹp về khớp cuối).
[[nodiscard]] std::vector<resource::Primitive> arm_parts() {
    resource::Primitive upper;
    upper.vertices.push_back(vertex_at(Vector3(0.0F, 0.0F, 0.0F), {0, 0, 0, 0}, {.x = 1.0F}));
    upper.vertices.push_back(vertex_at(Vector3(0.0F, 4.0F, 1.0F), {0, 1, 0, 0}, {.x = 0.3F, .y = 0.7F}));
    upper.vertices.push_back(vertex_at(Vector3(2.0F, 1.0F, 0.0F), {0, 1, 2, 0}, {}));
    resource::Primitive lower;
    lower.vertices.push_back(vertex_at(Vector3(0.0F, 8.0F, -1.0F), {1, 2, 0, 0}, {.x = 2.0F, .y = 2.0F}));
    lower.vertices.push_back(vertex_at(Vector3(1.0F, 9.0F, 0.5F), {9, 0, 0, 0}, {.x = 1.0F}));
    lower.vertices.push_back(vertex_at(Vector3(-1.0F, 7.0F, 0.0F), {2, 1, 0, 3}, {.x = 0.5F, .w = 0.5F}));
    return {upper, lower};
}

void moved_box_matches_corners(Context& context) {
    const math::Aabb box{.min = Vector3(-1.0F, 2.0F, -3.0F), .max = Vector3(4.0F, 5.0F, 0.5F)};
    const Matrix4 matrix = sheared(0.9F, Vector3(10.0F, -2.0F, 3.0F));
    const math::Aabb fast = render::moved_box(box, matrix);
    const math::Aabb corners = math::transform(box, matrix);
    context.expect(same_box(fast, corners), "hộp qua ma trận xiên bằng hộp của tám góc");
    const math::Aabb empty{};
    context.expect(render::is_empty(render::moved_box(empty, matrix)), "hộp rỗng vẫn rỗng");
}

void posed_box_holds_every_vertex(Context& context) {
    const std::vector<resource::Primitive> parts = arm_parts();
    const render::SkinBox bound = render::skin_box(parts, 3);
    context.expect(bound.is_bounded, "trọng số không âm thì có hộp");
    context.expect(bound.joints.size() == 3, "một hộp cho mỗi khớp");
    for (int pose = 0; pose < 8; ++pose) {
        const float turn = 0.4F * static_cast<float>(pose);
        const Vector3 offset(static_cast<float>(pose) * 5.0F, -3.0F, 2.0F);
        const std::vector<Matrix4> joints{sheared(turn, offset), sheared(-turn, -offset),
            Matrix4::scale(Vector3(0.5F, 3.0F, 1.0F))};
        const std::optional<math::Aabb> posed = render::posed_box(bound, joints);
        context.expect(posed.has_value(), "đủ khớp thì có hộp tư thế");
        if (!posed) continue;
        for (const resource::Primitive& part : parts) {
            for (const resource::Vertex& vertex : part.vertices) {
                context.expect(holds(*posed, skinned(vertex, joints)), "đỉnh nằm trong hộp tư thế");
            }
        }
    }
}

void still_vertex_stays_in_box(Context& context) {
    resource::Primitive part;
    part.vertices.push_back(vertex_at(Vector3(5.0F, 6.0F, 7.0F), {0, 0, 0, 0}, {}));
    const std::array parts{part};
    const render::SkinBox bound = render::skin_box(parts, 1);
    const std::vector<Matrix4> far_away{Matrix4::translation(Vector3(1000.0F, 0.0F, 0.0F))};
    const std::optional<math::Aabb> posed = render::posed_box(bound, far_away);
    const bool is_held = posed && holds(*posed, Vector3(5.0F, 6.0F, 7.0F));
    context.expect(is_held, "đỉnh không trọng số đứng yên, khớp đi xa không kéo hộp theo");
}

void negative_weight_has_no_box(Context& context) {
    resource::Primitive part;
    part.vertices.push_back(vertex_at(Vector3(0.0F, 0.0F, 0.0F), {0, 1, 0, 0}, {.x = 1.5F, .y = -0.5F}));
    const std::array parts{part};
    const render::SkinBox bound = render::skin_box(parts, 2);
    context.expect(!bound.is_bounded, "trọng số âm thì không bảo đảm");
    const std::vector<Matrix4> joints(2, Matrix4::identity());
    context.expect(!render::posed_box(bound, joints), "không có hộp tư thế");
    const render::SkinBox none = render::skin_box(parts, 0);
    context.expect(!none.is_bounded, "skin không khớp nào thì không có hộp");
    const std::vector<resource::Primitive> arm = arm_parts();
    const render::SkinBox good = render::skin_box(arm, 3);
    context.expect(!render::posed_box(good, joints), "thiếu khớp thì không có hộp tư thế");
}

void box_seen_by_frustum(Context& context) {
    render::Lens lens;
    lens.fov_degrees = 60.0F;
    lens.near_plane = 1.0F;
    lens.far_plane = 100.0F;
    const render::ViewSize square{.width = 100, .height = 100};
    const Point3 eye(0.0F, 0.0F, 0.0F);
    const Point3 ahead(0.0F, 0.0F, -10.0F);
    const render::Camera camera = render::look_camera(eye, ahead, lens, square);
    const render::Frustum frustum = render::frustum_of(camera.projection * camera.view);
    const Vector3 unit(1.0F);
    const auto cube = [&unit](const Vector3& centre) { return math::Aabb{.min = centre - unit, .max = centre + unit}; };
    context.expect(render::box_seen(frustum, cube(Vector3(0.0F, 0.0F, -10.0F))), "hộp trước mắt");
    context.expect(!render::box_seen(frustum, cube(Vector3(0.0F, 0.0F, 10.0F))), "hộp sau lưng");
    context.expect(!render::box_seen(frustum, cube(Vector3(-50.0F, 0.0F, -10.0F))), "hộp lệch trái");
    context.expect(render::box_seen(frustum, cube(Vector3(-6.5F, 0.0F, -10.0F))), "hộp cắt mặt trái");
    context.expect(!render::box_seen(frustum, cube(Vector3(0.0F, 0.0F, -150.0F))), "hộp quá mặt xa");
    context.expect(!render::box_seen(frustum, math::Aabb{}), "hộp rỗng không thấy");
    // Hộp dẹt dài nằm ngang trước mắt: tâm lệch xa nhưng thân cắt khung nhìn.
    const math::Aabb wall{.min = Vector3(-200.0F, -1.0F, -21.0F), .max = Vector3(-5.0F, 1.0F, -19.0F)};
    context.expect(render::box_seen(frustum, wall), "tường dài cắt khung nhìn");
}

constexpr std::array kCases{
    Case{.name = "moved_box_matches_corners", .body = &moved_box_matches_corners},
    Case{.name = "posed_box_holds_every_vertex", .body = &posed_box_holds_every_vertex},
    Case{.name = "still_vertex_stays_in_box", .body = &still_vertex_stays_in_box},
    Case{.name = "negative_weight_has_no_box", .body = &negative_weight_has_no_box},
    Case{.name = "box_seen_by_frustum", .body = &box_seen_by_frustum},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "bound_tests: mọi ca phải qua");
    return 0;
}

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
