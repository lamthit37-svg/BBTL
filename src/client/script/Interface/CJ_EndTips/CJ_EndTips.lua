-- 结果界面

local g_unifiedposistion
local g_ui_command = 99932109


function CJ_EndTips_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)
end

function CJ_EndTips_OnLoad()
	g_unifiedposistion = CJ_EndTips_Frame:GetProperty("UnifiedPosition")
end

function CJ_EndTips_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then
		CJ_EndTips_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_EndTips_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_EndTips_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		CJ_EndTips_CloseClicked()
	elseif(event == "PLAYER_LEAVE_WORLD") then
		CJ_EndTips_CloseClicked()
	end

end

function CJ_EndTips_OnShow()

	if IsWindowShow("CJ_End") then
		CloseWindow("CJ_End", true)
	end

	local rank = Get_XParam_INT(0)
	local kill = Get_XParam_INT(1)
	local strRank = ScriptGlobal_Format("#{TLCJ_20240709_303}", rank)
	local strKill = ScriptGlobal_Format("#{TLCJ_20240709_304}", kill)
	CJ_EndTips_RankNow:SetText(strRank)
	CJ_EndTips_KillNow:SetText(strKill)

	this:Show()
end

--================================================
-- 关闭
--================================================
function CJ_EndTips_OnHide()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_EndTips_CloseClicked()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_EndTips_Close_OnClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_EndTips_ResetPos()
	CJ_EndTips_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

