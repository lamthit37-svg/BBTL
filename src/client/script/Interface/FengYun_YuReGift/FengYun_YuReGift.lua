
local g_FengYun_YuReGift_Frame_UnifiedPosition

local g_FengYun_YuReGift_isFinish = 0
local g_FengYun_YuReGift_isGotReward = 0

function FengYun_YuReGift_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function FengYun_YuReGift_OnLoad()
	g_FengYun_YuReGift_Frame_UnifiedPosition = FengYun_YuReGift_Frame:GetProperty("UnifiedPosition")
	
end

function FengYun_YuReGift_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 2026010901 then
		local isOpen = Get_XParam_INT(0)
		g_FengYun_YuReGift_isFinish = Get_XParam_INT(1)
		g_FengYun_YuReGift_isGotReward = Get_XParam_INT(2)
		if isOpen == 1 then
			this:Show()
		end
		FengYun_YuReGift_Refresh()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2026010902) then
		AutoRuntoTargetExWithName(282, 301, 0, "癫狂的铸剑师")
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_YuReGift_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		FengYun_YuReGift_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		FengYun_YuReGift_OnClose()
	end
end

function FengYun_YuReGift_Refresh()
	FengYun_YuReGift_Btn_Tips:Hide()
	FengYun_YuReGift_Btn:Enable()
	if g_FengYun_YuReGift_isFinish == 0 then
		FengYun_YuReGift_Client_Bad:Show()
		FengYun_YuReGift_Client_Good:Hide()
	else
		FengYun_YuReGift_Client_Bad:Hide()
		FengYun_YuReGift_Client_Good:Show()
		
		if g_FengYun_YuReGift_isGotReward == 0 then
			FengYun_YuReGift_Btn_Tips:Show()
		else
			FengYun_YuReGift_Btn_Tips:Hide()
			FengYun_YuReGift_Btn:Disable()
		end
	end

end

function FengYun_YuReGift_OnHidden()
	
end

function FengYun_YuReGift_GoToBtnClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GoToFindNpc")
		Set_XSCRIPT_ScriptID(999820)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

-- function FengYun_YuReGift_GetRewardBtnClick()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name("GetReward")
-- 		Set_XSCRIPT_ScriptID(999820)
-- 		Set_XSCRIPT_ParamCount(0)
-- 	Send_XSCRIPT()
-- end

function FengYun_YuReGift_Help()
	PushEvent("CCSHOP_HELP", 241)
end

function FengYun_YuReGift_On_ResetPos()
	FengYun_YuReGift_Frame:SetProperty("UnifiedPosition", g_FengYun_YuReGift_Frame_UnifiedPosition)
end

function FengYun_YuReGift_OnClose()
	this:Hide()
end


