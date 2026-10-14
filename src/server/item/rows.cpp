// Bộ đọc bảng TSV theo dòng: xem rows.hpp.
#include "item/rows.hpp"

#include "core/aligned.hpp"

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
    std::size_t tab = 0;
    while (tab != std::string_view::npos) {
        tab = line.find('\t', begin);
        out.push_back(line.substr(begin, tab - begin));
        begin = tab + 1;
    }
}

[[nodiscard]] std::string_view strip_cr(std::string_view line) noexcept {
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    return line;
}

// Tên cột của bảng căn cột. Tên mang kSpaceMark (dấu cách thật) giữ cả ký hiệu để không khớp cột nào.
[[nodiscard]] std::string_view unpad_name(std::string_view name) noexcept {
    const core::AlignedCell cell = core::unpad(name);
    if (cell.trailing_spaces == 0) return cell.body;
    return name.substr(0, cell.body.size() + (cell.trailing_spaces * core::kSpaceMark.size()));
}

// Chữ thật của một ô bảng căn cột. Ô có dấu cách cuối thật được dựng lại trong storage.
[[nodiscard]] std::string_view unpad_cell(std::string_view cell, std::string& storage) {
    const core::AlignedCell aligned = core::unpad(cell);
    if (aligned.trailing_spaces == 0) return aligned.body;
    storage.assign(aligned.body);
    storage.append(aligned.trailing_spaces, ' ');
    return storage;
}

} // namespace

Rows::Rows(std::string_view text) : rest_(text) {
    std::string_view line;
    while (take_line(line)) {
        if (!note_layout(line)) return;
        if (line.empty() || line.front() == '#') continue;
        read_header(line);
        return;
    }
    error_ = "bảng không có dòng tên cột";
}

// Dòng kế của văn bản (đã bỏ CR cuối); false khi hết.
bool Rows::take_line(std::string_view& line) {
    if (rest_.empty()) return false;
    const std::size_t eol = rest_.find('\n');
    const std::string_view raw = eol == std::string_view::npos ? rest_ : rest_.substr(0, eol);
    rest_ = eol == std::string_view::npos ? std::string_view{} : rest_.substr(eol + 1);
    ++line_;
    line = strip_cr(raw);
    return true;
}

// Dòng "# layout: ..." trước tên cột đặt bố cục; false (đã ghi lỗi) khi bố cục lạ.
bool Rows::note_layout(std::string_view line) {
    if (!line.starts_with(core::kLayoutPrefix)) return true;
    if (line != core::kAlignedLayout) {
        error_ = "dòng " + std::to_string(line_) + ": bố cục lạ";
        return false;
    }
    layout_ = core::Layout::kAligned;
    return true;
}

void Rows::read_header(std::string_view line) {
    split_tabs(line, header_);
    if (layout_ != core::Layout::kAligned) return;
    for (std::string_view& name : header_) name = unpad_name(name);
    restored_.resize(header_.size());
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
    std::string_view line;
    while (take_line(line)) {
        if (line.empty() || line.front() == '#') continue;
        return read_cells(line);
    }
    return false;
}

// Cắt dòng dữ liệu thành ô của dòng hiện tại; false (đã ghi lỗi) khi lệch số ô của dòng tên cột.
bool Rows::read_cells(std::string_view line) {
    split_tabs(line, cells_);
    if (cells_.size() != header_.size()) {
        error_ = "dòng " + std::to_string(line_) + ": có " + std::to_string(cells_.size()) + " ô, cần "
            + std::to_string(header_.size());
        return false;
    }
    unpad_cells();
    return true;
}

// Bảng căn cột: bỏ đệm từng ô của dòng hiện tại.
void Rows::unpad_cells() {
    if (layout_ != core::Layout::kAligned) return;
    for (std::size_t col = 0; col < cells_.size(); ++col) {
        cells_[col] = unpad_cell(cells_[col], restored_[col]);
    }
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
