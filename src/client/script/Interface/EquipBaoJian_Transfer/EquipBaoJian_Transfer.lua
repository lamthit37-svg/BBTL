local m_EquipBagIndex_A = -1
local m_EquipBagIndex_B = -1

local g_ObjServerID = -1
local g_ObjCared = -1
local g_EquipBaoJian_Transfer_Frame_UnifiedPosition

local m_ActionButton_Equip_A
local m_ActionButton_Equip_B
local m_Button_OK

local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney

local m_ExtAttrName_A = {}
local m_ExtAttrValue_A = {}
local m_ExtAttrAdd_A = {}

local m_ExtAttrName_B = {}
local m_ExtAttrValue_B = {}
local m_ExtAttrAdd_B = {}

local m_NeedMonry = { 500000 , 1000000 , 2000000 }

function EquipBaoJian_Transfer_PreLoad()
		
		this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER")
		this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER_PUTIN_EQUIP")
		this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER_RCLICK")
		this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER_REMOVE_EQUIP")
		this:RegisterEvent("MONEY_CHANGE_EX",false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false) 
		this:RegisterEvent("ZHIZUN_EQUIP_RESET_CLOSE") 
		
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
end

function EquipBaoJian_Transfer_OnLoad()
	
	g_EquipBaoJian_Transfer_Frame_UnifiedPosition = EquipBaoJian_Transfer_Frame:GetProperty( "UnifiedPosition" )
	
	m_ActionButton_Equip_A = EquipBaoJian_Transfer_BeforeIcon
	m_ActionButton_Equip_B = EquipBaoJian_Transfer_AfterIcon
	
	m_Button_OK = EquipBaoJian_Transfer_OK
	
	m_StaticText_NeedMoney =  EquipBaoJian_Transfer_WantNum
	m_StaticText_HaveJZ =  EquipBaoJian_Transfer_HaveNum
	m_StaticText_HaveMoney =  EquipBaoJian_Transfer_HaveGoldNum
	
	m_ExtAttrName_A[ 1 ] = EquipBaoJian_Transfer_BeforeAttr1
	m_ExtAttrName_A[ 2 ] = EquipBaoJian_Transfer_BeforeAttr2
	m_ExtAttrName_A[ 3 ] = EquipBaoJian_Transfer_BeforeAttr3
	m_ExtAttrName_A[ 4 ] = EquipBaoJian_Transfer_BeforeAttr4
	m_ExtAttrName_A[ 5 ] = EquipBaoJian_Transfer_BeforeAttr5
	m_ExtAttrName_A[ 6 ] = EquipBaoJian_Transfer_BeforeAttr6
	m_ExtAttrName_A[ 7 ] = EquipBaoJian_Transfer_BeforeAttr7
	m_ExtAttrName_A[ 8 ] = EquipBaoJian_Transfer_BeforeAttr8
	m_ExtAttrName_A[ 9 ] = EquipBaoJian_Transfer_BeforeAttr9
	
	m_ExtAttrValue_A[ 1 ] = EquipBaoJian_Transfer_BeforeAttr1_1
	m_ExtAttrValue_A[ 2 ] = EquipBaoJian_Transfer_BeforeAttr2_1
	m_ExtAttrValue_A[ 3 ] = EquipBaoJian_Transfer_BeforeAttr3_1
	m_ExtAttrValue_A[ 4 ] = EquipBaoJian_Transfer_BeforeAttr4_1
	m_ExtAttrValue_A[ 5 ] = EquipBaoJian_Transfer_BeforeAttr5_1
	m_ExtAttrValue_A[ 6 ] = EquipBaoJian_Transfer_BeforeAttr6_1
	m_ExtAttrValue_A[ 7 ] = EquipBaoJian_Transfer_BeforeAttr7_1
	m_ExtAttrValue_A[ 8 ] = EquipBaoJian_Transfer_BeforeAttr8_1
	m_ExtAttrValue_A[ 9 ] = EquipBaoJian_Transfer_BeforeAttr9_1
	
	m_ExtAttrAdd_A[ 1 ] = EquipBaoJian_Transfer_BeforeAttr1_2
	m_ExtAttrAdd_A[ 2 ] = EquipBaoJian_Transfer_BeforeAttr2_2
	m_ExtAttrAdd_A[ 3 ] = EquipBaoJian_Transfer_BeforeAttr3_2
	m_ExtAttrAdd_A[ 4 ] = EquipBaoJian_Transfer_BeforeAttr4_2
	m_ExtAttrAdd_A[ 5 ] = EquipBaoJian_Transfer_BeforeAttr5_2
	m_ExtAttrAdd_A[ 6 ] = EquipBaoJian_Transfer_BeforeAttr6_2
	m_ExtAttrAdd_A[ 7 ] = EquipBaoJian_Transfer_BeforeAttr7_2
	m_ExtAttrAdd_A[ 8 ] = EquipBaoJian_Transfer_BeforeAttr8_2
	m_ExtAttrAdd_A[ 9 ] = EquipBaoJian_Transfer_BeforeAttr9_2
	
	m_ExtAttrName_B[ 1 ] = EquipBaoJian_Transfer_AfterAttr1
	m_ExtAttrName_B[ 2 ] = EquipBaoJian_Transfer_AfterAttr2
	m_ExtAttrName_B[ 3 ] = EquipBaoJian_Transfer_AfterAttr3
	m_ExtAttrName_B[ 4 ] = EquipBaoJian_Transfer_AfterAttr4
	m_ExtAttrName_B[ 5 ] = EquipBaoJian_Transfer_AfterAttr5
	m_ExtAttrName_B[ 6 ] = EquipBaoJian_Transfer_AfterAttr6
	m_ExtAttrName_B[ 7 ] = EquipBaoJian_Transfer_AfterAttr7
	m_ExtAttrName_B[ 8 ] = EquipBaoJian_Transfer_AfterAttr8
	m_ExtAttrName_B[ 9 ] = EquipBaoJian_Transfer_AfterAttr9
	
	m_ExtAttrValue_B[ 1 ] = EquipBaoJian_Transfer_AfterAttr1_1
	m_ExtAttrValue_B[ 2 ] = EquipBaoJian_Transfer_AfterAttr2_1
	m_ExtAttrValue_B[ 3 ] = EquipBaoJian_Transfer_AfterAttr3_1
	m_ExtAttrValue_B[ 4 ] = EquipBaoJian_Transfer_AfterAttr4_1
	m_ExtAttrValue_B[ 5 ] = EquipBaoJian_Transfer_AfterAttr5_1
	m_ExtAttrValue_B[ 6 ] = EquipBaoJian_Transfer_AfterAttr6_1
	m_ExtAttrValue_B[ 7 ] = EquipBaoJian_Transfer_AfterAttr7_1
	m_ExtAttrValue_B[ 8 ] = EquipBaoJian_Transfer_AfterAttr8_1
	m_ExtAttrValue_B[ 9 ] = EquipBaoJian_Transfer_AfterAttr9_1
	
	m_ExtAttrAdd_B[ 1 ] = EquipBaoJian_Transfer_AfterAttr1_2
	m_ExtAttrAdd_B[ 2 ] = EquipBaoJian_Transfer_AfterAttr2_2
	m_ExtAttrAdd_B[ 3 ] = EquipBaoJian_Transfer_AfterAttr3_2
	m_ExtAttrAdd_B[ 4 ] = EquipBaoJian_Transfer_AfterAttr4_2
	m_ExtAttrAdd_B[ 5 ] = EquipBaoJian_Transfer_AfterAttr5_2
	m_ExtAttrAdd_B[ 6 ] = EquipBaoJian_Transfer_AfterAttr6_2
	m_ExtAttrAdd_B[ 7 ] = EquipBaoJian_Transfer_AfterAttr7_2
	m_ExtAttrAdd_B[ 8 ] = EquipBaoJian_Transfer_AfterAttr8_2
	m_ExtAttrAdd_B[ 9 ] = EquipBaoJian_Transfer_AfterAttr9_2
	
