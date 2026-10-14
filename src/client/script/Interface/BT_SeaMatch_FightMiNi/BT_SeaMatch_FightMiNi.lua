--观看点选择
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_ShowUI = 0

function BT_SeaMatch_FightMiNi_PreLoad()

	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SHOW_DFS_WATCHER_UI")

	this:RegisterEvent("UI_COMMAND")
end

function BT_SeaMatch_FightMiNi_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BT_SeaMatch_FightMiNi_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BT_SeaMatch_FightMiNi_Frame:GetProperty("UnifiedYPosition");
end

function BT_SeaMatch_FightMiNi_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BT_SeaMatch_FightMiNi_ResetPos()
		
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BT_SeaMatch_FightMiNi_ResetPos()
		
	elseif( event == "SCENE_TRANSED" ) then
		BT_SeaMatch_FightMiNi_EnterScene()
		
	elseif( event == "SHOW_DFS_WATCHER_UI" ) then
		BT_SeaMatch_FightMiNi_Show()
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 29151302 ) then
		g_ShowUI = 1
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_SeaMatch_FightMiNi_ResetPos()
	BT_SeaMatch_FightMiNi_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_SeaMatch_FightMiNi_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================
--东
function BT_SeaMatch_FightMiNi_East_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(1,148,148)
end
--西
function BT_SeaMatch_FightMiNi_West_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(3,108,108)
end
--南
function BT_SeaMatch_FightMiNi_South_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(4,108,148)
end
--北
function BT_SeaMatch_FightMiNi_North_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(2,148,108)
end
--中心
function BT_SeaMatch_FightMiNi_Center_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(5,128,128)
end
--玩家视角
function BT_SeaMatch_FightMiNi_Player_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(0,0,0)
end
--================================================
function BT_SeaMatch_FightMiNi_OnShowTinyUI()
	BT_SeaMatch_FightMiNi_Hide()
	PushEvent( "SHOW_DFS_WATCHER_SMALL_UI" )
end

function BT_SeaMatch_FightMiNi_Hide()
	this:Hide()
end

function BT_SeaMatch_FightMiNi_Show()
	this:Show()
end

--进场景后相关处理
function BT_SeaMatch_FightMiNi_EnterScene()
	CorpsUI_2016:CancelPlayerWatchPosDirection()
		
	if g_ShowUI == 1 then
		DFS:LuaSetSpecialSceneFlag()
		g_ShowUI = 0
		BT_SeaMatch_FightMiNi_Show()
	else
		BT_SeaMatch_FightMiNi_Hide()
	end
end
