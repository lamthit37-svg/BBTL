#include "ui/text.hpp"

#include "core/text.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "render/ui.hpp"
#include "resource/image.hpp"
#include "ui/pace.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui {
namespace {

constexpr std::uint32_t kAlphaMask = 0xFF000000U;
constexpr std::uint32_t kRgbMask = 0x00FFFFFFU;

// Mã điều khiển của chuỗi đã đọc thẻ: bộ phân tích UI_CEGUI.dll 0x18004b170 sinh, drawTextLine
// CEGUIBase.dll 0x18004b250 đọc qua bảng nhảy 0x18004ced0 (byte cao trừ 0xD0).
constexpr Code kKindMask = 0xFF000000U;
constexpr Code kParamMask = 0x00FFFFFFU;
constexpr Code kGradient = 0xD0000000U;
constexpr Code kBlinkOn = 0xE0000000U;
constexpr Code kBlinkOff = 0xE1000000U;
constexpr Code kAlpha = 0xE2000000U;
constexpr Code kMotion = 0xE3000000U;
constexpr Code kUnderlineOn = 0xE6000000U;
constexpr Code kUnderlineOff = 0xE7000000U;
constexpr Code kLinkColour = 0xE8000000U;
constexpr Code kEffect = 0xE9000000U;
constexpr Code kFace = 0xFA000000U;
constexpr Code kColour = 0xFB000000U;
constexpr Code kEdge = 0xFC000000U;
constexpr Code kLinkOn = 0xFD000000U;
constexpr Code kLinkOff = 0xFE000000U;
// Tham số lớn hơn FF của mã alpha là "thôi ép alpha"; bộ phân tích sinh đúng số này ở cuối chuỗi.
constexpr Code kAlphaOff = kAlpha | 0x00FF0000U;
// Màu liên kết quanh #{_INFOMAP...} (UI_CEGUI.dll 0x18004e80f, 0x18004e82d); 00CCFF cũng là màu
// drawTextLine tự đặt khi chưa mã nào đặt màu liên kết (CEGUIBase.dll 0x18004b80c).
constexpr Code kMapLink = kLinkColour | 0x000099E5U;
constexpr Code kPlainLink = kLinkColour | 0x0000CCFFU;
constexpr std::uint32_t kDefaultLink = 0xFF00CCFFU;
constexpr Code kWhiteMark = kColour | 0x00FFFFFFU;

// Trần của một lần scan_markup. Khác gốc: bản gốc đệ quy và nối chuỗi không trần.
constexpr std::size_t kMaxDepth = 4;
constexpr std::size_t kMaxCodes = 16384;
constexpr std::size_t kMaxLookups = 256;

// Hằng của Font (CEGUIBase.dll .rdata 0x1801e7354, 0x1801e7358) và của phép bẻ dòng (0x1801e7368,
// 0x1801e737c).
constexpr float kLineSpace = 3.0F;
constexpr float kGlyphPad = 2.0F;
constexpr std::size_t kLookBack = 12;
constexpr std::array<Code, 5> kBreakers = {U' ', U',', U'.', U'?', U'!'};
// Bước dời của phông bitmap trong drawText (0x18004aacb) và độ lệch của ô bitmap trong ô glyph.
constexpr float kBitmapShift = 1.0F;
constexpr float kBitmapDrop = 1.0F;
constexpr float kHalf = 0.5F;
constexpr float kCaretWidth = 1.0F;
// GuiTextHorz: 0 trái, 1 phải, 2 giữa, 3 justified; cộng 4 là cùng kiểu có bẻ dòng.
constexpr std::uint8_t kRightAligned = 1;
constexpr std::uint8_t kCentreAligned = 2;
constexpr std::uint8_t kJustified = 3;
constexpr std::uint8_t kWrapFirst = 4;
constexpr std::uint8_t kWrapLast = 7;
constexpr std::uint8_t kVertCentre = 1;
constexpr std::uint8_t kVertBottom = 2;

struct ColourKey {
    char key = '\0';
    Code mark = 0;
};

// Mười hai thẻ màu một chữ cái của bản 2026 (0x18004b4d5..0x18004b932).
constexpr std::array<ColourKey, 12> kColourKeys = {{
    {.key = 'R', .mark = 0xFBFFC0CBU},
    {.key = 'G', .mark = 0xFB00FF00U},
    {.key = 'B', .mark = 0xFB00B4FFU},
    {.key = 'K', .mark = 0xFB000000U},
    {.key = 'P', .mark = 0xFBFF99CCU},
    {.key = 'H', .mark = 0xFB00FFFFU},
    {.key = 'I', .mark = 0xFBFFFFCCU},
    {.key = 'Y', .mark = 0xFBFFFF00U},
    {.key = 'W', .mark = 0xFBFFFFFFU},
    {.key = 'L', .mark = 0xFB6A3906U},
    {.key = 'M', .mark = 0xFB1F941EU},
    {.key = 'N', .mark = 0xFBE4007FU},
}};

// Đọc thẻ

[[nodiscard]] constexpr bool is_space(char letter) noexcept {
    return letter == ' ' || (letter >= '\t' && letter <= '\r');
}

[[nodiscard]] constexpr bool is_digit(char letter) noexcept {
    return letter >= '0' && letter <= '9';
}

[[nodiscard]] constexpr std::optional<std::uint32_t> hex_digit(char letter) noexcept {
    if (is_digit(letter)) return static_cast<std::uint32_t>(letter - '0');
    if (letter >= 'a' && letter <= 'f') return static_cast<std::uint32_t>(letter - 'a') + 10U;
    if (letter >= 'A' && letter <= 'F') return static_cast<std::uint32_t>(letter - 'A') + 10U;
    return std::nullopt;
}

// sscanf(" %6X") và sscanf(" %2X") của bản gốc trên một trường đã cắt đúng bề rộng: bỏ khoảng trắng
// đầu, nhận một dấu và tiền tố 0x, đọc chữ số hex tới ký tự lạ; không chữ số nào thì 0.
[[nodiscard]] constexpr std::uint32_t scan_hex(std::string_view field) noexcept {
    while (!field.empty() && is_space(field.front())) field.remove_prefix(1);
    const bool is_negative = field.starts_with('-');
    if (is_negative || field.starts_with('+')) field.remove_prefix(1);
    if (field.starts_with("0x") || field.starts_with("0X")) field.remove_prefix(2);
    std::uint32_t value = 0;
    for (const char letter : field) {
        const std::optional<std::uint32_t> digit = hex_digit(letter);
        if (!digit) break;
        value = (value << 4U) | *digit;
    }
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
    return size;
}

// getFormattedSize (0x18004e7f0): các đoạn giữa hai dấu xuống dòng; đoạn không mở đầu chuỗi cộng
// 3, đoạn rỗng cao font_height. Chỉ bề rộng của area được dùng.
gui::TextSize Typesetter::formatted_size(std::span<const Code> text, const Area& area, std::uint8_t format) const {
    if (text.empty() || format > kWrapLast) return {};
    const float width = cut(area.right + kHalf) - cut(area.left + kHalf);
    gui::TextSize size;
    for (std::size_t first = 0;;) {
        const Segment part = segment_at(text, first);
        const gui::TextSize one = format >= kWrapFirst ? wrapped_size(part.codes, width) : line_size(part.codes);
        size.height += (first != 0 ? kLineSpace : 0.0F) + std::max(one.height, height_);
        size.width = std::max(size.width, one.width);
        if (part.is_last) break;
        first += part.codes.size() + 1;
    }
    return size;
}

// Kết quả của drawText (0x18004b1b3): cao khối không nhỏ hơn cao phông, kể cả khi chuỗi rỗng.
float Typesetter::sealed(float total) const noexcept {
    return height_ <= total ? total : height_;
}

// Canh dọc trước drawText. TextComponent của look (CEGUIBase.dll 0x180128453): giữa cộng nửa phần
// thừa, không làm tròn. FalagardSimpleText (CEGUIFalagard.dll 0x18004e552): trên cộng 1, giữa cộng
// nửa phần thừa đã cộng 0,5 và cắt. Cả hai: dưới là đáy trừ cao khối. Chuỗi rỗng không vẽ gì.
void Typesetter::settle(Area& area, const gui::TextRun& run, std::span<const Code> text) const {
    if (run.rule == gui::TextRule::kRaw || text.empty()) return;
    const bool is_simple = run.rule == gui::TextRule::kSimpleText;
    const float height = formatted_size(text, area, run.horz).height;
    const float spare = ((area.bottom - area.top) - height) * kHalf;
    if (run.vert == kVertBottom) {
        area.top = area.bottom - height;
    } else if (run.vert == kVertCentre) {
        area.top = is_simple ? area.top + cut(spare + kHalf) : spare + area.top;
    } else if (is_simple && run.vert == 0) {
        area.top += 1.0F;
    }
}

// drawText (0x18004aa60) của lời gọi ngoài: ô dời lên 1 và làm nguyên, rồi theo kiểu canh. Trạng
// thái màu đã được write đặt lại (tham số reset = true của bản gốc).
float Typesetter::draw_text(std::span<const Code> text, const Area& area, std::uint8_t format) {
    const Area whole = snapped(area);
    if (format >= kWrapFirst && format <= kWrapLast) {
        return sealed(draw_wrapping(text, whole, static_cast<std::uint8_t>(format - kWrapFirst)));
    }
    return sealed(draw_rows(text, whole, format));
}

// Các đoạn giữa hai dấu xuống dòng của một kiểu không bẻ dòng, mỗi đoạn một dòng (0x18004adf0).
// whole là ô đã dời và làm nguyên. Trả tổng cao: mỗi dòng cao phông cộng 3, kể cả dòng rỗng. Canh
// giữa cộng thêm 1 sau khi cắt (0x18004afdb); canh phải không làm tròn thêm. Kiểu 3 và kiểu lạ:
// bản gốc ném lỗi ngay ở đoạn đầu.
float Typesetter::draw_rows(std::span<const Code> text, const Area& whole, std::uint8_t format) {
    if (text.empty() || is_aborted_) return 0.0F;
    if (format >= kJustified) {
        is_aborted_ = true;
        return 0.0F;
    }
    Corner pen{.x = whole.left, .y = whole.top};
    float total = 0.0F;
    for (std::size_t first = 0;;) {
        const Segment part = segment_at(text, first);
        const float spare = (whole.right - whole.left) - extent(part.codes);
        pen.x = whole.left;
        if (format == kRightAligned) pen.x = whole.right - extent(part.codes);
        if (format == kCentreAligned) pen.x = cut((spare * kHalf) + whole.left + kHalf) + 1.0F;
        const float drawn = draw_line(part.codes, pen);
        pen.y += drawn;
        total += drawn;
        if (part.is_last) break;
        first += part.codes.size() + 1;
    }
    return total;
}

// Các đoạn giữa hai dấu xuống dòng của một kiểu bẻ dòng (nhánh 4..7 của drawText, 0x18004b01f):
// mỗi đoạn qua drawWrappedText, ô tụt xuống theo cao đoạn vừa vẽ. format là kiểu trong (0..3).
// dòng rỗng vẫn chiếm font_height. Mỗi dòng vẽ bằng một drawText lồng: ô lại dời lên 1 (dời đúp).
// Kết thúc: đầu dòng tăng nghiêm ngặt sau mỗi lần cắt, nên số lần cắt không quá số phần tử.
float Typesetter::draw_wrapped(std::span<const Code> text, const Area& area, std::uint8_t format) {
    const float width = area.right - area.left;
    Area dest = area;
    float total = 0.0F;
    std::size_t first = 0;
    Tally tally;
    for (std::size_t index = 0; index < text.size(); ++index) {
        Tally tried = tally;
        add(tried, text[index]);
        if (!(std::max(0.0F, tried.width) > width)) {
            tally = tried;
            continue;
        }
        std::size_t count = index - first;
        const auto tail = text.subspan(first + count - std::min(count, kLookBack), std::min(count, kLookBack));
        const auto found = std::ranges::find_if(tail.rbegin(), tail.rend(), is_breaker);
        const bool is_backed = !is_breaker(text[index]) && found != tail.rend();
        const auto back = is_backed ? static_cast<std::size_t>(found - tail.rbegin()) + 1 : std::size_t{0};
        count -= back;
        index -= back;
        const float drawn = sealed(draw_rows(text.subspan(first, count), snapped(dest), format));
        dest.top += drawn;
        dest.bottom += drawn;
        total += drawn;
        if (count > 1) --index;
        first = index + 1;
        tally = {};
    }
    const std::uint8_t last = format == kJustified ? std::uint8_t{0} : format;
    return total + sealed(draw_rows(text.subspan(first), snapped(dest), last));
}

// drawTextLine (0x18004b250): pen.y là mép trên ô glyph, pen.x là cột bitmap đầu. Trả cao dòng cộng
// 3; với phông bitmap mọi ô glyph cao bằng cao phông nên bước dòng là S + 5.
float Typesetter::draw_line(std::span<const Code> text, Corner pen) {
    for (const Code code : text) {
        if (is_glyph(code)) {
            draw_glyph(code, pen);
        } else {
            apply(ink_, code);
        }
    }
    last_ = pen;
    return height_ + kLineSpace;
}

// Trong liên kết, dấu { mở khoá, dấu } đóng, chữ ở giữa là khoá: không vẽ, bút không tiến
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
        Stamp shifted = stamp;
        shifted.left += nudge.across;
        shifted.top += nudge.down;
        shifted.tint = flat(ink_.edge);
        push_stamp(shifted, clip_, *out_);
    }
}

