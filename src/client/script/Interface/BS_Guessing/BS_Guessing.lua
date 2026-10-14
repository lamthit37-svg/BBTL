-- [比武竞猜] 

---------------------------------------------------------------------------
local g_Controls = {};									-- 控件
local g_TableSel = 1
local g_Position = "{{0.500000,-290.000000},{0.500000,-300.000000}}";
local g_Guess = {}
local g_FinalDay = {}
local g_TeamIDList = {}
local g_VSList = {}
local g_TeamNameList = {}
local g_TeamIDListL = {}
local g_TeamIDListR = {}
local g_LimitHour = 17
local g_NpcObjId = 0
local g_WinNum = 0
local g_LoseNum = 0
local g_FinalSupportName
local g_UICommand = 89306002
local g_MF = {3742,3743,3744,3745,3746}
local g_CurrentHour = 0
local g_ServerObjId = 0
local g_lunkong = "#{JHSJC_190120_96}"
local g_emptyNum = 0
local g_reqdate = 0
local g_MD_XBW_GUESS_DAIBI = 2564
local g_MD_XBW_GUESSLOTTERY_TIMES = 2565
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function BS_Guessing_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "OPEN_GUESS_FRAME" );
	this : RegisterEvent( "UPDATE_GUESS_FRAME" );
	this : RegisterEvent( "CANNOTOPEN_GUESS_FRAME" );
	this : RegisterEvent( "UPDATE_SERVER_TIME_UI" );
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED",false );		-- 游戏分辨率发生了变化
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED",false );		-- 离开场景
	this : RegisterEvent( "ADJEST_UI_POS" , false);
	
end


--*********************************
-- OnLoad
--*********************************
function BS_Guessing_OnLoad()
	g_Controls = {
		-- 框架
		Framework = BS_GuessingFrame;
		-- 标签页
		Table = {
			[1] = BS_Guessing_RoundOf16_Button;
			[2] = BS_Guessing_RoundOf8_Button;
			[3] = BS_Guessing_QuarterFinals_Button;
			[4] = BS_Guessing_SemiFinals_Button;
			[5] = BS_Guessing_Finals_Button;
		};
		RedPoit = {
			[1] = BS_Guessing_RoundOf16_ButtonTip;
			[2] = BS_Guessing_RoundOf8_ButtonTip;
			[3] = BS_Guessing_QuarterFinals_ButtonTip;
			[4] = BS_Guessing_SemiFinals_ButtonTip;
			[5] = BS_Guessing_Finals_ButtonTip;
		};
		RewardText = BS_Guessing_RewardText;
		RewardButton = BS_Guessing_RewardButton;
	};
end


