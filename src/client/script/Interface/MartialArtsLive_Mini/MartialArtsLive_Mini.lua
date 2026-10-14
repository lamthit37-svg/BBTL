--******************************
--比武招亲：招亲实况小界面
--******************************


local g_MartialArtsLive_Mini_Frame_UnifiedPosition
local g_CompeMarry_ScnUse={
[0]=0,	--闲置期
[1]=1,	--预备期
[2]=2,	--赛前
[3]=3,	--赛中
[4]=4,	--赛后
[5]=5,	--无人报名的赛后
}

local g_PhaseBtn_Lignt={}
local g_PhaseLine_Lignt={}

local g_leftTickofMart=60*5
local g_leftTickofBattle=0

function MartialArtsLive_Mini_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("COMPEMARRY_ALIVEINFO")
	this:RegisterEvent("COMPEMARRY_ALIVEINFO_MINI")
end

function MartialArtsLive_Mini_OnLoad()
	g_MartialArtsLive_Mini_Frame_UnifiedPosition=MartialArtsLive_Mini_Frame:GetProperty("UnifiedPosition");
	g_PhaseBtn_Lignt={
	MartialArtsLive_Mini_Image1,
	MartialArtsLive_Mini_Image2,
	MartialArtsLive_Mini_Image3
	}
	g_PhaseLine_Lignt={
	MartialArtsLive_Mini_HLine1,
	MartialArtsLive_Mini_HLine2
	}
end

function MartialArtsLive_Mini_OnEvent(event)
	if event == "SCENE_TRANSED" then
	
		BWDH:CancelPlayerWatchPosDirection()
		local curSceneID = GetSceneID();
--		PushDebugMessage(event.." "..curSceneID)
		if (curSceneID >=687 and curSceneID <=691 ) then
			BWDH:SetSpecialSceneFlag()
		else
			KillTimer("MartialArtsLive_Mini_TimerProc()")
			this:Hide()
		end
	elseif (event == "COMPEMARRY_ALIVEINFO") then
		if tonumber(arg0) == 0  then
			KillTimer("MartialArtsLive_Mini_TimerProc()")
			if this:IsVisible() then
				BWDH:CancelPlayerWatchPosDirection()
				this:Hide()
			end
		elseif tonumber(arg0) == 1  then
			KillTimer("MartialArtsLive_Mini_TimerProc()")
			--计时器
			if tonumber(arg1)>=0 then
				g_leftTickofMart=math.mod(tonumber(arg1),1000)
				g_leftTickofBattle=math.floor(tonumber(arg1)/1000)
			end
--			PushDebugMessage("g_leftTickofMart="..g_leftTickofMart)
			SetTimer("MartialArtsLive_Mini","MartialArtsLive_Mini_TimerProc()", 1000)
			MartialArtsLive_Mini_TimerProc()
			MartialArtsLive_Mini_Update()
			this:Show()
		elseif tonumber(arg0) == 2 or tonumber(arg0) == 3  then
			if tonumber(arg1)>=0 then
				g_leftTickofMart=math.mod(tonumber(arg1),1000)
				g_leftTickofBattle=math.floor(tonumber(arg1)/1000)
			end
			if this:IsVisible() then
				MartialArtsLive_Mini_TimerProc()
				MartialArtsLive_Mini_Update()
			end
		end
	elseif (event == "COMPEMARRY_ALIVEINFO_MINI") then
		if tonumber(arg0) == 1 then
			MartialArtsLive_Mini_TimerProc()
			MartialArtsLive_Mini_Update()
			this:Show()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS") then
		MartialArtsLive_Mini_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MartialArtsLive_Mini_ResetPos()
	end
end

