// Lưới đi và luật đi của client 2026 (SRC/nav). Ba nhóm ca: bộ đọc .path trên byte tự dựng; so từng
// bit với câu trả lời của PathLib.dll gốc ghi ở tests/golden/nav_*.tsv (sinh bằng
// TOOLS/port/pathlib_oracle.py, không sửa tay); luật đi của CPath trên lưới tự vẽ nhúng trong
// nav_yard.tsv. Lưới tự vẽ là vùng 32 x 32 có viền vật cản dày 1, năm khối vật cản tứ giác và một
// hào vây kín một đảo (TOOLS/port/make_path_mesh.py). Góc các khối bị xê dịch tới 0,3 nên các ca
// chọn điểm cách mép khối ít nhất 0,7 đơn vị.
#include "core/check.hpp"
#include "core/number.hpp"
#include "io/file.hpp"
#include "nav/finder.hpp"
#include "nav/mesh.hpp"
#include "nav/route.hpp"
#include "nav_sample.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

namespace nav = game::nav;
using nav::MeshError;
using nav::Point;
using nav::Segment;
using Fields = std::vector<std::string_view>;

// Thư mục tests/golden và thư mục dữ liệu client của máy dựng; rỗng thì các ca cần nó tự bỏ qua.
#ifdef GAME_NAV_GOLDEN
constexpr std::string_view kGoldenFolder = GAME_NAV_GOLDEN;
#else
constexpr std::string_view kGoldenFolder;
#endif
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr std::size_t kQueries = 200;

[[nodiscard]] std::uint32_t bits_of(float value) noexcept {
    return std::bit_cast<std::uint32_t>(value);
}

[[nodiscard]] bool same_bits(Point got, Point want) noexcept {
    return bits_of(got.x) == bits_of(want.x) && bits_of(got.z) == bits_of(want.z);
}

// Số byte của một trường trong tệp.
enum class Width : std::uint8_t { kOne = 1, kTwo = 2, kFour = 4 };

// Ghi các byte thấp của value, byte thấp trước.
void put(Bytes& out, std::uint32_t value, Width width) {
    for (std::size_t index = 0; index < std::to_underlying(width); ++index) {
        out.push_back(static_cast<std::byte>((value >> (index * 8U)) & 0xFFU));
    }
}

void put_all(Bytes& out, std::initializer_list<std::uint32_t> values, Width width) {
    for (const std::uint32_t value : values) {
        put(out, value, width);
    }
}

// Tệp .path nhỏ nhất có đủ mọi phần: hình vuông cạnh 4 cắt theo đường chéo, nửa dưới phải (tam giác
// 0) đi được, nửa trên trái (tam giác 1) là vật cản, đường chéo là cạnh ràng buộc, lưới tra một ô.
// Mỗi trường là một chỗ để ca test bẻ.
struct Sample {
    bool is_wide = true;
    std::uint32_t version = 0x2000;
    std::uint32_t vertex_count = 4;
    float first_x = 0.0F;
    std::uint32_t first_corner = 0;
    std::uint32_t edge_end = 2;
    std::uint32_t cell_size = 8;
    std::uint32_t columns = 1;
    std::uint32_t listed_triangle = 1;
    std::uint32_t listed_edge = 0;
};

[[nodiscard]] Bytes encode(const Sample& sample) {
    const Width wide = sample.is_wide ? Width::kFour : Width::kTwo;
    const std::uint32_t none = sample.is_wide ? nav::kNone : 0xFFFFU;
    Bytes out;
    put(out, sample.version, Width::kTwo);
    put(out, sample.vertex_count, wide);
    put_all(out, {bits_of(sample.first_x), 0U, kFourBits, 0U, kFourBits, kFourBits, 0U, kFourBits}, Width::kFour);
    put(out, 2, wide);
    put_all(out, {sample.first_corner, 1U, 2U, none, 1U, none}, wide);
    put(out, 0, Width::kOne);
    put(out, 1, wide);
    put_all(out, {0U, 2U, 3U, none, none, 0U}, wide);
    put(out, 1, Width::kOne);
    put(out, 0, wide);
    put(out, 1, wide);
    put_all(out, {0U, sample.edge_end, 1U, 0U}, wide);
    put(out, sample.cell_size, Width::kFour);
    put_all(out, {sample.columns, 1U, 2U, 1U, 0U, sample.listed_triangle, sample.listed_edge}, wide);
    return out;
}

