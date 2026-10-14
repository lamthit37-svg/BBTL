--物品 2选1

local g_SpecialGift_DoubleChoice_Frame_UnifiedPosition = ""
local g_ItemIndexSel = 0
local g_UseItemPos = -1
local g_scriptId = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_flag = {0,0}
local g_Count = 2


function SpecialGift_DoubleChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function SpecialGift_DoubleChoice_OnLoad()

	g_SpecialGift_DoubleChoice_Frame_UnifiedPosition = SpecialGift_DoubleChoice_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SpecialGift_DoubleChoice_Item1
	g_ActionItem[2] = SpecialGift_DoubleChoice_Item2
	
	g_ActionMask[1] = SpecialGift_DoubleChoice_Item1_Mask
	g_ActionMask[2] = SpecialGift_DoubleChoice_Item2_Mask
	
	g_ItemNameText[1] = SpecialGift_DoubleChoice_Item1_Name
	g_ItemNameText[2] = SpecialGift_DoubleChoice_Item2_Name
end										

function SpecialGift_DoubleChoice_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88884801 then		

		SpecialGift_DoubleChoice_CleanUp()	
		SpecialGift_DoubleChoice_Update()
		this:Show()	

		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 99817501 then		

		SpecialGift_DoubleChoice_CleanUp()	
		SpecialGift_DoubleChoice_UpdateEX()
		this:Show()	

		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 99865401 then		

		SpecialGift_DoubleChoice_CleanUp()	
		SpecialGift_DoubleChoice_UpdateForQX()
		this:Show()	

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_DoubleChoice_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		SpecialGift_DoubleChoice_Close()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88884802 then	
		SpecialGift_DoubleChoice_Close()
		return
	end
	
end

function SpecialGift_DoubleChoice_Update()

	g_UseItemPos = Get_XParam_INT(0)
	if g_UseItemPos < 0 then
		return
	end
	
	LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)
	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	
	
	if useItemId == 38007059 or useItemId == 38006203 or useItemId == 38006696 or useItemId == 38007828 then
		for i = 1, g_Count do
			local awardItemId = Get_XParam_INT(2 * i - 1)
			local awardItemNum = Get_XParam_INT(2 * i)
			
			local itemAction = DataPool:CreateBindActionItemForShow(awardItemId, awardItemNum)
			if itemAction:GetID() ~= 0 then
				g_ActionItem[i]:SetActionItem(itemAction:GetID())
			end
			
			local strName = PlayerPackage:GetItemName(awardItemId)
			g_ItemNameText[i]:SetText("#L"..strName)
		end
		
	elseif useItemId == 38007821 or useItemId == 38007822 or useItemId == 38007823 or useItemId == 38007824 or useItemId == 38007825 then
		for i = 1, g_Count do
			local awardItemId = Get_XParam_INT(2 * i - 1)
			local awardItemNum = Get_XParam_INT(2 * i)
			
			local itemAction = DataPool:CreateBindActionItemForShow(awardItemId, awardItemNum)
			if itemAction:GetID() ~= 0 then
				g_ActionItem[i]:SetActionItem(itemAction:GetID())
			end
			
			local strName = PlayerPackage:GetEquipItemName(awardItemId)
			g_ItemNameText[i]:SetText("#L"..strName)
		end
		
	elseif useItemId == 38008302 or useItemId == 38008303 or useItemId == 38008304 or useItemId == 38008305 or useItemId == 38008306 then
		for i = 1, g_Count do
			local awardItemId = Get_XParam_INT(2 * i - 1)
			local awardItemNum = Get_XParam_INT(2 * i)
			
			local itemAction = DataPool:CreateBindActionItemForShow(awardItemId, awardItemNum)
			if itemAction:GetID() ~= 0 then
				g_ActionItem[i]:SetActionItem(itemAction:GetID())
			end
			
			local strName = PlayerPackage:GetEquipItemName(awardItemId)
			g_ItemNameText[i]:SetText("#L"..strName)
		end
	
	else
	
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
		
	end

	g_scriptId = Get_XParam_INT(5)
	
	local useItemName = PlayerPackage:GetItemName(useItemId)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	SpecialGift_DoubleChoice_DragTitle:SetText(itemNameShow)
	
	if useItemId == 38005657 then
		SpecialGift_DoubleChoice_Info:SetText("#{MDJH_211210_45}")
	else
		SpecialGift_DoubleChoice_Info:SetText("#{BWDH_210908_19}")
	end
	 

end


function SpecialGift_DoubleChoice_UpdateEX()

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

	g_scriptId = Get_XParam_INT(5)
	
	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	
	local useItemName = PlayerPackage:GetItemName(useItemId)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	SpecialGift_DoubleChoice_DragTitle:SetText(itemNameShow)
	
	g_flag[1] = Get_XParam_INT(6)
	g_flag[2] = Get_XParam_INT(7)
	if g_flag[1] == 1 then
		SpecialGift_DoubleChoice_Item1_Conermark:Show()
	else
		SpecialGift_DoubleChoice_Item1_Conermark:Hide()
	end
	
	if g_flag[2] == 1 then
		SpecialGift_DoubleChoice_Item2_Conermark:Show()
	else
		SpecialGift_DoubleChoice_Item2_Conermark:Hide()
	end
	
	SpecialGift_DoubleChoice_Text:SetText("#{JFZH_220615_19}")
	
	if useItemId == 38005657 then
		SpecialGift_DoubleChoice_Info:SetText("#{MDJH_211210_45}")
	else
		SpecialGift_DoubleChoice_Info:SetText("#{BWDH_210908_19}")
	end

end

function SpecialGift_DoubleChoice_UpdateForQX()

	g_UseItemPos = Get_XParam_INT(0)
	if g_UseItemPos < 0 then
		return
	end
	
	LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)
	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	
	
	for i = 1, g_Count do
		local awardItemId = Get_XParam_INT(2 * i - 1)
		local awardItemNum = Get_XParam_INT(2 * i)
			
		local itemAction = DataPool:CreateBindActionItemForShow(awardItemId, awardItemNum)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
			
		local strName = DataPool:Lua_GetItemNameByIndex(awardItemId)
		g_ItemNameText[i]:SetText("#L"..strName)
	end

	g_scriptId = Get_XParam_INT(5)
	
	local useItemName = DataPool:Lua_GetItemNameByIndex(useItemId)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	SpecialGift_DoubleChoice_DragTitle:SetText(itemNameShow)
	
	SpecialGift_DoubleChoice_Info:SetText("#{MDJH_211210_45}")	 

end

function SpecialGift_DoubleChoice_Choose(index)

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


function SpecialGift_DoubleChoice_Close()
	SpecialGift_DoubleChoice_CleanUp()
	this:Hide()
end


function SpecialGift_DoubleChoice_CleanUp()	

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
	SpecialGift_DoubleChoice_Text:SetText("")
	SpecialGift_DoubleChoice_Item2_Conermark:Hide()
	SpecialGift_DoubleChoice_Item1_Conermark:Hide()
end



function SpecialGift_DoubleChoice_GetClick()

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
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	--SpecialGift_DoubleChoice_Close()
end

function SpecialGift_DoubleChoice_Frame_On_ResetPos()
	if g_SpecialGift_DoubleChoice_Frame_UnifiedPosition == nil then
		return
	end
	
	SpecialGift_DoubleChoice_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_DoubleChoice_Frame_UnifiedPosition)
end

