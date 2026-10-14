local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_ShowUI = 0
function NoDiffMatch_Camera_PreLoad()

	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SHOW_WATCHER_UI_2018")

	this:RegisterEvent("SHOW_WATCHER_SMALL_UI_2018")
	this:RegisterEvent("UI_COMMAND")
end

function NoDiffMatch_Camera_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Camera_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Camera_Frame:GetProperty("UnifiedYPosition");
end

function NoDiffMatch_Camera_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Camera_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_Camera_ResetPos()
	elseif( event == "SCENE_TRANSED" ) then
		CorpsUI_2016:CancelPlayerWatchPosDirection()
		if g_ShowUI == 1 then
			CorpsUI_2018:SetSpecialSceneFlag()
			this:Show()
			g_ShowUI = 0
			return
		end
		this:Hide()
	elseif( event == "SHOW_WATCHER_UI_2018" ) then
		this:Show()
	elseif( event == "SHOW_WATCHER_SMALL_UI_2018" ) then
		this:Hide()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89270401 ) then
		g_ShowUI = 1
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_Camera_ResetPos()
	NoDiffMatch_Camera_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Camera_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================
--东
function NoDiffMatch_Camera_East_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(1,105,102)
end
--西
function NoDiffMatch_Camera_West_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(3,87,82)
end
--南
function NoDiffMatch_Camera_South_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(4,87,102)
end
--北
function NoDiffMatch_Camera_North_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(2,105,84)
end
--中心
function NoDiffMatch_Camera_Center_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(5,96,92)
end
--玩家视角
function NoDiffMatch_Camera_Player_Clicked()
	CorpsUI_2016:SetPlayerWatchPosDirection(0,0,0)
end
--================================================
function NoDiffMatch_Camera_OnShowTinyUI()
	this:Hide()
	PushEvent( "SHOW_WATCHER_SMALL_UI_2018", 1 )
end
