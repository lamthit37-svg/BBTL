--WuShenTan_Guide.lua
local g_WuShenTan_Guide_Frame_UnifiedPosition
local g_WuShenTan_Guide_Event                  = {
	--begtime-endtime 活动总持续时间 只是用来计算悬浮提示用的
	--btntips_unbeg   活动暂未开启的按钮悬浮提示
	--btntips_doing   点击后可参与活动的按钮悬浮提示
	--btntips_end     活动已结束的按钮悬浮提示
	--因为本次有活动使用两个按钮,并且两个按钮显示时间有重叠,所以加一套后缀2的给第二个按钮显示悬浮提示用。没有第二个按钮的活动不用填后缀2的参数
	[1] = { --打卡 按钮点击接口: WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_3_OnClick
		begtime = 20260831, endtime = 20260920,
		btntips_unbeg = "#{WSZH_260408_07}", btntips_doing = "#{WSDK_260327_89}", btntips_end = "#{WSZH_260408_09}",
		begtime2 = 0, endtime2 = 0,
		btntips_unbeg2 = "", btntips_doing2 = "", btntips_end2 = "",
		btnTabe = 1,
	}, 
	[2] = {--全民boss 按钮点击接口: WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_2_OnClick
		begtime = 20260831, endtime = 20260920, --全民boss
		btntips_unbeg = "#{WSZH_260408_07}", btntips_doing = "#{WSTZ_260403_136}", btntips_end = "#{WSZH_260408_09}",
		begtime2 = 0, endtime2 = 0, 
		btntips_unbeg2 = "", btntips_doing2 = "", btntips_end2 = "",
		btnTabe = 1,
	}, 
	[3] = {--武神坛PVP 按钮点击接口: WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_1_OnClick
		begtime = 20260831, endtime = 20260920,
		btntips_unbeg = "#{WSZH_260408_07}", btntips_doing = "#{JDQL_260630_03}", btntips_end = "#{JDQL_260630_04}",
		begtime2 = 0, endtime2 = 0,
		btntips_unbeg2 = "", btntips_doing2 = "", btntips_end2 = "",
		btnTabe = 1,
	},
	[4] = {--奖励展示 按钮点击接口: WuShenTan_Guide_Stage2_HuoDong_Btn_OnClick
		begtime = 0, endtime = 0,
		btntips_unbeg = "", btntips_doing = "", btntips_end = "",
		begtime2 = 0, endtime2 = 0,
		btntips_unbeg2 = "", btntips_doing2 = "", btntips_end2 = "",
		btnTabe = 2,
	}, 
	[5] = {--决战boss 按钮点击接口: WuShenTan_Guide_Stage1_FinalBattle_Btn_OnClick
		begtime = 20260920, endtime = 20260921,
		btntips_unbeg = "#{WSZH_260408_07}", btntips_doing = "#{WSTZ_260403_138}", btntips_end = "#{WSZH_260408_09}",
		begtime2 = 0, endtime2 = 0,
		btntips_unbeg2 = "", btntips_doing2 = "", btntips_end2 = "",
		btnTabe = 1,
	}, 
}
local g_WuShenTan_Guide_Button_Guide_StateTemp = {
	[1] = {
		isBtnShow = 0, --按钮是否显示
		isTipShow = 0, --红点是否显示
		nParam3 = 0, --参数3
		nParam4 = 0, --参数4
	},
	[2] = {
		isBtnShow = 0, --按钮是否显示
		isTipShow = 0, --红点是否显示
		nParam3 = 0, --参数3
		nParam4 = 0, --参数4
	},
	[3] = {
		isBtnShow = 0, --按钮是否显示
		isTipShow = 0, --红点是否显示
		nParam3 = 0, --参数3
		nParam4 = 0, --参数4
	},
	[4] = {
		isBtnShow = 0, --按钮是否显示
		isTipShow = 0, --红点是否显示
		nParam3 = 0, --参数3
		nParam4 = 0, --参数4
	},
	[5] = {
		isBtnShow = 0, --按钮是否显示
		isTipShow = 0, --红点是否显示
		nParam3 = 0, --参数3
		nParam4 = 0, --参数4
	},
}
local g_WuShenTan_Guide_Button                 = {}
local g_WuShenTan_Guide_MatchTip               = {}
local g_WuShenTan_Guide_UICOM                  = 21225601
local g_WuShenTan_Guide_QuickEnterId           = 88
local g_WuShenTan_Guide_ActNum                 = 5 --活动数量
local g_WuShenTan_Guide_TimeStage              = 0 --影响神力祝福按钮的悬浮提示
local g_WuShenTan_Guide_NeedLevel              = 30

