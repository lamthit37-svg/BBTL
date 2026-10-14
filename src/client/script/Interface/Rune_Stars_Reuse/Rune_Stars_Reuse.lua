--!!!reloadscript =Rune_Stars_Reuse

local g_Rune_Stars_Reuse_Frame_UnifiedPosition = ""
local m_ItemBagIndex = -1

function Rune_Stars_Reuse_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("SKILLCARD_RECYCLE_PUTIN")
	this:RegisterEvent("SKILLCARD_RECYCLE_RCLICK")
	this:RegisterEvent("SKILLCARD_RECYCLE_REMOVE",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function Rune_Stars_Reuse_OnLoad()	
	g_Rune_Stars_Reuse_Frame_UnifiedPosition = Rune_Stars_Reuse_Frame:GetProperty("UnifiedPosition")
	Rune_Stars_ReuseBtn:SetProperty("DraggingEnabled","True")
end										

function Rune_Stars_Reuse_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88855501 then		
		this:Show()
		m_ItemBagIndex = -1
		OpenWindow("Packet")
		Rune_Stars_Reuse_Update()
		Rune_Stars_Reuse_BeginCareObj(Get_XParam_INT(0))	
		return
	end
	
	if event == "SKILLCARD_RECYCLE_PUTIN" then
		if tonumber(arg0) ~= nil then
			Rune_Stars_Reuse_OnItemDragedDropFromBag(tonumber(arg0))
		end
		return
	end
	
	if event == "SKILLCARD_RECYCLE_RCLICK" then
		if tonumber(arg0) ~= nil then
			Rune_Stars_Reuse_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "SKILLCARD_RECYCLE_REMOVE" then
		Rune_Stars_Reuse_CleanUp()
		return		
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Stars_Reuse_Frame_On_ResetPos()	 
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == m_ItemBagIndex then
		Rune_Stars_Reuse_Update()
		return
	end
	
end

function Rune_Stars_Reuse_Update()
	
	--没有道具直接清空
	if m_ItemBagIndex == -1 then
		Rune_Stars_Reuse_CleanUp()
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagIndex)	
	local nSkillCardID, chip_type, chip_count = DataPool:LuaFnGetSkillCardRecycleInfo(item_table_index)
	if chip_type ~= 3 and chip_type ~= 4 then
		Rune_Stars_Reuse_CleanUp()
		return		
	end
	
	--加锁
	if PlayerPackage:IsLock(m_ItemBagIndex) == 1 then
		Rune_Stars_Reuse_CleanUp()
		return
	end

	local theAction = EnumAction(m_ItemBagIndex, "packageitem")
	if theAction:GetID() == 0 then
		Rune_Stars_Reuse_CleanUp()
		return
	end
	
	Rune_Stars_ReuseBtn:SetActionItem(theAction:GetID())
	LifeAbility:Lock_Packet_Item(m_ItemBagIndex,1)
	
	local nQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
	local strName = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Name")
	local strNameColor = ""
	
	if nQuality == 1 then
		strNameColor = "#G"
	elseif nQuality == 2 then
		strNameColor = "#B"
	elseif nQuality == 3 then
		strNameColor = "#cbe38ff"
	elseif nQuality == 4 then
		strNameColor = "#cfff965"
	end
	Rune_Stars_Reuse_Text2:SetText("#L"..strName)
	
	local strTemp = ""
	if chip_type == 3 then
		strTemp = ScriptGlobal_Format("#{XZJC_200309_356}", tostring(chip_count), "#{XZJC_200309_262}")
	elseif chip_type == 4 then
		strTemp = ScriptGlobal_Format("#{XZJC_200309_356}", tostring(chip_count), "#{XZJC_200309_261}")
	end

	Rune_Stars_Reuse_Text3:SetText("#{XZJC_200309_355}"..strTemp)
end

--从背包拖拽到UI
function Rune_Stars_Reuse_OnItemDragedDropFromBag(iBagIndex)
	
	--判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime() > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)	
	local _, chip_type, _ = DataPool:LuaFnGetSkillCardRecycleInfo(item_table_index)
	if chip_type ~= 3 and chip_type ~= 4 then
		PushDebugMessage("#{XZJC_200309_252}")
		return		
	end
	
	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{XZJC_200309_253}")	
		return
	end
		
	--释放原来的道具
	if m_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(m_ItemBagIndex,0)
	end
	
	m_ItemBagIndex = iBagIndex
	
	--刷新界面
	Rune_Stars_Reuse_Update()	
	
end

--从背包内右键点击
function Rune_Stars_Reuse_OnBagItemRClicked(iBagIndex)
	Rune_Stars_Reuse_OnItemDragedDropFromBag(iBagIndex)
end

--右键单击ActionItem
function Rune_Stars_Reuse_OnActionItemRClicked()
	Rune_Stars_Reuse_CleanUp()
end

function Rune_Stars_Reuse_CloseClicked()
	this:Hide()
end

function Rune_Stars_Reuse_CleanUp()	
	Rune_Stars_ReuseBtn:SetActionItem(-1)
	
	if m_ItemBagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(m_ItemBagIndex,0)
	end
	m_ItemBagIndex = -1
	
	Rune_Stars_Reuse_Text2:SetText("")
	Rune_Stars_Reuse_Text3:SetText("#{XZJC_200309_355}")
end

function Rune_Stars_Reuse_OnHidden()
	Rune_Stars_Reuse_CleanUp()
end

function Rune_Stars_Reuse_OKClicked()

	if m_ItemBagIndex < 0 then
		PushDebugMessage("#{XZJC_200309_357}")
		return
	end
	
	LuaFnSkillCardRecycleConfirm(m_ItemBagIndex)
end

--Care Obj
function Rune_Stars_Reuse_BeginCareObj(obj_id)	
	m_ObjCared = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(m_ObjCared, 1)
end

function Rune_Stars_Reuse_Frame_On_ResetPos()
	if g_Rune_Stars_Reuse_Frame_UnifiedPosition ~= nil then
		Rune_Stars_Reuse_Frame:SetProperty("UnifiedPosition", g_Rune_Stars_Reuse_Frame_UnifiedPosition)
	end
end