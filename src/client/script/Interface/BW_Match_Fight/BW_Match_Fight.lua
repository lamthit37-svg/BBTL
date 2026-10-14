-- 玩家血条积分UI
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_IsTimerSet = 0
local g_MenPaiNameList =
{
	-- [0]  ={Name="#{SCGZ_180816_30}" , Color="#cff6600", }, --shaolin
	-- [1]  ={Name="#{SCGZ_180816_31}" , Color="#c0000ff", }, --wudang
	-- [2]  ={Name="#{SCGZ_180816_32}" , Color="#c007700", }, --xingxiu
	-- [3]  ={Name="#{SCGZ_180816_33}" , Color="#cff99cc", }, --emei
	-- [4]  ={Name="#{SCGZ_180816_34}" , Color="#c7700ff", }, --xiaoyao
	-- [5]  ={Name="#{SCGZ_180816_35}" , Color="#cffffff", }, --tianshan
	-- [6]  ={Name="#{SCGZ_180816_36}" , Color="#cffcc00", }, --mingjiao
	-- [7]  ={Name="#{SCGZ_180816_37}" , Color="#c00ff00", }, --gaibang
	-- [8]  ={Name="#{SCGZ_180816_38}" , Color="#ccc00ff", }, --tangmen
	-- [9]  ={Name="#{SCGZ_180816_39}"     , Color="#c24dec6", }, --guigu
	-- [10] ={Name="#{SCGZ_180816_40}", Color="#c007fff", }, --murong
	-- [11] ={Name="#{SCGZ_180816_41}", Color="#cffff00", }, --tianlong
	-- [12] ={Name="无门派", Color="#c999999", },   --wumenpai
	[0]  ={Name="#{XQ_MP_1}" , Color="#cff6600", },
	[1]  ={Name="#{XQ_MP_2}" , Color="#cffcc00", },
	[2]  ={Name="#{XQ_MP_3}" , Color="#c00ff00", },
	[3]  ={Name="#{XQ_MP_4}" , Color="#c0000ff", },
	[4]  ={Name="#{XQ_MP_5}" , Color="#cff99cc", },
	[5]  ={Name="#{XQ_MP_6}" , Color="#c007700", },
	[6]  ={Name="#{XQ_MP_7}" , Color="#cffff00", },
	[7]  ={Name="#{XQ_MP_8}" , Color="#cffffff", },
	[8]  ={Name="#{XQ_MP_9}" , Color="#c7700ff", },
	[9]  ={Name="无门派"     , Color="#c999999", },	
	[10] ={Name="#{XQ_MP_10}", Color="#c007fff", },
	[11] ={Name="#{XQ_MP_13}", Color="#ccc00ff", },
	[12] ={Name="#{XMPGG_160524_02}", Color="#c24dec6", },   --鬼谷 待修改
	[13] ={Name="#{SCGZ_180816_119}", Color="#ca1d6da", },   --桃花岛
	[14] ={Name="#{XMPHM_210604_01}", Color="#cd61313", },
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", Color="#c656ab4", },--menpai15
}
local g_DuanWei1 = {
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
}
local g_DieColor = "#cff0000"
local g_DiaoXianColoer = "#ccccccc"

local g_Team_HP_Ctrl_List = {}
local g_Team_Level_Ctrl_List = {}
local g_Team_MenPai_Ctrl_List = {}
local g_Team_Name_Ctrl_List = {}

function BW_Match_Fight_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED2018",false)
	this:RegisterEvent("BWTROOPS_SHOW_FULLDATA_BOX2018")
	this:RegisterEvent("BWTROOPS_COPYDATA_FIRST_TIME2018")
	this:RegisterEvent("BWTROOPS_COPYDATA_REFRESH2018")
	this:RegisterEvent("BWTROOPS_COPYDATA_SYNC_TIME2018")
	this:RegisterEvent("BWTROOPS_RESULT_SHOW")
	this:RegisterEvent("BWTROOPS_COPYDATA_FULL_INFO2018")
	this:RegisterEvent("BWTROOPS_UPDATE_STATE2018")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function BW_Match_Fight_CtrlList_InitData()

	for i=1, 12 do
		g_Team_Name_Ctrl_List[i]:SetText("")
		g_Team_MenPai_Ctrl_List[i]:SetText("")
		g_Team_Level_Ctrl_List[i]:SetText("")
		g_Team_HP_Ctrl_List[i]:SetProgress(0, 100)
	end

	BW_Match_Fight_Team1FirstKill:Hide()
	BW_Match_Fight_Team2FirstKill:Hide()
	--BW_Match_Fight_Team_Left:SetText("")
	--BW_Match_Fight_Team_Right:SetText("")
	BW_Match_Fight_TimeText:SetText("")
	BW_Match_Fight_TimeWatch:Hide()
	BW_Match_Fight_WatchText:SetText("")
	BW_Match_Fight_WatchText:Hide()
	BW_Match_Fight_LeftList_TitleBK:Hide()
	BW_Match_Fight_RightList_TitleBK:Hide()