local g_WuShenTan_Guide_NextMatchIndex         = 1
local g_WuShenTan_Guide_RoundOneStage          = 0
local g_WuShenTan_Guide_RoundTwoStage          = 0
local g_WuShenTan_Guide_MatchHourMinuTblCount  = 6
local g_WuShenTan_Guide_MatchHourMinuTbl       =
{
	[1] = { sDateStr = "#{WSZH_260408_127}", monStr = "09", dayStr = "04", isOnlyOne = 0, oneStr = "", fRStr1 = "8",  fRStr2 = "4",  sRStr1 = "4",  sRStr2 = "2", },
	[2] = { sDateStr = "#{WSZH_260408_128}", monStr = "09", dayStr = "11", isOnlyOne = 0, oneStr = "", fRStr1 = "256", fRStr2 = "128", sRStr1 = "128", sRStr2 = "64", },
	[3] = { sDateStr = "#{WSZH_260408_128}", monStr = "09", dayStr = "12", isOnlyOne = 0, oneStr = "", fRStr1 = "64", fRStr2 = "32",  sRStr1 = "32",  sRStr2 = "16", },
	[4] = { sDateStr = "#{WSZH_260408_128}", monStr = "09", dayStr = "13", isOnlyOne = 1, oneStr = "", fRStr1 = "16",  fRStr2 = "8",  sRStr1 = "",  sRStr2 = "", },
	[5] = { sDateStr = "#{WSZH_260408_128}", monStr = "09", dayStr = "19", isOnlyOne = 0, oneStr = "", fRStr1 = "8",  fRStr2 = "4",  sRStr1 = "4",  sRStr2 = "2", },
	[6] = { sDateStr = "#{WSZH_260408_128}", monStr = "09", dayStr = "20", isOnlyOne = 1, oneStr = "", fRStr1 = "2",  fRStr2 = "1",  sRStr1 = "",  sRStr2 = "", },
}
local g_WuShenTan_Guide_MatchStage = 0
local g_WuShenTan_Guide_CurMatchIdx = 1

local g_WuShenTan_Guide_EmpowerTblCount = 10
local g_WuShenTan_Guide_EmpowerTbl            =
{
	[1] = { needEmpowerData = 500000,  damageStr = "1%", defenseStr = "0%", },
	[2] = { needEmpowerData = 1000000, damageStr = "1%", defenseStr = "1%", },
	[3] = { needEmpowerData = 1500000, damageStr = "2%", defenseStr = "1%", },
	[4] = { needEmpowerData = 2000000, damageStr = "2%", defenseStr = "2%", },
	[5] = { needEmpowerData = 2500000, damageStr = "3%", defenseStr = "2%", },
	[6] = { needEmpowerData = 3000000, damageStr = "3%", defenseStr = "3%", },
	[7] = { needEmpowerData = 3500000, damageStr = "4%", defenseStr = "3%", },
	[8] = { needEmpowerData = 4000000, damageStr = "4%", defenseStr = "4%", },
	[9] = { needEmpowerData = 4500000, damageStr = "5%", defenseStr = "4%", },
   [10] = { needEmpowerData = 5000000, damageStr = "5%", defenseStr = "5%", },
}
local g_WuShenTan_Guide_WorldEmpowerData      = 0
local g_WuShenTan_Guide_WorldCacheEmpowerData = 0 --比赛前缓存记录的本服神力祝福进度

local g_WuShenTan_Guide_IsHaveRewardToGet = 0
local g_WuShenTan_Guide_IsFinalBossOrHuache = 0
local g_WuShenTan_Guide_ShopDaibi = 0
local g_WuShenTan_Guide_IsInEmpowerMatchCacheTime = 0
local g_WuShenTan_Guide_BossKillCount = 0
local g_WuShenTan_Guide_DefaultMatchIndex = 1

function WuShenTan_Guide_PreLoad()
	--第二个参数代表界面隐藏时事件是否有效,默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function WuShenTan_Guide_OnLoad()
	WuShenTan_Guide_LoadControl()
	g_WuShenTan_Guide_Frame_UnifiedPosition = WuShenTan_Guide_Frame:GetProperty("UnifiedPosition")
	WuShenTan_Guide_Stage1_Match_Btn_RedDot:Hide()
	WuShenTan_Guide_Stage2_HuaChe_RedDot:Hide()
end

-- 装载控件
function WuShenTan_Guide_LoadControl()
	g_WuShenTan_Guide_Button[1] =
	{
		btn_1 = _G["WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_3"],
		tip_1 = _G["WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_3_RedDot"],
		btn_2 = nil,
		tip_2 = nil,
	}
	g_WuShenTan_Guide_Button[2] =
	{
		btn_1 = _G["WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_2"],
		tip_1 = _G["WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_2_RedDot"],
		btn_2 = nil,
		tip_2 = nil,
	}
	g_WuShenTan_Guide_Button[3] =
	{
		btn_1 = _G["WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_1"],
		tip_1 = _G["WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_1_RedDot"],
		btn_2 = nil,
		tip_2 = nil,
	}
	g_WuShenTan_Guide_Button[4] =
	{
		btn_1 = nil,
		tip_1 = nil,
		btn_2 = nil,
		tip_2 = nil,
	}
	g_WuShenTan_Guide_Button[5] =
	{
		btn_1 = _G["WuShenTan_Guide_Stage1_FinalBattle_Btn"],
		tip_1 = nil, --决战boss按钮不需要红点
		btn_2 = nil,
		tip_2 = nil,
	}

	g_WuShenTan_Guide_MatchTip[1] = 
	{
		[1] = WuShenTan_Guide_Match_1_UnableTip,
		[2] = WuShenTan_Guide_Match_1_EnableTip,
		[3] = WuShenTan_Guide_Match_1_FinshTip,
	}
	g_WuShenTan_Guide_MatchTip[2] = 
	{
		[1] = WuShenTan_Guide_Match_2_UnableTip,
		[2] = WuShenTan_Guide_Match_2_EnableTip,
		[3] = WuShenTan_Guide_Match_2_FinshTip,
	}
