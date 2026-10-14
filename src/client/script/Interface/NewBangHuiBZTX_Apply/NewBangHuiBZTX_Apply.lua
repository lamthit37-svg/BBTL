-- 凤鸣城战替换玩法（限制人数玩法）助战申请列表
local NewBangHuiBZTX_Apply_IsDebug = 0
-- 是否开启轮换玩法（玩法模式）
local NewBangHuiBZTX_Apply_TCWLServerOpenFlag = 0
local NewBangHuiBZTX_Apply_TCWLOpenWeekFlag = 0
-- 助战申请列表初始化标记
local NewBangHuiBZTX_Apply_ApplyPlayerInitFlag = 0
-- 人数
local NewBangHuiBZTX_Apply_GuildMemberNum = 0
local NewBangHuiBZTX_Apply_AssistPlayerNum = 0
local NewBangHuiBZTX_Apply_AssistApplyNum = 0
local NewBangHuiBZTX_Apply_TotalPlayerNum = 0
-- 最大参战人数（本帮成员+助战玩家）
local NewBangHuiBZTX_Apply_MaxPlayerCount = 60
-- 当前周数
local NewBangHuiBZTX_Apply_CurWeekCount = 0
-- 显示的玩家数量
local NewBangHuiBZTX_Apply_ListItemCount = 0
-- 当前选中的条目索引
local NewBangHuiBZTX_Apply_CurSelect = -1
-- 上一次操作时间
local NewBangHuiBZTX_Apply_LastOpTime = 0
local NewBangHuiBZTX_Apply_LastAssistOpTime = 0
-- 操作CD（秒）
local NewBangHuiBZTX_Apply_OpCDTime = 6
local NewBangHuiBZTX_Apply_RemoveAssistCDTime = 1
-- 数据改变标记
local NewBangHuiBZTX_Apply_DataChangedFlag = 0
-- 保存UI默认位置
local NewBangHuiBZTX_Apply_UnifiedPosition = nil

-- 助战操作时间
local NewBangHuiBZTX_Apply_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHuiBZTX_Apply_AssistOpTime
-- 门派
local NewBangHuiBZTX_Apply_MenPaiNameList =
{
	[0] = "#{XQ_MP_1}",    		--少林
	[1] = "#{XQ_MP_2}",    		--明教
	[2] = "#{XQ_MP_3}",    		--丐帮
	[3] = "#{XQ_MP_4}",    		--武当
	[4] = "#{XQ_MP_5}",    		--峨眉
	[5] = "#{XQ_MP_6}",    		--星宿
	[6] = "#{XQ_MP_7}",    		--天龙
	[7] = "#{XQ_MP_8}",    		--天山
	[8] = "#{XQ_MP_9}",    		--逍遥
	[9] = "#{GCQH_240429_141}", --无门派
	[10] = "#{XQ_MP_10}",		--慕容
	[11] = "#{XQ_MP_13}",  		--唐门
	[12] = "#{XQ_MP_14}",  		--鬼谷
    [13] = "#{XQ_MP_15}",  		--桃花岛
	[14] = "#{XQ_MP_16}", 		--绝情谷
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",	-- 恶人谷
} -- end NewBangHuiBZTX_Apply_MenPaiNameList



function NewBangHuiBZTX_Apply_PreLoad()
	-- this:RegisterEvent("GUILD_ASSISTAPPLYINFO_BZTX")
	-- this:RegisterEvent("GUILD_CLOSEASSISTAPPLY_BZTX")
	-- this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	-- this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func NewBangHuiBZTX_Apply_PreLoad()

function NewBangHuiBZTX_Apply_OnLoad()
	NewBangHuiBZTX_Apply_UnifiedPosition = NewBangHuiBZTX_Apply_FrameBK:GetProperty("UnifiedPosition")
end -- end func NewBangHuiBZTX_Apply_OnLoad()

