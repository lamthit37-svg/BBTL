-- OptionalGiftBox_Four.lua
-- 配表通用4选礼包

--变量
local g_OptionalGiftBox_Four_Frame_UnifiedPosition = ""
local g_OptionalGiftBox_Four_CurSelState = {}
local g_OptionalGiftBox_Four_CurBagPos = -1
local g_OptionalGiftBox_Four_CurSelNum = -1
local g_OptionalGiftBox_Four_CurNeedNum = -1

--UI
local g_OptionalGiftBox_Four_UI_ActionItem = {}
local g_OptionalGiftBox_Four_UI_ActionChosenMask = {}
local g_OptionalGiftBox_Four_UI_ActionCornerMask = {}
local g_OptionalGiftBox_Four_UI_ItemName = {}
local g_OptionalGiftBox_Four_UI_DragTitle = ""
local g_OptionalGiftBox_Four_UI_Info = ""
local g_OptionalGiftBox_Four_UI_Remark = ""

--常量
local g_OptionalGiftBox_Four_MainScript = 998256
local g_OptionalGiftBox_Four_UIC = 99825604
local g_OptionalGiftBox_Four_TotalNum = 4
local g_OptionalGiftBox_Four_MaxItemNum = 5

function OptionalGiftBox_Four_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function OptionalGiftBox_Four_OnLoad()

	g_OptionalGiftBox_Four_Frame_UnifiedPosition = OptionalGiftBox_Four_Frame_BK:GetProperty("UnifiedPosition")
	
	g_OptionalGiftBox_Four_UI_DragTitle = OptionalGiftBox_Four_DragTitle		
	g_OptionalGiftBox_Four_UI_Info = OptionalGiftBox_Four_Info
	g_OptionalGiftBox_Four_UI_Remark = OptionalGiftBox_Four_Remark
	
	g_OptionalGiftBox_Four_UI_ActionItem[1] = OptionalGiftBox_Four_Item1
	g_OptionalGiftBox_Four_UI_ActionItem[2] = OptionalGiftBox_Four_Item2
	g_OptionalGiftBox_Four_UI_ActionItem[3] = OptionalGiftBox_Four_Item3
	g_OptionalGiftBox_Four_UI_ActionItem[4] = OptionalGiftBox_Four_Item4
	
	g_OptionalGiftBox_Four_UI_ActionChosenMask[1] = OptionalGiftBox_Four_Item1_Mask
	g_OptionalGiftBox_Four_UI_ActionChosenMask[2] = OptionalGiftBox_Four_Item2_Mask
	g_OptionalGiftBox_Four_UI_ActionChosenMask[3] = OptionalGiftBox_Four_Item3_Mask
	g_OptionalGiftBox_Four_UI_ActionChosenMask[4] = OptionalGiftBox_Four_Item4_Mask
	
	g_OptionalGiftBox_Four_UI_ActionCornerMask[1] = OptionalGiftBox_Four_Item1_Cornermark
	g_OptionalGiftBox_Four_UI_ActionCornerMask[2] = OptionalGiftBox_Four_Item2_Cornermark
	g_OptionalGiftBox_Four_UI_ActionCornerMask[3] = OptionalGiftBox_Four_Item3_Cornermark
	g_OptionalGiftBox_Four_UI_ActionCornerMask[4] = OptionalGiftBox_Four_Item4_Cornermark
	
	g_OptionalGiftBox_Four_UI_ItemName[1] = OptionalGiftBox_Four_Item1_Name
	g_OptionalGiftBox_Four_UI_ItemName[2] = OptionalGiftBox_Four_Item2_Name
	g_OptionalGiftBox_Four_UI_ItemName[3] = OptionalGiftBox_Four_Item3_Name
	g_OptionalGiftBox_Four_UI_ItemName[4] = OptionalGiftBox_Four_Item4_Name
	
end										

