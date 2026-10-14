#include "ui/panel/action_bars.hpp"

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/function_bar_right_2.hpp"
#include "ui/panel/main_menu_bar_4.hpp"

#include <algorithm>
#include <cstdint>
#include <optional>
#include <string_view>
#include <vector>

namespace game::ui::panel {

ActionBars::ActionBars() {
    windows_.push_back(BarWindow{
        .bar = make_main_menu_bar_4(), .events = kMainMenuBar4Events, .on_event = &on_main_menu_bar_4_event});
    windows_.push_back(BarWindow{.bar = make_function_bar_right_2(),
        .events = kFunctionBarRight2Events,
        .on_event = &on_function_bar_right_2_event});
}

void ActionBars::raise(const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls) {
    for (BarWindow& window : windows_) {
        if (is_delivered(window.events, event.name, window.bar.is_shown)) window.on_event(window.bar, event, facts, calls);
    }
}

void ActionBars::press(std::string_view window, bool can_do, std::vector<Call>& calls) const {
    for (const BarWindow& item : windows_) {
        if (const std::optional<std::int32_t> id = bar_button_id(item.bar, window)) {
            press_bar_button(item.bar, *id, can_do, calls);
            return;
        }
    }
}

void ActionBars::paint(Deck& deck) const {
    for (const BarWindow& window : windows_)
        paint_action_bar(deck, window.bar);
}

const ActionBar* ActionBars::find(std::string_view name) const noexcept {
    const auto found = std::ranges::find(windows_, name, [](const BarWindow& window) { return window.bar.spec->name; });
    return found == windows_.end() ? nullptr : &found->bar;
}

} // namespace game::ui::panel
