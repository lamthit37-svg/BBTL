--!!!reloadscript =DiGong_Shop_Two

local g_DiGong_Shop_Two_Frame_UnifiedPosition = ""
local m_ItemIndexSel = 0
local m_ItemBagePos = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_SetItem = {	
	[38005658] = {38005066, 38005067},
}


function DiGong_Shop_Two_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function DiGong_Shop_Two_OnLoad()

	g_DiGong_Shop_Two_Frame_UnifiedPosition = DiGong_Shop_Two_Frame:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = DiGong_Shop_Two_Page_Lace1Item
	g_ActionItem[2] = DiGong_Shop_Two_Page_Lace2Item

	
	g_ActionMask[1] = DiGong_Shop_Two_Page_Lace1Item_Mask
	g_ActionMask[2] = DiGong_Shop_Two_Page_Lace2Item_Mask

	
	g_ItemNameText[1] = DiGong_Shop_Two_Page_Lace1Item_Tip
	g_ItemNameText[2] = DiGong_Shop_Two_Page_Lace2Item_Tip
end										

function DiGong_Shop_Two_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88888201 then		

		DiGong_Shop_Two_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()		
		DiGong_Shop_Two_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		DiGong_Shop_Two_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == m_ItemBagePos then
		this:Hide()
		return
	end
	
end

function DiGong_Shop_Two_Update()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if g_SetItem[item_table_index] == nil then
		return
	end
	
	for i = 1, 2 do
		local itemAction = DataPool:CreateBindActionItemForShow(g_SetItem[item_table_index][i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName =PlayerPackage:GetItemName(g_SetItem[item_table_index][i])
		g_ItemNameText[i]:SetText("#L"..strName)
	end
end

function DiGong_Shop_Two_OnActionItemClicked(index)

	if m_ItemIndexSel == index then
		return
	end
	
	m_ItemIndexSel = index
	
	for i = 1, 2 do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	g_ActionItem[m_ItemIndexSel]:SetPushed(1)
	g_ActionMask[m_ItemIndexSel]:Show()
	
end

function DiGong_Shop_Two_CloseClicked()
	this:Hide()
end

function DiGong_Shop_Two_CleanUp()	
	
	for i = 1, 2 do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
	end
	
	if m_ItemBagePos >= 0 then
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,0)
	end
	
	m_ItemBagePos = -1
	m_ItemIndexSel = 0
end

function DiGong_Shop_Two_OnHidden()
	DiGong_Shop_Two_CleanUp()
end

function DiGong_Shop_Two_OKClicked()
	
	if m_ItemBagePos < 0 then
		return
	end
	
	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{JLQX_211206_145}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickOne")
		Set_XSCRIPT_ScriptID(888882)
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	this:Hide()
end

function DiGong_Shop_Two_Frame_On_ResetPos()
	if g_DiGong_Shop_Two_Frame_UnifiedPosition ~= nil then
		DiGong_Shop_Two_Frame:SetProperty("UnifiedPosition", g_DiGong_Shop_Two_Frame_UnifiedPosition)
	end
end