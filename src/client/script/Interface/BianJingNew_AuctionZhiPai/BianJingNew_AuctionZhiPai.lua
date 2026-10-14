--!!!reloadscript =BianJingNew_AuctionZhiPai

local g_BianJingNew_AuctionZhiPai_UnifiedPosition = ""

local g_Top_BiddingPrice = 0
local g_My_BiddingPrice = 0
local g_Top_BiddingName = ""

local g_TimeFlag = 1			
--1：竞拍日竞拍未开始
--2：竞拍日竞拍进行中
--3：竞拍结束等待结算
--4：竞拍日竞拍结束

local g_BidBasePrice = 2500
local g_BidBaseAdd = 100
local g_My_Add = 0

local g_CountDownTime = 0

local g_BidIndex = 0
local g_CaredObjServerID = -1

local g_uiDataDate = 0
local g_ItemTableIndex = -1
local g_ItemNum = 0
	
function BianJingNew_AuctionZhiPai_PreLoad()	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_BJB_TOKEN", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BianJingNew_AuctionZhiPai_OnLoad()	
	g_BianJingNew_AuctionZhiPai_UnifiedPosition = BianJingNew_AuctionZhiPai:GetProperty("UnifiedPosition")
	BianJingNew_AuctionZhiPai_StopWatch:SetProperty("TextColor","FF00FF00")	
end

function BianJingNew_AuctionZhiPai_OnEvent(event)
    
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004451 then
		
		local bShowOrRefresh 	= Get_XParam_INT(0)
		g_uiDataDate			= Get_XParam_INT(1)
		g_BidIndex				= Get_XParam_INT(2)
		g_ItemTableIndex		= Get_XParam_INT(3)
		g_ItemNum				= Get_XParam_INT(4)
		g_TimeFlag 				= Get_XParam_INT(5)
		g_Top_BiddingPrice		= Get_XParam_INT(6)
		g_My_BiddingPrice		= Get_XParam_INT(7)
		g_CountDownTime			= Get_XParam_INT(8)
		local nObjID			= Get_XParam_INT(10)
		local showTakeBack		= Get_XParam_INT(11)
		g_Top_BiddingName		= Get_XParam_STR(0)
		
		--PushDebugMessage(tostring(g_uiDataDate).."-"..tostring(g_BidIndex).."-"..tostring(g_TimeFlag).."-"..tostring(bShowOrRefresh))
		if showTakeBack == 1 and g_My_BiddingPrice > 0 then
			BianJingNew_AuctionZhiPai_DownClient2_ReturnBtn:Show()
		else
			BianJingNew_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
		end
		
		if bShowOrRefresh == 0 then
			
			BianJingNew_AuctionZhiPai_CleanUp()
			this:Show()
			
			this:Activate()
			BianJingNew_AuctionZhiPai_Animate1:Play(false)
			BianJingNew_AuctionZhiPai_Update()
			
			if nObjID and nObjID >= 0 then
				g_CaredObjServerID = nObjID
				local nObjCared = DataPool:GetNPCIDByServerID(g_CaredObjServerID)
				this:CareObject(nObjCared, 1)
			end
			
		elseif bShowOrRefresh == 1 then
			if this:IsVisible() then
				if Get_XParam_INT(9) == 2 then
					BianJingNew_AuctionZhiPai_Animate1:Play(true)
				end
				BianJingNew_AuctionZhiPai_CleanUp()
				BianJingNew_AuctionZhiPai_Update()
			end
		end
		
		return
	end	
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004452 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	--竞拍失败返回刷新
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004453 then
		
		if this:IsVisible() then

			g_uiDataDate			= Get_XParam_INT(1)
			g_BidIndex				= Get_XParam_INT(2)
			g_ItemTableIndex		= Get_XParam_INT(3)
			g_ItemNum				= Get_XParam_INT(4)
			g_TimeFlag 				= Get_XParam_INT(5)
			g_Top_BiddingPrice		= Get_XParam_INT(6)
			g_My_BiddingPrice		= Get_XParam_INT(7)
			g_CountDownTime			= Get_XParam_INT(8)
			local showTakeBack		= Get_XParam_INT(9)
			g_Top_BiddingName		= Get_XParam_STR(0)
			
			if showTakeBack == 1 and g_My_BiddingPrice > 0 then
				BianJingNew_AuctionZhiPai_DownClient2_ReturnBtn:Show()
			else
				BianJingNew_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
			end
			
			BianJingNew_AuctionZhiPai_CleanUp()
			BianJingNew_AuctionZhiPai_Update()
		end
		return
	end
	
	--竞拍被超了
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004454 then
		if this:IsVisible() then
			if g_BidIndex == Get_XParam_INT(2) and g_uiDataDate == Get_XParam_INT(1) then			
				g_TimeFlag 				= Get_XParam_INT(3)
				g_Top_BiddingPrice		= Get_XParam_INT(4)
				g_My_BiddingPrice		= Get_XParam_INT(5)
				g_CountDownTime			= Get_XParam_INT(6)
				g_Top_BiddingName		= Get_XParam_STR(0)				
				
				BianJingNew_AuctionZhiPai_Animate1:Play(true)
				BianJingNew_AuctionZhiPai_Update()
				PushDebugMessage("#{BJPM_200804_149}")
				
				if g_Top_BiddingPrice > 0 then
					BianJingNew_AuctionZhiPai_DownClient2_ReturnBtn:Show()
				else
					BianJingNew_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
				end
			end
		end
		return
	end
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004455 then
		g_My_BiddingPrice = 0
		
		local strMyBid = ScriptGlobal_Format("#{BJPM_200804_247}", tostring(g_My_BiddingPrice))
		BianJingNew_AuctionZhiPai_DownClient2_Info_Test:SetText(tostring(strMyBid))
	
		BianJingNew_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
		
		local nTokens = Player:LuaFnGetBJBToken()
		local needTokens = g_My_Add - g_My_BiddingPrice
		if nTokens < needTokens then
			BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
		else
			BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
		end
		
		return
	end
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004456 then
		if this:IsVisible() then		
			if g_My_BiddingPrice ~= 0 then
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("RefreshTokenBidUI")
					Set_XSCRIPT_ScriptID(440044)
					Set_XSCRIPT_Parameter(0, g_BidIndex)
					Set_XSCRIPT_Parameter(1, g_uiDataDate)
					Set_XSCRIPT_ParamCount(2)
				Send_XSCRIPT()
			end		
		end
		return
	end
	--刷新代币
	if event == "UPDATE_BJB_TOKEN" then
		local nTokens = Player:LuaFnGetBJBToken()
		local strTokens = ScriptGlobal_Format("#{BJPM_200804_119}", tostring(nTokens))
		BianJingNew_AuctionZhiPai_HaveYuQianNum:SetText(strTokens)
		
		local needTokens = g_My_Add - g_My_BiddingPrice
		if nTokens < needTokens then
			BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
		else
			BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		BianJingNew_AuctionZhiPai_AdjustPosition()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end

