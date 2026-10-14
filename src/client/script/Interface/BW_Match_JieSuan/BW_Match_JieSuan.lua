-- 比赛结果UI显示
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
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

--local g_Team_Level_Ctrl_List = {}
local g_Team_MenPai_Ctrl_List = {}
local g_Team_Name_Ctrl_List = {}
local g_Team_DuanWei_Ctrl_List = {}
local g_Team_KillCount_Ctrl_List = {}
--local g_Team_CalcBattleScore_Ctrl_List = {}
local g_Team_WinRate_Ctrl_List = {}

local g_Team_MenPai_Ctrl_List_DPS = {}
local g_Team_Name_Ctrl_List_DPS = {}
local g_Team_KillCount_Ctrl_List_DPS = {}
local g_Team_Damage_Ctrl_List_DPS = {}
local g_Team_Afford_Ctrl_List_DPS = {}
local g_Team_Cure_Ctrl_List_DPS = {}
local g_Team_DamageProgress_Ctrl_List_DPS = {}
local g_Team_AffordProgress_Ctrl_List_DPS = {}
local g_Team_CureProgress_Ctrl_List_DPS = {}

local g_Team_MenPai_Ctrl_List_DPS2 = {}
local g_Team_Name_Ctrl_List_DPS2 = {}
local g_Team_KillCount_Ctrl_List_DPS2 = {}
local g_Team_Damage_Ctrl_List_DPS2 = {}
local g_Team_Afford_Ctrl_List_DPS2 = {}
local g_Team_Cure_Ctrl_List_DPS2 = {}
local g_Team_DamageProgress_Ctrl_List_DPS2 = {}
local g_Team_AffordProgress_Ctrl_List_DPS2 = {}
local g_Team_CureProgress_Ctrl_List_DPS2 = {}
local g_NowCheckPage = 0

--经典版图片素材
--local g_Image_Winner = "set:Ach image:CorpsMatch_ShengLi"
--local g_Image_Loser  = "set:Ach image:CorpsMatch_ShiLi"
--local g_Image_Draw	 = "set:Ach image:CorpsMatch_DaPing"

