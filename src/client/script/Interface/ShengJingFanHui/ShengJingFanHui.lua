
local g_ShengJingFanHui_Frame_UnifiedPosition
local g_ShengJingFanHui_CurYeQianIndex = 1
local g_ShengJingFanHui_Level = -1
local g_ShengJingFanHui_Paintbrush = 0
local g_ShengJingFanHui_PaintMD = 0
local g_ShengJingFanHui_PaintFinishCount = 0

local g_ShengJingFanHui_IsGotLowReward = 0
local g_ShengJingFanHui_IsGotHighReward = 0

local g_ShengJingFanHui_ItemNumPerPage = 12 --每页展示的物品个数
local g_ShengJingFanHui_CurPageNum = 1 --当前商店界面所在的页数
local g_ShengJingFanHui_ItemUITable = {}

local g_ShengJingFanHui_CurBuyTimesMD = 0

local g_ShengJingFanHui_IsShowTaskPoint = 0

local g_ShengJingFanHui_CanGetTitleTimes = 10 --完成多少次可以领称号

local g_ShengJingFanHui_IsGotTitle = 0

-- local alpha_to_info = string.format("curve:Liner mode:Once duration:%s startx:0 starty:0 endx:1 endy:0", 1)


--根据商店表的id 取得储存位index
local g_ShengJingFanHui_TableIdTransIndex =
{
	[8]  =1,
	[9]  =2,
	[10] =3,
	[11] =4,
	[14] =5,
	[17] =6,
}

local g_ShengJingFanHui_CurBuyTimes = {}

function ShengJingFanHui_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
	this:RegisterEvent("ADJEST_UI_POS",false)
	
end

function ShengJingFanHui_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2023051101) then
		if this:IsVisible() then
			ShengJingFanHui_OnClose()
			return
		end
		this:Show()
		g_ShengJingFanHui_Level = Get_XParam_INT(0)
		g_ShengJingFanHui_Paintbrush = Get_XParam_INT(1)
		g_ShengJingFanHui_PaintMD = Get_XParam_INT(2)
		g_ShengJingFanHui_PaintFinishCount = Get_XParam_INT(3)

		g_ShengJingFanHui_IsGotLowReward = Get_XParam_INT(4)
		g_ShengJingFanHui_IsGotHighReward = Get_XParam_INT(5)
		g_ShengJingFanHui_CurBuyTimesMD = Get_XParam_INT(6)
		g_ShengJingFanHui_IsShowTaskPoint = Get_XParam_INT(7)
		g_ShengJingFanHui_IsGotTitle = Get_XParam_INT(8)
		-- PushDebugMessage("g_ShengJingFanHui_Level:"..tostring(g_ShengJingFanHui_Level))
		-- PushDebugMessage("g_ShengJingFanHui_Paintbrush:"..tostring(g_ShengJingFanHui_Paintbrush))
		-- PushDebugMessage("g_ShengJingFanHui_PaintMD:"..tostring(g_ShengJingFanHui_PaintMD))
		if g_ShengJingFanHui_Level>=0 then
			ShengJingFanHui_OnFenYeClick(1, 0, 0)
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 2023051501) then
		if (true ~= this:IsVisible()) then
			return
		end
		g_ShengJingFanHui_Level = Get_XParam_INT(0)
		g_ShengJingFanHui_Paintbrush = Get_XParam_INT(1)
		g_ShengJingFanHui_PaintMD = Get_XParam_INT(2)
		g_ShengJingFanHui_PaintFinishCount = Get_XParam_INT(3)

		g_ShengJingFanHui_IsGotLowReward = Get_XParam_INT(4)
		g_ShengJingFanHui_IsGotHighReward = Get_XParam_INT(5)
		g_ShengJingFanHui_CurBuyTimesMD = Get_XParam_INT(6)
		g_ShengJingFanHui_IsGotTitle = Get_XParam_INT(8)
		g_ShengJingFanHui_IsShowTaskPoint = Get_XParam_INT(9)
		PushEvent("SJFH_CLOSE_POPUI")
		if g_ShengJingFanHui_Level>=0 then
			ShengJingFanHui_OnFenYeClick(g_ShengJingFanHui_CurYeQianIndex, 1, Get_XParam_INT(7))
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ShengJingFanHui_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		ShengJingFanHui_OnClose()
	elseif event == "ADJEST_UI_POS" then
		ShengJingFanHui_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ShengJingFanHui_OnClose()
	end
