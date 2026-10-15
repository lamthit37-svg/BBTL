#include "ui/script/context.hpp"

#include "ui/panel/call.hpp"

#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::script {

// NOLINTNEXTLINE(bugprone-exception-escape)
void Context::push_event(std::string_view event, std::span<const std::string_view> args) noexcept {
    if (calls.size() >= kCallLimit) {
        ++dropped_calls;
        return;
    }
    std::string text(event);
    for (const std::string_view arg : args) {
        text += '\t';
        text += arg;
    }
    calls.push_back(panel::Call{.ask = panel::Ask::kPushEvent, .text = std::move(text)});
}

} // namespace game::ui::script
