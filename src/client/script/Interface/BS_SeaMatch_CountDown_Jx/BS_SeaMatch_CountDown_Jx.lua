--试剑天下倒计时
local m_time = 0
--预加载函数，可以而且只能在这里注册脚本关心的事件
function BS_SeaMatch_CountDown_Jx_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function BS_SeaMatch_CountDown_Jx_OnLoad()
end


--响应事件的函数，当注册的事件发生时会调用的函数
function BS_SeaMatch_CountDown_Jx_OnEvent(event)

	if( event == "UI_COMMAND" and tonumber(arg0) == 89284301) then
		m_time = Get_XParam_INT(0)
		if (this:IsVisible()) then
			BS_SeaMatch_CountDown_Jx_Update()
			return
		end
		BS_SeaMatch_CountDown_Jx_Show()
		BS_SeaMatch_CountDown_Jx_Update()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BS_SeaMatch_CountDown_Jx_Hide()
	end
end

--显示UI
function BS_SeaMatch_CountDown_Jx_Show()
	BS_SeaMatch_CountDown_Jx_ClearData()

	this:Show()
	
end
--隐藏UI
function BS_SeaMatch_CountDown_Jx_Hide()
	BS_SeaMatch_CountDown_Jx_ClearData()

	this:Hide()
end
function BS_SeaMatch_CountDown_Jx_AutoClick_Timer()
	if m_time <= 0 then
		BS_SeaMatch_CountDown_Jx_Hide()
	end
	m_time = m_time - 1
end

--清除数据
function BS_SeaMatch_CountDown_Jx_ClearData()
	BS_SeaMatch_CountDown_Jx_Animate:Play(false)
	KillTimer("BS_SeaMatch_CountDown_Jx_AutoClick_Timer()")
end
--更新
function BS_SeaMatch_CountDown_Jx_Update()

	KillTimer("BS_SeaMatch_CountDown_Jx_AutoClick_Timer()")
	SetTimer("BS_SeaMatch_CountDown_Jx","BS_SeaMatch_CountDown_Jx_AutoClick_Timer()", 1000)
	BS_SeaMatch_CountDown_Jx_Animate:Play(true)
end

--##############点击事件##############
--####################################