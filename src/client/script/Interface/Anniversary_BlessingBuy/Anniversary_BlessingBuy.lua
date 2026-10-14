----------------------
-- Anniversary_BlessingBuy ---
----------------------
local g_Anniversary_BlessingBuy_UnifiedPosition = nil
local g_Anniversary_BlessingBuy_CurSelect = 0
local g_Anniversary_BlessingBuy_CurIdx = 0

local g_Anniversary_BlessingBuy_List = {}

function Anniversary_BlessingBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Anniversary_BlessingBuy_OnLoad()

	g_Anniversary_BlessingBuy_UnifiedPosition = Anniversary_BlessingBuy_Frame:GetProperty("UnifiedPosition")

end

--===============================================
-- OnEvent()
--===============================================
function Anniversary_BlessingBuy_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89340303) then
	
		local nFlag = Get_XParam_INT(0)		
		if nFlag == 1 then
			local qifubi = Get_XParam_INT(1)	
			local str = ScriptGlobal_Format("#{FBQF_200327_73}", qifubi)
			Anniversary_BlessingBuy_Text:SetText( str )
			this:Show()
		else
			Anniversary_BlessingBuy_OnHiden()
		end
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
	
		Anniversary_BlessingBuy_ResetPos()
		
	elseif(event == "ADJEST_UI_POS") then
	
		Anniversary_BlessingBuy_ResetPos()
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
	
		Anniversary_BlessingBuy_OnHiden()
		
	end
end

function Anniversary_BlessingBuy_ResetPos()

	Anniversary_BlessingBuy_Frame:SetProperty("UnifiedPosition", g_Anniversary_BlessingBuy_UnifiedPosition)
	
end

function Anniversary_BlessingBuy_OnHiden()
	
	this:Hide()
	
end

function Anniversary_BlessingBuy_ClickClose()

	Anniversary_BlessingBuy_OnHiden()
	
end

function Anniversary_BlessingBuy_ClickBuy( btn )

	if btn ~= 1 and btn ~= 10 and btn ~= 100 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoBuyQiFuBi" )
		Set_XSCRIPT_ScriptID( 893403 )
		Set_XSCRIPT_Parameter(0, btn)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()		
	
end
