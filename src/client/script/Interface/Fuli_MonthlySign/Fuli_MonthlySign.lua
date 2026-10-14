local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
											[6] = {x =0, y = 0, tipx =0, tipy =0},
											[7] = {x =0, y = 0, tipx =0, tipy =0},
										}
										
local g_Fuli_MonthlySign_DateButton = {};
local g_Fuli_MonthlySign_TodayImage = {};
local g_Fuli_MonthlySign_HideButton = {};
local g_Fuli_MonthlySign_PrizeItemList = {};
local g_Fuli_MonthlySign_Month = {};
local g_Fuli_MonthlySign_Mark = {};
local g_Fuli_MonthlySign_Figure = {};
local g_Fuli_MonthlySign_GiftSign = {};


local g_Fuli_MonthlySign_curDay = 0;
local g_Fuli_MonthlySign_curMonth = 0;
local g_Fuli_MonthlySign_daycount = 0;
local g_Fuli_MonthlySign_SignFlagData = 0;
local g_Fuli_MonthlySign_SignCount = 0;
local g_Fuli_MonthlySign_curDayButton = 1;
local g_Fuli_MonthlySign_GetPrizeFlag={};
 
local g_Fuli_MonthlySign_Spec_Month = {8,};		--OpenSpecimonth   	MonthSign ActivePoint
local g_Fuli_MonthlySign_Spec_Year = 2026;		--OpenSpeciYear 	MonthSign ActivePoint
--原服
local g_Fuli_MonthlySign_ItemInfo = {};
g_Fuli_MonthlySign_ItemInfo[0] = {};
g_Fuli_MonthlySign_ItemInfo[0][1] = 	{{awardid = 30607004, num = 1},{awardid = 30505217, num = 1}}
g_Fuli_MonthlySign_ItemInfo[0][2] = 	{{awardid = 39920394, num = 1},{awardid = 38006382, num = 5}}
g_Fuli_MonthlySign_ItemInfo[0][3] = 	{{awardid = 39920156, num = 1},{awardid = 20700063, num = 5}}
g_Fuli_MonthlySign_ItemInfo[0][4] = 	{{awardid = 38000380, num = 1},{awardid = 38000992, num = 1},{awardid = 20700063, num = 5}}
g_Fuli_MonthlySign_ItemInfo[0][5] = 	{{awardid = 30008130, num = 1},{awardid = 38000571, num = 1},{awardid = 20700063, num = 10}}
 
