// CPath và CAI_MySelf của Game.exe (client 2026) trên lưới đi. Phép chuẩn hoá vector là
// fVector2::normalise của tEngine.dll (0x18000d3e0): căn nghịch đảo nhanh kiểu Quake với một
// bước Newton, giữ nguyên để điểm lùi trùng từng bit.
#include "nav/route.hpp"

#include "nav/finder.hpp"
#include "nav/mesh.hpp"

#include <bit>
#include <cmath>
#include <cstdint>
#include <optional>
#include <utility>
#include <vector>

namespace game::nav {
namespace {

// Lùi lại chừng này trước cạnh vật cản, và quãng đi thẳng ngắn nhất (bình phương) còn được nhận.
constexpr float kBackOff = 0.100000001F;
constexpr float kShortestWalkSquared = 2.0F;
constexpr std::uint32_t kQuakeMagic = 0x5f3759dfU;

// fVector2::normalise(1.0): vector nhân với xấp xỉ của 1 / độ dài.
[[nodiscard]] Point quick_unit(Point vector) noexcept {
    const float squared = (vector.x * vector.x) + (vector.z * vector.z);
    const float half = squared * 0.5F;
    const std::uint32_t guess = kQuakeMagic - (std::bit_cast<std::uint32_t>(squared) >> 1U);
    const auto rough = std::bit_cast<float>(guess);
    const float scale = (1.5F - ((half * rough) * rough)) * rough;
    return Point{.x = vector.x * scale, .z = vector.z * scale};
}

// TDU_GetDistSq rồi phép so với 2,0 ở cuối GetPathDirect: quãng ngắn hơn căn 2 thì không đi.
[[nodiscard]] std::optional<Point> worth_walking(const Segment& hop) noexcept {
    const float across = hop.start.x - hop.end.x;
    const float down = hop.start.z - hop.end.z;
    if (kShortestWalkSquared > (across * across) + (down * down)) return std::nullopt;
    return hop.end;
}

// CreateMovePath: các đoạn đi nối điểm liền nhau, nên điểm phải tới là mọi điểm sau điểm đầu.
[[nodiscard]] Path without_start(Path route) {
    if (route.size() < 2) return {};
    route.erase(route.begin());
    return route;
}

} // namespace

Field::Field(Mesh mesh, Area area) noexcept : mesh_(std::move(mesh)), area_(area) {}

bool Field::is_inside(Point point) const noexcept {
    if (std::isnan(point.x) || std::isnan(point.z)) return false;
    const bool is_in_width = !(0.0F > point.x) && !(point.x > area_.width);
    return is_in_width && !(0.0F > point.z) && !(point.z > area_.depth);
}

bool Field::is_unreachable(Point point) const noexcept {
    if (!is_inside(point)) return true;
    return locate(mesh_, point, Ground::kObstacle).has_value();
}

// hit.start là chỗ đang đứng, hit.end là chỗ cắt cạnh: lùi 0,1 về phía chỗ đứng, trừ khi điểm lùi
// vẫn nằm trong vật cản.
Point Field::backed_off(const Segment& hit) const noexcept {
    const Point back{.x = hit.start.x - hit.end.x, .z = hit.start.z - hit.end.z};
    const Point toward = quick_unit(back);
    Point eased;
    eased.x = (toward.x * kBackOff) + hit.end.x;
    eased.z = (toward.z * kBackOff) + hit.end.z;
    const bool is_in_wall = locate(mesh_, eased, Ground::kObstacle).has_value();
    return is_in_wall ? hit.end : eased;
}

// Đi từ trong vật cản ra chỗ đi được thì không lùi và không xét quãng ngắn, như bản gốc.
std::optional<Point> Field::straight_stop(const Segment& walk) const {
    if (!is_inside(walk.start) || !is_inside(walk.end)) return std::nullopt;
    const std::optional<std::vector<Crossing>> found = crossings(mesh_, walk);
    if (!found) return std::nullopt;
    const bool starts_in_wall = locate(mesh_, walk.start, Ground::kObstacle).has_value();
    const bool is_escape = starts_in_wall && locate(mesh_, walk.end, Ground::kOpen).has_value();
    if (is_escape && found->size() > 1) return std::nullopt;
    if (is_escape) return walk.end;
    if (found->empty()) return worth_walking(walk);
    const Segment hit{.start = walk.start, .end = found->front().at};
    const Segment eased{.start = walk.start, .end = backed_off(hit)};
    return worth_walking(eased);
}

Point Field::step_reach(const Segment& walk) const {
    if (!is_inside(walk.end)) return walk.start;
    const bool ends_in_wall = locate(mesh_, walk.end, Ground::kObstacle).has_value();
    const bool starts_in_wall = locate(mesh_, walk.start, Ground::kObstacle).has_value();
    if (starts_in_wall || ends_in_wall) return ends_in_wall ? walk.start : walk.end;
    const std::optional<std::vector<Crossing>> found = crossings(mesh_, walk);
    if (!found) return walk.start;
    if (found->empty()) return walk.end;
    const Segment hit{.start = walk.start, .end = found->front().at};
    return backed_off(hit);
}

Path Field::straight_path(const Segment& walk) const {
    const std::optional<Point> stop = straight_stop(walk);
    if (!stop) return {};
    return Path{*stop};
}

// 0x1406199b0, nhánh không bay. Tìm được đường mà đường không có đoạn nào thì lệnh bị từ chối,
// không quay sang đi thẳng.
Path Field::plan_move(const MoveAsk& ask, Scratch& scratch) const {
    const Segment& walk = ask.walk;
    if (!is_inside(walk.end)) return {};
    const bool is_stuck = is_unreachable(walk.start);
    if (ask.mode == MoveMode::kStraight) return is_stuck ? Path{} : straight_path(walk);
    const bool can_escape = is_stuck && !is_unreachable(walk.end);
    if (can_escape) return straight_path(walk);
    std::optional<Path> route;
    if (is_inside(walk.start)) route = find_path(mesh_, walk, scratch);
    if (route) return without_start(std::move(*route));
    if (is_stuck) return {};
    return straight_path(walk);
}

} // namespace game::nav
