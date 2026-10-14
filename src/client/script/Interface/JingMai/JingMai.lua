
local XUEWEI_LIST = {}
local XUEWEI_LIST_NAN = {}

local XUEWEI_ANIMATE = {}
local XUEWEI_ANIMATE_NAN = {}
local XUEWEI_MASK = {}

--打上秘法的动画
local XUEWEI_ANIMATE_ENHANSE = {}
local XUEWEI_ANIMATE_NAN_ENHANSE = {}
local XUEWEI_MASK_MAN = {}
local XUEWEI_SELECT = -1; --默认没有选中l

local g_JingMai_FenYe = 0


-- 界面的默认相对位置
local g_XueWei_Frame_UnifiedXPosition;
local g_XueWei_Frame_UnifiedYPosition;

--穴位没有秘法时的图标(但激活)
local g_XueWei_Image_NoMifa =  "set:JingMaiUI image:JingMai_Anniu_Jihuo"
local g_XueWei_Image_NoMifa_Select =  "set:JingMaiUI image:JingMai_Anniu_Jihuo1" --选中
--穴位没有秘法时的图标(没激活)
local g_XueWei_Image_NoActive = "set:JingMaiUI image:JingMai_Anniu_Weijihuo"
local g_XueWei_Image_NoActive_Select = "set:JingMaiUI image:JingMai_Anniu_Weijihuo1"--选中
--穴位有秘法对应的图标
local g_XueWei_Image_Set = {
                              [0] = "set:JingMaiUI image:JingMai_Anniu_Huang",--天井
							  [1] = "set:JingMaiUI image:JingMai_Anniu_Huang",--阳池
							  [2] = "set:JingMaiUI image:JingMai_Anniu_Lan",--血海
							  [3] = "set:JingMaiUI image:JingMai_Anniu_Lan",--箕门
							  [4] = "set:JingMaiUI image:JingMai_Anniu_Hong",--气海
							  [5] = "set:JingMaiUI image:JingMai_Anniu_Lv",--神庭
							  [6] = "set:JingMaiUI image:JingMai_Anniu_Lv",--至阳
							  [0+7] = "set:JingMaiUI image:JingMai_Anniu_Huang",--天井
							  [1+7] = "set:JingMaiUI image:JingMai_Anniu_Huang",--阳池
							  [2+7] = "set:JingMaiUI image:JingMai_Anniu_Lan",--血海
							  [3+7] = "set:JingMaiUI image:JingMai_Anniu_Lan",--箕门
							  [4+7] = "set:JingMaiUI image:JingMai_Anniu_Hong",--气海
							  [5+7] = "set:JingMaiUI image:JingMai_Anniu_Lv",--神庭
							  [6+7] = "set:JingMaiUI image:JingMai_Anniu_Lv",--至阳
							  [0+14] = "set:JingMaiUI image:JingMai_Anniu_Huang",--天井
							  [1+14] = "set:JingMaiUI image:JingMai_Anniu_Huang",--阳池
							  [2+14] = "set:JingMaiUI image:JingMai_Anniu_Lan",--血海
							  [3+14] = "set:JingMaiUI image:JingMai_Anniu_Lan",--箕门
							  [4+14] = "set:JingMaiUI image:JingMai_Anniu_Hong",--气海
							  [5+14] = "set:JingMaiUI image:JingMai_Anniu_Lv",--神庭
							  [6+14] = "set:JingMaiUI image:JingMai_Anniu_Lv",--至阳
}

