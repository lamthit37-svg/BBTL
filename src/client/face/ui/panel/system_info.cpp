// Hộp thông báo của thủ tục đăng nhập (xem system_info.hpp).
#include "ui/panel/system_info.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <cstdint>
#include <format>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kRoot = "SelectServerQuest_Frame";
constexpr std::string_view kFrame = "SelectServerQuest_Frame_sub";
constexpr std::string_view kInfoWindow = "SelectServerQuest_InfoWindow";
constexpr std::string_view kSecondButton = "SelectServerQuest_Button2";
constexpr std::string_view kLostPassword = "SelectServerQuest_LostPassword";
constexpr std::string_view kBetterServer = "SelectServerQuest_BetterServer";
constexpr std::string_view kQuit = "SelectServerQuest_Quit";
constexpr std::string_view kTimeText = "SelectServerQuest_Time_Text";
constexpr std::string_view kCloseLabel = "关闭";

// MaxWidth và MinHeight của InfoWindow trong layout, lề chữ của look TLBB_Look_SelfWindow (TextArea cách
// mép 3 điểm), chiều cao tiêu đề và hàng nút của khung (nTitleHeight và nBottomHeight của
// LoginSelectUpdateRect), bề rộng khung.
constexpr float kMaxWidth = 326.0F;
constexpr float kMinHeight = 25.0F;
constexpr float kMargin = 3.0F;
constexpr float kTitleHeight = 23.0F;
constexpr float kBottomHeight = 25.0F;
constexpr float kFrameWidth = 346.0F;
// GuiTextHorz::kWordWrapLeftAligned: HorzFormatting của InfoWindow.
constexpr std::uint8_t kWrapLeft = 4;

// Cỡ của InfoWindow sau khi nó tự co theo chữ: khối chữ bẻ dòng trong bề rộng tối đa trừ hai lề, cộng
// lại hai lề; rộng không quá kMaxWidth, cao không dưới kMinHeight.
struct Fit {
    float width = 0.0F;
    float height = kMinHeight;
};

[[nodiscard]] Fit fit_of(std::string_view text, const gui::TextMeter* meter) {
    if (meter == nullptr) return {};
    const gui::TextSize block = meter->formatted_size(text, kMaxWidth - (2.0F * kMargin), kWrapLeft);
    return Fit{.width = std::min(block.width + (2.0F * kMargin), kMaxWidth),
        .height = std::max(block.height + (2.0F * kMargin), kMinHeight)};
}

} // namespace

void show_system_info(SystemInfo& info, std::string_view text) {
    info.is_open = true;
    info.text.assign(text);
}

void press_system_info(SystemInfo& info, std::string_view window) noexcept {
    if (info.is_open && window == kSystemInfoClose) info.is_open = false;
}

void paint_system_info(Deck& deck, const SystemInfo& info, const gui::TextMeter* meter) {
    if (!info.is_open) return;
    const Fit fit = fit_of(info.text, meter);
    deck.show(kRoot);
    deck.hide(kSecondButton);
    deck.hide(kLostPassword);
    deck.hide(kBetterServer);
    deck.hide(kQuit);
    deck.hide(kTimeText);
    // Khung cao bằng tiêu đề, hàng nút và ô chữ (LoginSelectUpdateRect đặt AbsoluteHeight).
    const std::string size = std::format("{{{{0.000000,{:.6f}}},{{0.000000,{:.6f}}}}}", kFrameWidth,
        kTitleHeight + kBottomHeight + fit.height);
    deck.set(gui::Override{.window = kFrame, .name = "UnifiedSize", .value = size});
    const std::string box = std::format("w:{:.6f} h:{:.6f}", fit.width, fit.height);
    deck.set(gui::Override{.window = kInfoWindow, .name = "AbsoluteSize", .value = box});
    deck.set(gui::Override{.window = kInfoWindow, .name = "Text", .value = info.text});
    deck.set(gui::Override{.window = kSystemInfoClose, .name = "Text", .value = kCloseLabel});
}

} // namespace game::ui::panel
