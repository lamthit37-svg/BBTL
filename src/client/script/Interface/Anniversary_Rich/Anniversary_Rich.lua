--周年庆 大富翁界面
local g_Anniversary_Rich_Frame_UnifiedPosition
local g_Anniversary_Rich_YeQianIndex = 1
local g_Anniversary_Rich_ItemNumPerPage = 12 --每页展示的物品个数
local g_Anniversary_Rich_MaxRound = 40
local g_Anniversary_Rich_CheckButtontabList = {}
-------------------------------页签1夺宝相关参数----------------------
local g_Anniversary_Rich_IsGotRewardUITable = {}
-- local g_Anniversary_Rich_Client1_ResultUITable = {}
local g_Anniversary_Rich_Client1_MoveStep = 0
local g_Anniversary_Rich_Client1_ShowCurOrder = 1
local g_Anniversary_Rich_Client1_ShowMaxOrder = 10

local g_Anniversary_Rich_PosData=
{
	[0]={posX=387,posY=81,faceDir=0},
	[1]={posX=448,posY=104,faceDir=0},
	[2]={posX=435,posY=158,faceDir=0},
	[3]={posX=500,posY=154,faceDir=0},
	[4]={posX=520,posY=102,faceDir=0},
	[5]={posX=564,posY=68,faceDir=0},
	[6]={posX=638,posY=72,faceDir=0},
	[7]={posX=695,posY=106,faceDir=0},
	[8]={posX=706,posY=160,faceDir=0},
	[9]={posX=732,posY=218,faceDir=0},
	[10]={posX=709,posY=270,faceDir=1},
	[11]={posX=639,posY=288,faceDir=1},
	[12]={posX=565,posY=269,faceDir=1},
	[13]={posX=490,posY=268,faceDir=1},
	[14]={posX=418,posY=286,faceDir=1},
	[15]={posX=427,posY=233,faceDir=1},
	[16]={posX=353,posY=228,faceDir=1},
	[17]={posX=292,posY=259,faceDir=1},
	[18]={posX=222,posY=278,faceDir=1},
	[19]={posX=143,posY=290,faceDir=1},
	[20]={posX=84,posY=264,faceDir=1},
	[21]={posX=74,posY=218,faceDir=1},
	[22]={posX=101,posY=176,faceDir=1},
	[23]={posX=41,posY=146,faceDir=1},
	[24]={posX=29,posY=89,faceDir=0},
	[25]={posX=88,posY=62,faceDir=0},
	[26]={posX=152,posY=71,faceDir=0},
	[27]={posX=219,posY=73,faceDir=0},
	[28]={posX=284,posY=98,faceDir=0},
	[29]={posX=316,posY=129,faceDir=0},
	
}

local g_Anniversary_Rich_RoundRewardItemId=
{
	[1]={itemId=38004960, num=1, round=2},
	[2]={itemId=38004960, num=1, round=4},
	[3]={itemId=38004960, num=1, round=8},
	[4]={itemId=38004960, num=1, round=14},
	[5]={itemId=38004960, num=1, round=20},
	[6]={itemId=38004960, num=1, round=28},
	[7]={itemId=38004960, num=1, round=40},
}

local g_Anniversary_Rich_TeamRoundRewardItemId=
{
	[1]={itemId=38004960, num=1, round=12},
	[2]={itemId=38004960, num=1, round=24},
	[3]={itemId=38004960, num=1, round=48},
	[4]={itemId=38004960, num=1, round=72},
	
}
local g_Anniversary_Rich_Client1_MapUITable = {}
local g_Anniversary_Rich_TenTimes_RewardUITable = {}
local g_Anniversary_Rich_CurPos = 0
local g_Anniversary_Rich_NewCurPos = 0

local g_Anniversary_Rich_Client1_TimePerUnit = 1000  
local g_Anniversary_Rich_Client1_TimePerUnitTenTimes = 350
local g_Anniversary_Rich_Client1_Delta = 30	--播动画时每帧的时间
local g_Anniversary_Rich_Client1_Timer = 0	--走一格累计的时间
local g_Anniversary_Rich_Client1_DeltaX = 0
local g_Anniversary_Rich_Client1_DeltaY = 0
local g_Anniversary_Rich_Client1_IsPlayAnim = 0

local g_Anniversary_Rich_Client1_Times = 1
local g_Anniversary_Rich_Client1_RealThrowCount = 10
--------------------------------------------------------------------------
local g_Anniversary_Rich_Client2_CurPageNum = 1
local g_Anniversary_Rich_Client2_ItemUITable = {}
local g_Anniversary_Rich_Client2_IsDismissState = 0
-------------------------------页签3碎片商店相关参数----------------------

local g_Anniversary_Rich_Client3_CurPageNum = 1 --当前商店界面所在的页数
local g_Anniversary_Rich_Client3_ItemUITable = {}
------------------------------------------------------------------------
local g_Anniversary_Rich_Client4_SelectIndexToKick = 0
local g_Anniversary_Rich_Client4_ItemListUI = {}
---------------------------------------------------

