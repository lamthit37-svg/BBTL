--春节应景

---------------------------------------------------------------------------
local g_Controls = {};									-- 控件
local g_Position = "{{0.500000,-351.000000},{0.500000,-237.000000}}";
local g_StartTime = 20240125
local g_EndTime = 20240208
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function SpringFestival_Activity_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED", false );		-- 游戏分辨率发生了变化
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED", false );		-- 离开场景
	this : RegisterEvent( "ADJEST_UI_POS" , false);
end


--*********************************
-- OnLoad
--*********************************
function SpringFestival_Activity_OnLoad()
	g_Controls = {
		-- 框架
		Framework = SpringFestival_Activity_Frame_BK;

		Button = SpringFestival_Activity_GoBtn;
	};
end


--*********************************
-- OnEvent
--*********************************
function SpringFestival_Activity_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 88887302) then
		SpringFestival_Activity_OnShow()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif	(event == "ADJEST_UI_POS" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end


--*********************************
-- 清空控件
--*********************************
function SpringFestival_Activity_CleanupUIControls()
	SetDefaultMouse()
	g_position = 1
end


--*********************************
-- 显示
--*********************************
function SpringFestival_Activity_OnShow()
	this:Show()
end

function SpringFestival_Activity_OnHide()
	this:Hide()
end

function SpringFestival_Activity_ShowHelp()
	PushEvent("CCSHOP_HELP", 142)
end

function SpringFestival_Activity_Goto()
	
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_StartTime or curDay > g_EndTime then
		PushDebugMessage("#{CJYJ_211203_173}")
		return
	end

	local nLevel = Player:GetLevel();
	if nLevel < 30 then
		PushDebugMessage("#{CJYJ_211203_174}")
		return
	end

	local bRet = AutoRuntoTargetExWithName(237, 337, 0, "陈弘海")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	SpringFestival_Activity_OnHide()
end