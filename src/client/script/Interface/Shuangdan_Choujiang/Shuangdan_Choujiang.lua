--双旦抽奖功能设计
local g_Shuangdan_Choujiang_IsRewardUpTime         = 0 --是否奖励升级时间段
local g_Shuangdan_Choujiang_IsNeedBroad            = 0 --是否需要广播  修改需求 不用客户端触发播公告了
local g_Shuangdan_Choujiang_IsChouJiangIng         = 0 --是否在抽奖动画中
local g_Shuangdan_Choujiang_IsKaJi                 = 0 --是否卡级服
local g_Shuangdan_Choujiang_RewardItemId           = -1
local g_Shuangdan_Choujiang_RewardNum              = 0
local g_Shuangdan_Choujiang_rewardIndex            = 1 --抽中的奖励序号
local g_Shuangdan_Choujiang_AnimateStep            = 1
local g_Shuangdan_Choujiang_AnimateCircleCount     = 1
local g_Shuangdan_Choujiang_IsAnimateCircleEnd     = 0
local g_Shuangdan_Choujiang_IsGetLJJLStates        = { 0, 0, 0, 0, 0 }
---------------------------------------------------------------
local g_Shuangdan_Choujiang_MD_LJCS                = 2925
local g_Shuangdan_Choujiang_MD_CHQ                 = 2926
local g_Shuangdan_Choujiang_MD_JYCHQ               = 2927
local g_Shuangdan_Choujiang_COST                   = 3
local g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index    = {
	[1] = { mf = 4555, needValue = 4, tips1 = "#{SDCJ_231026_11}", tips2 = "#{SDCJ_231026_38}", },
	[2] = { mf = 4556, needValue = 8, tips1 = "#{SDCJ_231026_12}", tips2 = "#{SDCJ_231026_39}", },
	[3] = { mf = 4557, needValue = 14, tips1 = "#{SDCJ_231026_13}", tips2 = "#{SDCJ_231026_40}", },
	[4] = { mf = 4558, needValue = 20, tips1 = "#{SDCJ_231026_14}", tips2 = "#{SDCJ_231026_41}", },
	[5] = { mf = 4559, needValue = 30, tips1 = "#{SDCJ_231026_15}", tips2 = "#{SDCJ_231026_42}", },
}
local g_Shuangdan_Choujiang_Op_Type                = {
	OpenUi = 1, --打开界面
	BeginChouJiang = 2, --开始抽奖动画
	CloseUi = 3, --关闭界面
	UpdateUI = 4, --刷新奖盘
	UpdateUI2 = 5, --刷新文本以及其他控件
}
local g_Shuangdan_Choujiang_UnifiedPosition
local g_Shuangdan_Choujiang_NormalRewardItem       =
{
	[1] = { itemId = 20310168, num = 1, highLight = 0 }, --highLight 重要物品的话背景图不同
	[2] = { itemId = 38000807, num = 1, highLight = 0 },
	[3] = { itemId = 38001595, num = 1, highLight = 0 },
	[4] = { itemId = 38000571, num = 1, highLight = 0 },
	[5] = { itemId = 20502003, num = 1, highLight = 0 },
	[6] = { itemId = 20501003, num = 1, highLight = 0 },
	[7] = { itemId = 10126975, num = 1, highLight = 0 },
	[8] = { itemId = 10146779, num = 1, highLight = 0 },

}
local g_Shuangdan_Choujiang_LevelUpRewardItem      =
{
	[1] = { itemId = 38000571, num = 2, highLight = 0 },
	[2] = { itemId = 38000807, num = 2, highLight = 1 },
	[3] = { itemId = 20502015, num = 1, highLight = 0 },
	[4] = { itemId = 20501009, num = 1, highLight = 0 },
	[5] = { itemId = 10192023, num = 1, highLight = 0 },
	[6] = { itemId = 39910107, num = 1, highLight = 0 },
	[7] = { itemId = 10126975, num = 1, highLight = 0 },
	[8] = { itemId = 10146780, num = 1, highLight = 0 },
}
local g_Shuangdan_Choujiang_NormalRewardItem_Kaji  =
{
	[1] = { itemId = 20310168, num = 1, highLight = 0 }, --highLight 重要物品的话背景图不同
	[2] = { itemId = 38000807, num = 1, highLight = 0 },
	[3] = { itemId = 38001595, num = 1, highLight = 0 },
	[4] = { itemId = 38000571, num = 1, highLight = 0 },
	[5] = { itemId = 20502003, num = 1, highLight = 0 },
	[6] = { itemId = 20501003, num = 1, highLight = 0 },
	[7] = { itemId = 10126975, num = 1, highLight = 0 },
	[8] = { itemId = 10146779, num = 1, highLight = 0 },

}
local g_Shuangdan_Choujiang_LevelUpRewardItem_Kaji =
{
	[1] = { itemId = 38000571, num = 2, highLight = 0 },
	[2] = { itemId = 38000807, num = 2, highLight = 0 },
	[3] = { itemId = 20502003, num = 1, highLight = 0 },
	[4] = { itemId = 20501003, num = 1, highLight = 0 },
	[5] = { itemId = 10192023, num = 1, highLight = 0 },
	[6] = { itemId = 39910107, num = 1, highLight = 0 },
	[7] = { itemId = 10126975, num = 1, highLight = 0 },
	[8] = { itemId = 10146780, num = 1, highLight = 0 },
}
local g_Shuangdan_Choujiang_AnimateCirCleMax       = 3 --抽奖至少转几圈
local g_Shuangdan_Choujiang_RewardItemUITalbe      = {} --奖盘 物品UI
local g_Shuangdan_Choujiang_AnimateSpeed           = { 70, 50, 65, 50, 68, 50, 55, 60 } --转一格物品的时间间隔
local g_Shuangdan_Choujiang_LJJLActionBtnTbl       = {} --累计奖励actionButton
local g_Shuangdan_Choujiang_MaxLJJL                = 5 --累计奖励个数
local g_Shuangdan_Choujiang_MaxCJJL                = 8 --抽奖奖励个数
local g_Shuangdan_Choujiang_MaxCJCS                = 55 --最多抽55次
---------------------------------------------------------------

