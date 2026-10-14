#include "ui/panel/main_menu_bar_2.hpp"

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/lua_value.hpp"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {
namespace {

// Lệnh giao diện của máy chủ mà MainMenuBar_2 nghe: đặt vật phẩm lên thanh rồi chỉ ô đó cho người chơi tân thủ.
constexpr std::string_view kGuideCommand = "20130527";
// Kiểu và hướng của lớp hướng dẫn (đối số thứ sáu và thứ bảy của OpenFreshManGuideNew trong script).
constexpr std::string_view kGuideStyle = "21";
constexpr std::string_view kGuideDirection = "0";

// MainMenuBar_2_PlayAnimate: hiện rồi chạy lặp hoạt ảnh của mười ô.
void play_masks(ActionBar& bar) {
    for (const std::string& mask : bar.masks) {
        bar.widgets.show(mask);
        bar.widgets.play(mask, true);
    }
}

// UI_COMMAND 20130527: nếu PutItemToMainmenuBar2 đã đặt vật phẩm vào một ô của thanh thì mở lớp hướng dẫn tại ô đó.
void open_guide(ActionBar& bar, const BarFacts& facts, std::vector<Call>& calls) {
    const GuideFacts& guide = facts.guide;
    const BarSpec& spec = *bar.spec;
    if (guide.put_is_show != 1) return;
    if (!(guide.put_index > spec.first_id - 1 && guide.put_index <= spec.first_id + spec.count - 1)) return;
    const BarBox& button = guide.buttons.at(static_cast<std::size_t>(guide.put_index - spec.first_id));
    // math.floor(fX + PosX + fW * 0.5) và math.floor(fY + PosY); fW, fH đưa nguyên cho lớp hướng dẫn.
    const double x = std::floor(button.x + guide.frame.x + button.width * 0.5);
    const double y = std::floor(button.y + guide.frame.y);
    calls.push_back(Call{.ask = Ask::kOpenFreshManGuide,
        .text = std::format("1\t{}\t{}\t{}\t{}\t{}\t{}\t{}", lua_tostring(x), lua_tostring(y), lua_tostring(button.width),
            lua_tostring(button.height), kGuideStyle, kGuideDirection, spec.name)});
    bar.is_drawing = true;
}

} // namespace

void on_main_menu_bar_2_event(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    if (on_bar_event(bar, event, facts, calls)) return;
    if (event.name == "OPEN_MENUBAR_2") {
        bar.is_shown = event.arg(0) == "1" && !facts.is_in_tlcj_scene;
        if (bar.is_shown) play_masks(bar);
    } else if (event.name == "UI_COMMAND" && event.arg(0) == kGuideCommand) {
        open_guide(bar, facts, calls);
    }
}

void press_main_menu_bar_2(ActionBar& bar, std::int32_t id, bool can_do, const BarFacts& facts, std::vector<Call>& calls) {
    press_bar_button(bar, id, can_do, calls);
    const BarSpec& spec = *bar.spec;
    const bool is_slot = id >= spec.first_id && id < spec.first_id + spec.count;
    if (!can_do || !is_slot || !bar.is_drawing) return;
    bar.is_drawing = false;
    if (facts.guide.owner == spec.name) calls.push_back(Call{.ask = Ask::kCloseFreshManGuide, .text = {}});
}

} // namespace game::ui::panel