[[nodiscard]] Sample narrow_sample() {
    Sample sample;
    sample.is_wide = false;
    sample.version = 0x1000;
    return sample;
}

[[nodiscard]] std::optional<MeshError> error_of(const Sample& sample) {
    const nav::MeshResult mesh = nav::read_mesh(encode(sample));
    if (mesh) return std::nullopt;
    return mesh.error();
}

void expect_sample_mesh(Context& context, const nav::Mesh& mesh) {
    context.expect(mesh.vertices.size() == 4 && mesh.triangles.size() == 2, "bốn đỉnh, hai tam giác");
    context.expect(mesh.edges.size() == 1 && mesh.cells.size() == 1, "một cạnh, một ô");
    const nav::Triangle& open = mesh.triangles[0];
    const nav::Triangle& wall = mesh.triangles[1];
    context.expect(!open.is_obstacle() && wall.is_obstacle(), "cờ vật cản");
    context.expect(open.neighbours == std::array{nav::kNone, 1U, nav::kNone}, "hàng xóm vắng là kNone");
    context.expect(wall.neighbours == std::array{nav::kNone, nav::kNone, 0U}, "hàng xóm của vật cản");
    const Point centre{.x = ((4.0F + 0.0F) + 4.0F) / 3.0F, .z = ((0.0F + 0.0F) + 4.0F) / 3.0F};
    context.expect(same_bits(open.centre, centre), "trọng tâm tính theo thứ tự của bản gốc");
    context.expect(mesh.triangles_of(mesh.cells[0]).size() == 2, "ô liệt kê hai tam giác");
    context.expect(mesh.edges_of(mesh.cells[0]).size() == 1, "ô liệt kê một cạnh");
    context.expect(mesh.cell_size == 8 && mesh.columns == 1 && mesh.rows == 1, "đầu lưới tra");
}

void reads_both_versions(Context& context) {
    const nav::MeshResult wide = nav::read_mesh(encode(Sample{}));
    const nav::MeshResult narrow = nav::read_mesh(encode(narrow_sample()));
    context.expect(wide.has_value() && narrow.has_value(), "đọc được bản 0x2000 và 0x1000");
    if (!wide || !narrow) return;
    expect_sample_mesh(context, *wide);
    expect_sample_mesh(context, *narrow);
}

// Số độ dài ngắn hơn cả tệp mà bộ đọc không trả kTruncated.
[[nodiscard]] std::size_t cuts_not_truncated(const Sample& sample) {
    const Bytes whole = encode(sample);
    const std::span<const std::byte> view{whole};
    std::size_t wrong = 0;
    for (std::size_t size = 0; size < whole.size(); ++size) {
        const nav::MeshResult cut = nav::read_mesh(view.first(size));
        wrong += (cut.has_value() || cut.error() != MeshError::kTruncated) ? 1U : 0U;
    }
    return wrong;
}

// Cắt tệp ở mọi độ dài ngắn hơn: luôn là kTruncated, không ca nào đọc được.
void every_cut_is_truncated(Context& context) {
    context.expect(cuts_not_truncated(Sample{}) == 0, "bản 0x2000: mọi độ dài ngắn hơn là kTruncated");
    context.expect(cuts_not_truncated(narrow_sample()) == 0, "bản 0x1000: mọi độ dài ngắn hơn là kTruncated");
}

