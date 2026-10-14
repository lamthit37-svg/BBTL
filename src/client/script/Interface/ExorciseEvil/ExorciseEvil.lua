-- 每日/每周杀怪经验
-- 界面脚本
--!!!reloadscript =ExorciseEvil
local g_ExorciseEvil_UnifiedPosition
local g_nScriptId = 999736
local g_nUICommandID = 99973601
local g_npcId = -1
local g_objCared = -1
local g_nKillMonsterCount = 0
local g_nKillMonsterCountWeekly = 0
local g_TotalExp = 0
local g_TaskTotalExpLimit = 99999999
--=========================================================
-- PreLoad
--=========================================================
function ExorciseEvil_PreLoad()
    this:RegisterEvent("UI_COMMAND", true) -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function ExorciseEvil_OnLoad()
    g_ExorciseEvil_UnifiedPosition = ExorciseEvil_Frame:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function ExorciseEvil_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID then
        -- 0 关闭, 1 打开, 2 刷新
        local nOpType = Get_XParam_INT(0)

        -- 关闭界面
        if nOpType == 0 then
            if this:IsVisible() then
                ExorciseEvil_OnClose()
            end
        end
        g_npcId = Get_XParam_INT(1)
        local objCared = DataPool:GetNPCIDByServerID(g_npcId)
        ExorciseEvil_BeginCareObject(objCared)
        -- 打开界面
        if nOpType == 1 then
            if this:IsVisible() then
                this:Hide()
            end
            ExorciseEvil_Reset()
            ExorciseEvil_ParamInit()
            ExorciseEvil_Update()
            this:Show()
            -- 刷新
        elseif nOpType == 2 then
            ExorciseEvil_ParamInit()
            ExorciseEvil_Update()
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        ExorciseEvil_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        ExorciseEvil_OnClose()
    end
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function ExorciseEvil_Reset()
    g_nKillMonsterCount = 0
    g_nKillMonsterCountWeekly = 0
    g_TotalExp = 0
end

--=========================================================
-- 界面参数初始化
--=========================================================
function ExorciseEvil_ParamInit()
    g_nKillMonsterCount = Get_XParam_INT(2)
    g_nKillMonsterCountWeekly = Get_XParam_INT(3)
    g_TotalExp = Get_XParam_INT(4)
end

--=========================================================
-- 界面更新
--=========================================================
function ExorciseEvil_Update()
    local level = Player:GetLevel()
    local exp, expPoolLimit, expBonus = DataPool:Lua_GetKillMonsterTaskExp(level)
    local expBonusStr = tostring(expBonus) .. "%"

    -- 顶部文字
    if level >= 110 then
        ExorciseEvil_Info:SetText("#{CJJY_250806_06}")
        ExorciseEvil_EXP_Up:Hide()
    else
        ExorciseEvil_Info:SetText(ScriptGlobal_Format("#{CJJY_250806_07}", level, expBonusStr))
        ExorciseEvil_EXP_Up:Show()
    end
    -- 设置杀怪数
    ExorciseEvil_KillNum_Day:SetText(ScriptGlobal_Format("#{CJJY_250806_15}", g_nKillMonsterCount))
    ExorciseEvil_KillNum_Week:SetText(ScriptGlobal_Format("#{CJJY_250806_16}", g_nKillMonsterCountWeekly))

    -- 进度条
    local st = math.floor(g_nKillMonsterCountWeekly / 700)
    if st == 20 then
        st = st - 1
    end
    ExorciseEvil_Reward1_Text:SetText(st * 700)
    ExorciseEvil_Reward2_Text:SetText((st + 1) * 700)
    local progress = g_nKillMonsterCountWeekly - 700 * st
    ExorciseEvil_Progress:SetProgress(progress, 700)

    local tooltip
    if level >= 110 then
        tooltip = ScriptGlobal_Format("#{CJJY_250806_10}", level, exp)
    else
        tooltip = ScriptGlobal_Format("#{CJJY_250806_09}", level, exp, expBonusStr)
    end
    ExorciseEvil_KillNum_Week:SetToolTip(tooltip)
    ExorciseEvil_ProgressBK:SetToolTip(tooltip)
    ExorciseEvil_Progress:SetToolTip(tooltip)

    ExorciseEvil_LevelBox:SetToolTip(ScriptGlobal_Format("#{CJJY_250806_18}", expPoolLimit))
    ExorciseEvil_LevelBox_Text:SetText(ScriptGlobal_Format("#{CJJY_250806_19}", g_TotalExp))
end

--=========================================================
-- 获取杀怪任务经验
--=========================================================
function ExorciseEvil_LevelBox_Clicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("GetRewardExp")
    Set_XSCRIPT_ScriptID(g_nScriptId)
    Set_XSCRIPT_ParamCount(0)

    Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function ExorciseEvil_OnClose()
    this:Hide()
end

--=========================================================
-- 杀怪获取帮助
--=========================================================
function ExorciseEvil_Help_Clicked()
    PushEvent("QUEST_HELPINFO", "#{CJJY_250806_04}")
end

--=========================================================
-- 界面隐藏
--=========================================================
function ExorciseEvil_OnHiden()
    ExorciseEvil_StopCareObject()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function ExorciseEvil_OnResetPos()
    ExorciseEvil_Frame:SetProperty("UnifiedPosition", g_ExorciseEvil_UnifiedPosition)
end

--=========================================================
--开始关心NPC
--=========================================================
function ExorciseEvil_BeginCareObject(objCaredId)
    if g_objCared ~= -1 then
        this:CareObject(objCaredId, 0, "ExorciseEvil");
    end
    g_objCared = objCaredId
    this:CareObject(g_objCared, 1, "ExorciseEvil")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ExorciseEvil_StopCareObject()
    if g_objCared ~= -1 then
        this:CareObject(g_objCared, 0, "ExorciseEvil");
        g_objCared = -1
    end
end
