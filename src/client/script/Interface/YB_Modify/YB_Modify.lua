
local g_Cur_Modify_Type = 0
local g_Index	= -1
local g_Old_Price	= 0
--local g_itemNum = 1

local YbMarketSale_IsInT = 0 --是否为T交易市场

function YB_Modify_PreLoad()
	this : RegisterEvent("OPEN_CHANGE_PRICE")
	this : RegisterEvent("OPEN_TAUCTION_CHANGE_PRICE")
end


function YB_Modify_OnLoad()

end


function YB_Modify_OnEvent(event)
	if event == "OPEN_CHANGE_PRICE"  then
		g_Cur_Modify_Type = tonumber(arg0)
		g_Index	= tonumber(arg1)
		g_Old_Price	= 0
		if g_Cur_Modify_Type == 1 then
			local pName ,nowStatus , price = Auction:GetMySellBoxPetAuctionInfo(g_Index)
			if nowStatus ~= nil and price ~= nil then
				g_Old_Price = price
			end
		--	g_itemNum = 1
		elseif g_Cur_Modify_Type == 2 then
			local pName ,nowStatus , price = Auction:GetMySellBoxItemAuctionInfo(g_Index)
			if nowStatus ~= nil and price ~= nil then
				g_Old_Price = price
			end
		--	g_itemNum = Auction:GetMySellBoxItemNum(g_Index)
		end
		YB_Modify_Edit:SetText("")
		YB_Modify_Accept:Disable()

		YbMarketSale_IsInT = 0
		YB_Modify_InitControl()
		this:Show()

	elseif event == "OPEN_TAUCTION_CHANGE_PRICE" then
		YbMarketSale_IsInT = 1
		g_Cur_Modify_Type = tonumber(arg0)
		g_Index	= tonumber(arg1)

		g_Old_Price	= 0
		local pName ,nowStatus , price = TAuction:GetMySellBoxItemAuctionInfo(g_Cur_Modify_Type, g_Index)
		if nowStatus ~= nil and price ~= nil then
			g_Old_Price = price
		end

		if g_Cur_Modify_Type == 1 then
			YB_Modify_Edit:SetText("")
		elseif g_Cur_Modify_Type == 2 then
			YB_Modify_Gold:SetText("0")
			YB_Modify_Silver:SetText("0")
			YB_Modify_CopperCoin:SetText("0")
			YB_Modify_Gold:SetSelected(0,-1)
			YB_Modify_Gold:SetProperty("DefaultEditBox", "True")
		end

		YB_Modify_Accept:Disable()
		YB_Modify_InitControl()
		this:Show()

	end
end

function YB_Modify_Edit_Change()
	local price = YB_Modify_Edit:GetText()
	if price ~= "" and tonumber(price) > 0 then
		local newNeedMoney = Auction:GetNeedMoneyForSell(tonumber(price))
		local oldNeedMoney = Auction:GetNeedMoneyForSell(tonumber(g_Old_Price))

		if newNeedMoney > oldNeedMoney then
			YB_Modify_Money:SetProperty("MoneyNumber", tostring(newNeedMoney - oldNeedMoney));
		else
			YB_Modify_Money:SetProperty("MoneyNumber", "0");
		end
		YB_Modify_Accept:Enable()
	else
		YB_Modify_Money:SetProperty("MoneyNumber", "0");
		YB_Modify_Accept:Disable()
	end

end

function YB_Modify_ChangeMoney()
	if YbMarketSale_IsInT ~= 0 and g_Cur_Modify_Type == 2 then
		local price = YB_Modify_Accept_GetPrice()
		if price ~= "" and tonumber(price) > 0 then
			local newNeedMoney = TAuction:GetNeedMoneyForSell(tonumber(price), g_Cur_Modify_Type)
			local oldNeedMoney = TAuction:GetNeedMoneyForSell(tonumber(g_Old_Price), g_Cur_Modify_Type)

			if newNeedMoney > oldNeedMoney then
				YB_Modify_Money:SetProperty("MoneyNumber", tostring(newNeedMoney - oldNeedMoney));
			else
				YB_Modify_Money:SetProperty("MoneyNumber", "0");
			end
			YB_Modify_Accept:Enable()
		else
			YB_Modify_Money:SetProperty("MoneyNumber", "0");
			YB_Modify_Accept:Disable()
		end
	end
end

function YB_Modify_Cancel_Clicked()
	YB_Modify_Clear()
	this:Hide()
end

