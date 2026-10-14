local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
										}

local g_MonthlySignSP_DateButton = {};
local g_MonthlySignSP_TodayImage = {};
local g_MonthlySignSP_HideButton = {};
local g_MonthlySignSP_PrizeItemList = {};
local g_MonthlySignSP_Month = {};
local g_MonthlySignSP_Mark = {};
local g_MonthlySignSP_Figure = {};
local g_MonthlySignSP_GiftSign = {};

local g_MonthlySignSP_curDay = 0;
local g_MonthlySignSP_curMonth = 0;
local g_MonthlySignSP_daycount = 0;
local g_MonthlySignSP_SignFlagData = 0;
local g_MonthlySignSP_SignCount = 0;
local g_MonthlySignSP_curDayButton = 1;
local g_MonthlySignSP_GetPrizeFlag={};


local g_MonthlySignSP_ItemInfo = {};
g_MonthlySignSP_ItemInfo[1] = 	{{awardid = 38000378, num = 1},{awardid = 39920156, num = 1}}
g_MonthlySignSP_ItemInfo[2] = 	{{awardid = 39920394, num = 1},{awardid = 38000992, num = 1},{awardid = 20700055, num = 25},{awardid = 38002051, num = 20}}
g_MonthlySignSP_ItemInfo[3] = 	{{awardid = 38000380, num = 1},{awardid = 38000571, num = 1},{awardid = 20700055, num = 25}}
g_MonthlySignSP_ItemInfo[4] = 	{{awardid = 30008130, num = 1},{awardid = 38000443, num = 2},{awardid = 20700055, num = 50},{awardid = 20700063, num = 50}}
g_MonthlySignSP_ItemInfo[5] = 	{{awardid = 39920397, num = 1},{awardid = 39920396, num = 1},{awardid = 38000945, num = 3}}

local g_MonthlySignSP_ItemInfo_Feb = {};
g_MonthlySignSP_ItemInfo_Feb[1] = 	{{awardid = 38000378, num = 1},{awardid = 39920156, num = 1}}
g_MonthlySignSP_ItemInfo_Feb[2] = 	{{awardid = 39920394, num = 1},{awardid = 38000992, num = 1},{awardid = 20700055, num = 25},{awardid = 38002051, num = 20}}
g_MonthlySignSP_ItemInfo_Feb[3] = 	{{awardid = 38000380, num = 1},{awardid = 38000571, num = 1},{awardid = 20700055, num = 25}}
g_MonthlySignSP_ItemInfo_Feb[4] = 	{{awardid = 30008130, num = 1},{awardid = 38000443, num = 2},{awardid = 20700055, num = 50},{awardid = 20700063, num = 50}}
g_MonthlySignSP_ItemInfo_Feb[5] = 	{{awardid = 39920397, num = 1},{awardid = 39920396, num = 1},{awardid = 38000945, num = 3}}

local g_MonthlySignSP_ItemInfo_ZN = {};
g_MonthlySignSP_ItemInfo_ZN[1] = 	{{awardid = 38000378, num = 1},{awardid = 39920085, num = 2}}
g_MonthlySignSP_ItemInfo_ZN[2] = 	{{awardid = 39921313, num = 1},{awardid = 38000992, num = 1},{awardid = 20700055, num = 25},{awardid = 38002051, num = 20}}
g_MonthlySignSP_ItemInfo_ZN[3] = 	{{awardid = 38000380, num = 1},{awardid = 38000571, num = 1},{awardid = 20700055, num = 25}}
g_MonthlySignSP_ItemInfo_ZN[4] = 	{{awardid = 30008130, num = 1},{awardid = 38000443, num = 2},{awardid = 20700055, num = 50},{awardid = 20700063, num = 50}}
g_MonthlySignSP_ItemInfo_ZN[5] = 	{{awardid = 39920397, num = 1},{awardid = 39920396, num = 1},{awardid = 38000945, num = 3}}


