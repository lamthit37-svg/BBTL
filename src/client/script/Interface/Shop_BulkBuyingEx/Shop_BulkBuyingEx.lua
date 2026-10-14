local g_ItemMax = 0;
local g_ItemIdx = -1;

local ARR_PRICE = {};

local CU_MONEY			= 1	-- 钱
local CU_MONEYJZ		= 8 -- 交子

function Shop_BulkBuyingEx_PreLoad()
	this:RegisterEvent("OPEN_BULKBUY_BOOTH_EX");
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("CLOSE_BOOTH");
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function Shop_BulkBuyingEx_OnLoad()
	ARR_PRICE[1] = Shop_BulkBuying_Money1_Ex;
	ARR_PRICE[2] = Shop_BulkBuying_Money2_Ex;
	ARR_PRICE[3] = Shop_BulkBuying_Money3_Ex;
end

function Shop_BulkBuyingEx_OnEvent(event)
	if(event == "OPEN_BULKBUY_BOOTH_EX") then
		Shop_BulkBuying_OpenEx(tonumber(arg0));
	elseif(event == "CLOSE_BOOTH") then
		this:Hide();
	elseif( event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" ) then
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
		local tmpjz = 0;
		if(NpcShop:GetShopType("unit") == CU_MONEYJZ) then
			tmpjz = playerMoneyJZ;
		end
		Shop_BulkBuying_Money2_Ex:SetProperty("MoneyMaxNumber", playerMoney + tmpjz);
		Shop_BulkBuying_Money3_Ex:SetProperty("MoneyNumber", playerMoney);
		Shop_BulkBuying_Money4_Ex:SetProperty("MoneyNumber", playerMoneyJZ);
	end
end

function Shop_BulkBuying_OpenEx( idx )
	--商店是消耗金钱的

	local i = 0;

	--商店是优先扣交子的
	if(NpcShop:GetShopType("unit") == CU_MONEYJZ) then
		--这个位置的物品的叠加数量是大于1的
		g_ItemMax = NpcShop:EnumItemMaxOverlay(idx);
		
		--if(g_ItemMax > 1) then
			--符合条件，显示界面
			for i = 1, 2 do
				if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，设置图片素材为唯美版
					ARR_PRICE[i]:SetProperty("GoldIcon", "set:WM_Button2 image:Jiaozi_Jin")
					ARR_PRICE[i]:SetProperty("SilverIcon", "set:WM_Button2 image:Jiaozi_Yin")
					ARR_PRICE[i]:SetProperty("CopperIcon", "set:WM_Button2 image:Jiaozi_Tong")
				else									--若客户端是经典版，设置图片素材为经典版
					ARR_PRICE[i]:SetProperty("GoldIcon", "set:Button6 image:Lace_JiaoziJin")
					ARR_PRICE[i]:SetProperty("SilverIcon", "set:Button6 image:Lace_JiaoziYin")
					ARR_PRICE[i]:SetProperty("CopperIcon", "set:Button6 image:Lace_JiaoziTong")
				end
			end
			Shop_BulkBuying_IME_Ex:SetProperty("DefaultEditBox", "True");
			g_ItemIdx = idx;
			local price = NpcShop:EnumItemPrice(g_ItemIdx);
			local playerMoney = Player:GetData("MONEY");
			local playerMoneyJZ = Player:GetData("MONEY_JZ");
			
			--数量
			Shop_BulkBuying_IME_Ex:SetProperty("DefaultEditBox", "True");
			Shop_BulkBuying_IME_Ex:SetText("20");
			Shop_BulkBuying_IME_Ex:SetSelected( 0, -1 )
			local num = tonumber(Shop_BulkBuying_IME_Ex:GetText());
			--需要花费
			Shop_BulkBuying_Money2_Ex:SetProperty("MoneyMaxNumber", playerMoney + playerMoneyJZ);
			Shop_BulkBuying_Money2_Ex:SetProperty("MoneyNumber", price*num);
			--物品单价
			Shop_BulkBuying_Money1_Ex:SetProperty("MoneyNumber", price);
			--身体携带
						
			--饺子和金币为红色目前实现有点怪开始，找到好的方法修改掉
			if(price*num > playerMoney + playerMoneyJZ ) then
				Shop_BulkBuying_Accept_Ex:Disable();
				
			else
					
					Shop_BulkBuying_Accept_Ex:Enable();
			end
			
	
						
			Shop_BulkBuying_Money3_Ex:SetProperty("MoneyNumber", playerMoney);
			Shop_BulkBuying_Money4_Ex:SetProperty("MoneyNumber", playerMoneyJZ);
		

			--名称
			--Shop_BulkBuying_PageHeader_Ex:SetText("#gFF0FA0"..NpcShop:EnumItemName(g_ItemIdx));
			Shop_BulkBuying_ItemInfo_Text_Ex:SetText("#gFF0FA0"..NpcShop:EnumItemName(g_ItemIdx));
			
			local theAction = EnumAction(idx, "boothitem");
			
			if theAction:GetID() ~= 0 then
				Shop_BulkBuying_Item_Ex:SetActionItem(theAction:GetID());
			end
			
			this:Show();
	end

end

function Shop_BulkBuying_Accept_Ex_Clicked()
	--购买多个
	local num = tonumber(Shop_BulkBuying_IME_Ex:GetText());
	if(nil ~= num) then
		if( tonumber( num ) == 0  ) then
		else
			NpcShop:BulkBuyItem(g_ItemIdx, num, 0);
		end
	end
	this:Hide();
end

function Shop_BulkBuying_IME_Ex_TextChanged()
	local num = tonumber(Shop_BulkBuying_IME_Ex:GetText());
	if(nil == num or(num and num < 0)) then
		Shop_BulkBuying_Money2_Ex:SetProperty("MoneyNumber", 0);
		return;
	end

	if(NpcShop:GetShopType("unit") == CU_MONEYJZ) then--饺子商店 add:lby2015
	
		if(num > 7500) then
			num = 7500;
		end
	
		if(num == 0) then
			Shop_BulkBuying_Money2_Ex:SetText("");
			Shop_BulkBuying_Money2_Ex:SetProperty("MoneyNumber", 0);
		end
	
		local price = NpcShop:EnumItemPrice(g_ItemIdx);
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
	
		--饺子和金币为红色目前实现有点怪开始，找到好的方法修改掉
		if(price*num > playerMoney + playerMoneyJZ ) then
			Shop_BulkBuying_Accept_Ex:Disable();
		
		else
				Shop_BulkBuying_Accept_Ex:Enable();
	
		end
			
		
		--饺子和金币为红色目前实现有点怪开始，找到好的方法修改掉
		
	end

	local price = NpcShop:EnumItemPrice(g_ItemIdx)*num;
	Shop_BulkBuying_Money2_Ex:SetProperty("MoneyNumber", price);
	Shop_BulkBuying_IME_Ex:SetTextOriginal(num); --修改原来的bug，递归调用导致客户端脚本系统死掉


end


function Shop_BulkBuying_Max_Ex_Clicked()

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
		Shop_BulkBuying_IME_Ex:SetText("0");
		return;
	end
	

	local price = NpcShop:EnumItemPrice(g_ItemIdx);
	local playerMoney = Player:GetData("MONEY");
	local playerMoneyJZ = Player:GetData("MONEY_JZ");
	local nItemNum2 = math.floor((playerMoney + playerMoneyJZ)/price);

	if nItemNum2 == 0 then		 
		PushDebugMessage("#{PLYH_171128_12}") 
	end
	
	local nItemNum = 0;
	nItemNum2 = math.floor(nItemNum2);
	
	--PushDebugMessage(nItemNum2);
	
	if(nItemNum1 > nItemNum2) then
		nItemNum = nItemNum2;
	else
		nItemNum = nItemNum1;
	end
	
	if(nItemNum > 7500) then
		nItemNum = 7500;
	end
		

	 
	local strText = tostring(nItemNum);
		
	Shop_BulkBuying_IME_Ex:SetText(strText);

end