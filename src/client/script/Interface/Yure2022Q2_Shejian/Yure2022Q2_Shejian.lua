--版本预热活动 射箭


local g_Yure2022Q2_Shejian_Frame_UnifiedPosition_Load
local g_UI_Items = {}

local g_UICOMMAND = 99810301

local g_GameRuler ={
	{beginPosX = 49 ,endPosX = 168,animStr = "set:Yure2022Q2_2 image:Yure2022Q2_Shejian_Miss",score = 0},
	{beginPosX = 168,endPosX = 254,animStr = "set:Yure2022Q2_2 image:Yure2022Q2_Shejian_Good",score = 5},
	{beginPosX = 254,endPosX = 312,animStr = "set:Yure2022Q2_2 image:Yure2022Q2_Shejian_Perfect",score = 10},
	{beginPosX = 312,endPosX = 399,animStr = "set:Yure2022Q2_2 image:Yure2022Q2_Shejian_Good",score = 5},
	{beginPosX = 399,endPosX = 520,animStr = "set:Yure2022Q2_2 image:Yure2022Q2_Shejian_Miss",score = 0},
}
local g_ArrowResetPosition = nil
local g_ConstVar = {
	ArrowBeginPosX = 0,
	ArrowEndPosX = 520-49,
	TimeIdxLimit = 39,
	TimeList =  {2.2,2.2,1.7,1.7,1.7,1.7,1.7,1.7,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5},
	playingBtnCD = 1,
	prepareCD = 5,
	ThrowmMoveCD = 0.5,
	targetScore = 150,
	gameTimeLength = 90,
	gameOverCountDown = 1, --s
	anmiDley = 1,
	resultAnimExistTime = 0.4,
}

local g_CurDirect = 1
local g_CurTimeIdx = -1  --当前是第几个来回
local g_CurLoopTime = -1  --游标循环时间
local g_CurBtnCDTime = -1 --按钮CD时间
local g_CurScore = 0
local g_ReadyToClose = 0
local g_AddScore = 0
local g_curArrowTargetNPC = -1



function Yure2022Q2_Shejian_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	--this:RegisterEvent("ADJEST_UI_POS",false)

end

function Yure2022Q2_Shejian_OnLoad()
	Yure2022Q2_Shejian_LoadControl()
	g_Yure2022Q2_Shejian_Frame_UnifiedPosition_Load = Yure2022Q2_Shejian_Frame:GetProperty("UnifiedPosition")
	g_ArrowResetPosition = g_UI_Items.arrow:GetProperty("AbsoluteXPosition")
end
--=========
-- 装载控件
--=========
function Yure2022Q2_Shejian_LoadControl()
	g_UI_Items = {
		arrow = Yure2022Q2_Shejian_Move,
		curScore = Yure2022Q2_Shejian_ScoreText,
		watch = Yure2022Q2_Shejian_Time,
		btn = Yure2022Q2_Shejian_Button,
		resultAnim = Yure2022Q2_Shejian_Result,
		countDownAnim = Yure2022Q2_Shejian_Countdown,
	}
end
--=========
-- Event
--=========
function Yure2022Q2_Shejian_OnEvent(event)


	if (event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND )  then 
		local opt = Get_XParam_INT(0)
		if opt == 1 then--open
			if(IsWindowShow("Yure2022Q2_Shejian")) then
				PushDebugMessage("#{BBYRHD_220523_79}")
				return 
			end
			Yure2022Q2_Shejian_Open()
		elseif opt == 2 then
			--射箭返回
			local retAdd = Get_XParam_INT(1)
			Yure2022Q2_Shejian_ThrowArrowReturn(retAdd)
		elseif opt == 9 then
			--关闭界面
			Yure2022Q2_Shejian_Closed()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Yure2022Q2_Shejian_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Yure2022Q2_Shejian_Closed()

	-- elseif event == "ADJEST_UI_POS" then

	-- 	Yure2022Q2_Shejian_On_AdjustPos()


	end

end


--=========
-- 重置
--=========
function Yure2022Q2_Shejian_On_ResetPos()

	Yure2022Q2_Shejian_Frame:SetProperty("UnifiedPosition", g_Yure2022Q2_Shejian_Frame_UnifiedPosition_Load)

end

local function ArrowReset(resetAll)
	g_UI_Items.arrow:Tween_Reset("Position", resetAll)
	g_UI_Items.arrow:SetProperty("AbsoluteXPosition", g_ArrowResetPosition)
end



local function ArrowGoOn()
	g_UI_Items.arrow:Tween_Play("Position", true, false)
end

local function ArrowPause()
	g_UI_Items.arrow:Tween_Stop("Position")
end

