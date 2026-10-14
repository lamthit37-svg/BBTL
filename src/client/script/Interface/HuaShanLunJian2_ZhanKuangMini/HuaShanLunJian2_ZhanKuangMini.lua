-- 玩家血条积分UI 最小化UI
local g_unifiedposistion

function HuaShanLunJian2_ZhanKuangMini_PreLoad()
	this:RegisterEvent("XBWJHS_BATTLE_DETAILMINI_SHOW",true)
	this:RegisterEvent("XBWJHS_BATTLE_GAMEOVER",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function HuaShanLunJian2_ZhanKuangMini_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion	= HuaShanLunJian2_ZhanKuangMini_Frame:GetProperty("UnifiedPosition")
end

function HuaShanLunJian2_ZhanKuangMini_OnEvent(event)

	if (event == "XBWJHS_BATTLE_DETAILMINI_SHOW") then
		HuaShanLunJian2_ZhanKuangMini_OnShow()
	elseif (event == "ADJEST_UI_POS") then
		HuaShanLunJian2_ZhanKuangMini_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanLunJian2_ZhanKuangMini_ResetPos()
	elseif (event == "XBWJHS_BATTLE_GAMEOVER") then
		this:Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if XBWJHS:IsInBattleScene() ~= 1 then
			FengYun_PVE_Guide_Hide()
		end
	end
end

function HuaShanLunJian2_ZhanKuangMini_OnShow()	
	this:Show()
end

function HuaShanLunJian2_ZhanKuangMini_ResetPos()
	if g_unifiedposistion ~= nil then
		HuaShanLunJian2_ZhanKuangMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
	end
end

function HuaShanLunJian2_ZhanKuangMini_OnShowNormalUI()
	this:Hide()
	PushEvent("XBWJHS_BATTLE_DETAIL_SHOW")
end
