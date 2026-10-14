--武意界面

local g_Martial_WuYi_Frame_UnifiedXPosition
local g_Martial_WuYi_Frame_UnifiedYPosition
--这个要和代码里的MAX_MARTIAL_ATTR_NUM 保持一致
local g_Martial_WuYi_Max_Martial_Attr_Num = 15
--这个要和代码里的MAX_MARTIAL_MONSTER_NUM 保持一致
local g_Martial_WuYi_Max_Monster_Num = 3000
--这个要和代码里的MAX_MARTIAL_MONSTER_NUM 保持一致
local g_Martial_WuYi_Max_MultiMonster_Num = 3000
local g_Martial_WuYi_ShuXingArray  = {}
-- local g_Martial_WuYi_ShuXingJingTong = {}
--武意接口脚本
local g_Martial_WuYi_ScriptId = 507010
--天赋接口脚本
local g_Martial_WuYi_TalentScriptId = 507011
--当前分页id
local g_Martial_WuYi_CurFenYe = 0
--武意洗点道具ID
local g_Martial_WuYi_ReclyItemID = 38002046
local g_Martial_WuYi_ReclyItemID1 = 38002047
local g_Martial_WuYi_ReclyNeedMoney = 50000

local g_Martial_WuYi_JingTongMaxIndex = 3
local g_Martial_WuYi_JingTongText = {}
local g_Martial_WuYi_JingTongLevelText = {}

local g_Martial_WuYi_YuanbaoPay=1

--每个属性点增加的属性的值，以配置表为准(配置表以0开始，这里我们从1开始)
local g_Martial_WuYi_ShuXingLevelPoint = 
{
	[1] = 750,			--血上限	
	[2] = 10,           --冰攻击	
	[3] = 10,           --火攻击	
	[4] = 10,           --玄攻击	
	[5] = 10,           --毒攻击	
	[6] = 110,          --命中	
	[7] = 35,           --闪避	
	[8] = 13,           --穿刺伤害
	[9] = 13,           --穿刺减免
	[10] = 5,           --所有属性
	[11] = 100,         --外功攻击
	[12] = 100,         --内功攻击
}
--属性index对应的名字 以配置表为准
local g_Martial_WuYi_ShuXing2Name = 
{
	[1] = 		   "血上限",
	[2] =          "冰攻击",
	[3] =          "火攻击",
	[4] =          "玄攻击",
	[5] =          "毒攻击",
	[6] =          "命中",
	[7] =          "闪避",
	[8] =          "穿刺伤害",
	[9] =          "穿刺减免",
	[10] =         "所有属性",
	[11] =         "外功攻击",
	[12] =         "内功攻击",
}
local g_Martial_Rigth_ShuxingText = {}
-- local g_Martial_Rigth_ShuxingText1 = {}
-- local g_Martial_Rigth_ShuxingText2 = {}
--武意经验等级表
local g_Martial_WuYi_LevelExp = {}
local g_Martial_WuYi_LevelAttrPoint = {}
local g_Martial_WuYi_LevelTalentPoint = {}
local g_Martial_WuYi_LevelLimit = {}
local g_Martial_WuYi_ShuXingToolTips = {}

--武意天赋
local g_Martial_MaxTalentLayer = 5
--天赋ID最大值，读表
local g_Martial_MaxTalentID = 0
--天赋名字和描述，读表
local g_Martial_TalentId2Name = {}
local g_Martial_TalentId2Desc = {}
local g_Martial_TalenLayerNeedLevel = 
{
	-- [1] = 0,
	-- [2] = 0,
	-- [3] = 15,
	-- [4] = 25,
	-- [5] = 35,
}
local g_Martial_TalentLayerButtons = {}
local g_Martial_TalentSelectButtons = {}
--当前选中的天赋层
local g_Martial_TalentCurSelectLayer = 0
--当前天赋层选中的天赋
local g_Martial_TalentCurLayerSelectTalent = 0
--每层天赋数量
local g_Martial_LayerTalentNum = 3

local g_Martial_AllTalentInfoButtons = {}
local g_Martial_AllTalentInfoNameText = {}

local g_Martial_TalentButtons = {}

local g_Martial_AllTalentInfoOldLayer = 0
local g_Martial_AllTalentInfoOldTalent = 0

local g_Martial_TalentLayer2Name = 
{
	[1] = 		   "#{WYXT_20170906_264}",
	[2] =          "#{WYXT_20170906_265}",
	[3] =          "#{WYXT_20170906_266}",
	[4] =          "#{WYXT_20170906_267}",
	[5] =          "#{WYXT_20170906_268}",
}


local g_AllMartialExp = -1
local g_MartialMaxLevel = 150

local g_MartialFlashTips = {}
local g_Martial_CurFlash = 0

local g_Talent_Driving_SkillBegin = 3588
local g_Talent_Driving_SkillEnd = 3590

local g_Martial_Talent_Image = {}
local g_Martial_Talent_LayerIdButton = {}
local g_Martial_Talent_MaxLevel = 10

local g_Martial_Talent_Id2IamgesetName = 
{
	[1] = 		   "set:MartialWuYi03 image:poshi",
	[2] =          "set:MartialWuYi03 image:qianjun",
	[3] =          "set:MartialWuYi03 image:jingtang",
	[4] =          "set:MartialWuYi03 image:bubai",
	[5] =          "set:MartialWuYi03 image:bugui",
	[6] =          "set:MartialWuYi03 image:buqu",
	[7] =          "set:MartialWuYi03 image:xuesha",
	[8] =          "set:MartialWuYi03 image:duoming",
	[9] =          "set:MartialWuYi03 image:qinlue",
	[10] =          "set:MartialWuYi03 image:shouxin",
	[11] =          "set:MartialWuYi03 image:guiran",
	[12] =          "set:MartialWuYi03 image:tongming",
	[13] =          "set:MartialWuYi03 image:chenfeng",
	[14] =          "set:MartialWuYi03 image:shuangsheng",
	[15] =          "set:MartialWuYi03 image:beishui",
}
local g_Martial_TalentTitles = 
{
	[1] = 		   "#{WYXT_20170907_318}",
	[2] =          "#{WYXT_20170907_319}",
	[3] =          "#{WYXT_20170907_320}",
	[4] =          "#{WYXT_20170907_321}",
	[5] =          "#{WYXT_20170907_322}",
}

--删除480 凤鸣镇 增加 金陵及支线
local g_Martial_Talent_TalentReclyLimitScene = {
[0] = 0,
[1] = 0,
[2]	= 0,
[186] = 0,
[15335] = 0,
[15352] = 0,
[15369] = 0,
[15386] = 0,
[15403] = 0,
[15420] = 0,
[15437] = 0,
[15454] = 0,
[15471] = 0,
[15488] = 0,
[15505] = 0,
[15522] = 0,
[15539] = 0,
[15556] = 0,
[15573] = 0,
[15590] = 0,
[15607] = 0,
[15624] = 0,
[15641] = 0,
[15658] = 0,
[15675] = 0,
[15692] = 0,
[15709] = 0,
[15726] = 0,
[15743] = 0,
[15760] = 0,
[15777] = 0,
[15794] = 0,
[15811] = 0,
[15828] = 0,
[15845] = 0,
[15862] = 0,
[15879] = 0,
[15901] = 0,
[15918] = 0,
[15935] = 0,
[15952] = 0,
[15974] = 0,
[15991] = 0,
[16008] = 0,
[16025] = 0,
[16042] = 0,
[16064] = 0,
[16081] = 0,
[16098] = 0,
[16115] = 0,
[16132] = 0,
[16149] = 0,
[16166] = 0,
[16183] = 0,
}


local g_Martial_Talent_LearnFlag = {}
local g_Martial_Talent_AllInfoButtons = {}
local g_Martial_Talent_AllInfoSelectButton = 0

local g_Martial_AutoRecycleAttrFlag = false
local g_Martial_AutoRecycleAttrIndex = -1
local g_Martial_IgoneRecycleClick = false
local g_Martial_RecycleClickLimit = 1000
local g_Martial_LastRecycleClick = 0

local g_Martial_MartialZhaoHuiBeginDay = 20171120

-- 武意新手引导相关任务ID
local g_Martial_Guide_MissionIdfst = 1939
local g_Martial_Guide_MissionIdsec = 1941


--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_Martial_WuYi_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = "#{RWYQ_150707_01}"},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = "#{RWYQ_150707_02}"},
	[6] = {Text = "#{XL_XML_35}",				NeedCheck = 0, Tip = "#{RWYQ_150707_03}"},
	[7] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = "#{RWYQ_150707_04}"},
	[8] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = "#{RWYQ_150707_05}"},
	[9] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_06}"},
	[10] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = "#{RWYQ_150707_07}"},
	[11] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_08}"},
	[12] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = "#{ZZZB_150811_114}"},
	[13] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = "#{WYXT_20170907_302}"},
	[14] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = "#{JXSQ_170829_217}"},
	[15] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = "#{NJBZ_220816_12}"},
	[16] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = "#{CPSJ_260112_2}"},
	[17] = {Text = "#{INTERFACE_XML_496}",		NeedCheck = 0, Tip = ""},
}

local g_Martial_WuYi_PageButton = {}
local g_Martial_WuYi_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

--===============================================
-- OnLoad()
--===============================================
function Martial_WuYi_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("MARTIAL_SHOWWUYI")
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_UPDATE_EXP",false)
	this:RegisterEvent("MARTIAIL_TALENT_UPDATE",false)
	this:RegisterEvent("MARTAIL_LEVEL_UP")
	this:RegisterEvent("MARTAIL_ATTR_LEVELUP")
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK")
	this:RegisterEvent("FINISH_MISSION")
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	--this:RegisterEvent("NEW_MISSION")
	this:RegisterEvent("UPDATE_MISSION_TRACK",false)
	this:RegisterEvent("UNIT_LEVEL",false)
	this:RegisterEvent("OPEN_WUYI_ZHAOHUI",true)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)

end

