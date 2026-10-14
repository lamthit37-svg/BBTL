
local g_MatchTestBeginTime = 20141215					-- [帮会跨服测试赛]期间屏蔽
local g_MatchTestEndTime = 20141228
local g_LongMenMatchTestBeginTime = 20141128
local g_LongMenMatchTestEndTime = 20141204

local g_SelfJunXian_Frame_UnifiedXPosition = 0;			-- 初始坐标X
local g_SelfJunXian_Frame_UnifiedYPosition = 0;			-- 初始坐标Y

local g_EffectName = {
	[ 1 ] = "#{JXJW_140922_12}",	-- 散功
	[ 2 ] = "#{JXJW_140922_14}",	-- 封印
	[ 3 ] = "#{JXJW_140922_13}",	-- 围困
	[ 4 ] = "#{JXJW_140922_11}",	-- 失明
	[ 5 ] = "#{JXJW_140922_16}",	-- 麻痹
	[ 6 ] = "#{JXJW_140922_17}",	-- 封穴
	[ 7 ] = "#{JXJW_140922_15}",	-- 昏睡
};

local g_EffectImageTipName = {

	[ 1 ] = "#{HXYSJ_141031_79}",	-- 散功
	[ 2 ] = "#{HXYSJ_141031_80}",	-- 封印
	[ 3 ] = "#{HXYSJ_141031_81}",	-- 围困
	[ 4 ] = "#{HXYSJ_141031_82}",	-- 失明
	[ 5 ] = "#{HXYSJ_141031_83}",	-- 麻痹
	[ 6 ] = "#{HXYSJ_141031_84}",	-- 封穴
	[ 7 ] = "#{HXYSJ_141031_85}",	-- 昏睡
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

local g_LevelUpButtonImage = {
				PushedImage = "set:ZhenYuanUI1 image:ZhenYuan_LevetUp_Pushed",
				NormalImage = "set:ZhenYuanUI1 image:ZhenYuan_LevetUp_Normal",
				HoverImage ="set:ZhenYuanUI1 image:ZhenYuan_LevetUp_Hover",
				DisabledImage ="set:ZhenYuanUI1 image:ZhenYuan_LevetUp_Disabled"
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
local g_CtrlJunXianExp
local g_CtrlJunXianHonour
local g_CtrlTotalEffectText
local g_CtrlTotalExAttrText
local g_CtrlJunXianComprehend
local g_CtrlJunXianComprehendBK
local g_CtrlJunXianComprehendIcon
local g_CtrlSubTable = {}

local g_CtrlEffectName = {}
local g_CtrlEffectImage = {}
local g_CtrlEffectButton = {}
local g_CtrlEffectAnimate = {}

local g_CtrlEquipButton
local g_CtrlEquipButton_LevelUp
local g_CtrlEquipAnimate_MaxLevel
local g_CtrlEquipBKImage
local g_CtrlEquipAnimate_LevelUp

---------------------------------------------------------------------------

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfJunXian_Page = {
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

local g_SelfJunXian_PageButton = {}
local g_SelfJunXian_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

--*********************************
-- PreLoad
--*********************************
function SelfJunXian_PreLoad()
	this : RegisterEvent( "OPEN_JUNXIAN_PAGE" );			-- 打开界面
	this : RegisterEvent( "UPDATE_SHOWRANKNAME" );			-- 军衔板
	this : RegisterEvent( "UPDATA_MILITARYEXP" );			-- 军功经验值
	this : RegisterEvent( "UPDATA_MILITARYEXCHANGEVALUE" );	-- 军功兑换值
	this : RegisterEvent( "UPDATA_COMPREHEND" );			-- 领悟值
	this : RegisterEvent( "UPDATA_MILITARYXIUWEI" );		-- 军衔修为值
	this : RegisterEvent( "UPDATE_MILITARYEFFES" );			-- 军衔效果
	this : RegisterEvent( "ADJEST_UI_POS" );				-- 窗口改变
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" );		-- 窗口改变
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" );			-- 离开场景

	this:RegisterEvent("REFRESH_EQUIP");
	this:RegisterEvent("UPDATE_NOBILITY_LV")
	this:RegisterEvent("HXY_LEVELUP_ANIMATION")
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end


--*********************************
-- OnLoad
--*********************************
function SelfJunXian_OnLoad()

	--军衔名称(侠位等级)
	g_CtrlMilitaryRankName = SelfJunXian_Frame_Part_text003
	--当前爵位
	g_CtrlJueWeiRankName = SelfJunXian_Frame_Part_text004
	--军功经验值(豪侠经验值)
	g_CtrlJunXianExp = SelfJunXian_Frame_Part_text005
	--军衔荣誉值(豪侠荣誉值)
	g_CtrlJunXianHonour = SelfJunXian_Frame_Part_text006

	g_CtrlTotalEffectText = SelfJunXian_Frame_Part_New_text002
	g_CtrlTotalExAttrText = SelfJunXian_Frame_Part_text002

	--修为值(功勋值)
	g_CtrlJunXianComprehend = SelfJunXian_Frame_Part_text007
	g_CtrlJunXianComprehendBK = SelfJunXian_Frame_Part_text007_Bk
	g_CtrlJunXianComprehendIcon = SelfJunXian_Frame_Part_text007_Icon

	--子标签页
	g_CtrlSubTable = {
		Equip = SelfJunXian_SelfEquip,
		Data = SelfJunXian_SelfData,
		Pet = SelfJunXian_Pet,
		Infant = SelfJunXian_Infant,
		Wuhun = SelfJunXian_Wuhun,
		Xiulian = SelfJunXian_Xiulian,
		Miji = SelfJunXian_Miji,
		ZhenYuan = SelfJunXian_ZhenYuan,
		JingMai = SelfJunXian_JingMai,
		ShenDing = SelfJunXian_ShenDing,
		JunXian = SelfJunXian_JunXian,
		Ride = SelfJunXian_Ride,
		OtherInfo = SelfJunXian_OtherInfo
	}

	g_CtrlEffectName[1] =	SelfJunXian_Frame_Btn_text1
	g_CtrlEffectName[2] =	SelfJunXian_Frame_Btn_text2
	g_CtrlEffectName[3] =	SelfJunXian_Frame_Btn_text3
	g_CtrlEffectName[4] =	SelfJunXian_Frame_Btn_text4
	g_CtrlEffectName[5] =	SelfJunXian_Frame_Btn_text5
	g_CtrlEffectName[6] =	SelfJunXian_Frame_Btn_text6
	g_CtrlEffectName[7] =	SelfJunXian_Frame_Btn_text7

	g_CtrlEffectImage[1] =	SelfJunXian_Frame_Part_Bk1_Icon1
	g_CtrlEffectImage[2] =	SelfJunXian_Frame_Part_Bk1_Icon2
	g_CtrlEffectImage[3] =	SelfJunXian_Frame_Part_Bk1_Icon3
	g_CtrlEffectImage[4] =	SelfJunXian_Frame_Part_Bk1_Icon4
	g_CtrlEffectImage[5] =	SelfJunXian_Frame_Part_Bk1_Icon5
	g_CtrlEffectImage[6] =	SelfJunXian_Frame_Part_Bk1_Icon6
	g_CtrlEffectImage[7] =	SelfJunXian_Frame_Part_Bk1_Icon7

	g_CtrlEffectButton[1] =	SelfJunXian_Frame_Btn_1
	g_CtrlEffectButton[2] =	SelfJunXian_Frame_Btn_2
	g_CtrlEffectButton[3] =	SelfJunXian_Frame_Btn_3
	g_CtrlEffectButton[4] =	SelfJunXian_Frame_Btn_4
	g_CtrlEffectButton[5] =	SelfJunXian_Frame_Btn_5
	g_CtrlEffectButton[6] =	SelfJunXian_Frame_Btn_6
	g_CtrlEffectButton[7] =	SelfJunXian_Frame_Btn_7

	g_CtrlEffectAnimate[1]	=	SelfJunXian_Frame_Part_Bk1_Flash1
	g_CtrlEffectAnimate[2]	=	SelfJunXian_Frame_Part_Bk1_Flash2
	g_CtrlEffectAnimate[3]	=	SelfJunXian_Frame_Part_Bk1_Flash3
	g_CtrlEffectAnimate[4]	=	SelfJunXian_Frame_Part_Bk1_Flash4
	g_CtrlEffectAnimate[5]	=	SelfJunXian_Frame_Part_Bk1_Flash5
	g_CtrlEffectAnimate[6]	=	SelfJunXian_Frame_Part_Bk1_Flash6
	g_CtrlEffectAnimate[7]	=	SelfJunXian_Frame_Part_Bk1_Flash7


	g_CtrlEquipButton = SelfJunXian_Frame_Part_Bk8_Icon
	g_CtrlEquipButton_LevelUp = SelfJunXian_Frame_Part_Bk8_Btn
	g_CtrlEquipAnimate_MaxLevel = SelfJunXian_Frame_Part_Bk8_Flash
	g_CtrlEquipBKImage = SelfJunXian_Frame_Part_Bk8
	g_CtrlEquipAnimate_LevelUp = SelfJunXian_Frame_Part_Bk8_Flash_LevelUp

	-- 初始化位置
	g_SelfJunXian_Frame_UnifiedXPosition = SelfJunXian_Frame:GetProperty( "UnifiedXPosition" );
	g_SelfJunXian_Frame_UnifiedYPosition = SelfJunXian_Frame:GetProperty( "UnifiedYPosition" );
	
	g_SelfJunXian_PageButton[1] = SelfJunXian_SelfEquip
	g_SelfJunXian_PageButton[2] = SelfJunXian_SelfData
	g_SelfJunXian_PageButton[3] = SelfJunXian_Pet
	g_SelfJunXian_PageButton[4] = SelfJunXian_Infant
	g_SelfJunXian_PageButton[5] = SelfJunXian_Wuhun
	g_SelfJunXian_PageButton[6] = SelfJunXian_Xiulian
	g_SelfJunXian_PageButton[7] = SelfJunXian_Miji
	g_SelfJunXian_PageButton[8] = SelfJunXian_ZhenYuan
	g_SelfJunXian_PageButton[9] = SelfJunXian_JingMai
	g_SelfJunXian_PageButton[10] = SelfJunXian_ShenDing
	g_SelfJunXian_PageButton[11] = SelfJunXian_JunXian
	g_SelfJunXian_PageButton[12] = SelfJunXian_BaoJian
	g_SelfJunXian_PageButton[13] = SelfJunXian_WuYi
	g_SelfJunXian_PageButton[14] = SelfJunXian_ShenQi
	g_SelfJunXian_PageButton[15] = SelfJunXian_Armor
	g_SelfJunXian_PageButton[16] = SelfJunXian_CangPin
	g_SelfJunXian_PageButton[17] = SelfJunXian_OtherInfo
	
	g_SelfJunXian_PageMask[1] = SelfJunXian_SelfEquip_tips
	g_SelfJunXian_PageMask[2] = SelfJunXian_SelfData_tips
	g_SelfJunXian_PageMask[3] = SelfJunXian_Pet_tips
	g_SelfJunXian_PageMask[4] = SelfJunXian_Infant_tips
	g_SelfJunXian_PageMask[5] = SelfJunXian_Wuhun_tips
	g_SelfJunXian_PageMask[6] = SelfJunXian_Xiulian_tips
	g_SelfJunXian_PageMask[7] = SelfJunXian_Miji_tips
	g_SelfJunXian_PageMask[8] = SelfJunXian_ZhenYuan_tips
	g_SelfJunXian_PageMask[9] = SelfJunXian_JingMai_tips
	g_SelfJunXian_PageMask[10] = SelfJunXian_ShenDing_tips
	g_SelfJunXian_PageMask[11] = SelfJunXian_JunXian_tips
	g_SelfJunXian_PageMask[12] = SelfJunXian_BaoJian_tips
	g_SelfJunXian_PageMask[13] = SelfJunXian_WuYi_tips
	g_SelfJunXian_PageMask[14] = SelfJunXian_ShenQi_tips
	g_SelfJunXian_PageMask[15] = SelfJunXian_Armor_tips
	g_SelfJunXian_PageMask[16] = SelfJunXian_CangPin_tips
	g_SelfJunXian_PageMask[17] = SelfJunXian_OtherInfo_tips
	
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


--*********************************
-- OnEvent
--*********************************
function SelfJunXian_OnEvent(event)

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT") or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		SelfJunXian_Refresh_Page_Button(nLevel)
		SelfJunXian_ShowPage()
	end
	if ( event == "OPEN_JUNXIAN_PAGE" ) then
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
		-- 位置
		local nUIPos = Variable:GetVariable( "SelfUnionPos" );
		SelfJunXian_Frame:SetProperty( "UnifiedPosition", nUIPos );

		-- 更新数据
		SelfJunXian_OnUpdateJunxianUI()
		g_CtrlEquipAnimate_LevelUp:Hide()
		-- 显示UI
		this:Show();
		local nLevel =Player:GetLevel()
		SelfJunXian_Refresh_Page_Button(nLevel)
		SelfJunXian_ShowPage()
	elseif ( event == "UPDATE_SHOWRANKNAME" and arg0 == "player" ) then
	--	if ( this:IsVisible() ) then
	--		SelfJunXian_OnUpdateJunxianUI();
	--	end
	elseif ( event == "UPDATA_MILITARYEXP" and arg0 == "player" ) then
		if ( this:IsVisible() ) then
			SelfJunXian_OnUpdateJunxianUI();
		end
	elseif ( event == "UPDATA_MILITARYEXCHANGEVALUE"
			or event == "UPDATA_COMPREHEND"
			or event == "UPDATA_MILITARYXIUWEI" ) then
		if ( this:IsVisible() ) then
			SelfJunXian_OnUpdateJunxianUI();
		end
	elseif ( event == "UPDATE_MILITARYEFFES" ) then
		if ( this:IsVisible() ) then
			SelfJunXian_OnUpdateJunxianUI();
			local nEffectLvl = tonumber( arg0 );
			if ( nEffectLvl > 0 ) then
				-- 设置定时器
				SetTimer( "SelfJunXian", "SelfJunXian_StopAnimation()", 5000 );	-- 5sec停
			end
		end
	elseif ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		SelfJunXian_Frame:SetProperty( "UnifiedXPosition", g_SelfJunXian_Frame_UnifiedXPosition );
		SelfJunXian_Frame:SetProperty( "UnifiedYPosition", g_SelfJunXian_Frame_UnifiedYPosition );
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();

	elseif( event == "REFRESH_EQUIP" and this:IsVisible() ) then
		SelfJunXian_OnUpdateJunxianUI()
	elseif( event == "UPDATE_NOBILITY_LV" and arg0 == "player"  ) then
		if ( this:IsVisible() ) then
			SelfJunXian_OnUpdateJunxianUI()
		end
	elseif event == "HXY_LEVELUP_ANIMATION" and this:IsVisible()  then

		g_CtrlEquipAnimate_LevelUp:Show()
		g_CtrlEquipAnimate_LevelUp:Play(true)
	elseif(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SelfJunXian_RefreshWuYiTip()
	end
	
	if event == "UPDATE_TOY_TIP" then
		SelfJunXian_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfJunXian_RefreshCangPinTip()
	end
end


--*********************************
-- 清空控件
--*********************************
function SelfJunXian_CleanupUIControls()

	--军衔名称(侠位等级)
	g_CtrlMilitaryRankName:SetText( "" )
	g_CtrlMilitaryRankName:SetToolTip("#{HXYSJ_141031_197}")
	--当前爵位
	g_CtrlJueWeiRankName:SetText("")
	--军功经验值(豪侠经验值)
	g_CtrlJunXianExp:SetText( "" )
	--军衔荣誉值(豪侠荣誉值)
	g_CtrlJunXianHonour:SetText( "" )
	-- 属性区域
	g_CtrlTotalEffectText:SetText( "" )
	g_CtrlTotalExAttrText:SetText( "" )

	--修为值(功勋值)
	g_CtrlJunXianComprehend:SetText( "0" )


	for i = 1 , 7 do

		g_CtrlEffectName[ i ]:SetProperty( "Image", g_EffectLevelImage[ i ][ 0 ] )
		g_CtrlEffectImage[ i ]:SetProperty( "Image", g_EffectImage.unactive[ i ] )
		g_CtrlEffectImage[i]:SetToolTip("#{HXYSJ_141031_76}")
		g_CtrlEffectButton[i]:Hide()
		g_CtrlEffectAnimate[i]:Hide()

	end

	SelfJunXian_Equip_Mask:Hide()
	g_CtrlEquipButton:SetActionItem(-1)
	g_CtrlEquipButton_LevelUp:Hide()
	g_CtrlEquipBKImage:SetProperty( "Image", g_EquipBkImage[0] )
	g_CtrlEquipAnimate_MaxLevel:Hide()

	-- 子标签页
	SelfJunXian_OnUpdateSubTableUI()
end

--*********************************
-- 子标签页
--*********************************
function SelfJunXian_OnUpdateSubTableUI()
	-- 子标签页
	g_CtrlSubTable.Equip:SetCheck( 0 );
	g_CtrlSubTable.Data:SetCheck( 0 );
	g_CtrlSubTable.Pet:SetCheck( 0 );
	g_CtrlSubTable.Infant:SetCheck( 0 );
	g_CtrlSubTable.Wuhun:SetCheck( 0 );
	g_CtrlSubTable.Xiulian:SetCheck( 0 );
	g_CtrlSubTable.Miji:SetCheck( 0 );
	g_CtrlSubTable.ZhenYuan:SetCheck( 0 );
	g_CtrlSubTable.JingMai:SetCheck( 0 );
	g_CtrlSubTable.ShenDing:SetCheck( 0 );
	g_CtrlSubTable.JunXian:SetCheck( 1 );
	g_CtrlSubTable.Ride:SetCheck( 0 );
	g_CtrlSubTable.OtherInfo:SetCheck( 0 );
end


--*********************************
-- 更新军衔界面
--*********************************
function SelfJunXian_OnUpdateJunxianUI()
	--清空控件
	SelfJunXian_CleanupUIControls()

	--军衔名称(侠位等级)
	local nRankLvl = SelfJunXian_GetMilitaryRankLvl();
	if nRankLvl and nRankLvl > 0 then
		local szName = GetMilitaryRankName(nRankLvl)
		strTemp = ScriptGlobal_Format("#{HXYSJ_141031_47}", tostring( szName) )

		g_CtrlMilitaryRankName:SetText( strTemp)

	else
		g_CtrlMilitaryRankName:SetText("#{HXYSJ_141031_48}")

	end

	--当前爵位
	local nJueWeiLevel = Player:GetData( "NobilityLevel" )
	if nJueWeiLevel and nJueWeiLevel > 0 then
		local strJueWeiName = Lua_GetNobilityName(nJueWeiLevel)
		local strTemp = ScriptGlobal_Format("#{HXYSJ_141031_49}", tostring( strJueWeiName ))
		g_CtrlJueWeiRankName:SetText(strTemp)
		g_CtrlJueWeiRankName:SetToolTip("#{HXYSJ_141031_52}")
	else
		g_CtrlJueWeiRankName:SetText("#{HXYSJ_141031_50}")
		g_CtrlJueWeiRankName:SetToolTip("#{HXYSJ_141031_53}")
	end
	--军功经验值(豪侠经验值)
	local nMaxMilitaryLvl = GetMaxMilitaryRankLevel();
	local nMilitaryExp = Player:GetData( "MILITARYEXP" );
	local nRankExpTop = GetMilitaryRankExpTop( nRankLvl )

	local strTemp = ScriptGlobal_Format("#{HXYSJ_141031_54}", tostring( nMilitaryExp ) ,tostring( nRankExpTop ))
	g_CtrlJunXianExp:SetText(strTemp);

	if ( nRankLvl < nMaxMilitaryLvl ) then
		strTemp = ScriptGlobal_Format("#{HXYSJ_141031_55}", tostring( nRankExpTop -  nMilitaryExp) )
		g_CtrlJunXianExp:SetToolTip( strTemp );
	else
		g_CtrlJunXianExp:SetToolTip( "#{HXYSJ_141031_56}" );
	end

	--军衔荣誉值(豪侠荣誉值)
	local nMilitaryValue = Player:GetData( "MILITARYEXCHANGE" );
	strTemp = ScriptGlobal_Format("#{HXYSJ_141031_57}", tostring( nMilitaryValue) )
	g_CtrlJunXianHonour:SetText(strTemp);
	g_CtrlJunXianHonour:SetToolTip( "#{HXYSJ_141031_58}" );

	--修为值(功勋值)
	local nComprehend = Player:GetData( "MILITARYXIUWEI" );
	g_CtrlJunXianComprehend:SetText( tostring( nComprehend ) )
	g_CtrlJunXianComprehend:SetToolTip( ScriptGlobal_Format( "#{HXYSJ_141031_90}", tostring( nComprehend ) ) )
	g_CtrlJunXianComprehendIcon:SetToolTip( ScriptGlobal_Format( "#{HXYSJ_141031_90}", tostring( nComprehend ) ) )
	g_CtrlJunXianComprehendBK:SetToolTip( ScriptGlobal_Format( "#{HXYSJ_141031_90}", tostring( nComprehend ) ) )

	g_CtrlTotalEffectText:SetText("#{HXYSJ_141031_61}")
	g_CtrlTotalExAttrText:SetText("#{HXYSJ_141031_61}")

	SelfJunXian_Equip_Mask:Hide()
	g_CtrlEquipButton:SetActionItem(-1)
	g_CtrlEquipButton_LevelUp:Hide()
	local ActionHXY = EnumAction(21,"equip")
	if ActionHXY and ActionHXY:GetID() ~= 0 then

		if  ActionHXY:GetEquipDur() < 0.1 then
			SelfJunXian_Equip_Mask:Show();
		else
			SelfJunXian_Equip_Mask:Hide();
		end

		local nEquipLevel = DataPool:Lua_GetHXYLevel(  )
		g_CtrlEquipButton:SetActionItem(ActionHXY:GetID())

		if nEquipLevel and nEquipLevel < 100 then
			g_CtrlEquipButton_LevelUp:Show()
		end

		if nEquipLevel and nEquipLevel >= 100 then
			g_CtrlEquipAnimate_MaxLevel:Show()
		end

		local nUpgradeCost = DataPool:Lua_GetHXYUpgradeCost(  )
		strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_60}", tostring(nUpgradeCost) )
		g_CtrlEquipButton_LevelUp:SetToolTip(strTemp)

		local nEquipGrade = DataPool:Lua_GetHXYGrade()
		if nEquipGrade ~= nil and g_EquipBkImage[nEquipGrade] ~= nil then
			g_CtrlEquipBKImage:SetProperty("Image" , g_EquipBkImage[nEquipGrade] )
		end

		local nEffectStr = ""
		local nExAttrStr = ""
		local nIsAnyEffectActive = 0
		for	i = 1, 7 do

			local nIndex , iEffectLevel, iCost , iNeedHXYLevel , iValue = DataPool:Lua_GetHXYEffect( i - 1 )

			if nIndex ~= nil then

				if iEffectLevel == 0 then  --没激活
					g_CtrlEffectImage[ i ]:SetProperty( "Image", g_EffectImage.unactive[ i ] )
					g_CtrlEffectButton[ i ]:Show()

					strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_77}", g_EffectImageTipName[i] )
					g_CtrlEffectImage[ i ]:SetToolTip(strTemp)

					if iCost > nComprehend then		--功勋值不够激活
						strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_86}", tostring(iCost).."#-65" )
						g_CtrlEffectButton[i]:SetToolTip(strTemp)
						g_CtrlEffectButton[i]:SetProperty("NormalImage" , g_LevelUpButtonImage.DisabledImage)
						g_CtrlEffectButton[i]:SetProperty("HoverImage" , g_LevelUpButtonImage.DisabledImage)
						g_CtrlEffectButton[i]:SetProperty("PushedImage" , g_LevelUpButtonImage.DisabledImage)
					else
						strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_88}", tostring(iCost).."#-65" )
						g_CtrlEffectButton[i]:SetToolTip(strTemp)
						g_CtrlEffectButton[i]:SetProperty("NormalImage" , g_LevelUpButtonImage.NormalImage)
						g_CtrlEffectButton[i]:SetProperty("HoverImage" , g_LevelUpButtonImage.HoverImage)
						g_CtrlEffectButton[i]:SetProperty("PushedImage" , g_LevelUpButtonImage.PushedImage)

					end
				else
					g_CtrlEffectImage[ i ]:SetProperty( "Image", g_EffectImage.active[ i ] )
					strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_78}", g_EffectImageTipName[i] ,  tostring(iEffectLevel) ,g_EffectImageTipName[i] , tostring(iValue))
					if nJueWeiLevel and nJueWeiLevel > 0 and Lua_IsInZBSScene()==0 then

						local nAddValueEffect = DataPool:Lua_GetHXYEffectRefixValue( i - 1 )
						if nAddValueEffect then
							strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_140}", g_EffectImageTipName[i] ,  tostring(iEffectLevel) ,g_EffectImageTipName[i] , tostring(iValue),tostring(nAddValueEffect))
						end
					end

					g_CtrlEffectImage[ i ]:SetToolTip(strTemp)

					strTemp =  ScriptGlobal_Format(g_EffectAttribInfo[i] , tostring(iValue))

					if nJueWeiLevel and nJueWeiLevel > 0 and Lua_IsInZBSScene()==0 then

						local nAddValueEffect = DataPool:Lua_GetHXYEffectRefixValue( i - 1 )
						if nAddValueEffect then
							strTemp =  ScriptGlobal_Format(g_EffectAttribInfoRefix[i] , tostring(iValue) , tostring(nAddValueEffect))
						end
					end

					nEffectStr = nEffectStr..strTemp.."#r"
					nIsAnyEffectActive = 1
					if iEffectLevel < 20 then

						g_CtrlEffectButton[ i ]:Show()

						if iCost > nComprehend then		--功勋值不够升级
							strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_87}", tostring(iCost).."#-65" )
							g_CtrlEffectButton[i]:SetToolTip(strTemp)
							g_CtrlEffectButton[i]:SetProperty("NormalImage" , g_LevelUpButtonImage.DisabledImage)
							g_CtrlEffectButton[i]:SetProperty("HoverImage" , g_LevelUpButtonImage.DisabledImage)
							g_CtrlEffectButton[i]:SetProperty("PushedImage" , g_LevelUpButtonImage.DisabledImage)
						else
							strTemp =  ScriptGlobal_Format( "#{HXYSJ_141031_89}", tostring(iCost).."#-65" )
							g_CtrlEffectButton[i]:SetToolTip(strTemp)
							g_CtrlEffectButton[i]:SetProperty("NormalImage" , g_LevelUpButtonImage.NormalImage)
							g_CtrlEffectButton[i]:SetProperty("HoverImage" , g_LevelUpButtonImage.HoverImage)
							g_CtrlEffectButton[i]:SetProperty("PushedImage" , g_LevelUpButtonImage.PushedImage)

						end
					else
						g_CtrlEffectAnimate[ i ] : Show()
					end
				end
				g_CtrlEffectName[ i ]:SetProperty( "Image", g_EffectLevelImage[ i ][ iEffectLevel ] )
			end

			local strExAttr = DataPool:Lua_GetHXYExAttrInfo( i - 1 )
			if strExAttr then
				nExAttrStr = nExAttrStr.."#cfff263"..tostring(strExAttr)
			end

			if nJueWeiLevel and nJueWeiLevel > 0 then
				local nRefixValue = DataPool:Lua_GetHXYExAttrRefixValue( i - 1 )
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

	SelfJunXian_UpdateGemContainer()

