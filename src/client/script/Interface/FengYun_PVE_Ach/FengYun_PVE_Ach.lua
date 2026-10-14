-- 风云联动 成就展示UI
local FengYun_PVE_Ach_SvrScriptId = 335922
local FengYun_PVE_Ach_LevelLimit = 60
local FengYun_PVE_Ach_LastAwardTime = 0
-- 默认位置
local FengYun_PVE_Ach_UnifiedPosition = nil
-- 成就控件列表
local FengYun_PVE_Ach_AchCtrl = nil

-- 成就类型
local FengYun_PVE_Ach_AchType =
{
	boss = 1,					-- 击杀boss
	totalpoint = 2,				-- 总物资点
	itemnum = 5,				-- 物品数量
} -- end FengYun_PVE_Ach_AchType

-- 成就状态
local FengYun_PVE_Ach_State =
{
	null = 0,					-- 默认值（未达成）
	achieved = 1,				-- 已达成 未领奖
	award = 2,					-- 已达成 已领奖
} -- end FengYun_PVE_Ach_State



function FengYun_PVE_Ach_PreLoad()
	this:RegisterEvent("FYPVE_TRYTOOPENACHIEVEMENT", true)
	this:RegisterEvent("FYPVE_ACHIEVEMENTOPEN", true)
	this:RegisterEvent("FYPVE_UPDATEACHSTATE", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Ach_PreLoad()

function FengYun_PVE_Ach_OnEvent(event)
	if (event == "FYPVE_TRYTOOPENACHIEVEMENT") then
		AskServerTimeAgain()
	elseif (event == "FYPVE_ACHIEVEMENTOPEN") then
		FengYun_PVE_Ach_UpdateAchInfo()
		FengYun_PVE_Ach_Show()
	elseif (event == "FYPVE_UPDATEACHSTATE") then
		if (this:IsVisible()) then
			FengYun_PVE_Ach_UpdateAchState(tonumber(arg0))
		end
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_Ach_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Ach_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Ach_UnifiedPos()
	end
end -- end func FengYun_PVE_Ach_OnEvent()

function FengYun_PVE_Ach_OnLoad()
	FengYun_PVE_Ach_UnifiedPosition = FengYun_PVE_Ach_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Ach_OnLoad()

-- 界面默认位置
function FengYun_PVE_Ach_UnifiedPos()
	if (FengYun_PVE_Ach_UnifiedPosition ~= nil) then
		FengYun_PVE_Ach_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Ach_UnifiedPosition)
	end
end -- end func FengYun_PVE_Ach_UnifiedPos()

function FengYun_PVE_Ach_Show()
	FengYun_PVE_Ach_LastAwardTime = 0
    this:Show()
end -- end func FengYun_PVE_Ach_Show()

function FengYun_PVE_Ach_Hide()
    this:Hide()
end -- end func FengYun_PVE_Ach_Hide()

--*************************************************************************************************
--
--*************************************************************************************************

-- 关闭按钮点击事件
function FengYun_PVE_Ach_OnHiden()
	FengYun_PVE_Ach_Hide()
end -- end func FengYun_PVE_Ach_OnHiden()