local g_MonthlySignSP_ItemInfo_SQ = {};
g_MonthlySignSP_ItemInfo_SQ[1] = 	{{awardid = 38000378, num = 1},{awardid = 39920156, num = 1}}
g_MonthlySignSP_ItemInfo_SQ[2] = 	{{awardid = 39920394, num = 1},{awardid = 38000992, num = 1},{awardid = 20700055, num = 25},{awardid = 38002051, num = 10}}
g_MonthlySignSP_ItemInfo_SQ[3] = 	{{awardid = 38000380, num = 1},{awardid = 38000571, num = 1},{awardid = 20700055, num = 25},{awardid = 38002068, num = 1}}
g_MonthlySignSP_ItemInfo_SQ[4] = 	{{awardid = 30008130, num = 1},{awardid = 38000443, num = 2},{awardid = 20700055, num = 50},{awardid = 38002047, num = 3}}
g_MonthlySignSP_ItemInfo_SQ[5] = 	{{awardid = 39920397, num = 1},{awardid = 39920396, num = 1},{awardid = 38000945, num = 3}}

local g_MonthlySignSP_SignDay = { 5, 10, 15, 20, 25}

local CreateDate = 904691712			-- 2013年08月22日08:00:00

local nCharCreateDate = 0;
local g_bIsNewServerGiftsForLevelUpValid = 0

function MonthlySignSP_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
	this:RegisterEvent("OPEN_MONTHLYSIGN_SP")

end

function MonthlySignSP_OnEvent(event)
	--MonthlySignSP_Button5tips : Hide()
	if event == "UI_COMMAND" and tonumber( arg0 ) == 89110604 then
		if ( Get_XParam_INT_Count() < 9 ) then
			return
		end
		g_MonthlySignSP_curDay = tonumber(Get_XParam_INT(0))
		g_MonthlySignSP_curMonth = tonumber(Get_XParam_INT(1))
		g_MonthlySignSP_daycount = tonumber(Get_XParam_INT(2))
		g_MonthlySignSP_SignFlagData = tonumber(Get_XParam_INT(3))
		for i = 1, 5 do
			g_MonthlySignSP_GetPrizeFlag[i] = tonumber(Get_XParam_INT(3+i))
		end
		MonthlySignSP_OnShown()
		DataPool:Lua_SetIsInSpringFlag( 1 )
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 89110605 then
		if ( Get_XParam_INT_Count() < 1 ) then
			return
		end
		g_MonthlySignSP_SignFlagData = tonumber(Get_XParam_INT(0))
		MonthlySignSP_OnShown()
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 89110606 then
		if ( Get_XParam_INT_Count() < 5 ) then
			return
		end
		for i = 1, 5 do
			g_MonthlySignSP_GetPrizeFlag[i] = tonumber(Get_XParam_INT(i-1))
		end
		MonthlySignSP_OnShown()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20170302 then
		--DataPool:Lua_SetDailySeckillFlag( Get_XParam_INT( 0 ))
		--MonthlySignSP_Refresh_ButtonTips()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2017122501 then
		--DataPool:Lua_SetDailySeckillFlag( Get_XParam_INT( 0 ))
		--MonthlySignSP_Refresh_ButtonTips()

	elseif( event == "ADJEST_UI_POS" ) then
		MonthlySignSP_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MonthlySignSP_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		if this:IsVisible() then
			MonthlySignSP_OnShown()
		end
	elseif event == "OPEN_MONTHLYSIGN_SP" then
		if(tonumber(arg0) == 0) then
			MonthlySignSP_ResetPos()
		else
			MonthlySignSP_SetLastPos()
		end
	--	this:Show()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	--	MonthlySignSP_OnShown()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
	end
