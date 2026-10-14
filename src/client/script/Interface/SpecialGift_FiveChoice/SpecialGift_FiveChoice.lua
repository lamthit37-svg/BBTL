--：5选1

local g_SpecialGift_FiveChoice_Frame_UnifiedPosition = ""
local m_ItemIndexSel = 0
local m_ItemBagePos = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_flag = {0,0,0,0,0}
local g_Count = 5

local g_SetItem = {	
	[38007058] = {	38007039, 38007040, 38007041, 38007042,38007043  },
	
}

local g_ScriptIdTable = {
	[38007058] = 998276,
	
}

local g_ItemTitle = {
	[38007058] = "#{CJSZ_211124_35}",

}

function SpecialGift_FiveChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function SpecialGift_FiveChoice_OnLoad()

	g_SpecialGift_FiveChoice_Frame_UnifiedPosition = SpecialGift_FiveChoice_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SpecialGift_FiveChoice_Page_Lace1Item
	g_ActionItem[2] = SpecialGift_FiveChoice_Page_Lace2Item
	g_ActionItem[3] = SpecialGift_FiveChoice_Page_Lace3Item
	g_ActionItem[4] = SpecialGift_FiveChoice_Page_Lace4Item
	g_ActionItem[5] = SpecialGift_FiveChoice_Page_Lace5Item
	
	g_ActionMask[1] = SpecialGift_FiveChoice_Page_Lace1Item_Mask
	g_ActionMask[2] = SpecialGift_FiveChoice_Page_Lace2Item_Mask
	g_ActionMask[3] = SpecialGift_FiveChoice_Page_Lace3Item_Mask
	g_ActionMask[4] = SpecialGift_FiveChoice_Page_Lace4Item_Mask
	g_ActionMask[5] = SpecialGift_FiveChoice_Page_Lace5Item_Mask
	
	g_ItemNameText[1] = SpecialGift_FiveChoice_Page_Lace1Item_Tip
	g_ItemNameText[2] = SpecialGift_FiveChoice_Page_Lace2Item_Tip
	g_ItemNameText[3] = SpecialGift_FiveChoice_Page_Lace3Item_Tip
	g_ItemNameText[4] = SpecialGift_FiveChoice_Page_Lace4Item_Tip
	g_ItemNameText[5] = SpecialGift_FiveChoice_Page_Lace5Item_Tip
end										

function SpecialGift_FiveChoice_OnEvent(event)
	if event == "UI_COMMAND" and (tonumber(arg0) == 99827601 ) then		 --todo uicommand

		SpecialGift_FiveChoice_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()		
		SpecialGift_FiveChoice_Update()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_FiveChoice_Frame_On_ResetPos()
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

function SpecialGift_FiveChoice_Update()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if g_SetItem[item_table_index] == nil or g_ItemTitle[item_table_index] == nil then
		return
	end
	
	for i = 1, 5 do
		local itemAction = DataPool:CreateActionItemForShow(g_SetItem[item_table_index][i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = PlayerPackage:GetItemName(g_SetItem[item_table_index][i])
		g_ItemNameText[i]:SetText("#L"..strName)
	end

	G_SpecialGift_FiveChoice_DragTitle = SpecialGift_FiveChoice_DragTitle
	G_SpecialGift_FiveChoice_Page_Info = SpecialGift_FiveChoice_Page_Info
	G_SpecialGift_FiveChoice_Text 	 = SpecialGift_FiveChoice_Text

	G_SpecialGift_FiveChoice_Page_Conermark = {}

	G_SpecialGift_FiveChoice_Page_Conermark[1] = SpecialGift_FiveChoice_Page_Lace1Item_Conermark
	G_SpecialGift_FiveChoice_Page_Conermark[2] = SpecialGift_FiveChoice_Page_Lace2Item_Conermark
	G_SpecialGift_FiveChoice_Page_Conermark[3] = SpecialGift_FiveChoice_Page_Lace3Item_Conermark
	G_SpecialGift_FiveChoice_Page_Conermark[4] = SpecialGift_FiveChoice_Page_Lace4Item_Conermark
	G_SpecialGift_FiveChoice_Page_Conermark[5] = SpecialGift_FiveChoice_Page_Lace5Item_Conermark
	for i=1,g_Count do
		g_flag[i] = Get_XParam_INT(i)
	end

	G_SpecialGift_FiveChoice_Text:Show()

	--已经拥有--
	for i = 1,5 do
		if g_flag[i] > 0 then
			G_SpecialGift_FiveChoice_Page_Conermark[i]:Show()
		else
			G_SpecialGift_FiveChoice_Page_Conermark[i]:Hide()
		end
	end	
	G_SpecialGift_FiveChoice_DragTitle:SetText(g_ItemTitle[item_table_index])
	G_SpecialGift_FiveChoice_Page_Info:SetText("#{CJSZ_211124_36}")
	G_SpecialGift_FiveChoice_Text:SetText("#{CJSZ_211124_37}")

end

function SpecialGift_FiveChoice_OnActionItemClicked(index)

	if m_ItemIndexSel == index then
		m_ItemIndexSel = -1
		for i = 1, 5 do	
			g_ActionItem[i]:SetPushed(0)
			g_ActionMask[i]:Hide()
		end
		return
	end
	
	m_ItemIndexSel = index
	
	for i = 1, 5 do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	g_ActionItem[m_ItemIndexSel]:SetPushed(1)
	g_ActionMask[m_ItemIndexSel]:Show()
	
end

function SpecialGift_FiveChoice_CloseClicked()
	this:Hide()
end

function SpecialGift_FiveChoice_CleanUp()	
	
	for i = 1, 5 do	
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

function SpecialGift_FiveChoice_OnHidden()
	SpecialGift_FiveChoice_CleanUp()
end

function SpecialGift_FiveChoice_OKClicked()
	
	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if g_ScriptIdTable[item_table_index] == nil then
		return
	end

	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{CJSZ_211124_38}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChoice")
		Set_XSCRIPT_ScriptID(g_ScriptIdTable[item_table_index])
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	this:Hide()
end

function SpecialGift_FiveChoice_Frame_On_ResetPos()
	if g_SpecialGift_FiveChoice_Frame_UnifiedPosition ~= nil then
		SpecialGift_FiveChoice_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_FiveChoice_Frame_UnifiedPosition)
	end
end