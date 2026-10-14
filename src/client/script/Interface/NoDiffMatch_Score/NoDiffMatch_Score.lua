-- 玩家血条积分UI
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_IsTimerSet = 0
local g_IsFuckBaby = 0
local g_MenPaiNameList =
{
	[0]  ={Name="#{WCBZ_180128_59}"},	--少林
	[1]  ={Name="#{WCBZ_180128_65}"},	--明教
	[2]  ={Name="#{WCBZ_180128_67}"},	--丐帮
	[3]  ={Name="#{WCBZ_180128_61}"},	--武当
	[4]  ={Name="#{WCBZ_180128_68}"},	--峨嵋
	[5]  ={Name="#{WCBZ_180128_66}"},	--星宿
	[6]  ={Name="#{WCBZ_180128_60}"},	--天龙
	[7]  ={Name="#{WCBZ_180128_63}"},	--天山
	[8]  ={Name="#{WCBZ_180128_64}"},	--逍遥
	[9]  ={Name=""},
	[10] ={Name="#{WCBZ_180128_62}"},	--慕容
	[11] ={Name="#{WCBZ_180128_69}"},	--唐门
	[12] ={Name="#{WCBZ_180128_70}"},	--鬼谷 待修改
	[13] ={Name="#{WCBZ_180516_646}"},	--桃花岛
	[14] ={Name="#{XMPHM_210604_01}"},
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}"},--menpai15 mptodo
}


local g_HP_Ctrl_List = {};
local g_Level_Ctrl_List = {};
local g_MenPai_Ctrl_List = {};
local g_Name_Ctrl_List = {};
local g_Icon_Ctrl_List = {};

local g_GuidList = {"","","","","","","","","","","","",}
local g_MemCount_All = 12
local g_MaxCropsMemCount = 6


local g_TeamAInfo = {}
local g_TeamBInfo = {}


--排序用
local g_MemberListA =  --pos:1队员 2副队长 3队长
{
	[1]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[2]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[3]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[4]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[5]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[6]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
}

local g_MemberListB =  --pos:1队员 2副队长 3队长
{
	[1]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[2]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[3]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[4]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[5]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
	[6]  ={Name="",MP=-1,Level=0,pos=0,HP=0,Guid="",Eqhh=0},
}

local g_CorpsLeaderIcon = "set:Union1 image:Union_LeaderIcon_L"
local g_CorpsAssistantIcon = "set:Union1 image:Union_MemberIcon_L"

function NoDiffMatch_Score_PreLoad()

	this:RegisterEvent("SCENE_TRANSED", false)
	this:RegisterEvent("SHOW_FULLDATA_BOX_2018")
	this:RegisterEvent("CORPS_COPYDATA_FIRST_TIME_2018")
	this:RegisterEvent("CORPS_COPYDATA_REFRESH_2018", false)
	this:RegisterEvent("CORPS_COPYDATA_SYNC_TIME_2018", false)
	this:RegisterEvent("RELIVE_HIDE")
	this:RegisterEvent("SHOW_PK_RESULT_2018")
	this:RegisterEvent("CORPS_COPYDATA_FULL_INFO_2018")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_Score_CtrlList_InitData()

	for i=1, g_MemCount_All do
		g_Name_Ctrl_List[i]:SetText("")
		g_Icon_Ctrl_List[i]:Hide()
		g_MenPai_Ctrl_List[i]:SetText("")
		g_Level_Ctrl_List[i]:SetText("")
		g_HP_Ctrl_List[i]:SetProgress(0, 100)
		g_GuidList[i] = ""
	end

	for i=1, g_MaxCropsMemCount do
		g_MemberListA[i].Name = ""
		g_MemberListA[i].MP = 9
		g_MemberListA[i].Level = 0
		g_MemberListA[i].pos = 0
		g_MemberListA[i].HP = 0
		g_MemberListA[i].Guid = ""
		g_MemberListA[i].Eqhh = 0

		g_MemberListB[i].Name = ""
		g_MemberListB[i].MP = 9
		g_MemberListB[i].Level = 0
		g_MemberListB[i].pos = 0
		g_MemberListB[i].HP = 0
		g_MemberListB[i].Guid = ""
		g_MemberListB[i].Eqhh = 0
	end

	NoDiffMatch_Score_Team_Left:SetText("")
	NoDiffMatch_Score_Team_Right:SetText("")
	NoDiffMatch_Score_Team1FirstKill:Hide()
	NoDiffMatch_Score_Team2FirstKill:Hide()
	NoDiffMatch_Score_TimeText:SetText("")
	NoDiffMatch_Score_TimeWatch:Hide()
	NoDiffMatch_Score_WatchText:SetText("")
	NoDiffMatch_Score_WatchText:Hide()
