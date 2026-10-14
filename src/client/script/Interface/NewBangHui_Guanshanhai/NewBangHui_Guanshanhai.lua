local g_NewBangHui_Guanshanhai_Frame_UnifiedPosition = nil
local g_NewBangHui_Guanshanhai_FuliType = 2
local g_NewBangHui_Guanshanhai_npcObjId = -1;
local g_NewBangHui_Guanshanhai_objCared = -1;

function NewBangHui_Guanshanhai_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("GUILD_BONUSSEL_OPENUI",true)
	this:RegisterEvent("GUILD_UPDATE_FULIPOINT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function NewBangHui_Guanshanhai_OnLoad()
	
	g_NewBangHui_Guanshanhai_Frame_UnifiedPosition = NewBangHui_Guanshanhai_Frame:GetProperty("UnifiedPosition")
	
	NewBangHui_Guanshanhai_Item1_Image:SetToolTip( "#{BHFLGTMB_210714_137}" );
	NewBangHui_Guanshanhai_Item2_Image:SetToolTip( "#{BHFLGTMB_210714_138}" );
		
end

function NewBangHui_Guanshanhai_OnEvent(event)
	if(event == "GUILD_BONUSSEL_OPENUI" ) then
		g_NewBangHui_Guanshanhai_FuliType = tonumber(arg0)
		this:Show();
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 61002002 ) then
		g_NewBangHui_Guanshanhai_FuliType = Get_XParam_INT(0)
		g_NewBangHui_Guanshanhai_npcObjId = Get_XParam_INT(1)
		this:Show();
		
		
		g_NewBangHui_Guanshanhai_objCared = DataPool : GetNPCIDByServerID(g_NewBangHui_Guanshanhai_npcObjId)
		if g_NewBangHui_Guanshanhai_objCared == -1 then
			NewBangHui_Guanshanhai_OnHiden()
			return
		end
		this : CareObject( g_NewBangHui_Guanshanhai_objCared, 1, "NewBangHui_Fuli" )
		
	elseif(event == "GUILD_UPDATE_FULIPOINT" ) then
		NewBangHui_Guanshanhai_OnHiden()
								
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_Guanshanhai_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_Guanshanhai_ResetPos()
	end
end

function NewBangHui_Guanshanhai_ItemClicked( nBonusIndex )

	if nBonusIndex < 1 or nBonusIndex > 2 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetFuli" )
		Set_XSCRIPT_ScriptID( 610020 )
		Set_XSCRIPT_Parameter(0, g_NewBangHui_Guanshanhai_FuliType)
		Set_XSCRIPT_Parameter(1, nBonusIndex-1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

function NewBangHui_Guanshanhai_OnHiden()
	--取消关心
	this:CareObject(g_NewBangHui_Guanshanhai_objCared, 0, "NewBangHui_Guanshanhai");	
	g_NewBangHui_Guanshanhai_objCared = -1
	
	this:Hide();
end

function NewBangHui_Guanshanhai_ResetPos()
	NewBangHui_Guanshanhai_Frame:SetProperty("UnifiedPosition",g_NewBangHui_Guanshanhai_Frame_UnifiedPosition)
end
