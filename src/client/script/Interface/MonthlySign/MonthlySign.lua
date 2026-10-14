local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_MonthlySign_DateButton = {};
local g_MonthlySign_TodayImage = {};
local g_MonthlySign_HideButton = {};
local g_MonthlySign_PrizeItemList = {};
local g_MonthlySign_Month = {};
local g_MonthlySign_Mark = {};
local g_MonthlySign_Figure = {}; 
local g_MonthlySign_GiftSign = {};

local g_MonthlySign_curDay = 0;
local g_MonthlySign_curMonth = 0;
local g_MonthlySign_daycount = 0;
local g_MonthlySign_SignFlagData = 0;
local g_MonthlySign_SignCount = 0;
local g_MonthlySign_curDayButton = 1;
local g_MonthlySign_GetPrizeFlag={};


local g_MonthlySign_ItemInfo = {}; 
g_MonthlySign_ItemInfo[1] = 	{{awardid = 30607004, num = 1},{awardid = 30505217, num = 1}}
g_MonthlySign_ItemInfo[2] = 	{{awardid = 39920394, num = 1},{awardid = 30505215, num = 1}}
g_MonthlySign_ItemInfo[3] = 	{{awardid = 39920156, num = 1},{awardid = 20700063, num = 5}}
g_MonthlySign_ItemInfo[4] = 	{{awardid = 38000380, num = 1},{awardid = 38000992, num = 1},{awardid = 20700063, num = 5}}
g_MonthlySign_ItemInfo[5] = 	{{awardid = 30008130, num = 1},{awardid = 38000571, num = 1},{awardid = 20700063, num = 10}}	

local g_MonthlySign_SignDay = { 5, 10, 15, 20, 25}


function MonthlySign_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
end

