-- 2021Q3 预热签到 整合界面

local g_ui_list					= {}
local g_limitlevel				= 30			-- 需要等级

local g_TimeSecStep_Update		= 1				-- 二阶段是否启动

local g_MainUICommandID			= 88877301		-- 打开界面
local g_MainUIRedPoint			= 88877302		-- 刷新红点
local g_MainUIFreshTips			= 88877303		-- 显示Tips
local g_MainUIFreshRedPoint		= 88877304		-- 刷新界面红点

local g_Box_RewardFlag			= 3337			-- 29日宝箱显示标识
local g_frame_unifiedposition	= nil			-- 分辨率变化跟踪数值

local g_Activity_Info = {
	-- 签到
	[1] = {begintime=20211011,endtime=20211117,name="#{MPYR_210830_14}",
			tips="#{MPYR_210830_15}",tipsbefore="#{MPYR_210830_16}",tipsend="#{MPYR_210830_16}",},
	-- 交互
	[2] = {begintime=20211011,endtime=20211028,name="#{MPYR_210830_14}",
			tips="#{XJH_210826_3}",tipsbefore="#{XJH_210826_64}",tipsend="#{XJH_210826_64}",},
	-- 付费
	[3] = {begintime=20211011,endtime=20211115,name="#{MPYR_210830_14}",
			tips="#{XMPYRFF_210826_04}",tipsbefore="#{XMPYRFF_210826_04}",tipsend="#{XMPYRFF_210826_122}",},
	-- 宝箱
	[4] = {begintime=20211029,endtime=20211114,name="#{MPYR_210830_14}",
			tipsbefore="#{MPYR_210830_05}",tipsend="#{MPYR_210830_06}",tipsend="#{MPYR_210830_06}",},
}

local g_npc_info = { x = 246, z = 269, sceneId = 0, name = "朔风", }

function CRWarmUp_Integrate_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CRWarmUp_Integrate_OnLoad()
	g_ui_list = {
		{btn=CRWarmUp_Integrate_SiginIn, red=CRWarmUp_Integrate_SignIn_Tips,},
		{btn=CRWarmUp_Integrate_Interact, red=CRWarmUp_Integrate_Interact_Tips,},
		{btn=CRWarmUp_Integrate_Pay, red=CRWarmUp_Integrate_Pay_Tips,},
		{btn=CRWarmUp_Integrate_BaoXiang, red=CRWarmUp_Integrate_Baoxiang_Tips,},
	}
	g_frame_unifiedposition = CRWarmUp_Integrate_Frame:GetProperty("UnifiedPosition") 
end

function CRWarmUp_Integrate_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == g_MainUICommandID then
		CRWarmUp_Integrate_OnShow()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_MainUIFreshRedPoint then
		CRWarmUp_Integrate_BaseUIUpdate()
		CRWarmUp_Integrate_RedPointUIUpdate()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CRWarmUp_Integrate_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		CRWarmUp_Integrate_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		CRWarmUp_Integrate_Close()
	end
end

--===================================================================================
--*******************************聚一起Start***************************************
--===================================================================================

--=================初始化界面信息==============================
function CRWarmUp_Integrate_OnShow()
	CRWarmUp_Integrate_BaseUIUpdate()
	CRWarmUp_Integrate_RedPointUIUpdate()
	this:Show()
end

--=================基础数据刷新==============================
function CRWarmUp_Integrate_BaseUIUpdate()

	for i, uidata in ipairs(g_Activity_Info) do
		--g_ui_list[i].btn:SetText(uidata.name)

		local nTime = CRWarmUp_Integrate_IsRightTime(i)
		if nTime > 0 then
			g_ui_list[i].btn:SetToolTip(uidata.tips)
		elseif nTime == -1 then
			g_ui_list[i].btn:SetToolTip(uidata.tipsbefore)
		else
			g_ui_list[i].btn:SetToolTip(uidata.tipsend)
		end
	end

	-- 29日宝箱Tips特殊处理
	local nTimeStep = CRWarmUp_Integrate_IsRightTime(4)
	if nTimeStep == 1 and  g_TimeSecStep_Update == 1 then
		g_ui_list[4].btn:SetToolTip("#{MPYR_210830_06}")
	else
		g_ui_list[4].btn:SetToolTip("#{MPYR_210830_05}")
	end

	if Pneuma:GetMF(g_Box_RewardFlag) > 0 then
		g_ui_list[4].btn:Hide()
	else
		g_ui_list[4].btn:Show()
	end

	--CongRenPre_Integrate_DragTitle:SetText("#{MPYR_210830_140}")
