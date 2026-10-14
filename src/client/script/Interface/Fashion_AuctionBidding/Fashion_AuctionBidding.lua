--!!!reloadscript =Fashion_AuctionBidding

local g_Fashion_AuctionBidding_Frame_UnifiedPosition

local g_CurSection = 0

local g_CurGroupIndex = -1

local g_OfferBid = 0
local g_MaxPrice = 9999999

local g_Follow_Img = {
	normal = "set:Button1 image:BtnHelp_Normal",
	hover = "set:Button1 image:BtnHelp_Hover",
	pushed = "set:Button1 image:BtnHelp_Pushed",
}

local g_Not_Follow_Img = {
	normal = "set:Button1 image:BtnClose_Normal",
	hover = "set:Button1 image:BtnClose_Hover",
	pushed = "set:Button1 image:BtnClose_Pushed",
}


function Fashion_AuctionBidding_PreLoad()
	this:RegisterEvent("OPEN_FASHION_AUCTION_BIDDING")
	this:RegisterEvent("UPDATE_FASHION_AUCTION_CURRENT_BIDDING")
	this:RegisterEvent("UPDATE_FASHION_AUCTION_CERTAIN_BIDDING")
	--player quit game
	this:RegisterEvent("PLAYER_LEAVE_WORLD")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("UPDATE_YUANBAO")
	this:RegisterEvent("UI_COMMAND")
end

function Fashion_AuctionBidding_OnLoad()
	g_Fashion_AuctionBidding_Frame_UnifiedPosition = Fashion_AuctionBidding_Frame:GetProperty("UnifiedPosition")
end

function Fashion_AuctionBidding_OnEvent(event)

	if event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
		return
	end
	
	if event == "OPEN_FASHION_AUCTION_BIDDING" then
		g_CurSection = tonumber(arg0)
		g_CurGroupIndex = tonumber(arg1)
		if this:IsVisible() then
			Fashion_AuctionBidding_Update()
			return
		end
		
		this:Show()
		Fashion_AuctionBidding_OnShown()
		Fashion_AuctionBidding_Update()
		return
	end
	
	if event == "UPDATE_FASHION_AUCTION_CURRENT_BIDDING" and this:IsVisible() then
		g_CurSection = tonumber(arg0)
		g_CurGroupIndex = tonumber(arg1)
		Fashion_AuctionBidding_Update()
	end
	
	if event == "UPDATE_FASHION_AUCTION_CERTAIN_BIDDING" and this:IsVisible() then
		if g_CurSection == tonumber(arg0) and g_CurGroupIndex == tonumber(arg1) then
			Fashion_AuctionBidding_Update()
		end
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		-- 更新背包界面位置
		Fashion_AuctionBidding_Frame_On_ResetPos()
	end
	
	if event == "UPDATE_YUANBAO" and this:IsVisible() then
		local my_yb = Player:GetData("YUANBAO")
		--local strTemp = ScriptGlobal_Format("#{WHTJ_240117_66}", tostring(my_yb))	
		Fashion_AuctionBidding_YuanbaoNum:SetText("#cfff263"..tostring(my_yb))
	end

end

function Fashion_AuctionBidding_OnShown()

end

