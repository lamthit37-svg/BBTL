-- 元宵十连抽

---------------------------------------------------------------------------	
local g_Position = "{{0.500000,-376.000000},{0.500000,-255.000000}}"
local g_OneDrawCD = 1
local g_TenDrawCD = 3
local g_LastOneDrawLeft = 0
local g_LasTenDrawLeft = 0
local g_LasOneDrawRight = 0
local g_LasTenDrawRight = 0
local g_rewardList_jixiangfu = 
{
	[1]  = {showId = 39921634, num = 500},
	[2]  = {showId = 39921634, num = 550},
	[3]  = {showId = 39921634, num = 600},
	[4]  = {showId = 39921635, num = 650},
	[5]  = {showId = 39921635, num = 700},
	[6]  = {showId = 39921635, num = 750},
	[7]  = {showId = 39921635, num = 800},
	[8]  = {showId = 39921635, num = 850},
	[9]  = {showId = 39921635, num = 900},
	[10] = {showId = 39921636, num = 950},
	[11] = {showId = 39921636, num = 1000},
}

local g_rewardList_ruyifu = 
{
	[1]  = {showId = 39921576, num = 200},
	[2]  = {showId = 39921576, num = 250},
	[3]  = {showId = 39921576, num = 300},
	[4]  = {showId = 39921633, num = 350},
	[5]  = {showId = 39921633, num = 400},
	[6]  = {showId = 39921633, num = 450},
	[7]  = {showId = 39921634, num = 500},
	[8]  = {showId = 39921634, num = 550},
	[9]  = {showId = 39921634, num = 600},
}
local g_rewardList = {}
local g_rewardIndexList = {}
local g_tenFudai = {}	
local g_tenDrawItem = {}
local g_tenDrawItemAnimate = {}
local g_tenDrawItemBoom = {}
local g_tenIndex = 0
local g_lastOptType = 0
local g_targetId = 0
local g_startDiscoutTm = 20190211
local g_endDiscoutTm = 20190214
local g_rareJixiang = 650
local g_rareRuyi = 500
local g_tenDrawItemText = {}
local g_oneIndex = 0
---------------------------------------------------------------------------

--*********************************
-- PreLoad
--*********************************
function YuanXiao_Lottery_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" );		-- 游戏分辨率发生了变化
	this : RegisterEvent( "GAMELOGIN_SELECTCHARACTER" );	-- 选择人物
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" );		-- 离开场景
	this : RegisterEvent( "ADJEST_UI_POS" , false);
end


