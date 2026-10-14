--EquipEducation_Upstage
--!!!reloadscript =EquipEducation_Upstage

local g_EquipEducation_Upstage_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_UI_Type = 0

local g_EquipBagIndex = -1
local g_LastUpdateEquipBagIndex = -1
local g_MaterialBagIndex = -1
local g_CurSelReplaceIndex = 0

local g_MaterialList = {
	{item = 20800055, bd_val = 5, min_val = 1},
	{item = 20800056, bd_val = 10, min_val = 1},
	{item = 20800057, bd_val = 15, min_val = 1},
	{item = 20800058, bd_val = 20, min_val = 5},
}

local g_BeforeAttrList = {}
local g_NewAttrList = {}
local g_AnimateList = {}
local g_ArrowList = {}

local g_bPlayAnimate = 0

local g_UpstageAddLevel = 30

local g_BaoDiPoint = {600, 1200, 2100, 3000, 3900, 4800, 6000, 7500, 9000, 12000}
local g_BaoDiPointEx = {900, 1800, 3150, 4500, 5850, 7200, 9000, 11250, 13500, 18000}

local g_NeedQual = 6

function EquipEducation_Upstage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
	
	this:RegisterEvent("EUS_UPSTAGE_ITEM", false)
	this:RegisterEvent("EUG_REPLACE_ITEM", false)
	this:RegisterEvent("UA_JEWEL_EMBED_REMOVE", false)
	this:RegisterEvent("EUS_SHOW_RESULT", false)
	this:RegisterEvent("EUS_POINT", false)
	this:RegisterEvent("EUS_UPSTAGE_ESCAPE", false)
end

function EquipEducation_Upstage_OnLoad()
	g_EquipEducation_Upstage_Frame_UnifiedPosition = EquipEducation_Upstage_Frame:GetProperty("UnifiedPosition")
	
	g_BeforeAttrList[1] = EquipEducation_Upstage_BeforeEquipAttr1
	g_BeforeAttrList[2] = EquipEducation_Upstage_BeforeEquipAttr2
	g_BeforeAttrList[3] = EquipEducation_Upstage_BeforeEquipAttr3
	g_BeforeAttrList[4] = EquipEducation_Upstage_BeforeEquipAttr4
	g_BeforeAttrList[5] = EquipEducation_Upstage_BeforeEquipAttr5
	g_BeforeAttrList[6] = EquipEducation_Upstage_BeforeEquipAttr6
	g_BeforeAttrList[7] = EquipEducation_Upstage_BeforeEquipAttr7
	g_BeforeAttrList[8] = EquipEducation_Upstage_BeforeEquipAttr8
	g_BeforeAttrList[9] = EquipEducation_Upstage_BeforeEquipAttr9
	g_BeforeAttrList[10] = EquipEducation_Upstage_BeforeEquipAttr10
	
	g_NewAttrList[1] = EquipEducation_Upstage_AfterEquipAttr1
	g_NewAttrList[2] = EquipEducation_Upstage_AfterEquipAttr2
	g_NewAttrList[3] = EquipEducation_Upstage_AfterEquipAttr3
	g_NewAttrList[4] = EquipEducation_Upstage_AfterEquipAttr4
	g_NewAttrList[5] = EquipEducation_Upstage_AfterEquipAttr5
	g_NewAttrList[6] = EquipEducation_Upstage_AfterEquipAttr6
	g_NewAttrList[7] = EquipEducation_Upstage_AfterEquipAttr7
	g_NewAttrList[8] = EquipEducation_Upstage_AfterEquipAttr8
	g_NewAttrList[9] = EquipEducation_Upstage_AfterEquipAttr9
	g_NewAttrList[10] = EquipEducation_Upstage_AfterEquipAttr10
	
	g_AnimateList[1] = EquipEducation_Upstage_AfterEquipAttr_Amin1
	g_AnimateList[2] = EquipEducation_Upstage_AfterEquipAttr_Amin2
	g_AnimateList[3] = EquipEducation_Upstage_AfterEquipAttr_Amin3
	g_AnimateList[4] = EquipEducation_Upstage_AfterEquipAttr_Amin4
	g_AnimateList[5] = EquipEducation_Upstage_AfterEquipAttr_Amin5
	g_AnimateList[6] = EquipEducation_Upstage_AfterEquipAttr_Amin6
	g_AnimateList[7] = EquipEducation_Upstage_AfterEquipAttr_Amin7
	g_AnimateList[8] = EquipEducation_Upstage_AfterEquipAttr_Amin8
	g_AnimateList[9] = EquipEducation_Upstage_AfterEquipAttr_Amin9
	g_AnimateList[10] = EquipEducation_Upstage_AfterEquipAttr_Amin10
	
	g_ArrowList[1] = EquipEducation_Upstage_AfterEquipAttr1_Status
	g_ArrowList[2] = EquipEducation_Upstage_AfterEquipAttr2_Status
	g_ArrowList[3] = EquipEducation_Upstage_AfterEquipAttr3_Status
	g_ArrowList[4] = EquipEducation_Upstage_AfterEquipAttr4_Status
	g_ArrowList[5] = EquipEducation_Upstage_AfterEquipAttr5_Status
	g_ArrowList[6] = EquipEducation_Upstage_AfterEquipAttr6_Status
	g_ArrowList[7] = EquipEducation_Upstage_AfterEquipAttr7_Status
	g_ArrowList[8] = EquipEducation_Upstage_AfterEquipAttr8_Status
	g_ArrowList[9] = EquipEducation_Upstage_AfterEquipAttr9_Status
	g_ArrowList[10] = EquipEducation_Upstage_AfterEquipAttr10_Status
