#include "ui/panel/widgets.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";
// Thuộc tính độ trong của cửa sổ và giá trị "mờ hẳn".
constexpr std::string_view kAlpha = "Alpha";
constexpr std::string_view kClear = "0";

[[nodiscard]] constexpr std::string_view truth(bool value) noexcept {
    return value ? kTrue : kFalse;
}

// Hai ký tự thay cho một ký tự điều khiển trong tệp trọng tài; rỗng khi ký tự giữ nguyên.
[[nodiscard]] constexpr std::string_view escape_of(char letter) noexcept {
    if (letter == '\\') return "\\\\";
    if (letter == '\n') return "\\n";
    if (letter == '\r') return "\\r";
    return {};
}

// Giá trị trên một dòng, như flat của TOOLS/port/lua_oracle.lua: gạch chéo ngược, xuống dòng và về
// đầu dòng viết thành hai ký tự.
[[nodiscard]] std::string flat(std::string_view value) {
    std::string out;
    out.reserve(value.size());
    for (const char letter : value) {
        const std::string_view escape = escape_of(letter);
        if (escape.empty()) out += letter;
        out += escape;
    }
    return out;
}

// Chỉ số của mục đầu tiên mang id; nullopt khi không có.
[[nodiscard]] std::optional<std::size_t> index_of(const std::vector<ListItem>& items, std::int32_t id) noexcept {
    const auto found = std::ranges::find(items, id, &ListItem::id);
    if (found == items.end()) return std::nullopt;
    return static_cast<std::size_t>(found - items.begin());
}

// Một dòng "cửa sổ<tab>tên<tab>giá trị" của tệp trọng tài.
void add_line(std::vector<std::string>& lines, const Key& key, std::string_view value) {
    lines.push_back(std::format("{}\t{}\t{}", key.window, key.name, value));
}

// Dòng của một cờ khi cờ đã được đặt.
void describe_flag(std::vector<std::string>& lines, const Key& key, std::optional<bool> flag) {
    if (flag) add_line(lines, key, truth(*flag));
}

// Dòng của một số khi số đã được đặt.
void describe_number(std::vector<std::string>& lines, const Key& key, std::optional<std::int32_t> number) {
    if (number) add_line(lines, key, std::to_string(*number));
}

void paint_flag(Deck& deck, const Key& key, std::optional<bool> flag) {
    if (!flag) return;
    deck.set(gui::Override{.window = key.window, .name = key.name, .value = truth(*flag)});
}

// Các dòng của một danh sách: số mục rồi từng mục (id, màu, chữ).
void describe_list(std::vector<std::string>& lines, std::string_view window, const std::vector<ListItem>& items) {
    add_line(lines, Key{.window = window, .name = "Items"}, std::to_string(items.size()));
    std::size_t number = 0;
    for (const ListItem& item : items) {
        ++number;
        const std::string name = std::format("Item{}", number);
        const std::string value = std::format("{}\t{}\t{}", item.id, item.colour, flat(item.text));
        add_line(lines, Key{.window = window, .name = name}, value);
    }
}

// Các dòng của một cửa sổ phức hợp: số phần tử rồi từng phần tử.
void describe_elements(std::vector<std::string>& lines, std::string_view window, const std::vector<std::string>& all) {
    add_line(lines, Key{.window = window, .name = "Elements"}, std::to_string(all.size()));
    std::size_t number = 0;
    for (const std::string& element : all) {
        ++number;
        const std::string name = std::format("Element{}", number);
        add_line(lines, Key{.window = window, .name = name}, flat(element));
    }
}

} // namespace

Widgets::Entry& Widgets::entry_of(std::string_view window) {
    const auto found = std::ranges::find(entries_, window, &Entry::window);
    if (found != entries_.end()) return *found;
    Entry& made = entries_.emplace_back();
    made.window = window;
    return made;
}

const Widgets::Entry* Widgets::find(std::string_view window) const noexcept {
    const auto found = std::ranges::find(entries_, window, &Entry::window);
    return found == entries_.end() ? nullptr : &*found;
}

