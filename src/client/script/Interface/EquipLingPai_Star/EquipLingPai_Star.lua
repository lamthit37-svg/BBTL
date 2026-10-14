local m_EquipBagIndex = -1

local g_ObjCared = -1
local g_UI_Command = 201406285

local g_MainFram_UnifiedPosition

local g_NeedMoney = 20000

--控件变量
local m_MainFram
local m_ActionButton_Equip
local m_Button_OK
local m_Text_StarInfo
local m_Text_NextStarInfo
local m_Text_Success
local m_Text_MustSuccessNum

local m_Text_CurLevel
local m_Text_NeedItem
local m_Text_NeedNum
local m_CheckButton_Page = {}

local m_StaticText_NeedMoney
local m_StaticText_HaveJZ
local m_StaticText_HaveMoney

local g_QuickPurchaseCheck = 1
local g_AutoRiseStar = 0

function EquipLingPai_Star_PreLoad( )

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("RL_STAR_PUTIN_EQUIP")	
	this:RegisterEvent("RL_STAR_PACKET_RCLICK")	
	this:RegisterEvent("RL_STAR_REMOVE_EQUIP")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	
	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR")
end

function EquipLingPai_Star_OnLoad( )
	
	m_MainFram = EquipLingPai_Star_Frame
	m_ActionButton_Equip = EquipLingPai_Star_Object
	m_Button_OK = EquipLingPai_Star_OK
	
	m_Text_StarInfo = EquipLingPai_Star_ZhanShi1_Text
	m_Text_NextStarInfo = EquipLingPai_Star_ZhanShi2_Text
	m_Text_Success = EquipLingPai_Star_Info4
	m_Text_MustSuccessNum = EquipLingPai_Star_Info6
	
	m_StaticText_NeedMoney =  EquipLingPai_Star_NeedMoney
	m_StaticText_HaveJZ =  EquipLingPai_Star_SelfJiaozi
	m_StaticText_HaveMoney =  EquipLingPai_Star_SelfMoney
	
	g_MainFram_UnifiedPosition = EquipLingPai_Star_Frame:GetProperty( "UnifiedPosition" )

end

