local g_NewBangHui_Fuben_Frame_UnifiedPosition = nil
local g_NewBangHui_Fuben_FuliType = 3

function NewBangHui_Fuben_PreLoad()

	this:RegisterEvent("GUILD_FUBENSEL_OPENUI",true)
	this:RegisterEvent("GUILD_UPDATE_FULIPOINT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function NewBangHui_Fuben_OnLoad()
	
	g_NewBangHui_Fuben_Frame_UnifiedPosition = NewBangHui_Fuben_Frame:GetProperty("UnifiedPosition")
	
	NewBangHui_Fuben_Item1_Image:SetToolTip( "#{BHFLGTMB_210714_122}" );
	NewBangHui_Fuben_Item2_Image:SetToolTip( "#{BHFLGTMB_210714_123}" );
	NewBangHui_Fuben_Item3_Image:SetToolTip( "#{BHFLGTMB_210714_124}" );
	
end

function NewBangHui_Fuben_OnEvent(event)
	if(event == "GUILD_FUBENSEL_OPENUI" ) then
		g_NewBangHui_Fuben_FuliType = tonumber(arg0)
		this:Show();
		if Player:GetData("Is2606S") == 1 then
			NewBangHui_Fuben_Item2:Hide()
			NewBangHui_Fuben_Item3:Hide()
		else
			NewBangHui_Fuben_Item2:Show()
			NewBangHui_Fuben_Item3:Show()
		end
	elseif(event == "GUILD_UPDATE_FULIPOINT" ) then
		NewBangHui_Fuben_OnHiden()
								
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_Fuben_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_Fuben_ResetPos()
	end
end

function NewBangHui_Fuben_ItemClicked( nFuben )

	if nFuben < 1 or nFuben > 3 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenFuli" )
		Set_XSCRIPT_ScriptID( 610020 )
		Set_XSCRIPT_Parameter(0, g_NewBangHui_Fuben_FuliType)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_Parameter(2, nFuben)  --Param
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function NewBangHui_Fuben_OnHiden()
	this:Hide();
end

function NewBangHui_Fuben_ResetPos()
	NewBangHui_Fuben_Frame:SetProperty("UnifiedPosition",g_NewBangHui_Fuben_Frame_UnifiedPosition)
end
