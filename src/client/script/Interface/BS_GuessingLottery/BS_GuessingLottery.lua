-- [神机妙算阁] 

---------------------------------------------------------------------------
local g_Controls = {};									-- 控件
local g_Position = "{{0.500000,-300.000000},{0.500000,-260.000000}}";
local g_leftTimes = 0;
local g_NpcObjId = 0
local g_rewardList = {
	[1]  = {showId = 39920397, num = 1},
	[2]  = {showId = 39920463, num = 1},
	[3]  = {showId = 39920163, num = 100},
	[4]  = {showId = 39920396, num = 1},
	[5]  = {showId = 39920315, num = 1},
	[6]  = {showId = 39921545, num = 5},
	[7]  = {showId = 39920162, num = 50},
	[8]  = {showId = 39923278, num = 1},
}
local g_MF = {3734,3735,3736,3737,3738,3739,3740,3741}
local g_position = 1
local g_round = 1
local g_lotteryIndex = 0
local g_rewardName
local g_clickCD = 1000
local g_lastClickTm = 0
local g_lottery = {
	[1]  = {leftNum = 8, round = 2, maxSpeed = 200, decay = 5},
	[2]  = {leftNum = 7, round = 2, maxSpeed = 200, decay = 5},
	[3]  = {leftNum = 6, round = 2, maxSpeed = 200, decay = 5},
	[4]  = {leftNum = 5, round = 3, maxSpeed = 200, decay = 5},
	[5]  = {leftNum = 4, round = 3, maxSpeed = 200, decay = 5},
}
local g_step = 0
local g_RewardIndex = 0
local g_MD_XBW_GUESSLOTTERY_TIMES = 2565
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function BS_GuessingLottery_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED", false );		-- 游戏分辨率发生了变化
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED", false );		-- 离开场景
	this : RegisterEvent( "ADJEST_UI_POS" , false);
end


--*********************************
-- OnLoad
--*********************************
function BS_GuessingLottery_OnLoad()
	g_Controls = {
		-- 框架
		Framework = BS_GuessingLottery_Frame;
		-- 标签页
		Item = {
			[1] = BS_GuessingLottery_Item1,
			[2] = BS_GuessingLottery_Item2,
			[3] = BS_GuessingLottery_Item3,
			[4] = BS_GuessingLottery_Item4,
			[5] = BS_GuessingLottery_Item5,
			[6] = BS_GuessingLottery_Item6,
			[7] = BS_GuessingLottery_Item7,
			[8] = BS_GuessingLottery_Item8,
		};
		Animate = {
			[1] = BS_GuessingLottery_Animate_Item1,
			[2] = BS_GuessingLottery_Animate_Item2,
			[3] = BS_GuessingLottery_Animate_Item3,
			[4] = BS_GuessingLottery_Animate_Item4,
			[5] = BS_GuessingLottery_Animate_Item5,
			[6] = BS_GuessingLottery_Animate_Item6,
			[7] = BS_GuessingLottery_Animate_Item7,
			[8] = BS_GuessingLottery_Animate_Item8,
		};
		Mask = {
			[1] = BS_GuessingLottery_Mask_Item1,
			[2] = BS_GuessingLottery_Mask_Item2,
			[3] = BS_GuessingLottery_Mask_Item3,
			[4] = BS_GuessingLottery_Mask_Item4,
			[5] = BS_GuessingLottery_Mask_Item5,
			[6] = BS_GuessingLottery_Mask_Item6,
			[7] = BS_GuessingLottery_Mask_Item7,
			[8] = BS_GuessingLottery_Mask_Item8,
		};
		TimesLeft = BS_GuessingLottery_TimesLeft_Text;
		Button = BS_GuessingLottery_DrawButton;
	};
end


--*********************************
-- OnEvent
--*********************************
function BS_GuessingLottery_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 89306003) then
		-- 关心NPC
		if tonumber( Get_XParam_INT(0)) == 1 then
			g_NpcObjId = Target:GetServerId2ClientId(tonumber(Get_XParam_INT(1)));
			this:CareObject(g_NpcObjId, 1, "BS_GuessingLottery");
			g_leftTimes = DataPool:GetPlayerMission_DataRound(g_MD_XBW_GUESSLOTTERY_TIMES)
			g_leftTimes = math.mod(g_leftTimes, 10)
			BS_GuessingLottery_OnUpdate()
			this:Show();
		elseif tonumber( Get_XParam_INT(0)) == 2 then
			g_RewardIndex = 0;
			g_position = 1;
			g_round = 1;
			g_RewardIndex = tonumber( Get_XParam_INT(1)) 
			g_leftTimes = DataPool:GetPlayerMission_DataRound(g_MD_XBW_GUESSLOTTERY_TIMES)
			g_leftTimes = math.mod(g_leftTimes, 10)
			g_rewardName = tostring(Get_XParam_STR(0))
			BS_GuessingLottery_ShowTimes()
			BS_GuessingLottery_Start()
		end
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif	(event == "ADJEST_UI_POS" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end


--*********************************
-- 清空控件
--*********************************
function BS_GuessingLottery_CleanupUIControls()
	SetDefaultMouse()
	g_position = 1
	g_round = 1
end


--*********************************
-- 显示
--*********************************
function BS_GuessingLottery_OnUpdate()
	BS_GuessingLottery_ShowTimes()
	for i = 1, 8 do
		local nItemId = g_rewardList[i].showId
		local theAction = DataPool:CreateActionItemForShow(nItemId,  g_rewardList[i].num)
		if theAction:GetID() ~= 0 then
			g_Controls.Item[i]:SetActionItem(theAction:GetID())
		else
			g_Controls.Item[i]:Hide()
		end
		if Pneuma:GetMF(g_MF[i]) == 1 then 
			g_Controls.Mask[i]:Show()
		else
			g_Controls.Mask[i]:Hide()
		end
		g_Controls.Animate[i]:PlayWarning(0)
	end

end

function BS_GuessingLottery_OnCloseClicked()
	this:Hide()
end

function BS_GuessingLottery_OnStartClicked()
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_lastClickTm < g_clickCD) then
		PushDebugMessage("#{JHSJC_190120_92}"); --当前操作过快，请稍后点击
		return
	end
	g_lastClickTm = curTime;
	if g_RewardIndex > 0 then
		KillTimer("BS_GuessingLottery_Tick()")
		KillTimer("BS_GuessingLottery_End()")
		BS_GuessingLottery_End()
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LotteryGO"); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID(893060);				-- 脚本编号 
		Set_XSCRIPT_ParamCount(0);				-- 参数个数
	Send_XSCRIPT()