void rejects_bad_fields(Context& context) {
    const float not_a_number = std::numeric_limits<float>::quiet_NaN();
    const float endless = std::numeric_limits<float>::infinity();
    context.expect(error_of(Sample{.version = 0x3000}) == MeshError::kBadVersion, "số bản lạ");
    context.expect(error_of(Sample{.vertex_count = 0xFFFFFFFFU}) == MeshError::kTruncated, "số đỉnh khai quá tệp");
    context.expect(error_of(Sample{.first_x = not_a_number}) == MeshError::kBadNumber, "toạ độ NaN");
    context.expect(error_of(Sample{.first_x = endless}) == MeshError::kBadNumber, "toạ độ vô cực");
    context.expect(error_of(Sample{.first_corner = 4}) == MeshError::kBadIndex, "đỉnh của tam giác ngoài bảng");
    context.expect(error_of(Sample{.edge_end = 9}) == MeshError::kBadIndex, "đỉnh của cạnh ngoài bảng");
    context.expect(error_of(Sample{.listed_triangle = 2}) == MeshError::kBadIndex, "ô trỏ tam giác ngoài bảng");
    context.expect(error_of(Sample{.listed_edge = 1}) == MeshError::kBadIndex, "ô trỏ cạnh ngoài bảng");
}

void rejects_bad_grids(Context& context) {
    context.expect(error_of(Sample{.cell_size = 0}) == MeshError::kBadGrid, "cỡ ô 0");
    context.expect(error_of(Sample{.columns = 0}) == MeshError::kBadGrid, "lưới không cột");
    context.expect(error_of(Sample{.columns = 2'000'000}) == MeshError::kBadGrid, "số ô vượt trần");
    context.expect(error_of(Sample{.columns = 1000}) == MeshError::kTruncated, "số ô khai quá tệp");
}

constexpr std::array kErrors{
    MeshError::kTruncated,
    MeshError::kBadVersion,
    MeshError::kBadIndex,
    MeshError::kBadNumber,
    MeshError::kBadGrid,
    MeshError::kTooLarge,
};

void describes_every_error(Context& context) {
    std::vector<std::string_view> seen(kErrors.size());
    std::ranges::transform(kErrors, seen.begin(), nav::describe);
    std::ranges::sort(seen);
    context.expect(std::ranges::adjacent_find(seen) == seen.end(), "mỗi lỗi một câu riêng");
    context.expect(!seen.front().empty(), "không câu nào rỗng");
}

// Các truy vấn trên tệp dựng tay, tính nhẩm được: đoạn (3, 1) tới (1, 3) cắt đường chéo ở (2, 2).
void answers_on_the_sample(Context& context) {
    const nav::MeshResult mesh = nav::read_mesh(encode(Sample{}));
    context.expect(mesh.has_value(), "đọc được tệp mẫu");
    if (!mesh) return;
    const Point low{.x = 3.0F, .z = 1.0F};
    const Point high{.x = 1.0F, .z = 3.0F};
    context.expect(nav::locate(*mesh, low, nav::Ground::kOpen) == 0U, "điểm dưới nằm trên tam giác đi được");
    context.expect(!nav::locate(*mesh, low, nav::Ground::kObstacle), "điểm dưới không nằm trong vật cản");
    context.expect(nav::locate(*mesh, high, nav::Ground::kObstacle) == 1U, "điểm trên nằm trong vật cản");
    const auto found = nav::crossings(*mesh, Segment{.start = low, .end = high});
    context.expect(found && found->size() == 1, "cắt đúng một cạnh");
    if (!found || found->empty()) return;
    const nav::Crossing& hit = found->front();
    context.expect(same_bits(hit.at, Point{.x = 2.0F, .z = 2.0F}) && hit.flags == 1, "chỗ cắt và cờ");
    context.expect(bits_of(hit.distance_squared) == bits_of(2.0F), "bình phương khoảng cách");
    context.expect(nav::sees(*mesh, Segment{.start = low, .end = Point{.x = 3.5F, .z = 0.5F}}), "nhìn thấy");
    context.expect(!nav::crossings(*mesh, Segment{.start = low, .end = Point{.x = 9.0F, .z = 1.0F}}), "ngoài lưới");
}

// Từ đây là phần đọc tệp số vàng.
[[nodiscard]] Fields split(std::string_view text, char mark) {
    Fields parts;
    std::size_t start = 0;
    for (std::size_t stop = text.find(mark); stop != std::string_view::npos; stop = text.find(mark, start)) {
        parts.push_back(text.substr(start, stop - start));
        start = stop + 1;
    }
    parts.push_back(text.substr(start));
    return parts;
}

