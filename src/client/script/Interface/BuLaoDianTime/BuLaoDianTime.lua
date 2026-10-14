
local g_BuLaoDianTime_UnifiedPosition

local g_BuLaoDianTime_UICommand = 99853001
local g_BuLaoDianTime_opType = {
	show = 1,						-- 显示UI
	init = 2,						-- 初始化UI
	close = 1000,					-- 关闭UI
}

local g_BuLaoDianTime_TimerInfo = {
	[1] = {hour=16,min=0,sec=0,txt="#{TJZF_230525_153}",},
	[2] = {hour=22,min=0,sec=0,txt="#{TJZF_230525_154}",},
}

local g_Data = {}
local g_KeyMax = 40					-- 钥匙最大数量

function BuLaoDianTime_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS", false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)		
end
--界面21点50到24点显示
function BuLaoDianTime_OnLoad()
	g_BuLaoDianTime_UnifiedPosition = BuLaoDianTime:GetProperty("UnifiedPosition")
end

function BuLaoDianTime_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_BuLaoDianTime_UICommand then
		g_Data = {}
		local opType =  Get_XParam_INT( 0 )
		-- 场景
		g_Data.Scene = Get_XParam_INT( 1 )
		-- 获取奖励次数
		g_Data.Reward = Get_XParam_INT( 2 )
		-- 代币数量
		g_Data.Key = Get_XParam_INT( 3 )
		-- 时间类型
		g_Data.TimeType = Get_XParam_INT( 4 )
		-- BOSS
		g_Data.BossSS = Get_XParam_INT( 5 )
		g_Data.BossYS = Get_XParam_INT( 6 )

		if opType == g_BuLaoDianTime_opType.show then
			BuLaoDianTime_Show()
			BuLaoDianTime_InitFrame()
		elseif opType == g_BuLaoDianTime_opType.init then
			if (this:IsVisible()) then
				BuLaoDianTime_InitFrame()
			end
		elseif opType == g_BuLaoDianTime_opType.close then
			if (this:IsVisible()) then
				BuLaoDianTime_Hide()
			end
		else
			if (this:IsVisible()) then
				BuLaoDianTime_Hide()
			end
		end
	-- 游戏窗口尺寸发生了变化
	elseif event == "ADJEST_UI_POS" then
		BuLaoDianTime_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		BuLaoDianTime_On_ResetPos()
	elseif event == "PLAYER_LEAVE_WORLD" then
		BuLaoDianTime_Hide()
	end	
end

--显示UI
function BuLaoDianTime_Show()

	if(IsWindowShow("BuLaoDianTime_Mini")) then
		CloseWindow("BuLaoDianTime_Mini", true)
	end
	this:Show()
	SetTimer("BuLaoDianTime","BuLaoDianTime_Timer()", 1000)
end

--隐藏UI
function BuLaoDianTime_Hide()
	this:Hide()
end

function BuLaoDianTime_Timer()
	--local curTime = tonumber(DataPool:GetServerMinuteTime())
	--if curTime >= 202000 and curTime < 202003 then	
	--	BuLaoDianTime_Text:SetText("#{MJXZ_210510_251}")
	--end
end
function BuLaoDianTime_On_ResetPos()
	BuLaoDianTime:SetProperty("UnifiedPosition", g_BuLaoDianTime_UnifiedPosition)
end

function BuLaoDianTime_InitFrame()
	-- 奖励次数
	local szReward = ScriptGlobal_Format("#{TJZF_230525_20}", g_Data.Reward)
	BuLaoDianTime_Award:SetText(szReward)
	-- 代币进度条
	local szKey = ScriptGlobal_Format("#{TJZF_230525_22}", g_Data.Key)
	BuLaoDianTime_Num:SetText(szKey)

	-- 活动结束时间
	local timer = 0
	local szTxt = "#{TJZF_230525_154}"
	local timerinfo = g_BuLaoDianTime_TimerInfo[g_Data.TimeType]
	if timerinfo ~= nil then
		szTxt = timerinfo.txt
		timer = Lua_GetDiffTime_InSecond_ServerTime(timerinfo.hour,timerinfo.min,timerinfo.sec)
	end

	if timer > 0 then
		BuLaoDianTime_Time:SetProperty("Timer", timer)
	else
		BuLaoDianTime_Time:SetProperty("Timer", 0)
	end
	BuLaoDianTime_Time:SetProperty("TextColor","FFFFF263")

	-- 提示
	BuLaoDianTime_Text:SetText(szTxt)

	local szSS =  "#cfff263"..tostring(g_Data.BossSS)
	local szYS = "#cfff263"..tostring(g_Data.BossYS)
	-- 上生台
	BuLaoDianTime_QinYongNum:SetText(szSS)
	-- 延寿台
	BuLaoDianTime_QinYongNum2:SetText(szYS)
end

function BuLaoDianTime_OnTimerEnd()
end

function BuLaoDianTime_OpenMini()
	PushEvent("OPEN_TJC_PVP_MINI")
	this:Hide()
end

function BuLaoDianTime_OnHiden()
	KillTimer("BuLaoDianTime_Timer()")
end

function BuLaoDianTime_Help()
	-- 借用一下别人的通道
	PushEvent("CCSHOP_HELP", 197)
end 