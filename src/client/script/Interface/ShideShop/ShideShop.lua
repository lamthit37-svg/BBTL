--师德商店
local g_Controls = {};									-- 控件
local g_TableSel = 1;									-- 标签页(默认选中1)
local g_SubTableSel = 0;								-- 子标签页(默认选中1)--废弃之
local g_BuyConfirm = 1;									-- 购买确认(两个商店共享)
local g_nCurPage = 0;									-- 默认第1页
local g_nOnePageNum = 18;								-- 一页显示18项
local g_NpcObjId = 0;									-- NpcId
local g_MaxDuanWei = 4;								-- 5个段位
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
function ShideShop_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "OPEN_SHIDESHOP" );				-- 打开师德商店
	this : RegisterEvent( "UPDATE_SHIDESHOPINFO" );		-- 师德商店
	this : RegisterEvent( "UPDATE_SHIDEVALUE" );			-- 师德
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" , false);		-- 游戏分辨率发生了变化
	this : RegisterEvent( "GAMELOGIN_SELECTCHARACTER" );	-- 选择人物
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" , false);			-- 离开场景
end


--*********************************
-- OnLoad
--*********************************
function ShideShop_OnLoad()
	g_Controls = {
		-- 框架
		Framework = ShideShop_Frame;
		-- 标签页
		Table = {
			CurLevel 	= ShideShop_Button01;
			NextLevel	= ShideShop_Button02;
		};
		-- 介绍
		Introduce = ShideShop_Bk_Explain1;
		-- 购买确认
		BuyConfirm = {
			BackGround = ShideShop_Bk4;
			CheckButton = ShideShop_querengoumaiBind;
		};
		-- 页码
		PageInfo = {
			-- 页数
			CurPage = ShideShop_CurrentlyPage;
			-- 背景
			PageBackGround = ShideShop_Bk_Bk;
			-- 向上翻页
			PageUp = ShideShop_UpPage;
			-- 向下翻页
			PageDown = ShideShop_DownPage;
		};
		-- 师德
		Shide = ShideShop_Text1;
		-- 物品
		ItemInfo = {
			-- 图标
			ActiveButton = {
				[1] = ShideShop_Item1,
				[2] = ShideShop_Item2,
				[3] = ShideShop_Item3,
				[4] = ShideShop_Item4,
				[5] = ShideShop_Item5,
				[6] = ShideShop_Item6,
				[7] = ShideShop_Item7,
				[8] = ShideShop_Item8,
				[9] = ShideShop_Item9,
				[10] = ShideShop_Item10,
				[11] = ShideShop_Item11,
				[12] = ShideShop_Item12,
				[13] = ShideShop_Item13,
				[14] = ShideShop_Item14,
				[15] = ShideShop_Item15,
				[16] = ShideShop_Item16,
				[17] = ShideShop_Item17,
				[18] = ShideShop_Item18,
			};
			-- 蒙红
			Mask = {
				[1] = ShideShop_Item1_Mask,
				[2] = ShideShop_Item2_Mask,
				[3] = ShideShop_Item3_Mask,
				[4] = ShideShop_Item4_Mask,
				[5] = ShideShop_Item5_Mask,
				[6] = ShideShop_Item6_Mask,
				[7] = ShideShop_Item7_Mask,
				[8] = ShideShop_Item8_Mask,
				[9] = ShideShop_Item9_Mask,
				[10] = ShideShop_Item10_Mask,
				[11] = ShideShop_Item11_Mask,
				[12] = ShideShop_Item12_Mask,
				[13] = ShideShop_Item13_Mask,
				[14] = ShideShop_Item14_Mask,
				[15] = ShideShop_Item15_Mask,
				[16] = ShideShop_Item16_Mask,
				[17] = ShideShop_Item17_Mask,
				[18] = ShideShop_Item18_Mask,
			};
			-- 售罄
			SellOut = {
				[1] = ShideShop_ItemIcon_1,
				[2] = ShideShop_ItemIcon_2,
				[3] = ShideShop_ItemIcon_3,
				[4] = ShideShop_ItemIcon_4,
				[5] = ShideShop_ItemIcon_5,
				[6] = ShideShop_ItemIcon_6,
				[7] = ShideShop_ItemIcon_7,
				[8] = ShideShop_ItemIcon_8,
				[9] = ShideShop_ItemIcon_9,
				[10] = ShideShop_ItemIcon_10,
				[11] = ShideShop_ItemIcon_11,
				[12] = ShideShop_ItemIcon_12,
				[13] = ShideShop_ItemIcon_13,
				[14] = ShideShop_ItemIcon_14,
				[15] = ShideShop_ItemIcon_15,
				[16] = ShideShop_ItemIcon_16,
				[17] = ShideShop_ItemIcon_17,
				[18] = ShideShop_ItemIcon_18,
			};
			-- 物品名称
			ItemName = {
				[1] = ShideShop_ItemInfo1_Text,
				[2] = ShideShop_ItemInfo2_Text,
				[3] = ShideShop_ItemInfo3_Text,
				[4] = ShideShop_ItemInfo4_Text,
				[5] = ShideShop_ItemInfo5_Text,
				[6] = ShideShop_ItemInfo6_Text,
				[7] = ShideShop_ItemInfo7_Text,
				[8] = ShideShop_ItemInfo8_Text,
				[9] = ShideShop_ItemInfo9_Text,
				[10] = ShideShop_ItemInfo10_Text,
				[11] = ShideShop_ItemInfo11_Text,
				[12] = ShideShop_ItemInfo12_Text,
				[13] = ShideShop_ItemInfo13_Text,
				[14] = ShideShop_ItemInfo14_Text,
				[15] = ShideShop_ItemInfo15_Text,
				[16] = ShideShop_ItemInfo16_Text,
				[17] = ShideShop_ItemInfo17_Text,
				[18] = ShideShop_ItemInfo18_Text,
			};
			-- 师德兑换值
			Shide = {
				[1] = ShideShop_ItemInfo1_GB,
				[2] = ShideShop_ItemInfo2_GB,
				[3] = ShideShop_ItemInfo3_GB,
				[4] = ShideShop_ItemInfo4_GB,
				[5] = ShideShop_ItemInfo5_GB,
				[6] = ShideShop_ItemInfo6_GB,
				[7] = ShideShop_ItemInfo7_GB,
				[8] = ShideShop_ItemInfo8_GB,
				[9] = ShideShop_ItemInfo9_GB,
				[10] = ShideShop_ItemInfo10_GB,
				[11] = ShideShop_ItemInfo11_GB,
				[12] = ShideShop_ItemInfo12_GB,
				[13] = ShideShop_ItemInfo13_GB,
				[14] = ShideShop_ItemInfo14_GB,
				[15] = ShideShop_ItemInfo15_GB,
				[16] = ShideShop_ItemInfo16_GB,
				[17] = ShideShop_ItemInfo17_GB,
				[18] = ShideShop_ItemInfo18_GB,
			};
		};
	};
