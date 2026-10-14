local g_Anniversary_DishuGoto_Frame_UnifiedXPosition
local g_Anniversary_DishuGoto_Frame_UnifiedYPosition

local g_Rand_MainCity =
{
	[1] = {PosX = 398, PosZ = 213, Scene = 0, Name = "方谐风"}, --洛阳
	[2] = {PosX = 383, PosZ = 349, Scene = 1, Name = "方谐风"}, --苏州
	[3] = {PosX = 138, PosZ = 280, Scene = 2, Name = "方谐风"}, --大理
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Anniversary_DishuGoto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Anniversary_DishuGoto_OnLoad()
	-- 保存界面的默认相对位置
	g_Anniversary_DishuGoto_Frame_UnifiedXPosition	= Anniversary_DishuGoto_Frame_BK:GetProperty("UnifiedXPosition");
	g_Anniversary_DishuGoto_Frame_UnifiedYPosition	= Anniversary_DishuGoto_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Anniversary_DishuGoto_ResetPos()
	Anniversary_DishuGoto_Frame_BK:SetProperty("UnifiedXPosition", g_Anniversary_DishuGoto_Frame_UnifiedXPosition);
	Anniversary_DishuGoto_Frame_BK:SetProperty("UnifiedYPosition", g_Anniversary_DishuGoto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Anniversary_DishuGoto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 99844501 then
		--打开界面
		Anniversary_DishuGoto_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99844502 then
		--前往寻路
		local RandVal = math.random( 1, 3 )
		local score = Get_XParam_INT(0)
		if score == 0 or score == 1 or score == 2 then
			RandVal = score + 1
		end
		AutoRuntoTargetExWithName(g_Rand_MainCity[RandVal].PosX,g_Rand_MainCity[RandVal].PosZ,g_Rand_MainCity[RandVal].Scene,g_Rand_MainCity[RandVal].Name)
		Anniversary_DishuGoto_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Anniversary_DishuGoto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_DishuGoto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_DishuGoto_ResetPos()
	end
end

--显示UI
function Anniversary_DishuGoto_Show()

	this:Show()
end

--隐藏UI
function Anniversary_DishuGoto_OnHide()
	this:Hide()
end

--关闭界面
function Anniversary_DishuGoto_Hide()
	this:Hide()
end


function Anniversary_DishuGoto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Help")
		Set_XSCRIPT_ScriptID(998445)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Anniversary_DishuGoto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(998445)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


