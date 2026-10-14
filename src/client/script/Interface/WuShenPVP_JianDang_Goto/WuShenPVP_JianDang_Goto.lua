local g_WuShenPVP_JianDang_Goto_Frame_UnifiedXPosition
local g_WuShenPVP_JianDang_Goto_Frame_UnifiedYPosition

--预加载函数，可以而且只能在这里注册脚本关心的事件
function WuShenPVP_JianDang_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function WuShenPVP_JianDang_Goto_OnLoad()
	-- 保存界面的默认相对位置
	g_WuShenPVP_JianDang_Goto_Frame_UnifiedXPosition	= WuShenPVP_JianDang_Goto_Frame_BK:GetProperty("UnifiedXPosition");
	g_WuShenPVP_JianDang_Goto_Frame_UnifiedYPosition	= WuShenPVP_JianDang_Goto_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function WuShenPVP_JianDang_Goto_ResetPos()
	WuShenPVP_JianDang_Goto_Frame_BK:SetProperty("UnifiedXPosition", g_WuShenPVP_JianDang_Goto_Frame_UnifiedXPosition);
	WuShenPVP_JianDang_Goto_Frame_BK:SetProperty("UnifiedYPosition", g_WuShenPVP_JianDang_Goto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function WuShenPVP_JianDang_Goto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 89338501 then
		--打开界面
		WuShenPVP_JianDang_Goto_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89338502 then 
		AutoRuntoTargetExWithName(231,269,0,"宋讨虏")
		WuShenPVP_JianDang_Goto_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuShenPVP_JianDang_Goto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		WuShenPVP_JianDang_Goto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		WuShenPVP_JianDang_Goto_ResetPos()
	end
end

--显示UI
function WuShenPVP_JianDang_Goto_Show()
	this:Show()
end

--隐藏UI
function WuShenPVP_JianDang_Goto_OnHide()
	this:Hide()
end


function WuShenPVP_JianDang_Goto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Help")
		Set_XSCRIPT_ScriptID(893385)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function WuShenPVP_JianDang_Goto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(893385)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


