-- 2024Q3版本稳活活动
--活动界面
--!!!reloadscript =ERenGuWenHuo

local g_Frame_Pos = nil

--=========
-- PreLoad
--=========
function ERenGuWenHuo_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end

--=========
-- OnLoad
--=========
function ERenGuWenHuo_OnLoad()
	g_Frame_Pos = ERenGuWenHuo_Frame_BK:GetProperty("UnifiedPosition")
end

--=========
-- OnEvent
--=========
function ERenGuWenHuo_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99942801 )  then
		--打开界面
		ERenGuWenHuo_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99942802 )  then 
		--自动寻路
		AutoRuntoTargetExWithName(240,269,0,"山流儿")
	elseif event == "ADJEST_UI_POS" then
		ERenGuWenHuo_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ERenGuWenHuo_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ERenGuWenHuo_OnHide()
	end
end

--=========
-- 重置
--=========
function ERenGuWenHuo_On_ResetPos()
	ERenGuWenHuo_Frame_BK:SetProperty("UnifiedPosition", g_Frame_Pos)
end

--=========
-- 打开
--=========
function ERenGuWenHuo_Open()
	--显示界面
	this:Show()
end

--=========
-- 关闭
--=========
function ERenGuWenHuo_OnHide()
	this:Hide()
end

--=========
-- 点击前往
--=========
function ERenGuWenHuo_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AutoNpc")
		Set_XSCRIPT_ScriptID(999428)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	ERenGuWenHuo_OnHide()
end

--=========
-- 帮助按钮
--=========
function ERenGuWenHuo_ShowHelp()
	PushEvent("CCSHOP_HELP", 219)
end




