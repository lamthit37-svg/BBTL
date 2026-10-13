// Bảng chọn nhân vật: lần nhấn đầu chỉ chọn, lần sau hoặc nút vào game mới vào, xoá hỏi hai lần.
#include "ui/panel/select_role.hpp"

#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "test.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/roles.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using ui::panel::Deck;
using ui::panel::Role;
using ui::panel::Roster;
using ui::panel::SelectAction;
using ui::panel::SelectRole;

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

Role named(std::string name) {
    Role role;
    role.name = std::move(name);
    role.level = 4;
    role.sect = 9;
    role.icon = "set:Face image:Girl_1";
    return role;
}

Roster two_roles() {
    Roster roster;
    roster.count = 2;
    roster.roles[0] = named("Mot");
    roster.roles[1] = named("Hai");
    return roster;
}

SelectRole opened(std::uint8_t selected) {
    SelectRole select;
    ui::panel::open_select(select, two_roles(), selected);
    return select;
}

void open_does_not_count_as_a_click(Context& context) {
    SelectRole select = opened(0);
    context.expect(select.count == 2 && select.selected == 0 && !select.was_clicked, "ô đầu được chọn sẵn");
    ui::panel::press_select(select, "SelectRole_TargetInfo_Button1");
    context.expect(!ui::panel::take_select(select), "lần nhấn đầu chưa vào game");
    context.expect(select.was_clicked && select.selected == 0, "đã ghi lần nhấn");
    ui::panel::press_select(select, "SelectRole_TargetInfo_Button1");
    context.expect(ui::panel::take_select(select) == SelectAction::kEnter, "lần nhấn sau vào game");
}

void play_enters_and_empty_explains(Context& context) {
    SelectRole select = opened(1);
    ui::panel::press_select(select, "SelectRole_Play");
    context.expect(ui::panel::take_select(select) == SelectAction::kEnter, "nút vào game");
    context.expect(ui::panel::chosen_role(select) != nullptr, "còn người đã chọn");
    SelectRole empty;
    ui::panel::open_select(empty, {}, 0);
    ui::panel::press_select(empty, "SelectRole_Play");
    context.expect(!ui::panel::take_select(empty), "chưa có ai thì không vào");
    context.expect(empty.info == "#{produce_char_sel_Info_Please_Sel_Role}", "nói vì sao");
}

void empty_slot_asks_to_create(Context& context) {
    SelectRole select = opened(0);
    ui::panel::press_select(select, "SelectRole_TargetInfo_Button3");
    context.expect(ui::panel::take_select(select) == SelectAction::kCreate, "ô trống mở tạo");
    ui::panel::press_select(select, "SelectRole_Create");
    context.expect(ui::panel::take_select(select) == SelectAction::kCreate, "nút tạo");
}

void full_list_refuses_create(Context& context) {
    Roster roster = two_roles();
    roster.count = 3;
    roster.roles[2] = named("Ba");
    SelectRole select;
    ui::panel::open_select(select, roster, 0);
    ui::panel::press_select(select, "SelectRole_Create");
    context.expect(!ui::panel::take_select(select), "đủ ba thì không tạo");
    context.expect(select.info == "#{ROLE_LIST_FULL}", "nói đã đủ");
}

void delete_asks_twice_and_other_keys_cancel(Context& context) {
    SelectRole select = opened(0);
    ui::panel::press_select(select, "SelectRole_Delete");
    context.expect(select.confirming && !ui::panel::take_select(select), "lần xoá đầu chỉ hỏi");
    context.expect(select.info.contains("Mot"), "hỏi đúng tên");
    ui::panel::press_select(select, "SelectRole_Play");
    context.expect(!select.confirming && !ui::panel::take_select(select), "nút khác chỉ huỷ câu hỏi");
    ui::panel::press_select(select, "SelectRole_Delete");
    ui::panel::press_select(select, "SelectRole_Delete");
    context.expect(ui::panel::take_select(select) == SelectAction::kDelete, "lần xoá thứ hai mới xoá");
}

void back_is_its_own_action(Context& context) {
    SelectRole select = opened(9);
    context.expect(select.selected == 1, "ô chọn nằm ngoài thì kẹp về ô cuối");
    ui::panel::press_select(select, "SelectRole_Last");
    context.expect(ui::panel::take_select(select) == SelectAction::kBack, "quay lại");
}

bool has_window(const gui::GuiAsset& asset, std::string_view name) {
    const auto is_named = [name](const gui::GuiWindow& window) { return window.name == name; };
    return std::ranges::any_of(asset.windows, is_named);
}

void names_exist_in_layout(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    gui::GuiSources sources;
    const gui::DiskSource files(root);
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện");
    if (!loader) return;
    context.expect(loader->add_layout(ui::panel::kSelectLayout).has_value(), "nạp được layout chọn");
    SelectRole select = opened(0);
    Deck deck;
    ui::panel::paint_select(deck, select);
    for (const gui::Override& item : deck.overrides()) {
        context.expect(has_window(loader->asset(), item.window), item.window);
    }
    context.expect(has_window(loader->asset(), "SelectRole_Play"), "nút vào game");
    context.expect(has_window(loader->asset(), "SelectRole_Last"), "nút quay lại");
}

constexpr std::array<Case, 7> kCases{{
    {.name = "open_does_not_count_as_a_click", .body = &open_does_not_count_as_a_click},
    {.name = "play_enters_and_empty_explains", .body = &play_enters_and_empty_explains},
    {.name = "empty_slot_asks_to_create", .body = &empty_slot_asks_to_create},
    {.name = "full_list_refuses_create", .body = &full_list_refuses_create},
    {.name = "delete_asks_twice_and_other_keys_cancel", .body = &delete_asks_twice_and_other_keys_cancel},
    {.name = "back_is_its_own_action", .body = &back_is_its_own_action},
    {.name = "names_exist_in_layout", .body = &names_exist_in_layout},
}};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_select_tests: mọi ca phải qua");
    return 0;
}
