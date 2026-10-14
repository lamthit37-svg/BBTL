-- 露荷撷香活动 引导界面

local ErtongjieHoudongEnter_BeginDate = 0
local ErtongjieHoudongEnter_EndDate = 0

-- 保存UI默认位置
local ErtongjieHoudongEnter_UnifiedPosition = nil

local ErtongjieHoudongEnter_ActInfo =
{
    -- 最小参与等级
    minlevel = 30,
    -- 入口npc位置
    targetpos = {scn = 0, x = 268, z = 347, name = "莲薇"}
} -- end ErtongjieHoudongEnter_ActInfo

function ErtongjieHoudongEnter_PreLoad()
	this:RegisterEvent("ETJFUBEN_2022_ENTEROPEN", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func ErtongjieHoudongEnter_PreLoad()

function ErtongjieHoudongEnter_OnLoad()
	ErtongjieHoudongEnter_UnifiedPosition = ErtongjieHoudongEnter_Frame_BK:GetProperty("UnifiedPosition")
end -- end func ErtongjieHoudongEnter_OnLoad()

function ErtongjieHoudongEnter_OnEvent(event)
	if (event == "ETJFUBEN_2022_ENTEROPEN") then
		ErtongjieHoudongEnter_BeginDate = tonumber(arg0)
		ErtongjieHoudongEnter_EndDate = tonumber(arg1)

		ErtongjieHoudongEnter_Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ErtongjieHoudongEnter_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ErtongjieHoudongEnter_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ErtongjieHoudongEnter_Hide()
	end
end -- end func ErtongjieHoudongEnter_OnEvent()

function ErtongjieHoudongEnter_On_ResetPos()
	ErtongjieHoudongEnter_Frame_BK:SetProperty("UnifiedPosition", ErtongjieHoudongEnter_UnifiedPosition)
end -- end func ErtongjieHoudongEnter_On_ResetPos()

--*****************************************************************************
-- UI关闭事件
--*****************************************************************************
function ErtongjieHoudongEnter_OnHide()
end -- end func ErtongjieHoudongEnter_OnHide()

--*****************************************************************************
-- 前往按钮事件
--*****************************************************************************
function ErtongjieHoudongEnter_Goto()
    local curDay = tonumber(DataPool:GetServerDayTime())
	if (curDay < ErtongjieHoudongEnter_BeginDate or curDay > ErtongjieHoudongEnter_EndDate) then
		PushDebugMessage("#{ETDDS_220406_01}")
		return
	end
	local level = Player:GetLevel()
	if (level < ErtongjieHoudongEnter_ActInfo.minlevel) then
		PushDebugMessage("#{ETDDS_220406_02}")
		return
    end
    
    --寻路
    local posInfo = ErtongjieHoudongEnter_ActInfo.targetpos
	--AutoRunToTargetEx(posInfo.x, posInfo.z, posInfo.scn)
	AutoRuntoTargetExWithName(posInfo.x, posInfo.z, posInfo.scn, posInfo.name)
    
    -- 关闭UI
    ErtongjieHoudongEnter_Hide()
end -- end func ErtongjieHoudongEnter_Goto()

--*****************************************************************************
-- 说明按钮
--*****************************************************************************
function ErtongjieHoudongEnter_ShowHelp()
    PushEvent("ETJFUBEN_2022_HELP")
end -- end func ErtongjieHoudongEnter_ShowHelp()

function ErtongjieHoudongEnter_Show()
    if (not this:IsVisible()) then
        this:Show()
	end
end -- end func ErtongjieHoudongEnter_Show()

function ErtongjieHoudongEnter_Hide()
    this:Hide()
end -- end func ErtongjieHoudongEnter_Hide()