--!!!reloadscript =Face_Authentication

local g_Face_Authentication_Frame_UnifiedPosition = ""
local m_ObjServerId = -1
local g_UICOMMAND = 99909901
local g_UICommandReOpen = 99909902
local g_AuthState = ""
local g_AuthButton = ""

local g_PlayerSex = ""
local g_ShowOrHideButton = ""
local g_but2Image = ""
local g_InfoText = ""
function Face_Authentication_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	
	this:RegisterEvent("OPEN_FASHION_LOTTERY")
	this:RegisterEvent("REFRESH_FASHION_LOTTERY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function Face_Authentication_OnLoad()
	g_Face_Authentication_Frame_UnifiedPosition = Face_Authentication_Frame:GetProperty("UnifiedPosition")
	g_AuthButton = Face_Authentication_TypeBut
	g_AuthState = Face_Authentication_State2_Text
	g_PlayerSex = Face_Authentication_Gender1_Text
	g_ShowOrHideButton = Face_Authentication_but2
	g_but2Image = Face_Authentication_but2Image
	g_InfoText = Face_Authentication_Info_Text
end

function Face_Authentication_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND ) then
		local PlayerSex = Get_XParam_INT(0)
		local ShowOrHideFlag = Get_XParam_INT(1)
		local nextGetIdentityRewardTime = Get_XParam_INT(2)
		local currentTime = Get_XParam_INT(3)
		local PlayeneedTimer = Get_XParam_INT(4)

		Face_Authentication_Open(PlayerSex,ShowOrHideFlag,nextGetIdentityRewardTime,currentTime,PlayeneedTimer)
		return
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == g_UICommandReOpen ) then
		if (IsWindowShow("Face_Authentication")) then
			local PlayerSex = Get_XParam_INT(0)
			local ShowOrHideFlag = Get_XParam_INT(1)
			local nextGetIdentityRewardTime = Get_XParam_INT(2)
			local currentTime = Get_XParam_INT(3)
			local PlayeneedTimer = Get_XParam_INT(4)
	
			Face_Authentication_Open(PlayerSex,ShowOrHideFlag,nextGetIdentityRewardTime,currentTime,PlayeneedTimer)
			return
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Face_Authentication_Close_Clicked()
	end
end
function Face_Authentication_Open(PlayerSex,ShowOrHideFlag,nextGetIdentityRewardTime,currentTime,PlayeneedTimer)
	if currentTime < nextGetIdentityRewardTime then
		g_ShowOrHideButton:Disable()
		g_but2Image:Show()
		g_but2Image:SetToolTip(ScriptGlobal_Format("#{RLYZ_20240516_24}", PlayeneedTimer))
		g_ShowOrHideButton:SetToolTip(ScriptGlobal_Format("#{RLYZ_20240516_24}", PlayeneedTimer))
	else
		g_but2Image:Hide()
		g_ShowOrHideButton:Enable()
		if ShowOrHideFlag == 1 then
			g_ShowOrHideButton:SetToolTip("#{RLYZ_20240516_22}")
		else
			g_ShowOrHideButton:SetToolTip("#{RLYZ_20240516_23}")
		end
	end
	local isSocialServer = DataPool:LuaFnOpenSocialServer()
	if isSocialServer == 0 then
		if PlayerSex == 0 then
			g_InfoText:SetText("#{RLYZ_20240516_56}")
		else
			g_InfoText:SetText("#{RLYZ_20240516_57}")
		end
	else
		if PlayerSex == 0 then
			g_InfoText:SetText("#{RLYZ_20240516_9}")
		else

			g_InfoText:SetText("#{RLYZ_20240516_53}")
		end
	end
	if PlayerSex == 0 then
		g_AuthButton:Show()
		g_AuthState:SetText("#{RLYZ_20240516_12}")
		g_PlayerSex:Hide()
	else
		g_AuthButton:Hide()
		g_AuthState:SetText("#{RLYZ_20240516_11}")
		g_PlayerSex:Show()

		if PlayerSex == 1 then
			g_PlayerSex:SetText(ScriptGlobal_Format("#{RLYZ_20240516_13}", "#{RLYZ_20240516_14}"))
		else
			g_PlayerSex:SetText(ScriptGlobal_Format("#{RLYZ_20240516_13}", "#{RLYZ_20240516_15}"))
		end
	end
	this:Show()
end
function Face_Authentication_TypeBut_Clicked()
	if(IsWindowShow("Face_Authentication")) then
		PushDebugMessage("#{RLYZ_20240516_20}") -- 请打开畅游+完成人脸验证，认证成功后请重新登录游戏。
	end
end
function Face_Authentication_Close_Clicked()	--关闭界面
	if(IsWindowShow("Face_Authentication")) then
		CloseWindow("Face_Authentication", true)
	end
	this:Hide()
end
function Face_Authentication_ShowOrHide_Clicked() --显示/隐藏标识
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(999099)
	Set_XSCRIPT_Function_Name("ShowOrHideFaceAuthFlag")
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end