#include "ui/script/variable.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

// Gốc so strncmp(tên, "View_DefaultCamera", 0x12) và strncmp(tên, "View_FOV", 8): tiền tố, không phải toàn tên.
[[nodiscard]] bool is_silent(std::string_view name) noexcept {
    return name.starts_with("View_DefaultCamera") || name.starts_with("View_FOV");
}

// atoi của MSVC (strtol rồi ép int): khoảng trắng đầu (isspace của locale C), một dấu tuỳ chọn, rồi chữ số; tràn thì kẹp.
[[nodiscard]] std::int32_t c_atoi(std::string_view text) noexcept {
    constexpr std::string_view kSpace = " \t\n\v\f\r";
    const std::size_t begin = text.find_first_not_of(kSpace);
    if (begin == std::string_view::npos) return 0;
    text.remove_prefix(begin);
    const bool negative = text.starts_with('-');
    if (negative || text.starts_with('+')) text.remove_prefix(1);
    const std::size_t digits = text.find_first_not_of("0123456789");
    text = text.substr(0, digits);
    if (text.empty()) return 0;
    std::int64_t magnitude = 0;
    for (const char digit : text) {
        magnitude = std::min<std::int64_t>(magnitude * 10 + (digit - '0'), std::int64_t{std::numeric_limits<std::int32_t>::max()} + 1);
    }
    const std::int64_t value = negative ? -magnitude : magnitude;
    return static_cast<std::int32_t>(std::clamp<std::int64_t>(value, std::numeric_limits<std::int32_t>::min(), std::numeric_limits<std::int32_t>::max()));
}

} // namespace

std::int32_t VariableSystem::get_int(std::string_view name) const {
    const std::optional<std::string_view> value = get(name);
    return value ? c_atoi(*value) : 0;
}

std::optional<std::string_view> VariableSystem::get(std::string_view name) const {
    const auto found = values_.find(name);
    if (found == values_.end()) return std::nullopt;
    return std::string_view(found->second);
}

// NOLINTNEXTLINE(bugprone-exception-escape)
std::optional<VariableChange> VariableSystem::set(std::string_view name, std::string_view value) noexcept {
    if (name.empty() || name.size() > kVariableNameLimit || value.size() >= kVariableValueLimit) return std::nullopt;
    auto found = values_.find(name);
    if (found == values_.end()) {
        if (values_.size() >= kVariableCountLimit) return std::nullopt;
        found = values_.emplace(std::string(name), std::string()).first;
    }
    if (found->second == value) return std::nullopt;
    found->second.assign(value);
    if (is_silent(name)) return std::nullopt;
    return VariableChange{.name = std::string(name), .value = std::string(value)};
}

} // namespace game::ui::script
