--gm视角界面 !!!reloadscript =OB_Pad
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

local g_TaoHuaDaoMp = 13
local g_SkillNum = 9
local g_BuffNum = 9


local g_teamAPkList = { player = nil, head = nil, headMask=nil, menpai=nil, name=nil, state={}, skill={}, buff={} }
local g_teamBPkList = { player = nil, head = nil, headMask=nil, menpai=nil, name=nil, state={}, skill={}, buff={} }

local g_teamARestList = {}
local g_teamBRestList = {}

local g_MaxTeamMember = 6

local g_TeamA = 1
local g_TeamB = 2

local g_HpFlashPoint = 20 --当该玩家血量不足20%时，头像蒙红，血条播放闪动动画

--全局可改变的变量
local g_bShowTitle = 0 --是否显示称号
local g_RoundOver = 0


--预加载函数，可以而且只能在这里注册脚本关心的事件
function OB_Pad_PreLoad()
	this:RegisterEvent("GMVISIBLE_ALLDATA") --所有数据，需要打开界面
	this:RegisterEvent("GMVISIBLE_CHANGEDATA") --变化的数据
	this:RegisterEvent("GMVISIBLE_OPEN")
	
	this:RegisterEvent("SJTX_FIGHTDATAUPDATE", false)
	
	this:RegisterEvent("DFS_FIGHTDATAUPDATE", false)
	--this:RegisterEvent("DFS_CLOSEUI")
	--this:RegisterEvent("SJTX_CLOSEUI")
	
	this:RegisterEvent("SJTX_JIESUAN")
	this:RegisterEvent("DFS_JIESUAN")
	this:RegisterEvent("ZBS_BATTLE_RESULT")

	this:RegisterEvent("CORPS_COPYDATA_REFRESH_2018", false) --更新血量
	this:RegisterEvent("CORPS_COPYDATA_SYNC_TIME_2018", false) --更新时间
	this:RegisterEvent("SHOW_PK_RESULT_2018") --比赛结果
	this:RegisterEvent("GMVISIBLE_JIFEN", false) --积分
	this:RegisterEvent("ZBS_BATTLE_REFRESH", false)
	this:RegisterEvent("ZBS_BATTLE_TIME_RFRESH", false)
	this:RegisterEvent("ZBS_BATTLE_SHOW", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("GMVISIBLE_CLOSE", false) --
	this:RegisterEvent("CAMERA_VISUAL_ACTIVE",false) --退出第一人称视角UI显隐
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function OB_Pad_ResetPos()
	OB_Pad_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	OB_Pad_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function OB_Pad_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= OB_Pad_Frame:GetProperty("UnifiedXPosition")
	m_Frame_UnifiedXPosition	= OB_Pad_Frame:GetProperty("UnifiedYPosition")
	
	--pk区
	g_teamAPkList[1] = {
		player=OB_Left_6V6_Player1_BK, head=OB_Left_6V6_Player1_Head, menpai=OB_Left_6V6_Player1_Menpai, headMask=OB_Left_6V6_Player1_HeadMask,
		name=OB_Left_6V6_Player1_Nametext, level=OB_Left_6V6_Player1_Leveltext,
		state={hp=OB_Left_6V6_Player1_HP, hpFlash=OB_Left_6V6_Player1_HP_Flash, mp=OB_Left_6V6_Player1_MP, sp=OB_Left_6V6_Player1_SP, 
				gq=OB_Left_6V6_Player1_GQ, tep=OB_Left_6V6_Player1_TEP
		},
		
		skill={
			OB_Left_6V6_Player1_Skill1, OB_Left_6V6_Player1_Skill2, OB_Left_6V6_Player1_Skill3, OB_Left_6V6_Player1_Skill4, OB_Left_6V6_Player1_Skill5,
			OB_Left_6V6_Player1_Skill6, OB_Left_6V6_Player1_Skill7, OB_Left_6V6_Player1_Skill8, OB_Left_6V6_Player1_Skill9
		},		
		buff={
			OB_Left_6V6_Player1_Buff1, OB_Left_6V6_Player1_Buff2, OB_Left_6V6_Player1_Buff3, OB_Left_6V6_Player1_Buff4, OB_Left_6V6_Player1_Buff5, 
			OB_Left_6V6_Player1_Buff6, OB_Left_6V6_Player1_Buff7, OB_Left_6V6_Player1_Buff8, OB_Left_6V6_Player1_Buff9, 
		},
	}

	g_teamAPkList[2] = {
		player=OB_Left_6V6_Player2_BK, head=OB_Left_6V6_Player2_Head, menpai=OB_Left_6V6_Player2_Menpai, headMask=OB_Left_6V6_Player2_HeadMask,
		name=OB_Left_6V6_Player2_Nametext, level=OB_Left_6V6_Player2_Leveltext,
		state={hp=OB_Left_6V6_Player2_HP, hpFlash=OB_Left_6V6_Player2_HP_Flash, mp=OB_Left_6V6_Player2_MP, sp=OB_Left_6V6_Player2_SP, 
				gq=OB_Left_6V6_Player2_GQ, tep=OB_Left_6V6_Player2_TEP
		},
		
		skill={
			OB_Left_6V6_Player2_Skill1, OB_Left_6V6_Player2_Skill2, OB_Left_6V6_Player2_Skill3, OB_Left_6V6_Player2_Skill4, OB_Left_6V6_Player2_Skill5,
			OB_Left_6V6_Player2_Skill6, OB_Left_6V6_Player2_Skill7, OB_Left_6V6_Player2_Skill8, OB_Left_6V6_Player2_Skill9
		},		
		buff={
			OB_Left_6V6_Player2_Buff1, OB_Left_6V6_Player2_Buff2, OB_Left_6V6_Player2_Buff3, OB_Left_6V6_Player2_Buff4, OB_Left_6V6_Player2_Buff5, 
			OB_Left_6V6_Player2_Buff6, OB_Left_6V6_Player2_Buff7, OB_Left_6V6_Player2_Buff8, OB_Left_6V6_Player2_Buff9, 
		},
	}

	g_teamAPkList[3] = {
		player=OB_Left_6V6_Player3_BK, head=OB_Left_6V6_Player3_Head, menpai=OB_Left_6V6_Player3_Menpai, headMask=OB_Left_6V6_Player3_HeadMask,
		name=OB_Left_6V6_Player3_Nametext, level=OB_Left_6V6_Player3_Leveltext,
		state={hp=OB_Left_6V6_Player3_HP, hpFlash=OB_Left_6V6_Player3_HP_Flash, mp=OB_Left_6V6_Player3_MP, sp=OB_Left_6V6_Player3_SP, 
				gq=OB_Left_6V6_Player3_GQ, tep=OB_Left_6V6_Player3_TEP
		},
		
		skill={
			OB_Left_6V6_Player3_Skill1, OB_Left_6V6_Player3_Skill2, OB_Left_6V6_Player3_Skill3, OB_Left_6V6_Player3_Skill4, OB_Left_6V6_Player3_Skill5,
			OB_Left_6V6_Player3_Skill6, OB_Left_6V6_Player3_Skill7, OB_Left_6V6_Player3_Skill8, OB_Left_6V6_Player3_Skill9
		},		
		buff={
			OB_Left_6V6_Player3_Buff1, OB_Left_6V6_Player3_Buff2, OB_Left_6V6_Player3_Buff3, OB_Left_6V6_Player3_Buff4, OB_Left_6V6_Player3_Buff5, 
			OB_Left_6V6_Player3_Buff6, OB_Left_6V6_Player3_Buff7, OB_Left_6V6_Player3_Buff8, OB_Left_6V6_Player3_Buff9, 
		},
	}

	g_teamAPkList[4] = {
		player=OB_Left_6V6_Player4_BK, head=OB_Left_6V6_Player4_Head, menpai=OB_Left_6V6_Player4_Menpai, headMask=OB_Left_6V6_Player4_HeadMask,
		name=OB_Left_6V6_Player4_Nametext, level=OB_Left_6V6_Player4_Leveltext,
		state={hp=OB_Left_6V6_Player4_HP, hpFlash=OB_Left_6V6_Player4_HP_Flash, mp=OB_Left_6V6_Player4_MP, sp=OB_Left_6V6_Player4_SP, 
				gq=OB_Left_6V6_Player4_GQ, tep=OB_Left_6V6_Player4_TEP
		},
		
		skill={
			OB_Left_6V6_Player4_Skill1, OB_Left_6V6_Player4_Skill2, OB_Left_6V6_Player4_Skill3, OB_Left_6V6_Player4_Skill4, OB_Left_6V6_Player4_Skill5,
			OB_Left_6V6_Player4_Skill6, OB_Left_6V6_Player4_Skill7, OB_Left_6V6_Player4_Skill8, OB_Left_6V6_Player4_Skill9
		},		
		buff={
			OB_Left_6V6_Player4_Buff1, OB_Left_6V6_Player4_Buff2, OB_Left_6V6_Player4_Buff3, OB_Left_6V6_Player4_Buff4, OB_Left_6V6_Player4_Buff5, 
			OB_Left_6V6_Player4_Buff6, OB_Left_6V6_Player4_Buff7, OB_Left_6V6_Player4_Buff8, OB_Left_6V6_Player4_Buff9, 
		},
	}

	g_teamAPkList[5] = {
		player=OB_Left_6V6_Player5_BK, head=OB_Left_6V6_Player5_Head, menpai=OB_Left_6V6_Player5_Menpai, headMask=OB_Left_6V6_Player5_HeadMask,
		name=OB_Left_6V6_Player5_Nametext, level=OB_Left_6V6_Player5_Leveltext,
		state={hp=OB_Left_6V6_Player5_HP, hpFlash=OB_Left_6V6_Player5_HP_Flash, mp=OB_Left_6V6_Player5_MP, sp=OB_Left_6V6_Player5_SP, 
				gq=OB_Left_6V6_Player5_GQ, tep=OB_Left_6V6_Player5_TEP
		},
		
		skill={
			OB_Left_6V6_Player5_Skill1, OB_Left_6V6_Player5_Skill2, OB_Left_6V6_Player5_Skill3, OB_Left_6V6_Player5_Skill4, OB_Left_6V6_Player5_Skill5,
			OB_Left_6V6_Player5_Skill6, OB_Left_6V6_Player5_Skill7, OB_Left_6V6_Player5_Skill8, OB_Left_6V6_Player5_Skill9
		},		
		buff={
			OB_Left_6V6_Player5_Buff1, OB_Left_6V6_Player5_Buff2, OB_Left_6V6_Player5_Buff3, OB_Left_6V6_Player5_Buff4, OB_Left_6V6_Player5_Buff5, 
			OB_Left_6V6_Player5_Buff6, OB_Left_6V6_Player5_Buff7, OB_Left_6V6_Player5_Buff8, OB_Left_6V6_Player5_Buff9, 
		},
	}

	g_teamAPkList[6] = {
		player=OB_Left_6V6_Player6_BK, head=OB_Left_6V6_Player6_Head, menpai=OB_Left_6V6_Player6_Menpai, headMask=OB_Left_6V6_Player6_HeadMask,
		name=OB_Left_6V6_Player6_Nametext, level=OB_Left_6V6_Player6_Leveltext,
		state={hp=OB_Left_6V6_Player6_HP, hpFlash=OB_Left_6V6_Player6_HP_Flash, mp=OB_Left_6V6_Player6_MP, sp=OB_Left_6V6_Player6_SP, 
				gq=OB_Left_6V6_Player6_GQ, tep=OB_Left_6V6_Player6_TEP
		},
		
		skill={
			OB_Left_6V6_Player6_Skill1, OB_Left_6V6_Player6_Skill2, OB_Left_6V6_Player6_Skill3, OB_Left_6V6_Player6_Skill4, OB_Left_6V6_Player6_Skill5,
			OB_Left_6V6_Player6_Skill6, OB_Left_6V6_Player6_Skill7, OB_Left_6V6_Player6_Skill8, OB_Left_6V6_Player6_Skill9
		},		
		buff={
			OB_Left_6V6_Player6_Buff1, OB_Left_6V6_Player6_Buff2, OB_Left_6V6_Player6_Buff3, OB_Left_6V6_Player6_Buff4, OB_Left_6V6_Player6_Buff5, 
			OB_Left_6V6_Player6_Buff6, OB_Left_6V6_Player6_Buff7, OB_Left_6V6_Player6_Buff8, OB_Left_6V6_Player6_Buff9, 
		},
	}
	
	g_teamBPkList[1] = {
		player=OB_Right_6V6_Player1_BK, head=OB_Right_6V6_Player1_Head, menpai=OB_Right_6V6_Player1_Menpai, headMask=OB_Right_6V6_Player1_HeadMask,
		name=OB_Right_6V6_Player1_Nametext, level=OB_Right_6V6_Player1_Leveltext,
		state={hp=OB_Right_6V6_Player1_HP, hpFlash=OB_Right_6V6_Player1_HP_Flash, mp=OB_Right_6V6_Player1_MP, sp=OB_Right_6V6_Player1_SP, 
				gq=OB_Right_6V6_Player1_GQ, tep=OB_Right_6V6_Player1_TEP
		},
		
		skill={
			OB_Right_6V6_Player1_Skill1, OB_Right_6V6_Player1_Skill2, OB_Right_6V6_Player1_Skill3, OB_Right_6V6_Player1_Skill4, OB_Right_6V6_Player1_Skill5,
			OB_Right_6V6_Player1_Skill6, OB_Right_6V6_Player1_Skill7, OB_Right_6V6_Player1_Skill8, OB_Right_6V6_Player1_Skill9
		},		
		buff={
			OB_Right_6V6_Player1_Buff1, OB_Right_6V6_Player1_Buff2, OB_Right_6V6_Player1_Buff3, OB_Right_6V6_Player1_Buff4, OB_Right_6V6_Player1_Buff5, 
			OB_Right_6V6_Player1_Buff6, OB_Right_6V6_Player1_Buff7, OB_Right_6V6_Player1_Buff8, OB_Right_6V6_Player1_Buff9, 
		},
	}

	g_teamBPkList[2] = {
		player=OB_Right_6V6_Player2_BK, head=OB_Right_6V6_Player2_Head, menpai=OB_Right_6V6_Player2_Menpai, headMask=OB_Right_6V6_Player2_HeadMask,
		name=OB_Right_6V6_Player2_Nametext, level=OB_Right_6V6_Player2_Leveltext,
		state={hp=OB_Right_6V6_Player2_HP, hpFlash=OB_Right_6V6_Player2_HP_Flash, mp=OB_Right_6V6_Player2_MP, sp=OB_Right_6V6_Player2_SP, 
				gq=OB_Right_6V6_Player2_GQ, tep=OB_Right_6V6_Player2_TEP
		},
		
		skill={
			OB_Right_6V6_Player2_Skill1, OB_Right_6V6_Player2_Skill2, OB_Right_6V6_Player2_Skill3, OB_Right_6V6_Player2_Skill4, OB_Right_6V6_Player2_Skill5,
			OB_Right_6V6_Player2_Skill6, OB_Right_6V6_Player2_Skill7, OB_Right_6V6_Player2_Skill8, OB_Right_6V6_Player2_Skill9
		},		
		buff={
			OB_Right_6V6_Player2_Buff1, OB_Right_6V6_Player2_Buff2, OB_Right_6V6_Player2_Buff3, OB_Right_6V6_Player2_Buff4, OB_Right_6V6_Player2_Buff5, 
			OB_Right_6V6_Player2_Buff6, OB_Right_6V6_Player2_Buff7, OB_Right_6V6_Player2_Buff8, OB_Right_6V6_Player2_Buff9, 
		},
	}

	g_teamBPkList[3] = {
		player=OB_Right_6V6_Player3_BK, head=OB_Right_6V6_Player3_Head, menpai=OB_Right_6V6_Player3_Menpai, headMask=OB_Right_6V6_Player3_HeadMask,
		name=OB_Right_6V6_Player3_Nametext, level=OB_Right_6V6_Player3_Leveltext,
		state={hp=OB_Right_6V6_Player3_HP, hpFlash=OB_Right_6V6_Player3_HP_Flash, mp=OB_Right_6V6_Player3_MP, sp=OB_Right_6V6_Player3_SP, 
				gq=OB_Right_6V6_Player3_GQ, tep=OB_Right_6V6_Player3_TEP
		},
		
		skill={
			OB_Right_6V6_Player3_Skill1, OB_Right_6V6_Player3_Skill2, OB_Right_6V6_Player3_Skill3, OB_Right_6V6_Player3_Skill4, OB_Right_6V6_Player3_Skill5,
			OB_Right_6V6_Player3_Skill6, OB_Right_6V6_Player3_Skill7, OB_Right_6V6_Player3_Skill8, OB_Right_6V6_Player3_Skill9
		},		
		buff={
			OB_Right_6V6_Player3_Buff1, OB_Right_6V6_Player3_Buff2, OB_Right_6V6_Player3_Buff3, OB_Right_6V6_Player3_Buff4, OB_Right_6V6_Player3_Buff5, 
			OB_Right_6V6_Player3_Buff6, OB_Right_6V6_Player3_Buff7, OB_Right_6V6_Player3_Buff8, OB_Right_6V6_Player3_Buff9, 
		},
	}

	g_teamBPkList[4] = {
		player=OB_Right_6V6_Player4_BK, head=OB_Right_6V6_Player4_Head, menpai=OB_Right_6V6_Player4_Menpai, headMask=OB_Right_6V6_Player4_HeadMask,
		name=OB_Right_6V6_Player4_Nametext, level=OB_Right_6V6_Player4_Leveltext,
		state={hp=OB_Right_6V6_Player4_HP, hpFlash=OB_Right_6V6_Player4_HP_Flash, mp=OB_Right_6V6_Player4_MP, sp=OB_Right_6V6_Player4_SP, 
				gq=OB_Right_6V6_Player4_GQ, tep=OB_Right_6V6_Player4_TEP
		},
		
		skill={
			OB_Right_6V6_Player4_Skill1, OB_Right_6V6_Player4_Skill2, OB_Right_6V6_Player4_Skill3, OB_Right_6V6_Player4_Skill4, OB_Right_6V6_Player4_Skill5,
			OB_Right_6V6_Player4_Skill6, OB_Right_6V6_Player4_Skill7, OB_Right_6V6_Player4_Skill8, OB_Right_6V6_Player4_Skill9
		},		
		buff={
			OB_Right_6V6_Player4_Buff1, OB_Right_6V6_Player4_Buff2, OB_Right_6V6_Player4_Buff3, OB_Right_6V6_Player4_Buff4, OB_Right_6V6_Player4_Buff5, 
			OB_Right_6V6_Player4_Buff6, OB_Right_6V6_Player4_Buff7, OB_Right_6V6_Player4_Buff8, OB_Right_6V6_Player4_Buff9, 
		},
	}

	g_teamBPkList[5] = {
		player=OB_Right_6V6_Player5_BK, head=OB_Right_6V6_Player5_Head, menpai=OB_Right_6V6_Player5_Menpai, headMask=OB_Right_6V6_Player5_HeadMask,
		name=OB_Right_6V6_Player5_Nametext, level=OB_Right_6V6_Player5_Leveltext,
		state={hp=OB_Right_6V6_Player5_HP, hpFlash=OB_Right_6V6_Player5_HP_Flash, mp=OB_Right_6V6_Player5_MP, sp=OB_Right_6V6_Player5_SP, 
				gq=OB_Right_6V6_Player5_GQ, tep=OB_Right_6V6_Player5_TEP
		},
		
		skill={
			OB_Right_6V6_Player5_Skill1, OB_Right_6V6_Player5_Skill2, OB_Right_6V6_Player5_Skill3, OB_Right_6V6_Player5_Skill4, OB_Right_6V6_Player5_Skill5,
			OB_Right_6V6_Player5_Skill6, OB_Right_6V6_Player5_Skill7, OB_Right_6V6_Player5_Skill8, OB_Right_6V6_Player5_Skill9
		},		
		buff={
			OB_Right_6V6_Player5_Buff1, OB_Right_6V6_Player5_Buff2, OB_Right_6V6_Player5_Buff3, OB_Right_6V6_Player5_Buff4, OB_Right_6V6_Player5_Buff5, 
			OB_Right_6V6_Player5_Buff6, OB_Right_6V6_Player5_Buff7, OB_Right_6V6_Player5_Buff8, OB_Right_6V6_Player5_Buff9, 
		},
	}

	g_teamBPkList[6] = {
		player=OB_Right_6V6_Player6_BK, head=OB_Right_6V6_Player6_Head, menpai=OB_Right_6V6_Player6_Menpai, headMask=OB_Right_6V6_Player6_HeadMask,
		name=OB_Right_6V6_Player6_Nametext, level=OB_Right_6V6_Player6_Leveltext,
		state={hp=OB_Right_6V6_Player6_HP, hpFlash=OB_Right_6V6_Player6_HP_Flash, mp=OB_Right_6V6_Player6_MP, sp=OB_Right_6V6_Player6_SP, 
				gq=OB_Right_6V6_Player6_GQ, tep=OB_Right_6V6_Player6_TEP
		},
		
		skill={
			OB_Right_6V6_Player6_Skill1, OB_Right_6V6_Player6_Skill2, OB_Right_6V6_Player6_Skill3, OB_Right_6V6_Player6_Skill4, OB_Right_6V6_Player6_Skill5,
			OB_Right_6V6_Player6_Skill6, OB_Right_6V6_Player6_Skill7, OB_Right_6V6_Player6_Skill8, OB_Right_6V6_Player6_Skill9
		},		
		buff={
			OB_Right_6V6_Player6_Buff1, OB_Right_6V6_Player6_Buff2, OB_Right_6V6_Player6_Buff3, OB_Right_6V6_Player6_Buff4, OB_Right_6V6_Player6_Buff5, 
			OB_Right_6V6_Player6_Buff6, OB_Right_6V6_Player6_Buff7, OB_Right_6V6_Player6_Buff8, OB_Right_6V6_Player6_Buff9, 
		},
	}
	
	g_teamARestList[1] = {
		player=OB_Left_0V0_Player6_BK, head=OB_Left_0V0_Player6_Head, menpai=OB_Left_0V0_Player6_MenPai,
		name=OB_Left_0V0_Player6_Nametext, level=OB_Left_0V0_Player6_Leveltext,
	}

	g_teamARestList[2] = {
		player=OB_Left_0V0_Player5_BK, head=OB_Left_0V0_Player5_Head, menpai=OB_Left_0V0_Player5_MenPai,
		name=OB_Left_0V0_Player5_Nametext, level=OB_Left_0V0_Player5_Leveltext,
	}

	g_teamARestList[3] = {
		player=OB_Left_0V0_Player4_BK, head=OB_Left_0V0_Player4_Head, menpai=OB_Left_0V0_Player4_MenPai,
		name=OB_Left_0V0_Player4_Nametext, level=OB_Left_0V0_Player4_Leveltext,
	}

	g_teamARestList[4] = {
		player=OB_Left_0V0_Player3_BK, head=OB_Left_0V0_Player3_Head, menpai=OB_Left_0V0_Player3_MenPai,
		name=OB_Left_0V0_Player3_Nametext, level=OB_Left_0V0_Player3_Leveltext,
	}

	g_teamARestList[5] = {
		player=OB_Left_0V0_Player2_BK, head=OB_Left_0V0_Player2_Head, menpai=OB_Left_0V0_Player2_MenPai,
		name=OB_Left_0V0_Player2_Nametext, level=OB_Left_0V0_Player2_Leveltext,
	}

	g_teamARestList[6] = {
		player=OB_Left_0V0_Player1_BK, head=OB_Left_0V0_Player1_Head, menpai=OB_Left_0V0_Player1_MenPai,
		name=OB_Left_0V0_Player1_Nametext, level=OB_Left_0V0_Player1_Leveltext,
	}

	g_teamBRestList[1] = {
		player=OB_Right_0V0_Player6_BK, head=OB_Right_0V0_Player6_Head, menpai=OB_Right_0V0_Player6_MenPai,
		name=OB_Right_0V0_Player6_Nametext, level=OB_Right_0V0_Player6_Leveltext,
	}

	g_teamBRestList[2] = {
		player=OB_Right_0V0_Player5_BK, head=OB_Right_0V0_Player5_Head, menpai=OB_Right_0V0_Player5_MenPai,
		name=OB_Right_0V0_Player5_Nametext, level=OB_Right_0V0_Player5_Leveltext,
	}

	g_teamBRestList[3] = {
		player=OB_Right_0V0_Player4_BK, head=OB_Right_0V0_Player4_Head, menpai=OB_Right_0V0_Player4_MenPai,
		name=OB_Right_0V0_Player4_Nametext, level=OB_Right_0V0_Player4_Leveltext,
	}

	g_teamBRestList[4] = {		
		player=OB_Right_0V0_Player3_BK, head=OB_Right_0V0_Player3_Head, menpai=OB_Right_0V0_Player3_MenPai,
		name=OB_Right_0V0_Player3_Nametext, level=OB_Right_0V0_Player3_Leveltext,
	}

	g_teamBRestList[5] = {
		player=OB_Right_0V0_Player2_BK, head=OB_Right_0V0_Player2_Head, menpai=OB_Right_0V0_Player2_MenPai,
		name=OB_Right_0V0_Player2_Nametext, level=OB_Right_0V0_Player2_Leveltext,
	}

	g_teamBRestList[6] = {
		player=OB_Right_0V0_Player1_BK, head=OB_Right_0V0_Player1_Head, menpai=OB_Right_0V0_Player1_MenPai,
		name=OB_Right_0V0_Player1_Nametext, level=OB_Right_0V0_Player1_Leveltext,
	}
	
end


--响应事件的函数，当注册的事件发生时会调用的函数
function OB_Pad_OnEvent(event)
	
	if( event == "GMVISIBLE_CLOSE" ) then
		OB_Pad_Hide(2)
	end

	if DataPool:LuaFnGetGMVisibleType() == 0 then
		return
	end
	
	if event == "GMVISIBLE_ALLDATA" then
		OB_Pad_Show(1)
		
	elseif event == "GMVISIBLE_CHANGEDATA" then
		
		--下一局开始
		if g_RoundOver == 1 then
			g_RoundOver = 0
			OB_Pad_Update_JieSuan()
		end
		
		--第一局开始显示界面
		if this:IsVisible() == false then
			OB_Pad_Show(2)	
			return
		end
		
		OB_Pad_UpdateMember( )
		
	elseif event == "SJTX_FIGHTDATAUPDATE" or event == "DFS_FIGHTDATAUPDATE" then
		local opType = tonumber(arg0)
		if opType == 1 then--更新血量
			OB_Pad_UpdateMember( )
		elseif opType == 3 then --更新时间,每秒更新
			OB_Pad_Update_Time()
		elseif opType == 4 then --更新玩家状态
			OB_Pad_UpdateMember( )
		end
	elseif event == "ZBS_BATTLE_REFRESH" or event == "ZBS_BATTLE_SHOW" then
		OB_Pad_Update_Time()
		OB_Pad_UpdateMember()
	elseif event == "GMVISIBLE_JIFEN" then
		OB_Pad_Update_Score()
	
	elseif event == "CORPS_COPYDATA_REFRESH_2018" then --更新血量
		OB_Pad_UpdateMember( )
		
	elseif event == "CORPS_COPYDATA_SYNC_TIME_2018" then --更新血量
		OB_Pad_Update_Time()
	elseif event == "ZBS_BATTLE_TIME_RFRESH" then
		OB_Pad_Update_Time()
	elseif (event == "SJTX_JIESUAN" or event == "DFS_JIESUAN" or event == "SHOW_PK_RESULT_2018" or event == "ZBS_BATTLE_RESULT") then --本局结束
		--本局结束
		OB_Pad_RoundEnd()
	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then --切场景前
		local bInPkScene = OB_Pad_IsInPkScene()
		
		if bInPkScene == 1 then
			g_bShowTitle = 1
			OB_Pad_Update_CreatureBoard()
		end
		
		OB_Pad_Hide(1)
		
	elseif event == "ADJEST_UI_POS" then
		OB_Pad_ResetPos()
		
	elseif event == "GMVISIBLE_OPEN" then
		OB_Pad_Init()
		
	elseif( event == "GMVISIBLE_CLOSE" ) then
		OB_Pad_Hide(2)
	elseif( event == "CAMERA_VISUAL_ACTIVE" ) then
		if ( tostring(arg1) ~= "OB_Pad") then
			return
		end
		
		if ( tonumber(arg0) == 0 ) then
            OB_FirstView_CloseWindow()
        else
            OB_FirstView_OpenWindow()
        end
	end
end

--是否在比赛场景
function OB_Pad_IsInPkScene()
	local nCurScene = GetSceneID()
	local bInPkScene = 0
		
	local bInPkScene_Zbs = CorpsUI_2018:IsInZbsMatchScene()
	if nCurScene == 729 or bInPkScene_Zbs == 1 or nCurScene == 733 or nCurScene == 879 then
		bInPkScene = 1
	end
		
	return bInPkScene
end


--每局只初始化一次的值
function OB_Pad_Init()
	g_RoundOver = 0
	
	--开启特殊视角
	CorpsUI_2016:CancelPlayerWatchPosDirection()
	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		SJTX:LuaSetSpecialSceneFlag()
		
	elseif matchType == 2 then
		DFS:LuaSetSpecialSceneFlag()
		
	elseif matchType == 3 then
		CorpsUI_2018:SetSpecialSceneFlag()
	elseif matchType == 4 then
		ZBS:SetSpecialSceneFlag()
	end

	OB_Pad_CloseOtherWindow()

	OB_FirstView_CloseWindow()
end

function OB_Pad_RoundEnd()
	
	g_RoundOver = 1
	
	OB_Pad_UpdateMember( )
	OB_Pad_Update_Time()
	OB_Pad_Update_JieSuan()
end

--显示UI
function OB_Pad_Show(aa)
	--PushDebugMessage(aa)
	--队伍名字
	OB_Pad_Update_Name()
	
	--成员信息
	OB_Pad_UpdateMember( )
	
	--比分
	OB_Pad_Update_Score()
	
	--倒计时
	OB_Pad_Update_Time()
	
	--胜负
	OB_Pad_Update_JieSuan()
	
	g_bShowTitle = 0
	OB_Pad_Update_CreatureBoard()
	
	--打开数据界面
	OB_Pad_OpenData_Click()
	
	OB_Pad_CloseOtherWindow()

	this:Show()
end

--隐藏UI
function OB_Pad_Hide(aa)
	--PushDebugMessage("aa="..aa)
	CorpsUI_2016:CancelPlayerWatchPosDirection()
	this:Hide()
end

--清除数据
function OB_Pad_ClearMemberData()
	OB_Left_6V6_Client:Hide()
	OB_Left_0V0_Client:Hide()
	
	OB_Right_6V6_Client:Hide()
	OB_Right_0V0_Client:Hide()
	
	--清空数据
	for i=1, g_MaxTeamMember do
		--隐藏
		g_teamAPkList[i].player : Hide()
		g_teamBPkList[i].player : Hide()
		
		--清空数据
		g_teamAPkList[i].head : SetImage("", "")
		g_teamAPkList[i].headMask : Hide()
		g_teamAPkList[i].name : SetText("")
		g_teamAPkList[i].menpai : SetText("")
		g_teamAPkList[i].level : SetText("")
		
		
		for skillIndex=1, g_SkillNum do
			g_teamAPkList[i].skill[skillIndex] : Hide()
		end
		
		for buffIndex=1, g_BuffNum do
			g_teamAPkList[i].buff[buffIndex] : Hide()
		end
		
		--B队
		g_teamBPkList[i].head : SetImage("", "")
		g_teamBPkList[i].headMask : Hide()
		g_teamBPkList[i].name : SetText("")
		g_teamBPkList[i].menpai : SetText("")
		g_teamBPkList[i].level : SetText("")
		
		
		for skillIndex=1, g_SkillNum do
			g_teamBPkList[i].skill[skillIndex] : Hide()
		end
		
		for buffIndex=1, g_BuffNum do
			g_teamBPkList[i].buff[buffIndex] : Hide()
		end
	end
	
	for i=1, g_MaxTeamMember do
		--隐藏
		g_teamARestList[i].player : Hide()
		g_teamBRestList[i].player : Hide()
		
		g_teamARestList[i].head : SetImage("", "")
		g_teamARestList[i].menpai : SetText("")
		g_teamARestList[i].name : SetText("")
		g_teamARestList[i].level : SetText("")
		
		--B队
		g_teamBRestList[i].head : SetImage("", "")
		g_teamBRestList[i].menpai : SetText("")
		g_teamBRestList[i].name : SetText("")
		g_teamBRestList[i].level : SetText("")
	end
end

--战斗状态
--x892843_g_ENBattleState=
--{
--	enBattleStateNone			= 0, --未开始
--	enBattleStateReady 			= 1, --1准备
--	enBattleStateBattle			= 2, --2战斗中
--	enBattleStateBalance 		= 3, --3战斗结算
--}
--local sceneState = SJTX:LuaFnGetSJTXSceneSceneState()

function OB_Pad_Update_Name()
	local teamAName = ""
	local teamBName = ""
	local teamAZoneWorldID = -1
	local teamBZoneWorldID = -1
	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		teamAName, teamBName = SJTX:LuaFnGetSJTXTeamName()
		teamAZoneWorldID, teamBZoneWorldID = SJTX:LuaFnGetSJTXTeamZoneWorldID()
		
	elseif matchType == 2 then
		teamAName, teamBName = DFS:LuaFnGetDfsTeamName()
		teamAZoneWorldID, teamBZoneWorldID = DFS:LuaFnGetDfsTeamZoneWorldID()
		
	elseif matchType == 3 then
		teamAName, teamBName = CorpsUI_2018:GetTwoCorpsNameInCopyScene()
	elseif matchType == 4 then
		teamAName, teamBName = ZBS:GetBattleVisiableInfo("TeamName")
	end

	if "" == teamAName or "" == teamBName then
		return
	end
	
	local teamAServerName = DataPool:GetServerName(teamAZoneWorldID)
	local teamBServerName = DataPool:GetServerName(teamBZoneWorldID)
	if teamAServerName == nil then
		teamAServerName = ""
	end
	if teamBServerName == nil then
		teamBServerName = ""
	end
 
	if teamAServerName ~= "" then
		teamAName = teamAName.."@"..teamAServerName
	end
	if teamBServerName ~= "" then
		teamBName = teamBName.."@"..teamBServerName
	end
	
	local nameAShow = ScriptGlobal_Format("#{SJYH_210426_05}", teamAName) 
	local nameBShow = ScriptGlobal_Format("#{SJYH_210426_05}", teamBName) 
	OB_Top_TeamAtext:SetText(nameAShow)
	OB_Top_TeamBtext:SetText(nameBShow)
	
end


--更新
function OB_Pad_UpdateMember( )
	OB_Pad_ClearMemberData()
	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		OB_Pad_Update_SJTX_MemberInfo( )
	elseif  matchType == 2 then
		OB_Pad_Update_DFS_MemberInfo( )
	elseif  matchType == 3 then
		OB_Pad_Update_ZBS_MemberInfo( )
	elseif  matchType == 4 then
		OB_Pad_Update_ZBS2023_MemberInfo( )
	end
end

function OB_Pad_Update_Rest_Member( )
	for i=1, g_MaxTeamMember do
		local guid = DataPool:LuaFnGetGMVisibleGuid(g_TeamA, i - 1 )
		local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
		
		if level ~= nil and level > 0 then
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamARestList[i].head:SetProperty("Image", portraitImage)
				
			g_teamARestList[i].name:SetText(name)
			g_teamARestList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamARestList[i].level:SetText(level)
			
			g_teamARestList[i].player : Show()
			OB_Left_0V0_Client:Show()
		end
	end
	
	for i=1, g_MaxTeamMember do
		local guid = DataPool:LuaFnGetGMVisibleGuid(g_TeamB, i - 1 )
		local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
		
		if level ~= nil and level > 0 then
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamBRestList[i].head:SetProperty("Image", portraitImage)
				
			g_teamBRestList[i].name:SetText(name)
			g_teamBRestList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamBRestList[i].level:SetText(level)
			
			g_teamBRestList[i].player : Show()
			OB_Right_0V0_Client:Show()
		end
	end
	
end

--拭剑天下成员信息
function OB_Pad_Update_SJTX_MemberInfo( )

	--场上pk队员数据
	--A对信息
	for i=1, g_MaxTeamMember do
				
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamA, i - 1 )
		if nil ~= name and ""~=name then
			g_teamAPkList[i].player : Show()
			
			local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamA, i - 1 )			
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
			
			OB_Pad_Update_MemberHp(guid, i, state, hp, mp, eng, rage, g_TeamA)
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamAPkList[i].head:SetProperty("Image", portraitImage)
				
			g_teamAPkList[i].name:SetText(name)
			g_teamAPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamAPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamA, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamAPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
		
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamA, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamAPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Left_6V6_Client:Show()
		end
	
	end

	
	--B对信息
	for i=1, g_MaxTeamMember do
				
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamB, i - 1 )
		if nil ~= name and ""~=name then
			g_teamBPkList[i].player : Show()
			
			local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamB, i - 1 )			
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
			
			OB_Pad_Update_MemberHp(guid, i, state, hp, mp, eng, rage, g_TeamB)
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamBPkList[i].head:SetProperty("Image", portraitImage)
			
			g_teamBPkList[i].name:SetText(name)
			g_teamBPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamBPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamB, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamBPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
		
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamB, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamBPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Right_6V6_Client:Show()
		end
	
	end
	
	--A对信息
	local restANum = 1
	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXSceneAllGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local isPk = SJTX:LuaFnIsSJTXSceneGuidPk(g_TeamA, guid)
		
			if isPk == 0 then
				g_teamARestList[restANum].player : Show()
			
				local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
				local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
				g_teamARestList[restANum].head:SetProperty("Image", portraitImage)
				
				g_teamARestList[restANum].name:SetText(name)
				g_teamARestList[restANum].menpai:SetText(m_MenPaiNameList[menPai].Name)
				g_teamARestList[restANum].level:SetText(level)
			
				restANum = restANum + 1
				OB_Left_0V0_Client:Show()
			end
		end
	end
	
	--B对信息
	local restBNum = 1
	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXSceneAllGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local isPk = SJTX:LuaFnIsSJTXSceneGuidPk(g_TeamB, guid)
		
			if isPk == 0 then
				g_teamBRestList[restBNum].player : Show()
			
				local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
				local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
				g_teamBRestList[restBNum].head:SetProperty("Image", portraitImage)
				
				g_teamBRestList[restBNum].name:SetText(name)
				g_teamBRestList[restBNum].menpai:SetText(m_MenPaiNameList[menPai].Name)
				g_teamBRestList[restBNum].level:SetText(level)
			
				restBNum = restBNum + 1
				OB_Right_0V0_Client:Show()
			end
		end
	end