function Anniversary_Rich_PreLoad()
	this:RegisterEvent("DAFUWENG_DATA_REFRESH", true)
	this:RegisterEvent("DAFUWENG_OPEN_TEAMDETAIL",false)
	this:RegisterEvent("DAFUWENG_REWARD_CALLBACK",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("DAFUWENG_REWARD_FAIL",false)
	this:RegisterEvent("DAFUWENG_REFRESH_HOTPOINTTIPS",false)
	this:RegisterEvent("DAFUWENG_USE_TIANJICHOU",false)
	this:RegisterEvent("DAFUWENG_CANCEL_DISMISS",false)
end


function Anniversary_Rich_OnEvent(event)
	if event == "DAFUWENG_DATA_REFRESH" then
		-- PushDebugMessage("DAFUWENG_DATA_REFRESH")
		if this:IsVisible() == false then
			if Player:GetData("IsOriginalJD") == 1 and IsInTServer() == 1 then
				PushDebugMessage("无法在当前场景进行该操作。")
				return 
			end
			this:Show()
			DaFuWeng:AskTeamInfo(0)
			Anniversary_Rich_Page_Clicked(1)
		else
			Anniversary_Rich_Refresh(g_Anniversary_Rich_YeQianIndex,1)
		end
	elseif event == "DAFUWENG_OPEN_TEAMDETAIL" then
		if g_Anniversary_Rich_YeQianIndex == 4 then
			Anniversary_Rich_SetSelect()
			Anniversary_Rich_Client1:Hide()
			Anniversary_Rich_Client2:Hide()
			Anniversary_Rich_Client3:Hide()
			Anniversary_Rich_RefreshTeam()
		end
	elseif event == "DAFUWENG_REFRESH_HOTPOINTTIPS" then
		Anniversary_Rich_RefreshCheckButtonTips()
	elseif event == "DAFUWENG_CANCEL_DISMISS" then
		g_Anniversary_Rich_Client2_IsDismissState = 0
		
	elseif event == "DAFUWENG_USE_TIANJICHOU" then
		local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
		Anniversary_Rich_Client1_Currency2Number:SetText(ScriptGlobal_Format("#{ZNLSG_230215_29}", DiceCount))
	elseif event == "DAFUWENG_REWARD_CALLBACK" then
		g_Anniversary_Rich_Client1_Times = tonumber(arg0) 
		if g_Anniversary_Rich_Client1_Times == 10 then
			g_Anniversary_Rich_Client1_RealThrowCount = tonumber(arg1)
		end
		Anniversary_Rich_Client1_Result_Frame:Hide()
		Anniversary_Rich_Client1_Return1_Frame:Hide()
		Anniversary_Rich_Client1_Return2_Frame:Hide()

		PushEvent("DAFUWENG_CLOSE_POPUI")
		Anniversary_Rich_RewardAnimate()
		
	elseif event == "DAFUWENG_REWARD_FAIL" then
		g_Anniversary_Rich_Client1_IsPlayAnim = 0
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_Rich_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_Rich_Close()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Rich_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Rich_Close()
	end
	
end

function Anniversary_Rich_RefreshCheckButtonTips()
	Anniversary_Rich_Page2Tips:Hide()
	Anniversary_Rich_Page3Tips:Hide()
	local isShowYeQian1Tips = 0
	local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
	for i=1, 7 do
		if Round >= g_Anniversary_Rich_RoundRewardItemId[i].round then
			if math.mod(selfRoundReward, 2) == 0 then
				isShowYeQian1Tips = 1
			end
		end
		selfRoundReward = math.floor(selfRoundReward / 2)
	end
	if Round >= g_Anniversary_Rich_MaxRound and DiceCount > 0 then
		isShowYeQian1Tips = 1
	end
	if isShowYeQian1Tips == 1 then
		Anniversary_Rich_Page1Tips:Show()
	else
		Anniversary_Rich_Page1Tips:Hide()
	end

	local teamId,isLock,isTeamLeader = DaFuWeng:GetTeamID()
	local isShowYeQian4Tips = 0
	local teamThrowTimes = 0  --队伍投掷次数等于队伍所有人的累加
	for i=1, 6 do
		local name,menpaiId,level,throwTimes,isLeader = DaFuWeng:GetTeamMemberInfo(i-1)
		teamThrowTimes = teamThrowTimes + throwTimes
	end
	local teamRoundReward = DaFuWeng:GetDataByUI("Team")
	for i=1, 4 do
		if teamThrowTimes >= g_Anniversary_Rich_TeamRoundRewardItemId[i].round and math.mod(teamRoundReward, 2) == 0 and isLock == 1 then
			isShowYeQian4Tips = 1
		end
		teamRoundReward = math.floor(teamRoundReward / 2)
	end
	if isShowYeQian4Tips == 1 then
		Anniversary_Rich_Page4Tips:Show()
	else
		Anniversary_Rich_Page4Tips:Hide()
	end

end

function Anniversary_Rich_Refresh(index,isRefreshData)
	-- Anniversary_Rich_Page1Tips:Hide()
	Anniversary_Rich_RefreshCheckButtonTips()
	-- Anniversary_Rich_Page4Tips:Hide()
	PushEvent("DAFUWENG_CLOSE_POPUI")
	if index == 1 then
		Anniversary_Rich_Client1_Result_Frame:Hide()
		Anniversary_Rich_Client1_Return1_Frame:Hide()
		Anniversary_Rich_Client1_Return2_Frame:Hide()
		Anniversary_Rich_Client1_Result_Animate:Play(false)
		g_Anniversary_Rich_Client1_MoveStep = 0
		KillTimer("Anniversary_Rich_OnTimer()")
		--刷新夺宝界面控件
		local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
		-- PushDebugMessage("CurPos:"..CurPos)
		g_Anniversary_Rich_CurPos = CurPos
		-- PushDebugMessage("g_Anniversary_Rich_CurPos:"..g_Anniversary_Rich_CurPos)
		--设置小人的位置
		if g_Anniversary_Rich_PosData[CurPos] ~= nil then
			Anniversary_Rich_Client1_Start:SetProperty("UnifiedPosition","{{0,"..tostring(g_Anniversary_Rich_PosData[CurPos].posX).."},{0,"..tostring(g_Anniversary_Rich_PosData[CurPos].posY).."}}")
			Anniversary_Rich_TurnFace(g_Anniversary_Rich_PosData[CurPos].faceDir) 
		end
		--设置其他数据
		-- Anniversary_Rich_Client1_Self:SetText(tostring(Round))
		Anniversary_Rich_Client1_Self:SetText(ScriptGlobal_Format("#{ZNLSG_230215_90}", Round))
		-- Anniversary_Rich_Client1_Currency1Number:SetText(ScriptGlobal_Format("#{ZNLSG_230215_29}", Jifen))
		Anniversary_Rich_Client1_Currency2Number:SetText(ScriptGlobal_Format("#{ZNLSG_230215_29}", DiceCount))
		-- local isShowYeQianTips = 0
		if Round >= g_Anniversary_Rich_MaxRound and DiceCount > 0 then
			Anniversary_Rich_Client1_Currency2_Btn2_Tips:Show()
		else
			Anniversary_Rich_Client1_Currency2_Btn2_Tips:Hide()
		end
		--设置已领取标记 及领奖的小红点
		local kjtype   = KaJi:LuaFnGetKaJiType(127)
		if Player:GetData("IsOriginalJD") == 1 then
			for i=1, 30 do
				if g_Anniversary_Rich_Client1_MapUITable[i].Quality == 1 then
					g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_260401_4}")
				elseif g_Anniversary_Rich_Client1_MapUITable[i].Quality == 2 then
					g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_260401_2}")
				elseif g_Anniversary_Rich_Client1_MapUITable[i].Quality == 3 then
					g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_260401_3}")
				end
			end		
		else
			if kjtype == 1 then
				for i=1, 30 do
					if g_Anniversary_Rich_Client1_MapUITable[i].Quality == 1 then
						g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_230215_381}")
					elseif g_Anniversary_Rich_Client1_MapUITable[i].Quality == 2 then
						g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_230215_383}")
					elseif g_Anniversary_Rich_Client1_MapUITable[i].Quality == 3 then
						g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_230215_385}")
					end
				end
			else
				for i=1, 30 do
					if g_Anniversary_Rich_Client1_MapUITable[i].Quality == 1 then
						g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_230215_380}")
					elseif g_Anniversary_Rich_Client1_MapUITable[i].Quality == 2 then
						g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_230215_382}")
					elseif g_Anniversary_Rich_Client1_MapUITable[i].Quality == 3 then
						g_Anniversary_Rich_Client1_MapUITable[i].MapItem:SetToolTip("#{ZNLSG_230215_384}")
					end
				end
			end
		end
		
		for i=1, 7 do
			if math.mod(selfRoundReward, 2) ~= 0 then
				g_Anniversary_Rich_IsGotRewardUITable[i].GetMark:Show()
				g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:Disable()
			else
				g_Anniversary_Rich_IsGotRewardUITable[i].GetMark:Hide()
				g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:Enable()
			end
			
			if Round >= g_Anniversary_Rich_RoundRewardItemId[i].round and math.mod(selfRoundReward, 2) == 0 then
				--未领取且符合领取条件的
				g_Anniversary_Rich_IsGotRewardUITable[i].Animate:Show()
				
			else
				g_Anniversary_Rich_IsGotRewardUITable[i].Animate:Hide()
			end
			
			g_Anniversary_Rich_IsGotRewardUITable[i].RoundNumText:SetText(ScriptGlobal_Format("#{ZNLSG_230215_344}", g_Anniversary_Rich_RoundRewardItemId[i].round))
			if Player:GetData("IsOriginalJD") == 1 then
				if i == 6 then
					g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_260401_5}")
				elseif i == 4 then
					g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_02}")
				elseif i == 7 then
					g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_260401_1}")
				elseif i == 5 then
					g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_06}")
				end
			else		
				if kjtype == 1 then
					if i == 6 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_85}")
					elseif i == 4 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_02}")
					elseif i == 7 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_79}")
					elseif i == 5 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_06}")
					end
				else
					if i == 6 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_97}")
					elseif i == 4 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_95}")
					elseif i == 7 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_89}")
					elseif i == 5 then
						g_Anniversary_Rich_IsGotRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_96}")					
					end
				end
			end
		
			selfRoundReward = math.floor(selfRoundReward / 2)
		
		end
		local isGuaranteed,throwCount = DaFuWeng:GetDataByUI("isGuaranteed")
		if isGuaranteed == 1 then
			
			Anniversary_Rich_Client1_ActionTips:SetText("#{ZNLSG_230215_337}")
		else
			Anniversary_Rich_Client1_ActionTips:SetText(ScriptGlobal_Format("#{ZNLSG_230215_336}", throwCount))
		end
	
	elseif index == 2 then
		--刷新奖励物品箱界面控件
		if isRefreshData == 1 then
			local totleKindNum = DaFuWeng:GetBagTotleNum()
			local maxPageNum = math.ceil(totleKindNum/g_Anniversary_Rich_ItemNumPerPage)
			if maxPageNum<1 then
				maxPageNum = 1
			end
			if g_Anniversary_Rich_Client2_CurPageNum > maxPageNum then
				g_Anniversary_Rich_Client2_CurPageNum = maxPageNum
			end
			
		else
			g_Anniversary_Rich_Client2_CurPageNum = 1
			
		end
		Anniversary_Rich_Client2_Page()
		local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
		Anniversary_Rich_Client2_Currency:SetText(ScriptGlobal_Format("#{ZNLSG_230215_106}", Jifen))
	elseif index == 3 then
		--刷新商店界面控件
		if isRefreshData == 1 then
			local shopItemTotleNum = DaFuWeng:GetShopCount()
			local maxPageNum = math.ceil(shopItemTotleNum/g_Anniversary_Rich_ItemNumPerPage)
			if maxPageNum<1 then
				maxPageNum = 1
			end
			if g_Anniversary_Rich_Client3_CurPageNum > maxPageNum then
				g_Anniversary_Rich_Client3_CurPageNum = maxPageNum
			end
		else
			g_Anniversary_Rich_Client3_CurPageNum = 1
		end
		Anniversary_Rich_Client3_Show()
		--显示碎片数量
		local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
		Anniversary_Rich_Client3_Currency:SetText(ScriptGlobal_Format("#{ZNLSG_230215_153}", Jifen))
		
	end
	
end

function Anniversary_Rich_SetSelect()

	local nListCount = table.getn(g_Anniversary_Rich_CheckButtontabList)


	for i = 1, nListCount do
		if g_Anniversary_Rich_YeQianIndex == i then
			g_Anniversary_Rich_CheckButtontabList[i].CheckButton:SetCheck(1)
		else
			g_Anniversary_Rich_CheckButtontabList[i].CheckButton:SetCheck(0)
		end
	end
	
end

--切换页签 1-3  当前页面页签为1
function Anniversary_Rich_Page_Clicked(index)
	Anniversary_Rich_Client1_Action_Btn5_Rewards:Show()
	DaFuWeng:CancelDFWDismiss()
	g_Anniversary_Rich_Client2_IsDismissState = 0
	g_Anniversary_Rich_YeQianIndex = index
	if g_Anniversary_Rich_YeQianIndex == 4 then 
		g_Anniversary_Rich_Client1_IsPlayAnim = 0
		DaFuWeng:AskTeamInfo(1)
	else
		Anniversary_Rich_SetSelect()
		Anniversary_Rich_Client1:Hide()
		Anniversary_Rich_Client2:Hide()
		Anniversary_Rich_Client3:Hide()
		Anniversary_Rich_Client4:Hide()

		if g_Anniversary_Rich_YeQianIndex == 1 then
			--打开夺宝界面
			Anniversary_Rich_Client1:Show()
			if g_Anniversary_Rich_Client1_IsPlayAnim == 0 then
				Anniversary_Rich_Refresh(g_Anniversary_Rich_YeQianIndex,0)
			end
		elseif g_Anniversary_Rich_YeQianIndex == 2 then
			--打开抽中的奖励物品箱界面
			g_Anniversary_Rich_Client1_IsPlayAnim = 0
			Anniversary_Rich_Client2:Show()
			
			Anniversary_Rich_Refresh(g_Anniversary_Rich_YeQianIndex,0)
		elseif g_Anniversary_Rich_YeQianIndex == 3 then
			--打开兑换商店界面
			g_Anniversary_Rich_Client1_IsPlayAnim = 0
			Anniversary_Rich_Client3:Show()
			Anniversary_Rich_Refresh(g_Anniversary_Rich_YeQianIndex,0)
	
		end
	end

