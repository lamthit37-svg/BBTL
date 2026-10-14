
--!!!reloadscript =LuckyBag_Sure


function LuckyBag_Sure_PreLoad()
	this:RegisterEvent("TOGGLE_ZNQ_BUY_TOKENS", true)
	this:RegisterEvent("UI_COMMAND", true)
end

function LuckyBag_Sure_OnLoad()	

end

function LuckyBag_Sure_OnEvent(event)

	if event == "TOGGLE_ZNQ_BUY_TOKENS" then
		
		if tonumber(arg0) == 1 then
			LuckyBag_Sure_UpdateButtonText()
			this:Show()
		else
			this:Hide()		
		end
		
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 44000003 then
		this:Hide()
	end

end

function LuckyBag_Sure_UpdateButtonText()
	
	local strTemp = ScriptGlobal_Format( "#{HDSW_190322_7}", "10" )
	LuckyBag_Sure_Button:SetText(strTemp)
	
	local strTemp_1 = ScriptGlobal_Format( "#{HDSW_190322_8}", "95" )
	LuckyBag_Sure_Button1:SetText(strTemp_1)
end


function LuckyBag_Sure_ClickClose()
	this:Hide()
end

function LuckyBag_Sure_ClickBuy10()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyTokens" )
		Set_XSCRIPT_ScriptID( 440000 )
		Set_XSCRIPT_Parameter(0,10)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

function LuckyBag_Sure_ClickBuy100()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyTokens" )
		Set_XSCRIPT_ScriptID( 440000 )
		Set_XSCRIPT_Parameter(0,100)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end