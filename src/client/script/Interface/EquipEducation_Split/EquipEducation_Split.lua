--!!!reloadscript =EquipEducation_Split

local g_EquipEducation_Split_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_ItemBagIndex = -1

local g_MaterilaList = {
	20800055,
	20800056,
	20800057,
	20800058,
}

function EquipEducation_Split_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("EUS_DECOMPOSE_ITEM", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false) 
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("EUS_FRAGMENT", false)
end

function EquipEducation_Split_OnLoad()	
	g_EquipEducation_Split_Frame_UnifiedPosition = EquipEducation_Split_Frame:GetProperty("UnifiedPosition")
end										

function EquipEducation_Split_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88220002 then		
		this:Show()
		g_ItemBagIndex = -1
		OpenWindow("Packet")
		EquipEducation_Split_Update()
		EquipEducation_Split_BeginCareObj(Get_XParam_INT(0))	
		return
	end
	
	if event == "EUS_DECOMPOSE_ITEM" then
		local bagidx = tonumber(arg0)
		local op_type = tonumber(arg1)	--1 左键拖 2 右键点
		if op_type == 1 then
			EquipEducation_Split_OnItemDragedDropFromBag(bagidx)
		elseif op_type == 2 then
			EquipEducation_Split_OnBagItemRClicked(bagidx)
		end
		return
	end
	
	if event == "SKILLCARD_RECYCLE_RCLICK" then
		if tonumber(arg0) ~= nil then
			EquipEducation_Split_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "SKILLCARD_RECYCLE_REMOVE" then
		EquipEducation_Split_CleanUp()
		return		
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		EquipEducation_Split_Frame_On_ResetPos()	 
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == g_ItemBagIndex then
		EquipEducation_Split_Update()
		return
	end
	
	if event == "EUS_FRAGMENT" then
		local eus_fragment = Player:GetData("EUSFRAGMENT")
		local strTemp = ScriptGlobal_Format("#{SZJJ_250801_80}", tostring(eus_fragment))
		EquipEducation_Split_Num:SetText(strTemp)
	end
	
end

function EquipEducation_Split_Update()
	
	local eus_fragment = Player:GetData("EUSFRAGMENT")
	local strTemp = ScriptGlobal_Format("#{SZJJ_250801_80}", tostring(eus_fragment))
	EquipEducation_Split_Num:SetText(strTemp)
	
	--没有道具直接清空
	if g_ItemBagIndex == -1 then
		EquipEducation_Split_CleanUp()
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(g_ItemBagIndex) == 1 then
		EquipEducation_Split_CleanUp()
		return
	end

	local theAction = EnumAction(g_ItemBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		EquipEducation_Split_CleanUp()
		return
	end

	EquipEducation_Split_BeforeItem:SetActionItem(theAction:GetID())
	LifeAbility:Lock_Packet_Item(g_ItemBagIndex, 1)
	
	EquipEducation_Split_AfterItem:SetText("")
	
	local item_count = PlayerPackage:GetBagItemNum(g_ItemBagIndex)
	local item_table_index = PlayerPackage:GetItemTableIndex(g_ItemBagIndex)
	
	if tonumber(item_count) ~= nil and item_count > 0 and tonumber(item_table_index) ~= nil then
		local split_num = PlayerPackage:LuaFnGetEquipUpstageMatSplitNum(item_table_index)
		if tonumber(split_num) ~= nil and split_num > 0 then
			local gain_fragment = split_num * item_count
			EquipEducation_Split_AfterItem:SetText(tostring(gain_fragment))
		end
	end
end

--从背包拖拽到UI
function EquipEducation_Split_OnItemDragedDropFromBag(iBagIndex)
	
	--判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime() > 0) then
		PushDebugMessage("#{SZJJ_250801_13}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{SZJJ_250801_112}")	
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
	if tonumber(item_table_index) == nil then
		PushDebugMessage("#{SZJJ_250801_46}")
		return
	end
	
	if EquipEducation_Split_IsUpstageMaterila(item_table_index) ~= 1 then
		PushDebugMessage("#{SZJJ_250801_46}")
		return
	end
	
	local split_num = PlayerPackage:LuaFnGetEquipUpstageMatSplitNum(item_table_index)
	if tonumber(split_num) == nil or split_num <= 0 then
		PushDebugMessage("#{SZJJ_250801_83}")
		return
	end

	--释放原来的道具
	if g_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_ItemBagIndex,0)
	end
	
	g_ItemBagIndex = iBagIndex
	
	--刷新界面
	EquipEducation_Split_Update()	
end

--从背包内右键点击
function EquipEducation_Split_OnBagItemRClicked(iBagIndex)
	EquipEducation_Split_OnItemDragedDropFromBag(iBagIndex)
end

--右键单击ActionItem
function EquipEducation_Split_OnActionItemRClicked()
	EquipEducation_Split_CleanUp()
end

function EquipEducation_Split_CloseClicked()
	this:Hide()
end

function EquipEducation_Split_CleanUp()	
	EquipEducation_Split_BeforeItem:SetActionItem(-1)
	
	if g_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_ItemBagIndex,0)
	end
	g_ItemBagIndex = -1
	
	EquipEducation_Split_AfterItem:SetText("")
end

function EquipEducation_Split_OnHidden()
	EquipEducation_Split_CleanUp()
	m_ObjServerId = -1
end

function EquipEducation_Split_OKClicked()

	if g_ItemBagIndex < 0 then
		PushDebugMessage("#{SZJJ_250801_81}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(882200)
		Set_XSCRIPT_Function_Name("MaterialDecompose")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_ItemBagIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--Care Obj
function EquipEducation_Split_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function EquipEducation_Split_Frame_On_ResetPos()
	if g_EquipEducation_Split_Frame_UnifiedPosition ~= nil then
		EquipEducation_Split_Frame:SetProperty("UnifiedPosition", g_EquipEducation_Split_Frame_UnifiedPosition)
	end
end

function EquipEducation_Split_IsUpstageMaterila(item_index)
	for i = 1, table.getn(g_MaterilaList) do
		if g_MaterilaList[i] == item_index then
			return 1
		end	
	end
	return 0
end