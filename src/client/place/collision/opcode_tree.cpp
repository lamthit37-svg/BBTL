// Cây OPCODE 1.3 của Model::Build (PathLib.dll 0x180037330), vai C, B3. Từng bước theo so-do/b-b1-opcode-cay.md:
// AABBTree::Build 0x18003bfb0 (mục 4), ComputeGlobalBox 0x18003e500 (4.1), Subdivide 0x18003c220 (4.2), Split
// 0x18003c160 và GetSplittingValue 0x18003e810/0x18003ea30 (4.3), _BuildNoLeafTree 0x18003e250 (5),
// AABBQuantizedNoLeafTree::Build 0x18003ce50 (6) với vòng sửa theo so-do/b-fenghuang-bo.md mục 5.
// Mỗi phép f32 một biểu thức con, đúng nhóm như mã máy; không đệ quy (ngăn xếp tường minh) để tệp hỏng không làm
// tràn ngăn xếp; thứ tự kết quả không đổi vì mỗi nút chỉ đụng đoạn chỉ số của nó.
#include "collision/opcode_tree.hpp"

#include "core/check.hpp"

#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <numeric>
#include <utility>
#include <vector>

namespace game::collision::detail {
namespace {

constexpr float kThird = std::bit_cast<float>(0x3EAAAAABU); // 0x18003ea70..0x18003ea82: nhân, không chia 3
constexpr float kHalf = 0.5F;
constexpr float kQuantMax = 32767.0F; // 0x46fffe00; (1 << 15) − 1 của nửa cạnh qua cvtdq2ps cũng ra số này
constexpr float kFloatMax = std::numeric_limits<float>::max();
constexpr std::uint16_t kWrapped = 0xFFFFU;

using Axes = std::array<float, 3>;

struct Box {
    Axes center{};
    Axes extents{};
};

// Nút AABBTree trong pool. positive: chỉ số con dương trong pool (con âm là positive + 1), 0 = lá.
struct BuildNode {
    Box box;
    std::uint32_t first = 0;
    std::uint32_t count = 0;
    std::uint32_t positive = 0;
};

[[nodiscard]] float component(Point3 point, std::size_t axis) noexcept {
    if (axis == 0) return point.x;
    if (axis == 1) return point.y;
    return point.z;
}

[[nodiscard]] bool is_zero(float value) noexcept {
    return std::fpclassify(value) == FP_ZERO;
}

class TreeBuilder {
public:
    explicit TreeBuilder(const Mesh& mesh) noexcept : mesh_(mesh) {}

    // AABBTree::Build: hoán vị đồng nhất, pool 2n − 1 nút, gốc giữ cả hoán vị.
    [[nodiscard]] bool build(std::uint32_t count) {
        perm_.resize(count);
        std::iota(perm_.begin(), perm_.end(), 0U);
        pool_.reserve((std::size_t{count} * 2U) - 1U);
        pool_.push_back(BuildNode{.box = {}, .first = 0, .count = count, .positive = 0});
        std::vector<std::uint32_t> pending{0};
        std::uint64_t work = 0;
        while (!pending.empty()) {
            const std::uint32_t id = pending.back();
            pending.pop_back();
            global_box(id);
            const std::uint32_t total = pool_[id].count;
            if (total == 1) continue;
            work += total;
            if (work > kMaxSplitWork) return false;
            const std::uint32_t positive_count = subdivide(id);
            const std::uint32_t first = pool_[id].first;
            const auto child = static_cast<std::uint32_t>(pool_.size());
            pool_.push_back(BuildNode{.box = {}, .first = first, .count = positive_count, .positive = 0});
            pool_.push_back(BuildNode{
                .box = {}, .first = first + positive_count, .count = total - positive_count, .positive = 0});
            pool_[id].positive = child;
            pending.push_back(child + 1);
            pending.push_back(child);
        }
        return true;
    }

    [[nodiscard]] const std::vector<BuildNode>& pool() const noexcept { return pool_; }
    [[nodiscard]] std::uint32_t leaf_triangle(const BuildNode& node) const noexcept { return perm_[node.first]; }

private:
    [[nodiscard]] float coordinate(std::uint32_t triangle, std::size_t corner, std::size_t axis) const noexcept {
        return component(mesh_.vertices[mesh_.triangles[triangle][corner]], axis);
    }

