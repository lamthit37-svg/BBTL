-- 等待救援界面

local g_unifiedposistion
local g_ui_command = 99933710
local g_ui_command_end = 99932104
local g_ui_command_end2 = 99932109
local g_ui_command_end3 = 99933711
local g_ui_command_pause = 99933712
local g_ui_command_sync = 99933713

local g_timer = 0
local g_timer_pause = 0
local g_killName = ""
function CJ_Dying_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("RELIVE_HIDE",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CJ_Dying_OnLoad()
	g_unifiedposistion = CJ_Dying_Frame:GetProperty("UnifiedPosition")
end

function CJ_Dying_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then
		CJ_Dying_OnShow()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_ui_command_end then
		CJ_Dying_CloseClicked()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_ui_command_end2 then
		CJ_Dying_CloseClicked()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_ui_command_end3 then
		CJ_Dying_CloseClicked()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_ui_command_pause then
		CJ_Dying_OnPause()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_ui_command_sync then
		CJ_Dying_OnRefresh()
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_Dying_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_Dying_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CJ_Dying_CloseClicked()
	elseif (event == "RELIVE_HIDE") then
		CJ_Dying_CloseClicked()
	end

end

function CJ_Dying_OnShow()

	g_timer = Get_XParam_INT(0)
	g_killName = Get_XParam_STR(0)

	g_timer_pause = 0

	local szTips = 	ScriptGlobal_Format("#{TLCJ_20240709_111}", g_killName, g_timer)
	CJ_Dying_Text:SetText(szTips)

	KillTimer("CJ_Dying_Timer()")
	SetTimer("CJ_Dying","CJ_Dying_Timer()", 1*1100)

	this:Show()
end

function CJ_Dying_OnPause()
	if not this:IsVisible() then
		return
	end

	g_timer_pause = g_timer

	g_timer = Get_XParam_INT(0)
end

function CJ_Dying_OnRefresh()
	if not this:IsVisible() then
		return
	end

	g_timer = Get_XParam_INT(0)

	g_timer_pause = 0

	local szTips = 	ScriptGlobal_Format("#{TLCJ_20240709_111}", g_killName, g_timer)
	CJ_Dying_Text:SetText(szTips)

	KillTimer("CJ_Dying_Timer()")
	SetTimer("CJ_Dying","CJ_Dying_Timer()", 1100)
end

function CJ_Dying_Timer()
	g_timer = g_timer - 1 
	if g_timer > 0 then
		if g_timer_pause ~= nil and g_timer_pause > 0 then
			local szTips = 	ScriptGlobal_Format("#{TLCJ_20240709_111}", g_killName, g_timer_pause)
			CJ_Dying_Text:SetText(szTips)
		else
			local szTips = 	ScriptGlobal_Format("#{TLCJ_20240709_111}", g_killName, g_timer)
			CJ_Dying_Text:SetText(szTips)
		end
	else
		KillTimer("CJ_Dying_Timer()")
		this:Hide()
	end
end

--================================================
-- 关闭
--================================================
function CJ_Dying_CloseClicked()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_Dying_OnHide()
	g_timer_pause = 0
	KillTimer("CJ_Dying_Timer()")
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_Dying_ResetPos()
	CJ_Dying_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

