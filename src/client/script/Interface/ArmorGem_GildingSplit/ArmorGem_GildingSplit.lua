--ArmorGem_GildingSplit
--!!!reloadscript =ArmorGem_GildingSplit

local g_ArmorGem_GildingSplit_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Jewel_BagIndex = -1

local g_PlateResetItem = {
	[1] = 38007044,
	[2] = 38007045,
	[3] = 38007046,
	[4] = 38007047,
	[5] = 38007048,
	[6] = 38007049,
	[7] = 38007050,
}

function ArmorGem_GildingSplit_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	
	this:RegisterEvent("UA_PLATE_RESET_PUTIN", false)
	this:RegisterEvent("UA_PLATE_RESET_RCLICK", false)
	this:RegisterEvent("UA_PLATE_RESET_REMOVE", false)
end

function ArmorGem_GildingSplit_OnLoad()
	g_ArmorGem_GildingSplit_Frame_UnifiedPosition = ArmorGem_GildingSplit_Frame:GetProperty("UnifiedPosition")	
end

function ArmorGem_GildingSplit_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500121 then
		if not this:IsVisible() then
			ArmorGem_GildingSplit_CleanUp()
			this:Show()
			ArmorGem_GildingSplit_Update()
			ArmorGem_GildingSplit_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end	

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_GildingSplit_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_GildingSplit_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_GildingSplit_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		
		ArmorGem_GildingSplit_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_GildingSplit_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end

	if event == "UA_PLATE_RESET_PUTIN" then
		if tonumber(arg0) ~= nil then
			ArmorGem_GildingSplit_OnItemDragedDropFromBag(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_PLATE_RESET_RCLICK" then
		if tonumber(arg0) ~= nil then
			ArmorGem_GildingSplit_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_PLATE_RESET_REMOVE" then
		ArmorGem_GildingSplit_OnItemDragedDropAway()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		ArmorGem_GildingSplit_Update()
		return
	end
	
end

function ArmorGem_GildingSplit_Check()
	if g_Jewel_BagIndex ~= -1 then
		if PlayerPackage:LuaFnIsUnderArmourJewel(g_Jewel_BagIndex) ~= 1 then
			return 0
		end
		
		local jewel_plate, jewel_plate_level = PlayerPackage:LuaFnGetUnderArmourJewelPlateInfo(g_Jewel_BagIndex)
		if tonumber(jewel_plate) ~= nil and tonumber(jewel_plate) == 0 then
			return 0
		end	

		--加锁
		if PlayerPackage:IsLock(g_Jewel_BagIndex) == 1 then
			return 0
		end
		
		return 1
	end
	
	return 0
end

function ArmorGem_GildingSplit_Update()
		
	local strTemp = ""

	ArmorGem_GildingSplit_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_GildingSplit_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	ArmorGem_GildingSplit_BeforeGemItem:SetActionItem(-1)
	ArmorGem_GildingSplit_AfterGemItem:SetActionItem(-1)
	ArmorGem_GildingSplit_AfterGemItem2:SetActionItem(-1)
	
	ArmorGem_GildingSplit_BeforeGemItemStarLevel:SetText("")
	ArmorGem_GildingSplit_BeforeGemItemGildingLevel:SetText("")
	ArmorGem_GildingSplit_AfterGemItemStarLevel:SetText("")

	if g_Jewel_BagIndex ~= -1 then

		if ArmorGem_GildingSplit_Check() ~= 1 then
			ArmorGem_GildingSplit_Currency1Num:SetProperty("MoneyNumber", "0")
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
			g_Jewel_BagIndex = -1
			return
		end
		
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 1)
		local theAction = EnumAction(g_Jewel_BagIndex, "packageitem")
		ArmorGem_GildingSplit_BeforeGemItem:SetActionItem(theAction:GetID())
		
		local jewel_id = PlayerPackage:GetItemTableIndex(g_Jewel_BagIndex)
		local isBind = GetItemBindStatus(g_Jewel_BagIndex)
		local jewel_data = PlayerPackage:Lua_GetItemAttachParam(g_Jewel_BagIndex, 4, 2)
		local jewel_level = math.floor(jewel_data / 1000)
		local jewel_plate = math.floor(math.mod(jewel_data, 1000) / 10)
		local jewel_plate_level = math.mod(jewel_data, 10)
		
		strTemp = ScriptGlobal_Format("#{NJBZ_230703_13}" ,tostring(jewel_level + 1))
		ArmorGem_GildingSplit_BeforeGemItemStarLevel:SetText(strTemp)
		ArmorGem_GildingSplit_AfterGemItemStarLevel:SetText(strTemp)
		strTemp = ScriptGlobal_Format("#{NJBZ_230703_14}" ,tostring(jewel_plate_level + 1))
		ArmorGem_GildingSplit_BeforeGemItemGildingLevel:SetText(strTemp)
	
		ArmorGem_GildingSplit_Currency1Num:SetProperty("MoneyNumber", tostring(100000))
		
		local newJewelAction = DataPool:LuaFnCreateUnderArmorJewelAfterPlateReset(g_Jewel_BagIndex)
		ArmorGem_GildingSplit_AfterGemItem:SetActionItem(newJewelAction:GetID())
		
		local jewel_plate, jewel_plate_level = PlayerPackage:LuaFnGetUnderArmourJewelPlateInfo(g_Jewel_BagIndex)
		if tonumber(jewel_plate) ~= nil and tonumber(jewel_plate_level) ~= nil and g_PlateResetItem[jewel_plate] ~= nil then
			local gain_item = g_PlateResetItem[jewel_plate]
			local gain_item_count = 50 * (jewel_plate_level + 1)
			if isBind ~= 0 then
				local itemAction = DataPool:CreateBindActionItemForShow(gain_item, gain_item_count)
				ArmorGem_GildingSplit_AfterGemItem2:SetActionItem(itemAction:GetID())
			else
				local itemAction = DataPool:CreateActionItemForShow(gain_item, gain_item_count)
				ArmorGem_GildingSplit_AfterGemItem2:SetActionItem(itemAction:GetID())
			end
		end
	end

