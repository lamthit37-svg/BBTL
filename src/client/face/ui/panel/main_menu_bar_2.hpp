// Thanh action phụ thứ hai (MainMenuBar_2): mười ô action id 31..40 của hệ thanh action, mỗi ô có hai cửa sổ nháy combo và
// một cửa sổ hoạt ảnh <ô>_Mask, mở bằng OPEN_MENUBAR_2; chuỗi gỡ gói hành động chat đôi (nhận UNINSTALL_CHAT_ACTION_BAR2, gỡ
// xong đẩy cấp 3 cho FunctionBarRight; dọn gói quá hạn thì chuyển Clear_ChatAction_Bar cho FunctionBarRight) và nhánh hướng
// dẫn tân thủ của lệnh giao diện UI_COMMAND 20130527.
// Nguồn: Interface/MainMenuBar_2/MainMenuBar_2.lua của client 2026 (10 hàm). Phần thân giống ba thanh kia nằm ở
// action_bar.hpp; file này khai BarSpec, bảng đăng ký sự kiện và các nhánh riêng: OPEN_MENUBAR_2, UI_COMMAND và Clicked có
// đóng lớp hướng dẫn. Test/Ui/ui_main_menu_bar_2_tests.cpp so trạng thái với số vàng do script gốc chạy trên LuaPlus.dll
// (Test/golden/panel/main_menu_bar_2_bar.tsv, kịch bản TOOLS/port/oracle/main_menu_bar_2_bar.lua).
// Port 10/10 hàm; MainMenuBar_2_PreLoad -> kMainMenuBar2Events, MainMenuBar_2_OnLoad -> make_main_menu_bar_2 (bốn bảng cửa sổ),
// MainMenuBar_2_OnEvent -> on_main_menu_bar_2_event và on_bar_event, MainmenuBar_2_UpdateComboFlash, _NewSkillStudy,
// _UnInstallChatActionButton, _ClearChatActionButton -> combo_flash, refresh_flashes, uninstall_chat_action, clear_chat_action
// (nằm trong action_bar.cpp), MainMenuBar_2_PlayAnimate -> play_masks, MainMenuBar_2_Clicked -> press_main_menu_bar_2,
// MainMenuBar_2_AdjustMoveCtl -> không làm gì (thân hàm toàn dòng chú thích; CHAT_ADJUST_MOVE_CTL đăng ký cờ false).
// Khác gốc: xem đầu action_bar.hpp, và:
//  - Hoạt ảnh <ô>_Mask: Show và Play(true) chỉ ghi vào Widgets; tầng vẽ chưa có cửa sổ TLBB_Animate (hoạt ảnh CoolDownEnd2
//    chưa nạp được), nên chưa thấy gì trên màn hình.
//  - UI_COMMAND 20130527: PutItemToMainmenuBar2(Get_XParam_INT(0)) (Game.exe 0x140267ae0, 0x140240ea0: tìm ô trống trong
//    ô 30..39 của hệ action, đặt vật phẩm vào đó rồi trả (1, ô); việc của kho đồ và hệ action) và hình học cửa sổ CEGUI
//    (GetProperty AbsoluteX/YPosition của khung, this:GetChildOffset, AbsoluteWidth/Height của ô), cùng chủ lớp hướng dẫn
//    (GetFreshManGuideOwner 0x1402621b0) do BarFacts::guide mang; OpenFreshManGuideNew (0x1402649e0) và CloseFreshManGuide
//    (0x140262120) chỉ ghi vào danh sách Call vì client chưa có lớp hướng dẫn tân thủ, kho đồ và hệ action. Máy chủ chưa
//    gửi lệnh UI_COMMAND này (máy chủ không có Lua).
#pragma once

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <cstdint>
#include <vector>

namespace game::ui::panel {

// Mười ô 31..40 (MAIN_2_BUTTONS). CHANGE_BAR đặt ô khi 31 <= id < 41 nhưng chỉ gỡ nháy khi 30 < id <= 40: hai dải khác nhau
// ở hai đầu, chỉ lộ với id không nguyên. Target:UpdateActionButton gọi ở mọi CHANGE_BAR main, trước mọi so sánh.
inline constexpr BarSpec kMainMenuBar2Spec = {
    .name = "MainMenuBar_2",
    .flash_infix = "_Button",
    .first_id = 31,
    .count = 10,
    .set_range = {.low = 31.0, .is_low_closed = true, .high = 41.0, .is_high_closed = false},
    .seen_range = {.low = 30.0, .is_low_closed = false, .high = 40.0, .is_high_closed = true},
    .is_refresh_always = true,
    .uninstall_event = "UNINSTALL_CHAT_ACTION_BAR2",
    .uninstall_level = 3,
    .forward = "FunctionBarRight",
    .has_masks = true,
};

// MainMenuBar_2_PreLoad: chín sự kiện; CHAT_ADJUST_MOVE_CTL, ACTION_UPDATE và UI_COMMAND đăng ký cờ false (thanh ẩn thì
// không nhận).
inline constexpr std::array<EventSub, 9> kMainMenuBar2Events = {{
    {.name = "OPEN_MENUBAR_2", .is_always = true},
    {.name = "CHANGE_BAR", .is_always = true},
    {.name = "CHAT_ADJUST_MOVE_CTL", .is_always = false},
    {.name = "ACTION_UPDATE", .is_always = false},
    {.name = "UNINSTALL_CHAT_ACTION_BAR2", .is_always = true},
    {.name = "CLEAR_CHAT_ACTION_BAR", .is_always = true},
    {.name = "FLASH_COMBOSKILL", .is_always = true},
    {.name = "UI_COMMAND", .is_always = false},
    {.name = "HIDE_THIS_UI", .is_always = true},
}};

[[nodiscard]] inline ActionBar make_main_menu_bar_2() {
    return make_action_bar(kMainMenuBar2Spec);
}

// MainMenuBar_2_OnEvent: một sự kiện đã đăng ký. OPEN_MENUBAR_2 với arg0 "1" khi không ở cảnh TLCJ hiện thanh và chạy hoạt
// ảnh mười ô, còn lại giấu. UI_COMMAND với arg0 "20130527" mở lớp hướng dẫn quanh ô vừa được đặt vật phẩm.
void on_main_menu_bar_2_event(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls);

// MainMenuBar_2_Clicked(id): như ô của các thanh kia, rồi nếu lớp hướng dẫn đang mở quanh thanh này (g_IsShowDrawing)
// thì đánh dấu đã đóng, và đóng hẳn khi chủ lớp hướng dẫn chính là MainMenuBar_2. Chỉ khi can_do; id ngoài dải là lỗi
// script ngay ở DoAction nên không tới phần đóng.
void press_main_menu_bar_2(ActionBar& bar, std::int32_t id, bool can_do, const BarFacts& facts, std::vector<Call>& calls);

} // namespace game::ui::panel
