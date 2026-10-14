-----------------------------------------------------------------------------------------------
--大改一次吧。实在受不了了。
--
--1，左侧显示大区列表：推荐服务器、争霸赛、电信、网能、双线
--2，右侧显示服务器：推荐服务器、流畅服务器、搜索服务器、争霸赛、电信、网能、双线

----------------------------------------------------------------------------------------------- 大区信息 --
-- 全局变量
local g_AreaButtonListImage = "ButtonTuiJian_Normal_L"
local g_AreaButtonListImageSet = "Button16"
local g_nAreaButton = {};				--区域按钮
local g_nAreaButtonInfo = {};		--区域
local g_nCurSelectListIndex = 0;
local g_nCurSelSubArea = {};

--tcp测速用
local lastArea;
local lastServer;
local update_delay=-1;
local selected=0
local SearchOrNormal=-1;
local btnindex=-1;

--服务器大区显示UI相关变量
local g_AreaUI = {
		AreaCtrlID_RECMD	= 1,	-- 推荐
		AreaCtrlID_ZBS		= 2,	-- 争霸赛
		AreaCtrlID_TEL		= 3,	-- 电信
		AreaCtrlID_CNC		= 4,	-- 联通
		AreaCtrlID_BGP		= 5,	-- 双线
		AreaCtrlID_SPECIAL= 6,	-- 特色服
		AreaCtrlID_2606S	= 7,	-- 轻享大区
		AreaCtrlID_BWDH		= 8,	-- 比武大会
		AreaCtrlID_TXHW		= 9,	-- 天下会武
		AreaCtrlID_DFS		= 10,	-- 巅峰赛		
		AreaCtrlID_WGONLY	= 11,	-- WG专服
		AreaCtrlCount= 11;
		AreaCtrlInfo = {
			--MustShow: 为1时必须显示，为0时，有可能不显示(依赖于服务器个数)
			--ShowList：为1时显示大区列表
			--CurShowListList：当前大区的子区域列表是否展开
			--strName：大区名字			
			[1] = { ctrl = nil, MustShow=1, ShowList=0, CurShowList=0, strName="#{DLYHQF_12121301}", OpenToolTipText="#{DLYHQF_12121307}", CloseToolTipText="#{DLYHQF_12121307}" },	--推荐服务器
			[2] = { ctrl = nil, MustShow=0, ShowList=0, CurShowList=0, strName="", OpenToolTipText="", CloseToolTipText=""},	--争霸赛
			[3] = { ctrl = nil, MustShow=1, ShowList=1, CurShowList=0, strName="#{DLYHQF_12121304}", OpenToolTipText="#{DLYHQF_12121310}", CloseToolTipText="#{DLYHQF_12121311}" },	--电信大区
			[4] = { ctrl = nil, MustShow=1, ShowList=1, CurShowList=0, strName="#{DLYHQF_12121305}", OpenToolTipText="#{DLYHQF_12121312}", CloseToolTipText="#{DLYHQF_12121313}" },	--网通大区
			[5] = { ctrl = nil, MustShow=1, ShowList=1, CurShowList=0, strName="#{DLYHQF_12121306}", OpenToolTipText="#{DLYHQF_12121314}", CloseToolTipText="#{DLYHQF_12121315}" },	--双线大区
			[6] = { ctrl = nil, MustShow=0, ShowList=1, CurShowList=0, strName="#{DLYHQF_12121362}", OpenToolTipText="#{DLYHQF_12121363}", CloseToolTipText="#{DLYHQF_12121364}" },	--特色服大区
			[7] = { ctrl = nil, MustShow=0, ShowList=0, CurShowList=0, strName="#{DLYHQF_12121365}", OpenToolTipText="#{DLYHQF_12121366}", CloseToolTipText="#{DLYHQF_12121367}" },	--轻享大区
			[8] = { ctrl = nil, MustShow=0, ShowList=0, CurShowList=0, strName="#{BHKF_150323_198}", OpenToolTipText="#{BHKF_150323_199}", CloseToolTipText="#{BHKF_150323_199}" },	--新比武大会大区赛
			[9] = { ctrl = nil, MustShow=0, ShowList=0, CurShowList=0, strName="#{WCJS_180521_71}", OpenToolTipText="#{WCJS_180521_72}", CloseToolTipText="#{WCJS_180521_72}" },	--天下会武
			[10] = { ctrl = nil, MustShow=0, ShowList=0, CurShowList=0, strName="#{SJDF_190603_194}", OpenToolTipText="#{SJDF_190603_195}", CloseToolTipText="#{SJDF_190603_196}" },	--巅峰赛大区
			[11] = { ctrl = nil, MustShow=0, ShowList=0, CurShowList=0, strName="#{WEJR_251216_03}", OpenToolTipText="#{WEJR_251216_04}", CloseToolTipText="#{WEJR_251216_05}" },	--WG独立大区
			};		
				
		CurPage			= 0;		--当前显示大区
		DefaultPage	= 1;		--默认显示大区
		
--		CurSelAreaIndex = -1;	--当前选择的大区
	};	
	
local g_ZBS_STRING = "全球争霸赛总决赛";
local g_ZBS_STRING2 = "全服争霸赛总决赛";
	
--LoginServer.txt中的服务器区域信息
local g_AreaInfo = {
	iAreaCount = 0;		--总区域的数量
	AreaServerInfo = {
		--iSubAreaCount：子区域个数
		--strAreaName:子区域名称
		--iAreaIndex:区域序号(0~..)
		--strAreaTip:区域Tips：现在只用于大区列表的Tips显示
		--iRecommendLevel:推荐级别，现在只用于大区列表的“推荐”显示		
		[1] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--推荐服务器 --其实没有用到
		[2] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--争霸赛服务器
		[3] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--电信大区
		[4] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--网通大区
		[5] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--双线大区
		[6] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--特色服
		[7] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--轻享大区
		[8] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--至尊帮派邀请赛
		[9] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--天下会武
		[10] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--巅峰赛大区
		[11] = { button={}, iSubAreaCount=0, strAreaName={}, iAreaIndex={}, strAreaTip={}, iRecommendLevel={}, },		--WG独立大区
		};
	};
	
----------------------------------------------------------------------------------------------- 服务器信息 --
--推荐服务器按钮
local g_RecommendServerBn = {
	MAX_SERVER_COUNT = 12;    	--最大个数
	BnServer = {};							-- 推荐服务器按钮
	BnServerAnimate = {};				-- 推荐服务器特效按钮数组
	BnWSTImage = {};						-- 推荐服务器图片
	};
	
--流畅服务器按钮
local g_FluencyServerBn = {
	MAX_SERVER_COUNT = 12;    	-- 最大个数
	BnServer = {};							-- 流畅服务器按钮
	BnServerAnimate = {};				-- 流畅服务器特效按钮数组
	BnWSTImage = {};						-- 服务器图片
	};
	
--服务器按钮
local g_ServerBn = {
	MAX_SERVER_COUNT = 85;    	-- 最大个数
	BnServer = {};							-- 服务器按钮
	BnServerAnimate = {};				-- 服务器特效按钮数组
	BnWSTImage = {};						-- 服务器图片
	};
	
--推荐服务器信息
local g_RecommendServerInfo = {
	iRecommendServerCount = 0;				-- 记载推荐服务器的个数
	strRecommendServerName = {};			-- 推荐服务器名字
	iRecommendServerIndex = {};				-- 推荐服务器Index
	iRecommendServerAreaIndex = {};		-- 推荐服务器区域Index
	iRecommendLevel = {};							-- 推荐服务器推荐等级
	iRecommendServerIsNew = {};				-- 推荐服务器是否新服
	iRecommendServerStatus = {};			-- 推荐服务器 状态
	iRecommendServerPrizeLevel = {};	-- 推荐服务器 获奖情况数组
	iRecommendServerVersion = {};			-- 推荐服务器 版本号	
	iRecommendServerWuShenTan = {};		-- 推荐服务器 武神坛标记
	};
	
--流畅服务器信息
local g_FluencyServerInfo = {
	iServerCount = 0;					-- 记载流畅服务器的个数
	strServerName = {};				-- 流畅服务器名字
	iServerIndex = {};				-- 流畅服务器Index
	iServerAreaIndex = {};		-- 流畅服务器区域Index
	iLevel = {};							-- 流畅服务器推荐等级
	iServerIsNew = {};				-- 流畅服务器是否新服
	iServerStatus = {};				-- 流畅服务器 状态
	iServerPrizeLevel = {};		-- 流畅服务器 获奖情况数组
	iServerVersion = {};			-- 流畅服务器 版本号	
	iServerWuShenTan = {};		-- 服务器 武神坛标记
	};
	
--服务器信息
local g_ServerInfo = {
	iServerCount = 0;					-- 记载服务器的个数
	strServerName = {};				-- 服务器名字
	iServerIndex = {};				-- 服务器Index
	iServerAreaIndex = {};		-- 服务器区域Index
	iLevel = {};							-- 服务器推荐等级
	iServerIsNew = {};				-- 服务器是否新服
	iServerStatus = {};				-- 服务器 状态
	iServerPrizeLevel = {};		-- 服务器 获奖情况数组
	iServerVersion = {};			-- 服务器 版本号	
	iServerWuShenTan = {};		-- 服务器 武神坛标记
	};
	
--搜索服务器信息
local g_SearchServerInfo = {
	iServerCount = 0;					-- 记载服务器的个数
	strServerName = {};				-- 服务器名字
	iServerIndex = {};				-- 服务器Index
	iServerAreaIndex = {};		-- 服务器区域Index
	iLevel = {};							-- 服务器推荐等级
	iServerIsNew = {};				-- 服务器是否新服
	iServerStatus = {};				-- 服务器 状态
	iServerPrizeLevel = {};		-- 服务器 获奖情况数组
	iServerVersion = {};			-- 服务器 版本号	
	iServerWuShenTan = {};		-- 服务器 武神坛标记
	};
	
--1，MouseEnter 发送Ping，
--2，页面变动，之前的要无效
--3，要知道当前页面

--当前右侧显示的页面标记
local g_iCurShowServer = 0;
local CUR_SHOW_SERVER_RECOMMEND = 1
local CUR_SHOW_SERVER_FLUENCY = 2
local CUR_SHOW_SERVER = 3
local CUR_SHOW_SERVER_SEARCH_BASE = 4 --如果第二页，则BASE+1

--当前Ping信息
local g_PingInfo = {
 iShowServer = 0;			--与g_iCurShowServer进行比较的，值意义相同
 iAreaIndex = -1;
 iServerIndex = -1;
 };
 
--最近登录服务器信息
local g_LastServer = -1;
local g_LastArea   = -1;
local g_LastServerState = -1;
local g_LastServerName = "";
local g_LastServerPrizeLevel = 0;--上次登录服务器的获奖级别added by lichengjie
local g_LastServerWuShenTan = 0;

-- 当前选择的区域
local g_iCurSelArea = 0;

--local week_days = {};
--local CurYear =0 ;
--local CurMon = 0;
--local CurDay = 0;
--local CurWeekDay = "";
--local numToCh = {"#{DLYHQF_12121351}","#{DLYHQF_12121352}","#{DLYHQF_12121353}","#{DLYHQF_12121354}",
--	"#{DLYHQF_12121355}","#{DLYHQF_12121356}","#{DLYHQF_12121357}","#{DLYHQF_12121358}",
--	"#{DLYHQF_12121359}","#{DLYHQF_12121360}","#{DLYHQF_12121361}"}

------------------------------------------------------------------------------
local g_idBackSound = -1;

local g_curSelectArea = -1;
local g_curSelectServer = -1;

-- 当前选择的login server
local g_iCurSelLoginServer = -1;

local g_bCommendSrvShow = -1;		--当前是否显示流畅服务器
local g_SearchCurPage = 0;				--当前显示页，取值从1开始
local g_SearchServerPage = 0;			--服务器搜索结果的总页数

--服务器处于维护状态
local StateStop = 4;
--不显示状态
local StatMax = 10;

local g_iNetProvide = -1;		-- 0 : 电信
								-- 1 : 网通
								-- 2 : 其他
								-- 3：默认

local g_AllNetProvide = {0,1,2,3}

local g_CriticalSpeed =200;
local g_CriticalSpeed1 =250
local g_CriticalSpeed2 =500
local g_CriticalSpeed3 =1000
--local g_NetSpeed ={"#e010101网络速度:#c4CFA4C良好","#e010101网络速度:#cff0000繁忙","#e010101网络速度:未知", "#e010101网络速度:#cff0000拥堵" }
local g_NetSpeed ={"##{DLYHQF_12121320}","#{DLYHQF_12121321}","#{DLYHQF_12121322}", "#{DLYHQF_12121323}" }

--获奖提示
local g_ThreePrizeTip =
{
	"#{WJZH_100910_20}",--这个地方将字典WJZH_100910_19改为新的WJZH_100910_20
	"#{WJZH_100910_18}",
	"#{WJZH_100910_17}",
	"#{CLCZ_101207_03}",
	"#{CLCZ_101207_02}",
	"#{CLCZ_101207_01}",
	"#{KFZB_110628_205}", --全国争霸赛总决赛第一名所在服务器！全服授予1.2倍经验奖励，持续2周。7
	"#{KFZB_110628_206}", --全国争霸赛总决赛第二名所在服务器！全服授予1.2倍经验奖励，持续1周。8
	"#{KFZB_110628_207}", --全国争霸赛总决赛第三名所在服务器！全服授予1.2倍经验奖励，持续1周。9
	"#{KFZB_110628_208}", --全国争霸赛大区赛前三名所在服务器！全服授予1.1倍经验奖励，持续1周。10
	"#{KFZB_110628_251}", --全国争霸赛总决赛32强所在服务器！全服授予1.2倍经验奖励，持续3天。。11

	"#{WJZH_100910_19}", --天龙3重战江湖系列活动中回归人气最高！全服授予1.2倍经验奖励，持续7天。12
	"#{WJZH_100910_18}", --天龙3重战江湖系列活动中回归人气次高！全服授予1.2倍经验奖励，持续3天。13
	"#{WJZH_100910_17}", --天龙3重战江湖系列活动中回归人气较高！全服授予1.1倍经验奖励，持续3天。14
	nil, --没有tips 15
	nil, --没有tips 16
	nil, --没有tips 17
	nil, --没有tips 18
}
--获奖动画特效资源
local g_ThreePrizeAnimate=
{
	"Server_3",
	"Server_2",
	"Server_1",
	"Server_3",
	"Server_2",
	"Server_1",
	"Server_3", --7
	"Server_2", --8中间两种情况特效应该一致才对
	"Server_2", --9
	"Server_1", --10
	"Server_1", --11
	"Server_3", --12
	"Server_2", --13
	"Server_1", --14
	"Server_4", --15
	"Server_Zhounian", --16
	"Server_PK", --17
	"Server_HJF", --18
}
local g_ThreeCommendablePrizeAnimate = --推荐服务器列表特效资源
{
	"Subarea_3",
	"Subarea_2",
	"Subarea_1",
	"Subarea_3",
	"Subarea_2",
	"Subarea_1",
	"Subarea_3", --7
	"Subarea_2", --8
	"Subarea_2", --9
	"Subarea_1", --10
	"Subarea_1", --11

	"Subarea_3", --12
	"Subarea_2", --13
	"Subarea_1", --14
	"Subarea_4", --15
	"Subarea_Zhounian", --16
	"Subarea_PK", --17
	"Subarea_HJF", --18
}
local g_LastServerPrizeAnimate = --上次登录服务器特效资源
{
	"Server_Last_3",
	"Server_Last_2",
	"Server_Last_1",
	"Server_Last_3",
	"Server_Last_2",
	"Server_Last_1",
	"Server_Last_3", --7
	"Server_Last_2", --8
	"Server_Last_2", --9
	"Server_Last_1", --10
	"Server_Last_1", --11

	"Server_Last_3", --12
	"Server_Last_2", --13
	"Server_Last_1", --14
	"Server_Last_4", --15
	"Server_Last_Zhounian", --16
	"Server_Last_PK", --17
	"Server_Last_HJF", --18
}
--end lichengjie

local g_SelectServer_Str = {
														"#{DLJM_XML_46}",   --电信
														"#{DLJM_XML_48}",   --网通
														"#{DLJM_XML_50}",   --教育网
														"#{DDFWQ_XML_01}",   --网通青岛代理
														"#{DLJM_XML_47}",   --电信#G(荐)
														"#{DLJM_XML_49}",   --网通#G(荐)
														"#{DLJM_XML_51}",   --教育网#G(荐)
														"#{DDFWQ_XML_03}",   --网通青岛代理#G(荐)
														"#{DLJM_XML_36}",	  --#gFF0FA0电信用户请点击此选项,从而更流畅的进行游戏
														"#{DLJM_XML_37}",	  --#gFF0FA0网通用户请点击此选项,从而更流畅的进行游戏
														"#{DLJM_XML_38}",	  --#gFF0FA0教育网用户请点击此选项,从而更流畅的进行游戏
														"#{DDFWQ_XML_02}",  --#gFF0FA0联通(网通)用户，如果连接的目标服务器也为联通（网通）服务器，推荐使用此连接方式。
														"#{DLJM_XML_52}",   --系统检测到您可能是电信用户，推荐您使用电信服务器代理以获得更流畅的游戏体验。
														"#{DLJM_XML_53}",   --系统检测到您可能是网通用户，推荐您使用网通服务器代理以获得更流畅的游戏体验。
														"#{DLJM_XML_54}",   --系统检测到您可能是教育网用户，推荐您使用教育网服务器代理以获得更流畅的游戏体验。
														"#{DLJM_XML_53}",   --系统检测到您可能是网通用户，推荐您使用网通服务器代理以获得更流畅的游戏体验。

														}

-------------------------------------------------------------------------------------------------------------
--
-- 函数区.
--
--

-- 注册onLoad事件
function LoginSelectServer_PreLoad()
	-- 打开选择服务器界面
	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_SERVER",true);

	-- 选择区域
	this:RegisterEvent("GAMELOGIN_CLOSE_SELECT_SERVER",false);

	-- 打开选择服务器界面
	this:RegisterEvent("GAMELOGIN_SELECT_AREA",false);

	-- 选择login
	this:RegisterEvent("GAMELOGIN_SELECT_LOGINSERVER",false);

	-- 选择是否使用代理
	this:RegisterEvent("GAMELOGIN_SELECT_USEPROXY",false);

	-- 注册选择一个login server事件
	this:RegisterEvent("GAMELOGIN_SELECT_LOGIN_SERVER",false);

	-- 玩家进入场景
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true);

	--上次登录的服务器
	this:RegisterEvent("GAMELOGIN_LASTSELECT_AREA_AND_SERVER",false);

	--进入账号输入界面
	this:RegisterEvent("GAMELOGIN_SERVER_SHOW_COUNTINPUT",false);

	--返回服务器选择Sub1
	this:RegisterEvent("GAMELOGIN_SERVER_SHOW_SUB",false);

	--更新服务器列表信息
	this:RegisterEvent("GAMELOGIN_UPDATE_SERVERINFO",true);
	
	--推荐更加合适的服务器
	this:RegisterEvent( "GAMELOGIN_OPEN_RECOMMEND_SERVER",true );
			
	--时间更新
	--this:RegisterEvent( "GAMELOGIN_TIME_UPDATE",false );

