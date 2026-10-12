#pragma once
// Toạ độ cảnh. x và z nằm trên mặt đất, y là độ cao.
// Nguồn: TLBB Dev src/math/vec3.hpp@e0d89a6. Khác gốc: namespace game::ogre (tách khỏi game::math
// dùng SIMD, vì module này giữ đúng toán tử và thứ tự của OGRE 1.2.5); hằng và phép tính viết theo
// cổng của dự án (hậu tố F, ngoặc quanh phép nhân, khởi tạo ghi tên thành viên), cùng giá trị; bỏ
// operator<=> (thứ tự giữa hai toạ độ không có nghĩa và chưa nơi nào dùng).

#include <cmath>

namespace game::ogre {

struct Vec3 {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    friend constexpr bool operator==(Vec3, Vec3) = default;
};

[[nodiscard]] constexpr Vec3 add_vec3(Vec3 left, Vec3 right) {
    return Vec3{.x = left.x + right.x, .y = left.y + right.y, .z = left.z + right.z};
}

[[nodiscard]] constexpr Vec3 sub_vec3(Vec3 left, Vec3 right) {
    return Vec3{.x = left.x - right.x, .y = left.y - right.y, .z = left.z - right.z};
}

[[nodiscard]] constexpr Vec3 scale_vec3(Vec3 value, float factor) {
    return Vec3{.x = value.x * factor, .y = value.y * factor, .z = value.z * factor};
}

// Nhân và chia từng thành phần, như Vector3::operator* và operator/ với một Vector3 của OGRE: scale
// của xương gộp theo trục, không trượt.
[[nodiscard]] constexpr Vec3 mul_vec3(Vec3 left, Vec3 right) {
    return Vec3{.x = left.x * right.x, .y = left.y * right.y, .z = left.z * right.z};
}

[[nodiscard]] constexpr Vec3 div_vec3(Vec3 left, Vec3 right) {
    return Vec3{.x = left.x / right.x, .y = left.y / right.y, .z = left.z / right.z};
}

[[nodiscard]] constexpr float dot_vec3(Vec3 left, Vec3 right) {
    return ((left.x * right.x) + (left.y * right.y)) + (left.z * right.z);
}

[[nodiscard]] constexpr Vec3 cross_vec3(Vec3 left, Vec3 right) {
    return Vec3{.x = (left.y * right.z) - (left.z * right.y),
        .y = (left.z * right.x) - (left.x * right.z),
        .z = (left.x * right.y) - (left.y * right.x)};
}

// Độ dài và chuẩn hoá để ở dạng inline chứ không constexpr: std::sqrt chỉ constexpr từ C++23 và
// mức hỗ trợ của nó khác nhau giữa các bản STL, không đáng đánh đổi.
[[nodiscard]] inline float length_vec3(Vec3 value) {
    return std::sqrt(dot_vec3(value, value));
}

// Vector đơn vị cùng hướng. Vector 0 trả về chính nó, để chỗ gọi tự quyết định thay vì nhận NaN.
[[nodiscard]] inline Vec3 normalize_vec3(Vec3 value) {
    const float size = length_vec3(value);
    if (size <= 0.0F) return value;
    return scale_vec3(value, 1.0F / size);
}

} // namespace game::ogre
