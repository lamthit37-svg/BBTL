#include "ui/panel/function_bar_right.hpp"

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <vector>

namespace game::ui::panel {

void on_function_bar_right_event(
    ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    if (facts.gm_visible_type != 0 || facts.viewer_watching > 0) {
        bar.is_shown = false;
        return;
    }
    if (on_bar_event(bar, event, facts, calls)) return;
    if (event.name == "PLAYER_ENTERING_WORLD") {
        bar.is_shown = true;
    } else if (event.name == "SHOW_TRANSFIGURATION_SKILL") {
        if (event.arg(0) == "2") {
            bar.is_shown = false;
        } else if (event.arg(0) == "0") {
            bar.is_shown = true;
        }
    }
}

} // namespace game::ui::panel