end
function MonthlySignSP_OnLoad()
	g_MonthlySignSP_Month[1] = "set:Sign image:Signmonth_1";
	g_MonthlySignSP_Month[2] = "set:Sign image:Signmonth_2";
	g_MonthlySignSP_Month[3] = "set:Sign image:Signmonth_3";
	g_MonthlySignSP_Month[4] = "set:Sign image:Signmonth_4";
	g_MonthlySignSP_Month[5] = "set:Sign image:Signmonth_5";
	g_MonthlySignSP_Month[6] = "set:Sign image:Signmonth_6";
	g_MonthlySignSP_Month[7] = "set:Sign image:Signmonth_7";
	g_MonthlySignSP_Month[8] = "set:Sign image:Signmonth_8";
	g_MonthlySignSP_Month[9] = "set:Sign image:Signmonth_9";
	g_MonthlySignSP_Month[10] = "set:Sign image:Signmonth_10";
	g_MonthlySignSP_Month[11] = "set:Sign image:Signmonth_11";
	g_MonthlySignSP_Month[12] = "set:Sign image:Signmonth_12";

	g_MonthlySignSP_Mark[1] = MonthlySignSP_Date_1_Mark;
	g_MonthlySignSP_Mark[2] = MonthlySignSP_Date_2_Mark;
	g_MonthlySignSP_Mark[3] = MonthlySignSP_Date_3_Mark;
	g_MonthlySignSP_Mark[4] = MonthlySignSP_Date_4_Mark;
	g_MonthlySignSP_Mark[5] = MonthlySignSP_Date_5_Mark;
	g_MonthlySignSP_Mark[6] = MonthlySignSP_Date_6_Mark;
	g_MonthlySignSP_Mark[7] = MonthlySignSP_Date_7_Mark;
	g_MonthlySignSP_Mark[8] = MonthlySignSP_Date_8_Mark;
	g_MonthlySignSP_Mark[9] = MonthlySignSP_Date_9_Mark;
	g_MonthlySignSP_Mark[10] = MonthlySignSP_Date_10_Mark;
	g_MonthlySignSP_Mark[11] = MonthlySignSP_Date_11_Mark;
	g_MonthlySignSP_Mark[12] = MonthlySignSP_Date_12_Mark;
	g_MonthlySignSP_Mark[13] = MonthlySignSP_Date_13_Mark;
	g_MonthlySignSP_Mark[14] = MonthlySignSP_Date_14_Mark;
	g_MonthlySignSP_Mark[15] = MonthlySignSP_Date_15_Mark;
	g_MonthlySignSP_Mark[16] = MonthlySignSP_Date_16_Mark;
	g_MonthlySignSP_Mark[17] = MonthlySignSP_Date_17_Mark;
	g_MonthlySignSP_Mark[18] = MonthlySignSP_Date_18_Mark;
	g_MonthlySignSP_Mark[19] = MonthlySignSP_Date_19_Mark;
	g_MonthlySignSP_Mark[20] = MonthlySignSP_Date_20_Mark;
	g_MonthlySignSP_Mark[21] = MonthlySignSP_Date_21_Mark;
	g_MonthlySignSP_Mark[22] = MonthlySignSP_Date_22_Mark;
	g_MonthlySignSP_Mark[23] = MonthlySignSP_Date_23_Mark;
	g_MonthlySignSP_Mark[24] = MonthlySignSP_Date_24_Mark;
	g_MonthlySignSP_Mark[25] = MonthlySignSP_Date_25_Mark;
	g_MonthlySignSP_Mark[26] = MonthlySignSP_Date_26_Mark;
	g_MonthlySignSP_Mark[27] = MonthlySignSP_Date_27_Mark;
	g_MonthlySignSP_Mark[28] = MonthlySignSP_Date_28_Mark;
	g_MonthlySignSP_Mark[29] = MonthlySignSP_Date_29_Mark;
	g_MonthlySignSP_Mark[30] = MonthlySignSP_Date_30_Mark;
	g_MonthlySignSP_Mark[31] = MonthlySignSP_Date_31_Mark;

	g_MonthlySignSP_DateButton[1] = MonthlySignSP_Date_1_ReSign;
	g_MonthlySignSP_DateButton[2] = MonthlySignSP_Date_2_ReSign;
	g_MonthlySignSP_DateButton[3] = MonthlySignSP_Date_3_ReSign;
	g_MonthlySignSP_DateButton[4] = MonthlySignSP_Date_4_ReSign;
	g_MonthlySignSP_DateButton[5] = MonthlySignSP_Date_5_ReSign;
	g_MonthlySignSP_DateButton[6] = MonthlySignSP_Date_6_ReSign;
	g_MonthlySignSP_DateButton[7] = MonthlySignSP_Date_7_ReSign;
	g_MonthlySignSP_DateButton[8] = MonthlySignSP_Date_8_ReSign;
	g_MonthlySignSP_DateButton[9] = MonthlySignSP_Date_9_ReSign;
	g_MonthlySignSP_DateButton[10] = MonthlySignSP_Date_10_ReSign;
	g_MonthlySignSP_DateButton[11] = MonthlySignSP_Date_11_ReSign;
	g_MonthlySignSP_DateButton[12] = MonthlySignSP_Date_12_ReSign;
	g_MonthlySignSP_DateButton[13] = MonthlySignSP_Date_13_ReSign;
	g_MonthlySignSP_DateButton[14] = MonthlySignSP_Date_14_ReSign;
	g_MonthlySignSP_DateButton[15] = MonthlySignSP_Date_15_ReSign;
	g_MonthlySignSP_DateButton[16] = MonthlySignSP_Date_16_ReSign;
	g_MonthlySignSP_DateButton[17] = MonthlySignSP_Date_17_ReSign;
	g_MonthlySignSP_DateButton[18] = MonthlySignSP_Date_18_ReSign;
	g_MonthlySignSP_DateButton[19] = MonthlySignSP_Date_19_ReSign;
	g_MonthlySignSP_DateButton[20] = MonthlySignSP_Date_20_ReSign;
	g_MonthlySignSP_DateButton[21] = MonthlySignSP_Date_21_ReSign;
	g_MonthlySignSP_DateButton[22] = MonthlySignSP_Date_22_ReSign;
	g_MonthlySignSP_DateButton[23] = MonthlySignSP_Date_23_ReSign;
	g_MonthlySignSP_DateButton[24] = MonthlySignSP_Date_24_ReSign;
	g_MonthlySignSP_DateButton[25] = MonthlySignSP_Date_25_ReSign;
	g_MonthlySignSP_DateButton[26] = MonthlySignSP_Date_26_ReSign;
	g_MonthlySignSP_DateButton[27] = MonthlySignSP_Date_27_ReSign;
	g_MonthlySignSP_DateButton[28] = MonthlySignSP_Date_28_ReSign;
	g_MonthlySignSP_DateButton[29] = MonthlySignSP_Date_29_ReSign;
	g_MonthlySignSP_DateButton[30] = MonthlySignSP_Date_30_ReSign;
	g_MonthlySignSP_DateButton[31] = MonthlySignSP_Date_31_ReSign;

	g_MonthlySignSP_TodayImage[1] = MonthlySignSP_Date_1_Today;
	g_MonthlySignSP_TodayImage[2] = MonthlySignSP_Date_2_Today;
	g_MonthlySignSP_TodayImage[3] = MonthlySignSP_Date_3_Today;
	g_MonthlySignSP_TodayImage[4] = MonthlySignSP_Date_4_Today;
	g_MonthlySignSP_TodayImage[5] = MonthlySignSP_Date_5_Today;
	g_MonthlySignSP_TodayImage[6] = MonthlySignSP_Date_6_Today;
	g_MonthlySignSP_TodayImage[7] = MonthlySignSP_Date_7_Today;
	g_MonthlySignSP_TodayImage[8] = MonthlySignSP_Date_8_Today;
	g_MonthlySignSP_TodayImage[9] = MonthlySignSP_Date_9_Today;
	g_MonthlySignSP_TodayImage[10] = MonthlySignSP_Date_10_Today;
	g_MonthlySignSP_TodayImage[11] = MonthlySignSP_Date_11_Today;
	g_MonthlySignSP_TodayImage[12] = MonthlySignSP_Date_12_Today;
	g_MonthlySignSP_TodayImage[13] = MonthlySignSP_Date_13_Today;
	g_MonthlySignSP_TodayImage[14] = MonthlySignSP_Date_14_Today;
	g_MonthlySignSP_TodayImage[15] = MonthlySignSP_Date_15_Today;
	g_MonthlySignSP_TodayImage[16] = MonthlySignSP_Date_16_Today;
	g_MonthlySignSP_TodayImage[17] = MonthlySignSP_Date_17_Today;
	g_MonthlySignSP_TodayImage[18] = MonthlySignSP_Date_18_Today;
	g_MonthlySignSP_TodayImage[19] = MonthlySignSP_Date_19_Today;
	g_MonthlySignSP_TodayImage[20] = MonthlySignSP_Date_20_Today;
	g_MonthlySignSP_TodayImage[21] = MonthlySignSP_Date_21_Today;
	g_MonthlySignSP_TodayImage[22] = MonthlySignSP_Date_22_Today;
	g_MonthlySignSP_TodayImage[23] = MonthlySignSP_Date_23_Today;
	g_MonthlySignSP_TodayImage[24] = MonthlySignSP_Date_24_Today;
	g_MonthlySignSP_TodayImage[25] = MonthlySignSP_Date_25_Today;
	g_MonthlySignSP_TodayImage[26] = MonthlySignSP_Date_26_Today;
	g_MonthlySignSP_TodayImage[27] = MonthlySignSP_Date_27_Today;
	g_MonthlySignSP_TodayImage[28] = MonthlySignSP_Date_28_Today;
	g_MonthlySignSP_TodayImage[29] = MonthlySignSP_Date_29_Today;
	g_MonthlySignSP_TodayImage[30] = MonthlySignSP_Date_30_Today;
	g_MonthlySignSP_TodayImage[31] = MonthlySignSP_Date_31_Today;

	g_MonthlySignSP_HideButton[29] = MonthlySignSP_Date_29;
	g_MonthlySignSP_HideButton[30] = MonthlySignSP_Date_30;
	g_MonthlySignSP_HideButton[31] = MonthlySignSP_Date_31;

	g_MonthlySignSP_Figure[0] = "set:Sign image:Signgreen_0";
	g_MonthlySignSP_Figure[1] = "set:Sign image:Signgreen_1";
	g_MonthlySignSP_Figure[2] = "set:Sign image:Signgreen_2";
	g_MonthlySignSP_Figure[3] = "set:Sign image:Signgreen_3";
	g_MonthlySignSP_Figure[4] = "set:Sign image:Signgreen_4";
	g_MonthlySignSP_Figure[5] = "set:Sign image:Signgreen_5";
	g_MonthlySignSP_Figure[6] = "set:Sign image:Signgreen_6";
	g_MonthlySignSP_Figure[7] = "set:Sign image:Signgreen_7";
	g_MonthlySignSP_Figure[8] = "set:Sign image:Signgreen_8";
	g_MonthlySignSP_Figure[9] = "set:Sign image:Signgreen_9";

	g_MonthlySignSP_GiftSign[1] = MonthlySignSP_Gift_1;
	g_MonthlySignSP_GiftSign[2] = MonthlySignSP_Gift_2;
	g_MonthlySignSP_GiftSign[3] = MonthlySignSP_Gift_3;
	g_MonthlySignSP_GiftSign[4] = MonthlySignSP_Gift_4;
	g_MonthlySignSP_GiftSign[5] = MonthlySignSP_Gift_5;

	g_MonthlySignSP_PrizeItemList[1] = MonthlySignSP_Item1;
	g_MonthlySignSP_PrizeItemList[2] = MonthlySignSP_Item2;
	g_MonthlySignSP_PrizeItemList[3] = MonthlySignSP_Item3;
	g_MonthlySignSP_PrizeItemList[4] = MonthlySignSP_Item4;


		-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= MonthlySignSP_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= MonthlySignSP_Frame:GetProperty("UnifiedYPosition");

	g_ButtonPos[1].x	= MonthlySignSP_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= MonthlySignSP_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= MonthlySignSP_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= MonthlySignSP_Button3tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[2].x	= MonthlySignSP_Button6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= MonthlySignSP_Button6:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= MonthlySignSP_Button6tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= MonthlySignSP_Button6tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= MonthlySignSP_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= MonthlySignSP_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= MonthlySignSP_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= MonthlySignSP_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= MonthlySignSP_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= MonthlySignSP_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= MonthlySignSP_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= MonthlySignSP_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[5].x	= MonthlySignSP_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= MonthlySignSP_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= MonthlySignSP_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= MonthlySignSP_Button8tips:GetProperty("UnifiedYPosition");


