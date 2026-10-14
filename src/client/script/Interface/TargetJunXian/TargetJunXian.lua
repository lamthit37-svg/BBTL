
local g_MatchTestBeginTime = 20141215					-- [帮会跨服测试赛]期间屏蔽
local g_MatchTestEndTime = 20141228
local g_LongMenMatchTestBeginTime = 20141128
local g_LongMenMatchTestEndTime = 20141204

local g_TargetJunXian_Frame_UnifiedXPosition = 0;		-- 初始化位置X
local g_TargetJunXian_Frame_UnifiedYPosition = 0;		-- 初始化位置Y

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetJunXian_Page = {
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

local g_TargetPageButton = {}
local g_TargetPageCount = 0
local g_TargetPageOrder = {}

local g_EffectName = {
	[ 1 ] = "#{JXJW_140922_12}",	-- 散功
	[ 2 ] = "#{JXJW_140922_14}",	-- 封印
	[ 3 ] = "#{JXJW_140922_13}",	-- 围困
	[ 4 ] = "#{JXJW_140922_11}",	-- 失明
	[ 5 ] = "#{JXJW_140922_16}",	-- 麻痹
	[ 6 ] = "#{JXJW_140922_17}",	-- 封穴
	[ 7 ] = "#{JXJW_140922_15}",	-- 昏睡
}

local g_EffectImageTipName = {

	[ 1 ] = "#{HXYSJ_141031_79}",	-- 散功
	[ 2 ] = "#{HXYSJ_141031_80}",	-- 封印
	[ 3 ] = "#{HXYSJ_141031_81}",	-- 围困
	[ 4 ] = "#{HXYSJ_141031_82}",	-- 失明
	[ 5 ] = "#{HXYSJ_141031_83}",	-- 麻痹
	[ 6 ] = "#{HXYSJ_141031_84}",	-- 封穴
	[ 7 ] = "#{HXYSJ_141031_85}",	-- 昏睡
}

local g_EffectImage = {

	active = {
					[ 1 ] = "set:JunXian_02 image:JunXian_JianSanGong_Light",		--散功
					[ 2 ] = "set:JunXian_02 image:JunXian_JianFengYin_Light",		--封印
					[ 3 ] = "set:JunXian_02 image:JunXian_JianWeiKun_Light",		--围困
					[ 4 ] = "set:JunXian_02 image:JunXian_JianShiMing_Light",		--失明
					[ 5 ] = "set:JunXian_02 image:JunXian_JianMaBi_Light",			--麻痹
					[ 6 ] = "set:JunXian_02 image:JunXian_JianFengXue_Light",		--封穴
					[ 7 ] = "set:JunXian_02 image:JunXian_JianHunShui_Light",		--昏睡
	} ,
	
	unactive = {
					[ 1 ] = "set:JunXian_02 image:JunXian_JianSanGong_Dark",	-- 散功
					[ 2 ] = "set:JunXian_02 image:JunXian_JianFengYin_Dark",	-- 封印
					[ 3 ] = "set:JunXian_02 image:JunXian_JianWeiKun_Dark",	-- 围困
					[ 4 ] = "set:JunXian_02 image:JunXian_JianShiMing_Dark",	-- 失明
					[ 5 ] = "set:JunXian_02 image:JunXian_JianMaBi_Dark",		-- 麻痹
					[ 6 ] = "set:JunXian_02 image:JunXian_JianFengXue_Dark",	-- 封穴
					[ 7 ] = "set:JunXian_02 image:JunXian_JianHunShui_Dark",	-- 昏睡
	}

}

local g_EffectAttribInfo = {
	[ 1 ] = "#{HXYSJ_141031_62}",		-- 散功
	[ 2 ] = "#{HXYSJ_141031_63}",		-- 封印
	[ 3 ] = "#{HXYSJ_141031_64}",		-- 围困
	[ 4 ] = "#{HXYSJ_141031_65}",		-- 失明
	[ 5 ] = "#{HXYSJ_141031_66}",		-- 麻痹
	[ 6 ] = "#{HXYSJ_141031_67}",		-- 封穴
	[ 7 ] = "#{HXYSJ_141031_68}",		-- 昏睡
}

local g_EffectAttribInfoRefix = {
	[ 1 ] = "#{HXYSJ_141031_69}",		-- 散功
	[ 2 ] = "#{HXYSJ_141031_70}",		-- 封印
	[ 3 ] = "#{HXYSJ_141031_71}",		-- 围困
	[ 4 ] = "#{HXYSJ_141031_72}",		-- 失明
	[ 5 ] = "#{HXYSJ_141031_73}",		-- 麻痹
	[ 6 ] = "#{HXYSJ_141031_74}",		-- 封穴
	[ 7 ] = "#{HXYSJ_141031_75}",		-- 昏睡
}

local g_EquipBkImage = {
	[ 0 ] = "set:JunXian_04 image:JunXian_HaoXiaYin_0" ,
	[ 1 ] = "set:JunXian_03 image:JunXian_HaoXiaYin_1",
	[ 2 ] = "set:JunXian_03 image:JunXian_HaoXiaYin_2",	
	[ 3 ] = "set:JunXian_02 image:JunXian_HaoXiaYin_3",	
	[ 4 ] = "set:JunXian_02 image:JunXian_HaoXiaYin_4",	
	[ 5 ] = "set:JunXian_02 image:JunXian_HaoXiaYin_5",	
	[ 6 ] = "set:JunXian_02 image:JunXian_HaoXiaYin_6",	
	[ 7 ] = "set:JunXian_02 image:JunXian_HaoXiaYin_7",	
	[ 8 ] = "set:JunXian_02 image:JunXian_HaoXiaYin_8",	
}

local g_EffectLevelImage = {

	[ 1 ] = {
					[0]	=	"set:JunXian_03 image:JunXian_JianSanGong_0"	,
					[1]	=	"set:JunXian_03 image:JunXian_JianSanGong_1"	,
					[2]	=	"set:JunXian_03 image:JunXian_JianSanGong_2"	,
					[3]	=	"set:JunXian_03 image:JunXian_JianSanGong_3"	,
					[4]	=	"set:JunXian_03 image:JunXian_JianSanGong_4"	,
					[5]	=	"set:JunXian_03 image:JunXian_JianSanGong_5"	,
					[6]	=	"set:JunXian_03 image:JunXian_JianSanGong_6"	,
					[7]	=	"set:JunXian_03 image:JunXian_JianSanGong_7"	,
					[8]	=	"set:JunXian_03 image:JunXian_JianSanGong_8"	,
					[9]	=	"set:JunXian_03 image:JunXian_JianSanGong_9"	,
					[10]	=	"set:JunXian_03 image:JunXian_JianSanGong_10"	,
					[11]	=	"set:JunXian_03 image:JunXian_JianSanGong_11"	,
					[12]	=	"set:JunXian_03 image:JunXian_JianSanGong_12"	,
					[13]	=	"set:JunXian_03 image:JunXian_JianSanGong_13"	,
					[14]	=	"set:JunXian_03 image:JunXian_JianSanGong_14"	,
					[15]	=	"set:JunXian_03 image:JunXian_JianSanGong_15"	,
					[16]	=	"set:JunXian_03 image:JunXian_JianSanGong_16"	,
					[17]	=	"set:JunXian_03 image:JunXian_JianSanGong_17"	,
					[18]	=	"set:JunXian_03 image:JunXian_JianSanGong_18"	,
					[19]	=	"set:JunXian_03 image:JunXian_JianSanGong_19"	,
					[20]	=	"set:JunXian_03 image:JunXian_JianSanGong_20"	,
	},
	
	[ 2 ] = {
					[0]	=	"set:JunXian_03 image:JunXian_JianFengYin_0"	,
					[1]	=	"set:JunXian_03 image:JunXian_JianFengYin_1"	,
					[2]	=	"set:JunXian_03 image:JunXian_JianFengYin_2"	,
					[3]	=	"set:JunXian_03 image:JunXian_JianFengYin_3"	,
					[4]	=	"set:JunXian_03 image:JunXian_JianFengYin_4"	,
					[5]	=	"set:JunXian_03 image:JunXian_JianFengYin_5"	,
					[6]	=	"set:JunXian_03 image:JunXian_JianFengYin_6"	,
					[7]	=	"set:JunXian_03 image:JunXian_JianFengYin_7"	,
					[8]	=	"set:JunXian_03 image:JunXian_JianFengYin_8"	,
					[9]	=	"set:JunXian_03 image:JunXian_JianFengYin_9"	,
					[10]	=	"set:JunXian_03 image:JunXian_JianFengYin_10"	,
					[11]	=	"set:JunXian_03 image:JunXian_JianFengYin_11"	,
					[12]	=	"set:JunXian_03 image:JunXian_JianFengYin_12"	,
					[13]	=	"set:JunXian_03 image:JunXian_JianFengYin_13"	,
					[14]	=	"set:JunXian_03 image:JunXian_JianFengYin_14"	,
					[15]	=	"set:JunXian_03 image:JunXian_JianFengYin_15"	,
					[16]	=	"set:JunXian_03 image:JunXian_JianFengYin_16"	,
					[17]	=	"set:JunXian_03 image:JunXian_JianFengYin_17"	,
					[18]	=	"set:JunXian_03 image:JunXian_JianFengYin_18"	,
					[19]	=	"set:JunXian_03 image:JunXian_JianFengYin_19"	,
					[20]	=	"set:JunXian_03 image:JunXian_JianFengYin_20"	,
	},
	
	[ 3 ] = {
					[0]	=	"set:JunXian_03 image:JunXian_JianWeiKun_0"	,
					[1]	=	"set:JunXian_03 image:JunXian_JianWeiKun_1"	,
					[2]	=	"set:JunXian_03 image:JunXian_JianWeiKun_2"	,
					[3]	=	"set:JunXian_03 image:JunXian_JianWeiKun_3"	,
					[4]	=	"set:JunXian_03 image:JunXian_JianWeiKun_4"	,
					[5]	=	"set:JunXian_03 image:JunXian_JianWeiKun_5"	,
					[6]	=	"set:JunXian_03 image:JunXian_JianWeiKun_6"	,
					[7]	=	"set:JunXian_03 image:JunXian_JianWeiKun_7"	,
					[8]	=	"set:JunXian_03 image:JunXian_JianWeiKun_8"	,
					[9]	=	"set:JunXian_03 image:JunXian_JianWeiKun_9"	,
					[10]	=	"set:JunXian_03 image:JunXian_JianWeiKun_10"	,
					[11]	=	"set:JunXian_03 image:JunXian_JianWeiKun_11"	,
					[12]	=	"set:JunXian_03 image:JunXian_JianWeiKun_12"	,
					[13]	=	"set:JunXian_03 image:JunXian_JianWeiKun_13"	,
					[14]	=	"set:JunXian_03 image:JunXian_JianWeiKun_14"	,
					[15]	=	"set:JunXian_03 image:JunXian_JianWeiKun_15"	,
					[16]	=	"set:JunXian_03 image:JunXian_JianWeiKun_16"	,
					[17]	=	"set:JunXian_03 image:JunXian_JianWeiKun_17"	,
					[18]	=	"set:JunXian_03 image:JunXian_JianWeiKun_18"	,
					[19]	=	"set:JunXian_03 image:JunXian_JianWeiKun_19"	,
					[20]	=	"set:JunXian_03 image:JunXian_JianWeiKun_20"	,
	},

	[ 4 ] = {
					[0]	=	"set:JunXian_03 image:JunXian_JianShiMing_0"	,
					[1]	=	"set:JunXian_03 image:JunXian_JianShiMing_1"	,
					[2]	=	"set:JunXian_03 image:JunXian_JianShiMing_2"	,
					[3]	=	"set:JunXian_03 image:JunXian_JianShiMing_3"	,
					[4]	=	"set:JunXian_03 image:JunXian_JianShiMing_4"	,
					[5]	=	"set:JunXian_03 image:JunXian_JianShiMing_5"	,
					[6]	=	"set:JunXian_03 image:JunXian_JianShiMing_6"	,
					[7]	=	"set:JunXian_03 image:JunXian_JianShiMing_7"	,
					[8]	=	"set:JunXian_03 image:JunXian_JianShiMing_8"	,
					[9]	=	"set:JunXian_03 image:JunXian_JianShiMing_9"	,
					[10]	=	"set:JunXian_03 image:JunXian_JianShiMing_10"	,
					[11]	=	"set:JunXian_03 image:JunXian_JianShiMing_11"	,
					[12]	=	"set:JunXian_03 image:JunXian_JianShiMing_12"	,
					[13]	=	"set:JunXian_03 image:JunXian_JianShiMing_13"	,
					[14]	=	"set:JunXian_03 image:JunXian_JianShiMing_14"	,
					[15]	=	"set:JunXian_03 image:JunXian_JianShiMing_15"	,
					[16]	=	"set:JunXian_03 image:JunXian_JianShiMing_16"	,
					[17]	=	"set:JunXian_03 image:JunXian_JianShiMing_17"	,
					[18]	=	"set:JunXian_03 image:JunXian_JianShiMing_18"	,
					[19]	=	"set:JunXian_03 image:JunXian_JianShiMing_19"	,
					[20]	=	"set:JunXian_03 image:JunXian_JianShiMing_20"	,
	},
	
	[ 5 ] = {
					[0]	=	"set:JunXian_03 image:JunXian_JianMaBi_0"	,
					[1]	=	"set:JunXian_03 image:JunXian_JianMaBi_1"	,
					[2]	=	"set:JunXian_03 image:JunXian_JianMaBi_2"	,
					[3]	=	"set:JunXian_03 image:JunXian_JianMaBi_3"	,
					[4]	=	"set:JunXian_03 image:JunXian_JianMaBi_4"	,
					[5]	=	"set:JunXian_03 image:JunXian_JianMaBi_5"	,
					[6]	=	"set:JunXian_03 image:JunXian_JianMaBi_6"	,
					[7]	=	"set:JunXian_03 image:JunXian_JianMaBi_7"	,
					[8]	=	"set:JunXian_03 image:JunXian_JianMaBi_8"	,
					[9]	=	"set:JunXian_03 image:JunXian_JianMaBi_9"	,
					[10]	=	"set:JunXian_03 image:JunXian_JianMaBi_10"	,
					[11]	=	"set:JunXian_03 image:JunXian_JianMaBi_11"	,
					[12]	=	"set:JunXian_03 image:JunXian_JianMaBi_12"	,
					[13]	=	"set:JunXian_03 image:JunXian_JianMaBi_13"	,
					[14]	=	"set:JunXian_03 image:JunXian_JianMaBi_14"	,
					[15]	=	"set:JunXian_03 image:JunXian_JianMaBi_15"	,
					[16]	=	"set:JunXian_03 image:JunXian_JianMaBi_16"	,
					[17]	=	"set:JunXian_03 image:JunXian_JianMaBi_17"	,
					[18]	=	"set:JunXian_03 image:JunXian_JianMaBi_18"	,
					[19]	=	"set:JunXian_03 image:JunXian_JianMaBi_19"	,
					[20]	=	"set:JunXian_03 image:JunXian_JianMaBi_20"	,
	},
	
	[ 6 ] = {
					[0]	=	"set:JunXian_03 image:JunXian_JianFengXue_0"	,
					[1]	=	"set:JunXian_03 image:JunXian_JianFengXue_1"	,
					[2]	=	"set:JunXian_03 image:JunXian_JianFengXue_2"	,
					[3]	=	"set:JunXian_03 image:JunXian_JianFengXue_3"	,
					[4]	=	"set:JunXian_03 image:JunXian_JianFengXue_4"	,
					[5]	=	"set:JunXian_03 image:JunXian_JianFengXue_5"	,
					[6]	=	"set:JunXian_03 image:JunXian_JianFengXue_6"	,
					[7]	=	"set:JunXian_03 image:JunXian_JianFengXue_7"	,
					[8]	=	"set:JunXian_03 image:JunXian_JianFengXue_8"	,
					[9]	=	"set:JunXian_03 image:JunXian_JianFengXue_9"	,
					[10]	=	"set:JunXian_03 image:JunXian_JianFengXue_10"	,
					[11]	=	"set:JunXian_03 image:JunXian_JianFengXue_11"	,
					[12]	=	"set:JunXian_03 image:JunXian_JianFengXue_12"	,
					[13]	=	"set:JunXian_03 image:JunXian_JianFengXue_13"	,
					[14]	=	"set:JunXian_03 image:JunXian_JianFengXue_14"	,
					[15]	=	"set:JunXian_03 image:JunXian_JianFengXue_15"	,
					[16]	=	"set:JunXian_03 image:JunXian_JianFengXue_16"	,
					[17]	=	"set:JunXian_03 image:JunXian_JianFengXue_17"	,
					[18]	=	"set:JunXian_03 image:JunXian_JianFengXue_18"	,
					[19]	=	"set:JunXian_03 image:JunXian_JianFengXue_19"	,
					[20]	=	"set:JunXian_03 image:JunXian_JianFengXue_20"	,
	},
	
	[ 7 ] = {
					[0]	=	"set:JunXian_03 image:JunXian_JianHunShui_0"	,
					[1]	=	"set:JunXian_03 image:JunXian_JianHunShui_1"	,
					[2]	=	"set:JunXian_03 image:JunXian_JianHunShui_2"	,
					[3]	=	"set:JunXian_03 image:JunXian_JianHunShui_3"	,
					[4]	=	"set:JunXian_03 image:JunXian_JianHunShui_4"	,
					[5]	=	"set:JunXian_03 image:JunXian_JianHunShui_5"	,
					[6]	=	"set:JunXian_03 image:JunXian_JianHunShui_6"	,
					[7]	=	"set:JunXian_03 image:JunXian_JianHunShui_7"	,
					[8]	=	"set:JunXian_03 image:JunXian_JianHunShui_8"	,
					[9]	=	"set:JunXian_03 image:JunXian_JianHunShui_9"	,
					[10]	=	"set:JunXian_03 image:JunXian_JianHunShui_10"	,
					[11]	=	"set:JunXian_03 image:JunXian_JianHunShui_11"	,
					[12]	=	"set:JunXian_03 image:JunXian_JianHunShui_12"	,
					[13]	=	"set:JunXian_03 image:JunXian_JianHunShui_13"	,
					[14]	=	"set:JunXian_03 image:JunXian_JianHunShui_14"	,
					[15]	=	"set:JunXian_03 image:JunXian_JianHunShui_15"	,
					[16]	=	"set:JunXian_03 image:JunXian_JianHunShui_16"	,
					[17]	=	"set:JunXian_03 image:JunXian_JianHunShui_17"	,
					[18]	=	"set:JunXian_03 image:JunXian_JianHunShui_18"	,
					[19]	=	"set:JunXian_03 image:JunXian_JianHunShui_19"	,
					[20]	=	"set:JunXian_03 image:JunXian_JianHunShui_20"	,
	},
}

local g_CtrlMilitaryRankName
local g_CtrlJueWeiRankName
local g_CtrlTotalEffectText
local g_CtrlTotalExAttrText
local g_CtrlSubTable = {}

local g_CtrlEffectName = {}
local g_CtrlEffectImage = {}
local g_CtrlEffectAnimate = {}

local g_CtrlEquipButton
local g_CtrlEquipAnimate_MaxLevel
local g_CtrlEquipBKImage
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function TargetJunXian_PreLoad()
	this : RegisterEvent( "OPEN_OTHERJUNXIAN_PAGE" );		-- 打开界面
	this : RegisterEvent( "ADJEST_UI_POS" );				-- 窗口改变
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" );		-- 窗口改变
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" );			-- 离开场景
end


--*********************************
-- OnLoad
--*********************************
function TargetJunXian_OnLoad()
	
	--军衔名称(侠位等级)
	g_CtrlMilitaryRankName = TargetJunXian_Frame_Part_text003
	--当前爵位
	g_CtrlJueWeiRankName = TargetJunXian_Frame_Part_text004
	
	g_CtrlTotalEffectText = TargetJunXian_Frame_Part_New_text002
	g_CtrlTotalExAttrText = TargetJunXian_Frame_Part_text002
	
	g_CtrlEquipButton = TargetJunXian_Frame_Part_Bk8_Icon
	g_CtrlEquipAnimate_MaxLevel = TargetJunXian_Frame_Part_Bk8_Flash
	g_CtrlEquipBKImage = TargetJunXian_Frame_Part_Bk8
	
	g_CtrlEffectName[1] =	TargetJunXian_Frame_Btn_text1
	g_CtrlEffectName[2] =	TargetJunXian_Frame_Btn_text2
	g_CtrlEffectName[3] =	TargetJunXian_Frame_Btn_text3
	g_CtrlEffectName[4] =	TargetJunXian_Frame_Btn_text4
	g_CtrlEffectName[5] =	TargetJunXian_Frame_Btn_text5
	g_CtrlEffectName[6] =	TargetJunXian_Frame_Btn_text6
	g_CtrlEffectName[7] =	TargetJunXian_Frame_Btn_text7
	
	g_CtrlEffectImage[1] =	TargetJunXian_Frame_Part_Bk1_Icon1
	g_CtrlEffectImage[2] =	TargetJunXian_Frame_Part_Bk1_Icon2
	g_CtrlEffectImage[3] =	TargetJunXian_Frame_Part_Bk1_Icon3
	g_CtrlEffectImage[4] =	TargetJunXian_Frame_Part_Bk1_Icon4
	g_CtrlEffectImage[5] =	TargetJunXian_Frame_Part_Bk1_Icon5
	g_CtrlEffectImage[6] =	TargetJunXian_Frame_Part_Bk1_Icon6
	g_CtrlEffectImage[7] =	TargetJunXian_Frame_Part_Bk1_Icon7
	
	g_CtrlEffectAnimate[1]	=	TargetJunXian_Frame_Part_Bk1_Flash1
	g_CtrlEffectAnimate[2]	=	TargetJunXian_Frame_Part_Bk1_Flash2
	g_CtrlEffectAnimate[3]	=	TargetJunXian_Frame_Part_Bk1_Flash3
	g_CtrlEffectAnimate[4]	=	TargetJunXian_Frame_Part_Bk1_Flash4
	g_CtrlEffectAnimate[5]	=	TargetJunXian_Frame_Part_Bk1_Flash5
	g_CtrlEffectAnimate[6]	=	TargetJunXian_Frame_Part_Bk1_Flash6
	g_CtrlEffectAnimate[7]	=	TargetJunXian_Frame_Part_Bk1_Flash7
	
	--子标签页
	g_CtrlSubTable = {
		Equip = TargetJunXian_SelfEquip,
		Data = TargetJunXian_SelfData,
		Pet = TargetJunXian_Pet,
		Infant = TargetJunXian_Infant,
		Wuhun = TargetJunXian_Wuhun,
		Miji = TargetJunXian_Miji,
		ZhenYuan = TargetJunXian_ZhenYuan,
		JingMai = TargetJunXian_JingMai,
		ShenDing = TargetJunXian_ShenDing,
		JunXian = TargetJunXian_JunXian,
		Ride = TargetJunXian_Ride
	}
	-- 初始化位置
	g_TargetJunXian_Frame_UnifiedXPosition = TargetJunXian_Frame:GetProperty( "UnifiedXPosition" );
	g_TargetJunXian_Frame_UnifiedYPosition = TargetJunXian_Frame:GetProperty( "UnifiedYPosition" );
	
	g_TargetPageButton[1] = TargetJunXian_SelfEquip
	g_TargetPageButton[2] = TargetJunXian_SelfData
	g_TargetPageButton[3] = TargetJunXian_Pet
	g_TargetPageButton[4] = TargetJunXian_Infant
	g_TargetPageButton[5] = TargetJunXian_Wuhun
	g_TargetPageButton[6] = TargetJunXian_Miji
	g_TargetPageButton[7] = TargetJunXian_ZhenYuan
	g_TargetPageButton[8] = TargetJunXian_JingMai
	g_TargetPageButton[9] = TargetJunXian_ShenDing
	g_TargetPageButton[10] = TargetJunXian_JunXian
	g_TargetPageButton[11] = TargetJunXian_BaoJian
	g_TargetPageButton[12] = TargetJunXian_WuYi
	g_TargetPageButton[13] = TargetJunXian_ShenQi
	g_TargetPageButton[14] = TargetJunXian_Armor
	g_TargetPageButton[15] = TargetJunXian_CangPin
	
end


--*********************************
-- OnEvent
--*********************************
function TargetJunXian_OnEvent(event)
	-- 打开UI
	if ( event == "OPEN_OTHERJUNXIAN_PAGE" ) then
		local nCurTime = tonumber( DataPool:GetServerDayTime() );
		local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
		if ( selfZoneWorldID == 9015 or selfZoneWorldID == 9031 or selfZoneWorldID == 104 ) then
			if ( nCurTime >= g_LongMenMatchTestBeginTime and nCurTime <= g_LongMenMatchTestEndTime ) then
				PushDebugMessage( "#{KFCSS_141110_24}" );
				return
			end
		else
			if ( nCurTime >= g_MatchTestBeginTime and nCurTime <= g_MatchTestEndTime ) then
				PushDebugMessage( "#{KFCSS_141110_18}" );
				return
			end
		end

		if ( this:IsVisible() ) then
			return
		end
		
		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~= "number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1)
		
		-- 位置
		local nUIPos = Variable:GetVariable( "OtherUnionPos" );
		TargetJunXian_Frame:SetProperty( "UnifiedPosition", nUIPos );
		-- 更新UI
		TargetJunXian_OnUpdateJunxianUI();
		-- 选项
		TargetJunXian_ShowPage()
		-- 显示
		this:Show();
	elseif ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		TargetJunXian_Frame:SetProperty( "UnifiedXPosition", g_TargetJunXian_Frame_UnifiedXPosition );
		TargetJunXian_Frame:SetProperty( "UnifiedYPosition", g_TargetJunXian_Frame_UnifiedYPosition );
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end


--*********************************
-- 清空控件
--*********************************
function TargetJunXian_CleanupUIControls()
	

	--军衔名称(侠位等级)
	g_CtrlMilitaryRankName:SetText( "" )
	g_CtrlMilitaryRankName:SetToolTip("#{HXYSJ_141031_197}")
	--当前爵位
	g_CtrlJueWeiRankName:SetText("")
	-- 属性区域
	g_CtrlTotalEffectText:SetText( "" )
	g_CtrlTotalExAttrText:SetText( "" )
	
	g_CtrlEquipButton:SetActionItem(-1)
	g_CtrlEquipBKImage:SetProperty( "Image", g_EquipBkImage[0] )
	g_CtrlEquipAnimate_MaxLevel:Hide()
	
	for i = 1 , 7 do
		
		g_CtrlEffectName[ i ]:SetProperty( "Image", g_EffectLevelImage[ i ][ 0 ] )
		g_CtrlEffectImage[ i ]:SetProperty( "Image", g_EffectImage.unactive[ i ] )
		g_CtrlEffectImage[i]:SetToolTip("#{HXYSJ_141031_100}")
		g_CtrlEffectAnimate[i]:Hide()
	
	end	
	TargetJunXian_OnUpdateSubTableUI()
end


--*********************************
-- 子标签页
--*********************************
function TargetJunXian_OnUpdateSubTableUI()
	-- 子标签页
	g_CtrlSubTable.Equip:SetCheck( 0 );
	g_CtrlSubTable.Data:SetCheck( 0 );
	g_CtrlSubTable.Pet:SetCheck( 0 );
	g_CtrlSubTable.Infant:SetCheck( 0 );
	g_CtrlSubTable.Wuhun:SetCheck( 0 );
	g_CtrlSubTable.Miji:SetCheck( 0 );
	g_CtrlSubTable.ZhenYuan:SetCheck( 0 );
	g_CtrlSubTable.JingMai:SetCheck( 0 );
	g_CtrlSubTable.ShenDing:SetCheck( 0 );
	g_CtrlSubTable.JunXian:SetCheck( 1 );
	g_CtrlSubTable.Ride:SetCheck( 0 );
end


--*********************************
-- 更新军衔界面
--*********************************
function TargetJunXian_OnUpdateJunxianUI()
	-- 清空控件
	TargetJunXian_CleanupUIControls()
	
	--军衔名称(侠位等级)
	local nRankLvl = TargetJunXian_GetMilitaryRankLvl();
	if nRankLvl and nRankLvl > 0 then
		local szName = GetMilitaryRankName(nRankLvl) 
		strTemp = ScriptGlobal_Format("#{HXYSJ_141031_94}", tostring( szName) )
		g_CtrlMilitaryRankName:SetText( strTemp)
	else
		g_CtrlMilitaryRankName:SetText("#{HXYSJ_141031_93}")
	end
	
	--当前爵位
	local nJueWeiLevel = CachedTarget:GetData( "NobilityLevel" )
	if nJueWeiLevel and nJueWeiLevel > 0 then
		local strJueWeiName = Lua_GetNobilityName(nJueWeiLevel)
		local strTemp = ScriptGlobal_Format("#{HXYSJ_141031_95}", tostring( strJueWeiName ))
		g_CtrlJueWeiRankName:SetText(strTemp)  
		g_CtrlJueWeiRankName:SetToolTip("#{HXYSJ_141031_97}")
	else
		g_CtrlJueWeiRankName:SetText("#{HXYSJ_141031_96}")
		g_CtrlJueWeiRankName:SetToolTip("#{HXYSJ_141031_98}")
	end
	
	g_CtrlTotalEffectText:SetText("#{HXYSJ_141031_99}")
	g_CtrlTotalExAttrText:SetText("#{HXYSJ_141031_99}") 
	
	g_CtrlEquipButton:SetActionItem(-1)
	local ActionHXY = EnumAction(21,"targetequip")
	if ActionHXY and ActionHXY:GetID() ~= 0 then
		
		local nEquipLevel = CachedTarget:Lua_GetHXYLevel(  )
		g_CtrlEquipButton:SetActionItem(ActionHXY:GetID())
		
		if nEquipLevel and nEquipLevel >= 100 then
			g_CtrlEquipAnimate_MaxLevel:Show()
		end
		
		local nEquipGrade = CachedTarget:Lua_GetHXYGrade() 
		if nEquipGrade ~= nil and g_EquipBkImage[nEquipGrade] ~= nil then
			g_CtrlEquipBKImage:SetProperty("Image" , g_EquipBkImage[nEquipGrade] )
		end
		
		local nEffectStr = ""
		local nExAttrStr = ""
		local nIsAnyEffectActive = 0
		for	i = 1, 7 do
			
			local nIndex , iEffectLevel, iCost , iNeedHXYLevel , iValue = CachedTarget:Lua_GetHXYEffect( i - 1 )
			
			if nIndex ~= nil then
				
				if iEffectLevel == 0 then  --没激活
					g_CtrlEffectImage[ i ]:SetProperty( "Image", g_EffectImage.unactive[ i ] )
										
					strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_101}", g_EffectImageTipName[i] )
					g_CtrlEffectImage[ i ]:SetToolTip(strTemp)
					
				else
					g_CtrlEffectImage[ i ]:SetProperty( "Image", g_EffectImage.active[ i ] )
					strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_102}", g_EffectImageTipName[i] ,  tostring(iEffectLevel) ,g_EffectImageTipName[i] , tostring(iValue))
					--有爵位
					if nJueWeiLevel and nJueWeiLevel > 0 and Lua_IsInZBSScene()==0 then
					
						local nAddValueEffect = CachedTarget:Lua_GetHXYEffectRefixValue( i - 1 )
						if nAddValueEffect then
							strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_141}", g_EffectImageTipName[i] ,  tostring(iEffectLevel) ,g_EffectImageTipName[i] , tostring(iValue),tostring(nAddValueEffect))
						end
					end
					g_CtrlEffectImage[ i ]:SetToolTip(strTemp)
					
					strTemp =  ScriptGlobal_Format(g_EffectAttribInfo[i] , tostring(iValue))
					
					if nJueWeiLevel and nJueWeiLevel > 0 and Lua_IsInZBSScene()==0 then
					
						local nAddValueEffect = CachedTarget:Lua_GetHXYEffectRefixValue( i - 1 )
						if nAddValueEffect then
							strTemp =  ScriptGlobal_Format(g_EffectAttribInfoRefix[i] , tostring(iValue) , tostring(nAddValueEffect))
						end
					end
					nEffectStr = nEffectStr..strTemp.."#r"
					nIsAnyEffectActive = 1
					if iEffectLevel >= 20 then
						g_CtrlEffectAnimate[ i ] : Show()
					end
				end
				g_CtrlEffectName[ i ]:SetProperty( "Image", g_EffectLevelImage[ i ][ iEffectLevel ] )
			end
			
			local strExAttr = CachedTarget:Lua_GetHXYExAttrInfo( i - 1 )
			if strExAttr then
				nExAttrStr = nExAttrStr.."#cfff263"..tostring(strExAttr)
			end
			
			if nJueWeiLevel and nJueWeiLevel > 0 then
				local nRefixValue = CachedTarget:Lua_GetHXYExAttrRefixValue( i - 1 )
				nExAttrStr = nExAttrStr.."#B(+"..tostring(nRefixValue)..")#r"
			else
			
				nExAttrStr = nExAttrStr.."#r"
			end
		end
		g_CtrlTotalExAttrText:SetText(nExAttrStr)
		if nIsAnyEffectActive > 0 then
			g_CtrlTotalEffectText:SetText(nEffectStr)
		else
			g_CtrlTotalEffectText:SetText("#{HXYSJ_141031_198}")
		end
	end
	
	TargetJunXian_UpdateGemContainer()
