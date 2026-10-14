--!!!reloadscript =BianJing_AuctionZhiPai

local g_BianJing_AuctionZhiPai_UnifiedPosition = ""

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
	
function BianJing_AuctionZhiPai_PreLoad()	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BianJing_AuctionZhiPai_OnLoad()	
	g_BianJing_AuctionZhiPai_UnifiedPosition = BianJing_AuctionZhiPai:GetProperty("UnifiedPosition")
	BianJing_AuctionZhiPai_StopWatch:SetProperty("TextColor","FF00FF00")	
end

function BianJing_AuctionZhiPai_OnEvent(event)
    
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004401 then
		
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
			BianJing_AuctionZhiPai_DownClient2_ReturnBtn:Show()
		else
			BianJing_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
		end
		
		if bShowOrRefresh == 0 then
			
			BianJing_AuctionZhiPai_CleanUp()
			this:Show()
			
			this:Activate()
			BianJing_AuctionZhiPai_Animate1:Play(false)
			BianJing_AuctionZhiPai_Update()
			
			if nObjID and nObjID >= 0 then
				g_CaredObjServerID = nObjID
				local nObjCared = DataPool:GetNPCIDByServerID(g_CaredObjServerID)
				this:CareObject(nObjCared, 1)
			end
			
		elseif bShowOrRefresh == 1 then
			if this:IsVisible() then
				if Get_XParam_INT(9) == 2 then
					BianJing_AuctionZhiPai_Animate1:Play(true)
				end
				BianJing_AuctionZhiPai_CleanUp()
				BianJing_AuctionZhiPai_Update()
			end
		end
		
		return
	end	
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004402 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	--竞拍失败返回刷新
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004403 then
		
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
				BianJing_AuctionZhiPai_DownClient2_ReturnBtn:Show()
			else
				BianJing_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
			end
			
			BianJing_AuctionZhiPai_CleanUp()
			BianJing_AuctionZhiPai_Update()
		end
		return
	end
	
	--竞拍被超了
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004404 then
		if this:IsVisible() then
			if g_BidIndex == Get_XParam_INT(2) and g_uiDataDate == Get_XParam_INT(1) then			
				g_TimeFlag 				= Get_XParam_INT(3)
				g_Top_BiddingPrice		= Get_XParam_INT(4)
				g_My_BiddingPrice		= Get_XParam_INT(5)
				g_CountDownTime			= Get_XParam_INT(6)
				g_Top_BiddingName		= Get_XParam_STR(0)				
				
				BianJing_AuctionZhiPai_Animate1:Play(true)
				BianJing_AuctionZhiPai_Update()
				PushDebugMessage("#{BJPM_200804_149}")
				
				if g_Top_BiddingPrice > 0 then
					BianJing_AuctionZhiPai_DownClient2_ReturnBtn:Show()
				else
					BianJing_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
				end
			end
		end
		return
	end
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004405 then
		g_My_BiddingPrice = 0
		
		local strMyBid = ScriptGlobal_Format("#{BJPM_200804_247}", tostring(g_My_BiddingPrice))
		BianJing_AuctionZhiPai_DownClient2_Info_Test:SetText(tostring(strMyBid))
	
		BianJing_AuctionZhiPai_DownClient2_ReturnBtn:Hide()
		
		local nHaveYB = Player:GetData("YUANBAO")
		local needYB = g_My_Add - g_My_BiddingPrice
		if nHaveYB < needYB then
			BianJing_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
		else
			BianJing_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
		end
		
		return
	end
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004406 then
		if this:IsVisible() then		
			if g_My_BiddingPrice ~= 0 then
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("RefreshBidUI")
					Set_XSCRIPT_ScriptID(440044)
					Set_XSCRIPT_Parameter(0, g_BidIndex)
					Set_XSCRIPT_Parameter(1, g_uiDataDate)
					Set_XSCRIPT_ParamCount(2)
				Send_XSCRIPT()
			end		
		end
		return
	end
	--刷新元宝
	if event == "UPDATE_YUANBAO" then
		local nHaveYB = Player:GetData("YUANBAO")
		local strYuanBao = ScriptGlobal_Format("#{BJPM_200804_119}", tostring(nHaveYB))
		BianJing_AuctionZhiPai_HaveYuQianNum:SetText(strYuanBao)
		
		local needYB = g_My_Add - g_My_BiddingPrice
		if nHaveYB < needYB then
			BianJing_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
		else
			BianJing_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		BianJing_AuctionZhiPai_AdjustPosition()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end

end

function BianJing_AuctionZhiPai_CleanUp()
	BianJing_AuctionZhiPai_Item:SetActionItem(-1)
end