    // GetSplittingValue(index, axis) 0x18003ea30: ((V1 + V0) + V2) * 0.333333343f.
    [[nodiscard]] float centroid(std::uint32_t triangle, std::size_t axis) const noexcept {
        const float pair = coordinate(triangle, 1, axis) + coordinate(triangle, 0, axis);
        const float sum = pair + coordinate(triangle, 2, axis);
        return sum * kThird;
    }

    // ComputeGlobalBox 0x18003e500: min nhận khi !(v > mn), max khi !(mx > v) (bằng nhau lấy giá trị mới).
    void global_box(std::uint32_t id) noexcept {
        BuildNode& node = pool_[id];
        Axes low{kFloatMax, kFloatMax, kFloatMax};
        Axes high{-kFloatMax, -kFloatMax, -kFloatMax};
        for (std::uint32_t at = node.first; at < node.first + node.count; ++at) {
            const std::uint32_t triangle = perm_[at];
            for (std::size_t corner = 0; corner < 3; ++corner) {
                for (std::size_t axis = 0; axis < 3; ++axis) {
                    const float value = coordinate(triangle, corner, axis);
                    if (!(value > low[axis])) low[axis] = value;
                }
            }
            for (std::size_t corner = 0; corner < 3; ++corner) {
                for (std::size_t axis = 0; axis < 3; ++axis) {
                    const float value = coordinate(triangle, corner, axis);
                    if (!(high[axis] > value)) high[axis] = value;
                }
            }
        }
        for (std::size_t axis = 0; axis < 3; ++axis) {
            const float sum = low[axis] + high[axis];
            node.box.center[axis] = sum * kHalf;
            const float span = high[axis] - low[axis];
            node.box.extents[axis] = span * kHalf;
        }
    }

    // Subdivide 0x18003c220 (SPLATTER_POINTS) + Split 0x18003c160 (GEOM_CENTER); trả số phần tử con dương.
    [[nodiscard]] std::uint32_t subdivide(std::uint32_t id) noexcept {
        const std::uint32_t first = pool_[id].first;
        const std::uint32_t count = pool_[id].count;
        Axes sum{0.0F, 0.0F, 0.0F};
        for (std::uint32_t at = first; at < first + count; ++at) {
            for (std::size_t axis = 0; axis < 3; ++axis)
                sum[axis] += centroid(perm_[at], axis);
        }
        const float inverse = 1.0F / static_cast<float>(std::uint64_t{count}); // cvtsi2ss 64 bit, divss
        Axes mean{};
        for (std::size_t axis = 0; axis < 3; ++axis)
            mean[axis] = sum[axis] * inverse;
        Axes variance{0.0F, 0.0F, 0.0F};
        for (std::uint32_t at = first; at < first + count; ++at) {
            for (std::size_t axis = 0; axis < 3; ++axis) {
                const float delta = centroid(perm_[at], axis) - mean[axis];
                const float square = delta * delta;
                variance[axis] += square;
            }
        }
        const float inverse_less = 1.0F / static_cast<float>(std::uint64_t{count} - 1U);
        for (float& value : variance)
            value *= inverse_less;
        std::size_t axis = 0;
        if (variance[1] > variance[0]) axis = 1;
        if (variance[2] > variance[axis]) axis = 2;
        // GetSplittingValue(prims, n, box, axis) 0x18003e810: trung bình đỉnh, một thanh ghi tích luỹ, chia thật.
        float vertex_sum = 0.0F;
        for (std::uint32_t at = first; at < first + count; ++at) {
            for (std::size_t corner = 0; corner < 3; ++corner)
                vertex_sum += coordinate(perm_[at], corner, axis);
        }
        const float split = vertex_sum / static_cast<float>(std::uint64_t{count} * 3U);
        // Phân hoạch hoán đổi tại chỗ, không ổn định: tâm > giá trị chia (so chặt, NaN sang âm) dồn lên đầu.
        std::uint32_t positive = 0;
        for (std::uint32_t index = 0; index < count; ++index) {
            if (centroid(perm_[first + index], axis) > split) {
                std::swap(perm_[first + index], perm_[first + positive]);
                ++positive;
            }
        }
        if (positive == 0 || positive == count) positive = count >> 1U; // chia hỏng, mLimit == 1
        return positive;
    }

