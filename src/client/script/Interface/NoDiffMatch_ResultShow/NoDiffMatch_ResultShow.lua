-- 比赛结果UI显示
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
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

local g_MemCount_All = 12
local g_MaxCropsMemCount = 6

local g_KillTimes_Ctrl_List = {};
local g_Icon_Ctrl_List = {};
local g_MenPai_Ctrl_List = {};
local g_Name_Ctrl_List = {};
local g_Image_Winner = "set:Wangzhe1 image:Wangzhe_sheng"
local g_Image_Loser  = "set:Wangzhe2 image:Wangzhe_fu"
local g_Image_Draw	 = "set:Wangzhe3 image:Wangzhe_ping"

--排序用
local g_MemberListA =  --pos:1队员 2副队长 3队长
{
	[1]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[2]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[3]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[4]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[5]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[6]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
}

local g_MemberListB =  --pos:1队员 2副队长 3队长
{
	[1]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[2]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[3]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[4]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[5]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
	[6]  ={Name="",MP=9,Level=0,pos=0,Guid="",KillCnt=0},
}

local g_CorpsLeaderIcon = "set:Union1 image:Union_LeaderIcon_L"
local g_CorpsAssistantIcon = "set:Union1 image:Union_MemberIcon_L"

function NoDiffMatch_ResultShow_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SHOW_PK_RESULT_2018")
	this:RegisterEvent("RELIVE_HIDE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_ResultShow_CtrlList_InitData()

	for i=1, g_MemCount_All do
		g_Icon_Ctrl_List[i]:Hide()
		g_Name_Ctrl_List[i]:SetText("")
		g_MenPai_Ctrl_List[i]:SetText("")
		g_KillTimes_Ctrl_List[i]:SetText("")
	end

	for i = 1, g_MaxCropsMemCount do
		g_MemberListA[i].Name = ""
		g_MemberListA[i].MP = 9
		g_MemberListA[i].Level = 0
		g_MemberListA[i].pos = 0
		g_MemberListA[i].Guid = ""
		g_MemberListA[i].KillCnt = 0
		
		g_MemberListB[i].Name = ""
		g_MemberListB[i].MP = 9
		g_MemberListB[i].Level = 0
		g_MemberListB[i].pos = 0
		g_MemberListB[i].Guid = ""
		g_MemberListB[i].KillCnt = 0
	end
	
	NoDiffMatch_ResultShow_Team_Left:SetText("")
	NoDiffMatch_ResultShow_LiftPic:SetProperty("Image" , g_Image_Draw)
	NoDiffMatch_ResultShow_Team1FirstKill:SetText("")

	NoDiffMatch_ResultShow_Team_Right:SetText("")
	NoDiffMatch_ResultShow_RightPic:SetProperty("Image" , g_Image_Draw)
	NoDiffMatch_ResultShow_Team2FirstKill:SetText("")

end


function NoDiffMatch_ResultShow_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_ResultShow_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_ResultShow_Frame:GetProperty("UnifiedYPosition");

	--索引1到10归第一战队；其他11-20属于第二战队
	g_Icon_Ctrl_List[1] = NoDiffMatch_ResultShow_Left_1_Icon;
	g_Icon_Ctrl_List[2] = NoDiffMatch_ResultShow_Left_2_Icon;
	g_Icon_Ctrl_List[3] = NoDiffMatch_ResultShow_Left_3_Icon;
	g_Icon_Ctrl_List[4] = NoDiffMatch_ResultShow_Left_4_Icon;
	g_Icon_Ctrl_List[5] = NoDiffMatch_ResultShow_Left_5_Icon;
	g_Icon_Ctrl_List[6] = NoDiffMatch_ResultShow_Left_6_Icon;
	g_Icon_Ctrl_List[7] = NoDiffMatch_ResultShow_Right_1_Icon;
	g_Icon_Ctrl_List[8] = NoDiffMatch_ResultShow_Right_2_Icon;
	g_Icon_Ctrl_List[9] = NoDiffMatch_ResultShow_Right_3_Icon;
	g_Icon_Ctrl_List[10] = NoDiffMatch_ResultShow_Right_4_Icon;
	g_Icon_Ctrl_List[11] = NoDiffMatch_ResultShow_Right_5_Icon;
	g_Icon_Ctrl_List[12] = NoDiffMatch_ResultShow_Right_6_Icon;


	g_MenPai_Ctrl_List[1] = NoDiffMatch_ResultShow_Left_1_Career;
	g_MenPai_Ctrl_List[2] = NoDiffMatch_ResultShow_Left_2_Career;
	g_MenPai_Ctrl_List[3] = NoDiffMatch_ResultShow_Left_3_Career;
	g_MenPai_Ctrl_List[4] = NoDiffMatch_ResultShow_Left_4_Career;
	g_MenPai_Ctrl_List[5] = NoDiffMatch_ResultShow_Left_5_Career;
	g_MenPai_Ctrl_List[6] = NoDiffMatch_ResultShow_Left_6_Career;
	g_MenPai_Ctrl_List[7] = NoDiffMatch_ResultShow_Right_1_Career;
	g_MenPai_Ctrl_List[8] = NoDiffMatch_ResultShow_Right_2_Career;
	g_MenPai_Ctrl_List[9] = NoDiffMatch_ResultShow_Right_3_Career;
	g_MenPai_Ctrl_List[10] = NoDiffMatch_ResultShow_Right_4_Career;
	g_MenPai_Ctrl_List[11] = NoDiffMatch_ResultShow_Right_5_Career;
	g_MenPai_Ctrl_List[12] = NoDiffMatch_ResultShow_Right_6_Career;

	g_Name_Ctrl_List[1] = NoDiffMatch_ResultShow_Left_1_name;
	g_Name_Ctrl_List[2] = NoDiffMatch_ResultShow_Left_2_name;
	g_Name_Ctrl_List[3] = NoDiffMatch_ResultShow_Left_3_name;
	g_Name_Ctrl_List[4] = NoDiffMatch_ResultShow_Left_4_name;
	g_Name_Ctrl_List[5] = NoDiffMatch_ResultShow_Left_5_name;
	g_Name_Ctrl_List[6] = NoDiffMatch_ResultShow_Left_6_name;
	g_Name_Ctrl_List[7] = NoDiffMatch_ResultShow_Right_1_name;
	g_Name_Ctrl_List[8] = NoDiffMatch_ResultShow_Right_2_name;
	g_Name_Ctrl_List[9] = NoDiffMatch_ResultShow_Right_3_name;
	g_Name_Ctrl_List[10] = NoDiffMatch_ResultShow_Right_4_name;
	g_Name_Ctrl_List[11] = NoDiffMatch_ResultShow_Right_5_name;
	g_Name_Ctrl_List[12] = NoDiffMatch_ResultShow_Right_6_name;

	g_KillTimes_Ctrl_List[1] = NoDiffMatch_ResultShow_Left_1_Level;
	g_KillTimes_Ctrl_List[2] = NoDiffMatch_ResultShow_Left_2_Level;
	g_KillTimes_Ctrl_List[3] = NoDiffMatch_ResultShow_Left_3_Level;
	g_KillTimes_Ctrl_List[4] = NoDiffMatch_ResultShow_Left_4_Level;
	g_KillTimes_Ctrl_List[5] = NoDiffMatch_ResultShow_Left_5_Level;
	g_KillTimes_Ctrl_List[6] = NoDiffMatch_ResultShow_Left_6_Level;
	g_KillTimes_Ctrl_List[7]= NoDiffMatch_ResultShow_Right_1_Level;
	g_KillTimes_Ctrl_List[8]= NoDiffMatch_ResultShow_Right_2_Level;
	g_KillTimes_Ctrl_List[9]= NoDiffMatch_ResultShow_Right_3_Level;
	g_KillTimes_Ctrl_List[10]= NoDiffMatch_ResultShow_Right_4_Level;
	g_KillTimes_Ctrl_List[11]= NoDiffMatch_ResultShow_Right_5_Level;
	g_KillTimes_Ctrl_List[12]= NoDiffMatch_ResultShow_Right_6_Level;

	NoDiffMatch_ResultShow_CtrlList_InitData()
end

function NoDiffMatch_ResultShow_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	
	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_ResultShow_ResetPos()

	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		NoDiffMatch_ResultShow_CtrlList_InitData()
		this:Hide()
	elseif(event == "SHOW_PK_RESULT_2018")	 then
		NoDiffMatch_ResultShow_CtrlList_InitData()
		NoDiffMatch_ResultShow_FullFill_Data()
		this:Show()
	elseif ( event == "RELIVE_HIDE"	) then
		local nGameOver = CorpsUI_2018:IsCorpsGameOver()
		--如果没有结束，并且处于隐藏状态，再显示给玩家看看。
		--如果游戏结束了，这个UI就没有必要显示了。否则会出现2个UI
		local bInPkScene = CorpsUI_2018:IsInZbsMatchScene()
		
		if (this:IsVisible() == false and nGameOver == 1 and bInPkScene == 1 )  then
			--读取数据显示更新
			NoDiffMatch_ResultShow_CtrlList_InitData()
			NoDiffMatch_ResultShow_FullFill_Data()
			this:Show()
		end
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_ResultShow_ResetPos()
	NoDiffMatch_ResultShow_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_ResultShow_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_ResultShow_Close_Clicked()
	this:Hide()
end

--================================================
-- 填充数据
--================================================
function NoDiffMatch_ResultShow_FullFill_Data()
	
	local nMemCntA = 1
	local nMemCntB = 1
	
	for i=1, g_MemCount_All do
		local nGuid,nHP,nLevel,nMenPai,nPos,szName,nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i-1)
		
		--碰到不合法的GUID，说明10个人没满。
		if nGuid ~= "" then
			if i <= g_MaxCropsMemCount then
				g_MemberListA[nMemCntA].Name = szName
				g_MemberListA[nMemCntA].MP = nMenPai
				g_MemberListA[nMemCntA].Level = nLevel
				g_MemberListA[nMemCntA].pos = nPos
				g_MemberListA[nMemCntA].Guid = nGuid
				g_MemberListA[nMemCntA].KillCnt = nKillCnt
				nMemCntA = nMemCntA + 1
			else
				g_MemberListB[nMemCntB].Name = szName
				g_MemberListB[nMemCntB].MP = nMenPai
				g_MemberListB[nMemCntB].Level = nLevel
				g_MemberListB[nMemCntB].pos = nPos
				g_MemberListB[nMemCntB].Guid = nGuid
				g_MemberListB[nMemCntB].KillCnt = nKillCnt
				nMemCntB = nMemCntB + 1
			end
		end
	end
	
	
	for index=1, g_MemCount_All do
		if index <= g_MaxCropsMemCount then
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
				--击败数
				g_KillTimes_Ctrl_List[index]:SetText(tostring(g_MemberListA[index].KillCnt))

		else
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
				--击败数
				g_KillTimes_Ctrl_List[index]:SetText(tostring(g_MemberListB[index - g_MaxCropsMemCount].KillCnt))
		end
	end
	
	
	local nKillerType = CorpsUI_2018:GetCopySceneFirstKillerType()

	local nResultType = CorpsUI_2018:GetCorpsPK_Result_Info()
	if nResultType == 1 then
		NoDiffMatch_ResultShow_LiftPic:SetProperty("Image" , g_Image_Winner)
		NoDiffMatch_ResultShow_RightPic:SetProperty("Image" , g_Image_Loser)
	elseif nResultType == 2 then
		NoDiffMatch_ResultShow_LiftPic:SetProperty("Image" , g_Image_Loser)
		NoDiffMatch_ResultShow_RightPic:SetProperty("Image" , g_Image_Winner)
	else
		return
	end
	
	if nKillerType == 1 then
		NoDiffMatch_ResultShow_Team1FirstKill:Show()
		NoDiffMatch_ResultShow_Team2FirstKill:Hide()
	elseif nKillerType == 2 then
		NoDiffMatch_ResultShow_Team1FirstKill:Hide()
		NoDiffMatch_ResultShow_Team2FirstKill:Show()
	else
		NoDiffMatch_ResultShow_Team1FirstKill:Hide()
		NoDiffMatch_ResultShow_Team2FirstKill:Hide()
	end

	local sNameA, sNameB = CorpsUI_2018:GetTwoCorpsNameInCopyScene()
	if sNameA == nil then sNameA ="" end
	if sNameB == nil then sNameB = "" end

	NoDiffMatch_ResultShow_Team_Left:SetText(sNameA)
	NoDiffMatch_ResultShow_Team_Right:SetText(sNameB)

end

