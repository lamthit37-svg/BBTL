// Hệ trục Euler của kính Cool3D (CameraEuler::UpdateViewMatrix).
// Một chỗ duy nhất tính sin/cos: forward, up, rồi mắt = đích − forward * khoảng cách.
// side = forward × up (D3DXVec3Cross): đó là hướng trái, không phải phải màn hình.
// Thế giới giữ centimet, Y lên, đúng số client gốc đọc. Ma trận tay trái ở lens.
// Trước lần dựng đầu, side mặc định là +X như hàm dựng gốc, chưa phải tích có hướng.
#pragma once

#include "math/vector.hpp"

namespace game::camera {

struct Euler {
    math::Point3 look_at{};
    float yaw = 0.0F;
    float pitch = 0.0F;
    float roll = 0.0F;
    float distance = 100.0F;
};

struct Basis {
    math::Vector3 forward{0.0F, 0.0F, 1.0F};
    math::Vector3 side{1.0F, 0.0F, 0.0F};
    math::Vector3 up{0.0F, 1.0F, 0.0F};
    math::Point3 eye{};
};

// Trục và mắt sau khi dựng. side là tích có hướng.
[[nodiscard]] Basis basis_of(const Euler& euler) noexcept;

} // namespace game::camera