end

function EquipBaoJian_Transfer_OnEvent(event)
	    
	if ( event == "ZHIZUN_EQUIP_TRANSFER" )  then

		g_ObjServerID = tonumber( arg0 )
		EquipBaoJian_Transfer_Init()
		this:Show()
		g_ObjCared = -1
		g_ObjCared = DataPool : GetNPCIDByServerID( g_ObjServerID )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		return
	end
	
	if event == "ZHIZUN_EQUIP_RESET_CLOSE" then
	
		EquipBaoJian_Transfer_OnCloseClicked()
		return
		
	end
	
	if (event == "ZHIZUN_EQUIP_TRANSFER_PUTIN_EQUIP"  and this:IsVisible()) then
		if tonumber(arg0) ~= nil and tonumber(arg1) ~= nil then
			EquipBaoJian_Transfer_OnItemDragedDropFromBag( tonumber(arg0) ,tonumber(arg1))
		end
		return
	end
	
	if (event == "ZHIZUN_EQUIP_TRANSFER_RCLICK"  and this:IsVisible()) then
		if tonumber(arg0) ~= nil then
			EquipBaoJian_Transfer_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	end
	
	if (event == "ZHIZUN_EQUIP_TRANSFER_REMOVE_EQUIP"  and this:IsVisible() ) then
		if tonumber(arg0) ~= nil then
			EquipBaoJian_Transfer_OnItemDragedDropAway( tonumber(arg0) )
		end
		return
	end
	
	if (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_EquipBagIndex_A then
			EquipBaoJian_Transfer_Refresh()
		end 
		return
	end

	if event == "HIDE_ON_SCENE_TRANSED"  then
        EquipBaoJian_Transfer_CleanUp()
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		EquipBaoJian_Transfer_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipBaoJian_Transfer_On_ResetPos()
	end
	
	if (event == "MONEY_CHANGE_EX" and this:IsVisible() ) then
		m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
	
end
--关闭 或 打开 UI时 ，清空一次
function EquipBaoJian_Transfer_CleanUp()

	m_ActionButton_Equip_A:SetActionItem(-1)
	m_ActionButton_Equip_B:SetActionItem(-1)
	
	if m_EquipBagIndex_A ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex_A,0)
	end
	
	if m_EquipBagIndex_B ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex_B,0)
	end

	m_EquipBagIndex_A = -1
	m_EquipBagIndex_B = -1
	m_Button_OK:Disable()
	
	EquipBaoJian_Transfer_BeforeAttrText:SetText("")
	EquipBaoJian_Transfer_AfterAttrText:SetText("")
	
	for i = 1 , 9  do

		m_ExtAttrName_A[ i ] :SetText("")
		m_ExtAttrValue_A[ i ] :SetText("")
		m_ExtAttrAdd_A[ i ] :SetText("")	
		
		m_ExtAttrName_B[ i ] :SetText("")
		m_ExtAttrValue_B[ i ] :SetText("")
		m_ExtAttrAdd_B[ i ] :SetText("")	

	end

	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	
