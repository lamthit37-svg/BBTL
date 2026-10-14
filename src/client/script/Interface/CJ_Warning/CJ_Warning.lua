
local g_LoopTime = 0.2
local g_count = 5
local g_countmax = 5
local g_uicommand = 99932108
--===============================================
-- OnLoad()
--===============================================
function CJ_Warning_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

--===============================================
-- OnLoad()
--===============================================
function CJ_Warning_OnLoad()    
end

--===============================================
-- OnEvent()
--===============================================
function CJ_Warning_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_uicommand then
        CJ_Warning_OnShow()
        this:Show()
    end
    
    if ( event == "HIDE_ON_SCENE_TRANSED" ) then
        KillTimer("CJ_Warning_OnTimer()")
        this:Hide()
    end

end

function CJ_Warning_OnShow()
    g_count = g_countmax
    KillTimer("CJ_Warning_OnTimer()")
	SetTimer("CJ_Warning","CJ_Warning_OnTimer()", g_LoopTime*1000)
end

function CJ_Warning_OnTimer()
    g_count = g_count - 1
    if g_count < 0 then
        KillTimer("CJ_Warning_OnTimer()")
        this:Hide()
    end
end
