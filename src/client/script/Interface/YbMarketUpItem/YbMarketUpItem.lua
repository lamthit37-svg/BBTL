local m_Item_Idx = -1
local YbMarketUpItem_IsInT = 0
local YbMarketUpItem_IsMoneyTrade = 0

-----------------------------------------------------------------------
-- OnGameEvent
-----------------------------------------------------------------------

function YbMarketUpItem_PreLoad()
	this:RegisterEvent("OPEN_UP_ITEM");
	this:RegisterEvent("CLOSE_UP_ITEM");
	this:RegisterEvent("UPDATE_UP_ITEM")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("UP_AUCTION_SUCCEED")

	this:RegisterEvent("UP_TAUCTION_SUCCEED")

end

function YbMarketUpItem_OnLoad()
	
end



function YbMarketUpItem_OnEvent(event)
	if event == "OPEN_UP_ITEM"  then
		if this:IsVisible() then
			return
		end
		YbMarketUpItem_IsInT = tonumber(arg0)
		YbMarketUpItem_IsMoneyTrade = tonumber(arg1)
		YbMarketUpItem_InitControl()

		YbMarketUpItem_Update(-1)
		this:Show()
	elseif event == "UPDATE_UP_ITEM" and this:IsVisible() then
		if arg0 ~= nil then
			YbMarketUpItem_Update( tonumber(arg0) )
		end
	
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		if arg0 ~= nil and tonumber(arg0) == m_Item_Idx then
			YbMarketUpItem_Update(m_Item_Idx)
		end 
	elseif event == "CLOSE_UP_ITEM" and this:IsVisible() then
		this:Hide()
	elseif (event == "UP_AUCTION_SUCCEED" or event == "UP_TAUCTION_SUCCEED") then
		YbMarketUpItem_Moral_Value:SetText("")
		YbMarketUpItem_ClearPrice()
	end
end

----------------------------------------------------------------------
-- on events
-----------------------------------------------------------------------

function YbMarketUpItem_OK_Clicked()
	--local price = YbMarketUpItem_Moral_Value:GetText()
	local price = YbMarketUpItem_GetPrice()
	if m_Item_Idx ~= -1 and price ~= "" and tonumber(price) > 0 then
		--安全时间
		if tonumber(DataPool:GetLeftProtectTime()) > 0 then
			PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
			return
		end
		--小于30级
		if  Player:GetData("LEVEL") < 30 then
			PushDebugMessage("#{YBSC_100111_42}")
			return
		end

		--是贵重物品
		if PlayerPackage:IsProtectGoods(m_Item_Idx) == 1 then
			PushDebugMessage("#{YBSC_100111_07}")
			return
		end
		--绑定了
		local isBind = GetItemBindStatus(m_Item_Idx)
		if isBind ~= nil and isBind == 1 then
			PushDebugMessage("#{YBSC_100111_46}")
			return
		end

		if YbMarketUpItem_IsInT == 0 then -- 元宝商品
			--不是元宝商品
			if  PlayerPackage:IsYubaoTradeItem(m_Item_Idx) ~= 1 then
				PushDebugMessage("#{YBSC_100111_05}")
				return
			end

			--输入价格过高
			if tonumber(price) > 200000 then
				PushDebugMessage("#{YBSC_100111_54}")
				return
			end
			if tonumber(price) < 2 then
				PushDebugMessage("#{YBSC_100111_53}")
				return
			end

		--	local nNum = PlayerPackage:GetBagItemNum(m_Item_Idx)
			local nMoney = Auction:GetNeedMoneyForSell(tonumber(price))
		--	local totalNeedMoney = nMoney * nNum
			local myMoney = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
			if myMoney < nMoney then
				PushDebugMessage("#{YBSC_100111_09}")
				return
			end
			Auction:PacketSend_SellItem(m_Item_Idx , tonumber(price) ,0)
		else

			local markettype = 1

			--是不是能在大世界交易
			local tradetype = PlayerPackage:GetT300ItemTradeType(m_Item_Idx)
			if tradetype == nil or tradetype == 0 then
				PushDebugMessage("#{KVKGZ_110620_12}")
				return
			end

			--天外85级限制
			local level = Player:GetLevel()
			if level < 85 then
				PushDebugMessage("#{TWXZ_171211_01}")
				return 0
			end
			if YbMarketUpItem_IsMoneyTrade == 0 then -- 元宝商品
				if tradetype == 1 then --只能金币交易
					PushDebugMessage("#{YBSC_100111_05}")
					return
				end

				--输入价格过高
				if tonumber(price) > 200000 then
					PushDebugMessage("#{YBSC_100111_54}")
					return
				end
				if tonumber(price) < 2 then
					PushDebugMessage("#{YBSC_100111_53}")
					return
				end

				markettype = 1
			else
				--不是元宝商品
				if tradetype == 2 then --只能元宝交易
					PushDebugMessage("#{KVKGZ_110620_13}")
					return
				end

				--输入价格过高
				if tonumber(price) > 20000*5000 then
					PushDebugMessage("#{KVKGZ_110620_100}")
					return
				end
				if tonumber(price) < 10000 then
					PushDebugMessage("#{KVKGZ_110620_101}")
					return
				end

				markettype = 2
			end

			local nMoney = TAuction:GetNeedMoneyForSell(tonumber(price), markettype)
			local myMoney = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
			if myMoney < nMoney then
				PushDebugMessage("#{YBSC_100111_09}")
				return
			end
			TAuction:PacketSend_SellItem(markettype, m_Item_Idx , tonumber(price) ,0)
		end
	end