end

function BW_Match_Fight_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BW_Match_Fight_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BW_Match_Fight_Frame:GetProperty("UnifiedYPosition");

	--索引1到3归第一战队；其他4-6属于第二战队 !!!!!!!!!!因为改成6v6所以 7-9属于第一队 10-12属于第二队
	--被策划小姐姐带沟里去了，空间名是level，我就以为也是level，结果是段位
	g_Team_Level_Ctrl_List[1] = BW_Match_Fight_Left_1_Level;
	g_Team_Level_Ctrl_List[2] = BW_Match_Fight_Left_2_Level;
	g_Team_Level_Ctrl_List[3] = BW_Match_Fight_Left_3_Level;

	g_Team_Level_Ctrl_List[4] = BW_Match_Fight_Right_1_Level;
	g_Team_Level_Ctrl_List[5] = BW_Match_Fight_Right_2_Level;
	g_Team_Level_Ctrl_List[6] = BW_Match_Fight_Right_3_Level;
	
	g_Team_Level_Ctrl_List[7] = BW_Match_Fight_Left_4_Level;
	g_Team_Level_Ctrl_List[8] = BW_Match_Fight_Left_5_Level;
	g_Team_Level_Ctrl_List[9] = BW_Match_Fight_Left_6_Level;

	g_Team_Level_Ctrl_List[10] = BW_Match_Fight_Right_4_Level;
	g_Team_Level_Ctrl_List[11] = BW_Match_Fight_Right_5_Level;
	g_Team_Level_Ctrl_List[12] = BW_Match_Fight_Right_6_Level;


	g_Team_MenPai_Ctrl_List[1] = BW_Match_Fight_Left_1_Career;
	g_Team_MenPai_Ctrl_List[2] = BW_Match_Fight_Left_2_Career;
	g_Team_MenPai_Ctrl_List[3] = BW_Match_Fight_Left_3_Career;

	g_Team_MenPai_Ctrl_List[4] = BW_Match_Fight_Right_1_Career;
	g_Team_MenPai_Ctrl_List[5] = BW_Match_Fight_Right_2_Career;
	g_Team_MenPai_Ctrl_List[6] = BW_Match_Fight_Right_3_Career;
	
	g_Team_MenPai_Ctrl_List[7] = BW_Match_Fight_Left_4_Career;
	g_Team_MenPai_Ctrl_List[8] = BW_Match_Fight_Left_5_Career;
	g_Team_MenPai_Ctrl_List[9] = BW_Match_Fight_Left_6_Career;

	g_Team_MenPai_Ctrl_List[10] = BW_Match_Fight_Right_4_Career;
	g_Team_MenPai_Ctrl_List[11] = BW_Match_Fight_Right_5_Career;
	g_Team_MenPai_Ctrl_List[12] = BW_Match_Fight_Right_6_Career;


	g_Team_Name_Ctrl_List[1] = BW_Match_Fight_Left_1_name;
	g_Team_Name_Ctrl_List[2] = BW_Match_Fight_Left_2_name;
	g_Team_Name_Ctrl_List[3] = BW_Match_Fight_Left_3_name;

	g_Team_Name_Ctrl_List[4] = BW_Match_Fight_Right_1_name;
	g_Team_Name_Ctrl_List[5] = BW_Match_Fight_Right_2_name;
	g_Team_Name_Ctrl_List[6] = BW_Match_Fight_Right_3_name;
	
	g_Team_Name_Ctrl_List[7] = BW_Match_Fight_Left_4_name;
	g_Team_Name_Ctrl_List[8] = BW_Match_Fight_Left_5_name;
	g_Team_Name_Ctrl_List[9] = BW_Match_Fight_Left_6_name;

	g_Team_Name_Ctrl_List[10] = BW_Match_Fight_Right_4_name;
	g_Team_Name_Ctrl_List[11] = BW_Match_Fight_Right_5_name;
	g_Team_Name_Ctrl_List[12] = BW_Match_Fight_Right_6_name;


	g_Team_HP_Ctrl_List[1] = BW_Match_Fight_Left_PlayerHP1;
	g_Team_HP_Ctrl_List[2] = BW_Match_Fight_Left_PlayerHP2;
	g_Team_HP_Ctrl_List[3] = BW_Match_Fight_Left_PlayerHP3;

	g_Team_HP_Ctrl_List[4] = BW_Match_Fight_Right_PlayerHP1;
	g_Team_HP_Ctrl_List[5] = BW_Match_Fight_Right_PlayerHP2;
	g_Team_HP_Ctrl_List[6] = BW_Match_Fight_Right_PlayerHP3;
	
	g_Team_HP_Ctrl_List[7] = BW_Match_Fight_Left_PlayerHP4;
	g_Team_HP_Ctrl_List[8] = BW_Match_Fight_Left_PlayerHP5;
	g_Team_HP_Ctrl_List[9] = BW_Match_Fight_Left_PlayerHP6;

	g_Team_HP_Ctrl_List[10] = BW_Match_Fight_Right_PlayerHP4;
	g_Team_HP_Ctrl_List[11] = BW_Match_Fight_Right_PlayerHP5;
	g_Team_HP_Ctrl_List[12] = BW_Match_Fight_Right_PlayerHP6;

	BW_Match_Fight_CtrlList_InitData()
