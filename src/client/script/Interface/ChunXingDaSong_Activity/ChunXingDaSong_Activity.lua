--2020Q4 春节活动 春行大宋

-- 服务器脚本号
local ChunXingDaSong_Activity_ServerScriptId = 888326
-- UICommand
local ChunXingDaSong_Activity_UICommand = 20122801
local ChunXingDaSong_Activity_UICommandType =
{
	Type_PointInfo = 1,             -- 里程信息
	Type_AwardState = 2,            -- 领奖状态信息
	Type_PointAndAwardState = 3,    -- 里程和领奖信息
} -- end ChunXingDaSong_Activity_UICommandType

-- 活动起止时间
local ChunXingDaSong_Activity_BeginDate = 20210125
local ChunXingDaSong_Activity_EndDate = 20210210

local ChunXingDaSong_Activity_MinLevel = 30					-- 参与活动最小等级（包含）
local ChunXingDaSong_Activity_MaxPoint = 400
local ChunXingDaSong_Activity_UnifiedPosition = nil

-- 奖励按钮状态
local ChunXingDaSong_Activity_AwardBtnState =
{
	State_None = 1,		-- 无奖励
	State_Has = 2,		-- 有奖励 未领取
	State_Got = 3,		-- 有奖励 已领取
} -- end ChunXingDaSong_Activity_AwardBtnState

-- 奖励展示物品
-- 奖励信息
local ChunXingDaSong_Activity_AwardItemInfo =
{
    -- 阶段1奖励
    [1] =
    {
		[1] = {needpoint = 1000},
        [2] = {item = 39923116, num = 8},
		[3] = {item = 39920566, num = 2},
		[4] = {item = 39922025, num = 12},
    },

    -- 阶段2奖励
    [2] =
    {
        [1] = {needpoint = 2000},
        [2] = {item = 39923116, num = 8},
		[3] = {item = 39920565, num = 2},
		[4] = {item = 39922025, num = 14},
    },

    -- 阶段3奖励
    [3] =
    {
        [1] = {needpoint = 3000},
        [2] = {item = 39923116, num = 8},
		[3] = {item = 39920945, num = 1},
		[4] = {item = 39922025, num = 16},
    },

    -- 阶段4奖励
    [4] =
    {
        [1] = {needpoint = 4000},
        [2] = {item = 39923116, num = 8},
		[3] = {item = 39922686, num = 10},
		[4] = {item = 39922025, num = 20},
    },

    -- 阶段5奖励
    [5] =
    {
        [1] = {needpoint = 5000},
        [2] = {item = 39923116, num = 8},
		[3] = {item = 39923161, num = 1},
		[4] = {item = 39922025, num = 24},
    },

    -- 阶段6奖励
    [6] =
    {
        [1] = {needpoint = 7500},
        [2] = {item = 39923116, num = 8},
		[3] = {item = 39922750, num = 10},
		[4] = {item = 39922025, num = 30},
    },
} -- end ChunXingDaSong_Activity_AwardItemInfo

-- 奖励展示控件列表
local ChunXingDaSong_Activity_AwardControl = {}
-- 领奖按钮控件列表
local ChunXingDaSong_Activity_AwardBtn = {}
-- 领奖按钮红点图标按钮
local ChunXingDaSong_Activity_AwardRedDot = {}
-- 领奖按钮已领取图标列表
local ChunXingDaSong_Activity_AwardGot = {}
-- 领奖按钮未达到领奖条件图标列表
local ChunXingDaSong_Activity_NotAwrad = {}



function ChunXingDaSong_Activity_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("CXDS_UI_OPEN")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end -- end func ChunXingDaSong_Activity_PreLoad()

function ChunXingDaSong_Activity_OnLoad()	
	ChunXingDaSong_Activity_UnifiedPosition = ChunXingDaSong_Activity:GetProperty("UnifiedPosition")	
end -- end func ChunXingDaSong_Activity_OnLoad()

