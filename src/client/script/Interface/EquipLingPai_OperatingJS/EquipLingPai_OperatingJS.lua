-- [四象宝珠击碎为翡翠心精设计] add by DuanXiaoTong_2014/12/29
-- PushDebugMessage
-- !!!reloadscript =EquipLingPai_OperatingJS
-- ScriptGlobal_Format
---------------------------------------------------------------------------
local g_Controls = {};									-- 控件
local g_TableSel = 1;									-- 标签页(默认选中1)
local g_GemBagIndex = -1;								-- 已放入宝石的 nBagIndex
local g_ObjCared = -1;									-- NPC ObjId
local g_NeedJiaoZi = 100000;							-- 所需交子
local g_GiveXinJingNum = {								-- 击碎获得心精数量
	"无法击碎", "6", "12", "18", "25",
	"32", "39", "48", "57", "66",
	"78", "90", "102", "118", "134",
	"150", "171", "192", "213", "240",
	"267", "294", "328", "362", "396",
	"438", "480", "522", "573", "624",
	"675", "736", "797", "858", "930",
	"1002", "1074", "1158", "1242", "1326",
	"1423", "1520", "1617", "1728", "1839",
	"1950", "2076", "2202", "2328", "2454",
};

local g_Position;		-- 位置
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function EquipLingPai_OperatingJS_PreLoad()
	this : RegisterEvent( "OPEN_RLOPPAGE" );				-- 打开UI
	this : RegisterEvent( "RL_OPJS_PACKET_RCLICK" );		-- 背包右键点击宝石
	this : RegisterEvent( "RL_OPJS_PUTIN_EQUIP" );			-- 背包拖拽放入装备
	this : RegisterEvent( "RL_OPJS_REMOVE_EQUIP" );			-- 符石击碎界面拖拽移除装备
	this : RegisterEvent( "MONEY_CHANGE_EX" , false);					-- 金币改变
	this : RegisterEvent( "MONEYJZ_CHANGE_EX" , false);				-- 交子改变
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "ADJEST_UI_POS" , false);				-- 游戏窗口尺寸发生改变
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" , false);		-- 游戏分辨率发生了变化
	this : RegisterEvent( "GAMELOGIN_SELECTCHARACTER" );	-- 选择人物
	this : RegisterEvent( "PLAYER_LEAVE_WORLD" , false);			-- 离开场景
end


--*********************************
-- OnLoad
--*********************************
function EquipLingPai_OperatingJS_OnLoad()
	g_Controls = {
		-- 框架
		Framework = EquipLingPai_OperatingJS_Frame;
		-- 标签页
		Label = {
			ShengJi 	= EquipLingPai_OperatingJS_Page1;
			XiangQian 	= EquipLingPai_OperatingJS_Page2;
			ZhaiChu 	= EquipLingPai_OperatingJS_Page3;
			JiSui 		= EquipLingPai_OperatingJS_Page4;
		};
		-- 宝石槽
		GemSlot = EquipLingPai_OperatingJS_InputIcon;
		-- 数量
		Number = EquipLingPai_OperatingJS_OutputNumber;
		-- 需要交子
		NeedJiaoZi = EquipLingPai_OperatingJSWantNum;
		-- 拥有交子
		OwnJiaoZi = EquipLingPai_OperatingJSHaveNum;
		-- 拥有金币
		OwnCoin = EquipLingPai_OperatingJS_HaveGoldNum;
		-- 确定
		BtnOK = EquipLingPai_OperatingJS_OK;
		-- 取消
		BtnCancel = EquipLingPai_OperatingJS_Cancel;
	};

	-- 初始化位置
	g_Position = g_Controls.Framework:GetProperty( "UnifiedPosition" )
end


