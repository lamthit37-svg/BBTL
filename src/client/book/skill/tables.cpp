// Bộ đọc và hàm tra của các bảng sách võ công (xem tables.hpp).
#include "skill/tables.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::skill {
namespace {

constexpr std::int32_t kLowest = std::numeric_limits<std::int32_t>::min();
constexpr std::int32_t kHighest = std::numeric_limits<std::int32_t>::max();
// Chuỗi GetIconFullName trả khi bảng không có icon (UI_CEGUI.dll 0x18001c806).
constexpr std::string_view kNoIcon = "set:X image:X";
// Chỗ điền trần cấp trong mô tả tâm pháp.
constexpr std::string_view kCapMark = "%d";
// Ô limit_exp của bảng lên cấp là trần độ thuần thục nhân 100.
constexpr std::int32_t kExpScale = 100;

[[nodiscard]] std::int32_t whole(table::RowReader& reader, std::string_view column) {
    return reader.integer(column, kLowest, kHighest);
}

// Mọi dòng của table qua parse, theo thứ tự của tệp; dừng ở dòng lỗi đầu tiên.
template <typename Row, typename Parse>
[[nodiscard]] std::expected<std::vector<Row>, std::string> read_rows(const table::Tsv& table, Parse parse) {
    std::vector<Row> rows;
    rows.reserve(table.rows.size());
    for (std::size_t index = 0; index < table.rows.size(); ++index) {
        table::RowReader reader(table, index);
        rows.push_back(parse(reader));
        if (reader.error()) return std::unexpected(*reader.error());
    }
    return rows;
}

// Xếp tăng theo khoá, khoá lặp giữ dòng gặp trước (bảng DBC gốc chèn vào bảng băm, không ghi đè).
template <typename Row, typename Key>
void keep_first(std::vector<Row>& rows, Key key) {
    std::ranges::stable_sort(rows, {}, key);
    const auto repeats = std::ranges::unique(rows, {}, key);
    rows.erase(repeats.begin(), repeats.end());
}

template <typename Row>
[[nodiscard]] const Row* row_by_id(const std::vector<Row>& rows, std::int32_t id) noexcept {
    const auto found = std::ranges::lower_bound(rows, id, {}, &Row::id);
    if (found == rows.end() || found->id != id) return nullptr;
    return &*found;
}

// Khoá của một dòng bảng lên cấp: tên bảng rồi cấp.
using LevelKey = std::pair<std::string_view, std::int32_t>;

[[nodiscard]] LevelKey level_key(const LifeLevelRow& row) noexcept {
    return {row.table, row.level};
}

[[nodiscard]] std::string_view icon_key(const IconRow& row) noexcept {
    return row.icon;
}

// Tên mười cột số liệu của formation_levels.tsv, theo thứ tự cột của ZhenFaStr.
constexpr std::array<std::string_view, kFormationValues> kFormationColumns = {"life_low", "life_high",
    "pierce_attack_low", "pierce_attack_high", "pierce_defence_low", "pierce_defence_high", "hit_low", "hit_high",
    "critical", "column_10"};

// Ô đầu và số ô của từng trận pháp trong FormationRow::values (0x14039a47b và ba nhánh kế).
struct ValueRange {
    std::size_t first = 0;
    std::size_t count = 0;
};

constexpr std::array<ValueRange, kFormations> kFormationRanges = {{
    {.first = 0, .count = 2},
    {.first = 2, .count = 2},
    {.first = 4, .count = 2},
    {.first = 6, .count = 4},
}};

// Tên các cột data_0..data_30 của skills.tsv.
using DataColumns = std::array<std::string, kDataTiers>;

[[nodiscard]] DataColumns data_columns() {
    DataColumns columns;
    for (std::size_t tier = 0; tier < kDataTiers; ++tier)
        columns.at(tier) = std::format("data_{}", tier);
    return columns;
}

[[nodiscard]] SkillRow parse_skill(table::RowReader& reader, const DataColumns& columns) {
    SkillRow row;
    row.id = whole(reader, "id");
    row.sect = whole(reader, "sect");
    row.inner_art_level = whole(reader, "inner_art_level");
    row.inner_art = whole(reader, "inner_art");
    row.level_offset = whole(reader, "level_offset");
    row.user_class = whole(reader, "user_class");
    row.passivity = whole(reader, "passivity");
    row.must_learn = whole(reader, "must_learn");
    row.column_101 = whole(reader, "column_101");
    for (std::size_t tier = 0; tier < kDataTiers; ++tier)
        row.data.at(tier) = whole(reader, columns.at(tier));
    row.name = reader.text("name");
    row.icon = reader.text("icon");
    row.explain = reader.text("explain");
    return row;
}

// Tên hai cột money_k, exp_k của một tâm pháp trong inner_art_learn_costs.tsv.
struct CostColumns {
    std::string money;
    std::string exp;
};

[[nodiscard]] std::vector<CostColumns> cost_columns() {
    std::vector<CostColumns> columns;
    columns.reserve(kCostArts);
    for (std::size_t art = 0; art < kCostArts; ++art) {
        columns.push_back(CostColumns{.money = std::format("money_{}", art), .exp = std::format("exp_{}", art)});
    }
    return columns;
}

[[nodiscard]] LearnCostRow parse_cost(table::RowReader& reader, std::span<const CostColumns> columns) {
    LearnCostRow row;
    row.level = whole(reader, "level");
    for (std::size_t art = 0; art < columns.size() && art < kCostArts; ++art) {
        const CostColumns& names = columns[art];
        row.costs.at(art) = LearnCost{.money = whole(reader, names.money), .exp = whole(reader, names.exp)};
    }
    return row;
}

} // namespace

