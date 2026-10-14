local g_WuYiH5_Frame_UnifiedPosition

function WuYiH5_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function WuYiH5_OnLoad()
	g_WuYiH5_Frame_UnifiedPosition = WuYiH5:GetProperty("UnifiedPosition")

end

function WuYiH5_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2021040901) then
		this:Show()
		WuYiH5_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		WuYiH5_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		WuYiH5_Close()
	elseif event == "ADJEST_UI_POS" then
		WuYiH5_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WuYiH5_Close()
	end
	
end

function WuYiH5_Open()

	
end

function WuYiH5_On_ResetPos()
	WuYiH5:SetProperty("UnifiedPosition", g_WuYiH5_Frame_UnifiedPosition)

end

function WuYiH5_Close()

	this:Hide()
end