end

-- Event
function WuShenTan_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_WuShenTan_Guide_UICOM then
		local nOperation = Get_XParam_INT(0)
		if nOperation == 1 then --打开界面 页签一
			WuShenTan_Guide_CacheBtnData()
			g_WuShenTan_Guide_CurMatchIdx = g_WuShenTan_Guide_DefaultMatchIndex
			WuShenTan_Guide_Update()
			this:Show()
		elseif nOperation == 2 then --关闭界面
			WuShenTan_Guide_Close()
		elseif nOperation == 3 then --刷新界面
			if this:IsVisible() then
				WuShenTan_Guide_CacheBtnData()
				WuShenTan_Guide_Update()
			end
		elseif nOperation == 4 then
			--无页签二 悬空
		elseif nOperation == 5 then 
			PushEvent("OPEN_WSTGUIDE_ORIGINTEAM", 2)
		elseif nOperation == 6 then
			PushEvent("OPEN_WSTGUIDE_ALLZONETEAM", 2)
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		WuShenTan_Guide_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WuShenTan_Guide_Close()
	elseif event == "ADJEST_UI_POS" then
		WuShenTan_Guide_On_ResetPos()
	end

end

--缓存各个活动按钮的状态 只能在响应onuicommand事件时使用
function WuShenTan_Guide_CacheBtnData()
	--operation Get_XParam_INT(0)
	--按钮参数 Get_XParam_INT(1-g_WuShenTan_Guide_ActNum)
	--后续参数
	for index = 1, g_WuShenTan_Guide_ActNum do
		local DataState = Get_XParam_INT(index)
		local IsBtnShow = math.floor(DataState / 1000)
		DataState = math.mod(DataState, 1000)
		local IsTipsShow = math.floor(DataState / 100)
		DataState = math.mod(DataState, 100)
		local nParam3 = math.floor(DataState / 10)
		DataState = math.mod(DataState, 10)
		local nParam4 = DataState
		g_WuShenTan_Guide_Button_Guide_StateTemp[index].isBtnShow = IsBtnShow
		g_WuShenTan_Guide_Button_Guide_StateTemp[index].isTipShow = IsTipsShow
		g_WuShenTan_Guide_Button_Guide_StateTemp[index].nParam3 = nParam3
		g_WuShenTan_Guide_Button_Guide_StateTemp[index].nParam4 = nParam4
	end
	--之后的参数
	local n4Params = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 1)
	g_WuShenTan_Guide_TimeStage = math.floor(n4Params / 1000)
	n4Params = math.mod(n4Params, 1000)
	g_WuShenTan_Guide_NextMatchIndex = math.floor(n4Params / 100)
	n4Params = math.mod(n4Params, 100)
	g_WuShenTan_Guide_RoundOneStage = math.floor(n4Params / 10)
	n4Params = math.mod(n4Params, 10)
	g_WuShenTan_Guide_RoundTwoStage = n4Params

	g_WuShenTan_Guide_MatchStage = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 2)
	g_WuShenTan_Guide_IsHaveRewardToGet = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 3)
	g_WuShenTan_Guide_WorldEmpowerData = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 4)
	g_WuShenTan_Guide_WorldCacheEmpowerData = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 5)
	g_WuShenTan_Guide_IsFinalBossOrHuache = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 6)
	g_WuShenTan_Guide_ShopDaibi = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 7)
	g_WuShenTan_Guide_IsInEmpowerMatchCacheTime = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 8)
	g_WuShenTan_Guide_BossKillCount = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 9)
	g_WuShenTan_Guide_DefaultMatchIndex = Get_XParam_INT(g_WuShenTan_Guide_ActNum + 10)
end

-- 重置界面位置
function WuShenTan_Guide_On_ResetPos()
	WuShenTan_Guide_Frame:SetProperty("UnifiedPosition", g_WuShenTan_Guide_Frame_UnifiedPosition)
end

function WuShenTan_Guide_InitialData()
	g_WuShenTan_Guide_TimeStage      = 0
	g_WuShenTan_Guide_NextMatchIndex = 1
	g_WuShenTan_Guide_RoundOneStage  = 0
	g_WuShenTan_Guide_RoundTwoStage  = 0
	g_WuShenTan_Guide_MatchStage = 0
	g_WuShenTan_Guide_IsHaveRewardToGet = 0
	g_WuShenTan_Guide_IsFinalBossOrHuache = 0
	g_WuShenTan_Guide_WorldEmpowerData = 0
	g_WuShenTan_Guide_WorldCacheEmpowerData = 0
	g_WuShenTan_Guide_CurMatchIdx = 1
	g_WuShenTan_Guide_ShopDaibi = 0
	g_WuShenTan_Guide_IsInEmpowerMatchCacheTime = 0
	g_WuShenTan_Guide_BossKillCount = 0
	g_WuShenTan_Guide_DefaultMatchIndex = 1
