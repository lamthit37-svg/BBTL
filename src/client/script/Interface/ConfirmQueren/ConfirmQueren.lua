
function ConfirmQueren_PreLoad()
	this:RegisterEvent("UI_COMMAND");
end

function ConfirmQueren_OnLoad()

end

function ConfirmQueren_OnEvent( event )
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20150415) then
		local MyName = Player:GetName()
		local str = ScriptGlobal_Format("#{BBHL_150228_117}", MyName)
		ConfirmQueren_Text:SetText(str)
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20150416) then
		this:Hide()
	end
end

function ConfirmQueren_Buttons_Clicked(index)
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OKClick");
			Set_XSCRIPT_ScriptID(340033);
			Set_XSCRIPT_Parameter(0,index);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
end

function ConfirmQueren_OnHiden()
	this:Hide()
end
