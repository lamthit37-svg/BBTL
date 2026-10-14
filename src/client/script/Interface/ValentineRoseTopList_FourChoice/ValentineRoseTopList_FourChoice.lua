--4选2

local g_ValentineRoseTopList_FourChoice_Frame_UnifiedPosition = ""
local m_ItemIndexSel1 = -1
local m_ItemIndexSel2 = -1
local m_ItemBagePos = -1
local m_ItemscriptId = -1
local m_UICommandId = -1
local g_SelectItemIndex={};

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}
local g_Page_Conermark = {}

local g_Count = 4

local g_SetItem = {	
	[38005618] = {38005614, 38005615, 38005616, 38005617},
}

function ValentineRoseTopList_FourChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function ValentineRoseTopList_FourChoice_OnLoad()

	g_ValentineRoseTopList_FourChoice_Frame_UnifiedPosition = ValentineRoseTopList_FourChoice_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = ValentineRoseTopList_FourChoice_Page_Lace1Item
	g_ActionItem[2] = ValentineRoseTopList_FourChoice_Page_Lace2Item
	g_ActionItem[3] = ValentineRoseTopList_FourChoice_Page_Lace3Item
	g_ActionItem[4] = ValentineRoseTopList_FourChoice_Page_Lace4Item
	
	g_ActionMask[1] = ValentineRoseTopList_FourChoice_Page_Lace1Item_Mask
	g_ActionMask[2] = ValentineRoseTopList_FourChoice_Page_Lace2Item_Mask
	g_ActionMask[3] = ValentineRoseTopList_FourChoice_Page_Lace3Item_Mask
	g_ActionMask[4] = ValentineRoseTopList_FourChoice_Page_Lace4Item_Mask
	
	g_ItemNameText[1] = ValentineRoseTopList_FourChoice_Page_Lace1Item_Tip
	g_ItemNameText[2] = ValentineRoseTopList_FourChoice_Page_Lace2Item_Tip
	g_ItemNameText[3] = ValentineRoseTopList_FourChoice_Page_Lace3Item_Tip
	g_ItemNameText[4] = ValentineRoseTopList_FourChoice_Page_Lace4Item_Tip
	
end										

function ValentineRoseTopList_FourChoice_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 89276001 then		
		ValentineRoseTopList_FourChoice_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		for i=1, 4 do
			g_SelectItemIndex[i] = Get_XParam_INT(i)
		end
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()		
		ValentineRoseTopList_FourChoice_Update()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 99811101 then	
		m_UICommandId = 99811101
		ValentineRoseTopList_FourChoice_CleanUp()
		m_ItemscriptId = Get_XParam_INT(0)
		if m_ItemscriptId <= 0 then
			ValentineRoseTopList_FourChoice_CleanUp()	
			return
		end
		m_ItemBagePos = Get_XParam_INT(1)
		for i=1, 4 do
			g_SelectItemIndex[i] = Get_XParam_INT(i+1)
		end
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()		
		ValentineRoseTopList_FourChoice_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ValentineRoseTopList_FourChoice_Frame_On_ResetPos()
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

function ValentineRoseTopList_FourChoice_Update()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if item_table_index <= 0 then
		return
	end

	for i = 1, 4 do
		if m_UICommandId == 99811101 then
			local itemAction = DataPool:CreateBindActionItemForShow(g_SelectItemIndex[i], 1)
			if itemAction:GetID() ~= 0 then
				g_ActionItem[i]:SetActionItem(itemAction:GetID())
			end
		else
			local itemAction = DataPool:CreateActionItemForShow(g_SelectItemIndex[i], 1)
			if itemAction:GetID() ~= 0 then
				g_ActionItem[i]:SetActionItem(itemAction:GetID())
			end
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(g_SelectItemIndex[i])
		g_ItemNameText[i]:SetText("#L"..strName)
	end

	for i=1, 4 do
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end

	local szName = DataPool:Lua_GetItemNameByIndex(item_table_index)
	local szNameShow = ScriptGlobal_Format("#{MGCQ_220128_09}", szName)
	ValentineRoseTopList_FourChoice_DragTitle:SetText(szNameShow)
	
	if item_table_index == 38005976 or item_table_index == 38006462 or item_table_index == 38007615 or item_table_index == 38008116
		or item_table_index == 38008814  
	then
		ValentineRoseTopList_FourChoice_Page_Info:SetText("#{QXLS_220517_63}")
	elseif item_table_index == 38008309 then
		ValentineRoseTopList_FourChoice_Page_Info:SetText("#{MGCQ_250112_10}")
	else
		ValentineRoseTopList_FourChoice_Page_Info:SetText("#{MGCQ_220128_01}")
	end

