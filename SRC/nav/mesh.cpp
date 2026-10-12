// Bộ đọc .path. Thứ tự và cỡ từng trường theo PathDataImpl::getDataFromMemory (PathLib.dll
// 0x18001c6f0): bản 0x2000 ở nhánh 0x18001cd98, bản 0x1000 ở nhánh đầu hàm.
// Khác gốc: bản gốc tin mọi chỉ số trong tệp; ở đây chỉ số ngoài khoảng là lỗi kBadIndex. Tệp bản
// 0x1000 ghi hàng xóm vắng là 0xFFFF, bản gốc đem số đó đi tra bảng tam giác (đọc quá biên); ở
// đây 0xFFFF của bản 0x1000 thành kNone.
#include "nav/mesh.hpp"

#include <algorithm>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::nav {
namespace {

constexpr std::uint32_t kWideVersion = 0x2000;
constexpr std::uint32_t kNarrowVersion = 0x1000;
constexpr std::uint32_t kNarrowNone = 0xFFFF;
constexpr std::size_t kPointBytes = 8;
// Trần số ô của lưới tra. Tệp lớn nhất của client có 128 x 128 = 16384 ô.
constexpr std::uint64_t kCellLimit = 1U << 20U;
// Trần cỡ tệp: dưới trần này mọi vị trí trong cell_triangles và cell_edges vừa 32 bit.
constexpr std::size_t kFileLimit = std::size_t{1} << 30U;

// Con trỏ đọc little-endian, ghép số từ từng byte. Mọi hàm lấy số đòi bên gọi đã hỏi has().
class Reader {
public:
    explicit Reader(std::span<const std::byte> bytes) noexcept : bytes_(bytes) {}

    void use_wide_indices(bool is_wide) noexcept { index_bytes_ = is_wide ? 4 : 2; }
    [[nodiscard]] std::size_t left() const noexcept { return bytes_.size(); }
    [[nodiscard]] bool has(std::size_t count) const noexcept { return count <= bytes_.size(); }
    [[nodiscard]] std::size_t index_bytes() const noexcept { return index_bytes_; }
    [[nodiscard]] bool is_wide() const noexcept { return index_bytes_ == 4; }

    [[nodiscard]] std::uint32_t u8() noexcept {
        const auto value = std::to_integer<std::uint32_t>(bytes_.front());
        bytes_ = bytes_.subspan(1);
        return value;
    }

    [[nodiscard]] std::uint32_t u16() noexcept {
        const std::uint32_t low = u8();
        const std::uint32_t high = u8();
        return low | (high << 8U);
    }

    [[nodiscard]] std::uint32_t u32() noexcept {
        const std::uint32_t low = u16();
        const std::uint32_t high = u16();
        return low | (high << 16U);
    }

    [[nodiscard]] float f32() noexcept { return std::bit_cast<float>(u32()); }

    // Số đếm hay chỉ số: 16 hoặc 32 bit tuỳ bản tệp.
    [[nodiscard]] std::uint32_t index() noexcept { return is_wide() ? u32() : u16(); }

