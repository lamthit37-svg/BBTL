
local g_PetEgg_Frame_UnifiedPosition = ""
local g_PetEgg_nBagIndex = -1    		--背包中的位置 
local g_PetEgg_nItemIndex = -1   		--物品ID 
local g_PetEgg_nCanSelectTotal = 0     	--可选按钮个数 
local g_PetEgg_strPetName = ""

local g_PetEgg_nScriptID = -1

function ValentineRose_PetEgg_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("ON_SCENE_TRANSING");

end

function ValentineRose_PetEgg_OnLoad()

end

function ValentineRose_PetEgg_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 999811001) then

		g_PetEgg_nBagIndex = Get_XParam_INT(0)
		g_PetEgg_nItemIndex = Get_XParam_INT(1)
        g_PetEgg_nCanSelectTotal = Get_XParam_INT(2)
        g_PetEgg_nScriptID = Get_XParam_INT(3)
        g_PetEgg_strPetName = Get_XParam_STR(0)
        
        ValentineRose_PetEgg_UpdateFrame()
        this:Show();
		
    elseif event == "PLAYER_LEAVE_WORLD"  then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "SCENE_TRANSED"  then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "ON_SCENE_TRANSING"  then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
			
end

function ValentineRose_PetEgg_UpdateFrame()
	
	if g_PetEgg_nCanSelectTotal == 6 then

		ValentineRose_PetEgg_OK1:Show()
		ValentineRose_PetEgg_OK2:Show()
		ValentineRose_PetEgg_OK3:Show()
		ValentineRose_PetEgg_OK4:Show()
		ValentineRose_PetEgg_OK5:Show()
		ValentineRose_PetEgg_OK6:Show()
			
		ValentineRose_PetEgg_OK1:SetText("#{ZSLZ_XML_5}")--45
		ValentineRose_PetEgg_OK2:SetText("#{ZSLZ_XML_6}")--55
		ValentineRose_PetEgg_OK3:SetText("#{ZSLZ_XML_7}")--65
		ValentineRose_PetEgg_OK4:SetText("#{ZSLZ_XML_8}")--75
		ValentineRose_PetEgg_OK5:SetText("#{ZSLZ_XML_9}")--85
		ValentineRose_PetEgg_OK6:SetText("#{BSJT_130114_10}")--95
			
		local str = ScriptGlobal_Format("#{MGCQ_250112_05}", g_PetEgg_strPetName)
		ValentineRose_PetEgg_Text:SetText( str )

	else
	
		this:Hide()
		
	end 
end

function ValentineRose_PetEgg_Close()

	this:Hide();
	
end

function ValentineRose_PetEgg_Select(nIndex)
	
	local nRealSelect = nIndex
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("SpecialPetEggChoosePet")
		Set_XSCRIPT_ScriptID(g_PetEgg_nScriptID)
		Set_XSCRIPT_Parameter(0, g_PetEgg_nBagIndex)
		Set_XSCRIPT_Parameter(1, g_PetEgg_nItemIndex)
		Set_XSCRIPT_Parameter(2, nRealSelect)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT();
	
	this:Hide()
end

