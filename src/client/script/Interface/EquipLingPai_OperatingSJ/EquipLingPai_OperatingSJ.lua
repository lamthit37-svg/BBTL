local m_EquipBagIndex = -1
local m_CurSel_Rs = -1
local m_Rs_Idx = {}

local g_ObjCared = -1
local g_UI_Command = 201405043

local g_RS_UnActived_Image  = "set:CommonFrame25 image:EquipLingPai_Feng"    --- 未打孔

local g_MainFram_UnifiedPosition

local g_RsLevelUp_NeedItem = 38000931
local g_RsLevelUp_NeedItem_Num = {
6,6,6,7,7,7,9,9,9,12,12,12,16,16,16,21,21,21,27,27,27,34,34,34,42,42,42,
51,51,51,61,61,61,72,72,72,84,84,84,97,97,97,111,111,111,126,126,126,126
}

local g_UnActived_tip = {"" , "#{BHZB_140521_169}" , "#{BHZB_140521_170}" , "#{BHZB_140521_171}"}
local g_SJ_NeedMoney = 50000
--控件变量
local m_MainFram
local m_ActionButton_Equip
local m_ActionButton_Rs = {}
local m_Text_RsLevel = {}
local m_Image_NoMove = {}
local m_Button_OK
local m_Text_CurLevel
local m_Text_NeedItem
local m_Text_NeedNum
local m_CheckButton_Page = {}

local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney

function EquipLingPai_OperatingSJ_PreLoad( )

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("RL_OPSJ_PUTIN_EQUIP")
	this:RegisterEvent("RL_OPSJ_PACKET_RCLICK")
	this:RegisterEvent("RL_OPSJ_REMOVE_EQUIP")
	this:RegisterEvent("OPEN_RLOPPAGE")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function EquipLingPai_OperatingSJ_OnLoad( )

	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片素材为唯美版
		g_RS_UnActived_Image  = "set:WM_MainFrame09 image:EquipLingPai_Feng"    --- 未打孔
	end
	
	m_MainFram = EquipLingPai_OperatingSJ_Frame
	m_ActionButton_Equip = EquipLingPai_OperatingSJ_InputIcon
	m_Button_OK = EquipLingPai_OperatingSJ_OK
	
	m_ActionButton_Rs[1] = EquipLingPai_OperatingSJ_FirstGem
	m_ActionButton_Rs[2] = EquipLingPai_OperatingSJ_SecondGem
	m_ActionButton_Rs[3] = EquipLingPai_OperatingSJ_ThirdGem
	m_ActionButton_Rs[4] = EquipLingPai_OperatingSJ_FourthGem
	
	m_Text_RsLevel[1] = EquipLingPai_OperatingSJ_FirstGrade
	m_Text_RsLevel[2] = EquipLingPai_OperatingSJ_SecondGrade
	m_Text_RsLevel[3] = EquipLingPai_OperatingSJ_ThirdGrade
	m_Text_RsLevel[4] = EquipLingPai_OperatingSJ_FourthGrade
	
	m_Image_NoMove[1] = EquipLingPai_OperatingSJ_FirstTuCeng
	m_Image_NoMove[2] = EquipLingPai_OperatingSJ_SecondTuCeng
	m_Image_NoMove[3] = EquipLingPai_OperatingSJ_ThirdTuCeng
	m_Image_NoMove[4] = EquipLingPai_OperatingSJ_FourthTuCeng
	
	m_Text_CurLevel = EquipLingPai_OperatingSJ_Text
	m_Text_NeedItem = EquipLingPai_OperatingSJ_Text1
	m_Text_NeedNum = EquipLingPai_OperatingSJ_Text2
	
	m_CheckButton_Page[1] = EquipLingPai_OperatingSJ_Page1
	m_CheckButton_Page[2] = EquipLingPai_OperatingSJ_Page2
	m_CheckButton_Page[3] = EquipLingPai_OperatingSJ_Page3
	
	m_StaticText_NeedMoney =  EquipLingPai_OperatingSJ_WantNum
	m_StaticText_HaveJZ =  EquipLingPai_OperatingSJ_HaveNum
	m_StaticText_HaveMoney =  EquipLingPai_OperatingSJ_HaveGoldNum

	g_MainFram_UnifiedPosition = m_MainFram:GetProperty( "UnifiedPosition" )