end

-- 关闭
function WuShenTan_Guide_Close()
	WuShenTan_Guide_InitialData()
	this:Hide()
end

-- 刷新界面
function WuShenTan_Guide_Update()
	local IsShowMiniMapPoint = 0 --快捷入口红点是否显示
	local curDay = DataPool:GetServerDayTime()
	--商店的代币数量
	local daibinum = ScriptGlobal_Format("#{WSZH_260408_135}",tostring(g_WuShenTan_Guide_ShopDaibi))
	WuShenTan_Guide_Shop_DBNum:SetText(daibinum)

	--boss击杀情况
	local bossKillStr = ScriptGlobal_Format("#{WSTZ_260403_125}",tostring(g_WuShenTan_Guide_BossKillCount))
	WuShenTan_Guide_Stage1_FinalBossKillNum:SetText(bossKillStr)

	--先隐藏活动的按钮
	for index = 1, g_WuShenTan_Guide_ActNum do
		if g_WuShenTan_Guide_Button[index].btn_1 ~= nil then
			g_WuShenTan_Guide_Button[index].btn_1:Disable()
		end
		if g_WuShenTan_Guide_Button[index].tip_1 ~= nil then
			g_WuShenTan_Guide_Button[index].tip_1:Hide()
		end
		if g_WuShenTan_Guide_Button[index].btn_2 ~= nil then
			g_WuShenTan_Guide_Button[index].btn_2:Disable()
		end
		if g_WuShenTan_Guide_Button[index].tip_2 ~= nil then
			g_WuShenTan_Guide_Button[index].tip_2:Hide()
		end
	end
	for index = 1, g_WuShenTan_Guide_ActNum do
		--获取缓存的按钮状态
		local isBtnShow = g_WuShenTan_Guide_Button_Guide_StateTemp[index].isBtnShow
		local isTipShow = g_WuShenTan_Guide_Button_Guide_StateTemp[index].isTipShow
		local nParam3 = g_WuShenTan_Guide_Button_Guide_StateTemp[index].nParam3
		local nParam4 = g_WuShenTan_Guide_Button_Guide_StateTemp[index].nParam4

		local event = g_WuShenTan_Guide_Event[index]
		--设置按钮1的悬浮提示
		if g_WuShenTan_Guide_Button[index].btn_1 ~= nil then
			if curDay < event.begtime then
				g_WuShenTan_Guide_Button[index].btn_1:SetToolTip(event.btntips_unbeg)
			elseif curDay >= event.begtime and curDay <= event.endtime then
				g_WuShenTan_Guide_Button[index].btn_1:SetToolTip(event.btntips_doing)
			elseif curDay > event.endtime then
				g_WuShenTan_Guide_Button[index].btn_1:SetToolTip(event.btntips_end)
			end
		end
		--设置按钮2的悬浮提示
		if g_WuShenTan_Guide_Button[index].btn_2 ~= nil then
			if curDay < event.begtime2 then
				g_WuShenTan_Guide_Button[index].btn_2:SetToolTip(event.btntips_unbeg2)
			elseif curDay >= event.begtime2 and curDay <= event.endtime2 then
				g_WuShenTan_Guide_Button[index].btn_2:SetToolTip(event.btntips_doing2)
			elseif curDay > event.endtime2 then
				g_WuShenTan_Guide_Button[index].btn_2:SetToolTip(event.btntips_end2)
			end
		end

		--按钮1显隐
		if isBtnShow == 1 and g_WuShenTan_Guide_Button[index].btn_1 ~= nil then
			g_WuShenTan_Guide_Button[index].btn_1:Enable()
			--红点
			if isTipShow == 1 and g_WuShenTan_Guide_Button[index].tip_1 ~= nil then
				g_WuShenTan_Guide_Button[index].tip_1:Show()
			end
		end

		--按钮2显隐 参数3和4先这么用着 有特殊需求再特写
		if nParam3 == 1 and g_WuShenTan_Guide_Button[index].btn_2 ~= nil then
			g_WuShenTan_Guide_Button[index].btn_2:Enable()
			--红点
			if nParam4 == 1 and g_WuShenTan_Guide_Button[index].tip_2 ~= nil then
				g_WuShenTan_Guide_Button[index].tip_2:Show()
				isTipShow = 1
			end
		end

		--神力祝福按钮的红点
		if g_WuShenTan_Guide_IsHaveRewardToGet == 1 then
			WuShenTan_Guide_ShenLiDetail_Btn_RedDot:Show()
		else
			WuShenTan_Guide_ShenLiDetail_Btn_RedDot:Hide()
		end

		--客户端也根据状态刷新显示一下快捷入口的红点 以免服务器忘记刷新了
		if isTipShow == 1 or g_WuShenTan_Guide_IsHaveRewardToGet == 1 then
			IsShowMiniMapPoint = 1
		end
	end

	--快捷入口的红点
	Lua_ShowQuickEnterPointTip(g_WuShenTan_Guide_QuickEnterId, IsShowMiniMapPoint)

	--侠意buff加成部分
	local nLastEmpowerBuffIdx = 0 --目前满足的阶段
	local nLastEmpowerCacheBuffIdx = 0
	for i = 1, g_WuShenTan_Guide_EmpowerTblCount, 1 do
		if g_WuShenTan_Guide_WorldEmpowerData >= g_WuShenTan_Guide_EmpowerTbl[i].needEmpowerData then
			nLastEmpowerBuffIdx = i
		end
		if g_WuShenTan_Guide_WorldCacheEmpowerData >= g_WuShenTan_Guide_EmpowerTbl[i].needEmpowerData then
			nLastEmpowerCacheBuffIdx = i
		end
	end
	if nLastEmpowerBuffIdx >= g_WuShenTan_Guide_EmpowerTblCount then--满了 阶段显示100%
		--显示进度
		local percentStr = ScriptGlobal_Format("#{WSZH_260408_124}","100%")
		WuShenTan_Guide_ShenLi_NextLevel_Percent:SetText(percentStr)
		WuShenTan_Guide_ShenLi_EXPLace:SetProgress(1, 1)
	else
		local beginData = 0
		if nLastEmpowerBuffIdx == 0 then
			beginData = 0
		else
			beginData = g_WuShenTan_Guide_EmpowerTbl[nLastEmpowerBuffIdx].needEmpowerData
		end
		local endData = 0
		endData = g_WuShenTan_Guide_EmpowerTbl[nLastEmpowerBuffIdx+1].needEmpowerData
		local totolData = endData - beginData
		local subData = g_WuShenTan_Guide_WorldEmpowerData - beginData
		if subData > totolData then
			subData = totolData
		end
		if subData < 0 then
			subData = 0
		end
		local persent = 0
		if totolData > 0 then
			persent = math.floor((subData / totolData) * 100)
			--显示进度
			local percentStr = ScriptGlobal_Format("#{WSZH_260408_124}",tostring(persent).."%")
			WuShenTan_Guide_ShenLi_NextLevel_Percent:SetText(percentStr)
			WuShenTan_Guide_ShenLi_EXPLace:SetProgress(persent, 100)
		else
			WuShenTan_Guide_ShenLi_EXPLace:SetProgress(0, 1)
		end
		--Lua_TDU_Log(tostring(beginData)..";"..tostring(endData)..";"..tostring(totolData)..";"..tostring(persent)..";"..tostring(subData));
	end
	WuShenTan_Guide_ShenLi_LevelFrame_1:Hide()
	WuShenTan_Guide_ShenLi_LevelFrame_2:Hide()
	if nLastEmpowerBuffIdx >= 0 and nLastEmpowerBuffIdx < g_WuShenTan_Guide_EmpowerTblCount then
		WuShenTan_Guide_ShenLi_LevelFrame_1:Show()
		WuShenTan_Guide_ShenLi_LevelFrame_1_1:SetProperty("Image", "set:WuShenTan_Guide image:WuShenTan_Guide_ShenLiNum_"..tostring(nLastEmpowerBuffIdx))
	elseif nLastEmpowerBuffIdx == g_WuShenTan_Guide_EmpowerTblCount then
		WuShenTan_Guide_ShenLi_LevelFrame_2:Show()
		WuShenTan_Guide_ShenLi_LevelFrame_2_1:SetProperty("Image", "set:WuShenTan_Guide image:WuShenTan_Guide_ShenLiNum_1")
	end
	--显示造成伤害和收到伤害的加成用比赛时间点缓存的值
	if g_WuShenTan_Guide_IsInEmpowerMatchCacheTime == 1 then --比赛期间 用比赛前缓存的神力值来显示加成
		if nLastEmpowerCacheBuffIdx > 0 and nLastEmpowerCacheBuffIdx <= g_WuShenTan_Guide_EmpowerTblCount then
			local sDamageStr =ScriptGlobal_Format("#{WSZH_260408_110}",g_WuShenTan_Guide_EmpowerTbl[nLastEmpowerCacheBuffIdx].damageStr)
			local sDefenseStr =ScriptGlobal_Format("#{WSZH_260408_111}",g_WuShenTan_Guide_EmpowerTbl[nLastEmpowerCacheBuffIdx].defenseStr)
			WuShenTan_Guide_ShenLi_AttackBuff_Num:SetText(sDamageStr)
			WuShenTan_Guide_ShenLi_DefenceBuff_Num:SetText(sDefenseStr)
		else
			local sDamageStr =ScriptGlobal_Format("#{WSZH_260408_110}","%0")
			local sDefenseStr =ScriptGlobal_Format("#{WSZH_260408_111}","%0")
			WuShenTan_Guide_ShenLi_AttackBuff_Num:SetText(sDamageStr)
			WuShenTan_Guide_ShenLi_DefenceBuff_Num:SetText(sDefenseStr)
		end
	else --用服务器当前的神力值来显示加成
		if nLastEmpowerBuffIdx > 0 and nLastEmpowerBuffIdx <= g_WuShenTan_Guide_EmpowerTblCount then
			local sDamageStr =ScriptGlobal_Format("#{WSZH_260408_110}",g_WuShenTan_Guide_EmpowerTbl[nLastEmpowerBuffIdx].damageStr)
			local sDefenseStr =ScriptGlobal_Format("#{WSZH_260408_111}",g_WuShenTan_Guide_EmpowerTbl[nLastEmpowerBuffIdx].defenseStr)
			WuShenTan_Guide_ShenLi_AttackBuff_Num:SetText(sDamageStr)
			WuShenTan_Guide_ShenLi_DefenceBuff_Num:SetText(sDefenseStr)
		else
			local sDamageStr =ScriptGlobal_Format("#{WSZH_260408_110}","0%")
			local sDefenseStr =ScriptGlobal_Format("#{WSZH_260408_111}","0%")
			WuShenTan_Guide_ShenLi_AttackBuff_Num:SetText(sDamageStr)
			WuShenTan_Guide_ShenLi_DefenceBuff_Num:SetText(sDefenseStr)
		end
	end

	--特写决战boss的控件 根据日期
	--未开放时脚标：暂未开放WSZH_260408_17
	--开放时脚标：已开放WSZH_260408_18
	WuShenTan_Guide_Stage1_FinalBossFrame:Show()
	WuShenTan_Guide_Stage2_HuaCheFrame:Hide()
	WuShenTan_Guide_Stage1_FinalBattle_UnableTip:Hide()
	WuShenTan_Guide_Stage1_FinalBattle_EnableTip:Hide()
	--显示决战boss还是花车的底图和控件
	WuShenTan_Guide_Stage1_FinalBattle_BossImage_Disable:Hide()
	WuShenTan_Guide_Stage1_FinalBattle_BossImage_Enable:Hide()
	if g_WuShenTan_Guide_IsFinalBossOrHuache == 0 then --决战boss未开放
		--决战boss脚标
		WuShenTan_Guide_Stage1_FinalBattle_UnableTip:Show()
		--决战boss底图置灰
		WuShenTan_Guide_Stage1_FinalBattle_BossImage_Disable:Show()
	elseif g_WuShenTan_Guide_IsFinalBossOrHuache == 1 then --决战boss进行中
		--决战boss脚标
		WuShenTan_Guide_Stage1_FinalBattle_EnableTip:Show()
		--决战boss底图置亮
		WuShenTan_Guide_Stage1_FinalBattle_BossImage_Enable:Show()
	else
		--显示花车底图
		WuShenTan_Guide_Stage1_FinalBossFrame:Hide()
		WuShenTan_Guide_Stage2_HuaCheFrame:Show()
	end

	--神力祝福按钮的悬浮提示
	if g_WuShenTan_Guide_TimeStage == 1 then
		WuShenTan_Guide_ShenLiDetail_Btn:SetToolTip("#{WSZH_260408_34}") --进行中
	elseif g_WuShenTan_Guide_TimeStage == 2 then
		WuShenTan_Guide_ShenLiDetail_Btn:SetToolTip("#{WSZH_260408_33}") --未开始
	elseif g_WuShenTan_Guide_TimeStage == 3 then
		WuShenTan_Guide_ShenLiDetail_Btn:SetToolTip("#{WSZH_260408_35}") --已结束
	end

	--赛程
	WuShenTan_Guide_UpdateMatch()
