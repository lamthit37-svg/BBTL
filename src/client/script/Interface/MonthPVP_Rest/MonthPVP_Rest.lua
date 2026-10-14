-- !!!reloadscript =MonthPVP_Rest
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local m_miniTime = 0;
local m_nReduceTime = 0;
local m_playerNum = 0;
--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_Rest_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PVPCAR_UIOP", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_Rest_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= MonthPVP_Rest_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= MonthPVP_Rest_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_Rest_ResetPos()
	MonthPVP_Rest_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	MonthPVP_Rest_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_Rest_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 82002201) then--
		local opType = Get_XParam_INT(0)
		m_nReduceTime = Get_XParam_INT(1)
		m_miniTime = Get_XParam_INT(2)
		m_playerNum = Get_XParam_INT(3)
		if opType == 1 then
			if (IsWindowShow("MonthPVP_RestMini")) then
				CloseWindow("MonthPVP_RestMini", true);
				return
			end
			if (this:IsVisible()) then
				MonthPVP_Rest_Update()
				return
			end
			MonthPVP_Rest_Show()
			MonthPVP_Rest_Update()
		else
			if (this:IsVisible()) then
				MonthPVP_Rest_Update()
				return
			end
			if (IsWindowShow("MonthPVP_RestMini")) then
				return
			else
				MonthPVP_Rest_Show()
				MonthPVP_Rest_Update()
			end
		end
	elseif (event == "PVPCAR_UIOP") then
		local opType = tonumber(arg0)
		if opType == 1 then
			if (this:IsVisible()) then
				MonthPVP_Rest_Update()
				return
			end
			MonthPVP_Rest_Show()
			MonthPVP_Rest_Update()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if GetSceneID() == 973 then
			return
		end
		MonthPVP_Rest_Hide()
	elseif event == "ADJEST_UI_POS" then
		MonthPVP_Rest_ResetPos()
	end
end

--显示UI
function MonthPVP_Rest_Show()
	MonthPVP_Rest_ClearData()
	this:Show()
	
end
--隐藏UI
function MonthPVP_Rest_Hide()
	MonthPVP_Rest_ClearData()

	this:Hide()
end

--清除数据
function MonthPVP_Rest_ClearData()
end
--更新
function MonthPVP_Rest_Update()
	-- 添加倒计时
	MonthPVP_Rest_Start:SetProperty("Timer",tostring(m_miniTime));
	MonthPVP_Rest_Time:SetProperty("Timer",tostring(m_nReduceTime));
	MonthPVP_Rest_PersonNum:SetText(m_playerNum)
end
--##############点击事件##############
function MonthPVP_Rest_OnClose()
	PushEvent("PVPCAR_UIOP", 2)
	MonthPVP_Rest_Hide()
end
function MonthPVP_Rest_StartTime()

end
function MonthPVP_Rest_TimeOut()

end
--####################################