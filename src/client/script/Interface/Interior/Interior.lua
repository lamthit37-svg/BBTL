-- [帮会建设] add by DuanXiaoTong
-- PushDebugMessage
-- ScriptGlobal_Format
-- !!gbuild
-- !!!reloadscript =Interior

-----------------------------------------------------------------
CITY_BUILDING_XIANYA			= 0		-- 县衙0
CITY_BUILDING_XIANGFANG			= 1     -- 厢房1
CITY_BUILDING_JIUSI				= 2     -- 酒肆2
CITY_BUILDING_QIANZHUANG		= 3     -- 钱庄3
CITY_BUILDING_FANGJUFANG		= 4     -- 防具4
CITY_BUILDING_DUANTAI			= 5     -- 锻台5
CITY_BUILDING_WUJUFANG			= 6     -- 武具6
CITY_BUILDING_MICANG			= 7     -- 米仓7
CITY_BUILDING_CHENGQIANG		= 8     -- 城墙8
CITY_BUILDING_JIFANG			= 9     -- 集仿9
CITY_BUILDING_YISHE				= 10    -- 医舍10
CITY_BUILDING_WUFANG			= 11    -- 武仿11
CITY_BUILDING_JIANTA			= 12    -- 箭塔12
CITY_BUILDING_SHUFANG			= 13    -- 书房13
CITY_BUILDING_QIJI				= 14    -- 奇迹14
CITY_BUILDING_XIAOCHANG			= 15    -- 校场15
CITY_BUILDING_HUOBINGTA			= 16    -- 火冰塔16
CITY_BUILDING_DAQI				= 17    -- 大旗17
CITY_BUILDING_MONEY				= 18	-- 淘金场
CITY_BUILDING_BAIBAOGE			= 19	-- 百宝阁
CITY_BUILDING_SHENBINGGE		= 20	-- 神兵阁
CITY_BUILDING_EQUIP				= 21	-- 天工阁

CITY_BUILDING_MAX				= 22	-- 城市建筑最大值(和ScriptGlobal.lua里保持一直)
-----------------------------------------------------------------


local g_NpcId = -1;				-- NpcId
local g_Controls = {};			-- 控件
local g_SelBuildingType = 1;	-- 默认选中第一个建筑物enum BUILDING_TYPE
local g_FuncIntroduce = {
	-- 未修建, 等级1, 等级2, 等级3, 等级4, 等级5
	[0] 	= { "", "#{BHJS_140515_153}", "#{BHJS_140515_154}", "#{BHJS_140515_155}", "#{BHJS_140515_156}", "#{BHJS_140515_157}" },
	[1] 	= { "", "#{BHJS_140515_158}", "#{BHJS_140515_159}", "#{BHJS_140515_160}", "#{BHJS_140515_161}", "#{BHJS_140515_162}" },
	[2] 	= { "#{BHJS_140515_221}", "#{BHJS_140515_222}", "#{BHJS_140515_223}", "#{BHJS_140515_224}", "", "" },
	[3] 	= { "", "#{BHJS_140515_163}", "#{BHJS_140515_164}", "#{BHJS_140515_165}", "#{BHJS_140515_166}", "#{BHJS_140515_167}" },
	[4] 	= { "", "", "", "", "", "" },
	[5] 	= { "", "#{BHJS_140515_168}", "#{BHJS_140515_169}", "#{BHJS_140515_170}", "#{BHJS_140515_171}", "#{BHJS_140515_172}" },
	[6] 	= { "", "", "", "", "", "" },
	[7] 	= { "", "#{BHJS_140515_173}", "#{BHJS_140515_174}", "#{BHJS_140515_175}", "#{BHJS_140515_176}", "#{BHJS_140515_177}" },
	[8] 	= { "", "", "", "", "", "" },
	[9] 	= { "", "#{BHJS_140515_178}", "#{BHJS_140515_179}", "#{BHJS_140515_180}", "#{BHJS_140515_181}", "#{BHJS_140515_182}" },
	[10] 	= { "#{BHJS_140515_225}", "#{BHJS_140515_226}", "#{BHJS_140515_227}", "#{BHJS_140515_228}", "", "" },
	[11] 	= { "", "#{BHJS_140515_183}", "#{BHJS_140515_184}", "#{BHJS_140515_185}", "#{BHJS_140515_186}", "#{BHJS_140515_187}" },
	[12] 	= { "", "", "", "", "", "" },
	[13] 	= { "", "#{BHJS_140515_188}", "#{BHJS_140515_189}", "#{BHJS_140515_190}", "#{BHJS_140515_191}", "#{BHJS_140515_192}" },
	[14] 	= { "", "", "", "", "", "" },
	[15] 	= { "", "#{BHJS_140515_193}", "#{BHJS_140515_194}", "#{BHJS_140515_195}", "#{BHJS_140515_196}", "#{BHJS_140515_197}" },
	[16] 	= { "", "", "", "", "", "" },
	[17] 	= { "", "", "", "", "", "" },
	[18] 	= { "", "#{BHJS_140515_198}", "#{BHJS_140515_199}", "#{BHJS_140515_200}", "#{BHJS_140515_201}", "#{BHJS_140515_202}" },
	[19] 	= { "#{BHJS_140515_203}", "#{BHJS_140515_204}", "#{BHJS_140515_205}", "#{BHJS_140515_206}", "#{BHJS_140515_207}", "#{BHJS_140515_208}" },
	[20] 	= { "#{BHJS_140515_209}", "#{BHJS_140515_210}", "#{BHJS_140515_211}", "#{BHJS_140515_212}", "#{BHJS_140515_213}", "#{BHJS_140515_214}" },
	[21] 	= { "#{BHJS_140515_215}", "#{BHJS_140515_216}", "#{BHJS_140515_217}", "#{BHJS_140515_218}", "#{BHJS_140515_219}", "#{BHJS_140515_220}" },
};