function Martial_WuYi_OnLoad()
	--每个index显示什么属性就以这里的初始化来决定
	g_Martial_WuYi_ShuXingArray[1] = Martial_WuYi_List1_shuxing_xue_Text
	g_Martial_WuYi_ShuXingArray[2] = Martial_WuYi_List1_shuxing_binggong_Text
	g_Martial_WuYi_ShuXingArray[3] = Martial_WuYi_List1_shuxing_huogong_Text
	g_Martial_WuYi_ShuXingArray[4] = Martial_WuYi_List1_shuxing_xuangong_Text
	g_Martial_WuYi_ShuXingArray[5] = Martial_WuYi_List1_shuxing_dugong_Text
	g_Martial_WuYi_ShuXingArray[6] = Martial_WuYi_List1_shuxing_mingzhong_Text
	g_Martial_WuYi_ShuXingArray[7] = Martial_WuYi_List1_shuxing_shanbi_Text
	g_Martial_WuYi_ShuXingArray[8] = Martial_WuYi_List1_shuxing_chuancishanghai_Text
	g_Martial_WuYi_ShuXingArray[9] = Martial_WuYi_List1_shuxing_chuancijianmian_Text

	
	g_Martial_Rigth_ShuxingText[1] = Martial_WuYi_List2_shuju_1_1
	g_Martial_Rigth_ShuxingText[2] = Martial_WuYi_List2_shuju_2_1
	g_Martial_Rigth_ShuxingText[3] = Martial_WuYi_List2_shuju_3_1
	g_Martial_Rigth_ShuxingText[4] = Martial_WuYi_List2_shuju_4_1
	g_Martial_Rigth_ShuxingText[5] = Martial_WuYi_List2_shuju_5_1
	g_Martial_Rigth_ShuxingText[6] = Martial_WuYi_List2_shuju_6_1
	g_Martial_Rigth_ShuxingText[7] = Martial_WuYi_List2_shuju_7_1
	g_Martial_Rigth_ShuxingText[8] = Martial_WuYi_List2_shuju_8_1
	g_Martial_Rigth_ShuxingText[9] = Martial_WuYi_List2_shuju_9_1
	
	-- g_Martial_Rigth_ShuxingText1[1] = Martial_WuYi_List2_shuju_1_2
	-- g_Martial_Rigth_ShuxingText1[2] = Martial_WuYi_List2_shuju_2_2
	-- g_Martial_Rigth_ShuxingText1[3] = Martial_WuYi_List2_shuju_3_2
	-- g_Martial_Rigth_ShuxingText1[4] = Martial_WuYi_List2_shuju_4_2
	-- g_Martial_Rigth_ShuxingText1[5] = Martial_WuYi_List2_shuju_5_2
	-- g_Martial_Rigth_ShuxingText1[6] = Martial_WuYi_List2_shuju_6_2
	-- g_Martial_Rigth_ShuxingText1[7] = Martial_WuYi_List2_shuju_7_2
	-- g_Martial_Rigth_ShuxingText1[8] = Martial_WuYi_List2_shuju_8_2
	-- g_Martial_Rigth_ShuxingText1[9] = Martial_WuYi_List2_shuju_9_2
	
	-- g_Martial_Rigth_ShuxingText2[1] = Martial_WuYi_List2_shuju_1_2
	-- g_Martial_Rigth_ShuxingText2[2] = Martial_WuYi_List2_shuju_2_2
	-- g_Martial_Rigth_ShuxingText2[3] = Martial_WuYi_List2_shuju_3_2
	-- g_Martial_Rigth_ShuxingText2[4] = Martial_WuYi_List2_shuju_4_2
	-- g_Martial_Rigth_ShuxingText2[5] = Martial_WuYi_List2_shuju_5_2
	-- g_Martial_Rigth_ShuxingText2[6] = Martial_WuYi_List2_shuju_6_2
	-- g_Martial_Rigth_ShuxingText2[7] = Martial_WuYi_List2_shuju_7_2
	-- g_Martial_Rigth_ShuxingText2[8] = Martial_WuYi_List2_shuju_8_2
	-- g_Martial_Rigth_ShuxingText2[9] = Martial_WuYi_List2_shuju_9_2

	
	g_Martial_TalentLayerButtons[1] = 
	{
		btn   			= Martial_WuYi2_Frame_Part_List1_Button1,
		text  			= Martial_WuYi2_Frame_Part_List1_Button1_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Button1_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Button1_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock6,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui6,
	}
	g_Martial_TalentLayerButtons[2] = 
	{
		btn   			= Martial_WuYi2_Frame_Part_List1_Button2,
		text  			= Martial_WuYi2_Frame_Part_List1_Button2_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Button2_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Button2_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock7,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui7,
	}
	g_Martial_TalentLayerButtons[3] = 
	{
		btn   			= Martial_WuYi2_Frame_Part_List1_Button3,
		text  			= Martial_WuYi2_Frame_Part_List1_Button3_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Button3_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Button3_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock8,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui8,
	}
	g_Martial_TalentLayerButtons[4] = 
	{
		btn   			= Martial_WuYi2_Frame_Part_List1_Button4,
		text  			= Martial_WuYi2_Frame_Part_List1_Button4_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Button4_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Button4_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock9,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui9,
	}
	g_Martial_TalentLayerButtons[5] = 
	{
		btn   			= Martial_WuYi2_Frame_Part_List1_Button5,
		text  			= Martial_WuYi2_Frame_Part_List1_Button5_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Button5_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Button5_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock10,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui10,
	}
	g_Martial_TalentSelectButtons[1] =
	{
		btn 			= Martial_WuYi2_Frame_Part_List1_Selected_Button1,
		text 			= Martial_WuYi2_Frame_Part_List1_Selected_Button1_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Selected_Button1_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Selected_Button1_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock1,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui1,
	}
	g_Martial_TalentSelectButtons[2] =
	{
		btn 			= Martial_WuYi2_Frame_Part_List1_Selected_Button2,
		text 			= Martial_WuYi2_Frame_Part_List1_Selected_Button2_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Selected_Button2_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Selected_Button2_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock2,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui2,
	}
	g_Martial_TalentSelectButtons[3] =
	{
		btn 			= Martial_WuYi2_Frame_Part_List1_Selected_Button3,
		text 			= Martial_WuYi2_Frame_Part_List1_Selected_Button3_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Selected_Button3_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Selected_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock3,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui3,
	}
	g_Martial_TalentSelectButtons[4] =
	{
		btn 			= Martial_WuYi2_Frame_Part_List1_Selected_Button4,
		text 			= Martial_WuYi2_Frame_Part_List1_Selected_Button4_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Selected_Button4_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Selected_Button4_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock4,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui4,
	}
	g_Martial_TalentSelectButtons[5] =
	{
		btn 			= Martial_WuYi2_Frame_Part_List1_Selected_Button5,
		text 			= Martial_WuYi2_Frame_Part_List1_Selected_Button5_Text2,
		--level 			= Martial_WuYi2_Frame_Part_List1_Selected_Button5_Text3,
		talentPonint 	= Martial_WuYi2_Frame_Part_List1_Selected_Button5_Text4,
		lock = Martial_WuYi2_Frame_Part_List1_Lock5,
		lockhui = Martial_WuYi2_Frame_Part_List1_LockHui5,
	}
	g_Martial_AllTalentInfoButtons = 
	{
		[1] = Martial_WuYi2_Frame_Part_List2_2_Buttons1_1,
		[2] = Martial_WuYi2_Frame_Part_List2_2_Buttons1_2,
		[3] = Martial_WuYi2_Frame_Part_List2_2_Buttons1_3,
		[4] = Martial_WuYi2_Frame_Part_List2_2_Buttons2_1,
		[5] = Martial_WuYi2_Frame_Part_List2_2_Buttons2_2,
		[6] = Martial_WuYi2_Frame_Part_List2_2_Buttons2_3,
		[7] = Martial_WuYi2_Frame_Part_List2_2_Buttons3_1,
		[8] = Martial_WuYi2_Frame_Part_List2_2_Buttons3_2,
		[9] = Martial_WuYi2_Frame_Part_List2_2_Buttons3_3,
		[10] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_1,
		[11] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_2,
		[12] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_3,
		[13] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_1,
		[14] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_2,
		[15] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_3,
	}
	g_Martial_AllTalentInfoNameText = 
	{
		[1] = Martial_WuYi2_Frame_Part_List2_2_Buttons1_1_Text,
		[2] = Martial_WuYi2_Frame_Part_List2_2_Buttons1_2_Text,
		[3] = Martial_WuYi2_Frame_Part_List2_2_Buttons1_3_Text,
		[4] = Martial_WuYi2_Frame_Part_List2_2_Buttons2_1_Text,
		[5] = Martial_WuYi2_Frame_Part_List2_2_Buttons2_2_Text,
		[6] = Martial_WuYi2_Frame_Part_List2_2_Buttons2_3_Text,
		[7] = Martial_WuYi2_Frame_Part_List2_2_Buttons3_1_Text,
		[8] = Martial_WuYi2_Frame_Part_List2_2_Buttons3_2_Text,
		[9] = Martial_WuYi2_Frame_Part_List2_2_Buttons3_3_Text,
		[10] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_1_Text,
		[11] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_2_Text,
		[12] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_3_Text,
		[13] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_1_Text,
		[14] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_2_Text,
		[15] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_3_Text,
		
	}
	g_Martial_TalentButtons = 
	{
		[1] = {
			win = Martial_WuYi2_Frame_Part_List2_1_Top_Level1_1,
			btntext = Martial_WuYi2_Frame_Part_List2_1_Top_Level1_Text1,
			selectText = Martial_WuYi2_Frame_Part_List2_1_Top_Level2_Text1,
			selectWin = Martial_WuYi2_Frame_Part_List2_1_Top_Level2_1,
			levelText = Martial_WuYi2_Frame_Part_List2_1_level1,
		},
		[2] = {
			win = Martial_WuYi2_Frame_Part_List2_1_Top_Level1_2,
			btntext = Martial_WuYi2_Frame_Part_List2_1_Top_Level1_Text2,
			selectText = Martial_WuYi2_Frame_Part_List2_1_Top_Level2_Text2,
			selectWin = Martial_WuYi2_Frame_Part_List2_1_Top_Level2_2,
			levelText = Martial_WuYi2_Frame_Part_List2_1_level2,
		},
		[3] = {
			win = Martial_WuYi2_Frame_Part_List2_1_Top_Level1_3,
			btntext = Martial_WuYi2_Frame_Part_List2_1_Top_Level1_Text3,
			selectText = Martial_WuYi2_Frame_Part_List2_1_Top_Level2_Text3,
			selectWin = Martial_WuYi2_Frame_Part_List2_1_Top_Level2_3,
			levelText = Martial_WuYi2_Frame_Part_List2_1_level3,
			
		},
	}
	-- g_Martial_WuYi_ShuXingJingTong = 
	-- {
		-- [1] = {Martial_WuYi_List1_shuxing_xue_jing},
		-- [2] = {Martial_WuYi_List1_shuxing_binggong_jing},
		-- [3] = {Martial_WuYi_List1_shuxing_huogong_jing},
		-- [4] = {Martial_WuYi_List1_shuxing_xuangong_jing},
		-- [5] = {Martial_WuYi_List1_shuxing_dugong_jing},
		-- [6] = {Martial_WuYi_List1_shuxing_mingzhong_jing},
		-- [7] = {Martial_WuYi_List1_shuxing_shanbi_jing},
		-- [8] = {Martial_WuYi_List1_shuxing_chuancishanghai_jing},
		-- [9] = {Martial_WuYi_List1_shuxing_chuancijianmian_jing},
	-- }
	-- g_Martial_WuYi_JingTongText = 
	-- {
		-- [1] = Martial_WuYi_List2_shuju_10,
		-- [2] = Martial_WuYi_List2_shuju_11,
		-- [3] = Martial_WuYi_List2_shuju_12,
	-- }
	-- g_Martial_WuYi_JingTongLevelText = 
	-- {
		-- [1] = Martial_WuYi_List2_shuju_10_1,
		-- [2] = Martial_WuYi_List2_shuju_11_1,
		-- [3] = Martial_WuYi_List2_shuju_12_1,
	-- }
	g_MartialFlashTips = 
	{
		[1] = {Martial_WuYi_List1_shuxing_xue_Animate},
		[2] = {Martial_WuYi_List1_shuxing_binggong_Animate},
		[3] = {Martial_WuYi_List1_shuxing_huogong_Animate},
		[4] = {Martial_WuYi_List1_shuxing_xuangong_Animate},
		[5] = {Martial_WuYi_List1_shuxing_dugong_Animate},
		[6] = {Martial_WuYi_List1_shuxing_mingzhong_Animate},
		[7] = {Martial_WuYi_List1_shuxing_shanbi_Animate},
		[8] = {Martial_WuYi_List1_shuxing_chuancishanghai_Animate},
		[9] = {Martial_WuYi_List1_shuxing_chuancijianmian_Animate},
	}
	g_Martial_Talent_Image = 
	{
		[1] = {Martial_WuYi2_Frame_Part_List2_1_Top_Level2_Image1,Martial_WuYi2_Frame_Part_List2_1_Top_Level1_Image1,Martial_WuYi2_Frame_Part_List2_1_Top_SkillImage1},
		[2] = {Martial_WuYi2_Frame_Part_List2_1_Top_Level2_Image2,Martial_WuYi2_Frame_Part_List2_1_Top_Level1_Image2,Martial_WuYi2_Frame_Part_List2_1_Top_SkillImage2},
		[3] = {Martial_WuYi2_Frame_Part_List2_1_Top_Level2_Image3,Martial_WuYi2_Frame_Part_List2_1_Top_Level1_Image3,Martial_WuYi2_Frame_Part_List2_1_Top_SkillImage3},
	}
	 
	g_Martial_WuYi_ShuXingToolTips[1] = Martial_WuYi_List1_shuxing_xue_bk
	g_Martial_WuYi_ShuXingToolTips[2] = Martial_WuYi_List1_shuxing_binggong_bk
	g_Martial_WuYi_ShuXingToolTips[3] = Martial_WuYi_List1_shuxing_huogong_bk
	g_Martial_WuYi_ShuXingToolTips[4] = Martial_WuYi_List1_shuxing_xuangong_bk
	g_Martial_WuYi_ShuXingToolTips[5] = Martial_WuYi_List1_shuxing_dugong_bk
	g_Martial_WuYi_ShuXingToolTips[6] = Martial_WuYi_List1_shuxing_mingzhong_bk
	g_Martial_WuYi_ShuXingToolTips[7] = Martial_WuYi_List1_shuxing_shanbi_bk
	g_Martial_WuYi_ShuXingToolTips[8] = Martial_WuYi_List1_shuxing_chuancishanghai_bk
	g_Martial_WuYi_ShuXingToolTips[9] = Martial_WuYi_List1_shuxing_chuancijianmian_bk
	
	g_Martial_Talent_LearnFlag[1]  = Martial_WuYi2_Frame_Part_List2_2_Buttons1_bk1
	g_Martial_Talent_LearnFlag[2]  = Martial_WuYi2_Frame_Part_List2_2_Buttons1_bk2
	g_Martial_Talent_LearnFlag[3]  = Martial_WuYi2_Frame_Part_List2_2_Buttons1_bk3
	g_Martial_Talent_LearnFlag[4]  = Martial_WuYi2_Frame_Part_List2_2_Buttons2_bk1
	g_Martial_Talent_LearnFlag[5]  = Martial_WuYi2_Frame_Part_List2_2_Buttons2_bk2
	g_Martial_Talent_LearnFlag[6]  = Martial_WuYi2_Frame_Part_List2_2_Buttons2_bk3
	g_Martial_Talent_LearnFlag[7]  = Martial_WuYi2_Frame_Part_List2_2_Buttons3_bk1
	g_Martial_Talent_LearnFlag[8]  = Martial_WuYi2_Frame_Part_List2_2_Buttons3_bk2
	g_Martial_Talent_LearnFlag[9]  = Martial_WuYi2_Frame_Part_List2_2_Buttons3_bk3
	g_Martial_Talent_LearnFlag[10] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_bk1
	g_Martial_Talent_LearnFlag[11] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_bk2
	g_Martial_Talent_LearnFlag[12] = Martial_WuYi2_Frame_Part_List2_2_Buttons4_bk3
	g_Martial_Talent_LearnFlag[13] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_bk1
	g_Martial_Talent_LearnFlag[14] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_bk2
	g_Martial_Talent_LearnFlag[15] = Martial_WuYi2_Frame_Part_List2_2_Buttons5_bk3
	
	g_Martial_Talent_AllInfoButtons[1]  = Martial_WuYi2_Frame_Part_List2_2_Button1
	g_Martial_Talent_AllInfoButtons[2]  = Martial_WuYi2_Frame_Part_List2_2_Button2
	g_Martial_Talent_AllInfoButtons[3]  = Martial_WuYi2_Frame_Part_List2_2_Button3
	g_Martial_Talent_AllInfoButtons[4]  = Martial_WuYi2_Frame_Part_List2_2_Button4
	g_Martial_Talent_AllInfoButtons[5]  = Martial_WuYi2_Frame_Part_List2_2_Button5
	g_Martial_Talent_AllInfoButtons[6]  = Martial_WuYi2_Frame_Part_List2_2_Button6
	g_Martial_Talent_AllInfoButtons[7]  = Martial_WuYi2_Frame_Part_List2_2_Button7
	g_Martial_Talent_AllInfoButtons[8]  = Martial_WuYi2_Frame_Part_List2_2_Button8
	g_Martial_Talent_AllInfoButtons[9]  = Martial_WuYi2_Frame_Part_List2_2_Button9
	g_Martial_Talent_AllInfoButtons[10] = Martial_WuYi2_Frame_Part_List2_2_Button10
	g_Martial_Talent_AllInfoButtons[11] = Martial_WuYi2_Frame_Part_List2_2_Button11
	g_Martial_Talent_AllInfoButtons[12] = Martial_WuYi2_Frame_Part_List2_2_Button12
	g_Martial_Talent_AllInfoButtons[13] = Martial_WuYi2_Frame_Part_List2_2_Button13
	g_Martial_Talent_AllInfoButtons[14] = Martial_WuYi2_Frame_Part_List2_2_Button14
	g_Martial_Talent_AllInfoButtons[15] = Martial_WuYi2_Frame_Part_List2_2_Button15
	
	Martial_WuYi_List1_shuxing_jiadian_ButtonAnimate:Hide()
	Martial_WuYi2_Frame_Part_List2_1_Explain_Button2Animate:Hide()
	-- 保存界面的默认相对位置
	g_Martial_WuYi_Frame_UnifiedXPosition	= Martial_WuYi_Frame : GetProperty("UnifiedXPosition");
	g_Martial_WuYi_Frame_UnifiedYPosition	= Martial_WuYi_Frame : GetProperty("UnifiedYPosition");
	--默认选中二次确认
	Martial_WuYi_Top_xidianqueren:SetCheck(1)
	Martial_WuYi_Top_yuanbaoqueren:SetCheck(g_Martial_WuYi_YuanbaoPay)
	
	Maritial_WuYi_LoadWuYiAttrInfo()
	Maritial_WuYi_LoadWuYiLevelInfo()
	Martial_WuYi_LoadTalentInfo()
	Maritial_WuYi_InitAllTalentInfo()
	Maritial_WuYi_LoadTalentDescInfo()
	Martial_WuYi_CleanAllFalsh()
	
	g_Martial_WuYi_PageButton[1] = Martial_WuYi_SelfEquip
	g_Martial_WuYi_PageButton[2] = Martial_WuYi_SelfData
	g_Martial_WuYi_PageButton[3] = Martial_WuYi_Pet
	g_Martial_WuYi_PageButton[4] = Martial_WuYi_Infant
	g_Martial_WuYi_PageButton[5] = Martial_WuYi_Wuhun
	g_Martial_WuYi_PageButton[6] = Martial_WuYi_Xiulian
	g_Martial_WuYi_PageButton[7] = Martial_WuYi_Miji
	g_Martial_WuYi_PageButton[8] = Martial_WuYi_ZhenYuan
	g_Martial_WuYi_PageButton[9] = Martial_WuYi_JingMai
	g_Martial_WuYi_PageButton[10] = Martial_WuYi_ShenDing
	g_Martial_WuYi_PageButton[11] = Martial_WuYi_JunXian
	g_Martial_WuYi_PageButton[12] = Martial_WuYi_BaoJian
	g_Martial_WuYi_PageButton[13] = Martial_WuYi_WuYi
	g_Martial_WuYi_PageButton[14] = Martial_WuYi_ShenQi
	g_Martial_WuYi_PageButton[15] = Martial_WuYi_Armor
	g_Martial_WuYi_PageButton[16] = Martial_WuYi_CangPin
	g_Martial_WuYi_PageButton[17] = Martial_WuYi_OtherInfo
	
	g_Martial_WuYi_PageMask[1] = Martial_WuYi_SelfEquip_tips
	g_Martial_WuYi_PageMask[2] = Martial_WuYi_SelfData_tips
	g_Martial_WuYi_PageMask[3] = Martial_WuYi_Pet_tips
	g_Martial_WuYi_PageMask[4] = Martial_WuYi_Infant_tips
	g_Martial_WuYi_PageMask[5] = Martial_WuYi_Wuhun_tips
	g_Martial_WuYi_PageMask[6] = Martial_WuYi_Xiulian_tips
	g_Martial_WuYi_PageMask[7] = Martial_WuYi_Miji_tips
	g_Martial_WuYi_PageMask[8] = Martial_WuYi_ZhenYuan_tips
	g_Martial_WuYi_PageMask[9] = Martial_WuYi_JingMai_tips
	g_Martial_WuYi_PageMask[10] = Martial_WuYi_ShenDing_tips
	g_Martial_WuYi_PageMask[11] = Martial_WuYi_JunXian_tips
	g_Martial_WuYi_PageMask[12] = Martial_WuYi_BaoJian_tips
	g_Martial_WuYi_PageMask[13] = Martial_WuYi_WuYi_tips
	g_Martial_WuYi_PageMask[14] = Martial_WuYi_ShenQi_tips
	g_Martial_WuYi_PageMask[15] = Martial_WuYi_Armor_tips
	g_Martial_WuYi_PageMask[16] = Martial_WuYi_CangPin_tips
	g_Martial_WuYi_PageMask[17] = Martial_WuYi_OtherInfo_tips
	
	g_PageButtonTipsPos[1] = "{0.000000,28.000000}" 
	g_PageButtonTipsPos[2] = "{0.000000,64.000000}" 
	g_PageButtonTipsPos[3] = "{0.000000,100.000000}"
	g_PageButtonTipsPos[4] = "{0.000000,136.000000}"
	g_PageButtonTipsPos[5] = "{0.000000,172.000000}"
	g_PageButtonTipsPos[6] = "{0.000000,208.000000}"
	g_PageButtonTipsPos[7] = "{0.000000,244.000000}"
	g_PageButtonTipsPos[8] = "{0.000000,280.000000}"
	g_PageButtonTipsPos[9] = "{0.000000,316.000000}" 
	g_PageButtonTipsPos[10] = "{0.000000,352.000000}" 
	g_PageButtonTipsPos[11] = "{0.000000,388.000000}" 
	g_PageButtonTipsPos[12] = "{0.000000,424.000000}" 
	g_PageButtonTipsPos[13] = "{0.000000,460.000000}" 
	g_PageButtonTipsPos[14] = "{0.000000,496.000000}"
	g_PageButtonTipsPos[15] = "{0.000000,532.000000}"
	g_PageButtonTipsPos[16] = "{0.000000,568.000000}"
	g_PageButtonTipsPos[17] = "{0.000000,604.000000}"
	
