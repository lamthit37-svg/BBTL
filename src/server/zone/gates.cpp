/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/gates.cpp
 *  PHÂN HỆ   : Server / Zone / Gates
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc ScenePosDefineEx và script chuansong, buộc vùng areas vào cổng đi bộ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/gates.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::zone {
namespace {

constexpr std::int32_t kCoordLimit = 1'000'000;
constexpr std::int32_t kSceneLimit = 2'000'000;

[[nodiscard]] bool row_ok(const table::RowReader& reader) { return !reader.error().has_value(); }

[[nodiscard]] bool is_chuansong(std::span<const std::int32_t> scripts, std::int32_t script) noexcept {
    return std::ranges::binary_search(scripts, script);
}

// Cách từ điểm tới hình chữ nhật đóng, mét bình phương. Cạnh phải và cạnh dưới tính vào khoảng cách
// dù area_stand không coi chúng là phía trong (điểm nằm đúng cạnh vẫn buộc được cổng).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): x và z là hai trục, nơi gọi ghi tên (HP-07)
[[nodiscard]] float gap_squared(const AreaRect& area, float x, float z) noexcept {
    const float dx = x < area.left ? area.left - x : (x > area.right ? x - area.right : 0.0F);
    const float dz = z < area.top ? area.top - z : (z > area.bottom ? z - area.bottom : 0.0F);
    return (dx * dx) + (dz * dz);
}

[[nodiscard]] bool walk_edge(const WalkGate& gate, std::int32_t scene) noexcept {
    if (gate.kind != 0) return false;
    if (gate.source_scene != scene || gate.dest_scene == scene) return false;
    if (gate.dest_scene < 0 || gate.dest_scene > 0xFFFF) return false;
    return true;
}

[[nodiscard]] const WalkGate* nearest_gate(std::span<const WalkGate> gates, std::int32_t scene, const AreaRect& area) noexcept {
    const WalkGate* best = nullptr;
    float best_gap = kGateBindMetres * kGateBindMetres;
    for (const WalkGate& gate : gates) {
        if (!walk_edge(gate, scene)) continue;
        const float gap = gap_squared(area, static_cast<float>(gate.source_x), static_cast<float>(gate.source_z));
        const bool closer = gap < best_gap || (gap == best_gap && best != nullptr && gate.id < best->id);
        if (best != nullptr && !closer) continue;
        if (gap > best_gap) continue;
        best = &gate;
        best_gap = gap;
    }
    return best;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): scene là cảnh nguồn, script là id script vùng (HP-07)
void bind_one(AreaRect& rect, std::int32_t scene, std::int32_t script, std::span<const WalkGate> gates,
    std::span<const std::int32_t> chuansong, const std::function<bool(std::uint16_t)>& known) {
    if (script < 0 || !is_chuansong(chuansong, script)) return;
    const WalkGate* const gate = nearest_gate(gates, scene, rect);
    if (gate == nullptr) return;
    const auto dest = static_cast<std::uint16_t>(gate->dest_scene);
    if (known && !known(dest)) return;
    rect.crossing = true;
    rect.dest_scene = dest;
    rect.dest_x_cm = static_cast<float>(gate->dest_x) * kCmPerGameUnit;
    rect.dest_z_cm = static_cast<float>(gate->dest_z) * kCmPerGameUnit;
}

} // namespace

std::expected<std::vector<WalkGate>, std::string> parse_gates(std::string_view text) {
    const table::TsvResult table = table::parse_tsv(text);
    if (!table) return std::unexpected(table.error());
    if (!table::column_of(*table, "column_2") || !table::column_of(*table, "column_11")) {
        return std::unexpected("bảng cổng thiếu cột column_2..column_11");
    }
    std::vector<WalkGate> gates;
    gates.reserve(table->rows.size());
    for (std::size_t row = 0; row < table->rows.size(); ++row) {
        table::RowReader reader{*table, row};
        WalkGate gate;
        gate.id = reader.integer("column_0", 0, kSceneLimit);
        gate.source_scene = reader.integer("column_2", 0, kSceneLimit);
        gate.source_x = reader.integer("column_3", -kCoordLimit, kCoordLimit);
        gate.source_z = reader.integer("column_4", -kCoordLimit, kCoordLimit);
        gate.dest_scene = reader.integer("column_6", 0, kSceneLimit);
        gate.dest_x = reader.integer("column_7", -kCoordLimit, kCoordLimit);
        gate.dest_z = reader.integer("column_8", -kCoordLimit, kCoordLimit);
        gate.kind = reader.integer("column_9", -1, 100);
        if (!row_ok(reader)) continue;
        gates.push_back(gate);
    }
    return gates;
}

std::expected<std::vector<std::int32_t>, std::string> parse_chuansong(std::string_view text) {
    const table::TsvResult table = table::parse_tsv(text);
    if (!table) return std::unexpected(table.error());
    if (!table::column_of(*table, "script_id") || !table::column_of(*table, "path")) {
        return std::unexpected("bảng script thiếu cột script_id hoặc path");
    }
    std::vector<std::int32_t> scripts;
    for (std::size_t row = 0; row < table->rows.size(); ++row) {
        table::RowReader reader{*table, row};
        const std::int32_t script = reader.integer("script_id", 0, kSceneLimit);
        const std::string_view path = reader.text("path");
        if (!row_ok(reader)) continue;
        if (!path.contains("/event/chuansong/")) continue;
        scripts.push_back(script);
    }
    std::ranges::sort(scripts);
    scripts.erase(std::ranges::unique(scripts).begin(), scripts.end());
    return scripts;
}

std::vector<AreaRect> area_rects(std::int32_t scene, std::span<const AreaSource> areas, std::span<const WalkGate> gates,
    std::span<const std::int32_t> chuansong, const std::function<bool(std::uint16_t)>& known) {
    std::vector<AreaRect> rects;
    rects.reserve(areas.size());
    for (const AreaSource& source : areas) {
        AreaRect rect;
        rect.left = source.left;
        rect.top = source.top;
        rect.right = source.right;
        rect.bottom = source.bottom;
        bind_one(rect, scene, source.script_id, gates, chuansong, known);
        rects.push_back(rect);
    }
    return rects;
}

AreaStand area_stand(std::span<const AreaRect> areas, float x, float z) noexcept {
    AreaStand found;
    if (!std::isfinite(x) || !std::isfinite(z)) return found;
    for (std::uint32_t index = 0; index < areas.size(); ++index) {
        const AreaRect& area = areas[index];
        const bool contains = x >= area.left && x < area.right && z >= area.top && z < area.bottom;
        if (!contains) continue;
        found.inside = true;
        found.index = index;
        found.crossing = area.crossing;
        found.dest_scene = area.dest_scene;
        found.dest_x_cm = area.dest_x_cm;
        found.dest_z_cm = area.dest_z_cm;
        return found;
    }
    return found;
}

} // namespace game::zone
