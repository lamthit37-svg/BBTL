--物品 3选1

local g_SpecialGift_ThreeChoiceTongyong_Frame_UnifiedPosition = ""
local g_ItemIndexSel = 0
local g_UseItemPos = -1
local g_scriptId = -1

local g_ActionItem = {}
local g_ActionMask = {}
local g_ItemNameText = {}

local g_flag = {0,0,0,0}
local g_Count = 3


function SpecialGift_ThreeChoiceTongyong_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function SpecialGift_ThreeChoiceTongyong_OnLoad()

	g_SpecialGift_ThreeChoiceTongyong_Frame_UnifiedPosition = SpecialGift_ThreeChoiceTongyong_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SpecialGift_ThreeChoiceTongyong_Item1
	g_ActionItem[2] = SpecialGift_ThreeChoiceTongyong_Item2
	g_ActionItem[3] = SpecialGift_ThreeChoiceTongyong_Item3
	
	g_ActionMask[1] = SpecialGift_ThreeChoiceTongyong_Item1_Mask
	g_ActionMask[2] = SpecialGift_ThreeChoiceTongyong_Item2_Mask
	g_ActionMask[3] = SpecialGift_ThreeChoiceTongyong_Item3_Mask
	
	g_ItemNameText[1] = SpecialGift_ThreeChoiceTongyong_Item1_Name
	g_ItemNameText[2] = SpecialGift_ThreeChoiceTongyong_Item2_Name
	g_ItemNameText[3] = SpecialGift_ThreeChoiceTongyong_Item3_Name
end										

function SpecialGift_ThreeChoiceTongyong_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 88897801 then		

		SpecialGift_ThreeChoiceTongyong_CleanUp()	
		SpecialGift_ThreeChoiceTongyong_Update()
		this:Show()	

		return
	end
	if event == "UI_COMMAND" and tonumber(arg0) == 99803901 then

		SpecialGift_ThreeChoiceTongyong_CleanUp()
		SpecialGift_ThreeChoiceTongyong_Update()
		this:Show()

		return
	end
	if event == "UI_COMMAND" and tonumber(arg0) == 99801801 then	

		SpecialGift_ThreeChoiceTongyong_CleanUp()	
		SpecialGift_ThreeChoiceTongyong_ZhuZongZi()
		this:Show()	

		return
	end
	if (event == "UI_COMMAND" and tonumber(arg0) == 80031501) then
		SpecialGift_ThreeChoiceTongyong_CleanUp()
		SpecialGift_ThreeChoiceTongyong_Update()
		this:Show()

		return
	end
	if (event == "UI_COMMAND" and tonumber(arg0) == 99948101) then
		SpecialGift_ThreeChoiceTongyong_CleanUp()
		SpecialGift_ThreeChoiceTongyong_Update()
		this:Show()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_ThreeChoiceTongyong_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		SpecialGift_ThreeChoiceTongyong_Close()
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88897802 then	
		SpecialGift_ThreeChoiceTongyong_Close()
		return
	end
	if (event == "UI_COMMAND" and tonumber(arg0) == 80031502) then	
		SpecialGift_ThreeChoiceTongyong_Close()
		return
	end
	if (event == "UI_COMMAND" and tonumber(arg0) == 99948102) then	
		SpecialGift_ThreeChoiceTongyong_Close()
		return
	end
	
end

function SpecialGift_ThreeChoiceTongyong_ZhuZongZi()
	
	SpecialGift_ThreeChoiceTongyong_GetButton2:Show()
	SpecialGift_ThreeChoiceTongyong_GetButton:Hide()
	SpecialGift_ThreeChoiceTongyong_GetButton2:SetText("#{ZZZH_220418_107}")
	if Get_XParam_INT(0) == 0 then
		SpecialGift_ThreeChoiceTongyong_Close()
		return 
	end
	
	g_UseItemPos = Get_XParam_INT(1)
	if g_UseItemPos < 0 then
		return
	end	
		
	if IsWindowShow("Zhuzongzi") then
		CloseWindow("Zhuzongzi", true);
	end

	LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)

	g_ActionItem[1]:SetProperty("BackImage", "set:Buff32 image:Buff32_4");
	g_ItemNameText[1]:SetText("#L".."#{ZZZH_220418_79}")
	g_ActionItem[2]:SetProperty("BackImage", "set:Buff32 image:Buff32_5");
	g_ItemNameText[2]:SetText("#L".."#{ZZZH_220418_80}")
	g_ActionItem[3]:SetProperty("BackImage", "set:Buff32 image:Buff32_3");
	g_ItemNameText[3]:SetText("#L".."#{ZZZH_220418_81}")

	SpecialGift_ThreeChoiceTongyong_DragTitle:SetText("#{ZZZH_220418_77}")

	SpecialGift_ThreeChoiceTongyong_Info:SetText("#{ZZZH_220418_78}")

	SpecialGift_ThreeChoiceTongyong_Text:SetText("")

	g_scriptId = 998018