end
--===============================================
-- OnEvent()
--===============================================
function Martial_WuYi_OnEvent(event)
	if(event == "MARTIAL_SHOWWUYI") then	
		--开界面重置一些数据
		Marial_WuYi_ClearAll()
		MaritialSys:SetLastDayMonsterTip(0)
		PushEvent("MARTIAL_HIDE_ZHAOHUI_TIP")
		Martial_WuYi_SwitchPage(1)
		Maritial_WuYi_SaveUnifiedPosion()
	elseif(event == "MARTIAL_UPDATE" or event == "UNIT_LEVEL") then
		if(g_AllMartialExp == -1) then
			g_AllMartialExp = MaritialSys:GetMaritiaExp()
		end
		if(this:IsVisible() and g_Martial_WuYi_CurFenYe == 1) then
			Martial_WuYi_Refresh()
		end
	elseif(event == "MARTIAL_UPDATE_EXP") then
		--Marial_WuYi_OnAddExpForTip(tonumber(arg0),tonumber(arg1))
		if(this:IsVisible() and g_Martial_WuYi_CurFenYe == 1) then
			Martial_WuYi_RefreshExp()
			Martial_WuYi_RefreshUI()
		end
	elseif(event == "MARTAIL_LEVEL_UP") then
		local nOld = tonumber(arg0)
		local nNew = tonumber(arg1)
		for i=nOld + 1,nNew do
			local str = ScriptGlobal_Format("#{WYXT_20170811_102}",i)
			PushDebugMessage(str)
			if(g_Martial_WuYi_LevelAttrPoint[i] > 0) then
				
				PushDebugMessage(ScriptGlobal_Format("#{WYXT_20170811_103}",g_Martial_WuYi_LevelAttrPoint[i]))
			end
			if(g_Martial_WuYi_LevelTalentPoint[i] > 0) then
				PushDebugMessage(ScriptGlobal_Format("#{WYXT_20170811_104}",g_Martial_WuYi_LevelTalentPoint[i]))
			end
		end
		--升级的时候重置一次
		g_AllMartialExp = MaritialSys:GetMaritiaExp()
		if(this:IsVisible() and g_Martial_WuYi_CurFenYe == 1) then
			Martial_WuYi_RefreshUI()
			Martial_WuYi_RefreshExp()
		end
	elseif(event == "MARTIAIL_TALENT_UPDATE") then
		if(this:IsVisible() and g_Martial_WuYi_CurFenYe == 2) then
			Martial_WuYi_TalentRefresh()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Martial_WuYi_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Martial_WuYi_Frame_On_ResetPos()
	elseif ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		Martial_WuYi_Refresh_Page_Button(nLevel)
		Martial_WuYi_ShowPage()
	elseif (event == "UPDATE_MISSION_TRACK") then
		if(this:IsVisible()) then
			Marial_WuYi_ReFreshMissonGuild()
		end
	elseif(event == "PLAYER_ENTERING_WORLD") then
		Martial_WuYi_AskForMartialData()
		Martial_WuYi_Frame_OnHiden()
	elseif(event == "OPEN_WUYI_ZHAOHUI") then 
		Martial_WuYi_ZhaoHuiClick()
	elseif(event == "MARTAIL_ATTR_LEVELUP") then
		local nIndex = tonumber(arg0)
		Maritial_WuYi_OnAttrLevelup(nIndex)
		if(g_Martial_AutoRecycleAttrFlag == true and this:IsVisible() and g_Martial_WuYi_CurFenYe == 1) then
			SetTimer("Martial_WuYi","Maritial_WuYi_StartAutoRecycleAttr()",300)
		end
	-- elseif(event == "NEW_MISSION") then
		-- local missname = DataPool:GetPlayerMission_Name(tonumber( arg0 ))
		-- local bOpen = 0
		-- local OpenIndex = 0
		-- if(missname == "Mission:1867") then
			-- local misIndex = DataPool:GetPlayerMissionIndexByID(1867)
			-- if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
				-- bOpen = 1
				-- OpenIndex = 1
			-- end
		-- elseif (missname == "Mission:1868") then
			-- local misIndex = DataPool:GetPlayerMissionIndexByID(1868)
			-- if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
				-- bOpen = 1
				-- OpenIndex = 2
			-- end
		-- end
		-- if(bOpen == 1) then
			-- Marial_WuYi_ClearAll()
			-- Maritial_WuYi_SaveUnifiedPosion()
			-- Martial_WuYi_SwitchPage(OpenIndex)
		-- end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 20171024) then
		local npcid = Get_XParam_INT(0)
		local actid = Get_XParam_INT(1)
		local para1 = Get_XParam_INT(2)
		if(actid == 1 and (para1 == 1 or para1 == 2)) then --打开界面 
			Marial_WuYi_ClearAll()
			Maritial_WuYi_SaveUnifiedPosion()
			Martial_WuYi_SwitchPage(para1)
		end
	end
	
	if event == "UPDATE_TOY_TIP" then
		Martial_WuYi_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		Martial_WuYi_RefreshCangPinTip()
	end
