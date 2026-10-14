-- 玩家血条积分UI
--
local g_unifiedposistion
local g_istimerset			= 0
local g_ui_list				= {}		-- ui集合
local g_memcount_max		= 12		-- 队员总数
local g_teammem_max			= 6			-- 单队伍最大人数
local g_team_max			= 2			-- 队伍最大数量
local g_btimerset			= 0			-- 是否设置过倒计时
local g_othercolor			= {			-- 其他状态颜色
	lose = "#ccccccc",					-- 掉线
	die = "#cff0000",					-- 死亡
}
local g_scene_res_id		= 821
local g_scene_res_id2		= 834
local g_scene_res_id3		= 835

local g_menpaiinfo			= {
	[0]  ={name="#{WCBZ_180128_59}" , color="#cff6600", },
	[1]  ={name="#{WCBZ_180128_65}" , color="#cffcc00", },
	[2]  ={name="#{WCBZ_180128_67}" , color="#c00ff00", },
	[3]  ={name="#{WCBZ_180128_61}" , color="#c0000ff", },
	[4]  ={name="#{WCBZ_180128_68}" , color="#cff99cc", },
	[5]  ={name="#{WCBZ_180128_66}" , color="#c007700", },
	[6]  ={name="#{WCBZ_180128_60}" , color="#cffff00", },
	[7]  ={name="#{WCBZ_180128_63}" , color="#cffffff", },
	[8]  ={name="#{WCBZ_180128_64}" , color="#c7700ff", },
	[9]  ={name="#{ZBS16_160511_55}", color="#c999999", },	
	[10] ={name="#{WCBZ_180128_62}", color="#c007fff", },
	[11] ={name="#{WCBZ_180128_69}", color="#ccc00ff", },
	[12] ={name="#{WCBZ_180128_70}", color="#ccc00ff", }, --鬼谷
	[13] ={name="#{WCBZ_180516_646}", color="#ca1d6da", }, --桃花岛
	[14] ={name="#{XMPHM_210604_01}", color="#cd61313", }, --menpai14
	[15] ={name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", color="#c656ab4", }, --menpai15
}
local g_battle_type			= {
	team_a = 0,						-- 队伍A一血
	team_b = 1,						-- 队伍B一血
}

local g_teampost = {
	[0] = {show = 0, icon = "",},									-- 成员
	[1] = {show = 1, icon = "set:Union1 image:Union_MemberIcon_L",},-- 副队长
	[2] = {show = 1, icon = "set:Union1 image:Union_LeaderIcon_L",},-- 副队长
}

local g_icon_result = 
{
	win = "set:Wangzhe1 image:Wangzhe_sheng",
	lose = "set:Wangzhe2 image:Wangzhe_fu",
}
function HuaShanLunJian2_ResultShow_PreLoad()
	this:RegisterEvent("XBWJHS_BATTLE_FULLDATA_UPDATE",true)
	this:RegisterEvent("XBWJHS_BATTLE_RESULT_UPDATE",true)
	this:RegisterEvent("XBWJHS_BATTLE_SHOW",true)
	this:RegisterEvent("XBWJHS_BATTLE_UPDATE",false)
	this:RegisterEvent("XBWJHS_BATTLE_TIME_UPDATE",false)
	this:RegisterEvent("XBWJHS_BATTLE_GAMEOVER",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function HuaShanLunJian2_ResultShow_OnLoad()

	local _prefix_l = "HuaShanLunJian2_ResultShow_Left_"
	local _prefix_r = "HuaShanLunJian2_ResultShow_Right_"
	local makeGroup = function(prefix,name,mp,leader,lv,hp,kill)
		return {
			["name"] = _G[prefix..name],
			["mp"] = _G[prefix..mp],
			["lv"] = _G[prefix..lv],
			["leader"] = _G[prefix..leader],
			["hp"] = _G[prefix..hp],
			["kill"] = _G[prefix..kill],
		}
	end
	-- 队伍信息控件列表初始化
	g_ui_list = {
		makeGroup(_prefix_l, "1_name","1_Career","1_Icon","1_Level","PlayerHP1","1_Kill"),
		makeGroup(_prefix_l, "2_name","2_Career","2_Icon","2_Level","PlayerHP2","2_Kill"),
		makeGroup(_prefix_l, "3_name","3_Career","3_Icon","3_Level","PlayerHP3","3_Kill"),
		makeGroup(_prefix_l, "4_name","4_Career","4_Icon","4_Level","PlayerHP4","4_Kill"),
		makeGroup(_prefix_l, "5_name","5_Career","5_Icon","5_Level","PlayerHP5","5_Kill"),
		makeGroup(_prefix_l, "6_name","6_Career","6_Icon","6_Level","PlayerHP6","6_Kill"),

		makeGroup(_prefix_r, "1_name","1_Career","1_Icon","1_Level","PlayerHP1","1_Kill"),
		makeGroup(_prefix_r, "2_name","2_Career","2_Icon","2_Level","PlayerHP2","2_Kill"),
		makeGroup(_prefix_r, "3_name","3_Career","3_Icon","3_Level","PlayerHP3","3_Kill"),
		makeGroup(_prefix_r, "4_name","4_Career","4_Icon","4_Level","PlayerHP4","4_Kill"),
		makeGroup(_prefix_r, "5_name","5_Career","5_Icon","5_Level","PlayerHP5","5_Kill"),
		makeGroup(_prefix_r, "6_name","6_Career","6_Icon","6_Level","PlayerHP6","6_Kill"),
	}

	g_unifiedposistion	= HuaShanLunJian2_ResultShow_Frame:GetProperty("UnifiedPosition")
end

function HuaShanLunJian2_ResultShow_OnEvent(event)
	if event == "XBWJHS_BATTLE_FULLDATA_UPDATE" then
		HuaShanLunJian2_ResultShow_OnShow()
	elseif event == "XBWJHS_BATTLE_SHOW" then
		HuaShanLunJian2_ResultShow_OnShow()
	elseif event == "XBWJHS_BATTLE_RESULT_UPDATE" then
		HuaShanLunJian2_ResultShow_OnResultShow()
	elseif event == "XBWJHS_BATTLE_UPDATE" then
		HuaShanLunJian2_ResultShow_RefreshUI()
	elseif event == "XBWJHS_BATTLE_TIME_UPDATE" then
		HuaShanLunJian2_ResultShow_InitData()
		HuaShanLunJian2_ResultShow_RefreshUI()
	elseif event == "XBWJHS_BATTLE_GAMEOVER" then
		HuaShanLunJian2_ResultShow_HideWindow()
	elseif event == "ADJEST_UI_POS" then
		HuaShanLunJian2_ResultShow_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		HuaShanLunJian2_ResultShow_ResetPos()
	elseif event == "SCENE_TRANSED" then
		if XBWJHS:IsInBattleScene() ~= 1 then
			HuaShanLunJian2_ResultShow_HideWindow()
		end
	end
end

--================================================
-- 显示信息
--================================================
function HuaShanLunJian2_ResultShow_OnShow()
	if (IsWindowShow("HuaShanLunJian2_ResultShowMini")) then
		return
	end

	HuaShanLunJian2_ResultShow_InitData()
	HuaShanLunJian2_ResultShow_InitOtherUI()
	HuaShanLunJian2_ResultShow_RefreshUI()
	this:Show()
end

--================================================
-- 显示信息
--================================================
function HuaShanLunJian2_ResultShow_OnResultShow()
	if (IsWindowShow("HuaShanLunJian2_ResultShowMini")) then
		CloseWindow("HuaShanLunJian2_ResultShowMini", true)
	end

	HuaShanLunJian2_ResultShow_InitData()
	HuaShanLunJian2_ResultShow_InitOtherUI()
	HuaShanLunJian2_ResultShow_RefreshUI(1)
	this:Show()
end

function HuaShanLunJian2_ResultShow_InitOtherUI()
	HuaShanLunJian2_ResultShow_Team_Left:SetText("")
	HuaShanLunJian2_ResultShow_Team_Right:SetText("")
	HuaShanLunJian2_ResultShow_Team1FirstKill:Hide()
	HuaShanLunJian2_ResultShow_Team2FirstKill:Hide()
	HuaShanLunJian2_ResultShow_TimeText:SetText("")
	HuaShanLunJian2_ResultShow_TimeWatch:Hide()
	HuaShanLunJian2_ResultShow_End:Hide()
	HuaShanLunJian2_ResultShow_Team_VS:Hide()
	HuaShanLunJian2_ResultShow_LiftPic:Hide()
	HuaShanLunJian2_ResultShow_RightPic:Hide()
	HuaShanLunJian2_ResultShow_Team_TitleBK:SetText("")
	HuaShanLunJian2_ResultShow_DragTitle:SetText("#{XLVL_260327_55}")
end

function HuaShanLunJian2_ResultShow_InitData()
	g_btimerset = 0
end

--================================================
-- 刷一遍信息
--================================================
function HuaShanLunJian2_ResultShow_RefreshUI(booResult)
	HuaShanLunJian2_ResultShow_RefreshTeamUI(booResult)
	HuaShanLunJian2_ResultShow_RefreshMemberUI(booResult)
end

--================================================
-- 刷一遍队伍信息
--================================================
function HuaShanLunJian2_ResultShow_RefreshTeamUI(booResult)

	local teamid_a,zoneid_a,teamname_a = XBWJHS:GetBattleTeamData(g_battle_type.team_a)
	local teamid_b,zoneid_b,teamname_b = XBWJHS:GetBattleTeamData(g_battle_type.team_b)
	if teamid_a <= 0 and teamid_b <= 0 then
		HuaShanLunJian2_ResultShow_InitOtherUI()
	else
		-- 名字
		HuaShanLunJian2_ResultShow_Team_Left:SetText(teamname_a)
		HuaShanLunJian2_ResultShow_Team_Right:SetText(teamname_b)
		-- 一血
		HuaShanLunJian2_ResultShow_Team1FirstKill:Hide()
		HuaShanLunJian2_ResultShow_Team2FirstKill:Hide()
		local fstblood = XBWJHS:GetBattleData("firstblood")
		if fstblood == teamid_a and fstblood > 0 then
			HuaShanLunJian2_ResultShow_Team1FirstKill:Show()
		elseif fstblood == teamid_b and fstblood > 0 then
			HuaShanLunJian2_ResultShow_Team2FirstKill:Show()
		end

		-- 比分
		local score_a,score_b = XBWJHS:GetBattleData("score")
		local szScore = score_a..":"..score_b
		HuaShanLunJian2_ResultShow_Team_TitleBK:SetText(szScore)

		-- 
		if booResult ~= nil and booResult > 0 then
			-- title
			HuaShanLunJian2_ResultShow_DragTitle:SetText("#{XLVL_260327_63}")
			-- 标识
			HuaShanLunJian2_ResultShow_End:Show()
			-- 胜负标识

			local winnerTeamId = XBWJHS:GetBattleData("result")
			if winnerTeamId == teamid_a and teamid_a > 0 then
				HuaShanLunJian2_ResultShow_LiftPic:SetProperty("Image", g_icon_result.win)
				HuaShanLunJian2_ResultShow_LiftPic:Show()
				HuaShanLunJian2_ResultShow_RightPic:SetProperty("Image", g_icon_result.lose)
				HuaShanLunJian2_ResultShow_RightPic:Show()
			elseif winnerTeamId == teamid_b and teamid_b > 0 then
				HuaShanLunJian2_ResultShow_RightPic:SetProperty("Image", g_icon_result.win)
				HuaShanLunJian2_ResultShow_RightPic:Show()
				HuaShanLunJian2_ResultShow_LiftPic:SetProperty("Image", g_icon_result.lose)
				HuaShanLunJian2_ResultShow_LiftPic:Show()
			end
		else
			local lefttime = XBWJHS:GetBattleData("lefttime")
			if g_btimerset == 0 then
				-- 倒计时
				g_btimerset = 1
	
				HuaShanLunJian2_ResultShow_TimeWatch:SetProperty("Timer", tostring(lefttime))
				HuaShanLunJian2_ResultShow_TimeWatch:Show()
			end
			if lefttime > 0 then
				HuaShanLunJian2_ResultShow_TimeText:SetText("#{WCBZ_220809_86}")
			else
				HuaShanLunJian2_ResultShow_TimeText:SetText("")
			end
		end
	end
end

--================================================
-- 刷一遍成员信息
--================================================
function HuaShanLunJian2_ResultShow_RefreshMemberUI(booResult)
	-- 遍历显示
	for teamIndex=1, g_team_max do
		for memberIndex=1, g_teammem_max do
			local i = (teamIndex-1)*g_teammem_max + memberIndex
			if g_ui_list[i] ~= nil then
				local data = XBWJHS:GetBattlePlayerData(teamIndex-1, memberIndex-1)
				-- 说明当前索引玩家不存在
				if data == nil or type(data) ~= "table" or data.name == "" then
					g_ui_list[i].name:SetText("")
					g_ui_list[i].mp:SetText("")
					g_ui_list[i].lv:SetText("")
					g_ui_list[i].kill:SetText("")
					g_ui_list[i].leader:Hide()
					g_ui_list[i].hp:SetProgress(0,100)
				else
					-- 名字
					local szname = HuaShanLunJian2_ResultShow_TransformName(data.name, teamIndex-1)
					g_ui_list[i].name:SetText(szname)
					-- 等级
					g_ui_list[i].lv:SetText(tostring(data.level))
					-- 门派
					local mpinfo = g_menpaiinfo[data.mp]
					if mpinfo ~= nil then
						g_ui_list[i].mp:SetText(mpinfo.name)
					else
						g_ui_list[i].mp:SetText("")
					end
					-- 是否是队长
					local postdata = g_teampost[data.post]
					if postdata == nil then
						g_ui_list[i].leader:Hide()
					else
						if postdata.show > 0 then
							g_ui_list[i].leader:SetProperty("Image", postdata.icon)
							g_ui_list[i].leader:Show()
						else
							g_ui_list[i].leader:Hide()
						end
					end
					-- 血量
					if booResult ~= nil and booResult > 0 then
						g_ui_list[i].hp:SetProgress(0,100)
					else
						g_ui_list[i].hp:SetProgress(data.hp,100)
					end
					-- 击败
					g_ui_list[i].kill:SetText(data.kill)
				end
			end
		end
	end
end

--================================================
-- 转换名字
--================================================
function HuaShanLunJian2_ResultShow_TransformName(name, teamidx)
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
function HuaShanLunJian2_ResultShow_ResetPos()
	HuaShanLunJian2_ResultShow_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function HuaShanLunJian2_ResultShow_OnTimer()
	HuaShanLunJian2_ResultShow_TimeText:SetText("")
	HuaShanLunJian2_ResultShow_TimeWatch:Hide()
	HuaShanLunJian2_ResultShow_End:Show()
end

--================================================
-- 选中目标
--================================================
function HuaShanLunJian2_ResultShow_Member_Click(teamIndex, memberIndex)

	if teamIndex < 1 or teamIndex > g_team_max then
		return
	end

	if memberIndex < 1 or memberIndex > g_teammem_max then
		return
	end
	
	local data = XBWJHS:GetBattlePlayerData(teamIndex-1, memberIndex-1)
	if data == nil or type(data) ~= "table" then
		return
	end

	XBWJHS:SetMainTargetByIdx(teamIndex-1, memberIndex-1)
end

--================================================
-- 关闭界面
--================================================
function HuaShanLunJian2_ResultShow_Close_Clicked()
	HuaShanLunJian2_ResultShow_HideWindow()
	PushEvent("XBWJHS_BATTLE_MINI_SHOW")
end

function HuaShanLunJian2_ResultShow_HideWindow()
	this:Hide()
end