end

function SelfJunXian_EquipHXYLevelup()

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name( "HXY_LevelUp" )
		Set_XSCRIPT_ScriptID( 880006 )
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT();

end
--*********************************
-- 获取军衔等级
--*********************************
function SelfJunXian_GetMilitaryRankLvl()
	local nRankLvl = 0;
	local nMaxMilitaryLvl = GetMaxMilitaryRankLevel();
	local nMilitaryExp = Player:GetData( "MILITARYEXP" );
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
function SelfJunXian_OnMoved()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
end


--*********************************
-- 激活/升级
--*********************************
function SelfJunXian_EffectButton( aryIndex )
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 880006 )
		Set_XSCRIPT_Function_Name( "HXY_EffectLevelUp" )
		Set_XSCRIPT_Parameter( 0, aryIndex )
		Set_XSCRIPT_Parameter( 1 , 1)
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()

end

function SelfJunXian_Equip_Clicked( buttonIn )
	local button = tonumber( buttonIn );
	if( button == 1 ) then
		g_CtrlEquipButton:DoAction();
	else
		g_CtrlEquipButton:DoSubAction();
	end

end

--*********************************
-- 查看帮助
--*********************************
function SelfJunXian_ShowHelp()
	OpenYBShopReference("#{HXYSJ_141031_92}")
