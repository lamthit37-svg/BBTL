--CangPin_ShuXing
--!!!reloadscript =CangPin_ShuXing

local g_CangPin_ShuXing_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_CurClass = 0	--当前大类

local g_InitList = 0

local g_MaxSetBarNum = 0
local g_MaxCangPinBarNum = 10

local g_SetBarList = {}
local g_CangPinBarList = {}

local g_SetList = {}

local g_CurSet = -1
local g_CurCangPinPage = 0
local g_CurCangPinMaxPage = 1
local g_EachPageCangPinNum = 4
local g_EachPageCangPinNum_Set2 = 7
local g_SetCount = {}

local g_ClassCount = 4
local g_MaxStar = 9

local g_TargetCangPinId = 0

local g_LimitLevel = 30
local g_PreMissionId = 1926

local g_StarImg = {
	"set:CangPin image:CangPin_Level1",
	"set:CangPin image:CangPin_Level2",
	"set:CangPin image:CangPin_Level3",
	"set:CangPin image:CangPin_Level4",
	"set:CangPin image:CangPin_Level5",
	"set:CangPin image:CangPin_Level6",
	"set:CangPin image:CangPin_Level7",
	"set:CangPin image:CangPin_Level8",
	"set:CangPin image:CangPin_Level9",
}

local g_ClassBtn = {}
local g_ClassBtnTip = {}

local g_ClassEffectTips = {
	"#{CPSJ_260112_106}",
	"#{CPSJ_260112_108}",
	"#{CPSJ_260112_107}",
	"#{CPSJ_260112_109}",
}

local g_ClassLevelStr = {
	"#{CPSJ_260112_5}",
	"#{CPSJ_260112_78}",
	"#{CPSJ_260112_77}",
	"#{CPSJ_260112_79}",
}

local g_CangPinActionButtons = {}
local g_CangPinLockImages = {}
local g_CangPinActiveButtons = {}
local g_CangPinActiveButtonTips = {}
local g_CangPinStarupButtons = {}
local g_CangPinStarupButtonTips = {}
local g_CangPinStarImages = {}
local g_CangPinChipTexts = {}
local g_CangPinNameTexts = {}
local g_CangPinNameBKs = {}
local g_CangPinBKImages = {}

local g_CangPinActionButtons_Set2 = {}
local g_CangPinLockImages_Set2 = {}
local g_CangPinActiveButtons_Set2 = {}
local g_CangPinActiveButtonTips_Set2 = {}
local g_CangPinStarupButtons_Set2 = {}
local g_CangPinStarupButtonTips_Set2 = {}
local g_CangPinStarImages_Set2 = {}
local g_CangPinChipTexts_Set2 = {}
local g_CangPinNameTexts_Set2 = {}
local g_CangPinNameBKs_Set2 = {}
local g_CangPinBKImages_Set2 = {}

local g_BannerImages = {
	"set:CangPin_1 image:CangPin_YiShouBanner",
	"set:CangPin_1 image:CangPin_YuShangBanner",
	"set:CangPin_1 image:CangPin_TianBingBanner",
	"set:CangPin_1 image:CangPin_BaiBaoBanner",
}

local g_MaxQualUpLevel = 4


