#include "gui/value.hpp"

#include "core/number.hpp"
#include "gui/asset.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::gui {
namespace {

constexpr std::string_view kNumberStart = "-+.0123456789";
// "%8X" của PropertyHelper: tối đa tám chữ số hex.
constexpr std::size_t kHexDigits = 8;

// Số thực bắt đầu ở position, dấu '+' đầu bỏ qua vì from_chars không nhận nó; position đi tới sau
// số.
std::optional<float> number_at(std::string_view text, std::size_t& position) noexcept {
    const std::size_t skip = text.substr(position).starts_with('+') ? 1U : 0U;
    const core::OptionalDouble parsed = core::parse_double(text.substr(position + skip));
    if (!parsed) return std::nullopt;
    position += skip + parsed->length;
    return static_cast<float>(parsed->value);
}

// N số đầu tiên của chuỗi theo thứ tự, bỏ qua ngoặc, dấu phẩy và dấu cách, như sscanf với mẫu
// " { { %g , %g } , ... }" của PropertyHelper khi chuỗi đúng dạng.
template <std::size_t N>
std::optional<std::array<float, N>> numbers(std::string_view text) noexcept {
    std::array<float, N> out{};
    std::size_t found = 0;
    std::size_t position = text.find_first_of(kNumberStart);
    bool is_valid = true;
    while (is_valid && found < N && position != std::string_view::npos) {
        const std::optional<float> value = number_at(text, position);
        is_valid = value.has_value();
        out.at(found) = value.value_or(0.0F);
        ++found;
        position = text.find_first_of(kNumberStart, position);
    }
    if (!is_valid || found != N) return std::nullopt;
    return out;
}

std::string_view trimmed(std::string_view text) noexcept {
    const std::size_t first = text.find_first_not_of(" \t");
    if (first == std::string_view::npos) return {};
    const std::size_t last = text.find_last_not_of(" \t");
    return text.substr(first, last - first + 1);
}

// Khoảng trắng của isspace, mà %s của sscanf bỏ qua và dừng ở đó.
constexpr std::string_view kSpace = " \t\n\v\f\r";

std::string_view after_spaces(std::string_view text) noexcept {
    const std::size_t first = text.find_first_not_of(kSpace);
    return first == std::string_view::npos ? std::string_view{} : text.substr(first);
}

// Từ đầu của text (text đã bỏ khoảng trắng đầu).
std::string_view word_of(std::string_view text) noexcept {
    return text.substr(0, text.find_first_of(kSpace));
}

bool is_blank(char letter) noexcept {
    return letter == ' ' || letter == '\t';
}

// Vị trí của key khi nó đứng đầu chuỗi hay ngay sau một khoảng trắng; npos khi không có.
std::size_t tag_at(std::string_view text, std::string_view key) noexcept {
    std::size_t position = text.find(key);
    while (position != std::string_view::npos && position != 0 && !is_blank(text[position - 1]))
        position = text.find(key, position + 1);
    return position;
}

// Hex tối đa 8 chữ số sau tiền tố key (rỗng là đầu chuỗi), như "%8X".
std::optional<std::uint32_t> hex_after(std::string_view text, std::string_view key) noexcept {
    const std::size_t position = text.find(key);
    if (position == std::string_view::npos) return std::nullopt;
    const std::string_view rest = trimmed(text.substr(position + key.size()));
    const core::OptionalUnsigned parsed = core::parse_unsigned(rest.substr(0, kHexDigits), 16);
    if (!parsed) return std::nullopt;
    return parsed->value;
}

} // namespace

std::optional<GuiUDim> parse_udim(std::string_view text) noexcept {
    const auto values = numbers<2>(text);
    if (!values) return std::nullopt;
    return GuiUDim{.scale = values->at(0), .offset = values->at(1)};
}

std::optional<UVector> parse_uvector(std::string_view text) noexcept {
    const auto values = numbers<4>(text);
    if (!values) return std::nullopt;
    const GuiUDim across{.scale = values->at(0), .offset = values->at(1)};
    const GuiUDim down{.scale = values->at(2), .offset = values->at(3)};
    return UVector{.x = across, .y = down};
}

