// Lũ và tam giác theo WXTerrainLiquid::build. Đỉnh biên được thăm nhưng không lan tiếp.
// Đỉnh cao hơn mực vẫn vào lưới nếu hàng xóm dưới mực đẩy tới, và không tự đẩy tiếp.
// Bốn góc phần tư quanh một đỉnh nằm trong một bảng: thứ tự của bảng là thứ tự thăm và thứ tự
// tam giác của gốc, test liquid_keeps_the_visit_order chốt dãy chỉ số.
#include "client/map/liquid.hpp"

#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"
#include "core/number.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client::map {
namespace {

constexpr int kVertexLimit = 32768;
constexpr std::uint32_t kMissing = 0xFFFFFFFFU;
// Trần số khung của một anim_texture. Chất liệu của client có nhiều nhất 40 khung.
constexpr double kFrameLimit = 256.0;
constexpr std::string_view kBlanks = " \t\r";

struct GridPos {
    int column = 0;
    int row = 0;
};

// Bước từ một đỉnh sang đỉnh hay ô bên cạnh.
struct Step {
    int column = 0;
    int row = 0;
};

constexpr Step kHere{.column = 0, .row = 0};
constexpr Step kWest{.column = -1, .row = 0};
constexpr Step kEast{.column = 1, .row = 0};
constexpr Step kNorth{.column = 0, .row = -1};
constexpr Step kSouth{.column = 0, .row = 1};
constexpr Step kNorthWest{.column = -1, .row = -1};
constexpr Step kSouthWest{.column = -1, .row = 1};
constexpr Step kNorthEast{.column = 1, .row = -1};
constexpr Step kSouthEast{.column = 1, .row = 1};

// Bốn hàng xóm thẳng theo thứ tự gốc đẩy vào hàng đợi, và bốn đỉnh của ô gieo.
constexpr std::array<Step, 4> kStraight{kWest, kEast, kNorth, kSouth};
constexpr std::array<Step, 4> kCellCorners{kHere, kEast, kSouth, kSouthEast};

// Một góc phần tư quanh đỉnh: ô chứa nó, đỉnh chéo, và hai đỉnh kề theo thứ tự của
// _ADD_TRIANGLE. Đường chéo của ô đi qua đỉnh (ô lật hay không lật tuỳ góc) thì góc có hai
// tam giác (chéo, second) và (first, chéo), và đỉnh chéo là hàng xóm; không thì một tam giác
// (first, second).
struct Quadrant {
    Step cell;
    Step diagonal;
    Step first;
    Step second;
    bool is_joined_when_flipped = false;
};

constexpr std::array<Quadrant, 4> kQuadrants{
    Quadrant{
        .cell = kNorthWest, .diagonal = kNorthWest, .first = kWest, .second = kNorth, .is_joined_when_flipped = true},
    Quadrant{.cell = kWest, .diagonal = kSouthWest, .first = kSouth, .second = kWest, .is_joined_when_flipped = false},
    Quadrant{.cell = kNorth, .diagonal = kNorthEast, .first = kNorth, .second = kEast, .is_joined_when_flipped = false},
    Quadrant{.cell = kHere, .diagonal = kSouthEast, .first = kEast, .second = kSouth, .is_joined_when_flipped = true},
};

enum class Corner : std::uint8_t { kOutside, kApart, kJoined };

// Hai đỉnh còn lại của một tam giác, tính từ đỉnh đang thăm.
struct Wedge {
    Step first;
    Step second;
};

struct Work {
    LiquidField field;
    // Mực nước tính bằng đơn vị của mẫu độ cao.
    float level = 0.0F;
    int visited_count = 0;
    int min_column = 0;
    int min_row = 0;
    std::vector<std::uint8_t> visited;
    std::vector<std::uint8_t> touched;
    std::deque<GridPos> pending;
    std::vector<std::size_t> corners;

