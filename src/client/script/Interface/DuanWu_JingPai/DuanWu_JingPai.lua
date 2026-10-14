
--!!!reloadscript =DuanWu_JingPai

local g_DuanWu_JingPai_UnifiedPosition = ""

local g_Top_BiddingPrice = 0
local g_My_BiddingPrice = 0
local g_Top_BiddingName = ""

local g_BidOrTakeBack = 0		--0：竞拍 1：取回
local g_TimeFlag = 1			
--1：没到竞拍的日期 
--2：竞拍当天未开始
--3：竞拍进行中
--4：竞拍当天已结束
--5：竞拍已结束
local g_BonusOrTokens = 0		--0: 获胜 1：失败

local g_RoundDate = 0
local g_BidBasePrice = 2500
local g_BidBaseAdd = 100
local g_My_Add = 0
local g_MyTokens = 0

local g_CountDownTime = 0

local g_font_color = "#L"

function DuanWu_JingPai_PreLoad()
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER_PUTIN_EQUIP")
	this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER_RCLICK")
	this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER_REMOVE_EQUIP")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false) 
	this:RegisterEvent("ZHIZUN_EQUIP_RESET_CLOSE")	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function DuanWu_JingPai_OnLoad()	
	g_DuanWu_JingPai_UnifiedPosition = DuanWu_JingPai:GetProperty("UnifiedPosition")
end

function DuanWu_JingPai_OnEvent(event)
    
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000101 then
		
		local bShowOrRefresh 	= Get_XParam_INT(0)
		g_BidOrTakeBack 		= Get_XParam_INT(1)
		g_TimeFlag 				= Get_XParam_INT(2)
		g_BonusOrTokens 		= Get_XParam_INT(3)
		g_Top_BiddingPrice		= Get_XParam_INT(4)
		g_MyTokens				= Get_XParam_INT(5)
		g_My_BiddingPrice		= Get_XParam_INT(6)
		g_CountDownTime			= Get_XParam_INT(7)
		g_RoundDate				= Get_XParam_INT(8)
		g_Top_BiddingName		= Get_XParam_STR(0)
		
	--	PushDebugMessage(tostring(g_BidOrTakeBack).."-"..tostring(g_TimeFlag).."-"..tostring(g_BonusOrTokens).."-"..tostring(g_MyTokens))
		
		if bShowOrRefresh == 0 then
			this:Show()
			DuanWu_JingPai_Update()
		elseif bShowOrRefresh == 1 then
			if this:IsVisible() then
				DuanWu_JingPai_Update()
			end
		end
		
		return
	end	
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000102 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	
	--竞拍失败返回刷新
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000103 then
		
		if this:IsVisible() then

			g_BidOrTakeBack 		= Get_XParam_INT(0)
			g_TimeFlag 				= Get_XParam_INT(1)
			g_BonusOrTokens 		= Get_XParam_INT(2)
			g_Top_BiddingPrice		= Get_XParam_INT(3)
			g_MyTokens				= Get_XParam_INT(4)
			g_My_BiddingPrice		= Get_XParam_INT(5)
			g_CountDownTime			= Get_XParam_INT(6)
			g_RoundDate				= Get_XParam_INT(7)
			g_Top_BiddingName		= Get_XParam_STR(0)
			
			DuanWu_JingPai_Update()
		end
		return
	end
	
	--竞拍被超了
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000104 then
		
		if this:IsVisible() then

			g_BidOrTakeBack 		= Get_XParam_INT(0)
			g_TimeFlag 				= Get_XParam_INT(1)
			g_BonusOrTokens 		= Get_XParam_INT(2)
			g_Top_BiddingPrice		= Get_XParam_INT(3)
			g_MyTokens				= Get_XParam_INT(4)
			g_My_BiddingPrice		= Get_XParam_INT(5)
			g_CountDownTime			= Get_XParam_INT(6)
			g_RoundDate				= Get_XParam_INT(7)
			g_Top_BiddingName		= Get_XParam_STR(0)
			
			DuanWu_JingPai_Update()
			PushDebugMessage("#{MHZD_190501_59}")
		end
		return
	end
	
	--刷新代币
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000105 then
		
		if this:IsVisible() then
			g_MyTokens	= Get_XParam_INT(0)
			DuanWu_JingPai_Update()
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu_JingPai_AdjustPosition()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

