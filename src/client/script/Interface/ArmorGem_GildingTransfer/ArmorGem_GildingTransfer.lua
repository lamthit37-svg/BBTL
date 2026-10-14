--ArmorGem_GildingTransfer
--!!!reloadscript =ArmorGem_GildingTransfer

local g_ArmorGem_GildingTransfer_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Jewel_BagIndex_A = -1
local g_Jewel_BagIndex_B = -1

local m_ActionButton_Jewel_A
local m_ActionButton_Jewel_B

function ArmorGem_GildingTransfer_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	
	this:RegisterEvent("JEWEL_PLATE_TRANSFER_PUTIN", false)	
	this:RegisterEvent("JEWEL_PLATE_TRANSFER_RCLICK", false)
	this:RegisterEvent("JEWEL_PLATE_TRANSFER_REMOVE", false)

end

--=========
--OnLoad
--=========
function ArmorGem_GildingTransfer_OnLoad()

	g_ArmorGem_GildingTransfer_Frame_UnifiedPosition = ArmorGem_GildingTransfer_Frame:GetProperty("UnifiedPosition")

	m_ActionButton_Jewel_A = ArmorGem_GildingTransfer_BeforeGemItem
	m_ActionButton_Jewel_B = ArmorGem_GildingTransfer_AfterGemItem

end
--=========
--OnEvent
--=========
function ArmorGem_GildingTransfer_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 55500112 then
		if not this:IsVisible() then
			ArmorGem_GildingTransfer_CleanUp()
			this:Show()
			ArmorGem_GildingTransfer_Update()
			ArmorGem_GildingTransfer_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end	
	
	if event == "JEWEL_PLATE_TRANSFER_PUTIN" and this:IsVisible() then
		if tonumber(arg0) ~= nil and tonumber(arg1) ~= nil then
			ArmorGem_GildingTransfer_OnItemDragedDropFromBag(tonumber(arg0) ,tonumber(arg1))
		end
		return
	end
	
	if event == "JEWEL_PLATE_TRANSFER_RCLICK"  and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			ArmorGem_GildingTransfer_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "JEWEL_PLATE_TRANSFER_REMOVE" and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			ArmorGem_GildingTransfer_OnItemDragedDropAway(tonumber(arg0))
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_GildingTransfer_Frame_On_ResetPos()	 
		return
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_GildingTransfer_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_GildingTransfer_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end

end

--刷新界面
function ArmorGem_GildingTransfer_Update()
	
	ArmorGem_GildingTransfer_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_GildingTransfer_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		
	if g_Jewel_BagIndex_A == -1 then
		m_ActionButton_Jewel_A:SetActionItem(-1)
	else
	
		local theAction_A = EnumAction(g_Jewel_BagIndex_A, "packageitem")
		if theAction_A:GetID() == 0 then
			m_ActionButton_Jewel_A:SetActionItem(-1)
		else
			m_ActionButton_Jewel_A:SetActionItem(theAction_A:GetID())
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_A, 1)
		end
	end
		
	if g_Jewel_BagIndex_B == -1 then
		m_ActionButton_Jewel_B:SetActionItem(-1)
	else
	
		local theAction_B = EnumAction(g_Jewel_BagIndex_B, "packageitem")
		if theAction_B:GetID() == 0 then
			m_ActionButton_Jewel_B:SetActionItem(-1)
		else
			m_ActionButton_Jewel_B:SetActionItem(theAction_B:GetID())
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_B, 1)
		end
	end	

	if g_Jewel_BagIndex_A ~= -1 and g_Jewel_BagIndex_B ~= -1 then
		ArmorGem_GildingTransfer_Currency1Num:SetProperty("MoneyNumber", "2000000")
	else
		ArmorGem_GildingTransfer_Currency1Num:SetProperty("MoneyNumber", "0")
	end

end
--从背包内右键点击
function ArmorGem_GildingTransfer_OnBagItemRClicked(iBagIndex)
	if g_Jewel_BagIndex_A == -1 then
		ArmorGem_GildingTransfer_OnItemDragedDropFromBag(iBagIndex , 1)
	else
		ArmorGem_GildingTransfer_OnItemDragedDropFromBag(iBagIndex , 2)
	end	