function MonthlySign_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 89110601 then
		if ( Get_XParam_INT_Count() < 9 ) then
			return
		end
		g_MonthlySign_curDay = tonumber(Get_XParam_INT(0))
		g_MonthlySign_curMonth = tonumber(Get_XParam_INT(1))
		g_MonthlySign_daycount = tonumber(Get_XParam_INT(2))
		g_MonthlySign_SignFlagData = tonumber(Get_XParam_INT(3))
		for i = 1, 5 do
			g_MonthlySign_GetPrizeFlag[i] = tonumber(Get_XParam_INT(3+i))
		end
		MonthlySign_OnShown()
		DataPool:Lua_SetIsInSpringFlag( 0 )
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 89110602 then
		if ( Get_XParam_INT_Count() < 1 ) then
			return
		end
		g_MonthlySign_SignFlagData = tonumber(Get_XParam_INT(0))
		MonthlySign_OnShown()	
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 89110603 then
		if ( Get_XParam_INT_Count() < 5 ) then
			return
		end
		for i = 1, 5 do
			g_MonthlySign_GetPrizeFlag[i] = tonumber(Get_XParam_INT(i-1))
		end
		MonthlySign_OnShown()	
	elseif( event == "ADJEST_UI_POS" ) then
		MonthlySign_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MonthlySign_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function MonthlySign_OnLoad()
	g_MonthlySign_Month[1] = "set:Sign image:Signmonth_1";
	g_MonthlySign_Month[2] = "set:Sign image:Signmonth_2";
	g_MonthlySign_Month[3] = "set:Sign image:Signmonth_3";
	g_MonthlySign_Month[4] = "set:Sign image:Signmonth_4";
	g_MonthlySign_Month[5] = "set:Sign image:Signmonth_5";
	g_MonthlySign_Month[6] = "set:Sign image:Signmonth_6";
	g_MonthlySign_Month[7] = "set:Sign image:Signmonth_7";
	g_MonthlySign_Month[8] = "set:Sign image:Signmonth_8";
	g_MonthlySign_Month[9] = "set:Sign image:Signmonth_9";
	g_MonthlySign_Month[10] = "set:Sign image:Signmonth_10";
	g_MonthlySign_Month[11] = "set:Sign image:Signmonth_11";
	g_MonthlySign_Month[12] = "set:Sign image:Signmonth_12";
	
	g_MonthlySign_Mark[1] = MonthlySign_Date_1_Mark;
	g_MonthlySign_Mark[2] = MonthlySign_Date_2_Mark;
	g_MonthlySign_Mark[3] = MonthlySign_Date_3_Mark;
	g_MonthlySign_Mark[4] = MonthlySign_Date_4_Mark;
	g_MonthlySign_Mark[5] = MonthlySign_Date_5_Mark;
	g_MonthlySign_Mark[6] = MonthlySign_Date_6_Mark;
	g_MonthlySign_Mark[7] = MonthlySign_Date_7_Mark;
	g_MonthlySign_Mark[8] = MonthlySign_Date_8_Mark;
	g_MonthlySign_Mark[9] = MonthlySign_Date_9_Mark;
	g_MonthlySign_Mark[10] = MonthlySign_Date_10_Mark;
	g_MonthlySign_Mark[11] = MonthlySign_Date_11_Mark;
	g_MonthlySign_Mark[12] = MonthlySign_Date_12_Mark;
	g_MonthlySign_Mark[13] = MonthlySign_Date_13_Mark;
	g_MonthlySign_Mark[14] = MonthlySign_Date_14_Mark;
	g_MonthlySign_Mark[15] = MonthlySign_Date_15_Mark;
	g_MonthlySign_Mark[16] = MonthlySign_Date_16_Mark;
	g_MonthlySign_Mark[17] = MonthlySign_Date_17_Mark;
	g_MonthlySign_Mark[18] = MonthlySign_Date_18_Mark;
	g_MonthlySign_Mark[19] = MonthlySign_Date_19_Mark;
	g_MonthlySign_Mark[20] = MonthlySign_Date_20_Mark;
	g_MonthlySign_Mark[21] = MonthlySign_Date_21_Mark;
	g_MonthlySign_Mark[22] = MonthlySign_Date_22_Mark;
	g_MonthlySign_Mark[23] = MonthlySign_Date_23_Mark;
	g_MonthlySign_Mark[24] = MonthlySign_Date_24_Mark;
	g_MonthlySign_Mark[25] = MonthlySign_Date_25_Mark;
	g_MonthlySign_Mark[26] = MonthlySign_Date_26_Mark;
	g_MonthlySign_Mark[27] = MonthlySign_Date_27_Mark;
	g_MonthlySign_Mark[28] = MonthlySign_Date_28_Mark;
	g_MonthlySign_Mark[29] = MonthlySign_Date_29_Mark;
	g_MonthlySign_Mark[30] = MonthlySign_Date_30_Mark;
	g_MonthlySign_Mark[31] = MonthlySign_Date_31_Mark;
	
	g_MonthlySign_DateButton[1] = MonthlySign_Date_1_ReSign;
	g_MonthlySign_DateButton[2] = MonthlySign_Date_2_ReSign;
	g_MonthlySign_DateButton[3] = MonthlySign_Date_3_ReSign;
	g_MonthlySign_DateButton[4] = MonthlySign_Date_4_ReSign;
	g_MonthlySign_DateButton[5] = MonthlySign_Date_5_ReSign;
	g_MonthlySign_DateButton[6] = MonthlySign_Date_6_ReSign;
	g_MonthlySign_DateButton[7] = MonthlySign_Date_7_ReSign;
	g_MonthlySign_DateButton[8] = MonthlySign_Date_8_ReSign;
	g_MonthlySign_DateButton[9] = MonthlySign_Date_9_ReSign;
	g_MonthlySign_DateButton[10] = MonthlySign_Date_10_ReSign;
	g_MonthlySign_DateButton[11] = MonthlySign_Date_11_ReSign;
	g_MonthlySign_DateButton[12] = MonthlySign_Date_12_ReSign;
	g_MonthlySign_DateButton[13] = MonthlySign_Date_13_ReSign;
	g_MonthlySign_DateButton[14] = MonthlySign_Date_14_ReSign;
	g_MonthlySign_DateButton[15] = MonthlySign_Date_15_ReSign;
	g_MonthlySign_DateButton[16] = MonthlySign_Date_16_ReSign;
	g_MonthlySign_DateButton[17] = MonthlySign_Date_17_ReSign;
	g_MonthlySign_DateButton[18] = MonthlySign_Date_18_ReSign;
	g_MonthlySign_DateButton[19] = MonthlySign_Date_19_ReSign;
	g_MonthlySign_DateButton[20] = MonthlySign_Date_20_ReSign;
	g_MonthlySign_DateButton[21] = MonthlySign_Date_21_ReSign;
	g_MonthlySign_DateButton[22] = MonthlySign_Date_22_ReSign;
	g_MonthlySign_DateButton[23] = MonthlySign_Date_23_ReSign;
	g_MonthlySign_DateButton[24] = MonthlySign_Date_24_ReSign;
	g_MonthlySign_DateButton[25] = MonthlySign_Date_25_ReSign;
	g_MonthlySign_DateButton[26] = MonthlySign_Date_26_ReSign;
	g_MonthlySign_DateButton[27] = MonthlySign_Date_27_ReSign;
	g_MonthlySign_DateButton[28] = MonthlySign_Date_28_ReSign;
	g_MonthlySign_DateButton[29] = MonthlySign_Date_29_ReSign;
	g_MonthlySign_DateButton[30] = MonthlySign_Date_30_ReSign;
	g_MonthlySign_DateButton[31] = MonthlySign_Date_31_ReSign;
	
	g_MonthlySign_TodayImage[1] = MonthlySign_Date_1_Today;
	g_MonthlySign_TodayImage[2] = MonthlySign_Date_2_Today;
	g_MonthlySign_TodayImage[3] = MonthlySign_Date_3_Today;
	g_MonthlySign_TodayImage[4] = MonthlySign_Date_4_Today;
	g_MonthlySign_TodayImage[5] = MonthlySign_Date_5_Today;
	g_MonthlySign_TodayImage[6] = MonthlySign_Date_6_Today;
	g_MonthlySign_TodayImage[7] = MonthlySign_Date_7_Today;
	g_MonthlySign_TodayImage[8] = MonthlySign_Date_8_Today;
	g_MonthlySign_TodayImage[9] = MonthlySign_Date_9_Today;
	g_MonthlySign_TodayImage[10] = MonthlySign_Date_10_Today;
	g_MonthlySign_TodayImage[11] = MonthlySign_Date_11_Today;
	g_MonthlySign_TodayImage[12] = MonthlySign_Date_12_Today;
	g_MonthlySign_TodayImage[13] = MonthlySign_Date_13_Today;
	g_MonthlySign_TodayImage[14] = MonthlySign_Date_14_Today;
	g_MonthlySign_TodayImage[15] = MonthlySign_Date_15_Today;
	g_MonthlySign_TodayImage[16] = MonthlySign_Date_16_Today;
	g_MonthlySign_TodayImage[17] = MonthlySign_Date_17_Today;
	g_MonthlySign_TodayImage[18] = MonthlySign_Date_18_Today;
	g_MonthlySign_TodayImage[19] = MonthlySign_Date_19_Today;
	g_MonthlySign_TodayImage[20] = MonthlySign_Date_20_Today;
	g_MonthlySign_TodayImage[21] = MonthlySign_Date_21_Today;
	g_MonthlySign_TodayImage[22] = MonthlySign_Date_22_Today;
	g_MonthlySign_TodayImage[23] = MonthlySign_Date_23_Today;
	g_MonthlySign_TodayImage[24] = MonthlySign_Date_24_Today;
	g_MonthlySign_TodayImage[25] = MonthlySign_Date_25_Today;
	g_MonthlySign_TodayImage[26] = MonthlySign_Date_26_Today;
	g_MonthlySign_TodayImage[27] = MonthlySign_Date_27_Today;
	g_MonthlySign_TodayImage[28] = MonthlySign_Date_28_Today;
	g_MonthlySign_TodayImage[29] = MonthlySign_Date_29_Today;
	g_MonthlySign_TodayImage[30] = MonthlySign_Date_30_Today;
	g_MonthlySign_TodayImage[31] = MonthlySign_Date_31_Today;
	
	g_MonthlySign_HideButton[29] = MonthlySign_Date_29;
	g_MonthlySign_HideButton[30] = MonthlySign_Date_30;
	g_MonthlySign_HideButton[31] = MonthlySign_Date_31;
	
	g_MonthlySign_Figure[0] = "set:Sign image:Signgreen_0";
	g_MonthlySign_Figure[1] = "set:Sign image:Signgreen_1";
	g_MonthlySign_Figure[2] = "set:Sign image:Signgreen_2";
	g_MonthlySign_Figure[3] = "set:Sign image:Signgreen_3";
	g_MonthlySign_Figure[4] = "set:Sign image:Signgreen_4";
	g_MonthlySign_Figure[5] = "set:Sign image:Signgreen_5";
	g_MonthlySign_Figure[6] = "set:Sign image:Signgreen_6";
	g_MonthlySign_Figure[7] = "set:Sign image:Signgreen_7";
	g_MonthlySign_Figure[8] = "set:Sign image:Signgreen_8";
	g_MonthlySign_Figure[9] = "set:Sign image:Signgreen_9";
	
	g_MonthlySign_GiftSign[1] = MonthlySign_Gift_1;
	g_MonthlySign_GiftSign[2] = MonthlySign_Gift_2;
	g_MonthlySign_GiftSign[3] = MonthlySign_Gift_3;
	g_MonthlySign_GiftSign[4] = MonthlySign_Gift_4;
	g_MonthlySign_GiftSign[5] = MonthlySign_Gift_5;
	
	g_MonthlySign_PrizeItemList[1] = MonthlySign_Item1;
	g_MonthlySign_PrizeItemList[2] = MonthlySign_Item2;
	g_MonthlySign_PrizeItemList[3] = MonthlySign_Item3;
	g_MonthlySign_PrizeItemList[4] = MonthlySign_Item4;

		-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= MonthlySign_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= MonthlySign_Frame:GetProperty("UnifiedYPosition");

