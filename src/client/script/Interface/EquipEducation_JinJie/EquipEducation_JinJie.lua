local m_EquipBagIndex = -1

local g_ObjCared = -1
local g_EquipEducation_JinJie_Frame_UnifiedPosition

local m_ActionButton_Equip
local m_Button_OK

local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney

local m_StaticText_NeedItem
local m_StaticText_HaveItem

local m_ItemIndex_Bind = 20800031	--紫薇灵魄（绑定）
local m_ItemIndex = 20800032	--紫薇灵魄

local m_DragonNum = 0

function EquipEducation_JinJie_PreLoad()
		
		this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE")
		this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_PUTIN_EQUIP")
		this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_RCLICK")
		this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_REMOVE_EQUIP")
		this:RegisterEvent("MONEY_CHANGE_EX",false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false) 
		this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_CLOSE") 
		this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_DONE") 
		
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
end

function EquipEducation_JinJie_OnLoad()
	
	g_EquipEducation_JinJie_Frame_UnifiedPosition = EquipEducation_JinJie_Frame:GetProperty( "UnifiedPosition" )
	
	m_ActionButton_Equip = EquipEducation_JinJie_Icon
	
	m_Button_OK = EquipEducation_JinJie_OK
	
	m_StaticText_NeedMoney =  EquipEducation_JinJie_DemandMoney
	m_StaticText_HaveJZ =  EquipEducation_JinJie_SelfJiaozi
	m_StaticText_HaveMoney =  EquipEducation_JinJie_SelfMoney
	
	m_StaticText_NeedItem = EquipEducation_JinJie_ZWLPNeed
	m_StaticText_HaveItem = EquipEducation_JinJie_ZWLPHold
	
end

function EquipEducation_JinJie_OnEvent(event)
	    
	if event == "ZHIZUN_EQUIP_UPGRADE" then
		local nObjServerID = tonumber( arg0 )
		EquipEducation_JinJie_Init()
		this:Show()
		
		if IsWindowShow("Packet") == false then
			ToggleContainer()
		end
		
		EquipEducation_JinJie_UpdateText( tonumber( arg1 ) ,  tonumber( arg2 ) , tonumber( arg3 ))
		
		g_ObjCared = -1
		g_ObjCared = DataPool : GetNPCIDByServerID( nObjServerID )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		return
	end
	
	if event == "ZHIZUN_EQUIP_UPGRADE_CLOSE" then
	
		EquipEducation_JinJie_OnCloseClicked()
		return
		
	end
	
	if (event == "ZHIZUN_EQUIP_UPGRADE_PUTIN_EQUIP"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipEducation_JinJie_OnItemDragedDropFromBag( tonumber(arg0) )
		end
		return
	end
	
	if (event == "ZHIZUN_EQUIP_UPGRADE_RCLICK"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipEducation_JinJie_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	end
	
	if (event == "ZHIZUN_EQUIP_UPGRADE_REMOVE_EQUIP"  and this:IsVisible() ) then
		EquipEducation_JinJie_OnItemDragedDropAway()
		return
	end
	
	if (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_EquipBagIndex then
			EquipEducation_JinJie_Refresh()
		end 
		
		local item_count = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex)
		local item_count_bind = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex_Bind)
		m_StaticText_HaveItem:SetText(tostring(item_count + item_count_bind))
		return
	end

	if event == "HIDE_ON_SCENE_TRANSED"  then
        EquipEducation_JinJie_CleanUp()
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		EquipEducation_JinJie_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipEducation_JinJie_On_ResetPos()
	end
	
	if (event == "MONEY_CHANGE_EX" and this:IsVisible() ) then
		m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
	
	if event == "ZHIZUN_EQUIP_UPGRADE_DONE" and this:IsVisible() then
		EquipEducation_JinJie_UpdateText( tonumber( arg0 ) ,  tonumber( arg1 ) , tonumber( arg2 ))
		return
	end
	
end

function EquipEducation_JinJie_UpdateText( nDragonNum  ,  nUpgradeTime1 , nUpgradeTime2)
	
	m_DragonNum = nDragonNum
	
	if nDragonNum < 2 then
		EquipEducation_JinJie_LeftFirst:SetText("#{ZZZB_150811_265}")
	elseif nDragonNum < 3 then
		local nLeftNum = 1 - nUpgradeTime1
		if nLeftNum < 0 then
			nLeftNum = 0
		end
		local strText = ScriptGlobal_Format("#{ZZZB_151105_08}" ,tostring(nLeftNum))
		EquipEducation_JinJie_LeftFirst:SetText(strText)	
	else
		local nLeftNum = 1 - nUpgradeTime1
		if nLeftNum < 0 then
			nLeftNum = 0
		end
		local strText = ScriptGlobal_Format("#{ZZZB_150811_266}" ,tostring(nLeftNum))
		EquipEducation_JinJie_LeftFirst:SetText(strText)
	end
		
	if nDragonNum < 5 then
		EquipEducation_JinJie_RightFirst:SetText("#{ZZZB_150811_265}")
	else
		local nLeftNum = 1 - nUpgradeTime2
		if nLeftNum < 0 then
			nLeftNum = 0
		end
		local strText = ScriptGlobal_Format("#{ZZZB_150811_268}" ,tostring(nLeftNum))
		EquipEducation_JinJie_RightFirst:SetText(strText)
	end

end
--关闭 或 打开 UI时 ，清空一次
function EquipEducation_JinJie_CleanUp()

	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
	m_Button_OK:Disable()
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	
	m_StaticText_NeedItem:SetText("0")
	m_DragonNum = 0

	
end

--UI恢复到第一次打开时的状态
function EquipEducation_JinJie_Init()
	
	EquipEducation_JinJie_CleanUp()
	
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	local item_count = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex)
	local item_count_bind = PlayerPackage:CountAvailableItemByIDTable(m_ItemIndex_Bind)
	m_StaticText_HaveItem:SetText(tostring(item_count + item_count_bind))