end

function MonthlySignSP_OnShown()
	--刷新服务器时间
	AskServerTimeAgain();

	if g_MonthlySignSP_curMonth == 5 then
		MonthlySignSP_DragTitle:SetText("#{MYQD_170214_49}")
	end

	local nSalaryTask = 2
	local nShaoDang = 3
	local nOneDay = 4
	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 ) then
		MonthlySignSP_Button3 : Hide();
		nSalaryTask = nSalaryTask - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
	--	return
	else
		MonthlySignSP_Button3 : Show();

	end

	local nLevel = Player:GetLevel();
	if ( nLevel < 35 or DataPool:GetServerDayTime() > 20211016) then
		MonthlySignSP_Button6:Hide()
		nSalaryTask = -1
		nShaoDang = nShaoDang - 1
		nOneDay = nOneDay-1
	else
		MonthlySignSP_Button6:Show()
	end

	MonthlySignSP_Button5:Show()
	if ( nLevel < 60 ) then
		MonthlySignSP_Button5:Hide()
		nShaoDang = -1
		nOneDay = nOneDay-1
	end


	if nSalaryTask ~= -1 then
		MonthlySignSP_Button6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].x);
		MonthlySignSP_Button6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].y);
		MonthlySignSP_Button6tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].tipx);
		MonthlySignSP_Button6tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].tipy);
	end

	if nShaoDang ~= -1 then
		MonthlySignSP_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		MonthlySignSP_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		MonthlySignSP_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		MonthlySignSP_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);

	end

	if nOneDay ~= -1 then
		MonthlySignSP_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		MonthlySignSP_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		MonthlySignSP_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		MonthlySignSP_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);

		MonthlySignSP_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].x);
		MonthlySignSP_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].y);
		MonthlySignSP_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].tipx);
		MonthlySignSP_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].tipy);
	end

	if g_MonthlySignSP_curMonth < 1 or g_MonthlySignSP_curMonth > 12 then
		return
	end

	if g_MonthlySignSP_daycount < 28 or g_MonthlySignSP_daycount > 31 then
		return
	end
	MonthlySignSP_Month_Number:SetProperty("Image", g_MonthlySignSP_Month[g_MonthlySignSP_curMonth]);
	if g_MonthlySignSP_curMonth == 1 then
		MonthlySignSP_Explain1:SetText("#{MYQD_161222_46}")
	elseif g_MonthlySignSP_curMonth == 2 then
		MonthlySignSP_Explain1:SetText("#{MYQD_161222_47}")
	elseif g_MonthlySignSP_curMonth == 5 then
		MonthlySignSP_Explain1:SetText("#{MYQD_170214_50}")
	end
	local check  = tonumber(NpcShop:GetResignDirectly());
	if(check>=1)then
		MonthlySignSP_YuanbaoCheck:SetCheck(0);
	else
		MonthlySignSP_YuanbaoCheck:SetCheck(1);
	end

	local curDay = math.mod(g_MonthlySignSP_curDay, 100);
	g_MonthlySignSP_SignCount = 0;

	local canResign = 0;
	for i=1,  g_MonthlySignSP_daycount do
		g_MonthlySignSP_TodayImage[i]:Hide();
		g_MonthlySignSP_Mark[i]:Hide();
		g_MonthlySignSP_DateButton[i]:Hide();
		if i <= curDay then
			if i  == curDay then
				g_MonthlySignSP_TodayImage[i]:Show();
			end
			local signflag =  DataPool:Lua_GetBinaryData(g_MonthlySignSP_SignFlagData, i-1 );
			if signflag == 1 then --已签到状态
				g_MonthlySignSP_SignCount=g_MonthlySignSP_SignCount+1;
				g_MonthlySignSP_Mark[i]:Show();
			else  --可补签状态
				if i < curDay then
					canResign = 1;
					g_MonthlySignSP_DateButton[i]:Show();
				end
			end
		end
	end

	for i=g_MonthlySignSP_daycount+1, 31 do
		g_MonthlySignSP_HideButton[i]:Hide();
	end

	local ubit = math.floor( g_MonthlySignSP_SignCount/10);
	local lbit = math.mod(g_MonthlySignSP_SignCount, 10);
	if ubit == 0 then
		MonthlySignSP_Date_Number1:SetProperty("Image", "");
	else
		MonthlySignSP_Date_Number1:SetProperty("Image", g_MonthlySignSP_Figure[ubit] );
	end
	MonthlySignSP_Date_Number2:SetProperty("Image", g_MonthlySignSP_Figure[lbit] );

	--今日签到按钮
	local todayflag = DataPool:Lua_GetBinaryData(g_MonthlySignSP_SignFlagData, curDay-1 );
	if todayflag == 1 then
		 --按钮置灰
		MonthlySignSP_Date_Sign:Disable();
		--设置按钮文本"已签到"
		MonthlySignSP_Date_Sign:SetText("#{MYQD_150513_06}")
		--取消动画闪烁
		MonthlySignSP_Date_Sign_Animate:Play(false)
	else
	          --按钮可用
		MonthlySignSP_Date_Sign:Enable();
		--设置按钮文本"今日签到"
		MonthlySignSP_Date_Sign:SetText("#{MYQD_150513_09}")
		--显示动画闪烁
		MonthlySignSP_Date_Sign_Animate:Play(true)
	end

	--补签按钮
	if canResign == 1 then
		MonthlySignSP_Date_ReSign:Enable();
	else
		MonthlySignSP_Date_ReSign:Disable();
	end

	local PrizeButton = 0;
	for i=1, 5 do
		if g_MonthlySignSP_SignCount >= g_MonthlySignSP_SignDay[i] and g_MonthlySignSP_GetPrizeFlag[i] == 0 then
			PrizeButton = i;
		end
	end
	if PrizeButton ~= 0 then
		g_MonthlySignSP_curDayButton = PrizeButton
	end

	MonthlySignSP_SignCountClicked(g_MonthlySignSP_curDayButton);

	MonthlySignSP_Button1:SetCheck(1)
	MonthlySignSP_Button2:SetCheck(0)
	MonthlySignSP_Button3:SetCheck(0)
	MonthlySignSP_Button5:SetCheck(0)
	MonthlySignSP_Button6:SetCheck(0)

	MonthlySignSP_Refresh_ButtonTips()
	this:Show();