end

function LoginSelectServer_OnLoad()

	SelectServer_UI_AreaList_Init();		--初始化大区列表控件	
	SelectServer_UI_Controls_Init();		--初始化服务器区各控件
	
	--week_days[1] = "#{DLYHQF_12121350}";
	--week_days[2] = "#{DLYHQF_12121352}";
	--week_days[3] = "#{DLYHQF_12121353}";
	--week_days[4] = "#{DLYHQF_12121354}";
	--week_days[5] = "#{DLYHQF_12121355}";
	--week_days[6] = "#{DLYHQF_12121356}";
	--week_days[7] = "#{DLYHQF_12121357}";
	
	-- 得到大区信息 和 推荐服务器信息
	SelectServer_Data_GetAreaInfoAndRecommendServerInfo();
	
	-- 打开界面
	SelectServer_Frame:SetProperty("AlwaysOnTop", "True");
		
	-- 隐藏所有推荐服务器
	--SelectServer_HideRecommendServerBn();

	--隐藏角色查询，现在显示了
	SelectServer_RoleInquiry_Text:Show();
	SelectServer_RoleInquiry:Show();
end

--是否自动把选择的服务器序号变成0，防止.txt文件有大的变动
local autoZero = 0;
-- OnEvent
function LoginSelectServer_OnEvent(event)
		
	if( event == "GAMELOGIN_OPEN_SELECT_SERVER" ) then
		SelectServer_ThisUIShow()
		if GameProduceLogin:IsWeGameClient() > 0 then
		
			g_AreaUI.AreaCtrlInfo[g_AreaUI.AreaCtrlID_RECMD].MustShow = 0;
			g_AreaUI.AreaCtrlInfo[g_AreaUI.AreaCtrlID_TEL].MustShow = 0;
			g_AreaUI.AreaCtrlInfo[g_AreaUI.AreaCtrlID_CNC].MustShow = 0;
			g_AreaUI.AreaCtrlInfo[g_AreaUI.AreaCtrlID_BGP].MustShow = 0;

			SelectServer_Regist:Hide();
			SelectServer_Charge:Hide();
			SelectServer_Cancel:Hide();
			SelectServer_RoleInquiry_Text:Hide();
			SelectServer_RoleInquiry:Hide();
		else
			SelectServer_WeGame_Cancel:Hide();
		end
		SelectServer_Server_SearchName:SetText("");
			
		--显示区域信息
		SelectServer_AddAllAreaButton();
		
		--显示默认页面：推荐服务器	
		g_nCurSelectListIndex = g_AreaUI.DefaultPage;
		SelectServerEvent_Area_SwitchPage( g_nCurSelectListIndex );

		-- 播放背景音乐
		-- 如果为微端，则也不播放背景音乐
		if(g_idBackSound == -1 and GetClientVersionType() ~= 1) then
			g_idBackSound = Sound:PlaySound(2110, true,true);
		end
		return;
	end

	-- 关闭界面
	if( event == "GAMELOGIN_CLOSE_SELECT_SERVER") then
		this:Hide();
		return;
	end
	
	-- 选择一个login server 选取符合要求的最空闲服务器
	if( event == "GAMELOGIN_SELECT_LOGIN_SERVER") then
		local num = tonumber(arg0);
		for page=2, g_AreaUI.AreaCtrlCount do
			for index = 1, g_AreaInfo.AreaServerInfo[page].iSubAreaCount do
				if ( num == g_AreaInfo.AreaServerInfo[page].iAreaIndex[index] ) then
					--清空所有状态
					SelectServer_Area_ClearAllStatus();
					SelectServer_SelectAreaButton( page, index, 1, 0 );
					SelectServer_SelectAreaServer( page, index);
					SelectServerEvent_ServerBn_Clicked(tonumber(arg1),1);
					return;
				end
			end
		end
		return;
	end

	-- 选择区域
	if( event == "GAMELOGIN_SELECT_AREA") then
		--如果从账号输入界面返回大区界面
		autoZero = 0;
		local num = tonumber(arg0); --AreaIndex
		for page=2, g_AreaUI.AreaCtrlCount do
			for index = 1, g_AreaInfo.AreaServerInfo[page].iSubAreaCount do
				if ( num == g_AreaInfo.AreaServerInfo[page].iAreaIndex[index] ) then
					--清空所有状态
					SelectServer_Area_ClearAllStatus();
					SelectServer_SelectAreaButton( page, index, 1, 0 );
					SelectServer_SelectAreaServer( page, index);
					return;
				end
			end
		end
		
		--完全没有找到，说明文件有了大的变化
		autoZero = 1;
		--显示默认页面：推荐服务器	
		g_nCurSelectListIndex = g_AreaUI.DefaultPage;
		SelectServerEvent_Area_SwitchPage( g_nCurSelectListIndex );
		return;
	end;

	-- 选择login
	if( event == "GAMELOGIN_SELECT_LOGINSERVER") then
		--如果从账号输入界面返回大区界面
		if tonumber(arg0) < 0 then
			return;
		end
		
		if ( g_ServerBn.BnServer[tonumber(arg0)+1]:GetProperty("Disabled")=="False") then
			if(autoZero == 0 )then
				SelectServerEvent_ServerBn_Clicked(tonumber(arg0),0);
			else
				SelectServerEvent_ServerBn_Clicked(0,0);
				autoZero = 0;
			end
		end;
		return;
	end;

	-- 使用代理
	if( event == "GAMELOGIN_SELECT_USEPROXY" ) then
		if tonumber(arg0) == 0 then
			g_iNetProvide = 0
			SelectServer_LineSelect:SetCurrentSelect(0)
		elseif tonumber(arg0) == 1 then
			g_iNetProvide = 1
			SelectServer_LineSelect:SetCurrentSelect(1)
		elseif tonumber(arg0) == 2 then
			g_iNetProvide = 2
			SelectServer_LineSelect:SetCurrentSelect(2)
		elseif tonumber(arg0) == 3 then
			g_iNetProvide = 3
			SelectServer_LineSelect:SetCurrentSelect(3)
		end
		return;
	end;

	-- 进入场景，停止背景音乐
	if( event == "PLAYER_ENTERING_WORLD") then
		if(g_idBackSound ~= -1) then
			Sound:StopSound(g_idBackSound);
			g_idBackSound = -1;
		end
	end

	--上次登录服务器
	if( event == "GAMELOGIN_LASTSELECT_AREA_AND_SERVER") then
		local numArea =-1;
		local numServer = -1;
		if(arg0~=nil)then
			numArea = tonumber(arg0);
			g_LastArea = numArea;
		end
		if(arg1~=nil)then
			numServer = tonumber(arg1);
			g_LastServer = numServer;
		end
		if(numArea ~= -1 and numServer~=-1)then
			local have = 0;
			
			for page=2, g_AreaUI.AreaCtrlCount do
				for index =1, g_AreaInfo.AreaServerInfo[page].iSubAreaCount do
					if ( numArea == g_AreaInfo.AreaServerInfo[page].iAreaIndex[index] ) then
						have = 1;
						break;
					end
				end
				if have == 1 then
					break;
				end
			end			
			
			if(have == 1)then
				g_LastServerName, g_LastServerState,_,_,_, g_LastServerPrizeLevel,_,g_LastServerWuShenTan = GameProduceLogin:GetAreaLoginServerInfo(numArea, numServer);
				SelectServer_Server_Last:SetText(g_LastServerName);
				if g_LastServerWuShenTan > 0 then
					SelectServer_Server_Last_Img:Show()
				else
					SelectServer_Server_Last_Img:Hide()
				end
				--判断上次登录服务器是否处于维护状态 tt69698
				if (g_LastServerState == StateStop) then
					SelectServer_Server_Last:SetCheck(0);
					SelectServer_Server_Last:Disable();
				else
					SelectServer_Server_Last:Enable();
					--if(g_iCurSelArea == g_LastArea and g_LastServer ==g_iCurSelLoginServer)then
						SelectServer_Server_Last:SetCheck(1);
					--end
				end
				---lichengjie 判断上次获得奖励，如果上次处于维护状态是否还显示特效？，现在是显示
				if( g_LastServerPrizeLevel > 0 ) then
					SelectServer_Server_Last_Animate:SetProperty("Animate", g_LastServerPrizeAnimate[g_LastServerPrizeLevel]);
					SelectServer_Server_Last_Animate:SetProperty("Visible", "True");
				else
					SelectServer_Server_Last_Animate:SetProperty("Animate", "");
					SelectServer_Server_Last_Animate:SetProperty("Visible", "False");
				end
				--获取选择大区
				--SelectServer_Server_AreaNameShow:SetText(g_iCurSelAreaName);
			else
				SelectServer_Server_Last:SetText("无");
				SelectServer_Server_Last:SetCheck(0);
				SelectServer_Server_Last:Disable();
			end
		else
			SelectServer_Server_Last:SetText("无");
			SelectServer_Server_Last:SetCheck(0);
			SelectServer_Server_Last:Disable();
			---added by lichengjie
			g_LastServerPrizeLevel = 0;
			SelectServer_Server_Last_Animate:SetProperty("Animate", "");
			SelectServer_Server_Last_Animate:SetProperty("Visible", "False");
			---lichengjie
		end
		return;
	end;

	if( event == "GAMELOGIN_SERVER_SHOW_COUNTINPUT") then
		SelectServerEvent_SelectOk();
	end

	if( event == "GAMELOGIN_SERVER_SHOW_SUB") then
		SelectServerEvent_ReturnAreaSelect_click();
	end

	if( event == "GAMELOGIN_UPDATE_SERVERINFO") then
		-- 得到大区信息 和 推荐服务器信息
		SelectServer_Data_GetAreaInfoAndRecommendServerInfo();
		--显示区域信息
		--SelectServer_AddAllAreaButton();
		--g_nCurSelectListIndex = g_AreaUI.DefaultPage;
		--SelectServerEvent_Area_SwitchPage( g_nCurSelectListIndex );
	end
	
	if (event == "GAMELOGIN_OPEN_RECOMMEND_SERVER") then
		SelectServer_ThisUIShow()
			
		--显示区域信息
		SelectServer_AddAllAreaButton();
	
		SelectServer_ShowFluencyServer();
		
		return
	end
end

function SelectServer_ThisUIShow()
	this:Show()
	if Lua_IsPrintMemMode() == 1 then
		Lua_PrintMem()
	end
end

----------------------------------------------------------------------------------------------- 数据获取 --
-- 得到大区信息 和 推荐服务器信息(放在这里，是因为较容易，并且任何时间必须的)
function SelectServer_Data_GetAreaInfoAndRecommendServerInfo()

	 	g_AreaInfo.iAreaCount = GameProduceLogin:GetServerAreaCount();
	 		
	 	g_RecommendServerInfo.iRecommendServerCount = 0;
	 	
	 	local strAreaName = "无服务器";
		local iLoginServerCount = -1;
		local ServerName;
		local ServerStatus;
		local RecommendLevel;
		local IsNew;
		local ServerPrizeLevel=0;
		local ServerVersion =""
		local nWuShenTan=0;

		local tuijian=0;
		
		--清空内容
		for i = 1, g_AreaUI.AreaCtrlCount do
			g_AreaInfo.AreaServerInfo[i].iSubAreaCount = 0;
		end		
		
	 	for index = 0, g_AreaInfo.iAreaCount - 1 do
			tuijian = 1;
			
			local strAreaName = GameProduceLogin:GetServerAreaName(index);
			local iPos = string.find( strAreaName, "-" );
			if ( iPos == nil ) then	--电信大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[3].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[3].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[3].strAreaName[iSubAreaCount] = strAreaName;
				g_AreaInfo.AreaServerInfo[3].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[3].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[3].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
					
			elseif ( string.sub(strAreaName, 1, iPos-1) == "电信" ) then		--电信大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[3].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[3].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[3].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[3].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[3].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[3].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
			
			elseif ( string.sub(strAreaName, 1, iPos-1) == "网通" ) then		--网通大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[4].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[4].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[4].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[4].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[4].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[4].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			elseif ( string.sub(strAreaName, 1, iPos-1) == "争霸赛" ) then	--争霸赛大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[2].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[2].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[2].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[2].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[2].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[2].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			elseif ( string.sub(strAreaName, 1, iPos-1) == "双线" ) then		--双线大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[5].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[5].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[5].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[5].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[5].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[5].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			elseif ( string.sub(strAreaName, 1, iPos-1) == "轻享" ) then		--轻享大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_2606S].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_2606S].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_2606S].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_2606S].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_2606S].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_2606S].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			elseif ( string.sub(strAreaName, 1, iPos-1) == "特色服" ) then		--特色服大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_SPECIAL].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_SPECIAL].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_SPECIAL].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_SPECIAL].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_SPECIAL].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_SPECIAL].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);

			elseif ( string.sub(strAreaName, 1, iPos-1) == "至尊帮派邀请赛" ) then		--至尊帮派邀请赛
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_BWDH].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_BWDH].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_BWDH].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_BWDH].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_BWDH].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_BWDH].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			elseif ( string.sub(strAreaName, 1, iPos-1) == "天下会武" ) then		--天下会武
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_TXHW].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_TXHW].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_TXHW].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_TXHW].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_TXHW].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_TXHW].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			elseif ( string.sub(strAreaName, 1, iPos-1) == "巅峰赛" ) then		--巅峰赛
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_DFS].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_DFS].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_DFS].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_DFS].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_DFS].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_DFS].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			elseif ( string.sub(strAreaName, 1, iPos-1) == "WG独立大区" ) then		--WG独立大区
				local iSubAreaCount = g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_WGONLY].iSubAreaCount + 1;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_WGONLY].iSubAreaCount = iSubAreaCount; 
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_WGONLY].strAreaName[iSubAreaCount] = string.sub(strAreaName, iPos+1);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_WGONLY].iAreaIndex[iSubAreaCount] = index;
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_WGONLY].strAreaTip[iSubAreaCount] = GameProduceLogin:GetServerAreaDis(index);
				g_AreaInfo.AreaServerInfo[g_AreaUI.AreaCtrlID_WGONLY].iRecommendLevel[iSubAreaCount] = GameProduceLogin:GetServerAreaRecommendLevel(index);
				
			end

	 		-- 设置名字.
			iLoginServerCount = GameProduceLogin:GetAreaLoginServerCount(index);
			if(iLoginServerCount > g_ServerBn.MAX_SERVER_COUNT) then
				iLoginServerCount=g_ServerBn.MAX_SERVER_COUNT;
			end
			
			--得到推荐服务器列表
			if(tuijian==1)then
				for i=0,iLoginServerCount-1 do

					ServerPrizeLevel= 0; --licehngjie赋值之后设为0

					if(g_RecommendServerInfo.iRecommendServerCount>=g_RecommendServerBn.MAX_SERVER_COUNT) then
							break;
					end;
					ServerName,
					ServerStatus,
					RecommendLevel,
					IsNew
					,_,
					ServerPrizeLevel,
					ServerVersion,
					nWuShenTan
						= GameProduceLogin:GetAreaLoginServerInfo(index, i);
						-- 推荐服务器id
					if(RecommendLevel>0 and g_RecommendServerInfo.iRecommendServerCount <g_RecommendServerBn.MAX_SERVER_COUNT and ServerStatus ~= StatMax) then
						local iServerCount = g_RecommendServerInfo.iRecommendServerCount + 1;
						g_RecommendServerInfo.iRecommendServerCount = iServerCount;
						g_RecommendServerInfo.strRecommendServerName[iServerCount] = ServerName;
						g_RecommendServerInfo.iRecommendServerIndex[iServerCount] = i;
						g_RecommendServerInfo.iRecommendServerAreaIndex[iServerCount] = index;
						g_RecommendServerInfo.iRecommendLevel[iServerCount] = RecommendLevel;
						g_RecommendServerInfo.iRecommendServerIsNew[iServerCount] = IsNew;
						g_RecommendServerInfo.iRecommendServerStatus[iServerCount] = ServerStatus;
						g_RecommendServerInfo.iRecommendServerPrizeLevel[iServerCount] = ServerPrizeLevel;
						g_RecommendServerInfo.iRecommendServerVersion[iServerCount] = ServerVersion;
						g_RecommendServerInfo.iRecommendServerWuShenTan[iServerCount] = nWuShenTan;

					end;
				end
			end;
	 	end
	 		 	
 	  --左侧大区控件，修改争霸赛的名字
 	  if tostring(g_AreaInfo.AreaServerInfo[2].strAreaName[1]) == tostring(g_ZBS_STRING) or
 	  		tostring(g_AreaInfo.AreaServerInfo[2].strAreaName[1]) == tostring(g_ZBS_STRING2) then
 	  	g_AreaInfo.AreaServerInfo[2].strAreaName[1] = g_ZBS_STRING;
 	  	g_AreaUI.AreaCtrlInfo[2].strName = "#{DLYHQF_12121302}";	--全球争霸赛总决赛
 	  	g_AreaUI.AreaCtrlInfo[2].OpenToolTipText = "#{DLYHQF_12121308}";
 	  	g_AreaUI.AreaCtrlInfo[2].CloseToolTipText = "#{DLYHQF_12121308}";
 	  else
 	  	g_AreaUI.AreaCtrlInfo[2].strName = "#{DLYHQF_12121303}";	--全球争霸赛大区赛
 	  	g_AreaUI.AreaCtrlInfo[2].OpenToolTipText = "#{DLYHQF_12121309}";
 	  	g_AreaUI.AreaCtrlInfo[2].CloseToolTipText = "#{DLYHQF_12121309}";
 	  end

end