end


function NoDiffMatch_Score_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Score_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Score_Frame:GetProperty("UnifiedYPosition");

	g_Icon_Ctrl_List[1] = NoDiffMatch_Score_Left_1_Icon;
	g_Icon_Ctrl_List[2] = NoDiffMatch_Score_Left_2_Icon;
	g_Icon_Ctrl_List[3] = NoDiffMatch_Score_Left_3_Icon;
	g_Icon_Ctrl_List[4] = NoDiffMatch_Score_Left_4_Icon;
	g_Icon_Ctrl_List[5] = NoDiffMatch_Score_Left_5_Icon;
	g_Icon_Ctrl_List[6] = NoDiffMatch_Score_Left_6_Icon;
	g_Icon_Ctrl_List[7] = NoDiffMatch_Score_Right_1_Icon;
	g_Icon_Ctrl_List[8] = NoDiffMatch_Score_Right_2_Icon;
	g_Icon_Ctrl_List[9] = NoDiffMatch_Score_Right_3_Icon;
	g_Icon_Ctrl_List[10] = NoDiffMatch_Score_Right_4_Icon;
	g_Icon_Ctrl_List[11] = NoDiffMatch_Score_Right_5_Icon;
	g_Icon_Ctrl_List[12] = NoDiffMatch_Score_Right_6_Icon;


	g_Level_Ctrl_List[1] = NoDiffMatch_Score_Left_1_Level;
	g_Level_Ctrl_List[2] = NoDiffMatch_Score_Left_2_Level;
	g_Level_Ctrl_List[3] = NoDiffMatch_Score_Left_3_Level;
	g_Level_Ctrl_List[4] = NoDiffMatch_Score_Left_4_Level;
	g_Level_Ctrl_List[5] = NoDiffMatch_Score_Left_5_Level;
	g_Level_Ctrl_List[6] = NoDiffMatch_Score_Left_6_Level;
	g_Level_Ctrl_List[7] = NoDiffMatch_Score_Right_1_Level;
	g_Level_Ctrl_List[8] = NoDiffMatch_Score_Right_2_Level;
	g_Level_Ctrl_List[9] = NoDiffMatch_Score_Right_3_Level;
	g_Level_Ctrl_List[10] = NoDiffMatch_Score_Right_4_Level;
	g_Level_Ctrl_List[11] = NoDiffMatch_Score_Right_5_Level;
	g_Level_Ctrl_List[12] = NoDiffMatch_Score_Right_6_Level;

	g_MenPai_Ctrl_List[1] = NoDiffMatch_Score_Left_1_Career;
	g_MenPai_Ctrl_List[2] = NoDiffMatch_Score_Left_2_Career;
	g_MenPai_Ctrl_List[3] = NoDiffMatch_Score_Left_3_Career;
	g_MenPai_Ctrl_List[4] = NoDiffMatch_Score_Left_4_Career;
	g_MenPai_Ctrl_List[5] = NoDiffMatch_Score_Left_5_Career;
	g_MenPai_Ctrl_List[6] = NoDiffMatch_Score_Left_6_Career;
	g_MenPai_Ctrl_List[7] = NoDiffMatch_Score_Right_1_Career;
	g_MenPai_Ctrl_List[8] = NoDiffMatch_Score_Right_2_Career;
	g_MenPai_Ctrl_List[9] = NoDiffMatch_Score_Right_3_Career;
	g_MenPai_Ctrl_List[10] = NoDiffMatch_Score_Right_4_Career;
	g_MenPai_Ctrl_List[11] = NoDiffMatch_Score_Right_5_Career;
	g_MenPai_Ctrl_List[12] = NoDiffMatch_Score_Right_6_Career;

	g_Name_Ctrl_List[1] = NoDiffMatch_Score_Left_1_name;
	g_Name_Ctrl_List[2] = NoDiffMatch_Score_Left_2_name;
	g_Name_Ctrl_List[3] = NoDiffMatch_Score_Left_3_name;
	g_Name_Ctrl_List[4] = NoDiffMatch_Score_Left_4_name;
	g_Name_Ctrl_List[5] = NoDiffMatch_Score_Left_5_name;
	g_Name_Ctrl_List[6] = NoDiffMatch_Score_Left_6_name;
	g_Name_Ctrl_List[7] = NoDiffMatch_Score_Right_1_name;
	g_Name_Ctrl_List[8] = NoDiffMatch_Score_Right_2_name;
	g_Name_Ctrl_List[9] = NoDiffMatch_Score_Right_3_name;
	g_Name_Ctrl_List[10] = NoDiffMatch_Score_Right_4_name;
	g_Name_Ctrl_List[11] = NoDiffMatch_Score_Right_5_name;
	g_Name_Ctrl_List[12] = NoDiffMatch_Score_Right_6_name;

	g_HP_Ctrl_List[1] = NoDiffMatch_Score_Left_PlayerHP1;
	g_HP_Ctrl_List[2] = NoDiffMatch_Score_Left_PlayerHP2;
	g_HP_Ctrl_List[3] = NoDiffMatch_Score_Left_PlayerHP3;
	g_HP_Ctrl_List[4] = NoDiffMatch_Score_Left_PlayerHP4;
	g_HP_Ctrl_List[5] = NoDiffMatch_Score_Left_PlayerHP5;
	g_HP_Ctrl_List[6] = NoDiffMatch_Score_Left_PlayerHP6;
	g_HP_Ctrl_List[7] = NoDiffMatch_Score_Right_PlayerHP1;
	g_HP_Ctrl_List[8] = NoDiffMatch_Score_Right_PlayerHP2;
	g_HP_Ctrl_List[9] = NoDiffMatch_Score_Right_PlayerHP3;
	g_HP_Ctrl_List[10] = NoDiffMatch_Score_Right_PlayerHP4;
	g_HP_Ctrl_List[11] = NoDiffMatch_Score_Right_PlayerHP5;
	g_HP_Ctrl_List[12] = NoDiffMatch_Score_Right_PlayerHP6;


	g_TeamAInfo = { list = g_MemberListA, FirstKill = NoDiffMatch_Score_Team1FirstKill,name=NoDiffMatch_Score_Team_Left, count = 1}
	g_TeamBInfo = { list = g_MemberListB, FirstKill = NoDiffMatch_Score_Team2FirstKill,name=NoDiffMatch_Score_Team_Right, count = 1}


	NoDiffMatch_Score_CtrlList_InitData()
