/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/mount.cpp
 *  PHÂN HỆ   : Figure / Look / Ride
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Luật thú cưỡi (xem mount.hpp). Neo và động tác giữ đúng nhánh của
 *    Obj_Character.cpp 2026; không đổi đơn vị của add_height hay camera_y.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "look/mount.hpp"

#include "look/detail/rows.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::look {
namespace {

using detail::read_all;
using detail::sorted_unique;

constexpr std::size_t kMostRows = 10'000;
constexpr std::int32_t kIntMin = std::numeric_limits<std::int32_t>::min();
constexpr std::int32_t kIntMax = std::numeric_limits<std::int32_t>::max();
// Trần đọc tệp. Exterior_Ride Speed cao nhất trong bảng là 125.
constexpr std::int32_t kSpeedPercentMax = 1000;
constexpr int kSexZero = 0;
constexpr int kPassengerFirst = 1;
constexpr int kPassengerLast = 5;

constexpr std::array<std::string_view, 25> kRideColumns{"id", "name", "passenger_capacity",
    "model_id", "add_height", "ride_recipe", "driver_action_0", "driver_action_1", "anchor_0",
    "passenger_action_0", "passenger_action_1", "anchor_1", "anchor_2", "anchor_3", "anchor_4",
    "anchor_5", "extra_16", "extra_17", "extra_18", "extra_19", "extra_20", "extra_21", "camera_y",
    "effect_id", "speed_percent"};
constexpr std::array<std::string_view, 4> kModelColumns{"model", "mesh", "scale", "action_set"};
constexpr std::array<std::string_view, 9> kOffsetColumns{
    "id", "x", "y", "z", "axis_x", "axis_y", "axis_z", "angle", "label"};
constexpr std::array<std::string_view, 5> kEffectColumns{
    "object", "slot", "effect", "locator", "translate_all"};
constexpr std::array<std::string_view, 5> kEntityColumns{
    "object", "slot", "file", "materials", "condition"};
constexpr std::int32_t kEntitySlotMax = 64;
constexpr std::array<std::string_view, 6> kAnchorNames{
    "anchor_0", "anchor_1", "anchor_2", "anchor_3", "anchor_4", "anchor_5"};
constexpr std::array<std::string_view, 6> kExtraNames{
    "extra_16", "extra_17", "extra_18", "extra_19", "extra_20", "extra_21"};

struct TableSpec {
    std::string_view name;
    std::span<const std::string_view> columns;
};

[[nodiscard]] std::optional<std::string_view> absent_column(const table::Tsv& table,
    std::string_view column) {
    if (table::column_of(table, column)) return std::nullopt;
    return column;
}

[[nodiscard]] std::optional<std::string_view> first_absent(const table::Tsv& table,
    std::span<const std::string_view> columns) {
    for (const std::string_view column : columns) {
        const std::optional<std::string_view> absent = absent_column(table, column);
        if (!absent) continue;
        return absent;
    }
    return std::nullopt;
}

[[nodiscard]] std::string bad_table(std::string_view name, const std::string& why) {
    return std::format("bảng {} sai, {}", name, why);
}

[[nodiscard]] std::string need_column(std::string_view name, std::string_view column) {
    return std::format("bảng {} thiếu cột {}", name, column);
}

[[nodiscard]] std::string too_many(std::string_view name, std::size_t count) {
    return std::format("bảng {} có {} dòng, quá trần {}", name, count, kMostRows);
}

[[nodiscard]] std::expected<table::Tsv, std::string> parse_named(const TableSpec& spec,
    std::string_view text) {
    table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(bad_table(spec.name, parsed.error()));
    const std::optional<std::string_view> missing = first_absent(*parsed, spec.columns);
    if (missing) return std::unexpected(need_column(spec.name, *missing));
    const bool over = parsed->rows.size() > kMostRows;
    if (over) return std::unexpected(too_many(spec.name, parsed->rows.size()));
    return std::move(*parsed);
}

[[nodiscard]] std::string row_failure(std::string_view name, const table::RowReader& reader) {
    return std::format("bảng {} sai, {}", name, reader.error().value_or("lỗi không rõ"));
}

[[nodiscard]] int sex_column(int sex_code) noexcept {
    if (sex_code == kSexZero) return 0;
    return 1;
}

[[nodiscard]] bool is_passenger(int seat) noexcept {
    return seat >= kPassengerFirst && seat <= kPassengerLast;
}

// Chủ, capacity 2 và giới khác 0: neo phụ. Mọi chủ còn lại: neo chính. 0x1405e2160.
[[nodiscard]] std::string_view owner_anchor(const RideRow& row, int owner_sex) noexcept {
    const bool takes_secondary = row.passenger_capacity == 2 && owner_sex != kSexZero;
    if (takes_secondary) return row.anchors[1];
    return row.anchors[0];
}

// Khách trên thú đôi: giới chủ 0 lấy neo phụ, khác 0 lấy neo chính. 0x1405e5490.
[[nodiscard]] std::string_view double_passenger_anchor(const RideRow& row, int owner_sex) noexcept {
    if (owner_sex == kSexZero) return row.anchors[1];
    return row.anchors[0];
}

[[nodiscard]] std::string_view listed_anchor(const RideRow& row, int seat) noexcept {
    if (!is_passenger(seat)) return {};
    return row.anchors[static_cast<std::size_t>(seat)];
}

[[nodiscard]] std::string_view passenger_anchor(const RideRow& row, int owner_sex,
    int seat) noexcept {
    if (row.passenger_capacity == 2) return double_passenger_anchor(row, owner_sex);
    return listed_anchor(row, seat);
}

void read_anchors(table::RowReader& reader, RideRow& row) {
    for (std::size_t seat = 0; seat < row.anchors.size(); ++seat) {
        row.anchors[seat] = std::string(reader.text(kAnchorNames[seat]));
    }
}

void read_extras(table::RowReader& reader, RideRow& row) {
    for (std::size_t column = 0; column < row.extra.size(); ++column) {
        row.extra[column] = reader.integer(kExtraNames[column], kIntMin, kIntMax);
    }
}

using RideRows = std::expected<std::vector<RideRow>, std::string>;
using ModelRows = std::expected<std::vector<RideModel>, std::string>;
using OffsetRows = std::expected<std::vector<RideOffset>, std::string>;

[[nodiscard]] RideRows read_rides(std::string_view text) {
    const auto table = parse_named({.name = "rides", .columns = kRideColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<RideRow> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        RideRow row;
        row.id = reader.integer("id", 0, kIntMax);
        row.name = std::string(reader.text("name"));
        row.passenger_capacity = reader.integer("passenger_capacity", 0, 32);
        row.model_id = reader.integer("model_id", -1, kIntMax);
        row.add_height = reader.real("add_height");
        row.ride_recipe = reader.integer("ride_recipe", kIntMin, kIntMax);
        row.driver_action[0] = reader.integer("driver_action_0", kIntMin, kIntMax);
        row.driver_action[1] = reader.integer("driver_action_1", kIntMin, kIntMax);
        row.passenger_action[0] = reader.integer("passenger_action_0", kIntMin, kIntMax);
        row.passenger_action[1] = reader.integer("passenger_action_1", kIntMin, kIntMax);
        read_anchors(reader, row);
        read_extras(reader, row);
        row.camera_y = reader.real("camera_y");
        row.effect_id = reader.integer("effect_id", kIntMin, kIntMax);
        row.speed_percent = reader.integer("speed_percent", 0, kSpeedPercentMax);
        if (reader.error()) return std::unexpected(row_failure("rides", reader));
        rows.push_back(std::move(row));
    }
    RideRows made = std::move(rows);
    const auto key = [](const RideRow& row) { return row.id; };
    return sorted_unique(std::move(made), key, "rides");
}

[[nodiscard]] ModelRows read_models(std::string_view text) {
    const auto table = parse_named({.name = "ride_models", .columns = kModelColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<RideModel> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        RideModel row;
        row.id = reader.integer("model", 0, kIntMax);
        row.mesh = std::string(reader.text("mesh"));
        row.scale = reader.positive("scale");
        row.action_set = reader.integer("action_set", -1, kIntMax);
        if (!reader.error() && row.mesh.empty()) reader.reject("mesh", "thiếu lưới");
        if (reader.error()) return std::unexpected(row_failure("ride_models", reader));
        rows.push_back(std::move(row));
    }
    ModelRows made = std::move(rows);
    const auto key = [](const RideModel& row) { return row.id; };
    return sorted_unique(std::move(made), key, "ride_models");
}

[[nodiscard]] OffsetRows read_offsets(std::string_view text) {
    const auto table = parse_named({.name = "ride_offsets", .columns = kOffsetColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<RideOffset> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        RideOffset row;
        row.id = reader.integer("id", 0, kIntMax);
        row.x = reader.real("x");
        row.y = reader.real("y");
        row.z = reader.real("z");
        row.axis_x = reader.real("axis_x");
        row.axis_y = reader.real("axis_y");
        row.axis_z = reader.real("axis_z");
        row.angle = reader.real("angle");
        row.label = std::string(reader.text("label"));
        if (reader.error()) return std::unexpected(row_failure("ride_offsets", reader));
        rows.push_back(std::move(row));
    }
    OffsetRows made = std::move(rows);
    const auto key = [](const RideOffset& row) { return row.id; };
    return sorted_unique(std::move(made), key, "ride_offsets");
}

[[nodiscard]] const RideRow* find_sorted(std::span<const RideRow> rows, std::int32_t id) noexcept {
    const auto found = std::ranges::lower_bound(rows, id, {}, &RideRow::id);
    if (found == rows.end() || found->id != id) return nullptr;
    return &*found;
}

[[nodiscard]] const RideModel* find_sorted(std::span<const RideModel> rows,
    std::int32_t id) noexcept {
    const auto found = std::ranges::lower_bound(rows, id, {}, &RideModel::id);
    if (found == rows.end() || found->id != id) return nullptr;
    return &*found;
}

[[nodiscard]] RideEffect read_effect_row(table::RowReader& reader) {
    RideEffect row;
    row.object = std::string(reader.text("object"));
    row.slot = std::string(reader.text("slot"));
    row.effect = std::string(reader.text("effect"));
    row.locator = std::string(reader.text("locator"));
    row.translate_all = reader.flag("translate_all");
    if (!reader.error() && row.object.empty()) reader.reject("object", "thiếu mẫu");
    if (!reader.error() && row.slot.empty()) reader.reject("slot", "thiếu tên");
    if (!reader.error() && row.effect.empty()) reader.reject("effect", "thiếu tên");
    if (!reader.error() && row.locator.empty()) reader.reject("locator", "thiếu điểm");
    return row;
}

[[nodiscard]] bool same_slot(const RideEffect& left, const RideEffect& right) {
    return left.object == right.object && left.slot == right.slot;
}

[[nodiscard]] std::string slot_clash(const RideEffect& row) {
    return std::format("bảng ride_effects trùng {} / {}", row.object, row.slot);
}

[[nodiscard]] std::optional<std::string> earlier_slot(std::span<const RideEffect> rows,
    std::size_t index) {
    for (std::size_t earlier = 0; earlier < index; ++earlier) {
        if (same_slot(rows[earlier], rows[index])) return slot_clash(rows[index]);
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<std::string> repeated_slot(std::span<const RideEffect> rows) {
    for (std::size_t index = 1; index < rows.size(); ++index) {
        const std::optional<std::string> clash = earlier_slot(rows, index);
        if (clash) return clash;
    }
    return std::nullopt;
}

[[nodiscard]] RideEntity read_entity_row(table::RowReader& reader) {
    RideEntity row;
    row.object = std::string(reader.text("object"));
    row.slot = reader.integer("slot", 0, kEntitySlotMax);
    row.file = std::string(reader.text("file"));
    row.materials = std::string(reader.text("materials"));
    row.condition = std::string(reader.text("condition"));
    if (!reader.error() && row.object.empty()) reader.reject("object", "thiếu mẫu");
    if (!reader.error() && row.file.empty()) reader.reject("file", "thiếu lưới");
    return row;
}

[[nodiscard]] bool same_entity(const RideEntity& left, const RideEntity& right) {
    return left.object == right.object && left.slot == right.slot;
}

[[nodiscard]] std::string entity_clash(const RideEntity& row) {
    return std::format("bảng ride_entities trùng {} / {}", row.object, row.slot);
}

[[nodiscard]] std::optional<std::string> earlier_entity(std::span<const RideEntity> rows,
    std::size_t index) {
    for (std::size_t earlier = 0; earlier < index; ++earlier) {
        if (same_entity(rows[earlier], rows[index])) return entity_clash(rows[index]);
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<std::string> repeated_entity(std::span<const RideEntity> rows) {
    for (std::size_t index = 1; index < rows.size(); ++index) {
        const std::optional<std::string> clash = earlier_entity(rows, index);
        if (clash) return clash;
    }
    return std::nullopt;
}

using EffectRows = std::expected<std::vector<RideEffect>, std::string>;
using EntityRows = std::expected<std::vector<RideEntity>, std::string>;

[[nodiscard]] EffectRows read_effects(std::string_view text) {
    const auto table = parse_named({.name = "ride_effects", .columns = kEffectColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<RideEffect> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        RideEffect row = read_effect_row(reader);
        if (reader.error()) return std::unexpected(row_failure("ride_effects", reader));
        rows.push_back(std::move(row));
    }
    const std::optional<std::string> clash = repeated_slot(rows);
    if (clash) return std::unexpected(*clash);
    return rows;
}

[[nodiscard]] EntityRows read_entities(std::string_view text) {
    const auto table = parse_named({.name = "ride_entities", .columns = kEntityColumns}, text);
    if (!table) return std::unexpected(table.error());
    std::vector<RideEntity> rows;
    rows.reserve(table->rows.size());
    for (std::size_t at = 0; at < table->rows.size(); ++at) {
        table::RowReader reader(*table, at);
        RideEntity row = read_entity_row(reader);
        if (reader.error()) return std::unexpected(row_failure("ride_entities", reader));
        rows.push_back(std::move(row));
    }
    const std::optional<std::string> clash = repeated_entity(rows);
    if (clash) return std::unexpected(*clash);
    return rows;
}

[[nodiscard]] const RideOffset* find_sorted(std::span<const RideOffset> rows,
    std::int32_t id) noexcept {
    const auto found = std::ranges::lower_bound(rows, id, {}, &RideOffset::id);
    if (found == rows.end() || found->id != id) return nullptr;
    return &*found;
}

} // namespace

const RideRow* RideTables::find_ride(std::int32_t id) const noexcept {
    return find_sorted(rides, id);
}

const RideModel* RideTables::find_model(std::int32_t id) const noexcept {
    return find_sorted(models, id);
}

const RideOffset* RideTables::find_offset(std::int32_t id) const noexcept {
    return find_sorted(offsets, id);
}

std::expected<RideTables, std::string> parse_ride_tables(const RideTexts& texts) {
    RideTables tables;
    auto rides = read_rides(texts.rides);
    if (!rides) return std::unexpected(rides.error());
    tables.rides = std::move(*rides);
    auto models = read_models(texts.models);
    if (!models) return std::unexpected(models.error());
    tables.models = std::move(*models);
    auto offsets = read_offsets(texts.offsets);
    if (!offsets) return std::unexpected(offsets.error());
    tables.offsets = std::move(*offsets);
    return tables;
}

[[nodiscard]] std::string unread(std::string_view file, const std::string& why) {
    return std::format("không đọc được {}: {}", file, why);
}

[[nodiscard]] std::expected<std::string, std::string> read_named(std::string_view folder,
    std::string_view file, const ReadFile& read) {
    const std::string path = std::format("{}/{}", folder, file);
    auto text = read(path);
    if (!text) return std::unexpected(unread(file, text.error()));
    return std::move(*text);
}

std::expected<std::vector<RideEffect>, std::string> parse_ride_effects(std::string_view text) {
    return read_effects(text);
}

std::expected<std::vector<RideEntity>, std::string> parse_ride_entities(std::string_view text) {
    return read_entities(text);
}

std::vector<const RideEffect*> effects_of(std::span<const RideEffect> rows,
    std::string_view object) {
    std::vector<const RideEffect*> found;
    for (const RideEffect& row : rows) {
        if (row.object != object) continue;
        found.push_back(&row);
    }
    return found;
}

std::vector<const RideEntity*> entities_of(std::span<const RideEntity> rows,
    std::string_view object) {
    std::vector<const RideEntity*> found;
    for (const RideEntity& row : rows) {
        if (row.object != object) continue;
        found.push_back(&row);
    }
    return found;
}

std::expected<RideTables, std::string> load_ride_tables(std::string_view folder,
    const ReadFile& read) {
    auto rides = read_named(folder, "rides.tsv", read);
    if (!rides) return std::unexpected(rides.error());
    auto models = read_named(folder, "ride_models.tsv", read);
    if (!models) return std::unexpected(models.error());
    auto offsets = read_named(folder, "ride_offsets.tsv", read);
    if (!offsets) return std::unexpected(offsets.error());
    const RideTexts texts{.rides = *rides, .models = *models, .offsets = *offsets};
    return parse_ride_tables(texts);
}

std::string_view anchor_of(const RideRow& row, int owner_sex, int seat) noexcept {
    if (seat < kRideOwner || seat >= kRideSeats) return {};
    if (seat == kRideOwner) return owner_anchor(row, owner_sex);
    return passenger_anchor(row, owner_sex, seat);
}

std::int32_t rider_action_of(const RideRow& row, int rider_sex, int seat) noexcept {
    const int column = sex_column(rider_sex);
    if (is_passenger(seat)) return row.passenger_action[static_cast<std::size_t>(column)];
    return row.driver_action[static_cast<std::size_t>(column)];
}

const RideOffset* halo_of(const RideTables& tables, const RideRow& row) noexcept {
    if (row.effect_id < 0) return nullptr;
    return tables.find_offset(row.effect_id);
}

[[nodiscard]] std::string missing_ride(std::int32_t id) {
    return std::format("thú cưỡi {} không có trong bảng", id);
}

[[nodiscard]] std::string bare_ride(std::int32_t id) {
    return std::format("thú cưỡi {} không có mô hình", id);
}

[[nodiscard]] std::string missing_model(std::int32_t ride, std::int32_t model) {
    return std::format("thú cưỡi {} trỏ mô hình {} không có", ride, model);
}

std::expected<RideFigure, std::string> ride_figure(const RideTables& tables, std::int32_t mount_id,
    int owner_sex, int rider_sex, int seat) {
    const RideRow* row = tables.find_ride(mount_id);
    if (row == nullptr) return std::unexpected(missing_ride(mount_id));
    if (row->model_id < 0) return std::unexpected(bare_ride(mount_id));
    const RideModel* model = tables.find_model(row->model_id);
    if (model == nullptr) return std::unexpected(missing_model(mount_id, row->model_id));
    RideFigure made;
    made.id = row->id;
    made.name = row->name;
    made.model_id = model->id;
    made.mesh = model->mesh;
    made.model_scale = model->scale;
    made.add_height = row->add_height;
    made.camera_y = row->camera_y;
    made.speed_percent = row->speed_percent;
    made.anchor = std::string(anchor_of(*row, owner_sex, seat));
    made.rider_action = rider_action_of(*row, rider_sex, seat);
    if (made.rider_action < 0) made.rider_action = model->action_set;
    made.model_action = model->action_set;
    const RideOffset* offset = halo_of(tables, *row);
    if (offset != nullptr) made.offset = *offset;
    return made;
}

} // namespace game::look
