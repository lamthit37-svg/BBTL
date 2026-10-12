// Trạng thái giữ lại của các cửa sổ một bảng (ui/panel/widgets): mỗi phương thức giữ đúng điều
// lời gọi Lua tương ứng để lại, describe ghi đúng dạng dòng của TOOLS/port/lua_oracle.py, và paint
// chép sang Deck đúng thứ đã đặt.
#include "ui/panel/widgets.hpp"

#include "gui/sheet.hpp"
#include "test.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::panel::Deck;
using ui::panel::Key;
using ui::panel::ListItem;
using ui::panel::Widgets;

constexpr std::string_view kList = "QuestLog_Listbox";
constexpr std::string_view kDesc = "QuestLog_Desc";

std::vector<std::string> lines_of(const Widgets& widgets) {
    std::vector<std::string> lines;
    widgets.describe(lines);
    return lines;
}

bool has_line(std::span<const std::string> lines, std::string_view wanted) {
    return std::ranges::contains(lines, wanted);
}

// Giá trị cuối của một thuộc tính trong deck; rỗng khi deck không có dòng nào.
std::string_view deck_value(Deck& deck, const Key& key) {
    std::string_view found;
    for (const gui::Override& item : deck.overrides()) {
        if (item.window == key.window && item.name == key.name) found = item.value;
    }
    return found;
}

ListItem item_of(std::string_view text, std::int32_t id, std::string_view colour) {
    ListItem item;
    item.text = text;
    item.id = id;
    item.colour = colour;
    return item;
}

void untouched_store_is_empty(Context& context) {
    const Widgets widgets;
    context.expect(lines_of(widgets).empty(), "chưa đặt gì thì không có dòng nào");
    context.expect(!widgets.is_checked("A"), "nút chưa đặt thì chưa đánh dấu");
    context.expect(widgets.selected_item(kList) == ui::panel::kNoItem, "danh sách chưa có thì không có mục chọn");
    context.expect(widgets.clicked_item(kList) == ui::panel::kNoItem, "chưa bấm mục nào");
    context.expect(widgets.first_item(kList) == 0, "chưa cuộn thì mục đầu là 0");
    context.expect(!widgets.value(Key{.window = "A", .name = "Text"}), "thuộc tính chưa đặt");
    context.expect(!widgets.action("A"), "ô action chưa đặt");
}

void property_keeps_last_value(Context& context) {
    Widgets widgets;
    widgets.set_text("A", "một");
    widgets.set_text("A", "hai\ndòng");
    widgets.set(gui::Override{.window = "A", .name = "Tooltip", .value = "#{KEY}"});
    const auto text = widgets.value(Key{.window = "A", .name = "Text"});
    context.expect(text == std::string_view("hai\ndòng"), "đặt lại thì giữ giá trị sau");
    const std::vector<std::string> lines = lines_of(widgets);
    context.expect(lines.size() == 2, "hai thuộc tính, mỗi cái một dòng");
    context.expect(has_line(lines, "A\tText\thai\\ndòng"), "xuống dòng viết thành hai ký tự");
    context.expect(has_line(lines, "A\tTooltip\t#{KEY}"), "thuộc tính khác giữ nguyên văn");
}

void flags_record_both_states(Context& context) {
    Widgets widgets;
    widgets.show("A");
    widgets.hide("B");
    widgets.disable("A");
    widgets.enable("A");
    widgets.check("C", true);
    widgets.check("D", false);
    widgets.push("E", true);
    widgets.set_action("E", ui::panel::ActionFace{});
    const std::vector<std::string> lines = lines_of(widgets);
    context.expect(has_line(lines, "A\tVisible\tTrue") && has_line(lines, "B\tVisible\tFalse"), "hiện và giấu");
    context.expect(has_line(lines, "A\tDisabled\tFalse"), "mở khoá cũng là đã đụng tới");
    context.expect(has_line(lines, "C\tSelected\tTrue") && has_line(lines, "D\tSelected\tFalse"), "dấu chọn");
    context.expect(has_line(lines, "E\tPushed\tTrue") && has_line(lines, "E\tActionItem\t-1"), "nút action");
    context.expect(widgets.is_checked("C") && !widgets.is_checked("D"), "GetCheck");
    context.expect(widgets.action("E") == -1, "ô action trống là -1");
}

void disabled_state_is_readable(Context& context) {
    Widgets widgets;
    context.expect(!widgets.is_disabled("A"), "cửa sổ chưa đụng tới không khoá");
    widgets.disable("A");
    context.expect(widgets.is_disabled("A"), "Disable rồi thì khoá");
    widgets.enable("A");
    context.expect(!widgets.is_disabled("A"), "Enable mở khoá");
    widgets.show("B");
    context.expect(!widgets.is_disabled("B"), "cửa sổ đã đụng mà chưa khoá lần nào thì không khoá");
}