function Shuangdan_Choujiang_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) --进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS", false)
end

function Shuangdan_Choujiang_OnLoad()
	g_Shuangdan_Choujiang_UnifiedPosition = Shuangdan_Choujiang_FrameNULL:GetProperty("UnifiedPosition")
	g_Shuangdan_Choujiang_RewardItemUITalbe =
	{
		[1] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon1,
			ItemAnimate = Shuangdan_ChoujiangAward1_Light,
			--BK1 = Shuangdan_Choujiang_Reward1_BK1,
			--BK2 = Shuangdan_Choujiang_Reward1_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward1_ItemBack,
		},
		[2] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon2,
			ItemAnimate = Shuangdan_ChoujiangAward2_Light,
			--BK1 = Shuangdan_Choujiang_Reward2_BK1,
			--BK2 = Shuangdan_Choujiang_Reward2_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward2_ItemBack,
		},
		[3] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon3,
			ItemAnimate = Shuangdan_ChoujiangAward3_Light,
			--BK1 = Shuangdan_Choujiang_Reward3_BK1,
			--BK2 = Shuangdan_Choujiang_Reward3_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward3_ItemBack,
		},
		[4] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon4,
			ItemAnimate = Shuangdan_ChoujiangAward4_Light,
			--BK1 = Shuangdan_Choujiang_Reward4_BK1,
			--BK2 = Shuangdan_Choujiang_Reward4_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward4_ItemBack,
		},
		[5] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon5,
			ItemAnimate = Shuangdan_ChoujiangAward5_Light,
			--BK1 = Shuangdan_Choujiang_Reward5_BK1,
			--BK2 = Shuangdan_Choujiang_Reward5_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward5_ItemBack,
		},
		[6] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon6,
			ItemAnimate = Shuangdan_ChoujiangAward6_Light,
			--BK1 = Shuangdan_Choujiang_Reward6_BK1,
			--BK2 = Shuangdan_Choujiang_Reward6_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward6_ItemBack,
		},
		[7] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon7,
			ItemAnimate = Shuangdan_ChoujiangAward7_Light,
			--BK1 = Shuangdan_Choujiang_Reward7_BK1,
			--BK2 = Shuangdan_Choujiang_Reward7_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward7_ItemBack,
		},
		[8] =
		{
			ItemAction = Shuangdan_ChoujiangAward_Icon8,
			ItemAnimate = Shuangdan_ChoujiangAward8_Light,
			--BK1 = Shuangdan_Choujiang_Reward7_BK1,
			--BK2 = Shuangdan_Choujiang_Reward7_BK2,
			--JinKuang = Shuangdan_Choujiang_Reward7_ItemBack,
		},
	}
	g_Shuangdan_Choujiang_LJJLActionBtnTbl =
	{
		[1] =
		{
			actionBtn = Shuangdan_Choujiang_Reward1Btn,
			IsGetMask = Shuangdan_Choujiang_Reward1BtnOK, --已领取显示的控件
			RedPoint = Shuangdan_Choujiang_Reward1_tips, --累计奖励按钮红点
			NameText = Shuangdan_Choujiang_Reward1Text, --累计奖励名称
			needValue = "4",
		},
		[2] =
		{
			actionBtn = Shuangdan_Choujiang_Reward2Btn,
			IsGetMask = Shuangdan_Choujiang_Reward2BtnOK,
			RedPoint = Shuangdan_Choujiang_Reward2_tips, --累计奖励按钮红点
			NameText = Shuangdan_Choujiang_Reward2Text, --累计奖励名称
			needValue = "8",
		},
		[3] =
		{
			actionBtn = Shuangdan_Choujiang_Reward3Btn,
			IsGetMask = Shuangdan_Choujiang_Reward3BtnOK,
			RedPoint = Shuangdan_Choujiang_Reward3_tips, --累计奖励按钮红点
			NameText = Shuangdan_Choujiang_Reward3Text, --累计奖励名称
			needValue = "14",
		},
		[4] =
		{
			actionBtn = Shuangdan_Choujiang_Reward4Btn,
			IsGetMask = Shuangdan_Choujiang_Reward4BtnOK,
			RedPoint = Shuangdan_Choujiang_Reward4_tips, --累计奖励按钮红点
			NameText = Shuangdan_Choujiang_Reward4Text, --累计奖励名称
			needValue = "20",
		},
		[5] =
		{
			actionBtn = Shuangdan_Choujiang_Reward5Btn,
			IsGetMask = Shuangdan_Choujiang_Reward5BtnOK,
			RedPoint = Shuangdan_Choujiang_Reward5_tips, --累计奖励按钮红点
			NameText = Shuangdan_Choujiang_Reward5Text, --累计奖励名称
			needValue = "30",
		},
	}
