-- 雪人战PVP 休息室信息展示UI最小化
-- 默认位置
local Frozen_PVPRestMini_UnifiedPosition = nil



function Frozen_PVPRestMini_PreLoad()
    this:RegisterEvent("XRZPVP_UI_OPENRESTINFOMINI", true)
    this:RegisterEvent("XRZPVP_UI_CLOSERESTINFOMINI", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func Frozen_PVPRestMini_PreLoad()

function Frozen_PVPRestMini_OnEvent(event)
    if (event == "XRZPVP_UI_OPENRESTINFOMINI") then
        Frozen_PVPRestMini_Show()
    elseif (event == "XRZPVP_UI_CLOSERESTINFOMINI") then
        Frozen_PVPRestMini_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_PVPRestMini_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_PVPRestMini_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		Frozen_PVPRestMini_UnifiedPos()
	end
end -- end func Frozen_PVPRestMini_OnEvent()

function Frozen_PVPRestMini_OnLoad()
	Frozen_PVPRestMini_UnifiedPosition = Frozen_RestMini_Frame:GetProperty("UnifiedPosition")
end -- end func Frozen_PVPRestMini_OnLoad()

-- 界面默认位置
function Frozen_PVPRestMini_UnifiedPos()
	if (Frozen_PVPRestMini_UnifiedPosition ~= nil) then
		Frozen_RestMini_Frame:SetProperty("UnifiedPosition", Frozen_PVPRestMini_UnifiedPosition)
	end
end -- end func Frozen_PVPRestMini_UnifiedPos()

function Frozen_PVPRestMini_Show()
    this:Show()
end -- end func Frozen_PVPRestMini_Show()

function Frozen_PVPRestMini_Hide()
    this:Hide()
end -- end func Frozen_PVPRestMini_Hide()

-- 打开休息室UI按钮点击事件
function Frozen_RestMini_OnClose()
    PushEvent("XRZPVP_UI_RESTORERESTINFO")
    
    Frozen_PVPRestMini_Hide()
end -- end func Frozen_RestMini_OnClose()