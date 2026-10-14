#include "ui/panel/start.hpp"

#include "ui/panel/deck.hpp"

#include <array>
#include <string_view>

namespace game::ui::panel {
namespace {

// Gốc hiện ở PLAYER_ENTERING_WORLD và SCENE_TRANSED. Các thanh phụ (MainMenuBar_2, _3, _4), thanh action
// bên phải (FunctionBarRight, _2; nhóm ActionBars tự quyết hiện hay ẩn), khung mục tiêu, khung buff và thanh thi
// triển chỉ hiện khi sự kiện riêng của chúng tới.
constexpr std::array<std::string_view, 5> kRoots = {
    "PlayerFrame",
    "MiniMap_Frame",
    "MainMenuBar",
    "Chat_Frame",
    "AutoAttack_Button_Frame",
};

// Nút tự chiến đấu chỉ có ở client 2026 và script của nó đã mã hoá: hiện nút "tự chiến đấu", giấu
// nút "đang tự chiến đấu" nằm chồng lên nó là suy từ layout (docs/NGHI-NGO.md mục 15).
constexpr std::string_view kAutoAttackOn = "AutoAttack_Button_Frame_Button";

// Cửa sổ con mà OnLoad của script gốc giấu, cùng những nút nháy và thanh kinh nghiệm nhân đôi chỉ
// hiện khi máy chủ báo. Dấu đội trưởng do bảng khung nhân vật quyết định (player_frame.hpp).
constexpr std::array<std::string_view, 18> kHidden = {
    "PlayerFrame_UpdateBtnFlash",
    "MiniMap_OpenButtons",
    "MiniMap_EquipEndurance",
    "MiniMap_Fangchengmi_Btn",
    "MiniMap_XinShouNew",
    "MainMenuBar_MainMenuBar_Off",
    "Button_ConfraternityPK_Ani",
    "Button_GuildBattleScoreFlash",
    "Button_GuildBattleScore",
    "MainMenuBar_Button_junior_Flash",
    "MainMenuBar_Button_senior_Flash",
    "MainMenuBar_Button_Peak_DoubleEXP2_TimeBK",
    "MainMenuBar_Doub",
    "MainMenuBar_EXP3",
    "MainMenuBar_DoubleExp_Flash",
    "Chat_ChatSpeaker_StarWindow",
    "Chat_ChatSpeaker_StarWindow2",
    "Chat_Frame_FenpingFrame",
};

// Ô kỹ năng của trang 2, trang 3 (11..30) và hàng biến thân (51..60) nằm chồng lên mười ô của
// trang 1; script gốc chỉ hiện trang đang chọn.
constexpr std::array<std::string_view, 30> kOtherPages = {
    "Button_Action11",
    "Button_Action12",
    "Button_Action13",
    "Button_Action14",
    "Button_Action15",
    "Button_Action16",
    "Button_Action17",
    "Button_Action18",
    "Button_Action19",
    "Button_Action20",
    "Button_Action21",
    "Button_Action22",
    "Button_Action23",
    "Button_Action24",
    "Button_Action25",
    "Button_Action26",
    "Button_Action27",
    "Button_Action28",
    "Button_Action29",
    "Button_Action30",
    "Button_Action51",
    "Button_Action52",
    "Button_Action53",
    "Button_Action54",
    "Button_Action55",
    "Button_Action56",
    "Button_Action57",
    "Button_Action58",
    "Button_Action59",
    "Button_Action60",
};

} // namespace

void show_start(Deck& deck) {
    for (const std::string_view root : kRoots)
        deck.show(root);
    for (const std::string_view window : kHidden)
        deck.hide(window);
    for (const std::string_view window : kOtherPages)
        deck.hide(window);
    deck.hide(kAutoAttackOn);
}

} // namespace game::ui::panel