--*********************************
-- OnLoad
--*********************************
function YuanXiao_Lottery_OnLoad()
	g_tenDrawItem[1] = YuanXiao_Lottery_TenDraw_Item1
	g_tenDrawItem[2] = YuanXiao_Lottery_TenDraw_Item2
	g_tenDrawItem[3] = YuanXiao_Lottery_TenDraw_Item3
	g_tenDrawItem[4] = YuanXiao_Lottery_TenDraw_Item4
	g_tenDrawItem[5] = YuanXiao_Lottery_TenDraw_Item5
	g_tenDrawItem[6] = YuanXiao_Lottery_TenDraw_Item6
	g_tenDrawItem[7] = YuanXiao_Lottery_TenDraw_Item7
	g_tenDrawItem[8] = YuanXiao_Lottery_TenDraw_Item8
	g_tenDrawItem[9] = YuanXiao_Lottery_TenDraw_Item9
	g_tenDrawItem[10] = YuanXiao_Lottery_TenDraw_Item10

	g_tenDrawItemAnimate[1] = YuanXiao_Lottery_TenDraw_Item1Animate
	g_tenDrawItemAnimate[2] = YuanXiao_Lottery_TenDraw_Item2Animate
	g_tenDrawItemAnimate[3] = YuanXiao_Lottery_TenDraw_Item3Animate
	g_tenDrawItemAnimate[4] = YuanXiao_Lottery_TenDraw_Item4Animate
	g_tenDrawItemAnimate[5] = YuanXiao_Lottery_TenDraw_Item5Animate
	g_tenDrawItemAnimate[6] = YuanXiao_Lottery_TenDraw_Item6Animate
	g_tenDrawItemAnimate[7] = YuanXiao_Lottery_TenDraw_Item7Animate
	g_tenDrawItemAnimate[8] = YuanXiao_Lottery_TenDraw_Item8Animate
	g_tenDrawItemAnimate[9] = YuanXiao_Lottery_TenDraw_Item9Animate
	g_tenDrawItemAnimate[10] = YuanXiao_Lottery_TenDraw_Item10Animate

	g_tenDrawItemBoom[1] = YuanXiao_Lottery_TenDraw_Item1Boom
	g_tenDrawItemBoom[2] = YuanXiao_Lottery_TenDraw_Item2Boom
	g_tenDrawItemBoom[3] = YuanXiao_Lottery_TenDraw_Item3Boom
	g_tenDrawItemBoom[4] = YuanXiao_Lottery_TenDraw_Item4Boom
	g_tenDrawItemBoom[5] = YuanXiao_Lottery_TenDraw_Item5Boom
	g_tenDrawItemBoom[6] = YuanXiao_Lottery_TenDraw_Item6Boom
	g_tenDrawItemBoom[7] = YuanXiao_Lottery_TenDraw_Item7Boom
	g_tenDrawItemBoom[8] = YuanXiao_Lottery_TenDraw_Item8Boom
	g_tenDrawItemBoom[9] = YuanXiao_Lottery_TenDraw_Item9Boom
	g_tenDrawItemBoom[10] = YuanXiao_Lottery_TenDraw_Item10Boom

	g_tenDrawItemText[1] = YuanXiao_Lottery_TenDraw_Item1Text
	g_tenDrawItemText[2] = YuanXiao_Lottery_TenDraw_Item2Text
	g_tenDrawItemText[3] = YuanXiao_Lottery_TenDraw_Item3Text
	g_tenDrawItemText[4] = YuanXiao_Lottery_TenDraw_Item4Text
	g_tenDrawItemText[5] = YuanXiao_Lottery_TenDraw_Item5Text
	g_tenDrawItemText[6] = YuanXiao_Lottery_TenDraw_Item6Text
	g_tenDrawItemText[7] = YuanXiao_Lottery_TenDraw_Item7Text
	g_tenDrawItemText[8] = YuanXiao_Lottery_TenDraw_Item8Text
	g_tenDrawItemText[9] = YuanXiao_Lottery_TenDraw_Item9Text
	g_tenDrawItemText[10] = YuanXiao_Lottery_TenDraw_Item10Text

	g_tenFudai[1] = YuanXiao_Lottery_TenDraw_Item1Fudai
	g_tenFudai[2] = YuanXiao_Lottery_TenDraw_Item2Fudai
	g_tenFudai[3] = YuanXiao_Lottery_TenDraw_Item3Fudai
	g_tenFudai[4] = YuanXiao_Lottery_TenDraw_Item4Fudai
	g_tenFudai[5] = YuanXiao_Lottery_TenDraw_Item5Fudai
	g_tenFudai[6] = YuanXiao_Lottery_TenDraw_Item6Fudai
	g_tenFudai[7] = YuanXiao_Lottery_TenDraw_Item7Fudai
	g_tenFudai[8] = YuanXiao_Lottery_TenDraw_Item8Fudai
	g_tenFudai[9] = YuanXiao_Lottery_TenDraw_Item9Fudai
	g_tenFudai[10] = YuanXiao_Lottery_TenDraw_Item10Fudai
end


