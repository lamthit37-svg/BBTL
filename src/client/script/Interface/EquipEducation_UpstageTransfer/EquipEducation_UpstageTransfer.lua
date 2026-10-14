--EquipEducation_UpstageTransfer
--!!!reloadscript =EquipEducation_UpstageTransfer

local g_EquipEducation_UpstageTransfer_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_UI_Type = 0

local g_EquipBagIndex = -1
local g_TargetEquipBagIndex = -1

local g_EquipAttrList = {}
local g_TargetAttrList = {}

local g_UpstageAddLevel = 30

function EquipEducation_UpstageTransfer_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("EUS_TRANSFER_ITEM", false)
end

function EquipEducation_UpstageTransfer_OnLoad()
	g_EquipEducation_UpstageTransfer_Frame_UnifiedPosition = EquipEducation_UpstageTransfer_Frame:GetProperty("UnifiedPosition")
	
	g_EquipAttrList[1] = EquipEducation_UpstageTransfer_BeforeEquipAttr1
	g_EquipAttrList[2] = EquipEducation_UpstageTransfer_BeforeEquipAttr2
	g_EquipAttrList[3] = EquipEducation_UpstageTransfer_BeforeEquipAttr3
	g_EquipAttrList[4] = EquipEducation_UpstageTransfer_BeforeEquipAttr4
	g_EquipAttrList[5] = EquipEducation_UpstageTransfer_BeforeEquipAttr5
	g_EquipAttrList[6] = EquipEducation_UpstageTransfer_BeforeEquipAttr6
	g_EquipAttrList[7] = EquipEducation_UpstageTransfer_BeforeEquipAttr7
	g_EquipAttrList[8] = EquipEducation_UpstageTransfer_BeforeEquipAttr8
	g_EquipAttrList[9] = EquipEducation_UpstageTransfer_BeforeEquipAttr9
	g_EquipAttrList[10] = EquipEducation_UpstageTransfer_BeforeEquipAttr10
	
	g_TargetAttrList[1] = EquipEducation_UpstageTransfer_AfterEquipAttr1
	g_TargetAttrList[2] = EquipEducation_UpstageTransfer_AfterEquipAttr2
	g_TargetAttrList[3] = EquipEducation_UpstageTransfer_AfterEquipAttr3
	g_TargetAttrList[4] = EquipEducation_UpstageTransfer_AfterEquipAttr4
	g_TargetAttrList[5] = EquipEducation_UpstageTransfer_AfterEquipAttr5
	g_TargetAttrList[6] = EquipEducation_UpstageTransfer_AfterEquipAttr6
	g_TargetAttrList[7] = EquipEducation_UpstageTransfer_AfterEquipAttr7
	g_TargetAttrList[8] = EquipEducation_UpstageTransfer_AfterEquipAttr8
	g_TargetAttrList[9] = EquipEducation_UpstageTransfer_AfterEquipAttr9
	g_TargetAttrList[10] = EquipEducation_UpstageTransfer_AfterEquipAttr10
end

function EquipEducation_UpstageTransfer_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88220001 then
		if not this:IsVisible() then
			EquipEducation_UpstageTransfer_CleanUp()
			this:Show()
			OpenWindow("Packet")
			EquipEducation_UpstageTransfer_Update()
			EquipEducation_UpstageTransfer_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		EquipEducation_UpstageTransfer_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		EquipEducation_UpstageTransfer_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		EquipEducation_UpstageTransfer_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		EquipEducation_UpstageTransfer_Update()
		return
	end	
	
	if event == "EUS_TRANSFER_ITEM" then
		local bagidx = tonumber(arg0)
		local op_type = tonumber(arg1)	--1 左键拖 2 右键点
		local abt_type = tonumber(arg2)	--1 源装备框 2 目标装备框
		
		if op_type == 1 then
			if abt_type == 1 then
				EquipEducation_UpstageTransfer_OnEquipDragedDropFromBag(bagidx)
			elseif abt_type == 2 then
				EquipEducation_UpstageTransfer_OnTargetEquipDragedDropFromBag(bagidx)
			end
		elseif op_type == 2 then
			EquipEducation_UpstageTransfer_OnBagItemRClicked(bagidx)
		end
		return
	end
