-- [军衔商店, 爵位商店 批量购买界面] add by DuanXiaoTong_2015/03/12
-- PushDebugMessage
-- ScriptGlobal_Format
-- !!!reloadscript =NEWShop_MBuy
-------------------------------------------------------------------
local g_ShopType = -1			-- 商店类型
local g_TableIndex = -1			-- 物品索引
local g_BuyNum = -1				-- 默认购买数量
local g_NpcObjId = -1;			-- NpcId

local g_MaxBuyNum_PerTime = 7500		-- 这个不是常量，打开窗口的时候会根据商店重新初始化，但最大7500
-- ============================================= 系统调用函数 =============================================
-- *******************
-- PreLoad
-- *******************
function NEWShop_MBuy_PreLoad()
	this:RegisterEvent( "OPEN_JUEWEISHOP_MULTI_BUYWINDOW" );	-- 打开UI
	this:RegisterEvent( "UPDATA_MILITARYEXCHANGEVALUE" );		-- 战功
	this : RegisterEvent( "UPDATE_YUANBAO" );					-- 元宝
	this:RegisterEvent("UPDATE_SELFGUILDCONTRI")--帮会商城
	this:RegisterEvent("GUILDSHOP_UI");
end


-- *******************
-- OnLoad
-- *******************
function NEWShop_MBuy_OnLoad()
	g_Controls = {
		-- 框架
		Framework = NEWShop_MBuy_Frame;
		-- 图标
		ActionButton = NEWShop_MBuy_Item;
		-- 道具名称
		ItemName = NEWShop_MBuy_ItemInfo_Text;
		-- 道具单价
		UnitPrice = NEWShop_MBuy_ItemInfo_GB;
		-- 购买数量
		BuyNumber = NEWShop_MBuy_InputNum;
		-- 最大
		MaxButton = NEWShop_MBuy_MAX;
		-- 所需费用
		Price = {
			Text = NEWShop_MBuy_Price;
			Value = NEWShop_MBuy_Price_Yuanbao;
		};
		-- 拥有资金
		Cash = {
			Text = NEWShop_MBuy_Cash;
			Value = NEWShop_MBuy_Cash_Yuanbao;
		};
		-- 确定
		OkButton = NEWShop_MBuy_Buy;
		-- 取消
		CancelButton = NEWShop_MBuy_Cancel;
	};
end


-- *******************
-- Event
-- *******************
function NEWShop_MBuy_OnEvent( nEvent )
	--
	if ( nEvent == "OPEN_JUEWEISHOP_MULTI_BUYWINDOW" ) then
		-- 关心NPC
		g_NpcObjId = tonumber( arg0 )
		this:CareObject( g_NpcObjId, 1, "NEWShop_MBuy" );
		-- 更新UI
		g_ShopType = tonumber( arg1 );
		if ( g_ShopType == 1 ) then
			-- 战功宝斋
			local nTableIndex = tonumber( arg2 );
			NEWShop_MBuy_UpdateHonorShopUI( nTableIndex );
			--
			this:Show();
		elseif ( g_ShopType == 2 ) then
			-- 元宝商坊
			local nTableIndex = tonumber( arg2 );
			NEWShop_MBuy_UpdateYuanBaoShopUI( nTableIndex );
			--
			this:Show();
		elseif ( g_ShopType == 3 ) then
			--帮会商城
			local nTableIndex = tonumber( arg2 );
			NEWShop_MBuy_UpdateBangHuiShopUI( nTableIndex );
			this:Show();
		elseif ( g_ShopType == 4 ) then
			-- 战功宝斋
			local nTableIndex = tonumber( arg2 );
			NEWShop_MBuy_UpdateShideShopUI( nTableIndex );
			--
			this:Show();
		end
	elseif ( nEvent == "UPDATA_MILITARYEXCHANGEVALUE" ) then
		g_Controls.Cash.Value:SetText( tostring( Player:GetData( "MILITARYEXCHANGE" ) ) );
	elseif ( nEvent == "UPDATE_YUANBAO" ) then
		g_Controls.Cash.Value:SetText( tostring( Player:GetData( "YUANBAO" ) ) );
	elseif ( nEvent == "UPDATE_SELFGUILDCONTRI" ) then
		local guildContri = Guild:GetGuildContri()
		g_Controls.Cash.Value:SetText( "#cfff263"..tostring(guildContri) );
		NEWShop_MBuy_TextChanged()
	elseif ( nEvent=="GUILDSHOP_UI" and tostring(arg0)=="update") then
		if this:IsVisible() then
			this:Hide()
		end
	end
