-- 玩家血条积分UI
--
local g_unifiedposistion

local g_icon = {
	win = "set:HSLJ_01 image:HSLJ_Win",
	lose = "set:HSLJ_01 image:HSLJ_Lost",
}

local g_battle_type	= {
	team_a = 0,
	team_b = 1,
}

local g_scene_res_id		= 821
local g_scene_res_id2		= 834
local g_scene_res_id3		= 835

function HuaShanLunJian2_ZhanKuang_PreLoad()
	this:RegisterEvent("XBWJHS_BATTLE_GAMEOVER",true)
	this:RegisterEvent("XBWJHS_BATTLE_DETAIL_SHOW",true)
	this:RegisterEvent("XBWJHS_BATTLE_RESULT_UPDATE",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function HuaShanLunJian2_ZhanKuang_OnLoad()
	g_unifiedposistion	= HuaShanLunJian2_ZhanKuang_Frame:GetProperty("UnifiedPosition")
end

function HuaShanLunJian2_ZhanKuang_OnEvent(event)
	if event == "XBWJHS_BATTLE_GAMEOVER" then
		HuaShanLunJian2_ZhanKuang_OnShow()
	elseif event == "XBWJHS_BATTLE_DETAIL_SHOW" then
		HuaShanLunJian2_ZhanKuang_OnShow(1)
	elseif event == "XBWJHS_BATTLE_RESULT_UPDATE" then
		HuaShanLunJian2_ZhanKuang_InitOtherUI()
		HuaShanLunJian2_ZhanKuang_RefreshUI()
	elseif event == "ADJEST_UI_POS" then
		HuaShanLunJian2_ZhanKuang_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		HuaShanLunJian2_ZhanKuang_ResetPos()
	elseif event == "SCENE_TRANSED" then
		if XBWJHS:IsInBattleScene() ~= 1 then
			HuaShanLunJian2_ZhanKuang_HideWindow()
		end
	end
end

--================================================
-- 显示信息
--================================================
function HuaShanLunJian2_ZhanKuang_OnShow(booDetail)
	if booDetail ~= nil and booDetail > 0 then
		if (IsWindowShow("HuaShanLunJian2_ZhanKuangMini")) then
			return
		end
	else
		if (IsWindowShow("HuaShanLunJian2_ZhanKuangMini")) then
			CloseWindow("HuaShanLunJian2_ZhanKuangMini", true)
		end
	end

	HuaShanLunJian2_ZhanKuang_InitOtherUI()
	HuaShanLunJian2_ZhanKuang_RefreshUI()
	this:Show()
end

function HuaShanLunJian2_ZhanKuang_InitOtherUI()
	HuaShanLunJian2_ZhanKuang_Sever_Left:SetText("")
	HuaShanLunJian2_ZhanKuang_Sever_Right:SetText("")
	HuaShanLunJian2_ZhanKuang_Team_Left:SetText("")
	HuaShanLunJian2_ZhanKuang_Time_Right:SetText("")
	HuaShanLunJian2_ZhanKuang_Team_TitleBK:SetText("0")
	HuaShanLunJian2_ZhanKuang_Team_TitleBK3:SetText("0")

	HuaShanLunJian2_ZhanKuang_First_Left:SetText("")
	HuaShanLunJian2_ZhanKuang_First_Right:SetText("")
	HuaShanLunJian2_ZhanKuang_Second_Left:SetText("")
	HuaShanLunJian2_ZhanKuang_Second_Right:SetText("")
	HuaShanLunJian2_ZhanKuang_Third_Left:SetText("")
	HuaShanLunJian2_ZhanKuang_Third_Right:SetText("")
	HuaShanLunJian2_ZhanKuang_LiftPic:Hide()
	HuaShanLunJian2_ZhanKuang_RightPic:Hide()
	-- HuaShanLunJian2_ZhanKuang_First:Hide()
	-- HuaShanLunJian2_ZhanKuang_Second:Hide()
	-- HuaShanLunJian2_ZhanKuang_Third:Hide()
end

--================================================
-- 刷一遍信息
--================================================
function HuaShanLunJian2_ZhanKuang_RefreshUI()
	local teamid_a,zoneid_a,teamname_a = XBWJHS:GetBattleTeamData(g_battle_type.team_a)
	local teamid_b,zoneid_b,teamname_b = XBWJHS:GetBattleTeamData(g_battle_type.team_b)
	if teamid_a > 0 then
		local szServerName = DataPool:GetServerName(zoneid_a)
		HuaShanLunJian2_ZhanKuang_Sever_Left:SetText(szServerName)
		--local szTeamName = HuaShanLunJian2_ZhanKuang_TransformName(teamname_a, g_battle_type.team_a)
		HuaShanLunJian2_ZhanKuang_Team_Left:SetText(teamname_a)
	end
	if teamid_b > 0 then
		local szServerName = DataPool:GetServerName(zoneid_b)
		HuaShanLunJian2_ZhanKuang_Sever_Right:SetText(szServerName)
		--local szTeamName = HuaShanLunJian2_ZhanKuang_TransformName(teamname_b, g_battle_type.team_b)
		HuaShanLunJian2_ZhanKuang_Time_Right:SetText(teamname_b)
	end
	-- 获得比赛结果
	local winner,winner2,winner3 = XBWJHS:GetBattleData("roundresult")
	if winner > 0 then
		if winner == teamid_a then
			HuaShanLunJian2_ZhanKuang_First_Left:SetText("#{XLVL_260327_81}")
			HuaShanLunJian2_ZhanKuang_First_Right:SetText("#{XLVL_260327_82}")
		elseif winner == teamid_b then
			HuaShanLunJian2_ZhanKuang_First_Left:SetText("#{XLVL_260327_82}")
			HuaShanLunJian2_ZhanKuang_First_Right:SetText("#{XLVL_260327_81}")
		end
		--HuaShanLunJian2_ZhanKuang_First:Show()
		if winner2 > 0 then
			if winner2 == teamid_a then
				HuaShanLunJian2_ZhanKuang_Second_Left:SetText("#{XLVL_260327_81}")
				HuaShanLunJian2_ZhanKuang_Second_Right:SetText("#{XLVL_260327_82}")
			elseif winner2 == teamid_b then
				HuaShanLunJian2_ZhanKuang_Second_Left:SetText("#{XLVL_260327_82}")
				HuaShanLunJian2_ZhanKuang_Second_Right:SetText("#{XLVL_260327_81}")
			end
			--HuaShanLunJian2_ZhanKuang_Second:Show()
			-- 第三场
			if winner3 == teamid_a then
				HuaShanLunJian2_ZhanKuang_Third_Left:SetText("#{XLVL_260327_81}")
				HuaShanLunJian2_ZhanKuang_Third_Right:SetText("#{XLVL_260327_82}")
			elseif winner3 == teamid_b then
				HuaShanLunJian2_ZhanKuang_Third_Left:SetText("#{XLVL_260327_82}")
				HuaShanLunJian2_ZhanKuang_Third_Right:SetText("#{XLVL_260327_81}")
			end
			--HuaShanLunJian2_ZhanKuang_Third:Show()
		end
		-- 比分
		local score_a,score_b = XBWJHS:GetBattleData("score")
		local szScore = score_a..":"..score_b
		HuaShanLunJian2_ZhanKuang_Team_TitleBK:SetText(score_a)
		HuaShanLunJian2_ZhanKuang_Team_TitleBK3:SetText(score_b)
	end
	-- 最终结果
	local finalResult = XBWJHS:GetBattleData("finalresult")
	if finalResult > 0 and finalResult == teamid_a then
		HuaShanLunJian2_ZhanKuang_LiftPic:SetProperty("Image", g_icon.win)
		HuaShanLunJian2_ZhanKuang_RightPic:SetProperty("Image", g_icon.lose)
		HuaShanLunJian2_ZhanKuang_LiftPic:Show()
		HuaShanLunJian2_ZhanKuang_RightPic:Show()
	elseif finalResult > 0 and finalResult == teamid_b then
		HuaShanLunJian2_ZhanKuang_RightPic:SetProperty("Image", g_icon.win)
		HuaShanLunJian2_ZhanKuang_LiftPic:SetProperty("Image", g_icon.lose)
		HuaShanLunJian2_ZhanKuang_LiftPic:Show()
		HuaShanLunJian2_ZhanKuang_RightPic:Show()
	end
end

--================================================
-- 转换名字
--================================================
function HuaShanLunJian2_ZhanKuang_TransformName(name, teamidx)
	local teamid,zoneid,teamname = XBWJHS:GetBattleTeamData(teamidx)
	if teamid < 0 then
		return name
	end

	local serverName = DataPool:GetServerName(zoneid)
	local retname = name.."@"..tostring(serverName)

	return retname
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function HuaShanLunJian2_ZhanKuang_ResetPos()
	HuaShanLunJian2_ZhanKuang_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

--================================================
-- 关闭界面
--================================================
function HuaShanLunJian2_ZhanKuang_Close_Clicked()
	HuaShanLunJian2_ZhanKuang_HideWindow()

	PushEvent("XBWJHS_BATTLE_DETAILMINI_SHOW")
end

function HuaShanLunJian2_ZhanKuang_HideWindow()
	this:Hide()
end
