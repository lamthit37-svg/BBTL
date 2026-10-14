--******************************
--比武招亲：招亲实况
--******************************

local g_MartialArtsLive_Frame_UnifiedPosition

local g_MartialArtsLive_ScnUse={
[0]=0,	--闲置期
[1]=1,	--预备期
[2]=2,	--赛前
[3]=3,	--赛中
[4]=4,	--赛后
[5]=5,	--无人报名的赛后
}

local g_MenPaiNameList =
{
	[0]  ="#{XQ_MP_1}",
	[1]  ="#{XQ_MP_2}",
	[2]  ="#{XQ_MP_3}",
	[3]  ="#{XQ_MP_4}",
	[4]  ="#{XQ_MP_5}",
	[5]  ="#{XQ_MP_6}",
	[6]  ="#{XQ_MP_7}",
	[7]  ="#{XQ_MP_8}",
	[8]  ="#{XQ_MP_9}",
	[9]  ="#{BWZQ_160623_102}",--无
	[10] ="#{XQ_MP_10}",
	[11] ="#{XQ_MP_13}",
	[12] ="#{XQ_MP_14}",--鬼谷
	[13] ="#{XQ_MP_15}",--桃花岛
	[14] ="#{XMPHM_210604_01}",
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
}

local g_leftTickofMart=60*5


function MartialArtsLive_PreLoad()
	 this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("COMPEMARRY_ALIVEINFO")
	this:RegisterEvent("COMPEMARRY_ALIVEINFO_MINI")
end

function MartialArtsLive_OnLoad()
	g_MartialArtsLive_Frame_UnifiedPosition=MartialArtsLive_Frame:GetProperty("UnifiedPosition");
end

function MartialArtsLive_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then

		local curSceneID = GetSceneID();
		if (curSceneID >=687 and curSceneID <=691 ) then
		else
			KillTimer("MartialArtsLive_TimerProc()")
			this:Hide()
		end
--		PushDebugMessage(event.." "..curSceneID)
		BWDH:CancelPlayerWatchPosDirection()
	elseif (event == "COMPEMARRY_ALIVEINFO") then
		if tonumber(arg0) == 0 then
			KillTimer("MartialArtsLive_TimerProc()")
			if this:IsVisible() then
				BWDH:CancelPlayerWatchPosDirection()
				this:Hide()
			end
		elseif tonumber(arg0) == 1 then
			KillTimer("MartialArtsLive_Mini_TimerProc()")
			--计时器
			if tonumber(arg1)>=0 then
				g_leftTickofMart=tonumber(arg1)+1
			end
			SetTimer("MartialArtsLive","MartialArtsLive_TimerProc()", 1000)
			--show
			MartialArtsLive_SponsorUpdate()
			this:Hide()
		elseif tonumber(arg0) == 2 or tonumber(arg0) == 3 then
			if tonumber(arg1)>=0 then
				g_leftTickofMart=tonumber(arg1)+1
			end
			if this:IsVisible() then
				--update
				MartialArtsLive_Update()
			end
		end
	elseif (event == "COMPEMARRY_ALIVEINFO_MINI") then
		if tonumber(arg0) == 0 then
			MartialArtsLive_Update()
			this:Show()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		MartialArtsLive_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MartialArtsLive_ResetPos()
	end
end

function MartialArtsLive_SponsorUpdate()
	--标题
	local szName, nLevel, nMenPai, szGuildName, nEquipHH = BWDH:GetCompeMarryCurSponsor()
	if szName==nil or szName=="" then return end;

	local titleMsg=ScriptGlobal_Format("#{BWZQ_160623_186}",szName)
	MartialArtsLive_DragTitle:SetText(titleMsg)

	--招亲者信息
	MartialArtsLive_Bk1_Name_1:SetText(szName)
	MartialArtsLive_Bk1_Level_1:SetText(g_MenPaiNameList[nMenPai])
	MartialArtsLive_Bk1_United_1:SetText(nLevel)
	if szGuildName~="" then
		MartialArtsLive_Bk1_Gang_1:SetText(szGuildName)
	else
		MartialArtsLive_Bk1_Gang_1:SetText("#{BWZQ_160623_102}")
	end
	MartialArtsLive_Bk1_Score_1:SetText(nEquipHH)