end

--UI恢复到第一次打开时的状态
function EquipBaoJian_Transfer_Init()
	
	EquipBaoJian_Transfer_CleanUp()
	
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
end

--UI没有装备的状态
function EquipBaoJian_Transfer_NoEqup( iSlotIdx )

	if iSlotIdx == 0 then
		
		m_ActionButton_Equip_A:SetActionItem(-1)
		m_ActionButton_Equip_B:SetActionItem(-1)
		
		if m_EquipBagIndex_A ~= -1 then
			LifeAbility : Lock_Packet_Item(m_EquipBagIndex_A,0)
		end
		
			if m_EquipBagIndex_B ~= -1 then
			LifeAbility : Lock_Packet_Item(m_EquipBagIndex_B,0)
		end

		m_EquipBagIndex_A = -1
		m_EquipBagIndex_B = -1

		m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
		m_Button_OK:Disable()
		
		EquipBaoJian_Transfer_BeforeAttrText:SetText("")
		EquipBaoJian_Transfer_AfterAttrText:SetText("")
		
		for i = 1 , 9  do

			m_ExtAttrName_A[ i ] :SetText("")
			m_ExtAttrValue_A[ i ] :SetText("")
			m_ExtAttrAdd_A[ i ] :SetText("")	
			
			m_ExtAttrName_B[ i ] :SetText("")
			m_ExtAttrValue_B[ i ] :SetText("")
			m_ExtAttrAdd_B[ i ] :SetText("")	

		end
		return 
		
	end
	
	if iSlotIdx == 1 then

		m_ActionButton_Equip_B:SetActionItem(-1)
		
		if m_EquipBagIndex_B ~= -1 then
			LifeAbility : Lock_Packet_Item(m_EquipBagIndex_B,0)
		end

		m_EquipBagIndex_B = -1
		
		m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
		m_Button_OK:Disable()
		
		EquipBaoJian_Transfer_AfterAttrText:SetText("")
		
		for i = 1 , 9  do

			m_ExtAttrName_B[ i ] :SetText("")
			m_ExtAttrValue_B[ i ] :SetText("")
			m_ExtAttrAdd_B[ i ] :SetText("")	

		end
		
		return 
		
	end
	