function ChunXingDaSong_Activity_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == ChunXingDaSong_Activity_UICommand) then
		if (this:IsVisible() == false) then
			ChunXingDaSong_Activity_OnShow()
		end

		local type = Get_XParam_INT(0)
		if (type == ChunXingDaSong_Activity_UICommandType.Type_PointInfo) then
			local totalPoint = Get_XParam_INT(1)
			local todayPoint = Get_XParam_INT(2)
			local todayFactor = Get_XParam_INT(3)

			ChunXingDaSong_Activity_UpdatePointInfo(totalPoint, todayPoint, todayFactor)
		elseif (type == ChunXingDaSong_Activity_UICommandType.Type_AwardState) then
			local state1 = Get_XParam_INT(1)
			local state2 = Get_XParam_INT(2)
			local state3 = Get_XParam_INT(3)
			local state4 = Get_XParam_INT(4)
			local state5 = Get_XParam_INT(5)
			local state6 = Get_XParam_INT(6)

			ChunXingDaSong_Activity_UpdateAwardState(state1, state2, state3, state4, state5, state6)
		elseif (type == ChunXingDaSong_Activity_UICommandType.Type_PointAndAwardState) then
			local totalPoint = Get_XParam_INT(1)
			local todayPoint = Get_XParam_INT(2)
			local todayFactor = Get_XParam_INT(3)
			local state1 = Get_XParam_INT(4)
			local state2 = Get_XParam_INT(5)
			local state3 = Get_XParam_INT(6)
			local state4 = Get_XParam_INT(7)
			local state5 = Get_XParam_INT(8)
			local state6 = Get_XParam_INT(9)

			ChunXingDaSong_Activity_UpdatePointAndAwardState(totalPoint, todayPoint, todayFactor, state1, state2, state3, state4, state5, state6)
		end
	elseif (event == "CXDS_UI_OPEN") then
		ChunXingDaSong_Activity_OnShow()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
        ChunXingDaSong_Activity_OnHide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        ChunXingDaSong_Activity_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        ChunXingDaSong_Activity_UnifiedPos()
	end
end -- end func ChunXingDaSong_Activity_OnEvent()

-- 界面默认位置
function ChunXingDaSong_Activity_UnifiedPos()
    if (this:IsVisible()) then
        if (ChunXingDaSong_Activity_UnifiedPosition ~= nil) then
            ChunXingDaSong_Activity:SetProperty("UnifiedPosition", ChunXingDaSong_Activity_UnifiedPosition)
        end
    end
end -- end func ChunXingDaSong_Activity_UnifiedPos()

