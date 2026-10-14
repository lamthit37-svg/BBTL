local g_DaHua_PKWarning_UnifiedPosition_1

function DaHua_PKWarning_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end


function DaHua_PKWarning_OnLoad()

	g_DaHua_PKWarning_UnifiedPosition_1 = DaHua_PKWarning_Frame:GetProperty("UnifiedPosition")
end


function DaHua_PKWarning_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 5122801) then

        local isShow = Get_XParam_INT(0)

        if isShow == 1 then
            DaHua_PKWarning_Fight:SetProperty("Visible", "True")
            this:Show()
        else
            DaHua_PKWarning_Fight:SetProperty("Visible", "False")
            this:Hide()

        end

	elseif event=="HIDE_ON_SCENE_TRANSED"  then
		this:Hide()
    end

	if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
			DaHua_PKWarning_ResetPos()
        end
	end

end

function DaHua_PKWarning_ResetPos()
    --DaHua_PKWarning_Frame:SetProperty("UnifiedPosition", g_DaHua_PKWarning_UnifiedPosition_1)
end
