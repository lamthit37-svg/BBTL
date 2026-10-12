// Nền của màn đăng nhập của client 2026: cảnh nào và nhìn từ đâu. Thủ tục đăng nhập không dùng
// camera cảnh hay camera chọn nhân vật; nó đặt thẳng một tư thế cố định lên Ogre::Camera.
// Port từ mã máy (docs/CAMERA-2026.md, mục màn đăng nhập): CGamePro_Login::Init (Game.exe
// 0x140630900) nạp "erengu_DL.Scene" rồi gọi ô +0x260 của CRenderSystem (Render.dll 0x18002ae90),
// hàm này kết thúc ở 0x180002a30: setFOVy(42 độ), setPosition, setOrientation,
// setFarClipDistance(40000). Hàm đó không đặt mặt gần; số còn lại trên Ogre::Camera là 5, do
// CCamera_Scene::Update đặt lúc CRenderSystem::Initial dựng camera cảnh (0x180026115).
// Đơn vị và hệ trục giữ nguyên của OGRE: centimet, tay phải, y lên; quaternion ở đây xếp x y z w,
// còn mã máy ghi theo thứ tự w x y z của Ogre::Quaternion.
#pragma once

#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <string_view>

namespace game::control {

// Một tư thế camera cố định: vị trí, hướng (quaternion đơn vị), góc nhìn dọc và hai mặt cắt.
struct FixedView {
    ogre::Vec3 eye;
    ogre::Quat orientation;
    float fov_degrees = 45.0F;
    float near_plane = 5.0F;
    float far_plane = 15000.0F;
};

// Tên cảnh nền của màn đăng nhập (tệp Scene/<tên>.Scene); cảnh này không có dòng trong bảng cảnh.
inline constexpr std::string_view kLoginScene = "erengu_DL";

inline constexpr FixedView kLoginView{
    .eye = {.x = -2279.21F, .y = 4462.81F, .z = -8181.77F},
    .orientation = {.x = -0.00902838F, .y = -0.968889F, .z = -0.0357472F, .w = 0.244674F},
    .fov_degrees = 42.0F,
    .near_plane = 5.0F,
    .far_plane = 40000.0F,
};

// Bảy chữ số của mã máy đủ để quaternion là đơn vị trong sai số float; lệch là chép sai một số.
inline constexpr float kLoginTurnNorm = ogre::quat_dot(kLoginView.orientation, kLoginView.orientation);
static_assert(kLoginTurnNorm > 0.9999F && kLoginTurnNorm < 1.0001F);

} // namespace game::control
