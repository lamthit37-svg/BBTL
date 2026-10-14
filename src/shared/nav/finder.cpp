// Port PathFinderImpl của PathLib.dll (client 2026). Địa chỉ của từng phần trong bản gốc:
// locate 0x18002c160 (thử điểm trong tam giác 0x1800117f0), giao hai đoạn 0x180031e00, thử các
// cạnh của một ô 0x18002b970, duyệt ô dọc đoạn thẳng 0x18002a580, A* 0x180027db0, né góc và tỉa
// điểm ở cuối 0x1800288d0. Thứ tự phép toán số thực giữ nguyên; phép cộng, nhân đổi chỗ hai vế
// thì kết quả không đổi nên không ghi chú.
// Khác gốc: (1) kéo căng đường viết theo thuật toán phễu chuẩn thay cho bản hai chuỗi của gốc;
// (2) một góc mà ô chứa nó liệt kê chưa đủ hai cạnh ràng buộc của nó, bản gốc dùng lại giá trị
// của góc trước, và ở góc đầu tiên thì đọc ngăn xếp chưa khởi tạo: ở đây góc đầu tiên như vậy
// không né; (3) góc không né được ở bán kính nào thì bản gốc đổi sang một thuật toán dự phòng
// (0x18002cd60, chưa port): ở đây góc đó giữ nguyên chỗ đỉnh; (4) vùng cấm động chưa có.
#include "nav/finder.hpp"

#include "nav/mesh.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::nav {
namespace {

// Dung sai "bằng 0" của phép thử điểm trong tam giác, và ngưỡng coi hai đoạn là song song.
constexpr float kTouch = 9.99999997e-07F;
constexpr float kParallel = 1.1920929e-07F;
// Bán kính né góc (PathFinderImpl +0xf0) và độ dài dưới đó một vector không được chuẩn hoá.
constexpr float kRadius = 0.1F;
constexpr double kShortest = 1e-08;
constexpr float kHalf = 0.5F;

constexpr std::uint8_t kFresh = 0;
constexpr std::uint8_t kQueued = 1;
constexpr std::uint8_t kClosed = 2;

struct GridPos {
    int column = 0;
    int row = 0;

    friend constexpr bool operator==(const GridPos&, const GridPos&) = default;
};

struct Line {
    Point from;
    Point to;
};

struct Corners {
    Point first;
    Point second;
    Point third;
};

[[nodiscard]] bool is_cell(const Mesh& mesh, GridPos cell) noexcept {
    const bool is_in_columns = cell.column >= 0 && std::cmp_less(cell.column, mesh.columns);
    return is_in_columns && cell.row >= 0 && std::cmp_less(cell.row, mesh.rows);
}

// Ô chứa điểm: phần nguyên của toạ độ chia cỡ ô, cắt về 0 như bản gốc (nên toạ độ trong (-cỡ ô,
// 0) vẫn rơi vào ô 0). Rỗng khi ngoài lưới; NaN cũng ra rỗng.
[[nodiscard]] std::optional<GridPos> cell_of(const Mesh& mesh, Point point) noexcept {
    const auto size = static_cast<float>(mesh.cell_size);
    const float across = point.x / size;
    const float down = point.z / size;
    const bool is_in_columns = across > -1.0F && across < static_cast<float>(mesh.columns);
    const bool is_in_rows = down > -1.0F && down < static_cast<float>(mesh.rows);
    if (!is_in_columns || !is_in_rows) return std::nullopt;
    GridPos cell;
    cell.column = static_cast<int>(across);
    cell.row = static_cast<int>(down);
    return cell;
}

// Tiền điều kiện: is_cell(mesh, cell).
[[nodiscard]] const Cell& cell_at(const Mesh& mesh, GridPos cell) noexcept {
    const auto row = static_cast<std::size_t>(cell.row);
    const auto column = static_cast<std::size_t>(cell.column);
    return mesh.cells[(row * mesh.columns) + column];
}

[[nodiscard]] Corners corners_of(const Mesh& mesh, const Triangle& triangle) noexcept {
    Corners corners;
    corners.first = mesh.vertices[triangle.corners[0]];
    corners.second = mesh.vertices[triangle.corners[1]];
    corners.third = mesh.vertices[triangle.corners[2]];
    return corners;
}

// Điểm nằm bên nào của đường thẳng: dương, âm, hoặc coi như nằm trên đường.
struct Lean {
    bool is_touching = false;
    int sign = 0;

