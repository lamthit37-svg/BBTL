--NewBangHui_AuctionBidding

local g_NewBangHui_AuctionBidding_UnifiedPosition = ""

local g_Top_BiddingPrice = 0
local g_My_Bidding = 0
local g_Top_BiddingName = ""

local g_TimeFlag = 0			

local g_BidBasePrice = 2500
local g_BidBaseAdd = 100
local g_My_Add = 0

local g_CountDownTime = 0

local g_ItemIndex = -1

local g_uiDataDate = 0
local g_ItemTableIndex = -1
local g_ItemNum = 0

local g_CurFenYe = 0

local g_Success = 0
local g_SaleTime = 0
local g_nFilterType = 100
local g_IsZhanTuan = 0  -- 是否是 -- 屏蔽
local g_CurSource = 1

function NewBangHui_AuctionBidding_PreLoad()	
	this:RegisterEvent("GUILD_BIDDING_SHOWJINGPAI")
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NewBangHui_AuctionBidding_OnLoad()	
	g_NewBangHui_AuctionBidding_UnifiedPosition = NewBangHui_AuctionBidding_Frame:GetProperty("UnifiedPosition")
	NewBangHui_AuctionBidding_ItemInfo_StopWatch:SetProperty("TextColor","FF00FF00")	
end

function NewBangHui_AuctionBidding_OnEvent(event)
    
	if event == "GUILD_BIDDING_SHOWJINGPAI" then
		local nOperation = tonumber(arg0)
		g_CurFenYe = tonumber(arg1)
		g_ItemIndex = tonumber(arg2)
		g_ItemTableIndex = tonumber(arg3)
		g_ItemNum = tonumber(arg4)
		g_TimeFlag = tonumber(arg5)
		g_Top_BiddingPrice = tonumber(arg6)
		g_My_Bidding = tonumber(arg7)
		g_CountDownTime = tonumber(arg8)
		g_Success = tonumber(arg9)
		g_SaleTime = tonumber(arg10)
		g_nFilterType = tonumber(arg11)
	--	g_IsZhanTuan = tonumber(arg12)
		g_CurSource = tonumber(arg13)

		if nOperation == 2 then
			if g_TimeFlag < 2 then
				PushDebugMessage("#{SCBHPM_20220815_50}") --未开始
				return
			end
			if g_TimeFlag > 2 then --结束
				return
			end
			g_My_Add = 0
			NewBangHui_AuctionBidding_Update()
		
			this:Show()
		elseif nOperation == 3 and this:IsVisible() then
			NewBangHui_AuctionBidding_Update()
		--elseif nOperation == 4 then
		--	if this:IsVisible() then
		--		NewBangHui_AuctionBidding_Update()
		--	end
		end
	
	end
	
	--竞拍失败返回刷新
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004403 then
		
		if this:IsVisible() then

		end
		return
	end
	
	--竞拍被超了
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004404 then
		if this:IsVisible() then

		end
		return
	end

	--刷新元宝
	if event == "UPDATE_YUANBAO" then
		local nHaveYB = Player:GetData("YUANBAO")
		NewBangHui_AuctionBidding_YuanbaoNum:SetText(ScriptGlobal_Format("#{FMPM_220815_83}",tostring(nHaveYB)))
		
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewBangHui_AuctionBidding_AdjustPosition()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end

end

function NewBangHui_AuctionBidding_CleanUp()
	NewBangHui_AuctionBidding_Item:SetActionItem(-1)
end

