--!!!reloadscript =T3DaibiShop_MBuy

local g_T3DaibiShop_MBuy_Frame_UnifiedPosition = ""
local g_ItemIdx = -1
local g_CurNum = 1
local g_MaxCount = 0


function T3DaibiShop_MBuy_PreLoad()
	this:RegisterEvent("T3SHOP_OPEN_MBUY")
	this:RegisterEvent("SHSHOP_LIMIT", false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("UPDATE_T3SHOP_TOKEN", false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function T3DaibiShop_MBuy_OnLoad()
	g_T3DaibiShop_MBuy_Frame_UnifiedPosition = T3DaibiShop_MBuy_Frame:GetProperty("UnifiedPosition")
end

function T3DaibiShop_MBuy_OnEvent(event)
	
	if event == "T3SHOP_OPEN_MBUY" then
		g_CurNum = 1
		g_ItemIdx = tonumber(arg0)
		T3DaibiShop_MBuy_Open()		
		this:Activate()
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		if g_T3DaibiShop_MBuy_Frame_UnifiedPosition ~= nil then
			T3DaibiShop_MBuy_Frame:SetProperty("UnifiedPosition", g_T3DaibiShop_MBuy_Frame_UnifiedPosition)	
		end
	elseif event == "SHSHOP_LIMIT" or event == "UPDATE_YUANBAO" or event == "UPDATE_T3SHOP_TOKEN" then
		T3DaibiShop_MBuy_Open()
	end
end

function T3DaibiShop_MBuy_Open()
	
	PushEvent("T3SHOP_BUY_ITEM_CONFIRM", "close")
	
	local item_shop_index = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "SHOPINDEX")
	local nPrice = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "PRICE")
	local theAction = EnumAction(item_shop_index, "t3shop")
	
	local limit_type = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "LIMITTYPE")
	if theAction:GetID() ~= 0 then
		T3DaibiShop_MBuy_Item:SetActionItem(theAction:GetID())
		local strTemp = ScriptGlobal_Format("#{XDBS_200417_40}", theAction:GetName())
		T3DaibiShop_MBuy_ItemInfo_Text:SetText(strTemp)
		
		--if limit_type == 1 then
		--	T3DaibiShop_MBuy_ItemInfo_Text1:Show()
		--	T3DaibiShop_MBuy_ItemInfo_Text1:SetProperty("Image", "set:T3Shop image:Geren")
		if limit_type == 2 then
			T3DaibiShop_MBuy_ItemInfo_Text1:Show()
			
			local iRandomFlag = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "RANDOMFLAG")
			
			if iRandomFlag == 1 then
				T3DaibiShop_MBuy_ItemInfo_Text1:SetProperty("Image", "set:T3Shop image:Yongjiu")
			else
				T3DaibiShop_MBuy_ItemInfo_Text1:SetProperty("Image", "set:T3Shop image:Quanbang")
			end			
			
		else
			T3DaibiShop_MBuy_ItemInfo_Text1:Hide()
		end
		
		local currency = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "CURRENCY")
		if currency == 0 then
			local strPrice = ScriptGlobal_Format("#{LDSD_200805_36}", tostring(nPrice))
			T3DaibiShop_MBuy_ItemInfo_GB:SetText(strPrice)	
		else
			local strPrice = ScriptGlobal_Format("#{LDSD_200805_37}", tostring(nPrice))
			T3DaibiShop_MBuy_ItemInfo_GB:SetText(strPrice)	
		end
		
	else
		T3DaibiShop_MBuy_Item:SetActionItem(-1)
		T3DaibiShop_MBuy_ItemInfo_Text:SetText("")
		T3DaibiShop_MBuy_ItemInfo_GB:SetText("")
		T3DaibiShop_MBuy_ItemInfo_Text1:Hide()
	end
	
	T3DaibiShop_MBuy_InputNum:SetProperty("DefaultEditBox", "True")
	T3DaibiShop_MBuy_InputNum:SetText(tostring(g_CurNum))
	T3DaibiShop_MBuy_InputNum:SetSelected(0, -1)
	T3DaibiShop_MBuy_UpdateMaxCount()
	T3DaibiShop_MBuy_UpdateCurMoneyInfo()
	this:Show()

end

