#include "ui/panel/widgets.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/lua_value.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <type_traits>
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

// Số của script sang float32 như phép ép double sang float của mã gốc; số ngoài miền float32 (mã gốc ra
// vô cực) thành số hữu hạn lớn nhất để phép ép không có hành vi không xác định.
[[nodiscard]] float to_float(double value) noexcept {
    constexpr auto kLimit = static_cast<double>(std::numeric_limits<float>::max());
    return static_cast<float>(std::clamp(value, -kLimit, kLimit));
}

// ProgressBar::setProgress (CEGUIBase.dll 0x1800fb270) trên float(tử) / float(mẫu): mức nhỏ hơn 0 thành 0,
// lớn hơn 1 thành 1.
// Khác gốc: NaN (0 trên 0) thành 0; mã gốc cho NaN đi qua, bộ vẽ thanh không có mức không xác định. Mẫu 0
// ra vô cực (hay NaN) ở mã gốc, ở đây ra 1 hay 0 theo dấu mà không chia cho 0; số ngoài miền float32 bị kẹp
// vào số hữu hạn lớn nhất nên tỉ số vô cực trên vô cực ra 1 thay vì NaN.
[[nodiscard]] float progress_of(const std::pair<double, double>& fraction) noexcept {
    const float current = to_float(fraction.first);
    const float total = to_float(fraction.second);
    if (total == 0.0F) {
        // Tử khác 0 trên mẫu 0 là vô cực mang dấu của tử nhân dấu của mẫu.
        const bool is_infinite_up = (current > 0.0F) != std::signbit(total);
        return (current != 0.0F && is_infinite_up) ? 1.0F : 0.0F;
    }
    const float ratio = current / total;
    if (std::isnan(ratio) || ratio < 0.0F) return 0.0F;
    return ratio > 1.0F ? 1.0F : ratio;
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

// Ô ở hàng row, cột chỉ số column của các hàng rows; nullptr khi ngoài bảng hay ô trống.
template <typename Rows>
[[nodiscard]] auto* find_cell(Rows& rows, std::int32_t row, std::int32_t column) noexcept {
    using Cell = std::conditional_t<std::is_const_v<Rows>, const GridCell, GridCell>;
    Cell* none = nullptr;
    if (row < 0 || column < 0 || std::cmp_greater_equal(row, rows.size())) return none;
    auto& cells = rows[static_cast<std::size_t>(row)];
    if (std::cmp_greater_equal(column, cells.size())) return none;
    auto& cell = cells[static_cast<std::size_t>(column)];
    return cell ? &*cell : none;
}

// lhs + rhs theo số nguyên 32 bit có dấu quay vòng như lệnh máy của mã gốc (ADD và DEC không bắt tràn).
[[nodiscard]] constexpr std::int32_t wrap_add(std::int32_t lhs, std::int32_t rhs) noexcept {
    return static_cast<std::int32_t>(static_cast<std::uint32_t>(lhs) + static_cast<std::uint32_t>(rhs));
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

void Widgets::set_progress(std::string_view window, double current, double total) {
    entry_of(window).progress = std::pair{current, total};
}

void Widgets::flash(std::string_view window) {
    if (action_item(window) == kEmptyAction) return;
    entry_of(window).is_flashing = true;
}

void Widgets::play(std::string_view window, bool is_looping) {
    entry_of(window).is_playing = is_looping;
}

void Widgets::gloom(std::string_view window, bool is_dim) {
    set(gui::Override{.window = window, .name = "Gloom", .value = is_dim ? "True" : "False"});
}

void Widgets::set_fade(std::string_view window, float total) {
    Entry& entry = entry_of(window);
    if (total > 0.0F) {
        entry.fade = Fade{.total = total, .left = total};
    } else {
        entry.fade.reset();
    }
}

std::vector<std::string> Widgets::fading() const {
    std::vector<std::string> names;
    for (const Entry& entry : entries_) {
        if (entry.fade) names.push_back(entry.window);
    }
    return names;
}

bool Widgets::step_fade(std::string_view window, float seconds) {
    Entry& entry = entry_of(window);
    if (!entry.fade) return false;
    entry.fade->left -= seconds;
    set(gui::Override{.window = window, .name = kAlpha, .value = std::format("{}", entry.fade->left / entry.fade->total)});
    if (!(entry.fade->left < 0.0F)) return false;
    hide(window);
    return true;
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

void Widgets::add_info(std::string_view window, ListItem info, std::size_t limit) {
    Entry& entry = entry_of(window);
    if (!entry.items) entry.items.emplace();
    std::vector<ListItem>& items = *entry.items;
    items.push_back(std::move(info));
    const std::size_t surplus = items.size() > limit ? items.size() - limit : 0;
    items.erase(items.begin(), items.begin() + static_cast<std::ptrdiff_t>(surplus));
    if (entry.selected) {
        if (*entry.selected < surplus) {
            entry.selected.reset();
        } else {
            *entry.selected -= surplus;
        }
    }
    entry.is_visible = true;
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

bool Widgets::select_index(std::string_view window, std::size_t index) {
    Entry& entry = entry_of(window);
    if (!entry.items || index >= entry.items->size()) return false;
    entry.selected = index;
    return true;
}

void Widgets::clear_selection(std::string_view window) {
    entry_of(window).selected.reset();
}

bool Widgets::set_item_text(std::string_view window, std::size_t index, std::string text) {
    Entry& entry = entry_of(window);
    if (!entry.items || index >= entry.items->size()) return false;
    (*entry.items)[index].text = std::move(text);
    return true;
}

std::size_t Widgets::item_count(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry == nullptr || !entry->items ? 0 : entry->items->size();
}

const ListItem* Widgets::item_at(std::string_view window, std::size_t index) const noexcept {
    const Entry* entry = find(window);
    if (entry == nullptr || !entry->items || index >= entry->items->size()) return nullptr;
    return &(*entry->items)[index];
}

const ListItem* Widgets::chosen_item(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    if (entry == nullptr || !entry->selected) return nullptr;
    return item_at(window, *entry->selected);
}

Widgets::Grid* Widgets::grid_of(std::string_view window) noexcept {
    const auto found = std::ranges::find(entries_, window, &Entry::window);
    return found == entries_.end() || !found->grid ? nullptr : &*found->grid;
}

const Widgets::Grid* Widgets::grid_of(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry == nullptr || !entry->grid ? nullptr : &*entry->grid;
}

GridCell* Widgets::cell_at(Grid& grid, std::int32_t row, std::int32_t column) noexcept {
    return find_cell(grid.rows, row, column);
}

const GridCell* Widgets::cell_at(const Grid& grid, std::int32_t row, std::int32_t column) noexcept {
    return find_cell(grid.rows, row, column);
}

void Widgets::add_column(std::string_view window, GridColumn column, std::optional<std::size_t> position) {
    Entry& entry = entry_of(window);
    if (!entry.grid) entry.grid.emplace();
    Grid& grid = *entry.grid;
    const std::size_t index = std::min(position.value_or(grid.columns.size()), grid.columns.size());
    grid.columns.insert(grid.columns.begin() + static_cast<std::ptrdiff_t>(index), std::move(column));
    for (auto& row : grid.rows) row.insert(row.begin() + static_cast<std::ptrdiff_t>(index), std::nullopt);
}

bool Widgets::remove_column(std::string_view window, std::size_t index) {
    Grid* grid = grid_of(window);
    if (grid == nullptr || index >= grid->columns.size()) return false;
    grid->columns.erase(grid->columns.begin() + static_cast<std::ptrdiff_t>(index));
    for (auto& row : grid->rows) row.erase(row.begin() + static_cast<std::ptrdiff_t>(index));
    return true;
}

bool Widgets::put_cell(std::string_view window, GridCell cell, std::int32_t row) {
    Entry& entry = entry_of(window);
    if (!entry.grid) entry.grid.emplace();
    Grid& grid = *entry.grid;
    const auto column = std::ranges::find(grid.columns, cell.id, &GridColumn::id);
    if (column == grid.columns.end()) return false;
    const auto index = static_cast<std::size_t>(column - grid.columns.begin());
    if (cell_at(grid, row, 0) != nullptr) {
        grid.rows[static_cast<std::size_t>(row)][index] = std::move(cell);
        return true;
    }
    cell.id = row;
    std::vector<std::optional<GridCell>> made(grid.columns.size());
    made[index] = std::move(cell);
    grid.rows.push_back(std::move(made));
    return true;
}

bool Widgets::set_cell_text(std::string_view window, std::int32_t row, std::int32_t column, std::string text) {
    Grid* grid = grid_of(window);
    GridCell* cell = grid == nullptr ? nullptr : cell_at(*grid, row, column);
    if (cell == nullptr) return false;
    cell->text = std::move(text);
    return true;
}

std::optional<std::string_view> Widgets::cell_text(std::string_view window, std::int32_t row,
    std::int32_t column) const noexcept {
    const Grid* grid = grid_of(window);
    const GridCell* cell = grid == nullptr ? nullptr : cell_at(*grid, row, column);
    if (cell == nullptr) return std::nullopt;
    return std::string_view(cell->text);
}

bool Widgets::set_row_data(std::string_view window, GridRowData data) {
    Grid* grid = grid_of(window);
    GridCell* cell = grid == nullptr ? nullptr : cell_at(*grid, data.row, 0);
    if (cell == nullptr) return false;
    cell->user = wrap_add(data.value, 1);
    return true;
}

std::int32_t Widgets::row_data(std::string_view window, std::int32_t row) const noexcept {
    const Grid* grid = grid_of(window);
    const GridCell* cell = grid == nullptr ? nullptr : cell_at(*grid, row, 0);
    if (cell == nullptr || cell->user == 0) return kNoRow;
    return wrap_add(cell->user, -1);
}

bool Widgets::set_row_tooltip(std::string_view window, std::int32_t row, std::string text) {
    Grid* grid = grid_of(window);
    GridCell* cell = grid == nullptr ? nullptr : cell_at(*grid, row, 0);
    if (cell == nullptr) return false;
    cell->tooltip = std::move(text);
    return true;
}

bool Widgets::remove_row(std::string_view window, std::int32_t row) {
    Grid* grid = grid_of(window);
    if (grid == nullptr || row < 0 || std::cmp_greater_equal(row, grid->rows.size())) return false;
    const auto index = static_cast<std::size_t>(row);
    grid->rows.erase(grid->rows.begin() + static_cast<std::ptrdiff_t>(index));
    if (grid->selected) {
        if (*grid->selected == index) {
            grid->selected.reset();
        } else if (*grid->selected > index) {
            --*grid->selected;
        }
    }
    return true;
}

void Widgets::clear_rows(std::string_view window) {
    Entry& entry = entry_of(window);
    if (!entry.grid) entry.grid.emplace();
    entry.grid->rows.clear();
    entry.grid->selected.reset();
    entry.grid->scroll = 0;
}

bool Widgets::select_row(std::string_view window, std::int32_t row) {
    Grid* grid = grid_of(window);
    if (grid == nullptr || cell_at(*grid, row, 0) == nullptr) return false;
    grid->selected = static_cast<std::size_t>(row);
    return true;
}

std::int32_t Widgets::selected_row(std::string_view window) const noexcept {
    const Grid* grid = grid_of(window);
    if (grid == nullptr || !grid->selected) return kNoRow;
    const GridCell* cell = cell_at(*grid, static_cast<std::int32_t>(*grid->selected), 0);
    return cell == nullptr ? kNoRow : cell->id;
}

bool Widgets::scroll_rows(std::string_view window, std::int32_t row) {
    Entry& entry = entry_of(window);
    if (!entry.grid) entry.grid.emplace();
    if (row < 0 || std::cmp_greater(row, entry.grid->rows.size())) return false;
    entry.grid->scroll = row;
    return true;
}

std::size_t Widgets::row_count(std::string_view window) const noexcept {
    const Grid* grid = grid_of(window);
    return grid == nullptr ? 0 : grid->rows.size();
}

std::size_t Widgets::column_count(std::string_view window) const noexcept {
    const Grid* grid = grid_of(window);
    return grid == nullptr ? 0 : grid->columns.size();
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

std::optional<float> Widgets::progress(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    if (entry == nullptr || !entry->progress) return std::nullopt;
    return progress_of(*entry->progress);
}

std::int32_t Widgets::action_item(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    if (entry == nullptr || !entry->action) return kEmptyAction;
    return entry->action->id;
}

void Widgets::seed_hidden(std::string_view window) {
    entry_of(window).is_layout_hidden = true;
}

bool Widgets::is_shown(std::string_view window) const noexcept {
    const Entry* entry = find(window);
    return entry == nullptr || entry->is_visible.value_or(!entry->is_layout_hidden);
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
    // Ô action (FalagardActionButton::drawSelf) chỉ vẽ icon khi thuộc tính Empty là False: SetActionItem(-1) đặt True,
    // SetActionItem(id) có action đặt False rồi NormalImage (UI_CEGUI 0x180028d70, docs/GIAO-DIEN-2026.md 2.7).
    if (entry.action) {
        deck.set(gui::Override{.window = window, .name = "Empty", .value = entry.action->id == kEmptyAction ? "True" : "False"});
    }
    const bool has_icon = entry.action && !entry.action->icon.empty();
    if (has_icon) deck.set(gui::Override{.window = window, .name = "NormalImage", .value = entry.action->icon});
    if (entry.progress) deck.bar(window, progress_of(*entry.progress));
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
    if (entry.progress) {
        const std::string ratio = std::format("{}/{}", lua_tostring(entry.progress->first), lua_tostring(entry.progress->second));
        add_line(lines, Key{.window = window, .name = "Progress"}, ratio);
    }
    if (entry.is_flashing) add_line(lines, Key{.window = window, .name = "NewFlash"}, truth(true));
    describe_flag(lines, Key{.window = window, .name = "Playing"}, entry.is_playing);
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
