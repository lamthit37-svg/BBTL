// Tư thế hạt mesh. Nguồn: MeshParticleRenderer::_updateRenderQueue (Render.dll 0x1801452e0) và
// MeshParticleVisualData (0x1801f4a90). Mỗi hạt có nút ngoài (vị trí hạt, scale = particle_width,
// particle_height, particle_depth, phép xoay theo orientation_type) và nút trong là con
// (local_position, local_rotation). Nút mesh là con của hệ hạt, nên tư thế trả về là cục bộ;
// nơi vẽ nhân với nút cha.
// Góc đã là radian (parseAngle). Thứ tự OGRE: yaw quanh Y, rồi pitch quanh X, rồi roll quanh Z.
// Scale theo trục của mesh (OGRE nhân scale cha với scale con từng thành phần): x bề rộng,
// y bề cao, z bề sâu. Mặc định bề sâu là 0 nên mesh không khai particle_depth bị dẹt theo trục z.
#pragma once

#include "fx/billboard.hpp"
#include "fx/field.hpp"

#include <vector>

namespace game::fx {

struct MeshPose {
    ogre::Vec3 position{};
    ogre::Quat orientation{};
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    // Màu hạt sau ColourFading (rgb và alpha đã nhân độ mờ). Bản gốc đưa nó vào chất liệu của hạt
    // bằng Material::setSelfIlluminationAndDiffuseAlpha (Render.dll 0x1801f4570): rgb thành
    // emissive, cộng vào màu đỉnh rồi nhân với ảnh; alpha nhân vào alpha của ảnh (Particle_ps:
    // surface_diffuse_colour.a).
    Colour colour{1.0F, 1.0F, 1.0F, 1.0F};
};

// Rỗng khi hệ không phải renderer mesh hoặc thiếu mesh_name. Camera cho kiểu xoay theo camera.
[[nodiscard]] std::vector<MeshPose> mesh_poses(const Field& field, const CameraAxes& axes);

} // namespace game::fx
