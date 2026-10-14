-- [福降天龙优惠活动] add by DuanXiaoTong
-- PushDebugMessage
-- !!!reloadscript =FuJiangTianLongHD
-- !!createitem =38002908 ==1
-- ============================================
local g_Controls = {};									-- 控件
local g_FuJiangTianLongActivityRefix = { 0.03, 0.06, 0.10 }		-- 连续天数对应的经验增长(活动)
local g_FuJiangTianLongOriginalRefix = { 0.1, 0.2, 0.35 }		-- 连续天数对应的经验增长(原始)
-- 非活动期间给的经验值
local g_FuJiangTianLongExp = { 							--注意逻辑中，这个基础值又乘以了1.5
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
-- 活动给的经验值
local g_ActivityExp = {	-- 这里的经验值已经是乘以1.5倍了, 所以逻辑中无需再乘
1376080, -- 50
1477184, -- 51
1578850, -- 52
1681092, -- 53
1783920, -- 54
1887341, -- 55
1991373, -- 56
2096022, -- 57
2201302, -- 58
2307220, -- 59
2597078, -- 60
2712223, -- 61
2828041, -- 62
2944546, -- 63
3061744, -- 64
3179651, -- 65
3298274, -- 66
3417627, -- 67
3537720, -- 68
3658565, -- 69
4114361, -- 70
4280549, -- 71
4528182, -- 72
4808488, -- 73
5089600, -- 74
5371532, -- 75
5654290, -- 76
5885764, -- 77
6094360, -- 78
6303820, -- 79
6942736, -- 80
7375404, -- 81
7834434, -- 82
8321410, -- 83
8838014, -- 84
9386030, -- 85
9967345, -- 86
10583965, -- 87
11238012, -- 88
11931735, -- 89
12749704, -- 90
13312277, -- 91
13876110, -- 92
14441215, -- 93
15007599, -- 94
15575285, -- 95
16144280, -- 96
16714602, -- 97
17286262, -- 98
17859276, -- 99
19509158, -- 100
19580206, -- 101
19651715, -- 102
19723691, -- 103
19796137, -- 104
19869057, -- 105
19942454, -- 106
20016333, -- 107
20090697, -- 108
20165551, -- 109
20240899, -- 110
20316742, -- 111
20393089, -- 112
20469940, -- 113
20547300, -- 114
20625172, -- 115
20703563, -- 116
20782474, -- 117
20861910, -- 118
20941876, -- 119
21021842, -- 120
21102113, -- 121
21182849, -- 122
21263894, -- 123
21345249, -- 124
21427001, -- 125
21509066, -- 126
21591445, -- 127
21674269, -- 128
21757411, -- 129
};

local g_FJL_UICommand = 91020819

local g_FJL_ItemID = 38002908    --2019福降令id

local g_TargetId = -1-- npcid
local g_ObjCaredID = -1-- 关注npc
local MAX_OBJ_DISTANCE = 3.0

-- *************************
-- PreLoad
-- *************************
function FuJiangTianLongHD_PreLoad()
	this:RegisterEvent( "OPEN_FUJIANG_TL_HD" );				-- 打开界面
	this:RegisterEvent( "UPDATE_SERVER_TIME_UI" );			-- 同步服务器时间
	this:RegisterEvent( "UNIT_LEVEL" );						-- 玩家升级
	this:RegisterEvent( "UI_COMMAND" );						-- UI_COMMAND
	this:RegisterEvent( "HIDE_ON_SCENE_TRANSED", false );				-- 离开此场景
	this:RegisterEvent( "OBJECT_CARED_EVENT", false )
end


-- *************************
-- OnLoad
-- *************************
function FuJiangTianLongHD_OnLoad()
	-- 控件
	g_Controls = {
		-- 框架
		Framework = FuJiangTianLongHD_Frame;
		-- 按钮: 祈福
		BlessButton = FuJiangTianLongHD_Frame_QiFu;
		-- 图片: 祈福
		BlessImage = FuJiangTianLongHD_Frame_QiFu2;
		-- 介绍
		Introduce = FuJiangTianLongHD_Frame_Text;
		-- 连续天数
		lianxuDays = {
			[ 1 ] = {
				DefaultWindow = FuJiangTianLongHD_Frame_Type1_Hun;
				NormalState = FuJiangTianLongHD_Frame_Type1_Hun_Button;
				SelectState = FuJiangTianLongHD_Frame_Type1_Hun_Select;
				Text = FuJiangTianLongHD_Frame_Type1_Hun_Info;
			};
			[ 2 ] = {
				DefaultWindow = FuJiangTianLong_FrameHD_Type2_Hun;
				NormalState = FuJiangTianLongHD_Frame_Type2_Hun_Button;
				SelectState = FuJiangTianLongHD_Frame_Type2_Hun_Select;
				Text = FuJiangTianLongHD_Frame_Type2_Hun_Info;
			};
			[ 3 ] = {
				DefaultWindow = FuJiangTianLong_FrameHD_Type3_Hun;
				NormalState = FuJiangTianLongHD_Frame_Type3_Hun_Button;
				SelectState = FuJiangTianLongHD_Frame_Type3_Hun_Select;
				Text = FuJiangTianLongHD_Frame_Type3_Hun_Info;
			};
			[ 4 ] = {
				DefaultWindow = FuJiangTianLong_FrameHD_Type4_Hun;
				NormalState = FuJiangTianLongHD_Frame_Type4_Hun_Button;
				SelectState = FuJiangTianLongHD_Frame_Type4_Hun_Select;
				Text = FuJiangTianLongHD_Frame_Type4_Hun_Info;
			};
		};
		-- 单选框
		RadioButton = FuJiangTianLongHD_Frame_QR;
	};
end


-- *************************
-- OnEvent
-- *************************
function FuJiangTianLongHD_OnEvent( event )
	--
	if ( event == "OPEN_FUJIANG_TL_HD" ) then
		if ( this:IsVisible() ) then
			FuJiangTianLongHD_OnHiden()
		else
			-- 请求服务器时间
			AskServerTimeAgain();
			-- 更新
			FuJiangTianLongHD_UpdateUI();
			this:Show();
			-- 关注npc
			g_TargetId = tonumber(arg0)
			g_ObjCaredID = DataPool : GetNPCIDByServerID(g_TargetId)
			if g_ObjCaredID ~= -1 then								
					this:CareObject(g_ObjCaredID, 1, "FuJiangTianLongHD")
			end		
		end
	elseif ( event == "UPDATE_SERVER_TIME_UI" ) then
		if ( this:IsVisible() ) then
			-- 更新
			FuJiangTianLongHD_UpdateUI();
		end
	elseif ( event == "UNIT_LEVEL" ) then
		if ( this:IsVisible() ) then
			-- 更新
			FuJiangTianLongHD_UpdateUI();
		end
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 890509 ) then
		local nOperate = tonumber ( Get_XParam_INT( 0 ) );
		if ( nOperate == 0 ) then
			FuJiangTianLongHD_OnHiden()
		elseif ( nOperate == 1 ) then
			-- 更新
			FuJiangTianLongHD_UpdateUI();
		end
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		FuJiangTianLongHD_OnHiden()
	elseif ( event == "UI_COMMAND" ) and tonumber(arg0) == g_FJL_UICommand then
		local bConfirm = tonumber( NpcShop:GetFuJiangTLBuyDirectly() );
		if ( bConfirm >= 1 ) then
		-- 执行脚本
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name( "DoBless" );	-- 函数名
				Set_XSCRIPT_ScriptID( 890509 );			-- 脚本号
				Set_XSCRIPT_Parameter( 0, 1 );			-- 0:非活动界面 1:活动界面
				Set_XSCRIPT_ParamCount( 1 );			-- 参数个数
			Send_XSCRIPT();
		else
			local nYuanBao, nDay, nExp = FuJiangTianLongHD_Getvariable();
			if ( nYuanBao ~= -1 and nDay ~= -1 and nExp ~= -1 ) then
				PushEvent( "TIANJIANGQIFU_CONFIRM", 1 );
			end
		end
	elseif (event == "OBJECT_CARED_EVENT") then	
		--AxTrace(0, 0, "arg0"..arg0.." arg1"..arg1.." arg2"..arg2);
		if(tonumber(arg0) ~= g_ObjCaredID) then
			return
		end		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if (arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			FuJiangTianLongHD_OnHiden()
		end
	end
end


-- *************************
-- CleanupUI
-- *************************
function FuJiangTianLongHD_CleanupUI()
	-- 按钮: 祈福
	g_Controls.BlessButton:Hide();
	-- 图片: 祈福
	g_Controls.BlessImage:Hide();
	-- 介绍
	g_Controls.Introduce:SetText( "" );
	-- 连续天数
	for i = 1, table.getn( g_Controls.lianxuDays ) do
		g_Controls.lianxuDays[ i ].DefaultWindow:SetToolTip( "" );
		g_Controls.lianxuDays[ i ].NormalState:Hide();
		g_Controls.lianxuDays[ i ].SelectState:Hide();
		g_Controls.lianxuDays[ i ].Text:SetText( "" );
	end
end


-- *************************
-- UpdateUI
-- *************************
function FuJiangTianLongHD_UpdateUI()
	-- CleanupUI
	FuJiangTianLongHD_CleanupUI();

	local Mission_Variable = DataPool:GetPlayerMission_DataRound(961);
	local lastBlessDay = math.mod(Mission_Variable,100000)
	local curDayTime = FuJiangTianLongHD_GetDayTime()
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
	-- 祈福按钮
	if curDayTime ~= lastBlessDay then	-- 今天没有祈福过
		g_Controls.BlessImage:Hide();
		g_Controls.BlessButton:Show();
	else
		g_Controls.BlessImage:Show();
		g_Controls.BlessButton:Hide();
	end
	local nLevel = Player:GetData("LEVEL")
	local baseExp = g_ActivityExp[nLevel - 49]
	if baseExp == nil then
		return
	end
	rewardExp = baseExp
	local rewardExp1 = math.floor(baseExp*(g_FuJiangTianLongActivityRefix[1] + 1))		--计算经验
	local rewardExp2 = math.floor(baseExp*(g_FuJiangTianLongActivityRefix[2] + 1))
	local rewardExp3 = math.floor(baseExp*(g_FuJiangTianLongActivityRefix[3] + 1))
	if lianxuDays > 0 and g_FuJiangTianLongActivityRefix[lianxuDays] ~= nil then
		rewardExp = math.floor(baseExp*(g_FuJiangTianLongActivityRefix[lianxuDays] + 1))		--计算经验
	end
	local needYuanbao = 200
	baseExp = math.floor(baseExp/10000)
	rewardExp1 = math.floor(rewardExp1/10000)
	rewardExp2 = math.floor(rewardExp2/10000)
	rewardExp3 = math.floor(rewardExp3/10000)
	rewardExp = math.floor(rewardExp/10000)
	local strTextFront = ScriptGlobal_Format("#{QFHD_150519_4}", tostring(needYuanbao))

	local nSrcExp = g_FuJiangTianLongExp[ nLevel - 49 ];
	if ( nSrcExp == nil ) then
		return
	end
	nSrcExp = nSrcExp * 1.5;	-- 原来的逻辑还是要乘以1.5倍的
	if ( lianxuDays > 0 and g_FuJiangTianLongOriginalRefix[ lianxuDays ] ~= nil ) then
		nSrcExp = math.floor( nSrcExp * ( g_FuJiangTianLongOriginalRefix[ lianxuDays ] + 1 ) );
	end
	nSrcExp = math.floor( nSrcExp / 10000 );
	local strTextMid = ""
	if curDayTime == lastBlessDay then
		--明天祈福咋样
		strTextMid = ScriptGlobal_Format("#{QFHD_150519_6}",tostring(lianxuDays),tostring(rewardExp),tostring(nSrcExp));
	else
		--今天咋样
		strTextMid = ScriptGlobal_Format("#{QFHD_150519_5}",tostring(lianxuDays),tostring(rewardExp),tostring(nSrcExp))
	end
	g_Controls.Introduce:SetText( strTextFront..strTextMid );

	-- 连续天数
	local aryExp = {
		[ 1 ] = { nExp = baseExp, tip = "#{QFHD_150519_15}" },
		[ 2 ] = { nExp = rewardExp1, tip = "#{QFHD_150519_16}" },
		[ 3 ] = { nExp = rewardExp2, tip = "#{QFHD_150519_17}" },
		[ 4 ] = { nExp = rewardExp3, tip = "#{QFHD_150519_18}" },
	};
	for i = 1, table.getn( g_Controls.lianxuDays ) do
		local strExp = ScriptGlobal_Format( "#{QFHD_150519_7}", tostring( aryExp[ i ].nExp ) );
		if ( ( i - 1 ) == lianxuDays ) then
			g_Controls.lianxuDays[ i ].NormalState:Hide();
			g_Controls.lianxuDays[ i ].SelectState:Show();
			g_Controls.lianxuDays[ i ].SelectState:SetToolTip( strExp );
		else
			g_Controls.lianxuDays[ i ].NormalState:Show();
			g_Controls.lianxuDays[ i ].NormalState:SetToolTip( strExp );
			g_Controls.lianxuDays[ i ].SelectState:Hide();
		end
		strExp = ScriptGlobal_Format( "#{QFHD_150519_19}", tostring( aryExp[ i ].nExp ) );
		g_Controls.lianxuDays[ i ].Text:SetText( aryExp[ i ].tip.."\n"..strExp );
	end

	-- RadioButton
	local bConfirm = NpcShop:GetFuJiangTLBuyDirectly();
	if ( bConfirm >= 1 ) then
		g_Controls.RadioButton:SetCheck( 0 );
	else
		g_Controls.RadioButton:SetCheck( 1 );
	end
end


-- *************************
-- 获取当前时间
-- *************************
function FuJiangTianLongHD_GetDayTime()
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


-- *************************
-- 计算[元宝][连续天数][经验]
-- *************************
function FuJiangTianLongHD_Getvariable()
	-- MD
	local Mission_Variable = DataPool:GetPlayerMission_DataRound( 961 );
	-- 上次祈福时间
	local lastBlessDay = math.mod( Mission_Variable, 100000 );
	-- 当前时间
	local curDayTime = FuJiangTianLongHD_GetDayTime()
	local MidData = math.floor( Mission_Variable / 100000 );
	-- 连续天数
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
	local baseExp = g_ActivityExp[nLevel - 49]
	if baseExp == nil then
		return -1, -1, -1
	end
	rewardExp = baseExp
	if lianxuDays > 0 and g_FuJiangTianLongActivityRefix[lianxuDays] ~= nil then
		rewardExp = math.floor(baseExp*(g_FuJiangTianLongActivityRefix[lianxuDays] + 1))		--计算经验
	end
	local needYuanbao = 200
	baseExp = math.floor(baseExp/10000)
	rewardExp = math.floor(rewardExp/10000)
	local strTextMid = ""
	return needYuanbao, lianxuDays, rewardExp
end


-- =============================================== 事件响应 ===============================================
-- *************************
-- Hide
-- *************************
function FuJiangTianLongHD_OnHiden()
	-- 关闭确认框
	if ( IsWindowShow( "MessageBox_Self" ) ) then
		CloseWindow( "MessageBox_Self", true );
	end
	this:Hide();
	this:CareObject(g_ObjCaredID, 0, "FuJiangTianLongHD")
end


-- *************************
-- 祈福
-- *************************
function FuJiangTianLongHD_DoBless()
	local bConfirm = tonumber( NpcShop:GetFuJiangTLBuyDirectly() );
	local isHasFJL = PlayerPackage:CountAvailableItemByIDTable(g_FJL_ItemID) + Bank:GetUnlockTemBankItemCount(g_FJL_ItemID);

	if isHasFJL >= 1 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name( "bConfirm_FJL" );	-- 函数名
			Set_XSCRIPT_ScriptID( 890509 );			-- 脚本号
			Set_XSCRIPT_ParamCount( 0 );			-- 参数个数
		Send_XSCRIPT();  --2019福降令
	elseif ( bConfirm >= 1 ) then
		-- 执行脚本
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name( "DoBless" );	-- 函数名
			Set_XSCRIPT_ScriptID( 890509 );			-- 脚本号
			Set_XSCRIPT_Parameter( 0, 1 );			-- 0:非活动界面 1:活动界面
			Set_XSCRIPT_ParamCount( 1 );			-- 参数个数
		Send_XSCRIPT();
	else
		local nYuanBao, nDay, nExp = FuJiangTianLongHD_Getvariable();
		if ( nYuanBao ~= -1 and nDay ~= -1 and nExp ~= -1 ) then
			PushEvent( "TIANJIANGQIFU_CONFIRM", 1 );
		end
	end
end


-- *************************
-- RadioButton
-- *************************
function FuJiangTianLongHDYuanBaoConfirm_Clicked()
	local bConfirm = g_Controls.RadioButton:GetCheck();
	if ( bConfirm == 0 ) then
		g_Controls.RadioButton:SetCheck( 0 );
		NpcShop:SetFuJiangTLBuyDirectly( 1 );
	elseif ( bConfirm == 1 ) then
		g_Controls.RadioButton:SetCheck( 1 );
		NpcShop:SetFuJiangTLBuyDirectly( 0 );
	end
end
