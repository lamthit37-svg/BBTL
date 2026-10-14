#include "scenedata/tables.hpp"

#include "core/ground_point.hpp"
#include "scenedata/detail/cells.hpp"
#include "scenedata/types.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::scenedata {
namespace {

using detail::Cells;

constexpr std::int32_t kMaxInt = 2'000'000'000;
// Hướng tính bằng bước 10 độ; dữ liệu thật nằm trong -20..117. Trần rộng để dữ liệu lạ vẫn nạp được,
// đủ hẹp để dir * 10 + 90 không tràn int32.
constexpr std::int32_t kMaxDirection = 100'000;
constexpr std::int32_t kMaxLevel = 100'000;
constexpr std::int32_t kMaxId = 100'000'000;
constexpr std::size_t kMaxFileName = 128;
// Dòng chú thích (# schema, # source, # tool, # types) cộng dòng tên cột: chỗ chừa cho trần số dòng.
constexpr std::size_t kHeaderSlack = 64;

constexpr std::array<std::string_view, 26> kSpawnColumns{"guid", "type", "name", "title", "position_x", "position_z",
    "direction", "script_id", "respawn_time", "group_id", "team_id", "base_ai", "ai_file", "patrol_id", "shop_0",
    "shop_1", "shop_2", "shop_3", "level", "is_pet", "script_timer", "reputation_id", "cshop", "leader_id", "is_npc",
    "camp"};
constexpr std::array<std::string_view, 6> kAreaColumns{"guid", "script_id", "left", "top", "right", "bottom"};
// Cột speech_N (N từ 1) tuỳ cảnh nên không bắt buộc.
constexpr std::array<std::string_view, 10> kPatrolColumns{"patrol_index", "point_index", "position_x", "position_y",
    "position_z", "settle_time", "point_script_id", "route_script_id", "turns_back", "teleport_to_respawn"};
constexpr std::array<std::string_view, 4> kGrowPointColumns{"point_id", "grow_point_type", "position_x", "position_y"};
constexpr std::array<std::string_view, 6> kGrowRuleColumns{"grow_point_type", "max_count", "column_2", "column_3",
    "column_4", "column_5"};
constexpr std::array<std::string_view, 7> kPlatformColumns{"type_id", "class_id", "position_x", "position_z",
    "direction", "script_id", "tip"};
constexpr std::array<std::string_view, 7> kWildPetColumns{"guid", "type", "name", "position_x", "position_z",
    "respawn_time", "ai_file"};
constexpr std::array<std::string_view, 8> kPortalColumns{"type", "scene_id", "position_x", "position_z",
    "target_scene_id", "target_position_x", "target_position_z", "target_direction"};
constexpr std::array<std::string_view, 4> kBusColumns{"guid", "data_id", "patrol_id", "reverse"};
constexpr std::array<std::string_view, 2> kSpawnLevelColumns{"monster_index", "level"};
constexpr std::array<std::string_view, 5> kOperateColumns{"spawn_file", "select_type", "select_value", "data_def",
    "max_left"};
constexpr std::array<std::string_view, 6> kOperateValueColumns{"spawn_file", "data_index", "data_type", "value_index",
    "value", "value_extra"};

[[nodiscard]] std::unexpected<LoadError> fail(std::string_view file, std::string_view what) {
    return std::unexpected(LoadError{std::string(file) + ": " + std::string(what)});
}

// Khung chung: kiểm cỡ trước khi tách dòng, tách bảng, kiểm đủ cột bắt buộc, rồi đọc từng dòng bằng
// fill(Cells&) -> Row. Lỗi đầu tiên của một dòng dừng cả bảng (không trả bảng nửa vời).
template <typename Row, typename Fill>
[[nodiscard]] Loaded<std::vector<Row>> read_rows(std::string_view file, std::span<const std::string_view> required,
    std::string_view text, Fill fill) {
    if (text.size() > kMaxTableBytes) return fail(file, "bảng quá lớn");
    const auto newlines = static_cast<std::size_t>(std::ranges::count(text, '\n'));
    if (newlines > kMaxTableRows + kHeaderSlack) return fail(file, "bảng quá nhiều dòng");
    const table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return fail(file, parsed.error());
    const table::Tsv& tsv = *parsed;
    if (tsv.header.size() > kMaxColumns) return fail(file, "bảng quá nhiều cột");
    if (tsv.rows.size() > kMaxTableRows) return fail(file, "bảng quá nhiều dòng");
    // Kiểm tên cột ngay cả khi bảng không có dòng nào: bảng đổi tên cột mà xoá hết dòng không được lọt.
    for (const std::string_view column : required) {
        if (!table::column_of(tsv, column)) return fail(file, "thiếu cột " + std::string(column));
    }
    std::vector<Row> rows;
    rows.reserve(tsv.rows.size());
    for (std::size_t index = 0; index < tsv.rows.size(); ++index) {
        Cells cells(file, tsv, index);
        Row row = fill(cells);
        if (cells.error()) return std::unexpected(LoadError{*cells.error()});
        rows.push_back(std::move(row));
    }
    return rows;
}

[[nodiscard]] core::GroundPoint point_of(Cells& cells, std::string_view x_column, std::string_view z_column) {
    const float x = cells.real_or_zero(x_column);
    const float z = cells.real_or_zero(z_column);
    return core::GroundPoint{.x = x, .z = z};
}

[[nodiscard]] bool safe_file_name(std::string_view name) noexcept {
    if (name.empty() || name.size() > kMaxFileName || name.find("..") != std::string_view::npos) return false;
    return name.find_first_of("/\\:") == std::string_view::npos;
}

Spawn read_spawn(Cells& cells) {
    Spawn spawn;
    spawn.guid = cells.uint_or_zero("guid", static_cast<std::uint32_t>(kMaxInt));
    spawn.type = ids::MonsterTemplateId{cells.uint_or_zero("type", static_cast<std::uint32_t>(kMaxId))};
    spawn.name = cells.text("name");
    spawn.title = cells.text("title");
    spawn.position_given = !cells.blank("position_x") && !cells.blank("position_z");
    spawn.position = point_of(cells, "position_x", "position_z");
    spawn.direction = cells.int_or_zero("direction", -kMaxDirection, kMaxDirection);
    spawn.script_id = cells.int_or_zero("script_id", -1, kMaxInt);
    spawn.respawn_ms = cells.int_or_zero("respawn_time", -1, kMaxInt);
    spawn.group_id = cells.int_or_zero("group_id", -1, kMaxInt);
    spawn.team_id = cells.int_or_zero("team_id", -1, kMaxInt);
    spawn.base_ai = cells.int_opt("base_ai", 0, 65'535);
    spawn.ai_file = cells.int_opt("ai_file", -1, kMaxId);
    spawn.patrol_id = cells.int_or_zero("patrol_id", -1, kMaxInt);
    constexpr std::array<std::string_view, 4> kShopColumns{"shop_0", "shop_1", "shop_2", "shop_3"};
    std::ranges::transform(kShopColumns, spawn.shop.begin(),
        [&cells](std::string_view column) { return cells.int_or(column, -1, -1, kMaxInt); });
    spawn.level = cells.int_or("level", 0, -1, kMaxLevel);
    spawn.is_pet = cells.flag("is_pet");
    spawn.script_timer_ms = cells.int_or("script_timer", 0, 0, kMaxInt);
    spawn.reputation_id = cells.int_opt("reputation_id", -1, kMaxId);
    spawn.custom_shop = cells.text("cshop");
    spawn.leader_id = cells.int_or("leader_id", -1, -1, kMaxInt);
    spawn.is_npc = cells.flag("is_npc");
    spawn.camp = cells.int_opt("camp", -1, kMaxId);
    return spawn;
}

Area read_area(Cells& cells) {
    Area area;
    area.guid = cells.uint_or_zero("guid", static_cast<std::uint32_t>(kMaxInt));
    area.script_id = cells.int_or_zero("script_id", -1, kMaxInt);
    area.left = cells.real_or_zero("left");
    area.top = cells.real_or_zero("top");
    area.right = cells.real_or_zero("right");
    area.bottom = cells.real_or_zero("bottom");
    return area;
}

struct IndexedPoint {
    std::int32_t patrol = 0;
    std::int32_t point = 0;
    PatrolPoint data;
};

IndexedPoint read_patrol_point(Cells& cells) {
    IndexedPoint indexed;
    indexed.patrol = cells.int_or_zero("patrol_index", 0, kMaxId);
    indexed.point = cells.int_or_zero("point_index", 0, kMaxId);
    PatrolPoint& data = indexed.data;
    data.position_given = !cells.blank("position_x") && !cells.blank("position_z");
    data.position = point_of(cells, "position_x", "position_z");
    data.height = cells.real_opt("position_y");
    data.settle_ms = cells.uint_opt("settle_time", static_cast<std::uint32_t>(kMaxInt));
    data.point_script_id = cells.int_opt("point_script_id", -1, kMaxInt);
    data.route_script_id = cells.int_opt("route_script_id", -1, kMaxInt);
    data.turns_back = cells.flag("turns_back");
    data.teleport_to_respawn = cells.flag("teleport_to_respawn");
    // speech_unread là khoá mã 2008 không đọc; chỉ speech_1.. là câu nói thật. Số cột speech tuỳ cảnh.
    for (std::size_t number = 1; number <= kMaxSpeechPerPoint; ++number) {
        const std::string column = "speech_" + std::to_string(number);
        if (!cells.has(column)) break;
        std::string line = cells.text(column);
        if (!line.empty()) data.speech.push_back(std::move(line));
    }
    return indexed;
}

GrowPoint read_grow_point(Cells& cells) {
    GrowPoint point;
    point.point_id = cells.int_or_zero("point_id", 0, kMaxInt);
    point.grow_point_type = cells.int_or_zero("grow_point_type", 0, kMaxInt);
    point.position = point_of(cells, "position_x", "position_y");
    return point;
}

GrowRule read_grow_rule(Cells& cells) {
    GrowRule rule;
    rule.grow_point_type = cells.int_or_zero("grow_point_type", 0, kMaxInt);
    rule.max_count = cells.int_or_zero("max_count", 0, kMaxInt);
    rule.per_batch = cells.int_or_zero("column_2", 0, kMaxInt);
    rule.control_function = cells.text("column_3");
    rule.refill_interval_ms = cells.int_or_zero("column_4", 0, kMaxInt);
    rule.refill_jitter_ms = cells.int_or_zero("column_5", 0, kMaxInt);
    return rule;
}

Platform read_platform(Cells& cells) {
    Platform platform;
    platform.type_id = cells.int_or_zero("type_id", 0, kMaxInt);
    platform.class_id = cells.int_or_zero("class_id", 0, kMaxInt);
    platform.position = point_of(cells, "position_x", "position_z");
    platform.direction = cells.int_or_zero("direction", -kMaxDirection, kMaxDirection);
    platform.script_id = cells.int_opt("script_id", -1, kMaxInt);
    platform.tip = cells.text("tip");
    return platform;
}

WildPet read_wild_pet(Cells& cells) {
    WildPet pet;
    pet.guid = cells.uint_or_zero("guid", static_cast<std::uint32_t>(kMaxInt));
    pet.type = cells.int_or_zero("type", 0, kMaxInt);
    pet.name = cells.text("name");
    pet.position = point_of(cells, "position_x", "position_z");
    pet.respawn_ms = cells.int_or_zero("respawn_time", -1, kMaxInt);
    pet.ai_file = cells.int_or_zero("ai_file", -1, kMaxInt);
    return pet;
}

Portal read_portal(Cells& cells) {
    Portal portal;
    portal.type = cells.int_or_zero("type", 0, kMaxInt);
    portal.scene_id = cells.int_or_zero("scene_id", 0, kMaxInt);
    portal.position = point_of(cells, "position_x", "position_z");
    portal.target_scene_id = cells.int_or_zero("target_scene_id", 0, kMaxInt);
    portal.target_position = point_of(cells, "target_position_x", "target_position_z");
    portal.target_direction = cells.int_or_zero("target_direction", -kMaxDirection, kMaxDirection);
    return portal;
}

Bus read_bus(Cells& cells) {
    Bus bus;
    bus.guid = cells.uint_or_zero("guid", static_cast<std::uint32_t>(kMaxInt));
    bus.data_id = cells.int_or_zero("data_id", 0, kMaxInt);
    bus.patrol_id = cells.int_or_zero("patrol_id", -1, kMaxInt);
    bus.reverse = cells.flag("reverse");
    return bus;
}

SpawnLevel read_spawn_level(Cells& cells) {
    SpawnLevel level;
    level.monster_index = cells.int_or_zero("monster_index", 0, kMaxInt);
    level.level = cells.int_or_zero("level", -1, kMaxLevel);
    return level;
}

std::string read_spawn_file(Cells& cells) {
    std::string name = cells.text("spawn_file");
    if (!safe_file_name(name)) cells.reject("spawn_file", "không phải tên tệp trong cùng thư mục");
    return name;
}

SpawnOperate read_spawn_operate(Cells& cells) {
    SpawnOperate operate;
    operate.spawn_file = read_spawn_file(cells);
    operate.select_type = cells.int_or_zero("select_type", 0, kMaxInt);
    operate.select_value = cells.text("select_value");
    operate.data_def = cells.int_or_zero("data_def", 0, kMaxInt);
    operate.max_left = cells.int_or_zero("max_left", 0, kMaxInt);
    return operate;
}

OperateValue read_operate_value(Cells& cells) {
    OperateValue value;
    value.spawn_file = read_spawn_file(cells);
    value.data_index = cells.int_or_zero("data_index", 0, kMaxInt);
    value.data_type = cells.int_or_zero("data_type", 0, kMaxInt);
    value.value_index = cells.int_or_zero("value_index", 0, kMaxInt);
    value.value = cells.text("value");
    value.value_extra = cells.text("value_extra");
    return value;
}

} // namespace

Loaded<std::vector<Spawn>> parse_spawns(std::string_view file, std::string_view text) {
    return read_rows<Spawn>(file, kSpawnColumns, text, read_spawn);
}

Loaded<std::vector<Area>> parse_areas(std::string_view file, std::string_view text) {
    return read_rows<Area>(file, kAreaColumns, text, read_area);
}

Loaded<std::vector<Patrol>> parse_patrols(std::string_view file, std::string_view text) {
    Loaded<std::vector<IndexedPoint>> points = read_rows<IndexedPoint>(file, kPatrolColumns, text, read_patrol_point);
    if (!points) return std::unexpected(std::move(points.error()));
    // Sắp ổn định theo (tuyến, điểm): thứ tự dòng trong tệp không quyết định thứ tự điểm.
    std::ranges::stable_sort(*points, [](const IndexedPoint& left, const IndexedPoint& right) {
        return left.patrol != right.patrol ? left.patrol < right.patrol : left.point < right.point;
    });
    std::vector<Patrol> patrols;
    for (std::size_t at = 0; at < points->size(); ++at) {
        IndexedPoint& current = (*points)[at];
        if (patrols.empty() || patrols.back().index != current.patrol) {
            if (patrols.size() >= kMaxPatrols) return fail(file, "quá nhiều tuyến tuần");
            patrols.push_back(Patrol{.index = current.patrol, .points = {}});
        } else if (at > 0 && (*points)[at - 1].point == current.point) {
            return fail(file, "trùng điểm " + std::to_string(current.point) + " của tuyến " +
                                  std::to_string(current.patrol));
        }
        if (patrols.back().points.size() >= kMaxPatrolPoints) return fail(file, "tuyến tuần quá nhiều điểm");
        patrols.back().points.push_back(std::move(current.data));
    }
    return patrols;
}

Loaded<std::vector<GrowPoint>> parse_grow_points(std::string_view file, std::string_view text) {
    return read_rows<GrowPoint>(file, kGrowPointColumns, text, read_grow_point);
}

Loaded<std::vector<GrowRule>> parse_grow_rules(std::string_view file, std::string_view text) {
    return read_rows<GrowRule>(file, kGrowRuleColumns, text, read_grow_rule);
}

Loaded<std::vector<Platform>> parse_platforms(std::string_view file, std::string_view text) {
    return read_rows<Platform>(file, kPlatformColumns, text, read_platform);
}

Loaded<std::vector<WildPet>> parse_wild_pets(std::string_view file, std::string_view text) {
    return read_rows<WildPet>(file, kWildPetColumns, text, read_wild_pet);
}

Loaded<std::vector<Portal>> parse_portals(std::string_view file, std::string_view text) {
    return read_rows<Portal>(file, kPortalColumns, text, read_portal);
}

Loaded<std::vector<Bus>> parse_buses(std::string_view file, std::string_view text) {
    return read_rows<Bus>(file, kBusColumns, text, read_bus);
}

Loaded<std::vector<SpawnLevel>> parse_spawn_levels(std::string_view file, std::string_view text) {
    return read_rows<SpawnLevel>(file, kSpawnLevelColumns, text, read_spawn_level);
}

Loaded<std::vector<SpawnOperate>> parse_spawn_operates(std::string_view file, std::string_view text) {
    return read_rows<SpawnOperate>(file, kOperateColumns, text, read_spawn_operate);
}

Loaded<std::vector<OperateValue>> parse_operate_values(std::string_view file, std::string_view text) {
    return read_rows<OperateValue>(file, kOperateValueColumns, text, read_operate_value);
}

} // namespace game::scenedata