--*********************************
-- OnEvent
--*********************************
function EquipLingPai_OperatingJS_OnEvent(event)
	--
	if ( event == "OPEN_RLOPPAGE" and tonumber( arg0 ) == 4 ) then
		-- 位置
		local nPos = Variable:GetVariable( "RL_OP_Pos" );
		if ( nPos == nil ) then
			return
		end
		-- NPC ObjId
		g_ObjCared = tonumber( arg1 );
		if ( g_ObjCared == -1 ) then
			return
		end
		this:CareObject( g_ObjCared, 1 );
		-- 显示
		EquipLingPai_OperatingJS_RefreshUI();
		this:Show();
	elseif ( event == "RL_OPJS_PACKET_RCLICK" and this:IsVisible() and tonumber( arg0 ) ~= nil ) then
		--
		local nBagIndex = tonumber( arg0 );
		EquipLingPai_OperatingJS_OnPacketRClick( nBagIndex );
	elseif ( event == "RL_OPJS_PUTIN_EQUIP" and this:IsVisible() and tonumber( arg0 ) ~= nil ) then
		--
		local nBagIndex = tonumber( arg0 );
		EquipLingPai_OperatingJS_OnItemDragedDropFromBag( nBagIndex );
	elseif ( event == "RL_OPJS_REMOVE_EQUIP" ) then
		-- 移除装备
		EquipLingPai_OperatingJS_OnItemDragedDropAway();
	elseif ( event == "MONEY_CHANGE_EX" ) then
		-- 拥有金币
		local nCoin = Player:GetData( "MONEY" );
		g_Controls.OwnCoin:SetProperty( "MoneyNumber", nCoin );
	elseif ( event == "MONEYJZ_CHANGE_EX" ) then
		-- 拥有交子
		local nJiaoZi = Player:GetData( "MONEY_JZ" );
		g_Controls.OwnJiaoZi:SetProperty( "MoneyNumber", nJiaoZi );
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 88001101 ) then
		-- 移除装备
		EquipLingPai_OperatingJS_OnItemDragedDropAway();
	elseif ( event == "ADJEST_UI_POS" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "GAMELOGIN_SELECTCHARACTER" ) then
		g_GemBagIndex = -1
	elseif ( event == "PLAYER_LEAVE_WORLD" ) then
		-- 释放原来的宝石
		if ( g_GemBagIndex ~= -1 ) then
			LifeAbility:Lock_Packet_Item( g_GemBagIndex, 0 );
			g_GemBagIndex = -1;
		end
	end
end


--*********************************
-- 清空UI
--*********************************
function EquipLingPai_OperatingJS_CleanupUIControls()
	-- 标签页
	g_Controls.Label.ShengJi:SetCheck( 0 );
	g_Controls.Label.XiangQian:SetCheck( 0 );
	g_Controls.Label.ZhaiChu:SetCheck( 0 );
	g_Controls.Label.JiSui:SetCheck( 1 );
	-- 宝石槽
	g_Controls.GemSlot:SetActionItem( -1 );
	-- 数量
	g_Controls.Number:SetText( "" );
	-- 需要交子
	g_Controls.NeedJiaoZi:SetProperty( "MoneyNumber", 0 );
	-- 拥有交子
	g_Controls.OwnJiaoZi:SetProperty( "MoneyNumber", 0 );
	-- 拥有金币
	g_Controls.OwnCoin:SetProperty( "MoneyNumber", 0 );
end


--*********************************
-- 刷新UI
--*********************************
function EquipLingPai_OperatingJS_RefreshUI()
	-- 清空UI
	EquipLingPai_OperatingJS_CleanupUIControls();

	if ( g_GemBagIndex ~= -1 ) then
		-- 宝石槽
		local theAction = EnumAction( g_GemBagIndex, "packageitem" );
		if ( theAction:GetID() ~= 0 ) then
			g_Controls.GemSlot:SetActionItem( theAction:GetID() );
			LifeAbility:Lock_Packet_Item( g_GemBagIndex, 1 );
		end
		-- 数量
		local nLevel = PlayerPackage:Lua_GetBagItemRsLevel( g_GemBagIndex );
		g_Controls.Number:SetText( g_GiveXinJingNum[ nLevel ] );
		-- 需要交子
		g_Controls.NeedJiaoZi:SetProperty( "MoneyNumber", g_NeedJiaoZi );
	end
	-- 拥有交子
	local nJiaoZi = Player:GetData( "MONEY_JZ" );
	g_Controls.OwnJiaoZi:SetProperty( "MoneyNumber", nJiaoZi );
	-- 拥有金币
	local nCoin = Player:GetData( "MONEY" );
	g_Controls.OwnCoin:SetProperty( "MoneyNumber", nCoin );
