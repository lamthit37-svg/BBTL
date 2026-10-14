#include "ui/panel/progress_bar.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/lua_value.hpp"

#include <charconv>
#include <format>
#include <memory>
#include <optional>
#include <string_view>
#include <system_error>

namespace game::ui::panel {
namespace {

constexpr std::string_view kFadeStateProperty = "SetFadeState";
constexpr std::string_view kAlphaProperty = "Alpha";
// Hai giá trị mà script đưa cho SetFadeState: "0" hiện lại thanh, "2" cho mờ dần trong hai giây.
constexpr std::string_view kFadeIn = "0";
constexpr std::string_view kFadeOut = "2";

// stringToFloat của CEGUI cho giá trị chữ của thuộc tính; chữ không đọc được thì 0.
[[nodiscard]] float float_of(std::string_view text) noexcept {
    float value = 0.0F;
    const std::from_chars_result done = std::from_chars(std::to_address(text.begin()), std::to_address(text.end()), value);
    return done.ec == std::errc{} ? value : 0.0F;
}

// SetProperty("SetFadeState", value) của thanh (FalagardSuperProgressProperties::SetFadeState).
void set_fade_state(ProgressBar& panel, std::string_view value) {
    panel.widgets.set(gui::Override{.window = kProgressBarRoot, .name = kFadeStateProperty, .value = value});
    const float state = float_of(value);
    panel.is_fading = state > 0.0F;
    if (!panel.is_fading) {
        // Cửa sổ của thanh cũng là `this` của script, nên hiện nó là hiện cả bảng.
        panel.widgets.show(kProgressBarRoot);
        panel.is_shown = true;
    }
    panel.widgets.set(gui::Override{.window = kProgressBarRoot, .name = kAlphaProperty, .value = "1"});
    panel.fade_total = state;
    panel.fade_left = state;
}

} // namespace

void progress_bar_event(ProgressBar& panel, const UiEvent& event) {
    const std::string_view name = event.name;
    if (name == "PROGRESSBAR_SHOW") {
        if (const std::optional<std::string_view> text = event.arg(0)) panel.widgets.set_text(kProgressBarRoot, *text);
        panel.is_shown = true;
        set_fade_state(panel, kFadeIn);
        return;
    }
    if (name == "PROGRESSBAR_HIDE") {
        progress_bar_break(panel);
        return;
    }
    if (name == "PROGRESSBAR_WIDTH") {
        progress_bar_set_width(panel, event.arg(0));
        return;
    }
    if (name == "PLAYER_LEAVE_WORLD") {
        progress_bar_break(panel);
        return;
    }
    if (name == "PROGRESSBAR_BREAK") progress_bar_break(panel);
    if (name == "HIDE_ON_SCENE_TRANSED") panel.is_shown = false;
}

void progress_bar_set_width(ProgressBar& panel, std::optional<std::string_view> arg0) {
    if (!arg0) return;
    const std::optional<double> ratio = lua_tonumber(*arg0);
    if (!ratio) return;
    panel.widgets.set_progress(kProgressBarRoot, *ratio * 100.0, 100.0);
}

void progress_bar_break(ProgressBar& panel) {
    set_fade_state(panel, kFadeOut);
}

void progress_bar_close(ProgressBar& panel) noexcept {
    panel.is_shown = false;
}

void progress_bar_fade(ProgressBar& panel, float seconds) {
    const bool is_running = panel.is_fading && panel.fade_total > 0.0F && panel.is_shown;
    if (!is_running) return;
    panel.fade_left -= seconds;
    const float alpha = panel.fade_left / panel.fade_total;
    panel.widgets.set(gui::Override{.window = kProgressBarRoot, .name = kAlphaProperty, .value = std::format("{}", alpha)});
    if (panel.fade_left < 0.0F) {
        panel.widgets.hide(kProgressBarRoot);
        panel.is_shown = false;
    }
}

void paint_progress_bar(Deck& deck, const ProgressBar& panel) {
    if (!panel.is_shown) return;
    deck.show(kProgressBarRoot);
    panel.widgets.paint(deck);
}

} // namespace game::ui::panel