end

function MonthlySignSP_UpdatePrizeItem(nIndex)
	local itemlist = g_MonthlySignSP_ItemInfo[nIndex];
	if g_MonthlySignSP_curMonth == 2 then
		itemlist = g_MonthlySignSP_ItemInfo_Feb[nIndex];
	elseif g_MonthlySignSP_curMonth == 5 then
		itemlist = g_MonthlySignSP_ItemInfo_ZN[nIndex];
	elseif g_MonthlySignSP_curMonth == 11 or g_MonthlySignSP_curMonth == 10 then
		itemlist = g_MonthlySignSP_ItemInfo_SQ[nIndex];
	end
	local cnt = table.getn(itemlist)
	DataPool:ClearMonthlySignItem();
	for i =1 , cnt do
		DataPool:CreateMonthlySignItem(itemlist[i].awardid, i-1,itemlist[i].num)
	end

	for i = 1, 4 do
		if i <= cnt then
			local theAction = EnumAction(i-1, "monthlysign_item");
			if theAction:GetID() ~= 0 then
				g_MonthlySignSP_PrizeItemList[i]:Show();
				g_MonthlySignSP_PrizeItemList[i]:Enable();
				g_MonthlySignSP_PrizeItemList[i]:SetActionItem(theAction:GetID())
			end
		else
			g_MonthlySignSP_PrizeItemList[i]:Hide();
		end
	end