end


--*********************************
-- 背包右键点击宝石
--*********************************
function EquipLingPai_OperatingJS_OnPacketRClick( nBagIndex )
	--
	if ( nBagIndex == -1 ) then
		return
	end

	-- 四象宝珠
	if ( PlayerPackage:Lua_IsBagItemRS( nBagIndex ) ~= 1 ) then
		PushDebugMessage( "#{JSBZ_141226_12}" );
		return
	end

	-- 加锁
	if ( PlayerPackage:IsLock( nBagIndex ) == 1 ) then
		PushDebugMessage( "#{JSBZ_141226_13}" );
		return
	end

	-- 宝石等级
	local nLevel = PlayerPackage:Lua_GetBagItemRsLevel( nBagIndex );
	if ( nLevel < 2 ) then
		PushDebugMessage( "#{JSBZ_141226_14}" );
		return
	end


	-- 释放原来的宝石
	if ( g_GemBagIndex ~= -1 ) then
		LifeAbility:Lock_Packet_Item( g_GemBagIndex, 0 );
	end

	-- 保存 nBagIndex
	g_GemBagIndex = nBagIndex;
	if ( g_GemBagIndex == -1 ) then
		return
	end

	-- 刷新UI
	EquipLingPai_OperatingJS_RefreshUI();
end


--*********************************
-- 从背包拖拽
--*********************************
function EquipLingPai_OperatingJS_OnItemDragedDropFromBag( nBagIndex )
	--
	if ( nBagIndex == -1 ) then
		return
	end

	-- 四象宝珠
	if ( PlayerPackage:Lua_IsBagItemRS( nBagIndex ) ~= 1 ) then
		PushDebugMessage( "#{JSBZ_141226_12}" );
		return
	end

	-- 加锁
	if ( PlayerPackage:IsLock( nBagIndex ) == 1 ) then
		PushDebugMessage( "#{JSBZ_141226_13}" );
		return
	end

	-- 宝石等级
	local nLevel = PlayerPackage:Lua_GetBagItemRsLevel( nBagIndex );
	if ( nLevel < 2 ) then
		PushDebugMessage( "#{JSBZ_141226_14}" );
		return
	end


	-- 释放原来的宝石
	if ( g_GemBagIndex ~= -1 ) then
		LifeAbility:Lock_Packet_Item( g_GemBagIndex, 0 );
	end

	-- 保存 nBagIndex
	g_GemBagIndex = nBagIndex;
	if ( g_GemBagIndex == -1 ) then
		return
	end

	-- 刷新UI
	EquipLingPai_OperatingJS_RefreshUI();
end


--*********************************
-- 移除装备
--*********************************
function EquipLingPai_OperatingJS_OnItemDragedDropAway()
	-- 释放原来的宝石
	if ( g_GemBagIndex ~= -1 ) then
		LifeAbility:Lock_Packet_Item( g_GemBagIndex, 0 );
		g_GemBagIndex = -1;
	end
	-- 刷新UI
	EquipLingPai_OperatingJS_RefreshUI();
end


