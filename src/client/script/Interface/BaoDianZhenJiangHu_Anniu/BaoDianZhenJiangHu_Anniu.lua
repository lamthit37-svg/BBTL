

function BaoDianZhenJiangHu_Anniu_PreLoad()

	this:RegisterEvent("UI_COMMAND")

end

function BaoDianZhenJiangHu_Anniu_OnLoad()
	
end


function BaoDianZhenJiangHu_Anniu_OnEvent(event)
	if(event == "UI_COMMAND" ) and (tonumber(arg0) == 2015053001) then
		local nParam = Get_XParam_INT(0);
		if nParam == 1 then

			if nParam == 1 then
				OpenFreshManGuide(1, 71, 10, 10, "BaoDianZhenJiangHu_Anniu", "northwest")
			--elseif nParam == 2 then
			--	OpenFreshManGuide(1, 70, 10, 10, "BaoDianZhenJiangHu_Anniu", "northwest")
			--elseif nParam == 3 then
			--	local nMeiLiValue = Get_XParam_INT(1);
			--	DataPool:Lua_SetMeiLiValue(nMeiLiValue);
			--	OpenFreshManGuide(1, 72, 10, 10, "BaoDianZhenJiangHu_Anniu", "northwest")
			end
			this:Show()
		else
			if this:IsVisible() then
				this:Hide()
			end
		end		
	end
end

function BaoDianZhenJiangHu_Anniu_OnClick()

	local nNumber = Player:GetData( "LEVEL" );
	if( nNumber < 15 ) then	
		PushDebugMessage("#{KPLS_150527_5}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenBaoDianZJHUI" )
		Set_XSCRIPT_ScriptID( 891151 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
	PushEvent("CLOSE_FRESHMAN_GUIDE");
end