function MartialArtsLive_Mini_TimerProc()
	if g_leftTickofMart<0 then
	else
		local scnUse=BWDH:GetCompeMarryCurStatus()
		--显示
		local phaseMsg=""
		if scnUse==g_CompeMarry_ScnUse[0] then--闲置
			return
		elseif scnUse==g_CompeMarry_ScnUse[1] then--准备期
			if math.mod(g_leftTickofMart, 60)==0 then
				local minshow=math.floor((g_leftTickofMart+59)/60)
				if minshow<=0 then
					minshow=1
				end
				phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_170}",  minshow)
				MartialArtsLive_Mini_Text1:SetText(phaseMsg)
			end
		elseif scnUse==g_CompeMarry_ScnUse[2] then--赛前
			local MyName = Player:GetName()
			local szName, nLevel, nMenPai, szGuildName, nEquipHH = BWDH:GetCompeMarryCurSponsor()
			local sec=string.format("%02d",math.mod(g_leftTickofMart,60))
			if MyName==szName then
				--发起者
				phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_171}", math.floor(g_leftTickofMart/60), sec )
			else
				--其他人
				phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_259}", math.floor(g_leftTickofMart/60), sec )
			end
			MartialArtsLive_Mini_Text8:SetText(phaseMsg)
		elseif scnUse==g_CompeMarry_ScnUse[3] then--赛中
			local MyName = Player:GetName()
			local szNameS, nLevelS, nMenPaiS, szGuildNameS, nEquipHHS = BWDH:GetCompeMarryCurSponsor()
			local szName, nLevel, nMenPai, szGuildName, nEquipHH = BWDH:GetCompeMarryCurTiaozhan()
			local sec=string.format("%02d",math.mod(g_leftTickofMart,60))
			local battlesec=string.format("%02d",math.mod(g_leftTickofBattle,60))
			if szName~="" then
				--有挑战者，比赛中
				phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_172}", math.floor(g_leftTickofMart/60), sec )
				MartialArtsLive_Mini_Text1:SetText(phaseMsg)
			else
				--无挑战者，间隔期
				if szNameS==MyName then
					phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_339}", math.floor(g_leftTickofMart/60), sec )
					MartialArtsLive_Mini_Text1:SetText(phaseMsg)
				else
					phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_260}", math.floor(g_leftTickofMart/60), sec )
					MartialArtsLive_Mini_Text1:SetText(phaseMsg)
				end
			end
			local battlemin=math.floor(g_leftTickofBattle/60)
			local battlesec=string.format("%02d",math.mod(g_leftTickofBattle,60))
			--无挑战者，间隔期
			phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_388}", battlemin, battlesec )
			MartialArtsLive_Mini_Text8:SetText(phaseMsg)
--		elseif scnUse==g_CompeMarry_ScnUse[4] then--赛后
--		elseif scnUse==g_CompeMarry_ScnUse[5] then--无人赛后
		end
	end
	g_leftTickofMart=g_leftTickofMart-1
	g_leftTickofBattle=g_leftTickofBattle-1
end

