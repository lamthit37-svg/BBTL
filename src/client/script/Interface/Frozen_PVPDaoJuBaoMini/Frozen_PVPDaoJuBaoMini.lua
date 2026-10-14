-- 界面最小化

local g_unifiedposistion = nil

function Frozen_PVPDaoJuBaoMini_PreLoad()
	this:RegisterEvent("XRZPVP_UI_BATTLE_PACKET_MINI_SHOW")
	this:RegisterEvent("XRZPVP_BATTLERESULT_SHOW",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Frozen_PVPDaoJuBaoMini_OnLoad()
	g_unifiedposistion = Frozen_PVPDaoJuBaoMini_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPDaoJuBaoMini_OnEvent(event)

	if ( event == "XRZPVP_UI_BATTLE_PACKET_MINI_SHOW" ) then
		Frozen_PVPDaoJuBaoMini_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		Frozen_PVPDaoJuBaoMini_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPDaoJuBaoMini_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_PVPDaoJuBaoMini_CloseClicked()
	elseif(event == "XRZPVP_BATTLERESULT_SHOW") then
		Frozen_PVPDaoJuBaoMini_CloseClicked()
	end

end

function Frozen_PVPDaoJuBaoMini_OnShow()
	if XRZPVP:IsInBattleScene() ~= 1 then
		this:Hide()
		return
	end
	if IsWindowShow("Frozen_PVPDaoJuBao") then
		CloseWindow("Frozen_PVPDaoJuBao", true)
	end
	
	this:Show()

end

--================================================
-- 关闭
--================================================
function Frozen_PVPDaoJuBaoMini_OnClose()
	this:Hide()
	PushEvent("XRZPVP_UI_BATTLE_PACKET_SHOW")
end

--================================================
-- 关闭
--================================================
function Frozen_PVPDaoJuBaoMini_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPDaoJuBaoMini_ResetPos()
	if g_unifiedposistion ~= nil then
		Frozen_PVPDaoJuBaoMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
	end
end
