--******************************************************************************
-- 清凉盛夏活动界面 by 宋旭阳
--******************************************************************************
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_JiuJiuXiaoHan_Summer_FrameImage = {}
local g_JiuJiuXiaoHan_Summer_Text = {}
local g_JiuJiuXiaoHan_Summer_ActiveTime = {}
local g_JiuJiuXiaoHan_Summer_Animate = {}
local g_JiuJiuXiaoHan_Summer_PrizeButton = {}  --活动界面两个奖励按钮
local g_JiuJiuXiaoHan_Summer_ShowTime
local g_JiuJiuXiaoHan_Summer_Fenye = 1

--兑换界面
local g_JiuJiuXiaoHan_Summer_CurPage = 0
local g_JiuJiuXiaoHan_Summer_Prize_Icon = {} --图标/按钮
local g_JiuJiuXiaoHan_Summer_Prize_Need = {} --需要薄荷叶txt
local g_JiuJiuXiaoHan_Summer_ItemName = {} --兑换物品名字
local g_JiuJiuXiaoHan_Summer_BuyLimitNumBK = {} --限购数字背景
local g_JiuJiuXiaoHan_Summer_BuyLimitNum = {} --限购数字
local g_JiuJiuXiaoHan_Summer_BuyLimitImg = {} --限购图标
local g_JiuJiuXiaoHan_Summer_Prize_SellOutMask = {} --售罄蒙灰
local g_JiuJiuXiaoHan_Summer_Prize_SellOutImg = {} --售罄图标

local g_JiuJiuXiaoHan_Summer_StartTime = 20210628
local g_JiuJiuXiaoHan_Summer_EndTime = 20210711
local g_JiuJiuXiaoHan_Summer_NeedItemID = 38002027

--时间单位 minute
local g_NeedOnlineTime_First = 30
local g_NeedOnlineTime_Second = 60
local g_NeedOnlineTime_Third = 120

local g_NeedPoint_First = 50
local g_NeedPoint_Second = 150
local g_NeedPoint_Third = 300