end

function OB_Pad_Update_DFS_MemberInfo( )
	
	--场上pk队员数据
	--A对信息
	for i=1, g_MaxTeamMember do
				
		local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamA, i - 1 )
		if nil ~= name and ""~=name then
			g_teamAPkList[i].player : Show()
		
			local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamA, i - 1 )			
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
			

			OB_Pad_Update_MemberHp(guid, i, state, hp, mp, eng, rage, g_TeamA)
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamAPkList[i].head:SetProperty("Image", portraitImage)
			
			g_teamAPkList[i].name:SetText(name)
			g_teamAPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamAPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamA, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamAPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
		
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamA, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamAPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Left_6V6_Client:Show()
		end
	
	end

	
	--B对信息
	for i=1, g_MaxTeamMember do
				
		local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamB, i - 1 )
		if nil ~= name and ""~=name then
			g_teamBPkList[i].player : Show()
			
			local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamB, i - 1 )	
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
			

			OB_Pad_Update_MemberHp(guid, i, state, hp, mp, eng, rage, g_TeamB)
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamBPkList[i].head:SetProperty("Image", portraitImage)
			
			g_teamBPkList[i].name:SetText(name)
			g_teamBPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamBPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamB, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamBPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
		
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamB, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamBPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Right_6V6_Client:Show()
		end
	
	end
	

	--A对信息
	local restANum = 1
	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsSceneAllGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local isPk = DFS:LuaFnIsDfsSceneGuidPk(g_TeamA, guid)
		
			if isPk == 0 then
				g_teamARestList[restANum].player : Show()
			
				local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
				local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
				g_teamARestList[restANum].head:SetProperty("Image", portraitImage)
				
				g_teamARestList[restANum].name:SetText(name)
				g_teamARestList[restANum].menpai:SetText(m_MenPaiNameList[menPai].Name)
				g_teamARestList[restANum].level:SetText(level)
			
				restANum = restANum + 1
				OB_Left_0V0_Client:Show()
			end
		end
	end
	
	--B对信息
	local restBNum = 1
	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsSceneAllGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local isPk = DFS:LuaFnIsDfsSceneGuidPk(g_TeamB, guid)
		
			if isPk == 0 then
				g_teamBRestList[restBNum].player : Show()
			
				local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
				local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
				g_teamBRestList[restBNum].head:SetProperty("Image", portraitImage)
				
				g_teamBRestList[restBNum].name:SetText(name)
				g_teamBRestList[restBNum].menpai:SetText(m_MenPaiNameList[menPai].Name)
				g_teamBRestList[restBNum].level:SetText(level)
			
				restBNum = restBNum + 1
				OB_Right_0V0_Client:Show()
			end
		end
	end
