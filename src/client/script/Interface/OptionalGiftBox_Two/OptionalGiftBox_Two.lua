-- OptionalGiftBox_Two.lua
-- 配表通用2选礼包

--变量
local g_OptionalGiftBox_Two_Frame_UnifiedPosition = ""
local g_OptionalGiftBox_Two_CurSelState = {}
local g_OptionalGiftBox_Two_CurBagPos = -1
local g_OptionalGiftBox_Two_CurSelNum = -1
local g_OptionalGiftBox_Two_CurNeedNum = -1

--UI
local g_OptionalGiftBox_Two_UI_ActionItem = {}
local g_OptionalGiftBox_Two_UI_ActionChosenMask = {}
local g_OptionalGiftBox_Two_UI_ActionCornerMask = {}
local g_OptionalGiftBox_Two_UI_ItemName = {}
local g_OptionalGiftBox_Two_UI_DragTitle = ""
local g_OptionalGiftBox_Two_UI_Info = ""
local g_OptionalGiftBox_Two_UI_Remark = ""

--常量
local g_OptionalGiftBox_Two_MainScript = 998256
local g_OptionalGiftBox_Two_UIC = 99825602
local g_OptionalGiftBox_Two_TotalNum = 2
local g_OptionalGiftBox_Two_MaxItemNum = 5

function OptionalGiftBox_Two_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function OptionalGiftBox_Two_OnLoad()

	g_OptionalGiftBox_Two_Frame_UnifiedPosition = OptionalGiftBox_Two_Frame_BK:GetProperty("UnifiedPosition")
	
	g_OptionalGiftBox_Two_UI_DragTitle = OptionalGiftBox_Two_DragTitle		
	g_OptionalGiftBox_Two_UI_Info = OptionalGiftBox_Two_Info
	g_OptionalGiftBox_Two_UI_Remark = OptionalGiftBox_Two_Remark
	
	g_OptionalGiftBox_Two_UI_ActionItem[1] = OptionalGiftBox_Two_Item1
	g_OptionalGiftBox_Two_UI_ActionItem[2] = OptionalGiftBox_Two_Item2
	
	g_OptionalGiftBox_Two_UI_ActionChosenMask[1] = OptionalGiftBox_Two_Item1_Mask
	g_OptionalGiftBox_Two_UI_ActionChosenMask[2] = OptionalGiftBox_Two_Item2_Mask
	
	g_OptionalGiftBox_Two_UI_ActionCornerMask[1] = OptionalGiftBox_Two_Item1_Cornermark
	g_OptionalGiftBox_Two_UI_ActionCornerMask[2] = OptionalGiftBox_Two_Item2_Cornermark
	
	g_OptionalGiftBox_Two_UI_ItemName[1] = OptionalGiftBox_Two_Item1_Name
	g_OptionalGiftBox_Two_UI_ItemName[2] = OptionalGiftBox_Two_Item2_Name
	
end										

function OptionalGiftBox_Two_OnEvent(event)
	
	if event == "UI_COMMAND" and (tonumber(arg0) == g_OptionalGiftBox_Two_UIC) then		

		OptionalGiftBox_Two_CleanUp()
		g_OptionalGiftBox_Two_CurBagPos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(g_OptionalGiftBox_Two_CurBagPos,1)
		this:Show()		
		OptionalGiftBox_Two_Update()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		OptionalGiftBox_Two_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == g_OptionalGiftBox_Two_CurBagPos then
		this:Hide()
		return
	end
	
end

