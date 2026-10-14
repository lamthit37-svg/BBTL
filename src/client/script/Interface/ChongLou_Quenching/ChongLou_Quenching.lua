--ChongLou_Quenching
--!!!reloadscript =ChongLou_Quenching

local g_ChongLou_Quenching_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_UI_Type = 0

local g_EquipBagIndex = -1
local g_LastUpdateEquipBagIndex = -1
local g_MaterialBagIndex = -1
local g_CurSelReplaceIndex = 0

local g_QuenchingMaterial = 20800059

function ChongLou_Quenching_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)	
	this:RegisterEvent("CHONGLOU_QUENCHING_ITEM", false)
end

function ChongLou_Quenching_OnLoad()
	g_ChongLou_Quenching_Frame_UnifiedPosition = ChongLou_Quenching_Frame:GetProperty("UnifiedPosition")
	
	g_BeforeAttrList[1] = ChongLou_Quenching_BeforeEquipAttr1
	g_BeforeAttrList[2] = ChongLou_Quenching_BeforeEquipAttr2
	g_BeforeAttrList[3] = ChongLou_Quenching_BeforeEquipAttr3
	g_BeforeAttrList[4] = ChongLou_Quenching_BeforeEquipAttr4
	g_BeforeAttrList[5] = ChongLou_Quenching_BeforeEquipAttr5
	g_BeforeAttrList[6] = ChongLou_Quenching_BeforeEquipAttr6
	g_BeforeAttrList[7] = ChongLou_Quenching_BeforeEquipAttr7
	g_BeforeAttrList[8] = ChongLou_Quenching_BeforeEquipAttr8
	g_BeforeAttrList[9] = ChongLou_Quenching_BeforeEquipAttr9
	g_BeforeAttrList[10] = ChongLou_Quenching_BeforeEquipAttr10
	
	g_NewAttrList[1] = ChongLou_Quenching_AfterEquipAttr1
	g_NewAttrList[2] = ChongLou_Quenching_AfterEquipAttr2
	g_NewAttrList[3] = ChongLou_Quenching_AfterEquipAttr3
	g_NewAttrList[4] = ChongLou_Quenching_AfterEquipAttr4
	g_NewAttrList[5] = ChongLou_Quenching_AfterEquipAttr5
	g_NewAttrList[6] = ChongLou_Quenching_AfterEquipAttr6
	g_NewAttrList[7] = ChongLou_Quenching_AfterEquipAttr7
	g_NewAttrList[8] = ChongLou_Quenching_AfterEquipAttr8
	g_NewAttrList[9] = ChongLou_Quenching_AfterEquipAttr9
	g_NewAttrList[10] = ChongLou_Quenching_AfterEquipAttr10
	
	g_AnimateList[1] = ChongLou_Quenching_AfterEquipAttr_Amin1
	g_AnimateList[2] = ChongLou_Quenching_AfterEquipAttr_Amin2
	g_AnimateList[3] = ChongLou_Quenching_AfterEquipAttr_Amin3
	g_AnimateList[4] = ChongLou_Quenching_AfterEquipAttr_Amin4
	g_AnimateList[5] = ChongLou_Quenching_AfterEquipAttr_Amin5
	g_AnimateList[6] = ChongLou_Quenching_AfterEquipAttr_Amin6
	g_AnimateList[7] = ChongLou_Quenching_AfterEquipAttr_Amin7
	g_AnimateList[8] = ChongLou_Quenching_AfterEquipAttr_Amin8
	g_AnimateList[9] = ChongLou_Quenching_AfterEquipAttr_Amin9
	g_AnimateList[10] = ChongLou_Quenching_AfterEquipAttr_Amin10
	
	g_ArrowList[1] = ChongLou_Quenching_AfterEquipAttr1_Status
	g_ArrowList[2] = ChongLou_Quenching_AfterEquipAttr2_Status
	g_ArrowList[3] = ChongLou_Quenching_AfterEquipAttr3_Status
	g_ArrowList[4] = ChongLou_Quenching_AfterEquipAttr4_Status
	g_ArrowList[5] = ChongLou_Quenching_AfterEquipAttr5_Status
	g_ArrowList[6] = ChongLou_Quenching_AfterEquipAttr6_Status
	g_ArrowList[7] = ChongLou_Quenching_AfterEquipAttr7_Status
	g_ArrowList[8] = ChongLou_Quenching_AfterEquipAttr8_Status
	g_ArrowList[9] = ChongLou_Quenching_AfterEquipAttr9_Status
	g_ArrowList[10] = ChongLou_Quenching_AfterEquipAttr10_Status