end

function ShengJingFanHui_OnFenYeClick(index,isRefresh,isPlayanimate)
	g_ShengJingFanHui_CurYeQianIndex = index
	if g_ShengJingFanHui_CurYeQianIndex == 1 then
		ShengJingFanHui_Frame_Fenye1:SetCheck(1)
		ShengJingFanHui_Frame_Fenye2:SetCheck(0)
		ShengJingFanHui_Frame_Client:Show()
		ShengJingFanHui_Frame_PrizeClient:Hide()
		ShengJingFanHui_Text:SetText(ScriptGlobal_Format("#{SJFH_230425_12}", g_ShengJingFanHui_Paintbrush))
		
		ShengJingFanHui_Reward1_tips:Hide()
		ShengJingFanHui_Reward2_tips:Hide()
		ShengJingFanHui_Reward1BtnOK:Hide()
		ShengJingFanHui_Reward2BtnOK:Hide()
		ShengJingFanHui_Guide_Button_Tips:Hide()
		if g_ShengJingFanHui_IsShowTaskPoint == 1 then
			ShengJingFanHui_Prize1_Tips:Show()
		else
			ShengJingFanHui_Prize1_Tips:Hide()
		end

		if g_ShengJingFanHui_PaintFinishCount >= g_ShengJingFanHui_CanGetTitleTimes and g_ShengJingFanHui_IsGotTitle==0 then
			-- ShengJingFanHui_GetTit_Tips:Show()
			ShengJingFanHui_Frame_Fenye2_Tips:Show()
		else
			-- ShengJingFanHui_GetTit_Tips:Hide()
			ShengJingFanHui_Frame_Fenye2_Tips:Hide()
		end


		ShengJingFanHui_ProgressBarText_Num:SetText(ScriptGlobal_Format("#{SJFH_230425_170}", g_ShengJingFanHui_Level))


		if g_ShengJingFanHui_Level < 3 and g_ShengJingFanHui_Paintbrush > 0 then
			-- if g_ShengJingFanHui_Level == 1 and g_ShengJingFanHui_Paintbrush < 2 then
			-- else
				ShengJingFanHui_Guide_Button_Tips:Show()
			-- end
		end

		if g_ShengJingFanHui_Level >= 2 and g_ShengJingFanHui_IsGotLowReward == 0 then
			ShengJingFanHui_Reward1_tips:Show()
		end
		if g_ShengJingFanHui_Level >= 3 and g_ShengJingFanHui_IsGotHighReward == 0 then
			ShengJingFanHui_Reward2_tips:Show()
		end
		if g_ShengJingFanHui_IsGotLowReward == 1 then
			ShengJingFanHui_Reward1BtnOK:Show()
		end
		if g_ShengJingFanHui_IsGotHighReward == 1 then
			ShengJingFanHui_Reward2BtnOK:Show()
		end
		if isRefresh== 1 and isPlayanimate == 1 then
			-- local alpha_to_info = string.format("curve:Liner mode:Once duration:%s startx:1 starty:0 endx:0 endy:0", 1.5)
			-- ShengJingFanHui_BK2:Tween_SetInfo("Alpha", alpha_to_info)
			-- ShengJingFanHui_BK3:Tween_SetInfo("Alpha", alpha_to_info)
			-- ShengJingFanHui_BK4:Tween_SetInfo("Alpha", alpha_to_info)
			ShengJingFanHui_Animate:Play(true)
			if g_ShengJingFanHui_Level == 1 then
				ShengJingFanHui_BK2:Show()
				ShengJingFanHui_BK2:Tween_Play("Alpha", true, true)
			elseif g_ShengJingFanHui_Level == 2 then
				ShengJingFanHui_BK3:Show()
				ShengJingFanHui_BK3:Tween_Play("Alpha", true, true)
			else
				ShengJingFanHui_BK4:Show()
				ShengJingFanHui_BK4:Tween_Play("Alpha", true, true)
			end
		else
			ShengJingFanHui_Animate:Play(false)
			if g_ShengJingFanHui_Level == 0 then
				-- ShengJingFanHui_BK1:Show()
				ShengJingFanHui_BK2:Hide()
				ShengJingFanHui_BK3:Hide()
				ShengJingFanHui_BK4:Hide()
			elseif g_ShengJingFanHui_Level == 1 then
				-- ShengJingFanHui_BK1:Show()
				ShengJingFanHui_BK2:Show()
				ShengJingFanHui_BK3:Hide()
				ShengJingFanHui_BK4:Hide()
			elseif g_ShengJingFanHui_Level == 2 then
				-- ShengJingFanHui_BK1:Show()
				ShengJingFanHui_BK2:Show()
				ShengJingFanHui_BK3:Show()
				ShengJingFanHui_BK4:Hide()
			else
				-- ShengJingFanHui_BK1:Show()
				ShengJingFanHui_BK2:Show()
				ShengJingFanHui_BK3:Show()
				ShengJingFanHui_BK4:Show()
			end
		end

	elseif g_ShengJingFanHui_CurYeQianIndex == 2 then

		if g_ShengJingFanHui_PaintFinishCount >= g_ShengJingFanHui_CanGetTitleTimes and g_ShengJingFanHui_IsGotTitle==0 then
			ShengJingFanHui_GetTit_Tips:Show()
		else
			ShengJingFanHui_GetTit_Tips:Hide()
			ShengJingFanHui_Frame_Fenye2_Tips:Hide()
		end

		ShengJingFanHui_Frame_Fenye1:SetCheck(0)
		ShengJingFanHui_Frame_Fenye2:SetCheck(1)
		ShengJingFanHui_Frame_Client:Hide()
		ShengJingFanHui_Frame_PrizeClient:Show()
		ShengJingFanHui_ItemNum:SetText(ScriptGlobal_Format("#{SJFH_230425_94}", g_ShengJingFanHui_PaintFinishCount))
		ShengJingFanHui_RefreshShop()
	end