end

function EquipLingPai_OperatingSJ_OnEvent( event )
	
	if event == "OPEN_RLOPPAGE" and  tonumber( arg0 ) == 1 then
		
		local nPos = Variable:GetVariable("RL_OP_Pos");
		if(nPos ~= nil) then
			m_MainFram:SetProperty("UnifiedPosition", nPos);
		end
		
		EquipLingPai_OperatingSJ_Init()
		this:Show()
		g_ObjCared = tonumber( arg1 )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		return
	
	end
	
	if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_UI_Command then
		EquipLingPai_OperatingSJ_Init()
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
	
	if (event == "RL_OPSJ_PUTIN_EQUIP"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipLingPai_OperatingSJ_OnItemDragedDropFromBag( tonumber(arg0)  )
		end
		return
	end
	
	if (event == "RL_OPSJ_PACKET_RCLICK"  and this:IsVisible()) then
		if arg0 ~= nil  then
			EquipLingPai_OperatingSJ_OnBagItemRClicked( tonumber(arg0)  )
		end
		return
	end 
	
	if (event == "RL_OPSJ_REMOVE_EQUIP"  and this:IsVisible()) then
		EquipLingPai_OperatingSJ_OnItemDragedDropAway()
		return
	end 

	if event == "HIDE_ON_SCENE_TRANSED"  then
        EquipLingPai_OperatingSJ_CleanUp()
		this:Hide()
	end
	
	if (event == "ADJEST_UI_POS" ) then
		EquipLingPai_OperatingSJ_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		EquipLingPai_OperatingSJ_On_ResetPos()
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
	
	if (event == "PACKAGE_ITEM_CHANGED_EX") then
		
		if this:IsVisible() and arg0 ~= nil and tonumber(arg0) == m_EquipBagIndex then
		
			EquipLingPai_OperatingSJ_Update_AfterLevelup()	
			
		end
		return
	end
	
end

--Window清空
function EquipLingPai_OperatingSJ_CleanUp()
	
	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
		
	for i=1,4 do
	
		m_ActionButton_Rs[i]:SetActionItem(-1)
		m_ActionButton_Rs[i]:SetProperty( "BackImage", "" )
		m_ActionButton_Rs[i]:SetToolTip( "" )

		m_Text_RsLevel[i]:SetText("")
		m_Image_NoMove[i]:Hide()
	end
	
	m_Rs_Idx = {}
	
	m_CurSel_Rs = -1
	m_Button_OK:Disable()
	
	
	m_Text_CurLevel:SetText("#{BHZB_140521_172}")
	m_Text_NeedItem:SetText("#{BHZB_140521_174}")
	m_Text_NeedNum:SetText("#{BHZB_140521_175}")
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")

end

--Window恢复默认状态
function EquipLingPai_OperatingSJ_Init()
	
	EquipLingPai_OperatingSJ_CleanUp()
	m_CheckButton_Page[1]:SetCheck(1)
	m_CheckButton_Page[2]:SetCheck(0)
	m_CheckButton_Page[3]:SetCheck(0)
	
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

end

--刷新界面
function EquipLingPai_OperatingSJ_Refresh()
	
	if m_EquipBagIndex == -1 then
	
		EquipLingPai_OperatingSJ_Init()
		return
		
	end
	
	local theAction = EnumAction(m_EquipBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		
		EquipLingPai_OperatingSJ_Init()
		return
		
	end
	
	m_ActionButton_Equip:SetActionItem(theAction:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	
	LifeAbility:Lua_RlOpRsList_Update(m_EquipBagIndex)
	
	for i=1,4 do
		m_ActionButton_Rs[i]:SetPushed(0)
		local nRsID = PlayerPackage:Lua_GetBagItemRl_Rs(m_EquipBagIndex , i-1)
			
		if nRsID == -2 then
		
			m_Rs_Idx[i] = nRsID
			m_ActionButton_Rs[i]:SetActionItem(-1)
			m_ActionButton_Rs[i]:SetProperty( "BackImage", g_RS_UnActived_Image )
			m_ActionButton_Rs[i]:SetToolTip( g_UnActived_tip[i] )
			m_Text_RsLevel[i]:SetText("#{BHZB_140521_59}")
			m_Image_NoMove[i]:Hide()
			
		elseif nRsID <= 0 then
				
			m_Rs_Idx[i] = -1
			m_ActionButton_Rs[i]:SetActionItem(-1)
			m_ActionButton_Rs[i]:SetProperty( "BackImage", "" )
			m_Text_RsLevel[i]:SetText("#{BHZB_140521_58}")
			m_Image_NoMove[i]:Hide()
				
		else
			
			m_Rs_Idx[i] = -3
			m_ActionButton_Rs[i]:SetProperty( "BackImage", "" )
			local uLevel = PlayerPackage:Lua_GetBagItemRl_RsLevel(m_EquipBagIndex , i-1)
			local strText = ScriptGlobal_Format("#{BHZB_140521_57}" ,tostring(uLevel))
			m_Text_RsLevel[i]:SetText(strText)
			m_Image_NoMove[i]:Show()
			
			local nAction = EnumAction( i - 1 , "rl_op_rs")
			if nAction:GetID() ~= 0 then
				
				m_ActionButton_Rs[i]:SetActionItem( nAction:GetID() )

			end
			
		end

	end
	
end

--从背包拖拽到UI
function EquipLingPai_OperatingSJ_OnItemDragedDropFromBag( iBagIndex )
	
	--如果是宝珠 ，提示去镶嵌页面
	if PlayerPackage:Lua_IsBagItemRS( iBagIndex ) == 1 then
		PushDebugMessage("#{BHZB_140521_259}")	--提示去镶嵌页面
		return
	end
	
	--是否是令牌
	if PlayerPackage:Lua_IsBagItemRL( iBagIndex ) ~= 1 then
		PushDebugMessage("#{BHZB_140521_69}")	
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipLingPai_OperatingSJ_Init()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipLingPai_OperatingSJ_Refresh()
	
end

--从背包内右键点击
function EquipLingPai_OperatingSJ_OnBagItemRClicked( iBagIndex )
	
	--如果是宝珠 ，提示去镶嵌页面
	if PlayerPackage:Lua_IsBagItemRS( iBagIndex ) == 1 then
		PushDebugMessage("#{BHZB_140521_259}")	--提示去镶嵌页面
		return
	end
	
	--是否是令牌
	if PlayerPackage:Lua_IsBagItemRL( iBagIndex ) ~= 1 then
		PushDebugMessage("#{BHZB_140521_69}")	
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipLingPai_OperatingSJ_Init()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipLingPai_OperatingSJ_Refresh()

end

--从ActionItem拖拽到Window之外
function EquipLingPai_OperatingSJ_OnItemDragedDropAway(  )
	
	EquipLingPai_OperatingSJ_CleanUp()
	EquipLingPai_OperatingSJ_Init()

end

--右键单击ActionItem
function EquipLingPai_OperatingSJ_OnActionItemRClicked(  )
	
	EquipLingPai_OperatingSJ_CleanUp()
	EquipLingPai_OperatingSJ_Init()

end

--左键单击ActionItem
function EquipLingPai_OperatingSJ_OnActionItemLClicked( nIndex )

	if m_Rs_Idx[nIndex] ~= nil and m_Rs_Idx[nIndex] == -3 then
		if m_ActionButton_Rs[m_CurSel_Rs] ~= nil then
			m_ActionButton_Rs[m_CurSel_Rs]:SetPushed(0)
		end
		
		m_CurSel_Rs = nIndex
		m_ActionButton_Rs[m_CurSel_Rs]:SetPushed(1)
		m_Button_OK:Enable()
		
		local uLevel = PlayerPackage:Lua_GetBagItemRl_RsLevel(m_EquipBagIndex , nIndex - 1)
		
		--承天雨露数量判断

		if uLevel >= 50  then
			local strText = ScriptGlobal_Format("#{BHZB_140521_173}" ,tostring(uLevel))
			m_Text_CurLevel:SetText("#{BHZB_140521_172}"..strText)
			m_Text_NeedItem:SetText("#{BHZB_140521_174}")
			m_Text_NeedNum:SetText("#{BHZB_140521_175}")
			return
		end
		
		local uNeedItemNum = g_RsLevelUp_NeedItem_Num[uLevel]
		local strItemName = PlayerPackage:GetItemName(g_RsLevelUp_NeedItem)
		
		local strText = ScriptGlobal_Format("#{BHZB_140521_173}" ,tostring(uLevel))
		m_Text_CurLevel:SetText("#{BHZB_140521_172}"..strText)
		m_Text_NeedItem:SetText("#{BHZB_140521_174}"..strItemName)
		strText = ScriptGlobal_Format( "#{BHZB_140521_176}", tostring(uNeedItemNum))
		m_Text_NeedNum:SetText("#{BHZB_140521_175}"..strText)
		
		m_StaticText_NeedMoney:SetProperty("MoneyNumber", tostring(g_SJ_NeedMoney))
		
	end
	
end

--点击分页
function EquipLingPai_OperatingSJ_OnPageButtonClicked(nIndex)
	
	Variable:SetVariable("RL_OP_Pos", m_MainFram:GetProperty("UnifiedPosition"), 1)

	if nIndex == 2 then
		if g_ObjCared ~= -1 then
			Lua_OpenRlOpPage(2 ,g_ObjCared )
			EquipLingPai_OperatingSJ_CleanUp()
			this:Hide()
		end
		return
	end
	
	if nIndex == 3 or nIndex == 4 then
		if IsZbs2018SpeicalServer() >= 1 then
			PushDebugMessage("#{WCBS_180307_20}")
			return
		end
	end
	
	if nIndex == 3 then
		if g_ObjCared ~= -1 then
			Lua_OpenRlOpPage(3 ,g_ObjCared )
			EquipLingPai_OperatingSJ_CleanUp()
			this:Hide()
		end
		return
	end

	if nIndex == 4 then
		if ( g_ObjCared ~= -1 ) then
			Lua_OpenRlOpPage( 4, g_ObjCared );
			EquipLingPai_OperatingSJ_CleanUp()
		end
		return
	end

end
--点击OK
function EquipLingPai_OperatingSJ_OnOkClicked(  )

	if m_CurSel_Rs  == -1 then
		return
	end
	
	if m_EquipBagIndex == -1 then
		return
	end
	
	if m_Rs_Idx[m_CurSel_Rs] == -3 then  --升级已镶嵌的符石
	
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name( "RsLevelUp_RL" );
			Set_XSCRIPT_ScriptID( 880001 );
			Set_XSCRIPT_Parameter( 0, m_EquipBagIndex     );         --- 装备背包索引
			Set_XSCRIPT_Parameter( 1, m_CurSel_Rs  - 1   );        --- 镶嵌的符石索引
			Set_XSCRIPT_ParamCount( 2 );
		Send_XSCRIPT();	
		return
	end
end

--点击Cancel
function EquipLingPai_OperatingSJ_OnCancelClicked(  )

	EquipLingPai_OperatingSJ_CleanUp()
	this:Hide()

end

--点击"X"
function EquipLingPai_OperatingSJ_OnCloseClicked(  )

	EquipLingPai_OperatingSJ_CleanUp()
	this:Hide()
	
end

function EquipLingPai_OperatingSJ_OnHiden(  )

	EquipLingPai_OperatingSJ_CleanUp()
	
end

function EquipLingPai_OperatingSJ_On_ResetPos()

	m_MainFram:SetProperty( "UnifiedPosition", g_MainFram_UnifiedPosition )
	
end

function EquipLingPai_OperatingSJ_Update_AfterLevelup()
	
	local nEquipBagIndex = m_EquipBagIndex
	local nCurSel_Rs = m_CurSel_Rs
	EquipLingPai_OperatingSJ_Init()
	
	m_EquipBagIndex = nEquipBagIndex
	EquipLingPai_OperatingSJ_Refresh()
	EquipLingPai_OperatingSJ_OnActionItemLClicked( nCurSel_Rs )
	
end