function BW_Match_JieSuan_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)--传送的时候隐藏
	this:RegisterEvent("BWTROOPS_RESULT_SHOW")
	this:RegisterEvent("RELIVE_HIDE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BW_Match_JieSuan_CtrlList_InitData()

	for i=1, 12 do
		g_Team_DuanWei_Ctrl_List[i]:SetText("")
		g_Team_Name_Ctrl_List[i]:SetText("")
		g_Team_MenPai_Ctrl_List[i]:SetText("")
		g_Team_KillCount_Ctrl_List[i]:SetText("")
		g_Team_WinRate_Ctrl_List[i]:SetText("")
		g_Team_Name_Ctrl_List_DPS[i]:SetText("")
		g_Team_KillCount_Ctrl_List_DPS[i]:SetText("")
		g_Team_Afford_Ctrl_List_DPS[i]:SetText("")
		g_Team_Cure_Ctrl_List_DPS[i]:SetText("")
		g_Team_Damage_Ctrl_List_DPS[i]:SetText("")
		g_Team_MenPai_Ctrl_List_DPS[i]:SetText("")
		g_Team_DamageProgress_Ctrl_List_DPS[i]:SetProgress(0, 100)
		g_Team_AffordProgress_Ctrl_List_DPS[i]:SetProgress(0, 100)
		g_Team_CureProgress_Ctrl_List_DPS[i]:SetProgress(0, 100)
		g_Team_DamageProgress_Ctrl_List_DPS[i]:Hide()
		g_Team_AffordProgress_Ctrl_List_DPS[i]:Hide()
		g_Team_CureProgress_Ctrl_List_DPS[i]:Hide()
		g_Team_Cure_Ctrl_List_DPS[i]:Hide()
		g_Team_Damage_Ctrl_List_DPS[i]:Hide()
		g_Team_Afford_Ctrl_List_DPS[i]:Hide()
		
		g_Team_Name_Ctrl_List_DPS2[i]:SetText("")
		g_Team_KillCount_Ctrl_List_DPS2[i]:SetText("")
		g_Team_Afford_Ctrl_List_DPS2[i]:SetText("")
		g_Team_Cure_Ctrl_List_DPS2[i]:SetText("")
		g_Team_Damage_Ctrl_List_DPS2[i]:SetText("")
		g_Team_MenPai_Ctrl_List_DPS2[i]:SetText("")
		
		--g_Team_CalcBattleScore_Ctrl_List[i]:SetText("")
	end

	BW_Match_JieSuan_Team_Left:Hide()
	BW_Match_JieSuan_Team_Right:Hide()

	BW_Match_JieSuan_Team1FirstKill:Hide()
	BW_Match_JieSuan_Team2FirstKill:Hide()
	
	BW_Match_JieSuan_LeftList_TitleBK:Hide()
	BW_Match_JieSuan_RightList_TitleBK:Hide()

end


function BW_Match_JieSuan_OnLoad()

	-- if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片素材为唯美版
		-- g_Image_Winner	= "set:WM_Zhengba image:Win"
		-- g_Image_Loser	= "set:WM_Zhengba image:Lose"
		-- g_Image_Draw	= "set:WM_Zhengba image:Draw"
	-- end

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BW_Match_JieSuan_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BW_Match_JieSuan_Frame:GetProperty("UnifiedYPosition");

	--索引1到3归第一战队；其他4-6属于第二战队
	g_Team_DuanWei_Ctrl_List[1] = BW_Match_JieSuan_Left_1_Level;
	g_Team_DuanWei_Ctrl_List[2] = BW_Match_JieSuan_Left_2_Level;
	g_Team_DuanWei_Ctrl_List[3] = BW_Match_JieSuan_Left_3_Level;
	g_Team_DuanWei_Ctrl_List[4] = BW_Match_JieSuan_Right_1_Level;
	g_Team_DuanWei_Ctrl_List[5] = BW_Match_JieSuan_Right_2_Level;
	g_Team_DuanWei_Ctrl_List[6] = BW_Match_JieSuan_Right_3_Level;
	
	g_Team_DuanWei_Ctrl_List[7] = BW_Match_JieSuan_Left_4_Level;
	g_Team_DuanWei_Ctrl_List[8] = BW_Match_JieSuan_Left_5_Level;
	g_Team_DuanWei_Ctrl_List[9] = BW_Match_JieSuan_Left_6_Level;
	g_Team_DuanWei_Ctrl_List[10] = BW_Match_JieSuan_Right_4_Level;
	g_Team_DuanWei_Ctrl_List[11] = BW_Match_JieSuan_Right_5_Level;
	g_Team_DuanWei_Ctrl_List[12] = BW_Match_JieSuan_Right_6_Level;	

	g_Team_MenPai_Ctrl_List[1] = BW_Match_JieSuan_Left_1_Career;
	g_Team_MenPai_Ctrl_List[2] = BW_Match_JieSuan_Left_2_Career;
	g_Team_MenPai_Ctrl_List[3] = BW_Match_JieSuan_Left_3_Career;
	g_Team_MenPai_Ctrl_List[4] = BW_Match_JieSuan_Right_1_Career;
	g_Team_MenPai_Ctrl_List[5] = BW_Match_JieSuan_Right_2_Career;
	g_Team_MenPai_Ctrl_List[6] = BW_Match_JieSuan_Right_3_Career;
	
	g_Team_MenPai_Ctrl_List[7] = BW_Match_JieSuan_Left_4_Career;
	g_Team_MenPai_Ctrl_List[8] = BW_Match_JieSuan_Left_5_Career;
	g_Team_MenPai_Ctrl_List[9] = BW_Match_JieSuan_Left_6_Career;
	g_Team_MenPai_Ctrl_List[10] = BW_Match_JieSuan_Right_4_Career;
	g_Team_MenPai_Ctrl_List[11] = BW_Match_JieSuan_Right_5_Career;
	g_Team_MenPai_Ctrl_List[12] = BW_Match_JieSuan_Right_6_Career;


	g_Team_Name_Ctrl_List[1] = BW_Match_JieSuan_Left_1_name;
	g_Team_Name_Ctrl_List[2] = BW_Match_JieSuan_Left_2_name;
	g_Team_Name_Ctrl_List[3] = BW_Match_JieSuan_Left_3_name;
	g_Team_Name_Ctrl_List[4] = BW_Match_JieSuan_Right_1_name;
	g_Team_Name_Ctrl_List[5] = BW_Match_JieSuan_Right_2_name;
	g_Team_Name_Ctrl_List[6] = BW_Match_JieSuan_Right_3_name;
	
	g_Team_Name_Ctrl_List[7] = BW_Match_JieSuan_Left_4_name;
	g_Team_Name_Ctrl_List[8] = BW_Match_JieSuan_Left_5_name;
	g_Team_Name_Ctrl_List[9] = BW_Match_JieSuan_Left_6_name;
	g_Team_Name_Ctrl_List[10] = BW_Match_JieSuan_Right_4_name;
	g_Team_Name_Ctrl_List[11] = BW_Match_JieSuan_Right_5_name;
	g_Team_Name_Ctrl_List[12] = BW_Match_JieSuan_Right_6_name;

	g_Team_KillCount_Ctrl_List[1] = BW_Match_JieSuan_Left_1_Number;
	g_Team_KillCount_Ctrl_List[2] = BW_Match_JieSuan_Left_2_Number;
	g_Team_KillCount_Ctrl_List[3] = BW_Match_JieSuan_Left_3_Number;
	g_Team_KillCount_Ctrl_List[4] = BW_Match_JieSuan_Right_1_Number;
	g_Team_KillCount_Ctrl_List[5] = BW_Match_JieSuan_Right_2_Number;
	g_Team_KillCount_Ctrl_List[6] = BW_Match_JieSuan_Right_3_Number;
	
	g_Team_KillCount_Ctrl_List[7] = BW_Match_JieSuan_Left_4_Number;
	g_Team_KillCount_Ctrl_List[8] = BW_Match_JieSuan_Left_5_Number;
	g_Team_KillCount_Ctrl_List[9] = BW_Match_JieSuan_Left_6_Number;
	g_Team_KillCount_Ctrl_List[10] = BW_Match_JieSuan_Right_4_Number;
	g_Team_KillCount_Ctrl_List[11] = BW_Match_JieSuan_Right_5_Number;
	g_Team_KillCount_Ctrl_List[12] = BW_Match_JieSuan_Right_6_Number;
	
	g_Team_WinRate_Ctrl_List[1] = BW_Match_JieSuan_Left_1_WinRate;
	g_Team_WinRate_Ctrl_List[2] = BW_Match_JieSuan_Left_2_WinRate;
	g_Team_WinRate_Ctrl_List[3] = BW_Match_JieSuan_Left_3_WinRate;
	g_Team_WinRate_Ctrl_List[4] = BW_Match_JieSuan_Right_1_WinRate;
	g_Team_WinRate_Ctrl_List[5] = BW_Match_JieSuan_Right_2_WinRate;
	g_Team_WinRate_Ctrl_List[6] = BW_Match_JieSuan_Right_3_WinRate;
	
	g_Team_WinRate_Ctrl_List[7] = BW_Match_JieSuan_Left_4_WinRate;
	g_Team_WinRate_Ctrl_List[8] = BW_Match_JieSuan_Left_5_WinRate;
	g_Team_WinRate_Ctrl_List[9] = BW_Match_JieSuan_Left_6_WinRate;
	g_Team_WinRate_Ctrl_List[10] = BW_Match_JieSuan_Right_4_WinRate;
	g_Team_WinRate_Ctrl_List[11] = BW_Match_JieSuan_Right_5_WinRate;
	g_Team_WinRate_Ctrl_List[12] = BW_Match_JieSuan_Right_6_WinRate;
	
	g_Team_MenPai_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_MP;
	g_Team_MenPai_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_MP;
	g_Team_MenPai_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_MP;
	g_Team_MenPai_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_MP;
	g_Team_MenPai_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_MP;
	g_Team_MenPai_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_MP;
	
	g_Team_MenPai_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_MP;
	g_Team_MenPai_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_MP;
	g_Team_MenPai_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_MP;
	g_Team_MenPai_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_MP;
	g_Team_MenPai_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_MP;
	g_Team_MenPai_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_MP;
	
	g_Team_Name_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_name;
	g_Team_Name_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_name;
	g_Team_Name_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_name;
	g_Team_Name_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_name;
	g_Team_Name_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_name;
	g_Team_Name_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_name;
	
	g_Team_Name_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_name;
	g_Team_Name_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_name;
	g_Team_Name_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_name;
	g_Team_Name_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_name;
	g_Team_Name_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_name;
	g_Team_Name_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_name;
	
	g_Team_KillCount_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_Number;
	g_Team_KillCount_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_Number;
	g_Team_KillCount_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_Number;
	g_Team_KillCount_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_Number;
	g_Team_KillCount_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_Number;
	g_Team_KillCount_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_Number;
	
	g_Team_KillCount_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_Number;
	g_Team_KillCount_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_Number;
	g_Team_KillCount_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_Number;
	g_Team_KillCount_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_Number;
	g_Team_KillCount_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_Number;
	g_Team_KillCount_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_Number;
	
	g_Team_Damage_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_DPS_Text;
	
	g_Team_Damage_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_DPS_Text;
	g_Team_Damage_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_DPS_Text;
	
	g_Team_DamageProgress_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_DPS_Damage;
	
	g_Team_DamageProgress_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_DPS_Damage;
	g_Team_DamageProgress_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_DPS_Damage;
	
	g_Team_Afford_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_TPS_Text;
	
	g_Team_Afford_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_TPS_Text;
	g_Team_Afford_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_TPS_Text;
	
	g_Team_AffordProgress_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_TPS_Damage;
	
	g_Team_AffordProgress_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_TPS_Damage;
	g_Team_AffordProgress_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_TPS_Damage;
	
	g_Team_Cure_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_HPS_Text;
	
	g_Team_Cure_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_HPS_Text;
	g_Team_Cure_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_HPS_Text;
	
	g_Team_CureProgress_Ctrl_List_DPS[1] = BW_Match_JieSuan_Client01_Left_1_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[2] = BW_Match_JieSuan_Client01_Left_2_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[3] = BW_Match_JieSuan_Client01_Left_3_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[4] = BW_Match_JieSuan_Client01_Right_1_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[5] = BW_Match_JieSuan_Client01_Right_2_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[6] = BW_Match_JieSuan_Client01_Right_3_HPS_Damage;
	
	g_Team_CureProgress_Ctrl_List_DPS[7] = BW_Match_JieSuan_Client01_Left_4_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[8] = BW_Match_JieSuan_Client01_Left_5_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[9] = BW_Match_JieSuan_Client01_Left_6_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[10] = BW_Match_JieSuan_Client01_Right_4_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[11] = BW_Match_JieSuan_Client01_Right_5_HPS_Damage;
	g_Team_CureProgress_Ctrl_List_DPS[12] = BW_Match_JieSuan_Client01_Right_6_HPS_Damage;
	
	
	
	g_Team_MenPai_Ctrl_List_DPS2[1] = BW_Match_JieSuan_Client02_Left_1_MP;
	g_Team_MenPai_Ctrl_List_DPS2[2] = BW_Match_JieSuan_Client02_Left_2_MP;
	g_Team_MenPai_Ctrl_List_DPS2[3] = BW_Match_JieSuan_Client02_Left_3_MP;
	g_Team_MenPai_Ctrl_List_DPS2[4] = BW_Match_JieSuan_Client02_Right_1_MP;
	g_Team_MenPai_Ctrl_List_DPS2[5] = BW_Match_JieSuan_Client02_Right_2_MP;
	g_Team_MenPai_Ctrl_List_DPS2[6] = BW_Match_JieSuan_Client02_Right_3_MP;
	
	g_Team_MenPai_Ctrl_List_DPS2[7] = BW_Match_JieSuan_Client02_Left_4_MP;
	g_Team_MenPai_Ctrl_List_DPS2[8] = BW_Match_JieSuan_Client02_Left_5_MP;
	g_Team_MenPai_Ctrl_List_DPS2[9] = BW_Match_JieSuan_Client02_Left_6_MP;
	g_Team_MenPai_Ctrl_List_DPS2[10] = BW_Match_JieSuan_Client02_Right_4_MP;
	g_Team_MenPai_Ctrl_List_DPS2[11] = BW_Match_JieSuan_Client02_Right_5_MP;
	g_Team_MenPai_Ctrl_List_DPS2[12] = BW_Match_JieSuan_Client02_Right_6_MP;
	
	g_Team_Name_Ctrl_List_DPS2[1] = BW_Match_JieSuan_Client02_Left_1_name;
	g_Team_Name_Ctrl_List_DPS2[2] = BW_Match_JieSuan_Client02_Left_2_name;
	g_Team_Name_Ctrl_List_DPS2[3] = BW_Match_JieSuan_Client02_Left_3_name;
	g_Team_Name_Ctrl_List_DPS2[4] = BW_Match_JieSuan_Client02_Right_1_name;
	g_Team_Name_Ctrl_List_DPS2[5] = BW_Match_JieSuan_Client02_Right_2_name;
	g_Team_Name_Ctrl_List_DPS2[6] = BW_Match_JieSuan_Client02_Right_3_name;
	
	g_Team_Name_Ctrl_List_DPS2[7] = BW_Match_JieSuan_Client02_Left_4_name;
	g_Team_Name_Ctrl_List_DPS2[8] = BW_Match_JieSuan_Client02_Left_5_name;
	g_Team_Name_Ctrl_List_DPS2[9] = BW_Match_JieSuan_Client02_Left_6_name;
	g_Team_Name_Ctrl_List_DPS2[10] = BW_Match_JieSuan_Client02_Right_4_name;
	g_Team_Name_Ctrl_List_DPS2[11] = BW_Match_JieSuan_Client02_Right_5_name;
	g_Team_Name_Ctrl_List_DPS2[12] = BW_Match_JieSuan_Client02_Right_6_name;
	
	g_Team_KillCount_Ctrl_List_DPS2[1] = BW_Match_JieSuan_Client02_Left_1_Number;
	g_Team_KillCount_Ctrl_List_DPS2[2] = BW_Match_JieSuan_Client02_Left_2_Number;
	g_Team_KillCount_Ctrl_List_DPS2[3] = BW_Match_JieSuan_Client02_Left_3_Number;
	g_Team_KillCount_Ctrl_List_DPS2[4] = BW_Match_JieSuan_Client02_Right_1_Number;
	g_Team_KillCount_Ctrl_List_DPS2[5] = BW_Match_JieSuan_Client02_Right_2_Number;
	g_Team_KillCount_Ctrl_List_DPS2[6] = BW_Match_JieSuan_Client02_Right_3_Number;
	
	g_Team_KillCount_Ctrl_List_DPS2[7] = BW_Match_JieSuan_Client02_Left_4_Number;
	g_Team_KillCount_Ctrl_List_DPS2[8] = BW_Match_JieSuan_Client02_Left_5_Number;
	g_Team_KillCount_Ctrl_List_DPS2[9] = BW_Match_JieSuan_Client02_Left_6_Number;
	g_Team_KillCount_Ctrl_List_DPS2[10] = BW_Match_JieSuan_Client02_Right_4_Number;
	g_Team_KillCount_Ctrl_List_DPS2[11] = BW_Match_JieSuan_Client02_Right_5_Number;
	g_Team_KillCount_Ctrl_List_DPS2[12] = BW_Match_JieSuan_Client02_Right_6_Number;
	
	g_Team_Damage_Ctrl_List_DPS2[1] = BW_Match_JieSuan_Client02_Left_1_DPS;
	g_Team_Damage_Ctrl_List_DPS2[2] = BW_Match_JieSuan_Client02_Left_2_DPS;
	g_Team_Damage_Ctrl_List_DPS2[3] = BW_Match_JieSuan_Client02_Left_3_DPS;
	g_Team_Damage_Ctrl_List_DPS2[4] = BW_Match_JieSuan_Client02_Right_1_DPS;
	g_Team_Damage_Ctrl_List_DPS2[5] = BW_Match_JieSuan_Client02_Right_2_DPS;
	g_Team_Damage_Ctrl_List_DPS2[6] = BW_Match_JieSuan_Client02_Right_3_DPS;
	
	g_Team_Damage_Ctrl_List_DPS2[7] = BW_Match_JieSuan_Client02_Left_4_DPS;
	g_Team_Damage_Ctrl_List_DPS2[8] = BW_Match_JieSuan_Client02_Left_5_DPS;
	g_Team_Damage_Ctrl_List_DPS2[9] = BW_Match_JieSuan_Client02_Left_6_DPS;
	g_Team_Damage_Ctrl_List_DPS2[10] = BW_Match_JieSuan_Client02_Right_4_DPS;
	g_Team_Damage_Ctrl_List_DPS2[11] = BW_Match_JieSuan_Client02_Right_5_DPS;
	g_Team_Damage_Ctrl_List_DPS2[12] = BW_Match_JieSuan_Client02_Right_6_DPS;
	
	
	
	g_Team_Afford_Ctrl_List_DPS2[1] = BW_Match_JieSuan_Client02_Left_1_TPS;
	g_Team_Afford_Ctrl_List_DPS2[2] = BW_Match_JieSuan_Client02_Left_2_TPS;
	g_Team_Afford_Ctrl_List_DPS2[3] = BW_Match_JieSuan_Client02_Left_3_TPS;
	g_Team_Afford_Ctrl_List_DPS2[4] = BW_Match_JieSuan_Client02_Right_1_TPS;
	g_Team_Afford_Ctrl_List_DPS2[5] = BW_Match_JieSuan_Client02_Right_2_TPS;
	g_Team_Afford_Ctrl_List_DPS2[6] = BW_Match_JieSuan_Client02_Right_3_TPS;
	
	g_Team_Afford_Ctrl_List_DPS2[7] = BW_Match_JieSuan_Client02_Left_4_TPS;
	g_Team_Afford_Ctrl_List_DPS2[8] = BW_Match_JieSuan_Client02_Left_5_TPS;
	g_Team_Afford_Ctrl_List_DPS2[9] = BW_Match_JieSuan_Client02_Left_6_TPS;
	g_Team_Afford_Ctrl_List_DPS2[10] = BW_Match_JieSuan_Client02_Right_4_TPS;
	g_Team_Afford_Ctrl_List_DPS2[11] = BW_Match_JieSuan_Client02_Right_5_TPS;
	g_Team_Afford_Ctrl_List_DPS2[12] = BW_Match_JieSuan_Client02_Right_6_TPS;
	
	
	
	g_Team_Cure_Ctrl_List_DPS2[1] = BW_Match_JieSuan_Client02_Left_1_HPS;
	g_Team_Cure_Ctrl_List_DPS2[2] = BW_Match_JieSuan_Client02_Left_2_HPS;
	g_Team_Cure_Ctrl_List_DPS2[3] = BW_Match_JieSuan_Client02_Left_3_HPS;
	g_Team_Cure_Ctrl_List_DPS2[4] = BW_Match_JieSuan_Client02_Right_1_HPS;
	g_Team_Cure_Ctrl_List_DPS2[5] = BW_Match_JieSuan_Client02_Right_2_HPS;
	g_Team_Cure_Ctrl_List_DPS2[6] = BW_Match_JieSuan_Client02_Right_3_HPS;
	
	g_Team_Cure_Ctrl_List_DPS2[7] = BW_Match_JieSuan_Client02_Left_4_HPS;
	g_Team_Cure_Ctrl_List_DPS2[8] = BW_Match_JieSuan_Client02_Left_5_HPS;
	g_Team_Cure_Ctrl_List_DPS2[9] = BW_Match_JieSuan_Client02_Left_6_HPS;
	g_Team_Cure_Ctrl_List_DPS2[10] = BW_Match_JieSuan_Client02_Right_4_HPS;
	g_Team_Cure_Ctrl_List_DPS2[11] = BW_Match_JieSuan_Client02_Right_5_HPS;
	g_Team_Cure_Ctrl_List_DPS2[12] = BW_Match_JieSuan_Client02_Right_6_HPS;
	
	
	
	
	--g_Team_CalcBattleScore_Ctrl_List[1] = BW_Match_JieSuan_Left_1_Scor;
	--g_Team_CalcBattleScore_Ctrl_List[2] = BW_Match_JieSuan_Left_2_Scor;
	--g_Team_CalcBattleScore_Ctrl_List[3] = BW_Match_JieSuan_Left_3_Scor;
	--g_Team_CalcBattleScore_Ctrl_List[4] = BW_Match_JieSuan_Right_1_Scor;
	--g_Team_CalcBattleScore_Ctrl_List[5] = BW_Match_JieSuan_Right_2_Scor;
	--g_Team_CalcBattleScore_Ctrl_List[6] = BW_Match_JieSuan_Right_3_Scor;

	BW_Match_JieSuan_CtrlList_InitData()
end

function BW_Match_JieSuan_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BW_Match_JieSuan_ResetPos()

	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		BW_Match_JieSuan_CtrlList_InitData()
		this:Hide()
	elseif(event == "BWTROOPS_RESULT_SHOW")	 then
		BW_Match_JieSuan_Client_Btn01:Disable()
		BW_Match_JieSuan_Client_Btn02:Enable()
		
		BW_Match_JieSuan_CtrlList_InitData()
		BW_Match_JieSuanFrame_FullFill_Data()
		BW_Match_JieSuanFrame_FullFill_Data2()
		BW_Match_JieSuanFrame_FullFill_Data3()
		BW_Match_JieSuan_TopBK:Show()
		BW_Match_JieSuan_Client01:Hide()
		BW_Match_JieSuan_Client02:Hide()
		BW_Match_JieSuan_Client_Btn03:Hide()		
		g_NowCheckPage = 0
		this:Show()
	-- elseif ( event == "RELIVE_HIDE"	) then
		-- local nGameOver = BWDH:IsBWTroopsGameOver()
		-- local nCurScene = GetSceneID()
		-- --如果没有结束，并且处于隐藏状态，再显示给玩家看看。
		-- --如果游戏结束了，这个UI就没有必要显示了。否则会出现2个UI
		-- if (this:IsVisible() == false and nGameOver == 1 and nCurScene == 620)  then
			-- --读取数据显示更新
			-- BW_Match_JieSuan_CtrlList_InitData()
			-- BW_Match_JieSuanFrame_FullFill_Data()
			-- this:Show()
		-- end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_Match_JieSuan_ResetPos()
	BW_Match_JieSuan_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BW_Match_JieSuan_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BW_Match_JieSuan_Close_Clicked()
	this:Hide()
end

--================================================
-- 填充数据
--================================================
function BW_Match_JieSuanFrame_FullFill_Data()
	
	
	local mUIDir = BWDH2018:GetMyUIDirInfo()
	if mUIDir == nil then
		return 
	end
	if mUIDir == 0 then
		BW_Match_JieSuan_LeftList_TitleBK:Show()
		BW_Match_JieSuan_RightList_TitleBK:Show()
		BW_Match_JieSuan_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		BW_Match_JieSuan_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		local nResultType = BWDH2018:GetBWTroopsPK_Result_Info2018()
		for i=1, 12 do
			local nGuid,nHP,nLevel,nMenPai,szName,nkill,nstate,nSeasonPartCnt,nSeasonWinCnt= BWDH2018:GetCopySceneBWPlayerInfoByIdx2018(i-1)
			--碰到不合法的GUID，说明6个人没满。
			local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
			if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

				--名字
				g_Team_Name_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
				--门派
				if g_MenPaiNameList[nMenPai] then
					g_Team_MenPai_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
				else
					g_Team_MenPai_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
				end
				--击败数
				local nRealKillTimes = math.mod(nkill,10)
				g_Team_KillCount_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
				--装备评分
				--g_Team_CalcBattleScore_Ctrl_List[i]:SetText(tostring(nCalcBattleScire))
				--段位
				g_Team_DuanWei_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..g_DuanWei1[nDuanWei])
				if nResultType == 1 then
					if (i <= 3) or (i > 6 and i <= 9) then
						g_Team_WinRate_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor(((nSeasonWinCnt+1)/(nSeasonPartCnt+1))*10000)/100))).."%")
					else
						g_Team_WinRate_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")
					end
				elseif nResultType == 2 then
					if (i <= 3) or (i > 6 and i <= 9) then
						g_Team_WinRate_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")
					else
						g_Team_WinRate_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor(((nSeasonWinCnt+1)/(nSeasonPartCnt+1))*10000)/100))).."%")
					end
				elseif nResultType == 3 then					
					if (i <= 3) or (i > 6 and i <= 9) then
						g_Team_WinRate_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")
					else
						g_Team_WinRate_Ctrl_List[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")
					end
				end
				
			end
		end

		local nKillerType = BWDH2018:GetCopySceneBWFirstKillerType2018()

		
		if nResultType == 1 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Winner)--胜利
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Loser)--失败
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		elseif nResultType == 2 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Loser)--失败
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Winner)--胜利
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
		elseif nResultType == 3 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Draw)
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Draw)
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			return
		end

		BW_Match_JieSuan_Team_Left:Show()
		BW_Match_JieSuan_Team_Right:Show()

		if nKillerType == 1 then
			BW_Match_JieSuan_Team1FirstKill:Show()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		elseif nKillerType == 2 then
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Show()
		else
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		end
	elseif mUIDir == 1 then
		BW_Match_JieSuan_LeftList_TitleBK:Show()
		BW_Match_JieSuan_RightList_TitleBK:Show()
		BW_Match_JieSuan_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		BW_Match_JieSuan_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		local nResultType = BWDH2018:GetBWTroopsPK_Result_Info2018()
		for i=1, 12 do
			if (i <= 3) or (i > 6 and i <= 9) then
			
				local nGuid,nHP,nLevel,nMenPai,szName,nkill,nstate,nSeasonPartCnt,nSeasonWinCnt= BWDH2018:GetCopySceneBWPlayerInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--名字
					g_Team_Name_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
					--门派
					if g_MenPaiNameList[nMenPai] then
						g_Team_MenPai_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
					else
						g_Team_MenPai_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
					end
					--击败数
					local nRealKillTimes = math.mod(nkill,10)
					g_Team_KillCount_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
					--装备评分
					--g_Team_CalcBattleScore_Ctrl_List[i+3]:SetText(tostring(nCalcBattleScire))
					--段位
					g_Team_DuanWei_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..g_DuanWei1[nDuanWei])
					--g_Team_WinRate_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nSeasonWinCnt/nSeasonPartCnt+1)*10000)/100).."%")
					if nResultType == 1 then						
						g_Team_WinRate_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor(((nSeasonWinCnt+1)/(nSeasonPartCnt+1))*10000)/100))).."%")						
					elseif nResultType == 2 then
						g_Team_WinRate_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")
					elseif nResultType == 3 then											
						g_Team_WinRate_Ctrl_List[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")						
					end

				end
			end
			
			if (i > 3 and i <= 6) or (i > 9 and i <= 12)  then
				local nGuid,nHP,nLevel,nMenPai,szName,nkill,nstate,nSeasonPartCnt,nSeasonWinCnt= BWDH2018:GetCopySceneBWPlayerInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				local nCalcBattleSkcire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--名字
					g_Team_Name_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
					--门派
					if g_MenPaiNameList[nMenPai] then
						g_Team_MenPai_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
					else
						g_Team_MenPai_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
					end
					--击败数
					local nRealKillTimes = math.mod(nkill,10)
					g_Team_KillCount_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
					--装备评分
					--g_Team_CalcBattleScore_Ctrl_List[i-3]:SetText(tostring(nCalcBattleScire))
					--段位
					g_Team_DuanWei_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..g_DuanWei1[nDuanWei])
					--g_Team_WinRate_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nSeasonWinCnt/nSeasonPartCnt+1)*10000)/100).."%")
					if nResultType == 1 then						
						g_Team_WinRate_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")						
					elseif nResultType == 2 then
						g_Team_WinRate_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor(((nSeasonWinCnt+1)/(nSeasonPartCnt+1))*10000)/100))).."%")
					elseif nResultType == 3 then											
						g_Team_WinRate_Ctrl_List[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((math.floor((nSeasonWinCnt/(nSeasonPartCnt+1))*10000)/100))).."%")						
					end

				end
				
			end
			

			
		end
		
		local nKillerType = BWDH2018:GetCopySceneBWFirstKillerType2018()

		
		if nResultType == 1 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image", "set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
		elseif nResultType == 2 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
			BW_Match_JieSuan_Team_Right:SetProperty("Image", "set:Wangzhe2 image:Wangzhe_fu")
		elseif nResultType == 3 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			return
		end

		BW_Match_JieSuan_Team_Left:Show()
		BW_Match_JieSuan_Team_Right:Show()

		if nKillerType == 1 then
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Show()
		elseif nKillerType == 2 then
			BW_Match_JieSuan_Team1FirstKill:Show()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		else
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		end
		
	end


