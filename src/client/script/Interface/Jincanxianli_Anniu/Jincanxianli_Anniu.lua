
function Jincanxianli_Anniu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Jincanxianli_Anniu_OnLoad()

end

function Jincanxianli_Anniu_OnEvent( event )
	if event == "UI_COMMAND" and arg0 == "890983" then
		if( Get_XParam_INT_Count() < 2 ) then
			return
		end
		local nPhase = Get_XParam_INT(0)
		if nPhase == 0 then
			this:Hide()
		else
			this:Show()
		end
		
		local nFlashOrPrize = Get_XParam_INT(1)
		if nPhase == 1 then
			Jincanxianli_Anniu_Icon_Tips:Hide();
			if nFlashOrPrize > 0 then
				Jincanxianli_Anniu_StartFlash()
			end
		else
			if nFlashOrPrize == 1 then
				Jincanxianli_Anniu_Icon_Tips:Show();
				Jincanxianli_Anniu_Icon:SetProperty("WarningAnimation", "Jincanxianli_Shuaguang");
				Jincanxianli_Anniu_Icon:PlayWarning( 1 )
			elseif nFlashOrPrize == 0 then	
				Jincanxianli_Anniu_Icon_Tips:Hide();
				Jincanxianli_Anniu_Icon:PlayWarning( 0 )
			end
		end
		
	end
end

function Jincanxianli_Anniu_OnClick()
	--PushEvent( "OPEN_JINCANSI_BUY" )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnShowUI")
		Set_XSCRIPT_ScriptID(890983)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	Jincanxianli_Anniu_Flashdown()
end

function Jincanxianli_Anniu_StartFlash_Delay()
	KillTimer("Jincanxianli_Anniu_StartFlash_Delay()")
	KillTimer("Jincanxianli_Anniu_Flashdown()")
	--开启tips
	OpenFreshManGuide(1, 57, 10, 68, "Jincanxianli_Anniu", "southwest")
	this:Show()
	SetTimer("Jincanxianli_Anniu", "Jincanxianli_Anniu_Flashdown()",10*1000)
	Jincanxianli_Anniu_Icon:SetProperty("WarningAnimation", "Jincanxianli_Flash");
	Jincanxianli_Anniu_Icon:PlayWarning( 1 )
end

function Jincanxianli_Anniu_StartFlash()
	SetTimer("Jincanxianli_Anniu", "Jincanxianli_Anniu_StartFlash_Delay()",500)
end

function Jincanxianli_Anniu_Flashdown()
	Jincanxianli_Anniu_Icon:PlayWarning(0)
	CloseFreshManGuide()
	KillTimer("Jincanxianli_Anniu_Flashdown()")
end
