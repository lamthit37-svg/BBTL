function SpringFirst_Dream_PreLoad()

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end

function SpringFirst_Dream_OnLoad()
	g_Frame_UnifiedPosition = SpringFirst_Dream_Frame_BK:GetProperty("UnifiedPosition") 
end

function SpringFirst_Dream_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == 25412221  then
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
	
        SpringFirst_Dream_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		SpringFirst_Dream_On_Close()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFirst_Dream_On_ResetPos()
    end
end

function SpringFirst_Dream_On_ResetPos()
	SpringFirst_Dream_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function SpringFirst_Dream_On_Close()
    this:Hide()
end

function SpringFirst_Dream_OnHide()
    this:Hide()
end

function SpringFirst_Dream_OnHiden()
	this:Hide()
end