end


--*********************************
-- 打开所有军衔
--*********************************
function SelfJunXian_OpenAllJunXian()
	-- 预览界面
	PushEvent( "OPEN_ALLJUNXIAN_PAGE" );
end


--*********************************
-- 关闭按钮
--*********************************
function SelfJunXian_CloseFunction()
	SelfJunXian_CleanupUIControls()
	this:Hide()
end


--*********************************
-- 定时器
--*********************************
function SelfJunXian_StopAnimation()

end


--*********************************
-- [装备]标签
--*********************************
function SelfJunXian_SelfEquip_Page_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	OpenEquip(1);
	this:Hide()
end


--*********************************
-- [资料]标签
--*********************************
function SelfJunXian_SelfData_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	SystemSetup:OpenPrivatePage("self");
	this:Hide()
end


--*********************************
-- [珍兽]标签
--*********************************
function SelfJunXian_Pet_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	TogglePetPage();
	this:Hide()
end


--*********************************
-- [子女]标签
--*********************************
function SelfJunXian_Infant_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local bRet = Infant:ToggleInfantPage();
	if ( bRet == 1 ) then
		this:Hide()
	else
		SelfJunXian_OnUpdateSubTableUI();
	end
end


--*********************************
-- [武魂]标签
--*********************************
function SelfJunXian_Wuhun_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	ToggleWuhunPage();
	this:Hide()
