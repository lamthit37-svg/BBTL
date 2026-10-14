// Dựng rig từ skeleton đã nấu và ra ma trận skin. Phép tính theo đúng toán tử và thứ tự của các hàm
// OGRE 1.2.5 ghi ở từng hàm; cây xương cập nhật cha trước con như Node::_update đệ quy từ xương
// gốc.
// Nguồn: TLBB Dev src/anim/rig.cpp@e0d89a6. Khác gốc: namespace game::anim, kiểu toán ở game::ogre;
// thân các vòng lặp có nhánh tách thành hàm một lượt và điều kiện dừng đưa lên điều kiện lặp (cổng
// của dự án cấm `if` trong vòng lặp); tên biến dài hơn ba ký tự; make_transform nhận Transform
// thay cho ba tham số cùng nhóm; mọi phép tính giữ đúng toán tử và thứ tự.
#include "anim/rig.hpp"

#include "anim/asset.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::anim {
namespace {

using ogre::Quat;
using ogre::Vec3;

constexpr Vec3 kUnitScale{.x = 1.0F, .y = 1.0F, .z = 1.0F};

// Kiểm dựng rig

// Đặt tư thế của một xương vào chỗ handle của nó; handle phải nằm trong miền và chưa gặp.
[[nodiscard]] std::optional<RigError> place_bone(std::vector<Transform>& initial, std::vector<bool>& seen,
    const Bone& bone) {
    if (bone.handle >= initial.size()) return RigError::kBadHandle;
    if (seen[bone.handle]) return RigError::kDuplicateHandle;
    seen[bone.handle] = true;
    initial[bone.handle] = Transform{.position = bone.position, .orientation = bone.orientation, .scale = bone.scale};
    return std::nullopt;
}

// Handle phải liền từ 0 và không trùng, như mBoneList của Skeleton đánh chỉ số bằng handle.
std::expected<std::vector<Transform>, RigError> initial_by_handle(const SourceSkeleton& skeleton) {
    const std::size_t count = skeleton.bones.size();
    std::vector<Transform> initial(count);
    std::vector<bool> seen(count, false);
    std::optional<RigError> failure;
    for (std::size_t index = 0; index < count && !failure; ++index) {
        failure = place_bone(initial, seen, skeleton.bones[index]);
    }
    if (failure) return std::unexpected(*failure);
    return initial;
}

// Ghi cạnh cha con vào bảng cha; cạnh phải trỏ xương có thật và xương con chưa có cha.
[[nodiscard]] std::optional<RigError> link_parent(std::vector<std::int32_t>& parent, const BoneParent& edge) {
    const bool known = edge.child < parent.size() && edge.parent < parent.size();
    if (!known) return RigError::kBadParent;
    if (parent[edge.child] >= 0) return RigError::kSecondParent;
    parent[edge.child] = edge.parent;
    return std::nullopt;
}

// Cha của từng xương, -1 là gốc. Node::addChild không cho một nút có hai cha.
std::expected<std::vector<std::int32_t>, RigError> parents_by_handle(const SourceSkeleton& skeleton) {
    std::vector<std::int32_t> parent(skeleton.bones.size(), -1);
    std::optional<RigError> failure;
    for (std::size_t index = 0; index < skeleton.parents.size() && !failure; ++index) {
        failure = link_parent(parent, skeleton.parents[index]);
    }
    if (failure) return std::unexpected(*failure);
    return parent;
}

// Thêm xương con vào cuối order khi cha của nó đúng là head.
void append_if_child(const std::vector<std::int32_t>& parent, std::int32_t head, std::size_t child,
    std::vector<std::uint16_t>& order) {
    if (parent[child] == head) order.push_back(static_cast<std::uint16_t>(child));
}

// Thêm mọi con trực tiếp của head vào cuối order.
void append_children(const std::vector<std::int32_t>& parent, std::int32_t head, std::vector<std::uint16_t>& order) {
    for (std::size_t child = 0; child < parent.size(); ++child) {
        append_if_child(parent, head, child, order);
    }
}

// Thứ tự cha trước con, đi theo chiều rộng từ các xương gốc. Xương không tới được từ gốc nào nằm
// trong một vòng cha con.
std::expected<std::vector<std::uint16_t>, RigError> update_order(const std::vector<std::int32_t>& parent) {
    std::vector<std::uint16_t> order;
    order.reserve(parent.size());
    append_children(parent, -1, order);
    for (std::size_t cursor = 0; cursor < order.size(); ++cursor) {
        append_children(parent, order[cursor], order);
    }
    if (order.size() != parent.size()) return std::unexpected(RigError::kCycle);
    return order;
}

// Phép biến đổi

// Bone::setBindingPose: vị trí đảo dấu, scale lấy nghịch đảo từng trục, hướng lấy
// Quaternion::Inverse, đều của biến đổi derived lúc bind.
Transform bind_inverse_of(const Transform& derived) {
    Transform inverse;
    inverse.position = ogre::scale_vec3(derived.position, -1.0F);
    inverse.scale = ogre::div_vec3(kUnitScale, derived.scale);
    inverse.orientation = ogre::quat_inverse(derived.orientation);
    return inverse;
}

// Ma trận quay 3x3 của Quaternion::ToRotationMatrix, theo hàng.
using Rotation = std::array<std::array<float, 3>, 3>;

Rotation rotation_matrix(Quat rotation) {
    const float two_x = 2.0F * rotation.x;
    const float two_y = 2.0F * rotation.y;
    const float two_z = 2.0F * rotation.z;
    const float two_wx = two_x * rotation.w;
    const float two_wy = two_y * rotation.w;
    const float two_wz = two_z * rotation.w;
    const float two_xx = two_x * rotation.x;
    const float two_xy = two_y * rotation.x;
    const float two_xz = two_z * rotation.x;
    const float two_yy = two_y * rotation.y;
    const float two_yz = two_z * rotation.y;
    const float two_zz = two_z * rotation.z;
    Rotation rot{};
    rot[0] = {1.0F - (two_yy + two_zz), two_xy - two_wz, two_xz + two_wy};
    rot[1] = {two_xy + two_wz, 1.0F - (two_xx + two_zz), two_yz - two_wx};
    rot[2] = {two_xz - two_wy, two_yz + two_wx, 1.0F - (two_xx + two_yy)};
    return rot;
}

// Matrix4::makeTransform: scale trước, quay sau, dịch cuối; cột j của ma trận quay nhân scale trục
// j.
Affine make_transform(const Transform& placed) {
    const Rotation rot = rotation_matrix(placed.orientation);
    const std::array<float, 3> factor = {placed.scale.x, placed.scale.y, placed.scale.z};
    const std::array<float, 3> move = {placed.position.x, placed.position.y, placed.position.z};
    Affine out{};
    for (std::size_t row = 0; row < 3; ++row) {
        const std::array<float, 3>& line = rot.at(row);
        out.at(row * 4) = line.at(0) * factor.at(0);
        out.at((row * 4) + 1) = line.at(1) * factor.at(1);
        out.at((row * 4) + 2) = line.at(2) * factor.at(2);
        out.at((row * 4) + 3) = move.at(row);
    }
    return out;
}

// Bone::_getOffsetTransform: ghép scale, hướng với nghịch đảo bind; phần dịch đưa vị trí bind về
// không gian bind của xương rồi sang không gian hiện tại.
Affine offset_transform(const Transform& derived, const Transform& inverse) {
    const Vec3 scale = ogre::mul_vec3(derived.scale, inverse.scale);
    const Quat rotate = ogre::quat_multiply(derived.orientation, inverse.orientation);
    const Vec3 moved = ogre::quat_rotate(rotate, ogre::mul_vec3(scale, inverse.position));
    const Vec3 translate = ogre::add_vec3(derived.position, moved);
    return make_transform(Transform{.position = translate, .orientation = rotate, .scale = scale});
}

} // namespace