end

--赛程、本服前二以及全服前四部分
function WuShenTan_Guide_UpdateMatch()
	--根据服务器传回的比赛状态来显示今日两场比赛的
	--比赛按钮悬浮提示
	if g_WuShenTan_Guide_NextMatchIndex <= g_WuShenTan_Guide_MatchHourMinuTblCount then
		WuShenTan_Guide_Stage1_Match_Btn:SetToolTip("#{WSZH_260408_90}")
	else
		WuShenTan_Guide_Stage1_Match_Btn:SetToolTip("#{WSZH_260408_91}")
	end
	if g_WuShenTan_Guide_CurMatchIdx < 1 or g_WuShenTan_Guide_CurMatchIdx > g_WuShenTan_Guide_MatchHourMinuTblCount then
		g_WuShenTan_Guide_CurMatchIdx = 1
	end
	local sDateTitle = g_WuShenTan_Guide_MatchHourMinuTbl[g_WuShenTan_Guide_CurMatchIdx].sDateStr
	local monStrS = g_WuShenTan_Guide_MatchHourMinuTbl[g_WuShenTan_Guide_CurMatchIdx].monStr
	local dayStrS = g_WuShenTan_Guide_MatchHourMinuTbl[g_WuShenTan_Guide_CurMatchIdx].dayStr
	local titleStr = ScriptGlobal_Format(sDateTitle,monStrS,dayStrS)
	WuShenTan_Guide_JHS_DateDetail:SetText(titleStr)
	--目前选中日期的两个比赛的名称
	local matchIndex = g_WuShenTan_Guide_CurMatchIdx
	local matchNameStr = ScriptGlobal_Format("#{WSZH_260408_14}",g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].fRStr1,g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].fRStr2)
	WuShenTan_Guide_MatchName_1:SetText(matchNameStr)
	if g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].oneStr ~= "" then
		WuShenTan_Guide_MatchName_1:SetText(g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].oneStr)
	end
	matchNameStr = ScriptGlobal_Format("#{WSZH_260408_14}",g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].sRStr1,g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].sRStr2)
	WuShenTan_Guide_MatchName_2:SetText(matchNameStr)
	if g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].oneStr ~= "" then
		WuShenTan_Guide_MatchName_2:SetText(g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].oneStr)
	end
	--是否此天只打一场比赛
	if g_WuShenTan_Guide_MatchHourMinuTbl[matchIndex].isOnlyOne == 1 then
		WuShenTan_Guide_Match_2:Hide()
	else
		WuShenTan_Guide_Match_2:Show()
	end
	--目前选中日期的两个比赛的进行状态 赛程状态：未开始WSZH_260408_12 交战中 WSZH_260408_15 已结束WSZH_260408_16
	if g_WuShenTan_Guide_CurMatchIdx < g_WuShenTan_Guide_NextMatchIndex then
		--显示已结束
		g_WuShenTan_Guide_MatchTip[1][1]:Hide()
		g_WuShenTan_Guide_MatchTip[1][2]:Hide()
		g_WuShenTan_Guide_MatchTip[1][3]:Show()
		g_WuShenTan_Guide_MatchTip[2][1]:Hide()
		g_WuShenTan_Guide_MatchTip[2][2]:Hide()
		g_WuShenTan_Guide_MatchTip[2][3]:Show()
	elseif g_WuShenTan_Guide_CurMatchIdx > g_WuShenTan_Guide_NextMatchIndex then
		--显示未开始
		g_WuShenTan_Guide_MatchTip[1][1]:Show()
		g_WuShenTan_Guide_MatchTip[1][2]:Hide()
		g_WuShenTan_Guide_MatchTip[1][3]:Hide()
		g_WuShenTan_Guide_MatchTip[2][1]:Show()
		g_WuShenTan_Guide_MatchTip[2][2]:Hide()
		g_WuShenTan_Guide_MatchTip[2][3]:Hide()
	else
		--显示两场比赛的状态
		g_WuShenTan_Guide_MatchTip[1][1]:Hide()
		g_WuShenTan_Guide_MatchTip[1][2]:Hide()
		g_WuShenTan_Guide_MatchTip[1][3]:Hide()
		g_WuShenTan_Guide_MatchTip[1][g_WuShenTan_Guide_RoundOneStage+1]:Show()
		g_WuShenTan_Guide_MatchTip[2][1]:Hide()
		g_WuShenTan_Guide_MatchTip[2][2]:Hide()
		g_WuShenTan_Guide_MatchTip[2][3]:Hide()
		g_WuShenTan_Guide_MatchTip[2][g_WuShenTan_Guide_RoundTwoStage+1]:Show()
	end

	--查看榜单按钮部分
	if g_WuShenTan_Guide_MatchStage == 0 then
		WuShenTan_Guide_WinAwards_BenFu_ListBtn:Disable()
		WuShenTan_Guide_WinAwards_QuanFu_ListBtn:Disable()
	elseif g_WuShenTan_Guide_MatchStage == 1 then
		WuShenTan_Guide_WinAwards_BenFu_ListBtn:Enable()
		WuShenTan_Guide_WinAwards_QuanFu_ListBtn:Disable()
	elseif g_WuShenTan_Guide_MatchStage == 2 then
		WuShenTan_Guide_WinAwards_BenFu_ListBtn:Enable()
		WuShenTan_Guide_WinAwards_QuanFu_ListBtn:Enable()
	elseif g_WuShenTan_Guide_MatchStage == 3 then
		WuShenTan_Guide_WinAwards_BenFu_ListBtn:Enable()
		WuShenTan_Guide_WinAwards_QuanFu_ListBtn:Enable()
	end
	if g_WuShenTan_Guide_CurMatchIdx >= 2 then
		WuShenTan_Guide_WinAwards_BenFu:Hide()
		WuShenTan_Guide_WinAwards_QuanFu:Show()
	else
		WuShenTan_Guide_WinAwards_BenFu:Show()
		WuShenTan_Guide_WinAwards_QuanFu:Hide()
	end