function YB_Modify_Accept_Clicked()
	local price = YB_Modify_Accept_GetPrice()
	if price ~= "" and tonumber(price) > 0 then
		--安全时间
		if tonumber(DataPool:GetLeftProtectTime()) > 0 then
			PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
			return
		end

		if YbMarketSale_IsInT == 0 then
			if tonumber(price) > 200000 then
				PushDebugMessage("#{YBSC_100111_54}")
				return
			end
			if tonumber(price) < 2 then
				PushDebugMessage("#{YBSC_100111_53}")
				return
			end
			local newNeedMoney = Auction:GetNeedMoneyForSell(tonumber(price))
			local oldNeedMoney = Auction:GetNeedMoneyForSell(tonumber(g_Old_Price))
			local myMoney = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
			local needMoney = 0
			if newNeedMoney > oldNeedMoney then
				needMoney = newNeedMoney - oldNeedMoney
			end
			if myMoney < needMoney then
				PushDebugMessage("#{YBSC_100111_30}")
			else
				local wantguidh = 0
				local wantguidl = 0
				if g_Cur_Modify_Type == 1 then
					wantguidh, wantguidl = Auction:GetMyAuctionSellBoxPetGuid(g_Index)
				elseif g_Cur_Modify_Type == 2 then
					wantguidh, wantguidl = Auction:GetMyAuctionSellBoxItemGuid(g_Index)
				end

				Auction:ChangePrice(g_Cur_Modify_Type ,g_Index , tonumber(price), wantguidh, wantguidl)
				this:Hide()
			end
		else
			if g_Cur_Modify_Type == 1 then --元宝
				if tonumber(price) > 200000 then
					PushDebugMessage("#{YBSC_100111_54}")
					return
				end
				if tonumber(price) < 2 then
					PushDebugMessage("#{YBSC_100111_53}")
					return
				end
			elseif g_Cur_Modify_Type == 2 then --金币
				if tonumber(price) > 20000*5000 then
					PushDebugMessage("#{KVKGZ_110620_100}")
					return
				end
				if tonumber(price) < 10000 then
					PushDebugMessage("#{KVKGZ_110620_101}")
					return
				end
			else
				PushDebugMessage("Error!")
				return
			end

			local newNeedMoney = TAuction:GetNeedMoneyForSell(tonumber(price), g_Cur_Modify_Type)
			local oldNeedMoney = TAuction:GetNeedMoneyForSell(tonumber(g_Old_Price), g_Cur_Modify_Type)
			local myMoney = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
			local needMoney = 0
			if newNeedMoney > oldNeedMoney then
				needMoney = newNeedMoney - oldNeedMoney
			end
			if myMoney < needMoney then
				PushDebugMessage("#{YBSC_100111_30}")
			else
				TAuction:ChangePrice(g_Cur_Modify_Type ,g_Index , tonumber(price) )
				this:Hide()
			end
		end

	else
		PushDebugMessage("请输入正确的价格")
	end
end

function YB_Modify_Clear()
	g_Cur_Modify_Type = 0
	g_Index	= -1
	g_Old_Price	= 0
--	g_itemNum = 1
	YB_Modify_Edit:SetText("")
	YB_Modify_Accept:Disable()

	YB_Modify_Gold:SetText("0")
	YB_Modify_Silver:SetText("0")
	YB_Modify_CopperCoin:SetText("0")
	YB_Modify_Gold:SetProperty("DefaultEditBox", "False")
end

function YB_Modify_InitControl()
	if YbMarketSale_IsInT ~= 0 and g_Cur_Modify_Type == 2 then --大世界金币交易
		YB_Modify_Explain5:Show()
		YB_Modify_Gold:Show()
		YB_Modify_Gold_Icon:Show()
		YB_Modify_Silver:Show()
		YB_Modify_Silver_Icon:Show()
		YB_Modify_CopperCoin:Show()
		YB_Modify_CopperCoin_Icon:Show()
		YB_Modify_Explain1:Hide()
		YB_Modify_Explain2:Hide()
		YB_Modify_Edit:Hide()
	else
		YB_Modify_Explain5:Hide()
		YB_Modify_Gold:Hide()
		YB_Modify_Gold_Icon:Hide()
		YB_Modify_Silver:Hide()
		YB_Modify_Silver_Icon:Hide()
		YB_Modify_CopperCoin:Hide()
		YB_Modify_CopperCoin_Icon:Hide()
		YB_Modify_Explain1:Show()
		YB_Modify_Explain2:Show()
		YB_Modify_Edit:Show()
	end
end

function YB_Modify_Accept_GetPrice()
	if YbMarketSale_IsInT ~= 0 and g_Cur_Modify_Type == 2 then --大世界金币交易
		local gold = YB_Modify_Gold:GetText()
		local silver = YB_Modify_Silver:GetText()
		local copper = YB_Modify_CopperCoin:GetText()
		local bAvailability, price = Bank:GetInputMoney(gold,silver,copper)
		if bAvailability ~= true then
			return -1
		end
		return price
	else
		return YB_Modify_Edit:GetText()
	end
end