end

--================================================
-- 填充数据
--================================================
function BW_Match_JieSuanFrame_FullFill_Data2()
	
	
	local mUIDir = BWDH2018:GetMyUIDirInfo()
	if mUIDir == nil then
		return 
	end
	if mUIDir == 0 then
		BW_Match_JieSuan_LeftList_TitleBK:Show()
		BW_Match_JieSuan_RightList_TitleBK:Show()
		BW_Match_JieSuan_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		BW_Match_JieSuan_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		local nAllDamageA = 0
		local nAllAffordA = 0
		local nAllCureA = 0
		
		local nAllDamageB = 0
		local nAllAffordB = 0
		local nAllCureB = 0
		for i=1, 12 do
			local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
			--碰到不合法的GUID，说明6个人没满。
			local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
			if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

				--名字
				g_Team_Name_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
				--门派
				if g_MenPaiNameList[nMenPai] then
					g_Team_MenPai_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
				else
					g_Team_MenPai_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
				end
				--击败数
				local nRealKillTimes = math.mod(nkill,10)
				g_Team_KillCount_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
				
				
				--装备评分
				--g_Team_CalcBattleScore_Ctrl_List[i]:SetText(tostring(nCalcBattleScire))
				--段位				
				
				if (i <= 3) or (i > 6 and i <= 9) then
					nAllDamageA = nAllDamageA + nDamage
					nAllAffordA = nAllAffordA + nAfford
					nAllCureA = nAllCureA + nCure
				end
				
				if (i > 3 and i <= 6) or (i > 9 and i <= 12)  then
					nAllDamageB = nAllDamageB + nDamage
					nAllAffordB = nAllAffordB + nAfford
					nAllCureB = nAllCureB + nCure
				end
				
				
			end
		end
		
		for i=1, 12 do
			local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
			if nGuid ~= "" then
				if (i <= 3) or (i > 6 and i <= 9) then
					if nAllDamageA ~= 0 then
						g_Team_Damage_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nDamage/nAllDamageA)*10000)/100).."%")
						g_Team_DamageProgress_Ctrl_List_DPS[i]:SetProgress(nDamage, nAllDamageA)
						g_Team_DamageProgress_Ctrl_List_DPS[i]:Show()
						g_Team_Damage_Ctrl_List_DPS[i]:Show()
					else
						g_Team_Damage_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
						g_Team_DamageProgress_Ctrl_List_DPS[i]:SetProgress(0, nAllDamageA)
						g_Team_DamageProgress_Ctrl_List_DPS[i]:Show()
						g_Team_Damage_Ctrl_List_DPS[i]:Show()
					end
					if nAllAffordA ~= 0 then
						g_Team_Afford_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nAfford/nAllAffordA)*10000)/100).."%")
						g_Team_AffordProgress_Ctrl_List_DPS[i]:SetProgress(nAfford, nAllAffordA)
						g_Team_Afford_Ctrl_List_DPS[i]:Show()
						g_Team_AffordProgress_Ctrl_List_DPS[i]:Show()
					else
						g_Team_Afford_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
						g_Team_AffordProgress_Ctrl_List_DPS[i]:SetProgress(0, nAllAffordA)
						g_Team_Afford_Ctrl_List_DPS[i]:Show()
						g_Team_AffordProgress_Ctrl_List_DPS[i]:Show()
					end
					if nAllCureA ~= 0 then
						g_Team_Cure_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nCure/nAllCureA)*10000)/100).."%")
						g_Team_CureProgress_Ctrl_List_DPS[i]:SetProgress(nCure, nAllCureA)
						g_Team_Cure_Ctrl_List_DPS[i]:Show()
						g_Team_CureProgress_Ctrl_List_DPS[i]:Show()
					else
						g_Team_Cure_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
						g_Team_CureProgress_Ctrl_List_DPS[i]:SetProgress(0, nAllCureA)
						g_Team_Cure_Ctrl_List_DPS[i]:Show()
						g_Team_CureProgress_Ctrl_List_DPS[i]:Show()
					end
				end
				
				if (i > 3 and i <= 6) or (i > 9 and i <= 12)  then
					
					
					if nAllDamageB ~= 0 then
						g_Team_Damage_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nDamage/nAllDamageB)*10000)/100).."%")
						g_Team_DamageProgress_Ctrl_List_DPS[i]:SetProgress(nDamage, nAllDamageB)
						g_Team_DamageProgress_Ctrl_List_DPS[i]:Show()
						g_Team_Damage_Ctrl_List_DPS[i]:Show()
					else
						g_Team_Damage_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
						g_Team_DamageProgress_Ctrl_List_DPS[i]:SetProgress(0, nAllDamageB)
						g_Team_DamageProgress_Ctrl_List_DPS[i]:Show()
						g_Team_Damage_Ctrl_List_DPS[i]:Show()
					end
					if nAllAffordB ~= 0 then
						g_Team_Afford_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nAfford/nAllAffordB)*10000)/100).."%")
						g_Team_AffordProgress_Ctrl_List_DPS[i]:SetProgress(nAfford, nAllAffordB)
						g_Team_Afford_Ctrl_List_DPS[i]:Show()
						g_Team_AffordProgress_Ctrl_List_DPS[i]:Show()
					else
						g_Team_Afford_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
						g_Team_AffordProgress_Ctrl_List_DPS[i]:SetProgress(0, nAllAffordB)
						g_Team_Afford_Ctrl_List_DPS[i]:Show()
						g_Team_AffordProgress_Ctrl_List_DPS[i]:Show()
					end
					if nAllCureB ~= 0 then
						g_Team_Cure_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nCure/nAllCureB)*10000)/100).."%")
						g_Team_CureProgress_Ctrl_List_DPS[i]:SetProgress(nCure, nAllCureB)
						g_Team_Cure_Ctrl_List_DPS[i]:Show()
						g_Team_CureProgress_Ctrl_List_DPS[i]:Show()
					else
						g_Team_Cure_Ctrl_List_DPS[i]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
						g_Team_CureProgress_Ctrl_List_DPS[i]:SetProgress(0, nAllCureB)
						g_Team_Cure_Ctrl_List_DPS[i]:Show()
						g_Team_CureProgress_Ctrl_List_DPS[i]:Show()
					end
				end
			end
		end

		local nKillerType = BWDH2018:GetCopySceneBWFirstKillerType2018()

		local nResultType = BWDH2018:GetBWTroopsPK_Result_Info2018()
		
		if nResultType == 1 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Winner)--胜利
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Loser)--失败
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		elseif nResultType == 2 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Loser)--失败
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Winner)--胜利
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
		elseif nResultType == 3 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Draw)
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Draw)
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			return
		end

		BW_Match_JieSuan_Team_Left:Show()
		BW_Match_JieSuan_Team_Right:Show()

		if nKillerType == 1 then
			BW_Match_JieSuan_Team1FirstKill:Show()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		elseif nKillerType == 2 then
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Show()
		else
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		end
	elseif mUIDir == 1 then
		BW_Match_JieSuan_LeftList_TitleBK:Show()
		BW_Match_JieSuan_RightList_TitleBK:Show()
		BW_Match_JieSuan_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		BW_Match_JieSuan_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		local nAllDamageA = 0
		local nAllAffordA = 0
		local nAllCureA = 0
		
		local nAllDamageB = 0
		local nAllAffordB = 0
		local nAllCureB = 0
		for i=1, 12 do
			if (i <= 3) or (i > 6 and i <= 9) then
			
				local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--名字
					g_Team_Name_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
					--门派
					if g_MenPaiNameList[nMenPai] then
						g_Team_MenPai_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
					else
						g_Team_MenPai_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
					end
					--击败数
					local nRealKillTimes = math.mod(nkill,10)
					g_Team_KillCount_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
					
					
					--装备评分
					--g_Team_CalcBattleScore_Ctrl_List[i]:SetText(tostring(nCalcBattleScire))
					--段位
					
					nAllDamageA = nAllDamageA + nDamage
					nAllAffordA = nAllAffordA + nAfford
					nAllCureA = nAllCureA + nCure
					
				end
			end
			
			if (i > 3 and i <= 6) or (i > 9 and i <= 12)  then
				local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				local nCalcBattleSkcire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--名字
					g_Team_Name_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
					--门派
					if g_MenPaiNameList[nMenPai] then
						g_Team_MenPai_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
					else
						g_Team_MenPai_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
					end
					--击败数
					local nRealKillTimes = math.mod(nkill,10)
					g_Team_KillCount_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
					
					
					--装备评分
					--g_Team_CalcBattleScore_Ctrl_List[i]:SetText(tostring(nCalcBattleScire))
					--段位
				
					nAllDamageB = nAllDamageB + nDamage
					nAllAffordB = nAllAffordB + nAfford
					nAllCureB = nAllCureB + nCure

				end
			end		
			
		end
		
		
		for i=1, 12 do
			local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
			if (i <= 3) or (i > 6 and i <= 9) then
				if nAllDamageA ~= 0 then
					g_Team_Damage_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nDamage/nAllDamageA)*10000)/100).."%")
					g_Team_DamageProgress_Ctrl_List_DPS[i+3]:SetProgress(nDamage, nAllDamageA)
					g_Team_Damage_Ctrl_List_DPS[i+3]:Show()
					g_Team_DamageProgress_Ctrl_List_DPS[i+3]:Show()
				else
					g_Team_Damage_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
					g_Team_DamageProgress_Ctrl_List_DPS[i+3]:SetProgress(0, nAllDamageA)
					g_Team_Damage_Ctrl_List_DPS[i+3]:Show()
					g_Team_DamageProgress_Ctrl_List_DPS[i+3]:Show()
				end
				if nAllAffordA ~= 0 then
					g_Team_Afford_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nAfford/nAllAffordA)*10000)/100).."%")
					g_Team_AffordProgress_Ctrl_List_DPS[i+3]:SetProgress(nAfford, nAllAffordA)
					g_Team_Afford_Ctrl_List_DPS[i+3]:Show()
					g_Team_AffordProgress_Ctrl_List_DPS[i+3]:Show()
				else
					g_Team_Afford_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
					g_Team_AffordProgress_Ctrl_List_DPS[i+3]:SetProgress(0, nAllAffordA)
					g_Team_Afford_Ctrl_List_DPS[i+3]:Show()
					g_Team_AffordProgress_Ctrl_List_DPS[i+3]:Show()
				end
				if nAllCureA ~= 0 then
					g_Team_Cure_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nCure/nAllCureA)*10000)/100).."%")
					g_Team_CureProgress_Ctrl_List_DPS[i+3]:SetProgress(nCure, nAllCureA)
					g_Team_Cure_Ctrl_List_DPS[i+3]:Show()
					g_Team_CureProgress_Ctrl_List_DPS[i+3]:Show()
				else
					g_Team_Cure_Ctrl_List_DPS[i+3]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
					g_Team_CureProgress_Ctrl_List_DPS[i+3]:SetProgress(0, nAllCureA)
					g_Team_Cure_Ctrl_List_DPS[i+3]:Show()
					g_Team_CureProgress_Ctrl_List_DPS[i+3]:Show()
				end
			end
			
			if (i > 3 and i <= 6) or (i > 9 and i <= 12)  then
				
				
				if nAllDamageB ~= 0 then
					g_Team_Damage_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nDamage/nAllDamageB)*10000)/100).."%")
					g_Team_DamageProgress_Ctrl_List_DPS[i-3]:SetProgress(nDamage, nAllDamageB)
					g_Team_Damage_Ctrl_List_DPS[i-3]:Show()
					g_Team_DamageProgress_Ctrl_List_DPS[i-3]:Show()
				else
					g_Team_Damage_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
					g_Team_DamageProgress_Ctrl_List_DPS[i-3]:SetProgress(0, nAllDamageB)
					g_Team_Damage_Ctrl_List_DPS[i-3]:Show()
					g_Team_DamageProgress_Ctrl_List_DPS[i-3]:Show()
				end
				if nAllAffordB ~= 0 then
					g_Team_Afford_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nAfford/nAllAffordB)*10000)/100).."%")
					g_Team_AffordProgress_Ctrl_List_DPS[i-3]:SetProgress(nAfford, nAllAffordB)
					g_Team_Afford_Ctrl_List_DPS[i-3]:Show()
					g_Team_AffordProgress_Ctrl_List_DPS[i-3]:Show()
				else
					g_Team_Afford_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
					g_Team_AffordProgress_Ctrl_List_DPS[i-3]:SetProgress(0, nAllAffordB)
					g_Team_Afford_Ctrl_List_DPS[i-3]:Show()
					g_Team_AffordProgress_Ctrl_List_DPS[i-3]:Show()
				end
				if nAllCureB ~= 0 then
					g_Team_Cure_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..(math.floor((nCure/nAllCureB)*10000)/100).."%")
					g_Team_CureProgress_Ctrl_List_DPS[i-3]:SetProgress(nCure, nAllCureB)
					g_Team_Cure_Ctrl_List_DPS[i-3]:Show()
					g_Team_CureProgress_Ctrl_List_DPS[i-3]:Show()
				else
					g_Team_Cure_Ctrl_List_DPS[i-3]:SetText(g_MenPaiNameList[nMenPai].Color.."0".."%")
					g_Team_CureProgress_Ctrl_List_DPS[i-3]:SetProgress(0, nAllCureB)
					g_Team_Cure_Ctrl_List_DPS[i-3]:Show()
					g_Team_CureProgress_Ctrl_List_DPS[i-3]:Show()
				end
			end
		end
		
		local nKillerType = BWDH2018:GetCopySceneBWFirstKillerType2018()

		local nResultType = BWDH2018:GetBWTroopsPK_Result_Info2018()
		
		if nResultType == 1 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image", "set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
		elseif nResultType == 2 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
			BW_Match_JieSuan_Team_Right:SetProperty("Image", "set:Wangzhe2 image:Wangzhe_fu")
		elseif nResultType == 3 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			return
		end

		BW_Match_JieSuan_Team_Left:Show()
		BW_Match_JieSuan_Team_Right:Show()

		if nKillerType == 1 then
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Show()
		elseif nKillerType == 2 then
			BW_Match_JieSuan_Team1FirstKill:Show()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		else
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		end
		
	end


