// Sinh bằng TOOLS/port/luagen/gen_event_natives.py từ decompile của Game.exe 2026; không sửa tay (sửa bộ sinh rồi sinh lại).
// Hàm game mà thân chỉ đẩy một sự kiện giao diện qua CEventSystem (+0xe8: không đối số, +0xe0: số in %d, +0xd8: chuỗi hằng) rồi
// trả 0, có thể bọc phép kiểm khoá cảnh (IsInHell) và một đối số số lấy từ script. Hàm có thêm bất cứ việc gì khác (đọc trạng
// thái, gọi đối tượng khác) được port tay ở native_*.cpp khác.
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <span>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

using lua::NativeError;
using lua::NativeResult;

// kNumber và kText mang đối số hằng; kArgument lấy số từ đối số `argument` của script (số nghiêm, ép (int)).
enum class Arg : std::uint8_t { kNone, kNumber, kText, kArgument };

struct Push {
    const char* table; // nullptr là hàm toàn cục
    const char* name;
    std::string_view event;
    Arg arg;
    std::int32_t number;
    std::string_view text;
    bool hell_guard = false; // cảnh địa ngục (Facts::in_hell) thì không đẩy
    int argument = 0;
    const char* bad_argument = nullptr; // câu ném khi đối số không phải số; nullptr là bỏ qua im lặng
    bool check_first = false; // gốc kiểm (và ném) đối số trước khi kiểm khoá
};

