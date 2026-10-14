--ArmorGem_Handle
--!!!reloadscript =ArmorGem_Handle

local g_ArmorGem_Handle_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_UI_Type = 1
local g_Jewel_BagIndex = -1
local g_CompoundChipId = -1

function ArmorGem_Handle_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	
	this:RegisterEvent("UA_JEWEL_COMPOUND_PUTIN", false)
	this:RegisterEvent("UA_JEWEL_COMPOUND_RCLICK", false)
	this:RegisterEvent("UA_JEWEL_COMPOUND_REMOVE", false)
end

function ArmorGem_Handle_OnLoad()
	g_ArmorGem_Handle_Frame_UnifiedPosition = ArmorGem_Handle_Frame:GetProperty("UnifiedPosition")	
end

function ArmorGem_Handle_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500109 then
		if not this:IsVisible() then
			g_UI_Type = 1
			ArmorGem_Handle_CleanUp(g_UI_Type)
			this:Show()
			ArmorGem_Handle_Update()
			ArmorGem_Handle_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end	
	
	if event == "UI_COMMAND" and tonumber(arg0) == 55500111 then
		ArmorGem_Handle_CleanUp(g_UI_Type)
		ArmorGem_Handle_Update()
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_Handle_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_Handle_Compose_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_Handle_Compose_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		
		ArmorGem_Handle_Split_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_Handle_Split_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end

	if event == "UA_JEWEL_COMPOUND_PUTIN" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Handle_OnItemDragedDropFromBag(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_JEWEL_COMPOUND_RCLICK" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Handle_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_JEWEL_COMPOUND_REMOVE" then
		ArmorGem_Handle_OnItemDragedDropAway()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		ArmorGem_Handle_Update()
		return
	end
	
end

function ArmorGem_Handle_Update()
	
	local strTemp = ""

	ArmorGem_Handle_Compose_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_Handle_Compose_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	ArmorGem_Handle_Split_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_Handle_Split_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	if g_UI_Type == 1 then
		ArmorGem_Handle_DragTitle:SetText("#{NJBZ_220816_295}")
		ArmorGem_Handle_Page1:SetCheck(1)
		ArmorGem_Handle_Page2:SetCheck(0)
		ArmorGem_Handle_ComposeFrame:Show()
		ArmorGem_Handle_SplitFrame:Hide()
		
		ArmorGem_Handle_Compose_FragGemItemNum:SetText("")
		ArmorGem_Handle_Compose_FragGemItem:SetActionItem(-1)
		ArmorGem_Handle_Compose_CompleteGemItem:SetActionItem(-1)

		if g_CompoundChipId ~= -1 then

			LifeAbility:Lock_Packet_ItemByID(g_CompoundChipId, 1)

			local jewel_id, need_item_count, need_money = DataPool:LuaFnGetUnderArmourJewelCompoundInfo(g_CompoundChipId)
			ArmorGem_Handle_Compose_Currency1Num:SetProperty("MoneyNumber", tostring(need_money))
			
			local have_count = PlayerPackage:Lua_GetUnLockItemCount(g_CompoundChipId)
			local have_bind_count = PlayerPackage:Lua_GetUnLockBindItemCount(g_CompoundChipId)
			if have_bind_count > 0 then
				local itemAction = DataPool:CreateBindActionItemForShow(g_CompoundChipId, 1)
				ArmorGem_Handle_Compose_FragGemItem:SetActionItem(itemAction:GetID())
				
				itemAction = DataPool:CreateBindActionItemForShow(jewel_id, 1)
				ArmorGem_Handle_Compose_CompleteGemItem:SetActionItem(itemAction:GetID())
			else
				local itemAction = DataPool:CreateActionItemForShow(g_CompoundChipId, 1)
				ArmorGem_Handle_Compose_FragGemItem:SetActionItem(itemAction:GetID())
				
				itemAction = DataPool:CreateActionItemForShow(jewel_id, 1)
				ArmorGem_Handle_Compose_CompleteGemItem:SetActionItem(itemAction:GetID())
			end
			
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_299}", tostring(have_count))
			ArmorGem_Handle_Compose_FragGemItemNum:SetText(strTemp)			
		end
	else
		ArmorGem_Handle_DragTitle:SetText("#{NJBZ_220816_306}")
		ArmorGem_Handle_Page1:SetCheck(0)
		ArmorGem_Handle_Page2:SetCheck(1)
		ArmorGem_Handle_ComposeFrame:Hide()
		ArmorGem_Handle_SplitFrame:Show()
		
		ArmorGem_Handle_Split_FragGemItem:SetActionItem(-1)
		ArmorGem_Handle_Split_CompleteGemItem:SetActionItem(-1)

		if g_Jewel_BagIndex ~= -1 then

			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 1)
			local theAction = EnumAction(g_Jewel_BagIndex, "packageitem")
			ArmorGem_Handle_Split_FragGemItem:SetActionItem(theAction:GetID())
			
			local jewel_id = PlayerPackage:GetItemTableIndex(g_Jewel_BagIndex)
			local isBind = GetItemBindStatus(g_Jewel_BagIndex)
			
			local gain_item, gain_item_count, need_money = DataPool:LuaFnGetUnderArmourJewelRecycleInfo(jewel_id)
			ArmorGem_Handle_Split_Currency1Num:SetProperty("MoneyNumber", tostring(need_money))
			
			if isBind ~= 0 then
				local itemAction = DataPool:CreateBindActionItemForShow(gain_item, gain_item_count)
				ArmorGem_Handle_Split_CompleteGemItem:SetActionItem(itemAction:GetID())
			else
				local itemAction = DataPool:CreateActionItemForShow(gain_item, gain_item_count)
				ArmorGem_Handle_Split_CompleteGemItem:SetActionItem(itemAction:GetID())
			end
		end
	end
