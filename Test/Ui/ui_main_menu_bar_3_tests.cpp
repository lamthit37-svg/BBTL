// Thanh kỹ năng thú cưng (ui/panel/main_menu_bar_3): bản port để lại đúng trạng thái cửa sổ mà
// MainMenuBar_3.lua của client 2026 để lại khi chạy trên LuaPlus.dll gốc (Test/golden/panel/
// main_menu_bar_3_pet.tsv, sinh bằng TOOLS/port/lua_oracle.py với kịch bản
// TOOLS/port/oracle/main_menu_bar_3_pet.lua), cùng quy tắc IsCanDoAction và bộ gửi sự kiện mà kịch bản
// không đi tới.
#include "ui/panel/main_menu_bar_3.hpp"

#include "core/check.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/can_do.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::panel::ActionFace;
using ui::panel::Call;
using ui::panel::MainMenuBar3;

constexpr std::string_view kGoldenFile = "main_menu_bar_3_pet.tsv";

// Mọi thứ một bước của kịch bản trọng tài đụng tới: thanh, kho đối số, việc đã nhờ, thanh kỹ năng thú cưng
// và cửa sổ giao dịch đang hiện.
struct Rig {
    MainMenuBar3 bar;
    ui::panel::EventArgs args;
    std::vector<Call> calls;
    std::vector<ActionFace> pet_bar;
    bool is_bank_shown = false;

    void raise(std::string_view name, std::span<const std::string_view> given = {}) {
        const ui::panel::UiEvent event = args.raise(name, given);
        ui::panel::on_main_menu_bar_3_event(bar, event, pet_bar);
    }
    void set_pet_bar(std::initializer_list<std::int32_t> ids) {
        pet_bar.clear();
        for (const std::int32_t id : ids)
            pet_bar.push_back(ActionFace{.id = id, .icon = {}});
    }
    [[nodiscard]] bool can_do() const {
        return ui::panel::can_do_action([this](std::string_view window) { return is_bank_shown && window == "Bank"; });
    }
    void press(std::int32_t index) { ui::panel::press_pet_skill_button(bar, index, can_do(), calls); }
    [[nodiscard]] std::vector<std::string> lines() { return panel_lines(bar.is_shown, bar.widgets, calls); }
};

using Step = void (*)(Rig&);

void step_empty(Rig& rig) {
    rig.raise("CHANGE_PETSKILL_BAR");
}

void step_one(Rig& rig) {
    rig.set_pet_bar({301});
    rig.raise("CHANGE_PETSKILL_BAR");
}

void step_two(Rig& rig) {
    rig.set_pet_bar({301, 305});
    rig.raise("CHANGE_PETSKILL_BAR");
}

void step_empty_first(Rig& rig) {
    rig.set_pet_bar({0, 305, 309});
    rig.raise("CHANGE_PETSKILL_BAR");
}

void step_all_empty(Rig& rig) {
    rig.set_pet_bar({0, 0});
    rig.raise("CHANGE_PETSKILL_BAR");
}

void step_three(Rig& rig) {
    rig.set_pet_bar({311, 312, 313});
    rig.raise("CHANGE_PETSKILL_BAR");
}

void step_adjust(Rig& rig) {
    constexpr std::array<std::string_view, 2> kSize = {"1280", "720"};
    rig.raise("CHAT_ADJUST_MOVE_CTL", kSize);
}

void step_press_both(Rig& rig) {
    rig.press(1);
    rig.press(2);
}

void step_press_blocked(Rig& rig) {
    rig.is_bank_shown = true;
    rig.press(1);
    rig.is_bank_shown = false;
}

void step_hide_toggle(Rig& rig) {
    rig.raise("HIDE_THIS_UI");
}

// Đúng thứ tự các bước của TOOLS/port/oracle/main_menu_bar_3_pet.lua.
constexpr std::array<Step, 11> kScript = {step_empty, step_one, step_two, step_empty_first, step_all_empty,
    step_three, step_adjust, step_press_both, step_press_blocked, step_hide_toggle, step_hide_toggle};

void port_matches_original_script(Context& context) {
    if (kPanelGolden.empty()) return;
    const std::vector<GoldenBlock> blocks = read_golden(kGoldenFile);
    context.expect(blocks.size() == kScript.size(), "số vàng có đủ các bước của kịch bản");
    if (blocks.size() != kScript.size()) return;
    Rig rig;
    for (std::size_t index = 0; index < kScript.size(); ++index) {
        kScript.at(index)(rig);
        expect_block(context, blocks.at(index), rig.lines());
    }
}

