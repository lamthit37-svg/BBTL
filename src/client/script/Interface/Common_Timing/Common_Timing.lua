--******************************************************************************
-- 倒计时界面
--******************************************************************************
local g_Common_Timing_Frame_UnifiedXPosition;
local g_Common_Timing_Frame_UnifiedYPosition;

--UI
local g_Common_Timing_Animate  --倒计时动画

--计数
local g_Common_Timing_CountDownTime = 5--剩余时间

--常量
local g_Common_Timing_Time = 5  --成功时最长显示时间

--===============================================
-- OnLoad()
--===============================================
function Common_Timing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function Common_Timing_OnLoad()

	-- 保存界面的默认相对位置
	g_Common_Timing_Frame_UnifiedXPosition = Common_Timing_Frame:GetProperty("UnifiedXPosition");
	g_Common_Timing_Frame_UnifiedYPosition = Common_Timing_Frame:GetProperty("UnifiedYPosition");

	--倒计时动画
	g_Common_Timing_Animate = Common_Timing_Animate

end


--===============================================
-- OnEvent()
--===============================================

function Common_Timing_OnEvent(event)
	if(event == "UI_COMMAND") then

		local arg = tonumber(arg0)

		--打开界面
		if arg == 99896401 then
			local param = Get_XParam_INT(0)
			if param == 1 then

				KillTimer("Common_Timing_CountDown()")
				KillTimer("Common_Timing_Close_CountDown()")

				g_Common_Timing_CountDownTime = g_Common_Timing_Time

				SetTimer("Common_Timing","Common_Timing_CountDown()", 1000)
				SetTimer("Common_Timing","Common_Timing_Close_CountDown()", g_Common_Timing_Time*1000)
				g_Common_Timing_Animate:Play(true)

                PushDebugMessage("倒计时5秒钟")
				this:Show()
			elseif param == 0 then
				Common_Timing_Close()
			end
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		Common_Timing_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		Common_Timing_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Common_Timing_Close()
	end
end

--===============================================
-- 游戏开始 每秒更新界面倒计时
--===============================================	
function Common_Timing_CountDown()
	g_Common_Timing_CountDownTime = g_Common_Timing_CountDownTime - 1
end

--===============================================
-- 开始倒计时
--===============================================	
function Common_Timing_Close_CountDown()
	--停止倒计时文字显示
	KillTimer("Common_Timing_CountDown()")
	KillTimer("Common_Timing_Close_CountDown()")
	Common_Timing_Close()
end

function Common_Timing_Close()
	Common_Timing_OnHiden()
end


--===============================================
-- OnHiden
--===============================================
function Common_Timing_OnHiden()
	g_Common_Timing_Animate:Play(false)
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Common_Timing_Frame_On_ResetPos()
	Common_Timing_Frame : SetProperty("UnifiedXPosition", g_Common_Timing_Frame_UnifiedXPosition);
	Common_Timing_Frame : SetProperty("UnifiedYPosition", g_Common_Timing_Frame_UnifiedYPosition);
end
