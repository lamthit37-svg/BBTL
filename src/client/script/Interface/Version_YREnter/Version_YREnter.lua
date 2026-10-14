-- 【2024Q2】Q2版本预热活动
local g_Version_YREnter_Frame_UnifiedPosition
local g_nScriptId = 999185
local g_nUICommandID = 99918501

--周博恒 NPC
local g_NPCPosX = 296
local g_NPCPosZ = 225
local g_NPCSceneId = 0
local g_NPCName = "周博恒"

--=========================================================
-- PreLoad
--=========================================================
function Version_YREnter_PreLoad()
    this:RegisterEvent("UI_COMMAND")	-- UI_COMMAND
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	-- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function Version_YREnter_OnLoad()
    g_Version_YREnter_Frame_UnifiedPosition = Version_YREnter_Frame_BK:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function Version_YREnter_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID then
        -- 0 关闭, 1 打开, 2 刷新，3 寻路
        local nOpType = Get_XParam_INT(0)

        -- 关闭界面
        if nOpType == 0 then
            if this:IsVisible() then
                Version_YREnter_OnClose()
            end
        end

        -- 打开界面
        if nOpType == 1 then
            Version_YREnter_Reset()
            Version_YREnter_ParamInit()
            Version_YREnter_Update()
            this:Show()
        -- 刷新
        elseif nOpType == 2 then
            Version_YREnter_ParamInit()
            Version_YREnter_Update()
        -- 寻路
        elseif nOpType == 3 then
            Version_YREnter_GotoNPC()
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        Version_YREnter_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        Version_YREnter_OnClose()
    end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Version_YREnter_ParamInit()
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Version_YREnter_Reset() 
end

--=========================================================
-- 界面更新
--=========================================================
function Version_YREnter_Update()
end

--=========================================================
-- 点击帮助
--=========================================================
function Version_YREnter_ShowHelp()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnHelp")
        Set_XSCRIPT_ScriptID(g_nScriptId)
        Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end
--=========================================================
-- 点击参加
--=========================================================
function Version_YREnter_Goto()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnParticipate")
        Set_XSCRIPT_ScriptID(g_nScriptId)
        Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function Version_YREnter_OnClose()
    this:Hide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function Version_YREnter_OnHide()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function Version_YREnter_OnResetPos()
    Version_YREnter_Frame_BK:SetProperty("UnifiedPosition", g_Version_YREnter_Frame_UnifiedPosition)
end

--=========================================================
-- 寻路
--=========================================================
function Version_YREnter_GotoNPC()
    AutoRuntoTargetExWithName(g_NPCPosX, g_NPCPosZ, g_NPCSceneId, g_NPCName)
    PushDebugMessage("#{SJYR_240516_10}")
end