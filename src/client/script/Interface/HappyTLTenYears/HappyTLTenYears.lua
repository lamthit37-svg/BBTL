--******************************************************************************
-- 天龙十载庆生图界面 by 宋旭阳
--******************************************************************************
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_HappyTLTenYears_FrameImage = {}
local g_HappyTLTenYears_Text = {}
local g_HappyTLTenYears_Animate = {}
local g_HappyTLTenYears_PrizeButton = {}
local g_HappyTLTenYears_ShowTime
local g_HappyTLTenYears_Prize_Icon = {}
local g_HappyTLTenYears_Prize_Button = {}

local g_HappyTLTenYears_StartTime = 0
local g_HappyTLTenYears_EndTime = 0
local g_HappyTLTenYears_UIEndTime = 0

--时间单位 minute
local g_NeedOnlineTime_First = 30
local g_NeedOnlineTime_Second = 60
local g_NeedOnlineTime_Third = 120

local g_NeedPoint_First = 50
local g_NeedPoint_Second = 150
local g_NeedPoint_Third = 300

local g_RewardList = {
	{GiftItemID = 39921213, num = 1, need = 4,},
	{GiftItemID = 39921234, num = 1, need = 4,},
	{GiftItemID = 39921109, num = 1, need = 4,},
	{GiftItemID = 39921130, num = 1, need = 4,},
	{GiftItemID = 39921230, num = 1, need = 6,},
	{GiftItemID = 39921231, num = 1, need = 6,},
	{GiftItemID = 39921232, num = 1, need = 6,},
	{GiftItemID = 39921233, num = 1, need = 6,},
	{GiftItemID = 39920397, num = 1, need = 6,},
	{GiftItemID = 39920396, num = 1, need = 6,},
	{GiftItemID = 39921224, num = 1, need = 6,},
	{GiftItemID = 39921225, num = 1, need = 6,},
	{GiftItemID = 39921226, num = 1, need = 8,},
	{GiftItemID = 39921227, num = 1, need = 8,},
	{GiftItemID = 39921228, num = 1, need = 8,},
	{GiftItemID = 39921229, num = 1, need = 8,},
}

local g_ThirdLayerText = {
	[7] = "#{TYQS_170424_32}",
	[8] = "#{TYQS_170424_33}",
	[9] = "#{TYQS_170424_34}",
	}

g_HappyTLTenYears_Image_Active = {
	[1] = "set:HappyTenYears01 image:HappyTenYears01_1",
	[2] = "set:HappyTenYears01 image:HappyTenYears01_2",
	[3] = "set:HappyTenYears01 image:HappyTenYears01_3",
	[4] = "set:HappyTenYears01 image:HappyTenYears01_4",
	[5] = "set:HappyTenYears01 image:HappyTenYears01_5",
	[6] = "set:HappyTenYears01 image:HappyTenYears01_6",
	[7] = "set:HappyTenYears01 image:HappyTenYears01_7",
	[8] = "set:HappyTenYears01 image:HappyTenYears01_8",
	[9] = "set:HappyTenYears01 image:HappyTenYears01_9",
}

g_HappyTLTenYears_Image_Inactive = {
	[1] = "set:HappyTenYears01 image:HappyTenYears01_10",
	[2] = "set:HappyTenYears01 image:HappyTenYears01_11",
	[3] = "set:HappyTenYears01 image:HappyTenYears01_12",
	[4] = "set:HappyTenYears02 image:HappyTenYears02_1",
	[5] = "set:HappyTenYears02 image:HappyTenYears02_2",
	[6] = "set:HappyTenYears02 image:HappyTenYears02_3",
	[7] = "set:HappyTenYears02 image:HappyTenYears02_4",
	[8] = "set:HappyTenYears02 image:HappyTenYears02_5",
	[9] = "set:HappyTenYears02 image:HappyTenYears02_6",
}