end


--*********************************
-- 获取军衔等级
--*********************************
function TargetJunXian_GetMilitaryRankLvl()
	local nRankLvl = 0;
	local nMaxMilitaryLvl = GetMaxMilitaryRankLevel();
	local nMilitaryExp = CachedTarget:GetData( "MILITARYEXP", 1 );
	for i = 1, nMaxMilitaryLvl do
		local nExpPhase = GetMilitaryRankExpPhase( i );
		if ( nMilitaryExp >= nExpPhase ) then
			nRankLvl = i;
		end
	end

	return nRankLvl;
end


-----------------------------------------------------------------------------
------------------------------------ 事件 -----------------------------------
-----------------------------------------------------------------------------


--*********************************
-- Frame 移动
--*********************************
function TargetJunXian_OnMoved()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
end


--*********************************
-- 关闭按钮
--*********************************
function TargetJunXian_CloseFunction()
	TargetJunXian_CleanupUIControls()
	PushEvent( "GEM_CONTAINER_CHECK", 18, 3 )
	this:Hide();
end

function TargetJunXian_ShowHelp()

	OpenYBShopReference("#{HXYSJ_141031_92}")
end
--*********************************
-- [装备]标签
--*********************************
function TargetJunXian_SelfEquip_Page_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenEquipFrame( "other" );
	this:Hide();
