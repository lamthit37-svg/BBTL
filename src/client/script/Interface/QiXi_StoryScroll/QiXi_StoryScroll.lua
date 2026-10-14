-- 【2026Q2】七夕联动剧情 剧情动画 zmk

-- 界面的默认相对位置
local g_QiXi_StoryScroll_Frame_UnifiedPosition
local g_QiXi_StoryScroll_ImageBK_Image_UnifiedPosition
local g_nScriptId = 505211
local g_nUICommandID = 50521101

local animate_str_once = "curve:%s mode:Once duration:%s startx:%s starty:%s endx:%s endy:%s"
local from_to_pos = string.format(animate_str_once, "easeInOutSine", 30.0, 0, 0, -3680, 0)

-- 执行tween内容
local function tweenstart(ui, sztype, info, reset)
    if ui == nil then
        return
    end
    if reset == true then
        ui:Tween_Reset(sztype, true)
    end
    ui:Tween_SetInfo(sztype, info)
    ui:Tween_Play(sztype, true, true)
    ui:Show()
end

function QiXi_StoryScroll_PreLoad()
    this:RegisterEvent("UI_COMMAND") -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

function QiXi_StoryScroll_OnLoad()
    -- 保存界面的默认相对位置
    g_QiXi_StoryScroll_Frame_UnifiedPosition = QiXi_StoryScroll_Frame:GetProperty("UnifiedPosition")
    g_QiXi_StoryScroll_ImageBK_Image_UnifiedPosition = QiXi_StoryScroll_ImageBK_Image:GetProperty("UnifiedPosition")
end

function QiXi_StoryScroll_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID then
        QiXi_StoryScroll_OnShow()
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        QiXi_StoryScroll_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        --切换场景关闭界面
        QiXi_StoryScroll_OnClose()
    end
end

function QiXi_StoryScroll_UIReset()
    QiXi_StoryScroll_ImageBK_Image:SetProperty("UnifiedPosition", g_QiXi_StoryScroll_ImageBK_Image_UnifiedPosition)
end

function QiXi_StoryScroll_TweenPlay()
    tweenstart(QiXi_StoryScroll_ImageBK_Image, "Position", from_to_pos, true)
end

--=========================================================
-- 显示界面
--=========================================================
function QiXi_StoryScroll_OnShow()
    -- 关闭影响显示的界面
    -- 关闭地图界面
    ToggleSceneMap(0)

    QiXi_StoryScroll_UIReset()
    QiXi_StoryScroll_TweenPlay()

    this:Show()
end

function QiXi_StoryScroll_StopAllTween()
    QiXi_StoryScroll_ImageBK_Image:Tween_Stop("Position")
end

--=========================================================
-- 关闭界面
--=========================================================
function QiXi_StoryScroll_OnClose()
    this:Hide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function QiXi_StoryScroll_OnHiden()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function QiXi_StoryScroll_OnResetPos()
    QiXi_StoryScroll_Frame:SetProperty("UnifiedPosition", g_QiXi_StoryScroll_Frame_UnifiedPosition)
end

--=========================================================
-- 动画结束
--=========================================================
function QiXi_StoryScroll_OnTweenAniEnd()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnTweenAniEnd")
    Set_XSCRIPT_ScriptID(g_nScriptId)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
    
    QiXi_StoryScroll_OnClose()
end
