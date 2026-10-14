--查看-武意界面

local g_OtherMartial_WuYi_Frame_UnifiedXPosition
local g_OtherMartial_WuYi_Frame_UnifiedYPosition
--这个要和代码里的MAX_OtherMartial_ATTR_NUM 保持一致
local g_OtherMartial_WuYi_Max_OtherMartial_Attr_Num = 15

local g_OtherMartial_WuYi_ShuXingArray  = {}
-- local g_OtherMartial_WuYi_ShuXingJingTong = {}

--当前分页id
local g_OtherMartial_WuYi_CurFenYe = 0


local g_OtherMartial_WuYi_JingTongMaxIndex = 3
-- local g_OtherMartial_WuYi_JingTongText = {}
local g_OtherMartial_WuYi_JingTongLevelText = {}

--每个属性点增加的属性的值，以配置表为准(配置表以0开始，这里我们从1开始)
local g_OtherMartial_WuYi_ShuXingLevelPoint = {}
--属性index对应的名字 以配置表为准
local g_OtherMartial_WuYi_ShuXing2Name = {}
local g_OtherMartial_Rigth_ShuxingText = {}
-- local g_OtherMartial_Rigth_ShuxingText1 = {}
-- local g_OtherMartial_Rigth_ShuxingText2 = {}


--武意天赋
local g_OtherMartial_MaxTalentLayer = 5
--天赋ID最大值，读表
local g_OtherMartial_MaxTalentID = 0
--天赋名字和描述，读表
local g_OtherMartial_TalentId2Name = {}
local g_OtherMartial_TalentId2Desc = {}
local g_OtherMartial_TalenLayerNeedLevel = {}
local g_OtherMartial_TalentLayerButtons = {}
local g_OtherMartial_TalentSelectButtons = {}
--当前选中的天赋层
local g_OtherMartial_TalentCurSelectLayer = 0
--当前天赋层选中的天赋
local g_OtherMartial_TalentCurLayerSelectTalent = 0
--每层天赋数量
local g_OtherMartial_LayerTalentNum = 3

local g_OtherMartial_TalentButtons = {}

local g_OtherMartial_AllTalentInfoOldLayer = 0
local g_OtherMartial_AllTalentInfoOldTalent = 0
local g_OtherMartial_TalentLayer2Name = 
{
	[1] = 		   "#{WYXT_20170906_264}",
	[2] =          "#{WYXT_20170906_265}",
	[3] =          "#{WYXT_20170906_266}",
	[4] =          "#{WYXT_20170906_267}",
	[5] =          "#{WYXT_20170906_268}",
}

local g_OtherMartialMaxLevel = 150

local g_OtherTalent_Driving_SkillBegin = 3588

local g_OtherMartial_Talent_Image = {}
local g_OtherMartial_Talent_LayerIdButton = {}
local g_OtherMartial_Talent_MaxLevel = 10

local g_OtherMartial_CareObjId = -1

local g_OtherMartial_Talent_Id2IamgesetName = 
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

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_OtherMartial_WuYi_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = ""},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = ""},
	[6] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = ""},
	[7] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = ""},
	[8] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = ""},
	[9] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = ""},
	[10] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = ""},
	[11] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = ""},
	[12] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = ""},
	[13] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = ""},
	[14] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = ""},
	[15] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = ""},
}

local g_OtherPageButton = {}
local g_OtherPageCount = 0
local g_OtherPageOrder = {}

--===============================================
-- OnLoad()
--===============================================
function OtherMartial_WuYi_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("TOGLE_OTHERMARTIAL_PAGE")
	
	this:RegisterEvent("MARTAIL_OTHER_UPDATE")
	
	this:RegisterEvent("TALENT_OTHER_UPDATE")
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	

end