    [[nodiscard]] bool opposes(const Lean& other) const noexcept {
        return !is_touching && !other.is_touching && sign != other.sign;
    }
};

[[nodiscard]] Lean lean_of(const Line& line, Point point) noexcept {
    const float across = (point.z - line.from.z) * (line.to.x - line.from.x);
    const float along = (point.x - line.from.x) * (line.to.z - line.from.z);
    const float side = across - along;
    Lean lean;
    lean.is_touching = kTouch >= std::fabs(0.0F - side);
    if (side > 0.0F) lean.sign = 1;
    if (0.0F > side) lean.sign = -1;
    return lean;
}

// 0x1800117f0: điểm ở cùng một bên của cả ba cạnh; cạnh mà điểm coi như nằm trên thì bỏ qua.
[[nodiscard]] bool contains(const Corners& corners, Point point) noexcept {
    const Line first{.from = corners.first, .to = corners.second};
    const Line second{.from = corners.second, .to = corners.third};
    const Line third{.from = corners.third, .to = corners.first};
    const Lean one = lean_of(first, point);
    const Lean two = lean_of(second, point);
    const Lean three = lean_of(third, point);
    return !one.opposes(two) && !one.opposes(three) && !two.opposes(three);
}

// 0x180031e00: giao điểm của đoạn với một cạnh, kể cả chạm đầu mút; rỗng khi gần song song.
[[nodiscard]] std::optional<Point> meet(const Segment& segment, const Line& wall) noexcept {
    const float run_x = segment.end.x - segment.start.x;
    const float run_z = segment.end.z - segment.start.z;
    const float wall_x = wall.to.x - wall.from.x;
    const float wall_z = wall.to.z - wall.from.z;
    const float denominator = (wall_z * run_x) - (run_z * wall_x);
    if (kParallel >= std::fabs(0.0F - denominator)) return std::nullopt;
    const float gap_z = segment.start.z - wall.from.z;
    const float gap_x = segment.start.x - wall.from.x;
    const float along = ((wall_x * gap_z) - (wall_z * gap_x)) / denominator;
    const float across = ((run_x * gap_z) - (run_z * gap_x)) / denominator;
    const bool is_on_segment = along >= 0.0F && 1.0F >= along;
    if (!is_on_segment || !(across >= 0.0F) || !(1.0F >= across)) return std::nullopt;
    Point hit;
    hit.x = (run_x * along) + segment.start.x;
    hit.z = (run_z * along) + segment.start.z;
    return hit;
}

[[nodiscard]] float length_squared(const Segment& segment) noexcept {
    const float across = segment.start.x - segment.end.x;
    const float down = segment.start.z - segment.end.z;
    return (across * across) + (down * down);
}

[[nodiscard]] float length(const Segment& segment) noexcept {
    return std::sqrt(length_squared(segment));
}

// Cờ của tam giác vật cản bên cạnh; tam giác thứ hai thắng khi cả hai là vật cản.
[[nodiscard]] std::uint8_t wall_flags(const Mesh& mesh, const Edge& edge) noexcept {
    std::uint8_t flags = 0;
    const std::array<std::uint32_t, 2> sides{edge.wall, edge.open};
    for (const std::uint32_t side : sides) {
        const bool is_wall = side != kNone && mesh.triangles[side].is_obstacle();
        flags = is_wall ? mesh.triangles[side].flags : flags;
    }
    return flags;
}

// Bước đi qua các ô dọc đoạn thẳng: trục chính đi từng ô, trục phụ cộng dần độ dốc.
struct Stride {
    bool is_x_major = false;
    float slope = 0.0F;
    float minor = 0.0F;
    int low = 0;
    int high = 0;
};

struct CellSpan {
    GridPos first;
    GridPos last;
};

[[nodiscard]] Stride stride_of(const CellSpan& span) noexcept {
    const auto run_x = static_cast<float>(span.last.column - span.first.column);
    const auto run_z = static_cast<float>(span.last.row - span.first.row);
    const float wide = std::fabs(run_x);
    const float tall = std::fabs(run_z);
    Stride stride;
    stride.is_x_major = wide > tall;
    stride.slope = tall > wide ? run_x / run_z : run_z / run_x;
    const bool is_forward_x = span.last.column > span.first.column;
    const bool is_forward_z = span.last.row > span.first.row;
    const int minor_x = is_forward_z ? span.first.column : span.last.column;
    const int minor_z = is_forward_x ? span.first.row : span.last.row;
    stride.minor = static_cast<float>(stride.is_x_major ? minor_z : minor_x);
    const auto columns = std::minmax(span.first.column, span.last.column);
    const auto rows = std::minmax(span.first.row, span.last.row);
    stride.low = stride.is_x_major ? columns.first : rows.first;
    stride.high = stride.is_x_major ? columns.second : rows.second;
    return stride;
}

// Gom chỗ cắt của một đoạn với cạnh ràng buộc của các ô nó đi qua (0x18002a580).
class Sweep {
public:
    Sweep(const Mesh& mesh, const Segment& segment) noexcept : mesh_(&mesh), segment_(segment) {}