    [[nodiscard]] const TerrainFile& terrain() const noexcept { return *field.terrain; }
};

// Tiền điều kiện của hai hàm đếm: x_size và z_size không âm.
[[nodiscard]] std::size_t vertex_count(const TerrainFile& terrain) noexcept {
    const std::size_t across = static_cast<std::size_t>(terrain.x_size) + 1;
    return across * (static_cast<std::size_t>(terrain.z_size) + 1);
}

[[nodiscard]] std::size_t cell_count(const TerrainFile& terrain) noexcept {
    return static_cast<std::size_t>(terrain.x_size) * static_cast<std::size_t>(terrain.z_size);
}

[[nodiscard]] bool inside_vertex(const TerrainFile& terrain, GridPos pos) noexcept {
    const bool is_in_columns = pos.column >= 0 && pos.column <= terrain.x_size;
    return is_in_columns && pos.row >= 0 && pos.row <= terrain.z_size;
}

[[nodiscard]] bool inside_cell(const TerrainFile& terrain, GridPos cell) noexcept {
    const bool is_in_columns = cell.column >= 0 && cell.column < terrain.x_size;
    return is_in_columns && cell.row >= 0 && cell.row < terrain.z_size;
}

[[nodiscard]] bool is_border(const TerrainFile& terrain, GridPos pos) noexcept {
    const bool is_side = pos.column <= 0 || pos.column >= terrain.x_size;
    return is_side || pos.row <= 0 || pos.row >= terrain.z_size;
}

[[nodiscard]] std::size_t vertex_index(const TerrainFile& terrain, GridPos pos) noexcept {
    const std::size_t stride = static_cast<std::size_t>(terrain.x_size) + 1;
    return (static_cast<std::size_t>(pos.row) * stride) + static_cast<std::size_t>(pos.column);
}

[[nodiscard]] GridPos shift(GridPos pos, Step step) noexcept {
    pos.column += step.column;
    pos.row += step.row;
    return pos;
}

[[nodiscard]] bool under_level(const Work& work, GridPos pos) noexcept {
    if (!inside_vertex(work.terrain(), pos)) return false;
    const float height = work.field.heights->samples[vertex_index(work.terrain(), pos)];
    return work.level >= height;
}

void push_neighbor(Work& work, GridPos pos) {
    if (!inside_vertex(work.terrain(), pos)) return;
    const std::size_t index = vertex_index(work.terrain(), pos);
    if (work.touched[index] != 0) return;
    work.touched[index] = 1;
    work.pending.push_back(pos);
}

void push_under(Work& work, GridPos pos) {
    if (!under_level(work, pos)) return;
    push_neighbor(work, pos);
}

// Ô phải nằm trong lưới; field_ready đã bảo đảm grid có đủ x_size * z_size ô.
[[nodiscard]] bool is_flipped(const Work& work, GridPos cell) noexcept {
    const auto across = static_cast<std::size_t>(work.terrain().x_size);
    const auto row = static_cast<std::size_t>(cell.row);
    const auto column = static_cast<std::size_t>(cell.column);
    return (work.field.grid->cells[(row * across) + column].flags & kFlipDiagonal) != 0;
}

[[nodiscard]] Corner corner_of(const Work& work, GridPos pos, const Quadrant& quadrant) noexcept {
    const GridPos cell = shift(pos, quadrant.cell);
    if (!inside_cell(work.terrain(), cell)) return Corner::kOutside;
    const bool is_joined = is_flipped(work, cell) == quadrant.is_joined_when_flipped;
    return is_joined ? Corner::kJoined : Corner::kApart;
}

[[nodiscard]] bool was_visited(const Work& work, GridPos pos) noexcept {
    if (!inside_vertex(work.terrain(), pos)) return false;
    return work.visited[vertex_index(work.terrain(), pos)] != 0;
}

// Thêm tam giác khi hai đỉnh kia đã thăm; chỉ số ghi theo thứ tự v0, v2, v1 của buffer gốc.
void add_stored(Work& work, GridPos origin, Wedge wedge) {
    const GridPos first = shift(origin, wedge.first);
    const GridPos second = shift(origin, wedge.second);
    if (!was_visited(work, first) || !was_visited(work, second)) return;
    work.corners.push_back(vertex_index(work.terrain(), origin));
    work.corners.push_back(vertex_index(work.terrain(), second));
    work.corners.push_back(vertex_index(work.terrain(), first));
}

void emit_quadrant(Work& work, GridPos pos, const Quadrant& quadrant) {
    const Corner corner = corner_of(work, pos, quadrant);
    if (corner == Corner::kOutside) return;
    const Wedge whole{.first = quadrant.first, .second = quadrant.second};
    const Wedge leading{.first = quadrant.diagonal, .second = quadrant.second};
    const Wedge trailing{.first = quadrant.first, .second = quadrant.diagonal};
    if (corner == Corner::kApart) {
        add_stored(work, pos, whole);
        return;
    }
    add_stored(work, pos, leading);
    add_stored(work, pos, trailing);
}

void spread_diagonal(Work& work, GridPos pos, const Quadrant& quadrant) {
    if (corner_of(work, pos, quadrant) != Corner::kJoined) return;
    push_neighbor(work, shift(pos, quadrant.diagonal));
}

void spread(Work& work, GridPos pos) {
    if (is_border(work.terrain(), pos) || !under_level(work, pos)) return;
    const int queued = work.visited_count + static_cast<int>(work.pending.size());
    if (queued + 8 >= kVertexLimit) return;
    for (const Step step : kStraight) {
        push_neighbor(work, shift(pos, step));
    }
    for (const Quadrant& quadrant : kQuadrants) {
        spread_diagonal(work, pos, quadrant);
    }
}

void visit(Work& work, GridPos pos) {
    const std::size_t index = vertex_index(work.terrain(), pos);
    if (work.visited[index] != 0) return;
    work.visited[index] = 1;
    ++work.visited_count;
    work.min_column = std::min(work.min_column, pos.column);
    work.min_row = std::min(work.min_row, pos.row);
    // Cùng lúc với gốc: chỉ thêm tam giác khi hai đỉnh kia đã thăm.
    for (const Quadrant& quadrant : kQuadrants) {
        emit_quadrant(work, pos, quadrant);
    }
    spread(work, pos);
}

void seed(Work& work, GridPos cell) {
    for (const Step step : kCellCorners) {
        push_under(work, shift(cell, step));
    }
}

void drain(Work& work) {
    while (!work.pending.empty()) {
        const GridPos pos = work.pending.front();
        work.pending.pop_front();
        visit(work, pos);
    }
}

[[nodiscard]] LiquidPoint point_at(const Work& work, GridPos pos) noexcept {
    const TerrainFile& terrain = work.terrain();
    const LiquidPlace& place = work.field.place;
    const auto along_x = static_cast<float>(pos.column - work.min_column);
    const auto along_z = static_cast<float>(pos.row - work.min_row);
    const float cosine = std::cos(place.texture_rotate);
    const float sine = std::sin(place.texture_rotate);
    LiquidPoint point;
    point.x = terrain.origin.x + (terrain.scale.x * static_cast<float>(pos.column));
    point.y = place.y;
    point.z = terrain.origin.z + (terrain.scale.z * static_cast<float>(pos.row));
    point.u = place.texture_scale * ((along_x * cosine) - (along_z * sine));
    point.v = place.texture_scale * ((along_x * sine) + (along_z * cosine));
    return point;
}

// Mặt đang gói và chỗ mới của từng đỉnh địa hình trong nó.
struct Packing {
    LiquidSheet sheet;
    std::vector<std::uint32_t> remap;
};

void keep_vertex(Packing& packing, const Work& work, std::size_t index) {
    if (work.visited[index] == 0) return;
    const std::size_t stride = static_cast<std::size_t>(work.terrain().x_size) + 1;
    GridPos pos;
    pos.column = static_cast<int>(index % stride);
    pos.row = static_cast<int>(index / stride);
    packing.remap[index] = static_cast<std::uint32_t>(packing.sheet.points.size());
    packing.sheet.points.push_back(point_at(work, pos));
}

[[nodiscard]] LiquidSheet pack(const Work& work) {
    const std::size_t count = work.visited.size();
    Packing packing;
    packing.remap.assign(count, kMissing);
    packing.sheet.points.reserve(static_cast<std::size_t>(work.visited_count));
    for (std::size_t index = 0; index < count; ++index) {
        keep_vertex(packing, work, index);
    }
    packing.sheet.indices.reserve(work.corners.size());
    for (const std::size_t corner : work.corners) {
        packing.sheet.indices.push_back(packing.remap[corner]);
    }
    return std::move(packing.sheet);
}

[[nodiscard]] bool field_ready(const LiquidField& field) noexcept {
    if (field.terrain == nullptr || field.heights == nullptr || field.grid == nullptr) return false;
    const TerrainFile& terrain = *field.terrain;
    const auto& scale = terrain.scale;
    const bool has_scale = scale.x != 0.0F && scale.y != 0.0F && scale.z != 0.0F;
    if (terrain.x_size <= 0 || terrain.z_size <= 0 || !has_scale) return false;
    const bool has_heights = field.heights->samples.size() >= vertex_count(terrain);
    return has_heights && field.grid->cells.size() >= cell_count(terrain);
}

// Ô chứa độ lệch offset (tính bằng ô) dọc một trục có size ô. Chỗ đặt đọc từ tệp cảnh, nên số
// quá lớn hay NaN không được đi vào phép ép sang int: ngoài [-1, size] thì rỗng, mà ô ngoài
// khoảng đó cũng không gieo được đỉnh nào.
[[nodiscard]] std::optional<int> cell_along(float offset, int size) noexcept {
    const float cell = std::floor(offset);
    const bool is_near = cell >= -1.0F && cell <= static_cast<float>(size);
    if (!is_near) return std::nullopt;
    return static_cast<int>(cell);
}

// Ô gieo của mặt nước; rỗng khi field thiếu dữ liệu hoặc chỗ đặt ở xa ngoài bản đồ.
[[nodiscard]] std::optional<GridPos> prepare(Work& work, const LiquidField& field) {
    if (!field_ready(field)) return std::nullopt;
    const TerrainFile& terrain = *field.terrain;
    // Nhân với nghịch đảo như gốc, không chia: hai cách lệch nhau ở bit cuối ngay mép ô.
    const float across = (field.place.x - terrain.origin.x) * (1.0F / terrain.scale.x);
    const float down = (field.place.z - terrain.origin.z) * (1.0F / terrain.scale.z);
    const std::optional<int> column = cell_along(across, terrain.x_size);
    const std::optional<int> row = cell_along(down, terrain.z_size);
    if (!column || !row) return std::nullopt;
    work.field = field;
    work.level = (field.place.y - terrain.origin.y) / terrain.scale.y;
    work.visited.assign(vertex_count(terrain), 0);
    work.touched.assign(vertex_count(terrain), 0);
    work.min_column = terrain.x_size;
    work.min_row = terrain.z_size;
    return GridPos{.column = *column, .row = *row};
}

[[nodiscard]] std::string_view next_line(std::string_view& script) noexcept {
    const std::string_view line = script.substr(0, script.find('\n'));
    script.remove_prefix(std::min(line.size() + 1, script.size()));
    return line;
}

[[nodiscard]] std::string_view trim(std::string_view text) noexcept {
    const std::size_t first = text.find_first_not_of(kBlanks);
    if (first == std::string_view::npos) return {};
    const std::size_t last = text.find_last_not_of(kBlanks);
    return text.substr(first, last - first + 1);
}

[[nodiscard]] std::string_view take_token(std::string_view& text) noexcept {
    text = trim(text);
    std::string_view token = text.substr(0, text.find_first_of(kBlanks));
    text.remove_prefix(token.size());
    if (!token.empty() && token.back() == '{') token.remove_suffix(1);
    return token;
}

void read_anim(LiquidLook& look, std::string_view line) {
    std::string_view rest = line;
    const std::string_view key = take_token(rest);
    if (key != "anim_texture") return;
    look.texture = std::string(take_token(rest));
    const core::OptionalDouble frames = core::parse_double(take_token(rest));
    const core::OptionalDouble duration = core::parse_double(take_token(rest));
    const bool has_frames = frames && frames->value >= 1.0 && frames->value <= kFrameLimit;
    if (has_frames) look.frames = static_cast<int>(frames->value);
    if (duration) look.duration = static_cast<float>(duration->value);
}

void read_scroll(LiquidLook& look, std::string_view line) {
    std::string_view rest = line;
    const std::string_view key = take_token(rest);
    const core::OptionalDouble first = core::parse_double(take_token(rest));
    const core::OptionalDouble second = core::parse_double(take_token(rest));
    if (!first || !second) return;
    const auto along_u = static_cast<float>(first->value);
    const auto along_v = static_cast<float>(second->value);
    if (key == "scroll") {
        look.scroll_u = along_u;
        look.scroll_v = along_v;
    }
    if (key == "scroll_anim") {
        look.speed_u = along_u;
        look.speed_v = along_v;
    }
}

void read_blend(LiquidLook& look, std::string_view line) {
    std::string_view rest = line;
    if (take_token(rest) != "scene_blend") return;
    look.blends = take_token(rest) == "alpha_blend";
}

[[nodiscard]] bool opens_material(std::string_view line, std::string_view name) noexcept {
    std::string_view rest = line;
    if (take_token(rest) != "material") return false;
    return take_token(rest) == name;
}

struct LookScan {
    std::string_view name;
    bool inside = false;
    bool stopped = false;
    LiquidLook look;
};

void take_look_line(LookScan& scan, std::string_view text) {
    if (!scan.inside) {
        scan.inside = opens_material(text, scan.name);
        return;
    }
    if (text.starts_with("material ")) {
        scan.stopped = true;
        return;
    }
    read_anim(scan.look, text);
    read_scroll(scan.look, text);
    read_blend(scan.look, text);
}

} // namespace

