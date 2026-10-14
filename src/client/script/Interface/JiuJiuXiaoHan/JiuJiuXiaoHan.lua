--******************************************************************************
-- 九九消寒活动界面 by 宋旭阳
--******************************************************************************
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

--local g_JiuJiuXiaoHan_IsFirstTimeOpen = 1
local g_JiuJiuXiaoHan_FrameImage = {}
local g_JiuJiuXiaoHan_Text = {}
local g_JiuJiuXiaoHan_PirzeButton = {}
local g_JiuJiuXiaoHan_Animate = {}
local g_JiuJiuXiaoHan_PrizeButton = {}
local g_JiuJiuXiaoHan_ShowTime
local g_JiuJiuXiaoHan_Prize_Icon = {}
local g_JiuJiuXiaoHan_Prize_ItemMoney = {}
local g_JiuJiuXiaoHan_Prize_ItemName = {}

local g_JiuJiuXiaoHan_StartTime = 20211118
local g_JiuJiuXiaoHan_EndTime = 20211201

--时间单位 minute
local g_NeedOnlineTime_First = 30
local g_NeedOnlineTime_Second = 60
local g_NeedOnlineTime_Third = 120

local g_NeedPoint_First = 50
local g_NeedPoint_Second = 150
local g_NeedPoint_Third = 300

local g_NowPrizePageIndex = 1

local g_RewardList = {
	{GiftItemID = 39923629, need = 3,num=1},
	{GiftItemID = 39920490, need = 3,num=2},
	{GiftItemID = 39921051, need = 3,num=4},
	{GiftItemID = 39922684, need = 3,num=10},
	{GiftItemID = 39923630, need = 5,num=1},
	{GiftItemID = 39920311, need = 5,num=3},
	{GiftItemID = 39920181, need = 5,num=1},
	{GiftItemID = 39922685, need = 5,num=20},
	{GiftItemID = 39922701, need = 5,num=1},
	{GiftItemID = 39921226, need = 8,num=1},--材料10
	{GiftItemID = 39921227, need = 8,num=1},--材料11
	{GiftItemID = 39921228, need = 8,num=1},--材料12
	{GiftItemID = 39921229, need = 8,num=1},--材料13
	{GiftItemID = 39922156, need = 8,num=10},
	{GiftItemID = 39920566, need = 10,num=1},--材料15
	{GiftItemID = 39920565, need = 10,num=1},--材料16
	{GiftItemID = 39923632, need = 10,num=1},
	{GiftItemID = 39923633, need = 3,num=1},
}

local g_ThirdLayerText = {
	[7] = "#{JJXH_161122_101}",
	[8] = "#{JJXH_161122_100}",
	[9] = "#{JJXH_161122_102}",
	}
--local g_TodayFirstTimeOpen = 0
g_JiuJiuXiaoHan_Image_Active = {
	[1] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_1",
	[2] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_3",
	[3] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_5",
	[4] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_7",
	[5] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_9",
	[6] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_11",
	[7] = "set:JiuJiuXiaoHanTu02 image:JiuJiuXiaoHanTu02_1",
	[8] = "set:JiuJiuXiaoHanTu02 image:JiuJiuXiaoHanTu02_3",
	[9] = "set:JiuJiuXiaoHanTu02 image:JiuJiuXiaoHanTu02_5",
}

g_JiuJiuXiaoHan_Image_Inactive = {
	[1] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_2",
	[2] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_4",
	[3] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_6",
	[4] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_8",
	[5] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_10",
	[6] = "set:JiuJiuXiaoHanTu01 image:JiuJiuXiaoHanTu01_12",
	[7] = "set:JiuJiuXiaoHanTu02 image:JiuJiuXiaoHanTu02_2",
	[8] = "set:JiuJiuXiaoHanTu02 image:JiuJiuXiaoHanTu02_4",
	[9] = "set:JiuJiuXiaoHanTu02 image:JiuJiuXiaoHanTu02_6",
}

