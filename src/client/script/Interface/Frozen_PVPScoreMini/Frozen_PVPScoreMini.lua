-- 界面最小化

local g_unifiedposistion = nil

function Frozen_PVPScoreMini_PreLoad()
	this:RegisterEvent("XRZPVP_UI_BATTLEMINI_SHOW")
	this:RegisterEvent("XRZPVP_BATTLERESULT_SHOW",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Frozen_PVPScoreMini_OnLoad()
	g_unifiedposistion = Frozen_PVPScoreMini_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPScoreMini_OnEvent(event)

	if ( event == "XRZPVP_UI_BATTLEMINI_SHOW" ) then
		Frozen_PVPScoreMini_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		Frozen_PVPScoreMini_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPScoreMini_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_PVPScoreMini_CloseClicked()
	elseif(event == "XRZPVP_BATTLERESULT_SHOW") then
		Frozen_PVPScoreMini_CloseClicked()
	end

end

function Frozen_PVPScoreMini_OnShow()
	if IsWindowShow("Frozen_PVPScore") then
		CloseWindow("Frozen_PVPScore", true)
	end
	
	this:Show()

end

--================================================
-- 关闭
--================================================
function Frozen_PVPScoreMini_OnClose()
	this:Hide()
	PushEvent("XRZPVP_BATTLESCORE_SHOW")
end

--================================================
-- 关闭
--================================================
function Frozen_PVPScoreMini_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPScoreMini_ResetPos()
	if g_unifiedposistion ~= nil then
		Frozen_PVPScoreMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
	end
end
