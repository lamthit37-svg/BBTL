#include "ui/panel/desk.hpp"

#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <optional>
#include <ranges>
#include <span>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";
constexpr std::string_view kBindTail = "_Bind";
constexpr std::string_view kShelfHead = "YuanbaoShop_Button0";
constexpr std::string_view kTabHead = "YuanbaoShop_Button";

// Một bảng của bàn: ô thứ hạng của nó trong Desk và ba cửa sổ của layout.
struct BoardRow {
    Board board = Board::kCharacter;
    std::uint32_t Desk::* rank = nullptr;
    std::string_view root;
    std::string_view opener;
    std::string_view closer;
};

constexpr std::array<BoardRow, 18> kRows{{
    {.board = Board::kCharacter,
        .rank = &Desk::character,
        .root = "SelfEquip_Frame",
        .opener = "Button_Character",
        .closer = "SelfEquip_Close"},
    {.board = Board::kBag,
        .rank = &Desk::bag,
        .root = "Packet_Frame",
        .opener = "Button_Pack",
        .closer = "Packet_Close"},
    {.board = Board::kQuest,
        .rank = &Desk::quest,
        .root = "QuestLog_Frame",
        .opener = "Button_Mission",
        .closer = "QuestLog_Close"},
    {.board = Board::kShop,
        .rank = &Desk::shop,
        .root = "YuanbaoShop_Frame",
        .opener = "MiniMap_Yuanbao",
        .closer = "YuanbaoShop_Close"},
    {.board = Board::kSystem,
        .rank = &Desk::system,
        .root = "Operation_Frame",
        .opener = "Button_System",
        .closer = "Operation_Frame_Close"},
    {.board = Board::kView,
        .rank = &Desk::view,
        .root = "ViewSetup_Frame",
        .opener = "Operation_System",
        .closer = "ViewSetup_Close"},
    {.board = Board::kSound,
        .rank = &Desk::sound,
        .root = "SoundSetup_Frame",
        .opener = "Operation_Sound",
        .closer = "SoundSetup_Close"},
    {.board = Board::kGame,
        .rank = &Desk::game,
        .root = "GameSetup_Frame",
        .opener = "Operation_Geme",
        .closer = "GameSetup_Close"},
    {.board = Board::kKeys,
        .rank = &Desk::keys,
        .root = "AcceSetup_Frame",
        .opener = "Operation_Acce_Custom",
        .closer = "AcceSetup_Close"},
    {.board = Board::kCommon,
        .rank = &Desk::common_skill,
        .root = "CommonSkill_Frame",
        .opener = "CommonSkill_CommonlySkill",
        .closer = "CommonSkill_Close"},
    {.board = Board::kAction,
        .rank = &Desk::action_skill,
        .root = "ActionSkill_Frame",
        .opener = "ActionSkill_ActionSkill",
        .closer = "ActionSkill_Close"},
    {.board = Board::kLife,
        .rank = &Desk::life_skill,
        .root = "LifeSkill_Frame",
        .opener = "LifeSkill_LifeSkill",
        .closer = "LifeSkill_Close"},
    {.board = Board::kZhenfa,
        .rank = &Desk::zhenfa_skill,
        .root = "ZhenfaSkill_Frame",
        .opener = "ZhenfaSkill_ZhenfaSkill",
        .closer = "ZhenfaSkill_Close"},
    {.board = Board::kAuto,
        .rank = &Desk::auto_skill,
        .root = "AutoAttackSkill_Frame",
        .opener = "AutoAttackSkill_AutoAttack",
        .closer = "AutoAttackSkill_Close"},
    {.board = Board::kSect,
        .rank = &Desk::sect_skill,
        .root = "ZongMenSkill_Frame",
        .opener = "ZongMenSkill_ZongMenSkill",
        .closer = "ZongMenSkill_Close"},
    {.board = Board::kPet, .rank = &Desk::pet, .root = "Pet_Frame", .opener = "Button_Pet", .closer = "Pet_Close"},
    {.board = Board::kFriend,
        .rank = &Desk::contacts,
        .root = "Friend_Frame",
        .opener = "Button_Friend",
        .closer = "Friend_Close"},
    {.board = Board::kTeam, .rank = &Desk::team, .root = "Team_Frame", .opener = "Button_Team", .closer = "Team_Close"},
}};

