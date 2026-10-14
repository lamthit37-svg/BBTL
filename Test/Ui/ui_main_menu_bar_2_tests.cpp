// Thanh action MainMenuBar_2 (ui/panel/main_menu_bar_2 trên lõi action_bar): bản port để lại đúng trạng thái cửa sổ và đúng
// việc nhờ game mà MainMenuBar_2.lua của client 2026 để lại khi chạy trên LuaPlus.dll gốc
// (Test/golden/panel/main_menu_bar_2_bar.tsv, sinh bằng TOOLS/port/lua_oracle.py với kịch bản
// TOOLS/port/oracle/main_menu_bar_2_bar.lua), cùng các ca mà kịch bản không đi tới: bảng đăng ký sự kiện (ba sự kiện cờ
// false), nối chuỗi gỡ gói với thanh kế, tên ô và cửa sổ hoạt ảnh, dữ liệu thù địch của nhánh hướng dẫn tân thủ.
#include "ui/panel/main_menu_bar_2.hpp"

#include "core/check.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/can_do.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/function_bar_right.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::panel::Call;
using ui::panel::ChatPack;

constexpr std::string_view kGoldenFile = "main_menu_bar_2_bar.tsv";

// Mọi thứ một bước của kịch bản trọng tài đụng tới: thanh, kho đối số, điều game trả cho script (BarFacts), việc đã nhờ
// và cửa sổ cửa hàng đang hiện.
struct Rig {
    ui::panel::ActionBar bar = ui::panel::make_main_menu_bar_2();
    ui::panel::EventArgs args;
    ui::panel::BarFacts facts;
    std::vector<Call> calls;
    bool is_shop_shown = false;

    Rig() {
        // Gói cài, danh sách mood và hình học của kịch bản: TOOLS/port/oracle/main_menu_bar_2_bar.lua.
        facts.chat.moods = {900, 901, 902, 903, 904, 905, 0, 907};
        facts.chat.double_moods = {1100, 1101, 1102, 1103, 1104};
        facts.chat.packs.at(2) = ChatPack{.real_id = 7, .count = 3, .min_index = 5, .kind = 1};
        facts.chat.packs.at(4) = ChatPack{.real_id = 9, .count = 2, .min_index = 2, .kind = ui::panel::kDoubleChatPack};
        facts.chat.packs.at(6) = ChatPack{.real_id = 0, .count = 3, .min_index = 5, .kind = 1};
        facts.chat.packs.at(8) = ChatPack{.real_id = 13, .count = 0, .min_index = 5, .kind = 1};
        facts.guide.frame = {.x = 150.5, .y = 600.25, .width = 0.0, .height = 0.0};
        facts.guide.buttons.at(0) = {.x = 6.0, .y = 18.0, .width = 32.0, .height = 32.0};
        facts.guide.buttons.at(2) = {.x = 70.0, .y = 4.5, .width = 32.0, .height = 30.5};
        facts.guide.buttons.at(9) = {.x = 316.0, .y = 4.0, .width = 31.5, .height = 32.0};
    }

    void raise(std::string_view name, std::initializer_list<std::string_view> given = {}) {
        const ui::panel::UiEvent event =
            args.raise(name, std::span<const std::string_view>(given.begin(), given.size()));
        ui::panel::on_main_menu_bar_2_event(bar, event, facts, calls);
    }
    [[nodiscard]] bool can_do() const {
        return ui::panel::can_do_action([this](std::string_view window) { return is_shop_shown && window == "Shop"; });
    }
    void press(std::int32_t id) { ui::panel::press_main_menu_bar_2(bar, id, can_do(), facts, calls); }
    [[nodiscard]] std::vector<std::string> lines() { return panel_lines(bar.is_shown, bar.widgets, calls); }
};

