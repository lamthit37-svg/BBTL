 local m_21Frame_UnifiedXPosition
local  m_21Frame_UnifiedYPosition
 
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Anniversary21_PreLoad() 
	this:RegisterEvent("OPEN_ANNIVERSARY_21")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Anniversary21_OnLoad()
	-- 保存界面的默认相对位置
	m_21Frame_UnifiedXPosition	= Anniversary21_Frame_BK:GetProperty("UnifiedXPosition");
	m_21Frame_UnifiedXPosition	= Anniversary21_Frame_BK:GetProperty("UnifiedYPosition"); 
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Anniversary21_ResetPos()
	Anniversary21_Frame_BK:SetProperty("UnifiedXPosition", m_21Frame_UnifiedXPosition);
	Anniversary21_Frame_BK:SetProperty("UnifiedYPosition", m_21Frame_UnifiedXPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Anniversary21_OnEvent(event)
	if event == "OPEN_ANNIVERSARY_21" then
		if (this:IsVisible()) then
			return
		end
		Anniversary21_Show() 
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Anniversary21_Hide()
	elseif event == "ADJEST_UI_POS" then
		Anniversary21_ResetPos()
	end
end

--显示UI
function Anniversary21_Show() 
	this:Show()
	
end
--隐藏UI
function Anniversary21_Hide() 
	this:Hide()
end
  