void list_selects_by_id(Context& context) {
    Widgets widgets;
    widgets.clear_list(kList);
    widgets.add_item(kList, item_of("#gFE7E82- Loại", 101, ""));
    widgets.add_item(kList, item_of("     1 Việc", 0, "FFD9F80A"));
    widgets.select_item(kList, 0);
    context.expect(widgets.selected_item(kList) == 0, "chọn theo id");
    widgets.select_item(kList, 77);
    context.expect(widgets.selected_item(kList) == 0, "id không có thì giữ mục đang chọn");
    const std::vector<std::string> lines = lines_of(widgets);
    context.expect(has_line(lines, "QuestLog_Listbox\tItems\t2"), "số mục");
    context.expect(has_line(lines, "QuestLog_Listbox\tItem1\t101\t\t#gFE7E82- Loại"), "mục không màu");
    context.expect(has_line(lines, "QuestLog_Listbox\tItem2\t0\tFFD9F80A\t     1 Việc"), "mục có màu");
    context.expect(has_line(lines, "QuestLog_Listbox\tSelectedItem\t0"), "id của mục đang chọn");
}

void list_pick_and_clear(Context& context) {
    Widgets widgets;
    widgets.add_item(kList, item_of("a", 5, ""));
    widgets.add_item(kList, item_of("b", 6, ""));
    widgets.pick_item(kList, 6);
    context.expect(widgets.selected_item(kList) == 6 && widgets.clicked_item(kList) == 6, "bấm một mục");
    widgets.pick_item(kList, 9);
    context.expect(widgets.selected_item(kList) == ui::panel::kNoItem, "bấm id không có thì bỏ chọn");
    context.expect(widgets.clicked_item(kList) == 9, "mục vừa bấm vẫn là id đó");
    widgets.set_first_item(kList, 4);
    widgets.pick_item(kList, 5);
    widgets.clear_list(kList);
    context.expect(widgets.selected_item(kList) == ui::panel::kNoItem, "xoá danh sách thì bỏ chọn");
    context.expect(widgets.first_item(kList) == 0, "xoá danh sách thì về đầu");
    const std::vector<std::string> lines = lines_of(widgets);
    context.expect(has_line(lines, "QuestLog_Listbox\tItems\t0"), "danh sách rỗng vẫn là đã đụng tới");
    context.expect(has_line(lines, "QuestLog_Listbox\tFirstItem\t0"), "mục đầu đã đụng tới thì ghi 0");
}

void elements_append_in_order(Context& context) {
    Widgets widgets;
    widgets.add_element(kDesc, "text\tcũ");
    widgets.clear_elements(kDesc);
    widgets.add_element(kDesc, "text\t#YMục tiêu:#W");
    widgets.add_element(kDesc, "money\t1200");
    widgets.reset_scroll(kDesc);
    std::vector<std::string> lines = lines_of(widgets);
    context.expect(has_line(lines, "QuestLog_Desc\tElements\t2"), "xoá rồi thêm hai phần tử");
    context.expect(has_line(lines, "QuestLog_Desc\tElement1\ttext\t#YMục tiêu:#W"), "phần tử chữ");
    context.expect(has_line(lines, "QuestLog_Desc\tElement2\tmoney\t1200"), "phần tử tiền");
    context.expect(has_line(lines, "QuestLog_Desc\tScroll\tReset"), "về đầu");
    widgets.keep_scroll(kDesc);
    lines = lines_of(widgets);
    context.expect(has_line(lines, "QuestLog_Desc\tScroll\tKeep"), "giữ chỗ cuộn");
}

void paint_copies_touched_state(Context& context) {
    Widgets widgets;
    widgets.set_text("A", "chữ");
    widgets.show("A");
    widgets.hide("B");
    widgets.disable("C");
    widgets.check("D", true);
    widgets.push("E", false);
    Deck deck;
    widgets.paint(deck);
    context.expect(deck_value(deck, Key{.window = "A", .name = "Text"}) == "chữ", "chữ sang deck");
    context.expect(deck_value(deck, Key{.window = "A", .name = "Visible"}) == "True", "Show thành Visible");
    const std::span<const std::string_view> hidden = deck.hidden();
    context.expect(hidden.size() == 1 && hidden.front() == "B", "Hide vào danh sách giấu");
    context.expect(deck_value(deck, Key{.window = "C", .name = "Disabled"}) == "True", "khoá");
    context.expect(deck_value(deck, Key{.window = "D", .name = "Selected"}) == "True", "dấu chọn");
    context.expect(deck_value(deck, Key{.window = "E", .name = "Pushed"}) == "False", "dấu nhấn");
    context.expect(deck_value(deck, Key{.window = "F", .name = "Text"}).empty(), "cửa sổ chưa đụng không có dòng");
}

