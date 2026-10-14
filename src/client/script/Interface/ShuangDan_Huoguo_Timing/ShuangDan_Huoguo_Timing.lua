--******************************************************************************
-- 倒计时界面
--******************************************************************************
local g_ShuangDan_Huoguo_Timing_Frame_UnifiedXPosition;
local g_ShuangDan_Huoguo_Timing_Frame_UnifiedYPosition;

--UI
local g_ShuangDan_Huoguo_Timing_Animate  --倒计时动画

--计数
local g_ShuangDan_Huoguo_Timing_CountDownTime = 5--剩余时间

--常量
local g_ShuangDan_Huoguo_Timing_Time = 5  --成功时最长显示时间

--===============================================
-- OnLoad()
--===============================================
function ShuangDan_Huoguo_Timing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function ShuangDan_Huoguo_Timing_OnLoad()

	-- 保存界面的默认相对位置
	g_ShuangDan_Huoguo_Timing_Frame_UnifiedXPosition = ShuangDan_Huoguo_Timing_Frame:GetProperty("UnifiedXPosition");
	g_ShuangDan_Huoguo_Timing_Frame_UnifiedYPosition = ShuangDan_Huoguo_Timing_Frame:GetProperty("UnifiedYPosition");
	
	--倒计时动画
	g_ShuangDan_Huoguo_Timing_Animate = ShuangDan_Huoguo_Timing_Animate
	
	
end


--===============================================
-- OnEvent()
--===============================================

function ShuangDan_Huoguo_Timing_OnEvent(event)
	if(event == "UI_COMMAND") then

		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 88881305 then
			local param = Get_XParam_INT(0)
			if param == 1 then

				KillTimer("g_ShuangDan_Huoguo_Timing_CountDown()")
				KillTimer("ShuangDan_Huoguo_Timing_Close_CountDown()")
			
				g_ShuangDan_Huoguo_Timing_CountDownTime = g_ShuangDan_Huoguo_Timing_Time
				PushDebugMessage("#{BWQH_211027_74}") --5s后将开始火锅烹饪，请少侠做好准备！
				
				SetTimer("ShuangDan_Huoguo_Timing","ShuangDan_Huoguo_Timing_CountDown()", 1000)
				SetTimer("ShuangDan_Huoguo_Timing","ShuangDan_Huoguo_Timing_Close_CountDown()", g_ShuangDan_Huoguo_Timing_Time*1000)
				
				g_ShuangDan_Huoguo_Timing_Animate:Play(true)

				this:Show()
			elseif param == 0 then
				ShuangDan_Huoguo_Timing_Close()	
			end
		elseif arg == 88881302 then
			ShuangDan_Huoguo_Timing_Close()
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		ShuangDan_Huoguo_Timing_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		ShuangDan_Huoguo_Timing_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ShuangDan_Huoguo_Timing_Close()
	end
end

--===============================================
-- 游戏开始 每秒更新界面倒计时
--===============================================	
function ShuangDan_Huoguo_Timing_CountDown()
	g_ShuangDan_Huoguo_Timing_CountDownTime = g_ShuangDan_Huoguo_Timing_CountDownTime - 1
	--PushDebugMessage(g_ShuangDan_Huoguo_Timing_CountDownTime.."秒之后游戏开始！")
	if g_ShuangDan_Huoguo_Timing_CountDownTime == 3 then
		PushDebugMessage("#{BWQH_211027_75}") --3s后将开始火锅烹饪，请少侠做好准备！
	end
end

--===============================================
-- 开始倒计时
--===============================================	
function ShuangDan_Huoguo_Timing_Close_CountDown()
	--停止倒计时文字显示
	KillTimer("ShuangDan_Huoguo_Timing_CountDown()")
	KillTimer("ShuangDan_Huoguo_Timing_Close_CountDown()")
	PushDebugMessage("#{BWQH_211027_76}")   --火锅烹饪开始，请少侠根据提示合力烹饪火锅！
	ShuangDan_Huoguo_Timing_Close()
end

function ShuangDan_Huoguo_Timing_Close()
	ShuangDan_Huoguo_Timing_OnHiden()
end


--===============================================
-- OnHiden
--===============================================
function ShuangDan_Huoguo_Timing_OnHiden()
	g_ShuangDan_Huoguo_Timing_Animate:Play(false)
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ShuangDan_Huoguo_Timing_Frame_On_ResetPos()
	ShuangDan_Huoguo_Timing_Frame : SetProperty("UnifiedXPosition", g_ShuangDan_Huoguo_Timing_Frame_UnifiedXPosition);
	ShuangDan_Huoguo_Timing_Frame : SetProperty("UnifiedYPosition", g_ShuangDan_Huoguo_Timing_Frame_UnifiedYPosition);
end
