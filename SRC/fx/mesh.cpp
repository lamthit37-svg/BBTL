#include "fx/mesh.hpp"

#include "ogre/quat.hpp"

namespace game::fx {
namespace {

using ogre::Quat;
using ogre::Vec3;

[[nodiscard]] Vec3 parent_local(const Field& field, Vec3 position) {
    if (field.definition().local_space) return position;
    const Vec3 shifted = ogre::sub_vec3(position, field.node().position);
    const Quat inverse = ogre::quat_inverse(field.node().orientation);
    const Vec3 turned = ogre::quat_rotate(inverse, shifted);
    return ogre::div_vec3(turned, field.node().scale);
}

[[nodiscard]] Quat euler_of(Vec3 radians) {
    const Quat yaw = ogre::quat_from_angle_axis(radians.x, Vec3{.y = 1.0F});
    const Quat pitch = ogre::quat_from_angle_axis(radians.y, Vec3{.x = 1.0F});
    const Quat roll = ogre::quat_from_angle_axis(radians.z, Vec3{.z = 1.0F});
    const Quat pitched = ogre::quat_multiply(pitch, roll);
    return ogre::quat_multiply(yaw, pitched);
}

void push_pose(std::vector<MeshPose>& poses, const Field& field, std::uint32_t index) {
    const Grain& grain = field.grain(index);
    const float width = grain.own ? grain.width : field.definition().width;
    const float height = grain.own ? grain.height : field.definition().height;
    MeshPose pose;
    pose.position = parent_local(field, grain.position);
    pose.orientation = euler_of(grain.angles);
    pose.scale = Vec3{.x = width, .y = height, .z = width};
    poses.push_back(pose);
}

} // namespace

std::vector<MeshPose> mesh_poses(const Field& field) {
    std::vector<MeshPose> poses;
    if (field.definition().renderer != RendererKind::kMesh) return poses;
    if (field.definition().mesh_name.empty()) return poses;
    for (const std::uint32_t index : field.order())
        push_pose(poses, field, index);
    return poses;
}

} // namespace game::fx