end

function ChongLou_Quenching_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88220010 then
		if not this:IsVisible() then
			ChongLou_Quenching_CleanUp()
			this:Show()
			OpenWindow("Packet")
			g_UI_Type = 0
			ChongLou_Quenching_Update()
			ChongLou_Quenching_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ChongLou_Quenching_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "CHONGLOU_QUENCHING_ITEM" then
		local bagidx = tonumber(arg0)
		local op_type = tonumber(arg1)	--1 左键拖 2 右键点
		local abt_type = tonumber(arg2)	--1 装备框 2 材料框
		
		if op_type == 1 then
			if abt_type == 1 then
				ChongLou_Quenching_OnEquipDragedDropFromBag(bagidx)
			elseif abt_type == 2 then
				ChongLou_Quenching_OnMaterialDragedDropFromBag(bagidx)
			end
		elseif op_type == 2 then
			ChongLou_Quenching_OnBagItemRClicked(bagidx)
		end
		return
	end

	if event == "PACKAGE_ITEM_CHANGED_EX" then
		ChongLou_Quenching_Update()
		return
	end
end

function ChongLou_Quenching_Check()
	if g_UI_Type == 0 then
		if g_EquipBagIndex ~= -1 then
			local need_remove = 0
			
			--加锁
			if PlayerPackage:IsLock(g_EquipBagIndex) == 1 then
				need_remove = 1
			end
			
			local is_chonglou = PlayerPackage:LuaFnIsChongLouEquip(g_EquipBagIndex)
			local ep = PlayerPackage:Lua_GetBagItemEquipPoint(g_EquipBagIndex)
			
			if is_chonglou ~= 1 then
				need_remove = 1
			end
			
			--6.戒指 7.项链 12.护符 14.护腕
			if ep ~= 6 and ep ~= 7 and ep ~= 12 and ep ~= 14 then
				need_remove = 1
			end
			
			local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
			if quench_times >= 10 then
				need_remove = 1
			end

			if need_remove == 1 then
				LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
				g_EquipBagIndex = -1
			end
		end
		
		if g_MaterialBagIndex ~= -1 then
			local need_remove = 0
			if g_EquipBagIndex == -1 then
			--	need_remove = 1
			end
			
			--加锁
			if PlayerPackage:IsLock(g_MaterialBagIndex) == 1 then
				need_remove = 1
			end
			
			if need_remove == 1 then
				LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 0)
				g_MaterialBagIndex = -1
			end
		end
		return
	end
	
	if g_UI_Type == 1 then
		if g_EquipBagIndex ~= -1 then
			local need_remove = 0
			
			--加锁
			if PlayerPackage:IsLock(g_EquipBagIndex) == 1 then
				need_remove = 1
			end
			
			local is_chonglou = PlayerPackage:LuaFnIsChongLouEquip(g_EquipBagIndex)
			local ep = PlayerPackage:Lua_GetBagItemEquipPoint(g_EquipBagIndex)
			
			if is_chonglou ~= 1 then
				need_remove = 1
			end
			
			--6.戒指 7.项链 12.护符
			if ep ~= 6 and ep ~= 7 and ep ~= 12 then
				need_remove = 1
			end
			
			local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
			if quench_times <= 0 then
				need_remove = 1
			end
			
			if need_remove == 1 then
				LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
				g_EquipBagIndex = -1
			end
		end
	end
end