local g_RewardList = {
	[1] = {GiftItemID = 39922858, nNum = 1, need = 3, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[2] = {GiftItemID = 39920490, nNum = 2, need = 3, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[3] = {GiftItemID = 39921051, nNum = 4, need = 3, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[4] = {GiftItemID = 39922684, nNum = 10, need = 3, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	--[5] = {GiftItemID = 39922711, nNum = 1, need = 3, nBind = 0, bag = 1,mat = 0, nLimit = 1, MD = 2114},
	[5] = {GiftItemID = 39921180, nNum = 1, need = 5, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[6] = {GiftItemID = 39922834, nNum = 1, need = 5, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[7] = {GiftItemID = 39920311, nNum = 3, need = 5, nBind = 0, bag = 3,mat = 0, nLimit = 0, MD = 0},
	[8] = {GiftItemID = 39920181, nNum = 1, need = 5, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[9] = {GiftItemID = 39922685, nNum = 20, need = 5, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[10] = {GiftItemID = 39922701, nNum = 1, need = 5, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[11] = {GiftItemID = 39921226, nNum = 1, need = 8, nBind = 1, bag = 0,mat = 1, nLimit = 0, MD = 0},
	[12] = {GiftItemID = 39921227, nNum = 1, need = 8, nBind = 1, bag = 0,mat = 1, nLimit = 0, MD = 0},
	[13] = {GiftItemID = 39921228, nNum = 1, need = 8, nBind = 1, bag = 0,mat = 1, nLimit = 0, MD = 0},
	[14] = {GiftItemID = 39921229, nNum = 1, need = 8, nBind = 1, bag = 0,mat = 1, nLimit = 0, MD = 0},
	[15] = {GiftItemID = 39922178, nNum = 10, need = 8, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
	[16] = {GiftItemID = 39920566, nNum = 1, need = 10, nBind = 1, bag = 0,mat = 1, nLimit = 0, MD = 0},
	[17] = {GiftItemID = 39920565, nNum = 1, need = 10, nBind = 1, bag = 0,mat = 1, nLimit = 0, MD = 0},
	[18] = {GiftItemID = 39922715, nNum = 1, need = 10, nBind = 0, bag = 1,mat = 0, nLimit = 0, MD = 0},
}

local g_ThirdLayerText = {
	[7] = "#{QLSX_170620_30}",
	[8] = "#{QLSX_170620_31}",
	[9] = "#{QLSX_170620_32}",
	}

g_JiuJiuXiaoHan_Summer_Image_Active = {
	[1] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_1",
	[2] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_3",
	[3] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_5",
	[4] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_7",
	[5] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_9",
	[6] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_11",
	[7] = "set:JiuJiuXiaoHanTu_Summer02 image:JiuJiuXiaoHanTu_Summer02_1",
	[8] = "set:JiuJiuXiaoHanTu_Summer02 image:JiuJiuXiaoHanTu_Summer02_3",
	[9] = "set:JiuJiuXiaoHanTu_Summer02 image:JiuJiuXiaoHanTu_Summer02_5",
}

g_JiuJiuXiaoHan_Summer_Image_Inactive = {
	[1] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_2",
	[2] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_4",
	[3] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_6",
	[4] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_8",
	[5] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_10",
	[6] = "set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_12",
	[7] = "set:JiuJiuXiaoHanTu_Summer02 image:JiuJiuXiaoHanTu_Summer02_2",
	[8] = "set:JiuJiuXiaoHanTu_Summer02 image:JiuJiuXiaoHanTu_Summer02_4",
	[9] = "set:JiuJiuXiaoHanTu_Summer02 image:JiuJiuXiaoHanTu_Summer02_6",
}

function JiuJiuXiaoHan_Summer_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_JIUJIUXIAOHAN_SUMMER_EXCHANGEPRIZE")
	--物品发生变化
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function JiuJiuXiaoHan_Summer_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition = JiuJiuXiaoHan_Summer_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = JiuJiuXiaoHan_Summer_Frame:GetProperty("UnifiedYPosition");
	
	g_JiuJiuXiaoHan_Summer_FrameImage[1] = JiuJiuXiaoHan_Summer_MainFrame_Clinet1_image
	g_JiuJiuXiaoHan_Summer_FrameImage[2] = JiuJiuXiaoHan_Summer_MainFrame_Clinet2_image
	g_JiuJiuXiaoHan_Summer_FrameImage[3] = JiuJiuXiaoHan_Summer_MainFrame_Clinet3_image
	g_JiuJiuXiaoHan_Summer_FrameImage[4] = JiuJiuXiaoHan_Summer_MainFrame_Clinet4_image
	g_JiuJiuXiaoHan_Summer_FrameImage[5] = JiuJiuXiaoHan_Summer_MainFrame_Clinet5_image
	g_JiuJiuXiaoHan_Summer_FrameImage[6] = JiuJiuXiaoHan_Summer_MainFrame_Clinet6_image
	g_JiuJiuXiaoHan_Summer_FrameImage[7] = JiuJiuXiaoHan_Summer_MainFrame_Clinet7_image
	g_JiuJiuXiaoHan_Summer_FrameImage[8] = JiuJiuXiaoHan_Summer_MainFrame_Clinet8_image
	g_JiuJiuXiaoHan_Summer_FrameImage[9] = JiuJiuXiaoHan_Summer_MainFrame_Clinet9_image
	
	g_JiuJiuXiaoHan_Summer_Text[1] = JiuJiuXiaoHan_Summer_MainFrame_Clinet1_text
	g_JiuJiuXiaoHan_Summer_Text[2] = JiuJiuXiaoHan_Summer_MainFrame_Clinet2_text
	g_JiuJiuXiaoHan_Summer_Text[3] = JiuJiuXiaoHan_Summer_MainFrame_Clinet3_text
	g_JiuJiuXiaoHan_Summer_Text[4] = JiuJiuXiaoHan_Summer_MainFrame_Clinet4_text
	g_JiuJiuXiaoHan_Summer_Text[5] = JiuJiuXiaoHan_Summer_MainFrame_Clinet5_text
	g_JiuJiuXiaoHan_Summer_Text[6] = JiuJiuXiaoHan_Summer_MainFrame_Clinet6_text
	g_JiuJiuXiaoHan_Summer_Text[7] = JiuJiuXiaoHan_Summer_MainFrame_Clinet7_text
	g_JiuJiuXiaoHan_Summer_Text[8] = JiuJiuXiaoHan_Summer_MainFrame_Clinet8_text
	g_JiuJiuXiaoHan_Summer_Text[9] = JiuJiuXiaoHan_Summer_MainFrame_Clinet9_text

	g_JiuJiuXiaoHan_Summer_ActiveTime[1] = 	JiuJiuXiaoHan_Summer_MainFrame_Clinet1_text1
	g_JiuJiuXiaoHan_Summer_ActiveTime[2] = 	JiuJiuXiaoHan_Summer_MainFrame_Clinet1_text2
	g_JiuJiuXiaoHan_Summer_ActiveTime[3] = 	JiuJiuXiaoHan_Summer_MainFrame_Clinet1_text3
	
	g_JiuJiuXiaoHan_Summer_Animate[7] = JiuJiuXiaoHan_Summer_MainFrame_Clinet7_image_Animate
	g_JiuJiuXiaoHan_Summer_Animate[8] = JiuJiuXiaoHan_Summer_MainFrame_Clinet8_image_Animate
	g_JiuJiuXiaoHan_Summer_Animate[9] = JiuJiuXiaoHan_Summer_MainFrame_Clinet9_image_Animate
	
	g_JiuJiuXiaoHan_Summer_PrizeButton[1] = JiuJiuXiaoHan_Summer_Prize1
	g_JiuJiuXiaoHan_Summer_PrizeButton[2] = JiuJiuXiaoHan_Summer_Prize2
	
	g_JiuJiuXiaoHan_Summer_ShowTime = JiuJiuXiaoHan_Summer_IntroFrame_TextLace_text
	
	g_JiuJiuXiaoHan_Summer_Prize_Icon[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_Icon
	g_JiuJiuXiaoHan_Summer_Prize_Icon[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_Icon

	g_JiuJiuXiaoHan_Summer_Prize_Need[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_ItemMoney
	g_JiuJiuXiaoHan_Summer_Prize_Need[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_ItemMoney
	
	g_JiuJiuXiaoHan_Summer_ItemName[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_ItemName
	g_JiuJiuXiaoHan_Summer_ItemName[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_ItemName
	
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_Icon_BuyLimitNumBK
	g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_Icon_BuyLimitNumBK
	
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_Icon_BuyLimitNum
	g_JiuJiuXiaoHan_Summer_BuyLimitNum[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_Icon_BuyLimitNum

	
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_Icon_BuyLimit
	g_JiuJiuXiaoHan_Summer_BuyLimitImg[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_Icon_BuyLimit
	
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_Icon_Mask
	g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_Icon_Mask
	
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[1] = JiuJiuXiaoHan_Summer_PrizeFrame_BK1_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[2] = JiuJiuXiaoHan_Summer_PrizeFrame_BK2_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[3] = JiuJiuXiaoHan_Summer_PrizeFrame_BK3_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[4] = JiuJiuXiaoHan_Summer_PrizeFrame_BK4_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[5] = JiuJiuXiaoHan_Summer_PrizeFrame_BK5_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[6] = JiuJiuXiaoHan_Summer_PrizeFrame_BK6_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[7] = JiuJiuXiaoHan_Summer_PrizeFrame_BK7_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[8] = JiuJiuXiaoHan_Summer_PrizeFrame_BK8_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[9] = JiuJiuXiaoHan_Summer_PrizeFrame_BK9_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[10] = JiuJiuXiaoHan_Summer_PrizeFrame_BK10_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[11] = JiuJiuXiaoHan_Summer_PrizeFrame_BK11_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[12] = JiuJiuXiaoHan_Summer_PrizeFrame_BK12_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[13] = JiuJiuXiaoHan_Summer_PrizeFrame_BK13_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[14] = JiuJiuXiaoHan_Summer_PrizeFrame_BK14_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[15] = JiuJiuXiaoHan_Summer_PrizeFrame_BK15_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[16] = JiuJiuXiaoHan_Summer_PrizeFrame_BK16_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[17] = JiuJiuXiaoHan_Summer_PrizeFrame_BK17_SellOut
	g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[18] = JiuJiuXiaoHan_Summer_PrizeFrame_BK18_SellOut
	
	
	
end

function JiuJiuXiaoHan_Summer_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 201706221 ) then
		Open_JiuJiuXiaoHan_Summer( Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), 
							Get_XParam_INT(3), Get_XParam_INT(4), Get_XParam_INT(5),
							Get_XParam_INT(6), Get_XParam_INT(7), Get_XParam_INT(8))
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201706223 ) then
		--更新界面
		if this:IsVisible() then
			Open_JiuJiuXiaoHan_Summer( Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), 
							Get_XParam_INT(3), Get_XParam_INT(4), Get_XParam_INT(5),
							Get_XParam_INT(6), Get_XParam_INT(7), Get_XParam_INT(8))
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201706224 ) then
		--更新按钮状态
		JiuJiuXiaoHan_Summer_Update_PrizeButton( Get_XParam_INT(0), Get_XParam_INT(1) )
	elseif ( event == "OPEN_JIUJIUXIAOHAN_SUMMER_EXCHANGEPRIZE" ) or ( event == "UI_COMMAND" and tonumber(arg0) == 89245611 ) then	
		JiuJiuXiaoHan_Summer_OpenPrize(1)
		this:Show()
	
	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		
		if (arg0~= nil and -1 == tonumber(arg0)) then
			return
		end 
		JiuJiuXiaoHan_Summer_Refresh_Item()
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		JiuJiuXiaoHan_Summer_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JiuJiuXiaoHan_Summer_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		JiuJiuXiaoHan_Summer_Close()
	end
end

function Open_JiuJiuXiaoHan_Summer(TodayOnlineTime, TodayPoint, mymission, 
							mission_7, mission_8, mission_9, 
							prize_1, prize_2, activenum)
	
	--活动重开 重新布局 这句不要了
	--local nTimeText = JiuJiuXiaoHan_Summer_GetTimeText(TodayOnlineTime)
	--g_JiuJiuXiaoHan_Summer_ShowTime:SetText( ScriptGlobal_Format("#{QLSX_180521_1}", nTimeText) )
	g_JiuJiuXiaoHan_Summer_Fenye = 1
	local onlineTime = ""
	local nHour = math.floor(TodayOnlineTime/60)
	local nMinute = math.mod(TodayOnlineTime, 60)
	if nHour > 0 then	
		onlineTime = ScriptGlobal_Format( "#{QLSX_180521_3}", nHour , nMinute )
	else	
		onlineTime = ScriptGlobal_Format( "#{QLSX_180521_4}",nMinute)
	end
	
	--第一层
	if TodayOnlineTime >=  g_NeedOnlineTime_Third then
		g_JiuJiuXiaoHan_Summer_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[1])
		g_JiuJiuXiaoHan_Summer_ActiveTime[1]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[1]:SetText("#G".."#{QLSX_170620_24}")
		g_JiuJiuXiaoHan_Summer_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[2])
		g_JiuJiuXiaoHan_Summer_ActiveTime[2]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[2]:SetText("#G".."#{QLSX_170620_25}")
		g_JiuJiuXiaoHan_Summer_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[3])
		g_JiuJiuXiaoHan_Summer_ActiveTime[3]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[3]:SetText("#G".."#{QLSX_170620_26}")
	elseif TodayOnlineTime >=  g_NeedOnlineTime_Second then
		g_JiuJiuXiaoHan_Summer_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[1])
		g_JiuJiuXiaoHan_Summer_ActiveTime[1]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[1]:SetText("#G".."#{QLSX_170620_24}")
		g_JiuJiuXiaoHan_Summer_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[2])
		g_JiuJiuXiaoHan_Summer_ActiveTime[2]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[2]:SetText("#G".."#{QLSX_170620_25}")
		g_JiuJiuXiaoHan_Summer_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[3])
		g_JiuJiuXiaoHan_Summer_ActiveTime[3]:SetText(onlineTime)
		g_JiuJiuXiaoHan_Summer_Text[3]:SetText("#cff0000".."#{QLSX_170620_26}")
	elseif TodayOnlineTime >=  g_NeedOnlineTime_First then
		g_JiuJiuXiaoHan_Summer_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[1])
		g_JiuJiuXiaoHan_Summer_ActiveTime[1]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[1]:SetText("#G".."#{QLSX_170620_24}")
		g_JiuJiuXiaoHan_Summer_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[2])
		g_JiuJiuXiaoHan_Summer_ActiveTime[2]:SetText(onlineTime)
		g_JiuJiuXiaoHan_Summer_Text[2]:SetText("#cff0000".."#{QLSX_170620_25}")
		g_JiuJiuXiaoHan_Summer_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[3])
		g_JiuJiuXiaoHan_Summer_ActiveTime[3]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[3]:SetText("#cff0000".."#{QLSX_170620_26}")
	else
		g_JiuJiuXiaoHan_Summer_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[1])
		g_JiuJiuXiaoHan_Summer_ActiveTime[1]:SetText(onlineTime)
		g_JiuJiuXiaoHan_Summer_Text[1]:SetText("#cff0000".."#{QLSX_170620_24}")
		g_JiuJiuXiaoHan_Summer_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[2])
		g_JiuJiuXiaoHan_Summer_ActiveTime[2]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[2]:SetText("#cff0000".."#{QLSX_170620_25}")
		g_JiuJiuXiaoHan_Summer_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[3])
		g_JiuJiuXiaoHan_Summer_ActiveTime[3]:SetText("")
		g_JiuJiuXiaoHan_Summer_Text[3]:SetText("#cff0000".."#{QLSX_170620_26}")
	end
	--第二层
	if TodayPoint >= g_NeedPoint_Third then
		g_JiuJiuXiaoHan_Summer_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[4])
		g_JiuJiuXiaoHan_Summer_Text[4]:SetText( "#G"..ScriptGlobal_Format("#{QLSX_170620_21}", g_NeedPoint_First) )
		g_JiuJiuXiaoHan_Summer_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[5])
		g_JiuJiuXiaoHan_Summer_Text[5]:SetText( "#G"..ScriptGlobal_Format("#{QLSX_170620_22}", g_NeedPoint_Second) )
		g_JiuJiuXiaoHan_Summer_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[6])
		g_JiuJiuXiaoHan_Summer_Text[6]:SetText( "#G"..ScriptGlobal_Format("#{QLSX_170620_23}", g_NeedPoint_Third) )
	elseif TodayPoint >=  g_NeedPoint_Second then
		g_JiuJiuXiaoHan_Summer_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[4])
		g_JiuJiuXiaoHan_Summer_Text[4]:SetText( "#G"..ScriptGlobal_Format("#{QLSX_170620_21}", g_NeedPoint_First) )
		g_JiuJiuXiaoHan_Summer_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[5])
		g_JiuJiuXiaoHan_Summer_Text[5]:SetText( "#G"..ScriptGlobal_Format("#{QLSX_170620_22}", g_NeedPoint_Second) )
		g_JiuJiuXiaoHan_Summer_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[6])
		g_JiuJiuXiaoHan_Summer_Text[6]:SetText( "#cff0000"..ScriptGlobal_Format("#{QLSX_170620_23}", TodayPoint) )
	elseif TodayPoint >=  g_NeedPoint_First then
		g_JiuJiuXiaoHan_Summer_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[4])
		g_JiuJiuXiaoHan_Summer_Text[4]:SetText( "#G"..ScriptGlobal_Format("#{QLSX_170620_21}", g_NeedPoint_First) )
		g_JiuJiuXiaoHan_Summer_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[5])
		g_JiuJiuXiaoHan_Summer_Text[5]:SetText( "#cff0000"..ScriptGlobal_Format("#{QLSX_170620_22}", TodayPoint) )
		g_JiuJiuXiaoHan_Summer_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[6])
		g_JiuJiuXiaoHan_Summer_Text[6]:SetText( "#cff0000"..ScriptGlobal_Format("#{QLSX_170620_23}", TodayPoint) )
	else
		g_JiuJiuXiaoHan_Summer_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[4])
		g_JiuJiuXiaoHan_Summer_Text[4]:SetText( "#cff0000"..ScriptGlobal_Format("#{QLSX_170620_21}", TodayPoint) )
		g_JiuJiuXiaoHan_Summer_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[5])
		g_JiuJiuXiaoHan_Summer_Text[5]:SetText( "#cff0000"..ScriptGlobal_Format("#{QLSX_170620_22}", TodayPoint) )
		g_JiuJiuXiaoHan_Summer_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[6])
		g_JiuJiuXiaoHan_Summer_Text[6]:SetText( "#cff0000"..ScriptGlobal_Format("#{QLSX_170620_23}", TodayPoint) )
	end
	--第三层
	if mission_7 == 1 then
		g_JiuJiuXiaoHan_Summer_FrameImage[7]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[7])
		g_JiuJiuXiaoHan_Summer_Text[7]:SetText("#{QLSX_170620_36}")
	else
		g_JiuJiuXiaoHan_Summer_FrameImage[7]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[7])
		g_JiuJiuXiaoHan_Summer_Text[7]:SetText("#{QLSX_170620_33}")
	end
	if mission_8 == 1 then
		g_JiuJiuXiaoHan_Summer_FrameImage[8]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[8])
		g_JiuJiuXiaoHan_Summer_Text[8]:SetText("#{QLSX_170620_36}")
	else
		g_JiuJiuXiaoHan_Summer_FrameImage[8]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[8])
		g_JiuJiuXiaoHan_Summer_Text[8]:SetText("#{QLSX_170620_34}")
	end
	if mission_9 == 1 then
		g_JiuJiuXiaoHan_Summer_FrameImage[9]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Active[9])
		g_JiuJiuXiaoHan_Summer_Text[9]:SetText("#{QLSX_170620_36}")
	else
		g_JiuJiuXiaoHan_Summer_FrameImage[9]:SetProperty("Image", g_JiuJiuXiaoHan_Summer_Image_Inactive[9])
		g_JiuJiuXiaoHan_Summer_Text[9]:SetText("#{QLSX_170620_35}")
	end
	
	for i=7,9 do
		g_JiuJiuXiaoHan_Summer_Animate[i]:Hide()
	end
	--玩家拥有的任务闪烁+文字 
	local mymissionstate = 0
	if mymission == 7 then
		mymissionstate = mission_7
	elseif mymission == 8 then
		mymissionstate = mission_8
	elseif mymission == 9 then
		mymissionstate = mission_9
	end
	if mymissionstate < 1 then
		g_JiuJiuXiaoHan_Summer_Text[mymission]:SetText(g_ThirdLayerText[mymission])
		g_JiuJiuXiaoHan_Summer_Animate[mymission]:Show()
	end
	
	--按钮状态
	JiuJiuXiaoHan_Summer_Update_PrizeButton(prize_1, prize_2)
	
	JiuJiuXiaoHan_Summer_HideAllChannel()
	JiuJiuXiaoHan_Summer_Frame_Client:Show()
	JiuJiuXiaoHan_Summer_Button01:SetCheck(1)
	JiuJiuXiaoHan_Summer_Button02:SetCheck(0)
	g_JiuJiuXiaoHan_Summer_CurPage = 0	
