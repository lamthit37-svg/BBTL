-- 【2025Q1】侠客行引导任务
-- 界面脚本
local g_XiaKeTL_Guide_Frame_UnifiedPosition
local g_nScriptId = 999630
local g_nUICommandID = 99963001
-- 任务状态
local g_TaskState = { 0, 0, 0, 0, 0 } -- 0 未接； 1 未完成； 2 完成
local g_ImageValues = {
    { "XiaKeTL_Guide",  "XiaKeTL_Guide1" },
    { "XiaKeTL_Guide",  "XiaKeTL_Guide2" },
    { "XiaKeTL_Guide2", "XiaKeTL_Guide2_3" },
    { "XiaKeTL_Guide2", "XiaKeTL_Guide2_4" },
    { "XiaKeTL_Guide3", "XiaKeTL_Guide3_5" },
}
-- 入口NPC
local XiaKeTL_Guide_PVPGoto_EnterNPCInfo =
{
    scn = 1016,
    pos = { 130, 15 },
    name = "木影",
}
--=========================================================
-- PreLoad
--=========================================================
function XiaKeTL_Guide_PreLoad()
    this:RegisterEvent("UI_COMMAND") -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function XiaKeTL_Guide_OnLoad()
    g_XiaKeTL_Guide_Frame_UnifiedPosition = XiaKeTL_Guide_Frame:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function XiaKeTL_Guide_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID then
        -- 0 关闭, 1 打开, 2 刷新
        local nOpType = Get_XParam_INT(0)

        -- 关闭界面
        if nOpType == 0 then
            if this:IsVisible() then
                XiaKeTL_Guide_OnClose()
            end
        end

        -- 打开界面
        if nOpType == 1 then
            XiaKeTL_Guide_Reset()
            XiaKeTL_Guide_ParamInit()
            XiaKeTL_Guide_Update()
            this:Show()
            -- 刷新
        elseif nOpType == 2 then
            XiaKeTL_Guide_ParamInit()
            XiaKeTL_Guide_Update()
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        XiaKeTL_Guide_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        XiaKeTL_Guide_OnClose()
    end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function XiaKeTL_Guide_ParamInit()
    for i = 1, table.getn(g_TaskState) do
        g_TaskState[i] = Get_XParam_INT(i)
    end
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function XiaKeTL_Guide_Reset()
    for i = 1, table.getn(g_TaskState) do
        g_TaskState[i] = 0
    end
end

--=========================================================
-- 界面更新
--=========================================================
function XiaKeTL_Guide_Update()
    local idx = XiaKeTL_Guide_GetLastTask()
    if idx == -1 then
        XiaKeTL_Guide_LetterBK:SetImage("")
    else
        XiaKeTL_Guide_LetterBK:SetImage(g_ImageValues[idx][1], g_ImageValues[idx][2])
    end
end

--=========================================================
-- 点击前往
--=========================================================
function XiaKeTL_Guide_Goto()
    local nLevel = Player:GetLevel()
    if nLevel < 30 then
        PushDebugMessage("#{XKXYD_250116_02}")
        return
    end

    -- 寻路前往入口NPC
    local targetInfo = XiaKeTL_Guide_PVPGoto_EnterNPCInfo
    if targetInfo ~= nil then
        AutoRuntoTargetExWithName(targetInfo.pos[1], targetInfo.pos[2], targetInfo.scn, targetInfo.name)
    end

    -- 关闭UI
    XiaKeTL_Guide_OnHiden()
end

--=========================================================
-- 关闭界面
--=========================================================
function XiaKeTL_Guide_OnClose()
    this:Hide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function XiaKeTL_Guide_OnHiden()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function XiaKeTL_Guide_OnResetPos()
    XiaKeTL_Guide_Frame:SetProperty("UnifiedPosition", g_XiaKeTL_Guide_Frame_UnifiedPosition)
end

--=========================================================
-- 获取最后未完成的任务
-- 如果没有找到，则返回-1
--=========================================================
function XiaKeTL_Guide_GetLastTask()
    for i = 1, table.getn(g_TaskState) do
        if g_TaskState[i] == 0 then
            return i
        end
    end
    return -1
end