-- 初始化控件列表
function ChunXingDaSong_Activity_InitControlList()
	ChunXingDaSong_Activity_AwardControl[1] = {}
	ChunXingDaSong_Activity_AwardControl[1].control1 = ChunXingDaSong_Activity_Reward_BasicItem1
	ChunXingDaSong_Activity_AwardControl[1].control2 = ChunXingDaSong_Activity_Reward_BasicItem2
	ChunXingDaSong_Activity_AwardControl[1].control3 = ChunXingDaSong_Activity_Reward_BasicItem3
	ChunXingDaSong_Activity_AwardControl[2] = {}
	ChunXingDaSong_Activity_AwardControl[2].control1 = ChunXingDaSong_Activity_Reward_BasicItem4
	ChunXingDaSong_Activity_AwardControl[2].control2 = ChunXingDaSong_Activity_Reward_BasicItem5
	ChunXingDaSong_Activity_AwardControl[2].control3 = ChunXingDaSong_Activity_Reward_BasicItem6
	ChunXingDaSong_Activity_AwardControl[3] = {}
	ChunXingDaSong_Activity_AwardControl[3].control1 = ChunXingDaSong_Activity_Reward_BasicItem7
	ChunXingDaSong_Activity_AwardControl[3].control2 = ChunXingDaSong_Activity_Reward_BasicItem8
	ChunXingDaSong_Activity_AwardControl[3].control3 = ChunXingDaSong_Activity_Reward_BasicItem9
	ChunXingDaSong_Activity_AwardControl[4] = {}
	ChunXingDaSong_Activity_AwardControl[4].control1 = ChunXingDaSong_Activity_Reward_BasicItem10
	ChunXingDaSong_Activity_AwardControl[4].control2 = ChunXingDaSong_Activity_Reward_BasicItem11
	ChunXingDaSong_Activity_AwardControl[4].control3 = ChunXingDaSong_Activity_Reward_BasicItem12
	ChunXingDaSong_Activity_AwardControl[5] = {}
	ChunXingDaSong_Activity_AwardControl[5].control1 = ChunXingDaSong_Activity_Reward_BasicItem13
	ChunXingDaSong_Activity_AwardControl[5].control2 = ChunXingDaSong_Activity_Reward_BasicItem14
	ChunXingDaSong_Activity_AwardControl[5].control3 = ChunXingDaSong_Activity_Reward_BasicItem15
	ChunXingDaSong_Activity_AwardControl[6] = {}
	ChunXingDaSong_Activity_AwardControl[6].control1 = ChunXingDaSong_Activity_Reward_BasicItem16
	ChunXingDaSong_Activity_AwardControl[6].control2 = ChunXingDaSong_Activity_Reward_BasicItem17
	ChunXingDaSong_Activity_AwardControl[6].control3 = ChunXingDaSong_Activity_Reward_BasicItem18

	ChunXingDaSong_Activity_AwardBtn[1] = ChunXingDaSong_Activity_Award_GetCondition_Btn1
	ChunXingDaSong_Activity_AwardBtn[2] = ChunXingDaSong_Activity_Award_GetCondition_Btn2
	ChunXingDaSong_Activity_AwardBtn[3] = ChunXingDaSong_Activity_Award_GetCondition_Btn3
	ChunXingDaSong_Activity_AwardBtn[4] = ChunXingDaSong_Activity_Award_GetCondition_Btn4
	ChunXingDaSong_Activity_AwardBtn[5] = ChunXingDaSong_Activity_Award_GetCondition_Btn5
	ChunXingDaSong_Activity_AwardBtn[6] = ChunXingDaSong_Activity_Award_GetCondition_Btn6

	ChunXingDaSong_Activity_AwardRedDot[1] = ChunXingDaSong_Activity_Award_GetCondition_RedDot1
	ChunXingDaSong_Activity_AwardRedDot[2] = ChunXingDaSong_Activity_Award_GetCondition_RedDot2
	ChunXingDaSong_Activity_AwardRedDot[3] = ChunXingDaSong_Activity_Award_GetCondition_RedDot3
	ChunXingDaSong_Activity_AwardRedDot[4] = ChunXingDaSong_Activity_Award_GetCondition_RedDot4
	ChunXingDaSong_Activity_AwardRedDot[5] = ChunXingDaSong_Activity_Award_GetCondition_RedDot5
	ChunXingDaSong_Activity_AwardRedDot[6] = ChunXingDaSong_Activity_Award_GetCondition_RedDot6

	ChunXingDaSong_Activity_AwardGot[1] = ChunXingDaSong_Activity_Award_GetCondition_Pic1
	ChunXingDaSong_Activity_AwardGot[2] = ChunXingDaSong_Activity_Award_GetCondition_Pic2
	ChunXingDaSong_Activity_AwardGot[3] = ChunXingDaSong_Activity_Award_GetCondition_Pic3
	ChunXingDaSong_Activity_AwardGot[4] = ChunXingDaSong_Activity_Award_GetCondition_Pic4
	ChunXingDaSong_Activity_AwardGot[5] = ChunXingDaSong_Activity_Award_GetCondition_Pic5
	ChunXingDaSong_Activity_AwardGot[6] = ChunXingDaSong_Activity_Award_GetCondition_Pic6

	ChunXingDaSong_Activity_NotAwrad[1] = ChunXingDaSong_Activity_Award_GetCondition_Pic1_0
	ChunXingDaSong_Activity_NotAwrad[2] = ChunXingDaSong_Activity_Award_GetCondition_Pic2_0
	ChunXingDaSong_Activity_NotAwrad[3] = ChunXingDaSong_Activity_Award_GetCondition_Pic3_0
	ChunXingDaSong_Activity_NotAwrad[4] = ChunXingDaSong_Activity_Award_GetCondition_Pic4_0
	ChunXingDaSong_Activity_NotAwrad[5] = ChunXingDaSong_Activity_Award_GetCondition_Pic5_0
	ChunXingDaSong_Activity_NotAwrad[6] = ChunXingDaSong_Activity_Award_GetCondition_Pic6_0
end -- end func ChunXingDaSong_Activity_InitControlList()