end

--帮助按钮点击
function Anniversary_Rich_Help_Clicked()
	PushEvent("CCSHOP_HELP", 183)
end

function Anniversary_Rich_On_ResetPos()
	Anniversary_Rich_Frame:SetProperty("UnifiedPosition", g_Anniversary_Rich_Frame_UnifiedPosition)

end

--界面隐藏事件
function Anniversary_Rich_Close()

	this:Hide()
	PushEvent("DAFUWENG_CLOSE_POPUI")
	g_Anniversary_Rich_YeQianIndex = 1
	
	g_Anniversary_Rich_Client2_CurPageNum = 1
	g_Anniversary_Rich_Client3_CurPageNum = 1
	Anniversary_Rich_Client4_List:Clear()	
	g_Anniversary_Rich_Client4_SelectIndexToKick = 0
	Anniversary_Rich_Client1_Result_Animate:Play(false)
	KillTimer("Anniversary_Rich_OnTimer()")
	g_Anniversary_Rich_Client1_MoveStep = 0
	g_Anniversary_Rich_Client1_Timer = 0
	g_Anniversary_Rich_Client1_DeltaX = 0
	g_Anniversary_Rich_Client1_DeltaY = 0
	g_Anniversary_Rich_Client1_IsPlayAnim = 0
	g_Anniversary_Rich_Client4_ItemListUI = {}
	g_Anniversary_Rich_Client1_ShowCurOrder = 1
	g_Anniversary_Rich_Client1_ShowMaxOrder = 10
	KillTimer("Anniversary_Rich_TimerProc()")

	DaFuWeng:CancelDFWDismiss()
	g_Anniversary_Rich_Client2_IsDismissState = 0
	
end

---------------------------------页签1夺宝的所有事件处理--------------------
--时装预览
function Anniversary_Rich_Client1_Action_Rewards_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, 10128683)
		Set_XSCRIPT_Parameter(1, 292)--hairId
		Set_XSCRIPT_Parameter(2, 212)--faceid
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
end

--弹抽签的动画
function Anniversary_Rich_RewardAnimate()
	
	Anniversary_Rich_Client1_Result_Frame:Show()

	Anniversary_Rich_Client1_Result_Animate:Play(true)
	KillTimer("Anniversary_Rich_OnTimer()")
	g_Anniversary_Rich_Client1_MoveStep = 1
	g_Anniversary_Rich_Client1_Timer = 0

end


function Anniversary_Rich_GetTable(tableId)
	local iteminfo = nil
	if Player:GetData("IsOriginalJD") == 1 then
		iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANCHANGESUIPIAN_ORI",tableId+1)
	else
		local kjtype   = KaJi:LuaFnGetKaJiType(127)

		if kjtype == 1 then
			iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANCHANGESUIPIAN_KAJI_1",tableId+1)
		else
			iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANCHANGESUIPIAN",tableId+1)
		end
	end

	return iteminfo
end


function Anniversary_Rich_GetShopTable(tableId)
	local iteminfo = nil
	if Player:GetData("IsOriginalJD") == 1 then
		iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANSHOP_ORI",tableId)
	else
		local kjtype   = KaJi:LuaFnGetKaJiType(127)			
		if kjtype == 1 then
			iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANSHOP_KAJI_1",tableId)
			else
				iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANSHOP",tableId)
		end
	end
	return iteminfo
end

function Anniversary_Rich_Client1_Result_OnDiceStop()

	local nStep = 0
	local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
	if g_Anniversary_Rich_Client1_Times == 1 then
		local tableId,count,step,isCross = DaFuWeng:GetRewardTableIdByIndex(0)
		nStep = step
		local tipStr = ScriptGlobal_Format("#{ZNLSG_230215_75}", nStep)
		if isCross == 1 then
			
			if Round >= g_Anniversary_Rich_MaxRound then
				tipStr = ScriptGlobal_Format("#{ZNLSG_230215_77}", nStep)
			else
				tipStr = ScriptGlobal_Format("#{ZNLSG_230215_76}", nStep, 1)
			end
			
		end
		PushDebugMessage(tipStr)
	else
		
		local throwCount = g_Anniversary_Rich_Client1_RealThrowCount
		local totleRoundNum = 0
		local totleStepNum = 0
		for i=1, 10 do
			local tableId,count,step,isCross = DaFuWeng:GetRewardTableIdByIndex(i-1)
			-- PushDebugMessage("tableId:"..tostring(tableId))
			if tableId >= 0 and i <= throwCount then
				-- g_Anniversary_Rich_TenTimes_RewardUITable[i].Frame:Show()

				local iteminfo = Anniversary_Rich_GetTable(tableId)
				if iteminfo then
					local theAction = DataPool:CreateActionItemForShow(iteminfo.nItemID, iteminfo.nItemCount)
					if theAction:GetID() ~= 0 then
						g_Anniversary_Rich_TenTimes_RewardUITable[i].ActionItem:SetActionItem(theAction:GetID())
					end
					if iteminfo.nIsShowEffect == 1 then
						g_Anniversary_Rich_TenTimes_RewardUITable[i].Animate:Show()
					else
						g_Anniversary_Rich_TenTimes_RewardUITable[i].Animate:Hide()
					end
					g_Anniversary_Rich_TenTimes_RewardUITable[i].ItemName:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
				end
		
				totleStepNum = totleStepNum + step
				if isCross == 1 then
					totleRoundNum = totleRoundNum + 1
				end
			end
			g_Anniversary_Rich_TenTimes_RewardUITable[i].Frame:Hide()
		
		end
		local tipStr = ScriptGlobal_Format("#{ZNLSG_230215_80}", totleStepNum)
		if totleRoundNum > 0 then
			if Round >= g_Anniversary_Rich_MaxRound then
				tipStr = ScriptGlobal_Format("#{ZNLSG_230215_83}", throwCount, totleStepNum)
			else
				tipStr = ScriptGlobal_Format("#{ZNLSG_230215_81}", totleStepNum, totleRoundNum)
			end
		end
		PushDebugMessage(tipStr)
		nStep = totleStepNum


	end

	local maxPos = table.getn(g_Anniversary_Rich_PosData)
	if g_Anniversary_Rich_CurPos + nStep > maxPos then
		g_Anniversary_Rich_NewCurPos = g_Anniversary_Rich_CurPos + nStep - maxPos - 1
	else
		g_Anniversary_Rich_NewCurPos = g_Anniversary_Rich_CurPos + nStep
	end
	SetTimer("Anniversary_Rich","Anniversary_Rich_OnTimer()",80)
end



function Anniversary_Rich_OnTimer()
	if g_Anniversary_Rich_Client1_MoveStep == 1 then
		g_Anniversary_Rich_Client1_MoveStep = 2
		Anniversary_Rich_Client1_Result_Frame:Hide()
		g_Anniversary_Rich_Client1_DeltaX = g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos].posX
		g_Anniversary_Rich_Client1_DeltaY = g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos].posY
		SetTimer("Anniversary_Rich","Anniversary_Rich_OnTimer()",g_Anniversary_Rich_Client1_Delta)
		return
	end
	if g_Anniversary_Rich_Client1_MoveStep == 2 then

		g_Anniversary_Rich_Client1_Timer = g_Anniversary_Rich_Client1_Timer + g_Anniversary_Rich_Client1_Delta
	
		local timePerUnit = g_Anniversary_Rich_Client1_TimePerUnitTenTimes
		if g_Anniversary_Rich_Client1_Times == 1 then
			timePerUnit = g_Anniversary_Rich_Client1_TimePerUnit
		end
		if g_Anniversary_Rich_Client1_Timer >= timePerUnit then
			g_Anniversary_Rich_Client1_Timer = 0
		
			g_Anniversary_Rich_CurPos = g_Anniversary_Rich_CurPos + 1
			if g_Anniversary_Rich_CurPos >= table.getn(g_Anniversary_Rich_PosData)+1 then
				g_Anniversary_Rich_CurPos = 0
			end
			if g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos] ~= nil then
				Anniversary_Rich_TurnFace(g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos].faceDir) 
			end
			
			if g_Anniversary_Rich_CurPos == g_Anniversary_Rich_NewCurPos then
				if g_Anniversary_Rich_Client1_Times == 1 then
					Anniversary_Rich_OpenThrowDiceReward_OneTimes()
					g_Anniversary_Rich_Client1_IsPlayAnim = 0
				else
					Anniversary_Rich_OpenThrowDiceReward_TenTimes(g_Anniversary_Rich_Client1_RealThrowCount)
				end
				KillTimer("Anniversary_Rich_OnTimer()")
			
			else
				g_Anniversary_Rich_Client1_DeltaX = g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos].posX
				g_Anniversary_Rich_Client1_DeltaY = g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos].posY
			end
		else
			if g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos] ~= nil then
				local curPosX = g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos].posX
				local curPosY = g_Anniversary_Rich_PosData[g_Anniversary_Rich_CurPos].posY
				local nextPos = g_Anniversary_Rich_CurPos + 1
				if nextPos >= table.getn(g_Anniversary_Rich_PosData)+1 then
					nextPos = 0
				end 
				local nextPosX = g_Anniversary_Rich_PosData[nextPos].posX
				local nextPosY = g_Anniversary_Rich_PosData[nextPos].posY
				local absX = math.abs(nextPosX-curPosX)
				local absY = math.abs(nextPosY-curPosY)

				local dirX = 1
				if nextPosX-curPosX < 0 then
					dirX = -1 
				end
				local Vx = absX / timePerUnit
				local dirY = 1
				if nextPosY-curPosY < 0 then
					dirY = -1 
				end
				local Vy = absY / timePerUnit
				g_Anniversary_Rich_Client1_DeltaX = g_Anniversary_Rich_Client1_DeltaX + dirX * Vx * g_Anniversary_Rich_Client1_Delta
				g_Anniversary_Rich_Client1_DeltaY = g_Anniversary_Rich_Client1_DeltaY + dirY * Vy * g_Anniversary_Rich_Client1_Delta
				
				Anniversary_Rich_Client1_Start:SetProperty("UnifiedPosition","{{0,"..tostring(g_Anniversary_Rich_Client1_DeltaX).."},{0,"..tostring(g_Anniversary_Rich_Client1_DeltaY).."}}")
			end

		end

	
	end