--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_CangPin_ShuXing_Page = {
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

local g_CangPin_ShuXing_PageButton = {}
local g_CangPin_ShuXing_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function CangPin_ShuXing_PreLoad()
	this:RegisterEvent("OPEN_CANGPIN", true)
	this:RegisterEvent("CANGPIN_UPDATE", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MARTIAL_UPDATE", false)	
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP", false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("UPDATE_MISSION_DATA", false)
	this:RegisterEvent("TOGGLE_UPDATE_INFANT", false) 				--子女有变化刷新按钮状态
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK", false)		--升级
	this:RegisterEvent("FINISH_MISSION", false)	
end

function CangPin_ShuXing_OnLoad()
	g_CangPin_ShuXing_Frame_UnifiedPosition = CangPin_ShuXing_Frame:GetProperty("UnifiedPosition")
	
	g_ClassBtn[1] = CangPin_ShuXing_GoTo_PageBtn_1
	g_ClassBtn[2] = CangPin_ShuXing_GoTo_PageBtn_3
	g_ClassBtn[3] = CangPin_ShuXing_GoTo_PageBtn_2
	g_ClassBtn[4] = CangPin_ShuXing_GoTo_PageBtn_4
	
	g_ClassBtnTip[1] = CangPin_ShuXing_GoTo_PageBtn_1_Buttontips
	g_ClassBtnTip[2] = CangPin_ShuXing_GoTo_PageBtn_3_Buttontips
	g_ClassBtnTip[3] = CangPin_ShuXing_GoTo_PageBtn_2_Buttontips
	g_ClassBtnTip[4] = CangPin_ShuXing_GoTo_PageBtn_4_Buttontips
	
	g_CangPinActionButtons[1] = CangPin_ShuXing_CangPin_ActionButton
	g_CangPinActionButtons[2] = CangPin_ShuXing_CangPin2_ActionButton
	g_CangPinActionButtons[3] = CangPin_ShuXing_CangPin3_ActionButton
	g_CangPinActionButtons[4] = CangPin_ShuXing_CangPin4_ActionButton
	
	g_CangPinLockImages[1] = CangPin_ShuXing_CangPin_LockImage
	g_CangPinLockImages[2] = CangPin_ShuXing_CangPin2_LockImage
	g_CangPinLockImages[3] = CangPin_ShuXing_CangPin3_LockImage
	g_CangPinLockImages[4] = CangPin_ShuXing_CangPin4_LockImage
	
	g_CangPinActiveButtons[1] = CangPin_ShuXing_CangPin_Active_Btn
	g_CangPinActiveButtons[2] = CangPin_ShuXing_CangPin2_Active_Btn
	g_CangPinActiveButtons[3] = CangPin_ShuXing_CangPin3_Active_Btn
	g_CangPinActiveButtons[4] = CangPin_ShuXing_CangPin4_Active_Btn
	
	g_CangPinActiveButtonTips[1] = CangPin_ShuXing_CangPin_Active_Btn_Buttontips
	g_CangPinActiveButtonTips[2] = CangPin_ShuXing_CangPin2_Active_Btn_Buttontips
	g_CangPinActiveButtonTips[3] = CangPin_ShuXing_CangPin3_Active_Btn_Buttontips
	g_CangPinActiveButtonTips[4] = CangPin_ShuXing_CangPin4_Active_Btn_Buttontips
	
	g_CangPinStarupButtons[1] = CangPin_ShuXing_CangPin_LevelUp_Btn
	g_CangPinStarupButtons[2] = CangPin_ShuXing_CangPin2_LevelUp_Btn
	g_CangPinStarupButtons[3] = CangPin_ShuXing_CangPin3_LevelUp_Btn
	g_CangPinStarupButtons[4] = CangPin_ShuXing_CangPin4_LevelUp_Btn
	
	g_CangPinStarupButtonTips[1] = CangPin_ShuXing_CangPin_LevelUp_Btn_Buttontips
	g_CangPinStarupButtonTips[2] = CangPin_ShuXing_CangPin2_LevelUp_Btn_Buttontips
	g_CangPinStarupButtonTips[3] = CangPin_ShuXing_CangPin3_LevelUp_Btn_Buttontips
	g_CangPinStarupButtonTips[4] = CangPin_ShuXing_CangPin4_LevelUp_Btn_Buttontips
	
	g_CangPinStarImages[1] = CangPin_ShuXing_CangPin_LevelNum
	g_CangPinStarImages[2] = CangPin_ShuXing_CangPin2_LevelNum
	g_CangPinStarImages[3] = CangPin_ShuXing_CangPin3_LevelNum
	g_CangPinStarImages[4] = CangPin_ShuXing_CangPin4_LevelNum
	
	g_CangPinChipTexts[1] = CangPin_ShuXing_CangPin_NumText
	g_CangPinChipTexts[2] = CangPin_ShuXing_CangPin2_NumText
	g_CangPinChipTexts[3] = CangPin_ShuXing_CangPin3_NumText
	g_CangPinChipTexts[4] = CangPin_ShuXing_CangPin4_NumText
	
	g_CangPinNameTexts[1] = CangPin_ShuXing_CangPin_NameBK_Text
	g_CangPinNameTexts[2] = CangPin_ShuXing_CangPin2_NameBK_Text
	g_CangPinNameTexts[3] = CangPin_ShuXing_CangPin3_NameBK_Text
	g_CangPinNameTexts[4] = CangPin_ShuXing_CangPin4_NameBK_Text
	
	g_CangPinNameBKs[1] = CangPin_ShuXing_CangPin_NameBK
	g_CangPinNameBKs[2] = CangPin_ShuXing_CangPin2_NameBK
	g_CangPinNameBKs[3] = CangPin_ShuXing_CangPin3_NameBK
	g_CangPinNameBKs[4] = CangPin_ShuXing_CangPin4_NameBK
	
	g_CangPinBKImages[1] = CangPin_ShuXing_CangPin_BKImage
	g_CangPinBKImages[2] = CangPin_ShuXing_CangPin2_BKImage
	g_CangPinBKImages[3] = CangPin_ShuXing_CangPin3_BKImage
	g_CangPinBKImages[4] = CangPin_ShuXing_CangPin4_BKImage
	
	--
	
	g_CangPinActionButtons_Set2[1] = CangPin_ShuXing_Special_CangPin_ActionButton_1_1
	g_CangPinActionButtons_Set2[2] = CangPin_ShuXing_Special_CangPin_ActionButton_1_2
	g_CangPinActionButtons_Set2[3] = CangPin_ShuXing_Special_CangPin_ActionButton_1_3
	g_CangPinActionButtons_Set2[4] = CangPin_ShuXing_Special_CangPin_ActionButton_1_4
	g_CangPinActionButtons_Set2[5] = CangPin_ShuXing_Special_CangPin2_ActionButton
	g_CangPinActionButtons_Set2[6] = CangPin_ShuXing_Special_CangPin3_ActionButton
	g_CangPinActionButtons_Set2[7] = CangPin_ShuXing_Special_CangPin4_ActionButton
	
	g_CangPinLockImages_Set2[1] = CangPin_ShuXing_Special_CangPin_LockImage_1_1
	g_CangPinLockImages_Set2[2] = CangPin_ShuXing_Special_CangPin_LockImage_1_2
	g_CangPinLockImages_Set2[3] = CangPin_ShuXing_Special_CangPin_LockImage_1_3
	g_CangPinLockImages_Set2[4] = CangPin_ShuXing_Special_CangPin_LockImage_1_4
	g_CangPinLockImages_Set2[5] = CangPin_ShuXing_Special_CangPin2_LockImage
	g_CangPinLockImages_Set2[6] = CangPin_ShuXing_Special_CangPin3_LockImage
	g_CangPinLockImages_Set2[7] = CangPin_ShuXing_Special_CangPin4_LockImage
	
	g_CangPinActiveButtons_Set2[1] = CangPin_ShuXing_Special_CangPin_Active_Btn_1_1
	g_CangPinActiveButtons_Set2[2] = CangPin_ShuXing_Special_CangPin_Active_Btn_1_2
	g_CangPinActiveButtons_Set2[3] = CangPin_ShuXing_Special_CangPin_Active_Btn_1_3
	g_CangPinActiveButtons_Set2[4] = CangPin_ShuXing_Special_CangPin_Active_Btn_1_4
	g_CangPinActiveButtons_Set2[5] = CangPin_ShuXing_Special_CangPin2_Active_Btn
	g_CangPinActiveButtons_Set2[6] = CangPin_ShuXing_Special_CangPin3_Active_Btn
	g_CangPinActiveButtons_Set2[7] = CangPin_ShuXing_Special_CangPin4_Active_Btn
	
	g_CangPinActiveButtonTips_Set2[1] = CangPin_ShuXing_Special_CangPin_Active_Btn_Buttontips_1_1
	g_CangPinActiveButtonTips_Set2[2] = CangPin_ShuXing_Special_CangPin_Active_Btn_Buttontips_1_2
	g_CangPinActiveButtonTips_Set2[3] = CangPin_ShuXing_Special_CangPin_Active_Btn_Buttontips_1_3
	g_CangPinActiveButtonTips_Set2[4] = CangPin_ShuXing_Special_CangPin_Active_Btn_Buttontips_1_4
	g_CangPinActiveButtonTips_Set2[5] = CangPin_ShuXing_Special_CangPin2_Active_Btn_Buttontips
	g_CangPinActiveButtonTips_Set2[6] = CangPin_ShuXing_Special_CangPin3_Active_Btn_Buttontips
	g_CangPinActiveButtonTips_Set2[7] = CangPin_ShuXing_Special_CangPin4_Active_Btn_Buttontips
	
	g_CangPinStarupButtons_Set2[1] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_1_1
	g_CangPinStarupButtons_Set2[2] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_1_2
	g_CangPinStarupButtons_Set2[3] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_1_3
	g_CangPinStarupButtons_Set2[4] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_1_4
	g_CangPinStarupButtons_Set2[5] = CangPin_ShuXing_Special_CangPin2_LevelUp_Btn
	g_CangPinStarupButtons_Set2[6] = CangPin_ShuXing_Special_CangPin3_LevelUp_Btn
	g_CangPinStarupButtons_Set2[7] = CangPin_ShuXing_Special_CangPin4_LevelUp_Btn
	
	g_CangPinStarupButtonTips_Set2[1] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_Buttontips_1_1
	g_CangPinStarupButtonTips_Set2[2] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_Buttontips_1_2
	g_CangPinStarupButtonTips_Set2[3] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_Buttontips_1_3
	g_CangPinStarupButtonTips_Set2[4] = CangPin_ShuXing_Special_CangPin_LevelUp_Btn_Buttontips_1_4
	g_CangPinStarupButtonTips_Set2[5] = CangPin_ShuXing_Special_CangPin2_LevelUp_Btn_Buttontips
	g_CangPinStarupButtonTips_Set2[6] = CangPin_ShuXing_Special_CangPin3_LevelUp_Btn_Buttontips
	g_CangPinStarupButtonTips_Set2[7] = CangPin_ShuXing_Special_CangPin4_LevelUp_Btn_Buttontips
	
	g_CangPinStarImages_Set2[1] = CangPin_ShuXing_Special_CangPin_LevelNum_1_1
	g_CangPinStarImages_Set2[2] = CangPin_ShuXing_Special_CangPin_LevelNum_1_2
	g_CangPinStarImages_Set2[3] = CangPin_ShuXing_Special_CangPin_LevelNum_1_3
	g_CangPinStarImages_Set2[4] = CangPin_ShuXing_Special_CangPin_LevelNum_1_4
	g_CangPinStarImages_Set2[5] = CangPin_ShuXing_Special_CangPin2_LevelNum
	g_CangPinStarImages_Set2[6] = CangPin_ShuXing_Special_CangPin3_LevelNum
	g_CangPinStarImages_Set2[7] = CangPin_ShuXing_Special_CangPin4_LevelNum
	
	g_CangPinChipTexts_Set2[1] = CangPin_ShuXing_Special_CangPin_NumText_1_1
	g_CangPinChipTexts_Set2[2] = CangPin_ShuXing_Special_CangPin_NumText_1_2
	g_CangPinChipTexts_Set2[3] = CangPin_ShuXing_Special_CangPin_NumText_1_3
	g_CangPinChipTexts_Set2[4] = CangPin_ShuXing_Special_CangPin_NumText_1_4
	g_CangPinChipTexts_Set2[5] = CangPin_ShuXing_Special_CangPin2_NumText
	g_CangPinChipTexts_Set2[6] = CangPin_ShuXing_Special_CangPin3_NumText
	g_CangPinChipTexts_Set2[7] = CangPin_ShuXing_Special_CangPin4_NumText
	
	g_CangPinNameTexts_Set2[1] = nil
	g_CangPinNameTexts_Set2[2] = nil
	g_CangPinNameTexts_Set2[3] = nil
	g_CangPinNameTexts_Set2[4] = nil
	g_CangPinNameTexts_Set2[5] = CangPin_ShuXing_Special_CangPin2_NameBK_Text
	g_CangPinNameTexts_Set2[6] = CangPin_ShuXing_Special_CangPin3_NameBK_Text
	g_CangPinNameTexts_Set2[7] = CangPin_ShuXing_Special_CangPin4_NameBK_Text
	
	g_CangPinNameBKs_Set2[1] = nil
	g_CangPinNameBKs_Set2[2] = nil
	g_CangPinNameBKs_Set2[3] = nil
	g_CangPinNameBKs_Set2[4] = nil
	g_CangPinNameBKs_Set2[5] = CangPin_ShuXing_Special_CangPin2_NameBK
	g_CangPinNameBKs_Set2[6] = CangPin_ShuXing_Special_CangPin3_NameBK
	g_CangPinNameBKs_Set2[7] = CangPin_ShuXing_Special_CangPin4_NameBK
	
	g_CangPinBKImages_Set2[1] = nil
	g_CangPinBKImages_Set2[2] = nil
	g_CangPinBKImages_Set2[3] = nil
	g_CangPinBKImages_Set2[4] = nil
	g_CangPinBKImages_Set2[5] = CangPin_ShuXing_Special_CangPin2_BKImage
	g_CangPinBKImages_Set2[6] = CangPin_ShuXing_Special_CangPin3_BKImage
	g_CangPinBKImages_Set2[7] = CangPin_ShuXing_Special_CangPin4_BKImage

	g_CangPin_ShuXing_PageButton[1] = CangPin_ShuXing_SelfEquip
	g_CangPin_ShuXing_PageButton[2] = CangPin_ShuXing_SelfData
	g_CangPin_ShuXing_PageButton[3] = CangPin_ShuXing_Pet
	g_CangPin_ShuXing_PageButton[4] = CangPin_ShuXing_Infant
	g_CangPin_ShuXing_PageButton[5] = CangPin_ShuXing_Wuhun
	g_CangPin_ShuXing_PageButton[6] = CangPin_ShuXing_Xiulian
	g_CangPin_ShuXing_PageButton[7] = CangPin_ShuXing_Miji
	g_CangPin_ShuXing_PageButton[8] = CangPin_ShuXing_ZhenYuan
	g_CangPin_ShuXing_PageButton[9] = CangPin_ShuXing_JingMai
	g_CangPin_ShuXing_PageButton[10] = CangPin_ShuXing_ShenDing
	g_CangPin_ShuXing_PageButton[11] = CangPin_ShuXing_JueWei
	g_CangPin_ShuXing_PageButton[12] = CangPin_ShuXing_BaoJian
	g_CangPin_ShuXing_PageButton[13] = CangPin_ShuXing_WuYi
	g_CangPin_ShuXing_PageButton[14] = CangPin_ShuXing_ShenQi
	g_CangPin_ShuXing_PageButton[15] = CangPin_ShuXing_Armor
	g_CangPin_ShuXing_PageButton[16] = CangPin_ShuXing_CangPin
	g_CangPin_ShuXing_PageButton[17] = CangPin_ShuXing_OtherInfo
	
	g_CangPin_ShuXing_PageMask[1] = CangPin_ShuXing_SelfEquip_tips
	g_CangPin_ShuXing_PageMask[2] = CangPin_ShuXing_SelfData_tips
	g_CangPin_ShuXing_PageMask[3] = CangPin_ShuXing_Pet_tips
	g_CangPin_ShuXing_PageMask[4] = CangPin_ShuXing_Infant_tips
	g_CangPin_ShuXing_PageMask[5] = CangPin_ShuXing_Wuhun_tips
	g_CangPin_ShuXing_PageMask[6] = CangPin_ShuXing_Xiulian_tips
	g_CangPin_ShuXing_PageMask[7] = CangPin_ShuXing_Miji_tips
	g_CangPin_ShuXing_PageMask[8] = CangPin_ShuXing_ZhenYuan_tips
	g_CangPin_ShuXing_PageMask[9] = CangPin_ShuXing_JingMai_tips
	g_CangPin_ShuXing_PageMask[10] = CangPin_ShuXing_ShenDing_tips
	g_CangPin_ShuXing_PageMask[11] = CangPin_ShuXing_JueWei_tips
	g_CangPin_ShuXing_PageMask[12] = CangPin_ShuXing_BaoJian_tips
	g_CangPin_ShuXing_PageMask[13] = CangPin_ShuXing_WuYi_tips
	g_CangPin_ShuXing_PageMask[14] = CangPin_ShuXing_ShenQi_tips
	g_CangPin_ShuXing_PageMask[15] = CangPin_ShuXing_Armor_tips
	g_CangPin_ShuXing_PageMask[16] = CangPin_ShuXing_CangPin_tips
	g_CangPin_ShuXing_PageMask[17] = CangPin_ShuXing_OtherInfo_tips
	
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

function CangPin_ShuXing_OnEvent(event)

	if event == "OPEN_CANGPIN" then
		if not this:IsVisible() then
			g_CurClass = tonumber(arg0)
			CangPin_ShuXing_OnShow()
			--CangPin_ShuXing_CleanUp()
			this:Show()
			CangPin_ShuXing_ShowPage()
			CangPin_ShuXing_Update()
			local iLevel = Player:GetLevel()
			CangPin_ShuXing_Refresh_Page_Button(iLevel)
		else
			this:Activate()
			local iLevel = Player:GetLevel()
			CangPin_ShuXing_Refresh_Page_Button(iLevel)
			CangPin_ShuXing_ShowPage()
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_ShuXing_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "CANGPIN_UPDATE" and this:IsVisible() then
		if arg0 == "unlock" then
			g_TargetCangPinId = tonumber(arg1)
		end
		
		if arg0 == "starup" then
			g_TargetCangPinId = tonumber(arg1)
		end

		CangPin_ShuXing_Update()
		return
	end
	
	if event == "MARTIAL_UPDATE"  or event == "MARTIAL_HIDE_ZHAOHUI_TIP" then
		CangPin_ShuXing_RefreshWuYiTip()
		return
	end
	
	if event == "UPDATE_TOY_TIP" then
		CangPin_ShuXing_RefreshOtherInfoTip()
	end
	
	if event == "UPDATE_WILLGET_MISSION_TRACK" or event == "TOGGLE_UPDATE_INFANT" or event == "FINISH_MISSION" then
		local iLevel = Player:GetLevel()
		CangPin_ShuXing_Refresh_Page_Button(iLevel)
		CangPin_ShuXing_ShowPage()
		return
	end
	
	if event == "UPDATE_MISSION_DATA" then
		local iLevel = Player:GetLevel()
		CangPin_ShuXing_Refresh_Page_Button(iLevel)
		CangPin_ShuXing_ShowPage()
	end
end

function CangPin_ShuXing_OnShow()
	CangPin_ShuXing_CangPin:SetCheck(1)
	local selfUnionPos = Variable:GetVariable("SelfUnionPos")
	if selfUnionPos ~= nil then
		CangPin_ShuXing_Frame:SetProperty("UnifiedPosition", selfUnionPos)
	end
end

function CangPin_ShuXing_InitList()
	if g_InitList == 0 then
		for i = 1, g_ClassCount do
			g_SetCount[i] = 0
			g_SetList[i] = {}
		end

		local all_set_count = LuaFnGetMaxCangPinSetCount()
		for i = 1, all_set_count do
			local set_id, class_id = LuaFnGetCangPinSetFromTable(i - 1)
			if set_id >= 0 and class_id >= 0 and class_id < g_ClassCount then
				g_SetCount[class_id + 1] = g_SetCount[class_id + 1] + 1
				g_SetList[class_id + 1][g_SetCount[class_id + 1]] = set_id
			end
		end
		
		for i = 1, g_ClassCount do
			for m = 1, g_SetCount[i] - 1 do
				for n = m + 1, g_SetCount[i] do
					local oValue_a = LuaFnGetCangPinSetOrderValue(g_SetList[i][m])
					local oValue_b = LuaFnGetCangPinSetOrderValue(g_SetList[i][n])
					if oValue_b > oValue_a then
						local tmp = g_SetList[i][m]
						g_SetList[i][m] = g_SetList[i][n]
						g_SetList[i][n] = tmp
					end
				end
			end
		end
		
		g_MaxSetBarNum = 0
		for i = 1, g_ClassCount do
			if g_SetCount[i] > g_MaxSetBarNum then
				g_MaxSetBarNum = g_SetCount[i]
			end
		end
		
		for i = 1, g_MaxSetBarNum do
			local bar = CangPin_ShuXing_TypeList:AddChild("CangPin_ShuXing_TypeListItem")
		--	bar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
			g_SetBarList[i] = bar			
			
			bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn"):SetProperty("CheckMode", "2")
			bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn"):SetEvent("MouseLButtonDown", string.format("CangPin_ShuXing_SetSelect(%d)", i))
		end

		g_InitList = 1
	end
end

function CangPin_ShuXing_Update()
	
	CangPin_ShuXing_Update_ClassBtn()
	CangPin_ShuXing_Update_SetList()
	CangPin_ShuXing_Update_CangPinList()
	CangPin_ShuXing_Update_SetInfo()
	local strTemp = ""

	CangPin_ShuXing_TotalLevelBK:SetProperty("Image", tostring(g_BannerImages[g_CurClass]))

	CangPin_ShuXing_TotalBuffBtn:SetToolTip(tostring(g_ClassEffectTips[g_CurClass]))
	
	local collect_val = DataPool:LuaFnGetCangPinClassCollectValue(g_CurClass - 1)
	local max_collect_val = DataPool:LuaFnGetCangPinMaxClassCollectValue(g_CurClass - 1)
	local class_level, cur_val, max_val = LuaFnGetCangPinClassLevel(collect_val)
	CangPin_ShuXing_TotalLevel_Progress:SetProgress(tonumber(cur_val), tonumber(max_val))

	strTemp = ScriptGlobal_Format("#{CPSJ_260112_147}", tostring(cur_val), tostring(max_val))
	CangPin_ShuXing_TotalLevel_JinDuNumText:SetText(tostring(strTemp))
	
	CangPin_ShuXing_TotalLevel_Text:SetText("")
	if g_ClassLevelStr[g_CurClass] ~= nil then
		strTemp = ScriptGlobal_Format(g_ClassLevelStr[g_CurClass], tostring(class_level))
	end
	CangPin_ShuXing_TotalLevel_Text:SetText(tostring(strTemp))
	
	CangPin_ShuXing_ShowClassLevelImage(tonumber(class_level))

	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	if bHaveChipToMelt == 1 then
		CangPin_ShuXing_TaoZhuang_ChaiJieBtn_Buttontips:Show()
	else
		CangPin_ShuXing_TaoZhuang_ChaiJieBtn_Buttontips:Hide()
	end
	
	local bTip = 0
	for i = 1, g_ClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 16 and g_PageButtonTipsPos[idx] then -- 名物
			local newpos = g_PageButtonTipsPos[idx] --28 + g_CangPin_ShuXing_PageButton[idx]:GetProperty("UnifiedXPosition");
			CangPin_ShuXing_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		CangPin_ShuXing_CangPin_Buttontips:Show()
	else
		CangPin_ShuXing_CangPin_Buttontips:Hide()
	end
end

function CangPin_ShuXing_GetClassCollectLevel(val)
	local lv = 0
	local cur_val = val
	local max_val = 10
	if val >= 10 and val < 30 then
		lv = 1
		cur_val = val - 10
		max_val = 20
	elseif val >= 30 and val < 50 then
		lv = 2
		cur_val = val - 30
		max_val = 20
	elseif val >= 50 and val < 70 then
		lv = 3
		cur_val = val - 50
		max_val = 20
	elseif val >= 70 and val < 90 then
		lv = 4
		cur_val = val - 70
		max_val = 20
	elseif val >= 90 and val < 120 then
		lv = 5
		cur_val = val - 90
		max_val = 30
	elseif val >= 120 and val < 150 then
		lv = 6
		cur_val = val - 120
		max_val = 30
	elseif val >= 150 and val < 200 then
		lv = 7
		cur_val = val - 150
		max_val = 50
	elseif val >= 200 then
		lv = math.floor(val / 100) + 6
		cur_val = math.mod(val, 100)
		max_val = 100
	end
	return lv, cur_val, max_val
end

local g_NumImages = {
	[0] = "set:CangPin_1 image:CangPin_LevelNum0",
	[1] = "set:CangPin_1 image:CangPin_LevelNum1",
	[2] = "set:CangPin_1 image:CangPin_LevelNum2",
	[3] = "set:CangPin_1 image:CangPin_LevelNum3",
	[4] = "set:CangPin_1 image:CangPin_LevelNum4",
	[5] = "set:CangPin_1 image:CangPin_LevelNum5",
	[6] = "set:CangPin_1 image:CangPin_LevelNum6",
	[7] = "set:CangPin_1 image:CangPin_LevelNum7",
	[8] = "set:CangPin_1 image:CangPin_LevelNum8",
	[9] = "set:CangPin_1 image:CangPin_LevelNum9",
}

function CangPin_ShuXing_ShowClassLevelImage(lv)
	CangPin_ShuXing_LevelNumImage_1:Hide()
	CangPin_ShuXing_LevelNumImage_2:Hide()
	CangPin_ShuXing_LevelNumImage_3:Hide()
	
	if lv >= 0 and lv < 10 then
		CangPin_ShuXing_LevelNumImage_1:Show()
		CangPin_ShuXing_LevelNumImage_1_1:SetProperty("Image", tostring(g_NumImages[lv]))
	elseif lv >= 10 and lv < 100 then
		local num1 = math.floor(lv / 10)
		local num2 = math.mod(lv, 10)
		CangPin_ShuXing_LevelNumImage_2:Show()
		CangPin_ShuXing_LevelNumImage_2_1:SetProperty("Image", tostring(g_NumImages[num1]))
		CangPin_ShuXing_LevelNumImage_2_2:SetProperty("Image", tostring(g_NumImages[num2]))
	elseif lv >= 100 and lv < 1000 then
		local num1 = math.floor(lv / 100)
		local num2 = math.floor(math.mod(lv, 100) / 10)
		local num3 = math.mod(lv, 10)
		CangPin_ShuXing_LevelNumImage_3:Show()
		CangPin_ShuXing_LevelNumImage_3_1:SetProperty("Image", tostring(g_NumImages[num1]))
		CangPin_ShuXing_LevelNumImage_3_2:SetProperty("Image", tostring(g_NumImages[num2]))
		CangPin_ShuXing_LevelNumImage_3_3:SetProperty("Image", tostring(g_NumImages[num3]))
	end
end

function CangPin_ShuXing_Update_SetList()
	CangPin_ShuXing_InitList()
	
	local uClassNum = 0
	if g_SetCount[g_CurClass] ~= nil then
		uClassNum = g_SetCount[g_CurClass]
	end

	for i = 1, g_MaxSetBarNum do
		local bar = g_SetBarList[i]
		if bar ~= nil then
			if i > uClassNum then
				bar:Hide()
			else
				bar:Show()
				
				local set_id = g_SetList[g_CurClass][i]
				local set_name = LuaFnGetCangPinSetName(set_id)
				bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn_Text"):SetText(tostring(set_name))
				if g_CurSet == -1 then
					g_CurSet = set_id
				end

				if g_CurSet == set_id then
					bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn"):SetCheck(1)
				else
					bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn"):SetCheck(0)
				end
				
				local bTip = DataPool:LuaFnIsCangPinSetShowTip(set_id)
				if bTip == 1 then
					bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn_Buttontips"):Show()
				else
					bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn_Buttontips"):Hide()
				end
			end
		end
	end
	
	CangPin_ShuXing_TypeList:RefreshLayout()
end

function CangPin_ShuXing_Update_SetInfo()

	CangPin_ShuXing_TaoZhuang_BuffText:ClearAllElement()
	CangPin_ShuXing_ActiveBuffList:Clear()
	CangPin_ShuXing_TaoZhuang_TotalBuffBtn:Hide()
	
	local strTemp = ""
	
	if g_CurSet >= 0 then
		local set_lv = DataPool:LuaFnGetCangPinSetEffectLevel(g_CurSet)
		local have_set_effect = LuaFnIsCangPinSetHaveEffect(g_CurSet)
		local have_set_xj_effect = LuaFnIsCangPinSetHaveXianJieEffect(g_CurSet)
		
		if have_set_effect == 1 then
			CangPin_ShuXing_TaoZhuang_TotalBuffBtn:Show()
			if have_set_xj_effect == 1 then
				local xj_level = DataPool:LuaFnGetCangPinSetXianJieLevel(g_CurSet)
				local set_effect_desc = ""
				local xj_effect_desc = ""
				
				if set_lv ~= 0 then
					set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, set_lv)
					set_effect_desc = "#cfff263"..tostring(set_effect_desc)
				else 
					set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, 1)
					set_effect_desc = "#c7F7F7F"..tostring(set_effect_desc)
				end
				
				if xj_level ~= 0 and set_lv ~= 0 then
					xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(g_CurSet, xj_level)
					xj_effect_desc = "#cfff263"..tostring(xj_effect_desc)
				else
					xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(g_CurSet, 1)
					xj_effect_desc = "#c7F7F7F"..tostring(xj_effect_desc)
				end
				
				CangPin_ShuXing_TaoZhuang_BuffText:AddTextElement(tostring(set_effect_desc).."#r"..tostring(xj_effect_desc))
			else
				if set_lv ~= 0 then
					local set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, set_lv)
					CangPin_ShuXing_TaoZhuang_BuffText:AddTextElement("#cfff263"..tostring(set_effect_desc))
				else 
					local set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, 1)
					CangPin_ShuXing_TaoZhuang_BuffText:AddTextElement("#c7F7F7F"..tostring(set_effect_desc))
				end
			end
		end
		
		DataPool:LuaFnInitCangPinSetSumAttrList(g_CurSet)
		local ct = DataPool:LuaFnGetCangPinSetSumAttrCount()

		if ct > 0 then
			for i = 1, ct do
				local attrString = DataPool:LuaFnGetCangPinSetSumAttr(i - 1)
				if tostring(attrString) ~= nil and tostring(attrString) ~= "" then
					local bar = CangPin_ShuXing_ActiveBuffList:AddChild("CangPin_ShuXing_ActiveBuffListItem")
					bar:GetSubItem("CangPin_ShuXing_ActiveBuff_Text"):SetText("#cfff263"..tostring(attrString))
				end
			end
			CangPin_ShuXing_ActiveBuffList:RefreshLayout()
		end
	end
