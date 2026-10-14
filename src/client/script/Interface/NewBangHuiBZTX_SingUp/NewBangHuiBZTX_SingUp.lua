-- 凤鸣城战替换玩法（限制人数玩法）报名帮会列表UI
local NewBangHuiBZTX_SingUp_IsDebug = 0
-- 报名状态
local NewBangHuiBZTX_SingUp_EnrollState =
{
	null = -1,
	outtime = 0,			-- 不在报名时间（重组比赛日结束 下一次报名开始时间还未到）
	finished = 1,			-- 报名结束（报名时间结束 比赛重组日还未结束）
	intime = 2,				-- 报名时间内
} -- end NewBangHuiBZTX_SingUp_EnrollState
-- 助战申请操作时间
-- 助战操作时间
local NewBangHuiBZTX_SingUp_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHuiBZTX_SingUp_AssistOpTime
local NewBangHuiBZTX_SingUp_AssistEnrollBeginDay = 0
local NewBangHuiBZTX_SingUp_AssistEnrollBeginTime = 0
local NewBangHuiBZTX_SingUp_AssistEnrollEndDay = 0
local NewBangHuiBZTX_SingUp_AssistEnrollEndTime = 0
-- 操作CD（秒）
local NewBangHuiBZTX_SingUp_OpCDTime = 3
local NewBangHuiBZTX_SingUp_LastOpTime = 0
-- 当前选中的帮会
local NewBangHuiBZTX_SingUp_SelectIndex = -1
local NewBangHuiBZTX_SingUp_SelectGuildId = -1
-- 帮会选择按钮列表
local NewBangHuiBZTX_SingUp_SelectBtnList = {}
local NewBangHuiBZTX_SingUp_SelectBtnNum = 0
-- 助战等级
local NewBangHuiBZTX_SingUp_MinLevel = 85
-- 保存UI默认位置
local NewBangHuiBZTX_SingUp_UnifiedPosition = nil



function NewBangHuiBZTX_SingUp_PreLoad()
	-- this:RegisterEvent("TCITYWARLIMIT_GUILDLIST")
	-- this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	-- this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func NewBangHuiBZTX_SingUp_PreLoad()

function NewBangHuiBZTX_SingUp_OnLoad()
	NewBangHuiBZTX_SingUp_UnifiedPosition = NewBangHuiBZTX_SingUp_Frame:GetProperty("UnifiedPosition")
end -- end func NewBangHuiBZTX_SingUp_OnLoad()

function NewBangHuiBZTX_SingUp_OnEvent(event)
	-- if event == "TCITYWARLIMIT_GUILDLIST" then
	-- 	NewBangHuiBZTX_SingUp_Update(arg0)
	-- 	NewBangHuiBZTX_SingUp_Show()
	-- elseif event == "VIEW_RESOLUTION_CHANGED" then
	-- 	NewBangHuiBZTX_SingUp_On_ResetPos()
	-- elseif event == "ADJEST_UI_POS" then
	-- 	NewBangHuiBZTX_SingUp_On_ResetPos()
	-- elseif event == "HIDE_ON_SCENE_TRANSED" then
	-- 	NewBangHuiBZTX_SingUp_Hide()
	-- end
end -- end func NewBangHuiBZTX_SingUp_OnEvent()

function NewBangHuiBZTX_SingUp_On_ResetPos()
	NewBangHuiBZTX_SingUp_Frame:SetProperty("UnifiedPosition", NewBangHuiBZTX_SingUp_UnifiedPosition)
end -- end func NewBangHuiBZTX_SingUp_On_ResetPos()

function NewBangHuiBZTX_SingUp_Show()
    this:Show()
end -- end func NewBangHuiBZTX_SingUp_Show()

function NewBangHuiBZTX_SingUp_Hide()
    this:Hide()
end -- end func NewBangHuiBZTX_SingUp_Hide()

