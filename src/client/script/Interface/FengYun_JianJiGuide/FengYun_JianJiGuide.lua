-- !!!reloadscript =FengYun_JianJiGuide
local g_FengYun_JianJiGuide_Frame_UnifiedXPosition
local g_FengYun_JianJiGuide_Frame_UnifiedYPosition

local m_ImageBkData = 
{
	--类型
	[1] = 
	{
		"set:FengYun_PVP2 image:FengYun_PVP_Guide1",
		"set:FengYun_PVP2 image:FengYun_PVP_Guide2",
		"set:FengYun_PVP3 image:FengYun_PVP_Guide3",
		"set:FengYun_PVP3 image:FengYun_PVP_Guide4",
	},
}

local m_opType = 0
local m_selectIndex = 1
local m_totalPage = 0

--预加载函数，可以而且只能在这里注册脚本关心的事件
function FengYun_JianJiGuide_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FengYun_JianJiGuide_OnLoad()
	-- 保存界面的默认相对位置
	g_FengYun_JianJiGuide_Frame_UnifiedXPosition	= FengYun_JianJiGuide_Frame:GetProperty("UnifiedXPosition");
	g_FengYun_JianJiGuide_Frame_UnifiedYPosition	= FengYun_JianJiGuide_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FengYun_JianJiGuide_ResetPos()
	FengYun_JianJiGuide_Frame:SetProperty("UnifiedXPosition", g_FengYun_JianJiGuide_Frame_UnifiedXPosition);
	FengYun_JianJiGuide_Frame:SetProperty("UnifiedYPosition", g_FengYun_JianJiGuide_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FengYun_JianJiGuide_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 82010601 then
		m_opType = Get_XParam_INT(0)
		local imageData = m_ImageBkData[m_opType]
		if nil == imageData then		
			return
		end
		m_totalPage = table.getn(imageData)
		--打开界面
		FengYun_JianJiGuide_Show()
		FengYun_JianJiGuide_Update()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		local curSceneID = GetSceneID(); --周常pve屏蔽地图
		if curSceneID == 1049 then
		
		else
			FengYun_JianJiGuide_OnHide()
		end
	elseif event == "ADJEST_UI_POS" then
		FengYun_JianJiGuide_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_JianJiGuide_ResetPos()
	end
end

--显示UI
function FengYun_JianJiGuide_Show()
	this:Show()
	m_selectIndex = 1
end
--隐藏UI
function FengYun_JianJiGuide_OnHide()
	this:Hide()
end

function FengYun_JianJiGuide_Update()
	local imageData = m_ImageBkData[m_opType]
	if nil == imageData then		
		return
	end
	-- PushDebugMessage(m_opType.." "..m_selectIndex)
	if nil ~= imageData[m_selectIndex] then
		FengYun_JianJiGuide_ImageBk_01:SetProperty("Image", imageData[m_selectIndex])
	end
	FengYun_JianJiGuide_LeftArrow:Show()
	FengYun_JianJiGuide_RightArrow:Show()
	if m_selectIndex == 1 then
		FengYun_JianJiGuide_LeftArrow:Hide()
	end
	-- PushDebugMessage(m_selectIndex.." "..m_totalPage)
	if m_selectIndex == m_totalPage then
		FengYun_JianJiGuide_RightArrow:Hide()
	end
end

function FengYun_JianJiGuide_OnClose()
	FengYun_JianJiGuide_OnHide()
end
function FengYun_JianJiGuide_Page_Left()
	m_selectIndex = m_selectIndex - 1
	if m_selectIndex < 1 then
		m_selectIndex = 1
	end
	FengYun_JianJiGuide_Update()
end
function FengYun_JianJiGuide_Page_Right()
	m_selectIndex = m_selectIndex + 1
	if m_selectIndex > m_totalPage then
		m_selectIndex = m_totalPage
	end

	FengYun_JianJiGuide_Update()
end