-- 得到流畅服务器信息
function SelectServer_Data_GetFluencyServerInfo()
		
		local lastNetProvider;
		--得到上次登录服务器的NetProvider
		_,_,_,_,lastNetProvider = GameProduceLogin:GetAreaLoginServerInfo(g_curSelectArea, g_curSelectServer);
		
	 	local iCurAreaCount = GameProduceLogin:GetServerAreaCount();
	 	local strAreaName = "无服务器";
		local iLoginServerCount = -1;
		local ServerName;
		local ServerStatus;
		--推荐等级
		local RecommendLevel;
		local IsNew;
		local netPro;
		--lichengjie
		local ServerPrizeLevel=0;
		local ServerVersion = ""
		local nWuShenTan=0;
		g_FluencyServerInfo.iServerCount = 0;
		
	 	for index = 0, iCurAreaCount - 1 do
			local strAreaName = GameProduceLogin:GetServerAreaName(index);
			iLoginServerCount = GameProduceLogin:GetAreaLoginServerCount(index);
			if(iLoginServerCount > g_ServerBn.MAX_SERVER_COUNT) then
				iLoginServerCount=g_ServerBn.MAX_SERVER_COUNT;
			end

			--得到流畅服务器列表
			for i=0,iLoginServerCount-1 do
				
				ServerPrizeLevel= 0;
				ServerName,
				ServerStatus,
				RecommendLevel,
				IsNew
				,netPro,
				ServerPrizeLevel,
				ServerVersion,
				nWuShenTan
					= GameProduceLogin:GetAreaLoginServerInfo(index, i);
					-- 推荐服务器id
				--if(lastNetProvider == netPro and ServerStatus ~= StatMax and ServerStatus ~= StateStop and ServerStatus ~= 0 ) then
				if(ServerStatus ~= StatMax and ServerStatus ~= StateStop and ServerStatus ~= 0 ) then
					local bAdd = 0
					if (g_iCurSelArea ~= -1 and g_iCurSelLoginServer ~= -1) then
						if (g_curSelectArea ~= index or g_curSelectServer ~= i) then
							bAdd = 1
						end
					elseif (g_LastArea ~= -1 and g_LastServer ~= -1) then
						if (g_LastArea ~= index or g_LastServer ~= i) then
							bAdd = 1
						end
					elseif (g_curSelectArea ~= index or g_curSelectServer ~= i) then
						bAdd = 1
					end
					if (bAdd == 1) then
						g_FluencyServerInfo.iServerCount = g_FluencyServerInfo.iServerCount + 1;
						g_FluencyServerInfo.strServerName[g_FluencyServerInfo.iServerCount] = ServerName;
						g_FluencyServerInfo.iServerIndex[g_FluencyServerInfo.iServerCount] = i;
						g_FluencyServerInfo.iServerAreaIndex[g_FluencyServerInfo.iServerCount] = index;
						g_FluencyServerInfo.iLevel[g_FluencyServerInfo.iServerCount] = RecommendLevel;
						g_FluencyServerInfo.iServerIsNew[g_FluencyServerInfo.iServerCount] = IsNew;
						g_FluencyServerInfo.iServerStatus[g_FluencyServerInfo.iServerCount] = ServerStatus;
						g_FluencyServerInfo.iServerPrizeLevel[g_FluencyServerInfo.iServerCount] = ServerPrizeLevel;
						g_FluencyServerInfo.iServerVersion[g_FluencyServerInfo.iServerCount] = ServerVersion
						g_FluencyServerInfo.iServerWuShenTan[g_FluencyServerInfo.iServerCount] = nWuShenTan
					end
				end
			end
	 	end

end

--得到当前选定区域服务器信息
function SelectServer_Data_GetServerInfo( iAreaIndex )
	
	local iServerCount = GameProduceLogin:GetAreaLoginServerCount(iAreaIndex);
	if(iServerCount > g_ServerBn.MAX_SERVER_COUNT) then
		iServerCount = g_ServerBn.MAX_SERVER_COUNT;
	end
	g_ServerInfo.iServerCount = iServerCount;
	
	for index=0, iServerCount-1 do
		g_ServerInfo.strServerName[index+1]
		,g_ServerInfo.iServerStatus[index+1]
		,g_ServerInfo.iLevel[index+1]
		,g_ServerInfo.iServerIsNew[index+1]
		,_
		,g_ServerInfo.iServerPrizeLevel[index+1]
		,g_ServerInfo.iServerVersion[index+1]
		,g_ServerInfo.iServerWuShenTan[index+1]
		= GameProduceLogin:GetAreaLoginServerInfo(iAreaIndex, index);
			
		g_ServerInfo.iServerIndex[index+1] = index;
		g_ServerInfo.iServerAreaIndex[index+1] = iAreaIndex;
	end	
end

--获取所有搜索结果
function SelectServer_Data_GetSearchServerInfo( szSearchName )

	local iServerCount = GameProduceLogin:SetLoginServerKeyword(szSearchName);
	--计算页数
	if iServerCount == 85 then
		g_SearchServerPage = 1;
	else
		g_SearchServerPage = math.floor( iServerCount/(g_ServerBn.MAX_SERVER_COUNT-1) );
		if math.mod(iServerCount, (g_ServerBn.MAX_SERVER_COUNT-1)) > 0 then
			g_SearchServerPage = g_SearchServerPage +1;
		end
	end
	
	g_SearchServerInfo.iServerCount = iServerCount;
	
	for index=0, iServerCount-1 do
		g_SearchServerInfo.strServerName[index+1],
		g_SearchServerInfo.iServerStatus[index+1],
		g_SearchServerInfo.iLevel[index+1],
		g_SearchServerInfo.iServerIsNew[index+1],
		_,
		g_SearchServerInfo.iServerAreaIndex[index+1],
		_,
		g_SearchServerInfo.iServerIndex[index+1]
		,g_SearchServerInfo.iServerPrizeLevel[index+1]
		,g_SearchServerInfo.iServerVersion[index+1]
		,g_SearchServerInfo.iServerWuShenTan[index+1]
		 = GameProduceLogin:GetKeywordLoginServerInfo(index);
	end
		
end

----------------------------------------------------------------------------------------------- 数据显示 --
----按序显示推荐服务器
function SelectServer_Data_ShowRecommendServer()
			if(g_RecommendServerInfo.iRecommendServerCount>=1)then
			SelectServer_Sort_RecommendServer();

			local strName="";
			for i = 1,g_RecommendServerInfo.iRecommendServerCount do
				g_RecommendServerBn.BnServer[i]:Show();
				
				if g_RecommendServerInfo.iRecommendServerWuShenTan[i] > 0 then
					g_RecommendServerBn.BnWSTImage[i]:Show();
				else
					g_RecommendServerBn.BnWSTImage[i]:Hide();
				end
				
				local tmpAreaName = GameProduceLogin:GetServerAreaName(g_RecommendServerInfo.iRecommendServerAreaIndex[i]);
				local _i = string.find(tmpAreaName,"-");
				if(_i~=nil and _i<string.len(tmpAreaName)) then
					if(string.sub(tmpAreaName,1,_i-1)=="双线" or string.sub(tmpAreaName,1,_i-1)=="网通" 
						or string.sub(tmpAreaName,1,_i-1)=="电信" or string.sub(tmpAreaName,1,_i-1)=="争霸赛" 
						or string.sub(tmpAreaName,1,_i-1)=="特色服" or string.sub(tmpAreaName,1,_i-1)=="轻享"
						or string.sub(tmpAreaName,1,_i-1)=="WG独立大区" ) then
						tmpAreaName = string.sub(tmpAreaName,_i+1);
					end
				end
				strName =tmpAreaName.."-"..g_RecommendServerInfo.strRecommendServerName[i];
				if(g_RecommendServerInfo.iRecommendServerIsNew[i]~=0)then
					strName =strName.."#{DLYHQF_12121324}";	--(新)
				end
				if(0 == g_RecommendServerInfo.iRecommendServerStatus[i]) then
					g_RecommendServerBn.BnServer[i]:Enable();
					strName = "#cff0000#e010101"..strName.."#cffffff";
				elseif(1 == g_RecommendServerInfo.iRecommendServerStatus[i]) then
					g_RecommendServerBn.BnServer[i]:Enable();
					strName = "#cff8a00#e010101"..strName.."#cffffff";
				elseif(2 == g_RecommendServerInfo.iRecommendServerStatus[i]) then
					g_RecommendServerBn.BnServer[i]:Enable();
					strName = "#cECE58D#e010101"..strName.."#cffffff";
				elseif(3 == g_RecommendServerInfo.iRecommendServerStatus[i]) then
					g_RecommendServerBn.BnServer[i]:Enable();
					strName = "#c4CFA4C#e010101"..strName.."#cffffff";
				else
					strName = "#c959595#e010101"..strName.."#cffffff";
					g_RecommendServerBn.BnServer[i]:Disable();
				end

				g_RecommendServerBn.BnServer[i]:SetText(strName);
				g_RecommendServerBn.BnServer[i]:SetCheck(0);
					
				local strStatus = SelectServer_UI_GetServerStatusString(g_RecommendServerInfo.iRecommendServerStatus[i], -1 );
				if( g_RecommendServerInfo.iRecommendServerPrizeLevel[i] > 0) then
					local szTooltips = ""
					if g_ThreePrizeTip[g_RecommendServerInfo.iRecommendServerPrizeLevel[i]] ~= nil then
				    szTooltips = g_ThreePrizeTip[g_RecommendServerInfo.iRecommendServerPrizeLevel[i]] .. "#r"
					end
					g_RecommendServerBn.BnServer[i]:SetToolTip(szTooltips..strStatus);
					g_RecommendServerBn.BnServerAnimate[i]:SetProperty("Animate",g_ThreeCommendablePrizeAnimate[g_RecommendServerInfo.iRecommendServerPrizeLevel[i]]);
					g_RecommendServerBn.BnServerAnimate[i]:SetProperty("Visible","True");
				else
					g_RecommendServerBn.BnServer[i]:SetToolTip(strStatus);
				end
			end;
		end;
		
end

--显示流畅服务器
function SelectServer_Data_ShowFluencyServer()
	if(g_FluencyServerInfo.iServerCount>=1)then
			SelectServer_Sort_FluencyServer();

			local strName="";
			local CommendableSrv = g_FluencyServerInfo.iServerCount
			if CommendableSrv > g_RecommendServerBn.MAX_SERVER_COUNT then
				CommendableSrv = g_RecommendServerBn.MAX_SERVER_COUNT
			end
			for i = 1,CommendableSrv do
				g_FluencyServerBn.BnServer[i]:Show();
				
				if g_FluencyServerInfo.iServerWuShenTan[i] > 0 then
					g_FluencyServerBn.BnWSTImage[i]:Show();
				else
					g_FluencyServerBn.BnWSTImage[i]:Hide();
				end
				
				local tmpAreaName = GameProduceLogin:GetServerAreaName(g_FluencyServerInfo.iServerAreaIndex[i]);
				local _i = string.find(tmpAreaName,"-");
				if(_i~=nil and _i<string.len(tmpAreaName)) then
					if(string.sub(tmpAreaName,1,_i-1)=="双线" or string.sub(tmpAreaName,1,_i-1)=="网通" 
						or string.sub(tmpAreaName,1,_i-1)=="电信" or string.sub(tmpAreaName,1,_i-1)=="争霸赛" 
						or string.sub(tmpAreaName,1,_i-1)=="轻享" or string.sub(tmpAreaName,1,_i-1)=="WG独立大区" ) then
						tmpAreaName = string.sub(tmpAreaName,_i+1);
					end
				end
				strName =tmpAreaName.."-"..g_FluencyServerInfo.strServerName[i];
				if(g_FluencyServerInfo.iServerIsNew[i]~=0)then
					strName =strName.."#{DLYHQF_12121324}"; --(新)
				end
				if(0 == g_FluencyServerInfo.iServerStatus[i]) then
					g_FluencyServerBn.BnServer[i]:Enable();
					strName = "#cff0000#e010101"..strName.."#cffffff";
				elseif(1 == g_FluencyServerInfo.iServerStatus[i]) then
					g_FluencyServerBn.BnServer[i]:Enable();
					strName = "#cff8a00#e010101"..strName.."#cffffff";
				elseif(2 == g_FluencyServerInfo.iServerStatus[i]) then
					g_FluencyServerBn.BnServer[i]:Enable();
					strName = "#cECE58D#e010101"..strName.."#cffffff";
				elseif(3 == g_FluencyServerInfo.iServerStatus[i]) then
					g_FluencyServerBn.BnServer[i]:Enable();
					strName = "#c4CFA4C#e010101"..strName.."#cffffff";
				else

					strName = "#c959595#e010101"..strName.."#cffffff";
					g_FluencyServerBn.BnServer[i]:Disable();
				end

				g_FluencyServerBn.BnServer[i]:SetText(strName);
				g_FluencyServerBn.BnServer[i]:SetCheck(0);
					
				local strStatus = SelectServer_UI_GetServerStatusString(g_FluencyServerInfo.iServerStatus[i], -1 );
				if( g_FluencyServerInfo.iServerPrizeLevel[i] > 0) then
					local szTooltips = ""
					if g_ThreePrizeTip[g_FluencyServerInfo.iServerPrizeLevel[i]] ~= nil then
				    szTooltips = g_ThreePrizeTip[g_FluencyServerInfo.iServerPrizeLevel[i]] .. "#r"
					end
					g_FluencyServerBn.BnServer[i]:SetToolTip(szTooltips..strStatus);
					g_FluencyServerBn.BnServerAnimate[i]:SetProperty("Animate",g_ThreeCommendablePrizeAnimate2[g_FluencyServerInfo.iServerPrizeLevel[i]]);
					g_FluencyServerBn.BnServerAnimate[i]:SetProperty("Visible","True");
				else
					g_FluencyServerBn.BnServer[i]:SetToolTip( strStatus );
				end
								
			end;
		end;
end

--显示服务器信息
function SelectServer_Data_ShowServer()

	for index = 1, g_ServerInfo.iServerCount do
			
		g_ServerBn.BnServer[index]:Enable();
		g_ServerBn.BnServer[index]:Show();
		
		if g_ServerInfo.iServerWuShenTan[index] > 0 then
			g_ServerBn.BnWSTImage[index]:Show();
		else
			g_ServerBn.BnWSTImage[index]:Hide();
		end
			
		local strName = g_ServerInfo.strServerName[index];
		if(g_ServerInfo.iServerIsNew[index]==1)then
			strName = strName.."#{DLYHQF_12121324}"; --(新)
		end;

		if(0 == g_ServerInfo.iServerStatus[index]) then
			strName = "#cff0000#e010101"..strName.."#cffffff";
		elseif(1 == g_ServerInfo.iServerStatus[index]) then
			strName = "#cff8a00#e010101"..strName.."#cffffff";
		elseif(2 == g_ServerInfo.iServerStatus[index]) then
			strName = "#cECE58D#e010101"..strName.."#cffffff";
		elseif(3 == g_ServerInfo.iServerStatus[index]) then
			strName = "#c4CFA4C#e010101"..strName.."#cffffff";
		else
			strName = "#c959595#e010101"..strName.."#cffffff";
			g_ServerBn.BnServer[index]:Disable();
		end		
		g_ServerBn.BnServer[index]:SetText(strName);

		local strStatus = SelectServer_UI_GetServerStatusString(g_ServerInfo.iServerStatus[index], -1 );
		if(g_ServerInfo.iServerPrizeLevel[index]>0) then
			 local szTooltips = ""
			 if g_ThreePrizeTip[g_ServerInfo.iServerPrizeLevel[index]] ~= nil then
				 szTooltips = g_ThreePrizeTip[g_ServerInfo.iServerPrizeLevel[index]] .. "#r"
			 end	
		   g_ServerBn.BnServer[index]:SetToolTip(szTooltips..strStatus);
	  	 g_ServerBn.BnServerAnimate[index]:SetProperty("Animate", g_ThreePrizeAnimate[g_ServerInfo.iServerPrizeLevel[index]]);--从3个特效里面选择对应的一个，特效数组怎么写？
		   g_ServerBn.BnServerAnimate[index]:SetProperty("Visible", "True");--将特效设为显示
		 else
	 		g_ServerBn.BnServer[index]:SetToolTip( strStatus );
	  end
	end

end

--显示服务器信息
function SelectServer_Data_ShowSearchServer( pageIndex )

	-- 隐藏区域按钮.
	SelectServer_HideServerBn();
	
	if pageIndex < 1 or pageIndex > g_SearchServerPage then
		return;
	end
	
	local iBeginServer = (pageIndex-1) * (g_ServerBn.MAX_SERVER_COUNT-1);
	if iBeginServer >= g_SearchServerInfo.iServerCount then
		return;
	end
	
	g_SearchCurPage = pageIndex;	
	g_iCurShowServer = CUR_SHOW_SERVER_SEARCH_BASE + g_SearchCurPage;
	
	--显示翻页按钮
	if g_SearchServerInfo.iServerCount > g_ServerBn.MAX_SERVER_COUNT then
		SelectServer_UpPage:Show();
		SelectServer_DownPage:Show();	
			
		if pageIndex == 1 then
			SelectServer_UpPage:Disable();
		else
			SelectServer_UpPage:Enable();			
		end
		
		if pageIndex == g_SearchServerPage then
			SelectServer_DownPage:Disable();
		else
			SelectServer_DownPage:Enable();			
		end		
	else
		SelectServer_UpPage:Hide();
		SelectServer_DownPage:Hide();
	end
		
	--显示
	local iBnIndex = 1;
	local iShowCount = g_SearchServerInfo.iServerCount - iBeginServer;
	if iShowCount > g_ServerBn.MAX_SERVER_COUNT-1 then
		iShowCount = g_ServerBn.MAX_SERVER_COUNT-1;
	end
	if g_SearchServerInfo.iServerCount == g_ServerBn.MAX_SERVER_COUNT then
		iShowCount = g_ServerBn.MAX_SERVER_COUNT;
	end
	for iBnIndex = 1, iShowCount do
		local index = iBnIndex + iBeginServer;
		g_ServerBn.BnServer[iBnIndex]:SetCheck(0);
		g_ServerBn.BnServer[iBnIndex]:Enable();
		g_ServerBn.BnServer[iBnIndex]:Show();
		
		if g_SearchServerInfo.iServerWuShenTan[index] > 0 then
			g_ServerBn.BnWSTImage[iBnIndex]:Show();
		else
			g_ServerBn.BnWSTImage[iBnIndex]:Hide();
		end
			
		local strName = g_SearchServerInfo.strServerName[index];
		if(g_SearchServerInfo.iServerIsNew[index]==1)then
			strName = strName.."#{DLYHQF_12121324}"; --(新)
		end;
		
		if(0 == g_SearchServerInfo.iServerStatus[index]) then
			strName = "#cff0000#e010101"..strName.."#cffffff";
		elseif(1 == g_SearchServerInfo.iServerStatus[index]) then
			strName = "#cff8a00#e010101"..strName.."#cffffff";
		elseif(2 == g_SearchServerInfo.iServerStatus[index]) then
			strName = "#cECE58D#e010101"..strName.."#cffffff";
		elseif(3 == g_SearchServerInfo.iServerStatus[index]) then
			strName = "#c4CFA4C#e010101"..strName.."#cffffff";
		else
			strName = "#c959595#e010101"..strName.."#cffffff";
			g_ServerBn.BnServer[iBnIndex]:Disable();
		end
		
		g_ServerBn.BnServer[iBnIndex]:SetText(strName);

		local strStatus = SelectServer_UI_GetServerStatusString(g_SearchServerInfo.iServerStatus[index], -1 );
		if(g_SearchServerInfo.iServerPrizeLevel[index] > 0) then
			local szTooltips = ""
			if g_ThreePrizeTip[g_SearchServerInfo.iServerPrizeLevel[index]] ~= nil then
				szTooltips = g_ThreePrizeTip[g_SearchServerInfo.iServerPrizeLevel[index]] .. "#r"
			end
			g_ServerBn.BnServer[iBnIndex]:SetToolTip(szTooltips..strStatus );
			g_ServerBn.BnServerAnimate[iBnIndex]:SetProperty("Animate", g_ThreePrizeAnimate[g_SearchServerInfo.iServerPrizeLevel[index]]);--从3个特效里面选择对应的一个，特效数组怎么写？
			g_ServerBn.BnServerAnimate[iBnIndex]:SetProperty("Visible", "True");--将特效设为显示
		else
			g_ServerBn.BnServer[iBnIndex]:SetToolTip( strStatus );
		end

	end
	
	SelectServer_NotFlashAll();
