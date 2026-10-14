--2021双旦集五福
--三选一礼盒
--!!!reloadscript =ShuangDan_SelectMaterial

local g_UnifiedPosition = ""
local m_ItemIndexSel = 0
local m_ItemBagePos = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_LiHeId = 38003001
local g_PrizeItem = {	39923635, 39920396, 39920397 }

function ShuangDan_SelectMaterial_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
		
end

function ShuangDan_SelectMaterial_OnLoad()

	g_UnifiedPosition = ShuangDan_SelectMaterial_Frame:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = ShuangDan_SelectMaterial_Item1
	g_ActionItem[2] = ShuangDan_SelectMaterial_Item2
	g_ActionItem[3] = ShuangDan_SelectMaterial_Item3
	
	g_ActionMask[1] = ShuangDan_SelectMaterial_Item1_Mask
	g_ActionMask[2] = ShuangDan_SelectMaterial_Item2_Mask
	g_ActionMask[3] = ShuangDan_SelectMaterial_Item3_Mask
	
	g_ItemNameText[1] = ShuangDan_SelectMaterial_Text1
	g_ItemNameText[2] = ShuangDan_SelectMaterial_Text2
	g_ItemNameText[3] = ShuangDan_SelectMaterial_Text3
	
end										

function ShuangDan_SelectMaterial_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88884101 then		

		ShuangDan_SelectMaterial_CleanUp()
		m_ItemBagePos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(m_ItemBagePos,1)
		this:Show()
		ShuangDan_SelectMaterial_Update()
		return
		
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ShuangDan_SelectMaterial_Frame_On_ResetPos()
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

function ShuangDan_SelectMaterial_Update()

	if m_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(m_ItemBagePos)	
	if item_table_index == nil or item_table_index ~= g_LiHeId then
		return
	end
	
	for i = 1, 3 do
		local itemAction = DataPool:CreateActionItemForShow(g_PrizeItem[i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(g_PrizeItem[i])
		g_ItemNameText[i]:SetText(ScriptGlobal_Format("#{FHSX_211019_128}",strName))
		
	end
	
end

function ShuangDan_SelectMaterial_OnActionItemClicked(index)

	if m_ItemIndexSel == index then
		return
	end
	
	m_ItemIndexSel = index
	
	for i = 1, 3 do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	g_ActionItem[m_ItemIndexSel]:SetPushed(1)
	g_ActionMask[m_ItemIndexSel]:Show()
	
end

function ShuangDan_SelectMaterial_CloseClicked()
	this:Hide()
end

function ShuangDan_SelectMaterial_CleanUp()	
	
	for i = 1, 3 do	
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

function ShuangDan_SelectMaterial_OnHidden()
	ShuangDan_SelectMaterial_CleanUp()
end

function ShuangDan_SelectMaterial_OKClicked()
	
	if m_ItemBagePos < 0 then
		return
	end
	
	if m_ItemIndexSel <= 0 then
		PushDebugMessage("#{FHSX_211019_124}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickOne")
		Set_XSCRIPT_ScriptID(888841)
		Set_XSCRIPT_Parameter(0, m_ItemBagePos)
		Set_XSCRIPT_Parameter(1, m_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
	this:Hide()
		
end

function ShuangDan_SelectMaterial_Frame_On_ResetPos()
	if g_UnifiedPosition ~= nil then
		ShuangDan_SelectMaterial_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
	end
end