function OtherMartial_WuYi_OnLoad()
	--每个index显示什么属性就以这里的初始化来决定
	g_OtherMartial_WuYi_ShuXingArray[1] = OtherMartial_WuYi_List1_shuxing_xue_Text
	g_OtherMartial_WuYi_ShuXingArray[2] = OtherMartial_WuYi_List1_shuxing_binggong_Text
	g_OtherMartial_WuYi_ShuXingArray[3] = OtherMartial_WuYi_List1_shuxing_huogong_Text
	g_OtherMartial_WuYi_ShuXingArray[4] = OtherMartial_WuYi_List1_shuxing_xuangong_Text
	g_OtherMartial_WuYi_ShuXingArray[5] = OtherMartial_WuYi_List1_shuxing_dugong_Text
	g_OtherMartial_WuYi_ShuXingArray[6] = OtherMartial_WuYi_List1_shuxing_mingzhong_Text
	g_OtherMartial_WuYi_ShuXingArray[7] = OtherMartial_WuYi_List1_shuxing_shanbi_Text
	g_OtherMartial_WuYi_ShuXingArray[8] = OtherMartial_WuYi_List1_shuxing_chuancishanghai_Text
	g_OtherMartial_WuYi_ShuXingArray[9] = OtherMartial_WuYi_List1_shuxing_chuancijianmian_Text
	
	g_OtherMartial_Rigth_ShuxingText[1] = OtherMartial_WuYi_List2_shuju_1_1
	g_OtherMartial_Rigth_ShuxingText[2] = OtherMartial_WuYi_List2_shuju_2_1
	g_OtherMartial_Rigth_ShuxingText[3] = OtherMartial_WuYi_List2_shuju_3_1
	g_OtherMartial_Rigth_ShuxingText[4] = OtherMartial_WuYi_List2_shuju_4_1
	g_OtherMartial_Rigth_ShuxingText[5] = OtherMartial_WuYi_List2_shuju_5_1
	g_OtherMartial_Rigth_ShuxingText[6] = OtherMartial_WuYi_List2_shuju_6_1
	g_OtherMartial_Rigth_ShuxingText[7] = OtherMartial_WuYi_List2_shuju_7_1
	g_OtherMartial_Rigth_ShuxingText[8] = OtherMartial_WuYi_List2_shuju_8_1
	g_OtherMartial_Rigth_ShuxingText[9] = OtherMartial_WuYi_List2_shuju_9_1
	
	-- g_OtherMartial_Rigth_ShuxingText1[1] = OtherMartial_WuYi_List2_shuju_1_2
	-- g_OtherMartial_Rigth_ShuxingText1[2] = OtherMartial_WuYi_List2_shuju_2_2
	-- g_OtherMartial_Rigth_ShuxingText1[3] = OtherMartial_WuYi_List2_shuju_3_2
	-- g_OtherMartial_Rigth_ShuxingText1[4] = OtherMartial_WuYi_List2_shuju_4_2
	-- g_OtherMartial_Rigth_ShuxingText1[5] = OtherMartial_WuYi_List2_shuju_5_2
	-- g_OtherMartial_Rigth_ShuxingText1[6] = OtherMartial_WuYi_List2_shuju_6_2
	-- g_OtherMartial_Rigth_ShuxingText1[7] = OtherMartial_WuYi_List2_shuju_7_2
	-- g_OtherMartial_Rigth_ShuxingText1[8] = OtherMartial_WuYi_List2_shuju_8_2
	-- g_OtherMartial_Rigth_ShuxingText1[9] = OtherMartial_WuYi_List2_shuju_9_2	
	
	-- g_OtherMartial_Rigth_ShuxingText2[1] = OtherMartial_WuYi_List2_shuju_1_2
	-- g_OtherMartial_Rigth_ShuxingText2[2] = OtherMartial_WuYi_List2_shuju_2_2
	-- g_OtherMartial_Rigth_ShuxingText2[3] = OtherMartial_WuYi_List2_shuju_3_2
	-- g_OtherMartial_Rigth_ShuxingText2[4] = OtherMartial_WuYi_List2_shuju_4_2
	-- g_OtherMartial_Rigth_ShuxingText2[5] = OtherMartial_WuYi_List2_shuju_5_2
	-- g_OtherMartial_Rigth_ShuxingText2[6] = OtherMartial_WuYi_List2_shuju_6_2
	-- g_OtherMartial_Rigth_ShuxingText2[7] = OtherMartial_WuYi_List2_shuju_7_2
	-- g_OtherMartial_Rigth_ShuxingText2[8] = OtherMartial_WuYi_List2_shuju_8_2
	-- g_OtherMartial_Rigth_ShuxingText2[9] = OtherMartial_WuYi_List2_shuju_9_2
	
	
	
	-- g_OtherMartial_WuYi_JingTongText = 
	-- {
		-- [1] = OtherMartial_WuYi_List2_shuju_10,
		-- [2] = OtherMartial_WuYi_List2_shuju_11,
		-- [3] = OtherMartial_WuYi_List2_shuju_12,
	-- }
	g_OtherMartial_WuYi_JingTongLevelText = 
	{
		[1] = OtherMartial_WuYi_List2_shuju_10_1,
		[2] = OtherMartial_WuYi_List2_shuju_11_1,
		[3] = OtherMartial_WuYi_List2_shuju_12_1,
	}
	
	-- g_OtherMartial_WuYi_ShuXingJingTong = 
	-- {
		-- [1] = {OtherMartial_WuYi_List1_shuxing_xue_jing,OtherMartial_WuYi_List2_shuju_1_jing},
		-- [2] = {OtherMartial_WuYi_List1_shuxing_binggong_jing,OtherMartial_WuYi_List2_shuju_2_jing},
		-- [3] = {OtherMartial_WuYi_List1_shuxing_huogong_jing,OtherMartial_WuYi_List2_shuju_3_jing},
		-- [4] = {OtherMartial_WuYi_List1_shuxing_xuangong_jing,OtherMartial_WuYi_List2_shuju_4_jing},
		-- [5] = {OtherMartial_WuYi_List1_shuxing_dugong_jing,OtherMartial_WuYi_List2_shuju_5_jing},
		-- [6] = {OtherMartial_WuYi_List1_shuxing_mingzhong_jing,OtherMartial_WuYi_List2_shuju_6_jing},
		-- [7] = {OtherMartial_WuYi_List1_shuxing_shanbi_jing,OtherMartial_WuYi_List2_shuju_7_jing},
		-- [8] = {OtherMartial_WuYi_List1_shuxing_chuancishanghai_jing,OtherMartial_WuYi_List2_shuju_8_jing},
		-- [9] = {OtherMartial_WuYi_List1_shuxing_chuancijianmian_jing,OtherMartial_WuYi_List2_shuju_9_jing},
	-- }


	g_OtherMartial_TalentButtons = 
	{
		[1] = {
			win = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_1,
			btntext = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_Text1,
			selectText = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_Text1,
			selectWin = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_1,
			levelText = OtherMartial_WuYi2_Frame_Part_List2_1_level1,
		},
		[2] = {
			win = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_2,
			btntext = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_Text2,
			selectText = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_Text2,
			selectWin = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_2,
			levelText = OtherMartial_WuYi2_Frame_Part_List2_1_level2,
		},
		[3] = {
			win = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_3,
			btntext = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_Text3,
			selectText = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_Text3,
			selectWin = OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_3,
			levelText = OtherMartial_WuYi2_Frame_Part_List2_1_level3,
		},
	}
	
	g_OtherMartial_TalentLayerButtons[1] = 
	{
		btn   			= OtherMartial_WuYi2_Frame_Part_List1_Button1,
		text  			= OtherMartial_WuYi2_Frame_Part_List1_Button1_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Button1_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock6,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui6,
	}
	g_OtherMartial_TalentLayerButtons[2] = 
	{
		btn   			= OtherMartial_WuYi2_Frame_Part_List1_Button2,
		text  			= OtherMartial_WuYi2_Frame_Part_List1_Button2_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Button2_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock7,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui7,
	}
	g_OtherMartial_TalentLayerButtons[3] = 
	{
		btn   			= OtherMartial_WuYi2_Frame_Part_List1_Button3,
		text  			= OtherMartial_WuYi2_Frame_Part_List1_Button3_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Button3_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock8,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui8,
	}
	g_OtherMartial_TalentLayerButtons[4] = 
	{
		btn   			= OtherMartial_WuYi2_Frame_Part_List1_Button4,
		text  			= OtherMartial_WuYi2_Frame_Part_List1_Button4_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Button4_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock9,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui9,
	}
	g_OtherMartial_TalentLayerButtons[5] = 
	{
		btn   			= OtherMartial_WuYi2_Frame_Part_List1_Button5,
		text  			= OtherMartial_WuYi2_Frame_Part_List1_Button5_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Button5_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock10,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui10,
	}
	
	g_OtherMartial_TalentSelectButtons[1] =
	{
		btn 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button1,
		text 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button1_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button1_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock1,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui1,
	}
	g_OtherMartial_TalentSelectButtons[2] =
	{
		btn 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button2,
		text 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button2_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button2_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock2,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui2,
	}
	g_OtherMartial_TalentSelectButtons[3] =
	{
		btn 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button3,
		text 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button3_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Selected_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock3,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui3,
	}
	g_OtherMartial_TalentSelectButtons[4] =
	{
		btn 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button4,
		text 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button4_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button4_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock4,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui4,
	}
	g_OtherMartial_TalentSelectButtons[5] =
	{
		btn 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button5,
		text 			= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button5_Text2,
		talentPonint 	= OtherMartial_WuYi2_Frame_Part_List1_Selected_Button5_Text4,
		lock = OtherMartial_WuYi2_Frame_Part_List1_Lock5,
		lockhui = OtherMartial_WuYi2_Frame_Part_List1_LockHui5,
	}
	
	g_OtherMartial_Talent_Image = 
	{
		[1] = {OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_Image1,OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_Image1,OtherMartial_WuYi2_Frame_Part_List2_1_Top_SkillImage1},
		[2] = {OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_Image2,OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_Image2,OtherMartial_WuYi2_Frame_Part_List2_1_Top_SkillImage2},
		[3] = {OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level2_Image3,OtherMartial_WuYi2_Frame_Part_List2_1_Top_Level1_Image3,OtherMartial_WuYi2_Frame_Part_List2_1_Top_SkillImage3},
	}
	
	-- 保存界面的默认相对位置
	g_OtherMartial_WuYi_Frame_UnifiedXPosition	= OtherMartial_WuYi_Frame : GetProperty("UnifiedXPosition");
	g_OtherMartial_WuYi_Frame_UnifiedYPosition	= OtherMartial_WuYi_Frame : GetProperty("UnifiedYPosition");

	OtherMartial_WuYi_LoadWuYiAttrInfo()
	OtherMartial_WuYi_LoadWuYiLevelInfo()
	OtherMartial_WuYi_LoadTalentInfo()
	OtherMartial_WuYi_LoadTalentDescInfo()

	g_OtherPageButton[1] = OtherMartial_WuYi_SelfEquip
	g_OtherPageButton[2] = OtherMartial_WuYi_SelfData
	g_OtherPageButton[3] = OtherMartial_WuYi_Pet
	g_OtherPageButton[4] = OtherMartial_WuYi_Infant
	g_OtherPageButton[5] = OtherMartial_WuYi_Wuhun
	g_OtherPageButton[6] = OtherMartial_WuYi_Miji
	g_OtherPageButton[7] = OtherMartial_WuYi_ZhenYuan
	g_OtherPageButton[8] = OtherMartial_WuYi_JingMai
	g_OtherPageButton[9] = OtherMartial_WuYi_ShenDing
	g_OtherPageButton[10] = OtherMartial_WuYi_JunXian
	g_OtherPageButton[11] = OtherMartial_WuYi_BaoJian
	g_OtherPageButton[12] = OtherMartial_WuYi_WuYi
	g_OtherPageButton[13] = OtherMartial_WuYi_ShenQi
	g_OtherPageButton[14] = OtherMartial_WuYi_Armor
	g_OtherPageButton[15] = OtherMartial_WuYi_CangPin
	
