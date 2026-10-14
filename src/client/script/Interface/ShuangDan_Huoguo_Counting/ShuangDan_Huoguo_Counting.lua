--******************************************************************************
-- 分数界面
--******************************************************************************
local g_ShuangDan_Huoguo_Counting_Frame_UnifiedXPosition;
local g_ShuangDan_Huoguo_Counting_Frame_UnifiedYPosition;

--UI
local g_ShuangDan_Huoguo_Counting_ScoreUI  --分数
local g_ShuangDan_Huoguo_Counting_TimeUI  --剩余时间

local g_ShuangDan_Huoguo_Counting_CurNPC = -1


--计数
local g_ShuangDan_Huoguo_Counting_Time = -1 --显示的数字：5、60秒倒计时
local g_ShuangDan_Huoguo_Counting_Score = -1 --当前得分

--常量
local g_ShuangDan_Huoguo_Counting_PerfectScore = 200 --奖励分数线
local g_ShuangDan_Huoguo_Counting_BaseScore = 100
local g_ShuangDan_Huoguo_Counting_GameTime = 120  --游戏时间
local g_ShuangDan_Huoguo_Counting_SuccTime = 60  --成功时最长显示时间


--===============================================
-- OnLoad()
--===============================================
function ShuangDan_Huoguo_Counting_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function ShuangDan_Huoguo_Counting_OnLoad()

	-- 保存界面的默认相对位置
	g_ShuangDan_Huoguo_Counting_Frame_UnifiedXPosition = ShuangDan_Huoguo_Counting_Frame:GetProperty("UnifiedXPosition");
	g_ShuangDan_Huoguo_Counting_Frame_UnifiedYPosition = ShuangDan_Huoguo_Counting_Frame:GetProperty("UnifiedYPosition");
	
	--分数
	g_ShuangDan_Huoguo_Counting_ScoreUI = ShuangDan_Huoguo_Counting_Point
	--剩余时间
	g_ShuangDan_Huoguo_Counting_TimeUI = ShuangDan_Huoguo_Counting_Time
	
	
end


--===============================================
-- OnEvent()
--===============================================

function ShuangDan_Huoguo_Counting_OnEvent(event)
	if(event == "UI_COMMAND") then

		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 88881302 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				
				local npcid = Get_XParam_INT(1)
				KillTimer("ShuangDan_Huoguo_Counting_GameOn()")
				KillTimer("ShuangDan_Huoguo_Counting_Close_GameOn()")
				KillTimer("ShuangDan_Huoguo_Counting_GameOver()")
				KillTimer("ShuangDan_Huoguo_Counting_Close_GameOver()")
				g_ShuangDan_Huoguo_Counting_Score = 0			
				g_ShuangDan_Huoguo_Counting_Time = g_ShuangDan_Huoguo_Counting_GameTime
				if g_ShuangDan_Huoguo_Counting_Time < 0 then
					g_ShuangDan_Huoguo_Counting_Time = 0
				end
				local str = ScriptGlobal_Format("#{BWQH_211027_79}",tostring(g_ShuangDan_Huoguo_Counting_Time))
				g_ShuangDan_Huoguo_Counting_TimeUI:SetText(str)
				--PushDebugMessage("g_ShuangDan_Huoguo_Counting_Time1 = "..g_ShuangDan_Huoguo_Counting_Time)	
				SetTimer("ShuangDan_Huoguo_Counting","ShuangDan_Huoguo_Counting_GameOn()", 1000)
				SetTimer("ShuangDan_Huoguo_Counting","ShuangDan_Huoguo_Counting_Close_GameOn()", g_ShuangDan_Huoguo_Counting_GameTime*1000)
				DataPool:SelectAsTargetByObjID(npcid)
				g_ShuangDan_Huoguo_Counting_CurNPC = npcid
				ShuangDan_Huoguo_Counting_Frame_On_ResetPos()
				this:Show()
				
			elseif param == 0 then
				ShuangDan_Huoguo_Counting_Close()
				return				
			end
		
		--更新分数
		elseif arg == 88881303 then
			local score = Get_XParam_INT(0)
			local correctTime = Get_XParam_INT(1)
			g_ShuangDan_Huoguo_Counting_Score = score
			local dic = "#{BWQH_211027_80}"
			if g_ShuangDan_Huoguo_Counting_Score >= 180 then
				dic = "#{BWQH_211027_110}"
			elseif g_ShuangDan_Huoguo_Counting_Score >= 100 then
				dic = "#{BWQH_211027_109}"
			end
			local scoreStr = ScriptGlobal_Format(dic ,tostring(g_ShuangDan_Huoguo_Counting_Score))
			g_ShuangDan_Huoguo_Counting_ScoreUI:SetText(scoreStr)
			
			g_ShuangDan_Huoguo_Counting_Time = g_ShuangDan_Huoguo_Counting_GameTime - correctTime
			--PushDebugMessage(ScriptGlobal_Format("#{XJH_210826_41}", g_ShuangDan_Huoguo_Counting_Time))
			if g_ShuangDan_Huoguo_Counting_Time < 0 then
				g_ShuangDan_Huoguo_Counting_Time = 0
			end
			local str = ScriptGlobal_Format("#{BWQH_211027_79}",tostring(g_ShuangDan_Huoguo_Counting_Time))
			g_ShuangDan_Huoguo_Counting_TimeUI:SetText(str)
			--PushDebugMessage("g_ShuangDan_Huoguo_Counting_Time2 = "..g_ShuangDan_Huoguo_Counting_Time)
			KillTimer("ShuangDan_Huoguo_Counting_Close_GameOn()")
			KillTimer("ShuangDan_Huoguo_Counting_GameOn()")
			SetTimer("ShuangDan_Huoguo_Counting","ShuangDan_Huoguo_Counting_GameOn()", 1000)
			SetTimer("ShuangDan_Huoguo_Counting","ShuangDan_Huoguo_Counting_Close_GameOn()", (g_ShuangDan_Huoguo_Counting_Time)*1000)
			ShuangDan_Huoguo_Counting_Frame_On_ResetPos()
			this:Show()
			---分数满180后，强制进入倒计时5秒关闭界面流程
			if g_ShuangDan_Huoguo_Counting_Score >= g_ShuangDan_Huoguo_Counting_PerfectScore then
				ShuangDan_Huoguo_Counting_Close_GameOn()
			end
		elseif arg == 88877101 then  --投掷结果
			
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		ShuangDan_Huoguo_Counting_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		ShuangDan_Huoguo_Counting_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ShuangDan_Huoguo_Counting_Close()
	end