end

function EquipEducation_UpstageTransfer_Check()
	if g_UI_Type == 0 then
		if g_EquipBagIndex ~= -1 then
			local need_remove = 0

			if PlayerPackage:LuaFnIsBagEquipUpstaged(g_EquipBagIndex) == 0 then
				need_remove = 1
			end
			
			if need_remove == 1 then
				LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
				g_EquipBagIndex = -1
			end
		end
		
		if g_TargetEquipBagIndex ~= -1 then
			local need_remove = 0
			if g_EquipBagIndex == -1 then
				need_remove = 1
			else
				if PlayerPackage:Lua_IsBagItemWeapon(g_TargetEquipBagIndex) == 1 then
					need_remove = 1
				else
					local ep = PlayerPackage:Lua_GetBagItemEquipPoint(g_EquipBagIndex)
					local target_ep = PlayerPackage:Lua_GetBagItemEquipPoint(g_TargetEquipBagIndex)
					if ep ~= target_ep then
						need_remove = 1
					else
						local attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(g_EquipBagIndex)
						local target_attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(g_TargetEquipBagIndex)
						local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
						local target_quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_TargetEquipBagIndex)
						local have_quenching = 0
						if quench_times > 0 then
							have_quenching = 1
						end
						local target_have_quenching = 0
						if target_quench_times > 0 then
							target_have_quenching = 1
						end
						if attr_count ~= target_attr_count or have_quenching ~= target_have_quenching then
							need_remove = 1
						else
							if PlayerPackage:LuaFnIsBagEquipUpstaged(g_TargetEquipBagIndex) ~= 0 then
								need_remove = 1
							end
						end
					end
				end
			end
			
			--加锁
			if PlayerPackage:IsLock(g_TargetEquipBagIndex) == 1 then
				need_remove = 1
			end
			
			if need_remove == 1 then
				LifeAbility:Lock_Packet_Item(g_TargetEquipBagIndex, 0)
				g_TargetEquipBagIndex = -1
			end
		end
		
	elseif g_UI_Type == 1 then
	
	end
end

function EquipEducation_UpstageTransfer_Update()
	
	EquipEducation_UpstageTransfer_Currency1Num:SetProperty("MoneyNumber", "100000")
	EquipEducation_UpstageTransfer_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	EquipEducation_UpstageTransfer_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	EquipEducation_UpstageTransfer_Check()
	
	EquipEducation_UpstageTransfer_BeforeEquipItem:SetActionItem(-1)
	EquipEducation_UpstageTransfer_AfterEquipItem:SetActionItem(-1)

	for i = 1, 10 do
		g_EquipAttrList[i]:Hide()
		g_EquipAttrList[i]:SetText("")
		g_TargetAttrList[i]:Hide()
		g_TargetAttrList[i]:SetText("")
	end
	
	if g_EquipBagIndex ~= -1 then
		local theEquipAction = EnumAction(g_EquipBagIndex, "packageitem")
		EquipEducation_UpstageTransfer_BeforeEquipItem:SetActionItem(theEquipAction:GetID())
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 1)
		
		local attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(g_EquipBagIndex)
		if attr_count > 0 and attr_count < 10 then
			for i = 1, attr_count do
				local attr_type, attr_value = PlayerPackage:LuaFnGetBagEquipExtAttr(g_EquipBagIndex, i - 1)
				g_EquipAttrList[i]:Show()
				local upstage_rate = PlayerPackage:LuaFnGetBagEquipUpstageRate(g_EquipBagIndex, i - 1)
				local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, upstage_rate)
				g_EquipAttrList[i]:SetText(tostring(attr_txt))
			end
			
			local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
			if quench_times > 0 then
				local attr_type, attr_value = PlayerPackage:LuaFnGetEquipQuenchingAttr(g_EquipBagIndex)
				g_EquipAttrList[attr_count + 1]:Show()
				local upstage_rate = PlayerPackage:LuaFnGetBagEquipUpstageRate(g_EquipBagIndex, attr_count)
				local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, upstage_rate)
				g_EquipAttrList[attr_count + 1]:SetText(tostring(attr_txt))
			end
		end

		if g_TargetEquipBagIndex ~= -1 then
			local theMaterilaAction = EnumAction(g_TargetEquipBagIndex, "packageitem")
			EquipEducation_UpstageTransfer_AfterEquipItem:SetActionItem(theMaterilaAction:GetID())
			LifeAbility:Lock_Packet_Item(g_TargetEquipBagIndex, 1)
			
			local target_attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(g_TargetEquipBagIndex)
			if target_attr_count > 0 and target_attr_count < 10 then
				for i = 1, target_attr_count do
					local attr_type, attr_value = PlayerPackage:LuaFnGetBagEquipExtAttr(g_TargetEquipBagIndex, i - 1)
					g_TargetAttrList[i]:Show()
					local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, 0)
					g_TargetAttrList[i]:SetText(tostring(attr_txt))
				end
				
				local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_TargetEquipBagIndex)
				if quench_times > 0 then
					local attr_type, attr_value = PlayerPackage:LuaFnGetEquipQuenchingAttr(g_TargetEquipBagIndex)
					g_TargetAttrList[target_attr_count + 1]:Show()
					local upstage_rate = PlayerPackage:LuaFnGetBagEquipUpstageRate(g_TargetEquipBagIndex, target_attr_count)
					local attr_txt = PlayerPackage:LuaFnGetEquipUpstageAttrTxt(attr_type, attr_value, upstage_rate)
					g_TargetAttrList[target_attr_count + 1]:SetText(tostring(attr_txt))
				end
			end
		end
	end	