    void run(const CellSpan& span);
    [[nodiscard]] std::vector<Crossing> take() noexcept { return std::move(found_); }

private:
    void test_cell(GridPos cell);
    void test_edge(std::uint32_t id);
    void keep(const Crossing& crossing);
    void test_column(int column, std::pair<int, int> rows);
    void test_row(int row, std::pair<int, int> columns);
    void step(Stride& stride, int major);

    const Mesh* mesh_;
    Segment segment_;
    std::vector<Crossing> found_;
};

// Hai chỗ cùng khoảng cách: giữ chỗ gặp trước, như std::set của bản gốc từ chối khoá trùng.
void Sweep::keep(const Crossing& crossing) {
    const float key = crossing.distance_squared;
    const auto after = std::ranges::lower_bound(found_, key, {}, &Crossing::distance_squared);
    const bool is_new = after == found_.end() || key < after->distance_squared;
    if (is_new) found_.insert(after, crossing);
}

void Sweep::test_edge(std::uint32_t id) {
    const Edge& edge = mesh_->edges[id];
    const Line wall{.from = mesh_->vertices[edge.first], .to = mesh_->vertices[edge.second]};
    const std::optional<Point> hit = meet(segment_, wall);
    if (!hit) return;
    const Segment reach{.start = segment_.start, .end = *hit};
    Crossing crossing;
    crossing.distance_squared = length_squared(reach);
    crossing.flags = wall_flags(*mesh_, edge);
    crossing.at = *hit;
    keep(crossing);
}

void Sweep::test_cell(GridPos cell) {
    if (!is_cell(*mesh_, cell)) return;
    for (const std::uint32_t id : mesh_->edges_of(cell_at(*mesh_, cell))) {
        test_edge(id);
    }
}

void Sweep::test_column(int column, std::pair<int, int> rows) {
    for (int row = rows.first; row <= rows.second; ++row) {
        test_cell(GridPos{.column = column, .row = row});
    }
}

void Sweep::test_row(int row, std::pair<int, int> columns) {
    for (int column = columns.first; column <= columns.second; ++column) {
        test_cell(GridPos{.column = column, .row = row});
    }
}

// Một ô của trục chính: ô ở giữa và hai ô kề theo trục phụ. minor luôn hữu hạn ở đây: độ dốc chỉ
// là NaN khi hai đầu cùng một ô, mà khi đó vòng lặp chỉ chạy đúng một lần trước phép cộng.
void Sweep::step(Stride& stride, int major) {
    const auto rounded = static_cast<int>(std::floor(stride.minor + kHalf));
    const int column = stride.is_x_major ? major : rounded;
    const int row = stride.is_x_major ? rounded : major;
    const int side_x = stride.is_x_major ? 0 : 1;
    const int side_z = stride.is_x_major ? 1 : 0;
    test_cell(GridPos{.column = column, .row = row});
    test_cell(GridPos{.column = column - side_x, .row = row - side_z});
    test_cell(GridPos{.column = column + side_x, .row = row + side_z});
    stride.minor += stride.slope;
}

// Thứ tự thử ô theo bản gốc (quyết định chỗ nào được giữ khi hai chỗ cắt cùng khoảng cách): cùng
// ô, cùng cột, cùng hàng, rồi mới đi theo trục chính.
void Sweep::run(const CellSpan& span) {
    const auto columns = std::minmax(span.first.column, span.last.column);
    const auto rows = std::minmax(span.first.row, span.last.row);
    if (span.first == span.last) test_cell(span.first);
    if (span.first.column == span.last.column) test_column(span.first.column, rows);
    if (span.first.row == span.last.row) test_row(span.first.row, columns);
    Stride stride = stride_of(span);
    for (int major = stride.low; major <= stride.high; ++major) {
        step(stride, major);
    }
}

// Cửa giữa hai tam giác kề nhau: hai đỉnh chung, theo thứ tự đỉnh của tam giác đang rời.
struct Gate {
    std::uint32_t first = kNone;
    std::uint32_t second = kNone;
};

[[nodiscard]] std::optional<Gate> gate_between(const Triangle& from, const Triangle& into) {
    const auto is_shared = [&into](std::uint32_t corner) {
        return std::ranges::find(into.corners, corner) != into.corners.end();
    };
    const auto first = std::ranges::find_if(from.corners, is_shared);
    if (first == from.corners.end()) return std::nullopt;
    const auto second = std::find_if(std::next(first), from.corners.end(), is_shared);
    if (second == from.corners.end()) return std::nullopt;
    return Gate{.first = *first, .second = *second};
}

[[nodiscard]] Point middle_of(const Mesh& mesh, const Gate& gate) noexcept {
    const Point first = mesh.vertices[gate.first];
    const Point second = mesh.vertices[gate.second];
    Point middle;
    middle.x = (second.x + first.x) * kHalf;
    middle.z = (second.z + first.z) * kHalf;
    return middle;
}

// Tam giác chứa điểm đầu và tam giác chứa đích.
struct Ends {
    std::uint32_t start = 0;
    std::uint32_t goal = 0;
};

// A* trên tam giác đi được (0x180027db0). Chi phí tới một tam giác là quãng từ điểm vào tam giác
// trước tới trung điểm cạnh chung; ước lượng là khoảng cách từ trọng tâm tới đích. Hàng đợi là
// đống nhị phân viết tay của bản gốc: thứ tự gỡ hoà quyết định hành lang nên giữ nguyên từng
// phép so.
class Search {
public:
    Search(const Mesh& mesh, Scratch& scratch, Point goal) noexcept : mesh_(&mesh), scratch_(&scratch), goal_(goal) {}