end


--*********************************
-- OnEvent
--*********************************
function ShideShop_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 20150609 ) then
		-- 打开UI
		local bShow = tonumber( Get_XParam_INT( 0 ) );
		if ( bShow == 1 ) then
			if ( this:IsVisible() ) then
				return
			end
			AskShideShopData();
			-- 页数
			g_nCurPage = 0;
		else
			this:Hide();
		end
		-- 关心NPC
		g_NpcObjId = Target:GetServerId2ClientId( tonumber( Get_XParam_INT( 1 ) ) );
		this:CareObject( g_NpcObjId, 1, "ShideShop" );
	elseif ( event == "OPEN_SHIDESHOP" ) then
		g_TableSel = 1;
		ShideShop_OnUpdateShop();
		this:Show();
	elseif ( event == "UPDATE_SHIDESHOPINFO" ) then
		if ( this:IsVisible()) then
			ShideShop_OnUpdateShop();
		end
	elseif ( event == "UPDATE_SHIDEVALUE") then
		if ( this:IsVisible() ) then
			ShideShop_OnUpdateShop();
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
function ShideShop_CleanupUIControls()
	-- 关闭UI
	if ( IsWindowShow( "NEWShop_MBuy" ) ) then
		CloseWindow( "NEWShop_MBuy", true );
	end
	SetDefaultMouse();

	-- 标签页
	g_Controls.Table.CurLevel:Show();
	g_Controls.Table.NextLevel:Show();
	if ( g_TableSel == 1 ) then
		g_Controls.Table.CurLevel:SetCheck( 1 );
		g_Controls.Table.NextLevel:SetCheck( 0 );
	elseif ( g_TableSel == 2 ) then
		g_Controls.Table.CurLevel:SetCheck( 0 );
		g_Controls.Table.NextLevel:SetCheck( 1 );
	end
	-- 介绍
	g_Controls.Introduce:SetText( "" );
	-- 购买确认
	if ( g_TableSel == 1 ) then
		g_Controls.BuyConfirm.BackGround:Show();
		ShideShop_MBuy:Show();
	elseif ( g_TableSel == 2 ) then
		g_Controls.BuyConfirm.BackGround:Hide();
		ShideShop_MBuy:Hide();
	end
	if ( g_BuyConfirm == 1 ) then
		g_Controls.BuyConfirm.CheckButton:SetCheck( 1 );
	else
		g_Controls.BuyConfirm.CheckButton:SetCheck( 0 );
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
		g_Controls.ItemInfo.Shide[ i ]:SetText( "" );
	end
	-- 师德
	g_Controls.Shide:SetText( "" );