end

function BianJingNew_AuctionZhiPai_CleanUp()
	BianJingNew_AuctionZhiPai_Item:SetActionItem(-1)
end

function BianJingNew_AuctionZhiPai_Update()
	
	--上部
	--BianJingNew_AuctionZhiPai_ManClient:Hide()
	
	--下部
	BianJingNew_AuctionZhiPai_DownClient2_Period:Hide()
	BianJingNew_AuctionZhiPai_DownClient2_End:Hide()
	
	if g_ItemTableIndex > 0 and g_ItemNum > 0 then
		local nShowItemTableIndex = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_ItemTableIndex, "SHOWITEMID")		
		local actionBonus = DataPool:CreateActionItemForShow(nShowItemTableIndex, g_ItemNum)
		if actionBonus:GetID() ~= 0 then
			BianJingNew_AuctionZhiPai_Item:SetActionItem(actionBonus:GetID())	
		end
	end

	g_BidBasePrice = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_ItemTableIndex, "BASETOKEN")
	g_BidBaseAdd = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_ItemTableIndex, "MINADDTOKEN")

	g_BidBasePrice = g_BidBasePrice * g_ItemNum
	g_BidBaseAdd = g_BidBaseAdd * g_ItemNum
	
	if g_Top_BiddingPrice == 0 then	
		g_My_Add = g_BidBasePrice
	else
		g_My_Add = g_Top_BiddingPrice + g_BidBaseAdd
	end	
	
	local item_name = DataPool:Lua_GetItemNameByIndex(g_ItemTableIndex)
	
	local strName = ScriptGlobal_Format("#{BJPM_200804_112}", tostring(item_name))	
	BianJingNew_AuctionZhiPai_ItemName:SetText(strName)
	
	local strCount = ScriptGlobal_Format("#{BJPM_200804_113}", tostring(g_ItemNum))	
	BianJingNew_AuctionZhiPai_ItemNum:SetText(strCount)
	
	local strTemp = ScriptGlobal_Format("#{BJPM_210511_22}",tostring(g_BidBaseAdd))
	BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseAdd:SetToolTip(strTemp)
	
	strTemp = ScriptGlobal_Format("#{BJPM_210511_23}",tostring(g_BidBaseAdd))
	BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseSub:SetToolTip(strTemp)
	
	BianJingNew_AuctionZhiPai_Item_Hint2:Hide()
	
	if g_TimeFlag == 1 then

	elseif g_TimeFlag == 3 then
		BianJingNew_AuctionZhiPai_Update_BiddingNow(1)
	elseif g_TimeFlag == 4 then
	--	BianJingNew_AuctionZhiPai_Update_BiddingTimeOut_Waiting()
	elseif g_TimeFlag == 5 then
	--	BianJingNew_AuctionZhiPai_Update_BiddingTimeOut()
	end
	
