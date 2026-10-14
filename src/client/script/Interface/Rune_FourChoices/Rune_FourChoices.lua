--!!!reloadscript =Rune_FourChoices

local g_Rune_FourChoices_Frame_UnifiedPosition = ""
local m_ItemIndexSel = 0
local m_ItemBagePos = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_SetItem = {	

	[38004679] = {38004517, 38004518, 38004519, 38004520},
	[38004680] = {38004521, 38004522, 38004523, 38004524},
	[38004681] = {38004525, 38004526, 38004527, 38004528},
	[38004682] = {38004529, 38004530, 38004531, 38004532},
	[38004683] = {38004535, 38004536, 38004537, 38004538},
	[38004684] = {38004539, 38004540, 38004541, 38004542},
	[38004685] = {38004543, 38004544, 38004545, 38004546},
	[38004686] = {38004547, 38004548, 38004549, 38004550},
	[38004687] = {38004553, 38004554, 38004555, 38004556},
	[38004688] = {38004557, 38004558, 38004559, 38004560},
	[38004689] = {38004561, 38004562, 38004563, 38004564},
	[38004690] = {38004565, 38004566, 38004567, 38004568},
	[38004691] = {38004569, 38004570, 38004571, 38004572},
	[38004692] = {38004573, 38004574, 38004575, 38004576},
	[38004716] = {38004228, 38004229, 38004230, 38004231},
	[38004717] = {38004232, 38004233, 38004234, 38004235},
	[38004718] = {38004242, 38004243, 38004244, 38004245},
	[38004819] = {38004268, 38004269, 38004270, 38004271},
	[38004848] = {38004286, 38004287, 38004288, 38004289},
	[38004879] = {38004282, 38004283, 38004284, 38004285}, --准星
	[38005074] = {38004264, 38004265, 38004266, 38004267},
	[38005089] = {38004268, 38004269, 38004270, 38004271},
	[38005311] = {38004256, 38004257, 38004258, 38004259},
	[38005383] = {38004278, 38004279, 38004280, 38004281}, -- 灵运残印集录
	[38005384] = {38004308, 38004309, 38004310, 38004311}, -- 誓江残印集录
	[38008153] = {38004274, 38004275, 38004276, 38004277}, -- 诛心残印集录
}


function Rune_FourChoices_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Rune_FourChoices_OnLoad()

	g_Rune_FourChoices_Frame_UnifiedPosition = Rune_FourChoices_Frame:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = Rune_FourChoices_Page_Lace1Item
	g_ActionItem[2] = Rune_FourChoices_Page_Lace2Item
	g_ActionItem[3] = Rune_FourChoices_Page_Lace3Item
	g_ActionItem[4] = Rune_FourChoices_Page_Lace4Item
	
	g_ActionMask[1] = Rune_FourChoices_Page_Lace1Item_Mask
	g_ActionMask[2] = Rune_FourChoices_Page_Lace2Item_Mask
	g_ActionMask[3] = Rune_FourChoices_Page_Lace3Item_Mask
	g_ActionMask[4] = Rune_FourChoices_Page_Lace4Item_Mask
	
	g_ItemNameText[1] = Rune_FourChoices_Page_Lace1Item_Tip
	g_ItemNameText[2] = Rune_FourChoices_Page_Lace2Item_Tip
	g_ItemNameText[3] = Rune_FourChoices_Page_Lace3Item_Tip
	g_ItemNameText[4] = Rune_FourChoices_Page_Lace4Item_Tip
end										

function Rune_FourChoices_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88855901 then		

		Rune_FourChoices_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()		
		Rune_FourChoices_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Rune_FourChoices_Frame_On_ResetPos()
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

function Rune_FourChoices_Update()

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
end

function Rune_FourChoices_OnActionItemClicked(index)

	if m_ItemIndexSel == index then
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

function Rune_FourChoices_CloseClicked()
	this:Hide()
end

function Rune_FourChoices_CleanUp()	
	
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
end

function Rune_FourChoices_OnHidden()
	Rune_FourChoices_CleanUp()
end

function Rune_FourChoices_OKClicked()
	
	if m_ItemBagePos < 0 then
		return
	end
	
	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{XZJC_200309_358}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickOne")
		Set_XSCRIPT_ScriptID(888559)
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	this:Hide()
end

function Rune_FourChoices_Frame_On_ResetPos()
	if g_Rune_FourChoices_Frame_UnifiedPosition ~= nil then
		Rune_FourChoices_Frame:SetProperty("UnifiedPosition", g_Rune_FourChoices_Frame_UnifiedPosition)
	end
end