end


--*********************************
-- [资料]标签
--*********************************
function TargetJunXian_SelfData_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenPrivatePage( "other" )
	this:Hide();
end


--*********************************
-- [珍兽]标签
--*********************************
function TargetJunXian_Pet_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenPetFrame( "other" );
	this:Hide();
end


--*********************************
-- [子女]标签
--*********************************
function TargetJunXian_Infant_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local bRet = Infant:Other_ToggleInfantPage();
	if ( bRet == 1 ) then
		this:Hide()
	else
		TargetJunXian_OnUpdateSubTableUI();
	end
end


--*********************************
-- [武魂]标签
--*********************************
function TargetJunXian_Wuhun_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenOtherWuhun();
	this:Hide();
end


--*********************************
-- [秘籍]标签
--*********************************
function TargetJunXian_Miji_Page_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenOtherMiji();
	this:Hide()
end


--*********************************
-- [真元]标签
--*********************************
function TargetJunXian_ZhenYuan_Page_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if ( bRet == 1 ) then
		this:Hide()
	else
		TargetJunXian_OnUpdateSubTableUI();
	end
end


--*********************************
-- [经脉]标签
--*********************************
function TargetJunXian_JingMai_Page_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenOtherJingMai();
	this:Hide();
end


--*********************************
-- [神鼎]标签
--*********************************
function TargetJunXian_ShenDing_Page_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local nLevel = CachedTarget:GetData( "LEVEL", 1 );
	if ( nLevel == nil or nLevel < 15 ) then
		PushDebugMessage( "#{XLDL_140606_63}" );
		TargetJunXian_OnUpdateSubTableUI();
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			this:Hide()
		else
			TargetJunXian_OnUpdateSubTableUI();
		end
	end
