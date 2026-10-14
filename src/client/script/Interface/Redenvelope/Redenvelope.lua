
local g_Flag = 0   --0：抢到了 1：抢的次数太多了 2：手气背没抢着 3:红包已抢空

function Redenvelope_PreLoad()
	this:RegisterEvent("OPEN_GUILD_GIFT_SINGLE")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("REFRESH_GUILD_GIFT_SINGLE")
end

function Redenvelope_OnLoad()
		
end

function Redenvelope_OnEvent(event)

	if event == "OPEN_GUILD_GIFT_SINGLE" then
		
		Redenvelope_Frame:SetProperty("ZOrderChangeEnabled","True")
		
		if this:IsVisible() then
			Redenvelope_Frame:SetForce()
		else
			Redenvelope_Clear()
			this:Show()
		end
		
		g_Flag = tonumber(arg1)
		Redenvelope_Refresh(tonumber(arg0))
	
		return	
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "REFRESH_GUILD_GIFT_SINGLE" then
	
		Redenvelope_Refresh(tonumber(arg0))	
	
	end

end

function Redenvelope_Clear()
	Redenvelope_List:CleanAllElement("Redenvelope")
	Redenvelope_Image:Hide()
end

function Redenvelope_Refresh(nGiftType)

	Redenvelope_List:CleanAllElement("Redenvelope")
	Redenvelope_Image:Hide()
		
	if nGiftType == 0 then--鸿运
		Redenvelope_Frame_JB:Show()
		Redenvelope_Frame_YB:Hide()
	else									--鸿福
		Redenvelope_Frame_JB:Hide()
		Redenvelope_Frame_YB:Show()
	end
			
	local my_bonus_item = 0
	local num = 0
	for i = 1, 20 do
		local isMySelf,_,szName,nType,nItemID,nCount,nBest,nLogTime = Guild:GetGuildGiftSingleLog(i - 1)
		if szName ~= nil then
			
			local ItemBar = Redenvelope_List:AddItemElement( "RedenvelopeLogButton", "LEFT", "Redenvelope","" ,"")
			ItemBar:SetText1( "#c2ebeff"..tostring(szName) )
			
			if nType == 1 then

			elseif nType == 2 then
				local item_name = DataPool:Lua_GetItemNameByIndex(nItemID)
				
				ItemBar:SetText2( "#cfff263"..tostring(item_name) )
				
				if nBest == 1 then
					ItemBar:SetImage1Show()
				else
					ItemBar:SetImage1Hide()
				end

				if isMySelf == 1 then
					my_bonus_item = nItemID
				end				
			end
			
		end
	end
	
	Redenvelope_List:Flash()
	
	local owner_name = Guild:GetGuildGiftSingleLogOwnerName()
	if owner_name ~= nil then
		if nGiftType == 0 then
			local str_title = ScriptGlobal_Format("#{BHHB_160516_19}", tostring(owner_name))
			Redenvelope_DragTitle:SetText(str_title)
		else
			local str_title = ScriptGlobal_Format("#{BHHB_160516_39}", tostring(owner_name))
			Redenvelope_DragTitle:SetText(str_title)
		end
	end
	
	if g_Flag == 0 then
		
		local item_name = DataPool:Lua_GetItemNameByIndex(my_bonus_item)
		local item_class = DataPool:Lua_GetItemClassByIndex(my_bonus_item)
		
		local my_str = ScriptGlobal_Format("#{BHHB_160516_87}" ,tostring(item_name) )
		
		if item_class == 1 then
		
			local item_equip_point = DataPool:Lua_GetEquipPointByIndex(my_bonus_item)
			if item_equip_point == 8 then
				my_str = ScriptGlobal_Format("#{BHHB_160516_89}" ,tostring(item_name) )
			elseif item_equip_point == 16 then
				my_str = ScriptGlobal_Format("#{BHHB_160516_88}" ,tostring(item_name) )
			end
		end
		Redenvelope_Text:SetText(my_str)
		
		Redenvelope_Text1:SetText("#{BHHB_160516_35}")
		
	elseif g_Flag == 1 then
	
		if nGiftType == 0 then
			Redenvelope_Text:SetText("#{BHHB_160516_73}")
		else
			Redenvelope_Text:SetText("#{BHHB_160516_90}")
		end
		
		Redenvelope_Text1:SetText("#{BHHB_160516_74}")
	elseif g_Flag == 2 then
		Redenvelope_Text:SetText("#{BHHB_160516_75}")
		Redenvelope_Text1:SetText("")
	elseif g_Flag == 3 then
		Redenvelope_Text:SetText("#{BHHB_160516_76}")
		Redenvelope_Text1:SetText("")
	else
		Redenvelope_Text1:SetText("")
	end
end

function Redenvelope_ButtonCloseOnClicked()
	this:Hide()
end

function Redenvelope_ButtonRefreshOnClicked()
	local nRet = Guild:RefreshGuildGiftSingleLog()
	if nRet == 2 then
		PushDebugMessage("#{BHHB_160516_77}")
		this:Hide()	
	end
end


function Redenvelope_OnHidden()
	Redenvelope_Clear()	
end





