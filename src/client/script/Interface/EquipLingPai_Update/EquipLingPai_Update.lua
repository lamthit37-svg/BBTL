local m_Equip_Idx = -1

local g_ObjCared = -1
local g_UI_Command = 201405042

local g_ResetExAttr_NeedMoney = {20000,40000,60000}

local g_EquipLingPai_Update_Frame_UnifiedPosition

local g_LockList = {}

local g_NeedItemNum = { 1 ,2 ,3 }

--控件成员
local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney

local m_StaticText_Attr = {}
local m_CheckRadio = {}
local m_CheckRadioText = {}

local g_QuickPurchaseCheck = 1

function EquipLingPai_Update_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("RL_UPDATE_PUTIN")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)

	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR")
end

function EquipLingPai_Update_OnLoad()

	g_EquipLingPai_Update_Frame_UnifiedPosition = EquipLingPai_Update_Frame:GetProperty( "UnifiedPosition" )
	
	m_StaticText_NeedMoney = EquipLingPai_Update_Money
	m_StaticText_HaveJZ = EquipLingPai_Update_Jiaozi
	m_StaticText_HaveMoney = EquipLingPai_Update_SelfMoney
	
	m_StaticText_Attr[1] = EquipLingPai_Update_AttrFirst
	m_StaticText_Attr[2] = EquipLingPai_Update_AttrSecond
	m_StaticText_Attr[3] = EquipLingPai_Update_AttrThird
	
	m_CheckRadio[1] = EquipLingPai_Update_SuoFirst
	m_CheckRadio[2] = EquipLingPai_Update_SuoSecond
	m_CheckRadio[3] = EquipLingPai_Update_SuoThird
	
	m_CheckRadioText[1] = EquipLingPai_Update_SuoFirstText
	m_CheckRadioText[2] = EquipLingPai_Update_SuoSecondText
	m_CheckRadioText[3] = EquipLingPai_Update_SuoThirdText
	
	g_LockList[1] = 0
	g_LockList[2] = 0
	g_LockList[3] = 0
	
end