local function ArrowStart()
	local from_to_info = string.format("curve:Liner mode:Once duration:%s startx:%s starty:0 endx:%s endy:0", g_CurLoopTime, g_ConstVar.ArrowBeginPosX, g_ConstVar.ArrowEndPosX * g_CurDirect)
	g_UI_Items.arrow:Tween_SetInfo("Position", from_to_info)
	g_UI_Items.arrow:Tween_Play("Position", true, true)
end

local function GameStart()
	g_UI_Items.btn:Enable()
	g_CurTimeIdx = 1
	g_CurLoopTime = g_ConstVar.TimeList[g_CurTimeIdx]
	ArrowStart()
end

-- [relPos)
local function CalcScore(relPos)
	local addScore = 0
	for i,v in ipairs(g_GameRuler) do
		if relPos >= v.beginPosX and relPos < v.endPosX then
			addScore = v.score
			break
		end
	end
	return addScore
end

local function GetAnimation(addScore)
	local anim = ""
	for i,v in ipairs(g_GameRuler) do
		if addScore == v.score then
			anim = v.animStr
		end
	end
	return anim
end

local function GameOver(success)
	--倒计时
	KillTimer("Yure2022Q2_Shejian_OnGameOver()")
	SetTimer("Yure2022Q2_Shejian","Yure2022Q2_Shejian_OnGameOver()", g_ConstVar.gameOverCountDown * 1000)
	if success == 1 then
		PushDebugMessage("#{BBYRHD_220523_84}")
	else
		PushDebugMessage("#{BBYRHD_220523_145}")
	end
	g_ReadyToClose = 1
	--暂停控件
	ArrowPause()
	g_UI_Items.btn:Disable()
	g_UI_Items.watch:SetProperty("Timer",0)
end



--=========
-- 关闭
--=========
function Yure2022Q2_Shejian_Closed()
	ArrowReset(true)
	g_CurDirect = 1
	g_CurTimeIdx = -1  --当前是第几个来回
	g_CurLoopTime = -1  --游标循环时间
	g_CurBtnCDTime = -1 --按钮CD时间
	g_CurScore = 0
	g_ReadyToClose = 0
	g_AddScore = 0
	g_curArrowTargetNPC = -1
	this:Hide()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnGameEnd")
	Set_XSCRIPT_ScriptID(998136)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


function Yure2022Q2_Shejian_OnTweenAniEnd()
	g_CurTimeIdx = g_CurTimeIdx + 1
	if g_CurTimeIdx > g_ConstVar.TimeIdxLimit then
		g_CurTimeIdx = g_ConstVar.TimeIdxLimit
	end
	if g_CurTimeIdx < 0 then
		g_CurTimeIdx = 1
	end
	g_CurLoopTime = g_ConstVar.TimeList[g_CurTimeIdx]
	g_CurDirect = g_CurDirect * -1
	ArrowStart()
end

-- 打开
function Yure2022Q2_Shejian_Open()
	ArrowReset(true)
	-- PushDebugMessage("AbsoluteXPosition:"..tostring(g_UI_Items.arrow:GetProperty("AbsoluteXPosition")))
	-- PushDebugMessage("RelativeXPosition:"..tostring(g_UI_Items.arrow:GetProperty("RelativeXPosition")))
	-- PushDebugMessage("XPosition:"..tostring(g_UI_Items.arrow:GetProperty("XPosition")))
	g_CurDirect = 1
	g_CurTimeIdx = -1  --当前是第几个来回
	g_CurLoopTime = -1  --游标循环时间
	g_CurBtnCDTime = -1 --按钮CD时间
	g_CurScore = 0
	g_ReadyToClose = 0 
	g_AddScore = 0
	g_curArrowTargetNPC = Get_XParam_INT(1)
	DataPool:SelectAsTargetByObjID(g_curArrowTargetNPC)
	--倒计时
	KillTimer("Yure2022Q2_Shejian_Prepare()")
	SetTimer("Yure2022Q2_Shejian","Yure2022Q2_Shejian_Prepare()", g_ConstVar.prepareCD * 1000)
	g_UI_Items.btn:Disable()
	g_UI_Items.resultAnim:Hide()
	g_UI_Items.countDownAnim:Show()
	g_UI_Items.countDownAnim:Play(true)
	g_UI_Items.watch:Hide()
	g_UI_Items.curScore:Hide()
	this:Show()
	
	PushDebugMessage(ScriptGlobal_Format("#{BBYRHD_220523_116}", g_ConstVar.prepareCD))
end

