local g_Friend_MaritalRelations_Frame_UnifiedXPosition = 0
local g_Friend_MaritalRelations_Frame_UnifiedYPosition = 0
local g_Timers = 0
local g_Seconds = 3
local g_Type = 0
local g_MarryRewardDate = 0;
local g_WeddingTime = 0;
local g_IsSetMarrayTitle = 0;	-- 是否显示婚龄称号

function Friend_MaritalRelations_PreLoad()

	this:RegisterEvent("FRIEND_MARITAL_RELATIONS");
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Friend_MaritalRelations_OnLoad()
	--PushDebugMessage("Friend_MaritalRelations_OnLoad...");
	g_Friend_MaritalRelations_Frame_UnifiedXPosition = Friend_MaritalRelations_Frame:GetProperty("UnifiedXPosition")
	g_Friend_MaritalRelations_Frame_UnifiedYPosition = Friend_MaritalRelations_Frame:GetProperty("UnifiedYPosition")
end

function Friend_MaritalRelations_ResetPos()
	Friend_MaritalRelations_Frame:SetProperty("UnifiedXPosition", g_Friend_MaritalRelations_Frame_UnifiedXPosition);
	Friend_MaritalRelations_Frame:SetProperty("UnifiedYPosition", g_Friend_MaritalRelations_Frame_UnifiedYPosition);
end

function Friend_MaritalRelations_OnEvent(event)
	if ( event == "FRIEND_MARITAL_RELATIONS" ) then
		Friend_MaritalRelations_SetDynamic_Pos();
		this:Show();
		Friend_MaritalRelations_Tab_Marry:SetCheck(1);
		Friend_MaritalRelations_Update();
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		Friend_MaritalRelations_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Friend_MaritalRelations_ResetPos()
	end
end

function Friend_MaritalRelations_Update()

	local marryYear = math.floor(arg2/100000000)+2000;
	local marryMonth = math.floor(math.mod(arg2,100000000)/1000000);
	local marryDay = math.floor(math.mod(arg2,1000000)/10000);
	local marryHour = math.floor(math.mod(arg2,10000)/100);
	--PushDebugMessage(marryYear.."_"..marryMonth.."_"..marryDay.."_"..marryHour.."Friend_MaritalRelations_Update..."..arg0.."_"..arg1.."_"..arg2.."_"..arg3.."_"..arg4);
	Friend_MaritalRelations_MateName:SetText(arg0);
	local strlen = string.len(arg1);
	if(0 == tonumber(arg2) or -1 == tonumber(arg2)) then
		Friend_MaritalRelations_WeddingDayDate:SetText("");
	else
		Friend_MaritalRelations_WeddingDayDate:SetText(marryYear.."年"..marryMonth.."月"..marryDay.."日"..marryHour.."时");
	end
	Friend_MaritalRelations_AggregateNum:SetText(arg3.."/18000");
	Friend_MaritalRelations_RealtimeNum:SetText(arg4.."/500");
	local weddingTime		= arg2;		--结婚日期
	local marryRewardDate	= arg5;		--领奖时间
	g_WeddingTime = arg2;
	g_MarryRewardDate = arg5;
	g_Type = tonumber(arg6);
	Friend_MaritalRelations_Show(weddingTime, marryRewardDate);
end

function Friend_MaritalRelations_Closed()
	--PushDebugMessage("Friend_MaritalRelations_Closed...");
	this:Hide();
end

