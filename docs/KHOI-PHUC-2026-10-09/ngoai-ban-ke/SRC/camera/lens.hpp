// Ống kính Cool3D CameraBase: nhìn D3DX tay trái, chiếu FovLH, đổi điểm màn hình.
// fov_y là radian sau set_perspective. Hàm dựng gốc ghi 30 khi ma trận còn đơn vị.
// SetZFar và SetZNear của phép song song gốc đổi chỗ rộng với cao: giữ đúng chỗ đó.
// Cubemap nhân theo cột, mặt * view. Mặt 0..5 là +X, −X, +Y, −Y, +Z, −Z.
// render_matrices là tay phải, độ sâu đảo, cùng mắt và đích, cho gpu của dự án.
// Tự up: nhìn thẳng xuống thì +Z, không thì dir × (Y × dir).
// GetMouseRay đẩy gốc tia thêm đúng một lần z_near sau khi đã đứng trên mặt gần.
// Khác gốc: up ban đầu là trục Y; mắt trùng đích thì giữ ma trận cũ, không ra NaN.
#pragma once

#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"

#include <cstdint>

namespace game::camera {

struct Viewport {
    float width = 400.0F;
    float height = 400.0F;
};

struct DepthRange {
    float z_near = 10.0F;
    float z_far = 1000.0F;
};

struct Pose {
    math::Point3 eye{};
    math::Point3 target{};
    math::Vector3 up{0.0F, 1.0F, 0.0F};
};

struct Aim {
    math::Point3 eye{};
    math::Point3 target{};
};

struct Pixel {
    std::int32_t x = 0;
    std::int32_t y = 0;
};

struct Lens {
    Viewport viewport{};
    DepthRange depth{};
    float fov_y = 30.0F;
    math::Point3 eye{};
    math::Point3 look_at{};
    math::Vector3 up{0.0F, 1.0F, 0.0F};
    math::Matrix4 view = math::Matrix4::identity();
    math::Matrix4 inverse_view = math::Matrix4::identity();
    math::Matrix4 projection = math::Matrix4::identity();
    math::Matrix4 inverse_projection = math::Matrix4::identity();
};

struct RenderMatrices {
    math::Matrix4 view = math::Matrix4::identity();
    math::Matrix4 projection = math::Matrix4::identity();
};

// Nhìn tay trái. Mắt trùng đích thì giữ nguyên.
void set_look_at(Lens& lens, const Pose& pose) noexcept;
// Tự chọn up khi người gọi không đưa.
void set_look_at(Lens& lens, Aim aim) noexcept;
// Nhìn tự up, rồi nhân view với mặt cubemap.
void set_look_at(Lens& lens, Aim aim, math::CubeFace face) noexcept;

void set_perspective(Lens& lens, Viewport viewport, float fov_y, DepthRange depth) noexcept;
void set_ortho(Lens& lens, Viewport viewport, DepthRange depth) noexcept;
void set_z_far(Lens& lens, float z_far) noexcept;
void set_z_near(Lens& lens, float z_near) noexcept;

// Co _11 và _22 để hộp vừa khung, đúng hai nhánh gốc.
void adjust_adaptive(Lens& lens, const math::Aabb& box) noexcept;

// Chiếu lại với gần/xa mới. fov_y > 0 thì phối cảnh.
[[nodiscard]] math::Matrix4 projection_for(const Lens& lens, DepthRange depth) noexcept;
// Nhân _33 với (1 + scale), bản GetPrjZBias một số.
[[nodiscard]] math::Matrix4 projection_z_bias(const Lens& lens, float scale) noexcept;

struct BiasQuery {
    float delta = 0.0F;
    math::Point3 reference{};
};

// Epsilon theo điểm rồi nhân _33, bản GetPrjZBias hai số.
[[nodiscard]] math::Matrix4 projection_z_bias_at(const Lens& lens, BiasQuery bias) noexcept;

[[nodiscard]] math::Vector3 world_to_ndc(const Lens& lens, math::Point3 world) noexcept;
[[nodiscard]] Pixel world_to_screen(const Lens& lens, math::Point3 world) noexcept;
[[nodiscard]] Pixel ndc_to_screen(const Lens& lens, math::Vector3 ndc) noexcept;
[[nodiscard]] math::Point3 screen_to_world(const Lens& lens, Pixel pixel) noexcept;
// Tia qua điểm gần, gốc bị đẩy thêm một z_near.
[[nodiscard]] math::Ray mouse_ray(const Lens& lens, Pixel pixel) noexcept;
// Hướng từ mắt tới đích. Trùng điểm thì ra vectơ 0.
[[nodiscard]] math::Vector3 direction_of(const Lens& lens) noexcept;

// Tay phải, độ sâu đảo. fov_y là radian đang lưu.
[[nodiscard]] RenderMatrices render_matrices(const Lens& lens) noexcept;

} // namespace game::camera
