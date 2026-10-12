// Test của toán vô hướng theo OGRE 1.2.5 (ogre/vec3, ogre/quat): vector, xoay vector bằng
// quaternion, thứ tự ghép, nghịch đảo, chuẩn hoá, nlerp hai chiều và quaternion từ góc-trục. Quy
// ước tay phải của OGRE là thứ asset gốc dựng theo: sai chiều là cả nhân vật quay ngược.
// Nguồn: TLBB Dev tests/math/math_test.cpp@e0d89a6 (phần vector và quaternion). Khác gốc: khung
// test của dự án (Context::expect), tên biến dài hơn ba ký tự, hậu tố F, enumerator Arc mang tiền
// tố k.
#include "core/check.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <numbers>

namespace game::test {
namespace {

using ogre::Arc;
using ogre::Quat;
using ogre::Vec3;

constexpr float kLoose = 1e-5F;

[[nodiscard]] bool near_value(float left, float right, float tolerance) {
    return std::abs(left - right) < tolerance;
}

[[nodiscard]] bool near_vec3(Vec3 left, Vec3 right) {
    const bool is_xy = near_value(left.x, right.x, kLoose) && near_value(left.y, right.y, kLoose);
    return is_xy && near_value(left.z, right.z, kLoose);
}

[[nodiscard]] bool near_quat(Quat left, Quat right) {
    const bool is_xyz =
        near_vec3(Vec3{.x = left.x, .y = left.y, .z = left.z}, Vec3{.x = right.x, .y = right.y, .z = right.z});
    return is_xyz && near_value(left.w, right.w, kLoose);
}

void vectors(Context& context) {
    const Vec3 axis_x{.x = 1.0F, .y = 0.0F, .z = 0.0F};
    const Vec3 axis_y{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    const Vec3 axis_z = ogre::cross_vec3(axis_x, axis_y);
    context.expect(axis_z == Vec3{.x = 0.0F, .y = 0.0F, .z = 1.0F}, "x nhân có hướng y ra z");
    context.expect(ogre::dot_vec3(axis_x, axis_y) == 0.0F, "hai trục vuông góc");
    context.expect(ogre::add_vec3(axis_x, axis_y) == Vec3{.x = 1.0F, .y = 1.0F, .z = 0.0F}, "cộng");
    context.expect(ogre::sub_vec3(axis_x, axis_y) == Vec3{.x = 1.0F, .y = -1.0F, .z = 0.0F}, "trừ");
    context.expect(ogre::scale_vec3(axis_y, 3.0F) == Vec3{.x = 0.0F, .y = 3.0F, .z = 0.0F}, "nhân vô hướng");
    const Vec3 three_four{.x = 3.0F, .y = 4.0F, .z = 0.0F};
    context.expect(near_value(ogre::length_vec3(three_four), 5.0F, 1e-6F), "độ dài tam giác 3-4-5");
    const Vec3 unit = ogre::normalize_vec3(Vec3{.x = 0.0F, .y = 0.0F, .z = 7.0F});
    context.expect(unit == Vec3{.x = 0.0F, .y = 0.0F, .z = 1.0F}, "chuẩn hoá ra vector đơn vị");
    context.expect(ogre::normalize_vec3(Vec3{}) == Vec3{}, "vector 0 trả chính nó, không NaN");
    const Vec3 size{.x = 2.0F, .y = 3.0F, .z = 4.0F};
    const Vec3 factor{.x = 0.5F, .y = 2.0F, .z = -1.0F};
    const Vec3 product{.x = 1.0F, .y = 6.0F, .z = -4.0F};
    context.expect(ogre::mul_vec3(size, factor) == product, "nhân từng thành phần");
    const Vec3 ones{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    const Vec3 quotient{.x = 0.5F, .y = 1.0F / 3.0F, .z = 0.25F};
    context.expect(ogre::div_vec3(ones, size) == quotient, "chia từng thành phần");
}

// sin 45 độ: quaternion của một phần tư vòng quanh một trục có hai thành phần bằng nó.
[[nodiscard]] Quat quarter_about_y() {
    const float sine = std::sqrt(0.5F);
    return Quat{.x = 0.0F, .y = sine, .z = 0.0F, .w = sine};
}

[[nodiscard]] Quat quarter_about_x() {
    const float sine = std::sqrt(0.5F);
    return Quat{.x = sine, .y = 0.0F, .z = 0.0F, .w = sine};
}

// Quy ước tay phải của OGRE: một phần tư vòng quanh +y đưa +x sang -z.
void quat_rotation(Context& context) {
    const Quat quarter_y = quarter_about_y();
    const Quat quarter_x = quarter_about_x();
    const Vec3 axis_x{.x = 1.0F, .y = 0.0F, .z = 0.0F};
    context.expect(ogre::quat_rotate(Quat{}, axis_x) == axis_x, "quaternion đơn vị giữ nguyên");
    const Vec3 minus_z{.x = 0.0F, .y = 0.0F, .z = -1.0F};
    context.expect(near_vec3(ogre::quat_rotate(quarter_y, axis_x), minus_z), "quanh y: +x sang -z");
    const Vec3 axis_y{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    const Vec3 plus_z{.x = 0.0F, .y = 0.0F, .z = 1.0F};
    context.expect(near_vec3(ogre::quat_rotate(quarter_x, axis_y), plus_z), "quanh x: +y sang +z");
    const Quat half = ogre::quat_multiply(quarter_y, quarter_y);
    const Quat half_turn{.x = 0.0F, .y = 1.0F, .z = 0.0F, .w = 0.0F};
    context.expect(near_quat(half, half_turn), "hai phần tư là nửa vòng");
    const Vec3 minus_x{.x = -1.0F, .y = 0.0F, .z = 0.0F};
    context.expect(near_vec3(ogre::quat_rotate(half, axis_x), minus_x), "nửa vòng đưa +x sang -x");
}

// quat_multiply(a, b) xoay theo b trước: phép ghép không giao hoán, thứ tự sai là sai tư thế.
void quat_order(Context& context) {
    const Quat quarter_y = quarter_about_y();
    const Quat quarter_x = quarter_about_x();
    const Vec3 probe{.x = 0.25F, .y = 1.0F, .z = -2.0F};
    const Quat first = ogre::quat_multiply(quarter_y, quarter_x);
    const Vec3 composed = ogre::quat_rotate(first, probe);
    const Vec3 stepwise = ogre::quat_rotate(quarter_y, ogre::quat_rotate(quarter_x, probe));
    context.expect(near_vec3(composed, stepwise), "a nhân b là xoay b rồi a");
    const Quat second = ogre::quat_multiply(quarter_x, quarter_y);
    const Vec3 swapped = ogre::quat_rotate(second, probe);
    context.expect(!near_vec3(composed, swapped), "đổi thứ tự thì ra hướng khác");
}

void quat_inverse_normalize(Context& context) {
    const Quat quarter_y = quarter_about_y();
    const Quat back = ogre::quat_multiply(quarter_y, ogre::quat_inverse(quarter_y));
    context.expect(near_quat(back, Quat{}), "nhân với nghịch đảo ra đơn vị");
    const Quat longer{.x = 0.0F, .y = 2.0F, .z = 0.0F, .w = 2.0F};
    const Quat shrunk = ogre::quat_multiply(longer, ogre::quat_inverse(longer));
    context.expect(near_quat(shrunk, Quat{}), "nghịch đảo tổng quát chia cho bình phương độ dài");
    const Quat zero{.x = 0.0F, .y = 0.0F, .z = 0.0F, .w = 0.0F};
    context.expect(ogre::quat_inverse(zero) == zero, "nghịch đảo của 0 là 0, như OGRE");
    const Quat doubled{.x = 0.0F, .y = 0.0F, .z = 0.0F, .w = 2.0F};
    context.expect(near_quat(ogre::quat_normalize(doubled), Quat{}), "chuẩn hoá về độ dài 1");
    const Quat even = ogre::quat_normalize(Quat{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F});
    const Quat quarter{.x = 0.5F, .y = 0.5F, .z = 0.5F, .w = 0.5F};
    context.expect(near_quat(even, quarter), "chuẩn hoá chia đều bốn thành phần");
}

// Tham chiếu tính bằng double theo định nghĩa: nội suy tới q hoặc -q, bên nào tích vô hướng không
// âm, rồi chuẩn hoá.
[[nodiscard]] Quat nlerp_reference(double blend, Quat from, Quat finish) {
    const double sign = ogre::quat_dot(from, finish) < 0.0F ? -1.0 : 1.0;
    const auto mixed = [blend, sign](float start, float end) {
        const auto first = static_cast<double>(start);
        return first + (blend * ((sign * static_cast<double>(end)) - first));
    };
    const double axis_x = mixed(from.x, finish.x);
    const double axis_y = mixed(from.y, finish.y);
    const double axis_z = mixed(from.z, finish.z);
    const double scalar = mixed(from.w, finish.w);
    const double size = std::sqrt((((axis_x * axis_x) + (axis_y * axis_y)) + (axis_z * axis_z)) + (scalar * scalar));
    const auto part = [size](double value) { return static_cast<float>(value / size); };
    return Quat{.x = part(axis_x), .y = part(axis_y), .z = part(axis_z), .w = part(scalar)};
}

[[nodiscard]] Quat negated(Quat value) {
    return Quat{.x = -value.x, .y = -value.y, .z = -value.z, .w = -value.w};
}

void quat_nlerp_shortest(Context& context) {
    const Quat quarter_y = quarter_about_y();
    const Quat quarter_x = quarter_about_x();
    const Quat from{};
    const Quat start = ogre::quat_nlerp(0.0F, from, quarter_y, Arc::kShortest);
    context.expect(near_quat(start, from), "t = 0 ra điểm đầu");
    const Quat end = ogre::quat_nlerp(1.0F, from, quarter_y, Arc::kShortest);
    context.expect(near_quat(end, quarter_y), "t = 1 ra điểm cuối");
    const Quat mid = ogre::quat_nlerp(0.5F, from, quarter_y, Arc::kShortest);
    context.expect(near_quat(mid, nlerp_reference(0.5, from, quarter_y)), "t = 0,5 khớp tham chiếu");
    const float cosine = std::cos(0.25F * std::numbers::pi_v<float>);
    const Vec3 eighth = ogre::quat_rotate(mid, Vec3{.x = 1.0F, .y = 0.0F, .z = 0.0F});
    context.expect(near_vec3(eighth, Vec3{.x = cosine, .y = 0.0F, .z = -cosine}), "giữa đường 45 độ");
    const Quat flipped = negated(quarter_y);
    const Quat short_way = ogre::quat_nlerp(0.5F, from, flipped, Arc::kShortest);
    context.expect(near_quat(short_way, mid), "-q cùng phép xoay nên nlerp đi đường ngắn tới đó");
    const Quat minus_one{.x = 0.0F, .y = 0.0F, .z = 0.0F, .w = -1.0F};
    const Quat twin = ogre::quat_nlerp(0.5F, from, minus_one, Arc::kShortest);
    context.expect(twin == from, "q và -q trùng nhau: không ra 0, không NaN");
    const Quat quarter = ogre::quat_nlerp(0.25F, quarter_x, flipped, Arc::kShortest);
    const Quat wanted = nlerp_reference(0.25, quarter_x, flipped);
    context.expect(near_quat(quarter, wanted), "t = 0,25 giữa hai trục");
}

// kDirect nội suy thẳng tới q dù tích vô hướng âm, như Quaternion::nlerp với shortestPath false mà
// OGRE dùng khi cộng dồn animation: đi đường dài, khác hẳn kShortest.
void quat_nlerp_direct(Context& context) {
    const Quat quarter_y = quarter_about_y();
    const Quat quarter_x = quarter_about_x();
    const Quat flipped = negated(quarter_y);
    const Quat direct = ogre::quat_nlerp(0.25F, quarter_x, flipped, Arc::kDirect);
    const Quat shortest = ogre::quat_nlerp(0.25F, quarter_x, flipped, Arc::kShortest);
    context.expect(!near_quat(direct, shortest), "tích vô hướng âm thì hai cách ra khác nhau");
    const float keep = 1.0F - 0.25F;
    const Quat raw{.x = (keep * quarter_x.x) + (0.25F * flipped.x),
        .y = (keep * quarter_x.y) + (0.25F * flipped.y),
        .z = (keep * quarter_x.z) + (0.25F * flipped.z),
        .w = (keep * quarter_x.w) + (0.25F * flipped.w)};
    context.expect(near_quat(direct, ogre::quat_normalize(raw)), "nội suy thẳng tới q rồi chuẩn hoá");
    const Quat same = ogre::quat_nlerp(0.5F, Quat{}, quarter_y, Arc::kDirect);
    const Quat same_short = ogre::quat_nlerp(0.5F, Quat{}, quarter_y, Arc::kShortest);
    context.expect(same == same_short, "tích vô hướng dương thì hai cách như nhau");
}

// Quaternion::FromAngleAxis: nửa góc, w = cos, phần vector = sin nhân trục. Quay mặt 90 độ quanh +y
// đưa hướng +z sang +x, khớp quy ước hướng mặt atan2(dx, dz).
void quat_angle_axis(Context& context) {
    const Vec3 up_axis{.x = 0.0F, .y = 1.0F, .z = 0.0F};
    const Quat quarter = ogre::quat_from_angle_axis(std::numbers::pi_v<float> / 2, up_axis);
    context.expect(near_quat(quarter, quarter_about_y()), "một phần tư vòng quanh y");
    const Vec3 turned = ogre::quat_rotate(quarter, Vec3{.x = 0.0F, .y = 0.0F, .z = 1.0F});
    context.expect(near_vec3(turned, Vec3{.x = 1.0F, .y = 0.0F, .z = 0.0F}), "quay 90 độ: +z sang +x");
    context.expect(near_quat(ogre::quat_from_angle_axis(0.0F, up_axis), Quat{}), "góc 0 là đơn vị");
}

constexpr std::array kCases{
    Case{.name = "vectors", .body = &vectors},
    Case{.name = "quat_rotation", .body = &quat_rotation},
    Case{.name = "quat_order", .body = &quat_order},
    Case{.name = "quat_inverse_normalize", .body = &quat_inverse_normalize},
    Case{.name = "quat_nlerp_shortest", .body = &quat_nlerp_shortest},
    Case{.name = "quat_nlerp_direct", .body = &quat_nlerp_direct},
    Case{.name = "quat_angle_axis", .body = &quat_angle_axis},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ogre_tests: mọi ca phải qua");
    return 0;
}
