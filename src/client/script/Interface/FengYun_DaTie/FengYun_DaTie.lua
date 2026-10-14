
local g_FengYun_DaTie_Frame_UnifiedPosition

local g_FengYun_DaTie_PrepareCD = 5
local g_FengYun_DaTie_GameTimeLength = 90
local g_FengYun_DaTie_CurScore = 0

local g_FengYun_DaTie_ArrowBeginPosX = 0
local g_FengYun_DaTie_ArrowEndPosX = 480-35

local g_FengYun_DaTie_ArrowResetPosition = nil
local g_FengYun_DaTie_CurDirect = 1
local g_FengYun_DaTie_TimeIdxLimit = 39
local g_FengYun_DaTie_TimeList = {2.2,2.2,1.7,1.7,1.7,1.7,1.7,1.7,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5}
local g_FengYun_DaTie_CurLoopTime = -1  
local g_FengYun_DaTie_CurTimeIdx = 1 
local g_FengYun_DaTie_CDFlag = -1
local g_FengYun_DaTie_NPCId = -1
local g_FengYun_DaTie_ReadyToClose = 0
local g_FengYun_DaTie_IsWin = 0

local g_FengYun_DaTie_GameRuler ={
	{beginPosX = 35 ,endPosX = 148, score = 2},
	{beginPosX = 148,endPosX = 228, score = 5},
	{beginPosX = 228,endPosX = 285, score = 8},
	{beginPosX = 285,endPosX = 365, score = 5},
	{beginPosX = 365,endPosX = 480, score = 2},
}

function FengYun_DaTie_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function FengYun_DaTie_OnLoad()
	g_FengYun_DaTie_Frame_UnifiedPosition = FengYun_DaTie_Frame:GetProperty("UnifiedPosition")
	g_FengYun_DaTie_ArrowResetPosition = FengYun_DaTie_Move:GetProperty("AbsoluteXPosition")
	
end

function FengYun_DaTie_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 2026011601 then
		local nType = Get_XParam_INT(0)
		if nType == 1 then
			g_FengYun_DaTie_NPCId = Get_XParam_INT(1)
			DataPool:SelectAsTargetByObjID(g_FengYun_DaTie_NPCId)
			this:Show()
			FengYun_DaTie_Open()
		elseif nType == 2 then
			local addScore = Get_XParam_INT(1)
			g_FengYun_DaTie_CurScore = Get_XParam_INT(2)
			FengYun_DaTie_AfterAddScore(addScore)
		elseif nType == 0 then
			this:Hide()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_DaTie_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		FengYun_DaTie_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		FengYun_DaTie_OnGameOver()
	end
end

function FengYun_DaTie_BtnCD()
	KillTimer("FengYun_DaTie_BtnCD()")
	g_FengYun_DaTie_CDFlag = -1
end

function FengYun_DaTie_ThrowPauseTimer()
	KillTimer("FengYun_DaTie_ThrowPauseTimer()")
	FengYun_DaTie_ArrowGoOn()
end

function FengYun_DaTie_AfterAddScore(addScore)
	if addScore == nil or addScore < 0 or addScore > 8 then
		return 
	end
	if addScore == 2 then
		FengYun_DaTie_Miss:Show()
	elseif addScore == 5 then
		FengYun_DaTie_Good:Show()
	elseif addScore == 8 then
		FengYun_DaTie_Perfect:Show()
	end
	FengYun_DaTie_ScoreText:SetText(ScriptGlobal_Format("#{BBYRHD_220523_77}",g_FengYun_DaTie_CurScore))
	KillTimer("FengYun_DaTie_PlayerAnimation()")
	SetTimer("FengYun_DaTie","FengYun_DaTie_PlayerAnimation()", 1000)
	if g_FengYun_DaTie_CurScore >= 150 then
		FengYun_DaTie_Finish:Show()
		g_FengYun_DaTie_IsWin = 1
		FengYun_DaTie_GameOver()
	end
end

function FengYun_DaTie_PlayerAnimation()
	KillTimer("FengYun_DaTie_PlayerAnimation()")
	FengYun_DaTie_Perfect:Hide()
	FengYun_DaTie_Good:Hide()
	FengYun_DaTie_Miss:Hide()
end

function FengYun_DaTie_GameOver()
	g_FengYun_DaTie_ReadyToClose = 1
	FengYun_DaTie_ArrowPause()
	FengYun_DaTie_Button:Disable()
	FengYun_DaTie_Time:SetProperty("Timer",0)
	KillTimer("FengYun_DaTie_OnGameOver()")
	SetTimer("FengYun_DaTie","FengYun_DaTie_OnGameOver()", 1000)
end

function FengYun_DaTie_OnGameOver()
	KillTimer("FengYun_DaTie_OnGameOver()")

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GameFailed")
		Set_XSCRIPT_ScriptID(999822)
		Set_XSCRIPT_Parameter(0, g_FengYun_DaTie_IsWin)
		Set_XSCRIPT_Parameter(1, g_FengYun_DaTie_NPCId)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function FengYun_DaTie_TimeOut()
	PushDebugMessage("#{FYYR_260108_97}")
	FengYun_DaTie_GameOver()
end

