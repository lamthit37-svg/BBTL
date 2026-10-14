

local g_UICOMMAND = 89039002
local g_WorldBoss_Mini_UnifiedPosition=nil;

function WorldBoss_InfoMini_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	
	this:RegisterEvent("BOSSINVADEOPENMINI")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	
end

function WorldBoss_InfoMini_OnLoad()	
	g_WorldBoss_Mini_UnifiedPosition  =WorldBoss_InfoMini_Frame:GetProperty("UnifiedPosition");
end

function WorldBoss_InfoMini_OnEvent(event)

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	if event == "BOSSINVADEOPENMINI"  then
		if  tonumber(arg0) == 1 then
			this:Show()
		else
			this:Hide()
		end
	end
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		WorldBoss_InfoMini_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WorldBoss_InfoMini_On_ResetPos()
	end
end


function WorldBoss_InfoMini_OnShowNormalUI()
	--打开info界面
	PushEvent("BOSSINVADEOPENMINI",3)
end

function WorldBoss_InfoMini_On_ResetPos()
	WorldBoss_InfoMini_Frame:SetProperty("UnifiedPosition", g_WorldBoss_Mini_UnifiedPosition);
end