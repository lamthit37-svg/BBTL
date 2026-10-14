local m_EquipBagIndex = -1

local g_ObjCared = -1
local g_HaoXiaYin_Update_Frame_UnifiedPosition

local g_ButtonState = {
	[1] = { 2, 3, 4 ,1},
	[2] = { 1, 3, 4, 2},
	[3] = { 1, 2, 4, 3},
	[4] = { 1, 2, 3, 4},
}

local g_ButtonText = {

	[1] = "#{HXYSJ_141031_157}",	--"青龙"
	[2] = "#{HXYSJ_141031_158}",	--"白虎"
	[3] = "#{HXYSJ_141031_159}"	,	--"朱雀"
	[4] = "#{HXYSJ_141031_160}",	--"玄武"

}

local g_RadioButton = {}
local g_RadioButtonText = {}

local m_ActionButton_Equip
local m_Button_OK

local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney


function HaoXiaYin_Update_PreLoad()
		this:RegisterEvent("OPEN_HXY_SWITCH")
		this:RegisterEvent("HXY_SWITCH_PUTIN_EQUIP")
		this:RegisterEvent("HXY_SWITCH_PACKET_RCLICK")
		this:RegisterEvent("HXY_SWITCH_REMOVE_EQUIP")
		this:RegisterEvent("MONEY_CHANGE_EX",false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false) 
		
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)


		this:RegisterEvent("ADJEST_UI_POS",false)
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
end

function HaoXiaYin_Update_OnLoad()
	g_HaoXiaYin_Update_Frame_UnifiedPosition = HaoXiaYin_Update_Frame:GetProperty( "UnifiedPosition" )
	
	m_ActionButton_Equip = HaoXiaYin_Update_InputIcon
	
	g_RadioButton[ 1 ] = HaoXiaYin_Update_SuoFirst
	g_RadioButton[ 2 ] = HaoXiaYin_Update_SuoSecond
	g_RadioButton[ 3 ] = HaoXiaYin_Update_SuoThird
	g_RadioButton[ 4 ] = HaoXiaYin_Update_SuoFourth
	
	g_RadioButtonText[ 1 ] = HaoXiaYin_Update_SuoFirstText
	g_RadioButtonText[ 2 ] = HaoXiaYin_Update_SuoSecondText
	g_RadioButtonText[ 3 ] = HaoXiaYin_Update_SuoThirdText
	g_RadioButtonText[ 4 ] = HaoXiaYin_Update_SuoFourthText
	
	m_Button_OK = HaoXiaYin_Update_OK
	
	m_StaticText_NeedMoney =  HaoXiaYin_Update_Money
	m_StaticText_HaveJZ =  HaoXiaYin_Update_Jiaozi
	m_StaticText_HaveMoney =  HaoXiaYin_Update_SelfMoney
	
	
end

function HaoXiaYin_Update_OnEvent(event)
	    
	if event == "OPEN_HXY_SWITCH" then
		local nObjServerID = tonumber(arg0)
		HaoXiaYin_Update_Init()
		this:Show()
		g_ObjCared = -1
		g_ObjCared = DataPool:GetNPCIDByServerID(nObjServerID)
		if g_ObjCared == -1 then
			return
		end
		this:CareObject(g_ObjCared, 1)
		return
	end
	
	if (event == "HXY_SWITCH_PUTIN_EQUIP"  and this:IsVisible()) then
		if arg0 ~= nil then
			HaoXiaYin_Update_OnItemDragedDropFromBag( tonumber(arg0) )
		end
		return
	end
	
	if (event == "HXY_SWITCH_PACKET_RCLICK"  and this:IsVisible()) then
		if arg0 ~= nil then
			HaoXiaYin_Update_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	end
	
	if (event == "HXY_SWITCH_REMOVE_EQUIP"  and this:IsVisible() ) then
		HaoXiaYin_Update_OnItemDragedDropAway()
		return
	end
	
	if (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_EquipBagIndex then
			HaoXiaYin_Update_Refresh()
		end 
		return
	end

	if event == "HIDE_ON_SCENE_TRANSED"  then
	
            HaoXiaYin_Update_CleanUp()
			this:Hide()
	
	elseif (event == "ADJEST_UI_POS" ) then
		HaoXiaYin_Update_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HaoXiaYin_Update_On_ResetPos()
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
function HaoXiaYin_Update_CleanUp()

	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
	m_nCurrentSelect = 0
	m_Button_OK:Disable()
	
	for i =1 ,4 do
		g_RadioButtonText[ i ]:SetText( g_ButtonText[ i ])
		g_RadioButton[ i ]:Disable()
		g_RadioButton[ i ]:SetCheck(0)
		g_RadioButtonText[ i ]:Disable()
	end
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")

	
end
--UI恢复到第一次打开时的状态
function HaoXiaYin_Update_Init()
	
	HaoXiaYin_Update_CleanUp()
	
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
end
--UI没有装备的状态
function HaoXiaYin_Update_NoEqup()

	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
	m_nCurrentSelect = 0

	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	m_Button_OK:Disable()
	
	for i =1 ,4 do
		g_RadioButtonText[ i ]:SetText( g_ButtonText[ i ])
		g_RadioButton[ i ]:Disable()
		g_RadioButton[ i ]:SetCheck(0)
		g_RadioButtonText[ i ]:Disable()
	end
	
end

function HaoXiaYin_Update_OnRadioButtonClicked(nIdx)
	
	m_nCurrentSelect = nIdx
	
end
--点击Cancel
function HaoXiaYin_Update_OnCancelClicked(  )

	HaoXiaYin_Update_CleanUp()
	this:Hide()

end
--点击"X"
function HaoXiaYin_Update_OnCloseClicked(  )

	HaoXiaYin_Update_CleanUp()
	this:Hide()
	
end
--OnHide
function HaoXiaYin_Update_OnHiden()
	
	HaoXiaYin_Update_CleanUp()
	
end
--点击OK
function HaoXiaYin_Update_OnOK()
	
	if m_EquipBagIndex == -1 then
		PushDebugMessage("#{HXYSJ_141031_167}")
		return
	end
	
	if m_nCurrentSelect < 1 or m_nCurrentSelect > 4 then
		PushDebugMessage("#{HXYSJ_141031_168}")
		return 
	end

	local nType = PlayerPackage:Lua_GetBagItemHxyType( m_EquipBagIndex ) 
	if nType and nType > 0 and nType <= 4 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "HXY_SwitchType" )
			Set_XSCRIPT_ScriptID( 880006 )
			Set_XSCRIPT_Parameter( 0, m_EquipBagIndex     )       --- 物品背包索引
			Set_XSCRIPT_Parameter( 1,g_ButtonState[nType][m_nCurrentSelect]     ) 
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	end
	
