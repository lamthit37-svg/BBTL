
--!!!reloadscript =DuanWu_JingPaiShow

local g_DuanWu_JingPaiShow_Frame_BK_UnifiedPosition = ""

function DuanWu_JingPaiShow_PreLoad()
	this:RegisterEvent("DUANWU_BIDDING_BONUS_PREVIEW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function DuanWu_JingPaiShow_OnLoad()
	
	g_DuanWu_JingPaiShow_Frame_BK_UnifiedPosition = DuanWu_JingPaiShow_Frame_BK:GetProperty("UnifiedPosition")
end

function DuanWu_JingPaiShow_OnEvent(event)
    
	if event == "DUANWU_BIDDING_BONUS_PREVIEW" then
		this:Show()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu_JingPaiShow_AdjustPosition()
		return
	end

end

function DuanWu_JingPaiShow_AdjustPosition()
	if g_DuanWu_JingPaiShow_Frame_BK_UnifiedPosition ~= nil then
		DuanWu_JingPaiShow_Frame_BK:SetProperty("UnifiedPosition",g_DuanWu_JingPaiShow_Frame_BK_UnifiedPosition)
	end
end

function DuanWu_JingPaiShow_ClickClose()
	this:Hide()
end