--*********************************
-- OnEvent
--*********************************
function YuanXiao_Lottery_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 89302001) then
		
		local bShow = tonumber(Get_XParam_INT(0));
		local jixiangfu = tonumber(Get_XParam_INT(2));
		local ruyifu = tonumber(Get_XParam_INT(3));
		local jinzhu = tonumber(Get_XParam_INT(4));
		if bShow == 10 then-- 打开UI
			-- 关心NPC
			g_targetId = Target:GetServerId2ClientId(tonumber(Get_XParam_INT(1)));
			this:CareObject(g_targetId, 1, "YuanXiao_Lottery");
			YuanXiao_Lottery_ShowSelectFrame()
		elseif bShow == 1 then
			local index = tonumber(Get_XParam_INT(5));
			g_oneIndex = index
			YuanXiao_Lottery_ShowOneDrawFrame(index)
		elseif bShow == 2 then
			g_rewardIndexList[1] = Get_XParam_INT(5)
			g_rewardIndexList[2] = Get_XParam_INT(6)
			g_rewardIndexList[3] = Get_XParam_INT(7)
			g_rewardIndexList[4] = Get_XParam_INT(8)
			g_rewardIndexList[5] = Get_XParam_INT(9)
			g_rewardIndexList[6] = Get_XParam_INT(10)
			g_rewardIndexList[7] = Get_XParam_INT(11)
			g_rewardIndexList[8] = Get_XParam_INT(12)
			g_rewardIndexList[9] = Get_XParam_INT(13)
			g_rewardIndexList[10] = Get_XParam_INT(14)
			YuanXiao_Lottery_ShowTenDrawFrame()
		end
		YuanXiao_Lottery_UpdateCurrencyFrame(jixiangfu, ruyifu, jinzhu)
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20181205) then
		local bShow = tonumber(Get_XParam_INT(0));
		if bShow == 4 then
			if (this:IsVisible()) then
				local jixiangfu = DataPool:GetPlayerMission_DataRound(1759)
				local ruyifu = DataPool:GetPlayerMission_DataRound(1760)
				local jinzhu = DataPool:GetPlayerMission_DataRound(1728)
				YuanXiao_Lottery_UpdateCurrencyFrame(jixiangfu, ruyifu, jinzhu)
			end
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 恢复默认位置
		YuanXiao_Lottery_FrameNULL:SetProperty("UnifiedPosition", g_Position)
	elseif (event == "GAMELOGIN_SELECTCHARACTER") then
		this:Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "ADJEST_UI_POS") then
		YuanXiao_Lottery_FrameNULL:SetProperty("UnifiedPosition", g_Position)
	end
end

function YuanXiao_Lottery_ShowSelectFrame()

	local isDiscout = YuanXiao_Lottery_IsDiscount()
	
	if isDiscout == 1 then --打折期间
		YuanXiao_Lottery_SelectFrame:Show()
		--YuanXiao_Lottery_CurrencyB_Text1:SetText("#{MHCJ_181128_09}")
		--YuanXiao_Lottery_CurrencyB_OneTimeButtonTip_Normal:Hide()
		--YuanXiao_Lottery_CurrencyB_OneTimeButtonTip_Discount:Show()
		--YuanXiao_Lottery_CurrencyB_TenTimesButtonTip_Normal:Hide()
		--YuanXiao_Lottery_CurrencyB_TenTimesButtonTip_Discount:Show()

		--YuanXiao_Lottery_CurrencyA_Text1:SetText("#{MHCJ_181128_16}")
		--YuanXiao_Lottery_CurrencyA_OneTimeButtonTip_Normal:Hide()
		--YuanXiao_Lottery_CurrencyA_OneTimeButtonTip_Discount:Show()
		--YuanXiao_Lottery_CurrencyA_TenTimesButtonTip_Normal:Hide()
		--YuanXiao_Lottery_CurrencyA_TenTimesButtonTip_Discount:Show()
		YuanXiao_Lottery_Select_NormalButtonsFrame:Hide()
		YuanXiao_Lottery_Select_DiscountButtonsFrame:Show()
		YuanXiao_Lottery_DiscountText:Show()
	else --非打折期间
		YuanXiao_Lottery_SelectFrame:Show()
		--YuanXiao_Lottery_CurrencyB_Text1:SetText("")
		--YuanXiao_Lottery_CurrencyB_OneTimeButtonTip_Normal:Show()
		--YuanXiao_Lottery_CurrencyB_OneTimeButtonTip_Discount:Hide()
		--YuanXiao_Lottery_CurrencyB_TenTimesButtonTip_Normal:Show()
		--YuanXiao_Lottery_CurrencyB_TenTimesButtonTip_Discount:Hide()

		--YuanXiao_Lottery_CurrencyA_Text1:SetText("")
		--YuanXiao_Lottery_CurrencyA_OneTimeButtonTip_Normal:Show()
		--YuanXiao_Lottery_CurrencyA_OneTimeButtonTip_Discount:Hide()
		--YuanXiao_Lottery_CurrencyA_TenTimesButtonTip_Normal:Show()
		--YuanXiao_Lottery_CurrencyA_TenTimesButtonTip_Discount:Hide()
		YuanXiao_Lottery_Select_NormalButtonsFrame:Show()
		YuanXiao_Lottery_Select_DiscountButtonsFrame:Hide()
		YuanXiao_Lottery_DiscountText:Hide()
	end
	YuanXiao_Lottery_OneDrawFrame:Hide()
	YuanXiao_Lottery_TenDrawFrame:Hide()
	g_lastOptType = 0	
