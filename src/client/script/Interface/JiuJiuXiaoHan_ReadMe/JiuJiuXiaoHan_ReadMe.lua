--******************************************************************************
-- 九九消寒Readme界面 by 宋旭阳
--******************************************************************************
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function JiuJiuXiaoHan_ReadMe_PreLoad()
	this:RegisterEvent("OPEN_JIUJIUXIAOHAN_README")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function JiuJiuXiaoHan_ReadMe_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition = JiuJiuXiaoHan_ReadMe_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = JiuJiuXiaoHan_ReadMe_Frame:GetProperty("UnifiedYPosition");
end

function JiuJiuXiaoHan_ReadMe_OnEvent(event)
	if (event == "OPEN_JIUJIUXIAOHAN_README" ) then
		this:Show()
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		JiuJiuXiaoHan_ReadMe_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JiuJiuXiaoHan_ReadMe_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end

function JiuJiuXiaoHan_ReadMe_ResetPos()
	JiuJiuXiaoHan_ReadMe_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	JiuJiuXiaoHan_ReadMe_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function JiuJiuXiaoHan_ReadMe_OnHide()
	this:Hide();
end
