-- 【2024Q4】冰雪节版本预热活动
local g_Bingxuejie_Yr_Frame_UnifiedPosition
local g_nScriptId = 999485
local g_nUICommandID = 99948501
-- 累计完成
local g_TotalDoneCount = 0
-- 今天任务
local g_TodayState = { 0, 0 } -- 0 未接； 1 未完成； 2 完成
-- 奖励
local g_RewardRecord = { 0, 0, 0 }
local g_RewardItems = {
    { itemId = 20501003, num = 1 },
    { itemId = 38000807, num = 1 },
    { itemId = 20502003, num = 1 },
    { itemId = 38007691, num = 1 }
}
local g_NeedPoint = { 2, 4, 7 }
-- 入口NPC
local Frozen_PVPGoto_EnterNPCInfo =
{
    scn = 0,
    pos = {254, 251},
    name = "云凛凛",
} -- end Frozen_PVPGoto_EnterNPCInfo

--=========================================================
-- PreLoad
--=========================================================
function Bingxuejie_Yr_PreLoad()
    this:RegisterEvent("UI_COMMAND") -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function Bingxuejie_Yr_OnLoad()
    g_Bingxuejie_Yr_Frame_UnifiedPosition = Bingxuejie_Yr:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function Bingxuejie_Yr_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID then
        -- 0 关闭, 1 打开, 2 刷新
        local nOpType = Get_XParam_INT(0)

        -- 关闭界面
        if nOpType == 0 then
            if this:IsVisible() then
                Bingxuejie_Yr_OnClose()
            end
        end

        -- 打开界面
        if nOpType == 1 then
            Bingxuejie_Yr_Reset()
            Bingxuejie_Yr_ParamInit()
            Bingxuejie_Yr_Update()
            this:Show()
            -- 刷新
        elseif nOpType == 2 then
            Bingxuejie_Yr_ParamInit()
            Bingxuejie_Yr_Update()
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        Bingxuejie_Yr_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        Bingxuejie_Yr_OnClose()
    end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Bingxuejie_Yr_ParamInit()
    g_TotalDoneCount  = Get_XParam_INT(1)
    g_TodayState[1]   = Get_XParam_INT(2)
    g_TodayState[2]   = Get_XParam_INT(3)
    g_RewardRecord[1] = Get_XParam_INT(4)
    g_RewardRecord[2] = Get_XParam_INT(5)
    g_RewardRecord[3] = Get_XParam_INT(6)
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Bingxuejie_Yr_Reset()
    g_TotalDoneCount  = 0
    g_TodayState[1]   = 0
    g_TodayState[2]   = 0
    g_RewardRecord[1] = 0
    g_RewardRecord[2] = 0
    g_RewardRecord[3] = 0
end

--=========================================================
-- 界面更新
--=========================================================
function Bingxuejie_Yr_Update()
    -- 任务1
    Bingxuejie_Yr_Item1_InfoBK:Hide()
    Bingxuejie_Yr_Item1_InfoBK_Lock:Hide()
    Bingxuejie_Yr_Item1_GoToBtn:Hide()
    if g_TodayState[1] == 0 then
        -- 未领取
        Bingxuejie_Yr_Item1_GoToBtn:Show()
    elseif g_TodayState[1] == 1 then
        -- 未完成
        Bingxuejie_Yr_Item1_GoToBtn:Show()
    elseif g_TodayState[1] == 2 then
        -- 已完成
        Bingxuejie_Yr_Item1_InfoBK:Show()
    end

    -- 任务2
    Bingxuejie_Yr_Item2_InfoBK:Hide()
    Bingxuejie_Yr_Item2_InfoBK_Lock:Hide()
    Bingxuejie_Yr_Item2_GoToBtn:Hide()
    if g_TodayState[2] == 0 then
        -- 未领取
        if g_TodayState[1] ~= 2 then
            -- 任务一未完成
            Bingxuejie_Yr_Item2_InfoBK_Lock:Show()
        else
            -- 任务一已完成
            Bingxuejie_Yr_Item2_GoToBtn:Show()
        end
    elseif g_TodayState[2] == 1 then
        -- 未完成
        Bingxuejie_Yr_Item2_GoToBtn:Show()
    elseif g_TodayState[2] == 2 then
        -- 已完成
        Bingxuejie_Yr_Item2_InfoBK:Show()
    end

    -- 奖励
    for i = 1, 3 do
        _G["Bingxuejie_Yr_RedDot" .. i]:Hide()
        _G["Bingxuejie_Yr_Received" .. i]:Hide()

        -- 展示奖励
        if g_TotalDoneCount >= g_NeedPoint[i] then
            if g_RewardRecord[i] == 0 then
                -- 可领取
                _G["Bingxuejie_Yr_RedDot" .. i]:Show()
            else
                -- 已领取
                _G["Bingxuejie_Yr_Received" .. i]:Show()
            end
        else
        end
    end

    --进度条相关
    Bingxuejie_Yr_EXP:SetProgress(g_TotalDoneCount, 7)
    local str = ScriptGlobal_Format("#{DDBB_240912_134}", g_TotalDoneCount)
    Bingxuejie_Yr_GiftTips_Num:SetText(str)
    -- -- 门票
    -- Bingxuejie_Yr_GetTravelValue_Btn1:Hide()
    -- Bingxuejie_Yr_BtnYiLingQu1:Hide()
    -- Bingxuejie_Yr_GetTravelValue_Tips1:Hide()
    -- if g_RewardTicket == 0 and g_TotalDoneCount < 7 then
    --     -- 待解锁
    --     Bingxuejie_Yr_GetTravelValue_Btn1:Show()
    --     Bingxuejie_Yr_GetTravelValue_Btn1:Disable()
    -- elseif g_RewardTicket == 0 and g_TotalDoneCount >= 7 then
    --     -- 可领取
    --     Bingxuejie_Yr_GetTravelValue_Btn1:Show()
    --     Bingxuejie_Yr_GetTravelValue_Btn1:Enable()
    --     Bingxuejie_Yr_GetTravelValue_Tips1:Show()
    -- elseif g_RewardTicket == 1 then
    --     Bingxuejie_Yr_BtnYiLingQu1:Show()
    -- else
    --     -- PushDebugMessage(g_RewardTicket .. "  " .. g_TotalDoneCount)
    -- end
end

--=========================================================
-- 点击领取
--=========================================================
function Bingxuejie_Yr_Reward_OnRewardClick(idx)
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnReward")
    Set_XSCRIPT_ScriptID(g_nScriptId)
    Set_XSCRIPT_Parameter(0, idx)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

--=========================================================
-- 点击帮助
--=========================================================
function Bingxuejie_Yr_ShowHelp()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnHelp")
    Set_XSCRIPT_ScriptID(g_nScriptId)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

--=========================================================
-- 点击前往
--=========================================================
function Bingxuejie_Yr_Goto(index)
    -- 寻路前往入口NPC
    local targetInfo = Frozen_PVPGoto_EnterNPCInfo
    if (targetInfo ~= nil) then
        AutoRuntoTargetExWithName(targetInfo.pos[1], targetInfo.pos[2], targetInfo.scn, targetInfo.name)
    end
    
    -- 关闭UI
    Bingxuejie_Yr_OnHiden()
end

--=========================================================
-- 关闭界面
--=========================================================
function Bingxuejie_Yr_OnClose()
    this:Hide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function Bingxuejie_Yr_OnHiden()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function Bingxuejie_Yr_OnResetPos()
    Bingxuejie_Yr:SetProperty("UnifiedPosition", g_Bingxuejie_Yr_Frame_UnifiedPosition)
end
