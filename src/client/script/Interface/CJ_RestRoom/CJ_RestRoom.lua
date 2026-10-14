-- 吃鸡玩法 休息室人数、倒计时等展示UI
-- mini UI打开状态
local CJ_RestRoom_OpenMiniUIState = 0
-- 默认位置
local CJ_RestRoom_UnifiedPosition = nil
-- 控件表
local CJ_RestRoom_CtrlList = nil

-- 比赛匹配类型
local CJ_RestRoom_MatchType =
{
    single = 1,                 -- 单人模式
    team = 2,                   -- 组队模式
} -- end CJ_RestRoom_MatchType

-- 场景逻辑状态
local CJ_RestRoom_LogicState =
{
    before_act = 2,             -- 逻辑开启 但是活动还未开启
    in_act = 3,                 -- 活动开启
    after_act = 4,              -- 活动结束 但是逻辑还未结束
} -- end CJ_RestRoom_LogicState



function CJ_RestRoom_PreLoad()
	this:RegisterEvent("TLCJ_REST_RESTINFOOPEN", true)
    this:RegisterEvent("TLCJ_REST_RESTINFOCLOSE", true)
    this:RegisterEvent("TLCJ_REST_RESTINFOUPDATE", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func CJ_RestRoom_PreLoad()

function CJ_RestRoom_OnEvent(event)
    if (event == "TLCJ_REST_RESTINFOOPEN") then
        CJ_RestRoom_OpenMiniUIState = 0
        --CJ_RestRoom_Show()
    elseif (event == "TLCJ_REST_RESTINFOCLOSE") then
        CJ_RestRoom_OpenMiniUIState = 1
        CJ_RestRoom_Hide()
    elseif (event == "TLCJ_REST_RESTINFOUPDATE") then
        if (CJ_RestRoom_OpenMiniUIState <= 0 and not this:IsVisible()) then
            CJ_RestRoom_Show()
        end

		CJ_RestRoom_UpdateRestInfo(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4))
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CJ_RestRoom_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CJ_RestRoom_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		CJ_RestRoom_UnifiedPos()
	end
end -- end func CJ_RestRoom_OnEvent()

function CJ_RestRoom_OnLoad()
	CJ_RestRoom_UnifiedPosition = CJ_RestRoom:GetProperty("UnifiedPosition")
end -- end func CJ_RestRoom_OnLoad()

-- 界面默认位置
function CJ_RestRoom_UnifiedPos()
	if (CJ_RestRoom_UnifiedPosition ~= nil) then
		CJ_RestRoom:SetProperty("UnifiedPosition", CJ_RestRoom_UnifiedPosition)
	end
end -- end func CJ_RestRoom_UnifiedPos()

function CJ_RestRoom_Show()
    this:Show()
end -- end func CJ_RestRoom_Show()

function CJ_RestRoom_Hide()
    this:Hide()
end -- end func CJ_RestRoom_Hide()

-- 最小化 打开Mini UI按钮点击事件
function CJ_RestRoom_OpenMini()
    CJ_RestRoom_OpenMiniUIState = 1
    PushEvent("TLCJ_REST_RESTINFOMINIOPEN")

    CJ_RestRoom_Hide()
end -- end func CJ_RestRoom_OpenMini()

-- 活动结束倒计时结束事件
function CJ_RestRoom_TimeOut()
end -- end func CJ_RestRoom_TimeOut()

-- 刷新休息室信息
function CJ_RestRoom_UpdateRestInfo(matchType, stateFlag, playerNum, forceMatchCountdown, actEndCountdown)
    if (matchType == CJ_RestRoom_MatchType.team) then
        CJ_RestRoom_Text:SetText("#{TLCJ_20240709_380}")
        CJ_RestRoom_TimeTitle3:SetText("#{TLCJ_20240709_381}")
    else
        CJ_RestRoom_Text:SetText("#{TLCJ_20240709_49}")
        CJ_RestRoom_TimeTitle3:SetText("#{TLCJ_20240709_52}")
    end

    if (stateFlag == CJ_RestRoom_LogicState.in_act) then
        -- 活动匹配阶段
        -- 人数
        local strPlayerNum = ""
        if (matchType == CJ_RestRoom_MatchType.team) then
            strPlayerNum = ScriptGlobal_Format("#{TLCJ_20240709_408}", playerNum)
        else
            strPlayerNum = ScriptGlobal_Format("#{TLCJ_20240709_53}", playerNum)
        end
        CJ_RestRoom_Time3Text:SetText(strPlayerNum)
        -- 匹配倒计时
        CJ_RestRoom_Time:SetProperty("Timer", tostring(forceMatchCountdown))
        CJ_RestRoom_Time:Show()
        -- 活动结束倒计时
        CJ_RestRoom_Time2:SetProperty("Timer", tostring(actEndCountdown))
        CJ_RestRoom_Time2:Show()
        CJ_RestRoom_Time2Text:Hide()
    elseif (stateFlag == CJ_RestRoom_LogicState.after_act) then
        -- 活动结束
        -- 人数
        local strPlayerNum = ""
        if (matchType == CJ_RestRoom_MatchType.team) then
            strPlayerNum = ScriptGlobal_Format("#{TLCJ_20240709_408}", 0)
        else
            strPlayerNum = ScriptGlobal_Format("#{TLCJ_20240709_53}", 0)
        end
        CJ_RestRoom_Time3Text:SetText(strPlayerNum)
        -- 匹配倒计时
        CJ_RestRoom_Time:SetProperty("Timer", tostring(0))
        CJ_RestRoom_Time:Show()
        -- 活动结束倒计时
        CJ_RestRoom_Time2:Hide()
        CJ_RestRoom_Time2Text:Show()
        CJ_RestRoom_Time2Text:SetText("#{TLCJ_20240709_55}")
    end
end -- end func CJ_RestRoom_UpdateRestInfo()