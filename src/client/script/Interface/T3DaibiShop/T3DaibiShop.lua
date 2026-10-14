--!!!reloadscript =T3DaibiShop

local GOODS_BUTTONS_NUM = 18
local GOODS_BUTTONS = {}
local GOODS_DESCS = {}
local GOODS_LIMIT_TEXT = {}
local GOODS_PRICE = {}
local GOODS_GUILD_LIMIT = {}
local g_CaredObjServerID = -1
local g_MaxPage = 1
local g_CurPage = 1
local g_CurShopLevel = 1

--当前商店的商品数量
local g_nTotalNum		= 0

local g_T3DaibiShop_Frame_UnifiedPosition

local g_CurTab = 1

--PreLoad
function T3DaibiShop_PreLoad()
	
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("OPEN_T3SHOP")
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("UPDATE_T3SHOP_TOKEN", false)
	this:RegisterEvent("T3SHOP_LIMIT_UPDATE", false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end
--OnLoad
function T3DaibiShop_OnLoad()
	
	GOODS_BUTTONS[1]	= T3DaibiShop_Item1
	GOODS_BUTTONS[2]	= T3DaibiShop_Item2
	GOODS_BUTTONS[3]	= T3DaibiShop_Item3
	GOODS_BUTTONS[4]	= T3DaibiShop_Item4
	GOODS_BUTTONS[5]	= T3DaibiShop_Item5
	GOODS_BUTTONS[6]	= T3DaibiShop_Item6
	GOODS_BUTTONS[7]	= T3DaibiShop_Item7
	GOODS_BUTTONS[8]	= T3DaibiShop_Item8
	GOODS_BUTTONS[9]	= T3DaibiShop_Item9
	GOODS_BUTTONS[10]	= T3DaibiShop_Item10
	GOODS_BUTTONS[11]	= T3DaibiShop_Item11
	GOODS_BUTTONS[12]	= T3DaibiShop_Item12
	GOODS_BUTTONS[13]	= T3DaibiShop_Item13
	GOODS_BUTTONS[14]	= T3DaibiShop_Item14
	GOODS_BUTTONS[15]	= T3DaibiShop_Item15
	GOODS_BUTTONS[16]	= T3DaibiShop_Item16
	GOODS_BUTTONS[17]	= T3DaibiShop_Item17
	GOODS_BUTTONS[18]	= T3DaibiShop_Item18

	GOODS_DESCS[1] 	= T3DaibiShop_ItemInfo1_Text
	GOODS_DESCS[2]	= T3DaibiShop_ItemInfo2_Text
	GOODS_DESCS[3]	= T3DaibiShop_ItemInfo3_Text
	GOODS_DESCS[4] 	= T3DaibiShop_ItemInfo4_Text
	GOODS_DESCS[5]	= T3DaibiShop_ItemInfo5_Text
	GOODS_DESCS[6]	= T3DaibiShop_ItemInfo6_Text
	GOODS_DESCS[7]	= T3DaibiShop_ItemInfo7_Text
	GOODS_DESCS[8]	= T3DaibiShop_ItemInfo8_Text
	GOODS_DESCS[9]	= T3DaibiShop_ItemInfo9_Text
	GOODS_DESCS[10]	= T3DaibiShop_ItemInfo10_Text
	GOODS_DESCS[11]	= T3DaibiShop_ItemInfo11_Text
	GOODS_DESCS[12]	= T3DaibiShop_ItemInfo12_Text
	GOODS_DESCS[13]	= T3DaibiShop_ItemInfo13_Text
	GOODS_DESCS[14]	= T3DaibiShop_ItemInfo14_Text
	GOODS_DESCS[15]	= T3DaibiShop_ItemInfo15_Text
	GOODS_DESCS[16]	= T3DaibiShop_ItemInfo16_Text
	GOODS_DESCS[17]	= T3DaibiShop_ItemInfo17_Text
	GOODS_DESCS[18]	= T3DaibiShop_ItemInfo18_Text
	
	GOODS_LIMIT_TEXT[1]		= T3DaibiShop_ItemInfo1_Text1
	GOODS_LIMIT_TEXT[2]		= T3DaibiShop_ItemInfo2_Text1
	GOODS_LIMIT_TEXT[3]		= T3DaibiShop_ItemInfo3_Text1
	GOODS_LIMIT_TEXT[4]		= T3DaibiShop_ItemInfo4_Text1
	GOODS_LIMIT_TEXT[5]		= T3DaibiShop_ItemInfo5_Text1
	GOODS_LIMIT_TEXT[6]		= T3DaibiShop_ItemInfo6_Text1
	GOODS_LIMIT_TEXT[7]		= T3DaibiShop_ItemInfo7_Text1
	GOODS_LIMIT_TEXT[8]		= T3DaibiShop_ItemInfo8_Text1
	GOODS_LIMIT_TEXT[9]		= T3DaibiShop_ItemInfo9_Text1
	GOODS_LIMIT_TEXT[10]	= T3DaibiShop_ItemInfo10_Text1
	GOODS_LIMIT_TEXT[11]	= T3DaibiShop_ItemInfo11_Text1
	GOODS_LIMIT_TEXT[12]	= T3DaibiShop_ItemInfo12_Text1
	GOODS_LIMIT_TEXT[13]	= T3DaibiShop_ItemInfo13_Text1
	GOODS_LIMIT_TEXT[14]	= T3DaibiShop_ItemInfo14_Text1
	GOODS_LIMIT_TEXT[15]	= T3DaibiShop_ItemInfo15_Text1
	GOODS_LIMIT_TEXT[16]	= T3DaibiShop_ItemInfo16_Text1
	GOODS_LIMIT_TEXT[17]	= T3DaibiShop_ItemInfo17_Text1
	GOODS_LIMIT_TEXT[18]	= T3DaibiShop_ItemInfo18_Text1
	
	GOODS_GUILD_LIMIT[1]		= T3DaibiShop_ItemInfo1_Text2
	GOODS_GUILD_LIMIT[2]		= T3DaibiShop_ItemInfo2_Text2
	GOODS_GUILD_LIMIT[3]		= T3DaibiShop_ItemInfo3_Text2
	GOODS_GUILD_LIMIT[4]		= T3DaibiShop_ItemInfo4_Text2
	GOODS_GUILD_LIMIT[5]		= T3DaibiShop_ItemInfo5_Text2
	GOODS_GUILD_LIMIT[6]		= T3DaibiShop_ItemInfo6_Text2
	GOODS_GUILD_LIMIT[7]		= T3DaibiShop_ItemInfo7_Text2
	GOODS_GUILD_LIMIT[8]		= T3DaibiShop_ItemInfo8_Text2
	GOODS_GUILD_LIMIT[9]		= T3DaibiShop_ItemInfo9_Text2
	GOODS_GUILD_LIMIT[10]	= T3DaibiShop_ItemInfo10_Text2
	GOODS_GUILD_LIMIT[11]	= T3DaibiShop_ItemInfo11_Text2
	GOODS_GUILD_LIMIT[12]	= T3DaibiShop_ItemInfo12_Text2
	GOODS_GUILD_LIMIT[13]	= T3DaibiShop_ItemInfo13_Text2
	GOODS_GUILD_LIMIT[14]	= T3DaibiShop_ItemInfo14_Text2
	GOODS_GUILD_LIMIT[15]	= T3DaibiShop_ItemInfo15_Text2
	GOODS_GUILD_LIMIT[16]	= T3DaibiShop_ItemInfo16_Text2
	GOODS_GUILD_LIMIT[17]	= T3DaibiShop_ItemInfo17_Text2
	GOODS_GUILD_LIMIT[18]	= T3DaibiShop_ItemInfo18_Text2

	GOODS_PRICE[1]  =     T3DaibiShop_ItemInfo1_GB
	GOODS_PRICE[2]  =     T3DaibiShop_ItemInfo2_GB
	GOODS_PRICE[3]  =     T3DaibiShop_ItemInfo3_GB
	GOODS_PRICE[4]  =     T3DaibiShop_ItemInfo4_GB
	GOODS_PRICE[5]  =     T3DaibiShop_ItemInfo5_GB
	GOODS_PRICE[6]  =     T3DaibiShop_ItemInfo6_GB
	GOODS_PRICE[7]  =     T3DaibiShop_ItemInfo7_GB
	GOODS_PRICE[8]  =     T3DaibiShop_ItemInfo8_GB
	GOODS_PRICE[9]  =     T3DaibiShop_ItemInfo9_GB
	GOODS_PRICE[10] =     T3DaibiShop_ItemInfo10_GB
	GOODS_PRICE[11] =     T3DaibiShop_ItemInfo11_GB
	GOODS_PRICE[12] =     T3DaibiShop_ItemInfo12_GB
	GOODS_PRICE[13]  =     T3DaibiShop_ItemInfo13_GB
	GOODS_PRICE[14]  =     T3DaibiShop_ItemInfo14_GB
	GOODS_PRICE[15]  =     T3DaibiShop_ItemInfo15_GB
	GOODS_PRICE[16]  =     T3DaibiShop_ItemInfo16_GB
	GOODS_PRICE[17]  =     T3DaibiShop_ItemInfo17_GB
	GOODS_PRICE[18]  =     T3DaibiShop_ItemInfo18_GB

	g_T3DaibiShop_Frame_UnifiedPosition = T3DaibiShop_Frame:GetProperty("UnifiedPosition")

end
--OnEvent
function T3DaibiShop_OnEvent(event)

	if event == "OPEN_T3SHOP" then
		g_CurShopLevel = tonumber(arg0)
		local nObjID = tonumber(arg1)
		if nObjID and nObjID >= 0 then
			g_CaredObjServerID = nObjID
			local nObjCared = DataPool:GetNPCIDByServerID(g_CaredObjServerID)
			this:CareObject(nObjCared, 1)
		end
		
		this:Show()		
		g_CurPage = 1
		g_CurTab = 1
		T3DaibiShop_UpdatePage()
		return
	end
	
	if event == "T3SHOP_LIMIT_UPDATE" then
		if g_CurTab == 1 then
			T3DaibiShop_UpdateLimit()
		end
		return
	end
	
	if event == "UPDATE_YUANBAO" then	
		local strTemp = ScriptGlobal_Format("#{LDSD_200805_29}", tostring(Player:GetData("YUANBAO")))	
		T3DaibiShop_Text2:SetText(strTemp)
		return
	end
	
	--刷新代币
	if event == "UPDATE_T3SHOP_TOKEN" then
		local nHaveToken = Player:LuaFnGetT3ShopToken()
		local strTemp = ScriptGlobal_Format("#{LDSD_200805_30}", tostring(nHaveToken))	
		T3DaibiShop_Text3:SetText(strTemp)
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		if g_T3DaibiShop_Frame_UnifiedPosition ~= nil then
			T3DaibiShop_Frame:SetProperty("UnifiedPosition", g_T3DaibiShop_Frame_UnifiedPosition)
		end
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 44005501 then	

		return
	end
end

function T3DaibiShop_OnHidden()
	for i = 1, GOODS_BUTTONS_NUM do
		GOODS_BUTTONS[i]:SetActionItem(-1)
	end
	
	g_CurPage = 1
	g_CurTab = 1
	g_CaredObjServerID = -1
	SetDefaultMouse()
	
	PushEvent("T3SHOP_BUY_ITEM_CONFIRM", "close")
	
	if IsWindowShow("T3DaibiShop_MBuy") then
		CloseWindow("T3DaibiShop_MBuy", true)
	end
end

function T3DaibiShop_OnCloseClicked()
	this:Hide()
end

function T3DaibiShop_UpdatePage()
	
	T3DaibiShop_UpdateButtons()	
	
	local strTemp = ScriptGlobal_Format("#{LDSD_200805_17}", tostring(g_CurShopLevel))
	T3DaibiShop_Text:SetText(strTemp) 
	
	if g_nTotalNum == 0 or g_nTotalNum ~= GetActionNum("t3shop") then
		g_nTotalNum	= GetActionNum("t3shop")
	end
	
	--计算总页数
	local nTotalPage
	if g_nTotalNum < 1 then
		nTotalPage	= 1
	else
		nTotalPage	= math.floor((g_nTotalNum - 1)/GOODS_BUTTONS_NUM) + 1
	end

	g_MaxPage = nTotalPage
	
	local nStartIndex = (g_CurPage - 1) * GOODS_BUTTONS_NUM
	
	for i = 1, GOODS_BUTTONS_NUM do
		
		local item_shop_index = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "SHOPINDEX")

		local theAction = EnumAction(item_shop_index, "t3shop")
		if theAction:GetID() ~= 0 then

			GOODS_BUTTONS[i]:SetActionItem(theAction:GetID())
			local strName = tostring(theAction:GetName())
			GOODS_DESCS[i]:SetText(strName)
			
			local price = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "PRICE")
			local currency = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "CURRENCY")
			if currency == 0 then
				local strPrice = ScriptGlobal_Format("#{LDSD_200805_27}", tostring(price))
				GOODS_PRICE[i]:SetText(strPrice)	
			else
				local strPrice = ScriptGlobal_Format("#{LDSD_200805_28}", tostring(price))
				GOODS_PRICE[i]:SetText(strPrice)	
			end
			
			local limit_type = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "LIMITTYPE")
			--if limit_type == 1 then
				--GOODS_LIMIT_TEXT[i]:Hide()
				--GOODS_LIMIT_TEXT[i]:SetProperty("Image", "set:T3Shop image:Geren")
				--GOODS_LIMIT_TEXT[i]:SetToolTip("#{LDSD_200805_23}")	
				--GOODS_GUILD_LIMIT[i]:SetText("")
			if limit_type == 2 then
				GOODS_LIMIT_TEXT[i]:Show()
				
				local iRandomFlag = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "RANDOMFLAG")				
				if iRandomFlag == 1 then
					GOODS_LIMIT_TEXT[i]:SetProperty("Image", "set:T3Shop image:Yongjiu")
					GOODS_LIMIT_TEXT[i]:SetToolTip("#{LDSD_200805_84}")
				else
					GOODS_LIMIT_TEXT[i]:SetProperty("Image", "set:T3Shop image:Quanbang")
					GOODS_LIMIT_TEXT[i]:SetToolTip("#{LDSD_200805_22}")
				end				
				
				local guild_remain = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "GUILDREMAIN")
				if guild_remain > 0 then
					local strRemain = ScriptGlobal_Format("#{LDSD_200805_25}", tostring(guild_remain))				
					GOODS_GUILD_LIMIT[i]:SetText(strRemain)
				else
					GOODS_BUTTONS[i]:Disable()
					GOODS_GUILD_LIMIT[i]:SetText("#{LDSD_200805_26}")
				end
			else
				GOODS_LIMIT_TEXT[i]:Hide()
				GOODS_LIMIT_TEXT[i]:SetToolTip("")
				GOODS_GUILD_LIMIT[i]:SetText("")
			end
			
		else
			GOODS_DESCS[i]:SetText("")
			GOODS_PRICE[i]:SetText("")
			GOODS_LIMIT_TEXT[i]:Hide()
			GOODS_LIMIT_TEXT[i]:SetToolTip("")
			GOODS_BUTTONS[i]:SetActionItem(-1)
			GOODS_GUILD_LIMIT[i]:SetText("")
		end
	end
	
	strTemp = ScriptGlobal_Format("#{LDSD_200805_29}", tostring(Player:GetData("YUANBAO")))	
	T3DaibiShop_Text2:SetText(strTemp)
	
	local nHaveToken = Player:LuaFnGetT3ShopToken()
	strTemp = ScriptGlobal_Format("#{LDSD_200805_30}", tostring(nHaveToken))	
	T3DaibiShop_Text3:SetText(strTemp)
	
	strTemp = ScriptGlobal_Format("#{LDSD_200805_33}", tostring(g_CurPage), tostring(g_MaxPage))	
	T3DaibiShop_CurrentlyPage:SetText(strTemp)
	
	
	T3DaibiShop_UpPage:Enable()
	T3DaibiShop_DownPage:Enable()
	if g_CurPage == g_MaxPage then
		T3DaibiShop_DownPage:Disable()
	end

	if g_CurPage == 1 then
		T3DaibiShop_UpPage:Disable()
	end	