function T3DaibiShop_MBuy_UpdateCurMoneyInfo()
	
	local currency = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "CURRENCY")
	local nPrice = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "PRICE")
	local total_price = nPrice * g_CurNum
	local nHaveToken = Player:LuaFnGetT3ShopToken()
	local nYuanbao = Player:GetData("YUANBAO")
	
	if currency == 0 then
		local strTemp = ScriptGlobal_Format("#{LDSD_200805_42}", tostring(total_price))
		T3DaibiShop_MBuy_Price_Yuanbao:SetText(strTemp)
	
		strTemp = ScriptGlobal_Format("#{LDSD_200805_42}", tostring(nYuanbao))
		T3DaibiShop_MBuy_Cash_Yuanbao:SetText(strTemp)
	else
		local strTemp = ScriptGlobal_Format("#{LDSD_200805_43}", tostring(total_price))
		T3DaibiShop_MBuy_Price_Yuanbao:SetText(strTemp)
	
		strTemp = ScriptGlobal_Format("#{LDSD_200805_43}", tostring(nHaveToken))
		T3DaibiShop_MBuy_Cash_Yuanbao:SetText(strTemp)
	end

end

function T3DaibiShop_MBuy_UpdateMaxCount()
	
	g_MaxCount = 0
	if g_ItemIdx == nil or g_ItemIdx < 0 then
		return
	end
	
	local nPrice = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "PRICE")
	
	local nMaxCanBuyByMoney = 0	
	local currency = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "CURRENCY")
	if currency == 0 then
		local nYuanbao = Player:GetData("YUANBAO")
		nMaxCanBuyByMoney = math.floor(nYuanbao / nPrice)	
	else
		local nHaveToken = Player:LuaFnGetT3ShopToken()
		nMaxCanBuyByMoney = math.floor(nHaveToken / nPrice)	
	end
	
	local limit_type = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "LIMITTYPE")
	if limit_type == 0 then
		g_MaxCount = nMaxCanBuyByMoney
		return
	end	
	
	if limit_type == 1 then
		local player_limit = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "PLAYERREMAIN")
		if player_limit < nMaxCanBuyByMoney then
			g_MaxCount = player_limit
		else
			g_MaxCount = nMaxCanBuyByMoney
		end
		return
	end

	if limit_type == 2 then
		local player_limit = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "PLAYERREMAIN")
		local guild_limit = DataPool:LuaFnGetT3ShopItemInfo(g_ItemIdx, "GUILDREMAIN")
		
		if player_limit < 0 then
			if guild_limit < nMaxCanBuyByMoney then
				g_MaxCount = guild_limit
			else
				g_MaxCount = nMaxCanBuyByMoney
			end		
		elseif player_limit < guild_limit then
			if player_limit < nMaxCanBuyByMoney then
				g_MaxCount = player_limit
			else
				g_MaxCount = nMaxCanBuyByMoney
			end
		else
			if guild_limit < nMaxCanBuyByMoney then
				g_MaxCount = guild_limit
			else
				g_MaxCount = nMaxCanBuyByMoney
			end
		end
		return
	end

end

function T3DaibiShop_MBuy_CalMax()
	T3DaibiShop_MBuy_UpdateMaxCount()	
	T3DaibiShop_MBuy_InputNum:SetText(tostring(g_MaxCount))
end

function T3DaibiShop_MBuy_TextChanged()
	
	local nString = T3DaibiShop_MBuy_InputNum:GetText()
	
	local nChangNum = 1
	
	if nString == nil or nString == "" then
		g_CurNum = 0
		T3DaibiShop_MBuy_UpdateCurMoneyInfo()
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
		T3DaibiShop_MBuy_InputNum:SetText(tostring(g_CurNum))		
		T3DaibiShop_MBuy_UpdateCurMoneyInfo()
	end
end

function T3DaibiShop_MBuy_Close_Clicked()
	this:Hide()
end

function T3DaibiShop_MBuy_OnHidden()
	g_CurNum = 1
	g_ItemIdx = -1
end

function T3DaibiShop_MBuy_OK_Clicked()
	
	if g_ItemIdx == nil or g_ItemIdx < 0 then
		return
	end	
	
	local nString = T3DaibiShop_MBuy_InputNum:GetText()
	if nString == nil or nString == "" then
		PushDebugMessage("#{LDSD_200805_58}")
		return
	end
	
	if g_CurNum == 0 then
		PushDebugMessage("#{LDSD_200805_58}")
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
	
	NpcShop:LuaFnT3ShopBuyItem(g_ItemIdx, g_CurNum)
	T3DaibiShop_MBuy_Close_Clicked()
end
