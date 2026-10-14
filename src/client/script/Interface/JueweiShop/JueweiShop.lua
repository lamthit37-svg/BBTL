-- [段位商店] add by DuanXiaoTong_2014/08/29
-- PushDebugMessage
-- ScriptGlobal_Format
-- !!!reloadscript =JueweiShop
---------------------------------------------------------------------------
local g_Controls = {};									-- 控件
local g_TableSel = 1;									-- 标签页(默认选中1)
local g_SubTableSel = 0;								-- 子标签页(默认选中1)
local g_BuyConfirm = 1;									-- 购买确认(两个商店共享)
local g_nCurPage = 0;									-- 默认第1页
local g_nOnePageNum = 15;								-- 一页显示15项
local g_NpcObjId = 0;									-- NpcId
local g_MaxDuanWei = 10;								-- 10个段位
local g_DuanWeiName = {
	"#{BHKF_140909_394}",
	"#{BHKF_140909_393}",
	"#{BHKF_140909_392}",
	"#{BHKF_140909_391}",
	"#{BHKF_140909_390}",
	"#{BHKF_140909_389}",
	"#{BHKF_140909_388}",
	"#{BHKF_140909_387}",
	"#{BHKF_140909_386}",
	"#{BHKF_140909_385}",
};

local g_Position = "{{0.500000,-330.000000},{0.500000,-226.000000}}";
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function JueweiShop_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "OPEN_DUANWEISHOP" );				-- 打开段位商店
	this : RegisterEvent( "OPEN_DUANWEIYUANBAOSHOP" );		-- 打开段位元宝商店
	this : RegisterEvent( "UPDATE_MILITARYSHOPINFO" );		-- 军衔商店
	this : RegisterEvent( "UPDATE_NOBILITYSHOPINFO" );		-- 爵位商店
	this : RegisterEvent( "UPDATA_MILITARYEXP" );			-- 军功经验值
	this : RegisterEvent( "UPDATA_MILITARYEXCHANGEVALUE" );	-- 军功兑换值
	this : RegisterEvent( "UPDATE_YUANBAO" , false);				-- 元宝
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" , false);		-- 游戏分辨率发生了变化
	this : RegisterEvent( "GAMELOGIN_SELECTCHARACTER" );	-- 选择人物
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" , false);			-- 离开场景
end


