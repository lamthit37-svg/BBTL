/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/bullet.cpp
 *  PHÂN HỆ   : Figure / Look / Bullet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Một bước bay của đạn và bộ đọc hai bảng.
 *  - Khác gốc: cung có đoạn xuất phát dài 0 thì không cộng độ nâng (gốc chia 0).
 *    Độ nâng không lấy từ cột reserved của Bullet.txt (mẫu cung đang là 0).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "look/bullet.hpp"

#include "look/detail/rows.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::look {
namespace {

constexpr std::uint32_t kMaxId = 2'000'000'000;
constexpr double kPi = 3.1415926535;
constexpr std::array<std::string_view, 8> kBulletColumns{"id", "trajectory", "speed",
    "flight_effect", "flight_sound", "explosion_effect", "explosion_sound", "hit_anchor"};
constexpr std::array<std::string_view, 3> kSkillColumns{"skill", "bullet_id", "spawn_point"};

[[nodiscard]] float dist3(FlightPoint left, FlightPoint right) noexcept {
    const float dx = right.x - left.x;
    const float dy = right.y - left.y;
    const float dz = right.z - left.z;
    return std::sqrt((dx * dx) + (dy * dy) + (dz * dz));
}

[[nodiscard]] float dist_sq(FlightPoint left, FlightPoint right) noexcept {
    const float dx = right.x - left.x;
    const float dy = right.y - left.y;
    const float dz = right.z - left.z;
    return (dx * dx) + (dy * dy) + (dz * dz);
}

[[nodiscard]] float yaw_of(FlightPoint from, FlightPoint to) noexcept {
    const float dx = to.x - from.x;
    const float dz = to.z - from.z;
    const float length = std::sqrt((dx * dx) + (dz * dz));
    if (!(length > 0.0F)) return 0.0F;
    const double cosine = static_cast<double>(dz) / static_cast<double>(length);
    const double clamped = std::clamp(cosine, -1.0, 1.0);
    const double angle = std::acos(clamped);
    if (to.x >= from.x) return static_cast<float>(angle);
    return static_cast<float>((2.0 * kPi) - angle);
}

[[nodiscard]] float arc_lift(const BulletFlight& flight, FlightPoint at) noexcept {
    if (flight.trail != Trail::kArc) return 0.0F;
    if (!(flight.span > 0.0F)) return 0.0F;
    const float travelled = dist3(at, flight.start);
    const float center = std::fabs(travelled - (flight.span * 0.5F));
    const float temp = (center * 2.0F) / flight.span;
    return (1.0F - (temp * temp)) * flight.arc_height;
}

[[nodiscard]] BulletStep stay_at(const BulletFlight& flight) noexcept {
    BulletStep step;
    step.at = flight.at;
    step.hit = flight.hit;
    return step;
}

[[nodiscard]] BulletStep arrive_at(const BulletFlight& flight, FlightPoint target) noexcept {
    BulletStep step;
    step.at = target;
    step.at.y += arc_lift(flight, target);
    step.facing = yaw_of(flight.at, step.at);
    step.hit = true;
    return step;
}

[[nodiscard]] FlightPoint fly_towards(FlightPoint from, FlightPoint target, float step) noexcept {
    const float dx = target.x - from.x;
    const float dy = target.y - from.y;
    const float dz = target.z - from.z;
    const float length = std::sqrt((dx * dx) + (dy * dy) + (dz * dz));
    FlightPoint next = from;
    if (!(length > 0.0F)) return next;
    next.x = from.x + ((dx / length) * step);
    next.y = from.y + ((dy / length) * step);
    next.z = from.z + ((dz / length) * step);
    return next;
}

[[nodiscard]] BulletStep fly_step(const BulletFlight& flight, FlightPoint target,
    float step) noexcept {
    BulletStep moved;
    moved.at = fly_towards(flight.at, target, step);
    moved.at.y += arc_lift(flight, moved.at);
    moved.facing = yaw_of(flight.at, moved.at);
    return moved;
}

[[nodiscard]] std::optional<Trail> trail_of(std::int32_t code) noexcept {
    if (code == 0) return Trail::kLine;
    if (code == 1) return Trail::kArc;
    if (code == 2 || code == -1) return Trail::kNone;
    return std::nullopt;
}

BulletRow bullet_row(table::RowReader& reader) {
    BulletRow row;
    row.id = reader.number("id", 0, kMaxId);
    const std::int32_t code = reader.integer("trajectory", -1, 2);
    const std::optional<Trail> trail = trail_of(code);
    if (!trail) reader.reject("trajectory", "chỉ nhận -1, 0, 1, 2");
    if (trail) row.trail = *trail;
    const float speed = reader.real("speed");
    if (speed < 0.0F) reader.reject("speed", "âm");
    row.speed = speed < 0.0F ? 0.0F : speed;
    row.flight = std::string(reader.text("flight_effect"));
    row.flight_sound = std::string(reader.text("flight_sound"));
    row.explosion = std::string(reader.text("explosion_effect"));
    row.explosion_sound = std::string(reader.text("explosion_sound"));
    row.anchor = std::string(reader.text("hit_anchor"));
    return row;
}

SkillBullet skill_row(table::RowReader& reader) {
    SkillBullet row;
    row.skill = reader.number("skill", 0, kMaxId);
    row.bullet = reader.number("bullet_id", 0, kMaxId);
    row.spawn = std::string(reader.text("spawn_point"));
    return row;
}

[[nodiscard]] std::string missing_named_column(std::string_view name, std::string_view column) {
    return std::format("bảng {} thiếu cột {}", name, column);
}

template <std::size_t N>
[[nodiscard]] std::expected<table::Tsv, std::string> parse_table(std::string_view text,
    std::string_view name, const std::array<std::string_view, N>& columns) {
    table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(std::format("bảng {} sai, {}", name, parsed.error()));
    for (const std::string_view column : columns) {
        if (table::column_of(*parsed, column)) continue;
        return std::unexpected(missing_named_column(name, column));
    }
    return std::move(*parsed);
}

} // namespace