function OptionalGiftBox_Four_OnEvent(event)
	
	if event == "UI_COMMAND" and (tonumber(arg0) == g_OptionalGiftBox_Four_UIC) then		

		OptionalGiftBox_Four_CleanUp()
		g_OptionalGiftBox_Four_CurBagPos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(g_OptionalGiftBox_Four_CurBagPos,1)
		this:Show()		
		OptionalGiftBox_Four_Update()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		OptionalGiftBox_Four_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == g_OptionalGiftBox_Four_CurBagPos then
		this:Hide()
		return
	end
	
end

function OptionalGiftBox_Four_Update()

	if g_OptionalGiftBox_Four_CurBagPos < 0 then
		return
	end
	
	--当前打开的礼包id
	local item_table_index = PlayerPackage:GetItemTableIndex(g_OptionalGiftBox_Four_CurBagPos)	
	
	--客户端读表，读取礼包内容
	local tbl_isBind, tbl_totalNum, tbl_chooseNum, tbl_boxTitle, tbl_boxTips1, tbl_boxTips2 = LuaFnGetOptionalGiftBoxInfo(item_table_index)
	if tbl_totalNum ~= g_OptionalGiftBox_Four_TotalNum or tbl_chooseNum > tbl_totalNum then
		this:Hide()
		return
	end
	
	g_OptionalGiftBox_Four_CurNeedNum = tbl_chooseNum
	g_OptionalGiftBox_Four_CurSelNum = 0
	g_OptionalGiftBox_Four_CurSelState = {0,0,0,0}
	
	--PushDebugMessage("初始化"..g_OptionalGiftBox_Four_CurSelNum..g_OptionalGiftBox_Four_CurNeedNum)
	
	g_OptionalGiftBox_Four_UI_DragTitle:SetText(tbl_boxTitle)
	g_OptionalGiftBox_Four_UI_Info:SetText(tbl_boxTips1)
	g_OptionalGiftBox_Four_UI_Remark:SetText(tbl_boxTips2)
	
	local itemList = {}
	for i = 1, g_OptionalGiftBox_Four_MaxItemNum do
		itemList[i] = {}
	end

	itemList[1].id, itemList[1].num, itemList[2].id, itemList[2].num, itemList[3].id, itemList[3].num, 
	itemList[4].id, itemList[4].num, itemList[5].id, itemList[5].num = LuaFnGetOptionalGiftBoxGiftInfo(item_table_index)
	
	for i = 1, g_OptionalGiftBox_Four_TotalNum do
		local itemAction
		if tbl_isBind == 1 then
			itemAction = DataPool:CreateBindActionItemForShow(itemList[i].id, itemList[i].num)
		else
			itemAction = DataPool:CreateActionItemForShow(itemList[i].id, itemList[i].num)
		end
		if itemAction:GetID() ~= 0 then
			g_OptionalGiftBox_Four_UI_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(itemList[i].id)
		g_OptionalGiftBox_Four_UI_ItemName[i]:SetText("#L"..strName)
	end
	
	local hadFlag = {}
	
	for i = 1, g_OptionalGiftBox_Four_TotalNum do
		hadFlag[i] = Get_XParam_INT(i)
	end

	--已经拥有--
	for i = 1, g_OptionalGiftBox_Four_TotalNum do
		if hadFlag[i] > 0 then
			g_OptionalGiftBox_Four_UI_ActionCornerMask[i]:Show()
		else
			g_OptionalGiftBox_Four_UI_ActionCornerMask[i]:Hide()
		end
	end	

end