// Gạch chân (0x18004bc33): bản gốc kéo ảnh "view" của phông (0x18004a120: S x S, chỉ hàng cuối
// sáng) vào ô rộng bằng bước ngang và cao bằng ô glyph, tức một nét ở hàng cuối của ô glyph. Màu:
// màu liên kết, màu dưới của gradient, hoặc màu chữ.
// Chưa kiểm: với lấy mẫu tuyến tính nét gốc nhoè sang hàng trên; ở đây là đúng một hàng điểm ảnh.
void Typesetter::draw_underline(const Corner& pen, float advance) {
    if (!writer_->solid_) return;
    const std::uint32_t colour = ink_.in_link || ink_.top == ink_.bottom ? tint_now().bottom : ink_.bottom;
    const Limits wide{.low = std::max(pen.x, clip_.x), .high = std::min(pen.x + advance, clip_.x + clip_.w)};
    const Limits tall{.low = std::max(pen.y + height_ - 1.0F, clip_.y),
        .high = std::min(pen.y + height_, clip_.y + clip_.h)};
    if (wide.high <= wide.low || tall.high <= tall.low) return;
    const TextWriter::Texel& dot = *writer_->solid_;
    out_->push_back({.x = wide.low, .y = tall.low, .u = dot.u, .v = dot.v, .colour = colour});
    out_->push_back({.x = wide.high, .y = tall.low, .u = dot.u, .v = dot.v, .colour = colour});
    out_->push_back({.x = wide.high, .y = tall.high, .u = dot.u, .v = dot.v, .colour = colour});
    out_->push_back({.x = wide.low, .y = tall.high, .u = dot.u, .v = dot.v, .colour = colour});
}

