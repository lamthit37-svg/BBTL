#include "scenedata/detail/cells.hpp"

#include "core/text.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>

namespace game::scenedata::detail {
namespace {

// Số nguyên có dấu chiếm TRỌN ô; không nhận dấu cộng, khoảng trắng hay phần dư.
[[nodiscard]] std::optional<std::int64_t> whole_integer(std::string_view text) noexcept {
    std::int64_t value = 0;
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    const auto [stop, error] = std::from_chars(first, last, value);
    if (error != std::errc{} || stop != last) return std::nullopt;
    return value;
}

// Số thực hữu hạn chiếm TRỌN ô, parse thẳng sang float để không làm tròn hai lần.
[[nodiscard]] std::optional<float> whole_real(std::string_view text) noexcept {
    float value = 0.0F;
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    const auto [stop, error] = std::from_chars(first, last, value);
    if (error != std::errc{} || stop != last || !std::isfinite(value)) return std::nullopt;
    return value;
}

[[nodiscard]] bool has_control_character(std::string_view text) noexcept {
    return std::ranges::any_of(text, [](char byte) {
        const auto code = static_cast<unsigned char>(byte);
        return code < 0x20U || code == 0x7FU;
    });
}

} // namespace

bool Cells::has(std::string_view column) const noexcept {
    return table::column_of(*table_, column).has_value();
}

std::optional<std::string_view> Cells::cell(std::string_view column) {
    const std::optional<std::size_t> index = table::column_of(*table_, column);
    if (!index) {
        reject(column, "bảng thiếu cột");
        return std::nullopt;
    }
    return std::string_view{table_->rows[row_][*index]};
}

bool Cells::blank(std::string_view column) {
    const std::optional<std::string_view> value = cell(column);
    return value && value->empty();
}

void Cells::reject(std::string_view column, std::string_view what) {
    if (error_) return;
    const std::size_t line = row_ < table_->lines.size() ? table_->lines[row_] : 0;
    error_ = std::string(file_) + ":" + std::to_string(line) + ": cột " + std::string(column) + ": " + std::string(what);
}

std::optional<std::int32_t> Cells::int_opt(std::string_view column, std::int32_t low, std::int32_t high) {
    const std::optional<std::string_view> value = cell(column);
    if (!value || value->empty()) return std::nullopt;
    const std::optional<std::int64_t> parsed = whole_integer(*value);
    if (!parsed) {
        reject(column, "không phải số nguyên");
        return std::nullopt;
    }
    if (*parsed < low || *parsed > high) {
        reject(column, "ngoài miền " + std::to_string(low) + ".." + std::to_string(high));
        return std::nullopt;
    }
    return static_cast<std::int32_t>(*parsed);
}

std::int32_t Cells::int_or(std::string_view column, std::int32_t fallback, std::int32_t low, std::int32_t high) {
    return int_opt(column, low, high).value_or(fallback);
}

std::int32_t Cells::int_or_zero(std::string_view column, std::int32_t low, std::int32_t high) {
    return int_or(column, 0, low, high);
}

std::optional<std::uint32_t> Cells::uint_opt(std::string_view column, std::uint32_t high) {
    constexpr auto kInt32Max = static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max());
    const std::optional<std::int32_t> value = int_opt(column, 0, static_cast<std::int32_t>(std::min(high, kInt32Max)));
    if (!value) return std::nullopt;
    return static_cast<std::uint32_t>(*value);
}

std::uint32_t Cells::uint_or_zero(std::string_view column, std::uint32_t high) {
    return uint_opt(column, high).value_or(0U);
}

std::optional<float> Cells::real_opt(std::string_view column) {
    const std::optional<std::string_view> value = cell(column);
    if (!value || value->empty()) return std::nullopt;
    const std::optional<float> parsed = whole_real(*value);
    if (!parsed) {
        reject(column, "không phải số thực hữu hạn");
        return std::nullopt;
    }
    if (std::fabs(*parsed) > kMaxCoordinate) {
        reject(column, "ngoài miền toạ độ");
        return std::nullopt;
    }
    return *parsed;
}

float Cells::real_or_zero(std::string_view column) {
    return real_opt(column).value_or(0.0F);
}

bool Cells::flag(std::string_view column) {
    return int_or_zero(column, 0, 1) != 0;
}

std::string Cells::text(std::string_view column) {
    const std::optional<std::string_view> value = cell(column);
    if (!value) return {};
    if (value->size() > kMaxTextCell) {
        reject(column, "chữ dài quá " + std::to_string(kMaxTextCell) + " byte");
        return {};
    }
    if (!core::is_valid_utf8(*value) || has_control_character(*value)) {
        reject(column, "không phải UTF-8 sạch");
        return {};
    }
    return std::string(*value);
}

} // namespace game::scenedata::detail