function HappyTLTenYears_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_HAPPYTLTENYEARS_EXCHANGEPRIZE")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function HappyTLTenYears_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition = HappyTLTenYears_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = HappyTLTenYears_Frame:GetProperty("UnifiedYPosition");
	
	g_HappyTLTenYears_FrameImage[1] = HappyTLTenYears_MainFrame_Clinet1_image
	g_HappyTLTenYears_FrameImage[2] = HappyTLTenYears_MainFrame_Clinet2_image
	g_HappyTLTenYears_FrameImage[3] = HappyTLTenYears_MainFrame_Clinet3_image
	g_HappyTLTenYears_FrameImage[4] = HappyTLTenYears_MainFrame_Clinet4_image
	g_HappyTLTenYears_FrameImage[5] = HappyTLTenYears_MainFrame_Clinet5_image
	g_HappyTLTenYears_FrameImage[6] = HappyTLTenYears_MainFrame_Clinet6_image
	g_HappyTLTenYears_FrameImage[7] = HappyTLTenYears_MainFrame_Clinet7_image
	g_HappyTLTenYears_FrameImage[8] = HappyTLTenYears_MainFrame_Clinet8_image
	g_HappyTLTenYears_FrameImage[9] = HappyTLTenYears_MainFrame_Clinet9_image
	
	g_HappyTLTenYears_Text[1] = HappyTLTenYears_MainFrame_Clinet1_text
	g_HappyTLTenYears_Text[2] = HappyTLTenYears_MainFrame_Clinet2_text
	g_HappyTLTenYears_Text[3] = HappyTLTenYears_MainFrame_Clinet3_text
	g_HappyTLTenYears_Text[4] = HappyTLTenYears_MainFrame_Clinet4_text
	g_HappyTLTenYears_Text[5] = HappyTLTenYears_MainFrame_Clinet5_text
	g_HappyTLTenYears_Text[6] = HappyTLTenYears_MainFrame_Clinet6_text
	g_HappyTLTenYears_Text[7] = HappyTLTenYears_MainFrame_Clinet7_text
	g_HappyTLTenYears_Text[8] = HappyTLTenYears_MainFrame_Clinet8_text
	g_HappyTLTenYears_Text[9] = HappyTLTenYears_MainFrame_Clinet9_text		
	
	g_HappyTLTenYears_Animate[7] = HappyTLTenYears_MainFrame_Clinet7_image_Animate
	g_HappyTLTenYears_Animate[8] = HappyTLTenYears_MainFrame_Clinet8_image_Animate
	g_HappyTLTenYears_Animate[9] = HappyTLTenYears_MainFrame_Clinet9_image_Animate
	
	g_HappyTLTenYears_PrizeButton[1] = HappyTLTenYears_Prize1
	g_HappyTLTenYears_PrizeButton[2] = HappyTLTenYears_Prize2
	
	g_HappyTLTenYears_ShowTime = HappyTLTenYears_IntroFrame_TextLace_text
	
	g_HappyTLTenYears_Prize_Icon[1] = HappyTLTenYears_PrizeFrame_BK1_Icon
	g_HappyTLTenYears_Prize_Icon[2] = HappyTLTenYears_PrizeFrame_BK2_Icon
	g_HappyTLTenYears_Prize_Icon[3] = HappyTLTenYears_PrizeFrame_BK3_Icon
	g_HappyTLTenYears_Prize_Icon[4] = HappyTLTenYears_PrizeFrame_BK4_Icon
	g_HappyTLTenYears_Prize_Icon[5] = HappyTLTenYears_PrizeFrame_BK5_Icon
	g_HappyTLTenYears_Prize_Icon[6] = HappyTLTenYears_PrizeFrame_BK6_Icon
	g_HappyTLTenYears_Prize_Icon[7] = HappyTLTenYears_PrizeFrame_BK7_Icon
	g_HappyTLTenYears_Prize_Icon[8] = HappyTLTenYears_PrizeFrame_BK8_Icon
	g_HappyTLTenYears_Prize_Icon[9] = HappyTLTenYears_PrizeFrame_BK9_Icon
	g_HappyTLTenYears_Prize_Icon[10] = HappyTLTenYears_PrizeFrame_BK10_Icon
	g_HappyTLTenYears_Prize_Icon[11] = HappyTLTenYears_PrizeFrame_BK11_Icon
	g_HappyTLTenYears_Prize_Icon[12] = HappyTLTenYears_PrizeFrame_BK12_Icon
	g_HappyTLTenYears_Prize_Icon[13] = HappyTLTenYears_PrizeFrame_BK13_Icon
	g_HappyTLTenYears_Prize_Icon[14] = HappyTLTenYears_PrizeFrame_BK14_Icon
	g_HappyTLTenYears_Prize_Icon[15] = HappyTLTenYears_PrizeFrame_BK15_Icon
	g_HappyTLTenYears_Prize_Icon[16] = HappyTLTenYears_PrizeFrame_BK16_Icon
	
	g_HappyTLTenYears_Prize_Button[1] = HappyTLTenYears_PrizeFrame_BK1_Button
	g_HappyTLTenYears_Prize_Button[2] = HappyTLTenYears_PrizeFrame_BK2_Button
	g_HappyTLTenYears_Prize_Button[3] = HappyTLTenYears_PrizeFrame_BK3_Button
	g_HappyTLTenYears_Prize_Button[4] = HappyTLTenYears_PrizeFrame_BK4_Button
	g_HappyTLTenYears_Prize_Button[5] = HappyTLTenYears_PrizeFrame_BK5_Button
	g_HappyTLTenYears_Prize_Button[6] = HappyTLTenYears_PrizeFrame_BK6_Button
	g_HappyTLTenYears_Prize_Button[7] = HappyTLTenYears_PrizeFrame_BK7_Button
	g_HappyTLTenYears_Prize_Button[8] = HappyTLTenYears_PrizeFrame_BK8_Button
	g_HappyTLTenYears_Prize_Button[9] = HappyTLTenYears_PrizeFrame_BK9_Button
	g_HappyTLTenYears_Prize_Button[10] = HappyTLTenYears_PrizeFrame_BK10_Button
	g_HappyTLTenYears_Prize_Button[11] = HappyTLTenYears_PrizeFrame_BK11_Button
	g_HappyTLTenYears_Prize_Button[12] = HappyTLTenYears_PrizeFrame_BK12_Button
	g_HappyTLTenYears_Prize_Button[13] = HappyTLTenYears_PrizeFrame_BK13_Button
	g_HappyTLTenYears_Prize_Button[14] = HappyTLTenYears_PrizeFrame_BK14_Button
	g_HappyTLTenYears_Prize_Button[15] = HappyTLTenYears_PrizeFrame_BK15_Button
	g_HappyTLTenYears_Prize_Button[16] = HappyTLTenYears_PrizeFrame_BK16_Button