function JiuJiuXiaoHan_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_JIUJIUXIAOHAN_EXCHANGEPRIZE")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--物品发生变化
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function JiuJiuXiaoHan_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition = JiuJiuXiaoHan_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = JiuJiuXiaoHan_Frame:GetProperty("UnifiedYPosition");
	
	g_JiuJiuXiaoHan_FrameImage[1] = JiuJiuXiaoHan_MainFrame_Clinet1_image
	g_JiuJiuXiaoHan_FrameImage[2] = JiuJiuXiaoHan_MainFrame_Clinet2_image
	g_JiuJiuXiaoHan_FrameImage[3] = JiuJiuXiaoHan_MainFrame_Clinet3_image
	g_JiuJiuXiaoHan_FrameImage[4] = JiuJiuXiaoHan_MainFrame_Clinet4_image
	g_JiuJiuXiaoHan_FrameImage[5] = JiuJiuXiaoHan_MainFrame_Clinet5_image
	g_JiuJiuXiaoHan_FrameImage[6] = JiuJiuXiaoHan_MainFrame_Clinet6_image
	g_JiuJiuXiaoHan_FrameImage[7] = JiuJiuXiaoHan_MainFrame_Clinet7_image
	g_JiuJiuXiaoHan_FrameImage[8] = JiuJiuXiaoHan_MainFrame_Clinet8_image
	g_JiuJiuXiaoHan_FrameImage[9] = JiuJiuXiaoHan_MainFrame_Clinet9_image
	
	g_JiuJiuXiaoHan_Text[1] = JiuJiuXiaoHan_MainFrame_Clinet1_text
	g_JiuJiuXiaoHan_Text[2] = JiuJiuXiaoHan_MainFrame_Clinet2_text
	g_JiuJiuXiaoHan_Text[3] = JiuJiuXiaoHan_MainFrame_Clinet3_text
	g_JiuJiuXiaoHan_Text[4] = JiuJiuXiaoHan_MainFrame_Clinet4_text
	g_JiuJiuXiaoHan_Text[5] = JiuJiuXiaoHan_MainFrame_Clinet5_text
	g_JiuJiuXiaoHan_Text[6] = JiuJiuXiaoHan_MainFrame_Clinet6_text
	g_JiuJiuXiaoHan_Text[7] = JiuJiuXiaoHan_MainFrame_Clinet7_text
	g_JiuJiuXiaoHan_Text[8] = JiuJiuXiaoHan_MainFrame_Clinet8_text
	g_JiuJiuXiaoHan_Text[9] = JiuJiuXiaoHan_MainFrame_Clinet9_text		
	
	g_JiuJiuXiaoHan_PirzeButton[1] = JiuJiuXiaoHan_Prize1
	g_JiuJiuXiaoHan_PirzeButton[2] = JiuJiuXiaoHan_Prize2
	
	g_JiuJiuXiaoHan_Animate[7] = JiuJiuXiaoHan_MainFrame_Clinet7_image_Animate
	g_JiuJiuXiaoHan_Animate[8] = JiuJiuXiaoHan_MainFrame_Clinet8_image_Animate
	g_JiuJiuXiaoHan_Animate[9] = JiuJiuXiaoHan_MainFrame_Clinet9_image_Animate
	
	g_JiuJiuXiaoHan_PrizeButton[1] = JiuJiuXiaoHan_Prize1
	g_JiuJiuXiaoHan_PrizeButton[2] = JiuJiuXiaoHan_Prize2
	
	g_JiuJiuXiaoHan_ShowTime = JiuJiuXiaoHan_IntroFrame_TextLace_text
	
	g_JiuJiuXiaoHan_Prize_Icon[1] = JiuJiuXiaoHan_PrizeFrame_BK1_Icon
	g_JiuJiuXiaoHan_Prize_Icon[2] = JiuJiuXiaoHan_PrizeFrame_BK2_Icon
	g_JiuJiuXiaoHan_Prize_Icon[3] = JiuJiuXiaoHan_PrizeFrame_BK3_Icon
	g_JiuJiuXiaoHan_Prize_Icon[4] = JiuJiuXiaoHan_PrizeFrame_BK4_Icon
	g_JiuJiuXiaoHan_Prize_Icon[5] = JiuJiuXiaoHan_PrizeFrame_BK5_Icon
	g_JiuJiuXiaoHan_Prize_Icon[6] = JiuJiuXiaoHan_PrizeFrame_BK6_Icon
	g_JiuJiuXiaoHan_Prize_Icon[7] = JiuJiuXiaoHan_PrizeFrame_BK7_Icon
	g_JiuJiuXiaoHan_Prize_Icon[8] = JiuJiuXiaoHan_PrizeFrame_BK8_Icon
	g_JiuJiuXiaoHan_Prize_Icon[9] = JiuJiuXiaoHan_PrizeFrame_BK9_Icon
	g_JiuJiuXiaoHan_Prize_Icon[10] = JiuJiuXiaoHan_PrizeFrame_BK10_Icon
	g_JiuJiuXiaoHan_Prize_Icon[11] = JiuJiuXiaoHan_PrizeFrame_BK11_Icon
	g_JiuJiuXiaoHan_Prize_Icon[12] = JiuJiuXiaoHan_PrizeFrame_BK12_Icon
	g_JiuJiuXiaoHan_Prize_Icon[13] = JiuJiuXiaoHan_PrizeFrame_BK13_Icon
	g_JiuJiuXiaoHan_Prize_Icon[14] = JiuJiuXiaoHan_PrizeFrame_BK14_Icon
	g_JiuJiuXiaoHan_Prize_Icon[15] = JiuJiuXiaoHan_PrizeFrame_BK15_Icon
	g_JiuJiuXiaoHan_Prize_Icon[16] = JiuJiuXiaoHan_PrizeFrame_BK16_Icon
	g_JiuJiuXiaoHan_Prize_Icon[17] = JiuJiuXiaoHan_PrizeFrame_BK17_Icon
	g_JiuJiuXiaoHan_Prize_Icon[18] = JiuJiuXiaoHan_PrizeFrame_BK18_Icon
	
	g_JiuJiuXiaoHan_Prize_ItemMoney[1] = JiuJiuXiaoHan_PrizeFrame_BK1_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[2] = JiuJiuXiaoHan_PrizeFrame_BK2_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[3] = JiuJiuXiaoHan_PrizeFrame_BK3_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[4] = JiuJiuXiaoHan_PrizeFrame_BK4_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[5] = JiuJiuXiaoHan_PrizeFrame_BK5_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[6] = JiuJiuXiaoHan_PrizeFrame_BK6_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[7] = JiuJiuXiaoHan_PrizeFrame_BK7_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[8] = JiuJiuXiaoHan_PrizeFrame_BK8_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[9] = JiuJiuXiaoHan_PrizeFrame_BK9_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[10] = JiuJiuXiaoHan_PrizeFrame_BK10_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[11] = JiuJiuXiaoHan_PrizeFrame_BK11_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[12] = JiuJiuXiaoHan_PrizeFrame_BK12_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[13] = JiuJiuXiaoHan_PrizeFrame_BK13_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[14] = JiuJiuXiaoHan_PrizeFrame_BK14_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[15] = JiuJiuXiaoHan_PrizeFrame_BK15_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[16] = JiuJiuXiaoHan_PrizeFrame_BK16_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[17] = JiuJiuXiaoHan_PrizeFrame_BK17_ItemMoney
	g_JiuJiuXiaoHan_Prize_ItemMoney[18] = JiuJiuXiaoHan_PrizeFrame_BK18_ItemMoney
	
	g_JiuJiuXiaoHan_Prize_ItemName[1] = JiuJiuXiaoHan_PrizeFrame_BK1_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[2] = JiuJiuXiaoHan_PrizeFrame_BK2_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[3] = JiuJiuXiaoHan_PrizeFrame_BK3_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[4] = JiuJiuXiaoHan_PrizeFrame_BK4_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[5] = JiuJiuXiaoHan_PrizeFrame_BK5_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[6] = JiuJiuXiaoHan_PrizeFrame_BK6_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[7] = JiuJiuXiaoHan_PrizeFrame_BK7_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[8] = JiuJiuXiaoHan_PrizeFrame_BK8_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[9] = JiuJiuXiaoHan_PrizeFrame_BK9_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[10] = JiuJiuXiaoHan_PrizeFrame_BK10_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[11] = JiuJiuXiaoHan_PrizeFrame_BK11_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[12] = JiuJiuXiaoHan_PrizeFrame_BK12_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[13] = JiuJiuXiaoHan_PrizeFrame_BK13_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[14] = JiuJiuXiaoHan_PrizeFrame_BK14_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[15] = JiuJiuXiaoHan_PrizeFrame_BK15_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[16] = JiuJiuXiaoHan_PrizeFrame_BK16_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[17] = JiuJiuXiaoHan_PrizeFrame_BK17_ItemName
	g_JiuJiuXiaoHan_Prize_ItemName[18] = JiuJiuXiaoHan_PrizeFrame_BK18_ItemName
	
	
