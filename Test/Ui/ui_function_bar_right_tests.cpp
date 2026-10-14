// Thanh action FunctionBarRight (ui/panel/function_bar_right trên lõi action_bar): bản port để lại đúng trạng thái cửa sổ
// và đúng việc nhờ game mà FunctionBarRight.lua của client 2026 để lại khi chạy trên LuaPlus.dll gốc
// (Test/golden/panel/function_bar_right_bar.tsv, sinh bằng TOOLS/port/lua_oracle.py với kịch bản
// TOOLS/port/oracle/function_bar_right_bar.lua), cùng các ca mà kịch bản không đi tới: bảng đăng ký sự kiện (ACTION_UPDATE
// chỉ tới thanh đang hiện), nối chuỗi gỡ gói với thanh kế, tên ô.
#include "ui/panel/function_bar_right.hpp"

#include "core/check.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/can_do.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/function_bar_right_2.hpp"

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

constexpr std::string_view kGoldenFile = "function_bar_right_bar.tsv";

// Mọi thứ một bước của kịch bản trọng tài đụng tới: thanh, kho đối số, điều game trả cho script (BarFacts), việc đã nhờ
// và cửa sổ cửa hàng đang hiện.
struct Rig {
    ui::panel::ActionBar bar = ui::panel::make_function_bar_right();
    ui::panel::EventArgs args;
    ui::panel::BarFacts facts;
    std::vector<Call> calls;
    bool is_shop_shown = false;

    Rig() {
        // Gói cài và danh sách mood của kịch bản: TOOLS/port/oracle/function_bar_right_bar.lua.
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
        ui::panel::on_function_bar_right_event(bar, event, facts, calls);
    }
    [[nodiscard]] bool can_do() const {
        return ui::panel::can_do_action([this](std::string_view window) { return is_shop_shown && window == "Shop"; });
    }
    void press(std::int32_t id) { ui::panel::press_bar_button(bar, id, can_do(), calls); }
    [[nodiscard]] std::vector<std::string> lines() { return panel_lines(bar.is_shown, bar.widgets, calls); }
};