end

function Marial_WuYi_ClearAll()
	g_Martial_WuYi_CurFenYe = 0
	Maritial_WuYi_CleanCurFlash()
	g_Martial_TalentCurSelectLayer = 0
	g_Martial_TalentCurLayerSelectTalent = 0
	g_Martial_Talent_AllInfoSelectButton = 0
	Martial_WuYi_StopAutoRecycleAttr()
	Maritial_WuYi_OnAttrLevelup()
end

function Maritial_WuYi_SaveUnifiedPosion()
	local nUIPos = Variable:GetVariable( "SelfUnionPos" );
	Martial_WuYi_Frame:SetProperty( "UnifiedPosition", nUIPos );
	g_Martial_WuYi_Frame_UnifiedXPosition	= Martial_WuYi_Frame : GetProperty("UnifiedXPosition");
	g_Martial_WuYi_Frame_UnifiedYPosition	= Martial_WuYi_Frame : GetProperty("UnifiedYPosition");
end

--===============================================
-- OnHiden
--===============================================
function Martial_WuYi_Frame_OnHiden()
	Martial_WuYi_StopAutoRecycleAttr()
	if "Martial_WuYi" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Martial_WuYi_Frame_On_ResetPos()

	Martial_WuYi_Frame : SetProperty("UnifiedXPosition", g_Martial_WuYi_Frame_UnifiedXPosition);
	Martial_WuYi_Frame : SetProperty("UnifiedYPosition", g_Martial_WuYi_Frame_UnifiedYPosition);

end
function Martial_WuYi_OnMoved()
	if "Martial_WuYi" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
	return
end

function Martial_WuYi_SwitchPage(nIndex)
	
	Martial_WuYi_Frame_Part:Hide()
	Martial_WuYi2_Frame_Part:Hide()
	if(1 == nIndex) then --武意属性点
		Martial_WuYi_Refresh()
		Martial_WuYi_Frame_Part:Show()
		Martial_WuYi_FenYe1:SetCheck(1)
		Martial_WuYi_FenYe2:SetCheck(0)
		Martial_WuYi_FenYe1:SetText("#{WYXT_20170907_332}")
		Martial_WuYi_FenYe2:SetText("#{WYXT_20170803_24}")
		g_Martial_WuYi_CurFenYe = 1
		Martial_WuYi_FenYe2_tishi:Hide()
	elseif(2 == nIndex) then
		Martial_WuYi2_Frame_Part:Show()
		Martial_WuYi_FenYe1:SetCheck(0)
		Martial_WuYi_FenYe2:SetCheck(1)
		Martial_WuYi_FenYe1:SetText("#{WYXT_20170803_23}")
		Martial_WuYi_FenYe2:SetText("#{WYXT_20170907_333}")
		g_Martial_WuYi_CurFenYe = 2
		Martial_WuYi_FenYe2_tishi:Show()
		--默认选中第一个
		if(g_Martial_TalentCurSelectLayer == 0) then
			Maritial_WuYi_TalentFenYeSwitch(1)
		else
			Martial_WuYi_TalentRefresh()
		end
	end
	local nLevel =Player:GetLevel()
	Marial_WuYi_ReFreshMissonGuild()
	Martial_WuYi_Refresh_Page_Button(nLevel)
	Martial_WuYi_WuYi:SetCheck(1)
	Martial_WuYi_ShowPage()
	this:Show()
end

function Martial_WuYi_CloseFunction()
	Martial_WuYi_Frame_OnHiden()
end
--刷新武意界面
function Martial_WuYi_Refresh()
	
	Martial_WuYi_RefreshShuXingDian()
	Martial_WuYi_RefreshUI()
	Martial_WuYi_RefreshExp()
	Martial_WuYi_RefreshWuYiTip()
	-- Martial_WuYi_RefreshJingTong()
end
--加载武意属性配置
function Maritial_WuYi_LoadWuYiAttrInfo()
	local data = MaritialSys:GetMaritiaAttrInfo()
	if(data ~= nil) then
		g_Martial_WuYi_ShuXing2Name = {}
		g_Martial_WuYi_ShuXingLevelPoint = {}
	end
	for i,v in ipairs(data) do
		g_Martial_WuYi_ShuXing2Name[v[1] + 1] = v[2];
		g_Martial_WuYi_ShuXingLevelPoint[v[1] + 1] = v[3];
	end
end
--加载武意等级配置
function Maritial_WuYi_LoadWuYiLevelInfo()
	local data = MaritialSys:GetMartialLevelInfo()
	if(data ~= nil) then
		g_Martial_WuYi_LevelExp = {}
		g_Martial_TalenLayerNeedLevel = {}
		g_Martial_WuYi_LevelAttrPoint = {}
		g_Martial_WuYi_LevelTalentPoint = {}
		g_Martial_WuYi_LevelLimit = {}
	end
	for i,v in ipairs(data) do
		local nLayer = v[5]
		g_Martial_WuYi_LevelExp[v[1]] = v[2]
		g_Martial_WuYi_LevelAttrPoint[v[1]] = v[3]
		g_Martial_WuYi_LevelTalentPoint[v[1]] = v[4]
		g_Martial_WuYi_LevelLimit[v[1]] = v[6]
 		if(nLayer ~= 0 and (g_Martial_TalenLayerNeedLevel[nLayer] == nil or g_Martial_TalenLayerNeedLevel[nLayer] > v[1])) then
			g_Martial_TalenLayerNeedLevel[nLayer] = v[1]
		end
	end
end
--加载天赋配置
function Martial_WuYi_LoadTalentInfo()
	local data = MaritialSys:GetTalentInfo()
	if(data ~= nil) then
		g_Martial_TalentIdInfo = {}
	end
	for i,v in ipairs(data) do
		g_Martial_TalentId2Name[v[1]] = v[2]
		if(g_Martial_MaxTalentID < v[1] ) then
			g_Martial_MaxTalentID = v[1]
		end
	end
end
--加载天赋描述
function Maritial_WuYi_LoadTalentDescInfo()
	local data = MaritialSys:GetTalentDescInfo()
	if(data == nil) then
		return
	end
	g_Martial_TalentId2Desc = data
end

--刷新武意属性界面属性点显示
function Martial_WuYi_RefreshShuXingDian()
	local nNum,attrArray = MaritialSys:GetMaritiaAttrs();
	
	if(nNum < table.getn(g_Martial_WuYi_ShuXingArray) and attrArray ~= nil) then
		return
	end
	--刷新中间的属性点显示和右边的属性显示
	--Martial_WuYi_List2_shuju:RemoveAllItem()
	for i = 1,table.getn(g_Martial_WuYi_ShuXingArray) do
		local nAttrPoint = math.floor((attrArray[i] * g_Martial_WuYi_ShuXingLevelPoint[i]) / 10 )
		local nPersent = Martial_WuYi_CalcAdvancePersent(i - 1)
		-- local nPersentValue = math.ceil((nPersent * nAttrPoint) / 100)
		--local str = ScriptGlobal_Format("#{WYXT_20170803_39}",g_Martial_WuYi_ShuXing2Name[i],tostring(nAttrPoint + nPersentValue))
		local str1 = ScriptGlobal_Format("#{WYXT_20170907_336}",attrArray[i])
		local str1_1 = "#cfff263+"..nAttrPoint
		-- local str2 = ""
		-- local str3 = ""
		g_Martial_WuYi_ShuXingArray[i]:SetText(str1)
		 -- if(nPersentValue ~= 0) then
			 -- str2 = "#H(+"..nPersentValue..")"
		 -- end
		if(g_Martial_Rigth_ShuxingText[i] ~= nil) then
			g_Martial_Rigth_ShuxingText[i]:SetText(str1_1)
			-- g_Martial_Rigth_ShuxingText1[i]:SetText(str2)
			--g_Martial_Rigth_ShuxingText2[i]:SetText(str3)
		end
		if(g_Martial_WuYi_ShuXingToolTips[i] ~= nil) then
			g_Martial_WuYi_ShuXingToolTips[i]:SetToolTip(ScriptGlobal_Format("#{WYXT_20170907_360}",g_Martial_WuYi_ShuXing2Name[i],g_Martial_WuYi_ShuXing2Name[i],string.format("%0.1f",g_Martial_WuYi_ShuXingLevelPoint[i]/10)))
		end
	end
	local nLevel = MaritialSys:GetMaritiaLevel()
	Martial_WuYi_List2_part2_text:SetText(ScriptGlobal_Format("#{WYXT_20170803_30}",nLevel))
end
--刷新精通显示标志
-- function Martial_WuYi_RefreshJingTong()
	-- -- for i = 1, table.getn(g_Martial_WuYi_ShuXingJingTong) do
		-- -- g_Martial_WuYi_ShuXingJingTong[i][1]:Hide()
	-- -- end
	-- for i = 1, g_Martial_WuYi_JingTongMaxIndex do
		-- local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(i - 1)
		-- if(nLevel > 0) then
			-- --g_Martial_WuYi_ShuXingJingTong[nId + 1][1]:Show()

			-- local present = MaritialSys:GetMartialAdvancePersent(nId,nLevel - 1)
			-- local str = ScriptGlobal_Format("#{WYXT_20170907_305}",g_Martial_WuYi_ShuXing2Name[nId + 1],nLevel,present)
			-- g_Martial_WuYi_JingTongText[i]:SetText(str)
			-- --g_Martial_WuYi_JingTongLevelText[i]:SetText(str)
		-- else
			-- g_Martial_WuYi_JingTongText[i]:SetText("#{WYXT_20170811_200}")
			-- --g_Martial_WuYi_JingTongLevelText[i]:SetText("")
		-- end
	-- end
-- end
--刷新武意属性界面
function Martial_WuYi_RefreshUI()
	--显示今天的武意怪数
	local nWuYiMonsterNum = MaritialSys:GetMaritialTodayNum()
	local nMonsterNumText = ScriptGlobal_Format("#{WYXT_20170907_291}",tostring(nWuYiMonsterNum),tostring(g_Martial_WuYi_Max_Monster_Num))
	Martial_WuYi_List1_shuxingtiao1_shuju:SetText(nMonsterNumText)
	--显示今天的多倍武意怪数
	local nMultiWuYiMonsterNum = MaritialSys:GetMaritiaLTodayMultiNum()
	Martial_WuYi_List1_shuxingtiao2_jingyan_shuju:SetText(tostring(nMultiWuYiMonsterNum).."/"..tostring(g_Martial_WuYi_Max_MultiMonster_Num))
	--显示昨日剩余的武意怪数
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	Martial_WuYi_List1_shuxingtiao3_shuju:SetText(tostring(nMonsterNum).."/"..tostring(g_Martial_WuYi_Max_Monster_Num))
	
	--显示分配点数
	local nRemainPoint = MaritialSys:GetMaritiaRemainPoint()
	local nAlreadyPoint = MaritialSys:GetMaritiaAlreadyPoint()
	Martial_WuYi_Top_LingqiNumber_Text:SetText(ScriptGlobal_Format("#{WYXT_20170907_306}",nRemainPoint))
	--武意多倍冻结按钮
	local nState = MaritialSys:GetMaritiaFreezeState()
	local FreezeStr = "冻结"
	local FreezeTooltip = "#{WYXT_20170907_286}"
	if(nState == 1) then
		--显示解冻
		FreezeStr="解冻"
		FreezeTooltip = "#{WYXT_20170907_287}"
	end
	Martial_WuYi_List1_shuxingtiao2_Button:SetToolTip(FreezeTooltip)
	Martial_WuYi_List1_shuxingtiao2_Button:SetText(FreezeStr)
	--按钮显示逻辑
	
	--local bShowTip = MaritialSys:GetLastDayMonsterTip()
	
	if(nMonsterNum > 0 and nReward == 0 ) then
		Martial_WuYi_List1_shuxingtiao1_Buttontips:Show()
	else
		Martial_WuYi_List1_shuxingtiao1_Buttontips:Hide()
	end
	if(nReward == 0) then
		Martial_WuYi_List1_shuxingtiao1_Button:Enable()
		Martial_WuYi_List1_shuxingtiao1_Button:SetText("#{WYXT_20170907_394}")
	else
		Martial_WuYi_List1_shuxingtiao1_Button:Disable()
		Martial_WuYi_List1_shuxingtiao1_Button:SetText("#{WYXT_20170907_431}")
	end
