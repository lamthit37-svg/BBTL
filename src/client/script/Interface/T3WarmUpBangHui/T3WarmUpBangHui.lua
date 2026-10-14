--帮会进度界面
-- !!!reloadscript =T3WarmUpBangHui
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition
local m_targetId = 0
local m_ObjCareID = 0

local m_firstLoginPoint = 0 --首次登陆红点
local m_lastWeekReceivePoint = 0 --上周领取奖励红点
local m_ActValueReceivePoint = 0 --领取奖励红点
local m_selfCurDayReceivePoint = 0 --个人当天奖励领取红点

local m_curWeekActValue = 0	--当周行动力
local m_lastWeekActValue = 0 --上周行动力
local m_curDaySelfActValue = 0	--当天个人行动力
local m_lastWeekReceiveFlag = 0  --
local m_curDay = 0

local m_startDay = 20201105
local m_endAddDay = 20201126
local m_endDay = 20201202

local m_everWeekTimeInfo = {
	[1] = {StartDay=20201105, EndDay=20201111, 
		Cur="#{BHHY_200907_107}", CurTips="#{BHHY_200907_34}", 
		Cur1="#{BHHY_200907_108}", CurTips1="#{BHHY_200907_34}", 
		Cur2="#{BHHY_200907_109}", CurTips2="#{BHHY_200907_34}"},
	[2] = {StartDay=20201112, EndDay=20201118, 
		Cur="#{BHHY_200907_110}", CurTips="#{BHHY_200907_34}", 
		Cur1="#{BHHY_200907_111}", CurTips1="#{BHHY_200907_34}", 
		Cur2="#{BHHY_200907_112}", CurTips2="#{BHHY_200907_34}"},
	[3] = {StartDay=20201119, EndDay=20201125, 
		Cur="#{BHHY_200907_113}", CurTips="#{BHHY_200907_34}", 
		Cur1="#{BHHY_200907_114}", CurTips1="#{BHHY_200907_34}", 
		Cur2="", CurTips2=""},
}

local m_guildEveryDayActValueMax = 900 --帮会每天行动力最大上限
local m_selfEveryWeekActValueMax = 140 --角色每周行动力最大上限
local m_EveryDayActValueMaxValue = 40 --角色每天行动力最大值


local m_lastWeekActValueNeedValue = 140 --领取上周奖励需要的值
local m_LastWeekActValueAwardItem = 39922888

--帮会行动力个人当天奖励
local m_GuildActValueSelfCurDayAward = 
{
	[1] = {MF=2899, NeedActValue=5, AwardItem=39922889, AwardNum=1, AwardItem1=39922895, AwardNum1=2, AwardItem2=0, AwardNum2=1},
	[2] = {MF=2900, NeedActValue=15, AwardItem=39922890, AwardNum=1, AwardItem1=39922896, AwardNum1=2, AwardItem2=0, AwardNum2=1},
	[3] = {MF=2901, NeedActValue=25, AwardItem=39922891, AwardNum=1, AwardItem1=39922897, AwardNum1=2, AwardItem2=39922898, AwardNum2=2},
}
--行动力领奖对应
local m_ActValueReceiveData = 
{
	[1] = {MF=2893, NeedActValue=800, AwardItem=39920162, AwardNum=20, AwardItem1=39920163, AwardNum1=30},
	[2] = {MF=2894, NeedActValue=2000, AwardItem=39920490, AwardNum=3, AwardItem1=39921051, AwardNum1=2},
	[3] = {MF=2895, NeedActValue=4500, AwardItem=39921415, AwardNum=1, AwardItem1=39921689, AwardNum1=1},
	[4] = {MF=2896, NeedActValue=7500, AwardItem=39921299, AwardNum=5, AwardItem1=39921303, AwardNum1=5},
	[5] = {MF=2897, NeedActValue=12000, AwardItem=39921549, AwardNum=1, AwardItem1=39921547, AwardNum1=1},
	[6] = {MF=2898, NeedActValue=17000, AwardItem=39922005, AwardNum=1, AwardItem1=0, AwardNum1=1},
}


local m_selfCurDayReceiveUI = {}

local m_ActValueReceiveUI = {}



