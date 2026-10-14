// Tia–tam giác là Möller–Trumbore, không loại mặt sau. Cây OPCODE chỉ tỉa hộp; điểm trúng
// ghép bằng trọng tâm, không bằng gốc + t * hướng. Con dương được xét trước con âm.
#include "collision/model.hpp"

#include "collision/mesh.hpp"
#include "collision/opcode_tree.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <limits>
#include <memory>
#include <utility>
#include <vector>

namespace game::collision {
namespace {

using detail::Mesh;
using detail::OpcodeTree;
using detail::Point3;
using detail::QuantizedNode;
using detail::TreeShape;

constexpr float kEpsilon = 1.0e-6F;
constexpr float kHeight = 10000.0F;

struct Best {
    float distance = std::numeric_limits<float>::max();
    Hit hit{};
    bool found = false;
};

[[nodiscard]] float dot3(Point3 left, Point3 right) noexcept {
    return (left.x * right.x) + (left.y * right.y) + (left.z * right.z);
}

[[nodiscard]] Point3 cross3(Point3 left, Point3 right) noexcept {
    Point3 out;
    out.x = (left.y * right.z) - (left.z * right.y);
    out.y = (left.z * right.x) - (left.x * right.z);
    out.z = (left.x * right.y) - (left.y * right.x);
    return out;
}

[[nodiscard]] Point3 sub3(Point3 left, Point3 right) noexcept {
    return Point3{.x = left.x - right.x, .y = left.y - right.y, .z = left.z - right.z};
}

[[nodiscard]] Point3 at3(std::span<const float, 3> value) noexcept {
    return Point3{.x = value[0], .y = value[1], .z = value[2]};
}

[[nodiscard]] bool in_mesh(const Mesh& mesh, std::uint32_t index) noexcept {
    return index < mesh.vertices.size();
}

void keep_hit(Best& best, Point3 v0, Point3 v1, Point3 v2, float u, float v) noexcept {
    const float rest = (1.0F - u) - v;
    Hit hit;
    hit.x = (u * v1.x) + (v * v2.x) + (rest * v0.x);
    hit.y = (u * v1.y) + (v * v2.y) + (rest * v0.y);
    hit.z = (u * v1.z) + (v * v2.z) + (rest * v0.z);
    best.hit = hit;
    best.found = true;
}

void test_triangle(Best& best, const Mesh& mesh, std::uint32_t index, Point3 origin, Point3 direction) noexcept {
    if (index >= mesh.triangle_count || index >= mesh.triangles.size()) return;
    const std::array<std::uint32_t, 3>& corners = mesh.triangles[index];
    if (!in_mesh(mesh, corners[0]) || !in_mesh(mesh, corners[1]) || !in_mesh(mesh, corners[2])) return;
    const Point3 v0 = mesh.vertices[corners[0]];
    const Point3 v1 = mesh.vertices[corners[1]];
    const Point3 v2 = mesh.vertices[corners[2]];
    const Point3 edge1 = sub3(v1, v0);
    const Point3 edge2 = sub3(v2, v0);
    const Point3 pvec = cross3(direction, edge2);
    const float det = dot3(edge1, pvec);
    if (det > -kEpsilon && det < kEpsilon) return;
    const float inverse = 1.0F / det;
    const Point3 tvec = sub3(origin, v0);
    const float u = dot3(tvec, pvec) * inverse;
    if (u < -kEpsilon || u > 1.0F + kEpsilon) return;
    const Point3 qvec = cross3(tvec, edge1);
    const float v = dot3(direction, qvec) * inverse;
    if (v < -kEpsilon || (u + v) > 1.0F + kEpsilon) return;
    const float distance = dot3(edge2, qvec) * inverse;
    if (distance < 0.0F || distance >= best.distance) return;
    best.distance = distance;
    keep_hit(best, v0, v1, v2, u, v);
}

struct Slab {
    float min_x = 0.0F;
    float min_y = 0.0F;
    float min_z = 0.0F;
    float max_x = 0.0F;
    float max_y = 0.0F;
    float max_z = 0.0F;
};

[[nodiscard]] Slab slab_of(const OpcodeTree& tree, const QuantizedNode& node) noexcept {
    Slab slab;
    const float center_x = static_cast<float>(node.center[0]) * tree.center_coeff.x;
    const float center_y = static_cast<float>(node.center[1]) * tree.center_coeff.y;
    const float center_z = static_cast<float>(node.center[2]) * tree.center_coeff.z;
    const float extent_x = static_cast<float>(node.extents[0]) * tree.extents_coeff.x;
    const float extent_y = static_cast<float>(node.extents[1]) * tree.extents_coeff.y;
    const float extent_z = static_cast<float>(node.extents[2]) * tree.extents_coeff.z;
    slab.min_x = center_x - extent_x;
    slab.max_x = center_x + extent_x;
    slab.min_y = center_y - extent_y;
    slab.max_y = center_y + extent_y;
    slab.min_z = center_z - extent_z;
    slab.max_z = center_z + extent_z;
    return slab;
}

struct Clip {
    float near_hit = 0.0F;
    float far_hit = 0.0F;
    bool missed = false;
};

void clip_axis(Clip& clip, float from, float toward, float low, float high) noexcept {
    if (toward > -kEpsilon && toward < kEpsilon) {
        clip.missed = from < low || from > high;
        return;
    }
    const float inverse = 1.0F / toward;
    float enter = (low - from) * inverse;
    float leave = (high - from) * inverse;
    if (enter > leave) std::swap(enter, leave);
    if (enter > clip.near_hit) clip.near_hit = enter;
    if (leave < clip.far_hit) clip.far_hit = leave;
    clip.missed = clip.near_hit > clip.far_hit;
}

[[nodiscard]] bool hits_slab(Point3 origin, Point3 direction, Slab slab, float limit) noexcept {
    Clip clip;
    clip.far_hit = limit;
    const std::array<float, 3> from{origin.x, origin.y, origin.z};
    const std::array<float, 3> toward{direction.x, direction.y, direction.z};
    const std::array<float, 3> low{slab.min_x, slab.min_y, slab.min_z};
    const std::array<float, 3> high{slab.max_x, slab.max_y, slab.max_z};
    for (int axis = 0; axis < 3; ++axis) {
        const auto slot = static_cast<std::size_t>(axis);
        clip_axis(clip, from[slot], toward[slot], low[slot], high[slot]);
        if (clip.missed) return false;
    }
    return true;
}

// Giữ nguyên mã con của cây: bit thấp là lá. Đẩy con âm trước con dương để lần rút sau lấy con dương.
void push_child(std::vector<std::uint32_t>& stack, std::uint32_t child) noexcept {
    if (stack.size() >= stack.capacity()) return;
    stack.push_back(child);
}

void visit_node(const OpcodeTree& tree, std::uint32_t index, Point3 origin, Point3 direction, float limit,
    std::vector<std::uint32_t>& stack) noexcept {
    if (index >= tree.nodes.size()) return;
    const QuantizedNode& node = tree.nodes[index];
    if (!hits_slab(origin, direction, slab_of(tree, node), limit)) return;
    push_child(stack, node.negative);
    push_child(stack, node.positive);
}

void open_child(Best& best, const Mesh& mesh, const OpcodeTree& tree, std::uint32_t child, Point3 origin,
    Point3 direction, std::vector<std::uint32_t>& stack) noexcept {
    if (detail::is_leaf(child)) {
        test_triangle(best, mesh, detail::child_index(child), origin, direction);
        return;
    }
    visit_node(tree, detail::child_index(child), origin, direction, best.distance, stack);
}

void walk_tree(Best& best, const Mesh& mesh, const OpcodeTree& tree, Point3 origin, Point3 direction,
    std::vector<std::uint32_t>& stack) noexcept {
    stack.clear();
    if (tree.nodes.empty()) return;
    stack.push_back(0);
    while (!stack.empty()) {
        const std::uint32_t child = stack.back();
        stack.pop_back();
        open_child(best, mesh, tree, child, origin, direction, stack);
    }
}

[[nodiscard]] Aabb bounds_of(const Mesh& mesh) noexcept {
    Aabb box;
    box.min_x = std::numeric_limits<float>::infinity();
    box.min_y = box.min_x;
    box.min_z = box.min_x;
    box.max_x = -box.min_x;
    box.max_y = box.max_x;
    box.max_z = box.max_x;
    const std::uint32_t count =
        mesh.vertex_count < mesh.vertices.size() ? mesh.vertex_count : static_cast<std::uint32_t>(mesh.vertices.size());
    for (std::uint32_t index = 0; index < count; ++index) {
        const Point3 point = mesh.vertices[index];
        if (point.x < box.min_x) box.min_x = point.x;
        if (point.y < box.min_y) box.min_y = point.y;
        if (point.z < box.min_z) box.min_z = point.z;
        if (point.x > box.max_x) box.max_x = point.x;
        if (point.y > box.max_y) box.max_y = point.y;
        if (point.z > box.max_z) box.max_z = point.z;
    }
    return box;
}

void cast_all(Best& best, const Mesh& mesh, const OpcodeTree& tree, std::vector<std::uint32_t>& stack, Point3 origin,
    Point3 direction) noexcept {
    if (tree.shape == TreeShape::kSingle) {
        test_triangle(best, mesh, 0, origin, direction);
        return;
    }
    if (tree.shape != TreeShape::kTree) return;
    walk_tree(best, mesh, tree, origin, direction, stack);
}

} // namespace

struct Model::Body {
    detail::Mesh mesh;
    detail::OpcodeTree tree;
    mutable std::vector<std::uint32_t> stack;
};

Model::Model(std::unique_ptr<Body> body) noexcept : body_(std::move(body)) {}

Model::Model(Model&&) noexcept = default;

Model& Model::operator=(Model&&) noexcept = default;

Model::~Model() = default;

std::optional<float> Model::height(float x, float z) const noexcept {
    const std::array<float, 3> origin{x, kHeight, z};
    const std::array<float, 3> direction{0.0F, -1.0F, 0.0F};
    const std::optional<Hit> hit = raycast(origin, direction);
    if (!hit) return std::nullopt;
    return hit->y;
}

std::optional<Hit> Model::raycast(std::span<const float, 3> origin,
    std::span<const float, 3> direction) const noexcept {
    if (body_ == nullptr) return std::nullopt;
    Best best;
    cast_all(best, body_->mesh, body_->tree, body_->stack, at3(origin), at3(direction));
    if (!best.found) return std::nullopt;
    return best.hit;
}

Aabb Model::bounds() const noexcept {
    if (body_ == nullptr) return bounds_of(Mesh{});
    return bounds_of(body_->mesh);
}

std::expected<Model, LoadError> load(std::span<const std::byte> data) {
    const detail::ParseResult view = detail::parse_building_file(data);
    if (!view) return std::unexpected(view.error());
    const std::expected<Mesh, detail::MeshError> mesh = detail::build_mesh(*view);
    if (!mesh) return std::unexpected(LoadError::kTooLarge);
    const std::expected<OpcodeTree, detail::TreeError> tree = detail::build_tree(*mesh);
    if (!tree) return std::unexpected(LoadError::kTooLarge);
    auto body = std::make_unique<Model::Body>();
    body->mesh = std::move(*mesh);
    body->tree = std::move(*tree);
    // Trần của hàng đợi duyệt: một cây đúng không bao giờ xin thêm trong lúc truy vấn noexcept.
    const std::size_t pending = static_cast<std::size_t>(body->mesh.triangle_count) + 2U;
    body->stack.reserve(pending);
    return Model(std::move(body));
}

} // namespace game::collision