end

--竞拍日期，未到竞拍时间
function BianJingNew_AuctionZhiPai_Update_BiddingDatePre()
	
	--上部
	--BianJingNew_AuctionZhiPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		--BianJingNew_AuctionZhiPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		--BianJingNew_AuctionZhiPai_ManName:SetText("")
	end
	
	local nTokens = Player:LuaFnGetBJBToken()
	--中部
	BianJingNew_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_134}")
	BianJingNew_AuctionZhiPai_TimeText2:SetText("#{CJPM_191126_72}")
	BianJingNew_AuctionZhiPai_TimeText2:Show()
	BianJingNew_AuctionZhiPai_StopWatch:Hide()
	BianJingNew_AuctionZhiPai_HaveYuQianNum:SetText("#G"..tostring(nTokens))
	
end

--竞拍进行中
function BianJingNew_AuctionZhiPai_Update_BiddingNow(setTimer)

	--上部
	if g_Top_BiddingPrice > 0 then
		local strTopBid = ScriptGlobal_Format("#{BJPM_200804_122}", tostring(g_Top_BiddingPrice))
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText(tostring(strTopBid))
		local strPlayerName = ScriptGlobal_Format("#{BJPM_200804_124}", tostring(g_Top_BiddingName))
		--BianJingNew_AuctionZhiPai_ManName:SetText(tostring(strPlayerName))
	else
		local strTopBid = ScriptGlobal_Format("#{BJPM_200804_122}", tostring(g_BidBasePrice))
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText(tostring(strTopBid))
		--BianJingNew_AuctionZhiPai_ManName:SetText("")
	end
	
	local strMyBid = ScriptGlobal_Format("#{BJPM_200804_247}", tostring(g_My_BiddingPrice))
	BianJingNew_AuctionZhiPai_DownClient2_Info_Test:SetText(tostring(strMyBid))
	
	--中部
	BianJingNew_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_135}")
	BianJingNew_AuctionZhiPai_TimeText2:Hide()
	BianJingNew_AuctionZhiPai_StopWatch:Show()
	if setTimer == 1 then
		BianJingNew_AuctionZhiPai_StopWatch:SetProperty("Timer",tostring(g_CountDownTime))
	end
	
	local nTokens = Player:LuaFnGetBJBToken()
	local strTokens = ScriptGlobal_Format("#{BJPM_200804_119}", tostring(nTokens))
	BianJingNew_AuctionZhiPai_HaveYuQianNum:SetText(strTokens)
	
	--下部
	BianJingNew_AuctionZhiPai_DownClient2_Period:Show()
	
	local strTemp = ""
	local needTokens = g_My_Add - g_My_BiddingPrice
	if nTokens < needTokens then
		BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
	else
		BianJingNew_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
	end

	local strTemp = ScriptGlobal_Format("#{BJPM_210511_24}", tostring(g_BidBaseAdd))
	BianJingNew_AuctionZhiPai_DownClient2_Period3_Hint:SetText(strTemp)