--*********************************
-- OnLoad
--*********************************
function JueweiShop_OnLoad()
	g_Controls = {
		-- 框架
		Framework = JueweiShop_Frame;

		-- 介绍
		Introduce = JueweiShop_Bk1_shuoming;
		-- 购买确认
		BuyConfirm = {
			BackGround = JueweiShop_Bk4;
			CheckButton = JueweiShop_querengoumaiBind;
		};
		-- 子标签页
		SubTable = {
			MilitaryShop = JueweiShop_Button01;
			EternalShop = JueweiShop_Button02;
		};
		-- 页码
		PageInfo = {
			-- 页数
			CurPage = JueweiShop_CurrentlyPage;
			-- 背景
			PageBackGround = JueweiShop_Bk_Bk;
			-- 向上翻页
			PageUp = JueweiShop_UpPage;
			-- 向下翻页
			PageDown = JueweiShop_DownPage;
		};
		-- 军功兑换值
		Honour = JueweiShop_Text1;
		-- 物品
		ItemInfo = {
			-- 图标
			ActiveButton = {
				[1] = JueweiShop_Item1,
				[2] = JueweiShop_Item2,
				[3] = JueweiShop_Item3,
				[4] = JueweiShop_Item4,
				[5] = JueweiShop_Item5,
				[6] = JueweiShop_Item6,
				[7] = JueweiShop_Item7,
				[8] = JueweiShop_Item8,
				[9] = JueweiShop_Item9,
				[10] = JueweiShop_Item10,
				[11] = JueweiShop_Item11,
				[12] = JueweiShop_Item12,
				[13] = JueweiShop_Item13,
				[14] = JueweiShop_Item14,
				[15] = JueweiShop_Item15,
			};
			-- 蒙红
			Mask = {
				[1] = JueweiShop_Item1_Mask,
				[2] = JueweiShop_Item2_Mask,
				[3] = JueweiShop_Item3_Mask,
				[4] = JueweiShop_Item4_Mask,
				[5] = JueweiShop_Item5_Mask,
				[6] = JueweiShop_Item6_Mask,
				[7] = JueweiShop_Item7_Mask,
				[8] = JueweiShop_Item8_Mask,
				[9] = JueweiShop_Item9_Mask,
				[10] = JueweiShop_Item10_Mask,
				[11] = JueweiShop_Item11_Mask,
				[12] = JueweiShop_Item12_Mask,
				[13] = JueweiShop_Item13_Mask,
				[14] = JueweiShop_Item14_Mask,
				[15] = JueweiShop_Item15_Mask,
			};
			-- 售罄
			SellOut = {
				[1] = JueweiShop_ItemIcon_1,
				[2] = JueweiShop_ItemIcon_2,
				[3] = JueweiShop_ItemIcon_3,
				[4] = JueweiShop_ItemIcon_4,
				[5] = JueweiShop_ItemIcon_5,
				[6] = JueweiShop_ItemIcon_6,
				[7] = JueweiShop_ItemIcon_7,
				[8] = JueweiShop_ItemIcon_8,
				[9] = JueweiShop_ItemIcon_9,
				[10] = JueweiShop_ItemIcon_10,
				[11] = JueweiShop_ItemIcon_11,
				[12] = JueweiShop_ItemIcon_12,
				[13] = JueweiShop_ItemIcon_13,
				[14] = JueweiShop_ItemIcon_14,
				[15] = JueweiShop_ItemIcon_15,
			};
			-- 物品名称
			ItemName = {
				[1] = JueweiShop_ItemInfo1_Text,
				[2] = JueweiShop_ItemInfo2_Text,
				[3] = JueweiShop_ItemInfo3_Text,
				[4] = JueweiShop_ItemInfo4_Text,
				[5] = JueweiShop_ItemInfo5_Text,
				[6] = JueweiShop_ItemInfo6_Text,
				[7] = JueweiShop_ItemInfo7_Text,
				[8] = JueweiShop_ItemInfo8_Text,
				[9] = JueweiShop_ItemInfo9_Text,
				[10] = JueweiShop_ItemInfo10_Text,
				[11] = JueweiShop_ItemInfo11_Text,
				[12] = JueweiShop_ItemInfo12_Text,
				[13] = JueweiShop_ItemInfo13_Text,
				[14] = JueweiShop_ItemInfo14_Text,
				[15] = JueweiShop_ItemInfo15_Text,
			};
			-- 军功兑换值
			Honour = {
				[1] = JueweiShop_ItemInfo1_GB,
				[2] = JueweiShop_ItemInfo2_GB,
				[3] = JueweiShop_ItemInfo3_GB,
				[4] = JueweiShop_ItemInfo4_GB,
				[5] = JueweiShop_ItemInfo5_GB,
				[6] = JueweiShop_ItemInfo6_GB,
				[7] = JueweiShop_ItemInfo7_GB,
				[8] = JueweiShop_ItemInfo8_GB,
				[9] = JueweiShop_ItemInfo9_GB,
				[10] = JueweiShop_ItemInfo10_GB,
				[11] = JueweiShop_ItemInfo11_GB,
				[12] = JueweiShop_ItemInfo12_GB,
				[13] = JueweiShop_ItemInfo13_GB,
				[14] = JueweiShop_ItemInfo14_GB,
				[15] = JueweiShop_ItemInfo15_GB,
			};
		};
	};
end


