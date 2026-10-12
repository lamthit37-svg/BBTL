// collision/mesh.hpp — lưới sau nạp của BuildingCollision (MeshInterface trong PathLib.dll), vai C, B3.
// Dựng từ BuildingFileView của bộ đọc (building_file.hpp), không định nghĩa lại kiểu tệp. Luật theo
// so-do/b-fenghuang-bo.md (B, mã máy 0x180004580 và 0x180004a00), trùng byte bộ nhớ DLL trên 26 cảnh:
// - Mã 1 (lưới ô): mỗi tam giác gọi map đỉnh cho đỉnh 2, 1, 0 theo thứ tự đó; khoá đỉnh là ba số
//   vertex_key_component (cắt-về-0 bằng phép bit của f32(v * 10000)); đỉnh mới đẩy f32 GỐC của lần gặp đầu.
//   Bộ ba (i0, i1, i2) vào std::set (so từ điển có dấu, trùng thì bỏ); mảng tam giác theo thứ tự set.
//   NbTris = cỡ set mod 65536, NbVerts = số đỉnh mod 65536 (movzx word ở 0x18000481b, 0x18000483d: gói,
//   không kẹp); cây chỉ dựng trên NbTris tam giác đầu, còn mảng đỉnh giữ đủ.
// - Mã 2 (khối + lượt đặt): mỗi lượt đặt theo thứ tự tệp đẩy mọi đỉnh của khối qua transform_vertex rồi mọi
//   mặt cộng số đỉnh đã đẩy trước nó. Không gộp, không set, không cắt.
// Tam giác suy biến (hai hay ba chỉ số trùng, hay ba đỉnh trùng toạ độ) được GIỮ ở cả hai mã như gốc.
#pragma once

#include "collision/building_file.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <vector>

namespace game::collision::detail {

// Khác gốc (chống tệp hỏng): DLL không có trần nào. Trần trên số bản ghi tam giác của tệp mã 1 và trên số
// tam giác, số đỉnh sau dựng của mã 2, để tệp hỏng không làm cấp phát hàng chục GB. Cảnh thật lớn nhất:
// mã 1 fenghuang 259 594 bản ghi; mã 2 bianjing 293 604 tam giác, 205 131 đỉnh. Chờ L chốt con số.
inline constexpr std::uint32_t kMaxCellRecords = 1U << 21U;
inline constexpr std::uint64_t kMaxMeshTriangles = 1U << 22U;
inline constexpr std::uint64_t kMaxMeshVertices = 1U << 22U;

enum class [[nodiscard]] MeshError : std::uint8_t {
    kTooLarge, // vượt trần ở trên (khác gốc)
};

// Lưới như MeshInterface của DLL. triangles là mảng Tris đủ (mã 1: mọi bộ ba của set, kể cả phần sau
// NbTris); vertices là vector đỉnh đủ. triangle_count, vertex_count là NbTris, NbVerts của DLL.
struct Mesh {
    std::vector<std::array<std::uint32_t, 3>> triangles;
    std::vector<Point3> vertices;
    std::uint32_t triangle_count = 0;
    std::uint32_t vertex_count = 0;
};

// Một thành phần khoá đỉnh mã 1 (0x180002b4d..0x180002c0c): b = bit của f32(value * 10000); e = mũ − 127;
// m = (b << 8) | 0x80000000; r = m >> ((31 − e) & 31); đổi dấu theo bit dấu; 0 khi e < 0. Không phải
// cvttss2si: |tích| >= 2^31 cho giá trị gói như mã máy.
[[nodiscard]] std::int32_t vertex_key_component(float value) noexcept;

// Dựng lưới từ view đã kiểm. Chỉ trả lỗi khi vượt trần.
[[nodiscard]] std::expected<Mesh, MeshError> build_mesh(const BuildingFileView& view);

} // namespace game::collision::detail