end

function JiuJiuXiaoHan_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 201611301 ) then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			return
		end
		Open_JiuJiuXiaoHan( Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), 
							Get_XParam_INT(3), Get_XParam_INT(4), Get_XParam_INT(5),
							Get_XParam_INT(6), Get_XParam_INT(7), Get_XParam_INT(8))
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201611303 ) then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			return
		end
		--更新界面
		if this:IsVisible() then
			Open_JiuJiuXiaoHan( Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), 
							Get_XParam_INT(3), Get_XParam_INT(4), Get_XParam_INT(5),
							Get_XParam_INT(6), Get_XParam_INT(7), Get_XParam_INT(8))
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201611304 ) then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			return
		end
		--更新按钮状态
		JiuJiuXiaoHan_Update_PrizeButton( Get_XParam_INT(0), Get_XParam_INT(1) )
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201611302 ) then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			return
		end
		JiuJiuXiaoHan_OpenPrize()
		this:Show()
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		JiuJiuXiaoHan_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JiuJiuXiaoHan_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		
		if (arg0~= nil and -1 == tonumber(arg0)) then
			return
		end 
		JiuJiuXiaoHan_Refresh_Item()
	end
end

function Open_JiuJiuXiaoHan(TodayOnlineTime, TodayPoint, mymission, 
							mission_7, mission_8, mission_9, 
							prize_1, prize_2, activenum)
	local nTimeText = JiuJiuXiaoHan_GetTimeText(TodayOnlineTime)
	g_JiuJiuXiaoHan_ShowTime:SetText( ScriptGlobal_Format("#{JJXH_161122_6}", nTimeText) )
	--第一层
	if TodayOnlineTime >=  g_NeedOnlineTime_Third then
		g_JiuJiuXiaoHan_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[1])
		g_JiuJiuXiaoHan_Text[1]:SetText("#{JJXH_161122_12}")
		g_JiuJiuXiaoHan_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[2])
		g_JiuJiuXiaoHan_Text[2]:SetText("#{JJXH_161122_13}")
		g_JiuJiuXiaoHan_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[3])
		g_JiuJiuXiaoHan_Text[3]:SetText("#{JJXH_161122_14}")
	elseif TodayOnlineTime >=  g_NeedOnlineTime_Second then
		g_JiuJiuXiaoHan_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[1])
		g_JiuJiuXiaoHan_Text[1]:SetText("#{JJXH_161122_12}")
		g_JiuJiuXiaoHan_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[2])
		g_JiuJiuXiaoHan_Text[2]:SetText("#{JJXH_161122_13}")
		g_JiuJiuXiaoHan_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[3])
		g_JiuJiuXiaoHan_Text[3]:SetText("#{JJXH_161122_17}")
	elseif TodayOnlineTime >=  g_NeedOnlineTime_First then
		g_JiuJiuXiaoHan_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[1])
		g_JiuJiuXiaoHan_Text[1]:SetText("#{JJXH_161122_12}")
		g_JiuJiuXiaoHan_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[2])
		g_JiuJiuXiaoHan_Text[2]:SetText("#{JJXH_161122_16}")
		g_JiuJiuXiaoHan_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[3])
		g_JiuJiuXiaoHan_Text[3]:SetText("#{JJXH_161122_17}")
	else
		g_JiuJiuXiaoHan_FrameImage[1]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[1])
		g_JiuJiuXiaoHan_Text[1]:SetText("#{JJXH_161122_15}")
		g_JiuJiuXiaoHan_FrameImage[2]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[2])
		g_JiuJiuXiaoHan_Text[2]:SetText("#{JJXH_161122_16}")
		g_JiuJiuXiaoHan_FrameImage[3]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[3])
		g_JiuJiuXiaoHan_Text[3]:SetText("#{JJXH_161122_17}")
	end
	--第二层
	if TodayPoint >= g_NeedPoint_Third then
		g_JiuJiuXiaoHan_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[4])
		g_JiuJiuXiaoHan_Text[4]:SetText("#{JJXH_161122_18}")
		g_JiuJiuXiaoHan_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[5])
		g_JiuJiuXiaoHan_Text[5]:SetText("#{JJXH_161122_19}")
		g_JiuJiuXiaoHan_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[6])
		g_JiuJiuXiaoHan_Text[6]:SetText("#{JJXH_161122_20}")
	elseif TodayPoint >=  g_NeedPoint_Second then
		g_JiuJiuXiaoHan_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[4])
		g_JiuJiuXiaoHan_Text[4]:SetText("#{JJXH_161122_18}")
		g_JiuJiuXiaoHan_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[5])
		g_JiuJiuXiaoHan_Text[5]:SetText("#{JJXH_161122_19}")
		g_JiuJiuXiaoHan_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[6])
		g_JiuJiuXiaoHan_Text[6]:SetText( ScriptGlobal_Format("#{JJXH_161122_23}", TodayPoint) )
	elseif TodayPoint >=  g_NeedPoint_First then
		g_JiuJiuXiaoHan_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[4])
		g_JiuJiuXiaoHan_Text[4]:SetText("#{JJXH_161122_18}")
		g_JiuJiuXiaoHan_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[5])
		g_JiuJiuXiaoHan_Text[5]:SetText( ScriptGlobal_Format("#{JJXH_161122_22}", TodayPoint) )
		g_JiuJiuXiaoHan_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[6])
		g_JiuJiuXiaoHan_Text[6]:SetText( ScriptGlobal_Format("#{JJXH_161122_23}", TodayPoint) )
	else
		g_JiuJiuXiaoHan_FrameImage[4]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[4])
		g_JiuJiuXiaoHan_Text[4]:SetText( ScriptGlobal_Format("#{JJXH_161122_21}", TodayPoint) )
		g_JiuJiuXiaoHan_FrameImage[5]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[5])
		g_JiuJiuXiaoHan_Text[5]:SetText( ScriptGlobal_Format("#{JJXH_161122_22}", TodayPoint) )
		g_JiuJiuXiaoHan_FrameImage[6]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[6])
		g_JiuJiuXiaoHan_Text[6]:SetText( ScriptGlobal_Format("#{JJXH_161122_23}", TodayPoint) )
	end
	--第三层
	if mission_7 == 1 then
		g_JiuJiuXiaoHan_FrameImage[7]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[7])
		g_JiuJiuXiaoHan_Text[7]:SetText("#{JJXH_161122_109}")
	else
		g_JiuJiuXiaoHan_FrameImage[7]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[7])
		g_JiuJiuXiaoHan_Text[7]:SetText("#{JJXH_161122_113}")
	end
	if mission_8 == 1 then
		g_JiuJiuXiaoHan_FrameImage[8]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[8])
		g_JiuJiuXiaoHan_Text[8]:SetText("#{JJXH_161122_109}")
	else
		g_JiuJiuXiaoHan_FrameImage[8]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[8])
		g_JiuJiuXiaoHan_Text[8]:SetText("#{JJXH_161122_114}")
	end
	if mission_9 == 1 then
		g_JiuJiuXiaoHan_FrameImage[9]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Active[9])
		g_JiuJiuXiaoHan_Text[9]:SetText("#{JJXH_161122_109}")
	else
		g_JiuJiuXiaoHan_FrameImage[9]:SetProperty("Image", g_JiuJiuXiaoHan_Image_Inactive[9])
		g_JiuJiuXiaoHan_Text[9]:SetText("#{JJXH_161122_115}")
	end
	
	for i=7,9 do
		g_JiuJiuXiaoHan_Animate[i]:Hide()
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
		g_JiuJiuXiaoHan_Text[mymission]:SetText(g_ThirdLayerText[mymission])
		g_JiuJiuXiaoHan_Animate[mymission]:Show()
	end
	
	--按钮状态
	JiuJiuXiaoHan_Update_PrizeButton(prize_1, prize_2)
	
	JiuJiuXiaoHan_HideAllChannel()
	JiuJiuXiaoHan_Frame_Client:Show()
	JiuJiuXiaoHan_Frame_Fenye1:SetCheck(1)
	JiuJiuXiaoHan_Frame_Fenye2:SetCheck(0)
	--JiuJiuXiaoHan_Frame_Fenye3:SetCheck(0)
	
