local g_Frozen_Dance_Goto_Frame_UnifiedXPosition
local g_Frozen_Dance_Goto_Frame_UnifiedYPosition

local g_Rand_MainCity =
{
	[1] = {PosX = 172, PosZ = 146, Scene = 1007, Name = "范大彪"},
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Frozen_Dance_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Frozen_Dance_Goto_OnLoad()
	-- 保存界面的默认相对位置
	g_Frozen_Dance_Goto_Frame_UnifiedXPosition	= Frozen_Dance_Goto_Frame:GetProperty("UnifiedXPosition");
	g_Frozen_Dance_Goto_Frame_UnifiedYPosition	= Frozen_Dance_Goto_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Dance_Goto_ResetPos()
	Frozen_Dance_Goto_Frame:SetProperty("UnifiedXPosition", g_Frozen_Dance_Goto_Frame_UnifiedXPosition);
	Frozen_Dance_Goto_Frame:SetProperty("UnifiedYPosition", g_Frozen_Dance_Goto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Frozen_Dance_Goto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 82009401 then
		--打开界面
		Frozen_Dance_Goto_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 82009402 then
		--前往寻路
		local RandVal = 1
		AutoRuntoTargetExWithName(g_Rand_MainCity[RandVal].PosX,g_Rand_MainCity[RandVal].PosZ,g_Rand_MainCity[RandVal].Scene,g_Rand_MainCity[RandVal].Name)
		Frozen_Dance_Goto_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_Dance_Goto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Frozen_Dance_Goto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_Dance_Goto_ResetPos()
	end
end

--显示UI
function Frozen_Dance_Goto_Show()

	this:Show()
end

--隐藏UI
function Frozen_Dance_Goto_OnHide()
	this:Hide()
end


function Frozen_Dance_Goto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Help")
		Set_XSCRIPT_ScriptID(820094)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Frozen_Dance_Goto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(820094)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


