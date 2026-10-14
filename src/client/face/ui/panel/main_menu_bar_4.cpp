#include "ui/panel/main_menu_bar_4.hpp"

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <string>
#include <vector>

namespace game::ui::panel {
namespace {

// Nhánh OPEN_UP_BAR_2: PushEvent("SWITCH_MENU_BUTTON", 1 hay 0) rồi this:Show() hay this:Hide().
void open_up_bar(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    const bool is_opened = event.arg(0) == "1" && event.arg(1) == "UpBar2" && !facts.is_in_tlcj_scene;
    calls.push_back(Call{.ask = Ask::kPushEvent, .text = std::string(is_opened ? "SWITCH_MENU_BUTTON\t1" : "SWITCH_MENU_BUTTON\t0")});
    bar.is_shown = is_opened;
}

} // namespace

void on_main_menu_bar_4_event(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    if (on_bar_event(bar, event, facts, calls)) return;
    if (event.name == "OPEN_UP_BAR_2") open_up_bar(bar, event, facts, calls);
}

} // namespace game::ui::panel
