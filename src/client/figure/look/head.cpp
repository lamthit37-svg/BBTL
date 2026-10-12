#include "look/head.hpp"

#include "core/number.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::look {
namespace {

constexpr std::array<std::string_view, 7> kColumns = {"model", "kind", "turn", "height", "distance", "pitch", "shift"};

// Chỉ số của bảy cột theo thứ tự kColumns; nullopt khi thiếu cột nào.
std::optional<std::array<std::size_t, 7>> columns_of(const table::Tsv& table) {
    std::array<std::size_t, 7> found{};
    bool is_whole = true;
    for (std::size_t slot = 0; slot < kColumns.size(); ++slot) {
        const std::optional<std::size_t> column = table::column_of(table, kColumns.at(slot));
        is_whole = is_whole && column.has_value();
        found.at(slot) = column.value_or(0);
    }
    if (!is_whole) return std::nullopt;
    return found;
}

// Số thực hữu hạn của một ô; nullopt khi ô không phải một số trọn vẹn.
std::optional<float> number_of(std::string_view cell) noexcept {
    const core::OptionalDouble parsed = core::parse_double(cell);
    if (!parsed || parsed->length != cell.size()) return std::nullopt;
    return static_cast<float>(parsed->value);
}

using Cells = std::vector<std::string>;
using Columns = std::array<std::size_t, 7>;

// Năm số của một dòng theo thứ tự turn, height, distance, pitch, shift; nullopt khi ô nào hỏng.
std::optional<std::array<float, 5>> numbers_of(const Cells& cells, const Columns& columns) {
    std::array<float, 5> numbers{};
    bool is_whole = true;
    for (std::size_t slot = 0; slot < numbers.size(); ++slot) {
        const std::optional<float> number = number_of(cells.at(columns.at(slot + 2)));
        is_whole = is_whole && number.has_value();
        numbers.at(slot) = number.value_or(0.0F);
    }
    if (!is_whole) return std::nullopt;
    return numbers;
}

// Một dòng của tệp thành HeadRow; nullopt khi dòng hỏng.
std::optional<HeadRow> row_of(const Cells& cells, const Columns& columns) {
    const std::optional<int> parsed = core::parse_whole_int(cells.at(columns.at(1)));
    const int kind = parsed.value_or(-1);
    const std::optional<std::array<float, 5>> numbers = numbers_of(cells, columns);
    const bool is_kind = kind >= 0 && kind < int{kHeadKinds};
    if (!numbers || !is_kind) return std::nullopt;
    HeadRow row;
    row.model = cells.at(columns.at(0));
    row.kind = static_cast<std::uint8_t>(kind);
    row.pose = HeadPose{.turn = numbers->at(0),
        .height = numbers->at(1),
        .distance = numbers->at(2),
        .pitch = numbers->at(3),
        .shift = numbers->at(4)};
    return row;
}

void take_row(std::vector<HeadRow>& rows, std::optional<HeadRow> row) {
    if (row) rows.push_back(std::move(*row));
}

} // namespace

std::vector<HeadRow> read_heads(const table::Tsv& table) {
    std::vector<HeadRow> rows;
    const auto columns = columns_of(table);
    if (!columns) return rows;
    rows.reserve(table.rows.size());
    for (const std::vector<std::string>& cells : table.rows) {
        std::optional<HeadRow> row = row_of(cells, *columns);
        take_row(rows, std::move(row));
    }
    return rows;
}

HeadsResult parse_heads(std::string_view text) {
    const table::TsvResult table = table::parse_tsv(text);
    if (!table) return std::unexpected(table.error());
    return read_heads(*table);
}

HeadPose find_head(const std::vector<HeadRow>& rows, const HeadKey& key) noexcept {
    const auto is_wanted = [&key](const HeadRow& row) { return row.kind == key.kind && row.model == key.model; };
    const auto found = std::ranges::find_if(rows, is_wanted);
    return found == rows.end() ? HeadPose{} : found->pose;
}

} // namespace game::look