void blocking_windows_stop_actions(Context& context) {
    const auto none = [](std::string_view) { return false; };
    context.expect(ui::panel::can_do_action(none), "không cửa sổ giao dịch nào hiện thì làm được");
    for (const std::string_view blocker : ui::panel::kActionBlockers) {
        const auto only = [blocker](std::string_view window) { return window == blocker; };
        context.expect(!ui::panel::can_do_action(only), "một cửa sổ giao dịch hiện là không làm được");
    }
    const auto other = [](std::string_view window) { return window == "Packet"; };
    context.expect(ui::panel::can_do_action(other), "cửa sổ ngoài tám cửa sổ chặn không ngăn hành động");
}

void event_args_stay_until_overwritten(Context& context) {
    ui::panel::EventArgs args;
    constexpr std::array<std::string_view, 3> kFirstArgs = {"a", "b", "c"};
    constexpr std::array<std::string_view, 1> kSecondArgs = {"z"};
    static_cast<void>(args.raise("FIRST", kFirstArgs));
    const ui::panel::UiEvent second = args.raise("SECOND", kSecondArgs);
    context.expect(second.arg(0) == "z", "đối số mới ghi đè arg0");
    context.expect(second.arg(1) == "b", "đối số không được gửi giữ giá trị của sự kiện trước");
    context.expect(second.table(3) == "c", "eventTable[3] là arg2");
    context.expect(!second.arg(3).has_value(), "arg3 chưa sự kiện nào đặt là nil");
    context.expect(!second.table(0).has_value(), "eventTable bắt đầu từ 1");
}

void unregistered_events_are_dropped(Context& context) {
    constexpr std::array<ui::panel::EventSub, 2> kSubs = {{{.name = "ALWAYS", .is_always = true},
        {.name = "VISIBLE_ONLY", .is_always = false}}};
    context.expect(ui::panel::is_delivered(kSubs, "ALWAYS", false), "cờ true nhận cả lúc ẩn");
    context.expect(!ui::panel::is_delivered(kSubs, "VISIBLE_ONLY", false), "cờ false bỏ sự kiện lúc ẩn");
    context.expect(ui::panel::is_delivered(kSubs, "VISIBLE_ONLY", true), "cờ false nhận khi cửa sổ hiện");
    context.expect(!ui::panel::is_delivered(kSubs, "OTHER", true), "sự kiện chưa đăng ký không tới");
    context.expect(ui::panel::is_delivered(ui::panel::kMainMenuBar3Events, "HIDE_THIS_UI", false),
        "HIDE_THIS_UI của thanh thú cưng nhận cả lúc ẩn");
}

void stray_button_index_does_nothing(Context& context) {
    Rig rig;
    rig.set_pet_bar({301});
    rig.raise("CHANGE_PETSKILL_BAR");
    const std::size_t before = rig.calls.size();
    rig.press(0);
    rig.press(3);
    rig.press(-1);
    context.expect(rig.calls.size() == before, "chỉ số nút ngoài 1..2 không ứng nút nào");
    rig.press(2);
    context.expect(rig.calls.size() == before, "nút chưa mang action thì không dùng gì");
}

void paint_only_when_shown(Context& context) {
    Rig rig;
    ui::panel::Deck deck;
    ui::panel::paint_main_menu_bar_3(deck, rig.bar);
    context.expect(!deck.is_shown(ui::panel::kMainMenuBar3Root), "thanh ẩn thì không hiện cửa sổ gốc");
    rig.set_pet_bar({301});
    rig.raise("CHANGE_PETSKILL_BAR");
    ui::panel::paint_main_menu_bar_3(deck, rig.bar);
    context.expect(deck.is_shown(ui::panel::kMainMenuBar3Root), "thanh hiện thì hiện cửa sổ gốc");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "blocking_windows_stop_actions", .body = &blocking_windows_stop_actions},
    Case{.name = "event_args_stay_until_overwritten", .body = &event_args_stay_until_overwritten},
    Case{.name = "unregistered_events_are_dropped", .body = &unregistered_events_are_dropped},
    Case{.name = "stray_button_index_does_nothing", .body = &stray_button_index_does_nothing},
    Case{.name = "paint_only_when_shown", .body = &paint_only_when_shown},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_main_menu_bar_3_tests: mọi ca phải qua");
    return 0;
}