--*********************************
-- OnEvent
--*********************************
function JueweiShop_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 61001801 ) then
		-- 打开UI
		local bShow = tonumber( Get_XParam_INT( 0 ) );
		if ( bShow == 1 ) then
			if ( this:IsVisible() ) then
				return
			end
			City:AskHonourShopData();
			City:AskYuanBaoShopData();
			-- 页数
			g_nCurPage = 0;
		else
			this:Hide();
		end
		-- 关心NPC
		g_NpcObjId = Target:GetServerId2ClientId( tonumber( Get_XParam_INT( 1 ) ) );
		this:CareObject( g_NpcObjId, 1, "JueweiShop" );
	elseif ( event == "OPEN_DUANWEISHOP" ) then
		g_TableSel = 1;
		g_SubTableSel = 0;
		JueWeiShop_OnUpdateHonourShop();
		this:Show();
	elseif ( event == "OPEN_DUANWEIYUANBAOSHOP" ) then
		g_TableSel = 1;
		g_SubTableSel = 1;
		JueWeiShop_OnUpdateYuanBaoShop();
		this:Show();
	elseif ( event == "UPDATE_MILITARYSHOPINFO" ) then
		if ( this:IsVisible() and g_SubTableSel == 0 ) then
			JueWeiShop_OnUpdateHonourShop();
		end
	elseif ( event == "UPDATE_NOBILITYSHOPINFO" ) then
		if ( this:IsVisible() and g_SubTableSel == 1 ) then
			-- 更新爵位商店
			JueWeiShop_OnUpdateYuanBaoShop();
		end
	elseif ( event == "UPDATA_MILITARYEXP" or event == "UPDATA_MILITARYEXCHANGEVALUE" ) then
		if ( this:IsVisible() ) then
			if ( g_TableSel == 1 ) then
				-- 更新军衔商店
				JueWeiShop_OnUpdateHonourShop();
			elseif ( g_TableSel == 2 ) then
				-- 更新爵位商店
				JueWeiShop_OnUpdateYuanBaoShop();
			end
		end
	elseif ( event == "UPDATE_YUANBAO" ) then
		if ( this:IsVisible() ) then
			if ( g_SubTableSel == 1 ) then
				JueWeiShop_OnUpdateYuanBaoShop();
			end
		end
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "GAMELOGIN_SELECTCHARACTER" ) then
		-- 恢复默认值
		g_BuyConfirm = 1;
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end


--*********************************
-- 清空控件
--*********************************
function JueweiShop_CleanupUIControls()
	-- 关闭UI
	if ( IsWindowShow( "NEWShop_MBuy" ) ) then
		CloseWindow( "NEWShop_MBuy", true );
	end
	SetDefaultMouse();

	-- 介绍
	g_Controls.Introduce:SetText( "" );
	-- 购买确认
	if ( g_TableSel == 1 ) then
		g_Controls.BuyConfirm.BackGround:Show();
	elseif ( g_TableSel == 2 ) then
		g_Controls.BuyConfirm.BackGround:Hide();
	end
	if ( g_BuyConfirm == 1 ) then
		g_Controls.BuyConfirm.CheckButton:SetCheck( 1 );
	else
		g_Controls.BuyConfirm.CheckButton:SetCheck( 0 );
	end
	-- 子标签页
	if ( g_SubTableSel == 0 ) then
		g_Controls.SubTable.MilitaryShop:SetCheck( 1 );
		g_Controls.SubTable.EternalShop:SetCheck( 0 );
	elseif ( g_SubTableSel == 1 ) then
		g_Controls.SubTable.MilitaryShop:SetCheck( 0 );
		g_Controls.SubTable.EternalShop:SetCheck( 1 );
	end
	-- 页数
	g_Controls.PageInfo.CurPage:SetText( "1/1" );
	-- 页码背景
	g_Controls.PageInfo.PageBackGround:Show();
	-- 向上翻页
	g_Controls.PageInfo.PageUp:Enable();
	-- 向下翻页
	g_Controls.PageInfo.PageDown:Enable();
	-- 物品
	for	i = 1, table.getn( g_Controls.ItemInfo.ActiveButton ) do
		g_Controls.ItemInfo.ActiveButton[ i ]:SetActionItem( -1 );
		g_Controls.ItemInfo.Mask[ i ]:Hide();
		g_Controls.ItemInfo.SellOut[ i ]:Hide();
		g_Controls.ItemInfo.ItemName[ i ]:SetText( "" );
		g_Controls.ItemInfo.Honour[ i ]:SetText( "" );
	end
	-- 军功兑换值
	g_Controls.Honour:SetText( "" );

end