--点击投出按钮
function Yure2022Q2_Shejian_ButtonClicked()
	if g_ReadyToClose == 1 then
		return 
	end
	if g_CurBtnCDTime < 0 then
		local curArrowXPos = g_UI_Items.arrow:GetProperty("AbsoluteXPosition")
		local addScore = CalcScore(tonumber(curArrowXPos))
		if addScore == nil then
			addScore =0
		end
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ThrowArrow")
		Set_XSCRIPT_ScriptID(998136)
		Set_XSCRIPT_Parameter(0,g_curArrowTargetNPC);
		Set_XSCRIPT_Parameter(1,addScore);
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		--按钮进入CD
		KillTimer("Yure2022Q2_Shejian_BtnCD()")
		SetTimer("Yure2022Q2_Shejian","Yure2022Q2_Shejian_BtnCD()", g_ConstVar.playingBtnCD *1000)
		g_CurBtnCDTime =  g_ConstVar.playingBtnCD
		--箭头暂停0.5s
		KillTimer("Yure2022Q2_Shejian_ThrowPauseTimer()")
		SetTimer("Yure2022Q2_Shejian","Yure2022Q2_Shejian_ThrowPauseTimer()", g_ConstVar.ThrowmMoveCD * 1000)
		ArrowPause()
	else
		PushDebugMessage("#{BBYRHD_220523_80}")
	end
end

function Yure2022Q2_Shejian_ThrowArrowReturn(retAdd)
	if retAdd < 0 then
		return 
	end
	
	if retAdd ~= nil then
		g_CurScore = g_CurScore + retAdd
		g_AddScore = retAdd
	end
	g_UI_Items.curScore:SetText(ScriptGlobal_Format("#{BBYRHD_220523_77}",g_CurScore))
	if g_CurScore >= g_ConstVar.targetScore then
		--任务完成了
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MissonCom")
		Set_XSCRIPT_ScriptID(998092)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		GameOver(1)
		return 
	end
	--延迟1s播动画
	KillTimer("Yure2022Q2_Shejian_PlayerAnimation()")
	SetTimer("Yure2022Q2_Shejian","Yure2022Q2_Shejian_PlayerAnimation()", g_ConstVar.anmiDley * 1000)
end

function Yure2022Q2_Shejian_BtnCD()
	KillTimer("Yure2022Q2_Shejian_BtnCD()")
	g_CurBtnCDTime = -1	
end

function Yure2022Q2_Shejian_ThrowPauseTimer()
	KillTimer("Yure2022Q2_Shejian_ThrowPauseTimer()")
	ArrowGoOn()
end

function Yure2022Q2_Shejian_Prepare()
	KillTimer("Yure2022Q2_Shejian_Prepare()")
	g_UI_Items.btn:Enable()
	g_UI_Items.countDownAnim:Hide()
	g_UI_Items.watch:Show()
	g_UI_Items.watch:SetProperty("Timer",g_ConstVar.gameTimeLength)
	g_UI_Items.watch:SetProperty("TextColor","ff00ff00")-- 直接变色
	g_UI_Items.curScore:Show()
	g_UI_Items.curScore:SetText(ScriptGlobal_Format("#{BBYRHD_220523_77}",g_CurScore))
	GameStart()
end

function Yure2022Q2_Shejian_PlayerAnimation()
	KillTimer("Yure2022Q2_Shejian_PlayerAnimation()")
	--给醒目提示
	--local restTime = g_UI_Items.watch:GetProperty("Timer")
	if g_AddScore == 0 then
		PushDebugMessage("#{BBYRHD_220523_81}")
	elseif g_AddScore == 5 then
		PushDebugMessage(ScriptGlobal_Format("#{BBYRHD_220523_82}",g_CurScore))
	elseif g_AddScore == 10 then
		PushDebugMessage(ScriptGlobal_Format("#{BBYRHD_220523_83}",g_CurScore))
	end
	local animStr = GetAnimation(g_AddScore)
	if animStr~= nil  then
		g_UI_Items.resultAnim:SetProperty("Image", animStr )
		g_UI_Items.resultAnim:Show()
		KillTimer("Yure2022Q2_Shejian_ResultAniHide()")
		SetTimer("Yure2022Q2_Shejian","Yure2022Q2_Shejian_ResultAniHide()", g_ConstVar.resultAnimExistTime * 1000)
	end
end

function Yure2022Q2_Shejian_TimeOut()
	if g_CurScore >= g_ConstVar.targetScore then
		GameOver(1)
	else
		GameOver(0)
	end
end

function Yure2022Q2_Shejian_OnGameOver()
	KillTimer("Yure2022Q2_Shejian_OnGameOver()")
	Yure2022Q2_Shejian_Closed()
end

function Yure2022Q2_Shejian_ResultAniHide()
	KillTimer("Yure2022Q2_Shejian_ResultAniHide()")
	g_UI_Items.resultAnim:Hide()
end