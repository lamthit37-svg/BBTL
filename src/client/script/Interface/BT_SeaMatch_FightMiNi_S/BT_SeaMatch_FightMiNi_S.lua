--观看点选择

local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function BT_SeaMatch_FightMiNi_S_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SHOW_DFS_WATCHER_SMALL_UI")

end

function BT_SeaMatch_FightMiNi_S_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BT_SeaMatch_FightMiNi_S_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BT_SeaMatch_FightMiNi_S_Frame:GetProperty("UnifiedYPosition");

end

function BT_SeaMatch_FightMiNi_S_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BT_SeaMatch_FightMiNi_S_ResetPos()
		
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BT_SeaMatch_FightMiNi_S_ResetPos()
		
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		CorpsUI_2016:CancelPlayerWatchPosDirection()
		this:Hide()

	elseif( event == "SHOW_DFS_WATCHER_SMALL_UI" ) then
		this:Show()
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_SeaMatch_FightMiNi_S_ResetPos()
	BT_SeaMatch_FightMiNi_S_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_SeaMatch_FightMiNi_S_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================

function BT_SeaMatch_FightMiNi_S_OnShowNormalUI()
	this:Hide()
	PushEvent( "SHOW_DFS_WATCHER_UI" )
end