end

function CangPin_ShuXing_SetSelect(idx)
	local set_id = g_SetList[g_CurClass][idx]
	if set_id == nil then
		return
	end

	g_CurSet = set_id
	CangPin_ShuXing_SetClassSelected(idx)
	
	g_CurCangPinPage = 0
	CangPin_ShuXing_Update_CangPinList()
	CangPin_ShuXing_Update_SetInfo()
end

function CangPin_ShuXing_SetClassSelected(idx)
	for i = 1, g_MaxSetBarNum do
		local bar = g_SetBarList[i]
		if bar ~= nil then
			if i == idx then
				bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn"):SetCheck(1)
			else
				bar:GetSubItem("CangPin_ShuXing_TypeListItem_Btn"):SetCheck(0)
			end
		end
	end
end

function CangPin_ShuXing_Update_CangPinList()
	--特写
	if g_CurSet == 2 then
		CangPin_ShuXing_Update_CangPinList_Set2()
		return
	end
	
	CangPin_ShuXing_CangPinListBK:Show()
	CangPin_ShuXing_Special_CangPinListBK:Hide()
	
	local uCangPinNum = 0
	if g_CurSet >= 0 then
		uCangPinNum = LuaFnGetCangPinCountInSet(g_CurSet)
	end
	
	g_CurCangPinMaxPage = math.floor((uCangPinNum - 1) / g_EachPageCangPinNum) + 1
	if g_CurCangPinPage >= g_CurCangPinMaxPage then
		g_CurCangPinPage = 0
	end
	
	local star_cangpin_idx = g_CurCangPinPage * g_EachPageCangPinNum
	
	local strTemp = ""
	
	for i = 1, g_EachPageCangPinNum do
		if star_cangpin_idx >= uCangPinNum then
			g_CangPinNameBKs[i]:Hide()
			g_CangPinActionButtons[i]:SetActionItem(-1)
			g_CangPinLockImages[i]:Hide()
			g_CangPinBKImages[i]:Hide()
			g_CangPinActiveButtons[i]:Hide()
			g_CangPinActiveButtonTips[i]:Hide()
			g_CangPinStarImages[i]:Hide()
			g_CangPinStarupButtons[i]:Hide()
			g_CangPinStarupButtonTips[i]:Hide()
			g_CangPinChipTexts[i]:Hide()
		else
			g_CangPinNameBKs[i]:Show()
			g_CangPinActionButtons[i]:SetActionItem(-1)
			g_CangPinBKImages[i]:Show()
			
			local cangpin_id = LuaFnGetCangPinIdInSet(g_CurSet, star_cangpin_idx)
			local nUnLocked = DataPool:LuaFnGetCangPinData(cangpin_id, "UnLocked")
			local nChipCount = DataPool:LuaFnGetCangPinData(cangpin_id, "ChipCount")
			local strName = DataPool:LuaFnGetCangPinData(cangpin_id, "Name")
			local qual = DataPool:LuaFnGetCangPinData(cangpin_id, "Quality")
			local bCanQualUp = DataPool:LuaFnGetCangPinData(cangpin_id, "CanQualUp")
			local nQualUpLevel = DataPool:LuaFnGetCangPinData(cangpin_id, "QualUpLevel")
			
			if nQualUpLevel == g_MaxQualUpLevel then
				strName = DataPool:LuaFnGetCangPinData(cangpin_id, "QualUpName")
			end
			
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_148}", tostring(strName))
			g_CangPinNameTexts[i]:SetText(tostring(strTemp))
			
			local theAction = EnumAction(cangpin_id, "cangpin")
			if theAction:GetID() ~= 0 then
				g_CangPinActionButtons[i]:SetActionItem(theAction:GetID())
			end
			
			if nUnLocked == 1 then
				g_CangPinLockImages[i]:Hide()

				if qual == 4 and bCanQualUp == 1 and nQualUpLevel == g_MaxQualUpLevel then
					local strBK = DataPool:LuaFnGetCangPinData(cangpin_id, "XianJieBKImage")
					g_CangPinBKImages[i]:SetProperty("Image", tostring(strBK))
				else
					local strBK = DataPool:LuaFnGetCangPinData(cangpin_id, "BKImage")
					g_CangPinBKImages[i]:SetProperty("Image", tostring(strBK))
				end

				g_CangPinActiveButtons[i]:Hide()
				g_CangPinActiveButtonTips[i]:Hide()
				g_CangPinStarImages[i]:Show()

				local nStar = DataPool:LuaFnGetCangPinData(cangpin_id, "Star")
				if nStar == g_MaxStar then
					g_CangPinStarupButtons[i]:Hide()
					g_CangPinStarupButtonTips[i]:Hide()
					g_CangPinChipTexts[i]:Hide()
				else
					g_CangPinStarupButtons[i]:Show()
					g_CangPinChipTexts[i]:Show()
					local _, nStarUpNeedCount, _ = DataPool:LuaFnGetCangPinStarInfo(cangpin_id, nStar, "Need")
					strTemp = ScriptGlobal_Format("#{CPSJ_260112_10}", tostring(nChipCount), tostring(nStarUpNeedCount))
					g_CangPinChipTexts[i]:SetText(tostring(strTemp))
					
					if nChipCount >= nStarUpNeedCount then
						g_CangPinStarupButtonTips[i]:Show()
					else
						g_CangPinStarupButtonTips[i]:Hide()
					end
				end
				
				g_CangPinStarImages[i]:SetProperty("Image", tostring(g_StarImg[nStar]))
			else
				g_CangPinLockImages[i]:Show()
				g_CangPinChipTexts[i]:Show()
				
				local strLockBK = DataPool:LuaFnGetCangPinData(cangpin_id, "LockBK")
				g_CangPinBKImages[i]:SetProperty("Image", tostring(strLockBK))
				
				local nActiveNeedChipCount = DataPool:LuaFnGetCangPinData(cangpin_id, "ActiveNeedChipCount")
				if nChipCount >= nActiveNeedChipCount then
					g_CangPinActiveButtons[i]:Show()
					g_CangPinActiveButtonTips[i]:Show()
				else
					g_CangPinActiveButtons[i]:Hide()
					g_CangPinActiveButtonTips[i]:Hide()
				end
				g_CangPinStarupButtons[i]:Hide()
				g_CangPinStarupButtonTips[i]:Hide()
				g_CangPinStarImages[i]:Hide()
				
				strTemp = ScriptGlobal_Format("#{CPSJ_260112_10}", tostring(nChipCount), tostring(nActiveNeedChipCount))
				g_CangPinChipTexts[i]:SetText(tostring(strTemp))
			end
		end
		
		star_cangpin_idx = star_cangpin_idx + 1
	end