end


function ShengJingFanHui_GetBuyTimesByIndex(index)
	if index<1 or index > 6 then
		return
	end
	local curBuyTimes = {}
	local bRet = 0
	for i = 1, 6 do
		bRet, curBuyTimes[i] = GetBitValueInUINT(g_ShengJingFanHui_CurBuyTimesMD, (i-1) * 3, 3)
		if nil == bRet or 1 ~= bRet then
			curBuyTimes[i] = -1
		end
	end

	return curBuyTimes[index]
end



function ShengJingFanHui_RefreshShop()
	ShengJingFanHui_PrizeInfo2_Lace:SetText(ScriptGlobal_Format("#{SJFH_230425_57}", g_ShengJingFanHui_PaintMD))

	local shopItemTotleNum = DataPool:GetSJFHShopCount()
	-- PushDebugMessage("g_ShengJingFanHui_Level:"..tostring(shopItemTotleNum))
	local maxPageNum = math.ceil(shopItemTotleNum/g_ShengJingFanHui_ItemNumPerPage)
	if maxPageNum<1 then
		maxPageNum = 1
	end

	if g_ShengJingFanHui_CurPageNum == 1 then
		ShengJingFanHui_UpPage:Disable()
	else
		ShengJingFanHui_UpPage:Enable()
	end

	if g_ShengJingFanHui_CurPageNum == maxPageNum then
		ShengJingFanHui_DownPage:Disable()
	else
		ShengJingFanHui_DownPage:Enable()
	end

	ShengJingFanHui_CurrentlyPage:SetText(ScriptGlobal_Format("#{SJFH_230425_141}", g_ShengJingFanHui_CurPageNum,maxPageNum))
	local curPageTotleNum = shopItemTotleNum-(g_ShengJingFanHui_CurPageNum-1)*g_ShengJingFanHui_ItemNumPerPage
	-- PushDebugMessage("curPageTotleNum:"..tostring(curPageTotleNum))
	for i = 1,table.getn(g_ShengJingFanHui_ItemUITable) do
		if i > curPageTotleNum then
			g_ShengJingFanHui_ItemUITable[i].ItemFrame:Hide()
		else
			g_ShengJingFanHui_ItemUITable[i].ItemFrame:Show()
			
			g_ShengJingFanHui_ItemUITable[i].LimitBuy:Hide()
			g_ShengJingFanHui_ItemUITable[i].LimitMask:Hide()
			g_ShengJingFanHui_ItemUITable[i].SellOut:Hide()

			local tableId = (g_ShengJingFanHui_CurPageNum-1)*g_ShengJingFanHui_ItemNumPerPage+i
			local kjtype   = KaJi:LuaFnGetKaJiType(135)
			local iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH",tableId)
			if kjtype == 1 then
				iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH_KAJI_1",tableId)
			end
			g_ShengJingFanHui_CurBuyTimes[tableId] = -1
			if iteminfo then
				local theAction = DataPool:CreateActionItemForShow(iteminfo.nShowItemID, 1)
				if theAction:GetID() ~= 0 then
					g_ShengJingFanHui_ItemUITable[i].ActionItem:SetActionItem(theAction:GetID())
				end
				g_ShengJingFanHui_ItemUITable[i].ItemName:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
				g_ShengJingFanHui_ItemUITable[i].ItemNum:SetText(iteminfo.nSaleCount)
				g_ShengJingFanHui_ItemUITable[i].LimitBuyNumBK:Hide()
				
				g_ShengJingFanHui_ItemUITable[i].ItemPrice:SetText(ScriptGlobal_Format("#{SJFH_230425_55}",iteminfo.nPrice))
				--看看是否有限量的需求 然后判断一下如何存储
				if iteminfo.nLimit > 0 and g_ShengJingFanHui_TableIdTransIndex[tableId] ~= nil then
					local buyTimes = ShengJingFanHui_GetBuyTimesByIndex(g_ShengJingFanHui_TableIdTransIndex[tableId])
					g_ShengJingFanHui_CurBuyTimes[tableId] = buyTimes
					g_ShengJingFanHui_ItemUITable[i].LimitBuyNumBK:Show()
					g_ShengJingFanHui_ItemUITable[i].LimitBuyNum:SetText(tostring(iteminfo.nLimit-buyTimes))
					g_ShengJingFanHui_ItemUITable[i].LimitBuy:Show()
					if iteminfo.nLimit-buyTimes > 0 then 
						g_ShengJingFanHui_ItemUITable[i].LimitMask:Hide()
						g_ShengJingFanHui_ItemUITable[i].SellOut:Hide()
					else
						g_ShengJingFanHui_ItemUITable[i].LimitMask:Show()
						g_ShengJingFanHui_ItemUITable[i].SellOut:Show()
						-- g_ShengJingFanHui_ItemUITable[i].ActionItem:Disable()
					end
				else
					g_ShengJingFanHui_ItemUITable[i].LimitBuy:Hide()
				end

			end
		end
	end

