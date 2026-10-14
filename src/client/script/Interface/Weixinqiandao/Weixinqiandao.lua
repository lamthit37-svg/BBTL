--******************************************************************************
-- 微信签到界面
--******************************************************************************
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function Weixinqiandao_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Weixinqiandao_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition = Weixinqiandao_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = Weixinqiandao_Frame:GetProperty("UnifiedYPosition");
end

function Weixinqiandao_OnEvent(event)
	if (event == "UI_COMMAND" ) and (tonumber(arg0) == 201801241) then
		this:Show()
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Weixinqiandao_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Weixinqiandao_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end

function Weixinqiandao_ResetPos()
	Weixinqiandao_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Weixinqiandao_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Weixinqiandao_Close()
	this:Hide();
end