// Nút thẻ trong từng trang cài đặt, và bản WeGame của menu hệ thống.
struct Door {
    std::string_view window;
    Board board = Board::kView;
};

constexpr std::array<Door, 20> kDoors{{
    {.window = "Operation_WeGame_System", .board = Board::kView},
    {.window = "Operation_WeGame_Sound", .board = Board::kSound},
    {.window = "Operation_WeGame_Geme", .board = Board::kGame},
    {.window = "Operation_WeGame_Acce_Custom", .board = Board::kKeys},
    {.window = "ViewSetup_MenuBox_ViewSetup", .board = Board::kView},
    {.window = "ViewSetup_MenuBox_SoundSetup", .board = Board::kSound},
    {.window = "ViewSetup_MenuBox_GameSetup", .board = Board::kGame},
    {.window = "ViewSetup_MenuBox_AcceSetup", .board = Board::kKeys},
    {.window = "SoundSetup_MenuBox_ViewSetup", .board = Board::kView},
    {.window = "SoundSetup_MenuBox_SoundSetup", .board = Board::kSound},
    {.window = "SoundSetup_MenuBox_GameSetup", .board = Board::kGame},
    {.window = "SoundSetup_MenuBox_AcceSetup", .board = Board::kKeys},
    {.window = "GameSetup_MenuBox_ViewSetup", .board = Board::kView},
    {.window = "GameSetup_MenuBox_SoundSetup", .board = Board::kSound},
    {.window = "GameSetup_MenuBox_GameSetup", .board = Board::kGame},
    {.window = "GameSetup_MenuBox_AcceSetup", .board = Board::kKeys},
    {.window = "AcceSetup_MenuBox_ViewSetup", .board = Board::kView},
    {.window = "AcceSetup_MenuBox_SoundSetup", .board = Board::kSound},
    {.window = "AcceSetup_MenuBox_GameSetup", .board = Board::kGame},
    {.window = "AcceSetup_MenuBox_AcceSetup", .board = Board::kKeys},
}};

// Sáu thẻ của một khung sách kỹ năng, cùng thứ tự với nhãn.
struct SkillFace {
    Board board = Board::kCommon;
    std::array<std::string_view, 6> tabs{};
};

constexpr std::array<SkillFace, 6> kSkillFaces{{
    {.board = Board::kCommon,
        .tabs = {"CommonSkill_CommonlySkill", "CommonSkill_ActionSkill", "CommonSkill_LifeSkill",
            "CommonSkill_ZhenfaSkill", "CommonSkill_AutoAttack", "CommonSkill_ZongMenSkill"}},
    {.board = Board::kAction,
        .tabs = {"ActionSkill_CommonlySkill", "ActionSkill_ActionSkill", "ActionSkill_LifeSkill",
            "ActionSkill_ZhenfaSkill", "ActionSkill_AutoAttack", "ActionSkill_ZongMenSkill"}},
    {.board = Board::kLife,
        .tabs = {"LifeSkill_CommonlySkill", "LifeSkill_ActionSkill", "LifeSkill_LifeSkill", "LifeSkill_ZhenfaSkill",
            "LifeSkill_AutoAttack", "LifeSkill_ZongMenSkill"}},
    {.board = Board::kZhenfa,
        .tabs = {"ZhenfaSkill_CommonlySkill", "ZhenfaSkill_ActionSkill", "ZhenfaSkill_LifeSkill",
            "ZhenfaSkill_ZhenfaSkill", "ZhenfaSkill_AutoAttack", "ZhenfaSkill_ZongMenSkill"}},
    {.board = Board::kAuto,
        .tabs = {"AutoAttackSkill_CommonlySkill", "AutoAttackSkill_ActionSkill", "AutoAttackSkill_LifeSkill",
            "AutoAttackSkill_ZhenfaSkill", "AutoAttackSkill_AutoAttack", "AutoAttackSkill_ZongMenSkill"}},
    {.board = Board::kSect,
        .tabs = {"ZongMenSkill_CommonlySkill", "ZongMenSkill_ActionSkill", "ZongMenSkill_LifeSkill",
            "ZongMenSkill_ZhenfaSkill", "ZongMenSkill_AutoAttack", "ZongMenSkill_ZongMenSkill"}},
}};