end


--***************************************
--更新活动界面的两个领奖按钮
--***************************************
function JiuJiuXiaoHan_Summer_Update_PrizeButton(PrizeButton_1, PrizeButton_2)
	if PrizeButton_1 == 0 then
		g_JiuJiuXiaoHan_Summer_PrizeButton[1]:Enable()
	elseif PrizeButton_1 == 1 then
		g_JiuJiuXiaoHan_Summer_PrizeButton[1]:Disable()
	end
	
	if PrizeButton_2 == 0 then
		g_JiuJiuXiaoHan_Summer_PrizeButton[2]:Enable()
	elseif PrizeButton_2 == 1 then
		g_JiuJiuXiaoHan_Summer_PrizeButton[2]:Disable()
	end
end

--*********************************
--每日奖励领取
--*********************************
function JiuJiuXiaoHan_Summer_PrizeButton_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetPrize")  
		Set_XSCRIPT_ScriptID(892456)
		Set_XSCRIPT_Parameter(0,tonumber(nIndex))
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function JiuJiuXiaoHan_Summer_ResetPos()
	JiuJiuXiaoHan_Summer_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	JiuJiuXiaoHan_Summer_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function JiuJiuXiaoHan_Summer_Close()
	g_JiuJiuXiaoHan_Summer_CurPage = 0
	g_JiuJiuXiaoHan_Summer_Fenye = 1
	this:Hide();
