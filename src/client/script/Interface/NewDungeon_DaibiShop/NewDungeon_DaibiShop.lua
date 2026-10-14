
local GOODS_BUTTONS_NUM = 15
local GOODS_BUTTONS = {}
local GOODS_PRICE = {}
local GOODS_NAME = {}
local g_LimitText = {}
local g_CurPage = 1
local maxPage = 1
local g_objCared = -1

--当前商店的商品数量
local	g_nTotalNum		= 0

local g_NewDungeon_DaibiShop_Frame_UnifiedPosition

local g_Limit = {{120, 40, 8}, {1, 1, 1}, {20, 10, 5}}
local limit_array = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}}

local g_CurShopIndex = 1
local g_NpcServerId = -1

local g_Limit_Text = {"#{XDBS_200417_22}", "#{XDBS_200417_20}", "#{XDBS_200417_18}"}
local g_Limit_Tip = {"#{XDBS_200417_23}", "#{XDBS_200417_21}", "#{XDBS_200417_19}"}

local g_QualColor = {"#{XDBS_200417_35}", "#{XDBS_200417_36}", "#{XDBS_200417_37}"}
local g_TabName = {"#{XDBS_200417_7}", "#{XDBS_200417_9}", "#{XDBS_200417_11}"}

local g_TabCtrl = {}