Affine affine_of(const Transform& placed) {
    return make_transform(placed);
}

// Hướng nhân hướng cha, scale nhân scale cha, vị trí co theo scale cha, quay theo hướng cha rồi
// cộng vị trí cha.
Transform from_parent(const Transform& parent, const Transform& local) {
    Transform derived;
    derived.orientation = ogre::quat_multiply(parent.orientation, local.orientation);
    derived.scale = ogre::mul_vec3(parent.scale, local.scale);
    const Vec3 scaled = ogre::mul_vec3(parent.scale, local.position);
    const Vec3 turned = ogre::quat_rotate(parent.orientation, scaled);
    derived.position = ogre::add_vec3(turned, parent.position);
    return derived;
}

// Skeleton::setBindingPose: tư thế trong tệp là trạng thái đầu, nghịch đảo derived của nó giữ lại
// để tính ma trận skin.
RigResult Rig::create(const SourceSkeleton& skeleton) {
    if (skeleton.bones.empty()) return std::unexpected(RigError::kEmpty);
    auto initial = initial_by_handle(skeleton);
    if (!initial) return std::unexpected(initial.error());
    auto parent = parents_by_handle(skeleton);
    if (!parent) return std::unexpected(parent.error());
    auto order = update_order(*parent);
    if (!order) return std::unexpected(order.error());
    Rig rig;
    rig.initial_ = std::move(*initial);
    rig.parent_ = std::move(*parent);
    rig.order_ = std::move(*order);
    const std::vector<Transform> derived = rig.derive(rig.initial_);
    rig.bind_inverse_.reserve(derived.size());
    for (const Transform& bone : derived) {
        rig.bind_inverse_.push_back(bind_inverse_of(bone));
    }
    return rig;
}