function MartialArtsLive_Mini_Update()
	--阶段
	local scnUse=BWDH:GetCompeMarryCurStatus()
	local phaseMsg=""
	if scnUse==g_CompeMarry_ScnUse[0] then--闲置
		return
	elseif scnUse==g_CompeMarry_ScnUse[1] then--准备期
		g_PhaseBtn_Lignt[1]:Show()
		g_PhaseBtn_Lignt[2]:Hide()
		g_PhaseBtn_Lignt[3]:Hide()
		g_PhaseLine_Lignt[1]:Hide()
		g_PhaseLine_Lignt[2]:Hide()
		--一行
		MartialArtsLive_Mini_Window:Hide()
		MartialArtsLive_Mini_Window2:Show()
		MartialArtsLive_Mini_Text8:SetText("#{BWZQ_160623_385}")

		local minshow=math.floor((g_leftTickofMart+59)/60)
		if minshow<=0 then
			minshow=1
		end
		phaseMsg=ScriptGlobal_Format( "#{BWZQ_160623_170}", minshow )
		MartialArtsLive_Mini_Text1:SetText(phaseMsg)

		local szName, _, _, _, _ = BWDH:GetCompeMarryCurSponsor()
		MartialArtsLive_Mini_Text7_1:SetText(szName)
		MartialArtsLive_Mini_Text8:SetToolTip("")
	elseif scnUse==g_CompeMarry_ScnUse[2] then--赛前
		g_PhaseBtn_Lignt[1]:Show()
		g_PhaseBtn_Lignt[2]:Show()
		g_PhaseBtn_Lignt[3]:Hide()
		g_PhaseLine_Lignt[1]:Show()
		g_PhaseLine_Lignt[2]:Hide()
		--一行
		MartialArtsLive_Mini_Window:Hide()
		MartialArtsLive_Mini_Window2:Show()

		local szName, _, _, _, _ = BWDH:GetCompeMarryCurSponsor()
		if MyName==szName then
			MartialArtsLive_Mini_Text1:SetText("#{BWZQ_160623_386}")
		else
			MartialArtsLive_Mini_Text1:SetText("#{BWZQ_160623_392}")
		end
		MartialArtsLive_Mini_Text7_1:SetText(szName)
		MartialArtsLive_Mini_Text8:SetToolTip("#{BWZQ_160623_387}")

	elseif scnUse==g_CompeMarry_ScnUse[3] then--赛中
		g_PhaseBtn_Lignt[1]:Show()
		g_PhaseBtn_Lignt[2]:Show()
		g_PhaseBtn_Lignt[3]:Show()
		g_PhaseLine_Lignt[1]:Show()
		g_PhaseLine_Lignt[2]:Show()
		--三行
		MartialArtsLive_Mini_Window:Show()
		MartialArtsLive_Mini_Window2:Hide()

		local szNameS, _, _, _, _ = BWDH:GetCompeMarryCurSponsor()
		MartialArtsLive_Mini_Text2_1:SetText(szNameS)
		local szNameL, _, _, _, _ = BWDH:GetCompeMarryCurLeizhu()
		MartialArtsLive_Mini_Text3_1:SetText(szNameL)
		local szNameT, _, _, _, _ = BWDH:GetCompeMarryCurTiaozhan()
		if szNameT=="" then
			--间隔期
			local MyName = Player:GetName()
			if MyName==szNameS then
				MartialArtsLive_Mini_Text4_1:SetText("#{BWZQ_160623_341}")
			else
				MartialArtsLive_Mini_Text4_1:SetText("#{BWZQ_160623_343}")
			end
			MartialArtsLive_Mini_Text8:SetToolTip("#{BWZQ_160623_389}")
		else
			--比赛期
			MartialArtsLive_Mini_Text4_1:SetText(szNameT)
			MartialArtsLive_Mini_Text8:SetToolTip("#{BWZQ_160623_390}")
		end

--	elseif scnUse==g_CompeMarry_ScnUse[4] or scnUse==g_CompeMarry_ScnUse[5] then--赛后 --无人赛后
--		g_PhaseBtn_Lignt[1]:Hide()
--		g_PhaseBtn_Lignt[2]:Hide()
--		g_PhaseBtn_Lignt[3]:Hide()
--		g_PhaseBtn_Lignt[4]:Hide()
--		--三行/两行 显示
--		MartialArtsLive_Mini_Text7:Hide()
--		MartialArtsLive_Mini_Window:Hide()
--		MartialArtsLive_Mini_Window1:Show()
--		local szNameS, _, _, _, _ = BWDH:GetCompeMarryCurSponsor()
--		MartialArtsLive_Mini_Text5_1:SetText(szNameS)
--		local szNameL, _, _, _, _ = BWDH:GetCompeMarryCurLeizhu()
--		if szNameL~="" then
--			local msg=ScriptGlobal_Format( "#{BWZQ_160623_342}", szNameL )
--			MartialArtsLive_Mini_Text1:SetText(msg)
--			MartialArtsLive_Mini_Text6_1:SetText(szNameL)
--		else
--			MartialArtsLive_Mini_Text1:SetText("#{BWZQ_160623_173}")
--			MartialArtsLive_Mini_Text6_1:SetText("#{BWZQ_160623_341}")
--		end

	end
end

function MartialArtsLive_Mini_ResetPos()
	MartialArtsLive_Mini_Frame:SetProperty("UnifiedPosition", g_MartialArtsLive_Mini_Frame_UnifiedPosition);
end

function MartialArtsLive_Mini_Clicked()
	this:Hide()
	PushEvent( "COMPEMARRY_ALIVEINFO_MINI", 0 )
end

function MartialArtsLive_Mini_CameraClicked(nIdx)
	--1：东侧，2：西侧，3：角色视角
	if nIdx==1 then
		BWDH:SetPlayerWatchPosDirection(270,105,99)
		PushEvent("UI_COMMAND", 1000)
	elseif nIdx==2 then
		BWDH:SetPlayerWatchPosDirection(90,87,99)
		PushEvent("UI_COMMAND", 1000)
	elseif nIdx==3 then
		BWDH:SetPlayerWatchPosDirection(0,0,0)
	end
end
