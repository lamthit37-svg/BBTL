// Hiện thực CameraEuler::UpdateViewMatrix. Sin/cos và thứ tự nhân giữ đúng gốc.
#include "camera/basis.hpp"

#include "math/vector.hpp"

#include <cmath>

namespace game::camera {

Basis basis_of(const Euler& euler) noexcept {
    const float cos_yaw = std::cos(euler.yaw);
    const float sin_yaw = std::sin(euler.yaw);
    const float cos_pitch = std::cos(euler.pitch);
    const float sin_pitch = std::sin(euler.pitch);
    const float cos_roll = std::cos(euler.roll);
    const float sin_roll = std::sin(euler.roll);

    Basis basis;
    basis.forward = {sin_yaw * cos_pitch, sin_pitch, cos_pitch * cos_yaw};
    const float up_x = (-cos_yaw * sin_roll) - (sin_yaw * sin_pitch * cos_roll);
    const float up_z = (-sin_yaw * sin_roll) - (sin_pitch * cos_roll * cos_yaw);
    basis.up = {up_x, cos_pitch * cos_roll, up_z};
    basis.side = cross(basis.forward, basis.up);
    basis.eye = euler.look_at - (basis.forward * euler.distance);
    return basis;
}

} // namespace game::camera
