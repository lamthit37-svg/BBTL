local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function NoDiffMatch_Camera_Tiny_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SHOW_WATCHER_UI_2018")

	this:RegisterEvent("SHOW_WATCHER_SMALL_UI_2018")

end

function NoDiffMatch_Camera_Tiny_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Camera_Tiny_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Camera_Tiny_Frame:GetProperty("UnifiedYPosition");

end

function NoDiffMatch_Camera_Tiny_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Camera_Tiny_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_Camera_Tiny_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		CorpsUI_2016:CancelPlayerWatchPosDirection()
		this:Hide()
	elseif( event == "SHOW_WATCHER_UI_2018" ) then
		this:Hide()
	elseif( event == "SHOW_WATCHER_SMALL_UI_2018" ) then
		this:Show()
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_Camera_Tiny_ResetPos()
	NoDiffMatch_Camera_Tiny_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Camera_Tiny_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================

function NoDiffMatch_Camera_Tiny_OnShowNormalUI()
	this:Hide()
	PushEvent( "SHOW_WATCHER_UI_2018", 1 )
end