function ChunXingDaSong_Activity_OnShow()
	ChunXingDaSong_Activity_InitControlList()

	-- 展示奖励物品
	ChunXingDaSong_Activity_ShowAwardItemInfo()

	-- 设置里程信息默认显示
	ChunXingDaSong_Activity_DefaultPointInfo()

	-- 向服务器请求里程值和奖励状态信息
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SyncPointAndAwardStateInfo")
		Set_XSCRIPT_ScriptID(ChunXingDaSong_Activity_ServerScriptId)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	this:Show()
end -- end func ChunXingDaSong_Activity_OnShow()

function ChunXingDaSong_Activity_OnHide()
	this:Hide()
end -- end func ChunXingDaSong_Activity_OnHide()

-- 关闭按钮事件
function ChunXingDaSong_Activity_Close(arg)
	ChunXingDaSong_Activity_OnHide()
end -- end func ChunXingDaSong_Activity_Close()

-- 活动说明按钮事件
function ChunXingDaSong_Activity_Description_Clicked()
	PushEvent("QUEST_HELP_MSG", "#{CXDS_201224_15}")
end -- end func ChunXingDaSong_Activity_Description_Clicked()

-- 奖励领取按钮事件
function ChunXingDaSong_Activity_Award_Item_Clicked(arg)
	-- 获取当前服务器日期
	local curDate = tonumber(DataPool:GetServerDayTime())

	-- 检查活动时间
	if (curDate < ChunXingDaSong_Activity_BeginDate and curDate > ChunXingDaSong_Activity_EndDate) then
		-- 不在活动时间
		PushDebugMessage("#{CXDS_201224_04}")
		return
	end

	-- 检查玩家等级
	local curLevel = Player:GetLevel()
	if (curLevel < ChunXingDaSong_Activity_MinLevel) then
		-- 玩家等级不足
		PushDebugMessage("#{CXDS_201224_03}")
		return
	end

	-- 调用服务器脚本
	-- 剩下的条件在服务器端判断
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetPointAward")
			Set_XSCRIPT_ScriptID(ChunXingDaSong_Activity_ServerScriptId)
			Set_XSCRIPT_Parameter(0, arg);
			Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func ChunXingDaSong_Activity_Award_Item_Clicked()

-- 展示奖励物品
function ChunXingDaSong_Activity_ShowAwardItemInfo()
	for i = 1, table.getn(ChunXingDaSong_Activity_AwardItemInfo), 1 do
		-- 设置奖励展示物品
		if (ChunXingDaSong_Activity_AwardItemInfo[i] ~= nil and ChunXingDaSong_Activity_AwardControl[i] ~= nil) then
			if (ChunXingDaSong_Activity_AwardControl[i].control1 ~= nil and ChunXingDaSong_Activity_AwardControl[i].control2) then
				local item1 = ChunXingDaSong_Activity_AwardItemInfo[i][2].item
				local num1 = ChunXingDaSong_Activity_AwardItemInfo[i][2].num
				local theAction1 = DataPool:CreateBindActionItemForShow(tonumber(item1), tonumber(num1))
				if (theAction1:GetID() ~= 0) then
					ChunXingDaSong_Activity_AwardControl[i].control1:SetActionItem(theAction1:GetID())
				end

				local item2 = ChunXingDaSong_Activity_AwardItemInfo[i][3].item
				local num2 = ChunXingDaSong_Activity_AwardItemInfo[i][3].num
				local theAction2 = DataPool:CreateBindActionItemForShow(tonumber(item2), tonumber(num2))
				if (theAction2:GetID() ~= 0) then
					ChunXingDaSong_Activity_AwardControl[i].control2:SetActionItem(theAction2:GetID())
				end

				local item3 = ChunXingDaSong_Activity_AwardItemInfo[i][4].item
				local num3 = ChunXingDaSong_Activity_AwardItemInfo[i][4].num
				local theAction3 = DataPool:CreateBindActionItemForShow(tonumber(item3), tonumber(num3))
				if (theAction3:GetID() ~= 0) then
					ChunXingDaSong_Activity_AwardControl[i].control3:SetActionItem(theAction3:GetID())
				end
			end
		end

		-- 设置领奖按钮默认状态
		if (ChunXingDaSong_Activity_AwardBtn[i] ~= nil) then
			ChunXingDaSong_Activity_AwardBtn[i]:Hide()
		end
		if (ChunXingDaSong_Activity_AwardRedDot[i] ~= nil) then
			ChunXingDaSong_Activity_AwardRedDot[i]:Hide()
		end
		if (ChunXingDaSong_Activity_AwardGot[i] ~= nil) then
			ChunXingDaSong_Activity_AwardGot[i]:Hide()
		end
		if (ChunXingDaSong_Activity_NotAwrad[i] ~= nil) then
			ChunXingDaSong_Activity_NotAwrad[i]:Hide()
		end
	end -- end for
