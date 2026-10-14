--物品 2选1

local g_SpecialGift_DoubleChoiceMax_Frame_UnifiedPosition = ""
local g_ItemIndexSel = 0
local g_UseItemPos = -1
local g_scriptId = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}
local g_maxnum=0
local g_Count = 2
local g_buyNum = 0

function SpecialGift_DoubleChoiceMax_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED",false)
end

function SpecialGift_DoubleChoiceMax_OnLoad()

	g_SpecialGift_DoubleChoiceMax_Frame_UnifiedPosition = SpecialGift_DoubleChoiceMax_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SpecialGift_DoubleChoiceMax_Item1
	g_ActionItem[2] = SpecialGift_DoubleChoiceMax_Item2 
	
	g_ActionMask[1] = SpecialGift_DoubleChoiceMax_Item1_Mask
	g_ActionMask[2] = SpecialGift_DoubleChoiceMax_Item2_Mask 
	
	g_ItemNameText[1] = SpecialGift_DoubleChoiceMax_Item1_Name
	g_ItemNameText[2] = SpecialGift_DoubleChoiceMax_Item2_Name 
end										

function SpecialGift_DoubleChoiceMax_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88897901 then		

		SpecialGift_DoubleChoiceMax_CleanUp()	
		SpecialGift_DoubleChoiceMax_Update()
		this:Show()	

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_DoubleChoiceMax_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		SpecialGift_DoubleChoiceMax_Close()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88897902 then	
		SpecialGift_DoubleChoiceMax_Close()
		return
	end
		
	if(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) or (event == "PACKAGE_ITEM_CHANGED" and this:IsVisible())  then
		if g_UseItemPos >= 0 then
			LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)			
		end
	end
	
end

function SpecialGift_DoubleChoiceMax_Update()

	g_UseItemPos = Get_XParam_INT(0)
	if g_UseItemPos < 0 then
		return
	end
	
	LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)
	
	for i = 1, g_Count do
		local awardItemId = Get_XParam_INT(2 * i - 1)
		local awardItemNum = Get_XParam_INT(2 * i)
		
		local itemAction = DataPool:CreateActionItemForShow(awardItemId, awardItemNum)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = PlayerPackage:GetItemName(awardItemId)
		g_ItemNameText[i]:SetText("#L"..strName)
	end

	g_scriptId = Get_XParam_INT(2*g_Count+1)
	g_maxnum   = Get_XParam_INT(2*g_Count+2)

	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	
	local useItemName = PlayerPackage:GetItemName(useItemId)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	SpecialGift_DoubleChoiceMax_DragTitle:SetText(itemNameShow)

	SpecialGift_DoubleChoiceMax_Info:SetText("#{BWDH_210908_19}")
	 
	SpecialGift_DoubleChoiceMax_ItemNumberInput:SetText(SpecialGift_DoubleChoiceMax_GetItemMax())
end

function SpecialGift_DoubleChoiceMax_GetItemMax()
	local bagnum = PlayerPackage:GetBagItemNum(g_UseItemPos) 
	if bagnum < g_maxnum then
		return bagnum
	else 
		return g_maxnum
	end 
end

function SpecialGift_DoubleChoiceMax_OnMax()
	SpecialGift_DoubleChoiceMax_ItemNumberInput:SetText(SpecialGift_DoubleChoiceMax_GetItemMax())
end

function SpecialGift_DoubleChoiceMax_Choose(index)

	PushEvent("CLOSE_MINGZHENJIANGHU_CONFIRM")

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

function SpecialGift_DoubleChoiceMax_Close()
	SpecialGift_DoubleChoiceMax_CleanUp()
	this:Hide()
end

function SpecialGift_DoubleChoiceMax_CleanUp()	

	PushEvent("CLOSE_MINGZHENJIANGHU_CONFIRM")
	
	for i = 1, g_Count do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
	end
	
	if g_UseItemPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_UseItemPos, 0)
	end
	
	g_UseItemPos = -1
	g_ItemIndexSel = 0
end


function SpecialGift_DoubleChoiceMax_EditEnter()
	local num = tonumber(SpecialGift_DoubleChoiceMax_ItemNumberInput:GetText()) 
	if(num == nil or num < 1) then
		SpecialGift_DoubleChoiceMax_ItemNumberInput:SetText("1")
		num = 1
	end
	
	local maxnum = SpecialGift_DoubleChoiceMax_GetItemMax()
	if(num > maxnum) then
		SpecialGift_DoubleChoiceMax_ItemNumberInput:SetText(tostring(maxnum)) 

		num = maxnum
	end	
	g_buyNum = num
end

function SpecialGift_DoubleChoiceMax_GetClick()

	PushEvent("CLOSE_MINGZHENJIANGHU_CONFIRM")
	
	if g_UseItemPos < 0 then
		return
	end
	
	if g_ItemIndexSel <= 0 then
		PushDebugMessage("#{FHSX_211019_124}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientActivateOnce")
		Set_XSCRIPT_ScriptID(g_scriptId)
		Set_XSCRIPT_Parameter(0, g_UseItemPos)
		Set_XSCRIPT_Parameter(1, g_ItemIndexSel)
		Set_XSCRIPT_Parameter(2, g_buyNum)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
 
end

function SpecialGift_DoubleChoiceMax_Frame_On_ResetPos()
	if g_SpecialGift_DoubleChoiceMax_Frame_UnifiedPosition == nil then
		return
	end
	
	SpecialGift_DoubleChoiceMax_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_DoubleChoiceMax_Frame_UnifiedPosition)
end

