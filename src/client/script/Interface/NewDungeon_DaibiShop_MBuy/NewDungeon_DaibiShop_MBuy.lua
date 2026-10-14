--!!!reloadscript =NewDungeon_DaibiShop_MBuy
local g_NewDungeon_DaibiShop_MBuy_Frame_UnifiedPosition = ""
local g_ItemIdx = -1
local g_CurNum = 1
local g_MaxCount = 0
local g_Limit = {120, 40, 8}

function NewDungeon_DaibiShop_MBuy_PreLoad()
	this:RegisterEvent("SHSHOP_OPEN_MBUY")
	this:RegisterEvent("SHSHOP_LIMIT", false)
	this:RegisterEvent("UPDATE_SHANHAIBI", false)
	this:RegisterEvent("CLOSE_BOOTH", false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NewDungeon_DaibiShop_MBuy_OnLoad()
	g_NewDungeon_DaibiShop_MBuy_Frame_UnifiedPosition = NewDungeon_DaibiShop_MBuy_Frame:GetProperty("UnifiedPosition")
end

function NewDungeon_DaibiShop_MBuy_OnEvent(event)
	
	if event == "SHSHOP_OPEN_MBUY" then
		g_CurNum = 1
		g_ItemIdx = tonumber(arg0)
		NewDungeon_DaibiShop_MBuy_Open()		
		this:Activate()
	elseif event == "CLOSE_BOOTH" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewDungeon_DaibiShop_MBuy_Frame:SetProperty("UnifiedPosition", g_NewDungeon_DaibiShop_MBuy_Frame_UnifiedPosition)	
	elseif event == "SHSHOP_LIMIT" or event == "UPDATE_SHANHAIBI" then
		NewDungeon_DaibiShop_MBuy_Open()
	end
end

function NewDungeon_DaibiShop_MBuy_Open()
	
	local nPrice = NpcShop:EnumItemPrice(g_ItemIdx)
	local theAction = EnumAction(g_ItemIdx, "boothitem")
	
	if theAction:GetID() ~= 0 then
		NewDungeon_DaibiShop_MBuy_But:SetActionItem(theAction:GetID())
		local strTemp = ScriptGlobal_Format("#{XDBS_200417_40}", theAction:GetName())
		NewDungeon_DaibiShop_MBuy_ItemInfo_Text:SetText(strTemp)
		
		local strPrice = ScriptGlobal_Format("#{XDBS_200417_41}", tostring(nPrice))		
		NewDungeon_DaibiShop_MBuy_ItemInfo_Lilianzhi:SetText(strPrice)
	else
		NewDungeon_DaibiShop_MBuy_But:SetActionItem(-1)
		NewDungeon_DaibiShop_MBuy_ItemInfo_Text:SetText("")
		NewDungeon_DaibiShop_MBuy_ItemInfo_Lilianzhi:SetText("")
	end
	
	NewDungeon_DaibiShop_MBuy_InputNum:SetProperty("DefaultEditBox", "True")
	NewDungeon_DaibiShop_MBuy_InputNum:SetText(tostring(g_CurNum))
	NewDungeon_DaibiShop_MBuy_InputNum:SetSelected(0, -1)
	NewDungeon_DaibiShop_MBuy_UpdateMaxCount()
	NewDungeon_DaibiShop_MBuy_UpdateCurMoneyInfo()
	this:Show()

end

function NewDungeon_DaibiShop_MBuy_UpdateCurMoneyInfo()

	local nPrice = NpcShop:EnumItemPrice(g_ItemIdx)
	local needTokens = nPrice * g_CurNum
	local haveTokens = Player:GetData("SHANHAIBI")
	
	local strTemp = ScriptGlobal_Format("#{XDBS_200417_47}", tostring(needTokens))
	NewDungeon_DaibiShop_MBuy_Price_Lilianzhi:SetText(strTemp)
		
	if needTokens > haveTokens then	
		strTemp = ScriptGlobal_Format("#{XDBS_200417_49}", tostring(haveTokens))
		NewDungeon_DaibiShop_MBuy_Cash_Lilianzhi:SetText(strTemp)
	else
		strTemp = ScriptGlobal_Format("#{XDBS_200417_50}", tostring(haveTokens))
		NewDungeon_DaibiShop_MBuy_Cash_Lilianzhi:SetText(strTemp)
	end
end

function NewDungeon_DaibiShop_MBuy_UpdateMaxCount()
	
	g_MaxCount = 0
	if g_ItemIdx == nil or g_ItemIdx < 0 then
		return
	end
	
	local nPrice = NpcShop:EnumItemPrice(g_ItemIdx)
	local theAction = EnumAction(g_ItemIdx, "boothitem")
	
	local limit_count = 0
	
	if theAction:GetID() ~= 0 then	
		local item_table_index = theAction:GetItemTableIndex()
		local item_qual = LuaFnGetSHShopItemQual(item_table_index, 0)
		local limit1, limit2, limit3, _, _, _, _, _, _ = Player:GetData("SHShopLimit")
		
		if item_qual == 0 then
			limit_count = g_Limit[1] - limit1
		elseif item_qual == 1 then
			limit_count = g_Limit[2] - limit2
		elseif item_qual == 2 then
			limit_count = g_Limit[3] - limit3
		end
		
		if limit_count < 0 then
			limit_count = 0
		end
	end
	
	local haveTokens = Player:GetData("SHANHAIBI")
	local nMaxCanBuyByMoney = math.floor(haveTokens/nPrice)
	
	if limit_count < nMaxCanBuyByMoney then
		g_MaxCount = limit_count
	else
		g_MaxCount = nMaxCanBuyByMoney
	end
end

function NewDungeon_DaibiShop_MBuy_CalMax()
	NewDungeon_DaibiShop_MBuy_UpdateMaxCount()	
	NewDungeon_DaibiShop_MBuy_InputNum:SetText(tostring(g_MaxCount))
end

function NewDungeon_DaibiShop_MBuy_TextChanged()
	
	local nString = NewDungeon_DaibiShop_MBuy_InputNum:GetText()
	
	local nChangNum = 1
	
	if nString == nil or nString == "" then
		g_CurNum = 0
		NewDungeon_DaibiShop_MBuy_UpdateCurMoneyInfo()
		return
	else
		nChangNum = tonumber(nString)
	end
	
	if nChangNum >= g_MaxCount then
		nChangNum = g_MaxCount
	end
	
	if nChangNum <= 0 then
		nChangNum = 1
	end
	
	if g_CurNum ~= tonumber(nString) then
		g_CurNum = nChangNum
		NewDungeon_DaibiShop_MBuy_InputNum:SetText(tostring(g_CurNum))		
		NewDungeon_DaibiShop_MBuy_UpdateCurMoneyInfo()
	end
end

function NewDungeon_DaibiShop_MBuy_Close_Clicked()
	this:Hide()
end

function NewDungeon_DaibiShop_MBuy_OnHidden()
	g_CurNum = 1
	g_ItemIdx = -1
end

function NewDungeon_DaibiShop_MBuy_OK_Clicked()
	
	if g_ItemIdx == nil or g_ItemIdx < 0 then
		return
	end
	
	local theAction = EnumAction(g_ItemIdx, "boothitem")
	if theAction:GetID() == 0 then
		return
	end	
	
	local nString = NewDungeon_DaibiShop_MBuy_InputNum:GetText()
	if nString == nil or nString == "" then
		PushDebugMessage("#{XDBS_200417_55}")
		return
	end
	
	if g_CurNum == 0 then
		PushDebugMessage("#{XDBS_200417_55}")
		return
	end
	
	local nLevel = Player:GetData("LEVEL")
	if nLevel < 75 then
		PushDebugMessage("#{XDBS_200417_24}")
		return
	end
	
	--判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end	
	
	local nPrice = NpcShop:EnumItemPrice(g_ItemIdx)
	
	local limit_count = 0
	local item_table_index = theAction:GetItemTableIndex()
	local item_qual = LuaFnGetSHShopItemQual(item_table_index, 0)
	local limit1, limit2, limit3, _, _, _, _, _, _ = Player:GetData("SHShopLimit")
	
	if item_qual == 0 then
		limit_count = g_Limit[1] - limit1
	elseif item_qual == 1 then
		limit_count = g_Limit[2] - limit2
	elseif item_qual == 2 then
		limit_count = g_Limit[3] - limit3
	end
	
	if limit_count < 0 then
		limit_count = 0
	end
	
	if limit_count < g_CurNum then
		if item_qual == 0 then
			local strTemp = ScriptGlobal_Format("#{XDBS_200417_54}", "#{XDBS_200417_35}", tostring(limit_count))
			PushDebugMessage(strTemp)
		elseif item_qual == 1 then
			local strTemp = ScriptGlobal_Format("#{XDBS_200417_54}", "#{XDBS_200417_36}", tostring(limit_count))
			PushDebugMessage(strTemp)
		elseif item_qual == 2 then
			local strTemp = ScriptGlobal_Format("#{XDBS_200417_54}", "#{XDBS_200417_37}", tostring(limit_count))
			PushDebugMessage(strTemp)
		end	
	end	

	NpcShop:BulkBuyItem(g_ItemIdx, g_CurNum, 0)
	NewDungeon_DaibiShop_MBuy_Close_Clicked()
end
