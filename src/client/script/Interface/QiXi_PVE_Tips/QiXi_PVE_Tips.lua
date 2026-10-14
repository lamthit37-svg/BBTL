
local g_LoopTime = 1.0
local g_count = 10
local g_uicommand = 05123802
local g_unifiedposistion = nil
--===============================================
-- OnLoad()
--===============================================
function QiXi_PVE_Tips_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad()
--===============================================
function QiXi_PVE_Tips_OnLoad()
    g_unifiedposistion = QiXi_PVE_Tips_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function QiXi_PVE_Tips_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_uicommand then
        QiXi_PVE_Tips_OnShow()
    elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
        KillTimer("QiXi_PVE_Tips_OnTimer()")
        this:Hide()
    elseif ( event == "ADJEST_UI_POS" ) then
		QiXi_PVE_Tips_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		QiXi_PVE_Tips_ResetPos()
    end
end

function QiXi_PVE_Tips_OnShow()
    g_count = Get_XParam_INT(0)
    local showStr = Get_XParam_STR(0)

    QiXi_PVE_Tips_Text:SetText(showStr)
    KillTimer("QiXi_PVE_Tips_OnTimer()")
    SetTimer("QiXi_PVE_Tips", "QiXi_PVE_Tips_OnTimer()", g_LoopTime*1000)
    
    this:Show() 
end

function QiXi_PVE_Tips_OnTimer()
    g_count = g_count - 1
    if g_count < 0 then
        KillTimer("QiXi_PVE_Tips_OnTimer()")
        this:Hide()
    end
end

function QiXi_PVE_Tips_ResetPos()
	QiXi_PVE_Tips_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end