end
--从背包拖拽到UI
function ArmorGem_GildingTransfer_OnItemDragedDropFromBag(iBagIndex, iSlotIdx)
	
	if iSlotIdx == 1 then
		if PlayerPackage:LuaFnIsUnderArmourJewel(iBagIndex) ~= 1 then
			PushDebugMessage("#{NJBZ_220816_265}")
			return
		end

		--加锁
		if PlayerPackage:IsLock(iBagIndex) == 1 then
			PushDebugMessage("#{NJBZ_220816_252}")	
			return
		end

		--释放原来的装备
		if g_Jewel_BagIndex_A ~= -1 then
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_A, 0)
		end

		g_Jewel_BagIndex_A = iBagIndex

		--刷新界面
		ArmorGem_GildingTransfer_Update()
		return

	end
	
	if iSlotIdx == 2 then		
		if PlayerPackage:LuaFnIsUnderArmourJewel(iBagIndex) ~= 1 then
			PushDebugMessage("#{NJBZ_220816_265}")
			return		
		end

		--加锁
		if PlayerPackage:IsLock(iBagIndex) == 1 then
			PushDebugMessage("#{NJBZ_220816_252}")	
			return
		end

		if g_Jewel_BagIndex_B ~= -1 then
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_B, 0)
		end
		g_Jewel_BagIndex_B = iBagIndex

		--刷新界面
		ArmorGem_GildingTransfer_Update()
		return

	end
end

function ArmorGem_GildingTransfer_OnItemDragedDropAway(iSlotIdx)
	ArmorGem_GildingTransfer_NoJewel(iSlotIdx)
end

function ArmorGem_GildingTransfer_OnJewelItemRClicked(iSlotIdx)
	ArmorGem_GildingTransfer_NoJewel(iSlotIdx)
end

function ArmorGem_GildingTransfer_NoJewel(iSlotIdx)

	if iSlotIdx == 1 then
		if g_Jewel_BagIndex_A ~= -1 then
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_A, 0)
		end
		g_Jewel_BagIndex_A = -1
		ArmorGem_GildingTransfer_Update()
		return 
	end

	if iSlotIdx == 2 then
		if g_Jewel_BagIndex_B ~= -1 then
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_B, 0)
		end
		g_Jewel_BagIndex_B = -1
		ArmorGem_GildingTransfer_Update()
		return
	end

end

function ArmorGem_GildingTransfer_OKClicked()
	
	if g_Jewel_BagIndex_A == -1 or g_Jewel_BagIndex_B == -1 then
		return	
	end

	if PlayerPackage:LuaFnIsUnderArmourJewel(g_Jewel_BagIndex_A) ~= 1 then
		return		
	end
	
	if PlayerPackage:LuaFnIsUnderArmourJewel(g_Jewel_BagIndex_B) ~= 1 then
		return		
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UnderArmourPlateTransfer")
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Jewel_BagIndex_A)
		Set_XSCRIPT_Parameter(2, g_Jewel_BagIndex_B)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()

end

function ArmorGem_GildingTransfer_CloseClicked()
	this:Hide()
end

function ArmorGem_GildingTransfer_CleanUp()

	ArmorGem_GildingTransfer_Currency1Num:SetProperty("MoneyNumber", "0")
	ArmorGem_GildingTransfer_Currency2Num:SetProperty("MoneyNumber", "0")
	ArmorGem_GildingTransfer_Currency3Num:SetProperty("MoneyNumber", "0")
		
	m_ActionButton_Jewel_A:SetActionItem(-1)
	m_ActionButton_Jewel_B:SetActionItem(-1)
	
	if g_Jewel_BagIndex_A ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_A, 0)
	end
	g_Jewel_BagIndex_A = -1
	
	if g_Jewel_BagIndex_B ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex_B, 0)
	end
	g_Jewel_BagIndex_B = -1

end

function ArmorGem_GildingTransfer_OnHidden()
	ArmorGem_GildingTransfer_CleanUp()
	m_ObjServerId = -1
end

function ArmorGem_GildingTransfer_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_GildingTransfer_Frame_On_ResetPos()
	if g_ArmorGem_GildingTransfer_Frame_UnifiedPosition ~= nil then
		ArmorGem_GildingTransfer_Frame:SetProperty("UnifiedPosition", g_ArmorGem_GildingTransfer_Frame_UnifiedPosition)
	end
end

function ArmorGem_GildingTransfer_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
