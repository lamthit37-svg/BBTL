
--4选1

local g_SeventhFestivalTopList_FourChoice_UnifiedPosition = ""
local m_ItemIndexSel = 0
local m_ItemBagePos = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_SetQXItem = {	0, 0, 0, 0 }
local g_SeventhFestivalTopList_ScriptIdQX = -1


function SeventhFestivalTopList_FourChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function SeventhFestivalTopList_FourChoice_OnLoad()

	g_SeventhFestivalTopList_FourChoice_UnifiedPosition = SeventhFestivalTopList_FourChoice_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SeventhFestivalTopList_FourChoice_Page_Lace1Item
	g_ActionItem[2] = SeventhFestivalTopList_FourChoice_Page_Lace2Item
	g_ActionItem[3] = SeventhFestivalTopList_FourChoice_Page_Lace3Item
	g_ActionItem[4] = SeventhFestivalTopList_FourChoice_Page_Lace4Item
	
	g_ActionMask[1] = SeventhFestivalTopList_FourChoice_Page_Lace1Item_Mask
	g_ActionMask[2] = SeventhFestivalTopList_FourChoice_Page_Lace2Item_Mask
	g_ActionMask[3] = SeventhFestivalTopList_FourChoice_Page_Lace3Item_Mask
	g_ActionMask[4] = SeventhFestivalTopList_FourChoice_Page_Lace4Item_Mask
	
	g_ItemNameText[1] = SeventhFestivalTopList_FourChoice_Page_Lace1Item_Tip
	g_ItemNameText[2] = SeventhFestivalTopList_FourChoice_Page_Lace2Item_Tip
	g_ItemNameText[3] = SeventhFestivalTopList_FourChoice_Page_Lace3Item_Tip
	g_ItemNameText[4] = SeventhFestivalTopList_FourChoice_Page_Lace4Item_Tip
	
end										

function SeventhFestivalTopList_FourChoice_OnEvent(event)
		
	if event == "UI_COMMAND" and (tonumber(arg0) == 89363002) then
	
		SeventhFestivalTopList_FourChoice_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		g_SeventhFestivalTopList_ScriptIdQX = Get_XParam_INT(1)
		for i = 1, table.getn(g_SetQXItem) do
			g_SetQXItem[i] = Get_XParam_INT(i+1)
		end
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()		
		SeventhFestivalTopList_FourChoice_UpdateForQiXi()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SeventhFestivalTopList_FourChoice_Frame_On_ResetPos()
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

function SeventhFestivalTopList_FourChoice_UpdateForQiXi()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	local strTitle = "#gFF0FA0"..PlayerPackage:GetItemName(item_table_index)
	SeventhFestivalTopList_FourChoice_DragTitle:SetText(strTitle)
	SeventhFestivalTopList_FourChoice_Page_Info:SetText("#{QXLS_240704_15}")
	
	for i = 1, 4 do
		local itemAction = DataPool:CreateActionItemForShow(g_SetQXItem[i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = PlayerPackage:GetItemName(g_SetQXItem[i])
		g_ItemNameText[i]:SetText("#L"..strName)
	end

end

function SeventhFestivalTopList_FourChoice_OnActionItemClicked(index)

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

function SeventhFestivalTopList_FourChoice_CloseClicked()
	this:Hide()
end

function SeventhFestivalTopList_FourChoice_CleanUp()	
	
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

function SeventhFestivalTopList_FourChoice_OnHidden()
	SeventhFestivalTopList_FourChoice_CleanUp()
end

function SeventhFestivalTopList_FourChoice_OKClicked()
	
	if m_ItemBagePos < 0 then
		return
	end

	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{CJSZ_211124_38}")
		return
	end
	
	if g_SeventhFestivalTopList_ScriptIdQX > 0 then
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnFourChoiceOne")
			Set_XSCRIPT_ScriptID(g_SeventhFestivalTopList_ScriptIdQX)
			Set_XSCRIPT_Parameter(0, m_ItemBagePos)
			Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	
	end
	
	this:Hide()
end

function SeventhFestivalTopList_FourChoice_Frame_On_ResetPos()
	if g_SeventhFestivalTopList_FourChoice_UnifiedPosition ~= nil then
		SeventhFestivalTopList_FourChoice_Frame_BK:SetProperty("UnifiedPosition", g_SeventhFestivalTopList_FourChoice_UnifiedPosition)
	end
end