// Số thực ghi bằng 8 chữ số hex của mẫu bit; ô hỏng ra NaN để phép so chắc chắn lệch.
[[nodiscard]] float float_of(std::string_view hex) noexcept {
    const core::OptionalUnsigned parsed = core::parse_unsigned(hex, 16);
    return parsed ? std::bit_cast<float>(parsed->value) : std::numeric_limits<float>::quiet_NaN();
}

// Số đếm hay chỉ số thập phân; "-" là không có.
[[nodiscard]] std::optional<std::uint32_t> whole_of(std::string_view text) noexcept {
    const core::OptionalUnsigned parsed = core::parse_unsigned(text, 10);
    if (!parsed) return std::nullopt;
    return parsed->value;
}

[[nodiscard]] Point point_at(const Fields& row, std::size_t index) noexcept {
    return Point{.x = float_of(row[index]), .z = float_of(row[index + 1])};
}

// Bốn ô sau tên loại dòng là hai đầu của đoạn. Tiền điều kiện: dòng có ít nhất năm ô.
[[nodiscard]] Segment segment_of(const Fields& row) noexcept {
    return Segment{.start = point_at(row, 1), .end = point_at(row, 3)};
}

[[nodiscard]] Bytes bytes_of_hex(std::string_view hex) {
    Bytes out;
    out.reserve(hex.size() / 2);
    for (std::size_t start = 0; start + 1 < hex.size(); start += 2) {
        const core::OptionalUnsigned pair = core::parse_unsigned(hex.substr(start, 2), 16);
        out.push_back(static_cast<std::byte>(pair ? pair->value : 0U));
    }
    return out;
}

[[nodiscard]] bool locate_matches(const nav::Mesh& mesh, const Fields& row) {
    if (row.size() != 5) return false;
    const Point point = point_at(row, 1);
    const bool is_open_same = nav::locate(mesh, point, nav::Ground::kOpen) == whole_of(row[3]);
    return is_open_same && nav::locate(mesh, point, nav::Ground::kObstacle) == whole_of(row[4]);
}

[[nodiscard]] bool crossing_matches(const nav::Crossing& got, const Fields& row, std::size_t first) {
    const bool is_same_key = bits_of(got.distance_squared) == bits_of(float_of(row[first]));
    const bool is_same_flags = whole_of(row[first + 1]) == std::uint32_t{got.flags};
    return is_same_key && is_same_flags && same_bits(got.at, point_at(row, first + 2));
}

[[nodiscard]] bool cross_matches(const nav::Mesh& mesh, const Fields& row) {
    if (row.size() < 6) return false;
    const auto found = nav::crossings(mesh, segment_of(row));
    const std::optional<std::uint32_t> count = whole_of(row[5]);
    if (!found || !count) return !found && !count;
    if (found->size() != *count || row.size() != 6 + (std::size_t{*count} * 4)) return false;
    bool is_same = true;
    for (std::size_t index = 0; index < found->size() && is_same; ++index) {
        is_same = crossing_matches((*found)[index], row, 6 + (index * 4));
    }
    return is_same;
}

// Từ ô first trở đi là các cặp toạ độ của đường đi mong đợi.
[[nodiscard]] bool points_match(std::span<const Point> got, const Fields& row, std::size_t first) {
    if (row.size() != first + (got.size() * 2)) return false;
    bool is_same = true;
    for (std::size_t index = 0; index < got.size() && is_same; ++index) {
        is_same = same_bits(got[index], point_at(row, first + (index * 2)));
    }
    return is_same;
}

[[nodiscard]] bool find_matches(const nav::Mesh& mesh, const Fields& row, nav::Scratch& scratch) {
    if (row.size() < 6) return false;
    const std::optional<nav::Path> path = nav::find_path(mesh, segment_of(row), scratch);
    const std::optional<std::uint32_t> count = whole_of(row[5]);
    if (!path || !count) return !path && !count;
    return path->size() == *count && points_match(*path, row, 6);
}