end


--无差别争霸赛成员
function OB_Pad_Update_ZBS_MemberInfo( )
	--场上pk队员数据
	--A对信息
	for i=1, g_MaxTeamMember do
			
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i - 1)
		if nil ~= name and ""~=name then
			g_teamAPkList[i].player : Show()
			
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
			
			g_teamAPkList[i].state.hp : SetProgress(hp, 100)
			g_teamAPkList[i].state.mp : SetProgress(mp, 100)	
					
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamAPkList[i].state.gq : SetProgress(eng, 100)
				g_teamAPkList[i].state.gq : Show()
			else
				g_teamAPkList[i].state.sp : SetProgress(rage, 100)
				g_teamAPkList[i].state.sp : Show()
			end
			
				
			if hp> 0 and hp < g_HpFlashPoint then
				g_teamAPkList[i].state.hpFlash : Play(true)
				g_teamAPkList[i].state.hpFlash : Show()
			else
				g_teamAPkList[i].state.hpFlash : Play(false)
				g_teamAPkList[i].state.hpFlash : Hide()
			end
			
			if hp == 0 then
				g_teamAPkList[i].headMask : Show()
				
				g_teamAPkList[i].state.hp : SetProgress(0, 100)
				g_teamAPkList[i].state.mp : SetProgress(0, 100)
				g_teamAPkList[i].state.gq : SetProgress(0, 100)
				g_teamAPkList[i].state.sp : SetProgress(0, 100)
			end
			
			if g_bShowTitle == 0 then
				Lua_SetSpecialObjHp(guid, hp, 100, g_TeamA)
				Lua_ShowSpecialObjHp(guid, 1, g_TeamA)
			end
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamAPkList[i].head:SetProperty("Image", portraitImage)
			
			g_teamAPkList[i].name:SetText(name)
			g_teamAPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamAPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamA, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamAPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
			
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamA, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamAPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Left_6V6_Client:Show()
		end
	
	end

	
	--B对信息
	for i=1, g_MaxTeamMember do
			
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(g_MaxTeamMember + i - 1)
		if nil ~= name and ""~=name then
			g_teamBPkList[i].player : Show()
			
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
			
			g_teamBPkList[i].state.hp : SetProgress(hp, 100)
			g_teamBPkList[i].state.mp : SetProgress(mp, 100)	
					
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamBPkList[i].state.gq : SetProgress(eng, 100)
				g_teamBPkList[i].state.gq : Show()
			else
				g_teamBPkList[i].state.sp : SetProgress(rage, 100)
				g_teamBPkList[i].state.sp : Show()
			end
				
			if hp> 0 and hp < g_HpFlashPoint then
				g_teamBPkList[i].state.hpFlash : Play(true)
				g_teamBPkList[i].state.hpFlash : Show()
			else
				g_teamBPkList[i].state.hpFlash : Play(false)
				g_teamBPkList[i].state.hpFlash : Hide()
			end
			
			if hp == 0 then
				g_teamBPkList[i].headMask : Show()
				
				g_teamBPkList[i].state.hp : SetProgress(0, 100)
				g_teamBPkList[i].state.mp : SetProgress(0, 100)
				g_teamBPkList[i].state.gq : SetProgress(0, 100)
				g_teamBPkList[i].state.sp : SetProgress(0, 100)
			end
			
			if g_bShowTitle == 0 then
				Lua_SetSpecialObjHp(guid, hp, 100, g_TeamB)
				Lua_ShowSpecialObjHp(guid, 1, g_TeamB)
			end
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamBPkList[i].head:SetProperty("Image", portraitImage)
			
			g_teamBPkList[i].name:SetText(name)
			g_teamBPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamBPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamB, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamBPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
		
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamB, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamBPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Right_6V6_Client:Show()
		end
	
	end
	
