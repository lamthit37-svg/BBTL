--FuJiangTianLong.lua
--福降天龙界面
--2014.0306
--by liuyong



--**********************************
-- PRELOAD
--**********************************
local FuJiangTianLong_Exp = { --注意逻辑中，这个基础值又乘以了1.5
565908, --50
608880, --51
651853, --52
694825, --53
737797, --54
780769, --55
823742, --56
866714, --57
909686, --58
952659, --59
995631, --60
1038603, --61
1081575, --62
1124548, --63
1167520, --64
1210492, --65
1253465, --66
1296437, --67
1339409, --68
1382381, --69
1455354, --70
1513326, --71
1605002, --72
1710000, --73
1814997, --74
1919994, --75
2024991, --76
2108208, --77
2181510, --78
2254812, --79
2328114, --80
2401416, --81
2474719, --82
2548021, --83
2621323, --84
2694625, --85
2767927, --86
2841229, --87
2914531, --88
3061136, --89
3207740, --90
3354344, --91
3500948, --92
3647553, --93
3794157, --94
3940761, --95
4087365, --96
4233970, --97
4380574, --98
4527178, --99
4673782, --100
4820387, --101
4966991, --102
5113595, --103
5260199, --104
5406804, --105
5553408, --106
5700012, --107
5846616, --108
5993221, --109
6139825, --110
6286429, --111
6433033, --112
6579637, --113
6726242, --114
6872846, --115
7019450, --116
7166054, --117
7312659, --118
7459263, --119
7600988, --120
7745406, --121
7884823, --122
8026749, --123
8171230, --124
8310140, --125
8451412, --126
8595086, --127
8732607, --128
8872328, --129
}
local FuJiangTianLong_g_Refix = {
0.1,
0.2,
0.35,
}

local g_TargetId = -1-- npcid
local g_ObjCaredID = -1-- 关注npc
local MAX_OBJ_DISTANCE = 3.0

function FuJiangTianLong_PreLoad()
	this:RegisterEvent("OPEN_FUJIANG_TL" );	--打开界面
	this:RegisterEvent( "UPDATE_SERVER_TIME_UI" );			-- 同步服务器时间
	this:RegisterEvent( "UNIT_LEVEL" );						-- 玩家升级
	this:RegisterEvent("UI_COMMAND");
	-- 离开此场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent( "OBJECT_CARED_EVENT", false )
end

function FuJiangTianLong_OnLoad()
end

