local g_Frozen_GeCao_Guide_Frame_UnifiedXPosition
local g_Frozen_GeCao_Guide_Frame_UnifiedYPosition

local m_ImageBkData = 
{
	--类型
	[1] = 
	{
		"set:Frozen_GeCao2 image:Frozen_GeCao2_Guide1",
		"set:Frozen_GeCao2 image:Frozen_GeCao2_Guide2",
		"set:Frozen_GeCao3 image:Frozen_GeCao3_Guide4",
		"set:Frozen_GeCao4 image:Frozen_GeCao4_Guide5",
	},
}

local m_opType = 0
local m_selectIndex = 1
local m_totalPage = 0

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Frozen_GeCao_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Frozen_GeCao_Guide_OnLoad()
	-- 保存界面的默认相对位置
	g_Frozen_GeCao_Guide_Frame_UnifiedXPosition	= Frozen_GeCao_Guide_Frame:GetProperty("UnifiedXPosition");
	g_Frozen_GeCao_Guide_Frame_UnifiedYPosition	= Frozen_GeCao_Guide_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_GeCao_Guide_ResetPos()
	Frozen_GeCao_Guide_Frame:SetProperty("UnifiedXPosition", g_Frozen_GeCao_Guide_Frame_UnifiedXPosition);
	Frozen_GeCao_Guide_Frame:SetProperty("UnifiedYPosition", g_Frozen_GeCao_Guide_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Frozen_GeCao_Guide_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 82003801 then
		m_opType = Get_XParam_INT(0)
		local imageData = m_ImageBkData[m_opType]
		if nil == imageData then		
			return
		end
		m_totalPage = table.getn(imageData)
		--打开界面
		Frozen_GeCao_Guide_Show()
		Frozen_GeCao_Guide_Update()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_GeCao_Guide_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Frozen_GeCao_Guide_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_GeCao_Guide_ResetPos()
	end
end

--显示UI
function Frozen_GeCao_Guide_Show()
	this:Show()
	m_selectIndex = 1
end
--隐藏UI
function Frozen_GeCao_Guide_OnHide()
	this:Hide()
end

function Frozen_GeCao_Guide_Update()
	local imageData = m_ImageBkData[m_opType]
	if nil == imageData then		
		return
	end
	if nil ~= imageData[m_selectIndex] then
		Frozen_GeCao_Guide_ImageBk:SetProperty("Image", imageData[m_selectIndex])
	end
	Frozen_GeCao_Guide_LeftArrow:Show()
	Frozen_GeCao_Guide_RightArrow:Show()
	if m_selectIndex == 1 then
		Frozen_GeCao_Guide_LeftArrow:Hide()
	end
	if m_selectIndex == m_totalPage then
		Frozen_GeCao_Guide_RightArrow:Hide()
	end
end

function Frozen_GeCao_Guide_OnClose()
	Frozen_GeCao_Guide_OnHide()
end
function Frozen_GeCao_Guide_Page_Left()
	m_selectIndex = m_selectIndex - 1
	if m_selectIndex < 1 then
		m_selectIndex = 1
	end
	Frozen_GeCao_Guide_Update()
end
function Frozen_GeCao_Guide_Page_Right()
	m_selectIndex = m_selectIndex + 1
	if m_selectIndex > m_totalPage then
		m_selectIndex = m_totalPage
	end
	Frozen_GeCao_Guide_Update()
end