end
--刷新武意属性界面经验显示
function Martial_WuYi_RefreshExp()
	local nMartialLevel = MaritialSys:GetMaritiaLevel()
	local nNeedExp = g_Martial_WuYi_LevelExp[g_MartialMaxLevel]
	local nCurExp = MaritialSys:GetMaritiaExp()
	local nNextAttrPoin = 0
	local nNextTalentPoint = 0
	if(g_Martial_WuYi_LevelExp[nMartialLevel + 1] ~= nil) then
		nNeedExp = g_Martial_WuYi_LevelExp[nMartialLevel + 1]
		nNextAttrPoin = g_Martial_WuYi_LevelAttrPoint[nMartialLevel + 1]
		nNextTalentPoint = g_Martial_WuYi_LevelTalentPoint[nMartialLevel + 1]
	end
	if(nMartialLevel == g_MartialMaxLevel) then
		nCurExp = g_Martial_WuYi_LevelExp[g_MartialMaxLevel]
		Martial_WuYi_List2_part2_textTips:SetText("#{WYXT_20170907_341}")
	else
		if(nNextTalentPoint > 0) then
			Martial_WuYi_List2_part2_textTips:SetText(ScriptGlobal_Format("#{WYXT_20170907_340}",tostring(nNextAttrPoin),tostring(nNextTalentPoint)))
		else
			Martial_WuYi_List2_part2_textTips:SetText(ScriptGlobal_Format("#{WYXT_20170907_339}",tostring(nNextAttrPoin)))
		end
	end 
	local StrMartialLevel = ScriptGlobal_Format("#{WYXT_20170803_30}",nMartialLevel)
	Martial_WuYi_List2_part2_text2:SetText("")
	if(nMartialLevel + 1 <=g_MartialMaxLevel and Player:GetLevel() < g_Martial_WuYi_LevelLimit[nMartialLevel + 1]) then
		Martial_WuYi_List2_part2_text2:SetText(ScriptGlobal_Format("#{WYXT_20170907_385}",g_Martial_WuYi_LevelLimit[nMartialLevel + 1]))
	end
	Martial_WuYi_List2_part2_text:SetText(StrMartialLevel)
	if(nMartialLevel == g_MartialMaxLevel) then
		Martial_WuYi_List2_part2_EXP2:SetProgress(nCurExp / nNeedExp, 1.0);
		Martial_WuYi_List2_part2_EXP:Hide()
		Martial_WuYi_List2_part2_EXP2:Show()
	else
		Martial_WuYi_List2_part2_EXP2:Hide()
		Martial_WuYi_List2_part2_EXP:Show()
		Martial_WuYi_List2_part2_EXP:SetProgress(nCurExp / nNeedExp, 1.0);
	end
	return
end

function Marial_WuYi_ShowExpTooltip()
	local nMartialLevel = MaritialSys:GetMaritiaLevel()
	local nNeedExp = g_Martial_WuYi_LevelExp[g_MartialMaxLevel]
	local nCurExp = MaritialSys:GetMaritiaExp()
	if(g_Martial_WuYi_LevelExp[nMartialLevel + 1] ~= nil) then
		nNeedExp = g_Martial_WuYi_LevelExp[nMartialLevel + 1]
	end
	local szExpTip = ""
	if(nMartialLevel == g_MartialMaxLevel) then
		nCurExp = g_Martial_WuYi_LevelExp[g_MartialMaxLevel]
		szExpTip = "#{WYXT_20170907_338}"
		Martial_WuYi_List2_part2_EXP2:SetToolTip(szExpTip)
	else
		szExpTip = ScriptGlobal_Format("#{WYXT_20170907_337}",nCurExp,nNeedExp)
		Martial_WuYi_List2_part2_EXP:SetToolTip(szExpTip)
	end
	
end

--天赋显示刷新
function Martial_WuYi_TalentRefresh()
	Martial_WuYi2_TalentRefreshButtons()
	Martial_WuYi_TalentRefreshLayer()
end


--刷新天赋层按钮显示
function Martial_WuYi2_TalentRefreshButtons()
	for i=1,g_Martial_MaxTalentLayer do
		local nNeedLevel = g_Martial_TalenLayerNeedLevel[i]
		local nMartialLevel = MaritialSys:GetMaritiaLevel()
		local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(i - 1)
		local levelDesc = ScriptGlobal_Format("#{WYXT_20170907_364}",nNeedLevel)
		local bOpen = 0
		--local strToolTips = ScriptGlobal_Format("#{WYXT_20170811_107}",nNeedLevel,g_Martial_TalentLayer2Name[i])
		local buttons = g_Martial_TalentLayerButtons
		g_Martial_TalentLayerButtons[i].btn:Hide()
		g_Martial_TalentSelectButtons[i].btn:Hide()
		if(nMartialLevel >= nNeedLevel) then
			bOpen = 1
		end
		if( i == g_Martial_TalentCurSelectLayer and bOpen == 1) then
			buttons = g_Martial_TalentSelectButtons
		end
		buttons[i].btn:Show()
		if( bOpen == 1 ) then
			if(g_Martial_TalentId2Name[nId] ~= nil and nLevel > 0) then
				levelDesc = "#cfff263"..g_Martial_TalentId2Name[nId]
				--strToolTips = ""
			else
				levelDesc = "#{WYXT_20170811_108}"
			end
		end
		buttons[i].lock:Show()
		buttons[i].lockhui:Hide()
		if(bOpen ~= 1) then
			--buttons[i].btn:SetProperty("Disabled", "True");
			buttons[i].btn:SetProperty("NormalImage","set:MartialWuYi01 image:WuYiButton1_Disable")
			buttons[i].btn:SetProperty("PushedImage","set:MartialWuYi02 image:WuYiButton1_PushedCheck")
			buttons[i].btn:SetProperty("HoverImage","set:MartialWuYi02  image:WuYiButton1_PushedHover")
			buttons[i].lock:Hide()
			buttons[i].lockhui:Show()
			if(i == g_Martial_TalentCurSelectLayer) then
				buttons[i].btn:SetCheck(1)
			else
				buttons[i].btn:SetCheck(0)
			end
		elseif(i ~= g_Martial_TalentCurSelectLayer) then
			--buttons[i].btn:SetProperty("Disabled", "False");
			buttons[i].btn:SetProperty("NormalImage","set:MartialWuYi01 image:WuYiButton1_Normal")
			buttons[i].btn:SetProperty("PushedImage","set:MartialWuYi01 image:WuYiButton1_Pushed")
			buttons[i].btn:SetProperty("HoverImage","set:MartialWuYi01 image:WuYiButton1_Hover")
		end
		buttons[i].text:SetText(levelDesc)
		--buttons[i].btn:SetToolTip(strToolTips)
		--buttons[i].level:SetText("#cfff263"..tostring(nNeedLevel))
		buttons[i].talentPonint:SetText("")
		local nLevelStr = ScriptGlobal_Format("#{WYXT_20170907_280}",nLevel)
		if(nLevel > 0 and g_Martial_TalentId2Name[nId] ~= nil) then
			buttons[i].talentPonint:SetText(nLevelStr)
			buttons[i].lock:Hide()
			buttons[i].lockhui:Hide()
		end
	end
end
--刷新天赋描述显示
function Martial_WuYi_TalentRefreshLayer()
	local nRemain = MaritialSys:GetTalentRemainPoint()
	Martial_WuYi2_Frame_Part_List3_Text:SetText(ScriptGlobal_Format("#{WYXT_20170803_68}",nRemain));
	
	local nId = (g_Martial_TalentCurSelectLayer - 1) * g_Martial_LayerTalentNum + 1
	if(nId <= 0 or nId > g_Martial_MaxTalentID - 2) then
		return 
	end
	
	local nLayerTalentId,nLevel = MaritialSys:GetTalentLevelBylayerID(g_Martial_TalentCurSelectLayer - 1)
	local bValidSeclect = 0
	if(g_Martial_TalentCurLayerSelectTalent > 0 and g_Martial_TalentCurLayerSelectTalent <= g_Martial_LayerTalentNum) then
		Martial_WuYi2_Frame_Part_List2_1_Explain_Title:SetText("#gFF0FA0"..g_Martial_TalentId2Name[nId + g_Martial_TalentCurLayerSelectTalent - 1])
		bValidSeclect = 1
	end
	for i = 1,g_Martial_LayerTalentNum do
		local ShowSelect = 0
		if(bValidSeclect == 1 and g_Martial_TalentCurLayerSelectTalent == i) then
			ShowSelect = 1
		end
		if(nLevel > 0 and nLayerTalentId == (nId + i - 1)) then
			g_Martial_TalentButtons[i].win:Hide()
			g_Martial_TalentButtons[i].selectWin:Show()
			g_Martial_TalentButtons[i].selectText:SetText("#cfff263"..g_Martial_TalentId2Name[nId + i - 1])
			g_Martial_TalentButtons[i].levelText:SetText("#G"..nLevel)
			g_Martial_TalentButtons[i].levelText:Show()
		else
			g_Martial_TalentButtons[i].win:Show()
			g_Martial_TalentButtons[i].selectWin:Hide()
			g_Martial_TalentButtons[i].levelText:Hide()
			g_Martial_TalentButtons[i].btntext:SetText("#cfff263"..g_Martial_TalentId2Name[nId + i - 1])
		end
		if(ShowSelect == 1) then
			g_Martial_Talent_Image[i][1]:SetCheck(1)
			g_Martial_Talent_Image[i][2]:SetCheck(1)
		else
			g_Martial_Talent_Image[i][1]:SetCheck(0)
			g_Martial_Talent_Image[i][2]:SetCheck(0)
		end
		local str = ScriptGlobal_Format("#{WYXT_20170811_109}",g_Martial_TalentId2Name[i + nId - 1])
		g_Martial_Talent_Image[i][2]:SetToolTip(str)
		g_Martial_Talent_Image[i][3]:SetProperty("Image",g_Martial_Talent_Id2IamgesetName[nId + i - 1])
	end
	if(nLayerTalentId ~= nId + g_Martial_TalentCurLayerSelectTalent - 1) then
		nLevel = 0
	end
	if(g_Martial_TalentCurSelectLayer == 5) then
		Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:SetActionItem(-1)
		local SkillInfoID = g_Talent_Driving_SkillBegin + nLayerTalentId - nId
		local nSkilliIndex = -1
		if( SkillInfoID >= g_Talent_Driving_SkillBegin and  SkillInfoID <= g_Talent_Driving_SkillEnd) then
			nSkilliIndex = Player:GetSkillInfo(g_Talent_Driving_SkillBegin + nLayerTalentId - nId,"skillnIndex")
		end
		local theAction = nil;
		if(nSkilliIndex ~= -1) then
			theAction = EnumAction(nSkilliIndex, "skill");
			Martial_WuYi2_Frame_Part_List2_1_Lock:Hide()
		else
			Martial_WuYi2_Frame_Part_List2_1_Lock:Show()
		end
		if(theAction ~= nil) then
			Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:SetActionItem(theAction:GetID());
		end
		Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:SetProperty("DraggingEnabled","True")
		Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:Show()
		Martial_WuYi2_Frame_Part_List2_1_SkillBk:Show()
		
	else
		Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:SetActionItem(-1)
		Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:SetProperty("DraggingEnabled","False")
		Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:Hide()
		Martial_WuYi2_Frame_Part_List2_1_SkillBk:Hide()
		Martial_WuYi2_Frame_Part_List2_1_Lock:Hide()
	end
	local nTalentPoint = nLevel
	if(nTalentPoint == 0) then
		nTalentPoint = 1
	end
	local str1 = ""
	
	if(nLevel > 0) then
		str1="#{WYXT_20170907_377}"
	else
		str1="#{WYXT_20170907_378}"
	end

	if(nLevel >= g_Martial_Talent_MaxLevel) then
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_384}",nTalentPoint)
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_380}",g_Martial_TalentId2Desc[nId + g_Martial_TalentCurLayerSelectTalent - 1][nTalentPoint])
	else
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_379}",nTalentPoint)
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_380}",g_Martial_TalentId2Desc[nId + g_Martial_TalentCurLayerSelectTalent - 1][nTalentPoint])
		local MartialLevel = MaritialSys:GetMaritiaLevel()
		local nNeedMartialLevel = MaritialSys:GetTalentNeedMartialLevel(g_Martial_TalentCurSelectLayer-1,nTalentPoint + 1)
		str1 = str1.."#r".."#{WYXT_20170907_381}"
		if(MartialLevel >= nNeedMartialLevel ) then
			str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_382}",nNeedMartialLevel)
		else
			str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_383}",nNeedMartialLevel)
		end
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_380}",g_Martial_TalentId2Desc[nId + g_Martial_TalentCurLayerSelectTalent - 1][nTalentPoint+1])
	end
	Martial_WuYi2_Frame_Part_List2_1_Top_Level1_Title:SetText(g_Martial_TalentTitles[g_Martial_TalentCurSelectLayer])
	Martial_WuYi2_Frame_Part_List2_1_Explain_Text:SetText(str1)