end

--UI没有装备的状态
function EquipEducation_JinJie_NoEqup()

	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	m_StaticText_NeedItem:SetText("0")
	m_Button_OK:Disable()
	
end

--点击Cancel
function EquipEducation_JinJie_OnCancelClicked(  )

	EquipEducation_JinJie_CleanUp()
	this:Hide()

end

--点击"X"
function EquipEducation_JinJie_OnCloseClicked(  )

	EquipEducation_JinJie_CleanUp()
	this:Hide()
	
end

--OnHide
function EquipEducation_JinJie_OnHiden()
	
	EquipEducation_JinJie_CleanUp()
	
end

--点击OK
function EquipEducation_JinJie_OnOK()
	
	if m_EquipBagIndex == -1 then
		return
	end

	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_150811_15}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpGrade" )
		Set_XSCRIPT_ScriptID( 880036 )
		Set_XSCRIPT_Parameter( 0, m_EquipBagIndex )       	--- 物品背包索引
		Set_XSCRIPT_Parameter( 1, 1 )       								--- 是否需要绑定确认
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()			
	
end

--刷新界面
function EquipEducation_JinJie_Refresh()
	
	if m_EquipBagIndex == -1 then
	
		EquipEducation_JinJie_NoEqup()
		return
		
	end
	
	if PlayerPackage:Lua_IsBagItemBelongZZType( m_EquipBagIndex ) ~= 1 then
		EquipEducation_JinJie_NoEqup()	--不属于可升灵装备
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex ) == 2 then
		EquipEducation_JinJie_NoEqup()	--至尊装备不能进阶了
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex) < 9 then
		EquipEducation_JinJie_NoEqup()	--升灵未到满级
		return
	end
	
	local theAction = EnumAction(m_EquipBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		
		EquipEducation_JinJie_NoEqup()
		return
		
	end
	
	m_ActionButton_Equip:SetActionItem(theAction:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "500000")
	if m_DragonNum == 2 then
		m_StaticText_NeedItem:SetText("40")
	end
	m_Button_OK:Enable()
	
end

--从背包拖拽到UI
function EquipEducation_JinJie_OnItemDragedDropFromBag( iBagIndex )
	
	if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
		PushDebugMessage("#{ZZZB_150811_32}")	--不属于可升灵装备
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 2 then
		PushDebugMessage("#{ZZZB_150811_32}")	--至尊装备不能进阶了
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex) < 9 then
		PushDebugMessage("#{ZZZB_150811_32}")	--升灵未到满级
		return
	end	
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipEducation_JinJie_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipEducation_JinJie_Refresh()
	
end

--从背包内右键点击
function EquipEducation_JinJie_OnBagItemRClicked( iBagIndex )
	
	if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
		PushDebugMessage("#{ZZZB_150811_32}")	--不属于可升灵装备
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 2 then
		PushDebugMessage("#{ZZZB_150811_32}")	--至尊装备不能进阶了
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex) < 9 then
		PushDebugMessage("#{ZZZB_150811_32}")	--升灵未到满级
		return
	end	
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipEducation_JinJie_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipEducation_JinJie_Refresh()

end

--从ActionItem拖拽到Window之外
function EquipEducation_JinJie_OnItemDragedDropAway(  )
	
	EquipEducation_JinJie_NoEqup()

end

--右键单击ActionItem
function EquipEducation_JinJie_OnActionItemRClicked(  )
	
	EquipEducation_JinJie_NoEqup()

end

function EquipEducation_JinJie_On_ResetPos()
    EquipEducation_JinJie_Frame:SetProperty( "UnifiedPosition", g_EquipEducation_JinJie_Frame_UnifiedPosition )
end
