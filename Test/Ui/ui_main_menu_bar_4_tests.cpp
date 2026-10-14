// Thanh action MainMenuBar_4 (ui/panel/main_menu_bar_4 trên lõi action_bar): bản port để lại đúng trạng thái cửa sổ
// và đúng việc nhờ game mà MainMenuBar_4.lua của client 2026 để lại khi chạy trên LuaPlus.dll gốc
// (Test/golden/panel/main_menu_bar_4_bar.tsv, sinh bằng TOOLS/port/lua_oracle.py với kịch bản
// TOOLS/port/oracle/main_menu_bar_4_bar.lua), cùng các ca mà kịch bản không đi tới: bảng đăng ký sự kiện, tên sự
// kiện gỡ gói đọc từ Game.exe, tên ô và đầu vào thù địch.
#include "ui/panel/main_menu_bar_4.hpp"

#include "core/check.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/can_do.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

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

constexpr std::string_view kGoldenFile = "main_menu_bar_4_bar.tsv";

// Mọi thứ một bước của kịch bản trọng tài đụng tới: thanh, kho đối số, điều game trả cho script (BarFacts), việc đã nhờ
// và cửa sổ cửa hàng đang hiện.
struct Rig {
    ui::panel::ActionBar bar = ui::panel::make_main_menu_bar_4();
    ui::panel::EventArgs args;
    ui::panel::BarFacts facts;
    std::vector<Call> calls;
    bool is_shop_shown = false;

    Rig() {
        // Gói cài và danh sách mood của kịch bản: TOOLS/port/oracle/main_menu_bar_4_bar.lua.
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
        ui::panel::on_main_menu_bar_4_event(bar, event, facts, calls);
    }
    [[nodiscard]] bool can_do() const {
        return ui::panel::can_do_action([this](std::string_view window) { return is_shop_shown && window == "Shop"; });
    }
    void press(std::int32_t id) { ui::panel::press_bar_button(bar, id, can_do(), calls); }
    [[nodiscard]] std::vector<std::string> lines() { return panel_lines(bar.is_shown, bar.widgets, calls); }
};

// Đúng thứ tự các bước của TOOLS/port/oracle/main_menu_bar_4_bar.lua.
constexpr std::array kScript = {
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"71", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "71", "301"}); },
    +[](Rig& rig) { rig.raise("OPEN_UP_BAR_2", {"1", "UpBar2"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "71", "301"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"72", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"72", "2"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"72", "1"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"72", "0"}); },
    +[](Rig& rig) { rig.raise("FLASH_COMBOSKILL", {"81", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "73", "305", "0"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "72", "302"}); },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = true;
        rig.raise("CHANGE_BAR", {"main", "74", "306", "1"});
    },
    +[](Rig& rig) {
        rig.facts.pet_is_fighting.at(1) = false;
        rig.raise("CHANGE_BAR", {"main", "75", "307", "1"});
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "76", "308", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "77", "309", "9"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "60", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"other", "71", "1"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "71.5", "2"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"main", "chu", "2"}); },
    +[](Rig& rig) {
        rig.raise("FLASH_COMBOSKILL", {"71", "1"});
        rig.raise("FLASH_COMBOSKILL", {"75", "2"});
        rig.raise("ACTION_UPDATE");
    },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "3", "71", "75", "99"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "1", "80"}); },
    +[](Rig& rig) { rig.raise("CHANGE_BAR", {"mainreset", "6", "72"}); },
    +[](Rig& rig) { rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"11"}); },
    +[](Rig& rig) { rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"chu"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "72", "905"});
        rig.raise("CHANGE_BAR", {"main", "73", "903"});
        rig.raise("CHANGE_BAR", {"main", "74", "906"});
        rig.raise("CHANGE_BAR", {"main", "75", "0"});
        rig.raise("CHANGE_BAR", {"main", "76", "1102"});
        rig.raise("CHANGE_BAR", {"main", "77", "1101"});
        rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"2"});
    },
    +[](Rig& rig) { rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"4"}); },
    +[](Rig& rig) { rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"6"}); },
    +[](Rig& rig) { rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"8"}); },
    +[](Rig& rig) { rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"3"}); },
    +[](Rig& rig) {
        rig.raise("CHANGE_BAR", {"main", "78", "904"});
        rig.raise("CLEAR_CHAT_ACTION_BAR", {"FunctionBarRight", "2", "5", "6"});
    },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_4", "2", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_4", "-1", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_4", "7", "5", "6"}); },
    +[](Rig& rig) { rig.raise("CLEAR_CHAT_ACTION_BAR", {"MainMenuBar_4", "7", "chu", "6"}); },
    +[](Rig& rig) { rig.raise("OPEN_UP_BAR_2", {"0", "UpBar2"}); },
    +[](Rig& rig) {
        rig.facts.is_in_tlcj_scene = true;
        rig.raise("OPEN_UP_BAR_2", {"1", "UpBar2"});
    },
    +[](Rig& rig) {
        rig.facts.is_in_tlcj_scene = false;
        rig.raise("OPEN_UP_BAR_2", {"1", "Other"});
    },
    +[](Rig& rig) { rig.raise("HIDE_THIS_UI"); },
    +[](Rig& rig) {
        rig.press(73);
        rig.press(74);
        rig.press(80);
    },
    +[](Rig& rig) {
        rig.is_shop_shown = true;
        rig.press(73);
    },
    +[](Rig& rig) {
        rig.is_shop_shown = false;
        rig.raise("HIDE_THIS_UI");
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
    for (const ui::panel::EventSub& sub : ui::panel::kMainMenuBar4Events) {
        context.expect(ui::panel::is_delivered(ui::panel::kMainMenuBar4Events, sub.name, false),
            "RegisterEvent không nêu cờ thì nhận cả lúc thanh ẩn");
    }
    context.expect(!ui::panel::is_delivered(ui::panel::kMainMenuBar4Events, "OPEN_MENUBAR_2", true),
        "sự kiện của thanh khác không tới");
    context.expect(
        ui::panel::is_delivered(ui::panel::kMainMenuBar4Events, ui::panel::kMainMenuBar4Spec.uninstall_event, false),
        "sự kiện gỡ gói của thanh nằm trong bảng đăng ký");
}

