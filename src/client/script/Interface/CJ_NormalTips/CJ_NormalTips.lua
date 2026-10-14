-- 基础界面

local g_unifiedposistion
local g_ui_command = 99932102
local g_timer = 0
local g_relivetimer = 0
local g_livingcount = 0
local g_killnum = 0
function CJ_NormalTips_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("TLCJ_OPENTIPS")
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)
end

function CJ_NormalTips_OnLoad()
	g_unifiedposistion = CJ_NormalTips_Frame:GetProperty("UnifiedPosition")
end

function CJ_NormalTips_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then
		CJ_NormalTips_OnShow()
	elseif event == "TLCJ_OPENTIPS" then
		CJ_NormalTips_OnShow_ByMini(arg0,arg1,arg2,arg3)
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_NormalTips_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_NormalTips_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		CJ_NormalTips_CloseClicked()
	elseif(event == "PLAYER_LEAVE_WORLD") then
		CJ_NormalTips_CloseClicked()
	end

end

function CJ_NormalTips_OnShow()

	local killerNum = Get_XParam_INT(0)
	local livingCount = Get_XParam_INT(1)
	local shrinkTime = Get_XParam_INT(2)
	local socre = Get_XParam_INT(3)
	local relivetime = Get_XParam_INT(4)
	
	local strKillerNum = ScriptGlobal_Format("#{TLCJ_20240709_199}", killerNum)
	CJ_NormalTips_Kill_Num:SetText(strKillerNum)

	local strLivingCount = ScriptGlobal_Format("#{TLCJ_20240709_85}", livingCount)
	CJ_NormalTips_Survival_Num:SetText(strLivingCount)

	if shrinkTime < 0 then
		shrinkTime = 0
	end
	
	local strShrinkTime = ScriptGlobal_Format("#{TLCJ_20240709_86}", shrinkTime)
	CJ_NormalTips_Time_Num:SetText(strShrinkTime)

	--local strScore = ScriptGlobal_Format("#{TLCJ_20240709_246}", socre)
	CJ_NormalTips_Explain_Text:SetText("#{TLCJ_20240709_298}")
	
	if relivetime > 0 then
		local strReliveTime = ScriptGlobal_Format("#{TLCJ_20240709_445}", relivetime)
		CJ_NormalTips_ReliveTime_Num:SetText(strReliveTime)
		CJ_NormalTips_ReliveTimeClockClient:Show()
	else
		CJ_NormalTips_ReliveTimeClockClient:Hide()
	end

	-- 消失倒计时
	g_timer = shrinkTime
	g_relivetimer = relivetime
	g_livingcount = livingCount
	g_killnum = killerNum

	KillTimer("CJ_NormalTips_Timer()")

	if IsWindowShow("CJ_NormalTipsMini") then
		PushEvent("TLCJ_OPENTIPSMINI", g_timer, g_relivetimer, g_livingcount, g_killnum)
		this:Hide()
	else
		SetTimer("CJ_NormalTips","CJ_NormalTips_Timer()", 1*1000)

		this:Show()
	end

end

function CJ_NormalTips_OnShow_ByMini(arg0,arg1,arg2,arg3)
	local killerNum = tonumber(arg0)
	local livingCount = tonumber(arg1)
	local shrinkTime = tonumber(arg2)
	local relivetime = tonumber(arg3)

	local strKillerNum = ScriptGlobal_Format("#{TLCJ_20240709_199}", killerNum)
	CJ_NormalTips_Kill_Num:SetText(strKillerNum)

	local strLivingCount = ScriptGlobal_Format("#{TLCJ_20240709_85}", livingCount)
	CJ_NormalTips_Survival_Num:SetText(strLivingCount)

	if shrinkTime < 0 then
		shrinkTime = 0
	end

	local strShrinkTime = ScriptGlobal_Format("#{TLCJ_20240709_86}", shrinkTime)
	CJ_NormalTips_Time_Num:SetText(strShrinkTime)

	CJ_NormalTips_Explain_Text:SetText("#{TLCJ_20240709_298}")
	
	if relivetime > 0 then
		local strReliveTime = ScriptGlobal_Format("#{TLCJ_20240709_445}", relivetime)
		CJ_NormalTips_ReliveTime_Num:SetText(strReliveTime)
		CJ_NormalTips_ReliveTimeClockClient:Show()
	else
		CJ_NormalTips_ReliveTimeClockClient:Hide()
	end

	-- 消失倒计时
	g_timer = shrinkTime
	g_relivetimer = relivetime
	g_livingcount = livingCount
	g_killnum = killerNum

	--local szLog = string.format("UI_COMMAND(2),%d,%d,%d,%d", g_killnum, g_livingcount, g_timer, g_relivetimer) 
	--Lua_TDU_Log(szLog)

	KillTimer("CJ_NormalTips_Timer()")

	if IsWindowShow("CJ_NormalTipsMini") then
		--PushEvent("TLCJ_OPENTIPSMINI", g_timer, g_relivetimer, g_livingcount, g_killnum)
		this:Hide()
	else
		SetTimer("CJ_NormalTips","CJ_NormalTips_Timer()", 1*1000)

		this:Show()
	end

end

function CJ_NormalTips_Timer()
	g_timer = g_timer - 1
	g_relivetimer = g_relivetimer - 1

	if g_timer >= 0 then
		local strShrinkTime = ScriptGlobal_Format("#{TLCJ_20240709_86}", g_timer)
		CJ_NormalTips_Time_Num:SetText(strShrinkTime)

		if g_relivetimer > 0 then
			local strReliveTime = ScriptGlobal_Format("#{TLCJ_20240709_445}", g_relivetimer)
			CJ_NormalTips_ReliveTime_Num:SetText(strReliveTime)
			CJ_NormalTips_ReliveTimeClockClient:Show()
		else
			CJ_NormalTips_ReliveTimeClockClient:Hide()
		end
	end

	if g_timer == 0 then
		KillTimer("CJ_NormalTips_Timer()")
	end
end

--================================================
-- 关闭
--================================================
function CJ_NormalTips_OnHide()
	KillTimer("CJ_NormalTips_Timer()")
end

--================================================
-- 关闭
--================================================
function CJ_NormalTips_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_NormalTips_ResetPos()
	CJ_NormalTips_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function CJ_NormalTips_MissonBtn_Clicked()
	PushEvent("TLCJ_BATTLE_MISSIONUI_SHOW")
end

function CJ_NormalTips_LeaveBtn_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		if TLCJ:IsInTLCJScene_Team() > 0 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ClientAskLeave" )
				Set_XSCRIPT_ScriptID(999337)
				Set_XSCRIPT_Parameter(0, 0)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ClientAskLeave" )
				Set_XSCRIPT_ScriptID(999321)
				Set_XSCRIPT_Parameter(0, 0)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
	end
end

function CJ_NormalTips_Btn_Clicked()
	PushEvent("TLCJ_OPENTIPSMINI", g_timer, g_relivetimer, g_livingcount, g_killnum)
	this:Hide()
end