end

function DuanWu_JingPai_CleanUp()
	if g_Top_BiddingPrice == 0 then	
		g_My_Add = g_BidBasePrice
	else
		g_My_Add = g_Top_BiddingPrice - g_My_BiddingPrice + g_BidBaseAdd
	end
end

function DuanWu_JingPai_Update()
	
	DuanWu_JingPai_Item:SetActionItem(-1)
	DuanWu_JingPai_ItemName:SetText("")
	--上部
	DuanWu_JingPai_ManClient:Hide()
	DuanWu_JingPai_NotTime:Hide()
		
	--下部
	DuanWu_JingPai_DownClient2_NotTime:Hide()
	DuanWu_JingPai_DownClient2_Period:Hide()
	DuanWu_JingPai_DownClient2_End:Hide()
	DuanWu_JingPai_DownClient2_AwardProlong:Hide()
	DuanWu_JingPai_DownClient2_Award:Hide()
	DuanWu_JingPai_DownClient2_GetBack:Hide()
	
	local nRound = DuanWu_JingPai_GetRoundByDate(g_RoundDate)
	
	g_BidBasePrice = DataPool:LuaFnGetDuanWuBiddingBonusInfo(nRound, "BASEPRICE")
	g_BidBaseAdd = DataPool:LuaFnGetDuanWuBiddingBonusInfo(nRound, "MINADD")
	local item_table_index = DataPool:LuaFnGetDuanWuBiddingBonusInfo(nRound, "BONUS")	
	local item_count = DataPool:LuaFnGetDuanWuBiddingBonusInfo(nRound, "BONUSCOUNT")	
	
	if item_table_index > 0 then
		local actionBonus = DataPool:CreateActionItemForShow(item_table_index,item_count)
		if actionBonus:GetID() ~= 0 then
			DuanWu_JingPai_Item:SetActionItem(actionBonus:GetID())	
		end
		
		local item_name = DataPool:Lua_GetItemNameByIndex(item_table_index)
		DuanWu_JingPai_ItemName:SetText(tostring(item_name))
	end
	
	if g_Top_BiddingPrice == 0 then	
		g_My_Add = g_BidBasePrice
	else		
		g_My_Add = g_Top_BiddingPrice - g_My_BiddingPrice + g_BidBaseAdd
	end
	
	if g_TimeFlag == 1 then
		DuanWu_JingPai_Update_BeforeBiddingDate()
	elseif g_TimeFlag == 2 then
		DuanWu_JingPai_Update_BiddingDatePre()
	elseif g_TimeFlag == 3 then
		DuanWu_JingPai_Update_BiddingNow(1)
	elseif g_TimeFlag == 4 then
		DuanWu_JingPai_Update_BiddingTimeOut_Waiting()
	elseif g_TimeFlag == 5 then
		DuanWu_JingPai_Update_BiddingTimeOut()
	elseif g_TimeFlag == 6 then
		DuanWu_JingPai_Update_BiddingBreak_I()
	elseif g_TimeFlag == 7 then
		DuanWu_JingPai_Update_BiddingBreak_II()
	elseif g_TimeFlag == 8 then
		DuanWu_JingPai_Update_BiddingTimeOut()
	elseif g_TimeFlag == 9 then
		DuanWu_JingPai_Update_BiddingAllOver()
	end	
	
end

--竞拍日期之前
function DuanWu_JingPai_Update_BeforeBiddingDate()
	
	--上部
	DuanWu_JingPai_NotTime:Show()
	DuanWu_JingPai_NotTime:SetText("#{MHZD_190501_14}")
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_07}")
	DuanWu_JingPai_TimeText2:SetText("#{MHZD_190501_08}")
	DuanWu_JingPai_TimeText2:Show()
	DuanWu_JingPai_StopWatch:Hide()
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))
	
	--下部
	DuanWu_JingPai_DownClient2_NotTime:Show()
	DuanWu_JingPai_DownClient2_NotTime_Num:SetText(tostring(g_BidBasePrice))

end