--*********************************
-- 显示[军衔商店]
--*********************************
function JueWeiShop_OnUpdateHonourShop()
	-- 清空控件
	JueweiShop_CleanupUIControls();

	-- 段位数据
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		if ( nDuanWei == 0 ) then
			nDuanWei = nDuanWei + 2;
		elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			nDuanWei = nDuanWei + 1;
		else
			nDuanWei = g_MaxDuanWei;
		end
	end

	-- 介绍
	if ( g_TableSel == 1 ) then
		g_Controls.Introduce : SetText( "#{JWSD_140821_12}" );
	elseif ( g_TableSel == 2 ) then
		g_Controls.Introduce : SetText( "#{JWSD_140821_55}" );
	end
	-- 页数
	local nItemNum = City:GetHonourShopItemNum( nDuanWei );
	local nMaxPage = math.floor( nItemNum / g_nOnePageNum );
	if ( math.mod( nItemNum, g_nOnePageNum ) > 0 ) then
		nMaxPage = nMaxPage + 1;
	end
	g_Controls.PageInfo.CurPage:SetText( ( g_nCurPage + 1 ).."/"..nMaxPage );
	-- 页码背景
	if ( nItemNum == 1 ) then
		g_Controls.PageInfo.PageBackGround:Hide();
	end
	-- 向上翻页
	if ( g_nCurPage == 0 ) then
		g_Controls.PageInfo.PageUp:Disable();
	end
	-- 向下翻页
	if ( g_nCurPage + 1 == nMaxPage ) then
		g_Controls.PageInfo.PageDown:Disable();
	end
	-- 物品
	local nStart = g_nCurPage * g_nOnePageNum;
	local nEnd = math.min( g_nCurPage * g_nOnePageNum + g_nOnePageNum - 1, nItemNum );
	for i = nStart, nEnd do
		local theAction = City:EnumHonourShop( i );
		local nIndex = math.mod( i, g_nOnePageNum ) + 1;
		if ( theAction:GetID() ~= 0 ) then
			g_Controls.ItemInfo.ActiveButton[ nIndex ]:SetActionItem( theAction:GetID() );
			local nRemainNum = City:GetHonourShopInfo( i, "remainnum" );
			if ( nRemainNum <= 0 ) then
				g_Controls.ItemInfo.Mask[ nIndex ]:Show();
				g_Controls.ItemInfo.SellOut[ nIndex ]:Show();
			end
			if ( theAction:GetItemColorInShop() ~= "" ) then
				g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( "#{JWSD_140821_75}"..theAction:GetName() );
			end
			g_Controls.ItemInfo.Honour[ nIndex ]:SetText( "#{JWSD_140821_68}"..tostring( City:GetHonourShopInfo( i, "honour" ) ) );
		else
			g_Controls.ItemInfo.ActiveButton[ nIndex ]:SetActionItem( -1 );
			g_Controls.ItemInfo.Mask[ nIndex ]:Hide();
			g_Controls.ItemInfo.SellOut[ nIndex ]:Hide();
			g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( "" );
			g_Controls.ItemInfo.Honour[ nIndex ]:SetText( "" );
		end
	end
	-- 荣誉值
	g_Controls.Honour:SetText( "#{JWSD_140821_15}"..Player:GetData( "MILITARYEXCHANGE" ) );
end


--*********************************
-- 显示[爵位商店]
--*********************************
function JueWeiShop_OnUpdateYuanBaoShop()
	-- 清空控件
	JueweiShop_CleanupUIControls();

	-- 段位数据
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		if ( nDuanWei == 0 ) then
			nDuanWei = nDuanWei + 2;
		elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			nDuanWei = nDuanWei + 1;
		else
			nDuanWei = g_MaxDuanWei;
		end
	end

	-- 介绍
	if ( g_TableSel == 1 ) then
		g_Controls.Introduce : SetText( "#{JWSD_140821_20}" );
	elseif ( g_TableSel == 2 ) then
		g_Controls.Introduce : SetText( "#{JWSD_140821_55}" );
	end
	-- 页数
	local nItemNum = City:GetYuanBaoShopItemNum( nDuanWei );
	local nMaxPage = math.floor( nItemNum / g_nOnePageNum );
	if ( math.mod( nItemNum, g_nOnePageNum ) > 0 ) then
		nMaxPage = nMaxPage + 1;
	end
	g_Controls.PageInfo.CurPage:SetText( ( g_nCurPage + 1 ).."/"..nMaxPage );
	-- 页码背景
	if ( nItemNum == 1 ) then
		g_Controls.PageInfo.PageBackGround:Hide();
	end
	-- 向上翻页
	if ( g_nCurPage == 0 ) then
		g_Controls.PageInfo.PageUp:Disable();
	end
	-- 向下翻页
	if ( g_nCurPage + 1 == nMaxPage ) then
		g_Controls.PageInfo.PageDown:Disable();
	end
	-- 物品
	local nStart = g_nCurPage * g_nOnePageNum;
	local nEnd = math.min( g_nCurPage * g_nOnePageNum + g_nOnePageNum - 1, nItemNum );
	for i = nStart, nEnd do
		local theAction = City:EnumYuanBaoShop( i );
		local nIndex = math.mod( i, g_nOnePageNum ) + 1;
		if ( theAction:GetID() ~= 0 ) then
			g_Controls.ItemInfo.ActiveButton[ nIndex ]:SetActionItem( theAction:GetID() );
			local nRemainNum = City:GetYuanBaoShopInfo( i, "remainnum" );
			if ( nRemainNum <= 0 ) then
				g_Controls.ItemInfo.Mask[ nIndex ]:Show();
				g_Controls.ItemInfo.SellOut[ nIndex ]:Show();
			end
			if ( theAction:GetItemColorInShop() ~= "" ) then
				g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( "#{JWSD_140821_75}"..theAction:GetName() );
			end
			g_Controls.ItemInfo.Honour[ nIndex ]:SetText( "#{JWSD_140821_70}"..tostring( City:GetYuanBaoShopInfo( i, "yuanbao" ) ) );
		else
			g_Controls.ItemInfo.ActiveButton[ nIndex ]:SetActionItem( -1 );
			g_Controls.ItemInfo.Mask[ nIndex ]:Hide();
			g_Controls.ItemInfo.SellOut[ nIndex ]:Hide();
			g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( "" );
			g_Controls.ItemInfo.Honour[ nIndex ]:SetText( "" );
		end
	end
	-- 军功兑换值
	local nYuanBao = Player:GetData( "YUANBAO" );
	g_Controls.Honour:SetText( "#{JWSD_140821_22}"..nYuanBao );