end -- end func ChunXingDaSong_Activity_ShowAwardItemInfo()

-- 里程值默认显示显示
function ChunXingDaSong_Activity_DefaultPointInfo()
	-- -- 设置进度条
	-- ChunXingDaSong_Activity_Huoyue:SetProgress(0, ChunXingDaSong_Activity_MaxPoint)

	-- 设置总里程值
	-- local pointStr = ScriptGlobal_Format("#{CXDS_201224_18}", 0)
	-- pointStr = "#{CXDS_201224_17}" .. pointStr
	ChunXingDaSong_Activity_Huoyue_Totle:SetText("0")
	ChunXingDaSong_Activity_Huoyue_Totle:SetToolTip("#{CXDS_201224_19}")

	-- 这个UI上不显示倍率了
	-- -- 设置今日里程倍率
	-- local todayFactorStr = ScriptGlobal_Format("#{CXDS_201224_24}", 0)
	-- todayFactorStr = "#{CXDS_201224_23}" .. todayFactorStr
	-- ChunXingDaSong_Activity_Huoyue_Times:SetText(todayFactorStr)
	-- ChunXingDaSong_Activity_Huoyue_Times:SetToolTip("#{CXDS_201224_25}")
end -- end func ChunXingDaSong_Activity_DefaultPointInfo()

-- 更新领奖按钮状态
function ChunXingDaSong_Activity_UpdateAwardBtnState(btnIndex, state)
	if (state == ChunXingDaSong_Activity_AwardBtnState.State_None) then
		-- 无奖励
		if (ChunXingDaSong_Activity_AwardBtn[btnIndex] ~= nil) then
			-- 隐藏领奖按钮
			ChunXingDaSong_Activity_AwardBtn[btnIndex]:Hide()
		end
		if (ChunXingDaSong_Activity_AwardRedDot[btnIndex] ~= nil) then
			-- 隐藏领奖按钮小红点
			ChunXingDaSong_Activity_AwardRedDot[btnIndex]:Hide()
		end
		if (ChunXingDaSong_Activity_AwardGot[btnIndex] ~= nil) then
			-- 隐藏已领奖图标
			ChunXingDaSong_Activity_AwardGot[btnIndex]:Hide()
		end
		if (ChunXingDaSong_Activity_NotAwrad[btnIndex] ~= nil) then
			-- 显示未达到图标
			ChunXingDaSong_Activity_NotAwrad[btnIndex]:Show()
		end
	elseif (state == ChunXingDaSong_Activity_AwardBtnState.State_Has) then
		--  有奖励可领取
		if (ChunXingDaSong_Activity_AwardBtn[btnIndex] ~= nil) then
			-- 显示领奖按钮
			ChunXingDaSong_Activity_AwardBtn[btnIndex]:Show()
		end
		if (ChunXingDaSong_Activity_AwardRedDot[btnIndex] ~= nil) then
			-- 显示领奖按钮小红点
			ChunXingDaSong_Activity_AwardRedDot[btnIndex]:Show()
		end
		if (ChunXingDaSong_Activity_AwardGot[btnIndex] ~= nil) then
			-- 隐藏已领奖图标
			ChunXingDaSong_Activity_AwardGot[btnIndex]:Hide()
		end
		if (ChunXingDaSong_Activity_NotAwrad[btnIndex] ~= nil) then
			-- 隐藏未达到图标
			ChunXingDaSong_Activity_NotAwrad[btnIndex]:Hide()
		end
	elseif (state == ChunXingDaSong_Activity_AwardBtnState.State_Got) then
		-- 奖励已领取
		if (ChunXingDaSong_Activity_AwardBtn[btnIndex] ~= nil) then
			-- 隐藏领奖按钮
			ChunXingDaSong_Activity_AwardBtn[btnIndex]:Hide()
		end
		if (ChunXingDaSong_Activity_AwardRedDot[btnIndex] ~= nil) then
			-- 隐藏领奖按钮小红点
			ChunXingDaSong_Activity_AwardRedDot[btnIndex]:Hide()
		end
		if (ChunXingDaSong_Activity_AwardGot[btnIndex] ~= nil) then
			-- 显示已领奖图标
			ChunXingDaSong_Activity_AwardGot[btnIndex]:Show()
		end
		if (ChunXingDaSong_Activity_NotAwrad[btnIndex] ~= nil) then
			-- 隐藏未达到图标
			ChunXingDaSong_Activity_NotAwrad[btnIndex]:Hide()
		end
	else
		-- 这里就不对了
	end
