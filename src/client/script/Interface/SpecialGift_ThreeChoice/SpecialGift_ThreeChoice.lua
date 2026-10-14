--对应珍兽幻玉 ：3选1

local g_SpecialGift_ThreeChoice_Frame_UnifiedPosition = ""
local m_ItemIndexSel = 0
local m_ItemBagePos = -1
local m_confirm = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_flag = {0,0,0}
local g_Count = 3

local g_SetItem = {	
	[38005609] = {38005598, 38005599, 38005600},
	[38005610] = {38005606, 38005607, 38005608},
}

local g_SetItem_str = {	
	[38005609] = {"#{VIPBS_211130_1}", "#{VIPBS_211130_21}", "#{VIPBS_211130_22}", "#{VIPBS_211130_23}"}, --烛引沧溟幻玉礼盒 幻玉：烛引沧溟
	[38005610] = {"#{VIPBS_211130_2}", "#{VIPBS_211130_24}", "#{VIPBS_211130_25}", "#{VIPBS_211130_26}"}, --昭明归墟幻玉礼盒 幻玉：昭明归墟
}

function SpecialGift_ThreeChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIPNIANDI_TURE")
end

function SpecialGift_ThreeChoice_OnLoad()

	g_SpecialGift_ThreeChoice_Frame_UnifiedPosition = SpecialGift_ThreeChoice_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SpecialGift_ThreeChoice_Item1
	g_ActionItem[2] = SpecialGift_ThreeChoice_Item2
	g_ActionItem[3] = SpecialGift_ThreeChoice_Item3
	
	g_ActionMask[1] = SpecialGift_ThreeChoice_Item1_Mask
	g_ActionMask[2] = SpecialGift_ThreeChoice_Item2_Mask
	g_ActionMask[3] = SpecialGift_ThreeChoice_Item3_Mask
	
	g_ItemNameText[1] = SpecialGift_ThreeChoice_Item1_Name
	g_ItemNameText[2] = SpecialGift_ThreeChoice_Item2_Name
	g_ItemNameText[3] = SpecialGift_ThreeChoice_Item3_Name

end										

function SpecialGift_ThreeChoice_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88885401 then

		if Get_XParam_STR(0) == "CLOSE_ThreeChoice" then --关闭界面
			if this:IsVisible() then
				SpecialGift_ThreeChoice_CleanUp()
			end
		else
			SpecialGift_ThreeChoice_CleanUp()
			m_ItemBagePos = Get_XParam_INT(0)
			LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
			this:Show()		
			SpecialGift_ThreeChoice_Update()
		end

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_ThreeChoice_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == m_ItemBagePos then
		this:Hide()
		return
	end

	if event == "VIPNIANDI_TURE" then
		if this:IsVisible() == false then
            return
        end
		SpecialGift_ThreeChoice_Confirm()
	end
end

function SpecialGift_ThreeChoice_Update()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if g_SetItem[item_table_index] == nil then
		return
	end
	
	for i = 1, g_Count do
		local itemAction = DataPool:CreateBindActionItemForShow(g_SetItem[item_table_index][i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		--local strName = PlayerPackage:GetItemName(g_SetItem[item_table_index][i])
		g_ItemNameText[i]:SetText(g_SetItem_str[item_table_index][i+1])
	end

	G_SpecialGift_ThreeChoice_DragTitle = SpecialGift_ThreeChoice_DragTitle
	G_SpecialGift_ThreeChoice_Info = SpecialGift_ThreeChoice_Info
	G_SpecialGift_ThreeChoice_Text 	 = SpecialGift_ThreeChoice_Text

	G_SpecialGift_ThreeChoice_Page_Conermark = {}

	G_SpecialGift_ThreeChoice_Page_Conermark[1] = SpecialGift_ThreeChoice_Item1_Conermark
	G_SpecialGift_ThreeChoice_Page_Conermark[2] = SpecialGift_ThreeChoice_Item2_Conermark
	G_SpecialGift_ThreeChoice_Page_Conermark[3] = SpecialGift_ThreeChoice_Item3_Conermark

	for i=1,g_Count do
		g_flag[i] = Get_XParam_INT(i)
	end

	G_SpecialGift_ThreeChoice_Text:Show()

	--已经拥有--
	for i = 1,g_Count do
		if g_flag[i] > 0 then
			G_SpecialGift_ThreeChoice_Page_Conermark[i]:Show()
		else
			G_SpecialGift_ThreeChoice_Page_Conermark[i]:Hide()
		end
	end
	
	if g_SetItem_str[item_table_index] == nil then
		return
	end

	G_SpecialGift_ThreeChoice_DragTitle:SetText(g_SetItem_str[item_table_index][1]) --界面标题
	G_SpecialGift_ThreeChoice_Info:SetText("#{VIPBS_211130_3}") --可从以下三种幻玉中选择其一，领取后幻玉礼盒会消失，如已激活该幻灵外观则会有对应显示。
	G_SpecialGift_ThreeChoice_Text:SetText("#{VIPBS_211130_20}") --#G小提示：已激活的幻灵外观会有对应显示。
	--G_SpecialGift_ThreeChoice_Text:Hide()

end

function SpecialGift_ThreeChoice_Choose(index)

	PushEvent("VIPNIANDI_CONFIRM", "close")

	if m_ItemIndexSel == index then
		m_ItemIndexSel = -1
		for i = 1, g_Count do	
			g_ActionItem[i]:SetPushed(0)
			g_ActionMask[i]:Hide()
		end
		return
	end
	
	m_ItemIndexSel = index
	
	for i = 1, g_Count do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	g_ActionItem[m_ItemIndexSel]:SetPushed(1)
	g_ActionMask[m_ItemIndexSel]:Show()
	
end

function SpecialGift_ThreeChoice_Close()

	PushEvent("VIPNIANDI_CONFIRM", "close")

	this:Hide()
end

function SpecialGift_ThreeChoice_CleanUp()

	PushEvent("VIPNIANDI_CONFIRM", "close")

	for i = 1, g_Count do	
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

function SpecialGift_ThreeChoice_OnHidden()
	SpecialGift_ThreeChoice_CleanUp()
end

function SpecialGift_ThreeChoice_GetClick()
	
	PushEvent("VIPNIANDI_CONFIRM", "close")

	if m_ItemBagePos < 0 then
		return
	end
	
	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{VIPBS_211130_6}") --请选择奖励后再进行领取。
		return
	end
	m_confirm = 1
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChoice")
		Set_XSCRIPT_ScriptID(888854)
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_Parameter(2, m_confirm)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	--this:Hide()
end

function SpecialGift_ThreeChoice_Frame_On_ResetPos()
	if g_SpecialGift_ThreeChoice_Frame_UnifiedPosition ~= nil then
		SpecialGift_ThreeChoice_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_ThreeChoice_Frame_UnifiedPosition)
	end
end

function SpecialGift_ThreeChoice_Confirm()
	
	if m_ItemBagePos < 0 then
		return
	end
	
	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{VIPBS_211130_6}") --请选择奖励后再进行领取。
		return
	end
	m_confirm = 0
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChoice")
		Set_XSCRIPT_ScriptID(888854)
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_Parameter(2, m_confirm)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	this:Hide()
end