--竞拍日期，未到竞拍时间
function DuanWu_JingPai_Update_BiddingDatePre()
	
	--上部
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_NotTime:Show()
		DuanWu_JingPai_NotTime:SetText("#{MHZD_190501_14}")
	else
		DuanWu_JingPai_ManClient:Show()
		if g_Top_BiddingPrice > 0 then
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_Top_BiddingPrice))
			DuanWu_JingPai_ManName:SetText(g_font_color..tostring(g_Top_BiddingName))
		else
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_BidBasePrice))
			DuanWu_JingPai_ManName:SetText("#{MHZD_190501_113}")
		end
	end
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_07}")
	DuanWu_JingPai_TimeText2:SetText("#{MHZD_190501_09}")
	DuanWu_JingPai_TimeText2:Show()
	DuanWu_JingPai_StopWatch:Hide()
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))
	
	--下部	
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_DownClient2_NotTime:Show()
		DuanWu_JingPai_DownClient2_NotTime_Num:SetText(tostring(g_BidBasePrice))
	else		
		if g_BonusOrTokens == 0 then
			DuanWu_JingPai_DownClient2_Award:Show()
		else
			DuanWu_JingPai_DownClient2_GetBack:Show()
			DuanWu_JingPai_DownClient2_GetBack_Num:SetText(tostring(g_My_BiddingPrice))
		end		
	end
end

--竞拍进行中
function DuanWu_JingPai_Update_BiddingNow(setTimer)

	--上部
	DuanWu_JingPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_Top_BiddingPrice))
		DuanWu_JingPai_ManName:SetText(g_font_color..tostring(g_Top_BiddingName))
	else
		DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_BidBasePrice))
		DuanWu_JingPai_ManName:SetText("#{MHZD_190501_113}")
	end
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_10}")
	DuanWu_JingPai_TimeText2:Hide()
	DuanWu_JingPai_StopWatch:Show()
	if setTimer == 1 then
		DuanWu_JingPai_StopWatch:SetProperty("Timer",tostring(g_CountDownTime))
	end
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))
	
	--下部	
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_DownClient2_Period:Show()
		
		if g_MyTokens < g_My_Add then
			DuanWu_JingPai_DownClient2_Period1_BidNum:SetText("#cFF0000"..tostring(g_My_BiddingPrice + g_My_Add))		
			DuanWu_JingPai_DownClient2_Period2_BaseNum:SetText(g_font_color..tostring(g_My_BiddingPrice))		
			DuanWu_JingPai_DownClient2_Period3_RaiseNum:SetText("#cFF0000"..tostring(g_My_Add))
		else
			DuanWu_JingPai_DownClient2_Period1_BidNum:SetText("#M"..tostring(g_My_BiddingPrice + g_My_Add))		
			DuanWu_JingPai_DownClient2_Period2_BaseNum:SetText(g_font_color..tostring(g_My_BiddingPrice))		
			DuanWu_JingPai_DownClient2_Period3_RaiseNum:SetText("#G"..tostring(g_My_Add))
		end		
		
	else		
		if g_BonusOrTokens == 0 then
			DuanWu_JingPai_DownClient2_Award:Show()
		else
			DuanWu_JingPai_DownClient2_GetBack:Show()
			DuanWu_JingPai_DownClient2_GetBack_Num:SetText(tostring(g_My_BiddingPrice))			
		end		
	end
end

--竞拍日期，竞拍时间已过 ，结算中
function DuanWu_JingPai_Update_BiddingTimeOut_Waiting()
	
	--上部
	DuanWu_JingPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_Top_BiddingPrice))
		DuanWu_JingPai_ManName:SetText(g_font_color..tostring(g_Top_BiddingName))
	else
		DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_BidBasePrice))
		DuanWu_JingPai_ManName:SetText("#{MHZD_190501_113}")
	end
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_10}")
	DuanWu_JingPai_TimeText2:SetText("#{MHZD_190501_11}")
	DuanWu_JingPai_TimeText2:Show()
	DuanWu_JingPai_StopWatch:Hide()	
	DuanWu_JingPai_StopWatch:SetProperty("Timer",tostring( (g_CountDownTime/1000) + 1 ) )
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))

	--下部	
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_DownClient2_End:Show()
		DuanWu_JingPai_DownClient2_End_Hint:SetText("#{MHZD_190501_111}")
	else		
		if g_BonusOrTokens == 0 then
			DuanWu_JingPai_DownClient2_Award:Show()
		else
			DuanWu_JingPai_DownClient2_GetBack:Show()
			DuanWu_JingPai_DownClient2_GetBack_Num:SetText(tostring(g_My_BiddingPrice))
		end		
	end
	

