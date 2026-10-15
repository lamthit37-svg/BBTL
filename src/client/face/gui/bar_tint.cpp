#include "gui/detail/bar_tint.hpp"

#include "gui/asset.hpp"
#include "gui/value.hpp"

#include <algorithm>
#include <array>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

namespace game::gui::detail {
namespace {

constexpr std::uint32_t kChannelMask = 0xFFU;
constexpr float kChannelMax = 255.0F;
constexpr float kPerLevel = 10.0F;
constexpr float kPerPercent = 100.0F;
constexpr std::size_t kCorners = 4;
// Trần của số nguyên đọc từ thuộc tính: phần trăm 0..100 nên trần này không cắt giá trị hợp lệ nào.
constexpr float kPointLimit = 1.0e6F;

// Tên giá trị của EffectColorType (so không phân biệt hoa thường, theo tiền tố đủ độ dài như hàm 0x180079770).
constexpr std::string_view kUninterrupted = "uninterrupted";
constexpr std::string_view kEffectLevel = "effectlevel";

[[nodiscard]] bool has_prefix_ignoring_case(std::string_view text, std::string_view prefix) noexcept {
    if (text.size() < prefix.size()) return false;
    const auto same = [](char left, char right) {
        return std::tolower(static_cast<unsigned char>(left)) == std::tolower(static_cast<unsigned char>(right));
    };
    return std::ranges::equal(text.substr(0, prefix.size()), prefix, same);
}

[[nodiscard]] std::optional<std::int32_t> int_after(std::string_view text, std::string_view key) noexcept {
    const TagValue tag = tagged_value(text, key);
    const std::optional<float> number = tag ? parse_float(*tag) : std::nullopt;
    if (!number || !std::isfinite(*number)) return std::nullopt;
    return static_cast<std::int32_t>(std::clamp(*number, -kPointLimit, kPointLimit));
}

// Phần trong ngoặc sau "key=(" (như "defcolor=(tl:... br:...)"); rỗng khi thiếu.
[[nodiscard]] std::string_view bracket_after(std::string_view text, std::string_view key) noexcept {
    const std::size_t at = text.find(key);
    if (at == std::string_view::npos) return {};
    const std::string_view rest = text.substr(at + key.size());
    const std::size_t close = rest.find(')');
    return close == std::string_view::npos ? std::string_view{} : rest.substr(0, close);
}

[[nodiscard]] std::optional<std::uint32_t> colour_after(std::string_view text, std::string_view key) noexcept {
    const std::optional<GuiColours> corners = parse_colours(bracket_after(text, key));
    if (!corners) return std::nullopt;
    return mean_colour(*corners);
}

// colour::operator-, operator* và operator+ của CEGUI: from + t * (to - from) từng kênh, rồi cắt phần thập phân khi đổi
// về ARGB (colour::calculateARGB).
[[nodiscard]] std::uint32_t lerp_of(const BarTint& tint, float t) noexcept {
    std::uint32_t mixed = 0;
    for (const unsigned shift : {24U, 16U, 8U, 0U}) {
        const float low = static_cast<float>((tint.start_colour >> shift) & kChannelMask) / kChannelMax;
        const float high = static_cast<float>((tint.end_colour >> shift) & kChannelMask) / kChannelMax;
        const float channel = std::clamp((t * (high - low)) + low, 0.0F, 1.0F);
        mixed |= static_cast<std::uint32_t>(channel * kChannelMax) << shift;
    }
    return mixed;
}

void apply_level(BarTint& tint, std::string_view value) {
    const std::optional<std::int32_t> index = int_after(value, "index:");
    const std::optional<GuiColours> corners = parse_colours(value);
    if (!index || !corners) return;
    const std::uint32_t colour = mean_colour(*corners);
    const auto first = static_cast<std::size_t>(std::max(*index, 0));
    for (std::size_t slot = first; slot < tint.levels.size(); ++slot) tint.levels.at(slot) = colour;
}

void apply_uninterrupted(BarTint& tint, std::string_view value) {
    const std::optional<std::int32_t> start = int_after(value, "startpoint:");
    const std::optional<std::int32_t> end = int_after(value, "endpoint:");
    const std::optional<std::uint32_t> start_colour = colour_after(value, "startcolor=(");
    const std::optional<std::uint32_t> end_colour = colour_after(value, "endcolor=(");
    const std::optional<std::uint32_t> default_colour = colour_after(value, "defcolor=(");
    if (start) tint.start_point = *start;
    if (end) tint.end_point = *end;
    if (start_colour) tint.start_colour = *start_colour;
    if (end_colour) tint.end_colour = *end_colour;
    if (default_colour) tint.default_colour = *default_colour;
}

} // namespace

std::uint32_t mean_colour(const GuiColours& corners) noexcept {
    std::uint32_t mixed = 0;
    for (const unsigned shift : {24U, 16U, 8U, 0U}) {
        std::uint32_t sum = 0;
        for (const std::uint32_t corner : corners) sum += (corner >> shift) & kChannelMask;
        mixed |= (sum / static_cast<std::uint32_t>(kCorners)) << shift;
    }
    return mixed;
}

std::uint32_t BarTint::at(float shown) const noexcept {
    // NaN và số âm tính là 0 để phép đổi sang số nguyên luôn nằm trong miền.
    const float level = shown > 0.0F ? std::min(shown, 1.0F) : 0.0F;
    if (!is_uninterrupted) return levels.at(static_cast<std::size_t>(level * kPerLevel));
    const auto percent = static_cast<std::int32_t>(level * kPerPercent);
    if (start_point > percent || percent > end_point) return default_colour;
    if (end_point == start_point) return start_colour;
    const float t = static_cast<float>(percent - start_point) / static_cast<float>(end_point - start_point);
    return lerp_of(*this, t);
}

void apply_tint_property(BarTint& tint, const GuiProperty& property) {
    const std::string_view value = property.value;
    if (property.name == "EffectColorType") {
        if (has_prefix_ignoring_case(value, kUninterrupted)) tint.is_uninterrupted = true;
        else if (has_prefix_ignoring_case(value, kEffectLevel)) tint.is_uninterrupted = false;
    } else if (property.name == "EffectColorLevel") {
        apply_level(tint, value);
    } else if (property.name == "UseUninterruptedEffectColor") {
        apply_uninterrupted(tint, value);
    }
}

BarTint read_bar_tint(std::span<const GuiProperty> from_look, std::span<const GuiProperty> from_layout) {
    BarTint tint;
    for (const std::span<const GuiProperty> run : {from_look, from_layout}) {
        for (const GuiProperty& property : run) apply_tint_property(tint, property);
    }
    return tint;
}

} // namespace game::gui::detail
