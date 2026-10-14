
local g_LoopTime = 1.0
local g_count = 5
local g_uicommand = 80030602
local g_unifiedposistion = nil
--===============================================
-- OnLoad()
--===============================================
function Frozen_PVPMessage_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad()
--===============================================
function Frozen_PVPMessage_OnLoad()
    g_unifiedposistion = Frozen_PVPMessage:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_PVPMessage_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_uicommand then
        Frozen_PVPMessage_OnShow()
    elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
        KillTimer("Frozen_PVPMessage_OnTimer()")
        this:Hide()
    elseif ( event == "ADJEST_UI_POS" ) then
		Frozen_PVPMessage_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPMessage_ResetPos()
    end
end

function Frozen_PVPMessage_OnShow()
    g_count = Get_XParam_INT(0)
    local showStr = Get_XParam_STR(0)

    Frozen_PVPMessage_Text:SetText(showStr)
    KillTimer("Frozen_PVPMessage_OnTimer()")
    SetTimer("Frozen_PVPMessage", "Frozen_PVPMessage_OnTimer()", g_LoopTime*1000)
    
    this:Show() 
end

function Frozen_PVPMessage_OnTimer()
    g_count = g_count - 1
    if g_count < 0 then
        KillTimer("Frozen_PVPMessage_OnTimer()")
        this:Hide()
    end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPMessage_ResetPos()
	Frozen_PVPMessage:SetProperty("UnifiedPosition", g_unifiedposistion)
end