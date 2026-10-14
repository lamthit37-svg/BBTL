// Thanh action FunctionBarRight_2 (ui/panel/function_bar_right_2 trên lõi action_bar): bản port để lại đúng trạng thái
// cửa sổ và đúng việc nhờ game mà FunctionBarRight_2.lua của client 2026 để lại khi chạy trên LuaPlus.dll gốc
// (Test/golden/panel/function_bar_right_2_bar.tsv, sinh bằng TOOLS/port/lua_oracle.py với kịch bản
// TOOLS/port/oracle/function_bar_right_2_bar.lua), cùng các ca mà kịch bản không đi tới: bảng đăng ký sự kiện, nối chuỗi
// gỡ gói với thanh kế, tên ô.
#include "ui/panel/function_bar_right_2.hpp"

#include "core/check.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/can_do.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/main_menu_bar_4.hpp"

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

using ui::panel::Call;
using ui::panel::ChatPack;

constexpr std::string_view kGoldenFile = "function_bar_right_2_bar.tsv";

// Mọi thứ một bước của kịch bản trọng tài đụng tới: thanh, kho đối số, điều game trả cho script (BarFacts), việc đã nhờ
// và cửa sổ cửa hàng đang hiện.
struct Rig {
    ui::panel::ActionBar bar = ui::panel::make_function_bar_right_2();
    ui::panel::EventArgs args;
    ui::panel::BarFacts facts;
    std::vector<Call> calls;
    bool is_shop_shown = false;

    Rig() {
        // Gói cài và danh sách mood của kịch bản: TOOLS/port/oracle/function_bar_right_2_bar.lua.
        facts.chat.moods = {900, 901, 902, 903, 904, 905, 0, 907};
        facts.chat.double_moods = {1100, 1101, 1102, 1103, 1104};
        facts.chat.packs.at(2) = ChatPack{.real_id = 7, .count = 3, .min_index = 5, .kind = 1};
        facts.chat.packs.at(4) = ChatPack{.real_id = 9, .count = 2, .min_index = 2, .kind = ui::panel::kDoubleChatPack};
        facts.chat.packs.at(6) = ChatPack{.real_id = 0, .count = 3, .min_index = 5, .kind = 1};
        facts.chat.packs.at(8) = ChatPack{.real_id = 13, .count = 0, .min_index = 5, .kind = 1};
    }

    void raise(std::string_view name, std::initializer_list<std::string_view> given = {}) {
        const ui::panel::UiEvent event =
            args.raise(name, std::span<const std::string_view>(given.begin(), given.size()));
        ui::panel::on_function_bar_right_2_event(bar, event, facts, calls);
    }
    [[nodiscard]] bool can_do() const {
        return ui::panel::can_do_action([this](std::string_view window) { return is_shop_shown && window == "Shop"; });
    }
    void press(std::int32_t id) { ui::panel::press_bar_button(bar, id, can_do(), calls); }
    [[nodiscard]] std::vector<std::string> lines() { return panel_lines(bar.is_shown, bar.widgets, calls); }
};

// Đúng thứ tự các bước của TOOLS/port/oracle/function_bar_right_2_bar.lua.
constexpr std::array kScript = {
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"61", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "61", "301"}); },
    +[](Rig& rig) { rig.raise("OPEN_RIGHT_BAR_2", {"1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "61", "301"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"62", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"62", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"62", "1"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"62", "0"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"70", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "63", "305", "0"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "62", "302"}); },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = true;
        rig.raise("CHANGE_BAR", {"main", "64", "306", "1"});
    },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = false;
        rig.raise("CHANGE_BAR", {"main", "65", "307", "1"});
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "66", "308", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "69", "309", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "60", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "70", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"other", "61", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "61.5", "2"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "chu", "2"}); },
    +[](Rig& rig) {
        rig.raise("FLASH_COMBOSKILL", {"61", "1"});
        rig.raise("FLASH_COMBOSKILL", {"65", "2"});
        rig.raise("ACTION_UPDATE");
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "3", "61", "65", "99"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "1", "69"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "6", "62"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR4", {"11"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR4", {"chu"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "62", "905"});
        rig.raise("CHANGE_BAR", {"main", "63", "903"});
        rig.raise("CHANGE_BAR", {"main", "64", "906"});
        rig.raise("CHANGE_BAR", {"main", "65", "0"});
        rig.raise("CHANGE_BAR", {"main", "66", "1102"});
        rig.raise("CHANGE_BAR", {"main", "67", "1101"});
        rig.raise("UNINSTALL_CHAT_ACTION_BAR4", {"2"});
    },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR4", {"4"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR4", {"6"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR4", {"8"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR4", {"3"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "68", "904"});
        rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_4", "2", "5", "6"});
    },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight_2", "2", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight_2", "-1", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight_2", "7", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight_2", "7", "chu", "6"}); },
    +[](Rig& rig) { rig.raise("OPEN_RIGHT_BAR_2", {"0"}); },
    +[](Rig& rig) {
        rig.facts.transform = 1;
        rig.raise("OPEN_RIGHT_BAR_2", {"1"});
    },
    +[](Rig& rig) {
        rig.facts.transform = 0;
        rig.raise("OPEN_RIGHT_BAR_2", {"2"});
    },
    +[](Rig& rig) { rig.raise("OPEN_RIGHT_BAR_2", {"1"}); },
    +[](Rig& rig) { rig.raise("HIDE_THIS_UI"); },
    +[](Rig& rig) { rig.raise("HIDE_THIS_UI"); },
    +[](Rig& rig) {
        rig.press(63);
        rig.press(64);
        rig.press(69);
    },
    +[](Rig& rig) {
        rig.is_shop_shown = true;
        rig.press(63);
    },
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

