-- 露荷撷香活动 活动开始倒计时界面

-- 保存UI默认位置
local ErtongjieHoudong_Timing_UnifiedPosition = nil

-- UI关闭定时器时间
local ErtongjieHoudong_Timing_CloseTimerTime = 5
-- UI关闭定时器ID
local ErtongjieHoudong_Timing_CloseTimerID = -1
-- UI关闭标记
local ErtongjieHoudong_Timing_HideFlag = 0

function ErtongjieHoudong_Timing_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func ErtongjieHoudong_Timing_PreLoad()

function ErtongjieHoudong_Timing_OnLoad()
	ErtongjieHoudong_Timing_UnifiedPosition = ErtongjieHoudong_Timing_Frame:GetProperty("UnifiedPosition")
end -- end func ErtongjieHoudong_Timing_OnLoad()

function ErtongjieHoudong_Timing_OnEvent(event)
    if (event == "UI_COMMAND") then
        local arg = tonumber(arg0)
        if (arg == 2022062001) then
            ErtongjieHoudong_Timing_Show()
        end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ErtongjieHoudong_Timing_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ErtongjieHoudong_Timing_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ErtongjieHoudong_Timing_Hide()
	end
end -- end func ErtongjieHoudong_Timing_OnEvent()

function ErtongjieHoudong_Timing_On_ResetPos()
	ErtongjieHoudong_Timing_Frame:SetProperty("UnifiedPosition", ErtongjieHoudong_Timing_UnifiedPosition)
end -- end func ErtongjieHoudong_Timing_On_ResetPos()

--*****************************************************************************
-- UI关闭事件
--*****************************************************************************
function ErtongjieHoudong_Timing_OnHiden()
    if (ErtongjieHoudong_Timing_HideFlag <= 0) then
        ErtongjieHoudong_Timing_Hide()
    end
end -- end func ErtongjieHoudong_Timing_OnHiden()

function ErtongjieHoudong_Timing_Show()
    if (not this:IsVisible()) then
        this:Show()
        ErtongjieHoudong_Timing_HideFlag = 0

        ErtongjieHoudong_Timing_Animate:Play(true)

        if (ErtongjieHoudong_Timing_CloseTimerID >= 0) then
            KillTimer(ErtongjieHoudong_Timing_CloseTimerID)
        end
        local timerTime = ErtongjieHoudong_Timing_CloseTimerTime * 1000
        ErtongjieHoudong_Timing_CloseTimerID = SetTimer("ErtongjieHoudong_Timing", "ErtongjieHoudong_Timing_Hide()", timerTime)
    end
end -- end func ErtongjieHoudong_Timing_Show()

function ErtongjieHoudong_Timing_Hide()
    this:Hide()
    ErtongjieHoudong_Timing_HideFlag = 1

    ErtongjieHoudong_Timing_Animate:Play(false)

    if (ErtongjieHoudong_Timing_CloseTimerID >= 0) then
        KillTimer(ErtongjieHoudong_Timing_CloseTimerID)
        ErtongjieHoudong_Timing_CloseTimerID = -1
    end
end -- end func ErtongjieHoudong_Timing_Hide()