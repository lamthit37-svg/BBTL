// Tệp va chạm công trình (.WCollision) của client: bộ đọc nội bộ của module collision, bước đầu
// của bản port BuildingCollision trong PathLib.dll. Bố cục theo docs/VA-CHAM.md của TLBB Dev (dòng
// 29, 43-55) và bộ đọc chuẩn T1 (lệnh scan của TOOLS/port/make_building_file.py). Số little-endian.
// - 0xFF000001: i32 số ô; mỗi ô i32 x, i32 z, i32 số tam giác, rồi tam giác 9 f32 (ba đỉnh x y z).
// - 0xFF000002: u16 số khối; mỗi khối u16 số đỉnh, đỉnh 3 f32, u16 số tam giác, tam giác 3 u16;
//   khung 6 f32 (gốc x y z, tỉ lệ x y z); u16 số lượt đặt; mỗi lượt 10 f32 (tỉ lệ x y z, vị trí
//   x y z, quaternion w x y z) và u16 chỉ số khối.
// Tệp là dữ liệu ngoài: parse_building_file đi trọn tệp một lần, kiểm mọi số đếm, chỉ số và số
// thực so với số byte còn lại, rồi trả một view KHÔNG cấp phát: số đếm và các span trỏ vào bộ đệm
// gốc. Phần tử đọc bằng cách ghép từng byte rồi std::bit_cast qua hàm truy cập, nên bộ đệm đặt ở offset nào cũng
// được, kể cả lệch căn lề, và không phụ thuộc thứ tự byte của máy. Mảng phẳng, tam giác thế giới và phép đặt là
// việc của Model (vai C) dựng từ view.
// API công khai (collision::load, height, raycast, bounds) là của vai C, không ở tệp này.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string_view>

namespace game::collision {

inline constexpr std::uint32_t kCellsVersion = 0xFF000001U;
inline constexpr std::uint32_t kBlocksVersion = 0xFF000002U;

// Mỗi chỗ hỏng một giá trị, theo thứ tự bộ đọc gặp nó.
enum class [[nodiscard]] LoadError : std::uint8_t {
    kTooLarge, // tệp từ 1 GiB trở lên: số đếm tổng và offset giữ trong 32 bit
    kTruncatedVersion, // chưa đủ 4 byte mã bản
    kTruncatedCellCount, // mã 1: hết byte giữa số ô
    kCellsBeyondEnd, // mã 1: số ô x 12 byte đầu ô vượt phần còn lại
    kTruncatedCell, // mã 1: hết byte giữa đầu một ô (x, z, số tam giác)
    kTrianglesBeyondEnd, // mã 1: số tam giác x 36 byte vượt phần còn lại
    kNonfiniteTriangle, // mã 1: toạ độ tam giác NaN hay vô cực
    kTruncatedBlockCount, // mã 2: hết byte giữa số khối
    kBlocksBeyondEnd, // mã 2: số khối x 4 byte tối thiểu vượt phần còn lại
    kTruncatedVertexCount, // mã 2: hết byte giữa số đỉnh của một khối
    kVerticesBeyondEnd, // mã 2: số đỉnh x 12 byte vượt phần còn lại
    kNonfiniteVertex, // mã 2: toạ độ đỉnh NaN hay vô cực
    kTruncatedFaceCount, // mã 2: hết byte giữa số tam giác của một khối
    kFacesBeyondEnd, // mã 2: số tam giác x 6 byte vượt phần còn lại
    kVertexOutOfBlock, // mã 2: chỉ số đỉnh của tam giác không nhỏ hơn số đỉnh của khối
    kTruncatedFrame, // mã 2: hết byte giữa khung 6 f32
    kNonfiniteFrame, // mã 2: gốc hay tỉ lệ của khung NaN hay vô cực
    kZeroFrameScale, // mã 2: một tỉ lệ của khung bằng 0
    kTruncatedPlacementCount, // mã 2: hết byte giữa số lượt đặt
    kPlacementsBeyondEnd, // mã 2: số lượt đặt x 42 byte vượt phần còn lại
    kNonfinitePlacement, // mã 2: tỉ lệ, vị trí hay quaternion của lượt đặt NaN hay vô cực
    kBlockOutOfRange, // mã 2: lượt đặt trỏ khối không có
};

// Câu tiếng Việt ngắn cho log.
[[nodiscard]] std::string_view describe(LoadError error) noexcept;

namespace detail {

struct Point3 {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
};

// Ba đỉnh theo thứ tự trong tệp, toạ độ game chưa đổi.
struct Triangle {
    std::array<Point3, 3> corners{};
};

// Chỉ số đỉnh trong khối của nó (0 .. vertex_count - 1), như tệp.
struct Face {
    std::array<std::uint32_t, 3> corners{};
};

// Khung của mã 2: gốc thế giới và tỉ lệ từng trục, như .Terrain cùng cảnh.
struct Frame {
    Point3 origin;
    Point3 scale;
};

// Một lượt đặt khối vào thế giới; rotation là quaternion w x y z như tệp.
struct Placement {
    Point3 scale;
    Point3 position;
    std::array<float, 4> rotation{};
    std::uint32_t block = 0;
};

// Một ô của mã 1. triangles là triangle_count x 36 byte của ô trong bộ đệm gốc; next là offset
// của ô kế trong BuildingFileView::cells (bằng cells.size() sau ô cuối).
struct CellView {
    std::int32_t x = 0;
    std::int32_t z = 0;
    std::uint32_t triangle_count = 0;
    std::span<const std::byte> triangles;
    std::size_t next = 0;