function OptionalGiftBox_Two_Update()

	if g_OptionalGiftBox_Two_CurBagPos < 0 then
		return
	end
	
	--当前打开的礼包id
	local item_table_index = PlayerPackage:GetItemTableIndex(g_OptionalGiftBox_Two_CurBagPos)	
	
	--客户端读表，读取礼包内容
	local tbl_isBind, tbl_totalNum, tbl_chooseNum, tbl_boxTitle, tbl_boxTips1, tbl_boxTips2 = LuaFnGetOptionalGiftBoxInfo(item_table_index)
	if tbl_totalNum ~= g_OptionalGiftBox_Two_TotalNum or tbl_chooseNum > tbl_totalNum then
		this:Hide()
		return
	end
	
	g_OptionalGiftBox_Two_CurNeedNum = tbl_chooseNum
	g_OptionalGiftBox_Two_CurSelNum = 0
	g_OptionalGiftBox_Two_CurSelState = {0,0}
	
	--PushDebugMessage("初始化"..g_OptionalGiftBox_Two_CurSelNum..g_OptionalGiftBox_Two_CurNeedNum)
	
	g_OptionalGiftBox_Two_UI_DragTitle:SetText(tbl_boxTitle)
	g_OptionalGiftBox_Two_UI_Info:SetText(tbl_boxTips1)
	g_OptionalGiftBox_Two_UI_Remark:SetText(tbl_boxTips2)
	
	local itemList = {}
	for i = 1, g_OptionalGiftBox_Two_MaxItemNum do
		itemList[i] = {}
	end

	itemList[1].id, itemList[1].num, itemList[2].id, itemList[2].num, itemList[3].id, itemList[3].num, 
	itemList[4].id, itemList[4].num, itemList[5].id, itemList[5].num = LuaFnGetOptionalGiftBoxGiftInfo(item_table_index)
	
	OptionalGiftBox_Two_Item2_Num:SetText("")
	OptionalGiftBox_Two_Item2_Num:Hide()

	for i = 1, g_OptionalGiftBox_Two_TotalNum do
		if item_table_index == 38008608 and i == 2 then--kaichuan 
			local itemAction
			if tbl_isBind == 1 then
				itemAction = DataPool:CreateBindActionItemForShow(itemList[i].id, 1)
			else
				itemAction = DataPool:CreateActionItemForShow(itemList[i].id, 1)
			end
			if itemAction:GetID() ~= 0 then
				g_OptionalGiftBox_Two_UI_ActionItem[i]:SetActionItem(itemAction:GetID())
			end
		
			local strName = DataPool:Lua_GetItemNameByIndex(itemList[i].id)
			g_OptionalGiftBox_Two_UI_ItemName[i]:SetText("#L"..strName)
			OptionalGiftBox_Two_Item2_Num:Show()
			OptionalGiftBox_Two_Item2_Num:SetText(ScriptGlobal_Format("#{DWKC_260515_23}", itemList[i].num))
		else
			local itemAction
			if tbl_isBind == 1 then
				itemAction = DataPool:CreateBindActionItemForShow(itemList[i].id, itemList[i].num)
			else
				itemAction = DataPool:CreateActionItemForShow(itemList[i].id, itemList[i].num)
			end
			if itemAction:GetID() ~= 0 then
				g_OptionalGiftBox_Two_UI_ActionItem[i]:SetActionItem(itemAction:GetID())
			end
		
			local strName = DataPool:Lua_GetItemNameByIndex(itemList[i].id)
			g_OptionalGiftBox_Two_UI_ItemName[i]:SetText("#L"..strName)
		end
		
	end
	
	local hadFlag = {}
	
	for i = 1, g_OptionalGiftBox_Two_TotalNum do
		hadFlag[i] = Get_XParam_INT(i)
	end

	--已经拥有--
	for i = 1, g_OptionalGiftBox_Two_TotalNum do
		if hadFlag[i] > 0 then
			g_OptionalGiftBox_Two_UI_ActionCornerMask[i]:Show()
		else
			g_OptionalGiftBox_Two_UI_ActionCornerMask[i]:Hide()
		end
	end	

end

