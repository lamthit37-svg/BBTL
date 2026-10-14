----------------------
-- ZhenYuanGilt_ZiJin ---
----------------------
local g_ZhenYuanGilt_ZiJin_UnifiedPosition = nil
local g_ZhenYuanGilt_ZiJin_CurIndex = 0

function ZhenYuanGilt_ZiJin_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function ZhenYuanGilt_ZiJin_OnLoad()
	g_ZhenYuanGilt_ZiJin_UnifiedPosition = ZhenYuanGilt_ZiJin_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function ZhenYuanGilt_ZiJin_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 88995804) then
		if this:IsVisible() then
				ZhenYuanGilt_ZiJin_OnHiden();
		else
				ZhenYuanGilt_ZiJin_Show();
		end
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		ZhenYuanGilt_ZiJin_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		ZhenYuanGilt_ZiJin_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		ZhenYuanGilt_ZiJin_OnHiden()
	end
end

function ZhenYuanGilt_ZiJin_ResetPos()
		ZhenYuanGilt_ZiJin_Frame:SetProperty("UnifiedPosition",g_ZhenYuanGilt_ZiJin_UnifiedPosition)
end

function ZhenYuanGilt_ZiJin_OnHiden()
	this:Hide()
end

function ZhenYuanGilt_ZiJin_Show()
	this:Show();
end

function ZhenYuanGilt_ZiJin_Select(index)
	if index <= 0 or index > 3 then
		return
	end
	
	--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID( 891810 )
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	ZhenYuanGilt_ZiJin_OnHiden()
end