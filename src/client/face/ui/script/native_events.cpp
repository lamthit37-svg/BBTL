// Sinh bằng TOOLS/port/luagen/gen_event_natives.py từ decompile của Game.exe 2026; không sửa tay (sửa bộ sinh rồi sinh lại).
// Hàm game mà thân chỉ đẩy một sự kiện giao diện qua CEventSystem (+0xe8: không đối số, +0xe0: số in %d, +0xd8: chuỗi hằng) rồi
// trả 0. Hàm có thêm bất cứ việc gì khác (kiểm đối số, đọc trạng thái, gọi đối tượng khác) được port tay ở native_*.cpp khác.
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <span>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

using lua::NativeResult;

enum class Arg : std::uint8_t { kNone, kNumber, kText };

struct Push {
    const char* table; // nullptr là hàm toàn cục
    const char* name;
    std::string_view event;
    Arg arg;
    std::int32_t number;
    std::string_view text;
};

constexpr std::array<Push, 94> kPushes = {{
    {.table = nullptr, .name = "AskEvaluateAndLevelup", .event = "OPEN_EVALUATE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140240db0
    {.table = nullptr, .name = "CloseFangDaohao", .event = "CLOSEDLG_FANGDAOHAO", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402554b0
    {.table = nullptr, .name = "CloseInputYuanbao", .event = "CLOSE_INPUT_YUANBAO", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140256b20
    {.table = nullptr, .name = "CloseTitleList", .event = "CLOSE_AGNAME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14023bd20
    {.table = nullptr, .name = "CountDown10Sec", .event = "COUNTDOWN_10SEC", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402492d0
    {.table = nullptr, .name = "FlashPacketButton", .event = "FLASH_PACKET_BUTTON", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140249220
    {.table = nullptr, .name = "LuaFnEquipUpstageAbandonResultConfirm", .event = "EUS_ABANDON_RESULT_CONFIRM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140287200
    {.table = nullptr, .name = "LuaFnOpenTargetXingZhen", .event = "OPEN_OTHER_XINGZHEN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140272ea0
    {.table = nullptr, .name = "Lua_ToggleFengyunlu", .event = "TOGGLE_FENGYUNLU", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402667c0
    {.table = nullptr, .name = "OpenAccountProtection", .event = "OPEN_SAFECENTER_ACCOUNTPROTECTION", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244030
    {.table = nullptr, .name = "OpenAutoSearch", .event = "OPEN_AUTOSEARCH", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243f40
    {.table = nullptr, .name = "OpenBugFeedBack", .event = "OPEN_BUGFEEDBACK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239b40
    {.table = nullptr, .name = "OpenHuoYueHaoLi", .event = "OPEN_HUOYUEHAOLI", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239b70
    {.table = nullptr, .name = "OpenLockUnlock", .event = "OPEN_SAFECENTER_LOCKUNLOCK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402440c0
    {.table = nullptr, .name = "OpenMobilePhone", .event = "OPEN_SAFECENTER_MOBILEPHONE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243fd0
    {.table = nullptr, .name = "OpenSafeCheck", .event = "OPEN_SAFECENTER_SAFECHECK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244090
    {.table = nullptr, .name = "OpenSafePattern", .event = "OPEN_SAFECENTER_SAFEPATTERN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243fa0
    {.table = nullptr, .name = "OpenSafeScore", .event = "OPEN_SAFECENTER_SAFESCORE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243f70
    {.table = nullptr, .name = "OpenSafeTime", .event = "OPEN_SAFECENTER_SAFETIME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244000
    {.table = nullptr, .name = "OpenSecKillList", .event = "OPEN_SECKILL_LIST", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140269160
    {.table = nullptr, .name = "OpenSecondPassword", .event = "OPEN_SAFECENTER_SECONDPASSWORD", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244060
    {.table = nullptr, .name = "OpenShouKaiKaUI", .event = "OPEN_SHOUKAIKA", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140238b50
    {.table = nullptr, .name = "OpenWeekHuoyuehaoli", .event = "OPEN_WEEKHUOYUEHAOLI", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239ba0
    {.table = nullptr, .name = "ToggleXuanShop", .event = "TOGGLE_XUANSHOP", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239a70
    {.table = nullptr, .name = "ToggleYuanbaoShop", .event = "TOGGLE_YUANBAOSHOP", .arg = Arg::kText, .number = 0, .text = "normal"}, // 0x1402399f0
    {.table = nullptr, .name = "Update_PartyFrame_Menu", .event = "ON_TEAM_UPDATE_PARTYFRAME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140241d70
    {.table = "Auction", .name = "CloseOnSaleWindow", .event = "CLOSE_ONSALE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a2a10
    {.table = "Auction", .name = "CloseUpItemWindow", .event = "CLOSE_UP_ITEM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a29e0
    {.table = "Auction", .name = "CloseUpPetWindow", .event = "CLOSE_UP_PET", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a29b0
    {.table = "Auction", .name = "OpenOnSaleWindow", .event = "OPEN_ONSALE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a2980
    {.table = "Auction", .name = "OpenUpPetWindow", .event = "OPEN_UP_PET", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a2920
    {.table = "CSongliaoWarData", .name = "CloseSongliaoWarMulti", .event = "SHOW_SONGLIAOWAR_SCORE_M", .arg = Arg::kNumber, .number = 0, .text = ""}, // 0x1403b5a20
    {.table = "CSongliaoWarData", .name = "OpenSongliaoWarMulti", .event = "SHOW_SONGLIAOWAR_SCORE_M", .arg = Arg::kNumber, .number = 1, .text = ""}, // 0x1403b5a50
    {.table = "City", .name = "ClosePhoenixPlainWarScoreMultiTable", .event = "SHOW_PHOENIXPLAINWAR_SCORE_M", .arg = Arg::kNumber, .number = 0, .text = ""}, // 0x140423eb0
    {.table = "City", .name = "OpenNewGuildWarDlg", .event = "NEW_BANGHUI_BHXZ_OPEN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140423dd0
    {.table = "City", .name = "OpenPhoenixPlainWarScoreMultiTable", .event = "SHOW_PHOENIXPLAINWAR_SCORE_M", .arg = Arg::kNumber, .number = 1, .text = ""}, // 0x140423e40
    {.table = "CommisionShop", .name = "CloseBuyConfrim", .event = "CONFIRM_COMMISION_BUY", .arg = Arg::kText, .number = 0, .text = "close"}, // 0x1402c5c20
    {.table = "CommisionShop", .name = "OnBuyConfrimed", .event = "COMMISION_BUY_CONFRIMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402c5c50
    {.table = "DataPool", .name = "OpenFenxianDlg", .event = "OPEN_FEN_XIAN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140304050
    {.table = "DataPool", .name = "ShowNormalWatch", .event = "OPEN_NORMAL_WATCH", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402f3770
    {.table = "DataPool", .name = "ToggleTrustFriendWindow", .event = "TOGGLE_TRUST_FRIEND_LIST", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402dc760
    {.table = "DataPool", .name = "UpdateCampaignListByTrack", .event = "UPDATE_CAMPAGIN_BY_TRACK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402d4220
    {.table = "DataPool", .name = "UpdateMissionTrack", .event = "UPDATE_MISSION_TRACK", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x1402d42d0
    {.table = "DataPool", .name = "UpdateQuestLogByTrack", .event = "UPDATE_QUESTLOG_BY_TRACK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402d41f0
    {.table = "DressEnchasing", .name = "Lua_DressTransferBindConfirmed", .event = "DRESS_TRANSFER_BIND_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403fdc10
    {.table = "DressEnchasing", .name = "Lua_FittingOnDressTransferOver", .event = "DRESS_TRANSFER_FITTING_HIDDEN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403fdbe0
    {.table = "Exchange", .name = "CloseExchangeInfo", .event = "CLOSE_EXCHAGE_INFO", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140336400
    {.table = "Friend", .name = "Close", .event = "TOGLE_FRIEND_INFO", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x1403398c0
    {.table = "Guild", .name = "ShowCityBuildIntroduce", .event = "OPEN_BUILD_INTRODUCE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140414d90
    {.table = "LifeAbility", .name = "ClosePetEquipEnhanceMsgBox", .event = "CLOSE_PETEQUIP_ENHANCE_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14034fb80
    {.table = "LifeAbility", .name = "CloseReIdentifyMsgBox", .event = "CLOSE_RE_IDENTIFY_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14034fc10
    {.table = "LifeAbility", .name = "CloseStrengthMsgBox", .event = "CLOSE_STRENGTH_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14034fb50
    {.table = "Match", .name = "CloseHuaShanGRMatchScoreMultiTable", .event = "SHOW_HUASHANGRMATCH_SCORE_M", .arg = Arg::kNumber, .number = 0, .text = ""}, // 0x1403ef870
    {.table = "Match", .name = "OpenHuaShanGRMatchScoreMultiTable", .event = "SHOW_HUASHANGRMATCH_SCORE_M", .arg = Arg::kNumber, .number = 1, .text = ""}, // 0x1403ef830
    {.table = "NpcShop", .name = "Close", .event = "CLOSE_BOOTH", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140359580
    {.table = "NpcShop", .name = "CloseConfirm", .event = "YUANBAO_BUY_ITEM_CONFIRM", .arg = Arg::kText, .number = 0, .text = "close"}, // 0x14035b930
    {.table = "Pet", .name = "ClosePetSkillStudyMsgBox", .event = "CLOSE_PETSKILLSTUDY_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037bfd0
    {.table = "Pet", .name = "CloseSignalPetProCreate", .event = "TEAM_PETCREATE_OPENED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037e600
    {.table = "Pet", .name = "CloseTeamPetProCreate", .event = "SIGNAL_PETCREATE_OPENED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037e5d0
    {.table = "Pet", .name = "ConfirmPetSkillStudy", .event = "CONFIRM_PETSKILLSTUDY", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037c000
    {.table = "Pet", .name = "Lua_LianHuaConfirmRet", .event = "PET_LIANHUA_CONFIRM_RET", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140380af0
    {.table = "Pet", .name = "Lua_NianShouHuanYuBindConfirm", .event = "NIANSHOU_HUANYU_BIND_CONFIRM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403821b0
    {.table = "Pet", .name = "Lua_NianShouHuanYuBindConfirmed", .event = "NIANSHOU_HUANYU_BIND_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140382210
    {.table = "Pet", .name = "Lua_NianShouHuanYuRareConfirmed", .event = "NIANSHOU_HUANYU_RARE_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403821e0
    {.table = "Pet", .name = "Lua_NianShouHuanYuUpBindConfirm", .event = "NIANSHOU_HUANYUUP_BIND_CONFIRM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403822c0
    {.table = "Pet", .name = "Lua_NianShouHuanYuUpBindConfirmed", .event = "NIANSHOU_HUANYUUP_BIND_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403822f0
    {.table = "Pet", .name = "Lua_OpenPetHuanLingUI", .event = "OPEN_PET_HUANLING_UI", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140381bf0
    {.table = "Pet", .name = "NotifyPetDlgClosed", .event = "CLOSE_PET_AGNAME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037bb60
    {.table = "Pet", .name = "OpenPetSkillStudyMsgBox", .event = "OPEN_PETSKILLSTUDY_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037bfa0
    {.table = "Pet", .name = "UpdatePetList", .event = "UPDATE_PET_LIST", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037e500
    {.table = "Player", .name = "ConfirmDismissTeam", .event = "CONFIRM_DISMISS_TEAM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140384e10
    {.table = "Player", .name = "OpenDismissTeamMsgbox", .event = "OPNE_DISMISS_TEAM_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140384de0
    {.table = "PlayerShop", .name = "CloseChangeTypeMsgBox", .event = "CLOSE_PS_CHANGETYPE_MSG", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14045a2e0
    {.table = "PlayerShop", .name = "CloseRecycleShop", .event = "CLOSE_RECYCLESHOP_MSG", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14045a3e0
    {.table = "PlayerShop", .name = "CloseShopMag", .event = "PS_CLOSE_SHOP_MAG", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140457d70
    {.table = "Raid", .name = "ConfirmShowAllSquad", .event = "RAID_SHOWALLSQUAD", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403a5c20
    {.table = "StallBuy", .name = "CloseStallMessage", .event = "CLOSE_STALL_MESSAGE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403baa40
    {.table = "StallSale", .name = "ConfirmRemoveStall", .event = "OPEN_REMOVE_STALL", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403bc3c0
    {.table = "StallSale", .name = "OpenPetList", .event = "OPEN_PET_LIST", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403be640
    {.table = "SuperTooltips", .name = "CloseCmpWindowMain", .event = "CLOSE_SP_CMP1", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1404b1090
    {.table = "SuperTooltips", .name = "CloseCmpWindowSub", .event = "CLOSE_SP_CMP2", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1404b10c0
    {.table = "SuperTooltips2", .name = "CloseCmp2WindowMain", .event = "CLOSE_SP2_CMP1", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1404afcb0
    {.table = "SuperTooltips2", .name = "CloseCmp2WindowSub", .event = "CLOSE_SP2_CMP2", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1404afce0
    {.table = "SystemSetup", .name = "GameSetup", .event = "TOGLE_GAMESETUP", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140460eb0
    {.table = "SystemSetup", .name = "OpenOptimize", .event = "OPEN_OPTIMIZE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1404682e0
    {.table = "SystemSetup", .name = "OpenOtherHuanLing", .event = "OPEN_OTHERHUANLING", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x1404682b0
    {.table = "SystemSetup", .name = "OpenOtherJingMai", .event = "OPEN_OTHERPLAYER_JINGMAI", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x140468200
    {.table = "SystemSetup", .name = "OpenOtherMiji", .event = "OPEN_OTHERPLAYER_MIJI", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x140468280
    {.table = "SystemSetup", .name = "OpenOtherWuhun", .event = "OPEN_OTHERPLAYER_WUHUN", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x1404681d0
    {.table = "SystemSetup", .name = "OpenSetup", .event = "TOGLE_SYSTEMFRAME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140460810
    {.table = "SystemSetup", .name = "SoundSetup", .event = "TOGLE_SOUNDSETUP", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140460870
    {.table = "SystemSetup", .name = "UISetup", .event = "TOGLE_UISETUP", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1404608a0
    {.table = "SystemSetup", .name = "ViewSetup", .event = "TOGLE_VIEWSETUP", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140460840
    {.table = "Talk", .name = "HideContexMenu4Speaker", .event = "HIDE_CONTEXMENU_SPEAKER", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14047d460
}};

// Một hàm Lua cho mỗi dòng của kPushes: lua_CFunction không mang dữ liệu đi kèm nên chỉ số dòng là tham số mẫu.
template <std::size_t Index>
NativeResult push_event(lua_State* lua) {
    constexpr const Push& push = kPushes.at(Index);
    Context& context = native::context_of(lua);
    switch (push.arg) {
    case Arg::kNone:
        context.push_event(push.event, std::span<const std::string_view>{});
        break;
    case Arg::kNumber: {
        // %d của gốc: tối đa 11 ký tự cho int32.
        std::array<char, 16> digits{};
        const std::format_to_n_result<char*> done = std::format_to_n(digits.data(), digits.size(), "{}", push.number);
        const std::array<std::string_view, 1> args = {std::string_view(digits.data(), static_cast<std::size_t>(done.size))};
        context.push_event(push.event, args);
        break;
    }
    case Arg::kText: {
        const std::array<std::string_view, 1> args = {push.text};
        context.push_event(push.event, args);
        break;
    }
    }
    return 0;
}

template <std::size_t... Index>
constexpr std::array<native::Entry, sizeof...(Index)> make_entries(std::index_sequence<Index...>) {
    return {{{.name = kPushes.at(Index).name, .function = &lua::adapt<push_event<Index>>}...}};
}

constexpr std::array kEntries = make_entries(std::make_index_sequence<kPushes.size()>{});

} // namespace

void register_events(lua_State* lua) {
    for (std::size_t index = 0; index < kPushes.size(); ++index) {
        const std::span<const native::Entry> entry(&kEntries.at(index), 1);
        if (kPushes.at(index).table == nullptr) {
            native::register_globals(lua, entry);
        } else {
            native::register_table(lua, kPushes.at(index).table, entry);
        }
    }
}

} // namespace game::ui::script
