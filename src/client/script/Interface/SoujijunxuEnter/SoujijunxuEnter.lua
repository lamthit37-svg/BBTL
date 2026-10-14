local g_SoujijunxuEnter_Frame_UnifiedXPosition
local g_SoujijunxuEnter_Frame_UnifiedYPosition

--预加载函数，可以而且只能在这里注册脚本关心的事件
function SoujijunxuEnter_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function SoujijunxuEnter_OnLoad()
	-- 保存界面的默认相对位置
	g_SoujijunxuEnter_Frame_UnifiedXPosition	= SoujijunxuEnter_Frame_BK:GetProperty("UnifiedXPosition");
	g_SoujijunxuEnter_Frame_UnifiedYPosition	= SoujijunxuEnter_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SoujijunxuEnter_ResetPos()
	SoujijunxuEnter_Frame_BK:SetProperty("UnifiedXPosition", g_SoujijunxuEnter_Frame_UnifiedXPosition);
	SoujijunxuEnter_Frame_BK:SetProperty("UnifiedYPosition", g_SoujijunxuEnter_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function SoujijunxuEnter_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 99823501 then
	--打开界面
		SoujijunxuEnter_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99823502 then
	--前往寻路
		AutoRuntoTargetExWithName(311, 269, 0, "姜裕明")
		SoujijunxuEnter_Close()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SoujijunxuEnter_OnHide()
	elseif event == "ADJEST_UI_POS" then
		SoujijunxuEnter_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		SoujijunxuEnter_ResetPos()
	end
end

--显示UI
function SoujijunxuEnter_Show()

	this:Show()
end

--隐藏UI
function SoujijunxuEnter_OnHide()
	this:Hide()
end

function SoujijunxuEnter_Hide()
	this:Hide()
end

--关闭界面
function SoujijunxuEnter_Close()
	this:Hide()
end

function SoujijunxuEnter_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskHelp")
		Set_XSCRIPT_ScriptID(998235)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SoujijunxuEnter_Goto()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnJoinInActivity")
		Set_XSCRIPT_ScriptID(998235)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


