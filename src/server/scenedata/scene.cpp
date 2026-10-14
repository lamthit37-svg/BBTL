#include "scenedata/scene.hpp"

#include "scenedata/tables.hpp"
#include "scenedata/types.hpp"
#include "scenedata/walk.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::scenedata {
namespace {

constexpr std::string_view kSuffix = ".tsv";

[[nodiscard]] bool name_char(char byte) noexcept {
    return (byte >= 'a' && byte <= 'z') || (byte >= 'A' && byte <= 'Z') || (byte >= '0' && byte <= '9') || byte == '_' ||
           byte == '.' || byte == '-';
}

// Nạp một bảng theo loại. `parse` là một trong các parse_* của tables.hpp; `place` đặt kết quả vào cảnh.
template <typename Row, typename Parse, typename Place>
[[nodiscard]] std::optional<LoadError> load_table(const NamedText& table, Parse parse, Place place) {
    Loaded<std::vector<Row>> rows = parse(table.name, table.text);
    if (!rows) return std::move(rows.error());
    place(std::move(*rows));
    return std::nullopt;
}

template <typename Row>
void place_variant(std::vector<Variant<Row>>& target, std::string_view label, std::vector<Row> rows) {
    target.push_back(Variant<Row>{.label = std::string(label), .rows = std::move(rows)});
}

// Bảng có nhãn: nhãn rỗng vào `base`, nhãn khác vào `variants`.
template <typename Row, typename Parse>
[[nodiscard]] std::optional<LoadError> load_labelled(const NamedText& table, const TableName& name, Parse parse,
    std::vector<Row>& base, std::vector<Variant<Row>>& variants) {
    return load_table<Row>(table, parse, [&](std::vector<Row> rows) {
        if (name.label.empty()) {
            base = std::move(rows);
        } else {
            place_variant(variants, name.label, std::move(rows));
        }
    });
}

// Bảng luôn tách theo nhãn, kể cả bản gốc (nhãn rỗng): spawn_operates và spawn_operate_values.
template <typename Row, typename Parse>
[[nodiscard]] std::optional<LoadError> load_variants(const NamedText& table, const TableName& name, Parse parse,
    std::vector<Variant<Row>>& variants) {
    return load_table<Row>(table, parse, [&](std::vector<Row> rows) { place_variant(variants, name.label, std::move(rows)); });
}

// Bảng chỉ có bản gốc (known_family đã loại tên có nhãn).
template <typename Row, typename Parse>
[[nodiscard]] std::optional<LoadError> load_plain(const NamedText& table, Parse parse, std::vector<Row>& target) {
    return load_table<Row>(table, parse, [&](std::vector<Row> rows) { target = std::move(rows); });
}

[[nodiscard]] bool is_plain_family(std::string_view family) noexcept {
    constexpr std::array<std::string_view, 8> kPlain{
        "spawn_levels", "patrols", "grow_points", "grow_point_rules", "platforms", "wild_pets", "portals", "buses"};
    return std::ranges::find(kPlain, family) != kPlain.end();
}

[[nodiscard]] std::optional<LoadError> dispatch(Scene& scene, const NamedText& table, const TableName& name) {
    const std::string_view family = name.family;
    if (family == "spawns") return load_labelled<Spawn>(table, name, parse_spawns, scene.spawns, scene.spawn_variants);
    if (family == "areas") return load_labelled<Area>(table, name, parse_areas, scene.areas, scene.area_variants);
    if (family == "spawn_operates") {
        return load_variants<SpawnOperate>(table, name, parse_spawn_operates, scene.spawn_operates);
    }
    if (family == "spawn_operate_values") {
        return load_variants<OperateValue>(table, name, parse_operate_values, scene.operate_values);
    }
    if (family == "spawn_levels") return load_plain<SpawnLevel>(table, parse_spawn_levels, scene.spawn_levels);
    if (family == "patrols") return load_plain<Patrol>(table, parse_patrols, scene.patrols);
    if (family == "grow_points") return load_plain<GrowPoint>(table, parse_grow_points, scene.grow_points);
    if (family == "grow_point_rules") return load_plain<GrowRule>(table, parse_grow_rules, scene.grow_rules);
    if (family == "platforms") return load_plain<Platform>(table, parse_platforms, scene.platforms);
    if (family == "wild_pets") return load_plain<WildPet>(table, parse_wild_pets, scene.wild_pets);
    if (family == "portals") return load_plain<Portal>(table, parse_portals, scene.portals);
    return load_plain<Bus>(table, parse_buses, scene.buses);
}

// Loại bộ nạp hiểu: có nhãn được với bốn loại đầu, các loại còn lại chỉ có bản gốc.
[[nodiscard]] bool known_family(const TableName& name) noexcept {
    if (name.family == "spawns" || name.family == "areas" || name.family == "spawn_operates" ||
        name.family == "spawn_operate_values") {
        return true;
    }
    return name.label.empty() && is_plain_family(name.family);
}

[[nodiscard]] std::optional<LoadError> check_names(const SceneFiles& files) {
    if (files.tables.size() > kMaxSceneTables) return LoadError{"scene: quá nhiều bảng"};
    std::set<std::string_view> seen;
    for (const NamedText& table : files.tables) {
        if (table.name.size() > kMaxTableName || !split_table_name(table.name)) {
            return LoadError{"scene: tên bảng không hợp lệ: " + table.name.substr(0, 64)};
        }
        if (!seen.insert(table.name).second) return LoadError{"scene: bảng lặp: " + table.name};
    }
    return std::nullopt;
}

// Mọi spawn_file của operate / operate_values phải trỏ tới một bảng quái có mặt.
[[nodiscard]] std::optional<LoadError> check_operate_targets(const SceneFiles& files, const Scene& scene) {
    std::set<std::string_view> present;
    for (const NamedText& table : files.tables) present.insert(table.name);
    const auto missing = [&](const auto& variants) -> std::optional<LoadError> {
        for (const auto& variant : variants) {
            for (const auto& row : variant.rows) {
                if (!present.contains(row.spawn_file)) {
                    return LoadError{"scene: " + variant.label + ": spawn_file trỏ tới bảng không có: " + row.spawn_file};
                }
            }
        }
        return std::nullopt;
    };
    if (auto problem = missing(scene.spawn_operates)) return problem;
    return missing(scene.operate_values);
}

} // namespace