local g_Fuli_MonthlySign_ItemInfo_Spec = {};
g_Fuli_MonthlySign_ItemInfo_Spec[0] = {};
g_Fuli_MonthlySign_ItemInfo_Spec[0][1] = 	{{awardid = 38000378, num = 3},{awardid = 20310168, num = 3},{awardid = 39920181, num = 1}}
g_Fuli_MonthlySign_ItemInfo_Spec[0][2] = 	{{awardid = 20310178, num = 1},{awardid = 20700063, num = 50},{awardid = 20700055, num = 25},{awardid = 20800033, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec[0][3] = 	{{awardid = 38000380, num = 2},{awardid = 38000571, num = 2},{awardid = 39922174, num = 2},{awardid = 20800031, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec[0][4] = 	{{awardid = 38000992, num = 2},{awardid = 20310179, num = 1},{awardid = 20700055, num = 50},{awardid = 20800033, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec[0][5] = 	{{awardid = 39921549, num = 1},{awardid = 39921547, num = 1},{awardid = 38000945, num = 3}}

--卡级服
g_Fuli_MonthlySign_ItemInfo[1] = {};
g_Fuli_MonthlySign_ItemInfo[1][1] = 	{{awardid = 30607004, num = 1},{awardid = 30505217, num = 1}}
g_Fuli_MonthlySign_ItemInfo[1][2] = 	{{awardid = 39920394, num = 1},{awardid = 38006382, num = 5}}
g_Fuli_MonthlySign_ItemInfo[1][3] = 	{{awardid = 39920156, num = 1},{awardid = 39920267, num = 1}}
g_Fuli_MonthlySign_ItemInfo[1][4] = 	{{awardid = 39920334, num = 1},{awardid = 38000992, num = 1},{awardid = 39920089, num = 1}}
g_Fuli_MonthlySign_ItemInfo[1][5] = 	{{awardid = 30008130, num = 1},{awardid = 38000571, num = 1},{awardid = 39920085, num = 2}} 
 
g_Fuli_MonthlySign_ItemInfo_Spec[1] = {};
g_Fuli_MonthlySign_ItemInfo_Spec[1][1] = 	{{awardid = 39920394, num = 2},{awardid = 20310168, num = 3},{awardid = 39920181, num = 1}}
g_Fuli_MonthlySign_ItemInfo_Spec[1][2] = 	{{awardid = 39923724, num = 5},{awardid = 39920817, num = 2},{awardid = 39920820, num = 2},{awardid = 39920334, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec[1][3] = 	{{awardid = 39920085, num = 5},{awardid = 38000571, num = 2},{awardid = 39920333, num = 1},{awardid = 39920332, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec[1][4] = 	{{awardid = 38000992, num = 2},{awardid = 39920235, num = 2},{awardid = 39920267, num = 2},{awardid = 39920334, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec[1][5] = 	{{awardid = 39920396, num = 1},{awardid = 39920397, num = 1},{awardid = 38000945, num = 3}}

local g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD = {};
g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD[0] = {};
g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD[0][1] = 	{{awardid = 38000378, num = 3},{awardid = 20310168, num = 3},{awardid = 30008130, num = 1}}
g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD[0][2] = 	{{awardid = 30503129, num = 5},{awardid = 20700063, num = 50},{awardid = 20700055, num = 25},{awardid = 38000807, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD[0][3] = 	{{awardid = 38000380, num = 2},{awardid = 38000571, num = 2},{awardid = 38000658, num = 1},{awardid = 38000656, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD[0][4] = 	{{awardid = 38000992, num = 2},{awardid = 30503133, num = 2},{awardid = 20700055, num = 50},{awardid = 38000807, num = 5}}
g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD[0][5] = 	{{awardid = 20502015, num = 1},{awardid = 20501009, num = 1},{awardid = 38000945, num = 3}}

local g_Fuli_MonthlySign_ItemInfo_2606S = {};
g_Fuli_MonthlySign_ItemInfo_2606S[0] = {};
g_Fuli_MonthlySign_ItemInfo_2606S[0][1] = 	{{awardid = 30607004, num = 1},{awardid = 30505217, num = 1}}
g_Fuli_MonthlySign_ItemInfo_2606S[0][2] = 	{{awardid = 39920394, num = 1},{awardid = 38006382, num = 5}}
g_Fuli_MonthlySign_ItemInfo_2606S[0][3] = 	{{awardid = 39920156, num = 1},{awardid = 30008034, num = 1}}
g_Fuli_MonthlySign_ItemInfo_2606S[0][4] = 	{{awardid = 38000380, num = 1},{awardid = 38000992, num = 1},{awardid = 30008034, num = 1}}
g_Fuli_MonthlySign_ItemInfo_2606S[0][5] = 	{{awardid = 30008027, num = 1},{awardid = 38000571, num = 1},{awardid = 30008034, num = 2}}

local g_Fuli_MonthlySign_ItemInfo_Spec_2606S = {};
g_Fuli_MonthlySign_ItemInfo_Spec_2606S[0] = {};
g_Fuli_MonthlySign_ItemInfo_Spec_2606S[0][1] = 	{{awardid = 38000378, num = 3},{awardid = 20310168, num = 3},{awardid = 30008027, num = 1}}
g_Fuli_MonthlySign_ItemInfo_Spec_2606S[0][2] = 	{{awardid = 38000807, num = 1},{awardid = 30008048, num = 1},{awardid = 38000656, num = 1},{awardid = 30503133, num = 1}}
g_Fuli_MonthlySign_ItemInfo_Spec_2606S[0][3] = 	{{awardid = 38000380, num = 2},{awardid = 38000571, num = 2},{awardid = 38000443, num = 3},{awardid = 30700241, num = 3}}
g_Fuli_MonthlySign_ItemInfo_Spec_2606S[0][4] = 	{{awardid = 38000992, num = 2},{awardid = 38000658, num = 2},{awardid = 38000656, num = 2},{awardid = 30503133, num = 1}}
g_Fuli_MonthlySign_ItemInfo_Spec_2606S[0][5] = 	{{awardid = 39921549, num = 1},{awardid = 39921547, num = 1},{awardid = 38000571, num = 3}}
 

local g_Fuli_MonthlySign_SignDay = { 5, 10, 15, 20, 25}

local CreateDate = 904691712			-- 2013年08月22日08:00:00

local nCharCreateDate = -1;
local g_bIsNewServerGiftsForLevelUpValid = 0
local g_bIsNewServerGiftsForLevelUpValid_2023 = 0


function Fuli_MonthlySign_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false) 
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
	this:RegisterEvent("OPEN_MONTHLYSIGN") 
end

function Fuli_MonthlySign_OnEvent(event)
	--Fuli_MonthlySign_Button5tips : Hide()
	if event == "UI_COMMAND" and tonumber( arg0 ) == 89110601 then
		if ( Get_XParam_INT_Count() < 9 ) then
			return
		end
		g_Fuli_MonthlySign_curDay = tonumber(Get_XParam_INT(0))
		g_Fuli_MonthlySign_curMonth = tonumber(Get_XParam_INT(1))
		g_Fuli_MonthlySign_daycount = tonumber(Get_XParam_INT(2))
		g_Fuli_MonthlySign_SignFlagData = tonumber(Get_XParam_INT(3))
		for i = 1, 5 do
			g_Fuli_MonthlySign_GetPrizeFlag[i] = tonumber(Get_XParam_INT(3+i))
		end
		Fuli_MonthlySign_OnShown()
		DataPool:Lua_SetIsInSpringFlag( 0 )
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 89110602 then
		if ( Get_XParam_INT_Count() < 1 ) then
			return
		end
		g_Fuli_MonthlySign_SignFlagData = tonumber(Get_XParam_INT(0))
		Fuli_MonthlySign_OnShown()
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 89110603 then
		if ( Get_XParam_INT_Count() < 5 ) then
			return
		end
		for i = 1, 5 do
			g_Fuli_MonthlySign_GetPrizeFlag[i] = tonumber(Get_XParam_INT(i-1))
		end
		Fuli_MonthlySign_OnShown()
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20170302 then
		--DataPool:Lua_SetDailySeckillFlag( Get_XParam_INT( 0 ))
		--Fuli_MonthlySign_Refresh_ButtonTips()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2017122501 then
		DataPool:Lua_SetDailySeckillFlag( Get_XParam_INT( 0 )) 

		Fuli_MonthlySign_Refresh_ButtonTips()
		
	elseif( event == "ADJEST_UI_POS" ) then
		Fuli_MonthlySign_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Fuli_MonthlySign_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		if this:IsVisible() then
			Fuli_MonthlySign_OnShown()
		else
			Fuli_MonthlySign_Refresh_ButtonTips()
		end
	elseif event == "OPEN_MONTHLYSIGN" then
		if(tonumber(arg0) == 0) then
			Fuli_MonthlySign_ResetPos()
		else
			Fuli_MonthlySign_SetLastPos()
		end
	--	this:Show()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = 0
		Lua_TDU_Log("nCharCreateDate"..nCharCreateDate);
		Lua_TDU_Log("g_bIsNewServerGiftsForLevelUpValid"..g_bIsNewServerGiftsForLevelUpValid);
		Fuli_MonthlySign_Debug("8889072")
		Fuli_MonthlySign_Refresh_ButtonTips()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 99847904 ) then
		nCharCreateDate = Get_XParam_INT( 0 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = Get_XParam_INT( 1 );
		g_bIsNewServerGiftsForLevelUpValid = 0
		Lua_TDU_Log("nCharCreateDate"..nCharCreateDate);
		Lua_TDU_Log("g_bIsNewServerGiftsForLevelUpValid_2023"..g_bIsNewServerGiftsForLevelUpValid_2023);
		Fuli_MonthlySign_Debug("99847904")
		Fuli_MonthlySign_Refresh_ButtonTips()
	end
end

function Fuli_MonthlySign_Debug(str)
	Lua_TDU_Log("Fuli_MonthlySign_Debug : "..str)
	--PushDebugMessage("Fuli_MonthlySign_Debug : "..str)
end

function Fuli_MonthlySign_OnLoad()
	g_Fuli_MonthlySign_Month[1] = "set:Sign image:Signmonth_1";
	g_Fuli_MonthlySign_Month[2] = "set:Sign image:Signmonth_2";
	g_Fuli_MonthlySign_Month[3] = "set:Sign image:Signmonth_3";
	g_Fuli_MonthlySign_Month[4] = "set:Sign image:Signmonth_4";
	g_Fuli_MonthlySign_Month[5] = "set:Sign image:Signmonth_5";
	g_Fuli_MonthlySign_Month[6] = "set:Sign image:Signmonth_6";
	g_Fuli_MonthlySign_Month[7] = "set:Sign image:Signmonth_7";
	g_Fuli_MonthlySign_Month[8] = "set:Sign image:Signmonth_8";
	g_Fuli_MonthlySign_Month[9] = "set:Sign image:Signmonth_9";
	g_Fuli_MonthlySign_Month[10] = "set:Sign image:Signmonth_10";
	g_Fuli_MonthlySign_Month[11] = "set:Sign image:Signmonth_11";
	g_Fuli_MonthlySign_Month[12] = "set:Sign image:Signmonth_12";

	g_Fuli_MonthlySign_Mark[1] = Fuli_MonthlySign_Date_1_Mark;
	g_Fuli_MonthlySign_Mark[2] = Fuli_MonthlySign_Date_2_Mark;
	g_Fuli_MonthlySign_Mark[3] = Fuli_MonthlySign_Date_3_Mark;
	g_Fuli_MonthlySign_Mark[4] = Fuli_MonthlySign_Date_4_Mark;
	g_Fuli_MonthlySign_Mark[5] = Fuli_MonthlySign_Date_5_Mark;
	g_Fuli_MonthlySign_Mark[6] = Fuli_MonthlySign_Date_6_Mark;
	g_Fuli_MonthlySign_Mark[7] = Fuli_MonthlySign_Date_7_Mark;
	g_Fuli_MonthlySign_Mark[8] = Fuli_MonthlySign_Date_8_Mark;
	g_Fuli_MonthlySign_Mark[9] = Fuli_MonthlySign_Date_9_Mark;
	g_Fuli_MonthlySign_Mark[10] = Fuli_MonthlySign_Date_10_Mark;
	g_Fuli_MonthlySign_Mark[11] = Fuli_MonthlySign_Date_11_Mark;
	g_Fuli_MonthlySign_Mark[12] = Fuli_MonthlySign_Date_12_Mark;
	g_Fuli_MonthlySign_Mark[13] = Fuli_MonthlySign_Date_13_Mark;
	g_Fuli_MonthlySign_Mark[14] = Fuli_MonthlySign_Date_14_Mark;
	g_Fuli_MonthlySign_Mark[15] = Fuli_MonthlySign_Date_15_Mark;
	g_Fuli_MonthlySign_Mark[16] = Fuli_MonthlySign_Date_16_Mark;
	g_Fuli_MonthlySign_Mark[17] = Fuli_MonthlySign_Date_17_Mark;
	g_Fuli_MonthlySign_Mark[18] = Fuli_MonthlySign_Date_18_Mark;
	g_Fuli_MonthlySign_Mark[19] = Fuli_MonthlySign_Date_19_Mark;
	g_Fuli_MonthlySign_Mark[20] = Fuli_MonthlySign_Date_20_Mark;
	g_Fuli_MonthlySign_Mark[21] = Fuli_MonthlySign_Date_21_Mark;
	g_Fuli_MonthlySign_Mark[22] = Fuli_MonthlySign_Date_22_Mark;
	g_Fuli_MonthlySign_Mark[23] = Fuli_MonthlySign_Date_23_Mark;
	g_Fuli_MonthlySign_Mark[24] = Fuli_MonthlySign_Date_24_Mark;
	g_Fuli_MonthlySign_Mark[25] = Fuli_MonthlySign_Date_25_Mark;
	g_Fuli_MonthlySign_Mark[26] = Fuli_MonthlySign_Date_26_Mark;
	g_Fuli_MonthlySign_Mark[27] = Fuli_MonthlySign_Date_27_Mark;
	g_Fuli_MonthlySign_Mark[28] = Fuli_MonthlySign_Date_28_Mark;
	g_Fuli_MonthlySign_Mark[29] = Fuli_MonthlySign_Date_29_Mark;
	g_Fuli_MonthlySign_Mark[30] = Fuli_MonthlySign_Date_30_Mark;
	g_Fuli_MonthlySign_Mark[31] = Fuli_MonthlySign_Date_31_Mark;

	g_Fuli_MonthlySign_DateButton[1] = Fuli_MonthlySign_Date_1_ReSign;
	g_Fuli_MonthlySign_DateButton[2] = Fuli_MonthlySign_Date_2_ReSign;
	g_Fuli_MonthlySign_DateButton[3] = Fuli_MonthlySign_Date_3_ReSign;
	g_Fuli_MonthlySign_DateButton[4] = Fuli_MonthlySign_Date_4_ReSign;
	g_Fuli_MonthlySign_DateButton[5] = Fuli_MonthlySign_Date_5_ReSign;
	g_Fuli_MonthlySign_DateButton[6] = Fuli_MonthlySign_Date_6_ReSign;
	g_Fuli_MonthlySign_DateButton[7] = Fuli_MonthlySign_Date_7_ReSign;
	g_Fuli_MonthlySign_DateButton[8] = Fuli_MonthlySign_Date_8_ReSign;
	g_Fuli_MonthlySign_DateButton[9] = Fuli_MonthlySign_Date_9_ReSign;
	g_Fuli_MonthlySign_DateButton[10] = Fuli_MonthlySign_Date_10_ReSign;
	g_Fuli_MonthlySign_DateButton[11] = Fuli_MonthlySign_Date_11_ReSign;
	g_Fuli_MonthlySign_DateButton[12] = Fuli_MonthlySign_Date_12_ReSign;
	g_Fuli_MonthlySign_DateButton[13] = Fuli_MonthlySign_Date_13_ReSign;
	g_Fuli_MonthlySign_DateButton[14] = Fuli_MonthlySign_Date_14_ReSign;
	g_Fuli_MonthlySign_DateButton[15] = Fuli_MonthlySign_Date_15_ReSign;
	g_Fuli_MonthlySign_DateButton[16] = Fuli_MonthlySign_Date_16_ReSign;
	g_Fuli_MonthlySign_DateButton[17] = Fuli_MonthlySign_Date_17_ReSign;
	g_Fuli_MonthlySign_DateButton[18] = Fuli_MonthlySign_Date_18_ReSign;
	g_Fuli_MonthlySign_DateButton[19] = Fuli_MonthlySign_Date_19_ReSign;
	g_Fuli_MonthlySign_DateButton[20] = Fuli_MonthlySign_Date_20_ReSign;
	g_Fuli_MonthlySign_DateButton[21] = Fuli_MonthlySign_Date_21_ReSign;
	g_Fuli_MonthlySign_DateButton[22] = Fuli_MonthlySign_Date_22_ReSign;
	g_Fuli_MonthlySign_DateButton[23] = Fuli_MonthlySign_Date_23_ReSign;
	g_Fuli_MonthlySign_DateButton[24] = Fuli_MonthlySign_Date_24_ReSign;
	g_Fuli_MonthlySign_DateButton[25] = Fuli_MonthlySign_Date_25_ReSign;
	g_Fuli_MonthlySign_DateButton[26] = Fuli_MonthlySign_Date_26_ReSign;
	g_Fuli_MonthlySign_DateButton[27] = Fuli_MonthlySign_Date_27_ReSign;
	g_Fuli_MonthlySign_DateButton[28] = Fuli_MonthlySign_Date_28_ReSign;
	g_Fuli_MonthlySign_DateButton[29] = Fuli_MonthlySign_Date_29_ReSign;
	g_Fuli_MonthlySign_DateButton[30] = Fuli_MonthlySign_Date_30_ReSign;
	g_Fuli_MonthlySign_DateButton[31] = Fuli_MonthlySign_Date_31_ReSign;

	g_Fuli_MonthlySign_TodayImage[1] = Fuli_MonthlySign_Date_1_Today;
	g_Fuli_MonthlySign_TodayImage[2] = Fuli_MonthlySign_Date_2_Today;
	g_Fuli_MonthlySign_TodayImage[3] = Fuli_MonthlySign_Date_3_Today;
	g_Fuli_MonthlySign_TodayImage[4] = Fuli_MonthlySign_Date_4_Today;
	g_Fuli_MonthlySign_TodayImage[5] = Fuli_MonthlySign_Date_5_Today;
	g_Fuli_MonthlySign_TodayImage[6] = Fuli_MonthlySign_Date_6_Today;
	g_Fuli_MonthlySign_TodayImage[7] = Fuli_MonthlySign_Date_7_Today;
	g_Fuli_MonthlySign_TodayImage[8] = Fuli_MonthlySign_Date_8_Today;
	g_Fuli_MonthlySign_TodayImage[9] = Fuli_MonthlySign_Date_9_Today;
	g_Fuli_MonthlySign_TodayImage[10] = Fuli_MonthlySign_Date_10_Today;
	g_Fuli_MonthlySign_TodayImage[11] = Fuli_MonthlySign_Date_11_Today;
	g_Fuli_MonthlySign_TodayImage[12] = Fuli_MonthlySign_Date_12_Today;
	g_Fuli_MonthlySign_TodayImage[13] = Fuli_MonthlySign_Date_13_Today;
	g_Fuli_MonthlySign_TodayImage[14] = Fuli_MonthlySign_Date_14_Today;
	g_Fuli_MonthlySign_TodayImage[15] = Fuli_MonthlySign_Date_15_Today;
	g_Fuli_MonthlySign_TodayImage[16] = Fuli_MonthlySign_Date_16_Today;
	g_Fuli_MonthlySign_TodayImage[17] = Fuli_MonthlySign_Date_17_Today;
	g_Fuli_MonthlySign_TodayImage[18] = Fuli_MonthlySign_Date_18_Today;
	g_Fuli_MonthlySign_TodayImage[19] = Fuli_MonthlySign_Date_19_Today;
	g_Fuli_MonthlySign_TodayImage[20] = Fuli_MonthlySign_Date_20_Today;
	g_Fuli_MonthlySign_TodayImage[21] = Fuli_MonthlySign_Date_21_Today;
	g_Fuli_MonthlySign_TodayImage[22] = Fuli_MonthlySign_Date_22_Today;
	g_Fuli_MonthlySign_TodayImage[23] = Fuli_MonthlySign_Date_23_Today;
	g_Fuli_MonthlySign_TodayImage[24] = Fuli_MonthlySign_Date_24_Today;
	g_Fuli_MonthlySign_TodayImage[25] = Fuli_MonthlySign_Date_25_Today;
	g_Fuli_MonthlySign_TodayImage[26] = Fuli_MonthlySign_Date_26_Today;
	g_Fuli_MonthlySign_TodayImage[27] = Fuli_MonthlySign_Date_27_Today;
	g_Fuli_MonthlySign_TodayImage[28] = Fuli_MonthlySign_Date_28_Today;
	g_Fuli_MonthlySign_TodayImage[29] = Fuli_MonthlySign_Date_29_Today;
	g_Fuli_MonthlySign_TodayImage[30] = Fuli_MonthlySign_Date_30_Today;
	g_Fuli_MonthlySign_TodayImage[31] = Fuli_MonthlySign_Date_31_Today;

	g_Fuli_MonthlySign_HideButton[29] = Fuli_MonthlySign_Date_29;
	g_Fuli_MonthlySign_HideButton[30] = Fuli_MonthlySign_Date_30;
	g_Fuli_MonthlySign_HideButton[31] = Fuli_MonthlySign_Date_31;

	g_Fuli_MonthlySign_Figure[0] = "set:Sign image:Signgreen_0";
	g_Fuli_MonthlySign_Figure[1] = "set:Sign image:Signgreen_1";
	g_Fuli_MonthlySign_Figure[2] = "set:Sign image:Signgreen_2";
	g_Fuli_MonthlySign_Figure[3] = "set:Sign image:Signgreen_3";
	g_Fuli_MonthlySign_Figure[4] = "set:Sign image:Signgreen_4";
	g_Fuli_MonthlySign_Figure[5] = "set:Sign image:Signgreen_5";
	g_Fuli_MonthlySign_Figure[6] = "set:Sign image:Signgreen_6";
	g_Fuli_MonthlySign_Figure[7] = "set:Sign image:Signgreen_7";
	g_Fuli_MonthlySign_Figure[8] = "set:Sign image:Signgreen_8";
	g_Fuli_MonthlySign_Figure[9] = "set:Sign image:Signgreen_9";

	g_Fuli_MonthlySign_GiftSign[1] = Fuli_MonthlySign_Gift_1;
	g_Fuli_MonthlySign_GiftSign[2] = Fuli_MonthlySign_Gift_2;
	g_Fuli_MonthlySign_GiftSign[3] = Fuli_MonthlySign_Gift_3;
	g_Fuli_MonthlySign_GiftSign[4] = Fuli_MonthlySign_Gift_4;
	g_Fuli_MonthlySign_GiftSign[5] = Fuli_MonthlySign_Gift_5;

	g_Fuli_MonthlySign_PrizeItemList[1] = Fuli_MonthlySign_Item1;
	g_Fuli_MonthlySign_PrizeItemList[2] = Fuli_MonthlySign_Item2;
	g_Fuli_MonthlySign_PrizeItemList[3] = Fuli_MonthlySign_Item3;
	g_Fuli_MonthlySign_PrizeItemList[4] = Fuli_MonthlySign_Item4;

		-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Fuli_MonthlySign_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Fuli_MonthlySign_Frame:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[1].x	= Fuli_MonthlySign_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_MonthlySign_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_MonthlySign_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_MonthlySign_Button3tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[2].x	= Fuli_MonthlySign_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_MonthlySign_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_MonthlySign_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_MonthlySign_Button5tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[3].x	= Fuli_MonthlySign_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_MonthlySign_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_MonthlySign_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_MonthlySign_Button7tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[4].x	= Fuli_MonthlySign_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_MonthlySign_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_MonthlySign_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_MonthlySign_Button8tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[5].x	= Fuli_MonthlySign_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_MonthlySign_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_MonthlySign_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_MonthlySign_Button9tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[6].x	= Fuli_MonthlySign_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_MonthlySign_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_MonthlySign_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_MonthlySign_Button10tips:GetProperty("UnifiedYPosition");

end

function Fuli_MonthlySign_OnShown()
	--刷新服务器时间
	AskServerTimeAgain();
	 
	if  Fuli_MonthlySign_isSpecialMonth() == 1 then
		Fuli_MonthlySign_DragTitle:SetText("#{MYQD_170721_02}")  
	else --这个代表的是 过了特殊日期 还没更新xml这几天 恢复原来的签到福利显示
		if Fuli_MonthlySign_Normal ~= nil then
			Fuli_MonthlySign_DragTitle:SetText("#{MYQD_170721_01}")
		end
		if Fuli_MonthlySign_Summer ~= nil then
			Fuli_MonthlySign_DragTitle:SetText("#{MYQD_170721_01}")
		end
		if Fuli_MonthlySign_Red ~= nil then
			Fuli_MonthlySign_DragTitle:SetText("#{MYQD_170721_01}") 
		end
	end	 
	
	--g_ButtonPos 里面的索引
	local nShaoDang 		= 2
	local nOneDay 			= 3
	local nHuiGui 			= 4
	local nSuperSave		= 5
	local nZhanLing =6
		
		-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)then
		Fuli_MonthlySign_Button3 : Hide();
		
		nShaoDang = nShaoDang-1 
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	--	return
	else
		Fuli_MonthlySign_Button3 : Show();
			
	end	

	local nLevel = Player:GetLevel();
	
	Fuli_MonthlySign_Button5:Show()
	if ( nLevel < 60 ) then
		Fuli_MonthlySign_Button5:Hide()
		nShaoDang = -1 
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	end

	nOneDay = -1
	if nOneDay == -1  then
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
		Fuli_MonthlySign_Button7:Hide()
	end
	
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_MonthlySign_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_MonthlySign_Button8 : Hide()
		nHuiGui   = - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	end

	if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
		Fuli_MonthlySign_Button9 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
		Fuli_MonthlySign_Button9 : Hide()
		nSuperSave =-1; 
		nZhanLing = nZhanLing -1
	end

	Fuli_MonthlySign_Button10:Show()
		if ( nLevel < 30 ) then
			Fuli_MonthlySign_Button10:Hide()
			nZhanLing = nZhanLing -1
		end
	
	
	
	if nShaoDang ~= -1 then
		Fuli_MonthlySign_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		Fuli_MonthlySign_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		Fuli_MonthlySign_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		Fuli_MonthlySign_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);
		
	end
	
	if nOneDay ~= -1 then
		Fuli_MonthlySign_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		Fuli_MonthlySign_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		Fuli_MonthlySign_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		Fuli_MonthlySign_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
		
	end
	
	if nHuiGui ~= -1 then
		Fuli_MonthlySign_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
		Fuli_MonthlySign_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
		Fuli_MonthlySign_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
		Fuli_MonthlySign_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
	end
	
	
	if nSuperSave ~= -1 then
		Fuli_MonthlySign_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].x);
		Fuli_MonthlySign_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].y);
		Fuli_MonthlySign_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].tipx);
		Fuli_MonthlySign_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].tipy);
	end

	if nZhanLing ~= -1 then
		Fuli_MonthlySign_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
		Fuli_MonthlySign_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
		Fuli_MonthlySign_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
		Fuli_MonthlySign_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
	end
	
	if g_Fuli_MonthlySign_curMonth < 1 or g_Fuli_MonthlySign_curMonth > 12 then
		return
	end

	if g_Fuli_MonthlySign_daycount < 28 or g_Fuli_MonthlySign_daycount > 31 then
		return
	end
	Fuli_MonthlySign_Month_Number:SetProperty("Image", g_Fuli_MonthlySign_Month[g_Fuli_MonthlySign_curMonth]);
	
	if Fuli_MonthlySign_isSpecialMonth()  == 1 then 
		Fuli_MonthlySign_Explain1:SetText("#{MYQD_170621_03}") 
	else 
		Fuli_MonthlySign_Explain1:SetText("#{MYQD_150513_05}")
	end
	local check  = tonumber(NpcShop:GetResignDirectly());
	if(check>=1)then
		Fuli_MonthlySign_YuanbaoCheck:SetCheck(0);
	else
		Fuli_MonthlySign_YuanbaoCheck:SetCheck(1);
	end

	local curDay = math.mod(g_Fuli_MonthlySign_curDay, 100);
	g_Fuli_MonthlySign_SignCount = 0;

	local canResign = 0;
	for i=1,  g_Fuli_MonthlySign_daycount do
		g_Fuli_MonthlySign_TodayImage[i]:Hide();
		g_Fuli_MonthlySign_Mark[i]:Hide();
		g_Fuli_MonthlySign_DateButton[i]:Hide();
		if i <= curDay then
			if i  == curDay then
				g_Fuli_MonthlySign_TodayImage[i]:Show();
			end
			local signflag =  DataPool:Lua_GetBinaryData(g_Fuli_MonthlySign_SignFlagData, i-1 );
			if signflag == 1 then --已签到状态
				g_Fuli_MonthlySign_SignCount=g_Fuli_MonthlySign_SignCount+1;
				g_Fuli_MonthlySign_Mark[i]:Show();
			else  --可补签状态
				if i < curDay then
					canResign = 1;
					g_Fuli_MonthlySign_DateButton[i]:Show();
				end
			end
		end
	end
	
	if g_Fuli_MonthlySign_daycount > 28 then
		for i=29, g_Fuli_MonthlySign_daycount do
			g_Fuli_MonthlySign_HideButton[i]:Show();
		end
	end

	for i=g_Fuli_MonthlySign_daycount+1, 31 do
		g_Fuli_MonthlySign_HideButton[i]:Hide();
	end

	local ubit = math.floor( g_Fuli_MonthlySign_SignCount/10);
	local lbit = math.mod(g_Fuli_MonthlySign_SignCount, 10);
	if ubit == 0 then
		Fuli_MonthlySign_Date_Number1:SetProperty("Image", "");
	else
		Fuli_MonthlySign_Date_Number1:SetProperty("Image", g_Fuli_MonthlySign_Figure[ubit] );
	end
	Fuli_MonthlySign_Date_Number2:SetProperty("Image", g_Fuli_MonthlySign_Figure[lbit] );

	--今日签到按钮
	local todayflag = DataPool:Lua_GetBinaryData(g_Fuli_MonthlySign_SignFlagData, curDay-1 );
	if todayflag == 1 then
	           --按钮置灰
		Fuli_MonthlySign_Date_Sign:Disable();
		--设置按钮文本"已签到"
		Fuli_MonthlySign_Date_Sign:SetText("#{MYQD_150513_06}")
		--取消动画闪烁
		Fuli_MonthlySign_Date_Sign_Animate:Play(false)
	else
	          --按钮可用
		Fuli_MonthlySign_Date_Sign:Enable();
		--设置按钮文本"今日签到"
		Fuli_MonthlySign_Date_Sign:SetText("#{MYQD_150513_09}")
		--显示动画闪烁
		Fuli_MonthlySign_Date_Sign_Animate:Play(true)
	end

	--补签按钮
	if canResign == 1 then
		Fuli_MonthlySign_Date_ReSign:Enable();
	else
		Fuli_MonthlySign_Date_ReSign:Disable();
	end

	local PrizeButton = 0;
	for i=1, 5 do
		if g_Fuli_MonthlySign_SignCount >= g_Fuli_MonthlySign_SignDay[i] and g_Fuli_MonthlySign_GetPrizeFlag[i] == 0 then
			PrizeButton = i;
		end
	end
	if PrizeButton ~= 0 then
		g_Fuli_MonthlySign_curDayButton = PrizeButton
	end
	Fuli_MonthlySign_SignCountClicked(g_Fuli_MonthlySign_curDayButton);

	Fuli_MonthlySign_Button1:SetCheck(1)
	Fuli_MonthlySign_Button2:SetCheck(0)
	Fuli_MonthlySign_Button3:SetCheck(0)
	Fuli_MonthlySign_Button5:SetCheck(0)
	Fuli_MonthlySign_Button7:SetCheck(0)
	Fuli_MonthlySign_Button8:SetCheck(0)
	Fuli_MonthlySign_Button9:SetCheck(0)
	Fuli_MonthlySign_Refresh_ButtonTips()
--PushDebugMessage("MonthlySign")
	this:Show();
end

function Fuli_MonthlySign_isSpecialMonth()
	for i=1, table.getn(g_Fuli_MonthlySign_Spec_Month) do
		if g_Fuli_MonthlySign_Spec_Month[i] == g_Fuli_MonthlySign_curMonth and g_Fuli_MonthlySign_Spec_Year == GetCurrentServerYear() then
			return 1
		end
	end
	return 0
end
function Fuli_MonthlySign_UpdatePrizeItem(nIndex)

	local kajiType = KaJi:LuaFnGetKaJiType(6)
	local itemlist = g_Fuli_MonthlySign_ItemInfo[0][nIndex]; 
	if kajiType ~= nil and kajiType ~= 0 and g_Fuli_MonthlySign_ItemInfo[kajiType][nIndex] ~= nil then
		itemlist = g_Fuli_MonthlySign_ItemInfo[kajiType][nIndex]; 
	else
		itemlist = g_Fuli_MonthlySign_ItemInfo[0][nIndex]; 
	end
	
	if Player:GetData("Is2606S") == 1 then
		itemlist = g_Fuli_MonthlySign_ItemInfo_2606S[0][nIndex]; 
	end

	if Fuli_MonthlySign_isSpecialMonth() == 1 then 
		if kajiType ~= nil and kajiType ~= 0 and g_Fuli_MonthlySign_ItemInfo_Spec[kajiType][nIndex] ~= nil then
			itemlist = g_Fuli_MonthlySign_ItemInfo_Spec[kajiType][nIndex]; 
		else
			itemlist = g_Fuli_MonthlySign_ItemInfo_Spec[0][nIndex]; 
			if Player:GetData("IsOriginalJD") == 1 then
				itemlist = g_Fuli_MonthlySign_ItemInfo_Spec_OriginalJD[0][nIndex]; 
			end
			if Player:GetData("Is2606S") == 1 then
				itemlist = g_Fuli_MonthlySign_ItemInfo_Spec_2606S[0][nIndex]; 
			end
		end 
	end
	local cnt = table.getn(itemlist)
	DataPool:ClearMonthlySignItem();
	for i =1 , cnt do
		DataPool:CreateMonthlySignItem(itemlist[i].awardid, i-1,itemlist[i].num)
	end 
	for i = 1, 4 do
		if i <= cnt then
			local theAction = DataPool:CreateBindActionItemForShow(itemlist[i].awardid, itemlist[i].num) 
			if theAction:GetID() ~= 0 then
				g_Fuli_MonthlySign_PrizeItemList[i]:Show();
				g_Fuli_MonthlySign_PrizeItemList[i]:Enable();
				g_Fuli_MonthlySign_PrizeItemList[i]:SetActionItem(theAction:GetID())
			end
		else
			g_Fuli_MonthlySign_PrizeItemList[i]:Hide();
		end
	end
end
--今日签到按钮
function Fuli_MonthlySign_DateSignClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CheckTodaySign")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Fuli_MonthlySign_DateResignClicked(nIndex)
	if nIndex == nil then
		return
	end

	if nIndex < 1 then
		return
	end

	local IsYBConfirm = NpcShop:GetResignDirectly()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CheckResign")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_Parameter(1,IsYBConfirm)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end
function Fuli_MonthlySign_AutoResign()
	local curDay = math.mod(g_Fuli_MonthlySign_curDay, 100);
	for i=1, curDay-1 do
		local signflag =  DataPool:Lua_GetBinaryData(g_Fuli_MonthlySign_SignFlagData, i-1 );
		if signflag == 0 then
			Fuli_MonthlySign_DateResignClicked(i)
			break;
		end
	end
end

function Fuli_MonthlySign_SignCountClicked(nIndex)
	if nIndex == nil then
		return
	end

	if nIndex < 1  or nIndex > 5 then
		return
	end

	g_Fuli_MonthlySign_curDayButton = nIndex;

	g_Fuli_MonthlySign_GiftSign[nIndex]:SetProperty("Selected", "True")
	
	if Fuli_MonthlySign_Normal ~= nil then
		if g_Fuli_MonthlySign_SignCount >= g_Fuli_MonthlySign_SignDay[nIndex] then
			if g_Fuli_MonthlySign_GetPrizeFlag[nIndex] == 1 then --已领取
				Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
				Fuli_MonthlySign_Item_Pick:Disable();
			else
				Fuli_MonthlySign_Item_Pick:Enable();
			end
		else
			Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
			Fuli_MonthlySign_Item_Pick:Disable();
		end
	end
	if Fuli_MonthlySign_Summer ~= nil then
			if g_Fuli_MonthlySign_SignCount >= g_Fuli_MonthlySign_SignDay[nIndex] then
				if g_Fuli_MonthlySign_GetPrizeFlag[nIndex] == 1 then --已领取
					if SystemSetup : IsClassic() == 1 then
						Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:CommonFrame34 image:SignSummerButton_Yilingqu")
					else
						Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:CommonFrame31 image:SignSummerButton_Yilingqu")
					end
					Fuli_MonthlySign_Item_Pick:Disable();
				else
					Fuli_MonthlySign_Item_Pick:Enable();
				end
			else
				if SystemSetup : IsClassic() == 1 then
					Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:CommonFrame34 image:SignSummerButton_Weidacheng")
				else
					Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:CommonFrame31 image:SignSummerButton_Weidacheng")
				end
				Fuli_MonthlySign_Item_Pick:Disable();
			end		
	end
	if Fuli_MonthlySign_Red ~= nil then
		 if g_Fuli_MonthlySign_SignCount >= g_Fuli_MonthlySign_SignDay[nIndex] then
			if g_Fuli_MonthlySign_GetPrizeFlag[nIndex] == 1 then --已领取
				if SystemSetup : IsClassic() == 1 then
					Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Yilingqu")
				else
					Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Yilingqu")
				end
				Fuli_MonthlySign_Item_Pick:Disable();
			else
				Fuli_MonthlySign_Item_Pick:Enable();
			end
		else
			if SystemSetup : IsClassic() == 1 then
				Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Weidacheng")
			else
				Fuli_MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:Button24 image:SignSPButton_Weidacheng")
			end
			Fuli_MonthlySign_Item_Pick:Disable();
		end
	end 
	

	Fuli_MonthlySign_UpdatePrizeItem(nIndex);


end
function Fuli_MonthlySign_YuanbaoConfirm()
	if(NpcShop:GetResignDirectly() == 0)then
		NpcShop:SetResignDirectly(1);
	else
		NpcShop:SetResignDirectly(0);
	end
end
function Fuli_MonthlySign_GetPrize()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetPrize")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_Parameter(0,g_Fuli_MonthlySign_curDayButton)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--================================================
-- 界面的默认相对位置
--================================================
function Fuli_MonthlySign_ResetPos()
	Fuli_MonthlySign_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Fuli_MonthlySign_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Fuli_MonthlySign_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
	    Fuli_MonthlySign_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

function Fuli_MonthlySign_OnClosed()
	this:Hide();
end


function Fuli_MonthlySign_Button1_Click()
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name("OpenWindowRequest")
--		Set_XSCRIPT_ScriptID(891106)
--		Set_XSCRIPT_ParamCount(0)
--	Send_XSCRIPT()

end

function Fuli_MonthlySign_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end
	OpenStrongRoadDiaoWen(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_MonthlySign_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_MonthlySign_Button3_Click()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_MonthlySign_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_MonthlySign_Button4_Click()
	
end

function Fuli_MonthlySign_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end
	
	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,0);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
	OpenZhaoHui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_MonthlySign_Frame:GetProperty("UnifiedPosition"), 1) 
end


function Fuli_MonthlySign_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AddYongYanLog" )
		Set_XSCRIPT_ScriptID( 892473)
		Set_XSCRIPT_Parameter( 0, 7 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	Variable:SetVariable("SelfFuliUIPos", Fuli_MonthlySign_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_MonthlySign_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_MonthlySign_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_MonthlySign_Button9_Click()
	OpenSuperSaveUp(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_MonthlySign_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_MonthlySign_Button10_Click()
	local nLevel = Player:GetLevel();
	if( nLevel < 30 ) then
		PushDebugMessage("#{TLZL_190802_03}")	
		return
	end
	OpenZhanLing(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_MonthlySign_Frame:GetProperty("UnifiedPosition"), 1)
end
function Fuli_MonthlySign_Refresh_ButtonTips()


	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_MonthlySign_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_MonthlySign_Button7tips : Hide()
	end
	
	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_MonthlySign_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_MonthlySign_Button8tips : Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_MonthlySign_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_MonthlySign_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_MonthlySign_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_MonthlySign_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if nCharCreateDate ~= -1 and ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)then
			Fuli_MonthlySign_Button3tips : Hide()
			DataPool:Lua_SetRedPointInUIShow(39, 0)
		else
			Fuli_MonthlySign_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_MonthlySign_Button3tips : Hide()
	end


	
	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_MonthlySign_Button5tips : Show()
	else
		Fuli_MonthlySign_Button5tips : Hide()
	end
	
	
	-- 福利 累充 
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_MonthlySign_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_MonthlySign_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_MonthlySign_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_MonthlySign_Button10tips : Hide()
	end

	
end
