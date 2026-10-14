--2022Q3 Vip9和SVip9 坐骑二选一礼包选择界面
--!!!reloadscript =VIP9_DoubleChoice

local g_VIP9_DoubleChoice_Frame_UnifiedPosition = ""

local g_ItemIndexSel = 0
local g_UseItemPos = -1
local g_scriptId = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_Count = 2

function VIP9_DoubleChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("PLAYER_LEAVE_WORLD",false)		-- 离开场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
end

function VIP9_DoubleChoice_OnLoad()

    g_VIP9_DoubleChoice_Frame_UnifiedPosition = VIP9_DoubleChoice_Frame_BK:GetProperty("UnifiedPosition")
    

    g_ActionItem[1] = VIP9_DoubleChoice_Item1
	g_ActionItem[2] = VIP9_DoubleChoice_Item2
	
	g_ActionMask[1] = VIP9_DoubleChoice_Item1_Mask
	g_ActionMask[2] = VIP9_DoubleChoice_Item2_Mask
	
	g_ItemNameText[1] = VIP9_DoubleChoice_Item1_Conermark
	g_ItemNameText[2] = VIP9_DoubleChoice_Item2_Conermark
end										

function VIP9_DoubleChoice_OnEvent(event)
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
        VIP9_DoubleChoice_Frame_On_ResetPos()
        
        return
    end
    
    if (event == "PLAYER_LEAVE_WORLD") then
		VIP9_DoubleChoice_Close()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		VIP9_DoubleChoice_Close()
	end
    
    if event == "UI_COMMAND" and tonumber(arg0) == 99832001 then		

		VIP9_DoubleChoice_CleanUp()
		VIP9_DoubleChoice_Update()
		this:Show()	

		return
    end
    
    if event == "UI_COMMAND" and tonumber(arg0) == 99832002 then		

		VIP9_DoubleChoice_Close()

		return
	end
	
end

function VIP9_DoubleChoice_CleanUp()

    for i = 1, g_Count do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ActionMask[i]:Hide()
	end
	
	if g_UseItemPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_UseItemPos, 0)
	end
	
	g_UseItemPos = -1
	g_ItemIndexSel = 0
	VIP9_DoubleChoice_Text:SetText("")
	VIP9_DoubleChoice_Item1_Conermark:Hide()
	VIP9_DoubleChoice_Item2_Conermark:Hide()

end

function VIP9_DoubleChoice_Update()

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
	end

	g_scriptId = Get_XParam_INT(5)
	
	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	
	local useItemName = PlayerPackage:GetItemName(useItemId)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	VIP9_DoubleChoice_DragTitle:SetText(itemNameShow)
	
	VIP9_DoubleChoice_Info:SetText("#{BWDH_210908_19}")

end

function VIP9_DoubleChoice_Choose(index)

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

function VIP9_DoubleChoice_GetClick()
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


end

function VIP9_DoubleChoice_Close()
	VIP9_DoubleChoice_CleanUp()
	this:Hide()
end

function VIP9_DoubleChoice_Frame_On_ResetPos()
	if g_VIP9_DoubleChoice_Frame_UnifiedPosition == nil then
		return
	end
	
	VIP9_DoubleChoice_Frame_BK:SetProperty("UnifiedPosition", g_VIP9_DoubleChoice_Frame_UnifiedPosition)
end