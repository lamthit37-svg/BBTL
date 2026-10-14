-- !!!reloadscript =FengYun_JianJiRest
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local m_miniTime = 0;
local m_nReduceTime = 0;
local m_playerNum = 0;
--预加载函数，可以而且只能在这里注册脚本关心的事件
function FengYun_JianJiRest_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FengYun_JianJiRest_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= FengYun_JianJiRest_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= FengYun_JianJiRest_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FengYun_JianJiRest_ResetPos()
	FengYun_JianJiRest_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	FengYun_JianJiRest_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FengYun_JianJiRest_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 82010801) then--
		-- PushDebugMessage("111111111111111111")
		local opType = Get_XParam_INT(0)
		m_nReduceTime = Get_XParam_INT(1)
		m_miniTime = Get_XParam_INT(2)
		m_playerNum = Get_XParam_INT(3)
		if opType == 1 then
			if (this:IsVisible()) then
				FengYun_JianJiRest_Update()
				return
			end
			FengYun_JianJiRest_Show()
			FengYun_JianJiRest_Update()
		else
			if (this:IsVisible()) then
				FengYun_JianJiRest_Update()
				return
			end
			FengYun_JianJiRest_Show()
			FengYun_JianJiRest_Update()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if GetSceneID() == 1058 then
			return
		end
		FengYun_JianJiRest_Hide()
	elseif event == "ADJEST_UI_POS" then
		FengYun_JianJiRest_ResetPos()
	end
end

--显示UI
function FengYun_JianJiRest_Show()
	FengYun_JianJiRest_ClearData()
	this:Show()
	
end
--隐藏UI
function FengYun_JianJiRest_Hide()
	FengYun_JianJiRest_ClearData()

	this:Hide()
end

--清除数据
function FengYun_JianJiRest_ClearData()
end
--更新
function FengYun_JianJiRest_Update()
	-- PushDebugMessage(m_miniTime.." "..m_nReduceTime)
	FengYun_JianJiRest_PersonNum2:SetText(m_playerNum)
	FengYun_JianJiRest_FinishTime2:SetProperty("Timer",tostring(m_miniTime));
	FengYun_JianJiRest_EndTime2:SetProperty("Timer",tostring(m_nReduceTime));
	if m_nReduceTime <= 0 then
		FengYun_JianJiRest_GameOver:Show()
		FengYun_JianJiRest_PersonNum2:SetText("")
	else
		FengYun_JianJiRest_GameOver:Hide()
	end
end
--##############点击事件##############
function FengYun_JianJiRest_TimeOut()
	-- FengYun_JianJiRest_GameOver:Show()
	-- FengYun_JianJiRest_PersonNum2:SetText("")
end
function FengYun_JianJiRest_EndTimeOut()
	FengYun_JianJiRest_GameOver:Show()
	FengYun_JianJiRest_PersonNum2:SetText("")
end
--####################################