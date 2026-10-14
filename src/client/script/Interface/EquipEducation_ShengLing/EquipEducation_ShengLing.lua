local m_EquipBagIndex = -1

local g_ObjServerID = -1
local g_ObjCared = -1
local g_EquipEducation_ShengLing_Frame_UnifiedPosition

local m_ActionButton_Equip
local m_Button_OK

local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney

local m_LevelupNeedItemCount = {

	[ 1 ] = { 5 , 6 ,8 ,10 ,12 ,14 ,16 ,19 ,22} ,
	[ 2 ] = { 25 , 28 ,32 ,36 ,40 ,45 ,50 ,55 ,62} ,

}

function EquipEducation_ShengLing_PreLoad()
		
		this:RegisterEvent("ZHIZUN_EQUIP_LEVELUP")
		this:RegisterEvent("ZHIZUN_EQUIP_LEVELUP_PUTIN_EQUIP")
		this:RegisterEvent("ZHIZUN_EQUIP_LEVELUP_RCLICK")
		this:RegisterEvent("ZHIZUN_EQUIP_LEVELUP_REMOVE_EQUIP")
		this:RegisterEvent("MONEY_CHANGE_EX",false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false) 
		this:RegisterEvent("ZHIZUN_EQUIP_LEVELUP_CLOSE") 
		
		
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
end

function EquipEducation_ShengLing_OnLoad()
	
	g_EquipEducation_ShengLing_Frame_UnifiedPosition = EquipEducation_ShengLing_Frame:GetProperty( "UnifiedPosition" )
	
	m_ActionButton_Equip = EquipEducation_ShengLing_Icon
	
	m_Button_OK = EquipEducation_ShengLing_OK
	
	m_StaticText_NeedMoney =  EquipEducation_ShengLing_DemandMoney
	m_StaticText_HaveJZ =  EquipEducation_ShengLing_SelfJiaozi
	m_StaticText_HaveMoney =  EquipEducation_ShengLing_SelfMoney
	
end

function EquipEducation_ShengLing_OnEvent(event)
	    
	if ( event == "ZHIZUN_EQUIP_LEVELUP" )  then
		g_ObjServerID = tonumber( arg0 )
		EquipEducation_ShengLing_Init()
		this:Show()
		g_ObjCared = -1	
		g_ObjCared = DataPool : GetNPCIDByServerID( g_ObjServerID )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		return
	end
	
	if event == "ZHIZUN_EQUIP_LEVELUP_CLOSE" then
	
		EquipEducation_ShengLing_OnCloseClicked()
		return
		
	end
	
	if (event == "ZHIZUN_EQUIP_LEVELUP_PUTIN_EQUIP"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipEducation_ShengLing_OnItemDragedDropFromBag( tonumber(arg0) )
		end
		return
	end
	
	if (event == "ZHIZUN_EQUIP_LEVELUP_RCLICK"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipEducation_ShengLing_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	end
	
	if (event == "ZHIZUN_EQUIP_LEVELUP_REMOVE_EQUIP"  and this:IsVisible() ) then
		EquipEducation_ShengLing_OnItemDragedDropAway()
		return
	end
	
	if (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_EquipBagIndex then
			EquipEducation_ShengLing_Refresh()
		end 
		return
	end

	if event == "HIDE_ON_SCENE_TRANSED"  then
		EquipEducation_ShengLing_CleanUp()
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		EquipEducation_ShengLing_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipEducation_ShengLing_On_ResetPos()
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
function EquipEducation_ShengLing_CleanUp()

	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
	m_Button_OK:Disable()
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	
	EquipEducation_ShengLing_Explain:SetText("")
	EquipEducation_ShengLing_Explain1:SetText("")
	EquipEducation_ShengLing_Explain2:SetText("")
	
end

--UI恢复到第一次打开时的状态
function EquipEducation_ShengLing_Init()
	
	EquipEducation_ShengLing_CleanUp()
	
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
end

--UI没有装备的状态
function EquipEducation_ShengLing_NoEqup()

	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1

	EquipEducation_ShengLing_Explain:SetText("")
	EquipEducation_ShengLing_Explain1:SetText("")
	EquipEducation_ShengLing_Explain2:SetText("")
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	m_Button_OK:Disable()
	
end

--点击Cancel
function EquipEducation_ShengLing_OnCancelClicked(  )

	EquipEducation_ShengLing_CleanUp()
	this:Hide()

end

--点击"X"
function EquipEducation_ShengLing_OnCloseClicked(  )

	EquipEducation_ShengLing_CleanUp()
	this:Hide()
	
end

--OnHide
function EquipEducation_ShengLing_OnHiden()
	
	EquipEducation_ShengLing_CleanUp()
	
end

--点击OK
function EquipEducation_ShengLing_OnOK()
	
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
		Set_XSCRIPT_Function_Name( "LevelUp" )
		Set_XSCRIPT_ScriptID( 880036 )
		Set_XSCRIPT_Parameter( 0, g_ObjServerID ) 
		Set_XSCRIPT_Parameter( 1, m_EquipBagIndex )       	--- 物品背包索引
		Set_XSCRIPT_Parameter( 2, 1 )       				--- 是否需要绑定确认
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()	
	
end

--刷新界面
function EquipEducation_ShengLing_Refresh()
	
	if m_EquipBagIndex == -1 then
	
		EquipEducation_ShengLing_NoEqup()
		return
		
	end
	
	if PlayerPackage:Lua_GetBagItemEquipPoint( m_EquipBagIndex ) == 0 then
		EquipEducation_ShengLing_NoEqup()
		return
	end
	
	if LifeAbility:IsIndentify(m_EquipBagIndex) ~= 1 then
		EquipEducation_ShengLing_NoEqup()
		return
	end

	if PlayerPackage:Lua_IsBagItemBelongZZType( m_EquipBagIndex ) ~= 1 then
		EquipEducation_ShengLing_NoEqup()
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex ) == 2 then
		EquipEducation_ShengLing_NoEqup()
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex) >= 9 then
		EquipEducation_ShengLing_NoEqup()
		return
	end
	
	local theAction = EnumAction(m_EquipBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		
		EquipEducation_ShengLing_NoEqup()
		return
		
	end
	
	m_ActionButton_Equip:SetActionItem(theAction:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	
	local nCurrentLevel = PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex)
	local nCurrentType = PlayerPackage:Lua_GetBagEquipHandMakeType(m_EquipBagIndex)
	if nCurrentLevel == 0 and nCurrentType == 0 then
		EquipEducation_ShengLing_Explain:SetText("#{ZZZB_150811_07}")
	else
		local strText = ScriptGlobal_Format("#{ZZZB_150811_06}" , tostring(nCurrentLevel))
		EquipEducation_ShengLing_Explain:SetText(strText)
	end
	
	EquipEducation_ShengLing_Explain1:SetText("#{ZZZB_150811_75}")
	
	local nLevel = PlayerPackage:Lua_GetBagEquipHandMakeLevel(m_EquipBagIndex)
	local nType = PlayerPackage:Lua_GetBagEquipHandMakeType( m_EquipBagIndex )
	
	if nLevel >= 0 and nLevel <=8 and nType >=0 and nType <= 1 then
		EquipEducation_ShengLing_Explain2:SetText(tostring(m_LevelupNeedItemCount[ nType + 1 ][ nLevel + 1]))
	end
	
	if nType == 0 then
		m_StaticText_NeedMoney:SetProperty("MoneyNumber", "100000")
	elseif nType == 1 then
		m_StaticText_NeedMoney:SetProperty("MoneyNumber", "200000")	
	end
	m_Button_OK:Enable()
	
end

--从背包拖拽到UI
function EquipEducation_ShengLing_OnItemDragedDropFromBag( iBagIndex )

	if Player:GetData("LEVEL") < 85 then
		PushDebugMessage("#{ZZZB_200805_5}")	--角色等级
		return
	end
	
	if PlayerPackage:Lua_GetBagItemEquipPoint( iBagIndex ) == 0 then
		PushDebugMessage("#{ZZZB_150811_11}")	--武器无法进行升灵
		return
	end
	
	if LifeAbility:IsIndentify(iBagIndex) ~= 1 then
		PushDebugMessage("#{ZZZB_150811_12}")	--该装备尚未鉴定
		return
	end

	if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
		PushDebugMessage("#{ZZZB_150811_10}")	--仅可对80（含）以上、星级达到6星的手工装备、重楼装备或六博装备进行升灵...
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 2 then
		PushDebugMessage("#{ZZZB_150811_261}")	--该装备已进阶为天道装备，无法继续进行升灵...
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex) >= 9 then
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 0 then
			PushDebugMessage("#{ZZZB_150811_13}")	--该装备进阶为王权装备后，方可继续进行升灵
		elseif PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_150811_260}")	--该装备进阶为天道装备后，方可继续进行升灵
		end
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipEducation_ShengLing_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipEducation_ShengLing_Refresh()
	