function NewBangHuiBZTX_Apply_OnEvent(event)
	-- if event == "GUILD_ASSISTAPPLYINFO_BZTX" then
	-- 	NewBangHuiBZTX_Apply_ApplyPlayerInitFlag = 0

	-- 	NewBangHuiBZTX_Apply_TCWLServerOpenFlag = tonumber(arg0)
    --     NewBangHuiBZTX_Apply_TCWLOpenWeekFlag = tonumber(arg1)
	-- 	NewBangHuiBZTX_Apply_CurWeekCount = tonumber(arg2)

	-- 	NewBangHuiBZTX_Apply_UpdateApplyList(-1, 1)
		
	-- 	local assistApplyNum = TCWL:GetAssistApplyNum()
	-- 	if (assistApplyNum <= 0) then
	-- 		PushDebugMessage("#{GCQH_240429_205}")

	-- 		DataPool:TCWLSetAssistApplyNum(assistApplyNum)
			
	-- 		NewBangHuiBZTX_Apply_Hide()
	-- 	else
	-- 		NewBangHuiBZTX_Apply_Show()
	-- 	end
	-- elseif event == "GUILD_CLOSEASSISTAPPLY_BZTX" then
	-- 	NewBangHuiBZTX_Apply_Hide()
	-- elseif event == "VIEW_RESOLUTION_CHANGED" then
	-- 	NewBangHuiBZTX_Apply_On_ResetPos()
	-- elseif event == "ADJEST_UI_POS" then
	-- 	NewBangHuiBZTX_Apply_On_ResetPos()
	-- elseif event == "HIDE_ON_SCENE_TRANSED" then
	-- 	NewBangHuiBZTX_Apply_Hide()
	-- end
end -- end func NewBangHuiBZTX_Apply_OnEvent()

function NewBangHuiBZTX_Apply_On_ResetPos()
	NewBangHuiBZTX_Apply_FrameBK:SetProperty("UnifiedPosition", NewBangHuiBZTX_Apply_UnifiedPosition)
end -- end func NewBangHuiBZTX_Apply_On_ResetPos()

function NewBangHuiBZTX_Apply_Show()
    this:Show()
end -- end func NewBangHuiBZTX_Apply_Show()

function NewBangHuiBZTX_Apply_Hide()
	NewBangHuiBZTX_Apply_DataChangedFlag = 0

	-- 更新小红点
	if (DataPool:GetProposerCount() <= 0) then
		PushEvent("UPDATE_GUILD_APPLY", "hide")
	end
	PushEvent("TCITYWARLIMIT_UPDATEREDPOINTTIPS")

    this:Hide()
end -- end func NewBangHuiBZTX_Apply_Hide()

--*****************************************************************************
-- 关闭按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Apply_CloseClicked()
	if (NewBangHuiBZTX_Apply_DataChangedFlag > 0) then
		-- 关闭这个UI的时候重新刷新一下霸者天下的UI
		PushEvent("TCITYWARLIMIT_OPENCANDIDATE")
	end

	NewBangHuiBZTX_Apply_Hide()
end -- end func NewBangHuiBZTX_Apply_CloseClicked()

--*****************************************************************************
-- 刷新按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Apply_ReFresh_Clicked()
	if (NewBangHuiBZTX_Apply_Check_OpCD() <= 0) then
        -- 操作频繁 稍微再试
        PushDebugMessage("#{GCQH_240429_142}")
        return
	end
	-- 重置CD时间
    NewBangHuiBZTX_Apply_LastOpTime = DataPool:GetCurrentServerTime()
	
	NewBangHuiBZTX_Apply_ApplyPlayerInitFlag = 0
	NewBangHuiBZTX_Apply_List:RemoveAllItem()
	NewBangHuiBZTX_Apply_ListItemCount = 0
	NewBangHuiBZTX_Apply_CurSelect = -1

	-- 重新请求助战申请列表
    TCWL:AskAssistApplyInfo()
end -- end func NewBangHuiBZTX_Apply_ReFresh_Clicked()