function NewDungeon_DaibiShop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OPEN_SHSHOP", true)
	this:RegisterEvent("UPDATE_BOOTH", false)
	this:RegisterEvent("SHSHOP_LIMIT", false)
	this:RegisterEvent("UPDATE_SHANHAIBI",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function NewDungeon_DaibiShop_OnLoad()

	g_NewDungeon_DaibiShop_Frame_UnifiedPosition = NewDungeon_DaibiShop_Frame:GetProperty("UnifiedPosition")
	
	GOODS_BUTTONS[1] = NewDungeon_DaibiShop_Item1
	GOODS_BUTTONS[2] = NewDungeon_DaibiShop_Item2
	GOODS_BUTTONS[3] = NewDungeon_DaibiShop_Item3
	GOODS_BUTTONS[4] = NewDungeon_DaibiShop_Item4
	GOODS_BUTTONS[5] = NewDungeon_DaibiShop_Item5
	GOODS_BUTTONS[6] = NewDungeon_DaibiShop_Item6
	GOODS_BUTTONS[7] = NewDungeon_DaibiShop_Item7
	GOODS_BUTTONS[8] = NewDungeon_DaibiShop_Item8
	GOODS_BUTTONS[9] = NewDungeon_DaibiShop_Item9
	GOODS_BUTTONS[10]= NewDungeon_DaibiShop_Item10
	GOODS_BUTTONS[11]= NewDungeon_DaibiShop_Item11
	GOODS_BUTTONS[12]= NewDungeon_DaibiShop_Item12
	GOODS_BUTTONS[13]= NewDungeon_DaibiShop_Item13
	GOODS_BUTTONS[14]= NewDungeon_DaibiShop_Item14
	GOODS_BUTTONS[15]= NewDungeon_DaibiShop_Item15
	
	GOODS_NAME[1] =	NewDungeon_DaibiShop_ItemInfo1_Name
	GOODS_NAME[2] =	NewDungeon_DaibiShop_ItemInfo2_Name
	GOODS_NAME[3] =	NewDungeon_DaibiShop_ItemInfo3_Name
	GOODS_NAME[4] =	NewDungeon_DaibiShop_ItemInfo4_Name
	GOODS_NAME[5] =	NewDungeon_DaibiShop_ItemInfo5_Name
	GOODS_NAME[6] =	NewDungeon_DaibiShop_ItemInfo6_Name
	GOODS_NAME[7] =	NewDungeon_DaibiShop_ItemInfo7_Name
	GOODS_NAME[8] =	NewDungeon_DaibiShop_ItemInfo8_Name
	GOODS_NAME[9] =	NewDungeon_DaibiShop_ItemInfo9_Name
	GOODS_NAME[10] =	NewDungeon_DaibiShop_ItemInfo10_Name
	GOODS_NAME[11] =	NewDungeon_DaibiShop_ItemInfo11_Name
	GOODS_NAME[12] =	NewDungeon_DaibiShop_ItemInfo12_Name
	GOODS_NAME[13] =	NewDungeon_DaibiShop_ItemInfo13_Name
	GOODS_NAME[14] =	NewDungeon_DaibiShop_ItemInfo14_Name
	GOODS_NAME[15] =	NewDungeon_DaibiShop_ItemInfo15_Name

	GOODS_PRICE[1] = NewDungeon_DaibiShop_ItemInfo1_Text
	GOODS_PRICE[2] = NewDungeon_DaibiShop_ItemInfo2_Text
	GOODS_PRICE[3] = NewDungeon_DaibiShop_ItemInfo3_Text
	GOODS_PRICE[4] = NewDungeon_DaibiShop_ItemInfo4_Text
	GOODS_PRICE[5] = NewDungeon_DaibiShop_ItemInfo5_Text
	GOODS_PRICE[6] = NewDungeon_DaibiShop_ItemInfo6_Text
	GOODS_PRICE[7] = NewDungeon_DaibiShop_ItemInfo7_Text
	GOODS_PRICE[8] = NewDungeon_DaibiShop_ItemInfo8_Text
	GOODS_PRICE[9] = NewDungeon_DaibiShop_ItemInfo9_Text
	GOODS_PRICE[10]= NewDungeon_DaibiShop_ItemInfo10_Text
	GOODS_PRICE[11]= NewDungeon_DaibiShop_ItemInfo11_Text
	GOODS_PRICE[12]= NewDungeon_DaibiShop_ItemInfo12_Text
	GOODS_PRICE[13]= NewDungeon_DaibiShop_ItemInfo13_Text
	GOODS_PRICE[14]= NewDungeon_DaibiShop_ItemInfo14_Text
	GOODS_PRICE[15]= NewDungeon_DaibiShop_ItemInfo15_Text
	
	g_TabCtrl[1] = NewDungeon_DaibiShop_FenYe_CardFragment
	g_TabCtrl[2] = NewDungeon_DaibiShop_FenYe_Skill
	g_TabCtrl[3] = NewDungeon_DaibiShop_FenYe_RelationItem
	g_TabCtrl[4] = NewDungeon_DaibiShop_FenYe_MenpaiCloth
	
	g_LimitText[1] = NewDungeon_DaibiShop_Text2
	g_LimitText[2] = NewDungeon_DaibiShop_Text3
	g_LimitText[3] = NewDungeon_DaibiShop_Text4	
end

function NewDungeon_DaibiShop_OnEvent(event)
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end	

	if event == "UI_COMMAND" and tonumber(arg0) == 88866601 then
		if not this:IsVisible() then
			g_NpcServerId = Get_XParam_INT(0)
			NewDungeon_DaibiShop_Show()			
		end	
	end
	
	
	if event == "OPEN_SHSHOP" then
	
		local nMult = NpcShop:GetShopType("buymult")
		if nMult <= 0 then		
		else
		end
		
		g_NpcServerId = tonumber(arg0)
		
		local nUnit = NpcShop:GetShopType("unit")		

		g_nTotalNum	= 0
		this:Show()
		
		NewDungeon_DaibiShop_UpdateTab()
		
		OpenBooth()

		--关心商人Obj
		g_objCared = NpcShop:GetNpcId()
		if tonumber(g_objCared) ~= nil then
			this:CareObject(tonumber(g_objCared), 1)
		end
		
		NpcShop:CloseConfirm()
		NewDungeon_DaibiShop_ChangeShowTab(g_CurShopIndex)
		g_CurPage = 1
		NewDungeon_DaibiShop_UpdatePage()
		
		SetDefaultMouse()

	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewDungeon_DaibiShop_Frame_On_ResetPos()
	end
	
	if event == "SHSHOP_LIMIT" then
		if g_CurShopIndex >= 1 and g_CurShopIndex <= 3 then	
			limit_array[1][1], limit_array[1][2], limit_array[1][3], limit_array[2][1], limit_array[2][2], limit_array[2][3], limit_array[3][1], limit_array[3][2], limit_array[3][3] = Player:GetData("SHShopLimit")
		
			for i = 1, 3 do
				strTemp = ScriptGlobal_Format(g_Limit_Text[i], tostring(g_Limit[g_CurShopIndex][i] - limit_array[g_CurShopIndex][i]), tostring(g_Limit[g_CurShopIndex][i]))
				g_LimitText[i]:SetText(strTemp)
				strTemp = ScriptGlobal_Format(g_Limit_Tip[i], tostring(g_Limit[g_CurShopIndex][i] - limit_array[g_CurShopIndex][i]))
				g_LimitText[i]:SetToolTip(strTemp)
			end
		end	
	end
	
	if event == "UPDATE_SHANHAIBI" then
		local haveTokens = Player:GetData("SHANHAIBI")
		local strTemp = ScriptGlobal_Format("#{XDBS_200417_17}" , tostring(haveTokens))
		NewDungeon_DaibiShop_Text1:SetText(strTemp)
	end
end

function NewDungeon_DaibiShop_Show()
	g_CurShopIndex = 1
	NewDungeon_DaibiShop_UpdateShopItem()
end

function NewDungeon_DaibiShop_UpdatePage()

	if IsWindowShow("NewDungeon_DaibiShop_MBuy") then
		CloseWindow("NewDungeon_DaibiShop_MBuy", true)
	end
	
	local nUnit = NpcShop:GetShopType("unit")

	local	i = 1
	if g_nTotalNum == 0 or g_nTotalNum ~= GetActionNum("boothitem") then
		g_nTotalNum	= GetActionNum("boothitem")
	end

	-- 计算总页数
	local	nTotalPage
	if g_nTotalNum < 1 then
		nTotalPage	= 1
	else
		nTotalPage	= math.floor((g_nTotalNum - 1)/GOODS_BUTTONS_NUM) + 1
	end

	maxPage = nTotalPage

	if g_CurPage < 1 or g_CurPage > nTotalPage then
		g_CurPage = 1
	end

	local nStartIndex = (g_CurPage - 1) * GOODS_BUTTONS_NUM
	i = 1

	for i = 1, GOODS_BUTTONS_NUM do

		local theAction = EnumAction(nStartIndex + i - 1, "boothitem")
		if theAction:GetID() ~= 0 then

			GOODS_BUTTONS[i]:SetActionItem(theAction:GetID())
			
			if theAction:GetItemColorInShop()~="" then
			--	GOODS_NAME[i]:SetText(theAction:GetItemColorInShop()..theAction:GetName())
			else
			--	GOODS_NAME[i]:SetText(theAction:GetName())
			end
			
			local strName = ScriptGlobal_Format("#{XDBS_200417_15}" ,theAction:GetName())
			GOODS_NAME[i]:SetText(strName)
			
			local nPrice = NpcShop:EnumItemPrice(nStartIndex + i - 1)
			local strPrice = ScriptGlobal_Format("#{XDBS_200417_16}" , tostring(nPrice))	
			GOODS_PRICE[i]:SetText(tostring(strPrice))
			
		else
			GOODS_NAME[i]:SetText("")
			GOODS_PRICE[i]:SetText("")
			GOODS_BUTTONS[i]:SetActionItem(-1)
		end
	end

	local strTemp = ""
	
	local haveTokens = Player:GetData("SHANHAIBI")
	strTemp = ScriptGlobal_Format("#{XDBS_200417_17}" , tostring(haveTokens))
	NewDungeon_DaibiShop_Text1:SetText(strTemp)
	
	if g_CurShopIndex >= 1 and g_CurShopIndex <= 3 then
	
		limit_array[1][1], limit_array[1][2], limit_array[1][3], limit_array[2][1], limit_array[2][2], limit_array[2][3], limit_array[3][1], limit_array[3][2], limit_array[3][3] = Player:GetData("SHShopLimit")
		for i = 1, 3 do
			g_LimitText[i]:Show()
			strTemp = ScriptGlobal_Format(g_Limit_Text[i], tostring(g_Limit[g_CurShopIndex][i] - limit_array[g_CurShopIndex][i]), tostring(g_Limit[g_CurShopIndex][i]))
			g_LimitText[i]:SetText(strTemp)
			strTemp = ScriptGlobal_Format(g_Limit_Tip[i], tostring(g_Limit[g_CurShopIndex][i] - limit_array[g_CurShopIndex][i]))
			g_LimitText[i]:SetToolTip(strTemp)
		end
	else
		for i = 1, 3 do
			g_LimitText[i]:Hide()
		end
	end
	
	if g_CurShopIndex == 1 then
		NewDungeon_DaibiShop_DuiHuan:Show()
	else
		NewDungeon_DaibiShop_DuiHuan:Hide()
	end
	
	if nTotalPage == 1 then
		NewDungeon_DaibiShop_UpPage:Hide()
		NewDungeon_DaibiShop_DownPage:Hide()
		NewDungeon_DaibiShop_CurrentlyPage:Hide()
	else
		NewDungeon_DaibiShop_UpPage:Show()
		NewDungeon_DaibiShop_DownPage:Show()
		NewDungeon_DaibiShop_CurrentlyPage:Show()

		NewDungeon_DaibiShop_UpPage:Enable()
		NewDungeon_DaibiShop_DownPage:Enable()

		if g_CurPage == nTotalPage then
			NewDungeon_DaibiShop_DownPage:Disable()
		end

		if g_CurPage == 1 then
			NewDungeon_DaibiShop_UpPage:Disable()
		end

		NewDungeon_DaibiShop_CurrentlyPage:SetText(tostring(g_CurPage) .. "/" .. tostring(nTotalPage) );
	end
end

function NewDungeon_DaibiShop_GoodButton_Clicked(nIndex)
	
	if nIndex < 1 or nIndex > GOODS_BUTTONS_NUM then
		return
	end
	
	local item_table_index = NpcShop:EnumItemID((g_CurPage - 1) * GOODS_BUTTONS_NUM + nIndex - 1)
	if item_table_index < 0 then
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
	
	if g_CurShopIndex >= 1 and g_CurShopIndex <= 3 then

		local item_qual = LuaFnGetSHShopItemQual(item_table_index, g_CurShopIndex - 1)
	
		if item_qual >= 0 and item_qual < 3 then
			if limit_array[g_CurShopIndex][item_qual + 1] >= g_Limit[g_CurShopIndex][item_qual + 1] then
				local strTemp = ScriptGlobal_Format("#{XDBS_200417_25}", g_TabName[g_CurShopIndex],g_QualColor[item_qual + 1])
				PushDebugMessage(strTemp)
				return		
			end		
		end
	end
	
	GOODS_BUTTONS[nIndex]:DoAction()

end

function NewDungeon_DaibiShop_HelpClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenSHShopHelp")
		Set_XSCRIPT_ScriptID(888666)
		Set_XSCRIPT_Parameter(0,g_NpcServerId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function NewDungeon_DaibiShop_PageUp()
	
	if g_CurPage <= 1 then
		return
	end
	
	g_CurPage = g_CurPage - 1
	NpcShop:CloseConfirm()
	NewDungeon_DaibiShop_UpdatePage()
end

function NewDungeon_DaibiShop_PageDown()

	if g_CurPage >= maxPage then
		return
	end
	
	g_CurPage = g_CurPage + 1
	
	NpcShop:CloseConfirm()
	NewDungeon_DaibiShop_UpdatePage()
end

function NewDungeon_DaibiShop_CloseClicked()
	this:Hide()
end

function NewDungeon_DaibiShop_OnHidden()
	for i = 1, GOODS_BUTTONS_NUM do
		GOODS_BUTTONS[i]:SetActionItem(-1)
	end
	
	SetDefaultMouse()
	this:CareObject(g_objCared, 0)
	NpcShop:CloseConfirm()
	
	if IsWindowShow("NewDungeon_DaibiShop_MBuy") then
		CloseWindow("NewDungeon_DaibiShop_MBuy", true)
	end
end

function NewDungeon_DaibiShop_ChangeShowTab(shopIndex)
	if g_CurShopIndex == shopIndex then
		return
	end
	g_CurShopIndex = shopIndex
	NewDungeon_DaibiShop_UpdateShopItem()
end

function NewDungeon_DaibiShop_UpdateShopItem()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenSHShop")
		Set_XSCRIPT_ScriptID(888666)
		Set_XSCRIPT_Parameter(0,g_NpcServerId)
		Set_XSCRIPT_Parameter(1,g_CurShopIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	NpcShop:CloseConfirm()
end

function NewDungeon_DaibiShop_MBuy()
	PrepearBuyMult()
end

function NewDungeon_DaibiShop_UpdateTab()
	for i = 1, 4 do
		g_TabCtrl[i]:SetCheck(0)
	end	
	g_TabCtrl[g_CurShopIndex]:SetCheck(1)
end

function NewDungeon_DaibiShop_Frame_On_ResetPos()
	NewDungeon_DaibiShop_Frame:SetProperty("UnifiedPosition", g_NewDungeon_DaibiShop_Frame_UnifiedPosition)
end

--!!!reloadscript =NewDungeon_DaibiShop