--Update
function Fashion_AuctionBidding_Update()
	
	local strTemp = ""
	Fashion_AuctionBidding_CleanUp()
	
	--道具ID
	local nItemTableIndex = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "ITEMID")
	--道具数量
	local uItemNum = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "ITEMNUM")
	--最高出价
	local nHighPrice = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "TOPBID")
	--最高出价人姓名
	local nHighName = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "NAME")
	--最高出价人的世界号
	local nHighZoneWorld = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "TOPWORLD")	
	--当前时间标志
	local nTimeFlag = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "TIMEFLAG")
	--底价
	local nBaseValue = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "BASEPRICE")
	--是否有人出价
	local nHaveBid = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "HAVEBID")
	--当前是否是最高出价人
	local bIsTop = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "ISTOP")
	--加价幅度
	local nMinAdd = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "MINADD")
	
	if nHaveBid == 1 then
		if tonumber(nHighZoneWorld) ~= nil and tonumber(nHighZoneWorld) >= 0 then
			local nHighZoneWorldName = DataPool:GetServerName(tonumber(nHighZoneWorld))
			nHighName = nHighName.."@"..tostring(nHighZoneWorldName)
		end
		nMinAdd = math.ceil(nHighPrice * 0.05)
		g_OfferBid = nHighPrice + nMinAdd
		if g_OfferBid > g_MaxPrice then
			g_OfferBid = g_MaxPrice
		end
	else
		g_OfferBid = nBaseValue
	end
	
	Fashion_AuctionBidding_Item:SetActionItem(-1)
	local theAction = DataPool:CreateActionItemForShow(nItemTableIndex, uItemNum)
	if theAction:GetID() ~= 0 then
		Fashion_AuctionBidding_Item:SetActionItem(theAction:GetID())
	end
	
	local item_name = DataPool:Lua_GetItemNameByIndex(nItemTableIndex)
	strTemp = ScriptGlobal_Format("#{WHTJ_240117_58}", item_name)
	Fashion_AuctionBidding_ItemInfo_Text1:SetText(strTemp)
	
	Fashion_AuctionBidding_ItemInfo_Text2:SetText("#{WHTJ_240117_59}")
	
	if nTimeFlag == 1 or nTimeFlag == 2 then
		strTemp = ScriptGlobal_Format("#{WHTJ_240117_62}", tostring(nBaseValue))
		Fashion_AuctionBidding_HighestNum:SetText(strTemp)
		Fashion_AuctionBidding_MineNum:SetText("#{WHTJ_240117_65}")
	elseif nTimeFlag == 3 or nTimeFlag == 4 or nTimeFlag == 5 then
		if nHaveBid == 0 then
			strTemp = ScriptGlobal_Format("#{WHTJ_240117_62}", tostring(nBaseValue))
			Fashion_AuctionBidding_HighestNum:SetText(strTemp)
			Fashion_AuctionBidding_MineNum:SetText("#{WHTJ_240117_65}")
		else
			if bIsTop == 1 then
				strTemp = ScriptGlobal_Format("#{WHTJ_240117_62}", tostring(nHighPrice))
				Fashion_AuctionBidding_HighestNum:SetText(strTemp)
				Fashion_AuctionBidding_MineNum:SetText("#{WHTJ_240117_64}")
			else
				strTemp = ScriptGlobal_Format("#{WHTJ_240117_62}", tostring(nHighPrice))
				Fashion_AuctionBidding_HighestNum:SetText(strTemp)
				Fashion_AuctionBidding_MineNum:SetText("#{WHTJ_240117_65}")
			end
		end
	end
	
	local my_yb = Player:GetData("YUANBAO")
	--strTemp = ScriptGlobal_Format("#{WHTJ_240117_66}", tostring(my_yb))	
	Fashion_AuctionBidding_YuanbaoNum:SetText("#cfff263"..tostring(my_yb))
	
	--PushDebugMessage(tostring(nTimeFlag))
	if nTimeFlag == 1 or nTimeFlag == 2 then
		Fashion_AuctionBidding_NotStarted:Show()
		Fashion_AuctionBidding_NumBK:Hide()
		Fashion_AuctionBidding_ButtonFrame:Hide()
		Fashion_AuctionBidding_NotStarted:SetText("#{WHTJ_240117_77}")
	elseif nTimeFlag == 3 then
		Fashion_AuctionBidding_NotStarted:Hide()
		Fashion_AuctionBidding_NumBK:Show()
		Fashion_AuctionBidding_ButtonFrame:Show()
	else
		Fashion_AuctionBidding_NotStarted:Show()
		Fashion_AuctionBidding_NumBK:Hide()
		Fashion_AuctionBidding_ButtonFrame:Hide()
		Fashion_AuctionBidding_NotStarted:SetText("#{WHTJ_240117_78}")
	end
	
	strTemp = ScriptGlobal_Format("#{WHTJ_240117_76}", tostring(nMinAdd))
	Fashion_AuctionBidding_RaiseSub:SetToolTip(strTemp)
	strTemp = ScriptGlobal_Format("#{WHTJ_240117_75}", tostring(nMinAdd))
	Fashion_AuctionBidding_RaiseAdd:SetToolTip(strTemp)
	
	Fashion_AuctionBidding_Num:SetText(tostring(g_OfferBid))
	local nMinValue = 0
	local nMaxValue = Player:GetData("YUANBAO")
	
	if nHaveBid == 0 then
		nMinValue = nBaseValue
	else
		nMinValue = nHighPrice + nMinAdd
	end
	
	if g_OfferBid <= 0 then
		Fashion_AuctionBidding_RaiseSub:Disable()
	else
		Fashion_AuctionBidding_RaiseSub:Enable()
	end
	
	if g_OfferBid >= nMaxValue then
		Fashion_AuctionBidding_RaiseAdd:Disable()
	else
		Fashion_AuctionBidding_RaiseAdd:Enable()
	end
	
	local canBidValue = nBaseValue
	if nHaveBid == 1 then
		canBidValue = nHighPrice + 1
	end
	
	if g_OfferBid >= canBidValue then
		Fashion_AuctionBidding_Submit:Enable()
	else
		Fashion_AuctionBidding_Submit:Disable()
	end
	
	if g_OfferBid < nMinValue then
		if g_OfferBid == g_MaxPrice and nMinValue > g_MaxPrice then
		--	Fashion_AuctionBidding_Submit:Enable()
		else
		--	Fashion_AuctionBidding_Submit:Disable()
		end
	else
	--	Fashion_AuctionBidding_Submit:Enable()
	end
	
	local CountDownTime = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "COUNTDOWN")
	--PushDebugMessage(tostring(CountDownTime))
	Fashion_AuctionBidding_ItemInfo_StopWatch:SetProperty("Timer", tostring(CountDownTime))