--*********************************
-- OnEvent
--*********************************
function BS_Guessing_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 89306001) then
		-- 关心NPC
		if tonumber( Get_XParam_INT(0)) == 1 then
			--g_TableSel = tonumber( Get_XParam_INT(1)) 
			g_ServerObjId = tonumber(Get_XParam_INT(1))
			g_NpcObjId = Target:GetServerId2ClientId(g_ServerObjId);
			this:CareObject(g_NpcObjId, 1, "BS_Guessing");
			g_CurrentHour =  Get_XParam_INT(2)
			AskServerTimeAgain()
		elseif tonumber( Get_XParam_INT(0)) == 2 then--支持左边
			local nIndex = tonumber( Get_XParam_INT(1)) --当前第几场比赛的索引
			BS_Guessing_SupportLeft(nIndex)
		elseif tonumber( Get_XParam_INT(0)) == 3 then--支持右边	
			local nIndex = tonumber( Get_XParam_INT(1)) --当前第几场比赛的索引
			BS_Guessing_SupportRight(nIndex)
		elseif tonumber( Get_XParam_INT(0)) == 4 then--领奖刷新按钮
			BS_Guessing_RewardButton:Show()
			BS_Guessing_RewardButton:SetText("已领奖")
			BS_Guessing_RewardButton:Disable()
			local timeLeft = DataPool:GetPlayerMission_DataRound(g_MD_XBW_GUESSLOTTERY_TIMES)
			timeLeft = math.mod(timeLeft, 10)
			local daibi = DataPool:GetPlayerMission_DataRound(g_MD_XBW_GUESS_DAIBI)
			BS_Guessing_GuessingPointText:SetText(ScriptGlobal_Format("#{JHSJC_190120_88}", daibi))
			BS_Guessing_LotteryPointText:SetText(ScriptGlobal_Format("#{JHSJC_190120_90}", timeLeft))
			BS_Guessing_ShowRedPoint(g_TableSel)
		end

	elseif (event == "OPEN_GUESS_FRAME") then
		BS_Guessing_CleanupUIControls()
		BS_Guessing_InitDate()
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		local index = BS_Guessing_FinalIndex(curTime2Day)
		g_TableSel = index
		g_reqdate = curTime2Day
		BS_Guessing_OnUpdate(g_TableSel);
		this:Show();
	--elseif (event == "UPDATE_GUESS_FRAME") then
		--if (this:IsVisible()) then
			--BS_Guessing_OnUpdate();
		--end
	elseif (event == "UPDATE_GUESS_FRAME") then
		BS_Guessing_CleanupUIControls()
		BS_Guessing_InitDate()
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		g_reqdate = curTime2Day
		BS_Guessing_OnUpdate(g_TableSel)
	elseif ( event == "CANNOTOPEN_GUESS_FRAME" ) then
		-- 32强没数据 
		BS_Guessing_CleanupUIControls()
		this:Hide()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("CanNotOpen")
			Set_XSCRIPT_ScriptID(893060)
			Set_XSCRIPT_Parameter(0, g_ServerObjId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif	(event == "ADJEST_UI_POS" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	elseif ( event == "UPDATE_SERVER_TIME_UI" ) then
		if ( this:IsVisible() ) then
			-- 更新
			--BS_Guessing_ShowFenYe()
		end
	end
end


--*********************************
-- 清空控件
--*********************************
function BS_Guessing_CleanupUIControls()
	SetDefaultMouse()
	-- 标签页
	for i = 1, 5 do
		g_Controls.Table[i]:Show()
		g_Controls.Table[i]:Enable()
		if g_TableSel == i then
			g_Controls.Table[i]:SetCheck(1)
		else
			g_Controls.Table[i]:SetCheck(0)
		end
	end
	g_Controls.RewardText:SetText("")
	g_Controls.RewardButton:Show()
	g_FinalDay = {}
	g_Guess = {}
	BS_Guessing_List:CleanAllElement("BS_Guessing")
	g_WinNum = 0
    g_LoseNum = 0
    BS_Guessing_RewardText:SetText("")
end


--*********************************
-- 显示
--*********************************
function BS_Guessing_OnUpdate(nIndex)
	-- 清空控件
	g_TeamIDList = {}
	g_TeamNameList = {}
	g_TeamIDListL = {}
	g_TeamIDListR = {}
	g_VSList = {}
	BS_GuessingFrame:Show()
	BS_Guessing_ShowFenYe()
	BS_Guessing_ShowRedPoint(nIndex)
	BS_Guessing_ShowVSList(nIndex)
	BS_Guessing_ShowReward(nIndex)
	local timeLeft = DataPool:GetPlayerMission_DataRound(g_MD_XBW_GUESSLOTTERY_TIMES)
	timeLeft = math.mod(timeLeft, 10)
	local daibi = DataPool:GetPlayerMission_DataRound(g_MD_XBW_GUESS_DAIBI)
	BS_Guessing_GuessingPointText:SetText(ScriptGlobal_Format("#{JHSJC_190120_88}", daibi))
	BS_Guessing_LotteryPointText:SetText(ScriptGlobal_Format("#{JHSJC_190120_90}", timeLeft))
end

function BS_Guessing_InitDate()
--总决赛日期
	for i = 1, 5 do
		local finalDay = BWDH2018:GetFinalDayByIndex(i)
		if finalDay ~= 0 then
			g_FinalDay[i] = finalDay
		end
	end
	--玩家猜的结果
	for j = 1, 31 do
		g_Guess[j] = BWDH2018:GetPlayerGuess(j)
	end
	local curHour = tonumber(DataPool:GetServerMinuteTime())
	curHour = curHour/10000
	if curHour >= 1900 then
		curHour = curHour - 1900
	end
	if curHour > g_CurrentHour then
		g_CurrentHour = curHour
	end
end

function BS_Guessing_ShowReward(nIndex)
	BS_Guessing_RewardButton:Show()
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	local index = BS_Guessing_FinalIndex(curTime2Day)
	BS_Guessing_RewardButton:SetText("#{JHSJC_190120_24}")

	if curTime2Day <= g_FinalDay[nIndex] then
		local tarDay = g_FinalDay[nIndex]--20190722
		local nDay = math.mod(tarDay, 100)
		local tmp = math.floor(tarDay/100)
		local month = math.mod(tmp, 100)
		local text = ScriptGlobal_Format("#{JHSJC_190120_20}", month,nDay)
		BS_Guessing_RewardText:SetText(text)--不可以领取
		BS_Guessing_RewardButton:Disable()
	else
		if nIndex ~= 5 then
			if g_emptyNum > 0 then
				local text = ScriptGlobal_Format("#{JHSJC_190120_100}", g_WinNum+g_LoseNum, g_WinNum, g_emptyNum)
				BS_Guessing_RewardText:SetText(text)--可以领取
				BS_Guessing_RewardButton:Enable()
			else
				local text = ScriptGlobal_Format("#{JHSJC_190120_21}", g_WinNum+g_LoseNum, g_WinNum)
				BS_Guessing_RewardText:SetText(text)--可以领取
				if g_WinNum == 0 and g_LoseNum == 0 then--没猜
					BS_Guessing_RewardButton:Disable()
				else
					BS_Guessing_RewardButton:Enable()
				end
			end
		else
			if g_WinNum == 0 and g_LoseNum == 0 then
				BS_Guessing_RewardText:SetText("#{JHSJC_190120_23}")--没猜
				BS_Guessing_RewardButton:Disable()
			else
				if g_WinNum == 1 then
					local text = ScriptGlobal_Format("#{JHSJC_190120_22}", g_FinalSupportName, "#{JHSJC_190120_85}")--猜对了冠军
					BS_Guessing_RewardText:SetText(text)--可以领取
				else
					local text = ScriptGlobal_Format("#{JHSJC_190120_22}", g_FinalSupportName, "#{JHSJC_190120_86}")--猜错了冠军
					BS_Guessing_RewardText:SetText(text)--可以领取
				end
				BS_Guessing_RewardButton:Enable()
			end
		end
	end

	local already = Pneuma:GetMF(g_MF[nIndex])		
	if already == 1 then
		BS_Guessing_RewardButton:SetText("#{JHSJC_190120_84}")
		BS_Guessing_RewardButton:Disable()
	end
end

function BS_Guessing_ShowVSList(nIndex)
	g_emptyNum = 0
	g_TeamIDList = {}
	g_TeamNameList = {}
	g_TeamIDListL = {}
	g_TeamIDListR = {}
	if nIndex == 1 then
		for i = 1, 32 do
			g_TeamIDList[i], g_TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
			if g_TeamNameList[i] == nil then
				g_TeamNameList[i] = g_lunkong
			end
		end
		for j = 1, 16 do
			local isGuess = g_Guess[j]
			BS_Guessing_AddCatalog(g_TeamNameList[j], g_TeamNameList[33 - j], isGuess, g_TeamIDList[j], g_TeamIDList[33 - j])
			g_TeamIDListL[j] = g_TeamIDList[j]
			g_TeamIDListR[j] = g_TeamIDList[33 - j]
		end
	end
	if nIndex == 2 then
		for i = 1, 16 do
			g_TeamIDList[i], g_TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
			if g_TeamNameList[i] == nil then
				g_TeamNameList[i] = g_lunkong
			end
		end
		for j = 1, 8 do
			local isGuess = g_Guess[16+j]
			BS_Guessing_AddCatalog(g_TeamNameList[j], g_TeamNameList[17 - j], isGuess, g_TeamIDList[j], g_TeamIDList[17 - j])
			g_TeamIDListL[j] = g_TeamIDList[j]
			g_TeamIDListR[j] = g_TeamIDList[17 - j]
		end
	end
	if nIndex == 3 then
		for i = 1, 8 do
			g_TeamIDList[i], g_TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
			if g_TeamNameList[i] == nil then
				g_TeamNameList[i] = g_lunkong
			end
		end
		for j = 1, 4 do
			local isGuess = g_Guess[16 + 8 + j]
			BS_Guessing_AddCatalog(g_TeamNameList[j], g_TeamNameList[9 - j], isGuess, g_TeamIDList[j], g_TeamIDList[9 - j])
			g_TeamIDListL[j] = g_TeamIDList[j]
			g_TeamIDListR[j] = g_TeamIDList[9 - j]
		end
	end
	if nIndex == 4 then
		for i = 1, 4 do
			g_TeamIDList[i], g_TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
			if g_TeamNameList[i] == nil then
				g_TeamNameList[i] = g_lunkong
			end
		end
		for j = 1, 2 do
			local isGuess = g_Guess[16 + 8 + 4 + j]
			BS_Guessing_AddCatalog(g_TeamNameList[j], g_TeamNameList[5 - j], isGuess, g_TeamIDList[j],g_TeamIDList[5 - j])
			g_TeamIDListL[j] = g_TeamIDList[j]
			g_TeamIDListR[j] = g_TeamIDList[5 - j]
		end
	end
	if nIndex == 5 then
		for i = 1, 2 do
			g_TeamIDList[i], g_TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
			if g_TeamNameList[i] == nil then
				g_TeamNameList[i] = g_lunkong
			end
		end
		local isGuess = g_Guess[31]
		BS_Guessing_AddCatalog(g_TeamNameList[1], g_TeamNameList[2], isGuess, g_TeamIDList[1],g_TeamIDList[2])
		g_TeamIDListL[1] = g_TeamIDList[1]
		g_TeamIDListR[1] = g_TeamIDList[2]
	end
	BS_Guessing_List:Flash()
end

function BS_Guessing_ShowFenYe()
	local curDay = tonumber(DataPool:GetServerDayTime())
	g_Controls.Table[1]:Enable()
	g_Controls.Table[2]:Enable()
	g_Controls.Table[3]:Enable()
	g_Controls.Table[4]:Enable()
	g_Controls.Table[5]:Enable()

	if curDay <= g_FinalDay[4] then
		g_Controls.Table[5]:Disable()
	end

	if curDay <= g_FinalDay[3] then
		g_Controls.Table[4]:Disable()
	end

	if curDay <= g_FinalDay[2] then
		g_Controls.Table[3]:Disable()
	end

	if curDay <= g_FinalDay[1] then
		g_Controls.Table[2]:Disable()
	end
	for i = 1, 5 do
		if i == g_TableSel then
			g_Controls.Table[i]:SetCheck(1)
		else
			g_Controls.Table[i]:SetCheck(0)
		end
	end
	
end

function BS_Guessing_AddCatalog(name1, name2, isGuess, leftTeamId, rightTeamId) --index为条目第几个 
	if leftTeamId == nil and rightTeamId == nil then
		g_emptyNum = g_emptyNum + 1
	end
	local itemCatalog = BS_Guessing_List:AddItemElement( "BSGuessingButton", "LEFT", "BS_Guessing","" ,"")
	itemCatalog:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	itemCatalog:SetText1(name1)
	itemCatalog:SetText2(name2)
	local xiangqingL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton1__")
	local xiangqingR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton2__")
	if BS_Guessing_IsShowDetail() == 1 then
		xiangqingL:Show()
		xiangqingR:Show()
	else
		xiangqingL:Hide()
		xiangqingR:Hide()
	end
	--轮空 隐藏详情
	if leftTeamId == nil then
		xiangqingL:Hide()
	end
	if rightTeamId == nil then
		xiangqingR:Hide()
	end
	itemCatalog:SetButton1Text("#{JHSJC_190120_16}"); 
	itemCatalog:SetButton2Text("#{JHSJC_190120_16}"); 
	xiangqingL:SetToolTip("#{JHSJC_190120_17}")
	xiangqingR:SetToolTip("#{JHSJC_190120_17}")
	if isGuess == 0 then--没猜
	    --左右看好你
		local kanhaoniL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage4__")
		local kanhaoniR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage5__")
		kanhaoniL:Hide()
		kanhaoniR:Hide()
	    --左右支持
	    if BS_Guessing_IsCanSupport() == 1 then
			local zhichiL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton3__")
			local zhichiR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton4__")
			zhichiL:Show()
			zhichiR:Show()
			--轮空 隐藏支持
			if leftTeamId == nil then
				zhichiL:Hide()
			end
			if rightTeamId == nil then
				zhichiR:Hide()
			end
			itemCatalog:SetButton3Text("#{JHSJC_190120_18}"); 
			itemCatalog:SetButton4Text("#{JHSJC_190120_18}"); 
			zhichiL:SetToolTip("#{JHSJC_190120_19}")
			zhichiR:SetToolTip("#{JHSJC_190120_19}")
		else
			local zhichiL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton3__")
			local zhichiR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton4__")
			zhichiL:Hide()
			zhichiR:Hide()
		end
	end
	if isGuess == 1 then --猜的左边赢
	    --左右看好你
		local kanhaoniL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage4__")
		local kanhaoniR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage5__")
		kanhaoniL:Show()
		kanhaoniR:Hide()
	    --左右支持
		local zhichiL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton3__")
		local zhichiR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton4__")
		zhichiL:Hide()
		zhichiR:Hide()
		if g_TableSel == 5 then --记录一下最后支持的队伍名字
			g_FinalSupportName = name1
		end
	end
	if isGuess == 2 then --猜的右边赢
	    --左右看好你
		local kanhaoniL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage4__")
		local kanhaoniR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage5__")
		kanhaoniL:Hide()
		kanhaoniR:Show()
	    --左右支持
		local zhichiL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton3__")
		local zhichiR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton4__")
		zhichiL:Hide()
		zhichiR:Hide()
		if g_TableSel == 5 then --记录一下最后支持的队伍名字
			g_FinalSupportName = name2
		end
	end

	local isShowWin = BS_Guessing_IsShowWin(leftTeamId, rightTeamId)
	     --左边胜负
	local shengfuL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage2__")
	    --右边胜负
	local shengfuR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage3__")
	if isShowWin == 0 then--没到显示胜负的时候
		shengfuL:Hide()
		shengfuR:Hide()
	elseif isShowWin == 1 then--左边赢了
		shengfuL:SetProperty("Image", "set:BW_Match5 image:Sheng");
		shengfuR:SetProperty("Image", "set:BW_Match5 image:Bai");
		shengfuL:Show()
		shengfuR:Show()
		if isGuess == 1 then
			g_WinNum = g_WinNum + 1
		elseif isGuess == 2 then
			g_LoseNum = g_LoseNum + 1
		end
	elseif isShowWin == 2 then--右边赢了
		shengfuL:SetProperty("Image", "set:BW_Match5 image:Bai");
		shengfuR:SetProperty("Image", "set:BW_Match5 image:Sheng");
		shengfuL:Show()
		shengfuR:Show()
		if isGuess == 2 then
			g_WinNum = g_WinNum + 1
		elseif isGuess == 1 then
			g_LoseNum = g_LoseNum + 1
		end
	end
	table.insert(g_VSList,itemCatalog)

end

--*********************************
-- 标签页
--*********************************
function BS_Guessing_ButtonFenYe_Click(nIndex)
	--
	if (g_TableSel == nIndex) then
		return
	end
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if g_reqdate < curTime2Day then--请求服务器刷新数据
		g_TableSel = nIndex
		g_reqdate = curTime2Day
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("FlashNewData")
			Set_XSCRIPT_ScriptID(893060)
			Set_XSCRIPT_Parameter(0, g_ServerObjId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();
	else
		g_TableSel = nIndex
		--g_TeamIDList = {}
		--g_TeamNameList = {}
		BS_Guessing_CleanupUIControls()
		BS_Guessing_InitDate()
		BS_Guessing_OnUpdate(g_TableSel)
	end
	AskServerTimeAgain()
end

function BS_Guessing_OnButton1Click()
	--左边详情
	AskServerTimeAgain()
	if BS_Guessing_IsShowDetail() ~= 1 then
		SetNotifyTip("#{JHSJC_190120_93}")
	end
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	local teamId = g_TeamIDListL[nIndex]
	if teamId ~= nil and teamId > 0 then
		PushEvent("UI_COMMAND", 89306004, g_NpcObjId)
		BWDH2018:RequsetWTeamInfoForGuess(tonumber(teamId))
	end
end

function BS_Guessing_OnButton2Click()
	--右边详情
	AskServerTimeAgain()
	if BS_Guessing_IsShowDetail() ~= 1 then
		SetNotifyTip("#{JHSJC_190120_93}")
	end
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	local teamId = g_TeamIDListR[nIndex]
	if teamId ~= nil and teamId > 0 then
		PushEvent("UI_COMMAND", 89306004, g_NpcObjId)
		BWDH2018:RequsetWTeamInfoForGuess(tonumber(teamId))
	end
end

function BS_Guessing_OnButton3Click()
	--左支持
	--是否在时间内
	if BS_Guessing_IsCanSupport() ~= 1 then
		SetNotifyTip("#{JHSJC_190120_26}")
		return
	end
	--等级是否满足
	local nLevel = Player:GetLevel();
	if nLevel < 50 then
		SetNotifyTip("#{JHSJC_190120_27}")
		return
	end

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1 --第几条对应第几场
	--是否已经猜了
	if BS_Guessing_AlreadySupported(nIndex) == 1 then
		SetNotifyTip("#{JHSJC_190120_28}")
		return
	end

	if g_TeamIDListL[nIndex] == nil or g_TeamIDListL[nIndex] <= 0 then
		return
	end

	local name = BWDH2018:GetWTeamNameForGuess(g_TeamIDListL[nIndex])
	--二次确认
	PushEvent("UI_COMMAND", 89306002, tostring(name), g_TableSel, nIndex, 1, g_TeamIDListL[nIndex])

end

function BS_Guessing_SupportLeft(nIndex)
	if g_VSList[nIndex] == nil then
		return
	end
	BS_Guessing_InitDate()
	local itemCatalog = g_VSList[nIndex]
	local kanhaoniL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage4__")
	local kanhaoniR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage5__")
	kanhaoniL:Show()
	kanhaoniR:Hide()
	--左右支持
	local zhichiL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton3__")
	local zhichiR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton4__")
	zhichiL:Hide()
	zhichiR:Hide()
	local name = BWDH2018:GetWTeamNameForGuess(g_TeamIDListL[nIndex])
	local text = ScriptGlobal_Format("#{JHSJC_190120_32}", name)
	SetNotifyTip(text)
end

function BS_Guessing_SupportRight(nIndex)
	if g_VSList[nIndex] == nil then
		return
	end
	BS_Guessing_InitDate()
	local itemCatalog = g_VSList[nIndex]
	local kanhaoniL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage4__")
	local kanhaoniR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarImage5__")
	kanhaoniL:Hide()
	kanhaoniR:Show()
	--左右支持
	local zhichiL = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton3__")
	local zhichiR = itemCatalog:GetChildItem("BS_Guessing","__auto_SuperBarButton4__")
	zhichiL:Hide()
	zhichiR:Hide()
	local name = BWDH2018:GetWTeamNameForGuess(g_TeamIDListR[nIndex])
	local text = ScriptGlobal_Format("#{JHSJC_190120_32}", name)
	SetNotifyTip(text)
end

function BS_Guessing_OnButton4Click()
	--右支持
	if BS_Guessing_IsCanSupport() ~= 1 then
		SetNotifyTip("#{JHSJC_190120_26}")
		return
	end
	--等级是否满足
	local nLevel = Player:GetLevel();
	if nLevel < 50 then
		SetNotifyTip("#{JHSJC_190120_27}")
		return
	end

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1 --第几条对应第几场
	--是否已经猜了
	if BS_Guessing_AlreadySupported(nIndex) == 1 then
		SetNotifyTip("#{JHSJC_190120_28}")
		return
	end

	if g_TeamIDListR[nIndex] == nil or g_TeamIDListR[nIndex] <= 0 then
		return
	end

	local name = BWDH2018:GetWTeamNameForGuess(g_TeamIDListR[nIndex])
	--二次确认
	PushEvent("UI_COMMAND", 89306002, tostring(name), g_TableSel, nIndex, 2, g_TeamIDListR[nIndex])
	
end

--看看当前处于那个阶段 1 2 3 4 5
function BS_Guessing_FinalIndex(curDay)
	if curDay <= g_FinalDay[1] then
		return 1
	end
	if curDay > g_FinalDay[1] and curDay <= g_FinalDay[2] then
		return 2
	end
	if curDay > g_FinalDay[2] and curDay <= g_FinalDay[3] then
		return 3
	end
	if curDay > g_FinalDay[3] and curDay <= g_FinalDay[4] then
		return 4
	end
	if curDay > g_FinalDay[4] and curDay <= g_FinalDay[5] then
		return 5
	end
	if curDay > g_FinalDay[5] then
		return 5
	end
	return 0
end

function BS_Guessing_IsCanSupport()

	local curHour = g_CurrentHour
	--SetNotifyTip("#{curHour}="..curHour)
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	--SetNotifyTip("#{curTime2Day}="..curTime2Day)
	--比赛当天17：00之前可以点
	--SetNotifyTip("#{g_FinalDay[g_TableSel]}="..g_FinalDay[g_TableSel])
	if curTime2Day == g_FinalDay[g_TableSel] and curHour < g_LimitHour then
		return 1
	end
	--如果是第一个页签 必须比第一天早才能点
	if g_TableSel == 1 and curTime2Day < g_FinalDay[g_TableSel] then
		return 1
	end
	--非比赛当天并且不是第一个页签 必须在区间内
	if g_TableSel > 1 and curTime2Day < g_FinalDay[g_TableSel] and curTime2Day > g_FinalDay[g_TableSel - 1] then
		return 1
	end

	return 0
end

function BS_Guessing_AlreadySupported(nIndex)
	local index = 0
	if g_TableSel == 1 then
		index = nIndex
	elseif g_TableSel == 2 then
		index = 16 + nIndex
	elseif g_TableSel == 3 then
		index = 16 + 8 + nIndex
	elseif g_TableSel == 4 then
		index = 16 + 8 + 4 + nIndex
	elseif g_TableSel == 5 then
		index = 16 + 8 + 4 + 2 + nIndex
	end
	if g_Guess[index] ~= nil and g_Guess[index] == 0 then
		return 0
	end
	return 1
end

function BS_Guessing_IsShowWin(leftTeamId, rightTeamId)
	--返回0表示不显示胜负图标，返回1表示左边赢了,返回2表示右边赢了

	if leftTeamId ~= nil and leftTeamId > 0 then
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
	--比赛当天不显示
		if curTime2Day == g_FinalDay[g_TableSel] then
			return 0
		end
		if curTime2Day > g_FinalDay[g_TableSel] then
			local isWin = BWDH2018:IsTeamWin(leftTeamId, g_TableSel)
			if isWin == 1 then
				return 1
			elseif isWin == 0 then
				return 2
			end
		end
		return 0
	end
	--异常了 左边TeamID 为空或者 0
	if rightTeamId ~= nil and rightTeamId > 0 then
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
	--比赛当天不显示
		if curTime2Day == g_FinalDay[g_TableSel] then
			return 0
		end
		if curTime2Day > g_FinalDay[g_TableSel] then
			return 2
		end
		return 0
	end
	return 0
end

function BS_Guessing_CloseClicked()
	PushEvent("UI_COMMAND", 89306004, g_NpcObjId)
	BS_Guessing_CleanupUIControls()
	this:Hide()
	g_CurrentHour = 0
	g_TableSel = 1
end

function BS_Guessing_ButtonLClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1 --第几条对应第几场
	if nil ~= g_VSList[nIndex] then
		local itemCatalog = g_VSList[nIndex]
		itemCatalog:SetBarButtonSelected(false)
	end
end

function BS_Guessing_OnRewardButtonClicked()--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetGuessPoint")
		Set_XSCRIPT_ScriptID(893060)
		Set_XSCRIPT_Parameter(0, g_TableSel)
		Set_XSCRIPT_Parameter(1, g_emptyNum)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT();
end

function BS_Guessing_IsShowDetail()
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	--比赛当天不显示
	if curTime2Day > g_FinalDay[5] then
		return 0
	end
	return 1
end

function BS_Guessing_ShowRedPoint()
	local curDay = tonumber(DataPool:GetServerDayTime())
	for i = 1, 5 do
		if curDay <= g_FinalDay[i] then
			g_Controls.RedPoit[i]:Hide()
		else
			if Pneuma:GetMF(g_MF[i]) == 1 then--已经领取过
				g_Controls.RedPoit[i]:Hide()
			else
				--没领取过判断他是否可以领取
				g_Controls.RedPoit[i]:Hide()
				BS_Guessing_ShowRedPointByIndex(i)
			end	 
		end
	end
end

function BS_Guessing_ShowRedPointByIndex(nIndex)
	local TeamIDList = {}
	local TeamNameList = {}
	if nIndex == 1 then
		for i = 1, 32 do
			TeamIDList[i], TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
		end
		for j = 1, 16 do
			local isGuess = g_Guess[j]
			if isGuess > 0 then--本页签猜过肯定可以领桨
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
			if TeamIDList[j] == nil and TeamIDList[33 - j] == nil then --轮空送的也让领取所以红
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
		end
	end

	if nIndex == 2 then
		for i = 1, 16 do
			TeamIDList[i], TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
		end
		for j = 1, 8 do
			local isGuess = g_Guess[16+j]
			if isGuess > 0 then--本页签猜过
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
			if TeamIDList[j] == nil and TeamIDList[17 - j] == nil then --轮空送的也让领取所以红
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
		end
	end
	if nIndex == 3 then
		for i = 1, 8 do
			TeamIDList[i], TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
		end
		for j = 1, 4 do
			local isGuess = g_Guess[16 + 8 + j]
			if isGuess > 0 then--本页签猜过
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
			if TeamIDList[j] == nil and TeamIDList[9 - j] == nil then --轮空送的也让领取所以红
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
		end
	end
	if nIndex == 4 then
		for i = 1, 4 do
			TeamIDList[i], TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
		end
		for j = 1, 2 do
			local isGuess = g_Guess[16 + 8 + 4 + j]
			if isGuess > 0 then--本页签猜过
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
			if TeamIDList[j] == nil and TeamIDList[5 - j] == nil then --轮空送的也让领取所以红
				g_Controls.RedPoit[nIndex]:Show()
				return
			end
		end
	end
	if nIndex == 5 then
		for i = 1, 2 do
			TeamIDList[i], TeamNameList[i] = BWDH2018:GetWTeamIDAndNameForGuess(i, nIndex)
		end
		local isGuess = g_Guess[31]
		if isGuess > 0 then--本页签猜过
			g_Controls.RedPoit[nIndex]:Show()
			return
		end
		if TeamIDList[1] == nil and TeamIDList[2] == nil then --轮空送的也让领取所以红
			g_Controls.RedPoit[nIndex]:Show()
			return
		end
	end
end