end

function JiuJiuXiaoHan_Summer_OpenRuleLink()
	PushEvent("OPEN_JIUJIUXIAOHAN_SUMMER_README")
end

function JiuJiuXiaoHan_Summer_GetTimeText(TodayOnlineTime)
	local nHour = math.floor(TodayOnlineTime/60)
	local nMinute = math.mod(TodayOnlineTime, 60)
	if nHour > 0 then
		return nHour.."小时"..nMinute.."分"
	else
		return nMinute.."分"
	end
end

function JiuJiuXiaoHan_Summer_OnFenYeClick(nIndex)

--	PushDebugMessage("JiuJiuXiaoHan_Summer_OnFenYeClick  nIndex="..nIndex)
	local curDay = tonumber(DataPool:GetServerDayTime())
	local IsFinish = 0
	if curDay > g_JiuJiuXiaoHan_Summer_EndTime or curDay < g_JiuJiuXiaoHan_Summer_StartTime then
		IsFinish = 1
	end
	
	--g_JiuJiuXiaoHan_Summer_Fenye = nIndex
	if nIndex == 1 then
		if IsFinish > 0 then 
			PushDebugMessage("#{QLSX_170620_10}")
			JiuJiuXiaoHan_Summer_Button01:SetCheck(0)
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")  
			Set_XSCRIPT_ScriptID(892456) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif nIndex == 2 then
		JiuJiuXiaoHan_Summer_OpenPrize(1)
	end
	