end

--拭剑天下成员信息
function OB_Pad_Update_ZBS2023_MemberInfo( )

	--场上pk队员数据
	--A对信息
	for i=1, g_MaxTeamMember do
		local state = 0
		local level,hp,menPai,killnum,post,name = ZBS:GetBattleMemberInfo(i-1)
		if nil ~= level and level > 0 then
			g_teamAPkList[i].player : Show()
			
			local guid = ZBS:GetBattleMemberGuid(i - 1)			
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
			
			OB_Pad_Update_MemberHp(guid, i, state, hp, mp, eng, rage, g_TeamA)
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamAPkList[i].head:SetProperty("Image", portraitImage)
	
			g_teamAPkList[i].name:SetText(name)
			g_teamAPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamAPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamA, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamAPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
		
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamA, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamAPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamAPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamAPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Left_6V6_Client:Show()
		end
	
	end

	
	--B对信息
	for i=1, g_MaxTeamMember do
		local state = 0
		local level,hp,menPai,killnum,post,name = ZBS:GetBattleMemberInfo(g_MaxTeamMember+i-1)
		if nil ~= level and level > 0 then
			g_teamBPkList[i].player : Show()
			
			local guid = ZBS:GetBattleMemberGuid(g_MaxTeamMember+i-1)		
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local _, _, _, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
			
			OB_Pad_Update_MemberHp(guid, i, state, hp, mp, eng, rage, g_TeamB)
			
			local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
			g_teamBPkList[i].head:SetProperty("Image", portraitImage)
			
			g_teamBPkList[i].name:SetText(name)
			g_teamBPkList[i].menpai:SetText(m_MenPaiNameList[menPai].Name)
			g_teamBPkList[i].level:SetText(level)
			
			local skillCnt = 1
			for skillIndex=1, g_SkillNum do
				local skillId, remain = DataPool:LuaFnGetGMVisibleSkill(g_TeamB, guid, skillIndex-1)
				if skillId ~= nil and skillId > 0 then
					local szIconName,szTipInfo = Lua_GetSkillInfo(skillId)
					g_teamBPkList[i].skill[skillCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].skill[skillCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].skill[skillCnt] : Show()
					
					skillCnt = skillCnt + 1
				end
			end
		
			local buffCnt = 1
			for buffIndex=1, g_BuffNum do
				local buffId, remain = DataPool:LuaFnGetGMVisibleImpact(g_TeamB, guid, buffIndex-1)
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					g_teamBPkList[i].buff[buffCnt] : SetProperty("ShortImage", szIconName);
					g_teamBPkList[i].buff[buffCnt] : SetToolTip(szTipInfo);
					g_teamBPkList[i].buff[buffCnt] : Show()
					
					buffCnt = buffCnt + 1
				end
			end
			
			OB_Right_6V6_Client:Show()
		end
	
	end
	
	--A对信息
	local restANum = 1
	for i=1, g_MaxTeamMember do
		local guid = DataPool:LuaFnGetGMVisibleGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local isPk = ZBS:IsBattlePKMember(guid)
			if isPk < 1 then
				g_teamARestList[restANum].player : Show()
			
				local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamA, guid)
				local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
				g_teamARestList[restANum].head:SetProperty("Image", portraitImage)
				
				g_teamARestList[restANum].name:SetText(name)
				g_teamARestList[restANum].menpai:SetText(m_MenPaiNameList[menPai].Name)
				g_teamARestList[restANum].level:SetText(level)
			
				restANum = restANum + 1
				OB_Left_0V0_Client:Show()
			end
		end
	end
	
	--B对信息
	local restBNum = 1
	for i=1, g_MaxTeamMember do
		local guid = DataPool:LuaFnGetGMVisibleGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local isPk = ZBS:IsBattlePKMember(guid)
		
			if isPk < 1 then
				g_teamBRestList[restBNum].player : Show()
			
				local level, menPai, name, portrait = DataPool:LuaFnGetGMVisibleBaseData(g_TeamB, guid)
				local portraitImage =  SJTX:LuaGetPortraitInfo(portrait)
				g_teamBRestList[restBNum].head:SetProperty("Image", portraitImage)
				
				g_teamBRestList[restBNum].name:SetText(name)
				g_teamBRestList[restBNum].menpai:SetText(m_MenPaiNameList[menPai].Name)
				g_teamBRestList[restBNum].level:SetText(level)
			
				restBNum = restBNum + 1
				OB_Right_0V0_Client:Show()
			end
		end
	end
