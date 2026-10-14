--!!!reloadscript =Cat_Choose

local g_Cat_Choose_Frame_UnifiedPosition = ""
local m_ItemIndexSel = 0
local m_ItemBagePos = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_flag = {0,0,0,0}
local g_Count = 4

local g_SetItem = {	
	[38005349] = {38005335, 38005336, 38005337, 38005338},
}


function Cat_Choose_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Cat_Choose_OnLoad()

	g_Cat_Choose_Frame_UnifiedPosition = Cat_Choose_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = Cat_Choose_Page_Lace1Item
	g_ActionItem[2] = Cat_Choose_Page_Lace2Item
	g_ActionItem[3] = Cat_Choose_Page_Lace3Item
	g_ActionItem[4] = Cat_Choose_Page_Lace4Item
	
	g_ActionMask[1] = Cat_Choose_Page_Lace1Item_Mask
	g_ActionMask[2] = Cat_Choose_Page_Lace2Item_Mask
	g_ActionMask[3] = Cat_Choose_Page_Lace3Item_Mask
	g_ActionMask[4] = Cat_Choose_Page_Lace4Item_Mask
	
	g_ItemNameText[1] = Cat_Choose_Page_Lace1Item_Tip
	g_ItemNameText[2] = Cat_Choose_Page_Lace2Item_Tip
	g_ItemNameText[3] = Cat_Choose_Page_Lace3Item_Tip
	g_ItemNameText[4] = Cat_Choose_Page_Lace4Item_Tip
end										

function Cat_Choose_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88844741 then		

		Cat_Choose_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()		
		Cat_Choose_Update()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Cat_Choose_Frame_On_ResetPos()
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

function Cat_Choose_Update()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if g_SetItem[item_table_index] == nil then
		return
	end
	
	for i = 1, 4 do
		local itemAction = DataPool:CreateActionItemForShow(g_SetItem[item_table_index][i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = PlayerPackage:GetItemName(g_SetItem[item_table_index][i])
		g_ItemNameText[i]:SetText("#L"..strName)
	end

	G_Cat_Choose_DragTitle = Cat_Choose_DragTitle
	G_Cat_Choose_Page_Info = Cat_Choose_Page_Info
	G_Cat_Choose_Text 	 = Cat_Choose_Text

	G_Cat_Choose_Page_Conermark = {}

	G_Cat_Choose_Page_Conermark[1] = Cat_Choose_Page_Lace1Item_Conermark
	G_Cat_Choose_Page_Conermark[2] = Cat_Choose_Page_Lace2Item_Conermark
	G_Cat_Choose_Page_Conermark[3] = Cat_Choose_Page_Lace3Item_Conermark
	G_Cat_Choose_Page_Conermark[4] = Cat_Choose_Page_Lace4Item_Conermark

	for i=1,g_Count do
		g_flag[i] = Get_XParam_INT(i)
	end

	G_Cat_Choose_Text:Show()

	--已经拥有--
	for i = 1,4 do
		if g_flag[i] > 0 then
			G_Cat_Choose_Page_Conermark[i]:Show()
		else
			G_Cat_Choose_Page_Conermark[i]:Hide()
		end
	end	
	G_Cat_Choose_DragTitle:SetText("#{YHGMHY_210609_16}")
	G_Cat_Choose_Page_Info:SetText("#{YHGMHY_210609_17}")
	G_Cat_Choose_Text:SetText("#{YHGMHY_210609_22}")

end

function Cat_Choose_OnActionItemClicked(index)

	if m_ItemIndexSel == index then
		m_ItemIndexSel = -1
		for i = 1, 4 do	
			g_ActionItem[i]:SetPushed(0)
			g_ActionMask[i]:Hide()
		end
		return
	end
	
	m_ItemIndexSel = index
	
	for i = 1, 4 do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	g_ActionItem[m_ItemIndexSel]:SetPushed(1)
	g_ActionMask[m_ItemIndexSel]:Show()
	
end

function Cat_Choose_CloseClicked()
	this:Hide()
end

function Cat_Choose_CleanUp()	
	
	for i = 1, 4 do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
	end
	
	if m_ItemBagePos >= 0 then
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,0)
	end
	
	m_ItemBagePos = -1
	m_ItemIndexSel = 0
	
	this:Hide()
end

function Cat_Choose_OnHidden()
	Cat_Choose_CleanUp()
end

function Cat_Choose_OKClicked()
	
	if m_ItemBagePos < 0 then
		return
	end
	
	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{XZJC_200309_358}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChoice")
		Set_XSCRIPT_ScriptID(888447)
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	this:Hide()
end

function Cat_Choose_Frame_On_ResetPos()
	if g_Cat_Choose_Frame_UnifiedPosition ~= nil then
		Cat_Choose_Frame_BK:SetProperty("UnifiedPosition", g_Cat_Choose_Frame_UnifiedPosition)
	end
end