    // Chỉ số tam giác hàng xóm: bản 16 bit ghi "không có" là 0xFFFF.
    [[nodiscard]] std::uint32_t neighbour() noexcept {
        const std::uint32_t value = index();
        const bool is_absent = !is_wide() && value == kNarrowNone;
        return is_absent ? kNone : value;
    }

private:
    std::span<const std::byte> bytes_;
    std::size_t index_bytes_ = 2;
};

// Số đếm của một dãy bản ghi cỡ cố định; rỗng khi dãy không nằm trọn trong phần còn lại.
[[nodiscard]] std::optional<std::uint32_t> take_count(Reader& reader, std::size_t each) noexcept {
    if (!reader.has(reader.index_bytes())) return std::nullopt;
    const std::uint32_t count = reader.index();
    if (count > reader.left() / each) return std::nullopt;
    return count;
}

[[nodiscard]] bool read_vertices(Reader& reader, Mesh& mesh) {
    const std::optional<std::uint32_t> count = take_count(reader, kPointBytes);
    if (!count) return false;
    mesh.vertices.resize(*count);
    for (Point& vertex : mesh.vertices) {
        vertex.x = reader.f32();
        vertex.z = reader.f32();
    }
    return true;
}

void read_triangle(Reader& reader, Triangle& triangle) noexcept {
    for (std::uint32_t& corner : triangle.corners) {
        corner = reader.index();
    }
    for (std::uint32_t& neighbour : triangle.neighbours) {
        neighbour = reader.neighbour();
    }
    triangle.flags = static_cast<std::uint8_t>(reader.u8());
    triangle.island = reader.index();
}

[[nodiscard]] bool read_triangles(Reader& reader, Mesh& mesh) {
    const std::size_t each = (reader.index_bytes() * 7) + 1;
    const std::optional<std::uint32_t> count = take_count(reader, each);
    if (!count) return false;
    mesh.triangles.resize(*count);
    for (Triangle& triangle : mesh.triangles) {
        read_triangle(reader, triangle);
    }
    return true;
}

[[nodiscard]] bool read_edges(Reader& reader, Mesh& mesh) {
    const std::optional<std::uint32_t> count = take_count(reader, reader.index_bytes() * 4);
    if (!count) return false;
    mesh.edges.resize(*count);
    for (Edge& edge : mesh.edges) {
        edge.first = reader.index();
        edge.second = reader.index();
        edge.wall = reader.index();
        edge.open = reader.index();
    }
    return true;
}

// Đầu lưới: cỡ ô luôn là 32 bit, số cột và số hàng theo bản tệp. Bản gốc đọc đúng như vậy cả ở
// bản 0x1000, nên hai tệp bản đó của client (cỡ ô ghi 16 bit) ra cỡ ô rất lớn và mọi điểm rơi
// vào ô (0, 0); giữ nguyên để trùng bản gốc.
[[nodiscard]] bool read_grid_head(Reader& reader, Mesh& mesh) noexcept {
    if (!reader.has(4 + (reader.index_bytes() * 2))) return false;
    mesh.cell_size = reader.u32();
    mesh.columns = reader.index();
    mesh.rows = reader.index();
    return true;
}

void read_ids(Reader& reader, std::vector<std::uint32_t>& out, std::uint32_t count) {
    for (std::uint32_t taken = 0; taken < count; ++taken) {
        out.push_back(reader.index());
    }
}

[[nodiscard]] bool read_cell(Reader& reader, Mesh& mesh) {
    if (!reader.has(reader.index_bytes() * 2)) return false;
    Cell cell;
    cell.triangle_count = reader.index();
    cell.edge_count = reader.index();
    const std::uint64_t listed = std::uint64_t{cell.triangle_count} + cell.edge_count;
    if (listed > reader.left() / reader.index_bytes()) return false;
    cell.triangles_at = static_cast<std::uint32_t>(mesh.cell_triangles.size());
    cell.edges_at = static_cast<std::uint32_t>(mesh.cell_edges.size());
    read_ids(reader, mesh.cell_triangles, cell.triangle_count);
    read_ids(reader, mesh.cell_edges, cell.edge_count);
    mesh.cells.push_back(cell);
    return true;
}

[[nodiscard]] std::expected<void, MeshError> read_grid(Reader& reader, Mesh& mesh) {
    if (!read_grid_head(reader, mesh)) return std::unexpected(MeshError::kTruncated);
    const std::uint64_t total = std::uint64_t{mesh.columns} * mesh.rows;
    const bool is_sane = mesh.cell_size > 0 && total > 0 && total <= kCellLimit;
    if (!is_sane) return std::unexpected(MeshError::kBadGrid);
    // Mỗi ô chiếm ít nhất hai số đếm: số ô khai quá phần còn lại thì dừng trước khi cấp phát.
    if (total > reader.left() / (reader.index_bytes() * 2)) return std::unexpected(MeshError::kTruncated);
    mesh.cells.reserve(static_cast<std::size_t>(total));
    bool is_whole = true;
    for (std::uint64_t cell = 0; cell < total && is_whole; ++cell) {
        is_whole = read_cell(reader, mesh);
    }
    if (!is_whole) return std::unexpected(MeshError::kTruncated);
    return {};
}

// Kiểm chỉ số: sau bước này mọi chỉ số trong Mesh tra được bảng của nó.
struct Limits {
    std::uint32_t vertices = 0;
    std::uint32_t triangles = 0;
    std::uint32_t edges = 0;

    [[nodiscard]] bool has_vertex(std::uint32_t index) const noexcept { return index < vertices; }
    [[nodiscard]] bool has_edge(std::uint32_t index) const noexcept { return index < edges; }
    [[nodiscard]] bool has_triangle(std::uint32_t index) const noexcept { return index < triangles; }
    [[nodiscard]] bool has_side(std::uint32_t index) const noexcept { return index == kNone || index < triangles; }

    [[nodiscard]] bool fits(const Triangle& triangle) const noexcept {
        const auto corner_ok = [this](std::uint32_t index) { return has_vertex(index); };
        const auto side_ok = [this](std::uint32_t index) { return has_side(index); };
        const bool has_corners = std::ranges::all_of(triangle.corners, corner_ok);
        return has_corners && std::ranges::all_of(triangle.neighbours, side_ok);
    }

