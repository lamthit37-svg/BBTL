
local g_unifiedposistion
--新服社交
local g_ServerNew_XFSJ_Rewards_RewardCtrl = {}

function ServerNew_XFSJ_Rewards_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("SCENE_TRANSED",false);
end

function ServerNew_XFSJ_Rewards_OnLoad()	
	g_unifiedposistion = ServerNew_XFSJ_Rewards_Frame:GetProperty("UnifiedPosition")

	g_ServerNew_XFSJ_Rewards_RewardCtrl = {
		{btn=ServerNew_XFSJ_Rewards_JinDu_Reward_1, tips=ServerNew_XFSJ_Rewards_JinDu_Reward_1_Tips, mask=ServerNew_XFSJ_Rewards_JinDu_Reward_1_Mark},
		{btn=ServerNew_XFSJ_Rewards_JinDu_Reward_2, tips=ServerNew_XFSJ_Rewards_JinDu_Reward_2_Tips, mask=ServerNew_XFSJ_Rewards_JinDu_Reward_2_Mark},
		{btn=ServerNew_XFSJ_Rewards_JinDu_Reward_3, tips=ServerNew_XFSJ_Rewards_JinDu_Reward_3_Tips, mask=ServerNew_XFSJ_Rewards_JinDu_Reward_3_Mark},
		{btn=ServerNew_XFSJ_Rewards_JinDu_Reward_4, tips=ServerNew_XFSJ_Rewards_JinDu_Reward_4_Tips, mask=ServerNew_XFSJ_Rewards_JinDu_Reward_4_Mark},
	}
	
end

function ServerNew_XFSJ_Rewards_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88818501 ) then -- 2025Q1新服社交玩法
		ServerNew_XFSJ_Rewards_UpdateInfo()
	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		ServerNew_XFSJ_Rewards_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ServerNew_XFSJ_Rewards_ResetPos()
	elseif event == "SCENE_TRANSED" then
		this:Hide()
	end
end


---!!!reloadscript =ServerNew_XFSJ_Rewards
function ServerNew_XFSJ_Rewards_ResetPos()
	ServerNew_XFSJ_Rewards_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ServerNew_XFSJ_Rewards_Help_Btn_OnClicked()
	PushEvent("QUEST_HELP_MSG", "#{XFSJ_250527_16}")
end


function ServerNew_XFSJ_Rewards_OnClose()
	this:Hide()
end


function ServerNew_XFSJ_UpdateRedPoint(redPoint)
	if g_XinFuSheJiao_RedPointPos < 0 then
		return
	end
	local nLevel = Player : GetLevel()
	if nLevel < 30 then
		g_Broadcast_RedPointButton[g_XinFuSheJiao_RedPointPos]:Hide()
		return
	end

	if redPoint == 1 then
		g_Broadcast_RedPointButton[g_XinFuSheJiao_RedPointPos]:Show()
	else
		g_Broadcast_RedPointButton[g_XinFuSheJiao_RedPointPos]:Hide()
	end
end

function ServerNew_XFSJ_Show()
	--隐藏界面内小红点
	for i=1,4 do
		g_ServerNew_XFSJ_Rewards_RewardCtrl[i].tips:Hide()
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateUI" )
		Set_XSCRIPT_ScriptID( 888185 )
		Set_XSCRIPT_Parameter( 0,1 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	ServerNew_XFSJ_Frame : Show()
end

function ServerNew_XFSJ_Rewards_UpdateInfo()
	local serverValue  = Get_XParam_INT(0)
	local mfData  = Get_XParam_INT(1)
	local mfList = {0, 0, 0, 0}
	local nLevel = Player : GetLevel()
	local nLevelUnReach = 1
	if nLevel < 30 then
		nLevelUnReach = 0
	end
	mfList[1] = math.mod(mfData, 10)
	mfData = math.floor(mfData / 10)
	mfList[2] = math.mod(mfData, 10)
	mfData = math.floor(mfData / 10)
	mfList[3] = math.mod(mfData, 10)
	mfList[4] = math.floor(mfData / 10)

	--进度条
	local nServerStd = {1000,3200,7500,12000}
	
	ServerNew_XFSJ_Rewards_JinDu:SetProgress(serverValue, nServerStd[4])
	ServerNew_XFSJ_Rewards_Reward_Info:SetText( ScriptGlobal_Format("#{XFSJ_250527_69}",serverValue) )

	for i=1,4 do
		if mfList[i] == 1 then
			--已领取
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].mask:Show()
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].tips:Hide()
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].btn:Hide()
		elseif serverValue >= nServerStd[i] then
			--可以领取
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].mask:Hide()
			if nLevelUnReach == 1 then
				g_ServerNew_XFSJ_Rewards_RewardCtrl[i].tips:Show()
			else
				g_ServerNew_XFSJ_Rewards_RewardCtrl[i].tips:Hide()
			end
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].btn:Show()
		else
			--不可领取
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].mask:Hide()
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].tips:Hide()
			g_ServerNew_XFSJ_Rewards_RewardCtrl[i].btn:Show()
		end
	end
	this:Show()
end

function ServerNew_XFSJ_Rewards_JinDu_Reward(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "XinFuSheJiaoPrize" )
		Set_XSCRIPT_ScriptID( 888185 )
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end