-- 显示 婚龄 本月纪念礼领取日期 婚龄称谓 可领取纪念礼
function Friend_MaritalRelations_Show(weddingTime, marryRewardDate)
	g_IsSetMarrayTitle = 0;
	local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid();
	if(0 == isHaveSpouse) then
		Friend_MaritalRelations_MateName:SetText("#{HYGX_150515_129}");
		Friend_MaritalRelations_Stage:SetText("#{HYGX_150515_129}");
		Friend_MaritalRelations_WeddingDayDate:SetText("#{HYGX_150515_129}");
		Friend_MaritalRelations_MarriageTimeAge:SetText("#{HYGX_150515_129}");
		Friend_MaritalRelations_NextWeddingDayGiftName:SetText("#{HYGX_150515_129}");
		Friend_MaritalRelations_NextWeddingDayDate:SetText("#{HYGX_150515_129}");
		-- 不显示婚龄称号
		Friend_MaritalRelations_AgnameText:SetToolTip("#{HYGX_150515_174}");
		Friend_MaritalRelations_AgnameCheck:SetToolTip("#{HYGX_150515_174}");
		if (0 == g_Type) then		--夫妻时常的称号后缀标志
			Friend_MaritalRelations_AgnameCheck:SetCheck(1);
		else
			Friend_MaritalRelations_AgnameCheck:SetCheck(0);
		end
		return;
	end
	
	if(tonumber(weddingTime) < 10000) then
		Friend_MaritalRelations_MateName:SetText(arg0);
		Friend_MaritalRelations_WeddingDayDate:SetText("#{HYGX_150515_167}");
		Friend_MaritalRelations_MarriageTimeAge:SetText("#{HYGX_150515_169}");
		Friend_MaritalRelations_NextWeddingDayDate:SetText("#{HYGX_150515_169}");
		Friend_MaritalRelations_Stage:SetText("#{HYGX_150515_168}");
		Friend_MaritalRelations_NextWeddingDayGiftName:SetText("#{HYGX_150515_168}");
		-- 不显示婚龄称号
		Friend_MaritalRelations_AgnameText:SetToolTip("#{HYGX_150515_174}");
		Friend_MaritalRelations_AgnameCheck:SetToolTip("#{HYGX_150515_174}");
		if (0 == g_Type) then		--夫妻时常的称号后缀标志
			Friend_MaritalRelations_AgnameCheck:SetCheck(1);
		else
			Friend_MaritalRelations_AgnameCheck:SetCheck(0);
		end
		return;
	end
	--PushDebugMessage("Friend_MaritalRelations_Show...");
	local marryYear = math.floor(weddingTime/100000000)+2000;
	local marryMonth = math.floor(math.mod(weddingTime,100000000)/1000000);
	local marryday = math.floor(math.mod(weddingTime,1000000)/10000);
	local weddingDate = ZhanTuanInterface:GetGivenDWORDTime(marryYear, marryMonth, marryday, 0, 0);
	AskServerTimeAgain();
	local ServerDayTime = DataPool:GetServerDayTime();
	local year = math.floor(ServerDayTime/10000);
	local month = math.floor(math.mod(ServerDayTime,10000)/100);
	local day = math.mod(ServerDayTime,100);
	
	local nowTime = ZhanTuanInterface:GetGivenDWORDTime( year, month, day, 0, 0)
	local beforeTime = nowTime - 3*24*3600;
	local lasterTime = nowTime + 3*24*3600;

	local beforeCurTime = nowTime - 3*24*3600;
	local lasterCurTime = nowTime + 3*24*3600;
	local beforeCuryear, beforeCurmonth, beforeCurday = ZhanTuanInterface:GetConvertUT(beforeCurTime);
	local lasterCuryear, lasterCurmonth, lasterCurday = ZhanTuanInterface:GetConvertUT(lasterCurTime);
	local beforeDay = ZhanTuanInterface:GetDaysInMonth(beforeCuryear, beforeCurmonth);
	local curDay = ZhanTuanInterface:GetDaysInMonth(year,month);
	local lasterDay = ZhanTuanInterface:GetDaysInMonth(lasterCuryear,lasterCurmonth);
	local _lasterDay = lasterDay;
	if(beforeDay>marryday) then
		beforeDay = marryday;
	end
	if(curDay>marryday) then
		curDay = marryday;
	end
	if(lasterDay>marryday) then
		lasterDay = marryday;
	end
	
	local curNowTime = ZhanTuanInterface:GetGivenDWORDTime(year, month, curDay, 0, 0)
	local beforeNowTime = ZhanTuanInterface:GetGivenDWORDTime(beforeCuryear, beforeCurmonth, beforeDay, 0, 0)
	local lasterNowTime = ZhanTuanInterface:GetGivenDWORDTime(lasterCuryear, lasterCurmonth, lasterDay, 0, 0)
	local marryThisMonth = 0;
	local nStatus = 0;
	if (beforeTime<=curNowTime and curNowTime<=lasterTime) then
		nStatus = 1;
		marryThisMonth = curNowTime;
	end
	if (beforeTime<=beforeNowTime and beforeNowTime<=lasterTime) then
		nStatus = 1;
		marryThisMonth = beforeNowTime;
	end
	if (beforeTime<=lasterNowTime and lasterNowTime<=lasterTime) then
		nStatus = 1;
		marryThisMonth = lasterNowTime;
	end
	
	if (0 == nStatus) then
		marryThisMonth = ZhanTuanInterface:GetGivenDWORDTime(year, month, marryday, 0, 0)
	end
	
	-- 取出下一个月
	local lasterMonthYear, lasterMonthMonth, lasterMonthDay = 0;
	if((tonumber(weddingDate + 3*24*3600)>=tonumber(nowTime)) or (tonumber(beforeTime)<=tonumber(marryRewardDate) and tonumber(marryRewardDate)<=tonumber(lasterTime)) or tonumber(marryThisMonth + 3*24*3600)<tonumber(nowTime)) then
		local tmp_year, tmp_month, tmp_day = ZhanTuanInterface:GetConvertUT(marryThisMonth);
		local curMonthOneDay = ZhanTuanInterface:GetGivenDWORDTime(tmp_year, tmp_month, 1, 0, 0)
		local lasterMonthTime = curMonthOneDay + 31*24*3600;
		lasterMonthYear, lasterMonthMonth, lasterMonthDay = ZhanTuanInterface:GetConvertUT(lasterMonthTime);
		lasterMonthDay = marryday;
		-- 取出下一个月最后一天
		local tmpMarryday = ZhanTuanInterface:GetDaysInMonth(lasterMonthYear,lasterMonthMonth);
		if (tmpMarryday < lasterMonthDay) then		-- 如果下个月最后一天小于结婚日期，则结婚日期改成下个月的最后一天
			lasterMonthDay = tmpMarryday;
		end
		marryThisMonth = ZhanTuanInterface:GetGivenDWORDTime(lasterMonthYear, lasterMonthMonth, lasterMonthDay, 0, 0)
	end
	
	if (0 == g_Type) then		--夫妻时常的称号后缀标志
		Friend_MaritalRelations_AgnameCheck:SetCheck(1);
	else
		Friend_MaritalRelations_AgnameCheck:SetCheck(0);
	end
	--local marryThisMonthYear, marryThisMonthMonth, marryThisMonthDay = ZhanTuanInterface:GetConvertUT(marryThisMonth);
	--local diffYear = marryThisMonthYear - marryYear;
	--local diffMonth = diffYear*12 + marryThisMonthMonth - marryMonth;
	
	--本月纪念礼领取日期
	Friend_MaritalRelations_RewardDate(marryThisMonth);
	
	-- 婚龄
	local diffMonth = Friend_MaritalRelations_HunLing(year,month,day,marryYear,marryMonth,marryday);
	
	-- 是否显示婚龄称号
	if (tonumber(diffMonth) < 2) then
		Friend_MaritalRelations_AgnameCheck:SetToolTip("#{HYGX_150515_174}");
		Friend_MaritalRelations_AgnameText:SetToolTip("#{HYGX_150515_174}");
	elseif (tonumber(marryRewardDate) < 10000) then
		Friend_MaritalRelations_AgnameCheck:SetToolTip("#{HYGX_150515_179}");
		Friend_MaritalRelations_AgnameText:SetToolTip("#{HYGX_150515_179}");
	else
		Friend_MaritalRelations_AgnameCheck:SetToolTip("#{HYGX_150515_175}");
		Friend_MaritalRelations_AgnameText:SetToolTip("#{HYGX_150515_175}");
		g_IsSetMarrayTitle = 1;
	end
	Friend_MaritalRelations_AgnameCheck:Show();
	Friend_MaritalRelations_AgnameText:Show();
	
	-- 婚龄称谓
	local szTitleName = Friend_MaritalRelations_AwardCharTitle(diffMonth);
	if("" ~= szTitleName) then
		Friend_MaritalRelations_Stage:SetText(szTitleName);
	else
		Friend_MaritalRelations_Stage:SetText("新婚");
	end
	
	-- 可领取纪念礼
	Friend_MaritalRelations_JiNianLi(diffMonth);
	