void BulletBook::reset(std::vector<BulletRow> rows) {
    rows_ = std::move(rows);
}

const BulletRow* BulletBook::find(std::uint32_t id) const noexcept {
    const auto found = std::ranges::lower_bound(rows_, id, {}, &BulletRow::id);
    if (found == rows_.end() || found->id != id) return nullptr;
    return &*found;
}

void SkillBulletBook::reset(std::vector<SkillBullet> rows) {
    rows_ = std::move(rows);
}

const SkillBullet* SkillBulletBook::find(std::uint32_t skill) const noexcept {
    const auto found = std::ranges::lower_bound(rows_, skill, {}, &SkillBullet::skill);
    if (found == rows_.end() || found->skill != skill) return nullptr;
    return &*found;
}

BulletFlight begin_flight(Trail trail, float speed, float arc_height, FlightPoint from,
    FlightPoint to) noexcept {
    BulletFlight flight;
    flight.trail = trail;
    flight.speed = speed > 0.0F ? speed : 0.0F;
    flight.arc_height = arc_height;
    flight.start = from;
    flight.at = from;
    if (trail == Trail::kNone) flight.at = to;
    if (trail == Trail::kNone) flight.start = to;
    flight.span = dist3(to, flight.start);
    return flight;
}

BulletStep step_bullet(const BulletFlight& flight, FlightPoint target, float seconds) noexcept {
    if (flight.hit) return stay_at(flight);
    if (flight.trail == Trail::kNone) return arrive_at(flight, target);
    const float step = flight.speed * seconds;
    const float remain = dist_sq(target, flight.at);
    const float reach = step * step;
    if (!(step > 0.0F) && remain > 0.0F) return stay_at(flight);
    if (remain <= reach) return arrive_at(flight, target);
    return fly_step(flight, target, step);
}

std::expected<std::vector<BulletRow>, std::string> parse_bullets(std::string_view text) {
    auto table = parse_table(text, "bullets", kBulletColumns);
    if (!table) return std::unexpected(table.error());
    Rows<BulletRow> rows = detail::read_all<BulletRow>(*table, bullet_row);
    if (!rows) return std::unexpected(std::format("bảng bullets sai, {}", rows.error()));
    const auto bullet_key = [](const BulletRow& row) { return row.id; };
    rows = detail::sorted_unique(std::move(rows), bullet_key, "bullets");
    if (!rows) return std::unexpected(rows.error());
    return std::move(*rows);
}

std::expected<std::vector<SkillBullet>, std::string> parse_skill_bullets(std::string_view text) {
    auto table = parse_table(text, "skill_bullets", kSkillColumns);
    if (!table) return std::unexpected(table.error());
    Rows<SkillBullet> rows = detail::read_all<SkillBullet>(*table, skill_row);
    if (!rows) return std::unexpected(std::format("bảng skill_bullets sai, {}", rows.error()));
    const auto skill_key = [](const SkillBullet& row) { return row.skill; };
    rows = detail::sorted_unique(std::move(rows), skill_key, "skill_bullets");
    if (!rows) return std::unexpected(rows.error());
    return std::move(*rows);
}

} // namespace game::look
