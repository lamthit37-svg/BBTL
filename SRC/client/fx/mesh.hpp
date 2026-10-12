// Tư thế hạt mesh. Nguồn: OgreMeshParticleRenderer::_notifyParticleMoved và
// MeshParticleVisualData::setScale / setOrientation. Nút mesh là con của hệ hạt,
// nên tư thế trả về là cục bộ; nơi vẽ nhân với nút cha.
// Góc đã là radian (parseAngle). Thứ tự OGRE: yaw quanh Y, rồi pitch quanh X, rồi roll quanh Z.
// Scale: trục x và z cùng bề rộng, trục y là bề cao.
#pragma once

#include "fx/field.hpp"

#include <vector>

namespace game::fx {

struct MeshPose {
    ogre::Vec3 position{};
    ogre::Quat orientation{};
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
};

// Rỗng khi hệ không phải renderer mesh hoặc thiếu mesh_name.
[[nodiscard]] std::vector<MeshPose> mesh_poses(const Field& field);

} // namespace game::fx
