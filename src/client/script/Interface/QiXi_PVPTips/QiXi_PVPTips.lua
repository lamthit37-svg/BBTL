
local g_LoopTime = 1.0
local g_count = 5
local g_uicommand = 56004102
local g_unifiedposistion = nil
--===============================================
-- OnLoad()
--===============================================
function QiXi_PVPTips_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad()
--===============================================
function QiXi_PVPTips_OnLoad()
    g_unifiedposistion = QiXi_PVPTips:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function QiXi_PVPTips_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_uicommand then
        QiXi_PVPTips_OnShow()
    elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
        KillTimer("QiXi_PVPTips_OnTimer()")
        this:Hide()
    elseif ( event == "ADJEST_UI_POS" ) then
		QiXi_PVPTips_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		QiXi_PVPTips_ResetPos()
    end
end

function QiXi_PVPTips_OnShow()
    g_count = Get_XParam_INT(0)
    local showStr = Get_XParam_STR(0)

    QiXi_PVPTips_Text:SetText(showStr)
    KillTimer("QiXi_PVPTips_OnTimer()")
    SetTimer("QiXi_PVPTips", "QiXi_PVPTips_OnTimer()", g_LoopTime*1000)
    
    this:Show() 
end

function QiXi_PVPTips_OnTimer()
    g_count = g_count - 1
    if g_count < 0 then
        KillTimer("QiXi_PVPTips_OnTimer()")
        this:Hide()
    end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function QiXi_PVPTips_ResetPos()
	QiXi_PVPTips:SetProperty("UnifiedPosition", g_unifiedposistion)
end