end


--*********************************
-- [军衔商店]购买检测
--*********************************
function JueweiShop_CheckMilitaryShopBuy( uiPos )
	-- 段位数据
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		PushDebugMessage( "#{JWSD_140821_82}" );
		return 0;
		--if ( nDuanWei == 0 ) then
			--nDuanWei = nDuanWei + 2;
		--elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			--nDuanWei = nDuanWei + 1;
		--else
			--return 0;
		--end
	end

	-- 表格索引
	local nTableIndex = g_nCurPage * g_nOnePageNum + uiPos;
	local nItemNum = City:GetHonourShopItemNum( nDuanWei );
	if ( nTableIndex < 0 or nTableIndex >= nItemNum ) then
		return 0;
	end

	-- theAction
	local theAction = City:EnumHonourShop( nTableIndex );
	if ( theAction:GetID() == 0 ) then
		return 0;
	end

	-- 实际物品数量
	local nTotal = City:GetHonourShopInfo( nTableIndex, "total" );
	if ( nTableIndex < 0 or nTableIndex >= nTotal ) then
		return 0;
	end

	-- 安全时间
	if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
		PushDebugMessage( "#{OR_PILFER_LOCK_FLAG}" );
		return 0;
	end

	-- 硬件密保
	if ( CheckPhoneMibaoAndMinorPassword() ~= 1 ) then
		return 0;
	end

	-- 等级
	local nLevel = Player:GetLevel();
	if ( nLevel < 85 ) then
		PushDebugMessage( "#{JWSD_140821_57}" );
		return 0;
	end

	-- 物品数量
	local nRemainNum = City:GetHonourShopInfo( nTableIndex, "remainnum" );
	if ( nRemainNum <= 0 ) then
		local nItemTableIndex = City:GetHonourShopInfo( nTableIndex, "tableindex" );
		local strItemName = theAction:GetName();
		local tip = ScriptGlobal_Format( "#{JWSD_140821_29}", nItemNum, strItemName );
		PushDebugMessage( tip );
		return 0;
	end

	-- 帮会
	local nGuildID = Guild:GetMyGuildDetailInfo( "ID" );
	if ( nGuildID == -1 ) then
		PushDebugMessage( "#{JWSD_140821_32}" );
		return 0;
	end

	-- 城市
	local nCityName = Guild:GetMyGuildDetailInfo( "CityName" );
	if ( nCityName == "" ) then
		PushDebugMessage( "#{JWSD_140821_33}" );
		return 0;
	end

	-- 段位
	local nMyDuanWei = City:GetWeekDuanWei();
	if ( nMyDuanWei < nDuanWei ) then
		PushDebugMessage( "#{JWSD_140821_38}" );
		return 0;
	end

	-- 荣誉值
	local nItemHonour = City:GetHonourShopInfo( nTableIndex, "honour" );
	local nMyHonour = Player:GetData( "MILITARYEXCHANGE" );
	if ( nMyHonour < nItemHonour ) then
		PushDebugMessage( "#{JWSD_140821_37}" );
		return 0;
	end

	return 1;