end

function JiuJiuXiaoHan_Update_PrizeButton(PrizeButton_1, PrizeButton_2)
	if PrizeButton_1 == 0 then
		g_JiuJiuXiaoHan_PrizeButton[1]:Enable()
	elseif PrizeButton_1 == 1 then
		g_JiuJiuXiaoHan_PrizeButton[1]:Disable()
	end
	
	if PrizeButton_2 == 0 then
		g_JiuJiuXiaoHan_PrizeButton[2]:Enable()
	elseif PrizeButton_2 == 1 then
		g_JiuJiuXiaoHan_PrizeButton[2]:Disable()
	end
end

function JiuJiuXiaoHan_PrizeButton_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetPrize")  
		Set_XSCRIPT_ScriptID(892394)
		Set_XSCRIPT_Parameter(0,tonumber(nIndex))
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function JiuJiuXiaoHan_ResetPos()
	JiuJiuXiaoHan_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	JiuJiuXiaoHan_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function JiuJiuXiaoHan_OnHide()
	this:Hide();
end

function JiuJiuXiaoHan_OpenRuleLink()
	PushEvent("OPEN_JIUJIUXIAOHAN_README")
end

function JiuJiuXiaoHan_GetTimeText(TodayOnlineTime)
	local nHour = math.floor(TodayOnlineTime/60)
	local nMinute = math.mod(TodayOnlineTime, 60)
	if nHour > 0 then
		return nHour.."小时"..nMinute.."分"
	else
		return nMinute.."分"
	end