end

function YuanXiao_Lottery_ShowOneDrawFrame(index)
	YuanXiao_Lottery_SelectFrame:Hide()
	YuanXiao_Lottery_TenDrawFrame:Hide()
	YuanXiao_Lottery_OneDrawFrame:Show()
	YuanXiao_Lottery_DiscountText:Hide()
	YuanXiao_Lottery_OneDraw_Item1Fudai:Hide()
	if YuanXiao_Lottery_IsDiscount() == 1 then --折扣
		--YuanXiao_Lottery_OneDraw_AgainButtonTip_Normal:Hide()
		--YuanXiao_Lottery_OneDraw_AgainButtonTip_Discount:Show()
		YuanXiao_Lottery_OneDraw_AgainButton_NormalCurrencyB:Hide()
		YuanXiao_Lottery_OneDraw_AgainButton_NormalCurrencyA:Hide()
		if g_lastOptType == 1 then
			--YuanXiao_Lottery_OneDraw_RuyiDiscountIcon:Show()
			--YuanXiao_Lottery_OneDraw_JixiangDiscountIcon:Hide()
			YuanXiao_Lottery_OneDraw_AgainButton_DiscountCurrencyB:Show()
			YuanXiao_Lottery_OneDraw_AgainButton_DiscountCurrencyA:Hide()
		else
			--YuanXiao_Lottery_OneDraw_RuyiDiscountIcon:Hide()
			--YuanXiao_Lottery_OneDraw_JixiangDiscountIcon:Show()
			YuanXiao_Lottery_OneDraw_AgainButton_DiscountCurrencyB:Hide()
			YuanXiao_Lottery_OneDraw_AgainButton_DiscountCurrencyA:Show()
		end
	else
		--YuanXiao_Lottery_OneDraw_AgainButtonTip_Normal:Show()
		--YuanXiao_Lottery_OneDraw_AgainButtonTip_Discount:Hide()
		YuanXiao_Lottery_OneDraw_AgainButton_DiscountCurrencyB:Hide()
		YuanXiao_Lottery_OneDraw_AgainButton_DiscountCurrencyA:Hide()
		if g_lastOptType == 1 then
			--YuanXiao_Lottery_OneDraw_RuyiIcon:Show()
			--YuanXiao_Lottery_OneDraw_JixiangIcon:Hide()
			YuanXiao_Lottery_OneDraw_AgainButton_NormalCurrencyB:Show()
			YuanXiao_Lottery_OneDraw_AgainButton_NormalCurrencyA:Hide()
		else
			--YuanXiao_Lottery_OneDraw_JixiangIcon:Show()
			--YuanXiao_Lottery_OneDraw_RuyiIcon:Hide()
			YuanXiao_Lottery_OneDraw_AgainButton_NormalCurrencyB:Hide()
			YuanXiao_Lottery_OneDraw_AgainButton_NormalCurrencyA:Show()
		end
	end

	if g_lastOptType == 1 then
		g_rewardList = g_rewardList_ruyifu
		--rareNum = g_rareRuyi
		--YuanXiao_Lottery_OneDraw_Title:SetText(ScriptGlobal_Format("#{MHCJ_181128_25}", "#{MHCJ_181128_77}"))
		YuanXiao_Lottery_OneDraw_TitleRuyi:Show()
		YuanXiao_Lottery_OneDraw_Title:Hide()
	elseif g_lastOptType == 3 then
		g_rewardList = g_rewardList_jixiangfu
		--rareNum = g_rareJixiang
		--YuanXiao_Lottery_OneDraw_Title:SetText(ScriptGlobal_Format("#{MHCJ_181128_25}", "#{MHCJ_181128_76}"))
		YuanXiao_Lottery_OneDraw_TitleRuyi:Hide()
		YuanXiao_Lottery_OneDraw_Title:Show()
	end
	
	YuanXiao_Lottery_OneDraw_Item1Boom:Show()
	YuanXiao_Lottery_OneDraw_Item1Boom:Play(true)
	SetTimer("YuanXiao_Lottery","YuanXiao_Lottery_OneAnimeTimer()", 300)	
	--稀有
	
