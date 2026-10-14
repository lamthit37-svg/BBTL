local g_DecorateWeaponChange_UnifiedPosition = nil

function DecorateWeaponChange_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function DecorateWeaponChange_OnLoad()
	g_DecorateWeaponChange_UnifiedPosition = DecorateWeaponChange_Frame:GetProperty("UnifiedPosition")	
end

function DecorateWeaponChange_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 891831) then
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		DecorateWeaponChange_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		DecorateWeaponChange_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		DecorateWeaponChange_OnHiden()
	end
end

function DecorateWeaponChange_ResetPos()
		DecorateWeaponChange_Frame:SetProperty("UnifiedPosition",g_DecorateWeaponChange_UnifiedPosition)
end

function DecorateWeaponChange_OnHiden()
	this:Hide()
end

function DecorateWeaponChange_OnButton(index)
	if index < 1 or index > 2 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(891831)
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	DecorateWeaponChange_OnHiden()
end