end

--竞拍日期，竞拍时间已过，结算完毕
function DuanWu_JingPai_Update_BiddingTimeOut()
	
	--上部
	DuanWu_JingPai_ManClient:Show()
	if g_Top_BiddingPrice > 0 then
		DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_Top_BiddingPrice))
		DuanWu_JingPai_ManName:SetText(g_font_color..tostring(g_Top_BiddingName))
	else
		DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_BidBasePrice))
		DuanWu_JingPai_ManName:SetText("#{MHZD_190501_113}")
	end
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_10}")
	DuanWu_JingPai_TimeText2:SetText("#{MHZD_190501_11}")
	DuanWu_JingPai_TimeText2:Show()
	DuanWu_JingPai_StopWatch:Hide()
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))
	
	--下部	
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_DownClient2_End:Show()
		DuanWu_JingPai_DownClient2_End_Hint:SetText("#{MHZD_190501_35}")
	else		
		if g_BonusOrTokens == 0 then
			DuanWu_JingPai_DownClient2_Award:Show()
		else
			DuanWu_JingPai_DownClient2_GetBack:Show()
			DuanWu_JingPai_DownClient2_GetBack_Num:SetText(tostring(g_My_BiddingPrice))
		end		
	end
end

--竞拍日期 第一次间歇
function DuanWu_JingPai_Update_BiddingBreak_I()
	
	--上部
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_NotTime:Show()
		DuanWu_JingPai_NotTime:SetText("#{MHZD_190501_14}")
	else
		DuanWu_JingPai_ManClient:Show()
		if g_Top_BiddingPrice > 0 then
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_Top_BiddingPrice))
			DuanWu_JingPai_ManName:SetText(g_font_color..tostring(g_Top_BiddingName))
		else
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_BidBasePrice))
			DuanWu_JingPai_ManName:SetText("#{MHZD_190501_113}")
		end
	end
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_07}")
	DuanWu_JingPai_TimeText2:SetText("#{MHZD_190501_106}")
	DuanWu_JingPai_TimeText2:Show()
	DuanWu_JingPai_StopWatch:Hide()
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))
	
	--下部
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_DownClient2_NotTime:Show()
		DuanWu_JingPai_DownClient2_NotTime_Num:SetText(tostring(g_BidBasePrice))
	else		
		if g_BonusOrTokens == 0 then
			DuanWu_JingPai_DownClient2_Award:Show()
		else
			DuanWu_JingPai_DownClient2_GetBack:Show()
			DuanWu_JingPai_DownClient2_GetBack_Num:SetText(tostring(g_My_BiddingPrice))
		end		
	end

end

--竞拍日期 第二次间歇
function DuanWu_JingPai_Update_BiddingBreak_II()
	
	--上部	
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_NotTime:Show()
		DuanWu_JingPai_NotTime:SetText("#{MHZD_190501_14}")
	else
		DuanWu_JingPai_ManClient:Show()
		if g_Top_BiddingPrice > 0 then
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_Top_BiddingPrice))
			DuanWu_JingPai_ManName:SetText(g_font_color..tostring(g_Top_BiddingName))
		else
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_BidBasePrice))
			DuanWu_JingPai_ManName:SetText("#{MHZD_190501_113}")
		end
	end
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_07}")
	DuanWu_JingPai_TimeText2:SetText("#{MHZD_190501_107}")
	DuanWu_JingPai_TimeText2:Show()
	DuanWu_JingPai_StopWatch:Hide()
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))
	
	--下部
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_DownClient2_NotTime:Show()
		DuanWu_JingPai_DownClient2_NotTime_Num:SetText(tostring(g_BidBasePrice))
	else		
		if g_BonusOrTokens == 0 then
			DuanWu_JingPai_DownClient2_Award:Show()
		else
			DuanWu_JingPai_DownClient2_GetBack:Show()
			DuanWu_JingPai_DownClient2_GetBack_Num:SetText(tostring(g_My_BiddingPrice))
		end		
	end

end