// Skeleton::_updateTransforms: xương gốc lấy nguyên biến đổi cục bộ, xương con ghép với cha đã
// tính.
std::vector<Transform> Rig::derive(std::span<const Transform> local) const {
    if (local.size() != initial_.size()) return {};
    std::vector<Transform> derived(local.size());
    for (const std::uint16_t handle : order_) {
        const std::int32_t above = parent_[handle];
        const bool root = above < 0;
        const Transform& own = local[handle];
        derived[handle] = root ? own : from_parent(derived[static_cast<std::size_t>(above)], own);
    }
    return derived;
}

// Skeleton::_getBoneMatrices: một ma trận offset mỗi xương theo handle.
std::vector<Affine> Rig::skin(std::span<const Transform> local) const {
    if (local.size() != initial_.size()) return {};
    const std::vector<Transform> derived = derive(local);
    std::vector<Affine> out;
    out.reserve(derived.size());
    for (std::size_t handle = 0; handle < derived.size(); ++handle) {
        out.push_back(offset_transform(derived[handle], bind_inverse_[handle]));
    }
    return out;
}

void Rig::skin(std::span<const Transform> local, std::vector<Affine>& out_skin,
    std::vector<Transform>& out_derived) const {
    if (local.size() != initial_.size()) {
        out_skin.clear();
        out_derived.clear();
        return;
    }
    out_derived.resize(local.size());
    for (const std::uint16_t handle : order_) {
        const std::int32_t above = parent_[handle];
        const bool root = above < 0;
        const Transform& own = local[handle];
        out_derived[handle] = root ? own : from_parent(out_derived[static_cast<std::size_t>(above)], own);
    }
    out_skin.resize(out_derived.size());
    for (std::size_t handle = 0; handle < out_derived.size(); ++handle) {
        out_skin[handle] = offset_transform(out_derived[handle], bind_inverse_[handle]);
    }
}