end

function CangPin_ShuXing_Update_CangPinList_Set2()
	--特写
	if g_CurSet ~= 2 then
		return
	end
	
	CangPin_ShuXing_CangPinListBK:Hide()
	CangPin_ShuXing_Special_CangPinListBK:Show()
	
	local uCangPinNum = LuaFnGetCangPinCountInSet(g_CurSet)

	g_CurCangPinMaxPage = math.floor((uCangPinNum - 1) / g_EachPageCangPinNum_Set2) + 1
	if g_CurCangPinPage >= g_CurCangPinMaxPage then
		g_CurCangPinPage = 0
	end
	
	local star_cangpin_idx = g_CurCangPinPage * g_EachPageCangPinNum_Set2
	
	local strTemp = ""
	
	local fourIn1_actived = 0
	for i = 1, g_EachPageCangPinNum_Set2 do
		if star_cangpin_idx >= uCangPinNum then
			if g_CangPinNameBKs_Set2[i] ~= nil then
				g_CangPinNameBKs_Set2[i]:Hide()
			end
			g_CangPinActionButtons_Set2[i]:SetActionItem(-1)
			g_CangPinLockImages_Set2[i]:Hide()
			if g_CangPinBKImages_Set2[i] ~= nil then
				g_CangPinBKImages_Set2[i]:Hide()
			end
			g_CangPinActiveButtons_Set2[i]:Hide()
			g_CangPinActiveButtonTips_Set2[i]:Hide()
			g_CangPinStarImages_Set2[i]:Hide()
			g_CangPinStarupButtons_Set2[i]:Hide()
			g_CangPinStarupButtonTips_Set2[i]:Hide()
			g_CangPinChipTexts_Set2[i]:Hide()
		else
			if g_CangPinNameBKs_Set2[i] ~= nil then
				g_CangPinNameBKs_Set2[i]:Show()
			end
			g_CangPinActionButtons_Set2[i]:SetActionItem(-1)
			if g_CangPinBKImages_Set2[i] ~= nil then
				g_CangPinBKImages_Set2[i]:Show()
			end
			
			local cangpin_id = LuaFnGetCangPinIdInSet(g_CurSet, star_cangpin_idx)
			local nUnLocked = DataPool:LuaFnGetCangPinData(cangpin_id, "UnLocked")
			local nChipCount = DataPool:LuaFnGetCangPinData(cangpin_id, "ChipCount")
			local strName = DataPool:LuaFnGetCangPinData(cangpin_id, "Name")
			local qual = DataPool:LuaFnGetCangPinData(cangpin_id, "Quality")
			local bCanQualUp = DataPool:LuaFnGetCangPinData(cangpin_id, "CanQualUp")
			local nQualUpLevel = DataPool:LuaFnGetCangPinData(cangpin_id, "QualUpLevel")
			
			if nQualUpLevel == g_MaxQualUpLevel then
				strName = DataPool:LuaFnGetCangPinData(cangpin_id, "QualUpName")
			end
		
			if g_CangPinNameTexts_Set2[i] ~= nil then
				strTemp = ScriptGlobal_Format("#{CPSJ_260112_148}", tostring(strName))
				g_CangPinNameTexts_Set2[i]:SetText(tostring(strTemp))
			end
			
			local theAction = EnumAction(cangpin_id, "cangpin")
			if theAction:GetID() ~= 0 then
				g_CangPinActionButtons_Set2[i]:SetActionItem(theAction:GetID())
			end
			
			if nUnLocked == 1 then
				if i >= 1 and i <= 4 then
					fourIn1_actived = 1
				end
				g_CangPinLockImages_Set2[i]:Hide()

				if qual == 4 and bCanQualUp == 1 and nQualUpLevel == g_MaxQualUpLevel then
					local strBK = DataPool:LuaFnGetCangPinData(cangpin_id, "XianJieBKImage")
					if g_CangPinBKImages_Set2[i] ~= nil then
						g_CangPinBKImages_Set2[i]:SetProperty("Image", tostring(strBK))
					end
				else
					local strBK = DataPool:LuaFnGetCangPinData(cangpin_id, "BKImage")
					if g_CangPinBKImages_Set2[i] ~= nil then
						g_CangPinBKImages_Set2[i]:SetProperty("Image", tostring(strBK))
					end
				end

				g_CangPinActiveButtons_Set2[i]:Hide()
				g_CangPinActiveButtonTips_Set2[i]:Hide()
				g_CangPinStarImages_Set2[i]:Show()

				local nStar = DataPool:LuaFnGetCangPinData(cangpin_id, "Star")
				if nStar == g_MaxStar then
					g_CangPinStarupButtons_Set2[i]:Hide()
					g_CangPinStarupButtonTips_Set2[i]:Hide()
					g_CangPinChipTexts_Set2[i]:Hide()
				else
					g_CangPinStarupButtons_Set2[i]:Show()
					g_CangPinChipTexts_Set2[i]:Show()
					local _, nStarUpNeedCount, _ = DataPool:LuaFnGetCangPinStarInfo(cangpin_id, nStar, "Need")
					strTemp = ScriptGlobal_Format("#{CPSJ_260112_10}", tostring(nChipCount), tostring(nStarUpNeedCount))
					g_CangPinChipTexts_Set2[i]:SetText(tostring(strTemp))
					
					if nChipCount >= nStarUpNeedCount then
						g_CangPinStarupButtonTips_Set2[i]:Show()
					else
						g_CangPinStarupButtonTips_Set2[i]:Hide()
					end
				end
				
				g_CangPinStarImages_Set2[i]:SetProperty("Image", tostring(g_StarImg[nStar]))
			else
				g_CangPinLockImages_Set2[i]:Show()
				g_CangPinChipTexts_Set2[i]:Show()
				
				local strLockBK = DataPool:LuaFnGetCangPinData(cangpin_id, "LockBK")
				if g_CangPinBKImages_Set2[i] ~= nil then
					g_CangPinBKImages_Set2[i]:SetProperty("Image", tostring(strLockBK))
				end
				
				local nActiveNeedChipCount = DataPool:LuaFnGetCangPinData(cangpin_id, "ActiveNeedChipCount")
				if nChipCount >= nActiveNeedChipCount then
					g_CangPinActiveButtons_Set2[i]:Show()
					g_CangPinActiveButtonTips_Set2[i]:Show()
				else
					g_CangPinActiveButtons_Set2[i]:Hide()
					g_CangPinActiveButtonTips_Set2[i]:Hide()
				end
				g_CangPinStarupButtons_Set2[i]:Hide()
				g_CangPinStarupButtonTips_Set2[i]:Hide()
				g_CangPinStarImages_Set2[i]:Hide()
				
				strTemp = ScriptGlobal_Format("#{CPSJ_260112_10}", tostring(nChipCount), tostring(nActiveNeedChipCount))
				g_CangPinChipTexts_Set2[i]:SetText(tostring(strTemp))
			end
		end
		
		star_cangpin_idx = star_cangpin_idx + 1
	end
	
	CangPin_ShuXing_Special_Table_Image_3_TitleBK_Text:SetText("#{CPSJ_260112_151}")
	if fourIn1_actived == 1 then
		CangPin_ShuXing_Special_Table_Image_3_ShowLight:Show()
	else
		CangPin_ShuXing_Special_Table_Image_3_ShowLight:Hide()
	end
