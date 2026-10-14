--秀场商店物品批量购买界面
--create by kaibin
local g_MaxBuyNum_PerTime = 7500		-- 这个不是常量，打开窗口的时候会根据商店重新初始化，但最大7500
local g_ItemMax = 0;
local g_ItemIdx = -1;
local g_ItemDefaultNum = 1;
local g_MaxInt = 2147483647


local g_ServerNpcId = -1;

local CU_SHOWCREDIT			= 14	--秀场积分


function ShowShop_MBuy_PreLoad()
	this:RegisterEvent("OPEN_BULKBUY_BOOTH_SC")
	this:RegisterEvent("CLOSE_BOOTH")
	this:RegisterEvent("UPDATE_SHOWCREDITPOINT")
end

function ShowShop_MBuy_OnLoad()

end
function ShowShop_MBuy_OnEvent(event)
	if event == "OPEN_BULKBUY_BOOTH_SC" then
		ShowShop_MBuy_Open(tonumber(arg0))
	elseif event == "CLOSE_BOOTH" then
		this:Hide();
	elseif event == "UPDATE_SHOWCREDITPOINT" then
		ShowShop_MBuy_UpdateCurMoneyInfo(g_ItemDefaultNum)
	end
end

function ShowShop_MBuy_Open(idx)
	--使用什么作为货币
	local nUnit = NpcShop:GetShopType("unit");
	if CU_SHOWCREDIT ~= nUnit then
		return
	end

	--这个位置的物品的叠加数量是大于1的
	g_ItemMax = NpcShop:EnumItemMaxOverlay(idx);

	g_ItemIdx = idx;
	local nPrice = NpcShop:EnumItemPrice(g_ItemIdx);

	local theAction = EnumAction(idx, "boothitem");
	if theAction:GetID() ~= 0 then
		ShowShop_MBuy_Item:SetActionItem(theAction:GetID());
		--名字
		if(theAction:GetItemColorInShop()~="") then
			ShowShop_MBuy_ItemInfo_Text:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
		else
			ShowShop_MBuy_ItemInfo_Text:SetText( theAction:GetName() );
		end

		--价格
		ShowShop_MBuy_ItemInfo_GB:SetText("#{XCZB_160105_48}" .. tostring(nPrice))
	else
		ShowShop_MBuy_Item:SetActionItem(-1);
		ShowShop_MBuy_ItemInfo_Text:SetText("");
		ShowShop_MBuy_ItemInfo_GB:SetText("");
	end

	--输入框
	ShowShop_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
	ShowShop_MBuy_InputNum:SetText(tostring(g_ItemDefaultNum));
	ShowShop_MBuy_InputNum:SetSelected( 0, -1 );

	ShowShop_MBuy_UpdateCurMoneyInfo(g_ItemDefaultNum)
	this:Show();

end

function ShowShop_MBuy_UpdateCurMoneyInfo(num)
	local	nPrice = NpcShop:EnumItemPrice(g_ItemIdx);
	if nPrice > 0 and Division(g_MaxInt, nPrice) < num then
		ShowShop_MBuy_Price_Yuanbao:SetText("0")
		PushDebugMessage("#{FFSDGZ_120615_127}")
		return
	end


	local playerCoin_credit = GetShowShopCredit()
	--需要花费
	local needCreditColor = ""
	local nNeedMoney = Lua_Multiply(num, nPrice)
	if playerCoin_credit >= nNeedMoney then
		needCreditColor="#cfff263"
		ShowShop_MBuy_Buy:Enable()
	else
		needCreditColor="#cff0000"
		ShowShop_MBuy_Buy:Disable()
	end
	--需要多少
	ShowShop_MBuy_Price_Yuanbao:SetText(needCreditColor..tostring( nNeedMoney ))
	--拥有多少
	if playerCoin_credit == -1 then
		ShowShop_MBuy_Cash_Yuanbao:SetText("#cfff263".."#{XCZB_160105_58}") --正在读取中
	else
		ShowShop_MBuy_Cash_Yuanbao:SetText("#cfff263"..tostring(playerCoin_credit))
	end
