#pragma once
// Tia từ một điểm trên màn hình vào cảnh, như Camera::getCameraToViewportRay của OGRE ở nhánh chiếu
// phối cảnh: gốc tia là mắt, tia đi qua điểm tương ứng trên mặt gần. Tính thẳng từ mắt, hướng nhìn,
// góc nhìn dọc và tỉ lệ khung của camera, nên tia khớp đúng hình đang vẽ mà không phụ thuộc quy ước
// độ sâu hay chiều trục y của backend; mọi backend của dự án đều vẽ ảnh không bị lật gương.
// Nguồn: TLBB Dev src/control/view_ray.hpp và view_ray.cpp@e0d89a6. Khác gốc: tính từ thông số của
// camera thay cho nghịch đảo của chiếu nhân nhìn (dự án chưa có nghịch đảo 4x4 và không cần cờ độ
// sâu); chưa có mặt công trình.

#include "control/ground.hpp"
#include "core/ground_point.hpp"
#include "ogre/vec3.hpp"

#include <optional>

namespace game::control {

// Điểm trên màn hình, mỗi trục trong [0, 1], gốc ở góc trái trên như toạ độ chuột.
struct ScreenPoint {
    float x = 0.5F;
    float y = 0.5F;
};

// Thông số nhìn của camera: mắt, hướng nhìn đơn vị, góc nhìn dọc (radian) và tỉ lệ rộng trên cao.
// "Lên" của màn hình là +y của thế giới.
struct Lens {
    ogre::Vec3 eye;
    ogre::Vec3 forward;
    float fov_y = 0.0F;
    float aspect = 1.0F;
};

// Tia qua điểm màn hình; hướng đơn vị.
[[nodiscard]] Ray screen_ray(const Lens& lens, ScreenPoint point);

// Chỗ đứng (toạ độ game) dưới điểm màn hình: điểm địa hình mà tia chạm trước; không có khi tia
// không chạm địa hình, như bản gốc.
[[nodiscard]] std::optional<core::GroundPoint> pick_ground(const Ground& ground, const Lens& lens, ScreenPoint point);

} // namespace game::control