end

function SpecialGift_ThreeChoiceTongyong_Update()

	SpecialGift_ThreeChoiceTongyong_GetButton2:Hide()
	SpecialGift_ThreeChoiceTongyong_GetButton:Show()
	g_UseItemPos = Get_XParam_INT(0)
	if g_UseItemPos < 0 then
		return
	end
	
	LifeAbility:Lock_Packet_Item(g_UseItemPos, 1)
	
	for i = 1, g_Count do
		local awardItemId = Get_XParam_INT(g_Count * (i-1) + 1 )
		local awardItemNum = Get_XParam_INT(g_Count * (i-1) + 2 )
		local awardItemBind = Get_XParam_INT(g_Count * (i-1) + 3 )
		local itemAction
		if awardItemBind == 1 then
			itemAction = DataPool:CreateBindActionItemForShow(awardItemId, awardItemNum)
		else
			itemAction = DataPool:CreateActionItemForShow(awardItemId, awardItemNum)
		end 
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		--local strName = PlayerPackage:GetItemName(awardItemId)
		local strName = DataPool:Lua_GetItemNameByIndex(awardItemId)
		g_ItemNameText[i]:SetText("#L"..strName)
	end

	g_scriptId = Get_XParam_INT(3*g_Count+1)
	
	local useItemId = PlayerPackage:GetItemTableIndex(g_UseItemPos)	
	--local useItemName = PlayerPackage:GetItemName(useItemId)
	local useItemName = DataPool:Lua_GetItemNameByIndex(useItemId)
	local itemNameShow = ScriptGlobal_Format("#{BWDH_210908_13}", useItemName)
	SpecialGift_ThreeChoiceTongyong_DragTitle:SetText(itemNameShow)

	SpecialGift_ThreeChoiceTongyong_Info:SetText("#{BWDH_210908_19}")
	 

end


function SpecialGift_ThreeChoiceTongyong_Choose(index)

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


function SpecialGift_ThreeChoiceTongyong_Close()
	SpecialGift_ThreeChoiceTongyong_CleanUp()
	this:Hide()
end


function SpecialGift_ThreeChoiceTongyong_CleanUp()	

	PushEvent("CLOSE_MINGZHENJIANGHU_CONFIRM")
	
	for i = 1, g_Count do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ActionItem[i]:SetProperty("Image", "");
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
	end
	
	if g_UseItemPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_UseItemPos, 0)
	end
	
	g_UseItemPos = -1
	g_ItemIndexSel = 0
	SpecialGift_ThreeChoiceTongyong_GetButton2:Hide()
	SpecialGift_ThreeChoiceTongyong_GetButton:Show()
end



function SpecialGift_ThreeChoiceTongyong_GetClick()

	PushEvent("CLOSE_MINGZHENJIANGHU_CONFIRM") 
	if g_UseItemPos < 0 then
		return
	end 
	if g_ItemIndexSel <= 0 then
		--请选择其中一种物品。
		PushDebugMessage("#{ETJHD_220421_17}")
		return
	end 
 

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientActivateOnce")
		Set_XSCRIPT_ScriptID(g_scriptId)
		Set_XSCRIPT_Parameter(0, g_UseItemPos)
		Set_XSCRIPT_Parameter(1, g_ItemIndexSel)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	--SpecialGift_ThreeChoiceTongyong_Close()
end

function SpecialGift_ThreeChoiceTongyong_Frame_On_ResetPos()
	if g_SpecialGift_ThreeChoiceTongyong_Frame_UnifiedPosition == nil then
		return
	end
	
	SpecialGift_ThreeChoiceTongyong_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_ThreeChoiceTongyong_Frame_UnifiedPosition)
end