end


-- ============================================= 自定义函数 =============================================
-- *******************
-- 清除控件内容
-- *******************
function NEWShop_MBuy_CleanupUI()
	-- 重置索引
	g_TableIndex = -1;
	g_BuyNum = -1;

	-- 图标
	g_Controls.ActionButton:SetActionItem( -1 );
	-- 道具名称
	g_Controls.ItemName:SetText( "" );
	-- 道具单价
	g_Controls.UnitPrice:SetText( "" );
	-- 购买数量
	g_Controls.BuyNumber:SetProperty( "DefaultEditBox", "True" );
	g_Controls.BuyNumber:SetText( "" );
	g_Controls.BuyNumber:SetSelected( 0, -1 );
	-- 最大
	g_Controls.MaxButton:Enable();
	-- 所需费用
	g_Controls.Price.Text:SetText( "" );
	g_Controls.Price.Value:SetText( "" );
	-- 拥有资金
	g_Controls.Cash.Text:SetText( "" );
	g_Controls.Cash.Value:SetText( "" );
	-- 确定
	g_Controls.OkButton:Enable();
	-- 取消
	g_Controls.CancelButton:Enable();
end


-- *******************
-- [战功宝斋]更新UI
-- *******************
function NEWShop_MBuy_UpdateHonorShopUI( nTableIndex )
	-- 参数
	if ( nTableIndex == nil or nTableIndex < 0 ) then
		return
	end

	-- CleanupUI
	NEWShop_MBuy_CleanupUI();

	--
	local theAction = City:EnumHonourShop( nTableIndex );
	if ( theAction:GetID() ~= 0 ) then
		-- 索引
		g_TableIndex = nTableIndex;
		g_BuyNum = 1;

		-- 图标
		g_Controls.ActionButton:SetActionItem( theAction:GetID() );
		-- 道具名称
		if ( theAction:GetItemColorInShop() ~= "" ) then
			g_Controls.ItemName:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
		else
			g_Controls.ItemName:SetText( "#{JWSD_140821_75}"..theAction:GetName() );
		end
		-- 单价
		local nHonor = City:GetHonourShopInfo( nTableIndex, "honour" );
		g_Controls.UnitPrice:SetText( "#{JWSD_140821_68}"..tostring( nHonor ) );
		-- 购买数量
		g_Controls.BuyNumber:SetText( tostring( g_BuyNum ) );
		-- 所需费用
		g_Controls.Price.Text:SetText( "#{PLGM_150306_12}" );
		g_Controls.Price.Value:SetText( tostring( g_BuyNum * nHonor ) );
		-- 拥有资金
		g_Controls.Cash.Text:SetText( "#{PLGM_150306_14}" );
		g_Controls.Cash.Value:SetText( tostring( Player:GetData( "MILITARYEXCHANGE" ) ) );
	end
end