// Nhãn thẻ, như ZhenfaSkill_SetTabColor: màu rồi khoá từ điển. Đang chọn thêm #Y.
// Thứ tự theo cửa sổ Commonly, Action, Life, Zhenfa, Auto, ZongMen.
constexpr std::array<std::string_view, 6> kSkillKeys = {
    "#{INTERFACE_XML_494}",
    "#{INTERFACE_XML_448}",
    "#{INTERFACE_XML_635}",
    "#{JBGXW_150526_215}",
    "#{ZDZD_200724_08}",
    "#{ZMTF_230628_20}",
};
constexpr std::string_view kSkillOn = "#e010101#Y";
constexpr std::string_view kSkillOff = "#e010101";

// Thẻ tiền của thương thành, cùng số với ShopTabIdx.
struct MoneyButton {
    std::string_view window;
    std::uint8_t money = 0;
};

constexpr std::array<MoneyButton, 6> kMoneyButtons{{
    {.window = "YuanbaoShop_Yuanbao", .money = 0},
    {.window = "YuanbaoShop_Gongzi", .money = 1},
    {.window = "YuanbaoShop_Fanquan", .money = 2},
    {.window = "YuanbaoShop_XuanShop", .money = 3},
    {.window = "YuanbaoShop_VIP", .money = 4},
    {.window = "YuanbaoShop_Lijin", .money = 5},
}};

constexpr std::array<std::string_view, 8> kYuanbaoTabs = {
    "YuanbaoShop_Button1",
    "YuanbaoShop_Button2",
    "YuanbaoShop_Button3",
    "YuanbaoShop_Button4",
    "YuanbaoShop_Button5",
    "YuanbaoShop_Button6",
    "YuanbaoShop_Button7",
    "YuanbaoShop_Button8",
};
constexpr std::array<std::string_view, 8> kYuanbaoShelves = {
    "YuanbaoShop_Button01",
    "YuanbaoShop_Button02",
    "YuanbaoShop_Button03",
    "YuanbaoShop_Button04",
    "YuanbaoShop_Button05",
    "YuanbaoShop_Button06",
    "YuanbaoShop_Button07",
    "YuanbaoShop_Button08",
};
constexpr std::array<std::string_view, 8> kBindTabs = {
    "YuanbaoShop_Button1_Bind",
    "YuanbaoShop_Button2_Bind",
    "YuanbaoShop_Button3_Bind",
    "YuanbaoShop_Button4_Bind",
    "YuanbaoShop_Button5_Bind",
    "YuanbaoShop_Button6_Bind",
    "YuanbaoShop_Button7_Bind",
    "YuanbaoShop_Button8_Bind",
};
constexpr std::array<std::string_view, 8> kBindShelfButtons = {
    "YuanbaoShop_Button01_Bind",
    "YuanbaoShop_Button02_Bind",
    "YuanbaoShop_Button03_Bind",
    "YuanbaoShop_Button04_Bind",
    "YuanbaoShop_Button05_Bind",
    "YuanbaoShop_Button06_Bind",
    "YuanbaoShop_Button07_Bind",
    "YuanbaoShop_Button08_Bind",
};