end

--本月纪念礼领取日期
function Friend_MaritalRelations_RewardDate(marryThisMonth)
	local beforeCurTime = marryThisMonth - 3*24*3600;
	local lasterCurTime = marryThisMonth + 3*24*3600;
	local beforeCuryear, beforeCurmonth, beforeCurday = ZhanTuanInterface:GetConvertUT(beforeCurTime);
	local lasterCuryear, lasterCurmonth, lasterCurday = ZhanTuanInterface:GetConvertUT(lasterCurTime);
	
	--PushDebugMessage("本月纪念礼领取日期:"..beforeCurmonth..":"..beforeCurday.."--->"..lasterCurmonth..":"..lasterCurday);
	Friend_MaritalRelations_NextWeddingDayDate:SetText(beforeCurmonth.."月"..beforeCurday.."日至"..lasterCurmonth.."月"..lasterCurday.."日");
end

-- 婚龄
function Friend_MaritalRelations_HunLing(year,month,day,marryYear,marryMonth,marryday)

	-- 计算出上个月的天数
	local monthStatus = 0;
	local yearStatus = 0;
	local beforeMonth = month - 1;
	local beforeyear = year;
	if(beforeMonth == 0) then
		beforeMonth = 12;
		beforeyear = beforeyear -1;
	end
	local beforeDaysInMonth = ZhanTuanInterface:GetDaysInMonth(beforeyear, beforeMonth);
	
	local hunlingYear = 0;
	local hunlingMonth = 0;
	local hunlingDay = 0;
	if(day >= marryday) then	--当前日期天大于结婚日期天
		hunlingDay = day - marryday;
	else
		hunlingDay = day + beforeDaysInMonth - marryday;
		monthStatus = 1;	-- 月减少一个月了
	end
	
	if(month-monthStatus >= marryMonth) then	--当前日期月大于结婚日期月
		hunlingMonth = month-monthStatus - marryMonth;
	else
		hunlingMonth = month-monthStatus + 12 - marryMonth;
		yearStatus = 1;
	end
	
	if(year-yearStatus >= marryYear) then	--当前日期月大于结婚日期月
		hunlingYear = year - yearStatus - marryYear;
	else
		PushDebugMessage("error");
	end
	--PushDebugMessage("婚龄:"..hunlingMonth.."月"..hunlingDay.."天");
	local monthCount = hunlingYear*12 + hunlingMonth;
	if(tonumber(monthCount) <= 0 and tonumber(hunlingDay) <= 0) then
		Friend_MaritalRelations_MarriageTimeAge:SetText("#{HYGX_150515_166}");
	else
		local strHunlingYear = "";
		local strHunlingMonth = "";
		local strHunlingDay = "";
		if( tonumber(hunlingYear) > 0 ) then
			strHunlingYear = hunlingYear.."年";
		end
		if( tonumber(hunlingMonth) > 0 ) then
			strHunlingMonth = hunlingMonth.."月";
		end
		if( tonumber(hunlingDay) > 0 ) then
			strHunlingDay = hunlingDay.."天";
		end
		Friend_MaritalRelations_MarriageTimeAge:SetText(strHunlingYear..strHunlingMonth..strHunlingDay);
	end
	
	-- 如果玩家在本月结婚日期的前三天之内，则月份+1
	if(hunlingDay+3 >= beforeDaysInMonth) then
		monthCount = monthCount + 1;
	end
	return monthCount;