end
--刷新界面
function HaoXiaYin_Update_Refresh()
	
	if m_EquipBagIndex == -1 then
	
		HaoXiaYin_Update_NoEqup()
		return
		
	end
	
	local theAction = EnumAction(m_EquipBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		
		HaoXiaYin_Update_NoEqup()
		return
		
	end
	
	m_ActionButton_Equip:SetActionItem(theAction:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "10000")
	
	local nType = PlayerPackage:Lua_GetBagItemHxyType( m_EquipBagIndex ) 
	
	if nType and nType > 0 and nType <= 4 then
		for i =1 ,4 do
			g_RadioButtonText[ i ]:SetText( g_ButtonText[ g_ButtonState[nType][ i ] ])
			if i == 4 then
				g_RadioButton[ i ]:Disable()
			else
				g_RadioButton[ i ]:Enable()
			end

		end
	else
		for i =1 ,4 do
			g_RadioButtonText[ i ]:SetText( g_ButtonText[ i ])
			g_RadioButton[ i ]:Disable()
			g_RadioButton[ i ]:SetCheck(0)
			g_RadioButtonText[ i ]:Disable()
		end
	end
	
	m_Button_OK:Enable()
	
end
--从背包拖拽到UI
function HaoXiaYin_Update_OnItemDragedDropFromBag( iBagIndex )
	
	if PlayerPackage:Lua_IsBagItemHXY( iBagIndex ) ~= 1 then
		PushDebugMessage("#{HXYSJ_141031_163}")	--请选择一个豪侠印放入
		return
	end
		
	--是否加锁
	if PlayerPackage:IsLock( iBagIndex ) == 1 then
		PushDebugMessage("#{Item_Locked}")	--道具已上锁
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	HaoXiaYin_Update_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	HaoXiaYin_Update_Refresh()
	
end
--从背包内右键点击
function HaoXiaYin_Update_OnBagItemRClicked( iBagIndex )
	
	if PlayerPackage:Lua_IsBagItemHXY( iBagIndex ) ~= 1 then
		PushDebugMessage("#{HXYSJ_141031_163}")	--请选择一个豪侠印放入
		return
	end
		
	--是否加锁
	if PlayerPackage:IsLock( iBagIndex ) == 1 then
		PushDebugMessage("#{Item_Locked}")	--道具已上锁
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	HaoXiaYin_Update_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	HaoXiaYin_Update_Refresh()

end
--从ActionItem拖拽到Window之外
function HaoXiaYin_Update_OnItemDragedDropAway(  )
	
	HaoXiaYin_Update_NoEqup()

end
--右键单击ActionItem
function HaoXiaYin_Update_OnActionItemRClicked(  )
	
	HaoXiaYin_Update_NoEqup()

end

function HaoXiaYin_Update_On_ResetPos()
    HaoXiaYin_Update_Frame:SetProperty( "UnifiedPosition", g_HaoXiaYin_Update_Frame_UnifiedPosition )
end