function OptionalGiftBox_Four_OnItemClicked(index)
	
	if g_OptionalGiftBox_Four_CurNeedNum == -1 or g_OptionalGiftBox_Four_CurSelNum == -1 then
		PushDebugMessage("礼包数据读取错误")
		return
	end

	if g_OptionalGiftBox_Four_CurNeedNum == 1 then
		
		g_OptionalGiftBox_Four_CurSelNum = 0
		for i = 1, g_OptionalGiftBox_Four_TotalNum do
			g_OptionalGiftBox_Four_UI_ActionItem[i]:SetPushed(0)
			g_OptionalGiftBox_Four_UI_ActionChosenMask[i]:Hide()
			g_OptionalGiftBox_Four_CurSelState[i] = 0
		end	
		
		g_OptionalGiftBox_Four_UI_ActionItem[index]:SetPushed(1)
		g_OptionalGiftBox_Four_UI_ActionChosenMask[index]:Show()
		g_OptionalGiftBox_Four_CurSelNum = g_OptionalGiftBox_Four_CurSelNum + 1
		g_OptionalGiftBox_Four_CurSelState[index] = 1
	
	else
		if g_OptionalGiftBox_Four_CurSelState[index] == 0 then
			if g_OptionalGiftBox_Four_CurSelNum >= g_OptionalGiftBox_Four_CurNeedNum then
				PushDebugMessage("#{TYLB_20220809_11}")
				return
			else
				g_OptionalGiftBox_Four_UI_ActionItem[index]:SetPushed(1)
				g_OptionalGiftBox_Four_UI_ActionChosenMask[index]:Show()
				g_OptionalGiftBox_Four_CurSelNum = g_OptionalGiftBox_Four_CurSelNum + 1
				g_OptionalGiftBox_Four_CurSelState[index] = 1
			end
		else
			g_OptionalGiftBox_Four_UI_ActionItem[index]:SetPushed(0)
			g_OptionalGiftBox_Four_UI_ActionChosenMask[index]:Hide()
			g_OptionalGiftBox_Four_CurSelNum = g_OptionalGiftBox_Four_CurSelNum - 1
			g_OptionalGiftBox_Four_CurSelState[index] = 0
		end
	end

end

function OptionalGiftBox_Four_CleanUp()	
	
	for i = 1, g_OptionalGiftBox_Four_TotalNum do	
		g_OptionalGiftBox_Four_UI_ActionItem[i]:SetActionItem(-1)
		g_OptionalGiftBox_Four_UI_ItemName[i]:SetText("")
		g_OptionalGiftBox_Four_UI_ActionChosenMask[i]:Hide()
	end 
	
	if g_OptionalGiftBox_Four_CurBagPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_OptionalGiftBox_Four_CurBagPos,0)
	end
	
	g_OptionalGiftBox_Four_CurBagPos = -1
	g_OptionalGiftBox_Four_CurSelState = {}
	g_OptionalGiftBox_Four_CurSelNum = -1
	g_OptionalGiftBox_Four_CurNeedNum = -1

end

function OptionalGiftBox_Four_OnHidden()
	OptionalGiftBox_Four_CleanUp()
	this:Hide()
end

function OptionalGiftBox_Four_OnGetClicked()
	
	if g_OptionalGiftBox_Four_CurBagPos < 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(g_OptionalGiftBox_Four_CurBagPos)	

	if g_OptionalGiftBox_Four_CurSelNum < g_OptionalGiftBox_Four_CurNeedNum then
		PushDebugMessage(ScriptGlobal_Format("#{TYLB_20220809_09}", g_OptionalGiftBox_Four_CurNeedNum))
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnClientGetGift")
		Set_XSCRIPT_ScriptID(g_OptionalGiftBox_Four_MainScript)
		Set_XSCRIPT_Parameter(0, g_OptionalGiftBox_Four_CurBagPos)
		Set_XSCRIPT_Parameter(1, g_OptionalGiftBox_Four_CurSelState[1])
		Set_XSCRIPT_Parameter(2, g_OptionalGiftBox_Four_CurSelState[2])
		Set_XSCRIPT_Parameter(3, g_OptionalGiftBox_Four_CurSelState[3])
		Set_XSCRIPT_Parameter(4, g_OptionalGiftBox_Four_CurSelState[4])
		Set_XSCRIPT_Parameter(5, -1)
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()

	this:Hide()
end

function OptionalGiftBox_Four_Frame_On_ResetPos()
	if g_OptionalGiftBox_Four_Frame_UnifiedPosition ~= nil then
		OptionalGiftBox_Four_Frame_BK:SetProperty("UnifiedPosition", g_OptionalGiftBox_Four_Frame_UnifiedPosition)
	end
end