end

-- 可领取纪念礼
function Friend_MaritalRelations_JiNianLi(diffMonth)
	
	local itemName = "";
	if(diffMonth <= 6) then
		itemName = "#{HYGX_150515_117}";
	elseif(diffMonth <= 12) then
		itemName = "#{HYGX_150515_118}";
	elseif(diffMonth <= 18) then
		itemName = "#{HYGX_150515_119}";
	elseif(diffMonth > 18) then
		itemName = "#{HYGX_150515_120}";
	end
	if("" ~= itemName) then
		--PushDebugMessage(itemName);
		Friend_MaritalRelations_NextWeddingDayGiftName:SetText(itemName);
	end
	
end
--==================================
-- 称号
--==================================
function Friend_MaritalRelations_AwardCharTitle( diffMonth)

	local marrytitlename = {
	"",					--小于2个月
	"纸婚",				--2个月
	"丝婚",				--4个月
	"木婚",				--6个月
	"花边婚",			--8个月
	"象牙婚",			--10个月
	"水晶婚",			--12个月
	"银婚",				--14个月
	"珍珠婚",			--16个月
	"珊瑚婚",			--18个月
	"金婚",				--20个月
	"翠玉婚",			--22个月
	"钻石婚",			--24个月
	};
	local szTitleName = "";
	if(diffMonth<2) then
		szTitleName = marrytitlename[1];
	elseif(diffMonth<4) then
		szTitleName = marrytitlename[2];
	elseif(diffMonth<6) then
		szTitleName = marrytitlename[3];
	elseif(diffMonth<8) then
		szTitleName = marrytitlename[4];
	elseif(diffMonth<10) then
		szTitleName = marrytitlename[5];
	elseif(diffMonth<12) then
		szTitleName = marrytitlename[6];
	elseif(diffMonth<14) then
		szTitleName = marrytitlename[7];
	elseif(diffMonth<16) then
		szTitleName = marrytitlename[8];
	elseif(diffMonth<18) then
		szTitleName = marrytitlename[9];
	elseif(diffMonth<20) then
		szTitleName = marrytitlename[10];
	elseif(diffMonth<22) then
		szTitleName = marrytitlename[11];
	elseif(diffMonth<24) then
		szTitleName = marrytitlename[12];
	elseif(diffMonth>=24) then
		szTitleName = marrytitlename[13];
	end
	return szTitleName;
