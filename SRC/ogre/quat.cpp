// Hai phép của quaternion cần căn bậc hai, để ở TU riêng. Thứ tự toán tử theo Quaternion::normalise
// và Quaternion::nlerp của OGRE 1.2.5 trong _ref.
// Nguồn: TLBB Dev src/math/quat.cpp@e0d89a6. Khác gốc: namespace game::ogre; khởi tạo ghi tên
// thành viên và hậu tố F theo cổng của dự án; enumerator của Arc mang tiền tố k.
#include "ogre/quat.hpp"

#include "ogre/vec3.hpp"

#include <cmath>

namespace game::ogre {
namespace {

constexpr Quat add(Quat left, Quat right) {
    return Quat{.x = left.x + right.x, .y = left.y + right.y, .z = left.z + right.z, .w = left.w + right.w};
}

constexpr Quat subtract(Quat left, Quat right) {
    return Quat{.x = left.x - right.x, .y = left.y - right.y, .z = left.z - right.z, .w = left.w - right.w};
}

constexpr Quat scale(Quat value, float factor) {
    return Quat{.x = factor * value.x, .y = factor * value.y, .z = factor * value.z, .w = factor * value.w};
}

constexpr Quat negate(Quat value) {
    return Quat{.x = -value.x, .y = -value.y, .z = -value.z, .w = -value.w};
}

} // namespace

// OGRE nhân với nghịch đảo của căn bậc hai chứ không chia từng thành phần; giữ đúng như vậy.
Quat quat_normalize(Quat value) {
    const float length = quat_dot(value, value);
    const float factor = 1.0F / std::sqrt(length);
    return scale(value, factor);
}

Quat quat_nlerp(float blend, Quat from, Quat finish, Arc arc) {
    const float cosine = quat_dot(from, finish);
    const bool flip = cosine < 0.0F && arc == Arc::kShortest;
    const Quat target = flip ? negate(finish) : finish;
    const Quat step = scale(subtract(target, from), blend);
    return quat_normalize(add(from, step));
}

// Quaternion::FromAngleAxis: nửa góc nhân 0,5 trước, rồi sin cho phần vector, cos cho w.
Quat quat_from_angle_axis(float radians, Vec3 axis) {
    const float half = 0.5F * radians;
    const float sine = std::sin(half);
    return Quat{.x = sine * axis.x, .y = sine * axis.y, .z = sine * axis.z, .w = std::cos(half)};
}

} // namespace game::ogre