void Widgets::set(const gui::Override& said) {
    Entry& entry = entry_of(said.window);
    const auto found = std::ranges::find(entry.properties, said.name, &Property::name);
    if (found != entry.properties.end()) {
        found->value = said.value;
        return;
    }
    entry.properties.push_back(Property{.name = std::string(said.name), .value = std::string(said.value)});
}

void Widgets::set_text(std::string_view window, std::string_view text) {
    set(gui::Override{.window = window, .name = "Text", .value = text});
}

void Widgets::show(std::string_view window) {
    entry_of(window).is_visible = true;
}

void Widgets::hide(std::string_view window) {
    entry_of(window).is_visible = false;
}

void Widgets::enable(std::string_view window) {
    entry_of(window).is_disabled = false;
}

void Widgets::disable(std::string_view window) {
    entry_of(window).is_disabled = true;
}

void Widgets::check(std::string_view window, bool is_on) {
    entry_of(window).is_checked = is_on;
}

void Widgets::check_one(std::string_view window, std::span<const std::string_view> group) {
    for (const std::string_view other : group)
        entry_of(other).is_checked = false;
    entry_of(window).is_checked = true;
}

void Widgets::push(std::string_view window, bool is_on) {
    entry_of(window).is_pushed = is_on;
}

void Widgets::set_action(std::string_view window, ActionFace face) {
    entry_of(window).action = std::move(face);
}

void Widgets::clear_list(std::string_view window) {
    Entry& entry = entry_of(window);
    entry.items.emplace();
    entry.selected.reset();
    if (entry.first) entry.first = 0;
}

void Widgets::add_item(std::string_view window, ListItem item) {
    Entry& entry = entry_of(window);
    if (!entry.items) entry.items.emplace();
    entry.items->push_back(std::move(item));
}

void Widgets::select_item(std::string_view window, std::int32_t id) {
    Entry& entry = entry_of(window);
    if (!entry.items) return;
    const std::optional<std::size_t> index = index_of(*entry.items, id);
    if (index) entry.selected = index;
}

void Widgets::pick_item(std::string_view window, std::int32_t id) {
    Entry& entry = entry_of(window);
    entry.clicked = id;
    entry.selected = entry.items ? index_of(*entry.items, id) : std::nullopt;
}

void Widgets::set_first_item(std::string_view window, std::int32_t index) {
    entry_of(window).first = index;
}

void Widgets::clear_elements(std::string_view window) {
    entry_of(window).elements.emplace();
}

void Widgets::add_element(std::string_view window, std::string line) {
    Entry& entry = entry_of(window);
    if (!entry.elements) entry.elements.emplace();
    entry.elements->push_back(std::move(line));
}

void Widgets::keep_scroll(std::string_view window) {
    entry_of(window).keeps_scroll = true;
}

void Widgets::reset_scroll(std::string_view window) {
    entry_of(window).keeps_scroll = false;
}

bool Widgets::is_checked(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry != nullptr && entry->is_checked.value_or(false);
}

bool Widgets::is_disabled(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry != nullptr && entry->is_disabled.value_or(false);
}

bool Widgets::is_hidden(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry != nullptr && !entry->is_visible.value_or(true);
}

std::optional<std::int32_t> Widgets::chosen_id(const Entry& entry) noexcept {
    const bool is_chosen = entry.items && entry.selected && *entry.selected < entry.items->size();
    if (!is_chosen) return std::nullopt;
    return (*entry.items)[*entry.selected].id;
}

std::int32_t Widgets::selected_item(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry == nullptr ? kNoItem : chosen_id(*entry).value_or(kNoItem);
}

std::int32_t Widgets::clicked_item(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry == nullptr ? kNoItem : entry->clicked.value_or(kNoItem);
}

std::int32_t Widgets::first_item(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry == nullptr ? 0 : entry->first.value_or(0);
}