end


--*********************************
-- 显示
--*********************************
function ShideShop_OnUpdateShop()
	-- 清空控件
	ShideShop_CleanupUIControls();

	-- 段位数据
	local nDuanWei = WenDingUI:GetShideLevel();
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

	-- 标签页
	if ( g_TableSel == 1 and nDuanWei >= g_MaxDuanWei ) then
		g_Controls.Table.NextLevel:Hide();
	end
	-- 介绍
	local ShideLevelValue = {3000,6000,9000}
	if ( g_TableSel == 1 ) then
		ShideShop_Button01:SetToolTip(ScriptGlobal_Format("#{SDSD_150514_07}",WenDingUI:GetHistoryShide()))
		if nDuanWei < g_MaxDuanWei then
			ShideShop_Button02:SetToolTip(ScriptGlobal_Format("#{SDSD_150514_08}",ShideLevelValue[nDuanWei]))
			g_Controls.Introduce : SetText( ScriptGlobal_Format("#{SDSD_150514_05}",nDuanWei,ShideLevelValue[nDuanWei],WenDingUI:GetHistoryShide()) );
		else
			g_Controls.Introduce : SetText( ScriptGlobal_Format("#{SDSD_150514_43}",nDuanWei) );
		end		
	elseif ( g_TableSel == 2 ) then
		g_Controls.Introduce : SetText( ScriptGlobal_Format("#{SDSD_150514_05}",nDuanWei-1,ShideLevelValue[nDuanWei-1],WenDingUI:GetHistoryShide()) );
		ShideShop_Button01:SetToolTip(ScriptGlobal_Format("#{SDSD_150514_07}",WenDingUI:GetHistoryShide()))
		ShideShop_Button02:SetToolTip(ScriptGlobal_Format("#{SDSD_150514_08}",ShideLevelValue[nDuanWei-1]))
	end	
	-- 页数
	local nItemNum = WenDingUI:GetShideShopItemNum( nDuanWei );
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
		local theAction = WenDingUI:EnumShideShop( i );
		local nIndex = math.mod( i, g_nOnePageNum ) + 1;
		if ( theAction:GetID() ~= 0 ) then
			g_Controls.ItemInfo.ActiveButton[ nIndex ]:SetActionItem( theAction:GetID() );
			local nRemainNum = WenDingUI:GetShideShopInfo( i, "remainnum" );
			if ( nRemainNum <= 0 ) then
				g_Controls.ItemInfo.Mask[ nIndex ]:Show();
				g_Controls.ItemInfo.SellOut[ nIndex ]:Show();
			end
			if ( theAction:GetItemColorInShop() ~= "" ) then
				g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( "#{JWSD_140821_75}"..theAction:GetName() );
			end
			g_Controls.ItemInfo.Shide[ nIndex ]:SetText( "#{SDSD_150514_09}"..tostring( WenDingUI:GetShideShopInfo( i, "shide" ) ) );
		else
			g_Controls.ItemInfo.ActiveButton[ nIndex ]:SetActionItem( -1 );
			g_Controls.ItemInfo.Mask[ nIndex ]:Hide();
			g_Controls.ItemInfo.SellOut[ nIndex ]:Hide();
			g_Controls.ItemInfo.ItemName[ nIndex ]:SetText( "" );
			g_Controls.ItemInfo.Shide[ nIndex ]:SetText( "" );
		end
	end
	-- 师德
	g_Controls.Shide:SetText( ScriptGlobal_Format("#{SDSD_150514_17}",Player:GetData( "SHIDEVALUE" ) ));
