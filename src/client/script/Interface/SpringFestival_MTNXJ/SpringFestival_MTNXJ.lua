
local g_SpringFestival_MTNXJ_UnifiedPosition
local g_SpringFestival_MTNXJ_IsFinish
function SpringFestival_MTNXJ_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end

function SpringFestival_MTNXJ_OnLoad()
	g_SpringFestival_MTNXJ_UnifiedPosition = SpringFestival_MTNXJ_Frame_BK:GetProperty("UnifiedPosition")

end

function SpringFestival_MTNXJ_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_MTNXJ_Frame_BK:SetProperty("UnifiedPosition", g_SpringFestival_MTNXJ_UnifiedPosition)
	
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2022120901 then
		g_SpringFestival_MTNXJ_IsFinish = Get_XParam_INT(0)
		this:Show()
	elseif ( event == "SCENE_TRANSED") then
		this:Hide()
	end
end

function SpringFestival_MTNXJ_ShowHelp()
	PushEvent("CCSHOP_HELP", 177)
end

function SpringFestival_MTNXJ_OnClose()
	this:Hide()
end

function SpringFestival_MTNXJ_Goto()
	if g_SpringFestival_MTNXJ_IsFinish == 1 then
		--完成了 提示消息
		PushDebugMessage("#{YTZ_20221107_16}")
	else
		--寻路
		AutoRunToTargetEx(299, 269, 0)	
	end
	
end

function SpringFestival_MTNXJ_OnHide()
	
end