end
--===============================================
-- OnEvent()
--===============================================
function OtherMartial_WuYi_OnEvent(event)

	if(event == "TOGLE_OTHERMARTIAL_PAGE") then	
		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		g_OtherMartial_CareObjId = obj_id
		this:CareObject(obj_id, 1, "OtherMartial_WuYi");
		local selfUnionPos = Variable:GetVariable("OtherUnionPos");
		if(selfUnionPos ~= nil) then
			OtherMartial_WuYi_Frame:SetProperty("UnifiedPosition", selfUnionPos);
			g_OtherMartial_WuYi_Frame_UnifiedXPosition	= OtherMartial_WuYi_Frame : GetProperty("UnifiedXPosition");
			g_OtherMartial_WuYi_Frame_UnifiedYPosition	= OtherMartial_WuYi_Frame : GetProperty("UnifiedYPosition");
		end
		OtherMartial_WuYi_WuYi:SetCheck(1)
		OtherMartial_WuYi_SwitchPage(1)
		OtherMartial_WuYi_ShowPage()
	elseif(event == "MARTAIL_OTHER_UPDATE") then
		if(this:IsVisible() and g_OtherMartial_WuYi_CurFenYe == 1) then
			OtherMartial_WuYi_Refresh()
		end
	elseif(event == "TALENT_OTHER_UPDATE") then
		if(this:IsVisible() and g_OtherMartial_WuYi_CurFenYe == 2) then
			OtherMartial_WuYi_TalentRefresh()
		end
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		OtherMartial_WuYi_Frame_OnHiden();
		return;
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		OtherMartial_WuYi_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		OtherMartial_WuYi_Frame_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_OtherMartial_CareObjId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1=="destroy") then
			OtherMartial_WuYi_Frame_OnHiden()
		end
	end
