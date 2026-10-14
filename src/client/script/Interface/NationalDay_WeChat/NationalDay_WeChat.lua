--国庆H5引导界面

local g_NationalDay_WeChat_Frame_UnifiedPosition

function NationalDay_WeChat_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function NationalDay_WeChat_OnLoad()
	g_NationalDay_WeChat_Frame_UnifiedPosition = NationalDay_WeChat_Frame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function NationalDay_WeChat_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 89323610) then
		this:Show()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
		NationalDay_WeChat_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		NationalDay_WeChat_Close()

	elseif event == "ADJEST_UI_POS" then
		NationalDay_WeChat_On_ResetPos()

	end

end

--=========
-- 重置
--=========
function NationalDay_WeChat_On_ResetPos()
	NationalDay_WeChat_Frame:SetProperty("UnifiedPosition", g_NationalDay_WeChat_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function NationalDay_WeChat_Close()
	this:Hide()
end