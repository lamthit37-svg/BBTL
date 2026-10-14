----------------------
-- Token_Giftset ---
----------------------
local g_Token_Giftset_UnifiedPosition = nil

function Token_Giftset_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Token_Giftset_OnLoad()
	g_Token_Giftset_UnifiedPosition = Token_Giftset:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function Token_Giftset_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89292109 ) then
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Token_Giftset_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		Token_Giftset_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Token_Giftset_Close()
	end
end

function Token_Giftset_ResetPos()
		Token_Giftset:SetProperty("UnifiedPosition",g_Token_Giftset_UnifiedPosition)
end

function Token_Giftset_Close()
	this:Hide()
end