end

function NoDiffMatch_Score_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	
	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Score_ResetPos()

	elseif( event == "SHOW_FULLDATA_BOX_2018") then
		--读取数据显示
		NoDiffMatch_Score_CtrlList_InitData()
		NoDiffMatch_ScoreFrame_FullFill_Data()
		this:Show()
	elseif (event == "CORPS_COPYDATA_FIRST_TIME_2018")	then
		--读取数据显示
		NoDiffMatch_Score_CtrlList_InitData()
		--2.初始化
		g_IsTimerSet = 0
		g_IsFuckBaby = 0
		NoDiffMatch_ScoreFrame_FullFill_Data()
		--只在该事件里面，开始计时器。
		NoDiffMatch_Score_SetTimer()
		this:Show()
	elseif (event == "CORPS_COPYDATA_FULL_INFO_2018" )	then
		--读取数据显示
		NoDiffMatch_Score_CtrlList_InitData()
		--2.初始化
		g_IsTimerSet = 0
		--GM进来的时候，会触发这个设置.如果置为1，则此次且场景事件不执行。
		g_IsFuckBaby = 1
		NoDiffMatch_ScoreFrame_FullFill_Data()
		--只在该事件里面，开始计时器。
		NoDiffMatch_Score_SetTimer()
		this:Show()
	elseif( event == "SCENE_TRANSED" ) then
		--忽略此次切场景事件
		if g_IsFuckBaby == 1 then
			g_IsFuckBaby = 0
			return
		end
		NoDiffMatch_Score_CtrlList_InitData()
		--1.切场景才关闭那个UI，下次肯定重新计时。
		g_IsTimerSet = 0
		g_IsFuckBaby = 0
		this:Hide()
	elseif  (event == "CORPS_COPYDATA_REFRESH_2018" )	 then
		if (this:IsVisible())  then
			--读取数据显示更新
			NoDiffMatch_Score_CtrlList_InitData()
			NoDiffMatch_ScoreFrame_FullFill_Data()
		end
	elseif ( event =="CORPS_COPYDATA_SYNC_TIME_2018") then
		if (this:IsVisible())  then
			NoDiffMatch_ScoreFrame_Sync_Time()
		end
	elseif ( event == "RELIVE_HIDE"	) then
		local nGameOver = CorpsUI_2018:IsCorpsGameOver()
		
		--如果没有结束，并且处于隐藏状态，再显示给玩家看看。
		--如果游戏结束了，这个UI就没有必要显示了。否则会出现2个UI
		
		local bInPkScene = CorpsUI_2018:IsInZbsMatchScene()
		
		if (this:IsVisible() == false and nGameOver == 0 and bInPkScene == 1 )  then
			--读取数据显示更新
			NoDiffMatch_Score_CtrlList_InitData()
			NoDiffMatch_ScoreFrame_FullFill_Data()
			this:Show()
		end
	elseif(event == "SHOW_PK_RESULT_2018")	 then
		this:Hide()
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_Score_ResetPos()
	NoDiffMatch_Score_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Score_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_ScoreFrame_CloseWindow()
	this:Hide()
	PushEvent( "CORPS_SHOW_MINI_BOX_2018", 1 )