end


--*********************************
-- [爵位商店]购买检测
--*********************************
function JueweiShop_CheckNobilityShopBuy( uiPos )
	-- 段位数据
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		PushDebugMessage( "#{JWSD_140821_82}" );
		return 0;
		--if ( nDuanWei == 0 ) then
			--nDuanWei = nDuanWei + 2;
		--elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			--nDuanWei = nDuanWei + 1;
		--else
			--return 0;
		--end
	end

	-- 表格索引
	local nTableIndex = g_nCurPage * g_nOnePageNum + uiPos;
	local nItemNum = City:GetYuanBaoShopItemNum( nDuanWei );
	if ( nTableIndex < 0 or nTableIndex >= nItemNum ) then
		return 0;
	end

	-- 实际物品数量
	local nTotal = City:GetYuanBaoShopInfo( nTableIndex, "total" );
	if ( nTableIndex < 0 or nTableIndex >= nTotal ) then
		return 0;
	end

	-- 安全时间
	if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
		PushDebugMessage( "#{OR_PILFER_LOCK_FLAG}" );
		return 0;
	end

	-- 硬件密保
	if ( CheckPhoneMibaoAndMinorPassword() ~= 1 ) then
		return 0;
	end

	-- 等级
	local nLevel = Player:GetLevel();
	if ( nLevel < 85 ) then
		PushDebugMessage( "#{JWSD_140821_57}" );
		return 0;
	end

	-- 物品数量
	local nRemainNum = City:GetYuanBaoShopInfo( nTableIndex, "remainnum" );
	if ( nRemainNum <= 0 ) then
		local nItemTableIndex = City:GetYuanBaoShopInfo( nTableIndex, "tableindex" );
		local strItemName = theAction:GetName();
		local tip = ScriptGlobal_Format( "#{JWSD_140821_45}", nItemNum, strItemName );
		PushDebugMessage( tip );
		return 0;
	end

	-- 帮会
	local nGuildID = Guild:GetMyGuildDetailInfo( "ID" );
	if ( nGuildID == -1 ) then
		PushDebugMessage( "#{JWSD_140821_32}" );
		return 0;
	end

	-- 城市
	local nCityName = Guild:GetMyGuildDetailInfo( "CityName" );
	if ( nCityName == "" ) then
		PushDebugMessage( "#{JWSD_140821_33}" );
		return 0;
	end

	-- 段位
	local nMyDuanWei = City:GetWeekDuanWei();
	if ( nMyDuanWei < nDuanWei ) then
		PushDebugMessage( "#{JWSD_140821_38}" );
		return 0;
	end

	-- 元宝
	local nNeedYuanBao = City:GetYuanBaoShopInfo( nTableIndex, "yuanbao" );
	local nYuanBao = Player:GetData( "YUANBAO" );
	if ( nYuanBao < nNeedYuanBao ) then
		PushDebugMessage( "#{JWSD_140821_49}" );
		return 0;
	end

	return 1;
end