end

--===============================================
-- 游戏开始 每秒更新界面倒计时
--===============================================	
function ShuangDan_Huoguo_Counting_GameOn()
	g_ShuangDan_Huoguo_Counting_Time = g_ShuangDan_Huoguo_Counting_Time - 1
	if g_ShuangDan_Huoguo_Counting_Time < 0 then
		g_ShuangDan_Huoguo_Counting_Time = 0
	end
	local str = ScriptGlobal_Format("#{BWQH_211027_79}",tostring(g_ShuangDan_Huoguo_Counting_Time))
	g_ShuangDan_Huoguo_Counting_TimeUI:SetText(str)
	--PushDebugMessage(g_ShuangDan_Huoguo_Counting_Time.."秒之后游戏结束")
end

--===============================================
-- 游戏结束
--===============================================	
function ShuangDan_Huoguo_Counting_Close_GameOn()
	--停止倒计时文字显示
	KillTimer("ShuangDan_Huoguo_Counting_GameOn()")
	KillTimer("ShuangDan_Huoguo_Counting_Close_GameOn()")
	
	--开启60s倒计时
	g_ShuangDan_Huoguo_Counting_Time = g_ShuangDan_Huoguo_Counting_SuccTime
	local str = ScriptGlobal_Format("#{BWQH_211027_79}","0")
	g_ShuangDan_Huoguo_Counting_TimeUI:SetText(str)
	SetTimer("ShuangDan_Huoguo_Counting","ShuangDan_Huoguo_Counting_GameOver()", 1000)	
	SetTimer("ShuangDan_Huoguo_Counting","ShuangDan_Huoguo_Counting_Close_GameOver()", g_ShuangDan_Huoguo_Counting_SuccTime*1000)

end

--===============================================
-- 刷新60秒倒计时文字显示：X秒后停止投壶
--===============================================	
function ShuangDan_Huoguo_Counting_GameOver()
	g_ShuangDan_Huoguo_Counting_Time = g_ShuangDan_Huoguo_Counting_Time - 1
	--PushDebugMessage(g_ShuangDan_Huoguo_Counting_Time.."秒之后强制关闭界面")
end

--===============================================
-- 关闭倒计时文字显示：X秒后停止投壶
-- 60秒计时满后，更新文字
--===============================================	
function ShuangDan_Huoguo_Counting_Close_GameOver()
	--停止倒计时文字显示
	KillTimer("ShuangDan_Huoguo_Counting_GameOver()")
	KillTimer("ShuangDan_Huoguo_Counting_Close_GameOver()")
	ShuangDan_Huoguo_Counting_Close()
end

function ShuangDan_Huoguo_Counting_Close()
	ShuangDan_Huoguo_Counting_OnHiden()
end


--===============================================
-- OnHiden
--===============================================
function ShuangDan_Huoguo_Counting_OnHiden()
	g_ShuangDan_Huoguo_Counting_Time = -1
	g_ShuangDan_Huoguo_Counting_Score = -1
	g_ShuangDan_Huoguo_Counting_CurNPC = -1
	local scorestr = ScriptGlobal_Format("#{BWQH_211027_80}","0")
	g_ShuangDan_Huoguo_Counting_ScoreUI:SetText(scorestr)
	local str = ScriptGlobal_Format("#{BWQH_211027_79}","0")
	g_ShuangDan_Huoguo_Counting_TimeUI:SetText(str)
	KillTimer("ShuangDan_Huoguo_Counting_GameOn()")
	KillTimer("ShuangDan_Huoguo_Counting_Close_GameOn()")
	KillTimer("ShuangDan_Huoguo_Counting_GameOver()")
	KillTimer("ShuangDan_Huoguo_Counting_Close_GameOver()")
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ShuangDan_Huoguo_Counting_Frame_On_ResetPos()
	ShuangDan_Huoguo_Counting_Frame : SetProperty("UnifiedXPosition", g_ShuangDan_Huoguo_Counting_Frame_UnifiedXPosition);
	ShuangDan_Huoguo_Counting_Frame : SetProperty("UnifiedYPosition", g_ShuangDan_Huoguo_Counting_Frame_UnifiedYPosition);
end