end

function ShengJingFanHui_ExchangePrize(index)
	if index<1 or index>g_ShengJingFanHui_ItemNumPerPage then
		return
	end

	local tableId = (g_ShengJingFanHui_CurPageNum-1)*g_ShengJingFanHui_ItemNumPerPage+index
	
	if tableId == nil or tableId < 0 then
		return 
	end

	local kjtype   = KaJi:LuaFnGetKaJiType(135)
	local iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH",tableId)
	if kjtype == 1 then
		iteminfo = DataPool:TBSearch_Index_EQU("DBC_SJFH_KAJI_1",tableId)
	end
	if iteminfo then
		if iteminfo.nLimit > 0 and g_ShengJingFanHui_CurBuyTimes[tableId] ~= nil then
			if iteminfo.nLimit - g_ShengJingFanHui_CurBuyTimes[tableId] <= 0 then
				return
			end
		end
	else
		return
	end

	-- PushDebugMessage("g_ShengJingFanHui_PaintMD:"..tostring(g_ShengJingFanHui_PaintMD))
	PushEvent("SJFH_OPEN_BUY", tableId, g_ShengJingFanHui_PaintMD, g_ShengJingFanHui_CurBuyTimes[tableId])

end


function ShengJingFanHui_UpPageClick()
	-- PushDebugMessage("xtcU")
	if g_ShengJingFanHui_CurPageNum > 1 then
		g_ShengJingFanHui_CurPageNum = g_ShengJingFanHui_CurPageNum - 1
		ShengJingFanHui_RefreshShop()
	end