end

-- 切换页签一
function WuShenTan_Guide_SwitchToStage1_Btn_OnClick()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenGuideUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 1)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function WuShenTan_Guide_SwitchToStage2_Btn_OnClick()
	--没有页签二了
end

--切换到整合界面
function WuShenTan_Guide_GoToGuide_Btn()

end

--切换到兑换商店
function WuShenTan_Guide_GoToShop_Btn_OnClick()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenShop")
	Set_XSCRIPT_ScriptID(893651)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--打卡
function WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_3_OnClick()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenWSTDaKaUI")
	Set_XSCRIPT_ScriptID(893624)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	WuShenTan_Guide_ServerFreshTips()
end

--全民boss
function WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_2_OnClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWSTBossUI")
		Set_XSCRIPT_ScriptID(893760)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	WuShenTan_Guide_ServerFreshTips()
end

--决战boss
function WuShenTan_Guide_Stage1_FinalBattle_Btn_OnClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWSTBossUI")
		Set_XSCRIPT_ScriptID(893768)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	WuShenTan_Guide_ServerFreshTips()
end

--武神坛PVP
function WuShenTan_Guide_Stage1_AllServer_HuoDongBtn_1_OnClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUI")
		Set_XSCRIPT_ScriptID(893385)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	WuShenTan_Guide_ServerFreshTips()
