-- 界面最小化

local g_unifiedposistion = nil
local g_ui_command = 99932102
local g_timer = 0
local g_relivetimer = 0
local g_livingcount = 0
local g_killnum = 0

function CJ_NormalTipsMini_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("TLCJ_OPENTIPSMINI")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CJ_NormalTipsMini_OnLoad()
	g_unifiedposistion = CJ_NormalTipsMini_Frame:GetProperty("UnifiedPosition")
end

function CJ_NormalTipsMini_OnEvent(event)

	if ( event == "TLCJ_OPENTIPSMINI" ) then
		CJ_NormalTipsMini_OnShow(arg0,arg1,arg2,arg3)
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_NormalTipsMini_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_NormalTipsMini_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		CJ_NormalTipsMini_CloseClicked()
	end

end

function CJ_NormalTipsMini_OnShow(arg0,arg1,arg2,arg3)
	if IsWindowShow("CJ_NormalTips") then
		CloseWindow("CJ_NormalTips", true)
	end
	
	CJ_NormalTipsMini_Refresh(arg0,arg1,arg2,arg3)
	this:Show()
end

--================================================
-- 关闭
--================================================
function CJ_NormalTipsMini_OnClose()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_NormalTipsMini_OnHide()
	KillTimer("CJ_NormalTipsMini_Timer()")
end

--================================================
-- 关闭
--================================================
function CJ_NormalTipsMini_CloseClicked()
	this:Hide()
end

function CJ_NormalTipsMini_Btn_Clicked()
	this:Hide()

	PushEvent("TLCJ_OPENTIPS", g_killnum, g_livingcount, g_timer, g_relivetimer)
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_NormalTipsMini_ResetPos()
	if g_unifiedposistion ~= nil then
		CJ_NormalTipsMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
	end
end


function CJ_NormalTipsMini_Refresh(arg0,arg1,arg2,arg3)

	local shrinkTime = tonumber(arg0)
	local relivetime = tonumber(arg1)
	local livingCount = tonumber(arg2)
	local killnum = tonumber(arg3)

	if shrinkTime < 0 then
		shrinkTime = 0
	end
	
	local strShrinkTime = ScriptGlobal_Format("#{TLCJ_20240709_86}", shrinkTime)
	CJ_NormalTipsMini_Time_Num:SetText(strShrinkTime)
	
	local strLivingCount = ScriptGlobal_Format("#{TLCJ_20240709_85}", livingCount)
	CJ_NormalTipsMini_ReliveTime_Num:SetText(strLivingCount)

	-- if relivetime > 0 then
	-- 	local strReliveTime = ScriptGlobal_Format("#{TLCJ_20240709_445}", relivetime)
	-- 	CJ_NormalTipsMini_ReliveTime_Num:SetText(strReliveTime)
	-- 	CJ_NormalTipsMini_ReliveTimeClockClient:Show()
	-- else
	-- 	CJ_NormalTipsMini_ReliveTimeClockClient:Hide()
	-- end

	-- 消失倒计时
	g_timer = shrinkTime
	g_relivetimer = relivetime
	g_livingcount = livingCount
	g_killnum = killnum

	KillTimer("CJ_NormalTipsMini_Timer()")
	SetTimer("CJ_NormalTipsMini","CJ_NormalTipsMini_Timer()", 1*1000)
end

function CJ_NormalTipsMini_Timer()
	g_timer = g_timer - 1
	g_relivetimer = g_relivetimer - 1

	if g_timer >= 0 then
		local strShrinkTime = ScriptGlobal_Format("#{TLCJ_20240709_86}", g_timer)
		CJ_NormalTipsMini_Time_Num:SetText(strShrinkTime)

		-- if g_relivetimer > 0 then
		-- 	local strReliveTime = ScriptGlobal_Format("#{TLCJ_20240709_445}", g_relivetimer)
		-- 	CJ_NormalTipsMini_ReliveTime_Num:SetText(strReliveTime)
		-- 	CJ_NormalTipsMini_ReliveTimeClockClient:Show()
		-- else
		-- 	CJ_NormalTipsMini_ReliveTimeClockClient:Hide()
		-- end
	end

	if g_timer == 0 then
		KillTimer("CJ_NormalTipsMini_Timer()")
	end
end