end

function YbMarketUpItem_Cancel_Clicked()
	this:Hide()
end


function YbMarketUpItem_Count_Change()
	YbMarketUpItem_Refresh_Bn_and_Money()
end

function YbMarketUpItem_OnHidden()
	YbMarketUpItem_Object:SetActionItem(-1);			
	LifeAbility : Lock_Packet_Item(m_Item_Idx,0);		
	m_Item_Idx = -1;
	YbMarketUpItem_Moral_Value:SetText("")
	YbMarketUpItem_OK:Disable()
	YbMarketUpItem_NeedMoney:SetProperty("MoneyNumber", "0");
	if(IsWindowShow("Packet")) then
		CloseWindow("Packet", true);
	end 
end
-----------------------------------------------------------------------
--private function
-----------------------------------------------------------------------
function YbMarketUpItem_Update(itemIdx)
	
	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if PlayerPackage:IsLock( itemIdx ) == 1 then
			PushDebugMessage("物品已加锁")	--道具已上锁
			return
		end
			
		if m_Item_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Item_Idx,0);
		end

		--增加对物品的判断是否能放上去add by quyan
		if YbMarketUpItem_IsItemValid(itemIdx) ~= 1 then
			return
		end

		YbMarketUpItem_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Item_Idx = itemIdx
	else
		YbMarketUpItem_Object:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(m_Item_Idx,0);		
		m_Item_Idx = -1;
	end
	YbMarketUpItem_Refresh_Bn_and_Money()
end


function YbMarketUpItem_Refresh_Bn_and_Money()
	--local price = YbMarketUpItem_Moral_Value:GetText()
	local price = YbMarketUpItem_GetPrice()
	if m_Item_Idx ~= -1 and price ~= "" and tonumber(price) > 0 then
		YbMarketUpItem_OK:Enable()
	--	local nNum = PlayerPackage:GetBagItemNum(m_Item_Idx)
		if YbMarketUpItem_IsInT == 0 then
			local nMoney = Auction:GetNeedMoneyForSell(tonumber(price))
			YbMarketUpItem_NeedMoney:SetProperty("MoneyNumber", tostring(nMoney));
		else
			if YbMarketUpItem_IsMoneyTrade == 0 then
				local nMoney = TAuction:GetNeedMoneyForSell(tonumber(price), 1)
				YbMarketUpItem_NeedMoney:SetProperty("MoneyNumber", tostring(nMoney))
			else
				local nMoney = TAuction:GetNeedMoneyForSell(tonumber(price), 2)
				YbMarketUpItem_NeedMoney:SetProperty("MoneyNumber", tostring(nMoney))
			end
		end
	else
		YbMarketUpItem_NeedMoney:SetProperty("MoneyNumber", "0");
		YbMarketUpItem_OK:Disable()
	end