--*********************************
-- PreLoad
--*********************************
function Interior_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);						-- UI_COMMAND
	this:RegisterEvent("CITY_SHOW_MANAGE",true);					-- 显示
	this:RegisterEvent("CLOSE_INTERIOR",false);					-- 隐藏
end


--*********************************
-- OnLoad
--*********************************
function Interior_OnLoad()
	g_Controls = {
		-- 建筑物列表
		BuildingList = Interior_Info;
		-- 正在修建/建设
		CurrentBuiding = Interior_Bk2_Text2;
		-- 已完成任务数/需要完成任务数
		MissionInfo = Interior_Bk2_Text4;
		-- 进度条
--		Progress1 = Interior_Pro1_1;
--		Progress2 = Interior_Pro2_1;
		-- 建筑物介绍
		Introduce = {
			CurLevel 	= 	Interior_Bk3_Text1;		-- 建筑物：县衙（1级）
			NextLevel 	= 	Interior_Bk3_Text2;		-- 建筑物：县衙（2级）
			GuildMoney 	= 	Interior_Bk3_Text3;		-- 帮会资金
			MissionNum 	= 	Interior_Bk3_Text4;		-- 发布任务数量
			Condition 	= 	Interior_Bk3_Text5;		-- 前置建筑物
			FuncIntro 	= 	Interior_Bk3_Text7;		-- 功能介绍
		};
		-- 帮会资金
		GuildMoney = Interior_BanghuiMoney;
	}
end


--*********************************
-- OnEvent
--*********************************
function Interior_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 100 ) then
		if ( this : IsVisible() ) then
			return
		end
		g_NpcId = Get_XParam_INT( 0 );
		g_NpcId = Target:GetServerId2ClientId( g_NpcId );
		City:AskCityManageInfo();	-- 请求数据
	elseif ( event == "CITY_SHOW_MANAGE" ) then
		this:CareObject( g_NpcId, 1, "CityManage" );
		PushEvent( "CLOSE_RESEARCH" )		-- 城市研究
		PushEvent( "CLOSE_CIRCULARTASK" )	-- 循环任务
		Interior_OnShow();	-- 显示
	elseif ( event == "CLOSE_INTERIOR" ) then
		City_Manage_Hide();
	end
end


--*********************************
-- OnShow
--*********************************
function Interior_OnShow()
	-- 清空控件
	Interior_CleanupUIControls();

	-- 建筑物列表
	Interior_OnShowBuildingList();
	-- 当前修建/升级中
	Interior_OnShowCurrentBuilding();
	-- 帮会资金
	Interior_OnShowGuildMoney();

	-- 显示
	this:Show();
