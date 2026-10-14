
local g_PayTopList_ZhanShi_UnifiedPosition = nil
local g_Index = 0
function PayTopList_ZhanShi_PreLoad()

	this:RegisterEvent("UI_COMMAND")
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function PayTopList_ZhanShi_OnLoad()
	g_PayTopList_ZhanShi_UnifiedPosition = PayTopList_ZhanShi_Frame:GetProperty("UnifiedPosition")

	
end

--===============================================
-- OnEvent()
--===============================================
function PayTopList_ZhanShi_OnEvent(event)
	if (event == "UI_COMMAND")  and (tonumber(arg0) == 20141014)  then
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		PayTopList_ZhanShi_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		PayTopList_ZhanShi_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function PayTopList_ZhanShi_ResetPos()
		PayTopList_ZhanShi_Frame:SetProperty("UnifiedPosition",g_PayTopList_ZhanShi_UnifiedPosition)
end

function PayTopList_ZhanShi_OnHiden()
	this:Hide()
end