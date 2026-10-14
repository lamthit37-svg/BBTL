#include "ui/panel/function_bar_right_2.hpp"

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <vector>

namespace game::ui::panel {

void on_function_bar_right_2_event(
    ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    if (on_bar_event(bar, event, facts, calls)) return;
    if (event.name == "OPEN_RIGHT_BAR_2") bar.is_shown = event.arg(0) == "1" && facts.transform != 1;
}

} // namespace game::ui::panel