function OptionalGiftBox_Two_OnItemClicked(index)
	
	if g_OptionalGiftBox_Two_CurNeedNum == -1 or g_OptionalGiftBox_Two_CurSelNum == -1 then
		PushDebugMessage("礼包数据读取错误")
		return
	end
	
	if g_OptionalGiftBox_Two_CurNeedNum == 1 then
		
		g_OptionalGiftBox_Two_CurSelNum = 0
		for i = 1, g_OptionalGiftBox_Two_TotalNum do
			g_OptionalGiftBox_Two_UI_ActionItem[i]:SetPushed(0)
			g_OptionalGiftBox_Two_UI_ActionChosenMask[i]:Hide()
			g_OptionalGiftBox_Two_CurSelState[i] = 0
		end	
		
		g_OptionalGiftBox_Two_UI_ActionItem[index]:SetPushed(1)
		g_OptionalGiftBox_Two_UI_ActionChosenMask[index]:Show()
		g_OptionalGiftBox_Two_CurSelNum = g_OptionalGiftBox_Two_CurSelNum + 1
		g_OptionalGiftBox_Two_CurSelState[index] = 1
	
	else
		if g_OptionalGiftBox_Two_CurSelState[index] == 0 then
			if g_OptionalGiftBox_Two_CurSelNum >= g_OptionalGiftBox_Two_CurNeedNum then
				PushDebugMessage("#{TYLB_20220809_11}")
				return
			else
				g_OptionalGiftBox_Two_UI_ActionItem[index]:SetPushed(1)
				g_OptionalGiftBox_Two_UI_ActionChosenMask[index]:Show()
				g_OptionalGiftBox_Two_CurSelNum = g_OptionalGiftBox_Two_CurSelNum + 1
				g_OptionalGiftBox_Two_CurSelState[index] = 1
			end
		else
			g_OptionalGiftBox_Two_UI_ActionItem[index]:SetPushed(0)
			g_OptionalGiftBox_Two_UI_ActionChosenMask[index]:Hide()
			g_OptionalGiftBox_Two_CurSelNum = g_OptionalGiftBox_Two_CurSelNum - 1
			g_OptionalGiftBox_Two_CurSelState[index] = 0
		end

	end

end

function OptionalGiftBox_Two_CleanUp()	
	
	for i = 1, g_OptionalGiftBox_Two_TotalNum do	
		g_OptionalGiftBox_Two_UI_ActionItem[i]:SetActionItem(-1)
		g_OptionalGiftBox_Two_UI_ItemName[i]:SetText("")
		g_OptionalGiftBox_Two_UI_ActionChosenMask[i]:Hide()
	end 
	
	if g_OptionalGiftBox_Two_CurBagPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_OptionalGiftBox_Two_CurBagPos,0)
	end
	
	g_OptionalGiftBox_Two_CurBagPos = -1
	g_OptionalGiftBox_Two_CurSelState = {}
	g_OptionalGiftBox_Two_CurSelNum = -1
	g_OptionalGiftBox_Two_CurNeedNum = -1

end

function OptionalGiftBox_Two_OnHidden()
	OptionalGiftBox_Two_CleanUp()
	this:Hide()
end

function OptionalGiftBox_Two_OnGetClicked()
	
	if g_OptionalGiftBox_Two_CurBagPos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(g_OptionalGiftBox_Two_CurBagPos)	

	if g_OptionalGiftBox_Two_CurSelNum < g_OptionalGiftBox_Two_CurNeedNum then
		PushDebugMessage(ScriptGlobal_Format("#{TYLB_20220809_09}", g_OptionalGiftBox_Two_CurNeedNum))
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnClientGetGift")
		Set_XSCRIPT_ScriptID(g_OptionalGiftBox_Two_MainScript)
		Set_XSCRIPT_Parameter(0, g_OptionalGiftBox_Two_CurBagPos)
		Set_XSCRIPT_Parameter(1, g_OptionalGiftBox_Two_CurSelState[1])
		Set_XSCRIPT_Parameter(2, g_OptionalGiftBox_Two_CurSelState[2])
		Set_XSCRIPT_Parameter(3, -1)
		Set_XSCRIPT_Parameter(4, -1)
		Set_XSCRIPT_Parameter(5, -1)
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()

	this:Hide()
end

function OptionalGiftBox_Two_Frame_On_ResetPos()
	if g_OptionalGiftBox_Two_Frame_UnifiedPosition ~= nil then
		OptionalGiftBox_Two_Frame_BK:SetProperty("UnifiedPosition", g_OptionalGiftBox_Two_Frame_UnifiedPosition)
	end
end