std::optional<TableName> split_table_name(std::string_view name) noexcept {
    if (!name.ends_with(kSuffix) || !std::ranges::all_of(name, name_char)) return std::nullopt;
    const std::string_view stem = name.substr(0, name.size() - kSuffix.size());
    const std::size_t dot = stem.find('.');
    const std::string_view family = stem.substr(0, dot);
    const std::string_view label = dot == std::string_view::npos ? std::string_view{} : stem.substr(dot + 1);
    if (family.empty() || (dot != std::string_view::npos && label.empty())) return std::nullopt;
    return TableName{.family = family, .label = label};
}

const Patrol* Scene::find_patrol(std::int32_t index) const noexcept {
    const auto at = std::ranges::lower_bound(patrols, index, {}, &Patrol::index);
    return at != patrols.end() && at->index == index ? &*at : nullptr;
}

Loaded<Scene> parse_scene(const SceneFiles& files) {
    if (std::optional<LoadError> problem = check_names(files)) return std::unexpected(std::move(*problem));
    Scene scene;
    scene.name = files.name;
    // Thứ tự nạp cố định theo tên tệp: kết quả không phụ thuộc thứ tự tệp trong `files`.
    std::vector<const NamedText*> ordered;
    ordered.reserve(files.tables.size());
    for (const NamedText& table : files.tables) ordered.push_back(&table);
    std::ranges::sort(ordered, {}, [](const NamedText* table) -> const std::string& { return table->name; });
    for (const NamedText* table : ordered) {
        const std::optional<TableName> name = split_table_name(table->name);
        if (!name || !known_family(*name)) {
            scene.unread_files.push_back(table->name);
            continue;
        }
        if (std::optional<LoadError> problem = dispatch(scene, *table, *name)) return std::unexpected(std::move(*problem));
    }
    std::ranges::sort(scene.spawn_variants, {}, &Variant<Spawn>::label);
    std::ranges::sort(scene.area_variants, {}, &Variant<Area>::label);
    std::ranges::sort(scene.spawn_operates, {}, &Variant<SpawnOperate>::label);
    std::ranges::sort(scene.operate_values, {}, &Variant<OperateValue>::label);
    if (std::optional<LoadError> problem = check_operate_targets(files, scene)) return std::unexpected(std::move(*problem));
    Loaded<Manifest> manifest = parse_manifest(files.manifest);
    if (!manifest) return std::unexpected(std::move(manifest.error()));
    const auto view_of = [](const std::optional<std::string>& bytes) -> std::optional<std::string_view> {
        if (!bytes) return std::nullopt;
        return std::string_view{*bytes};
    };
    Loaded<Walk> walk = build_walk(*manifest, view_of(files.walk_path), view_of(files.walk_nav));
    if (!walk) return std::unexpected(std::move(walk.error()));
    scene.walk = std::move(*walk);
    return scene;
}

SceneAudit audit_scene(const Scene& scene) noexcept {
    SceneAudit audit;
    audit.has_walk = scene.walk.source != WalkSource::kNone;
    audit.has_legacy_grid = scene.walk.grid.has_value();
    const auto count = [&](const std::vector<Spawn>& spawns) {
        for (const Spawn& spawn : spawns) {
            ++audit.spawns;
            if (spawn.patrol_id >= 0 && scene.find_patrol(spawn.patrol_id) == nullptr) ++audit.spawns_dangling_patrol;
            if (!spawn.position_given) continue;
            ++audit.spawns_placed;
            if (audit.has_walk && !scene.walk.walkable(spawn.position)) ++audit.spawns_off_walk;
            if (audit.has_legacy_grid && !scene.walk.grid->can_go(spawn.position, 0)) ++audit.spawns_off_legacy_grid;
        }
    };
    count(scene.spawns);
    for (const Variant<Spawn>& variant : scene.spawn_variants) count(variant.rows);
    for (const Patrol& patrol : scene.patrols) {
        for (const PatrolPoint& point : patrol.points) {
            if (audit.has_walk && point.position_given && !scene.walk.walkable(point.position)) {
                ++audit.patrol_points_off_walk;
            }
        }
    }
    return audit;
}

} // namespace game::scenedata
