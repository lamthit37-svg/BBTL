--付费商店改造，赠送好友礼物 by liuyong
local CU_YUANBAO			= 5	-- 钱
local g_ItemMax = 0;
local g_ItemIdx = -1;
local g_ItemDefaultNum = 1;
local g_Friendgroup = 0
local g_Friendindex = -1
local g_Friendguid = ""
local g_FriendName = ""
local g_bFromRecentBooth = 0
local g_MaxInt = 2147483647
function Shop_MGift_PreLoad()
	this:RegisterEvent("OPEN_GIVEGIFT_WND");
	this:RegisterEvent("UPDATE_YUANBAO");
	this:RegisterEvent("CLOSE_BOOTH");
	this:RegisterEvent("OPEN_GIVEGIFT_COMPLETE_CHOOSE");
	this:RegisterEvent("OPEN_YUANBAOSHOP_RECENTLY")
end

function Shop_MGift_OnLoad()

end
function Shop_MGift_OnEvent(event)
	if(event == "OPEN_GIVEGIFT_WND") then
		g_bFromRecentBooth = 0
		g_bFromRecentBooth = tonumber(arg1)
		--Shop_MBuy_Open 必须在 g_bFromRecentBooth 赋值的后面
		Shop_MGift_Open(tonumber(arg0));
	elseif(event == "CLOSE_BOOTH") then
		this:Hide();
	elseif( event == "UPDATE_YUANBAO" and this:IsVisible() ) then
		--需要花费
		local playerYuanBao = Player:GetData("YUANBAO");
		local	nPrice	= NpcShop:EnumItemPrice(g_ItemIdx);
		if g_bFromRecentBooth > 0 then
			nPrice = NpcShop:EnumItemPriceRecently(g_ItemIdx);
		end
		local needYuanBaoColor = ""
		local num = tonumber(Shop_MGift_InputNum:GetText());
		if(nil ~= num) then
			if nPrice > 0 and Division(g_MaxInt, nPrice) < num then
				Shop_MGift_Price_Yuanbao:SetText("")
				PushDebugMessage("#{FFSDGZ_120615_127}")
				return
			end
			local needYuanBaoNum = Lua_Multiply(nPrice, num)
			if playerYuanBao >= needYuanBaoNum then
				needYuanBaoColor="#cfff263"
				Shop_MGift_Buy:Enable()
			else
				needYuanBaoColor="#cff0000"
				Shop_MGift_Buy:Disable()
			end
			Shop_MGift_Price_Yuanbao:SetText(needYuanBaoColor..""..tostring( needYuanBaoNum ))
			--身体携带
			Shop_MGift_Cash_Yuanbao:SetText("#cfff263"..tostring(playerYuanBao))
		end
	elseif ( event == "OPEN_GIVEGIFT_COMPLETE_CHOOSE" ) then
		g_Friendguid = arg0
		g_FriendName = tostring(arg1)
		g_Friendgroup, g_Friendindex = DataPool:GetFriendByGUID(g_Friendguid);
		if g_Friendgroup == nil or g_Friendindex == nil then
			PushDebugMessage("#{ZSGN_101129_24}")
			return
		end

		if g_Friendgroup == 0 or g_Friendindex == -1 then
			PushDebugMessage("#{ZSGN_101129_24}")
			return
		end
		Shop_MGift_InputName:SetText(g_FriendName)
	elseif ( event == "OPEN_YUANBAOSHOP_RECENTLY" ) then
		if g_bFromRecentBooth > 0 then
			Shop_MGift_Close_Clicked()
		end
	end
end

