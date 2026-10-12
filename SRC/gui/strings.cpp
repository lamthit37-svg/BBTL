#include "gui/strings.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <functional>
#include <iterator>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gui {
namespace {

// Ký tự mở đầu khoá của một chuỗi viết thẳng trong bảng dịch.
constexpr char kLiteralMark = '=';

// Hai chỉ số cột của bảng chuỗi.
struct Columns {
    std::size_t key = 0;
    std::size_t text = 0;
};

// Khoá key có đứng trước chuỗi "=" nối text theo thứ tự byte của bảng không; so từng phần để khỏi
// dựng chuỗi đó. Byte so như unsigned char, đúng cách std::string xếp.
bool is_before_literal(std::string_view key, std::string_view text) noexcept {
    if (key.empty()) return true;
    const auto lead = static_cast<unsigned char>(key.front());
    if (lead != static_cast<unsigned char>(kLiteralMark)) return lead < kLiteralMark;
    return key.substr(1) < text;
}

std::optional<Columns> columns_of(const table::Tsv& table) {
    const auto key = table::column_of(table, "key");
    const auto text = table::column_of(table, "text");
    if (!key || !text) return std::nullopt;
    return Columns{.key = *key, .text = *text};
}

} // namespace

StringBook StringBook::from_table(const table::Tsv& table) {
    StringBook book;
    book.overlay(table);
    return book;
}

void StringBook::overlay(const table::Tsv& table) {
    const std::optional<Columns> columns = columns_of(table);
    if (!columns) return;
    std::vector<Row> merged;
    merged.reserve(table.rows.size() + rows_.size());
    // Đảo trước khi xếp ổn định: dòng sau của một khoá đứng đầu nhóm, và unique giữ dòng đầu nhóm.
    // Dòng đã có đứng sau cùng nên thua mọi dòng của table.
    for (const std::vector<std::string>& row : table.rows | std::views::reverse)
        merged.push_back(Row{.key = row.at(columns->key), .text = row.at(columns->text)});
    std::ranges::move(rows_, std::back_inserter(merged));
    std::ranges::stable_sort(merged, std::less<>{}, &Row::key);
    const auto tail = std::ranges::unique(merged, std::equal_to<>{}, &Row::key);
    merged.erase(tail.begin(), tail.end());
    rows_ = std::move(merged);
}

std::optional<std::string_view> StringBook::find(std::string_view id) const noexcept {
    const auto found = std::ranges::lower_bound(rows_, id, std::less<>{}, &Row::key);
    if (found == rows_.end() || found->key != id) return std::nullopt;
    return std::string_view{found->text};
}

std::optional<std::string_view> StringBook::find_literal(std::string_view text) const noexcept {
    const auto is_before = [text](const Row& row) { return is_before_literal(row.key, text); };
    const auto found = std::ranges::partition_point(rows_, is_before);
    if (found == rows_.end()) return std::nullopt;
    const std::string_view key = found->key;
    const bool is_match = key.starts_with(kLiteralMark) && key.substr(1) == text;
    if (!is_match) return std::nullopt;
    return std::string_view{found->text};
}

} // namespace game::gui
