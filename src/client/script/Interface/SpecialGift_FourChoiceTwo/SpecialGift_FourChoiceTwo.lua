-- 4选2

local g_SpecialGift_FourChoiceTwo_Frame_UnifiedPosition = ""

local g_FourChoiceTwo_ItemBagePos = -1
local g_FourChoiceTwo_ScriptId = -1

local g_FourChoiceTwo_ActionItem = {}
local g_FourChoiceTwo_ActionMask = {}
local g_FourChoiceTwo_ItemNameText = {}
local g_FourChoiceTwo_Conermark = {}

local g_FourChoiceTwoGiftBox_Four_CurNeedNum = 2
local g_FourChoiceTwoGiftBox_Four_CurSelNum = 0
local g_FourChoiceTwoGiftBox_Four_CurSelState = {}

local g_flag = {0,0,0,0}
local g_Count = 4

local g_FourChoiceTwo_SelectItemIndex={};
local g_FourChoiceTwo_SelectItemNum={1,1,10,1};
function SpecialGift_FourChoiceTwo_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function SpecialGift_FourChoiceTwo_OnLoad()

	g_SpecialGift_FourChoiceTwo_Frame_UnifiedPosition = SpecialGift_FourChoiceTwo_Frame_BK:GetProperty("UnifiedPosition")
	
	g_FourChoiceTwo_ActionItem[1] = SpecialGift_FourChoiceTwo_Page_Lace1Item
	g_FourChoiceTwo_ActionItem[2] = SpecialGift_FourChoiceTwo_Page_Lace2Item
	g_FourChoiceTwo_ActionItem[3] = SpecialGift_FourChoiceTwo_Page_Lace3Item
	g_FourChoiceTwo_ActionItem[4] = SpecialGift_FourChoiceTwo_Page_Lace4Item
	
	g_FourChoiceTwo_ActionMask[1] = SpecialGift_FourChoiceTwo_Page_Lace1Item_Mask
	g_FourChoiceTwo_ActionMask[2] = SpecialGift_FourChoiceTwo_Page_Lace2Item_Mask
	g_FourChoiceTwo_ActionMask[3] = SpecialGift_FourChoiceTwo_Page_Lace3Item_Mask
	g_FourChoiceTwo_ActionMask[4] = SpecialGift_FourChoiceTwo_Page_Lace4Item_Mask
	
	g_FourChoiceTwo_Conermark[1] = SpecialGift_FourChoiceTwo_Page_Lace1Item_Conermark
	g_FourChoiceTwo_Conermark[2] = SpecialGift_FourChoiceTwo_Page_Lace2Item_Conermark
	g_FourChoiceTwo_Conermark[3] = SpecialGift_FourChoiceTwo_Page_Lace3Item_Conermark
	g_FourChoiceTwo_Conermark[4] = SpecialGift_FourChoiceTwo_Page_Lace4Item_Conermark
	
	g_FourChoiceTwo_ItemNameText[1] = SpecialGift_FourChoiceTwo_Page_Lace1Item_Tip
	g_FourChoiceTwo_ItemNameText[2] = SpecialGift_FourChoiceTwo_Page_Lace2Item_Tip
	g_FourChoiceTwo_ItemNameText[3] = SpecialGift_FourChoiceTwo_Page_Lace3Item_Tip
	g_FourChoiceTwo_ItemNameText[4] = SpecialGift_FourChoiceTwo_Page_Lace4Item_Tip
end										

function SpecialGift_FourChoiceTwo_OnEvent(event)

	if event == "UI_COMMAND" and (tonumber(arg0) == 99811102) then		

		SpecialGift_FourChoiceTwo_CleanUp()
		-- 脚本号
		g_FourChoiceTwo_ScriptId = Get_XParam_INT(0)
		if g_FourChoiceTwo_ScriptId <= 0 then
			SpecialGift_FourChoiceTwo_CleanUp()	
			return
		end
		
		-- 道具位置
		g_FourChoiceTwo_ItemBagePos = Get_XParam_INT(1)
		LifeAbility:Lock_Packet_Item(g_FourChoiceTwo_ItemBagePos,1)
		--可选道具
		for i=1, 4 do
			g_FourChoiceTwo_SelectItemIndex[i] = Get_XParam_INT(i+1)
		end
		this:Show()		
		SpecialGift_FourChoiceTwo_Update()

		return
	end
	

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_FourChoiceTwo_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == g_FourChoiceTwo_ItemBagePos then
		this:Hide()
		return
	end
	
end

