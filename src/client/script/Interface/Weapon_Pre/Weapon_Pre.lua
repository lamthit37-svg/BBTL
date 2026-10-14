----------------------
-- Weapon_Pre ---
----------------------
local g_Weapon_Pre_UnifiedPosition = nil

local g_Weapon_Pre_ShopId = 0

function Weapon_Pre_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Weapon_Pre_OnLoad()
	g_Weapon_Pre_UnifiedPosition = Weapon_Pre:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function Weapon_Pre_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89292108 ) then
		if IsWindowShow("Weapon_Pre") then
			CloseWindow("Weapon_Pre", true)
			return
		end
		g_Weapon_Pre_ShopId = tonumber(arg1)
		if g_Weapon_Pre_ShopId == 3 then
			Weapon_Pre_DragTitle:SetText("#{SJSD_180817_63}")
			Weapon_Pre_Image:SetProperty("Image", "set:Token_Weapon image:Token_Weapon_01")
		end
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Weapon_Pre_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		Weapon_Pre_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Weapon_Pre_Close()
	end
end

function Weapon_Pre_ResetPos()
	Weapon_Pre:SetProperty("UnifiedPosition",g_Weapon_Pre_UnifiedPosition)
end

function Weapon_Pre_Close()
	this:Hide()
end