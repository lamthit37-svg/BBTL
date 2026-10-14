// Thanh kỹ năng thú cưng (MainMenuBar_3): hai ô action của thanh kỹ năng thú cưng, mỗi ô có một cửa sổ
// hoạt ảnh "CoolDownEnd2" phủ lên. Hiện khi game báo thanh đổi và có ít nhất một action không rỗng.
// Nguồn: Interface/MainMenuBar_3/MainMenuBar_3.lua của client 2026 (7 hàm). Bản dịch từng hàm ghi vào
// Widgets đúng những lời gọi script làm; Test/Ui/ui_main_menu_bar_3_tests.cpp so trạng thái đó từng dòng
// với số vàng do script gốc chạy trên LuaPlus.dll (Test/golden/panel/main_menu_bar_3_pet.tsv, kịch bản
// TOOLS/port/oracle/main_menu_bar_3_pet.lua).
// Port 6/7 hàm; MainMenuBar_3_PreLoad -> kMainMenuBar3Events, MainMenuBar_3_OnLoad -> kPetButtons và
// kPetMasks, MainMenuBar_3_OnEvent -> on_main_menu_bar_3_event, MainMenuBar_3_Clicked ->
// press_pet_skill_button, MainMenuBar_3_PlayAnimate và MainMenuBar_3_ShowItems nằm trong .cpp.
// Khác gốc:
//  - MainMenuBar_3_AdjustMoveCtl: thân hàm gốc toàn là chú thích (không làm gì), nên bản port không có hàm
//    đó; nhánh CHAT_ADJUST_MOVE_CTL của OnEvent vẫn nhận sự kiện và không đổi gì, như bản gốc.
//  - Danh sách action của thanh (Pet:GetPetSkillBarItemCount, Pet:EnumPetSkillBarItem: vector action ở
//    Game.exe 0x14002bf90 và 0x14002bf00) do hệ thú cưng giữ; client chưa có hệ thú cưng, nên HUD đưa
//    PetSkillBar rỗng và thanh luôn ẩn. Mỗi phần tử mang id action (0 là action rỗng của mã gốc) và tên
//    icon do hệ action đổi.
//  - DoAction chỉ ghi lời nhờ (Ask::kDoAction); chưa có hệ action để thi triển.
#pragma once

#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Cửa sổ gốc của thanh (this của script).
inline constexpr std::string_view kMainMenuBar3Root = "MainMenuBar_3_Frame";

// MainMenuBar_3_PreLoad: ba sự kiện, đều nhận cả lúc thanh ẩn.
inline constexpr std::array<EventSub, 3> kMainMenuBar3Events = {{
    {.name = "CHANGE_PETSKILL_BAR", .is_always = true},
    {.name = "CHAT_ADJUST_MOVE_CTL", .is_always = true},
    {.name = "HIDE_THIS_UI", .is_always = true},
}};

// MainMenuBar_3_OnLoad: hai nút action (MAIN_3_BUTTONS) và hai cửa sổ hoạt ảnh phủ chúng (MAIN_3_ANIMATES),
// theo chỉ số 1..2 của script.
inline constexpr std::array<std::string_view, 2> kPetButtons = {"MainMenuBar_3_Button_Action1", "MainMenuBar_3_Button_Action2"};
inline constexpr std::array<std::string_view, 2> kPetMasks = {
    "MainMenuBar_3_Button_Action1_Mask", "MainMenuBar_3_Button_Action2_Mask"};

// Thanh kỹ năng thú cưng của game: các action theo thứ tự ô (Pet:EnumPetSkillBarItem(0..n-1)); id 0 là
// action rỗng. Span phải sống tới hết lời gọi.
using PetSkillBar = std::span<const ActionFace>;

// Trạng thái của thanh: các cửa sổ con script đã đụng tới và cờ hiện của chính nó (this:IsVisible()).
struct MainMenuBar3 {
    Widgets widgets;
    bool is_shown = false;
};

// MainMenuBar_3_OnEvent: một sự kiện đã đăng ký. pet_bar là điều Pet:GetPetSkillBarItemCount và
// Pet:EnumPetSkillBarItem trả lúc xử lý CHANGE_PETSKILL_BAR.
void on_main_menu_bar_3_event(MainMenuBar3& bar, const UiEvent& event, PetSkillBar pet_bar);

// MainMenuBar_3_Clicked(index) của nút index (1..2), qua cả Clicked lẫn RBClicked. can_do là
// DataPool:IsCanDoAction() lúc nhấn (can_do_action của can_do.hpp). Chỉ số ngoài 1..2 không ứng nút nào.
void press_pet_skill_button(const MainMenuBar3& bar, std::int32_t index, bool can_do, std::vector<Call>& calls);

// Chép trạng thái của thanh sang deck: hiện cửa sổ gốc khi this:IsVisible(), rồi các cửa sổ con.
void paint_main_menu_bar_3(Deck& deck, const MainMenuBar3& bar);

} // namespace game::ui::panel
