--周年庆 国韵华裳 展示
local g_Anniversary_Zhanshi_Frame_UnifiedPosition

function Anniversary_Zhanshi_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
end

function Anniversary_Zhanshi_OnLoad()
	g_Anniversary_Zhanshi_Frame_UnifiedPosition = Anniversary_Zhanshi_Frame_BK:GetProperty("UnifiedPosition")
end

function Anniversary_Zhanshi_OnEvent(event)
	if event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_Zhanshi_On_ResetPos()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2020040101) then
		this:Show()
		Anniversary_Zhanshi_Open()
		
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Zhanshi_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Zhanshi_OnHide()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_Zhanshi_OnHide()
	end
	
end

function Anniversary_Zhanshi_On_ResetPos()
	Anniversary_Zhanshi_Frame_BK:SetProperty("UnifiedPosition", g_Anniversary_Zhanshi_Frame_UnifiedPosition)
end

function Anniversary_Zhanshi_OnHide()
	this:Hide()
end


function Anniversary_Zhanshi_Open()
	PushEvent( "CLOSE_ANNIVERSARY_GUIDE" )
end