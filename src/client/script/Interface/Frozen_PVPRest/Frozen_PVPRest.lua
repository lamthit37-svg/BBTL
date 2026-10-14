-- 雪人战PVP 休息室信息展示UI
-- mini UI打开状态
local Frozen_PVPRest_OpenMiniUIState = 0
-- 保存UI默认位置
local Frozen_PVPRest_UnifiedPosition = nil

-- 场景逻辑状态
local Frozen_PVPRest_LogicState =
{
    before_act = 2,             -- 逻辑开启 但是活动还未开启
    in_act = 3,                 -- 活动开启
    after_act = 4,              -- 活动结束 但是逻辑还未结束
} -- end Frozen_PVPRest_LogicState



function Frozen_PVPRest_PreLoad()
    this:RegisterEvent("XRZPVP_UI_OPENRESTINFO")
    this:RegisterEvent("XRZPVP_UI_UPDATERESTINFO")
    this:RegisterEvent("XRZPVP_UI_CLOSERESTINFO")
    this:RegisterEvent("XRZPVP_UI_RESTORERESTINFO")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func Frozen_PVPRest_PreLoad()

function Frozen_PVPRest_OnLoad()
	Frozen_PVPRest_UnifiedPosition = Frozen_PVPRest_Frame:GetProperty("UnifiedPosition")
end -- end func Frozen_PVPRest_OnLoad()

function Frozen_PVPRest_OnEvent(event)
    if event == "XRZPVP_UI_OPENRESTINFO" then
        Frozen_PVPRest_OpenMiniUIState = 0
        Frozen_PVPRest_Show()
    elseif event == "XRZPVP_UI_UPDATERESTINFO" then
        if (Frozen_PVPRest_OpenMiniUIState <= 0 and not this:IsVisible()) then
            Frozen_PVPRest_Show()
        end

        Frozen_PVPRest_UpdateRestInfo(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3))
    elseif event == "XRZPVP_UI_CLOSERESTINFO" then
        Frozen_PVPRest_OpenMiniUIState = 1
        Frozen_PVPRest_Hide()
    elseif event == "XRZPVP_UI_RESTORERESTINFO" then
        Frozen_PVPRest_OpenMiniUIState = 0
        Frozen_PVPRest_Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_PVPRest_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_PVPRest_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_PVPRest_Hide()
	end
end -- end func Frozen_PVPRest_OnEvent()

function Frozen_PVPRest_On_ResetPos()
	Frozen_PVPRest_Frame:SetProperty("UnifiedPosition", Frozen_PVPRest_UnifiedPosition)
end -- end func Frozen_PVPRest_On_ResetPos()

function Frozen_PVPRest_Show()
    PushEvent("XRZPVP_UI_CLOSERESTINFOMINI")
    this:Show()
end -- end func Frozen_PVPRest_Show()

function Frozen_PVPRest_Hide()
    this:Hide()
end -- end func Frozen_PVPRest_Hide()

-- 最小化按钮
function Frozen_PVPRest_OnClose()
    Frozen_PVPRest_OpenMiniUIState = 1
    PushEvent("XRZPVP_UI_OPENRESTINFOMINI")
    Frozen_PVPRest_Hide()
end -- end func Frozen_PVPRest_OnClose()

-- 活动结束倒计时开始事件
function Frozen_PVPRest_StartTime()
end -- end func Frozen_PVPRest_StartTime()

-- 活动结束倒计时结束事件
function Frozen_PVPRest_TimeOut()
end -- end func Frozen_PVPRest_TimeOut()

-- 更新数据
function Frozen_PVPRest_UpdateRestInfo(stateFlag, teamNum, forceMatchCountdown, actEndCountdown)
    -- 队伍数
    local strTeamNum = ScriptGlobal_Format("#{BXDZ_240918_49}", teamNum)
    Frozen_PVPRest_PersonNum:SetText(strTeamNum)
    -- 匹配倒计时
    if (forceMatchCountdown <= 0) then
        Frozen_PVPRest_Start:SetProperty("Timer", tostring(0))
    else
        Frozen_PVPRest_Start:SetProperty("Timer", tostring(forceMatchCountdown))
    end
    Frozen_PVPRest_Start:Show()
    -- 活动结束倒计时
    if (actEndCountdown <= 0) then
        Frozen_PVPRest_Time:SetProperty("Timer", tostring(0))
    else
        Frozen_PVPRest_Time:SetProperty("Timer", tostring(actEndCountdown))
    end
    Frozen_PVPRest_Time:Show()
end -- end func Frozen_PVPRest_UpdateRestInfo()