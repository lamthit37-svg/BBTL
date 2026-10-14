local adjest_pos

function NianHuoH5_OnEvent(event)
	if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 89333503 then
            NianHuoH5_Show()
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
           event == "VIEW_RESOLUTION_CHANGED" then
            NianHuoH5_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

function NianHuoH5_Show()
    this:Show()
end

function NianHuoH5_Close()
    this:Hide()
end

function NianHuoH5_ResetPos()
    NianHuoH5:SetProperty("UnifiedPosition", adjest_pos)
end

function NianHuoH5_OnHiden()
    this:Hide()
end

function NianHuoH5_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function NianHuoH5_OnLoad()
    adjest_pos = NianHuoH5:GetProperty("UnifiedPosition")
end

function NianHuoH5_Help_Clicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("help")
    Set_XSCRIPT_ScriptID(893335)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end