end

function JiuJiuXiaoHan_OnFenYeClick(nIndex)
	local curDay = tonumber(DataPool:GetServerDayTime())
	local IsFinish = 0
	if curDay > g_JiuJiuXiaoHan_EndTime or curDay < g_JiuJiuXiaoHan_StartTime then
		IsFinish = 1
	end
	
	if nIndex == 1 then
		if IsFinish > 0 then 
			PushDebugMessage("#{JJXH_161122_142}")
			JiuJiuXiaoHan_Frame_Fenye1:SetCheck(0)
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")  
			Set_XSCRIPT_ScriptID(892394) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif nIndex == 2 then
		JiuJiuXiaoHan_OpenPrize()
	elseif nIndex == 3 then
		-- if IsFinish > 0 then 
			-- PushDebugMessage("#{JJXH_161122_144}")
			-- --JiuJiuXiaoHan_Frame_Fenye3:SetCheck(0)
			-- return 
		-- end
		-- JiuJiuXiaoHan_OpenOtherClient()
	end
	
end

function JiuJiuXiaoHan_OpenPrize()
	--JiuJiuXiaoHan_PrizeFrame_Client1_Text:SetText( ScriptGlobal_Format("#{JJXH_161122_129}", 4 ) )
	--JiuJiuXiaoHan_PrizeFrame_Client2_Text:SetText( ScriptGlobal_Format("#{JJXH_161122_129}", 6 ) )
	--JiuJiuXiaoHan_PrizeFrame_Client3_Text:SetText( ScriptGlobal_Format("#{JJXH_161122_129}", 8 ) )
	JiuJiuXiaoHan_UpPageClick()
	for i = 1, table.getn(g_RewardList) do
		local theAction = DataPool:CreateActionItemForShow(g_RewardList[i].GiftItemID, g_RewardList[i].num)
		if theAction:GetID() ~= 0 then
			g_JiuJiuXiaoHan_Prize_Icon[i]:SetActionItem(theAction:GetID());
			g_JiuJiuXiaoHan_Prize_Icon[i]:Show();
		end
		local itemname = DataPool:Lua_GetItemNameByIndex(g_RewardList[i].GiftItemID)
		g_JiuJiuXiaoHan_Prize_ItemName[i]:SetText("#L"..itemname)
		g_JiuJiuXiaoHan_Prize_ItemMoney[i]:SetText(ScriptGlobal_Format("#{JJXH_161122_129}",  g_RewardList[i].need ))
	end

	
	JiuJiuXiaoHan_HideAllChannel()
	JiuJiuXiaoHan_Frame_PrizeClient:Show()
	JiuJiuXiaoHan_Frame_Fenye1:SetCheck(0)
	JiuJiuXiaoHan_Frame_Fenye2:SetCheck(1)
	--显示当前薄荷数
	local HaveIDcount = PlayerPackage:CountAvailableItemByIDTable(38005576) 
	JiuJiuXiaoHan_PrizeInfo2_Lace:SetText(ScriptGlobal_Format("#{JJXH_201207_16}", HaveIDcount))
	--JiuJiuXiaoHan_Frame_Fenye3:SetCheck(0)
	local iszhekouquan = Pneuma:GetMF(3376)
	if iszhekouquan == 1 then
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_Mask:Show()
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_BuyLimitNum:SetText(0)
		JiuJiuXiaoHan_PrizeFrame_BK18_SellOut:Show()
	else
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_Mask:Hide()
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_BuyLimitNum:SetText(1)
		JiuJiuXiaoHan_PrizeFrame_BK18_SellOut:Hide()
	end
