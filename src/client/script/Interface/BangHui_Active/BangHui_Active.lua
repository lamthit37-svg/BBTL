--帮会活动
-- 单页效果
local g_Frame_UnifiedPosition

-- 活动等级限制
local g_LimitLevel = 30
local g_CanCall = {}
local g_CannotCall = {}
local g_RewardButton = {}
local g_RewardTips = {}
local g_RewardMark = {}
local g_nCurrentDayCount = 0
local g_nBossTime = 0
local g_nStepNomal = {100,150,200}
local g_nStepKaji = {50,75,100}
local g_nStep = {}
local g_SelfProgressMD = 2725
local g_RewardMF = {4145,4146,4147,4148,4149}
local g_nTarTimes = {1,3,5,7,9}
local g_nKaJiTarTimes = {1,2,3,4,5}
local g_RewardText = {}
local g_nTargetTimes = {}
local g_ActiveInfoText = {}
local g_ActiveInfoTextNomal = {"#{BHHYRW_230301_21}","#{BHHYRW_230301_22}","#{BHHYRW_230301_23}"}
local g_ActiveInfoTextKaji = {"#{BHHYRW_230301_156}","#{BHHYRW_230301_157}","#{BHHYRW_230301_158}"}
local g_ActiveInfoTextInfo = {}
local g_RewardTextTipsWindow = {}
local g_RewardTextTipsNomal = {"#{BHHYRW_230301_29}","#{BHHYRW_230301_30}","#{BHHYRW_230301_31}","#{BHHYRW_230301_32}","#{BHHYRW_230301_33}"}
local g_RewardTextTipsKaJi = {"#{BHHYRW_230301_34}","#{BHHYRW_230301_35}","#{BHHYRW_230301_36}","#{BHHYRW_230301_37}","#{BHHYRW_230301_38}"}
local g_RewardTextTips = {}
local g_AlreadyCall = 0
--=========
-- PreLoad
--=========
function BangHui_Active_PreLoad()
	
	this:RegisterEvent("BANGHUI_ACTIVE_OPENFRAME", true)
	this:RegisterEvent("BANGHUI_ACTIVE_UPDATETIME", false)
	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("CLOSE_SPRINGFES_GUIDE", false);

end

--=========
-- OnLoad
--=========
function BangHui_Active_OnLoad()

	g_Frame_UnifiedPosition = BangHui_Active:GetProperty("UnifiedPosition") 

	g_CanCall[1] = BangHui_Active_Item1_Callable
	g_CanCall[2] = BangHui_Active_Item2_Callable
	g_CanCall[3] = BangHui_Active_Item3_Callable

	g_CannotCall[1] = BangHui_Active_Item1_Uncallable
	g_CannotCall[2] = BangHui_Active_Item2_Uncallable
	g_CannotCall[3] = BangHui_Active_Item3_Uncallable

	g_ActiveInfoTextInfo[1] = BangHui_Active_Item1_Info
	g_ActiveInfoTextInfo[2] = BangHui_Active_Item2_Info
	g_ActiveInfoTextInfo[3] = BangHui_Active_Item3_Info

	g_RewardButton[1] = BangHui_Active_Reward1Btn
	g_RewardButton[2] = BangHui_Active_Reward2Btn
	g_RewardButton[3] = BangHui_Active_Reward3Btn
	g_RewardButton[4] = BangHui_Active_Reward4Btn
	g_RewardButton[5] = BangHui_Active_Reward5Btn

	g_RewardTips[1] = BangHui_Active_Reward1_tips
	g_RewardTips[2] = BangHui_Active_Reward2_tips
	g_RewardTips[3] = BangHui_Active_Reward3_tips
	g_RewardTips[4] = BangHui_Active_Reward4_tips
	g_RewardTips[5] = BangHui_Active_Reward5_tips

	g_RewardMark[1] = BangHui_Active_Reward1BtnOK
	g_RewardMark[2] = BangHui_Active_Reward2BtnOK
	g_RewardMark[3] = BangHui_Active_Reward3BtnOK
	g_RewardMark[4] = BangHui_Active_Reward4BtnOK
	g_RewardMark[5] = BangHui_Active_Reward5BtnOK

	g_RewardText[1] = BangHui_Active_Reward1Text
	g_RewardText[2] = BangHui_Active_Reward2Text
	g_RewardText[3] = BangHui_Active_Reward3Text
	g_RewardText[4] = BangHui_Active_Reward4Text
	g_RewardText[5] = BangHui_Active_Reward5Text

	g_RewardTextTipsWindow[1] = BangHui_Active_Reward1
	g_RewardTextTipsWindow[2] = BangHui_Active_Reward2
	g_RewardTextTipsWindow[3] = BangHui_Active_Reward3
	g_RewardTextTipsWindow[4] = BangHui_Active_Reward4
	g_RewardTextTipsWindow[5] = BangHui_Active_Reward5

end

