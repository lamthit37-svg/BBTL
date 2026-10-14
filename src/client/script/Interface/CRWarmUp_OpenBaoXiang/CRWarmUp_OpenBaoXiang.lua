-- 2021Q3 预热签到 开宝箱

local g_ui_list = {}								-- 组合表
local g_crwarmup_openbox_cost = 1 					-- 抽奖消耗
local g_crwarmup_openbox_lotterymax = 5				-- 最大抽奖次数
local g_crwarmup_openbox_level = 30					-- 等级限制
local g_crwarmup_openbox_actneed = 1200				-- 钥匙日活需要
local g_crwarmup_openbox_actweekneed = 2000			-- 钥匙周活需要

local g_crwarmup_openbox_expmax = 20				-- 历练最大值
local g_crwarmup_openbox_expactneed = 200			-- 历练日活需要
local g_crwarmup_openbox_exprewardmax = 9			-- 历练聚一起可以领奖的个数
local g_crwarmup_openbox_playerexpcost = {			-- 主角历练消耗
	2, 4, 6, 8, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
}

g_crwarmup_openbox_17expcost = {					-- 十七历练一次消耗的代币数量
	2, 2, 3, 2, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
}

local g_crwarmup_boxreward 		= 39923604			-- 神秘宝箱展示ID

local g_Time_Start				= 20211011			-- 20211011
local g_TimeStep1_End			= 20211028			--20211028
local g_TimeStep2_Start			= 20211029			--20211029			-- 第二阶段：29日宝箱
local g_TimeBox_End				= 20211114			-- 礼包结束时间
local g_TimeEnd					= 20211117

local g_secStep_Update			= 1					-- 二阶段更新标识
local g_npc_info = { x = 256, z = 142, sceneId = 824, name = "穆宇", }

local g_OpenTime				= 0
local g_UICommand				= 88877304	-- 刷新界面红点