end

--从背包拖拽到转移源装备框
function EquipEducation_UpstageTransfer_OnEquipDragedDropFromBag(iBagIndex)
	
	if iBagIndex == nil then
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{NJBZ_220816_252}")
		return
	end

	if PlayerPackage:LuaFnIsBagEquipUpstaged(iBagIndex) == 0 then
		PushDebugMessage("#{SZJJ_250801_66}")
		return
	end
	
	--释放原来的道具
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
	end
	g_EquipBagIndex = iBagIndex

	EquipEducation_UpstageTransfer_Update()
end

function EquipEducation_UpstageTransfer_OnBagItemRClicked(iBagIndex)
	if g_EquipBagIndex == -1 then
		EquipEducation_UpstageTransfer_OnEquipDragedDropFromBag(iBagIndex)
	else
		EquipEducation_UpstageTransfer_OnTargetEquipDragedDropFromBag(iBagIndex)
	end
end

function EquipEducation_UpstageTransfer_OnEquipRClicked(flag)
	if flag == 1 then		
		if g_EquipBagIndex ~= -1 then
			LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
			g_EquipBagIndex = -1
			EquipEducation_UpstageTransfer_Update()
		end		
	elseif flag == 2 then
		if g_TargetEquipBagIndex ~= -1 then
			LifeAbility:Lock_Packet_Item(g_TargetEquipBagIndex, 0)
			g_TargetEquipBagIndex = -1
			EquipEducation_UpstageTransfer_Update()
		end
	end
end

function EquipEducation_UpstageTransfer_OnItemDragedDropAway()

end

