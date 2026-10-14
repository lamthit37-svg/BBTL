--春节应景

---------------------------------------------------------------------------
local g_Controls = {};									-- 控件
local g_Position = "{{0.500000,-351.000000},{0.500000,-237.000000}}";
local g_StartTime = 20260224
local g_EndTime = 20260315
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function SpringFestival_Activity2_PreLoad()
	this : RegisterEvent( "OPEN_YINGJINGACTIVITY2" );					-- UI_COMMAND
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED", false );		-- 游戏分辨率发生了变化
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED", false );		-- 离开场景
	this : RegisterEvent( "ADJEST_UI_POS" , false);
end


--*********************************
-- OnLoad
--*********************************
function SpringFestival_Activity2_OnLoad()
	g_Controls = {
		-- 框架
		Framework = SpringFestival_Activity2_Frame_BK;

		Button = SpringFestival_Activity2_GoBtn;
	};
end


--*********************************
-- OnEvent
--*********************************
function SpringFestival_Activity2_OnEvent(event)
	if (event == "OPEN_YINGJINGACTIVITY2") then
		SpringFestival_Activity2_OnShow()
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
function SpringFestival_Activity2_CleanupUIControls()
	SetDefaultMouse()
	g_position = 1
end


--*********************************
-- 显示
--*********************************
function SpringFestival_Activity2_OnShow()
	this:Show()
end

function SpringFestival_Activity2_OnHide()
	this:Hide()
end

function SpringFestival_Activity2_OnClickedHelp()
	PushEvent("CCSHOP_HELP", 240)
end

function SpringFestival_Activity2_OnClickedBtn()
	
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_StartTime or curDay > g_EndTime then
		PushDebugMessage("#{QCBF_260105_3}")
		return
	end

	local nLevel = Player:GetLevel();
	if nLevel < 30 then
		PushDebugMessage("#{QCBF_260105_2}")
		return
	end

	local bRet = AutoRuntoTargetExWithName(217,158, 0, "年老板")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	SpringFestival_Activity2_OnHide()
end