end

--===============================================
-- OnHiden
--===============================================
function OtherMartial_WuYi_Frame_OnHiden()
	if(g_OtherMartial_CareObjId ~= nil and g_OtherMartial_CareObjId ~= -1) then
		this:CareObject(g_OtherMartial_CareObjId, 0, "OtherMartial_WuYi");
	end
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function OtherMartial_WuYi_Frame_On_ResetPos()

	OtherMartial_WuYi_Frame : SetProperty("UnifiedXPosition", g_OtherMartial_WuYi_Frame_UnifiedXPosition);
	OtherMartial_WuYi_Frame : SetProperty("UnifiedYPosition", g_OtherMartial_WuYi_Frame_UnifiedYPosition);

end
function OtherMartial_WuYi_OnMoved()
	return
end

function OtherMartial_WuYi_SwitchPage(nIndex)
	
	OtherMartial_WuYi_Frame_Part:Hide()
	OtherMartial_WuYi2_Frame_Part:Hide()
	if(1 == nIndex) then --武意属性点
		OtherMartial_WuYi_Refresh()
		OtherMartial_WuYi_Frame_Part:Show()
		OtherMartial_WuYi_FenYe1:SetCheck(1)
		OtherMartial_WuYi_FenYe2:SetCheck(0)
		g_OtherMartial_WuYi_CurFenYe = 1
	elseif(2 == nIndex) then
		OtherMartial_WuYi2_Frame_Part:Show()
		OtherMartial_WuYi_FenYe1:SetCheck(0)
		OtherMartial_WuYi_FenYe2:SetCheck(1)
		g_OtherMartial_WuYi_CurFenYe = 2
		--默认选中第一个
		if(g_OtherMartial_TalentCurSelectLayer == 0) then
			OtherMartial_WuYi_TalentFenYeSwitch(1)
		else
			OtherMartial_WuYi_TalentRefresh()
		end
	end
	this:Show()
end

function OtherMartial_WuYi_CloseFunction()
	OtherMartial_WuYi_Frame_OnHiden()
end
--刷新武意界面
function OtherMartial_WuYi_Refresh()
	
	OtherMartial_WuYi_RefreshShuXingDian()

	OtherMartial_WuYi_RefreshJingTong()
