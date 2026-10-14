local m_EquipBagIndex = -1
local EquipLingPai_SkillQH_Update_AfterQH = -1

local g_ObjCared = -1
local g_UI_Command = 201405044
local g_UI_Command_Refresh = 201406284

local g_RS_UnActived_Image  = "set:CommonFrame25 image:EquipLingPai_Feng"    --- 未打孔

local g_SkillQH_NeedMoney = 100000

local g_MainFram_UnifiedPosition

--控件变量
local m_MainFram
local m_ActionButton_Equip
local m_Button_OK
local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney
local m_Text_CurrentSkill
local m_Text_SkillSelInfo
local m_Text_SkillList

function EquipLingPai_SkillQH_PreLoad( )

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("RL_SKILL_PUTIN_EQUIP")
	this:RegisterEvent("RL_SKILL_PACKET_RCLICK")
	this:RegisterEvent("RL_SKILL_REMOVE_EQUIP")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function EquipLingPai_SkillQH_OnLoad( )

	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片素材为唯美版
		g_RS_UnActived_Image  = "set:WM_MainFrame09 image:EquipLingPai_Feng"    --- 未打孔
	end
	
	m_MainFram = EquipLingPai_SkillQH_Frame
	m_ActionButton_Equip = EquipLingPai_SkillQH_InputIcon
	m_Button_OK = EquipLingPai_SkillQH_OK
	
	m_StaticText_NeedMoney =  EquipLingPai_SkillQH_WantNum
	m_StaticText_HaveJZ =  EquipLingPai_SkillQH_HaveNum
	m_StaticText_HaveMoney =  EquipLingPai_SkillQH_HaveGoldNum
	
	m_Text_CurrentSkill = EquipLingPai_SkillQH_CurrentSkillNameText

	m_Text_SkillSelInfo = EquipLingPai_SkillQH_NameShuomingText
	m_Text_SkillList = EquipLingPai_SkillQH_SkillZiKuang
	
	g_MainFram_UnifiedPosition = m_MainFram:GetProperty( "UnifiedPosition" )

end