function ChongLou_Quenching_Update()
	
	local strTemp = ""
	
	ChongLou_Quenching_Check()
	
	if g_UI_Type == 0 then
		ChongLou_Quenching_Page1:SetCheck(1)
		ChongLou_Quenching_Page2:SetCheck(0)
		ChongLou_Quenching_PageFrame1:Show()
		ChongLou_Quenching_PageFrame2:Hide()
	else
		ChongLou_Quenching_Page1:SetCheck(0)
		ChongLou_Quenching_Page2:SetCheck(1)
		ChongLou_Quenching_PageFrame1:Hide()
		ChongLou_Quenching_PageFrame2:Show()
	end
	
	ChongLou_Quenching_PageFrame1_BeforeEquipItem:SetActionItem(-1)
	ChongLou_Quenching_PageFrame1_AfterEquipItem:SetActionItem(-1)
	ChongLou_Quenching_PageFrame1_Item:SetActionItem(-1)
	ChongLou_Quenching_PageFrame2_Item1:SetActionItem(-1)
	ChongLou_Quenching_PageFrame2_Item2:SetActionItem(-1)
	
	if g_UI_Type == 0 then
		if g_EquipBagIndex ~= -1 then
			local theEquipAction = EnumAction(g_EquipBagIndex, "packageitem")
			ChongLou_Quenching_PageFrame1_BeforeEquipItem:SetActionItem(theEquipAction:GetID())
			LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 1)
			
			local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
			if quench_times == 0 then
				ChongLou_Quenching_PageFrame1_ComboList:Show()
				
				if g_EquipBagIndex ~= g_LastUpdateEquipBagIndex then
					ChongLou_Quenching_PageFrame1_ComboList:ResetList()
					ChongLou_Quenching_PageFrame1_ComboList:SetText("#{CLFJ_251104_11}")
					ChongLou_Quenching_PageFrame1_ComboList:AddTextItem("#{equip_attr_attack_cold}", 6)
					ChongLou_Quenching_PageFrame1_ComboList:AddTextItem("#{equip_attr_attack_fire}", 9)
					ChongLou_Quenching_PageFrame1_ComboList:AddTextItem("#{equip_attr_attack_light}", 12)
					ChongLou_Quenching_PageFrame1_ComboList:AddTextItem("#{equip_attr_attack_poison}", 15)
				end
				g_LastUpdateEquipBagIndex = g_EquipBagIndex
				
				local _, attr_sel = ChongLou_Quenching_PageFrame1_ComboList:GetCurrentSelect()
				if attr_sel > 0 then
					local theResultAction = DataPool:LuaFnCreateEquipQuenchingResultActionItem(g_EquipBagIndex, attr_sel)
					ChongLou_Quenching_PageFrame1_AfterEquipItem:SetActionItem(theResultAction:GetID())
				end
			else
				g_LastUpdateEquipBagIndex = -1
				ChongLou_Quenching_PageFrame1_ComboList:ResetList()
				ChongLou_Quenching_PageFrame1_ComboList:Hide()
				
				local theResultAction = DataPool:LuaFnCreateEquipQuenchingResultActionItem(g_EquipBagIndex, -1)
				ChongLou_Quenching_PageFrame1_AfterEquipItem:SetActionItem(theResultAction:GetID())
			end
		else
			g_LastUpdateEquipBagIndex = -1
			ChongLou_Quenching_PageFrame1_ComboList:ResetList()
			ChongLou_Quenching_PageFrame1_ComboList:Hide()
		end
		
		if g_MaterialBagIndex ~= -1 then
			local theMaterilaAction = EnumAction(g_MaterialBagIndex, "packageitem")
			ChongLou_Quenching_PageFrame1_Item:SetActionItem(theMaterilaAction:GetID())
			LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 1)
		end
	end
	
	if g_UI_Type == 1 then
		if g_EquipBagIndex ~= -1 then
			local theEquipAction = EnumAction(g_EquipBagIndex, "packageitem")
			ChongLou_Quenching_PageFrame2_Item1:SetActionItem(theEquipAction:GetID())
			LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 1)
			
			local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
			if quench_times > 0 then
				local theSplitAction = DataPool:CreateBindActionItemForShow(g_QuenchingMaterial, 1*quench_times)
				ChongLou_Quenching_PageFrame2_Item2:SetActionItem(theSplitAction:GetID())
			end
		end
	end
end

