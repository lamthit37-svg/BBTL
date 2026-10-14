-- 雪人战PVP 活动入口界面
-- 当前是否活动时间
local Frozen_PVPGoto_IsInActTime = 0
-- 参加活动最低等级
local Frozen_PVPGoto_MinLevel = 60
-- 保存UI默认位置
local Frozen_PVPGoto_UnifiedPosition = nil
-- 入口NPC
local Frozen_PVPGoto_EnterNPCInfo =
{
    scn = 1007,
    pos = {146, 189},
    name = "侯赛磊",
} -- end Frozen_PVPGoto_EnterNPCInfo



function Frozen_PVPGoto_PreLoad()
	this:RegisterEvent("XRZPVP_UI_OPENGOTO")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func Frozen_PVPGoto_PreLoad()

function Frozen_PVPGoto_OnLoad()
	Frozen_PVPGoto_UnifiedPosition = Frozen_PVPGoto_Frame_BK:GetProperty("UnifiedPosition")
end -- end func Frozen_PVPGoto_OnLoad()

function Frozen_PVPGoto_OnEvent(event)
    if event == "XRZPVP_UI_OPENGOTO" then
        Frozen_PVPGoto_IsInActTime = tonumber(arg0)
		Frozen_PVPGoto_Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_PVPGoto_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_PVPGoto_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_PVPGoto_Hide()
	end
end -- end func Frozen_PVPGoto_OnEvent()

function Frozen_PVPGoto_On_ResetPos()
	Frozen_PVPGoto_Frame_BK:SetProperty("UnifiedPosition", Frozen_PVPGoto_UnifiedPosition)
end -- end func Frozen_PVPGoto_On_ResetPos()

function Frozen_PVPGoto_Show()
    this:Show()
end -- end func Frozen_PVPGoto_Show()

function Frozen_PVPGoto_Hide()
    this:Hide()
end -- end func Frozen_PVPGoto_Hide()

-- 关闭按钮
function Frozen_PVPGoto_Close()
    Frozen_PVPGoto_Hide()
end -- end func Frozen_PVPGoto_Close()

-- 关于按钮
function Frozen_PVPGoto_OnClickedHelp()
    PushEvent("XRZPVP_UI_OPENGOTOHELP")
end -- end func Frozen_PVPGoto_OnClickedHelp()

-- 前往按钮
function Frozen_PVPGoto_OnClickedBtn()
    -- 是否活动时间
    if (Frozen_PVPGoto_IsInActTime <= 0) then
        PushDebugMessage("#{BXDZ_240918_05}")
        return
    end

    -- 等级
    local myLevel = Player:GetLevel()
    if (myLevel < Frozen_PVPGoto_MinLevel) then
        PushDebugMessage("#{BXDZ_240918_06}")
        return
    end

    -- 寻路前往入口NPC
    local targetInfo = Frozen_PVPGoto_EnterNPCInfo
    if (targetInfo ~= nil) then
        AutoRuntoTargetExWithName(targetInfo.pos[1], targetInfo.pos[2], targetInfo.scn, targetInfo.name)
    end

    -- 关闭UI
    Frozen_PVPGoto_Hide()
end -- end func Frozen_PVPGoto_OnClickedBtn()