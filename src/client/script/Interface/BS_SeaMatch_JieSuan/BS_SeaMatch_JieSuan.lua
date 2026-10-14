--试剑天下结算
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition
local m_MenPaiNameList =
{
	[0]  ={Name="#{SCGZ_180816_30}" , Color="#cff6600", }, --少林
	[1]  ={Name="#{SCGZ_180816_36}" , Color="#cffcc00", }, --明教
	[2]  ={Name="#{SCGZ_180816_37}" , Color="#c00ff00", }, --丐帮
	[3]  ={Name="#{SCGZ_180816_31}" , Color="#c0000ff", }, --武当
	[4]  ={Name="#{SCGZ_180816_33}" , Color="#cff99cc", }, --峨嵋
	[5]  ={Name="#{SCGZ_180816_32}" , Color="#c007700", }, --星宿
	[6]  ={Name="#{SCGZ_180816_41}" , Color="#cffff00", }, --天龙
	[7]  ={Name="#{SCGZ_180816_35}" , Color="#cffffff", }, --天山
	[8]  ={Name="#{SCGZ_180816_34}" , Color="#c7700ff", }, --逍遥
	[9]  ={Name="无门派"     , Color="#c999999", },	
	[10] ={Name="#{SCGZ_180816_40}", Color="#c007fff", }, --慕容
	[11] ={Name="#{SCGZ_180816_38}", Color="#ccc00ff", }, --唐门
	[12] ={Name="#{SCGZ_180816_39}", Color="#c24dec6", },   --鬼谷
	[13] ={Name="#{SCGZ_180816_119}", Color="#ca1d6da", },   --桃花岛
	[14] ={Name="#{XMPHM_210604_01}", Color="#cd61313", },
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", Color="#c656ab4", },--menpai15
}

local g_DieColor = "#cff0000"
local g_DiaoXianColoer = "#ccccccc"

local m_teamAList = {}
local m_teamBList = {}
local m_teamAList_DPS = {}
local m_teamBList_DPS = {}
local m_teamAList_DPSEx = {}
local m_teamBList_DPSEx = {}

local m_isCanCloseUI = 1
local g_NowCheckPage = 0

