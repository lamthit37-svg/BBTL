-- 比赛结果UI显示
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_MenPaiNameList =
{
	[0]  ={Name="#{XQ_MP_1}"},
	[1]  ={Name="#{XQ_MP_2}"},
	[2]  ={Name="#{XQ_MP_3}"},
	[3]  ={Name="#{XQ_MP_4}"},
	[4]  ={Name="#{XQ_MP_5}"},
	[5]  ={Name="#{XQ_MP_6}"},
	[6]  ={Name="#{XQ_MP_7}"},
	[7]  ={Name="#{XQ_MP_8}"},
	[8]  ={Name="#{XQ_MP_9}"},
	[10] ={Name="#{XQ_MP_10}"},
	[11] ={Name="#{XQ_MP_13}"},
	[12] ={Name="#{XMPGG_160524_02}"},	--鬼谷
	[13] ={Name="#{XQ_MP_15}"},	--桃花岛
	[14] ={Name="#{XMPHM_210604_01}"},--menpai14
	[15] ={Name="#{BHSD_20240709_1}"},--menpai15
}

local g_Team_KillTimes_Ctrl_List = {};
local g_Team_Icon_Ctrl_List = {};
local g_Team_MenPai_Ctrl_List = {};
local g_Team_Name_Ctrl_List = {};
local g_Team_ShangHai_Ctrl_List ={};

--经典版图片素材
local g_Image_Winner = "set:Ach image:CorpsMatch_ShengLi"
local g_Image_Loser  = "set:Ach image:CorpsMatch_ShiLi"
local g_Image_Draw	 = "set:Ach image:CorpsMatch_DaPing"