end

--从背包拖拽到UI
function ArmorGem_Handle_OnItemDragedDropFromBag(iBagIndex)

	if g_UI_Type == 1 then
		if PlayerPackage:LuaFnIsUnderArmourJewelChip(iBagIndex) ~= 1 then
			return
		end

		--加锁
		if PlayerPackage:IsLock(iBagIndex) == 1 then
			PushDebugMessage("#{NJBZ_220816_252}")
			return
		end
		
		local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
		if g_CompoundChipId > 0 then
			LifeAbility:Lock_Packet_ItemByID(g_CompoundChipId, 0)
		end
		g_CompoundChipId = item_table_index		
		ArmorGem_Handle_Update()
	end
	
	if g_UI_Type == 2 then	
		if PlayerPackage:LuaFnIsUnderArmourJewel(iBagIndex) ~= 1 then
			return
		end

		--加锁
		if PlayerPackage:IsLock(iBagIndex) == 1 then
			PushDebugMessage("#{NJBZ_220816_252}")
			return
		end
		
		if g_Jewel_BagIndex >= 0 then
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		end
		g_Jewel_BagIndex = iBagIndex	

		ArmorGem_Handle_Update()
	end
end

function ArmorGem_Handle_OnBagItemRClicked(iBagIndex)
	ArmorGem_Handle_OnItemDragedDropFromBag(iBagIndex)
end

function ArmorGem_Handle_Split_FragGemItem_OnRBClicked()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_Handle_Update()
	end
end

function ArmorGem_Handle_Compose_FragGemItem_OnRBClicked()
	if g_CompoundChipId ~= -1 then
		LifeAbility:Lock_Packet_ItemByID(g_CompoundChipId, 0)
		g_CompoundChipId = -1
		ArmorGem_Handle_Update()
	end
end

function ArmorGem_Handle_OnItemDragedDropAway()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_Handle_Update()
	end
end

function ArmorGem_Handle_PageClicked(iIndex)
	if g_UI_Type ~= iIndex then
		ArmorGem_Handle_CleanUp(g_UI_Type)
		g_UI_Type = iIndex		
		ArmorGem_Handle_Update()
	end
end

function ArmorGem_Handle_CloseClicked()
	this:Hide()
end

function ArmorGem_Handle_CleanUp(iType)

	if iType == 0 or iType == 1 then
		ArmorGem_Handle_Compose_Currency1Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Handle_Compose_Currency2Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Handle_Compose_Currency3Num:SetProperty("MoneyNumber", "0")
		
		ArmorGem_Handle_Compose_FragGemItemNum:SetText("")
		ArmorGem_Handle_Compose_FragGemItem:SetActionItem(-1)
		ArmorGem_Handle_Compose_CompleteGemItem:SetActionItem(-1)
		if g_CompoundChipId ~= -1 then
			LifeAbility:Lock_Packet_ItemByID(g_CompoundChipId, 0)
		end
		g_CompoundChipId = -1
	end

	if iType == 0 or iType == 2 then
		ArmorGem_Handle_Split_Currency1Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Handle_Split_Currency2Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Handle_Split_Currency3Num:SetProperty("MoneyNumber", "0")

		ArmorGem_Handle_Split_FragGemItem:SetActionItem(-1)
		ArmorGem_Handle_Split_CompleteGemItem:SetActionItem(-1)
		
		if g_Jewel_BagIndex ~= -1 then
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		end
		g_Jewel_BagIndex = -1
	end	
end

function ArmorGem_Handle_OnHidden()
	ArmorGem_Handle_CleanUp(0)
	m_ObjServerId = -1
end

function ArmorGem_Handle_Compse_OKClicked()
	if g_CompoundChipId == -1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourJewelCompound")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_CompoundChipId)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function ArmorGem_Handle_Split_OKClicked()
	if g_Jewel_BagIndex == -1 then
		PushDebugMessage("#{NJBZ_220816_313}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourJewelRecycle")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Jewel_BagIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function ArmorGem_Handle_HelpClicked()

end
--Care Obj
function ArmorGem_Handle_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_Handle_Frame_On_ResetPos()
	if g_ArmorGem_Handle_Frame_UnifiedPosition ~= nil then
		ArmorGem_Handle_Frame:SetProperty("UnifiedPosition", g_ArmorGem_Handle_Frame_UnifiedPosition)
	end
end

function ArmorGem_Handle_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end