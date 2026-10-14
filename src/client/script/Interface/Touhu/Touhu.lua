--******************************************************************************
-- 投壶界面
--******************************************************************************
local g_Touhu_Frame_UnifiedXPosition;
local g_Touhu_Frame_UnifiedYPosition;

--UI
local g_Touhu_CountInfo  --计数信息
local g_Touhu_Arrow  --滑动箭头
local g_Touhu_Btn   --交互按钮
local g_Touhu_ArrowAnima
local g_Touhu_Miss
local g_Touhu_Hit
local g_Touhu_CountDown  --倒计时

local g_curPotNPC = -1


--计数
local g_Touhu_Time = -1 --显示的数字：5、60秒倒计时
local g_Touhu_Count = 0 --投中数量

local g_Touhu_CurBtnCDTime = -1 --按钮CD时间
local g_Touhu_CurLoopTime = -1  --游标循环时间
local g_Touhu_CurDirect = 1

local g_Touhu_CurThrowResult = -1  --本次投掷结果

local g_Touhu_CurTimeIdx = -1  --当前是第几个来回

--常量
local g_Touhu_BonusNum = 50 --投壶奖励线
local g_Touhu_Arrow_startX = 0
local g_Touhu_Arrow_endX = 455
local g_Touhu_PreparingTime = 5  --准备时间
local g_Touhu_GameTime = 60   --游戏时间
local g_Touhu_StdBtnCDTime = 1   --按钮CD时间
local g_Touhu_Speed = 1  --游标运动速度
local g_Touhu_ArrowOriX = 0
local g_Touhu_SkillDelayTime = 1.5  --技能延迟时间
local g_Touhu_EffectDelayTime = 0.5  --特效延迟时间
local g_Touhu_TimeIdxLimit = 39
local g_Touhu_TimeList = {2.2,2.2,1.7,1.7,1.7,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5,1.5}

--===============================================
-- OnLoad()
--===============================================
function Touhu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function Touhu_OnLoad()

	-- 保存界面的默认相对位置
	g_Touhu_Frame_UnifiedXPosition = Touhu_Frame:GetProperty("UnifiedXPosition");
	g_Touhu_Frame_UnifiedYPosition = Touhu_Frame:GetProperty("UnifiedYPosition");
	
	
	--计数信息
	g_Touhu_CountInfo = Touhu_DragTitle
	--滑动箭头
	g_Touhu_Arrow = Touhu_Arrow_All
	g_Touhu_ArrowOriX = g_Touhu_Arrow:GetProperty("AbsoluteXPosition")
	--按钮
	g_Touhu_Btn = Touhu_Btn
	g_Touhu_CountInfo:SetText(ScriptGlobal_Format("#{XJH_210826_60}",0))
	
	--箭头动画
	g_Touhu_ArrowAnima = Touhu_Arrow_Animate
	--投中
	g_Touhu_Hit = Touhu_Hit
	--未投中
	g_Touhu_Miss = Touhu_Miss
		
	g_Touhu_Time = 5
	
	g_Touhu_CountDown = Touhu_Countdown
	g_Touhu_CountDown:Hide()
	
	g_Touhu_Hit:Hide()
	g_Touhu_Miss:Hide()
	
	
end


--===============================================
-- OnEvent()
--===============================================

function Touhu_OnEvent(event)
	if(event == "UI_COMMAND") then

		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 88876902 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				
				local npcid = Get_XParam_INT(1)

				KillTimer("Touhu_Zhunbei()")
				KillTimer("Touhu_Close_Zhunbei()")
				KillTimer("Touhu_Jinxing()")
				KillTimer("Touhu_Close_Jinxing()")

				g_Touhu_Count = 0
				
				g_Touhu_UIType = 1
				
				g_Touhu_Time = g_Touhu_PreparingTime
				PushDebugMessage(ScriptGlobal_Format("#{XJH_210826_41}", g_Touhu_Time))
				SetTimer("Touhu","Touhu_Zhunbei()", 1000)
				SetTimer("Touhu","Touhu_Close_Zhunbei()", g_Touhu_PreparingTime*1000)
				
				g_Touhu_Btn:Disable()
				Touhu_ArrowReset(true)
				g_Touhu_Hit:Hide()
				g_Touhu_Miss:Hide()
				
				g_Touhu_CountDown:Show()
				g_Touhu_CountDown:Play(true)
				
				DataPool:SelectAsTargetByObjID(npcid)
				g_curPotNPC = npcid


				this:Show()
			elseif param == 0 then
				Touhu_Close()
				return				
			end
		
		--更新拾取树叶数量
		elseif arg == 88876903 then
			g_Touhu_Count = Get_XParam_INT(0)
			g_Touhu_CountInfo:SetText(ScriptGlobal_Format("#{XJH_210826_60}",g_Touhu_Count))
			 --收集满100个后，强制进入倒计时5秒关闭界面流程
			if g_Touhu_Count >= g_Touhu_BonusNum then
				Touhu_Close_Jinxing()
			end
		elseif arg == 88877101 then  --投掷结果
			local throwResult = Get_XParam_INT(0)
			Touhu_AfterThrow(throwResult)
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		Touhu_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		Touhu_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Touhu_Close()
	end