constexpr std::array<Push, 163> kPushes = {{
    {.table = nullptr, .name = "AskEvaluateAndLevelup", .event = "OPEN_EVALUATE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140240db0
    {.table = nullptr, .name = "CloseFangDaohao", .event = "CLOSEDLG_FANGDAOHAO", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402554b0
    {.table = nullptr, .name = "CloseInputYuanbao", .event = "CLOSE_INPUT_YUANBAO", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140256b20
    {.table = nullptr, .name = "CloseTitleList", .event = "CLOSE_AGNAME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14023bd20
    {.table = nullptr, .name = "CountDown10Sec", .event = "COUNTDOWN_10SEC", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402492d0
    {.table = nullptr, .name = "FlashPacketButton", .event = "FLASH_PACKET_BUTTON", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140249220
    {.table = nullptr, .name = "LuaFnEquipUpstageAbandonResultConfirm", .event = "EUS_ABANDON_RESULT_CONFIRM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140287200
    {.table = nullptr, .name = "LuaFnOpenCangPin", .event = "OPEN_CANGPIN", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1, .bad_argument = "LUA:LuaFnOpenCangPin Param 1 Error", .check_first = true}, // 0x140273610
    {.table = nullptr, .name = "LuaFnOpenCangPinClassEffect", .event = "CANGPIN_SHOW_CLASS_EFFECT", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1, .bad_argument = "LUA:LuaFnOpenCangPinClassEffect Param 1 Error", .check_first = true}, // 0x140274e10
    {.table = nullptr, .name = "LuaFnOpenCangPinLevelUp", .event = "OPEN_CANGPIN_LEVELUP", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1, .bad_argument = "LUA:LuaFnOpenCangPinLevelUp Param 1 Error", .check_first = true}, // 0x140273690
    {.table = nullptr, .name = "LuaFnOpenCangPinMelt", .event = "OPEN_CANGPIN_MELT", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140273710
    {.table = nullptr, .name = "LuaFnOpenCangPinRankAllBuff", .event = "OPEN_CANGPIN_RANK_ALL_BUFF", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x1402734c0
    {.table = nullptr, .name = "LuaFnOpenCangPinSetEffect", .event = "CANGPIN_SHOW_SET_EFFECT", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1, .bad_argument = "LUA:LuaFnOpenCangPinSetEffect Param 1 Error", .check_first = true}, // 0x140274e90
    {.table = nullptr, .name = "LuaFnOpenOtherCangPin", .event = "OPEN_OTHER_CANGPIN", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140274dd0
    {.table = nullptr, .name = "LuaFnOpenSkillCardDetail", .event = "OPEN_SKILLCARD_DETAIL", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1, .bad_argument = "LUA:LuaFnOpenSkillCardDetail Param 1 Error", .check_first = true}, // 0x140272ed0
    {.table = nullptr, .name = "LuaFnOpenTargetXingZhen", .event = "OPEN_OTHER_XINGZHEN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140272ea0
    {.table = nullptr, .name = "LuaFnOpenXingZhenChip", .event = "OPEN_XINGZHEN_CHIP", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1, .bad_argument = "LUA:LuaFnOpenXingZhenChip Param1 Error", .check_first = true}, // 0x140272570
    {.table = nullptr, .name = "LuaFnOpenXingZhenSkill", .event = "OPEN_XINGZHEN_SKILL", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140272640
    {.table = nullptr, .name = "LuaFnOpenXingZhenUpgrade", .event = "OPEN_XINGZHEN_UPGRADE", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140272600
    {.table = nullptr, .name = "LuaFnSkillCardRecycleConfirm", .event = "SKILLCARD_RECYCLE_CONFIRM", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA:LuaFnSkillCardRecycleConfirm parameter 1 error"}, // 0x1402768b0
    {.table = nullptr, .name = "Lua_CloseFiveElementsWashConfirm", .event = "CLOSE_FIVE_ELEMENTS_WASH_COMFIRM", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x14026afc0
    {.table = nullptr, .name = "Lua_FiveElementsAutoWashConfirm", .event = "FIVE_ELEMENTS_AUTOWASH_CONFIRM", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x14026b070
    {.table = nullptr, .name = "Lua_FiveElementsAutoWashStart", .event = "FIVE_ELEMENTS_AUTOWASH_START", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x14026b120
    {.table = nullptr, .name = "Lua_FiveElementsNotSwitchConfirm", .event = "FIVE_ELEMENTS_WASH_NOTSWITCH_CONFIRM", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1}, // 0x14026b0b0
    {.table = nullptr, .name = "Lua_OpenChatSymbol", .event = "OPEN_CHATSYMBOL", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x14023bd50
    {.table = nullptr, .name = "Lua_OpenFiveElementsPage", .event = "SELF_FIVE_ELEMENTS_OPEN", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140232a50
    {.table = nullptr, .name = "Lua_OpenOtherFiveElementsPage", .event = "TARGET_FIVE_ELEMENTS_OPEN", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140232a90
    {.table = nullptr, .name = "Lua_OpenVipZZEquipTransfer", .event = "ZHIZUN_EQUIP_VIP_TRANSFER", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x14026aee0
    {.table = nullptr, .name = "Lua_ToggleFengyunlu", .event = "TOGGLE_FENGYUNLU", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402667c0
    {.table = nullptr, .name = "Lua_ToggleGQHYChouJiangBuyTokens", .event = "GQHYCHOUJIANG_BUYTOKENS", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_ToggleGQHYChouJiangBuyTokens Param1 Error"}, // 0x140270120
    {.table = nullptr, .name = "Lua_ToggleRecruitDungeonMiniUI", .event = "RECRUIT_DUNGEON_UI_MINI_SHOW", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1}, // 0x14026aca0
    {.table = nullptr, .name = "Lua_ToggleSwearDungeonMiniUI", .event = "SWEAR_DUNGEON_UI_MINI_SHOW", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1}, // 0x14026ad80
    {.table = nullptr, .name = "Lua_ToggleSwearDungeonUI", .event = "SWEAR_DUNGEON_UI_SHOW", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1}, // 0x14026ad10
    {.table = nullptr, .name = "Lua_ToggleZNQBugTokens", .event = "TOGGLE_ZNQ_BUY_TOKENS", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_ToggleZNQBugTokens Param1 Error"}, // 0x14026f110
    {.table = nullptr, .name = "MailListClicked", .event = "MAILLIST_CLICKED", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA:MailListClicked Wrong Param 1"}, // 0x1402374f0
    {.table = nullptr, .name = "OpenAccountProtection", .event = "OPEN_SAFECENTER_ACCOUNTPROTECTION", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244030
    {.table = nullptr, .name = "OpenAutoSearch", .event = "OPEN_AUTOSEARCH", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243f40
    {.table = nullptr, .name = "OpenBugFeedBack", .event = "OPEN_BUGFEEDBACK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239b40
    {.table = nullptr, .name = "OpenEquip", .event = "OPEN_EQUIP", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1}, // 0x14023be90
    {.table = nullptr, .name = "OpenHuiGui", .event = "OPEN_HUIGUI", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenHuiGui Wrong Param"}, // 0x1402386f0
    {.table = nullptr, .name = "OpenHuoYueHaoLi", .event = "OPEN_HUOYUEHAOLI", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239b70
    {.table = nullptr, .name = "OpenLockUnlock", .event = "OPEN_SAFECENTER_LOCKUNLOCK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402440c0
    {.table = nullptr, .name = "OpenMobilePhone", .event = "OPEN_SAFECENTER_MOBILEPHONE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243fd0
    {.table = nullptr, .name = "OpenMonthlySign", .event = "OPEN_MONTHLYSIGN", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenMonthlySign Wrong Param"}, // 0x140238960
    {.table = nullptr, .name = "OpenMonthlySignSP", .event = "OPEN_MONTHLYSIGN_SP", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenMonthlySignSP Wrong Param"}, // 0x140238a80
    {.table = nullptr, .name = "OpenQianKunDai", .event = "OPEN_QIANKUNDAI", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenQianKunDai Wrong Param"}, // 0x140238690
    {.table = nullptr, .name = "OpenQianKunDaiSP", .event = "OPEN_QIANKUNDAI_SP", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenQianKunDaiSP Wrong Param"}, // 0x140238a20
    {.table = nullptr, .name = "OpenRidePage", .event = "OPEN_RIDE_PAGE", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x1402333d0
    {.table = nullptr, .name = "OpenSafeCheck", .event = "OPEN_SAFECENTER_SAFECHECK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244090
    {.table = nullptr, .name = "OpenSafePattern", .event = "OPEN_SAFECENTER_SAFEPATTERN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243fa0
    {.table = nullptr, .name = "OpenSafeScore", .event = "OPEN_SAFECENTER_SAFESCORE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140243f70
    {.table = nullptr, .name = "OpenSafeTime", .event = "OPEN_SAFECENTER_SAFETIME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244000
    {.table = nullptr, .name = "OpenSecKillList", .event = "OPEN_SECKILL_LIST", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140269160
    {.table = nullptr, .name = "OpenSecondPassword", .event = "OPEN_SAFECENTER_SECONDPASSWORD", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140244060
    {.table = nullptr, .name = "OpenShouKaiKaUI", .event = "OPEN_SHOUKAIKA", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140238b50
    {.table = nullptr, .name = "OpenStrongRoadDiaoWen", .event = "OPEN_CHAOZHIFANKUI", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenStrongRoadDiaoWen Wrong Param"}, // 0x1402389c0
    {.table = nullptr, .name = "OpenStrongRoadDiaoWenSP", .event = "OPEN_CHAOZHIFANKUI_SP", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenStrongRoadDiaoWenSP Wrong Param"}, // 0x140238ae0
    {.table = nullptr, .name = "OpenSuperSaveUp", .event = "OPEN_FULI_SUPERSAVEUP", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenHuiGui Wrong Param"}, // 0x140238840
    {.table = nullptr, .name = "OpenTitleList", .event = "OPEN_AGNAME", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x14023bce0
    {.table = nullptr, .name = "OpenWeekHuoyuehaoli", .event = "OPEN_WEEKHUOYUEHAOLI", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239ba0
    {.table = nullptr, .name = "OpenZhanLing", .event = "OPEN_ZHANLING", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 1, .bad_argument = "LUA: Lua_OpenZhanLing Wrong Param"}, // 0x140238750
    {.table = nullptr, .name = "ShowTeamInfoDlg", .event = "TEAM_OPEN_TEAMINFO_DLG", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 1}, // 0x140241c70
    {.table = nullptr, .name = "ToggleContainer", .event = "TOGLE_CONTAINER", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140233780
    {.table = nullptr, .name = "ToggleMission", .event = "TOGLE_MISSION", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x1402337c0
    {.table = nullptr, .name = "ToggleMissionOutLine", .event = "TOGLE_MISSION_OUTLINE", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140233800
    {.table = nullptr, .name = "ToggleWuhunPage", .event = "TOGGLE_WUHUN_PAGE", .arg = Arg::kNumber, .number = -1, .text = "", .hell_guard = true}, // 0x1402329c0
    {.table = nullptr, .name = "ToggleXuanShop", .event = "TOGGLE_XUANSHOP", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140239a70
    {.table = nullptr, .name = "ToggleYuanbaoShop", .event = "TOGGLE_YUANBAOSHOP", .arg = Arg::kText, .number = 0, .text = "normal"}, // 0x1402399f0
    {.table = nullptr, .name = "Update_PartyFrame_Menu", .event = "ON_TEAM_UPDATE_PARTYFRAME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140241d70
    {.table = nullptr, .name = "XiuLianPage", .event = "OPEN_XIULIAN_PAGE", .arg = Arg::kNumber, .number = -1, .text = "", .hell_guard = true}, // 0x140233040
    {.table = "Auction", .name = "CloseOnSaleWindow", .event = "CLOSE_ONSALE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a2a10
    {.table = "Auction", .name = "CloseUpItemWindow", .event = "CLOSE_UP_ITEM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a29e0
    {.table = "Auction", .name = "CloseUpPetWindow", .event = "CLOSE_UP_PET", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a29b0
    {.table = "Auction", .name = "OpenOnSaleWindow", .event = "OPEN_ONSALE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a2980
    {.table = "Auction", .name = "OpenUpPetWindow", .event = "OPEN_UP_PET", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402a2920
    {.table = "Bank", .name = "OpenSaveFrame", .event = "TOGLE_INPUT_MONEY", .arg = Arg::kText, .number = 0, .text = "save", .hell_guard = true}, // 0x1402a4430
    {.table = "CSongliaoWarData", .name = "CloseSongliaoWarMulti", .event = "SHOW_SONGLIAOWAR_SCORE_M", .arg = Arg::kNumber, .number = 0, .text = ""}, // 0x1403b5a20
    {.table = "CSongliaoWarData", .name = "OpenSongliaoWarMulti", .event = "SHOW_SONGLIAOWAR_SCORE_M", .arg = Arg::kNumber, .number = 1, .text = ""}, // 0x1403b5a50
    {.table = "City", .name = "ClosePhoenixPlainWarScoreMultiTable", .event = "SHOW_PHOENIXPLAINWAR_SCORE_M", .arg = Arg::kNumber, .number = 0, .text = ""}, // 0x140423eb0
    {.table = "City", .name = "OpenNewGuildWarDlg", .event = "NEW_BANGHUI_BHXZ_OPEN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140423dd0
    {.table = "City", .name = "OpenPhoenixPlainWarScoreMultiTable", .event = "SHOW_PHOENIXPLAINWAR_SCORE_M", .arg = Arg::kNumber, .number = 1, .text = ""}, // 0x140423e40
    {.table = "CommisionShop", .name = "CloseBuyConfrim", .event = "CONFIRM_COMMISION_BUY", .arg = Arg::kText, .number = 0, .text = "close"}, // 0x1402c5c20
    {.table = "CommisionShop", .name = "OnBuyConfrimed", .event = "COMMISION_BUY_CONFRIMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402c5c50
    {.table = "DataPool", .name = "EditMood", .event = "MOOD_SET", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x1402e0460
    {.table = "DataPool", .name = "MissionTrackGotoQuestLog", .event = "OPEN_FROM_MISSIONTRACK", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:MissionTrackGotoQuestLog"}, // 0x1402d3d70
    {.table = "DataPool", .name = "OpenDelCheckBox", .event = "TEAMBOARD_OPEN_DEL_CHECK", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:OpenDelCheckBox arg error"}, // 0x1402f36d0
    {.table = "DataPool", .name = "OpenFenxianDlg", .event = "OPEN_FEN_XIAN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140304050
    {.table = "DataPool", .name = "OpenFriendList", .event = "TOGLE_FRIEND", .arg = Arg::kText, .number = 0, .text = "2", .hell_guard = true}, // 0x1402e1870
    {.table = "DataPool", .name = "OpenMailRead", .event = "OPEN_EMAIL", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x1402e2490
    {.table = "DataPool", .name = "OpenModifyGroupNotice", .event = "SHOW_MODIFY_GROUPNOTICE", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 2, .bad_argument = "LUA:OpenModifyGroupNotice Param Error", .check_first = true}, // 0x1402f4530
    {.table = "DataPool", .name = "OpenSystemHistroy", .event = "OPEN_SYSTEMINFO", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x1402e42e0
    {.table = "DataPool", .name = "ShowNormalWatch", .event = "OPEN_NORMAL_WATCH", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402f3770
    {.table = "DataPool", .name = "ToggleTrustFriendWindow", .event = "TOGGLE_TRUST_FRIEND_LIST", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402dc760
    {.table = "DataPool", .name = "UpdateCampaignListByTrack", .event = "UPDATE_CAMPAGIN_BY_TRACK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402d4220
    {.table = "DataPool", .name = "UpdateMissionTrack", .event = "UPDATE_MISSION_TRACK", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x1402d42d0
    {.table = "DataPool", .name = "UpdateQuestLogByTrack", .event = "UPDATE_QUESTLOG_BY_TRACK", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1402d41f0
    {.table = "DataPool", .name = "UpdateTrackStateButton", .event = "UPDATE_TRACK_STATE_BUTTON", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:UpdateTrackStateButton"}, // 0x1402d4980
    {.table = "DressEnchasing", .name = "Lua_DressTransferBindConfirmed", .event = "DRESS_TRANSFER_BIND_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403fdc10
    {.table = "DressEnchasing", .name = "Lua_FittingOnDressTransferOver", .event = "DRESS_TRANSFER_FITTING_HIDDEN", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403fdbe0
    {.table = "Exchange", .name = "CloseExchangeInfo", .event = "CLOSE_EXCHAGE_INFO", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140336400
    {.table = "Friend", .name = "Close", .event = "TOGLE_FRIEND_INFO", .arg = Arg::kNumber, .number = -1, .text = ""}, // 0x1403398c0
    {.table = "FriendSearcher", .name = "OpenFriendSearch", .event = "OPEN_FRIEND_SEARCH", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x14033d720
    {.table = "Guild", .name = "ShowCityBuildIntroduce", .event = "OPEN_BUILD_INTRODUCE", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140414d90
    {.table = "Guild", .name = "ToggleGuildDetailInfo", .event = "GUILD_SELFEQUIP_CLICK", .arg = Arg::kNone, .number = 0, .text = "", .hell_guard = true}, // 0x140410fd0
    {.table = "LifeAbility", .name = "ClosePetEquipEnhanceMsgBox", .event = "CLOSE_PETEQUIP_ENHANCE_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14034fb80
    {.table = "LifeAbility", .name = "CloseReIdentifyMsgBox", .event = "CLOSE_RE_IDENTIFY_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14034fc10
    {.table = "LifeAbility", .name = "CloseStrengthMsgBox", .event = "CLOSE_STRENGTH_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14034fb50
    {.table = "LifeAbility", .name = "ConfirmDiaowenChaichu", .event = "UI_COMMAND", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:LifeAbility ConfirmDiaowenChaichu parameter error"}, // 0x140353e70
    {.table = "LifeAbility", .name = "Open_Compose_Gem_Page", .event = "OPEN_COMPOSE_GEM", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 2, .bad_argument = "LUA: LifeAbility:Open_Compose_Gem_Page Wrong Param"}, // 0x140348410
    {.table = "Match", .name = "CloseHuaShanGRMatchScoreMultiTable", .event = "SHOW_HUASHANGRMATCH_SCORE_M", .arg = Arg::kNumber, .number = 0, .text = ""}, // 0x1403ef870
    {.table = "Match", .name = "OpenHuaShanGRMatchScoreMultiTable", .event = "SHOW_HUASHANGRMATCH_SCORE_M", .arg = Arg::kNumber, .number = 1, .text = ""}, // 0x1403ef830
    {.table = "NpcShop", .name = "Close", .event = "CLOSE_BOOTH", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140359580
    {.table = "NpcShop", .name = "CloseConfirm", .event = "YUANBAO_BUY_ITEM_CONFIRM", .arg = Arg::kText, .number = 0, .text = "close"}, // 0x14035b930
    {.table = "Pet", .name = "ClosePetSkillStudyMsgBox", .event = "CLOSE_PETSKILLSTUDY_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037bfd0
    {.table = "Pet", .name = "CloseSignalPetProCreate", .event = "TEAM_PETCREATE_OPENED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037e600
    {.table = "Pet", .name = "CloseTeamPetProCreate", .event = "SIGNAL_PETCREATE_OPENED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037e5d0
    {.table = "Pet", .name = "ConfirmPetSkillStudy", .event = "CONFIRM_PETSKILLSTUDY", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037c000
    {.table = "Pet", .name = "Lua_LianHuaConfirm", .event = "PET_LIANHUA_CONFIRM", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:Pet Lua_LianHuaConfirm parameter error"}, // 0x140380a80
    {.table = "Pet", .name = "Lua_LianHuaConfirmRet", .event = "PET_LIANHUA_CONFIRM_RET", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140380af0
    {.table = "Pet", .name = "Lua_NianShouHuanYuBindConfirm", .event = "NIANSHOU_HUANYU_BIND_CONFIRM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403821b0
    {.table = "Pet", .name = "Lua_NianShouHuanYuBindConfirmed", .event = "NIANSHOU_HUANYU_BIND_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140382210
    {.table = "Pet", .name = "Lua_NianShouHuanYuRareConfirm", .event = "NIANSHOU_HUANYU_RARE_CONFIRM", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:Pet Lua_NianShouHuanYuRareConfirm parameter error"}, // 0x140382140
    {.table = "Pet", .name = "Lua_NianShouHuanYuRareConfirmed", .event = "NIANSHOU_HUANYU_RARE_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403821e0
    {.table = "Pet", .name = "Lua_NianShouHuanYuUpBindConfirm", .event = "NIANSHOU_HUANYUUP_BIND_CONFIRM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403822c0
    {.table = "Pet", .name = "Lua_NianShouHuanYuUpBindConfirmed", .event = "NIANSHOU_HUANYUUP_BIND_CONFIRMED", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x1403822f0
    {.table = "Pet", .name = "Lua_NianShouNingYuConfirm", .event = "NIANSHOU_NINGYU_CONFIRM", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:Pet Lua_NianShouNingYuConfirm parameter error"}, // 0x140381ef0
    {.table = "Pet", .name = "Lua_OpenNianShouHuanYuJian", .event = "NIANSHOU_HUANYU_JIAN", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:Pet Lua_OpenNianShouHuanYuJian parameter error"}, // 0x140382240
    {.table = "Pet", .name = "Lua_OpenPetHuanLingUI", .event = "OPEN_PET_HUANLING_UI", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140381bf0
    {.table = "Pet", .name = "NotifyPetDlgClosed", .event = "CLOSE_PET_AGNAME", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037bb60
    {.table = "Pet", .name = "NotifySelChange", .event = "PET_CHANGE", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:Pet NotifySelChange parameter error"}, // 0x14037baf0
    {.table = "Pet", .name = "OpenPetSkillStudyMsgBox", .event = "OPEN_PETSKILLSTUDY_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037bfa0
    {.table = "Pet", .name = "PetOpenTitleList", .event = "OPEN_PET_AGNAME", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 2, .bad_argument = "LUA:Pet PetOpenTitleList parameter error", .check_first = true}, // 0x14037ba70
    {.table = "Pet", .name = "UpdatePetList", .event = "UPDATE_PET_LIST", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14037e500
    {.table = "Player", .name = "ConfirmDismissTeam", .event = "CONFIRM_DISMISS_TEAM", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140384e10
    {.table = "Player", .name = "OpenDismissTeamMsgbox", .event = "OPNE_DISMISS_TEAM_MSGBOX", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140384de0
    {.table = "PlayerPackage", .name = "OpenLockFrame", .event = "OPEN_ITEM_COFFER", .arg = Arg::kArgument, .number = 0, .text = "", .hell_guard = true, .argument = 2, .bad_argument = "LUA: PlayerPackage::OpenLockFrame Wrong Param1"}, // 0x140360020
    {.table = "PlayerPackage", .name = "OpenPetEquipEnhanceMsgBox", .event = "CONFIRM_PETEQUIP_ENHANCE", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "Lua PlayerPackage::OpenPetEquipEnhanceMsgBox parameter error!"}, // 0x140362100
    {.table = "PlayerPackage", .name = "OpenPetEquipReIdentifyMsgBox", .event = "PETEQUIP_CONFIRM_RE_IDENTIFY", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "Lua PlayerPackage::OpenPetEquipReIdentifyMsgBox parameter error!"}, // 0x140362090
    {.table = "PlayerPackage", .name = "OpenReIdentifyMsgBox", .event = "CONFIRM_RE_IDENTIFY", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "Lua PlayerPackage::OpenReIdentifyMsgBox parameter error!"}, // 0x140361e00
    {.table = "PlayerShop", .name = "CloseChangeTypeMsgBox", .event = "CLOSE_PS_CHANGETYPE_MSG", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14045a2e0
    {.table = "PlayerShop", .name = "CloseRecycleShop", .event = "CLOSE_RECYCLESHOP_MSG", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x14045a3e0
    {.table = "PlayerShop", .name = "CloseShopMag", .event = "PS_CLOSE_SHOP_MAG", .arg = Arg::kNone, .number = 0, .text = ""}, // 0x140457d70
    {.table = "PlayerShop", .name = "OpenADDlg", .event = "RECYCLE_AD_SET", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "PlayerShop::OpenADDlg[1] param parameter error"}, // 0x14045a260
    {.table = "PlayerShop", .name = "OpenSelectRecycleItemDLG", .event = "OPEN_SELECTRECYCLEITEM_DLG", .arg = Arg::kArgument, .number = 0, .text = "", .argument = 2, .bad_argument = "LUA:PlayerShop::OpenSelectRecycleItemDLG[2] param parameter error"}, // 0x140457f00
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
    std::optional<double> given;
    if constexpr (push.arg == Arg::kArgument) {
        given = native::strict_number(lua, push.argument);
        if constexpr (push.check_first) {
            if (!given) return std::unexpected(NativeError::of(push.bad_argument));
        }
    }
    if constexpr (push.hell_guard) {
        if (context.facts.in_hell()) return 0;
    }
    if constexpr (push.arg == Arg::kArgument && !push.check_first) {
        if (!given) {
            if constexpr (push.bad_argument != nullptr) return std::unexpected(NativeError::of(push.bad_argument));
            return 0;
        }
    }
    switch (push.arg) {
    case Arg::kNone:
        context.push_event(push.event, std::span<const std::string_view>{});
        break;
    case Arg::kNumber:
    case Arg::kArgument: {
        const std::int32_t value = given ? native::to_int(*given) : push.number;
        // %d của gốc: tối đa 11 ký tự cho int32.
        std::array<char, 16> digits{};
        const std::format_to_n_result<char*> done = std::format_to_n(digits.data(), digits.size(), "{}", value);
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
