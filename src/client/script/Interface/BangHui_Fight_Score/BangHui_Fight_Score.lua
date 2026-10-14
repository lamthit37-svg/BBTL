-- 玩家血条积分UI
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_IsTimerSet = 0
local g_IsFuckBaby = 0
local g_MenPaiNameList =
{
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
	[12] ={Name="#{XMPGG_160524_02}", Color="#ccc00ff", }, --鬼谷
	[13] ={Name="#{XQ_MP_15}", Color="#ca1d6da", }, --桃花岛
	[14] ={Name="#{XMPHM_210604_01}", Color="#cd61313", }, --menpai14
	[15] ={Name="#{BHSD_20240709_1}", Color="#c656ab4", }, --menpai15
}
local g_DieColor = "#cff0000"

local g_Team_HP_Ctrl_List = {};
local g_Team_Icon_Ctrl_List = {};
local g_Team_Level_Ctrl_List = {};
local g_Team_MenPai_Ctrl_List = {};
local g_Team_Name_Ctrl_List = {};


function BangHui_Fight_Score_PreLoad()

	this:RegisterEvent("SCENE_TRANSED", false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BHSDZD_SHOW_FULLDATA_BOX")
	this:RegisterEvent("BHSDZD_COPYDATA_FIRST_TIME")
	this:RegisterEvent("BHSDZD_COPYDATA_REFRESH")
	this:RegisterEvent("BHSDZD_COPYDATA_SYNC_TIME")
	this:RegisterEvent("RELIVE_HIDE")
	this:RegisterEvent("BHSDZD_SHOW_PK_RESULT")
	this:RegisterEvent("BHSDZD_COPYDATA_FULL_INFO")
	this:RegisterEvent("BHSDZD_UPDATE_STATE")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BangHui_Fight_Score_CtrlList_InitData()

	for i=1, 12 do
		g_Team_Icon_Ctrl_List[i]:Hide()
		g_Team_Name_Ctrl_List[i]:SetText("")
		g_Team_MenPai_Ctrl_List[i]:SetText("")
		g_Team_Level_Ctrl_List[i]:SetText("")
		g_Team_HP_Ctrl_List[i]:SetProgress(0, 100)
	end

	BangHui_Fight_Score_Team1FirstKill:Hide()
	BangHui_Fight_Score_Team2FirstKill:Hide()
	BangHui_Fight_Score_Team1Name:SetText("")
	BangHui_Fight_Score_Team2Name:SetText("")
	BangHui_Fight_Score_TimeText:SetText("")
	BangHui_Fight_Score_TimeWatch:Hide()
	BangHui_Fight_Score_WatchText:SetText("")
	BangHui_Fight_Score_WatchText:Hide()
end


function BangHui_Fight_Score_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BangHui_Fight_Score_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BangHui_Fight_Score_Frame:GetProperty("UnifiedYPosition");

	--索引1到6归第一战队；其他7-12属于第二战队
	g_Team_Icon_Ctrl_List[1] = BangHui_Fight_Score_Team1_1_Icon;
	g_Team_Icon_Ctrl_List[2] = BangHui_Fight_Score_Team1_2_Icon;
	g_Team_Icon_Ctrl_List[3] = BangHui_Fight_Score_Team1_3_Icon;
	g_Team_Icon_Ctrl_List[4] = BangHui_Fight_Score_Team1_4_Icon;
	g_Team_Icon_Ctrl_List[5] = BangHui_Fight_Score_Team1_5_Icon;
	g_Team_Icon_Ctrl_List[6] = BangHui_Fight_Score_Team1_6_Icon;
		
	g_Team_Icon_Ctrl_List[7] = BangHui_Fight_Score_Team2_1_Icon;
	g_Team_Icon_Ctrl_List[8] = BangHui_Fight_Score_Team2_2_Icon;
	g_Team_Icon_Ctrl_List[9] = BangHui_Fight_Score_Team2_3_Icon;
	g_Team_Icon_Ctrl_List[10]= BangHui_Fight_Score_Team2_4_Icon;
	g_Team_Icon_Ctrl_List[11]= BangHui_Fight_Score_Team2_5_Icon;
	g_Team_Icon_Ctrl_List[12]= BangHui_Fight_Score_Team2_6_Icon;


	g_Team_Level_Ctrl_List[1] = BangHui_Fight_Score_Team1_1_Level;
	g_Team_Level_Ctrl_List[2] = BangHui_Fight_Score_Team1_2_Level;
	g_Team_Level_Ctrl_List[3] = BangHui_Fight_Score_Team1_3_Level;
	g_Team_Level_Ctrl_List[4] = BangHui_Fight_Score_Team1_4_Level;
	g_Team_Level_Ctrl_List[5] = BangHui_Fight_Score_Team1_5_Level;
	g_Team_Level_Ctrl_List[6] = BangHui_Fight_Score_Team1_6_Level;

	g_Team_Level_Ctrl_List[7] = BangHui_Fight_Score_Team2_1_Level;
	g_Team_Level_Ctrl_List[8] = BangHui_Fight_Score_Team2_2_Level;
	g_Team_Level_Ctrl_List[9] = BangHui_Fight_Score_Team2_3_Level;
	g_Team_Level_Ctrl_List[10]= BangHui_Fight_Score_Team2_4_Level;
	g_Team_Level_Ctrl_List[11]= BangHui_Fight_Score_Team2_5_Level;
	g_Team_Level_Ctrl_List[12]= BangHui_Fight_Score_Team2_6_Level;


	g_Team_MenPai_Ctrl_List[1] = BangHui_Fight_Score_Team1_1_Career;
	g_Team_MenPai_Ctrl_List[2] = BangHui_Fight_Score_Team1_2_Career;
	g_Team_MenPai_Ctrl_List[3] = BangHui_Fight_Score_Team1_3_Career;
	g_Team_MenPai_Ctrl_List[4] = BangHui_Fight_Score_Team1_4_Career;
	g_Team_MenPai_Ctrl_List[5] = BangHui_Fight_Score_Team1_5_Career;
	g_Team_MenPai_Ctrl_List[6] = BangHui_Fight_Score_Team1_6_Career;

	g_Team_MenPai_Ctrl_List[7] = BangHui_Fight_Score_Team2_1_Career;
	g_Team_MenPai_Ctrl_List[8] = BangHui_Fight_Score_Team2_2_Career;
	g_Team_MenPai_Ctrl_List[9] = BangHui_Fight_Score_Team2_3_Career;
	g_Team_MenPai_Ctrl_List[10]= BangHui_Fight_Score_Team2_4_Career;
	g_Team_MenPai_Ctrl_List[11]= BangHui_Fight_Score_Team2_5_Career;
	g_Team_MenPai_Ctrl_List[12]= BangHui_Fight_Score_Team2_6_Career;


	g_Team_Name_Ctrl_List[1] = BangHui_Fight_Score_Team1_1_name;
	g_Team_Name_Ctrl_List[2] = BangHui_Fight_Score_Team1_2_name;
	g_Team_Name_Ctrl_List[3] = BangHui_Fight_Score_Team1_3_name;
	g_Team_Name_Ctrl_List[4] = BangHui_Fight_Score_Team1_4_name;
	g_Team_Name_Ctrl_List[5] = BangHui_Fight_Score_Team1_5_name;
	g_Team_Name_Ctrl_List[6] = BangHui_Fight_Score_Team1_6_name;

	g_Team_Name_Ctrl_List[7] = BangHui_Fight_Score_Team2_1_name;
	g_Team_Name_Ctrl_List[8] = BangHui_Fight_Score_Team2_2_name;
	g_Team_Name_Ctrl_List[9] = BangHui_Fight_Score_Team2_3_name;
	g_Team_Name_Ctrl_List[10]= BangHui_Fight_Score_Team2_4_name;
	g_Team_Name_Ctrl_List[11]= BangHui_Fight_Score_Team2_5_name;
	g_Team_Name_Ctrl_List[12]= BangHui_Fight_Score_Team2_6_name;


	g_Team_HP_Ctrl_List[1] = BangHui_Fight_Score_Team1_PlayerHP1;
	g_Team_HP_Ctrl_List[2] = BangHui_Fight_Score_Team1_PlayerHP2;
	g_Team_HP_Ctrl_List[3] = BangHui_Fight_Score_Team1_PlayerHP3;
	g_Team_HP_Ctrl_List[4] = BangHui_Fight_Score_Team1_PlayerHP4;
	g_Team_HP_Ctrl_List[5] = BangHui_Fight_Score_Team1_PlayerHP5;
	g_Team_HP_Ctrl_List[6] = BangHui_Fight_Score_Team1_PlayerHP6;

	g_Team_HP_Ctrl_List[7] = BangHui_Fight_Score_Team2_PlayerHP1;
	g_Team_HP_Ctrl_List[8] = BangHui_Fight_Score_Team2_PlayerHP2;
	g_Team_HP_Ctrl_List[9] = BangHui_Fight_Score_Team2_PlayerHP3;
	g_Team_HP_Ctrl_List[10]= BangHui_Fight_Score_Team2_PlayerHP4;
	g_Team_HP_Ctrl_List[11]= BangHui_Fight_Score_Team2_PlayerHP5;
	g_Team_HP_Ctrl_List[12]= BangHui_Fight_Score_Team2_PlayerHP6;

	BangHui_Fight_Score_CtrlList_InitData()
end

function BangHui_Fight_Score_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BangHui_Fight_Score_ResetPos()

	elseif( event == "BHSDZD_SHOW_FULLDATA_BOX") then
		--读取数据显示
		BangHui_Fight_Score_CtrlList_InitData()
		BangHui_Fight_ScoreFrame_FullFill_Data()
		this:Show()
	elseif (event == "BHSDZD_COPYDATA_FIRST_TIME")	then
		--读取数据显示
		BangHui_Fight_Score_CtrlList_InitData()
		--2.初始化
		g_IsTimerSet = 0
		g_IsFuckBaby = 0
		BangHui_Fight_ScoreFrame_FullFill_Data()
		--只在该事件里面，开始计时器。
		BangHui_Fight_Score_SetTimer()
		this:Show()
	elseif (event == "BHSDZD_COPYDATA_FULL_INFO" )	then
		--读取数据显示
		BangHui_Fight_Score_CtrlList_InitData()
		--2.初始化
		g_IsTimerSet = 0
		--GM进来的时候，会触发这个设置.如果置为1，则此次且场景事件不执行。
		g_IsFuckBaby = 1
		BangHui_Fight_ScoreFrame_FullFill_Data()
		--只在该事件里面，开始计时器。
		BangHui_Fight_Score_SetTimer()
		this:Show()
	elseif( event == "SCENE_TRANSED" ) then
		--忽略此次切场景事件
		if g_IsFuckBaby == 1 then
			g_IsFuckBaby = 0
			return
		end
		BangHui_Fight_Score_CtrlList_InitData()
		--1.切场景才关闭那个UI，下次肯定重新计时。
		g_IsTimerSet = 0
		g_IsFuckBaby = 0
		this:Hide()
	elseif  (event == "BHSDZD_COPYDATA_REFRESH" )	 then
		if (this:IsVisible())  then
			--读取数据显示更新
			BangHui_Fight_Score_CtrlList_InitData()
			BangHui_Fight_ScoreFrame_FullFill_Data()
		end
	elseif ( event =="BHSDZD_COPYDATA_SYNC_TIME") then
		if (this:IsVisible())  then
			BangHui_Fight_ScoreFrame_Sync_Time()
		end
	elseif ( event == "RELIVE_HIDE"	) then
		local nGameOver = GangT:IsBHSDZDGameOver()
		local nCurScene = GetSceneID()
		--如果没有结束，并且处于隐藏状态，再显示给玩家看看。
		--如果游戏结束了，这个UI就没有必要显示了。否则会出现2个UI
		if (this:IsVisible() == false and nGameOver == 0 and nCurScene>=654 and nCurScene<=657)  then
			--读取数据显示更新
			BangHui_Fight_Score_CtrlList_InitData()
			BangHui_Fight_ScoreFrame_FullFill_Data()
			this:Show()
		end
	elseif(event == "BHSDZD_SHOW_PK_RESULT")	 then
		this:Hide()
	elseif(event == "BHSDZD_UPDATE_STATE")	 then
		if (this:IsVisible())  then
			--读取数据显示更新
			BangHui_Fight_Score_CtrlList_InitData()
			BangHui_Fight_ScoreFrame_FullFill_Data()
		end
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BangHui_Fight_Score_ResetPos()
	BangHui_Fight_Score_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BangHui_Fight_Score_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BangHui_Fight_ScoreFrame_CloseWindow()
	this:Hide()
	PushEvent( "BHSDZD_SHOW_MINI_BOX", 1 )
end
--================================================
-- 刷新同步的时间数据
--================================================
function BangHui_Fight_ScoreFrame_Sync_Time()
	local nCountTimers = GangT:GetBHSDZDPK_LeftTimes()
	if nCountTimers == nil then
		nCountTimers = 0
	end
	BangHui_Fight_Score_TimeWatch:SetProperty("Timer", tostring(nCountTimers))
	BangHui_Fight_Score_TimeWatch:Show()
end
--================================================
-- 填充数据
--================================================
function BangHui_Fight_ScoreFrame_FullFill_Data()

	for i=1, 12 do
		local nGuid,nHP,nLevel,nMenPai,szName,nkill,nSH,nstate = GangT:GetCopyScenePlayerInfoByIdx(i-1)
		--碰到不合法的GUID，说明6个人没满。
		if nGuid ~= "" then
			--队长标记
			if i == 1 or i==7 then
				g_Team_Icon_Ctrl_List[i]:Show()
			end

			--玩家状态： 　  
			if nstate == 0 then      --0-正常
				 	g_Team_Name_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..szName)  --名字			
					g_Team_MenPai_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)  --门派
					g_Team_Level_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..nLevel)  --等级
					g_Team_HP_Ctrl_List[i]:SetProgress(nHP, 100)--血量百分比
			elseif nstate == 1 then  --1-死亡
				 	g_Team_Name_Ctrl_List[i]:SetText(g_DieColor..szName)  --名字			
					g_Team_MenPai_Ctrl_List[i]:SetText(g_DieColor..g_MenPaiNameList[nMenPai].Name)  --门派
					g_Team_Level_Ctrl_List[i]:SetText(g_DieColor..nLevel)  --等级
					g_Team_HP_Ctrl_List[i]:SetProgress(nHP, 100)--血量百分比						
			elseif nstate == 2 then  --2-掉线
				 	g_Team_Icon_Ctrl_List[i]:Hide()
					g_Team_Name_Ctrl_List[i]:SetText("")
					g_Team_MenPai_Ctrl_List[i]:SetText("")
					g_Team_Level_Ctrl_List[i]:SetText("")
					g_Team_HP_Ctrl_List[i]:SetProgress(0, 100)					
			end
				
		end
	end

	local nKillerType = GangT:GetCopySceneFirstKillerType()
	if nKillerType == 1 then
		BangHui_Fight_Score_Team1FirstKill:Show()
		BangHui_Fight_Score_Team2FirstKill:Hide()
	elseif nKillerType == 2 then
		BangHui_Fight_Score_Team1FirstKill:Hide()
		BangHui_Fight_Score_Team2FirstKill:Show()
	else
		BangHui_Fight_Score_Team1FirstKill:Hide()
		BangHui_Fight_Score_Team2FirstKill:Hide()
	end
	local sNameA, sNameB = GangT:GetTwoBHSDZDNameInCopyScene()
	if sNameA == nil then sNameA ="" end
	if sNameB == nil then sNameB = "" end
	BangHui_Fight_Score_Team1Name:SetText(sNameA)
	BangHui_Fight_Score_Team2Name:SetText(sNameB)
	BangHui_Fight_Score_TimeText:SetText("#{ZBS_YXS_120301_79}")
	if g_IsTimerSet == 0 then
		--因为只有在最初的时候同步一次时间；另外，就是玩家短线重连同步一次时间
		--倒计时纯客户端行为，虽然Server端有计时，但不向客户端同步了。
		g_IsTimerSet = 1
		BangHui_Fight_Score_SetTimer()
	else
		BangHui_Fight_Score_TimeWatch:Show()
	end
end

function BangHui_Fight_Score_SetTimer()

	local nCountTimers = GangT:GetBHSDZDPK_LeftTimes()
	if nCountTimers == nil then
		nCountTimers = 0
	end
	if nCountTimers <= 0 then
		return
	end
	BangHui_Fight_Score_TimeWatch:SetProperty("Timer", tostring(nCountTimers))
	BangHui_Fight_Score_TimeWatch:Show()

end

function BangHui_Fight_Score_OnTimer()
	BangHui_Fight_Score_TimeWatch:Hide()
	BangHui_Fight_Score_WatchText:SetText("结束")
	BangHui_Fight_Score_WatchText:Show()
end

function BangHui_Fight_Score_Team_Click(idx)
    if idx < 1 or idx > 12 then
        return
    end

    GangT:SetBMMainTargetByUIIdx(idx)
end