end

--点击预览所有奖励
function Anniversary_Rich_Client1_AllRewards_Clicked()
	PushEvent("DAFUWENG_OPEN_REWARD_DETAIL")
end


function Anniversary_Rich_Client1_Action_Clicked(rewardIndex)
	if g_Anniversary_Rich_Client1_IsPlayAnim == 1 then
		PushDebugMessage("#{ZNLSG_230215_74}")
		return
	end
	DaFuWeng:GetRoundReward(rewardIndex-1)
end


function Anniversary_Rich_OK_Clicked(times)
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZNLSG_230215_358}")     					
		return
	end

	if g_Anniversary_Rich_Client1_IsPlayAnim == 1 then
		PushDebugMessage("#{ZNLSG_230215_74}")
		return
	end
	PushEvent("DAFUWENG_CLOSE_REWARD_DETAIL")
	g_Anniversary_Rich_Client1_IsPlayAnim = 1
	if times == 10 then
		DaFuWeng:DiceTenTimes()
	else 
		DaFuWeng:DiceOne()
	end
end

--购买次数
function Anniversary_Rich_Client1_Currency2_BtnClicked()
	PushEvent("DAFUWENG_OPEN_BUYDICE")
end

--兑换
function Anniversary_Rich_Client1_Currency2_Btn2Clicked()
	DaFuWeng:ExchangeYB(0)
end


--更改朝向 0向右 1向左
function Anniversary_Rich_TurnFace(dir)
	if dir == 0 then
		Anniversary_Rich_Client1_StartRight:Show()
		Anniversary_Rich_Client1_StartLeft:Hide()
	else 
		Anniversary_Rich_Client1_StartRight:Hide()
		Anniversary_Rich_Client1_StartLeft:Show()
	end
end

function Anniversary_Rich_OpenThrowDiceReward_OneTimes()
	Anniversary_Rich_Refresh(g_Anniversary_Rich_YeQianIndex,1)
	Anniversary_Rich_Client1_Return1_Frame:Show()
	local tableId,count,step,isCross = DaFuWeng:GetRewardTableIdByIndex(0)


	local iteminfo = Anniversary_Rich_GetTable(tableId)

	if iteminfo then
		local theAction = DataPool:CreateActionItemForShow(iteminfo.nItemID, iteminfo.nItemCount)
		if theAction:GetID() ~= 0 then
			Anniversary_Rich_Client1_Return1_Item1:SetActionItem(theAction:GetID())
		end
		if iteminfo.nIsShowEffect == 1 then
			Anniversary_Rich_Client1_Return1_Item1_Animate:Show()
		else
			Anniversary_Rich_Client1_Return1_Item1_Animate:Hide()
		end
		Anniversary_Rich_Client1_Return1_Item1_Text:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
	end
	local tipStr = ScriptGlobal_Format("#{ZNLSG_230215_78}", iteminfo.nItemCount, DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
	PushDebugMessage(tipStr)
end

function Anniversary_Rich_OpenThrowDiceReward_TenTimes(throwCount)
	Anniversary_Rich_Refresh(g_Anniversary_Rich_YeQianIndex,1)
	Anniversary_Rich_Client1_Return2_Frame:Show()

	PushDebugMessage("#{ZNLSG_230215_84}")

	SetTimer("Anniversary_Rich","Anniversary_Rich_TimerProc()", 100)
	g_Anniversary_Rich_Client1_ShowCurOrder = 1
	g_Anniversary_Rich_Client1_ShowMaxOrder = throwCount
end

--十连奖励延迟显示
function Anniversary_Rich_TimerProc()
	if g_Anniversary_Rich_TenTimes_RewardUITable[g_Anniversary_Rich_Client1_ShowCurOrder] ~= nil then
		g_Anniversary_Rich_TenTimes_RewardUITable[g_Anniversary_Rich_Client1_ShowCurOrder].Frame:Show()
		if g_Anniversary_Rich_Client1_ShowCurOrder >= g_Anniversary_Rich_Client1_ShowMaxOrder then
			KillTimer("Anniversary_Rich_TimerProc()")
			g_Anniversary_Rich_Client1_IsPlayAnim = 0

		end
		g_Anniversary_Rich_Client1_ShowCurOrder = g_Anniversary_Rich_Client1_ShowCurOrder + 1
	end

end

function Anniversary_Rich_Client1_Return2_Close_Clicked()
	Anniversary_Rich_Client1_Return2_Frame:Hide()
end

function Anniversary_Rich_Client1_Return1_Close_Clicked()
	Anniversary_Rich_Client1_Return1_Frame:Hide()
end
-------------------------------------------------------------

---------------------------------页签2物品箱的所有事件处理--------------------
function Anniversary_Rich_Client2_Resolve_Clicked()
	DaFuWeng:EnterDFWDismiss()
	g_Anniversary_Rich_Client2_IsDismissState = 1
	
end

function Anniversary_Rich_Client2_Page()
	Anniversary_Rich_Client2_NoItem1:Hide()
	local totleKindNum = DaFuWeng:GetBagTotleNum()
	local maxPageNum = math.ceil(totleKindNum/g_Anniversary_Rich_ItemNumPerPage)
	if maxPageNum<1 then
		maxPageNum = 1
	end

	if g_Anniversary_Rich_Client2_CurPageNum == 1 then
		Anniversary_Rich_Client2_UpPage:Disable()
	else
		Anniversary_Rich_Client2_UpPage:Enable()
	end

	if g_Anniversary_Rich_Client2_CurPageNum == maxPageNum then
		Anniversary_Rich_Client2_DownPage:Disable()
	else
		Anniversary_Rich_Client2_DownPage:Enable()
	end

	Anniversary_Rich_Client2_CurrentlyPage:SetText(ScriptGlobal_Format("#{ZNLSG_230215_120}", g_Anniversary_Rich_Client2_CurPageNum,maxPageNum))

	
	--领取
	if totleKindNum <= 0 then
		Anniversary_Rich_Client2_NoItem1:Show()
	end
	
	local curPageTotleNum = totleKindNum-(g_Anniversary_Rich_Client2_CurPageNum-1)*g_Anniversary_Rich_ItemNumPerPage
	for i = 1,table.getn(g_Anniversary_Rich_Client2_ItemUITable) do
		if i > curPageTotleNum then
			g_Anniversary_Rich_Client2_ItemUITable[i].ItemFrame:Hide()
		else
			g_Anniversary_Rich_Client2_ItemUITable[i].ItemFrame:Show()
			g_Anniversary_Rich_Client2_ItemUITable[i].LimitMask:Hide()
			local tableId,itemCount = DaFuWeng:GetBagDataByIndex((g_Anniversary_Rich_Client2_CurPageNum-1)*g_Anniversary_Rich_ItemNumPerPage+i-1)

			g_Anniversary_Rich_Client2_ItemUITable[i].LimitNum:SetText(itemCount)

			local iteminfo = Anniversary_Rich_GetTable(tableId)
			if iteminfo then
				-- PushDebugMessage("tableid:"..tostring(iteminfo.nID))
			-- PushDebugMessage("nSort:"..tostring(iteminfo.nSort))
				local theAction = DataPool:CreateActionItemForShow(iteminfo.nItemID, iteminfo.nItemCount)
				if theAction:GetID() ~= 0 then
					g_Anniversary_Rich_Client2_ItemUITable[i].ActionItem:SetActionItem(theAction:GetID())
				end
				g_Anniversary_Rich_Client2_ItemUITable[i].ItemName:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
			
				g_Anniversary_Rich_Client2_ItemUITable[i].DisassembleNum:Show()
				g_Anniversary_Rich_Client2_ItemUITable[i].DisassembleMark:Show()
				if iteminfo.nIsCanDismiss == 0 then
					g_Anniversary_Rich_Client2_ItemUITable[i].DisassembleNum:SetText("#{ZNLSG_230215_347}")
				else
					g_Anniversary_Rich_Client2_ItemUITable[i].DisassembleNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_389}", iteminfo.nSuiPianNum))
				end
			end
		end
	end

end

function Anniversary_Rich_Client2_ItemClicked(index)
	if index<1 or index>12 then
		return
	end
	-- PushEvent("DAFUWENG_CLOSE_POPUI")
	local tableId,itemCount = DaFuWeng:GetBagDataByIndex((g_Anniversary_Rich_Client2_CurPageNum-1)*g_Anniversary_Rich_ItemNumPerPage+index-1)
	if tableId == nil or tableId < 0 then
		return 
	end

	local iteminfo = Anniversary_Rich_GetTable(tableId)
	if iteminfo then

		if g_Anniversary_Rich_Client2_IsDismissState == 0 then
			--领取
			-- PushDebugMessage("tableId:"..tostring(tableId))
			PushEvent("DAFUWENG_OPEN_GOTITEM", tableId, itemCount)

		else
		-- PushDebugMessage("tableId:"..tostring(tableId))
			if iteminfo.nIsCanDismiss == 0 then
				PushDebugMessage("#{ZNLSG_230215_345}")
			else
				--分解
				PushEvent("DAFUWENG_OPEN_DISASSEMBLE", tableId, itemCount)
			end

			DaFuWeng:CancelDFWDismiss()
			g_Anniversary_Rich_Client2_IsDismissState = 0
		end
	end
	
	
