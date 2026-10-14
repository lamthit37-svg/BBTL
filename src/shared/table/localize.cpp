// Thay ô của bảng theo bản dịch (xem localize.hpp).
#include "table/localize.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::table {
namespace {

constexpr std::string_view kTableSuffix = ".tsv";
// Hai bảng chữ giao diện mà <bảng>.lang.tsv là bảng khoá-chữ của gui::StringBook.
constexpr std::array<std::string_view, 2> kTextBooks = {"ui_strings.tsv", "scene_names.tsv"};

// Cột của bản dịch.
struct LangColumns {
    std::size_t id = 0;
    std::size_t column = 0;
    std::size_t text = 0;
};

[[nodiscard]] std::expected<LangColumns, std::string> lang_columns(const Tsv& lang) {
    const std::optional<std::size_t> id = column_of(lang, "id");
    const std::optional<std::size_t> column = column_of(lang, "column");
    const std::optional<std::size_t> text = column_of(lang, "text");
    if (!id || !column || !text) return std::unexpected(std::string("bản dịch bảng thiếu cột id, column hay text"));
    return LangColumns{.id = *id, .column = *column, .text = *text};
}

// Id -> chỉ số dòng; id lặp giữ dòng gặp trước. Khoá trỏ vào ô cột key của table, nên cột đó không
// được đổi khi bảng tra còn dùng.
using RowIndex = std::unordered_map<std::string_view, std::size_t>;

[[nodiscard]] RowIndex index_rows(const Tsv& table, std::size_t key) {
    RowIndex rows;
    rows.reserve(table.rows.size());
    for (std::size_t row = 0; row < table.rows.size(); ++row) {
        rows.try_emplace(table.rows[row].at(key), row);
    }
    return rows;
}

// Bảng đang dịch, bảng tra id của nó và cột khoá.
struct Target {
    Tsv* table = nullptr;
    const RowIndex* rows = nullptr;
    std::size_t key = 0;
};

// Ghi chữ của một dòng bản dịch vào ô (id, column); false khi bảng không có id hay cột đó, hay đó là cột
// khoá (bảng tra id trỏ vào chính các ô ấy).
[[nodiscard]] bool put(const Target& target, const std::vector<std::string>& cells, const LangColumns& columns) {
    const auto found = target.rows->find(cells.at(columns.id));
    const std::optional<std::size_t> cell = column_of(*target.table, cells.at(columns.column));
    if (found == target.rows->end() || !cell || *cell == target.key) return false;
    target.table->rows.at(found->second).at(*cell) = cells.at(columns.text);
    return true;
}

} // namespace

LocalizeResult localize(Tsv& table, const Tsv& lang, std::string_view id_column) {
    const std::optional<std::size_t> key = column_of(table, id_column);
    if (!key) return std::unexpected(std::format("bảng không có cột khoá {}", id_column));
    const auto columns = lang_columns(lang);
    if (!columns) return std::unexpected(columns.error());
    const RowIndex rows = index_rows(table, *key);
    const Target target{.table = &table, .rows = &rows, .key = *key};
    LocalizeCount count;
    for (const auto& cells : lang.rows) {
        const bool is_put = put(target, cells, *columns);
        count.applied += is_put ? 1 : 0;
        count.missed += is_put ? 0 : 1;
    }
    return count;
}

std::string lang_name(std::string_view name) {
    if (!name.ends_with(kTableSuffix) || name.ends_with(kLangSuffix)) return {};
    if (std::ranges::find(kTextBooks, name) != kTextBooks.end()) return {};
    name.remove_suffix(kTableSuffix.size());
    return std::format("{}{}", name, kLangSuffix);
}

} // namespace game::table