--*********************************
-- 购买
--*********************************
function JueweiShop_BuyItem( uiPos )
	--
	if ( uiPos < 0 or uiPos >= g_nOnePageNum ) then
		return
	end
	-- 段位数据
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		if ( nDuanWei == 0 ) then
			nDuanWei = nDuanWei + 2;
		elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			nDuanWei = nDuanWei + 1;
		else
			return 0;
		end
	end

	-- 军衔商店
	if ( g_SubTableSel == 0 ) then
		-- 检测
		if ( JueweiShop_CheckMilitaryShopBuy( uiPos ) == 1 ) then
			-- 表格索引
			local nTableIndex = g_nCurPage * g_nOnePageNum + uiPos;
			-- 批量购买
			local bMultiBuy = City:IsHonourShopMultiBuy( nTableIndex, g_NpcObjId );
			if ( bMultiBuy == 1 ) then
				SetDefaultMouse();
				return
			end
			-- 购买确认
			if ( g_BuyConfirm == 1 ) then
				local theAction = City:EnumHonourShop( nTableIndex );
				if ( theAction:GetID() ~= 0 ) then
					local nItemTableIndex = City:GetHonourShopInfo( nTableIndex, "tableindex" );
					local strItemName = theAction:GetName();
					local nNeedHonour = City:GetHonourShopInfo( nTableIndex, "honour" );
					PushEvent( "MILITARYRANKSHOPBUYCONFIRM", nTableIndex, strItemName, nNeedHonour, g_NpcObjId );
					return
				end
			end
			-- 消息
			City:DoHonourShopBuy( nTableIndex, 1 );
		end
	-- 爵位商店
	elseif ( g_SubTableSel == 1 ) then
		-- 检测
		if ( JueweiShop_CheckNobilityShopBuy( uiPos ) == 1 ) then
			-- 表格索引
			local nTableIndex = g_nCurPage * g_nOnePageNum + uiPos;
			-- 批量购买
			local bMultiBuy = City:IsYuanBaoShopMultiBuy( nTableIndex, g_NpcObjId );
			if ( bMultiBuy == 1 ) then
				SetDefaultMouse();
				return
			end
			-- 购买确认
			if ( g_BuyConfirm == 1 ) then
				local theAction = City:EnumYuanBaoShop( nTableIndex );
				if ( theAction:GetID() ~= 0 ) then
					local nItemTableIndex = City:GetYuanBaoShopInfo( nTableIndex, "tableindex" );
					local strItemName = theAction:GetName();
					local nNeedYuanBao = City:GetYuanBaoShopInfo( nTableIndex, "yuanbao" );
					PushEvent( "NOBILITYSHOPBUYCONFIRM", nTableIndex, strItemName, nNeedYuanBao, g_NpcObjId );
					return
				end
			end
			-- 消息
			City:DoYuanBaoShopBuy( nTableIndex, 1 );
		end
	end
end


--*********************************
-- 批量购买检查
--*********************************
function JueweiShop_CheckMultiBuy()
	-- 安全时间
	if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
		PushDebugMessage( "#{OR_PILFER_LOCK_FLAG}" );
		return 0;
	end

	-- 电话密保、硬件密保、畅游+保护状态
	if ( CheckPhoneMibaoAndMinorPassword() ~= 1 ) then
		return 0;
	end

	return 1;
end


--==========================================================================--
-- 响应事件
--==========================================================================--


--*********************************
-- 标签页
--*********************************
function ButtonFenYe_Click( nIndex )
	--
	if ( g_TableSel == nIndex ) then
		return
	end
	--
	if ( g_TableSel ~= 1 and g_TableSel ~= 2 ) then
		return
	end

	-- 页数
	g_nCurPage = 0
	-- 标签页
	g_TableSel = nIndex;

	-- 更新段位
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		if ( nDuanWei == 0 ) then
			nDuanWei = nDuanWei + 2;
		elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			nDuanWei = nDuanWei + 1;
		else
			return
		end
	end

	-- 更新内容
	if ( g_SubTableSel == 0 ) then
		City:UpdateHonourShopData( nDuanWei, g_TableSel );
	elseif ( g_SubTableSel == 1 ) then
		City:UpdateYuanBaoShopData( nDuanWei, g_TableSel );
	end
end


--*********************************
-- 子标签页
--*********************************
function JueweiShop_OnSubCheckButtonClicked( nSubIndex )
	--
	if ( g_SubTableSel == nSubIndex ) then
		return
	end
	--
	if ( g_SubTableSel ~= 0 and g_SubTableSel ~= 1 ) then
		return
	end

	-- 页数
	g_nCurPage = 0;
	-- 标签页
	g_SubTableSel = nSubIndex;

	-- 更新段位
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		if ( nDuanWei == 0 ) then
			nDuanWei = nDuanWei + 2;
		elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			nDuanWei = nDuanWei + 1;
		else
			return
		end
	end

	-- 更新内容
	if ( g_SubTableSel == 0 ) then
		City:UpdateHonourShopData( nDuanWei, g_TableSel );
	elseif ( g_SubTableSel == 1 ) then
		City:UpdateYuanBaoShopData( nDuanWei, g_TableSel );
	end
end