end

--点击最大按钮
function ShowShop_MBuy_CalMax()
	if g_ItemIdx == nil or g_ItemIdx < 0 then
		return
	end

	local nPrice = NpcShop:EnumItemPrice(g_ItemIdx);
	if nPrice == nil or nPrice <= 0 then
		return
	end

	local theAction = EnumAction(g_ItemIdx, "boothitem");
	if theAction:GetID() == 0 then
		return
	end

	local nTotalMoney = GetShowShopCredit()
	--按策划规则，如果是-1（正在刷新中，则按0算）
	if nTotalMoney == -1 then
		nTotalMoney= 0
	end

	if nTotalMoney == nil or nTotalMoney < 0 then
		return
	end
	
	local	nMaxCanBuyByMoney = math.floor(nTotalMoney/nPrice)
	if nMaxCanBuyByMoney > g_MaxBuyNum_PerTime then
		nMaxCanBuyByMoney = g_MaxBuyNum_PerTime
	end

	--背包空间可买大小
	local nMaxCanBuyByBag = 0
	local nItemTableIndex = theAction:GetItemTableIndex()
	if nItemTableIndex ~= nil and nItemTableIndex > 0 then
		local nMaxCount = CalcItemSpace(nItemTableIndex) --根据背包计算出的最大可放物品个数
		if nMaxCount == 0 then
			local SpaceType = CalcItemSpaceType(nItemTableIndex)
			if SpaceType == 1 then
				PushDebugMessage("#{PLYH_171128_01}")
			end
			if SpaceType == 2 then
				PushDebugMessage("#{PLYH_171128_02}")
			end			
			ShowShop_MBuy_InputNum:SetText("0");
			return;		
		end
		local nPileNum = theAction:GetNum();
		nMaxCanBuyByBag = math.floor(nMaxCount/nPileNum);
	end
	
	
	if nMaxCanBuyByMoney == 0 then
		PushDebugMessage("#{PLYH_171128_08}")
		ShowShop_MBuy_InputNum:SetText("0");
		return;
	end
	
	--最终
	local nFinalCount = nMaxCanBuyByMoney
	if nMaxCanBuyByMoney > nMaxCanBuyByBag then
		nFinalCount = nMaxCanBuyByBag
	end

	if nFinalCount > g_MaxBuyNum_PerTime then
		nFinalCount = g_MaxBuyNum_PerTime
	end

	ShowShop_MBuy_InputNum:SetText(tostring(nFinalCount));
end

function ShowShop_MBuy_TextChanged()
	local num = tonumber(ShowShop_MBuy_InputNum:GetText());
	if(nil == num or num < 0) then
		ShowShop_MBuy_Price_Yuanbao:SetText("0")
		return;
	end

	if(num > g_MaxBuyNum_PerTime) then
		num = g_MaxBuyNum_PerTime;
		ShowShop_MBuy_InputNum:SetText(tostring(num))
	end

	ShowShop_MBuy_UpdateCurMoneyInfo(num)
end

function ShowShop_MBuy_Close_Clicked()
	this:Hide()
end

--点击确定按钮
function ShowShop_MBuy_BuyMulti_Clicked()
	if g_ItemIdx == nil or g_ItemIdx < 0 then
		return
	end

	local playerCoin_credit = GetShowShopCredit()
	if playerCoin_credit <= 0 then
		return
	end

	local num = tonumber(ShowShop_MBuy_InputNum:GetText());
	if num ~= nil and num > 0 then
		NpcShop:BulkBuyItem(g_ItemIdx, num, 0);
		ShowShop_MBuy_Close_Clicked()
	else
		PushDebugMessage("#{FFSDGZ_120615_47}")
	end
end