function Shop_MGift_Open( idx )
	--商店是消耗元宝
	local i = 0;
	g_Friendguid = "";
	g_FriendName = "";
	if(NpcShop:GetShopType("unit") == CU_YUANBAO) then
		--这个位置的物品的叠加数量是大于1的
		g_ItemMax = NpcShop:EnumItemMaxOverlay(idx);

		g_ItemIdx = idx;
		local	nPrice	= NpcShop:EnumItemPrice(g_ItemIdx);
		local theAction = EnumAction(idx, "boothitem");
		if g_bFromRecentBooth > 0 then
			theAction = EnumAction(idx, "yuanbaorecently");
			nPrice = NpcShop:EnumItemPriceRecently(g_ItemIdx);
		end
		if theAction:GetID() ~= 0 then

			Shop_MGift_Item:SetActionItem(theAction:GetID());
			if(theAction:GetItemColorInShop() ~= "") then
				Shop_MGift_ItemInfo_Text:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				Shop_MGift_ItemInfo_Text:SetText( theAction:GetName() );
			end

			Shop_MGift_ItemInfo_GB:SetText("#{YBSD_081225_101}" .. tostring(nPrice))

		else
			Shop_MGift_Item:SetActionItem(-1);
			Shop_MGift_ItemInfo_Text:SetText("");
			Shop_MGift_ItemInfo_GB:SetText("");
		end

		--需要花费
		local playerYuanBao = Player:GetData("YUANBAO");
		local needYuanBaoColor = ""
		local nNeedMoney = Lua_Multiply(g_ItemDefaultNum, nPrice)
		if playerYuanBao >= nNeedMoney then
			needYuanBaoColor="#cfff263"
			Shop_MGift_Buy:Enable()
		else
			needYuanBaoColor="#cff0000"
			Shop_MGift_Buy:Disable()
		end
		if nPrice > 0 and Division(g_MaxInt, nPrice) < g_ItemDefaultNum then
			Shop_MGift_Price_Yuanbao:SetText("")
			PushDebugMessage("#{FFSDGZ_120615_127}")
			return
		end
		Shop_MGift_Price_Yuanbao:SetText(needYuanBaoColor..""..tostring( nNeedMoney ))
		--身体携带
		Shop_MGift_Cash_Yuanbao:SetText("#cfff263"..tostring(playerYuanBao))
		--数量
		Shop_MGift_InputNum:SetProperty("DefaultEditBox", "True");
		local num = tonumber(Shop_MGift_InputNum:GetText());
		if(nil ~= num or(num and num > 0)) then
			Shop_MGift_InputNum:SetText(tostring(g_ItemDefaultNum));
		end
		Shop_MGift_InputNum:SetSelected( 0, -1 );
		--名称

		--好友
		Shop_MGift_InputName:SetText("")
		this:Show();
		--显示赠送列表
		if IsWindowShow("XuanPresent_ChooseFriend") then
			CloseWindow("XuanPresent_ChooseFriend", true)
		end
		local fX = Shop_MGift_Frame:GetProperty("AbsoluteXPosition")
		local fY = Shop_MGift_Frame:GetProperty("AbsoluteYPosition")
		fX = fX + Shop_MGift_Frame:GetProperty("AbsoluteWidth")
		PushEvent("OPEN_XUANPRESENT_CHOOSEFRIEND", "YuanBaoGift", fX, fY)
	end
end

function Shop_MGift_TextChanged()
	local num = tonumber(Shop_MGift_InputNum:GetText());
	if(nil == num or(num and num < 0)) then
		return;
	end

	if(num > 5) then
		num = 5;
		Shop_MGift_InputNum:SetText("5")
	end

	local playerYuanBao = Player:GetData("YUANBAO");
	local	nPrice	= NpcShop:EnumItemPrice(g_ItemIdx);
	if g_bFromRecentBooth > 0 then
		nPrice = NpcShop:EnumItemPriceRecently(g_ItemIdx);
	end
	local needYuanBaoColor = ""
	if(nil ~= num) then
		if nPrice > 0 and Division(g_MaxInt, nPrice) < num then
			Shop_MGift_Price_Yuanbao:SetText("")
			PushDebugMessage("#{FFSDGZ_120615_127}")
			return
		end
		local needYuanBaoNum = Lua_Multiply(nPrice, num)
		if playerYuanBao >= needYuanBaoNum then
			needYuanBaoColor="#cfff263"
			Shop_MGift_Buy:Enable()
		else
			needYuanBaoColor="#cff0000"
			Shop_MGift_Buy:Disable()
		end
		Shop_MGift_Price_Yuanbao:SetText(needYuanBaoColor..""..tostring( needYuanBaoNum ))
		--身体携带
		Shop_MGift_Cash_Yuanbao:SetText("#cfff263"..tostring(playerYuanBao))
	end

end

function Shop_MGift_InputNum_Clicked()
	local num = tonumber(Shop_MGift_InputNum:GetText());
	if(nil == num or(num and num < 0)) then
		Shop_MGift_InputNum:SetText("");
	end
end

function Shop_MGift_Close_Clicked()
	g_Friendguid = "";
	g_FriendName = "";
	this:Hide()
end
function Shop_MGift_ChooseFriend_Clicked()
	if (GetSceneID() == 77 or GetSceneID() == 578) then
		PushDebugMessage("#{IMXZ_20100919_104}")
		return;
	end
	if IsWindowShow("XuanPresent_ChooseFriend") then
		CloseWindow("XuanPresent_ChooseFriend", true)
	else
		local fX = Shop_MGift_Frame:GetProperty("AbsoluteXPosition")
		local fY = Shop_MGift_Frame:GetProperty("AbsoluteYPosition")
		fX = fX + Shop_MGift_Frame:GetProperty("AbsoluteWidth")
		PushEvent("OPEN_XUANPRESENT_CHOOSEFRIEND", "YuanBaoGift", fX, fY)
	end
end
--回头和策划确认是否要二次确认
function Shop_MGift_BuyForFriend_Clicked()
	if g_Friendguid == nil or g_FriendName ==nil or g_FriendName == "" then
		PushDebugMessage("#{FFSDGZ_120615_51}")
		return
	end
	local num = tonumber(Shop_MGift_InputNum:GetText());
	if(nil == num or(num and num < 0)) then
		PushDebugMessage("#{FFSDGZ_120615_96}")
		return;
	end
	local num = tonumber(Shop_MGift_InputNum:GetText());
	NpcShop:BuyItemForFriend(g_ItemIdx,num,g_Friendguid, g_bFromRecentBooth);
	Shop_MGift_Close_Clicked()
end
function Shop_MGift_OnHiden()
	if IsWindowShow("XuanPresent_ChooseFriend") then
		CloseWindow("XuanPresent_ChooseFriend", true)
	end
end
