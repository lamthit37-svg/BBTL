// Lưới đi của một cảnh (tệp .path của client 2026): đỉnh, tam giác có cờ vật cản, cạnh ràng buộc
// nằm giữa một tam giác vật cản và một tam giác đi được, và lưới ô vuông tra tam giác, cạnh theo
// vị trí. Client 2026 không còn tự đọc .region: nó giao tệp này cho PathLib.dll, và mọi luật đi,
// chặn, tìm đường của bản gốc chạy trên chính lưới này.
// Bố cục tệp đọc từ PathDataImpl::getDataFromMemory của PathLib.dll (0x18001c6f0); bộ đọc khớp
// đúng số byte của cả 419 tệp .path của client. Tệp là dữ liệu ngoài: mọi số đếm và chỉ số được
// kiểm trước khi dùng, sai thì trả lỗi. Nguồn và lệnh tái hiện: docs/DUONG-DI-2026.md.
#pragma once

#include "core/ground_point.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string_view>
#include <vector>

namespace game::nav {

using Point = core::GroundPoint;

// Chỉ số "không có" của bản gốc (tam giác hàng xóm vắng): 1000000.
inline constexpr std::uint32_t kNone = 1000000;
inline constexpr std::uint8_t kObstacleBit = 1U;
inline constexpr std::uint8_t kFlyableBit = 2U;

enum class [[nodiscard]] MeshError : std::uint8_t {
    kTruncated,
    kBadVersion,
    kBadIndex,
    kBadNumber,
    kBadGrid,
    kTooLarge,
};

// neighbours[k] nằm đối diện corners[k]; kNone khi cạnh đó là biên. centre là trọng tâm, tính lúc
// nạp bằng đúng phép tính của bản gốc vì A* dùng nó làm ước lượng.
struct Triangle {
    std::array<std::uint32_t, 3> corners{};
    std::array<std::uint32_t, 3> neighbours{};
    std::uint8_t flags = 0;
    std::uint32_t island = 0;
    Point centre;

    [[nodiscard]] bool is_obstacle() const noexcept { return (flags & kObstacleBit) != 0; }
};

// Cạnh ràng buộc: hai đỉnh và hai tam giác hai bên (trong dữ liệu của client, wall luôn là tam
// giác vật cản và open là tam giác đi được).
struct Edge {
    std::uint32_t first = 0;
    std::uint32_t second = 0;
    std::uint32_t wall = kNone;
    std::uint32_t open = kNone;
};

// Một ô của lưới tra: khoảng trong Mesh::cell_triangles và Mesh::cell_edges.
struct Cell {
    std::uint32_t triangles_at = 0;
    std::uint32_t triangle_count = 0;
    std::uint32_t edges_at = 0;
    std::uint32_t edge_count = 0;
};

struct Mesh {
    std::vector<Point> vertices;
    std::vector<Triangle> triangles;
    std::vector<Edge> edges;
    // Cạnh của một ô, đơn vị game. Ô (cột, hàng) nằm ở cells[hàng * columns + cột].
    std::uint32_t cell_size = 0;
    std::uint32_t columns = 0;
    std::uint32_t rows = 0;
    std::vector<Cell> cells;
    std::vector<std::uint32_t> cell_triangles;
    std::vector<std::uint32_t> cell_edges;

    [[nodiscard]] std::span<const std::uint32_t> triangles_of(const Cell& cell) const noexcept;
    [[nodiscard]] std::span<const std::uint32_t> edges_of(const Cell& cell) const noexcept;
};

using MeshResult = std::expected<Mesh, MeshError>;

// Cả tệp .path. Hai bản: 0x2000 (số đếm và chỉ số 32 bit) và 0x1000 (16 bit). Tệp từ 1 GiB trở lên
// là kTooLarge: vị trí trong các bảng của Mesh là số 32 bit.
[[nodiscard]] MeshResult read_mesh(std::span<const std::byte> bytes);

// Câu tiếng Việt ngắn cho log.
[[nodiscard]] std::string_view describe(MeshError error) noexcept;

} // namespace game::nav