end

function YuanXiao_Lottery_OneAnimeTimer()
	--显示item
	KillTimer("YuanXiao_Lottery_OneAnimeTimer()")
	YuanXiao_Lottery_OneDraw_Item1Fudai:Show()
	local nItemId = g_rewardList[g_oneIndex].showId
	local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
	if theAction:GetID() ~= 0 then
		YuanXiao_Lottery_OneDraw_Item1:SetActionItem(theAction:GetID());
		YuanXiao_Lottery_OneDraw_Item1:Show()
		YuanXiao_Lottery_OneDraw_Item1Text:SetText(g_rewardList[g_oneIndex].num)
	else
		YuanXiao_Lottery_OneDraw_Item1:Hide()
	end

	local rareNum = 0
	if g_lastOptType == 1 then
		rareNum = g_rareRuyi
	elseif g_lastOptType == 3 then
		rareNum = g_rareJixiang
	end

	if g_rewardList[g_oneIndex].num >= rareNum then
		YuanXiao_Lottery_OneDraw_Item1Animate:Show()
		YuanXiao_Lottery_OneDraw_Item1Animate:Play(true)
	else
		YuanXiao_Lottery_OneDraw_Item1Animate:Play(false)
		YuanXiao_Lottery_OneDraw_Item1Animate:Hide()
	end
end