// Nút đánh dấu CheckMode 1: bật một nút thì các nút cùng cha tắt, và nút nào trong nhóm cũng thành
// "đã đụng tới" như trạng thái trọng tài ghi.
void check_one_clears_the_group(Context& context) {
    constexpr std::array<std::string_view, 3> kGroup = {"Tab1", "Tab2", "Tab3"};
    Widgets widgets;
    widgets.check_one("Tab2", kGroup);
    context.expect(widgets.is_checked("Tab2") && !widgets.is_checked("Tab1") && !widgets.is_checked("Tab3"), "chỉ nút hai bật");
    std::vector<std::string> lines = lines_of(widgets);
    context.expect(has_line(lines, "Tab1	Selected	False") && has_line(lines, "Tab3	Selected	False"), "nút cùng nhóm ghi là tắt");
    context.expect(has_line(lines, "Tab2	Selected	True"), "nút được bật ghi là bật");
    widgets.check_one("Tab2", kGroup);
    context.expect(widgets.is_checked("Tab2"), "bấm nút đang bật thì nó vẫn bật");
    widgets.check_one("Tab3", kGroup);
    context.expect(widgets.is_checked("Tab3") && !widgets.is_checked("Tab2"), "bật nút khác thì nút cũ tắt");
    widgets.check_one("Ngoai", kGroup);
    context.expect(widgets.is_checked("Ngoai") && !widgets.is_checked("Tab3"), "nút ngoài nhóm vẫn bật và nhóm tắt hết");
    widgets.check_one("Don", {});
    context.expect(widgets.is_checked("Don"), "nhóm rỗng thì chỉ bật nút đó");
}

void hidden_state_is_readable(Context& context) {
    Widgets widgets;
    context.expect(!widgets.is_hidden("A"), "chưa đặt lần nào thì không giấu");
    widgets.hide("A");
    context.expect(widgets.is_hidden("A"), "Hide thì giấu");
    widgets.show("A");
    context.expect(!widgets.is_hidden("A"), "Show thì hết giấu");
    widgets.disable("B");
    context.expect(!widgets.is_hidden("B"), "khoá không phải giấu");
}

// Cửa sổ mờ hẳn (thuộc tính Alpha bằng "0") được giấu ở deck dù script đã Show nó.
void clear_window_is_hidden_in_the_deck(Context& context) {
    const auto is_hidden = [](const Deck& deck, std::string_view window) {
        return std::ranges::contains(deck.hidden(), window);
    };
    Widgets widgets;
    widgets.show("Frame");
    widgets.set(gui::Override{.window = "Frame", .name = "Alpha", .value = "0"});
    widgets.set(gui::Override{.window = "Other", .name = "Alpha", .value = "0"});
    Deck deck;
    widgets.paint(deck);
    context.expect(is_hidden(deck, "Frame"), "cửa sổ đang hiện mà mờ hẳn thì giấu");
    context.expect(is_hidden(deck, "Other"), "cửa sổ chưa Show lần nào mà mờ hẳn cũng giấu");
    widgets.set(gui::Override{.window = "Frame", .name = "Alpha", .value = "1"});
    deck.clear();
    widgets.paint(deck);
    context.expect(!is_hidden(deck, "Frame"), "rõ lại thì hết giấu");
    context.expect(deck_value(deck, Key{.window = "Frame", .name = "Alpha"}) == "1", "thuộc tính vẫn chép sang deck");
}

constexpr std::array<Case, 11> kCases = {{
    {.name = "untouched_store_is_empty", .body = untouched_store_is_empty},
    {.name = "property_keeps_last_value", .body = property_keeps_last_value},
    {.name = "flags_record_both_states", .body = flags_record_both_states},
    {.name = "disabled_state_is_readable", .body = disabled_state_is_readable},
    {.name = "list_selects_by_id", .body = list_selects_by_id},
    {.name = "list_pick_and_clear", .body = list_pick_and_clear},
    {.name = "elements_append_in_order", .body = elements_append_in_order},
    {.name = "paint_copies_touched_state", .body = paint_copies_touched_state},
    {.name = "check_one_clears_the_group", .body = check_one_clears_the_group},
    {.name = "hidden_state_is_readable", .body = hidden_state_is_readable},
    {.name = "clear_window_is_hidden_in_the_deck", .body = clear_window_is_hidden_in_the_deck},
}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