end


--*********************************
-- 清空控件
--*********************************
function Interior_CleanupUIControls()
	-- 建筑物列表
	g_Controls.BuildingList : RemoveAllItem();

	-- 正在修建/建设
	g_Controls.CurrentBuiding : SetText( "" );
	-- 已完成任务数/需要完成任务数
	g_Controls.MissionInfo : SetText( "" );
	-- 进度条
--	g_Controls.Progress1 : SetProgress( 0, 0 );
--	g_Controls.Progress2 : SetProgress( 0, 0 );
	-- 建筑物介绍
	g_Controls.Introduce.CurLevel : SetText( "" );
	g_Controls.Introduce.NextLevel : SetText( "" );
	g_Controls.Introduce.GuildMoney : SetText( "" );
	g_Controls.Introduce.MissionNum : SetText( "" );
	g_Controls.Introduce.Condition : SetText( "" );
	g_Controls.Introduce.FuncIntro : SetText( "" );
	-- 帮会资金
	g_Controls.GuildMoney : SetProperty( "MoneyNumber", 0 );
end


--*********************************
-- 建筑物列表
--*********************************
function Interior_OnShowBuildingList()
	-- 建筑物列表
	local nBDIndex = 0;
	local nListIndex = 0;
	local buildingInfo = { City:GetCityManageInfo( "BuildingList" ) };	-- {(名称,等级,存在),()....}
	for i = 1, table.getn( buildingInfo ), 4 do
		if ( Interior_HideBuildings( nBDIndex ) == -1 ) then
			local szBuildingName = buildingInfo[ i ];													-- 名称
			local nBuildingLevel = Interior_DefaultBuildingLevels( nBDIndex, buildingInfo[ i + 1 ] );	-- 等级
			local bBuildingExist = buildingInfo[ i + 2 ];				
			local bBuildingID = buildingInfo[ i + 3 ];									-- ID
			local szCurBuildingName = "";
			local nCurBuildingLevel = -1;
			local nCurBuildingType = -1;
			szCurBuildingName, nCurBuildingLevel, nCurBuildingType = City:GetCityManageInfo( "CurBuilding" ); 
			-- 加入控件
			g_Controls.BuildingList : AddNewItem( szBuildingName, 0, nListIndex );
			if ( bBuildingExist == 1 ) then
				local nMaxLevel = Interior_GetBuildingMaxLevel( nBDIndex );
				if bBuildingID == nCurBuildingType then
					g_Controls.BuildingList : AddNewItem( "升级中", 1, nListIndex );
				else
					g_Controls.BuildingList : AddNewItem( nBuildingLevel.."/"..nMaxLevel, 1, nListIndex );
				end 
			else
				if bBuildingID == nCurBuildingType then
					g_Controls.BuildingList : AddNewItem( "修建中", 1, nListIndex );
				else
					g_Controls.BuildingList : AddNewItem( "#{BHJS_140515_38}", 1, nListIndex );
				end  
			end
			g_Controls.BuildingList : SetRowUserData( nListIndex, nBDIndex );		-- data
			g_Controls.BuildingList : SetRowTooltip( nListIndex, szBuildingName );	-- tip
			nListIndex = nListIndex + 1;
		end
		nBDIndex = nBDIndex + 1;
	end
	g_Controls.BuildingList : SetSelectItem( 0 );	-- 选中第一行
end


--*********************************
-- 当前正在修建/升级的建筑物
--*********************************
function Interior_OnShowCurrentBuilding()
	local szBuildingName = "";
	local nBuildingLevel = -1;
	local nBuildingType = -1;
	szBuildingName, nBuildingLevel, nBuildingType = City:GetCityManageInfo( "CurBuilding" );
	if ( szBuildingName == "" or nBuildingLevel == -1 or nBuildingType == -1 ) then
		g_Controls.CurrentBuiding : SetText( "" );
		g_Controls.MissionInfo : SetText( "" );
