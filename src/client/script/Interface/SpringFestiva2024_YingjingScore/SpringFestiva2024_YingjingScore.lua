--******************************************************************************
-- 分数界面
--******************************************************************************
local g_SpringFestiva2024_YingjingScore_Frame_UnifiedXPosition
local g_SpringFestiva2024_YingjingScore_Frame_UnifiedYPosition

--UI
local g_SpringFestiva2024_YingjingScore_ScoreUI  --分数
local g_SpringFestiva2024_YingjingScore_TimeUI  --剩余时间

--计数
local g_SpringFestiva2024_YingjingScore_Time = -1 --显示的数字：5、60秒倒计时
local g_SpringFestiva2024_YingjingScore_Score = -1 --当前得分

--常量
local g_SpringFestiva2024_YingjingScore_PerfectScore = 100 --奖励分数线
local g_SpringFestiva2024_YingjingScore_BaseScore = 60
local g_SpringFestiva2024_YingjingScore_GameTime = 120  --游戏时间
local g_SpringFestiva2024_YingjingScore_SuccTime = 60  --成功时最长显示时间


--===============================================
-- OnLoad()
--===============================================
function SpringFestiva2024_YingjingScore_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true)
end

function SpringFestiva2024_YingjingScore_OnLoad()

	-- 保存界面的默认相对位置
	g_SpringFestiva2024_YingjingScore_Frame_UnifiedXPosition = SpringFestiva2024_YingjingScore_Frame:GetProperty("UnifiedXPosition")
	g_SpringFestiva2024_YingjingScore_Frame_UnifiedYPosition = SpringFestiva2024_YingjingScore_Frame:GetProperty("UnifiedYPosition")

	--分数
	g_SpringFestiva2024_YingjingScore_ScoreUI = SpringFestiva2024_YingjingScore_Point
	--剩余时间
	g_SpringFestiva2024_YingjingScore_TimeUI = SpringFestiva2024_YingjingScore_Time


	--设置时间
	local str = ScriptGlobal_Format("#{XXJQ_20231130_78}",tostring(g_SpringFestiva2024_YingjingScore_GameTime))
	g_SpringFestiva2024_YingjingScore_TimeUI:SetText(str)
	
	--设置分数
	local scoreStr = ScriptGlobal_Format("#{XXJQ_20231130_80}" ,tostring(0))
	g_SpringFestiva2024_YingjingScore_ScoreUI:SetText(scoreStr)

end


--===============================================
-- OnEvent()
--===============================================

function SpringFestiva2024_YingjingScore_OnEvent(event)
	if(event == "UI_COMMAND") then

		local arg = tonumber(arg0)

		--更新时间
		if arg == 99896402 then
			local correctTime = Get_XParam_INT(0)

				g_SpringFestiva2024_YingjingScore_Time = g_SpringFestiva2024_YingjingScore_GameTime - correctTime
				if g_SpringFestiva2024_YingjingScore_Time < 0 then
					g_SpringFestiva2024_YingjingScore_Time = 0
				end
				local str = ScriptGlobal_Format("#{XXJQ_20231130_78}",tostring(g_SpringFestiva2024_YingjingScore_Time))
				g_SpringFestiva2024_YingjingScore_TimeUI:SetText(str)
				SpringFestiva2024_YingjingScore_Frame_On_ResetPos()
				this:Show()

		--更新分数
		elseif arg == 99896403 then
			local score = Get_XParam_INT(0)
			g_SpringFestiva2024_YingjingScore_Score = 0
			g_SpringFestiva2024_YingjingScore_Score = score
			local dic = "#{XXJQ_20231130_80}"
			if g_SpringFestiva2024_YingjingScore_Score >= 60 and g_SpringFestiva2024_YingjingScore_Score <= 99 then
				dic = "#{XXJQ_20231130_81}"
			elseif g_SpringFestiva2024_YingjingScore_Score > 99 then
				dic = "#{XXJQ_20231130_82}"
			end
			local scoreStr = ScriptGlobal_Format(dic ,tostring(g_SpringFestiva2024_YingjingScore_Score))
			g_SpringFestiva2024_YingjingScore_ScoreUI:SetText(scoreStr)
			SpringFestiva2024_YingjingScore_Frame_On_ResetPos()
			---分数满100后，强制进入倒计时5秒关闭界面流程
			if g_SpringFestiva2024_YingjingScore_Score >= g_SpringFestiva2024_YingjingScore_PerfectScore then
				SpringFestiva2024_YingjingScore_Close_GameOn()
			end
		--打开界面
		elseif arg == 99896404 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				local npcid = Get_XParam_INT(1)
				DataPool:SelectAsTargetByObjID(npcid)

				--设置时间
				local str = ScriptGlobal_Format("#{XXJQ_20231130_78}",tostring(g_SpringFestiva2024_YingjingScore_GameTime))
				g_SpringFestiva2024_YingjingScore_TimeUI:SetText(str)

				--设置分数
				local scoreStr = ScriptGlobal_Format("#{XXJQ_20231130_80}" ,tostring(0))
				g_SpringFestiva2024_YingjingScore_ScoreUI:SetText(scoreStr)

				SpringFestiva2024_YingjingScore_Frame_On_ResetPos()
				this:Show()
			elseif param == 0 then
				this:Hide()
			end
		end
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		SpringFestiva2024_YingjingScore_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		SpringFestiva2024_YingjingScore_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		SpringFestiva2024_YingjingScore_Close()
	end
end

--===============================================
-- 游戏结束
--===============================================
function SpringFestiva2024_YingjingScore_Close_GameOn()
	SpringFestiva2024_YingjingScore_OnHiden()
	this:Hide()
end

function SpringFestiva2024_YingjingScore_Close()
	SpringFestiva2024_YingjingScore_OnHiden()
	this:Hide()
end


--===============================================
-- OnHiden
--===============================================
function SpringFestiva2024_YingjingScore_OnHiden()
	g_SpringFestiva2024_YingjingScore_Time = -1
	g_SpringFestiva2024_YingjingScore_Score = -1

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SpringFestiva2024_YingjingScore_Frame_On_ResetPos()
	SpringFestiva2024_YingjingScore_Frame : SetProperty("UnifiedXPosition", g_SpringFestiva2024_YingjingScore_Frame_UnifiedXPosition)
	SpringFestiva2024_YingjingScore_Frame : SetProperty("UnifiedYPosition", g_SpringFestiva2024_YingjingScore_Frame_UnifiedYPosition)
end
