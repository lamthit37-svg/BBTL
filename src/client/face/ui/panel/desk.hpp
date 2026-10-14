// Bàn các bảng mở từ thanh menu và minimap. Nút đảo bảng của nó; nút đóng thì đóng. Trang cài
// đặt và trang sách kỹ năng thì hiện trang được chọn và đóng các trang cùng nhóm. Thương thành
// là YuanbaoShop. Menu hệ thống là Operation.
// Nguồn: MainMenuBar.lua, CommonSkill.lua, YuanbaoShop.lua, Operation.lua, TeamFrame.lua,
// Friend.lua, Pet.lua của client 2026 và Lua_ToggleSkillBook, Lua_ShowTeamInfoDlg,
// DataPool::OpenFriendList của client 2008.
// Khác gốc: hàng và giá do script 888902 gửi, chưa có trong cây nên ô giá trống; nút giao dịch
// khi không có lời mời gọi PrepearExchange, hàm đó chưa đo nên không mở khung; Về Đăng Nhập gọi
// ReturnServerLogin, chưa có đường từ màn chơi; thẻ tự động và tông môn cần mức cấp và
// Lua_CheckOpenTalent chưa đo, nhân vật vô phái không mở; diễn đàn chưa có URL WEB_TLLUNTAN.
#pragma once

#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/logon.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::ui::panel {

enum class Board : std::uint8_t {
    kCharacter,
    kBag,
    kQuest,
    kShop,
    kSystem,
    kView,
    kSound,
    kGame,
    kKeys,
    kCommon,
    kAction,
    kLife,
    kZhenfa,
    kAuto,
    kSect,
    kPet,
    kFriend,
    kTeam,
};

// Lời PushDebugMessage mà nút vừa bấm gọi, chờ HUD đẩy vào DebugListBox (take_notice). kNone là không có lời.
enum class Notice : std::uint8_t { kNone, kNoGuild, kNoSect };

// Môn phái của người đang chơi, cho thẻ võ công của sách kỹ năng. Vô phái không mở trang môn phái.
struct PlayFacts {
    hero::Sect sect = hero::Sect::kNone;
};

// Thứ hạng mở của từng bảng: 0 là đóng; số lớn hơn là mở sau và nằm trên.
struct Desk {
    std::uint32_t character = 0;
    std::uint32_t bag = 0;
    std::uint32_t quest = 0;
    std::uint32_t shop = 0;
    std::uint32_t system = 0;
    std::uint32_t view = 0;
    std::uint32_t sound = 0;
    std::uint32_t game = 0;
    std::uint32_t keys = 0;
    std::uint32_t common_skill = 0;
    std::uint32_t action_skill = 0;
    std::uint32_t life_skill = 0;
    std::uint32_t zhenfa_skill = 0;
    std::uint32_t auto_skill = 0;
    std::uint32_t sect_skill = 0;
    std::uint32_t pet = 0;
    std::uint32_t contacts = 0;
    std::uint32_t team = 0;
    // Thứ hạng đã phát gần nhất.
    std::uint32_t last = 0;
    // Thẻ tiền và kệ của thương thành. 0 là nguyên bảo; kệ và mục đếm từ 1.
    std::uint8_t shop_money = 0;
    std::uint8_t shop_tab = 1;
    std::uint8_t shop_shelf = 1;
    // Trang danh sách hảo hữu, 1..6.
    std::uint8_t friend_page = 1;
    Notice notice = Notice::kNone;
};

// Thoát game của bảng hệ thống. Cả hai bản classic và WeGame.
[[nodiscard]] inline bool is_quit_button(std::string_view window) noexcept {
    return window == "Operation_QuitGame" || window == "Operation_WeGame_QuitGame";
}

// Nút trợ giúp: Helper:GotoHelper của các bảng đã nối.
[[nodiscard]] inline bool is_help_button(std::string_view window) noexcept {
    constexpr std::array<std::string_view, 12> kHelp = {
        "Operation_Help",
        "Operation_WeGame_Help",
        "Operation_Frame_Help",
        "CommonSkill_Help",
        "ActionSkill_Help",
        "LifeSkill_Help",
        "ZhenfaSkill_Help",
        "AutoAttackSkill_Help",
        "ZongMenSkill_Help",
        "Pet_Help",
        "Friend_Help",
        "Team_Help",
    };
    return std::ranges::contains(kHelp, window);
}

// Việc một nút nhờ vòng cửa sổ: thoát, trợ giúp, diễn đàn. Nút khác thì không có việc.
[[nodiscard]] inline std::optional<LogonAction> menu_action(std::string_view window) noexcept {
    if (is_quit_button(window)) return LogonAction::kLeave;
    if (is_help_button(window)) return LogonAction::kOpenHelp;
    if (window == "Operation_BBS") return LogonAction::kOpenForum;
    return std::nullopt;
}

[[nodiscard]] bool is_open(const Desk& desk, Board board) noexcept;
// Đang hiện thì giấu, đang giấu thì hiện.
void toggle_board(Desk& desk, Board board) noexcept;
void close_board(Desk& desk, Board board) noexcept;
// Nút của thanh menu, thẻ trang và kệ thương thành. facts là môn phái đang chơi.
void press_desk(Desk& desk, std::string_view window, PlayFacts facts = {}) noexcept;
// Lời PushDebugMessage mà nút vừa bấm gọi (khoá "#{...}" của bảng chuỗi), rỗng khi không có; lấy xong thì xoá, để HUD đẩy
// đúng một lần sự kiện NEW_DEBUGMESSAGE cho DebugListBox.
[[nodiscard]] std::string_view take_notice(Desk& desk) noexcept;
// Kê gốc của các bảng đang mở theo thứ tự mở, rồi chữ của thẻ và kệ.
void paint_desk(Deck& deck, const Desk& desk);

} // namespace game::ui::panel