end

function Touhu_AfterThrow(throwResult)

	SetTimer("Touhu","Touhu_ThrowAnimaPause()", g_Touhu_EffectDelayTime * 1000)
	Touhu_ArrowPause()	
	g_Touhu_ArrowAnima:Play(true)
	g_Touhu_CurThrowResult = throwResult
	SetTimer("Touhu","Touhu_ThrowSkillDelay()", g_Touhu_SkillDelayTime * 1000)
end


--===============================================
-- 刷新5秒倒计时文字显示：X秒后开始投壶
--===============================================	
function Touhu_Zhunbei()
	g_Touhu_Time = g_Touhu_Time - 1
	PushDebugMessage(ScriptGlobal_Format("#{XJH_210826_41}", g_Touhu_Time))
end

--===============================================
-- 关闭倒计时文字显示：X秒后开始投壶
-- 开启1分钟倒计时
--===============================================	
function Touhu_Close_Zhunbei()
	--停止倒计时文字显示
	KillTimer("Touhu_Zhunbei()")
	KillTimer("Touhu_Close_Zhunbei()")
	
	--开启30s倒计时
	g_Touhu_Time = g_Touhu_GameTime
	--PushDebugMessage(ScriptGlobal_Format("#{XJH_210826_18}", g_Touhu_Time))
	SetTimer("Touhu","Touhu_Jinxing()", 1000)	
	SetTimer("Touhu","Touhu_Close_Jinxing()", g_Touhu_GameTime*1000)
	
	g_Touhu_CountDown:Hide()
	g_Touhu_CountDown:Play(false)
	
	Touhu_GameStart()

end

--===============================================
-- 刷新60秒倒计时文字显示：X秒后停止投壶
--===============================================	
function Touhu_Jinxing()
	g_Touhu_Time = g_Touhu_Time - 1
	---PushDebugMessage(ScriptGlobal_Format("#{XJH_210826_18}", g_Touhu_Time))
end

--===============================================
-- 关闭倒计时文字显示：X秒后停止投壶
-- 60秒计时满后，更新文字
--===============================================	
function Touhu_Close_Jinxing()
	--停止倒计时文字显示
	KillTimer("Touhu_Jinxing()")
	KillTimer("Touhu_Close_Jinxing()")
	
	--倒计时结束
	Touhu_TimeUp()
end

function Touhu_GameStart()
	Touhu_ArrowReset(true)
	g_Touhu_Btn:Enable()
	g_Touhu_CurTimeIdx = 1
	g_Touhu_CurLoopTime = g_Touhu_TimeList[g_Touhu_CurTimeIdx]
	Touhu_ArrowStart()

end

function Touhu_Arrow_OnTweenAniEnd()
	--g_Touhu_CurLoopTime = g_Touhu_CurLoopTime - g_Touhu_Speed * 0.1
	--if g_Touhu_CurLoopTime < g_Touhu_MinLoopTime then
	--	g_Touhu_CurLoopTime = g_Touhu_MinLoopTime
	--end
	g_Touhu_CurTimeIdx = g_Touhu_CurTimeIdx + 1
	if g_Touhu_CurTimeIdx > g_Touhu_TimeIdxLimit then
		g_Touhu_CurTimeIdx = g_Touhu_TimeIdxLimit
	end
	if g_Touhu_CurTimeIdx < 0 then
		g_Touhu_CurTimeIdx = 1
	end
	g_Touhu_CurLoopTime = g_Touhu_TimeList[g_Touhu_CurTimeIdx]
	g_Touhu_CurDirect = g_Touhu_CurDirect * -1
	Touhu_ArrowStart()
end

