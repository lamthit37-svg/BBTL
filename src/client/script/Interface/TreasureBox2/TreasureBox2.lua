--TreasureBox2
local g_TreasureBox2_UnifiedPosition;

local g_TreasureBox2_ActionButton = {}
local g_TreasureBox2_ItemName = {}
local g_TreasureBox2_ItemCost = {}
local g_TreasureBox2_BuyItem_Num = {}
local g_TreasureBox2_ShowItemInfo = {}
local g_TreasureBox2_Preview = {}
local g_TreasureBox2_pagebuttonleft = {}

local g_TreasureBox2_ItemNumMax = 999

local g_curShopType = 0
local g_curDaibi1 = 0
local g_curDaibi2 = 0
local g_curTBIndex = 0

local g_DuiHuan_MD_List1 = {}
local g_DuiHuan_MD_List2 = {}
local g_DuiHuan_MD_List3 = {0,0,0,0}

local g_CurPageIndex = 0
local g_CurPageItemMax = 9
local g_CurItemIndex = 0
local g_MaxItemCount = 36
local g_RedPointIsShow = 0

local g_NeedDaibiList = {
	[1] = {Daibi1 = 1125, Daibi2 = 75},
	[2] = {Daibi1 = 1125, Daibi2 = 75},
	[3] = {Daibi1 = 240, Daibi2 = 16},
	[4] = {Daibi1 = 120, Daibi2 = 8},
}
function TreasureBox2_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

	this:RegisterEvent("UPDATE_YUANBAO",false)
end

