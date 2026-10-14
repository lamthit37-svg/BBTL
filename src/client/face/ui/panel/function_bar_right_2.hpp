// Thanh action bên phải thứ hai (FunctionBarRight_2): chín ô action id 61..69 của hệ thanh action, mỗi ô có hai cửa sổ
// nháy combo, và chuỗi gỡ gói hành động chat đôi (nhận UNINSTALL_CHAT_ACTION_BAR4, gỡ xong đẩy cấp 5 cho MainMenuBar_4;
// dọn gói quá hạn thì chuyển Clear_ChatAction_Bar cho MainMenuBar_4).
// Nguồn: Interface/FunctionBarRight_2/FunctionBarRight_2.lua của client 2026 (8 hàm). Phần thân giống ba thanh kia nằm ở
// action_bar.hpp; file này khai BarSpec và xử lý OPEN_RIGHT_BAR_2. Test/Ui/ui_function_bar_right_2_tests.cpp so trạng thái
// với số vàng do script gốc chạy trên LuaPlus.dll (Test/golden/panel/function_bar_right_2_bar.tsv, kịch bản
// TOOLS/port/oracle/function_bar_right_2_bar.lua).
// Port 8/8 hàm; FunctionBarRight_2_PreLoad -> kFunctionBarRight2Events, FunctionBarRight_2_OnLoad ->
// make_function_bar_right_2 (ba bảng cửa sổ), FunctionBarRight_2_OnEvent -> on_function_bar_right_2_event và on_bar_event,
// FunctionBarRight_2_UpdateComboFlash, _ActionUpdate, _UnInstallChatActionButton, _ClearChatActionButton, _Clicked ->
// combo_flash, refresh_flashes, uninstall_chat_action, clear_chat_action, press_bar_button (nằm trong action_bar.cpp).
// Khác gốc: xem đầu action_bar.hpp (hệ action, hệ thú cưng, kho gói hành động chat do BarFacts mang).
#pragma once

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <vector>

namespace game::ui::panel {

// Chín ô 61..69 (RIGHTBAR_2_BUTTONS). Khác ba thanh kia: Target:UpdateActionButton chỉ được gọi khi id nằm trong dải (nằm
// trong nhánh if của CHANGE_BAR main).
inline constexpr BarSpec kFunctionBarRight2Spec = {
    .name = "FunctionBarRight_2",
    .flash_infix = "_Function_Button",
    .first_id = 61,
    .count = 9,
    .set_range = {.low = 60.0, .is_low_closed = false, .high = 70.0, .is_high_closed = false},
    .seen_range = {.low = 60.0, .is_low_closed = false, .high = 70.0, .is_high_closed = false},
    .is_refresh_always = false,
    .uninstall_event = "UNINSTALL_CHAT_ACTION_BAR4",
    .uninstall_level = 5,
    .forward = "MainMenuBar_4",
};

// FunctionBarRight_2_PreLoad: bảy sự kiện, đều nhận cả lúc thanh ẩn (RegisterEvent không nêu cờ, hay cờ true).
inline constexpr std::array<EventSub, 7> kFunctionBarRight2Events = {{
    {.name = "CHANGE_BAR", .is_always = true},
    {.name = "ACTION_UPDATE", .is_always = true},
    {.name = "UNINSTALL_CHAT_ACTION_BAR4", .is_always = true},
    {.name = "CLEAR_CHAT_ACTION_BAR", .is_always = true},
    {.name = "OPEN_RIGHT_BAR_2", .is_always = true},
    {.name = "FLASH_COMBOSKILL", .is_always = true},
    {.name = "HIDE_THIS_UI", .is_always = true},
}};

[[nodiscard]] inline ActionBar make_function_bar_right_2() {
    return make_action_bar(kFunctionBarRight2Spec);
}

// FunctionBarRight_2_OnEvent: một sự kiện đã đăng ký. Nhánh OPEN_RIGHT_BAR_2 hiện thanh khi arg0 là "1" và người chơi không
// biến hình (DataPool:GetTrans() ~= 1), còn lại giấu.
void on_function_bar_right_2_event(
    ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls);

} // namespace game::ui::panel