end

function HappyTLTenYears_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 201704263 ) then
		Open_HappyTLTenYears( Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), 
							Get_XParam_INT(3), Get_XParam_INT(4), Get_XParam_INT(5),
							Get_XParam_INT(6), Get_XParam_INT(7), Get_XParam_INT(8))
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201704264 ) then
		--更新界面
		if this:IsVisible() then
			Open_HappyTLTenYears( Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), 
							Get_XParam_INT(3), Get_XParam_INT(4), Get_XParam_INT(5),
							Get_XParam_INT(6), Get_XParam_INT(7), Get_XParam_INT(8))
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201704265 ) then
		--更新按钮状态
		HappyTLTenYears_Update_PrizeButton( Get_XParam_INT(0), Get_XParam_INT(1) )
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 201704268) then
		--更新活动时间
		g_HappyTLTenYears_StartTime = Get_XParam_INT(0)
		g_HappyTLTenYears_EndTime = Get_XParam_INT(1)
		g_HappyTLTenYears_UIEndTime = Get_XParam_INT(2)
	elseif ( event == "OPEN_HAPPYTLTENYEARS_EXCHANGEPRIZE" ) then
		HappyTLTenYears_OpenPrize()
		this:Show()
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		HappyTLTenYears_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HappyTLTenYears_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end