end
--加载武意属性配置
function OtherMartial_WuYi_LoadWuYiAttrInfo()
	local data = MaritialSys:GetMaritiaAttrInfo()
	if(data ~= nil) then
		g_OtherMartial_WuYi_ShuXing2Name = {}
		g_OtherMartial_WuYi_ShuXingLevelPoint = {}
	end
	for i,v in ipairs(data) do
		g_OtherMartial_WuYi_ShuXing2Name[v[1] + 1] = v[2];
		g_OtherMartial_WuYi_ShuXingLevelPoint[v[1] + 1] = v[3];
	end
end

--加载天赋配置
function OtherMartial_WuYi_LoadTalentInfo()
	local data = MaritialSys:GetTalentInfo()
	if(data ~= nil) then
		g_OtherMartial_TalentIdInfo = {}
	end
	for i,v in ipairs(data) do
		g_OtherMartial_TalentId2Name[v[1]] = v[2]
		if(g_OtherMartial_MaxTalentID < v[1] ) then
			g_OtherMartial_MaxTalentID = v[1]
		end
	end
end
--加载武意等级配置
function OtherMartial_WuYi_LoadWuYiLevelInfo()
	local data = MaritialSys:GetMartialLevelInfo()
	if(data ~= nil) then
		g_OtherMartial_TalenLayerNeedLevel = {}
	end
	for i,v in ipairs(data) do
		local nLayer = v[5]
		if(nLayer ~= 0 and (g_OtherMartial_TalenLayerNeedLevel[nLayer] == nil or g_OtherMartial_TalenLayerNeedLevel[nLayer] > v[1])) then
			g_OtherMartial_TalenLayerNeedLevel[nLayer] = v[1]
		end
	end
end

--加载天赋描述
function OtherMartial_WuYi_LoadTalentDescInfo()
	local data = MaritialSys:GetTalentDescInfo()
	if(data == nil) then
		return
	end
	g_OtherMartial_TalentId2Desc = data
end

--刷新武意属性界面属性点显示
function OtherMartial_WuYi_RefreshShuXingDian()
	local nNum,attrArray = MaritialSys:GetMaritiaAttrs("other");
	
	if(nNum < table.getn(g_OtherMartial_WuYi_ShuXingArray) and attrArray ~= nil) then
		return
	end
	--刷新中间的属性点显示和右边的属性显示
	for i = 1,table.getn(g_OtherMartial_WuYi_ShuXingArray) do
		local nAttrPoint = math.floor((attrArray[i] * g_OtherMartial_WuYi_ShuXingLevelPoint[i]) / 10 )
		local nPersent = OtherMartial_WuYi_CalcAdvancePersent(i - 1)
		-- local nPersentValue = math.ceil((nPersent * nAttrPoint) / 100)
		local str1 = "#cfff263+"..nAttrPoint
		-- local str2 = ""
		local str3 = ScriptGlobal_Format("#{WYXT_20170907_336}",attrArray[i])
		g_OtherMartial_WuYi_ShuXingArray[i]:SetText(str3)
		 -- if(nPersentValue ~= 0) then
			-- str2 = "#H(+"..nPersentValue..")"
		 -- end
		if(g_OtherMartial_Rigth_ShuxingText[i] ~= nil) then
			g_OtherMartial_Rigth_ShuxingText[i]:SetText(str1)
			-- g_OtherMartial_Rigth_ShuxingText1[i]:SetText(str2)
			-- g_OtherMartial_Rigth_ShuxingText2[i]:SetText(str3)
		end
		
	end
	local nLevel = MaritialSys:GetMaritiaLevel("other")
	OtherMartial_WuYi_List2_part2_text:SetText(ScriptGlobal_Format("#{WYXT_20170803_30}",nLevel))
end
--刷新精通显示标志
function OtherMartial_WuYi_RefreshJingTong()
	-- for i = 1, table.getn(g_OtherMartial_WuYi_ShuXingJingTong) do
		-- g_OtherMartial_WuYi_ShuXingJingTong[i][1]:Hide()
		-- g_OtherMartial_WuYi_ShuXingJingTong[i][2]:Hide()
	-- end
	for i = 1, g_OtherMartial_WuYi_JingTongMaxIndex do
		local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(i - 1,"other")
		if(nLevel > 0 ) then
			-- g_OtherMartial_WuYi_ShuXingJingTong[nId + 1][1]:Show()
			-- g_OtherMartial_WuYi_ShuXingJingTong[nId + 1][2]:Show()
			local present = MaritialSys:GetMartialAdvancePersent(nId,nLevel - 1)
			local str = ScriptGlobal_Format("#{WYXT_20170907_298}",g_OtherMartial_WuYi_ShuXing2Name[nId + 1],nLevel,present)
			--g_OtherMartial_WuYi_JingTongText[i]:SetText(str)
			--g_OtherMartial_WuYi_JingTongLevelText[i]:SetText(str)
		else
			--g_OtherMartial_WuYi_JingTongText[i]:SetText("#{WYXT_20170811_200}")
			--g_OtherMartial_WuYi_JingTongLevelText[i]:SetText("")
		end
	
	end