end

function Shuangdan_Choujiang_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 80081601) then
		opType = Get_XParam_INT(0)
		if opType == g_Shuangdan_Choujiang_Op_Type.OpenUi then
			g_Shuangdan_Choujiang_IsRewardUpTime = Get_XParam_INT(1)
			g_Shuangdan_Choujiang_IsKaJi         = Get_XParam_INT(2)
			Shuangdan_Choujiang_Update()
			Shuangdan_Choujiang_Update2()
			this:Show()
		elseif opType == g_Shuangdan_Choujiang_Op_Type.BeginChouJiang then
			if this:IsVisible() then
				g_Shuangdan_Choujiang_IsRewardUpTime = Get_XParam_INT(1)
				g_Shuangdan_Choujiang_rewardIndex = Get_XParam_INT(2)
				g_Shuangdan_Choujiang_IsNeedBroad = Get_XParam_INT(3)
				g_Shuangdan_Choujiang_IsKaJi = Get_XParam_INT(4)
				Shuangdan_Choujiang_Update()
				Shuangdan_Choujiang_Update2()
				Shuangdan_Choujiang_Begin()
			end
		elseif opType == g_Shuangdan_Choujiang_Op_Type.CloseUi then
			Shuangdan_Choujiang_Close()
		elseif opType == g_Shuangdan_Choujiang_Op_Type.UpdateUI then
			if this:IsVisible() and g_Shuangdan_Choujiang_IsChouJiangIng == 0 then
				g_Shuangdan_Choujiang_IsRewardUpTime = Get_XParam_INT(1)
				g_Shuangdan_Choujiang_IsKaJi = Get_XParam_INT(2)
				Shuangdan_Choujiang_Update()
				Shuangdan_Choujiang_Update2()--红点也刷新
			end
		elseif opType == g_Shuangdan_Choujiang_Op_Type.UpdateUI2 then
			if this:IsVisible() then
				g_Shuangdan_Choujiang_IsKaJi = Get_XParam_INT(1)
				Shuangdan_Choujiang_Update2()
			end
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Shuangdan_Choujiang_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Shuangdan_Choujiang_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Shuangdan_Choujiang_Close()
	end
end

--关闭界面
function Shuangdan_Choujiang_Close()
	Shuangdan_Choujiang_OnHide()
	this:Hide()
end

