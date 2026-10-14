
--!!!reloadscript =ChunJie_AuctionJingPai

local g_ChunJie_AuctionJingPai_UnifiedPosition = ""

local g_Bid_Round = 0		--当前竞拍的轮次
local g_Top_BiddingPrice = 0
local g_My_BiddingPrice = 0
local g_Top_BiddingName = ""

local g_BidOrTakeBack = 0		--0：竞拍 1：取回
local g_TimeFlag = 1			
--1：竞拍日竞拍未开始
--2：竞拍日竞拍进行中
--3：竞拍结束等待结算
--4：竞拍日竞拍结束

local g_BonusOrTokens = 0		--0: 获胜 1：失败

local g_BidBasePrice = 2500
local g_BidBaseAdd = 100
local g_My_Add = 0

local g_CountDownTime = 0

local g_BonusItem = 0

local g_CurRound = 0
local g_CurIndex = 0

function ChunJie_AuctionJingPai_PreLoad()
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
	
end

function ChunJie_AuctionJingPai_OnLoad()	
	g_ChunJie_AuctionJingPai_UnifiedPosition = ChunJie_AuctionJingPai:GetProperty("UnifiedPosition")
	ChunJie_AuctionJingPai_StopWatch:SetProperty("TextColor","FF00FF00")	
end

function ChunJie_AuctionJingPai_OnEvent(event)
    
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000301 then
		
		local bShowOrRefresh 	= Get_XParam_INT(0)
		g_CurRound				= Get_XParam_INT(1)
		g_CurIndex				= Get_XParam_INT(2) + 1
		g_TimeFlag 				= Get_XParam_INT(3)
		g_Top_BiddingPrice		= Get_XParam_INT(4)
		g_My_BiddingPrice		= Get_XParam_INT(5)
		g_CountDownTime			= Get_XParam_INT(6)
		g_Top_BiddingName		= Get_XParam_STR(0)
		
	--	PushDebugMessage(tostring(g_CurRound).."-"..tostring(g_CurIndex).."-"..tostring(g_TimeFlag))
		
		if bShowOrRefresh == 0 then
			ChunJie_AuctionJingPai_CleanUp()
			this:Show()
			this:Activate()
			ChunJie_AuctionJingPai_Animate1:Play(false)
			ChunJie_AuctionJingPai_Update()
		elseif bShowOrRefresh == 1 then
			if this:IsVisible() then
				if Get_XParam_INT(8) == 2 then
					ChunJie_AuctionJingPai_Animate1:Play(true)
				end
				ChunJie_AuctionJingPai_CleanUp()
				ChunJie_AuctionJingPai_Update()
			end
		end
		
		return
	end	
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000302 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000309 then
		if this:IsVisible() then
			PushDebugMessage("#{CJPM_191126_116}")
			this:Hide()
		end
		return
	end
	
	--竞拍失败返回刷新
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000303 then
		
		if this:IsVisible() then

			g_CurRound				= Get_XParam_INT(1)
			g_CurIndex				= Get_XParam_INT(2) + 1
			g_TimeFlag 				= Get_XParam_INT(3)
			g_Top_BiddingPrice		= Get_XParam_INT(4)
			g_My_BiddingPrice		= Get_XParam_INT(5)
			g_CountDownTime			= Get_XParam_INT(6)
			g_Top_BiddingName		= Get_XParam_STR(0)
			
			ChunJie_AuctionJingPai_CleanUp()
			ChunJie_AuctionJingPai_Update()
		end
		return
	end
	
	--竞拍被超了
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000304 then
		
		if this:IsVisible() then
			
			if g_CurRound == Get_XParam_INT(1) and g_CurIndex == (Get_XParam_INT(2) + 1) then			
			
				g_CurRound				= Get_XParam_INT(1)
				g_CurIndex				= Get_XParam_INT(2) + 1
				g_TimeFlag 				= Get_XParam_INT(3)
				g_Top_BiddingPrice		= Get_XParam_INT(4)
				g_My_BiddingPrice		= Get_XParam_INT(5)
				g_CountDownTime			= Get_XParam_INT(6)
				g_Top_BiddingName		= Get_XParam_STR(0)
				
				ChunJie_AuctionJingPai_Animate1:Play(true)
				ChunJie_AuctionJingPai_Update()
				PushDebugMessage("#{CJPM_191126_102}")
			end
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ChunJie_AuctionJingPai_AdjustPosition()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	--刷新元宝
	if event == "UPDATE_YUANBAO" and this:IsVisible() then
		ChunJie_AuctionJingPai_HaveYuQianNum:SetText("#G"..tostring(Player:GetData("YUANBAO")))
		return
	end

end

function ChunJie_AuctionJingPai_CleanUp()
	ChunJie_AuctionJingPai_Item:SetActionItem(-1)
end