-- *******************
-- [师德商店]更新UI
-- *******************
function NEWShop_MBuy_UpdateShideShopUI( nTableIndex )
	-- 参数
	if ( nTableIndex == nil or nTableIndex < 0 ) then
		return
	end
	-- CleanupUI
	NEWShop_MBuy_CleanupUI();

	--
	local theAction = WenDingUI:EnumShideShop( nTableIndex );
	if ( theAction:GetID() ~= 0 ) then
		-- 索引
		g_TableIndex = nTableIndex;
		g_BuyNum = 1;

		-- 图标
		g_Controls.ActionButton:SetActionItem( theAction:GetID() );
		-- 道具名称
		if ( theAction:GetItemColorInShop() ~= "" ) then
			g_Controls.ItemName:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
		else
			g_Controls.ItemName:SetText( "#{JWSD_140821_75}"..theAction:GetName() );
		end
		-- 单价
		local nHonor = WenDingUI:GetShideShopInfo( nTableIndex, "shide" );
		g_Controls.UnitPrice:SetText( "#{SDSD_150514_31}"..tostring( nHonor ) );
		-- 购买数量
		g_Controls.BuyNumber:SetText( tostring( g_BuyNum ) );
		-- 所需费用
		g_Controls.Price.Text:SetText( "#{SDSD_150514_33}" );
		g_Controls.Price.Value:SetText( tostring( g_BuyNum * nHonor ) );
		-- 拥有资金
		g_Controls.Cash.Text:SetText( "#{SDSD_150514_34}" );
		g_Controls.Cash.Value:SetText( tostring( Player:GetData( "SHIDEVALUE" ) ) );
	end
end


-- *******************
-- [元宝商坊]更新UI
-- *******************
function NEWShop_MBuy_UpdateYuanBaoShopUI( nTableIndex )
	-- 参数
	if ( nTableIndex == nil or nTableIndex < 0 ) then
		return
	end

	-- CleanupUI
	NEWShop_MBuy_CleanupUI();

	--
	local theAction = City:EnumYuanBaoShop( nTableIndex );
	if ( theAction:GetID() ~= 0 ) then
		-- 索引
		g_TableIndex = nTableIndex;
		g_BuyNum = 1

		-- 图标
		g_Controls.ActionButton:SetActionItem( theAction:GetID() );
		-- 道具名称
		if ( theAction:GetItemColorInShop() ~= "" ) then
			g_Controls.ItemName:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
		else
			g_Controls.ItemName:SetText( "#{JWSD_140821_75}"..theAction:GetName() );
		end
		-- 单价
		local nYuanbao = City:GetYuanBaoShopInfo( nTableIndex, "yuanbao" );
		g_Controls.UnitPrice:SetText( "#{JWSD_140821_70}"..tostring( nYuanbao ) );
		-- 购买数量
		g_Controls.BuyNumber:SetText( tostring( g_BuyNum ) );
		-- 所需费用
		g_Controls.Price.Text:SetText( "#{DJGMYH_120428_23}" );
		g_Controls.Price.Value:SetText( tostring( g_BuyNum * nYuanbao ) );
		-- 拥有资金
		g_Controls.Cash.Text:SetText( "#{JWSD_140821_22}" );
		g_Controls.Cash.Value:SetText( tostring( Player:GetData( "YUANBAO" ) ) );
	end
end

function NEWShop_MBuy_UpdateBangHuiShopUI(nTableIndex)
	-- 参数
	if ( nTableIndex == nil or nTableIndex < 0 ) then
		return
	end

	-- CleanupUI
	NEWShop_MBuy_CleanupUI();

	local theAction, isSoldOut = City:EnumGuildShop(nTableIndex);
	if ( theAction:GetID() ~= 0 ) then
		-- 索引
		g_TableIndex = nTableIndex;
		g_BuyNum = 1

		-- 图标
		g_Controls.ActionButton:SetActionItem( theAction:GetID() );
		-- 道具名称
		if ( theAction:GetItemColorInShop() ~= "" ) then
			g_Controls.ItemName:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
		else
			g_Controls.ItemName:SetText( "#{JWSD_140821_75}"..theAction:GetName() );
		end
		-- 单价
		local contribute = City:GetGuildShopInfo(nTableIndex, "contribute");
		local szShow=ScriptGlobal_Format( "#{BHSC_140509_42}", contribute)
		g_Controls.UnitPrice:SetText( szShow );
		-- 购买数量
		g_Controls.BuyNumber:SetText( tostring( g_BuyNum ) );
		g_Controls.BuyNumber:SetSelected( 0, -1 );
		-- 所需费用
		g_Controls.Price.Text:SetText( "#{PLGM_150306_11}" );--需要帮贡
		g_Controls.Price.Value:SetText( "#cfff263"..tostring( g_BuyNum * contribute ) );
		-- 拥有资金
		g_Controls.Cash.Text:SetText( "#{PLGM_150306_13}" );
		g_Controls.Cash.Value:SetText( "#cfff263"..tostring( Guild:GetGuildContri() ) );
	end
