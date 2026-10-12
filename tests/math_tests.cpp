// Test của math: ma trận T * R * S và nghịch đảo, quaternion (x, y, z, w) sang ma trận, công thức
// đặt vật thể Matrix4(quaternion, tịnh tiến) * scale, hệ tay phải Y lên, hộp bao qua ma trận, phối
// cảnh độ sâu đảo, khối nhìn với hộp, tia với hộp và mặt phẳng, phân rã, Half (KT-01, KT-02).
// Mã được kiểm chép từ Forge2. Giá trị kỳ vọng tính tay từ công thức và đã khớp số đo trên bản
// chép. Phép tính không qua sin, cos, tan so bằng ==; phần còn lại dùng sai số tuyệt đối sát mức
// đã đo, chừa chỗ cho libm lệch nhau một ulp giữa các nền.
#include "core/check.hpp"
#include "math/cofactor.hpp"
#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/quat.hpp"
#include "math/scalar.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <limits>
#include <numbers>
#include <optional>
#include <span>

namespace game::test {
namespace {

using math::Aabb;
using math::AffineTransform;
using math::FovLens;
using math::Frustum;
using math::FrustumTest;
using math::Matrix3;
using math::Matrix4;
using math::Point3;
using math::Quat;
using math::Vector3;
using math::Vector4;
using math::ViewWindow;

// Hàm constexpr của math phải tính được lúc biên dịch.
static_assert(math::lerp(2.0F, 6.0F, 0.25F) == 3.0F);
static_assert(math::closest_pow2(5U) == 4U && math::closest_pow2(7U) == 8U);
static_assert(math::round_up<std::uint32_t>(13U, 8U) == 16U);
static_assert(math::to_half(1.0F).bits == 0x3C00 && math::to_half(-2.0F).bits == 0xC000);
static_assert(math::to_half(65520.0F).bits == 0x7C00, "từ 65520 trở lên là vô cùng");
static_assert(math::to_float(math::Half{0x3C00}) == 1.0F);

[[nodiscard]] constexpr double multiply(const double& left, const double& right) noexcept {
    return left * right;
}

// Ma trận chéo (2, 3, 4, 5): định thức 120, ma trận phụ hợp chéo (60, 40, 30, 24).
constexpr std::array<double, 4> kDiagonal0{2.0, 0.0, 0.0, 0.0};
constexpr std::array<double, 4> kDiagonal1{0.0, 3.0, 0.0, 0.0};
constexpr std::array<double, 4> kDiagonal2{0.0, 0.0, 4.0, 0.0};
constexpr std::array<double, 4> kDiagonal3{0.0, 0.0, 0.0, 5.0};
constexpr math::detail::Grid4<double> kDiagonal{kDiagonal0, kDiagonal1, kDiagonal2, kDiagonal3};
constexpr math::detail::Cofactors<double> kParts = math::detail::cofactors(kDiagonal, &multiply);
static_assert(kParts.determinant == 120.0);
static_assert(kParts.adjugate[0][0] == 60.0 && kParts.adjugate[1][1] == 40.0);
static_assert(kParts.adjugate[2][2] == 30.0 && kParts.adjugate[3][3] == 24.0);
static_assert(kParts.adjugate[0][1] == 0.0 && kParts.adjugate[3][0] == 0.0);

// So gần đúng theo sai số tuyệt đối: giá trị đo, giá trị kỳ vọng, rồi sai số,
// cùng thứ tự với near(a, b, tolerance) của math (ngoại lệ của API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
[[nodiscard]] bool is_close(float got, float want, float tolerance) noexcept {
    return std::abs(got - want) <= tolerance;
}

[[nodiscard]] bool is_close(const Vector3& got, const Vector3& want, float tolerance) noexcept {
    return math::near(math::store(got), math::store(want), tolerance);
}

[[nodiscard]] bool is_close(const Vector4& got, const Vector4& want, float tolerance) noexcept {
    return math::near(math::store(got), math::store(want), tolerance);
}

[[nodiscard]] bool is_close(const Quat& got, const Quat& want, float tolerance) noexcept {
    return math::near(math::store(got), math::store(want), tolerance);
}

[[nodiscard]] bool is_close(const Matrix3& got, const Matrix3& want, float tolerance) noexcept {
    const bool is_first_close = is_close(got.col0(), want.col0(), tolerance);
    const bool is_second_close = is_close(got.col1(), want.col1(), tolerance);
    const bool is_third_close = is_close(got.col2(), want.col2(), tolerance);
    return is_first_close && is_second_close && is_third_close;
}

[[nodiscard]] bool is_close(const Matrix4& got, const Matrix4& want, float tolerance) noexcept {
    const bool is_first_close = is_close(got.col0(), want.col0(), tolerance);
    const bool is_second_close = is_close(got.col1(), want.col1(), tolerance);
    const bool is_third_close = is_close(got.col2(), want.col2(), tolerance);
    const bool is_fourth_close = is_close(got.col3(), want.col3(), tolerance);
    return is_first_close && is_second_close && is_third_close && is_fourth_close;
}

[[nodiscard]] bool is_close(const Aabb& got, const Aabb& want, float tolerance) noexcept {
    return is_close(got.min, want.min, tolerance) && is_close(got.max, want.max, tolerance);
}
// NOLINTEND(bugprone-easily-swappable-parameters)

// Toạ độ NDC của point qua ma trận chiếu: chia cho w.
[[nodiscard]] Vector3 ndc(const Matrix4& projection, const Point3& point) noexcept {
    const Vector4 clip = projection * point;
    return clip.xyz() / clip.w();
}

// Ma trận T * R * S dùng chung cho nhiều ca:
// tịnh tiến (10, 20, 30), quay 90 độ quanh Z,
// tỉ lệ (2, 3, 4).
[[nodiscard]] Matrix4 placed_model() noexcept {
    const Matrix4 move = Matrix4::translation(Vector3(10.0F, 20.0F, 30.0F));
    const Matrix4 turn = Matrix4::rotation_z(math::kHalfPi);
    const Matrix4 size = Matrix4::scale(Vector3(2.0F, 3.0F, 4.0F));
    return move * turn * size;
}

// Hộp lập phương cạnh 1 quanh center.
[[nodiscard]] Aabb unit_box_at(const Vector3& center) noexcept {
    return {.min = center - Vector3(0.5F), .max = center + Vector3(0.5F)};
}

// Tên ngắn của aabb_touches_frustum cho các ca về khối nhìn.
[[nodiscard]] bool touches(const Aabb& box, const Frustum& view, FrustumTest test) noexcept {
    return math::aabb_touches_frustum(box, view, test);
}

[[nodiscard]] constexpr bool is_half_stable(std::uint32_t bits) noexcept {
    const math::Half half{static_cast<std::uint16_t>(bits)};
    const bool is_nan = (bits & 0x7C00U) == 0x7C00U && (bits & 0x03FFU) != 0;
    return is_nan || math::to_half(math::to_float(half)) == half;
}

// Số mẫu half (trừ NaN) đổi sang float rồi đổi lại
// không ra đúng mẫu bit cũ.
[[nodiscard]] std::uint32_t half_mismatches() noexcept {
    std::uint32_t mismatches = 0;
    for (std::uint32_t bits = 0; bits <= 0xFFFFU; ++bits) {
        mismatches += is_half_stable(bits) ? 0U : 1U;
    }
    return mismatches;
}

void trs_places_point_and_columns(Context& context) noexcept {
    const Matrix4 model = placed_model();
    const Vector4 moved = model * Point3(1.0F, 1.0F, 1.0F);
    const Vector4 landed(7.0F, 22.0F, 34.0F, 1.0F);
    context.expect(is_close(moved, landed, 1e-5F), "T * R * S đưa (1, 1, 1) tới (7, 22, 34)");
    const Vector4 col0(0.0F, 2.0F, 0.0F, 0.0F);
    const Vector4 col1(-3.0F, 0.0F, 0.0F, 0.0F);
    const Vector4 col2(0.0F, 0.0F, 4.0F, 0.0F);
    const Vector4 col3(10.0F, 20.0F, 30.0F, 1.0F);
    const Matrix4 expected(col0, col1, col2, col3);
    context.expect(is_close(model, expected, 1e-6F), "cột là trục đã quay nhân tỉ lệ");
    const float volume = math::determinant(model);
    context.expect(is_close(volume, 24.0F, 1e-4F), "định thức bằng tích ba tỉ lệ 2 * 3 * 4");
}

void trs_inverse_round_trips(Context& context) noexcept {
    const Matrix4 model = placed_model();
    const Matrix4 identity = Matrix4::identity();
    const Matrix4 inverted = math::inverse(model);
    const Matrix4 product = inverted * model;
    context.expect(is_close(product, identity, 1e-5F), "inverse(M) * M là ma trận đơn vị");
    const Matrix4 affine = math::affine_inverse(model);
    context.expect(is_close(affine, inverted, 1e-5F), "affine_inverse khớp inverse");
    const Matrix4 flipped = math::transpose(model);
    const Matrix4 restored = math::transpose(flipped);
    context.expect(restored == model, "chuyển vị hai lần ra đúng ma trận cũ");
    const std::array<math::Float4, 4> stored = math::store(model);
    const Matrix4 reloaded = math::load(stored);
    context.expect(reloaded == model, "store rồi load giữ từng bit");
}

void quat_keeps_xyzw_order(Context& context) noexcept {
    const Quat turn(0.1F, 0.2F, 0.3F, 0.4F);
    const math::Float4 stored = math::store(turn);
    const math::Float4 expected{.x = 0.1F, .y = 0.2F, .z = 0.3F, .w = 0.4F};
    context.expect(stored == expected, "Quat(x, y, z, w) lưu đúng thứ tự x, y, z, w");
    context.expect(turn.w() == 0.4F, "w là thành phần thứ tư");
    const math::Float4 identity = math::store(Quat::identity());
    const math::Float4 no_turn{.x = 0.0F, .y = 0.0F, .z = 0.0F, .w = 1.0F};
    context.expect(identity == no_turn, "identity là (0, 0, 0, 1)");
}

void quat_becomes_rotation_matrix(Context& context) noexcept {
    // Quay quanh Y, sin và cos nửa góc là 0,6 và 0,8:
    // mọi phần tử của ma trận là số gọn.
    const Quat turn(0.0F, 0.6F, 0.0F, 0.8F);
    const Matrix3 rotation(turn);
    const Vector3 col0(0.28F, 0.0F, -0.96F);
    const Vector3 col2(0.96F, 0.0F, 0.28F);
    const Matrix3 expected(col0, Vector3::y_axis(), col2);
    context.expect(is_close(rotation, expected, 1e-6F), "ma trận của quaternion (0, 0.6, 0, 0.8)");
    const Quat back(rotation);
    context.expect(is_close(back, turn, 1e-6F), "ma trận quay về lại đúng quaternion");
    const Vector3 turned = math::rotate(turn, Vector3::x_axis());
    context.expect(is_close(turned, col0, 1e-6F), "rotate đưa +X tới cột 0 của ma trận");
}

void quat_axis_angle_matches_matrices(Context& context) noexcept {
    const Quat quarter = Quat::rotation(math::kHalfPi, Vector3::z_axis());
    const Matrix3 rotation(quarter);
    const Vector3 col0(0.0F, 1.0F, 0.0F);
    const Vector3 col1(-1.0F, 0.0F, 0.0F);
    const Matrix3 expected(col0, col1, Vector3::z_axis());
    context.expect(is_close(rotation, expected, 1e-6F), "quay 90 độ quanh Z: +X tới +Y, +Y tới -X");
    const Quat tilt = Quat::rotation_x(0.3F);
    const Quat both = quarter * tilt;
    const Matrix3 composed(both);
    const Matrix3 product = rotation * Matrix3(tilt);
    context.expect(is_close(composed, product, 1e-6F), "ma trận của tích bằng tích hai ma trận");
}

void quat_translation_scale_matches_trs(Context& context) noexcept {
    const Quat turn = Quat::rotation_z(math::kHalfPi);
    const Vector3 offset(10.0F, 20.0F, 30.0F);
    const Matrix4 size = Matrix4::scale(Vector3(2.0F, 3.0F, 4.0F));
    const Matrix4 placed = Matrix4(turn, offset) * size;
    const Matrix4 reference = placed_model();
    context.expect(is_close(placed, reference, 1e-6F), "Matrix4(quat, t) * scale khớp T * R * S");
    const Vector4 moved = placed * Point3(1.0F, 1.0F, 1.0F);
    const Vector4 landed(7.0F, 22.0F, 34.0F, 1.0F);
    context.expect(is_close(moved, landed, 1e-5F), "vật thể đưa (1, 1, 1) tới (7, 22, 34)");
}

void quat_places_points_and_directions(Context& context) noexcept {
    const Quat turn(0.0F, 0.6F, 0.0F, 0.8F);
    const Vector3 offset(100.0F, 0.0F, -50.0F);
    const Matrix4 size = Matrix4::scale(Vector3(2.0F));
    const Matrix4 object = Matrix4(turn, offset) * size;
    const Vector4 point = object * Point3(1.0F, 0.0F, 0.0F);
    const Vector4 landed(100.56F, 0.0F, -51.92F, 1.0F);
    context.expect(is_close(point, landed, 1e-5F), "điểm: quay, nhân tỉ lệ 2, cộng tịnh tiến");
    const Vector4 direction = object * Vector3::x_axis();
    const Vector4 facing(0.56F, 0.0F, -1.92F, 0.0F);
    context.expect(is_close(direction, facing, 1e-6F), "hướng: không cộng tịnh tiến, w = 0");
}

void rotation_y_is_right_handed(Context& context) noexcept {
    const Matrix4 quarter = Matrix4::rotation_y(math::kHalfPi);
    const Vector4 turned_x = quarter * Vector3::x_axis();
    const Vector4 turned_z = quarter * Vector3::z_axis();
    const Vector4 minus_z(0.0F, 0.0F, -1.0F, 0.0F);
    const Vector4 plus_x = Vector4::x_axis();
    context.expect(is_close(turned_x, minus_z, 1e-6F), "quay +90 độ quanh Y đưa +X tới -Z");
    context.expect(is_close(turned_z, plus_x, 1e-6F), "quay +90 độ quanh Y đưa +Z tới +X");
}

void look_at_rh_looks_down_minus_z(Context& context) noexcept {
    const Point3 eye(1.0F, 2.0F, 3.0F);
    const Point3 target(1.0F, 2.0F, 10.0F);
    const Matrix4 view = Matrix4::look_at_rh(eye, target, Vector3::y_axis());
    const Vector4 eye_seen = view * eye;
    const Vector4 target_seen = view * target;
    const Vector4 origin(0.0F, 0.0F, 0.0F, 1.0F);
    const Vector4 ahead(0.0F, 0.0F, -7.0F, 1.0F);
    context.expect(is_close(eye_seen, origin, 1e-6F), "mắt nằm ở gốc không gian camera");
    context.expect(is_close(target_seen, ahead, 1e-6F), "đích cách 7 nằm trên trục -Z của camera");
}

void aabb_follows_rotation(Context& context) noexcept {
    const Aabb box{.min = Vector3(-1.0F, -2.0F, -3.0F), .max = Vector3(1.0F, 2.0F, 3.0F)};
    const Matrix4 move = Matrix4::translation(Vector3(10.0F, 0.0F, 0.0F));
    const Matrix4 placement = move * Matrix4::rotation_z(math::kHalfPi);
    const Aabb moved = math::transform(box, placement);
    const Aabb wanted{.min = Vector3(8.0F, -1.0F, -3.0F), .max = Vector3(12.0F, 1.0F, 3.0F)};
    context.expect(is_close(moved, wanted, 1e-5F), "quay 90 độ quanh Z đổi chỗ cỡ X và Y, dời 10");
    // Hình vuông cạnh 2 quay 45 độ: nửa đường chéo là căn 2.
    const Aabb unit{.min = Vector3(-1.0F), .max = Vector3(1.0F)};
    const Matrix4 eighth = Matrix4::rotation_z(math::kHalfPi * 0.5F);
    const Aabb diamond = math::transform(unit, eighth);
    const float reach = std::numbers::sqrt2_v<float>;
    const Aabb around{.min = Vector3(-reach, -reach, -1.0F), .max = Vector3(reach, reach, 1.0F)};
    context.expect(is_close(diamond, around, 1e-6F), "quay 45 độ quanh Z nới hộp tới căn 2");
}

void aabb_follows_trs(Context& context) noexcept {
    // Nửa cỡ (1, 1, 1) nhân tỉ lệ thành (2, 3, 4), quay 90 độ quanh Z
    // thành (3, 2, 4), rồi dời tâm tới (10, 20, 30).
    const Aabb unit{.min = Vector3(-1.0F), .max = Vector3(1.0F)};
    const Aabb moved = math::transform(unit, placed_model());
    const Aabb wanted{.min = Vector3(7.0F, 18.0F, 26.0F), .max = Vector3(13.0F, 22.0F, 34.0F)};
    context.expect(is_close(moved, wanted, 1e-5F), "hộp bao của vật thể đặt bằng T * R * S");
}

void bounds_wraps_points(Context& context) noexcept {
    const std::array cloud{Vector3(1.0F, 5.0F, 2.0F), Vector3(-3.0F, 0.0F, 4.0F)};
    const Aabb around = math::bounds(cloud);
    const Vector3 lowest(-3.0F, 0.0F, 2.0F);
    const Vector3 highest(1.0F, 5.0F, 4.0F);
    context.expect(around.min == lowest, "min lấy thành phần nhỏ nhất của từng trục");
    context.expect(around.max == highest, "max lấy thành phần lớn nhất của từng trục");
    const std::span<const Vector3> no_points;
    const Aabb nothing = math::bounds(no_points);
    context.expect(nothing.min.x() > nothing.max.x(), "không điểm nào thì hộp rỗng: min > max");
}

void empty_aabb_transform_spans_all(Context& context) noexcept {
    const Aabb empty;
    context.expect(empty.min.x() > empty.max.x(), "hộp mặc định là hộp rỗng: min > max");
    const Aabb moved = math::transform(empty, Matrix4::identity());
    const Vector3 highest(std::numeric_limits<float>::max());
    const Vector3 lowest(-std::numeric_limits<float>::max());
    const bool is_inverted = moved.min.x() > moved.max.x();
    context.expect(moved.max == highest, "hành vi hiện tại: hộp rỗng biến đổi ra max = +FLT_MAX");
    context.expect(moved.min == lowest, "hành vi hiện tại: hộp rỗng biến đổi ra min = -FLT_MAX");
    context.expect(!is_inverted, "hành vi hiện tại: hộp rỗng biến đổi xong phủ cả không gian");
}

void reverse_z_right_handed(Context& context) noexcept {
    // math không có bản tay phải của độ sâu đảo: gọi perspective_rh
    // với mặt gần và mặt xa đổi chỗ.
    const FovLens lens{.fov_x = math::kHalfPi, .aspect_inverse = 0.5F, .z_near = 100.0F, .z_far = 1.0F};
    const Matrix4 projection = Matrix4::perspective_rh(lens);
    const Vector3 at_near = ndc(projection, Point3(0.0F, 0.0F, -1.0F));
    const Vector3 at_far = ndc(projection, Point3(0.0F, 0.0F, -100.0F));
    const Vector3 near_wanted(0.0F, 0.0F, 1.0F);
    const Vector3 far_wanted(0.0F, 0.0F, 0.0F);
    context.expect(is_close(at_near, near_wanted, 1e-6F), "tay phải: mặt gần z = -1 ra độ sâu 1");
    context.expect(is_close(at_far, far_wanted, 1e-6F), "tay phải: mặt xa z = -100 ra độ sâu 0");
    // Góc nhìn ngang 90 độ, khung cao bằng nửa rộng: x = -z ra mép phải,
    // y = -z / 2 ra mép trên; độ sâu (100 - 5) / (99 * 5).
    const Vector3 corner = ndc(projection, Point3(5.0F, 2.5F, -5.0F));
    const Vector3 corner_wanted(1.0F, 1.0F, 95.0F / 495.0F);
    context.expect(is_close(corner, corner_wanted, 1e-6F), "tay phải: góc trên phải ở z = -5");
}

void reverse_z_left_handed(Context& context) noexcept {
    const FovLens lens{.fov_x = math::kHalfPi, .aspect_inverse = 0.5F, .z_near = 1.0F, .z_far = 100.0F};
    const Matrix4 projection = Matrix4::perspective_lh_reverse_z(lens);
    const Vector4 col0(1.0F, 0.0F, 0.0F, 0.0F);
    const Vector4 col1(0.0F, 2.0F, 0.0F, 0.0F);
    const Vector4 col2(0.0F, 0.0F, -1.0F / 99.0F, 1.0F);
    const Vector4 col3(0.0F, 0.0F, 100.0F / 99.0F, 0.0F);
    const Matrix4 expected(col0, col1, col2, col3);
    context.expect(is_close(projection, expected, 1e-6F), "ma trận độ sâu đảo với gần 1, xa 100");
    const Vector3 at_near = ndc(projection, Point3(0.0F, 0.0F, 1.0F));
    const Vector3 at_middle = ndc(projection, Point3(0.0F, 0.0F, 2.0F));
    const Vector3 at_far = ndc(projection, Point3(0.0F, 0.0F, 100.0F));
    const Vector3 near_wanted(0.0F, 0.0F, 1.0F);
    const Vector3 middle_wanted(0.0F, 0.0F, 98.0F / 198.0F);
    const Vector3 far_wanted(0.0F, 0.0F, 0.0F);
    context.expect(is_close(at_near, near_wanted, 1e-6F), "mặt gần z = 1 ra độ sâu 1");
    context.expect(is_close(at_middle, middle_wanted, 1e-6F), "z = 2 ra độ sâu 98 / 198");
    context.expect(is_close(at_far, far_wanted, 1e-6F), "mặt xa z = 100 ra độ sâu 0");
    const Vector3 corner = ndc(projection, Point3(5.0F, 2.5F, 5.0F));
    const Vector3 corner_wanted(1.0F, 1.0F, 95.0F / 495.0F);
    context.expect(is_close(corner, corner_wanted, 1e-6F), "góc trên phải ở z = 5");
}

void perspective_maps_depth_to_zero_one(Context& context) noexcept {
    const FovLens lens{.fov_x = math::kHalfPi, .aspect_inverse = 0.5F, .z_near = 1.0F, .z_far = 100.0F};
    const Matrix4 projection = Matrix4::perspective_lh(lens);
    const Vector3 at_near = ndc(projection, Point3(0.0F, 0.0F, 1.0F));
    const Vector3 at_far = ndc(projection, Point3(0.0F, 0.0F, 100.0F));
    const Vector3 near_wanted(0.0F, 0.0F, 0.0F);
    const Vector3 far_wanted(0.0F, 0.0F, 1.0F);
    context.expect(is_close(at_near, near_wanted, 1e-6F), "mặt gần ra độ sâu 0");
    context.expect(is_close(at_far, far_wanted, 1e-6F), "mặt xa ra độ sâu 1");
    const Vector3 corner = ndc(projection, Point3(5.0F, 2.5F, 5.0F));
    const Vector3 corner_wanted(1.0F, 1.0F, 80.0F / 99.0F);
    context.expect(is_close(corner, corner_wanted, 1e-6F), "góc trên phải ở z = 5, độ sâu 80 / 99");
    // Khối nhìn lệch tâm: chữ nhật [0, 2] x [0, 1] trên mặt gần.
    const ViewWindow window{.left = 0.0F, .right = 2.0F, .bottom = 0.0F, .top = 1.0F, .z_near = 1.0F, .z_far = 100.0F};
    const Matrix4 shifted = Matrix4::frustum_lh(window);
    const Vector3 low = ndc(shifted, Point3(0.0F, 0.0F, 1.0F));
    const Vector3 high = ndc(shifted, Point3(2.0F, 1.0F, 1.0F));
    const Vector3 low_wanted(-1.0F, -1.0F, 0.0F);
    const Vector3 high_wanted(1.0F, 1.0F, 0.0F);
    context.expect(is_close(low, low_wanted, 1e-6F), "lệch tâm: góc dưới trái ra (-1, -1)");
    context.expect(is_close(high, high_wanted, 1e-6F), "lệch tâm: góc trên phải ra (1, 1)");
}

void clip_planes_face_inward(Context& context) noexcept {
    const FovLens lens{.fov_x = math::kHalfPi, .aspect_inverse = 0.5F, .z_near = 1.0F, .z_far = 100.0F};
    const Matrix4 projection = Matrix4::perspective_lh(lens);
    const math::ClipPlanes planes = math::clip_planes(projection, true);
    const float behind_near = math::dot(planes.z_near, Vector4(0.0F, 0.0F, 1.5F, 1.0F));
    const float before_near = math::dot(planes.z_near, Vector4(0.0F, 0.0F, 0.5F, 1.0F));
    context.expect(is_close(behind_near, 0.5F, 1e-6F), "z = 1,5 nằm trong, cách mặt gần 0,5");
    context.expect(is_close(before_near, -0.5F, 1e-6F), "z = 0,5 nằm ngoài, cách mặt gần -0,5");
    // Mặt phải là x = z: khoảng cách có dấu là (z - x) / căn 2.
    const float slant = std::sqrt(0.5F);
    const float left_of_right = math::dot(planes.right, Vector4(4.0F, 0.0F, 5.0F, 1.0F));
    const float right_of_right = math::dot(planes.right, Vector4(6.0F, 0.0F, 5.0F, 1.0F));
    context.expect(is_close(left_of_right, slant, 1e-6F), "x = 4 ở z = 5 nằm trong mặt phải");
    context.expect(is_close(right_of_right, -slant, 1e-6F), "x = 6 ở z = 5 nằm ngoài mặt phải");
}

void frustum_culls_boxes(Context& context) noexcept {
    const FovLens lens{.fov_x = math::kHalfPi, .aspect_inverse = 1.0F, .z_near = 1.0F, .z_far = 10.0F};
    const Matrix4 projection = Matrix4::perspective_lh(lens);
    const Frustum frustum = math::make_frustum(projection);
    const Vector4 near_corner(-1.0F, 1.0F, 1.0F, 1.0F);
    const Vector4 far_corner(10.0F, -10.0F, 10.0F, 1.0F);
    context.expect(is_close(frustum.near_top_left, near_corner, 1e-5F), "đỉnh gần trên trái");
    context.expect(is_close(frustum.far_bottom_right, far_corner, 1e-5F), "đỉnh xa dưới phải");
    const Aabb inside = unit_box_at(Vector3(0.0F, 0.0F, 5.0F));
    const Aabb behind = unit_box_at(Vector3(0.0F, 0.0F, -5.0F));
    const Aabb beside = unit_box_at(Vector3(50.0F, 0.0F, 5.0F));
    const FrustumTest planes = FrustumTest::kPlanesOnly;
    const FrustumTest corners = FrustumTest::kWithCorners;
    context.expect(touches(inside, frustum, planes), "hộp giữa khối nhìn: chạm");
    context.expect(touches(inside, frustum, corners), "hộp giữa: chạm cả khi kiểm đỉnh");
    context.expect(!touches(behind, frustum, planes), "hộp sau camera: không chạm");
    context.expect(!touches(beside, frustum, corners), "hộp lệch 50 sang phải: không chạm");
}

void corner_test_rejects_diagonal_box(Context& context) noexcept {
    // Hộp nằm chéo ngoài cạnh phải xa: không mặt nào loại được cả tám đỉnh
    // hộp, nhưng cả tám đỉnh khối nhìn có x <= 10, nhỏ hơn min.x = 11.
    const FovLens lens{.fov_x = math::kHalfPi, .aspect_inverse = 1.0F, .z_near = 1.0F, .z_far = 10.0F};
    const Matrix4 projection = Matrix4::perspective_lh(lens);
    const Frustum frustum = math::make_frustum(projection);
    const Aabb diagonal{.min = Vector3(11.0F, -1.0F, 5.0F), .max = Vector3(20.0F, 1.0F, 12.0F)};
    const FrustumTest planes = FrustumTest::kPlanesOnly;
    const FrustumTest corners = FrustumTest::kWithCorners;
    context.expect(touches(diagonal, frustum, planes), "sáu mặt không loại được hộp chéo");
    context.expect(!touches(diagonal, frustum, corners), "phép kiểm đỉnh loại hộp chéo");
}

void ray_meets_box(Context& context) noexcept {
    const Aabb box{.min = Vector3(-1.0F), .max = Vector3(1.0F)};
    const Vector3 forward = Vector3::x_axis();
    const Vector3 outside(-5.0F, 0.0F, 0.0F);
    const math::Ray along = math::make_ray(outside, forward);
    const math::Ray within = math::make_ray(Vector3::zero(), forward);
    const math::Ray above = math::make_ray(Vector3(-5.0F, 3.0F, 0.0F), forward);
    const math::Ray away = math::make_ray(outside, -forward);
    context.expect(math::intersect(along, box) == 4.0F, "tia từ x = -5 vào hộp sau 4 đơn vị");
    context.expect(math::intersect(within, box) == 0.0F, "gốc tia trong hộp: khoảng cách 0");
    context.expect(math::intersect(above, box) == std::nullopt, "tia ở y = 3 trượt trên hộp");
    context.expect(math::intersect(away, box) == std::nullopt, "tia quay lưng không chạm hộp");
    const Aabb empty;
    context.expect(math::intersect(within, empty) == std::nullopt, "hộp rỗng không giao tia nào");
}

void ray_meets_plane(Context& context) noexcept {
    // Mặt phẳng y = 3, pháp tuyến hướng lên: n . x + d = 0 nên d = -3.
    const Vector3 upward(0.0F, 2.0F, 0.0F);
    const Vector3 on_plane(5.0F, 3.0F, 5.0F);
    const math::Plane ground = math::plane_from_point(upward, on_plane);
    context.expect(ground.d == -3.0F, "mặt phẳng y = 3 có d = -3");
    const Vector3 start(1.0F, 10.0F, 2.0F);
    const math::Ray down = math::make_ray(start, Vector3(0.0F, -4.0F, 0.0F));
    const std::optional<float> reach = math::ray_plane_distance(down, ground);
    context.expect(reach == 7.0F, "tia từ y = 10 đi xuống chạm sau 7 đơn vị");
    const Vector3 landing(1.0F, 3.0F, 2.0F);
    context.expect(math::intersect(down, ground) == landing, "điểm chạm nằm ngay dưới gốc tia");
    const math::Ray rising = math::make_ray(start, Vector3::y_axis());
    const std::optional<Vector3> missed = math::intersect(rising, ground);
    context.expect(missed == std::nullopt, "tia đi lên không chạm mặt phẳng phía dưới");
    const math::Ray level = math::make_ray(start, Vector3::x_axis());
    const std::optional<float> never = math::ray_plane_distance(level, ground);
    context.expect(never == std::nullopt, "tia song song cách mặt phẳng 7: không có giao điểm");
}

void decompose_recovers_trs(Context& context) noexcept {
    const std::optional<AffineTransform> parts = math::decompose(placed_model());
    context.expect(parts.has_value(), "ma trận T * R * S phân rã được");
    const AffineTransform found = parts.value_or(AffineTransform{});
    const Vector3 offset(10.0F, 20.0F, 30.0F);
    const Vector3 factors(2.0F, 3.0F, 4.0F);
    const Quat turn = Quat::rotation_z(math::kHalfPi);
    context.expect(found.translation == offset, "tịnh tiến lấy nguyên cột cuối");
    context.expect(is_close(found.scale, factors, 1e-5F), "tỉ lệ là độ dài ba cột");
    context.expect(is_close(found.rotation, turn, 1e-5F), "phần quay là quay 90 độ quanh Z");
}

void decompose_handles_mirror_and_flat(Context& context) noexcept {
    const Vector3 axis = math::normalize(Vector3(1.0F, -2.0F, 0.5F));
    const Quat spin = Quat::rotation(0.8F, axis);
    const Matrix4 placed(spin, Vector3(1.0F, 2.0F, 3.0F));
    const Matrix4 mirror = Matrix4::scale(Vector3(-2.0F, 3.0F, 4.0F));
    const Matrix4 mirrored = placed * mirror;
    const AffineTransform flipped = math::decompose(mirrored).value_or(AffineTransform{});
    const Matrix4 turned(flipped.rotation, flipped.translation);
    const Matrix4 rebuilt = turned * Matrix4::scale(flipped.scale);
    context.expect(is_close(rebuilt, mirrored, 1e-5F), "ma trận lật ghép lại ra ma trận cũ");
    const Vector3 negated(-2.0F, -3.0F, -4.0F);
    context.expect(is_close(flipped.scale, negated, 1e-5F), "hành vi hiện tại: ba tỉ lệ đều âm");
    const Matrix4 flat = Matrix4::scale(Vector3(1.0F, 0.0F, 1.0F));
    context.expect(math::decompose(flat) == std::nullopt, "tỉ lệ 0 trên một trục là suy biến");
    const Matrix4 tiny = Matrix4::scale(Vector3(0.001F));
    const AffineTransform small = math::decompose(tiny).value_or(AffineTransform{});
    const Vector3 thousandth(0.001F);
    context.expect(is_close(small.scale, thousandth, 1e-9F), "tỉ lệ đều 0,001 không phải suy biến");
}

void half_round_trips_every_pattern(Context& context) noexcept {
    context.expect(half_mismatches() == 0, "mọi mẫu half trừ NaN đổi qua float rồi về đúng mẫu cũ");
}

constexpr std::array kCases{
    Case{.name = "trs_places_point_and_columns", .body = &trs_places_point_and_columns},
    Case{.name = "trs_inverse_round_trips", .body = &trs_inverse_round_trips},
    Case{.name = "quat_keeps_xyzw_order", .body = &quat_keeps_xyzw_order},
    Case{.name = "quat_becomes_rotation_matrix", .body = &quat_becomes_rotation_matrix},
    Case{.name = "quat_axis_angle_matches_matrices", .body = &quat_axis_angle_matches_matrices},
    Case{.name = "quat_translation_scale_matches_trs", .body = &quat_translation_scale_matches_trs},
    Case{.name = "quat_places_points_and_directions", .body = &quat_places_points_and_directions},
    Case{.name = "rotation_y_is_right_handed", .body = &rotation_y_is_right_handed},
    Case{.name = "look_at_rh_looks_down_minus_z", .body = &look_at_rh_looks_down_minus_z},
    Case{.name = "aabb_follows_rotation", .body = &aabb_follows_rotation},
    Case{.name = "aabb_follows_trs", .body = &aabb_follows_trs},
    Case{.name = "bounds_wraps_points", .body = &bounds_wraps_points},
    Case{.name = "empty_aabb_transform_spans_all", .body = &empty_aabb_transform_spans_all},
    Case{.name = "reverse_z_right_handed", .body = &reverse_z_right_handed},
    Case{.name = "reverse_z_left_handed", .body = &reverse_z_left_handed},
    Case{.name = "perspective_maps_depth_to_zero_one", .body = &perspective_maps_depth_to_zero_one},
    Case{.name = "clip_planes_face_inward", .body = &clip_planes_face_inward},
    Case{.name = "frustum_culls_boxes", .body = &frustum_culls_boxes},
    Case{.name = "corner_test_rejects_diagonal_box", .body = &corner_test_rejects_diagonal_box},
    Case{.name = "ray_meets_box", .body = &ray_meets_box},
    Case{.name = "ray_meets_plane", .body = &ray_meets_plane},
    Case{.name = "decompose_recovers_trs", .body = &decompose_recovers_trs},
    Case{.name = "decompose_handles_mirror_and_flat", .body = &decompose_handles_mirror_and_flat},
    Case{.name = "half_round_trips_every_pattern", .body = &half_round_trips_every_pattern},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "math_tests: mọi ca phải qua");
    return 0;
}