end

--=================刷新红点==============================
function CRWarmUp_Integrate_RedPointUIUpdate()
	-- 根据参数显示
	local curday,cnt = Get_XParam_INT(0), table.getn(g_ui_list)
	for i=1,cnt  do
		local state = Get_XParam_INT(i)
		if state > 0 then
			g_ui_list[i].red:Show()
		else
			g_ui_list[i].red:Hide()
		end
	end
end

--=================是否为正确时间=============================
function CRWarmUp_Integrate_IsRightTime(nIndex)
	local cnt = table.getn(g_Activity_Info)
	if nIndex < 0 or nIndex > cnt then
		return 0
	end

	local info = g_Activity_Info[nIndex]
	local nCurDay = tonumber(DataPool:GetServerDayTime())
	-- 第一阶段
	if nCurDay >= info.begintime and nCurDay <= info.endtime then
		return 1
	end

	-- 活动未开启
	if nCurDay < info.begintime then
		return -1
	end

	-- 活动已结束
	if nCurDay > info.endtime then
		return -2
	end

	return 0
end

--=================基础条件检查=============================
function CRWarmUp_Integrate_BaseCheck()
	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_limitlevel then
		PushDebugMessage("#{MPYR_210830_104}")
		return 0
	end

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

function CRWarmUp_Integrate_Close()
	this:Hide()
end

function CRWarmUp_Integrate_ResetPos()
	CRWarmUp_Integrate_Frame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end

--=================点击活动页签==============================
function CRWarmUp_Integrate_ActivityOnClick(nIndex)
	-- 签到
	if nIndex == 1 then
		CRWarmUp_Integrate_SignInOnClick()
		return
	end

	-- 交互
	if nIndex == 2 then
		CRWarmUp_Integrate_TouhuOnClick()
		return
	end

	-- 付费
	if nIndex == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenUI" )
			Set_XSCRIPT_ScriptID( 888765 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		return
	end

	-- 29日宝箱
	if nIndex == 4 then
		CRWarmUp_Integrate_29BoxOnClick()
		return
	end
end


function CRWarmUp_Integrate_SignInOnClick()
	local nLevel = Player:GetLevel()
	if nLevel < g_limitlevel then
		PushDebugMessage("#{MPYR_210830_17}")
		return
	end
	local nStep = CRWarmUp_Integrate_IsRightTime(1)
	if nStep < 1 then
		PushDebugMessage("#{MPYR_210830_18}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIEvent" )
		Set_XSCRIPT_ScriptID( 888772 )
		Set_XSCRIPT_Parameter(0,-1)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function CRWarmUp_Integrate_TouhuOnClick()
	local nStep = CRWarmUp_Integrate_IsRightTime(2)
	if nStep ~= 1 then
		PushDebugMessage("#{XJH_210826_1}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_limitlevel then
		PushDebugMessage("#{XJH_210826_2}")
		return
	end
	-- 前往NPC
	local tNpc = g_npc_info
	AutoRuntoTargetExWithName(tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name)
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RedPointClicked" )
		Set_XSCRIPT_ScriptID( 888770 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function CRWarmUp_Integrate_29BoxOnClick()
	local nStep = CRWarmUp_Integrate_IsRightTime(4)
	if nStep ~= 1 or g_TimeSecStep_Update ~= 1 then
		if nStep == -2 then
			PushDebugMessage("#{MPYR_210830_12}")
		else
			PushDebugMessage("#{MPYR_210830_194}")
		end
		return
	end

	local nLevel = Player:GetLevel()
	if nLevel < g_limitlevel then
		PushDebugMessage("#{MPYR_210830_13}")
		return
	end

	if Pneuma:GetMF(g_Box_RewardFlag) > 0 then
		PushDebugMessage("#{MPYR_210830_141}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetBoxReward" )
		Set_XSCRIPT_ScriptID( 888774 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
