// Bộ đọc .WCollision: một lượt đi trọn tệp, kiểm rồi ghi số đếm và các span vào view. Không cấp
// phát: lỗi trả qua std::expected của một enum, view chỉ chứa số và span.
// Theo PathLib.dll ở mọi chỗ DLL có hành vi xác định (nguyên tắc L): mã bản khác 0xFF000002 đọc như bản 1, số ô
// n <= 0 là mô hình rỗng, byte sau phần cuối bị bỏ qua (oracle của B: so-do/b-goc-n-am-ma-la.log và
// so-do/b-goc-byte-thua.log). Từ chối khi bản gốc đọc ngoài biên (cụt, số đếm vượt tệp, chỉ số ngoài khối) và ở
// các chỗ ghi `Khác gốc:` bên dưới.
// Mọi kích cỡ lấy từ tệp được so với số byte còn lại và trả LoadError; core::check chỉ giữ bất biến nội bộ (offset
// trong vùng đã cắt đúng cỡ, chỉ số truyền vào hàm truy cập).
#include "collision/building_file.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <ranges>
#include <span>
#include <string_view>
#include <type_traits>

namespace game::collision {
namespace {

using enum LoadError;
using detail::BuildingFileView;
using detail::Point3;

constexpr std::size_t kWordBytes = 4;
constexpr std::size_t kHalfBytes = 2;
constexpr std::size_t kCellHeadBytes = 12;
constexpr std::size_t kCellCountAt = 8;
constexpr std::size_t kTriangleBytes = 36;
constexpr std::size_t kBlockHeadBytes = 4;
constexpr std::size_t kVertexBytes = 12;
constexpr std::size_t kFaceBytes = 6;
constexpr std::size_t kFrameBytes = 24;
constexpr std::size_t kPlacementBytes = 42;
constexpr std::size_t kPlacementFloatBytes = 40;
constexpr std::size_t kPointBytes = 12;
constexpr std::size_t kRotationAt = 24;

using Bytes = std::span<const std::byte>;
using Problem = std::optional<LoadError>;
using Region = std::expected<Bytes, LoadError>;
using Word = std::expected<std::uint32_t, LoadError>;

// bytes bỏ offset byte đầu. Bất biến nội bộ: offset luôn nằm trong vùng đã cắt đúng cỡ.
[[nodiscard]] Bytes drop(Bytes bytes, std::size_t offset) noexcept {
    core::check(offset <= bytes.size(), "collision: vị trí ngoài vùng đã kiểm");
    return bytes.subspan(offset);
}

// size byte đầu của bytes. Bất biến nội bộ như drop.
[[nodiscard]] Bytes head(Bytes bytes, std::size_t size) noexcept {
    core::check(size <= bytes.size(), "collision: vùng ngoài vùng đã kiểm");
    return bytes.first(size);
}

// Một số 2 hay 4 byte ở đầu bytes: ghép từng byte theo little-endian của tệp rồi std::bit_cast sang Value, nên không
// phụ thuộc thứ tự byte của máy hay căn lề của bộ đệm.
template <class Value>
    requires(sizeof(Value) == 2 || sizeof(Value) == 4)
[[nodiscard]] Value load(Bytes bytes) noexcept {
    using Bits = std::conditional_t<sizeof(Value) == 2, std::uint16_t, std::uint32_t>;
    std::uint32_t bits = 0;
    for (const std::byte part : head(bytes, sizeof(Value)) | std::views::reverse) {
        bits = (bits << 8U) | std::to_integer<std::uint32_t>(part);
    }
    return std::bit_cast<Value>(static_cast<Bits>(bits));
}

template <class Value>
[[nodiscard]] Value load_at(Bytes bytes, std::size_t offset) noexcept {
    return load<Value>(drop(bytes, offset));
}

[[nodiscard]] Point3 point_at(Bytes bytes, std::size_t offset) noexcept {
    const Bytes point = drop(bytes, offset);
    return Point3{.x = load_at<float>(point, 0), .y = load_at<float>(point, 4), .z = load_at<float>(point, 8)};
}

[[nodiscard]] bool is_zero(float value) noexcept {
    return std::fpclassify(value) == FP_ZERO;
}

// Con trỏ đọc tuần tự. take trả nullopt khi thiếu byte để bên gọi trả LoadError: kích cỡ lấy từ tệp không bao giờ
// đi tới core::check.
class Reader {
public:
    explicit Reader(Bytes bytes) noexcept : rest_(bytes) {}