end

function Fashion_AuctionBidding_TimeOut()

end

function Fashion_AuctionBidding_CleanUp()
	Fashion_AuctionBidding_Item:SetActionItem(-1)
	Fashion_AuctionBidding_NotStarted:Hide()
	Fashion_AuctionBidding_NumBK:Hide()
	Fashion_AuctionBidding_ButtonFrame:Hide()
end

function Fashion_AuctionBidding_CloseClicked()
	this:Hide()
end

function Fashion_AuctionBidding_OnHidden()
	Fashion_AuctionBidding_CleanUp()
end

function Fashion_AuctionBidding_AddYuanBao(flag)
	
	--最高出价
	local nHighPrice = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "TOPBID")
	--底价
	local nBaseValue = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "BASEPRICE")
	--是否有人出价
	local nHaveBid = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "HAVEBID")
	--加价幅度
	local nMinAdd = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "MINADD")
	
	local nMinValue = 0
	local nMaxValue = Player:GetData("YUANBAO")
	
	if nHaveBid == 0 then
		nMinValue = nBaseValue
	else
		nMinAdd = math.ceil(nHighPrice * 0.05)
		nMinValue = nHighPrice + nMinAdd
	end
	
	local nString = Fashion_AuctionBidding_Num:GetText()
	local nCurNum = 0
	if nString == nil or nString == "" then
		nCurNum = 0
	else
		nCurNum = tonumber(nString)
	end

	if flag == 0 then
		if nCurNum > nMinValue then
			nCurNum = nCurNum - nMinAdd
			if nCurNum < nMinValue then
				nCurNum = nMinValue
			end
			g_OfferBid = nCurNum
			Fashion_AuctionBidding_Num:SetText(tostring(g_OfferBid))
		end
	else
		if nCurNum < nMaxValue then
			nCurNum = nCurNum + nMinAdd
			if nCurNum > nMaxValue then
				nCurNum = nMaxValue
			end
			g_OfferBid = nCurNum
			Fashion_AuctionBidding_Num:SetText(tostring(g_OfferBid))
		end
	end
	
	if g_OfferBid <= 0 then
		Fashion_AuctionBidding_RaiseSub:Disable()
	else
		Fashion_AuctionBidding_RaiseSub:Enable()
	end
	
	if g_OfferBid >= nMaxValue then
		Fashion_AuctionBidding_RaiseAdd:Disable()
	else
		Fashion_AuctionBidding_RaiseAdd:Enable()
	end
	
	local canBidValue = nBaseValue
	if nHaveBid == 1 then
		canBidValue = nHighPrice + 1
	end
	
	if g_OfferBid >= canBidValue then
		Fashion_AuctionBidding_Submit:Enable()
	else
		Fashion_AuctionBidding_Submit:Disable()
	end
	
	if g_OfferBid < nMinValue then
		if g_OfferBid == g_MaxPrice and nMinValue > g_MaxPrice then
		--	Fashion_AuctionBidding_Submit:Enable()
		else
		--	Fashion_AuctionBidding_Submit:Disable()
		end
	else
	--	Fashion_AuctionBidding_Submit:Enable()
	end
	
end

