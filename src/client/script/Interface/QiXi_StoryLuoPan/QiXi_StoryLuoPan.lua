-- 【2026Q2】七夕联动剧情 任务道具UI

-- 界面的默认相对位置
local g_QiXi_StoryLuoPan_Frame_UnifiedPosition
local g_nScriptId = 505209
local g_nUICommandID = 50520901

-- 任务完成状态
local g_MissionParam = { 0, 0, 0 }
local g_AnimatePos = 0
local g_AnimatePlayInterval = 1000
-- UI组件
local g_Point = {}
local g_CollectionInfo =
{
    scn = 1075,
    name = "遗失的碎镜片",
    pos =
    {
        { 145, 117 },
        { 99,  196 },
        { 182, 39 },
    }
}
local g_NPCInfo =
{
    scn = 1075,
    name = "卢姑娘",
    pos = { 215, 121 },
}

function QiXi_StoryLuoPan_PreLoad()
    this:RegisterEvent("UI_COMMAND") -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

function QiXi_StoryLuoPan_OnLoad()
    -- 保存界面的默认相对位置
    g_QiXi_StoryLuoPan_Frame_UnifiedPosition = QiXi_StoryLuoPan_Frame:GetProperty("UnifiedPosition")
    -- UI控件
    for i = 1, 3 do
        local btn = _G["QiXi_StoryLuoPan_Point_" .. i .. "_GoButton"]
        local img = _G["QiXi_StoryLuoPan_Point_" .. i .. "_Img"]
        local arr = _G["QiXi_StoryLuoPan_Point_" .. i .. "_Arrival"]
        g_Point[i] = { btn = btn, img = img, arr = arr }
    end
end

function QiXi_StoryLuoPan_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID then
        -- 0 关闭, 1 打开, 2 刷新
        local nOpType = Get_XParam_INT(0)

        -- 关闭界面
        if nOpType == 0 then
            if this:IsVisible() then
                QiXi_StoryLuoPan_Close()
            end
        end

        -- 打开界面
        if nOpType == 1 then
            QiXi_StoryLuoPan_Reset()
            QiXi_StoryLuoPan_ParamInit()
            QiXi_StoryLuoPan_Update()
            this:Show()
            -- 刷新
        elseif nOpType == 2 then
            QiXi_StoryLuoPan_ParamInit()
            QiXi_StoryLuoPan_Update()
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        QiXi_StoryLuoPan_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        QiXi_StoryLuoPan_Close()
    end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function QiXi_StoryLuoPan_ParamInit()
    g_MissionParam[1] = Get_XParam_INT(1)
    g_MissionParam[2] = Get_XParam_INT(2)
    g_MissionParam[3] = Get_XParam_INT(3)
    g_AnimatePos = Get_XParam_INT(4)
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function QiXi_StoryLuoPan_Reset()
    g_MissionParam[1] = 0
    g_MissionParam[2] = 0
    g_MissionParam[3] = 0
    g_AnimatePos = 0
end

--=========================================================
-- 界面更新
--=========================================================
function QiXi_StoryLuoPan_Update()
    for i = 1, 3 do
        if g_AnimatePos == i then
            g_Point[i].btn:Hide()
            g_Point[i].img:Show()
            g_Point[i].arr:Show()
            g_Point[i].arr:Play(true)
            SetTimer("QiXi_StoryLuoPan", "QiXi_StoryLuoPan_AnimateTimer()", g_AnimatePlayInterval)
        elseif g_MissionParam[i] == 1 then
            g_Point[i].btn:Hide()
            g_Point[i].img:Show()
            g_Point[i].arr:Hide()
        else
            g_Point[i].btn:Show()
            g_Point[i].img:Hide()
            g_Point[i].arr:Hide()
        end
    end

    if g_MissionParam[1] == 1 and g_MissionParam[2] == 1 and g_MissionParam[3] == 1 then
        QiXi_StoryLuoPan_Finsh_GoButton:Show()
        QiXi_StoryLuoPan_Client:Hide()
        QiXi_StoryLuoPan_Client_2:Show()
    else
        QiXi_StoryLuoPan_Finsh_GoButton:Hide()
        QiXi_StoryLuoPan_Client:Show()
        QiXi_StoryLuoPan_Client_2:Hide()
    end
end

--=========================================================
-- 动画结束
--=========================================================
function QiXi_StoryLuoPan_AnimateTimer()
    for i = 1, 3 do
        g_Point[i].arr:Play(false)
        g_Point[i].arr:Hide()
    end
    KillTimer("QiXi_StoryLuoPan_AnimateTimer()")
end

--=========================================================
-- 点击前往
--=========================================================
function QiXi_StoryLuoPan_Point_GoButton_OnClick(idx)
    if idx < 1 or idx > table.getn(g_CollectionInfo.pos) then
        return
    end
    PushDebugMessage("#{XYYJ_260529_254}")
    local pos = g_CollectionInfo.pos[idx]
    AutoRunToTargetEx(pos[1], pos[2], g_CollectionInfo.scn, g_CollectionInfo.name)
end

--=========================================================
-- 点击回收
--=========================================================
function QiXi_StoryLuoPan_Finsh_GoButton_OnClick()
    AutoRuntoTargetExWithName(g_NPCInfo.pos[1], g_NPCInfo.pos[2], g_NPCInfo.scn, g_NPCInfo.name)
    QiXi_StoryLuoPan_OnHiden()
end

--=========================================================
-- 关闭界面
--=========================================================
function QiXi_StoryLuoPan_Close()
    this:Hide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function QiXi_StoryLuoPan_OnHiden()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function QiXi_StoryLuoPan_OnResetPos()
    QiXi_StoryLuoPan_Frame:SetProperty("UnifiedPosition", g_QiXi_StoryLuoPan_Frame_UnifiedPosition)
end