end

--竞拍日期，竞拍时间已过 ，结算中
function BianJingNew_AuctionZhiPai_Update_BiddingTimeOut_Waiting()
	
	--上部
	--BianJingNew_AuctionZhiPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		--BianJingNew_AuctionZhiPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		--BianJingNew_AuctionZhiPai_ManName:SetText("")
	end
	
	local nTokens = Player:LuaFnGetBJBToken()
	--中部
	BianJingNew_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_135}")
	BianJingNew_AuctionZhiPai_TimeText2:SetText("#{CJPM_191126_75}")
	BianJingNew_AuctionZhiPai_TimeText2:Show()
	BianJingNew_AuctionZhiPai_StopWatch:Hide()	
	BianJingNew_AuctionZhiPai_StopWatch:SetProperty("Timer",tostring( (g_CountDownTime/1000) + 1 ) )
	BianJingNew_AuctionZhiPai_HaveYuQianNum:SetText("#G"..tostring(nTokens))

	--下部
	BianJingNew_AuctionZhiPai_DownClient2_End:Show()
	BianJingNew_AuctionZhiPai_DownClient2_End_Hint:SetText("#{CJPM_191126_88}")
end

--竞拍日期，竞拍时间已过，结算完毕
function BianJingNew_AuctionZhiPai_Update_BiddingTimeOut()
	
	--上部
	--BianJingNew_AuctionZhiPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		--BianJingNew_AuctionZhiPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		BianJingNew_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		--BianJingNew_AuctionZhiPai_ManName:SetText("")
	end
	
	local nTokens = Player:LuaFnGetBJBToken()
	--中部
	BianJingNew_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_135}")
	BianJingNew_AuctionZhiPai_TimeText2:SetText("#{CJPM_191126_75}")
	BianJingNew_AuctionZhiPai_TimeText2:Show()
	BianJingNew_AuctionZhiPai_StopWatch:Hide()
	BianJingNew_AuctionZhiPai_HaveYuQianNum:SetText("#G"..tostring(nTokens))
	
	--下部
	BianJingNew_AuctionZhiPai_DownClient2_End:Show()
	BianJingNew_AuctionZhiPai_DownClient2_End_Hint:SetText("#{CJPM_191126_89}")
end

function BianJingNew_AuctionZhiPai_Refresh()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RefreshTokenBidUI")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_uiDataDate)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function BianJingNew_AuctionZhiPai_TimeOut()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RefreshTokenBidUI")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_uiDataDate)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

function BianJingNew_AuctionZhiPai_AddTokens(flag)

	if flag > 0 then
		g_My_Add = g_My_Add + g_BidBaseAdd
	else
		g_My_Add = g_My_Add - g_BidBaseAdd
		
		if g_Top_BiddingPrice == 0 then
			if g_My_Add < g_BidBasePrice then
				g_My_Add = g_BidBasePrice
			end
		else
			if g_My_Add < g_Top_BiddingPrice + g_BidBaseAdd then
				g_My_Add = g_Top_BiddingPrice + g_BidBaseAdd
			end
		end
	end
	
	if g_TimeFlag == 3 then
		BianJingNew_AuctionZhiPai_Update_BiddingNow(0)	
	end

end

function BianJingNew_AuctionZhiPai_NewBidding()	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NewTokenBidding")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_My_Add)
		Set_XSCRIPT_Parameter(2, g_uiDataDate)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

function BianJingNew_AuctionZhiPai_TakeBackYuanBao()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TakeBackToken")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_uiDataDate)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function BianJingNew_AuctionZhiPai_OnHidden()
	BianJingNew_AuctionZhiPai_CleanUp()
end

function BianJingNew_AuctionZhiPai_Close()
	this:Hide()
end

function BianJingNew_AuctionZhiPai_ClickTimeHelp()
	PushEvent("BIANJING_BIDDING_TIME_HELP")
end

function BianJingNew_AuctionZhiPai_AdjustPosition()
	if g_BianJingNew_AuctionZhiPai_UnifiedPosition ~= nil then
		BianJingNew_AuctionZhiPai:SetProperty("UnifiedPosition",g_BianJingNew_AuctionZhiPai_UnifiedPosition)
	end
end

--!!!reloadscript =BianJingNew_AuctionZhiPai