end

function ShengJingFanHui_DownPageClick()
		-- PushDebugMessage("xtcD")
	local shopItemTotleNum = DataPool:GetSJFHShopCount()
	local maxPageNum = math.ceil(shopItemTotleNum/g_ShengJingFanHui_ItemNumPerPage)
	if g_ShengJingFanHui_CurPageNum < maxPageNum then
		g_ShengJingFanHui_CurPageNum = g_ShengJingFanHui_CurPageNum + 1
		ShengJingFanHui_RefreshShop()
	end
end

function ShengJingFanHui_TaskClicked()
	-- PushDebugMessage("xtc")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenEveryDayTask")
		Set_XSCRIPT_ScriptID(998544)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ShengJingFanHui_PrizeButton_Clicked(index)
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GetReward")
	Set_XSCRIPT_ScriptID(998544)
	Set_XSCRIPT_Parameter( 0, index )
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ShengJingFanHui_Paint()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LevelAdvance")
		Set_XSCRIPT_ScriptID(998544)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ShengJingFanHui_GetTit()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetTitleItem")
		Set_XSCRIPT_ScriptID(998544)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ShengJingFanHui_HelpClick()
	PushEvent("CCSHOP_HELP", 195)
end

function ShengJingFanHui_On_ResetPos()
	ShengJingFanHui_Frame:SetProperty("UnifiedPosition", g_ShengJingFanHui_Frame_UnifiedPosition)
end

function ShengJingFanHui_OnHide()
	PushEvent("SJFH_CLOSE_POPUI")
	g_ShengJingFanHui_CurYeQianIndex = 1
	g_ShengJingFanHui_CurPageNum = 1
	g_ShengJingFanHui_Level = -1
	ShengJingFanHui_Animate:Play(false)

	ShengJingFanHui_BK2:Tween_Reset("Alpha",false)
	ShengJingFanHui_BK3:Tween_Reset("Alpha",false)
	ShengJingFanHui_BK4:Tween_Reset("Alpha",false)
end

function ShengJingFanHui_OnClose()
	this:Hide()
end


