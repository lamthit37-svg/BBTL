local g_ErTongJie_Activity_Frame_UnifiedXPosition
local g_ErTongJie_Activity_Frame_UnifiedYPosition

--预加载函数，可以而且只能在这里注册脚本关心的事件
function ErTongJie_Activity_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ErTongJie_Activity_OnLoad()
	-- 保存界面的默认相对位置
	g_ErTongJie_Activity_Frame_UnifiedXPosition	= ErTongJie_Activity_Frame_BK:GetProperty("UnifiedXPosition");
	g_ErTongJie_Activity_Frame_UnifiedYPosition	= ErTongJie_Activity_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ErTongJie_Activity_ResetPos()
	ErTongJie_Activity_Frame_BK:SetProperty("UnifiedXPosition", g_ErTongJie_Activity_Frame_UnifiedXPosition);
	ErTongJie_Activity_Frame_BK:SetProperty("UnifiedYPosition", g_ErTongJie_Activity_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function ErTongJie_Activity_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928011 then
	--打开界面
		ErTongJie_Activity_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 8928010 then
	--前往寻路
		AutoRuntoTargetExWithName(262, 342, 0, "童姥")
		ErTongJie_Activity_Close()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ErTongJie_Activity_OnHiden()
	elseif event == "ADJEST_UI_POS" then
		ErTongJie_Activity_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ErTongJie_Activity_ResetPos()
	end
end

--显示UI
function ErTongJie_Activity_Show()

	this:Show()
end

--隐藏UI
function ErTongJie_Activity_OnHiden()
	this:Hide()
end

--关闭界面
function ErTongJie_Activity_Close()
	this:Hide()
end

function ErTongJie_Activity_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ChildrenDayBallonHelp")
		Set_XSCRIPT_ScriptID(892800)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ErTongJie_Activity_Goto()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnJoinInChildrenDayBallon")
		Set_XSCRIPT_ScriptID(892800)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