end

function JiuJiuXiaoHan_ExchangePrize(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ExchangePrizeCheck")  
		Set_XSCRIPT_ScriptID(892394)
		Set_XSCRIPT_Parameter(0,tonumber(nIndex))
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function JiuJiuXiaoHan_HideAllChannel()
	JiuJiuXiaoHan_Frame_PrizeClient:Hide()
	JiuJiuXiaoHan_Frame_Client:Hide()
	--JiuJiuXiaoHan_Frame_OtherClient:Hide()
end

function JiuJiuXiaoHan_OpenOtherClient()
	--JiuJiuXiaoHan_HideAllChannel()
	--JiuJiuXiaoHan_Frame_OtherClient:Show()
	--JiuJiuXiaoHan_Frame_Fenye1:SetCheck(0)
	--JiuJiuXiaoHan_Frame_Fenye2:SetCheck(0)
	--JiuJiuXiaoHan_Frame_Fenye3:SetCheck(1)
end

function JiuJiuXiaoHan_UpPageClick()
	g_NowPrizePageIndex = 1
	JiuJiuXiaoHan_PrizeFrame_Client1:Show()
	JiuJiuXiaoHan_PrizeFrame_Client2:Hide()
	JiuJiuXiaoHan_UpPage:Disable()
	JiuJiuXiaoHan_DownPage:Enable()
	JiuJiuXiaoHan_CurrentlyPage:SetText(ScriptGlobal_Format("#{JJXH_201207_18}", g_NowPrizePageIndex, 2))
end

function JiuJiuXiaoHan_DownPageClick()
	g_NowPrizePageIndex = 2
	JiuJiuXiaoHan_PrizeFrame_Client1:Hide()
	JiuJiuXiaoHan_PrizeFrame_Client2:Show()
	JiuJiuXiaoHan_UpPage:Enable()
	JiuJiuXiaoHan_DownPage:Disable()
	JiuJiuXiaoHan_CurrentlyPage:SetText(ScriptGlobal_Format("#{JJXH_201207_18}", g_NowPrizePageIndex, 2))
end

function JiuJiuXiaoHan_HelpClick()
	PushEvent("CCSHOP_HELP", 126)
end

function JiuJiuXiaoHan_Refresh_Item()

	local HaveIDcount = PlayerPackage:CountAvailableItemByIDTable(38005576) 
	JiuJiuXiaoHan_PrizeInfo2_Lace:SetText(ScriptGlobal_Format("#{JJXH_201207_16}", HaveIDcount))
	local iszhekouquan = Pneuma:GetMF(3376)
	if iszhekouquan == 1 then
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_Mask:Show()
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_BuyLimitNum:SetText(0)
		JiuJiuXiaoHan_PrizeFrame_BK18_SellOut:Show()
	else
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_Mask:Hide()
		JiuJiuXiaoHan_PrizeFrame_BK18_Icon_BuyLimitNum:SetText(1)
		JiuJiuXiaoHan_PrizeFrame_BK18_SellOut:Hide()
	end
	
end