--初始化变量
function Shuangdan_Choujiang_OnHide()
	KillTimer("Shuangdan_Choujiang_Tick()")
	g_Shuangdan_Choujiang_AnimateStep = 1
	g_Shuangdan_Choujiang_AnimateCircleCount = 1
	g_Shuangdan_Choujiang_IsAnimateCircleEnd = 0
	g_Shuangdan_Choujiang_RewardItemId = -1
	g_Shuangdan_Choujiang_RewardNum = 0
	g_Shuangdan_Choujiang_rewardIndex = 1
	g_Shuangdan_Choujiang_IsNeedBroad = 0
	g_Shuangdan_Choujiang_IsChouJiangIng = 0
	g_Shuangdan_Choujiang_IsKaJi = 0
	g_Shuangdan_Choujiang_IsGetLJJLStates = { 0, 0, 0, 0, 0 }

	g_Shuangdan_Choujiang_IsRewardUpTime = 0
end

--帮助按钮
function Shuangdan_Choujiang_Help_Clicked()
	if g_Shuangdan_Choujiang_IsKaJi == 1 then
		PushEvent("QUEST_HELP_MSG", "#{SDCJ_231026_43}")
	else
		PushEvent("QUEST_HELP_MSG", "#{SDCJ_231026_17}")
	end
end

--刷新奖盘
function Shuangdan_Choujiang_Update()
	--是否是升级奖池
	local tempRewardItemTable = g_Shuangdan_Choujiang_NormalRewardItem
	if g_Shuangdan_Choujiang_IsKaJi == 1 then
		if g_Shuangdan_Choujiang_IsRewardUpTime == 1 then
			tempRewardItemTable = g_Shuangdan_Choujiang_LevelUpRewardItem_Kaji
		else
			tempRewardItemTable = g_Shuangdan_Choujiang_NormalRewardItem_Kaji
		end
	else
		if g_Shuangdan_Choujiang_IsRewardUpTime == 1 then
			tempRewardItemTable = g_Shuangdan_Choujiang_LevelUpRewardItem
		else
			tempRewardItemTable = g_Shuangdan_Choujiang_NormalRewardItem
		end
	end
	--设置抽奖轮盘显示
	for i = 1, g_Shuangdan_Choujiang_MaxCJJL do
		local ItemID = tempRewardItemTable[i].itemId
		local theAction = DataPool:CreateBindActionItemForShow(ItemID, tempRewardItemTable[i].num)
		if theAction:GetID() ~= 0 then
			g_Shuangdan_Choujiang_RewardItemUITalbe[i].ItemAction:SetActionItem(theAction:GetID())
			g_Shuangdan_Choujiang_RewardItemUITalbe[i].ItemAction:Show()
		end
		g_Shuangdan_Choujiang_RewardItemUITalbe[i].ItemAnimate:Hide()
		--if tempRewardItemTable[i].highLight == 1 then
		--	g_RewardItemUITalbe[i].BK2:Show()
		--	g_RewardItemUITalbe[i].BK1:Hide()
		--	g_RewardItemUITalbe[i].JinKuang:Show()
		--else
		--	g_RewardItemUITalbe[i].BK2:Hide()
		--	g_RewardItemUITalbe[i].BK1:Show()
		--	g_RewardItemUITalbe[i].JinKuang:Hide()
		--end
	end
	--设置中间的标题
	if g_Shuangdan_Choujiang_IsRewardUpTime == 1 then
		Shuangdan_Choujiang_UseTipsText:SetText("#{SDCJ_231026_47}")
	else
		Shuangdan_Choujiang_UseTipsText:SetText("#{SDCJ_231026_46}")
	end
end