end

function T3DaibiShop_UpdateLimit()	
	
	local nStartIndex = (g_CurPage - 1) * GOODS_BUTTONS_NUM
	
	for i = 1, GOODS_BUTTONS_NUM do
		local theAction = EnumAction(nStartIndex + i - 1, "t3shop")
		if theAction:GetID() ~= 0 then			
			local limit_type = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "LIMITTYPE")
			if limit_type == 2 then
				local guild_remain = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "GUILDREMAIN")
				if guild_remain > 0 then
					local strRemain = ScriptGlobal_Format("#{LDSD_200805_25}", tostring(guild_remain))				
					GOODS_GUILD_LIMIT[i]:SetText(strRemain)
				else
					GOODS_BUTTONS[i]:Disable()
					GOODS_GUILD_LIMIT[i]:SetText("#{LDSD_200805_26}")
				end
			end
		end
	end

end

function T3DaibiShop_UpdatePagePreview()
	
	T3DaibiShop_UpdateButtons()	
	
	if g_CurShopLevel == 5 then
		return
	end
	
	local strTemp = ScriptGlobal_Format("#{LDSD_200805_17}", tostring(g_CurShopLevel + 1))
	T3DaibiShop_Text:SetText(strTemp) 
	
	if g_nTotalNum == 0 or g_nTotalNum ~= GetActionNum("t3shop_pre") then
		g_nTotalNum	= GetActionNum("t3shop_pre")
	end
	
	--计算总页数
	local nTotalPage
	if g_nTotalNum < 1 then
		nTotalPage	= 1
	else
		nTotalPage	= math.floor((g_nTotalNum - 1)/GOODS_BUTTONS_NUM) + 1
	end

	g_MaxPage = nTotalPage
	
	local nStartIndex = (g_CurPage - 1) * GOODS_BUTTONS_NUM
	
	for i = 1, GOODS_BUTTONS_NUM do
		
		local item_shop_index = DataPool:LuaFnGetT3ShopPreviewItemInfo(nStartIndex + i - 1, "SHOPINDEX")
		
		local theAction = EnumAction(item_shop_index, "t3shop_pre")
		if theAction:GetID() ~= 0 then

			GOODS_BUTTONS[i]:SetActionItem(theAction:GetID())
			local strName = tostring(theAction:GetName())
			GOODS_DESCS[i]:SetText(strName)
			
			local price = DataPool:LuaFnGetT3ShopPreviewItemInfo(nStartIndex + i - 1, "PRICE")
			local currency = DataPool:LuaFnGetT3ShopPreviewItemInfo(nStartIndex + i - 1, "CURRENCY")
			if currency == 0 then
				local strPrice = ScriptGlobal_Format("#{LDSD_200805_27}", tostring(price))
				GOODS_PRICE[i]:SetText(strPrice)	
			else
				local strPrice = ScriptGlobal_Format("#{LDSD_200805_28}", tostring(price))
				GOODS_PRICE[i]:SetText(strPrice)	
			end
			
			local limit_type = DataPool:LuaFnGetT3ShopPreviewItemInfo(nStartIndex + i - 1, "LIMITTYPE")
			--if limit_type == 1 then
			--	GOODS_LIMIT_TEXT[i]:Show()
			--	GOODS_LIMIT_TEXT[i]:SetProperty("Image", "set:T3Shop image:Geren ")
			--	GOODS_LIMIT_TEXT[i]:SetToolTip("#{LDSD_200805_23}")	
			--	GOODS_GUILD_LIMIT[i]:SetText("")
			if limit_type == 2 then
				GOODS_LIMIT_TEXT[i]:Show()
				
				local iRandomFlag = DataPool:LuaFnGetT3ShopItemInfo(nStartIndex + i - 1, "RANDOMFLAG")				
				if iRandomFlag == 1 then
					GOODS_LIMIT_TEXT[i]:SetProperty("Image", "set:T3Shop image:Yongjiu")
					GOODS_LIMIT_TEXT[i]:SetToolTip("#{LDSD_200805_84}")
				else
					GOODS_LIMIT_TEXT[i]:SetProperty("Image", "set:T3Shop image:Quanbang")
					GOODS_LIMIT_TEXT[i]:SetToolTip("#{LDSD_200805_22}")
				end
				
				local guild_remain = DataPool:LuaFnGetT3ShopPreviewItemInfo(nStartIndex + i - 1, "GUILDREMAIN")
				local strRemain = ScriptGlobal_Format("#{LDSD_200805_25}", tostring(guild_remain))				
				GOODS_GUILD_LIMIT[i]:SetText(strRemain)
			else
				GOODS_LIMIT_TEXT[i]:Hide()
				GOODS_LIMIT_TEXT[i]:SetToolTip("")
				GOODS_GUILD_LIMIT[i]:SetText("")
			end
			
		else
			GOODS_DESCS[i]:SetText("")
			GOODS_PRICE[i]:SetText("")
			GOODS_LIMIT_TEXT[i]:Hide()
			GOODS_LIMIT_TEXT[i]:SetToolTip("")
			GOODS_BUTTONS[i]:SetActionItem(-1)
			GOODS_GUILD_LIMIT[i]:SetText("")
		end
	end
	
	strTemp = ScriptGlobal_Format("#{LDSD_200805_29}", tostring(Player:GetData("YUANBAO")))	
	T3DaibiShop_Text2:SetText(strTemp)
	
	local nHaveToken = Player:LuaFnGetT3ShopToken()
	strTemp = ScriptGlobal_Format("#{LDSD_200805_30}", tostring(nHaveToken))	
	T3DaibiShop_Text3:SetText(strTemp)
	
	strTemp = ScriptGlobal_Format("#{LDSD_200805_33}", tostring(g_CurPage), tostring(g_MaxPage))	
	T3DaibiShop_CurrentlyPage:SetText(strTemp)
	
	
	T3DaibiShop_UpPage:Enable()
	T3DaibiShop_DownPage:Enable()
	if g_CurPage == g_MaxPage then
		T3DaibiShop_DownPage:Disable()
	end

	if g_CurPage == 1 then
		T3DaibiShop_UpPage:Disable()
	end	