end

function CangPin_ShuXing_Active_Clicked(idx)

	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end

	local iEachPageCangPinNum = g_EachPageCangPinNum
	if g_CurSet == 2 then
		iEachPageCangPinNum = g_EachPageCangPinNum_Set2
	end
	local cangpin_idx = g_CurCangPinPage * iEachPageCangPinNum + idx - 1
	local cangpin_id = LuaFnGetCangPinIdInSet(g_CurSet, cangpin_idx)

	local nUnLocked = DataPool:LuaFnGetCangPinData(cangpin_id, "UnLocked")
	if nUnLocked == 1 then
		return
	end
	
	local nChipCount = DataPool:LuaFnGetCangPinData(cangpin_id, "ChipCount")
	local nActiveNeedChipCount = DataPool:LuaFnGetCangPinData(cangpin_id, "ActiveNeedChipCount")
	if nChipCount < nActiveNeedChipCount then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UnlockCangPin")
		Set_XSCRIPT_ScriptID(885555)
		Set_XSCRIPT_Parameter(0, cangpin_id)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function CangPin_ShuXing_SwitchClass(idx)
	if g_CurClass == idx then
		return
	end
	g_CurClass = idx
	g_CurSet = -1
	CangPin_ShuXing_Update()
end

function CangPin_ShuXing_Update_ClassBtn()
	for i = 1, g_ClassCount do
		if i == g_CurClass then
			g_ClassBtn[i]:SetCheck(1)
		else
			g_ClassBtn[i]:SetCheck(0)
		end
		
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			g_ClassBtnTip[i]:Show()
		else
			g_ClassBtnTip[i]:Hide()
		end
	end
