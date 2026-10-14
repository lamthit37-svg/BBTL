--冰雪躲避战 活动主界面
local g_Frozen_DodgeBall_Guide_Frame_UnifiedPosition

function Frozen_DodgeBall_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function Frozen_DodgeBall_Guide_OnLoad()
	g_Frozen_DodgeBall_Guide_Frame_UnifiedPosition = Frozen_DodgeBall_Guide_Frame_BK:GetProperty("UnifiedPosition")

end

function Frozen_DodgeBall_Guide_OnEvent(event)
	if event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_DodgeBall_Guide_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_DodgeBall_Guide_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_DodgeBall_Guide_Close()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 2024101701) then
		local operate = Get_XParam_INT(0)
		if operate == 0 then	
			this:Show()
		elseif operate == 1 then
			AutoRuntoTargetExWithName(99, 200, 1007, "戴春生")  --看看要不要处理主分线的事儿
		end
	end
	
end

function Frozen_DodgeBall_Guide_OnClickedBtn()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GoToFindNpc")
		Set_XSCRIPT_ScriptID(999463)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Frozen_DodgeBall_Guide_OnClickedHelp()
	PushEvent("CCSHOP_HELP", 226)
end

function Frozen_DodgeBall_Guide_On_ResetPos()
	Frozen_DodgeBall_Guide_Frame_BK:SetProperty("UnifiedPosition", g_Frozen_DodgeBall_Guide_Frame_UnifiedPosition)
end

function Frozen_DodgeBall_Guide_Close()
	this:Hide()
end