function YuanXiao_Lottery_ShowTenDrawFrame()
	YuanXiao_Lottery_SelectFrame:Hide()
	YuanXiao_Lottery_TenDrawFrame:Show()
	YuanXiao_Lottery_OneDrawFrame:Hide()
	YuanXiao_Lottery_DiscountText:Hide()
	if YuanXiao_Lottery_IsDiscount() == 1 then
		--YuanXiao_Lottery_TenDraw_AgainButtonTip_Normal:Hide()
		--YuanXiao_Lottery_TenDraw_AgainButtonTip_Discount:Show()
		YuanXiao_Lottery_TenDraw_AgainButton_NormalCurrencyB:Hide()
		YuanXiao_Lottery_TenDraw_AgainButton_NormalCurrencyA:Hide()
		if g_lastOptType == 2 then
			--YuanXiao_Lottery_TenDraw_RuyiDiscountIcon:Show()
			--YuanXiao_Lottery_TenDraw_JixiangDiscountIcon:Hide()
			YuanXiao_Lottery_TenDraw_TitleRuyi:Show()
			YuanXiao_Lottery_TenDraw_Title:Hide()
			--YuanXiao_Lottery_TenDraw_Title:SetText(ScriptGlobal_Format("#{MHCJ_181128_25}", "#{MHCJ_181128_77}"))
			YuanXiao_Lottery_TenDraw_AgainButton_DiscountCurrencyB:Show()
			YuanXiao_Lottery_TenDraw_AgainButton_DiscountCurrencyA:Hide()
		else
			--YuanXiao_Lottery_TenDraw_RuyiDiscountIcon:Hide()
			--YuanXiao_Lottery_TenDraw_JixiangDiscountIcon:Show()
			YuanXiao_Lottery_TenDraw_TitleRuyi:Hide()
			YuanXiao_Lottery_TenDraw_Title:Show()
			--YuanXiao_Lottery_TenDraw_Title:SetText(ScriptGlobal_Format("#{MHCJ_181128_25}", "#{MHCJ_181128_76}"))
			YuanXiao_Lottery_TenDraw_AgainButton_DiscountCurrencyB:Hide()
			YuanXiao_Lottery_TenDraw_AgainButton_DiscountCurrencyA:Show()
		end
	else
		--YuanXiao_Lottery_TenDraw_AgainButtonTip_Normal:Show()
		--YuanXiao_Lottery_TenDraw_AgainButtonTip_Discount:Hide()
		YuanXiao_Lottery_TenDraw_AgainButton_DiscountCurrencyB:Hide()
		YuanXiao_Lottery_TenDraw_AgainButton_DiscountCurrencyA:Hide()
		if g_lastOptType == 2 then
			--YuanXiao_Lottery_TenDraw_RuyiIcon:Show()
			--YuanXiao_Lottery_TenDraw_JixiangIcon:Hide()
			YuanXiao_Lottery_TenDraw_TitleRuyi:Show()
			YuanXiao_Lottery_TenDraw_Title:Hide()
			--YuanXiao_Lottery_TenDraw_Title:SetText(ScriptGlobal_Format("#{MHCJ_181128_25}", "#{MHCJ_181128_77}"))
			YuanXiao_Lottery_TenDraw_AgainButton_NormalCurrencyB:Show()
			YuanXiao_Lottery_TenDraw_AgainButton_NormalCurrencyA:Hide()
		else
			--YuanXiao_Lottery_TenDraw_RuyiIcon:Hide()
			--YuanXiao_Lottery_TenDraw_JixiangIcon:Show()
			YuanXiao_Lottery_TenDraw_TitleRuyi:Hide()
			YuanXiao_Lottery_TenDraw_Title:Show()
			--YuanXiao_Lottery_TenDraw_Title:SetText(ScriptGlobal_Format("#{MHCJ_181128_25}", "#{MHCJ_181128_76}"))
			YuanXiao_Lottery_TenDraw_AgainButton_NormalCurrencyB:Hide()
			YuanXiao_Lottery_TenDraw_AgainButton_NormalCurrencyA:Show()
		end
	end

	for index=1,table.getn(g_tenDrawItem) do
		g_tenFudai[index]:Hide()
		g_tenDrawItem[index]:Hide()
		g_tenDrawItemAnimate[index]:Play(false)
		g_tenDrawItemAnimate[index]:Hide()
		g_tenDrawItemBoom[index]:Play(false)
		g_tenDrawItemBoom[index]:Hide()
	end	

	--播放动画
	SetTimer("YuanXiao_Lottery","YuanXiao_Lottery_TenAnimeTimer()", 300)
	g_tenIndex = 1
	g_tenDrawItemBoom[g_tenIndex]:Show()
	g_tenDrawItemBoom[g_tenIndex]:Play(true)
end

function YuanXiao_Lottery_TenAnimeTimer()
	KillTimer("YuanXiao_Lottery_TenAnimeTimer()")
	--挨个播
	local rareNum = 0
	if g_lastOptType == 2 then
		g_rewardList = g_rewardList_ruyifu
		rareNum = g_rareRuyi
	elseif g_lastOptType == 4 then
		g_rewardList = g_rewardList_jixiangfu
		rareNum = g_rareJixiang
	end

	for index=1,table.getn(g_rewardIndexList) do
		if index == g_tenIndex then
			if g_rewardIndexList[index] > 0 then
				local rewardIndex = g_rewardIndexList[index]
				if rewardIndex > table.getn(g_rewardList) then
					return
				end
				local nItemId = g_rewardList[rewardIndex].showId
				if nItemId < 0 then
					return
				end	
				local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
				if theAction:GetID() ~= 0 then
					g_tenDrawItem[index]:SetActionItem(theAction:GetID());
					g_tenDrawItem[index]:Show()
					g_tenFudai[index]:Show()
					g_tenDrawItemText[index]:SetText(g_rewardList[rewardIndex].num)
				else
					g_tenDrawItem[index]:Hide()
				end
				if g_rewardList[rewardIndex].num >= rareNum then
					g_tenDrawItemAnimate[index]:Show()
					g_tenDrawItemAnimate[index]:Play(true)
				else
					g_tenDrawItemAnimate[index]:Hide()
					g_tenDrawItemAnimate[index]:Play(false)
				end
			end
		end
	end	
	g_tenIndex = g_tenIndex + 1
	if g_tenIndex <= 10 then
		SetTimer("YuanXiao_Lottery","YuanXiao_Lottery_TenAnimeTimer()", 300)
		g_tenDrawItemBoom[g_tenIndex]:Show()
		g_tenDrawItemBoom[g_tenIndex]:Play(true)
	end
