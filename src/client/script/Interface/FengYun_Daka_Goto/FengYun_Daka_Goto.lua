local g_FengYun_Daka_Goto_Frame_UnifiedXPosition
local g_FengYun_Daka_Goto_Frame_UnifiedYPosition

local g_Rand_MainCity =
{
	[1] = {PosX = 283, PosZ = 112, Scene = 1055, Name = "无名"},
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function FengYun_Daka_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FengYun_Daka_Goto_OnLoad()
	-- 保存界面的默认相对位置
	g_FengYun_Daka_Goto_Frame_UnifiedXPosition	= FengYun_Daka_Goto_Frame:GetProperty("UnifiedXPosition");
	g_FengYun_Daka_Goto_Frame_UnifiedYPosition	= FengYun_Daka_Goto_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FengYun_Daka_Goto_ResetPos()
	FengYun_Daka_Goto_Frame:SetProperty("UnifiedXPosition", g_FengYun_Daka_Goto_Frame_UnifiedXPosition);
	FengYun_Daka_Goto_Frame:SetProperty("UnifiedYPosition", g_FengYun_Daka_Goto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FengYun_Daka_Goto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 89360202 then
		--打开界面
		local opType = Get_XParam_INT(0)
		if opType == 1 then
			FengYun_Daka_Goto_Show()
		elseif opType == 3 then
			FengYun_Daka_Goto_ShowMiniMap(Get_XParam_INT(1))
		else
			local RandVal = 1
			AutoRuntoTargetExWithName(g_Rand_MainCity[RandVal].PosX,g_Rand_MainCity[RandVal].PosZ,g_Rand_MainCity[RandVal].Scene,g_Rand_MainCity[RandVal].Name)
			FengYun_Daka_Goto_OnHide()
		end
	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_Daka_Goto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		FengYun_Daka_Goto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_Daka_Goto_ResetPos()
	end
end

--显示UI
function FengYun_Daka_Goto_Show()

	this:Show()
end

--隐藏UI
function FengYun_Daka_Goto_OnHide()
	this:Hide()
end


function FengYun_Daka_Goto_ShowHelp()
	PushEvent("CCSHOP_HELP", 244)
end

function FengYun_Daka_Goto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(893602)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function FengYun_Daka_Goto_ShowMiniMap(idx)
	LuaFnFengYunTargetOnMiniMap(idx)
end