// Kệ của SHOP_LIST_A. Ô trống là nút script giấu.
constexpr std::array<std::string_view, 8> kYuan1 = {
    "#{YBSD_081225_019}",
    "#{YBSD_081225_020}",
    "#{YBSD_081225_021}",
    "",
    "",
    "",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kYuan2 = {
    "#{YBSD_081225_023}",
    "#{YBSDTZ_130503_01}",
    "#{YBSDTZ_130503_02}",
    "#{YBSD_081225_024}",
    "#{YBSD_081225_025}",
    "#{YBSD_081225_026}",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kYuan3 = {
    "#{YBSD_081225_027}",
    "#{YBSD_081225_028}",
    "#{YBSD_081225_029}",
    "#{YBSD_081225_030}",
    "",
    "",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kYuan4 = {
    "#{YBSD_081225_091}",
    "#{YBSD_XML_3}",
    "#{YBSD_081225_031}",
    "#{YBSD_081225_032}",
    "",
    "",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kYuan5 = {
    "#{YBSD_XML_1}",
    "#{YBSD_XML_2}",
    "#{YBSD_081225_034}",
    "#{YBSD_081225_035}",
    "#{YBSD_081225_036}",
    "#{YBSD_081225_037}",
    "#{YBSD_90624_1}",
    "#{YBSD_171026_102}",
};
constexpr std::array<std::string_view, 8> kYuan6 = {
    "#{YBSD_081225_038}",
    "#{YBSD_081225_039}",
    "#{YBSD_XML_5}",
    "#{YBSD_081225_040}",
    "#{YBSD_081225_041}",
    "",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kYuan7 = {
    "#{YBSD_081225_042}",
    "#{YBSD_XML_4}",
    "#{YBSD_XML_6}",
    "#{YBSD_XML_7}",
    "",
    "",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kYuan8 = {
    "#{YBSD_081225_102}",
    "#{YBSD_081225_096}",
    "#{YBSD_081225_046}",
    "#{YBSD_081225_047}",
    "#{YBSD_081225_048}",
    "#{YBSD_081225_049}",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kBind1 = {"#{YBSD_081225_019}", "", "", "", "", "", "", ""};
constexpr std::array<std::string_view, 8> kBind2 = {"#{YBSD_081225_026}", "", "", "", "", "", "", ""};
constexpr std::array<std::string_view, 8> kBind3 = {"#{YBSD_081225_030}", "", "", "", "", "", "", ""};
constexpr std::array<std::string_view, 8> kBind4 = {
    "#{YBSD_081225_091}",
    "#{YBSD_081225_031}",
    "#{YBSD_XML_8}",
    "#{YBSD_XML_9}",
    "#{SSXDW_140819_75}",
    "#{YBSD_XML_10}",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kGift1 = {"#{YBSD_081225_019}", "", "", "", "", "", "", ""};
constexpr std::array<std::string_view, 8> kGift2 = {"#{YBSD_XML_2}", "#{YBSD_081225_037}", "", "", "", "", "", ""};
constexpr std::array<std::string_view, 8> kVipShelves = {
    "#{FFSDGZ_120615_07}",
    "#{FFSDGZ_120615_08}",
    "",
    "",
    "",
    "",
    "",
    "",
};
constexpr std::array<std::string_view, 8> kNoShelves{};

constexpr std::array<std::string_view, 6> kFriendPages = {
    "Friend_List_Page1",
    "Friend_List_Page2",
    "Friend_List_Page3",
    "Friend_List_Page4",
    "Friend_List_Page5",
    "Friend_List_Page6",
};

// Khung nút của tổ đội khi người chơi chưa có đội: chỉ còn nút tự lập đội.
constexpr std::array<std::string_view, 10> kTeamHidden = {
    "Team_Button_Frame0",
    "Team_Button_Frame1",
    "Team_Button_Frame2",
    "Team_Button_Frame3",
    "Team_Button_Frame4",
    "Team_Button_Frame5",
    "Team_Button_Frame7",
    "Team_Button_Frame8",
    "Team_Follow_Button",
    "Team_AbortTeamFollow_Button",
};
constexpr std::array<std::string_view, 6> kTeamNames = {
    "Team_PlayerInfo1_Name",
    "Team_PlayerInfo2_Name",
    "Team_PlayerInfo3_Name",
    "Team_PlayerInfo4_Name",
    "Team_PlayerInfo5_Name",
    "Team_PlayerInfo6_Name",
};

// Dòng của một bảng. Mọi giá trị của Board đều có dòng; giá trị ngoài enum thì lấy dòng đầu.
[[nodiscard]] const BoardRow& row_of(Board board) noexcept {
    const auto found = std::ranges::find(kRows, board, &BoardRow::board);
    return found == kRows.end() ? kRows.front() : *found;
}

[[nodiscard]] bool is_setup(Board board) noexcept {
    if (board == Board::kView) return true;
    if (board == Board::kSound) return true;
    if (board == Board::kGame) return true;
    return board == Board::kKeys;
}

[[nodiscard]] bool skill_open(const Desk& desk) noexcept {
    if (is_open(desk, Board::kCommon)) return true;
    if (is_open(desk, Board::kAction)) return true;
    if (is_open(desk, Board::kLife)) return true;
    if (is_open(desk, Board::kZhenfa)) return true;
    if (is_open(desk, Board::kAuto)) return true;
    return is_open(desk, Board::kSect);
}

void close_setups(Desk& desk) noexcept {
    close_board(desk, Board::kView);
    close_board(desk, Board::kSound);
    close_board(desk, Board::kGame);
    close_board(desk, Board::kKeys);
}

void close_skills(Desk& desk) noexcept {
    close_board(desk, Board::kCommon);
    close_board(desk, Board::kAction);
    close_board(desk, Board::kLife);
    close_board(desk, Board::kZhenfa);
    close_board(desk, Board::kAuto);
    close_board(desk, Board::kSect);
}

void show_board(Desk& desk, Board board) noexcept {
    if (is_open(desk, board)) return;
    ++desk.last;
    desk.*(row_of(board).rank) = desk.last;
}

// Trang cài đặt luôn hiện và giấu các trang kia cùng menu. Bảng khác thì đảo.
void admit(Desk& desk, Board board) noexcept {
    if (is_setup(board)) {
        close_board(desk, Board::kSystem);
        close_setups(desk);
        show_board(desk, board);
        return;
    }
    if (board == Board::kSystem) close_setups(desk);
    toggle_board(desk, board);
}

void press_skills(Desk& desk) noexcept {
    if (skill_open(desk)) {
        close_skills(desk);
        return;
    }
    show_board(desk, Board::kCommon);
}

// Trang môn phái cần đã bái sư. Tự động và tông môn cần số chưa đo nên không mở.
void admit_skill(Desk& desk, Board board, PlayFacts facts) noexcept {
    if (board == Board::kAction && facts.sect == hero::Sect::kNone) {
        desk.notice = Notice::kNoSect;
        return;
    }
    if (board == Board::kAuto) return;
    if (board == Board::kSect) return;
    close_skills(desk);
    show_board(desk, board);
}

// Hậu tố thẻ quyết định trang mở, không phải khung đang chứa nút.
struct SkillSuffix {
    std::string_view suffix;
    Board board = Board::kCommon;
};

constexpr std::array<SkillSuffix, 6> kSkillSuffixes{{
    {.suffix = "_CommonlySkill", .board = Board::kCommon},
    {.suffix = "_ActionSkill", .board = Board::kAction},
    {.suffix = "_LifeSkill", .board = Board::kLife},
    {.suffix = "_ZhenfaSkill", .board = Board::kZhenfa},
    {.suffix = "_AutoAttack", .board = Board::kAuto},
    {.suffix = "_ZongMenSkill", .board = Board::kSect},
}};

[[nodiscard]] bool is_skill_tab(std::string_view window) noexcept {
    const auto holds = [window](const SkillFace& face) { return std::ranges::contains(face.tabs, window); };
    return std::ranges::find_if(kSkillFaces, holds) != kSkillFaces.end();
}

[[nodiscard]] std::optional<Board> skill_board(std::string_view window) noexcept {
    if (!is_skill_tab(window)) return std::nullopt;
    const auto matches = [window](const SkillSuffix& item) { return window.ends_with(item.suffix); };
    const auto found = std::ranges::find_if(kSkillSuffixes, matches);
    if (found == kSkillSuffixes.end()) return std::nullopt;
    return found->board;
}

[[nodiscard]] bool is_digit(char digit) noexcept {
    return digit >= '0' && digit <= '9';
}

[[nodiscard]] std::optional<std::uint8_t> digits_of(std::string_view tail) noexcept {
    if (tail.empty() || tail.size() > 2) return std::nullopt;
    if (!std::ranges::all_of(tail, is_digit)) return std::nullopt;
    unsigned value = 0;
    for (const char digit : tail)
        value = value * 10U + static_cast<unsigned>(digit - '0');
    if (value < 1 || value > 8) return std::nullopt;
    return static_cast<std::uint8_t>(value);
}

[[nodiscard]] std::optional<std::uint8_t> money_of(std::string_view window) noexcept {
    const auto found = std::ranges::find(kMoneyButtons, window, &MoneyButton::window);
    if (found == kMoneyButtons.end()) return std::nullopt;
    return found->money;
}

[[nodiscard]] std::string_view strip_bind(std::string_view window) noexcept {
    if (!window.ends_with(kBindTail)) return window;
    return window.substr(0, window.size() - kBindTail.size());
}

[[nodiscard]] bool press_shelf(Desk& desk, std::string_view bare) noexcept {
    if (!bare.starts_with(kShelfHead)) return false;
    const auto index = digits_of(bare.substr(kShelfHead.size()));
    if (!index) return false;
    desk.shop_shelf = *index;
    return true;
}

[[nodiscard]] bool press_tab(Desk& desk, std::string_view bare) noexcept {
    if (!bare.starts_with(kTabHead)) return false;
    const auto index = digits_of(bare.substr(kTabHead.size()));
    if (!index) return false;
    desk.shop_tab = *index;
    desk.shop_shelf = 1;
    return true;
}

[[nodiscard]] bool press_shop_button(Desk& desk, std::string_view window) noexcept {
    const bool is_bind = window.ends_with(kBindTail);
    if (is_bind != (desk.shop_money == 1)) return false;
    const std::string_view bare = strip_bind(window);
    if (press_shelf(desk, bare)) return true;
    return press_tab(desk, bare);
}

[[nodiscard]] bool press_shop(Desk& desk, std::string_view window) noexcept {
    if (const auto money = money_of(window)) {
        desk.shop_money = *money;
        desk.shop_tab = 1;
        desk.shop_shelf = 1;
        return true;
    }
    return press_shop_button(desk, window);
}

[[nodiscard]] bool press_friend_page(Desk& desk, std::string_view window) noexcept {
    constexpr std::string_view kHead = "Friend_List_Page";
    if (!window.starts_with(kHead)) return false;
    const auto index = digits_of(window.substr(kHead.size()));
    if (!index || *index > 6) return false;
    desk.friend_page = *index;
    return true;
}

void put(Deck& deck, std::string_view window, std::string_view name, std::string_view value) {
    const gui::Override said{.window = window, .name = name, .value = value};
    deck.set(said);
}

void paint_one_check(Deck& deck, std::string_view window, bool is_on) {
    put(deck, window, "Selected", is_on ? kTrue : kFalse);
}

[[nodiscard]] std::span<const std::string_view> yuanbao_row(std::uint8_t tab) noexcept {
    if (tab == 1) return kYuan1;
    if (tab == 2) return kYuan2;
    if (tab == 3) return kYuan3;
    if (tab == 4) return kYuan4;
    if (tab == 5) return kYuan5;
    if (tab == 6) return kYuan6;
    if (tab == 7) return kYuan7;
    if (tab == 8) return kYuan8;
    return kNoShelves;
}

[[nodiscard]] std::span<const std::string_view> bind_row(std::uint8_t tab) noexcept {
    if (tab == 1) return kBind1;
    if (tab == 2) return kBind2;
    if (tab == 3) return kBind3;
    if (tab == 4) return kBind4;
    return kNoShelves;
}

[[nodiscard]] std::span<const std::string_view> gift_row(std::uint8_t tab) noexcept {
    if (tab == 1) return kGift1;
    if (tab == 2) return kGift2;
    return kNoShelves;
}

[[nodiscard]] std::span<const std::string_view> shelf_keys(std::uint8_t money, std::uint8_t tab) noexcept {
    if (money == 1) return bind_row(tab);
    if (money == 2) return gift_row(tab);
    if (money == 4) return kVipShelves;
    if (money != 0) return kNoShelves;
    return yuanbao_row(tab);
}

[[nodiscard]] bool has_shelf(std::span<const std::string_view> keys) noexcept {
    const auto filled = [](std::string_view key) { return !key.empty(); };
    return std::ranges::any_of(keys, filled);
}

void paint_category(Deck& deck, std::string_view window, bool is_shown, bool is_on) {
    if (!is_shown) {
        deck.hide(window);
        return;
    }
    deck.reveal(window);
    paint_one_check(deck, window, is_on);
}

void paint_category_at(Deck& deck, std::string_view name, std::uint8_t money, std::uint8_t index, std::uint8_t tab) {
    const auto keys = shelf_keys(money, index);
    paint_category(deck, name, has_shelf(keys), index == tab);
}

void paint_categories(Deck& deck, std::span<const std::string_view> names, std::uint8_t money, std::uint8_t tab) {
    for (std::size_t i = 0; i < names.size(); ++i)
        paint_category_at(deck, names[i], money, static_cast<std::uint8_t>(i + 1), tab);
}

void paint_one_shelf(Deck& deck, std::string_view window, std::string_view key, bool is_on) {
    if (key.empty()) {
        deck.hide(window);
        return;
    }
    deck.reveal(window);
    put(deck, window, "Text", key);
    paint_one_check(deck, window, is_on);
}

struct ShelfSide {
    std::span<const std::string_view> windows;
    std::span<const std::string_view> keys;
};

void paint_shelf_row(Deck& deck, ShelfSide side, std::uint8_t chosen) {
    const std::size_t count = std::min(side.windows.size(), side.keys.size());
    for (std::size_t i = 0; i < count; ++i)
        paint_one_shelf(deck, side.windows[i], side.keys[i], i + 1U == chosen);
}

void paint_shelves(Deck& deck, std::span<const std::string_view> windows, const Desk& desk) {
    const auto keys = shelf_keys(desk.shop_money, desk.shop_tab);
    const ShelfSide side{.windows = windows, .keys = keys};
    paint_shelf_row(deck, side, desk.shop_shelf);
}

void paint_money(Deck& deck, std::uint8_t money) {
    for (const MoneyButton& button : kMoneyButtons)
        paint_one_check(deck, button.window, button.money == money);
}

void hide_shop_rows(Deck& deck, std::uint8_t money) {
    if (money != 0 && money != 2) deck.hide("YuanbaoShop_Bk1");
    if (money != 1) deck.hide("YuanbaoShop_Bk1_Bind");
    if (money != 1) deck.hide("YuanbaoShop_Bk2_Bind");
    if (money != 4) deck.hide("YuanbaoShop_Bk1_VIP");
    deck.hide("YuanbaoShop_Bk1_Fanquan");
    if (money == 3 || money == 5) deck.hide("YuanbaoShop_Bk2");
}

void hide_shop_pages(Deck& deck) {
    deck.hide("YuanbaoShop_UpPage");
    deck.hide("YuanbaoShop_DownPage");
    deck.hide("YuanbaoShop_CurrentlyPage");
}

void paint_shop_lists(Deck& deck, const Desk& desk) {
    if (desk.shop_money == 1) {
        paint_categories(deck, kBindTabs, desk.shop_money, desk.shop_tab);
        paint_shelves(deck, kBindShelfButtons, desk);
        return;
    }
    if (desk.shop_money == 4) {
        paint_shelves(deck, kYuanbaoShelves, desk);
        return;
    }
    if (desk.shop_money == 3 || desk.shop_money == 5) return;
    paint_categories(deck, kYuanbaoTabs, desk.shop_money, desk.shop_tab);
    paint_shelves(deck, kYuanbaoShelves, desk);
    if (desk.shop_money == 2) put(deck, "YuanbaoShop_Button2", "Text", "#{YBSD_081225_007}");
}

void paint_shop(Deck& deck, const Desk& desk) {
    if (!is_open(desk, Board::kShop)) return;
    paint_money(deck, desk.shop_money);
    hide_shop_rows(deck, desk.shop_money);
    paint_shop_lists(deck, desk);
    hide_shop_pages(deck);
    put(deck, "YuanbaoShop_MBuy", "Disabled", kTrue);
    put(deck, "YuanbaoShop_Gift", "Disabled", kTrue);
}

[[nodiscard]] const SkillFace* open_skill(const Desk& desk) noexcept {
    const auto is_shown = [&desk](const SkillFace& face) { return is_open(desk, face.board); };
    const auto found = std::ranges::find_if(kSkillFaces, is_shown);
    return found == kSkillFaces.end() ? nullptr : &*found;
}

[[nodiscard]] std::size_t skill_slot(Board board) noexcept {
    const auto same = [board](const SkillFace& face) { return face.board == board; };
    const auto found = std::ranges::find_if(kSkillFaces, same);
    if (found == kSkillFaces.end()) return 0;
    return static_cast<std::size_t>(found - kSkillFaces.begin());
}

void paint_skill_tab(Deck& deck, std::string_view window, std::size_t slot, std::size_t chosen) {
    const bool is_on = slot == chosen;
    std::string text(is_on ? kSkillOn : kSkillOff);
    text.append(kSkillKeys[slot]);
    put(deck, window, "Text", text);
    paint_one_check(deck, window, is_on);
}

void paint_skill_face(Deck& deck, const SkillFace& face, std::size_t chosen) {
    for (std::size_t slot = 0; slot < face.tabs.size(); ++slot)
        paint_skill_tab(deck, face.tabs[slot], slot, chosen);
}

void paint_skills(Deck& deck, const Desk& desk) {
    const SkillFace* face = open_skill(desk);
    if (face == nullptr) return;
    paint_skill_face(deck, *face, skill_slot(face->board));
}

void paint_friend(Deck& deck, const Desk& desk) {
    if (!is_open(desk, Board::kFriend)) return;
    for (std::size_t i = 0; i < kFriendPages.size(); ++i)
        paint_one_check(deck, kFriendPages[i], i + 1U == desk.friend_page);
}

void paint_team(Deck& deck, const Desk& desk) {
    if (!is_open(desk, Board::kTeam)) return;
    for (const std::string_view name : kTeamHidden)
        deck.hide(name);
    for (const std::string_view name : kTeamNames)
        put(deck, name, "Text", "");
    deck.reveal("Team_Button_Frame6");
    put(deck, "Team_Button_Frame6", "Text", "#{INTERFACE_XML_892}");
    put(deck, "Team_Name", "Text", "#{INTERFACE_XML_914}");
}

[[nodiscard]] std::string_view notice_text(Notice notice) noexcept {
    constexpr std::string_view kNoGuild = "#{GMGameInterface_Script_Guild_Not_Guild_Member}";
    constexpr std::string_view kNoSect = "#{YD_20080421_222}";
    if (notice == Notice::kNoGuild) return kNoGuild;
    if (notice == Notice::kNoSect) return kNoSect;
    return {};
}

void paint_notice(Deck& deck, const Desk& desk) {
    const std::string_view text = notice_text(desk.notice);
    if (text.empty()) return;
    deck.show("DebugListBox");
    put(deck, "DebugListBox_ListBox", "Text", text);
}

} // namespace

bool is_open(const Desk& desk, Board board) noexcept {
    return desk.*(row_of(board).rank) != 0;
}

void close_board(Desk& desk, Board board) noexcept {
    desk.*(row_of(board).rank) = 0;
}

void toggle_board(Desk& desk, Board board) noexcept {
    if (is_open(desk, board)) {
        close_board(desk, board);
        return;
    }
    ++desk.last;
    desk.*(row_of(board).rank) = desk.last;
}

void press_desk(Desk& desk, std::string_view window, PlayFacts facts) noexcept {
    if (press_shop(desk, window)) return;
    if (press_friend_page(desk, window)) return;
    if (window == "Button_Skills") {
        press_skills(desk);
        return;
    }
    if (window == "Button_Reputation") {
        desk.notice = Notice::kNoGuild;
        return;
    }
    if (const std::optional<Board> skill = skill_board(window)) {
        admit_skill(desk, *skill, facts);
        return;
    }
    const auto opened = std::ranges::find(kRows, window, &BoardRow::opener);
    if (opened != kRows.end()) {
        admit(desk, opened->board);
        return;
    }
    const auto door = std::ranges::find(kDoors, window, &Door::window);
    if (door != kDoors.end()) {
        admit(desk, door->board);
        return;
    }
    if (window == "Operation_BackGame" || window == "Operation_WeGame_BackGame") {
        close_board(desk, Board::kSystem);
        return;
    }
    const auto closed = std::ranges::find(kRows, window, &BoardRow::closer);
    if (closed != kRows.end()) close_board(desk, closed->board);
}

void paint_desk(Deck& deck, const Desk& desk) {
    const auto rank_of = [&desk](const BoardRow* row) noexcept { return desk.*(row->rank); };
    const auto is_shown = [&rank_of](const BoardRow* row) noexcept { return rank_of(row) != 0; };
    std::array<const BoardRow*, kRows.size()> order{};
    std::ranges::transform(kRows, order.begin(), [](const BoardRow& row) { return &row; });
    std::ranges::sort(order, {}, rank_of);
    for (const BoardRow* row : order | std::views::filter(is_shown))
        deck.show(row->root);
    paint_shop(deck, desk);
    paint_skills(deck, desk);
    paint_friend(deck, desk);
    paint_team(deck, desk);
    paint_notice(deck, desk);
}

} // namespace game::ui::panel