--刷新文本控件以及累计奖励领取情况
function Shuangdan_Choujiang_Update2()
	local chqValue = DataPool:GetPlayerMission_DataRound(g_Shuangdan_Choujiang_MD_CHQ)
	if chqValue < 0 then
		chqValue = 0
	end
	local jychqValue = DataPool:GetPlayerMission_DataRound(g_Shuangdan_Choujiang_MD_JYCHQ)
	if jychqValue < 0 then
		jychqValue = 0
	end
	local ljcsValue = DataPool:GetPlayerMission_DataRound(g_Shuangdan_Choujiang_MD_LJCS)
	if ljcsValue < g_Shuangdan_Choujiang_MaxCJCS then
		--这里也根据值是否够一抽来判断是否开启抽奖按钮红点
		if g_Shuangdan_Choujiang_IsRewardUpTime == 1 then
			if jychqValue >= g_Shuangdan_Choujiang_COST then
				Shuangdan_Choujiang_LotteryBtn_tips:Show()
			else
				Shuangdan_Choujiang_LotteryBtn_tips:Hide()
			end
		else
			if chqValue+jychqValue >= g_Shuangdan_Choujiang_COST then
				Shuangdan_Choujiang_LotteryBtn_tips:Show()
			else
				Shuangdan_Choujiang_LotteryBtn_tips:Hide()
			end
		end
	else
		--已经抽55次了
		Shuangdan_Choujiang_LotteryBtn_tips:Hide()
	end
	local chqStr = ScriptGlobal_Format("#{SDCJ_231026_06}", tostring(chqValue))
	local jychqStr = ScriptGlobal_Format("#{SDCJ_231026_07}", tostring(jychqValue))
	local ljcsStr = ScriptGlobal_Format("#{SDCJ_231026_09}", tostring(ljcsValue))
	Shuangdan_Choujiang_Reward_ResultText1:SetText(chqStr)
	Shuangdan_Choujiang_Reward_ResultText2:SetText(jychqStr)
	Shuangdan_Choujiang_RewardText:SetText(ljcsStr)
	Shuangdan_Choujiang_SetLJJLABtnUI(ljcsValue)
end

--开始抽奖动画
function Shuangdan_Choujiang_Begin()
	--是否是升级奖池
	local tempRewardItemTable = g_Shuangdan_Choujiang_NormalRewardItem
	if g_Shuangdan_Choujiang_IsKaJi == 1 then
		if g_Shuangdan_Choujiang_IsRewardUpTime == 1 then
			tempRewardItemTable = g_Shuangdan_Choujiang_LevelUpRewardItem_Kaji
		else
			tempRewardItemTable = g_Shuangdan_Choujiang_NormalRewardItem_Kaji
		end
	else
		if g_Shuangdan_Choujiang_IsRewardUpTime == 1 then
			tempRewardItemTable = g_Shuangdan_Choujiang_LevelUpRewardItem
		else
			tempRewardItemTable = g_Shuangdan_Choujiang_NormalRewardItem
		end
	end
	if g_Shuangdan_Choujiang_rewardIndex > 0 then --g_rewardIndex小于0时抽奖界面仅作为查看奖励的展示
		g_Shuangdan_Choujiang_RewardItemId = tempRewardItemTable[g_Shuangdan_Choujiang_rewardIndex].itemId
		g_Shuangdan_Choujiang_RewardNum = tempRewardItemTable[g_Shuangdan_Choujiang_rewardIndex].num
		g_Shuangdan_Choujiang_RewardItemUITalbe[g_Shuangdan_Choujiang_AnimateStep].ItemAnimate:Show()
		KillTimer("Shuangdan_Choujiang_Tick()") --启动前先kill一次，保证m_TimerMapS中只有一个此函数的timer
		SetTimer("Shuangdan_Choujiang", "Shuangdan_Choujiang_Tick()",
			g_Shuangdan_Choujiang_AnimateSpeed[g_Shuangdan_Choujiang_AnimateStep])
		g_Shuangdan_Choujiang_IsChouJiangIng = 1
	end
end

--抽奖按钮
function Shuangdan_Choujiang_LotteryBtnClick()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("BeginChouJiang"); -- 脚本函数名称
	Set_XSCRIPT_ScriptID(800816); -- 脚本编号
	Set_XSCRIPT_ParamCount(0); -- 参数个数
	Send_XSCRIPT()
end

--领取累计奖励
function Shuangdan_Choujiang_GetReward(index)
	if index < 1 or index > g_Shuangdan_Choujiang_MaxLJJL then
		return 0
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GetLJJL"); -- 脚本函数名称
	Set_XSCRIPT_ScriptID(800816); -- 脚本编号
	Set_XSCRIPT_Parameter(0, index);
	Set_XSCRIPT_ParamCount(1); -- 参数个数
	Send_XSCRIPT()
end