function Touhu_ArrowStart()

	local from_to_info = string.format("curve:Liner mode:Once duration:%s startx:%s starty:0 endx:%s endy:0", g_Touhu_CurLoopTime, g_Touhu_Arrow_startX, g_Touhu_Arrow_endX * g_Touhu_CurDirect)
	g_Touhu_Arrow:Tween_SetInfo("Position", from_to_info)
	g_Touhu_Arrow:Tween_Play("Position", true, true)
end

function Touhu_ArrowPause()
	g_Touhu_Arrow:Tween_Stop("Position")
end

function Touhu_ArrowGoOn()
	g_Touhu_Arrow:Tween_Play("Position", true, false)
end

function Touhu_ArrowReset(resetAll)
	g_Touhu_Arrow:Tween_Reset("Position", resetAll)
	g_Touhu_Arrow:SetProperty("AbsoluteXPosition", g_Touhu_ArrowOriX)
end


function Touhu_ThrowBtnCD()
	g_Touhu_CurBtnCDTime = g_Touhu_CurBtnCDTime - 1
	--PushDebugMessage(ScriptGlobal_Format("CD还剩"..g_Touhu_CurBtnCDTime.."秒"))
end

function Touhu_Close_ThrowBtnCD()
	--停止倒计时文字显示
	KillTimer("Touhu_ThrowBtnCD()")
	KillTimer("Touhu_Close_ThrowBtnCD()")
	--按钮恢复
	g_Touhu_CurBtnCDTime = -1	
end



function Touhu_ThrowAnimaPause()
	KillTimer("Touhu_ThrowAnimaPause()")
	Touhu_ArrowGoOn()
	g_Touhu_ArrowAnima:Play(false)
end

function Touhu_ThrowSkillDelay()
	KillTimer("Touhu_ThrowSkillDelay()")
	
	if g_Touhu_CurThrowResult == 1 or g_Touhu_CurThrowResult == 0 then
		--客户端播特效
		if g_Touhu_CurThrowResult == 1 then  --投中
			g_Touhu_Hit:Show()
			g_Touhu_Hit:Play(true)
		else  --未投中
			g_Touhu_Miss:Show()
			g_Touhu_Miss:Play(true)
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("RealThrow")
			Set_XSCRIPT_ScriptID(888771)
			Set_XSCRIPT_Parameter(0,g_Touhu_CurThrowResult);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	g_Touhu_CurThrowResult = -1
end




--===============================================
-- 投壶结束
--===============================================	
function Touhu_TimeUp()

	--判断是否成功
	
	
	--关闭界面
	Touhu_Close()
end

function Touhu_Throw()

	if g_Touhu_CurBtnCDTime < 0 then
		---PushDebugMessage("Throw!!!!")
		local curArrowXPos = g_Touhu_Arrow:GetProperty("AbsoluteXPosition")
		local curArrowRelXPos = curArrowXPos - g_Touhu_ArrowOriX
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ThrowArrow")
			Set_XSCRIPT_ScriptID(888771)
			Set_XSCRIPT_Parameter(0,curArrowRelXPos);
			Set_XSCRIPT_Parameter(1,g_curPotNPC);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()		
		SetTimer("Touhu","Touhu_ThrowBtnCD()", 1000)
		SetTimer("Touhu","Touhu_Close_ThrowBtnCD()", g_Touhu_StdBtnCDTime*1000)	
		--按钮进入CD
		g_Touhu_CurBtnCDTime = g_Touhu_StdBtnCDTime
	else
		PushDebugMessage("#{XJH_210826_44}")
	end
end


function Touhu_Close()
	Touhu_OnHiden()
end


--===============================================
-- OnHiden
--===============================================
function Touhu_OnHiden()
	g_Touhu_CurBtnCDTime = -1
	g_Touhu_CurLoopTime = -1
	g_Touhu_CurDirect = 1
	g_Touhu_CurTimeIdx = -1
	g_curPotNPC = -1
	Touhu_ArrowReset(true)
	g_Touhu_Hit:Play(false)
	g_Touhu_Miss:Play(false)
	g_Touhu_ArrowAnima:Play(false)
	g_Touhu_CountInfo:SetText(ScriptGlobal_Format("#{XJH_210826_60}",0))
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Touhu_Frame_On_ResetPos()
	Touhu_Frame : SetProperty("UnifiedXPosition", g_Touhu_Frame_UnifiedXPosition);
	Touhu_Frame : SetProperty("UnifiedYPosition", g_Touhu_Frame_UnifiedYPosition);
end