end

function CangPin_ShuXing_LevelUp_Clicked(idx)
	local iEachPageCangPinNum = g_EachPageCangPinNum
	if g_CurSet == 2 then
		iEachPageCangPinNum = g_EachPageCangPinNum_Set2
	end
	local cangpin_idx = g_CurCangPinPage * iEachPageCangPinNum + idx - 1
	local cangpin_id = LuaFnGetCangPinIdInSet(g_CurSet, cangpin_idx)
	LuaFnOpenCangPinLevelUp(cangpin_id)
end

function CangPin_ShuXing_ShowHelp()

end

function CangPin_ShuXing_LeftArrowBtn_OnClick()
	if g_CurCangPinPage > 0 then
		g_CurCangPinPage = g_CurCangPinPage - 1
		CangPin_ShuXing_Update_CangPinList()
	end
end

function CangPin_ShuXing_RightArrowBtn_OnClick()
	if g_CurCangPinPage < g_CurCangPinMaxPage - 1 then
		g_CurCangPinPage = g_CurCangPinPage + 1
		CangPin_ShuXing_Update_CangPinList()
	end
end

function CangPin_ShuXing_ShowClassEffect()
	LuaFnOpenCangPinClassEffect(g_CurClass - 1)
end

function CangPin_ShuXing_ShowSetEffect()
	local have_set_effect = LuaFnIsCangPinSetHaveEffect(g_CurSet)
	if have_set_effect == 1 then
		LuaFnOpenCangPinSetEffect(g_CurSet)
	end