--*****************************************************************************
-- 同意按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Apply_OK_Clicked()
	if (NewBangHuiBZTX_Apply_ApplyPlayerInitFlag <= 0) then
		return
	end

	if (NewBangHuiBZTX_Apply_Check_AssistOpCD() <= 0) then
        -- 操作频繁 稍微再试
        PushDebugMessage("#{GCQH_240429_142}")
        return
	end
	-- 重置CD时间
    NewBangHuiBZTX_Apply_LastAssistOpTime = DataPool:GetCurrentServerTime()

	if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_78}")
        return
	end
	
	-- 是否助战报名操作时间
	local isInTime = NewBangHuiBZTX_Apply_Check_AssistEnrollTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_215}")
        return
	end
	
	-- 是否选中了一个玩家
	if (NewBangHuiBZTX_Apply_CurSelect < 0) then
		PushDebugMessage("#{GCQH_240429_216}")
        return
	end

	-- 是否还有助战名额
	if (NewBangHuiBZTX_Apply_TotalPlayerNum >= NewBangHuiBZTX_Apply_MaxPlayerCount) then
		PushDebugMessage("#{GCQH_240429_285}")
        return
	end

	-- 同意申请
	local ret = TCWL:AgreeAssistApply(NewBangHuiBZTX_Apply_CurSelect)
	if (ret > 0) then
		NewBangHuiBZTX_Apply_DataChangedFlag = 1
		NewBangHuiBZTX_Apply_TotalPlayerNum = NewBangHuiBZTX_Apply_TotalPlayerNum + 1

		-- 这里需要重新刷新一个申请列表 因为上面的操作会将操作的玩家从列表中删除
		NewBangHuiBZTX_Apply_ListItemCount = NewBangHuiBZTX_Apply_ListItemCount - 1
		if (NewBangHuiBZTX_Apply_ListItemCount > 0) then
			NewBangHuiBZTX_Apply_ListItemCount = 0
		end
		if (NewBangHuiBZTX_Apply_CurSelect >= NewBangHuiBZTX_Apply_ListItemCount) then
			NewBangHuiBZTX_Apply_CurSelect = NewBangHuiBZTX_Apply_ListItemCount - 1
		end
		NewBangHuiBZTX_Apply_UpdateApplyList(NewBangHuiBZTX_Apply_CurSelect, 0)

		-- 三城战场人数展示
		local numMsg = ScriptGlobal_Format("#{GCQH_240429_211}", NewBangHuiBZTX_Apply_TotalPlayerNum)
		NewBangHuiBZTX_Apply_ThreeCityNum:SetText(numMsg)
		-- 申请人数展示
		numMsg = ScriptGlobal_Format("#{GCQH_240429_212}", NewBangHuiBZTX_Apply_AssistApplyNum)
		NewBangHuiBZTX_Apply_ApplyNum:SetText(numMsg)
	end
end -- end func NewBangHuiBZTX_Apply_OK_Clicked()

--*****************************************************************************
-- 拒绝按钮事件
--*****************************************************************************
function NewBangHuiBZTX_Apply_NO_Clicked()
	if (NewBangHuiBZTX_Apply_ApplyPlayerInitFlag <= 0) then
		return
	end

	if (NewBangHuiBZTX_Apply_Check_AssistOpCD() <= 0) then
        -- 操作频繁 稍微再试
        PushDebugMessage("#{GCQH_240429_142}")
        return
	end
	-- 重置CD时间
    NewBangHuiBZTX_Apply_LastAssistOpTime = DataPool:GetCurrentServerTime()

	if (Player:GetData("TCWLSvrOpenFlag") < 0) then
        PushDebugMessage("#{GCQH_240429_154}")
        return
    end

    -- 是否帮主或副帮主
    local isChiefOrAss = Guild:IsChieforAss()
    if (isChiefOrAss ~= 1) then
        PushDebugMessage("#{GCQH_240429_78}")
        return
	end
	
	-- 是否助战报名操作时间
	local isInTime = NewBangHuiBZTX_Apply_Check_AssistEnrollTime()
    if (isInTime <= 0) then
        PushDebugMessage("#{GCQH_240429_215}")
        return
	end
	
	-- 是否选中了一个玩家
	if (NewBangHuiBZTX_Apply_CurSelect < 0) then
		PushDebugMessage("#{GCQH_240429_216}")
        return
	end

	-- 拒绝申请
	local ret = TCWL:RemoveAssistApply(NewBangHuiBZTX_Apply_CurSelect)
	if (ret > 0) then
		NewBangHuiBZTX_Apply_DataChangedFlag = 1

		-- 这里需要重新刷新一个申请列表 因为上面的操作会将操作的玩家从列表中删除
		NewBangHuiBZTX_Apply_UpdateApplyList(NewBangHuiBZTX_Apply_CurSelect, 1)
	end