    // true khi tới được; trail của scratch khi đó là dãy tam giác từ đầu tới đích.
    [[nodiscard]] bool run(const Ends& ends, Point from);

private:
    [[nodiscard]] float score(std::uint32_t id) const noexcept { return scratch_->walked[id] + scratch_->ahead[id]; }
    [[nodiscard]] std::size_t lighter_child(std::size_t index) const noexcept;
    void sink_front() noexcept;
    void rise(std::size_t index) noexcept;
    void expand();
    void relax(std::uint32_t neighbour);
    void open(std::uint32_t id);
    void trace(const Ends& ends);

    const Mesh* mesh_;
    Scratch* scratch_;
    Point goal_;
    // Tam giác đang được mở rộng.
    std::uint32_t current_ = 0;
};

std::size_t Search::lighter_child(std::size_t index) const noexcept {
    const std::vector<std::uint32_t>& heap = scratch_->heap;
    const std::size_t left = (index * 2) + 1;
    const std::size_t right = left + 1;
    if (left >= heap.size()) return index;
    std::size_t best = index;
    if (score(heap[index]) >= score(heap[left])) best = left;
    if (right < heap.size() && score(heap[best]) >= score(heap[right])) best = right;
    return best;
}

void Search::sink_front() noexcept {
    std::vector<std::uint32_t>& heap = scratch_->heap;
    std::size_t index = 0;
    std::size_t best = lighter_child(index);
    while (best != index) {
        std::swap(heap[index], heap[best]);
        index = best;
        best = lighter_child(index);
    }
}

void Search::rise(std::size_t index) noexcept {
    std::vector<std::uint32_t>& heap = scratch_->heap;
    while (index != 0 && score(heap[(index - 1) / 2]) >= score(heap[index])) {
        std::swap(heap[(index - 1) / 2], heap[index]);
        index = (index - 1) / 2;
    }
}

void Search::open(std::uint32_t id) {
    const Segment remaining{.start = mesh_->triangles[id].centre, .end = goal_};
    scratch_->parent[id] = current_;
    scratch_->ahead[id] = length(remaining);
    scratch_->state[id] = kQueued;
    scratch_->heap.push_back(id);
    rise(scratch_->heap.size() - 1);
}

// Tam giác đã đóng mà gặp đường ngắn hơn thì chỉ sửa số, không mở lại, như bản gốc.
void Search::relax(std::uint32_t neighbour) {
    if (neighbour == kNone || mesh_->triangles[neighbour].is_obstacle()) return;
    const Triangle& leaving = mesh_->triangles[current_];
    const std::optional<Gate> gate = gate_between(leaving, mesh_->triangles[neighbour]);
    if (!gate) return;
    const Point door = middle_of(*mesh_, *gate);
    const Segment hop{.start = door, .end = scratch_->entry[current_]};
    const float cost = length(hop) + scratch_->walked[current_];
    const std::uint8_t state = scratch_->state[neighbour];
    if (state != kFresh && !(scratch_->walked[neighbour] > cost)) return;
    scratch_->walked[neighbour] = cost;
    scratch_->entry[neighbour] = door;
    if (state == kFresh) {
        open(neighbour);
        return;
    }
    scratch_->parent[neighbour] = current_;
    if (state == kClosed) return;
    const auto queued = std::ranges::find(scratch_->heap, neighbour);
    rise(static_cast<std::size_t>(std::distance(scratch_->heap.begin(), queued)));
}

void Search::expand() {
    current_ = scratch_->heap.front();
    scratch_->heap.front() = scratch_->heap.back();
    scratch_->heap.pop_back();
    sink_front();
    scratch_->state[current_] = kClosed;
    for (const std::uint32_t neighbour : mesh_->triangles[current_].neighbours) {
        relax(neighbour);
    }
}

void Search::trace(const Ends& ends) {
    std::vector<std::uint32_t>& trail = scratch_->trail;
    trail.assign(1, ends.goal);
    std::uint32_t walker = scratch_->parent[ends.goal];
    while (walker != ends.start) {
        trail.push_back(walker);
        walker = scratch_->parent[walker];
    }
    trail.push_back(ends.start);
    std::ranges::reverse(trail);
}

bool Search::run(const Ends& ends, Point from) {
    const std::size_t count = mesh_->triangles.size();
    scratch_->parent.assign(count, 0);
    scratch_->walked.assign(count, 0.0F);
    scratch_->ahead.assign(count, 0.0F);
    scratch_->state.assign(count, kFresh);
    scratch_->entry.assign(count, Point{});
    scratch_->heap.assign(1, ends.start);
    scratch_->state[ends.start] = kQueued;
    scratch_->entry[ends.start] = from;
    while (!scratch_->heap.empty() && scratch_->heap.front() != ends.goal) {
        expand();
    }
    if (scratch_->heap.empty()) return false;
    trace(ends);
    return true;
}

// Cửa nhìn theo chiều đi: đỉnh bên trái, đỉnh bên phải.
struct Portal {
    Point left;
    Point right;
    std::uint32_t left_id = kNone;
    std::uint32_t right_id = kNone;
};

using Portals = std::vector<Portal>;
// Dãy tam giác từ đầu tới đích.
using Trail = std::span<const std::uint32_t>;

// Dương khi probe lệch về bên phải của đường from → to (toạ độ game, nhìn từ trên xuống).
[[nodiscard]] float turn(const Line& line, Point probe) noexcept {
    const float reach = (probe.x - line.from.x) * (line.to.z - line.from.z);
    const float drift = (line.to.x - line.from.x) * (probe.z - line.from.z);
    return reach - drift;
}

[[nodiscard]] std::optional<Portal> portal_at(const Mesh& mesh, Trail trail, std::size_t index) {
    const Triangle& leaving = mesh.triangles[trail[index]];
    const std::optional<Gate> gate = gate_between(leaving, mesh.triangles[trail[index + 1]]);
    if (!gate) return std::nullopt;
    const auto is_behind = [&gate](std::uint32_t corner) { return corner != gate->first && corner != gate->second; };
    const auto behind = std::ranges::find_if(leaving.corners, is_behind);
    if (behind == leaving.corners.end()) return std::nullopt;
    const Line door{.from = mesh.vertices[gate->first], .to = mesh.vertices[gate->second]};
    const bool is_flipped = turn(door, mesh.vertices[*behind]) < 0.0F;
    Portal portal;
    portal.left_id = is_flipped ? gate->second : gate->first;
    portal.right_id = is_flipped ? gate->first : gate->second;
    portal.left = mesh.vertices[portal.left_id];
    portal.right = mesh.vertices[portal.right_id];
    return portal;
}

// Kéo căng đường qua dãy cửa (thuật toán phễu): ra chỉ số các đỉnh mà đường phải rẽ quanh.
class Funnel {
public:
    // Tiền điều kiện: portals không rỗng; cửa đầu là điểm xuất phát (hai đỉnh trùng nhau).
    explicit Funnel(std::span<const Portal> portals) noexcept;