function EquipLingPai_Star_OnEvent( event )

	if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_UI_Command then
		EquipLingPai_Star_Init()
		this:Show()
		g_ObjCared = -1
		local xx = Get_XParam_INT( 0 )
		g_ObjCared = DataPool : GetNPCIDByServerID( xx )
		if g_ObjCared == -1 then
			return
		end
		this:CareObject( g_ObjCared, 1)
		g_AutoRiseStar = 0
		EquipLingPai_Star_Zidong:SetText("#{LPZDSX_161107_3}")
		return
	end
	
	if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == 20161110 then
		EquipLingPai_Star_Auto_Stop()
		return
	end
	
	if (event == "RL_STAR_PUTIN_EQUIP"  and this:IsVisible()) then
		if arg0 ~= nil then
			EquipLingPai_Star_OnItemDragedDropFromBag( tonumber(arg0)  )
		end
		return
	end
	
	if (event == "RL_STAR_PACKET_RCLICK"  and this:IsVisible()) then
		if arg0 ~= nil  then
			EquipLingPai_Star_OnBagItemRClicked( tonumber(arg0)  )
		end
		return
	end
	
	if (event == "RL_STAR_REMOVE_EQUIP"  and this:IsVisible()) then
		EquipLingPai_Star_OnItemDragedDropAway()
		return
	end 
	
	if event == "HIDE_ON_SCENE_TRANSED"  then
        EquipLingPai_Star_CleanUp()
		this:Hide()
		if g_AutoRiseStar == 1 then
			EquipLingPai_Star_Auto_Stop()
		end
		return
	end
	
	if (event == "ADJEST_UI_POS" ) then
		EquipLingPai_Star_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		EquipLingPai_Star_On_ResetPos()
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
	
	if (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_EquipBagIndex then
			EquipLingPai_Star_Refresh()
		end 
		return
	end

	if (event == "GAMELOGIN_OPEN_SELECT_CHARACTOR" ) then
		g_QuickPurchaseCheck = 1
		return
	end
end

--Window清空
function EquipLingPai_Star_CleanUp()
	
	m_ActionButton_Equip:SetActionItem(-1)
	
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end

	m_EquipBagIndex = -1
		
	m_Button_OK:Disable()

	m_Text_StarInfo:SetText("")
	m_Text_NextStarInfo:SetText("")
	m_Text_Success:SetText("")
	m_Text_MustSuccessNum:SetText("")
	
	m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
	
	if g_QuickPurchaseCheck == 1 then
		EquipLingPai_Star_ZidongCheckButton:SetProperty("Selected", "True")
	else
		EquipLingPai_Star_ZidongCheckButton:SetProperty("Selected", "False")
	end	
	
	EquipLingPai_Star_Zidong:Disable()
	EquipLingPai_Star_Zidong_Animate:Play(false)
end

--Window恢复默认状态
function EquipLingPai_Star_Init()

	EquipLingPai_Star_CleanUp()
	m_StaticText_HaveMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	m_StaticText_HaveJZ:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
end

function EquipLingPai_Star_Refresh()

	if m_EquipBagIndex == -1 then
	
		EquipLingPai_Star_Init()
		return
		
	end
	
	local theAction = EnumAction(m_EquipBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		
		EquipLingPai_Star_Init()
		return
		
	end
	
	m_ActionButton_Equip:SetActionItem(theAction:GetID())
	LifeAbility : Lock_Packet_Item(m_EquipBagIndex,1)
	
	local nStarLevel , nStarEffect , strSuccess , nMustSuccessTry ,nNextStarLevel , nNextStarEffect  = PlayerPackage:Lua_GetBagItemRl_StarInfo(m_EquipBagIndex)
	
	if nStarLevel and nStarLevel > 0 then
	
		m_Text_StarInfo:SetText("#{BHZB_140521_234}#G"..tostring(nStarLevel).."#r#{BHZB_140521_236}#G"..tostring(nStarEffect).."%#r#{BHZB_140521_237}#G"..tostring(nStarEffect).."%")
		if nStarLevel < 8 then
			m_Text_Success:SetText(strSuccess)
			m_Text_MustSuccessNum:SetText(tostring(nMustSuccessTry))
			m_Text_NextStarInfo:SetText("#{BHZB_140521_234}#G"..tostring(nNextStarLevel).."#r#{BHZB_140521_236}#G"..tostring(nNextStarEffect).."%#r#{BHZB_140521_237}#G"..tostring(nNextStarEffect).."%")
			m_Button_OK:Enable()
			m_StaticText_NeedMoney:SetProperty("MoneyNumber", tostring(g_NeedMoney))
			EquipLingPai_Star_Zidong:Enable()
			EquipLingPai_Star_Zidong_Animate:Play(true)
		else
			m_Text_Success:SetText("")
			m_Text_MustSuccessNum:SetText("")
			m_Text_NextStarInfo:SetText("#{BHZB_140521_234}#{BHZB_140521_250}#r#{BHZB_140521_236}#{BHZB_140521_250}#r#{BHZB_140521_237}#{BHZB_140521_250}")
			m_Button_OK:Disable()
			m_StaticText_NeedMoney:SetProperty("MoneyNumber", "0")
			EquipLingPai_Star_Zidong:Disable()
			EquipLingPai_Star_Zidong_Animate:Play(false)
		end

	end
	
end

--从背包拖拽到UI
function EquipLingPai_Star_OnItemDragedDropFromBag( iBagIndex )
	if g_AutoRiseStar == 1 then
		PushDebugMessage("#{LPZDSX_161107_11}") 
		return 
	end
	
	--是否是令牌
	if PlayerPackage:Lua_IsBagItemRL( iBagIndex ) ~= 1 then
		PushDebugMessage("#{BHZB_140521_109}")	
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipLingPai_Star_Init()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipLingPai_Star_Refresh()
end

--从背包内右键点击
function EquipLingPai_Star_OnBagItemRClicked( iBagIndex )
	
	if g_AutoRiseStar == 1 then
		PushDebugMessage("#{LPZDSX_161107_11}") 
		return 
	end
	
	--是否是令牌
	if PlayerPackage:Lua_IsBagItemRL( iBagIndex ) ~= 1 then
		PushDebugMessage("#{BHZB_140521_109}")	
		return
	end
	
	--释放原来的装备
	if m_EquipBagIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(m_EquipBagIndex,0)
	end
	
	EquipLingPai_Star_Init()
	m_EquipBagIndex = iBagIndex
	--刷新界面
	EquipLingPai_Star_Refresh()	

end

--从ActionItem拖拽到Window之外
function EquipLingPai_Star_OnItemDragedDropAway(  )
	if g_AutoRiseStar == 1 then
		PushDebugMessage("#{LPZDSX_161107_11}") 
		return 
	end
	
	EquipLingPai_Star_CleanUp()
	EquipLingPai_Star_Init()

end

--右键单击ActionItem
function EquipLingPai_Star_OnActionItemRClicked(  )
	
	if g_AutoRiseStar == 1 then
		PushDebugMessage("#{LPZDSX_161107_11}") 
		return 
	end
	
	EquipLingPai_Star_CleanUp()
	EquipLingPai_Star_Init()

end

--左键单击ActionItem
function EquipLingPai_Star_OnActionItemLClicked(  )


end

--点击OK
function EquipLingPai_Star_OnOkClicked(  )
	
	if g_AutoRiseStar == 1 then
		PushDebugMessage("#{LPZDSX_161107_11}") 
		return 
	end
	
	if m_EquipBagIndex == -1 then
		return
	end
	

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name( "RL_StarLevelup" );
		Set_XSCRIPT_ScriptID( 880001 );
		Set_XSCRIPT_Parameter( 0, m_EquipBagIndex     );         --- 装备背包索引
		Set_XSCRIPT_Parameter( 1, g_QuickPurchaseCheck     );         ---自动购买确认
		Set_XSCRIPT_ParamCount( 2 );
	Send_XSCRIPT();	

end

--点击Cancel
function EquipLingPai_Star_OnCancelClicked(  )

	EquipLingPai_Star_CleanUp()
	this:Hide()

	if g_AutoRiseStar == 1 then
		EquipLingPai_Star_Auto_Stop()
		PushDebugMessage("#{LPZDSX_161107_17}")
	end
end

--点击"X"
function EquipLingPai_Star_OnCloseClicked(  )

	EquipLingPai_Star_CleanUp()
	this:Hide()
	
	if g_AutoRiseStar == 1 then
		EquipLingPai_Star_Auto_Stop()
		PushDebugMessage("#{LPZDSX_161107_17}")
	end
end

function EquipLingPai_Star_OnHiden(  )

	EquipLingPai_Star_CleanUp()
	
	if g_AutoRiseStar == 1 then
		EquipLingPai_Star_Auto_Stop()
		PushDebugMessage("#{LPZDSX_161107_17}")
	end
end

function EquipLingPai_Star_On_ResetPos()

	m_MainFram:SetProperty( "UnifiedPosition", g_MainFram_UnifiedPosition )
	
end

--自动购买
function EquipLingPai_Star_ZidongCheck_Clicked()

	if g_QuickPurchaseCheck == 1 then
		g_QuickPurchaseCheck = 0
		EquipLingPai_Star_ZidongCheckButton:SetProperty("Selected", "False")
	else
		g_QuickPurchaseCheck = 1
		EquipLingPai_Star_ZidongCheckButton:SetProperty("Selected", "True")
	end

end

--自动升星
function EquipLingPai_Star_Zidong_Clicked()

	if g_AutoRiseStar == 0 then
		--开始一键升星
		g_AutoRiseStar = 1
		EquipLingPai_Star_Zidong:SetText("#{LPZDSX_161107_4}")
    SetTimer("EquipLingPai_Star","EquipLingPai_Star_Auto_Timeproc()", 300)
    
	elseif g_AutoRiseStar == 1 then
		--停止一键升星
		EquipLingPai_Star_Auto_Stop()
		PushDebugMessage("#{LPZDSX_161107_17}")
	end

end

function EquipLingPai_Star_Auto_Rising()
	if this:IsVisible() == false then 
		return 0
	end
	
	if g_AutoRiseStar ~= 1 then
		return 0
	end

	if m_EquipBagIndex == -1 then
		PushDebugMessage("#{ZBQH_130521_14}")
		return 0
	end
	
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return 0
	end 
	
	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return 0
	end
	
	local equipQual = tonumber(PlayerPackage:GetSuperWeaponQual(m_EquipBagIndex));
	
	if equipQual <= 0 then
		PushDebugMessage("#{ZBQH_130521_14}")
		return 0
	end
	
	if equipQual >= 8 then
		PushDebugMessage("#{LPZDSX_161107_16}")
		return 0
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_NeedMoney then
		PushDebugMessage("#{LPZDSX_161107_12}")
		return 0
	end 
		
	--唤灵液
	local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38000932));
	if index1 == -1 then
		local index2,BindState2 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38000933))
		if index2 == -1 then
			PushDebugMessage("#{LPZDSX_161107_13}")
			return 0
		end
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RL_StarLevelup_Auto" );
		Set_XSCRIPT_ScriptID( 880001 );
		Set_XSCRIPT_Parameter( 0, m_EquipBagIndex     );         --- 装备背包索引
		Set_XSCRIPT_ParamCount( 1 );
	Send_XSCRIPT()
	return 1
end

function EquipLingPai_Star_Auto_Timeproc()

	local ret = EquipLingPai_Star_Auto_Rising()
	if ret == 0 then
		EquipLingPai_Star_Auto_Stop()
	end

end

function EquipLingPai_Star_Auto_Stop()

	g_AutoRiseStar = 0
	EquipLingPai_Star_Zidong:SetText("#{LPZDSX_161107_3}")
	EquipLingPai_Star_OK:Enable()
	KillTimer("EquipLingPai_Star_Auto_Timeproc()")

end