end

function MartialArtsLive_Update()
	local scnUse=BWDH:GetCompeMarryCurStatus()
	local MyName = Player:GetName()
	local szNameS, nLevelS, nMenPaiS, szGuildNameS, nEquipHHS = BWDH:GetCompeMarryCurSponsor()

	if scnUse==g_MartialArtsLive_ScnUse[0] then--闲置
		return
	elseif scnUse==g_MartialArtsLive_ScnUse[1] then--准备期
		local msg="#{BWZQ_160623_219}"
		local minshow=math.floor((g_leftTickofMart+59)/60)
		if minshow<=0 then
			minshow=1
		end
		if szNameS==MyName then
			msg=msg..ScriptGlobal_Format( "#{BWZQ_160623_247}", minshow )
		else
			msg=msg..ScriptGlobal_Format( "#{BWZQ_160623_266}", minshow )
		end
		MartialArtsLive_Explain:SetText(msg)
	elseif scnUse==g_MartialArtsLive_ScnUse[2] then--赛前
		if szNameS==MyName then
			MartialArtsLive_Explain:SetText("#{BWZQ_160623_219}".."#{BWZQ_160623_248}")
		else
			MartialArtsLive_Explain:SetText("#{BWZQ_160623_219}".."#{BWZQ_160623_267}")
		end
	elseif scnUse==g_MartialArtsLive_ScnUse[3] then--赛中
		if szNameS==MyName then
			MartialArtsLive_Explain:SetText("#{BWZQ_160623_219}".."#{BWZQ_160623_249}")
		else
			MartialArtsLive_Explain:SetText("#{BWZQ_160623_219}".."#{BWZQ_160623_344}")
		end
	elseif scnUse==g_MartialArtsLive_ScnUse[4] or scnUse==g_MartialArtsLive_ScnUse[5] then--赛后
		if szNameS==MyName then
			MartialArtsLive_Explain:SetText("#{BWZQ_160623_219}".."#{BWZQ_160623_250}")
		else
			MartialArtsLive_Explain:SetText("#{BWZQ_160623_219}".."#{BWZQ_160623_345}")
		end
	end

	--是否有擂主
	local szName, nLevel, nMenPai, szGuildName, nEquipHH = BWDH:GetCompeMarryCurLeizhu()
	if szName=="" then
		MartialArtsLive_Bk2_Noinfo:Show()
		MartialArtsLive_Bk2_Lace:Hide()
		if scnUse==g_MartialArtsLive_ScnUse[0] then
			return
		elseif scnUse==g_MartialArtsLive_ScnUse[1] then
			if szNameS==MyName then
				MartialArtsLive_Bk2_Noinfo:SetText("#{BWZQ_160623_251}")
			else
				MartialArtsLive_Bk2_Noinfo:SetText("#{BWZQ_160623_228}")
			end
		elseif scnUse==g_MartialArtsLive_ScnUse[2] then
			if szNameS==MyName then
				-- #cfff263尚未产生擂主！#r  当前为#G抢擂阶段#cfff263！在场大侠可进行抢擂，坐镇#G擂主#cfff263，接受其他大侠的挑战。
				MartialArtsLive_Bk2_Noinfo:SetText("#{BWZQ_160623_252}")
			else
				MartialArtsLive_Bk2_Noinfo:SetText("#{BWZQ_160623_229}")
			end
		elseif scnUse==g_MartialArtsLive_ScnUse[4] or scnUse==g_MartialArtsLive_ScnUse[5] then
			if szNameS==MyName then
				-- #cfff263比武招亲结束！#r  本场比武招亲没有#G擂主#cfff263产出。
				MartialArtsLive_Bk2_Noinfo:SetText("#{BWZQ_160623_253}")
			else
				MartialArtsLive_Bk2_Noinfo:SetText("#{BWZQ_160623_230}")
			end
		end
	else
		MartialArtsLive_Bk2_Noinfo:Hide()
		MartialArtsLive_Bk2_Lace:Show()
		MartialArtsLive_Bk2_Name_1:SetText(szName)

		MartialArtsLive_Bk2_Level_1:SetText(g_MenPaiNameList[nMenPai])
		MartialArtsLive_Bk2_United_1:SetText(nLevel)
		if szGuildName~="" then
			MartialArtsLive_Bk2_Gang_1:SetText(szGuildName)
		else
			MartialArtsLive_Bk2_Gang_1:SetText("#{BWZQ_160623_102}")
		end
		MartialArtsLive_Bk2_Score_1:SetText(nEquipHH)
	end
	--是否有挑战者
	szName, nLevel, nMenPai, szGuildName, nEquipHH = BWDH:GetCompeMarryCurTiaozhan()
	if szName=="" then
		MartialArtsLive_Bk3_Noinfo:Show()
		MartialArtsLive_Bk3_Lace:Hide()
		if scnUse==g_MartialArtsLive_ScnUse[0] then
			return
		elseif scnUse==g_MartialArtsLive_ScnUse[1] then
			if szNameS==MyName then
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_254}")
			else
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_233}")
			end
		elseif scnUse==g_MartialArtsLive_ScnUse[2] then
			if szNameS==MyName then
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_255}")
			else
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_234}")
			end
		elseif scnUse==g_MartialArtsLive_ScnUse[3] then
			if szNameS==MyName then
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_256}")
			else
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_235}")
			end
		elseif scnUse==g_MartialArtsLive_ScnUse[4] or scnUse==g_MartialArtsLive_ScnUse[5] then
			if szNameS==MyName then
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_257}")
			else
				MartialArtsLive_Bk3_Noinfo:SetText("#{BWZQ_160623_236}")
			end
		end
	else
		MartialArtsLive_Bk3_Noinfo:Hide()
		MartialArtsLive_Bk3_Lace:Show()
		MartialArtsLive_Bk3_Name_1:SetText(szName)

		MartialArtsLive_Bk3_Level_1:SetText(g_MenPaiNameList[nMenPai])
		MartialArtsLive_Bk3_United_1:SetText(nLevel)
		if szGuildName~="" then
			MartialArtsLive_Bk3_Gang_1:SetText(szGuildName)
		else
			MartialArtsLive_Bk3_Gang_1:SetText("#{BWZQ_160623_102}")
		end
		MartialArtsLive_Bk3_Score_1:SetText(nEquipHH)
	end