    [[nodiscard]] std::vector<std::uint32_t> run();

private:
    struct Side {
        Point at;
        std::uint32_t id = kNone;
        std::size_t index = 0;
    };

    [[nodiscard]] bool narrows_right(const Portal& portal);
    [[nodiscard]] bool narrows_left(const Portal& portal);
    void turn_at(const Side& corner);

    std::span<const Portal> portals_;
    Point apex_;
    Side left_;
    Side right_;
    std::size_t index_ = 1;
    std::vector<std::uint32_t> corners_;
};

Funnel::Funnel(std::span<const Portal> portals) noexcept
    : portals_(portals), apex_(portals.front().left), left_{.at = apex_}, right_{.at = apex_} {}

// Đường phải rẽ ở corner: nó thành đỉnh phễu mới, và duyệt lại từ cửa ngay sau nó.
void Funnel::turn_at(const Side& corner) {
    const bool is_repeat = !corners_.empty() && corners_.back() == corner.id;
    if (corner.id != kNone && !is_repeat) corners_.push_back(corner.id);
    apex_ = corner.at;
    index_ = corner.index + 1;
    left_ = corner;
    right_ = corner;
}

// true khi phễu vừa đổi đỉnh (cạnh phải vượt qua cạnh trái).
bool Funnel::narrows_right(const Portal& portal) {
    const Line to_right{.from = apex_, .to = right_.at};
    if (!(turn(to_right, portal.right) <= 0.0F)) return false;
    const Line to_left{.from = apex_, .to = left_.at};
    const bool is_inside = apex_ == right_.at || turn(to_left, portal.right) > 0.0F;
    if (!is_inside) {
        turn_at(left_);
        return true;
    }
    right_ = Side{.at = portal.right, .id = portal.right_id, .index = index_};
    return false;
}

bool Funnel::narrows_left(const Portal& portal) {
    const Line to_left{.from = apex_, .to = left_.at};
    if (!(turn(to_left, portal.left) >= 0.0F)) return false;
    const Line to_right{.from = apex_, .to = right_.at};
    const bool is_inside = apex_ == left_.at || turn(to_right, portal.left) < 0.0F;
    if (!is_inside) {
        turn_at(right_);
        return true;
    }
    left_ = Side{.at = portal.left, .id = portal.left_id, .index = index_};
    return false;
}

std::vector<std::uint32_t> Funnel::run() {
    while (index_ < portals_.size()) {
        const Portal& portal = portals_[index_];
        const bool has_turned = narrows_right(portal) || narrows_left(portal);
        index_ += has_turned ? 0 : 1;
    }
    return std::move(corners_);
}

[[nodiscard]] Point unit(Point vector) noexcept {
    const float size = std::sqrt((vector.x * vector.x) + (vector.z * vector.z));
    if (!(static_cast<double>(size) > kShortest)) return vector;
    const float scale = 1.0F / size;
    return Point{.x = vector.x * scale, .z = vector.z * scale};
}

// Dời điểm rẽ khỏi đỉnh vật cản 0,1 theo phân giác ngoài của hai cạnh ràng buộc tại đỉnh; điểm
// dời rơi vào vật cản thì thử nửa quãng, rồi một phần tư... Hai đỉnh kề được nhớ từ góc này sang
// góc sau, như hai thanh ghi của bản gốc: ô của một đỉnh không phải lúc nào cũng liệt kê đủ cạnh
// của nó.
class Rounder {
public:
    Rounder(const Mesh& mesh, Point first_side) noexcept : mesh_(&mesh), near_(first_side) {}

