/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/fx/billboard.cpp
 *  PHÂN HỆ   : Place / Fx / Billboard
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dựng đỉnh quad billboard và dải ribbon của hạt đang sống, đỉnh ở thế giới;
 *    hệ không gian cục bộ đổi qua node của hệ.
 *  - grain_sphere cho cầu bao mọi đỉnh của hệ billboard kiểu điểm để FxView bỏ
 *    hệ ngoài khung nhìn trước khi dựng quad; kiểu khác luôn được vẽ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "fx/billboard.hpp"

#include "fx/field.hpp"
#include "fx/strip.hpp"
#include "fx/system.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <utility>
#include <variant>
#include <vector>

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

// Hướng của hệ chỉ tính cho kiểu billboard cần nó (đường nóng: mỗi hạt mỗi khung). direction là hướng của
// hạt trong không gian của hệ; kiểu theo hướng hạt mới đổi nó sang thế giới.
[[nodiscard]] Axes axes_of(const SystemDef& definition, const Field& field, Vec3 direction, CameraAxes camera) {
    const BillboardKind kind = definition.billboard;
    if (kind == BillboardKind::kOrientedCommon) {
        const Vec3 common = world_direction(field, definition.common_direction);
        return Axes{.x = unit_vec(ogre::cross_vec3(camera.forward, common)), .y = common};
    }
    if (kind == BillboardKind::kPerpendicularCommon) {
        const Vec3 common = world_direction(field, definition.common_direction);
        const Vec3 up = world_direction(field, definition.common_up);
        return Axes{.x = ogre::cross_vec3(up, common), .y = ogre::cross_vec3(common, ogre::cross_vec3(up, common))};
    }
    const bool is_self = kind == BillboardKind::kOrientedSelf || kind == BillboardKind::kPerpendicularSelf;
    if (!is_self) return Axes{.x = camera.right, .y = camera.up};
    const Vec3 velocity = world_direction(field, direction);
    const bool stretch = kind == BillboardKind::kOrientedSelf && definition.speed_factor > 0.0F;
    const Vec3 own = stretch ? ogre::scale_vec3(velocity, definition.speed_factor) : unit_vec(velocity);
    if (kind == BillboardKind::kOrientedSelf) return Axes{.x = unit_vec(ogre::cross_vec3(camera.forward, own)), .y = own};
    const Vec3 up = world_direction(field, definition.common_up);
    const Vec3 across = unit_vec(ogre::cross_vec3(up, own));
    return Axes{.x = across, .y = ogre::cross_vec3(own, across)};
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

// sequence là sequence_of(definition), tìm một lần cho cả hệ thay vì cho từng hạt.
[[nodiscard]] TexFrame frame_of(const SystemDef& definition, const SequenceFrame* sequence, const Grain& grain) {
    if (definition.renderer != RendererKind::kTexcoord) return {};
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

// Bốn góc theo thứ tự trái trên, phải trên, trái dưới, phải dưới như genVertOffsets.
using Offsets = std::array<Vec3, 4>;

// BillboardSet::genVertices kiểu BBR_VERTEX, kiểu mặc định của bản gốc (OgreMain 0x18004e680 để
// 0): bốn góc quay quanh trục (o3 − o0) × (o2 − o1) một góc bằng rotation của hạt.
[[nodiscard]] Offsets spin_offsets(const Offsets& offsets, float rotation) {
    const Vec3 across = ogre::sub_vec3(offsets[3], offsets[0]);
    const Vec3 down = ogre::sub_vec3(offsets[2], offsets[1]);
    const Vec3 normal = ogre::cross_vec3(across, down);
    const Vec3 axis = ogre::normalize_vec3(normal);
    const ogre::Quat turn = ogre::quat_from_angle_axis(rotation, axis);
    Offsets turned{};
    for (std::size_t index = 0; index < offsets.size(); ++index)
        turned.at(index) = ogre::quat_rotate(turn, offsets.at(index));
    return turned;
}

void push_grain(BillboardBatch& batch, const Field& field, const SequenceFrame* sequence,
    const Grain& grain, CameraAxes camera) {
    const SystemDef& definition = field.definition();
    const float width = grain.own ? grain.width : definition.width;
    const float height = grain.own ? grain.height : definition.height;
    const Vec3 center = world_point(field, grain.position);
    const Axes axes = axes_of(definition, field, grain.direction, camera);
    // Phần của bốn góc trên trục x (thấp, cao) và trục y (cao, thấp) theo billboard_origin.
    const Vec3 x_low = ogre::scale_vec3(axes.x, definition.origin.left * width);
    const Vec3 x_high = ogre::scale_vec3(axes.x, definition.origin.right * width);
    const Vec3 y_high = ogre::scale_vec3(axes.y, definition.origin.top * height);
    const Vec3 y_low = ogre::scale_vec3(axes.y, definition.origin.bottom * height);
    const Colour colour = grain.colour;
    const TexFrame frame = frame_of(definition, sequence, grain);
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
    const Vec3 left_top = ogre::add_vec3(x_low, y_high);
    const Vec3 right_top = ogre::add_vec3(x_high, y_high);
    const Vec3 left_bottom = ogre::add_vec3(x_low, y_low);
    const Vec3 right_bottom = ogre::add_vec3(x_high, y_low);
    Offsets offsets{left_top, right_top, left_bottom, right_bottom};
    const bool turns = !definition.rotate_texcoord && grain.rotation != 0.0F;
    if (turns) offsets = spin_offsets(offsets, grain.rotation);
    push_corner(batch, ogre::add_vec3(center, offsets[0]), top_left.u, top_left.v, colour);
    push_corner(batch, ogre::add_vec3(center, offsets[1]), top_right.u, top_right.v, colour);
    push_corner(batch, ogre::add_vec3(center, offsets[2]), low_left.u, low_left.v, colour);
    push_corner(batch, ogre::add_vec3(center, offsets[3]), low_right.u, low_right.v, colour);
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

void push_one(BillboardBatch& batch, const Field& field, const SequenceFrame* sequence, std::uint32_t index,
    CameraAxes camera) {
    if (field.definition().renderer == RendererKind::kRibbon) {
        push_ribbon(batch, field, index, camera);
        return;
    }
    if (field.definition().renderer == RendererKind::kMesh) return;
    push_grain(batch, field, sequence, field.grain(index), camera);
}

// Mỗi hạt bốn đỉnh; chuỗi có thể nhiều hơn, vector tự nới phần còn lại.
void fill_field(BillboardBatch& batch, const Field& field, CameraAxes camera) {
    const SequenceFrame* sequence = sequence_of(field.definition());
    batch.vertices.reserve(field.order().size() * 4U);
    for (const std::uint32_t index : field.order())
        push_one(batch, field, sequence, index, camera);
}

[[nodiscard]] bool shown_field(const Field* field) {
    if (field == nullptr) return false;
    if (field->order().empty()) return false;
    return !field->definition().material.empty();
}

// Màu của hệ nhân vào màu từng đỉnh. Trắng thì không đổi gì.
void apply_tint(BillboardBatch& batch, const Colour& tint) {
    const bool is_white = tint[0] == 1.0F && tint[1] == 1.0F && tint[2] == 1.0F && tint[3] == 1.0F;
    if (is_white) return;
    for (BillboardVertex& vertex : batch.vertices) {
        vertex.red *= tint[0];
        vertex.green *= tint[1];
        vertex.blue *= tint[2];
        vertex.alpha *= tint[3];
    }
}

void take_batch(std::vector<BillboardBatch>& batches, const Field* field, CameraAxes camera) {
    if (!shown_field(field)) return;
    BillboardBatch batch;
    batch.material = field->definition().material;
    fill_field(batch, *field, camera);
    if (batch.vertices.empty()) return;
    apply_tint(batch, field->tint());
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

// Phần cầu bao hạt: hộp Field::extent (đo một lần mỗi bước mô phỏng) đổi sang thế giới, cầu ngoại
// tiếp hộp, cộng tầm với lớn nhất của một quad. Cầu này chứa cầu dựng từ hộp thế giới của từng tâm
// hạt, nên vẫn bao mọi đỉnh.

// Quad theo trục camera (kPoint) mới có tầm với không đổi theo hướng nhìn; các kiểu còn lại luôn
// được vẽ.
[[nodiscard]] bool is_point_quad(const SystemDef& definition) noexcept {
    if (definition.renderer == RendererKind::kRibbon) return false;
    if (definition.renderer == RendererKind::kMesh) return false;
    return definition.billboard == BillboardKind::kPoint;
}

// Đỉnh cách tâm hạt không quá hypot(across * bề rộng, up * bề cao) vì hai trục camera trực chuẩn;
// bề rộng, bề cao lớn nhất của hộp chặn trên mọi hạt. Quad không nhân scale của node.
[[nodiscard]] float quad_reach(const Origin& origin, const Field::Extent& extent) noexcept {
    const float across = std::max(std::fabs(origin.left), std::fabs(origin.right));
    const float upward = std::max(std::fabs(origin.top), std::fabs(origin.bottom));
    return std::hypot(across * extent.widest, upward * extent.tallest);
}

// Hệ cục bộ: node kéo dài một đoạn tối đa |scale| lớn nhất lần, phép quay giữ độ dài.
[[nodiscard]] float stretch_of(const Field& field) noexcept {
    if (!field.definition().local_space) return 1.0F;
    const Vec3 scale = field.node().scale;
    const float flat = std::max(std::fabs(scale.x), std::fabs(scale.y));
    return std::max(flat, std::fabs(scale.z));
}

// Số không hữu hạn (hạt hỏng) thì không bao được gì: để hệ được vẽ như cũ.
[[nodiscard]] std::optional<GrainSphere> sphere_of(Vec3 middle, float radius) noexcept {
    const bool is_flat_finite = std::isfinite(middle.x) && std::isfinite(middle.y);
    const bool is_finite = is_flat_finite && std::isfinite(middle.z) && std::isfinite(radius);
    if (!is_finite) return std::nullopt;
    return GrainSphere{.centre = middle, .radius = radius};
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

std::optional<GrainSphere> grain_sphere(const Field& field) {
    if (!is_point_quad(field.definition())) return std::nullopt;
    const Field::Extent& extent = field.extent();
    if (extent.is_empty) return std::nullopt;
    const Vec3 diagonal = ogre::sub_vec3(extent.high, extent.low);
    const Vec3 sum = ogre::add_vec3(extent.low, extent.high);
    const Vec3 local_middle = ogre::scale_vec3(sum, 0.5F);
    const Vec3 middle = world_point(field, local_middle);
    const float spread = ogre::length_vec3(diagonal) * 0.5F * stretch_of(field);
    const float radius = spread + quad_reach(field.definition().origin, extent);
    return sphere_of(middle, radius);
}

std::vector<BillboardBatch> billboards_of(std::span<const Field* const> fields, CameraAxes camera) {
    std::vector<BillboardBatch> batches;
    batches.reserve(fields.size());
    for (const Field* field : fields)
        take_batch(batches, field, camera);
    return batches;
}

} // namespace game::fx
