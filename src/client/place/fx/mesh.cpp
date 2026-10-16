#include "fx/mesh.hpp"

#include "fx/billboard.hpp"
#include "ogre/quat.hpp"

#include <cmath>

namespace game::fx {
namespace {

using ogre::Quat;
using ogre::Vec3;

constexpr float kTiny = 1.0e-6F;

// Camera trong hệ của nút hạt: bản gốc đổi camera về hệ nút rồi mới tính hướng mesh
// (MeshParticleRenderer::_notifyCurrentCamera, Render.dll 0x1801450b0).
struct Eye {
    // Trục +z của camera, từ cảnh về phía người xem (camera OGRE nhìn theo -z).
    Vec3 back{.z = 1.0F};
    Vec3 up{.y = 1.0F};
    Vec3 position{};
};

[[nodiscard]] Eye eye_in(const Field& field, const CameraAxes& axes) {
    const Node& node = field.node();
    const Quat inverse = ogre::quat_inverse(node.orientation);
    const Vec3 backward = ogre::scale_vec3(axes.forward, -1.0F);
    const Vec3 shifted = ogre::sub_vec3(axes.eye, node.position);
    const Vec3 turned = ogre::quat_rotate(inverse, shifted);
    Eye eye;
    eye.back = ogre::quat_rotate(inverse, backward);
    eye.up = ogre::quat_rotate(inverse, axes.up);
    eye.position = ogre::div_vec3(turned, node.scale);
    return eye;
}

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

[[nodiscard]] bool is_flat(Vec3 axis) {
    return ogre::length_vec3(axis) < kTiny;
}

// Ba trục xoay của mesh: x ngang, y dọc, z hướng ra khỏi mặt.
struct Axes {
    Vec3 across{};
    Vec3 ahead{};
    Vec3 toward{};
};

// Các nhánh của FromRotationMatrix. Vết ma trận dương thì dùng w làm gốc căn.
[[nodiscard]] Quat quat_by_trace(const Axes& axes, float trace) {
    const Vec3& across = axes.across;
    const Vec3& ahead = axes.ahead;
    const Vec3& toward = axes.toward;
    const float root = std::sqrt(trace + 1.0F);
    const float half = 0.5F / root;
    const float part_x = (ahead.z - toward.y) * half;
    const float part_y = (toward.x - across.z) * half;
    const float part_z = (across.y - ahead.x) * half;
    return Quat{.x = part_x, .y = part_y, .z = part_z, .w = 0.5F * root};
}

// Vết không dương thì trục trội nhất cho gốc căn.
[[nodiscard]] Quat quat_by_x(const Axes& axes) {
    const Vec3& across = axes.across;
    const Vec3& ahead = axes.ahead;
    const Vec3& toward = axes.toward;
    const float root = std::sqrt(across.x - ahead.y - toward.z + 1.0F);
    const float half = 0.5F / root;
    const float part_y = (across.y + ahead.x) * half;
    const float part_z = (across.z + toward.x) * half;
    const float part_w = (ahead.z - toward.y) * half;
    return Quat{.x = 0.5F * root, .y = part_y, .z = part_z, .w = part_w};
}

[[nodiscard]] Quat quat_by_y(const Axes& axes) {
    const Vec3& across = axes.across;
    const Vec3& ahead = axes.ahead;
    const Vec3& toward = axes.toward;
    const float root = std::sqrt(ahead.y - toward.z - across.x + 1.0F);
    const float half = 0.5F / root;
    const float part_x = (ahead.x + across.y) * half;
    const float part_z = (ahead.z + toward.y) * half;
    const float part_w = (toward.x - across.z) * half;
    return Quat{.x = part_x, .y = 0.5F * root, .z = part_z, .w = part_w};
}

[[nodiscard]] Quat quat_by_z(const Axes& axes) {
    const Vec3& across = axes.across;
    const Vec3& ahead = axes.ahead;
    const Vec3& toward = axes.toward;
    const float root = std::sqrt(toward.z - across.x - ahead.y + 1.0F);
    const float half = 0.5F / root;
    const float part_x = (toward.x + across.z) * half;
    const float part_y = (toward.y + ahead.z) * half;
    const float part_w = (across.y - ahead.x) * half;
    return Quat{.x = part_x, .y = part_y, .z = 0.5F * root, .w = part_w};
}

// Quaternion::FromAxes của OGRE: ba trục là ba cột của ma trận xoay (FromRotationMatrix).
[[nodiscard]] Quat quat_from_axes(const Axes& axes) {
    const float trace = axes.across.x + axes.ahead.y + axes.toward.z;
    if (trace > 0.0F) return quat_by_trace(axes, trace);
    const bool is_x = axes.across.x >= axes.ahead.y && axes.across.x >= axes.toward.z;
    if (is_x) return quat_by_x(axes);
    if (axes.ahead.y >= axes.toward.z) return quat_by_y(axes);
    return quat_by_z(axes);
}

// Trục y mesh chạy dọc `along`, mặt mesh quay về camera (oriented_self, oriented_common).
// Khác gốc: trục suy biến (along song song hướng camera) cho phép xoay đơn vị, không chuẩn hoá
// vector 0.
[[nodiscard]] Quat face_along(Vec3 along, const Eye& eye) {
    const Vec3 direction = ogre::normalize_vec3(along);
    const Vec3 across = ogre::normalize_vec3(ogre::cross_vec3(direction, eye.back));
    if (is_flat(across)) return Quat{};
    const Vec3 toward = ogre::cross_vec3(across, direction);
    const Axes axes{.across = across, .ahead = direction, .toward = toward};
    return quat_from_axes(axes);
}

// Mặt mesh vuông góc `along`, trục x vuông góc với `up` (perpendicular_common, perpendicular_self).
[[nodiscard]] Quat face_flat(Vec3 sky, Vec3 along) {
    const Vec3 across = ogre::normalize_vec3(ogre::cross_vec3(sky, along));
    const Vec3 ahead = ogre::normalize_vec3(ogre::cross_vec3(along, across));
    if (is_flat(across) || is_flat(ahead)) return Quat{};
    const Vec3 toward = ogre::cross_vec3(across, ahead);
    const Axes axes{.across = across, .ahead = ahead, .toward = toward};
    return quat_from_axes(axes);
}

// Trục z mesh hướng vào camera, trục y theo hướng "lên" của camera (oriented_camera).
[[nodiscard]] Quat face_camera(Vec3 position, const Eye& eye) {
    const Vec3 toward = ogre::normalize_vec3(ogre::sub_vec3(eye.position, position));
    const Vec3 across = ogre::normalize_vec3(ogre::cross_vec3(eye.up, toward));
    if (is_flat(across)) return Quat{};
    const Vec3 ahead = ogre::cross_vec3(toward, across);
    const Axes axes{.across = across, .ahead = ahead, .toward = toward};
    return quat_from_axes(axes);
}

// oriented_camera nhân góc roll của hạt vào sau phép quay về camera.
[[nodiscard]] Quat turn_camera(const Grain& grain, Vec3 position, const Eye& eye) {
    const Quat roll = ogre::quat_from_angle_axis(grain.angles.z, Vec3{.z = 1.0F});
    return ogre::quat_multiply(face_camera(position, eye), roll);
}

// Phép xoay của nút ngoài (MeshParticleRenderer::_updateRenderQueue, Render.dll 0x1801452e0):
// góc MeshRotator trước, kiểu xoay sau; oriented_camera nhân góc roll vào sau.
[[nodiscard]] Quat outer_turn(const Field& field, const Grain& grain, Vec3 position,
    const Eye& eye) {
    const SystemDef& definition = field.definition();
    const Quat spin = euler_of(grain.angles);
    const Vec3 common = definition.common_direction;
    switch (definition.facing) {
    case MeshFacing::kOrigin: return spin;
    case MeshFacing::kSelf: return ogre::quat_multiply(spin, face_along(grain.direction, eye));
    case MeshFacing::kCamera: return turn_camera(grain, position, eye);
    case MeshFacing::kCommon: return ogre::quat_multiply(spin, face_along(common, eye));
    case MeshFacing::kPerpendicularCommon:
        return ogre::quat_multiply(spin, face_flat(definition.common_up, common));
    case MeshFacing::kPerpendicularSelf:
        return ogre::quat_multiply(spin, face_flat(definition.common_up, grain.direction));
    }
    return spin;
}

void push_pose(std::vector<MeshPose>& poses, const Field& field, const Eye& eye,
    std::uint32_t index) {
    const Grain& grain = field.grain(index);
    const SystemDef& definition = field.definition();
    const float width = grain.own ? grain.width : definition.width;
    const float height = grain.own ? grain.height : definition.height;
    const float depth = grain.own ? grain.depth : definition.depth;
    const Vec3 scale{.x = width, .y = height, .z = depth};
    const Vec3 position = parent_local(field, grain.position);
    const Quat outer = outer_turn(field, grain, position, eye);
    // Nút trong là con của nút ngoài: vị trí cục bộ nhân scale rồi xoay theo nút ngoài
    // (Node::_updateFromParent).
    const Vec3 shift = ogre::mul_vec3(scale, definition.local_position);
    MeshPose pose;
    pose.position = ogre::add_vec3(position, ogre::quat_rotate(outer, shift));
    pose.orientation = ogre::quat_multiply(outer, definition.local_rotation);
    pose.scale = scale;
    pose.colour = grain.colour;
    poses.push_back(pose);
}

} // namespace

std::vector<MeshPose> mesh_poses(const Field& field, const CameraAxes& axes) {
    std::vector<MeshPose> poses;
    if (field.definition().renderer != RendererKind::kMesh) return poses;
    if (field.definition().mesh_name.empty()) return poses;
    const Eye eye = eye_in(field, axes);
    for (const std::uint32_t index : field.order())
        push_pose(poses, field, eye, index);
    return poses;
}

} // namespace game::fx