function Open_HappyTLTenYears(TodayOnlineTime, TodayPoint, mymission, 
							mission_7, mission_8, mission_9, 
							prize_1, prize_2, activenum)
	local nTimeStart = HappyTLTenYears_GetTimestr(g_HappyTLTenYears_StartTime)
	local nTimeEnd = HappyTLTenYears_GetTimestr(g_HappyTLTenYears_EndTime)
	local nTimeUI = HappyTLTenYears_GetTimestr(g_HappyTLTenYears_UIEndTime)
	local nTimeText = HappyTLTenYears_GetTimeText(TodayOnlineTime)
	g_HappyTLTenYears_ShowTime:SetText( ScriptGlobal_Format("#{TYQS_170424_10}", nTimeStart, nTimeEnd, nTimeUI, nTimeText) )
	--第一层
	if TodayOnlineTime >=  g_NeedOnlineTime_Third then
		g_HappyTLTenYears_FrameImage[1]:SetProperty("Image", g_HappyTLTenYears_Image_Active[1])
		g_HappyTLTenYears_Text[1]:SetText("#{TYQS_170424_18}".."#{TYQS_170424_20}")
		g_HappyTLTenYears_FrameImage[2]:SetProperty("Image", g_HappyTLTenYears_Image_Active[2])
		g_HappyTLTenYears_Text[2]:SetText("#{TYQS_170424_18}".."#{TYQS_170424_21}")
		g_HappyTLTenYears_FrameImage[3]:SetProperty("Image", g_HappyTLTenYears_Image_Active[3])
		g_HappyTLTenYears_Text[3]:SetText("#{TYQS_170424_18}".."#{TYQS_170424_22}")
	elseif TodayOnlineTime >=  g_NeedOnlineTime_Second then
		g_HappyTLTenYears_FrameImage[1]:SetProperty("Image", g_HappyTLTenYears_Image_Active[1])
		g_HappyTLTenYears_Text[1]:SetText("#{TYQS_170424_18}".."#{TYQS_170424_20}")
		g_HappyTLTenYears_FrameImage[2]:SetProperty("Image", g_HappyTLTenYears_Image_Active[2])
		g_HappyTLTenYears_Text[2]:SetText("#{TYQS_170424_18}".."#{TYQS_170424_21}")
		g_HappyTLTenYears_FrameImage[3]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[3])
		g_HappyTLTenYears_Text[3]:SetText("#{TYQS_170424_19}".."#{TYQS_170424_22}")
	elseif TodayOnlineTime >=  g_NeedOnlineTime_First then
		g_HappyTLTenYears_FrameImage[1]:SetProperty("Image", g_HappyTLTenYears_Image_Active[1])
		g_HappyTLTenYears_Text[1]:SetText("#{TYQS_170424_18}".."#{TYQS_170424_20}")
		g_HappyTLTenYears_FrameImage[2]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[2])
		g_HappyTLTenYears_Text[2]:SetText("#{TYQS_170424_19}".."#{TYQS_170424_21}")
		g_HappyTLTenYears_FrameImage[3]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[3])
		g_HappyTLTenYears_Text[3]:SetText("#{TYQS_170424_19}".."#{TYQS_170424_22}")
	else
		g_HappyTLTenYears_FrameImage[1]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[1])
		g_HappyTLTenYears_Text[1]:SetText("#{TYQS_170424_19}".."#{TYQS_170424_20}")
		g_HappyTLTenYears_FrameImage[2]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[2])
		g_HappyTLTenYears_Text[2]:SetText("#{TYQS_170424_19}".."#{TYQS_170424_21}")
		g_HappyTLTenYears_FrameImage[3]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[3])
		g_HappyTLTenYears_Text[3]:SetText("#{TYQS_170424_19}".."#{TYQS_170424_22}")
	end
	--第二层
	if TodayPoint >= g_NeedPoint_Third then
		g_HappyTLTenYears_FrameImage[4]:SetProperty("Image", g_HappyTLTenYears_Image_Active[4])
		g_HappyTLTenYears_Text[4]:SetText( "#{TYQS_170424_18}"..ScriptGlobal_Format("#{TYQS_170424_26}", g_NeedPoint_First) )
		g_HappyTLTenYears_FrameImage[5]:SetProperty("Image", g_HappyTLTenYears_Image_Active[5])
		g_HappyTLTenYears_Text[5]:SetText( "#{TYQS_170424_18}"..ScriptGlobal_Format("#{TYQS_170424_27}", g_NeedPoint_Second) )
		g_HappyTLTenYears_FrameImage[6]:SetProperty("Image", g_HappyTLTenYears_Image_Active[6])
		g_HappyTLTenYears_Text[6]:SetText( "#{TYQS_170424_18}"..ScriptGlobal_Format("#{TYQS_170424_28}", g_NeedPoint_Third) )
	elseif TodayPoint >=  g_NeedPoint_Second then
		g_HappyTLTenYears_FrameImage[4]:SetProperty("Image", g_HappyTLTenYears_Image_Active[4])
		g_HappyTLTenYears_Text[4]:SetText( "#{TYQS_170424_18}"..ScriptGlobal_Format("#{TYQS_170424_26}", g_NeedPoint_First) )
		g_HappyTLTenYears_FrameImage[5]:SetProperty("Image", g_HappyTLTenYears_Image_Active[5])
		g_HappyTLTenYears_Text[5]:SetText( "#{TYQS_170424_18}"..ScriptGlobal_Format("#{TYQS_170424_27}", g_NeedPoint_Second) )
		g_HappyTLTenYears_FrameImage[6]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[6])
		g_HappyTLTenYears_Text[6]:SetText( "#{TYQS_170424_19}"..ScriptGlobal_Format("#{TYQS_170424_28}", TodayPoint) )
	elseif TodayPoint >=  g_NeedPoint_First then
		g_HappyTLTenYears_FrameImage[4]:SetProperty("Image", g_HappyTLTenYears_Image_Active[4])
		g_HappyTLTenYears_Text[4]:SetText( "#{TYQS_170424_18}"..ScriptGlobal_Format("#{TYQS_170424_26}", g_NeedPoint_First) )
		g_HappyTLTenYears_FrameImage[5]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[5])
		g_HappyTLTenYears_Text[5]:SetText( "#{TYQS_170424_19}"..ScriptGlobal_Format("#{TYQS_170424_27}", TodayPoint) )
		g_HappyTLTenYears_FrameImage[6]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[6])
		g_HappyTLTenYears_Text[6]:SetText( "#{TYQS_170424_19}"..ScriptGlobal_Format("#{TYQS_170424_28}", TodayPoint) )
	else
		g_HappyTLTenYears_FrameImage[4]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[4])
		g_HappyTLTenYears_Text[4]:SetText( "#{TYQS_170424_19}"..ScriptGlobal_Format("#{TYQS_170424_26}", TodayPoint) )
		g_HappyTLTenYears_FrameImage[5]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[5])
		g_HappyTLTenYears_Text[5]:SetText( "#{TYQS_170424_19}"..ScriptGlobal_Format("#{TYQS_170424_27}", TodayPoint) )
		g_HappyTLTenYears_FrameImage[6]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[6])
		g_HappyTLTenYears_Text[6]:SetText( "#{TYQS_170424_19}"..ScriptGlobal_Format("#{TYQS_170424_28}", TodayPoint) )
	end
	--第三层
	if mission_7 == 1 then
		g_HappyTLTenYears_FrameImage[7]:SetProperty("Image", g_HappyTLTenYears_Image_Active[7])
		g_HappyTLTenYears_Text[7]:SetText("#{TYQS_170424_38}")
	else
		g_HappyTLTenYears_FrameImage[7]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[7])
		g_HappyTLTenYears_Text[7]:SetText("#{TYQS_170424_35}")
	end
	if mission_8 == 1 then
		g_HappyTLTenYears_FrameImage[8]:SetProperty("Image", g_HappyTLTenYears_Image_Active[8])
		g_HappyTLTenYears_Text[8]:SetText("#{TYQS_170424_38}")
	else
		g_HappyTLTenYears_FrameImage[8]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[8])
		g_HappyTLTenYears_Text[8]:SetText("#{TYQS_170424_36}")
	end
	if mission_9 == 1 then
		g_HappyTLTenYears_FrameImage[9]:SetProperty("Image", g_HappyTLTenYears_Image_Active[9])
		g_HappyTLTenYears_Text[9]:SetText("#{TYQS_170424_38}")
	else
		g_HappyTLTenYears_FrameImage[9]:SetProperty("Image", g_HappyTLTenYears_Image_Inactive[9])
		g_HappyTLTenYears_Text[9]:SetText("#{TYQS_170424_37}")
	end
	
	for i=7,9 do
		g_HappyTLTenYears_Animate[i]:Hide()
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
		g_HappyTLTenYears_Text[mymission]:SetText(g_ThirdLayerText[mymission])
		g_HappyTLTenYears_Animate[mymission]:Show()
	end
	
	--按钮状态
	HappyTLTenYears_Update_PrizeButton(prize_1, prize_2)
	
	HappyTLTenYears_HideAllChannel()
	HappyTLTenYears_Frame_Client:Show()
	HappyTLTenYears_Frame_Fenye1:SetCheck(1)
	HappyTLTenYears_Frame_Fenye2:SetCheck(0)
	--HappyTLTenYears_Frame_Fenye3:SetCheck(0)
