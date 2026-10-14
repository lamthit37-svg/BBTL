--T3WarmUp_Letter.lua
--2020 新天外预热 信封界面
local g_T3WarmUp_Letter_UnifiedPosition

--===============================================
-- OnLoad()
--===============================================
function T3WarmUp_Letter_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end
function T3WarmUp_Letter_OnLoad()

	g_T3WarmUp_Letter_UnifiedPosition = T3WarmUp_Letter_Frame:GetProperty("UnifiedPosition")
	
end

--===============================================
-- OnEvent()
--===============================================
function T3WarmUp_Letter_OnEvent(event)

	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		T3WarmUp_Letter_Frame:SetProperty("UnifiedPosition", g_T3WarmUp_Letter_UnifiedPosition)
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		T3WarmUp_Letter_Closed()
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15630001 ) then
		if arg1 == nil or tonumber(arg1) == 0 then 
			T3WarmUp_Letter_Closed()
			return
		end
		
		T3WarmUp_Letter_UpdateInfo()
		this:Show()
	end
end
function T3WarmUp_Letter_Closed()
	this:Hide()
end
--===============================================
--===============================================
function T3WarmUp_Letter_UpdateInfo()

end