function EquipLingPai_Update_OnEvent(event)

	if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_UI_Command then
		EquipLingPai_Update_Reset()
		this:Show()
		g_ObjCared = -1
		local xx = Get_XParam_INT( 0 )
		g_ObjCared = DataPool : GetNPCIDByServerID( xx )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		return
	end
	
	if (event == "RL_UPDATE_PUTIN"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipLingPai_Update_Update( tonumber(arg0) )
		end
		return
	end

	if (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			EquipLingPai_Update_Update(m_Equip_Idx)
		end 
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED"  then
		EquipLingPai_Update_Reset()
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		EquipLingPai_Update_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipLingPai_Update_On_ResetPos()
	end
	
	if (event == "MONEY_CHANGE_EX") then
		m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if (event == "MONEYJZ_CHANGE_EX") then
		m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
	
	if (event == "GAMELOGIN_OPEN_SELECT_CHARACTOR" ) then
		g_QuickPurchaseCheck = 1
		return
	end
end

function EquipLingPai_Update_Reset()
	
	LifeAbility : Lock_Packet_Item(m_Equip_Idx,0)
	m_Equip_Idx = -1
	g_ObjCared = -1
	EquipLingPai_Update_OK:Disable()
	EquipLingPai_Update_InputIcon:SetActionItem(-1)
	
	for i = 1, 3 do
		m_StaticText_Attr[i]:SetText("")
		m_CheckRadio[i]:SetCheck(0)
		m_CheckRadio[i]:Hide()
		m_CheckRadioText[i]:Hide()
		g_LockList[i] = 0
	end
	
	EquipLingPai_Update_Amount:SetText("")
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	if g_QuickPurchaseCheck == 1 then
		EquipLingPai_Update_ZidongCheckButton:SetProperty("Selected", "True")
	else
		EquipLingPai_Update_ZidongCheckButton:SetProperty("Selected", "False")
	end
end

function EquipLingPai_Update_OnClosed()
	
	EquipLingPai_Update_Reset()
	this:Hide()

	end

function EquipLingPai_Update_OnHiden()
	
	EquipLingPai_Update_Reset()
	
end

function EquipLingPai_Update_Update(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem")
	if theAction:GetID() ~= 0 then
		
		if PlayerPackage:Lua_IsBagItemRL( itemIdx ) ~= 1 then
			PushDebugMessage("#{BHZB_140521_109}")	
			return
		end
		
		if PlayerPackage:IsLock( itemIdx ) == 1 then
			PushDebugMessage("#{BSZK_121012_17}")	--道具已上锁
			return
		end
		
		local iAllUnActive = 1
		for i  = 1 , 3 do
			local nExAttrID , nExAttrStr = PlayerPackage:Lua_GetBagRlExAttr(itemIdx , i - 1)
			if nExAttrID ~= -1 then
				iAllUnActive = 0
				break
			end	
		end
		if iAllUnActive == 1 then
			PushDebugMessage("#{BHZB_140521_253}")	--没有可用的扩展属性
			return
		end
		
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0)
		end
		
		EquipLingPai_Update_InputIcon:SetActionItem(theAction:GetID())
		LifeAbility : Lock_Packet_Item(itemIdx,1)
		
		local bUpdateCheckRadio = 0
		if m_Equip_Idx ~= itemIdx then
			m_Equip_Idx = itemIdx
			bUpdateCheckRadio = 1
		end

		for i = 1 , 3 do
		
			local nExAttrID , nExAttrStr = PlayerPackage:Lua_GetBagRlExAttr(m_Equip_Idx , i - 1)
			m_StaticText_Attr[i]:SetText(tostring(nExAttrStr))	
			if bUpdateCheckRadio == 1 then
				if nExAttrID == -1 then
					
					m_CheckRadio[i]:SetCheck(0)
					g_LockList[i] = 0
					m_CheckRadio[i]:Hide()
					m_CheckRadioText[i]:Hide()
				
				else
					
					m_CheckRadio[i]:SetCheck(0)
					g_LockList[i] = 0
					m_CheckRadio[i]:Show()
					m_CheckRadioText[i]:Show()
				
				end
			end
		end
		
		local nLockNum = 0
		for i =1 , 3 do
			if g_LockList[i] == 1 then
				nLockNum = nLockNum + 1
			end
		end
		
		if nLockNum == 3 then
		
			m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
			EquipLingPai_Update_Amount:SetText("")
			
		else
			
			local strText = ScriptGlobal_Format("#{BHZB_140521_252}" ,tostring(nLockNum + 1))
			EquipLingPai_Update_Amount:SetText(strText)
			m_StaticText_NeedMoney:SetProperty("MoneyNumber", tostring(g_ResetExAttr_NeedMoney[nLockNum + 1]))		
		
		end
		
		EquipLingPai_Update_OK:Enable()
		
	else
		
		EquipLingPai_Update_Reset()
	
	end
end

function EquipLingPai_Update_OnOK()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end
	
	if m_Equip_Idx == -1 then
		
		PushDebugMessage("#{BHZB_140521_111}")
		return

	end
	
	if PlayerPackage:IsLock( m_Equip_Idx ) == 1 then
		PushDebugMessage("#{LDCL_100508_09}")	--道具已上锁
		return
	end
	
	local iAllLock = 1
	for i  = 1 , 3 do
		local nExAttrID , nExAttrStr = PlayerPackage:Lua_GetBagRlExAttr(m_Equip_Idx , i - 1)
		if nExAttrID ~= -1 and m_CheckRadio[i]:IsVisible() and m_CheckRadio[i]:GetCheck() == 0 then
			iAllLock = 0
			break
		end	
	end
	
	if iAllLock == 1 then
		PushDebugMessage("#{BHZB_140521_255}")
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name( "RlResetExAttr" );
		Set_XSCRIPT_ScriptID( 880001 );
		Set_XSCRIPT_Parameter( 0, m_Equip_Idx     );          --- 物品背包索引
		Set_XSCRIPT_Parameter( 1, m_CheckRadio[1]:GetCheck()     );          --- 物品背包索引
		Set_XSCRIPT_Parameter( 2, m_CheckRadio[2]:GetCheck()     );          --- 物品背包索引
		Set_XSCRIPT_Parameter( 3, m_CheckRadio[3]:GetCheck()     );          --- 物品背包索引
		Set_XSCRIPT_Parameter( 4, g_QuickPurchaseCheck     );          --- 自动购买确认
		Set_XSCRIPT_ParamCount( 5 );
	Send_XSCRIPT();	

end

function EquipLingPai_Update_Resume_Equip()
	EquipLingPai_Update_Reset()
end

function EquipLingPai_Update_Clicked(idx)
	
	if idx < 1 or idx > 3 then
		return
	end
	if g_LockList[idx] == 1 then
		g_LockList[idx]  = 0
	else
		g_LockList[idx]  = 1
	end
	
	local nLockNum = 0
	for i =1 , 3 do
		if g_LockList[i] == 1 then
			nLockNum = nLockNum + 1
		end
	end
	
	if nLockNum == 3 then
		
			m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
			EquipLingPai_Update_Amount:SetText("")
			
		else
			
			local strText = ScriptGlobal_Format("#{BHZB_140521_252}" ,tostring(nLockNum + 1))
			EquipLingPai_Update_Amount:SetText(strText)
			m_StaticText_NeedMoney:SetProperty("MoneyNumber", tostring(g_ResetExAttr_NeedMoney[nLockNum + 1]))		
		
		end
	
	
end

function EquipLingPai_Update_On_ResetPos()
    EquipLingPai_Update_Frame:SetProperty( "UnifiedPosition", g_EquipLingPai_Update_Frame_UnifiedPosition )
end

--自动购买
function EquipLingPai_Update_ZidongCheck_Clicked()

	if g_QuickPurchaseCheck == 1 then
		g_QuickPurchaseCheck = 0
		EquipLingPai_Update_ZidongCheckButton:SetProperty("Selected", "False")
	else
		g_QuickPurchaseCheck = 1
		EquipLingPai_Update_ZidongCheckButton:SetProperty("Selected", "True")
	end

end
