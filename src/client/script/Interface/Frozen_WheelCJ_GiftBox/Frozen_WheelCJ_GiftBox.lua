--Frozen_WheelCJ_GiftBox

local g_Frozen_WheelCJ_GiftBox_Frame_UnifiedPosition = ""
local g_ItemIndexSel = 0
local g_UseItemPos = -1
local g_scriptId = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}
local g_DressItemText = {
	[1] = "#{BXZP_240911_89}",
	[2] = "#{BXZP_240911_90}"
}

local g_flag = {0,0}
local g_Count = 2


function Frozen_WheelCJ_GiftBox_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Frozen_WheelCJ_GiftBox_OnLoad()

	g_Frozen_WheelCJ_GiftBox_Frame_UnifiedPosition = Frozen_WheelCJ_GiftBoxFrame:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = Frozen_WheelCJ_GiftBoxGift1_Icon
	g_ActionItem[2] = Frozen_WheelCJ_GiftBoxGift2_Icon
	
	--g_ActionMask[1] = Frozen_WheelCJ_GiftBox_Item1_Mask
	--g_ActionMask[2] = Frozen_WheelCJ_GiftBox_Item2_Mask
	
	g_ItemNameText[1] = Frozen_WheelCJ_GiftBoxGift1_Text
	g_ItemNameText[2] = Frozen_WheelCJ_GiftBoxGift2_Text
end										

function Frozen_WheelCJ_GiftBox_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 99954901 then		

		Frozen_WheelCJ_GiftBox_CleanUp()	
		Frozen_WheelCJ_GiftBox_Update()
		this:Show()	

		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_WheelCJ_GiftBox_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_WheelCJ_GiftBoxOnClose()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 99954902 then	
		Frozen_WheelCJ_GiftBoxOnClose()
		return
	end
	
end

function Frozen_WheelCJ_GiftBox_Update()

	g_UseItemPos = Get_XParam_INT(0)
	if g_UseItemPos < 0 then
		return
	end
	
	LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)
	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	

	for i = 1, g_Count do
		local awardItemId = Get_XParam_INT(2 * i - 1)
		local awardItemNum = Get_XParam_INT(2 * i)
		local itemAction = DataPool:CreateActionItemForShow(awardItemId, awardItemNum)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
			
		local strName = g_DressItemText[i]
		g_ItemNameText[i]:SetText(strName)
	end

	g_scriptId = Get_XParam_INT(5)
	
end


function Frozen_WheelCJ_GiftBoxConfirm(index)
	if g_UseItemPos < 0 then
		return
	end
		
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnceFree")
			Set_XSCRIPT_ScriptID(g_scriptId)
			Set_XSCRIPT_Parameter(0, g_UseItemPos)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnceBuy")
			Set_XSCRIPT_ScriptID(g_scriptId)
			Set_XSCRIPT_Parameter(0, g_UseItemPos)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()		
	end
	
end


function Frozen_WheelCJ_GiftBoxOnClose()
	Frozen_WheelCJ_GiftBox_CleanUp()
	this:Hide()
end

function Frozen_WheelCJ_GiftBox_OnHidden()
	Frozen_WheelCJ_GiftBoxOnClose()
end

function Frozen_WheelCJ_GiftBox_CleanUp()	


	for i = 1, g_Count do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		--g_ActionMask[i]:Hide()
	end
	
	if g_UseItemPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_UseItemPos, 0)
	end
	
	g_UseItemPos = -1
	g_ItemIndexSel = 0

end

function Frozen_WheelCJ_GiftBoxPreview()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10128101)
		Set_XSCRIPT_Parameter(1, -1)
		Set_XSCRIPT_Parameter(2, -1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

function Frozen_WheelCJ_GiftBox_Frame_On_ResetPos()
	if g_Frozen_WheelCJ_GiftBox_Frame_UnifiedPosition == nil then
		return
	end
	
	Frozen_WheelCJ_GiftBoxFrame:SetProperty("UnifiedPosition", g_Frozen_WheelCJ_GiftBox_Frame_UnifiedPosition)
end

function Frozen_WheelCJ_GiftBox_Help_Clicked()
	PushEvent("CCSHOP_HELP", 224)
end