end


--*********************************
-- [军衔]标签
--*********************************
function TargetJunXian_JunXian_Page_Switch()
	-- 子标签页状态
	TargetJunXian_OnUpdateSubTableUI();
end


--*********************************
-- [骑乘]标签
--*********************************
function TargetJunXian_Ride_Page_Switch()
	Variable:SetVariable( "OtherUnionPos", TargetJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenRidePage( "other" );
	this:Hide();
end

function TargetJunXian_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end


function TargetJunXian_BaoShiCheck_Clicked()
   PushEvent( "GEM_CONTAINER_CHECK", 18, 1 )
end

local g_TargetJunXian_TypeList =
{
	[1]  = { name="#{WBSS_120727_34}", gemConIndex=0,  equipIndex=0,  },    --- 武器
	[2]  = { name="#{WBSS_120727_26}", gemConIndex=11, equipIndex=14, },    --- 护腕
	[3]  = { name="#{WBSS_120727_30}", gemConIndex=6,  equipIndex=6,  },    --- 戒指（上）
	[4]  = { name="#{WBSS_120727_31}", gemConIndex=8,  equipIndex=11, },    --- 戒指（下）
	[5]  = { name="#{WBSS_120727_32}", gemConIndex=9,  equipIndex=12, },    --- 护符（上）
	[6]  = { name="#{WBSS_120727_33}", gemConIndex=10, equipIndex=13, },    --- 护符（下）
	[7]  = { name="#{WBSS_120727_35}", gemConIndex=2,  equipIndex=2,  },    --- 衣服
	[8]  = { name="#{WBSS_120727_24}", gemConIndex=1,  equipIndex=1,  },    --- 帽子
	[9]  = { name="#{WBSS_120727_25}", gemConIndex=12, equipIndex=15, },    --- 肩膀
	[10] = { name="#{WBSS_120727_27}", gemConIndex=3,  equipIndex=3,  },    --- 手套
	[11] = { name="#{WBSS_120727_28}", gemConIndex=5,  equipIndex=5,  },    --- 腰带
	[12] = { name="#{WBSS_120727_29}", gemConIndex=4,  equipIndex=4,  },    --- 鞋子
	[13] = { name="#{WBSS_120727_36}", gemConIndex=7,  equipIndex=7,  },    --- 项链
	[14] = { name="#{WBSS_120727_37}", gemConIndex=13, equipIndex=17, },    --- 暗器
	[15] = { name="#{WBSS_120727_39}", gemConIndex=15, equipIndex=19, },    --- 龙纹
	[16] = { name="#{WBSS_120727_38}", gemConIndex=14, equipIndex=18, },    --- 武魂
	[17] = { name="符石传说", gemConIndex=16, equipIndex=20, },    --- 符石传说
	[18] = { name="#{HXYSJ_141031_131}", gemConIndex=17, equipIndex=21, },    --- 豪侠印
}


--- 显示人身上的宝石装备位
function TargetJunXian_UpdateGemContainer( )
    local ret = TargetJunXian_Can_SwitchGem( 18 )
    if ret == 1 then
        --- 正常态：玩家学会万宝随身互换，装备位上存在装备且所有装备位上的宝石都可以进行互换时
        TargetJunXian_Frame_Part_Bk8_green : Enable()
        TargetJunXian_Frame_Part_Bk8_green : Show()
        TargetJunXian_Frame_Part_Bk8_green : SetToolTip( "#{WBSS_120727_44}" )
        TargetJunXian_Frame_Part_Bk8_red   : Hide()
    else
        --- 异常态：玩家学会万宝随身互换，装备位上不存在装备或非所有装备位上的宝石都可以进行互换时
        TargetJunXian_Frame_Part_Bk8_red   : Enable()
        TargetJunXian_Frame_Part_Bk8_red   : Show()
        TargetJunXian_Frame_Part_Bk8_red   : SetToolTip( "#{WBSS_120727_44}" )
        TargetJunXian_Frame_Part_Bk8_green : Hide()
    end

end

function TargetJunXian_Can_SwitchGem( curSel )
    local equipPoint = g_TargetJunXian_TypeList[curSel].equipIndex
    local gemConPos  = g_TargetJunXian_TypeList[curSel].gemConIndex

    --- 得到装备上的宝石
    local equipIndex, gemHole, equipGem1, equipGem2, equipGem3, equipGem4 = LifeAbility : Get_OtherPlayerEquip_GemInfo( equipPoint )
    local equipTypeList = {}
    local gemIndexList  = {}
    gemIndexList[1] = equipGem1
    gemIndexList[2] = equipGem2
    gemIndexList[3] = equipGem3
    gemIndexList[4] = equipGem4
    if equipIndex ~= -1 then
        for i = 1, 4 do
            if gemIndexList[i] > 0 then
                equipTypeList[i] = TargetJunXian_GetGemTypeByIndex( gemIndexList[i] )
            else
                equipTypeList[i] = -1
            end
        end
    else
        --- 没有装备
        return 0
    end

    --- 其次得到装备位上的宝石类型
    local gemConTypeList  = { }
    local bHaveGemCon     = 0       --- 装备位上是否有宝石
    local conGem1, conGem2, conGem3, conGem4 = LifeAbility : Get_OtherPlayerEquip_GemContainerInfo( gemConPos )
    gemConTypeList[1] = conGem1
    gemConTypeList[2] = conGem2
    gemConTypeList[3] = conGem3
    gemConTypeList[4] = conGem4
    for i = 1, 4 do
        if gemConTypeList[i] > 0 then
            gemConTypeList[i] = TargetJunXian_GetGemTypeByIndex( gemConTypeList[i] )
            bHaveGemCon       = 1
        else
            gemConTypeList[i] = -1
        end
    end

    if bHaveGemCon == 0 then
        return 0
    end

    --- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
    for i = 1, 4 do
        --- 如果装备位上有宝石
        if gemConTypeList[i] > 0 then
            -- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
            if equipTypeList[i] <= 0 then
                return 0
            end
            equipTypeList[i] = gemConTypeList[i]
        end
    end

    --- 判断互换后，当前装备前三孔是否会出现同类型宝石
    if equipTypeList[1] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[1] == equipTypeList[3] ) then
            return 0
        end
    end

    if equipTypeList[2] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 0
        end
    end

    if equipTypeList[3] > 0 then
        if ( equipTypeList[1] == equipTypeList[3] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 0
        end
    end

    return 1
end

--- 根据物品序列号来获得物品的类型
function TargetJunXian_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function TargetJunXian_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetJunXian_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetJunXian_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetJunXian_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function TargetJunXian_ShowPage()

	for i = 1, table.getn(g_TargetJunXian_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetJunXian_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetJunXian_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetJunXian_Page) do
		if TargetJunXian_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetJunXian_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetJunXian_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetJunXian_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		TargetJunXian_SelfData_Switch()
	elseif idx == 3 then--珍兽
		TargetJunXian_Pet_Switch()
	elseif idx == 4 then--子女
		TargetJunXian_Infant_Switch()
	elseif idx == 5 then--武魂
		TargetJunXian_Wuhun_Switch()
	elseif idx == 6 then--秘籍
		TargetJunXian_Miji_Page_Switch()
	elseif idx == 7 then--真元
		TargetJunXian_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		TargetJunXian_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		TargetJunXian_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		--TargetWuhun_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetJunXian_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetJunXian_OpenWuYi()
	elseif idx == 13 then--神器
		TargetJunXian_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetJunXian_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetJunXian_CangPin_Page_Switch()
	end
end

function TargetJunXian_CheckPage(idx)
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

function TargetJunXian_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