std::optional<std::int32_t> Widgets::item_id(std::string_view window, std::size_t index) const noexcept {
    const Entry* entry = find(window);
    if (entry == nullptr || !entry->items || index >= entry->items->size()) return std::nullopt;
    return (*entry->items)[index].id;
}

std::optional<std::string_view> Widgets::value(const Key& key) const noexcept {
    const Entry* entry = find(key.window);
    if (entry == nullptr) return std::nullopt;
    const auto found = std::ranges::find(entry->properties, key.name, &Property::name);
    if (found == entry->properties.end()) return std::nullopt;
    return std::string_view(found->value);
}

std::optional<std::int32_t> Widgets::action(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    if (entry == nullptr || !entry->action) return std::nullopt;
    return entry->action->id;
}

void Widgets::paint_entry(const Entry& entry, Deck& deck) {
    const std::string_view window = entry.window;
    for (const Property& property : entry.properties) {
        deck.set(gui::Override{.window = window, .name = property.name, .value = property.value});
    }
    const auto alpha = std::ranges::find(entry.properties, kAlpha, &Property::name);
    const bool is_clear = alpha != entry.properties.end() && alpha->value == kClear;
    const bool is_shown = entry.is_visible.value_or(false) && !is_clear;
    const bool is_hidden = is_clear || !entry.is_visible.value_or(true);
    if (is_shown) deck.reveal(window);
    if (is_hidden) deck.hide(window);
    paint_flag(deck, Key{.window = window, .name = "Disabled"}, entry.is_disabled);
    paint_flag(deck, Key{.window = window, .name = "Selected"}, entry.is_checked);
    paint_flag(deck, Key{.window = window, .name = "Pushed"}, entry.is_pushed);
    const bool has_icon = entry.action && !entry.action->icon.empty();
    if (has_icon) deck.set(gui::Override{.window = window, .name = "NormalImage", .value = entry.action->icon});
}

void Widgets::paint(Deck& deck) const {
    for (const Entry& entry : entries_) {
        paint_entry(entry, deck);
    }
}

// Thuộc tính đã đặt, xếp theo tên như trọng tài.
void Widgets::describe_properties(const Entry& entry, std::vector<std::string>& lines) {
    std::vector<const Property*> sorted;
    sorted.reserve(entry.properties.size());
    for (const Property& property : entry.properties)
        sorted.push_back(&property);
    std::ranges::sort(sorted, {}, [](const Property* property) { return std::string_view(property->name); });
    for (const Property* property : sorted) {
        add_line(lines, Key{.window = entry.window, .name = property->name}, flat(property->value));
    }
}

void Widgets::describe_entry(const Entry& entry, std::vector<std::string>& lines) {
    const std::string_view window = entry.window;
    describe_properties(entry, lines);
    describe_flag(lines, Key{.window = window, .name = "Visible"}, entry.is_visible);
    describe_flag(lines, Key{.window = window, .name = "Disabled"}, entry.is_disabled);
    describe_flag(lines, Key{.window = window, .name = "Selected"}, entry.is_checked);
    describe_flag(lines, Key{.window = window, .name = "Pushed"}, entry.is_pushed);
    if (entry.action) add_line(lines, Key{.window = window, .name = "ActionItem"}, std::to_string(entry.action->id));
    describe_number(lines, Key{.window = window, .name = "FirstItem"}, entry.first);
    const std::string_view scroll = entry.keeps_scroll.value_or(false) ? "Keep" : "Reset";
    if (entry.keeps_scroll) add_line(lines, Key{.window = window, .name = "Scroll"}, scroll);
    if (entry.items) describe_list(lines, window, *entry.items);
    describe_number(lines, Key{.window = window, .name = "SelectedItem"}, chosen_id(entry));
    if (entry.elements) describe_elements(lines, window, *entry.elements);
}

void Widgets::describe(std::vector<std::string>& lines) const {
    for (const Entry& entry : entries_) {
        describe_entry(entry, lines);
    }
}

} // namespace game::ui::panel
