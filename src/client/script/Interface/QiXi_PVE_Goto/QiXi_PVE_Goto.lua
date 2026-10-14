local g_QiXi_PVE_Goto_Frame_UnifiedXPosition
local g_QiXi_PVE_Goto_Frame_UnifiedYPosition


local g_Rand_MainCity =
{
	[1] = {PosX = 208, PosZ = 51, Scene = 1075, Name = "溯缘镜"}, --垓下
}


--预加载函数，可以而且只能在这里注册脚本关心的事件
function QiXi_PVE_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--加载窗口的时候调用的函数，加载窗口时调用一次
function QiXi_PVE_Goto_OnLoad()
	-- 保存界面的默认相对位置
	g_QiXi_PVE_Goto_Frame_UnifiedXPosition	= QiXi_PVE_Goto_Frame:GetProperty("UnifiedXPosition");
	g_QiXi_PVE_Goto_Frame_UnifiedYPosition	= QiXi_PVE_Goto_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function QiXi_PVE_Goto_ResetPos()
	QiXi_PVE_Goto_Frame:SetProperty("UnifiedXPosition", g_QiXi_PVE_Goto_Frame_UnifiedXPosition);
	QiXi_PVE_Goto_Frame:SetProperty("UnifiedYPosition", g_QiXi_PVE_Goto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function QiXi_PVE_Goto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 05123805 then
		local opType =  Get_XParam_INT( 0 )
		if opType == 10 then
			AutoRuntoTargetExWithName(g_Rand_MainCity[1].PosX,g_Rand_MainCity[1].PosZ,g_Rand_MainCity[1].Scene,g_Rand_MainCity[1].Name)
			QiXi_PVE_Goto_OnHide()
		elseif opType == 1 then
			QiXi_PVE_Goto_Show()
		end
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		QiXi_PVE_Goto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		QiXi_PVE_Goto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_PVE_Goto_ResetPos()
	end
end

--显示UI
function QiXi_PVE_Goto_Show()
	this:Show()
end

--隐藏UI
function QiXi_PVE_Goto_OnHide()
	this:Hide()
end

--关闭界面
function QiXi_PVE_Goto_Hide()
	this:Hide()
end


function QiXi_PVE_Goto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UIHelp")
		Set_XSCRIPT_ScriptID(051238)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function QiXi_PVE_Goto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UIGOTO")
		Set_XSCRIPT_ScriptID(051238)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


