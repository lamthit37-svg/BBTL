--ArmorGem_Downstage
--!!!reloadscript =ArmorGem_Downstage

local g_ArmorGem_Downstage_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Jewel_BagIndex = -1
local g_ret_item_text = {}
function ArmorGem_Downstage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	
	this:RegisterEvent("JEWEL_RANK_RESET_PUTIN", false)
	this:RegisterEvent("JEWEL_RANK_RESET_RCLICK", false)
	this:RegisterEvent("JEWEL_RANK_RESET_REMOVE", false)
end

function ArmorGem_Downstage_OnLoad()
	g_ArmorGem_Downstage_Frame_UnifiedPosition = ArmorGem_Downstage_Frame:GetProperty("UnifiedPosition")	
	
	g_ret_item_text[1] = ArmorGem_Downstage_AfterMaterial2
	g_ret_item_text[2] = ArmorGem_Downstage_AfterMaterial3
	g_ret_item_text[3] = ArmorGem_Downstage_AfterMaterial4
	g_ret_item_text[4] = ArmorGem_Downstage_AfterMaterial5
end

function ArmorGem_Downstage_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500116 then
		if not this:IsVisible() then
			ArmorGem_Downstage_CleanUp()
			this:Show()
			ArmorGem_Downstage_Update()
			ArmorGem_Downstage_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end	
	
	if event == "UI_COMMAND" and tonumber(arg0) == 55500117 then
		ArmorGem_Downstage_CleanUp()
		ArmorGem_Downstage_Update()
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_Downstage_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_Downstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_Downstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end

	if event == "JEWEL_RANK_RESET_PUTIN" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Downstage_OnItemDragedDropFromBag(tonumber(arg0))
		end
		return
	end
	
	if event == "JEWEL_RANK_RESET_RCLICK" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Downstage_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "JEWEL_RANK_RESET_REMOVE" then
		ArmorGem_Downstage_OnItemDragedDropAway()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		ArmorGem_Downstage_Update()
		return
	end
	
end

function ArmorGem_Downstage_Update()
	local strTemp = ""

	ArmorGem_Downstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_Downstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		
	ArmorGem_Downstage_BeforeGemItemName:SetText("")
	ArmorGem_Downstage_BeforeGemItem:SetActionItem(-1)

	ArmorGem_Downstage_AfterMaterial1:SetText("")
	for i = 1, 4 do
		g_ret_item_text[i]:SetText("")
	end

	if g_Jewel_BagIndex ~= -1 then	
		local jewel_data = PlayerPackage:Lua_GetItemAttachParam(g_Jewel_BagIndex, 4, 2)		
		if tonumber(jewel_data) ~= nil then
			local jewel_level = math.floor(jewel_data / 1000)
			if jewel_level > 0 then
				LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 1)
				local theAction = EnumAction(g_Jewel_BagIndex, "packageitem")
				ArmorGem_Downstage_BeforeGemItem:SetActionItem(theAction:GetID())

				local jewel_id = PlayerPackage:GetItemTableIndex(g_Jewel_BagIndex)
				local jewel_plate = math.floor(math.mod(jewel_data, 1000) / 10)
				local jewel_name = DataPool:LuaFnGetUnderArmourJewelName(jewel_id, jewel_plate)
				ArmorGem_Downstage_BeforeGemItemName:SetText(tostring(jewel_name))				
				
				local isBind = GetItemBindStatus(g_Jewel_BagIndex)

				local chip_count = 0
				local chip_item_id = -1
				for i = 0, jewel_level - 1 do
					local need_item, need_item_count, need_item_1, need_item_count_1, _, _ = DataPool:LuaFnGetUnderArmourJewelLevelUpInfo(jewel_id, i)
					if chip_item_id == -1 then
						chip_item_id = need_item_1
					end
					chip_count = chip_count + need_item_count_1
					local item_name = DataPool:Lua_GetItemNameByIndex(need_item)
					strTemp = ScriptGlobal_Format("#{NJBZ_220816_319}", tostring(item_name), tostring(need_item_count))
					g_ret_item_text[i + 1]:SetText(strTemp)
				end

				if chip_item_id > 0 then
					local item_name = DataPool:Lua_GetItemNameByIndex(chip_item_id)
					strTemp = ScriptGlobal_Format("#{NJBZ_220816_319}", tostring(item_name), tostring(chip_count))
					ArmorGem_Downstage_AfterMaterial1:SetText(strTemp)
				end

				ArmorGem_Downstage_Currency1Num:SetProperty("MoneyNumber", "2000000")
			end
		end
	end

end

--从背包拖拽到UI
function ArmorGem_Downstage_OnItemDragedDropFromBag(iBagIndex)
	
	if PlayerPackage:LuaFnIsUnderArmourJewel(iBagIndex) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_265}")
		return
	end

	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{NJBZ_220816_252}")
		return
	end
	
	local jewel_data = PlayerPackage:Lua_GetItemAttachParam(iBagIndex, 4, 2)
	if tonumber(jewel_data) ~= nil then
		local jewel_level = math.floor(jewel_data / 1000)
		if jewel_level == 0 then
			PushDebugMessage("#{NJBZ_220816_320}")
			return
		end
	end	
	
	if g_Jewel_BagIndex >= 0 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
	end
	g_Jewel_BagIndex = iBagIndex	

	ArmorGem_Downstage_Update()

end

function ArmorGem_Downstage_OnBagItemRClicked(iBagIndex)
	ArmorGem_Downstage_OnItemDragedDropFromBag(iBagIndex)
end

function ArmorGem_Downstage_JewelItem_OnRBClicked()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_Downstage_Update()
	end
end

function ArmorGem_Downstage_OnItemDragedDropAway()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_Downstage_Update()
	end
end

function ArmorGem_Downstage_CloseClicked()
	this:Hide()
end

function ArmorGem_Downstage_CleanUp()

	ArmorGem_Downstage_Currency1Num:SetProperty("MoneyNumber", "0")
	ArmorGem_Downstage_Currency2Num:SetProperty("MoneyNumber", "0")
	ArmorGem_Downstage_Currency3Num:SetProperty("MoneyNumber", "0")
	
	ArmorGem_Downstage_BeforeGemItem:SetActionItem(-1)
	ArmorGem_Downstage_BeforeGemItemName:SetText("")

	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
	end
	g_Jewel_BagIndex = -1
	
	ArmorGem_Downstage_AfterMaterial1:SetText("")
	for i = 1, 4 do
		g_ret_item_text[i]:SetText("")
	end

end

function ArmorGem_Downstage_OnHidden()
	ArmorGem_Downstage_CleanUp()
	m_ObjServerId = -1
end

function ArmorGem_Downstage_OKClicked()
	if g_Jewel_BagIndex == -1 then
		PushDebugMessage("#{NJBZ_220816_267}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourJewelRankReset")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Jewel_BagIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function ArmorGem_Downstage_HelpClicked()

end
--Care Obj
function ArmorGem_Downstage_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_Downstage_Frame_On_ResetPos()
	if g_ArmorGem_Downstage_Frame_UnifiedPosition ~= nil then
		ArmorGem_Downstage_Frame:SetProperty("UnifiedPosition", g_ArmorGem_Downstage_Frame_UnifiedPosition)
	end
end

function ArmorGem_Downstage_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end