--从背包拖拽到淬火装备框
function ChongLou_Quenching_OnEquipDragedDropFromBag(iBagIndex)
	
	if g_UI_Type == 1 then
		ChongLou_Quenching_OnRemoveDragedDropFromBag(iBagIndex)
		return
	end
	
	if iBagIndex == nil then
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{CLFJ_251104_16}")
		return
	end
	
	local is_chonglou = PlayerPackage:LuaFnIsChongLouEquip(iBagIndex)
	local ep = PlayerPackage:Lua_GetBagItemEquipPoint(iBagIndex)
		
	if is_chonglou ~= 1 then
		PushDebugMessage("#{CLFJ_251104_17}")
		return
	end
		
	--6.戒指 7.项链 12.护符
	if ep ~= 6 and ep ~= 7 and ep ~= 12 then
		PushDebugMessage("#{CLFJ_251104_17}")
		return
	end
	
	local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(iBagIndex)
	if quench_times >= 10 then
		PushDebugMessage("#{CLFJ_251104_18}")
		return
	end
	
	--释放原来的道具
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
	end
	g_EquipBagIndex = iBagIndex

	ChongLou_Quenching_Update()
end

function ChongLou_Quenching_OnBagItemRClicked(iBagIndex)
	if g_UI_Type == 0 then
		local is_chonglou = PlayerPackage:LuaFnIsChongLouEquip(iBagIndex)
		local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
		local is_material = ChongLou_Quenching_IsUpstageMaterial(item_table_index)
		
		if is_chonglou == 1 then
			ChongLou_Quenching_OnEquipDragedDropFromBag(iBagIndex)
		elseif is_material == 1 then
			ChongLou_Quenching_OnMaterialDragedDropFromBag(iBagIndex)
		elseif g_EquipBagIndex == -1 then
			ChongLou_Quenching_OnEquipDragedDropFromBag(iBagIndex)
		else
			ChongLou_Quenching_OnMaterialDragedDropFromBag(iBagIndex)
		end
		return
	end
	
	if g_UI_Type == 1 then
		ChongLou_Quenching_OnRemoveDragedDropFromBag(iBagIndex)
	end
end

function ChongLou_Quenching_UpstageEquip_OnRBClicked()
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
		ChongLou_Quenching_Update()
	end
end

function ChongLou_Quenching_OnItemDragedDropAway()

end

--从背包拖拽到淬火材料框
function ChongLou_Quenching_OnMaterialDragedDropFromBag(iBagIndex)

	if iBagIndex == nil then
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{CLFJ_251104_16}")
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
	if ChongLou_Quenching_IsUpstageMaterial(item_table_index) ~= 1 then
		PushDebugMessage("#{CLFJ_251104_19}")
		return
	end

	--释放原来的道具
	if g_MaterialBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 0)
	end
	g_MaterialBagIndex = iBagIndex

	ChongLou_Quenching_Update()
end

function ChongLou_Quenching_UpstageMaterial_OnRBClicked()
	if g_MaterialBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 0)
		g_MaterialBagIndex = -1
		ChongLou_Quenching_Update()
	end
end

function ChongLou_Quenching_OnRemoveDragedDropFromBag(iBagIndex)
	
	if iBagIndex == nil then
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{CLFJ_251104_16}")
		return
	end
	
	local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(iBagIndex)
	if quench_times <= 0 then
		PushDebugMessage("#{CLFJ_251104_25}")
		return
	end
	
	--释放原来的道具
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
	end
	g_EquipBagIndex = iBagIndex

	ChongLou_Quenching_Update()
end

function ChongLou_Quenching_RemoveQuenchingEquip_OnRBClicked()
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
		ChongLou_Quenching_Update()
	end
end

function ChongLou_Quenching_CloseClicked()
	this:Hide()
end

function ChongLou_Quenching_CleanUp()
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
	end
	
	if g_MaterialBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 0)
		g_MaterialBagIndex = -1
	end
	
	ChongLou_Quenching_PageFrame1_BeforeEquipItem:SetActionItem(-1)
	ChongLou_Quenching_PageFrame1_AfterEquipItem:SetActionItem(-1)
	ChongLou_Quenching_PageFrame1_Item:SetActionItem(-1)
	ChongLou_Quenching_PageFrame2_Item1:SetActionItem(-1)
	ChongLou_Quenching_PageFrame2_Item2:SetActionItem(-1)

