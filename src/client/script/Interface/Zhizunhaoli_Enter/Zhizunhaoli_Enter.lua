--Zhizunhaoli_Enter
function Zhizunhaoli_Enter_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
end

function Zhizunhaoli_Enter_OnLoad()
end

function Zhizunhaoli_Enter_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	if (event == "UI_COMMAND") and (arg0 == "20140608") then
		if Get_XParam_INT(0) == 1 then
			this:Show()
		else
			this:Hide()
		end
	end
	if (event == "UI_COMMAND") and (arg0 == "20140609") then
	
		    --开启tips
		local fX = 0
		local fY = 0

		fX, fY = this:GetChildOffset("Zhizunhaoli_Enter_Icon")

		fX = fX + 40
		fY = fY + 10
		OpenFreshManGuide(1, 53, fX, fY, "Zhizunhaoli_Enter", "northwest")
	end	
end

function Zhizunhaoli_Enter_OnClick()
	CloseFreshManGuide()
	local nNumber = Player:GetData( "LEVEL" );
	if( nNumber < 15 ) then
		PushDebugMessage("#{ZZQH_140606_04}")
		return
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClientAskOpenFrame");
		Set_XSCRIPT_ScriptID(890890);
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT();		
end
