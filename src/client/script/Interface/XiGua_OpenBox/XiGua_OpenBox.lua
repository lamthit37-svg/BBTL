
local g_XiGua_OpenBox_UnifiedPosition

local g_XiGua_OpenBox_GoldenKeyNum = 0
local g_XiGua_OpenBox_GoldenKeyNeed = 1

local g_XiGua_OpenBox_GoldenShowId = 38004798

local g_XiGua_OpenBox_LeftShowId = 39922654
local g_XiGua_OpenBox_MiddleShowId = 39922655
local g_XiGua_OpenBox_RightShowId = 39922706

local g_XiGua_OpenBox_targetId = -1
local g_objCared = -1

function XiGua_OpenBox_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)		

end

function XiGua_OpenBox_OnLoad()
	
	g_XiGua_OpenBox_UnifiedPosition = XiGua_OpenBox:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function XiGua_OpenBox_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88808501) then
				
		g_XiGua_OpenBox_targetId = Get_XParam_INT(0)
		if g_XiGua_OpenBox_targetId == -1 then
			XiGua_OpenBox_Close()
			return
		end
		
		g_objCared = DataPool : GetNPCIDByServerID(g_XiGua_OpenBox_targetId);
		if g_objCared == -1 then
			XiGua_OpenBox_Close()
			return
		end
		XiGua_OpenBox_BeginCareObject()

		g_XiGua_OpenBox_GoldenKeyNum = Get_XParam_INT(1)	
		
		XiGua_OpenBox_OpenShow()
		this:Show()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_OpenBox_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		XiGua_OpenBox_Close()

	elseif event == "ADJEST_UI_POS" then

		XiGua_OpenBox_On_ResetPos()
		
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		
		g_XiGua_OpenBox_GoldenKeyNum = PlayerPackage:CountAvailableItemByIDTable(38004798)
		XiGua_OpenBox_UpdateKey()
		
	end

end

function XiGua_OpenBox_UpdateKey()

	if g_XiGua_OpenBox_GoldenKeyNum < g_XiGua_OpenBox_GoldenKeyNeed then
		strMsg = ScriptGlobal_Format("#{MZXB_200609_53}", g_XiGua_OpenBox_GoldenKeyNum)
	else
		if g_XiGua_OpenBox_GoldenKeyNum > 999 then
			strMsg = ScriptGlobal_Format("#{MZXB_200609_54}", "999+")
		else
			strMsg = ScriptGlobal_Format("#{MZXB_200609_54}", g_XiGua_OpenBox_GoldenKeyNum)
		end
	end
	XiGua_OpenBox_IconL_text:SetText(strMsg)
	
end

--=========
-- 重置
--=========
function XiGua_OpenBox_On_ResetPos()

	XiGua_OpenBox:SetProperty("UnifiedPosition", g_XiGua_OpenBox_UnifiedPosition)

end

function XiGua_OpenBox_BeginCareObject()
	this:CareObject(g_objCared, 1, "XiGua_OpenBox")
end

function XiGua_OpenBox_StopCareObject()
	this:CareObject(g_objCared, 0, "XiGua_OpenBox")
end

--=========
-- 关闭
--=========
function XiGua_OpenBox_Close()

	XiGua_OpenBox_IconL:SetActionItem(-1)
	XiGua_OpenBox_IconR:SetActionItem(-1)
	
	XiGua_OpenBox_ChooseL_IconL:SetActionItem(-1)
	
	XiGua_OpenBox_StopCareObject()
	
	this:Hide()
end

--=========
-- 打开
--=========
function XiGua_OpenBox_OpenShow()
	
	local strMsg = ""
	
	-- 钥匙
	local theAction = DataPool:CreateActionItemForShow(g_XiGua_OpenBox_GoldenShowId, 1)
	if theAction:GetID() ~= 0 then
		XiGua_OpenBox_ChooseL_IconL:SetActionItem(theAction:GetID())
		
		XiGua_OpenBox_UpdateKey()
	end
	
	-- 必得道具
	theAction = DataPool:CreateActionItemForShow(g_XiGua_OpenBox_LeftShowId, 1)
	if theAction:GetID() ~= 0 then
		XiGua_OpenBox_IconL:SetActionItem(theAction:GetID())
	end
	
	-- 概率得 左 
	theAction = DataPool:CreateActionItemForShow(g_XiGua_OpenBox_MiddleShowId, 1)
	if theAction:GetID() ~= 0 then
		XiGua_OpenBox_IconM:SetActionItem(theAction:GetID())
	end
	
	-- 概率得 右
	theAction = DataPool:CreateActionItemForShow(g_XiGua_OpenBox_RightShowId, 1)
	if theAction:GetID() ~= 0 then
		XiGua_OpenBox_IconR:SetActionItem(theAction:GetID())
	end

end

--================
-- 开启
--================
function XiGua_OpenBox_Open_Click()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenPayBox")
		Set_XSCRIPT_ScriptID(888085)
		Set_XSCRIPT_Parameter(0, g_XiGua_OpenBox_targetId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