end

function OB_Pad_Update_MemberHp(guid, i, memberState, hp, mp, eng, rage, teamIndex)
	if g_RoundOver == 1 then
		return
	end
	
	
	if teamIndex == g_TeamA then
		g_teamAPkList[i].state.hp : SetProgress(0, 100)
		g_teamAPkList[i].state.hpFlash : Play(false)
		g_teamAPkList[i].state.hpFlash : Hide()
		g_teamAPkList[i].state.mp : SetProgress(0, 100)
		g_teamAPkList[i].state.sp : SetProgress(0, 100)
		g_teamAPkList[i].state.sp : Hide()
		g_teamAPkList[i].state.gq : SetProgress(0, 100)
		g_teamAPkList[i].state.gq : Hide()
		g_teamAPkList[i].state.tep : Hide()
		
		if memberState == 0 then      --0-正常
			g_teamAPkList[i].state.hp : SetProgress(hp, 100)
			g_teamAPkList[i].state.mp : SetProgress(mp, 100)	
					
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamAPkList[i].state.gq : SetProgress(eng, 100)
				g_teamAPkList[i].state.gq : Show()
			else
				g_teamAPkList[i].state.sp : SetProgress(rage, 100)
				g_teamAPkList[i].state.sp : Show()
			end
					
		elseif memberState == 1 then --死亡
			g_teamAPkList[i].state.hp : SetProgress(0, 100)
			g_teamAPkList[i].state.mp : SetProgress(0, 100)
				
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamAPkList[i].state.gq : SetProgress(0, 100)
				g_teamAPkList[i].state.gq : Show()
			else
				g_teamAPkList[i].state.sp : SetProgress(0, 100)
				g_teamAPkList[i].state.sp : Show()
			end
					
		elseif memberState == 2 then --掉线
			g_teamAPkList[i].state.hp : SetProgress(0, 100)
			g_teamAPkList[i].state.mp : SetProgress(0, 100)
					
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamAPkList[i].state.gq : SetProgress(0, 100)
				g_teamAPkList[i].state.gq : Show()
			else
				g_teamAPkList[i].state.sp : SetProgress(0, 100)
				g_teamAPkList[i].state.sp : Show()
			end
				
		end
				
		if hp > 0 and hp < g_HpFlashPoint then
			g_teamAPkList[i].state.hpFlash : Play(true)
			g_teamAPkList[i].state.hpFlash : Show()
		else
			g_teamAPkList[i].state.hpFlash : Play(false)
			g_teamAPkList[i].state.hpFlash : Hide()
		end
			
		if hp == 0 then
			g_teamAPkList[i].headMask : Show()
		end
		
	elseif teamIndex == g_TeamB then
		g_teamBPkList[i].state.hp : SetProgress(0, 100)
		g_teamBPkList[i].state.hpFlash : Play(false)
		g_teamBPkList[i].state.hpFlash : Hide()
		g_teamBPkList[i].state.mp : SetProgress(0, 100)
		g_teamBPkList[i].state.sp : SetProgress(0, 100)
		g_teamBPkList[i].state.sp : Hide()
		g_teamBPkList[i].state.gq : SetProgress(0, 100)
		g_teamBPkList[i].state.gq : Hide()
		g_teamBPkList[i].state.tep : Hide()
		
		if memberState == 0 then      --0-正常
			g_teamBPkList[i].state.hp : SetProgress(hp, 100)
			g_teamBPkList[i].state.mp : SetProgress(mp, 100)	
					
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamBPkList[i].state.gq : SetProgress(eng, 100)
				g_teamBPkList[i].state.gq : Show()
			else
				g_teamBPkList[i].state.sp : SetProgress(rage, 100)
				g_teamBPkList[i].state.sp : Show()
			end
					
		elseif memberState == 1 then --死亡
			g_teamBPkList[i].state.hp : SetProgress(0, 100)
			g_teamBPkList[i].state.mp : SetProgress(0, 100)
				
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamBPkList[i].state.gq : SetProgress(0, 100)
				g_teamBPkList[i].state.gq : Show()
			else
				g_teamBPkList[i].state.sp : SetProgress(0, 100)
				g_teamBPkList[i].state.sp : Show()
			end
					
		elseif memberState == 2 then --掉线
			g_teamBPkList[i].state.hp : SetProgress(0, 100)
			g_teamBPkList[i].state.mp : SetProgress(0, 100)
					
			--怒气
			if menPai == g_TaoHuaDaoMp then
				g_teamBPkList[i].state.gq : SetProgress(0, 100)
				g_teamBPkList[i].state.gq : Show()
			else
				g_teamBPkList[i].state.sp : SetProgress(0, 100)
				g_teamBPkList[i].state.sp : Show()
			end
				
		end
				
		if hp > 0 and hp < g_HpFlashPoint then
			g_teamBPkList[i].state.hpFlash : Play(true)
			g_teamBPkList[i].state.hpFlash : Show()
		else
			g_teamBPkList[i].state.hpFlash : Play(false)
			g_teamBPkList[i].state.hpFlash : Hide()
		end
			
		if hp == 0 then
			g_teamBPkList[i].headMask : Show()
		end
	end
	
			
	if g_bShowTitle == 0 then
		Lua_SetSpecialObjHp(guid, hp, 100, teamIndex)
		Lua_ShowSpecialObjHp(guid, 1, teamIndex)
	end