end


--*********************************
-- [修炼]标签
--*********************************
function SelfJunXian_Xiulian_Switch()
	local nLevel = Player:GetData( "LEVEL" )
	if( nLevel >= 70 ) then
		Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
		XiuLianPage();
		this:Hide()
	else
		SelfJunXian_OnUpdateSubTableUI();
	    PushDebugMessage("#{XL_090707_62}")
	end
end


--*********************************
-- [秘籍]标签
--*********************************
function SelfJunXian_Miji_Page_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local bRet = OpenMijiPage();
	if ( bRet == 1 ) then
		this:Hide()
	else
		SelfJunXian_OnUpdateSubTableUI();
	end
end


--*********************************
-- [真元]标签
--*********************************
function SelfJunXian_ZhenYuan_Page_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local bRet = Pneuma:ToggleZhenYuanPage();
	if ( bRet == 1 ) then
		this:Hide()
	else
		SelfJunXian_OnUpdateSubTableUI();
	end
end


--*********************************
-- [经脉]标签
--*********************************
function SelfJunXian_JingMai_Page_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local nRet = OpenJingMaiPage();
	if ( nRet == 1 ) then
		this:Hide()
	else
		SelfJunXian_OnUpdateSubTableUI();
	end
end


--*********************************
-- [神鼎]标签
--*********************************
function SelfJunXian_ShenDing_Page_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	local bRet = OpenShenDingPage();
	if ( bRet == 1 ) then
		this:Hide()
	else
		SelfJunXian_OnUpdateSubTableUI();
	end