end
-- ============================================= 响应事件 =============================================
-- *******************
-- 输入框
-- *******************
function NEWShop_MBuy_TextChanged()
	-- 数量
	local nNum = tonumber( g_Controls.BuyNumber:GetText() );
	if ( nil == nNum or ( nNum and nNum < 0 ) ) then
		g_Controls.Price.Value:SetText( tostring( 0 ) );
		g_BuyNum = -1;
		return
	end
	-- 索引
	if ( g_TableIndex == -1 ) then
		return
	end

	--
	if ( g_ShopType == 1 ) then			-- 战功宝斋
		-- 剩余数量
		local nRemainNum = City:GetHonourShopInfo( g_TableIndex, "remainnum" );
		if ( nRemainNum <= 0 ) then
			return
		end
		-- 叠加数量
		local nDuanWei = City:GetWeekDuanWei();
		local nLayerNum = City:GetHonourShopItemLayerNum( nDuanWei, g_TableIndex );
		-- 背包空间
		local nItemTableIndex = City:GetHonourShopInfo( g_TableIndex, "tableindex" );
		local nBagSpace = CalcItemSpace( nItemTableIndex );
		-- 价格
		local nMyHonour = Player:GetData( "MILITARYEXCHANGE" );
		local nItemHonour = City:GetHonourShopInfo( g_TableIndex, "honour" );
		-- 计算实际可购买数量
		local nCanBuyNum = math.floor( nBagSpace / nLayerNum );
		nCanBuyNum = math.min( nCanBuyNum, math.floor( nMyHonour / nItemHonour ) );
		nCanBuyNum = math.min( nCanBuyNum, nRemainNum );
		-- 设置购买数量
		if ( nNum > nCanBuyNum ) then
			g_Controls.BuyNumber:SetText( tostring( nCanBuyNum ) );
			g_BuyNum = nCanBuyNum;
		else
			g_BuyNum = nNum;
		end
		g_Controls.Price.Value:SetText( tostring( g_BuyNum * nItemHonour ) );
	elseif ( g_ShopType == 2 ) then		-- 元宝商坊
		-- 剩余数量
		local nRemainNum = City:GetYuanBaoShopInfo( g_TableIndex, "remainnum" );
		if ( nRemainNum <= 0 ) then
			return
		end
		-- 叠加数量
		local nDuanWei = City:GetWeekDuanWei();
		local nLayerNum = City:GetYuanBaoShopItemLayerNum( nDuanWei, g_TableIndex );
		-- 背包空间
		local nItemTableIndex = City:GetYuanBaoShopInfo( g_TableIndex, "tableindex" );
		local nBagSpace = CalcItemSpace( nItemTableIndex );
		-- 价格
		local nMyYuanBao = Player:GetData( "YUANBAO" );
		local nItemYuanBao = City:GetYuanBaoShopInfo( g_TableIndex, "yuanbao" );
		-- 计算实际可购买数量
		local nCanBuyNum = math.floor( nBagSpace / nLayerNum );
		nCanBuyNum = math.min( nCanBuyNum, math.floor( nMyYuanBao / nItemYuanBao ) );
		nCanBuyNum = math.min( nCanBuyNum, nRemainNum );
		-- 设置购买数量
		if ( nNum > nCanBuyNum ) then
			g_Controls.BuyNumber:SetText( tostring( nCanBuyNum ) );
			g_BuyNum = nCanBuyNum;
		else
			g_BuyNum = nNum;
		end
		g_Controls.Price.Value:SetText( tostring( g_BuyNum * nItemYuanBao ) );
	elseif (g_ShopType == 3) then--帮会商城

		if(nil == nNum or(nNum and nNum < 0)) then
			g_Controls.Price.Value:SetText( "0" );--需要货币
			g_BuyNum=0
			return;
		end
		if(nNum > g_MaxBuyNum_PerTime) then
			nNum = g_MaxBuyNum_PerTime;
			g_Controls.BuyNumber:SetText( tostring( nNum ) );
		end
		g_BuyNum=nNum

		local needTxtColor = ""
		--需要花费
		local contribute = City:GetGuildShopInfo(g_TableIndex, "contribute");--单价
		if g_BuyNum>=0 then
			local guildContri = Guild:GetGuildContri()
			if guildContri>=contribute * g_BuyNum then
				needTxtColor="#cfff263"
			else
				needTxtColor="#cff0000"
			end
		else
			needTxtColor="#cfff263"
		end
		g_Controls.Price.Value:SetText( needTxtColor..tostring( contribute * g_BuyNum ) );--需要元宝
	elseif ( g_ShopType == 4 ) then			-- 师德商店
		-- 剩余数量
		local nRemainNum = WenDingUI:GetShideShopInfo( g_TableIndex, "remainnum" );
		if ( nRemainNum <= 0 ) then
			return
		end
		-- 叠加数量
		local nDuanWei = WenDingUI:GetShideLevel();
		local nLayerNum = WenDingUI:GetShideShopItemLayerNum( nDuanWei, g_TableIndex );
		-- 背包空间
		local nItemTableIndex = WenDingUI:GetShideShopInfo( g_TableIndex, "tableindex" );
		local nBagSpace = CalcItemSpace( nItemTableIndex );
		
		-- 价格
		local nMyHonour = Player:GetData( "SHIDEVALUE" );
		local nItemHonour = WenDingUI:GetShideShopInfo( g_TableIndex, "shide" );
		-- 计算实际可购买数量
		local nCanBuyNum = math.floor( nBagSpace / nLayerNum );
		
		nCanBuyNum = math.min( nCanBuyNum, math.floor( nMyHonour / nItemHonour ) ); 
		nCanBuyNum = math.min( nCanBuyNum, nRemainNum );
		-- 设置购买数量
		if ( nNum > nCanBuyNum ) then
			g_Controls.BuyNumber:SetText( tostring( nCanBuyNum ) );
			g_BuyNum = nCanBuyNum;
		else
			g_BuyNum = nNum;
		end
		g_Controls.Price.Value:SetText( tostring( g_BuyNum * nItemHonour ) );
	end