[[nodiscard]] bool stop_matches(const nav::Field& field, const Fields& row) {
    if (row.size() < 6) return false;
    const std::optional<Point> stop = field.straight_stop(segment_of(row));
    if (!stop) return row.size() == 6 && row[5] == "-";
    return row.size() == 7 && same_bits(*stop, point_at(row, 5));
}

// Số dòng đã so của một loại, số dòng lệch và dòng lệch đầu tiên (đếm từ 1).
struct Tally {
    std::size_t rows = 0;
    std::size_t wrong = 0;
    std::size_t first_wrong = 0;

    void add(bool is_same, std::size_t line) noexcept {
        ++rows;
        if (is_same) return;
        first_wrong = wrong == 0 ? line : first_wrong;
        ++wrong;
    }
};

struct Totals {
    Tally locate;
    Tally cross;
    Tally find;
    Tally stop;
};

// Một tệp số vàng đang được so trên một lưới.
struct Golden {
    nav::Field field;
    nav::Scratch scratch;
    Totals totals;

    void check_row(const Fields& row, std::size_t line) {
        const std::string_view kind = row.front();
        if (kind == "locate") totals.locate.add(locate_matches(field.mesh(), row), line);
        if (kind == "cross") totals.cross.add(cross_matches(field.mesh(), row), line);
        if (kind == "find") totals.find.add(find_matches(field.mesh(), row, scratch), line);
        if (kind == "stop") totals.stop.add(stop_matches(field, row), line);
    }
};

// Dòng đầu tiên thuộc loại kind, đã tách ô; rỗng khi không có.
[[nodiscard]] Fields row_of(const Fields& lines, std::string_view kind) {
    const auto is_kind = [kind](std::string_view line) { return split(line, '\t').front() == kind; };
    const auto found = std::ranges::find_if(lines, is_kind);
    if (found == lines.end()) return {};
    return split(*found, '\t');
}

[[nodiscard]] std::string read_golden(std::string_view name) {
    if (kGoldenFolder.empty()) return {};
    const std::filesystem::path path = std::filesystem::path(std::string(kGoldenFolder)) / name;
    return io::read_text(path).value_or(std::string{});
}

void expect_clean(Context& context, const Tally& tally, std::string_view kind, std::size_t rows) {
    const std::string wrong = std::to_string(tally.wrong) + " dòng lệch, dòng đầu " + std::to_string(tally.first_wrong);
    const std::string note = std::string(kind) + ": " + wrong;
    context.expect(tally.wrong == 0, note);
    context.expect(tally.rows == rows, kind);
}

// So mọi dòng của tệp số vàng text trên lưới mesh; cỡ cảnh lấy ở dòng area của chính tệp đó.
void compare_golden(Context& context, std::string_view text, nav::Mesh mesh) {
    const Fields lines = split(text, '\n');
    const Fields area_row = row_of(lines, "area");
    context.expect(area_row.size() == 3, "tệp số vàng có dòng area");
    if (area_row.size() != 3) return;
    const nav::Area area{.width = float_of(area_row[1]), .depth = float_of(area_row[2])};
    Golden golden{.field = nav::Field(std::move(mesh), area), .scratch = {}, .totals = {}};
    for (std::size_t index = 0; index < lines.size(); ++index) {
        golden.check_row(split(lines[index], '\t'), index + 1);
    }
    expect_clean(context, golden.totals.locate, "locate", kQueries);
    expect_clean(context, golden.totals.cross, "cross", kQueries);
    expect_clean(context, golden.totals.find, "find", kQueries * 2);
    expect_clean(context, golden.totals.stop, "stop", kQueries);
}

// Lưới tự vẽ nhúng ở dòng mesh của nav_yard.tsv; rỗng khi bản dựng không có thư mục số vàng.
[[nodiscard]] std::optional<nav::Mesh> yard_mesh(std::string_view text) {
    const Fields mesh_row = row_of(split(text, '\n'), "mesh");
    if (mesh_row.size() != 2) return std::nullopt;
    nav::MeshResult mesh = nav::read_mesh(bytes_of_hex(mesh_row[1]));
    if (!mesh) return std::nullopt;
    return std::move(*mesh);
}