end

function YuanXiao_Lottery_UpdateCurrencyFrame(jixiangfu, ruyifu, jinzhu)
	YuanXiao_Lottery_CurrencyFrame:Show()
	YuanXiao_Lottery_Currency_CurrencyBNum:SetText(ScriptGlobal_Format("#{MHCJ_181128_22}", ruyifu))
	YuanXiao_Lottery_Currency_CurrencyANum:SetText(ScriptGlobal_Format("#{MHCJ_181128_23}", jixiangfu))
	YuanXiao_Lottery_Currency_TicketNum:SetText(ScriptGlobal_Format("#{MHCJ_181128_24}", jinzhu))
end

function YuanXiao_Lottery_OnButtonClick(optId)
	if optId ~= 11 then
		g_lastOptType = optId
	end
	if optId == 1 then --左1单抽
		local curTime = OSAPI:GetTickCount();
		if ( curTime - g_LastOneDrawLeft < g_OneDrawCD * 1000) then
			PushDebugMessage("#{MHCJ_181128_35}"); --当前操作过快，请稍后点击
			return
		end
		g_LastOneDrawLeft = curTime;
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OneDrawClick")
			Set_XSCRIPT_ScriptID(893020)
			Set_XSCRIPT_Parameter(0 ,optId)
			Set_XSCRIPT_Parameter(1 ,g_targetId)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif optId == 2 then
		local curTime = OSAPI:GetTickCount();
		if ( curTime - g_LasTenDrawLeft < g_TenDrawCD * 1000) then
			PushDebugMessage("#{MHCJ_181128_35}"); --当前操作过快，请稍后点击
			return
		end
		g_LasTenDrawLeft = curTime;
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TenDrawClick")
			Set_XSCRIPT_ScriptID(893020)
			Set_XSCRIPT_Parameter(0 ,optId)
			Set_XSCRIPT_Parameter(1 ,g_targetId)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif optId == 3 then
		local curTime = OSAPI:GetTickCount();
		if ( curTime - g_LasOneDrawRight < g_OneDrawCD * 1000) then
			PushDebugMessage("#{MHCJ_181128_35}"); --当前操作过快，请稍后点击
			return
		end
		g_LasOneDrawRight = curTime;
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OneDrawClick")
			Set_XSCRIPT_ScriptID(893020)
			Set_XSCRIPT_Parameter(0 ,optId)
			Set_XSCRIPT_Parameter(1 ,g_targetId)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif optId == 4 then
		local curTime = OSAPI:GetTickCount();
		if ( curTime - g_LasTenDrawRight < g_TenDrawCD * 1000) then
			PushDebugMessage("#{MHCJ_181128_35}"); --当前操作过快，请稍后点击
			return
		end
		g_LasTenDrawRight = curTime;
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TenDrawClick")
			Set_XSCRIPT_ScriptID(893020)
			Set_XSCRIPT_Parameter(0 ,optId)
			Set_XSCRIPT_Parameter(1 ,g_targetId)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif optId == 11 then
		YuanXiao_Lottery_OnButtonClick(g_lastOptType)--单抽或者10连点了再抽
	end
end
--*********************************
-- 清空控件
--*********************************
function YuanXiao_Lottery_CleanupUIControls()
	SetDefaultMouse()

	g_LastOneDrawLeft = 0
    g_LasTenDrawLeft = 0
    g_LasOneDrawRight = 0
    g_LasTenDrawRight = 0
    g_rewardIndexList = {}	
    g_tenIndex = 0
    g_lastOptType = 0
    g_targetId = 0
	this:Hide()
end

function YuanXiao_Lottery_Close()
	YuanXiao_Lottery_CleanupUIControls()
end

function YuanXiao_Lottery_OnHiden()
	YuanXiao_Lottery_CleanupUIControls()
end

function YuanXiao_Lottery_IsDiscount()
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	
	if curTime2Day >= g_startDiscoutTm and curTime2Day <= g_endDiscoutTm then
		return 1
	end

	return 0
end