end

function MonthlySign_OnShown()
	if g_MonthlySign_curMonth < 1 or g_MonthlySign_curMonth > 12 then
		return
	end
	
	if g_MonthlySign_daycount < 28 or g_MonthlySign_daycount > 31 then
		return
	end
	MonthlySign_Month_Number:SetProperty("Image", g_MonthlySign_Month[g_MonthlySign_curMonth]);
		
	local check  = tonumber(NpcShop:GetResignDirectly());
	if(check>=1)then
		MonthlySign_YuanbaoCheck:SetCheck(0);
	else
		MonthlySign_YuanbaoCheck:SetCheck(1);
	end
		
	local curDay = math.mod(g_MonthlySign_curDay, 100);
	g_MonthlySign_SignCount = 0;
	
	local canResign = 0;
	for i=1,  g_MonthlySign_daycount do
		g_MonthlySign_TodayImage[i]:Hide();
		g_MonthlySign_Mark[i]:Hide();
		g_MonthlySign_DateButton[i]:Hide();
		if i <= curDay then  
			if i  == curDay then
				g_MonthlySign_TodayImage[i]:Show();
			end
			local signflag =  DataPool:Lua_GetBinaryData(g_MonthlySign_SignFlagData, i-1 );
			if signflag == 1 then --已签到状态
				g_MonthlySign_SignCount=g_MonthlySign_SignCount+1;
				g_MonthlySign_Mark[i]:Show();
			else  --可补签状态
				if i < curDay then
					canResign = 1;
					g_MonthlySign_DateButton[i]:Show();
				end
			end
		end
	end
	
	if g_MonthlySign_daycount > 28 then
		for i=29, g_MonthlySign_daycount do
			g_MonthlySign_HideButton[i]:Show();
		end
	end
	
	for i=g_MonthlySign_daycount+1, 31 do
		g_MonthlySign_HideButton[i]:Hide();
	end
	
	local ubit = math.floor( g_MonthlySign_SignCount/10);
	local lbit = math.mod(g_MonthlySign_SignCount, 10);
	if ubit == 0 then
		MonthlySign_Date_Number1:SetProperty("Image", "");
	else
		MonthlySign_Date_Number1:SetProperty("Image", g_MonthlySign_Figure[ubit] );
	end
	MonthlySign_Date_Number2:SetProperty("Image", g_MonthlySign_Figure[lbit] );
		
	--今日签到按钮
	local todayflag = DataPool:Lua_GetBinaryData(g_MonthlySign_SignFlagData, curDay-1 );
	if todayflag == 1 then
		MonthlySign_Date_Sign:Disable();
	else
		MonthlySign_Date_Sign:Enable();
	end
	
	--补签按钮
	if canResign == 1 then
		MonthlySign_Date_ReSign:Enable();
	else
		MonthlySign_Date_ReSign:Disable();
	end
	
	local PrizeButton = 0;
	for i=1, 5 do
		if g_MonthlySign_SignCount >= g_MonthlySign_SignDay[i] and g_MonthlySign_GetPrizeFlag[i] == 0 then
			PrizeButton = i;
		end
	end
	if PrizeButton ~= 0 then
		g_MonthlySign_curDayButton = PrizeButton
	end
	
	MonthlySign_SignCountClicked(g_MonthlySign_curDayButton);
	
	this:Show();
