-- 玩家血条积分UI 最小化UI
local g_unifiedposistion

function ZBS_Score_Tiny_PreLoad()
	this:RegisterEvent("ZBS_BATTLE_TINYSHOW",true)
	this:RegisterEvent("ZBS_BATTLE_SHOW",false)
	this:RegisterEvent("ZBS_BATTLE_RESULT",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ZBS_CLOSE_BATTLEUI",false)
end

function ZBS_Score_Tiny_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion	= ZBS_Score_Tiny_Frame:GetProperty("UnifiedPosition")
end

function ZBS_Score_Tiny_OnEvent(event)

	if event == "ZBS_BATTLE_TINYSHOW" then
		ZBS_Score_Tiny_OnShow()
	elseif( event == "ADJEST_UI_POS" ) then
		ZBS_Score_Tiny_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_Score_Tiny_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif( event == "ZBS_BATTLE_SHOW" ) then
		this:Hide()
	elseif( event == "ZBS_BATTLE_RESULT" ) then
		this:Hide()
	elseif event == "ZBS_CLOSE_BATTLEUI" then
		this:Hide()
	end
end

function ZBS_Score_Tiny_OnShow()
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	this:Show()
end

function ZBS_Score_Tiny_ResetPos()
	ZBS_Score_Tiny_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ZBS_Score_Tiny_OnShowNormalUI()
	this:Hide()
	PushEvent( "ZBS_BATTLE_SHOW" )
end