end

--从背包拖拽到UI
function ArmorGem_GildingSplit_OnItemDragedDropFromBag(iBagIndex)

	if PlayerPackage:LuaFnIsUnderArmourJewel(iBagIndex) ~= 1 then
		PushDebugMessage("#{NJBZ_230703_09}")
		return
	end
	
	local jewel_plate, jewel_plate_level = PlayerPackage:LuaFnGetUnderArmourJewelPlateInfo(iBagIndex)
	if tonumber(jewel_plate) ~= nil and tonumber(jewel_plate) == 0 then
		PushDebugMessage("#{NJBZ_230703_09}")
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

	ArmorGem_GildingSplit_Update()

end

function ArmorGem_GildingSplit_OnBagItemRClicked(iBagIndex)
	ArmorGem_GildingSplit_OnItemDragedDropFromBag(iBagIndex)
end

function ArmorGem_GildingSplit_OnJewelItemRClicked()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_GildingSplit_Update()
	end
end

function ArmorGem_GildingSplit_OnItemDragedDropAway()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_GildingSplit_Update()
	end
end

function ArmorGem_GildingSplit_CloseClicked()
	this:Hide()
end

function ArmorGem_GildingSplit_CleanUp()
	ArmorGem_GildingSplit_Currency1Num:SetProperty("MoneyNumber", "0")
	ArmorGem_GildingSplit_Currency2Num:SetProperty("MoneyNumber", "0")
	ArmorGem_GildingSplit_Currency3Num:SetProperty("MoneyNumber", "0")

	ArmorGem_GildingSplit_BeforeGemItem:SetActionItem(-1)
	ArmorGem_GildingSplit_AfterGemItem:SetActionItem(-1)
	ArmorGem_GildingSplit_AfterGemItem2:SetActionItem(-1)
	
	ArmorGem_GildingSplit_BeforeGemItemStarLevel:SetText("")
	ArmorGem_GildingSplit_BeforeGemItemGildingLevel:SetText("")
	ArmorGem_GildingSplit_AfterGemItemStarLevel:SetText("")
	
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
	end
	g_Jewel_BagIndex = -1
end

function ArmorGem_GildingSplit_OnHidden()
	ArmorGem_GildingSplit_CleanUp()
	m_ObjServerId = -1
end

function ArmorGem_GildingSplit_OKClicked()
	if g_Jewel_BagIndex == -1 then
		PushDebugMessage("#{NJBZ_230703_12}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourPlateReset")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Jewel_BagIndex)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function ArmorGem_GildingSplit_HelpClicked()

end
--Care Obj
function ArmorGem_GildingSplit_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_GildingSplit_Frame_On_ResetPos()
	if g_ArmorGem_GildingSplit_Frame_UnifiedPosition ~= nil then
		ArmorGem_GildingSplit_Frame:SetProperty("UnifiedPosition", g_ArmorGem_GildingSplit_Frame_UnifiedPosition)
	end
end

function ArmorGem_GildingSplit_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end