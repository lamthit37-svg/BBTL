--Anniversary_SJZYX.lua
--UICOMMANDINDEX 99841701 - interface 1921
local g_Anniversary_SJZYX_Frame_UnifiedPosition
local g_Anniversary_SJZYX_NPC_sceneID = 0 --洛阳
local g_Anniversary_SJZYX_NPC_posX = 274
local g_Anniversary_SJZYX_NPC_posZ = 270
local g_Anniversary_GoToNpcName = "周庆达"

function Anniversary_SJZYX_PreLoad()
    --uicommand
    this:RegisterEvent("UI_COMMAND")
	--场景切换
	this:RegisterEvent("ON_SCENE_TRANS")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

function Anniversary_SJZYX_OnLoad()
	--this:Hide()
    g_Anniversary_SJZYX_Frame_UnifiedPosition = Anniversary_SJZYX_Frame_BK:GetProperty("UnifiedPosition")
end

function Anniversary_SJZYX_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == 99841701 then
        local operator = Get_XParam_INT(0)
        if operator == 1 then--打开界面
            this:Show()
        elseif operator == 2 then--自动寻路
            AutoRuntoTargetExWithName(g_Anniversary_SJZYX_NPC_posX, g_Anniversary_SJZYX_NPC_posZ, g_Anniversary_SJZYX_NPC_sceneID, g_Anniversary_GoToNpcName)
        end
    elseif event == "ON_SCENE_TRANS" then
		Anniversary_SJZYX_OnHide()
	elseif (event == "ADJEST_UI_POS" ) then
        Anniversary_SJZYX_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Anniversary_SJZYX_Frame_On_ResetPos()
	end	
end

--前往参与按钮 todo allowfunc
function Anniversary_SJZYX_Goto()
    --周年打卡活动
	Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("GoToTarget")
        Set_XSCRIPT_ScriptID(998417) 
        Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

--帮助按钮
function Anniversary_SJZYX_ShowHelp()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")
		Set_XSCRIPT_ScriptID( 998417 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--关闭按钮
function Anniversary_SJZYX_OnHide()
    this:Hide()
end

--游戏窗口尺寸变化
--游戏分辨率变化
function Anniversary_SJZYX_Frame_On_ResetPos()
    Anniversary_SJZYX_Frame_BK:SetProperty("UnifiedPosition", g_Anniversary_SJZYX_Frame_UnifiedPosition)
end