function NewBangHui_AuctionBidding_Update()
	if g_CurFenYe == 1 then
		NewBangHui_AuctionBidding_DragTitle:SetText("#{SCBHPM_20220815_55}") --帮会
	else
		NewBangHui_AuctionBidding_DragTitle:SetText("#{FMPM_220815_65}") --世界
	end

	if g_IsZhanTuan == 1 then
		NewBangHui_AuctionBidding_DragTitle:SetText("#{FMPM_220815_65}") --战团
	end
	
	NewBangHui_AuctionBidding_CleanUp()
	
	if g_ItemTableIndex > 0 and g_ItemNum > 0 then
		local nShowItemTableIndex = DataPool:LuaFnGetGuildBiddingBonusInfo(g_ItemTableIndex, "SHOWITEMID")		
		local actionBonus = DataPool:CreateActionItemForShow(nShowItemTableIndex, g_ItemNum)
		if actionBonus:GetID() ~= 0 then
			NewBangHui_AuctionBidding_Item:SetActionItem(actionBonus:GetID())	
		end
	end

	g_BidBasePrice = DataPool:LuaFnGetGuildBiddingBonusInfo(g_ItemTableIndex, "BASEPRICE",g_CurSource)
	g_BidBaseAdd = DataPool:LuaFnGetGuildBiddingBonusInfo(g_ItemTableIndex, "MINADD",g_CurSource)

	g_BidBasePrice = g_BidBasePrice * g_ItemNum
	g_BidBaseAdd = g_BidBaseAdd * g_ItemNum
	
	--初始加价
	if g_My_Add == 0 then
		if g_My_Bidding == 0 then	
			g_My_Add = g_BidBasePrice
		else
			g_My_Add = g_Top_BiddingPrice + g_BidBaseAdd
		end	
	end
	
	local item_name = DataPool:Lua_GetItemNameByIndex(g_ItemTableIndex)
	
	local strName = ScriptGlobal_Format("#{FMPM_220815_25}", tostring(item_name))	
	NewBangHui_AuctionBidding_ItemInfo_Text1:SetText(strName)
	
	--local strCount = ScriptGlobal_Format("#{BJPM_200804_113}", tostring(g_ItemNum))	
	--NewBangHui_AuctionBidding_ItemNum:SetText(strCount)
	
	--加价
	local strTemp = ScriptGlobal_Format("#{FMPM_220815_84}",tostring(g_BidBaseAdd))
	NewBangHui_AuctionBidding_RaiseAdd:SetToolTip(strTemp)
	--减价
	strTemp = ScriptGlobal_Format("#{FMPM_220815_86}",tostring(g_BidBaseAdd))
	NewBangHui_AuctionBidding_RaiseSub:SetToolTip(strTemp)
	
	--元宝数
	local nHaveYB = Player:GetData("YUANBAO")
	NewBangHui_AuctionBidding_YuanbaoNum:SetText(ScriptGlobal_Format("#{FMPM_220815_83}",tostring(nHaveYB)))
	
	NewBangHui_AuctionBidding_ItemInfo_Text2:Hide()
	--阶段 0：无拍卖 1：公示期 2：拍卖中 3：结果展示期 4:展示结束至领奖结束期间
	NewBangHui_AuctionBidding_HighestAnimate:Play(false)
	
	if g_TimeFlag == 1 then
		--最高竞价
		NewBangHui_AuctionBidding_HighestNum:SetText(ScriptGlobal_Format("#{FMPM_220815_69}",tostring(g_BidBasePrice)))
		--是否是最高出价
		NewBangHui_AuctionBidding_MineNum:SetText("#{FMPM_220815_72}")
		NewBangHui_AuctionBidding_NumBK:Hide()
		NewBangHui_AuctionBidding_NotStarted:Show()
		NewBangHui_AuctionBidding_NotStarted:SetText("#{FMPM_220815_89}")
		NewBangHui_AuctionBidding_ButtonFrame:Hide()
	elseif g_TimeFlag == 2 then
		--倒计时
		NewBangHui_AuctionBidding_ItemInfo_Text2:Show()
		NewBangHui_AuctionBidding_ItemInfo_StopWatch:SetProperty("Timer",tostring(g_CountDownTime)) 
		
		--最高竞价
		if g_Top_BiddingPrice > 0 then
			NewBangHui_AuctionBidding_HighestNum:SetText(ScriptGlobal_Format("#{FMPM_220815_69}",tostring(g_Top_BiddingPrice)))
		else
			NewBangHui_AuctionBidding_HighestNum:SetText(ScriptGlobal_Format("#{FMPM_220815_69}",tostring(g_BidBasePrice)))
		end
		
		--出价成功
		if g_Success == 1 then
			NewBangHui_AuctionBidding_HighestAnimate:Play(true)
			--Guild:AskGuildBiddingInfo(1,g_CurFenYe,g_nFilterType) --刷新列表
		else
			NewBangHui_AuctionBidding_HighestAnimate:Play(false)
		end
		
		--是否是最高出价
		if g_My_Bidding == 1 then
			NewBangHui_AuctionBidding_MineNum:SetText("#{FMPM_220815_71}")
		else
			NewBangHui_AuctionBidding_MineNum:SetText("#{FMPM_220815_72}")
		end
		NewBangHui_AuctionBidding_NumBK:Show()
		NewBangHui_AuctionBidding_NotStarted:Hide()
		NewBangHui_AuctionBidding_ButtonFrame:Show()
		--加价
		if g_My_Bidding == 2 then --其他人出最高价
			g_My_Add = g_Top_BiddingPrice + g_BidBaseAdd
		end 
		NewBangHui_AuctionBidding_Num:SetText(tostring(g_My_Add))
		if g_My_Add <= g_Top_BiddingPrice + g_BidBaseAdd then
			NewBangHui_AuctionBidding_RaiseSub:Disable()
		else
			NewBangHui_AuctionBidding_RaiseSub:Enable()
		end
	elseif g_TimeFlag == 3 then
		--最高竞价
		if g_Top_BiddingPrice > 0 then
			NewBangHui_AuctionBidding_HighestNum:SetText(ScriptGlobal_Format("#{FMPM_220815_69}",tostring(g_Top_BiddingPrice)))
		else
			NewBangHui_AuctionBidding_HighestNum:SetText(ScriptGlobal_Format("#{FMPM_220815_69}",tostring(g_BidBasePrice)))
		end
		--是否是最高出价
		if g_My_Bidding == 1 then
			NewBangHui_AuctionBidding_MineNum:SetText("#{FMPM_220815_71}")
		else
			NewBangHui_AuctionBidding_MineNum:SetText("#{FMPM_220815_72}")
		end
		NewBangHui_AuctionBidding_NumBK:Hide()
		NewBangHui_AuctionBidding_NotStarted:Show()
		NewBangHui_AuctionBidding_NotStarted:SetText("#{FMPM_220815_90}")
		NewBangHui_AuctionBidding_ButtonFrame:Hide()
	else 
		--最高竞价
		NewBangHui_AuctionBidding_HighestNum:SetText(ScriptGlobal_Format("#{FMPM_220815_69}",tostring(g_BidBasePrice)))
		--是否是最高出价
		NewBangHui_AuctionBidding_MineNum:SetText("#{FMPM_220815_72}")
		NewBangHui_AuctionBidding_NumBK:Hide()
		NewBangHui_AuctionBidding_NotStarted:Show()
		NewBangHui_AuctionBidding_NotStarted:SetText("#{FMPM_220815_89}")
		NewBangHui_AuctionBidding_ButtonFrame:Hide()
	end
	
