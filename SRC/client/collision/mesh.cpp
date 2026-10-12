// Lưới sau nạp của BuildingCollision (vai C, B3): mã 1 theo ô 1 lớp get 0x180004580, mã 2 theo 0x180004a00 của
// PathLib.dll; luật và địa chỉ ở so-do/b-fenghuang-bo.md (B), đã trùng byte bộ nhớ DLL trên 26 cảnh.
#include "collision/mesh.hpp"

#include "collision/transform.hpp"
#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <utility>
#include <vector>

namespace game::collision::detail {
namespace {

using Key = std::array<std::int32_t, 3>;
using Corners = std::array<std::uint32_t, 3>;

constexpr float kKeyScale = 10000.0F; // hằng 10000 ở 0x180043c18 (mulss)
constexpr std::uint32_t kCountMask = 0xFFFFU; // movzx word: NbTris, NbVerts mod 65536

[[nodiscard]] Key vertex_key(Point3 point) noexcept {
    return Key{vertex_key_component(point.x), vertex_key_component(point.y), vertex_key_component(point.z)};
}

// Map đỉnh 0x180002b10: khoá đã có thì trả chỉ số cũ; chưa có thì đẩy f32 GỐC, chỉ số = cỡ vector − 1.
class VertexMap {
public:
    explicit VertexMap(std::vector<Point3>& vertices) noexcept : vertices_(vertices) {}

    [[nodiscard]] std::uint32_t id(Point3 point) {
        const auto next = static_cast<std::uint32_t>(vertices_.size());
        const auto [where, added] = ids_.try_emplace(vertex_key(point), next);
        if (added) vertices_.push_back(point);
        return where->second;
    }

private:
    std::vector<Point3>& vertices_;
    std::map<Key, std::uint32_t> ids_; // so từ điển có dấu trên 3 i32 như 0x180002c20..0x180002c39
};

[[nodiscard]] std::expected<Mesh, MeshError> build_cells(const BuildingFileView& view) {
    if (view.triangle_count > kMaxCellRecords) return std::unexpected(MeshError::kTooLarge);
    Mesh mesh;
    VertexMap map(mesh.vertices);
    std::vector<Corners> triples;
    triples.reserve(view.triangle_count);
    std::size_t offset = 0;
    for (std::uint32_t cell_index = 0; cell_index < view.cell_count; ++cell_index) {
        const CellView cell = view.cell_at(offset);
        for (std::uint32_t index = 0; index < cell.triangle_count; ++index) {
            const Triangle triangle = cell.triangle(index);
            // Thứ tự gọi map: đỉnh 2 (0x1800046d5), đỉnh 1 (0x1800046e9), đỉnh 0 (0x1800046fd).
            const std::uint32_t third = map.id(triangle.corners[2]);
            const std::uint32_t second = map.id(triangle.corners[1]);
            const std::uint32_t first = map.id(triangle.corners[0]);
            triples.push_back(Corners{first, second, third});
        }
        offset = cell.next;
    }
    // std::set (0x180001d30) rồi chép theo thứ tự duyệt giữa = sắp tăng từ điển, bỏ trùng. Chỉ số < 2^31 nên so
    // không dấu trùng so có dấu của DLL.
    std::ranges::sort(triples);
    const auto duplicates = std::ranges::unique(triples);
    triples.erase(duplicates.begin(), duplicates.end());
    mesh.triangles = std::move(triples);
    mesh.triangle_count = static_cast<std::uint32_t>(mesh.triangles.size()) & kCountMask;
    mesh.vertex_count = static_cast<std::uint32_t>(mesh.vertices.size()) & kCountMask;
    return mesh;
}

[[nodiscard]] std::expected<Mesh, MeshError> build_blocks(const BuildingFileView& view) {
    std::vector<BlockView> blocks;
    blocks.reserve(view.block_count);
    std::size_t offset = 0;
    for (std::uint32_t index = 0; index < view.block_count; ++index) {
        blocks.push_back(view.block_at(offset));
        offset = blocks.back().next;
    }
    // Đếm trước để từ chối tệp quá lớn trước khi cấp phát (khác gốc, xem kMaxMeshVertices).
    std::uint64_t vertex_total = 0;
    std::uint64_t face_total = 0;
    for (std::uint32_t index = 0; index < view.placement_count; ++index) {
        const Placement placement = view.placement(index);
        core::check(placement.block < blocks.size(), "build_mesh: lượt đặt trỏ khối ngoài view đã kiểm");
        vertex_total += blocks[placement.block].vertex_count;
        face_total += blocks[placement.block].face_count;
    }
    if (vertex_total > kMaxMeshVertices || face_total > kMaxMeshTriangles) return std::unexpected(MeshError::kTooLarge);
    Mesh mesh;
    mesh.vertices.reserve(vertex_total);
    mesh.triangles.reserve(face_total);
    for (std::uint32_t index = 0; index < view.placement_count; ++index) {
        const Placement placement = view.placement(index);
        const BlockView& block = blocks[placement.block];
        const auto base = static_cast<std::uint32_t>(mesh.vertices.size());
        for (std::uint32_t vertex = 0; vertex < block.vertex_count; ++vertex) {
            mesh.vertices.push_back(transform_vertex(view.frame, placement, block.vertex(vertex)));
        }
        for (std::uint32_t face_index = 0; face_index < block.face_count; ++face_index) {
            const Face face = block.face(face_index);
            mesh.triangles.push_back(Corners{face.corners[0] + base, face.corners[1] + base, face.corners[2] + base});
        }
    }
    mesh.triangle_count = static_cast<std::uint32_t>(mesh.triangles.size());
    mesh.vertex_count = static_cast<std::uint32_t>(mesh.vertices.size());
    return mesh;
}

} // namespace

std::int32_t vertex_key_component(float value) noexcept {
    const float product = value * kKeyScale;
    const auto bits = std::bit_cast<std::uint32_t>(product);
    const auto exponent = static_cast<std::int32_t>((bits >> 23U) & 0xFFU) - 127;
    if (exponent < 0) return 0;
    const std::uint32_t mantissa = (bits << 8U) | 0x80000000U;
    const std::uint32_t shift = static_cast<std::uint32_t>(31 - exponent) & 31U; // shr cl chỉ lấy 5 bit
    const std::uint32_t sign = (bits >> 31U) != 0U ? 0xFFFFFFFFU : 0U; // sar 31
    const std::uint32_t magnitude = mantissa >> shift;
    return std::bit_cast<std::int32_t>((magnitude ^ sign) - sign);
}

std::expected<Mesh, MeshError> build_mesh(const BuildingFileView& view) {
    if (view.version == kBlocksVersion) return build_blocks(view);
    return build_cells(view);
}

} // namespace game::collision::detail
