// Tên chuỗi của các enum Falagard theo CEGUIFalXMLEnumHelper; chỉ số trong mảng là giá trị enum.
// Bộ nạp look đổi tên trong XML ra chỉ số, bộ vẽ đổi tên trong thuộc tính của cửa sổ ra cùng chỉ
// số đó, nên hai bên dùng chung một bảng ở đây. Nội bộ module gui.
#pragma once

#include "gui/asset.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace game::gui::detail {

// GuiHorz và GuiVert: căn của ảnh.
inline constexpr std::array<std::string_view, 5> kImageHorz = {
    "LeftAligned", "CentreAligned", "RightAligned", "Stretched", "Tiled"};
inline constexpr std::array<std::string_view, 5> kImageVert = {
    "TopAligned", "CentreAligned", "BottomAligned", "Stretched", "Tiled"};
// GuiTextHorz và GuiTextVert: căn của chữ.
inline constexpr std::array<std::string_view, 8> kTextHorz = {"LeftAligned", "RightAligned", "CentreAligned",
    "Justified", "WordWrapLeftAligned", "WordWrapRightAligned", "WordWrapCentreAligned", "WordWrapJustified"};
inline constexpr std::array<std::string_view, 3> kTextVert = {"TopAligned", "CentreAligned", "BottomAligned"};

static_assert(kImageHorz.size() == std::to_underlying(GuiHorz::kTiled) + 1U);
static_assert(kImageVert.size() == std::to_underlying(GuiVert::kTiled) + 1U);
static_assert(kTextHorz.size() == std::to_underlying(GuiTextHorz::kWordWrapJustified) + 1U);
static_assert(kTextVert.size() == std::to_underlying(GuiTextVert::kBottomAligned) + 1U);

} // namespace game::gui::detail