function TreasureBox2_OnLoad()
	g_TreasureBox2_UnifiedPosition = TreasureBox2_FrameNULL:GetProperty("UnifiedPosition")

	g_TreasureBox2_ActionButton[1] = TreasureBox2_Item1_Icon
	g_TreasureBox2_ActionButton[2] = TreasureBox2_Item2_Icon
	g_TreasureBox2_ActionButton[3] = TreasureBox2_Item3_Icon
	g_TreasureBox2_ActionButton[4] = TreasureBox2_Item4_Icon
	g_TreasureBox2_ActionButton[5] = TreasureBox2_Item5_Icon
	g_TreasureBox2_ActionButton[6] = TreasureBox2_Item6_Icon
	g_TreasureBox2_ActionButton[7] = TreasureBox2_Item7_Icon
	g_TreasureBox2_ActionButton[8] = TreasureBox2_Item8_Icon
	g_TreasureBox2_ActionButton[9] = TreasureBox2_Item9_Icon

	g_TreasureBox2_ItemName[1] = TreasureBox2_Item1_Text
	g_TreasureBox2_ItemName[2] = TreasureBox2_Item2_Text
	g_TreasureBox2_ItemName[3] = TreasureBox2_Item3_Text
	g_TreasureBox2_ItemName[4] = TreasureBox2_Item4_Text
	g_TreasureBox2_ItemName[5] = TreasureBox2_Item5_Text
	g_TreasureBox2_ItemName[6] = TreasureBox2_Item6_Text
	g_TreasureBox2_ItemName[7] = TreasureBox2_Item7_Text
	g_TreasureBox2_ItemName[8] = TreasureBox2_Item8_Text
	g_TreasureBox2_ItemName[9] = TreasureBox2_Item9_Text

	g_TreasureBox2_ItemCost[1] = TreasureBox2_Item1_Text2
	g_TreasureBox2_ItemCost[2] = TreasureBox2_Item2_Text2
	g_TreasureBox2_ItemCost[3] = TreasureBox2_Item3_Text2
	g_TreasureBox2_ItemCost[4] = TreasureBox2_Item4_Text2
	g_TreasureBox2_ItemCost[5] = TreasureBox2_Item5_Text2
	g_TreasureBox2_ItemCost[6] = TreasureBox2_Item6_Text2
	g_TreasureBox2_ItemCost[7] = TreasureBox2_Item7_Text2
	g_TreasureBox2_ItemCost[8] = TreasureBox2_Item8_Text2
	g_TreasureBox2_ItemCost[9] = TreasureBox2_Item9_Text2

	g_TreasureBox2_BuyItem_Num[1] = TreasureBox2_Item1_Text3
	g_TreasureBox2_BuyItem_Num[2] = TreasureBox2_Item2_Text3
	g_TreasureBox2_BuyItem_Num[3] = TreasureBox2_Item3_Text3
	g_TreasureBox2_BuyItem_Num[4] = TreasureBox2_Item4_Text3
	g_TreasureBox2_BuyItem_Num[5] = TreasureBox2_Item5_Text3
	g_TreasureBox2_BuyItem_Num[6] = TreasureBox2_Item6_Text3
	g_TreasureBox2_BuyItem_Num[7] = TreasureBox2_Item7_Text3
	g_TreasureBox2_BuyItem_Num[8] = TreasureBox2_Item8_Text3
	g_TreasureBox2_BuyItem_Num[9] = TreasureBox2_Item9_Text3

	g_TreasureBox2_ShowItemInfo[1] = TreasureBox2_Item1_Image
	g_TreasureBox2_ShowItemInfo[2] = TreasureBox2_Item2_Image
	g_TreasureBox2_ShowItemInfo[3] = TreasureBox2_Item3_Image
	g_TreasureBox2_ShowItemInfo[4] = TreasureBox2_Item4_Image
	g_TreasureBox2_ShowItemInfo[5] = TreasureBox2_Item5_Image
	g_TreasureBox2_ShowItemInfo[6] = TreasureBox2_Item6_Image
	g_TreasureBox2_ShowItemInfo[7] = TreasureBox2_Item7_Image
	g_TreasureBox2_ShowItemInfo[8] = TreasureBox2_Item8_Image
	g_TreasureBox2_ShowItemInfo[9] = TreasureBox2_Item9_Image

	g_TreasureBox2_Preview[1] = TreasureBox2_Item1_Preview1
	g_TreasureBox2_Preview[2] = TreasureBox2_Item2_Preview2
	g_TreasureBox2_Preview[3] = TreasureBox2_Item3_Preview3
	g_TreasureBox2_Preview[4] = TreasureBox2_Item4_Preview4
	g_TreasureBox2_Preview[5] = TreasureBox2_Item5_Preview5
	g_TreasureBox2_Preview[6] = TreasureBox2_Item6_Preview6
	g_TreasureBox2_Preview[7] = TreasureBox2_Item7_Preview7
	g_TreasureBox2_Preview[8] = TreasureBox2_Item8_Preview8
	g_TreasureBox2_Preview[9] = TreasureBox2_Item9_Preview9

	g_TreasureBox2_pagebuttonleft[1] = TreasureBox2_Buttontab01
	g_TreasureBox2_pagebuttonleft[2] = TreasureBox2_Buttontab02
	g_TreasureBox2_pagebuttonleft[3] = TreasureBox2_Buttontab03
	g_TreasureBox2_pagebuttonleft[4] = TreasureBox2_Buttontab04
end