end

--比赛
function WuShenTan_Guide_Stage1_Match_Btn_OnClick()
	if g_WuShenTan_Guide_NextMatchIndex > g_WuShenTan_Guide_MatchHourMinuTblCount then
		PushDebugMessage("#{WSZH_260408_26}")
		return 0
	end
	if Player:GetLevel() < g_WuShenTan_Guide_NeedLevel then
		PushDebugMessage("#{WSZH_260408_03}")
		return 0
	end
	AutoRuntoTargetExWithName(296, 225, 0, "周伯衡")
	--WuShenTan_Guide_ServerFreshTips()
end

--奖励展示
function WuShenTan_Guide_Stage2_HuoDong_Btn_OnClick()
	--todo 这个按钮没功能 后面应该干掉此按钮
	WuShenTan_Guide_ServerFreshTips()
end

function WuShenTan_Guide_OriginTeamListBtn()
	PushEvent("OPEN_WSTGUIDE_ORIGINTEAM", 0)
	if g_WuShenTan_Guide_MatchStage <= 1 then--直接显示虚位以待
		PushEvent("OPEN_WSTGUIDE_ORIGINTEAM", 2)
		return 0
	end
	--local zwid,_ = DataPool:LuaFnWSTGetOriginTeamInfoByIndex(0,0)--客户端已有缓存
	--if zwid ~= -1 then
	--	PushEvent("OPEN_WSTGUIDE_ORIGINTEAM", 1)
	--	return 0
	--end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenGuideUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 3)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function WuShenTan_Guide_AllZoneTeamListBtn()
	PushEvent("OPEN_WSTGUIDE_ALLZONETEAM", 0)
	if g_WuShenTan_Guide_MatchStage <= 2 then--直接显示虚位以待
		PushEvent("OPEN_WSTGUIDE_ALLZONETEAM", 2)
		return 0
	end
	--local zwid,_ = DataPool:LuaFnWSTGetAllZoneTeamInfoByIndex(0,0)--客户端已有缓存
	--if zwid ~= -1 then
	--	PushEvent("OPEN_WSTGUIDE_ALLZONETEAM", 1)
	--	return 0
	--end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenGuideUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 4)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--打开神力祝福页面