end

function EquipEducation_Upstage_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88220000 then
		if not this:IsVisible() then
			EquipEducation_Upstage_CleanUp()
			this:Show()
			OpenWindow("Packet")
			EquipEducation_Upstage_Update()
			EquipEducation_Upstage_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		EquipEducation_Upstage_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	--	EquipEducation_Upstage_Enchase_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	--	EquipEducation_Upstage_Enchase_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		
	--	EquipEducation_Upstage_Split_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	--	EquipEducation_Upstage_Split_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end

	if event == "EUS_UPSTAGE_ITEM" then
		local bagidx = tonumber(arg0)
		local op_type = tonumber(arg1)	--1 左键拖 2 右键点
		local abt_type = tonumber(arg2)	--1 装备框 2 材料框
		
		if op_type == 1 then
			if abt_type == 1 then
				EquipEducation_Upstage_OnEquipDragedDropFromBag(bagidx)
			elseif abt_type == 2 then
				EquipEducation_Upstage_OnMaterialDragedDropFromBag(bagidx)
			end
		elseif op_type == 2 then
			EquipEducation_Upstage_OnBagItemRClicked(bagidx)
		end
		return
	end

	if event == "UA_JEWEL_EMBED_REMOVE" then
		EquipEducation_Upstage_OnItemDragedDropAway()
		return
	end
	
	if event == "EUS_SHOW_RESULT" then
		g_bPlayAnimate = 1
		EquipEducation_Upstage_Update()
		return
	end
	
	if event == "EUS_UPSTAGE_ESCAPE" then
		EquipEducation_Upstage_CloseClicked()
		return
	end
	
	if event == "EUS_POINT" then
		EquipEducation_Upstage_Update()
		return
	end
end

function EquipEducation_Upstage_Check()
	if g_UI_Type == 0 then
		if g_EquipBagIndex ~= -1 then
			local need_remove = 0
			
			--武器不可以
			if PlayerPackage:Lua_IsBagItemWeapon(g_EquipBagIndex) == 1 then
				need_remove = 1
			end
			
			local can_upstage = 0
			local is_chonglou = PlayerPackage:LuaFnIsChongLouEquip(g_EquipBagIndex)
			local is_shougong = PlayerPackage:LuaFnIsHandMakeEquip(g_EquipBagIndex)
			local req_level = PlayerPackage:Lua_GetBagEquipNeedLevel(g_EquipBagIndex)
			local equip_qual = PlayerPackage:LuaFnGetBagEquipQual(g_EquipBagIndex)
			if is_chonglou == 1 then
				can_upstage = 1
			elseif is_shougong == 1 and req_level >= 90 and equip_qual >= g_NeedQual then
				can_upstage = 1
				if PlayerPackage:Lua_IsBagItemNeedIdentify(g_EquipBagIndex) == 1 then
					need_remove = 1
				end
			end
			
			if can_upstage ~= 1 then
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
				need_remove = 1
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
		
	elseif g_UI_Type == 1 then
	
	end