end

-----------------------------------------------------------------------------------------------------------------------------------
--更新服务器按钮的Tooltips
function SelectServer_Update_Button_Tooltips( iAreaIndex, iServerIndex, speed ) 

	if g_iCurShowServer ~= g_PingInfo.iShowServer or 
		g_PingInfo.iAreaIndex ~= iAreaIndex or 
		g_PingInfo.iServerIndex ~= iServerIndex then
		return;
	end
		
	--当前显示的是推荐服务器
	if g_iCurShowServer == CUR_SHOW_SERVER_RECOMMEND then
		for index =1, g_RecommendServerInfo.iRecommendServerCount do
			if iServerIndex == g_RecommendServerInfo.iRecommendServerIndex[index] and iAreaIndex == g_RecommendServerInfo.iRecommendServerAreaIndex[index] then
				local strStatus = SelectServer_UI_GetServerStatusString(g_RecommendServerInfo.iRecommendServerStatus[index], speed );
				if( g_RecommendServerInfo.iRecommendServerPrizeLevel[index] > 0) then
					local szTooltips = ""
					if g_ThreePrizeTip[g_RecommendServerInfo.iRecommendServerPrizeLevel[index]] ~= nil then
						szTooltips = g_ThreePrizeTip[g_RecommendServerInfo.iRecommendServerPrizeLevel[index]] .. "\n"
					end
					g_RecommendServerBn.BnServer[index]:SetToolTip(szTooltips..strStatus);
				else
					g_RecommendServerBn.BnServer[index]:SetToolTip(strStatus);
				end
				return;
			end
		end 
	end
	
	--当前显示的是流畅服务器
	if g_iCurShowServer == CUR_SHOW_SERVER_FLUENCY then
		for index =1, g_FluencyServerInfo.iServerCount do
			if iServerIndex == g_FluencyServerInfo.iServerIndex[index] and iAreaIndex == g_FluencyServerInfo.iServerAreaIndex[index] then
				local strStatus = SelectServer_UI_GetServerStatusString(g_FluencyServerInfo.iServerStatus[index], speed );
				if( g_FluencyServerInfo.iServerPrizeLevel[index] > 0) then
					local szTooltips = ""
					if g_ThreePrizeTip[g_FluencyServerInfo.iServerPrizeLevel[index]] ~= nil then
						szTooltips = g_ThreePrizeTip[g_FluencyServerInfo.iServerPrizeLevel[index]] .. "#r"
					end
					g_FluencyServerBn.BnServer[index]:SetToolTip(szTooltips..strStatus);
				else
					g_FluencyServerBn.BnServer[index]:SetToolTip(strStatus);
				end
				return;
			end
		end 
	end
	
	
	--当前显示的是一般服务器
	if g_iCurShowServer == CUR_SHOW_SERVER then
		for index =1, g_ServerInfo.iServerCount do
			if iServerIndex == g_ServerInfo.iServerIndex[index] and iAreaIndex == g_ServerInfo.iServerAreaIndex[index] then
				local strStatus = SelectServer_UI_GetServerStatusString(g_ServerInfo.iServerStatus[index], speed );
				if( g_ServerInfo.iServerPrizeLevel[index] > 0) then
					local szTooltips = ""
					if g_ThreePrizeTip[g_ServerInfo.iServerPrizeLevel[index]] ~= nil then
						szTooltips = g_ThreePrizeTip[g_ServerInfo.iServerPrizeLevel[index]] .. "#r"
					end
					g_ServerBn.BnServer[index]:SetToolTip(szTooltips..strStatus);
				else
					g_ServerBn.BnServer[index]:SetToolTip(strStatus);
				end
				return;
			end
		end 
	end
	
	--当前显示的是搜索服务器
	if g_iCurShowServer == CUR_SHOW_SERVER_SEARCH_BASE + g_SearchCurPage then
		--计算本页显示的个数
		local iBeginServer = (g_SearchCurPage-1) * (g_ServerBn.MAX_SERVER_COUNT-1);
		if iBeginServer >= g_SearchServerInfo.iServerCount then
			return;
		end
		local iShowCount = g_SearchServerInfo.iServerCount - iBeginServer;
		if iShowCount > g_ServerBn.MAX_SERVER_COUNT-1 then
			iShowCount = g_ServerBn.MAX_SERVER_COUNT-1;
		end
		if g_SearchServerInfo.iServerCount == g_ServerBn.MAX_SERVER_COUNT then
			iShowCount = g_ServerBn.MAX_SERVER_COUNT;
		end
			
		--更新tooltip
		for index =1, iShowCount do
			local i = index + iBeginServer;
			if iServerIndex == g_SearchServerInfo.iServerIndex[i] and iAreaIndex == g_SearchServerInfo.iServerAreaIndex[i] then
				local strStatus = SelectServer_UI_GetServerStatusString(g_ServerInfo.iServerStatus[i], speed );
				if( g_SearchServerInfo.iServerPrizeLevel[i] > 0) then
					local szTooltips = ""
					if g_ThreePrizeTip[g_SearchServerInfo.iServerPrizeLevel[i]] ~= nil then
						szTooltips = g_ThreePrizeTip[g_SearchServerInfo.iServerPrizeLevel[i]] .. "#r"
					end
					g_ServerBn.BnServer[index]:SetToolTip(szTooltips..strStatus);
				else
					g_ServerBn.BnServer[index]:SetToolTip(strStatus);
				end
				return;
			end
		end 
	end
		
end
			
--负责展开大区列表(可展开时)，并设置相应大区按钮的状态
function SelectServer_SelectAreaButton( iBigArea, iSubArea, selected, flash )
	if iBigArea <= 1 or iBigArea > g_AreaUI.AreaCtrlCount then
		return
	end
	if iSubArea <=0 or iSubArea > g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount then
		return
	end
	
	--清空大区按钮状态
	SelectServer_Area_ClearAllStatus();
	
	--争霸赛设置状态
	if g_AreaUI.AreaCtrlInfo[iBigArea].MustShow == 0 then
		if g_AreaUI.AreaCtrlInfo[iBigArea].ctrl ~= nil then
			--选中
			if selected > 0 then
				g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:SetCatalogButtonSelect(true);		
			else
				g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:SetCatalogButtonSelect(false);		
			end
			
			--闪烁
			local strName = g_AreaUI.AreaCtrlInfo[iBigArea].strName;
			if flash > 0 then
				strName = "#b"..strName;
			end
			g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:AddTextCatalogTextAndImage(strName,g_AreaButtonListImage,g_AreaButtonListImageSet);			
		end
		return
	end
		
	--网通、电信、双线设置状态
	if g_AreaUI.AreaCtrlInfo[iBigArea].ShowList > 0 then
		SelectServer_Area_SubAreaButtonUpdate( iBigArea, iSubArea, flash );
	end
	
	SelectServer_Frame2_List:Flash();	
	
end

function SelectServerEvent_LastServer_Cliecked()
	if(g_LastArea ~=-1 and g_LastServer ~= -1)then	
		for i=2, g_AreaUI.AreaCtrlCount do
			
			for index =1, g_AreaInfo.AreaServerInfo[i].iSubAreaCount do
				if ( g_LastArea == g_AreaInfo.AreaServerInfo[i].iAreaIndex[index] ) then
					SelectServer_SelectAreaButton( i, index, 1, 0 );
					SelectServer_SelectAreaServer( i, index);
					SelectServerEvent_ServerBn_Clicked(g_LastServer,1);
					return;
				end
			end
			
		end
	end
	
	return;
end