end

function Marial_WuYi_ReFreshMissonGuild()
	local bShowAnimate = 0
	if(g_Martial_WuYi_CurFenYe == 1) then
		CloseFreshManGuide()
		if DataPool:Lua_IsHaveMission(g_Martial_Guide_MissionIdfst) > 0  then
			local misIndex = DataPool:GetPlayerMissionIndexByID(g_Martial_Guide_MissionIdfst)
			if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
				local fX, fY = this:GetChildOffset("Martial_WuYi_List1_shuxing_jiadian_Button")
				OpenFreshManGuide(1, 197, fX+60, fY+10,"Martial_WuYi","northeast")
				bShowAnimate = 1
			end
		end
		if(bShowAnimate == 1 ) then
			Martial_WuYi_List1_shuxing_jiadian_ButtonAnimate:Show()
		else
			Martial_WuYi_List1_shuxing_jiadian_ButtonAnimate:Hide()
		end
	elseif (g_Martial_WuYi_CurFenYe == 2) then
		
		CloseFreshManGuide()
		if DataPool:Lua_IsHaveMission(g_Martial_Guide_MissionIdsec) > 0  then
			local misIndex = DataPool:GetPlayerMissionIndexByID(g_Martial_Guide_MissionIdsec)
			if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
				local fX, fY = this:GetChildOffset("Martial_WuYi2_Frame_Part_List2_1_Top_Level1")
				OpenFreshManGuide(1, 199, fX+400, fY+50,"Martial_WuYi","northeast")
				bShowAnimate = 1
				SetTimer("Martial_WuYi","Martial_WuYi_MissionGuildTimer()",10*1000)
			end
		end
		if(bShowAnimate == 1) then
			Martial_WuYi2_Frame_Part_List2_1_Explain_Button2Animate:Show()
			--Martial_WuYi2_Frame_Part_List2_1_Explain_Button2:Hide()
		else
			Martial_WuYi2_Frame_Part_List2_1_Explain_Button2Animate:Hide()
			--Martial_WuYi2_Frame_Part_List2_1_Explain_Button2:Show()
		end
	end
end

function Martial_WuYi_MissionGuildTimer()
	if(this:IsVisible() and g_Martial_WuYi_CurFenYe == 2) then
		CloseFreshManGuide()
		if DataPool:Lua_IsHaveMission(g_Martial_Guide_MissionIdsec) > 0  then
			local misIndex = DataPool:GetPlayerMissionIndexByID(g_Martial_Guide_MissionIdsec)
			if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
				local fX, fY = this:GetChildOffset("Martial_WuYi2_Frame_Part_List2_1_Explain_Button2")
				OpenFreshManGuide(1, 200, fX+10, fY+10,"Martial_WuYi","northeast")
				bShowAnimate = 1
			end
		end
	end
	KillTimer("Martial_WuYi_MissionGuildTimer()")
end

function Martial_WuYi_ShowTalentNextTooltip()
	local nId = (g_Martial_TalentCurSelectLayer - 1) * g_Martial_LayerTalentNum + g_Martial_TalentCurLayerSelectTalent
	local nLayerTalentId,nLevel = MaritialSys:GetTalentLevelBylayerID(g_Martial_TalentCurSelectLayer - 1)
	if(nId ~= nLayerTalentId or nLevel < 0) then
		nLevel = 1
	else
		nLevel = nLevel + 1
	end
	if(g_Martial_TalentCurSelectLayer >=1 and g_Martial_TalentCurSelectLayer <= g_Martial_MaxTalentLayer ) then
		if(g_Martial_TalentCurLayerSelectTalent >=1 and g_Martial_TalentCurLayerSelectTalent <= g_Martial_LayerTalentNum) then
			local strNextTip = ScriptGlobal_Format("#{WYXT_20170907_278}",tostring(g_Martial_TalentId2Desc[nId][nLevel]))
			if(nLevel - 1 >= g_Martial_Talent_MaxLevel) then
				strNextTip = "#{WYXT_20170907_279}"
			end
			Martial_WuYi2_Frame_Part_List2_1_Explain_NextButton:SetToolTip(strNextTip)
			return
		end
	end
	Martial_WuYi2_Frame_Part_List2_1_Explain_NextButton:SetToolTip("")
end

--天赋层分页切换
function Maritial_WuYi_TalentFenYeSwitch(nLayer)
	if(nLayer > 0 and nLayer <= g_Martial_MaxTalentLayer ) then
		-- local nMartialLevel = MaritialSys:GetMaritiaLevel()
		-- local nNeedLevel = g_Martial_TalenLayerNeedLevel[nLayer]
		-- if(nMartialLevel >= nNeedLevel) then
			g_Martial_TalentCurSelectLayer = nLayer
			--默认选中学习的那个，如果没有学习的，就选中第一个
			g_Martial_TalentCurLayerSelectTalent = 1
			local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(nLayer - 1)
			if(nId > 0) then
				g_Martial_TalentCurLayerSelectTalent = (nId - (math.floor(nId/g_Martial_LayerTalentNum) * g_Martial_LayerTalentNum));
				if(g_Martial_TalentCurLayerSelectTalent == 0) then
					g_Martial_TalentCurLayerSelectTalent = 3
				end
			end
		-- end
	end
	Martial_WuYi_TalentRefresh()
	--一个都没有开启的状态先显示所有的信息
	-- if(g_Martial_TalentCurSelectLayer == 0) then
		-- Maritial_WuYi_ShowAllTalentInfo()
		-- Martial_WuYi2_Frame_Part_List3_Button1:Hide()
	-- else
	Maritial_WuYi_HideAllTalentInfo()
	-- end
end
--天赋选中切换
function Maritial_WuYi_LayerTalentSwitch(nIndex)
	if(nIndex <=0 or nIndex > g_Martial_LayerTalentNum) then
		return
	end
	--if(nIndex ~= g_Martial_TalentCurLayerSelectTalent) then
		g_Martial_TalentCurLayerSelectTalent = nIndex
		Martial_WuYi_TalentRefreshLayer()
	--end
end
--查看所有天赋介绍
function Maritial_WuYi_ShowAllTalentInfo()
	Martial_WuYi2_Frame_Part_List2_2:Show()
	Martial_WuYi2_Frame_Part_List3_Button1:Show()
	Martial_WuYi2_Frame_Part_List3_Button:Hide()
	Martial_WuYi2_Frame_Part_List2_1_Explain_Button2:Hide()
	Martial_WuYi2_Frame_Part_List2_1_Explain_Button1:Hide()
	Martial_WuYi2_Frame_Part_List2_1:Hide()
	Martial_WuYi_FenYe2_tishi:Hide()
	Martial_WuYi2_Frame_Part_List3_Texttips:Hide()
	Martial_WuYi2_Frame_Part_List3_Help:Hide()
	Martial_WuYi2_Frame_Part_List3_Text:Hide()
	for i=1,g_Martial_MaxTalentID do 
		g_Martial_Talent_LearnFlag[i]:Hide()
	end
	for i=1,g_Martial_MaxTalentLayer do
		local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(i - 1)
		if(nLevel > 0) then
			g_Martial_Talent_LearnFlag[nId]:Show()
		end
	end
end
function Martial_WuYi_SwitchAllTalentInfoButton(nIndex)
	if(g_Martial_Talent_AllInfoSelectButton ~= nIndex) then
		Martial_WuYi2_Frame_Part_List2_2_Explain_Text:SetText("")
		Martial_WuYi2_Frame_Part_List2_2_Explain_title:SetText("")
		for i=1,table.getn(g_Martial_Talent_AllInfoButtons) do
			if(i == nIndex) then
				g_Martial_Talent_AllInfoButtons[i]:SetCheck(1)
				g_Martial_Talent_AllInfoSelectButton = nIndex
				Martial_WuYi2_Frame_Part_List2_2_Explain_title:SetText("#cfff263"..g_Martial_TalentId2Name[i])
				Martial_WuYi2_Frame_Part_List2_2_Explain_Text:SetText(ScriptGlobal_Format("#{WYXT_20170811_149}",tostring(g_Martial_TalentId2Desc[i][g_Martial_Talent_MaxLevel])))
			else
				g_Martial_Talent_AllInfoButtons[i]:SetCheck(0)
			end
		end
	else
		if(g_Martial_Talent_AllInfoButtons[nIndex] ~= nil) then
			g_Martial_Talent_AllInfoButtons[nIndex]:SetCheck(1)
		end
	end
end
--隐藏天赋介绍
function Maritial_WuYi_HideAllTalentInfo()
	Martial_WuYi2_Frame_Part_List2_2:Hide()
	Martial_WuYi2_Frame_Part_List3_Button:Show()
	Martial_WuYi2_Frame_Part_List3_Button1:Hide()
	Martial_WuYi2_Frame_Part_List2_1:Show()
	Martial_WuYi2_Frame_Part_List2_1_Explain_Button2:Show()
	Martial_WuYi2_Frame_Part_List2_1_Explain_Button1:Show()
	Martial_WuYi_FenYe2_tishi:Show()
	Martial_WuYi2_Frame_Part_List3_Texttips:Show()
	Martial_WuYi2_Frame_Part_List3_Text:Show()
	Martial_WuYi2_Frame_Part_List3_Help:Show()
end
--点击返回
function Maritial_WuYi_AllTalentInfoReturnClick()
	if(g_Martial_AllTalentInfoOldLayer == 0) then
		return
	end
	Maritial_WuYi_HideAllTalentInfo()
	g_Martial_TalentCurSelectLayer = g_Martial_AllTalentInfoOldLayer
	g_Martial_TalentCurLayerSelectTalent = g_Martial_AllTalentInfoOldTalent
	g_Martial_AllTalentInfoOldLayer = 0
	g_Martial_AllTalentInfoOldTalent = 0
	Martial_WuYi_TalentRefresh()
end

--点击查看全部
function Maritial_WuYi_AllTalentInfoViewClick()
	g_Martial_AllTalentInfoOldLayer = g_Martial_TalentCurSelectLayer
	g_Martial_AllTalentInfoOldTalent = g_Martial_TalentCurLayerSelectTalent
	g_Martial_TalentCurSelectLayer = 0
	g_Martial_TalentCurLayerSelectTalent = 0
	Martial_WuYi2_TalentRefreshButtons()
	Maritial_WuYi_ShowAllTalentInfo()
end

--初始化天赋介绍页面
function Maritial_WuYi_InitAllTalentInfo()
	for i=1, g_Martial_MaxTalentID do
		-- if(g_Martial_AllTalentInfoButtons[i] ~= nil )then
			-- g_Martial_AllTalentInfoButtons[i]:SetToolTip(tostring(g_Martial_TalentId2Desc[i][1]))
		-- end
		if(g_Martial_AllTalentInfoNameText[i] ~= nil ) then
			g_Martial_AllTalentInfoNameText[i]:SetText(g_Martial_TalentId2Name[i])
		end
	end