    [[nodiscard]] Point round(std::uint32_t vertex);

private:
    void note(const Edge& edge, Point here) noexcept;
    void scan(Point here) noexcept;
    [[nodiscard]] Point outward(Point here) const noexcept;

    const Mesh* mesh_;
    Point near_;
    Point far_;
    bool has_far_ = false;
    bool is_first_ = true;
};

void Rounder::note(const Edge& edge, Point here) noexcept {
    const Point head = mesh_->vertices[edge.first];
    const Point tail = mesh_->vertices[edge.second];
    if (head != here && tail != here) return;
    const Point other = head == here ? tail : head;
    if (is_first_) {
        near_ = other;
        is_first_ = false;
        return;
    }
    far_ = other;
    has_far_ = true;
}

void Rounder::scan(Point here) noexcept {
    is_first_ = true;
    const std::optional<GridPos> cell = cell_of(*mesh_, here);
    if (!cell) return;
    for (const std::uint32_t id : mesh_->edges_of(cell_at(*mesh_, *cell))) {
        note(mesh_->edges[id], here);
    }
}

[[nodiscard]] Point Rounder::outward(Point here) const noexcept {
    const Point first = unit(Point{.x = near_.x - here.x, .z = near_.z - here.z});
    const Point second = unit(Point{.x = far_.x - here.x, .z = far_.z - here.z});
    Point between;
    between.x = (second.x + first.x) * kHalf;
    between.z = (second.z + first.z) * kHalf;
    return unit(between);
}

Point Rounder::round(std::uint32_t vertex) {
    const Point here = mesh_->vertices[vertex];
    scan(here);
    if (!has_far_) return here;
    const Point normal = outward(here);
    const float push_x = normal.x * kRadius;
    const float push_z = normal.z * kRadius;
    Point moved{.x = here.x - push_x, .z = here.z - push_z};
    float scale = kHalf;
    while (scale != 0.0F && locate(*mesh_, moved, Ground::kObstacle)) {
        moved.z = here.z - (scale * push_z);
        moved.x = here.x - (scale * push_x);
        scale *= kHalf;
    }
    return scale == 0.0F ? here : moved;
}

// Điểm xa nhất kể từ next mà from nhìn thấy; không thấy điểm nào thì chính next.
[[nodiscard]] std::size_t farthest_seen(const Mesh& mesh, const Path& path, std::size_t from) {
    std::size_t reach = path.size() - 1;
    const auto is_hidden = [&](std::size_t index) {
        const Segment sight{.start = path[from], .end = path[index]};
        return !sees(mesh, sight);
    };
    while (reach > from + 1 && is_hidden(reach)) {
        --reach;
    }
    return reach;
}

// Tỉa điểm ở cuối 0x1800288d0: từ mỗi điểm giữ lại, nhảy tới điểm xa nhất còn nhìn thấy.
void prune(const Mesh& mesh, Path& path) {
    if (path.size() < 3) return;
    Path kept{path.front()};
    std::size_t from = 0;
    while (from + 1 < path.size()) {
        from = farthest_seen(mesh, path, from);
        kept.push_back(path[from]);
    }
    path = std::move(kept);
}

// Cửa đầu và cửa cuối là chính điểm đầu và điểm cuối của đường.
[[nodiscard]] Portals portals_along(const Mesh& mesh, Trail trail, const Segment& segment) {
    Portals portals;
    portals.reserve(trail.size() + 1);
    portals.push_back(Portal{.left = segment.start, .right = segment.start});
    bool is_whole = true;
    for (std::size_t index = 0; index + 1 < trail.size() && is_whole; ++index) {
        const std::optional<Portal> portal = portal_at(mesh, trail, index);
        is_whole = portal.has_value();
        portals.push_back(portal.value_or(Portal{}));
    }
    portals.push_back(Portal{.left = segment.end, .right = segment.end});
    return is_whole ? portals : Portals{};
}

[[nodiscard]] std::optional<Path> pulled_path(const Mesh& mesh, const Segment& segment, Trail trail) {
    const Portals portals = portals_along(mesh, trail, segment);
    if (portals.empty()) return std::nullopt;
    Funnel funnel(portals);
    const std::vector<std::uint32_t> corners = funnel.run();
    // Đỉnh kề ban đầu của bản gốc: đỉnh chung thứ hai của cửa đầu tiên, theo thứ tự đỉnh của tam
    // giác xuất phát.
    const Triangle& first = mesh.triangles[trail[0]];
    const std::optional<Gate> gate = gate_between(first, mesh.triangles[trail[1]]);
    if (!gate) return std::nullopt;
    Rounder rounder(mesh, mesh.vertices[gate->second]);
    Path path{segment.start};
    for (const std::uint32_t corner : corners) {
        path.push_back(rounder.round(corner));
    }
    path.push_back(segment.end);
    prune(mesh, path);
    return path;
}

} // namespace