--竞拍日期已过
function DuanWu_JingPai_Update_BiddingAllOver()
	
	--上部	
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_NotTime:Show()
		DuanWu_JingPai_NotTime:SetText("#{MHZD_190501_91}")
	else
		DuanWu_JingPai_ManClient:Show()
		if g_Top_BiddingPrice > 0 then
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_Top_BiddingPrice))
			DuanWu_JingPai_ManName:SetText(g_font_color..tostring(g_Top_BiddingName))
		else
			DuanWu_JingPai_ManMoneyNum:SetText(g_font_color..tostring(g_BidBasePrice))
			DuanWu_JingPai_ManName:SetText("#{MHZD_190501_113}")
		end
	end
	
	--中部
	DuanWu_JingPai_TimeText:SetText("#{MHZD_190501_10}")
	DuanWu_JingPai_TimeText2:SetText("#{MHZD_190501_11}")
	DuanWu_JingPai_TimeText2:Show()
	DuanWu_JingPai_StopWatch:Hide()
	DuanWu_JingPai_HaveYuQianNum:SetText(tostring(g_MyTokens))
	
	--下部
	if g_BidOrTakeBack == 0 then
		DuanWu_JingPai_DownClient2_AwardProlong:Show()
	else		
		if g_BonusOrTokens == 0 then
			DuanWu_JingPai_DownClient2_Award:Show()
		else
			DuanWu_JingPai_DownClient2_GetBack:Show()
			DuanWu_JingPai_DownClient2_GetBack_Num:SetText(tostring(g_My_BiddingPrice))
		end		
	end
end

function DuanWu_JingPai_Refresh()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Refresh" )
		Set_XSCRIPT_ScriptID( 440001 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

function DuanWu_JingPai_TimeOut()
	DuanWu_JingPai_Refresh()
end

function DuanWu_JingPai_AddTokens(flag)

	if flag > 0 then	

		g_My_Add = g_My_Add + g_BidBaseAdd
	else
		g_My_Add = g_My_Add - g_BidBaseAdd		
		if g_My_Add < 0 then
			g_My_Add = 0
		end
	end
	
	if g_TimeFlag == 3 then
		DuanWu_JingPai_Update_BiddingNow(0)	
	end

end

function DuanWu_JingPai_NewBidding()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "NewBidding" )
		Set_XSCRIPT_ScriptID( 440001 )
		Set_XSCRIPT_Parameter(0, g_My_BiddingPrice + g_My_Add)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

function DuanWu_JingPai_TakeBonus()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "TakeBonus" )
		Set_XSCRIPT_ScriptID( 440001 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DuanWu_JingPai_TakeBackTokens()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "TakeBackTokens" )
		Set_XSCRIPT_ScriptID( 440001 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DuanWu_JingPai_Close()
	this:Hide()
end

function DuanWu_JingPai_ClickItemShow()
	
	local nRound = DuanWu_JingPai_GetRoundByDate(g_RoundDate)
	local item_table_index = DataPool:LuaFnGetDuanWuBiddingBonusInfo(nRound, "BONUS")	
	
	if item_table_index == 38002811 then
		PushEvent("DUANWU_BIDDING_BONUS_PREVIEW")
	elseif item_table_index == 38004733 then
		LuaFnOpenSkillCardDetail(35)	
	end
end

function DuanWu_JingPai_ClickTimeHelp()
	PushEvent("DUANWU_BIDDING_HELP_I")
end

function DuanWu_JingPai_ClickPriceHelp()
	PushEvent("DUANWU_BIDDING_HELP_II")
end

function DuanWu_JingPai_ClickItemHelp()
	PushEvent("DUANWU_BIDDING_HELP_III")
end

function DuanWu_JingPai_AdjustPosition()
	if g_DuanWu_JingPai_UnifiedPosition ~= nil then
		DuanWu_JingPai:SetProperty("UnifiedPosition",g_DuanWu_JingPai_UnifiedPosition)
	end
end

function DuanWu_JingPai_GetRoundByDate(nDate)

	if nDate <= 20210618 then
		return 1
	elseif nDate == 20210619 then
		return 2	
	elseif nDate == 20210620 then
		return 3		
	elseif nDate == 20210621 or nDate == 20210622 then
		return 4
	elseif nDate == 20210623 then
		return 5
	elseif nDate == 20210624 or nDate == 20210625 then
		return 6
	elseif nDate == 20210626 then
		return 7
	elseif nDate >= 20210627 then
		return 8	
	end
	
	return 8
end

--!!!reloadscript =DuanWu_JingPai