end
--属性加点成功的事件
function Maritial_WuYi_OnAttrLevelup(nIndex)
	if(nIndex ~= nil and g_MartialFlashTips[nIndex + 1] ~= nil) then
		g_MartialFlashTips[nIndex + 1][1]:Play(true)
		if(g_MartialFlashTips[g_Martial_CurFlash] ~= nil and g_Martial_CurFlash ~= nIndex + 1) then
			g_MartialFlashTips[g_Martial_CurFlash][1]:Play(false)
		end
		g_Martial_CurFlash = nIndex + 1
		KillTimer("Maritial_WuYi_FlashTimer()")
		SetTimer("Maritial_WuYi","Maritial_WuYi_FlashTimer()",5*1000)
		return
	else
		if(g_MartialFlashTips[g_Martial_CurFlash] ~= nil ) then
			g_MartialFlashTips[g_Martial_CurFlash][1]:Play(false)
		end
		g_Martial_CurFlash = 0
		return
	end
end

function Maritial_WuYi_FlashTimer()
	Maritial_WuYi_CleanCurFlash()
	KillTimer("Maritial_WuYi_FlashTimer()")
end

function Maritial_WuYi_CleanCurFlash()
	if(g_MartialFlashTips[g_Martial_CurFlash] ~= nil) then
		g_MartialFlashTips[g_Martial_CurFlash][1]:Play(false)
		g_Martial_CurFlash = 0
	end
end

function Martial_WuYi_CleanAllFalsh()
	for i=1,table.getn(g_MartialFlashTips) do
		g_MartialFlashTips[i][1]:Play(false)
	end
end

--武意属性操作基础检查
function Martial_WuYi_BaseCheck()
	--安全时间内不能操作
	if(DataPool:GetForeverLock() == true or DataPool:GetLeftProtectTime() > 0 ) then
		PushDebugMessage("#{BYFUR_160531_48}")
		return 0
	end
	--密保 二级密码
	if(CheckPhoneMibaoAndMinorPassword() == 0) then
		return 0
	end
	--是否完成武意突破
	if(MaritialSys:HasFinishWuYiMisson() ~= 1) then
		PushDebugMessage("#{WYXT_20170803_21}")
		return 0
	end
	
	return 1
end
--加点
function Martial_WuYi_ClickAddAttr()
	if(Martial_WuYi_BaseCheck() ~= 1) then
		return 
	end
	--是否有足够的武意点数
	local nRemainPoint = MaritialSys:GetMaritiaRemainPoint()
	if(nRemainPoint <= 0) then
		PushDebugMessage("#{WYXT_20170803_46}")
		PushDebugMessage("#{WYXT_20170907_372}")
		return
	end
	Martial_WuYi_StopAutoRecycleAttr()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AddAttr" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYi_ScriptId )
	Send_XSCRIPT()
end

function Martial_WuYi_RecycleAttrPointClick(nIdx)
	local CurTime = OSAPI:GetTickCount()
	if(CurTime - g_Martial_LastRecycleClick >= g_Martial_RecycleClickLimit) then
		g_Martial_LastRecycleClick = CurTime
		if(g_Martial_IgoneRecycleClick == false) then
			Martial_WuYi_RecycleAttrPoint(nIdx)
		end
	else
		PushDebugMessage("#{WYXT_20170907_391}")
	end
end
--洗点
function Martial_WuYi_RecycleAttrPoint(nIdx)
	--范围检查
	if(nIdx < 0 or nIdx >= g_Martial_WuYi_Max_Martial_Attr_Num) then
		return 0
	end
	if(Martial_WuYi_BaseCheck() ~= 1) then
		return 0
	end
	--检查是否有属性点
	local nValue = MaritialSys:GetMaritiaAttrByIndex(nIdx)
	if(nValue <= 0) then
		PushDebugMessage("#{WYXT_20170803_49}")
		return 0
	end
	--检查金钱
	if(Player:GetData("MONEY_JZ") + Player:GetData("MONEY") < g_Martial_WuYi_ReclyNeedMoney) then
		PushDebugMessage("#{WYXT_20170907_390}")
		return
	end
	--检查道具
	local bExist = IsItemExist(g_Martial_WuYi_ReclyItemID)
	local bExist1 = IsItemExist(g_Martial_WuYi_ReclyItemID1)
	local ISTips = 1;
	if(bExist == 0 and bExist1 == 0) then
		--PushDebugMessage("#{WYXT_20170803_50}")
		--return 0
		ISTips = 0;
	end
	--是否二次确认
	local bComfirm = Martial_WuYi_Top_xidianqueren:GetCheck()
	if(bComfirm == 1) and ISTips == 1 then
		local strTip = ScriptGlobal_Format("#{WYXT_20170803_51}",g_Martial_WuYi_ShuXing2Name[nIdx + 1],g_Martial_WuYi_ShuXing2Name[nIdx + 1])
		PushEvent("MARTIAIL_RECYCLEATTRPOINT_CONFIRM",nIdx,strTip,g_Martial_WuYi_YuanbaoPay)
		return 0
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RecycleAttrPoint" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYi_ScriptId )
		Set_XSCRIPT_Parameter(0,nIdx)
		Set_XSCRIPT_Parameter(1,g_Martial_WuYi_YuanbaoPay)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	return 1
end

function Martial_WuYi_SetAutoRecycleAttr(nIndex)
	--范围检查
	if(nIndex < 0 or nIndex >= g_Martial_WuYi_Max_Martial_Attr_Num) then
		return 
	end
	g_Martial_AutoRecycleAttrFlag = true
	g_Martial_AutoRecycleAttrIndex = nIndex
	SetTimer("Martial_WuYi","Maritial_WuYi_StartAutoRecycleAttr()",300)
end

function Maritial_WuYi_StartAutoRecycleAttr()
	if(g_Martial_AutoRecycleAttrFlag == true) then
		if(Martial_WuYi_RecycleAttrPoint(g_Martial_AutoRecycleAttrIndex) == 0) then
			Martial_WuYi_StopAutoRecycleAttr()
		end
		g_Martial_IgoneRecycleClick = true
	end
	KillTimer("Maritial_WuYi_StartAutoRecycleAttr()")
end

function Martial_WuYi_StopAutoRecycleAttr()
	g_Martial_AutoRecycleAttrFlag = false
	g_Martial_AutoRecycleAttrIndex = -1
	g_Martial_IgoneRecycleClick = false
end

function Martial_WuYi_BangZhuClick(nIndex)
	PushEvent("MARTIAL_SHOW_HELP",nIndex)
end
--一键洗点
function Martial_WuYi_RecycleAllAttrPoint()
	if(Martial_WuYi_BaseCheck() ~= 1) then
		return
	end
	--检查道具
	-- local bExist = IsItemExist(g_Martial_WuYi_ReclyItemID)
	-- local bExist1 = IsItemExist(g_Martial_WuYi_ReclyItemID1)
	-- if(bExist == 0 and bExist1 == 0) then
		-- PushDebugMessage("#{WYXT_20170803_50}")
		-- return
	-- end
	--二次确认
	local bComfirm = Martial_WuYi_Top_xidianqueren:GetCheck()
	if(bComfirm == 1) then
		local nAllAttrCount = 0
		local nNum,attrArray = MaritialSys:GetMaritiaAttrs();
		for i=1,table.getn(g_Martial_WuYi_ShuXingArray) do
			nAllAttrCount = nAllAttrCount + attrArray[i]
		end
		if(nAllAttrCount <= 0 ) then
			PushDebugMessage("#{WYXT_20170803_55}")
			return
		end
		PushEvent("MARTIAIL_RECYCLEATTRPOINT_CONFIRM",g_Martial_WuYi_Max_Martial_Attr_Num,nAllAttrCount)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RecycleAllAttrPoint" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYi_ScriptId )
	Send_XSCRIPT()
end
--冻结经验
function Martial_WuYi_FreezeMartialExp()
	local nState = MaritialSys:GetMaritiaFreezeState()
	local FreezeType = nState - 1
	if(FreezeType < 0) then
		FreezeType = 1
	end
	--检查武意怪数
	local nWuYiMonsterNum = MaritialSys:GetMaritialTodayNum()
	local nWuYiMultiMonsterNum = MaritialSys:GetMaritiaLTodayMultiNum()
	if(nWuYiMonsterNum >= g_Martial_WuYi_Max_Monster_Num) then
		PushDebugMessage("#{WYXT_20170811_180}")
		return
	end
	--二次确认
	-- if(FreezeType == 1) then
		-- PushEvent("MARTIAL_FREEZE_EXP_CONFIRM",g_Martial_WuYi_Max_Monster_Num,nWuYiMonsterNum,nWuYiMultiMonsterNum)
		-- return
	-- end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FreezeMartialExp" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYi_ScriptId )
		Set_XSCRIPT_Parameter(0,FreezeType)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--天赋加点操作
function Maritial_WuYi_LearnTalentClick()
	local layer = g_Martial_TalentCurSelectLayer
	local nId = (layer - 1) * 3 + g_Martial_TalentCurLayerSelectTalent; 
	if(layer < 1 or layer >  g_Martial_MaxTalentLayer) then
		PushDebugMessage("请选择一层天赋")
		return
	end
	if(nId < 0 or nId > g_Martial_MaxTalentID) then
		PushDebugMessage("请选择一个天赋")
		return 
	end
	if(Martial_WuYi_BaseCheck() ~= 1) then
		return
	end
	local nId1,nLevel = MaritialSys:GetTalentLevelBylayerID(layer - 1)
	local nNeedLevel = g_Martial_TalenLayerNeedLevel[layer]
	local nMartialLevel = MaritialSys:GetMaritiaLevel()
	--天赋层是否解锁
	if(nMartialLevel < nNeedLevel ) then
		local str = ScriptGlobal_Format("#{WYXT_20170803_70}",g_Martial_TalentLayer2Name[layer])
		PushDebugMessage(str)
		return
	end
	--有没有足够的点数
	local nTalentPoint = MaritialSys:GetTalentRemainPoint()
	if(nTalentPoint <= 0) then
		PushDebugMessage("#{WYXT_20170803_71}")
		PushDebugMessage("#{WYXT_20170907_366}")
		return
	end
	if(nLevel <= 0) then
		local strTip = ScriptGlobal_Format("#{WYXT_20170907_330}",g_Martial_TalentId2Name[nId])
		PushEvent("TALENT_LEARN_CONFIRM",strTip,layer,nId)
		CloseFreshManGuide()
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "LearnTalent" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYi_TalentScriptId )
		Set_XSCRIPT_Parameter(0,layer)
		Set_XSCRIPT_Parameter(1,nId)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
--天赋洗点操作
function Maritial_WuYi_RecycleTalentClick()
	local layer = g_Martial_TalentCurSelectLayer
	if(layer < 1 or layer >  g_Martial_MaxTalentLayer) then
		PushDebugMessage("请选择一层天赋")
		return
	end
	if(Martial_WuYi_BaseCheck() ~= 1) then
		return
	end
	local nNeedLevel = g_Martial_TalenLayerNeedLevel[layer]
	local nMartialLevel = MaritialSys:GetMaritiaLevel()
	local nId1,nLevel = MaritialSys:GetTalentLevelBylayerID(layer - 1)
	--天赋层是否解锁
	if(nMartialLevel < nNeedLevel ) then
		local str = ScriptGlobal_Format("#{WYXT_20170803_77}",g_Martial_TalentLayer2Name[layer])
		PushDebugMessage(str)
		return
	end
	--改天赋层是否学习
	if(nLevel <= 0 or nId1 <= 0) then
		local str = ScriptGlobal_Format("#{WYXT_20170811_118}",layer)
		PushDebugMessage(str)
		return
	end
	--金钱够不够
	if(Player:GetData("MONEY_JZ") + Player:GetData("MONEY") < 100000) then
		local str = ScriptGlobal_Format( "#{WYXT_20170803_79}", g_Martial_TalentLayer2Name[layer],100000)
		PushDebugMessage(str)
		PushDebugMessage("#{WYXT_20170907_273}")
		return
	end
	--检查场景
	local sceneid = GetSceneServerID()
	local mainsceneid = GetMainSceneID(sceneid)
	if(g_Martial_Talent_TalentReclyLimitScene[mainsceneid] == nil or g_Martial_Talent_TalentReclyLimitScene[mainsceneid] ~= 0) then
		PushDebugMessage("#{WYXT_20170907_301}")
		return
	end
	--全部条件通过二次确认
	PushEvent("MARTAIL_RLEARN_TALENT_CONFIRM",layer,nLevel,100000,g_Martial_TalentId2Name[nId1])
	
	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name( "RecycleTalent" )
		-- Set_XSCRIPT_ScriptID( g_Martial_WuYi_TalentScriptId )
		-- Set_XSCRIPT_Parameter(0,layer)
		-- Set_XSCRIPT_Parameter(1,nId)
		-- Set_XSCRIPT_ParamCount(2)
	-- Send_XSCRIPT()
