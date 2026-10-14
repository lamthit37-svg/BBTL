local g_MonthPVP_Goto_Frame_UnifiedXPosition
local g_MonthPVP_Goto_Frame_UnifiedYPosition

local g_Rand_MainCity =
{
	[1] = {PosX = 265, PosZ = 250, Scene = 0, Name = "葡萄小祖"}, --洛阳
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_Goto_OnLoad()
	-- 保存界面的默认相对位置
	g_MonthPVP_Goto_Frame_UnifiedXPosition	= MonthPVP_Goto_Frame:GetProperty("UnifiedXPosition");
	g_MonthPVP_Goto_Frame_UnifiedYPosition	= MonthPVP_Goto_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_Goto_ResetPos()
	MonthPVP_Goto_Frame:SetProperty("UnifiedXPosition", g_MonthPVP_Goto_Frame_UnifiedXPosition);
	MonthPVP_Goto_Frame:SetProperty("UnifiedYPosition", g_MonthPVP_Goto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_Goto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 82002301 then
		--打开界面
		MonthPVP_Goto_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 82002302 then
		--前往寻路
		local RandVal = 1
		AutoRuntoTargetExWithName(g_Rand_MainCity[RandVal].PosX,g_Rand_MainCity[RandVal].PosZ,g_Rand_MainCity[RandVal].Scene,g_Rand_MainCity[RandVal].Name)
		MonthPVP_Goto_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		MonthPVP_Goto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		MonthPVP_Goto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		MonthPVP_Goto_ResetPos()
	end
end

--显示UI
function MonthPVP_Goto_Show()

	this:Show()
end

--隐藏UI
function MonthPVP_Goto_OnHide()
	this:Hide()
end

--关闭界面
function MonthPVP_Goto_Hide()
	this:Hide()
end


function MonthPVP_Goto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Help")
		Set_XSCRIPT_ScriptID(820023)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function MonthPVP_Goto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(820023)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


