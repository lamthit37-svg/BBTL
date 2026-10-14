--周年庆 购买时装展示界面
local g_AnniversaryShow_ZS_Frame_UnifiedPosition

function AnniversaryShow_ZS_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
end

function AnniversaryShow_ZS_OnLoad()
	g_AnniversaryShow_ZS_Frame_UnifiedPosition = AnniversaryShow_ZS_Frame:GetProperty("UnifiedPosition")
end

function AnniversaryShow_ZS_OnEvent(event)
	if event == "VIEW_RESOLUTION_CHANGED" then
		AnniversaryShow_ZS_On_ResetPos()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2020041101) then
		this:Show()
		AnniversaryShow_ZS_Open()
		
	elseif event == "ADJEST_UI_POS" then
		AnniversaryShow_ZS_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		AnniversaryShow_ZS_Close()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		AnniversaryShow_ZS_Close()
	end
	
end

function AnniversaryShow_ZS_On_ResetPos()
	AnniversaryShow_ZS_Frame:SetProperty("UnifiedPosition", g_AnniversaryShow_ZS_Frame_UnifiedPosition)
end

function AnniversaryShow_ZS_Close()
	this:Hide()
end


function AnniversaryShow_ZS_Open()
	-- PushEvent( "CLOSE_ANNIVERSARY_GUIDE" )
end