function WuShenTan_Guide_Stage1_ShenLiDetail_Btn_OnClick()
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_NeedLevel then
		PushDebugMessage("#{WSZH_260408_03}")
		return 0
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 1)
	Set_XSCRIPT_Parameter(1, 0)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function WuShenTan_Guide_ServerFreshTips()
	--主动刷新红点
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("ShowButtonTips")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--花车帮助
function WuShenTan_Guide_Stage2_HuaChe_ShowHelp()
	PushEvent("QUEST_HELPINFO", "#{GJHC_260424_39}")
end

--决战boss奖励展示
function WuShenTan_Guide_Stage1_FinalBoss_SeeReward_Btn_OnClick()
	PushEvent("OPEN_WST_HUACHE_REWARD", "1")
end

--花车奖励展示
function WuShenTan_Guide_Stage2_HuaChe_SeeReward_Btn_OnClick()
	PushEvent("OPEN_WST_HUACHE_REWARD", "1")
end

--名冠本服奖励展示
function WuShenTan_Guide_WinAwards_BenFu_Btn_OnClick()
	PushEvent("OPEN_WST_HUACHE_REWARD", "2")
end

--名冠全服奖励展示
function WuShenTan_Guide_WinAwards_QuanFu_Btn_OnClick()
	PushEvent("OPEN_WST_HUACHE_REWARD", "2")
end

--向左翻页
function WuShenTan_Guide_JHS_PageUp()
	g_WuShenTan_Guide_CurMatchIdx = g_WuShenTan_Guide_CurMatchIdx - 1
	if g_WuShenTan_Guide_CurMatchIdx < 1 or g_WuShenTan_Guide_CurMatchIdx > g_WuShenTan_Guide_MatchHourMinuTblCount then
		g_WuShenTan_Guide_CurMatchIdx = 1
	end
	WuShenTan_Guide_UpdateMatch()
end

--向右翻页
function WuShenTan_Guide_JHS_PageDown()
	g_WuShenTan_Guide_CurMatchIdx = g_WuShenTan_Guide_CurMatchIdx + 1
	if g_WuShenTan_Guide_CurMatchIdx < 1 or g_WuShenTan_Guide_CurMatchIdx > g_WuShenTan_Guide_MatchHourMinuTblCount then
		g_WuShenTan_Guide_CurMatchIdx = g_WuShenTan_Guide_MatchHourMinuTblCount
	end
	WuShenTan_Guide_UpdateMatch()
end

function WuShenTan_Guide_Help_Btn_OnClick()
	PushEvent("QUEST_HELPINFO", "#{WSZH_260408_41}")
end