--穴位没有秘法时的图标(但激活)
local g_XueWei_Image_NoMifa_wm =  "set:WM_Jingmai1 image:JingMai_Anniu_Jihuo"
local g_XueWei_Image_NoMifa_Select_wm =  "set:WM_Jingmai1 image:JingMai_Anniu_Jihuo1" --选中
--穴位没有秘法时的图标(没激活)
local g_XueWei_Image_NoActive_wm = "set:WM_Jingmai1 image:JingMai_Anniu_Weijihuo"
local g_XueWei_Image_NoActive_Select_wm = "set:WM_Jingmai1 image:JingMai_Anniu_Weijihuo1"--选中
--穴位有秘法对应的图标
local g_XueWei_Image_Set_wm = {
                              [0] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--天井
							  [1] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--阳池
							  [2] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--血海
							  [3] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--箕门
							  [4] = "set:WM_Jingmai1 image:JingMai_Anniu_Hong",--气海
							  [5] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--神庭
							  [6] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--至阳
							  [0+7] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--天井
							  [1+7] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--阳池
							  [2+7] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--血海
							  [3+7] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--箕门
							  [4+7] = "set:WM_Jingmai1 image:JingMai_Anniu_Hong",--气海
							  [5+7] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--神庭
							  [6+7] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--至阳
							  [0+14] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--天井
							  [1+14] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--阳池
							  [2+14] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--血海
							  [3+14] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--箕门
							  [4+14] = "set:WM_Jingmai1 image:JingMai_Anniu_Hong",--气海
							  [5+14] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--神庭
							  [6+14] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--至阳
}
--切换经脉脚本
g_JingMai_QHJM_ScriptId = 800815
--MF 是否开启经脉分页2 经脉分页3 Pneuma:GetMF(g_JingMai_MF_OpenFenye2) ~= 1
g_JingMai_MF_OpenFenye2 = 4531
g_JingMai_MF_OpenFenye3 = 4532
g_JingMai_Fenye_1 = 0
g_JingMai_Fenye_2 = 1
g_JingMai_Fenye_3 = 2

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfJingMai_Page = {
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

local g_SelfJingMai_PageButton = {}
local g_SelfJingMai_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function SelfJingMai_PreLoad()

	-- 打开界面
	this:RegisterEvent("OPEN_JINGMAI_PAGE");

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("XUEWEI_UPDATE");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("EQUIPGEM_JINJIE_SCORE_CHANGE");

	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION");
	
	this:RegisterEvent("MARTIAL_UPDATE",false)
	
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("SWITCHMENPAI",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
	this:RegisterEvent("XUEWEI_FENYE", true)
end

function SelfJingMai_OnLoad()

	XUEWEI_LIST[0] = SelfJingMai_NV1_TianJing --天井
	XUEWEI_LIST[1] = SelfJingMai_NV1_YangChi --阳池
	XUEWEI_LIST[2] = SelfJingMai_NV1_XueHai --血海
	XUEWEI_LIST[3] = SelfJingMai_NV1_QiMen --箕门
	XUEWEI_LIST[4] = SelfJingMai_NV1_TanZhong --檀中(现在是气海了)
	XUEWEI_LIST[5] = SelfJingMai_NV1_ShenTing --神庭
	XUEWEI_LIST[6] = SelfJingMai_NV1_RenZhong --人中(现在是至阳了)
	
	XUEWEI_LIST[0+7] = SelfJingMai_NV2_TianJing --天井
	XUEWEI_LIST[1+7] = SelfJingMai_NV2_YangChi --阳池
	XUEWEI_LIST[2+7] = SelfJingMai_NV2_XueHai --血海
	XUEWEI_LIST[3+7] = SelfJingMai_NV2_QiMen --箕门
	XUEWEI_LIST[4+7] = SelfJingMai_NV2_TanZhong --檀中(现在是气海了)
	XUEWEI_LIST[5+7] = SelfJingMai_NV2_ShenTing --神庭
	XUEWEI_LIST[6+7] = SelfJingMai_NV2_RenZhong --人中(现在是至阳了)
	
	XUEWEI_LIST[0+14] = SelfJingMai_NV3_TianJing --天井
	XUEWEI_LIST[1+14] = SelfJingMai_NV3_YangChi --阳池
	XUEWEI_LIST[2+14] = SelfJingMai_NV3_XueHai --血海
	XUEWEI_LIST[3+14] = SelfJingMai_NV3_QiMen --箕门
	XUEWEI_LIST[4+14] = SelfJingMai_NV3_TanZhong --檀中(现在是气海了)
	XUEWEI_LIST[5+14] = SelfJingMai_NV3_ShenTing --神庭
	XUEWEI_LIST[6+14] = SelfJingMai_NV3_RenZhong --人中(现在是至阳了)
	----------------------------------------------------------------

	XUEWEI_ANIMATE[0] = SelfJingMai_NV1_TianJingAnimate
	XUEWEI_ANIMATE[1] = SelfJingMai_NV1_YangChiAnimate
	XUEWEI_ANIMATE[2] = SelfJingMai_NV1_XueHaiAnimate
	XUEWEI_ANIMATE[3] = SelfJingMai_NV1_QiMenAnimate
	XUEWEI_ANIMATE[4] = SelfJingMai_NV1_TanZhongAnimate
	XUEWEI_ANIMATE[5] = SelfJingMai_NV1_ShenTingAnimate
	XUEWEI_ANIMATE[6] = SelfJingMai_NV1_RenZhongAnimate

	XUEWEI_ANIMATE[0+7] = SelfJingMai_NV2_TianJingAnimate
	XUEWEI_ANIMATE[1+7] = SelfJingMai_NV2_YangChiAnimate
	XUEWEI_ANIMATE[2+7] = SelfJingMai_NV2_XueHaiAnimate
	XUEWEI_ANIMATE[3+7] = SelfJingMai_NV2_QiMenAnimate
	XUEWEI_ANIMATE[4+7] = SelfJingMai_NV2_TanZhongAnimate
	XUEWEI_ANIMATE[5+7] = SelfJingMai_NV2_ShenTingAnimate
	XUEWEI_ANIMATE[6+7] = SelfJingMai_NV2_RenZhongAnimate

	XUEWEI_ANIMATE[0+14] = SelfJingMai_NV3_TianJingAnimate
	XUEWEI_ANIMATE[1+14] = SelfJingMai_NV3_YangChiAnimate
	XUEWEI_ANIMATE[2+14] = SelfJingMai_NV3_XueHaiAnimate
	XUEWEI_ANIMATE[3+14] = SelfJingMai_NV3_QiMenAnimate
	XUEWEI_ANIMATE[4+14] = SelfJingMai_NV3_TanZhongAnimate
	XUEWEI_ANIMATE[5+14] = SelfJingMai_NV3_ShenTingAnimate
	XUEWEI_ANIMATE[6+14] = SelfJingMai_NV3_RenZhongAnimate

	XUEWEI_MASK[0] = SelfJingMai_NV1_TianJing_Mask
	XUEWEI_MASK[1] = SelfJingMai_NV1_YangChi_Mask
	XUEWEI_MASK[2] = nil
	XUEWEI_MASK[3] = nil
	XUEWEI_MASK[4] = SelfJingMai_NV1_TanZhong_Mask
	XUEWEI_MASK[5] = nil
	XUEWEI_MASK[6] = nil

	XUEWEI_MASK[0+7] = SelfJingMai_NV2_TianJing_Mask
	XUEWEI_MASK[1+7] = SelfJingMai_NV2_YangChi_Mask
	XUEWEI_MASK[2+7] = nil
	XUEWEI_MASK[3+7] = nil
	XUEWEI_MASK[4+7] = SelfJingMai_NV2_TanZhong_Mask
	XUEWEI_MASK[5+7] = nil
	XUEWEI_MASK[6+7] = nil

	XUEWEI_MASK[0+14] = SelfJingMai_NV3_TianJing_Mask
	XUEWEI_MASK[1+14] = SelfJingMai_NV3_YangChi_Mask
	XUEWEI_MASK[2+14] = nil
	XUEWEI_MASK[3+14] = nil
	XUEWEI_MASK[4+14] = SelfJingMai_NV3_TanZhong_Mask
	XUEWEI_MASK[5+14] = nil
	XUEWEI_MASK[6+14] = nil

	XUEWEI_MASK_MAN[0] = SelfJingMai_NAN1_TianJing_Mask
	XUEWEI_MASK_MAN[1] = SelfJingMai_NAN1_YangChi_Mask
	XUEWEI_MASK_MAN[2] = nil
	XUEWEI_MASK_MAN[3] = nil
	XUEWEI_MASK_MAN[4] = SelfJingMai_NAN1_TanZhong_Mask
	XUEWEI_MASK_MAN[5] = nil
	XUEWEI_MASK_MAN[6] = nil

	XUEWEI_MASK_MAN[0+7] = SelfJingMai_NAN2_TianJing_Mask
	XUEWEI_MASK_MAN[1+7] = SelfJingMai_NAN2_YangChi_Mask
	XUEWEI_MASK_MAN[2+7] = nil
	XUEWEI_MASK_MAN[3+7] = nil
	XUEWEI_MASK_MAN[4+7] = SelfJingMai_NAN2_TanZhong_Mask
	XUEWEI_MASK_MAN[5+7] = nil
	XUEWEI_MASK_MAN[6+7] = nil

	XUEWEI_MASK_MAN[0+14] = SelfJingMai_NAN3_TianJing_Mask
	XUEWEI_MASK_MAN[1+14] = SelfJingMai_NAN3_YangChi_Mask
	XUEWEI_MASK_MAN[2+14] = nil
	XUEWEI_MASK_MAN[3+14] = nil
	XUEWEI_MASK_MAN[4+14] = SelfJingMai_NAN3_TanZhong_Mask
	XUEWEI_MASK_MAN[5+14] = nil
	XUEWEI_MASK_MAN[6+14] = nil


	XUEWEI_ANIMATE_ENHANSE[0] = SelfJingMai_NV1_TianJingAnimate1
	XUEWEI_ANIMATE_ENHANSE[1] = SelfJingMai_NV1_YangChiAnimate1
	XUEWEI_ANIMATE_ENHANSE[2] = SelfJingMai_NV1_XueHaiAnimate1
	XUEWEI_ANIMATE_ENHANSE[3] = SelfJingMai_NV1_QiMenAnimate1
	XUEWEI_ANIMATE_ENHANSE[4] = SelfJingMai_NV1_TanZhongAnimate1
	XUEWEI_ANIMATE_ENHANSE[5] = SelfJingMai_NV1_ShenTingAnimate1
	XUEWEI_ANIMATE_ENHANSE[6] = SelfJingMai_NV1_RenZhongAnimate1

	XUEWEI_ANIMATE_ENHANSE[0+7] = SelfJingMai_NV2_TianJingAnimate1
	XUEWEI_ANIMATE_ENHANSE[1+7] = SelfJingMai_NV2_YangChiAnimate1
	XUEWEI_ANIMATE_ENHANSE[2+7] = SelfJingMai_NV2_XueHaiAnimate1
	XUEWEI_ANIMATE_ENHANSE[3+7] = SelfJingMai_NV2_QiMenAnimate1
	XUEWEI_ANIMATE_ENHANSE[4+7] = SelfJingMai_NV2_TanZhongAnimate1
	XUEWEI_ANIMATE_ENHANSE[5+7] = SelfJingMai_NV2_ShenTingAnimate1
	XUEWEI_ANIMATE_ENHANSE[6+7] = SelfJingMai_NV2_RenZhongAnimate1

	XUEWEI_ANIMATE_ENHANSE[0+14] = SelfJingMai_NV3_TianJingAnimate1
	XUEWEI_ANIMATE_ENHANSE[1+14] = SelfJingMai_NV3_YangChiAnimate1
	XUEWEI_ANIMATE_ENHANSE[2+14] = SelfJingMai_NV3_XueHaiAnimate1
	XUEWEI_ANIMATE_ENHANSE[3+14] = SelfJingMai_NV3_QiMenAnimate1
	XUEWEI_ANIMATE_ENHANSE[4+14] = SelfJingMai_NV3_TanZhongAnimate1
	XUEWEI_ANIMATE_ENHANSE[5+14] = SelfJingMai_NV3_ShenTingAnimate1
	XUEWEI_ANIMATE_ENHANSE[6+14] = SelfJingMai_NV3_RenZhongAnimate1

	-- 保存界面的默认相对位置
	g_XueWei_Frame_UnifiedXPosition	= SelfJingMai_Frame : GetProperty("UnifiedXPosition");
	g_XueWei_Frame_UnifiedYPosition	= SelfJingMai_Frame : GetProperty("UnifiedYPosition");

	--屏蔽 隐藏切换经脉附近的控件
	SelfJingMai_NAN1Watch_Frame_sub:Hide()
	SelfJingMai_NAN1_Btn:Hide()
	SelfJingMai_NV1Watch_Frame_sub:Hide()
	SelfJingMai_NV1_Btn:Hide()
	SelfJingMai_NAN2Watch_Frame_sub:Hide()
	SelfJingMai_NAN2_Btn:Hide()
	SelfJingMai_NV2Watch_Frame_sub:Hide()
	SelfJingMai_NV2_Btn:Hide()
	SelfJingMai_NAN3Watch_Frame_sub:Hide()
	SelfJingMai_NAN3_Btn:Hide()
	SelfJingMai_NV3Watch_Frame_sub:Hide()
	SelfJingMai_NV3_Btn:Hide()
	
	g_SelfJingMai_PageButton[1] = SelfJingMai_Equip
	g_SelfJingMai_PageButton[2] = SelfJingMai_SelfData
	g_SelfJingMai_PageButton[3] = SelfJingMai_Pet
	g_SelfJingMai_PageButton[4] = SelfJingMai_Infant
	g_SelfJingMai_PageButton[5] = SelfJingMai_Wuhun
	g_SelfJingMai_PageButton[6] = SelfJingMai_Xiulian
	g_SelfJingMai_PageButton[7] = SelfJingMai_Miji
	g_SelfJingMai_PageButton[8] = SelfJingMai_ZhenYuan
	g_SelfJingMai_PageButton[9] = SelfJingMai_JingMaiInfo
	g_SelfJingMai_PageButton[10] = SelfJingMai_ShenDing
	g_SelfJingMai_PageButton[11] = SelfJingMai_JueWei
	g_SelfJingMai_PageButton[12] = SelfJingMai_BaoJian
	g_SelfJingMai_PageButton[13] = SelfJingMai_WuYi
	g_SelfJingMai_PageButton[14] = SelfJingMai_ShenQi
	g_SelfJingMai_PageButton[15] = SelfJingMai_Armor
	g_SelfJingMai_PageButton[16] = SelfJingMai_CangPin
	g_SelfJingMai_PageButton[17] = SelfJingMai_OtherInfo
	
	g_SelfJingMai_PageMask[1] = SelfJingMai_Equip_tips
	g_SelfJingMai_PageMask[2] = SelfJingMai_SelfData_tips
	g_SelfJingMai_PageMask[3] = SelfJingMai_Pet_tips
	g_SelfJingMai_PageMask[4] = SelfJingMai_Infant_tips
	g_SelfJingMai_PageMask[5] = SelfJingMai_Wuhun_tips
	g_SelfJingMai_PageMask[6] = SelfJingMai_Xiulian_tips
	g_SelfJingMai_PageMask[7] = SelfJingMai_Miji_tips
	g_SelfJingMai_PageMask[8] = SelfJingMai_ZhenYuan_tips
	g_SelfJingMai_PageMask[9] = SelfJingMai_JingMaiInfo_tips
	g_SelfJingMai_PageMask[10] = SelfJingMai_ShenDing_tips
	g_SelfJingMai_PageMask[11] = SelfJingMai_JueWei_tips
	g_SelfJingMai_PageMask[12] = SelfJingMai_BaoJian_tips
	g_SelfJingMai_PageMask[13] = SelfJingMai_WuYi_tips
	g_SelfJingMai_PageMask[14] = SelfJingMai_ShenQi_tips
	g_SelfJingMai_PageMask[15] = SelfJingMai_Armor_tips
	g_SelfJingMai_PageMask[16] = SelfJingMai_CangPin_tips
	g_SelfJingMai_PageMask[17] = SelfJingMai_OtherInfo_tips
	
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

-- OnEvent
function SelfJingMai_OnEvent(event)
	--PushDebugMessage(event)
	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION")  then
		local nLevel =Player:GetLevel()
		SelfJingMai_Refresh_Page_Button(nLevel)
		SelfJingMai_ShowPage()
	end
	
	if ( event == "SWITCHMENPAI" ) then
		Animate_Update()
	end
	if ( event == "OPEN_JINGMAI_PAGE" ) then

	    if(this:IsVisible()) then
			if(arg0 == "dontclose") then
				Player:LuaFnSetCurrentJingMaiPage(g_JingMai_FenYe) --使用秘法时设置一次当前页
				if g_JingMai_FenYe == g_JingMai_Fenye_1 then
					--SelfJingMai_FenYe1:SetProperty("Selected", "True");
				elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
					--SelfJingMai_FenYe2:SetProperty("Selected", "True");
				elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
					--SelfJingMai_FenYe3:SetProperty("Selected", "True");
				end
			else
				this:Hide();
				return;
			end
		else
			g_JingMai_FenYe = GetJingMaiFenYeFlag() --打开经脉页面时默认已激活页
			if g_JingMai_FenYe == nil or g_JingMai_FenYe < g_JingMai_Fenye_1 or g_JingMai_FenYe > g_JingMai_Fenye_3 then
				g_JingMai_FenYe = g_JingMai_Fenye_1
			end
			if SelfJingMai_IsOnlyFenYe1() == 1 then --2 3页都没解锁，也就是只有第一页
				g_JingMai_FenYe = g_JingMai_Fenye_1
			end
			--PushDebugMessage(g_JingMai_FenYe)
			Player:LuaFnSetCurrentJingMaiPage(g_JingMai_FenYe) --打开经脉界面设置一次当前页
		end
		
		SelfJingMai_LoadControl()

		--隐藏所有动画
		for jj=0,6+14 do
			XUEWEI_ANIMATE[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_NAN[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_ENHANSE[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_NAN_ENHANSE[jj]:SetProperty("Visible", "False")
			if XUEWEI_MASK_MAN[jj] ~= nil then
				XUEWEI_MASK_MAN[jj]:SetProperty("Visible", "False")
			end
			if XUEWEI_MASK[jj] ~= nil then
				XUEWEI_MASK[jj]:SetProperty("Visible", "False")
			end
		end

		local iSexy = Player:GetMySex()
		
		SelfJingMai_fenye_update(iSexy)
		if iSexy == 1 then
			--SelfJingMai_NAN1_BEIJING1:Show();
            if SystemSetup:IsClassic() == 1 then
    			--SelfJingMai_NAN1_BEIJING2:Show()
            end

			--SelfJingMai_NV1_BEIJING1:Hide()
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NV1_BEIJING2:Hide()
            end

			for i=0,6+14 do
				XUEWEI_LIST[i]:Hide()
				XUEWEI_LIST_NAN[i]:Show()
			end
		else
			--SelfJingMai_NAN1_BEIJING1:Hide();
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NAN1_BEIJING2:Hide()
            end

			--SelfJingMai_NV1_BEIJING1:Show()
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NV1_BEIJING2:Show()
            end

			for i=0,6+14 do
				XUEWEI_LIST[i]:Show()
				XUEWEI_LIST_NAN[i]:Hide()
			end
		end

	    local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	    if(selfUnionPos ~= nil) then
			if arg0 == "dontclose" then
				Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
			else
				SelfJingMai_Frame:SetProperty("UnifiedPosition", selfUnionPos);
			end
    	end

		XUEWEI_SELECT = -1;
		
		this:Show();
		XueWei_Update()
		if arg0 == "dontclose" then
			Animate_Update()
		end
		if Player:LuaFnIsUsingMifa() == 1 then--处于使用秘法道具准备镶嵌穴位状态时，出穴位bling动画
			Animate_Update()
		end
		XueWei_SetSelectState()
		XueWei_SetTabState()

		local nLevel =Player:GetLevel()
		SelfJingMai_Refresh_Page_Button(nLevel)
		SelfJingMai_ShowPage()
	end

	if( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	end
	

	if( event == "XUEWEI_FENYE") then
		
		g_JingMai_FenYe = tonumber(arg0)
		SelfJingMai_FenYe()
		return;
	end
	if( event == "XUEWEI_UPDATE" ) then

		SelfJingMai_LoadControl()
		--影藏所有动画
		for jj=0,6+14 do
			XUEWEI_ANIMATE[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_NAN[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_ENHANSE[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_NAN_ENHANSE[jj]:SetProperty("Visible", "False")
		end

		local iSexy = Player:GetMySex()
		SelfJingMai_fenye_update(iSexy)
		if iSexy == 1 then
			--SelfJingMai_NAN1_BEIJING1:Show();
            if SystemSetup:IsClassic() == 1 then
			  --SelfJingMai_NAN1_BEIJING2:Show();
            end

			--SelfJingMai_NV1_BEIJING1:Hide()
            if SystemSetup:IsClassic() == 1 then
			   -- SelfJingMai_NV1_BEIJING2:Hide()
            end

			for i=0,6+14 do
				XUEWEI_LIST[i]:Hide()
				XUEWEI_LIST_NAN[i]:Show()
			end
		else
			----SelfJingMai_NAN1_BEIJING1:Hide();
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NAN1_BEIJING2:Hide();
            end

			--SelfJingMai_NV1_BEIJING1:Show()
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NV1_BEIJING2:Show()
            end

			for i=0,6+14 do
				XUEWEI_LIST[i]:Show()
				XUEWEI_LIST_NAN[i]:Hide()
			end
		end


		XueWei_Update()
		if Player:LuaFnIsUsingMifa() == 1 then--处于使用秘法道具准备镶嵌穴位状态时，出穴位bling动画
			Animate_Update()
		end

		--是否要播放打上的动画
		local nxueweiindex = tonumber(arg0)
		if nxueweiindex ~= -1 then
			if iSexy == 1 then --男的
				if XUEWEI_ANIMATE_NAN_ENHANSE[nxueweiindex] ~= nil then
					XUEWEI_ANIMATE_NAN_ENHANSE[nxueweiindex]:SetProperty("Visible", "True")
				end
			else
				if XUEWEI_ANIMATE_ENHANSE[nxueweiindex] ~= nil then
					XUEWEI_ANIMATE_ENHANSE[nxueweiindex]:SetProperty("Visible", "True")
				end
			end
		end

		XueWei_SetSelectState()
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新经脉界面位置
		JingMai_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新经脉界面位置
		JingMai_Frame_On_ResetPos()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 111008) then
		--打开并增加tips
		SelfJingMai_LoadControl()

		--影藏所有动画
		for jj=0,6+14 do
			XUEWEI_ANIMATE[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_NAN[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_ENHANSE[jj]:SetProperty("Visible", "False")
			XUEWEI_ANIMATE_NAN_ENHANSE[jj]:SetProperty("Visible", "False")
		end

		local iSexy = Player:GetMySex()
		
		SelfJingMai_fenye_update(iSexy)
		if iSexy == 1 then
			--SelfJingMai_NAN1_BEIJING1:Show();
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NAN1_BEIJING2:Show();
            end

			--SelfJingMai_NV1_BEIJING1:Hide()
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NV1_BEIJING2:Hide()
            end

			for i=0,6+14 do
				XUEWEI_LIST[i]:Hide()
				XUEWEI_LIST_NAN[i]:Show()
			end
		else
			--SelfJingMai_NAN1_BEIJING1:Hide();
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NAN1_BEIJING2:Hide();
            end

			--SelfJingMai_NV1_BEIJING1:Show()
            if SystemSetup:IsClassic() == 1 then
			    --SelfJingMai_NV1_BEIJING2:Show()
            end

			for i=0,6+14 do
				XUEWEI_LIST[i]:Show()
				XUEWEI_LIST_NAN[i]:Hide()
			end
		end

	    local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	    if(selfUnionPos ~= nil) then
			SelfJingMai_Frame:SetProperty("UnifiedPosition", selfUnionPos);
    	end

		XUEWEI_SELECT = -1;
		
		this:Show();
		XueWei_Update()
		XueWei_SetSelectState()
		XueWei_SetTabState()

		--开启tips
		local fX = 0
        local fY = 0
		if iSexy == 1 then
			fX, fY = this:GetChildOffset("SelfJingMai_NAN1_TianJing")
		else
			fX, fY = this:GetChildOffset("SelfJingMai_TianJing")
		end
		fX = fX + 27
	--	fY = fY + 10
		OpenFreshManGuide(1, 22, fX, fY, "SelfJingMai", "northeast")
	end

	if (event == "EQUIPGEM_JINJIE_SCORE_CHANGE") then
		if this:IsVisible() then
			JingMai_ShowGemScore()
		end
	end
	
	if(event == "MARTIAL_UPDATE"  or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SelfJingMai_RefreshWuYiTip()
	end

	if event == "UPDATE_TOY_TIP" then
		SelfJingMai_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfJingMai_RefreshCangPinTip()
	end

end

function SelfJingMai_OnMoved()
    if "SelfJingMai" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
		OpenFreshManGuide(2, -1, -1, -1)
    end
end

function JingMai_SelfEquip_Page_Switch()

	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	this:Hide();
end

function JingMai_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	TogglePetPage();
	this:Hide();
end

--神木王鼎
function JingMai_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	local bRet = OpenShenDingPage();
	if bRet == 1 then
		this:Hide()
	end
end

function JingMai_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	OpenRidePage();
	this:Hide();
end

function JingMai_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	SystemSetup:OpenPrivatePage("self");
	this:Hide();
end

function JingMai_Xiulian_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	XiuLianPage();
	this:Hide();
end

function JingMai_SelfJingMai_Page_Switch()
	SelfJingMai_JingMaiInfo:SetCheck(1)
end

function JingMai_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	this:Hide();
end

function JingMai_Wuhun_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
	this:Hide();
end

function XueWei_SetTabState()
	SelfJingMai_Equip:SetCheck(0)
	SelfJingMai_SelfData:SetCheck(0)
	SelfJingMai_Miji:SetCheck(0)
	SelfJingMai_Pet:SetCheck(0)
	SelfJingMai_Wuhun:SetCheck(0)
	SelfJingMai_Xiulian:SetCheck(0)
	SelfJingMai_Ride:SetCheck(0)
	SelfJingMai_JingMaiInfo:SetCheck(1)
	SelfJingMai_OtherInfo:SetCheck(0)
end


function JingMai_XueWei_Clicked(nIndex)
	if(nIndex < 21 and nIndex >= 0) then
		local theAction = EnumAction(nIndex, "xueweiinfo")
		if(theAction:GetID() ~= 0) then
			XUEWEI_SELECT = nIndex
			--XueWei_Selected_Update()
			XueWei_Update()
			XueWei_SetSelectState()

			local iSexy = Player:GetMySex()
			if iSexy == 1 then
				XUEWEI_LIST_NAN[nIndex]:DoSubAction()
			else
				XUEWEI_LIST[nIndex]:DoSubAction()
			end
		end
	end
end


--动画的更新
function Animate_Update()
	--取当前使用秘法需要激活的穴位动画
	--鉴于咱返回表的被废了，这个函数就返回所有穴位状态
	local xw0,xw1,xw2,xw3,xw4,xw5,xw6,xw7,xw8,xw9,xw10,xw11,xw12,xw13,xw14,xw15,xw16,xw17,xw18,xw19,xw20 = Player:GetMifaActiveXueWei()
	--PushDebugMessage("xw0="..xw0.." xw15="..xw15)
	local tmplist = {}
	tmplist[0] = xw0
	tmplist[1] = xw1
	tmplist[2] = xw2
	tmplist[3] = xw3
	tmplist[4] = xw4
	tmplist[5] = xw5
	tmplist[6] = xw6

	tmplist[0+7] = xw7
	tmplist[1+7] = xw8
	tmplist[2+7] = xw9
	tmplist[3+7] = xw10
	tmplist[4+7] = xw11
	tmplist[5+7] = xw12
	tmplist[6+7] = xw13

	tmplist[0+14] = xw14
	tmplist[1+14] = xw15
	tmplist[2+14] = xw16
	tmplist[3+14] = xw17
	tmplist[4+14] = xw18
	tmplist[5+14] = xw19
	tmplist[6+14] = xw20
	local iSexy = Player:GetMySex()
	for i=0,6+14 do
		if tmplist[i] == 1 then--激活
			if iSexy == 1 then
				XUEWEI_ANIMATE_NAN[i]:SetProperty("Visible", "True")
			else
				XUEWEI_ANIMATE[i]:SetProperty("Visible", "True")
			end
		else --没激活
			if iSexy == 1 then
				XUEWEI_ANIMATE_NAN[i]:SetProperty("Visible", "False")
			else
				XUEWEI_ANIMATE[i]:SetProperty("Visible", "False")
			end
		end
	end
end



--===============================================
-- 更新
--===============================================
function XueWei_Update()
	local iSexy = Player:GetMySex()
	for i = 0, 6+14 do
		local theAction = EnumAction(i, "xueweiinfo")

		if(theAction:GetID() ~= 0) then
			if iSexy == 1 then
				XUEWEI_LIST_NAN[i] : SetActionItem(theAction:GetID())
			else
				XUEWEI_LIST[i] : SetActionItem(theAction:GetID())
			end
		end
		if XUEWEI_MASK[i] ~= nil then
			XUEWEI_MASK[i]:SetProperty("Visible", "False")
		end
		if XUEWEI_MASK_MAN[i] ~= nil then
			XUEWEI_MASK_MAN[i]:SetProperty("Visible", "False")
		end
		if i==0 or i == 1 or i==4 or
		  (i== 7 or i == 8 or i == 11) or
		  (i== 14 or i == 15 or i == 18)  then
			local MifaMenpai = Player:GetMifaInfo(i, "MenpaiID")
			if MifaMenpai ~= nil and MifaMenpai ~= -1 and MifaMenpai~=Player:GetData("MEMPAI") then
				if iSexy == 1 then
					XUEWEI_MASK_MAN[i]:SetProperty("Visible", "True")
				else
					XUEWEI_MASK[i]:SetProperty("Visible", "True")
				end
			end				
		end

		local MifaName = Player:GetMifaInfo(i, "MifaName")
		if MifaName ~= nil then
			--说明该穴位有秘法
			if(SystemSetup:IsClassic() == 1) then
				if iSexy == 1 then
					XUEWEI_LIST_NAN[i]:SetProperty("NormalImage", g_XueWei_Image_Set[i])
					XUEWEI_LIST_NAN[i]:SetProperty("HoverImage", g_XueWei_Image_Set[i])
					XUEWEI_LIST_NAN[i]:SetProperty("PushedImage", g_XueWei_Image_Set[i])
				else
					XUEWEI_LIST[i]:SetProperty("NormalImage", g_XueWei_Image_Set[i])
					XUEWEI_LIST[i]:SetProperty("HoverImage", g_XueWei_Image_Set[i])
					XUEWEI_LIST[i]:SetProperty("PushedImage", g_XueWei_Image_Set[i])
				end
			else
				if iSexy == 1 then
					XUEWEI_LIST_NAN[i]:SetProperty("NormalImage", g_XueWei_Image_Set_wm[i])
					XUEWEI_LIST_NAN[i]:SetProperty("HoverImage", g_XueWei_Image_Set_wm[i])
					XUEWEI_LIST_NAN[i]:SetProperty("PushedImage", g_XueWei_Image_Set_wm[i])
				else
					XUEWEI_LIST[i]:SetProperty("NormalImage", g_XueWei_Image_Set_wm[i])
					XUEWEI_LIST[i]:SetProperty("HoverImage", g_XueWei_Image_Set_wm[i])
					XUEWEI_LIST[i]:SetProperty("PushedImage", g_XueWei_Image_Set_wm[i])
				end
			end
		else
			local nRet = Player:GetMifaInfo(i, "bActived")
			local lTubiao = nil
			if(SystemSetup:IsClassic() == 1) then
				if nRet == 1 then--已经激活
					if i == XUEWEI_SELECT then--选中
						lTubiao = g_XueWei_Image_NoMifa_Select
					else
						lTubiao = g_XueWei_Image_NoMifa
					end
				else
					if i == XUEWEI_SELECT then --选中
						lTubiao = g_XueWei_Image_NoActive_Select
					else
						lTubiao = g_XueWei_Image_NoActive
					end
				end
			else
				if nRet == 1 then--已经激活
					if i == XUEWEI_SELECT then--选中
						lTubiao = g_XueWei_Image_NoMifa_Select_wm
					else
						lTubiao = g_XueWei_Image_NoMifa_wm
					end
				else
					if i == XUEWEI_SELECT then --选中
						lTubiao = g_XueWei_Image_NoActive_Select_wm
					else
						lTubiao = g_XueWei_Image_NoActive_wm
					end
				end
			end

			if iSexy == 1 then
				XUEWEI_LIST_NAN[i]:SetProperty("NormalImage", lTubiao)
				XUEWEI_LIST_NAN[i]:SetProperty("HoverImage", lTubiao)
				XUEWEI_LIST_NAN[i]:SetProperty("PushedImage", lTubiao)
			else
				XUEWEI_LIST[i]:SetProperty("NormalImage", lTubiao)
				XUEWEI_LIST[i]:SetProperty("HoverImage", lTubiao)
				XUEWEI_LIST[i]:SetProperty("PushedImage", lTubiao)
			end
		end
	end
    XueWei_Selected_Update()
    --设置进阶评分
	SelfJingMai_Pingfen_Text:SetText("#{MPJJ_XT_XML_15}") --进阶评分：
	local nScore =  Player:GetData("UPGRADE_SCORE")
	SelfJingMai_Vigor:SetText(nScore)
	JingMai_ShowGemScore()

end

--===============================================
-- 选择穴位后刷新
--===============================================
function  XueWei_Selected_Update()

	if XUEWEI_SELECT < 0 or XUEWEI_SELECT > 6+14 then
		SelfJingMai_MifaName:SetText("")
		SelfJingMai_Jinjiexiaoguo:SetText("#{MPJJ_XT_110705_05}")
		SelfJingMai_dis:SetText("#{MPJJ_XT_XML_02}")
		SelfJingMai_Item:SetProperty("Image", "")
		return
	end

	local iSexy = Player:GetMySex()
	local nRet = Player:GetMifaInfo(XUEWEI_SELECT, "bActived")
	local lTubiao = nil
	if(SystemSetup:IsClassic() == 1) then
		if nRet == 1 then--已经激活
			lTubiao = g_XueWei_Image_NoMifa_Select
		else
			lTubiao = g_XueWei_Image_NoActive_Select
		end
	else
		if nRet == 1 then--已经激活
			lTubiao = g_XueWei_Image_NoMifa_Select_vm
		else
			lTubiao = g_XueWei_Image_NoActive_Select_vm
		end
	end

	--根据选择获得秘法信息
	local MifaName = Player:GetMifaInfo(XUEWEI_SELECT, "MifaName")
	if MifaName == nil then
		--说明该穴位没有秘法
		SelfJingMai_MifaName:SetText("")
	else
		--设置秘法名字
		SelfJingMai_MifaName:SetText(MifaName)

		if(SystemSetup:IsClassic() == 1) then
			lTubiao = g_XueWei_Image_Set[XUEWEI_SELECT]
		else
			lTubiao = g_XueWei_Image_Set_vm[XUEWEI_SELECT]
		end
	end

	if iSexy == 1 then
		XUEWEI_LIST_NAN[XUEWEI_SELECT]:SetProperty("NormalImage", lTubiao)
		XUEWEI_LIST_NAN[XUEWEI_SELECT]:SetProperty("HoverImage", lTubiao)
		XUEWEI_LIST_NAN[XUEWEI_SELECT]:SetProperty("PushedImage", lTubiao)
	else
		XUEWEI_LIST[XUEWEI_SELECT]:SetProperty("NormalImage", lTubiao)
		XUEWEI_LIST[XUEWEI_SELECT]:SetProperty("HoverImage", lTubiao)
		XUEWEI_LIST[XUEWEI_SELECT]:SetProperty("PushedImage", lTubiao)
	end

	--设置效果描述
	local MifaXiaoGuo = Player:GetMifaInfo(XUEWEI_SELECT, "MifaXiaoGuo")

	if MifaXiaoGuo ~= nil then
		SelfJingMai_Jinjiexiaoguo:SetText(MifaXiaoGuo)
	else
		local nActived = Player:GetMifaInfo(XUEWEI_SELECT, "bActived")
		if nActived ~= 1 then
			--如果没激活
			if XUEWEI_SELECT == 1 or XUEWEI_SELECT == 2 or XUEWEI_SELECT == 3 or 
			XUEWEI_SELECT == 8 or XUEWEI_SELECT == 9 or XUEWEI_SELECT == 10  or
			XUEWEI_SELECT == 15 or XUEWEI_SELECT == 16 or XUEWEI_SELECT == 17 then
				SelfJingMai_Jinjiexiaoguo:SetText("#{MPJJ_XT_110705_15}")--未激活，需要第1卷10级
			elseif XUEWEI_SELECT == 4 or XUEWEI_SELECT == 5 or XUEWEI_SELECT == 6 or 
			XUEWEI_SELECT == 11 or XUEWEI_SELECT == 12 or XUEWEI_SELECT == 13 or
			XUEWEI_SELECT == 18 or XUEWEI_SELECT == 19 or XUEWEI_SELECT == 20 then
				SelfJingMai_Jinjiexiaoguo:SetText("#{MPJJ_XT_110705_16}")--未激活，需要第1,2卷都20级
			else
				SelfJingMai_Jinjiexiaoguo:SetText("")--异常
			end
		else
			SelfJingMai_Jinjiexiaoguo:SetText("#{MPJJ_XT_110705_05}")
		end
	end

	local ZhengtiMiaosu = Player:GetMifaInfo(XUEWEI_SELECT, "XueWeiShuoMing")
	if ZhengtiMiaosu ~= nil then
		SelfJingMai_dis:SetText(ZhengtiMiaosu)
	else
		SelfJingMai_dis:SetText("#{MPJJ_XT_XML_02}")
	end

	--设置图标
	local IconName = Player:GetMifaInfo(XUEWEI_SELECT, "IconName")
	if IconName == nil then
		--说明该穴位没有秘法
		SelfJingMai_Item:SetProperty("Image", "")
	else
		--设置秘法技能图标
		local sPos, ePos = string.find(IconName, "_")
		if sPos ~= nil then
			local filename = string.sub(IconName, 0, sPos-1)
			local value = string.format("set:%s image:%s", filename, IconName)
			SelfJingMai_Item:SetProperty("Image", value)
		else
			SelfJingMai_Item:SetProperty("Image", "")
		end
	end

end
--===============================================
-- 设置选中状态
--===============================================
function XueWei_SetSelectState()
	local iSexy = Player:GetMySex()
	for i=0,6+14 do
  	  if(i == XUEWEI_SELECT) then
	      if iSexy == 1 then
			XUEWEI_LIST_NAN[i]:SetPushed(1)
		  else
			XUEWEI_LIST[i]:SetPushed(1)
		  end
  	  else
		  if iSexy == 1 then
			XUEWEI_LIST_NAN[i]:SetPushed(0)
		  else
			XUEWEI_LIST[i]:SetPushed(0)
		  end

  	  end
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function JingMai_Frame_On_ResetPos()
	SelfJingMai_Frame : SetProperty("UnifiedXPosition", g_XueWei_Frame_UnifiedXPosition);
	SelfJingMai_Frame : SetProperty("UnifiedYPosition", g_XueWei_Frame_UnifiedYPosition);

end

--===============================================
-- 关闭
--===============================================
function SelfJingMai_CloseUI()
	this:Hide()
	local page = GetJingMaiFenYeFlag()
	Player:LuaFnSetCurrentJingMaiPage(page)--关闭界面时设置一下当前经脉页,因为打开界面时默认开启激活的经脉页，所以关闭时也给他设置成激活的经脉页。
	if "SelfJingMai" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    end
end

function JingMai_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function JingMai_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end


function JingMai_ShowGemScore()

	local nGemScore = Player:GetData("EQUIPGEMJINJIESCORE")
	local nGemScoreNextLevel = 0
	local nGemScoreLevel = 0
	local nGemEffect = "0"
	local nGemEffectNextLevel = "0"
	if nGemScore < 960 then
		nGemScoreLevel = 0
		nGemScoreNextLevel = 960
		nGemEffect = "0"
		nGemEffectNextLevel = "2"
	elseif nGemScore < 1280 then
		nGemScoreLevel = 1
		nGemScoreNextLevel = 1280
		nGemEffect = "2"
		nGemEffectNextLevel = "4"
	elseif nGemScore < 1920 then
		nGemScoreLevel = 2
		nGemScoreNextLevel = 1920
		nGemEffect = "4"
		nGemEffectNextLevel = "7"
	elseif nGemScore < 3200 then
		nGemScoreLevel = 3
		nGemScoreNextLevel = 3200
		nGemEffect = "7"
		nGemEffectNextLevel = "10"
	else
		nGemScoreLevel = 4
		nGemScoreNextLevel = 5120
		nGemEffect = "10"
		nGemEffectNextLevel = "10"
	end
	SelfJingMai_ShuZhi:SetText("#cfff263"..tostring(nGemScore).."/"..tostring(nGemScoreNextLevel))
	SelfJingMai_ShuZhi1:SetText("#cfff263"..tostring(nGemScoreLevel))
	nGemEffectStr = ScriptGlobal_Format("#{BSZJPF_130311_18}",nGemEffect,nGemEffect)
	SelfJingMai_Effect_Text:SetText(nGemEffectStr)

	SelfJingMai_ShuZhi:SetToolTip("#{BSZJPF_130311_19}");
	if nGemScoreLevel < 3 then
		local strTemp = ScriptGlobal_Format("#{BSZJPF_130311_20}",tostring(nGemScoreNextLevel - nGemScore))
		SelfJingMai_GemJinJieLevel_Text:SetToolTip(strTemp)
		SelfJingMai_ShuZhi1:SetToolTip(strTemp)
		strTemp = ScriptGlobal_Format("#{BSZJPF_130311_22}",nGemEffectNextLevel,nGemEffectNextLevel)
		SelfJingMai_Effect_Text:SetToolTip(strTemp)
	else
		SelfJingMai_GemJinJieLevel_Text:SetToolTip("#{BSZJPF_130311_21}")
		SelfJingMai_ShuZhi1:SetToolTip("#{BSZJPF_130311_21}")
		local strTemp = ScriptGlobal_Format("#{BSZJPF_130311_23}",nGemEffect,nGemEffect)
		SelfJingMai_Effect_Text:SetToolTip(strTemp)
	end
end

function JingMai_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function SelfJingMai_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function SelfJingMai_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function SelfJingMai_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		SelfJingMai_ShenDing:Disable()
		SelfJingMai_ShenDing_tips:Show()
	--	SelfJingMai_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		SelfJingMai_ShenDing:Enable()
		SelfJingMai_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		SelfJingMai_Infant:Disable()
		SelfJingMai_Infant_tips:Show()
	--	SelfJingMai_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		SelfJingMai_Infant:Enable()
		SelfJingMai_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		SelfJingMai_Wuhun:Disable()
--		SelfJingMai_Wuhun_tips:Show()
	--	SelfJingMai_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		SelfJingMai_Wuhun:Enable()
		SelfJingMai_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		SelfJingMai_Xiulian:Disable()
		SelfJingMai_Xiulian_tips:Show()
	--	SelfJingMai_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		SelfJingMai_Xiulian:Enable()
		SelfJingMai_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SelfJingMai_Miji:Disable()
		SelfJingMai_Miji_tips:Show()
	--	SelfJingMai_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		SelfJingMai_Miji:Enable()
		SelfJingMai_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SelfJingMai_ZhenYuan:Disable()
		SelfJingMai_ZhenYuan_tips:Show()
	--	SelfJingMai_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		SelfJingMai_ZhenYuan:Enable()
		SelfJingMai_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		SelfJingMai_JueWei:Disable()
		SelfJingMai_JueWei_tips:Show()
	--	SelfJingMai_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		SelfJingMai_JueWei:Enable()
		SelfJingMai_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SelfJingMai_JingMaiInfo:Disable()
		SelfJingMai_JingMaiInfo_tips:Show()
	--	SelfJingMai_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		SelfJingMai_JingMaiInfo:Enable()
		SelfJingMai_JingMaiInfo_tips:Hide()
	end

	if ( nLevel < 85 ) then
		SelfJingMai_BaoJian:Disable()
		SelfJingMai_BaoJian_tips:Show()
	else
		SelfJingMai_BaoJian:Enable()
		SelfJingMai_BaoJian_tips:Hide()
	end
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SelfJingMai_WuYi:Enable()
		SelfJingMai_WuYi_tips:Hide()
	else
		SelfJingMai_WuYi:Disable()
		SelfJingMai_WuYi_tips:Show()
	end
	SelfJingMai_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SelfJingMai_ShenQi:Enable()
		SelfJingMai_ShenQi_tips:Hide()
	else
		SelfJingMai_ShenQi:Disable()
		SelfJingMai_ShenQi_tips:Show()
	end
	SelfJingMai_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SelfJingMai_Armor:Enable()
		SelfJingMai_Armor_tips:Hide()
	else
		SelfJingMai_Armor:Disable()
		SelfJingMai_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SelfJingMai_CangPin:Enable()
		SelfJingMai_CangPin_tips:Hide()
	else
		SelfJingMai_CangPin:Disable()
		SelfJingMai_CangPin_tips:Show()
	end
	
	SelfJingMai_RefreshCangPinTip()
end

function SelfJingMai_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function SelfJingMai_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SelfJingMai_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfJingMai_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfJingMai_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SelfJingMai_WuYi_Buttontips:Show()
	else
		SelfJingMai_WuYi_Buttontips:Hide()
	end
end

function SelfJingMai_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfJingMai_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfJingMai_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SelfJingMai_OtherInfo_ButtonTips:Show()
	else
		SelfJingMai_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SelfJingMai_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function SelfJingMai_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfJingMai_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfJingMai_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfJingMai_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfJingMai_CangPin_Buttontips:Show()
	else
		SelfJingMai_CangPin_Buttontips:Hide()
	end
end

function SelfJingMai_FenYe()
	Player:LuaFnSetCurrentJingMaiPage(g_JingMai_FenYe)--刷新时设置一下当前经脉页
	--影藏所有动画
	for jj=0,6+14 do
		XUEWEI_ANIMATE[jj]:SetProperty("Visible", "False")
		XUEWEI_ANIMATE_NAN[jj]:SetProperty("Visible", "False")
		XUEWEI_ANIMATE_ENHANSE[jj]:SetProperty("Visible", "False")
		XUEWEI_ANIMATE_NAN_ENHANSE[jj]:SetProperty("Visible", "False")
	end
	local iSexy = Player:GetMySex()
	
	SelfJingMai_fenye_update(iSexy)
	if iSexy == 1 then
		--SelfJingMai_NAN1_BEIJING1:Show();
		if SystemSetup:IsClassic() == 1 then
			--SelfJingMai_NAN1_BEIJING2:Show();
		end

		--SelfJingMai_NV1_BEIJING1:Hide()
		if SystemSetup:IsClassic() == 1 then
			--SelfJingMai_NV1_BEIJING2:Hide()
		end

		for i=0,6+14 do
			XUEWEI_LIST[i]:Hide()
			XUEWEI_LIST_NAN[i]:Show()
		end
	else
		--SelfJingMai_NAN1_BEIJING1:Hide();
		if SystemSetup:IsClassic() == 1 then
			--SelfJingMai_NAN1_BEIJING2:Hide();
		end

		--SelfJingMai_NV1_BEIJING1:Show()
		if SystemSetup:IsClassic() == 1 then
			--SelfJingMai_NV1_BEIJING2:Show()
		end

		for i=0,6+14 do
			XUEWEI_LIST[i]:Show()
			XUEWEI_LIST_NAN[i]:Hide()
		end
	end
	--去掉切换经脉页时会变动位置
	--local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	--if(selfUnionPos ~= nil) then
	--	SelfJingMai_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	--end

	XUEWEI_SELECT = -1;

	XueWei_Update()

	XueWei_SetSelectState()
	XueWei_SetTabState()

	if Player:LuaFnIsUsingMifa() == 1 then--处于使用秘法道具准备镶嵌穴位状态时，出穴位bling动画
		Animate_Update()
	end
end
function SelfJingMai_FenYe1_function()
	--加个判断
	--local nLevel = Player:GetLevel();
    --if nLevel < 90 then        
	--	PushDebugMessage("#{JMQH_230829_8}")
	--	return
    --end
	--local ret=DataPool:Lua_IsMissionHaveDone(1554)
	--if ret==0 then
	--	PushDebugMessage("#{JMQH_230829_9}")
	--	return
	--end
	--g_JingMai_FenYe = g_JingMai_Fenye_1
	--SelfJingMai_FenYe()
end
function SelfJingMai_FenYe2_function()
	--加个判断
	--local nLevel = Player:GetLevel();
    --if nLevel < 90 then        
	--	PushDebugMessage("#{JMQH_230829_8}")
	--	return
    --end
	--local ret=DataPool:Lua_IsMissionHaveDone(1554)
	--if ret==0 then
	--	PushDebugMessage("#{JMQH_230829_9}")
	--	return
	--end
	--if Pneuma:GetMF(g_JingMai_MF_OpenFenye2) ~= 1 then
	--	PushDebugMessage("#{JMQH_230829_10}")
	--	return
	--end
	--g_JingMai_FenYe = g_JingMai_Fenye_2
	--SelfJingMai_FenYe()
end
function SelfJingMai_FenYe3_function()
	--加个判断
	--local nLevel = Player:GetLevel();
    --if nLevel < 90 then        
	--	PushDebugMessage("#{JMQH_230829_8}")
	--	return
    --end
	--local ret=DataPool:Lua_IsMissionHaveDone(1554)
	--if ret==0 then
	--	PushDebugMessage("#{JMQH_230829_9}")
	--	return
	--end
	--if Pneuma:GetMF(g_JingMai_MF_OpenFenye3) ~= 1 then
	--	PushDebugMessage("#{JMQH_230829_10}")
	--	return
	--end
	--g_JingMai_FenYe = g_JingMai_Fenye_3
	--SelfJingMai_FenYe()
end
function SelfJingMai_Btn_Button()
	--SetJingMaiFenYeFlag(g_JingMai_FenYe)
end

function SelfJingMai_FenYeBtn_update()
	--根据g_JingMai_FenYe重置下经脉分页按钮的select状态
	--SelfJingMai_FenYe1:SetProperty("Selected", "False");
	--SelfJingMai_FenYe2:SetProperty("Selected", "False");
	--SelfJingMai_FenYe3:SetProperty("Selected", "False");
	--if g_JingMai_FenYe == g_JingMai_Fenye_1 then
	--	SelfJingMai_FenYe1:SetProperty("Selected", "True");
	--elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
	--	SelfJingMai_FenYe2:SetProperty("Selected", "True");
	--elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
	--	SelfJingMai_FenYe3:SetProperty("Selected", "True");
	--end
	--根据MF判断下经脉分页2和3是否已经解锁了
	--if Pneuma:GetMF(g_JingMai_MF_OpenFenye2) ~= 1 then
	--	SelfJingMai_FenYe2:Disable()
	--else
	--	SelfJingMai_FenYe2:Enable()
	--end
	--if Pneuma:GetMF(g_JingMai_MF_OpenFenye3) ~= 1 then
	--	SelfJingMai_FenYe3:Disable()
	--else
	--	SelfJingMai_FenYe3:Enable()
	--end
end

function SelfJingMai_fenye_update(sex)
	if SelfJingMai_IsOnlyFenYe1() == 1 then--2 3页都没解锁，也就是只有第一页，这里控制只显示第一页的内容
		g_JingMai_FenYe = g_JingMai_Fenye_1
	end
	SelfJingMai_FenYeBtn_update()
	SelfJingMai_Info1_Text:Hide()
	SelfJingMai_Info2_Text:Hide()
	SelfJingMai_Info3_Text:Hide()
	if g_JingMai_FenYe == g_JingMai_Fenye_1 then
		SelfJingMai_Info1_Text:Show()
	elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
		SelfJingMai_Info2_Text:Show()
	elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
		SelfJingMai_Info3_Text:Show()
	end
	--local myusetime = DataPool:lua_GetJingMaiFenYeTimeValue()
	--KillTimer("SelfJingMai_Watch_Time()")--开启timer前先kill一下吧 有个倒计时text和激活按钮提早出现的小bug可能是这个点引起的
	--SetTimer("SelfJingMai","SelfJingMai_Watch_Time()",myusetime*1000)
	--SelfJingMai_NV1_Btn:Enable()
	--SelfJingMai_NV1_Btn:SetText("#{JMQH_230829_7}")--切换经脉
	--SelfJingMai_NV2_Btn:Enable()
	--SelfJingMai_NV2_Btn:SetText("#{JMQH_230829_7}")--切换经脉
	--SelfJingMai_NV3_Btn:Enable()
	--SelfJingMai_NV3_Btn:SetText("#{JMQH_230829_7}")--切换经脉
	--SelfJingMai_NAN1_Btn:Enable()
	--SelfJingMai_NAN1_Btn:SetText("#{JMQH_230829_7}")--切换经脉
	--SelfJingMai_NAN2_Btn:Enable()
	--SelfJingMai_NAN2_Btn:SetText("#{JMQH_230829_7}")--切换经脉
	--SelfJingMai_NAN3_Btn:Enable()
	--SelfJingMai_NAN3_Btn:SetText("#{JMQH_230829_7}")--切换经脉

	local fenyeflag = GetJingMaiFenYeFlag()
	--PushDebugMessage(g_JingMai_FenYe)
	if sex == 0 then
		if g_JingMai_FenYe == g_JingMai_Fenye_1 then
			SelfJingMai_NAN1_Head:Hide()
			SelfJingMai_NV1_Head:Show()
		elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
			SelfJingMai_NAN2_Head:Hide()
			SelfJingMai_NV2_Head:Show()
		elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
			SelfJingMai_NAN3_Head:Hide()
			SelfJingMai_NV3_Head:Show()
		end

		--if myusetime == 0 then
		--	if g_JingMai_FenYe == g_JingMai_Fenye_1 then
		--		SelfJingMai_NV1Watch_Time_Text:Hide()
		--		SelfJingMai_NV1Watch_DaoJiShi:Hide()
		--		SelfJingMai_NV1Watch_Bk2:Hide()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NV1_Btn:Show()
		--			SelfJingMai_NV1_Btn:Disable()
		--			SelfJingMai_NV1_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
		--		SelfJingMai_NV2Watch_Time_Text:Hide()
		--		SelfJingMai_NV2Watch_DaoJiShi:Hide()
		--		SelfJingMai_NV2Watch_Bk2:Hide()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NV2_Btn:Show()
		--			SelfJingMai_NV2_Btn:Disable()
		--			SelfJingMai_NV2_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
		--		SelfJingMai_NV3Watch_Time_Text:Hide()
		--		SelfJingMai_NV3Watch_DaoJiShi:Hide()
		--		SelfJingMai_NV3Watch_Bk2:Hide()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NV3_Btn:Show()
		--			SelfJingMai_NV3_Btn:Disable()
		--			SelfJingMai_NV3_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	end
		--
		--else
		--	if g_JingMai_FenYe == g_JingMai_Fenye_1 then
		--		SelfJingMai_NV1Watch_Time_Text:Show()
		--		SelfJingMai_NV1Watch_Time_Text:SetProperty("Timer", tostring( myusetime) )
		--		SelfJingMai_NV1Watch_DaoJiShi:Show()
		--		SelfJingMai_NV1Watch_Bk2:Show()
		--		--SelfJingMai_NV1_Btn:Hide()
		--		SelfJingMai_NV1_Btn:Show()
		--		SelfJingMai_NV1_Btn:Disable()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NV1_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
		--		SelfJingMai_NV2Watch_Time_Text:Show()
		--		SelfJingMai_NV2Watch_Time_Text:SetProperty("Timer", tostring( myusetime) )
		--		SelfJingMai_NV2Watch_DaoJiShi:Show()
		--		SelfJingMai_NV2Watch_Bk2:Show()
		--		--SelfJingMai_NV2_Btn:Hide()
		--		SelfJingMai_NV2_Btn:Show()
		--		SelfJingMai_NV2_Btn:Disable()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NV2_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
		--		SelfJingMai_NV3Watch_Time_Text:Show()
		--		SelfJingMai_NV3Watch_Time_Text:SetProperty("Timer", tostring( myusetime) )
		--		SelfJingMai_NV3Watch_DaoJiShi:Show()
		--		SelfJingMai_NV3Watch_Bk2:Show()
		--		--SelfJingMai_NV3_Btn:Hide()
		--		SelfJingMai_NV3_Btn:Show()
		--		SelfJingMai_NV3_Btn:Disable()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NV3_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	end
		--end
	else
		if g_JingMai_FenYe == g_JingMai_Fenye_1 then
			SelfJingMai_NAN1_Head:Show()
			SelfJingMai_NV1_Head:Hide()
		elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
			SelfJingMai_NAN2_Head:Show()
			SelfJingMai_NV2_Head:Hide()
		elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
			SelfJingMai_NAN3_Head:Show()
			SelfJingMai_NV3_Head:Hide()
		end
		--if myusetime == 0 then
		--	if g_JingMai_FenYe == g_JingMai_Fenye_1 then
		--		SelfJingMai_NAN1Watch_Time_Text:Hide()
		--		SelfJingMai_NAN1Watch_DaoJiShi:Hide()
		--		SelfJingMai_NAN1Watch_Bk2:Hide()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NAN1_Btn:Show()
		--			SelfJingMai_NAN1_Btn:Disable()
		--			SelfJingMai_NAN1_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
		--		SelfJingMai_NAN2Watch_Time_Text:Hide()
		--		SelfJingMai_NAN2Watch_DaoJiShi:Hide()
		--		SelfJingMai_NAN2Watch_Bk2:Hide()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NAN2_Btn:Show()
		--			SelfJingMai_NAN2_Btn:Disable()
		--			SelfJingMai_NAN2_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
		--		SelfJingMai_NAN3Watch_Time_Text:Hide()
		--		SelfJingMai_NAN3Watch_DaoJiShi:Hide()
		--		SelfJingMai_NAN3Watch_Bk2:Hide()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NAN3_Btn:Show()
		--			SelfJingMai_NAN3_Btn:Disable()
		--			SelfJingMai_NAN3_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	end
		--else
		--	if g_JingMai_FenYe == g_JingMai_Fenye_1 then
		--		SelfJingMai_NAN1Watch_Time_Text:Show()
		--		SelfJingMai_NAN1Watch_Time_Text:SetProperty("Timer", tostring( myusetime ) )
		--		SelfJingMai_NAN1Watch_DaoJiShi:Show()
		--		SelfJingMai_NAN1Watch_Bk2:Show()
		--		--SelfJingMai_NAN1_Btn:Hide()
		--		SelfJingMai_NAN1_Btn:Show()
		--		SelfJingMai_NAN1_Btn:Disable()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NAN1_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
		--		SelfJingMai_NAN2Watch_Time_Text:Show()
		--		SelfJingMai_NAN2Watch_Time_Text:SetProperty("Timer", tostring( myusetime ) )
		--		SelfJingMai_NAN2Watch_DaoJiShi:Show()
		--		SelfJingMai_NAN2Watch_Bk2:Show()
		--		--SelfJingMai_NAN2_Btn:Hide()
		--		SelfJingMai_NAN2_Btn:Show()
		--		SelfJingMai_NAN2_Btn:Disable()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NAN2_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
		--		SelfJingMai_NAN3Watch_Time_Text:Show()
		--		SelfJingMai_NAN3Watch_Time_Text:SetProperty("Timer", tostring( myusetime ) )
		--		SelfJingMai_NAN3Watch_DaoJiShi:Show()
		--		SelfJingMai_NAN3Watch_Bk2:Show()
		--		--SelfJingMai_NAN3_Btn:Hide()
		--		SelfJingMai_NAN3_Btn:Show()
		--		SelfJingMai_NAN3_Btn:Disable()
		--		if fenyeflag == g_JingMai_FenYe then
		--			SelfJingMai_NAN3_Btn:SetText("#{JMQH_230829_36}")--已使用
		--		end
		--	end
		--end
	end	
	if SelfJingMai_IsOnlyFenYe1() == 1 then--2 3页都没解锁，也就是只有第一页这里在所有控件显隐处理完之后再判断是否只有第一页然后针对第一页的控件进行隐藏。在开头那边已经控制只显示第一页的控件了。
		--SelfJingMai_NAN1_Btn:Hide()
		--SelfJingMai_NAN1Watch_Bk2:Hide()
		--SelfJingMai_NAN1Watch_DaoJiShi:Hide()
		--SelfJingMai_NAN1Watch_Time_Text:Hide()
		--
		--SelfJingMai_NV1_Btn:Hide()
		--SelfJingMai_NV1Watch_Bk2:Hide()
		--SelfJingMai_NV1Watch_DaoJiShi:Hide()
		--SelfJingMai_NV1Watch_Time_Text:Hide()
	end
end

function SelfJingMai_LoadControl()

	--打开并增加tips
	if XUEWEI_LIST_NAN[0] == nil then
		XUEWEI_LIST_NAN[0] = SelfJingMai_NAN1_TianJing --天井
		XUEWEI_LIST_NAN[1] = SelfJingMai_NAN1_YangChi --阳池
		XUEWEI_LIST_NAN[2] = SelfJingMai_NAN1_XueHai --血海
		XUEWEI_LIST_NAN[3] = SelfJingMai_NAN1_QiMen --箕门
		XUEWEI_LIST_NAN[4] = SelfJingMai_NAN1_TanZhong --檀中(现在是气海了)
		XUEWEI_LIST_NAN[5] = SelfJingMai_NAN1_ShenTing --神庭
		XUEWEI_LIST_NAN[6] = SelfJingMai_NAN1_RenZhong --人中(现在是至阳了)

		XUEWEI_LIST_NAN[0+7] = SelfJingMai_NAN2_TianJing --天井
		XUEWEI_LIST_NAN[1+7] = SelfJingMai_NAN2_YangChi --阳池
		XUEWEI_LIST_NAN[2+7] = SelfJingMai_NAN2_XueHai --血海
		XUEWEI_LIST_NAN[3+7] = SelfJingMai_NAN2_QiMen --箕门
		XUEWEI_LIST_NAN[4+7] = SelfJingMai_NAN2_TanZhong --檀中(现在是气海了)
		XUEWEI_LIST_NAN[5+7] = SelfJingMai_NAN2_ShenTing --神庭
		XUEWEI_LIST_NAN[6+7] = SelfJingMai_NAN2_RenZhong --人中(现在是至阳了)

		XUEWEI_LIST_NAN[0+14] = SelfJingMai_NAN3_TianJing --天井
		XUEWEI_LIST_NAN[1+14] = SelfJingMai_NAN3_YangChi --阳池
		XUEWEI_LIST_NAN[2+14] = SelfJingMai_NAN3_XueHai --血海
		XUEWEI_LIST_NAN[3+14] = SelfJingMai_NAN3_QiMen --箕门
		XUEWEI_LIST_NAN[4+14] = SelfJingMai_NAN3_TanZhong --檀中(现在是气海了)
		XUEWEI_LIST_NAN[5+14] = SelfJingMai_NAN3_ShenTing --神庭
		XUEWEI_LIST_NAN[6+14] = SelfJingMai_NAN3_RenZhong --人中(现在是至阳了)
		---------------------------------------------------------------

		XUEWEI_ANIMATE_NAN[0] = SelfJingMai_NAN1_TianJingAnimate
		XUEWEI_ANIMATE_NAN[1] = SelfJingMai_NAN1_YangChiAnimate
		XUEWEI_ANIMATE_NAN[2] = SelfJingMai_NAN1_XueHaiAnimate
		XUEWEI_ANIMATE_NAN[3] = SelfJingMai_NAN1_QiMenAnimate
		XUEWEI_ANIMATE_NAN[4] = SelfJingMai_NAN1_TanZhongAnimate
		XUEWEI_ANIMATE_NAN[5] = SelfJingMai_NAN1_ShenTingAnimate
		XUEWEI_ANIMATE_NAN[6] = SelfJingMai_NAN1_RenZhongAnimate

		XUEWEI_ANIMATE_NAN[0+7] = SelfJingMai_NAN2_TianJingAnimate
		XUEWEI_ANIMATE_NAN[1+7] = SelfJingMai_NAN2_YangChiAnimate
		XUEWEI_ANIMATE_NAN[2+7] = SelfJingMai_NAN2_XueHaiAnimate
		XUEWEI_ANIMATE_NAN[3+7] = SelfJingMai_NAN2_QiMenAnimate
		XUEWEI_ANIMATE_NAN[4+7] = SelfJingMai_NAN2_TanZhongAnimate
		XUEWEI_ANIMATE_NAN[5+7] = SelfJingMai_NAN2_ShenTingAnimate
		XUEWEI_ANIMATE_NAN[6+7] = SelfJingMai_NAN2_RenZhongAnimate

		XUEWEI_ANIMATE_NAN[0+14] = SelfJingMai_NAN3_TianJingAnimate
		XUEWEI_ANIMATE_NAN[1+14] = SelfJingMai_NAN3_YangChiAnimate
		XUEWEI_ANIMATE_NAN[2+14] = SelfJingMai_NAN3_XueHaiAnimate
		XUEWEI_ANIMATE_NAN[3+14] = SelfJingMai_NAN3_QiMenAnimate
		XUEWEI_ANIMATE_NAN[4+14] = SelfJingMai_NAN3_TanZhongAnimate
		XUEWEI_ANIMATE_NAN[5+14] = SelfJingMai_NAN3_ShenTingAnimate
		XUEWEI_ANIMATE_NAN[6+14] = SelfJingMai_NAN3_RenZhongAnimate

		XUEWEI_ANIMATE_NAN_ENHANSE[0] = SelfJingMai_NAN1_TianJingAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[1] = SelfJingMai_NAN1_YangChiAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[2] = SelfJingMai_NAN1_XueHaiAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[3] = SelfJingMai_NAN1_QiMenAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[4] = SelfJingMai_NAN1_TanZhongAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[5] = SelfJingMai_NAN1_ShenTingAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[6] = SelfJingMai_NAN1_RenZhongAnimate1

		XUEWEI_ANIMATE_NAN_ENHANSE[0+7] = SelfJingMai_NAN2_TianJingAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[1+7] = SelfJingMai_NAN2_YangChiAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[2+7] = SelfJingMai_NAN2_XueHaiAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[3+7] = SelfJingMai_NAN2_QiMenAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[4+7] = SelfJingMai_NAN2_TanZhongAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[5+7] = SelfJingMai_NAN2_ShenTingAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[6+7] = SelfJingMai_NAN2_RenZhongAnimate1

		XUEWEI_ANIMATE_NAN_ENHANSE[0+14] = SelfJingMai_NAN3_TianJingAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[1+14] = SelfJingMai_NAN3_YangChiAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[2+14] = SelfJingMai_NAN3_XueHaiAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[3+14] = SelfJingMai_NAN3_QiMenAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[4+14] = SelfJingMai_NAN3_TanZhongAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[5+14] = SelfJingMai_NAN3_ShenTingAnimate1
		XUEWEI_ANIMATE_NAN_ENHANSE[6+14] = SelfJingMai_NAN3_RenZhongAnimate1
	end
	if XUEWEI_LIST[0] == nil then
		XUEWEI_LIST[0] = SelfJingMai_NV1_TianJing --天井
		XUEWEI_LIST[1] = SelfJingMai_NV1_YangChi --阳池
		XUEWEI_LIST[2] = SelfJingMai_NV1_XueHai --血海
		XUEWEI_LIST[3] = SelfJingMai_NV1_QiMen --箕门
		XUEWEI_LIST[4] = SelfJingMai_NV1_TanZhong --檀中(现在是气海了)
		XUEWEI_LIST[5] = SelfJingMai_NV1_ShenTing --神庭
		XUEWEI_LIST[6] = SelfJingMai_NV1_RenZhong --人中(现在是至阳了)

		XUEWEI_LIST[0+7] = SelfJingMai_NV2_TianJing --天井
		XUEWEI_LIST[1+7] = SelfJingMai_NV2_YangChi --阳池
		XUEWEI_LIST[2+7] = SelfJingMai_NV2_XueHai --血海
		XUEWEI_LIST[3+7] = SelfJingMai_NV2_QiMen --箕门
		XUEWEI_LIST[4+7] = SelfJingMai_NV2_TanZhong --檀中(现在是气海了)
		XUEWEI_LIST[5+7] = SelfJingMai_NV2_ShenTing --神庭
		XUEWEI_LIST[6+7] = SelfJingMai_NV2_RenZhong --人中(现在是至阳了)

		XUEWEI_LIST[0+14] = SelfJingMai_NV3_TianJing --天井
		XUEWEI_LIST[1+14] = SelfJingMai_NV3_YangChi --阳池
		XUEWEI_LIST[2+14] = SelfJingMai_NV3_XueHai --血海
		XUEWEI_LIST[3+14] = SelfJingMai_NV3_QiMen --箕门
		XUEWEI_LIST[4+14] = SelfJingMai_NV3_TanZhong --檀中(现在是气海了)
		XUEWEI_LIST[5+14] = SelfJingMai_NV3_ShenTing --神庭
		XUEWEI_LIST[6+14] = SelfJingMai_NV3_RenZhong --人中(现在是至阳了)

		XUEWEI_ANIMATE[0] = SelfJingMai_NV1_TianJingAnimate
		XUEWEI_ANIMATE[1] = SelfJingMai_NV1_YangChiAnimate
		XUEWEI_ANIMATE[2] = SelfJingMai_NV1_XueHaiAnimate
		XUEWEI_ANIMATE[3] = SelfJingMai_NV1_QiMenAnimate
		XUEWEI_ANIMATE[4] = SelfJingMai_NV1_TanZhongAnimate
		XUEWEI_ANIMATE[5] = SelfJingMai_NV1_ShenTingAnimate
		XUEWEI_ANIMATE[6] = SelfJingMai_NV1_RenZhongAnimate

		XUEWEI_ANIMATE[0+7] = SelfJingMai_NV2_TianJingAnimate
		XUEWEI_ANIMATE[1+7] = SelfJingMai_NV2_YangChiAnimate
		XUEWEI_ANIMATE[2+7] = SelfJingMai_NV2_XueHaiAnimate
		XUEWEI_ANIMATE[3+7] = SelfJingMai_NV2_QiMenAnimate
		XUEWEI_ANIMATE[4+7] = SelfJingMai_NV2_TanZhongAnimate
		XUEWEI_ANIMATE[5+7] = SelfJingMai_NV2_ShenTingAnimate
		XUEWEI_ANIMATE[6+7] = SelfJingMai_NV2_RenZhongAnimate

		XUEWEI_ANIMATE[0+14] = SelfJingMai_NV3_TianJingAnimate
		XUEWEI_ANIMATE[1+14] = SelfJingMai_NV3_YangChiAnimate
		XUEWEI_ANIMATE[2+14] = SelfJingMai_NV3_XueHaiAnimate
		XUEWEI_ANIMATE[3+14] = SelfJingMai_NV3_QiMenAnimate
		XUEWEI_ANIMATE[4+14] = SelfJingMai_NV3_TanZhongAnimate
		XUEWEI_ANIMATE[5+14] = SelfJingMai_NV3_ShenTingAnimate
		XUEWEI_ANIMATE[6+14] = SelfJingMai_NV3_RenZhongAnimate

		XUEWEI_ANIMATE_ENHANSE[0] = SelfJingMai_NV1_TianJingAnimate1
		XUEWEI_ANIMATE_ENHANSE[1] = SelfJingMai_NV1_YangChiAnimate1
		XUEWEI_ANIMATE_ENHANSE[2] = SelfJingMai_NV1_XueHaiAnimate1
		XUEWEI_ANIMATE_ENHANSE[3] = SelfJingMai_NV1_QiMenAnimate1
		XUEWEI_ANIMATE_ENHANSE[4] = SelfJingMai_NV1_TanZhongAnimate1
		XUEWEI_ANIMATE_ENHANSE[5] = SelfJingMai_NV1_ShenTingAnimate1
		XUEWEI_ANIMATE_ENHANSE[6] = SelfJingMai_NV1_RenZhongAnimate1

		XUEWEI_ANIMATE_ENHANSE[0+7] = SelfJingMai_NV2_TianJingAnimate1
		XUEWEI_ANIMATE_ENHANSE[1+7] = SelfJingMai_NV2_YangChiAnimate1
		XUEWEI_ANIMATE_ENHANSE[2+7] = SelfJingMai_NV2_XueHaiAnimate1
		XUEWEI_ANIMATE_ENHANSE[3+7] = SelfJingMai_NV2_QiMenAnimate1
		XUEWEI_ANIMATE_ENHANSE[4+7] = SelfJingMai_NV2_TanZhongAnimate1
		XUEWEI_ANIMATE_ENHANSE[5+7] = SelfJingMai_NV2_ShenTingAnimate1
		XUEWEI_ANIMATE_ENHANSE[6+7] = SelfJingMai_NV2_RenZhongAnimate1

		XUEWEI_ANIMATE_ENHANSE[0+14] = SelfJingMai_NV3_TianJingAnimate1
		XUEWEI_ANIMATE_ENHANSE[1+14] = SelfJingMai_NV3_YangChiAnimate1
		XUEWEI_ANIMATE_ENHANSE[2+14] = SelfJingMai_NV3_XueHaiAnimate1
		XUEWEI_ANIMATE_ENHANSE[3+14] = SelfJingMai_NV3_QiMenAnimate1
		XUEWEI_ANIMATE_ENHANSE[4+14] = SelfJingMai_NV3_TanZhongAnimate1
		XUEWEI_ANIMATE_ENHANSE[5+14] = SelfJingMai_NV3_ShenTingAnimate1
		XUEWEI_ANIMATE_ENHANSE[6+14] = SelfJingMai_NV3_RenZhongAnimate1
	end
end

--function SelfJingMai_Watch_Time()
--	KillTimer("SelfJingMai_Watch_Time()")
--	SelfJingMai_NAN1Watch_Bk2:Hide()
--	SelfJingMai_NAN2Watch_Bk2:Hide()
--	SelfJingMai_NAN3Watch_Bk2:Hide()
--	SelfJingMai_NV1Watch_Bk2:Hide()
--	SelfJingMai_NV2Watch_Bk2:Hide()
--	SelfJingMai_NV3Watch_Bk2:Hide()
--
--	
--	if g_JingMai_FenYe == g_JingMai_Fenye_1 then
--		SelfJingMai_NAN1_Btn:Show() 
--		SelfJingMai_NV1_Btn:Show()  
--		SelfJingMai_NAN2_Btn:Hide() 
--		SelfJingMai_NV2_Btn:Hide() 
--		SelfJingMai_NAN3_Btn:Hide() 
--		SelfJingMai_NV3_Btn:Hide() 
--		if GetJingMaiFenYeFlag() == g_JingMai_FenYe then --激活页面A，不做任何操作等冷却结束，出现的激活按钮A应该判断是否置灰
--			SelfJingMai_NAN1_Btn:Disable() 
--			SelfJingMai_NV1_Btn:Disable()
--			SelfJingMai_NV1_Btn:SetText("#{JMQH_230829_36}")--已使用
--			SelfJingMai_NAN1_Btn:SetText("#{JMQH_230829_36}")--已使用
--		else
--			SelfJingMai_NAN1_Btn:Enable() 
--			SelfJingMai_NV1_Btn:Enable()
--			SelfJingMai_NV1_Btn:SetText("#{JMQH_230829_7}")--切换经脉
--			SelfJingMai_NAN1_Btn:SetText("#{JMQH_230829_7}")--切换经脉
--		end
--	elseif g_JingMai_FenYe == g_JingMai_Fenye_2 then
--		SelfJingMai_NAN1_Btn:Hide() 
--		SelfJingMai_NV1_Btn:Hide() 
--		SelfJingMai_NAN2_Btn:Show() 
--		SelfJingMai_NV2_Btn:Show() 
--		SelfJingMai_NAN3_Btn:Hide() 
--		SelfJingMai_NV3_Btn:Hide() 
--		if GetJingMaiFenYeFlag() == g_JingMai_FenYe then
--			SelfJingMai_NAN2_Btn:Disable() 
--			SelfJingMai_NV2_Btn:Disable() 
--			SelfJingMai_NV2_Btn:SetText("#{JMQH_230829_36}")--已使用
--			SelfJingMai_NAN2_Btn:SetText("#{JMQH_230829_36}")--已使用
--		else
--			SelfJingMai_NAN2_Btn:Enable() 
--			SelfJingMai_NV2_Btn:Enable()
--			SelfJingMai_NV2_Btn:SetText("#{JMQH_230829_7}")--切换经脉
--			SelfJingMai_NAN2_Btn:SetText("#{JMQH_230829_7}")--切换经脉
--		end
--	elseif g_JingMai_FenYe == g_JingMai_Fenye_3 then
--		SelfJingMai_NAN1_Btn:Hide() 
--		SelfJingMai_NV1_Btn:Hide() 
--		SelfJingMai_NAN2_Btn:Hide() 
--		SelfJingMai_NV2_Btn:Hide() 
--		SelfJingMai_NAN3_Btn:Show() 
--		SelfJingMai_NV3_Btn:Show() 
--		if GetJingMaiFenYeFlag() == g_JingMai_FenYe then
--			SelfJingMai_NAN3_Btn:Disable() 
--			SelfJingMai_NV3_Btn:Disable() 
--			SelfJingMai_NV3_Btn:SetText("#{JMQH_230829_36}")--已使用
--			SelfJingMai_NAN3_Btn:SetText("#{JMQH_230829_36}")--已使用
--		else
--			SelfJingMai_NAN3_Btn:Enable() 
--			SelfJingMai_NV3_Btn:Enable()
--			SelfJingMai_NV3_Btn:SetText("#{JMQH_230829_7}")--切换经脉
--			SelfJingMai_NAN3_Btn:SetText("#{JMQH_230829_7}")--切换经脉
--		end
--	end
--
--	SelfJingMai_NV1Watch_DaoJiShi:Hide()
--	SelfJingMai_NV2Watch_DaoJiShi:Hide()
--	SelfJingMai_NV3Watch_DaoJiShi:Hide()
--
--	SelfJingMai_NAN1Watch_DaoJiShi:Hide()
--	SelfJingMai_NAN2Watch_DaoJiShi:Hide()
--	SelfJingMai_NAN3Watch_DaoJiShi:Hide()
--
--	if SelfJingMai_IsOnlyFenYe1() == 1 then--2 3页都没解锁，也就是只有第一页这里在所有控件显隐处理完之后再判断是否只有第一页然后针对第一页的控件进行隐藏。
--		SelfJingMai_NAN1_Btn:Hide()
--		SelfJingMai_NAN1Watch_DaoJiShi:Hide()
--		SelfJingMai_NAN1Watch_Time_Text:Hide()
--
--		SelfJingMai_NV1_Btn:Hide()
--		SelfJingMai_NV1Watch_DaoJiShi:Hide()
--		SelfJingMai_NV1Watch_Time_Text:Hide()
--	end
--end

function SelfJingMai_IsOnlyFenYe1()--只有分页1时返回1，否则返回0
	local is2Open = Pneuma:GetMF(g_JingMai_MF_OpenFenye2)
	local is3Open = Pneuma:GetMF(g_JingMai_MF_OpenFenye3)

	if is2Open == 0 and is3Open == 0 then
		return 1
	end
	return 0
end


function SelfJingMai_ShowPage()

	for i = 1, table.getn(g_SelfJingMai_Page) do
		g_SelfJingMai_PageButton[i]:Hide()
		g_SelfJingMai_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfJingMai_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfJingMai_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfJingMai_Page) do
			if i ~= nPageNumber then
				g_SelfJingMai_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfJingMai_Page) do
		if SelfJingMai_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfJingMai_PageButton[g_PageCount]:Show()
			g_SelfJingMai_PageButton[g_PageCount]:SetText(g_SelfJingMai_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfJingMai_IsPageEnable(i) == 1 then
				g_SelfJingMai_PageButton[g_PageCount]:Enable()
				g_SelfJingMai_PageMask[g_PageCount]:Hide()
			else
				g_SelfJingMai_PageButton[g_PageCount]:Disable()
				g_SelfJingMai_PageMask[g_PageCount]:Show()
				if g_SelfJingMai_Page[i].Tip ~= "" then
					g_SelfJingMai_PageMask[g_PageCount]:SetToolTip(g_SelfJingMai_Page[i].Tip)
				end
			end
		end
	end
	
	SelfJingMai_RefreshWuYiTip()
	SelfJingMai_RefreshOtherInfoTip()
	SelfJingMai_RefreshCangPinTip()
	
end

function SelfJingMai_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		JingMai_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		JingMai_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		JingMai_Pet_Page_Switch()
	elseif idx == 4 then--子女
		JingMai_Infant_Switch()
	elseif idx == 5 then--武魂
		JingMai_Wuhun_Page_Switch()
	elseif idx == 6 then--修炼
		JingMai_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		JingMai_Miji_Page_Switch()
	elseif idx == 8 then--真元
		JingMai_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		JingMai_SelfJingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		JingMai_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SelfJingMai_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		SelfJingMai_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfJingMai_OpenWuYi()
	elseif idx == 14 then--神器
		SelfJingMai_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfJingMai_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfJingMai_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		JingMai_OtherInfo_Page_Switch()
	end
end

function SelfJingMai_CheckPage(idx)
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

function SelfJingMai_IsPageEnable(idx)
	
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

function SelfJingMai_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end