function TreasureBox2_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88814304 ) then
		if IsWindowShow("TreasureBox_MBuy") then
			CloseWindow("TreasureBox_MBuy", true)
		end
		local operator = Get_XParam_INT(0)
		if operator == 1 then
			if IsWindowShow("VIP_Shop") then
				CloseWindow("VIP_Shop", true)
			end
			if(IsWindowShow("YuanbaoShop")) then
				CloseWindow("YuanbaoShop", true)
			end
			if(IsWindowShow("ShowShop")) then
				CloseWindow("ShowShop", true)
			end
			if(IsWindowShow("XuanShop")) then
				CloseWindow("XuanShop", true)
			end

			g_curShopType = Get_XParam_INT(1)	
			g_curDaibi1 = Get_XParam_INT(2)		
			g_curDaibi2 = Get_XParam_INT(3)
			g_curTBIndex = Get_XParam_INT(4)
			g_RedPointIsShow = Get_XParam_INT(5)

			g_CurPageIndex = 1

			TreasureBox2_On_SetLastPos()
			
			TreasureBox2_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				g_curShopType = Get_XParam_INT(1)
				g_curDaibi1 = Get_XParam_INT(2)
				g_curDaibi2 = Get_XParam_INT(3)
				g_curTBIndex = Get_XParam_INT(4)
				g_RedPointIsShow = Get_XParam_INT(5)

				TreasureBox2_Update()
			end
		elseif operator == 3 then
			if this:IsVisible() then
				g_curDaibi1 = Get_XParam_INT(2)
				g_curDaibi2 = Get_XParam_INT(3)
				TreasureBox2_YuanBaoNum2:SetText(ScriptGlobal_Format( "#{RCLS_200731_46}", g_curDaibi1))
				TreasureBox2_YuanBaoNum3:SetText(ScriptGlobal_Format( "#{RCLS_200731_48}", g_curDaibi2))
			end
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88814306 ) then
		if this:IsVisible() then
			local nType = Get_XParam_INT(0)
			if nType == 1 then
				for i = 1, 11 do
					g_DuiHuan_MD_List1[i] = Get_XParam_INT(i)
				end
			elseif nType == 2 then
				for i = 1, 6 do
					g_DuiHuan_MD_List2[i] = Get_XParam_INT(i)
				end
			elseif nType == 3 then
				for i = 1, 4 do
					g_DuiHuan_MD_List3[i] = Get_XParam_INT(i)
				end
			end
			TreasureBox2_Update()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		TreasureBox2_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TreasureBox2_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if IsWindowShow("TreasureBox_MBuy") then
			CloseWindow("TreasureBox_MBuy", true)
		end
		if IsWindowShow("TreasureBox_Preview") then
			CloseWindow("TreasureBox_Preview", true)
		end
		if IsWindowShow("TreasureBox_AwardPreview") then
			CloseWindow("TreasureBox_AwardPreview", true)
		end
		if IsWindowShow("TreasureBox_Award") then
			CloseWindow("TreasureBox_Award", true)
		end
		this:Hide()
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		TreasureBox2_YuanBaoNum:SetText(ScriptGlobal_Format( "#{RCLS_200731_45}", Player:GetData("YUANBAO")))
	end
end

--=========================================================
--刷新位置
--=========================================================
function TreasureBox2_On_ResetPos()
	TreasureBox2_FrameNULL:SetProperty("UnifiedPosition", g_TreasureBox2_UnifiedPosition);
end

--===============================================
-- 设置共享位置信息
--===============================================
function TreasureBox2_On_SetLastPos()
	local CurUIPos = Variable:GetVariable("TreasureBoxUIPos")
	if( CurUIPos ~= nil) then
	    TreasureBox2_FrameNULL:SetProperty("UnifiedPosition", CurUIPos )
	end
end