end

function BW_Match_Fight_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BW_Match_Fight_ResetPos()
	elseif( event == "BWTROOPS_SHOW_FULLDATA_BOX2018") then
		--读取数据显示
		BW_Match_Fight_CtrlList_InitData()
		BW_Match_FightFrame_FullFill_Data()
		this:Show()
	elseif (event == "BWTROOPS_COPYDATA_FIRST_TIME2018")	then
		--读取数据显示
		BW_Match_Fight_CtrlList_InitData()
		--2.初始化
		g_IsTimerSet = 0
		--g_IsFuckBaby = 0
		BW_Match_FightFrame_FullFill_Data()
		--只在该事件里面，开始计时器。
		BW_Match_Fight_SetTimer()
		this:Show()
	elseif (event == "BWTROOPS_COPYDATA_FULL_INFO2018" )	then
		--读取数据显示
		BW_Match_Fight_CtrlList_InitData()
		--2.初始化
		g_IsTimerSet = 0
		--GM进来的时候，会触发这个设置.如果置为1，则此次且场景事件不执行。
		--g_IsFuckBaby = 1
		BW_Match_FightFrame_FullFill_Data()
		--只在该事件里面，开始计时器。
		BW_Match_Fight_SetTimer()
		this:Show()
	elseif  (event == "BWTROOPS_COPYDATA_REFRESH2018" )	 then
		if (this:IsVisible())  then
			--读取数据显示更新
			BW_Match_Fight_CtrlList_InitData()
			BW_Match_FightFrame_FullFill_Data()
		end
	elseif ( event =="BWTROOPS_COPYDATA_SYNC_TIME2018") then
		if (this:IsVisible())  then
			BW_Match_FightFrame_Sync_Time()
		end

	elseif(event == "BWTROOPS_RESULT_SHOW")	 then
		BW_Match_Fight_CtrlList_InitData()
		this:Hide()
	elseif(event == "BWTROOPS_UPDATE_STATE2018")	 then
		if (this:IsVisible())  then
			--读取数据显示更新
			BW_Match_Fight_CtrlList_InitData()
			BW_Match_FightFrame_FullFill_Data()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BW_Match_Fight_CtrlList_InitData()
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_Match_Fight_ResetPos()
	BW_Match_Fight_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BW_Match_Fight_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BW_Match_FightFrame_CloseWindow()
	this:Hide()
	PushEvent( "BWTROOPS_SHOW_MINI_BOX2018" )
end

--================================================
-- 刷新同步的时间数据
--================================================
function BW_Match_FightFrame_Sync_Time()
	local nCountTimers = BWDH2018:GetBWTroopsPK_LeftTimes2018()
	if nCountTimers == nil then
		nCountTimers = 0
	end
	BW_Match_Fight_TimeWatch:SetProperty("Timer", tostring(nCountTimers))
	BW_Match_Fight_TimeWatch:Show()