    [[nodiscard]] bool fits(const Edge& edge) const noexcept {
        const bool has_ends = has_vertex(edge.first) && has_vertex(edge.second);
        return has_ends && has_side(edge.wall) && has_side(edge.open);
    }
};

[[nodiscard]] bool is_finite(Point point) noexcept {
    return std::isfinite(point.x) && std::isfinite(point.z);
}

[[nodiscard]] std::optional<MeshError> find_flaw(const Mesh& mesh) noexcept {
    Limits limits;
    limits.vertices = static_cast<std::uint32_t>(mesh.vertices.size());
    limits.triangles = static_cast<std::uint32_t>(mesh.triangles.size());
    limits.edges = static_cast<std::uint32_t>(mesh.edges.size());
    if (!std::ranges::all_of(mesh.vertices, is_finite)) return MeshError::kBadNumber;
    const auto triangle_ok = [&limits](const Triangle& triangle) { return limits.fits(triangle); };
    const auto edge_ok = [&limits](const Edge& edge) { return limits.fits(edge); };
    const auto listed_triangle = [&limits](std::uint32_t id) { return limits.has_triangle(id); };
    const auto listed_edge = [&limits](std::uint32_t id) { return limits.has_edge(id); };
    const bool has_shapes = std::ranges::all_of(mesh.triangles, triangle_ok);
    const bool has_edges = std::ranges::all_of(mesh.edges, edge_ok);
    const bool has_lists = std::ranges::all_of(mesh.cell_triangles, listed_triangle);
    const bool has_edge_lists = std::ranges::all_of(mesh.cell_edges, listed_edge);
    if (!has_shapes || !has_edges || !has_lists || !has_edge_lists) return MeshError::kBadIndex;
    return std::nullopt;
}

// Trọng tâm như bản gốc: ((v2 + v1) + v3) / 3, số thực 32 bit.
void set_centre(const Mesh& mesh, Triangle& triangle) noexcept {
    const Point first = mesh.vertices[triangle.corners[0]];
    const Point second = mesh.vertices[triangle.corners[1]];
    const Point third = mesh.vertices[triangle.corners[2]];
    triangle.centre.x = ((second.x + first.x) + third.x) / 3.0F;
    triangle.centre.z = ((second.z + first.z) + third.z) / 3.0F;
}

} // namespace

std::span<const std::uint32_t> Mesh::triangles_of(const Cell& cell) const noexcept {
    return std::span(cell_triangles).subspan(cell.triangles_at, cell.triangle_count);
}

std::span<const std::uint32_t> Mesh::edges_of(const Cell& cell) const noexcept {
    return std::span(cell_edges).subspan(cell.edges_at, cell.edge_count);
}

MeshResult read_mesh(std::span<const std::byte> bytes) {
    if (bytes.size() >= kFileLimit) return std::unexpected(MeshError::kTooLarge);
    Reader reader(bytes);
    if (!reader.has(2)) return std::unexpected(MeshError::kTruncated);
    const std::uint32_t version = reader.u16();
    const bool is_known = version == kWideVersion || version == kNarrowVersion;
    if (!is_known) return std::unexpected(MeshError::kBadVersion);
    reader.use_wide_indices(version == kWideVersion);
    Mesh mesh;
    if (!read_vertices(reader, mesh)) return std::unexpected(MeshError::kTruncated);
    if (!read_triangles(reader, mesh)) return std::unexpected(MeshError::kTruncated);
    if (!read_edges(reader, mesh)) return std::unexpected(MeshError::kTruncated);
    const std::expected<void, MeshError> grid = read_grid(reader, mesh);
    if (!grid) return std::unexpected(grid.error());
    const std::optional<MeshError> flaw = find_flaw(mesh);
    if (flaw) return std::unexpected(*flaw);
    for (Triangle& triangle : mesh.triangles) {
        set_centre(mesh, triangle);
    }
    return mesh;
}

std::string_view describe(MeshError error) noexcept {
    switch (error) {
    case MeshError::kTruncated: return "tệp .path bị cụt";
    case MeshError::kBadVersion: return "tệp .path có số bản lạ";
    case MeshError::kBadIndex: return "tệp .path có chỉ số ngoài khoảng";
    case MeshError::kBadNumber: return "tệp .path có toạ độ không hữu hạn";
    case MeshError::kBadGrid: return "tệp .path có lưới tra không hợp lệ";
    case MeshError::kTooLarge: return "tệp .path quá lớn";
    }
    return "lỗi lưới đi không rõ";
}

} // namespace game::nav