end

--*********************************
-- 购买
--*********************************
function ShideShop_BuyItem( uiPos )
	--
	if ( uiPos < 0 or uiPos >= g_nOnePageNum ) then
		return
	end
	-- 段位数据
	local nDuanWei = WenDingUI:GetShideLevel();
	if ( g_TableSel == 2 ) then		
		PushDebugMessage( "#{SDSD_150514_18}" );
		return
	end
	-- 表格索引
	local nTableIndex = g_nCurPage * g_nOnePageNum + uiPos;
	-- 批量购买
	local bMultiBuy = WenDingUI:IsShideShopMultiBuy( nTableIndex, g_NpcObjId );
	if ( bMultiBuy == 1 ) then
		SetDefaultMouse();
		return
	end
	-- 购买确认
	if ( g_BuyConfirm == 1 ) then
		local theAction = WenDingUI:EnumShideShop( nTableIndex );
		if ( theAction:GetID() ~= 0 ) then
			local nItemTableIndex = WenDingUI:GetShideShopInfo( nTableIndex, "tableindex" );
			local strItemName = theAction:GetName();
			local nNeedHonour = WenDingUI:GetShideShopInfo( nTableIndex, "shide" );
			PushEvent( "SHIDESHOPBUYCONFIRM", nTableIndex, strItemName, nNeedHonour, g_NpcObjId );
			return
		end
	end
	-- 消息
	WenDingUI:DoShideShopBuy( nTableIndex, 1 );	
	
end

--==========================================================================--
-- 响应事件
--==========================================================================--


--*********************************
-- 标签页
--*********************************
function ShideShop_ButtonFenYe_Click( nIndex )
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
	local nDuanWei = WenDingUI:GetShideLevel();
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
	WenDingUI:UpdateShideShopData( nDuanWei, g_TableSel );
	
end


--*********************************
-- 向上翻页
--*********************************
function ShideShop_UpPageClick()
	-- 更新师德
	local nDuanWei = WenDingUI:GetShideLevel();
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
	
	-- 总页数
	local nItemNum = WenDingUI:GetShideShopItemNum( nDuanWei );
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
	ShideShop_OnUpdateShop();
	
end


--*********************************
-- 向下翻页
--*********************************
function ShideShop_DownPageClick()
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
	ShideShop_OnUpdateShop();
end


--*********************************
-- 购买确认
--*********************************
function ShideShopBuyConfirm_Clicked()
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
function ShideShop_MultiBuyItem()
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
function ShideShop_OnHiden()
	-- 关闭UI
	if ( IsWindowShow( "NEWShop_MBuy" ) ) then
		CloseWindow( "NEWShop_MBuy", true );
	end

	SetDefaultMouse();
	this:Hide();
end