end

function EquipEducation_Upstage_Update()
	
	local strTemp = ""
	
	EquipEducation_Upstage_Check()
	
	EquipEducation_Upstage_BeforeEquipItem:SetActionItem(-1)
	EquipEducation_Upstage_AfterEquipItem:SetActionItem(-1)
	EquipEducation_Upstage_MaterialItem:SetActionItem(-1)
	
	for i = 1, 10 do
		g_BeforeAttrList[i]:Hide()
		g_BeforeAttrList[i]:SetText("")
		g_NewAttrList[i]:Hide()
		g_NewAttrList[i]:SetText("")
		g_ArrowList[i]:Hide()
	end
	
	strTemp = ScriptGlobal_Format("#{SZJJ_250801_126}", "0")
	EquipEducation_Upstage_Info2:SetText(strTemp)
	
	strTemp = ScriptGlobal_Format("#{SZJJ_250801_130}", "0")
	EquipEducation_Upstage_Info3:SetText(strTemp)
	EquipEducation_Upstage_Info3:SetToolTip("")
	EquipEducation_Upstage_Info4_Text:Hide()
	EquipEducation_Upstage_Info5:Hide()
	
	if g_EquipBagIndex ~= -1 then
		local theEquipAction = EnumAction(g_EquipBagIndex, "packageitem")
		EquipEducation_Upstage_BeforeEquipItem:SetActionItem(theEquipAction:GetID())
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 1)
		
		local attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(g_EquipBagIndex)
		if attr_count > 0 and attr_count < 10 then
			for i = 1, attr_count do
				local attr_type, attr_value = PlayerPackage:LuaFnGetBagEquipExtAttr(g_EquipBagIndex, i - 1)
				g_BeforeAttrList[i]:Show()
				local upstage_rate = PlayerPackage:LuaFnGetBagEquipUpstageRate(g_EquipBagIndex, i - 1)
				local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, upstage_rate)
				g_BeforeAttrList[i]:SetText(tostring(attr_txt))
			end
			
			local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
			if quench_times > 0 then
				local attr_type, attr_value = PlayerPackage:LuaFnGetEquipQuenchingAttr(g_EquipBagIndex)
				g_BeforeAttrList[attr_count + 1]:Show()
				local upstage_rate = PlayerPackage:LuaFnGetBagEquipUpstageRate(g_EquipBagIndex, attr_count)
				local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, upstage_rate)
				g_BeforeAttrList[attr_count + 1]:SetText(tostring(attr_txt))
			end

			if PlayerPackage:LuaFnIsHaveBagEquipUpstageResult(g_EquipBagIndex) == 1 then
				local theResultAction = DataPool:LuaFnCreateEquipStageResultActionItem(g_EquipBagIndex)
				EquipEducation_Upstage_AfterEquipItem:SetActionItem(theResultAction:GetID())

				for i = 1, attr_count do
					local attr_type, attr_value = PlayerPackage:LuaFnGetBagEquipExtAttr(g_EquipBagIndex, i - 1)
					g_NewAttrList[i]:Show()
					local upstage_rate = PlayerPackage:LuaFnGetBagEquipUpstageRate(g_EquipBagIndex, i - 1)
					local new_rate = PlayerPackage:LuaFnGetBagEquipUpstageNewRate(g_EquipBagIndex, i - 1)
					local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, new_rate)
					g_NewAttrList[i]:SetText(tostring(attr_txt))
					if new_rate > upstage_rate then
						g_ArrowList[i]:Show()
						g_ArrowList[i]:SetText("#{SZJJ_250801_137}")
					elseif new_rate < upstage_rate then
						g_ArrowList[i]:Show()
						g_ArrowList[i]:SetText("#{SZJJ_250801_138}")
					end
				end
				
				if quench_times > 0 then
					local attr_type, attr_value = PlayerPackage:LuaFnGetEquipQuenchingAttr(g_EquipBagIndex)
					g_NewAttrList[attr_count + 1]:Show()
					local upstage_rate = PlayerPackage:LuaFnGetBagEquipUpstageRate(g_EquipBagIndex, attr_count)
					local new_rate = PlayerPackage:LuaFnGetBagEquipUpstageNewRate(g_EquipBagIndex, attr_count)
					local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, new_rate)
					g_NewAttrList[attr_count + 1]:SetText(tostring(attr_txt))
					
					if new_rate > upstage_rate then
						g_ArrowList[attr_count + 1]:Show()
						g_ArrowList[attr_count + 1]:SetText("#{SZJJ_250801_137}")
					elseif new_rate < upstage_rate then
						g_ArrowList[attr_count + 1]:Show()
						g_ArrowList[attr_count + 1]:SetText("#{SZJJ_250801_138}")
					end
				end

				if g_bPlayAnimate == 1 then
					g_bPlayAnimate = 0
					for i = 1, attr_count do
						g_AnimateList[i]:Play(true)
					end
				end
			end
		end

		if g_MaterialBagIndex ~= -1 then
			local theMaterilaAction = EnumAction(g_MaterialBagIndex, "packageitem")
			EquipEducation_Upstage_MaterialItem:SetActionItem(theMaterilaAction:GetID())
			LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 1)
			
			local mat_table_index = PlayerPackage:GetItemTableIndex(g_MaterialBagIndex)
			local val = EquipEducation_Upstage_GetUpstageMaterialBD(mat_table_index)
			if val ~= 0 then
				EquipEducation_Upstage_Info4_Text:Show()
				strTemp = ScriptGlobal_Format("#{SZJJ_250801_136}", tostring(val).."%")
				EquipEducation_Upstage_Info4_Text:SetText(strTemp)
			end
			
			local min_val = EquipEducation_Upstage_GetUpstageMaterialMin(mat_table_index)
			if min_val ~= 0 then
				EquipEducation_Upstage_Info5:Show()
				strTemp = ScriptGlobal_Format("#{SZJJ_250801_140}", tostring(min_val).."%")
				EquipEducation_Upstage_Info5:SetText(strTemp)
			end
		end
		
		local ep = PlayerPackage:Lua_GetBagItemEquipPoint(g_EquipBagIndex)
		local eus_point = Player:LuaFnGetEusPoint(ep)
		local ct, next_point = EquipEducation_Upstage_GetBaoDiCount(ep, eus_point)

		strTemp = ScriptGlobal_Format("#{SZJJ_250801_130}", tostring(ct))
		EquipEducation_Upstage_Info3:SetText(strTemp)
		
		if next_point > eus_point then
			strTemp = ScriptGlobal_Format("#{SZJJ_250801_126}", tostring(eus_point))
			EquipEducation_Upstage_Info2:SetText(strTemp)
		
			strTemp = ScriptGlobal_Format("#{SZJJ_250801_131}", tostring(next_point - eus_point))
			EquipEducation_Upstage_Info3:SetToolTip(strTemp)
		else
			strTemp = ScriptGlobal_Format("#{SZJJ_250801_126}", tostring(eus_point))
			EquipEducation_Upstage_Info2:SetText(strTemp.."#{SZJJ_250801_127}")
			
			EquipEducation_Upstage_Info3:SetToolTip("#{SZJJ_250801_132}")
		end
	end
	
	if g_LastUpdateEquipBagIndex ~= g_EquipBagIndex then
		EquipEducation_Upstage_UpdateComboList()
		g_LastUpdateEquipBagIndex = g_EquipBagIndex
	end	
