local g_FengYun_JianJiGoto_Frame_UnifiedXPosition
local g_FengYun_JianJiGoto_Frame_UnifiedYPosition

local g_Rand_MainCity =
{
	[1] = {PosX = 150, PosZ = 110, Scene = 1056, Name = "步惊云"},
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function FengYun_JianJiGoto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FengYun_JianJiGoto_OnLoad()
	-- 保存界面的默认相对位置
	g_FengYun_JianJiGoto_Frame_UnifiedXPosition	= FengYun_JianJiGoto_Frame_BK:GetProperty("UnifiedXPosition");
	g_FengYun_JianJiGoto_Frame_UnifiedYPosition	= FengYun_JianJiGoto_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FengYun_JianJiGoto_ResetPos()
	FengYun_JianJiGoto_Frame_BK:SetProperty("UnifiedXPosition", g_FengYun_JianJiGoto_Frame_UnifiedXPosition);
	FengYun_JianJiGoto_Frame_BK:SetProperty("UnifiedYPosition", g_FengYun_JianJiGoto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FengYun_JianJiGoto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 82010901 then
		--打开界面
		FengYun_JianJiGoto_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 82010902 then
		--前往寻路
		local RandVal = 1
		AutoRuntoTargetExWithName(g_Rand_MainCity[RandVal].PosX,g_Rand_MainCity[RandVal].PosZ,g_Rand_MainCity[RandVal].Scene,g_Rand_MainCity[RandVal].Name)
		FengYun_JianJiGoto_OnHide()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 82006602 then --借用下界面
		AutoRuntoTargetExWithName(312,273,0,"统战禁军")
		FengYun_JianJiGoto_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_JianJiGoto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		FengYun_JianJiGoto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_JianJiGoto_ResetPos()
	end
end

--显示UI
function FengYun_JianJiGoto_Show()

	this:Show()
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay >= 20260504 and curDay <= 20260524 then
		FengYun_JianJiGoto_Text:SetText("#{FYPVP_260106_183}")
	else
		FengYun_JianJiGoto_Text:SetText("#{FYPVP_260106_182}")
	end
end

--隐藏UI
function FengYun_JianJiGoto_OnHide()
	this:Hide()
end


function FengYun_JianJiGoto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Help")
		Set_XSCRIPT_ScriptID(820109)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function FengYun_JianJiGoto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(820109)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