end

function ChongLou_Quenching_OnHidden()
	ChongLou_Quenching_CleanUp()
	m_ObjServerId = -1
end

function ChongLou_Quenching_OKClicked()
	if g_UI_Type == 0 then
		
		if g_EquipBagIndex == -1 then
			PushDebugMessage("#{CLFJ_251104_21}")
			return
		end
		
		if g_MaterialBagIndex == -1 then
			PushDebugMessage("#{CLFJ_251104_22}")
			return
		end
		
		local attr_add = -1
		local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
		if quench_times <= 0 then
			local _, attr_sel = ChongLou_Quenching_PageFrame1_ComboList:GetCurrentSelect()
			if attr_sel ~= 6 and attr_sel ~= 9 and attr_sel ~= 12 and attr_sel ~= 15 then
				PushDebugMessage("#{CLFJ_251104_23}")
				return
			end
			attr_add = attr_sel
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(882200)
			Set_XSCRIPT_Function_Name("Quench")
			Set_XSCRIPT_Parameter(0, m_ObjServerId)
			Set_XSCRIPT_Parameter(1, g_EquipBagIndex)
			Set_XSCRIPT_Parameter(2, g_MaterialBagIndex)
			Set_XSCRIPT_Parameter(3, attr_add)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
		return
	end
	
	if g_UI_Type == 1 then
		if g_EquipBagIndex == -1 then
			PushDebugMessage("#{CLFJ_251104_25}")
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(882200)
			Set_XSCRIPT_Function_Name("RemoveQuenching")
			Set_XSCRIPT_Parameter(0, m_ObjServerId)
			Set_XSCRIPT_Parameter(1, g_EquipBagIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		
		return
	end
end

function ChongLou_Quenching_Attr_ListChanged()
	ChongLou_Quenching_Update()
end

function ChongLou_Quenching_PageClicked(idx)
	if idx == 1 and g_UI_Type == 1 then
		g_UI_Type = 0
		ChongLou_Quenching_CleanUp()
		ChongLou_Quenching_Update()
	elseif idx == 2 and g_UI_Type == 0 then
		g_UI_Type = 1
		ChongLou_Quenching_CleanUp()
		ChongLou_Quenching_Update()
	end
end


function ChongLou_Quenching_HelpClicked()

end
--Care Obj
function ChongLou_Quenching_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ChongLou_Quenching_Frame_On_ResetPos()
	if g_ChongLou_Quenching_Frame_UnifiedPosition ~= nil then
		ChongLou_Quenching_Frame:SetProperty("UnifiedPosition", g_ChongLou_Quenching_Frame_UnifiedPosition)
	end
end

function ChongLou_Quenching_IsUpstageMaterial(item_index)
	if item_index == g_QuenchingMaterial then
		return 1
	end
	return 0
end

function ChongLou_Quenching_GetUpstageMaterialBD(item_index)
	for i = 1, table.getn(g_MaterialList) do
		if g_MaterialList[i].item == item_index then
			return g_MaterialList[i].bd_val
		end	
	end
	return 0
end

function ChongLou_Quenching_GetUpstageMaterialMin(item_index)
	for i = 1, table.getn(g_MaterialList) do
		if g_MaterialList[i].item == item_index then
			return g_MaterialList[i].min_val
		end	
	end
	return 0
end 

function ChongLou_Quenching_GetBaoDiCount(ep, val)
	local ct = 0
	local next_point = 0
	if ep == 6 or ep == 12 then
		for i = 1, table.getn(g_BaoDiPointEx) do
			if g_BaoDiPointEx[i] > val then
				next_point = g_BaoDiPointEx[i]
				break
			else
				ct = i
			end
		end
	else
		for i = 1, table.getn(g_BaoDiPoint) do
			if g_BaoDiPoint[i] > val then
				next_point = g_BaoDiPoint[i]
				break
			else
				ct = i
			end
		end
	end
	
	return ct, next_point	
end

function ChongLou_Quenching_SelectChanged()

end

function ChongLou_Quenching_IsQuenchingMaterial(iBagIndex)
	
end