end

function CangPin_ShuXing_ShowHelp()
	PushEvent("OPEN_SWEEPPAGE_QUEST", "CangPin_ShuXing_Help")
end

function CangPin_ShuXing_TaoZhuang_ChaiJieBtn_OnClick()
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	if bHaveChipToMelt == 1 then
		LuaFnOpenCangPinMelt()
	else
		PushDebugMessage("#{CPSJ_260112_45}")
	end
end

function CangPin_ShuXing_CloseClicked()
	this:Hide()
end

function CangPin_ShuXing_CleanUp()
	g_CurSet = -1
end

function CangPin_ShuXing_OnHidden()
	CangPin_ShuXing_CleanUp()
	m_ObjServerId = -1
end

--Care Obj
function CangPin_ShuXing_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function CangPin_ShuXing_Frame_On_ResetPos()
	if g_CangPin_ShuXing_Frame_UnifiedPosition ~= nil then
		CangPin_ShuXing_Frame:SetProperty("UnifiedPosition", g_CangPin_ShuXing_Frame_UnifiedPosition)
	end
end

--装备
function CangPin_ShuXing_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	OpenEquip(1)
end

--资料
function CangPin_ShuXing_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("self")
end

--珍兽
function CangPin_ShuXing_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	TogglePetPage()
end

--子女
function CangPin_ShuXing_Infant_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:ToggleInfantPage()
	if bRet == 1 then
		this:Hide()
	else
		CangPin_ShuXing_Infant:SetCheck(0)
	end
end

--武魂
function CangPin_ShuXing_Wuhun_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	ToggleWuhunPage()
end

--修炼
function CangPin_ShuXing_Xiulian_Page_Switch()
    local iLevel = Player:GetData("LEVEL")
	if iLevel >= 70 then
		Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
		XiuLianPage()
	else
		CangPin_ShuXing_Xiulian:SetCheck(0)
		PushDebugMessage("#{XL_090707_62}")
	end
end

--秘籍
function CangPin_ShuXing_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenMijiPage()
	if nRet ~= 1 then
		CangPin_ShuXing_Miji:SetCheck(0)
	end
end

--真元
function CangPin_ShuXing_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleZhenYuanPage()
	if bRet == 1 then
		this:Hide()
	end
end

--经脉
function CangPin_ShuXing_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenJingMaiPage()
	if nRet == 1 then
		this:Hide()
		-- CangPin_ShuXing_CangPin_ShuXing:SetCheck(0)
	else
		CangPin_ShuXing_JingMai:SetCheck(0)
	end
end

--神木王鼎
function CangPin_ShuXing_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenShenDingPage()
	if nRet ~= 1 then
		CangPin_ShuXing_ShenDing:SetCheck(0)
	end
end

--侠印
function CangPin_ShuXing_JueWei_Page_Switch()
	if Player:GetLevel() < 85 then
		PushDebugMessage("#{JXJW_140822_20}")
		return
	end
	
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = OpenJunXianPage()
	if bRet == 1 then
		this:Hide()
	else
		CangPin_ShuXing_JueWei:SetCheck(0)
	end
end

--五行宝鉴
function CangPin_ShuXing_BaoJian_Page_Switch()
	local iLevel = Player:GetLevel()
	if iLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()
end

--武意
function CangPin_ShuXing_WuYi_Page_Switch()
	local iLevel = Player:GetLevel()
	if MaritialSys:HasFinishWuYiMisson() ~= 1 or iLevel < 85 then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("MARTIAL_SHOWWUYI")