--预加载函数，可以而且只能在这里注册脚本关心的事件
function T3WarmUpBangHui_PreLoad()
	this:RegisterEvent("GUILDACTVALUE_OP")
	this:RegisterEvent("GUILDACTVALUE_POINT")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function T3WarmUpBangHui_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= T3WarmUpBangHui_Frame:GetProperty("UnifiedXPosition")
	m_Frame_UnifiedYPosition	= T3WarmUpBangHui_Frame:GetProperty("UnifiedYPosition")

	m_selfCurDayReceiveUI[1] = {Btn=T3WarmUpBangHui_Info2Item7Btn, Text=T3WarmUpBangHui_Info2Item7Text, Point=T3WarmUpBangHui_Info2Item7Btn_Tips, 
			StateText=T3WarmUpBangHui_Info2Item7state, ItemAction=T3WarmUpBangHui_Info2Item7Icon, ItemAction1=T3WarmUpBangHui_Info2Item7Icon2, ItemAction2=nil}
	m_selfCurDayReceiveUI[2] = {Btn=T3WarmUpBangHui_Info2Item8Btn, Text=T3WarmUpBangHui_Info2Item8Text, Point=T3WarmUpBangHui_Info2Item8Btn_Tips, 
			StateText=T3WarmUpBangHui_Info2Item8state, ItemAction=T3WarmUpBangHui_Info2Item8Icon, ItemAction1=T3WarmUpBangHui_Info2Item8Icon2, ItemAction2=nil}
	m_selfCurDayReceiveUI[3] = {Btn=T3WarmUpBangHui_Info2Item9Btn, Text=T3WarmUpBangHui_Info2Item9Text, Point=T3WarmUpBangHui_Info2Item9Btn_Tips, 
			StateText=T3WarmUpBangHui_Info2Item9state, ItemAction=T3WarmUpBangHui_Info2Item9Icon, ItemAction1=T3WarmUpBangHui_Info2Item9Icon2, ItemAction2=T3WarmUpBangHui_Info2Item9Icon3}

	m_ActValueReceiveUI[1] = {Btn=T3WarmUpBangHui_Info2Item1Btn, Text=T3WarmUpBangHui_Info2Item1Text, Point=T3WarmUpBangHui_Info2Item1Btn_Tips, 
			ItemAction=T3WarmUpBangHuiList_Info2Item1Icon, ItemAction1=T3WarmUpBangHuiList_Info2Item1Icon2}
	m_ActValueReceiveUI[2] = {Btn=T3WarmUpBangHui_Info2Item2Btn, Text=T3WarmUpBangHui_Info2Item2Text, Point=T3WarmUpBangHui_Info2Item2Btn_Tips, 
			ItemAction=T3WarmUpBangHuiList_Info2Item2Icon, ItemAction1=T3WarmUpBangHuiList_Info2Item2Icon2}
	m_ActValueReceiveUI[3] = {Btn=T3WarmUpBangHui_Info2Item3Btn, Text=T3WarmUpBangHui_Info2Item3Text, Point=T3WarmUpBangHui_Info2Item3Btn_Tips, 
			ItemAction=T3WarmUpBangHuiList_Info2Item3Icon, ItemAction1=T3WarmUpBangHuiList_Info2Item3Icon2}
	m_ActValueReceiveUI[4] = {Btn=T3WarmUpBangHui_Info2Item4Btn, Text=T3WarmUpBangHui_Info2Item4Text, Point=T3WarmUpBangHui_Info2Item4Btn_Tips, 
			ItemAction=T3WarmUpBangHuiList_Info2Item4Icon, ItemAction1=T3WarmUpBangHuiList_Info2Item4Icon2}
	m_ActValueReceiveUI[5] = {Btn=T3WarmUpBangHui_Info2Item5Btn, Text=T3WarmUpBangHui_Info2Item5Text, Point=T3WarmUpBangHui_Info2Item5Btn_Tips, 
			ItemAction=T3WarmUpBangHuiList_Info2Item5Icon, ItemAction1=T3WarmUpBangHuiList_Info2Item5Icon2}
	m_ActValueReceiveUI[6] = {Btn=T3WarmUpBangHui_Info2Item6Btn, Text=T3WarmUpBangHui_Info2Item6Text, Point=T3WarmUpBangHui_Info2Item6Btn_Tips, 
			ItemAction=T3WarmUpBangHuiList_Info2Item6Icon, ItemAction1=nil}

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function T3WarmUpBangHui_ResetPos()
	T3WarmUpBangHui_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	T3WarmUpBangHui_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end
