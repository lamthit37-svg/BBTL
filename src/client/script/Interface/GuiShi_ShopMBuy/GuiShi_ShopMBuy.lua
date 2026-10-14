local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_NpcId = -1
local g_GoodsIndex = -1
local g_MaxNum = 0

local g_strPrice = {"#{GSHB_190801_65}", "#{GSHB_190801_66}", "#{GSHB_190801_67}", "#{GSHB_190801_68}", "#{GXDJ_200323_59}" }

local g_haveMoney = {}
local g_baseMoney = {}
local g_needMoney = {}

function GuiShi_ShopMBuy_PreLoad()
	this:RegisterEvent("GUISHI_OPENMUTLBUY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("UPDATE_TEMBANK",false)
	this:RegisterEvent("GUISHI_YINPIAO_UPDATE",false)
	this:RegisterEvent("GUISHI_YINLIANG_UPDATE",false)
	this:RegisterEvent("GUISHI_TONGBI_UPDATE",false)
	this:RegisterEvent("GUISHI_MONEY4_UPDATE",false)
	this:RegisterEvent("MONEY_CHANGE_EX", false);
end

function GuiShi_ShopMBuy_OnLoad()
	g_Frame_UnifiedXPosition	= GuiShi_ShopMBuy_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= GuiShi_ShopMBuy_Frame:GetProperty("UnifiedYPosition");
	
	g_haveMoney[1] = GuiShi_ShopMBuy_Cash1
	g_haveMoney[2] = GuiShi_ShopMBuy_Cash2
	
	g_baseMoney[1] = GuiShi_ShopMBuy_ItemPrice1
	g_baseMoney[2] = GuiShi_ShopMBuy_ItemPrice2
	
	g_needMoney[1] = GuiShi_ShopMBuy_Price1
	g_needMoney[2] = GuiShi_ShopMBuy_Price2
end

function GuiShi_ShopMBuy_OnEvent(event)
	if (event == "GUISHI_OPENMUTLBUY") then
		g_GoodsIndex = tonumber(arg0)
		g_NpcId = tonumber(arg1)
		this:CareObject( g_NpcId, 1, "GuiShi_ShopMBuy" )
		this:Show()
		GuiShi_ShopMBuy_OnOpen()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		GuiShi_ShopMBuy_OnClose()
	elseif (event == "ADJEST_UI_POS") then
		GuiShi_ShopMBuy__ResetPos()
	elseif (event == "UPDATE_TEMBANK") then
		GuiShi_ShopMBuy_MaxNum()
		GuiShi_ShopMBuy_TextChanged()
	elseif event == "GUISHI_YINPIAO_UPDATE" then
		GuiShi_ShopMBuy_MaxNum()
		GuiShi_ShopMBuy_TextChanged()
	elseif event == "GUISHI_YINLIANG_UPDATE" then
		GuiShi_ShopMBuy_MaxNum()
		GuiShi_ShopMBuy_TextChanged()
	elseif event == "GUISHI_TONGBI_UPDATE" then
		GuiShi_ShopMBuy_MaxNum()
		GuiShi_ShopMBuy_TextChanged()
	elseif event == "GUISHI_MONEY4_UPDATE" then
		GuiShi_ShopMBuy_MaxNum()
		GuiShi_ShopMBuy_TextChanged()
	elseif event == "MONEY_CHANGE_EX" then
		GuiShi_ShopMBuy_MaxNum()
		GuiShi_ShopMBuy_TextChanged()
	end
end

function GuiShi_ShopMBuy__ResetPos()
	GuiShi_ShopMBuy_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	GuiShi_ShopMBuy_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function GuiShi_ShopMBuy_OnHidden()
	this:CareObject( g_NpcId, 0, "GuiShi_ShopMBuy" )
	GuiShi_ShopMBuy_InputNum:SetProperty("DefaultEditBox", "False");
end

function GuiShi_ShopMBuy_GetPriceTypeList(needType1, needNum1, needType2, needNum2)
	local priceList = {}
	if needNum1 > 0 then
		table.insert(priceList, needType1)
	end
	
	if needNum2 > 0 then
		table.insert(priceList, needType2)
	end
	
	local isHigher = function(a, b)
		return a < b 
	end

	table.sort(priceList, isHigher)
	
	return priceList
end

function GuiShi_ShopMBuy_OnOpen()
	local result, name, isLimited, limitedNum, buyNum, needType1, needNum1, needStep1, needType2, needNum2, needStep2= GuiShiUI:LuaFnGetNPCShopGoodsInfo(g_GoodsIndex)
	if result == 0 then
		return
	end
	
	local itemIndex =  GuiShiUI:LuaFnGetNPCShopGoodsItemIndex(g_GoodsIndex)
	if itemIndex == 0 then
		return 0
	end
	
	local theAction = EnumAction(g_GoodsIndex, "gs_npcshop_goodslist")
	if theAction:GetID() == 0 then
		return
	end
	
	GuiShi_ShopMBuy_ItemLimitNumber:SetText("")
	GuiShi_ShopMBuy_ItemLimitiImage:Hide()
	GuiShi_ShopMBuy_ItemLimitNumberBK:Hide()
	GuiShi_ShopMBuy_ItemIcon:Hide()
	if isLimited > 0 then
		if limitedNum < 0 then
			limitedNum = 0
		end
		
		GuiShi_ShopMBuy_ItemLimitNumber:SetText(tostring(limitedNum))
		GuiShi_ShopMBuy_ItemLimitiImage:Show()
		GuiShi_ShopMBuy_ItemIcon:Show()
		GuiShi_ShopMBuy_ItemLimitNumberBK:Show()
	end
	
	GuiShi_ShopMBuy_Item:SetActionItem(theAction:GetID())
	GuiShi_ShopMBuy_ItemName:SetText(name)
	
	local priceList = GuiShi_ShopMBuy_GetPriceTypeList(needType1, needNum1, needType2, needNum2)
	local basePrice = {[needType1] = needNum1,  [needType2] = needNum2}
	local havePrice = {GuiShiUI:LuaFnGetGuiShiYinPiao(), GuiShiUI:LuaFnGetGuiShiYinLiang(), GuiShiUI:LuaFnGetGuiShiTongBi(), Player:GetData("MONEY"), GuiShiUI:LuaFnGetGuiShiMoney4() }
	
	for i = 1, 2 do
		g_haveMoney[i]:SetText("")
		g_baseMoney[i]:SetText("")
		g_needMoney[i]:SetText("")
	end
	
	baseMoney = ""
	local l = table.getn(priceList)
	while l >= 1 do
		g_haveMoney[l]:SetText(ScriptGlobal_Format(g_strPrice[priceList[l]], havePrice[priceList[l]]))
		if baseMoney ~= "" then
			baseMoney = baseMoney.."#{GSHB_190801_99}"
		end
		
		baseMoney = baseMoney..ScriptGlobal_Format(g_strPrice[priceList[l]], basePrice[priceList[l]])
		l = l - 1
	end
	
	g_baseMoney[1]:SetText(baseMoney)
	GuiShi_ShopMBuy_MaxNum()
	
	GuiShi_ShopMBuy_InputNum:SetProperty("DefaultEditBox", "True");
	GuiShi_ShopMBuy_InputNum:SetText(tostring(1))
	GuiShi_ShopMBuy_InputNum:SetSelected( 0, -1 );
end

function GuiShi_ShopMBuy_MaxNum()
	local result, name, isLimited, limitedNum, buyNum, needType1, needNum1, needStep1, needType2, needNum2, needStep2, isInTemBank= GuiShiUI:LuaFnGetNPCShopGoodsInfo(g_GoodsIndex)
	if result == 0 then
		return
	end
	
	local itemIndex =  GuiShiUI:LuaFnGetNPCShopGoodsItemIndex(g_GoodsIndex)
	if itemIndex == 0 then
		return
	end
	
	local havePrice = {GuiShiUI:LuaFnGetGuiShiYinPiao(), GuiShiUI:LuaFnGetGuiShiYinLiang(), GuiShiUI:LuaFnGetGuiShiTongBi(), Player:GetData("MONEY"), GuiShiUI:LuaFnGetGuiShiMoney4() }
	
	local bagSpace = 0
	if isInTemBank > 0 then
		bagSpace = Bank:GetTemBankSpace()
	else
		bagSpace = GetBagSpace(itemIndex)
	end
	
	local layerNum = GuiShiUI:LuaFnGetNPCShopGoodsLayerNum(itemIndex)
	
	local layerMaxNum = bagSpace * layerNum
	
	local numList = {}
	table.insert(numList, layerMaxNum) 
	
	if isLimited > 0 then
		table.insert(numList, limitedNum)
	end 
	
	if needNum1 > 0 then
		if needStep1 > 0 then
			table.insert(numList, GuiShi_ShopMBuy_getNum(havePrice[needType1], needNum1, needStep1, buyNum))
		else
			table.insert(numList, math.floor(havePrice[needType1] / needNum1))
		end
	end
	
	if needNum2 > 0 then
		if needStep2 > 0 then
			table.insert(numList, GuiShi_ShopMBuy_getNum(havePrice[needType2], needNum2, needStep2, buyNum))
		else
			table.insert(numList, math.floor(havePrice[needType2] / needNum2))
		end
	end
	
	g_MaxNum = numList[1]
	for i = 1, table.getn(numList) do
		if g_MaxNum > numList[i] then
			g_MaxNum = numList[i]
		end
	end
	
	if g_MaxNum < 1 then
		g_MaxNum = 1
	end
	
	if g_MaxNum > 999 then
		g_MaxNum = 999
	end
end

function GuiShi_ShopMBuy_getNum(totoal, base, step, buyNum)
	local a = step / 2
	local b = (base + buyNum * step - step / 2)
	local c = -totoal
	
	local result =  math.floor((-b + math.sqrt(b*b - 4*a*c)) / (2*a))
	if result < 0 then
		result = 0
	end
	return result
end

function GuiShi_ShopMBuy_getPrice(base, buyedNum, buyNum, step)
	local price = base * buyNum + math.ceil((buyedNum*step + (buyNum + buyedNum - 1) * step) * buyNum / 2)
	if price < 0 then
		price = 0
	end
	
	return price
end

function GuiShi_ShopMBuy_TextChanged()
	local num = tonumber(GuiShi_ShopMBuy_InputNum:GetText())
	if num == nil then
		return
	end
	
	if num > g_MaxNum then
		GuiShi_ShopMBuy_InputNum:SetText(tostring(g_MaxNum))
		
	elseif num < 1 then
		GuiShi_ShopMBuy_InputNum:SetText(tostring("1"))
		
	else
		if num == 0 then
			for i = 1, 2 do
				g_needMoney[i]:SetText("")
			end
		else
			local result, name, isLimited, limitedNum, buyNum, needType1, needNum1, needStep1, needType2, needNum2, needStep2= GuiShiUI:LuaFnGetNPCShopGoodsInfo(g_GoodsIndex)
			if result == 0 then
				return
			end
			
			local priceList = GuiShi_ShopMBuy_GetPriceTypeList(needType1, needNum1, needType2, needNum2)
			local basePrice = {[needType1] = {needNum1, needStep1} ,  [needType2] = {needNum2,needStep2}}
			local havePrice = {GuiShiUI:LuaFnGetGuiShiYinPiao(), GuiShiUI:LuaFnGetGuiShiYinLiang(), GuiShiUI:LuaFnGetGuiShiTongBi(), Player:GetData("MONEY"), GuiShiUI:LuaFnGetGuiShiMoney4() }
			
			for i = 1, table.getn(priceList) do
				local step = basePrice[priceList[i]][2]
				if num > 1 then
					if isLimited > 0 and step > 0 then
						basePrice[priceList[i]][1] = GuiShi_ShopMBuy_getPrice(basePrice[priceList[i]][1], buyNum, num, step)
					else
						basePrice[priceList[i]][1] = basePrice[priceList[i]][1] * num
					end
				else
					if isLimited > 0 and step > 0 then
						basePrice[priceList[i]][1] = basePrice[priceList[i]][1] + step * buyNum
					end
				end
				
				g_needMoney[i]:SetText(ScriptGlobal_Format(g_strPrice[priceList[i]], basePrice[priceList[i]][1]))
				local msg = ScriptGlobal_Format(g_strPrice[priceList[i]], havePrice[priceList[i]])
				if havePrice[priceList[i]] < basePrice[priceList[i]][1] then
					g_haveMoney[i]:SetText("#cff0000"..msg)
				else
					g_haveMoney[i]:SetText("#G"..msg)
				end
			end
		end
	end
end

function GuiShi_ShopMBuy_OnClose()
	this:Hide()
end

function GuiShi_ShopMBuy_OnOK()
	local num = tonumber(GuiShi_ShopMBuy_InputNum:GetText());
	if num == nil then
		return
	end
	local goodsId = GuiShiUI:LuaFnGetNPCShopGoodsId(g_GoodsIndex)
	if goodsId == -1 then
		return
	end
	 
	if num > 0 and num ~= nil then
		PushEvent("GUISHI_ONBUY", tostring(g_GoodsIndex), tostring(goodsId), tostring(0), GuiShi_ShopMBuy_InputNum:GetText(), tostring(0))
	else
		PushDebugMessage("#{FFSDGZ_120615_47}")
	end
end

function GuiShi_ShopMBuy_OnMax()
	GuiShi_ShopMBuy_InputNum:SetText(g_MaxNum)
end