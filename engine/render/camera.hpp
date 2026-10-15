/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/camera.hpp
 *  PHÂN HỆ   : Render / Camera
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Camera của một khung hình: nhìn từ mắt tới điểm nhìn (look_camera), đặt
 *    bằng vị trí và hướng (posed_camera), quay quanh một điểm (orbit_camera),
 *    hay lùi vừa một khung bao (frame_camera); cắt khuất hộp và hình cầu; cùng
 *    hai tiện ích model: ma trận nút ở tư thế nghỉ và hộp bao ở một tư thế. Quy
 *    ước của gpu: hệ tay phải như glTF (camera nhìn theo -Z), NDC có Y hướng
 *    lên, độ sâu đảo (mặt gần ra 1, mặt xa ra 0).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn: Forge2 src/render/camera.hpp@d7fcd76 (Camera, rest_nodes, bounds_of); TLBB Dev src/render/camera.hpp và
// camera.cpp@e0d89a6 (frame_camera, orbit, look, box_in_view, frustum). Khác gốc: không có bgfx nên bỏ cờ
// homogeneous_depth; phép chiếu luôn là độ sâu đảo; mặt xa của cắt khuất là z >= 0 thay cho w - z; cooked::MeshBounds
// thành SceneBounds.

#pragma once

#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/quat.hpp"
#include "math/vector.hpp"
#include "render/view_size.hpp"
#include "resource/model.hpp"

#include <array>
#include <span>
#include <vector>

namespace game::render {

struct Camera {
    // Thế giới sang không gian camera.
    math::Matrix4 view = math::Matrix4::identity();
    // Không gian camera sang clip space, độ sâu đảo.
    math::Matrix4 projection = math::Matrix4::identity();
    // Chiều cao khung dựng theo điểm ảnh, để Forward chọn mức chi tiết theo kích thước trên màn hình. 0 thì luôn vẽ mức
    // đủ chi tiết.
    float pixels_high = 0.0F;
};

// Ma trận không gian mô hình của mọi nút ở tư thế nghỉ của tệp, theo chỉ số nút.
[[nodiscard]] std::vector<math::Matrix4> rest_nodes(const resource::Model& model);

// Hộp bao mọi đỉnh của model khi các nút nằm ở nodes (theo chỉ số nút). Lưới có skin tính ở tư thế
// bind: glTF bỏ qua biến đổi của nút mang lưới ấy, và tư thế bind là chỗ lưới được dựng. Model
// không có đỉnh nào trả hộp rỗng.
[[nodiscard]] math::Aabb bounds_of(const resource::Model& model, std::span<const math::Matrix4> nodes);

// Camera quay quanh một điểm: nhìn chếch từ trên xuống, lùi radius nhân 3,2, hướng nhìn xoay quanh
// trục y một góc angle (radian). Dùng để xem một cảnh.
struct Orbit {
    math::Vector3 centre;
    float radius = 1.0F;
    float angle = 0.0F;
};

[[nodiscard]] Camera orbit_camera(Orbit orbit, ViewSize size) noexcept;

// Ống kính của camera người chơi: FOV dọc và hai mặt cắt, đơn vị thế giới.
struct Lens {
    float fov_degrees = 35.0F;
    float near_plane = 0.25F;
    float far_plane = 150.0F;
};

// Camera nhìn từ eye tới target, trục lên +y, như Camera_Scene của client gốc đặt Ogre::Camera bằng
// setPosition rồi lookAt. Tỉ lệ khung lấy từ size; chiều cao 0 thì coi như khung vuông.
[[nodiscard]] Camera look_camera(math::Point3 eye, math::Point3 target, Lens lens, ViewSize size) noexcept;

// Camera đặt bằng vị trí và hướng, như Ogre::Camera sau setPosition và setOrientation: nhìn theo -z
// của hướng, trục lên là +y của hướng, nên giữ được cả góc nghiêng mà look_camera không biểu diễn
// được. turn phải là quaternion đơn vị.
[[nodiscard]] Camera posed_camera(math::Point3 eye, const math::Quat& turn, Lens lens, ViewSize size) noexcept;

// Khung bao thế giới kèm bán kính, đứng chỗ cooked::MeshBounds của TLBB Dev. Bán kính 0 nghĩa là
// chưa khai: frame_camera lấy nửa đường chéo, hộp rỗng thì bán kính 1.
struct SceneBounds {
    math::Vector3 min;
    math::Vector3 max;
    float radius = 0.0F;
};

// Điền bán kính bằng nửa đường chéo; hộp rỗng ra 1 để camera vẫn dựng được.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): min rồi max, chữ ký của TLBB Dev (HP-07)
[[nodiscard]] SceneBounds bounds_with_radius(math::Vector3 low, math::Vector3 high) noexcept;

// Đặt camera nhìn chếch từ trên xuống, lùi đủ xa để khung bao nằm trọn trong khung vẽ.
[[nodiscard]] Camera frame_camera(SceneBounds bounds, ViewSize size) noexcept;

// Hộp còn thấy qua ma trận clip (projection * view) hay không: chỉ loại khi cả tám góc cùng ngoài
// một mặt.
[[nodiscard]] bool box_in_view(const math::Matrix4& clip, const SceneBounds& box) noexcept;

// Sáu mặt khung nhìn trong thế giới, cùng thứ tự với box_in_view; dương là phía trong.
struct Frustum {
    std::array<math::Vector4, 6> planes{};
};

[[nodiscard]] Frustum frustum_of(const math::Matrix4& clip) noexcept;

// Hình cầu còn thấy hay không: chỉ loại khi nằm hẳn ngoài một mặt.
[[nodiscard]] bool sphere_in_view(const Frustum& frustum, math::Vector3 centre, float radius) noexcept;

} // namespace game::render