function FengYun_DaTie_ButtonClicked()
	if g_FengYun_DaTie_ReadyToClose == 1 then
		return 
	end
	if g_FengYun_DaTie_CDFlag < 0 then
		local curArrowXPos = FengYun_DaTie_Move:GetProperty("AbsoluteXPosition")
		local addScore = 2
		for i,v in ipairs(g_FengYun_DaTie_GameRuler) do
			if tonumber(curArrowXPos) >= v.beginPosX and tonumber(curArrowXPos) < v.endPosX then
				addScore = v.score
				break
			end
		end

		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AddScore")
		Set_XSCRIPT_ScriptID(999822)
		Set_XSCRIPT_Parameter(0, g_FengYun_DaTie_NPCId)
		Set_XSCRIPT_Parameter(1, addScore)
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()

		g_FengYun_DaTie_CDFlag = 1
		FengYun_DaTie_ArrowPause()
		KillTimer("FengYun_DaTie_BtnCD()")
		SetTimer("FengYun_DaTie","FengYun_DaTie_BtnCD()", 1000)

		KillTimer("FengYun_DaTie_ThrowPauseTimer()")
		SetTimer("FengYun_DaTie","FengYun_DaTie_ThrowPauseTimer()", 500)
	else
		PushDebugMessage("#{FYYR_260108_105}")
	end
end

function FengYun_DaTie_ArrowReset(resetAll)
	FengYun_DaTie_Move:Tween_Reset("Position", resetAll)
	FengYun_DaTie_Move:SetProperty("AbsoluteXPosition", g_FengYun_DaTie_ArrowResetPosition)
end

function FengYun_DaTie_ArrowGoOn()
	FengYun_DaTie_Move:Tween_Play("Position", true, false)
end

function FengYun_DaTie_ArrowPause()
	FengYun_DaTie_Move:Tween_Stop("Position")
end

function FengYun_DaTie_OnTweenAniEnd()
	g_FengYun_DaTie_CurTimeIdx = g_FengYun_DaTie_CurTimeIdx + 1
	if g_FengYun_DaTie_CurTimeIdx > g_FengYun_DaTie_TimeIdxLimit then
		g_FengYun_DaTie_CurTimeIdx = 1
	end
	if g_FengYun_DaTie_CurTimeIdx < 0 then
		g_FengYun_DaTie_CurTimeIdx = 1
	end
	g_FengYun_DaTie_CurLoopTime = g_FengYun_DaTie_TimeList[g_FengYun_DaTie_CurTimeIdx]
	g_FengYun_DaTie_CurDirect = g_FengYun_DaTie_CurDirect * -1
	FengYun_DaTie_ArrowStart()
end

function FengYun_DaTie_ArrowStart()
	local from_to_info = string.format("curve:Liner mode:Once duration:%s startx:%s starty:0 endx:%s endy:0", g_FengYun_DaTie_CurLoopTime, g_FengYun_DaTie_ArrowBeginPosX, g_FengYun_DaTie_ArrowEndPosX * g_FengYun_DaTie_CurDirect)
	FengYun_DaTie_Move:Tween_SetInfo("Position", from_to_info)
	FengYun_DaTie_Move:Tween_Play("Position", true, true)
end

function FengYun_DaTie_Prepare()
	KillTimer("FengYun_DaTie_Prepare()")
	FengYun_DaTie_Countdown:Hide()

	FengYun_DaTie_Button:Enable()
	FengYun_DaTie_Time:Show()
	FengYun_DaTie_Time:SetProperty("Timer", g_FengYun_DaTie_GameTimeLength)
	FengYun_DaTie_Time:SetProperty("TextColor","ff00ff00")
	FengYun_DaTie_ScoreText:Show()
	FengYun_DaTie_ScoreText:SetText(ScriptGlobal_Format("#{BBYRHD_220523_77}",g_FengYun_DaTie_CurScore))

	g_FengYun_DaTie_CurTimeIdx = 1
	g_FengYun_DaTie_CurLoopTime = g_FengYun_DaTie_TimeList[g_FengYun_DaTie_CurTimeIdx]
	FengYun_DaTie_ArrowStart()
end

function FengYun_DaTie_Open()
	FengYun_DaTie_Finish:Hide()
	-- PushDebugMessage("#{FYYR_260108_96}")
	FengYun_DaTie_Perfect:Hide()
	FengYun_DaTie_Good:Hide()
	FengYun_DaTie_Miss:Hide()
	
	FengYun_DaTie_ScoreText:Hide()
	FengYun_DaTie_Time:Hide()
	FengYun_DaTie_Button:Disable()
	
	KillTimer("FengYun_DaTie_Prepare()")
	SetTimer("FengYun_DaTie","FengYun_DaTie_Prepare()", g_FengYun_DaTie_PrepareCD * 1000)

	FengYun_DaTie_Countdown:Show()
	FengYun_DaTie_Countdown:Play(true)

end

function FengYun_DaTie_On_ResetPos()
	FengYun_DaTie_Frame:SetProperty("UnifiedPosition", g_FengYun_DaTie_Frame_UnifiedPosition)
end

function FengYun_DaTie_OnHidden()
	FengYun_DaTie_ArrowReset(true)
	KillTimer("FengYun_DaTie_Prepare()")
	KillTimer("FengYun_DaTie_BtnCD()")
	KillTimer("FengYun_DaTie_ThrowPauseTimer()")
	KillTimer("FengYun_DaTie_OnGameOver()")
	KillTimer("FengYun_DaTie_PlayerAnimation()")
	FengYun_DaTie_Countdown:Hide()
	g_FengYun_DaTie_CurScore = 0
	g_FengYun_DaTie_CurDirect = 1
	g_FengYun_DaTie_CurLoopTime = -1  
	g_FengYun_DaTie_CurTimeIdx = 1 
	g_FengYun_DaTie_CDFlag = -1
	g_FengYun_DaTie_NPCId = -1
	g_FengYun_DaTie_ReadyToClose = 0
	g_FengYun_DaTie_IsWin = 0
end

function FengYun_DaTie_Closed()
	PushEvent("FENGYUN_YURE_CLOSE_CONFIRM", g_FengYun_DaTie_IsWin, g_FengYun_DaTie_NPCId)
end
