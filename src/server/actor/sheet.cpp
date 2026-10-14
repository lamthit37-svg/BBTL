// Bộ đọc bảng TSV có kiểm lỗi (xem sheet.hpp).
#include "actor/sheet.hpp"

#include "core/number.hpp"
#include "table/tsv.hpp"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string_view>
#include <utility>

namespace game::actor {

LoadError fail(std::string_view table, std::string_view what) {
    return LoadError{std::format("{}: {}", table, what)};
}

std::optional<std::int32_t> int_cell(std::string_view cell, std::int32_t low, std::int32_t high) noexcept {
    std::int64_t value = 0;
    const core::OptionalSigned parsed = core::parse_signed(cell);
    if (parsed && parsed->length == cell.size()) {
        value = parsed->value;
    } else {
        const core::OptionalDouble real = core::parse_double(cell);
        if (!real || real->length != cell.size() || !std::isfinite(real->value)) return std::nullopt;
        if (real->value < -2.0e9 || real->value > 2.0e9 || real->value != std::trunc(real->value)) return std::nullopt;
        value = static_cast<std::int64_t>(real->value);
    }
    if (value < low || value > high) return std::nullopt;
    return static_cast<std::int32_t>(value);
}

std::optional<std::int64_t> parse_scaled(std::string_view text, std::int64_t scale) noexcept {
    const core::OptionalDouble parsed = core::parse_double(text);
    if (!parsed || parsed->length != text.size() || !std::isfinite(parsed->value)) return std::nullopt;
    const double scaled = parsed->value * static_cast<double>(scale);
    constexpr double kLimit = 9.0e18;
    if (scaled > kLimit || scaled < -kLimit) return std::nullopt;
    const std::int64_t rounded = std::llround(scaled);
    return rounded;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tên bảng rồi nội dung, mọi nơi gọi cùng một thứ tự (HP-07)
Loaded<table::Tsv> parse_table(std::string_view name, std::string_view text) {
    if (text.empty()) return std::unexpected(fail(name, "thiếu nội dung bảng"));
    table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(fail(name, parsed.error()));
    return std::move(*parsed);
}

std::size_t Sheet::column(std::string_view column_name) {
    const std::optional<std::size_t> index = table::column_of(*tsv_, column_name);
    if (!index) {
        raise(0, column_name, "thiếu cột");
        return 0;
    }
    return *index;
}

std::int32_t Sheet::integer(std::size_t row, std::size_t column_index, std::int32_t low, std::int32_t high) {
    const std::string_view cell = text(row, column_index);
    const std::optional<std::int32_t> value = int_cell(cell, low, high);
    if (!value) {
        raise(row, tsv_->header[column_index], std::format("\"{}\" không phải số nguyên trong {}..{}", cell, low, high));
        return 0;
    }
    return *value;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): dòng, cột, hệ số khác vai, nơi gọi nêu tên (HP-07)
std::int64_t Sheet::scaled(std::size_t row, std::size_t column_index, std::int64_t scale) {
    const std::string_view cell = text(row, column_index);
    const std::optional<std::int64_t> value = parse_scaled(cell, scale);
    if (!value) {
        raise(row, tsv_->header[column_index], std::format("\"{}\" không phải số", cell));
        return 0;
    }
    return *value;
}

void Sheet::raise(std::size_t row, std::string_view column_name, std::string_view what) {
    if (error_) return;
    const std::size_t line = row < tsv_->lines.size() ? tsv_->lines[row] : 0;
    error_ = fail(name_, std::format("dòng {}, cột {}: {}", line, column_name, what));
}

} // namespace game::actor