--		g_Controls.Progress1 : SetProgress( 0, 0 );
--		g_Controls.Progress2 : SetProgress( 0, 0 );
		return
	end
	g_Controls.CurrentBuiding : SetText( szBuildingName );
	local nFinishedNum = 0;		-- 已完成
	local nTotalNum = 0;		-- 总数
	local nDisPatchedNum = 0;	-- 发布数
	nFinishedNum, nTotalNum, nDisPatchedNum = City : GetCityManageInfo( "CurProgress" );
	local nConstructTime = City : GetBuildingInfo( nBuildingType, "ConstructTime" ); --City : GetCityManageInfo( "ConstructTime" ); 
	g_Controls.MissionInfo : SetText( nConstructTime );
end


--*********************************
-- 帮会资金
--*********************************
function Interior_OnShowGuildMoney()
	local nGuildMoney = City : GetCityManageInfo( "GuildMoney" );
	if ( nGuildMoney ) then
		g_Controls.GuildMoney : SetProperty( "MoneyNumber", nGuildMoney );
	else
		g_Controls.GuildMoney : SetProperty( "MoneyNumber", 0 );
	end
end


--*********************************
-- 建筑物介绍
--*********************************
function Interior_OnShowBuildingIntroduce( nBuildingType )
	if ( nBuildingType < CITY_BUILDING_XIANYA or nBuildingType >= CITY_BUILDING_MAX ) then
		return
	end
	-- 主建筑物
	local szMainName = "";
	local nMainLevel = -1;
	szMainName, nMainLevel = City : GetCityManageInfo( "MainBuilding" );
	if ( szMainName == "" or nMainLevel == -1 ) then
		return
	end
	nMainLevel = Interior_DefaultBuildingLevels( CITY_BUILDING_XIANYA, nMainLevel );	-- 主建筑物等级
	--PushDebugMessage( "3333333333333" );
	local szCurName, szNextName = City : GetBuildingInfo( nBuildingType, "name" );										-- 建筑物名称
	local nLevel = Interior_DefaultBuildingLevels( nBuildingType, City : GetBuildingInfo( nBuildingType, "level" ) );	-- 建筑物等级
	local nConditions = { City : GetBuildingInfo( nBuildingType, "condition" ) }; 										-- nNeedMoney, nMissionNum, nNeedAttr, nNeedAttrVal, nNeedBuilding, nNeedBuildingLevel

	-- 1) 建筑物控件
	if ( nLevel == 0 ) then
		local uiStr = ScriptGlobal_Format( "#{BHJS_140515_40}", szCurName, 1 );
		g_Controls.Introduce.CurLevel : SetText( uiStr );
	else
		local uiStr = ScriptGlobal_Format( "#{BHJS_140515_40}", szCurName, nLevel );
		g_Controls.Introduce.CurLevel : SetText( uiStr );
	end
	-- 2) 升级后建筑物控件
	if ( szNextName ~= "" ) then	-- 下一级
		local uiStr = ScriptGlobal_Format( "#{BHJS_140515_43}", szNextName, nLevel + 1 );
		g_Controls.Introduce.NextLevel : SetText( uiStr );
	end
	local nMaxLevel = Interior_GetBuildingMaxLevel( nBuildingType );
	if ( nLevel <= 0 ) then		-- 未修建
		g_Controls.Introduce.NextLevel : SetText( "#{BHJS_140515_41}" );
	elseif ( nLevel == nMaxLevel ) then	-- 满级
		g_Controls.Introduce.NextLevel : SetText( "#{BHJS_140515_42}" );
	end
	-- 3) 修建/升级所需消耗帮会资金控件
	local nNeedGuildMoney = nConditions[ 1 ];
	local nGuildMoney = City : GetBaseInfo( "money" );
	local nAmortizeMoney = City : GetBaseInfo( "AmortizeMoney" );
	local nAvailableMoney = nGuildMoney - nAmortizeMoney;
	-- 这里为了解决lua版本中的加法精度问题, 就放到代码里边去计算了. 绕过这个坑.
	local nSum = City : CalculateNeedMoney( nNeedGuildMoney, nAmortizeMoney );
	g_Controls.Introduce.GuildMoney : SetToolTip( "" );
	if ( nAvailableMoney < 0 ) then
		nAvailableMoney = 0;
		local uiStr = ScriptGlobal_Format( "#{BHJS_140515_49}", nSum );
		g_Controls.Introduce.GuildMoney : SetToolTip( uiStr );
	else
		if ( nAvailableMoney < nNeedGuildMoney ) then
			local uiStr = ScriptGlobal_Format( "#{BHJS_140515_49}", nSum );
			g_Controls.Introduce.GuildMoney : SetToolTip( uiStr );
		end
	end
	if ( nLevel == 0 ) then
		local uiStr = ScriptGlobal_Format( "#{BHJS_140515_50}", nNeedGuildMoney );
		g_Controls.Introduce.GuildMoney : SetText( uiStr );
	else
		local nMaxLevel = Interior_GetBuildingMaxLevel( nBuildingType );
		if ( nLevel >= nMaxLevel ) then
			g_Controls.Introduce.GuildMoney : SetText( "#{BHJS_140515_51}" );
		else
			local uiStr = ScriptGlobal_Format( "#{BHJS_140515_52}", nNeedGuildMoney );
			g_Controls.Introduce.GuildMoney : SetText( uiStr );
		end
	end
	-- 4) 修建/升级所需完成建设任务控件
	local nMissionNum = nConditions[ 2 ];
	local nbuildtime = City : GetBuildingInfo( nBuildingType, "BuildingTime" ); --City : GetCityManageInfo( "ConstructTime" ); 
	
	--PushDebugMessage("nbuildtime"..nbuildtime)		
	if ( nLevel == 0 ) then
		local uiStr = ScriptGlobal_Format( "#{BHJS_140515_53}", nbuildtime );
		g_Controls.Introduce.MissionNum : SetText( uiStr );
	else
		local nMaxLevel = Interior_GetBuildingMaxLevel( nBuildingType );
		if ( nLevel >= nMaxLevel ) then
			g_Controls.Introduce.MissionNum : SetText( "#{BHJS_140515_54}" );
		else
			local uiStr = ScriptGlobal_Format( "#{BHJS_140515_55}", nbuildtime );
			g_Controls.Introduce.MissionNum : SetText( uiStr );
		end
	end
	-- 5) 修建/升级条件控件
	local nNeedBuildingType = nConditions[ 5 ];
	local nNeedBuildingLevel = nConditions[ 6 ];
	if ( nLevel == 0 ) then	-- 未修建
		if ( nNeedBuildingType ~= -1 ) then
			local nCurNeedBuildingLevel = City : GetBuildingInfo( nNeedBuildingType, "level" );
			nCurNeedBuildingLevel = Interior_DefaultBuildingLevels( nNeedBuildingType, nCurNeedBuildingLevel );
			if ( nCurNeedBuildingLevel >= nNeedBuildingLevel ) then
				local uiStr = ScriptGlobal_Format( "#{BHJS_140515_44}", "无" );
				g_Controls.Introduce.Condition : SetText( uiStr );
			else
				--PushDebugMessage( "2222222222222222" );
				local szNeedBuildingName, szNeedNextBuildingName = City : GetBuildingInfo( nNeedBuildingType, "name" );
				local uiStr = ScriptGlobal_Format( "#{BHJS_140515_45}", szNeedBuildingName, szNeedNextBuildingName );
				uiStr = ScriptGlobal_Format( "#{BHJS_140515_44}", uiStr );
				g_Controls.Introduce.Condition : SetText( uiStr );
			end
		else
			local uiStr = ScriptGlobal_Format( "#{BHJS_140515_44}", "无" );
			g_Controls.Introduce.Condition : SetText( uiStr );
		end
	else
		local nMaxLevel = Interior_GetBuildingMaxLevel( nBuildingType );
		if ( nLevel >= nMaxLevel ) then
			local uiStr = ScriptGlobal_Format( "#{BHJS_140515_46}", "无" );
			g_Controls.Introduce.Condition : SetText( uiStr );
		else
			if ( g_SelBuildingType == CITY_BUILDING_XIANYA ) then	-- 主建筑物
				if ( 1 <= nLevel and nLevel <= 3 ) then
					local uiStr = ScriptGlobal_Format( "#{BHJS_140515_47}", nLevel );
					uiStr = ScriptGlobal_Format( "#{BHJS_140515_46}", uiStr );
					g_Controls.Introduce.Condition : SetText( uiStr );
				else
					local uiStr = ScriptGlobal_Format( "#{BHJS_140515_46}", "#{BHJS_140515_48}" );
					g_Controls.Introduce.Condition : SetText( uiStr );
				end
			else	-- 功能建筑
				if ( nNeedBuildingType ~= -1 ) then
					--PushDebugMessage( "111111111111111" );
					local szNeedBuildingName, szNeedNextBuildingName = City : GetBuildingInfo( nNeedBuildingType, "name" );
					local nCurNeedBuildingLevel = City : GetBuildingInfo( nNeedBuildingType, "level" );
					nCurNeedBuildingLevel = Interior_DefaultBuildingLevels( nNeedBuildingType, nCurNeedBuildingLevel );
					if ( nCurNeedBuildingLevel < nNeedBuildingLevel ) then
						local uiStr = ScriptGlobal_Format( "#{BHJS_140515_45}", szNeedBuildingName, szNeedNextBuildingName );
						uiStr = ScriptGlobal_Format( "#{BHJS_140515_46}", uiStr );
						g_Controls.Introduce.Condition : SetText( uiStr );
					else
						local uiStr = ScriptGlobal_Format( "#{BHJS_140515_46}", "无" );
						g_Controls.Introduce.Condition : SetText( uiStr );
					end
				else
					local uiStr = ScriptGlobal_Format( "#{BHJS_140515_46}", "无" );
					g_Controls.Introduce.Condition : SetText( uiStr );
				end
			end
		end
	end
	-- 6) 建筑物功能介绍
	if ( nLevel == 0 ) then
		g_Controls.Introduce.FuncIntro : SetText( g_FuncIntroduce[ nBuildingType ][ 1 ] );
	else
		g_Controls.Introduce.FuncIntro : SetText( g_FuncIntroduce[ nBuildingType ][ nLevel + 1 ] );
	end