local g_frame_unifiedposition = nil			-- 分辨率变化跟踪数值
function CRWarmUp_OpenBaoXiang_PreLoad()
	this:RegisterEvent("OPENUI_21Q3ACT_SIGNIN")
	this:RegisterEvent("UPDATE_21Q3ACT_SIGNIN",false)
	this:RegisterEvent("UI_COMMAND",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CRWarmUp_OpenBaoXiang_OnLoad()
	g_ui_list = {
		[1] = {action=CRWarmUp_OpenBaoXiang_Item1, mask=CRWarmUp_OpenBaoXiang_Item1Mask,lock=CRWarmUp_OpenBaoXiang_Item1_Locked,},
		[2] = {action=CRWarmUp_OpenBaoXiang_Item2, mask=CRWarmUp_OpenBaoXiang_Item2Mask,lock=CRWarmUp_OpenBaoXiang_Item2_Locked,},
		[3] = {action=CRWarmUp_OpenBaoXiang_Item3, mask=CRWarmUp_OpenBaoXiang_Item3Mask,lock=CRWarmUp_OpenBaoXiang_Item3_Locked,},
		[4] = {action=CRWarmUp_OpenBaoXiang_Item4, mask=CRWarmUp_OpenBaoXiang_Item4Mask,lock=CRWarmUp_OpenBaoXiang_Item4_Locked,},
		[5] = {action=CRWarmUp_OpenBaoXiang_Item5, mask=CRWarmUp_OpenBaoXiang_Item5Mask,lock=CRWarmUp_OpenBaoXiang_Item5_Locked,},
	}

	g_frame_unifiedposition = CRWarmUp_OpenBaoXiang_MainFrame:GetProperty("UnifiedPosition") 
end

function CRWarmUp_OpenBaoXiang_OnEvent(event)
	if event == "OPENUI_21Q3ACT_SIGNIN" and tonumber(arg0) == 2 then
		CRWarmUp_OpenBaoXiang_InitPos()
		CRWarmUp_OpenBaoXiang_OnShow()
	elseif event == "UPDATE_21Q3ACT_SIGNIN" then
		CRWarmUp_OpenBaoXiang_OnShow()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_UICommand then
		CRWarmUp_OpenBaoXiang_UpdateAllUI()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CRWarmUp_OpenBaoXiang_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		CRWarmUp_OpenBaoXiang_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		CRWarmUp_OpenBaoXiang_Close()
	end
end

--===================================================================================
--*******************************显示剧情内容 Start***************************************
--===================================================================================

--=================初始化界面信息==============================
function CRWarmUp_OpenBaoXiang_OnShow()
	g_OpenTime = tonumber(DataPool:GetServerDayTime())
	CRWarmUp_OpenBaoXiang_BaseInfoOnShow()
	CRWarmUp_OpenBaoXiang_ItemInfoOnShow()
	CRWarmUp_OpenBaoXiang_RedPointOnShow()
	CRWarmUp_OpenBaoXiang_CloseOtherUI()
	this:Show()
end

--=================显示基础信息==============================
function CRWarmUp_OpenBaoXiang_BaseInfoOnShow()
	-- 显示需要钥匙
	local strCost = ScriptGlobal_Format("#{MPYR_210830_68}", g_crwarmup_openbox_cost)
	CRWarmUp_OpenBaoXiang_ChouQu_DemandInfo:SetText(strCost)

	-- 获得的钥匙数量
	local nKey = DataPool:Lua_21Q3SignInAct_GetCoin(2)
	local strOwn = ScriptGlobal_Format("#{MPYR_210830_70}", nKey)
	CRWarmUp_OpenBaoXiang_KeyNum:SetText(strOwn)
	CRWarmUp_OpenBaoXiang_KeyNum:SetToolTip("#{MPYR_210830_71}")

	-- tips
	CRWarmUp_OpenBaoXiang_PageSelect1:SetToolTip("#{MPYR_210830_35}")
	CRWarmUp_OpenBaoXiang_PageSelect2:SetToolTip("#{MPYR_210830_36}")
	CRWarmUp_OpenBaoXiang_ChouQu_Btn:SetToolTip("#{MPYR_210830_202}")
	CRWarmUp_OpenBaoXiang_GetMiXin:SetToolTip("#{MPYR_210830_204}")
	CRWarmUp_OpenBaoXiang_KeyNum:SetToolTip("#{MPYR_210830_71}")
	CRWarmUp_OpenBaoXiang_GetKey:SetToolTip("#{MPYR_210830_203}")

	if CRWarmUp_OpenBaoXiang_IsRightTime() == 2 then
		local bKeyBug = 0
		for i=1, g_crwarmup_openbox_lotterymax do
			local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
			if reward == 0 then
				bKeyBug = 1
				break
			end
		end
		if bKeyBug > 0 then
			CRWarmUp_OpenBaoXiang_GetMiXin:Show()
		else
			CRWarmUp_OpenBaoXiang_GetMiXin:Hide()
		end
	else
		CRWarmUp_OpenBaoXiang_GetMiXin:Hide()
	end

	CRWarmUp_OpenBaoXiang_PageSelect2:SetCheck(1)
end

--=================显示抽奖情况==============================
function CRWarmUp_OpenBaoXiang_ItemInfoOnShow()
	--local itemcnt = DataPool:Lua_21Q3SignInAct_GetLotteryCount()
	local cnt = table.getn(g_ui_list or {})
	for i=1, cnt do
		local uidata = g_ui_list[i]
		-- 展示道具
		local action = DataPool:CreateActionItemForShow(g_crwarmup_boxreward, 1)
		local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)

		if reward > 0 and action:GetID() ~= 0 then
			uidata.action:SetActionItem( action:GetID() )
			-- 显示是否已经领取过道具
			if reward == 1 then
				uidata.mask:Show()
			else
				uidata.mask:Hide()
			end
			uidata.action:Show()
			uidata.lock:Hide()
		else
			uidata.action:SetActionItem( -1 )
			uidata.mask:Hide()
			uidata.action:Hide()
			uidata.lock:Show()
		end
	end
end

