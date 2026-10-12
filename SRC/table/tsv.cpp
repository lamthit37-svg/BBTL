// Đọc bảng TSV và các ô của một bản ghi (xem tsv.hpp).
#include "table/tsv.hpp"

#include "core/number.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::table {
namespace {

constexpr char kTab = '\t';

// Tách một dòng theo tab; dòng rỗng cho một ô rỗng, nên ô cuối rỗng vẫn được tính.
std::vector<std::string> split_tabs(std::string_view line) {
    std::vector<std::string> cells;
    std::size_t start = 0;
    std::size_t stop = 0;
    while (stop != std::string_view::npos) {
        stop = line.find(kTab, start);
        cells.emplace_back(line.substr(start, stop - start));
        start = stop + 1;
    }
    return cells;
}

// Dòng bỏ qua: rỗng hay chú thích.
bool is_skipped(std::string_view line) {
    return line.empty() || line.front() == '#';
}

// Bỏ '\r' cuối dòng của tệp viết trên Windows.
std::string_view without_return(std::string_view line) {
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    return line;
}

// Thêm một dòng vào bảng: dòng đầu là tên cột, các dòng sau phải đủ số ô.
std::optional<std::string> add_line(Tsv& table, std::string_view line, std::size_t number) {
    std::vector<std::string> cells = split_tabs(line);
    if (table.header.empty()) {
        table.header = std::move(cells);
        return std::nullopt;
    }
    if (cells.size() != table.header.size()) {
        return std::format("dòng {}: {} ô, dòng tên cột có {}", number, cells.size(), table.header.size());
    }
    table.rows.push_back(std::move(cells));
    table.lines.push_back(number);
    return std::nullopt;
}

// Số nguyên không dấu thuần chữ số, vừa 32 bit.
std::optional<std::uint32_t> whole_number(std::string_view cell) {
    const core::OptionalUnsigned parsed = core::parse_unsigned(cell, 10);
    if (!parsed || parsed->length != cell.size()) return std::nullopt;
    return parsed->value;
}

// Vị trí đọc trong văn bản: byte đầu của dòng kế và số dòng đã đọc.
struct Cursor {
    std::size_t start = 0;
    std::size_t number = 0;
};

// Đọc một dòng của văn bản vào bảng rồi dời con trỏ; lỗi của dòng nếu có.
std::optional<std::string> read_line(Tsv& table, std::string_view text, Cursor& cursor) {
    const std::size_t stop = text.find('\n', cursor.start);
    const std::size_t end = stop == std::string_view::npos ? text.size() : stop;
    const std::string_view line = without_return(text.substr(cursor.start, end - cursor.start));
    ++cursor.number;
    cursor.start = end + 1;
    if (is_skipped(line)) return std::nullopt;
    return add_line(table, line, cursor.number);
}

} // namespace

TsvResult parse_tsv(std::string_view text) {
    Tsv table;
    Cursor cursor;
    std::optional<std::string> failure;
    while (cursor.start <= text.size() && !failure) {
        failure = read_line(table, text, cursor);
    }
    if (failure) return std::unexpected(*failure);
    if (table.header.empty()) return std::unexpected("bảng không có dòng tên cột");
    return table;
}

std::optional<std::size_t> column_of(const Tsv& table, std::string_view name) {
    const auto found = std::ranges::find(table.header, name);
    if (found == table.header.end()) return std::nullopt;
    return static_cast<std::size_t>(found - table.header.begin());
}

void RowReader::reject(std::string_view column, std::string_view what) {
    if (error_) return;
    error_ = std::format("dòng {}, cột {}: {}", table_->lines.at(row_), column, what);
}

std::string_view RowReader::text(std::string_view column) {
    const std::optional<std::size_t> index = column_of(*table_, column);
    if (!index) {
        reject(column, "bảng không có cột này");
        return {};
    }
    return table_->rows.at(row_).at(*index);
}

std::uint32_t RowReader::number(std::string_view column, std::uint32_t low, std::uint32_t high) {
    const std::string_view cell = text(column);
    if (error_) return 0;
    const std::optional<std::uint32_t> value = whole_number(cell);
    if (!value) {
        reject(column, std::format("\"{}\" không phải số nguyên không dấu", cell));
        return 0;
    }
    if (*value < low || *value > high) {
        reject(column, std::format("{} ngoài miền {}..{}", *value, low, high));
        return 0;
    }
    return *value;
}

std::int32_t RowReader::integer(std::string_view column, std::int32_t low, std::int32_t high) {
    const std::string_view cell = text(column);
    if (error_) return 0;
    const core::OptionalSigned parsed = core::parse_signed(cell);
    if (!parsed || parsed->length != cell.size()) {
        reject(column, std::format("\"{}\" không phải số nguyên", cell));
        return 0;
    }
    if (parsed->value < low || parsed->value > high) {
        reject(column, std::format("{} ngoài miền {}..{}", parsed->value, low, high));
        return 0;
    }
    return parsed->value;
}

float RowReader::positive(std::string_view column) {
    const std::string_view cell = text(column);
    if (error_) return 0.0F;
    const core::OptionalDouble parsed = core::parse_double(cell);
    const bool is_whole = parsed && parsed->length == cell.size();
    const bool is_usable = is_whole && std::isfinite(parsed->value) && parsed->value > 0.0;
    if (!is_usable) {
        reject(column, std::format("\"{}\" không phải số thực dương", cell));
        return 0.0F;
    }
    return static_cast<float>(parsed->value);
}

bool RowReader::flag(std::string_view column) {
    return number(column, 0, 1) == 1;
}

} // namespace game::table