end

function MonthlySign_UpdatePrizeItem(nIndex)

	local itemlist = g_MonthlySign_ItemInfo[nIndex];
	local cnt = table.getn(itemlist)
	DataPool:ClearMonthlySignItem();
	for i =1 , cnt do
		DataPool:CreateMonthlySignItem(itemlist[i].awardid, i-1,itemlist[i].num)
	end
	
	for i = 1, 4 do
		if i <= cnt then
			local theAction = EnumAction(i-1, "monthlysign_item");
			if theAction:GetID() ~= 0 then
				g_MonthlySign_PrizeItemList[i]:Show();
				g_MonthlySign_PrizeItemList[i]:Enable();
				g_MonthlySign_PrizeItemList[i]:SetActionItem(theAction:GetID())
			end
		else
			g_MonthlySign_PrizeItemList[i]:Hide();
		end
	end
end
--今日签到按钮
function MonthlySign_DateSignClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CheckTodaySign")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()		
end

function MonthlySign_DateResignClicked(nIndex)
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
function MonthlySign_AutoResign()
	local curDay = math.mod(g_MonthlySign_curDay, 100);
	for i=1, curDay-1 do
		local signflag =  DataPool:Lua_GetBinaryData(g_MonthlySign_SignFlagData, i-1 );
		if signflag == 0 then
			MonthlySign_DateResignClicked(i)
			break;
		end
	end