end

--更新时间
function OB_Pad_Update_Time()
	if g_RoundOver == 1 then
		OB_Top_Timetext:Show()
		OB_Top_TimeStopWatch:Hide()
		OB_Top_TimeStopWatchIcon:Hide()
		OB_Top_Timetext:SetText("#{SJYH_210426_09}")
		
	else
		OB_Top_Timetext:Hide()
		OB_Top_TimeStopWatch:Show()
		OB_Top_TimeStopWatchIcon:Show()
		
		local remainTime = 0
	
		local matchType = DataPool:LuaFnGetGMMathcType()
		if matchType == 1 then
			remainTime = SJTX:LuaFnGetSJTXSceneRemainTime()
		elseif matchType == 2 then
			remainTime = DFS:LuaFnGetDfsSceneRemainTime()
		elseif matchType == 3 then
			remainTime = CorpsUI_2018:GetCorpsPK_LeftTimes()
		elseif matchType == 4 then
			remainTime = ZBS:GetRemainTime()
		end
	
		OB_Top_TimeStopWatch:SetProperty("Timer", remainTime)
	end
end


--打开数据统计界面
function OB_Pad_OpenData_Click()
	PushEvent("OPEN_GMVISIBLE_DATA")
end

--更新头顶信息
function OB_Pad_Update_CreatureBoard()
	
	if g_bShowTitle == 1 then
		OB_Right_TitleShow : Hide()
		OB_Right_HPShow : Show()
		
	else
		OB_Right_TitleShow : Show()
		OB_Right_HPShow : Hide()
	end
	
	if g_bShowTitle == 1 then
		OB_Pad_ShowTitle( 1 )
		OB_Pad_ShowHp( 0 )
	else
		OB_Pad_ShowTitle( 0 )
		OB_Pad_ShowHp( 1 )
	end