end

function BS_GuessingLottery_Start()

	local leftNum = BS_GuessingLottery_GetLeftNum()
	for i = 1, 8 do
		if leftNum == g_lottery[i].leftNum then
			g_lotteryIndex = i
		end
		g_Controls.Animate[i]:PlayWarning(0)
	end
	g_position = BS_GuessingLottery_CalcStartPosition()

	for i = 1, 8 do
		if Pneuma:GetMF(g_MF[i]) == 1 and i ~= g_RewardIndex then 
			g_Controls.Mask[i]:Show()
		else
			g_Controls.Mask[i]:Hide()
		end
		g_Controls.Animate[i]:PlayWarning(0)
	end

	SetTimer("BS_GuessingLottery","BS_GuessingLottery_Tick()", g_lottery[g_lotteryIndex].maxSpeed)
	g_Controls.Animate[g_position]:PlayWarning(1)
end

function BS_GuessingLottery_Tick()
	g_Controls.Animate[g_position]:PlayWarning(0)
	BS_GuessingLottery_CalcNextPosition()
	KillTimer("BS_GuessingLottery_Tick()")
	if g_round == (g_lottery[g_lotteryIndex].round + 1) then
		if g_position == g_RewardIndex then
			BS_GuessingLottery_End()
			return
		end
	end
	g_Controls.Animate[g_position]:PlayWarning(1)
	SetTimer("BS_GuessingLottery","BS_GuessingLottery_Tick()", g_lottery[g_lotteryIndex].maxSpeed - g_lottery[g_lotteryIndex].decay * g_step)

end

function BS_GuessingLottery_End()

	g_Controls.Animate[g_RewardIndex]:PlayWarning(1)

	if g_leftTimes <= 0 then 
		BS_GuessingLottery_DrawButton:Disable()
	end

	local text = ScriptGlobal_Format("#{JHSJC_190120_49}", g_rewardList[g_RewardIndex].num, g_rewardName)
	SetNotifyTip(text)
	g_RewardIndex = 0;
	g_position = 1;
	g_round = 1;
	g_step = 0;
	g_lotteryIndex = 0;
end

function BS_GuessingLottery_OnHiden()
	this:Hide()
end

function BS_GuessingLottery_ShowTimes()
	local text = ScriptGlobal_Format("#{JHSJC_190120_42}", g_leftTimes)
	BS_GuessingLottery_TimesLeft_Text:SetText(text)
	BS_GuessingLottery_DrawButton:Show()
	if g_leftTimes <= 0 then
		BS_GuessingLottery_DrawButton:Disable()
		BS_GuessingLottery_TimesLeft_Text:SetText("#{JHSJC_190120_83}")
	else
		BS_GuessingLottery_DrawButton:Enable()
	end
end

function BS_GuessingLottery_GetLeftNum()
	local total = 0
	for i = 1, 8 do
		if Pneuma:GetMF(g_MF[i]) == 1 then 
			total = total + 1
		end
	end
	total = 8 - total + 1
	return total 
end

function BS_GuessingLottery_CalcStartPosition()
	for i = 1, 8 do
		if i == g_RewardIndex then
			return i
		end
		if Pneuma:GetMF(g_MF[i]) ~= 1 then 
			return i
		end
	end
	return 1
end

function BS_GuessingLottery_CalcNextPosition()
	--第一圈
	for i = 1, 8 do
		if Pneuma:GetMF(g_MF[i]) ~= 1 and i > g_position then 
			g_position = i
			g_step = g_step + 1
			return
		end
		if i == g_RewardIndex and i > g_position then
			g_position = i
			g_step = g_step + 1
			return
		end
	end
	--第二圈找第一个
	for i = 1, 8 do
		if i == g_RewardIndex then
			g_position = i
			g_round = g_round + 1
			g_step = g_step + 1
			return 
		end
		if Pneuma:GetMF(g_MF[i]) ~= 1 then 
			g_position = i
			g_round = g_round + 1
			g_step = g_step + 1
			return 
		end
	end
end