function Fashion_AuctionBidding_TextChanged()
	local nString = Fashion_AuctionBidding_Num:GetText()
	if nString == nil or nString == "" then
		Fashion_AuctionBidding_Submit:Disable()
		Fashion_AuctionBidding_RaiseSub:Disable()
		Fashion_AuctionBidding_RaiseAdd:Enable()
		return
	end
	
	--最高出价
	local nHighPrice = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "TOPBID")
	--底价
	local nBaseValue = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "BASEPRICE")
	--是否有人出价
	local nHaveBid = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "HAVEBID")
	--加价幅度
	local nMinAdd = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "MINADD")
	
	local nMinValue = 0
	local nMaxValue = Player:GetData("YUANBAO")
	
	if nHaveBid == 0 then
		nMinValue = nBaseValue
	else
		nMinAdd = math.ceil(nHighPrice * 0.05)
		nMinValue = nHighPrice + nMinAdd
	end

	local nChangNum = tonumber(nString)
	
	local nMaxValue = Player:GetData("YUANBAO")
	if nChangNum >= nMaxValue then
		nChangNum = nMaxValue
	end
	
	if g_OfferBid ~= tonumber(nString) then
		g_OfferBid = nChangNum
		Fashion_AuctionBidding_Num:SetText(tostring(g_OfferBid))
	end
	
	if g_OfferBid <= 0 then
		Fashion_AuctionBidding_RaiseSub:Disable()
	else
		Fashion_AuctionBidding_RaiseSub:Enable()
	end
	
	if g_OfferBid >= nMaxValue then
		Fashion_AuctionBidding_RaiseAdd:Disable()
	else
		Fashion_AuctionBidding_RaiseAdd:Enable()
	end
	
	local canBidValue = nBaseValue
	if nHaveBid == 1 then
		canBidValue = nHighPrice + 1
	end
	
	if g_OfferBid >= canBidValue then
		Fashion_AuctionBidding_Submit:Enable()
	else
		Fashion_AuctionBidding_Submit:Disable()
	end
	
	if g_OfferBid < nMinValue then
		if g_OfferBid == g_MaxPrice and nMinValue > g_MaxPrice then
		--	Fashion_AuctionBidding_Submit:Enable()
		else
		--	Fashion_AuctionBidding_Submit:Disable()
		end
	else
	--	Fashion_AuctionBidding_Submit:Enable()
	end
end

function Fashion_AuctionBidding_Refresh()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenBidUI")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_Parameter(0, 1)								--打开
		Set_XSCRIPT_Parameter(1, tonumber(g_CurSection))		--索引
		Set_XSCRIPT_Parameter(2, tonumber(g_CurGroupIndex))		--索引
		Set_XSCRIPT_Parameter(3, 1)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function Fashion_AuctionBidding_DoBidding()
	local nString = Fashion_AuctionBidding_Num:GetText()
	if nString == nil or nString == "" then
		return
	end
	
	--最高出价
	local nHighPrice = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "TOPBID")
	--底价
	local nBaseValue = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "BASEPRICE")
	--是否有人出价
	local nHaveBid = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "HAVEBID")
	--加价幅度
	local nMinAdd = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, g_CurGroupIndex, "MINADD")
	
	local nMinValue = 0
	local nMaxValue = Player:GetData("YUANBAO")
	
	if nHaveBid == 0 then
		nMinValue = nBaseValue
	else
		nMinAdd = math.ceil(nHighPrice * 0.05)
		nMinValue = nHighPrice + nMinAdd
	end
	
	if nMinValue <= g_MaxPrice then
		if tonumber(nString) < nMinValue then
			g_OfferBid = nMinValue
			Fashion_AuctionBidding_Num:SetText(tostring(g_OfferBid))
			PushDebugMessage("#{WHTJ_240117_87}")
			return
		end
	else
		if tonumber(nString) < g_MaxPrice then
			g_OfferBid = g_MaxPrice
			Fashion_AuctionBidding_Num:SetText(tostring(g_OfferBid))
			PushDebugMessage("#{WHTJ_240117_113}")
			return
		end
	end
	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NewBidding")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_Parameter(0, tonumber(g_CurSection))		--
		Set_XSCRIPT_Parameter(1, tonumber(g_CurGroupIndex))		--索引
		Set_XSCRIPT_Parameter(2, tonumber(nString))				--索引
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function Fashion_AuctionBidding_Frame_On_ResetPos()
	Fashion_AuctionBidding_Frame:SetProperty("UnifiedPosition", g_Fashion_AuctionBidding_Frame_UnifiedPosition)
end