end
--今日签到按钮
function MonthlySignSP_DateSignClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CheckTodaySign")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function MonthlySignSP_DateResignClicked(nIndex)
	if nIndex == nil then
		return
	end

	if nIndex < 1 then
		return
	end

	if(NpcShop:GetResignDirectly() == 1)then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CheckResign")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		PushEvent( "RESIGN_CONFIRM" , nIndex);
	end
end
function MonthlySignSP_AutoResign()
	local curDay = math.mod(g_MonthlySignSP_curDay, 100);
	for i=1, curDay-1 do
		local signflag =  DataPool:Lua_GetBinaryData(g_MonthlySignSP_SignFlagData, i-1 );
		if signflag == 0 then
			MonthlySignSP_DateResignClicked(i)
			break;
		end
	end
end

function MonthlySignSP_SignCountClicked(nIndex)
	if nIndex == nil then
		return
	end

	if nIndex < 1  or nIndex > 5 then
		return
	end

	g_MonthlySignSP_curDayButton = nIndex;

	g_MonthlySignSP_GiftSign[nIndex]:SetProperty("Selected", "True")

	if g_MonthlySignSP_SignCount >= g_MonthlySignSP_SignDay[nIndex] then
		if g_MonthlySignSP_GetPrizeFlag[nIndex] == 1 then --已领取
			if SystemSetup : IsClassic() == 1 then
				MonthlySignSP_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Yilingqu")
			else
				MonthlySignSP_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Yilingqu")
			end
			MonthlySignSP_Item_Pick:Disable();
		else
			MonthlySignSP_Item_Pick:Enable();
		end
	else
		if SystemSetup : IsClassic() == 1 then
			MonthlySignSP_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Weidacheng")
		else
			MonthlySignSP_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Weidacheng")
		end
		MonthlySignSP_Item_Pick:Disable();
	end

	MonthlySignSP_UpdatePrizeItem(nIndex);