end

function HappyTLTenYears_Update_PrizeButton(PrizeButton_1, PrizeButton_2)
	if PrizeButton_1 == 0 then
		g_HappyTLTenYears_PrizeButton[1]:Enable()
	elseif PrizeButton_1 == 1 then
		g_HappyTLTenYears_PrizeButton[1]:Disable()
	end
	
	if PrizeButton_2 == 0 then
		g_HappyTLTenYears_PrizeButton[2]:Enable()
	elseif PrizeButton_2 == 1 then
		g_HappyTLTenYears_PrizeButton[2]:Disable()
	end
end

function HappyTLTenYears_PrizeButton_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetPrize")  
		Set_XSCRIPT_ScriptID(892454)
		Set_XSCRIPT_Parameter(0,tonumber(nIndex))
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function HappyTLTenYears_ResetPos()
	HappyTLTenYears_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	HappyTLTenYears_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function HappyTLTenYears_OnHide()
	this:Hide();
end

-- function HappyTLTenYears_OpenRuleLink()
	-- PushEvent("OPEN_HappyTLTenYears_README")
-- end

function HappyTLTenYears_GetTimeText(TodayOnlineTime)
	local nHour = math.floor(TodayOnlineTime/60)
	local nMinute = math.mod(TodayOnlineTime, 60)
	if nHour > 0 then
		return nHour.."#{TYQS_170424_12}"..nMinute.."#{TYQS_170424_13}"
	else
		return nMinute.."#{TYQS_170424_13}"
	end