SkillRows read_skills(const table::Tsv& table) {
    const DataColumns columns = data_columns();
    const auto parse = [&columns](table::RowReader& reader) { return parse_skill(reader, columns); };
    SkillRows rows = read_rows<SkillRow>(table, parse);
    if (rows) keep_first(*rows, &SkillRow::id);
    return rows;
}

LevelRows read_skill_levels(const table::Tsv& table) {
    const auto parse = [](table::RowReader& reader) {
        LevelRow row;
        row.id = whole(reader, "id");
        row.description = reader.text("description");
        return row;
    };
    LevelRows rows = read_rows<LevelRow>(table, parse);
    if (rows) keep_first(*rows, &LevelRow::id);
    return rows;
}

InnerArtRows read_inner_arts(const table::Tsv& table) {
    const auto parse = [](table::RowReader& reader) {
        InnerArtRow row;
        row.id = whole(reader, "id");
        row.sect = whole(reader, "sect");
        row.need_level = whole(reader, "need_level");
        row.name = reader.text("name");
        row.explain = reader.text("explain");
        row.icon = reader.text("icon");
        return row;
    };
    InnerArtRows rows = read_rows<InnerArtRow>(table, parse);
    if (rows) keep_first(*rows, &InnerArtRow::id);
    return rows;
}

LearnCostRows read_learn_costs(const table::Tsv& table) {
    const std::vector<CostColumns> columns = cost_columns();
    const auto parse = [&columns](table::RowReader& reader) { return parse_cost(reader, columns); };
    return read_rows<LearnCostRow>(table, parse);
}

LifeSkillRows read_life_skills(const table::Tsv& table) {
    const auto parse = [](table::RowReader& reader) {
        LifeSkillRow row;
        row.id = whole(reader, "id");
        row.max_level = whole(reader, "max_level");
        row.popup = whole(reader, "popup");
        row.consume = whole(reader, "consume");
        row.name = reader.text("name");
        row.level_table = reader.text("level_table");
        row.icon = reader.text("icon");
        row.explain = reader.text("explain");
        return row;
    };
    LifeSkillRows rows = read_rows<LifeSkillRow>(table, parse);
    if (rows) keep_first(*rows, &LifeSkillRow::id);
    return rows;
}