--响应事件的函数，当注册的事件发生时会调用的函数
function T3WarmUpBangHui_OnEvent(event)

	if event == "GUILDACTVALUE_OP" then
		local nType = tonumber(arg0)
		if nType == 1 then --打开帮会行动力进度界面
			if (this:IsVisible()) then
				T3WarmUpBangHui_Update()
				return
			end
			T3WarmUpBangHui_Show()
			T3WarmUpBangHui_Update()
		elseif nType == 2 then --打开帮会行动力排行界面
			T3WarmUpBangHui_Hide()
		elseif nType == 3 then --数据更新
			if (this:IsVisible()) then
				T3WarmUpBangHui_Update()
				return
			end
		end
	elseif event == "GUILDACTVALUE_POINT" then
		m_firstLoginPoint = tonumber(arg0)
		m_lastWeekReceivePoint = tonumber(arg1)
		m_ActValueReceivePoint = tonumber(arg2)
		m_selfCurDayReceivePoint = tonumber(arg3)
		m_curWeekActValue  = tonumber(arg4)	--当周行动力
		m_lastWeekActValue  = tonumber(arg5) --上周行动力
		m_curDaySelfActValue  = tonumber(arg6)	--当天个人行动力
		m_lastWeekReceiveFlag  = tonumber(arg7)  --
		m_curDay = tonumber(arg8)
		-- PushDebugMessage(m_firstLoginPoint.." "..m_lastWeekReceivePoint.." "..m_ActValueReceivePoint.." "..m_selfCurDayReceivePoint)
		if (this:IsVisible()) then
			m_firstLoginPoint = 0
			T3WarmUpBangHui_Update()
		end
		if m_firstLoginPoint == 1 or 
			m_lastWeekReceivePoint == 1 or
			m_ActValueReceivePoint == 1 or
			m_selfCurDayReceivePoint == 1 then
			Lua_RedPoint_SetActive("T3WarmUp_Guide_Action_Tips2", true)
		else
			Lua_RedPoint_SetActive("T3WarmUp_Guide_Action_Tips2", false)
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		T3WarmUpBangHui_Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		T3WarmUpBangHui_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		T3WarmUpBangHui_ResetPos()
	-- elseif event == "OBJECT_CARED_EVENT" then
	-- 	T3WarmUpBangHui_CareEvent(arg0,arg1,arg2)
	end

end
--显示UI
function T3WarmUpBangHui_Show()
	T3WarmUpBangHui_ClearData()
	this:Show()
end
--隐藏UI
function T3WarmUpBangHui_Hide()
	T3WarmUpBangHui_ClearData()
	this:Hide()
end

--清除数据
function T3WarmUpBangHui_ClearData()
end