end

function T3DaibiShop_UpdateButtons()
	if g_CurTab == 1 then

	else

	end
end

function T3DaibiShop_GoodButton_Clicked(nIndex)
	if nIndex < 1 or nIndex > GOODS_BUTTONS_NUM then
		return
	end
	GOODS_BUTTONS[nIndex]:DoAction()
end

function T3DaibiShop_ChangeShowTab(idx)
	
	if g_CurTab == idx then
		return
	end
	
	if g_CurShopLevel == 5 and idx == 2 then
		return
	end
	
	if idx == 1 or idx == 2 then
		g_CurTab = idx
		g_CurPage = 1
		if g_CurTab == 1 then
			T3DaibiShop_UpdatePage()
		else
			T3DaibiShop_UpdatePagePreview()
		end
	end	
end

function T3DaibiShop_PageUp()
	if g_CurPage <= 1 then
		return
	end
	
	g_CurPage = g_CurPage - 1
	if g_CurTab == 1 then
		T3DaibiShop_UpdatePage()
	else
		T3DaibiShop_UpdatePagePreview()
	end
end

function T3DaibiShop_PageDown()
	if g_CurPage >= g_MaxPage then
		return
	end
	
	g_CurPage = g_CurPage + 1
	if g_CurTab == 1 then
		T3DaibiShop_UpdatePage()
	else
		T3DaibiShop_UpdatePagePreview()
	end
end

function T3DaibiShop_BatchBuy()
	if g_CurTab == 1 then
		PushEvent("T3SHOP_BUY_ITEM_CONFIRM", "close")
		PrepearBuyMult()
	end
end



