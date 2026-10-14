local g_nBagIndex = -1    		--背包中的位置 
local g_nItemIndex = -1   		--物品ID 
local g_nCanSelectTotal = 0     --可选按钮个数 
local g_strPetName = ""
local g_nServerScriptID = -1    --服务器脚本号
local g_strServerFunName = ""   --服务器函数名

function PetLongzi_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- this:RegisterEvent("ON_SCENE_TRANSING");

end

function PetLongzi_OnLoad()


end

function PetLongzi_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 171718) then
        --PushDebugMessage("Enter UI_COMMAND")
		g_nBagIndex = Get_XParam_INT(0)
		g_nItemIndex = Get_XParam_INT(1)
        g_nCanSelectTotal = Get_XParam_INT(2)
		g_nServerScriptID = Get_XParam_INT(3)
        g_strPetName = Get_XParam_STR(0)
		g_strServerFunName = Get_XParam_STR(1)
        
        PetLongzi_UpdateFrame()
        this:Show();
    elseif event == "HIDE_ON_SCENE_TRANSED"  then
		
			this:Hide()
	
	
	
	
    end
			
end

function PetLongzi_UpdateFrame()
	--目前只有2,4两种情况 
	local nIsBaiShou = Pet:GetIsBaiShou()
	if  g_nCanSelectTotal == 2 then
		
		PetLongzi_OK1:Show()
		PetLongzi_OK2:Show()
		PetLongzi_OK3:Hide()
		PetLongzi_OK4:Hide()
		PetLongzi_OK5:Hide()
		PetLongzi_OK6:Hide()
		PetLongzi_OK7:Hide()
		
		PetLongzi_OK1:SetText("#{ZSLZ_XML_4}")
		PetLongzi_OK2:SetText("#{ZSLZ_XML_5}")
		local str2 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
		if nIsBaiShou == 1 then
			str2 = str2.."\n".."#{BSJT_130114_11}"
		end
		PetLongzi_Text:SetText(str2)

	elseif g_nCanSelectTotal == 3 then
		PetLongzi_OK1:Show()
		PetLongzi_OK2:Show()
		PetLongzi_OK3:Show()
		PetLongzi_OK4:Hide()
		PetLongzi_OK5:Hide()
		PetLongzi_OK6:Hide()
		PetLongzi_OK7:Hide()
		
		PetLongzi_OK1:SetText("#{ZSLZ_XML_5}")
		PetLongzi_OK2:SetText("#{ZSLZ_XML_6}")
		PetLongzi_OK3:SetText("#{ZSLZ_XML_7}")

		local str4 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
		if nIsBaiShou == 1 then
			str4 = str4.."\n".."#{BSJT_130114_11}"
		end
		PetLongzi_Text:SetText(str4)
	
	elseif g_nCanSelectTotal == 4 and g_nServerScriptID == 300300 then
		if g_nItemIndex == 39910142 or g_nItemIndex == 39910146 then
			PetLongzi_OK1:Show()
			PetLongzi_OK2:Show()
			PetLongzi_OK3:Show()
			PetLongzi_OK4:Show()
			PetLongzi_OK5:Hide()
			PetLongzi_OK6:Hide()
			PetLongzi_OK7:Hide()
		
			PetLongzi_OK1:SetText("#{ZSLZ_XML_7}")
			PetLongzi_OK2:SetText("#{ZSLZ_XML_8}")
			PetLongzi_OK3:SetText("#{ZSLZ_XML_9}")
			PetLongzi_OK4:SetText("#{BSJT_130114_10}")
			
			--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
			local str4 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
			if nIsBaiShou == 1 then
				str4 = str4.."\n".."#{BSJT_130114_11}"
			end
			PetLongzi_Text:SetText(str4)
		else
			PetLongzi_OK1:Show()
			PetLongzi_OK2:Show()
			PetLongzi_OK3:Show()
			PetLongzi_OK4:Show()
			PetLongzi_OK5:Hide()
			PetLongzi_OK6:Hide()
			PetLongzi_OK7:Hide()
		
			PetLongzi_OK1:SetText("#{ZSLZ_XML_6}")
			PetLongzi_OK2:SetText("#{ZSLZ_XML_7}")
			PetLongzi_OK3:SetText("#{ZSLZ_XML_8}")
			PetLongzi_OK4:SetText("#{ZSLZ_XML_9}")
			
			--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
			local str4 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
			if nIsBaiShou == 1 then
				str4 = str4.."\n".."#{BSJT_130114_11}"
			end
			PetLongzi_Text:SetText(str4)
		end
		
	elseif g_nCanSelectTotal == 4 and g_nServerScriptID == 300027 then
		if g_nItemIndex == 30504330 then
			PetLongzi_OK1:Show()
			PetLongzi_OK2:Show()
			PetLongzi_OK3:Show()
			PetLongzi_OK4:Show()
			PetLongzi_OK5:Hide()
			PetLongzi_OK6:Hide()
			PetLongzi_OK7:Hide()
			
			PetLongzi_OK1:SetText("#{ZSLZ_XML_6}")
			PetLongzi_OK2:SetText("#{ZSLZ_XML_7}")
			PetLongzi_OK3:SetText("#{ZSLZ_XML_8}")
			PetLongzi_OK4:SetText("#{ZSLZ_XML_9}")
			
			--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
			local str4 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
			if nIsBaiShou == 1 then
				str4 = str4.."\n".."#{BSJT_130114_11}"
			end
			PetLongzi_Text:SetText(str4)
		else
			PetLongzi_OK1:Show()
			PetLongzi_OK2:Show()
			PetLongzi_OK3:Show()
			PetLongzi_OK4:Show()
			PetLongzi_OK5:Hide()
			PetLongzi_OK6:Hide()
			PetLongzi_OK7:Hide()
			
			PetLongzi_OK1:SetText("#{ZSLZ_XML_4}")
			PetLongzi_OK2:SetText("#{ZSLZ_XML_5}")
			PetLongzi_OK3:SetText("#{ZSLZ_XML_6}")
			PetLongzi_OK4:SetText("#{ZSLZ_XML_7}")
			
			--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
			local str4 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
			if nIsBaiShou == 1 then
				str4 = str4.."\n".."#{BSJT_130114_11}"
			end
			PetLongzi_Text:SetText(str4)
		end
	elseif g_nCanSelectTotal == 4 and g_nServerScriptID == 999300 then
		
		PetLongzi_OK1:Show()
		PetLongzi_OK2:Show()
		PetLongzi_OK3:Show()
		PetLongzi_OK4:Show()
		PetLongzi_OK5:Hide()
		PetLongzi_OK6:Hide()
		PetLongzi_OK7:Hide()
		
		PetLongzi_OK1:SetText("#{ZSLZ_XML_7}")
		PetLongzi_OK2:SetText("#{ZSLZ_XML_8}")
		PetLongzi_OK3:SetText("#{ZSLZ_XML_9}")
		PetLongzi_OK4:SetText("#{BSJT_130114_10}")
		
		--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
		local str4 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
		if nIsBaiShou == 1 then
			str4 = str4.."\n".."#{BSJT_130114_11}"
		end
		PetLongzi_Text:SetText(str4)
	elseif g_nCanSelectTotal == 5 then
		PetLongzi_OK1:Show()
		PetLongzi_OK2:Show()
		PetLongzi_OK3:Show()
		PetLongzi_OK4:Show()
		PetLongzi_OK5:Show()
		PetLongzi_OK6:Hide()
		PetLongzi_OK7:Hide()
		
		PetLongzi_OK1:SetText("#{ZSLZ_XML_6}")
		PetLongzi_OK2:SetText("#{ZSLZ_XML_7}")
		PetLongzi_OK3:SetText("#{ZSLZ_XML_8}")
		PetLongzi_OK4:SetText("#{ZSLZ_XML_9}")
		PetLongzi_OK5:SetText("#{BSJT_130114_10}")
		
		--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
		local str5 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
		if nIsBaiShou == 1 then
			str5 = str5.."\n".."#{BSJT_130114_11}"
		end
		PetLongzi_Text:SetText(str5)
		
	elseif g_nCanSelectTotal == 6 then
		if g_nServerScriptID == 300027 and g_nItemIndex == 39910165 then
			PetLongzi_OK1:Show()
			PetLongzi_OK2:Show()
			PetLongzi_OK3:Show()
			PetLongzi_OK4:Show()
			PetLongzi_OK5:Show()
			PetLongzi_OK6:Show()
			PetLongzi_OK7:Hide()
					
			PetLongzi_OK1:SetText("#{ZSLZ_XML_5}")
			PetLongzi_OK2:SetText("#{ZSLZ_XML_6}")
			PetLongzi_OK3:SetText("#{ZSLZ_XML_7}")
			PetLongzi_OK4:SetText("#{ZSLZ_XML_8}")
			PetLongzi_OK5:SetText("#{ZSLZ_XML_9}")
			PetLongzi_OK6:SetText("#{BSJT_130114_10}")
		
			local str6 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
			if nIsBaiShou == 1 then
				str6 = str6.."\n".."#{BSJT_130114_11}"
			end
			PetLongzi_Text:SetText(str6)
		else
		
		PetLongzi_OK1:Show()
		PetLongzi_OK2:Show()
		PetLongzi_OK3:Show()
		PetLongzi_OK4:Show()
		PetLongzi_OK5:Show()
		PetLongzi_OK6:Show()
		PetLongzi_OK7:Hide()
		
		PetLongzi_OK1:SetText("#{ZSLZ_XML_4}")
		PetLongzi_OK2:SetText("#{ZSLZ_XML_5}")
		PetLongzi_OK3:SetText("#{ZSLZ_XML_6}")
		PetLongzi_OK4:SetText("#{ZSLZ_XML_7}")
		PetLongzi_OK5:SetText("#{ZSLZ_XML_8}")
		PetLongzi_OK6:SetText("#{ZSLZ_XML_9}")
		
		--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
		local str6 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
		if nIsBaiShou == 1 then
			str6 = str6.."\n".."#{BSJT_130114_11}"
		end
		PetLongzi_Text:SetText(str6)
		end
	
	elseif g_nCanSelectTotal == 7 then
		PetLongzi_OK1:Show()
		PetLongzi_OK2:Show()
		PetLongzi_OK3:Show()
		PetLongzi_OK4:Show()
		PetLongzi_OK5:Show()
		PetLongzi_OK6:Show()
		PetLongzi_OK7:Show()
		
		PetLongzi_OK1:SetText("#{ZSLZ_XML_4}")
		PetLongzi_OK2:SetText("#{ZSLZ_XML_5}")
		PetLongzi_OK3:SetText("#{ZSLZ_XML_6}")
		PetLongzi_OK4:SetText("#{ZSLZ_XML_7}")
		PetLongzi_OK5:SetText("#{ZSLZ_XML_8}")
		PetLongzi_OK6:SetText("#{ZSLZ_XML_9}")
		PetLongzi_OK7:SetText("#{BSJT_130114_10}")
		
		--PetLongzi_Text:SetText("#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}".."\n".."#{BSJT_130114_11}")
		local str7 = "#{ZSLZ_XML_2}"..g_strPetName.."#{ZSLZ_XML_3}"
		if nIsBaiShou == 1 then
			str7 = str7.."\n".."#{BSJT_130114_11}"
		end
		PetLongzi_Text:SetText(str7)

	else
		this:Hide()
	end 
end

function PetLongzi_Close()
	this:Hide();
end

function PetLongzi_Select(nIndex)

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name(g_strServerFunName)
		Set_XSCRIPT_ScriptID(g_nServerScriptID)
		Set_XSCRIPT_Parameter(0,g_nBagIndex)
		Set_XSCRIPT_Parameter(1,g_nItemIndex)
		Set_XSCRIPT_Parameter(2,nIndex)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT();
	
	this:Hide()
end