end

function EquipEducation_Upstage_UpdateComboList()
	local strTemp = ""
	EquipEducation_Upstage_Select:ResetList()
	local Index = 0
	EquipEducation_Upstage_Select:AddTextItem("#{SZJJ_250801_143}", Index)

	if g_EquipBagIndex ~= -1 then
		local attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(g_EquipBagIndex)
		for i = 1, attr_count do
			local attr_type, _ = PlayerPackage:LuaFnGetBagEquipExtAttr(g_EquipBagIndex, i - 1)
			local attr_name = ""
			if tonumber(attr_type) ~= nil then 
				attr_name = PlayerPackage:LuaFnGetEquipAttrName(attr_type)
			end			
			strTemp = ScriptGlobal_Format("#{SZJJ_250801_144}", tostring(attr_name))
			Index = Index + 1
			EquipEducation_Upstage_Select:AddTextItem(strTemp, Index)
		end
		
		if attr_count > 1 then
			Index = Index + 1
			EquipEducation_Upstage_Select:AddTextItem("#{SZJJ_250801_145}", Index)
		end
	end
	EquipEducation_Upstage_Select:SetCurrentSelect(0)
end

--从背包拖拽到进阶装备框
function EquipEducation_Upstage_OnEquipDragedDropFromBag(iBagIndex)
	
	if iBagIndex == nil then
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{SZJJ_250801_112}")
		return
	end
	
	--未鉴定
	if PlayerPackage:Lua_IsBagItemNeedIdentify(iBagIndex) == 1 then
		PushDebugMessage("#{SZJJ_250801_113}")
		return
	end

	--武器不可以
	if PlayerPackage:Lua_IsBagItemWeapon(iBagIndex) == 1 then
		PushDebugMessage("#{SZJJ_250801_26}")
		return
	end
	
	local can_upstage = 0
	local is_chonglou = PlayerPackage:LuaFnIsChongLouEquip(iBagIndex)
	local is_shougong = PlayerPackage:LuaFnIsHandMakeEquip(iBagIndex)
	local req_level = PlayerPackage:Lua_GetBagEquipNeedLevel(iBagIndex)
	local equip_qual = PlayerPackage:LuaFnGetBagEquipQual(iBagIndex)
	if is_chonglou == 1 then
		can_upstage = 1
	elseif is_shougong == 1 and req_level >= 90 and equip_qual >= g_NeedQual then
		can_upstage = 1
	end
	
	if can_upstage ~= 1 then
		PushDebugMessage("#{SZJJ_250801_26}")
		return
	end
	
	if PlayerPackage:LuaFnIsBagEquipUpstaged(iBagIndex) == 0 then
		local player_lv = Player:GetData("LEVEL")
		if req_level + g_UpstageAddLevel > player_lv then
			local strTemp = ScriptGlobal_Format("#{SZJJ_250801_118}", tostring(req_level + g_UpstageAddLevel))
			PushDebugMessage(strTemp)
			return
		end
	end
	
	--释放原来的道具
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
	end
	g_EquipBagIndex = iBagIndex

	EquipEducation_Upstage_Update()