end -- end func ChunXingDaSong_Activity_UpdateAwardBtnState()

-- 更新里程值
function ChunXingDaSong_Activity_UpdatePointInfo(point, todayPoint, todayPointFactor)
	-- -- 设置进度条
	-- if (point > ChunXingDaSong_Activity_MaxPoint) then
	-- 	ChunXingDaSong_Activity_Huoyue:SetProgress(ChunXingDaSong_Activity_MaxPoint, ChunXingDaSong_Activity_MaxPoint)
	-- else
	-- 	ChunXingDaSong_Activity_Huoyue:SetProgress(point, ChunXingDaSong_Activity_MaxPoint)
	-- end

	-- 设置总里程值
	-- local pointStr = ScriptGlobal_Format("#{CXDS_201224_18}", point)
	-- pointStr = "#{CXDS_201224_17}" .. pointStr
	ChunXingDaSong_Activity_Huoyue_Totle:SetText(tostring(point))

	-- 这个UI上不显示倍率了
	-- -- 设置今日里程倍率
	-- local todayFactorStr = ScriptGlobal_Format("#{CXDS_201224_24}", (todayPointFactor/10))
	-- todayFactorStr = "#{CXDS_201224_23}" .. todayFactorStr
	-- ChunXingDaSong_Activity_Huoyue_Times:SetText(todayFactorStr)
end -- end func ChunXingDaSong_Activity_UpdatePointInfo()

-- 更新领奖状态
function ChunXingDaSong_Activity_UpdateAwardState(state1, state2, state3, state4, state5, state6)
	-- 奖励阶段1 领奖状态
	if (state1 > 0) then
		-- 已领奖
	else
		-- 未领奖
	end

	-- 奖励阶段2 领奖状态
	if (state2 > 0) then
		-- 已领奖
	else
		-- 未领奖
	end

	-- 奖励阶段3 领奖状态
	if (state3 > 0) then
		-- 已领奖
	else
		--未领奖
	end

	-- 奖励阶段4 领奖状态
	if (state4 > 0) then
		-- 已领奖
	else
		-- 未领奖
	end

	-- 奖励阶段5 领奖状态
	if (state5 > 0) then
		-- 已领奖
	else
		--未领奖
	end

	-- 奖励阶段6 领奖状态
	if (state6 > 0) then
		-- 已领奖
	else
		-- 未领奖
	end
end -- end func ChunXingDaSong_Activity_UpdateAwardState()