function SpecialGift_FourChoiceTwo_Update()

	if g_FourChoiceTwo_ItemBagePos < 0 then
		return
	end
	
	g_FourChoiceTwoGiftBox_Four_CurSelNum = 0
	g_FourChoiceTwoGiftBox_Four_CurSelState = {0,0,0,0}
	
	local item_table_index = PlayerPackage:GetItemTableIndex(g_FourChoiceTwo_ItemBagePos)	
	if item_table_index <= 0 then
		return
	end

	for i = 1, 4 do
		local itemAction 
		if g_FourChoiceTwo_ScriptId == 998288 then
			--重回三城礼包的特写
			itemAction = DataPool:CreateBindActionItemForShow(g_FourChoiceTwo_SelectItemIndex[i], g_FourChoiceTwo_SelectItemNum[i])
		elseif g_FourChoiceTwo_ScriptId == 998654 then
			itemAction = DataPool:CreateBindActionItemForShow(g_FourChoiceTwo_SelectItemIndex[i],1)
		else
			itemAction = DataPool:CreateActionItemForShow(g_FourChoiceTwo_SelectItemIndex[i],1)
		end 
	
		if itemAction:GetID() ~= 0 then
			g_FourChoiceTwo_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(g_FourChoiceTwo_SelectItemIndex[i])
		g_FourChoiceTwo_ItemNameText[i]:SetText("#L"..strName)
	end

	for i=1, 4 do
		g_FourChoiceTwo_ActionItem[i]:SetPushed(0)
		g_FourChoiceTwo_ActionMask[i]:Hide()
	end

	local szName = DataPool:Lua_GetItemNameByIndex(item_table_index)
	local szNameShow = ScriptGlobal_Format("#{MGCQ_220128_09}", szName)
	SpecialGift_FourChoiceTwo_DragTitle:SetText(szNameShow)
	
	if (g_FourChoiceTwo_ScriptId == 998288) then 
		SpecialGift_FourChoiceTwo_Page_Info:SetText("#{CHSC_20220817_12}")
	else 
		SpecialGift_FourChoiceTwo_Page_Info:SetText("#{QXLS_220517_65}")
	end
	
	SpecialGift_FourChoiceTwo_Text:Hide()

end

function SpecialGift_FourChoiceTwo_OnActionItemClicked(index)

	if g_FourChoiceTwoGiftBox_Four_CurNeedNum == -1 or g_FourChoiceTwoGiftBox_Four_CurSelNum == -1 then
		PushDebugMessage("#H礼包数据错误")
		return
	end
	if g_FourChoiceTwoGiftBox_Four_CurSelState[index] == 0 then
		if g_FourChoiceTwoGiftBox_Four_CurSelNum >= g_FourChoiceTwoGiftBox_Four_CurNeedNum then
			PushDebugMessage("#H当前选择数量达到上限，请先取消一个选择。")
			return
		else
			g_FourChoiceTwo_ActionItem[index]:SetPushed(0)
			g_FourChoiceTwo_ActionMask[index]:Show()
			g_FourChoiceTwoGiftBox_Four_CurSelNum = g_FourChoiceTwoGiftBox_Four_CurSelNum + 1
			g_FourChoiceTwoGiftBox_Four_CurSelState[index] = 1
		end
	else
		g_FourChoiceTwo_ActionItem[index]:SetPushed(0)
		g_FourChoiceTwo_ActionMask[index]:Hide()
		g_FourChoiceTwoGiftBox_Four_CurSelNum = g_FourChoiceTwoGiftBox_Four_CurSelNum - 1
		g_FourChoiceTwoGiftBox_Four_CurSelState[index] = 0
	end

end

function SpecialGift_FourChoiceTwo_CleanUp()	
	
	for i = 1, 4 do	
		g_FourChoiceTwo_ActionItem[i]:SetActionItem(-1)
		g_FourChoiceTwo_ItemNameText[i]:SetText("")
		g_FourChoiceTwo_ActionMask[i]:Hide()
		g_FourChoiceTwo_Conermark[i]:Hide()
	end
	
	if g_FourChoiceTwo_ItemBagePos >= 0 then
		LifeAbility:Lock_Packet_Item(g_FourChoiceTwo_ItemBagePos,0)
	end
	
	g_FourChoiceTwo_ScriptId = -1
	g_FourChoiceTwo_ItemBagePos = -1
	
	this:Hide()
end

function SpecialGift_FourChoiceTwo_OnHidden()

	SpecialGift_FourChoiceTwo_CleanUp()
	
	this:Hide()
	
end

function SpecialGift_FourChoiceTwo_OKClicked()
	
	if g_FourChoiceTwo_ItemBagePos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(g_FourChoiceTwo_ItemBagePos)	
	if item_table_index <= 0 then
		return
	end
	
	if g_FourChoiceTwo_ScriptId <= 0 then
		return
	end
	
		
	if g_FourChoiceTwoGiftBox_Four_CurSelNum < g_FourChoiceTwoGiftBox_Four_CurNeedNum then
		if  (g_FourChoiceTwo_ScriptId == 998288) then 
			PushDebugMessage("#{CHSC_20220817_13}")
		else 
			PushDebugMessage("#{QXLS_220517_68}")
		end
		return
	end
	local select1 = 0
	local select2 = 0
	
	for i= 1,4 do
		if (g_FourChoiceTwoGiftBox_Four_CurSelState[i] ~= 0) then
			if select1 == 0 then
				select1 = i	
			else
				select2 = i
			end
		end
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnFourChoiceTwo")
		Set_XSCRIPT_ScriptID(g_FourChoiceTwo_ScriptId)
		Set_XSCRIPT_Parameter(0, g_FourChoiceTwo_ItemBagePos)
		Set_XSCRIPT_Parameter(1, select1)
		Set_XSCRIPT_Parameter(2, select2)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	this:Hide()
end

function SpecialGift_FourChoiceTwo_Frame_On_ResetPos()

	if g_SpecialGift_FourChoiceTwo_Frame_UnifiedPosition ~= nil then
		SpecialGift_FourChoiceTwo_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_FourChoiceTwo_Frame_UnifiedPosition)
	end
	
end