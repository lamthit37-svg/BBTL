-- 风云联动 主UI
local FengYun_PVE_AwardScriptId = 335922
local FengYun_PVE_LevelLimit = 60
local FengYun_PVE_LastAwardTime = 0
-- 默认位置
local FengYun_PVE_UnifiedPosition = nil
-- 奖励按钮控件列表
local FengYun_PVE_AwardCtrl = nil

-- 查看事件id
local FengYun_PVE_ViewEvent =
{
	collect = 1,					-- 查看收藏
	achievement = 2,				-- 查看成就
	talent = 3,						-- 查看天赋
} -- end FengYun_PVE_ViewEvent

-- 寻路目标npc
local FengYun_PVE_EnterNPCInfo =
{
	[1] = {scn = 1054, pos = {87, 97}},
	[2] = {scn = 1055, pos = {280, 63}},
} -- end FengYun_PVE_EnterNPCInfo

-- 奖励点数
local FengYun_PVE_WeekAwardActPoint =
{
	[1] = 1500,						-- 奖励1领奖需要的点数
	[2] = 3000,						-- 奖励2领奖需要的点数
	[3] = 5000,						-- 奖励3领奖需要的点数
	[4] = 7000,						-- 奖励4领奖需要的点数
	[5] = 10000,					-- 奖励5领奖需要的点数

	count = 5,
} -- end FengYun_PVE_WeekAwardActPoint

local FengYun_PVE_AwardTips =
{
	[1] = "#{FYPVE_260108_144}",
	[2] = "#{FYPVE_260108_145}",
	[3] = "#{FYPVE_260108_146}",
	[4] = "#{FYPVE_260108_147}",
	[5] = "#{FYPVE_260108_148}",
}

