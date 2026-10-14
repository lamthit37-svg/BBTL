local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


function CampPVP2023_Progress_Mini_PreLoad()

	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ZYPVP_SHOW_MINI")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CampPVP2023_Progress_Mini_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= CampPVP2023_Progress_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= CampPVP2023_Progress_Mini_Frame:GetProperty("UnifiedYPosition");
end

function CampPVP2023_Progress_Mini_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		CampPVP2023_Progress_Mini_ResetPos()
	 elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CampPVP2023_Progress_Mini_ResetPos()
	--elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
	--	this:Hide();
	elseif( event == "ZYPVP_SHOW_MINI" ) then
		this:Show();
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998429006) then	--比赛结束
		this:Hide()
	end
	
end

function CampPVP2023_Progress_Mini_ResetPos()

	CampPVP2023_Progress_Mini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	CampPVP2023_Progress_Mini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);

end

function CampPVP2023_Progress_Mini_OnShowNormalUI()
	this:Hide()
	PushEvent( "ZYPVP_SHOW_BIG" )
end