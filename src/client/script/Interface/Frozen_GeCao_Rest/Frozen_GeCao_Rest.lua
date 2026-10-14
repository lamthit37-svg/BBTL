-- !!!reloadscript =Frozen_GeCao_Rest
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local m_miniTime = 0;
local m_nReduceTime = 0;
local m_playerNum = 0;
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Frozen_GeCao_Rest_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Frozen_GeCao_Rest_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= Frozen_GeCao_Rest_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= Frozen_GeCao_Rest_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_GeCao_Rest_ResetPos()
	Frozen_GeCao_Rest_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	Frozen_GeCao_Rest_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Frozen_GeCao_Rest_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 82004001) then--
		-- PushDebugMessage("111111111111111111")
		local opType = Get_XParam_INT(0)
		m_nReduceTime = Get_XParam_INT(1)
		m_miniTime = Get_XParam_INT(2)
		m_playerNum = Get_XParam_INT(3)
		if opType == 1 then
			if (this:IsVisible()) then
				Frozen_GeCao_Rest_Update()
				return
			end
			Frozen_GeCao_Rest_Show()
			Frozen_GeCao_Rest_Update()
		else
			if (this:IsVisible()) then
				Frozen_GeCao_Rest_Update()
				return
			end
			Frozen_GeCao_Rest_Show()
			Frozen_GeCao_Rest_Update()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if GetSceneID() == 1009 then
			return
		end
		Frozen_GeCao_Rest_Hide()
	elseif event == "ADJEST_UI_POS" then
		Frozen_GeCao_Rest_ResetPos()
	end
end

--显示UI
function Frozen_GeCao_Rest_Show()
	Frozen_GeCao_Rest_ClearData()
	this:Show()
	
end
--隐藏UI
function Frozen_GeCao_Rest_Hide()
	Frozen_GeCao_Rest_ClearData()

	this:Hide()
end

--清除数据
function Frozen_GeCao_Rest_ClearData()
end
--更新
function Frozen_GeCao_Rest_Update()
	-- PushDebugMessage(m_miniTime.." "..m_nReduceTime)
	Frozen_GeCao_Rest_PersonNum2:SetText(m_playerNum)
	Frozen_GeCao_Rest_StartTime2:SetProperty("Timer",tostring(m_miniTime));
	Frozen_GeCao_Rest_FinishTime2:SetProperty("Timer",tostring(m_nReduceTime));
	if m_nReduceTime <= 0 then
		Frozen_GeCao_Rest_GameOver:Show()
		Frozen_GeCao_Rest_PersonNum2:SetText("")
	else
		Frozen_GeCao_Rest_GameOver:Hide()
	end
end
--##############点击事件##############
function Frozen_GeCao_Rest_StartTime()

end
function Frozen_GeCao_Rest_TimeOut()
	Frozen_GeCao_Rest_GameOver:Show()
	Frozen_GeCao_Rest_PersonNum2:SetText("")
end
--####################################