end


--*********************************
-- [军衔]标签
--*********************************
function SelfJunXian_JunXian_Page_Switch()
	-- 子标签页状态
	SelfJunXian_OnUpdateSubTableUI();
end


--*********************************
-- [骑乘]标签
--*********************************
function SelfJunXian_Ride_Page_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	OpenRidePage();
	this:Hide()
end


--*********************************
-- [其他]标签
--*********************************
function SelfJunXian_Other_Info_Page_Switch()
	Variable:SetVariable( "SelfUnionPos", SelfJunXian_Frame:GetProperty( "UnifiedPosition" ), 1 );
	OtherInfoPage();
	this:Hide()
end

function SelfJunXian_BaoShiCheck_Clicked()
	PushEvent( "GEM_CONTAINER_CHECK", 18, 0 )
end

--- 根据物品序列号来获得物品的类型
function SelfJunXian_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function SelfJunXian_Can_SwitchGem(gem_con_index, equip_point)

    --- 得到装备上的宝石
    local equipTypeList = {}
    local isHaveEquip, gemIndex1, gemIndex2, gemIndex3, gemIndex4 = LifeAbility : SplitWearedEquipGem(equip_point)
    local gemIndexList  = {}
    gemIndexList[1] = gemIndex1
    gemIndexList[2] = gemIndex2
    gemIndexList[3] = gemIndex3
    gemIndexList[4] = gemIndex4
    if isHaveEquip == 1 then
        for i = 1, 4 do
            if gemIndexList[i] > 0 then
                equipTypeList[i] = SelfJunXian_GetGemTypeByIndex( gemIndexList[i] )
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
    LifeAbility : GemContainer_Update()
    for i = 1, 4 do
        local nItemID, tmpGemType
        nItemID, _, tmpGemType = LifeAbility : GetGemContainer_Gem(gem_con_index, i - 1 )
        if nItemID ~= -1 then
            gemConTypeList[i] = tmpGemType
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