// Tên sự kiện ứng cấp UnInstall_RMB_ChatAction đọc từ bảng đăng ký sự kiện UI của Game.exe (0x140a272b0): id 0x325
// UNINSTALL_CHAT_ACTION_CONFIRM, 0x326 UNINSTALL_CHAT_ACTION_BAR, 0x327 và 0x328 ..BAR2 và ..BAR3, 0x38c ..BAR4, 0x38d
// GE_UNINSTALL_CHAT_ACTION_BAR5; cấp 6 gửi gói tin nên không có sự kiện.
void uninstall_levels_map_to_game_events(Context& context) {
    using ui::panel::uninstall_chat_action_event;
    context.expect(uninstall_chat_action_event(0) == "UNINSTALL_CHAT_ACTION_CONFIRM", "cấp 0 là xác nhận gỡ gói");
    context.expect(uninstall_chat_action_event(1) == "UNINSTALL_CHAT_ACTION_BAR", "cấp 1 là thanh chính");
    context.expect(uninstall_chat_action_event(2) == "UNINSTALL_CHAT_ACTION_BAR2", "cấp 2");
    context.expect(uninstall_chat_action_event(3) == "UNINSTALL_CHAT_ACTION_BAR3", "cấp 3");
    context.expect(uninstall_chat_action_event(4) == "UNINSTALL_CHAT_ACTION_BAR4", "cấp 4");
    context.expect(uninstall_chat_action_event(5) == "GE_UNINSTALL_CHAT_ACTION_BAR5", "cấp 5");
    context.expect(!uninstall_chat_action_event(ui::panel::kUninstallByPacket).has_value(), "cấp 6 gửi gói tin");
    context.expect(!uninstall_chat_action_event(-1).has_value(), "cấp âm không có sự kiện");
    context.expect(!uninstall_chat_action_event(7).has_value(), "cấp ngoài bảng không có sự kiện");
    context.expect(ui::panel::kMainMenuBar4Spec.uninstall_event == uninstall_chat_action_event(5),
        "MainMenuBar_4 nhận sự kiện của cấp 5 do FunctionBarRight_2 gửi");
    context.expect(ui::panel::kMainMenuBar4Spec.uninstall_level == ui::panel::kUninstallByPacket,
        "MainMenuBar_4 là cuối chuỗi: gỡ xong thì gửi gói tin");
}

