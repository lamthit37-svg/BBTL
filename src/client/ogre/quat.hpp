#pragma once
// Quaternion cho xương và animation, theo đúng quy ước của OGRE 1.2.5 mà asset của ref xuất ra:
// - lưu x, y, z, w, cũng là thứ tự float trên dây của .skeleton và của container đã nấu;
// - quat_multiply(a, b) xoay theo b trước rồi mới a, như Quaternion::operator* của OGRE;
// - quat_nlerp nhận cờ đường đi như nlerp(t, p, q, shortestPath): nội suy giữa hai khoá đi đường
//   ngắn nhất, còn cộng dồn animation thì OGRE gọi nlerp với cờ mặc định false.
// Công thức viết lại theo ngữ nghĩa của OgreQuaternion.cpp trong _ref (đọc, không chép mã), giữ
// nguyên toán tử và thứ tự toán hạng, để cùng đầu vào thì tư thế ra trùng client gốc.
// Nguồn: TLBB Dev src/math/quat.hpp@e0d89a6. Khác gốc: namespace game::ogre; hằng và phép tính
// viết theo cổng của dự án (hậu tố F, ngoặc quanh phép nhân, khởi tạo ghi tên, biến tạm đặt tên
// dài hơn), cùng giá trị và cùng thứ tự phép tính; enumerator của Arc mang tiền tố k.

#include "ogre/vec3.hpp"

#include <cstdint>

namespace game::ogre {

struct Quat {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float w = 1.0F;

    friend constexpr bool operator==(Quat, Quat) = default;
};

// Tích vô hướng bốn chiều, cộng theo thứ tự w, x, y, z như Quaternion::Dot.
[[nodiscard]] constexpr float quat_dot(Quat left, Quat right) {
    return (((left.w * right.w) + (left.x * right.x)) + (left.y * right.y)) + (left.z * right.z);
}

// Ghép hai phép xoay: kết quả xoay theo `right` trước rồi mới theo `left`.
[[nodiscard]] constexpr Quat quat_multiply(Quat left, Quat right) {
    const float scalar = (((left.w * right.w) - (left.x * right.x)) - (left.y * right.y)) - (left.z * right.z);
    const float axis_x = (((left.w * right.x) + (left.x * right.w)) + (left.y * right.z)) - (left.z * right.y);
    const float axis_y = (((left.w * right.y) + (left.y * right.w)) + (left.z * right.x)) - (left.x * right.z);
    const float axis_z = (((left.w * right.z) + (left.z * right.w)) + (left.x * right.y)) - (left.y * right.x);
    return Quat{.x = axis_x, .y = axis_y, .z = axis_z, .w = scalar};
}

// Trục z cục bộ của quaternion, Quaternion::zAxis của OGRE 1.2.5. Camera OGRE nhìn theo -z.
[[nodiscard]] constexpr Vec3 quat_z_axis(Quat value) {
    const float twice_x = 2.0F * value.x;
    const float twice_y = 2.0F * value.y;
    const float twice_z = 2.0F * value.z;
    const float twice_wx = twice_x * value.w;
    const float twice_wy = twice_y * value.w;
    const float twice_xx = twice_x * value.x;
    const float twice_xz = twice_z * value.x;
    const float twice_yy = twice_y * value.y;
    const float twice_yz = twice_z * value.y;
    return Vec3{.x = twice_xz + twice_wy, .y = twice_yz - twice_wx, .z = 1.0F - (twice_xx + twice_yy)};
}

// Xoay một vector theo cách của SDK nVidia mà OGRE dùng: v + 2w(q×v) + 2(q×(q×v)), với q là phần
// vector của quaternion. Chỉ đúng với quaternion đơn vị.
[[nodiscard]] constexpr Vec3 quat_rotate(Quat rotation, Vec3 value) {
    const Vec3 axis{.x = rotation.x, .y = rotation.y, .z = rotation.z};
    const Vec3 across = cross_vec3(axis, value);
    const Vec3 uuv = cross_vec3(axis, across);
    const Vec3 spin = scale_vec3(across, 2.0F * rotation.w);
    const Vec3 lift = scale_vec3(uuv, 2.0F);
    return add_vec3(add_vec3(value, spin), lift);
}

// Nghịch đảo tổng quát, như Quaternion::Inverse: quaternion 0 trả về 0 để báo lỗi, không chia 0.
[[nodiscard]] constexpr Quat quat_inverse(Quat value) {
    const float norm = quat_dot(value, value); // như Quaternion::Norm: w, x, y, z bình phương
    if (!(norm > 0.0F)) return Quat{.x = 0.0F, .y = 0.0F, .z = 0.0F, .w = 0.0F};
    const float inverse = 1.0F / norm;
    return Quat{.x = -value.x * inverse, .y = -value.y * inverse, .z = -value.z * inverse, .w = value.w * inverse};
}

// Xoay radians quanh trục đơn vị axis, như Quaternion::FromAngleAxis: nửa góc, w = cos, phần vector
// = sin nhân trục. Nhân vật quay mặt theo cách này, quanh +y.
[[nodiscard]] Quat quat_from_angle_axis(float radians, Vec3 axis);

// Chia cho độ dài, như Quaternion::normalise. Giống OGRE, quaternion 0 cho ra NaN; quat_nlerp của
// hai quaternion đơn vị không bao giờ rơi vào đó.
[[nodiscard]] Quat quat_normalize(Quat value);

// Chiều nội suy, như cờ shortestPath của Quaternion::nlerp: kShortest nội suy tới -q khi tích vô
// hướng âm, kDirect nội suy thẳng tới q.
enum class Arc : std::uint8_t { kShortest, kDirect };

// Nội suy tuyến tính rồi chuẩn hoá: p + t * (q - p), đúng phép tính của Quaternion::nlerp.
[[nodiscard]] Quat quat_nlerp(float blend, Quat from, Quat finish, Arc arc);

// log và exp của Quaternion trong OGRE 1.2.5. log cho ra phần vector A * trục, w = 0.
// exp đưa phần vector ấy về cos(A) + sin(A) * trục. Dùng cho tiếp tuyến RotationalSpline.
[[nodiscard]] Quat quat_log(Quat value);
[[nodiscard]] Quat quat_exp(Quat value);

// Nội suy cầu Quaternion::Slerp. Gần trùng hoặc gần nghịch thì rơi về nội suy tuyến tính rồi
// chuẩn hoá, đúng nhánh |cos| >= 1 - 1e-3 của gốc.
[[nodiscard]] Quat quat_slerp(float blend, Quat from, Quat finish, Arc arc);

// Bốn quaternion của Quaternion::Squad: hai đầu và hai tiếp tuyến.
struct SquadSpan {
    Quat from{};
    Quat from_tangent{};
    Quat finish_tangent{};
    Quat finish{};
};

// Squad(t, p, a, b, q, shortestPath). Hai slerp trong (tiếp tuyến, rồi slerp của hai kết quả)
// đi thẳng, không lật, như lời gọi Slerp bỏ cờ của gốc (mặc định false).
[[nodiscard]] Quat quat_squad(float blend, SquadSpan span, Arc arc);

} // namespace game::ogre