function ChunJie_AuctionJingPai_Update()
	
	--上部
	--ChunJie_AuctionJingPai_ManClient:Hide()
	
	--下部
	ChunJie_AuctionJingPai_DownClient2_Period:Hide()
	ChunJie_AuctionJingPai_DownClient2_End:Hide()
	
	local nBonusItemIndex = DataPool:Lua_GetSpringFestivalBonusInfo(g_CurRound, g_CurIndex - 1,"BONUS")
	local nBonusCount = DataPool:Lua_GetSpringFestivalBonusInfo(g_CurRound, g_CurIndex - 1,"BONUSCOUNT")
	g_BidBasePrice = DataPool:Lua_GetSpringFestivalBonusInfo(g_CurRound, g_CurIndex - 1,"BASEPRICE")
	g_BidBaseAdd = DataPool:Lua_GetSpringFestivalBonusInfo(g_CurRound, g_CurIndex - 1,"MINADD")
	
	if nBonusItemIndex and tonumber(nBonusItemIndex) > 0 then
		local actionBonus = DataPool:CreateActionItemForShow(nBonusItemIndex,nBonusCount)
	if actionBonus:GetID() ~= 0 then
		ChunJie_AuctionJingPai_Item:SetActionItem(actionBonus:GetID())	
	end
	end

	if g_Top_BiddingPrice == 0 then	
		g_My_Add = g_BidBasePrice
	else
		g_My_Add = g_Top_BiddingPrice - g_My_BiddingPrice + g_BidBaseAdd
	end	
	
	local item_name = DataPool:Lua_GetItemNameByIndex(nBonusItemIndex)
	ChunJie_AuctionJingPai_ItemName:SetText("#G"..tostring(item_name).."*"..tostring(nBonusCount))
	
	local strTemp = ScriptGlobal_Format("#{CJPM_191126_84}",tostring(g_BidBaseAdd))
	ChunJie_AuctionJingPai_DownClient2_Period3_RaiseSub:SetToolTip(strTemp)
	strTemp = ScriptGlobal_Format("#{CJPM_191126_83}",tostring(g_BidBaseAdd))
	ChunJie_AuctionJingPai_DownClient2_Period3_RaiseAdd:SetToolTip(strTemp)
	
	if g_TimeFlag == 1 then

	elseif g_TimeFlag == 2 then
		ChunJie_AuctionJingPai_Update_BiddingNow(1)
	elseif g_TimeFlag == 3 then
		ChunJie_AuctionJingPai_Update_BiddingTimeOut_Waiting()
	elseif g_TimeFlag == 4 then
		ChunJie_AuctionJingPai_Update_BiddingTimeOut()
	end	
	
end

--竞拍日期，未到竞拍时间
function ChunJie_AuctionJingPai_Update_BiddingDatePre()
	
	--上部
	--ChunJie_AuctionJingPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		ChunJie_AuctionJingPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		ChunJie_AuctionJingPai_ManName:SetText("")
	end
	
	--中部
	ChunJie_AuctionJingPai_TimeText:SetText("#{CJPM_191126_134}")
	ChunJie_AuctionJingPai_TimeText2:SetText("#{CJPM_191126_72}")
	ChunJie_AuctionJingPai_TimeText2:Show()
	ChunJie_AuctionJingPai_StopWatch:Hide()
	ChunJie_AuctionJingPai_HaveYuQianNum:SetText("#G"..tostring(Player:GetData("YUANBAO")))
	
end

--竞拍进行中
function ChunJie_AuctionJingPai_Update_BiddingNow(setTimer)

	--上部
	if g_Top_BiddingPrice > 0 then
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		ChunJie_AuctionJingPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		ChunJie_AuctionJingPai_ManName:SetText("")
	end
	
	--中部
	ChunJie_AuctionJingPai_TimeText:SetText("#{CJPM_191126_135}")
	ChunJie_AuctionJingPai_TimeText2:Hide()
	ChunJie_AuctionJingPai_StopWatch:Show()
	if setTimer == 1 then
		ChunJie_AuctionJingPai_StopWatch:SetProperty("Timer",tostring(g_CountDownTime))
	end
	ChunJie_AuctionJingPai_HaveYuQianNum:SetText("#G"..tostring(Player:GetData("YUANBAO")))
	
	--下部
	ChunJie_AuctionJingPai_DownClient2_Period:Show()
	
	local strTemp = ""
	
	local myYuanBao = Player:GetData("YUANBAO")	
	if tonumber(myYuanBao) < g_My_Add then
	
		ChunJie_AuctionJingPai_DownClient2_Period1_BidNum:SetText("#cFF0000"..tostring(g_My_BiddingPrice + g_My_Add))		
		ChunJie_AuctionJingPai_DownClient2_Period2_BaseNum:SetText("#L"..tostring(g_My_BiddingPrice))
		ChunJie_AuctionJingPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
	else	
		ChunJie_AuctionJingPai_DownClient2_Period1_BidNum:SetText("#M"..tostring(g_My_BiddingPrice + g_My_Add))		
		ChunJie_AuctionJingPai_DownClient2_Period2_BaseNum:SetText("#L"..tostring(g_My_BiddingPrice))		
		ChunJie_AuctionJingPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
	end		

	local strTemp = ScriptGlobal_Format("#{CJPM_191126_86}",tostring(g_BidBaseAdd))
	ChunJie_AuctionJingPai_DownClient2_Period3_Hint:SetText(strTemp)

