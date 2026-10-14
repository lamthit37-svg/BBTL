#pragma once
// Khuôn đọc bảng dùng chung của các bộ đọc trong module look (appearance.cpp, weapon.cpp): đọc mọi
// dòng qua một bộ đọc một dòng, xếp theo khoá rồi bắt khoá trùng. Tách ra để hai nơi không chép
// lại cùng một đoạn.

#include "look/appearance.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <expected>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::look::detail {

// Mọi dòng của bảng qua một bộ đọc một dòng; dừng ở dòng sai đầu tiên.
template <typename Row>
Rows<Row> read_all(const table::Tsv& table, Row (*read_row)(table::RowReader&)) {
    std::vector<Row> rows;
    rows.reserve(table.rows.size());
    std::optional<std::string> failure;
    for (std::size_t index = 0; index < table.rows.size() && !failure; ++index) {
        // NOLINTNEXTLINE(misc-const-correctness): giả dương, read_row nhận RowReader& (HP-07)
        table::RowReader reader(table, index);
        rows.push_back(read_row(reader));
        failure = reader.error();
    }
    if (failure) return std::unexpected(*failure);
    return rows;
}

// Khoá của hàng trước phải nhỏ hơn khoá của hàng sau: bảng không có khoá trùng.
template <typename Row, typename Key>
std::optional<std::string> check_unique(std::span<const Row> rows, Key key, std::string_view name) {
    const auto repeats = [&key](const Row& left, const Row& right) { return key(left) == key(right); };
    const auto found = std::ranges::adjacent_find(rows, repeats);
    if (found == rows.end()) return std::nullopt;
    return std::format("bảng {} có khoá trùng", name);
}

// Xếp theo khoá (O(n log n)) rồi bắt khoá trùng; bảng xếp rồi cho phép tra nhị phân.
template <typename Row, typename Key>
Rows<Row> sorted_unique(Rows<Row> rows, Key key, std::string_view name) {
    if (!rows) return rows;
    const auto before = [&key](const Row& left, const Row& right) { return key(left) < key(right); };
    std::ranges::sort(*rows, before);
    const std::optional<std::string> repeated = check_unique<Row>(*rows, key, name);
    if (repeated) return std::unexpected(*repeated);
    return rows;
}

template <typename Row>
Rows<Row> not_empty(Rows<Row> rows, std::string_view name) {
    if (rows && rows->empty()) return std::unexpected(std::format("bảng {} không có dòng nào", name));
    return rows;
}

} // namespace game::look::detail