--=================显示红点情况==============================
function CRWarmUp_OpenBaoXiang_RedPointOnShow()
	-- 二阶段红点
	if CRWarmUp_OpenBaoXiang_IsRightTime() >= 2 then
		local bRed = 0
		-- 抽取一次红点
		local lotterycnt = DataPool:Lua_21Q3SignInAct_GetLotteryCount()
		local nKey = DataPool:Lua_21Q3SignInAct_GetCoin(2)
		if nKey >= g_crwarmup_openbox_cost then
			local ownrewad = 0
			for i=1, g_crwarmup_openbox_lotterymax do
				local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
				if reward == 1000 then
					ownrewad = 1
					break
				end
			end
			if ownrewad > 0 and lotterycnt < g_crwarmup_openbox_lotterymax then
				bRed = 1
				CRWarmUp_OpenBaoXiang_ChouQu_Tips:Show()
			else
				CRWarmUp_OpenBaoXiang_ChouQu_Tips:Hide()
			end
		else
			CRWarmUp_OpenBaoXiang_ChouQu_Tips:Hide()
		end

		-- 获取钥匙红点
		local bKeyPoint = 0
		if CRWarmUp_OpenBaoXiang_IsRightTime() == 2 then
			if lotterycnt < g_crwarmup_openbox_lotterymax then
				-- 日活跃钥匙
				local nDayReward = DataPool:Lua_21Q3SignInAct_GetDayActiveKeyReward()
				if nDayReward <=0 then
					local nToadyActivePoint = Player:GetData("WEEKACTIVEPOINT")
					if nToadyActivePoint >= g_crwarmup_openbox_actneed then
						bRed = 1
						bKeyPoint = 1
					end
				end

				-- 周活跃钥匙
				if bKeyPoint < 1 then
					local nWeekReward = DataPool:Lua_21Q3SignInAct_GetWeekActiveKeyReward()
					if nWeekReward > 0 then
						bRed = 1
						bKeyPoint = 1
					end
				end
			end
		end
		-- 显示钥匙红点
		if bKeyPoint > 0 then
			CRWarmUp_OpenBaoXiang_GetKey_Tips:Show()
		else
			CRWarmUp_OpenBaoXiang_GetKey_Tips:Hide()
		end

		local bKeyBug = 0
		--for i=1, g_crwarmup_openbox_lotterymax do
		--	local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
		--	if reward == 0 then
		--		bKeyBug = 1
		--		bRed = 1
		--		break
		--	end
		--end

		if bKeyBug > 0 then
			CRWarmUp_OpenBaoXiang_GetMiXin_Tips:Show()
		else
			CRWarmUp_OpenBaoXiang_GetMiXin_Tips:Hide()
		end

		-- 显示开宝箱红点
		if bRed > 0 then
			CRWarmUp_OpenBaoXiang_PageSelect2_Tips:Show()
		else
			CRWarmUp_OpenBaoXiang_PageSelect2_Tips:Hide()
		end
	else
		CRWarmUp_OpenBaoXiang_GetKey_Tips:Hide()
		CRWarmUp_OpenBaoXiang_ChouQu_Tips:Hide()
		CRWarmUp_OpenBaoXiang_GetMiXin_Tips:Hide()
		CRWarmUp_OpenBaoXiang_PageSelect2_Tips:Hide()
	end

	-- 红点默人一阶段没有红点
	CRWarmUp_OpenBaoXiang_PageSelect1_Tips:Hide()
	-- 一阶段红点
	if CRWarmUp_OpenBaoXiang_IsRightTime() == 1 then
		-- 男主历练值
		local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
		-- 十七历练值
		local n17Coin = DataPool:Lua_21Q3SignInAct_GetCoin(1)
		-- 获得男主历练值
		local nPlayerCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
		-- 获得17历练值
		local n17Cnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
		
		local bRed = 0
		--判定男主历练是否显示红点
		if nPlayerCnt >= g_crwarmup_openbox_expmax then
		elseif nPlayerCoin >= g_crwarmup_openbox_playerexpcost[nPlayerCnt+1] then
			bRed = 1
		end

		--判定十七历练是否否显示红点
		if n17Cnt >= g_crwarmup_openbox_expmax then
		elseif n17Coin >= g_crwarmup_openbox_17expcost[n17Cnt+1] then
			bRed = 1
		end

		for i=1, g_crwarmup_openbox_exprewardmax do
			local bGetItem = DataPool:Lua_21Q3SignInAct_GetRewardListValue(i-1)
			if bGetItem == 1000 then
				bRed = 1
				break
			end
		end

		local bValueRed = 0
		-- 登录奖励是否领取
		local blogin = DataPool:Lua_21Q3SignInAct_GetDayExpReward(0)
		if blogin <= 0 then
			bValueRed = 1
		end

		-- 日活奖励
		local bDay = DataPool:Lua_21Q3SignInAct_GetDayExpReward(1)
		if bDay <= 0 then
			local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
			if nToadyActivePoint >= g_crwarmup_openbox_expactneed then
				bValueRed = 1
			end
		end

		-- 参与交互活动
		-- local bAct = DataPool:Lua_21Q3SignInAct_GetDayExpReward(2)
		-- if bAct <= 0 then
		-- 	bValueRed = 1
		-- end

		-- 显示聚一起红点
		if bValueRed > 0 or bRed > 0 then
			CRWarmUp_OpenBaoXiang_PageSelect1_Tips:Show()
		else
			CRWarmUp_OpenBaoXiang_PageSelect1_Tips:Hide()
		end
	else
		CRWarmUp_OpenBaoXiang_PageSelect1_Tips:Hide()
	end