end


-- *******************
-- 最大 按钮
-- *******************
function NEWShop_MBuy_MaxButtonDwon()
	-- 商店类型
	if ( g_ShopType == -1  ) then
		return
	end
	-- 索引
	if ( g_TableIndex == -1 ) then
		return
	end

	--
	if ( g_ShopType == 1 ) then		-- 战功宝斋
		
		-- 剩余数量
		local nRemainNum = City:GetHonourShopInfo( g_TableIndex, "remainnum" );
		if ( nRemainNum <= 0 ) then
			PushDebugMessage("#{PLYH_171128_04}")
			return
		end
		-- 叠加数量
		local nDuanWei = City:GetWeekDuanWei();
		local nLayerNum = City:GetHonourShopItemLayerNum( nDuanWei, g_TableIndex );
		-- 背包空间
		local nItemTableIndex = City:GetHonourShopInfo( g_TableIndex, "tableindex" );
		local nBagSpace = CalcItemSpace( nItemTableIndex );	
		if nBagSpace == 0 then
			local SpaceType = CalcItemSpaceType(nItemTableIndex)
			if SpaceType == 1 then
				PushDebugMessage("#{PLYH_171128_01}")
			end
			if SpaceType == 2 then
				PushDebugMessage("#{PLYH_171128_02}")
			end	
			g_Controls.BuyNumber:SetText( tostring( 0 ) );
			return	
		end
		-- 价格
		local nMyHonour = Player:GetData( "MILITARYEXCHANGE" );
		local nItemHonour = City:GetHonourShopInfo( g_TableIndex, "honour" );
		-- 计算实际可购买数量
		local nCanBuyNum = math.floor( nBagSpace / nLayerNum );
		nCanBuyNum = math.min( nCanBuyNum, math.floor( nMyHonour / nItemHonour ) );
		if nCanBuyNum == 0 then
			PushDebugMessage("#{PLYH_171128_14}")
			g_Controls.BuyNumber:SetText( tostring( 0 ) );
			return
		end 
		nCanBuyNum = math.min( nCanBuyNum, nRemainNum );
		-- 设置购买数量
		g_Controls.BuyNumber:SetText( tostring( nCanBuyNum ) );
		g_BuyNum = nCanBuyNum;
	elseif ( g_ShopType == 2 ) then	-- 元宝商坊
		-- 剩余数量
		local nRemainNum = City:GetYuanBaoShopInfo( g_TableIndex, "remainnum" );
		if ( nRemainNum <= 0 ) then
			PushDebugMessage("#{PLYH_171128_04}")
			g_Controls.BuyNumber:SetText( "0" );
			return
		end
		-- 叠加数量
		local nDuanWei = City:GetWeekDuanWei();
		local nLayerNum = City:GetYuanBaoShopItemLayerNum( nDuanWei, g_TableIndex );
		-- 背包空间
		local nItemTableIndex = City:GetYuanBaoShopInfo( g_TableIndex, "tableindex" );
		local nBagSpace = CalcItemSpace( nItemTableIndex );
		-- 价格
		local nMyYuanBao = Player:GetData( "YUANBAO" );
		local nItemYuanBao = City:GetYuanBaoShopInfo( g_TableIndex, "yuanbao" );
		-- 计算实际可购买数量
		local nCanBuyNum = math.floor( nBagSpace / nLayerNum );
		if nCanBuyNum == 0 then
			local SpaceType = CalcItemSpaceType(nItemTableIndex)
			if SpaceType == 1 then
				PushDebugMessage("#{PLYH_171128_01}")
			end
			if SpaceType == 2 then
				PushDebugMessage("#{PLYH_171128_02}")
			end	
			g_Controls.BuyNumber:SetText( "0" );	
			return
		end
		nCanBuyNum = math.min( nCanBuyNum, math.floor( nMyYuanBao / nItemYuanBao ) );
		if nCanBuyNum == 0 then
			PushDebugMessage("#{PLYH_171128_15}")
			g_Controls.BuyNumber:SetText( "0" );
			return
		end
		nCanBuyNum = math.min( nCanBuyNum, nRemainNum );
		-- 设置购买数量
		g_Controls.BuyNumber:SetText( tostring( nCanBuyNum ) );
		g_BuyNum = nCanBuyNum;
	elseif (g_ShopType==3) then
		--剩余数量
		local nRemainNum = City:GetGuildShopInfo(g_TableIndex, "MaxNumber");
		if ( nRemainNum <= 0 ) then
			PushDebugMessage("#{PLYH_171128_04}")
			g_Controls.BuyNumber:SetText( "0" );
			return
		end
		--获取商品id
		local nItemTableIndex = City:GetGuildShopInfo(g_TableIndex, "itemindex");
		--PushDebugMessage("nItemTableIndex="..nItemTableIndex)
		local nMaxCount = CalcItemSpace(nItemTableIndex)
		--PushDebugMessage("nMaxCount="..nMaxCount)
		local theAction, isSoldOut = City:EnumGuildShop(g_TableIndex);
		local	nPileNum = theAction:GetNum();
		nMaxCount = math.floor(nMaxCount/nPileNum);
		if nMaxCount == 0 then
			local SpaceType = CalcItemSpaceType(nItemTableIndex)
			if SpaceType == 1 then
				PushDebugMessage("#{PLYH_171128_01}")
			end
			if SpaceType == 2 then
				PushDebugMessage("#{PLYH_171128_02}")
			end	
			g_Controls.BuyNumber:SetText( tostring( 0 ) );
			return	
		end
		
		local	nTotalMoney = Guild:GetGuildContri()--当前拥有帮贡值
		local contributeper = City:GetGuildShopInfo(g_TableIndex, "contribute");--单价
		local	nMaxCanBuyByMoney = math.floor(nTotalMoney/contributeper)
		if nMaxCanBuyByMoney == 0 then
			PushDebugMessage("#{PLYH_171128_13}")
			g_Controls.BuyNumber:SetText( tostring( 0 ) );
			return
		end
		if nMaxCount > nMaxCanBuyByMoney then
			nMaxCount = nMaxCanBuyByMoney
		end
		if nMaxCount > g_MaxBuyNum_PerTime then
			nMaxCount = g_MaxBuyNum_PerTime
		end
		if nMaxCount > nRemainNum then
			nMaxCount = nRemainNum
		end
		g_Controls.BuyNumber:SetText( tostring( nMaxCount ) );
		g_BuyNum = nMaxCount;
	elseif ( g_ShopType == 4 ) then		-- 师德商店
		-- 剩余数量
		local nRemainNum = WenDingUI:GetShideShopInfo( g_TableIndex, "remainnum" );
		if ( nRemainNum <= 0 ) then
			PushDebugMessage("#{PLYH_171128_04}")
			return
		end
		-- 叠加数量
		local nDuanWei = WenDingUI:GetShideLevel();
		local nLayerNum = WenDingUI:GetShideShopItemLayerNum( nDuanWei, g_TableIndex );
		-- 背包空间
		local nItemTableIndex = WenDingUI:GetShideShopInfo( g_TableIndex, "tableindex" );
		local nBagSpace = CalcItemSpace( nItemTableIndex );
		
		
		
		-- 价格
		local nMyHonour = Player:GetData( "SHIDEVALUE" );
		
		local nItemHonour = WenDingUI:GetShideShopInfo( g_TableIndex, "shide" );
		-- 计算实际可购买数量
		local nCanBuyNum = math.floor( nBagSpace / nLayerNum );
		if nCanBuyNum == 0 then
			local SpaceType = CalcItemSpaceType(nItemTableIndex)
			if SpaceType == 1 then
				PushDebugMessage("#{PLYH_171128_01}")
			end
			if SpaceType == 2 then
				PushDebugMessage("#{PLYH_171128_02}")
			end	
			g_Controls.BuyNumber:SetText( tostring( 0 ) );	
			return
		end
		
		nCanBuyNum = math.min( nCanBuyNum, math.floor( nMyHonour / nItemHonour ) );
		if nCanBuyNum <= 0 then
			PushDebugMessage("#{PLYH_171128_10}")
		end
		nCanBuyNum = math.min( nCanBuyNum, nRemainNum );
		-- 设置购买数量
		g_Controls.BuyNumber:SetText( tostring( nCanBuyNum ) );
		g_BuyNum = nCanBuyNum;
	end
end


-- *******************
-- 确定
-- *******************
function NEWShop_MBuy_BuyMulti_Clicked()
	-- 商店类型
	if ( g_ShopType == -1 ) then
		return
	end
	-- 索引
	if ( g_TableIndex == -1 ) then
		return
	end
	-- 购买数量
	if ( g_BuyNum == -1 ) then
		return
	end

	--
	if ( g_ShopType == 1 ) then
		-- 战功宝斋
		City:DoHonourShopBuy( g_TableIndex, g_BuyNum );
	elseif ( g_ShopType == 2 ) then
		-- 元宝商坊
		City:DoYuanBaoShopBuy( g_TableIndex, g_BuyNum );
	elseif (g_ShopType == 3) then
		if g_BuyNum<1 then
			PushDebugMessage("#{PLGM_150306_15}")
			return
		end
		City:DoGuildShopBuy( g_TableIndex, g_BuyNum );
	elseif ( g_ShopType == 4 ) then
		-- 师德商店
		WenDingUI:DoShideShopBuy( g_TableIndex, g_BuyNum );	
	end
end


-- *******************
-- 取消
-- *******************
function NEWShop_MBuy_Close_Clicked()
	this:Hide();
end