--- 更新一键换宝石显示
function SelfJunXian_UpdateGemContainer( )

    --- 当玩家未学会万宝随身互换时，装备位宝石查看按钮为灰态
  local gemSwitchSkillID = 278

	if( Player:GetSkillInfo( gemSwitchSkillID, "learn") ) then
        SelfJunXian_Frame_Part_Bk8_BaoShiCheckBK : Hide()
	else
        SelfJunXian_Frame_Part_Bk8_red : Hide()
        SelfJunXian_Frame_Part_Bk8_green : Hide()
        SelfJunXian_Frame_Part_Bk8_BaoShiCheckBK : Show()
        return
	end

   local ret = SelfJunXian_Can_SwitchGem(17, 21)
   if ret == 1 then
       --- 正常态：玩家学会万宝随身互换，装备位上存在装备且所有装备位上的宝石都可以进行互换时
       SelfJunXian_Frame_Part_Bk8_green : Enable()
       SelfJunXian_Frame_Part_Bk8_green : Show()
       SelfJunXian_Frame_Part_Bk8_green : SetToolTip( "#{WBSS_120727_44}" )
       SelfJunXian_Frame_Part_Bk8_red   : Hide()
   else
       --- 异常态：玩家学会万宝随身互换，装备位上不存在装备或非所有装备位上的宝石都可以进行互换时
       SelfJunXian_Frame_Part_Bk8_red : Enable()
       SelfJunXian_Frame_Part_Bk8_red : Show()
       SelfJunXian_Frame_Part_Bk8_red : SetToolTip( "#{WBSS_120727_44}" )
       SelfJunXian_Frame_Part_Bk8_green : Hide()
   end