end

function Anniversary_Rich_Client2_PageUp()
	if g_Anniversary_Rich_Client2_CurPageNum > 1 then
		g_Anniversary_Rich_Client2_CurPageNum = g_Anniversary_Rich_Client2_CurPageNum - 1
		
		Anniversary_Rich_Client2_Page()
	end
end

function Anniversary_Rich_Client2_PageDown()
	local totleKindNum = DaFuWeng:GetBagTotleNum()
	local maxPageNum = math.ceil(totleKindNum/g_Anniversary_Rich_ItemNumPerPage)
	if g_Anniversary_Rich_Client2_CurPageNum < maxPageNum then
		g_Anniversary_Rich_Client2_CurPageNum = g_Anniversary_Rich_Client2_CurPageNum + 1
		
		Anniversary_Rich_Client2_Page()
	end
end

-------------------------------------------------------------

---------------------------------页签3碎片商店的所有事件处理--------------------
function Anniversary_Rich_Client3_Show()

	local shopItemTotleNum = DaFuWeng:GetShopCount()
	local maxPageNum = math.ceil(shopItemTotleNum/g_Anniversary_Rich_ItemNumPerPage)
	if maxPageNum<1 then
		maxPageNum = 1
	end

	if g_Anniversary_Rich_Client3_CurPageNum == 1 then
		Anniversary_Rich_Client3_UpPage:Disable()
	else
		Anniversary_Rich_Client3_UpPage:Enable()
	end

	if g_Anniversary_Rich_Client3_CurPageNum == maxPageNum then
		Anniversary_Rich_Client3_DownPage:Disable()
	else
		Anniversary_Rich_Client3_DownPage:Enable()
	end

	local kjtype   = KaJi:LuaFnGetKaJiType(127)

	if Player:GetData("IsOriginalJD") == 1 then
		--删减服
		Anniversary_Rich_Client3_InfoText:SetText("#{ZNLSG_230215_18}")
	else
		if kjtype == 1 then
			--卡级服
			Anniversary_Rich_Client3_InfoText:SetText("#{ZNLSG_230215_18}")
		else
			Anniversary_Rich_Client3_InfoText:SetText("#{ZNLSG_230215_56}")
		end
	end


	local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")


	Anniversary_Rich_Client3_CurrentlyPage:SetText(ScriptGlobal_Format("#{ZNLSG_230215_120}", g_Anniversary_Rich_Client3_CurPageNum,maxPageNum))
	local curPageTotleNum = shopItemTotleNum-(g_Anniversary_Rich_Client3_CurPageNum-1)*g_Anniversary_Rich_ItemNumPerPage
	for i = 1,table.getn(g_Anniversary_Rich_Client3_ItemUITable) do
		if i > curPageTotleNum then
			g_Anniversary_Rich_Client3_ItemUITable[i].ItemFrame:Hide()
		else
			g_Anniversary_Rich_Client3_ItemUITable[i].ItemFrame:Show()
			g_Anniversary_Rich_Client3_ItemUITable[i].LimitMask:Hide()
			g_Anniversary_Rich_Client3_ItemUITable[i].LimitNumBK:Hide()
			g_Anniversary_Rich_Client3_ItemUITable[i].SellOut:Hide()
			
			g_Anniversary_Rich_Client3_ItemUITable[i].Eye:Hide()
			local tableId = (g_Anniversary_Rich_Client3_CurPageNum-1)*g_Anniversary_Rich_ItemNumPerPage+i
			local iteminfo = Anniversary_Rich_GetShopTable(tableId)


			local buyTimes = DaFuWeng:GetItemBuyTimes(tableId-1)
			if iteminfo then
				local theAction = DataPool:CreateActionItemForShow(iteminfo.nItemID, iteminfo.nSaleCount)
				if theAction:GetID() ~= 0 then
					g_Anniversary_Rich_Client3_ItemUITable[i].ActionItem:SetActionItem(theAction:GetID())
				end
				g_Anniversary_Rich_Client3_ItemUITable[i].ItemName:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
				
				g_Anniversary_Rich_Client3_ItemUITable[i].ItemPrice:SetText(ScriptGlobal_Format("#{ZNLSG_230215_390}",iteminfo.nPrice))
				
				if iteminfo.nItemID == 10128233 then
					g_Anniversary_Rich_Client3_ItemUITable[i].Eye:Show()
				end
				if Round >= iteminfo.nCanBuyCircle then
					if iteminfo.nLimit > 0 then
						g_Anniversary_Rich_Client3_ItemUITable[i].LimitBuy:Show()
						if iteminfo.nLimit-buyTimes > 0 then 
							g_Anniversary_Rich_Client3_ItemUITable[i].LimitNumBK:Show()
							g_Anniversary_Rich_Client3_ItemUITable[i].LimitNum:SetText(tostring(iteminfo.nLimit-buyTimes))
						end
					else
						g_Anniversary_Rich_Client3_ItemUITable[i].LimitBuy:Hide()
					end
					if iteminfo.nLimit > 0 and buyTimes >= iteminfo.nLimit then
						g_Anniversary_Rich_Client3_ItemUITable[i].SellOut:Show()
						g_Anniversary_Rich_Client3_ItemUITable[i].LimitMask:Show()
						g_Anniversary_Rich_Client3_ItemUITable[i].ActionItem:Disable()
					end
				else
					--未达到购买圈数
					g_Anniversary_Rich_Client3_ItemUITable[i].LimitMask:Show()
					-- g_Anniversary_Rich_Client3_ItemUITable[i].LimitBuy:Hide()
					-- g_Anniversary_Rich_Client3_ItemUITable[i].ActionItem:Disable()
					if iteminfo.nLimit > 0 then
						g_Anniversary_Rich_Client3_ItemUITable[i].LimitBuy:Show()
						if iteminfo.nLimit-buyTimes > 0 then 
							g_Anniversary_Rich_Client3_ItemUITable[i].LimitNumBK:Show()
							g_Anniversary_Rich_Client3_ItemUITable[i].LimitNum:SetText(tostring(iteminfo.nLimit-buyTimes))
						end
					else
						g_Anniversary_Rich_Client3_ItemUITable[i].LimitBuy:Hide()
					end

				end

			end


		end

	end

end

--特殊的
function Anniversary_Rich_Client3_EyeSign(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, 10127709)
		Set_XSCRIPT_Parameter(1, 0)--hairId
		Set_XSCRIPT_Parameter(2, 0)--faceid
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end
function Anniversary_Rich_Client3_ItemClicked(index)
	if index<1 or index>12 then
		return
	end
	local tableId = (g_Anniversary_Rich_Client3_CurPageNum-1)*g_Anniversary_Rich_ItemNumPerPage+index
	if tableId == nil or tableId < 0 then
		return 
	end
	local iteminfo = Anniversary_Rich_GetShopTable(tableId)


	if iteminfo then
		local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
		if Round >= iteminfo.nCanBuyCircle then
			PushEvent("DAFUWENG_OPEN_EXCHANGEITEM", tableId)
		else
			PushDebugMessage("#{ZNLSG_230818_03}")
		end
	end
end

function Anniversary_Rich_Client3_PageUp()
	if g_Anniversary_Rich_Client3_CurPageNum > 1 then
		g_Anniversary_Rich_Client3_CurPageNum = g_Anniversary_Rich_Client3_CurPageNum - 1
		Anniversary_Rich_Client3_Show()
	end
end

function Anniversary_Rich_Client3_PageDown()
	local shopItemTotleNum = DaFuWeng:GetShopCount()
	local maxPageNum = math.ceil(shopItemTotleNum/g_Anniversary_Rich_ItemNumPerPage)
	if g_Anniversary_Rich_Client3_CurPageNum < maxPageNum then
		g_Anniversary_Rich_Client3_CurPageNum = g_Anniversary_Rich_Client3_CurPageNum + 1
		Anniversary_Rich_Client3_Show()
	end
end


-------------------------------------------------------------

----------------------页签4 组队---------------------------

