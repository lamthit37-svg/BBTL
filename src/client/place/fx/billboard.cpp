#include "fx/billboard.hpp"

#include "fx/field.hpp"
#include "fx/system.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <cmath>

namespace game::fx {
namespace {

using ogre::Vec3;

[[nodiscard]] Vec3 unit_vec(Vec3 value) {
    const float length = ogre::length_vec3(value);
    if (length <= 1.0e-8F) return value;
    return ogre::scale_vec3(value, 1.0F / length);
}

struct Axes {
    Vec3 x{};
    Vec3 y{};
};

[[nodiscard]] Vec3 world_point(const Field& field, Vec3 point) {
    if (!field.definition().local_space) return point;
    const Vec3 scaled = ogre::mul_vec3(field.node().scale, point);
    return ogre::add_vec3(field.node().position, ogre::quat_rotate(field.node().orientation, scaled));
}

[[nodiscard]] Vec3 world_direction(const Field& field, Vec3 direction) {
    if (!field.definition().local_space) return direction;
    return ogre::quat_rotate(field.node().orientation, direction);
}

[[nodiscard]] Axes axes_of(const SystemDef& definition, const Field& field, Vec3 velocity, CameraAxes camera) {
    const Vec3 common = world_direction(field, definition.common_direction);
    const Vec3 up = world_direction(field, definition.common_up);
    const bool stretch = definition.billboard == BillboardKind::kOrientedSelf && definition.speed_factor > 0.0F;
    const Vec3 own = stretch ? ogre::scale_vec3(velocity, definition.speed_factor) : unit_vec(velocity);
    if (definition.billboard == BillboardKind::kOrientedCommon)
        return Axes{.x = unit_vec(ogre::cross_vec3(camera.forward, common)), .y = common};
    if (definition.billboard == BillboardKind::kOrientedSelf)
        return Axes{.x = unit_vec(ogre::cross_vec3(camera.forward, own)), .y = own};
    if (definition.billboard == BillboardKind::kPerpendicularCommon)
        return Axes{.x = ogre::cross_vec3(up, common), .y = ogre::cross_vec3(common, ogre::cross_vec3(up, common))};
    if (definition.billboard == BillboardKind::kPerpendicularSelf) {
        const Vec3 across = unit_vec(ogre::cross_vec3(up, own));
        return Axes{.x = across, .y = ogre::cross_vec3(own, across)};
    }
    return Axes{.x = camera.right, .y = camera.up};
}

struct Uv {
    float u = 0.0F;
    float v = 0.0F;
};

// Xoay UV quanh tâm khung. billboard_rotation_type texcoord của gốc xoay ảnh, không xoay quad.
[[nodiscard]] Uv spin_uv(Uv uv, float angle, Uv center) noexcept {
    const float du = uv.u - center.u;
    const float dv = uv.v - center.v;
    const float cosine = std::cos(angle);
    const float sine = std::sin(angle);
    Uv spun;
    spun.u = center.u + (du * cosine) - (dv * sine);
    spun.v = center.v + (du * sine) + (dv * cosine);
    return spun;
}

void push_corner(BillboardBatch& batch, Vec3 at, float u, float v, Colour colour) {
    BillboardVertex vertex;
    vertex.x = at.x;
    vertex.y = at.y;
    vertex.z = at.z;
    vertex.u = u;
    vertex.v = v;
    vertex.red = colour[0];
    vertex.green = colour[1];
    vertex.blue = colour[2];
    vertex.alpha = colour[3];
    batch.vertices.push_back(vertex);
}

struct TexFrame {
    float left = 0.0F;
    float top = 0.0F;
    float right = 1.0F;
    float bottom = 1.0F;
};

// Affector SequenceFrame của hệ, nếu có: nó quyết ô nào của ảnh hạt đang hiện thay cho stacks, slices và repeat_times
// của chính hệ.
[[nodiscard]] const SequenceFrame* sequence_of(const SystemDef& definition) noexcept {
    for (const Affector& affector : definition.affectors) {
        if (const auto* frames = std::get_if<SequenceFrame>(&affector)) return frames;
    }
    return nullptr;
}

// Vị trí trong dãy ô, 0..1: hết một vòng thì quay lại (loop), đi tới rồi lùi lại (pingpang), không thì dừng ở ô cuối.
[[nodiscard]] float sequence_phase(const SequenceFrame& frames, const Grain& grain) noexcept {
    float phase = grain.frame_start + (grain.life() * frames.repeat_times);
    if (frames.pingpang) {
        const float wave = std::fmod(phase, 2.0F);
        phase = wave > 1.0F ? 2.0F - wave : wave;
    } else if (frames.loop) {
        phase = std::fmod(phase, 1.0F);
    } else {
        phase = std::min(phase, 1.0F);
    }
    return std::max(phase, 0.0F);
}

[[nodiscard]] TexFrame frame_of(const SystemDef& definition, const Grain& grain) {
    if (definition.renderer != RendererKind::kTexcoord) return {};
    const SequenceFrame* sequence = sequence_of(definition);
    const int slice_count = std::max(1, sequence != nullptr ? sequence->slices : definition.slices);
    const int stack_count = std::max(1, sequence != nullptr ? sequence->stacks : definition.stacks);
    const int frames = slice_count * stack_count;
    const float wrapped = sequence != nullptr ? sequence_phase(*sequence, grain)
                                              : std::fmod(grain.life() * definition.repeat_times, 1.0F);
    int index = static_cast<int>(wrapped * static_cast<float>(frames));
    if (index == frames) index = frames - 1;
    if (index < 0) index = 0;
    const int column = index % slice_count;
    const int row = index / slice_count;
    const float slice = static_cast<float>(slice_count);
    const float stack = static_cast<float>(stack_count);
    TexFrame frame;
    frame.left = static_cast<float>(column) / slice;
    frame.top = static_cast<float>(row) / stack;
    frame.right = static_cast<float>(column + 1) / slice;
    frame.bottom = static_cast<float>(row + 1) / stack;
    return frame;
}

void push_grain(BillboardBatch& batch, const Field& field, const Grain& grain, CameraAxes camera) {
    const SystemDef& definition = field.definition();
    const float width = grain.own ? grain.width : definition.width;
    const float height = grain.own ? grain.height : definition.height;
    const Vec3 center = world_point(field, grain.position);
    const Axes axes = axes_of(definition, field, world_direction(field, grain.direction), camera);
    const Vec3 left = ogre::scale_vec3(axes.x, definition.origin.left * width);
    const Vec3 right = ogre::scale_vec3(axes.x, definition.origin.right * width);
    const Vec3 top = ogre::scale_vec3(axes.y, definition.origin.top * height);
    const Vec3 bottom = ogre::scale_vec3(axes.y, definition.origin.bottom * height);
    const Colour colour = grain.colour;
    const TexFrame frame = frame_of(definition, grain);
    Uv top_left{.u = frame.left, .v = frame.top};
    Uv top_right{.u = frame.right, .v = frame.top};
    Uv low_left{.u = frame.left, .v = frame.bottom};
    Uv low_right{.u = frame.right, .v = frame.bottom};
    const bool spins = definition.rotate_texcoord && grain.rotation != 0.0F;
    if (spins) {
        const Uv middle{.u = (frame.left + frame.right) * 0.5F, .v = (frame.top + frame.bottom) * 0.5F};
        top_left = spin_uv(top_left, grain.rotation, middle);
        top_right = spin_uv(top_right, grain.rotation, middle);
        low_left = spin_uv(low_left, grain.rotation, middle);
        low_right = spin_uv(low_right, grain.rotation, middle);
    }
    push_corner(batch, ogre::add_vec3(center, ogre::add_vec3(left, top)), top_left.u, top_left.v, colour);
    push_corner(batch, ogre::add_vec3(center, ogre::add_vec3(right, top)), top_right.u, top_right.v, colour);
    push_corner(batch, ogre::add_vec3(center, ogre::add_vec3(left, bottom)), low_left.u, low_left.v, colour);
    push_corner(batch, ogre::add_vec3(center, ogre::add_vec3(right, bottom)), low_right.u, low_right.v, colour);
    if (grain.rotation == 0.0F || definition.rotate_texcoord) return;
    static_cast<void>(grain.rotation);
}

// Chuỗi luôn ở không gian node. Mắt đưa về không gian đó rồi nhân nửa bề rộng, như BillboardChain.
[[nodiscard]] Vec3 chain_eye(const Field& field, Vec3 eye) {
    const Vec3 shifted = ogre::sub_vec3(eye, field.node().position);
    const Vec3 turned = ogre::quat_rotate(ogre::quat_inverse(field.node().orientation), shifted);
    return ogre::div_vec3(turned, field.node().scale);
}

[[nodiscard]] Vec3 link_tangent(std::span<const Field::ChainPoint> points, std::size_t index) {
    if (index == 0) return ogre::sub_vec3(points[1].position, points[0].position);
    const std::size_t last = points.size() - 1;
    if (index == last) return ogre::sub_vec3(points[last].position, points[last - 1].position);
    return ogre::sub_vec3(points[index + 1].position, points[index - 1].position);
}

[[nodiscard]] Vec3 link_side(Vec3 tangent, Vec3 eye, Vec3 position, float width) {
    const Vec3 toward = ogre::sub_vec3(eye, position);
    const Vec3 raw = ogre::cross_vec3(tangent, toward);
    const float length = ogre::length_vec3(raw);
    if (!(length > 1.0e-8F)) return {};
    return ogre::scale_vec3(raw, (width * 0.5F) / length);
}

void push_ribbon_segment(BillboardBatch& batch, const Field& field, std::span<const Field::ChainPoint> points,
    std::size_t index, Vec3 eye) {
    const Field::ChainPoint& head = points[index - 1];
    const Field::ChainPoint& tail = points[index];
    const Vec3 head_tangent = link_tangent(points, index - 1);
    const Vec3 tail_tangent = link_tangent(points, index);
    const Vec3 head_side = link_side(head_tangent, eye, head.position, head.width);
    const Vec3 tail_side = link_side(tail_tangent, eye, tail.position, tail.width);
    const Vec3 head_left = world_point(field, ogre::sub_vec3(head.position, head_side));
    const Vec3 head_right = world_point(field, ogre::add_vec3(head.position, head_side));
    const Vec3 tail_left = world_point(field, ogre::sub_vec3(tail.position, tail_side));
    const Vec3 tail_right = world_point(field, ogre::add_vec3(tail.position, tail_side));
    push_corner(batch, head_left, head.texcoord, 0.0F, head.colour);
    push_corner(batch, head_right, head.texcoord, 1.0F, head.colour);
    push_corner(batch, tail_left, tail.texcoord, 0.0F, tail.colour);
    push_corner(batch, tail_right, tail.texcoord, 1.0F, tail.colour);
}

void push_ribbon_span(BillboardBatch& batch, const Field& field, std::span<const Field::ChainPoint> points, Vec3 eye) {
    for (std::size_t index = 1; index < points.size(); ++index)
        push_ribbon_segment(batch, field, points, index, eye);
}

void push_ribbon(BillboardBatch& batch, const Field& field, std::uint32_t index, CameraAxes camera) {
    const std::span<const Field::ChainPoint> points = field.chain(index);
    if (points.size() < 2) return;
    const Vec3 eye = chain_eye(field, camera.eye);
    push_ribbon_span(batch, field, points, eye);
}

void push_one(BillboardBatch& batch, const Field& field, std::uint32_t index, CameraAxes camera) {
    if (field.definition().renderer == RendererKind::kRibbon) {
        push_ribbon(batch, field, index, camera);
        return;
    }
    if (field.definition().renderer == RendererKind::kMesh) return;
    push_grain(batch, field, field.grain(index), camera);
}

void fill_field(BillboardBatch& batch, const Field& field, CameraAxes camera) {
    for (const std::uint32_t index : field.order())
        push_one(batch, field, index, camera);
}

[[nodiscard]] bool shown_field(const Field* field) {
    if (field == nullptr) return false;
    if (field->order().empty()) return false;
    return !field->definition().material.empty();
}

void take_batch(std::vector<BillboardBatch>& batches, const Field* field, CameraAxes camera) {
    if (!shown_field(field)) return;
    BillboardBatch batch;
    batch.material = field->definition().material;
    fill_field(batch, *field, camera);
    if (batch.vertices.empty()) return;
    batches.push_back(std::move(batch));
}

[[nodiscard]] Vec3 chain_tangent(std::span<const ChainSample> points, std::size_t index) {
    if (index == 0) return ogre::sub_vec3(points[1].position, points[0].position);
    const std::size_t last = points.size() - 1;
    if (index == last) return ogre::sub_vec3(points[last].position, points[last - 1].position);
    return ogre::sub_vec3(points[index + 1].position, points[index - 1].position);
}

[[nodiscard]] Vec3 chain_offset(Vec3 tangent, Vec3 eye, Vec3 place, float width, bool full_width) {
    const Vec3 toward = ogre::sub_vec3(eye, place);
    const Vec3 raw = ogre::cross_vec3(tangent, toward);
    const float length = ogre::length_vec3(raw);
    if (!(length > 1.0e-8F)) return {};
    const float span = full_width ? width : width * 0.5F;
    return ogre::scale_vec3(raw, span / length);
}

void push_chain_link(BillboardBatch& batch, std::span<const ChainSample> points, std::size_t index, Vec3 eye,
    bool full_width) {
    const ChainSample& head = points[index - 1];
    const ChainSample& tail = points[index];
    const Vec3 head_tangent = chain_tangent(points, index - 1);
    const Vec3 tail_tangent = chain_tangent(points, index);
    const Vec3 head_side = chain_offset(head_tangent, eye, head.position, head.width, full_width);
    const Vec3 tail_side = chain_offset(tail_tangent, eye, tail.position, tail.width, full_width);
    push_corner(batch, ogre::sub_vec3(head.position, head_side), head.along, 0.0F, head.colour);
    push_corner(batch, ogre::add_vec3(head.position, head_side), head.along, 1.0F, head.colour);
    push_corner(batch, ogre::sub_vec3(tail.position, tail_side), tail.along, 0.0F, tail.colour);
    push_corner(batch, ogre::add_vec3(tail.position, tail_side), tail.along, 1.0F, tail.colour);
}

void append_chain_span(BillboardBatch& batch, std::span<const ChainSample> points, Vec3 eye, bool full_width) {
    for (std::size_t index = 1; index < points.size(); ++index)
        push_chain_link(batch, points, index, eye, full_width);
}

[[nodiscard]] Vec3 deck_corner(const Node& node, float x, float z) {
    const Vec3 local{.x = x, .y = 0.0F, .z = z};
    const Vec3 scaled = ogre::mul_vec3(node.scale, local);
    const Vec3 turned = ogre::quat_rotate(node.orientation, scaled);
    return ogre::add_vec3(node.position, turned);
}

} // namespace

void append_chain(BillboardBatch& batch, std::span<const ChainSample> points, CameraAxes camera, bool full_width) {
    if (points.size() < 2) return;
    append_chain_span(batch, points, camera.eye, full_width);
}

void append_deck(BillboardBatch& batch, const Node& node, float size, Colour colour) {
    const float half = size * 0.5F;
    push_corner(batch, deck_corner(node, -half, -half), 0.0F, 0.0F, colour);
    push_corner(batch, deck_corner(node, half, -half), 1.0F, 0.0F, colour);
    push_corner(batch, deck_corner(node, -half, half), 0.0F, 1.0F, colour);
    push_corner(batch, deck_corner(node, half, half), 1.0F, 1.0F, colour);
}

std::vector<BillboardBatch> billboards_of(std::span<const Field* const> fields, CameraAxes camera) {
    std::vector<BillboardBatch> batches;
    for (const Field* field : fields)
        take_batch(batches, field, camera);
    return batches;
}

} // namespace game::fx
