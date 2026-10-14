--EquipEducation_UpstageRemove
--!!!reloadscript =EquipEducation_UpstageRemove

local g_EquipEducation_UpstageRemove_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_EquipBagIndex = -1

local g_ApplyState = 0
local g_LeftTime = 0

function EquipEducation_UpstageRemove_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("EUS_REMOVE_ITEM", false)
end

function EquipEducation_UpstageRemove_OnLoad()
	g_EquipEducation_UpstageRemove_Frame_UnifiedPosition = EquipEducation_UpstageRemove_Frame:GetProperty("UnifiedPosition")
end

function EquipEducation_UpstageRemove_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88220008 then
		if not this:IsVisible() then
			g_ApplyState = Get_XParam_INT(1)
			g_LeftTime = Get_XParam_INT(2)
			EquipEducation_UpstageRemove_CleanUp()
			this:Show()
			--OpenWindow("Packet")
			EquipEducation_UpstageRemove_Update()
			EquipEducation_UpstageRemove_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88220009 then
		if this:IsVisible() then
			g_ApplyState = Get_XParam_INT(0)
			g_LeftTime = Get_XParam_INT(1)
			EquipEducation_UpstageRemove_Update()
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		EquipEducation_UpstageRemove_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "PACKAGE_ITEM_CHANGED_EX" then
		EquipEducation_UpstageRemove_Update()
		return
	end	
	
	if event == "EUS_REMOVE_ITEM" then
		local bagidx = tonumber(arg0)
		local op_type = tonumber(arg1)	--1 左键拖 2 右键点
		
		if op_type == 1 then
			EquipEducation_UpstageRemove_OnEquipDragedDropFromBag(bagidx)
		elseif op_type == 2 then
			EquipEducation_UpstageRemove_OnBagItemRClicked(bagidx)
		end
		return
	end
end

function EquipEducation_UpstageRemove_Check()
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
end

function EquipEducation_UpstageRemove_Update()
	
	EquipEducation_UpstageRemove_Check()
	
	EquipEducation_UpstageRemove_Item:SetActionItem(-1)
	
	EquipEducation_UpstageRemove_Time:SetText("")
	
	if g_ApplyState == 1 then
		local hr = math.floor(g_LeftTime / 3600)
		if math.mod(g_LeftTime, 3600) ~= 0 then
			hr = hr + 1
		end
		local strTemp = ScriptGlobal_Format("#{SZJJ_250801_152}", tostring(hr))
		EquipEducation_UpstageRemove_Time:SetText(tostring(strTemp))
		
		EquipEducation_UpstageRemove_Apply:Disable()
		EquipEducation_UpstageRemove_Cancel:Enable()
	elseif g_ApplyState == 2 then
		local hr = math.floor(g_LeftTime / 3600)
		if math.mod(g_LeftTime, 3600) ~= 0 then
			hr = hr + 1
		end
		local strTemp = ScriptGlobal_Format("#{SZJJ_250801_153}", tostring(hr))
		EquipEducation_UpstageRemove_Time:SetText(tostring(strTemp))
		
		EquipEducation_UpstageRemove_Apply:Disable()
		EquipEducation_UpstageRemove_Cancel:Enable()
	else
		EquipEducation_UpstageRemove_Cancel:Disable()
		EquipEducation_UpstageRemove_Apply:Enable()
	end
	
	if g_EquipBagIndex ~= -1 then
		local theEquipAction = EnumAction(g_EquipBagIndex, "packageitem")
		EquipEducation_UpstageRemove_Item:SetActionItem(theEquipAction:GetID())
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 1)
	end	
end

--从背包拖拽到装备框
function EquipEducation_UpstageRemove_OnEquipDragedDropFromBag(iBagIndex)
	
	if iBagIndex == nil then
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
	--	PushDebugMessage("#{NJBZ_220816_252}")
	--	return
	end

	if PlayerPackage:LuaFnIsBagEquipUpstaged(iBagIndex) == 0 then
		PushDebugMessage("#{SZJJ_250801_156}")
		return
	end
	
	if g_ApplyState ~= 2 then
		PushDebugMessage("#{SZJJ_250801_155}")
		return
	end
	
	--释放原来的道具
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
	end
	g_EquipBagIndex = iBagIndex

	EquipEducation_UpstageRemove_Update()
end

function EquipEducation_UpstageRemove_OnBagItemRClicked(iBagIndex)
	EquipEducation_UpstageRemove_OnEquipDragedDropFromBag(iBagIndex)
end

function EquipEducation_UpstageRemove_OnEquipRClicked(flag)
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
		EquipEducation_UpstageRemove_Update()
	end		
end

function EquipEducation_UpstageRemove_OnItemDragedDropAway()

end

function EquipEducation_UpstageRemove_CloseClicked()
	this:Hide()
end

function EquipEducation_UpstageRemove_CleanUp()
	if g_EquipBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_EquipBagIndex, 0)
		g_EquipBagIndex = -1
	end
	
	EquipEducation_UpstageRemove_Item:SetActionItem(-1)
end

function EquipEducation_UpstageRemove_OnHidden()
	EquipEducation_UpstageRemove_CleanUp()
	m_ObjServerId = -1
end

function EquipEducation_UpstageRemove_OKClicked()
	if g_EquipBagIndex == -1 then
		PushDebugMessage("#{SZJJ_250801_157}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("UpstageRemove")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_EquipBagIndex)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function EquipEducation_UpstageRemove_OnApply()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("ApplyUpstageRemove")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function EquipEducation_UpstageRemove_OnCancelApply()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("ApplyCancelUpstageRemove")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function EquipEducation_UpstageRemove_HelpClicked()

end
--Care Obj
function EquipEducation_UpstageRemove_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function EquipEducation_UpstageRemove_Frame_On_ResetPos()
	if g_EquipEducation_UpstageRemove_Frame_UnifiedPosition ~= nil then
		EquipEducation_UpstageRemove_Frame:SetProperty("UnifiedPosition", g_EquipEducation_UpstageRemove_Frame_UnifiedPosition)
	end
end