end

--点击Cancel
function EquipBaoJian_Transfer_OnCancelClicked(  )

	EquipBaoJian_Transfer_CleanUp()
	this:Hide()

end

--点击"X"
function EquipBaoJian_Transfer_OnCloseClicked(  )
	
	EquipBaoJian_Transfer_CleanUp()
	this:Hide()
	
end

--OnHide
function EquipBaoJian_Transfer_OnHiden()
	
	EquipBaoJian_Transfer_CleanUp()
	
end

--点击OK
function EquipBaoJian_Transfer_OnOK()

	if m_EquipBagIndex_A == -1 then
		return
	end
	
	if m_EquipBagIndex_B == -1 then
		return
	end

	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_140910_17}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	
	--是否加锁
	if PlayerPackage:IsLock( m_EquipBagIndex_A ) == 1 then
		PushDebugMessage("#{ZZZB_150811_323}")	
		return
	end
	
	--是否加锁
	if PlayerPackage:IsLock( m_EquipBagIndex_B ) == 1 then
		PushDebugMessage("#{ZZZB_150811_325}")	
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Transfer" )
		Set_XSCRIPT_ScriptID( 880036 )
		Set_XSCRIPT_Parameter( 0, g_ObjServerID )
		Set_XSCRIPT_Parameter( 1, m_EquipBagIndex_A )       				--- 物品背包索引
		Set_XSCRIPT_Parameter( 2, m_EquipBagIndex_B )       				--- 物品背包索引
		Set_XSCRIPT_Parameter( 3, 1 )       											    --- 是否目标装备升灵等级被覆盖和绑定需要确认
		Set_XSCRIPT_ParamCount( 4 )
	Send_XSCRIPT()
	
end