--********************************
-- 击碎检查
--********************************
function EquipLingPai_OperatingJS_CheckShredding()
	-- 安全时间
	if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
		PushDebugMessage( "#{OR_PILFER_LOCK_FLAG}" );
		return 0;
	end

	-- 全沉迷或半沉迷
	if ( IsInFatigueState() <= 0 ) then
		PushDebugMessage( "#{FCMX_90609_22}" );
		return 0;
	end

	-- 硬件密保, 畅游+, 电话密保, 二级密保
	if ( CheckPhoneMibaoAndMinorPassword() ~= 1 ) then
		return 0;
	end

	-- 四象宝珠
	if ( g_GemBagIndex == -1 ) then
		PushDebugMessage( "#{JSBZ_141226_15}" );
		return 0;
	end

	-- 加锁
	if ( PlayerPackage:IsLock( g_GemBagIndex ) == 1 ) then
		PushDebugMessage( "#{JSBZ_141226_16}" );
		return 0;
	end

	-- 宝石等级
	local nLevel = PlayerPackage:Lua_GetBagItemRsLevel( g_GemBagIndex );
	if ( nLevel < 2 ) then
		PushDebugMessage( "#{JSBZ_141226_17}" );
		return 0;
	end

	-- 交子
	local nCoin = Player:GetData( "MONEY" );
	local nJiaoZi = Player:GetData( "MONEY_JZ" );
	if ( nCoin + nJiaoZi < g_NeedJiaoZi ) then
		PushDebugMessage( "#{JSBZ_141226_18}" );
		return 0;
	end


	return 1;
end


--==========================================================================--
-- 响应事件
--==========================================================================--


--*********************************
-- 关闭
--*********************************
function EquipLingPai_OperatingJS_OnCloseClicked()
	-- 释放原来的宝石
	if ( g_GemBagIndex ~= -1 ) then
		LifeAbility:Lock_Packet_Item( g_GemBagIndex, 0 );
		g_GemBagIndex = -1;
	end
	-- 刷新UI
	EquipLingPai_OperatingJS_RefreshUI();
	-- 隐藏UI
	this:Hide();
	--
	g_ObjCared = -1
end


--*********************************
-- 隐藏
--*********************************
function EquipLingPai_OperatingJS_OnHiden()
	-- 释放原来的宝石
	if ( g_GemBagIndex ~= -1 ) then
		LifeAbility:Lock_Packet_Item( g_GemBagIndex, 0 );
		g_GemBagIndex = -1;
	end
	--
	g_ObjCared = -1
end


--*********************************
-- 标签页
--*********************************
function EquipLingPai_OperatingJS_OnPageButtonClicked( nIndex )
	--
	if ( g_ObjCared == -1 ) then
		return
	end
	
	if nIndex == 3 or nIndex == 4 then
		if IsZbs2018SpeicalServer() >= 1 then
			PushDebugMessage("#{WCBS_180307_20}")
			return
		end
	end

	-- 打开UI
	Lua_OpenRlOpPage( nIndex, g_ObjCared );

	-- 清空UI
	EquipLingPai_OperatingJS_CleanupUIControls();

	-- 释放原来的宝石
	if ( g_GemBagIndex ~= -1 ) then
		LifeAbility:Lock_Packet_Item( g_GemBagIndex, 0 );
		g_GemBagIndex = -1;
	end

end


--********************************
-- ActionButton
--********************************
function EquipLingPai_OperatingJS_OnActionItemRClicked()
	-- 移除装备
	EquipLingPai_OperatingJS_OnItemDragedDropAway();
end


--********************************
-- 确定
--********************************
function EquipLingPai_OperatingJS_OnOkClicked()
	-- 检查
	if ( EquipLingPai_OperatingJS_CheckShredding() ~= 1 ) then
		return
	end

	-- 击碎
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name( "ShreddingGem" );
		Set_XSCRIPT_ScriptID( 880011 );
		Set_XSCRIPT_Parameter( 0, g_GemBagIndex );
		Set_XSCRIPT_ParamCount( 1 );
	Send_XSCRIPT();

end


--********************************
-- 取消
--********************************
function EquipLingPai_OperatingJS_OnCancelClicked()
	-- 移除装备
	EquipLingPai_OperatingJS_OnItemDragedDropAway();
	-- 隐藏UI
	this:Hide();
	--
	g_ObjCared = -1
end