end

--=================点击抽奖=============================
function CRWarmUp_OpenBaoXiang_LotteryOnClick()
	
	local nTimeType = CRWarmUp_OpenBaoXiang_IsRightTime()
	if nTimeType < 2 then
		if nTimeType <= -2 then
			PushDebugMessage("#{MPYR_210830_217}")
		else
			PushDebugMessage("#{MPYR_210830_128}")
		end
		return
	end


	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_openbox_level then
		PushDebugMessage("#{MPYR_210830_129}")
		return
	end

	if CRWarmUp_OpenBaoXiang_BaseCheck() < 1 then
		return
	end

	
	-- 看是否达到最大抽奖次数
	local lotterycnt = DataPool:Lua_21Q3SignInAct_GetLotteryCount()
	if lotterycnt >= g_crwarmup_openbox_lotterymax then
		PushDebugMessage("#{MPYR_210830_130}")
		return
	end

	local ownrewad = 0
	for i=1, g_crwarmup_openbox_lotterymax do
		local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
		if reward == 1000 then
			ownrewad = 1
			break
		end
	end
	if ownrewad <= 0 then
		PushDebugMessage("#{MPYR_210830_218}")
		return
	end
	-- 判断钥匙是否充足
	local nKey = DataPool:Lua_21Q3SignInAct_GetCoin(2)
	if nKey < g_crwarmup_openbox_cost then
		PushDebugMessage("#{MPYR_210830_131}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Lottery" )
		Set_XSCRIPT_ScriptID( 888772 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=================点击获取钥匙=============================
function CRWarmUp_OpenBaoXiang_GetKeyOnClick()
	local nTimeType = CRWarmUp_OpenBaoXiang_IsRightTime()
	if nTimeType > 2 or nTimeType == -2 then
		PushDebugMessage("#{MPYR_210830_217}")
		return
	end
	if nTimeType < 2 then
		PushDebugMessage("#{MPYR_210830_120}")
		return
	end

	local tNpc = g_npc_info
	-- 前往NPC
	AutoRuntoTargetExWithName(tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name)
end

--=================点击聚一起=============================
function CRWarmUp_OpenBaoXiang_JuYiQiOnClick()
	-- 判定时间
	if CRWarmUp_OpenBaoXiang_IsRightTime() ~= 1 then
		PushDebugMessage("#{MPYR_210830_18}")
		CRWarmUp_OpenBaoXiang_PageSelect1:SetCheck(0)
		CRWarmUp_OpenBaoXiang_PageSelect2:SetCheck(1)
		return
	end

	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_openbox_level then
		PushDebugMessage("#{MPYR_210830_17}")
		CRWarmUp_OpenBaoXiang_PageSelect1:SetCheck(0)
		CRWarmUp_OpenBaoXiang_PageSelect2:SetCheck(1)
		return
	end

	Variable:SetVariable("CRWarmUpPos", CRWarmUp_OpenBaoXiang_MainFrame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OPENUI_21Q3ACT_SIGNIN", 1)
end

function CRWarmUp_OpenBaoXiang_GetMiXinOnClick()

	local nTimeType = CRWarmUp_OpenBaoXiang_IsRightTime()
	if nTimeType > 2 or nTimeType == -2 then
		PushDebugMessage("#{MPYR_210830_217}")
		return
	end
	if nTimeType < 2 then
		PushDebugMessage("#{MPYR_210830_170}")
		return
	end

	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_openbox_level then
		PushDebugMessage("#{MPYR_210830_171}")
		return
	end

	if CRWarmUp_OpenBaoXiang_BaseCheck() < 1 then
		return
	end

	local total = 0
	for i=1, g_crwarmup_openbox_lotterymax do
		local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
		if reward > 0 then
			total = total + 1
		end
	end

	if total >= g_crwarmup_openbox_lotterymax then
		PushDebugMessage("#{MPYR_210830_172}")
		return
	end

	PushEvent("OPEN_21Q3ACT_SIGNIN_OTHER", 3)
end

function CRWarmUp_OpenBaoXiang_OnHelpClick()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 3, "#{MPYR_210830_38}" )
end

--=================是否为正确时间=============================
function CRWarmUp_OpenBaoXiang_IsRightTime()
	local nCurDay = tonumber(DataPool:GetServerDayTime())
	-- 第一阶段
	if nCurDay >= g_Time_Start and nCurDay <= g_TimeStep1_End then
		return 1
	end

	-- 宝箱阶段
	if nCurDay >= g_TimeStep2_Start and nCurDay <= g_TimeBox_End and g_secStep_Update > 0 then
		return 2
	end

	-- 第二阶段
	if nCurDay >= g_TimeStep2_Start and nCurDay <= g_TimeEnd and g_secStep_Update > 0 then
		return 3
	end

	-- 活动未开启
	if nCurDay < g_Time_Start then
		return -1
	end

	-- 活动已结束
	if nCurDay > g_TimeEnd then
		return -2
	end

	return 0
end

--=================基础条件检查=============================
function CRWarmUp_OpenBaoXiang_BaseCheck()

	-- 安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return 0
	end

	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return 0
	end

	-- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage("#{ZJWF_201231_25}")
		return 0
	end

	return 1
end

function CRWarmUp_OpenBaoXiang_UpdateAllUI()
	if this:IsVisible() then
		local curday = Get_XParam_INT(0)
		if curday > g_OpenTime then
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "RefreshClientUI" )
			Set_XSCRIPT_ScriptID( 888772 )
			Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		end
	end
end

function CRWarmUp_OpenBaoXiang_CloseOtherUI()
	if IsWindowShow( "CRWarmUp_GetTogther" ) then
		CloseWindow( "CRWarmUp_GetTogther", true )
	end
	if IsWindowShow( "CRWarmUp_Story" ) then
		CloseWindow( "CRWarmUp_Story", true )
	end
	if IsWindowShow( "CRWarmUp_GetTravelValue" ) then
		CloseWindow( "CRWarmUp_GetTravelValue", true )
	end
end

function CRWarmUp_OpenBaoXiang_InitPos()
	local selfUnionPos = Variable:GetVariable("CRWarmUpPos")
	if selfUnionPos ~= nil then
		CRWarmUp_OpenBaoXiang_MainFrame:SetProperty("UnifiedPosition", selfUnionPos)
	end
end

function CRWarmUp_OpenBaoXiang_Close()
	Variable:SetVariable("CRWarmUpPos", CRWarmUp_OpenBaoXiang_MainFrame:GetProperty("UnifiedPosition"), 1)
	this:Hide()
end

function CRWarmUp_OpenBaoXiang_ResetPos()
	CRWarmUp_OpenBaoXiang_MainFrame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end
