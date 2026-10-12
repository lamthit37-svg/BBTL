// Đọc giá trị thuộc tính dạng chuỗi của CEGUI 0.4.1 (PropertyHelper trong _ref): UDim "{s,o}",
// UVector2 "{{s,o},{s,o}}", URect "{{s,o},{s,o},{s,o},{s,o}}", bool "True"/"False", ảnh "set:<bộ>
// image:<ảnh>", màu "AARRGGBB" và ColourRect "tl:... tr:... bl:... br:...". Chuỗi hỏng cho nullopt;
// chỗ gọi giữ giá trị mặc định như CEGUI (sscanf không đọc được thì biến giữ nguyên).
// Nguồn: TLBB Dev src/gui/gui_value.hpp@e0d89a6. Khác gốc: namespace game::gui; số đọc qua
// core::parse_double rồi ép sang float (client gốc đọc thẳng %g, sai khác chỉ ở bit cuối của vài
// chuỗi nằm đúng giữa hai số float).
#pragma once

#include "gui/asset.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::gui {

struct UVector {
    GuiUDim x;
    GuiUDim y;
};

// Vùng thống nhất: góc trên trái min và góc dưới phải max.
struct URect {
    UVector min;
    UVector max;
};

struct ImageName {
    std::string_view set;
    std::string_view image;
};

using TagValue = std::optional<std::string_view>;

// UDim "{scale,offset}".
[[nodiscard]] std::optional<GuiUDim> parse_udim(std::string_view text) noexcept;
[[nodiscard]] std::optional<UVector> parse_uvector(std::string_view text) noexcept;
[[nodiscard]] std::optional<URect> parse_urect(std::string_view text) noexcept;
// "True" và "true" là đúng, như stringToBool; còn lại là sai.
[[nodiscard]] bool parse_bool(std::string_view text) noexcept;
[[nodiscard]] std::optional<float> parse_float(std::string_view text) noexcept;
// Mượn chuỗi text.
[[nodiscard]] std::optional<ImageName> parse_image(std::string_view text) noexcept;
// Giá trị của một thẻ trong chuỗi nhiều thẻ cách nhau bằng dấu cách, như animate trong
// "type:Animate10 animate:Minimap_arrow". key gồm cả dấu hai chấm và phải đứng đầu một thẻ; giá
// trị rỗng cho nullopt. Mượn chuỗi text.
[[nodiscard]] TagValue tagged_value(std::string_view text, std::string_view key) noexcept;
// Ảnh đứng sau các thẻ khác, như "name:Time1 set:CommonStaticImage image:Minimap_Time1" của
// ChildImage và IconImage; chuỗi chỉ có "set:... image:..." cũng nhận. Mượn chuỗi text.
[[nodiscard]] std::optional<ImageName> tagged_image(std::string_view text) noexcept;
[[nodiscard]] std::optional<std::uint32_t> parse_colour(std::string_view text) noexcept;
// ColourRect; một màu đơn cũng nhận, áp cho cả bốn góc.
[[nodiscard]] std::optional<GuiColours> parse_colours(std::string_view text) noexcept;
// Hai màu ARGB nhân từng kênh như colour::operator*= rồi colour::calculateARGB của CEGUI: kênh
// thành số thực trên 255, nhân, cắt về số nguyên. Nhân với trắng giữ nguyên màu.
[[nodiscard]] std::uint32_t modulate(std::uint32_t first, std::uint32_t second) noexcept;

} // namespace game::gui