void button_names_map_to_ids(Context& context) {
    const Rig rig;
    context.expect(ui::panel::bar_button_id(rig.bar, "MainMenuBar_4_Button_Action1") == 71, "ô đầu là 71");
    context.expect(ui::panel::bar_button_id(rig.bar, "MainMenuBar_4_Button_Action10") == 80, "ô cuối là 80");
    context.expect(!ui::panel::bar_button_id(rig.bar, "MainMenuBar_4_Button_Action11").has_value(), "không có ô 11");
    context.expect(!ui::panel::bar_button_id(rig.bar, "MainMenuBar_4_Button1_junior_Flash").has_value(),
        "cửa sổ nháy không phải ô action");
    context.expect(rig.bar.root == "MainMenuBar_4_Frame", "cửa sổ gốc");
}

void stray_button_id_does_nothing(Context& context) {
    Rig rig;
    rig.raise("CHANGE_BAR", {"main", "71", "301"});
    rig.calls.clear();
    rig.press(70);
    rig.press(81);
    rig.press(-1);
    rig.press(std::numeric_limits<std::int32_t>::max());
    context.expect(rig.calls.empty(), "id ngoài 71..80 không ứng ô nào");
    rig.press(71);
    context.expect(
        rig.calls.size() == 1 && rig.calls.front().ask == ui::panel::Ask::kDoAction, "ô có action thì thi triển");
}

// Gói do dữ liệu hỏng hay thù địch (số hành động và chỉ số đầu cực lớn, âm) không làm vòng gỡ gói chạy theo con số ấy
// và không tràn: chỉ phần giao với danh sách mood được duyệt.
void hostile_pack_data_is_bounded(Context& context) {
    Rig rig;
    rig.raise("OPEN_UP_BAR_2", {"1", "UpBar2"});
    rig.raise("CHANGE_BAR", {"main", "71", "905"});
    rig.calls.clear();
    constexpr std::int32_t kMax = std::numeric_limits<std::int32_t>::max();
    rig.facts.chat.packs.at(1) = ChatPack{.real_id = 1, .count = kMax, .min_index = kMax, .kind = 1};
    rig.facts.chat.packs.at(2) = ChatPack{.real_id = 1, .count = kMax, .min_index = 1, .kind = 1};
    rig.facts.chat.packs.at(3) = ChatPack{.real_id = 1, .count = -5, .min_index = 1, .kind = 1};
    rig.facts.chat.packs.at(5) = ChatPack{.real_id = -1, .count = 3, .min_index = 1, .kind = 1};
    constexpr std::string_view kButton = "MainMenuBar_4_Button_Action1";
    rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"1"});
    context.expect(rig.bar.widgets.action_item(kButton) == 905, "chỉ số đầu ngoài danh sách thì không gỡ ô nào");
    rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"3"});
    rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"5"});
    context.expect(rig.bar.widgets.action_item(kButton) == 905, "gói số âm hay real id âm không gỡ ô nào");
    rig.raise("GE_UNINSTALL_CHAT_ACTION_BAR5", {"2"});
    context.expect(rig.bar.widgets.action_item(kButton) == ui::panel::kEmptyAction,
        "số hành động cực lớn vẫn gỡ đúng ô trùng trong danh sách");
}

void paint_only_when_shown(Context& context) {
    Rig rig;
    ui::panel::Deck deck;
    ui::panel::paint_action_bar(deck, rig.bar);
    context.expect(!deck.is_shown(rig.bar.root), "thanh ẩn thì không hiện cửa sổ gốc");
    rig.raise("OPEN_UP_BAR_2", {"1", "UpBar2"});
    ui::panel::paint_action_bar(deck, rig.bar);
    context.expect(deck.is_shown(rig.bar.root), "thanh hiện thì hiện cửa sổ gốc");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "registered_events_are_all_always", .body = &registered_events_are_all_always},
    Case{.name = "uninstall_levels_map_to_game_events", .body = &uninstall_levels_map_to_game_events},
    Case{.name = "button_names_map_to_ids", .body = &button_names_map_to_ids},
    Case{.name = "stray_button_id_does_nothing", .body = &stray_button_id_does_nothing},
    Case{.name = "hostile_pack_data_is_bounded", .body = &hostile_pack_data_is_bounded},
    Case{.name = "paint_only_when_shown", .body = &paint_only_when_shown},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_main_menu_bar_4_tests: mọi ca phải qua");
    return 0;
}
