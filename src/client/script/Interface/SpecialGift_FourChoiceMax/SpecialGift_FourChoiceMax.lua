--物品 4选1

local g_SpecialGift_FourChoiceMax_Frame_UnifiedPosition = ""
local g_ItemIndexSel = 0
local g_UseItemPos = -1
local g_scriptId = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}
local g_maxnum=0
local g_Count = 4
local g_buyNum = 0

function SpecialGift_FourChoiceMax_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED",false)
end

function SpecialGift_FourChoiceMax_OnLoad()

	g_SpecialGift_FourChoiceMax_Frame_UnifiedPosition = SpecialGift_FourChoiceMax_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SpecialGift_FourChoiceMax_Page_Lace1Item
	g_ActionItem[2] = SpecialGift_FourChoiceMax_Page_Lace2Item 
	g_ActionItem[3] = SpecialGift_FourChoiceMax_Page_Lace3Item
	g_ActionItem[4] = SpecialGift_FourChoiceMax_Page_Lace4Item 
	
	g_ActionMask[1] = SpecialGift_FourChoiceMax_Page_Lace1Item_Mask
	g_ActionMask[2] = SpecialGift_FourChoiceMax_Page_Lace2Item_Mask 
	g_ActionMask[3] = SpecialGift_FourChoiceMax_Page_Lace3Item_Mask
	g_ActionMask[4] = SpecialGift_FourChoiceMax_Page_Lace4Item_Mask 
	
	g_ItemNameText[1] = SpecialGift_FourChoiceMax_Page_Lace1Item_Tip
	g_ItemNameText[2] = SpecialGift_FourChoiceMax_Page_Lace2Item_Tip 
	g_ItemNameText[3] = SpecialGift_FourChoiceMax_Page_Lace3Item_Tip 
	g_ItemNameText[4] = SpecialGift_FourChoiceMax_Page_Lace4Item_Tip 
end										

function SpecialGift_FourChoiceMax_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88899201 then		

		SpecialGift_FourChoiceMax_CleanUp()	
		SpecialGift_FourChoiceMax_Update()
		this:Show()	

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_FourChoiceMax_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		SpecialGift_FourChoiceMax_Close()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88899202 then	
		SpecialGift_FourChoiceMax_Close()
		return
	end
		
	if(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) or (event == "PACKAGE_ITEM_CHANGED" and this:IsVisible())  then
		if g_UseItemPos >= 0 then
			LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)			
		end
	end
	
end

function SpecialGift_FourChoiceMax_Update()

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
		
		local strName = DataPool:Lua_GetItemNameByIndex(awardItemId)
		g_ItemNameText[i]:SetText("#L"..strName)
	end

	g_scriptId = Get_XParam_INT(2*g_Count+1)
	g_maxnum   = Get_XParam_INT(2*g_Count+2)

	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	
	local useItemName = PlayerPackage:GetItemName(useItemId)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	SpecialGift_FourChoiceMax_DragTitle:SetText(itemNameShow)

	SpecialGift_FourChoiceMax_Page_Info:SetText("#{BWDH_210908_19}")
	 
	SpecialGift_FourChoiceMax_ItemNumberInput:SetText(SpecialGift_FourChoiceMax_GetItemMax())
end

function SpecialGift_FourChoiceMax_GetItemMax()
	local bagnum = PlayerPackage:GetBagItemNum(g_UseItemPos) 
	if bagnum < g_maxnum then
		return bagnum
	else 
		return g_maxnum
	end 
end

function SpecialGift_FourChoiceMax_OnMax()
	SpecialGift_FourChoiceMax_ItemNumberInput:SetText(SpecialGift_FourChoiceMax_GetItemMax())
end

function SpecialGift_FourChoiceMax_OnActionItemClicked(index)
 
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

function SpecialGift_FourChoiceMax_Close()
	SpecialGift_FourChoiceMax_CleanUp()
	this:Hide()
end

function SpecialGift_FourChoiceMax_CleanUp()	
 
	
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


function SpecialGift_FourChoiceMax_EditEnter()
	local num = tonumber(SpecialGift_FourChoiceMax_ItemNumberInput:GetText()) 
	if(num == nil or num < 1) then
		SpecialGift_FourChoiceMax_ItemNumberInput:SetText("1")
		num = 1
	end
	
	local maxnum = SpecialGift_FourChoiceMax_GetItemMax()
	if(num > maxnum) then
		SpecialGift_FourChoiceMax_ItemNumberInput:SetText(tostring(maxnum)) 

		num = maxnum
	end	
	g_buyNum = num
end

function SpecialGift_FourChoiceMax_GetClick()

	PushEvent("CLOSE_MINGZHENJIANGHU_CONFIRM")
	
	if g_UseItemPos < 0 then
		return
	end
	
	if g_ItemIndexSel <= 0 then
		PushDebugMessage("#{TSFCL_220210_59}")
		return
	end

	if g_buyNum <= 0 then
		PushDebugMessage("#{TSFCL_220210_60}")
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

function SpecialGift_FourChoiceMax_Frame_On_ResetPos()
	if g_SpecialGift_FourChoiceMax_Frame_UnifiedPosition == nil then
		return
	end
	
	SpecialGift_FourChoiceMax_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_FourChoiceMax_Frame_UnifiedPosition)
end