-- 领取按钮点击事件
function FengYun_PVE_Ach_ListItem_BtnClicked(achId)
	if (achId <= 0) then
		return
	end

	-- 操作CD
	local curTime = os.time()
	if (curTime <= FengYun_PVE_Ach_LastAwardTime) then
		return
	end
	FengYun_PVE_Ach_LastAwardTime = curTime

	local isInAct, actStage = FengYun_PVE_GetActStage()
	if (isInAct < 0) then
		-- 不在活动时间
		PushDebugMessage("#{FYPVE_260108_16}")
		return
	end

	local curLevel = Player:GetLevel()
	if (curLevel < FengYun_PVE_Ach_LevelLimit) then
		-- 等级不够
		PushDebugMessage("#{FYPVE_260108_17}")
		return
	end

	local achId, achType, achState, achParam = FYPVE:GetAchievementDataByIndex(achId-1)
	if (achState <= FengYun_PVE_Ach_State.null) then
		-- 未达成此成就
		PushDebugMessage("#{FYPVE_260108_30}")
		return
	end
	if (achState >= FengYun_PVE_Ach_State.award) then
		-- 已领奖
		PushDebugMessage("#{FYPVE_260108_29}")
		return
	end

	-- if (FengYun_PVE_Ach_AchCtrl ~= nil and FengYun_PVE_Ach_AchCtrl[achId] ~= nil) then
	-- 	FengYun_PVE_Ach_AchCtrl[achId].btn:Hide()
	-- 	FengYun_PVE_Ach_AchCtrl[achId].tip:Hide()
	-- 	FengYun_PVE_Ach_AchCtrl[achId].finish:Hide()
	-- 	FengYun_PVE_Ach_AchCtrl[achId].mark:Show()
	-- end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CCallBack_AchievementAward")
		Set_XSCRIPT_ScriptID(FengYun_PVE_Ach_SvrScriptId)
		Set_XSCRIPT_Parameter(0, achId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func FengYun_PVE_Ach_ListItem_BtnClicked()

--*************************************************************************************************
--
--*************************************************************************************************

-- 成就信息
function FengYun_PVE_Ach_UpdateAchInfo()
	FengYun_PVE_Ach_AchCtrl = {}

	FengYun_PVE_Ach_List:Clear()
	local achNum = FYPVE:GetTableAchievementNum()
	if (achNum > 0) then
		for i=1, achNum, 1 do
			local achId, achType, achParam1, achParam2, achShowId, achItemNum, achDesc = FYPVE:GetTableAchievementData(i)
			if (achId ~= nil) then
				local bar = FengYun_PVE_Ach_List:AddChild("FengYun_PVE_Ach_ListItem")
				if (bar ~= nil) then
					FengYun_PVE_Ach_AchCtrl[i] = {}
					FengYun_PVE_Ach_AchCtrl[i].achid = achId
					FengYun_PVE_Ach_AchCtrl[i].txt = bar:GetSubItem("FengYun_PVE_Ach_ListItem_Text")
					FengYun_PVE_Ach_AchCtrl[i].icon = bar:GetSubItem("FengYun_PVE_Ach_ListItem_Icon")
					FengYun_PVE_Ach_AchCtrl[i].btn = bar:GetSubItem("FengYun_PVE_Ach_ListItem_Btn")
					FengYun_PVE_Ach_AchCtrl[i].tip = bar:GetSubItem("FengYun_PVE_Ach_ListItem_BtnTips")
					FengYun_PVE_Ach_AchCtrl[i].mark = bar:GetSubItem("FengYun_PVE_Ach_ListItem_GetMark")
					FengYun_PVE_Ach_AchCtrl[i].finish = bar:GetSubItem("FengYun_PVE_Ach_ListItem_UnFinishedMark")

					local curAchId, curAchType, curAchState, curAchParam = FYPVE:GetAchievementDataByIndex(achId-1)

					-- 成就进度
					local achProcess = ""
					if (achType == FengYun_PVE_Ach_AchType.totalpoint) then
						-- 总物资点成就
						achProcess = ScriptGlobal_Format("#{FYPVE_260108_164}", curAchParam, achParam1)
					else
						achProcess = ScriptGlobal_Format("#{FYPVE_260108_164}", curAchParam, achParam2)
					end

					-- 成就描述
					bar:GetSubItem("FengYun_PVE_Ach_ListItem_Text"):SetText(achDesc .. achProcess)

					-- 成就奖励
					local theAction = DataPool:CreateActionItemForShow(achShowId, achItemNum)
					if (theAction ~= nil and theAction:GetID() ~= 0) then
						bar:GetSubItem("FengYun_PVE_Ach_ListItem_Icon"):SetActionItem(theAction:GetID())
					end
					
					if (curAchId ~= nil and curAchId > 0) then
						if (curAchState <= FengYun_PVE_Ach_State.null) then
							-- 未达成
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_Btn"):Hide()			-- 领取按钮
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_BtnTips"):Hide()		-- 小红点
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_GetMark"):Hide()		-- 已领取标识
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_UnFinishedMark"):Show()
						elseif (curAchState == FengYun_PVE_Ach_State.achieved) then
							-- 已达成 未领奖
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_Btn"):Enable()			-- 领取按钮
							-- 领取按钮事件
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_Btn"):SetEvent("MouseLClick", string.format("FengYun_PVE_Ach_ListItem_BtnClicked(%d)", i))
							
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_BtnTips"):Show()		-- 小红点
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_GetMark"):Hide()		-- 已领取标识
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_UnFinishedMark"):Hide()
						else
							-- 已达成 已领奖
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_Btn"):Hide()			-- 领取按钮
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_BtnTips"):Hide()		-- 小红点
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_GetMark"):Show()		-- 已领取标识
							bar:GetSubItem("FengYun_PVE_Ach_ListItem_UnFinishedMark"):Hide()
						end
					else
						-- 这里说明该成就未达成
						bar:GetSubItem("FengYun_PVE_Ach_ListItem_Btn"):Hide()				-- 领取按钮
						bar:GetSubItem("FengYun_PVE_Ach_ListItem_BtnTips"):Hide()			-- 小红点
						bar:GetSubItem("FengYun_PVE_Ach_ListItem_GetMark"):Hide()			-- 已领取标识
						bar:GetSubItem("FengYun_PVE_Ach_ListItem_UnFinishedMark"):Show()
					end
				end
			end
		end -- end for
	end
end -- end func FengYun_PVE_Ach_UpdateAchInfo()

function FengYun_PVE_Ach_UpdateAchState(achId)
	if (achId == nil or achId <= 0) then
		return
	end
	if (FengYun_PVE_Ach_AchCtrl == nil) then
		return
	end

	for  i=1, table.getn(FengYun_PVE_Ach_AchCtrl), 1 do
		local ctrlInfo = FengYun_PVE_Ach_AchCtrl[i]
		if (ctrlInfo ~= nil and ctrlInfo.achid == achId) then
			local curAchId, curAchType, curAchState, curAchParam = FYPVE:GetAchievementDataByIndex(achId-1)
			if (curAchState <= FengYun_PVE_Ach_State.null) then
				-- 未达成
				ctrlInfo.btn:Hide()			-- 领取按钮
				ctrlInfo.tip:Hide()			-- 小红点
				ctrlInfo.mark:Hide()		-- 领取标识
				ctrlInfo.finish:Show()
			elseif (curAchState == FengYun_PVE_Ach_State.achieved) then
				-- 已达成 未领奖
				ctrlInfo.btn:Show()			-- 领取按钮
				ctrlInfo.tip:Show()			-- 小红点
				ctrlInfo.mark:Hide()		-- 领取标识
				ctrlInfo.finish:Hide()
			else
				-- 已达成 已领奖
				ctrlInfo.btn:Hide()			-- 领取按钮
				ctrlInfo.tip:Hide()			-- 小红点
				ctrlInfo.mark:Show()		-- 领取标识
				ctrlInfo.finish:Hide()
			end

			break
		end
	end -- end for
end -- end func FengYun_PVE_Ach_UpdateAchState()