end

function HappyTLTenYears_OnFenYeClick(nIndex)
	local curDay = tonumber(DataPool:GetServerDayTime())
	local IsFinish = 0
	if curDay > g_HappyTLTenYears_EndTime or curDay < g_HappyTLTenYears_StartTime then
		IsFinish = 1
	end
	
	if nIndex == 1 then
		if IsFinish > 0 then 
			PushDebugMessage("#{TYQS_170502_103}")
			HappyTLTenYears_Frame_Fenye1:SetCheck(0)
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenWindowRequest")  
			Set_XSCRIPT_ScriptID(892454) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif nIndex == 2 then
		HappyTLTenYears_OpenPrize()
	-- elseif nIndex == 3 then
		-- if IsFinish > 0 then 
			-- PushDebugMessage("#{JJXH_161122_144}")
			-- HappyTLTenYears_Frame_Fenye3:SetCheck(0)
			-- return 
		-- end
		-- HappyTLTenYears_OpenOtherClient()
	end
	
end

function HappyTLTenYears_OpenPrize()
	local nTimeStart = HappyTLTenYears_GetTimestr(g_HappyTLTenYears_StartTime)
	local nTimeEnd = HappyTLTenYears_GetTimestr(g_HappyTLTenYears_EndTime)
	local nTimeUI = HappyTLTenYears_GetTimestr(g_HappyTLTenYears_UIEndTime)
	HappyTLTenYears_PrizeInfo_Lace_text:SetText( ScriptGlobal_Format("#{TYQS_170424_82}", nTimeStart, nTimeEnd, nTimeUI) )
	
	HappyTLTenYears_PrizeFrame_Client1_Text:SetText( ScriptGlobal_Format("#{TYQS_170424_85}", 4 ) )
	
	HappyTLTenYears_PrizeFrame_Client2_Text:SetText( ScriptGlobal_Format("#{TYQS_170424_85}", 6 ) )
	HappyTLTenYears_PrizeFrame_Client3_Text:SetText( ScriptGlobal_Format("#{TYQS_170424_85}", 8 ) )
	
	for i = 1, table.getn(g_RewardList) do
		local theAction = DataPool:CreateActionItemForShow(g_RewardList[i].GiftItemID, g_RewardList[i].num)
		if theAction:GetID() ~= 0 then
			g_HappyTLTenYears_Prize_Icon[i]:SetActionItem(theAction:GetID());
			g_HappyTLTenYears_Prize_Icon[i]:Show();
		end
		--local itemname = DataPool:Lua_GetItemNameByIndex(g_RewardList[i].GiftItemID)
		local tooltip = ScriptGlobal_Format("#{TYQS_170424_84}", g_RewardList[i].need)
		g_HappyTLTenYears_Prize_Button[i]:SetToolTip(tooltip)
	end

	
	HappyTLTenYears_HideAllChannel()
	HappyTLTenYears_Frame_PrizeClient:Show()
	HappyTLTenYears_Frame_Fenye1:SetCheck(0)
	HappyTLTenYears_Frame_Fenye2:SetCheck(1)
	--HappyTLTenYears_Frame_Fenye3:SetCheck(0)
end

function HappyTLTenYears_ExchangePrize(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ExchangePrizeCheck")  
		Set_XSCRIPT_ScriptID(892454)
		Set_XSCRIPT_Parameter(0,tonumber(nIndex))
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function HappyTLTenYears_HideAllChannel()
	HappyTLTenYears_Frame_PrizeClient:Hide()
	HappyTLTenYears_Frame_Client:Hide()
	--HappyTLTenYears_Frame_OtherClient:Hide()
end

-- function HappyTLTenYears_OpenOtherClient()
	-- HappyTLTenYears_HideAllChannel()
	-- HappyTLTenYears_Frame_OtherClient:Show()
	-- HappyTLTenYears_Frame_Fenye1:SetCheck(0)
	-- HappyTLTenYears_Frame_Fenye2:SetCheck(0)
	-- HappyTLTenYears_Frame_Fenye3:SetCheck(1)
-- end

function HappyTLTenYears_GetTimestr(nTime)
	local str =""
	if nTime > 0 then
		local nYear = math.floor(nTime/10000)
		local nMonth =  math.mod(math.floor(nTime/100), 100)
		local nDay = math.mod(nTime, 100)
		str = nYear.."年"..nMonth.."月"..nDay.."日"
	end
	return str
end