    [[nodiscard]] std::size_t left() const noexcept { return rest_.size(); }
    [[nodiscard]] Bytes rest() const noexcept { return rest_; }

    [[nodiscard]] std::optional<Bytes> take(std::size_t size) noexcept {
        if (size > rest_.size()) return std::nullopt;
        const Bytes taken = rest_.first(size);
        rest_ = rest_.subspan(size);
        return taken;
    }

private:
    Bytes rest_;
};

// Phần đã đi qua kể từ start (start là rest() lúc bắt đầu).
[[nodiscard]] Bytes walked(Bytes start, const Reader& reader) noexcept {
    return head(start, start.size() - reader.left());
}

// Số u32 kế tiếp; thiếu byte là lỗi truncated.
[[nodiscard]] Word take_word(Reader& reader, LoadError truncated) noexcept {
    const std::optional<Bytes> field = reader.take(kWordBytes);
    if (!field) return std::unexpected(truncated);
    return load<std::uint32_t>(*field);
}

// Số u16 kế tiếp; thiếu byte là lỗi truncated.
[[nodiscard]] Word take_half(Reader& reader, LoadError truncated) noexcept {
    const std::optional<Bytes> field = reader.take(kHalfBytes);
    if (!field) return std::unexpected(truncated);
    return load<std::uint16_t>(*field);
}

// Vùng count x each byte kế tiếp; vượt phần còn lại là lỗi beyond. So bằng phép chia nên không tràn số khi nhân.
[[nodiscard]] Region take_region(Reader& reader, std::uint32_t count, std::size_t each, LoadError beyond) noexcept {
    if (count > reader.left() / each) return std::unexpected(beyond);
    const std::optional<Bytes> region = reader.take(std::size_t{count} * each);
    if (!region) return std::unexpected(beyond);
    return *region;
}

// Số f32 không hữu hạn trong floats (cỡ là bội của 4 do bên gọi cắt).
[[nodiscard]] std::uint32_t count_nonfinite(Bytes floats) noexcept {
    std::uint32_t found = 0;
    for (std::size_t at = 0; at < floats.size(); at += kWordBytes) {
        found += static_cast<std::uint32_t>(!std::isfinite(load_at<float>(floats, at)));
    }
    return found;
}

// Chỉ số đỉnh lớn nhất trong vùng tam giác (3 u16 mỗi tam giác); 0 khi vùng rỗng.
[[nodiscard]] std::uint32_t largest_corner(Bytes faces) noexcept {
    std::uint32_t largest = 0;
    for (std::size_t at = 0; at < faces.size(); at += kHalfBytes) {
        largest = std::max<std::uint32_t>(largest, load_at<std::uint16_t>(faces, at));
    }
    return largest;
}

// Số tam giác của ô (i32 ở kCellCountAt của đầu ô): âm là ô rỗng như gốc (R2-1, xem check_cell).
[[nodiscard]] std::uint32_t cell_triangles(Bytes cell) noexcept {
    const auto count = load_at<std::int32_t>(cell, kCellCountAt);
    return count < 0 ? 0U : static_cast<std::uint32_t>(count);
}

[[nodiscard]] Problem check_cell(Reader& reader, BuildingFileView& view) noexcept {
    const std::optional<Bytes> cell = reader.take(kCellHeadBytes);
    if (!cell) return kTruncatedCell;
    // x, z: ô âm (G3-28) và hai ô cách nhau 2^32 (G3-29) đều nạp được, C chốt 14:13; lưới tra dựng
    // từ ô là việc của Model nên kẹp hộp bao ở đó, không ở đây.
    // Số tam giác âm là ô rỗng, rồi đọc tiếp ô sau, theo gốc (R2-1 của so-do/r-a-building-file.md): 0x180004680
    // đọc số tam giác, 0x180004687 test eax,eax; jle bỏ qua vòng tam giác. B đo g3-20 (so-do/b-goc-g3-20.log, sha
    // 68d5eeed): DLL trả True, 0 đỉnh, mNbTris 0; 36 byte tam giác sau đầu ô bị bỏ qua như đuôi thừa.
    const std::uint32_t wanted = cell_triangles(*cell);
    const Region triangles = take_region(reader, wanted, kTriangleBytes, kTrianglesBeyondEnd);
    if (!triangles) return triangles.error();
    view.triangle_count += wanted;
    // Khác gốc: bản gốc giữ NaN và vô cực khi nạp; ở đây từ chối (C chốt 14:13). 435 tệp thật có 0
    // giá trị không hữu hạn (so-do/b-t1-tep-2.tsv) nên kết quả truy vấn vẫn trùng bit với bản gốc.
    if (count_nonfinite(*triangles) != 0) return kNonfiniteTriangle;
    return std::nullopt;
}

// Số ô i32. n <= 0 là mô hình rỗng như bản gốc: B đo n = -1 nạp được, 0 tam giác, mọi truy vấn trả false
// (so-do/b-goc-n-am-ma-la.log); L chốt cho mọi n <= 0 (G3-11, G3-12). Không đọc gì thêm: phần còn lại của tệp bị
// bỏ qua như byte thừa (B thêm 4 và 36 byte sau tệp n = -1, vẫn rỗng: so-do/b-goc-byte-thua.log).
[[nodiscard]] Problem check_cells(Reader& reader, BuildingFileView& view) noexcept {
    const Word word = take_word(reader, kTruncatedCellCount);
    if (!word) return word.error();
    const auto cells = std::bit_cast<std::int32_t>(*word);
    if (cells <= 0) return std::nullopt;
    const auto count = static_cast<std::uint32_t>(cells);
    if (count > reader.left() / kCellHeadBytes) return kCellsBeyondEnd;
    view.cell_count = count;
    const Bytes start = reader.rest();
    Problem error;
    for (std::uint32_t index = 0; index < count && !error; ++index) {
        error = check_cell(reader, view);
    }
    view.cells = walked(start, reader);
    return error;
}

[[nodiscard]] Problem check_block(Reader& reader, BuildingFileView& view) noexcept {
    const Word vertices = take_half(reader, kTruncatedVertexCount);
    if (!vertices) return vertices.error();
    const Region points = take_region(reader, *vertices, kVertexBytes, kVerticesBeyondEnd);
    if (!points) return points.error();
    // Khác gốc: đỉnh NaN hay vô cực bị từ chối, bản gốc giữ; 435 tệp thật có 0 giá trị như vậy.
    if (count_nonfinite(*points) != 0) return kNonfiniteVertex;
    const Word faces = take_half(reader, kTruncatedFaceCount);
    if (!faces) return faces.error();
    const Region corners = take_region(reader, *faces, kFaceBytes, kFacesBeyondEnd);
    if (!corners) return corners.error();
    view.vertex_count += *vertices;
    view.face_count += *faces;
    if (*faces != 0 && largest_corner(*corners) >= *vertices) return kVertexOutOfBlock;
    return std::nullopt;
}

[[nodiscard]] Problem check_blocks(Reader& reader, BuildingFileView& view) noexcept {
    const Word blocks = take_half(reader, kTruncatedBlockCount);
    if (!blocks) return blocks.error();
    if (*blocks > reader.left() / kBlockHeadBytes) return kBlocksBeyondEnd;
    view.block_count = *blocks;
    const Bytes start = reader.rest();
    Problem error;
    for (std::uint32_t index = 0; index < *blocks && !error; ++index) {
        error = check_block(reader, view);
    }
    view.blocks = walked(start, reader);
    return error;
}

[[nodiscard]] Problem check_frame(Reader& reader, BuildingFileView& view) noexcept {
    const std::optional<Bytes> frame = reader.take(kFrameBytes);
    if (!frame) return kTruncatedFrame;
    view.frame = detail::Frame{.origin = point_at(*frame, 0), .scale = point_at(*frame, kPointBytes)};
    // Khác gốc: khung NaN hay vô cực bị từ chối, bản gốc giữ; 435 tệp thật có 0 giá trị như vậy.
    if (count_nonfinite(*frame) != 0) return kNonfiniteFrame;
    const Point3 scale = view.frame.scale;
    // Khác gốc: tỉ lệ 0 bị từ chối (C chốt 14:13, G3-46) vì đổi sang toạ độ game chia cho tỉ lệ; bản
    // gốc không kiểm. 435 tệp thật có 0 khung như vậy (cột bad_frame của b-t1-tep-2.tsv).
    if (is_zero(scale.x) || is_zero(scale.y) || is_zero(scale.z)) return kZeroFrameScale;
    return std::nullopt;
}

// Lượt đặt: tỉ lệ, vị trí, quaternion w x y z (10 f32) rồi chỉ số khối u16. Quaternion giữ nguyên bit như tệp:
// không chuẩn hoá, không có ngưỡng nào (quaternion toàn 0 của G3-50 cũng nạp), vì Model phải tái hiện đúng hình méo
// mà bản gốc dựng cho họ congren từ quaternion không đơn vị của họ đó; congrentx trong T2 là chốt kiểm. Tỉ lệ lượt
// đặt bằng 0, âm hay subnormal cũng nhận (V-6); chỉ tỉ lệ khung bị kiểm (check_frame).
[[nodiscard]] Problem check_placements(Reader& reader, BuildingFileView& view) noexcept {
    const Word count = take_half(reader, kTruncatedPlacementCount);
    if (!count) return count.error();
    const Region placements = take_region(reader, *count, kPlacementBytes, kPlacementsBeyondEnd);
    if (!placements) return placements.error();
    view.placement_count = *count;
    view.placements = *placements;
    std::uint32_t nonfinite = 0;
    std::uint32_t largest = 0;
    for (std::size_t at = 0; at < placements->size(); at += kPlacementBytes) {
        nonfinite += count_nonfinite(head(drop(*placements, at), kPlacementFloatBytes));
        largest = std::max<std::uint32_t>(largest, load_at<std::uint16_t>(*placements, at + kPlacementFloatBytes));
    }
    // Khác gốc: lượt đặt NaN hay vô cực bị từ chối, bản gốc giữ; 435 tệp thật có 0 giá trị như vậy.
    if (nonfinite != 0) return kNonfinitePlacement;
    if (*count != 0 && largest >= view.block_count) return kBlockOutOfRange;
    return std::nullopt;
}

// Mã bản: 0xFF000002 là bản khối; mọi mã khác đọc như bản 1 như bản gốc (B đo 0xFF000003 với thân bản 1: nạp và
// 16 truy vấn trùng từng bit tệp 0xFF000001 đối chứng, so-do/b-goc-n-am-ma-la.log; L chốt cho mọi mã khác, G3-04
// tới G3-08). view.version ghi bản đã đọc theo (kCellsVersion), mã thô vẫn ở 4 byte đầu tệp.
// Khác gốc: DLL đọc vượt biên (0x180004680/0x1800046a0), xem so-do/b-goc-ma-la-than-2.log: mã lạ trên thân mã 2
// không rỗng; ở đây thân đó đọc theo bản 1 có kiểm biên nên bị từ chối. Thân mã 2 rỗng (32 byte, i32 ở offset 4
// bằng 0) mang mã lạ thì nạp ra mô hình rỗng như DLL (L 15:50, theo mã máy 0x1800045e7/0x180004603/0x180004670).
[[nodiscard]] Problem check_body(Reader& reader, BuildingFileView& view) noexcept {
    if (view.version != kBlocksVersion) {
        view.version = kCellsVersion;
        return check_cells(reader, view);
    }
    Problem error = check_blocks(reader, view);
    if (!error) error = check_frame(reader, view);
    if (!error) error = check_placements(reader, view);
    return error;
}

} // namespace

namespace detail {

Triangle CellView::triangle(std::uint32_t index) const noexcept {
    core::check(index < triangle_count, "CellView::triangle: chỉ số ngoài ô");
    const Bytes triangle = drop(triangles, std::size_t{index} * kTriangleBytes);
    const Point3 first = point_at(triangle, 0);
    const Point3 second = point_at(triangle, kPointBytes);
    return Triangle{.corners = {first, second, point_at(triangle, 2 * kPointBytes)}};
}

Point3 BlockView::vertex(std::uint32_t index) const noexcept {
    core::check(index < vertex_count, "BlockView::vertex: chỉ số ngoài khối");
    return point_at(vertices, std::size_t{index} * kVertexBytes);
}

Face BlockView::face(std::uint32_t index) const noexcept {
    core::check(index < face_count, "BlockView::face: chỉ số ngoài khối");
    const Bytes face = drop(faces, std::size_t{index} * kFaceBytes);
    const std::uint32_t first = load_at<std::uint16_t>(face, 0);
    const std::uint32_t second = load_at<std::uint16_t>(face, 2);
    return Face{.corners = {first, second, load_at<std::uint16_t>(face, 4)}};
}

CellView BuildingFileView::cell_at(std::size_t offset) const noexcept {
    CellView cell;
    cell.x = load_at<std::int32_t>(cells, offset);
    cell.z = load_at<std::int32_t>(cells, offset + 4);
    // Số tam giác âm là ô rỗng như khi parse (R2-1).
    cell.triangle_count = cell_triangles(drop(cells, offset));
    const std::size_t size = std::size_t{cell.triangle_count} * kTriangleBytes;
    cell.triangles = head(drop(cells, offset + kCellHeadBytes), size);
    cell.next = offset + kCellHeadBytes + size;
    return cell;
}

BlockView BuildingFileView::block_at(std::size_t offset) const noexcept {
    BlockView block;
    block.vertex_count = load_at<std::uint16_t>(blocks, offset);
    block.vertices = head(drop(blocks, offset + 2), std::size_t{block.vertex_count} * kVertexBytes);
    const std::size_t faces_at = offset + 2 + block.vertices.size();
    block.face_count = load_at<std::uint16_t>(blocks, faces_at);
    block.faces = head(drop(blocks, faces_at + 2), std::size_t{block.face_count} * kFaceBytes);
    block.next = faces_at + 2 + block.faces.size();
    return block;
}

Placement BuildingFileView::placement(std::uint32_t index) const noexcept {
    core::check(index < placement_count, "BuildingFileView::placement: chỉ số ngoài bảng");
    const Bytes record = drop(placements, std::size_t{index} * kPlacementBytes);
    Placement result;
    result.scale = point_at(record, 0);
    result.position = point_at(record, kPointBytes);
    std::size_t offset = kRotationAt;
    for (float& part : result.rotation) {
        part = load_at<float>(record, offset);
        offset += kWordBytes;
    }
    result.block = load_at<std::uint16_t>(record, kPlacementFloatBytes);
    return result;
}

ParseResult parse_building_file(std::span<const std::byte> bytes) noexcept {
    return parse_with_limit(bytes, kFileLimit);
}

ParseResult parse_with_limit(std::span<const std::byte> bytes, std::size_t limit) noexcept {
    if (bytes.size() >= limit) return std::unexpected(kTooLarge);
    Reader reader(bytes);
    BuildingFileView view;
    const Word version = take_word(reader, kTruncatedVersion);
    if (!version) return std::unexpected(version.error());
    view.version = *version;
    // Byte sau phần cuối bị bỏ qua ở cả hai mã như bản gốc: B thêm 4 và 36 byte sau tệp mã 1, nạp và 16 truy vấn
    // trùng từng bit tệp không thừa (so-do/b-goc-byte-thua.log); L chốt cho cả mã 2 (G3-30, G3-64).
    const Problem error = check_body(reader, view);
    if (error) return std::unexpected(*error);
    return view;
}

} // namespace detail

std::string_view describe(LoadError error) noexcept {
    switch (error) {
    case kTooLarge: return "tệp quá lớn (từ 1 GiB)";
    case kTruncatedVersion: return "cụt giữa mã bản";
    case kTruncatedCellCount: return "mã 1: cụt giữa số ô";
    case kCellsBeyondEnd: return "mã 1: số ô vượt số byte còn lại";
    case kTruncatedCell: return "mã 1: cụt giữa đầu ô";
    case kTrianglesBeyondEnd: return "mã 1: số tam giác vượt số byte còn lại";
    case kNonfiniteTriangle: return "mã 1: toạ độ tam giác không hữu hạn";
    case kTruncatedBlockCount: return "mã 2: cụt giữa số khối";
    case kBlocksBeyondEnd: return "mã 2: số khối vượt số byte còn lại";
    case kTruncatedVertexCount: return "mã 2: cụt giữa số đỉnh";
    case kVerticesBeyondEnd: return "mã 2: số đỉnh vượt số byte còn lại";
    case kNonfiniteVertex: return "mã 2: toạ độ đỉnh không hữu hạn";
    case kTruncatedFaceCount: return "mã 2: cụt giữa số tam giác";
    case kFacesBeyondEnd: return "mã 2: số tam giác vượt số byte còn lại";
    case kVertexOutOfBlock: return "mã 2: chỉ số đỉnh ngoài khối";
    case kTruncatedFrame: return "mã 2: cụt giữa khung";
    case kNonfiniteFrame: return "mã 2: khung không hữu hạn";
    case kZeroFrameScale: return "mã 2: tỉ lệ khung bằng 0";
    case kTruncatedPlacementCount: return "mã 2: cụt giữa số lượt đặt";
    case kPlacementsBeyondEnd: return "mã 2: số lượt đặt vượt số byte còn lại";
    case kNonfinitePlacement: return "mã 2: lượt đặt không hữu hạn";
    case kBlockOutOfRange: return "mã 2: lượt đặt trỏ khối không có";
    }
    return "lỗi lạ";
}

} // namespace game::collision