LiquidSheet build_liquid(const LiquidField& field) {
    Work work;
    const std::optional<GridPos> cell = prepare(work, field);
    if (!cell) return {};
    seed(work, *cell);
    drain(work);
    if (work.visited_count == 0) return {};
    return pack(work);
}

namespace {

// Dòng chứa vị trí spot, không gồm ký tự xuống dòng.
[[nodiscard]] std::string_view line_around(std::string_view script, std::size_t spot) noexcept {
    const std::size_t before = script.rfind('\n', spot);
    const std::size_t begin = before == std::string_view::npos ? 0 : before + 1;
    const std::size_t end = script.find('\n', spot);
    return script.substr(begin, end == std::string_view::npos ? std::string_view::npos : end - begin);
}

} // namespace

// Tệp script thật dài 21 MB (all.material) và một cảnh có hàng chục mặt nước: đọc từng dòng cả tệp cho mỗi mặt
// tốn ~40 ms một lần (đo 2026-10-13, 11 mặt nước của Đại Lý: 454 ms). Tìm chuỗi tên bằng tìm kiếm nhanh của thư
// viện rồi chỉ đọc dòng chứa nó; kết quả y hệt đọc từ đầu vì vẫn là lần mở material khớp đầu tiên.
LiquidLookResult find_liquid_look(std::string_view script, std::string_view name) {
    LookScan scan;
    scan.name = name;
    std::size_t spot = 0;
    while (!name.empty() && !scan.inside) {
        spot = script.find(name, spot);
        if (spot == std::string_view::npos) break;
        const std::string_view line = line_around(script, spot);
        if (opens_material(trim(line), name)) {
            // Đọc tiếp từ dòng mở material tới hết khối của nó.
            std::string_view rest = script.substr(static_cast<std::size_t>(line.data() - script.data()));
            while (!rest.empty() && !scan.stopped) {
                take_look_line(scan, trim(next_line(rest)));
            }
            break;
        }
        spot += name.size();
    }
    if (!scan.inside || scan.look.texture.empty()) return std::nullopt;
    return scan.look;
}

} // namespace game::client::map
