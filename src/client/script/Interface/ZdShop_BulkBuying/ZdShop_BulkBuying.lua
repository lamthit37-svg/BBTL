local g_ItemMax = 0;
local g_ItemIdx = -1;

local ARR_PRICE = {};

local CU_ZENGDIAN			= 6	-- 赠点

function ZdShop_BulkBuying_PreLoad()
	this:RegisterEvent("OPEN_BULKBUY_BOOTH_ZD");
	this:RegisterEvent("UPDATE_ZENGDIAN");
	this:RegisterEvent("CLOSE_BOOTH");
end

function ZdShop_BulkBuying_OnLoad()
	ARR_PRICE[1] = Shop_BulkBuying_Money1;
	ARR_PRICE[2] = Shop_BulkBuying_Money2;
	ARR_PRICE[3] = Shop_BulkBuying_Money3;
end

function ZdShop_BulkBuying_OnEvent(event)
	if(event == "OPEN_BULKBUY_BOOTH_ZD") then
		ZdShop_BulkBuying_Open(tonumber(arg0));
	elseif(event == "CLOSE_BOOTH") then
		this:Hide();
	elseif( (event == "UPDATE_ZENGDIAN" ) and this:IsVisible()) then
		local playerZengDian = Player:GetData("ZENGDIAN");
		ZdShop_BulkBuying_Money3:SetText(playerZengDian);
	end
end

function ZdShop_BulkBuying_Open( idx )
	--商店是消耗金钱的
	local i = 0;
	if(NpcShop:GetShopType("unit") == CU_ZENGDIAN) then
		--这个位置的物品的叠加数量是大于1的
		g_ItemMax = NpcShop:EnumItemMaxOverlay(idx);
		--if(g_ItemMax > 1) then
			--符合条件，显示界面
		
			ZdShop_BulkBuying_IME:SetProperty("DefaultEditBox", "True");
			g_ItemIdx = idx;
			local price = NpcShop:EnumItemPrice(g_ItemIdx);
			--local playerZengDian = Player:GetData("IPREGION");
			local playerZengDian = Player:GetData("ZENGDIAN");
			
				--数量
			ZdShop_BulkBuying_IME:SetProperty("DefaultEditBox", "True");
			ZdShop_BulkBuying_IME:SetText("20");
			ZdShop_BulkBuying_IME:SetSelected( 0, -1 );
			local num = tonumber(ZdShop_BulkBuying_IME:GetText());
			
			--需要花费
			--Shop_BulkBuying_Money2:SetProperty("MoneyMaxNumber", playerMoney);
			ZdShop_BulkBuying_Money2:SetText(price*num);
			--物品单价
			ZdShop_BulkBuying_Money1:SetText(price);
			--身体携带
			ZdShop_BulkBuying_Money3:SetText(playerZengDian);
		
			
			if price*num > playerZengDian then
			
			
				ZdShop_BulkBuying_Money2:SetProperty("TextColor", "FFFF0000");
					ZdShop_BulkBuying_Accept:Disable();
			else
			
				
				ZdShop_BulkBuying_Money2:SetProperty("TextColor", "FFFFFFFF");
				ZdShop_BulkBuying_Accept:Enable();
			end
			--名称
			--ZdShop_BulkBuying_PageHeader:SetText("#gFF0FA0"..NpcShop:EnumItemName(g_ItemIdx));
			ZdShop_BulkBuying_ItemInfo:SetText("#gFF0FA0"..NpcShop:EnumItemName(g_ItemIdx));
			local theAction = EnumAction(idx, "boothitem");
			
			if theAction:GetID() ~= 0 then
				ZdShop_BulkBuying_Item:SetActionItem(theAction:GetID());
			end
			
			this:Show();
		--end
	end
	
		
end

function ZdShop_BulkBuying_Accept_Clicked()
	--购买多个
	local num = tonumber(ZdShop_BulkBuying_IME:GetText());
	if(nil ~= num) then
		if( tonumber( num ) == 0  ) then
		else
			NpcShop:BulkBuyItem(g_ItemIdx, num, 0);
		end
	end
	this:Hide();
end

function ZdShop_BulkBuying_TextChanged()

	local num = tonumber(ZdShop_BulkBuying_IME:GetText());
	
	if(nil == num or(num and num < 0)) then 
		ZdShop_BulkBuying_Money2:SetText(0);
		return; 
	end
	
	if(num > 7500) then
		num = 7500;
	end
	
	if(num == 0) then
		ZdShop_BulkBuying_Money2:SetText(0);
	end
	
	local playerZengDian = Player:GetData("ZENGDIAN");
	local price = NpcShop:EnumItemPrice(g_ItemIdx);
	
	if price*num > playerZengDian then
	
			--PushDebugMessage("红色");
			ZdShop_BulkBuying_Money2:SetProperty("TextColor", "FFFF0000");
		
			ZdShop_BulkBuying_Accept:Disable();
	else
			--PushDebugMessage("白色");
			
			ZdShop_BulkBuying_Money2:SetProperty("TextColor", "FFFFFFFF");
			ZdShop_BulkBuying_Accept:Enable();
	end
	
	
		local price = NpcShop:EnumItemPrice(g_ItemIdx)*num;
		ZdShop_BulkBuying_Money2:SetText(price);
		ZdShop_BulkBuying_IME:SetTextOriginal(num); --修改原来的bug，递归调用导致客户端脚本系统死掉
	
	
end

function ZdShop_BulkBuying_Max_Clicked()

	local theAction = EnumAction(g_ItemIdx, "boothitem");

	local nItemTableIdx = theAction:GetItemTableIndex()
	
	local nItemNum1 = CalcItemSpace(nItemTableIdx);
	if nItemNum1 == 0 then
		local SpaceType = CalcItemSpaceType(nItemTableIdx)
		if SpaceType == 1 then
			PushDebugMessage("#{PLYH_171128_01}")
		end
		if SpaceType == 2 then
			PushDebugMessage("#{PLYH_171128_02}")
		end		
		
		ZdShop_BulkBuying_IME:SetText("0");
		return;
	end
	
	local price = NpcShop:EnumItemPrice(g_ItemIdx);
	local playerZengDian = Player:GetData("ZENGDIAN");

	local nItemNum2 = math.floor(playerZengDian/price);
	
	if nItemNum2 == 0 then
		PushDebugMessage("#{PLYH_171128_11}")
	end
	local nItemNum = 0;
	

	nItemNum2 = math.floor(nItemNum2);
	
	if(nItemNum1 > nItemNum2) then
		nItemNum = nItemNum2;
	else
		nItemNum = nItemNum1;
	end
	
	if(nItemNum > 7500) then
		nItemNum = 7500;
	end
	
	
	local strText = tostring(nItemNum);
		
	ZdShop_BulkBuying_IME:SetText(strText);

end