function BangHui_Fight_ResultShow_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("BHSDZD_SHOW_PK_RESULT")
	this:RegisterEvent("RELIVE_HIDE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BangHui_Fight_ResultShow_CtrlList_InitData()

	for i=1, 12 do
		g_Team_Icon_Ctrl_List[i]:Hide()
		g_Team_Name_Ctrl_List[i]:SetText("")
		g_Team_MenPai_Ctrl_List[i]:SetText("")
		g_Team_KillTimes_Ctrl_List[i]:SetText("")
		g_Team_ShangHai_Ctrl_List[i]:SetText("")
	end

	BangHui_Fight_ResultShow_Team1Name:SetText("")
	BangHui_Fight_ResultShow_ResultShowX1:Hide()
	BangHui_Fight_ResultShow_ScoreX1:SetText("")

	BangHui_Fight_ResultShow_Team2Name:SetText("")
	BangHui_Fight_ResultShow_ResultShowX2:Hide()
	BangHui_Fight_ResultShow_ScoreX2:SetText("")


	BangHui_Fight_ResultShow_Team1FirstKill:Hide()
	BangHui_Fight_ResultShow_Team2FirstKill:Hide()

end


function BangHui_Fight_ResultShow_OnLoad()

	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片素材为唯美版
		g_Image_Winner	= "set:WM_Zhengba image:Win"
		g_Image_Loser	= "set:WM_Zhengba image:Lose"
		g_Image_Draw	= "set:WM_Zhengba image:Draw"
	end

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BangHui_Fight_ResultShow_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BangHui_Fight_ResultShow_Frame:GetProperty("UnifiedYPosition");

	--索引1到6归第一战队；其他7-12属于第二战队
	g_Team_Icon_Ctrl_List[1] = BangHui_Fight_ResultShow_Team1_1_Icon;
	g_Team_Icon_Ctrl_List[2] = BangHui_Fight_ResultShow_Team1_2_Icon;
	g_Team_Icon_Ctrl_List[3] = BangHui_Fight_ResultShow_Team1_3_Icon;
	g_Team_Icon_Ctrl_List[4] = BangHui_Fight_ResultShow_Team1_4_Icon;
	g_Team_Icon_Ctrl_List[5] = BangHui_Fight_ResultShow_Team1_5_Icon;
	g_Team_Icon_Ctrl_List[6] = BangHui_Fight_ResultShow_Team1_6_Icon;
	
	g_Team_Icon_Ctrl_List[7] = BangHui_Fight_ResultShow_Team2_1_Icon;
	g_Team_Icon_Ctrl_List[8] = BangHui_Fight_ResultShow_Team2_2_Icon;
	g_Team_Icon_Ctrl_List[9] = BangHui_Fight_ResultShow_Team2_3_Icon;
	g_Team_Icon_Ctrl_List[10]= BangHui_Fight_ResultShow_Team2_4_Icon;
	g_Team_Icon_Ctrl_List[11]= BangHui_Fight_ResultShow_Team2_5_Icon;
	g_Team_Icon_Ctrl_List[12]= BangHui_Fight_ResultShow_Team2_6_Icon;

	g_Team_MenPai_Ctrl_List[1] = BangHui_Fight_ResultShow_Team1_1_Career;
	g_Team_MenPai_Ctrl_List[2] = BangHui_Fight_ResultShow_Team1_2_Career;
	g_Team_MenPai_Ctrl_List[3] = BangHui_Fight_ResultShow_Team1_3_Career;
	g_Team_MenPai_Ctrl_List[4] = BangHui_Fight_ResultShow_Team1_4_Career;
	g_Team_MenPai_Ctrl_List[5] = BangHui_Fight_ResultShow_Team1_5_Career;
	g_Team_MenPai_Ctrl_List[6] = BangHui_Fight_ResultShow_Team1_6_Career;
	
	g_Team_MenPai_Ctrl_List[7] = BangHui_Fight_ResultShow_Team2_1_Career;
	g_Team_MenPai_Ctrl_List[8] = BangHui_Fight_ResultShow_Team2_2_Career;
	g_Team_MenPai_Ctrl_List[9] = BangHui_Fight_ResultShow_Team2_3_Career;
	g_Team_MenPai_Ctrl_List[10]= BangHui_Fight_ResultShow_Team2_4_Career;
	g_Team_MenPai_Ctrl_List[11]= BangHui_Fight_ResultShow_Team2_5_Career;
	g_Team_MenPai_Ctrl_List[12]= BangHui_Fight_ResultShow_Team2_6_Career;

	g_Team_Name_Ctrl_List[1] = BangHui_Fight_ResultShow_Team1_1_name;
	g_Team_Name_Ctrl_List[2] = BangHui_Fight_ResultShow_Team1_2_name;
	g_Team_Name_Ctrl_List[3] = BangHui_Fight_ResultShow_Team1_3_name;
	g_Team_Name_Ctrl_List[4] = BangHui_Fight_ResultShow_Team1_4_name;
	g_Team_Name_Ctrl_List[5] = BangHui_Fight_ResultShow_Team1_5_name;
	g_Team_Name_Ctrl_List[6] = BangHui_Fight_ResultShow_Team1_6_name;
	
	g_Team_Name_Ctrl_List[7] = BangHui_Fight_ResultShow_Team2_1_name;
	g_Team_Name_Ctrl_List[8] = BangHui_Fight_ResultShow_Team2_2_name;
	g_Team_Name_Ctrl_List[9] = BangHui_Fight_ResultShow_Team2_3_name;
	g_Team_Name_Ctrl_List[10]= BangHui_Fight_ResultShow_Team2_4_name;
	g_Team_Name_Ctrl_List[11]= BangHui_Fight_ResultShow_Team2_5_name;
	g_Team_Name_Ctrl_List[12]= BangHui_Fight_ResultShow_Team2_6_name;

	g_Team_KillTimes_Ctrl_List[1] = BangHui_Fight_ResultShow_Team1_1_Jishashu;
	g_Team_KillTimes_Ctrl_List[2] = BangHui_Fight_ResultShow_Team1_2_Jishashu;
	g_Team_KillTimes_Ctrl_List[3] = BangHui_Fight_ResultShow_Team1_3_Jishashu;
	g_Team_KillTimes_Ctrl_List[4] = BangHui_Fight_ResultShow_Team1_4_Jishashu;
	g_Team_KillTimes_Ctrl_List[5] = BangHui_Fight_ResultShow_Team1_5_Jishashu;
	g_Team_KillTimes_Ctrl_List[6] = BangHui_Fight_ResultShow_Team1_6_Jishashu;
	
	g_Team_KillTimes_Ctrl_List[7] = BangHui_Fight_ResultShow_Team2_1_Jishashu;
	g_Team_KillTimes_Ctrl_List[8] = BangHui_Fight_ResultShow_Team2_2_Jishashu;
	g_Team_KillTimes_Ctrl_List[9] = BangHui_Fight_ResultShow_Team2_3_Jishashu;
	g_Team_KillTimes_Ctrl_List[10]= BangHui_Fight_ResultShow_Team2_4_Jishashu;
	g_Team_KillTimes_Ctrl_List[11]= BangHui_Fight_ResultShow_Team2_5_Jishashu;
	g_Team_KillTimes_Ctrl_List[12]= BangHui_Fight_ResultShow_Team2_6_Jishashu;
	
	g_Team_ShangHai_Ctrl_List[1]  = BangHui_Fight_ResultShow_Team1_1_Shanghai;	
	g_Team_ShangHai_Ctrl_List[2]  = BangHui_Fight_ResultShow_Team1_2_Shanghai;	
	g_Team_ShangHai_Ctrl_List[3]  = BangHui_Fight_ResultShow_Team1_3_Shanghai;	
	g_Team_ShangHai_Ctrl_List[4]  = BangHui_Fight_ResultShow_Team1_4_Shanghai;	
	g_Team_ShangHai_Ctrl_List[5]  = BangHui_Fight_ResultShow_Team1_5_Shanghai;	
	g_Team_ShangHai_Ctrl_List[6]  = BangHui_Fight_ResultShow_Team1_6_Shanghai;	

	g_Team_ShangHai_Ctrl_List[7]  = BangHui_Fight_ResultShow_Team2_1_Shanghai;	
	g_Team_ShangHai_Ctrl_List[8]  = BangHui_Fight_ResultShow_Team2_2_Shanghai;	
	g_Team_ShangHai_Ctrl_List[9]  = BangHui_Fight_ResultShow_Team2_3_Shanghai;	
	g_Team_ShangHai_Ctrl_List[10] = BangHui_Fight_ResultShow_Team2_4_Shanghai;	
	g_Team_ShangHai_Ctrl_List[11] = BangHui_Fight_ResultShow_Team2_5_Shanghai;	
	g_Team_ShangHai_Ctrl_List[12] = BangHui_Fight_ResultShow_Team2_6_Shanghai;	
	
	BangHui_Fight_ResultShow_CtrlList_InitData()
end

function BangHui_Fight_ResultShow_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BangHui_Fight_ResultShow_ResetPos()

	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		BangHui_Fight_ResultShow_CtrlList_InitData()
		this:Hide()
	elseif(event == "BHSDZD_SHOW_PK_RESULT")	 then
		BangHui_Fight_ResultShow_CtrlList_InitData()
		BangHui_Fight_ResultShowFrame_FullFill_Data()
		this:Show()
	elseif ( event == "RELIVE_HIDE"	) then
		local nGameOver = GangT:IsBHSDZDGameOver()
		local nCurScene = GetSceneID()
		--如果没有结束，并且处于隐藏状态，再显示给玩家看看。
		--如果游戏结束了，这个UI就没有必要显示了。否则会出现2个UI
		if (this:IsVisible() == false and nGameOver == 1 and nCurScene>=654 and nCurScene<=657)  then
			--读取数据显示更新
			BangHui_Fight_ResultShow_CtrlList_InitData()
			BangHui_Fight_ResultShowFrame_FullFill_Data()
			this:Show()
		end
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BangHui_Fight_ResultShow_ResetPos()
	BangHui_Fight_ResultShow_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BangHui_Fight_ResultShow_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BangHui_Fight_ResultShow_Close_Clicked()
	this:Hide()
end

--================================================
-- 填充数据
--================================================
function BangHui_Fight_ResultShowFrame_FullFill_Data()

	local nShanghaiA = 0;
	local nShanghaiB = 0;
	for i=1, 12 do
		local nGuid,nHP,nLevel,nMenPai,szName,nKillTimes,nShanghai,nstate = GangT:GetCopyScenePlayerInfoByIdx(i-1)
		--碰到不合法的GUID，说明6个人没满。
		if nGuid ~= "" then
			--队长标记
			if i == 1 or i==7 then
				g_Team_Icon_Ctrl_List[i]:Show()
			end

			--名字
			g_Team_Name_Ctrl_List[i]:SetText("#c530303"..szName)
			--门派
			if g_MenPaiNameList[nMenPai] then
				g_Team_MenPai_Ctrl_List[i]:SetText("#c530303"..g_MenPaiNameList[nMenPai].Name)
			else
				g_Team_MenPai_Ctrl_List[i]:SetText("#c530303".."无门派")
			end
			--击败数
			local nRealKillTimes = math.mod(nKillTimes,10)
			g_Team_KillTimes_Ctrl_List[i]:SetText("#c530303"..tostring(nRealKillTimes))
			--伤害数值
			g_Team_ShangHai_Ctrl_List[i]:SetText("#c530303"..tostring(nShanghai))
			
			--伤害值求和
			if i>=1 and i<=6 then
				nShanghaiA = nShanghaiA + nShanghai;
			elseif i>=7 and i<=12 then
				nShanghaiB = nShanghaiB + nShanghai;
			end
		end
	end

	local nKillerType = GangT:GetCopySceneFirstKillerType()

	local nResultType = GangT:GetBHSDZDPK_Result_Info()
	if nResultType == 0 then
		BangHui_Fight_ResultShow_ResultShowX1:SetProperty("Image" , g_Image_Draw)
		BangHui_Fight_ResultShow_ResultShowX2:SetProperty("Image" , g_Image_Draw)
	elseif  nResultType == 1 then
			BangHui_Fight_ResultShow_ResultShowX1:SetProperty("Image" , g_Image_Winner)--胜利
			BangHui_Fight_ResultShow_ResultShowX2:SetProperty("Image" , g_Image_Loser)--失败
	elseif nResultType == 2 then
			BangHui_Fight_ResultShow_ResultShowX1:SetProperty("Image" , g_Image_Loser)--失败
			BangHui_Fight_ResultShow_ResultShowX2:SetProperty("Image" , g_Image_Winner)--胜利
	end

	BangHui_Fight_ResultShow_ScoreX1:SetText("#c530303".."+".. nShanghaiA)
	BangHui_Fight_ResultShow_ScoreX2:SetText("#c530303".."+".. nShanghaiB)

	BangHui_Fight_ResultShow_ResultShowX1:Show()
	BangHui_Fight_ResultShow_ResultShowX2:Show()

	if nKillerType == 1 then
		BangHui_Fight_ResultShow_Team1FirstKill:Show()
		BangHui_Fight_ResultShow_Team2FirstKill:Hide()
	elseif nKillerType == 2 then
		BangHui_Fight_ResultShow_Team1FirstKill:Hide()
		BangHui_Fight_ResultShow_Team2FirstKill:Show()
	else
		BangHui_Fight_ResultShow_Team1FirstKill:Hide()
		BangHui_Fight_ResultShow_Team2FirstKill:Hide()
	end

	local sNameA, sNameB = GangT:GetTwoBHSDZDNameInCopyScene()
	if sNameA == nil then sNameA ="" end
	if sNameB == nil then sNameB = "" end

	BangHui_Fight_ResultShow_Team1Name:SetText("#c530303"..sNameA)
	BangHui_Fight_ResultShow_Team2Name:SetText("#c530303"..sNameB)

end