end

function EquipEducation_Upstage_OnBagItemRClicked(iBagIndex)
	if g_EquipBagIndex == -1 then
		EquipEducation_Upstage_OnEquipDragedDropFromBag(iBagIndex)
	else
		EquipEducation_Upstage_OnMaterialDragedDropFromBag(iBagIndex)
	end
end

function EquipEducation_Upstage_UpstageEquip_OnRBClicked()
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
		EquipEducation_Upstage_Update()
	end
end

function EquipEducation_Upstage_OnItemDragedDropAway()

end

--从背包拖拽到进阶材料框
function EquipEducation_Upstage_OnMaterialDragedDropFromBag(iBagIndex)

	if iBagIndex == nil then
		return
	end
	
	if g_EquipBagIndex == -1 then
		PushDebugMessage("#{SZJJ_250801_27}")
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{SZJJ_250801_112}")
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
	if EquipEducation_Upstage_IsUpstageMaterial(item_table_index) ~= 1 then
		PushDebugMessage("#{SZJJ_250801_28}")
		return
	end

	--释放原来的道具
	if g_MaterialBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 0)
	end
	g_MaterialBagIndex = iBagIndex

	EquipEducation_Upstage_Update()
end

function EquipEducation_Upstage_UpstageMaterial_OnRBClicked()
	if g_MaterialBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 0)
		g_MaterialBagIndex = -1
		EquipEducation_Upstage_Update()
	end
