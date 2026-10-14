
local m_PointArray_Button = {}

local m_PointArray_NoActived = {}
local m_PointArray_Actived_Possession = {}
local m_AnimateArray_Actived = {}
local m_AnimateArray_CanActived = {}

local m_AnimateArray_ArrowPointActived = {}

local m_pmPointIndex = {58,59,60,61,62, 63,64,65,66,67, 68,69,70,71,72, 73,74,75,76,77,
78,79,80,81,82, 83,84,85,86}

local m_pmEffectString = {
	"#{YSSJ_140818_81}#{YSSJ_140818_83}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_84}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_85}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_86}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_87}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_88}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_89}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_90}" ,
	"#{YSSJ_140818_81}#{YSSJ_140818_91}" ,

	"#{YSSJ_140818_82}#{YSSJ_140818_92}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_93}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_94}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_95}" ,
	"#{YSSJ_140818_82}#{YSSJ_140818_96}" ,
}

local m_TextCtr_TotalEffect = {}

local m_ButtonFightImage_Small = {

	"set:ButtonYuShou01 image:ButtonYuShouCZX_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouCZX_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouCZX_Pushed",		--pushed

}

local m_ButtonFightImage_Big = {

	"set:ButtonYuShou01 image:ButtonYuShouCZD_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouCZD_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouCZD_Pushed",		--pushed

}

local m_ButtonPossessionImage_Small = {

	"set:ButtonYuShou01 image:ButtonYuShouFTX_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouFTX_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouFTX_Pushed",		--pushed

}

local m_ButtonPossessionImage_Big = {

	"set:ButtonYuShou01 image:ButtonYuShouFTD_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouFTD_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouFTD_Pushed",		--pushed

}

local m_ButtonUnActiveImage_Small = {

	"set:ButtonYuShou01 image:ButtonYuShouHS_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouHS_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouHS_Pushed",		--pushed

}