--=========================================================
--更新界面
--=========================================================
function TreasureBox2_Update()
	if g_curShopType == 1 then
		TreasureBox2_ButtonPage(2)
	elseif g_curShopType == 2 then
		TreasureBox2_ButtonPage(3)
	elseif g_curShopType == 3 then
		TreasureBox2_ButtonPage(4)
	end

	for i = 1, table.getn(g_TreasureBox2_ActionButton) do
		if g_TreasureBox2_ActionButton[i] ~= nil then
			g_TreasureBox2_ActionButton[i]:SetActionItem(-1)
			g_TreasureBox2_ActionButton[i]:Disable()

			g_TreasureBox2_ItemName[i]:SetText("")
			g_TreasureBox2_ItemCost[i]:SetText("")
			g_TreasureBox2_BuyItem_Num[i]:SetText("")
			g_TreasureBox2_ShowItemInfo[i]:Hide()
			g_TreasureBox2_Preview[i]:Hide()
		end
	end

	local nCount = GetLashouShopDuihuanCount( g_curTBIndex, g_curShopType )
	local maxpagenum = 0
	if math.mod(nCount, g_CurPageItemMax) > 0 then
		maxpagenum = math.floor(nCount/g_CurPageItemMax)+1
	else
		maxpagenum = math.floor(nCount/g_CurPageItemMax)
	end

	for i = 1, table.getn(g_TreasureBox2_ActionButton) do
		local nID, nNeedDaibi, nShowItemId, nItemNum, nLimit, nLimitType = GetLashouShopDuihuanItem( g_curTBIndex, g_curShopType, i+(g_CurPageIndex-1)*9 )

		if nID < 0 then
			break
		end

		local theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
		g_TreasureBox2_ActionButton[i]:SetActionItem(theAction:GetID())
		g_TreasureBox2_ActionButton[i]:Enable()
		g_TreasureBox2_ItemName[i]:SetText("#L"..theAction:GetName())

		if g_curShopType == 1 then
			g_TreasureBox2_ItemCost[i]:SetText(ScriptGlobal_Format( "#{RCLS_200731_80}",nNeedDaibi))
		elseif g_curShopType == 2 then
			g_TreasureBox2_ItemCost[i]:SetText(ScriptGlobal_Format( "#{RCLS_200731_81}",nNeedDaibi))
		elseif g_curShopType == 3 then
			g_TreasureBox2_ItemCost[i]:SetText(ScriptGlobal_Format( "#{RCLS_240905_02}",g_NeedDaibiList[i].Daibi2,g_NeedDaibiList[i].Daibi1))
		end

		local curbuycnt = TreasureBox2_GetLimitCount(i+(g_CurPageIndex-1)*9)
		if nLimit == 0 then
			g_TreasureBox2_BuyItem_Num[i]:SetText("")
		elseif curbuycnt >= nLimit then
			if nLimitType == 1 then --周限量
				g_TreasureBox2_BuyItem_Num[i]:SetText("#{RCLS_200731_84}") --售罄
			else
				g_TreasureBox2_BuyItem_Num[i]:SetText("#{RCLS_200731_114}") --售罄
			end
		else
			if nLimitType == 2 then --活动限量
				g_TreasureBox2_BuyItem_Num[i]:SetText(ScriptGlobal_Format( "#{RCLS_200731_83}",curbuycnt, nLimit))
			else
				g_TreasureBox2_BuyItem_Num[i]:SetText(ScriptGlobal_Format( "#{RCLS_200731_113}",curbuycnt, nLimit))
			end		
		end

		if nLimitType == 1 then
			g_TreasureBox2_ShowItemInfo[i]:Show()
			g_TreasureBox2_ShowItemInfo[i]:SetProperty("Image", "set:LLZBG02 image:LLZBG_ZXL")
		elseif nLimitType == 2 then
			g_TreasureBox2_ShowItemInfo[i]:Show()
			g_TreasureBox2_ShowItemInfo[i]:SetProperty("Image", "set:LLZBG02 image:LLZBG_HDXL")
		end

		if g_curShopType == 3 and nShowItemId == 39923285 then --预览
		
			g_TreasureBox2_Preview[i]:Show()
			g_TreasureBox2_Preview[i]:SetEvent("Clicked", "TreasureBox2_AwardPreview_ButtonClick()")
		else
			g_TreasureBox2_Preview[i]:Hide()
		end
		
	end
	
	TreasureBox2_YuanBaoNum:SetText(ScriptGlobal_Format( "#{RCLS_200731_45}", Player:GetData("YUANBAO")))
	TreasureBox2_YuanBaoNum2:SetText(ScriptGlobal_Format( "#{RCLS_200731_46}", g_curDaibi1))
	TreasureBox2_YuanBaoNum3:SetText(ScriptGlobal_Format( "#{RCLS_200731_48}", g_curDaibi2))
	TreasureBox2_CurrentlyPage:SetText(ScriptGlobal_Format( "#{RCLS_200731_169}", g_CurPageIndex, maxpagenum ) )
	
	TreasureBox2_UpPage:Enable()
	TreasureBox2_DownPage:Enable()
	
	if g_CurPageIndex <= 1 then
		TreasureBox2_UpPage:Disable()
	end
	
	if g_CurPageIndex >= maxpagenum then
		TreasureBox2_DownPage:Disable()
	end

	if g_RedPointIsShow == 0 then
		TreasureBox2_Buttontab01_Tips:Hide()
	else
		TreasureBox2_Buttontab01_Tips:Show()
	end

	this:Show()
end

function TreasureBox2_PageUp()
	g_CurPageIndex = g_CurPageIndex - 1

	TreasureBox2_Update()
end

function TreasureBox2_PageDown()
	g_CurPageIndex = g_CurPageIndex + 1

	TreasureBox2_Update()
end

--=========================================================
--商店说明
--=========================================================
function TreasureBox2_Help_Clicked()
	PushEvent("CCSHOP_HELP", 119)
end