end

function YbMarketUpItem_InitControl()
	if 0 == YbMarketUpItem_IsMoneyTrade then --元宝的
		YbMarketUpItem_Info2:Show()
		YbMarketUpItem_Moral_Value:Show()
		YbMarketUpItem_Info3:Show()
		YbMarketUpItem_MoneyInfo:Hide()
		YbMarketUpItem_Gold:Hide()
		YbMarketUpItem_Gold_Icon:Hide()
		YbMarketUpItem_Silver:Hide()
		YbMarketUpItem_Silver_Icon:Hide()
		YbMarketUpItem_CopperCoin:Hide()
		YbMarketUpItem_CopperCoin_Icon:Hide()
	else
		YbMarketUpItem_Info2:Hide()
		YbMarketUpItem_Moral_Value:Hide()
		YbMarketUpItem_Info3:Hide()
		YbMarketUpItem_MoneyInfo:Show()
		YbMarketUpItem_Gold:Show()
		YbMarketUpItem_Gold_Icon:Show()
		YbMarketUpItem_Silver:Show()
		YbMarketUpItem_Silver_Icon:Show()
		YbMarketUpItem_CopperCoin:Show()
		YbMarketUpItem_CopperCoin_Icon:Show()
		YbMarketUpItem_Gold:SetText("0")
		YbMarketUpItem_Silver:SetText("0")
		YbMarketUpItem_CopperCoin:SetText("0")
	end
end

function YbMarketUpItem_GetPrice()
	if YbMarketUpItem_IsMoneyTrade == 0 then --元宝的
		return YbMarketUpItem_Moral_Value:GetText()
	else
		local gold = YbMarketUpItem_Gold:GetText()
		local silver = YbMarketUpItem_Silver:GetText()
		local copper = YbMarketUpItem_CopperCoin:GetText()

		local bAvailability, price = Bank:GetInputMoney(gold,silver,copper)
		if bAvailability == true then
			return price
		end
		return -1
	end
end

function YbMarketUpItem_ClearPrice()
	YbMarketUpItem_Moral_Value:SetText("")
	YbMarketUpItem_Gold:SetText("0")
	YbMarketUpItem_Silver:SetText("0")
	YbMarketUpItem_CopperCoin:SetText("0")
end

function YbMarketUpItem_ChangeMoney()
	YbMarketUpItem_Refresh_Bn_and_Money()
end

function YbMarketUpItem_IsItemValid(itemIdx)
	--是贵重物品
	if PlayerPackage:IsProtectGoods(itemIdx) == 1 then
		PushDebugMessage("#{YBSC_100111_07}")
		return 0
	end

	--绑定了
	local isBind = GetItemBindStatus(itemIdx)
	if isBind ~= nil and isBind == 1 then
		PushDebugMessage("#{YBSC_100111_46}")
		return 0
	end

	if YbMarketUpItem_IsInT == 0 then -- 元宝商品
		--不是元宝商品
		if  PlayerPackage:IsYubaoTradeItem(itemIdx) ~= 1 then
			PushDebugMessage("#{YBSC_100111_05}")
			return 0
		end
	else
		--是不是能在大世界交易
		local tradetype = PlayerPackage:GetT300ItemTradeType(itemIdx)
		if tradetype == nil or tradetype == 0 then
			PushDebugMessage("#{KVKGZ_110620_12}")
			return 0
		end

		if YbMarketUpItem_IsMoneyTrade == 0 then -- 元宝商品
			if tradetype == 1 then --只能金币交易
				PushDebugMessage("#{YBSC_100111_05}")
				return 0
			end
		else
			--不是元宝商品
			if tradetype == 2 then --只能元宝交易
				PushDebugMessage("#{KVKGZ_110620_13}")
				return 0
			end
		end
	end

	return 1
end