--从背包拖拽到转移目标装备框
function EquipEducation_UpstageTransfer_OnTargetEquipDragedDropFromBag(iBagIndex)

	if iBagIndex == nil then
		return
	end
	
	if g_EquipBagIndex == -1 then
		PushDebugMessage("#{SZJJ_250801_67}")
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{SZJJ_250801_112}")
		return
	end
	
	--武器不可以
	if PlayerPackage:Lua_IsBagItemWeapon(iBagIndex) == 1 then
		PushDebugMessage("#{SZJJ_250801_120}")
		return
	end
	
	local can_upstage = 0
	local is_chonglou = PlayerPackage:LuaFnIsChongLouEquip(iBagIndex)
	local is_shougong = PlayerPackage:LuaFnIsHandMakeEquip(iBagIndex)
	local req_level = PlayerPackage:Lua_GetBagEquipNeedLevel(iBagIndex)
	local equip_qual = PlayerPackage:LuaFnGetBagEquipQual(iBagIndex)
	if is_chonglou == 1 then
		can_upstage = 1
	elseif is_shougong == 1 and req_level >= 90 and equip_qual >= 6 then
		can_upstage = 1
		if PlayerPackage:Lua_IsBagItemNeedIdentify(iBagIndex) == 1 then
			PushDebugMessage("#{SZJJ_250801_113}")
			return
		end
	end
	
	if can_upstage ~= 1 then
		PushDebugMessage("#{SZJJ_250801_120}")
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
	
	local ep = PlayerPackage:Lua_GetBagItemEquipPoint(g_EquipBagIndex)
	local target_ep = PlayerPackage:Lua_GetBagItemEquipPoint(iBagIndex)
	if ep ~= target_ep then
		PushDebugMessage("#{SZJJ_250801_119}")
		return
	end

	local attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(g_EquipBagIndex)
	local target_attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(iBagIndex)
	local quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(g_EquipBagIndex)
	local target_quench_times = PlayerPackage:LuaFnGetEquipQuenchingTimes(iBagIndex)
	local have_quenching = 0
	if quench_times > 0 then
		have_quenching = 1
	end
	local target_have_quenching = 0
	if target_quench_times > 0 then
		target_have_quenching = 1
	end
	if attr_count ~= target_attr_count or have_quenching ~= target_have_quenching then
		PushDebugMessage("#{SZJJ_250801_108}")
		return
	end
	
	if PlayerPackage:LuaFnIsBagEquipUpstaged(iBagIndex) ~= 0 then
		PushDebugMessage("#{SZJJ_250801_70}")
		return
	end

	--释放原来的道具
	if g_TargetEquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_TargetEquipBagIndex, 0)
	end
	g_TargetEquipBagIndex = iBagIndex

	EquipEducation_UpstageTransfer_Update()
end

function EquipEducation_UpstageTransfer_UpstageMaterial_OnRBClicked()
	if g_TargetEquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_TargetEquipBagIndex, 0)
		g_TargetEquipBagIndex = -1
		EquipEducation_UpstageTransfer_Update()
	end
end

function EquipEducation_UpstageTransfer_CloseClicked()
	this:Hide()
end

function EquipEducation_UpstageTransfer_CleanUp()
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
	end
	
	if g_TargetEquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_TargetEquipBagIndex, 0)
		g_TargetEquipBagIndex = -1
	end
	
	EquipEducation_UpstageTransfer_BeforeEquipItem:SetActionItem(-1)
	EquipEducation_UpstageTransfer_AfterEquipItem:SetActionItem(-1)

end

function EquipEducation_UpstageTransfer_OnHidden()
	EquipEducation_UpstageTransfer_CleanUp()
	m_ObjServerId = -1
end

function EquipEducation_UpstageTransfer_OKClicked()
	if g_EquipBagIndex == -1 then
		PushDebugMessage("#{SZJJ_250801_71}")
		return
	end
	
	if g_TargetEquipBagIndex == -1 then
		PushDebugMessage("#{SZJJ_250801_71}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("UpstageTransfer")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_EquipBagIndex)
		Set_XSCRIPT_Parameter(2, g_TargetEquipBagIndex)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function EquipEducation_UpstageTransfer_HelpClicked()

end
--Care Obj
function EquipEducation_UpstageTransfer_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function EquipEducation_UpstageTransfer_Frame_On_ResetPos()
	if g_EquipEducation_UpstageTransfer_Frame_UnifiedPosition ~= nil then
		EquipEducation_UpstageTransfer_Frame:SetProperty("UnifiedPosition", g_EquipEducation_UpstageTransfer_Frame_UnifiedPosition)
	end
end

function EquipEducation_UpstageTransfer_GetEquipType(ep)
	--1.帽子 2.衣服 3.手套 4.鞋 5.腰带 15.护肩 
	if ep == 1 or ep == 2 or 
		ep == 3 or ep == 4 or 
		ep == 5 or ep == 15 then
		return 1
	end
	
	--6.戒指 7.项链 12.护符 14.护腕
	if ep == 6 or ep == 7 or 
		ep == 12 or ep == 14 then
		return 2
	end
	
	return 0
end 