LifeLevelRows read_life_levels(const table::Tsv& table) {
    const auto parse = [](table::RowReader& reader) {
        LifeLevelRow row;
        row.table = reader.text("table");
        row.level = whole(reader, "level");
        row.limit_exp = whole(reader, "limit_exp");
        return row;
    };
    LifeLevelRows rows = read_rows<LifeLevelRow>(table, parse);
    if (rows) keep_first(*rows, &level_key);
    return rows;
}

FormationRows read_formation_levels(const table::Tsv& table) {
    const auto parse = [](table::RowReader& reader) {
        FormationRow row;
        row.level = whole(reader, "level");
        for (std::size_t index = 0; index < kFormationValues; ++index) {
            row.values.at(index) = whole(reader, kFormationColumns.at(index));
        }
        return row;
    };
    FormationRows rows = read_rows<FormationRow>(table, parse);
    if (rows) keep_first(*rows, &FormationRow::level);
    return rows;
}

IconRows read_icons(const table::Tsv& table) {
    const auto parse = [](table::RowReader& reader) {
        IconRow row;
        row.icon = reader.text("icon");
        row.imageset = reader.text("imageset");
        return row;
    };
    IconRows rows = read_rows<IconRow>(table, parse);
    if (rows) keep_first(*rows, &icon_key);
    return rows;
}

const SkillRow* skill_row(const Tables& tables, std::int32_t id) noexcept {
    return row_by_id(tables.skills, id);
}

const LevelRow* level_row(const Tables& tables, std::int32_t id) noexcept {
    return row_by_id(tables.levels, id);
}

const InnerArtRow* inner_art_row(const Tables& tables, std::int32_t id) noexcept {
    return row_by_id(tables.inner_arts, id);
}

const LifeSkillRow* life_skill_row(const Tables& tables, std::int32_t id) noexcept {
    return row_by_id(tables.life_skills, id);
}

const FormationRow* formation_row(const Tables& tables, std::int32_t level) noexcept {
    const auto found = std::ranges::lower_bound(tables.formations, level, {}, &FormationRow::level);
    if (found == tables.formations.end() || found->level != level) return nullptr;
    return &*found;
}

std::span<const std::int32_t> formation_values(const FormationRow& row, std::size_t formation) noexcept {
    if (formation >= kFormations) return {};
    const ValueRange range = kFormationRanges.at(formation);
    return std::span<const std::int32_t>(row.values).subspan(range.first, range.count);
}

std::optional<LearnCost> learn_cost(const Tables& tables, const AtLevel& ask) noexcept {
    if (ask.id < 0 || std::cmp_greater_equal(ask.id, kCostArts)) return std::nullopt;
    const auto found = std::ranges::find(tables.learn_costs, ask.level, &LearnCostRow::level);
    if (found == tables.learn_costs.end()) return std::nullopt;
    return found->costs.at(static_cast<std::size_t>(ask.id));
}

std::int32_t life_limit_exp(const Tables& tables, const AtLevel& ask) noexcept {
    const LifeSkillRow* skill = life_skill_row(tables, ask.id);
    if (skill == nullptr) return kNone;
    const LevelKey wanted(skill->level_table, ask.level);
    const auto found = std::ranges::lower_bound(tables.life_levels, wanted, {}, &level_key);
    if (found == tables.life_levels.end() || level_key(*found) != wanted) return kNone;
    return found->limit_exp / kExpScale;
}

std::string icon_full_name(std::span<const IconRow> icons, std::string_view icon) {
    const auto found = std::ranges::lower_bound(icons, icon, {}, &icon_key);
    if (found == icons.end() || found->icon != icon) return std::string(kNoIcon);
    return std::format("set:{} image:{}", found->imageset, icon);
}

std::string fill_cap(std::string_view explain, std::int32_t cap) {
    const std::size_t at = explain.find(kCapMark);
    if (at == std::string_view::npos) return std::string(explain);
    return std::format("{}{}{}", explain.substr(0, at), cap, explain.substr(at + kCapMark.size()));
}

} // namespace game::skill
