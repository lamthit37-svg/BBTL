----------------------
-- Qingmeizhujiu_Preview ---
----------------------
local g_Qingmeizhujiu_Preview_UnifiedPosition = nil


function Qingmeizhujiu_Preview_PreLoad()
	this:RegisterEvent("SHOW_QINGMEIZHUJIU_PREVIEW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Qingmeizhujiu_Preview_OnLoad()
	g_Qingmeizhujiu_Preview_UnifiedPosition = Qingmeizhujiu_Preview:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function Qingmeizhujiu_Preview_OnEvent(event)
	if ( event == "SHOW_QINGMEIZHUJIU_PREVIEW" ) then
		
		if this:IsVisible() then
			Qingmeizhujiu_Preview_Close()
			return
		end
		
		this:Show()
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
	
		Qingmeizhujiu_Preview_ResetPos()
		
	elseif(event == "ADJEST_UI_POS") then
	
		Qingmeizhujiu_Preview_ResetPos()
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
	
		Qingmeizhujiu_Preview_Close()
		
	end
end

function Qingmeizhujiu_Preview_ResetPos()

	Qingmeizhujiu_Preview:SetProperty("UnifiedPosition", g_Qingmeizhujiu_Preview_UnifiedPosition)
	
end


function Qingmeizhujiu_Preview_Close()

	this:Hide()
	
end