end

function EquipEducation_Upstage_CloseClicked()
	if g_EquipBagIndex ~= -1 then
		if PlayerPackage:LuaFnIsHaveBagEquipUpstageResult(g_EquipBagIndex) == 1 then
		--	PushDebugMessage("#{SZJJ_250801_104}")
			LuaFnEquipUpstageAbandonResultConfirm()
			return
		end
	end
	this:Hide()
end

function EquipEducation_Upstage_CleanUp()
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
	end
	
	if g_MaterialBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_MaterialBagIndex, 0)
		g_MaterialBagIndex = -1
	end
	
	EquipEducation_Upstage_BeforeEquipItem:SetActionItem(-1)
	EquipEducation_Upstage_AfterEquipItem:SetActionItem(-1)
	EquipEducation_Upstage_MaterialItem:SetActionItem(-1)
	
	for i = 1, 10 do
		g_AnimateList[i]:Play(false)
	end
end

function EquipEducation_Upstage_OnHidden()
	EquipEducation_Upstage_CleanUp()
	m_ObjServerId = -1
	PlayerPackage:LuaFnCleanEquipUpstageResult()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("AbandonResult")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function EquipEducation_Upstage_OKClicked()
	if g_EquipBagIndex == -1 then
		PushDebugMessage("#{SZJJ_250801_115}")
		return
	end
	
	if g_MaterialBagIndex == -1 then
		PushDebugMessage("#{SZJJ_250801_110}")
		return
	end
	
	local _, Index = EquipEducation_Upstage_Select:GetCurrentSelect()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("EquipUpstage")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_EquipBagIndex)
		Set_XSCRIPT_Parameter(2, g_MaterialBagIndex)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_Parameter(4, Index)
		Set_XSCRIPT_ParamCount(5)
	Send_XSCRIPT()
end

function EquipEducation_Upstage_AttrChangedClicked()
	if g_EquipBagIndex == -1 then
	--	PushDebugMessage("#{SZJJ_250801_26}")
		return
	end
	
	if PlayerPackage:LuaFnIsHaveBagEquipUpstageResult(g_EquipBagIndex) ~= 1 then
		PushDebugMessage("#{SZJJ_250801_105}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("SaveUpstageResult")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_EquipBagIndex)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function EquipEducation_Upstage_HelpClicked()

end
--Care Obj
function EquipEducation_Upstage_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function EquipEducation_Upstage_Frame_On_ResetPos()
	if g_EquipEducation_Upstage_Frame_UnifiedPosition ~= nil then
		EquipEducation_Upstage_Frame:SetProperty("UnifiedPosition", g_EquipEducation_Upstage_Frame_UnifiedPosition)
	end
end

function EquipEducation_Upstage_IsUpstageMaterial(item_index)
	for i = 1, table.getn(g_MaterialList) do
		if g_MaterialList[i].item == item_index then
			return 1
		end	
	end
	return 0
end

function EquipEducation_Upstage_GetUpstageMaterialBD(item_index)
	for i = 1, table.getn(g_MaterialList) do
		if g_MaterialList[i].item == item_index then
			return g_MaterialList[i].bd_val
		end	
	end
	return 0
end

function EquipEducation_Upstage_GetUpstageMaterialMin(item_index)
	for i = 1, table.getn(g_MaterialList) do
		if g_MaterialList[i].item == item_index then
			return g_MaterialList[i].min_val
		end	
	end
	return 0
end 

function EquipEducation_Upstage_GetBaoDiCount(ep, val)
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

function EquipEducation_Upstage_SelectChanged()

end