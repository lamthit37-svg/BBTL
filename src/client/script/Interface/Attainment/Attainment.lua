--Attainment.lua
local g_bagIndex = -1;
function Attainment_PreLoad()
	this:RegisterEvent("UI_COMMAND");
end

function Attainment_OnLoad()

end

function Attainment_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 890545) then
		g_bagIndex = Get_XParam_INT(0)
		local nValue = Get_XParam_INT(1)
		local szText = ScriptGlobal_Format("#{KSTS_131212_11}",tostring(nValue))
		Attainment_Text1:SetText(szText)
		this:Show()
	end
end

function Attainment_ChooseAttr(type)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("UseSiShuWuJing");
		Set_XSCRIPT_ScriptID(890545);
		Set_XSCRIPT_Parameter(0,g_bagIndex);
		Set_XSCRIPT_Parameter(1,type);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
	Attainment_Close()
end

function Attainment_Close()
	this:Hide()
end
