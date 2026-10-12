// Kính chơi của Thiên Long Bát Bộ: camera bám một điểm trên mặt đất, nhìn xuống 40 độ, xoay quanh
// điểm đó, zoom theo nấc và tự dốc lên khi mắt chạm địa hình.
// Nguồn: G:\TLBB\Dev src/control/follow_camera.{hpp,cpp} và src/control/ground.cpp (camera_box,
// touches_sphere, sphere_touches) ở commit e0d89a6. Bản đó port từ client gốc:
// WXRender/Camera/Camera_Scene.cpp (_GetEyePos, _GetValidPitch, Update), Camera_SetZoom,
// Camera_AddDirection và WXSystem::_adjustCamera. Số mặc định theo Bin/System.cfg của client:
// khoảng cách 6 tới 27,5 đơn vị game, pitch 40 độ, FOV 35 độ.
// Khác gốc: địa hình vào bằng Terrain (lưới độ cao của map) thay cho control::Ground; kiểu toán là
// của module math; vòng nâng pitch viết bằng while, thử cùng dãy giá trị theo cùng thứ tự; hai
// chiều zoom gộp vào dấu của số nấc (zoom_steps).
// Chưa port: rung camera của kỹ năng (AddOneVib).
#pragma once

#include "math/vector.hpp"

#include <cstdint>
#include <span>

namespace game::camera {

// Lưới độ cao của một map: đỉnh (cột, hàng) nằm ở origin + scale * (cột, độ cao thô, hàng).
struct Terrain {
    math::Vector3 origin;
    math::Vector3 scale{100.0F, 100.0F, 100.0F};
    // Số ô theo X và theo Z; lưới có (columns + 1) * (rows + 1) đỉnh.
    int columns = 0;
    int rows = 0;
    // Độ cao thô của từng đỉnh, theo hàng: chỉ số = hàng * (columns + 1) + cột.
    std::span<const float> heights;
};

struct FollowRules {
    float min_distance = 6.0F;
    float max_distance = 27.5F;
    // Góc nhìn xuống so với mặt ngang, độ.
    float pitch_degrees = 40.0F;
    float fov_degrees = 35.0F;
    // Điểm nhìn cao hơn chân nhân vật, đơn vị game.
    float add_height = 0.7F;
    // Hướng ban đầu, radian, đúng hằng của hàm dựng CCamera_Scene.
    // NOLINTNEXTLINE(modernize-use-std-numbers): giữ đúng hằng 3.1416 của bản gốc (HP-07)
    float direction = 3.1416F;
};

// Mắt, điểm nhìn và phép chiếu của một khung hình, trong toạ độ thế giới.
struct FollowPose {
    math::Point3 eye;
    math::Point3 target;
    float fov_degrees = 35.0F;
    float near_plane = 0.25F;
    float far_plane = 150.0F;
};

// Một yêu cầu đặt mắt quanh điểm nhìn: khoảng cách, hướng (radian) và pitch (âm là mắt ở trên).
struct Orbit {
    float distance = 0.0F;
    float direction = 0.0F;
    float pitch = 0.0F;
};

class FollowCamera {
public:
    // Bắt đầu ở khoảng cách xa nhất và pitch chuẩn, như RenderSystem.cpp dựng camera cảnh.
    explicit FollowCamera(FollowRules rules) noexcept;

    // Đặt zoom trong [0, 1]; ngoài khoảng thì bỏ qua, như Camera_SetZoom(FLOAT).
    void set_zoom(float zoom) noexcept;
    // Lại gần hoặc ra xa một số nấc; kẹp trong [0, 1], như Camera_SetZoom(BOOL, INT).
    void zoom_steps(int steps_closer) noexcept;
    // Xoay quanh điểm nhìn, radian, như Camera_AddDirection.
    void turn(float radians) noexcept;
    // Về khoảng cách xa nhất, pitch chuẩn và hướng lúc dựng.
    void home() noexcept;

    [[nodiscard]] float zoom_level() const noexcept;
    [[nodiscard]] float pitch() const noexcept { return pitch_; }
    [[nodiscard]] float direction() const noexcept { return direction_; }

    // Gọi mỗi khung: nhìn vào chân nhân vật (toạ độ thế giới), chỉnh pitch theo địa hình.
    [[nodiscard]] FollowPose update(const Terrain& terrain, math::Point3 foot) noexcept;

private:
    FollowRules rules_;
    // Âm là nhìn xuống, như STATIC_PITCH.
    float static_pitch_ = 0.0F;
    float pitch_ = 0.0F;
    // Đơn vị game, như GetDistance.
    float distance_ = 0.0F;
    float direction_ = 0.0F;
};

// Phím điều khiển kính. Nguồn: G:\TLBB\Dev src/control/player_input.cpp@e0d89a6, hằng của
// GamePro_Main.cpp trong client gốc.
enum class CameraKey : std::uint8_t { kLeft, kRight, kUp, kDown };

// Một lần nhấn phím: trái hoặc phải xoay 0,04 radian, lên hoặc xuống zoom hai nấc.
void apply_key(FollowCamera& camera, CameraKey key) noexcept;
// Lăn chuột: notches dương là lại gần, mỗi nấc lăn zoom hai nấc.
void apply_wheel(FollowCamera& camera, int notches) noexcept;
// Kéo chuột phải dx điểm ảnh: xoay -dx / 300 radian.
void apply_drag(FollowCamera& camera, float dx_pixels) noexcept;

// Vị trí mắt quanh điểm nhìn, như _GetEyePos.
[[nodiscard]] math::Point3 eye_position(math::Point3 target, Orbit orbit) noexcept;

// Căn bậc hai của tỉ lệ x nhân tỉ lệ z, như mBaseScale: thước đo mặt gần và mặt xa.
[[nodiscard]] float base_scale(const Terrain& terrain) noexcept;

// Quả cầu có chạm hộp của các ô quanh đỉnh lưới gần nhất không, như _IsValidEye đảo dấu. Hộp của
// một ô cao tới góc cao nhất của ô và sâu vô hạn.
[[nodiscard]] bool touches_sphere(
    const Terrain& terrain, math::Point3 center, float radius) noexcept;

} // namespace game::camera