function BianJing_AuctionZhiPai_Update()
	
	--上部
	--BianJing_AuctionZhiPai_ManClient:Hide()
	
	--下部
	BianJing_AuctionZhiPai_DownClient2_Period:Hide()
	BianJing_AuctionZhiPai_DownClient2_End:Hide()
	
	if g_ItemTableIndex > 0 and g_ItemNum > 0 then
		local nShowItemTableIndex = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_ItemTableIndex, "SHOWITEMID")		
		local actionBonus = DataPool:CreateActionItemForShow(nShowItemTableIndex, g_ItemNum)
		if actionBonus:GetID() ~= 0 then
			BianJing_AuctionZhiPai_Item:SetActionItem(actionBonus:GetID())	
		end
	end

	g_BidBasePrice = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_ItemTableIndex, "BASEPRICE")
	g_BidBaseAdd = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_ItemTableIndex, "MINADD")

	g_BidBasePrice = g_BidBasePrice * g_ItemNum
	g_BidBaseAdd = g_BidBaseAdd * g_ItemNum
	
	if g_Top_BiddingPrice == 0 then	
		g_My_Add = g_BidBasePrice
	else
		g_My_Add = g_Top_BiddingPrice + g_BidBaseAdd
	end	
	
	local item_name = DataPool:Lua_GetItemNameByIndex(g_ItemTableIndex)
	
	local strName = ScriptGlobal_Format("#{BJPM_200804_112}", tostring(item_name))	
	BianJing_AuctionZhiPai_ItemName:SetText(strName)
	
	local strCount = ScriptGlobal_Format("#{BJPM_200804_113}", tostring(g_ItemNum))	
	BianJing_AuctionZhiPai_ItemNum:SetText(strCount)
	
	local strTemp = ScriptGlobal_Format("#{BJPM_200804_128}",tostring(g_BidBaseAdd))
	BianJing_AuctionZhiPai_DownClient2_Period3_RaiseAdd:SetToolTip(strTemp)
	
	strTemp = ScriptGlobal_Format("#{BJPM_200804_129}",tostring(g_BidBaseAdd))
	BianJing_AuctionZhiPai_DownClient2_Period3_RaiseSub:SetToolTip(strTemp)
	
	BianJing_AuctionZhiPai_Item_Hint2:Hide()
	
	if g_TimeFlag == 1 then

	elseif g_TimeFlag == 3 then
		BianJing_AuctionZhiPai_Update_BiddingNow(1)
	elseif g_TimeFlag == 4 then
	--	BianJing_AuctionZhiPai_Update_BiddingTimeOut_Waiting()
	elseif g_TimeFlag == 5 then
	--	BianJing_AuctionZhiPai_Update_BiddingTimeOut()
	end
	
end

--竞拍日期，未到竞拍时间
function BianJing_AuctionZhiPai_Update_BiddingDatePre()
	
	--上部
	--BianJing_AuctionZhiPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		BianJing_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		BianJing_AuctionZhiPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		BianJing_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		BianJing_AuctionZhiPai_ManName:SetText("")
	end
	
	local nHaveYB = Player:GetData("YUANBAO")
	--中部
	BianJing_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_134}")
	BianJing_AuctionZhiPai_TimeText2:SetText("#{CJPM_191126_72}")
	BianJing_AuctionZhiPai_TimeText2:Show()
	BianJing_AuctionZhiPai_StopWatch:Hide()
	BianJing_AuctionZhiPai_HaveYuQianNum:SetText("#G"..tostring(nHaveYB))
	
end

--竞拍进行中
function BianJing_AuctionZhiPai_Update_BiddingNow(setTimer)

	--上部
	if g_Top_BiddingPrice > 0 then
		local strTopBid = ScriptGlobal_Format("#{BJPM_200804_122}", tostring(g_Top_BiddingPrice))
		BianJing_AuctionZhiPai_ManMoneyNum:SetText(tostring(strTopBid))
		local strPlayerName = ScriptGlobal_Format("#{BJPM_200804_124}", tostring(g_Top_BiddingName))
		BianJing_AuctionZhiPai_ManName:SetText(tostring(strPlayerName))
	else
		local strTopBid = ScriptGlobal_Format("#{BJPM_200804_122}", tostring(g_BidBasePrice))
		BianJing_AuctionZhiPai_ManMoneyNum:SetText(tostring(strTopBid))
		BianJing_AuctionZhiPai_ManName:SetText("")
	end
	
	local strMyBid = ScriptGlobal_Format("#{BJPM_200804_247}", tostring(g_My_BiddingPrice))
	BianJing_AuctionZhiPai_DownClient2_Info_Test:SetText(tostring(strMyBid))
	
	--中部
	BianJing_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_135}")
	BianJing_AuctionZhiPai_TimeText2:Hide()
	BianJing_AuctionZhiPai_StopWatch:Show()
	if setTimer == 1 then
		BianJing_AuctionZhiPai_StopWatch:SetProperty("Timer",tostring(g_CountDownTime))
	end
	
	local nHaveYB = Player:GetData("YUANBAO")
	local strYuanBao = ScriptGlobal_Format("#{BJPM_200804_119}", tostring(nHaveYB))
	BianJing_AuctionZhiPai_HaveYuQianNum:SetText(strYuanBao)
	
	--下部
	BianJing_AuctionZhiPai_DownClient2_Period:Show()
	
	local strTemp = ""

	local needYB = g_My_Add - g_My_BiddingPrice
	if nHaveYB < needYB then
		BianJing_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
	else
		BianJing_AuctionZhiPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
	end

	local strTemp = ScriptGlobal_Format("#{BJPM_200804_130}", tostring(g_BidBaseAdd))
	BianJing_AuctionZhiPai_DownClient2_Period3_Hint:SetText(strTemp)