end

function ShuaXin_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end

-- 师徒
function Friend_MaritalRelations_ShiTu()
    Variable:SetVariable("SelfFriendClanUnionPos", Friend_MaritalRelations_Frame:GetProperty("UnifiedPosition"), 1);
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskShiMenInfo")
		Set_XSCRIPT_ScriptID(891116)
		Set_XSCRIPT_Parameter(0,2);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	--this:Hide();
end

-- 结拜
function Friend_MaritalRelations_JieBai()
    Variable:SetVariable("SelfFriendClanUnionPos", Friend_MaritalRelations_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("NEWFRIEND_JIEBAI_OPEN")
	--this:Hide();
end

-- 修改夫妻时常的称号后缀
function Friend_MaritalRelations_ModifyCharTitle()
	--CD时间
	if not ShuaXin_PassTime(g_Seconds) then
		PushDebugMessage("#{ZYPT_081127_2}");
		Friend_MaritalRelations_AgnameCheck:SetCheck(tonumber(g_Type));
		return
	end
	
	-- 是否有结婚日期
	if(tonumber(g_WeddingTime) < 1) then
		PushDebugMessage("#{HYGX_150515_176}");
		Friend_MaritalRelations_AgnameCheck:SetCheck(tonumber(g_Type));
		return;
	end
	
	-- 已婚，婚龄不足2月/已婚，婚龄满2月，但未领取过婚龄称号
	if (tonumber(g_MarryRewardDate) < 10000) then
		PushDebugMessage("#{HYGX_150515_176}");
		Friend_MaritalRelations_AgnameCheck:SetCheck(tonumber(g_Type));
		return;
	end
	
	if (tonumber(g_IsSetMarrayTitle) == 0) then
		PushDebugMessage("#{HYGX_150515_176}");
		Friend_MaritalRelations_AgnameCheck:SetCheck(tonumber(g_Type));
		return;
	end
	
	if(tonumber(g_Type) == 0) then
		g_Type = 1;
	else
		g_Type = 0;
	end
	
	Friend_MaritalRelations_AgnameCheck:SetCheck(tonumber(g_Type));
	--PushDebugMessage(Friend_MaritalRelations_AgnameCheck:GetCheck().."nType:"..g_Type);

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ModifyCharTitle")
		Set_XSCRIPT_ScriptID(000093)
		Set_XSCRIPT_Parameter(0,g_Type);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	return;
end

function Friend_MaritalRelations_SetDynamic_Pos()
	if (IsWindowShow( "NewFriend_ST")) then
		CloseWindow( "NewFriend_ST", true );
	elseif ( IsWindowShow( "NewFriend_Jiebai" ) ) then
		CloseWindow( "NewFriend_Jiebai", true );
	end
	if ( IsWindowShow( "Friend_Recall" ) ) then
		CloseWindow( "Friend_Recall", true );
	end	
    local selfFriendClanUnionPos = Variable:GetVariable("SelfFriendClanUnionPos")
	if( selfFriendClanUnionPos ~= nil) then
	    Friend_MaritalRelations_Frame:SetProperty("UnifiedPosition", selfFriendClanUnionPos )
	end
end

--打开关于界面
function Friend_MaritalRelations_FQ_OpenInfo(infotype)
	PushEvent("OPEN_FUQICHENGHAO",infotype)
end