function EquipLingPai_SkillQH_OnEvent( event )

	if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_UI_Command then
		EquipLingPai_SkillQH_Init()
		this:Show()
		g_ObjCared = -1
		local nServerID = Get_XParam_INT( 0 )
		g_ObjCared = DataPool : GetNPCIDByServerID( nServerID )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		return
	end
	
	if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_UI_Command_Refresh and this:IsVisible() then
		
		EquipLingPai_SkillQH_Update_AfterQH()
		return
		
	end
	
	if (event == "RL_SKILL_PUTIN_EQUIP"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipLingPai_SkillQH_OnItemDragedDropFromBag( tonumber(arg0)  )
		end
		return
	end
	
	if (event == "RL_SKILL_PACKET_RCLICK"  and this:IsVisible()) then
		if arg0 ~= nil  then
			EquipLingPai_SkillQH_OnBagItemRClicked( tonumber(arg0)  )
		end
		return
	end 
	
	if (event == "RL_SKILL_REMOVE_EQUIP"  and this:IsVisible()) then
		EquipLingPai_SkillQH_OnItemDragedDropAway()
		return
	end 

	if event == "HIDE_ON_SCENE_TRANSED"  then
        EquipLingPai_SkillQH_CleanUp()
		this:Hide()
		return
	end
	
	if (event == "ADJEST_UI_POS" ) then
		EquipLingPai_SkillQH_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		EquipLingPai_SkillQH_On_ResetPos()
		return
	end
	
	if (event == "MONEY_CHANGE_EX") then
		m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if (event == "MONEYJZ_CHANGE_EX") then
		m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
	
end

--Window清空
function EquipLingPai_SkillQH_CleanUp()
	
	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1

	m_Text_SkillList:ClearListBox()

	m_Text_CurrentSkill:SetText("")
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	m_Button_OK:Disable()

end

--Window恢复默认状态
function EquipLingPai_SkillQH_Init()
	
	EquipLingPai_SkillQH_CleanUp()
	
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	local allBuffNum = Lua_GetALLRlBuffNum()
	for i = 1 , allBuffNum do
		
		local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable(  i - 1 , 0 )
		local ret  = DataPool:Lua_IsHumanLearnedRlSkill(nSaveFlag)
		if ret == 1 or nBuffGroupID <= 6 then
		
			m_Text_SkillList:AddItem(nBuffName, i - 1)
		else
			
			m_Text_SkillList:AddItem(nBuffName.."#{BHZB_140521_226}", i - 1)
		end
	end

	if allBuffNum > 0 then
		m_Text_SkillList:SetItemSelect(0)
	end
	
end

function EquipLingPai_SkillQH_NoEqup()

	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1

	m_Text_CurrentSkill:SetText("")
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	m_Button_OK:Disable()
	
	local nSelIdx = m_Text_SkillList:GetFirstSelectItem()
	local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable( nSelIdx , 0)
	m_Text_SkillSelInfo:SetText(nBuffBaseString)
	
end
--刷新界面
function EquipLingPai_SkillQH_Refresh()
	
	if m_EquipBagIndex == -1 then
	
		EquipLingPai_SkillQH_NoEqup()
		return
		
	end
	
	local theAction = EnumAction(m_EquipBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		
		EquipLingPai_SkillQH_NoEqup()
		return
		
	end
	
	m_ActionButton_Equip:SetActionItem(theAction:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	
	local nGrade = PlayerPackage:Lua_GetBagItemRl_Grade( m_EquipBagIndex ) 
	local nBuffGroupID = PlayerPackage:Lua_GetBagItemRl_BuffGroupID(m_EquipBagIndex)
	local nBuffName  = Lua_GetRlBuffNameByID( nBuffGroupID )
	
	if nGrade ~= 5 then
	
		m_Text_CurrentSkill:SetText("#{BHZB_140521_188}")
		
	else
	
		m_Text_CurrentSkill:SetText(nBuffName)
		
	end
	
	local nSelIdx = m_Text_SkillList:GetFirstSelectItem()
	if nSelIdx ~= -1 then
		m_Button_OK:Enable()
		m_StaticText_NeedMoney:SetProperty("MoneyNumber", tostring(g_SkillQH_NeedMoney))
		
		local nStarLevel , nStarEffect , strSuccess , nMustSuccessTry ,nNextStarLevel , nNextStarEffect  = PlayerPackage:Lua_GetBagItemRl_StarInfo(m_EquipBagIndex)
		
		if nStarLevel ~= nil  then	
			
			local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable( nSelIdx , nStarLevel)
			m_Text_SkillSelInfo:SetText(nBuffBaseString)
			
		else
			
			local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable( nSelIdx , 0)
			m_Text_SkillSelInfo:SetText(nBuffBaseString)
			
		end
	end
	
end

--从背包拖拽到UI
function EquipLingPai_SkillQH_OnItemDragedDropFromBag( iBagIndex )
	
	--是否是令牌
	if PlayerPackage:Lua_IsBagItemRL( iBagIndex ) ~= 1 then
		PushDebugMessage("#{BHZB_140521_69}")	
		return
	end
	
	--是否加锁
	--if PlayerPackage:IsLock( iBagIndex ) == 1 then
	--	PushDebugMessage("#{BSZK_121012_17}")	--道具已上锁
	--	return
	--end

	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipLingPai_SkillQH_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipLingPai_SkillQH_Refresh()
	
end

--从背包内右键点击
function EquipLingPai_SkillQH_OnBagItemRClicked( iBagIndex )
	
	--是否是令牌
	if PlayerPackage:Lua_IsBagItemRL( iBagIndex ) ~= 1 then
		PushDebugMessage("#{BHZB_140521_69}")	
		return
	end
	
	--是否加锁
	--if PlayerPackage:IsLock( iBagIndex ) == 1 then
	--	PushDebugMessage("#{BSZK_121012_17}")	--道具已上锁
	--	return
	--end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipLingPai_SkillQH_NoEqup()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipLingPai_SkillQH_Refresh()

end

--从ActionItem拖拽到Window之外
function EquipLingPai_SkillQH_OnItemDragedDropAway(  )
	
	EquipLingPai_SkillQH_NoEqup()

end

--右键单击ActionItem
function EquipLingPai_SkillQH_OnActionItemRClicked(  )
	
	EquipLingPai_SkillQH_NoEqup()

end

function EquipLingPai_SkillQH_OnSelectedChange()
	
	local nSelIdx = m_Text_SkillList:GetFirstSelectItem()
	
	if m_EquipBagIndex ~= -1 then
		
		m_Button_OK:Enable()
		m_StaticText_NeedMoney:SetProperty("MoneyNumber", tostring(g_SkillQH_NeedMoney))
		
		local nStarLevel , nStarEffect , strSuccess , nMustSuccessTry ,nNextStarLevel , nNextStarEffect  = PlayerPackage:Lua_GetBagItemRl_StarInfo(m_EquipBagIndex)
		
		if nStarLevel ~= nil  then	
			
			local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable( nSelIdx , nStarLevel)
			m_Text_SkillSelInfo:SetText(nBuffBaseString)
			
		else
			
			local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable( nSelIdx , 0)
			m_Text_SkillSelInfo:SetText(nBuffBaseString)
			
		end
	else
		
		local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable( nSelIdx , 0)
		m_Text_SkillSelInfo:SetText(nBuffBaseString)
	
	end
	
end

--点击OK
function EquipLingPai_SkillQH_OnOkClicked(  )

	local nSelIdx = m_Text_SkillList:GetFirstSelectItem()
	if nSelIdx == -1 then
		PushDebugMessage("#{BHZB_140521_205} ")		
		return
	end
	
	if m_EquipBagIndex == -1 then
		return
	end
	
	local nGrade = PlayerPackage:Lua_GetBagItemRl_Grade( m_EquipBagIndex ) 
	if nGrade ~= 5 then
		PushDebugMessage("#{BHZB_140521_223}")	
		return
	end
	
	local nBuffGroupID , nSaveFlag , nBuffName , nBuffBaseString = Lua_GetRlBuffFromTable( nSelIdx , 0 )
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name( "RL_SwitchSkill" );
		Set_XSCRIPT_ScriptID( 880001 );
		Set_XSCRIPT_Parameter( 0, m_EquipBagIndex     );        
		Set_XSCRIPT_Parameter( 1, nBuffGroupID   );        
		Set_XSCRIPT_ParamCount( 2 );
	Send_XSCRIPT();	
	return

end

--点击Cancel
function EquipLingPai_SkillQH_OnCancelClicked(  )

	EquipLingPai_SkillQH_CleanUp()
	this:Hide()

end

--点击"X"
function EquipLingPai_SkillQH_OnCloseClicked(  )

	EquipLingPai_SkillQH_CleanUp()
	this:Hide()
	
end

function EquipLingPai_SkillQH_OnHiden(  )

	EquipLingPai_SkillQH_CleanUp()
	
end

function EquipLingPai_SkillQH_On_ResetPos()

	m_MainFram:SetProperty( "UnifiedPosition", g_MainFram_UnifiedPosition )
	
end

function EquipLingPai_SkillQH_Update_AfterQH()
	
	local nEquipBagIndex = m_EquipBagIndex
	EquipLingPai_SkillQH_NoEqup()
		
	m_EquipBagIndex = nEquipBagIndex
	EquipLingPai_SkillQH_Refresh()
	
end