local m_ButtonUnActiveImage_Big = {

	"set:ButtonYuShou01 image:ButtonYuShouHS_Normal" ,  	--normal
	"set:ButtonYuShou01 image:ButtonYuShouHS_Hover",		--hover
	"set:ButtonYuShou01 image:ButtonYuShouHS_Pushed",		--pushed

}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_YuShou_QingLong_Page = {
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

local g_YuShou_QingLong_PageButton = {}
local g_YuShou_QingLong_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function YuShou_QingLong_PreLoad()

	this:RegisterEvent("OPEN_PETMASTER")
	this:RegisterEvent("QILING_CHANGE")
	this:RegisterEvent("PETMASTER_UPDATE")
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级
	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态
	this:RegisterEvent("FINISH_MISSION");
	
	this:RegisterEvent("NEIDAN_CHIP_UPDATE", false)
	
	this:RegisterEvent("CANGPIN_UPDATE", false)

end

function YuShou_QingLong_OnLoad()
	--未激活
	m_PointArray_NoActived[1]	 = YuShou_QingLong_PointA01
	m_PointArray_NoActived[2]	 = YuShou_QingLong_PointA02
	m_PointArray_NoActived[3]	 = YuShou_QingLong_PointA03
	m_PointArray_NoActived[4]	 = YuShou_QingLong_PointA04
	m_PointArray_NoActived[5]	 = YuShou_QingLong_PointA05
	m_PointArray_NoActived[6]	 = YuShou_QingLong_PointA06
	m_PointArray_NoActived[7]	 = YuShou_QingLong_PointA07
	m_PointArray_NoActived[8]	 = YuShou_QingLong_PointA08
	m_PointArray_NoActived[9]	 = YuShou_QingLong_PointA09
	m_PointArray_NoActived[10]	 = YuShou_QingLong_PointA10
	m_PointArray_NoActived[11]	 = YuShou_QingLong_PointA11
	m_PointArray_NoActived[12]	 = YuShou_QingLong_PointA12
	m_PointArray_NoActived[13]	 = YuShou_QingLong_PointA13
	m_PointArray_NoActived[14]	 = YuShou_QingLong_PointA14
	m_PointArray_NoActived[15]	 = YuShou_QingLong_PointA15
	m_PointArray_NoActived[16]	 = YuShou_QingLong_PointA16
	m_PointArray_NoActived[17]	 = YuShou_QingLong_PointA17
	m_PointArray_NoActived[18]	 = YuShou_QingLong_PointA18
	m_PointArray_NoActived[19]	 = YuShou_QingLong_PointA19
	m_PointArray_NoActived[20]	 = YuShou_QingLong_PointA20
	m_PointArray_NoActived[21]	 = YuShou_QingLong_PointA21
	m_PointArray_NoActived[22]	 = YuShou_QingLong_PointA22
	m_PointArray_NoActived[23]	 = YuShou_QingLong_PointA23
	m_PointArray_NoActived[24]	 = YuShou_QingLong_PointA24
	m_PointArray_NoActived[25]	 = YuShou_QingLong_PointA25
	m_PointArray_NoActived[26]	 = YuShou_QingLong_PointA26
	m_PointArray_NoActived[27]	 = YuShou_QingLong_PointA27
	m_PointArray_NoActived[28]	 = YuShou_QingLong_PointA28
	m_PointArray_NoActived[29]	 = YuShou_QingLong_PointA29
	--已激活出战
	m_PointArray_Button[1] = YuShou_QingLong_Point01
	m_PointArray_Button[2] =	YuShou_QingLong_Point02
	m_PointArray_Button[3] =	YuShou_QingLong_Point03
	m_PointArray_Button[4] =	YuShou_QingLong_Point04
	m_PointArray_Button[5] =	YuShou_QingLong_Point05
	m_PointArray_Button[6] =	YuShou_QingLong_Point06
	m_PointArray_Button[7] =	YuShou_QingLong_Point07
	m_PointArray_Button[8] =	YuShou_QingLong_Point08
	m_PointArray_Button[9] =	YuShou_QingLong_Point09
	m_PointArray_Button[10] =	YuShou_QingLong_Point10
	m_PointArray_Button[11] =	YuShou_QingLong_Point11
	m_PointArray_Button[12] =	YuShou_QingLong_Point12
	m_PointArray_Button[13] =	YuShou_QingLong_Point13
	m_PointArray_Button[14] =	YuShou_QingLong_Point14
	m_PointArray_Button[15] =	YuShou_QingLong_Point15
	m_PointArray_Button[16] =	YuShou_QingLong_Point16
	m_PointArray_Button[17] =	YuShou_QingLong_Point17
	m_PointArray_Button[18] =	YuShou_QingLong_Point18
	m_PointArray_Button[19] =	YuShou_QingLong_Point19
	m_PointArray_Button[20] =	YuShou_QingLong_Point20
	m_PointArray_Button[21] =	YuShou_QingLong_Point21
	m_PointArray_Button[22] =	YuShou_QingLong_Point22
	m_PointArray_Button[23] =	YuShou_QingLong_Point23
	m_PointArray_Button[24] =	YuShou_QingLong_Point24
	m_PointArray_Button[25] =	YuShou_QingLong_Point25
	m_PointArray_Button[26] =	YuShou_QingLong_Point26
	m_PointArray_Button[27] =	YuShou_QingLong_Point27
	m_PointArray_Button[28] =	YuShou_QingLong_Point28
	m_PointArray_Button[29] =	YuShou_QingLong_Point29
	--已激活附体
	m_PointArray_Actived_Possession[1]	 = YuShou_QingLong_Point01_T
	m_PointArray_Actived_Possession[2]	 = YuShou_QingLong_Point02_T
	m_PointArray_Actived_Possession[3]	 = YuShou_QingLong_Point03_T
	m_PointArray_Actived_Possession[4]	 = YuShou_QingLong_Point04_T
	m_PointArray_Actived_Possession[5]	 = YuShou_QingLong_Point05_T
	m_PointArray_Actived_Possession[6]	 = YuShou_QingLong_Point06_T
	m_PointArray_Actived_Possession[7]	 = YuShou_QingLong_Point07_T
	m_PointArray_Actived_Possession[8]	 = YuShou_QingLong_Point08_T
	m_PointArray_Actived_Possession[9]	 = YuShou_QingLong_Point09_T
	m_PointArray_Actived_Possession[10]	 = YuShou_QingLong_Point10_T
	m_PointArray_Actived_Possession[11]	 = YuShou_QingLong_Point11_T
	m_PointArray_Actived_Possession[12]	 = YuShou_QingLong_Point12_T
	m_PointArray_Actived_Possession[13]	 = YuShou_QingLong_Point13_T
	m_PointArray_Actived_Possession[14]	 = YuShou_QingLong_Point14_T
	m_PointArray_Actived_Possession[15]	 = YuShou_QingLong_Point15_T
	m_PointArray_Actived_Possession[16]	 = YuShou_QingLong_Point16_T
	m_PointArray_Actived_Possession[17]	 = YuShou_QingLong_Point17_T
	m_PointArray_Actived_Possession[18]	 = YuShou_QingLong_Point18_T
	m_PointArray_Actived_Possession[19]	 = YuShou_QingLong_Point19_T
	m_PointArray_Actived_Possession[20]	 = YuShou_QingLong_Point20_T
	m_PointArray_Actived_Possession[21]	 = YuShou_QingLong_Point21_T
	m_PointArray_Actived_Possession[22]	 = YuShou_QingLong_Point22_T
	m_PointArray_Actived_Possession[23]	 = YuShou_QingLong_Point23_T
	m_PointArray_Actived_Possession[24]	 = YuShou_QingLong_Point24_T
	m_PointArray_Actived_Possession[25]	 = YuShou_QingLong_Point25_T
	m_PointArray_Actived_Possession[26]	 = YuShou_QingLong_Point26_T
	m_PointArray_Actived_Possession[27]	 = YuShou_QingLong_Point27_T
	m_PointArray_Actived_Possession[28]	 = YuShou_QingLong_Point28_T
	m_PointArray_Actived_Possession[29]	 = YuShou_QingLong_Point29_T
	--激活时特效
	m_AnimateArray_Actived[1]	 = YuShou_QingLong_PointB01
	m_AnimateArray_Actived[2]	 = YuShou_QingLong_PointB02
	m_AnimateArray_Actived[3]	 = YuShou_QingLong_PointB03
	m_AnimateArray_Actived[4]	 = YuShou_QingLong_PointB04
	m_AnimateArray_Actived[5]	 = YuShou_QingLong_PointB05
	m_AnimateArray_Actived[6]	 = YuShou_QingLong_PointB06
	m_AnimateArray_Actived[7]	 = YuShou_QingLong_PointB07
	m_AnimateArray_Actived[8]	 = YuShou_QingLong_PointB08
	m_AnimateArray_Actived[9]	 = YuShou_QingLong_PointB09
	m_AnimateArray_Actived[10]	 = YuShou_QingLong_PointB10
	m_AnimateArray_Actived[11]	 = YuShou_QingLong_PointB11
	m_AnimateArray_Actived[12]	 = YuShou_QingLong_PointB12
	m_AnimateArray_Actived[13]	 = YuShou_QingLong_PointB13
	m_AnimateArray_Actived[14]	 = YuShou_QingLong_PointB14
	m_AnimateArray_Actived[15]	 = YuShou_QingLong_PointB15
	m_AnimateArray_Actived[16]	 = YuShou_QingLong_PointB16
	m_AnimateArray_Actived[17]	 = YuShou_QingLong_PointB17
	m_AnimateArray_Actived[18]	 = YuShou_QingLong_PointB18
	m_AnimateArray_Actived[19]	 = YuShou_QingLong_PointB19
	m_AnimateArray_Actived[20]	 = YuShou_QingLong_PointB20
	m_AnimateArray_Actived[21]	 = YuShou_QingLong_PointB21
	m_AnimateArray_Actived[22]	 = YuShou_QingLong_PointB22
	m_AnimateArray_Actived[23]	 = YuShou_QingLong_PointB23
	m_AnimateArray_Actived[24]	 = YuShou_QingLong_PointB24
	m_AnimateArray_Actived[25]	 = YuShou_QingLong_PointB25
	m_AnimateArray_Actived[26]	 = YuShou_QingLong_PointB26
	m_AnimateArray_Actived[27]	 = YuShou_QingLong_PointB27
	m_AnimateArray_Actived[28]	 = YuShou_QingLong_PointB28
	m_AnimateArray_Actived[29]	 = YuShou_QingLong_PointB29
	--可激活的特效
	m_AnimateArray_CanActived[1]	 = YuShou_QingLong_PointC01
	m_AnimateArray_CanActived[2]	 = YuShou_QingLong_PointC02
	m_AnimateArray_CanActived[3]	 = YuShou_QingLong_PointC03
	m_AnimateArray_CanActived[4]	 = YuShou_QingLong_PointC04
	m_AnimateArray_CanActived[5]	 = YuShou_QingLong_PointC05
	m_AnimateArray_CanActived[6]	 = YuShou_QingLong_PointC06
	m_AnimateArray_CanActived[7]	 = YuShou_QingLong_PointC07
	m_AnimateArray_CanActived[8]	 = YuShou_QingLong_PointC08
	m_AnimateArray_CanActived[9]	 = YuShou_QingLong_PointC09
	m_AnimateArray_CanActived[10]	 = YuShou_QingLong_PointC10
	m_AnimateArray_CanActived[11]	 = YuShou_QingLong_PointC11
	m_AnimateArray_CanActived[12]	 = YuShou_QingLong_PointC12
	m_AnimateArray_CanActived[13]	 = YuShou_QingLong_PointC13
	m_AnimateArray_CanActived[14]	 = YuShou_QingLong_PointC14
	m_AnimateArray_CanActived[15]	 = YuShou_QingLong_PointC15
	m_AnimateArray_CanActived[16]	 = YuShou_QingLong_PointC16
	m_AnimateArray_CanActived[17]	 = YuShou_QingLong_PointC17
	m_AnimateArray_CanActived[18]	 = YuShou_QingLong_PointC18
	m_AnimateArray_CanActived[19]	 = YuShou_QingLong_PointC19
	m_AnimateArray_CanActived[20]	 = YuShou_QingLong_PointC20
	m_AnimateArray_CanActived[21]	 = YuShou_QingLong_PointC21
	m_AnimateArray_CanActived[22]	 = YuShou_QingLong_PointC22
	m_AnimateArray_CanActived[23]	 = YuShou_QingLong_PointC23
	m_AnimateArray_CanActived[24]	 = YuShou_QingLong_PointC24
	m_AnimateArray_CanActived[25]	 = YuShou_QingLong_PointC25
	m_AnimateArray_CanActived[26]	 = YuShou_QingLong_PointC26
	m_AnimateArray_CanActived[27]	 = YuShou_QingLong_PointC27
	m_AnimateArray_CanActived[28]	 = YuShou_QingLong_PointC28
	m_AnimateArray_CanActived[29]	 = YuShou_QingLong_PointC29

	m_TextCtr_TotalEffect[1] = YuShou_QingLong_Frame_Client2_Client_Text01_002
	m_TextCtr_TotalEffect[2] = YuShou_QingLong_Frame_Client2_Client_Text01_003
	m_TextCtr_TotalEffect[3] = YuShou_QingLong_Frame_Client2_Client_Text01_004
	m_TextCtr_TotalEffect[4] = YuShou_QingLong_Frame_Client2_Client_Text01_005
	m_TextCtr_TotalEffect[5] = YuShou_QingLong_Frame_Client2_Client_Text01_006
	m_TextCtr_TotalEffect[6] = YuShou_QingLong_Frame_Client2_Client_Text01_007
	m_TextCtr_TotalEffect[7] = YuShou_QingLong_Frame_Client2_Client_Text01_008
	m_TextCtr_TotalEffect[8] = YuShou_QingLong_Frame_Client2_Client_Text01_009
	m_TextCtr_TotalEffect[9] = YuShou_QingLong_Frame_Client2_Client_Text01_010

	m_TextCtr_TotalEffect[10] = YuShou_QingLong_Frame_Client2_Client_Text03_002
	m_TextCtr_TotalEffect[11] = YuShou_QingLong_Frame_Client2_Client_Text03_003
	m_TextCtr_TotalEffect[12] = YuShou_QingLong_Frame_Client2_Client_Text03_004
	m_TextCtr_TotalEffect[13] = YuShou_QingLong_Frame_Client2_Client_Text03_005
	m_TextCtr_TotalEffect[14] = YuShou_QingLong_Frame_Client2_Client_Text03_006

	m_AnimateArray_ArrowPointActived[1]	=	YuShou_QingLong_PointUP01
	m_AnimateArray_ArrowPointActived[2]	=	YuShou_QingLong_PointUP02
	m_AnimateArray_ArrowPointActived[3]	=	YuShou_QingLong_PointUP03
	m_AnimateArray_ArrowPointActived[4]	=	YuShou_QingLong_PointUP04
	m_AnimateArray_ArrowPointActived[5]	=	YuShou_QingLong_PointUP05
	m_AnimateArray_ArrowPointActived[6]	=	YuShou_QingLong_PointUP06
	m_AnimateArray_ArrowPointActived[7]	=	YuShou_QingLong_PointUP07
	m_AnimateArray_ArrowPointActived[8]	=	YuShou_QingLong_PointUP08
	m_AnimateArray_ArrowPointActived[9]	=	YuShou_QingLong_PointUP09
	m_AnimateArray_ArrowPointActived[10]	=	YuShou_QingLong_PointUP10
	m_AnimateArray_ArrowPointActived[11]	=	YuShou_QingLong_PointUP11
	m_AnimateArray_ArrowPointActived[12]	=	YuShou_QingLong_PointUP12
	m_AnimateArray_ArrowPointActived[13]	=	YuShou_QingLong_PointUP13
	m_AnimateArray_ArrowPointActived[14]	=	YuShou_QingLong_PointUP14

	g_YuShou_QingLong_PageButton[1] = YuShou_QingLong_SelfEquip
	g_YuShou_QingLong_PageButton[2] = YuShou_QingLong_SelfData
	g_YuShou_QingLong_PageButton[3] = YuShou_QingLong_Pet
	g_YuShou_QingLong_PageButton[4] = YuShou_QingLong_Infant
	g_YuShou_QingLong_PageButton[5] = YuShou_QingLong_Wuhun
	g_YuShou_QingLong_PageButton[6] = YuShou_QingLong_Xiulian
	g_YuShou_QingLong_PageButton[7] = YuShou_QingLong_Miji
	g_YuShou_QingLong_PageButton[8] = YuShou_QingLong_ZhenYuan
	g_YuShou_QingLong_PageButton[9] = YuShou_QingLong_JingMai
	g_YuShou_QingLong_PageButton[10] = YuShou_QingLong_ShenDing
	g_YuShou_QingLong_PageButton[11] = YuShou_QingLong_JueWei
	g_YuShou_QingLong_PageButton[12] = YuShou_QingLong_BaoJian
	g_YuShou_QingLong_PageButton[13] = YuShou_QingLong_WuYi
	g_YuShou_QingLong_PageButton[14] = YuShou_QingLong_ShenQi
	g_YuShou_QingLong_PageButton[15] = YuShou_QingLong_Armor
	g_YuShou_QingLong_PageButton[16] = YuShou_QingLong_CangPin
	g_YuShou_QingLong_PageButton[17] = YuShou_QingLong_OtherInfo
	
	g_YuShou_QingLong_PageMask[1] = YuShou_QingLong_SelfEquip_tips
	g_YuShou_QingLong_PageMask[2] = YuShou_QingLong_SelfData_tips
	g_YuShou_QingLong_PageMask[3] = YuShou_QingLong_Pet_tips
	g_YuShou_QingLong_PageMask[4] = YuShou_QingLong_Infant_tips
	g_YuShou_QingLong_PageMask[5] = YuShou_QingLong_Wuhun_tips
	g_YuShou_QingLong_PageMask[6] = YuShou_QingLong_Xiulian_tips
	g_YuShou_QingLong_PageMask[7] = YuShou_QingLong_Miji_tips
	g_YuShou_QingLong_PageMask[8] = YuShou_QingLong_ZhenYuan_tips
	g_YuShou_QingLong_PageMask[9] = YuShou_QingLong_JingMai_tips
	g_YuShou_QingLong_PageMask[10] = YuShou_QingLong_ShenDing_tips
	g_YuShou_QingLong_PageMask[11] = YuShou_QingLong_JueWei_tips
	g_YuShou_QingLong_PageMask[12] = YuShou_QingLong_BaoJian_tips
	g_YuShou_QingLong_PageMask[13] = YuShou_QingLong_WuYi_tips
	g_YuShou_QingLong_PageMask[14] = YuShou_QingLong_ShenQi_tips
	g_YuShou_QingLong_PageMask[15] = YuShou_QingLong_Armor_tips
	g_YuShou_QingLong_PageMask[16] = YuShou_QingLong_CangPin_tips
	g_YuShou_QingLong_PageMask[17] = YuShou_QingLong_OtherInfo_tips
	
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

function YuShou_QingLong_OnEvent(event)

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT") or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		YuShou_QingLong_Refresh_Page_Button(nLevel)
		YuShou_QingLong_ShowPage()
	end
	if( event == "OPEN_PETMASTER" ) then

		if Player:GetData("Is2606S") == 1 then
			return
		end
		
		if tonumber(arg0) == 2 then
			YuShou_QingLong_Init()
			this:Show()
			local nLevel =Player:GetLevel()
			YuShou_QingLong_Refresh_Page_Button(nLevel)
			YuShou_QingLong_ShowPage()
		end
	end

	if( event == "QILING_CHANGE" ) then

		if this:IsVisible() then
			local nQiLing = Player:GetData("QILING")
			YuShou_QingLong_Frame_Client2_Client_Text08_001:SetText(tostring(nQiLing))
		end

	end

	if( event == "PETMASTER_UPDATE" ) then
		if this:IsVisible() then
			YuShou_QingLong_Update(tonumber(arg0))
		end
	end
	
	if event == "NEIDAN_CHIP_UPDATE" then
		YuShou_QingLong_Refresh_PetTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		YuShou_QingLong_RefreshCangPinTip()
	end
end

function YuShou_QingLong_Reset()

	YuShou_QingLong_SelfEquip:SetCheck(0)
	YuShou_QingLong_SelfData:SetCheck(0)
	YuShou_QingLong_Pet:SetCheck(1)
	YuShou_QingLong_Infant:SetCheck(0)
	YuShou_QingLong_Wuhun:SetCheck(0)
	YuShou_QingLong_Xiulian:SetCheck(0)
	YuShou_QingLong_Miji:SetCheck(0)
	YuShou_QingLong_ZhenYuan:SetCheck(0)
	YuShou_QingLong_JingMai:SetCheck(0)
	YuShou_QingLong_ShenDing:SetCheck(0)
	YuShou_QingLong_Ride:SetCheck(0)
	YuShou_QingLong_OtherInfo:SetCheck(0)

	YuShou_QingLong_Client_Button01:SetCheck(0)
	YuShou_QingLong_Client_Button02:SetCheck(1)
	YuShou_QingLong_Client_Button03:SetCheck(0)

	YuShou_QingLong_Frame_Client2_Client_Image01_Button01:SetCheck(0)
	YuShou_QingLong_Frame_Client2_Client_Image01_Button02:SetCheck(0)
	YuShou_QingLong_Frame_Client2_Client_Image01_Button03:SetCheck(1)
	YuShou_QingLong_Frame_Client2_Client_Image01_Button04:SetCheck(0)

	for i = 1 , 29 do

		m_PointArray_NoActived[i]:Hide()
		m_PointArray_Button[i]:Show()
		m_PointArray_Actived_Possession[i]:Hide()
		m_AnimateArray_Actived[i]:Hide()
		m_AnimateArray_CanActived[i]:Hide()

	end

end

function YuShou_QingLong_Adjust_Position()

	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		YuShou_QingLong_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end

end

function YuShou_QingLong_Init()

	YuShou_QingLong_Reset()
	YuShou_QingLong_Adjust_Position()

	local nQiLing = Player:GetData("QILING")
	YuShou_QingLong_Frame_Client2_Client_Text08_001:SetText(tostring(nQiLing))

	YuShou_QingLong_UpdatePoint(0 , 0)

	for i = 1 , 14 do

		local effectStr = Player:GetPetMasterTotalEffect( i - 1)
		if effectStr ~= nil then

			m_TextCtr_TotalEffect[i]:SetText(tostring(effectStr).." ")
		end

	end

	if Player:GetData("IsOriginalJD") == 1 or Player : GetData("Is2606S") == 1 then
		YuShou_QingLong_Client_Button04:Hide()
	else
		YuShou_QingLong_Client_Button04:Show()
	end
	
	YuShou_QingLong_UpdatePageButton()

end

function YuShou_QingLong_UpdatePoint(update , nActivePointIndex)

	for i = 1, 14 do

		m_AnimateArray_ArrowPointActived[i]:Hide()
	end

	for i = 1, table.getn(m_pmPointIndex) do

		local pointState = Player:GetPetMasterPointState(m_pmPointIndex[i] , "State")
		local petFlag = Player:GetPetMasterPointState(m_pmPointIndex[i] , "PetFlag")
		if pointState ~= nil and petFlag ~= nil then

			local strTip = ""
			local strTipTail = ""
			if pointState == 0 or pointState == 1 then			--未激活 或者 待激活

				if m_pmPointIndex[i] == 86 then
					m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonUnActiveImage_Big[1])
					m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonUnActiveImage_Big[2])
					m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonUnActiveImage_Big[3])
				else
					m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonUnActiveImage_Small[1])
					m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonUnActiveImage_Small[2])
					m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonUnActiveImage_Small[3])
				end

				m_AnimateArray_Actived[i]:Hide()
				if pointState == 1 then
					m_AnimateArray_CanActived[i]:Show()
				else
					m_AnimateArray_CanActived[i]:Hide()
				end

				strTip = strTip.."#{YSSJ_140818_80}#r"
				local nCost = Player:GetPetMasterPointState(m_pmPointIndex[i] , "Cost")
				if nCost ~= nil then
					strTipTail = "#r#{YSSJ_140818_97}"..tostring(nCost)
				end

			elseif pointState == 2 then 	--已激活

				if petFlag == 0 then
					if m_pmPointIndex[i] == 86 then
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonFightImage_Big[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonFightImage_Big[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonFightImage_Big[3])
					else
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonFightImage_Small[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonFightImage_Small[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonFightImage_Small[3])
					end
				else
					if m_pmPointIndex[i] == 86 then
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonPossessionImage_Big[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonPossessionImage_Big[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonPossessionImage_Big[3])
					else
						m_PointArray_Button[i]:SetProperty("NormalImage" , m_ButtonPossessionImage_Small[1])
						m_PointArray_Button[i]:SetProperty("HoverImage" , m_ButtonPossessionImage_Small[2])
						m_PointArray_Button[i]:SetProperty("PushedImage" , m_ButtonPossessionImage_Small[3])
					end
				end

				if update == 1 and m_pmPointIndex[i] == nActivePointIndex then
					m_AnimateArray_Actived[i]:Show()
					m_AnimateArray_Actived[i]:Play(true)

					for j = 0 , 2 do
						local nEffectIndex , _ = Player:GetPetMasterPointEffect(m_pmPointIndex[i] ,j)
						if m_AnimateArray_ArrowPointActived[nEffectIndex + 1]  ~= nil then
							m_AnimateArray_ArrowPointActived[nEffectIndex + 1]:Show()
							m_AnimateArray_ArrowPointActived[nEffectIndex + 1]:Play(true)
						end

					end
				else
					m_AnimateArray_Actived[i]:Hide()
				end

				m_AnimateArray_CanActived[i]:Hide()

				strTip = strTip.."#{YSSJ_140818_98}#r"
			end

			local nEffectEnum , strEffect = Player:GetPetMasterPointEffect(m_pmPointIndex[i] ,0)
			if nEffectEnum ~= nil and m_pmEffectString[nEffectEnum + 1] ~= nil then
				strTip = strTip..m_pmEffectString[nEffectEnum + 1]..tostring(strEffect)
			end

			nEffectEnum , strEffect = Player:GetPetMasterPointEffect(m_pmPointIndex[i] ,1)
			if nEffectEnum ~= nil and m_pmEffectString[nEffectEnum + 1] ~= nil then
				strTip = strTip.."#r"..m_pmEffectString[nEffectEnum + 1]..tostring(strEffect)
			end

			nEffectEnum , strEffect = Player:GetPetMasterPointEffect(m_pmPointIndex[i] ,2)
			if nEffectEnum ~= nil and m_pmEffectString[nEffectEnum + 1] ~= nil then
				strTip = strTip.."#r"..m_pmEffectString[nEffectEnum + 1]..tostring(strEffect)
			end

			m_PointArray_Button[i]:SetToolTip(strTip..strTipTail)

		end

	end


end

function YuShou_QingLong_UpdatePageButton()

	local p3_LastPointState = Player:GetPetMasterPointState(86 , "State")
	if p3_LastPointState ~= nil and p3_LastPointState == 2 then
		YuShou_QingLong_Frame_Client2_Client_Image01_Button04:Enable()
		YuShou_QingLong_FakeTip04:Hide()
		YuShou_QingLong_Frame_Client2_Client_Image0ImageDB:SetProperty("Image", "set:YuShou_DiBanJH image:YuShou_DiBanJH_Picture")
	else
		YuShou_QingLong_Frame_Client2_Client_Image01_Button04:Disable()
		YuShou_QingLong_FakeTip04:Show()
		YuShou_QingLong_Frame_Client2_Client_Image0ImageDB:SetProperty("Image", "set:YuShou_DiBan image:YuShou_DiBan_Picture")
	end

end

function YuShou_QingLong_Update(nActivePointIndex)

	YuShou_QingLong_UpdatePoint(1 , nActivePointIndex)

	for i = 1 , 14 do

		local effectStr = Player:GetPetMasterTotalEffect( i - 1)
		if effectStr ~= nil then

			m_TextCtr_TotalEffect[i]:SetText(tostring(effectStr).." ")
		end

	end

	YuShou_QingLong_UpdatePageButton()

end

function YuShou_QingLong_Close()

	this:Hide()

end

function YuShou_QingLong_OnHidden()

	YuShou_QingLong_Reset()

end

function YuShou_QingLong_Point_Clicked(nIndex)

	if m_pmPointIndex[ nIndex ] ~= nil then

		local pointState = Player:GetPetMasterPointState(m_pmPointIndex[ nIndex ] , "State")

		if pointState == 0 then

			PushDebugMessage("#{YSSJ_140818_46}")
			return
		end

		if pointState == 2 then

			PushDebugMessage("#{YSSJ_140818_45}")
			return
		end

		if pointState ~= nil and pointState == 1 then

			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "PetMasterActive" )
				Set_XSCRIPT_ScriptID( 880004 )
				Set_XSCRIPT_Parameter( 0, m_pmPointIndex[ nIndex ]    )         ---点的索引
				Set_XSCRIPT_ParamCount( 1 )
			Send_XSCRIPT()

		end
	end

end

--装备
function YuShou_QingLong_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	OpenEquip(1);
end

--资料
function YuShou_QingLong_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
end

--子女
function YuShou_QingLong_Infant_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	else
		YuShou_QingLong_Infant:SetCheck(0)
	end
end

--武魂
function YuShou_QingLong_Wuhun_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
end

--修炼
function YuShou_QingLong_Xiulian_Page_Switch()
    local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    YuShou_QingLong_Xiulian:SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

--秘籍
function YuShou_QingLong_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenMijiPage();
	if nRet ~= 1 then
		YuShou_QingLong_Miji:SetCheck(0)
	end
end

--真元
function YuShou_QingLong_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet ~= 1 then
		YuShou_QingLong_ZhenYuan:SetCheck(0)
	end
end

--经脉
function YuShou_QingLong_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet ~= 1 then
		YuShou_QingLong_JingMai:SetCheck(0)
	end
end

--神鼎
function  YuShou_QingLong_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet ~= 1 then
		YuShou_QingLong_ShenDing:SetCheck(0)
	end
end

--侠印
function  YuShou_QingLong_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	else
		YuShou_QingLong_JueWei:SetCheck(0)
	end
end

--骑乘
function YuShou_QingLong_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
end

--其他
function YuShou_QingLong_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
end

--五行宝鉴
function YuShou_QingLong_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

--珍兽
function YuShou_QingLong_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	TogglePetPage();
end

--幻灵
function YuShou_QingLong_HuanLing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	Pet:Lua_OpenPetHuanLingUI()
end

--朱雀诀
function YuShou_QingLong_ZhuQue_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local ret = Lua_OpenPetMasterPage(0)
	if ret ~= 1 then
		YuShou_QingLong_Frame_Client2_Client_Image01_Button01:SetCheck(0)
	end
end

--玄武诀
function YuShou_QingLong_XuanWu_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local ret = Lua_OpenPetMasterPage(1)
	if ret ~= 1 then
		YuShou_QingLong_Frame_Client2_Client_Image01_Button02:SetCheck(0)
	end
end

--白虎诀
function YuShou_QingLong_BaiHu_Page_Switch()
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	local ret = Lua_OpenPetMasterPage(3)
	if ret ~= 1 then
		YuShou_QingLong_Frame_Client2_Client_Image01_Button04:SetCheck(0)
	end
end

function YuShou_QingLong_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		YuShou_QingLong_ShenDing:Disable()
		YuShou_QingLong_ShenDing_tips:Show()
	--	Infant_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		YuShou_QingLong_ShenDing:Enable()
		YuShou_QingLong_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		YuShou_QingLong_Infant:Disable()
		YuShou_QingLong_Infant_tips:Show()
	--	YuShou_BaiHu_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		YuShou_QingLong_Infant:Enable()
		YuShou_QingLong_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		YuShou_QingLong_Wuhun:Disable()
--		YuShou_QingLong_Wuhun_tips:Show()
	--	Infant_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		YuShou_QingLong_Wuhun:Enable()
		YuShou_QingLong_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		YuShou_QingLong_Xiulian:Disable()
		YuShou_QingLong_Xiulian_tips:Show()
	--	Infant_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		YuShou_QingLong_Xiulian:Enable()
		YuShou_QingLong_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		YuShou_QingLong_Miji:Disable()
		YuShou_QingLong_Miji_tips:Show()
	--	Infant_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		YuShou_QingLong_Miji:Enable()
		YuShou_QingLong_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		YuShou_QingLong_ZhenYuan:Disable()
		YuShou_QingLong_ZhenYuan_tips:Show()
	--	Infant_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		YuShou_QingLong_ZhenYuan:Enable()
		YuShou_QingLong_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		YuShou_QingLong_JueWei:Disable()
		YuShou_QingLong_JueWei_tips:Show()
	--	Infant_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		YuShou_QingLong_JueWei:Enable()
		YuShou_QingLong_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		YuShou_QingLong_JingMai:Disable()
		YuShou_QingLong_JingMai_tips:Show()
	--	Infant_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		YuShou_QingLong_JingMai:Enable()
		YuShou_QingLong_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		YuShou_QingLong_BaoJian:Disable()
		YuShou_QingLong_BaoJian_tips:Show()
	else
		YuShou_QingLong_BaoJian:Enable()
		YuShou_QingLong_BaoJian_tips:Hide()
	end

	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		YuShou_QingLong_WuYi:Enable()
		YuShou_QingLong_WuYi_tips:Hide()
	else
		YuShou_QingLong_WuYi:Disable()
		YuShou_QingLong_WuYi_tips:Show()
	end
		
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		YuShou_QingLong_ShenQi:Enable()
		YuShou_QingLong_ShenQi_tips:Hide()
	else
		YuShou_QingLong_ShenQi:Disable()
		YuShou_QingLong_ShenQi_tips:Show()
	end
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		YuShou_QingLong_Armor:Enable()
		YuShou_QingLong_Armor_tips:Hide()
	else
		YuShou_QingLong_Armor:Disable()
		YuShou_QingLong_Armor_tips:Show()
	end
	
	YuShou_QingLong_Refresh_PetTip()
	
	if nLevel >= 30 then
		YuShou_QingLong_CangPin:Enable()
		YuShou_QingLong_CangPin_tips:Hide()
	else
		YuShou_QingLong_CangPin:Disable()
		YuShou_QingLong_CangPin_tips:Show()
	end
	
	YuShou_QingLong_RefreshCangPinTip()
end

function YuShou_QingLong_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function YuShou_QingLong_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--内甲
function YuShou_QingLong_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function YuShou_QingLong_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function YuShou_QingLong_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_YuShou_QingLong_PageButton[idx]:GetProperty("UnifiedXPosition");
			YuShou_QingLong_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		YuShou_QingLong_CangPin_Buttontips:Show()
	else
		YuShou_QingLong_CangPin_Buttontips:Hide()
	end
end

--珍兽内丹
function YuShou_QingLong_NeiDan_Page_Switch()

	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	local nLevel = Player:GetData("LEVEL")
	if nLevel < 60 then
		PushDebugMessage("#{ZSND_230428_05}")
		YuShou_QingLong_Client_Button04:SetCheck(0)
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(3000) ~= 1 then
		PushDebugMessage("#{ZSND_230428_06}")
		YuShou_QingLong_Client_Button04:SetCheck(0)
		return
	end
	Variable:SetVariable("SelfUnionPos", YuShou_QingLong_Frame:GetProperty("UnifiedPosition"), 1)	
	Pet:LuaFnOpenPetNeiDan("self")
end

function YuShou_QingLong_Refresh_PetTip()
	local bShowTip = DataPool:LuaFnHavePetNeiDanChipCanCompound()
	if bShowTip == 1 then
		YuShou_QingLong_Client_Button04tips:Show()
		YuShou_QingLong_Pet_Buttontips:Show()
	else
		YuShou_QingLong_Client_Button04tips:Hide()
		YuShou_QingLong_Pet_Buttontips:Hide()
	end
end


function YuShou_QingLong_ShowPage()

	for i = 1, table.getn(g_YuShou_QingLong_Page) do
		g_YuShou_QingLong_PageButton[i]:Hide()
		g_YuShou_QingLong_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	YuShou_QingLong_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_YuShou_QingLong_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_YuShou_QingLong_Page) do
			if i ~= nPageNumber then
				g_YuShou_QingLong_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_YuShou_QingLong_Page) do
		if YuShou_QingLong_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_YuShou_QingLong_PageButton[g_PageCount]:Show()
			g_YuShou_QingLong_PageButton[g_PageCount]:SetText(g_YuShou_QingLong_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if YuShou_QingLong_IsPageEnable(i) == 1 then
				g_YuShou_QingLong_PageButton[g_PageCount]:Enable()
				g_YuShou_QingLong_PageMask[g_PageCount]:Hide()
			else
				g_YuShou_QingLong_PageButton[g_PageCount]:Disable()
				g_YuShou_QingLong_PageMask[g_PageCount]:Show()
				if g_YuShou_QingLong_Page[i].Tip ~= "" then
					g_YuShou_QingLong_PageMask[g_PageCount]:SetToolTip(g_YuShou_QingLong_Page[i].Tip)
				end
			end
		end
	end
	
	YuShou_QingLong_Refresh_PetTip()
	YuShou_QingLong_RefreshCangPinTip()
	
end

function YuShou_QingLong_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		YuShou_QingLong_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		YuShou_QingLong_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		--SelfData_Pet_Down()
	elseif idx == 4 then--子女
		YuShou_QingLong_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		YuShou_QingLong_Wuhun_Page_Switch()
	elseif idx == 6 then--修炼
		YuShou_QingLong_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		YuShou_QingLong_Miji_Page_Switch()
	elseif idx == 8 then--真元
		YuShou_QingLong_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		YuShou_QingLong_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		YuShou_QingLong_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		YuShou_QingLong_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		YuShou_QingLong_OpenBaoJian()
	elseif idx == 13 then--武意
		YuShou_QingLong_OpenWuYi()
	elseif idx == 14 then--神器
		YuShou_QingLong_OpenShenQi()
	elseif idx == 15 then--星盘
		YuShou_QingLong_Armor_Page_Switch()
	elseif idx == 16 then--名物
		YuShou_QingLong_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		YuShou_QingLong_OtherInfo_Page_Switch()
	end
end

function YuShou_QingLong_CheckPage(idx)
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

function YuShou_QingLong_IsPageEnable(idx)
	
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

function YuShou_QingLong_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