end

function SelfJunXian_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function SelfJunXian_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		SelfJunXian_ShenDing:Disable()
		SelfJunXian_ShenDing_tips:Show()
	--	SelfJunXian_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		SelfJunXian_ShenDing:Enable()
		SelfJunXian_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		SelfJunXian_Infant:Disable()
		SelfJunXian_Infant_tips:Show()
	--	SelfJunXian_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		SelfJunXian_Infant:Enable()
		SelfJunXian_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		SelfJunXian_Wuhun:Disable()
--		SelfJunXian_Wuhun_tips:Show()
	--	SelfJunXian_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		SelfJunXian_Wuhun:Enable()
		SelfJunXian_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		SelfJunXian_Xiulian:Disable()
		SelfJunXian_Xiulian_tips:Show()
	--	SelfJunXian_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		SelfJunXian_Xiulian:Enable()
		SelfJunXian_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SelfJunXian_Miji:Disable()
		SelfJunXian_Miji_tips:Show()
	--	SelfJunXian_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		SelfJunXian_Miji:Enable()
		SelfJunXian_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SelfJunXian_ZhenYuan:Disable()
		SelfJunXian_ZhenYuan_tips:Show()
	--	SelfJunXian_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		SelfJunXian_ZhenYuan:Enable()
		SelfJunXian_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		SelfJunXian_JunXian:Disable()
		SelfJunXian_JunXian_tips:Show()