--预加载函数，可以而且只能在这里注册脚本关心的事件
function BS_SeaMatch_JieSuan_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SJTX_JIESUAN")
	this:RegisterEvent("SJTX_FIGHTUI_OP")
	this:RegisterEvent("SJTX_FIGHTDATAUPDATE", false)
	this:RegisterEvent("SJTX_CLOSEUI", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_SeaMatch_JieSuan_ResetPos()
	BS_SeaMatch_JieSuan_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BS_SeaMatch_JieSuan_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end


--加载窗口的时候调用的函数，加载窗口时调用一次
function BS_SeaMatch_JieSuan_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= BS_SeaMatch_JieSuan_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= BS_SeaMatch_JieSuan_Frame:GetProperty("UnifiedYPosition");
	m_teamAList[1] = {Hp=BS_SeaMatch_JieSuan_Left_PlayerHP1,Name=BS_SeaMatch_JieSuan_Left_1_name,MenPai=BS_SeaMatch_JieSuan_Left_1_Career,Level=BS_SeaMatch_JieSuan_Left_1_Level,Number=BS_SeaMatch_JieSuan_Left_1_Number}
	m_teamAList[2] = {Hp=BS_SeaMatch_JieSuan_Left_PlayerHP2,Name=BS_SeaMatch_JieSuan_Left_2_name,MenPai=BS_SeaMatch_JieSuan_Left_2_Career,Level=BS_SeaMatch_JieSuan_Left_2_Level,Number=BS_SeaMatch_JieSuan_Left_2_Number}
	m_teamAList[3] = {Hp=BS_SeaMatch_JieSuan_Left_PlayerHP3,Name=BS_SeaMatch_JieSuan_Left_3_name,MenPai=BS_SeaMatch_JieSuan_Left_3_Career,Level=BS_SeaMatch_JieSuan_Left_3_Level,Number=BS_SeaMatch_JieSuan_Left_3_Number}
	m_teamAList[4] = {Hp=BS_SeaMatch_JieSuan_Left_PlayerHP4,Name=BS_SeaMatch_JieSuan_Left_4_name,MenPai=BS_SeaMatch_JieSuan_Left_4_Career,Level=BS_SeaMatch_JieSuan_Left_4_Level,Number=BS_SeaMatch_JieSuan_Left_4_Number}
	m_teamAList[5] = {Hp=BS_SeaMatch_JieSuan_Left_PlayerHP5,Name=BS_SeaMatch_JieSuan_Left_5_name,MenPai=BS_SeaMatch_JieSuan_Left_5_Career,Level=BS_SeaMatch_JieSuan_Left_5_Level,Number=BS_SeaMatch_JieSuan_Left_5_Number}
	m_teamAList[6] = {Hp=BS_SeaMatch_JieSuan_Left_PlayerHP6,Name=BS_SeaMatch_JieSuan_Left_6_name,MenPai=BS_SeaMatch_JieSuan_Left_6_Career,Level=BS_SeaMatch_JieSuan_Left_6_Level,Number=BS_SeaMatch_JieSuan_Left_6_Number}

	m_teamBList[1] = {Hp=BS_SeaMatch_JieSuan_Right_PlayerHP1,Name=BS_SeaMatch_JieSuan_Right_1_name,MenPai=BS_SeaMatch_JieSuan_Right_1_Career,Level=BS_SeaMatch_JieSuan_Right_1_Level,Number=BS_SeaMatch_JieSuan_Right_1_Number}
	m_teamBList[2] = {Hp=BS_SeaMatch_JieSuan_Right_PlayerHP2,Name=BS_SeaMatch_JieSuan_Right_2_name,MenPai=BS_SeaMatch_JieSuan_Right_2_Career,Level=BS_SeaMatch_JieSuan_Right_2_Level,Number=BS_SeaMatch_JieSuan_Right_2_Number}
	m_teamBList[3] = {Hp=BS_SeaMatch_JieSuan_Right_PlayerHP3,Name=BS_SeaMatch_JieSuan_Right_3_name,MenPai=BS_SeaMatch_JieSuan_Right_3_Career,Level=BS_SeaMatch_JieSuan_Right_3_Level,Number=BS_SeaMatch_JieSuan_Right_3_Number}
	m_teamBList[4] = {Hp=BS_SeaMatch_JieSuan_Right_PlayerHP4,Name=BS_SeaMatch_JieSuan_Right_4_name,MenPai=BS_SeaMatch_JieSuan_Right_4_Career,Level=BS_SeaMatch_JieSuan_Right_4_Level,Number=BS_SeaMatch_JieSuan_Right_4_Number}
	m_teamBList[5] = {Hp=BS_SeaMatch_JieSuan_Right_PlayerHP5,Name=BS_SeaMatch_JieSuan_Right_5_name,MenPai=BS_SeaMatch_JieSuan_Right_5_Career,Level=BS_SeaMatch_JieSuan_Right_5_Level,Number=BS_SeaMatch_JieSuan_Right_5_Number}
	m_teamBList[6] = {Hp=BS_SeaMatch_JieSuan_Right_PlayerHP6,Name=BS_SeaMatch_JieSuan_Right_6_name,MenPai=BS_SeaMatch_JieSuan_Right_6_Career,Level=BS_SeaMatch_JieSuan_Right_6_Level,Number=BS_SeaMatch_JieSuan_Right_6_Number}
	
	m_teamAList_DPS[1] = {Name=BS_SeaMatch_JieSuan_Client01_Left_1_name,MenPai=BS_SeaMatch_JieSuan_Client01_Left_1_MP,Number=BS_SeaMatch_JieSuan_Client01_Left_1_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Left_1_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Left_1_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Left_1_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Left_1_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Left_1_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Left_1_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Left_1_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Left_1_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Left_1_HPS_Text,}
	m_teamAList_DPS[2] = {Name=BS_SeaMatch_JieSuan_Client01_Left_2_name,MenPai=BS_SeaMatch_JieSuan_Client01_Left_2_MP,Number=BS_SeaMatch_JieSuan_Client01_Left_2_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Left_2_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Left_2_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Left_2_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Left_2_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Left_2_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Left_2_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Left_2_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Left_2_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Left_2_HPS_Text,}
	m_teamAList_DPS[3] = {Name=BS_SeaMatch_JieSuan_Client01_Left_3_name,MenPai=BS_SeaMatch_JieSuan_Client01_Left_3_MP,Number=BS_SeaMatch_JieSuan_Client01_Left_3_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Left_3_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Left_3_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Left_3_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Left_3_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Left_3_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Left_3_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Left_3_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Left_3_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Left_3_HPS_Text,}
	m_teamAList_DPS[4] = {Name=BS_SeaMatch_JieSuan_Client01_Left_4_name,MenPai=BS_SeaMatch_JieSuan_Client01_Left_4_MP,Number=BS_SeaMatch_JieSuan_Client01_Left_4_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Left_4_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Left_4_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Left_4_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Left_4_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Left_4_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Left_4_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Left_4_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Left_4_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Left_4_HPS_Text,}
	m_teamAList_DPS[5] = {Name=BS_SeaMatch_JieSuan_Client01_Left_5_name,MenPai=BS_SeaMatch_JieSuan_Client01_Left_5_MP,Number=BS_SeaMatch_JieSuan_Client01_Left_5_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Left_5_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Left_5_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Left_5_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Left_5_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Left_5_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Left_5_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Left_5_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Left_5_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Left_5_HPS_Text,}
	m_teamAList_DPS[6] = {Name=BS_SeaMatch_JieSuan_Client01_Left_6_name,MenPai=BS_SeaMatch_JieSuan_Client01_Left_6_MP,Number=BS_SeaMatch_JieSuan_Client01_Left_6_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Left_6_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Left_6_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Left_6_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Left_6_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Left_6_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Left_6_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Left_6_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Left_6_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Left_6_HPS_Text,}		

	m_teamBList_DPS[1] = {Name=BS_SeaMatch_JieSuan_Client01_Right_1_name,MenPai=BS_SeaMatch_JieSuan_Client01_Right_1_MP,Number=BS_SeaMatch_JieSuan_Client01_Right_1_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Right_1_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Right_1_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Right_1_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Right_1_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Right_1_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Right_1_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Right_1_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Right_1_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Right_1_HPS_Text,}
	m_teamBList_DPS[2] = {Name=BS_SeaMatch_JieSuan_Client01_Right_2_name,MenPai=BS_SeaMatch_JieSuan_Client01_Right_2_MP,Number=BS_SeaMatch_JieSuan_Client01_Right_2_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Right_2_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Right_2_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Right_2_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Right_2_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Right_2_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Right_2_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Right_2_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Right_2_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Right_2_HPS_Text,}
	m_teamBList_DPS[3] = {Name=BS_SeaMatch_JieSuan_Client01_Right_3_name,MenPai=BS_SeaMatch_JieSuan_Client01_Right_3_MP,Number=BS_SeaMatch_JieSuan_Client01_Right_3_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Right_3_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Right_3_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Right_3_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Right_3_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Right_3_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Right_3_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Right_3_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Right_3_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Right_3_HPS_Text,}
	m_teamBList_DPS[4] = {Name=BS_SeaMatch_JieSuan_Client01_Right_4_name,MenPai=BS_SeaMatch_JieSuan_Client01_Right_4_MP,Number=BS_SeaMatch_JieSuan_Client01_Right_4_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Right_4_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Right_4_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Right_4_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Right_4_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Right_4_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Right_4_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Right_4_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Right_4_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Right_4_HPS_Text,}
	m_teamBList_DPS[5] = {Name=BS_SeaMatch_JieSuan_Client01_Right_5_name,MenPai=BS_SeaMatch_JieSuan_Client01_Right_5_MP,Number=BS_SeaMatch_JieSuan_Client01_Right_5_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Right_5_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Right_5_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Right_5_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Right_5_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Right_5_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Right_5_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Right_5_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Right_5_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Right_5_HPS_Text,}
	m_teamBList_DPS[6] = {Name=BS_SeaMatch_JieSuan_Client01_Right_6_name,MenPai=BS_SeaMatch_JieSuan_Client01_Right_6_MP,Number=BS_SeaMatch_JieSuan_Client01_Right_6_Number,
			Damage=BS_SeaMatch_JieSuan_Client01_Right_6_DPS,DamageProgress=BS_SeaMatch_JieSuan_Client01_Right_6_DPS_Damage,DamageText=BS_SeaMatch_JieSuan_Client01_Right_6_DPS_Text,
			Afford=BS_SeaMatch_JieSuan_Client01_Right_6_TPS,AffordProgress=BS_SeaMatch_JieSuan_Client01_Right_6_TPS_Damage,AffordText=BS_SeaMatch_JieSuan_Client01_Right_6_TPS_Text,
			Cure=BS_SeaMatch_JieSuan_Client01_Right_6_HPS,CureProgress=BS_SeaMatch_JieSuan_Client01_Right_6_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client01_Right_6_HPS_Text,}
	
	m_teamAList_DPSEx[1] = {Name=BS_SeaMatch_JieSuan_Client02_Left_1_name,MenPai=BS_SeaMatch_JieSuan_Client02_Left_1_MP,Number=BS_SeaMatch_JieSuan_Client02_Left_1_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Left_1_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Left_1_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Left_1_HPS,}
	m_teamAList_DPSEx[2] = {Name=BS_SeaMatch_JieSuan_Client02_Left_2_name,MenPai=BS_SeaMatch_JieSuan_Client02_Left_2_MP,Number=BS_SeaMatch_JieSuan_Client02_Left_2_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Left_2_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Left_2_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Left_2_HPS,}
	m_teamAList_DPSEx[3] = {Name=BS_SeaMatch_JieSuan_Client02_Left_3_name,MenPai=BS_SeaMatch_JieSuan_Client02_Left_3_MP,Number=BS_SeaMatch_JieSuan_Client02_Left_3_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Left_3_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Left_3_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Left_3_HPS,}
	m_teamAList_DPSEx[4] = {Name=BS_SeaMatch_JieSuan_Client02_Left_4_name,MenPai=BS_SeaMatch_JieSuan_Client02_Left_4_MP,Number=BS_SeaMatch_JieSuan_Client02_Left_4_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Left_4_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Left_4_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Left_4_HPS,}
	m_teamAList_DPSEx[5] = {Name=BS_SeaMatch_JieSuan_Client02_Left_5_name,MenPai=BS_SeaMatch_JieSuan_Client02_Left_5_MP,Number=BS_SeaMatch_JieSuan_Client02_Left_5_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Left_5_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Left_5_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Left_5_HPS,}
	m_teamAList_DPSEx[6] = {Name=BS_SeaMatch_JieSuan_Client02_Left_6_name,MenPai=BS_SeaMatch_JieSuan_Client02_Left_6_MP,Number=BS_SeaMatch_JieSuan_Client02_Left_6_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Left_6_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Left_6_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Left_6_HPS,}		

	m_teamBList_DPSEx[1] = {Name=BS_SeaMatch_JieSuan_Client02_Right_1_name,MenPai=BS_SeaMatch_JieSuan_Client02_Right_1_MP,Number=BS_SeaMatch_JieSuan_Client02_Right_1_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Right_1_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Right_1_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Right_1_HPS,}
	m_teamBList_DPSEx[2] = {Name=BS_SeaMatch_JieSuan_Client02_Right_2_name,MenPai=BS_SeaMatch_JieSuan_Client02_Right_2_MP,Number=BS_SeaMatch_JieSuan_Client02_Right_2_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Right_2_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Right_2_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Right_2_HPS,}
	m_teamBList_DPSEx[3] = {Name=BS_SeaMatch_JieSuan_Client02_Right_3_name,MenPai=BS_SeaMatch_JieSuan_Client02_Right_3_MP,Number=BS_SeaMatch_JieSuan_Client02_Right_3_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Right_3_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Right_3_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Right_3_HPS,}
	m_teamBList_DPSEx[4] = {Name=BS_SeaMatch_JieSuan_Client02_Right_4_name,MenPai=BS_SeaMatch_JieSuan_Client02_Right_4_MP,Number=BS_SeaMatch_JieSuan_Client02_Right_4_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Right_4_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Right_4_TPS,CureProgress=BS_SeaMatch_JieSuan_Client02_Right_4_HPS_Damage,CureText=BS_SeaMatch_JieSuan_Client02_Right_4_HPS,}
	m_teamBList_DPSEx[5] = {Name=BS_SeaMatch_JieSuan_Client02_Right_5_name,MenPai=BS_SeaMatch_JieSuan_Client02_Right_5_MP,Number=BS_SeaMatch_JieSuan_Client02_Right_5_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Right_5_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Right_5_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Right_5_HPS,}
	m_teamBList_DPSEx[6] = {Name=BS_SeaMatch_JieSuan_Client02_Right_6_name,MenPai=BS_SeaMatch_JieSuan_Client02_Right_6_MP,Number=BS_SeaMatch_JieSuan_Client02_Right_6_Number,
			DamageText=BS_SeaMatch_JieSuan_Client02_Right_6_DPS,AffordText=BS_SeaMatch_JieSuan_Client02_Right_6_TPS,CureText=BS_SeaMatch_JieSuan_Client02_Right_6_HPS,}
end


--响应事件的函数，当注册的事件发生时会调用的函数
function BS_SeaMatch_JieSuan_OnEvent(event)
	
	if event == "SJTX_JIESUAN" then
		local  opType = tonumber(arg0)
		if opType == 1 then
			if (this:IsVisible()) then
				BS_SeaMatch_JieSuan_Update()
				return
			end
			BS_SeaMatch_JieSuan_Show()
			BS_SeaMatch_JieSuan_Update()
		end
	elseif event == "SJTX_FIGHTUI_OP" then
		local  opType = tonumber(arg0)
		if opType == 3 then --打开界面

			local sceneState = SJTX:LuaFnGetSJTXSceneSceneState()
			if sceneState ~= 3 then
				return
			end
			if (this:IsVisible()) then
				BS_SeaMatch_JieSuan_Update()
				return
			end
			m_isCanCloseUI = 0
			BS_SeaMatch_JieSuan_Show()
			BS_SeaMatch_JieSuan_Update()
		end
	elseif event == "SJTX_FIGHTDATAUPDATE" then
		local opType = tonumber(arg0)
		if opType == 4 then --更新玩家状态
			BS_SeaMatch_JieSuan_Update()
		elseif opType == 1 then
			BS_SeaMatch_JieSuan_Update()
		end
	elseif (event == "SJTX_CLOSEUI") then
		BS_SeaMatch_JieSuan_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if m_isCanCloseUI == 0 then
			m_isCanCloseUI = 1
			return
		end
		BS_SeaMatch_JieSuan_Hide()
	elseif event == "ADJEST_UI_POS" then
		BS_SeaMatch_JieSuan_ResetPos()
	end
end

--显示UI
function BS_SeaMatch_JieSuan_Show()
	BS_SeaMatch_JieSuan_ClearData()
	g_NowCheckPage = 0
	BS_SeaMatch_JieSuan_PageClick(1)
	this:Show()
	
end
--隐藏UI
function BS_SeaMatch_JieSuan_Hide()
	BS_SeaMatch_JieSuan_ClearData()
	m_isCanCloseUI = 1
	this:Hide()
end

--清除数据
function BS_SeaMatch_JieSuan_ClearData()

end
--更新
function BS_SeaMatch_JieSuan_Update()
	BS_SeaMatch_JieSuan_Update_JieSuan()
	BS_SeaMatch_JieSuan_Update_Damage()
	BS_SeaMatch_JieSuan_Update_DamageEx()
end

--更新结算界面
function BS_SeaMatch_JieSuan_Update_JieSuan()
	BS_SeaMatch_JieSuan_Team1FirstKill:Hide()
	BS_SeaMatch_JieSuan_Team2FirstKill:Hide()
	local teamAName, teamBName = SJTX:LuaFnGetSJTXTeamName()
	if "" == teamAName or "" == teamBName then
		BS_SeaMatch_JieSuan_Hide()
		return
	end
	local teamAZoneWorldID, teamBZoneWorldID = SJTX:LuaFnGetSJTXTeamZoneWorldID()
	local teamAServerName = DataPool:GetServerName(teamAZoneWorldID)
	local teamBServerName = DataPool:GetServerName(teamBZoneWorldID)
	if teamAServerName == nil then
		teamAServerName = ""
	end
	if teamBServerName == nil then
		teamBServerName = ""
	end
	local firstKillerResult = SJTX:LuaFnGetSJTXSceneFirstKillerResult()
	local matchResult = SJTX:LuaFnGetSJTXSceneMatchResult()

	local selfSuoShu = SJTX:LuaFnGetSJTXSceneSelfSuoShu()
	local otherSuoShu = 1
	if selfSuoShu ~= 1 and selfSuoShu ~= 2 then
		selfSuoShu = 1
	end
	if selfSuoShu == 1 then
		otherSuoShu = 2
	end
	if teamAServerName ~= "" then
		teamAName = teamAName.."@"..teamAServerName
	end
	if teamBServerName ~= "" then
		teamBName = teamBName.."@"..teamBServerName
	end
	if selfSuoShu == 1 then
		BS_SeaMatch_JieSuan_LeftList_TitleBK:SetText(teamAName)
		BS_SeaMatch_JieSuan_RightList_TitleBK:SetText(teamBName)
		if firstKillerResult == 1 then
			BS_SeaMatch_JieSuan_Team1FirstKill:Show()
		elseif firstKillerResult == 2 then
			BS_SeaMatch_JieSuan_Team2FirstKill:Show()
		end
		if matchResult == 1 then
			BS_SeaMatch_JieSuan_Team_Left:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
			BS_SeaMatch_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		elseif matchResult == 2 then
			BS_SeaMatch_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BS_SeaMatch_JieSuan_Team_Right:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
		else
			BS_SeaMatch_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BS_SeaMatch_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		end
	else
		BS_SeaMatch_JieSuan_LeftList_TitleBK:SetText(teamBName)
		BS_SeaMatch_JieSuan_RightList_TitleBK:SetText(teamAName)
		if firstKillerResult == 1 then
			BS_SeaMatch_JieSuan_Team2FirstKill:Show()
		elseif firstKillerResult == 2 then
			BS_SeaMatch_JieSuan_Team1FirstKill:Show()
		end
		if matchResult == 1 then
			BS_SeaMatch_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BS_SeaMatch_JieSuan_Team_Right:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
		elseif matchResult == 2 then
			BS_SeaMatch_JieSuan_Team_Left:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
			BS_SeaMatch_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			BS_SeaMatch_JieSuan_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BS_SeaMatch_JieSuan_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		end
	end
	--A对信息
	for index=1, 6 do
		m_teamAList[index].Hp:SetProgress(0, 100)
		m_teamAList[index].Name:SetText("")
		m_teamAList[index].MenPai:SetText("")
		m_teamAList[index].Level:SetText("")
		m_teamAList[index].Number:SetText("")
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score = SJTX:LuaFnGetSJTXScenePlayerData(selfSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamAList[index].Hp:SetProgress(hp, 100)
			m_teamAList[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamAList[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamAList[index].Level:SetText(m_MenPaiNameList[menPai].Color..level)
			m_teamAList[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
		end
	end

	--B对信息
	for index=1, 6 do
		m_teamBList[index].Hp:SetProgress(0, 100)
		m_teamBList[index].Name:SetText("")
		m_teamBList[index].MenPai:SetText("")
		m_teamBList[index].Level:SetText("")
		m_teamBList[index].Number:SetText("")
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score = SJTX:LuaFnGetSJTXScenePlayerData(otherSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamBList[index].Hp:SetProgress(hp, 100)
			m_teamBList[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamBList[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamBList[index].Level:SetText(m_MenPaiNameList[menPai].Color..level)
			m_teamBList[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
			
		end
	end
end

--更新伤害界面
function BS_SeaMatch_JieSuan_Update_Damage()
	local selfSuoShu = SJTX:LuaFnGetSJTXSceneSelfSuoShu()
	local otherSuoShu = 1
	if selfSuoShu ~= 1 and selfSuoShu ~= 2 then
		selfSuoShu = 1
	end
	if selfSuoShu == 1 then
		otherSuoShu = 2
	end
	
	local nAllDamageA = 0
	local nAllAffordA = 0
	local nAllCureA = 0
		
	local nAllDamageB = 0
	local nAllAffordB = 0
	local nAllCureB = 0
		
	for index=1, 6 do
		local damage, damageAfford, cure = SJTX:LuaFnGetSJTXScenePlayerDataEx(selfSuoShu, index - 1)
		nAllDamageA = nAllDamageA + damage
		nAllAffordA = nAllAffordA + damageAfford
		nAllCureA = nAllCureA + cure
	end
	
	for index=1, 6 do
		local damage, damageAfford, cure = SJTX:LuaFnGetSJTXScenePlayerDataEx(otherSuoShu, index - 1)
		nAllDamageB = nAllDamageB + damage
		nAllAffordB = nAllAffordB + damageAfford
		nAllCureB = nAllCureB + cure
	end
	
	--A对信息
	for index=1, 6 do
		m_teamAList_DPS[index].Name:SetText("")
		m_teamAList_DPS[index].MenPai:SetText("")
		m_teamAList_DPS[index].Number:SetText("")
		m_teamAList_DPS[index].DamageProgress:SetProgress(0, 100)
		m_teamAList_DPS[index].DamageText:SetText("")
		m_teamAList_DPS[index].AffordProgress:SetProgress(0, 100)
		m_teamAList_DPS[index].AffordText:SetText("")
		m_teamAList_DPS[index].CureProgress:SetProgress(0, 100)
		m_teamAList_DPS[index].CureText:SetText("")
		m_teamAList_DPS[index].Damage:Hide()
		m_teamAList_DPS[index].Afford:Hide()
		m_teamAList_DPS[index].Cure:Hide()
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score = SJTX:LuaFnGetSJTXScenePlayerData(selfSuoShu, index - 1)
		local damage, damageAfford, cure = SJTX:LuaFnGetSJTXScenePlayerDataEx(selfSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamAList_DPS[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamAList_DPS[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamAList_DPS[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
			m_teamAList_DPS[index].DamageProgress:SetProgress(damage, nAllDamageA)
			if nAllDamageA ~= 0 then
				m_teamAList_DPS[index].DamageText:SetText(m_MenPaiNameList[menPai].Color..(math.floor((damage/nAllDamageA)*10000)/100).."%")
			else
				m_teamAList_DPS[index].DamageText:SetText(m_MenPaiNameList[menPai].Color.."0%")
			end
			m_teamAList_DPS[index].AffordProgress:SetProgress(damageAfford, nAllAffordA)
			if nAllAffordA ~= 0 then
				m_teamAList_DPS[index].AffordText:SetText(m_MenPaiNameList[menPai].Color..(math.floor((damageAfford/nAllAffordA)*10000)/100).."%")
			else
				m_teamAList_DPS[index].AffordText:SetText(m_MenPaiNameList[menPai].Color.."0%")
			end
			m_teamAList_DPS[index].CureProgress:SetProgress(cure, nAllCureA)
			if nAllCureA ~= 0 then
				m_teamAList_DPS[index].CureText:SetText(m_MenPaiNameList[menPai].Color..(math.floor((cure/nAllCureA)*10000)/100).."%")
			else
				m_teamAList_DPS[index].CureText:SetText(m_MenPaiNameList[menPai].Color.."0%")
			end
			m_teamAList_DPS[index].Damage:Show()
			m_teamAList_DPS[index].Afford:Show()
			m_teamAList_DPS[index].Cure:Show()
		end
	end

	--B对信息
	for index=1, 6 do
		m_teamBList_DPS[index].Name:SetText("")
		m_teamBList_DPS[index].MenPai:SetText("")
		m_teamBList_DPS[index].Number:SetText("")
		m_teamBList_DPS[index].DamageProgress:SetProgress(0, 100)
		m_teamBList_DPS[index].DamageText:SetText("")
		m_teamBList_DPS[index].AffordProgress:SetProgress(0, 100)
		m_teamBList_DPS[index].AffordText:SetText("")
		m_teamBList_DPS[index].CureProgress:SetProgress(0, 100)
		m_teamBList_DPS[index].CureText:SetText("")
		m_teamBList_DPS[index].Damage:Hide()
		m_teamBList_DPS[index].Afford:Hide()
		m_teamBList_DPS[index].Cure:Hide()
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score = SJTX:LuaFnGetSJTXScenePlayerData(otherSuoShu, index - 1)
		local damage, damageAfford, cure = SJTX:LuaFnGetSJTXScenePlayerDataEx(otherSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamBList_DPS[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamBList_DPS[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamBList_DPS[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
			m_teamBList_DPS[index].DamageProgress:SetProgress(damage, nAllDamageB)
			if nAllDamageB ~= 0 then
				m_teamBList_DPS[index].DamageText:SetText(m_MenPaiNameList[menPai].Color..(math.floor((damage/nAllDamageB)*10000)/100).."%")
			else
				m_teamBList_DPS[index].DamageText:SetText(m_MenPaiNameList[menPai].Color.."0%")
			end
			m_teamBList_DPS[index].AffordProgress:SetProgress(damageAfford, nAllAffordB)
			if nAllAffordB ~= 0 then
				m_teamBList_DPS[index].AffordText:SetText(m_MenPaiNameList[menPai].Color..(math.floor((damageAfford/nAllAffordB)*10000)/100).."%")
			else
				m_teamBList_DPS[index].AffordText:SetText(m_MenPaiNameList[menPai].Color.."0%")
			end
			m_teamBList_DPS[index].CureProgress:SetProgress(cure, nAllCureB)
			if nAllCureB ~= 0 then
				m_teamBList_DPS[index].CureText:SetText(m_MenPaiNameList[menPai].Color..(math.floor((cure/nAllCureB)*10000)/100).."%")
			else
				m_teamBList_DPS[index].CureText:SetText(m_MenPaiNameList[menPai].Color.."0%")
			end
			m_teamBList_DPS[index].Damage:Show()
			m_teamBList_DPS[index].Afford:Show()
			m_teamBList_DPS[index].Cure:Show()
		end
	end
end


--更新伤害界面
function BS_SeaMatch_JieSuan_Update_DamageEx()
	local selfSuoShu = SJTX:LuaFnGetSJTXSceneSelfSuoShu()
	local otherSuoShu = 1
	if selfSuoShu ~= 1 and selfSuoShu ~= 2 then
		selfSuoShu = 1
	end
	if selfSuoShu == 1 then
		otherSuoShu = 2
	end
	
	--A对信息
	for index=1, 6 do
		m_teamAList_DPSEx[index].Name:SetText("")
		m_teamAList_DPSEx[index].MenPai:SetText("")
		m_teamAList_DPSEx[index].Number:SetText("")
		m_teamAList_DPSEx[index].DamageText:SetText("")
		m_teamAList_DPSEx[index].AffordText:SetText("")
		m_teamAList_DPSEx[index].CureText:SetText("")
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score = SJTX:LuaFnGetSJTXScenePlayerData(selfSuoShu, index - 1)
		local damage, damageAfford, cure = SJTX:LuaFnGetSJTXScenePlayerDataEx(selfSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamAList_DPSEx[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamAList_DPSEx[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamAList_DPSEx[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
			m_teamAList_DPSEx[index].DamageText:SetText(m_MenPaiNameList[menPai].Color..damage)
			m_teamAList_DPSEx[index].AffordText:SetText(m_MenPaiNameList[menPai].Color..damageAfford)
			m_teamAList_DPSEx[index].CureText:SetText(m_MenPaiNameList[menPai].Color..cure)
		end
	end

	--B对信息
	for index=1, 6 do
		m_teamBList_DPSEx[index].Name:SetText("")
		m_teamBList_DPSEx[index].MenPai:SetText("")
		m_teamBList_DPSEx[index].Number:SetText("")
		m_teamBList_DPSEx[index].DamageText:SetText("")
		m_teamBList_DPSEx[index].AffordText:SetText("")
		m_teamBList_DPSEx[index].CureText:SetText("")
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score = SJTX:LuaFnGetSJTXScenePlayerData(otherSuoShu, index - 1)
		local damage, damageAfford, cure = SJTX:LuaFnGetSJTXScenePlayerDataEx(otherSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamBList_DPSEx[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamBList_DPSEx[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamBList_DPSEx[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
			m_teamBList_DPSEx[index].DamageText:SetText(m_MenPaiNameList[menPai].Color..damage)
			m_teamBList_DPSEx[index].AffordText:SetText(m_MenPaiNameList[menPai].Color..damageAfford)
			m_teamBList_DPSEx[index].CureText:SetText(m_MenPaiNameList[menPai].Color..cure)
		end
	end
end

--##############点击事件##############
--####################################
function BS_SeaMatch_JieSuan_PageClick(index)
	if index == 1 then
		BS_SeaMatch_JieSuan_TopBK:Show()
		BS_SeaMatch_JieSuan_Client01:Hide()
		BS_SeaMatch_JieSuan_Client02:Hide()
		BS_SeaMatch_JieSuan_Client_Btn01:Disable()
		BS_SeaMatch_JieSuan_Client_Btn02:Enable()
		BS_SeaMatch_JieSuan_Client_Btn03:Hide()
	elseif index == 2 then
		BS_SeaMatch_JieSuan_Mode_Click()
		BS_SeaMatch_JieSuan_Client_Btn01:Enable()
		BS_SeaMatch_JieSuan_Client_Btn02:Disable()
		BS_SeaMatch_JieSuan_Client_Btn03:Show()		
	end	
end

function BS_SeaMatch_JieSuan_Mode_Click()
	if g_NowCheckPage == 0 then
		BS_SeaMatch_JieSuan_TopBK:Hide()
		BS_SeaMatch_JieSuan_Client01:Show()
		BS_SeaMatch_JieSuan_Client02:Hide()	
		g_NowCheckPage = 1
	else
		BS_SeaMatch_JieSuan_TopBK:Hide()
		BS_SeaMatch_JieSuan_Client01:Hide()
		BS_SeaMatch_JieSuan_Client02:Show()	
		g_NowCheckPage = 0
	end
end

