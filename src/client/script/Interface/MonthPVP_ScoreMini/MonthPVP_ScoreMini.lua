local g_MonthPVP_ScoreMini_Frame_UnifiedPosition

function MonthPVP_ScoreMini_PreLoad()
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

function MonthPVP_ScoreMini_OnLoad()
	g_MonthPVP_ScoreMini_Frame_UnifiedPosition = MonthPVP_ScoreMini_Frame:GetProperty("UnifiedPosition")
end

function MonthPVP_ScoreMini_OnEvent(event)

	if(event == "OPEN_WINDOW") then
		if( arg0 == "MonthPVP_ScoreMini") then
			this:Show()
		end
	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "MonthPVP_ScoreMini") then
			this:Hide()
		end	
	elseif event=="HIDE_ON_SCENE_TRANSED" or event=="SCENE_TRANSED" or event=="PLAYER_LEAVE_WORLD"  then
		MonthPVP_ScoreMini_OnHidden()
    end
	
	if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
			MonthPVP_ScoreMini_ResetPos()
        end
	end

end

function MonthPVP_ScoreMini_ResetPos()
    MonthPVP_ScoreMini_Frame:SetProperty("UnifiedPosition", g_MonthPVP_ScoreMini_Frame_UnifiedPosition)
end

function MonthPVP_ScoreMini_OnHidden()
	this:Hide()
end

function MonthPVP_ScoreMini_OnClose()
	OpenWindow("MonthPVP_Score")
	this:Hide()
end