local g_QiXi_Growflowers_Goto_Frame_UnifiedXPosition
local g_QiXi_Growflowers_Goto_Frame_UnifiedYPosition
local g_SuShi_PosX = 158
local g_SuShi_PosZ = 98
local g_SuShi_Scene = 1075
local g_SuShi_Name = "许望虞"

--预加载函数，可以而且只能在这里注册脚本关心的事件
function QiXi_Growflowers_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function QiXi_Growflowers_Goto_OnLoad()
	-- 保存界面的默认相对位置
	g_QiXi_Growflowers_Goto_Frame_UnifiedXPosition	= QiXi_Growflowers_Goto_Frame_BK:GetProperty("UnifiedXPosition");
	g_QiXi_Growflowers_Goto_Frame_UnifiedYPosition	= QiXi_Growflowers_Goto_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function QiXi_Growflowers_Goto_ResetPos()
	QiXi_Growflowers_Goto_Frame_BK:SetProperty("UnifiedXPosition", g_QiXi_Growflowers_Goto_Frame_UnifiedXPosition);
	QiXi_Growflowers_Goto_Frame_BK:SetProperty("UnifiedYPosition", g_QiXi_Growflowers_Goto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function QiXi_Growflowers_Goto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 90003101 then
		--打开界面
		QiXi_Growflowers_Goto_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 90003102 then
		--前往寻路
		AutoRuntoTargetExWithName(g_SuShi_PosX, g_SuShi_PosZ, g_SuShi_Scene, g_SuShi_Name)
		QiXi_Growflowers_Goto_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		QiXi_Growflowers_Goto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		QiXi_Growflowers_Goto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_Growflowers_Goto_ResetPos()
	end
end

--显示UI
function QiXi_Growflowers_Goto_Show()

	this:Show()
end

--隐藏UI
function QiXi_Growflowers_Goto_OnHide()
	this:Hide()
end

--关闭界面
function QiXi_Growflowers_Goto_Hide()
	this:Hide()
end


function QiXi_Growflowers_Goto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Help")
		Set_XSCRIPT_ScriptID(900031)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function QiXi_Growflowers_Goto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(900031)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