--刷新界面
function EquipBaoJian_Transfer_Refresh()
	
	
	--没有源装备直接清空
	if m_EquipBagIndex_A == -1 then
		EquipBaoJian_Transfer_NoEqup( 0 )
		return
	end
	
	--不是可升灵装备
	if PlayerPackage:Lua_IsBagItemBelongZZType( m_EquipBagIndex_A ) ~= 1 then
		EquipBaoJian_Transfer_NoEqup( 0 )
		return
	end
	
	--没有升灵等级
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex_A) == 0 and PlayerPackage:Lua_GetBagEquipHandMakeType(m_EquipBagIndex_A) == 0 then
		EquipBaoJian_Transfer_NoEqup( 0 )
		return
	end
	
	local theAction_A = EnumAction(m_EquipBagIndex_A, "packageitem")
	if theAction_A:GetID() == 0 then
		EquipBaoJian_Transfer_NoEqup( 0 )
		return
	end
	
	m_ActionButton_Equip_A:SetActionItem(theAction_A:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex_A,1)
	
	local nLevel_a = PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex_A)
	local nType_a = PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex_A )
	local nAddRate_a = PlayerPackage:Lua_GetBagZZItemZZRate( m_EquipBagIndex_A )
	
	local nExtAttrCount_A = PlayerPackage:Lua_GetBagZZItemExtAttrCount(m_EquipBagIndex_A)
	if nExtAttrCount_A > 9 then 
		nExtAttrCount_A = 9
	end
	
	local strTemp = ScriptGlobal_Format("#{ZZZB_150811_307}",tostring(nAddRate_a))
	EquipBaoJian_Transfer_BeforeAttrText:SetText( strTemp )
	
	for i = 1 , nExtAttrCount_A  do
		local nExtAttrName , nExtAttrValue , nExtAttrAdd = PlayerPackage:Lua_GetBagZZItemExtAttr(m_EquipBagIndex_A , i - 1 ,nType_a , nLevel_a)
		if nExtAttrName ~= "" then
			m_ExtAttrName_A[ i ] :SetText("#cFFCC00"..tostring(nExtAttrName))
			m_ExtAttrValue_A[ i ] :SetText("#cFFCC00+"..tostring(nExtAttrValue))
			m_ExtAttrAdd_A[ i ] :SetText("#H+"..tostring(nExtAttrAdd))	
		end
	end
	
	--没有源装备直接清空
	if m_EquipBagIndex_B == -1 then
		EquipBaoJian_Transfer_NoEqup( 1 )
		return
	end
	
	--不是可升灵装备
	if PlayerPackage:Lua_IsBagItemBelongZZType( m_EquipBagIndex_B ) ~= 1 then
		EquipBaoJian_Transfer_NoEqup( 1 )
		return
	end
	
	local theAction_B = EnumAction(m_EquipBagIndex_B, "packageitem")
	if theAction_B:GetID() == 0 then
		EquipBaoJian_Transfer_NoEqup( 0 )
		return
	end
	
	m_ActionButton_Equip_B:SetActionItem(theAction_B:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex_B,1)
	
	local nExtAttrCount_B = PlayerPackage:Lua_GetBagZZItemExtAttrCount(m_EquipBagIndex_B)
	if nExtAttrCount_B > 9 then 
		nExtAttrCount_B = 9
	end
	
	strTemp = ScriptGlobal_Format("#{ZZZB_150811_308}",tostring(nAddRate_a))
	EquipBaoJian_Transfer_AfterAttrText:SetText( strTemp )
	
	for i = 1 , nExtAttrCount_B  do
		local nExtAttrName , nExtAttrValue , nExtAttrAdd = PlayerPackage:Lua_GetBagZZItemExtAttr(m_EquipBagIndex_B , i - 1 ,nType_a , nLevel_a)
		if nExtAttrName ~= "" then
			m_ExtAttrName_B[ i ] :SetText("#cFFCC00"..tostring(nExtAttrName))
			m_ExtAttrValue_B[ i ] :SetText("#cFFCC00+"..tostring(nExtAttrValue))
			m_ExtAttrAdd_B[ i ] :SetText("#H+"..tostring(nExtAttrAdd))	
		end
	end
	
	local nLevel = PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex_A)
	local nType = PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex_A )
	
	if m_NeedMonry[ nType_a + 1] ~= nil then
		m_StaticText_NeedMoney:SetProperty("MoneyNumber", tostring( m_NeedMonry[ nType_a + 1]  ))
	end
	
	m_Button_OK:Enable()
	
end

