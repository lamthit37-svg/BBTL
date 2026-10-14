-- 2021Q3 预热签到 批量购买界面

local g_limitlevel = 30				-- 需要等级

local g_Time_Start				= 20211011		-- 20211011
local g_TimeStep1_End			= 20211028		-- 20211028
local g_TimeStep2_Start			= 20211029		-- 20211029		-- 29日宝箱开启时间
local g_TimeBox_End				= 20211114		-- 29日宝箱结束时间
local g_TimeEnd					= 20211117

local g_TimeSecStep_Update		= 1				-- 二阶段是否启动

local g_Item_ID 				= 39923604		-- 神秘宝箱展示ID
local g_LotteryMax				= 5
local g_Buy_Cost				= 8000			-- 购买一次消耗的元宝
local g_CurBuyNum				= 1
local g_Limitlevel				= 30			-- 限制等级
local g_frame_unifiedposition = nil				-- 分辨率变化跟踪数值

function CRWarmUp_BuyMiXin_PreLoad()
	this:RegisterEvent("OPEN_21Q3ACT_SIGNIN_OTHER")
	this:RegisterEvent("UPDATE_21Q3ACT_SIGNIN",false)
	this:RegisterEvent("UPDATE_YUANBAO",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CRWarmUp_BuyMiXin_OnLoad()

	g_frame_unifiedposition = CRWarmUp_BuyMiXin_Frame:GetProperty("UnifiedPosition") 
end

function CRWarmUp_BuyMiXin_OnEvent(event)
	if event == "OPEN_21Q3ACT_SIGNIN_OTHER" and tonumber(arg0) == 3 then
		CRWarmUp_BuyMiXin_OnShow()
	elseif event == "UPDATE_21Q3ACT_SIGNIN" then
		CRWarmUp_BuyMiXin_BaseUIUpdate()
	elseif event == "UPDATE_YUANBAO" then
		CRWarmUp_BuyMiXin_BaseUIUpdate()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CRWarmUp_BuyMiXin_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		CRWarmUp_BuyMiXin_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		CRWarmUp_BuyMiXin_Close()
	end
end

--===================================================================================
--*******************************聚一起Start***************************************
--===================================================================================

--=================初始化界面信息==============================
function CRWarmUp_BuyMiXin_OnShow()
	CRWarmUp_BuyMiXin_BaseUIUpdate()
	this:Show()
end

--=================基础数据刷新==============================
function CRWarmUp_BuyMiXin_BaseUIUpdate()

	local action = DataPool:CreateActionItemForShow(g_Item_ID, 1) 
	if action:GetID() ~= 0 then
		CRWarmUp_BuyMiXin_Item:SetActionItem( action:GetID() )
	else
		CRWarmUp_BuyMiXin_Item:SetActionItem( -1 )
	end
	
	CRWarmUp_BuyMiXin_ItemInfo_Text:SetText("#{MPYR_210830_186}")

	local szShowYB = ScriptGlobal_Format("#{MPYR_210830_148}", g_Buy_Cost)
	CRWarmUp_BuyMiXin_ItemInfo_YuanBao:SetText(szShowYB)

	local nYuanbao = Player:GetData("YUANBAO")
	local szOwnYB = ScriptGlobal_Format("#{MPYR_210830_156}", nYuanbao)
	CRWarmUp_BuyMiXin_CashNum:SetText(szOwnYB)

	local cost = g_Buy_Cost*g_CurBuyNum
	local szCost = ScriptGlobal_Format("#{MPYR_210830_152}", cost)
	if nYuanbao < cost then
		szCost = ScriptGlobal_Format("#{MPYR_210830_153}", cost)
		szCost = "#cff0000" .. szCost 
	else
		szCost = ScriptGlobal_Format("#{MPYR_210830_153}", cost)
		szCost = "#G" .. szCost 
	end

	CRWarmUp_BuyMiXin_PriceNum:SetText(szCost)

	local total = 0
	for i=1, g_LotteryMax do
		local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
		if reward > 0 then
			total = total + 1
		end
	end


	local lotterycnt = g_LotteryMax - total
	if lotterycnt > 0 then
		CRWarmUp_BuyMiXin_Item_BuyLimitNum:SetText(tostring(lotterycnt))
		CRWarmUp_BuyMiXin_Item_BuyLimitNumBK:Show()
		CRWarmUp_BuyMiXin_Item_Mask:Hide()
	else
		CRWarmUp_BuyMiXin_Item_Mask:Show()
		CRWarmUp_BuyMiXin_Item_BuyLimitNumBK:Hide()
	end

	CRWarmUp_BuyMiXin_InputNumBK:SetTextOriginal(tostring(g_CurBuyNum))

end


--=================是否为正确时间=============================
function CRWarmUp_BuyMiXin_IsRightTime()
	local nCurDay = tonumber(DataPool:GetServerDayTime())
	-- 第一阶段
	if nCurDay >= g_Time_Start and nCurDay <= g_TimeStep1_End then
		return 1
	end

	-- 第二阶段
	if nCurDay >= g_TimeStep2_Start and nCurDay <= g_TimeBox_End and g_TimeSecStep_Update > 0 then
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
function CRWarmUp_BuyMiXin_BaseCheck()
	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_Limitlevel then
		PushDebugMessage("#{MPYR_210830_171}")
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
		PushDebugMessage("#{FCMX_90609_22}")
		return 0
	end

	return 1
end

--=================文字变化==============================
function CRWarmUp_BuyMiXin_TextChanged()

	local num = tonumber(CRWarmUp_BuyMiXin_InputNumBK:GetText())
	if num == nil then
		g_CurBuyNum = 0
		return
	elseif num <= 0  then
		g_CurBuyNum = 0
		return
	else
		--local total = 0
		--for i=1, g_LotteryMax do
		--	local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
		--	if reward > 0 then
		--		total = total + 1
		--	end
		--end
		--local max = g_LotteryMax - total
		--if num > max then
		--	g_CurBuyNum = max
		--else
		--	g_CurBuyNum = num
		--end
		g_CurBuyNum = num
	end

	CRWarmUp_BuyMiXin_BaseUIUpdate()
end

--=================最大==============================
function CRWarmUp_BuyMiXin_CalMax()
	local total = 0
	for i=1, g_LotteryMax do
		local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
		if reward > 0 then
			total = total + 1
		end
	end

	local num = g_LotteryMax - total
	g_CurBuyNum = num
	CRWarmUp_BuyMiXin_BaseUIUpdate()
end

--=================点击购买按钮==============================
function CRWarmUp_BuyMiXin_OK_Clicked(nIndex)
	local nTimeType = CRWarmUp_BuyMiXin_IsRightTime()
	if nTimeType ~= 2 then
		if nTimeType <= -2 then
			PushDebugMessage("#{MPYR_210830_170}")
		else
			PushDebugMessage("#{MPYR_210830_217}")
		end
		return
	end

	if CRWarmUp_BuyMiXin_BaseCheck() < 1 then
		return
	end

	if g_CurBuyNum < 1 then
		PushDebugMessage("#{MPYR_210830_173}")
		return
	end

	local nYuanbao = Player:GetData("YUANBAO")
	local cost = g_Buy_Cost*g_CurBuyNum
	if nYuanbao < cost then
		PushDebugMessage("#{MPYR_210830_174}")
		return
	end

	local total = 0
	for i=1, g_LotteryMax do
		local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
		if reward > 0 then
			total = total + 1
		end
	end

	if total + g_CurBuyNum > g_LotteryMax then
		PushDebugMessage("#{MPYR_210830_175}")
		return
	end

	if total >= g_LotteryMax then
		PushDebugMessage("#{MPYR_210830_176}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyLotteryLiBao" )
		Set_XSCRIPT_ScriptID( 888772 )
		Set_XSCRIPT_Parameter(0, g_CurBuyNum)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()


	CRWarmUp_BuyMiXin_Close()
end

--=================关闭==============================
function CRWarmUp_BuyMiXin_Close_Clicked()
	CRWarmUp_BuyMiXin_Close()
end

function CRWarmUp_BuyMiXin_Close()
	g_CurBuyNum = 1
	this:Hide()
end

function CRWarmUp_BuyMiXin_ResetPos()
	CRWarmUp_BuyMiXin_Frame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end



