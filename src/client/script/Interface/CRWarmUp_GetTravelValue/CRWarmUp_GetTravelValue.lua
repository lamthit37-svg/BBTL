-- 2021Q3 预热签到 获取游历值界面

local g_ui_list = {}
local g_frame_unifiedposition = nil				-- 分辨率变化跟踪数值

local g_crwarmup_limitlevel		= 30			-- 限制等级
local g_Time_Start				= 20211011		-- 20211011
local g_TimeStep1_End			= 20211028
local g_TimeStep2_Start			= 20211029		-- 第二阶段
local g_TimeEnd					= 20211114

local g_ui_day_actpoint			= 200			-- 活跃数量
local g_ui_item_max				= 3				-- 领奖条数
local g_ui_item = {
	{item=39923606,},
	{item=39923606,},
	{item=39923607,},
}

local g_yqgz_MD					= 2384			-- 逸趣共掷领奖标识

local g_npc_info = { x = 246, z = 269, sceneId = 0, name = "朔风", }

function CRWarmUp_GetTravelValue_PreLoad()
	this:RegisterEvent("OPEN_21Q3ACT_SIGNIN_OTHER")
	this:RegisterEvent("UPDATE_21Q3ACT_SIGNIN",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CRWarmUp_GetTravelValue_OnLoad()
	g_ui_list = {
		{action=CRWarmUp_GetTravelValue_Item1,btn=CRWarmUp_GetTravelValue_Btn1,red=CRWarmUp_GetTravelValue_Tips1,bget=CRWarmUp_GetTravelValue_BtnYiLingQu1,},
		{action=CRWarmUp_GetTravelValue_Item2,btn=CRWarmUp_GetTravelValue_Btn2,red=CRWarmUp_GetTravelValue_Tips2,bget=CRWarmUp_GetTravelValue_BtnYiLingQu2,},
		{action=CRWarmUp_GetTravelValue_Item3,btn=CRWarmUp_GetTravelValue_Btn3,red=nil,bget=CRWarmUp_GetTravelValue_BtnYiLingQu3,},
	}
	g_frame_unifiedposition = CRWarmUp_GetTravelValue_Frame:GetProperty("UnifiedPosition") 
end

function CRWarmUp_GetTravelValue_OnEvent(event)
	if event == "OPEN_21Q3ACT_SIGNIN_OTHER" and tonumber(arg0) == 2  then
		CRWarmUp_GetTravelValue_OnShow()
	elseif event == "UPDATE_21Q3ACT_SIGNIN" then
		CRWarmUp_GetTravelValue_BaseUIUpdate()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CRWarmUp_GetTravelValue_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		CRWarmUp_GetTravelValue_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		CRWarmUp_GetTravelValue_Close()
	end
end

--===================================================================================
--*******************************聚一起Start***************************************
--===================================================================================

--=================初始化界面信息==============================
function CRWarmUp_GetTravelValue_OnShow()
	CRWarmUp_GetTravelValue_BaseUIUpdate()
	this:Show()
end

--=================基础数据刷新==============================
function CRWarmUp_GetTravelValue_BaseUIUpdate()
	-- 显示图标
	for i=1, g_ui_item_max do
		local uidata,itemdata = g_ui_list[i],g_ui_item[i]
		local action = DataPool:CreateActionItemForShow(itemdata.item, 1)
		-- 展示道具
		if action:GetID() ~= 0 then
			uidata.action:SetActionItem( action:GetID() )
		else
			uidata.action:SetActionItem( -1 )
		end
	end
	-- 进度
	local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
	local szTxt = ScriptGlobal_Format("#{MPYR_210830_94}", nToadyActivePoint, g_ui_day_actpoint)
	CRWarmUp_GetTravelValue_Reward2_Progress:SetText(szTxt)
	-- 按钮情况
	local login = DataPool:Lua_21Q3SignInAct_GetDayExpReward(0)
	if login <= 0 then
		g_ui_list[1].red:Show()
		g_ui_list[1].btn:Show()
		g_ui_list[1].bget:Hide()
	else
		g_ui_list[1].red:Hide()
		g_ui_list[1].btn:Hide()
		g_ui_list[1].bget:Show()
	end

	local actpoint = DataPool:Lua_21Q3SignInAct_GetDayExpReward(1)
	if actpoint <= 0 then
		if nToadyActivePoint >= g_ui_day_actpoint then
			g_ui_list[2].red:Show()
		else
			g_ui_list[2].red:Hide()
		end
		g_ui_list[2].btn:Show()
		g_ui_list[2].bget:Hide()
	else
		g_ui_list[2].red:Hide()
		g_ui_list[2].btn:Hide()
		g_ui_list[2].bget:Show()
	end

	local bgetprice = 0
	local nCurDay = tonumber(DataPool:GetServerDayTime())
	if nCurDay == DataPool:GetPlayerMission_DataRound(g_yqgz_MD) then
		bgetprice = 1
	end
	if bgetprice > 0 then
		g_ui_list[3].bget:Show()
		g_ui_list[3].btn:Hide()
	else
		g_ui_list[3].bget:Hide()
		g_ui_list[3].btn:Show()
	end
	--local login = DataPool:Lua_21Q3SignInAct_GetDayExpReward(0)
end

--=================是否为正确时间=============================
function CRWarmUp_GetTravelValue_IsRightTime()
	local nCurDay = tonumber(DataPool:GetServerDayTime())
	-- 第一阶段
	if nCurDay >= g_Time_Start and nCurDay <= g_TimeStep1_End then
		return 1
	end

	-- 第二阶段
	if nCurDay >= g_TimeStep2_Start and nCurDay <= g_TimeEnd then
		return 2
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
function CRWarmUp_GetTravelValue_BaseCheck()
	-- 时间
	if CRWarmUp_GetTravelValue_IsRightTime() ~= 1 then
		PushDebugMessage("#{MPYR_210830_114}")
		return 0
	end

	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_limitlevel then
		PushDebugMessage("#{MPYR_210830_115}")
		return 0
	end

	-- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage("#{ZJWF_201231_25}")
		return 0
	end

	return 1
end



--================领取奖励==============================
function CRWarmUp_GetTravelValue_GetRewardOnClick(nIndex)
	if CRWarmUp_GetTravelValue_BaseCheck() ~= 1 then
		return
	end

	if nIndex == 1 then
		local nDayReward = DataPool:Lua_21Q3SignInAct_GetDayExpReward(nIndex-1)
		if nDayReward > 0 then
			PushDebugMessage("#{MPYR_210830_116}")
			return
		end
	elseif nIndex == 2 then
		local nWeekReward = DataPool:Lua_21Q3SignInAct_GetDayExpReward(nIndex-1)
		if nWeekReward > 0 then
			PushDebugMessage("#{MPYR_210830_116}")
			return
		end
		local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
		if nToadyActivePoint < g_ui_day_actpoint then
			PushDebugMessage("#{MPYR_210830_125}")
			return
		end
	else
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetExpReward" )
		Set_XSCRIPT_ScriptID( 888772 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_Parameter(1, nIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--================前往NPC==============================
function CRWarmUp_GetTravelValue_GotoOnClick()

	if CRWarmUp_GetTravelValue_IsRightTime() ~= 1 then
		PushDebugMessage("#{MPYR_210830_126}")
		return
	end

	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_limitlevel then
		PushDebugMessage("#{MPYR_210830_127}")
		return
	end

	local tNpc = g_npc_info
	-- 前往NPC
	AutoRuntoTargetExWithName(tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name)
	
end


function CRWarmUp_GetTravelValue_Close()
	this:Hide()
end

function CRWarmUp_GetTravelValue_ResetPos()
	CRWarmUp_GetTravelValue_Frame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end
