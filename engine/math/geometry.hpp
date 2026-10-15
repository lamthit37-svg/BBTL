/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/math/geometry.hpp
 *  PHÂN HỆ   : Math / Geometry
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hình học cho chọn vật, va chạm thô và cắt khối nhìn: Ray, Plane, Aabb,
 *    Obb, Frustum và các phép giao — phần "intersection helpers" và "matrix
 *    helpers" của common.hpp trong _Ref. Khác gốc:
 *  - MỘT quy ước mặt phẳng: normal . x + d = 0, giống mặt phẳng dạng Vector4
 *    (a, b, c, d). Gốc cho Plane(normal, point) lưu d = normal . point (tức
 *    normal . x - d = 0) nhưng rayPlaneDistance lại giải theo dấu cộng, rồi
 *    rayIntersectsPlane bù bằng cách đảo dấu t: điểm chạm ra sai phía;
 *  - phép giao trả std::optional thay bool cộng con trỏ ra;
 *  - đỉnh khối nhìn lấy z của NDC trong [0, 1] (D3D, Vulkan); gốc dùng [-1, 1]
 *    của OpenGL;
 *  - decompose là một hàm, trả optional: gốc có hai bản, bản decomposeMatrix
 *    tính ma trận đã bỏ tỉ lệ rồi không dùng và thiếu khôi phục dấu; bản
 *    decompose chỉ đổi dấu một hàng khi hệ toạ độ lật và lặng lẽ bỏ dở khi ma
 *    trận suy biến.
 *  - Nguồn: Forge2 src/math/geometry.hpp@d7fcd76. Khác gốc (so với Forge2):
 *    enumerator của FrustumTest mang tiền tố k; bỏ {} thừa ở thành viên Vector3
 *    của Ray, Plane, Obb; Float2 của frustum_size_fov_x/y khởi tạo bằng tên
 *    thành viên; NOLINT kèm lý do cho plane_from_point và frustum_size_fov_x/y.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "math/matrix.hpp"

#include <array>
#include <limits>
#include <optional>
#include <span>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

// Tia: gốc và hướng đơn vị. make_ray chuẩn hoá hướng.
struct Ray {
    Vector3 origin;
    Vector3 direction;
};

[[nodiscard]] inline Ray make_ray(const Vector3& origin, const Vector3& direction) noexcept {
    return {.origin = origin, .direction = normalize(direction)};
}

// Điểm trên tia cách gốc t.
[[nodiscard]] inline Vector3 at(const Ray& ray, float t) noexcept {
    return ray.origin + (ray.direction * t);
}

// Tia qua một ma trận (có thể là chiếu): gốc chia cho w, hướng chuẩn hoá lại.
[[nodiscard]] Ray transform(const Ray& ray, const Matrix4& m) noexcept;

// Mặt phẳng normal . x + d = 0, normal đơn vị; d âm khi gốc toạ độ nằm phía sau pháp tuyến.
struct Plane {
    Vector3 normal;
    float d = 0.0F;
};

// Mặt phẳng qua point với pháp tuyến normal (không cần đơn vị).
// Pháp tuyến rồi điểm, như Plane(normal, point) của gốc (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] inline Plane plane_from_point(const Vector3& normal, const Vector3& point) noexcept {
    const Vector3 unit = normalize(normal);
    return {.normal = unit, .d = -dot(unit, point)};
}

[[nodiscard]] inline Vector4 as_vector(const Plane& plane) noexcept {
    return {plane.normal, plane.d};
}

// Khoảng cách có dấu từ điểm tới mặt phẳng (a, b, c, d) đã chuẩn hoá; dương ở phía pháp tuyến.
[[nodiscard]] inline float plane_distance(const Vector4& plane, const Vector3& point) noexcept {
    return dot(plane.xyz(), point) + plane.w();
}

// Tham số t của hình chiếu point lên đường thẳng qua line0, line1 (0 tại line0, 1 tại line1).
[[nodiscard]] inline float line_projection(const Vector3& line0, const Vector3& line1, const Vector3& point) noexcept {
    const Vector3 along = line1 - line0;
    return dot(along, point - line0) / dot(along, along);
}

// Hộp theo trục. Mặc định là hộp rỗng (min > max): gộp điểm đầu tiên vào là thành hộp điểm đó.
struct Aabb {
    Vector3 min{std::numeric_limits<float>::max()};
    Vector3 max{-std::numeric_limits<float>::max()};
};

// Hộp nhỏ nhất chứa mọi điểm.
[[nodiscard]] Aabb bounds(std::span<const Vector3> points) noexcept;

// Hộp theo trục chứa hộp cũ sau biến đổi affine m.
[[nodiscard]] Aabb transform(const Aabb& box, const Matrix4& m) noexcept;

// Hộp có hướng: tâm, nửa kích thước, ba trục đơn vị vuông góc.
struct Obb {
    Vector3 center;
    Vector3 half_extents;
    Vector3 x = Vector3::x_axis();
    Vector3 y = Vector3::y_axis();
    Vector3 z = Vector3::z_axis();
};

[[nodiscard]] inline Obb make_obb(const Aabb& box) noexcept {
    return {.center = (box.min + box.max) * 0.5F, .half_extents = (box.max - box.min) * 0.5F};
}

// Biến đổi affine; nửa kích thước nhận phần co giãn. Trục có nửa kích thước 0 cho NaN.
[[nodiscard]] Obb transform(const Obb& box, const Matrix4& m) noexcept;

// Khoảng cách dọc tia tới mặt phẳng, có thể âm (mặt phẳng phía sau gốc tia). Tia song song: 0 khi
// gốc nằm trên mặt phẳng, rỗng khi không.
[[nodiscard]] std::optional<float> ray_plane_distance(const Ray& ray, const Plane& plane) noexcept;