end


--*********************************
-- 不显示的建筑物
--*********************************
--~ function City_Manage_Is_Hide_Idx(idx)
function Interior_HideBuildings( nIndex )
	local hideBuidings = { 4, 6, 8, 12, 14, 16, 17 };
	for i = 1, table.getn( hideBuidings ) do
		if ( hideBuidings[ i ] == nIndex ) then
			return 1;
		end
	end

	return -1;
end


--*********************************
-- 未建造建筑物缺省时, 等级不+1
--*********************************
function Interior_DefaultBuildingLevels( nBuildingType, nLevel )
	local nBuildings = { 2, 4, 6, 10, 19, 20, 21 };
	for i = 1, table.getn( nBuildings ) do
		if ( nBuildings[ i ] == nBuildingType ) then
			return nLevel;
		end
	end

	return ( nLevel + 1 );
end


--*********************************
-- 事件响应: Listbox
--*********************************
function City_Manage_SelectChanged()
	-- 设置选中的建筑物类型
	local nListIndex = g_Controls.BuildingList : GetSelectItem();
	g_SelBuildingType = g_Controls.BuildingList : GetRowUserData( nListIndex );

	-- 建筑物介绍
	Interior_OnShowBuildingIntroduce( g_SelBuildingType );
end


--*********************************
-- 建筑物可以升到的最高等级
--*********************************
function Interior_GetBuildingMaxLevel( nBuildingType )
	if ( nBuildingType == 2 or nBuildingType == 4 or nBuildingType == 6 or nBuildingType == 10 ) then
		return 3;
	end

	return 5;
end


--*********************************
-- 1修建/2升级按钮响应事件
-- 需要修改XML, 最好不要映射表
--*********************************
function City_Manage_DoBuilding( nIndex )
	-- 映射表
	local fOperate = {2,3};
	-- XML到城市操作配型的映射
	local nOptType = fOperate[ nIndex ];

	-- xx建筑物还没有
	local nBuildingType = -1;
	_, _, nBuildingType = City : GetCityManageInfo( "CurBuilding" );
	if ( nBuildingType ~= -1 ) then
		local szName = City : GetBuildingInfo( nBuildingType, "name" );
		PushDebugMessage( szName.."的建设或升级尚未完成" );
		return
	end

	-- 开始建造升级
	City : DoConfirm( nOptType, g_SelBuildingType )
end


--*********************************
-- 关闭UI
--*********************************
function City_Manage_Hide()
	this : Hide();
end