void registered_events_are_all_always(Context& context) {
    for (const ui::panel::EventSub& sub : ui::panel::kFunctionBarRight2Events) {
        context.expect(ui::panel::is_delivered(ui::panel::kFunctionBarRight2Events, sub.name, false),
            "RegisterEvent không nêu cờ hay cờ true thì nhận cả lúc thanh ẩn");
    }
    context.expect(!ui::panel::is_delivered(ui::panel::kFunctionBarRight2Events, "OPEN_UP_BAR_2", true),
        "sự kiện của thanh khác không tới");
    context.expect(ui::panel::is_delivered(
                       ui::panel::kFunctionBarRight2Events, ui::panel::kFunctionBarRight2Spec.uninstall_event, false),
        "sự kiện gỡ gói của thanh nằm trong bảng đăng ký");
}

// Chuỗi gỡ gói: thanh này nhận sự kiện của cấp mà thanh trước đẩy (FunctionBarRight, cấp 4) và đẩy cấp 5, tức sự kiện
// mà MainMenuBar_4 nghe; dọn gói quá hạn thì chuyển cho đúng MainMenuBar_4.
void uninstall_chain_links_to_main_menu_bar_4(Context& context) {
    using ui::panel::uninstall_chat_action_event;
    context.expect(ui::panel::kFunctionBarRight2Spec.uninstall_event == uninstall_chat_action_event(4),
        "nhận sự kiện của cấp 4 do FunctionBarRight gửi");
    context.expect(uninstall_chat_action_event(ui::panel::kFunctionBarRight2Spec.uninstall_level) ==
            ui::panel::kMainMenuBar4Spec.uninstall_event,
        "đẩy cấp 5 là sự kiện của MainMenuBar_4");
    context.expect(ui::panel::kFunctionBarRight2Spec.forward == ui::panel::kMainMenuBar4Spec.name,
        "dọn gói chuyển tiếp cho MainMenuBar_4");
}

void button_names_map_to_ids(Context& context) {
    const Rig rig;
    context.expect(
        ui::panel::bar_button_id(rig.bar, "FunctionBarRight_2_Button_Action1") == 61, "ô đầu là 61");
    context.expect(
        ui::panel::bar_button_id(rig.bar, "FunctionBarRight_2_Button_Action9") == 69, "ô cuối là 69");
    context.expect(!ui::panel::bar_button_id(rig.bar, "FunctionBarRight_2_Button_Action10").has_value(),
        "thanh chỉ có chín ô");
    context.expect(rig.bar.root == "FunctionBarRight_2_Frame", "cửa sổ gốc");
    context.expect(rig.bar.juniors.back() == "FunctionBarRight_2_Function_Button9_junior_Flash", "cửa sổ nháy cấp thấp");
    context.expect(rig.bar.seniors.front() == "FunctionBarRight_2_Function_Button1_senior_Flash", "cửa sổ nháy cấp cao");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "registered_events_are_all_always", .body = &registered_events_are_all_always},
    Case{.name = "uninstall_chain_links_to_main_menu_bar_4", .body = &uninstall_chain_links_to_main_menu_bar_4},
    Case{.name = "button_names_map_to_ids", .body = &button_names_map_to_ids},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_function_bar_right_2_tests: mọi ca phải qua");
    return 0;
}