void yard_matches_the_original(Context& context) {
    const std::string text = read_golden("nav_yard.tsv");
    if (text.empty()) return;
    std::optional<nav::Mesh> mesh = yard_mesh(text);
    context.expect(mesh.has_value(), "đọc được lưới nhúng trong nav_yard.tsv");
    if (!mesh) return;
    context.expect(mesh->triangles.size() == 66 && mesh->edges.size() == 32, "66 tam giác, 32 cạnh");
    compare_golden(context, text, std::move(*mesh));
}

void real_scene_matches_the_original(Context& context) {
    const std::string text = read_golden("nav_huoyangu.tsv");
    if (text.empty() || kClientData.empty()) return;
    const std::filesystem::path path = std::filesystem::path(std::string(kClientData)) / "Scene" / "huoyangu.path";
    const io::TextResult file = io::read_text(path);
    context.expect(file.has_value(), "đọc được huoyangu.path");
    if (!file) return;
    nav::MeshResult mesh = nav::read_mesh(std::as_bytes(std::span{*file}));
    context.expect(mesh.has_value(), "huoyangu.path là lưới hợp lệ");
    if (!mesh) return;
    compare_golden(context, text, std::move(*mesh));
}

// Từ đây là luật đi trên lưới tự vẽ. Khối A phủ x 6..12, z 6..20; khối C phủ x 16..20, z 14..26; đảo
// trong hào phủ x 24..28, z 26..29; viền vật cản là dải rộng 1 quanh vùng.
constexpr nav::Area kYard{.width = 32.0F, .depth = 32.0F};
constexpr Point kWest{.x = 2.0F, .z = 13.0F};
constexpr Point kInsideA{.x = 9.0F, .z = 13.0F};
// Phía đông khối A, đủ xa khe hẹp: đường tới đây vòng qua đầu bắc của khối A.
constexpr Point kEastOfA{.x = 14.0F, .z = 17.0F};
constexpr Point kCorner{.x = 2.0F, .z = 2.0F};

[[nodiscard]] std::optional<nav::Field> yard_field() {
    std::optional<nav::Mesh> mesh = yard_mesh(read_golden("nav_yard.tsv"));
    if (!mesh) return std::nullopt;
    return nav::Field(std::move(*mesh), kYard);
}

[[nodiscard]] float gap(const Segment& span) noexcept {
    return std::hypot(span.start.x - span.end.x, span.start.z - span.end.z);
}

void knows_inside_and_walls(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    const float not_a_number = std::numeric_limits<float>::quiet_NaN();
    context.expect(field->is_inside(Point{}) && field->is_inside(Point{.x = 32.0F, .z = 32.0F}), "hai mép tính là trong");
    context.expect(!field->is_inside(Point{.x = -0.01F, .z = 5.0F}), "âm là ngoài");
    context.expect(!field->is_inside(Point{.x = 5.0F, .z = 32.01F}), "quá cỡ cảnh là ngoài");
    context.expect(!field->is_inside(Point{.x = not_a_number, .z = 5.0F}), "NaN là ngoài");
    context.expect(field->is_unreachable(kInsideA), "trong khối vật cản");
    context.expect(field->is_unreachable(Point{.x = 40.0F, .z = 1.0F}), "ngoài cảnh");
    context.expect(!field->is_unreachable(kWest), "chỗ trống");
}

void walks_straight_when_clear(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    const Point north{.x = 2.0F, .z = 20.0F};
    const auto clear = field->straight_stop(Segment{.start = kCorner, .end = north});
    context.expect(clear && same_bits(*clear, north), "không vướng thì tới đúng đích");
    const auto shortest = field->straight_stop(Segment{.start = kCorner, .end = Point{.x = 3.0F, .z = 3.0F}});
    context.expect(shortest.has_value(), "bình phương quãng đúng 2 thì còn đi");
    const auto tiny = field->straight_stop(Segment{.start = kCorner, .end = Point{.x = 2.5F, .z = 2.5F}});
    context.expect(!tiny, "quãng ngắn hơn căn 2 thì không đi");
    const auto outside = field->straight_stop(Segment{.start = kCorner, .end = Point{.x = 40.0F, .z = 2.0F}});
    context.expect(!outside, "đích ngoài cảnh thì không đi");
}