std::optional<URect> parse_urect(std::string_view text) noexcept {
    const auto values = numbers<8>(text);
    if (!values) return std::nullopt;
    const UVector low{
        .x = {.scale = values->at(0), .offset = values->at(1)}, .y = {.scale = values->at(2), .offset = values->at(3)}};
    const UVector high{
        .x = {.scale = values->at(4), .offset = values->at(5)}, .y = {.scale = values->at(6), .offset = values->at(7)}};
    return URect{.min = low, .max = high};
}

bool parse_bool(std::string_view text) noexcept {
    const std::string_view value = trimmed(text);
    return value == "True" || value == "true";
}

std::optional<float> parse_float(std::string_view text) noexcept {
    const auto values = numbers<1>(text);
    if (!values) return std::nullopt;
    return values->at(0);
}

// sscanf(" set:%127s image:%127s") của PropertyHelper::stringToImage: mỗi nửa là một từ, khoảng trắng nào
// (kể cả xuống dòng mà vài layout gốc ngắt giữa hai nửa) cũng ngăn cách. Không giữ trần 127 ký tự.
std::optional<ImageName> parse_image(std::string_view text) noexcept {
    std::string_view rest = after_spaces(text);
    if (!rest.starts_with("set:")) return std::nullopt;
    rest = after_spaces(rest.substr(4));
    const std::string_view set = word_of(rest);
    rest = after_spaces(rest.substr(set.size()));
    if (set.empty() || !rest.starts_with("image:")) return std::nullopt;
    rest = after_spaces(rest.substr(6));
    const std::string_view image = word_of(rest);
    if (image.empty()) return std::nullopt;
    return ImageName{.set = set, .image = image};
}

TagValue tagged_value(std::string_view text, std::string_view key) noexcept {
    const std::size_t position = tag_at(text, key);
    if (position == std::string_view::npos) return std::nullopt;
    const std::string_view rest = text.substr(position + key.size());
    const std::string_view value = rest.substr(0, rest.find_first_of(" \t"));
    if (value.empty()) return std::nullopt;
    return value;
}

std::optional<ImageName> tagged_image(std::string_view text) noexcept {
    const std::size_t position = tag_at(text, "set:");
    if (position == std::string_view::npos) return std::nullopt;
    return parse_image(text.substr(position));
}

std::optional<std::uint32_t> parse_colour(std::string_view text) noexcept {
    return hex_after(text, "");
}

std::optional<GuiColours> parse_colours(std::string_view text) noexcept {
    const auto top_left = hex_after(text, "tl:");
    const auto top_right = hex_after(text, "tr:");
    const auto bottom_left = hex_after(text, "bl:");
    const auto bottom_right = hex_after(text, "br:");
    const bool has_corners = top_left && top_right && bottom_left && bottom_right;
    if (has_corners) return GuiColours{*top_left, *top_right, *bottom_left, *bottom_right};
    const auto single = parse_colour(text);
    if (!single) return std::nullopt;
    return GuiColours{*single, *single, *single, *single};
}

namespace {

// Kênh 8 bit thành số trên 255, nhân, rồi cắt phần thập phân.
[[nodiscard]] std::uint32_t scaled_channel(std::uint32_t first, std::uint32_t second, unsigned shift) noexcept {
    const float left = static_cast<float>((first >> shift) & 0xFFU) / 255.0F;
    const float right = static_cast<float>((second >> shift) & 0xFFU) / 255.0F;
    return static_cast<std::uint32_t>(left * right * 255.0F) << shift;
}

} // namespace

std::uint32_t modulate(std::uint32_t first, std::uint32_t second) noexcept {
    const std::uint32_t alpha = scaled_channel(first, second, 24);
    const std::uint32_t red = scaled_channel(first, second, 16);
    const std::uint32_t green = scaled_channel(first, second, 8);
    const std::uint32_t blue = scaled_channel(first, second, 0);
    return alpha | red | green | blue;
}

} // namespace game::gui
