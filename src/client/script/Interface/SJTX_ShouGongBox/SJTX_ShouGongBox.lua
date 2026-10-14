--比武商店 三选一礼盒

local g_UnifiedPosition = ""
local g_ItemIndexSel = 0
local g_ItemBagePos = -1
local g_Count = 3

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_LiHeId = 38005650
local g_PrizeItem = { 20500003, 20501003, 20502003 }


function SJTX_ShouGongBox_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function SJTX_ShouGongBox_OnLoad()

	g_UnifiedPosition = SJTX_ShouGongBox_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SJTX_ShouGongBox_Item1
	g_ActionItem[2] = SJTX_ShouGongBox_Item2
	g_ActionItem[3] = SJTX_ShouGongBox_Item3
	
	g_ActionMask[1] = SJTX_ShouGongBox_Item1_Mask
	g_ActionMask[2] = SJTX_ShouGongBox_Item2_Mask
	g_ActionMask[3] = SJTX_ShouGongBox_Item3_Mask
	
	g_ItemNameText[1] = SJTX_ShouGongBox_Item1_Name
	g_ItemNameText[2] = SJTX_ShouGongBox_Item2_Name
	g_ItemNameText[3] = SJTX_ShouGongBox_Item3_Name

end										

function SJTX_ShouGongBox_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88887801 then

		SJTX_ShouGongBox_CleanUp()
		SJTX_ShouGongBox_Open()		

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SJTX_ShouGongBox_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		SJTX_ShouGongBox_Close()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == g_ItemBagePos then
		SJTX_ShouGongBox_Close()
		return
	end

end

function SJTX_ShouGongBox_Open()

	g_ItemBagePos = Get_XParam_INT(0)
	if g_ItemBagePos < 0 then
		return
	end
	
	LifeAbility:Lock_Packet_Item(g_ItemBagePos, 1)
	
	local item_table_index = PlayerPackage:GetItemTableIndex(g_ItemBagePos)	
	if item_table_index == nil or item_table_index ~= g_LiHeId then
		return
	end
	
	for i = 1, g_Count do
		local itemAction = DataPool:CreateBindActionItemForShow(g_PrizeItem[i], 1)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = PlayerPackage:GetItemName(g_PrizeItem[i])
		g_ItemNameText[i]:SetText("#L"..strName)
	end
	
	local useItemName = PlayerPackage:GetItemName(item_table_index)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	SJTX_ShouGongBox_DragTitle:SetText(itemNameShow) --界面标题
	
	SJTX_ShouGongBox_Info:SetText("#{BWDH_210908_19}") --请从以下奖励中选择其中一种进行领取：
	
	this:Show()

end


function SJTX_ShouGongBox_Choose(index)

	if g_ItemIndexSel == index then
		g_ItemIndexSel = -1
		for i = 1, g_Count do	
			g_ActionItem[i]:SetPushed(0)
			g_ActionMask[i]:Hide()
		end
		return
	end
	
	g_ItemIndexSel = index
	
	for i = 1, g_Count do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	
	g_ActionItem[g_ItemIndexSel]:SetPushed(1)
	g_ActionMask[g_ItemIndexSel]:Show()
	
end

function SJTX_ShouGongBox_Close()

	SJTX_ShouGongBox_CleanUp()	
	this:Hide()
end

function SJTX_ShouGongBox_CleanUp()

	for i = 1, g_Count do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
	end
	
	if g_ItemBagePos >= 0 then
		LifeAbility:Lock_Packet_Item(g_ItemBagePos,0)
	end
	
	g_ItemBagePos = -1
	g_ItemIndexSel = 0
end

function SJTX_ShouGongBox_OnHidden()
	SJTX_ShouGongBox_CleanUp()
end

function SJTX_ShouGongBox_GetClick()

	if g_ItemBagePos < 0 then
		return
	end
	
	if g_ItemIndexSel <= 0 then
		PushDebugMessage("#{FHSX_211019_124}") --请选择1个材料。
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PickOne")
		Set_XSCRIPT_ScriptID(888878)
		Set_XSCRIPT_Parameter(0, g_ItemBagePos)
		Set_XSCRIPT_Parameter(1, g_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	SJTX_ShouGongBox_Close()
end


function SJTX_ShouGongBox_Frame_On_ResetPos()
	if g_UnifiedPosition ~= nil then
		SJTX_ShouGongBox_Frame_BK:SetProperty("UnifiedPosition", g_UnifiedPosition)
	end
end