std::optional<gui::Box> Typesetter::write(const gui::TextRun& run, std::span<const Code> text, Vertices& out) {
    out_ = &out;
    clip_ = run.clip.value_or(run.box);
    if (run.rule == gui::TextRule::kEdit) return write_edit(run, text);
    Area area{.top = run.box.y, .bottom = run.box.y + run.box.h, .left = run.box.x, .right = run.box.x + run.box.w};
    settle(area, run, text);
    ink_ = Ink{};
    ink_.text = run.colour;
    ink_.base_alpha = run.colour & kAlphaMask;
    const Area whole = snapped(area);
    last_ = {.x = whole.left, .y = whole.top};
    static_cast<void>(draw_text(text, area, run.horz));
    if (!run.has_caret) return std::nullopt;
    return gui::Box{.x = last_.x, .y = last_.y, .w = kCaretWidth, .h = height_};
}

// Ô nhập (TextRule::kEdit): giữ cách dàn của bản viết trước, theo FalagardIMEEditBox của mã 2008
// (bản 2026 chưa tháo). Dòng cao S + 2, mép trái và mép trên làm tròn nửa lên, ô bitmap thấp hơn
// mép dòng 1, bước ngang lấy thẳng từ tệp phông, mã phông không có thì bỏ, mã điều khiển bỏ qua.
// Không bẻ dòng: gui chỉ đưa kiểu canh một dòng cho ô nhập.
float Typesetter::edit_width(std::span<const Code> row) const {
    float width = 0.0F;
    for (const Code code : row) {
        if (is_glyph(code)) width += writer_->cell_of(code).file_advance;
    }
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