end -- end func NewBangHuiBZTX_Apply_NO_Clicked()

--*****************************************************************************
-- 助战列表选择事件
--*****************************************************************************
function NewBangHuiBZTX_Apply_ListSelectChanged()
	NewBangHuiBZTX_Apply_CurSelect = NewBangHuiBZTX_Apply_List:GetSelectItem()
end -- end func NewBangHuiBZTX_Apply_ListSelectChanged()

--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************
--*************************************************************************************************

--*****************************************************************************
-- 操作CD检查
--*****************************************************************************
function NewBangHuiBZTX_Apply_Check_OpCD()
    if (NewBangHuiBZTX_Apply_IsDebug > 0) then
        return 1
    end

    local curTime = DataPool:GetCurrentServerTime()
    local diffTime = curTime - NewBangHuiBZTX_Apply_LastOpTime
    if (NewBangHuiBZTX_Apply_OpCDTime > 0) then
        if (diffTime >= 0 and diffTime < NewBangHuiBZTX_Apply_OpCDTime) then
            return -1
        end
    end

    return 1
end -- end func NewBangHuiBZTX_Apply_Check_OpCD()

function NewBangHuiBZTX_Apply_Check_AssistOpCD()
    if (NewBangHuiBZTX_Apply_IsDebug > 0) then
        return 1
    end

    local curTime = DataPool:GetCurrentServerTime()
    local diffTime = curTime - NewBangHuiBZTX_Apply_LastAssistOpTime
    if (NewBangHuiBZTX_Apply_RemoveAssistCDTime > 0) then
        if (diffTime >= 0 and diffTime < NewBangHuiBZTX_Apply_RemoveAssistCDTime) then
            return -1
        end
    end

    return 1
end -- end func NewBangHuiBZTX_Apply_Check_AssistOpCD()

--*****************************************************************************
-- 是否在助战申请时间内
--*****************************************************************************
function NewBangHuiBZTX_Apply_Check_AssistEnrollTime()
    if (NewBangHuiBZTX_Apply_IsDebug > 0) then
        return 1
    end

	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHuiBZTX_Apply_AssistOpTime[1].weekday
	local beginTime = NewBangHuiBZTX_Apply_AssistOpTime[1].begintime
	local endDay = NewBangHuiBZTX_Apply_AssistOpTime[2].weekday
	local endTime = NewBangHuiBZTX_Apply_AssistOpTime[2].endtime

	if (curWeekDay >= beginDay and curWeekDay <= endDay) then
		local curMinTime = DataPool:GetServerMinuteTime()
		if (curWeekDay == beginDay) then
			if (curMinTime >= beginTime) then
				return 1
			else
				return -1
			end
		elseif (curWeekDay == endDay) then
			if (curMinTime < endTime) then
				return 1
			else
				return -1
			end
		else
			return 1
		end
	end

    return -1
end -- end func NewBangHuiBZTX_Apply_Check_AssistEnrollTime()