function FengYun_PVE_PreLoad()
	this:RegisterEvent("FYPVE_TRYTOOPENMAIN", true)
	this:RegisterEvent("FYPVE_MAINOPEN", true)
	this:RegisterEvent("FYPVE_MAINUPDATE", true)
	this:RegisterEvent("FYPVE_UPDATEWEEKAWARDSTATE", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_PreLoad()

function FengYun_PVE_OnEvent(event)
	if (event == "FYPVE_TRYTOOPENMAIN") then
		AskServerTimeAgain()
		FYPVE:AskForFYPVEActData()
		FengYun_PVE_InitCtrl()
	elseif (event == "FYPVE_MAINOPEN") then
		AskServerTimeAgain()
		FengYun_PVE_UpdateUIInfo(arg0, arg1)
		FengYun_PVE_Ach_Show()
	elseif (event == "FYPVE_MAINUPDATE") then
		if (this:IsVisible()) then
			FengYun_PVE_UpdateUIInfo(arg0, arg1)
		end
	elseif (event == "FYPVE_UPDATEWEEKAWARDSTATE") then
		if (this:IsVisible()) then
			FengYun_PVE_UpdateWeekAwardState()
		end
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_UnifiedPos()
	end
end -- end func FengYun_PVE_OnEvent()

function FengYun_PVE_OnLoad()
	FengYun_PVE_UnifiedPosition = FengYun_PVE_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_OnLoad()

-- 界面默认位置
function FengYun_PVE_UnifiedPos()
	if (FengYun_PVE_UnifiedPosition ~= nil) then
		FengYun_PVE_Frame:SetProperty("UnifiedPosition", FengYun_PVE_UnifiedPosition)
	end
end -- end func FengYun_PVE_UnifiedPos()

function FengYun_PVE_Show()
	FengYun_PVE_LastAwardTime = 0
    this:Show()
end -- end func FengYun_PVE_Show()

function FengYun_PVE_Hide()
    this:Hide()
end -- end func FengYun_PVE_Hide()

--*************************************************************************************************
--
--*************************************************************************************************

-- 关闭按钮点击事件
function FengYun_PVE_OnHiden()
	FengYun_PVE_Hide()
end -- end func FengYun_PVE_OnHiden()

-- 查看收藏 成就 天赋按钮事件
function FengYun_PVE_ConfirmClick(viewId)
	if (viewId == nil) then
		return
	end

	FYPVE:AskForFYPVEActBaseData()
	if (viewId == FengYun_PVE_ViewEvent.collect) then
		-- 查看收藏
		PushEvent("FYPVE_COLLECTOPEN")
	elseif (viewId == FengYun_PVE_ViewEvent.achievement) then
		-- 查看成就
		PushEvent("FYPVE_ACHIEVEMENTOPEN")
	elseif (viewId == FengYun_PVE_ViewEvent.talent) then
		-- 查看天赋
		PushEvent("FYPVE_TALENTOPEN")
	else
		-- 按说不应该到这的
	end

	-- FengYun_PVE_Hide()
end -- end func FengYun_PVE_ConfirmClick

-- 前往参与按钮事件
function FengYun_PVE_GotoNpc()
	local curLevel = Player:GetLevel()
	if (curLevel < FengYun_PVE_LevelLimit) then
		PushDebugMessage("#{FYPVE_260108_02}")
		return
	end
	local isInAct, actStage = FengYun_PVE_GetActStage()
	if (isInAct == nil or isInAct <= 0) then
		-- 不在活动时间
		PushDebugMessage("#{FYPVE_260108_16}")
		return
	elseif (actStage == nil or actStage == 0) then
		-- 两个阶段间隔期
		PushDebugMessage("#{FYPVE_260108_169}")
		return
	end

	local npcInfo = FengYun_PVE_EnterNPCInfo[actStage]
	if (npcInfo ~= nil) then
		if (npcInfo.name ~= nil) then
			AutoRuntoTargetExWithName(npcInfo.pos[1], npcInfo.pos[2], npcInfo.scn, npcInfo.name)
		else
			AutoRunToTargetEx(npcInfo.pos[1], npcInfo.pos[2], npcInfo.scn)
		end
	end
end -- end func FengYun_PVE_GotoNpc

-- 领奖按钮
function FengYun_PVE_Clicked(awardId)
	if (awardId <= 0 or awardId > table.getn(FengYun_PVE_WeekAwardActPoint)) then
		return
	end

	-- 操作CD
	local curTime = os.time()
	if (curTime <= FengYun_PVE_LastAwardTime) then
		return
	end
	FengYun_PVE_LastAwardTime = curTime

	local isInAct, actStage = FengYun_PVE_GetActStage()
	if (isInAct < 0) then
		-- 不在活动时间
		PushDebugMessage("#{FYPVE_260108_16}")
		return
	end

	local curLevel = Player:GetLevel()
	if (curLevel < FengYun_PVE_LevelLimit) then
		-- 等级不够
		PushDebugMessage("#{FYPVE_260108_17}")
		return
	end

	local curWeekPoint = FYPVE:GetCurWeekActPoint()
	local needPoint = FengYun_PVE_WeekAwardActPoint[awardId]
	if (curWeekPoint < needPoint) then
		-- 玩家点数不够
		PushDebugMessage("#{FYPVE_260108_19}")
		return
	end

	local awardState1 = FYPVE:GetCurWeekPointAwardFlag(awardId-1)
	if (awardState1 > 0) then
		-- 已领取过奖励
		PushDebugMessage("#{FYPVE_260108_18}")
		return
	end

	-- if (FengYun_PVE_AwardCtrl ~= nil and FengYun_PVE_AwardCtrl[awardId] ~= nil) then
	-- 	FengYun_PVE_AwardCtrl[awardId].tip:Hide()
	-- 	FengYun_PVE_AwardCtrl[awardId].mark:Show()
	-- end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CCallBack_WeekAward")
		Set_XSCRIPT_ScriptID(FengYun_PVE_AwardScriptId)
		Set_XSCRIPT_Parameter(0, awardId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func FengYun_PVE_Clicked()

--*************************************************************************************************
--
--*************************************************************************************************
function FengYun_PVE_InitCtrl()
	if (FengYun_PVE_AwardCtrl == nil) then
		FengYun_PVE_AwardCtrl = {}

		FengYun_PVE_AwardCtrl[1] = {}
		FengYun_PVE_AwardCtrl[1].btn = FengYun_PVE_ProgressBtn1
		FengYun_PVE_AwardCtrl[1].tip = FengYun_PVE_ProgressTips1
		FengYun_PVE_AwardCtrl[1].mark = FengYun_PVE_ProgressGetMark1
		FengYun_PVE_AwardCtrl[1].txt = FengYun_PVE_ProgressText1

		FengYun_PVE_AwardCtrl[2] = {}
		FengYun_PVE_AwardCtrl[2].btn = FengYun_PVE_ProgressBtn2
		FengYun_PVE_AwardCtrl[2].tip = FengYun_PVE_ProgressTips2
		FengYun_PVE_AwardCtrl[2].mark = FengYun_PVE_ProgressGetMark2
		FengYun_PVE_AwardCtrl[2].txt = FengYun_PVE_ProgressText2

		FengYun_PVE_AwardCtrl[3] = {}
		FengYun_PVE_AwardCtrl[3].btn = FengYun_PVE_ProgressBtn3
		FengYun_PVE_AwardCtrl[3].tip = FengYun_PVE_ProgressTips3
		FengYun_PVE_AwardCtrl[3].mark = FengYun_PVE_ProgressGetMark3
		FengYun_PVE_AwardCtrl[3].txt = FengYun_PVE_ProgressText3

		FengYun_PVE_AwardCtrl[4] = {}
		FengYun_PVE_AwardCtrl[4].btn = FengYun_PVE_ProgressBtn4
		FengYun_PVE_AwardCtrl[4].tip = FengYun_PVE_ProgressTips4
		FengYun_PVE_AwardCtrl[4].mark = FengYun_PVE_ProgressGetMark4
		FengYun_PVE_AwardCtrl[4].txt = FengYun_PVE_ProgressText4

		FengYun_PVE_AwardCtrl[5] = {}
		FengYun_PVE_AwardCtrl[5].btn = FengYun_PVE_ProgressBtn5
		FengYun_PVE_AwardCtrl[5].tip = FengYun_PVE_ProgressTips5
		FengYun_PVE_AwardCtrl[5].mark = FengYun_PVE_ProgressGetMark5
		FengYun_PVE_AwardCtrl[5].txt = FengYun_PVE_ProgressText5
	end
end -- end func FengYun_PVE_InitCtrl()

function FengYun_PVE_GetActStage()
	local beginDate1 = nil
	local endDate1 = nil
	local beginDate2 = nil
	local endDate2 = nil
	beginDate1, endDate1, beginDate2, endDate2 = FYPVE:GetActTime()
	if (beginDate1 == nil) then
		return -10, -10
	end

	local inAct = -1
	local curStage = -1
	local curDay = tonumber(DataPool:GetServerDayTime())
	if (curDay < beginDate1) then
		-- 活动未开始
		inAct = -1
		curStage = -1
	elseif (curDay >= beginDate1 and curDay <= endDate1) then
		-- 活动第一阶段
		inAct = 1
		curStage = 1
	elseif (curDay > endDate1 and curDay < beginDate2) then
		-- 第一阶段和第二阶段之间
		inAct = 1
		curStage = 0
	elseif (curDay >= beginDate2 and curDay <= endDate2) then
		-- 活动第二阶段
		inAct = 1
		curStage = 2
	else
		-- 活动已结束
		inAct = -2
		curStage = -1
	end

	return inAct, curStage
end -- end func FengYun_PVE_GetActStage()

function FengYun_PVE_UpdateUIInfo(achAwardRedPoint, talentRedPoint)
	FengYun_PVE_InitCtrl()

	local achAwardRedPointFlag = 0
	if (achAwardRedPoint ~= nil) then
		achAwardRedPointFlag = tonumber(achAwardRedPoint)
	end
	if (achAwardRedPointFlag > 0) then
		FengYun_PVE_Button2Tips:Show()
	else
		FengYun_PVE_Button2Tips:Hide()
	end

	local talentRedPointFlag = 0
	if (talentRedPoint ~= nil) then
		talentRedPointFlag = tonumber(talentRedPoint)
	end
	if (talentRedPointFlag > 0) then
		FengYun_PVE_Button3Tips:Show()
	else
		FengYun_PVE_Button3Tips:Hide()
	end

	-- 活动描述
	local isInAct, actStage = FengYun_PVE_GetActStage()
	if (isInAct < 0) then
		-- 活动未开始 按时不应该这样 不过既然到这了就显示第一阶段的描述吧
		FengYun_PVE_Info:SetText("#{FYPVE_260108_06}")
		FengYun_PVE_Lingyunku_BK:Show()
		FengYun_PVE_Tianxiahui_BK:Hide()
	else
		if (actStage == 1) then
			-- 第一阶段
			FengYun_PVE_Info:SetText("#{FYPVE_260108_06}")
			FengYun_PVE_Lingyunku_BK:Show()
			FengYun_PVE_Tianxiahui_BK:Hide()
		elseif (actStage == 0) then
			-- 第一阶段和第二阶段之间
			FengYun_PVE_Info:SetText("#{FYPVE_260108_07}")
			FengYun_PVE_Lingyunku_BK:Hide()
			FengYun_PVE_Tianxiahui_BK:Show()
		elseif (actStage == 2) then
			-- 第二阶段
			FengYun_PVE_Info:SetText("#{FYPVE_260108_07}")
			FengYun_PVE_Lingyunku_BK:Hide()
			FengYun_PVE_Tianxiahui_BK:Show()
		else
			-- 按说不应该这样 不过既然到这了就显示第一阶段的描述吧
			FengYun_PVE_Info:SetText("#{FYPVE_260108_06}")
			FengYun_PVE_Lingyunku_BK:Show()
			FengYun_PVE_Tianxiahui_BK:Hide()
		end
	end

	if (FengYun_PVE_GoBtn ~= nil) then
		if (actStage == 1) then
			FengYun_PVE_GoBtn:SetToolTip("#{FYPVE_260108_01}")
		else
			FengYun_PVE_GoBtn:SetToolTip("#{FYPVE_260108_139}")
		end
	end
	
	-- 本周累计带出物资
	local curWeekPoint = FYPVE:GetCurWeekActPoint()
	local weekPointStr = ScriptGlobal_Format("#{FYPVE_260108_08}", curWeekPoint)
	FengYun_PVE_ProgressText:SetText(weekPointStr)

	-- 奖励进度
	local weekAwardCount = FengYun_PVE_WeekAwardActPoint.count
	local weekAwardMaxCount = FengYun_PVE_WeekAwardActPoint[weekAwardCount]
	if (weekAwardMaxCount ~= nil and weekAwardMaxCount > 0) then
		FengYun_PVE_Progress:SetProgress(curWeekPoint, weekAwardMaxCount)
	end

	-- 奖励
	for i=1, table.getn(FengYun_PVE_AwardCtrl), 1 do
		if (FengYun_PVE_AwardCtrl[i] ~= nil) then
			if (curWeekPoint < FengYun_PVE_WeekAwardActPoint[i]) then
				-- 未达条件
				FengYun_PVE_AwardCtrl[i].btn:Show()
				FengYun_PVE_AwardCtrl[i].btn:Enable()	-- 领奖按钮
				FengYun_PVE_AwardCtrl[i].mark:Hide()	-- 领取标记
				FengYun_PVE_AwardCtrl[i].tip:Hide()		-- 小红点
			else
				-- 已达条件
				local awardState = FYPVE:GetCurWeekPointAwardFlag(i-1)
				if (awardState > 0) then
					-- 已领奖
					FengYun_PVE_AwardCtrl[i].btn:Hide()		-- 领奖按钮
					FengYun_PVE_AwardCtrl[i].mark:Show()	-- 领取标记
					FengYun_PVE_AwardCtrl[i].tip:Hide()		-- 小红点
					local tipInfo = FengYun_PVE_AwardTips[i]
					if tipInfo ~= nil then
						FengYun_PVE_AwardCtrl[i].mark:SetToolTip(tipInfo)
					else
						FengYun_PVE_AwardCtrl[i].mark:SetToolTip("")
					end
				else
					-- 未领奖
					FengYun_PVE_AwardCtrl[i].btn:Show()
					FengYun_PVE_AwardCtrl[i].btn:Enable()	-- 领奖按钮
					FengYun_PVE_AwardCtrl[i].mark:Hide()	-- 领取标记
					FengYun_PVE_AwardCtrl[i].tip:Show()		-- 小红点
				end
			end
			FengYun_PVE_AwardCtrl[i].txt:SetText(tostring(FengYun_PVE_WeekAwardActPoint[i]))
		end
	end -- end for

	-- 本周参与次数
	local weekEnterCount = FYPVE:GetCurWeekEnterCount()
	local weekEnterCountStr = ScriptGlobal_Format("#{FYPVE_260108_12}", weekEnterCount)
	FengYun_PVE_GotoNum:SetText(weekEnterCountStr)
end -- end func FengYun_PVE_UpdateUIInfo()

function FengYun_PVE_UpdateWeekAwardState()
	FengYun_PVE_InitCtrl()

	local curWeekPoint = FYPVE:GetCurWeekActPoint()
	-- 奖励
	for i=1, table.getn(FengYun_PVE_AwardCtrl), 1 do
		if (FengYun_PVE_AwardCtrl[i] ~= nil) then
			if (curWeekPoint < FengYun_PVE_WeekAwardActPoint[i]) then
				-- 未达条件
				FengYun_PVE_AwardCtrl[i].btn:Show()
				FengYun_PVE_AwardCtrl[i].btn:Enable()	-- 领奖按钮
				FengYun_PVE_AwardCtrl[i].mark:Hide()	-- 领取标记
				FengYun_PVE_AwardCtrl[i].tip:Hide()		-- 小红点
			else
				-- 已达条件
				local awardState = FYPVE:GetCurWeekPointAwardFlag(i-1)
				if (awardState > 0) then
					-- 已领奖
					FengYun_PVE_AwardCtrl[i].btn:Hide()		-- 领奖按钮
					FengYun_PVE_AwardCtrl[i].mark:Show()	-- 领取标记
					FengYun_PVE_AwardCtrl[i].tip:Hide()		-- 小红点
					local tipInfo = FengYun_PVE_AwardTips[i]
					if tipInfo ~= nil then
						FengYun_PVE_AwardCtrl[i].mark:SetToolTip(tipInfo)
					else
						FengYun_PVE_AwardCtrl[i].mark:SetToolTip("")
					end
				else
					-- 未领奖
					FengYun_PVE_AwardCtrl[i].btn:Show()
					FengYun_PVE_AwardCtrl[i].btn:Enable()	-- 领奖按钮
					FengYun_PVE_AwardCtrl[i].mark:Hide()	-- 领取标记
					FengYun_PVE_AwardCtrl[i].tip:Show()		-- 小红点
				end
			end
			FengYun_PVE_AwardCtrl[i].txt:SetText(tostring(FengYun_PVE_WeekAwardActPoint[i]))
		end
	end -- end for
end -- end fucn FengYun_PVE_UpdateWeekAwardState()