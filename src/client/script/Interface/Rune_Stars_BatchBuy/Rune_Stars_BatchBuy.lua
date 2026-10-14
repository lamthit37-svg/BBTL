local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_NpcId = -1
local g_GoodsIndex = -1
local g_MaxNum = 0

local moneyTypeStr = { [1] = {"#{XZJC_200309_190}", "#{XZJC_200309_200}", "#{XZJC_200309_203}", },
											 [2] = {"#{XZJC_200309_189}", "#{XZJC_200309_199}", "#{XZJC_200309_202}",},
											 [3] = {"#{XZJC_200309_244}", "#{XZJC_200309_246}", "#{XZJC_200309_248}"},
											 [4] = {"#{XZJC_200309_243}", "#{XZJC_200309_245}", "#{XZJC_200309_247}"}}

function Rune_Stars_BatchBuy_PreLoad()
	this:RegisterEvent("XZ_OPENMUTLBUY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("XINGJUAN_CHIPDRE",false)
	this:RegisterEvent("XINGJUAN_CHIPESS", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Rune_Stars_BatchBuy_OnLoad()
	g_Frame_UnifiedXPosition	= Rune_Stars_BatchBuy_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= Rune_Stars_BatchBuy_Frame:GetProperty("UnifiedYPosition")
end

function Rune_Stars_BatchBuy_OnEvent(event)
	if (event == "XZ_OPENMUTLBUY") then
		g_GoodsIndex = tonumber(arg0)
		g_NpcId = tonumber(arg1)
		this:CareObject( g_NpcId, 1, "Rune_Stars_BatchBuy" )
		this:Show()
		Rune_Stars_BatchBuy_OnOpen()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Rune_Stars_BatchBuy_OnClose()
		
	elseif (event == "ADJEST_UI_POS") then
		Rune_Stars_BatchBuy_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Rune_Stars_BatchBuy_ResetPos()
		
	elseif (event == "XINGJUAN_CHIPDRE") then
		Rune_Stars_BatchBuy_MaxNum()
		Rune_Stars_BatchBuy_TextChanged()

	elseif event == "XINGJUAN_CHIPESS" then
		Rune_Stars_BatchBuy_MaxNum()
		Rune_Stars_BatchBuy_TextChanged()

	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		Rune_Stars_BatchBuy_MaxNum()
		Rune_Stars_BatchBuy_TextChanged()
	end
end

function Rune_Stars_BatchBuy_ResetPos()
	Rune_Stars_BatchBuy_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Rune_Stars_BatchBuy_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Rune_Stars_BatchBuy_OnHidden()
	this:CareObject( g_NpcId, 0, "Rune_Stars_BatchBuy" )
	Rune_Stars_BatchBuy_NumberInput:SetProperty("DefaultEditBox", "False");
end

function Rune_Stars_BatchBuy_OnOpen()
	local result, realIndex, itemId, name, limitType, lastNum, moneyType, moneyNum, needFubenLayerNum = DataPool:LuaFnGetXZNPCShopGoodsInfo(g_GoodsIndex)
	if result == 0 then
		return
	end
	
	local theAction = EnumAction(g_GoodsIndex, "xz_npcshop_goodslist")
	if theAction:GetID() == 0 then
		return
	end
	
	Rune_Stars_BatchBuyBtnNumber:SetText("")
	Rune_Stars_BatchBuyBtnNumberBK:Hide()
	Rune_Stars_BatchBuy_ItemLimitiImage:Hide()
	
	if limitType > 0 then
		if lastNum < 0 then
			lastNum = 0
		end
		
		Rune_Stars_BatchBuyBtnNumber:SetText(tostring(lastNum))
		Rune_Stars_BatchBuyBtnNumberBK:Show()
		Rune_Stars_BatchBuy_ItemLimitiImage:Show()
		if limitType == 1 then
			Rune_Stars_BatchBuy_ItemLimitiImage:SetProperty("Image", "set:Rune_Star01 image:zhouxian")
		elseif limitType == 2 then
			Rune_Stars_BatchBuy_ItemLimitiImage:SetProperty("Image", "set:Rune_Star01 image:yongxian")
		else
			Rune_Stars_BatchBuy_ItemLimitiImage:SetProperty("Image", "set:Rune_Star01 image:rixian")
		end
	end
	
	Rune_Stars_BatchBuy_Item:SetActionItem(theAction:GetID())
	Rune_Stars_BatchBuy_ItemName:SetText("#L"..name)
	Rune_Stars_BatchBuy_ItemPrice:SetText(ScriptGlobal_Format(moneyTypeStr[moneyType][1], tostring(moneyNum)))
	
	Rune_Stars_BatchBuy_TextNeed:SetText(moneyTypeStr[moneyType][2])
	Rune_Stars_BatchBuy_TextHave:SetText(moneyTypeStr[moneyType][3])


	Rune_Stars_BatchBuy_MaxNum()	
	Rune_Stars_BatchBuy_NumberInput:SetProperty("DefaultEditBox", "True");
	Rune_Stars_BatchBuy_NumberInput:SetText(tostring(1))
	Rune_Stars_BatchBuy_NumberInput:SetSelected( 0, -1 );
end

function Rune_Stars_BatchBuy_haveMoney(moneyType)
	if moneyType == 1 then
		return Player:GetData("XJCHIPDRE")
		
	elseif moneyType == 2 then
		return Player:GetData("XJCHIPESS")
		
	elseif moneyType == 3 then
		return Player:GetData("XJSKILLCARDDRE")
		
	elseif moneyType == 4 then
		return Player:GetData("XJSKILLCARDESS")
	end
		
	return 0
end

function Rune_Stars_BatchBuy_MaxNum()
	local result, realIndex, itemIndex, name, limitType, lastNum, moneyType, moneyNum, needFubenLayerNum = DataPool:LuaFnGetXZNPCShopGoodsInfo(g_GoodsIndex)
	if result == 0 then
		return
	end
	
	local bagSpace = GetBagSpace(itemIndex)
	local layerNum = GuiShiUI:LuaFnGetNPCShopGoodsLayerNum(itemIndex)
	
	local layerMaxNum = bagSpace * layerNum
	
	local numList = {}
	table.insert(numList, layerMaxNum) 
	
	if limitType > 0 then
		table.insert(numList, lastNum)
	end 
	
	table.insert(numList, math.floor(Rune_Stars_BatchBuy_haveMoney(moneyType) / moneyNum))
	
	
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

function Rune_Stars_BatchBuy_TextChanged()
	local num = tonumber(Rune_Stars_BatchBuy_NumberInput:GetText())
	if num == nil then
		return
	end
	
	if num > g_MaxNum then
		Rune_Stars_BatchBuy_NumberInput:SetText(tostring(g_MaxNum))
		
	elseif num < 1 then
		Rune_Stars_BatchBuy_NumberInput:SetText("1")
		
	else
		local result, realIndex, itemIndex, name, limitType, lastNum, moneyType, moneyNum, needFubenLayerNum = DataPool:LuaFnGetXZNPCShopGoodsInfo(g_GoodsIndex)
		if result == 0 then
			return
		end
		
		local totalNum = num * moneyNum
		Rune_Stars_BatchBuy_TextNeedNum:SetText("#L"..tostring(totalNum))
		
		local haveNum = Rune_Stars_BatchBuy_haveMoney(moneyType)
		if haveNum < totalNum then
			Rune_Stars_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{XZJC_200309_204}", tostring(haveNum)))
		else
			Rune_Stars_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{XZJC_200309_205}", tostring(haveNum)))
		end
	end
end

function Rune_Stars_BatchBuy_OnMax()
	Rune_Stars_BatchBuy_NumberInput:SetText(g_MaxNum)
end

function Rune_Stars_BatchBuy_OnClose()
	this:Hide()
end


function Rune_Stars_BatchBuy_OnOK()
	local num = tonumber(Rune_Stars_BatchBuy_NumberInput:GetText());
	if num == nil then
		return
	end
	local goodsId = DataPool:LuaFnGetXZNPCShopGoodsId(g_GoodsIndex)
	if goodsId == -1 then
		return
	end
	 
	if num > 0 and num ~= nil then
		PushEvent("XZ_ONBUY", tostring(g_GoodsIndex), tostring(goodsId), "0", Rune_Stars_BatchBuy_NumberInput:GetText(), "0")
	end
end