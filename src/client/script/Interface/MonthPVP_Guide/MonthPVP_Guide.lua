local g_MonthPVP_Guide_Frame_UnifiedXPosition
local g_MonthPVP_Guide_Frame_UnifiedYPosition

local m_ImageBkData = 
{
	[1] = "set:DaHua_PVP2 image:DaHua_PVP2_Guide1",
	[2] = "set:DaHua_PVP2 image:DaHua_PVP2_Guide2",
	[3] = "set:DaHua_PVP3 image:DaHua_PVP3_Guide3",
	[4] = "set:DaHua_PVP3 image:DaHua_PVP3_Guide4",
}

local m_selectIndex = 1

--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_Guide_OnLoad()
	-- 保存界面的默认相对位置
	g_MonthPVP_Guide_Frame_UnifiedXPosition	= MonthPVP_Guide_Frame:GetProperty("UnifiedXPosition");
	g_MonthPVP_Guide_Frame_UnifiedYPosition	= MonthPVP_Guide_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_Guide_ResetPos()
	MonthPVP_Guide_Frame:SetProperty("UnifiedXPosition", g_MonthPVP_Guide_Frame_UnifiedXPosition);
	MonthPVP_Guide_Frame:SetProperty("UnifiedYPosition", g_MonthPVP_Guide_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_Guide_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 8200201 then
		--打开界面
		MonthPVP_Guide_Show()
		MonthPVP_Guide_Update()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		MonthPVP_Guide_OnHide()
	elseif event == "ADJEST_UI_POS" then
		MonthPVP_Guide_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		MonthPVP_Guide_ResetPos()
	end
end

--显示UI
function MonthPVP_Guide_Show()
	this:Show()
	m_selectIndex = 1
end
--隐藏UI
function MonthPVP_Guide_OnHide()
	this:Hide()
end

function MonthPVP_Guide_Update()
	if nil == m_ImageBkData[m_selectIndex] then
		return
	end
	MonthPVP_Guide_ImageBk:SetProperty("Image", m_ImageBkData[m_selectIndex])
	MonthPVP_Guide_LeftArrow:Show()
	MonthPVP_Guide_RightArrow:Show()
	if m_selectIndex == 1 then
		MonthPVP_Guide_LeftArrow:Hide()
	end
	if m_selectIndex == 4 then
		MonthPVP_Guide_RightArrow:Hide()
	end
end

function MonthPVP_Guide_OnClose()
	MonthPVP_Guide_OnHide()
end
function MonthPVP_Guide_Page_Left()
	m_selectIndex = m_selectIndex - 1
	if m_selectIndex < 1 then
		m_selectIndex = 1
	end
	MonthPVP_Guide_Update()
end
function MonthPVP_Guide_Page_Right()
	m_selectIndex = m_selectIndex + 1
	if m_selectIndex > 4 then
		m_selectIndex = 4
	end
	MonthPVP_Guide_Update()
end