// Điểm tia chạm mặt phẳng ở phía trước gốc tia.
[[nodiscard]] std::optional<Vector3> intersect(const Ray& ray, const Plane& plane) noexcept;

// Khoảng cách tới điểm vào hộp (0 khi gốc tia nằm trong hộp) — phương pháp slab.
// Hộp rỗng (min > max) không giao: slab đổi chỗ hai mặt nên hộp ngược trông như cả không gian.
[[nodiscard]] std::optional<float> intersect(const Ray& ray, const Aabb& box) noexcept;
[[nodiscard]] std::optional<float> intersect(const Ray& ray, const Obb& box) noexcept;

// Giao của hai đường thẳng VÔ HẠN qua (a, b) và (c, d); rỗng khi song song.
[[nodiscard]] std::optional<Vector2> intersect_lines(Vector2 a, Vector2 b, Vector2 c, Vector2 d) noexcept;

// Khối nhìn: sáu mặt (pháp tuyến hướng vào trong) và tám đỉnh, w của đỉnh bằng 1.
struct Frustum {
    Vector4 near_plane{};
    Vector4 far_plane{};
    Vector4 top_plane{};
    Vector4 bottom_plane{};
    Vector4 left_plane{};
    Vector4 right_plane{};
    Vector4 near_top_left{};
    Vector4 near_top_right{};
    Vector4 near_bottom_left{};
    Vector4 near_bottom_right{};
    Vector4 far_top_left{};
    Vector4 far_top_right{};
    Vector4 far_bottom_left{};
    Vector4 far_bottom_right{};
};

// Khối nhìn đầy đủ (mặt đã chuẩn hoá và đỉnh) của ma trận nhìn-chiếu, z của NDC trong [0, 1].
[[nodiscard]] Frustum make_frustum(const Matrix4& view_projection) noexcept;

// Điền tám đỉnh từ ma trận nhìn-chiếu, giữ nguyên các mặt (InitFrustumVerts của gốc).
void set_corners(Frustum& frustum, const Matrix4& view_projection) noexcept;

// Mặt phẳng thế giới của một mặt cho trong không gian clip: pháp tuyến normal, tiếp tuyến tangent,
// cách gốc distance dọc pháp tuyến.
[[nodiscard]] Vector4 frustum_plane(const Matrix4& inverse_view_projection, const Vector3& normal,
    const Vector3& tangent, float distance) noexcept;

// Chữ nhật trên màn hình, tính bằng điểm ảnh, gốc ở góc trên trái.
struct ScreenRect {
    float x_min = 0.0F;
    float x_max = 0.0F;
    float y_min = 0.0F;
    float y_max = 0.0F;
};

// Bốn mặt bên của khối nhìn con ứng với một chữ nhật trên màn hình cỡ screen; mặt gần, xa và các
// đỉnh để nguyên giá trị 0 (dùng với aabb_touches_frustum ở chế độ chỉ kiểm mặt).
[[nodiscard]] Frustum frustum_from_rect(const Matrix4& view_projection, const ScreenRect& rect, Float2 screen) noexcept;

// Cỡ của mặt cắt khối nhìn ở khoảng cách distance, theo góc nhìn ngang hoặc dọc và tỉ lệ khung
// (rộng / cao).
// Góc nhìn, tỉ lệ khung rồi khoảng cách: tên tham số nói rõ từng số (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
[[nodiscard]] inline Float2 frustum_size_fov_x(float fov_x, float aspect, float distance) noexcept {
    const float width = 2.0F * distance * std::tan(0.5F * fov_x);
    return {.x = width, .y = (1.0F / aspect) * width};
}

[[nodiscard]] inline Float2 frustum_size_fov_y(float fov_y, float aspect, float distance) noexcept {
    const float height = 2.0F * distance * std::tan(0.5F * fov_y);
    return {.x = aspect * height, .y = height};
}
// NOLINTEND(bugprone-easily-swappable-parameters)

enum class FrustumTest : std::uint8_t {
    // Chỉ kiểm hộp với sáu mặt: nhanh, có thể giữ nhầm hộp lớn nằm ngoài gần góc khối nhìn.
    kPlanesOnly,
    // Thêm kiểm tám đỉnh khối nhìn với sáu mặt của hộp, loại được trường hợp trên.
    kWithCorners,
};

// Sai khi hộp chắc chắn nằm ngoài khối nhìn (theo "Correct Frustum Culling" của Inigo Quilez).
[[nodiscard]] bool aabb_touches_frustum(const Aabb& box, const Frustum& frustum, FrustumTest test) noexcept;

// Ma trận phân rã thành tịnh tiến, quay, tỉ lệ (bỏ phần xiên). Rỗng khi m[3][3] gần 0 hoặc phần
// 3x3 suy biến.
[[nodiscard]] std::optional<AffineTransform> decompose(const Matrix4& m) noexcept;

// Góc Euler (x, y, z) của ma trận quay dựng theo rotation_zyx.
[[nodiscard]] Vector3 euler_angles(const Matrix3& rotation) noexcept;

// Điểm thế giới sang không gian mô hình, biết nghịch đảo của ma trận mô hình.
[[nodiscard]] inline Point3 world_to_model(const Matrix4& inverse_model, const Point3& p) noexcept {
    return Point3(inverse_model * p);
}

// Ma trận chiếu bóng phẳng lên mặt phẳng plane từ nguồn sáng light (w = 1: đèn điểm, w = 0: đèn
// hướng).
[[nodiscard]] Matrix4 shadow_matrix(const Vector4& plane, const Vector4& light) noexcept;

} // namespace game::math
// NOLINTEND(readability-identifier-length)