function Anniversary_Rich_RefreshTeam()
	Anniversary_Rich_RefreshCheckButtonTips()
	g_Anniversary_Rich_Client4_ItemListUI = {}
	--刷新组队界面控件
	Anniversary_Rich_Client4:Show()
	local teamId,isLock,isTeamLeader = DaFuWeng:GetTeamID()
	-- PushDebugMessage("teamId:"..tostring(teamId))
	-- PushDebugMessage("isLock:"..tostring(isLock))
	-- PushDebugMessage("isTeamLeader:"..tostring(isTeamLeader))
	--按钮的控制显隐也要写
	if teamId < 0 then
		Anniversary_Rich_Client4_TeamStatus:SetText("#{ZNLSG_230215_331}")
		Anniversary_Rich_Client4_Team:SetText("#{ZNLSG_230215_173}")
		Anniversary_Rich_Client4_ListActionFrame:Hide()
		Anniversary_Rich_Client4_NoList:Show()
		Anniversary_Rich_Client4_ListBK:Hide()
		Anniversary_Rich_Client4_List:Hide()
		-- Anniversary_Rich_Client4_TeamID:SetText(ScriptGlobal_Format("#{ZNLSG_230215_273}", tostring(-1)))
	else
		Anniversary_Rich_Client4_ListActionFrame:Show()
		Anniversary_Rich_Client4_NoList:Hide()
		Anniversary_Rich_Client4_ListBK:Show()
		if isLock == 1 then
			Anniversary_Rich_Client4_ListButton1:Disable()
			Anniversary_Rich_Client4_TeamStatus:SetText("#{ZNLSG_230215_275}")
		else
			Anniversary_Rich_Client4_ListButton1:Enable()
			Anniversary_Rich_Client4_TeamStatus:SetText("#{ZNLSG_230215_274}")
		end
		if isTeamLeader == 1 then
			Anniversary_Rich_Client4_ListButton1:Show()
			
			Anniversary_Rich_Client4_ListButton2:Show()
			Anniversary_Rich_Client4_ListButton3:Show()
		else
			Anniversary_Rich_Client4_ListButton1:Hide()
			Anniversary_Rich_Client4_ListButton2:Hide()
			Anniversary_Rich_Client4_ListButton3:Hide()
		end
		-- Anniversary_Rich_Client4_TeamID:SetText(ScriptGlobal_Format("#{ZNLSG_230215_273}", tostring(teamId)))
		Anniversary_Rich_Client4_List:Show()
		Anniversary_Rich_Client4_List:Clear()		
		for i=1, 6 do
			local name,menpaiId,level,throwTimes,isLeader = DaFuWeng:GetTeamMemberInfo(i-1)
			if level > 0 then
				local bar = Anniversary_Rich_Client4_List:AddChild("Anniversary_Rich_Client4_ListItem")
				g_Anniversary_Rich_Client4_ItemListUI[i] = bar
				if nil ~= bar then
					bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Text1"):SetText("#L"..name)
					bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Text2"):SetText("#L"..Anniversary_Rich_GetMenpaiName(menpaiId))
					bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Text3"):SetText("#L"..tostring(level))
					bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Text4"):SetText("#L"..tostring(throwTimes))
					if isLeader == 1 then
						bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Pic1"):Show()
						bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Pic2"):Hide()
					else
						bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Pic1"):Hide()
						bar:GetSubItem("Anniversary_Rich_Client4_ListItem_Pic2"):Show()
					end

					bar:SetEvent("MouseLClick", string.format("Anniversary_Rich_Client4_ItemClicked(%d)", i))
				end
			end
		end

	end
	local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")

	local teamThrowTimes = 0  --队伍投掷次数等于队伍所有人的累加
	for i=1, 6 do
		local name,menpaiId,level,throwTimes,isLeader = DaFuWeng:GetTeamMemberInfo(i-1)
		teamThrowTimes = teamThrowTimes + throwTimes
	end

	Anniversary_Rich_Client4_Team:SetText(ScriptGlobal_Format("#{ZNLSG_230215_172}", tostring(teamThrowTimes)))
	--组队圈数奖励情况展示
	local teamRoundReward = DaFuWeng:GetDataByUI("Team")
	local kjtype   = KaJi:LuaFnGetKaJiType(127)
	--设置已领取标记 及领奖的小红点
	for i=1, 4 do
		if math.mod(teamRoundReward, 2) ~= 0 then
			g_Anniversary_Rich_IsGotTeamRewardUITable[i].GetMark:Show()
			g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:Disable()
		else
			g_Anniversary_Rich_IsGotTeamRewardUITable[i].GetMark:Hide()
			g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:Enable()
		end
		
		if teamThrowTimes >= g_Anniversary_Rich_TeamRoundRewardItemId[i].round and math.mod(teamRoundReward, 2) == 0 and isLock == 1 then
			--未领取且符合领取条件的
			g_Anniversary_Rich_IsGotTeamRewardUITable[i].Animate:Show()
		else
			g_Anniversary_Rich_IsGotTeamRewardUITable[i].Animate:Hide()
		end
		
		g_Anniversary_Rich_IsGotTeamRewardUITable[i].RoundNumText:SetText(ScriptGlobal_Format("#{ZNLSG_230215_344}", g_Anniversary_Rich_TeamRoundRewardItemId[i].round))

		teamRoundReward = math.floor(teamRoundReward / 2)

		if Player:GetData("IsOriginalJD") == 1 then
			if i == 3 then
				g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_04}")
			elseif i == 4 then
				g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_05}")
			end
		else
			if kjtype == 1 then
				if i == 3 then
					g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_04}")
				elseif i == 4 then
					g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230818_05}")
				end
			else
				if i == 3 then
					g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_177}")
				elseif i == 4 then
					g_Anniversary_Rich_IsGotTeamRewardUITable[i].ActionItem:SetToolTip("#{ZNLSG_230215_178}")
				end
			end
		end

	end

end


function Anniversary_Rich_Client4_Action_Clicked(rewardIndex)
	DaFuWeng:GetTeamRoundReward(rewardIndex-1)
end


function Anniversary_Rich_Client4_ItemClicked(nIndex)
	Anniversary_Rich_Client4_SetItemSelected(nIndex)
	g_Anniversary_Rich_Client4_SelectIndexToKick = nIndex
end

function Anniversary_Rich_Client4_ListButton_Clicked(index)

	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")     					
		return
	end
	if index == 1 then
		--锁定队伍
		DaFuWeng:LockTeam(0)
	elseif index == 2 then
		--解散队伍
		DaFuWeng:DissMissTeam(0)
	elseif index == 3 then
		--请离队伍
		if g_Anniversary_Rich_Client4_SelectIndexToKick < 1 or g_Anniversary_Rich_Client4_SelectIndexToKick > 6 then
			PushDebugMessage("#{ZNLSG_230215_303}")
			return
		end
		DaFuWeng:KickTeamMember(g_Anniversary_Rich_Client4_SelectIndexToKick-1,0)
	elseif index == 4 then
		--退出队伍
		DaFuWeng:LeaveTeam(0)
	end
end

function Anniversary_Rich_Client4_SetItemSelected(nIndex)
	for i = 1, 6 do		
		if g_Anniversary_Rich_Client4_ItemListUI[i] ~= nil then		
			if i == nIndex then
				g_Anniversary_Rich_Client4_ItemListUI[i]:GetSubItem("Anniversary_Rich_Client4_ListItemCheck"):SetCheck(1)
			
			else
				g_Anniversary_Rich_Client4_ItemListUI[i]:GetSubItem("Anniversary_Rich_Client4_ListItemCheck"):SetCheck(0)
			end
		end
	end
end

function Anniversary_Rich_GetMenpaiName(menpai)
	local strMenPai = ""
	if(0 == menpai) then
		strMenPai = "少林";
	elseif(1 == menpai) then
		strMenPai = "明教";
	elseif(2 == menpai) then
		strMenPai = "丐帮";
	elseif(3 == menpai) then
		strMenPai = "武当";
	elseif(4 == menpai) then
		strMenPai = "峨嵋";
	elseif(5 == menpai) then
		strMenPai = "星宿";
	elseif(6 == menpai) then
		strMenPai = "天龙";
	elseif(7 == menpai) then
		strMenPai = "天山";
	elseif(8 == menpai) then
		strMenPai = "逍遥";
	elseif(10 == menpai) then
		strMenPai = "慕容";
	elseif(11 == menpai) then
		strMenPai = "唐门";
	elseif(12 == menpai) then
		strMenPai = "鬼谷";
	elseif(13 == menpai) then
		strMenPai = "#{XQ_MP_15}"; --桃花岛
	elseif(14 == menpai) then
		strMenPai = "#{XMPHM_210604_01}"; 
	elseif(15 == menpai) then--menpai15 mptodo
		strMenPai = "#{GMGameInterface_Script_DataPool_Info_ERenGu}"; 
	else
		strMenPai = "无门派";
	end
	return strMenPai
end