end

function MonthlySign_SignCountClicked(nIndex)
	if nIndex == nil then
		return
	end

	if nIndex < 1  or nIndex > 5 then
		return
	end
	
	g_MonthlySign_curDayButton = nIndex;
	
	g_MonthlySign_GiftSign[nIndex]:SetProperty("Selected", "True")
		
	if g_MonthlySign_SignCount >= g_MonthlySign_SignDay[nIndex] then
		if g_MonthlySign_GetPrizeFlag[nIndex] == 1 then --已领取
			MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
			MonthlySign_Item_Pick:Disable();
		else
			MonthlySign_Item_Pick:Enable();
		end
	else
		MonthlySign_Item_Pick:SetProperty("DisabledImage", "set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
		MonthlySign_Item_Pick:Disable();
	end
	
	MonthlySign_UpdatePrizeItem(nIndex);
	
	
end
function MonthlySign_YuanbaoConfirm()
	if(NpcShop:GetResignDirectly() == 0)then
		NpcShop:SetResignDirectly(1);
	else
		NpcShop:SetResignDirectly(0);
	end
end
function MonthlySign_GetPrize()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetPrize")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_Parameter(0,g_MonthlySign_curDayButton)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--================================================
-- 界面的默认相对位置
--================================================
function MonthlySign_ResetPos()
	MonthlySign_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	MonthlySign_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function MonthlySign_OnClosed()
	this:Hide();
end
