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
// IsZbs2018SpeicalServer.
void register_world(lua_State* lua);

// ScriptGlobal_Format (message_format.hpp).
void register_format(lua_State* lua);

} // namespace game::ui::script