--*********************************
-- 向上翻页
--*********************************
function JueweiShop_UpPageClick()
	-- 更新段位
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		if ( nDuanWei == 0 ) then
			nDuanWei = nDuanWei + 2;
		elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			nDuanWei = nDuanWei + 1;
		else
			return
		end
	end

	--
	if ( g_SubTableSel == 0 ) then
		-- 总页数
		local nItemNum = City:GetHonourShopItemNum( nDuanWei );
		local nMaxPage = math.floor( nItemNum / g_nOnePageNum );
		if ( math.mod( nItemNum, g_nOnePageNum ) > 0 ) then
			nMaxPage = nMaxPage + 1;
		end
		-- 页数
		if ( g_nCurPage <= 0 ) then
			g_nCurPage = 0;
			return
		end
		g_nCurPage = g_nCurPage - 1;
		-- 更新
		JueWeiShop_OnUpdateHonourShop();
	elseif ( g_SubTableSel == 1 ) then
		-- 总页数
		local nItemNum = City:GetYuanBaoShopItemNum( nDuanWei );
		local nMaxPage = math.floor( nItemNum / g_nOnePageNum );
		if ( math.mod( nItemNum, g_nOnePageNum ) > 0 ) then
			nMaxPage = nMaxPage + 1;
		end
		-- 页数
		if ( g_nCurPage <= 0 ) then
			g_nCurPage = 0;
			return
		end
		g_nCurPage = g_nCurPage - 1;
		-- 更新
		JueWeiShop_OnUpdateYuanBaoShop();
	end
end


--*********************************
-- 向下翻页
--*********************************
function JueweiShop_DownPageClick()
	-- 更新段位
	local nDuanWei = City:GetWeekDuanWei();
	if ( g_TableSel == 1 ) then
		nDuanWei = nDuanWei;
	elseif ( g_TableSel == 2 ) then
		if ( nDuanWei == 0 ) then
			nDuanWei = nDuanWei + 2;
		elseif ( nDuanWei + 1 <= g_MaxDuanWei ) then
			nDuanWei = nDuanWei + 1;
		else
			return
		end
	end

	--
	if ( g_SubTableSel == 0 ) then
		-- 总页数
		local nItemNum = City:GetHonourShopItemNum( nDuanWei );
		local nMaxPage = math.floor( nItemNum / g_nOnePageNum );
		if ( math.mod( nItemNum, g_nOnePageNum ) > 0 ) then
			nMaxPage = nMaxPage + 1;
		end
		-- 页数
		if ( g_nCurPage + 1 >= nMaxPage ) then
			g_nCurPage = nMaxPage - 1;
			return
		end
		g_nCurPage = g_nCurPage + 1;
		-- 更新
		JueWeiShop_OnUpdateHonourShop();
	elseif ( g_SubTableSel == 1 ) then
		-- 总页数
		local nItemNum = City:GetYuanBaoShopItemNum( nDuanWei );
		local nMaxPage = math.floor( nItemNum / g_nOnePageNum );
		if ( math.mod( nItemNum, g_nOnePageNum ) > 0 ) then
			nMaxPage = nMaxPage + 1;
		end
		-- 页数
		if ( g_nCurPage + 1 >= nMaxPage ) then
			g_nCurPage = nMaxPage - 1;
			return
		end
		g_nCurPage = g_nCurPage + 1;
		-- 更新
		JueWeiShop_OnUpdateYuanBaoShop();
	end
end


--*********************************
-- 购买确认
--*********************************
function JueWeiShopBuyConfirm_Clicked()
	-- 购买确认
	local bConfirm = g_Controls.BuyConfirm.CheckButton : GetCheck();
	if ( bConfirm == 1 ) then
		g_Controls.BuyConfirm.CheckButton:SetCheck( 1 );
		g_BuyConfirm = 1;
	elseif ( bConfirm == 0 ) then
		g_Controls.BuyConfirm.CheckButton:SetCheck( 0 );
		g_BuyConfirm = 0;
	end
end


--*********************************
-- 批量购买
--*********************************
function JueweiShop_MultiBuyItem()
	--
	if ( JueweiShop_CheckMultiBuy() ~= 1 ) then
		return
	end

	-- 关闭UI
	if ( IsWindowShow( "NEWShop_MBuy" ) ) then
		CloseWindow( "NEWShop_MBuy", true );
	end

	-- 进入批量购买状态
	PrepearBuyMult();
	-- 醒目提示
	PushDebugMessage( "#{PLGM_150306_03}" );
end


--*********************************
-- Frame隐藏
--*********************************
function JueweiShop_OnHiden()
	-- 关闭UI
	if ( IsWindowShow( "NEWShop_MBuy" ) ) then
		CloseWindow( "NEWShop_MBuy", true );
	end

	SetDefaultMouse();
	this:Hide();
end