// Đúng thứ tự các bước của TOOLS/port/oracle/main_menu_bar_2_bar.lua.
constexpr std::array kScript = {
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"31", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "31", "301"}); },
    +[](Rig& rig) { rig.raise("OPEN_MENUBAR_2", {"1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "31", "301"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"32", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"32", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"32", "1"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"32", "0"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"41", "1"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"30", "1"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"40", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "33", "305", "0"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "32", "302"}); },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = true;
        rig.raise("CHANGE_BAR", {"main", "34", "306", "1"});
    },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = false;
        rig.raise("CHANGE_BAR", {"main", "35", "307", "1"});
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "36", "308", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "40", "309", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "30", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "41", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"other", "31", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "40.5", "2"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "30.5", "2"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "31.5", "2"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "chu", "2"}); },
    +[](Rig& rig) {
        rig.raise("FLASH_COMBOSKILL", {"31", "1"});
        rig.raise("FLASH_COMBOSKILL", {"35", "2"});
        rig.raise("ACTION_UPDATE");
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "3", "31", "35", "99"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "1", "40"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "6", "32"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR2", {"11"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR2", {"chu"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "32", "905"});
        rig.raise("CHANGE_BAR", {"main", "33", "903"});
        rig.raise("CHANGE_BAR", {"main", "34", "906"});
        rig.raise("CHANGE_BAR", {"main", "35", "0"});
        rig.raise("CHANGE_BAR", {"main", "36", "1102"});
        rig.raise("CHANGE_BAR", {"main", "37", "1101"});
        rig.raise("UNINSTALL_CHAT_ACTION_BAR2", {"2"});
    },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR2", {"4"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR2", {"6"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR2", {"8"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR2", {"3"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "38", "904"});
        rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_4", "2", "5", "6"});
    },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight", "2", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_2", "2", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_2", "-1", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_2", "7", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_2", "7", "chu", "6"}); },
    +[](Rig& rig) { rig.raise("CHAT_ADJUST_MOVE_CTL", {"1920", "1080"}); },
    +[](Rig& rig) { rig.raise("UI_COMMAND", {"20130527"}); },
    +[](Rig& rig) {
        rig.facts.guide.put_is_show = 1;
        rig.facts.guide.put_index = 33;
        rig.raise("UI_COMMAND", {"1"});
    },
    +[](Rig& rig) { rig.raise("UI_COMMAND", {"20130527"}); },
    +[](Rig& rig) {
        rig.facts.guide.put_index = 30;
        rig.raise("UI_COMMAND", {"20130527"});
    },
    +[](Rig& rig) {
        rig.facts.guide.put_index = 41;
        rig.raise("UI_COMMAND", {"20130527"});
    },
    +[](Rig& rig) {
        rig.facts.guide.put_is_show = 2;
        rig.facts.guide.put_index = 31;
        rig.raise("UI_COMMAND", {"20130527"});
    },
    +[](Rig& rig) {
        rig.facts.guide.put_is_show = 1;
        rig.raise("UI_COMMAND", {"20130527"});
    },
    +[](Rig& rig) {
        rig.facts.guide.put_index = 40;
        rig.raise("UI_COMMAND", {"20130527"});
    },
    +[](Rig& rig) {
        rig.facts.guide.owner = "Other";
        rig.press(33);
    },
    +[](Rig& rig) { rig.press(33); },
    +[](Rig& rig) {
        rig.raise("UI_COMMAND", {"20130527"});
        rig.is_shop_shown = true;
        rig.press(33);
    },
    +[](Rig& rig) {
        rig.is_shop_shown = false;
        rig.facts.guide.owner = "MainMenuBar_2";
        rig.press(33);
    },
    +[](Rig& rig) { rig.press(33); },
    +[](Rig& rig) { rig.press(39); },
    +[](Rig& rig) { rig.raise("OPEN_MENUBAR_2", {"0"}); },
    +[](Rig& rig) {
        rig.facts.is_in_tlcj_scene = true;
        rig.raise("OPEN_MENUBAR_2", {"1"});
    },
    +[](Rig& rig) {
        rig.facts.is_in_tlcj_scene = false;
        rig.raise("OPEN_MENUBAR_2", {"2"});
    },
    +[](Rig& rig) { rig.raise("OPEN_MENUBAR_2", {"1"}); },
    +[](Rig& rig) { rig.raise("HIDE_THIS_UI"); },
    +[](Rig& rig) { rig.raise("HIDE_THIS_UI"); },
};

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

void bar_starts_hidden(Context& context) {
    const Rig rig;
    context.expect(!rig.bar.is_shown, "layout nạp ở trạng thái ẩn, thanh chờ OPEN_MENUBAR_2");
    context.expect(!rig.bar.is_drawing, "chưa có lớp hướng dẫn");
}

// Ba sự kiện đăng ký cờ false (CHAT_ADJUST_MOVE_CTL, ACTION_UPDATE, UI_COMMAND): thanh ẩn thì không nhận; sáu sự kiện còn
// lại nhận cả lúc ẩn.
void three_events_need_a_shown_bar(Context& context) {
    constexpr std::array<std::string_view, 3> kShownOnly = {"CHAT_ADJUST_MOVE_CTL", "ACTION_UPDATE", "UI_COMMAND"};
    for (const ui::panel::EventSub& sub : ui::panel::kMainMenuBar2Events) {
        const bool is_shown_only = std::ranges::find(kShownOnly, sub.name) != kShownOnly.end();
        context.expect(ui::panel::is_delivered(ui::panel::kMainMenuBar2Events, sub.name, false) == !is_shown_only,
            "thanh ẩn chỉ không nhận ba sự kiện cờ false");
        context.expect(ui::panel::is_delivered(ui::panel::kMainMenuBar2Events, sub.name, true),
            "thanh hiện nhận mọi sự kiện đã đăng ký");
    }
    context.expect(!ui::panel::is_delivered(ui::panel::kMainMenuBar2Events, "OPEN_RIGHT_BAR_2", true),
        "sự kiện của thanh khác không tới");
    context.expect(ui::panel::is_delivered(
                       ui::panel::kMainMenuBar2Events, ui::panel::kMainMenuBar2Spec.uninstall_event, false),
        "sự kiện gỡ gói của thanh nằm trong bảng đăng ký");
}

