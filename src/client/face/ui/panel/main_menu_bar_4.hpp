// Thanh action phụ phía trên (MainMenuBar_4, "UpBar2"): mười ô action id 71..80 của hệ thanh action, mỗi ô có hai
// cửa sổ nháy combo, và chuỗi gỡ gói hành động chat đôi (thanh cuối của chuỗi: gỡ xong thì gửi gói tin).
// Nguồn: Interface/MainMenuBar_4/MainMenuBar_4.lua của client 2026 (8 hàm). Phần thân giống ba thanh kia nằm ở
// action_bar.hpp; file này khai BarSpec và xử lý OPEN_UP_BAR_2. Test/Ui/ui_main_menu_bar_4_tests.cpp so trạng thái
// với số vàng do script gốc chạy trên LuaPlus.dll (Test/golden/panel/main_menu_bar_4_bar.tsv, kịch bản
// TOOLS/port/oracle/main_menu_bar_4_bar.lua).
// Port 8/8 hàm; MainMenuBar_4_PreLoad -> kMainMenuBar4Events, MainMenuBar_4_OnLoad -> make_main_menu_bar_4 (ba bảng
// cửa sổ), MainMenuBar_4_OnEvent -> on_main_menu_bar_4_event và on_bar_event, MainmenuBar_4_UpdateComboFlash ->
// combo_flash, MainMenuBar_4_ActionUpdate -> refresh_flashes, MainMenuBar_4_UnInstallChatActionButton ->
// uninstall_chat_action, MainMenuBar_4_ClearChatActionButton -> clear_chat_action, MainMenuBar_4_Clicked ->
// press_bar_button (hàm nằm trong action_bar.cpp).
// Khác gốc: xem đầu action_bar.hpp (hệ action, hệ thú cưng, kho gói hành động chat do BarFacts mang).
#pragma once

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <vector>

namespace game::ui::panel {

// Mười ô 71..80 (UPBAR_2_BUTTONS); thanh cuối của chuỗi nên không chuyển Clear_ChatAction_Bar tiếp mà ghi vào kho.
inline constexpr BarSpec kMainMenuBar4Spec = {
    .name = "MainMenuBar_4",
    .flash_infix = "_Button",
    .first_id = 71,
    .count = 10,
    .set_range = {.low = 70.0, .is_low_closed = false, .high = 81.0, .is_high_closed = false},
    .seen_range = {.low = 70.0, .is_low_closed = false, .high = 80.0, .is_high_closed = true},
    .is_refresh_always = true,
    .uninstall_event = "GE_UNINSTALL_CHAT_ACTION_BAR5",
    .uninstall_level = kUninstallByPacket,
    .forward = {},
};

// MainMenuBar_4_PreLoad: bảy sự kiện, đều nhận cả lúc thanh ẩn (RegisterEvent không nêu cờ thì cờ là true).
inline constexpr std::array<EventSub, 7> kMainMenuBar4Events = {{
    {.name = "CHANGE_BAR", .is_always = true},
    {.name = "ACTION_UPDATE", .is_always = true},
    {.name = "GE_UNINSTALL_CHAT_ACTION_BAR5", .is_always = true},
    {.name = "CLEAR_CHAT_ACTION_BAR", .is_always = true},
    {.name = "OPEN_UP_BAR_2", .is_always = true},
    {.name = "FLASH_COMBOSKILL", .is_always = true},
    {.name = "HIDE_THIS_UI", .is_always = true},
}};

[[nodiscard]] inline ActionBar make_main_menu_bar_4() {
    return make_action_bar(kMainMenuBar4Spec);
}

// MainMenuBar_4_OnEvent: một sự kiện đã đăng ký. Nhánh OPEN_UP_BAR_2 (arg0 "1" và arg1 "UpBar2", không ở cảnh TLCJ) hiện
// thanh và đẩy SWITCH_MENU_BUTTON 1, còn lại giấu thanh và đẩy SWITCH_MENU_BUTTON 0.
void on_main_menu_bar_4_event(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls);

} // namespace game::ui::panel