-- 选择一个区域:右侧把此区域所有服务器显示出来 page:1~6, index:1~...
function SelectServer_SelectAreaServer(page, index)
	selected = 0;
	SelectServer_Help2_Text:SetText("#{FWQWL_201130_01}")

	-- 记录当前选择的区域索引.
	g_iCurSelArea = g_AreaInfo.AreaServerInfo[page].iAreaIndex[index];
	g_iCurSelLoginServer = -1;

	g_AreaUI.CurPage = page;

	-- 设置选择的名字
	SelectServer_Server_AreaNameShow:SetText( "#e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[page].strAreaName[index]);

	-- 显示服务器界面
	SelectServer_UI_ShowServerUI();
	g_iCurShowServer = CUR_SHOW_SERVER;
	
	-- 隐藏区域按钮.
	SelectServer_HideServerBn();
	
	--得到当前选定区域服务器信息
	SelectServer_Data_GetServerInfo( g_iCurSelArea );
	
	--显示服务器信息
	SelectServer_Data_ShowServer();
	
	SelectServer_NotFlashAll();
end

function DisableSelect()
		g_iCurSelLoginServer =-1;
		for i = 1,g_RecommendServerInfo.iRecommendServerCount do
				g_RecommendServerBn.BnServer[i]:SetCheck(0)
		end;
		SelectServer_NotFlashAll();
end

--------------------------------------------------------------------------------------------------------------
--
-- 从推荐列表里选择一个login server: index(1~12)
function SelectServerEvent_RecommendBn_Cliecked(index)
	-- 设置按钮选中状态.
	if(g_RecommendServerBn.BnServer[index]:GetProperty("Disabled")=="True") then
		return;
	end

	local CommendableSrvCnt = g_RecommendServerInfo.iRecommendServerCount;
	if CommendableSrvCnt > g_RecommendServerBn.MAX_SERVER_COUNT then
		CommendableSrvCnt = g_RecommendServerBn.MAX_SERVER_COUNT
	end
	for i = 1,CommendableSrvCnt do
		g_RecommendServerBn.BnServer[i]:SetCheck(0)
	end
	g_RecommendServerBn.BnServer[index]:SetCheck(1);

	--Modify by ChengJianCai 2010/03/04
	g_iCurSelArea = g_RecommendServerInfo.iRecommendServerAreaIndex[index];
	g_iCurSelLoginServer = g_RecommendServerInfo.iRecommendServerIndex[index];
			
	for i=2, g_AreaUI.AreaCtrlCount do
		for index =1, g_AreaInfo.AreaServerInfo[i].iSubAreaCount do
			if ( g_iCurSelArea == g_AreaInfo.AreaServerInfo[i].iAreaIndex[index] ) then
				SelectServer_SelectAreaButton( i, index, 0, 1 );
				return;
			end
		end
	end
end;

--------------------------------------------------------------------------------------------------------------
--选择流畅服务器:index(1~12)
function SelectServerEvent_FluencyBn_Cliecked(index)
	-- 设置按钮选中状态.
	if(g_FluencyServerBn.BnServer[index]:GetProperty("Disabled")=="True") then
		return;
	end
	local CommendableSrvCnt = g_FluencyServerInfo.iServerCount
	if CommendableSrvCnt > g_RecommendServerBn.MAX_SERVER_COUNT then
		CommendableSrvCnt = g_RecommendServerBn.MAX_SERVER_COUNT
	end
	for i = 1,CommendableSrvCnt do
		g_FluencyServerBn.BnServer[i]:SetCheck(0)
	end
	g_FluencyServerBn.BnServer[index]:SetCheck(1);
	
	--Modify by ChengJianCai 2010/03/04
	g_iCurSelArea = g_FluencyServerInfo.iServerAreaIndex[index];
	g_iCurSelLoginServer = g_FluencyServerInfo.iServerIndex[index];

	--Commendable_ShowServerInfo2(index)
	
	for i=2, g_AreaUI.AreaCtrlCount do
		for index =1, g_AreaInfo.AreaServerInfo[i].iSubAreaCount do
			if ( g_iCurSelArea == g_AreaInfo.AreaServerInfo[i].iAreaIndex[index] ) then
				SelectServer_SelectAreaButton( i, index, 0, 1 );
				return;
			end
		end
	end
end;

-- 选择一个服务器index(0~84)
function SelectServerEvent_ServerBn_Clicked(index,flash)
	if(g_ServerBn.BnServer[index+1]:GetProperty("Disabled")=="True") then
		return;
	end
	lastArea=g_iCurSelArea;
	lastServer=g_iCurSelLoginServer;
	selected = 1; 
	btnindex=index
	--如果处于搜索显示页面
	if(g_bSearch == 1) then
	
		SearchOrNormal=0;
		local SvrIndex = index + 1;
		if g_SearchCurPage >= 1 then
			SvrIndex = SvrIndex + (g_ServerBn.MAX_SERVER_COUNT-1) * (g_SearchCurPage - 1);
		end
	
		g_iCurSelArea = g_SearchServerInfo.iServerAreaIndex[SvrIndex];
		g_iCurSelLoginServer = 	g_SearchServerInfo.iServerIndex[SvrIndex];
		g_ServerBn.BnServer[index+1]:SetCheck(1);
		
		if(lastArea == nil or lastServer == nil) then
			return
		end

		if(lastArea ~= g_iCurSelArea or lastServer~=g_iCurSelLoginServer) then		
			local szWuShengTan = "";
			if g_SearchServerInfo.iServerWuShenTan[SvrIndex] == 1 then
				szWuShengTan = "#{GJHC_260424_18}";
			end
			SelectServer_Help2_Text:SetText(ScriptGlobal_Format("#{FWQWL_201130_02}", g_SearchServerInfo.strServerName[SvrIndex] )..szWuShengTan)
		end
		
		local tmpAreaName = GameProduceLogin:GetServerAreaName(g_iCurSelArea);
		local _i = string.find(tmpAreaName,"-");
		if(_i~=nil and _i<string.len(tmpAreaName)) then
			if(string.sub(tmpAreaName,1,_i-1)=="双线" or string.sub(tmpAreaName,1,_i-1)=="网通" 
						or string.sub(tmpAreaName,1,_i-1)=="电信" or string.sub(tmpAreaName,1,_i-1)=="争霸赛" 
						or string.sub(tmpAreaName,1,_i-1)=="至尊帮派邀请赛"
						or string.sub(tmpAreaName,1,_i-1)=="特色服"
						or string.sub(tmpAreaName,1,_i-1)=="天下会武"
						or string.sub(tmpAreaName,1,_i-1)=="巅峰赛"
						or string.sub(tmpAreaName,1,_i-1)=="轻享"
						or string.sub(tmpAreaName,1,_i-1)=="WG独立大区") then
				tmpAreaName = string.sub(tmpAreaName,_i+1);
			end
		end
		
		--推荐选择代理服务器
		LoginSelectServer_RecommendNetProvider();
		
		--大区部分处理：1，争霸赛按钮闪烁；2，其它大区，展开并闪烁
		for i=2, g_AreaUI.AreaCtrlCount do			
			for index =1, g_AreaInfo.AreaServerInfo[i].iSubAreaCount do
				if ( g_iCurSelArea == g_AreaInfo.AreaServerInfo[i].iAreaIndex[index] ) then
					SelectServer_SelectAreaButton( i, index, 0, 1 );
					return;
				end
			end			
		end
		return;
	end

	SearchOrNormal=1;
	-- 记录当前选择的login server
	g_iCurSelLoginServer = index;

	if(g_LastServer == g_iCurSelLoginServer and g_LastArea == g_iCurSelArea)then
		SelectServer_Server_Last:SetCheck(1);
	else
		SelectServer_Server_Last:SetCheck(0);
	end

	if(flash==1)then
		g_ServerBn.BnServer[index+1]:FlashMe(1);
	else
		SelectServer_NotFlashAll();
	end
		--推荐选择代理服务器
    LoginSelectServer_RecommendNetProvider();

	-- 设置按钮选中状态.
	g_ServerBn.BnServer[index+1]:SetCheck(1);
	
	if(lastArea == nil or lastServer == nil) then
		return
	end
	
	if(lastArea ~= g_iCurSelArea or lastServer~=g_iCurSelLoginServer) then		
		local szWuShengTan = "";
		if g_ServerInfo.iServerWuShenTan[index+1] == 1 then
			szWuShengTan = "#{GJHC_260424_18}";
		end
		SelectServer_Help2_Text:SetText(ScriptGlobal_Format("#{FWQWL_201130_02}", g_ServerInfo.strServerName[index+1] )..szWuShengTan)
	end
end

function SelectServer_NotFlashAll()
	for i=1,g_ServerBn.MAX_SERVER_COUNT do
		g_ServerBn.BnServer[i]:FlashMe(0);
		g_ServerBn.BnServer[i]:SetCheck(0);
	end
end

-- 双击选择一个服务器。index(0~84)
function SelectServerEvent_ServerBn_DoubleClicked(index)
	-- 选中一个login server
	SelectServerEvent_ServerBn_Clicked(index,0);

	-- 确认选择一个服务器
	SelectServerEvent_SelectOk();

end;

-- 双击选择一个服务器。
function SelectServerEvent_LastServer_DoubleClick()

	-- 选中一个login server
	SelectServerEvent_LastServer_Cliecked();

	-- 确认选择一个服务器
	SelectServerEvent_SelectOk();

end;
-- 双击选择一个服务器。index(1~12)
function SelectServerEvent_RecommendBn_DoubleClieck(index)
	-- 选中一个login server
	SelectServerEvent_RecommendBn_Cliecked(index);

	-- 确认选择一个服务器
	SelectServerEvent_SelectOk();

end;

-- 双击选择一个服务器。index(1~12)
function SelectServerEvent_FluencyBn_DoubleClieck(index)
	-- 选中一个login server
	SelectServerEvent_FluencyBn_Cliecked(index);

	-- 确认选择一个服务器
	SelectServerEvent_SelectOk();

end;

--显示流畅服务器
function SelectServer_UI_ShowFluencyServerUI()
	g_bCommendSrvShow = 1
	g_bSearch = 0;
	g_iCurShowServer = CUR_SHOW_SERVER_FLUENCY;
	SelectServer_Frame2_Sub2:Hide();
	SelectServer_Frame2_Sub1:Hide();
	SelectServer_Frame2_Sub4:Show();
	SelectServer_HideFluencyServerBn()
	SelectServer_Frame2_Sub1:StartFade(0,1,0.3);
					
end

--显示推荐服务器界面
function SelectServer_UI_ShowRecommendServerUI()
	g_bCommendSrvShow = 0
	g_bSearch = 0;
	g_iCurShowServer = CUR_SHOW_SERVER_RECOMMEND;
	SelectServer_UpPage:Hide();
	SelectServer_DownPage:Hide();
	SelectServer_Frame2_Sub4:Hide();
	SelectServer_Frame2_Sub2:Hide();
	SelectServer_Frame2_Sub1:Show();
	g_iCurSelLoginServer =-1;
	SelectServer_Frame2_Sub1:StartFade(0,1,0.3);
		
end

--显示服务器界面
function SelectServer_UI_ShowServerUI()
	g_bCommendSrvShow = 0
	g_bSearch = 0;
	SelectServer_Frame2_Sub4:Hide();
	SelectServer_Frame2_Sub1:Hide();
	SelectServer_Frame2_Sub2:Show();
	SelectServer_Frame2_Sub2:StartFade(0,1,0.3);
		
end


--搜索按钮
function SelectServerEvent_Search_OK()
	local szSearchName = SelectServer_Server_SearchName:GetText();
	--去除字符串首尾的空格
	szSearchName = string.gsub(szSearchName, "^%s*(.-)%s*$", "%1");
	SelectServer_Server_SearchName:SetText(szSearchName)
	if (szSearchName == "") then
		return;
	end

	--清空大区按钮所有状态
	SelectServer_Area_ClearAllStatus();	
		
	--获取所有搜索结果
	SelectServer_Data_GetSearchServerInfo( szSearchName );
	
	--显示服务器界面
	SelectServer_UI_ShowServerUI();
		
	g_bSearch = 1;
	g_SearchCurPage = 0;
	g_AreaUI.CurPage = 0;		--设置当前没有选择大区按钮
	
	if ( g_SearchServerInfo.iServerCount == 0) then
		SelectServer_Server_AreaNameShow:SetText("#{DLYHQF_12121317}"); --未找到相匹配结果
	else
		SelectServer_Server_AreaNameShow:SetText("#{DLYHQF_12121316}");	--搜索结果
	end
	
	--显示服务器信息 --显示第一页
	SelectServer_Data_ShowSearchServer( 1 );
	
end

--得到并显示流畅服务器
function SelectServer_ShowFluencyServer()

	SelectServer_Server_SearchName:SetText("");
	
	--显示流畅服务器的界面	
	SelectServer_UI_ShowFluencyServerUI();
	
	--得到流畅服务器数据
	SelectServer_Data_GetFluencyServerInfo();
	
	--显示流畅服务器
	SelectServer_Data_ShowFluencyServer()
	
	--ClearServerTextInfo()
	if(g_LastServerName~="") then
		SelectServer_Server_Last:SetCheck(1);
	end
	g_iCurSelLoginServer =-1
	
end

----------------------------------------------------------------------------------------------- 界面UI --
function SelectServer_HideFluencyServerBn()
	for i = 1,g_RecommendServerBn.MAX_SERVER_COUNT do
		g_FluencyServerBn.BnServer[i]:Hide();
		g_FluencyServerBn.BnServer[i]:SetToolTip("");
		g_FluencyServerBn.BnServerAnimate[i]:SetProperty("Animate","");
		g_FluencyServerBn.BnServerAnimate[i]:SetProperty("Visible","False");
		--lichengjie
	end;
end
function SelectServer_HideRecommendServerBn()
	for i = 1,g_RecommendServerBn.MAX_SERVER_COUNT do
		g_RecommendServerBn.BnServer[i]:Hide();
		g_RecommendServerBn.BnWSTImage[i]:Hide();
		g_RecommendServerBn.BnServer[i]:SetToolTip("");
		g_RecommendServerBn.BnServerAnimate[i]:SetProperty("Animate","");
		g_RecommendServerBn.BnServerAnimate[i]:SetProperty("Visible","False");
		--g_RecommendServerInfo.iRecommendServerPrizeLevel[i] = 0;
	end;
end

-- 隐藏login server 按钮
function SelectServer_HideServerBn()

	local index;
	for index = 1, g_ServerBn.MAX_SERVER_COUNT  do
 		g_ServerBn.BnServer[index]:Hide();
 		g_ServerBn.BnWSTImage[index]:Hide();
		g_ServerBn.BnServer[index]:SetToolTip("");
		g_ServerBn.BnServerAnimate[index]:SetProperty("Animate","");
		g_ServerBn.BnServerAnimate[index]:SetProperty("Visible","False");
		g_ServerInfo.iServerPrizeLevel[index] = 0;
 	end
 	
 	SelectServer_UpPage:Hide();
	SelectServer_DownPage:Hide();

end

--返回字符串：状态：xx #r 网络速度：yy #r 网络延迟：zz
function SelectServer_UI_GetServerStatusString( iStatus, iNetSpeed )
	
	--状态
	local strStatus;
	if(0 == iStatus) then
		strStatus = "#{DLYHQF_12121326}"	--"#e010101#cff0000爆满#cffffff";
	elseif(1 == iStatus) then
		strStatus = "#{DLYHQF_12121327}"	--"#e010101#c9E5705繁忙#cffffff";
	elseif(2 == iStatus) then
		strStatus = "#{DLYHQF_12121328}"	--"#e010101#cECE58D良好#cffffff";
	elseif(3 == iStatus) then
		strStatus = "#{DLYHQF_12121329}"	--"#e010101#c4CFA4C极佳#cffffff";
	else
		strStatus = "#{DLYHQF_12121330}"	--"#e010101#c959595维护#cffffff";
	end
	
	--网络速度
	local strSpeed = g_NetSpeed[3];
	local strDelay = "#{DLYHQF_12121332}";	--"未知";
	if ( iNetSpeed >= 0 ) then
		if ( iNetSpeed <= g_CriticalSpeed ) then
			strSpeed = g_NetSpeed[1];
		elseif ( iNetSpeed <= g_CriticalSpeed2 ) then
			strSpeed = g_NetSpeed[2];
		elseif ( iNetSpeed <= g_CriticalSpeed3 ) then
			strSpeed = g_NetSpeed[4];
		else
			strSpeed = g_NetSpeed[3];
		end
		strDelay = tostring(iNetSpeed);
	end
	
	--状态:xxx 网络速度:yyy 网络延迟:zzz
	local strRet = "#{DLYHQF_12121325}"..strStatus;		--.."#r"..strSpeed.."#r#{DLYHQF_12121331}"..strDelay;
	return strRet;
	
end
----------------------------------------------------------------------------------------------- 鼠标点击 --
function SelectServer_Area_KeepSubAreaStatus( nIndex )
	--清空所有的选中状态
	local BigArea = g_nAreaButtonInfo[nIndex].BigArea;
	for SubArea = 1, g_AreaInfo.AreaServerInfo[BigArea].iSubAreaCount do
		if nil ~= g_AreaInfo.AreaServerInfo[BigArea].button[SubArea] then
			g_AreaInfo.AreaServerInfo[BigArea].button[SubArea]:SetTextCatalogSelected(false);	--不选中
		end
	end
	
	if g_nCurSelSubArea ~= nil then
		local iBigArea = g_nCurSelSubArea.iBigArea;
		local iSubArea = g_nCurSelSubArea.iSubArea;
		if iBigArea ~= nil and iSubArea ~= nil and g_AreaInfo.AreaServerInfo[iBigArea] ~= nil and g_AreaInfo.AreaServerInfo[iBigArea].button[iSubArea] ~= nil then
			
			g_AreaInfo.AreaServerInfo[iBigArea].button[iSubArea]:SetTextCatalogSelected(true);	--选中
		end
	end

end

function SelectServerEvent_ListContentItemRClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1;
	if nIndex <= 0 then
		return
	end
		
	if nil == g_nAreaButton[nIndex] or nil == g_nAreaButtonInfo[nIndex] then
		return 
	end
	
	if g_nAreaButtonInfo[nIndex].AreaType == 1 then		-- 子区
		
		SelectServer_Area_KeepSubAreaStatus( nIndex );
		
		SelectServer_Frame2_List:Flash();
		
	end	
	
end

function SelectServerEvent_ListContentItemMouseEnter()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	local nIndex = CurClickIndex + 1;
	
	if nIndex <= 0 or nIndex > table.getn(g_nAreaButton) then
		return
	end
	
	if nil == g_nAreaButton[nIndex] or nil == g_nAreaButtonInfo[nIndex] then
		return 
	end

	local iBigArea = g_nAreaButtonInfo[nIndex].BigArea;
	local iSubArea = g_nAreaButtonInfo[nIndex].SubArea;	
	if g_nAreaButtonInfo[nIndex].AreaType == 1 then		-- 子区

		if iBigArea ~= nil and iSubArea ~= nil and g_AreaInfo.AreaServerInfo[iBigArea] ~= nil then
				
			local strText = g_AreaInfo.AreaServerInfo[iBigArea].strAreaTip[iSubArea];
			if strText ~= nil then
				SelectServer_Info:SetText( strText );
			end
		end
		
	elseif g_nAreaButtonInfo[nIndex].AreaType == 0 then	--大区
	
		if iBigArea ~= nil then
			if g_AreaUI.AreaCtrlInfo[iBigArea].CurShowList > 0 then
				SelectServer_Info:SetText( g_AreaUI.AreaCtrlInfo[iBigArea].CloseToolTipText );
			else
				SelectServer_Info:SetText( g_AreaUI.AreaCtrlInfo[iBigArea].OpenToolTipText );
			end
		end
		
	end
	
end

function SelectServerEvent_ListContentItemMouseLeave()

	SelectServer_Info:SetText("");
	
end

--单击区域控件
function SelectServerEvent_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if CurClickIndex + 1 > 0 then
		g_nCurSelectListIndex =	CurClickIndex + 1
	else
		return
	end
	
	SelectServerEvent_Area_SwitchPage( g_nCurSelectListIndex );
end

--切换到指定页面，nIndex有可能是大区，也有可能是小区
function SelectServerEvent_Area_SwitchPage( nIndex )

	--清空所有状态
	SelectServer_Area_ClearAllStatus();
	
	--刷新区域按钮状态
	SelectServerEvent_AreaButtonUpdate( nIndex, 0 );
	
	--刷新区域对应服务器
	SelectServerEvent_AreaUpdate( nIndex );
	
	SelectServer_Frame2_List:Flash();
	
end

function SelectServerEvent_AreaButtonUpdate( nIndex, flash )
	if nIndex <= 0 or nIndex > table.getn(g_nAreaButton) then
		return
	end
	
	if nil == g_nAreaButton[nIndex] or nil == g_nAreaButtonInfo[nIndex] then
		return 
	end
	
	if g_nAreaButtonInfo[nIndex].AreaType == 0 then		-- 大区
	
		SelectServer_Area_BigAreaButtonUpdate( g_nAreaButtonInfo[nIndex].BigArea, flash );		
		
	elseif g_nAreaButtonInfo[nIndex].AreaType == 1 then		-- 子区
	
		--SelectServer_Area_BigAreaUpdate( g_nAreaButtonInfo[nIndex].BigArea );
		SelectServer_Area_SubAreaButtonUpdate( g_nAreaButtonInfo[nIndex].BigArea, g_nAreaButtonInfo[nIndex].SubArea, flash );
		
	end
	
end

--点击小区按钮，更新子区按钮状态
function SelectServer_Area_SubAreaButtonUpdate( iBigArea, iSubArea, flash )
	if iBigArea <= 0 or iBigArea > g_AreaUI.AreaCtrlCount then
		return
	end
	if iSubArea <=0 or iSubArea > g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount then
		return
	end
	
	--显示当前大区下的所有子区，因为前面已全部隐藏掉了。唉
	for SubArea = 1, g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount do
		if nil ~= g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea] then
			g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:Show();	--子区全部显示
			g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:SetTextCatalogSelected(false);	--不选中
			if g_AreaInfo.AreaServerInfo[iBigArea].iRecommendLevel[SubArea] > 0 then
				g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:AddTextTextAndImage( "#-50#e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[SubArea] ,"","");
			else
				g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:AddTextTextAndImage( "    #e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[SubArea] ,"","");
			end
		end
	end
	
	--设置所属大区按钮的状态
	if nil ~= g_AreaUI.AreaCtrlInfo[iBigArea] and nil ~= g_AreaUI.AreaCtrlInfo[iBigArea].ctrl then
		g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:SetCatalogButtonSelect(true);
	end
	
	--设置子区按钮的状态
	if nil ~= g_AreaInfo.AreaServerInfo[iBigArea].button[iSubArea] then
		g_AreaInfo.AreaServerInfo[iBigArea].button[iSubArea]:SetTextCatalogSelected(true);	--选中
		g_nCurSelSubArea.iBigArea = iBigArea;
		g_nCurSelSubArea.iSubArea = iSubArea;
		if flash > 0 then
			if g_AreaInfo.AreaServerInfo[iBigArea].iRecommendLevel[iSubArea] > 0 then
				g_AreaInfo.AreaServerInfo[iBigArea].button[iSubArea]:AddTextTextAndImage( "#b#-50#e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[iSubArea] ,"","");
			else
				g_AreaInfo.AreaServerInfo[iBigArea].button[iSubArea]:AddTextTextAndImage( "#b    #e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[iSubArea] ,"","");
			end
		end
	end
	
end

--点击大区按钮，更新大区按钮状态
function SelectServer_Area_BigAreaButtonUpdate( iBigArea, flash )
	if iBigArea <= 0 or iBigArea > g_AreaUI.AreaCtrlCount then
		return
	end
	
	--先把所有的状态置为不显示
	local iOldCurShowList = g_AreaUI.AreaCtrlInfo[iBigArea].CurShowList;
	SelectServer_Area_ClearAllBigAreaShowListStatus();
	
	--推荐服务器 & 争霸赛
	if g_AreaUI.AreaCtrlInfo[iBigArea].ShowList <= 0 and nil ~= g_AreaUI.AreaCtrlInfo[iBigArea].ctrl then
		g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:SetCatalogButtonSelect(true);
		if flash > 0 then
			g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:AddTextCatalogTextAndImage("#b"..g_AreaUI.AreaCtrlInfo[iBigArea].strName,g_AreaButtonListImage,g_AreaButtonListImageSet);
		end
	end
	
	--其它区域，如果展开状态，则关闭；如果关闭状态，则展开
	if g_AreaUI.AreaCtrlInfo[iBigArea].ShowList > 0 then
		if iOldCurShowList > 0 then
			g_AreaUI.AreaCtrlInfo[iBigArea].CurShowList = 0;
			
			--设置为非选中，不闪烁
			g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:SetCatalogButtonSelect(false);
		
		else			
			g_AreaUI.AreaCtrlInfo[iBigArea].CurShowList = 1;
			g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:SetToolTip( g_AreaUI.AreaCtrlInfo[iBigArea].CloseToolTipText );
			
			g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:SetCatalogButtonSelect(true);
			if flash > 0 then
				g_AreaUI.AreaCtrlInfo[iBigArea].ctrl:AddTextCatalogTextAndImage("#b"..g_AreaUI.AreaCtrlInfo[iBigArea].strName,g_AreaButtonListImage,g_AreaButtonListImageSet);
			end
			
			--显示所有子区域
			for SubArea = 1, g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount do
				if nil ~= g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea] then
					g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:Show();	--子区全部显示
					g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:SetTextCatalogSelected(false);	--不选中
						
					if g_AreaInfo.AreaServerInfo[iBigArea].iRecommendLevel[SubArea] > 0 then
						g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:AddTextTextAndImage( "#-50#e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[SubArea] ,"","");
					else
						g_AreaInfo.AreaServerInfo[iBigArea].button[SubArea]:AddTextTextAndImage( "    #e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[SubArea] ,"","");
					end
				end
			end
			
		end
	end	
	
end

--响应选中区域按钮的事件
function SelectServerEvent_AreaUpdate( nIndex )
	if nIndex <= 0 or nIndex > table.getn(g_nAreaButton) then
		return
	end
	
	if nil == g_nAreaButton[nIndex] or nil == g_nAreaButtonInfo[nIndex] then
		return 
	end

	if g_nAreaButtonInfo[nIndex].AreaType == 0 then		-- 大区

		SelectServer_Area_BigAreaUpdate( g_nAreaButtonInfo[nIndex].BigArea );
		
	elseif g_nAreaButtonInfo[nIndex].AreaType == 1 then		-- 子区

		--SelectServer_Area_BigAreaUpdate( g_nAreaButtonInfo[nIndex].BigArea );
		SelectServer_Area_SubAreaUpdate( g_nAreaButtonInfo[nIndex].BigArea, g_nAreaButtonInfo[nIndex].SubArea );
		
	end
	
end

--点击小区按钮，显示当前区域下所有服务器
function SelectServer_Area_SubAreaUpdate( iBigArea, iSubArea )
	if iBigArea <= 0 or iBigArea > g_AreaUI.AreaCtrlCount then
		return
	end
	if iSubArea <=0 or iSubArea > g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount then
		return
	end
	
	--右侧显示子区下的所有服务器
	SelectServer_SelectAreaServer( iBigArea, iSubArea );
	
end

--点击大区按钮
function SelectServer_Area_BigAreaUpdate( iBigArea )
	if iBigArea <= 0 or iBigArea > g_AreaUI.AreaCtrlCount then
		return
	end
	selected = 0;
	SelectServer_Help2_Text:SetText("#{FWQWL_201130_01}")
	--右侧显示推荐服务器内容
	if iBigArea == 1 then
	
		-- 显示推荐服务器界面
		SelectServer_UI_ShowRecommendServerUI();
		
		-- 隐藏所有推荐服务器
		SelectServer_HideRecommendServerBn();		
		
		--显示所有推荐服务器数据
		SelectServer_Data_ShowRecommendServer();
	
	end
	
	--右侧显示争霸赛服务器内容
	if g_AreaUI.AreaCtrlInfo[iBigArea].MustShow == 0 then
		if g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount >= 1 then
			SelectServer_SelectAreaServer( iBigArea, 1 );
		end
	end
	
	--展开与否的状态已更新。只需要检查是否需要显示子区即可
	if g_AreaUI.AreaCtrlInfo[iBigArea].ShowList > 0 then
		if g_AreaUI.AreaCtrlInfo[iBigArea].CurShowList > 0 then
			--显示第一个子区服务器，并选中子区控件
			SelectServer_Area_SubAreaButtonUpdate( iBigArea, 1, 0 );
			
			SelectServer_Area_SubAreaUpdate( iBigArea, 1 );
		end
	end
		
end

--把所有的状态置为不显示
function SelectServer_Area_ClearAllBigAreaShowListStatus()

	for i=0, g_AreaUI.AreaCtrlCount do
		if g_AreaUI.AreaCtrlInfo[i] ~= nil and g_AreaUI.AreaCtrlInfo[i].ctrl ~= nil then
			g_AreaUI.AreaCtrlInfo[i].CurShowList = 0;
			g_AreaUI.AreaCtrlInfo[i].ctrl:SetToolTip( g_AreaUI.AreaCtrlInfo[i].OpenToolTipText );
		end
	end
end

--清除区域控件的所有状态
function SelectServer_Area_ClearAllStatus()

	for BigArea = 1, g_AreaUI.AreaCtrlCount do
	
		--清空大区的选中与闪烁
		if g_AreaUI.AreaCtrlInfo[BigArea].ctrl ~= nil then
			g_AreaUI.AreaCtrlInfo[BigArea].ctrl:SetCatalogButtonSelect(false);
			g_AreaUI.AreaCtrlInfo[BigArea].ctrl:AddTextCatalogTextAndImage(g_AreaUI.AreaCtrlInfo[BigArea].strName,g_AreaButtonListImage,g_AreaButtonListImageSet);
		end
		
		for SubArea = 1, g_AreaInfo.AreaServerInfo[BigArea].iSubAreaCount do
			--清空小区的选中与闪烁
			if nil ~= g_AreaInfo.AreaServerInfo[BigArea].button[SubArea] then
				g_AreaInfo.AreaServerInfo[BigArea].button[SubArea]:Hide();	--子区全部隐藏
				g_AreaInfo.AreaServerInfo[BigArea].button[SubArea]:SetTextCatalogSelected(false);	--不选中
					
				if g_AreaInfo.AreaServerInfo[BigArea].iRecommendLevel[SubArea] > 0 then
					g_AreaInfo.AreaServerInfo[BigArea].button[SubArea]:AddTextTextAndImage( "#-50#e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[BigArea].strAreaName[SubArea] ,"","");
				else
					g_AreaInfo.AreaServerInfo[BigArea].button[SubArea]:AddTextTextAndImage( "    #e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[BigArea].strAreaName[SubArea] ,"","");
				end				
			end
		end
		
	end
	
	SelectServer_Frame2_List:Flash();
	
end

--填充所有区域信息
function SelectServer_AddAllAreaButton()

	SelectServer_Frame2_List:CleanAllElement("LoginSelectServer")
	SelectServer_Frame2_List:SetVertScrollbarHide();
		
	g_nAreaButton = {};
	g_nAreaButtonInfo = {};
	for BigArea = 1, g_AreaUI.AreaCtrlCount do
		g_AreaUI.AreaCtrlInfo[BigArea].ctrl = nil;
	end
		
	--显示大区
	for iBigArea=1, g_AreaUI.AreaCtrlCount do
	
		if g_AreaUI.AreaCtrlInfo[iBigArea].MustShow > 0 or g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount > 0 then
		
			--创建大区控件
			SelectServer_AddBigArea( iBigArea );
			SelectServer_AddAreaButtonInfo( 0, iBigArea, -1 );
			
			--创建小区控件
			if g_AreaUI.AreaCtrlInfo[iBigArea].ShowList > 0 then
				for iSubArea=1, g_AreaInfo.AreaServerInfo[iBigArea].iSubAreaCount do
					SelectServer_AddSubArea( iBigArea, iSubArea );
					SelectServer_AddAreaButtonInfo( 1, iBigArea, iSubArea );
				end							
			end
			
		end
		
	end

	SelectServer_Area_ClearAllBigAreaShowListStatus();
	SelectServer_Frame2_List:Flash();
	
end

--增加大区
function SelectServer_AddBigArea( iAreaIndex )
	local BigAreaButton = SelectServer_Frame2_List:AddItemElement( "SelectServerCatalog", "LEFT", "LoginSelectServer","" ,"")
	BigAreaButton:SetProperty("AchievementWindowCatalogButtonHover","SelectServerHoverSection")
	BigAreaButton:AddTextCatalogTextAndImage(g_AreaUI.AreaCtrlInfo[iAreaIndex].strName,g_AreaButtonListImage,g_AreaButtonListImageSet);
	BigAreaButton:SetToolTip( g_AreaUI.AreaCtrlInfo[iAreaIndex].OpenToolTipText );
	g_AreaUI.AreaCtrlInfo[iAreaIndex].ctrl = BigAreaButton;
	table.insert(g_nAreaButton, BigAreaButton)
end


--增加小区
function SelectServer_AddSubArea(iBigArea, iSubArea)
	local SubAreaButton = SelectServer_Frame2_List:AddItemElement("SelectServerText","LEFT","LoginSelectServer","","")
	SubAreaButton:SetProperty("AchievementWindowButtonTextHover","SelectServerHoverSection")
		
	if g_AreaInfo.AreaServerInfo[iBigArea].iRecommendLevel[iSubArea] > 0 then
		SubAreaButton:AddTextTextAndImage( "#-50#e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[iSubArea] ,"","")
	else
		SubAreaButton:AddTextTextAndImage( "    #e010101#gFF0FA0"..g_AreaInfo.AreaServerInfo[iBigArea].strAreaName[iSubArea] ,"","")
	end
		
	SubAreaButton:SetToolTip( g_AreaInfo.AreaServerInfo[iBigArea].strAreaTip[iSubArea] );
	SubAreaButton:Hide()		--刚开始子控件不可见
	g_AreaInfo.AreaServerInfo[iBigArea].button[iSubArea] = SubAreaButton;
	table.insert(g_nAreaButton, SubAreaButton)
end

--记录区域按钮信息
function SelectServer_AddAreaButtonInfo( iAreaType, iBigArea, iSubArea )

	local info = {};
	info.AreaType = iAreaType;	--0为大区，1为小区
	info.BigArea = iBigArea;
	info.SubArea = iSubArea;
	
	table.insert( g_nAreaButtonInfo, info );
end

--  确定选择一个服务器
function SelectServerEvent_SelectOk()
	g_curSelectArea = g_iCurSelArea;
	g_curSelectServer = g_iCurSelLoginServer;
		
	--选择Last服务器 Modify by ChengJiancai 2010/03/10
	if(g_iCurSelArea == -1 or g_iCurSelLoginServer == -1) and g_LastServerState ~= StateStop then
		GameProduceLogin:SelectLoginServer(g_LastArea, g_LastServer, g_iNetProvide);
		g_curSelectArea = g_LastArea
		g_curSelectServer = g_LastServer
	else
		GameProduceLogin:SelectLoginServer(g_iCurSelArea, g_iCurSelLoginServer, g_iNetProvide);
	end
	return;
end

--   退出游戏
function SelectServerEvent_Exit()
	QuitApplication("quit");
end

--刷新按钮
function SelectServerEvent_FreshPage()
	if g_bCommendSrvShow == 1 then
		SelectServer_ShowFluencyServer();
		return
	end
	GameProduceLogin:LoadLaunch();
end

--申请帐号
function SelectServerEvent_AccountReg()
    GameProduceLogin:StartAccountReg()
end

--帐号充值
function SelectServerEvent_Payment_Clicked()
	if(Variable:GetVariable("System_CodePage") == "1258") then
    GameProduceLogin:OpenURL(GetWeblink("WEB_LOGON_VN"))
	else
    GameProduceLogin:OpenURL(GetWeblink("WEB_LOGON_MAIN"))
  end
end

--角色查询
function SelectServerEvent_RoleInquiry()
	--GameProduceLogin:OpenURL(GetWeblink("WEB_ROLE_INQUIRY"))
	LuaFindRoleByAcc()
end

function SelectServerEvent_shangyibu_click()
	--GameProduceLogin:GoToCampaignDlg();
end

function SelectServerEvent_ReturnAreaSelect_click()
	--SelectServer_UI_ShowRecommendServerUI();
	--ClearServerTextInfo();
end

--搜索服务器页面，上一页
function SelectServerEvent_Search_UpPage()
	SelectServer_Data_ShowSearchServer( g_SearchCurPage - 1 );
end

--搜索服务器页面，下一页
function SelectServerEvent_Search_DownPage()
	SelectServer_Data_ShowSearchServer( g_SearchCurPage + 1 );
end

function LoginSelectServer_RecommendNetProvider()
	local loginServerNetProvider;
	--得到当前loginServer的NetProvider
	if(g_iCurSelArea == -1 or g_iCurSelLoginServer == -1) and g_LastServerState ~= StateStop then
		_,_,_,_,loginServerNetProvider = GameProduceLogin:GetAreaLoginServerInfo(g_LastArea, g_LastServer);
	else
		_,_,_,_,loginServerNetProvider = GameProduceLogin:GetAreaLoginServerInfo(g_iCurSelArea, g_iCurSelLoginServer);
	end
end

function SelectServerEvent_LineChanged()
	local str , nIndex = SelectServer_LineSelect:GetCurrentSelect()
	if g_AllNetProvide[nIndex] ~= nil then
		g_iNetProvide = g_AllNetProvide[nIndex]
	end
end

----------------------------------------------------------------------------------------------- 鼠标事件 --

-- 鼠标进入推荐服务器: index(1~12)
function SelectServerEvent_RecommendBn_MouseEnter(index)
	if(g_RecommendServerInfo.iRecommendServerPrizeLevel[index] > 0 and g_ThreePrizeTip[g_RecommendServerInfo.iRecommendServerPrizeLevel[index]] ~= nil ) then
		SelectServer_Info:SetText(g_ThreePrizeTip[g_RecommendServerInfo.iRecommendServerPrizeLevel[index]]);
	else
		local szWuShengTan = "";
		if g_RecommendServerInfo.iRecommendServerWuShenTan[index] == 1 then
			szWuShengTan = "#{GJHC_260424_18}";
		end
		SelectServer_Info:SetText(g_RecommendServerInfo.strRecommendServerName[index]..tostring("#{DLYHQF_12121333}")..szWuShengTan);
	end
	
	g_PingInfo.iShowServer = CUR_SHOW_SERVER_RECOMMEND;
	g_PingInfo.iAreaIndex = g_RecommendServerInfo.iRecommendServerAreaIndex[index];
	g_PingInfo.iServerIndex = g_RecommendServerInfo.iRecommendServerIndex[index];
end

-- 鼠标进入流畅服务器: index(1~12)
function SelectServerEvent_FluencyBn_MouseEnter(index)
	if(g_FluencyServerInfo.iServerPrizeLevel[index] > 0 and g_ThreePrizeTip[g_FluencyServerInfo.iServerPrizeLevel[index]] ~= nil ) then
		SelectServer_Info:SetText(g_ThreePrizeTip[g_FluencyServerInfo.iServerPrizeLevel[index]]);
	else
		local szWuShengTan = "";
		if g_FluencyServerInfo.iServerWuShenTan[index] == 1 then
			szWuShengTan = "#{GJHC_260424_18}";
		end
		SelectServer_Info:SetText(g_FluencyServerInfo.strServerName[index]..tostring("#{DLYHQF_12121333}")..szWuShengTan);
	end
	
	g_PingInfo.iShowServer = CUR_SHOW_SERVER_FLUENCY;
	g_PingInfo.iAreaIndex = g_FluencyServerInfo.iServerAreaIndex[index];
	g_PingInfo.iServerIndex = g_FluencyServerInfo.iServerIndex[index];
end

-- 鼠标进入服务器按钮 index(0~84)
function SelectServerEvent_ServerBn_MouseEnter(index)
	if (g_bSearch == 1 ) then
		local SvrIndex = index + 1;
		if g_SearchCurPage >= 1 then
			SvrIndex = SvrIndex + (g_ServerBn.MAX_SERVER_COUNT-1) * (g_SearchCurPage - 1);
		end
		
		if (g_SearchServerInfo.iServerPrizeLevel[SvrIndex] > 0 and g_ThreePrizeTip[g_SearchServerInfo.iServerPrizeLevel[SvrIndex]] ~= nil ) then
			SelectServer_Info:SetText(g_ThreePrizeTip[g_SearchServerInfo.iServerPrizeLevel[SvrIndex]]);
		else
			local szWuShengTan = "";
			if g_SearchServerInfo.iServerWuShenTan[SvrIndex] == 1 then
				szWuShengTan = "#{GJHC_260424_18}";
			end
			SelectServer_Info:SetText(g_SearchServerInfo.strServerName[SvrIndex]..tostring("#{DLYHQF_12121333}")..szWuShengTan);
		end
		
		g_PingInfo.iShowServer = CUR_SHOW_SERVER_SEARCH_BASE + g_SearchCurPage;
		g_PingInfo.iAreaIndex = g_SearchServerInfo.iServerAreaIndex[SvrIndex];
		g_PingInfo.iServerIndex = g_SearchServerInfo.iServerIndex[SvrIndex];
	else

		if (g_ServerInfo.iServerPrizeLevel[index+1] > 0 and g_ThreePrizeTip[g_ServerInfo.iServerPrizeLevel[index+1]] ~= nil ) then
			SelectServer_Info:SetText(g_ThreePrizeTip[g_ServerInfo.iServerPrizeLevel[index+1]]);
		else
			local szWuShengTan = "";
			if g_ServerInfo.iServerWuShenTan[index+1] == 1 then
				szWuShengTan = "#{GJHC_260424_18}";
			end
			SelectServer_Info:SetText(g_ServerInfo.strServerName[index+1]..tostring("#{DLYHQF_12121333}")..szWuShengTan);	-- 服务器
		end
		
		g_PingInfo.iShowServer = CUR_SHOW_SERVER;
		g_PingInfo.iAreaIndex = g_ServerInfo.iServerAreaIndex[index+1];
		g_PingInfo.iServerIndex = g_ServerInfo.iServerIndex[index+1];
	end
end

--角色查询
function SelectServerEvent_RoleInquiry_MouseEnter()
	SelectServer_Info:SetText("#{DLYHQF_12121319}"); --查看账号下所有角色所在的服务器
end

--帐号充值
function SelectServerEvent_Payment_MouseEnter()
	SelectServer_Info:SetText("#{DLYHQF_12121334}");	--为您的账号充值
end

--帐号注册
function SelectServerEvent_AccountReg_MouseEnter()
	SelectServer_Info:SetText("#{DLYHQF_12121335}");	--申请一个新账号
end

--上一步
function SelectServerEvent_shangyibu_MouseEnter()
	SelectServer_Info:SetText("#{DLYHQF_12121336}");	--返回活动日程界面
end

--退出游戏
function SelectServerEvent_Cancel_MouseEnter()
	SelectServer_Info:SetText("#{DLYHQF_12121337}"); --退出天龙八部
end;

--上次登录
function SelectServerEvent_LastServer_MouseEnter()
	if(g_LastServerName~="") then
		if( g_LastServerPrizeLevel > 0 and g_ThreePrizeTip[g_LastServerPrizeLevel] ~= nil ) then
			SelectServer_Info:SetText(g_ThreePrizeTip[g_LastServerPrizeLevel]);
		else
			local szWuShengTan = "";
			if g_LastServerWuShenTan == 1 then
				szWuShengTan = "#{GJHC_260424_18}";
			end
			SelectServer_Info:SetText(g_LastServerName..tostring("#{DLYHQF_12121333}")..szWuShengTan);
		end
	else
		SelectServer_Info:SetText("");
	end
end

--上次登录
function SelectServerEvent_LastServer_MouseLeave()

	SelectServer_Info:SetText("");
end

function SelectServerEvent_MouseLeave(index)

	SelectServer_Info:SetText("");
end

--确认选择
function SelectServerEvent_Accept_MouseEnter()

	SelectServer_Info:SetText("#{DLYHQF_12121338}"); --点击进入所选择服务器登陆界面
end;

----------------------------------------------------------------------------------------------- 界面初始化 --
--界面左侧大区列表区域 --SelectServer_Frame2_Sub3下的内容
function SelectServer_UI_AreaList_Init()

	--ctrl是指控件，显示规则：MustShow > 0 or ServerCount > 0
	g_AreaUI.CurPage	= 0;		--当前显示大区
	g_AreaUI.DefaultPage = 1;	--默认显示大区	
				
end

function SelectServer_UI_Controls_Init()
	--得到流畅服务器列表
	g_FluencyServerBn.BnServer[1] = SelectServer_Commendable2_Subarea1;
	g_FluencyServerBn.BnServer[2] = SelectServer_Commendable2_Subarea2;
	g_FluencyServerBn.BnServer[3] = SelectServer_Commendable2_Subarea3;
	g_FluencyServerBn.BnServer[4] = SelectServer_Commendable2_Subarea4;
	g_FluencyServerBn.BnServer[5] = SelectServer_Commendable2_Subarea5;
	g_FluencyServerBn.BnServer[6] = SelectServer_Commendable2_Subarea6;
	g_FluencyServerBn.BnServer[7] = SelectServer_Commendable2_Subarea7;
	g_FluencyServerBn.BnServer[8] = SelectServer_Commendable2_Subarea8;
	g_FluencyServerBn.BnServer[9] = SelectServer_Commendable2_Subarea9;
	g_FluencyServerBn.BnServer[10] = SelectServer_Commendable2_Subarea10;
	g_FluencyServerBn.BnServer[11] = SelectServer_Commendable2_Subarea11;
	g_FluencyServerBn.BnServer[12] = SelectServer_Commendable2_Subarea12;
	g_FluencyServerBn.BnServerAnimate[1] = SelectServer_Commendable2_Subarea1_Animate;
	g_FluencyServerBn.BnServerAnimate[2] = SelectServer_Commendable2_Subarea2_Animate;
	g_FluencyServerBn.BnServerAnimate[3] = SelectServer_Commendable2_Subarea3_Animate;
	g_FluencyServerBn.BnServerAnimate[4] = SelectServer_Commendable2_Subarea4_Animate;
	g_FluencyServerBn.BnServerAnimate[5] = SelectServer_Commendable2_Subarea5_Animate;
	g_FluencyServerBn.BnServerAnimate[6] = SelectServer_Commendable2_Subarea6_Animate;
	g_FluencyServerBn.BnServerAnimate[7] = SelectServer_Commendable2_Subarea7_Animate;
	g_FluencyServerBn.BnServerAnimate[8] = SelectServer_Commendable2_Subarea8_Animate;
	g_FluencyServerBn.BnServerAnimate[9] = SelectServer_Commendable2_Subarea9_Animate;
	g_FluencyServerBn.BnServerAnimate[10] = SelectServer_Commendable2_Subarea10_Animate;
	g_FluencyServerBn.BnServerAnimate[11] = SelectServer_Commendable2_Subarea11_Animate;
	g_FluencyServerBn.BnServerAnimate[12] = SelectServer_Commendable2_Subarea12_Animate;
	g_FluencyServerBn.BnServer[1] = SelectServer_Commendable2_Subarea1;
	g_FluencyServerBn.BnServer[2] = SelectServer_Commendable2_Subarea2;
	g_FluencyServerBn.BnServer[3] = SelectServer_Commendable2_Subarea3;
	g_FluencyServerBn.BnServer[4] = SelectServer_Commendable2_Subarea4;
	g_FluencyServerBn.BnServer[5] = SelectServer_Commendable2_Subarea5;
	g_FluencyServerBn.BnServer[6] = SelectServer_Commendable2_Subarea6;
	g_FluencyServerBn.BnServer[7] = SelectServer_Commendable2_Subarea7;
	g_FluencyServerBn.BnServer[8] = SelectServer_Commendable2_Subarea8;
	g_FluencyServerBn.BnServer[9] = SelectServer_Commendable2_Subarea9;
	g_FluencyServerBn.BnServer[10] = SelectServer_Commendable2_Subarea10;
	g_FluencyServerBn.BnServer[11] = SelectServer_Commendable2_Subarea11;
	g_FluencyServerBn.BnServer[12] = SelectServer_Commendable2_Subarea12;
	
	--得到推荐服务器列表
	g_RecommendServerBn.BnServer[1] = SelectServer_Commendable_Subarea1;
	g_RecommendServerBn.BnServer[2] = SelectServer_Commendable_Subarea2;
	g_RecommendServerBn.BnServer[3] = SelectServer_Commendable_Subarea3;
	g_RecommendServerBn.BnServer[4] = SelectServer_Commendable_Subarea4;
	g_RecommendServerBn.BnServer[5] = SelectServer_Commendable_Subarea5;
	g_RecommendServerBn.BnServer[6] = SelectServer_Commendable_Subarea6;
	g_RecommendServerBn.BnServer[7] = SelectServer_Commendable_Subarea7;
	g_RecommendServerBn.BnServer[8] = SelectServer_Commendable_Subarea8;
	g_RecommendServerBn.BnServer[9] = SelectServer_Commendable_Subarea9;
	g_RecommendServerBn.BnServer[10] = SelectServer_Commendable_Subarea10;
	g_RecommendServerBn.BnServer[11] = SelectServer_Commendable_Subarea11;
	g_RecommendServerBn.BnServer[12] = SelectServer_Commendable_Subarea12;
	g_RecommendServerBn.BnServerAnimate[1] = SelectServer_Commendable_Subarea1_Animate;
	g_RecommendServerBn.BnServerAnimate[2] = SelectServer_Commendable_Subarea2_Animate;
	g_RecommendServerBn.BnServerAnimate[3] = SelectServer_Commendable_Subarea3_Animate;
	g_RecommendServerBn.BnServerAnimate[4] = SelectServer_Commendable_Subarea4_Animate;
	g_RecommendServerBn.BnServerAnimate[5] = SelectServer_Commendable_Subarea5_Animate;
	g_RecommendServerBn.BnServerAnimate[6] = SelectServer_Commendable_Subarea6_Animate;
	g_RecommendServerBn.BnServerAnimate[7] = SelectServer_Commendable_Subarea7_Animate;
	g_RecommendServerBn.BnServerAnimate[8] = SelectServer_Commendable_Subarea8_Animate;
	g_RecommendServerBn.BnServerAnimate[9] = SelectServer_Commendable_Subarea9_Animate;
	g_RecommendServerBn.BnServerAnimate[10] = SelectServer_Commendable_Subarea10_Animate;
	g_RecommendServerBn.BnServerAnimate[11] = SelectServer_Commendable_Subarea11_Animate;
	g_RecommendServerBn.BnServerAnimate[12] = SelectServer_Commendable_Subarea12_Animate;
	g_RecommendServerBn.BnWSTImage[1] = SelectServer_Commendable_Subarea1_Img;
	g_RecommendServerBn.BnWSTImage[2] = SelectServer_Commendable_Subarea2_Img;
	g_RecommendServerBn.BnWSTImage[3] = SelectServer_Commendable_Subarea3_Img;
	g_RecommendServerBn.BnWSTImage[4] = SelectServer_Commendable_Subarea4_Img;
	g_RecommendServerBn.BnWSTImage[5] = SelectServer_Commendable_Subarea5_Img;
	g_RecommendServerBn.BnWSTImage[6] = SelectServer_Commendable_Subarea6_Img;
	g_RecommendServerBn.BnWSTImage[7] = SelectServer_Commendable_Subarea7_Img;
	g_RecommendServerBn.BnWSTImage[8] = SelectServer_Commendable_Subarea8_Img;
	g_RecommendServerBn.BnWSTImage[9] = SelectServer_Commendable_Subarea9_Img;
	g_RecommendServerBn.BnWSTImage[10] = SelectServer_Commendable_Subarea10_Img;
	g_RecommendServerBn.BnWSTImage[11] = SelectServer_Commendable_Subarea11_Img;
	g_RecommendServerBn.BnWSTImage[12] = SelectServer_Commendable_Subarea12_Img;
	
	local i;
	for i = 1,g_RecommendServerBn.MAX_SERVER_COUNT do
	 	g_RecommendServerBn.BnServer[i]:SetProperty("CheckMode", "1");
	end
	
	-- 得到服务器按钮
	g_ServerBn.BnServer[1] = SelectServer_Server1;
	g_ServerBn.BnServer[2] = SelectServer_Server2;
	g_ServerBn.BnServer[3] = SelectServer_Server3;
	g_ServerBn.BnServer[4] = SelectServer_Server4;
	g_ServerBn.BnServer[5] = SelectServer_Server5;
	g_ServerBn.BnServer[6] = SelectServer_Server6;
	g_ServerBn.BnServer[7] = SelectServer_Server7;
	g_ServerBn.BnServer[8] = SelectServer_Server8;
	g_ServerBn.BnServer[9] = SelectServer_Server9;
	g_ServerBn.BnServer[10] = SelectServer_Server10;

	g_ServerBn.BnServer[11] = SelectServer_Server11;
	g_ServerBn.BnServer[12] = SelectServer_Server12;
	g_ServerBn.BnServer[13] = SelectServer_Server13;
	g_ServerBn.BnServer[14] = SelectServer_Server14;
	g_ServerBn.BnServer[15] = SelectServer_Server15;
	g_ServerBn.BnServer[16] = SelectServer_Server16;
	g_ServerBn.BnServer[17] = SelectServer_Server17;
	g_ServerBn.BnServer[18] = SelectServer_Server18;
	g_ServerBn.BnServer[19] = SelectServer_Server19;
	g_ServerBn.BnServer[20] = SelectServer_Server20;

	g_ServerBn.BnServer[21] = SelectServer_Server21;
	g_ServerBn.BnServer[22] = SelectServer_Server22;
	g_ServerBn.BnServer[23] = SelectServer_Server23;
	g_ServerBn.BnServer[24] = SelectServer_Server24;
	g_ServerBn.BnServer[25] = SelectServer_Server25;
	g_ServerBn.BnServer[26] = SelectServer_Server26;
	g_ServerBn.BnServer[27] = SelectServer_Server27;
	g_ServerBn.BnServer[28] = SelectServer_Server28;
	g_ServerBn.BnServer[29] = SelectServer_Server29;
	g_ServerBn.BnServer[30] = SelectServer_Server30;

	g_ServerBn.BnServer[31] = SelectServer_Server31;
	g_ServerBn.BnServer[32] = SelectServer_Server32;
	g_ServerBn.BnServer[33] = SelectServer_Server33;
	g_ServerBn.BnServer[34] = SelectServer_Server34;
	g_ServerBn.BnServer[35] = SelectServer_Server35;
	g_ServerBn.BnServer[36] = SelectServer_Server36;
	g_ServerBn.BnServer[37] = SelectServer_Server37;
	g_ServerBn.BnServer[38] = SelectServer_Server38;
	g_ServerBn.BnServer[39] = SelectServer_Server39;
	g_ServerBn.BnServer[40] = SelectServer_Server40;

	g_ServerBn.BnServer[41] = SelectServer_Server41;
	g_ServerBn.BnServer[42] = SelectServer_Server42;
	g_ServerBn.BnServer[43] = SelectServer_Server43;
	g_ServerBn.BnServer[44] = SelectServer_Server44;
	g_ServerBn.BnServer[45] = SelectServer_Server45;
	g_ServerBn.BnServer[46] = SelectServer_Server46;
	g_ServerBn.BnServer[47] = SelectServer_Server47;
	g_ServerBn.BnServer[48] = SelectServer_Server48;
	g_ServerBn.BnServer[49] = SelectServer_Server49;
	g_ServerBn.BnServer[50] = SelectServer_Server50;

	g_ServerBn.BnServer[51] = SelectServer_Server51;
	g_ServerBn.BnServer[52] = SelectServer_Server52;
	g_ServerBn.BnServer[53] = SelectServer_Server53;
	g_ServerBn.BnServer[54] = SelectServer_Server54;
	g_ServerBn.BnServer[55] = SelectServer_Server55;
	g_ServerBn.BnServer[56] = SelectServer_Server56;
	g_ServerBn.BnServer[57] = SelectServer_Server57;
	g_ServerBn.BnServer[58] = SelectServer_Server58;
	g_ServerBn.BnServer[59] = SelectServer_Server59;
	g_ServerBn.BnServer[60] = SelectServer_Server60;

	g_ServerBn.BnServer[61] = SelectServer_Server61;
	g_ServerBn.BnServer[62] = SelectServer_Server62;
	g_ServerBn.BnServer[63] = SelectServer_Server63;
	g_ServerBn.BnServer[64] = SelectServer_Server64;
	g_ServerBn.BnServer[65] = SelectServer_Server65;
	g_ServerBn.BnServer[66] = SelectServer_Server66;
	g_ServerBn.BnServer[67] = SelectServer_Server67;
	g_ServerBn.BnServer[68] = SelectServer_Server68;
	g_ServerBn.BnServer[69] = SelectServer_Server69;
	g_ServerBn.BnServer[70] = SelectServer_Server70;

	g_ServerBn.BnServer[71] = SelectServer_Server71;
	g_ServerBn.BnServer[72] = SelectServer_Server72;
	g_ServerBn.BnServer[73] = SelectServer_Server73;
	g_ServerBn.BnServer[74] = SelectServer_Server74;
	g_ServerBn.BnServer[75] = SelectServer_Server75;
	g_ServerBn.BnServer[76] = SelectServer_Server76;
	g_ServerBn.BnServer[77] = SelectServer_Server77;
	g_ServerBn.BnServer[78] = SelectServer_Server78;
	g_ServerBn.BnServer[79] = SelectServer_Server79;
	g_ServerBn.BnServer[80] = SelectServer_Server80;

	g_ServerBn.BnServer[81] = SelectServer_Server81;
	g_ServerBn.BnServer[82] = SelectServer_Server82;
	g_ServerBn.BnServer[83] = SelectServer_Server83;
	g_ServerBn.BnServer[84] = SelectServer_Server84;
	g_ServerBn.BnServer[85] = SelectServer_Server85;
	
	-- 得到特效服务器按钮
	g_ServerBn.BnServerAnimate[1] = SelectServer_Server1_Animate;
	g_ServerBn.BnServerAnimate[2] = SelectServer_Server2_Animate;
	g_ServerBn.BnServerAnimate[3] = SelectServer_Server3_Animate;
	g_ServerBn.BnServerAnimate[4] = SelectServer_Server4_Animate;
	g_ServerBn.BnServerAnimate[5] = SelectServer_Server5_Animate;
	g_ServerBn.BnServerAnimate[6] = SelectServer_Server6_Animate;
	g_ServerBn.BnServerAnimate[7] = SelectServer_Server7_Animate;
	g_ServerBn.BnServerAnimate[8] = SelectServer_Server8_Animate;
	g_ServerBn.BnServerAnimate[9] = SelectServer_Server9_Animate;
	g_ServerBn.BnServerAnimate[10] = SelectServer_Server10_Animate;
	g_ServerBn.BnServerAnimate[11] = SelectServer_Server11_Animate;
	g_ServerBn.BnServerAnimate[12] = SelectServer_Server12_Animate;
	g_ServerBn.BnServerAnimate[13] = SelectServer_Server13_Animate;
	g_ServerBn.BnServerAnimate[14] = SelectServer_Server14_Animate;
	g_ServerBn.BnServerAnimate[15] = SelectServer_Server15_Animate;
	g_ServerBn.BnServerAnimate[16] = SelectServer_Server16_Animate;
	g_ServerBn.BnServerAnimate[17] = SelectServer_Server17_Animate;
	g_ServerBn.BnServerAnimate[18] = SelectServer_Server18_Animate;
	g_ServerBn.BnServerAnimate[19] = SelectServer_Server19_Animate;
	g_ServerBn.BnServerAnimate[20] = SelectServer_Server20_Animate;

	g_ServerBn.BnServerAnimate[21] = SelectServer_Server21_Animate;
	g_ServerBn.BnServerAnimate[22] = SelectServer_Server22_Animate;
	g_ServerBn.BnServerAnimate[23] = SelectServer_Server23_Animate;
	g_ServerBn.BnServerAnimate[24] = SelectServer_Server24_Animate;
	g_ServerBn.BnServerAnimate[25] = SelectServer_Server25_Animate;
	g_ServerBn.BnServerAnimate[26] = SelectServer_Server26_Animate;
	g_ServerBn.BnServerAnimate[27] = SelectServer_Server27_Animate;
	g_ServerBn.BnServerAnimate[28] = SelectServer_Server28_Animate;
	g_ServerBn.BnServerAnimate[29] = SelectServer_Server29_Animate;
	g_ServerBn.BnServerAnimate[30] = SelectServer_Server30_Animate;

	g_ServerBn.BnServerAnimate[31] = SelectServer_Server31_Animate;
	g_ServerBn.BnServerAnimate[32] = SelectServer_Server32_Animate;
	g_ServerBn.BnServerAnimate[33] = SelectServer_Server33_Animate;
	g_ServerBn.BnServerAnimate[34] = SelectServer_Server34_Animate;
	g_ServerBn.BnServerAnimate[35] = SelectServer_Server35_Animate;
	g_ServerBn.BnServerAnimate[36] = SelectServer_Server36_Animate;
	g_ServerBn.BnServerAnimate[37] = SelectServer_Server37_Animate;
	g_ServerBn.BnServerAnimate[38] = SelectServer_Server38_Animate;
	g_ServerBn.BnServerAnimate[39] = SelectServer_Server39_Animate;
	g_ServerBn.BnServerAnimate[40] = SelectServer_Server40_Animate;

	g_ServerBn.BnServerAnimate[41] = SelectServer_Server41_Animate;
	g_ServerBn.BnServerAnimate[42] = SelectServer_Server42_Animate;
	g_ServerBn.BnServerAnimate[43] = SelectServer_Server43_Animate;
	g_ServerBn.BnServerAnimate[44] = SelectServer_Server44_Animate;
	g_ServerBn.BnServerAnimate[45] = SelectServer_Server45_Animate;
	g_ServerBn.BnServerAnimate[46] = SelectServer_Server46_Animate;
	g_ServerBn.BnServerAnimate[47] = SelectServer_Server47_Animate;
	g_ServerBn.BnServerAnimate[48] = SelectServer_Server48_Animate;
	g_ServerBn.BnServerAnimate[49] = SelectServer_Server49_Animate;
	g_ServerBn.BnServerAnimate[50] = SelectServer_Server50_Animate;

	g_ServerBn.BnServerAnimate[51] = SelectServer_Server51_Animate;
	g_ServerBn.BnServerAnimate[52] = SelectServer_Server52_Animate;
	g_ServerBn.BnServerAnimate[53] = SelectServer_Server53_Animate;
	g_ServerBn.BnServerAnimate[54] = SelectServer_Server54_Animate;
	g_ServerBn.BnServerAnimate[55] = SelectServer_Server55_Animate;
	g_ServerBn.BnServerAnimate[56] = SelectServer_Server56_Animate;
	g_ServerBn.BnServerAnimate[57] = SelectServer_Server57_Animate;
	g_ServerBn.BnServerAnimate[58] = SelectServer_Server58_Animate;
	g_ServerBn.BnServerAnimate[59] = SelectServer_Server59_Animate;
	g_ServerBn.BnServerAnimate[60] = SelectServer_Server60_Animate;

	g_ServerBn.BnServerAnimate[61] = SelectServer_Server61_Animate;
	g_ServerBn.BnServerAnimate[62] = SelectServer_Server62_Animate;
	g_ServerBn.BnServerAnimate[63] = SelectServer_Server63_Animate;
	g_ServerBn.BnServerAnimate[64] = SelectServer_Server64_Animate;
	g_ServerBn.BnServerAnimate[65] = SelectServer_Server65_Animate;
	g_ServerBn.BnServerAnimate[66] = SelectServer_Server66_Animate;
	g_ServerBn.BnServerAnimate[67] = SelectServer_Server67_Animate;
	g_ServerBn.BnServerAnimate[68] = SelectServer_Server68_Animate;
	g_ServerBn.BnServerAnimate[69] = SelectServer_Server69_Animate;
	g_ServerBn.BnServerAnimate[70] = SelectServer_Server70_Animate;

	g_ServerBn.BnServerAnimate[71] = SelectServer_Server71_Animate;
	g_ServerBn.BnServerAnimate[72] = SelectServer_Server72_Animate;
	g_ServerBn.BnServerAnimate[73] = SelectServer_Server73_Animate;
	g_ServerBn.BnServerAnimate[74] = SelectServer_Server74_Animate;
	g_ServerBn.BnServerAnimate[75] = SelectServer_Server75_Animate;
	g_ServerBn.BnServerAnimate[76] = SelectServer_Server76_Animate;
	g_ServerBn.BnServerAnimate[77] = SelectServer_Server77_Animate;
	g_ServerBn.BnServerAnimate[78] = SelectServer_Server78_Animate;
	g_ServerBn.BnServerAnimate[79] = SelectServer_Server79_Animate;
	g_ServerBn.BnServerAnimate[80] = SelectServer_Server80_Animate;

	g_ServerBn.BnServerAnimate[81] = SelectServer_Server81_Animate;
	g_ServerBn.BnServerAnimate[82] = SelectServer_Server82_Animate;
	g_ServerBn.BnServerAnimate[83] = SelectServer_Server83_Animate;
	g_ServerBn.BnServerAnimate[84] = SelectServer_Server84_Animate;
	g_ServerBn.BnServerAnimate[85] = SelectServer_Server85_Animate;
	
	g_ServerBn.BnWSTImage[1] = SelectServer_Server1_Img;
	g_ServerBn.BnWSTImage[2] = SelectServer_Server2_Img;
	g_ServerBn.BnWSTImage[3] = SelectServer_Server3_Img;
	g_ServerBn.BnWSTImage[4] = SelectServer_Server4_Img;
	g_ServerBn.BnWSTImage[5] = SelectServer_Server5_Img;
	g_ServerBn.BnWSTImage[6] = SelectServer_Server6_Img;
	g_ServerBn.BnWSTImage[7] = SelectServer_Server7_Img;
	g_ServerBn.BnWSTImage[8] = SelectServer_Server8_Img;
	g_ServerBn.BnWSTImage[9] = SelectServer_Server9_Img;
	g_ServerBn.BnWSTImage[10] = SelectServer_Server10_Img;

	g_ServerBn.BnWSTImage[11] = SelectServer_Server11_Img;
	g_ServerBn.BnWSTImage[12] = SelectServer_Server12_Img;
	g_ServerBn.BnWSTImage[13] = SelectServer_Server13_Img;
	g_ServerBn.BnWSTImage[14] = SelectServer_Server14_Img;
	g_ServerBn.BnWSTImage[15] = SelectServer_Server15_Img;
	g_ServerBn.BnWSTImage[16] = SelectServer_Server16_Img;
	g_ServerBn.BnWSTImage[17] = SelectServer_Server17_Img;
	g_ServerBn.BnWSTImage[18] = SelectServer_Server18_Img;
	g_ServerBn.BnWSTImage[19] = SelectServer_Server19_Img;
	g_ServerBn.BnWSTImage[20] = SelectServer_Server20_Img;
	
	g_ServerBn.BnWSTImage[21] = SelectServer_Server21_Img;
	g_ServerBn.BnWSTImage[22] = SelectServer_Server22_Img;
	g_ServerBn.BnWSTImage[23] = SelectServer_Server23_Img;
	g_ServerBn.BnWSTImage[24] = SelectServer_Server24_Img;
	g_ServerBn.BnWSTImage[25] = SelectServer_Server25_Img;
	g_ServerBn.BnWSTImage[26] = SelectServer_Server26_Img;
	g_ServerBn.BnWSTImage[27] = SelectServer_Server27_Img;
	g_ServerBn.BnWSTImage[28] = SelectServer_Server28_Img;
	g_ServerBn.BnWSTImage[29] = SelectServer_Server29_Img;
	g_ServerBn.BnWSTImage[30] = SelectServer_Server30_Img;
	
	g_ServerBn.BnWSTImage[31] = SelectServer_Server31_Img;
	g_ServerBn.BnWSTImage[32] = SelectServer_Server32_Img;
	g_ServerBn.BnWSTImage[33] = SelectServer_Server33_Img;
	g_ServerBn.BnWSTImage[34] = SelectServer_Server34_Img;
	g_ServerBn.BnWSTImage[35] = SelectServer_Server35_Img;
	g_ServerBn.BnWSTImage[36] = SelectServer_Server36_Img;
	g_ServerBn.BnWSTImage[37] = SelectServer_Server37_Img;
	g_ServerBn.BnWSTImage[38] = SelectServer_Server38_Img;
	g_ServerBn.BnWSTImage[39] = SelectServer_Server39_Img;
	g_ServerBn.BnWSTImage[40] = SelectServer_Server40_Img;
	
	g_ServerBn.BnWSTImage[41] = SelectServer_Server41_Img;
	g_ServerBn.BnWSTImage[42] = SelectServer_Server42_Img;
	g_ServerBn.BnWSTImage[43] = SelectServer_Server43_Img;
	g_ServerBn.BnWSTImage[44] = SelectServer_Server44_Img;
	g_ServerBn.BnWSTImage[45] = SelectServer_Server45_Img;
	g_ServerBn.BnWSTImage[46] = SelectServer_Server46_Img;
	g_ServerBn.BnWSTImage[47] = SelectServer_Server47_Img;
	g_ServerBn.BnWSTImage[48] = SelectServer_Server48_Img;
	g_ServerBn.BnWSTImage[49] = SelectServer_Server49_Img;
	g_ServerBn.BnWSTImage[50] = SelectServer_Server50_Img;
	
	g_ServerBn.BnWSTImage[51] = SelectServer_Server51_Img;
	g_ServerBn.BnWSTImage[52] = SelectServer_Server52_Img;
	g_ServerBn.BnWSTImage[53] = SelectServer_Server53_Img;
	g_ServerBn.BnWSTImage[54] = SelectServer_Server54_Img;
	g_ServerBn.BnWSTImage[55] = SelectServer_Server55_Img;
	g_ServerBn.BnWSTImage[56] = SelectServer_Server56_Img;
	g_ServerBn.BnWSTImage[57] = SelectServer_Server57_Img;
	g_ServerBn.BnWSTImage[58] = SelectServer_Server58_Img;
	g_ServerBn.BnWSTImage[59] = SelectServer_Server59_Img;
	g_ServerBn.BnWSTImage[60] = SelectServer_Server60_Img;
	
	g_ServerBn.BnWSTImage[61] = SelectServer_Server61_Img;
	g_ServerBn.BnWSTImage[62] = SelectServer_Server62_Img;
	g_ServerBn.BnWSTImage[63] = SelectServer_Server63_Img;
	g_ServerBn.BnWSTImage[64] = SelectServer_Server64_Img;
	g_ServerBn.BnWSTImage[65] = SelectServer_Server65_Img;
	g_ServerBn.BnWSTImage[66] = SelectServer_Server66_Img;
	g_ServerBn.BnWSTImage[67] = SelectServer_Server67_Img;
	g_ServerBn.BnWSTImage[68] = SelectServer_Server68_Img;
	g_ServerBn.BnWSTImage[69] = SelectServer_Server69_Img;
	g_ServerBn.BnWSTImage[70] = SelectServer_Server70_Img;
	
	g_ServerBn.BnWSTImage[71] = SelectServer_Server71_Img;
	g_ServerBn.BnWSTImage[72] = SelectServer_Server72_Img;
	g_ServerBn.BnWSTImage[73] = SelectServer_Server73_Img;
	g_ServerBn.BnWSTImage[74] = SelectServer_Server74_Img;
	g_ServerBn.BnWSTImage[75] = SelectServer_Server75_Img;
	g_ServerBn.BnWSTImage[76] = SelectServer_Server76_Img;
	g_ServerBn.BnWSTImage[77] = SelectServer_Server77_Img;
	g_ServerBn.BnWSTImage[78] = SelectServer_Server78_Img;
	g_ServerBn.BnWSTImage[79] = SelectServer_Server79_Img;
	g_ServerBn.BnWSTImage[80] = SelectServer_Server80_Img;
	
	g_ServerBn.BnWSTImage[81] = SelectServer_Server81_Img;
	g_ServerBn.BnWSTImage[82] = SelectServer_Server82_Img;
	g_ServerBn.BnWSTImage[83] = SelectServer_Server83_Img;
	g_ServerBn.BnWSTImage[84] = SelectServer_Server84_Img;
	g_ServerBn.BnWSTImage[85] = SelectServer_Server85_Img;
	
	for i = 1, g_ServerBn.MAX_SERVER_COUNT do
	 	g_ServerBn.BnServer[i]:SetProperty("CheckMode", "1");
	end
	
	local strNormalColor = "#cFFF263";
	SelectServer_Help_Text1:SetText(	strNormalColor.."#{DLYHQF_12121339}" ); --#e010101#cff0000红色表示:爆满#cffffff
	SelectServer_Help_Text2:SetText(	strNormalColor.."#{DLYHQF_12121340}" ); --#e010101#cECE58D浅色表示:良好#cffffff
	SelectServer_Help_Text3:SetText(	strNormalColor.."#{DLYHQF_12121341}" ); --#e010101#c959595灰色表示:维护#cffffff
	SelectServer_Help_Text4:SetText(	strNormalColor.."#{DLYHQF_12121342}" ); --#e010101#cff8a00橙色表示:繁忙#cffffff
	SelectServer_Help_Text5:SetText(	strNormalColor.."#{DLYHQF_12121343}" ); --#e010101#c4CFA4C绿色表示:极佳#cffffff

	SelectServer_Server_Last_Animate:SetProperty("Animate", "");
	SelectServer_Server_Last_Animate:SetProperty("Visible", "False");

	SelectServer_LineSelect:AddTextItem("#{DLJM_XML_46}" ,1)	--电信      0
	SelectServer_LineSelect:AddTextItem("#{DLJM_XML_48}" ,2)	--网通1		1
	--SelectServer_LineSelect:AddTextItem("#{DDFWQ_XML_01}" ,3)	--网通2		4	青岛网通代理已经移除
	SelectServer_LineSelect:AddTextItem("#{DLJM_XML_50}" ,3)	--教育网	2
	SelectServer_LineSelect:AddTextItem("#{DLYHQF_12121344}" ,4)				--默认		3
	SelectServer_LineSelect:SetCurrentSelect(3)
		
	SelectServer_shangyibu:Hide();

end

----------------------------------------------------------------------------------------------- 排序函数 --
--排序列，从小到大，对推荐服务器排序
function SelectServer_Sort_RecommendServer()

	local TotalCount = g_RecommendServerInfo.iRecommendServerCount;
	local tmp ;
	local p=0;
	for j = 1 , TotalCount -1 do
		for i=1, TotalCount-j do
			if(g_RecommendServerInfo.iRecommendLevel[i]>g_RecommendServerInfo.iRecommendLevel[i+1]) then
				tmp = g_RecommendServerInfo.iRecommendLevel[i];
				g_RecommendServerInfo.iRecommendLevel[i] = g_RecommendServerInfo.iRecommendLevel[i+1];
				g_RecommendServerInfo.iRecommendLevel[i+1] = tmp;

				tmp = g_RecommendServerInfo.strRecommendServerName[i];
				g_RecommendServerInfo.strRecommendServerName[i] = g_RecommendServerInfo.strRecommendServerName[i+1];
				g_RecommendServerInfo.strRecommendServerName[i+1] = tmp;

				tmp = g_RecommendServerInfo.iRecommendServerIndex[i];
				g_RecommendServerInfo.iRecommendServerIndex[i] = g_RecommendServerInfo.iRecommendServerIndex[i+1];
				g_RecommendServerInfo.iRecommendServerIndex[i+1] = tmp;

				tmp = g_RecommendServerInfo.iRecommendServerAreaIndex[i];
				g_RecommendServerInfo.iRecommendServerAreaIndex[i] = g_RecommendServerInfo.iRecommendServerAreaIndex[i+1];
				g_RecommendServerInfo.iRecommendServerAreaIndex[i+1] = tmp;

				tmp = g_RecommendServerInfo.iRecommendServerIsNew[i];
				g_RecommendServerInfo.iRecommendServerIsNew[i] = g_RecommendServerInfo.iRecommendServerIsNew[i+1];
				g_RecommendServerInfo.iRecommendServerIsNew[i+1] = tmp;

				tmp = g_RecommendServerInfo.iRecommendServerStatus[i];
				g_RecommendServerInfo.iRecommendServerStatus[i] = g_RecommendServerInfo.iRecommendServerStatus[i+1];
				g_RecommendServerInfo.iRecommendServerStatus[i+1] = tmp;

				tmp = g_RecommendServerInfo.iRecommendServerPrizeLevel[i];--------lichengjie --added
				g_RecommendServerInfo.iRecommendServerPrizeLevel[i] = g_RecommendServerInfo.iRecommendServerPrizeLevel[i+1];
				g_RecommendServerInfo.iRecommendServerPrizeLevel[i+1] = tmp;
				
				tmp = g_RecommendServerInfo.iRecommendServerVersion[i];
				g_RecommendServerInfo.iRecommendServerVersion[i] = g_RecommendServerInfo.iRecommendServerVersion[i+1];
				g_RecommendServerInfo.iRecommendServerVersion[i+1] = tmp;
			end
		end;
	end;
end;
--排序列2，对流畅服务器排序
function SelectServer_Sort_FluencyServer()

	local TotalCount = g_FluencyServerInfo.iServerCount;
	local tmp ;
	for j = 1 , TotalCount -1 do
		for i=1, TotalCount-j do
			if(g_FluencyServerInfo.iServerIsNew[i]<g_FluencyServerInfo.iServerIsNew[i+1]) then
				tmp = g_FluencyServerInfo.iLevel[i];
				g_FluencyServerInfo.iLevel[i] = g_FluencyServerInfo.iLevel[i+1];
				g_FluencyServerInfo.iLevel[i+1] = tmp;

				tmp = g_FluencyServerInfo.strServerName[i];
				g_FluencyServerInfo.strServerName[i] = g_FluencyServerInfo.strServerName[i+1];
				g_FluencyServerInfo.strServerName[i+1] = tmp;

				tmp = g_FluencyServerInfo.iServerIndex[i];
				g_FluencyServerInfo.iServerIndex[i] = g_FluencyServerInfo.iServerIndex[i+1];
				g_FluencyServerInfo.iServerIndex[i+1] = tmp;

				tmp = g_FluencyServerInfo.iServerAreaIndex[i];
				g_FluencyServerInfo.iServerAreaIndex[i] = g_FluencyServerInfo.iServerAreaIndex[i+1];
				g_FluencyServerInfo.iServerAreaIndex[i+1] = tmp;

				tmp = g_FluencyServerInfo.iServerIsNew[i];
				g_FluencyServerInfo.iServerIsNew[i] = g_FluencyServerInfo.iServerIsNew[i+1];
				g_FluencyServerInfo.iServerIsNew[i+1] = tmp;

				tmp = g_FluencyServerInfo.iServerStatus[i];
				g_FluencyServerInfo.iServerStatus[i] = g_FluencyServerInfo.iServerStatus[i+1];
				g_FluencyServerInfo.iServerStatus[i+1] = tmp;

				tmp = g_FluencyServerInfo.iServerPrizeLevel[i];--------lichengjie --added
				g_FluencyServerInfo.iServerPrizeLevel[i] = g_FluencyServerInfo.iServerPrizeLevel[i+1];
				g_FluencyServerInfo.iServerPrizeLevel[i+1] = tmp;
				
				tmp = g_FluencyServerInfo.iServerVersion[i];--------lichengjie --added
				g_FluencyServerInfo.iServerVersion[i] = g_FluencyServerInfo.iServerVersion[i+1];
				g_FluencyServerInfo.iServerVersion[i+1] = tmp;
			end
		end;
	end;
	--对新服顺序做随机
	local tempOrderPool = {}
	
	--对老服做随机 add by cxy
	local tempOrderPool_Old = {}
	local count = 1;
	local newCnt = 0;
	for k=1, TotalCount do
		if g_FluencyServerInfo.iServerIsNew[k] <= 0 then
			tempOrderPool_Old[count] = k
			count = count + 1
		elseif g_FluencyServerInfo.iServerIsNew[k] > 0 then
			tempOrderPool[k] = k
			newCnt = newCnt + 1;
		else
			break;
		end
	end
	for l = 1, table.getn(tempOrderPool) do
		local idx = math.random(1, table.getn(tempOrderPool))
		local val = tempOrderPool[idx]
		--交换val与l值
		tmp = g_FluencyServerInfo.iLevel[val];
		g_FluencyServerInfo.iLevel[val] = g_FluencyServerInfo.iLevel[l];
		g_FluencyServerInfo.iLevel[l] = tmp;

		tmp = g_FluencyServerInfo.strServerName[val];
		g_FluencyServerInfo.strServerName[val] = g_FluencyServerInfo.strServerName[l];
		g_FluencyServerInfo.strServerName[l] = tmp;

		tmp = g_FluencyServerInfo.iServerIndex[val];
		g_FluencyServerInfo.iServerIndex[val] = g_FluencyServerInfo.iServerIndex[l];
		g_FluencyServerInfo.iServerIndex[l] = tmp;

		tmp = g_FluencyServerInfo.iServerAreaIndex[val];
		g_FluencyServerInfo.iServerAreaIndex[val] = g_FluencyServerInfo.iServerAreaIndex[l];
		g_FluencyServerInfo.iServerAreaIndex[l] = tmp;

		tmp = g_FluencyServerInfo.iServerIsNew[val];
		g_FluencyServerInfo.iServerIsNew[val] = g_FluencyServerInfo.iServerIsNew[l];
		g_FluencyServerInfo.iServerIsNew[l] = tmp;

		tmp = g_FluencyServerInfo.iServerStatus[val];
		g_FluencyServerInfo.iServerStatus[val] = g_FluencyServerInfo.iServerStatus[l];
		g_FluencyServerInfo.iServerStatus[l] = tmp;

		tmp = g_FluencyServerInfo.iServerPrizeLevel[val];--------lichengjie --added
		g_FluencyServerInfo.iServerPrizeLevel[val] = g_FluencyServerInfo.iServerPrizeLevel[l];
		g_FluencyServerInfo.iServerPrizeLevel[l] = tmp;
		
		tmp = g_FluencyServerInfo.iServerVersion[val];
		g_FluencyServerInfo.iServerVersion[val] = g_FluencyServerInfo.iServerVersion[l];
		g_FluencyServerInfo.iServerVersion[l] = tmp;
		
		table.remove(tempOrderPool, idx)
	end

	-- 对老服随机
	local begin = newCnt + 1
	local len = newCnt + table.getn(tempOrderPool_Old)
	for l = begin, len do
		local idx = math.random(1, table.getn(tempOrderPool_Old))
		local val = tempOrderPool_Old[idx]
		--交换val与l值
		tmp = g_FluencyServerInfo.iLevel[val];
		g_FluencyServerInfo.iLevel[val] = g_FluencyServerInfo.iLevel[l];
		g_FluencyServerInfo.iLevel[l] = tmp;

		tmp = g_FluencyServerInfo.strServerName[val];
		g_FluencyServerInfo.strServerName[val] = g_FluencyServerInfo.strServerName[l];
		g_FluencyServerInfo.strServerName[l] = tmp;

		tmp = g_FluencyServerInfo.iServerIndex[val];
		g_FluencyServerInfo.iServerIndex[val] = g_FluencyServerInfo.iServerIndex[l];
		g_FluencyServerInfo.iServerIndex[l] = tmp;

		tmp = g_FluencyServerInfo.iServerAreaIndex[val];
		g_FluencyServerInfo.iServerAreaIndex[val] = g_FluencyServerInfo.iServerAreaIndex[l];
		g_FluencyServerInfo.iServerAreaIndex[l] = tmp;

		tmp = g_FluencyServerInfo.iServerIsNew[val];
		g_FluencyServerInfo.iServerIsNew[val] = g_FluencyServerInfo.iServerIsNew[l];
		g_FluencyServerInfo.iServerIsNew[l] = tmp;

		tmp = g_FluencyServerInfo.iServerStatus[val];
		g_FluencyServerInfo.iServerStatus[val] = g_FluencyServerInfo.iServerStatus[l];
		g_FluencyServerInfo.iServerStatus[l] = tmp;

		tmp = g_FluencyServerInfo.iServerPrizeLevel[val];--------lichengjie --added
		g_FluencyServerInfo.iServerPrizeLevel[val] = g_FluencyServerInfo.iServerPrizeLevel[l];
		g_FluencyServerInfo.iServerPrizeLevel[l] = tmp;
		
		tmp = g_FluencyServerInfo.iServerVersion[val];
		g_FluencyServerInfo.iServerVersion[val] = g_FluencyServerInfo.iServerVersion[l];
		g_FluencyServerInfo.iServerVersion[l] = tmp;
		
		table.remove(tempOrderPool_Old, idx)
	end
end;

-- 打开CG界面
function SelectServerEvent_OpenCGWindow()
	PushEvent("CG_WINDOW_SHOW")
end

---------------------------------------------------------------------------------------------- 废弃函数 --
function SelectServerEvent_ReturnAreaSelect_MouseEnter()
	--SelectServer_Info:SetText("返回大区选择界面");
end

function SelectServerEvent_CurSelectArea_MouseEnter()
	--if(g_iCurSelAreaName~="") then
	--	SelectServer_Info:SetText(g_iCurSelAreaName);
	--else
	--	SelectServer_Info:SetText("");
	--end
end

function SelectServerEvent_CurSelectArea()
end
