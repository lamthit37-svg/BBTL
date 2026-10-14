-- 2023Q1城战奖励升级活动

-- 保存UI默认位置
local Chengzhan_Jiangli_UnifiedPosition = nil
-- 快捷入口上的按钮索引
local Chengzhan_Jiangli_QuicklyEnterIndex = 49



function Chengzhan_Jiangli_PreLoad()
    this:RegisterEvent("2023Q1_TCW_AWARDENHANCE_OPEN", true)
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func Chengzhan_Jiangli_PreLoad()

function Chengzhan_Jiangli_OnLoad()
    Chengzhan_Jiangli_UnifiedPosition = Chengzhan_Jiangli_Frame_BK:GetProperty("UnifiedPosition")
end -- end func Chengzhan_Jiangli_OnLoad()

function Chengzhan_Jiangli_OnEvent(event)
    if (event == "2023Q1_TCW_AWARDENHANCE_OPEN") then
        Chengzhan_Jiangli_Show()
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 99821301) then
        Chengzhan_Jiangli_Show()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Chengzhan_Jiangli_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Chengzhan_Jiangli_UnifiedPos()
    end
end -- end func Chengzhan_Jiangli_OnEvent()

-- 界面默认位置
function Chengzhan_Jiangli_UnifiedPos()
	if (Chengzhan_Jiangli_UnifiedPosition ~= nil) then
		Chengzhan_Jiangli_Frame_BK:SetProperty("UnifiedPosition", Chengzhan_Jiangli_UnifiedPosition)
	end
end -- end func Chengzhan_Jiangli_UnifiedPos()

function Chengzhan_Jiangli_Show()
    this:Show()

    -- 隐藏快捷入口按钮上的小红点
    Lua_ShowQuickEnterPointTip(Chengzhan_Jiangli_QuicklyEnterIndex, 0)

    Chengzhan_Jiangli_Text:SetText("#{CZSJ_230301_08}")
end -- end func Chengzhan_Jiangli_Show()

function Chengzhan_Jiangli_Hide()
    this:Hide()
end -- end func Chengzhan_Jiangli_Hide()

function Chengzhan_Jiangli_OnHide()
end -- end func Chengzhan_Jiangli_OnHide()

function Chengzhan_Jiangli_ShowHelp()
    PushEvent("CCSHOP_HELP", 186)
end -- end func Chengzhan_Jiangli_ShowHelp()