end


--显示心情或称号
function OB_Pad_ShowTitle_Click()
	if g_RoundOver == 1 then
		PushDebugMessage("本局比赛已结束")
		return
	end
	
	g_bShowTitle = 1
	OB_Pad_Update_CreatureBoard()
end


--显示血条
function OB_Pad_ShowHp_Click()
	if g_RoundOver == 1 then
		PushDebugMessage("本局比赛已结束")
		return
	end
	
	g_bShowTitle = 0	
	OB_Pad_Update_CreatureBoard()
end

function OB_Pad_ShowTitle( bShow )	
	DataPool:LuaShowObjTitle(bShow)
end


function OB_Pad_ShowHp( bShow )	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		OB_Pad_Show_SJTX_Hp( bShow )
	elseif matchType == 2 then
		OB_Pad_Show_DFS_Hp( bShow )
	elseif matchType == 3 then
		OB_Pad_Show_ZBS_Hp( bShow )
	elseif matchType == 4 then
		OB_Pad_Show_ZBS2023_Hp( bShow )
	end
end

function OB_Pad_Show_SJTX_Hp( bShow )	
	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamA, i - 1 )	
		if guid ~= "" then
			local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamA, i - 1 )
			
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamA)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamA)
		end
	end
	
	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamB, i - 1 )	
		if guid ~= "" then
			local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamB, i - 1 )
			
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamB)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamB)
		end
	end