end


--************************************************
-- 兑换界面
--************************************************
function JiuJiuXiaoHan_Summer_OpenPrize(nPage)

	--PushDebugMessage("JiuJiuXiaoHan_Summer_OpenPrize")
	g_JiuJiuXiaoHan_Summer_Fenye = 2
	for i = 1, table.getn(g_RewardList) do
		local theAction = DataPool:CreateActionItemForShow(g_RewardList[i].GiftItemID, g_RewardList[i].nNum)
		if theAction:GetID() ~= 0 then
			g_JiuJiuXiaoHan_Summer_Prize_Icon[i]:SetActionItem(theAction:GetID());
			g_JiuJiuXiaoHan_Summer_Prize_Icon[i]:Show();
		end
		--物品名字
		local itemname = DataPool:Lua_GetItemNameByIndex(g_RewardList[i].GiftItemID)
		g_JiuJiuXiaoHan_Summer_ItemName[i]:SetText("#L"..itemname)
		--兑换需要数ToolTip
		local tooltip = ScriptGlobal_Format("#{QLSX_170620_81}", g_RewardList[i].need)
		g_JiuJiuXiaoHan_Summer_Prize_Icon[i]:SetToolTip(tooltip)	
		--兑换需要数txt
		local needTooltip = ScriptGlobal_Format("#{QLSX_170620_82}", g_RewardList[i].need)
		g_JiuJiuXiaoHan_Summer_Prize_Need[i]:SetText(needTooltip)	
		--限购数字
		if g_RewardList[i].nLimit < 1 then
			g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[i]:Hide() 
			g_JiuJiuXiaoHan_Summer_BuyLimitNum[i]:Hide() 
			g_JiuJiuXiaoHan_Summer_BuyLimitImg[i]:Hide() 
			g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[i]:Hide() 
			g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[i]:Hide() 
		else
			if tonumber(g_RewardList[i].MD) > 0 then
				--限购物品
				local mCurNum = DataPool:GetPlayerMission_DataRound(tonumber(g_RewardList[i].MD))	
				local nCurLeft = g_RewardList[i].nLimit - mCurNum
				--PushDebugMessage("限购物品 mCurNum="..mCurNum.."  nLimit="..g_RewardList[i].nLimit.."  nCurLeft="..nCurLeft)
				if g_RewardList[i].nLimit > mCurNum then
					g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[i]:Show()
					g_JiuJiuXiaoHan_Summer_BuyLimitNum[i]:Show()
					g_JiuJiuXiaoHan_Summer_BuyLimitNum[i]:SetText(tonumber(nCurLeft))	
					g_JiuJiuXiaoHan_Summer_BuyLimitImg[i]:Show()
					g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[i]:Hide() 
					g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[i]:Hide() 
				else
					--售罄
					g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[i]:Show()
					g_JiuJiuXiaoHan_Summer_BuyLimitNum[i]:Show()
					g_JiuJiuXiaoHan_Summer_BuyLimitNum[i]:SetText(tonumber(nCurLeft))	
					g_JiuJiuXiaoHan_Summer_BuyLimitImg[i]:Show()
					g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[i]:Show()
					g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[i]:Show()
				end
			else
				g_JiuJiuXiaoHan_Summer_BuyLimitNumBK[i]:Hide() 
				g_JiuJiuXiaoHan_Summer_BuyLimitNum[i]:Hide() 
				g_JiuJiuXiaoHan_Summer_BuyLimitImg[i]:Hide() 
				g_JiuJiuXiaoHan_Summer_Prize_SellOutMask[i]:Hide() 
				g_JiuJiuXiaoHan_Summer_Prize_SellOutImg[i]:Hide() 
			end
		end
	end

	JiuJiuXiaoHan_Summer_HideAllChannel()
	JiuJiuXiaoHan_Summer_Frame_PrizeClient:Show()
	JiuJiuXiaoHan_Summer_Button01:SetCheck(0)
	JiuJiuXiaoHan_Summer_Button02:SetCheck(1)
	
	if nPage == 2 then	
		JiuJiuXiaoHan_Summer_PrizeFrame_Client1:Hide() 
		JiuJiuXiaoHan_Summer_PrizeFrame_Client2:Show()
		g_JiuJiuXiaoHan_Summer_CurPage = 2
	else
		JiuJiuXiaoHan_Summer_PrizeFrame_Client1:Show()
		JiuJiuXiaoHan_Summer_PrizeFrame_Client2:Hide() 
		g_JiuJiuXiaoHan_Summer_CurPage = 1
	end
	
	--显示当前页数
	local numShow = ScriptGlobal_Format("#{QLSX_200624_21}", g_JiuJiuXiaoHan_Summer_CurPage,2)
	JiuJiuXiaoHan_Summer_CurrentlyPage:SetText(numShow)	
	
	--显示当前薄荷数
	local HaveIDcount = PlayerPackage:CountAvailableItemByIDTable(g_JiuJiuXiaoHan_Summer_NeedItemID) 
	JiuJiuXiaoHan_Summer_PrizeInfo2_Lace:SetText(ScriptGlobal_Format("#{QLSX_200624_01}", HaveIDcount))