end
--================================================
-- 填充数据
--================================================
function BW_Match_FightFrame_FullFill_Data()


	local mUIDir = BWDH2018:GetMyUIDirInfo()
	if mUIDir == nil then
		return 
	end
	if mUIDir == 0 then
		for i=1, 12 do
			local nGuid,nHP,nLevel,nMenPai,szName,nkill,nstate,nSeasonPartCnt,nSeasonWinCnt= BWDH2018:GetCopySceneBWPlayerInfoByIdx2018(i-1)
			local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
			--碰到不合法的GUID，说明6个人没满。
			--PushDebugMessage(nDuanWei)
			if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

				--玩家状态： 　
				if nstate == 0 then      --0-正常
						g_Team_Name_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..szName)  --名字
						g_Team_MenPai_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)  --门派
						g_Team_Level_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..g_DuanWei1[nDuanWei])  --duanewi
						g_Team_HP_Ctrl_List[i]:SetProgress(nHP, 100)--血量百分比
				elseif nstate == 1 then  --1-死亡
						g_Team_Name_Ctrl_List[i]:SetText(g_DieColor..szName)  --名字
						g_Team_MenPai_Ctrl_List[i]:SetText(g_DieColor..g_MenPaiNameList[nMenPai].Name)  --门派
						g_Team_Level_Ctrl_List[i]:SetText(g_DieColor..g_DuanWei1[nDuanWei])  --等级
						g_Team_HP_Ctrl_List[i]:SetProgress(nHP, 100)--血量百分比
				elseif nstate == 2 then  --2-掉线
						g_Team_Name_Ctrl_List[i]:SetText("")
						g_Team_MenPai_Ctrl_List[i]:SetText("")
						g_Team_Level_Ctrl_List[i]:SetText("")
						g_Team_HP_Ctrl_List[i]:SetProgress(0, 100)
				end

			end
		end
	elseif mUIDir == 1 then
		for i=1, 12 do
			if (i <= 3) or (i > 6 and i <= 9) then
				local nGuid,nHP,nLevel,nMenPai,szName,nkill,nstate,nSeasonPartCnt,nSeasonWinCnt= BWDH2018:GetCopySceneBWPlayerInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				--PushDebugMessage(nDuanWei)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--玩家状态： 　
					if nstate == 0 then      --0-正常
							g_Team_Name_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)  --名字
							g_Team_MenPai_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)  --门派
							g_Team_Level_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..g_DuanWei1[nDuanWei])  --等级
							g_Team_HP_Ctrl_List[i+3]:SetProgress(nHP, 100)--血量百分比
					elseif nstate == 1 then  --1-死亡
							g_Team_Name_Ctrl_List[i+3]:SetText(g_DieColor..szName)  --名字
							g_Team_MenPai_Ctrl_List[i+3]:SetText(g_DieColor..g_MenPaiNameList[nMenPai].Name)  --门派
							g_Team_Level_Ctrl_List[i+3]:SetText(g_DieColor..g_DuanWei1[nDuanWei])  --等级
							g_Team_HP_Ctrl_List[i+3]:SetProgress(nHP, 100)--血量百分比
					elseif nstate == 2 then  --2-掉线
							g_Team_Name_Ctrl_List[i+3]:SetText("")
							g_Team_MenPai_Ctrl_List[i+3]:SetText("")
							g_Team_Level_Ctrl_List[i+3]:SetText("")
							g_Team_HP_Ctrl_List[i+3]:SetProgress(0, 100)
					end

				end
			end
			if (i > 3 and i <= 6) or (i > 9 and i <= 12)  then
				local nGuid,nHP,nLevel,nMenPai,szName,nkill,nstate,nSeasonPartCnt,nSeasonWinCnt= BWDH2018:GetCopySceneBWPlayerInfoByIdx2018(i-1)
				local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				--PushDebugMessage(nDuanWei)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--玩家状态： 　
					if nstate == 0 then      --0-正常
							g_Team_Name_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)  --名字
							g_Team_MenPai_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)  --门派
							g_Team_Level_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..g_DuanWei1[nDuanWei])  --等级
							g_Team_HP_Ctrl_List[i-3]:SetProgress(nHP, 100)--血量百分比
					elseif nstate == 1 then  --1-死亡
							g_Team_Name_Ctrl_List[i-3]:SetText(g_DieColor..szName)  --名字
							g_Team_MenPai_Ctrl_List[i-3]:SetText(g_DieColor..g_MenPaiNameList[nMenPai].Name)  --门派
							g_Team_Level_Ctrl_List[i-3]:SetText(g_DieColor..g_DuanWei1[nDuanWei])  --等级
							g_Team_HP_Ctrl_List[i-3]:SetProgress(nHP, 100)--血量百分比
					elseif nstate == 2 then  --2-掉线
							g_Team_Name_Ctrl_List[i-3]:SetText("")
							g_Team_MenPai_Ctrl_List[i-3]:SetText("")
							g_Team_Level_Ctrl_List[i-3]:SetText("")
							g_Team_HP_Ctrl_List[i-3]:SetProgress(0, 100)
					end

				end
			end
			
		end
	end

	local nKillerType = BWDH2018:GetCopySceneBWFirstKillerType2018()
	if mUIDir == 0 then
		BW_Match_Fight_LeftList_TitleBK:Show()
		BW_Match_Fight_RightList_TitleBK:Show()
		BW_Match_Fight_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		BW_Match_Fight_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		if nKillerType == 1 then
			BW_Match_Fight_Team1FirstKill:Show()
			BW_Match_Fight_Team2FirstKill:Hide()
		elseif nKillerType == 2 then
			BW_Match_Fight_Team1FirstKill:Hide()
			BW_Match_Fight_Team2FirstKill:Show()
		else
			BW_Match_Fight_Team1FirstKill:Hide()
			BW_Match_Fight_Team2FirstKill:Hide()
		end
	else
		BW_Match_Fight_LeftList_TitleBK:Show()
		BW_Match_Fight_RightList_TitleBK:Show()
		BW_Match_Fight_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		BW_Match_Fight_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		if nKillerType == 1 then
			BW_Match_Fight_Team1FirstKill:Hide()
			BW_Match_Fight_Team2FirstKill:Show()
		elseif nKillerType == 2 then
			BW_Match_Fight_Team1FirstKill:Show()
			BW_Match_Fight_Team2FirstKill:Hide()
		else
			BW_Match_Fight_Team1FirstKill:Hide()
			BW_Match_Fight_Team2FirstKill:Hide()
		end
	end
	-- local sNameA, sNameB = BWDH:GetTwoBWTroopsNameInCopyScene()
	-- if sNameA == nil then sNameA ="" end
	-- if sNameB == nil then sNameB = "" end
	-- BW_Match_Fight_Team1Name:SetText(sNameA)
	-- BW_Match_Fight_Team2Name:SetText(sNameB)
	BW_Match_Fight_TimeText:SetText("#{ZBS_YXS_120301_79}")
	if g_IsTimerSet == 0 then
		--因为只有在最初的时候同步一次时间；另外，就是玩家短线重连同步一次时间
		--倒计时纯客户端行为，虽然Server端有计时，但不向客户端同步了。
		g_IsTimerSet = 1
		BW_Match_Fight_SetTimer()
	else
		BW_Match_Fight_TimeWatch:Show()
	end