--=========
-- OnEvent
--=========
function BangHui_Active_OnEvent(event)

	if event == "BANGHUI_ACTIVE_OPENFRAME" then
		if this:IsVisible() then
			local nProgress = DataPool:GetPlayerMission_DataRound(g_SelfProgressMD)
			for i = 1, table.getn(g_RewardButton) do
				if nProgress >= g_nTargetTimes[i] and Pneuma:GetMF(g_RewardMF[i]) <= 0 then
					g_RewardTips[i]:Show()
					g_RewardMark[i]:Hide()
				end
				if Pneuma:GetMF(g_RewardMF[i]) > 0 then
					g_RewardMark[i]:Show()
					g_RewardTips[i]:Hide()
					g_RewardButton[i]:Hide()
				end
			end
			return
		end

		BangHui_Active_Clear()
		g_nCurrentDayCount = tonumber(arg0)
		if g_nCurrentDayCount < 0 then
			g_nCurrentDayCount = 0
		end
		g_nBossTime = tonumber(arg1)
		g_nBossTime = math.mod(g_nBossTime, 10000)
		g_AlreadyCall = tonumber(arg2)

		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(124) > 0 then
			g_nTargetTimes = g_nKaJiTarTimes
			g_ActiveInfoText = g_ActiveInfoTextKaji
			g_nStep = g_nStepKaji
			g_RewardTextTips = g_RewardTextTipsKaJi
		else
			g_nTargetTimes = g_nTarTimes
			g_ActiveInfoText = g_ActiveInfoTextNomal
			g_nStep = g_nStepNomal
			g_RewardTextTips = g_RewardTextTipsNomal
		end

		BangHui_Active_Update()
		-- 显示
		this:Show()	

	elseif event == "BANGHUI_ACTIVE_UPDATETIME" then
	
		g_nBossTime = tonumber(arg0)
		g_nBossTime = math.mod(g_nBossTime, 10000)
		BangHui_Active_Update()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		BangHui_Active_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		BangHui_Active_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		BangHui_Active_OnHiden()
		
	elseif (event == "CLOSE_SPRINGFES_GUIDE") then
	
		BangHui_Active_OnHiden()
		
	end

end

--=========
-- 重置
--=========
function BangHui_Active_On_ResetPos()

	BangHui_Active:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 打开
--=========
function BangHui_Active_Update()
	
	local myPos = Guild:GetMyPosition()
	--if 8 == myPos or 9 == myPos then
		--BangHui_Active_Time_Set:Show()
	--else
		--BangHui_Active_Time_Set:Hide()
	--end
	
	--if g_nBossTime <= 0 then
		--BangHui_Active_Time_Text:SetText("#{BHHYRW_230301_27}")
	--else
		--local min = math.mod(g_nBossTime, 100)
		--local hour = math.floor(g_nBossTime/100)
		--BangHui_Active_Time_Text:SetText("#G"..hour..":"..min)
		--if min == 0 then
			--BangHui_Active_Time_Text:SetText("#G"..hour..":".."00")
		--end
	--end
	BangHui_Active_Info:SetText("#{BHHYRW_230301_18}")
	BangHui_Active_Progress_NUM:SetText(ScriptGlobal_Format("#{BHHYRW_230301_165}", g_nCurrentDayCount))

	for i = 1, 3 do 
		if i == g_AlreadyCall then
			g_CanCall[i]:Show()
			g_CannotCall[i]:Hide()
		else
			g_CanCall[i]:Hide()
			g_CannotCall[i]:Show()
		end
	end

	local nProgress = DataPool:GetPlayerMission_DataRound(g_SelfProgressMD)
	BangHui_Active_Personal_Progress:SetText(ScriptGlobal_Format("#{BHHYRW_230301_28}", nProgress))
	BangHui_Active_Progress2:SetProgress(nProgress, g_nTargetTimes[5])

	for i = 1, table.getn(g_RewardButton) do
		if nProgress >= g_nTargetTimes[i] and Pneuma:GetMF(g_RewardMF[i]) <= 0 then
			g_RewardTips[i]:Show()
			g_RewardMark[i]:Hide()
		end
		if Pneuma:GetMF(g_RewardMF[i]) > 0 then
			g_RewardMark[i]:Show()
			g_RewardTips[i]:Hide()
			g_RewardButton[i]:Hide()
		end
		g_RewardText[i]:SetText("#G"..g_nTargetTimes[i])
		g_RewardButton[i]:SetToolTip(g_RewardTextTips[i])
	end

	for i = 1, table.getn(g_ActiveInfoTextInfo) do
		g_ActiveInfoTextInfo[i]:SetText(g_ActiveInfoText[i])
	end

	BangHui_Active_Progress:SetToolTip("#{BHHYRW_230301_175}")
end

--=========
-- 隐藏
--=========
function BangHui_Active_OnHiden()
	BangHui_Active_Clear()
	this:Hide()
end


--=========
-- 小问号
--=========
function BangHui_Active_Description_Clicked()
	PushEvent("CCSHOP_HELP", 187)
end

--function BangHui_Active_Time_Set_Clicked()
	--PushEvent("BANGHUI_ACTIVE_SETTIME")
--end

function BangHui_Active_Reward_OnRewardClick(idx)
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 505010 )
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_Parameter(0, idx); 
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
end

function BangHui_Active_Clear()
	for i = 1, table.getn(g_RewardButton) do
		g_RewardTips[i]:Hide()
		g_RewardMark[i]:Hide()
		g_RewardButton[i]:Show()
	end
	--BangHui_Active_Time_Set:Hide()
	g_AlreadyCall = 0
end