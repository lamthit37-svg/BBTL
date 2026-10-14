
--周年活动 花车巡游
local g_Anniversary_Parade_Frame_UnifiedPosition

function Anniversary_Parade_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	
end

function Anniversary_Parade_OnLoad()
	g_Anniversary_Parade_Frame_UnifiedPosition = Anniversary_Parade_Frame:GetProperty("UnifiedPosition")

end

function Anniversary_Parade_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2023032401) then
		if this:IsVisible() then
			this:Hide()
			return
		end
		
		this:Show()
		Anniversary_Parade_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_Parade_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Parade_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
end

function Anniversary_Parade_Open()


end
--帮助问号点击
function Anniversary_Parade_ShowHelp()
	PushEvent("CCSHOP_HELP", 191)
end

function Anniversary_Parade_On_ResetPos()
	Anniversary_Parade_Frame:SetProperty("UnifiedPosition", g_Anniversary_Parade_Frame_UnifiedPosition)
end

function Anniversary_Parade_OnHide()
	this:Hide()
end
