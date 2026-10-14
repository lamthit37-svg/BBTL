

function JieBaiZFSJ_PreLoad()
	this:RegisterEvent("UI_COMMAND");
end


function JieBaiZFSJ_OnLoad()

end


function JieBaiZFSJ_OnEvent(event)
	if (event == "UI_COMMAND") then
		if(tonumber(arg0) == 20150526 ) then
			this:Show()
		end
	end
end


function JieBaiZFSJ_acceptMis(nIndex)

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientAcceptMission");
			Set_XSCRIPT_ScriptID(891115);
			Set_XSCRIPT_Parameter(0,tonumber(nIndex));
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
end