end

--神器
function CangPin_ShuXing_ShenQi_Page_Switch()
	if DataPool:Lua_IsMissionHaveDone(1950) ~= 1 then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--内甲
function CangPin_ShuXing_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function CangPin_ShuXing_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

--其他
function CangPin_ShuXing_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	OtherInfoPage()
end

--骑乘
function CangPin_ShuXing_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	OpenRidePage()
end

function CangPin_ShuXing_Refresh_Page_Button(nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if nLevel < 15 then
		CangPin_ShuXing_ShenDing:Disable()
		CangPin_ShuXing_ShenDing_tips:Show()
	else
		CangPin_ShuXing_ShenDing:Enable()
		CangPin_ShuXing_ShenDing_tips:Hide()
	end

	--子女
	local InfantCount = Infant:GetInfantCount()
	if nLevel < 50 or InfantCount <= 0 then
		CangPin_ShuXing_Infant:Disable()
		CangPin_ShuXing_Infant_tips:Show()
	else
		CangPin_ShuXing_Infant:Enable()
		CangPin_ShuXing_Infant_tips:Hide()
	end

	CangPin_ShuXing_Wuhun:Enable()
	CangPin_ShuXing_Wuhun_tips:Hide()

	--修炼
	if nLevel < 70 then
		CangPin_ShuXing_Xiulian:Disable()
		CangPin_ShuXing_Xiulian_tips:Show()
	else
		CangPin_ShuXing_Xiulian:Enable()
		CangPin_ShuXing_Xiulian_tips:Hide()
	end

	--秘籍
	if nLevel < 75 or DataPool:Lua_IsMissionHaveDone(1651) == 0 then
		CangPin_ShuXing_Miji:Disable()
		CangPin_ShuXing_Miji_tips:Show()
	else
		CangPin_ShuXing_Miji:Enable()
		CangPin_ShuXing_Miji_tips:Hide()
	end

	--真元
	if nLevel < 80 or DataPool:Lua_IsMissionHaveDone(1600) == 0 then
		CangPin_ShuXing_ZhenYuan:Disable()
		CangPin_ShuXing_ZhenYuan_tips:Show()
	else
		CangPin_ShuXing_ZhenYuan:Enable()
		CangPin_ShuXing_ZhenYuan_tips:Hide()
	end

	--侠印
	if nLevel < 85 then
		CangPin_ShuXing_JueWei:Disable()
		CangPin_ShuXing_JueWei_tips:Show()
	else
		CangPin_ShuXing_JueWei:Enable()
		CangPin_ShuXing_JueWei_tips:Hide()
	end

	--经脉
	if nLevel < 90 or DataPool:Lua_IsMissionHaveDone(1554) == 0  then
		CangPin_ShuXing_JingMai:Disable()
		CangPin_ShuXing_JingMai_tips:Show()
	else
		CangPin_ShuXing_JingMai:Enable()
		CangPin_ShuXing_JingMai_tips:Hide()
	end

	if nLevel < 85 then
		CangPin_ShuXing_BaoJian:Disable()
		CangPin_ShuXing_BaoJian_tips:Show()
	else
		CangPin_ShuXing_BaoJian:Enable()
		CangPin_ShuXing_BaoJian_tips:Hide()
	end

	--武意
	if MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85 then
		CangPin_ShuXing_WuYi:Enable()
		CangPin_ShuXing_WuYi_tips:Hide()
	else
		CangPin_ShuXing_WuYi:Disable()
		CangPin_ShuXing_WuYi_tips:Show()
	end

	CangPin_ShuXing_RefreshWuYiTip()

	--九星神器DIY技能
	if DataPool:Lua_IsMissionHaveDone(1950) == 1 then
		CangPin_ShuXing_ShenQi:Enable()
		CangPin_ShuXing_ShenQi_tips:Hide()
	else
		CangPin_ShuXing_ShenQi:Disable()
		CangPin_ShuXing_ShenQi_tips:Show()
	end

	CangPin_ShuXing_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		CangPin_ShuXing_Armor:Enable()
		CangPin_ShuXing_Armor_tips:Hide()
	else
		CangPin_ShuXing_Armor:Disable()
		CangPin_ShuXing_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		CangPin_ShuXing_CangPin:Enable()
		CangPin_ShuXing_CangPin_tips:Hide()
	else
		CangPin_ShuXing_CangPin:Disable()
		CangPin_ShuXing_CangPin_tips:Show()
	end
end

--刷新武意上的红点
function CangPin_ShuXing_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_CangPin_ShuXing_PageButton[idx]:GetProperty("UnifiedXPosition");
			CangPin_ShuXing_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum, nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1 then
		CangPin_ShuXing_WuYi_Buttontips:Show()
	else
		CangPin_ShuXing_WuYi_Buttontips:Hide()
	end
end

--刷新其他上的红点
function CangPin_ShuXing_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_CangPin_ShuXing_PageButton[idx]:GetProperty("UnifiedXPosition");
			CangPin_ShuXing_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then		
		CangPin_ShuXing_OtherInfo_ButtonTips:Show()
	else
		CangPin_ShuXing_OtherInfo_ButtonTips:Hide()
	end
end

function CangPin_ShuXing_ListClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenCangPinRankList")
		Set_XSCRIPT_ScriptID(885554)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


function CangPin_ShuXing_ShowPage()

	for i = 1, table.getn(g_CangPin_ShuXing_Page) do
		g_CangPin_ShuXing_PageButton[i]:Hide()
		g_CangPin_ShuXing_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	CangPin_ShuXing_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_CangPin_ShuXing_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_CangPin_ShuXing_Page) do
			if i ~= nPageNumber then
				g_CangPin_ShuXing_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_CangPin_ShuXing_Page) do
		if CangPin_ShuXing_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_CangPin_ShuXing_PageButton[g_PageCount]:Show()
			g_CangPin_ShuXing_PageButton[g_PageCount]:SetText(g_CangPin_ShuXing_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if CangPin_ShuXing_IsPageEnable(i) == 1 then
				g_CangPin_ShuXing_PageButton[g_PageCount]:Enable()
				g_CangPin_ShuXing_PageMask[g_PageCount]:Hide()
			else
				g_CangPin_ShuXing_PageButton[g_PageCount]:Disable()
				g_CangPin_ShuXing_PageMask[g_PageCount]:Show()
				if g_CangPin_ShuXing_Page[i].Tip ~= "" then
					g_CangPin_ShuXing_PageMask[g_PageCount]:SetToolTip(g_CangPin_ShuXing_Page[i].Tip)
				end
			end
		end
	end
	
	CangPin_ShuXing_RefreshWuYiTip()
	CangPin_ShuXing_RefreshOtherInfoTip()
	
end

function CangPin_ShuXing_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		CangPin_ShuXing_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		CangPin_ShuXing_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		CangPin_ShuXing_Pet_Page_Switch()
	elseif idx == 4 then--子女
		CangPin_ShuXing_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		CangPin_ShuXing_Wuhun_Page_Switch()
	elseif idx == 6 then--修炼
		CangPin_ShuXing_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		CangPin_ShuXing_Miji_Page_Switch()
	elseif idx == 8 then--真元
		CangPin_ShuXing_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		CangPin_ShuXing_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		CangPin_ShuXing_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		CangPin_ShuXing_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		CangPin_ShuXing_BaoJian_Page_Switch()
	elseif idx == 13 then--武意
		CangPin_ShuXing_WuYi_Page_Switch()
	elseif idx == 14 then--神器
		CangPin_ShuXing_ShenQi_Page_Switch()
	elseif idx == 15 then--星盘
		CangPin_ShuXing_Armor_Page_Switch()
	elseif idx == 16 then--名物
		--SelfData_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		CangPin_ShuXing_OtherInfo_Page_Switch()
	end
end

function CangPin_ShuXing_CheckPage(idx)
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

function CangPin_ShuXing_IsPageEnable(idx)
	
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

function CangPin_ShuXing_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