function ShengJingFanHui_OnLoad()
	g_ShengJingFanHui_Frame_UnifiedPosition = ShengJingFanHui_Frame:GetProperty("UnifiedPosition")

	local alpha_to_info = string.format("curve:Liner mode:Once duration:%s startx:0 starty:0 endx:1 endy:0", 1.8)
	ShengJingFanHui_BK2:Tween_SetInfo("Alpha", alpha_to_info)
	ShengJingFanHui_BK3:Tween_SetInfo("Alpha", alpha_to_info)
	ShengJingFanHui_BK4:Tween_SetInfo("Alpha", alpha_to_info)

	g_ShengJingFanHui_ItemUITable=
	{
		[1] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK1,
			ActionItem = ShengJingFanHui_PrizeFrame_BK1_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK1_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK1_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK1_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK1_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK1_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item1LimitNumber,
			ItemNum = ShengJingFanHui_Item1Number,
			LimitBuyNumBK = ShengJingFanHui_Item1LimitNumberBK,
		},
		[2] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK2,
			ActionItem = ShengJingFanHui_PrizeFrame_BK2_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK2_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK2_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK2_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK2_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK2_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item2LimitNumber,
			ItemNum = ShengJingFanHui_Item2Number,
			LimitBuyNumBK = ShengJingFanHui_Item2LimitNumberBK,
		},
		[3] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK3,
			ActionItem = ShengJingFanHui_PrizeFrame_BK3_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK3_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK3_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK3_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK3_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK3_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item3LimitNumber,
			ItemNum = ShengJingFanHui_Item3Number,
			LimitBuyNumBK = ShengJingFanHui_Item3LimitNumberBK,
		},
		[4] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK4,
			ActionItem = ShengJingFanHui_PrizeFrame_BK4_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK4_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK4_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK4_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK4_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK4_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item4LimitNumber,
			ItemNum = ShengJingFanHui_Item4Number,
			LimitBuyNumBK = ShengJingFanHui_Item4LimitNumberBK,
		},
		[5] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK5,
			ActionItem = ShengJingFanHui_PrizeFrame_BK5_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK5_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK5_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK5_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK5_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK5_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item5LimitNumber,
			ItemNum = ShengJingFanHui_Item5Number,
			LimitBuyNumBK = ShengJingFanHui_Item5LimitNumberBK,
		},
		[6] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK6,
			ActionItem = ShengJingFanHui_PrizeFrame_BK6_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK6_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK6_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK6_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK6_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK6_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item6LimitNumber,
			ItemNum = ShengJingFanHui_Item6Number,
			LimitBuyNumBK = ShengJingFanHui_Item6LimitNumberBK,
		},
		[7] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK7,
			ActionItem = ShengJingFanHui_PrizeFrame_BK7_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK7_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK7_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK7_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK7_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK7_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item7LimitNumber,
			ItemNum = ShengJingFanHui_Item7Number,
			LimitBuyNumBK = ShengJingFanHui_Item7LimitNumberBK,
		},
		[8] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK8,
			ActionItem = ShengJingFanHui_PrizeFrame_BK8_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK8_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK8_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK8_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK8_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK8_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item8LimitNumber,
			ItemNum = ShengJingFanHui_Item8Number,
			LimitBuyNumBK = ShengJingFanHui_Item8LimitNumberBK,
		},
		[9] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK9,
			ActionItem = ShengJingFanHui_PrizeFrame_BK9_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK9_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK9_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK9_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK9_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK9_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item9LimitNumber,
			ItemNum = ShengJingFanHui_Item9Number,
			LimitBuyNumBK = ShengJingFanHui_Item9LimitNumberBK,
		},
		[10] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK10,
			ActionItem = ShengJingFanHui_PrizeFrame_BK10_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK10_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK10_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK10_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK10_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK10_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item10LimitNumber,
			ItemNum = ShengJingFanHui_Item10Number,
			LimitBuyNumBK = ShengJingFanHui_Item10LimitNumberBK,
		},
		[11] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK11,
			ActionItem = ShengJingFanHui_PrizeFrame_BK11_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK11_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK11_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK11_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK11_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK11_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item11LimitNumber,
			ItemNum = ShengJingFanHui_Item11Number,
			LimitBuyNumBK = ShengJingFanHui_Item11LimitNumberBK,
		},
		[12] = {
			ItemFrame = ShengJingFanHui_PrizeFrame_BK12,
			ActionItem = ShengJingFanHui_PrizeFrame_BK12_Icon,
			ItemName = ShengJingFanHui_PrizeFrame_BK12_ItemName,
			ItemPrice = ShengJingFanHui_PrizeFrame_BK12_ItemMoney,
			SellOut = ShengJingFanHui_PrizeFrame_BK12_SellOut,
			LimitMask = ShengJingFanHui_PrizeFrame_BK12_Icon_Mask,
			LimitBuy = ShengJingFanHui_PrizeFrame_BK12_Icon_BuyLimit,
			LimitBuyNum = ShengJingFanHui_Item12LimitNumber,
			ItemNum = ShengJingFanHui_Item12Number,
			LimitBuyNumBK = ShengJingFanHui_Item12LimitNumberBK,
		},
		-- [13] = {
		-- 	ItemFrame = ShengJingFanHui_PrizeFrame_BK13,
		-- 	ActionItem = ShengJingFanHui_PrizeFrame_BK13_Icon,
		-- 	ItemName = ShengJingFanHui_PrizeFrame_BK13_ItemName,
		-- 	ItemPrice = ShengJingFanHui_PrizeFrame_BK13_ItemMoney,
		-- 	SellOut = ShengJingFanHui_PrizeFrame_BK13_SellOut,
		-- 	LimitMask = ShengJingFanHui_PrizeFrame_BK13_Icon_Mask,
		-- 	LimitBuy = ShengJingFanHui_PrizeFrame_BK13_Icon_BuyLimit,
		-- 	LimitBuyNum = ShengJingFanHui_Item13LimitNumber,
		-- 	ItemNum = ShengJingFanHui_Item13Number,
		-- 	LimitBuyNumBK = ShengJingFanHui_Item13LimitNumberBK,
		-- },
		-- [14] = {
		-- 	ItemFrame = ShengJingFanHui_PrizeFrame_BK14,
		-- 	ActionItem = ShengJingFanHui_PrizeFrame_BK14_Icon,
		-- 	ItemName = ShengJingFanHui_PrizeFrame_BK14_ItemName,
		-- 	ItemPrice = ShengJingFanHui_PrizeFrame_BK14_ItemMoney,
		-- 	SellOut = ShengJingFanHui_PrizeFrame_BK14_SellOut,
		-- 	LimitMask = ShengJingFanHui_PrizeFrame_BK14_Icon_Mask,
		-- 	LimitBuy = ShengJingFanHui_PrizeFrame_BK14_Icon_BuyLimit,
		-- 	LimitBuyNum = ShengJingFanHui_Item14LimitNumber,
		-- 	ItemNum = ShengJingFanHui_Item14Number,
		-- 	LimitBuyNumBK = ShengJingFanHui_Item14LimitNumberBK,
		-- },
		-- [15] = {
		-- 	ItemFrame = ShengJingFanHui_PrizeFrame_BK15,
		-- 	ActionItem = ShengJingFanHui_PrizeFrame_BK15_Icon,
		-- 	ItemName = ShengJingFanHui_PrizeFrame_BK15_ItemName,
		-- 	ItemPrice = ShengJingFanHui_PrizeFrame_BK15_ItemMoney,
		-- 	SellOut = ShengJingFanHui_PrizeFrame_BK15_SellOut,
		-- 	LimitMask = ShengJingFanHui_PrizeFrame_BK15_Icon_Mask,
		-- 	LimitBuy = ShengJingFanHui_PrizeFrame_BK15_Icon_BuyLimit,
		-- 	LimitBuyNum = ShengJingFanHui_Item15LimitNumber,
		-- 	ItemNum = ShengJingFanHui_Item15Number,
		-- 	LimitBuyNumBK = ShengJingFanHui_Item15LimitNumberBK,
		-- },
	}

end