end

function OB_Pad_Show_DFS_Hp( bShow )	
	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamA, i - 1 )	
		if guid ~= "" then
			local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamA, i - 1 )
			
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamA)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamA)
		end
	end
	
	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamB, i - 1 )	
		if guid ~= "" then
			local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamB, i - 1 )
			
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamB)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamB)
		end
	end
end

function OB_Pad_Show_ZBS_Hp( bShow )
	for i=1, g_MaxTeamMember do
		local guid, hp, level, nMenPai,nPos,szName,nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i - 1)
		if guid ~= nil and guid ~= "" then
			
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamA)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamA)
		end
	end
	
	for i=1, g_MaxTeamMember do
		local guid, hp, level, nMenPai,nPos,szName,nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(g_MaxTeamMember + i - 1)
		if guid ~= nil and guid ~= "" then
			
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamB)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamB)
		end
	end
end

function OB_Pad_Show_ZBS2023_Hp( bShow )
	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(i-1)
		local hp = ZBS:GetBattleMemberVisiableInfo(i-1, "HP")
		if hp >= 0 and guid ~= nil and guid ~= "" then
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamA)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamA)
		end
	end
	
	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(g_MaxTeamMember+i-1)
		local hp = ZBS:GetBattleMemberVisiableInfo(g_MaxTeamMember + i - 1, "HP")
		if hp >= 0 and guid ~= nil and guid ~= "" then
			Lua_SetSpecialObjHp(guid, hp, 100, g_TeamB)
			Lua_ShowSpecialObjHp(guid, bShow, g_TeamB)
		end
	end
end

function OB_Pad_Update_Score()
	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 or matchType == 2 or matchType == 4 then
		local ajiFen, bjiFen = DataPool:LuaFnGetGMVisibleJiFen()
		local jifenText = ScriptGlobal_Format("#{SJYH_210426_07}", ajiFen, bjiFen) 
		OB_Top_Scoretext:SetText(jifenText)
		
	elseif matchType == 3 then
		--天下会武
		OB_Top_Scoretext:SetText("#{SJYH_210426_06}")
		
	end
	
end

--胜负信息
function OB_Pad_Update_JieSuan()
	OB_Top_TeamA_Win:Hide()
	OB_Top_TeamB_Win:Hide()

	local matchResult = -1
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		matchResult = SJTX:LuaFnGetSJTXSceneMatchResult()
	elseif matchType == 2 then
		matchResult = DFS:LuaFnGetDfsSceneMatchResult()
	elseif matchType == 3 then
		matchResult = CorpsUI_2018:GetCorpsPK_Result_Info()
	elseif matchType == 4 then
		matchResult = ZBS:GetBattleVisiableInfo("Result")
	end
	
	if matchResult == -1 then
		return
	end
	
	--胜负
	if matchResult == 1 then
		OB_Top_TeamA_Win:Show()
		
	elseif matchResult == 2 then
		OB_Top_TeamB_Win:Show()
		
	end
	
end


function OB_Left_6V6_Player_ShowTooltip(index, stateType)
end

function OB_Right_6V6_Player_ShowTooltip(index, stateType)
end

function OB_Pad_SelectTarget(teamIndex, memIndex)
	local szName = ""
	local matchType = DataPool:LuaFnGetGMMathcType()
	
	if matchType == 1 then
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(teamIndex, memIndex - 1 )
		szName = name
		
	elseif  matchType == 2 then
		local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(teamIndex, memIndex - 1 )
		szName = name
		
	elseif  matchType == 3 then
	
		if teamIndex == g_TeamA then
			local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(memIndex - 1)
			szName = name
		else
			local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(g_MaxTeamMember + memIndex - 1)
			szName = name
		end
	elseif matchType == 4 then
		local idx = g_MaxTeamMember*(teamIndex-1) + memIndex - 1
		szName = ZBS:GetBattleMemberVisiableInfo(idx, "Name")
	end
	
	if(nil ~= szName and "" ~= szName) then
		Target:SelectThePlayer(szName);
	end
end

function OB_Pad_CloseOtherWindow()
	if IsWindowShow("PayTopList") then
		CloseWindow("PayTopList", true)
	end
	if IsWindowShow("PayTopList_Anniu") then
		CloseWindow("PayTopList_Anniu", true)
	end
	if IsWindowShow("FangDaohao") then
		CloseWindow("FangDaohao", true)
	end
	if IsWindowShow("MsgButton_MenpaiBook") then
		CloseWindow("MsgButton_MenpaiBook", true)
	end
	if IsWindowShow("FreshmanWatch") then
		CloseWindow("FreshmanWatch", true)
	end
end

--关闭第一视角界面
function OB_FirstView_CloseWindow()
	OB_FirstView_Frame:Hide()
end

--显示第一视角界面
function OB_FirstView_OpenWindow()
	OB_FirstView_Frame:Show()
end

--关闭第一视角
function OB_FirstView_Cancel_Click()
	--关闭第一视角
	if LuaFnCameraVisualGetActive() == 1 then 
		--退出第一人称视角
		LuaFnCameraVisualSetActive(0)
	end	
	OB_FirstView_CloseWindow()
end

--点击开启第一视角
function OB_Pad_ChangeFirstView_Click(teamIndex, memIndex)
	local guid = ""
	local szName = ""
	local matchType = DataPool:LuaFnGetGMMathcType()
	
	if matchType == 4 then
		local idx = g_MaxTeamMember*(teamIndex-1) + memIndex - 1
		guid = ZBS:GetBattleMemberGuid(idx)
		szName = ZBS:GetBattleMemberVisiableInfo(idx, "Name")
	end
	
	if("" == szName or "" == guid) then
		return
	end

	--进入第一人称视角
	if LuaFnCameraVisualGetActive() == 1 then 
		--LuaFnCameraVisualResetTargetId(targetId)
		LuaFnCameraVisualResetTargetGUID(guid)
	else
		LuaFnCameraSetVisualInfo(2, "OB_Pad", nil, guid, {
			-- MIN_DISTANCE = 0.14,
			-- MAX_DISTANCE = 32.56,
			-- MIN_PITCH = -29,
			-- MAX_PITCH = 56,
			-- CURRENT_ZOOM = 0.8,
			-- CURRENT_PITCH = 23,
			-- CURRENT_DIRECTION = 1.28,
		})
		LuaFnCameraVisualSetActive(1)
	end

	local textShow = ScriptGlobal_Format("#{SJYH_250320_1}", szName) 
	OB_FirstView_Player_NameText:SetText(textShow)
end
--####################################