void stops_before_a_wall(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    const Segment walk{.start = kWest, .end = kInsideA};
    const auto found = nav::crossings(field->mesh(), walk);
    const auto stop = field->straight_stop(walk);
    context.expect(found && !found->empty() && stop.has_value(), "có chỗ cắt và có chỗ dừng");
    if (!found || found->empty() || !stop) return;
    const Point hit = found->front().at;
    const float back = gap(Segment{.start = *stop, .end = hit});
    context.expect(std::fabs(back - 0.1F) < 0.001F, "dừng cách cạnh 0,1");
    context.expect(stop->x < hit.x && !field->is_unreachable(*stop), "dừng phía trước cạnh, ngoài vật cản");
    context.expect(nav::sees(field->mesh(), Segment{.start = kWest, .end = *stop}), "đường tới chỗ dừng thông");
}

void escapes_through_one_edge_only(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    const Point edge_of_wall{.x = 7.0F, .z = 13.0F};
    const auto out = field->straight_stop(Segment{.start = edge_of_wall, .end = Point{.x = 5.2F, .z = 13.0F}});
    context.expect(out && same_bits(*out, Point{.x = 5.2F, .z = 13.0F}), "ra khỏi vật cản không lùi, không xét quãng ngắn");
    const Point deep{.x = 9.0F, .z = 16.0F};
    const auto through = field->straight_stop(Segment{.start = deep, .end = Point{.x = 22.0F, .z = 16.0F}});
    context.expect(!through, "phải qua hơn một cạnh thì không cho ra");
}

void routes_around_a_wall(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    nav::Scratch scratch;
    const nav::MoveAsk ask{.walk = Segment{.start = kWest, .end = kEastOfA}, .mode = nav::MoveMode::kFind};
    const nav::Path path = field->plan_move(ask, scratch);
    context.expect(path.size() >= 2, "đi vòng qua ít nhất một góc");
    if (path.empty()) return;
    context.expect(same_bits(path.back(), kEastOfA), "điểm cuối là đích");
    Point from = kWest;
    bool is_clear = true;
    for (const Point next : path) {
        is_clear = is_clear && nav::sees(field->mesh(), Segment{.start = from, .end = next});
        from = next;
    }
    // Không phải bất biến của bản gốc (đường qua khe 0,05 của lưới này cắt sượt một góc khối), nhưng
    // đúng với đường vòng quanh một khối đứng riêng.
    context.expect(is_clear, "mọi đoạn của đường đều không cắt cạnh vật cản");
}

void falls_back_to_a_straight_walk(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    nav::Scratch scratch;
    const Segment into_wall{.start = kWest, .end = kInsideA};
    const nav::Path blocked = field->plan_move(nav::MoveAsk{.walk = into_wall}, scratch);
    const auto stop = field->straight_stop(into_wall);
    context.expect(blocked.size() == 1 && stop && same_bits(blocked.front(), *stop), "đích trong tường: tới sát tường");
    const Segment to_island{.start = kCorner, .end = Point{.x = 26.0F, .z = 28.0F}};
    const nav::Path moat = field->plan_move(nav::MoveAsk{.walk = to_island}, scratch);
    context.expect(moat.size() == 1 && !field->is_unreachable(moat.front()), "đích ở đảo khác: tới sát hào");
    const Point reached = moat.empty() ? kCorner : moat.front();
    context.expect(gap(Segment{.start = reached, .end = to_island.end}) > 1.0F, "không tới được đảo");
    const Segment off_map{.start = kCorner, .end = Point{.x = 40.0F, .z = 2.0F}};
    context.expect(field->plan_move(nav::MoveAsk{.walk = off_map}, scratch).empty(), "đích ngoài cảnh: từ chối");
}

