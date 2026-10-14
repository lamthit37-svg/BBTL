--******************************************
--武神坛全民boss 指引界面
--create by  limengyue 
--2026-05-26
--******************************************

local g_WuShenTan_BOSS_Goto_Frame_UnifiedPosition;

--=========================================================
--PreLoad
--=========================================================
function WuShenTan_BOSS_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--=========================================================
--OnLoad
--=========================================================
function WuShenTan_BOSS_Goto_OnLoad()
	g_WuShenTan_BOSS_Goto_Frame_UnifiedPosition	= WuShenTan_BOSS_Goto_Frame:GetProperty("UnifiedPosition");
end

--=========================================================
--恢复界面的默认相对位置
--=========================================================
function WuShenTan_BOSS_Goto_On_ResetPos()
	WuShenTan_BOSS_Goto_Frame:SetProperty("UnifiedPosition", g_WuShenTan_BOSS_Goto_Frame_UnifiedPosition);
end

--=========================================================
--OnEvent
--=========================================================
function WuShenTan_BOSS_Goto_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 89376001 ) then
		--打开界面
		if(IsWindowShow("WuShenTan_BOSS_Goto")) then
			CloseWindow("WuShenTan_BOSS_Goto", true)
		end
		WuShenTan_BOSS_Goto_Open()
	end
	-- 窗口变化
	if (event=="PLAYER_LEAVE_WORLD") then
		WuShenTan_BOSS_Goto_OnHide()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		WuShenTan_BOSS_Goto_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then	
		WuShenTan_BOSS_Goto_On_ResetPos();
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       WuShenTan_BOSS_Goto_OnHide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		WuShenTan_BOSS_Goto_OnHide()
    end	
end

--=========================================================
--打开界面
--=========================================================
function WuShenTan_BOSS_Goto_Open()
	
	this:Show()
end
--=========================================================
--关闭界面
--=========================================================
function WuShenTan_BOSS_Goto_OnHide()
	this:Hide()
end

--=========================================================
--寻路
--=========================================================
function WuShenTan_BOSS_Goto_OnClickedBtn()
	AutoRuntoTargetExWithName(151, 102, 0, "灵灵铃") 
end

--=========================================================
--帮助
--=========================================================
function WuShenTan_BOSS_Goto_OnClickedHelp()
	PushEvent("QUEST_HELPINFO", "#{WSTZ_260403_07}")
end