end
--================================================
-- 刷新同步的时间数据
--================================================
function NoDiffMatch_ScoreFrame_Sync_Time()
	local nCountTimers = CorpsUI_2018:GetCorpsPK_LeftTimes()
	if nCountTimers == nil then
		nCountTimers = 0
	end
	NoDiffMatch_Score_TimeWatch:SetProperty("Timer", tostring(nCountTimers))
	NoDiffMatch_Score_TimeWatch:Show()
end
--================================================
-- 填充数据
--================================================
function NoDiffMatch_ScoreFrame_FullFill_Data()

	local nMemCntA = 1
	local nMemCntB = 1

	local myteam = g_TeamAInfo
	local enemyteam = g_TeamBInfo

	myteam.count = 1
	enemyteam.count = 1
	local myGuid = Player:GetGUID();

	for i=1, g_MemCount_All do
		local nGuid = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i-1)
		if nGuid == myGuid then
			if i <= g_MaxCropsMemCount then
				myteam = g_TeamAInfo
				enemyteam = g_TeamBInfo
			else
				myteam = g_TeamBInfo
				enemyteam = g_TeamAInfo
			end
			break
		end
	end


	for i=1, g_MemCount_All do
		local nGuid,nHP,nLevel,nMenPai,nPos,szName,nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i-1)
		--碰到不合法的GUID，说明10个人没满。
		if nGuid == "" then
			--非法值
			continue
		end

		if i <= g_MaxCropsMemCount then
				myteam.list[nMemCntA].Name = szName
				myteam.list[nMemCntA].MP = nMenPai
				myteam.list[nMemCntA].Level = nLevel
				myteam.list[nMemCntA].pos = nPos
				myteam.list[nMemCntA].HP = nHP
				myteam.list[nMemCntA].Guid = nGuid
				nMemCntA = nMemCntA + 1
			else
				enemyteam.list[nMemCntB].Name = szName
				enemyteam.list[nMemCntB].MP = nMenPai
				enemyteam.list[nMemCntB].Level = nLevel
				enemyteam.list[nMemCntB].pos = nPos
				enemyteam.list[nMemCntB].HP = nHP
				enemyteam.list[nMemCntB].Guid = nGuid
				nMemCntB = nMemCntB + 1
		end
	end

	myteam.count = nMemCntA
	enemyteam.count = nMemCntB


	for index=1, g_MemCount_All do
		if index <= g_MaxCropsMemCount then
				--if index <= myteam.count then
					if g_MemberListA[index].Name == "" then
						continue
					end
					if g_MemberListA[index].pos == 3 then --队长标记
						g_Icon_Ctrl_List[index]:SetProperty("Image", g_CorpsLeaderIcon)
						g_Icon_Ctrl_List[index]:Show()
					elseif g_MemberListA[index].pos == 2 then
						g_Icon_Ctrl_List[index]:SetProperty("Image", g_CorpsAssistantIcon)
						g_Icon_Ctrl_List[index]:Show()
					end
					--名字
					g_Name_Ctrl_List[index]:SetText(g_MemberListA[index].Name)
					--门派
					local nMenPai = g_MemberListA[index].MP
					g_MenPai_Ctrl_List[index]:SetText(g_MenPaiNameList[nMenPai].Name)
					--等级
					g_Level_Ctrl_List[index]:SetText(g_MemberListA[index].Level)
					--血量百分比
					g_HP_Ctrl_List[index]:SetProgress(g_MemberListA[index].HP, 100)

					g_GuidList[index] = g_MemberListA[index].Guid
				--end

		else
			--if index-10 <= enemyteam.count then
				if g_MemberListB[index - g_MaxCropsMemCount].Name == "" then
					continue
				end

				if g_MemberListB[index - g_MaxCropsMemCount].pos == 3 then --队长标记
					g_Icon_Ctrl_List[index]:SetProperty("Image", g_CorpsLeaderIcon)
					g_Icon_Ctrl_List[index]:Show()
				elseif g_MemberListB[index - g_MaxCropsMemCount].pos == 2 then
					g_Icon_Ctrl_List[index]:SetProperty("Image", g_CorpsAssistantIcon)
					g_Icon_Ctrl_List[index]:Show()
				end
				--名字
				g_Name_Ctrl_List[index]:SetText(g_MemberListB[index - g_MaxCropsMemCount].Name)
				--门派
				local nMenPai = g_MemberListB[index - g_MaxCropsMemCount].MP
				g_MenPai_Ctrl_List[index]:SetText(g_MenPaiNameList[nMenPai].Name)
				--等级
				g_Level_Ctrl_List[index]:SetText(g_MemberListB[index - g_MaxCropsMemCount].Level)
				--血量百分比
				g_HP_Ctrl_List[index]:SetProgress(g_MemberListB[index - g_MaxCropsMemCount].HP, 100)

				g_GuidList[index] = g_MemberListB[index - g_MaxCropsMemCount].Guid
			--end
		end
	end

	local nKillerType = CorpsUI_2018:GetCopySceneFirstKillerType()
	if nKillerType == 1 then
		myteam.FirstKill:Show()
		enemyteam.FirstKill:Hide()
	elseif nKillerType == 2 then
		myteam.FirstKill:Hide()
		enemyteam.FirstKill:Show()
	else
		myteam.FirstKill:Hide()
		enemyteam.FirstKill:Hide()
	end
	local sNameA, sNameB = CorpsUI_2018:GetTwoCorpsNameInCopyScene()
	if sNameA == nil then sNameA ="" end
	if sNameB == nil then sNameB = "" end
	myteam.name:SetText(sNameA)
	enemyteam.name:SetText(sNameB)
	NoDiffMatch_Score_TimeText:SetText("#{ZBS_YXS_120301_79}")
	if g_IsTimerSet == 0 then
		--因为只有在最初的时候同步一次时间；另外，就是玩家短线重连同步一次时间
		--倒计时纯客户端行为，虽然Server端有计时，但不向客户端同步了。
		g_IsTimerSet = 1
		NoDiffMatch_Score_SetTimer()
	else
		NoDiffMatch_Score_TimeWatch:Show()
	end
end

function NoDiffMatch_Score_SetTimer()

	local nCountTimers = CorpsUI_2018:GetCorpsPK_LeftTimes()
	if nCountTimers == nil then
		nCountTimers = 0
	end
	if nCountTimers <= 0 then
		return
	end
	NoDiffMatch_Score_TimeWatch:SetProperty("Timer", tostring(nCountTimers))
	NoDiffMatch_Score_TimeWatch:Show()

end

function NoDiffMatch_Score_OnTimer()
	NoDiffMatch_Score_TimeWatch:Hide()
	NoDiffMatch_Score_WatchText:SetText("结束")
	NoDiffMatch_Score_WatchText:Show()
end

function NoDiffMatch_Score_Member_Click(idx)
    if idx < 1 or idx > g_MemCount_All then
        return
    end

    local guid = g_GuidList[idx]
    if guid == "" then
    	return
    end
    CorpsUI_2018:SetMainTargetByUIIdx(guid)
end