end

function MartialArtsLive_ResetPos()
	MartialArtsLive_Frame:SetProperty("UnifiedPosition", g_MartialArtsLive_Frame_UnifiedPosition);
end

function MartialArtsLive_OnShowMiniUI()
	this:Hide()
	PushEvent( "COMPEMARRY_ALIVEINFO_MINI", 1 )
end

--白
function MartialArtsLive_TimerProc()
	g_leftTickofMart=g_leftTickofMart-1
	if g_leftTickofMart<0 then
	else
		local msg="#{BWZQ_160623_219}"
		local scnUse=BWDH:GetCompeMarryCurStatus()
		if scnUse==g_MartialArtsLive_ScnUse[1] then--进入期
			if math.mod(g_leftTickofMart, 60)==0 then
				local leftBeginTick=math.floor((g_leftTickofMart+59)/60)
				msg=msg..ScriptGlobal_Format("#{BWZQ_160623_247}", leftBeginTick)
				MartialArtsLive_Explain:SetText(msg)
			end
		elseif scnUse==g_MartialArtsLive_ScnUse[2] then--赛前
		elseif scnUse==g_MartialArtsLive_ScnUse[3] then--赛中
		elseif scnUse==g_MartialArtsLive_ScnUse[4] then--赛后
		elseif scnUse==g_MartialArtsLive_ScnUse[5] then--无人赛后
		end
	end
end

function MartialArtsLive_CameraClicked(nIdx)
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
