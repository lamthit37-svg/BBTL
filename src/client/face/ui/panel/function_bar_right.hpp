// Thanh action bên phải (FunctionBarRight): chín ô action id 41..49 của hệ thanh action, mỗi ô có hai cửa sổ nháy combo, và
// chuỗi gỡ gói hành động chat đôi (nhận UNINSTALL_CHAT_ACTION_BAR3, gỡ xong đẩy cấp 4 cho FunctionBarRight_2; dọn gói quá hạn
// thì chuyển Clear_ChatAction_Bar cho FunctionBarRight_2).
// Nguồn: Interface/FunctionBarRight/FunctionBarRight.lua của client 2026 (8 hàm). Phần thân giống ba thanh kia nằm ở
// action_bar.hpp; file này khai BarSpec, bảng đăng ký sự kiện và các nhánh riêng: chặn GM đang ẩn hay đang xem trận trước mọi
// sự kiện, PLAYER_ENTERING_WORLD và SHOW_TRANSFIGURATION_SKILL. Test/Ui/ui_function_bar_right_tests.cpp so trạng thái với
// số vàng do script gốc chạy trên LuaPlus.dll (Test/golden/panel/function_bar_right_bar.tsv, kịch bản
// TOOLS/port/oracle/function_bar_right_bar.lua).
// Port 8/8 hàm; FunctionBarRight_PreLoad -> kFunctionBarRightEvents, FunctionBarRight_OnLoad -> make_function_bar_right (ba bảng
// cửa sổ), FunctionBarRight_OnEvent -> on_function_bar_right_event và on_bar_event, FunctionBarRight_UpdateComboFlash,
// _ActionUpdate, _UnInstallChatActionButton, _ClearChatActionButton, _Clicked -> combo_flash, refresh_flashes,
// uninstall_chat_action, clear_chat_action, press_bar_button (nằm trong action_bar.cpp).
// Khác gốc: xem đầu action_bar.hpp (hệ action, hệ thú cưng, kho gói hành động chat, GM, chế độ xem trận do BarFacts mang).
#pragma once

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <vector>

namespace game::ui::panel {

// Chín ô 41..49 (RIGHTBAR_BUTTONS). Khác FunctionBarRight_2: Target:UpdateActionButton gọi ở mọi CHANGE_BAR main, kể cả id
// ngoài dải.
inline constexpr BarSpec kFunctionBarRightSpec = {
    .name = "FunctionBarRight",
    .flash_infix = "_Function_Button",
    .first_id = 41,
    .count = 9,
    .set_range = {.low = 40.0, .is_low_closed = false, .high = 50.0, .is_high_closed = false},
    .seen_range = {.low = 40.0, .is_low_closed = false, .high = 50.0, .is_high_closed = false},
    .is_refresh_always = true,
    .uninstall_event = "UNINSTALL_CHAT_ACTION_BAR3",
    .uninstall_level = 4,
    .forward = "FunctionBarRight_2",
};

// FunctionBarRight_PreLoad: tám sự kiện; chỉ ACTION_UPDATE đăng ký cờ false (thanh ẩn thì không nhận).
inline constexpr std::array<EventSub, 8> kFunctionBarRightEvents = {{
    {.name = "PLAYER_ENTERING_WORLD", .is_always = true},
    {.name = "CHANGE_BAR", .is_always = true},
    {.name = "ACTION_UPDATE", .is_always = false},
    {.name = "UNINSTALL_CHAT_ACTION_BAR3", .is_always = true},
    {.name = "CLEAR_CHAT_ACTION_BAR", .is_always = true},
    {.name = "SHOW_TRANSFIGURATION_SKILL", .is_always = true},
    {.name = "FLASH_COMBOSKILL", .is_always = true},
    {.name = "HIDE_THIS_UI", .is_always = true},
}};

[[nodiscard]] inline ActionBar make_function_bar_right() {
    return make_action_bar(kFunctionBarRightSpec);
}

// FunctionBarRight_OnEvent: một sự kiện đã đăng ký. Trước mọi nhánh, GM đang ẩn (DataPool:LuaFnGetGMVisibleType() ~= 0) hay
// đang xem trận (ZBS:IsViewerWatching() > 0) thì giấu thanh rồi thôi. PLAYER_ENTERING_WORLD hiện thanh;
// SHOW_TRANSFIGURATION_SKILL với arg0 "2" giấu, "0" hiện, giá trị khác không đổi.
void on_function_bar_right_event(
    ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls);

} // namespace game::ui::panel