--从背包拖拽到UI
function EquipBaoJian_Transfer_OnItemDragedDropFromBag( iBagIndex , iSlotIdx)
	
	--拖到源装备槽
	if iSlotIdx == 0 then
		
		--不是装备
		if PlayerPackage:Lua_IsBagItemEquip( iBagIndex ) ~= 1 then
			PushDebugMessage("#{ZZZB_150811_317}")	
			return		
		end
		
		--不是可升灵装备
		if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
			PushDebugMessage("#{ZZZB_150811_317}")	
			return
		end
		
		--没有升灵等级
		if PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex) == 0 and PlayerPackage:Lua_GetBagEquipHandMakeType(iBagIndex) == 0 then
			PushDebugMessage("#{ZZZB_150811_317}")
			return
		end
		
		--加锁
		if PlayerPackage:IsLock( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_150811_315}")	
			return
		end
		
		--释放原来的装备
		if m_EquipBagIndex_A ~= -1 then
			LifeAbility : Lock_Packet_Item(m_EquipBagIndex_A,0)
		end
		
		m_EquipBagIndex_A = iBagIndex
		
		--刷新界面
		EquipBaoJian_Transfer_Refresh()
		
		return
		
	end
	
	--拖到目标装备槽
	if iSlotIdx == 1 then
		
		--不是装备
		if PlayerPackage:Lua_IsBagItemEquip( iBagIndex ) ~= 1 then
			PushDebugMessage("#{ZZZB_150811_313}")	
			return		
		end
		
		--是武器
		if PlayerPackage:Lua_IsBagItemWeapon( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_150811_321}")	
			return		
		end
		
		--需要鉴定
		if PlayerPackage:Lua_IsBagItemNeedIdentify( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_150811_319}")	
			return		
		end
		
		--加锁
		if PlayerPackage:IsLock( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_150811_315}")	
			return
		end
		
		--没有源装备
		if m_EquipBagIndex_A == -1 then
			PushDebugMessage("#{ZZZB_150811_318}")	
			return
		end
		
		--不是可升灵装备
		if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
			PushDebugMessage("#{ZZZB_150811_313}")	
			return
		end
		
		--装备位不同
		if PlayerPackage:Lua_GetBagItemEquipPoint(m_EquipBagIndex_A) ~= PlayerPackage:Lua_GetBagItemEquipPoint(iBagIndex) then
			PushDebugMessage("#{ZZZB_150811_313}")	
			return		
		end
		
		local sl_level_a = PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex_A)
		local sl_type_a = PlayerPackage:Lua_GetBagEquipHandMakeType(m_EquipBagIndex_A)
		local sl_level_b = PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex)
		local sl_type_b = PlayerPackage:Lua_GetBagEquipHandMakeType(iBagIndex)
		
		--升灵类型 高于 源装备
		if sl_type_b > sl_type_a then
			PushDebugMessage("#{ZZZB_150811_316}")
			return
		end
		
		--升灵类型相等 升灵等级不小于源装备
		if sl_type_b == sl_type_a then
			if sl_level_b >= sl_level_a then
				PushDebugMessage("#{ZZZB_150811_316}")
				return		
			end
		end
		
		--释放原来的装备
		if m_EquipBagIndex_B ~= -1 then
			LifeAbility : Lock_Packet_Item(m_EquipBagIndex_B,0)
		end
		
		m_EquipBagIndex_B = iBagIndex
		
		--刷新界面
		EquipBaoJian_Transfer_Refresh()
		
		return

	end
	
end

--从背包内右键点击
function EquipBaoJian_Transfer_OnBagItemRClicked( iBagIndex )
	
	--源装备槽空着 ，相当于拖入源装备槽
	if m_EquipBagIndex_A == -1 then
		EquipBaoJian_Transfer_OnItemDragedDropFromBag( iBagIndex , 0)
		return
	else
		--源装备没空 ，相当于拖入目标装备槽
		EquipBaoJian_Transfer_OnItemDragedDropFromBag( iBagIndex , 1)
	end
	
end

--从ActionItem拖拽到Window之外
function EquipBaoJian_Transfer_OnItemDragedDropAway( iSlotIdx )
	
	EquipBaoJian_Transfer_NoEqup( iSlotIdx )

end

--右键单击ActionItem
function EquipBaoJian_Transfer_OnActionItemRClicked( iSlotIdx )

	EquipBaoJian_Transfer_NoEqup( iSlotIdx )

end

function EquipBaoJian_Transfer_On_ResetPos()
    EquipBaoJian_Transfer_Frame:SetProperty( "UnifiedPosition", g_EquipBaoJian_Transfer_Frame_UnifiedPosition )
end