end

--天赋显示刷新
function OtherMartial_WuYi_TalentRefresh()
	OtherMartial_WuYi2_TalentRefreshButtons()
	OtherMartial_WuYi_TalentRefreshLayer()
end



--刷新天赋层按钮显示
function OtherMartial_WuYi2_TalentRefreshButtons()
	for i=1,g_OtherMartial_MaxTalentLayer do
		local nNeedLevel = g_OtherMartial_TalenLayerNeedLevel[i]
		local nMartialLevel = MaritialSys:GetMaritiaLevel("other")
		local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(i - 1,"other")
		local levelDesc = "#{WYXT_20170811_108}"
		local bOpen = 0
		local buttons = g_OtherMartial_TalentLayerButtons
		g_OtherMartial_TalentLayerButtons[i].btn:Hide()
		g_OtherMartial_TalentSelectButtons[i].btn:Hide()
		if(nMartialLevel >= nNeedLevel) then
			bOpen = 1
		end
		if( i == g_OtherMartial_TalentCurSelectLayer and bOpen == 1) then
			buttons = g_OtherMartial_TalentSelectButtons
		end
		buttons[i].btn:Show()
		buttons[i].lock:Show()
		buttons[i].lockhui:Hide()
		if( bOpen == 1 ) then
			if(g_OtherMartial_TalentId2Name[nId] ~= nil and nLevel > 0) then
				levelDesc = "#cfff263"..g_OtherMartial_TalentId2Name[nId]
			end
		end
		if(bOpen ~= 1) then
			--buttons[i].btn:SetProperty("Disabled", "True");
			buttons[i].btn:SetProperty("NormalImage","set:MartialWuYi01 image:WuYiButton1_Disable")
			buttons[i].btn:SetProperty("PushedImage","set:MartialWuYi02 image:WuYiButton1_PushedCheck")
			buttons[i].btn:SetProperty("HoverImage","set:MartialWuYi02  image:WuYiButton1_PushedHover")
			buttons[i].lock:Hide()
			buttons[i].lockhui:Show()
			if(i == g_OtherMartial_TalentCurSelectLayer) then
				buttons[i].btn:SetCheck(1)
			else
				buttons[i].btn:SetCheck(0)
			end
		elseif(i ~= g_OtherMartial_TalentCurSelectLayer) then
			--buttons[i].btn:SetProperty("Disabled", "False");
			buttons[i].btn:SetProperty("NormalImage","set:MartialWuYi01 image:WuYiButton1_Normal")
			buttons[i].btn:SetProperty("PushedImage","set:MartialWuYi01 image:WuYiButton1_Pushed")
			buttons[i].btn:SetProperty("HoverImage","set:MartialWuYi01 image:WuYiButton1_Hover")
		end
		buttons[i].text:SetText(levelDesc)
		--buttons[i].level:SetText("#cfff263"..tostring(nNeedLevel))
		local nLevelStr = ScriptGlobal_Format("#{WYXT_20170907_280}",nLevel)
		buttons[i].talentPonint:SetText("")
		if(nLevel > 0 and g_OtherMartial_TalentId2Name[nId] ~= nil) then
			buttons[i].talentPonint:SetText(nLevelStr)
			buttons[i].lock:Hide()
			buttons[i].lockhui:Hide()
		end
	end
