#include "ui/panel/debug_list_box.hpp"

#include "core/text.hpp"
#include "ui/panel/data_pool.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::panel {
namespace {

// Biến cục bộ max_size của script: số byte tối đa của một lời nhắn.
constexpr std::size_t kMaxSize = 400;
// Số mục tối đa của InfoList (FalagardInfoList::FalagardInfoList, 0x18006b676), Life và FadeSpeed của layout.
constexpr std::size_t kMaxInfo = 5;
constexpr std::int32_t kLifeMs = 5000;
constexpr std::int32_t kFadeSpeed = 128;
// Màu mặc định của script khi GetUIColor trả "-1".
constexpr std::string_view kNoColour = "-1";
constexpr std::string_view kDefaultFont = "00FFFF";
constexpr std::string_view kDefaultExtent = "010101";
// updateSelf chia tốc độ mờ cho 255 (0x180136544) và nhân thời gian với 1000 để ra ms (0x180135ab8).
constexpr float kFadeScale = 255.0F;
constexpr double kMillisecondsPerSecond = 1000.0;

// Đồng bộ bản chữ của các mục sang Widgets: ClearListBox rồi AddItem từng mục.
void sync_items(DebugListBox& panel) {
    panel.widgets.clear_list(kDebugListBoxList);
    for (const InfoLine& line : panel.lines)
        panel.widgets.add_item(kDebugListBoxList, ListItem{.text = line.text, .id = 0, .colour = {}});
}

// FalagardInfoList::AddInfo: mục mới, NormalizeItemNumber, rồi setVisible(true) cho danh sách.
void add_info(DebugListBox& panel, std::string text) {
    panel.lines.push_back(InfoLine{.text = std::move(text), .life_ms = kLifeMs, .fade_speed = kFadeSpeed, .alpha = 1.0F});
    if (panel.lines.size() > kMaxInfo)
        panel.lines.erase(panel.lines.begin(), panel.lines.end() - static_cast<std::ptrdiff_t>(kMaxInfo));
    sync_items(panel);
    panel.widgets.show(kDebugListBoxList);
}

// Phần của lời nhắn mà script giữ lại: cả chuỗi khi không quá kMaxSize byte; không thì kMaxSize byte đầu, hay
// kMaxSize - 1 khi Check_StringCode báo kMaxSize byte đầu kết thúc giữa một ký tự.
[[nodiscard]] std::string_view kept_part(std::string_view message) noexcept {
    if (message.size() <= kMaxSize) return message;
    const bool is_whole = check_string_code(message.substr(0, kMaxSize));
    // Khác gốc: lùi tới đầu ký tự UTF-8 (xem đầu debug_list_box.hpp); utf8_prefix xét byte ngay sau phần giữ lại.
    return core::utf8_prefix(message, is_whole ? kMaxSize : kMaxSize - 1);
}

[[nodiscard]] std::string_view or_default(std::string_view colour, std::string_view fallback) noexcept {
    return colour == kNoColour ? fallback : colour;
}

} // namespace

void debug_list_box_event(DebugListBox& panel, const UiEvent& event, UiColour colour) {
    if (event.name == "APPLICATION_INITED") {
        panel.is_shown = true;
        panel.lines.clear();
        sync_items(panel);
        return;
    }
    if (event.name == "NEW_DEBUGMESSAGE") debug_list_box_update(panel, event.arg(0), colour);
}

void debug_list_box_update(DebugListBox& panel, std::optional<std::string_view> arg0, UiColour colour) {
    panel.is_shown = true;
    if (!arg0) return;
    const std::string_view font = or_default(colour.font, kDefaultFont);
    const std::string_view extent = or_default(colour.extent, kDefaultExtent);
    add_info(panel, std::format("#c{}#e{}{}", font, extent, kept_part(*arg0)));
}

void debug_list_box_tick(DebugListBox& panel, float seconds) {
    // Thời gian âm hay NaN tính là 0; vô hạn hay quá lớn kẹp ở mức int32 lớn nhất (double biểu diễn đúng mức đó).
    const float step = seconds > 0.0F ? seconds : 0.0F;
    const auto elapsed = static_cast<std::int32_t>(
        std::min(static_cast<double>(step) * kMillisecondsPerSecond, static_cast<double>(std::numeric_limits<std::int32_t>::max())));
    bool is_removed = false;
    // Như vòng của updateSelf: bỏ một mục thì mục kế dồn vào chỗ đó và bị bỏ qua tới nhịp sau.
    for (std::size_t index = 0; index < panel.lines.size(); ++index) {
        InfoLine& line = panel.lines[index];
        line.life_ms = static_cast<std::int32_t>(std::max<std::int64_t>(
            static_cast<std::int64_t>(line.life_ms) - elapsed, std::numeric_limits<std::int32_t>::min()));
        if (line.life_ms >= 0) continue;
        line.alpha -= static_cast<float>(line.fade_speed) * step / kFadeScale;
        if (line.alpha >= 0.0F) continue;
        panel.lines.erase(panel.lines.begin() + static_cast<std::ptrdiff_t>(index));
        is_removed = true;
    }
    if (is_removed) sync_items(panel);
}

void paint_debug_list_box(Deck& deck, const DebugListBox& panel) {
    if (!panel.is_shown) return;
    deck.show(kDebugListBoxRoot);
    panel.widgets.paint(deck);
    if (panel.lines.empty()) return;
    std::string& text = deck.compose(Key{.window = kDebugListBoxList, .name = "Text"});
    for (const InfoLine& line : panel.lines) {
        if (!text.empty()) text += '\n';
        text += line.text;
    }
}

} // namespace game::ui::panel