end


--================================================
-- 填充数据
--================================================
function BW_Match_JieSuanFrame_FullFill_Data3()
	
	
	local mUIDir = BWDH2018:GetMyUIDirInfo()
	if mUIDir == nil then
		return 
	end
	if mUIDir == 0 then
		BW_Match_JieSuan_LeftList_TitleBK:Show()
		BW_Match_JieSuan_RightList_TitleBK:Show()
		BW_Match_JieSuan_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		BW_Match_JieSuan_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		local nAllDamageA = 0
		local nAllAffordA = 0
		local nAllCureA = 0
		
		local nAllDamageB = 0
		local nAllAffordB = 0
		local nAllCureB = 0
		for i=1, 12 do
			local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
			--碰到不合法的GUID，说明6个人没满。
			local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
			if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

				--名字
				g_Team_Name_Ctrl_List_DPS2[i]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
				--门派
				if g_MenPaiNameList[nMenPai] then
					g_Team_MenPai_Ctrl_List_DPS2[i]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
				else
					g_Team_MenPai_Ctrl_List_DPS2[i]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
				end
				--击败数
				local nRealKillTimes = math.mod(nkill,10)
				g_Team_KillCount_Ctrl_List_DPS2[i]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
				
				
				g_Team_Damage_Ctrl_List_DPS2[i]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nDamage))
				g_Team_Afford_Ctrl_List_DPS2[i]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nAfford))
				g_Team_Cure_Ctrl_List_DPS2[i]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nCure))
				
			end
		end
		
		

		local nKillerType = BWDH2018:GetCopySceneBWFirstKillerType2018()

		local nResultType = BWDH2018:GetBWTroopsPK_Result_Info2018()
		
		if nResultType == 1 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Winner)--胜利
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Loser)--失败
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		elseif nResultType == 2 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Loser)--失败
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Winner)--胜利
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
		elseif nResultType == 3 then
			--BW_Match_JieSuan_ResultShowX1:SetProperty("Image" , g_Image_Draw)
			--BW_Match_JieSuan_ResultShowX2:SetProperty("Image" , g_Image_Draw)
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			return
		end

		BW_Match_JieSuan_Team_Left:Show()
		BW_Match_JieSuan_Team_Right:Show()

		if nKillerType == 1 then
			BW_Match_JieSuan_Team1FirstKill:Show()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		elseif nKillerType == 2 then
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Show()
		else
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		end
	elseif mUIDir == 1 then
		BW_Match_JieSuan_LeftList_TitleBK:Show()
		BW_Match_JieSuan_RightList_TitleBK:Show()
		BW_Match_JieSuan_LeftList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Blue")
		BW_Match_JieSuan_RightList_TitleBK:SetProperty("Image", "set:BW_Match5 image:Red")
		local nAllDamageA = 0
		local nAllAffordA = 0
		local nAllCureA = 0
		
		local nAllDamageB = 0
		local nAllAffordB = 0
		local nAllCureB = 0
		for i=1, 12 do
			if (i <= 3) or (i > 6 and i <= 9) then
			
				local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				local nCalcBattleScire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--名字
					g_Team_Name_Ctrl_List_DPS2[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
					--门派
					if g_MenPaiNameList[nMenPai] then
						g_Team_MenPai_Ctrl_List_DPS2[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
					else
						g_Team_MenPai_Ctrl_List_DPS2[i+3]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
					end
					--击败数
					local nRealKillTimes = math.mod(nkill,10)
					g_Team_KillCount_Ctrl_List_DPS2[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
					
					
					--装备评分
					--g_Team_CalcBattleScore_Ctrl_List[i]:SetText(tostring(nCalcBattleScire))
					--段位
					
					g_Team_Damage_Ctrl_List_DPS2[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nDamage))
					g_Team_Afford_Ctrl_List_DPS2[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nAfford))
					g_Team_Cure_Ctrl_List_DPS2[i+3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nCure))
					
				end
			end
			
			if (i > 3 and i <= 6) or (i > 9 and i <= 12)  then
				local nGuid,nMenPai,szName,nkill,nDamage,nAfford,nCure= BWDH2018:GetCopySceneBWPlayerDPSInfoByIdx2018(i-1)
				--碰到不合法的GUID，说明6个人没满。
				local nCalcBattleSkcire,nDuanWei = BWDH2018:GetCalcBattleScoreAndDuanweiInfoByIdx2018(i-1)
				if nGuid ~= "" and nDuanWei >= 1 and nDuanWei <= 6 then

					--名字
					g_Team_Name_Ctrl_List_DPS2[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..szName)
					--门派
					if g_MenPaiNameList[nMenPai] then
						g_Team_MenPai_Ctrl_List_DPS2[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..g_MenPaiNameList[nMenPai].Name)
					else
						g_Team_MenPai_Ctrl_List_DPS2[i-3]:SetText(g_MenPaiNameList[nMenPai].Color.."无门派")
					end
					--击败数
					local nRealKillTimes = math.mod(nkill,10)
					g_Team_KillCount_Ctrl_List_DPS2[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nRealKillTimes))
					
					
					--装备评分
					--g_Team_CalcBattleScore_Ctrl_List[i]:SetText(tostring(nCalcBattleScire))
					--段位
				
					g_Team_Damage_Ctrl_List_DPS2[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nDamage))
					g_Team_Afford_Ctrl_List_DPS2[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nAfford))
					g_Team_Cure_Ctrl_List_DPS2[i-3]:SetText(g_MenPaiNameList[nMenPai].Color..tostring(nCure))

				end
			end		
			
		end
		
		
		
		
		local nKillerType = BWDH2018:GetCopySceneBWFirstKillerType2018()

		local nResultType = BWDH2018:GetBWTroopsPK_Result_Info2018()
		
		if nResultType == 1 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image", "set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
		elseif nResultType == 2 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe1 image:Wangzhe_sheng")
			BW_Match_JieSuan_Team_Right:SetProperty("Image", "set:Wangzhe2 image:Wangzhe_fu")
		elseif nResultType == 3 then
			
			BW_Match_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BW_Match_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			return
		end

		BW_Match_JieSuan_Team_Left:Show()
		BW_Match_JieSuan_Team_Right:Show()

		if nKillerType == 1 then
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Show()
		elseif nKillerType == 2 then
			BW_Match_JieSuan_Team1FirstKill:Show()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		else
			BW_Match_JieSuan_Team1FirstKill:Hide()
			BW_Match_JieSuan_Team2FirstKill:Hide()
		end
		
	end