std::optional<std::uint32_t> locate(const Mesh& mesh, Point point, Ground ground) noexcept {
    const std::optional<GridPos> cell = cell_of(mesh, point);
    if (!cell) return std::nullopt;
    const bool wants_obstacle = ground == Ground::kObstacle;
    const auto holds = [&](std::uint32_t id) {
        const Triangle& triangle = mesh.triangles[id];
        const bool is_wanted = triangle.is_obstacle() == wants_obstacle;
        return is_wanted && contains(corners_of(mesh, triangle), point);
    };
    const std::span<const std::uint32_t> listed = mesh.triangles_of(cell_at(mesh, *cell));
    const auto found = std::ranges::find_if(listed, holds);
    if (found == listed.end()) return std::nullopt;
    return *found;
}

std::optional<std::vector<Crossing>> crossings(const Mesh& mesh, const Segment& segment) {
    const std::optional<GridPos> first = cell_of(mesh, segment.start);
    const std::optional<GridPos> last = cell_of(mesh, segment.end);
    if (!first || !last) return std::nullopt;
    Sweep sweep(mesh, segment);
    sweep.run(CellSpan{.first = *first, .last = *last});
    return sweep.take();
}

bool sees(const Mesh& mesh, const Segment& segment) {
    const std::optional<std::vector<Crossing>> found = crossings(mesh, segment);
    return found && found->empty();
}

std::optional<Path> find_path(const Mesh& mesh, const Segment& segment, Scratch& scratch) {
    const std::optional<std::uint32_t> first = locate(mesh, segment.start, Ground::kOpen);
    const std::optional<std::uint32_t> last = locate(mesh, segment.end, Ground::kOpen);
    if (!first || !last) return std::nullopt;
    if (mesh.triangles[*first].island != mesh.triangles[*last].island) return std::nullopt;
    const bool is_same_triangle = *first == *last;
    if (is_same_triangle && segment.start == segment.end) return std::nullopt;
    if (is_same_triangle || sees(mesh, segment)) return Path{segment.start, segment.end};
    Search search(mesh, scratch, segment.end);
    const Ends ends{.start = *first, .goal = *last};
    if (!search.run(ends, segment.start)) return std::nullopt;
    return pulled_path(mesh, segment, scratch.trail);
}

} // namespace game::nav