end

--竞拍日期，竞拍时间已过 ，结算中
function ChunJie_AuctionJingPai_Update_BiddingTimeOut_Waiting()
	
	--上部
	--ChunJie_AuctionJingPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		ChunJie_AuctionJingPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		ChunJie_AuctionJingPai_ManName:SetText("")
	end
	
	--中部
	ChunJie_AuctionJingPai_TimeText:SetText("#{CJPM_191126_135}")
	ChunJie_AuctionJingPai_TimeText2:SetText("#{CJPM_191126_75}")
	ChunJie_AuctionJingPai_TimeText2:Show()
	ChunJie_AuctionJingPai_StopWatch:Hide()	
	ChunJie_AuctionJingPai_StopWatch:SetProperty("Timer",tostring( (g_CountDownTime/1000) + 1 ) )
	ChunJie_AuctionJingPai_HaveYuQianNum:SetText("#G"..tostring(Player:GetData("YUANBAO")))

	--下部
	ChunJie_AuctionJingPai_DownClient2_End:Show()
	ChunJie_AuctionJingPai_DownClient2_End_Hint:SetText("#{CJPM_191126_88}")
end

--竞拍日期，竞拍时间已过，结算完毕
function ChunJie_AuctionJingPai_Update_BiddingTimeOut()
	
	--上部
	--ChunJie_AuctionJingPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_Top_BiddingPrice))
		ChunJie_AuctionJingPai_ManName:SetText("#L"..tostring(g_Top_BiddingName))
	else
		ChunJie_AuctionJingPai_ManMoneyNum:SetText("#L"..tostring(g_BidBasePrice))
		ChunJie_AuctionJingPai_ManName:SetText("")
	end
	
	--中部
	ChunJie_AuctionJingPai_TimeText:SetText("#{CJPM_191126_135}")
	ChunJie_AuctionJingPai_TimeText2:SetText("#{CJPM_191126_75}")
	ChunJie_AuctionJingPai_TimeText2:Show()
	ChunJie_AuctionJingPai_StopWatch:Hide()
	ChunJie_AuctionJingPai_HaveYuQianNum:SetText("#G"..tostring(Player:GetData("YUANBAO")))
	
	--下部
	ChunJie_AuctionJingPai_DownClient2_End:Show()
	ChunJie_AuctionJingPai_DownClient2_End_Hint:SetText("#{CJPM_191126_89}")
end

function ChunJie_AuctionJingPai_Refresh()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowClientUI" )
		Set_XSCRIPT_ScriptID(440003)
		Set_XSCRIPT_Parameter(0, 0)				--竞拍
		Set_XSCRIPT_Parameter(1, 0)				--刷新
		Set_XSCRIPT_Parameter(2, g_CurRound)	--轮次	
		Set_XSCRIPT_Parameter(3, g_CurIndex - 1)--索引
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function ChunJie_AuctionJingPai_TimeOut()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Refresh" )
		Set_XSCRIPT_ScriptID(440003)
		Set_XSCRIPT_Parameter(0, g_CurRound)		--轮次	
		Set_XSCRIPT_Parameter(1, g_CurIndex - 1)	--索引
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
end

function ChunJie_AuctionJingPai_AddTokens(flag)

	if flag > 0 then	

		g_My_Add = g_My_Add + g_BidBaseAdd
	else
		g_My_Add = g_My_Add - g_BidBaseAdd		
		if g_My_Add < 0 then
			g_My_Add = 0
		end
	end
	
	if g_TimeFlag == 2 then
		ChunJie_AuctionJingPai_Update_BiddingNow(0)	
	end

end

function ChunJie_AuctionJingPai_NewBidding()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "NewBidding" )
		Set_XSCRIPT_ScriptID( 440003 )
		Set_XSCRIPT_Parameter(0, g_CurRound)	--轮次	
		Set_XSCRIPT_Parameter(1, g_CurIndex - 1)--索引
		Set_XSCRIPT_Parameter(2, g_My_BiddingPrice + g_My_Add)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
end

function ChunJie_AuctionJingPai_TakeBonus()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "TakeBonus" )
		Set_XSCRIPT_ScriptID( 440001 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ChunJie_AuctionJingPai_TakeBackTokens()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "TakeBackTokens" )
		Set_XSCRIPT_ScriptID( 440001 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ChunJie_AuctionJingPai_OnHidden()
	ChunJie_AuctionJingPai_CleanUp()
end

function ChunJie_AuctionJingPai_Close()
	this:Hide()
end

function ChunJie_AuctionJingPai_ClickTimeHelp()
	PushEvent("SRPING_FESTIVAL_BIDDING_HELP")
end

function ChunJie_AuctionJingPai_AdjustPosition()
	if g_ChunJie_AuctionJingPai_UnifiedPosition ~= nil then
		ChunJie_AuctionJingPai:SetProperty("UnifiedPosition",g_ChunJie_AuctionJingPai_UnifiedPosition)
	end
end

--!!!reloadscript =ChunJie_AuctionJingPai