end
--刷新天赋描述显示
function OtherMartial_WuYi_TalentRefreshLayer()	
	local nId = (g_OtherMartial_TalentCurSelectLayer - 1) * g_OtherMartial_LayerTalentNum + 1
	if(nId <= 0 or nId > g_OtherMartial_MaxTalentID - 2) then
		return 
	end
	
	local nLayerTalentId,nLevel = MaritialSys:GetTalentLevelBylayerID(g_OtherMartial_TalentCurSelectLayer - 1,"other")
	local bValidSeclect = 0
	if(g_OtherMartial_TalentCurLayerSelectTalent > 0 and g_OtherMartial_TalentCurLayerSelectTalent <= g_OtherMartial_LayerTalentNum) then
		OtherMartial_WuYi2_Frame_Part_List2_1_Explain_Title:SetText("#gFF0FA0"..g_OtherMartial_TalentId2Name[nId + g_OtherMartial_TalentCurLayerSelectTalent - 1])
		bValidSeclect = 1
	end
	for i = 1,g_OtherMartial_LayerTalentNum do
		local ShowSelect = 0
		if(bValidSeclect == 1 and g_OtherMartial_TalentCurLayerSelectTalent == i) then
			ShowSelect = 1
		end
		if(nLevel > 0 and nLayerTalentId == (nId + i - 1)) then
			g_OtherMartial_TalentButtons[i].win:Hide()
			g_OtherMartial_TalentButtons[i].selectWin:Show()
			g_OtherMartial_TalentButtons[i].selectText:SetText("#cfff263"..g_OtherMartial_TalentId2Name[nId + i - 1])
			g_OtherMartial_TalentButtons[i].levelText:SetText("#G"..nLevel)
			g_OtherMartial_TalentButtons[i].levelText:Show()
		else
			g_OtherMartial_TalentButtons[i].win:Show()
			g_OtherMartial_TalentButtons[i].selectWin:Hide()
			g_OtherMartial_TalentButtons[i].levelText:Hide()
			g_OtherMartial_TalentButtons[i].btntext:SetText("#cfff263"..g_OtherMartial_TalentId2Name[nId + i - 1])
		end
		if(ShowSelect == 1) then
			g_OtherMartial_Talent_Image[i][1]:SetCheck(1)
			g_OtherMartial_Talent_Image[i][2]:SetCheck(1)
		else
			g_OtherMartial_Talent_Image[i][1]:SetCheck(0)
			g_OtherMartial_Talent_Image[i][2]:SetCheck(0)
		end
		local str = ScriptGlobal_Format("#{WYXT_20170811_109}",g_OtherMartial_TalentId2Name[i + nId - 1])
		g_OtherMartial_Talent_Image[i][2]:SetToolTip(str)
		g_OtherMartial_Talent_Image[i][3]:SetProperty("Image",g_OtherMartial_Talent_Id2IamgesetName[nId + i - 1])
	end
	if(nLayerTalentId ~= nId + g_OtherMartial_TalentCurLayerSelectTalent - 1) then
		nLevel = 0
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

	if(nLevel >= g_OtherMartial_Talent_MaxLevel) then
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_384}",nTalentPoint)
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_380}",g_OtherMartial_TalentId2Desc[nId + g_OtherMartial_TalentCurLayerSelectTalent - 1][nTalentPoint])
	else
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_379}",nTalentPoint)
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_380}",g_OtherMartial_TalentId2Desc[nId + g_OtherMartial_TalentCurLayerSelectTalent - 1][nTalentPoint])
		local MartialLevel = MaritialSys:GetMaritiaLevel()
		local nNeedMartialLevel = MaritialSys:GetTalentNeedMartialLevel(g_OtherMartial_TalentCurSelectLayer-1,nTalentPoint + 1)
		str1 = str1.."#r".."#{WYXT_20170907_381}"
		if(MartialLevel >= nNeedMartialLevel ) then
			str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_382}",nNeedMartialLevel)
		else
			str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_383}",nNeedMartialLevel)
		end
		str1 = str1.."#r"..ScriptGlobal_Format("#{WYXT_20170907_380}",g_OtherMartial_TalentId2Desc[nId + g_OtherMartial_TalentCurLayerSelectTalent - 1][nTalentPoint+1])
	end
	
	OtherMartial_WuYi2_Frame_Part_List2_1_Explain_Text:SetText(str1)
end

function OtherMartial_WuYi_ShowTalentNextTooltip()
	local nId = (g_OtherMartial_TalentCurSelectLayer - 1) * g_OtherMartial_LayerTalentNum + g_OtherMartial_TalentCurLayerSelectTalent
	local nLayerTalentId,nLevel = MaritialSys:GetTalentLevelBylayerID(g_OtherMartial_TalentCurSelectLayer - 1)
	if(nId ~= nLayerTalentId or nLevel < 0) then
		nLevel = 1
	else
		nLevel = nLevel + 1
	end
	if(g_OtherMartial_TalentCurSelectLayer >=1 and g_OtherMartial_TalentCurSelectLayer <= g_OtherMartial_MaxTalentLayer ) then
		if(g_OtherMartial_TalentCurLayerSelectTalent >=1 and g_OtherMartial_TalentCurLayerSelectTalent <= g_OtherMartial_LayerTalentNum) then
			local strNextTip = ScriptGlobal_Format("#{WYXT_20170907_278}",tostring(g_OtherMartial_TalentId2Desc[nId][nLevel]))
			if(nLevel - 1 >= g_OtherMartial_Talent_MaxLevel) then
				strNextTip = "#{WYXT_20170907_279}"
			end
			OtherMartial_WuYi2_Frame_Part_List2_1_Explain_NextButton:SetToolTip(strNextTip)
			return
		end
	end
	OtherMartial_WuYi2_Frame_Part_List2_1_Explain_NextButton:SetToolTip()
end

--天赋层分页切换
function OtherMartial_WuYi_TalentFenYeSwitch(nLayer)
	if(nLayer > 0 and nLayer <= g_OtherMartial_MaxTalentLayer ) then
		-- local nMartialLevel = MaritialSys:GetMaritiaLevel("other")
		-- local nNeedLevel = g_OtherMartial_TalenLayerNeedLevel[nLayer]
		-- if(nMartialLevel >= nNeedLevel) then
			g_OtherMartial_TalentCurSelectLayer = nLayer
			--默认选中学习的那个，如果没有学习的，就选中第一个
			g_OtherMartial_TalentCurLayerSelectTalent = 1
			local nId,nLevel = MaritialSys:GetTalentLevelBylayerID(nLayer - 1,"other")
			if(nId > 0) then
				g_OtherMartial_TalentCurLayerSelectTalent = (nId - (math.floor(nId/g_OtherMartial_LayerTalentNum) * g_OtherMartial_LayerTalentNum));
				if(g_OtherMartial_TalentCurLayerSelectTalent == 0) then
					g_OtherMartial_TalentCurLayerSelectTalent = 3
				end
			end
		-- end
	end
	OtherMartial_WuYi_TalentRefresh()