// Đúng thứ tự các bước của TOOLS/port/oracle/function_bar_right_bar.lua.
constexpr std::array kScript = {
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"41", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "41", "301"}); },
    +[](Rig& rig) { rig.raise("PLAYER_ENTERING_WORLD"); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "41", "301"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"42", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"42", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"42", "1"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"42", "0"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"50", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "43", "305", "0"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "42", "302"}); },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = true;
        rig.raise("CHANGE_BAR", {"main", "44", "306", "1"});
    },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = false;
        rig.raise("CHANGE_BAR", {"main", "45", "307", "1"});
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "46", "308", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "49", "309", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "40", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "50", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"other", "41", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "41.5", "2"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "chu", "2"}); },
    +[](Rig& rig) {
        rig.raise("FLASH_COMBOSKILL", {"41", "1"});
        rig.raise("FLASH_COMBOSKILL", {"45", "2"});
        rig.raise("ACTION_UPDATE");
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "3", "41", "45", "99"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "1", "49"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "6", "42"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR3", {"11"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR3", {"chu"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "42", "905"});
        rig.raise("CHANGE_BAR", {"main", "43", "903"});
        rig.raise("CHANGE_BAR", {"main", "44", "906"});
        rig.raise("CHANGE_BAR", {"main", "45", "0"});
        rig.raise("CHANGE_BAR", {"main", "46", "1102"});
        rig.raise("CHANGE_BAR", {"main", "47", "1101"});
        rig.raise("UNINSTALL_CHAT_ACTION_BAR3", {"2"});
    },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR3", {"4"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR3", {"6"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR3", {"8"}); },
    +[](Rig& rig) { rig.raise("UNINSTALL_CHAT_ACTION_BAR3", {"3"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "48", "904"});
        rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_4", "2", "5", "6"});
    },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight_2", "2", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight", "2", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight", "-1", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight", "7", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight", "7", "chu", "6"}); },
    +[](Rig& rig) { rig.raise("SHOW_TRANSFIGURATION_SKILL", {"2"}); },
    +[](Rig& rig) { rig.raise("SHOW_TRANSFIGURATION_SKILL", {"1"}); },
    +[](Rig& rig) { rig.raise("SHOW_TRANSFIGURATION_SKILL", {"0"}); },
    +[](Rig& rig) {
        rig.raise("SHOW_TRANSFIGURATION_SKILL", {"2"});
        rig.raise("SHOW_TRANSFIGURATION_SKILL", {"chu"});
    },
    +[](Rig& rig) { rig.raise("PLAYER_ENTERING_WORLD"); },
    +[](Rig& rig) { rig.raise("HIDE_THIS_UI"); },
    +[](Rig& rig) { rig.raise("HIDE_THIS_UI"); },
    +[](Rig& rig) {
        rig.facts.gm_visible_type = 1;
        rig.raise("CHANGE_BAR", {"main", "41", "301"});
    },
    +[](Rig& rig) { rig.raise("PLAYER_ENTERING_WORLD"); },
    +[](Rig& rig) {
        rig.facts.gm_visible_type = 0;
        rig.facts.viewer_watching = 1;
        rig.raise("PLAYER_ENTERING_WORLD");
    },
    +[](Rig& rig) {
        rig.facts.viewer_watching = 0;
        rig.raise("PLAYER_ENTERING_WORLD");
    },
    +[](Rig& rig) {
        rig.facts.viewer_watching = -1;
        rig.raise("HIDE_THIS_UI");
    },
    +[](Rig& rig) {
        rig.facts.viewer_watching = 0;
        rig.raise("PLAYER_ENTERING_WORLD");
        rig.press(43);
        rig.press(44);
        rig.press(49);
    },
    +[](Rig& rig) {
        rig.is_shop_shown = true;
        rig.press(43);
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

void bar_starts_hidden(Context& context) {
    const Rig rig;
    context.expect(!rig.bar.is_shown, "layout nạp ở trạng thái ẩn, thanh chờ PLAYER_ENTERING_WORLD");
}

// Chỉ ACTION_UPDATE đăng ký cờ false: thanh ẩn thì không nhận; các sự kiện khác nhận cả lúc ẩn.
void only_action_update_needs_a_shown_bar(Context& context) {
    for (const ui::panel::EventSub& sub : ui::panel::kFunctionBarRightEvents) {
        const bool is_action_update = sub.name == "ACTION_UPDATE";
        context.expect(
            ui::panel::is_delivered(ui::panel::kFunctionBarRightEvents, sub.name, false) == !is_action_update,
            "thanh ẩn chỉ không nhận ACTION_UPDATE");
        context.expect(ui::panel::is_delivered(ui::panel::kFunctionBarRightEvents, sub.name, true),
            "thanh hiện nhận mọi sự kiện đã đăng ký");
    }
    context.expect(!ui::panel::is_delivered(ui::panel::kFunctionBarRightEvents, "OPEN_RIGHT_BAR_2", true),
        "sự kiện của thanh khác không tới");
    context.expect(ui::panel::is_delivered(
                       ui::panel::kFunctionBarRightEvents, ui::panel::kFunctionBarRightSpec.uninstall_event, false),
        "sự kiện gỡ gói của thanh nằm trong bảng đăng ký");
}

// Chuỗi gỡ gói: thanh này nhận sự kiện của cấp mà MainMenuBar_2 đẩy (cấp 3) và đẩy cấp 4, tức sự kiện mà
// FunctionBarRight_2 nghe; dọn gói quá hạn thì chuyển cho đúng FunctionBarRight_2.
void uninstall_chain_links_to_function_bar_right_2(Context& context) {
    using ui::panel::uninstall_chat_action_event;
    context.expect(ui::panel::kFunctionBarRightSpec.uninstall_event == uninstall_chat_action_event(3),
        "nhận sự kiện của cấp 3 do MainMenuBar_2 gửi");
    context.expect(uninstall_chat_action_event(ui::panel::kFunctionBarRightSpec.uninstall_level) ==
            ui::panel::kFunctionBarRight2Spec.uninstall_event,
        "đẩy cấp 4 là sự kiện của FunctionBarRight_2");
    context.expect(ui::panel::kFunctionBarRightSpec.forward == ui::panel::kFunctionBarRight2Spec.name,
        "dọn gói chuyển tiếp cho FunctionBarRight_2");
}

void button_names_map_to_ids(Context& context) {
    const Rig rig;
    context.expect(ui::panel::bar_button_id(rig.bar, "FunctionBarRight_Button_Action1") == 41, "ô đầu là 41");
    context.expect(ui::panel::bar_button_id(rig.bar, "FunctionBarRight_Button_Action9") == 49, "ô cuối là 49");
    context.expect(!ui::panel::bar_button_id(rig.bar, "FunctionBarRight_Button_Action10").has_value(),
        "thanh chỉ có chín ô");
    context.expect(!ui::panel::bar_button_id(rig.bar, "FunctionBarRight_2_Button_Action1").has_value(),
        "ô của FunctionBarRight_2 không phải của thanh này");
    context.expect(rig.bar.root == "FunctionBarRight_Frame", "cửa sổ gốc");
    context.expect(rig.bar.juniors.back() == "FunctionBarRight_Function_Button9_junior_Flash", "cửa sổ nháy cấp thấp");
    context.expect(rig.bar.seniors.front() == "FunctionBarRight_Function_Button1_senior_Flash", "cửa sổ nháy cấp cao");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "bar_starts_hidden", .body = &bar_starts_hidden},
    Case{.name = "only_action_update_needs_a_shown_bar", .body = &only_action_update_needs_a_shown_bar},
    Case{.name = "uninstall_chain_links_to_function_bar_right_2", .body = &uninstall_chain_links_to_function_bar_right_2},
    Case{.name = "button_names_map_to_ids", .body = &button_names_map_to_ids},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_function_bar_right_tests: mọi ca phải qua");
    return 0;
}