end
function MonthlySignSP_YuanbaoConfirm()
	if(NpcShop:GetResignDirectly() == 0)then
		NpcShop:SetResignDirectly(1);
	else
		NpcShop:SetResignDirectly(0);
	end
end
function MonthlySignSP_GetPrize()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetPrize")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_Parameter(0,g_MonthlySignSP_curDayButton)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--================================================
-- 界面的默认相对位置
--================================================
function MonthlySignSP_ResetPos()
	MonthlySignSP_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	MonthlySignSP_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function MonthlySignSP_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SPSelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
	    MonthlySignSP_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

function MonthlySignSP_OnClosed()
	this:Hide();
end


function MonthlySignSP_Button1_Click()
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name("OpenWindowRequest")
--		Set_XSCRIPT_ScriptID(891106)
--		Set_XSCRIPT_ParamCount(0)
--	Send_XSCRIPT()

end

function MonthlySignSP_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end
	OpenStrongRoadDiaoWenSP(1)

	Variable:SetVariable("SPSelfFuliUIPos", MonthlySignSP_Frame:GetProperty("UnifiedPosition"), 1)

end

function MonthlySignSP_Button3_Click()
	OpenQianKunDaiSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", MonthlySignSP_Frame:GetProperty("UnifiedPosition"), 1)
end


function MonthlySignSP_Button4_Click()

end

function MonthlySignSP_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end

	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,1);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
	
	OpenZhaoHui(1)
	Variable:SetVariable("SPSelfFuliUIPos", MonthlySignSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function MonthlySignSP_Button6_Click()
end

function MonthlySignSP_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end 
	Variable:SetVariable("SPSelfFuliUIPos", MonthlySignSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function MonthlySignSP_Button8_Click()
	OpenHuiGuiSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", MonthlySignSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function MonthlySignSP_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		MonthlySignSP_Button7tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		MonthlySignSP_Button7tips : Hide()
	end

	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		MonthlySignSP_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		MonthlySignSP_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		MonthlySignSP_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		MonthlySignSP_Button8 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		MonthlySignSP_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		MonthlySignSP_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		MonthlySignSP_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		MonthlySignSP_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 )then
			DataPool:Lua_SetRedPointInUIShow(39, 0) 
			MonthlySignSP_Button3tips : Hide()
		else
			MonthlySignSP_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		MonthlySignSP_Button3tips : Hide()
	end

	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		MonthlySignSP_Button5tips : Show()
	else
		MonthlySignSP_Button5tips : Hide()
	end

	MonthlySignSP_Button6tips : Hide()
end