--转三圈之后 走到抽中的位置
function Shuangdan_Choujiang_Tick()
	-- PushDebugMessage("g_rewardIndex:"..tostring(g_rewardIndex))
	g_Shuangdan_Choujiang_RewardItemUITalbe[g_Shuangdan_Choujiang_AnimateStep].ItemAnimate:Hide()
	if g_Shuangdan_Choujiang_AnimateStep >= g_Shuangdan_Choujiang_MaxCJJL then
		g_Shuangdan_Choujiang_AnimateStep = 1
		if g_Shuangdan_Choujiang_AnimateCircleCount < g_Shuangdan_Choujiang_AnimateCirCleMax and
			g_Shuangdan_Choujiang_IsAnimateCircleEnd == 0 then
			g_Shuangdan_Choujiang_AnimateCircleCount = g_Shuangdan_Choujiang_AnimateCircleCount + 1
		else
			-- PushDebugMessage("g_rewardIndex:"..tostring(g_rewardIndex))
			g_Shuangdan_Choujiang_IsAnimateCircleEnd = 1
		end
	else
		g_Shuangdan_Choujiang_AnimateStep = g_Shuangdan_Choujiang_AnimateStep + 1
	end
	g_Shuangdan_Choujiang_RewardItemUITalbe[g_Shuangdan_Choujiang_AnimateStep].ItemAnimate:Show()
	KillTimer("Shuangdan_Choujiang_Tick()")
	if g_Shuangdan_Choujiang_AnimateStep == g_Shuangdan_Choujiang_rewardIndex and
		g_Shuangdan_Choujiang_IsAnimateCircleEnd == 1 then
		-- g_RewardItemUITalbe[g_AnimateStep].BK2:Show()
		g_Shuangdan_Choujiang_IsChouJiangIng = 0
		g_Shuangdan_Choujiang_IsAnimateCircleEnd = 0
		g_Shuangdan_Choujiang_AnimateCircleCount = 1
		PushDebugMessage(ScriptGlobal_Format("#{SDCJ_231026_24}", tostring(g_Shuangdan_Choujiang_RewardNum),
			DataPool:Lua_GetItemNameByIndex(g_Shuangdan_Choujiang_RewardItemId)))
	else
		SetTimer("Shuangdan_Choujiang", "Shuangdan_Choujiang_Tick()",
			g_Shuangdan_Choujiang_AnimateSpeed[g_Shuangdan_Choujiang_AnimateStep])
	end
end

--获得累计奖励的领取情况
function Shuangdan_Choujiang_GetSixActionBtnStates()
	local r1, r2, r3, r4, r5 = 0, 0, 0, 0, 0
	r1 = Pneuma:GetMF(g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[1].mf)
	r2 = Pneuma:GetMF(g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[2].mf)
	r3 = Pneuma:GetMF(g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[3].mf)
	r4 = Pneuma:GetMF(g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[4].mf)
	r5 = Pneuma:GetMF(g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[5].mf)
	return r1, r2, r3, r4, r5
end

--设置累计奖励actionbtn的UI表现
function Shuangdan_Choujiang_SetLJJLABtnUI(ljjlcs)
	g_Shuangdan_Choujiang_IsGetLJJLStates[1], g_Shuangdan_Choujiang_IsGetLJJLStates[2],
		g_Shuangdan_Choujiang_IsGetLJJLStates[3],
		g_Shuangdan_Choujiang_IsGetLJJLStates[4], g_Shuangdan_Choujiang_IsGetLJJLStates[5] = Shuangdan_Choujiang_GetSixActionBtnStates()
	for i = 1, g_Shuangdan_Choujiang_MaxLJJL, 1 do
		if g_Shuangdan_Choujiang_IsGetLJJLStates[i] == 1 then --已被领取 开启已领取MASK 关闭红点
			g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].IsGetMask:Show()
			g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].RedPoint:Hide()
		else --未被领取 关闭已领取MASK 根据当前领奖次数 开关红点
			g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].IsGetMask:Hide()
			if g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[i].needValue <= ljjlcs then
				g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].RedPoint:Show()
			else
				g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].RedPoint:Hide()
			end
		end
		if g_Shuangdan_Choujiang_IsKaJi == 1 then
			g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].actionBtn:SetToolTip(g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[i].tips2)
		else
			g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].actionBtn:SetToolTip(g_Shuangdan_Choujiang_MD_LJCS_IsGet_Index[i].tips1)
		end
		local text = ScriptGlobal_Format("#{SDCJ_231026_10}", g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].needValue)
		g_Shuangdan_Choujiang_LJJLActionBtnTbl[i].NameText:SetText(text)
	end
end

--重置位置
function Shuangdan_Choujiang_On_ResetPos()
	Shuangdan_Choujiang_FrameNULL:SetProperty("UnifiedPosition", g_Shuangdan_Choujiang_UnifiedPosition)
end