end

--刷新
function NewBangHui_AuctionBidding_Refresh()
	Guild:AskGuildBiddingAuctionItem(2,g_CurFenYe,g_ItemIndex,g_ItemTableIndex,g_ItemNum,g_SaleTime,g_nFilterType,g_IsZhanTuan) --操作类型2，表类型:0：世界 1:帮会
end

function NewBangHui_AuctionBidding_TimeOut()

end

function NewBangHui_AuctionBidding_AddTokens(flag)

	if flag > 0 then
		g_My_Add = g_My_Add + g_BidBaseAdd
	else
		g_My_Add = g_My_Add - g_BidBaseAdd
		
		if g_My_Bidding == 0 then
			if g_My_Add <= g_BidBasePrice then
				g_My_Add = g_BidBasePrice
			end
		else
			if g_My_Add < g_Top_BiddingPrice + g_BidBaseAdd then
				g_My_Add = g_Top_BiddingPrice + g_BidBaseAdd
			end
		end
	end
	--加价
	NewBangHui_AuctionBidding_Num:SetText(tostring(g_My_Add))
	
	if g_My_Bidding == 0 then
		if g_My_Add <= g_BidBasePrice then
			NewBangHui_AuctionBidding_RaiseSub:Disable()
		else
			NewBangHui_AuctionBidding_RaiseSub:Enable()
		end
	else
		if g_My_Add <= g_Top_BiddingPrice + g_BidBaseAdd then
			NewBangHui_AuctionBidding_RaiseSub:Disable()
		else
			NewBangHui_AuctionBidding_RaiseSub:Enable()
		end
	end

end

--竞拍
function NewBangHui_AuctionBidding_DoBidding()	
	Guild:AskGuildBiddingAuctionItem(3,g_CurFenYe,g_ItemIndex,g_ItemTableIndex,g_ItemNum,g_SaleTime,g_nFilterType,g_IsZhanTuan,g_My_Add)
end

function NewBangHui_AuctionBidding_OnHidden()
	NewBangHui_AuctionBidding_CleanUp()
end

function NewBangHui_AuctionBidding_Close()
	this:Hide()
end


function NewBangHui_AuctionBidding_AdjustPosition()
	if g_NewBangHui_AuctionBidding_UnifiedPosition ~= nil then
		NewBangHui_AuctionBidding_Frame:SetProperty("UnifiedPosition",g_NewBangHui_AuctionBidding_UnifiedPosition)
	end
end