    const Mesh& mesh_;
    std::vector<std::uint32_t> perm_;
    std::vector<BuildNode> pool_;
};

struct Pending {
    std::uint32_t pool_id = 0;
    std::uint32_t parent = 0;
    bool positive_side = false;
    bool has_parent = false;
};

// _BuildNoLeafTree 0x18003e250: tiền thứ tự, con dương trước; trả hộp f32 từng nút và liên kết.
void link_nodes(const TreeBuilder& builder, std::vector<QuantizedNode>& nodes, std::vector<Box>& boxes) {
    const std::vector<BuildNode>& pool = builder.pool();
    std::vector<Pending> pending{Pending{}};
    std::uint32_t next = 0;
    while (!pending.empty()) {
        const Pending item = pending.back();
        pending.pop_back();
        const std::uint32_t id = next++;
        if (item.has_parent) {
            std::uint32_t& slot = item.positive_side ? nodes[item.parent].positive : nodes[item.parent].negative;
            slot = id << 1U;
        }
        const BuildNode& node = pool[item.pool_id];
        boxes[id] = node.box;
        const BuildNode& positive = pool[node.positive];
        const BuildNode& negative = pool[node.positive + 1];
        if (negative.count == 1) {
            nodes[id].negative = (builder.leaf_triangle(negative) << 1U) | 1U;
        } else {
            pending.push_back(Pending{
                .pool_id = node.positive + 1, .parent = id, .positive_side = false, .has_parent = true});
        }
        if (positive.count == 1) {
            nodes[id].positive = (builder.leaf_triangle(positive) << 1U) | 1U;
        } else {
            pending.push_back(Pending{
                .pool_id = node.positive, .parent = id, .positive_side = true, .has_parent = true});
        }
    }
}

[[nodiscard]] float axis_of(Point3 point, std::size_t axis) noexcept {
    return component(point, axis);
}

void set_axis(Point3& point, std::size_t axis, float value) noexcept {
    if (axis == 0) {
        point.x = value;
    } else if (axis == 1) {
        point.y = value;
    } else {
        point.z = value;
    }
}

// AABBQuantizedNoLeafTree::Build 0x18003ce50 sau _BuildNoLeafTree: cực đại, hệ số, lượng tử, vòng sửa.
void quantize(OpcodeTree& tree, const std::vector<Box>& boxes) noexcept {
    Axes center_max{-kFloatMax, -kFloatMax, -kFloatMax};
    Axes extent_max{-kFloatMax, -kFloatMax, -kFloatMax};
    for (const Box& box : boxes) {
        for (std::size_t axis = 0; axis < 3; ++axis) {
            const float center = std::fabs(box.center[axis]);
            if (center > center_max[axis]) center_max[axis] = center;
            const float extent = std::fabs(box.extents[axis]);
            if (extent > extent_max[axis]) extent_max[axis] = extent;
        }
    }
    Axes center_quant{};
    Axes extent_quant{};
    for (std::size_t axis = 0; axis < 3; ++axis) {
        // ucomiss: NaN đi nhánh chia như "khác 0".
        center_quant[axis] = !is_zero(center_max[axis]) ? kQuantMax / center_max[axis] : 0.0F;
        extent_quant[axis] = !is_zero(extent_max[axis]) ? kQuantMax / extent_max[axis] : 0.0F;
        set_axis(tree.center_coeff, axis, !is_zero(center_quant[axis]) ? 1.0F / center_quant[axis] : 0.0F);
        set_axis(tree.extents_coeff, axis, !is_zero(extent_quant[axis]) ? 1.0F / extent_quant[axis] : 0.0F);
    }
    for (std::size_t index = 0; index < boxes.size(); ++index) {
        QuantizedNode& node = tree.nodes[index];
        const Box& box = boxes[index];
        for (std::size_t axis = 0; axis < 3; ++axis) {
            const float scaled_center = center_quant[axis] * box.center[axis];
            const auto center_bits = static_cast<std::uint32_t>(truncate_to_int32(scaled_center));
            node.center[axis] = std::bit_cast<std::int16_t>(static_cast<std::uint16_t>(center_bits & 0xFFFFU));
            const float scaled_extent = extent_quant[axis] * box.extents[axis];
            const auto extent_bits = static_cast<std::uint64_t>(truncate_to_int64(scaled_extent));
            const auto quantized = static_cast<std::uint16_t>(extent_bits & 0xFFFFU);
            const float dequantized_center = static_cast<float>(node.center[axis]) * axis_of(tree.center_coeff, axis);
            node.extents[axis] = fix_extent(quantized, box.center[axis], box.extents[axis], dequantized_center,
                axis_of(tree.extents_coeff, axis));
        }
    }
}

} // namespace

std::int32_t truncate_to_int32(float value) noexcept {
    constexpr float kLimit = 2147483648.0F; // 2^31
    if (!(value >= -kLimit && value < kLimit)) return std::numeric_limits<std::int32_t>::min();
    return static_cast<std::int32_t>(value);
}

std::int64_t truncate_to_int64(float value) noexcept {
    constexpr float kLimit = 9223372036854775808.0F; // 2^63
    if (!(value >= -kLimit && value < kLimit)) return std::numeric_limits<std::int64_t>::min();
    return static_cast<std::int64_t>(value);
}

std::uint16_t fix_extent_reference(std::uint16_t quantized, float center, float extent, float dequantized_center,
    float extents_coeff) noexcept {
    const float top = extent + center; // 0x180037770
    const float bottom = center - extent; // 0x180037730
    std::uint16_t value = quantized;
    for (;;) {
        const float dequantized = static_cast<float>(value) * extents_coeff;
        const float upper = dequantized + dequantized_center;
        const float lower = dequantized_center - dequantized;
        const bool grow = top > upper || lower > bottom; // comiss + ja
        if (grow) value = static_cast<std::uint16_t>(value + 1U); // inc ax: gói 16 bit
        if (value == 0) return kWrapped; // 0x18003d3ad: kiểm sau MỌI vòng
        if (!grow) return value;
    }
}

namespace {

[[nodiscard]] bool grows(std::uint32_t value, float top, float bottom, float dequantized_center, float coeff) noexcept {
    const float dequantized = static_cast<float>(value) * coeff;
    const float upper = dequantized + dequantized_center;
    const float lower = dequantized_center - dequantized;
    return top > upper || lower > bottom;
}

} // namespace

std::uint16_t fix_extent(std::uint16_t quantized, float center, float extent, float dequantized_center,
    float extents_coeff) noexcept {
    if (!(extents_coeff >= 0.0F)) {
        return fix_extent_reference(quantized, center, extent, dequantized_center, extents_coeff);
    }
    const float top = extent + center;
    const float bottom = center - extent;
    if (!grows(quantized, top, bottom, dequantized_center, extents_coeff)) {
        return quantized == 0 ? kWrapped : quantized;
    }
    // grows đơn điệu (đúng rồi sai) trên q tăng dần khi hệ số >= 0: tìm q nhỏ nhất trong (quantized, 0xFFFF] không
    // tăng; không có thì vòng gốc gói về 0 rồi ghi 0xFFFF, có ở 0xFFFF cũng ra 0xFFFF.
    std::uint32_t low = std::uint32_t{quantized} + 1U; // q đầu chưa biết
    std::uint32_t high = std::uint32_t{kWrapped} + 1U; // 0x10000 = "không có"
    while (low < high) {
        const std::uint32_t middle = low + ((high - low) >> 1U);
        if (grows(middle, top, bottom, dequantized_center, extents_coeff)) {
            low = middle + 1U;
        } else {
            high = middle;
        }
    }
    return low > kWrapped ? kWrapped : static_cast<std::uint16_t>(low);
}

std::expected<OpcodeTree, TreeError> build_tree(const Mesh& mesh) {
    OpcodeTree tree;
    const std::uint32_t count = mesh.triangle_count;
    // MeshInterface::IsValid 0x180036fd0: NbTris, NbVerts (và hai con trỏ) khác 0.
    core::check(count <= mesh.triangles.size(), "build_tree: NbTris vượt mảng tam giác");
    if (count == 0 || mesh.vertex_count == 0 || mesh.vertices.empty()) return tree;
    if (count == 1) {
        tree.shape = TreeShape::kSingle;
        return tree;
    }
    TreeBuilder builder(mesh);
    if (!builder.build(count)) return std::unexpected(TreeError::kTooMuchWork);
    tree.shape = TreeShape::kTree;
    tree.nodes.resize(count - 1U);
    std::vector<Box> boxes(count - 1U);
    link_nodes(builder, tree.nodes, boxes);
    quantize(tree, boxes);
    return tree;
}

} // namespace game::collision::detail