void stuck_player_may_only_escape(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    nav::Scratch scratch;
    const Segment out{.start = Point{.x = 7.0F, .z = 13.0F}, .end = kWest};
    const nav::Path found = field->plan_move(nav::MoveAsk{.walk = out, .mode = nav::MoveMode::kFind}, scratch);
    context.expect(found.size() == 1 && same_bits(found.front(), kWest), "nhấp chuột ra chỗ trống: đi thẳng ra");
    const nav::Path held = field->plan_move(nav::MoveAsk{.walk = out, .mode = nav::MoveMode::kStraight}, scratch);
    context.expect(held.empty(), "giữ chuột khi đang trong vật cản: không đi");
    const Segment deeper{.start = Point{.x = 7.0F, .z = 13.0F}, .end = kInsideA};
    context.expect(field->plan_move(nav::MoveAsk{.walk = deeper}, scratch).empty(), "trong vật cản đi sâu thêm: từ chối");
    const Segment clear{.start = kCorner, .end = Point{.x = 2.0F, .z = 20.0F}};
    const nav::Path run = field->plan_move(nav::MoveAsk{.walk = clear, .mode = nav::MoveMode::kStraight}, scratch);
    context.expect(run.size() == 1 && same_bits(run.front(), clear.end), "giữ chuột ở chỗ trống: đi thẳng");
}

void key_steps_never_enter_walls(Context& context) {
    const std::optional<nav::Field> field = yard_field();
    if (!field) return;
    const Point near_wall{.x = 5.2F, .z = 13.0F};
    const Point in_wall{.x = 6.9F, .z = 13.0F};
    const Point free_end{.x = 2.3F, .z = 2.0F};
    context.expect(same_bits(field->step_reach(Segment{.start = kCorner, .end = free_end}), free_end), "bước thông");
    const Point held = field->step_reach(Segment{.start = near_wall, .end = in_wall});
    context.expect(!field->is_unreachable(held) && held.x < in_wall.x, "bước vào tường dừng trước tường");
    const Point deeper{.x = 9.2F, .z = 13.0F};
    context.expect(same_bits(field->step_reach(Segment{.start = kInsideA, .end = deeper}), kInsideA), "trong tường không đi sâu");
    context.expect(same_bits(field->step_reach(Segment{.start = in_wall, .end = near_wall}), near_wall), "bước ra khỏi tường");
    const Point edge{.x = 0.1F, .z = 2.0F};
    const Point beyond{.x = -0.2F, .z = 2.0F};
    context.expect(same_bits(field->step_reach(Segment{.start = edge, .end = beyond}), edge), "không bước ra ngoài cảnh");
}

constexpr std::array kCases{
    Case{.name = "reads_both_versions", .body = &reads_both_versions},
    Case{.name = "every_cut_is_truncated", .body = &every_cut_is_truncated},
    Case{.name = "rejects_bad_fields", .body = &rejects_bad_fields},
    Case{.name = "rejects_bad_grids", .body = &rejects_bad_grids},
    Case{.name = "describes_every_error", .body = &describes_every_error},
    Case{.name = "answers_on_the_sample", .body = &answers_on_the_sample},
    Case{.name = "yard_matches_the_original", .body = &yard_matches_the_original},
    Case{.name = "real_scene_matches_the_original", .body = &real_scene_matches_the_original},
    Case{.name = "knows_inside_and_walls", .body = &knows_inside_and_walls},
    Case{.name = "walks_straight_when_clear", .body = &walks_straight_when_clear},
    Case{.name = "stops_before_a_wall", .body = &stops_before_a_wall},
    Case{.name = "escapes_through_one_edge_only", .body = &escapes_through_one_edge_only},
    Case{.name = "routes_around_a_wall", .body = &routes_around_a_wall},
    Case{.name = "falls_back_to_a_straight_walk", .body = &falls_back_to_a_straight_walk},
    Case{.name = "stuck_player_may_only_escape", .body = &stuck_player_may_only_escape},
    Case{.name = "key_steps_never_enter_walls", .body = &key_steps_never_enter_walls},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "nav_tests: mọi ca phải qua");
    return 0;
}