----------------------------------------------------------
function Anniversary_Rich_OnLoad()
	g_Anniversary_Rich_Frame_UnifiedPosition = Anniversary_Rich_Frame:GetProperty("UnifiedPosition")
	g_Anniversary_Rich_CheckButtontabList=
	{
		[1] =
		{
			CheckButton = Anniversary_Rich_Page1,
			ButtonTips = Anniversary_Rich_Page1Tips,
		},
		[2] =
		{
			CheckButton = Anniversary_Rich_Page2,
			ButtonTips = Anniversary_Rich_Page2Tips,
		},
		[3] =
		{
			CheckButton = Anniversary_Rich_Page3,
			ButtonTips = Anniversary_Rich_Page3Tips,
		},
		[4] =
		{
			CheckButton = Anniversary_Rich_Page4,
			ButtonTips = Anniversary_Rich_Page4Tips,
		},
	}

	g_Anniversary_Rich_IsGotRewardUITable=
	{
		[1] = {
			ActionItem = Anniversary_Rich_Client1_Action_Btn1,
			GetMark = Anniversary_Rich_Client1_Action_GetMark1,
			Animate = Anniversary_Rich_Client1_Action_Tips1,
			RoundNumText = Anniversary_Rich_Client1_Action_ProgressText1,
		},
		[2] = {
			ActionItem = Anniversary_Rich_Client1_Action_Btn2,
			GetMark = Anniversary_Rich_Client1_Action_GetMark2,
			Animate = Anniversary_Rich_Client1_Action_Tips2,
			RoundNumText = Anniversary_Rich_Client1_Action_ProgressText2,
		},
		[3] = {
			ActionItem = Anniversary_Rich_Client1_Action_Btn3,
			GetMark = Anniversary_Rich_Client1_Action_GetMark3,
			Animate = Anniversary_Rich_Client1_Action_Tips3,
			RoundNumText = Anniversary_Rich_Client1_Action_ProgressText3,
		},
		[4] = {
			ActionItem = Anniversary_Rich_Client1_Action_Btn4,
			GetMark = Anniversary_Rich_Client1_Action_GetMark4,
			Animate = Anniversary_Rich_Client1_Action_Tips4,
			RoundNumText = Anniversary_Rich_Client1_Action_ProgressText4,
		},
		[5] = {
			ActionItem = Anniversary_Rich_Client1_Action_Btn5,
			GetMark = Anniversary_Rich_Client1_Action_GetMark5,
			Animate = Anniversary_Rich_Client1_Action_Tips5,
			RoundNumText = Anniversary_Rich_Client1_Action_ProgressText5,
		},
		[6] = {
			ActionItem = Anniversary_Rich_Client1_Action_Btn6,
			GetMark = Anniversary_Rich_Client1_Action_GetMark6,
			Animate = Anniversary_Rich_Client1_Action_Tips6,
			RoundNumText = Anniversary_Rich_Client1_Action_ProgressText6,
		},
		[7] = {
			ActionItem = Anniversary_Rich_Client1_Action_Btn7,
			GetMark = Anniversary_Rich_Client1_Action_GetMark7,
			Animate = Anniversary_Rich_Client1_Action_Tips7,
			RoundNumText = Anniversary_Rich_Client1_Action_ProgressText7,
		},
		
	}

	g_Anniversary_Rich_IsGotTeamRewardUITable=
	{
		[1] = {
			ActionItem = Anniversary_Rich_Client4_Action_Btn1,
			GetMark = Anniversary_Rich_Client4_Action_GetMark1,
			Animate = Anniversary_Rich_Client4_Action_Tips1,
			RoundNumText = Anniversary_Rich_Client4_Action_ProgressText1,
		},
		[2] = {
			ActionItem = Anniversary_Rich_Client4_Action_Btn2,
			GetMark = Anniversary_Rich_Client4_Action_GetMark2,
			Animate = Anniversary_Rich_Client4_Action_Tips2,
			RoundNumText = Anniversary_Rich_Client4_Action_ProgressText2,
		},
		[3] = {
			ActionItem = Anniversary_Rich_Client4_Action_Btn3,
			GetMark = Anniversary_Rich_Client4_Action_GetMark3,
			Animate = Anniversary_Rich_Client4_Action_Tips3,
			RoundNumText = Anniversary_Rich_Client4_Action_ProgressText3,
		},
		[4] = {
			ActionItem = Anniversary_Rich_Client4_Action_Btn4,
			GetMark = Anniversary_Rich_Client4_Action_GetMark4,
			Animate = Anniversary_Rich_Client4_Action_Tips4,
			RoundNumText = Anniversary_Rich_Client4_Action_ProgressText4,
		},
		
	}

	g_Anniversary_Rich_TenTimes_RewardUITable=
	{
		[1]={
			Frame = Anniversary_Rich_Client1_Return2_Item1_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item1,
			ItemName = Anniversary_Rich_Client1_Return2_Item1_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item1_Animate,
		},
		[2]={
			Frame = Anniversary_Rich_Client1_Return2_Item2_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item2,
			ItemName = Anniversary_Rich_Client1_Return2_Item2_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item2_Animate,
		},
		[3]={
			Frame = Anniversary_Rich_Client1_Return2_Item3_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item3,
			ItemName = Anniversary_Rich_Client1_Return2_Item3_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item3_Animate,
		},
		[4]={
			Frame = Anniversary_Rich_Client1_Return2_Item4_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item4,
			ItemName = Anniversary_Rich_Client1_Return2_Item4_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item4_Animate,
		},
		[5]={
			Frame = Anniversary_Rich_Client1_Return2_Item5_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item5,
			ItemName = Anniversary_Rich_Client1_Return2_Item5_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item5_Animate,
		},
		[6]={
			Frame = Anniversary_Rich_Client1_Return2_Item6_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item6,
			ItemName = Anniversary_Rich_Client1_Return2_Item6_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item6_Animate,
		},
		[7]={
			Frame = Anniversary_Rich_Client1_Return2_Item7_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item7,
			ItemName = Anniversary_Rich_Client1_Return2_Item7_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item7_Animate,
		},
		[8]={
			Frame = Anniversary_Rich_Client1_Return2_Item8_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item8,
			ItemName = Anniversary_Rich_Client1_Return2_Item8_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item8_Animate,
		},
		[9]={
			Frame = Anniversary_Rich_Client1_Return2_Item9_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item9,
			ItemName = Anniversary_Rich_Client1_Return2_Item9_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item9_Animate,
		},
		[10]={
			Frame = Anniversary_Rich_Client1_Return2_Item10_Frame,
			ActionItem = Anniversary_Rich_Client1_Return2_Item10,
			ItemName = Anniversary_Rich_Client1_Return2_Item10_Text,
			Animate = Anniversary_Rich_Client1_Return2_Item10_Animate,
		},
	}


	g_Anniversary_Rich_Client2_ItemUITable = 
	{
		[1] = {
			ItemFrame = Anniversary_Rich_Client2_Item1Frame,
			ActionItem = Anniversary_Rich_Client2_Item1,
			ItemName = Anniversary_Rich_Client2_ItemInfo1_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo1_Currency,
			LimitMask = Anniversary_Rich_Client2_Item1_Mask,
			LimitNum = Anniversary_Rich_Client2_Item1_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo1_CurrencyIcon,
		},
		[2] = {
			ItemFrame = Anniversary_Rich_Client2_Item2Frame,
			ActionItem = Anniversary_Rich_Client2_Item2,
			ItemName = Anniversary_Rich_Client2_ItemInfo2_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo2_Currency,
			LimitMask = Anniversary_Rich_Client2_Item2_Mask,
			LimitNum = Anniversary_Rich_Client2_Item2_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo2_CurrencyIcon,
		},
		[3] = {
			ItemFrame = Anniversary_Rich_Client2_Item3Frame,
			ActionItem = Anniversary_Rich_Client2_Item3,
			ItemName = Anniversary_Rich_Client2_ItemInfo3_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo3_Currency,
			LimitMask = Anniversary_Rich_Client2_Item3_Mask,
			LimitNum = Anniversary_Rich_Client2_Item3_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo3_CurrencyIcon,
		},
		[4] = {
			ItemFrame = Anniversary_Rich_Client2_Item4Frame,
			ActionItem = Anniversary_Rich_Client2_Item4,
			ItemName = Anniversary_Rich_Client2_ItemInfo4_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo4_Currency,
			LimitMask = Anniversary_Rich_Client2_Item4_Mask,
			LimitNum = Anniversary_Rich_Client2_Item4_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo4_CurrencyIcon,
		},
		[5] = {
			ItemFrame = Anniversary_Rich_Client2_Item5Frame,
			ActionItem = Anniversary_Rich_Client2_Item5,
			ItemName = Anniversary_Rich_Client2_ItemInfo5_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo5_Currency,
			LimitMask = Anniversary_Rich_Client2_Item5_Mask,
			LimitNum = Anniversary_Rich_Client2_Item5_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo5_CurrencyIcon,
		},
		[6] = {
			ItemFrame = Anniversary_Rich_Client2_Item6Frame,
			ActionItem = Anniversary_Rich_Client2_Item6,
			ItemName = Anniversary_Rich_Client2_ItemInfo6_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo6_Currency,
			LimitMask = Anniversary_Rich_Client2_Item6_Mask,
			LimitNum = Anniversary_Rich_Client2_Item6_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo6_CurrencyIcon,
		},
		[7] = {
			ItemFrame = Anniversary_Rich_Client2_Item7Frame,
			ActionItem = Anniversary_Rich_Client2_Item7,
			ItemName = Anniversary_Rich_Client2_ItemInfo7_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo7_Currency,
			LimitMask = Anniversary_Rich_Client2_Item7_Mask,
			LimitNum = Anniversary_Rich_Client2_Item7_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo7_CurrencyIcon,
		},
		[8] = {
			ItemFrame = Anniversary_Rich_Client2_Item8Frame,
			ActionItem = Anniversary_Rich_Client2_Item8,
			ItemName = Anniversary_Rich_Client2_ItemInfo8_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo8_Currency,
			LimitMask = Anniversary_Rich_Client2_Item8_Mask,
			LimitNum = Anniversary_Rich_Client2_Item8_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo8_CurrencyIcon,
		},
		[9] = {
			ItemFrame = Anniversary_Rich_Client2_Item9Frame,
			ActionItem = Anniversary_Rich_Client2_Item9,
			ItemName = Anniversary_Rich_Client2_ItemInfo9_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo9_Currency,
			LimitMask = Anniversary_Rich_Client2_Item9_Mask,
			LimitNum = Anniversary_Rich_Client2_Item9_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo9_CurrencyIcon,
		},
		[10] = {
			ItemFrame = Anniversary_Rich_Client2_Item10Frame,
			ActionItem = Anniversary_Rich_Client2_Item10,
			ItemName = Anniversary_Rich_Client2_ItemInfo10_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo10_Currency,
			LimitMask = Anniversary_Rich_Client2_Item10_Mask,
			LimitNum = Anniversary_Rich_Client2_Item10_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo10_CurrencyIcon,
		},
		[11] = {
			ItemFrame = Anniversary_Rich_Client2_Item11Frame,
			ActionItem = Anniversary_Rich_Client2_Item11,
			ItemName = Anniversary_Rich_Client2_ItemInfo11_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo11_Currency,
			LimitMask = Anniversary_Rich_Client2_Item11_Mask,
			LimitNum = Anniversary_Rich_Client2_Item11_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo11_CurrencyIcon,
		},
		[12] = {
			ItemFrame = Anniversary_Rich_Client2_Item12Frame,
			ActionItem = Anniversary_Rich_Client2_Item12,
			ItemName = Anniversary_Rich_Client2_ItemInfo12_Text,
			DisassembleNum = Anniversary_Rich_Client2_ItemInfo12_Currency,
			LimitMask = Anniversary_Rich_Client2_Item12_Mask,
			LimitNum = Anniversary_Rich_Client2_Item12_BuyLimitNum,
			DisassembleMark = Anniversary_Rich_Client2_ItemInfo12_CurrencyIcon,
		},
	}

	g_Anniversary_Rich_Client3_ItemUITable = 
	{
		[1] = {
			ItemFrame = Anniversary_Rich_Client3_Item1Frame,
			ActionItem = Anniversary_Rich_Client3_Item1,
			ItemName = Anniversary_Rich_Client3_ItemInfo1_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo1_Currency,
			SellOut = Anniversary_Rich_Client3_Item1_Mask2,
			Eye = Anniversary_Rich_Client3_Item1_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item1_Mask,
			LimitNum = Anniversary_Rich_Client3_Item1_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item1_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item1_BuyLimit,
		},
		[2] = {
			ItemFrame = Anniversary_Rich_Client3_Item2Frame,
			ActionItem = Anniversary_Rich_Client3_Item2,
			ItemName = Anniversary_Rich_Client3_ItemInfo2_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo2_Currency,
			SellOut = Anniversary_Rich_Client3_Item2_Mask2,
			Eye = Anniversary_Rich_Client3_Item2_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item2_Mask,
			LimitNum = Anniversary_Rich_Client3_Item2_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item2_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item2_BuyLimit,
		},
		[3] = {
			ItemFrame = Anniversary_Rich_Client3_Item3Frame,
			ActionItem = Anniversary_Rich_Client3_Item3,
			ItemName = Anniversary_Rich_Client3_ItemInfo3_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo3_Currency,
			SellOut = Anniversary_Rich_Client3_Item3_Mask2,
			Eye = Anniversary_Rich_Client3_Item3_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item3_Mask,
			LimitNum = Anniversary_Rich_Client3_Item3_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item3_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item3_BuyLimit,
		},
		[4] = {
			ItemFrame = Anniversary_Rich_Client3_Item4Frame,
			ActionItem = Anniversary_Rich_Client3_Item4,
			ItemName = Anniversary_Rich_Client3_ItemInfo4_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo4_Currency,
			SellOut = Anniversary_Rich_Client3_Item4_Mask2,
			Eye = Anniversary_Rich_Client3_Item4_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item4_Mask,
			LimitNum = Anniversary_Rich_Client3_Item4_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item4_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item4_BuyLimit,
		},
		[5] = {
			ItemFrame = Anniversary_Rich_Client3_Item5Frame,
			ActionItem = Anniversary_Rich_Client3_Item5,
			ItemName = Anniversary_Rich_Client3_ItemInfo5_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo5_Currency,
			SellOut = Anniversary_Rich_Client3_Item5_Mask2,
			Eye = Anniversary_Rich_Client3_Item5_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item5_Mask,
			LimitNum = Anniversary_Rich_Client3_Item5_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item5_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item5_BuyLimit,
		},
		[6] = {
			ItemFrame = Anniversary_Rich_Client3_Item6Frame,
			ActionItem = Anniversary_Rich_Client3_Item6,
			ItemName = Anniversary_Rich_Client3_ItemInfo6_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo6_Currency,
			SellOut = Anniversary_Rich_Client3_Item6_Mask2,
			Eye = Anniversary_Rich_Client3_Item6_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item6_Mask,
			LimitNum = Anniversary_Rich_Client3_Item6_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item6_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item6_BuyLimit,
		},
		[7] = {
			ItemFrame = Anniversary_Rich_Client3_Item7Frame,
			ActionItem = Anniversary_Rich_Client3_Item7,
			ItemName = Anniversary_Rich_Client3_ItemInfo7_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo7_Currency,
			SellOut = Anniversary_Rich_Client3_Item7_Mask2,
			Eye = Anniversary_Rich_Client3_Item7_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item7_Mask,
			LimitNum = Anniversary_Rich_Client3_Item7_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item7_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item7_BuyLimit,
		},
		[8] = {
			ItemFrame = Anniversary_Rich_Client3_Item8Frame,
			ActionItem = Anniversary_Rich_Client3_Item8,
			ItemName = Anniversary_Rich_Client3_ItemInfo8_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo8_Currency,
			SellOut = Anniversary_Rich_Client3_Item8_Mask2,
			Eye = Anniversary_Rich_Client3_Item8_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item8_Mask,
			LimitNum = Anniversary_Rich_Client3_Item8_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item8_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item8_BuyLimit,
		},
		[9] = {
			ItemFrame = Anniversary_Rich_Client3_Item9Frame,
			ActionItem = Anniversary_Rich_Client3_Item9,
			ItemName = Anniversary_Rich_Client3_ItemInfo9_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo9_Currency,
			SellOut = Anniversary_Rich_Client3_Item9_Mask2,
			Eye = Anniversary_Rich_Client3_Item9_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item9_Mask,
			LimitNum = Anniversary_Rich_Client3_Item9_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item9_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item9_BuyLimit,
		},
		[10] = {
			ItemFrame = Anniversary_Rich_Client3_Item10Frame,
			ActionItem = Anniversary_Rich_Client3_Item10,
			ItemName = Anniversary_Rich_Client3_ItemInfo10_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo10_Currency,
			SellOut = Anniversary_Rich_Client3_Item10_Mask2,
			Eye = Anniversary_Rich_Client3_Item10_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item10_Mask,
			LimitNum = Anniversary_Rich_Client3_Item10_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item10_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item10_BuyLimit,
		},
		[11] = {
			ItemFrame = Anniversary_Rich_Client3_Item11Frame,
			ActionItem = Anniversary_Rich_Client3_Item11,
			ItemName = Anniversary_Rich_Client3_ItemInfo11_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo11_Currency,
			SellOut = Anniversary_Rich_Client3_Item11_Mask2,
			Eye = Anniversary_Rich_Client3_Item11_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item11_Mask,
			LimitNum = Anniversary_Rich_Client3_Item11_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item11_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item11_BuyLimit,
		},
		[12] = {
			ItemFrame = Anniversary_Rich_Client3_Item12Frame,
			ActionItem = Anniversary_Rich_Client3_Item12,
			ItemName = Anniversary_Rich_Client3_ItemInfo12_Text,
			ItemPrice = Anniversary_Rich_Client3_ItemInfo12_Currency,
			SellOut = Anniversary_Rich_Client3_Item12_Mask2,
			Eye = Anniversary_Rich_Client3_Item12_EyeSign,
			LimitMask = Anniversary_Rich_Client3_Item12_Mask,
			LimitNum = Anniversary_Rich_Client3_Item12_BuyLimitNum,
			LimitNumBK = Anniversary_Rich_Client3_Item12_BuyLimitNumBK,
			LimitBuy = Anniversary_Rich_Client3_Item12_BuyLimit,
		},
	}

	g_Anniversary_Rich_Client1_MapUITable = 
	{
		[1] = 
		{
			MapItem = Anniversary_Rich_Client1_Item1BK,
			Quality = 3,
		},
		[2] = 
		{
			MapItem = Anniversary_Rich_Client1_Item2BK,
			Quality = 2,
		},
		[3] = 
		{
			MapItem = Anniversary_Rich_Client1_Item3BK,
			Quality = 1,
		},
		[4] = 
		{
			MapItem = Anniversary_Rich_Client1_Item4BK,
			Quality = 2,
		},
		[5] = 
		{
			MapItem = Anniversary_Rich_Client1_Item5BK,
			Quality = 1,
		},
		[6] = 
		{
			MapItem = Anniversary_Rich_Client1_Item6BK,
			Quality = 2,
		},
		[7] = 
		{
			MapItem = Anniversary_Rich_Client1_Item7BK,
			Quality = 3,
		},
		[8] = 
		{
			MapItem = Anniversary_Rich_Client1_Item8BK,
			Quality = 1,
		},
		[9] = 
		{
			MapItem = Anniversary_Rich_Client1_Item9BK,
			Quality = 2,
		},
		[10] = 
		{
			MapItem = Anniversary_Rich_Client1_Item10BK,
			Quality = 2,
		},
		[11] = 
		{
			MapItem = Anniversary_Rich_Client1_Item11BK,
			Quality = 1,
		},
		[12] = 
		{
			MapItem = Anniversary_Rich_Client1_Item12BK,
			Quality = 2,
		},
		[13] = 
		{
			MapItem = Anniversary_Rich_Client1_Item13BK,
			Quality = 3,
		},
		[14] = 
		{
			MapItem = Anniversary_Rich_Client1_Item14BK,
			Quality = 2,
		},
		[15] = 
		{
			MapItem = Anniversary_Rich_Client1_Item15BK,
			Quality = 2,
		},
		[16] = 
		{
			MapItem = Anniversary_Rich_Client1_Item16BK,
			Quality = 1,
		},
		[17] = 
		{
			MapItem = Anniversary_Rich_Client1_Item17BK,
			Quality = 2,
		},
		[18] = 
		{
			MapItem = Anniversary_Rich_Client1_Item18BK,
			Quality = 1,
		},
		[19] = 
		{
			MapItem = Anniversary_Rich_Client1_Item19BK,
			Quality = 3,
		},
		[20] = 
		{
			MapItem = Anniversary_Rich_Client1_Item20BK,
			Quality = 2,
		},
		[21] = 
		{
			MapItem = Anniversary_Rich_Client1_Item21BK,
			Quality = 1,
		},
		[22] = 
		{
			MapItem = Anniversary_Rich_Client1_Item22BK,
			Quality = 1,
		},
		[23] = 
		{
			MapItem = Anniversary_Rich_Client1_Item23BK,
			Quality = 2,
		},
		[24] = 
		{
			MapItem = Anniversary_Rich_Client1_Item24BK,
			Quality = 2,
		},
		[25] = 
		{
			MapItem = Anniversary_Rich_Client1_Item25BK,
			Quality = 3,
		},
		[26] = 
		{
			MapItem = Anniversary_Rich_Client1_Item26BK,
			Quality = 1,
		},
		[27] = 
		{
			MapItem = Anniversary_Rich_Client1_Item27BK,
			Quality = 2,
		},
		[28] = 
		{
			MapItem = Anniversary_Rich_Client1_Item28BK,
			Quality = 2,
		},
		[29] = 
		{
			MapItem = Anniversary_Rich_Client1_Item29BK,
			Quality = 1,
		},
		[30] = 
		{
			MapItem = Anniversary_Rich_Client1_Item30BK,
			Quality = 2,
		},
		
	}

	
end