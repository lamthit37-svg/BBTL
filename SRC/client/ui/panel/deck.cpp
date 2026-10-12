#include "ui/panel/deck.hpp"

#include "gui/sheet.hpp"

#include <algorithm>
#include <span>
#include <string>
#include <string_view>

namespace game::ui::panel {

void Deck::clear() noexcept {
    roots_.clear();
    hidden_.clear();
    bars_.clear();
    views_.clear();
    used_ = 0;
}

bool Deck::is_shown(std::string_view root) const noexcept {
    return std::ranges::contains(roots_, root);
}

void Deck::show(std::string_view root) {
    if (is_shown(root)) return;
    roots_.push_back(root);
}

void Deck::hide(std::string_view window) {
    hidden_.push_back(window);
}

void Deck::reveal(std::string_view window) {
    const gui::Override shown{.window = window, .name = "Visible", .value = "True"};
    set(shown);
}

void Deck::set(const gui::Override& said) {
    const Key key{.window = said.window, .name = said.name};
    compose(key).assign(said.value);
}

std::string& Deck::compose(const Key& key) {
    if (used_ == entries_.size()) entries_.emplace_back();
    Entry& entry = entries_.at(used_);
    entry.window = key.window;
    entry.name = key.name;
    entry.value.clear();
    ++used_;
    return entry.value;
}

void Deck::bar(std::string_view window, float amount) {
    bars_.push_back(gui::Bar{.window = window, .amount = amount});
}

std::span<const gui::Override> Deck::overrides() {
    views_.clear();
    views_.reserve(used_);
    for (const Entry& entry : std::span(entries_).first(used_)) {
        const gui::Override view{.window = entry.window, .name = entry.name, .value = entry.value};
        views_.push_back(view);
    }
    return views_;
}

} // namespace game::ui::panel