end

--从背包内右键点击
function EquipEducation_ShengLing_OnBagItemRClicked( iBagIndex )

	if Player:GetData("LEVEL") < 85 then
		PushDebugMessage("#{ZZZB_200805_5}")	--角色等级
		return
	end
	
	if PlayerPackage:Lua_GetBagItemEquipPoint( iBagIndex ) == 0 then
		PushDebugMessage("#{ZZZB_150811_11}")	--武器无法进行升灵
		return
	end
	
	if LifeAbility:IsIndentify(iBagIndex) ~= 1 then
		PushDebugMessage("#{ZZZB_150811_12}")	--该装备尚未鉴定
		return
	end

	if PlayerPackage:Lua_IsBagItemBelongZZType( iBagIndex ) ~= 1 then
		PushDebugMessage("#{ZZZB_150811_10}")	--仅可对80（含）以上、星级达到6星的手工装备、重楼装备或六博装备进行升灵...
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 2 then
		PushDebugMessage("#{ZZZB_150811_261}")	--该装备已进阶为天道装备，无法继续进行升灵...
		return
	end
	
	if PlayerPackage:Lua_GetBagEquipHandMakeLevel(iBagIndex) >= 9 then
		if PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 0 then
			PushDebugMessage("#{ZZZB_150811_13}")	--该装备进阶为王权装备后，方可继续进行升灵
		elseif PlayerPackage:Lua_GetBagEquipHandMakeType( iBagIndex ) == 1 then
			PushDebugMessage("#{ZZZB_150811_260}")	--该装备进阶为天道装备后，方可继续进行升灵
		end
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipEducation_ShengLing_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipEducation_ShengLing_Refresh()

end

--从ActionItem拖拽到Window之外
function EquipEducation_ShengLing_OnItemDragedDropAway(  )
	
	EquipEducation_ShengLing_NoEqup()

end

--右键单击ActionItem
function EquipEducation_ShengLing_OnActionItemRClicked(  )
	
	EquipEducation_ShengLing_NoEqup()

end

function EquipEducation_ShengLing_On_ResetPos()
    EquipEducation_ShengLing_Frame:SetProperty( "UnifiedPosition", g_EquipEducation_ShengLing_Frame_UnifiedPosition )
end
