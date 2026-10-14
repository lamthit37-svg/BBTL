// Bộ nạp dữ liệu cảnh máy chủ: parser mà sai thì hỏng thầm (quái đặt sai chỗ, luật AI chạy sai thứ tự, lưới
// đi lệch một ô), nên ghim bằng số tính tay/độc lập:
//   * hướng quái: độ = bước * 10 + 90, trừ 360 một lần (MonsterManager.cpp 2008: dir * pi/18 + pi/2);
//   * ô lưới cũ: chỉ số ô = phần nguyên của toạ độ nhân đôi, đi được khi level >= state (PathFinder.cpp 2008);
//   * thứ tự luật AI: ưu tiên giảm dần, bằng nhau giữ thứ tự tệp (AIScript.cpp 2008);
//   * số tổng của dữ liệu thật đếm độc lập bằng Python (TOOLS/server, đọc thẳng các tệp TSV), không lấy
//     từ đầu ra của C++.
// Ca đọc dữ liệu thật tự bỏ qua khi thư mục dev/server không có (GAME_SERVER_DATA).
#include "Nav/nav_sample.hpp"
#include "scenedata/ai_rules.hpp"
#include "scenedata/disk.hpp"
#include "scenedata/scene.hpp"
#include "scenedata/tables.hpp"
#include "scenedata/types.hpp"
#include "scenedata/walk.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <iostream>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::scenedata::test {
namespace {

using game::test::Case;
using game::test::Context;

// ---------- dựng bảng ----------

constexpr std::array<std::string_view, 26> kSpawnColumns{"guid", "type", "name", "title", "position_x", "position_z",
    "direction", "script_id", "respawn_time", "group_id", "team_id", "base_ai", "ai_file", "patrol_id", "shop_0",
    "shop_1", "shop_2", "shop_3", "level", "is_pet", "script_timer", "reputation_id", "cshop", "leader_id", "is_npc",
    "camp"};
using SpawnRow = std::array<std::string, 26>;

[[nodiscard]] std::string join(const std::vector<std::string>& cells, char separator) {
    std::string out;
    for (std::size_t index = 0; index < cells.size(); ++index) {
        if (index != 0) out.push_back(separator);
        out += cells[index];
    }
    return out;
}

// Bảng TSV có dòng chú thích như tệp do công cụ sinh.
[[nodiscard]] std::string make_table(const std::vector<std::string>& columns, const std::vector<std::vector<std::string>>& rows) {
    std::string text = "# schema 1\n# source: test\n# tool: TOOLS/server/test.py; sửa tay sẽ mất ở lượt xuất sau\n";
    text += "# types: text\n" + join(columns, '\t') + "\n";
    for (const std::vector<std::string>& row : rows) text += join(row, '\t') + "\n";
    return text;
}

[[nodiscard]] SpawnRow good_spawn() {
    return {"10", "3", "鸭", "", "1.50", "2", "9", "4", "5", "6", "7", "1", "2", "0", "-1", "-1", "-1", "-1", "", "", "", "",
        "", "", "", ""};
}

void set(SpawnRow& row, std::string_view column, std::string value) {
    const auto at = std::ranges::find(kSpawnColumns, column);
    if (at == kSpawnColumns.end()) return;
    std::span<std::string, 26>{row}[static_cast<std::size_t>(at - kSpawnColumns.begin())] = std::move(value);
}

[[nodiscard]] std::string spawn_text(const std::vector<SpawnRow>& rows) {
    const std::vector<std::string> columns(kSpawnColumns.begin(), kSpawnColumns.end());
    std::vector<std::vector<std::string>> body;
    body.reserve(rows.size());
    for (const SpawnRow& row : rows) body.emplace_back(row.begin(), row.end());
    return make_table(columns, body);
}

template <typename T>
[[nodiscard]] bool failed_with(const Loaded<T>& result, std::string_view fragment) {
    return !result.has_value() && result.error().what.find(fragment) != std::string::npos;
}

// ---------- quái ----------

void spawn_fields_and_heading(Context& context) {
    const Loaded<std::vector<Spawn>> loaded = parse_spawns("spawns.tsv", spawn_text({good_spawn()}));
    context.expect(loaded.has_value() && loaded->size() == 1, "nạp được một quái hợp lệ");
    if (!loaded) return;
    const Spawn& spawn = loaded->front();
    context.expect(spawn.guid == 10 && spawn.type.value() == 3, "guid và type");
    context.expect(spawn.name == "鸭" && spawn.title.empty(), "tên UTF-8 và tiêu đề rỗng");
    context.expect(spawn.position_given && spawn.position.x == 1.5F && spawn.position.z == 2.0F, "vị trí");
    context.expect(spawn.direction == 9 && spawn.heading_degrees() == 180, "dir 9 -> 9 * 10 + 90 = 180 độ");
    context.expect(spawn.script_id == 4 && spawn.respawn_ms == 5 && spawn.group_id == 6 && spawn.team_id == 7, "số nguyên");
    context.expect(spawn.base_ai == 1 && spawn.ai_file == 2 && spawn.patrol_id == 0, "AI và tuyến tuần");
    context.expect(spawn.shop == std::array<std::int32_t, 4>{-1, -1, -1, -1}, "cửa hàng vắng là -1");
    // Hướng: bảng nhẩm theo công thức 2008.
    struct Case {
        std::int32_t step;
        std::int32_t degrees;
    };
    constexpr std::array<Case, 6> kCases{{{.step = 0, .degrees = 90}, {.step = 9, .degrees = 180}, {.step = 27, .degrees = 360}, {.step = 28, .degrees = 10}, {.step = -9, .degrees = 0}, {.step = 35, .degrees = 80}}};
    for (const Case& one : kCases) {
        Spawn probe;
        probe.direction = one.step;
        context.expect(probe.heading_degrees() == one.degrees, "heading_degrees theo bảng nhẩm");
    }
}

void spawn_blank_cells_follow_2008(Context& context) {
    SpawnRow row = good_spawn();
    set(row, "position_x", "");
    set(row, "script_id", "");
    set(row, "ai_file", "");
    set(row, "base_ai", "");
    set(row, "shop_3", "");
    set(row, "level", "");
    const Loaded<std::vector<Spawn>> loaded = parse_spawns("spawns.tsv", spawn_text({row}));
    context.expect(loaded.has_value(), "ô rỗng hợp lệ");
    if (!loaded) return;
    const Spawn& spawn = loaded->front();
    context.expect(!spawn.position_given && spawn.position.x == 0.0F && spawn.position.z == 2.0F, "x rỗng: atof thành 0");
    context.expect(spawn.script_id == 0, "script_id rỗng: atoi thành 0");
    context.expect(!spawn.ai_file && !spawn.base_ai, "AI rỗng: lấy theo mẫu quái");
    context.expect(spawn.shop[3] == -1 && spawn.level == 0 && spawn.leader_id == -1, "mặc định của khoá tuỳ chọn");
    context.expect(!spawn.is_pet && !spawn.is_npc && !spawn.camp && spawn.script_timer_ms == 0, "cờ tuỳ chọn vắng");
}

void spawn_rejects_hostile_cells(Context& context) {
    struct Bad {
        std::string_view column;
        std::string value;
        std::string_view fragment;
    };
    const std::vector<Bad> bad{
        {.column = "type", .value = "abc", .fragment = "cột type"},
        {.column = "type", .value = "-1", .fragment = "cột type"},
        {.column = "guid", .value = "4294967296", .fragment = "cột guid"},
        {.column = "position_x", .value = "nan", .fragment = "cột position_x"},
        {.column = "position_z", .value = "inf", .fragment = "cột position_z"},
        {.column = "position_x", .value = "1e9", .fragment = "cột position_x"},
        {.column = "position_x", .value = "1.5x", .fragment = "cột position_x"},
        {.column = "direction", .value = "100001", .fragment = "cột direction"},
        {.column = "respawn_time", .value = "-2", .fragment = "cột respawn_time"},
        {.column = "is_pet", .value = "2", .fragment = "cột is_pet"},
        {.column = "name", .value = std::string(257, 'a'), .fragment = "cột name"},
        {.column = "name", .value = "\xFF\xFE", .fragment = "UTF-8"},
        {.column = "title", .value = "ab\x01", .fragment = "UTF-8"},
        {.column = "level", .value = "99999999999", .fragment = "cột level"},
    };
    for (const Bad& one : bad) {
        SpawnRow row = good_spawn();
        set(row, one.column, one.value);
        const auto loaded = parse_spawns("spawns.tsv", spawn_text({good_spawn(), row}));
        context.expect(failed_with(loaded, one.fragment), "ô xấu bị từ chối");
        context.expect(failed_with(loaded, "spawns.tsv:"), "lỗi nêu tệp và dòng");
    }
}

void table_structure_and_caps(Context& context) {
    context.expect(failed_with(parse_spawns("a.tsv", ""), "a.tsv"), "bảng rỗng là lỗi");
    // Thiếu cột camp.
    const std::vector<std::string> columns(kSpawnColumns.begin(), kSpawnColumns.end() - 1);
    context.expect(failed_with(parse_spawns("a.tsv", make_table(columns, {})), "camp"), "thiếu cột trong bảng không có dòng");
    std::vector<std::vector<std::string>> one_row;
    const SpawnRow row = good_spawn();
    one_row.emplace_back(row.begin(), row.end() - 1);
    context.expect(failed_with(parse_spawns("a.tsv", make_table(columns, one_row)), "camp"), "thiếu cột bị bắt ở dòng đầu");
    // Dòng thiếu ô (ragged).
    std::string ragged = spawn_text({good_spawn()});
    ragged += "1\t2\n";
    context.expect(!parse_spawns("a.tsv", ragged).has_value(), "dòng thiếu ô");
    // Trần số dòng: chặn trước khi tách.
    const std::string flood(kMaxTableRows + 100, '\n');
    context.expect(failed_with(parse_spawns("a.tsv", flood), "quá nhiều dòng"), "trần số dòng");
    // Trần số cột.
    std::vector<std::string> wide(kMaxColumns + 1, "c");
    for (std::size_t index = 0; index < wide.size(); ++index) wide[index] = "c" + std::to_string(index);
    context.expect(failed_with(parse_spawns("a.tsv", make_table(wide, {})), "quá nhiều cột"), "trần số cột");
    // Bảng không có dòng nào vẫn hợp lệ.
    const std::vector<std::string> full(kSpawnColumns.begin(), kSpawnColumns.end());
    const auto empty = parse_spawns("a.tsv", make_table(full, {}));
    context.expect(empty.has_value() && empty->empty(), "bảng chỉ có tên cột");
}

// ---------- vùng, tuyến tuần, điểm thu thập ----------

void area_bounds_follow_2008(Context& context) {
    const std::vector<std::string> columns{"guid", "script_id", "left", "top", "right", "bottom"};
    const auto good = parse_areas("areas.tsv", make_table(columns, {{"0", "400000", "28", "124", "34", "135"}}));
    context.expect(good.has_value() && good->size() == 1, "vùng hợp lệ");
    if (good) {
        const Area& area = good->front();
        // AreaManager.h 2008: cạnh trái và trên thuộc vùng, cạnh phải và dưới thì không.
        context.expect(area.contains({.x = 28.0F, .z = 124.0F}) && area.contains({.x = 33.99F, .z = 134.99F}), "góc trên trái và mép trong");
        context.expect(!area.contains({.x = 34.0F, .z = 130.0F}) && !area.contains({.x = 30.0F, .z = 135.0F}), "cạnh phải và dưới không thuộc vùng");
        context.expect(!area.contains({.x = 27.99F, .z = 130.0F}) && !area.contains({.x = 30.0F, .z = 123.99F}), "ngoài biên là ngoài vùng");
        context.expect(!area.contains({.x = std::nanf(""), .z = 130.0F}), "NaN không nằm trong vùng");
    }
    // Dữ liệu thật có vùng left > right (taohuadao): nạp được, và là vùng rỗng như mã 2008.
    const auto inverted = parse_areas("areas.tsv", make_table(columns, {{"0", "552", "274", "177", "102", "179"}}));
    context.expect(inverted.has_value() && inverted->size() == 1, "vùng đảo chiều vẫn nạp");
    context.expect(inverted && !inverted->front().contains({.x = 150.0F, .z = 178.0F}) && !inverted->front().contains({.x = 274.0F, .z = 178.0F}),
        "vùng đảo chiều không chứa điểm nào");
    const auto blank_script = parse_areas("areas.tsv", make_table(columns, {{"0", "", "1", "1", "2", "2"}}));
    context.expect(blank_script.has_value() && blank_script->front().script_id == 0, "script_id rỗng là 0");
}

[[nodiscard]] std::vector<std::string> patrol_columns() {
    return {"patrol_index", "point_index", "position_x", "position_y", "position_z", "settle_time", "point_script_id",
        "route_script_id", "turns_back", "teleport_to_respawn", "speech_unread", "speech_1", "speech_2"};
}

void patrol_grouping_and_order(Context& context) {
    // Dòng xáo thứ tự: tuyến 3 điểm 1, tuyến 0 điểm 1, tuyến 3 điểm 0, tuyến 0 điểm 0.
    const std::vector<std::vector<std::string>> rows{
        {"3", "1", "30", "", "31", "", "", "", "", "", "", "", ""},
        {"0", "1", "2", "9.5", "3", "1000", "050031", "7", "1", "0", "", "câu một", ""},
        {"3", "0", "10", "", "11", "", "", "", "", "", "", "", "hai"},
        {"0", "0", "", "", "", "", "", "", "", "", "", "", ""},
    };
    const auto loaded = parse_patrols("patrols.tsv", make_table(patrol_columns(), rows));
    context.expect(loaded.has_value() && loaded->size() == 2, "hai tuyến");
    if (!loaded) return;
    context.expect((*loaded)[0].index == 0 && (*loaded)[1].index == 3, "tuyến sắp theo chỉ số");
    context.expect((*loaded)[0].points.size() == 2 && (*loaded)[1].points.size() == 2, "mỗi tuyến hai điểm");
    const PatrolPoint& origin = (*loaded)[0].points[0];
    context.expect(!origin.position_given && origin.position.x == 0.0F && origin.position.z == 0.0F, "điểm không toạ độ");
    const PatrolPoint& second = (*loaded)[0].points[1];
    context.expect(second.position_given && second.position.x == 2.0F && second.position.z == 3.0F, "toạ độ điểm");
    context.expect(second.height == 9.5F && second.settle_ms == 1000U, "độ cao và thời gian dừng");
    context.expect(second.point_script_id == 50031 && second.route_script_id == 7, "script id bỏ số 0 đầu như atoi");
    context.expect(second.turns_back && !second.teleport_to_respawn, "cờ");
    context.expect(second.speech.size() == 1 && second.speech[0] == "câu một", "câu nói, bỏ ô rỗng");
    context.expect((*loaded)[1].points[0].speech.size() == 1 && (*loaded)[1].points[0].speech[0] == "hai", "speech_2 đứng riêng");
    Scene filled;
    filled.patrols = *loaded;
    const Scene& scene = filled;
    context.expect(scene.find_patrol(3) == &scene.patrols[1] && scene.find_patrol(0) == scene.patrols.data(), "find_patrol");
    context.expect(scene.find_patrol(1) == nullptr && scene.find_patrol(-1) == nullptr, "tuyến không có");
}

void patrol_rejects_hostile_input(Context& context) {
    const auto columns = patrol_columns();
    const auto row_for = [&](std::string patrol, std::string point) {
        std::vector<std::string> row(columns.size(), "");
        row[0] = std::move(patrol);
        row[1] = std::move(point);
        return row;
    };
    context.expect(failed_with(parse_patrols("p.tsv", make_table(columns, {row_for("0", "1"), row_for("0", "1")})), "trùng điểm"),
        "trùng (tuyến, điểm)");
    context.expect(failed_with(parse_patrols("p.tsv", make_table(columns, {row_for("-1", "0")})), "cột patrol_index"),
        "chỉ số tuyến âm");
    std::vector<std::vector<std::string>> many_points;
    for (std::size_t point = 0; point <= kMaxPatrolPoints; ++point) many_points.push_back(row_for("0", std::to_string(point)));
    context.expect(failed_with(parse_patrols("p.tsv", make_table(columns, many_points)), "quá nhiều điểm"), "trần điểm một tuyến");
    std::vector<std::vector<std::string>> many_routes;
    for (std::size_t route = 0; route <= kMaxPatrols; ++route) many_routes.push_back(row_for(std::to_string(route), "0"));
    context.expect(failed_with(parse_patrols("p.tsv", make_table(columns, many_routes)), "quá nhiều tuyến"), "trần số tuyến");
}

void grow_platform_pet_portal_bus(Context& context) {
    const auto points = parse_grow_points("g.tsv",
        make_table({"point_id", "grow_point_type", "position_x", "position_y"}, {{"1", "8", "1.50", "2.25"}}));
    context.expect(points.has_value() && points->front().position.x == 1.5F && points->front().position.z == 2.25F,
        "position_y của điểm thu thập là trục Z");
    const auto rules = parse_grow_rules("r.tsv",
        make_table({"grow_point_type", "max_count", "column_2", "column_3", "column_4", "column_5"},
            {{"620", "1", "1", "", "3900000", "3600000"}}));
    context.expect(rules.has_value() && rules->front().max_count == 1 && rules->front().refill_interval_ms == 3'900'000 &&
                       rules->front().refill_jitter_ms == 3'600'000 && rules->front().control_function.empty(),
        "nhịp bổ sung");
    const auto platforms = parse_platforms("p.tsv",
        make_table({"type_id", "class_id", "position_x", "position_z", "direction", "script_id", "tip"},
            {{"2", "2", "214", "161", "27", "-1", "打造台"}, {"1", "1", "140", "164", "27", "", ""}}));
    context.expect(platforms.has_value() && platforms->size() == 2, "hai bàn chế tác");
    if (platforms) {
        context.expect((*platforms)[0].script_id == -1 && !(*platforms)[1].script_id, "script_id vắng là nullopt");
        context.expect((*platforms)[0].tip == "打造台" && (*platforms)[1].tip.empty(), "tip");
    }
    const auto pets = parse_wild_pets("w.tsv",
        make_table({"guid", "type", "name", "position_x", "position_z", "respawn_time", "ai_file"},
            {{"5201555", "3000", "鹿", "37", "23", "60000", "2"}}));
    context.expect(pets.has_value() && pets->front().guid == 5201555U && pets->front().respawn_ms == 60000, "trân thú hoang");
    const auto portals = parse_portals("p.tsv",
        make_table({"type", "scene_id", "position_x", "position_z", "target_scene_id", "target_position_x",
                       "target_position_z", "target_direction"},
            {{"0", "1", "22.6", "27.4", "0", "17.3", "13.7", "9"}}));
    context.expect(portals.has_value() && portals->front().target_position.z == 13.7F, "cổng dịch chuyển");
    const auto buses = parse_buses("b.tsv",
        make_table({"guid", "data_id", "patrol_id", "reverse"}, {{"1000001", "2", "5", "1"}}));
    context.expect(buses.has_value() && buses->front().reverse && buses->front().patrol_id == 5, "xe buýt");
    const auto levels = parse_spawn_levels("l.tsv", make_table({"monster_index", "level"}, {{"0", "-1"}, {"1", "63"}}));
    context.expect(levels.has_value() && levels->size() == 2 && (*levels)[1].level == 63, "cấp riêng");
}

void operate_tables_reject_paths(Context& context) {
    const std::vector<std::string> columns{"spawn_file", "select_type", "select_value", "data_def", "max_left"};
    const auto good = parse_spawn_operates("o.tsv", make_table(columns, {{"spawns.level_100.tsv", "6", "1", "0", "1"}}));
    context.expect(good.has_value() && good->front().spawn_file == "spawns.level_100.tsv", "operate hợp lệ");
    for (const std::string_view name : {"../spawns.tsv", "a/b.tsv", "a\\b.tsv", "c:x.tsv", ""}) {
        const auto bad = parse_spawn_operates("o.tsv", make_table(columns, {{std::string(name), "6", "1", "0", "1"}}));
        context.expect(failed_with(bad, "spawn_file"), "spawn_file chứa đường dẫn bị từ chối");
    }
    const std::vector<std::string> value_columns{"spawn_file", "data_index", "data_type", "value_index", "value", "value_extra"};
    const auto values = parse_operate_values("v.tsv", make_table(value_columns, {{"spawns.level_100.tsv", "0", "3", "19", "x", ""}}));
    context.expect(values.has_value() && values->front().value_index == 19, "operate_values hợp lệ");
}

// ---------- tên bảng, manifest, lưới đi ----------

void table_name_splitting(Context& context) {
    const auto base = split_table_name("spawns.tsv");
    context.expect(base && base->family == "spawns" && base->label.empty(), "bảng gốc");
    const auto label = split_table_name("spawn_operates.level_100.tsv");
    context.expect(label && label->family == "spawn_operates" && label->label == "level_100", "nhãn");
    const auto dotted = split_table_name("spawns.level_150.alt.tsv");
    context.expect(dotted && dotted->label == "level_150.alt", "nhãn chứa dấu chấm");
    for (const std::string_view bad : {"spawns..tsv", ".tsv", "spawns", "a/b.tsv", "spawns.tsv.bak", "sp awns.tsv", "spawns.\xE9.tsv",
             "..tsv", "a\\b.tsv", ""}) {
        context.expect(!split_table_name(bad).has_value(), "tên bảng xấu bị từ chối");
    }
}

[[nodiscard]] std::string_view valid_manifest() noexcept {
    return "#=====\n# CẢNH TEST\n#=====\nschema           = 1     # phiên bản\n\ngrid_width       = 3\ngrid_height      = 2\n"
           "walk_source      = \"legacy_nav_0859602\"   # nguồn\nwalk             = \"walk.nav\"\n";
}

void manifest_parsing(Context& context) {
    const Loaded<Manifest> good = parse_manifest(valid_manifest());
    context.expect(good.has_value() && good->grid_width == 3U && good->grid_height == 2U, "đọc kích thước lưới");
    context.expect(good && good->walk_source == "legacy_nav_0859602", "đọc walk_source, bỏ chú thích");
    const Loaded<Manifest> plain = parse_manifest("schema = 1\n");
    context.expect(plain.has_value() && !plain->walk_source && !plain->grid_width, "chỉ có schema");
    const std::array<std::pair<std::string_view, std::string_view>, 12> bad{{
        {"grid_width = 3\n", "schema"},
        {"schema = 2\n", "schema"},
        {"schema = \"1\"\n", "schema"},
        {"schema = 1\nschema = 1\n", "lặp"},
        {"schema = 1\nwalk_source = legacy\n", "giá trị"},
        {"schema = 1\nwalk_source = \"a\\b\"\n", "giá trị"},
        {"schema = 1\nwalk_source = \"abc\n", "giá trị"},
        {"schema = 1\nwalk_source = \"a\" x\n", "giá trị"},
        {"schema = 1\nwalk_source = 5\n", "chuỗi"},
        {"schema = 1\ngrid_width = 0\n", "grid_width"},
        {"schema = 1\ngrid_height = 70000\n", "grid_height"},
        {"schema = 1\nnot a key value\n", "khoá = giá trị"},
    }};
    for (const auto& [text, fragment] : bad) {
        context.expect(failed_with(parse_manifest(text), fragment), "manifest xấu bị từ chối");
    }
    std::string many = "schema = 1\n";
    for (std::size_t line = 0; line < kMaxManifestLines; ++line) many += "# c\n";
    context.expect(failed_with(parse_manifest(many), "quá nhiều dòng"), "trần số dòng manifest");
    context.expect(failed_with(parse_manifest(std::string(kMaxManifestBytes + 1, '#')), "quá lớn"), "trần cỡ manifest");
}

// Lưới 3 x 2: hàng 0 có state 0, 1, 2; hàng 1 có 15, 3, 0. Byte đầu của mỗi ô mang thêm nửa byte cao rác (0xA0) mà
// mã 2008 bỏ đi (trường bit state:4).
[[nodiscard]] std::string legacy_bytes() {
    std::string bytes{'\x03', '\x00', '\x02', '\x00'};
    for (const unsigned state : {0U, 1U, 2U, 15U, 3U, 0U}) {
        bytes.push_back(static_cast<char>(0xA0U | state));
        bytes.append(3, '\x7F');
    }
    return bytes;
}

void legacy_grid_lookup(Context& context) {
    const Loaded<LegacyGrid> loaded = parse_legacy_grid(legacy_bytes());
    context.expect(loaded.has_value() && loaded->width == 3 && loaded->height == 2, "đọc đầu tệp");
    if (!loaded) return;
    const LegacyGrid& grid = *loaded;
    struct Probe {
        float x;
        float z;
        int state; // -1: ngoài lưới
    };
    const std::array<Probe, 12> probes{{
        {.x = 0.0F, .z = 0.0F, .state = 0}, {.x = 0.5F, .z = 0.0F, .state = 1}, {.x = 1.0F, .z = 0.0F, .state = 2}, {.x = 1.49F, .z = 0.0F, .state = 2}, {.x = 1.5F, .z = 0.0F, .state = -1},
        {.x = 0.0F, .z = 0.5F, .state = 15}, {.x = 0.5F, .z = 0.5F, .state = 3}, {.x = 1.0F, .z = 0.99F, .state = 0}, {.x = 0.0F, .z = 1.0F, .state = -1}, {.x = -0.1F, .z = 0.0F, .state = -1},
        {.x = std::nanf(""), .z = 0.0F, .state = -1}, {.x = std::numeric_limits<float>::infinity(), .z = 0.0F, .state = -1},
    }};
    for (const Probe& probe : probes) {
        const std::optional<std::uint8_t> got = grid.state_at({.x = probe.x, .z = probe.z});
        context.expect((got ? static_cast<int>(*got) : -1) == probe.state, "state_at theo ô 0,5 đơn vị");
    }
    context.expect(!grid.can_go({.x = 0.5F, .z = 0.0F}, 0) && grid.can_go({.x = 0.5F, .z = 0.0F}, 1), "đi được khi level >= state");
    context.expect(grid.can_go({.x = 0.0F, .z = 0.5F}, 15) && !grid.can_go({.x = 0.0F, .z = 0.5F}, 14), "state 15");
    context.expect(!grid.can_go({.x = 9.0F, .z = 9.0F}, 15) && !grid.can_go({.x = 0.0F, .z = 0.0F}, -1), "ngoài lưới / level âm");
}

void legacy_grid_rejects_hostile_input(Context& context) {
    context.expect(failed_with(parse_legacy_grid(""), "cụt"), "tệp rỗng");
    context.expect(failed_with(parse_legacy_grid(std::string("\x00\x00\x02\x00", 4)), "rỗng"), "rộng bằng 0");
    context.expect(failed_with(parse_legacy_grid(std::string("\x02\x00\x00\x00", 4)), "rỗng"), "cao bằng 0");
    std::string cut = legacy_bytes();
    cut.pop_back();
    context.expect(failed_with(parse_legacy_grid(cut), "cỡ tệp"), "cụt một byte");
    context.expect(failed_with(parse_legacy_grid(legacy_bytes() + "x"), "cỡ tệp"), "thừa một byte");
    // 65535 x 65535 ô: từ chối bằng số học, không cấp phát.
    context.expect(failed_with(parse_legacy_grid(std::string("\xFF\xFF\xFF\xFF", 4)), "quá lớn"), "lưới khổng lồ");
}

// ---------- chọn nguồn lưới đi ----------

[[nodiscard]] std::string path_bytes() {
    const game::test::Bytes bytes = game::test::encode(game::test::Sample{});
    std::string text;
    for (const std::byte one : bytes) text.push_back(static_cast<char>(one));
    return text;
}

void walk_source_choice(Context& context) {
    const std::string path = path_bytes();
    const std::string nav = legacy_bytes();
    const Manifest none;
    // Không khai nguồn: suy từ tệp có mặt, .path thắng.
    const Loaded<Walk> inferred = build_walk(none, path, nav);
    context.expect(inferred.has_value() && inferred->source == WalkSource::kClientPath && inferred->declared.empty(),
        ".path thắng khi không khai");
    context.expect(inferred && inferred->mesh && inferred->grid, "cả hai được nạp");
    const Loaded<Walk> only_nav = build_walk(none, std::nullopt, nav);
    context.expect(only_nav.has_value() && only_nav->source == WalkSource::kLegacyNav, "chỉ có nav");
    const Loaded<Walk> nothing = build_walk(none, std::nullopt, std::nullopt);
    context.expect(nothing.has_value() && nothing->source == WalkSource::kNone && !nothing->walkable({.x = 1.0F, .z = 1.0F}), "không lưới");
    // Khai nguồn.
    Manifest client;
    client.walk_source = "client_2026_path";
    context.expect(build_walk(client, path, std::nullopt).has_value(), "khai client có .path");
    context.expect(failed_with(build_walk(client, std::nullopt, nav), "walk.path"), "khai client mà thiếu .path");
    Manifest legacy;
    legacy.walk_source = "legacy_nav_xjl7457";
    context.expect(build_walk(legacy, std::nullopt, nav).has_value(), "khai nav có walk.nav");
    context.expect(failed_with(build_walk(legacy, path, std::nullopt), "walk.nav"), "khai nav mà thiếu walk.nav");
    Manifest explicit_none;
    explicit_none.walk_source = "none";
    const Loaded<Walk> declared_none = build_walk(explicit_none, std::nullopt, std::nullopt);
    context.expect(declared_none.has_value() && declared_none->source == WalkSource::kNone, "khai none");
    Manifest odd;
    odd.walk_source = "mars_rover";
    context.expect(failed_with(build_walk(odd, path, nav), "walk_source lạ"), "nguồn lạ");
    // Kích thước khai lệch đầu walk.nav.
    Manifest wrong_size;
    wrong_size.grid_width = 4;
    context.expect(failed_with(build_walk(wrong_size, std::nullopt, nav), "lệch"), "grid_width lệch");
    // Tệp dự phòng hỏng vẫn là lỗi.
    context.expect(failed_with(build_walk(client, path, std::string("\x01\x00\x01\x00", 4)), "walk.nav"), "walk.nav hỏng");
    context.expect(failed_with(build_walk(client, std::string("xx"), std::nullopt), "walk.path"), "walk.path hỏng");
}

void walkable_per_source(Context& context) {
    const std::string path = path_bytes();
    Manifest client;
    client.walk_source = "client_2026_path";
    const Loaded<Walk> mesh_walk = build_walk(client, path, std::nullopt);
    context.expect(mesh_walk.has_value(), "dựng lưới tam giác mẫu");
    if (mesh_walk) {
        // Mẫu: hình vuông cạnh 4, nửa x >= z đi được, nửa x < z là vật cản.
        context.expect(mesh_walk->walkable({.x = 3.0F, .z = 1.0F}), "trong tam giác đi được");
        context.expect(!mesh_walk->walkable({.x = 1.0F, .z = 3.0F}), "trong tam giác vật cản");
        context.expect(!mesh_walk->walkable({.x = -1.0F, .z = 1.0F}) && !mesh_walk->walkable({.x = 50.0F, .z = 1.0F}), "ngoài lưới tra");
    }
    Manifest legacy;
    legacy.walk_source = "legacy_nav_0859602";
    const Loaded<Walk> grid_walk = build_walk(legacy, std::nullopt, legacy_bytes());
    context.expect(grid_walk.has_value() && grid_walk->walkable({.x = 0.0F, .z = 0.0F}) && !grid_walk->walkable({.x = 0.5F, .z = 0.0F}),
        "lưới ô: level 0 chỉ đi được ô state 0");
    context.expect(grid_walk && grid_walk->walkable({.x = 0.5F, .z = 0.0F}, 1), "level cao hơn đi được ô state 1");
}

// ---------- cả cảnh ----------

[[nodiscard]] SceneFiles sample_scene() {
    SceneFiles files;
    files.name = "demo";
    files.manifest = valid_manifest();
    SpawnRow near_wall = good_spawn();
    set(near_wall, "position_x", "0.5");
    set(near_wall, "position_z", "0");
    set(near_wall, "patrol_id", "9");
    SpawnRow unplaced = good_spawn();
    set(unplaced, "position_x", "");
    files.tables.push_back({.name = "spawns.level_100.tsv", .text = spawn_text({good_spawn()})});
    files.tables.push_back({.name = "spawns.tsv", .text = spawn_text({near_wall, unplaced})});
    files.tables.push_back({.name = "spawn_operates.level_100.tsv", .text = make_table({"spawn_file", "select_type", "select_value", "data_def", "max_left"}, {{"spawns.level_100.tsv", "6", "1", "0", "1"}})});
    files.tables.push_back({.name = "areas.tsv", .text = make_table({"guid", "script_id", "left", "top", "right", "bottom"}, {{"0", "1", "1", "1", "2", "2"}})});
    files.tables.push_back({.name = "patrols.tsv", .text = make_table(patrol_columns(), {{"0", "0", "1.0", "", "0.0", "", "", "", "", "", "", "", ""}})});
    files.tables.push_back({.name = "mystery.tsv", .text = make_table({"a"}, {{"1"}})});
    files.walk_nav = legacy_bytes();
    return files;
}

void scene_assembly(Context& context) {
    const Loaded<Scene> loaded = parse_scene(sample_scene());
    context.expect(loaded.has_value(), "nạp được cảnh mẫu");
    if (!loaded) return;
    const Scene& scene = *loaded;
    context.expect(scene.name == "demo" && scene.spawns.size() == 2, "bảng gốc");
    context.expect(scene.spawn_variants.size() == 1 && scene.spawn_variants[0].label == "level_100", "bảng theo nhãn");
    context.expect(scene.spawn_operates.size() == 1 && scene.spawn_operates[0].label == "level_100", "operate theo nhãn");
    context.expect(scene.areas.size() == 1 && scene.patrols.size() == 1, "vùng và tuyến");
    context.expect(scene.unread_files == std::vector<std::string>{"mystery.tsv"}, "bảng lạ vào unread_files");
    context.expect(scene.walk.source == WalkSource::kLegacyNav && scene.walk.declared == "legacy_nav_0859602", "nguồn lưới đi");
    // Kiểm chéo: spawn 1 đứng ở (0,5; 0) = ô state 1 (không đi được ở level 0) và trỏ tới tuyến 9 không có;
    // spawn 2 không có vị trí; spawn của bảng level_100 ở (1,5; 2) ngoài lưới 3 x 2 ô = 1,5 x 1 đơn vị.
    const SceneAudit audit = audit_scene(scene);
    context.expect(audit.spawns == 3 && audit.spawns_placed == 2, "đếm quái");
    context.expect(audit.has_walk && audit.spawns_off_walk == 2, "hai quái đứng ngoài chỗ đi được");
    context.expect(audit.has_legacy_grid && audit.spawns_off_legacy_grid == 2, "cùng lưới ô nên cùng hai quái ngoài");
    context.expect(audit.spawns_dangling_patrol == 1, "một tuyến tuần treo");
    context.expect(audit.patrol_points_off_walk == 1, "điểm tuần (1, 0) rơi ô state 2, level 0 không đi được");
}

void scene_is_independent_of_file_order(Context& context) {
    const SceneFiles forward = sample_scene();
    SceneFiles reversed = sample_scene();
    std::ranges::reverse(reversed.tables);
    const auto left = parse_scene(forward);
    const auto right = parse_scene(reversed);
    context.expect(left.has_value() && right.has_value(), "cả hai nạp được");
    if (!left || !right) return;
    context.expect(left->spawns.size() == right->spawns.size() && left->unread_files == right->unread_files, "cùng kết quả");
    context.expect(left->spawn_variants[0].label == right->spawn_variants[0].label, "cùng nhãn");
}

void scene_rejects_inconsistent_files(Context& context) {
    SceneFiles missing_target = sample_scene();
    missing_target.tables.erase(missing_target.tables.begin());
    context.expect(failed_with(parse_scene(missing_target), "spawn_file trỏ tới bảng không có"), "operate trỏ bảng quái vắng");
    SceneFiles twice = sample_scene();
    twice.tables.push_back(twice.tables.front());
    context.expect(failed_with(parse_scene(twice), "lặp"), "bảng lặp");
    SceneFiles bad_name = sample_scene();
    bad_name.tables.push_back({.name = "../evil.tsv", .text = ""});
    context.expect(failed_with(parse_scene(bad_name), "tên bảng"), "tên bảng có đường dẫn");
    SceneFiles no_schema = sample_scene();
    no_schema.manifest = "walk_source = \"none\"\n";
    context.expect(failed_with(parse_scene(no_schema), "schema"), "manifest thiếu schema");
    SceneFiles bad_table = sample_scene();
    bad_table.tables[1].text += "x\n";
    context.expect(!parse_scene(bad_table).has_value(), "một bảng hỏng làm hỏng cả cảnh");
    SceneFiles flood = sample_scene();
    for (std::size_t index = 0; index <= kMaxSceneTables; ++index) flood.tables.push_back({.name = "x" + std::to_string(index) + ".tsv", .text = ""});
    context.expect(failed_with(parse_scene(flood), "quá nhiều bảng"), "trần số bảng");
}

// ---------- luật AI ----------

constexpr std::string_view kRuleColumns = "ai_id\trule_index\tsection\tpriority\ttimes\tpart\tseq\tfunction\top\tvalue\targ_0\targ_1\targ_2\tskill_id\tvalue_name";

[[nodiscard]] std::string rule_table(const std::vector<std::string>& lines) {
    std::string text = "# schema 1\n# types: text\n" + std::string(kRuleColumns) + "\n";
    for (const std::string& line : lines) text += line + "\n";
    return text;
}

[[nodiscard]] std::string file_table(const std::vector<std::string>& lines) {
    std::string text = "# schema 1\n# types: text\nai_id\tfile\ttitle\tdat_name\trules\tin_dat\tin_0859602_index\n";
    for (const std::string& line : lines) text += line + "\n";
    return text;
}

// Sáu luật của kịch bản 7 (rule_index 0, 1, 2, 3, 5, 6; chỉ số 4 là một dòng hỏng đã bị bỏ). Đoạn skill: chỉ số 0 ưu
// tiên 34, 1 và 2 ưu tiên 40, 3 ưu tiên 30 -> thứ tự chạy 1, 2, 0, 3.
[[nodiscard]] std::vector<std::string> sample_rules() {
    return {
        "7\t0\tskill\t34\t1\tif\t0\tis_can_skill\teq\t1\t564\t-1\t-1\t564\t",
        "7\t0\tskill\t34\t1\tdo\t0\tto_skill\t\t0\t564\t-1\t-1\t564\t",
        "7\t1\tskill\t40\t-1\tif\t0\trand\tlt\t50\t-1\t-1\t-1\t-1\t",
        "7\t1\tskill\t40\t-1\tdo\t0\tto_flee\t\t0\t1\t-1\t-1\t-1\t",
        "7\t2\tskill\t40\t2\tif\t0\tget_hp\tlt\t30\t-1\t-1\t-1\t-1\t",
        "7\t2\tskill\t40\t2\tdo\t0\tto_summon\t\t0\t3\t-1\t-1\t-1\t",
        "7\t2\tskill\t40\t2\tdo\t1\tto_speak\t\t0\t8\t-1\t-1\t-1\t",
        "7\t3\tskill\t30\t-1\tif\t0\tget_hp\tge\t1\t-1\t-1\t-1\t-1\t",
        "7\t3\tskill\t30\t-1\tdo\t0\tto_skill\t\t0\t99\t-1\t-1\t99\t",
        "7\t5\tcommon\t-1\t0\tif\t0\tget_ai_state\teq\t6\t-1\t-1\t-1\t-1\tSATTACK",
        "7\t5\tcommon\t-1\t0\tdo\t0\tcall_other_monster_by_group\t\t0\t5\t-1\t-1\t-1\t",
        "7\t6\tdead\t3\t1\tif\t0\tconst\teq\t1\t1\t-1\t-1\t-1\t",
        "7\t6\tdead\t3\t1\tdo\t0\tstart_patrol\t\t0\t-1\t-1\t-1\t-1\t",
    };
}

void ai_rules_order_and_content(Context& context) {
    const auto loaded = parse_ai_rules({.rules = rule_table(sample_rules()), .files = file_table({"7\ts.ai\t\t\t6\t1\t1", "9\tt.ai\t\t\t0\t1\t1"})});
    context.expect(loaded.has_value(), "nạp được bảng luật mẫu");
    if (!loaded) return;
    context.expect(loaded->scripts().size() == 2 && loaded->rule_count() == 6, "hai kịch bản, sáu luật");
    const AiScript* script = loaded->find(7);
    context.expect(script != nullptr && script->rule_count() == 6, "kịch bản 7");
    context.expect(loaded->find(9) != nullptr && loaded->find(9)->rule_count() == 0, "kịch bản không luật vẫn có mặt");
    context.expect(loaded->find(8) == nullptr && loaded->find(-1) == nullptr, "kịch bản không có");
    if (script == nullptr) return;
    const std::span<const AiRule> skill = script->rules(AiSection::kSkill);
    context.expect(skill.size() == 4, "bốn luật ở đoạn skill");
    if (skill.size() == 4) {
        context.expect(skill[0].rule_index == 1 && skill[1].rule_index == 2, "ưu tiên 40 trước, giữ thứ tự tệp khi bằng nhau");
        context.expect(skill[2].rule_index == 0 && skill[3].rule_index == 3, "rồi 34, rồi 30");
        context.expect(skill[0].times == -1 && skill[1].times == 2 && skill[2].times == 1, "số lần");
        context.expect(skill[2].conditions.size() == 1 && skill[2].conditions[0].function == AiFunction::kIsCanSkill &&
                           skill[2].conditions[0].compare == AiCompare::kEq && skill[2].conditions[0].value == 1,
            "điều kiện is_can_skill == 1");
        context.expect(skill[2].actions.size() == 1 && skill[2].actions[0].function == AiFunction::kToSkill &&
                           skill[2].actions[0].args[0] == 564,
            "hành động to_skill(564)");
        context.expect(skill[1].actions.size() == 2 && skill[1].actions[1].function == AiFunction::kToSpeak, "hai hành động giữ thứ tự seq");
        context.expect(skill[0].conditions[0].compare == AiCompare::kLt && skill[0].conditions[0].value == 50, "rand < 50");
    }
    const std::span<const AiRule> common = script->rules(AiSection::kCommon);
    context.expect(common.size() == 1 && common[0].priority == -1 && common[0].times == 0, "đầu luật mặc định");
    context.expect(common[0].conditions[0].value == 6 && common[0].actions[0].function == AiFunction::kCallOtherMonsterByGroup,
        "get_ai_state == SATTACK(6), hàm bản private");
    context.expect(script->rules(AiSection::kBeSkill).empty() && script->rules(AiSection::kDamage).empty(), "đoạn trống");
    context.expect(script->rules(AiSection::kDead).size() == 1 && script->rules(AiSection::kDead)[0].conditions[0].function == AiFunction::kConst,
        "đoạn dead, điều kiện hằng");
}

void ai_rules_reject_bad_tables(Context& context) {
    const std::string files = file_table({"7\ts.ai\t\t\t1\t1\t1"});
    const auto check = [&](const std::vector<std::string>& lines, std::string_view fragment, std::string_view what) {
        context.expect(failed_with(parse_ai_rules({.rules = rule_table(lines), .files = files}), fragment), what);
    };
    const std::string cond = "7\t0\tskill\t34\t1\tif\t0\tis_can_skill\teq\t1\t564\t-1\t-1\t564\t";
    const std::string act = "7\t0\tskill\t34\t1\tdo\t0\tto_skill\t\t0\t564\t-1\t-1\t564\t";
    context.expect(parse_ai_rules({.rules = rule_table({cond, act}), .files = files}).has_value(), "bảng tốt nạp được");
    check({"7\t0\tskill\t34\t1\tif\t0\tmagic_missile\teq\t1\t5\t-1\t-1\t-1\t", act}, "hàm lạ", "tên hàm lạ");
    check({"7\t0\tskill\t34\t1\tif\t0\tto_skill\teq\t1\t5\t-1\t-1\t5\t", act}, "sai vế", "hành động ở vế if");
    check({cond, "7\t0\tskill\t34\t1\tdo\t0\tget_hp\t\t0\t-1\t-1\t-1\t-1\t"}, "sai vế", "điều kiện ở vế do");
    check({"7\t0\tskill\t34\t1\tif\t0\tget_hp\tnear\t1\t-1\t-1\t-1\t-1\t", act}, "so sánh lạ", "so sánh lạ");
    check({cond, "7\t0\tskill\t34\t1\tdo\t0\tto_flee\teq\t0\t1\t-1\t-1\t-1\t"}, "không có so sánh", "hành động có so sánh");
    check({cond, "7\t0\tskill\t34\t1\tdo\t0\tto_flee\t\t5\t1\t-1\t-1\t-1\t"}, "giá trị so sánh", "hành động có value");
    check({cond, "7\t0\tskill\t34\t1\tdo\t0\tto_skill\t\t0\t564\t-1\t-1\t565\t"}, "skill_id", "skill_id lệch arg_0");
    check({cond, "7\t0\tskill\t34\t1\tdo\t0\tto_flee\t\t0\t1\t-1\t-1\t7\t"}, "skill_id", "skill_id ở hàm không mang kỹ năng");
    check({cond, "7\t0\tskill\t34\t2\tdo\t0\tto_skill\t\t0\t564\t-1\t-1\t564\t"}, "đầu luật lệch", "times lệch giữa các dòng");
    check({cond, "7\t0\tskill\t35\t1\tdo\t0\tto_skill\t\t0\t564\t-1\t-1\t564\t"}, "đầu luật lệch", "priority lệch");
    check({cond, "7\t0\tdead\t34\t1\tdo\t0\tto_skill\t\t0\t564\t-1\t-1\t564\t"}, "đầu luật lệch", "section lệch");
    check({cond, act, "7\t0\tskill\t34\t1\tdo\t0\tto_flee\t\t0\t1\t-1\t-1\t-1\t"}, "seq", "seq lặp");
    check({act, cond}, "vế if", "if sau do");
    check({cond, act, "7\t0\tskill\t34\t1\tdo\t1\tto_flee\t\t0\t1\t-1\t-1\t-1\t", "7\t0\tskill\t34\t1\tdo\t5\tto_flee\t\t0\t1\t-1\t-1\t-1\t"},
        "seq", "seq nhảy cóc");
    check({"7\t3\tskill\t34\t1\tif\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t", "7\t2\tskill\t34\t1\tif\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t"},
        "rule_index", "rule_index giảm");
    check({"7\t0\tskill\t34\t1\tif\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t", "7\t0\tskill\t34\t1\tif\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t"},
        "seq", "dòng nguyên tử lặp");
    check({cond, act, "6\t0\tskill\t34\t1\tdo\t0\tto_flee\t\t0\t1\t-1\t-1\t-1\t"}, "sắp ai_id", "ai_id lùi lại");
    check({cond, act, "8\t0\tskill\t34\t1\tif\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t"}, "không nằm trong", "kịch bản không có trong danh sách tệp");
    check({"7\t0\tbogus\t34\t1\tif\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t"}, "đoạn lạ", "đoạn lạ");
    check({"7\t0\tskill\t34\t1\tmaybe\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t"}, "if hoặc do", "part lạ");
    check({"7\t0\tskill\t34\t1\tif\t0\tget_hp\tlt\t\t-1\t-1\t-1\t-1\t"}, "ô rỗng", "value rỗng");
    check({"7\t0\tskill\t34\t1\tif\t0\tget_hp\tlt\tx\t-1\t-1\t-1\t-1\t"}, "cột value", "value chữ");
    context.expect(failed_with(parse_ai_rules({.rules = rule_table({cond, act}), .files = file_table({"7\ts.ai\t\t\t2\t1\t1"})}), "khai 2 luật"),
        "cột rules lệch số luật thật");
    context.expect(failed_with(parse_ai_rules({.rules = rule_table({cond, act}), .files = file_table({"7\ts.ai\t\t\t1\t1\t1", "7\tt.ai\t\t\t1\t1\t1"})}), "lặp"),
        "ai_id lặp trong danh sách tệp");
    context.expect(failed_with(parse_ai_rules({.rules = rule_table({}), .files = file_table({"7\ts.ai\t\t\t1\t1\t1"})}), "khai 1 luật"),
        "danh sách khai luật mà bảng không có");
    context.expect(failed_with(parse_ai_rules({.rules = "", .files = files}), "monster_ai_rules"), "bảng luật rỗng");
}

void ai_rules_caps(Context& context) {
    std::vector<std::string> lines;
    for (std::size_t index = 0; index <= kMaxAiAtomsPerRule; ++index) {
        lines.push_back("7\t0\tskill\t34\t1\tif\t" + std::to_string(index) + "\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t");
    }
    context.expect(failed_with(parse_ai_rules({.rules = rule_table(lines), .files = file_table({"7\ts.ai\t\t\t1\t1\t1"})}), "quá nhiều nguyên tử"),
        "trần nguyên tử một luật");
    std::vector<std::string> many_rules;
    for (std::size_t index = 0; index <= kMaxAiRulesPerScript; ++index) {
        many_rules.push_back("7\t" + std::to_string(index) + "\tskill\t34\t1\tif\t0\tget_hp\tlt\t1\t-1\t-1\t-1\t-1\t");
    }
    context.expect(failed_with(parse_ai_rules({.rules = rule_table(many_rules), .files = file_table({"7\ts.ai\t\t\t4096\t1\t1"})}), "quá nhiều luật"),
        "trần luật một kịch bản");
    const std::string flood(kMaxAiRows + 100, '\n');
    context.expect(failed_with(parse_ai_rules({.rules = flood, .files = file_table({})}), "quá nhiều dòng"), "trần số dòng");
    context.expect(ai_function_from_name("start_patrol") == AiFunction::kStartPatrol && !ai_function_from_name("set_times").has_value(),
        "set_times không phải nguyên tử");
    for (std::uint8_t value = 0; value <= static_cast<std::uint8_t>(AiFunction::kStartPatrol); ++value) {
        const auto function = static_cast<AiFunction>(value);
        context.expect(ai_function_from_name(ai_function_name(function)) == function, "tên hàm đi-về");
    }
}

// ---------- dữ liệu thật ----------

#ifdef GAME_SERVER_DATA
constexpr std::string_view kServerData = GAME_SERVER_DATA;
#else
constexpr std::string_view kServerData;
#endif

[[nodiscard]] std::optional<std::filesystem::path> data_folder(std::string_view relative) {
    if (kServerData.empty()) return std::nullopt;
    std::error_code error;
    std::filesystem::path folder = std::filesystem::path(kServerData) / relative;
    if (!std::filesystem::is_directory(folder, error)) return std::nullopt;
    return folder;
}

struct Totals {
    std::size_t scenes = 0;
    std::size_t spawns = 0;
    std::size_t areas = 0;
    std::size_t patrol_points = 0;
    std::size_t grow_points = 0;
    std::size_t grow_rules = 0;
    std::size_t platforms = 0;
    std::size_t wild_pets = 0;
    std::size_t portals = 0;
    std::size_t buses = 0;
    std::size_t spawn_levels = 0;
    std::size_t operates = 0;
    std::size_t operate_values = 0;
    std::size_t client_path = 0;
    std::size_t legacy_nav = 0;
    std::size_t no_walk = 0;
    std::size_t unread = 0;
};

void add_scene(Totals& totals, const Scene& scene) {
    ++totals.scenes;
    totals.spawns += scene.spawns.size();
    totals.areas += scene.areas.size();
    for (const Variant<Spawn>& variant : scene.spawn_variants) totals.spawns += variant.rows.size();
    for (const Variant<Area>& variant : scene.area_variants) totals.areas += variant.rows.size();
    for (const Patrol& patrol : scene.patrols) totals.patrol_points += patrol.points.size();
    totals.grow_points += scene.grow_points.size();
    totals.grow_rules += scene.grow_rules.size();
    totals.platforms += scene.platforms.size();
    totals.wild_pets += scene.wild_pets.size();
    totals.portals += scene.portals.size();
    totals.buses += scene.buses.size();
    totals.spawn_levels += scene.spawn_levels.size();
    for (const Variant<SpawnOperate>& variant : scene.spawn_operates) totals.operates += variant.rows.size();
    for (const Variant<OperateValue>& variant : scene.operate_values) totals.operate_values += variant.rows.size();
    totals.unread += scene.unread_files.size();
    switch (scene.walk.source) {
    case WalkSource::kClientPath: ++totals.client_path; break;
    case WalkSource::kLegacyNav: ++totals.legacy_nav; break;
    case WalkSource::kNone: ++totals.no_walk; break;
    }
}

void real_ai_rules(Context& context) {
    const auto folder = data_folder("tables/server");
    if (!folder) return;
    const auto loaded = load_ai_rules(*folder);
    context.expect(loaded.has_value(), "nạp được bảng luật AI thật");
    if (!loaded) {
        context.expect(false, loaded.error().what);
        return;
    }
    std::size_t conditions = 0;
    std::size_t actions = 0;
    for (const AiScript& script : loaded->scripts()) {
        for (const std::vector<AiRule>& rules : script.sections) {
            for (const AiRule& rule : rules) {
                conditions += rule.conditions.size();
                actions += rule.actions.size();
            }
        }
    }
    // Số đếm độc lập: ai_convert.py in "tệp 307 luật 1073 điều kiện 2443 hành động 1097".
    context.expect(loaded->scripts().size() == 307, "307 kịch bản");
    context.expect(loaded->rule_count() == 1073 && conditions == 2443 && actions == 1097, "1073 luật, 2443 điều kiện, 1097 hành động");
    // Script 1 (大黄蜂): hai luật; kiểm một kỹ năng đã biết là 581 (chú thích tệp: 中毒(581)).
    const AiScript* wasp = loaded->find(1);
    context.expect(wasp != nullptr && wasp->rule_count() == 2, "script1 có hai luật");
    bool has_poison = false;
    if (wasp != nullptr) {
        for (const std::vector<AiRule>& rules : wasp->sections) {
            for (const AiRule& rule : rules) {
                for (const AiAtom& action : rule.actions) has_poison = has_poison || (action.function == AiFunction::kToSkill && action.args[0] == 581);
            }
        }
    }
    context.expect(has_poison, "script1 dùng kỹ năng 581");
    // Bảng thật (đọc bằng Python): rule_index 0 ưu tiên 30, rule_index 1 ưu tiên 32 -> luật 1 chạy trước.
    const std::span<const AiRule> first = wasp != nullptr ? wasp->rules(AiSection::kSkill) : std::span<const AiRule>{};
    context.expect(first.size() == 2 && first[0].rule_index == 1 && first[0].priority == 32 && first[0].times == 2 &&
                       first[1].rule_index == 0 && first[1].times == -1,
        "script1: luật ưu tiên 32 đứng trước luật ưu tiên 30");
}

// Cộng số kiểm chéo của mọi cảnh. Hai nhóm riêng để đối chiếu với số đếm độc lập: cảnh có walk.nav (bất kể nguồn
// đang dùng) và cảnh dùng walk.nav làm nguồn.
struct AuditSums {
    SceneAudit all;
    std::size_t grid_scenes = 0;
    std::size_t grid_placed = 0;
    std::size_t legacy_source_placed = 0;
    std::size_t legacy_source_off = 0;
};

void add_audit(AuditSums& sums, const Scene& scene, const SceneAudit& audit) {
    sums.all.spawns += audit.spawns;
    sums.all.spawns_placed += audit.spawns_placed;
    sums.all.spawns_off_walk += audit.spawns_off_walk;
    sums.all.spawns_off_legacy_grid += audit.spawns_off_legacy_grid;
    sums.all.spawns_dangling_patrol += audit.spawns_dangling_patrol;
    sums.all.patrol_points_off_walk += audit.patrol_points_off_walk;
    if (audit.has_legacy_grid) {
        ++sums.grid_scenes;
        sums.grid_placed += audit.spawns_placed;
    }
    if (scene.walk.source == WalkSource::kLegacyNav) {
        sums.legacy_source_placed += audit.spawns_placed;
        sums.legacy_source_off += audit.spawns_off_walk;
    }
}

void real_scenes(Context& context) {
    const auto folder = data_folder("scenes");
    if (!folder) return;
    Totals totals;
    AuditSums sums;
    std::vector<std::filesystem::path> directories;
    std::error_code error;
    for (const auto& entry : std::filesystem::directory_iterator(*folder, error)) {
        if (entry.is_directory()) directories.push_back(entry.path());
    }
    std::ranges::sort(directories);
    for (const std::filesystem::path& directory : directories) {
        const Loaded<Scene> loaded = load_scene(directory);
        if (!loaded) {
            context.expect(false, loaded.error().what);
            continue;
        }
        add_scene(totals, *loaded);
        add_audit(sums, *loaded, audit_scene(*loaded));
    }
    const SceneAudit& sum = sums.all;
    std::cout << "[số liệu] " << totals.scenes << " cảnh, " << sum.spawns << " quái (" << sum.spawns_placed
              << " có vị trí); ngoài lưới đang dùng " << sum.spawns_off_walk << ", ngoài walk.nav "
              << sum.spawns_off_legacy_grid << "; " << sum.patrol_points_off_walk << " điểm tuần ngoài\n";
    // Số đếm độc lập bằng Python trên các tệp TSV trong dev/server/scenes (xem TOOLS/server/scene_walk.py): 325 thư
    // mục, 273 có walk_source client_2026_path, 48 + 4 có walk.nav làm nguồn.
    context.expect(totals.scenes == 325, "325 cảnh nạp được");
    context.expect(totals.client_path == 273 && totals.legacy_nav == 52 && totals.no_walk == 0, "nguồn lưới đi từng cảnh");
    context.expect(totals.spawns == 47970 && sum.spawns == 47970, "47970 quái và NPC");
    context.expect(totals.areas == 488 && totals.patrol_points == 3430, "488 vùng, 3430 điểm tuần");
    context.expect(totals.grow_points == 8255 && totals.grow_rules == 242, "8255 điểm thu thập, 242 nhịp bổ sung");
    context.expect(totals.platforms == 116 && totals.wild_pets == 3 && totals.portals == 8 && totals.buses == 6, "bàn chế tác, trân thú, cổng, xe");
    context.expect(totals.spawn_levels == 361 && totals.operates == 423 && totals.operate_values == 2410, "cấp, operate");
    context.expect(sum.spawns_placed == 47938, "47938 quái có vị trí (32 quái bỏ trống ô toạ độ)");
    context.expect(sum.spawns_dangling_patrol == 0, "mọi patrol_id của quái trỏ tới tuyến có thật");
    // Lưới ô 0,5 của 2008: Python độc lập (cùng định dạng, tự tính chỉ số ô và bốn bit thấp) cho 310 cảnh có walk.nav,
    // 45430 quái có vị trí, 3066 quái ngoài ô đi được; riêng 52 cảnh dùng nó làm nguồn: 5766 quái, 1 ngoài. Bộ giải mã
    // lưới và bộ đếm chạy lại đúng số đó.
    // walk.nav bị .gitignore (nguồn Public/Scene không còn nên không sinh lại được); checkout sạch chỉ có 52 tệp được ép vào
    // git, đúng 52 cảnh dùng nó làm nguồn. Số đếm trên cả 310 cảnh chỉ so khi đủ tệp.
    if (sums.grid_scenes == 310) {
        context.expect(sums.grid_placed == 45430 && sum.spawns_off_legacy_grid == 3066,
            "lưới ô: đủ số quái đứng ngoài như Python đếm");
    } else {
        std::cout << "[bỏ qua] " << sums.grid_scenes << "/310 cảnh có walk.nav: bỏ số đếm lưới ô toàn bộ\n";
    }
    context.expect(sums.legacy_source_placed == 5766 && sums.legacy_source_off == 1, "cảnh dùng lưới ô làm nguồn: 1/5766 ngoài");
    // Lưới tam giác của client 2026: không có số đếm độc lập (nav::locate đã có test riêng ở module nav). Quái 0859602
    // đặt theo bố cục cũ nên một phần đứng ngoài lưới 2026 (10,3% khi đo ngày 2026-10-14, chủ yếu quái ở góc (64, 64)
    // của bản sao phó bản và các thành đã dựng lại: docs/SERVER-SCENEDATA.md); chặn hồi quy thô, không phải mục tiêu.
    context.expect(sum.spawns_off_walk * 100 < sum.spawns_placed * 15, "dưới 15% quái đứng ngoài chỗ đi được");
}

constexpr std::array<Case, 23> kCases{{
    {.name = "spawn_fields_and_heading", .body = spawn_fields_and_heading},
    {.name = "spawn_blank_cells_follow_2008", .body = spawn_blank_cells_follow_2008},
    {.name = "spawn_rejects_hostile_cells", .body = spawn_rejects_hostile_cells},
    {.name = "table_structure_and_caps", .body = table_structure_and_caps},
    {.name = "area_bounds_follow_2008", .body = area_bounds_follow_2008},
    {.name = "patrol_grouping_and_order", .body = patrol_grouping_and_order},
    {.name = "patrol_rejects_hostile_input", .body = patrol_rejects_hostile_input},
    {.name = "grow_platform_pet_portal_bus", .body = grow_platform_pet_portal_bus},
    {.name = "operate_tables_reject_paths", .body = operate_tables_reject_paths},
    {.name = "table_name_splitting", .body = table_name_splitting},
    {.name = "manifest_parsing", .body = manifest_parsing},
    {.name = "legacy_grid_lookup", .body = legacy_grid_lookup},
    {.name = "legacy_grid_rejects_hostile_input", .body = legacy_grid_rejects_hostile_input},
    {.name = "walk_source_choice", .body = walk_source_choice},
    {.name = "walkable_per_source", .body = walkable_per_source},
    {.name = "scene_assembly", .body = scene_assembly},
    {.name = "scene_is_independent_of_file_order", .body = scene_is_independent_of_file_order},
    {.name = "scene_rejects_inconsistent_files", .body = scene_rejects_inconsistent_files},
    {.name = "ai_rules_order_and_content", .body = ai_rules_order_and_content},
    {.name = "ai_rules_reject_bad_tables", .body = ai_rules_reject_bad_tables},
    {.name = "ai_rules_caps", .body = ai_rules_caps},
    {.name = "real_ai_rules", .body = real_ai_rules},
    {.name = "real_scenes", .body = real_scenes},
}};

} // namespace
} // namespace game::scenedata::test

int main() {
    return game::test::run_all(game::scenedata::test::kCases);
}