--=========================================================
--关闭
--=========================================================
function TreasureBox2_Close()
	if IsWindowShow("TreasureBox_MBuy") then
		CloseWindow("TreasureBox_MBuy", true)
	end
	if IsWindowShow("TreasureBox_Preview") then
		CloseWindow("TreasureBox_Preview", true)
	end
	if IsWindowShow("TreasureBox_AwardPreview") then
		CloseWindow("TreasureBox_AwardPreview", true)
	end
	if IsWindowShow("TreasureBox_Award") then
		CloseWindow("TreasureBox_Award", true)
	end
	this:Hide()
end

function TreasureBox2_OnHiden()
	TreasureBox2_Close()
end

function TreasureBox2_Item_Click(nIndex)
	local ItemIndex = nIndex
	if ItemIndex < 1 or ItemIndex > g_CurPageItemMax then
		return
	end

	local curbuycnt = TreasureBox2_GetLimitCount(nIndex+(g_CurPageIndex-1)*9)

	if g_curShopType == 1 then
		PushEvent( "UI_COMMAND", 88819004, g_curTBIndex, g_curShopType, g_CurPageIndex, nIndex, curbuycnt, g_curDaibi1 )
	elseif g_curShopType == 2 then
		PushEvent( "UI_COMMAND", 88819004, g_curTBIndex, g_curShopType, g_CurPageIndex, nIndex, curbuycnt, g_curDaibi2 )
	elseif g_curShopType == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoExchange" )
			Set_XSCRIPT_ScriptID(888143)
			Set_XSCRIPT_Parameter(0,g_curShopType)
			Set_XSCRIPT_Parameter(1,nIndex)
			Set_XSCRIPT_Parameter(2,1)
			Set_XSCRIPT_Parameter(3,0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end

	this:Show()
end

-- 获取已兑换数
function TreasureBox2_GetLimitCount(nIndex)
	local ret = -1

	if g_curShopType == 1 then
		local MDData = nil
		for i = 1, 11 do
			if nIndex > 4*(i-1) and nIndex <= 4*i then
				MDData = g_DuiHuan_MD_List1[i]
				break
			end
		end

		if MDData ~= nil then
			local temp = math.mod(nIndex-1, 4) --0,1,2,3

			if temp == 0 then
				ret = math.mod(MDData, 100)
			elseif temp == 1 then
				ret = math.mod(math.floor(MDData/100), 100)
			elseif temp == 2 then
				ret = math.mod(math.floor(MDData/10000), 100)
			elseif temp == 3 then
				ret = math.mod(math.floor(MDData/1000000), 100)
			end
		end
	elseif g_curShopType == 2 then
		local MDData = nil
		for i = 1, 6 do
			if nIndex > 4*(i-1) and nIndex <= 4*i then
				MDData = g_DuiHuan_MD_List2[i]
				break
			end
		end

		if MDData ~= nil then
			local temp = math.mod(nIndex-1, 4) --0,1,2,3

			if temp == 0 then
				ret = math.mod(MDData, 100)
			elseif temp == 1 then
				ret = math.mod(math.floor(MDData/100), 100)
			elseif temp == 2 then
				ret = math.mod(math.floor(MDData/10000), 100)
			elseif temp == 3 then
				ret = math.mod(math.floor(MDData/1000000), 100)
			end
		end
	elseif g_curShopType == 3 then
		ret = g_DuiHuan_MD_List3[nIndex]
	end

	return ret
end

function TreasureBox2_Page_Clicked(index)
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenLibaoShop" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 2 then
		if g_curShopType == 1 then
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 3 then
		if g_curShopType == 2 then
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 4 then
		if g_curShopType == 3 then
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,3)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end

	Variable:SetVariable("TreasureBoxUIPos", TreasureBox2_FrameNULL:GetProperty("UnifiedPosition"), 1)
end

-- 选中页签
function TreasureBox2_ButtonPage(index)
	for i = 1, 4 do
		if index == i then
			g_TreasureBox2_pagebuttonleft[i]:SetProperty("Selected", "True")
		else
			g_TreasureBox2_pagebuttonleft[i]:SetProperty("Selected", "False")
		end
	end
end

--预览
function TreasureBox2_AwardPreview_ButtonClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10126420)
		Set_XSCRIPT_Parameter(1, 118)
		Set_XSCRIPT_Parameter(2, 86)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end