end
--天赋选中切换
function OtherMartial_WuYi_LayerTalentSwitch(nIndex)
	if(nIndex <=0 or nIndex > g_OtherMartial_LayerTalentNum) then
		return
	end
	g_OtherMartial_TalentCurLayerSelectTalent = nIndex
	OtherMartial_WuYi_TalentRefreshLayer()
end

function OtherMartial_WuYi_BangZhuClick(nIndex)
	PushEvent("MARTIAL_SHOW_HELP",nIndex)
end

function OtherMartial_WuYi_CalcAdvancePersent(nIndex)
	local nPersent = 0
	for i=1,g_OtherMartial_WuYi_JingTongMaxIndex do
		local nId,nLevel = MaritialSys:GetMartialAdvanceByIndex(i - 1,"other")
		if(nId == nIndex and nLevel > 0) then
			nPersent = nPersent + MaritialSys:GetMartialAdvancePersent(nId,nLevel - 1)
		end
	end
	return nPersent
end

--===============================================
-- 打开玩家装备UI
--===============================================
function OtherMartial_WuYi_SelfEquip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
	this:Hide()
end

--===============================================
-- 打开玩家资料UI
--===============================================
function OtherMartial_WuYi_SelfData_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
	this:Hide()
end

function OtherMartial_WuYi_Pet_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
	this:Hide()
end

--武魂

function OtherMartial_WuYi_Wuhun_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
	this:Hide()
end

--经脉
function OtherMartial_WuYi_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
	this:Hide()
end

--神木王鼎
function OtherMartial_WuYi_ShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local nLevel = CachedTarget:GetData("LEVEL",1);
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" );
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			this:Hide()
		end
	end	
end

function OtherMartial_WuYi_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end



function OtherMartial_WuYi_Miji_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end

function OtherMartial_WuYi_Infant_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherMartial_WuYi_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherMartial_WuYi_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
	this:Hide()
end

function OtherMartial_WuYi_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1);

	SystemSetup:OpenRidePage("other");
	this:Hide();
end

function OtherMartial_WuYi_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function OtherMartial_WuYi_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
	this:Hide()
end

function OtherMartial_WuYi_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherMartial_WuYi_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function OtherMartial_WuYi_ShowPage()

	for i = 1, table.getn(g_OtherMartial_WuYi_Page) do
		g_OtherPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	OtherMartial_WuYi_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_OtherPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_OtherMartial_WuYi_Page) do
			if i ~= nOtherPageNumber then
				g_OtherPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_OtherPageOrder = {}
	g_OtherPageCount = 0
	for i = 1, table.getn(g_OtherMartial_WuYi_Page) do
		if OtherMartial_WuYi_CheckPage(i) == 1 then
			g_OtherPageCount = g_OtherPageCount + 1
			g_OtherPageButton[g_OtherPageCount]:Show()
			g_OtherPageButton[g_OtherPageCount]:SetText(g_OtherMartial_WuYi_Page[i].Text)	
			g_OtherPageOrder[g_OtherPageCount] = i
		end
	end
	
end

function OtherMartial_WuYi_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_OtherPageOrder[idx]
	
	if idx == 1 then--装备
		OtherMartial_WuYi_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		OtherMartial_WuYi_SelfData_Switch()
	elseif idx == 3 then--珍兽
		OtherMartial_WuYi_Pet_Switch()
	elseif idx == 4 then--子女
		OtherMartial_WuYi_Infant_Switch()
	elseif idx == 5 then--武魂
		OtherMartial_WuYi_Wuhun_Switch()
	elseif idx == 6 then--秘籍
		OtherMartial_WuYi_Miji_Page_Switch()
	elseif idx == 7 then--真元
		OtherMartial_WuYi_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		OtherMartial_WuYi_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		OtherMartial_WuYi_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		OtherMartial_WuYi_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		OtherMartial_WuYi_OpenBaoJian()
	elseif idx == 12 then--武意
		--OtherHuanLing_OpenWuYi()
	elseif idx == 13 then--神器
		OtherMartial_WuYi_OpenShenQi()
	elseif idx == 14 then--星盘
		OtherMartial_WuYi_Armor_Page_Switch()
	elseif idx == 15 then--名物
		OtherMartial_WuYi_CangPin_Page_Switch()
	end
end

function OtherMartial_WuYi_CheckPage(idx)
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
	elseif idx == 6 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 7 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 8 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 9 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	end
	return 0
end

function OtherMartial_WuYi_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end