end

function BW_Match_Fight_SetTimer()

	local nCountTimers = BWDH2018:GetBWTroopsPK_LeftTimes2018()
	if nCountTimers == nil then
		nCountTimers = 0
	end
	if nCountTimers <= 0 then
		return
	end
	BW_Match_Fight_TimeWatch:SetProperty("Timer", tostring(nCountTimers))
	BW_Match_Fight_TimeWatch:Show()

end

function BW_Match_Fight_OnTimer()
	BW_Match_Fight_TimeWatch:Hide()
	BW_Match_Fight_WatchText:SetText("结束")
	BW_Match_Fight_WatchText:Show()
end

function BW_Match_Fight_Raid_Click(idx)
    if idx < 1 or idx > 12 then
        return
    end
	local mUIDir = BWDH2018:GetMyUIDirInfo()
	if mUIDir == nil then
		return 
	end 
	if mUIDir == 0 then
		BWDH2018:SetBMMainTargetByUIIdx2018(idx)
	elseif mUIDir == 1 then
		if (idx <= 3) or (idx > 6 and idx <= 9) then
			BWDH2018:SetBMMainTargetByUIIdx2018(idx+3)
		elseif (idx > 3 and idx <= 6) or (idx > 9 and idx <= 12) then
			BWDH2018:SetBMMainTargetByUIIdx2018(idx-3)
		end
	end
    
end