--*****************************************************************************
-- 刷新助战申请列表
--*****************************************************************************
function NewBangHuiBZTX_Apply_UpdateApplyList(selectedIdx, updateNumTips)
	NewBangHuiBZTX_Apply_ApplyPlayerInitFlag = 1

	if (updateNumTips == nil or updateNumTips > 0) then
		NewBangHuiBZTX_Apply_GuildMemberNum = 0
		NewBangHuiBZTX_Apply_AssistPlayerNum = 0
		NewBangHuiBZTX_Apply_AssistApplyNum = 0
		NewBangHuiBZTX_Apply_TotalPlayerNum = 0
	end

	NewBangHuiBZTX_Apply_List:RemoveAllItem()
	NewBangHuiBZTX_Apply_ListItemCount = 0
	NewBangHuiBZTX_Apply_CurSelect = -1
	-- 申请玩家列表
	local listIdx = 0
	local assistApplyNum = TCWL:GetAssistApplyNum()
	if (assistApplyNum > 0) then
		for i=1, assistApplyNum, 1 do
			local assistIdx = i - 1
			local playerName = TCWL:GetAssistApplyInfo(assistIdx, "playername")
			local guildName = TCWL:GetAssistApplyInfo(assistIdx, "guildname")
			local playerLevel = TCWL:GetAssistApplyInfo(assistIdx, "level")
			local playerMenPai = TCWL:GetAssistApplyInfo(assistIdx, "menpai")
			local playerEquipScore = TCWL:GetAssistApplyInfo(assistIdx, "equipscore")

			local color = "#cfff263"
			NewBangHuiBZTX_Apply_List:AddNewItem(color .. playerName, 0, listIdx)
			NewBangHuiBZTX_Apply_List:AddNewItem(color .. guildName, 1, listIdx)
			NewBangHuiBZTX_Apply_List:AddNewItem(color .. tostring(playerLevel), 2, listIdx)
			NewBangHuiBZTX_Apply_List:AddNewItem(color .. NewBangHuiBZTX_Apply_MenPaiNameList[playerMenPai], 3, listIdx)
			NewBangHuiBZTX_Apply_List:AddNewItem(color .. tostring(playerEquipScore), 4, listIdx)

			listIdx = listIdx + 1
		end -- end for
	end
	NewBangHuiBZTX_Apply_ListItemCount = listIdx

	if (NewBangHuiBZTX_Apply_ListItemCount > 0) then
		if (selectedIdx ~= nil and selectedIdx >= 0) then
			if (selectedIdx >= NewBangHuiBZTX_Apply_ListItemCount) then
				selectedIdx = NewBangHuiBZTX_Apply_ListItemCount - 1
			end
			if (selectedIdx >= 0) then
				NewBangHuiBZTX_Apply_List:SetSelectItem(selectedIdx)
				NewBangHuiBZTX_Apply_CurSelect = selectedIdx
			end
		end
	end

	DataPool:TCWLSetAssistApplyNum(assistApplyNum)
	if (assistApplyNum <= 0) then
		--PushDebugMessage("#{GCQH_240429_205}")
		
		if (DataPool:GetProposerCount() <= 0) then
			PushEvent("UPDATE_GUILD_APPLY", "hide")
		end
	else
		PushEvent("UPDATE_GUILD_APPLY", "show")
	end
	-- 更新小红点
	PushEvent("TCITYWARLIMIT_UPDATEREDPOINTTIPS")
	NewBangHuiBZTX_Apply_AssistApplyNum = assistApplyNum

	if (updateNumTips == nil or updateNumTips > 0) then
		-- 三城战场人数
		local NewBangHuiBZTX_Apply_GuildMemberNum, _ = Guild:GetTCWLAssignPlayerNumEx()
		local NewBangHuiBZTX_Apply_AssistPlayerNum, _ = TCWL:GetAssistPlayerNum()
		NewBangHuiBZTX_Apply_TotalPlayerNum = NewBangHuiBZTX_Apply_GuildMemberNum + NewBangHuiBZTX_Apply_AssistPlayerNum
		local numMsg = ScriptGlobal_Format("#{GCQH_240429_211}", NewBangHuiBZTX_Apply_TotalPlayerNum)
		NewBangHuiBZTX_Apply_ThreeCityNum:SetText(numMsg)

		-- 申请人数
		numMsg = ScriptGlobal_Format("#{GCQH_240429_212}", NewBangHuiBZTX_Apply_AssistApplyNum)
		NewBangHuiBZTX_Apply_ApplyNum:SetText(numMsg)
	end
end -- end func NewBangHuiBZTX_Apply_UpdateApplyList()