end


--***************************************
--兑换界面 点击物品
--***************************************
function JiuJiuXiaoHan_Summer_ExchangePrize(nIndex)
	if nIndex < 1 or nIndex > table.getn(g_RewardList) then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ExchangePrizeCheck")  
		Set_XSCRIPT_ScriptID(892456)
		Set_XSCRIPT_Parameter(0,tonumber(nIndex))
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function JiuJiuXiaoHan_Summer_HideAllChannel()
	JiuJiuXiaoHan_Summer_Frame_PrizeClient:Hide()
	JiuJiuXiaoHan_Summer_Frame_Client:Hide()
end

--************************************************
-- 兑换界面翻页按钮 上一页
--************************************************
function JiuJiuXiaoHan_Summer_onPageUp()

	JiuJiuXiaoHan_Summer_OpenPrize(1)
end


--************************************************
-- 兑换界面翻页按钮 下一页
--************************************************
function JiuJiuXiaoHan_Summer_onPageDown()

	JiuJiuXiaoHan_Summer_OpenPrize(2)
end


--************************************************
-- help说明按钮
--************************************************
function JiuJiuXiaoHan_Summer_Help()

	--PushDebugMessage("help")
	--弹出说明
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HelpInstruction")
		Set_XSCRIPT_ScriptID(892456)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end


--************************************************
-- 物品发生变化
--************************************************
function JiuJiuXiaoHan_Summer_Refresh_Item() 

	--如果当前不在限购页面 返回
	if g_JiuJiuXiaoHan_Summer_Fenye ~= 2 then
		return
	end
	--PushDebugMessage("JiuJiuXiaoHan_Summer_Refresh_Item")
	local HaveIDcount = PlayerPackage:CountAvailableItemByIDTable(g_JiuJiuXiaoHan_Summer_NeedItemID) 
	JiuJiuXiaoHan_Summer_PrizeInfo2_Lace:SetText(ScriptGlobal_Format("#{QLSX_200624_01}", HaveIDcount))
	
	--刷新限购
	JiuJiuXiaoHan_Summer_OpenPrize(g_JiuJiuXiaoHan_Summer_CurPage)
end