end

function ValentineRoseTopList_FourChoice_OnActionItemClicked(index)

	if index == 1 or index == 2 then
		if m_ItemIndexSel1 == index then
			m_ItemIndexSel1 = -1
		else
			m_ItemIndexSel1 = index
		end		
	end
	if index == 3 or index == 4 then
		if m_ItemIndexSel2 == index then
			m_ItemIndexSel2 = -1
		else
			m_ItemIndexSel2 = index
		end		
	end
	
	for i = 1, 4 do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	if m_ItemIndexSel1 > 0 then
		g_ActionItem[m_ItemIndexSel1]:SetPushed(1)
		g_ActionMask[m_ItemIndexSel1]:Show()
	end
	if m_ItemIndexSel2 > 0 then
		g_ActionItem[m_ItemIndexSel2]:SetPushed(1)
		g_ActionMask[m_ItemIndexSel2]:Show()
	end
	
end

function ValentineRoseTopList_FourChoice_CloseClicked()
	this:Hide()
end

function ValentineRoseTopList_FourChoice_CleanUp()	

	for i = 1, 4 do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
	end
	
	if m_ItemBagePos >= 0 then
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,0)
	end
	
	m_ItemBagePos = -1
	m_ItemIndexSel1 = -1
	m_ItemIndexSel2 = -1

	this:Hide()
end

function ValentineRoseTopList_FourChoice_OnHidden()
	ValentineRoseTopList_FourChoice_CleanUp()
end

function ValentineRoseTopList_FourChoice_OKClicked()
	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if item_table_index <= 0 then
		return
	end
	
	if m_ItemIndexSel1 ~= 1 and m_ItemIndexSel1 ~= 2 then
		if item_table_index == 38005976 or item_table_index == 38006462 or item_table_index == 38007615 or item_table_index == 38008116
		or item_table_index == 38008814 
		then
			PushDebugMessage("#{QXLS_220517_93}")
		elseif item_table_index == 38008309 then
			PushDebugMessage("#{MGCQ_250112_11}")
		else
			PushDebugMessage("#{MGCQ_220128_06}")
		end
		return
	end
	
	if m_ItemIndexSel2 ~= 3 and m_ItemIndexSel2 ~= 4 then
		if item_table_index == 38005976 or item_table_index == 38006462 or item_table_index == 38007615 or item_table_index == 38008116 
		or item_table_index == 38008814 
		then
			PushDebugMessage("#{QXLS_220517_93}")
		elseif item_table_index == 38008309 then
			PushDebugMessage("#{MGCQ_250112_11}")
		else
			PushDebugMessage("#{MGCQ_220128_05}")
		end
		return
	end
	
	Clear_XSCRIPT()
		if m_ItemscriptId == 999827 then
			Set_XSCRIPT_Function_Name("OnFourChoiceTwo")
		else
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
		end
		if m_ItemscriptId ~= -1 then
			Set_XSCRIPT_ScriptID(m_ItemscriptId)
		else
			Set_XSCRIPT_ScriptID(892760)
		end
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel1)
		Set_XSCRIPT_Parameter(2, m_ItemIndexSel2)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	this:Hide()
end

function ValentineRoseTopList_FourChoice_Frame_On_ResetPos()
	if g_ValentineRoseTopList_FourChoice_Frame_UnifiedPosition ~= nil then
		ValentineRoseTopList_FourChoice_Frame_BK:SetProperty("UnifiedPosition", g_ValentineRoseTopList_FourChoice_Frame_UnifiedPosition)
	end
end