function T3WarmUpBangHui_Update()
	-- local curWeekActValue = DataPool:GetPlayerMission_DataRound(2156)	--当周行动力
	-- local lastWeekActValue = DataPool:GetPlayerMission_DataRound(2157)	--上周行动力
	-- local curDaySelfActValue = DataPool:GetPlayerMission_DataRound(2175)	--当天个人行动力

	local totalGuildActValue = GuildActValueUI:LuaFnGetGetTotalGuildActValue()
	local todayGuildActValue = GuildActValueUI:LuaFnGetTodayGuildActValue()
	-- local lastWeekReceiveFlag = Pneuma:GetMF(2902)
	-- local rankReceiveFlag = Pneuma:GetMF(2902)
	local selfGuildID, selfclanID = DataPool:GetGuildClanID()
	-- local curDay = tonumber(DataPool:GetServerDayTime())

	for index = 1, table.getn(m_ActValueReceiveData) do
		if  nil ~= m_ActValueReceiveUI[index].ItemAction then
			if m_ActValueReceiveData[index].AwardNum > 0 then
				local theAction = DataPool:CreateActionItemForShow(m_ActValueReceiveData[index].AwardItem, m_ActValueReceiveData[index].AwardNum)
				if theAction:GetID() ~= 0 then
					m_ActValueReceiveUI[index].ItemAction:SetActionItem(theAction:GetID())
				else
					m_ActValueReceiveUI[index].ItemAction:SetActionItem(-1)
				end
			else
				m_ActValueReceiveUI[index].ItemAction:SetActionItem(-1)
			end
		end
		if nil ~= m_ActValueReceiveUI[index].ItemAction1 then
			if m_ActValueReceiveData[index].AwardNum1 > 0 then
				local theAction = DataPool:CreateActionItemForShow(m_ActValueReceiveData[index].AwardItem1, m_ActValueReceiveData[index].AwardNum1)
				if theAction:GetID() ~= 0 then
					m_ActValueReceiveUI[index].ItemAction1:SetActionItem(theAction:GetID())
				else
					m_ActValueReceiveUI[index].ItemAction1:SetActionItem(-1)
				end
			else
				m_ActValueReceiveUI[index].ItemAction1:SetActionItem(-1)
			end
		end
		if totalGuildActValue >= m_ActValueReceiveData[index].NeedActValue then
			m_ActValueReceiveUI[index].Btn:Show()
			m_ActValueReceiveUI[index].Text:Hide()
			if 1 ~= Pneuma:GetMF(m_ActValueReceiveData[index].MF) then
				-- m_ActValueReceiveUI[index].Btn:SetText("#{BHHY_200907_26}")
				m_ActValueReceiveUI[index].Btn:Enable()
				m_ActValueReceiveUI[index].Point:Show()
			else
				-- m_ActValueReceiveUI[index].Btn:SetText("#{BHHY_200907_27}")
				m_ActValueReceiveUI[index].Btn:Hide()
			end
		else
			m_ActValueReceiveUI[index].Btn:Hide()
			m_ActValueReceiveUI[index].Text:Show()
			m_ActValueReceiveUI[index].Text:SetText(ScriptGlobal_Format("#{BHHY_200907_24}", totalGuildActValue, m_ActValueReceiveData[index].NeedActValue))
		end
		if m_curDay > m_endAddDay then
			m_ActValueReceiveUI[index].Text:Hide()
		end
	end
	if m_curDay <= m_endAddDay then
		if selfGuildID < 0 then
			T3WarmUpBangHui_TodayGo:Hide()
			T3WarmUpBangHui_TodayGo_Text:Show()
			for index = 1, table.getn(m_ActValueReceiveData) do
				m_ActValueReceiveUI[index].Btn:Hide()
				m_ActValueReceiveUI[index].Text:Hide()
			end

		else
			T3WarmUpBangHui_TodayGo_Text:Hide()
			T3WarmUpBangHui_TodayGo:Show()
			if todayGuildActValue < m_guildEveryDayActValueMax then
				T3WarmUpBangHui_TodayGo:SetText(ScriptGlobal_Format("#{BHHY_200907_83}", totalGuildActValue, todayGuildActValue))
			else
				T3WarmUpBangHui_TodayGo:SetText(ScriptGlobal_Format("#{BHHY_200907_117}", totalGuildActValue))
			end
			T3WarmUpBangHui_TodayGo:SetToolTip(ScriptGlobal_Format("#{BHHY_200907_84}", m_guildEveryDayActValueMax))
		end
	else
		T3WarmUpBangHui_TodayGo_Text:Hide()
		T3WarmUpBangHui_TodayGo:Show()
		T3WarmUpBangHui_TodayGo:SetText("#{BHHY_200907_93}")
		T3WarmUpBangHui_TodayGo:SetToolTip("")
	end

	
	for index = 1, table.getn(m_GuildActValueSelfCurDayAward) do
		if nil ~= m_selfCurDayReceiveUI[index].ItemAction then
			if m_GuildActValueSelfCurDayAward[index].AwardItem > 0 then
				local theAction = DataPool:CreateActionItemForShow(m_GuildActValueSelfCurDayAward[index].AwardItem, m_GuildActValueSelfCurDayAward[index].AwardNum)
				if theAction:GetID() ~= 0 then
					m_selfCurDayReceiveUI[index].ItemAction:SetActionItem(theAction:GetID())
				else
					m_selfCurDayReceiveUI[index].ItemAction:SetActionItem(-1)
				end
			else
				m_selfCurDayReceiveUI[index].ItemAction:SetActionItem(-1)
			end
		end
		if nil ~= m_selfCurDayReceiveUI[index].ItemAction1 then
			if m_GuildActValueSelfCurDayAward[index].AwardItem1 > 0 then
				local theAction = DataPool:CreateActionItemForShow(m_GuildActValueSelfCurDayAward[index].AwardItem1, m_GuildActValueSelfCurDayAward[index].AwardNum1)
				if theAction:GetID() ~= 0 then
					m_selfCurDayReceiveUI[index].ItemAction1:SetActionItem(theAction:GetID())
				else
					m_selfCurDayReceiveUI[index].ItemAction1:SetActionItem(-1)
				end
			else
				m_selfCurDayReceiveUI[index].ItemAction1:SetActionItem(-1)
			end
		end
		if nil ~= m_selfCurDayReceiveUI[index].ItemAction2 then
			if m_GuildActValueSelfCurDayAward[index].AwardItem2 > 0 then
				local theAction = DataPool:CreateActionItemForShow(m_GuildActValueSelfCurDayAward[index].AwardItem2, m_GuildActValueSelfCurDayAward[index].AwardNum2)
				if theAction:GetID() ~= 0 then
					m_selfCurDayReceiveUI[index].ItemAction2:SetActionItem(theAction:GetID())
				else
					m_selfCurDayReceiveUI[index].ItemAction2:SetActionItem(-1)
				end
			else
				m_selfCurDayReceiveUI[index].ItemAction:SetActionItem(-1)
			end
		end

		if m_curDay >= m_startDay and m_curDay <= m_endAddDay then
			m_selfCurDayReceiveUI[index].StateText:Hide()
			m_selfCurDayReceiveUI[index].Btn:Show()
			if m_curDaySelfActValue >= m_GuildActValueSelfCurDayAward[index].NeedActValue then
				m_selfCurDayReceiveUI[index].Text:SetText(ScriptGlobal_Format("#{BHHY_200907_106}", m_curDaySelfActValue, m_GuildActValueSelfCurDayAward[index].NeedActValue))
				m_selfCurDayReceiveUI[index].Text:SetToolTip("#{BHHY_200907_30}")
				if 1 ~= Pneuma:GetMF(m_GuildActValueSelfCurDayAward[index].MF) then
					m_selfCurDayReceiveUI[index].Btn:Enable()
					m_selfCurDayReceiveUI[index].Point:Show()
				else
					m_selfCurDayReceiveUI[index].Btn:SetProperty("DisabledImage", "set:Spring24 image:Received")
					m_selfCurDayReceiveUI[index].Btn:Disable()
					m_selfCurDayReceiveUI[index].Point:Hide()
				end
			else
				m_selfCurDayReceiveUI[index].Text:SetText(ScriptGlobal_Format("#{BHHY_200907_24}", m_curDaySelfActValue, m_GuildActValueSelfCurDayAward[index].NeedActValue))
				m_selfCurDayReceiveUI[index].Text:SetToolTip("#{BHHY_200907_30}")
				m_selfCurDayReceiveUI[index].Btn:SetProperty("DisabledImage", "set:Spring24 image:NotReach")
				m_selfCurDayReceiveUI[index].Btn:Disable()
				m_selfCurDayReceiveUI[index].Point:Hide()
			end
		else
			m_selfCurDayReceiveUI[index].Text:SetText(ScriptGlobal_Format("#{BHHY_200907_24}", "-", m_GuildActValueSelfCurDayAward[index].NeedActValue))
			m_selfCurDayReceiveUI[index].Text:SetToolTip("")
			m_selfCurDayReceiveUI[index].Btn:Hide()
			m_selfCurDayReceiveUI[index].StateText:Show()
			m_selfCurDayReceiveUI[index].StateText:SetText("#{BHHY_200907_102}")
		end
	end

	local theAction = DataPool:CreateActionItemForShow(m_LastWeekActValueAwardItem, 1)
	if theAction:GetID() ~= 0 then
		T3WarmUpBangHuiList_Info_Nextweek:SetActionItem(theAction:GetID())
	else
		T3WarmUpBangHuiList_Info_Nextweek:SetActionItem(-1)
	end

	local isFind = 0
	for index = 1,  table.getn(m_everWeekTimeInfo) do
		if m_curDay >= m_everWeekTimeInfo[index].StartDay and m_curDay <= m_everWeekTimeInfo[index].EndDay then
			T3WarmUpBangHuiList_AwardBtn:Show()
			if m_curWeekActValue >= m_lastWeekActValueNeedValue then
				if 1 ~= m_lastWeekReceiveFlag then
					T3WarmUpBangHuiList_Info:SetText(ScriptGlobal_Format(m_everWeekTimeInfo[index].Cur1, m_curWeekActValue, m_lastWeekActValueNeedValue))
					T3WarmUpBangHuiList_Info:SetToolTip(m_everWeekTimeInfo[index].CurTips1)
					T3WarmUpBangHuiList_AwardBtn:Enable()
					T3WarmUpBangHuiList_AwardBtn_Tips:Show()
				else
					if m_everWeekTimeInfo[index].Cur2 ~= "" then
						T3WarmUpBangHuiList_Info:SetText(ScriptGlobal_Format(m_everWeekTimeInfo[index].Cur2, m_curWeekActValue, m_lastWeekActValueNeedValue))
						T3WarmUpBangHuiList_Info:SetToolTip(m_everWeekTimeInfo[index].CurTips2)
					else
						T3WarmUpBangHuiList_Info:SetText("")
						T3WarmUpBangHuiList_Info:SetToolTip("")
					end
					T3WarmUpBangHuiList_AwardBtn:SetProperty("DisabledImage", "set:Spring24 image:Received")
					T3WarmUpBangHuiList_AwardBtn:Disable()
					T3WarmUpBangHuiList_AwardBtn_Tips:Hide()
				end
			else
				T3WarmUpBangHuiList_Info:SetText(ScriptGlobal_Format(m_everWeekTimeInfo[index].Cur, m_curWeekActValue, m_lastWeekActValueNeedValue))
				T3WarmUpBangHuiList_Info:SetToolTip(m_everWeekTimeInfo[index].CurTips)
				T3WarmUpBangHuiList_AwardBtn:SetProperty("DisabledImage", "set:Spring24 image:NotReach")
				T3WarmUpBangHuiList_AwardBtn:Disable()
				T3WarmUpBangHuiList_AwardBtn_Tips:Hide()
			end
			isFind = 1
			break
		end
	end
	if 1 ~= isFind then
		T3WarmUpBangHuiList_Info:SetText("#{BHHY_200907_39}")
		T3WarmUpBangHuiList_Info:SetToolTip("")
		T3WarmUpBangHuiList_AwardBtn:Hide()
	end
end

--##############点击事件##############
function T3WarmUpBangHui_Close()
	T3WarmUpBangHui_Hide()
end

function T3WarmUpBangHui_ClickInfoHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")
		Set_XSCRIPT_ScriptID( 888213 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--领取奖励
function T3WarmUpBangHui_ClickActValueAwardBtn(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientReceiveActValueAward")
		Set_XSCRIPT_ScriptID( 888213 )
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--领取当天奖励
function T3WarmUpBangHui_ClickActValueCurDayAwardBtn(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ReceiveSelfCurDayAward")
		Set_XSCRIPT_ScriptID( 888213 )
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--领取上周奖励
function T3WarmUpBangHui_ClickAwardBtn()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ReceiveLastWeekAward")
		Set_XSCRIPT_ScriptID( 888213 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--####################################

--以下是用户自定义的函数
function T3WarmUpBangHui_CareEvent(arg0,arg1,arg2)
	local ObjCaredID = tonumber(arg0)
	if( ObjCaredID ~= m_ObjCareID) then
		return
	end
	local ObjDistance = tonumber(arg2)
	if( (arg1 == "distance" and ObjDistance>MAX_OBJ_DISTANCE) or arg1=="destroy") then
		T3WarmUpBangHui_Hide()
	end
end