end

function BW_Match_JieSuan_PageClick(index)
	if index == 1 then
		BW_Match_JieSuan_TopBK:Show()
		BW_Match_JieSuan_Client01:Hide()
		BW_Match_JieSuan_Client02:Hide()
		BW_Match_JieSuan_Client_Btn01:Disable()
		BW_Match_JieSuan_Client_Btn02:Enable()
		
		BW_Match_JieSuan_Client_Btn03:Hide()
	elseif index == 2 then
		if g_NowCheckPage == 0 then
			BW_Match_JieSuan_TopBK:Hide()
			BW_Match_JieSuan_Client01:Show()
			BW_Match_JieSuan_Client02:Hide()	
			g_NowCheckPage = 1
		else
			BW_Match_JieSuan_TopBK:Hide()
			BW_Match_JieSuan_Client01:Hide()
			BW_Match_JieSuan_Client02:Show()
			g_NowCheckPage = 0			
		end
		BW_Match_JieSuan_Client_Btn01:Enable()
		BW_Match_JieSuan_Client_Btn02:Disable()
		BW_Match_JieSuan_Client_Btn03:Show()		
	end	
end

function BW_Match_JieSuan_Mode_Click()
	if g_NowCheckPage == 0 then
		BW_Match_JieSuan_TopBK:Hide()
		BW_Match_JieSuan_Client01:Show()
		BW_Match_JieSuan_Client02:Hide()	
		g_NowCheckPage = 1
	else
		BW_Match_JieSuan_TopBK:Hide()
		BW_Match_JieSuan_Client01:Hide()
		BW_Match_JieSuan_Client02:Show()	
		g_NowCheckPage = 0
	end
end