-- 操作CD检查
function NewBangHuiBZTX_SingUp_Check_OpCD()
	if (NewBangHuiBZTX_SingUp_IsDebug > 0) then
		return 1
	end

    local curTime = DataPool:GetCurrentServerTime()
    local diffTime = curTime - NewBangHuiBZTX_SingUp_LastOpTime
    if (NewBangHuiBZTX_SingUp_OpCDTime > 0) then
        if (diffTime >= 0 and diffTime < NewBangHuiBZTX_SingUp_OpCDTime) then
            return -1
        end
    end

    return 1
end -- end func NewBangHuiBZTX_SingUp_Check_OpCD()

-- 重置操作CD
function NewBangHuiBZTX_SingUp_ResetOpCD()
	NewBangHuiBZTX_SingUp_LastOpTime = DataPool:GetCurrentServerTime()
end -- end func NewBangHuiBZTX_SingUp_ResetOpCD()

-- 是否在助战申请时间内
function NewBangHuiBZTX_SingUp_Check_AssistEnrollTime()
	if (NewBangHuiBZTX_SingUp_IsDebug > 0) then
		return 1
	end

	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end
	local beginDay = NewBangHuiBZTX_SingUp_AssistOpTime[1].weekday
	local beginTime = NewBangHuiBZTX_SingUp_AssistOpTime[1].begintime
	local endDay = NewBangHuiBZTX_SingUp_AssistOpTime[2].weekday
	local endTime = NewBangHuiBZTX_SingUp_AssistOpTime[2].endtime

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
end -- end func NewBangHuiBZTX_SingUp_Check_AssistEnrollTime()

-- 关闭按钮点击事件
function NewBangHuiBZTX_SingUp_CloseClicked()
    NewBangHuiBZTX_SingUp_Hide()
end -- end func NewBangHuiBZTX_SingUp_CloseClicked()

-- 帮会选择按钮点击事件
function NewBangHuiBZTX_SingUp_ListItem_SelectBtnClicked(btnIndex, guidlId)
	if (btnIndex == nil or guidlId == nil) then
		PushDebugMessage("#{GCQH_240429_169}")
		return
	end
	if (btnIndex < 0 or guidlId < 0) then
		PushDebugMessage("#{GCQH_240429_169}")
		return
	end

	NewBangHuiBZTX_SingUp_SelectIndex = btnIndex
	NewBangHuiBZTX_SingUp_SelectGuildId = guidlId

	if (NewBangHuiBZTX_SingUp_SelectBtnNum > 0) then
		for i=1, NewBangHuiBZTX_SingUp_SelectBtnNum, 1 do
			if (NewBangHuiBZTX_SingUp_SelectBtnList[i] ~= nil) then
				if (i == btnIndex) then
					NewBangHuiBZTX_SingUp_SelectBtnList[i]:SetCheck(1)
				else
					NewBangHuiBZTX_SingUp_SelectBtnList[i]:SetCheck(0)
				end
			end
		end -- end for
	end
end -- end func NewBangHuiBZTX_SingUp_ListItem_SelectBtnClicked()