--		SelfJunXian_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		SelfJunXian_JunXian:Enable()
		SelfJunXian_JunXian_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SelfJunXian_JingMai:Disable()
		SelfJunXian_JingMai_tips:Show()
	--	SelfJunXian_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		SelfJunXian_JingMai:Enable()
		SelfJunXian_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		SelfJunXian_BaoJian:Disable()
		SelfJunXian_BaoJian_tips:Show()
	else
		SelfJunXian_BaoJian:Enable()
		SelfJunXian_BaoJian_tips:Hide()
	end

	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SelfJunXian_WuYi:Enable()
		SelfJunXian_WuYi_tips:Hide()
	else
		SelfJunXian_WuYi:Disable()
		SelfJunXian_WuYi_tips:Show()
	end
	SelfJunXian_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SelfJunXian_ShenQi:Enable()
		SelfJunXian_ShenQi_tips:Hide()
	else
		SelfJunXian_ShenQi:Disable()
		SelfJunXian_ShenQi_tips:Show()
	end
	SelfJunXian_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SelfJunXian_Armor:Enable()
		SelfJunXian_Armor_tips:Hide()
	else
		SelfJunXian_Armor:Disable()
		SelfJunXian_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SelfJunXian_CangPin:Enable()
		SelfJunXian_CangPin_tips:Hide()
	else
		SelfJunXian_CangPin:Disable()
		SelfJunXian_CangPin_tips:Show()
	end
	
	SelfJunXian_RefreshCangPinTip()
end

function SelfJunXian_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfJunXian_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function SelfJunXian_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfJunXian_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SelfJunXian_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfJunXian_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfJunXian_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SelfJunXian_WuYi_Buttontips:Show()
	else
		SelfJunXian_WuYi_Buttontips:Hide()
	end
end

function SelfJunXian_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfJunXian_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfJunXian_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SelfJunXian_OtherInfo_ButtonTips:Show()
	else
		SelfJunXian_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SelfJunXian_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function SelfJunXian_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfJunXian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfJunXian_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfJunXian_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfJunXian_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfJunXian_CangPin_Buttontips:Show()
	else
		SelfJunXian_CangPin_Buttontips:Hide()
	end
end


function SelfJunXian_ShowPage()

	for i = 1, table.getn(g_SelfJunXian_Page) do
		g_SelfJunXian_PageButton[i]:Hide()
		g_SelfJunXian_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfJunXian_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfJunXian_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfJunXian_Page) do
			if i ~= nPageNumber then
				g_SelfJunXian_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfJunXian_Page) do
		if SelfJunXian_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfJunXian_PageButton[g_PageCount]:Show()
			g_SelfJunXian_PageButton[g_PageCount]:SetText(g_SelfJunXian_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfJunXian_IsPageEnable(i) == 1 then
				g_SelfJunXian_PageButton[g_PageCount]:Enable()
				g_SelfJunXian_PageMask[g_PageCount]:Hide()
			else
				g_SelfJunXian_PageButton[g_PageCount]:Disable()
				g_SelfJunXian_PageMask[g_PageCount]:Show()
				if g_SelfJunXian_Page[i].Tip ~= "" then
					g_SelfJunXian_PageMask[g_PageCount]:SetToolTip(g_SelfJunXian_Page[i].Tip)
				end
			end
		end
	end
	
	SelfJunXian_RefreshWuYiTip()
	SelfJunXian_RefreshOtherInfoTip()
	SelfJunXian_RefreshCangPinTip()
	
end

function SelfJunXian_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SelfJunXian_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		SelfJunXian_SelfData_Switch()
	elseif idx == 3 then--珍兽
		SelfJunXian_Pet_Switch()
	elseif idx == 4 then--子女
		SelfJunXian_Infant_Switch()
	elseif idx == 5 then--武魂
		SelfJunXian_Wuhun_Switch()
	elseif idx == 6 then--修炼
		SelfJunXian_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		SelfJunXian_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SelfJunXian_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SelfJunXian_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SelfJunXian_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SelfJunXian_JunXian_Page_Switch()
	elseif idx == 12 then--宝鉴
		SelfJunXian_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfJunXian_OpenWuYi()
	elseif idx == 14 then--神器
		SelfJunXian_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfJunXian_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfJunXian_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		SelfJunXian_Other_Info_Page_Switch()
	end
end

function SelfJunXian_CheckPage(idx)
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

function SelfJunXian_IsPageEnable(idx)
	
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

function SelfJunXian_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


