// Bộ đọc bảng TSV theo dòng: xem rows.hpp.
#include "item/rows.hpp"

#include <charconv>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

namespace game::item::tsv {
namespace {

// Cắt một dòng thành ô cách nhau bằng tab. Dòng không có tab vẫn là một ô.
void split_tabs(std::string_view line, std::vector<std::string_view>& out) {
    out.clear();
    std::size_t begin = 0;
    for (;;) {
        const std::size_t tab = line.find('\t', begin);
        if (tab == std::string_view::npos) {
            out.push_back(line.substr(begin));
            return;
        }
        out.push_back(line.substr(begin, tab - begin));
        begin = tab + 1;
    }
}

[[nodiscard]] std::string_view strip_cr(std::string_view line) noexcept {
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    return line;
}

} // namespace

Rows::Rows(std::string_view text) : rest_(text) {
    while (!rest_.empty()) {
        const std::size_t eol = rest_.find('\n');
        const std::string_view raw = eol == std::string_view::npos ? rest_ : rest_.substr(0, eol);
        rest_ = eol == std::string_view::npos ? std::string_view{} : rest_.substr(eol + 1);
        ++line_;
        const std::string_view line = strip_cr(raw);
        if (line.empty() || line.front() == '#') continue;
        split_tabs(line, header_);
        return;
    }
    error_ = "bảng không có dòng tên cột";
}

std::size_t Rows::column(std::string_view name) const noexcept {
    for (std::size_t i = 0; i < header_.size(); ++i) {
        if (header_[i] == name) return i;
    }
    return npos;
}

std::string_view Rows::name(std::size_t col) const noexcept {
    return col < header_.size() ? header_[col] : std::string_view{};
}

bool Rows::next() {
    if (error_) return false;
    while (!rest_.empty()) {
        const std::size_t eol = rest_.find('\n');
        const std::string_view raw = eol == std::string_view::npos ? rest_ : rest_.substr(0, eol);
        rest_ = eol == std::string_view::npos ? std::string_view{} : rest_.substr(eol + 1);
        ++line_;
        const std::string_view line = strip_cr(raw);
        if (line.empty() || line.front() == '#') continue;
        split_tabs(line, cells_);
        if (cells_.size() != header_.size()) {
            error_ = "dòng " + std::to_string(line_) + ": có " + std::to_string(cells_.size()) + " ô, cần "
                + std::to_string(header_.size());
            return false;
        }
        return true;
    }
    return false;
}

std::optional<std::int64_t> to_int(std::string_view cell) noexcept {
    if (cell.empty()) return std::nullopt;
    std::int64_t value = 0;
    const char* const first = cell.data();
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars nhận cặp con trỏ đầu-cuối.
    const char* const last = first + cell.size();
    const auto [stop, ec] = std::from_chars(first, last, value);
    if (ec != std::errc{} || stop != last) return std::nullopt;
    return value;
}

std::string_view Cells::text(std::size_t col) const noexcept {
    const auto cells = rows_->cells();
    return col < cells.size() ? cells[col] : std::string_view{};
}

void Cells::fail(std::size_t col, std::string_view what) {
    if (error_) return;
    error_ = std::string(table_) + ":" + std::to_string(rows_->line()) + " cột " + std::string(rows_->name(col))
        + ": " + std::string(what);
}

std::int64_t Cells::integer(std::size_t col, Bounds bounds) {
    const std::optional<std::int64_t> value = to_int(text(col));
    if (!value) {
        fail(col, "không phải số nguyên");
        return bounds.first;
    }
    if (*value < bounds.first || *value > bounds.second) {
        fail(col, "ngoài miền");
        return bounds.first;
    }
    return *value;
}

std::int64_t Cells::optional_integer(std::size_t col, Bounds bounds, std::int64_t fallback) {
    const std::string_view cell = text(col);
    if (cell.empty() || cell == "-1") return fallback;
    return integer(col, bounds);
}

} // namespace game::item::tsv