-- 申请助战按钮点击事件
function NewBangHuiBZTX_SingUp_ApplyClicked()
	-- 操作CD
	if (NewBangHuiBZTX_SingUp_Check_OpCD() <= 0) then
		PushDebugMessage("#{GCQH_240429_142}")
        return
	end

	-- 是否申请时段内
	if (NewBangHuiBZTX_SingUp_Check_AssistEnrollTime() <= 0) then
		PushDebugMessage("#{GCQH_240429_173}")
        return
	end

	-- -- 玩家所在服务器是否开启轮换玩法
	-- if (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	PushDebugMessage("#{GCQH_240429_167}")
    --     return
	-- end

	-- 是否选中助战帮会
	if (NewBangHuiBZTX_SingUp_SelectGuildId < 0) then
		PushDebugMessage("#{GCQH_240429_169}")
		return
	end

	-- 等级
	if(Player:GetLevel() < NewBangHuiBZTX_SingUp_MinLevel) then
		PushDebugMessage("#{GCQH_240429_168}")
		return
	end

	-- 是否选中自己的帮会
	if (Player:GetData("GUILD") == NewBangHuiBZTX_SingUp_SelectGuildId) then
		PushDebugMessage("#{GCQH_240429_170}")
		return
	end

	-- 重置操作CD
	NewBangHuiBZTX_SingUp_ResetOpCD()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CCallBack_AssistEnroll")
		Set_XSCRIPT_ScriptID(998224)
		Set_XSCRIPT_Parameter(0, NewBangHuiBZTX_SingUp_SelectGuildId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func NewBangHuiBZTX_SingUp_ApplyClicked()

function NewBangHuiBZTX_SingUp_Update(arg)
	local enrollState = tonumber(arg)
	local msg = "null"
	if (enrollState == NewBangHuiBZTX_SingUp_EnrollState.outtime) then
		-- 不在报名时间
		msg = "#{GCQH_240429_29}"
	elseif (enrollState == NewBangHuiBZTX_SingUp_EnrollState.finished) then
		-- 已结算
		msg = "#{GCQH_240429_27}"
	elseif (enrollState == NewBangHuiBZTX_SingUp_EnrollState.intime) then
		-- 报名时间内
		msg = "#{GCQH_240429_28}"
	else
		-- 按说不应该这样 按不在报名时间算吧
		msg = "#{GCQH_240429_29}"
	end

	local tipMsg = ScriptGlobal_Format("#{GCQH_240429_26}", msg)
	NewBangHuiBZTX_SingUp_Info:SetText(tipMsg)

	NewBangHuiBZTX_SingUp_List:Clear()
	NewBangHuiBZTX_SingUp_SelectBtnList = {}
	NewBangHuiBZTX_SingUp_SelectBtnNum = 0
	NewBangHuiBZTX_SingUp_SelectIndex = -1
	NewBangHuiBZTX_SingUp_SelectGuildId = -1

	local count = 1
	local guildListSize = TCWL:GetGuildListSize()
	for i=1, guildListSize, 1 do
		local idx, guildId, guildLevel, guildScore, guildName = TCWL:GetGuildDataByIndex(i-1)
		if (guildId >= 0) then
			local bar = NewBangHuiBZTX_SingUp_List:AddChild("NewBangHuiBZTX_SingUp_ListItem")
			if (bar ~= nil) then
				local selectBtn = bar:GetSubItem("NewBangHuiBZTX_SingUp_ListItem_SelectBtn")
				if (selectBtn ~= nil) then
					NewBangHuiBZTX_SingUp_SelectBtnNum = NewBangHuiBZTX_SingUp_SelectBtnNum + 1
					NewBangHuiBZTX_SingUp_SelectBtnList[NewBangHuiBZTX_SingUp_SelectBtnNum] = selectBtn

					selectBtn:SetEvent("MouseLClick", string.format("NewBangHuiBZTX_SingUp_ListItem_SelectBtnClicked(%d, %d)", NewBangHuiBZTX_SingUp_SelectBtnNum, guildId))
					selectBtn:SetCheck(0)
				end

				bar:GetSubItem("NewBangHuiBZTX_SingUp_ListItem_Text1"):SetText(tostring(count))
				bar:GetSubItem("NewBangHuiBZTX_SingUp_ListItem_Text2"):SetText(guildName)
				bar:GetSubItem("NewBangHuiBZTX_SingUp_ListItem_Text3"):SetText(tostring(guildId))
				bar:GetSubItem("NewBangHuiBZTX_SingUp_ListItem_Text4"):SetText(tostring(guildLevel))
				bar:GetSubItem("NewBangHuiBZTX_SingUp_ListItem_Text5"):SetText(tostring(guildScore))

				count = count + 1
			end
		end
	end -- end for
end -- end func NewBangHuiBZTX_SingUp_Update()