// Chuỗi gỡ gói: thanh này nhận sự kiện của cấp mà MainMenuBar đẩy (cấp 2) và đẩy cấp 3, tức sự kiện mà FunctionBarRight
// nghe; dọn gói quá hạn thì chuyển cho đúng FunctionBarRight.
void uninstall_chain_links_to_function_bar_right(Context& context) {
    using ui::panel::uninstall_chat_action_event;
    context.expect(ui::panel::kMainMenuBar2Spec.uninstall_event == uninstall_chat_action_event(2),
        "nhận sự kiện của cấp 2 do MainMenuBar gửi");
    context.expect(uninstall_chat_action_event(ui::panel::kMainMenuBar2Spec.uninstall_level) ==
            ui::panel::kFunctionBarRightSpec.uninstall_event,
        "đẩy cấp 3 là sự kiện của FunctionBarRight");
    context.expect(ui::panel::kMainMenuBar2Spec.forward == ui::panel::kFunctionBarRightSpec.name,
        "dọn gói chuyển tiếp cho FunctionBarRight");
}

void button_names_map_to_ids(Context& context) {
    const Rig rig;
    context.expect(ui::panel::bar_button_id(rig.bar, "MainMenuBar_2_Button_Action1") == 31, "ô đầu là 31");
    context.expect(ui::panel::bar_button_id(rig.bar, "MainMenuBar_2_Button_Action10") == 40, "ô cuối là 40");
    context.expect(!ui::panel::bar_button_id(rig.bar, "MainMenuBar_2_Button_Action11").has_value(), "thanh chỉ có mười ô");
    context.expect(rig.bar.root == "MainMenuBar_2_Frame", "cửa sổ gốc");
    context.expect(rig.bar.juniors.back() == "MainMenuBar_2_Button10_junior_Flash", "cửa sổ nháy cấp thấp");
    context.expect(rig.bar.seniors.front() == "MainMenuBar_2_Button1_senior_Flash", "cửa sổ nháy cấp cao");
    context.expect(rig.bar.masks.size() == 10 && rig.bar.masks.front() == "MainMenuBar_2_Button_Action1_Mask" &&
            rig.bar.masks.back() == "MainMenuBar_2_Button_Action10_Mask",
        "mười cửa sổ hoạt ảnh");
}

// Chỉ số ô mà kho đồ trả có thể là gì cũng được: ngoài 31..40 thì không mở lớp hướng dẫn, không đọc ngoài mảng hình học.
void hostile_put_index_opens_nothing(Context& context) {
    constexpr std::array<std::int32_t, 6> kIndexes = {std::numeric_limits<std::int32_t>::min(), -1, 0, 30, 41,
        std::numeric_limits<std::int32_t>::max()};
    for (const std::int32_t index : kIndexes) {
        Rig rig;
        rig.raise("OPEN_MENUBAR_2", {"1"});
        rig.calls.clear();
        rig.facts.guide.put_is_show = 1;
        rig.facts.guide.put_index = index;
        rig.raise("UI_COMMAND", {"20130527"});
        context.expect(rig.calls.empty() && !rig.bar.is_drawing, "chỉ số ngoài 31..40 không mở lớp hướng dẫn");
    }
}

// Bấm ô ngoài dải không đóng lớp hướng dẫn (script dừng ở DoAction trên ô không có).
void press_outside_the_bar_keeps_the_guide(Context& context) {
    Rig rig;
    rig.raise("OPEN_MENUBAR_2", {"1"});
    rig.facts.guide.put_is_show = 1;
    rig.facts.guide.put_index = 33;
    rig.raise("UI_COMMAND", {"20130527"});
    rig.facts.guide.owner = "MainMenuBar_2";
    rig.calls.clear();
    rig.press(41);
    rig.press(30);
    context.expect(rig.calls.empty() && rig.bar.is_drawing, "ô ngoài dải không đụng lớp hướng dẫn");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "bar_starts_hidden", .body = &bar_starts_hidden},
    Case{.name = "three_events_need_a_shown_bar", .body = &three_events_need_a_shown_bar},
    Case{.name = "uninstall_chain_links_to_function_bar_right", .body = &uninstall_chain_links_to_function_bar_right},
    Case{.name = "button_names_map_to_ids", .body = &button_names_map_to_ids},
    Case{.name = "hostile_put_index_opens_nothing", .body = &hostile_put_index_opens_nothing},
    Case{.name = "press_outside_the_bar_keeps_the_guide", .body = &press_outside_the_bar_keeps_the_guide},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_main_menu_bar_2_tests: mọi ca phải qua");
    return 0;
}