namespace {

using Handles = std::map<std::string, std::uint16_t, std::less<>>;

Handles handles_by_name(const SourceSkeleton& skeleton) {
    Handles handles;
    for (const Bone& bone : skeleton.bones) {
        handles.emplace(bone.name, bone.handle);
    }
    return handles;
}

// Handle của own tới tên và tới cha; xương gốc không có trong parents.
// Bộ dựng mặc định của struct chứa std::map bị tidy coi là noexcept dù STL MSVC cấp phát nút gác.
// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
struct Tree {
    std::map<std::uint16_t, std::string_view> names;
    std::map<std::uint16_t, std::uint16_t> parents;
};

Tree tree_of(const SourceSkeleton& skeleton) {
    Tree tree;
    for (const Bone& bone : skeleton.bones) {
        tree.names.emplace(bone.handle, bone.name);
    }
    for (const BoneParent& link : skeleton.parents) {
        tree.parents.emplace(link.child, link.parent);
    }
    return tree;
}

// Handle trong main của xương handle, nếu chính nó có tên trong main.
std::optional<std::uint16_t> named_in_main(std::uint16_t handle, const Tree& own, const Handles& main) {
    const auto name = own.names.find(handle);
    const auto found = name == own.names.end() ? main.end() : main.find(name->second);
    if (found == main.end()) return std::nullopt;
    return found->second;
}

// Cha của xương handle trong cây own, nếu có.
std::optional<std::uint16_t> parent_in_own(std::uint16_t handle, const Tree& own) {
    const auto parent = own.parents.find(handle);
    if (parent == own.parents.end()) return std::nullopt;
    return parent->second;
}

// Handle trong main của xương handle hay của tổ tiên gần nhất của nó có trong main. Đi tối đa
// bằng số xương, nên cây có vòng cũng dừng (Rig::create mới là nơi từ chối vòng).
std::optional<std::uint16_t> main_of(std::uint16_t handle, const Tree& own, const Handles& main) {
    std::optional<std::uint16_t> cursor = handle;
    std::optional<std::uint16_t> found;
    for (std::size_t step = 0; cursor && !found && step <= own.names.size(); ++step) {
        found = named_in_main(*cursor, own, main);
        cursor = found ? cursor : parent_in_own(*cursor, own);
    }
    return found;
}

// Ghi handle của main cho một xương của own vào bảng; xương không có tổ tiên chính là Orphan.
std::optional<RetargetError> map_bone(std::vector<std::uint16_t>& map, const Bone& bone, const Tree& own,
    const Handles& main) {
    const std::optional<std::uint16_t> target = main_of(bone.handle, own, main);
    if (!target) return RetargetError::kOrphan;
    const std::size_t wanted = bone.handle + std::size_t{1};
    map.resize(std::max(map.size(), wanted), kUnknownBone);
    map[bone.handle] = *target;
    return std::nullopt;
}

} // namespace

// own và main khác vai, đúng chữ ký của bản gốc.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): own, main khác vai (HP-07)
RetargetResult retarget(const SourceSkeleton& own, const SourceSkeleton& main) {
    const Handles handles = handles_by_name(main);
    const Tree tree = tree_of(own);
    std::vector<std::uint16_t> map(own.bones.size(), kUnknownBone);
    std::optional<RetargetError> failure;
    for (std::size_t index = 0; index < own.bones.size() && !failure; ++index) {
        failure = map_bone(map, own.bones[index], tree, handles);
    }
    if (failure) return std::unexpected(*failure);
    return map;
}

void retarget_palette(std::span<std::uint16_t> palette, std::span<const std::uint16_t> map) {
    for (std::uint16_t& handle : palette) {
        handle = handle < map.size() ? map[handle] : kUnknownBone;
    }
}

// Lệch có chủ đích: handle ngoài skeleton ra ma trận đơn vị thay vì đọc ngoài mảng như OGRE.
std::vector<Affine> palette_matrices(std::span<const Affine> skin, std::span<const std::uint16_t> palette) {
    std::vector<Affine> out;
    out.reserve(palette.size());
    for (const std::uint16_t handle : palette) {
        const bool known = handle < skin.size();
        out.push_back(known ? skin[handle] : kIdentityAffine);
    }
    return out;
}

void palette_matrices(std::span<const Affine> skin, std::span<const std::uint16_t> palette, std::vector<Affine>& out) {
    out.clear();
    out.reserve(palette.size());
    for (const std::uint16_t handle : palette) {
        const bool known = handle < skin.size();
        out.push_back(known ? skin[handle] : kIdentityAffine);
    }
}

} // namespace game::anim