-- 更新里程和领奖状态
function ChunXingDaSong_Activity_UpdatePointAndAwardState(point, todayPoint, todayPointFactor, state1, state2, state3, state4, state5, state6)
	-- -- 设置进度条
	-- if (point > ChunXingDaSong_Activity_MaxPoint) then
	-- 	ChunXingDaSong_Activity_Huoyue:SetProgress(ChunXingDaSong_Activity_MaxPoint, ChunXingDaSong_Activity_MaxPoint)
	-- else
	-- 	ChunXingDaSong_Activity_Huoyue:SetProgress(point, ChunXingDaSong_Activity_MaxPoint)
	-- end

	-- 设置总里程值
	-- local pointStr = ScriptGlobal_Format("#{CXDS_201224_18}", point)
	-- pointStr = "#{CXDS_201224_17}" .. pointStr
	ChunXingDaSong_Activity_Huoyue_Totle:SetText(tostring(point))

	-- 这个UI上不显示倍率了
	-- -- 设置今日里程倍率
	-- local todayFactorStr = ScriptGlobal_Format("#{CXDS_201224_24}", (todayPointFactor/10))
	-- todayFactorStr = "#{CXDS_201224_23}" .. todayFactorStr
	-- ChunXingDaSong_Activity_Huoyue_Times:SetText(todayFactorStr)

	-- 奖励阶段1 领奖状态
	if (state1 > 0) then
		-- 已领奖
		ChunXingDaSong_Activity_UpdateAwardBtnState(1, ChunXingDaSong_Activity_AwardBtnState.State_Got)
	else
		-- 未领奖
		if (point >= ChunXingDaSong_Activity_AwardItemInfo[1][1].needpoint) then
			ChunXingDaSong_Activity_UpdateAwardBtnState(1, ChunXingDaSong_Activity_AwardBtnState.State_Has)
		else
			ChunXingDaSong_Activity_UpdateAwardBtnState(1, ChunXingDaSong_Activity_AwardBtnState.State_None)
		end
	end

	-- 奖励阶段2 领奖状态
	if (state2 > 0) then
		-- 已领奖
		ChunXingDaSong_Activity_UpdateAwardBtnState(2, ChunXingDaSong_Activity_AwardBtnState.State_Got)
	else
		-- 未领奖
		if (point >= ChunXingDaSong_Activity_AwardItemInfo[2][1].needpoint) then
			ChunXingDaSong_Activity_UpdateAwardBtnState(2, ChunXingDaSong_Activity_AwardBtnState.State_Has)
		else
			ChunXingDaSong_Activity_UpdateAwardBtnState(2, ChunXingDaSong_Activity_AwardBtnState.State_None)
		end
	end

	-- 奖励阶段3 领奖状态
	if (state3 > 0) then
		-- 已领奖
		ChunXingDaSong_Activity_UpdateAwardBtnState(3, ChunXingDaSong_Activity_AwardBtnState.State_Got)
	else
		--未领奖
		if (point >= ChunXingDaSong_Activity_AwardItemInfo[3][1].needpoint) then
			ChunXingDaSong_Activity_UpdateAwardBtnState(3, ChunXingDaSong_Activity_AwardBtnState.State_Has)
		else
			ChunXingDaSong_Activity_UpdateAwardBtnState(3, ChunXingDaSong_Activity_AwardBtnState.State_None)
		end
	end

	-- 奖励阶段4 领奖状态
	if (state4 > 0) then
		-- 已领奖
		ChunXingDaSong_Activity_UpdateAwardBtnState(4, ChunXingDaSong_Activity_AwardBtnState.State_Got)
	else
		-- 未领奖
		if (point >= ChunXingDaSong_Activity_AwardItemInfo[4][1].needpoint) then
			ChunXingDaSong_Activity_UpdateAwardBtnState(4, ChunXingDaSong_Activity_AwardBtnState.State_Has)
		else
			ChunXingDaSong_Activity_UpdateAwardBtnState(4, ChunXingDaSong_Activity_AwardBtnState.State_None)
		end
	end

	-- 奖励阶段5 领奖状态
	if (state5 > 0) then
		-- 已领奖
		ChunXingDaSong_Activity_UpdateAwardBtnState(5, ChunXingDaSong_Activity_AwardBtnState.State_Got)
	else
		--未领奖
		if (point >= ChunXingDaSong_Activity_AwardItemInfo[5][1].needpoint) then
			ChunXingDaSong_Activity_UpdateAwardBtnState(5, ChunXingDaSong_Activity_AwardBtnState.State_Has)
		else
			ChunXingDaSong_Activity_UpdateAwardBtnState(5, ChunXingDaSong_Activity_AwardBtnState.State_None)
		end
	end

	-- 奖励阶段6 领奖状态
	if (state6 > 0) then
		-- 已领奖
		ChunXingDaSong_Activity_UpdateAwardBtnState(6, ChunXingDaSong_Activity_AwardBtnState.State_Got)
	else
		-- 未领奖
		if (point >= ChunXingDaSong_Activity_AwardItemInfo[6][1].needpoint) then
			ChunXingDaSong_Activity_UpdateAwardBtnState(6, ChunXingDaSong_Activity_AwardBtnState.State_Has)
		else
			ChunXingDaSong_Activity_UpdateAwardBtnState(6, ChunXingDaSong_Activity_AwardBtnState.State_None)
		end
	end
end -- end func ChunXingDaSong_Activity_UpdatePointAndAwardState()