end

--竞拍日期，竞拍时间已过 ，结算中
function BianJing_AuctionZhiPai_Update_BiddingTimeOut_Waiting()
	
	--上部
	--BianJing_AuctionZhiPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		BianJing_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		BianJing_AuctionZhiPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		BianJing_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		BianJing_AuctionZhiPai_ManName:SetText("")
	end
	
	local nHaveYB = Player:GetData("YUANBAO")
	--中部
	BianJing_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_135}")
	BianJing_AuctionZhiPai_TimeText2:SetText("#{CJPM_191126_75}")
	BianJing_AuctionZhiPai_TimeText2:Show()
	BianJing_AuctionZhiPai_StopWatch:Hide()	
	BianJing_AuctionZhiPai_StopWatch:SetProperty("Timer",tostring( (g_CountDownTime/1000) + 1 ) )
	BianJing_AuctionZhiPai_HaveYuQianNum:SetText("#G"..tostring(nHaveYB))

	--下部
	BianJing_AuctionZhiPai_DownClient2_End:Show()
	BianJing_AuctionZhiPai_DownClient2_End_Hint:SetText("#{CJPM_191126_88}")
end

--竞拍日期，竞拍时间已过，结算完毕
function BianJing_AuctionZhiPai_Update_BiddingTimeOut()
	
	--上部
	--BianJing_AuctionZhiPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		BianJing_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		BianJing_AuctionZhiPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		BianJing_AuctionZhiPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		BianJing_AuctionZhiPai_ManName:SetText("")
	end
	
	local nHaveYB = Player:GetData("YUANBAO")
	--中部
	BianJing_AuctionZhiPai_TimeText:SetText("#{CJPM_191126_135}")
	BianJing_AuctionZhiPai_TimeText2:SetText("#{CJPM_191126_75}")
	BianJing_AuctionZhiPai_TimeText2:Show()
	BianJing_AuctionZhiPai_StopWatch:Hide()
	BianJing_AuctionZhiPai_HaveYuQianNum:SetText("#G"..tostring(nHaveYB))
	
	--下部
	BianJing_AuctionZhiPai_DownClient2_End:Show()
	BianJing_AuctionZhiPai_DownClient2_End_Hint:SetText("#{CJPM_191126_89}")
end

function BianJing_AuctionZhiPai_Refresh()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RefreshBidUI")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_uiDataDate)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function BianJing_AuctionZhiPai_TimeOut()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RefreshBidUI")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_uiDataDate)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

function BianJing_AuctionZhiPai_AddTokens(flag)

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
		BianJing_AuctionZhiPai_Update_BiddingNow(0)	
	end

end

function BianJing_AuctionZhiPai_NewBidding()	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NewBidding")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_My_Add)
		Set_XSCRIPT_Parameter(2, g_uiDataDate)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

function BianJing_AuctionZhiPai_TakeBackYuanBao()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TakeBackYuanBao")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_BidIndex)
		Set_XSCRIPT_Parameter(1, g_uiDataDate)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function BianJing_AuctionZhiPai_OnHidden()
	BianJing_AuctionZhiPai_CleanUp()
end

function BianJing_AuctionZhiPai_Close()
	this:Hide()
end

function BianJing_AuctionZhiPai_ClickTimeHelp()
	PushEvent("BIANJING_BIDDING_TIME_HELP")
end

function BianJing_AuctionZhiPai_AdjustPosition()
	if g_BianJing_AuctionZhiPai_UnifiedPosition ~= nil then
		BianJing_AuctionZhiPai:SetProperty("UnifiedPosition",g_BianJing_AuctionZhiPai_UnifiedPosition)
	end
end

--!!!reloadscript =BianJing_AuctionZhiPai