--**********************************
-- ONEvent
--**********************************
function FuJiangTianLong_OnEvent( event )
	if ( event == "OPEN_FUJIANG_TL" ) then
		-- 其它时间
		if not this:IsVisible() then
			-- 请求服务器时间
			AskServerTimeAgain();
			FuJiangTianLong_RefreshInfo()
			this:Show();			
			-- 关注npc
			g_TargetId = tonumber(arg0)
			g_ObjCaredID = DataPool : GetNPCIDByServerID(g_TargetId)
			if g_ObjCaredID ~= -1 then								
					this:CareObject(g_ObjCaredID, 1, "FuJiangTianLong")
			end
		else
			FuJiangTianLong_OnHiden()
		end
	elseif ( event == "UPDATE_SERVER_TIME_UI" ) then
		if ( this:IsVisible() ) then
			FuJiangTianLong_RefreshInfo()
		end
	elseif ( event == "UNIT_LEVEL" ) then
		--
		if ( this:IsVisible() ) then
			-- 更新
			FuJiangTianLong_RefreshInfo();
		end
	elseif ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 890509 then
			if ( Get_XParam_INT_Count() < 1 ) then
				return
			end
			if tonumber(arg0) == 0 then
				FuJiangTianLong_OnHiden()
			else
				FuJiangTianLong_RefreshInfo()
			end
		end
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		FuJiangTianLong_OnHiden()
	elseif (event == "OBJECT_CARED_EVENT") then	
		--AxTrace(0, 0, "arg0"..arg0.." arg1"..arg1.." arg2"..arg2);
		if(tonumber(arg0) ~= g_ObjCaredID) then
			return
		end		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if (arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			FuJiangTianLong_OnHiden()
		end
	end
end

function FuJiangTianLong_RefreshInfo()
	local Mission_Variable = DataPool:GetPlayerMission_DataRound(961);
	local lastBlessDay = math.mod(Mission_Variable,100000)

	local curDayTime = FuJiangTianLong_GetDayTime()

	local MidData = math.floor(Mission_Variable/100000)
	local lianxuDays = math.mod(MidData,100)

	local diffDays = 0;
	local curDayTimeYear = math.floor(curDayTime/1000)
	local lastDayTimeYear = math.floor(lastBlessDay/1000)
	if curDayTimeYear == lastDayTimeYear then
		diffDays = curDayTime - lastBlessDay
	elseif curDayTimeYear > lastDayTimeYear then
		if curDayTimeYear == lastDayTimeYear + 1 then
			local lastYearDays = math.mod(lastBlessDay,1000)
			local curYearDays = math.mod(curDayTime,1000)
			if math.mod(lastDayTimeYear, 4) == 0 then
				diffDays = 366 - lastYearDays + curYearDays
			else
				diffDays = 365 - lastYearDays + curYearDays
			end
		else
			diffDays = 3 + 1; ---这里默认x890509_g_MaxLianXuDays 这个值是小于365的
		end

	else
		return
	end

	if diffDays > lianxuDays then
		lianxuDays = 0
	elseif diffDays > 0 then
		lianxuDays = lianxuDays - (diffDays - 1)
	end
	--PushDebugMessage("ddd"..curDayTime)
	if curDayTime ~= lastBlessDay then	-- 今天没有祈福过
		--显示开始祈福
		FuJiangTianLong_Frame_QiFu2:Hide()
		FuJiangTianLong_Frame_QiFu:Show()
	else
		FuJiangTianLong_Frame_QiFu2:Show()
		FuJiangTianLong_Frame_QiFu:Hide()
		--显示已祈福
	end
	local nLevel = Player:GetData("LEVEL")
	local baseExp = FuJiangTianLong_Exp[nLevel - 49]
	if baseExp == nil then
		return
	end
	baseExp = baseExp * 1.5 --经验基础值修改为原来的1.5倍
	rewardExp = baseExp
	local rewardExp1 = math.floor(baseExp*(FuJiangTianLong_g_Refix[1] + 1))		--计算经验
	local rewardExp2 = math.floor(baseExp*(FuJiangTianLong_g_Refix[2] + 1))
	local rewardExp3 = math.floor(baseExp*(FuJiangTianLong_g_Refix[3] + 1))
	if lianxuDays > 0 and FuJiangTianLong_g_Refix[lianxuDays] ~= nil then
		rewardExp = math.floor(baseExp*(FuJiangTianLong_g_Refix[lianxuDays] + 1))		--计算经验
	end
	local needYuanbao = 200
	baseExp = math.floor(baseExp/10000)
	rewardExp1 = math.floor(rewardExp1/10000)
	rewardExp2 = math.floor(rewardExp2/10000)
	rewardExp3 = math.floor(rewardExp3/10000)
	rewardExp = math.floor(rewardExp/10000)
	local strTextFront = ScriptGlobal_Format("#{FJTL_140305_02}", tostring(needYuanbao))
	local strTextTail = ScriptGlobal_Format("#{FJTL_140305_19}", tostring(baseExp),tostring(rewardExp1),tostring(rewardExp2),tostring(rewardExp3))
	local strTextMid = ""
	if curDayTime == lastBlessDay then
		--明天祈福咋样
		strTextMid = ScriptGlobal_Format("#{FJTL_140305_18}",tostring(lianxuDays),tostring(rewardExp))
	else
		--今天咋样
		strTextMid = ScriptGlobal_Format("#{FJTL_140305_17}",tostring(lianxuDays),tostring(rewardExp))
	end
	FuJiangTianLong_Frame_Text:SetText(strTextFront..strTextMid..strTextTail)

	-- 单选框
	local bConfirm = NpcShop:GetFuJiangTLBuyDirectly();
	if ( bConfirm >= 1 ) then
		FuJiangTianLong_Frame_QR:SetCheck( 0 );
	else
		FuJiangTianLong_Frame_QR:SetCheck( 1 );
	end
end
function FuJiangTianLong_GetDayTime()
	local ServerDayTime = DataPool:GetServerDayTime()
	local CurrDay = math.mod(ServerDayTime, 100)
	local tempData = math.floor(ServerDayTime/100)
	local CurrMonth = math.mod(tempData, 100)
	local CurrYear = math.floor(ServerDayTime/10000)
	--local CurrYear,CurrMonth,CurrDay = SnsDataPool:GetCurrDay();
	--PushDebugMessage("ddd"..CurrMonth)
	local yearPart = math.mod(CurrYear,100)
	local dayPart = 0
	local smallMonth = {4,6,9,11}
	for i = 1, CurrMonth - 1 do
		if i == 2 then
			if math.mod(CurrYear,4) == 0 then
				dayPart = dayPart + 29
			else
				dayPart = dayPart + 28
			end
		else
			local findIt = 0;
			for j, TempVal in smallMonth do
				if TempVal == i then
					dayPart = dayPart + 30
					findIt = 1
					break
				end
			end
			if findIt == 0 then
				dayPart = dayPart + 31
			end
		end
	end
	return (yearPart*1000 + dayPart + CurrDay - 1)
end

function FuJiangTianLong_DoBless()
	local bConfirm = NpcShop:GetFuJiangTLBuyDirectly();
	if ( bConfirm >= 1 ) then
		-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoBless" ); 	-- 脚本号
			Set_XSCRIPT_ScriptID( 890509 );				-- 脚本编号
			Set_XSCRIPT_Parameter( 0, 0 );				-- 0:非活动界面 1:活动界面
			Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
		Send_XSCRIPT()
	else
		local nYuanBao, nDay, nExp = FuJiangTianLong_Getvariable();
		if ( nYuanBao ~= -1 and nDay ~= -1 and nExp ~= -1 ) then
			PushEvent( "TIANJIANGQIFU_CONFIRM", 0 );
		end
	end
end

function FuJiangTianLong_OnHiden()
	this:Hide()
	this:CareObject(g_ObjCaredID, 0, "FuJiangTianLong")
	if ( IsWindowShow( "MessageBox_Self" ) ) then
		CloseWindow( "MessageBox_Self", true );
	end
end


--*********************************
-- 获取[连续祈福天数][今日可获得经验]
--*********************************
function FuJiangTianLong_Getvariable()
	local Mission_Variable = DataPool:GetPlayerMission_DataRound(961);
	local lastBlessDay = math.mod(Mission_Variable,100000)

	local curDayTime = FuJiangTianLong_GetDayTime()

	local MidData = math.floor(Mission_Variable/100000)
	local lianxuDays = math.mod(MidData,100)

	local diffDays = 0;
	local curDayTimeYear = math.floor(curDayTime/1000)
	local lastDayTimeYear = math.floor(lastBlessDay/1000)
	if curDayTimeYear == lastDayTimeYear then
		diffDays = curDayTime - lastBlessDay
	elseif curDayTimeYear > lastDayTimeYear then
		if curDayTimeYear == lastDayTimeYear + 1 then
			local lastYearDays = math.mod(lastBlessDay,1000)
			local curYearDays = math.mod(curDayTime,1000)
			if math.mod(lastDayTimeYear, 4) == 0 then
				diffDays = 366 - lastYearDays + curYearDays
			else
				diffDays = 365 - lastYearDays + curYearDays
			end
		else
			diffDays = 3 + 1; ---这里默认x890509_g_MaxLianXuDays 这个值是小于365的
		end

	else
		return -1, -1, -1
	end

	if diffDays > lianxuDays then
		lianxuDays = 0
	elseif diffDays > 0 then
		lianxuDays = lianxuDays - (diffDays - 1)
	end

	local nLevel = Player:GetData("LEVEL")
	local baseExp = FuJiangTianLong_Exp[nLevel - 49]
	if baseExp == nil then
		return -1, -1, -1
	end
	baseExp = baseExp * 1.5 --经验基础值修改为原来的1.5倍
	rewardExp = baseExp
	if lianxuDays > 0 and FuJiangTianLong_g_Refix[lianxuDays] ~= nil then
		rewardExp = math.floor(baseExp*(FuJiangTianLong_g_Refix[lianxuDays] + 1))		--计算经验
	end
	local needYuanbao = 200
	baseExp = math.floor(baseExp/10000)
	rewardExp = math.floor(rewardExp/10000)
	local strTextMid = ""
	return needYuanbao, lianxuDays, rewardExp
end


--*********************************
-- 元宝购买确认
--*********************************
function FuJiangTianLongYuanBaoConfirm_Clicked()
	local bConfirm = FuJiangTianLong_Frame_QR:GetCheck();
	if ( bConfirm == 1 ) then
		FuJiangTianLong_Frame_QR:SetCheck( 1 );
		NpcShop:SetFuJiangTLBuyDirectly( 0 );
	elseif ( bConfirm == 0 ) then
		FuJiangTianLong_Frame_QR:SetCheck( 0 );
		NpcShop:SetFuJiangTLBuyDirectly( 1 );
	end
end
