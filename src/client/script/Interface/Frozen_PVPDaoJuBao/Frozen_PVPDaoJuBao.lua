-- 界面最小化

local g_unifiedposistion = nil
local g_item_max = 18
local g_item_list = {}
local g_item_limit_list = {
	38007698,38007699,38007700,38007701,38007702,38007703,
	38007704,38007705,38007706,38007707,38007708,38007709,
	38007710,38007726,38007727
}
function Frozen_PVPDaoJuBao_PreLoad()
	this:RegisterEvent("XRZPVP_UI_BATTLE_PACKET_SHOW")
	this:RegisterEvent("XRZPVP_BATTLERESULT_SHOW",false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Frozen_PVPDaoJuBao_OnLoad()
	g_item_list = {
		Frozen_PVPDaoJuBao_Equip_Item1,
		Frozen_PVPDaoJuBao_Equip_Item2,
		Frozen_PVPDaoJuBao_Equip_Item3,
		Frozen_PVPDaoJuBao_Equip_Item4,
		Frozen_PVPDaoJuBao_Equip_Item5,
		Frozen_PVPDaoJuBao_Equip_Item6,	
		Frozen_PVPDaoJuBao_Equip_Item7,	
		Frozen_PVPDaoJuBao_Equip_Item8,	
		Frozen_PVPDaoJuBao_Equip_Item9,	
		Frozen_PVPDaoJuBao_Equip_Item10,	
		Frozen_PVPDaoJuBao_Equip_Item11,	
		Frozen_PVPDaoJuBao_Equip_Item12,	
		Frozen_PVPDaoJuBao_Equip_Item13,	
		Frozen_PVPDaoJuBao_Equip_Item14,	
		Frozen_PVPDaoJuBao_Equip_Item15,	
		Frozen_PVPDaoJuBao_Equip_Item16,
		Frozen_PVPDaoJuBao_Equip_Item17,
		Frozen_PVPDaoJuBao_Equip_Item18,	
	}
	g_unifiedposistion = Frozen_PVPDaoJuBao_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPDaoJuBao_OnEvent(event)

	if ( event == "XRZPVP_UI_BATTLE_PACKET_SHOW" ) then
		Frozen_PVPDaoJuBao_OnShow()
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" ) then
		Frozen_PVPDaoJuBao_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		Frozen_PVPDaoJuBao_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPDaoJuBao_ResetPos()
	elseif(event == "PLAYER_LEAVE_WORLD") then
		Frozen_PVPDaoJuBao_CloseClicked()
	elseif(event == "XRZPVP_BATTLERESULT_SHOW") then
		Frozen_PVPDaoJuBao_CloseClicked()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		if XRZPVP:IsInBattleScene() ~= 1 then
			Frozen_PVPDaoJuBao_CloseClicked()
		end
	end

end

function Frozen_PVPDaoJuBao_OnShow()
	if XRZPVP:IsInBattleScene() ~= 1 then
		this:Hide()
		return
	end
	if IsWindowShow("Frozen_PVPDaoJuBaoMini") then
		this:Hide()
	else
		Frozen_PVPDaoJuBao_OnItemShow()
		this:Show()
	end
end

--================================================
-- 关闭
--================================================
function Frozen_PVPDaoJuBao_OnItemShow()
	for _, ui in (g_item_list or {}) do
		ui:SetActionItem(-1)
		ui:Enable()
	end

	local index = 0
	local num = DataPool:GetBaseBag_Num()
	for i=1, num do
		local theAction,bLocked,bProtect,nElapsedTime = PlayerPackage:EnumItem("base", i-1)
		if theAction ~= nil then
			local itemIndex = theAction:GetDefineID()
			for _, itemid in (g_item_limit_list or {}) do
				if itemIndex == itemid then
					index = index + 1
					local actbtn = g_item_list[index]
					if actbtn == nil then
						break
					end

					actbtn:Show()
					actbtn:SetProperty("BackImage", "")
					if theAction:GetID() ~= 0 then
						actbtn:SetActionItem(theAction:GetID())
					end

					if bLocked == 1 then
						actbtn:Disable()
					end
					break
				end
			end
		end
	end
end

--================================================
-- 关闭
--================================================
function Frozen_PVPDaoJuBao_Hide_OnClick()
	this:Hide()
	PushEvent("XRZPVP_UI_BATTLE_PACKET_MINI_SHOW")
end

--================================================
-- 关闭
--================================================
function Frozen_PVPDaoJuBao_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPDaoJuBao_ResetPos()
	if g_unifiedposistion ~= nil then
		Frozen_PVPDaoJuBao_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
	end
end

function Frozen_PVPDaoJuBao_Equip_Item_Click(index, flag)
	local actbtn = g_item_list[index]
	if actbtn == nil then
		return
	end

	if flag > 0 then
		actbtn:DoSubAction()
	else
		actbtn:DoAction()
	end
end