end

function Martial_WuYi_ZhaoHuiClick()
	--开服当天不允许找回
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end
	local curDay = tonumber(DataPool:GetServerDayTime());
	if(curDay <= g_Martial_MartialZhaoHuiBeginDay) then
		PushDebugMessage("#{WYXT_20170907_432}")
		return
	end
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nMartialLevel = MaritialSys:GetMaritiaLevel()
	if(nMartialLevel >= g_MartialMaxLevel) then
		PushDebugMessage("#{WYXT_20170907_420}")
		return
	end
	if(nMonsterNum <= 0) then
		PushDebugMessage("#{WYXT_20170907_398}")
		return
	end
	if(nReward == 1) then
		PushDebugMessage("#{WYXT_20170907_397}")
		return
	end
	if(nMartialLevel + 1 <=g_MartialMaxLevel and Player:GetLevel() < g_Martial_WuYi_LevelLimit[nMartialLevel + 1]) then
		PushDebugMessage(ScriptGlobal_Format("#{WYXT_20170907_415}",g_Martial_WuYi_LevelLimit[nMartialLevel + 1]))
		return
	end
	--MaritialSys:SetLastDayMonsterTip(0)
	--Martial_WuYi_List1_shuxingtiao1_Buttontips:Hide()
	PushEvent("SHOW_MARTIAL_ZHAOHUI",g_Martial_WuYi_LevelExp[g_MartialMaxLevel])
end

--主动向服务器请求数据
function Martial_WuYi_AskForMartialData()
	g_AllMartialExp = -1
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReturnMartialData" )
		Set_XSCRIPT_ScriptID( g_Martial_WuYi_ScriptId )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Martial_WuYi_CalcAdvancePersent(nIndex)
	local nPersent = 0
	for i=1,g_Martial_WuYi_JingTongMaxIndex do
		local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(i - 1)
		if(nId == nIndex and nLevel > 0) then
			nPersent = nPersent + MaritialSys:GetMartialAdvancePersent(nId,nLevel - 1)
		end
	end
	return nPersent
end

function Marial_WuYi_OnAddExpForTip(nAddExp,nAddExpDouble)
	local nLevel = MaritialSys:GetMaritiaLevel()
	if(nAddExp ~= nil and nAddExp ~= 0 and nLevel < g_MartialMaxLevel) then
		local str = ""
		if(nAddExpDouble ~=nil and nAddExpDouble ~= 0) then
			str = ScriptGlobal_Format("#{WYXT_20170808_101}",nAddExp,nAddExpDouble)
		else	
			str = ScriptGlobal_Format("#{WYXT_20170808_100}",nAddExp)
		end
		g_AllMartialExp = g_AllMartialExp + nAddExp + nAddExpDouble
		PushDebugMessage(str)
	end
end

function Martial_WuYi_ButtonActionClick()
	local isCanDo = DataPool:IsCanDoAction()
	if isCanDo == true then
		Martial_WuYi2_Frame_Part_List2_1_Explain_ActionButton:DoAction()
	else
		PushDebugMessage("你不能这么做。")
		return;
	end
end

function Martial_WuYi_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		Martial_WuYi_ShenDing:Disable()
		Martial_WuYi_ShenDing_tips:Show()
	--	Martial_WuYi_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		Martial_WuYi_ShenDing:Enable()
		Martial_WuYi_ShenDing_tips:Hide()
	end
	--子女2
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 or InfantCount<=0) then--or InfantCount <= 0 then
		Martial_WuYi_Infant:Disable()
		Martial_WuYi_Infant_tips:Show()
--		Infant_infant:SetToolTip("#{RWYQ_150707_01}")
	else
		Martial_WuYi_Infant:Enable()
		Martial_WuYi_Infant_tips:Hide()
	end
	--武魂
	if ( nLevel < 65 ) then
		Martial_WuYi_Wuhun:Disable()
		Martial_WuYi_Wuhun_tips:Show()
	else
		Martial_WuYi_Wuhun:Enable()
		Martial_WuYi_Wuhun_tips:Hide()
	end
	--修炼
	if ( nLevel < 70 ) then
		Martial_WuYi_Xiulian:Disable()
		Martial_WuYi_Xiulian_tips:Show()
	else
		Martial_WuYi_Xiulian:Enable()
		Martial_WuYi_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		Martial_WuYi_Miji:Disable()
		Martial_WuYi_Miji_tips:Show()

	else
		Martial_WuYi_Miji:Enable()
		Martial_WuYi_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		Martial_WuYi_ZhenYuan:Disable()
		Martial_WuYi_ZhenYuan_tips:Show()
	else
		Martial_WuYi_ZhenYuan:Enable()
		Martial_WuYi_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		Martial_WuYi_JunXian:Disable()
		Martial_WuYi_JunXian_tips:Show()
	else
		Martial_WuYi_JunXian:Enable()
		Martial_WuYi_JunXian_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		Martial_WuYi_JingMai:Disable()
		Martial_WuYi_JingMai_tips:Show()
	else
		Martial_WuYi_JingMai:Enable()
		Martial_WuYi_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		Martial_WuYi_BaoJian:Disable()
		Martial_WuYi_BaoJian_tips:Show()
	else
		Martial_WuYi_BaoJian:Enable()
		Martial_WuYi_BaoJian_tips:Hide()
	end
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		Martial_WuYi_WuYi:Enable()
		Martial_WuYi_WuYi_tips:Hide()
	else
		Martial_WuYi_WuYi:Disable()
		Martial_WuYi_WuYi_tips:Show()
	end
	Martial_WuYi_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		Martial_WuYi_ShenQi:Enable()
		Martial_WuYi_ShenQi_tips:Hide()
	else
		Martial_WuYi_ShenQi:Disable()
		Martial_WuYi_ShenQi_tips:Show()
	end
	Martial_WuYi_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		Martial_WuYi_Armor:Enable()
		Martial_WuYi_Armor_tips:Hide()
	else
		Martial_WuYi_Armor:Disable()
		Martial_WuYi_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		Martial_WuYi_CangPin:Enable()
		Martial_WuYi_CangPin_tips:Hide()
	else
		Martial_WuYi_CangPin:Disable()
		Martial_WuYi_CangPin_tips:Show()
	end
	
	Martial_WuYi_RefreshCangPinTip()
end


function Martial_WuYi_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenEquip(1);
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = SystemSetup:OpenPrivatePage("self");
	Martial_WuYi_Frame_OnHiden()
end


function Martial_WuYi_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = TogglePetPage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = ToggleWuhunPage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_Xiulian_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = XiuLianPage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJingMaiPage();
	Martial_WuYi_Frame_OnHiden()
end

--神木王鼎
function Martial_WuYi_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenRidePage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_OtherInfo_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OtherInfoPage();
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_OpenBaoJian()
	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()
	Martial_WuYi_Frame_OnHiden()
end

function Martial_WuYi_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	Martial_WuYi_Frame_OnHiden()

end

function Martial_WuYi_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	Martial_WuYi_Frame_OnHiden()
end

-- 九星神器DIY技能
function Martial_WuYi_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Martial_WuYi_Confirm_Clicked() 
	g_Martial_WuYi_YuanbaoPay = Martial_WuYi_Top_yuanbaoqueren:GetCheck();
end

function Martial_WuYi_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Martial_WuYi_PageButton[idx]:GetProperty("UnifiedXPosition");
			Martial_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		Martial_WuYi_Buttontips:Show()
	else
		Martial_WuYi_Buttontips:Hide()
	end
end

function Martial_WuYi_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Martial_WuYi_PageButton[idx]:GetProperty("UnifiedXPosition");
			Martial_WuYi_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		Martial_WuYi_OtherInfo_ButtonTips:Show()
	else
		Martial_WuYi_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function Martial_WuYi_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function Martial_WuYi_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Martial_WuYi_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function Martial_WuYi_RefreshCangPinTip()
	local CangPinClassCount = 4
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	local bTip = 0
	for i = 1, CangPinClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 16 and g_PageButtonTipsPos[idx] then -- 名物
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Martial_WuYi_PageButton[idx]:GetProperty("UnifiedXPosition");
			Martial_WuYi_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		Martial_WuYi_CangPin_Buttontips:Show()
	else
		Martial_WuYi_CangPin_Buttontips:Hide()
	end
end


function Martial_WuYi_ShowPage()

	for i = 1, table.getn(g_Martial_WuYi_Page) do
		g_Martial_WuYi_PageButton[i]:Hide()
		g_Martial_WuYi_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	Martial_WuYi_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_Martial_WuYi_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_Martial_WuYi_Page) do
			if i ~= nPageNumber then
				g_Martial_WuYi_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_Martial_WuYi_Page) do
		if Martial_WuYi_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_Martial_WuYi_PageButton[g_PageCount]:Show()
			g_Martial_WuYi_PageButton[g_PageCount]:SetText(g_Martial_WuYi_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if Martial_WuYi_IsPageEnable(i) == 1 then
				g_Martial_WuYi_PageButton[g_PageCount]:Enable()
				g_Martial_WuYi_PageMask[g_PageCount]:Hide()
			else
				g_Martial_WuYi_PageButton[g_PageCount]:Disable()
				g_Martial_WuYi_PageMask[g_PageCount]:Show()
				if g_Martial_WuYi_Page[i].Tip ~= "" then
					g_Martial_WuYi_PageMask[g_PageCount]:SetToolTip(g_Martial_WuYi_Page[i].Tip)
				end
			end
		end
	end
	
	Martial_WuYi_RefreshWuYiTip()
	Martial_WuYi_RefreshOtherInfoTip()
	Martial_WuYi_RefreshCangPinTip()
	
end

function Martial_WuYi_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		Martial_WuYi_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		Martial_WuYi_SelfData_Switch()
	elseif idx == 3 then--珍兽
		Martial_WuYi_Pet_Switch()
	elseif idx == 4 then--子女
		Martial_WuYi_Infant_Switch()
	elseif idx == 5 then--武魂
		Martial_WuYi_Wuhun_Switch()
	elseif idx == 6 then--修炼
		Martial_WuYi_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		Martial_WuYi_Miji_Page_Switch()
	elseif idx == 8 then--真元
		Martial_WuYi_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		Martial_WuYi_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		Martial_WuYi_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		Martial_WuYi_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		Martial_WuYi_OpenBaoJian()
	elseif idx == 13 then--武意
		--SelfData_OpenWuYi()
	elseif idx == 14 then--神器
		Martial_WuYi_OpenShenQi()
	elseif idx == 15 then--星盘
		Martial_WuYi_Armor_Page_Switch()
	elseif idx == 16 then--名物
		Martial_WuYi_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		Martial_WuYi_OtherInfo_Switch()
	end
end

function Martial_WuYi_CheckPage(idx)
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		return 1
	elseif idx == 7 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 9 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 16 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function Martial_WuYi_IsPageEnable(idx)
	
	local nLevel = Player:GetLevel()
	
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		local InfantCount = Infant:GetInfantCount();
		if ( nLevel < 50 ) or ( InfantCount <= 0 ) then
			return 0
		end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		if ( nLevel < 70 ) then
			return 0
		end
		return 1
	elseif idx == 7 then--秘籍
		local ret = DataPool:Lua_IsMissionHaveDone(1651)
		if ( nLevel < 75 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		local ret = DataPool:Lua_IsMissionHaveDone(1600)
		if ( nLevel < 80 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 9 then--经脉
		local ret = DataPool:Lua_IsMissionHaveDone(1554)
		if ( nLevel < 90 ) or ( ret == 0 )  then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if ( nLevel < 15 ) then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if (MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
			return 1
		end
		return 0
	elseif idx == 14 then--神器
		if (DataPool:Lua_IsMissionHaveDone(1950) == 1) then
			return 1
		end
		return 0
	elseif idx == 15 then--星盘
		if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
			return 1
		end
		return 0
	elseif idx == 16 then--名物
		if nLevel < 30 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function Martial_WuYi_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


