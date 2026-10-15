// Sinh bằng TOOLS/port/luagen/gen_pool_natives.py từ decompile của Game.exe 2026; không sửa tay (sửa bộ sinh rồi sinh lại).
// Hàm game mà thân chỉ đọc một hay hai trường số của CDataPool (DAT_141034c40) rồi lua_pushnumber. Client chưa có kho đó:
// giá trị là ảnh bộ nhớ Facts::pool (phía mạng ghi theo offset), không có thì giá trị mà hàm dựng CDataPool (0x1400dec40) đặt.
#include "lua/capi.hpp"
#include "lua/native.hpp"
#include "ui/script/context.hpp"
#include "ui/script/native_groups.hpp"
#include "ui/script/native_support.hpp"
#include "ui/script/pool_image.hpp"

#include <array>
#include <cstddef>
#include <span>
#include <utility>

namespace game::ui::script {
namespace {

using lua::NativeResult;

struct Getter {
    const char* table = nullptr; // nullptr là hàm toàn cục
    const char* name = nullptr;
    std::array<PoolField, 2> fields{}; // lần đẩy thứ nhất và thứ hai
    int count = 0; // số lần đẩy
};

constexpr std::array<Getter, 130> kGetters = {{
    {.table = nullptr, .name = "AppWareGetLeftCheckTime", .fields = {{{.offset = 0x5c11d4, .width = Width::kI32}, {}}}, .count = 1}, // 0x140244960
    {.table = nullptr, .name = "AskFYJCPVPMapBaseInfo", .fields = {{{.offset = 0x6bac14, .width = Width::kI32}, {.offset = 0x6bac18, .width = Width::kI32}}}, .count = 2}, // 0x140254b30
    {.table = nullptr, .name = "GetCampaignIsShow", .fields = {{{.offset = 0x5eef6c, .width = Width::kI32}, {}}}, .count = 1}, // 0x14025f630
    {.table = nullptr, .name = "GetClientVersionType", .fields = {{{.offset = 0x5df288, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402655e0
    {.table = nullptr, .name = "GetCurCampaignID", .fields = {{{.offset = 0x5eef70, .width = Width::kI32}, {}}}, .count = 1}, // 0x14025f590
    {.table = nullptr, .name = "GetHuoYueShopDaiBiInfo", .fields = {{{.offset = 0x676500, .width = Width::kI32}, {.offset = 0x676504, .width = Width::kI32}}}, .count = 2}, // 0x140279680
    {.table = nullptr, .name = "IMDressChestGetSelIndex", .fields = {{{.offset = 0x16058, .width = Width::kI32}, {}}}, .count = 1}, // 0x140259740
    {.table = nullptr, .name = "IsZbsSpeicalServer", .fields = {{{.offset = 0x632c08, .width = Width::kI32}, {}}}, .count = 1}, // 0x14026aac0
    {.table = nullptr, .name = "LuaFnCameraVisualGetActive", .fields = {{{.offset = 0x6f57d0, .width = Width::kI32}, {}}}, .count = 1}, // 0x14023a370
    {.table = nullptr, .name = "LuaFnGetCurModelState", .fields = {{{.offset = 0x6ba2f8, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402779e0
    {.table = nullptr, .name = "LuaFnXinShouZhanLing_GetAwardProgressJingying", .fields = {{{.offset = 0x6ba314, .width = Width::kI32}, {}}}, .count = 1}, // 0x140281ea0
    {.table = nullptr, .name = "LuaFnXinShouZhanLing_GetAwardProgressPutong", .fields = {{{.offset = 0x6ba310, .width = Width::kI32}, {}}}, .count = 1}, // 0x140281e60
    {.table = nullptr, .name = "LuaFnXinShouZhanLing_GetExp", .fields = {{{.offset = 0x6ba304, .width = Width::kI32}, {}}}, .count = 1}, // 0x140281ae0
    {.table = nullptr, .name = "LuaFnXinShouZhanLing_GetHaveJingying", .fields = {{{.offset = 0x6ba308, .width = Width::kI32}, {}}}, .count = 1}, // 0x140281da0
    {.table = nullptr, .name = "LuaFnXinShouZhanLing_GetLevel", .fields = {{{.offset = 0x6ba300, .width = Width::kI32}, {}}}, .count = 1}, // 0x140281a20
    {.table = nullptr, .name = "LuaFnXinShouZhanLing_GetWeekExp", .fields = {{{.offset = 0x6ba31c, .width = Width::kI32}, {}}}, .count = 1}, // 0x140281fe0
    {.table = nullptr, .name = "Lua_GetDaHua_DaiBiGouMai_DaibiBuyCount", .fields = {{{.offset = 0x6ec9c4, .width = Width::kI32}, {}}}, .count = 1}, // 0x140285cd0
    {.table = nullptr, .name = "Lua_GetHuiLiu2022_ShouCeHuiLiuLevel", .fields = {{{.offset = 0x6ba1f0, .width = Width::kI32}, {}}}, .count = 1}, // 0x140277810
    {.table = nullptr, .name = "Lua_GetHuiLiu2022_ShouCeProgress", .fields = {{{.offset = 0x6ba1f4, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402773a0
    {.table = nullptr, .name = "Lua_GetTWBSceneRankNum", .fields = {{{.offset = 0x6784b4, .width = Width::kI32}, {}}}, .count = 1}, // 0x14027b410
    {.table = "AbilityTeacher", .name = "GetAbilityID", .fields = {{{.offset = 0x5b8f70, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402a0af0
    {.table = "AbilityTeacher", .name = "GetNeedExp", .fields = {{{.offset = 0x5b8f78, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402a0b30
    {.table = "AbilityTeacher", .name = "GetNeedLevel", .fields = {{{.offset = 0x5b8f80, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402a0cf0
    {.table = "AbilityTeacher", .name = "GetNeedSkillExp", .fields = {{{.offset = 0x5b8f7c, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402a0cb0
    {.table = "BWDH2018", .name = "GetBWTroopsPK_LeftTimes2018", .fields = {{{.offset = 0x6621e4, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403f2cf0
    {.table = "BWDH2018", .name = "GetBWTroopsPK_Result_Info2018", .fields = {{{.offset = 0x66220c, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403f3a30
    {.table = "BWDH2018", .name = "GetCopySceneBWFirstKillerType2018", .fields = {{{.offset = 0x6621dc, .width = Width::kU8}, {}}}, .count = 1}, // 0x1403f3030
    {.table = "BWDH2018", .name = "GetFightPairCount", .fields = {{{.offset = 0x6738c0, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403f7640
    {.table = "BWDH2018", .name = "GetFightPairFlag", .fields = {{{.offset = 0x6738c4, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403f77d0
    {.table = "BWDH2018", .name = "GetMyUIDirInfo", .fields = {{{.offset = 0x663e70, .width = Width::kU8}, {}}}, .count = 1}, // 0x1403f5410
    {.table = "BWDH2018", .name = "GetRankListNum", .fields = {{{.offset = 0x663e60, .width = Width::kU8}, {}}}, .count = 1}, // 0x1403f3a80
    {.table = "BWDH2018", .name = "GetRankMatchID", .fields = {{{.offset = 0x663e58, .width = Width::kU8}, {}}}, .count = 1}, // 0x1403f3c80
    {.table = "BWDH2018", .name = "GetRankNodeCount", .fields = {{{.offset = 0x6714bc, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403f72e0
    {.table = "BWDH2018", .name = "GetRankType", .fields = {{{.offset = 0x663e71, .width = Width::kU8}, {}}}, .count = 1}, // 0x1403f5520
    {.table = "CityBank", .name = "GetCityLevel", .fields = {{{.offset = 0x62bf34, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402c4f00
    {.table = "CityBank", .name = "GetCurPageRecordNum", .fields = {{{.offset = 0x62bf38, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402c4f40
    {.table = "CityBank", .name = "GetRecordNum", .fields = {{{.offset = 0x62bf30, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402c4ec0
    {.table = "CommanderFlag", .name = "GetCommanderLevel", .fields = {{{.offset = 0x6f56f8, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402939e0
    {.table = "CommisionShop", .name = "GetNpcId", .fields = {{{.offset = 0x5c1280, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402c55e0
    {.table = "CorpsUI_2018", .name = "GetCopySceneFirstKillerType", .fields = {{{.offset = 0x64a630, .width = Width::kU8}, {}}}, .count = 1}, // 0x1402cb860
    {.table = "CorpsUI_2018", .name = "GetCorpsPK_LeftTimes", .fields = {{{.offset = 0x64a638, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402cb810
    {.table = "CorpsUI_2018", .name = "GetCorpsPK_Result_Info", .fields = {{{.offset = 0x64a63c, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402cb7c0
    {.table = "CorpsUI_2018", .name = "GetFightPairCount", .fields = {{{.offset = 0x66134c, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402cc8a0
    {.table = "CorpsUI_2018", .name = "GetRankNodeCount", .fields = {{{.offset = 0x65e648, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402cbd70
    {.table = "CorpsUI_2018", .name = "GetZbsStage", .fields = {{{.offset = 0x64a640, .width = Width::kU8}, {}}}, .count = 1}, // 0x1402cc390
    {.table = "DFS", .name = "GetRankNodeCount", .fields = {{{.offset = 0x631784, .width = Width::kI32}, {}}}, .count = 1}, // 0x140331660
    {.table = "DataPool", .name = "GetBieYeScenePlayerCount", .fields = {{{.offset = 0x62ebe4, .width = Width::kI32}, {}}}, .count = 1}, // 0x140309410
    {.table = "DataPool", .name = "GetChallengeCount", .fields = {{{.offset = 0x5fdd3c, .width = Width::kI32}, {}}}, .count = 1}, // 0x140309b40
    {.table = "DataPool", .name = "GetChallengeTeamMemberCount", .fields = {{{.offset = 0x5c0580, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402e8bc0
    {.table = "DataPool", .name = "GetCurActiveRidePoint", .fields = {{{.offset = 0x5c11e8, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402ea2a0
    {.table = "DataPool", .name = "GetDBLeftProtectTime", .fields = {{{.offset = 0x5c11e4, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402ea180
    {.table = "DataPool", .name = "GetImMsgNumber", .fields = {{{.offset = 0x5d6e58, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402f4a00
    {.table = "DataPool", .name = "GetIsBaiBing", .fields = {{{.offset = 0x5df054, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403006c0
    {.table = "DataPool", .name = "GetIsShowChatSignRedPoint", .fields = {{{.offset = 0x6e01e4, .width = Width::kU8}, {}}}, .count = 1}, // 0x1403242b0
    {.table = "DataPool", .name = "GetMsgNum", .fields = {{{.offset = 0x5d6c68, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402f0f80
    {.table = "DataPool", .name = "GetProposerCount", .fields = {{{.offset = 0x5ac3c4, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402e4630
    {.table = "DataPool", .name = "GetTrans", .fields = {{{.offset = 0x5de5cc, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402fb940
    {.table = "DataPool", .name = "GetTransBWaitTime", .fields = {{{.offset = 0x5c11e0, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402ea220
    {.table = "DataPool", .name = "GetVipAccProgress", .fields = {{{.offset = 0x5df00c, .width = Width::kI32}, {.offset = 0x5df010, .width = Width::kI32}}}, .count = 2}, // 0x1402ffe70
    {.table = "DataPool", .name = "GetVipLevel", .fields = {{{.offset = 0x5deeb8, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402ffdf0
    {.table = "DataPool", .name = "GetXiuChangRoomCount", .fields = {{{.offset = 0x5f8798, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030edd0
    {.table = "DataPool", .name = "IsZhuJiVipShopOpen", .fields = {{{.offset = 0x5c0d00, .width = Width::kI32}, {}}}, .count = 1}, // 0x1402ea580
    {.table = "DataPool", .name = "LuaFnGetGMMathcType", .fields = {{{.offset = 0x632bd9, .width = Width::kU8}, {}}}, .count = 1}, // 0x14031b700
    {.table = "DataPool", .name = "LuaFnGetGuildBiddingItemCount", .fields = {{{.offset = 0x6dfed0, .width = Width::kI32}, {}}}, .count = 1}, // 0x14031e050
    {.table = "DataPool", .name = "LuaFnGetGuildBiddingStage", .fields = {{{.offset = 0x6dfed4, .width = Width::kI32}, {}}}, .count = 1}, // 0x14031e090
    {.table = "DataPool", .name = "LuaFnGetIcePrizeDrawListCount", .fields = {{{.offset = 0x5ef9e8, .width = Width::kI32}, {}}}, .count = 1}, // 0x140328960
    {.table = "DataPool", .name = "LuaFnGetIcePrizeDrawNowId", .fields = {{{.offset = 0x5ef9f0, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403289a0
    {.table = "DataPool", .name = "LuaFnGetIcePrizeDrawNowState", .fields = {{{.offset = 0x5ef9ec, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403289e0
    {.table = "DataPool", .name = "LuaFnGetPlayerCangPinRankInfo", .fields = {{{.offset = 0x67f230, .width = Width::kI32}, {.offset = 0x67f234, .width = Width::kI32}}}, .count = 2}, // 0x1403298d0
    {.table = "DataPool", .name = "Lua_GetBossShamHpPercent100", .fields = {{{.offset = 0x5b8b58, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030b750
    {.table = "DataPool", .name = "Lua_GetChallengeRoomFilterMemberCount", .fields = {{{.offset = 0x60b46c, .width = Width::kI32}, {}}}, .count = 1}, // 0x140309eb0
    {.table = "DataPool", .name = "Lua_GetCurTimeWaveMarkNum", .fields = {{{.offset = 0x5b8c0c, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030b980
    {.table = "DataPool", .name = "Lua_GetCurXiaKeBossType", .fields = {{{.offset = 0x5b8c08, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030b9c0
    {.table = "DataPool", .name = "Lua_GetJiebanHuiliuFlag", .fields = {{{.offset = 0x679b9c, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403130a0
    {.table = "DataPool", .name = "Lua_GetRecoinNum", .fields = {{{.offset = 0x60b4d4, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030bcc0
    {.table = "DataPool", .name = "Lua_GetShamHpBossDataId", .fields = {{{.offset = 0x5b8b5c, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030b790
    {.table = "DataPool", .name = "Lua_GetShamHpXiaKeBossDataId", .fields = {{{.offset = 0x5b8c04, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030b940
    {.table = "DataPool", .name = "Lua_GetSuperRecoinNum", .fields = {{{.offset = 0x60b530, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030bf60
    {.table = "DataPool", .name = "Lua_GetXiaKeBossShamHpPercent100", .fields = {{{.offset = 0x5b8c00, .width = Width::kI32}, {}}}, .count = 1}, // 0x14030b900
    {.table = "DataPool", .name = "lua_GetFYJCTDTeamCount", .fields = {{{.offset = 0x6d2b70, .width = Width::kI32}, {}}}, .count = 1}, // 0x140329250
    {.table = "Exterior", .name = "LuaFnGetExteriorHairColorCount", .fields = {{{.offset = 0x69faa8, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403df1e0
    {.table = "GangT", .name = "GetBHSDZDPK_LeftTimes", .fields = {{{.offset = 0x5ef558, .width = Width::kI32}, {}}}, .count = 1}, // 0x140407220
    {.table = "GangT", .name = "GetBHSDZDPK_Result_Info", .fields = {{{.offset = 0x5ef55c, .width = Width::kI32}, {}}}, .count = 1}, // 0x140407150
    {.table = "GangT", .name = "GetCopySceneFirstKillerType", .fields = {{{.offset = 0x5ef550, .width = Width::kU8}, {}}}, .count = 1}, // 0x140407100
    {.table = "Guild", .name = "GetGuildContri", .fields = {{{.offset = 0x5ac3b8, .width = Width::kI32}, {}}}, .count = 1}, // 0x140411620
    {.table = "Guild", .name = "GetGuildNum", .fields = {{{.offset = 0x4c1b0, .width = Width::kI32}, {}}}, .count = 1}, // 0x140409520
    {.table = "Guild", .name = "GetGuildNumCurPage", .fields = {{{.offset = 0x4c1b4, .width = Width::kI32}, {}}}, .count = 1}, // 0x140409790
    {.table = "Guild", .name = "GetMyPosition", .fields = {{{.offset = 0x5ac390, .width = Width::kU8}, {}}}, .count = 1}, // 0x140414c40
    {.table = "GuildLeague", .name = "GetApplyGuildCount", .fields = {{{.offset = 0x59faa8, .width = Width::kI32}, {}}}, .count = 1}, // 0x140438d00
    {.table = "GuildLeague", .name = "GetLeagueCount", .fields = {{{.offset = 0x58d088, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404386d0
    {.table = "GuildLeague", .name = "GetMemberCount", .fields = {{{.offset = 0x59f93c, .width = Width::kI32}, {}}}, .count = 1}, // 0x140437c60
    {.table = "GuildLeague", .name = "GetUserCount", .fields = {{{.offset = 0x59f938, .width = Width::kI32}, {}}}, .count = 1}, // 0x140437c20
    {.table = "JueZhanWuLinZhiDian", .name = "GetCurBossIndex", .fields = {{{.offset = 0x6a3088, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404e56c0
    {.table = "LuHeXieXiang", .name = "GetCurChoose", .fields = {{{.offset = 0x6b3f84, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403edb30
    {.table = "LuHeXieXiang", .name = "GetFBLevel", .fields = {{{.offset = 0x6b3f88, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403edaf0
    {.table = "LuHeXieXiang", .name = "GetMemberCount", .fields = {{{.offset = 0x6b3f80, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403edab0
    {.table = "MaritialSys", .name = "GetLastDayMonster", .fields = {{{.offset = 0x649e0c, .width = Width::kI32}, {.offset = 0x649e10, .width = Width::kI32}}}, .count = 2}, // 0x140358ba0
    {.table = "MaritialSys", .name = "GetMaritiaExp", .fields = {{{.offset = 0x649d98, .width = Width::kI32}, {}}}, .count = 1}, // 0x140357a10
    {.table = "MaritialSys", .name = "GetMaritiaFreezeState", .fields = {{{.offset = 0x649d94, .width = Width::kU8}, {}}}, .count = 1}, // 0x1403574d0
    {.table = "MaritialSys", .name = "GetMaritiaLTodayMultiNum", .fields = {{{.offset = 0x649d8c, .width = Width::kI32}, {}}}, .count = 1}, // 0x140357490
    {.table = "MaritialSys", .name = "GetMaritiaRemainPoint", .fields = {{{.offset = 0x649da0, .width = Width::kI32}, {}}}, .count = 1}, // 0x140357520
    {.table = "MaritialSys", .name = "GetMaritialTodayNum", .fields = {{{.offset = 0x649d88, .width = Width::kI32}, {}}}, .count = 1}, // 0x140357450
    {.table = "MaritialSys", .name = "GetTalentRemainPoint", .fields = {{{.offset = 0x649e20, .width = Width::kI32}, {}}}, .count = 1}, // 0x140358f40
    {.table = "NpcShop", .name = "GetFengMingShopDaiBi", .fields = {{{.offset = 0x6b9950, .width = Width::kI32}, {}}}, .count = 1}, // 0x14035d6c0
    {.table = "Player", .name = "GetTimeToPeace", .fields = {{{.offset = 0x5c0cf4, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403872b0
    {.table = "Player", .name = "WeekcardTakeTimes", .fields = {{{.offset = 0x5df280, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403993e0
    {.table = "PlayerPackage", .name = "GetSplitSum", .fields = {{{.offset = 0x5b8cdc, .width = Width::kI32}, {}}}, .count = 1}, // 0x14035f630
    {.table = "PlayerShop", .name = "GetCanOpenShopType", .fields = {{{.offset = 0x15dfc, .width = Width::kU8}, {}}}, .count = 1}, // 0x140453600
    {.table = "PlayerShop", .name = "GetCreateType", .fields = {{{.offset = 0x15dfd, .width = Width::kU8}, {}}}, .count = 1}, // 0x140453650
    {.table = "PlayerShop", .name = "GetFriendNum", .fields = {{{.offset = 0x16038, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404569e0
    {.table = "PlayerShop", .name = "GetLockStatus", .fields = {{{.offset = 0x15f48, .width = Width::kI32}, {}}}, .count = 1}, // 0x14045a410
    {.table = "PlayerShop", .name = "GetNpcId", .fields = {{{.offset = 0x1605c, .width = Width::kI32}, {}}}, .count = 1}, // 0x140456e20
    {.table = "PlayerShop", .name = "GetUnlockTime", .fields = {{{.offset = 0x15f4c, .width = Width::kI32}, {}}}, .count = 1}, // 0x14045a450
    {.table = "PlayerShop", .name = "IsCoopertiveList", .fields = {{{.offset = 0x60b4cc, .width = Width::kI32}, {}}}, .count = 1}, // 0x14045b210
    {.table = "QianKunPotScript", .name = "GetQianKunPotTypeMax", .fields = {{{.offset = 0x6b9b58, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403a0000
    {.table = "Raid", .name = "GetApplicantCount", .fields = {{{.offset = 0x5ddc90, .width = Width::kU16}, {}}}, .count = 1}, // 0x1403a2600
    {.table = "Raid", .name = "GetMemCount", .fields = {{{.offset = 0x5ddc68, .width = Width::kU16}, {}}}, .count = 1}, // 0x1403a3b10
    {.table = "ReturnTool", .name = "GetNowPageNum", .fields = {{{.offset = 0x5c128c, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403a6650
    {.table = "ReturnTool", .name = "GetReturnItemPageTatol", .fields = {{{.offset = 0x5c1290, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403a6590
    {.table = "ReturnTool", .name = "GetReturnPetPageTatol", .fields = {{{.offset = 0x5c1294, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403a65d0
    {.table = "ReturnTool", .name = "GetReturnShopPageTatol", .fields = {{{.offset = 0x5c1298, .width = Width::kI32}, {}}}, .count = 1}, // 0x1403a6610
    {.table = "Talk", .name = "GetGSInfoIsRetNew", .fields = {{{.offset = 0x5ef898, .width = Width::kI32}, {}}}, .count = 1}, // 0x140483b40
    {.table = "Talk", .name = "GetGSState", .fields = {{{.offset = 0x5ef570, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404827d0
    {.table = "Talk", .name = "GetNewGSState", .fields = {{{.offset = 0x5ef704, .width = Width::kI32}, {}}}, .count = 1}, // 0x140482820
    {.table = "WuLinZhiDian", .name = "GetAvalibleAwardCount", .fields = {{{.offset = 0x6a3090, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404e4780
    {.table = "WuLinZhiDian", .name = "GetAverageStage", .fields = {{{.offset = 0x6a3080, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404e4250
    {.table = "WuLinZhiDian", .name = "GetChooseStage", .fields = {{{.offset = 0x6a3084, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404e4190
    {.table = "WuLinZhiDian", .name = "GetCurBossIndex", .fields = {{{.offset = 0x6a3088, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404e49d0
    {.table = "WuLinZhiDian", .name = "GetMaxStage", .fields = {{{.offset = 0x6a307c, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404e40d0
    {.table = "WuLinZhiDian", .name = "IsDoubleAwardTime", .fields = {{{.offset = 0x6a3074, .width = Width::kI32}, {}}}, .count = 1}, // 0x1404e4090
}};

// Giá trị đầu khác 0 của các trường trên theo hàm dựng CDataPool (trường không có ở đây là 0).
constexpr std::array<PoolInitial, 6> kInitial = {{
    {.offset = 0x5c0cf4, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x5df054, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x5df288, .width = Width::kI32, .value = 2}, // hàm dựng ghi
    {.offset = 0x5eef70, .width = Width::kI32, .value = -1}, // hàm dựng ghi
    {.offset = 0x5ef9f0, .width = Width::kI32, .value = -1}, // hàm dựng con FUN_140153ec0 ghi
    {.offset = 0x64a63c, .width = Width::kI32, .value = -1}, // hàm dựng con FUN_1400a1d50 ghi
}};

// Một hàm Lua cho mỗi dòng của kGetters: lua_CFunction không mang dữ liệu đi kèm nên chỉ số dòng là tham số mẫu.
template <std::size_t Index>
NativeResult pool_number(lua_State* lua) {
    constexpr const Getter& getter = kGetters.at(Index);
    const PoolImage& pool = native::context_of(lua).facts.pool;
    for (int pushed = 0; pushed < getter.count; ++pushed) {
        lua_pushnumber(lua, static_cast<double>(pool.read(getter.fields.at(static_cast<std::size_t>(pushed)), kInitial)));
    }
    return getter.count;
}

template <std::size_t... Index>
constexpr std::array<native::Entry, sizeof...(Index)> make_entries(std::index_sequence<Index...>) {
    return {{{.name = kGetters.at(Index).name, .function = &lua::adapt<pool_number<Index>>}...}};
}

constexpr std::array kEntries = make_entries(std::make_index_sequence<kGetters.size()>{});

} // namespace

void register_pool(lua_State* lua) {
    for (std::size_t index = 0; index < kGetters.size(); ++index) {
        const std::span<const native::Entry> entry(&kEntries.at(index), 1);
        if (kGetters.at(index).table == nullptr) {
            native::register_globals(lua, entry);
        } else {
            native::register_table(lua, kGetters.at(index).table, entry);
        }
    }
}

} // namespace game::ui::script
