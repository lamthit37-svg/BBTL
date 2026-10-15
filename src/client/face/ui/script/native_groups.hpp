// Các nhóm hàm game của script giao diện (tầng B của LUA-GEN). Mỗi nhóm một native_<nhóm>.cpp, có một hàm đăng ký gọi từ
// open_natives. Đều chạy trong lua_cpcall và dùng Context đã attach (native_support.hpp).
#pragma once

struct lua_State;

namespace game::ui::script {

// XSCRIPT và XParam: cách script giao diện nói chuyện với script máy chủ (xscript.hpp). Get_XParam_INT, Get_XParam_UINT,
// Get_XParam_STR, Get_XParam_INT_Count, Get_XParam_STR_Count, Set_XSCRIPT_ScriptID, Set_XSCRIPT_Function_Name,
// Set_XSCRIPT_ParamCount, Set_XSCRIPT_Parameter, Clear_XSCRIPT, Send_XSCRIPT.
void register_xscript(lua_State* lua);

// Variable:GetVariable, Variable:SetVariable (bảng biến toàn cục, variable.hpp); SetVariable phát VARIABLE_CHANGED.
void register_variable(lua_State* lua);

// Điều game biết về thế giới (Context::facts): DataPool:GetCurDialogNpcId, DataPool:LuaFnGetGMVisibleType, SystemSetup:IsClassic,
// WuLinZhiDian:IsWuLinZhiDianScene, JueZhanWuLinZhiDian:IsJueZhanWuLinZhiDianScene, CSongliaoWarData:TSLGetLocalSceneID, GetSceneID,
// IsZbs2018SpeicalServer, GetSceneSize, GetSceneSizeByID, GetSceneMapByID, IsInTServer, IsTBFinalServer, KVKInterface:IsInKVKServer,
// TLCJ:IsInTLCJScene.
void register_world(lua_State* lua);

// ScriptGlobal_Format (message_format.hpp).
void register_format(lua_State* lua);

// Player:GetData, GetLevel, GetName, IsLeader; DataPool:GetSelfZoneWorldID, GetGuildClanID (nhân vật người chơi, Facts::hero).
void register_player(lua_State* lua);

// Hàm hệ thống nhỏ: OSAPI:GetTickCount, ZBS:IsViewerWatching, IsDfsSpeicalServer, Infant:GetMaxSkillNum, KaJi:LuaFnIsKaJiServer,
// KaJi:LuaFnGetKaJiType, CloseMessageBoxCommon, DataPool:SetCanUseHotKey, DataPool:Lua_GetUpdateTipsFlag.
void register_system(lua_State* lua);

// Hàm mà thân chỉ đẩy một sự kiện giao diện (OpenSafeScore, ToggleXuanShop, CloseTitleList...): sinh bằng
// TOOLS/port/luagen/gen_event_natives.py vào native_events.cpp.
void register_events(lua_State* lua);

// Hàm chỉ đọc một hay hai trường số của CDataPool (GetImMsgNumber, GetTimeToPeace, GetVipLevel...): sinh bằng
// TOOLS/port/luagen/gen_pool_natives.py vào native_pool.cpp, đọc từ Facts::pool.
void register_pool(lua_State* lua);

// Hàm đọc trạng thái nhỏ và hàm nhờ game (GetCurrentTime, Player:IsVaild, GetHumanExpRatioToNeedExp, Lua_IsRedPointInUIShow, lớp hướng dẫn
// tân thủ, SetMenuBarPageNumber, AskServerTimeAgain...) cùng những hàm xoá trạng thái mà client chưa có.
void register_state(lua_State* lua);

// Thú cưng và thú con trên kho dữ liệu máy chủ mà client chưa có: Pet:GetPet_Count, Pet:IsPresent, Pet:GetPetList_Appoint, Pet:ShowPetList,
// TargetPet:IsPresent, Infant:GetInfantCount, Infant:GetInfantSkillInfo, Infant:ToggleInfantPage... (native_pet.cpp).
void register_pet(lua_State* lua);

// Mục tiêu đang chọn khi chưa có mục tiêu: Target/CachedTarget:GetMenPai, IsPresent, Lua_CheckMainTargetHaveMaskBuff (native_target.cpp).
void register_target(lua_State* lua);

} // namespace game::ui::script
