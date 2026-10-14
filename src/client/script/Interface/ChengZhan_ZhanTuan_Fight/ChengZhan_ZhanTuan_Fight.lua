--!!!reloadscript =ChengZhan_ZhanTuan_Fight

local g_ChengZhan_ZhanTuan_Fight_Frame_UnifiedXPosition
local g_ChengZhan_ZhanTuan_Fight_Frame_UnifiedYPosition
--local g_ChengZhan_ZhanTuan_Fight_Mini = 0

local m_UIZhanTuanInfo = nil
local m_UITextButton = nil
local m_UITextButton2 = nil
local g_ChengZhan_ZhanTuan_nMaxScore = 10000

local g_ChengZhan_ZhanTuan_Fight_Step = 0
local g_ChengZhan_ZhanTuan_Fight_nTick = 0
local g_ChengZhan_ZhanTuan_Fight_nKillNum = 0
local g_ChengZhan_ZhanTuan_Fight_Team = 0
local g_ChengZhan_ZhanTuan_Fight_Text = 0

local g_ChengZhan_ZhanTuan_Fight_nZhanTuanID = {}
local g_ChengZhan_ZhanTuan_Fight_nScore = {}	
local g_ChengZhan_ZhanTuan_Fight_nGuildName = {}	

local g_ChengZhan_ZhanTuan_Fight_ZhanTuanTips = 
{
	[1] = "#{ZTPVP_260515_15}", --1号战团
	[2] = "#{ZTPVP_260515_16}", --2号战团
	[3] = "#{ZTPVP_260515_17}", --3号战团
	[4] = "#{ZTPVP_260515_18}", --4号战团
	[5] = "#{ZTPVP_260515_19}", --5号战团
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function ChengZhan_ZhanTuan_Fight_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ChengZhan_ZhanTuan_Fight_OnLoad()
	-- 保存界面的默认相对位置
	g_ChengZhan_ZhanTuan_Fight_Frame_UnifiedXPosition	= ChengZhan_ZhanTuan_Fight_Frame:GetProperty("UnifiedXPosition");
	g_ChengZhan_ZhanTuan_Fight_Frame_UnifiedYPosition	= ChengZhan_ZhanTuan_Fight_Frame:GetProperty("UnifiedYPosition");

	m_UIZhanTuanInfo = {}
	m_UIZhanTuanInfo[1] = ChengZhan_ZhanTuan_Fight_P1
	m_UIZhanTuanInfo[2] = ChengZhan_ZhanTuan_Fight_P2

	m_UITextButton = {}
	m_UITextButton[1] = ChengZhan_ZhanTuan_Fight_SufferBK_Jindu
	m_UITextButton[2] = ChengZhan_ZhanTuan_Fight_SufferBK1_Jindu

	m_UITextButton2 = {}
	m_UITextButton2[1] = ChengZhan_ZhanTuan_Fight_SufferBK_Txt
	m_UITextButton2[2] = ChengZhan_ZhanTuan_Fight_SufferBK1_Txt
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ChengZhan_ZhanTuan_Fight_ResetPos()
	ChengZhan_ZhanTuan_Fight_Frame:SetProperty("UnifiedXPosition", g_ChengZhan_ZhanTuan_Fight_Frame_UnifiedXPosition);
	ChengZhan_ZhanTuan_Fight_Frame:SetProperty("UnifiedYPosition", g_ChengZhan_ZhanTuan_Fight_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function ChengZhan_ZhanTuan_Fight_OnEvent(event)
	if event == "UI_COMMAND" and (tonumber(arg0) == 90001602) then

		g_ChengZhan_ZhanTuan_Fight_nGuildName[1] = Get_XParam_STR(0);
		g_ChengZhan_ZhanTuan_Fight_nGuildName[2] = Get_XParam_STR(1);

		g_ChengZhan_ZhanTuan_Fight_nZhanTuanID[1] = Get_XParam_INT(0);
		g_ChengZhan_ZhanTuan_Fight_nScore[1] = Get_XParam_INT(1);
		g_ChengZhan_ZhanTuan_Fight_nZhanTuanID[2] = Get_XParam_INT(2);
		g_ChengZhan_ZhanTuan_Fight_nScore[2] = Get_XParam_INT(3);
		g_ChengZhan_ZhanTuan_Fight_nTick = Get_XParam_INT(4);
		g_ChengZhan_ZhanTuan_Fight_nKillNum = Get_XParam_INT(5);
		g_ChengZhan_ZhanTuan_Fight_Step = Get_XParam_INT(6);
		g_ChengZhan_ZhanTuan_Fight_Team = Get_XParam_INT(7);
		g_ChengZhan_ZhanTuan_Fight_Text = Get_XParam_INT(8);

		if (this:IsVisible()) then
			ChengZhan_ZhanTuan_Fight_Update()
			return
		end
		--打开界面
		ChengZhan_ZhanTuan_Fight_Show()
		ChengZhan_ZhanTuan_Fight_Update()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ChengZhan_ZhanTuan_Fight_OnHide()
	elseif event == "ADJEST_UI_POS" then
		ChengZhan_ZhanTuan_Fight_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ChengZhan_ZhanTuan_Fight_ResetPos()
	end
end

--显示UI
function ChengZhan_ZhanTuan_Fight_Show()
	this:Show()
end

--隐藏UI
function ChengZhan_ZhanTuan_Fight_OnHide()
	this:Hide()
end

function ChengZhan_ZhanTuan_Fight_Update()
	for i=1,2 do
		local nZhanTuanID = g_ChengZhan_ZhanTuan_Fight_nZhanTuanID[i]
		if nZhanTuanID >= 1 and nZhanTuanID <= 5 then
			m_UIZhanTuanInfo[i]:SetText(ScriptGlobal_Format("#{ZTPVP_260515_69}",g_ChengZhan_ZhanTuan_Fight_nGuildName[i]))
			m_UIZhanTuanInfo[i]:Show()
		elseif nZhanTuanID == 6 then
			m_UIZhanTuanInfo[i]:SetText(ScriptGlobal_Format("#{ZTPVP_260515_144}",g_ChengZhan_ZhanTuan_Fight_nGuildName[i]))
			m_UIZhanTuanInfo[i]:Show()
		else
			m_UIZhanTuanInfo[i]:Hide()
		end
		if i == 1 then
			local nScore = g_ChengZhan_ZhanTuan_nMaxScore - g_ChengZhan_ZhanTuan_Fight_nScore[i]
			if nScore <= 0 then
				nScore = 0
			end
			m_UITextButton[i]:SetProgress( nScore, g_ChengZhan_ZhanTuan_nMaxScore )
		else
			m_UITextButton[i]:SetProgress( g_ChengZhan_ZhanTuan_Fight_nScore[i], g_ChengZhan_ZhanTuan_nMaxScore )
		end
		m_UITextButton2[i]:SetText(g_ChengZhan_ZhanTuan_Fight_nScore[i])
	end

	ChengZhan_ZhanTuan_Fight_Point:SetText(ScriptGlobal_Format("#{ZTPVP_260515_41}",g_ChengZhan_ZhanTuan_Fight_nKillNum))
	--ChengZhan_ZhanTuan_Fight_Mini_Point:SetText(ScriptGlobal_Format("#{ZTPVP_260515_41}",g_ChengZhan_ZhanTuan_Fight_nKillNum))
	if g_ChengZhan_ZhanTuan_Fight_Team == 1 then
		local nScoreStr = ScriptGlobal_Format("#{ZTPVP_260515_244}",g_ChengZhan_ZhanTuan_Fight_nScore[1])
		--ChengZhan_ZhanTuan_Fight_Mini_Num:SetText(nScoreStr)
	else
		local nScoreStr = ScriptGlobal_Format("#{ZTPVP_260515_244}",g_ChengZhan_ZhanTuan_Fight_nScore[2])
		--ChengZhan_ZhanTuan_Fight_Mini_Num:SetText(nScoreStr)
	end
	
	if g_ChengZhan_ZhanTuan_Fight_Step ~= -1 then
		--ChengZhan_ZhanTuan_Fight_Timer:Hide()
		--ChengZhan_ZhanTuan_Fight_Mini_Timer:Hide()
		if g_ChengZhan_ZhanTuan_Fight_Step == 1 then
			ChengZhan_ZhanTuan_Fight_EndP1:Show()
			ChengZhan_ZhanTuan_Fight_EndP2:Hide()
		elseif g_ChengZhan_ZhanTuan_Fight_Step == 2 then
			ChengZhan_ZhanTuan_Fight_EndP1:Hide()
			ChengZhan_ZhanTuan_Fight_EndP2:Show()
		else
			ChengZhan_ZhanTuan_Fight_EndP1:Hide()
			ChengZhan_ZhanTuan_Fight_EndP2:Hide()
		end
	else
		ChengZhan_ZhanTuan_Fight_EndP1:Hide()
		ChengZhan_ZhanTuan_Fight_EndP2:Hide()
	end

	ChengZhan_ZhanTuan_Fight_Timer:Show()
	--ChengZhan_ZhanTuan_Fight_Mini_Timer:Show()
	ChengZhan_ZhanTuan_Fight_FarmTimer(g_ChengZhan_ZhanTuan_Fight_nTick,g_ChengZhan_ZhanTuan_Fight_Text)
	
	-- if g_ChengZhan_ZhanTuan_Fight_Mini == 0 then
	-- 	ChengZhan_ZhanTuan_Fight_FrameBk:Show()
	-- 	FChengZhan_ZhanTuan_Fight_Mini_Frame:Hide()
	-- else
	-- 	ChengZhan_ZhanTuan_Fight_FrameBk:Hide()
	-- 	FChengZhan_ZhanTuan_Fight_Mini_Frame:Show()
	-- end
end


-- function ChengZhan_ZhanTuan_Fight_CloseClicked()
-- 	if g_ChengZhan_ZhanTuan_Fight_Mini == 0 then
-- 		g_ChengZhan_ZhanTuan_Fight_Mini = 1
-- 		ChengZhan_ZhanTuan_Fight_FrameBk:Hide()
-- 		FChengZhan_ZhanTuan_Fight_Mini_Frame:Show()

-- 	else
-- 		g_ChengZhan_ZhanTuan_Fight_Mini = 0
-- 		ChengZhan_ZhanTuan_Fight_FrameBk:Show()
-- 		FChengZhan_ZhanTuan_Fight_Mini_Frame:Hide()
-- 	end
-- end

function ChengZhan_ZhanTuan_Fight_FarmTimer(countTime,nText)

	if countTime < 0 then
		countTime = 0
	end

	local minuteTime = math.floor(countTime/60)
	local secTime = math.mod(countTime,60)

	local strMinute = tostring(minuteTime)
	if minuteTime < 10 then
		strMinute = "0"..tostring(minuteTime)
	end
	
	local strSec = tostring(secTime)
	if secTime < 10 then
		strSec = "0"..tostring(secTime)
	end
	
	if g_ChengZhan_ZhanTuan_Fight_Step ~= -1 then
		--已结束
		ChengZhan_ZhanTuan_Fight_Timer:SetText(ScriptGlobal_Format("#{ZTPVP_260515_78}",countTime))
		if nText == 1 then
			ChengZhan_ZhanTuan_Fight_Text:SetText("#{ZTPVP_260515_214}")
		elseif nText == 2 then
			ChengZhan_ZhanTuan_Fight_Text:SetText("#{ZTPVP_260515_216}")
		else
			ChengZhan_ZhanTuan_Fight_Text:SetText("#{ZTPVP_260515_215}")
		end
		
		--ChengZhan_ZhanTuan_Fight_Mini_Timer:SetText(ScriptGlobal_Format("#{ZTPVP_260515_78}",countTime))
	else
		--未结束
		ChengZhan_ZhanTuan_Fight_Timer:SetText(ScriptGlobal_Format("#{ZTPVP_260515_42}",strMinute,strSec))
		ChengZhan_ZhanTuan_Fight_Text:SetText("#{ZTPVP_260515_235}")
		--ChengZhan_ZhanTuan_Fight_Mini_Timer:SetText(ScriptGlobal_Format("#{ZTPVP_260515_42}",strMinute,strSec))
	end

end
