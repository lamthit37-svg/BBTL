--******************************************************************************
-- 倒计时界面
--******************************************************************************
local g_ThreeCity_SaveTree_Timing_Frame_UnifiedXPosition;
local g_ThreeCity_SaveTree_Timing_Frame_UnifiedYPosition;

--UI
local g_ThreeCity_SaveTree_Timing_Animate  --倒计时动画

--计数
local g_ThreeCity_SaveTree_Timing_CountDownTime = 5--剩余时间

--常量
local g_ThreeCity_SaveTree_Timing_Time = 5  --成功时最长显示时间

--===============================================
-- OnLoad()
--===============================================
function ThreeCity_SaveTree_Timing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function ThreeCity_SaveTree_Timing_OnLoad()

	-- 保存界面的默认相对位置
	g_ThreeCity_SaveTree_Timing_Frame_UnifiedXPosition = ThreeCity_SaveTree_Timing_Frame:GetProperty("UnifiedXPosition");
	g_ThreeCity_SaveTree_Timing_Frame_UnifiedYPosition = ThreeCity_SaveTree_Timing_Frame:GetProperty("UnifiedYPosition");
	
	--倒计时动画
	g_ThreeCity_SaveTree_Timing_Animate = ThreeCity_SaveTree_Timing_Animate
	
	
end


--===============================================
-- OnEvent()
--===============================================

function ThreeCity_SaveTree_Timing_OnEvent(event)
	if(event == "UI_COMMAND") then

		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 99822605 then
			local param = Get_XParam_INT(0)
			if param == 1 then

				KillTimer("g_ThreeCity_SaveTree_Timing_CountDown()")
				KillTimer("ThreeCity_SaveTree_Timing_Close_CountDown()")
			
				g_ThreeCity_SaveTree_Timing_CountDownTime = g_ThreeCity_SaveTree_Timing_Time
				PushDebugMessage("#{ZJSS_220803_91}") --5s后将开始火锅烹饪，请少侠做好准备！
				
				SetTimer("ThreeCity_SaveTree_Timing","ThreeCity_SaveTree_Timing_CountDown()", 1000)
				SetTimer("ThreeCity_SaveTree_Timing","ThreeCity_SaveTree_Timing_Close_CountDown()", g_ThreeCity_SaveTree_Timing_Time*1000)
				
				g_ThreeCity_SaveTree_Timing_Animate:Play(true)

				this:Show()
			elseif param == 0 then
				ThreeCity_SaveTree_Timing_Close()	
			end
		elseif arg == 99822602 then
			ThreeCity_SaveTree_Timing_Close()
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		ThreeCity_SaveTree_Timing_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		ThreeCity_SaveTree_Timing_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ThreeCity_SaveTree_Timing_Close()
	end
end

--===============================================
-- 游戏开始 每秒更新界面倒计时
--===============================================	
function ThreeCity_SaveTree_Timing_CountDown()
	g_ThreeCity_SaveTree_Timing_CountDownTime = g_ThreeCity_SaveTree_Timing_CountDownTime - 1
	--PushDebugMessage(g_ThreeCity_SaveTree_Timing_CountDownTime.."秒之后游戏开始！")
	if g_ThreeCity_SaveTree_Timing_CountDownTime == 3 then
		PushDebugMessage("#{ZJSS_220803_92}") --3s后将开始火锅烹饪，请少侠做好准备！
	end
end

--===============================================
-- 开始倒计时
--===============================================	
function ThreeCity_SaveTree_Timing_Close_CountDown()
	--停止倒计时文字显示
	KillTimer("ThreeCity_SaveTree_Timing_CountDown()")
	KillTimer("ThreeCity_SaveTree_Timing_Close_CountDown()")
	PushDebugMessage("#{ZJSS_220803_93}")   --火锅烹饪开始，请少侠根据提示合力烹饪火锅！
	ThreeCity_SaveTree_Timing_Close()
end

function ThreeCity_SaveTree_Timing_Close()
	ThreeCity_SaveTree_Timing_OnHiden()
end


--===============================================
-- OnHiden
--===============================================
function ThreeCity_SaveTree_Timing_OnHiden()
	g_ThreeCity_SaveTree_Timing_Animate:Play(false)
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ThreeCity_SaveTree_Timing_Frame_On_ResetPos()
	ThreeCity_SaveTree_Timing_Frame : SetProperty("UnifiedXPosition", g_ThreeCity_SaveTree_Timing_Frame_UnifiedXPosition);
	ThreeCity_SaveTree_Timing_Frame : SetProperty("UnifiedYPosition", g_ThreeCity_SaveTree_Timing_Frame_UnifiedYPosition);
end