    [[nodiscard]] Triangle triangle(std::uint32_t index) const noexcept;
};

// Một khối mẫu của mã 2, toạ độ cục bộ của lưới; next như CellView::next, trong blocks.
struct BlockView {
    std::uint32_t vertex_count = 0;
    std::uint32_t face_count = 0;
    std::span<const std::byte> vertices;
    std::span<const std::byte> faces;
    std::size_t next = 0;

    [[nodiscard]] Point3 vertex(std::uint32_t index) const noexcept;
    [[nodiscard]] Face face(std::uint32_t index) const noexcept;
};

// Kết quả đọc một tệp đã kiểm. Ô và khối dài thay đổi nên duyệt tuần tự: cell_at(0) hay
// block_at(0) là phần tử đầu, rồi lấy next; offset khác các giá trị đó là vi phạm hợp đồng.
// Mã 1 chỉ có các trường cell, triangle; mã 2 chỉ có block, vertex, face, frame, placement. version là bản đã đọc
// theo: kBlocksVersion, hay kCellsVersion cho mọi mã khác (bản gốc đọc mọi mã khác 0xFF000002 như bản 1; mã thô ở 4
// byte đầu tệp). Mã 1 có số ô n <= 0 là mô hình rỗng: cell_count = 0, triangle_count = 0, cells rỗng.
// View mượn bộ đệm: bộ đệm phải sống lâu hơn view.
struct BuildingFileView {
    std::uint32_t version = 0;
    std::uint32_t cell_count = 0;
    std::uint32_t triangle_count = 0;
    std::span<const std::byte> cells;
    std::uint32_t block_count = 0;
    std::uint32_t vertex_count = 0;
    std::uint32_t face_count = 0;
    std::span<const std::byte> blocks;
    Frame frame;
    std::uint32_t placement_count = 0;
    std::span<const std::byte> placements;

    [[nodiscard]] CellView cell_at(std::size_t offset) const noexcept;
    [[nodiscard]] BlockView block_at(std::size_t offset) const noexcept;
    [[nodiscard]] Placement placement(std::uint32_t index) const noexcept;
};

using ParseResult = std::expected<BuildingFileView, LoadError>;

// Ngưỡng của kTooLarge: bộ đệm từ kFileLimit byte trở lên bị từ chối trước khi đọc byte nào (số đếm tổng và offset
// giữ trong 32 bit).
inline constexpr std::size_t kFileLimit = std::size_t{1} << 30U;

// Kiểm và đọc cả tệp, không cấp phát. Tệp hỏng trả LoadError. Đúng bằng parse_with_limit(bytes, kFileLimit).
[[nodiscard]] ParseResult parse_building_file(std::span<const std::byte> bytes) noexcept;

// Như parse_building_file nhưng ngưỡng của kTooLarge là limit. Điểm chèn cho test: kiểm nhánh kTooLarge bằng bộ đệm
// nhỏ thay vì cấp kFileLimit byte thật (R3-10 K1, L 16:10); mã sản phẩm gọi parse_building_file.
[[nodiscard]] ParseResult parse_with_limit(std::span<const std::byte> bytes, std::size_t limit) noexcept;

} // namespace detail
} // namespace game::collision
