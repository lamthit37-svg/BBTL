local g_KeepHeight = 105; --屏幕上方不可覆盖的区域所占的高度
local g_MinHeight = 112; --上面屏的最小值
local g_MaxHeight = 336; --上面屏的最大值
local g_Spin = 4
local g_FenpingMinHeight = 108; --下面屏高度最小值
local g_FenpingMaxHeight = 192; --下面屏高度最大值

local g_MinWidth	=	320;	--聊天区域宽度的最小值
local g_MaxWidth	=	608;	--聊天区域宽度的最大值

local g_MaxFrameHeight = 423   --整个窗口的最大高度
local g_MinFrameHeight = 255   -- or 255 depend on buttonframe

local g_SpeakerHeight = 85
local g_CheckBoxHeight = 20
local g_ToggleButtonHeight = 19
local g_EditBarHeight = 19

local g_MoveUpHeight = 70; --屏幕分辨率变化时的上升高度
local g_CurSpeakerName = "";
local g_CurSpeakerZoneworldid = -1
local g_CurSpeakerDisplayName = "" --玩家名@服务器
local channel_config = {};
local CHANNEL_DATA = {};

local channel_seltab = 0;		--默认选择“全部”
local channel_tab = {};
local CHANNEL_TAB_MAX = 8;	--最大有五个页面Tab
local g_channel_fenping = 8; --分屏ID
local channel_tab_total = 6;	--默认有两个页面Tab, 0 & 1

local channel_sendhis = 0;	--0 不是从发送历史里获取的字串
														--1 是从发送历史里获取的字串
local channel_sendhis2 = 0;

local g_CurFlashTab = -1;

local channel_flash = {};

local g_CurSecretFlag = -1;

local g_TBlevel = 0;

local g_CurSecretType = -1;

local g_ChatFramePrivate = "";
--设置
local CHANNEL_DATA_NEAR =
	{
		"set:Buttons image:Channelvicinity_Normal", 		-- 频道选择按钮普通
		"set:Buttons image:ChannelVicinity_Hover", 		-- 频道选择按钮激活
		"set:Buttons image:ChannelVicinity_Pushed",		-- 频道选择按钮按下
		"#cFFFFFF",									-- 聊天内容颜色
		"#e010101#cFFFFFF",						-- 名称【附近】
--		"#91#e010101#cFFFFFF",
	};

local CHANNEL_DATA_SCENE =
	{
		"set:Buttons image:ChannelWorld_Normal",
		"set:Buttons image:ChannelWorld_Hover",
		"set:Buttons image:ChannelWorld_Pushed",
		"#cFFFFFF",
		"#e010101#c00FFCC",					--【世界】
--		"#92#e010101#c00FF00",
	};

local CHANNEL_DATA_PRIVATE =
	{
		"set:Buttons image:ChannelPersonal_Normal",
		"set:Buttons image:ChannelPersonal_Hover",
		"set:Buttons image:ChannelPersonal_Pushed",
		"#cFFFFFF",
		"#e010101#cFF7C80",					--【私聊】
--		"#98#e010101#c99CC00",
	};

local CHANNEL_DATA_SYSTEM =
	{
		"set:Buttons image:ChannelPersonal_Normal",
		"set:Buttons image:ChannelPersonal_Hover",
		"set:Buttons image:ChannelPersonal_Pushed",
		"#cFF0000",
		"#e010101#cFF0000",					--【系统】
--		"#96#e010101#cFFFF00",
	};

local CHANNEL_DATA_TEAM =
	{
		"set:Buttons image:ChannelTeam_Normal",
		"set:Buttons image:ChannelTeam_Hover",
		"set:Buttons image:ChannelTeam_Pushed",
		"#cFFFFFF",
		"#e010101#cCC99FF",					--【队伍】
--	"#93#e010101#cFFFF00",
	};

local CHANNEL_DATA_SELF =
	{
		"set:Buttons image:ChannelTeam_Normal",
		"set:Buttons image:ChannelTeam_Hover",
		"set:Buttons image:ChannelTeam_Pushed",
		"#e010101#cFFFFFF",
--		"#e010101#cFFFF00",				--【自用】
		"nouse",
	};

local CHANNEL_DATA_HELP =
	{
		"set:Buttons image:ChannelTeam_Normal",
		"set:Buttons image:ChannelTeam_Hover",
		"set:Buttons image:ChannelTeam_Pushed",
		"#e010101#cFFFFFF",
--		"#e010101#cFFFF00",				--【帮助】
		"nouse",
	};

local CHANNEL_DATA_MENPAI =
	{
		"set:Buttons image:ChannelMenpai_Normal",
		"set:Buttons image:ChannelMenpai_Hover",
		"set:Buttons image:ChannelMenpai_Pushed",
		"#cFFFFFF",
		"#e010101#cFFFF00",					--【门派】
--		"#94#e010101#cFFFF00",
	};

local CHANNEL_DATA_GUILD =
	{
		"set:Buttons image:ChannelCorporative_Normal",
		"set:Buttons image:ChannelCorporative_Hover",
		"set:Buttons image:ChannelCorporative_Pushed",
		"#cFFFFFF",
		"#e010101#cFFCC99",					--【帮会】
--		"#95#e010101#cFFFF00",
	};

local CHANNEL_DATA_GUILD_LEAGUE =
	{
		"set:CommonFrame6 image:ChannelTongMeng_Normal",
		"set:CommonFrame6 image:ChannelTongMeng_Hover",
		"set:CommonFrame6 image:ChannelTongMeng_Pushed",
		"#cFFFFFF",
		"#e010101#c66c4fc",					--【帮会同盟】
--		"#95#e010101#cFFFF00",
	};

local CHANNEL_DATA_IPREGION =
	{
		"set:UIIcons image:ChannelCorporative_Normal",
		"set:UIIcons image:ChannelCorporative_Hover",
		"set:UIIcons image:ChannelCorporative_Pushed",
		"#e010101#cFFFFFF",
--		"#e010101#cFFFF00",				--【同城】
		"nouse",
	};

local CHANNEL_DATA_RAID =
	{
		"set:Union1 image:Union_Channel_Normal",
		"set:Union1 image:Union_Channel_Hover",
		"set:Union1 image:Union_Channel_Pushed",
		"#cFFFFFF",
		"#e010101#cff3300",					--【团队】
	};

local CHANNEL_DATA_RAIDSQUAD =
	{
		"set:Buttons image:ChannelTeam_Normal",
		"set:Buttons image:ChannelTeam_Hover",
		"set:Buttons image:ChannelTeam_Pushed",
		"#cFFFFFF",
		"#e010101#cCC99FF",					--【小队】
	};

local CHANNEL_DATA_BIGWORLD =
	{
		"set:Button12 image:ChannelOUT_Normal",
		"set:Button12 image:ChannelOUT_Hover",
		"set:Button12 image:ChannelOUT_Pushed",
		"#cFFFFFF",
		"#e010101#cFF0000",					--【世外】
	};
--- 2014Q1大世界改造，世族功能去除。-- By Godwit. 2014.02.08
--- local CHANNEL_DATA_CLAN =
--- 	{
--- 		"set:Button12 image:ChannelShili_Normal",
--- 		"set:Button12 image:ChannelShili_Hover",
--- 		"set:Button12 image:ChannelShili_Pushed",
--- 		"#cFFFFFF",
--- 		"#e010101#cFF0000",					--【势力】
--- 	};
local CHANNEL_DATA_ZHENGZHAO =
	{
		"set:Button12 image:ChannelShili_Normal",
		"set:Button12 image:ChannelShili_Hover",
		"set:Button12 image:ChannelShili_Pushed",
		"#cFFFFFF",
		"#e010101#cFF0000",					--【征召】
	};
	

local CHANNEL_DATA_T300 =
	{
		"set:Button12 image:ChannelOUT_Normal",
		"set:Button12 image:ChannelOUT_Hover",
		"set:Button12 image:ChannelOUT_Pushed",
		"#cFFFFFF",
		"#e010101#cFF0000",					--【T300】
	};
	
local CHANNEL_DATA_PAID_WORLD =
	{
		"set:Buttons image:ChannelJiangHu_Normal",
		"set:Buttons image:ChannelJiangHu_Hover",
		"set:Buttons image:ChannelJiangHu_Pushed",
		"#cFFFFFF",
		"#e010101#c00FFCC",					--【世界】
--		"#92#e010101#c00FF00",
	};
	
local g_theCurrentChannel = "near";
local g_theCurrentChannelName = "";
local g_MoveCtl = nil;

-- 保存双人聊天动作字符串信息
local g_ChatActionTxt = "";
local g_InputLanguageIcon = {};

local m_UserIndex = {0,0,0}

function ChatFrame_GetCityRaw()
	local ret = {"同城",0,1,0,1,0,0,1,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0};
	return ret
end

function ChatFrame_PreLoad()
	this:RegisterEvent("APPLICATION_INITED",true);
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true);
	this:RegisterEvent("CHAT_MESSAGE",true);
	this:RegisterEvent("CHAT_CHANNEL_CHANGED",true);
	this:RegisterEvent("CHAT_CHANGE_PRIVATENAME",true);
	this:RegisterEvent("CHAT_TAB_CREATE_FINISH",true);
	this:RegisterEvent("CHAT_TAB_CONFIG_FINISH",true);
	this:RegisterEvent("ACCELERATE_KEYSEND",true);
	this:RegisterEvent("CHAT_CONTEX_MENU",true);
	this:RegisterEvent("CHAT_ACTSET",true);							-- 单人休闲动作
	this:RegisterEvent("CHAT_DOUBLE_ACTSET",true);				-- 双人休闲动作
	this:RegisterEvent("CHAT_ADJUST_MOVE_CTL",true);
	this:RegisterEvent("CHAT_LOAD_TAB_CONFIG",true);
	this:RegisterEvent("CHAT_MENUBAR_ACTION",true);			-- 接受聊天栏输入字符串
	this:RegisterEvent("RESET_ALLUI",true);
	this:RegisterEvent("SHOW_SPEAKER",true);
	this:RegisterEvent("FLASH_TAB",true);

	-- 注册同城频道闪烁, 登录后闪烁X秒
	this:RegisterEvent("UI_COMMAND",true);

	this:RegisterEvent("CHAT_FENPING_CREATE",true);
	this:RegisterEvent("CHAT_FENPING_CONFIG",true);
	this:RegisterEvent("CHAT_FENPING_CLOSE",true);
	this:RegisterEvent("OPEN_FENPING_DLG_CHATFRAME",true);
	this:RegisterEvent("HIDE_TLBB_MAIN",true);

	this:RegisterEvent("CHAT_ACCEPT_DOUBLE_ACTION_STRING",true);		-- 从聊天栏里输入双人休闲动作的响应
	this:RegisterEvent("CHAT_INPUTLANGUAGE_CHANGE",true);
	this:RegisterEvent("CHAT_TEXTCOLOR_SELECT",true);
	this:RegisterEvent("CHAT_FACEMOTION_SELECT",true);
	this:RegisterEvent("ASK_CHAT_EDITBOX_POS_SIZE",true);
	this:RegisterEvent("HIDE_THIS_UI",true);
	this:RegisterEvent("SHOW_SECRETSPEAKER",true);
	this:RegisterEvent("XUNZONG_GET_CURRENTCHANNEL",true);
	this:RegisterEvent("SHOW_TSPEAKER",true);
		
end

function ChatFrame_OnLoad()

	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图标资源为唯美版对应的资源
		CHANNEL_DATA_NEAR =
		{
			"set:WM_MainFrame02 image:BtnJin_Normal", 		-- 频道选择按钮普通
			"set:WM_MainFrame02 image:BtnJin_Hover", 		-- 频道选择按钮激活
			"set:WM_MainFrame02 image:BtnJin_Pushed",		-- 频道选择按钮按下
			"#cFFFFFF",									-- 聊天内容颜色
			"#e010101#c00FFCC",						-- 名称【附近】
		};

		CHANNEL_DATA_SCENE =
		{
			"set:WM_MainFrame02 image:BtnShe_Normal",
			"set:WM_MainFrame02 image:BtnShe_Hover",
			"set:WM_MainFrame02 image:BtnShe_Pushed",
			"#cFFFFFF",
			"#e010101#c00FFCC",					--【世界】
		};

		CHANNEL_DATA_PRIVATE =
		{
			"set:WM_MainFrame02 image:BtnMi_Normal",
			"set:WM_MainFrame02 image:BtnMi_Hover",
			"set:WM_MainFrame02 image:BtnMi_Pushed",
			"#cFFFFFF",
			"#e010101#cFF7C80",					--【私聊】
		};

		CHANNEL_DATA_SYSTEM =
		{
			"set:WM_MainFrame02 image:BtnMi_Normal",
			"set:WM_MainFrame02 image:BtnMi_Hover",
			"set:WM_MainFrame02 image:BtnMi_Pushed",
			"#cFF0000",
			"#e010101#cFF0000",					--【系统】
		};

		CHANNEL_DATA_TEAM =
		{
			"set:WM_MainFrame02 image:BtnZu_Normal",
			"set:WM_MainFrame02 image:BtnZu_Hover",
			"set:WM_MainFrame02 image:BtnZu_Pushed",
			"#cFFFFFF",
			"#e010101#cCC99FF",					--【队伍】
		};

		CHANNEL_DATA_SELF =
		{
			"set:WM_MainFrame02 image:BtnZu_Normal",
			"set:WM_MainFrame02 image:BtnZu_Hover",
			"set:WM_MainFrame02 image:BtnZu_Pushed",
			"#e010101#cFFFFFF",		--【自用】
			"nouse",
		};

		CHANNEL_DATA_HELP =
		{
			"set:WM_MainFrame02 image:BtnZu_Normal",
			"set:WM_MainFrame02 image:BtnZu_Hover",
			"set:WM_MainFrame02 image:BtnZu_Pushed",
			"#e010101#cFFFFFF",		--【帮助】
			"nouse",
		};

		CHANNEL_DATA_MENPAI =
		{
			"set:WM_MainFrame02 image:BtnMen_Normal",
			"set:WM_MainFrame02 image:BtnMen_Hover",
			"set:WM_MainFrame02 image:BtnMen_Pushed",
			"#cFFFFFF",
			"#e010101#cFFFF00",					--【门派】
		};

		CHANNEL_DATA_GUILD =
		{
			"set:WM_MainFrame02 image:BtnBang_Normal",
			"set:WM_MainFrame02 image:BtnBang_Hover",
			"set:WM_MainFrame02 image:BtnBang_Pushed",
			"#cFFFFFF",
			"#e010101#cFFCC99",					--【帮会】
		};

		CHANNEL_DATA_GUILD_LEAGUE =
		{
			"set:WM_MainFrame02 image:BtnMeng_Normal",
			"set:WM_MainFrame02 image:BtnMeng_Hover",
			"set:WM_MainFrame02 image:BtnMeng_Pushed",
			"#cFFFFFF",
			"#e010101#c66c4fc",					--【帮会同盟】
		};

		CHANNEL_DATA_IPREGION =
		{
			"set:WM_MainFrame02 image:BtnCheng_Normal",
			"set:WM_MainFrame02 image:BtnCheng_Hover",
			"set:WM_MainFrame02 image:BtnCheng_Pushed",
			"#e010101#cFFFFFF",						--【同城】
			"nouse",
		};

		CHANNEL_DATA_RAID =
		{
			"set:WM_MainFrame02 image:BtnTuan_Normal",
			"set:WM_MainFrame02 image:BtnTuan_Hover",
			"set:WM_MainFrame02 image:BtnTuan_Pushed",
			"#cFFFFFF",
			"#e010101#cff3300",					--【团队】
		};

		CHANNEL_DATA_RAIDSQUAD =
		{
			"set:WM_MainFrame02 image:BtnZu_Normal",
			"set:WM_MainFrame02 image:BtnZu_Hover",
			"set:WM_MainFrame02 image:BtnZu_Pushed",
			"#cFFFFFF",
			"#e010101#cCC99FF",					--【小队】
		};

		CHANNEL_DATA_BIGWORLD =
		{
			"set:WM_MainFrame02 image:BtnGu_Normal",
			"set:WM_MainFrame02 image:BtnGu_Hover",
			"set:WM_MainFrame02 image:BtnGu_Pushed",
			"#cFFFFFF",
			"#e010101#cFF0000",					--【世外】
		};

--- 2014Q1大世界改造，世族功能去除。-- By Godwit. 2014.02.08
---		CHANNEL_DATA_CLAN =
---			{
---				"set:WM_MainFrame02 image:BtnZu2_Normal",
---				"set:WM_MainFrame02 image:BtnZu2_Hover",
---				"set:WM_MainFrame02 image:BtnZu2_Pushed",
---				"#cFFFFFF",
---				"#e010101#cFF0000",					--【势力】
---			};
		CHANNEL_DATA_ZHENGZHAO =
		{
			"set:WM_MainFrame02 image:BtnZu2_Normal",
			"set:WM_MainFrame02 image:BtnZu2_Hover",
			"set:WM_MainFrame02 image:BtnZu2_Pushed",
			"#cFFFFFF",
			"#e010101#cFF0000",					--【征召】
		};
		
		CHANNEL_DATA_PAID_WORLD =
		{
			"set:Buttons image:ChannelWorld_Normal",
			"set:Buttons image:ChannelWorld_Hover",
			"set:Buttons image:ChannelWorld_Pushed",
			"#cFFFFFF",
			"#e010101#c00FFCC",					--【世界】
	--		"#92#e010101#c00FF00",
		};

		g_InputLanguageIcon[1] = "set:WM_MainFrame02 image:BtnE_Normal";
		g_InputLanguageIcon[2052] = "set:WM_MainFrame02 image:BtnZhong_Normal";
		g_InputLanguageIcon[1033] = "set:WM_MainFrame02 image:BtnE_Normal";
	else		--若客户端是经典版
		g_InputLanguageIcon[1] = "set:Button2 image:BtnE_Normal";
		g_InputLanguageIcon[2052] = "set:Buttons image:IME_Chinese";
		g_InputLanguageIcon[1033] = "set:Button2 image:BtnE_Normal";
	end

	CHANNEL_DATA["near"] = CHANNEL_DATA_NEAR;
	CHANNEL_DATA["scene"] = CHANNEL_DATA_SCENE;
	CHANNEL_DATA["private"] = CHANNEL_DATA_PRIVATE;
	CHANNEL_DATA["system"] = CHANNEL_DATA_SYSTEM;
	CHANNEL_DATA["team"] = CHANNEL_DATA_TEAM;
	CHANNEL_DATA["self"] = CHANNEL_DATA_SELF;
	CHANNEL_DATA["menpai"] = CHANNEL_DATA_MENPAI;
	CHANNEL_DATA["guild"] = CHANNEL_DATA_GUILD;
	CHANNEL_DATA["guild_league"] = CHANNEL_DATA_GUILD_LEAGUE;
	CHANNEL_DATA["help"] = CHANNEL_DATA_HELP;
	CHANNEL_DATA["ipregion"] = CHANNEL_DATA_IPREGION;

	CHANNEL_DATA["raid"] = CHANNEL_DATA_RAID;
	CHANNEL_DATA["raidsquad"] = CHANNEL_DATA_RAIDSQUAD;
	CHANNEL_DATA["bigworld"] = CHANNEL_DATA_BIGWORLD;
---		CHANNEL_DATA["clan"] = CHANNEL_DATA_CLAN;
	CHANNEL_DATA["zhengyou"] = CHANNEL_DATA_ZHENGZHAO;
	CHANNEL_DATA["t300"] = CHANNEL_DATA_T300;
	CHANNEL_DATA["paid_world"] = CHANNEL_DATA_PAID_WORLD;


	--TAB页的配置信息
	channel_tab[2] = Chat_SelfChk;
	channel_tab[3] = Chat_City;
	channel_tab[4] = Chat_CreateChk1;
	channel_tab[5] = Chat_JiangHu;
	channel_tab[6] = Chat_CreateChk2;
	channel_tab[7] = Chat_CreateChk3;

	channel_flash[3] = Chat_City_Flash

	-- 按照GameDefine2.h 中 ENUM_CHAT_TYPE 顺序
	channel_config[0] = {"综合",1,1,1,1,1,1,1,1,0,1,0,0,1,1,1,0,1, 0,0,0,0,1,0,1,1};
	channel_config[1] = {"系统",0,0,0,1,1,0,0,0,1,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0};
	channel_config[2] = {"个人",0,1,0,1,0,0,1,0,0,0,0,0,1,1,1,0,1, 1,0,0,0,0,0,1,0};
	channel_config[3] = ChatFrame_GetCityRaw();
	channel_config[4] = {"#{ZZDY_130131_85}",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,1,0,0,0,0,0,0};
	channel_config[5] = {"江湖",0,1,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0, 0,0,0,0,0,0,0,1};
	channel_config[6] = {"",1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1, 0,0,0,0,1,0,0,0};
	channel_config[7] = {"",1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1, 0,0,0,0,1,0,0,0};
	--分屏
	channel_config[8] = {"",1,1,1,1,1,1,1,1,0,1,0,0,1,1,1,0,1, 1,0,0,0,1,0,1,1};

	--隐藏小喇叭
	Chat_ChatSpeaker_StarWindow:SetText( "" );
	Chat_ChatSpeaker_StarWindow:SetProperty( "Name","" );
	Chat_ChatSpeaker_StarWindow:Hide();
	Chat_ChatSpeaker_StarWindow2:Hide();

	Chat_Frame_FenpingFrame:Hide();
	NotFlashAllTab()

	Chat_Chat_ScaleBtn:SetProperty("MiniHeight" ,tostring(g_MinFrameHeight) )
	Chat_Chat_ScaleBtn:SetProperty("MaxHeight" ,tostring(g_MaxFrameHeight) )
	Chat_Chat_ScaleBtn:SetProperty("MinWidth" ,tostring(g_MinWidth) )
	Chat_Chat_ScaleBtn:SetProperty("MaxWidth" ,tostring(g_MaxWidth) )

end

function ChatFrame_OnEvent(event)

	local gmType = DataPool:LuaFnGetGMVisibleType()
	if gmType == 1 or gmType == 2  then --观战号和录像号
		this:Hide()
		return
	end
	
	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end
	
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		this:Show();
		--设置历史消息记录保存的最大值
		Talk:SetMaxSaveNumber(tonumber(Chat_Frame_History:GetProperty("ChatBoardNumber")));
		--设置系统消息的自动消失时间间隔
		Talk:SetDisappearTime(tonumber(Chat_Frame_History:GetProperty("BoardKillTimer")));
		Talk:SetCurTab(channel_seltab);

		ChatFrame_SetTabConfig( 0 );
		ChatFrame_SetTabConfig( 1 );
		ChatFrame_SetTabConfig( 2 );
		ChatFrame_SetTabConfig( 3 );
		ChatFrame_SetTabConfig( 4 );
		ChatFrame_SetTabConfig( 5 );
		channel_tab[3]:SetText("同城");
		channel_tab[4]:SetText("征召");
		channel_tab[5]:SetText("江湖");
		ChatFrame_SetChannelSel(g_theCurrentChannel, g_theCurrentChannelName);

		local noChatActiveMode = Variable:GetVariable("NonChatActive");
		if(noChatActiveMode==nil or noChatActiveMode=="0") then
			Chat_EditBox:SetProperty("DefaultEditBox", "True");
		end
		ChatFrame_InputLanguage_Changed();

		Chat_CheckBox_Frame:Hide()
		local _,_,_,_,_,_,_,_,_,f10,_,_,_,_,_,_,_,_,_,_,_,_,_,_ = SystemSetup:GameGetData();
		local alphaStr = string.format("%f" , f10 / 2 )
		Chat_Frame_HistoryFrame:SetProperty("Alpha" , alphaStr)
		Chat_Frame_FenpingFrame:SetProperty("Alpha" , alphaStr)

	elseif (event == "CHAT_MESSAGE" ) then
		--ChatFrame_InsertChatContent(arg0, arg1, arg2);
	elseif (event == "CHAT_CHANNEL_CHANGED" ) then
		ChatFrame_ChannelChanged(arg0);
	elseif (event == "CHAT_TAB_CREATE_FINISH") then
		ChatFrame_CreateTabFinish(arg0,arg1,arg2);
	elseif (event == "CHAT_FENPING_CREATE") then
		ChatFrame_CreateFenping(arg0);
	elseif (event == "CHAT_FENPING_CLOSE") then
		ChatFrame_CloseFenping(arg0);
	elseif (event == "CHAT_FENPING_CONFIG") then
		ChatFrame_ConfigFenping(arg0);
	elseif (event == "OPEN_FENPING_DLG_CHATFRAME") then
		ChatFrame_OpenFenpingDlg(arg0);
	elseif (event == "CHAT_TAB_CONFIG_FINISH") then
		ChatFrame_ConfigTabFinish(arg0,arg1,arg2);
	elseif (event == "ACCELERATE_KEYSEND") then
		ChatFrame_HandleAccKey(arg0,arg1,arg2);
	elseif (event == "CHAT_CHANGE_PRIVATENAME") then
		ChatFrame_ChangePrivateName(arg0);
	elseif (event == "CHAT_CONTEX_MENU") then
		ChatFrame_ContexMenu_Open(arg0,arg1);
	elseif (event == "CHAT_ACTSET")	then							-- 单人聊天动作
		ChatFrame_ActSetMessage(arg0, 1);
	elseif (event == "CHAT_DOUBLE_ACTSET")	then			-- 双人聊天动作
		ChatFrame_ActSetMessage(arg0, 2);
	elseif (event == "CHAT_ADJUST_MOVE_CTL") then
	--	ChatFrame_AdjustMoveCtl(arg0, arg1);
	elseif (event == "CHAT_LOAD_TAB_CONFIG") then
		ChatFrame_LoadTabConfig(arg2,arg0,arg1);

	-- 接受聊天栏输入字符串
	elseif (event == "CHAT_MENUBAR_ACTION") then
		ChatFrame_HandleMenuBarAction(arg0,arg1,arg2);
	elseif ( event == "HIDE_TLBB_MAIN" ) then
		this:Hide()
	elseif (event == "RESET_ALLUI") then
		-- 隐藏多余的Tab窗体
		channel_tab_total = 6;
		for i= channel_tab_total, CHANNEL_TAB_MAX-1 do
			ChatFrame_SetTabMouseRButtonHollow(i, 1);
			channel_tab[i]:Hide();
		end
		g_theCurrentChannel = "near";
		g_theCurrentChannelName = "";
		channel_seltab = 0;
		--隐藏小喇叭
		Chat_ChatSpeaker_StarWindow:SetText( "" );
		Chat_ChatSpeaker_StarWindow:SetProperty( "Name","" );
		Chat_ChatSpeaker_StarWindow:Hide();
		Chat_ChatSpeaker_StarWindow2:Hide();

		Chat_SystemChk : SetCheck(1)

		--先关闭分屏 TT:81898
		Talk:CloseFenping();

		NotFlashAllTab()
		ChatFrame_SetEditBoxTxt("");
		ChatFrame_SetChannelSel("near","");
		PushEvent("XUNZONG_CHANGE_CURRENTCHANNEL", g_theCurrentChannel)
		g_ChatFramePrivate = "";
	  	PushEvent("XUNZONG_CHANGE_PRIVATE", g_ChatFramePrivate);
	elseif (event == "SHOW_SPEAKER") then
		Chat_ChatSpeaker_StarWindow:SetProperty( "Font","SongTiBmp12" );
		g_CurSecretType = -1;
		g_CurSpeakerName = arg0;
		g_CurSpeakerContex = arg1;
		g_CurSpeakerZoneworldid = tonumber(arg2)
		g_CurSpeakerDisplayName = g_CurSpeakerName
		local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
		local chatsymbol = tonumber(arg3)
		local strSymbol = ""
		if chatsymbol > 0 then
			local trs = Player:LuaFnGetChatSymbolData("Transfer_BYID",chatsymbol)
			if trs~=nil then
				strSymbol = "#+"..tostring(trs)
			end
		end
		
		local relationInfo = tostring( arg4 )
		if(Player:GetName() == g_CurSpeakerName and (selfZoneWorldID == g_CurSpeakerZoneworldid or selfZoneWorldID == -1 or g_CurSpeakerZoneworldid == -1) )then
			Chat_ChatSpeaker_StarWindow:SetText( strSymbol.."#e010101["..tostring( arg0 ).."]#W:"..tostring(arg1) );
		else
			if selfZoneWorldID ~= -1 and selfZoneWorldID ~= g_CurSpeakerZoneworldid and g_CurSpeakerZoneworldid ~= -1 then
				local serverName = DataPool:GetServerName( g_CurSpeakerZoneworldid )
				g_CurSpeakerDisplayName = g_CurSpeakerName.."@"..tostring(serverName)
				Chat_ChatSpeaker_StarWindow:SetText( strSymbol..relationInfo.."#e010101#c00ccff["..tostring( g_CurSpeakerDisplayName ).."]#W:"..tostring(arg1) )
			else
				Chat_ChatSpeaker_StarWindow:SetText( strSymbol..relationInfo.."#e010101#c00ccff["..tostring( arg0 ).."]#W:"..tostring(arg1) );
			end
		end
		
		Chat_ChatSpeaker_StarWindow:SetProperty( "Name",strSymbol..strSymbol.."["..tostring(arg0).."@"..g_CurSpeakerZoneworldid.."]" );
		Chat_ChatSpeaker_StarWindow:SetProperty( "Reset","false" );
		Chat_ChatSpeaker_StarWindow2:SetProperty( "Reset","false" );
		Talk:HideContexMenu4Speaker();
	elseif (event == "SHOW_TSPEAKER") then
		g_CurSecretType = -1;
		g_CurSpeakerName = arg0;
		g_CurSpeakerContex = arg1;
		g_CurSpeakerZoneworldid = tonumber(arg2)
		local nlevel = tonumber(arg3)
		if(g_TBlevel > nlevel) then
			return
		end
		g_TBlevel = nlevel
		Chat_ChatSpeaker_StarWindow:SetProperty( "Font","YouYuan13" );
		-- PushDebugMessage("g_level="..g_level)
		g_CurSpeakerDisplayName = g_CurSpeakerName
		local selfZoneWorldID = DataPool:GetSelfZoneWorldID()

		if(Player:GetName() == g_CurSpeakerName and (selfZoneWorldID == g_CurSpeakerZoneworldid or selfZoneWorldID == -1 or g_CurSpeakerZoneworldid == -1) )then
			Chat_ChatSpeaker_StarWindow:SetText( "["..tostring( arg0 ).."]#W:"..tostring(arg1) );
		else
			if selfZoneWorldID ~= -1 and selfZoneWorldID ~= g_CurSpeakerZoneworldid and g_CurSpeakerZoneworldid ~= -1 then
				local serverName = DataPool:GetServerName( g_CurSpeakerZoneworldid )
				g_CurSpeakerDisplayName = g_CurSpeakerName.."@"..tostring(serverName)
				Chat_ChatSpeaker_StarWindow:SetText( "#c00ccff["..tostring( g_CurSpeakerDisplayName ).."]#W:"..tostring(arg1) )
			else
				Chat_ChatSpeaker_StarWindow:SetText( "#c00ccff["..tostring( arg0 ).."]#W:"..tostring(arg1) );
			end
		end
		Chat_ChatSpeaker_StarWindow:SetProperty( "Reset","false" );
		Chat_ChatSpeaker_StarWindow2:SetProperty( "Reset","false" );
		Talk:HideContexMenu4Speaker();
		KillTimer("ClenTBLevel()");	
		SetTimer("ChatFrame","ClenTBLevel()", 5000);		--设置定时器5s可以更新信息

--	取消每次在同城发言中出现按钮闪烁
--	elseif (event == "FLASH_TAB") then
--
--		local showTab = tonumber(arg0);
--		local isShow  = tonumber(arg1);
--
--		if(showTab > 0 and showTab < CHANNEL_TAB_MAX -1) then
--			if(isShow > 0 ) then
--				FlashTab(showTab);
--			else
--				NotFlashTab(showTab);
--			end
--		end

	-- 上线同城频道闪烁
	elseif (event == "UI_COMMAND") then
		if (tonumber( arg0 ) == 870001001) then
			FlashTab(3);
			SetTimer("ChatFrame","StopFlashCityChannel()", 5000);		--设置定时器10秒钟关闭窗口
		end
	elseif(event == "CHAT_ACCEPT_DOUBLE_ACTION_STRING") then
		ChatFrame_DoubleChatActionMessageSend(tonumber(arg0), tostring(arg1));
	elseif (event == "CHAT_INPUTLANGUAGE_CHANGE") then
		ChatFrame_InputLanguage_Changed();
	elseif (event == "CHAT_TEXTCOLOR_SELECT") then
		ChatFrame_SelectColorFaceFinish(arg0, arg1);
	elseif (event == "CHAT_FACEMOTION_SELECT") then
		ChatFrame_SelectColorFaceFinish(arg0, arg1);
	elseif (event == "HIDE_THIS_UI") then
		if this:IsVisible() then
			this:Hide()
		else
			this:Show()
		end
	elseif (event == "ASK_CHAT_EDITBOX_POS_SIZE") then
		ChatFrame_DispatchEditBoxPosSize()
	elseif (event == "SHOW_SECRETSPEAKER") then
		Chat_ChatSpeaker_StarWindow:SetProperty( "Font","SongTiBmp12" );
		g_CurSecretType = 1;
		g_CurSecretFlag = arg0;
		g_CurSpeakerContex = arg1;
		g_CurSpeakerZoneworldid = tonumber(arg2)
		local selfZoneWorldID = DataPool:GetSelfZoneWorldID()

		if (g_CurSecretFlag == "1") then
			Chat_ChatSpeaker_StarWindow:SetText( "#e010101#-63#G您的好友#W:"..tostring(arg1) );
		elseif (g_CurSecretFlag == "2") then
			Chat_ChatSpeaker_StarWindow:SetText( "#e010101#-60#cff0000您的仇人#W:"..tostring(arg1) );
		elseif	(g_CurSecretFlag == "3") then
			Chat_ChatSpeaker_StarWindow:SetText( "#e010101#-61#W您的消息#W:"..tostring(arg1) );
		else
			Chat_ChatSpeaker_StarWindow:SetText( "#e010101#-62#cbe38ff江湖奇闻#W:"..tostring(arg1) );
		end
		Chat_ChatSpeaker_StarWindow:SetProperty( "Name","[speaker]" );
		Chat_ChatSpeaker_StarWindow:SetProperty( "Reset","false" );
		Chat_ChatSpeaker_StarWindow2:SetProperty( "Reset","false" );
		Talk:HideContexMenu4Speaker();
	elseif (event == "XUNZONG_GET_CURRENTCHANNEL") then
		PushEvent("XUNZONG_CHANGE_CURRENTCHANNEL", g_theCurrentChannel);
	  	PushEvent("XUNZONG_CHANGE_PRIVATE", g_ChatFramePrivate);
	end
end

function StopFlashCityChannel()
	NotFlashTab(3);
	KillTimer("StopFlashCityChannel()");		--关闭定时器
end

function ClenTBLevel()
	g_TBlevel = 0
	KillTimer("ClenTBLevel()");		--关闭定时器
end

function NotFlashTab(idx)
	for i =2, 6 do
		if(idx == i and channel_flash[i])then
			g_CurFlashTab = -1;
			channel_flash[i] : Play( false );
		end
	end
end

function FlashTab(idx)
	for i =2, 6 do
		if(idx == i and channel_flash[i])then
			g_CurFlashTab = idx;
			channel_flash[i] : Play( true );
		end
	end
end

function NotFlashAllTab()
	for i =2, 6 do
		if(channel_flash[i])then

			channel_flash[i] : Play( false );
		end

	end

	g_CurFlashTab = -1;
end

function ChatFrame_ChannelListSelect()
	Chat_Frame_ChannelFrame:Hide();
	
	local selCh = Chat_Frame_Channel:GetProperty("HoverChannel");
	local prv = Chat_Frame_Channel:GetHoverChannelName();
	
	ChatFrame_ChannelListChange( selCh, prv );
end

function ChatFrame_ChannelListChange( selChannel, prvtxt)

	if(CHANNEL_DATA[selChannel] == nil) then
		return;
	end

	g_theCurrentChannel = selChannel;
	g_theCurrentChannelName = prvtxt;

	ChatFrame_SetChannelSel(g_theCurrentChannel, g_theCurrentChannelName);
	local curtxt = Chat_EditBox:GetItemElementsString();
	local facetxt = Talk:ModifyChatTxt(g_theCurrentChannel, g_theCurrentChannelName, curtxt);
	ChatFrame_SetEditBoxTxt(facetxt);
	PushEvent("XUNZONG_CHANGE_CURRENTCHANNEL", g_theCurrentChannel)
	if(g_theCurrentChannel == "private") then
		g_ChatFramePrivate = facetxt;
	else
		g_ChatFramePrivate = "";
	end
	PushEvent("XUNZONG_CHANGE_PRIVATE", g_ChatFramePrivate);
end

function ChatFrame_ChangePrivateName( newname )
	if(ChatFrame_IsNameMySelf(newname) > 0) then
		return;
	end
	local curtxt = Chat_EditBox:GetItemElementsString();
	local facetxt = Talk:ModifyChatTxt("private", newname, curtxt);
	ChatFrame_SetEditBoxTxt(facetxt);
	g_ChatFramePrivate = facetxt;
	PushEvent("XUNZONG_CHANGE_PRIVATE", g_ChatFramePrivate);
end

function ChatFrame_InsertChatContent(chatType, chatTalkerName, chatContent)
	if(CHANNEL_DATA[chatType] == nil) then
		return
	end

	local strFinal;
	local strHeader = Talk:GetChannelHeader(chatType, chatTalkerName);
	if(nil == strHeader) then
		return
	end
	if(chatTalkerName == "" and chatType ~= "self") then
		strFinal = CHANNEL_DATA[chatType][5];
		strFinal = strFinal .. "[" .. strHeader .. "]";
		strFinal = strFinal .. CHANNEL_DATA[chatType][4] ..chatContent;
	else
		if(chatType ~= "self") then
			strFinal = CHANNEL_DATA[chatType][5];
			if(string.byte(chatContent, 1) ~= 64 and string.byte(chatContent, 1) ~= 42) then -- '@' 文字表情解析
				strFinal = strFinal .. "[" .. strHeader .. "]";
				if(ChatFrame_IsNameMySelf(chatTalkerName) > 0) then
					strFinal = strFinal .. "#W[" .. chatTalkerName .. "]";
				else
					strFinal = strFinal .. Talk:GetHyperLinkString(chatType,chatTalkerName);
				end
				strFinal = strFinal .. CHANNEL_DATA[chatType][4] .. "：" ..chatContent;
			else
				local strTemplate = Talk:GetTalkTemplateString(chatTalkerName, chatContent);
				strFinal = strFinal .. "[" .. strHeader .. "]";
				strFinal = strFinal .. strTemplate;
			end
		else
			strFinal = CHANNEL_DATA[chatType][4] .. chatContent;
		end
	end

	Chat_Frame_History:InsertChatString(strFinal);

end

function ChatFrame_DispatchEditBoxPosSize()

	local EditboxX= Chat_EditBox:GetProperty("AbsoluteXPosition") + Chat_ToolBar:GetProperty("AbsoluteXPosition") + Chat_Frame:GetProperty("AbsoluteXPosition")
	local EditboxY = Chat_EditBox:GetProperty("AbsoluteYPosition") + Chat_ToolBar:GetProperty("AbsoluteYPosition") + Chat_Frame:GetProperty("AbsoluteYPosition")
	local EditboxWidth = Chat_EditBox:GetProperty("AbsoluteWidth")
	local EditboxHeight = Chat_EditBox:GetProperty("AbsoluteHeight")
	PushEvent("REQ_CHAT_EDITBOX_POS_SIZE", EditboxX, EditboxY, EditboxWidth,EditboxHeight)

end

function ChatFrame_PrepareMove()
	g_MoveCtl = {
					frame = Chat_Frame,
					check = Chat_CheckBox_Frame,
					history = Chat_Frame_HistoryFrame,
					toolbar1 = Chat_ToolBar,
					toolbar2 = Chat_Button_ChatFrame,
					fenping = Chat_Frame_FenpingFrame,
					speaker = Chat_ChatSpeaker,
				};
end

--设置上屏高度
function ChatFrame_MoveCtl(dir)
	ChatFrame_PrepareMove();

	local absFrameHeight = g_MoveCtl.frame:GetProperty("AbsoluteHeight");
	local absFenpingHeight = g_MoveCtl.fenping:GetProperty("AbsoluteHeight");
	local absHistoryHeight = g_MoveCtl.history:GetProperty("AbsoluteHeight");
	local absCheckHeight = g_MoveCtl.check:GetProperty("AbsoluteHeight");
	local absToolBarHeight_1 = g_MoveCtl.toolbar1:GetProperty("AbsoluteHeight");
	local absToolBarHeight_2 = g_MoveCtl.toolbar2:GetProperty("AbsoluteHeight");
	local absToolBarHeight = absToolBarHeight_1 + absToolBarHeight_2
	local absSpeakerHeight = g_MoveCtl.speaker:GetProperty("AbsoluteHeight")
	local step = 28;

	if(dir > 0) then
		--分屏开着
		if g_MoveCtl.fenping:IsVisible() then
			--最外框已达最大值，缩小分屏
			if tonumber(absFrameHeight) >= g_MaxFrameHeight then
				--分屏已经最小值，不能再缩
				if absFenpingHeight - step < g_FenpingMinHeight then
					return
				else
					--fenping
					local udimStr_fenping = string.format("{%f,%f}", 0.000000, absFenpingHeight - step );
					g_MoveCtl.fenping:SetProperty("UnifiedHeight", udimStr_fenping );
					udimStr_fenping= string.format("{%f,%f}", 1.000000, -(absToolBarHeight + absFenpingHeight - step));
					g_MoveCtl.fenping:SetProperty("UnifiedYPosition", udimStr_fenping);
				end
			--最外框没有达到最大值，直接增加，分屏不动
			else
				if absFrameHeight + step > g_MaxFrameHeight then
					step = g_MaxFrameHeight - absFrameHeight
				end
				--frame
				g_MoveCtl.frame:SetProperty("AbsoluteHeight", absFrameHeight + step );
				local udimStr_frame= string.format("{%f,%f}", 1.000000, -(absFrameHeight + step + g_MoveUpHeight));
				g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
			end
		--分屏关着
		else
			--最外框已达最大值
			if tonumber(absFrameHeight) >= g_MaxFrameHeight then
				return
			else
				if absFrameHeight + step > g_MaxFrameHeight then
					step = g_MaxFrameHeight - absFrameHeight
				end
				--frame
				g_MoveCtl.frame:SetProperty("AbsoluteHeight", absFrameHeight + step );
				local udimStr_frame= string.format("{%f,%f}", 1.000000, -(absFrameHeight + step + g_MoveUpHeight));
				g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
			end
		end
	else
		if tonumber(absHistoryHeight) <= g_MinHeight then
			return
		else
			if absHistoryHeight - step < g_MinHeight then
				step = absHistoryHeight - g_MinHeight
			end
			--frame
			g_MoveCtl.frame:SetProperty("AbsoluteHeight", absFrameHeight - step );
			local udimStr_frame= string.format("{%f,%f}", 1.000000, -(absFrameHeight - step + g_MoveUpHeight));
			g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
		end
	end
	--History
	if g_MoveCtl.fenping:IsVisible() then
		local new_absFenpingHeight = g_MoveCtl.fenping:GetProperty("AbsoluteHeight");
		local other_Height = absSpeakerHeight + absCheckHeight + new_absFenpingHeight + absToolBarHeight + g_Spin
		local udimStr_history = string.format("{%f,%f}", 1.000000, -other_Height);
		g_MoveCtl.history:SetProperty("UnifiedHeight" ,udimStr_history)

	else
		local other_Height = absSpeakerHeight + absCheckHeight + absToolBarHeight
		local udimStr_history = string.format("{%f,%f}", 1.000000, -other_Height);
		g_MoveCtl.history:SetProperty("UnifiedHeight" ,udimStr_history)
	end
	Chat_Frame_History:ScrollToEnd();
end

--设置下屏高度
function ChatFrame_MoveCtl_Fenping(dir)
	ChatFrame_PrepareMove();

	local absFrameHeight = g_MoveCtl.frame:GetProperty("AbsoluteHeight");
	local absFenpingHeight = g_MoveCtl.fenping:GetProperty("AbsoluteHeight");
	local absHistoryHeight = g_MoveCtl.history:GetProperty("AbsoluteHeight");
	local absCheckHeight = g_MoveCtl.check:GetProperty("AbsoluteHeight");
	local absToolBarHeight_1 = g_MoveCtl.toolbar1:GetProperty("AbsoluteHeight");
	local absToolBarHeight_2 = g_MoveCtl.toolbar2:GetProperty("AbsoluteHeight");
	local absToolBarHeight = absToolBarHeight_1 + absToolBarHeight_2
	local absSpeakerHeight = g_MoveCtl.speaker:GetProperty("AbsoluteHeight")
	local step = 28;

	--下面3位表示是否需要移动控件的位置
	local bMoveFrame = 0
	local bMoveHistory = 0
	local bMoveFenping = 0
	--注意，策划要求：上下两个屏总和有最大值，下面屏的最大高度为g_FenpingMaxHeight,当两屏总和达到最大值的时候，下面的屏会顶开上面的屏
	if absFenpingHeight + step > g_FenpingMaxHeight then
		--下屏的高度超过最大值，缩回原有值
		step = absFenpingHeight - g_FenpingMinHeight;
		--fenping
		local udimStr_fenping = string.format("{%f,%f}", 0.000000, absFenpingHeight - step );
		g_MoveCtl.fenping:SetProperty("UnifiedHeight", udimStr_fenping );
		udimStr_fenping= string.format("{%f,%f}", 1.000000, -(absToolBarHeight + absFenpingHeight - step));
		g_MoveCtl.fenping:SetProperty("UnifiedYPosition", udimStr_fenping);
		--frame
		g_MoveCtl.frame:SetProperty("AbsoluteHeight", absFrameHeight - step );
		local udimStr_frame= string.format("{%f,%f}", 1.000000, -(absFrameHeight - step + g_MoveUpHeight));
		g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
	else
		--下屏高度没超过最大值,增加分屏高度
		--fenping
		local udimStr_fenping = string.format("{%f,%f}", 0.000000, absFenpingHeight + step );
		g_MoveCtl.fenping:SetProperty("UnifiedHeight", udimStr_fenping );
		udimStr_fenping= string.format("{%f,%f}", 1.000000, -(absToolBarHeight + absFenpingHeight + step));
		g_MoveCtl.fenping:SetProperty("UnifiedYPosition", udimStr_fenping);

		if absFrameHeight + step > g_MaxFrameHeight then
			--frame
			g_MoveCtl.frame:SetProperty("AbsoluteHeight", g_MaxFrameHeight );
			local udimStr_frame= string.format("{%f,%f}", 1.000000, -(g_MaxFrameHeight + g_MoveUpHeight));
			g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
		else
			--frame
			g_MoveCtl.frame:SetProperty("AbsoluteHeight", absFrameHeight + step );
			local udimStr_frame= string.format("{%f,%f}", 1.000000, -(absFrameHeight + step + g_MoveUpHeight));
			g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
		end
	end

	--History

	local new_absFenpingHeight = g_MoveCtl.fenping:GetProperty("AbsoluteHeight");
	local other_Height = absSpeakerHeight + absCheckHeight + new_absFenpingHeight + absToolBarHeight + g_Spin
	local udimStr_history = string.format("{%f,%f}", 1.000000, -other_Height);
	g_MoveCtl.history:SetProperty("UnifiedHeight" ,udimStr_history)

	Chat_Frame_History:ScrollToEnd();
	Chat_Frame_Fenping:ScrollToEnd();
end

--设置两屏的宽度
function ChatFrame_WidthCtl(dir)
	ChatFrame_PrepareMove();
	local absFrameWidth = g_MoveCtl.frame:GetProperty("AbsoluteWidth");

	local step;
	if(dir > 0) then
		step = -18
		if(absFrameWidth-step > g_MaxWidth) then
			return;
		end
	else
		step = 18;
		if(absFrameWidth-step < g_MinWidth) then
			return;
		end
	end

	--frame
	g_MoveCtl.frame:SetProperty("AbsoluteWidth", absFrameWidth-step);

	Chat_Frame_History:ScrollToEnd();
	Chat_Frame_Fenping:ScrollToEnd();
end

function ChatFrame_AdjustMoveCtl( screenWidth, screenHeight )
	ChatFrame_PrepareMove();
end

function ChatFrame_ChannelChanged(force)

	if(force == "force_near") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(force == "close_team" and g_theCurrentChannel == "team") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(force == "close_menpai" and g_theCurrentChannel == "menpai") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(force == "close_guild" and g_theCurrentChannel == "guild") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(force == "close_guild_league" and g_theCurrentChannel == "guild_league") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(g_theCurrentChannel == "private") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(force == "close_raid" and g_theCurrentChannel == "raid") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(force == "close_raid" and g_theCurrentChannel == "raidsquad") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
	elseif(force == "close_bigworld" and g_theCurrentChannel == "bigworld") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
		--关闭频道列表，不然暂留的显示错误
		Chat_Frame_ChannelFrame:Hide()
	elseif(force == "close_t300" and g_theCurrentChannel == "t300") then
		g_theCurrentChannel = "near"
		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
		--关闭频道列表，不然暂留的显示错误
		Chat_Frame_ChannelFrame:Hide()
	elseif(force == "add_t300" and (g_theCurrentChannel == "scene" or g_theCurrentChannel == "menpai" or g_theCurrentChannel == "ipregion" or g_theCurrentChannel == "paid_world") ) then
		if(Lua_GetServerID() ~= 100 and g_theCurrentChannel == "scene") then
			g_theCurrentChannel = "scene"
		else
			g_theCurrentChannel = "near"
			ChatFrame_SetChannelSel(g_theCurrentChannel, "");
			Chat_Frame_ChannelFrame:Hide()
		end
		
		if(Lua_GetServerID() ~= 100 and g_theCurrentChannel == "paid_world") then
			g_theCurrentChannel = "paid_world"
		else
			g_theCurrentChannel = "near"
			ChatFrame_SetChannelSel(g_theCurrentChannel, "");
			Chat_Frame_ChannelFrame:Hide()
		end
	end	
--- 2014Q1大世界改造，世族功能去除。-- By Godwit. 2014.02.08
---    elseif(force == "close_clan" and g_theCurrentChannel == "clan") then
---		g_theCurrentChannel = "near"
---		ChatFrame_SetChannelSel(g_theCurrentChannel, "");
---	end
	  PushEvent("XUNZONG_CHANGE_CURRENTCHANNEL", g_theCurrentChannel)
	  g_ChatFramePrivate = "";
	  PushEvent("XUNZONG_CHANGE_PRIVATE", g_ChatFramePrivate);
end

-- 选中某一个Tab对应的频道
function Chat_ChangeTabIndex( nIndex )
	Chat_Frame_History:RemoveAllChatString();
	channel_seltab = nIndex;
	Talk:SetCurTab(channel_seltab);
	
	ChatFrame_FixTabConfig()
	
	if channel_config[nIndex] == nil then
		Talk:InsertHistory( nIndex, "" );
	else
		local i = 2;
		local strConfig = "";
		while channel_config[nIndex][i] ~= nil do
			strConfig = strConfig .. tostring(channel_config[nIndex][i]);
			i = i+1;
		end
		Talk:InsertHistory( nIndex, strConfig);
	end

	Chat_Frame_History:ScrollToEnd();

	if(g_CurFlashTab == channel_seltab and channel_seltab > 0)then
		NotFlashTab(g_CurFlashTab);
	end
end

-- 捕捉Tab按钮失败时的操作
-- 解决 TT：47859	【频道】左下方4个频道栏，左键按住一个频道栏标题，拖动到非频道栏标题后松手，频道栏标题改变，内容不变
function Chat_OnTabCaptureLost (nIndex)
	if nIndex ~= channel_seltab then
		Chat_ChangeTabIndex(nIndex);
	end
end

function ChatFrame_CreateTabFinish(tabName,tabCfg, strFlg)
	if(tabName == nil or tabCfg == nil or strFlg == nil) then
		return;
	end

	if(strFlg == "cancel") then
		--channel_tab_total = channel_tab_total - 1;
	elseif(strFlg == "sucess") then
		channel_tab_total = channel_tab_total + 1;
		if(tabName == "") then
			tabName = "自建" .. tostring(channel_tab_total - 5);
		end

		channel_seltab = channel_tab_total-1;
		ChatFrame_ChangeTabConfig(tabCfg);
		channel_config[channel_seltab][1] = tabName;

		--保存配置
		Talk:SaveTab(channel_seltab, tabName, tabCfg);
		ChatFrame_SetTabConfig(channel_seltab);

		ChatFrame_SetTabMouseRButtonHollow(channel_seltab, 0);
		channel_tab[channel_seltab]:Show();
		channel_tab[channel_seltab]:SetCheck(1);
		channel_tab[channel_seltab]:SetText(channel_config[channel_seltab][1]);
		Chat_ChangeTabIndex(channel_seltab);
	end
end

function ChatFrame_ConfigTabFinish(tabName, tabCfg, strFlg)
	if(tabName == nil or tabCfg == nil or strFlg == nil) then
		return;
	end
	if(strFlg == "cancel") then
	elseif(strFlg == "delete") then
		Chat_DestoryTabIndex(channel_seltab);
	elseif(strFlg == "sucess") then
		if(channel_seltab ~= 0) then
			ChatFrame_ChangeTabConfig(tabCfg);

			--保存配置
			Talk:SaveTab(channel_seltab, channel_config[channel_seltab][1], tabCfg);
			ChatFrame_SetTabConfig(channel_seltab);
		end
	end
end

-- 更改聊天页面Tab配置
function ChatFrame_ChangeTabConfig( tabCfg )
	local k = 1;
	for i = 2, table.getn(channel_config[channel_seltab]) do
		if(string.byte(tabCfg, k) == 48) then -- 0
			channel_config[channel_seltab][i] = 0;
		elseif(string.byte(tabCfg, k) == 49) then -- 1
			channel_config[channel_seltab][i] = 1;
		else
			channel_config[channel_seltab][i] = 0;
		end

		k = k+1;
	end
	ChatFrame_PrintTabConfig(channel_seltab);
end

function ChatFrame_FixTabConfig()
	local fix = 0
	if channel_seltab == 3 then
		--同城频道下，只有系统、私聊、队伍、帮会、同盟是可选的
		--其他的都走初始配置
		local _ipRegionConfig = {3,5,6,8,14};
		local r = ChatFrame_GetCityRaw()
		for i, v in ipairs(r) do
			if i ~= 3 and i ~= 5 and i ~= 6 and i ~= 8 and i ~= 14 then
				if channel_config[3][i] ~= r[i] then
					channel_config[3][i] = r[i]
					fix = 1
				end
			end
		end
	end
	if fix == 1 then
		local i = 2
		local strConfig = ""
		while channel_config[channel_seltab][i] ~= nil do
			strConfig = strConfig .. tostring(channel_config[channel_seltab][i]);
			i = i+1;
		end
		Talk:SaveTab( channel_seltab, channel_config[channel_seltab][1], strConfig );
	end
end

-- 删除聊天页面Tab
function Chat_DestoryTabIndex( nIndex )
	if( nIndex <= 5) then
		PushDebugMessage("此频道不可删除");
		return;
	end

	if(channel_tab_total-1 == 4) then
		return;
	end

	channel_tab_total = channel_tab_total - 1;

	-- 向前拷贝配置
	if( channel_tab_total ~= 4 ) then
		local i;
		for i=nIndex, channel_tab_total do
			local k=1;
			while channel_config[i][k] ~= nil and channel_config[i+1][k] ~= nil and i+1<CHANNEL_TAB_MAX do
				channel_config[i][k] = channel_config[i+1][k];
				k = k+1;
			end
			--保存配置
			local xxi = 2;
			local strConfig = "";
			while channel_config[i][xxi] ~= nil do
				strConfig = strConfig .. tostring(channel_config[i][xxi]);
				xxi = xxi+1;
			end

			if(nil ~= channel_config[i][1]) then
				Talk:SaveTab(i, channel_config[i][1], strConfig);
				ChatFrame_SetTabConfig(i);
			end
			--改变文字
			channel_tab[i]:SetText(channel_config[i][1]);
		end

		if(channel_seltab == channel_tab_total) then
			channel_seltab = channel_seltab - 1;
		end

		if(1 < channel_seltab) then
			channel_tab[channel_seltab]:SetText(channel_config[channel_seltab][1]);
			channel_tab[channel_seltab]:SetCheck(1);
		end
	else
		channel_seltab = 0;
		Chat_CommonChk:SetCheck(1);
	end

	-- 隐藏多余的Tab窗体
	for i=channel_tab_total, CHANNEL_TAB_MAX-1 do
		ChatFrame_SetTabMouseRButtonHollow(i, 1);
		channel_tab[i]:Hide();
	end
	Talk:ClearTab(channel_tab_total);

	-- 更新ChatHistory里的内容
	Talk:MoveTabHisQue(nIndex, channel_tab_total);
	Chat_ChangeTabIndex(channel_seltab);
end

function ChatFrame_HandleAccKey( op, msg )
	if( nil == op ) then
		return;
	end

	if(channel_sendhis == 0 and op == "save_old") then
	elseif( op == "shift_up" or op == "shift_down") then
		local txt = Chat_EditBox:GetItemElementsString();
		Talk:SaveOldTalkMsg(g_theCurrentChannel, txt);
		ChatFrame_SetEditBoxTxt(msg);
	elseif( op == "acc_prevchannel") then
		ChatFrame_ChangeCurrentChannel(1); --当前频道的前一频道
	elseif( op == "acc_nextchannel") then
		ChatFrame_ChangeCurrentChannel(-1);	--当前频道的后一频道
	elseif( op == "acc_clearchat" ) then
		ChatFrame_extendRegionTest();
	elseif (op == "acc_chatmod") then
		ChatFrame_ChatMood()
	elseif (op == "acc_face") then
		ChatFrame_SelectFaceMotion()
	end
end

function ChatFrame_ClearSendHis()
	if(1 ~= channel_sendhis2) then
		channel_sendhis = 0;
	end

	channel_sendhis2 = 0;
end

function ChatFrame_ChangeCurrentChannel( dir )
	local newtype, newname = Talk:ChangeCurrentChannel( g_theCurrentChannel, g_theCurrentChannelName, dir );
	ChatFrame_ChannelListChange(newtype, newname);
end

function ChatFrame_ContexMenu_Open( strLink,msgid )
	if(nil == strLink or ChatFrame_IsNameMySelf(strLink)>0) then
		return;
	end

	Talk:ShowContexMenu( strLink,tonumber(msgid) );
end

function ChatFrame_ActSetMessage( strAct, type )

	if(strAct == nil or strAct == "") then
		return;
	end

	if (type <= 0) or (type > 2) then
	  return;
	end

	local strKey = "";
	if ( type == 1 ) then
		strKey = "*" .. strAct;					-- 单人休闲动作
	elseif ( type ==2 ) then
		strKey = "*@" .. strAct;				-- 双人休闲动作（这里不能用"**"，两个'*'作为一个‘*’输出 )
	end

	Talk : SendChatMessage(g_theCurrentChannel, strKey);

end

function ChatFrame_IsNameMySelf( strName )
	if( strName == nil or strName == "") then
		return -1;
	end

	local myselfName = Player:GetName();
	if( myselfName == strName) then
		return 1;
	else
		return -1;
	end
end

function ChatFrame_LoadTabConfig(tabIdx, tabName, tabConfig)
	if(nil == tabIdx or nil == tabName or nil == tabConfig) then
		return;
	end

	local selbak = channel_seltab;

	local tabId = tonumber(tabIdx);
	if(tabId > 0 and tabId < CHANNEL_TAB_MAX) then
		channel_seltab = tabId;
		ChatFrame_ChangeTabConfig(tabConfig);
		channel_config[channel_seltab][1] = tabName;

		ChatFrame_SetTabMouseRButtonHollow(channel_seltab, 0);
		if(channel_seltab == 3) then	--同城频道特殊处理
			channel_tab[channel_seltab]:SetText("同城");
		elseif(channel_seltab == 4) then	--征召频道特殊处理
			channel_tab[channel_seltab]:SetText("征召");
		else
			channel_tab[channel_seltab]:SetText(channel_config[channel_seltab][1]);
		end
		channel_tab[channel_seltab]:Show();
		if(tabId > 3) then channel_tab_total = channel_tab_total + 1; end
		ChatFrame_SetTabConfig( tabId );
	elseif tabId == g_channel_fenping then
		--分屏设置load
		Talk:CreateFenping(tabConfig)
	end

	channel_seltab = selbak;
	
	ChatFrame_FixTabConfig()
end

function ChatFrame_SetTabConfig( tabIdx )
	if(channel_config[tabIdx] ~= nil) then
		local i = 2;
		local strConfig = "";
		while channel_config[tabIdx][i] ~= nil do
			strConfig = strConfig .. tostring(channel_config[tabIdx][i]);
			i = i+1;
		end
		Talk:SetTabCfg(tabIdx, strConfig);
	end
end

function ChatFrame_SetTabMouseRButtonHollow( tabIdx, op )
	if(nil == tabIdx or tabIdx < 3 or tabIdx >= CHANNEL_TAB_MAX) then return end;

	if(0 == tonumber(op)) then
		channel_tab[tabIdx]:SetProperty("MouseRButtonHollow", "False");
	elseif(1 == tonumber(op)) then
		channel_tab[tabIdx]:SetProperty("MouseRButtonHollow", "True");
	end
end

function ChatFrame_HandleMenuBarAction(op,arg,new)

	if(op == "chatbkg") then
		ChatFrame_ChangeChatBkgAlpha(arg);
	elseif(op == "infochannel") then
		ChatFrame_ChannelListChange(arg,new);
	end
end

function ChatFrame_ChannelSelect_ChangePosition(pos)
	Chat_Frame_Channel:SetProperty("AnchorPosition", "x:"..tostring(pos-2).." y:23.0");
end

function ChatFrame_ChangeChatBkgAlpha(val)
	Chat_Frame_HistoryFrame:SetProperty( "Alpha", val );
	Chat_Frame_FenpingFrame:SetProperty( "Alpha", val );
end

function ChatFrame_PrintTabConfig(idx)
	if(idx == nil or idx < 0 or idx > 6) then
		return;
	end

	local strMsg = "ChatTabConfig idx:"..tostring(idx).." config:";
	for i = 2, table.getn(channel_config[idx]) do
		strMsg = strMsg..tostring(channel_config[idx][i]);
	end
end

function Chat_ChatSpeaker_NameLClick()
	--ChatFrame_ChangePrivateName( g_CurSpeakerName );
	if (g_CurSecretType == 1) then
		return;
	end
	ChatFrame_ChangePrivateName( g_CurSpeakerDisplayName );
end
function Chat_ChatSpeaker_NameRClick()
	--if(nil == g_CurSpeakerName or ChatFrame_IsNameMySelf(g_CurSpeakerName)>0) then
	if (g_CurSecretType == 1 ) then
		if (g_CurSecretFlag ~="3") then
			Talk:ShowContexMenu4SecretSpeaker( g_CurSpeakerContex, g_CurSpeakerZoneworldid);
		end
	else
		if(nil == g_CurSpeakerDisplayName or ChatFrame_IsNameMySelf(g_CurSpeakerDisplayName)>0) then
			return;
		end
		--Talk:ShowContexMenu4Speaker( g_CurSpeakerName, g_CurSpeakerContex);
		Talk:ShowContexMenu4Speaker( g_CurSpeakerName, g_CurSpeakerContex, g_CurSpeakerZoneworldid);
	end
end

--创建分屏 added by zhanglei
--strCfg 分屏属性
function ChatFrame_CreateFenping(strCfg)
	ChatFrame_PrepareMove();

	local absFrameHeight = g_MoveCtl.frame:GetProperty("AbsoluteHeight");
	local absFenpingHeight = g_FenpingMinHeight
	local absHistoryHeight = g_MoveCtl.history:GetProperty("AbsoluteHeight");
	local absCheckHeight = g_MoveCtl.check:GetProperty("AbsoluteHeight");
	local absToolBarHeight_1 = g_MoveCtl.toolbar1:GetProperty("AbsoluteHeight");
	local absToolBarHeight_2 = g_MoveCtl.toolbar2:GetProperty("AbsoluteHeight");
	local absToolBarHeight = absToolBarHeight_1 + absToolBarHeight_2
	local absSpeakerHeight = g_MoveCtl.speaker:GetProperty("AbsoluteHeight")

	g_MoveCtl.fenping:Show()
	--fenping
	local udimStr_fenping = string.format("{%f,%f}", 0.000000, absFenpingHeight );
	g_MoveCtl.fenping:SetProperty("UnifiedHeight", udimStr_fenping );
	udimStr_fenping= string.format("{%f,%f}", 1.000000, -(absToolBarHeight + absFenpingHeight));
	g_MoveCtl.fenping:SetProperty("UnifiedYPosition", udimStr_fenping);
	--frame
	if absFrameHeight + absFenpingHeight > g_MaxFrameHeight then
		--frame
		g_MoveCtl.frame:SetProperty("AbsoluteHeight", g_MaxFrameHeight );
		local udimStr_frame= string.format("{%f,%f}", 1.000000, -(g_MaxFrameHeight + g_MoveUpHeight));
		g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
	else
		--frame
		g_MoveCtl.frame:SetProperty("AbsoluteHeight", absFrameHeight + absFenpingHeight + g_Spin );
		local udimStr_frame= string.format("{%f,%f}", 1.000000, -(absFrameHeight + absFenpingHeight + g_Spin + g_MoveUpHeight));
		g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
	end
	--History
	local other_Height = absSpeakerHeight + absCheckHeight + absFenpingHeight + absToolBarHeight + g_Spin
	local udimStr_history = string.format("{%f,%f}", 1.000000, -other_Height);
	g_MoveCtl.history:SetProperty("UnifiedHeight" ,udimStr_history)

	ChatFrame_FenpingCreateConfig(strCfg);

	Chat_Frame_History:ScrollToEnd();
	Chat_Frame_Fenping:ScrollToEnd();

	local minHeight = tonumber(Chat_Chat_ScaleBtn:GetProperty("MiniHeight"))
	Chat_Chat_ScaleBtn:SetProperty("MiniHeight" , tostring(minHeight + g_FenpingMinHeight + g_Spin) )
end

--分屏创建的时候设置的保存，历史数据的写入
function ChatFrame_FenpingCreateConfig(tabCfg)
		local tabName = "FP";
		local old_channel = channel_seltab;
		channel_seltab = g_channel_fenping;
		ChatFrame_ChangeTabConfig(tabCfg);
		channel_config[channel_seltab][1] = tabName;

		--保存配置
		Talk:SaveTab(channel_seltab, tabName, tabCfg);
		ChatFrame_SetTabConfig(channel_seltab);

		ChatFrame_AddFenpingMsg(channel_seltab);

		channel_seltab = old_channel;
end

-- 分屏对历史数据的处理
-- 将历史信息显示到分屏
function ChatFrame_AddFenpingMsg(nIndex)
	Chat_Frame_Fenping:RemoveAllChatString();

	if channel_config[nIndex] == nil then
		Talk:InsertHistory( nIndex, "" );
	else
		local i = 2;
		local strConfig = "";
		while channel_config[nIndex][i] ~= nil do
			strConfig = strConfig .. tostring(channel_config[nIndex][i]);
			i = i+1;
		end
		Talk:InsertHistory( nIndex, strConfig);
	end

	Chat_Frame_Fenping:ScrollToEnd();
end
--设置分屏属性 added by zhanglei
--strCfg 分屏属性
function ChatFrame_CloseFenping(strCfg)
	ChatFrame_PrepareMove();

	--先关闭分屏
	g_MoveCtl.fenping:Hide();

	local absFrameHeight = g_MoveCtl.frame:GetProperty("AbsoluteHeight");
	local absFenpingHeight = g_MoveCtl.fenping:GetProperty("AbsoluteHeight");
	local absHistoryHeight = g_MoveCtl.history:GetProperty("AbsoluteHeight");
	local absCheckHeight = g_MoveCtl.check:GetProperty("AbsoluteHeight");
	local absToolBarHeight_1 = g_MoveCtl.toolbar1:GetProperty("AbsoluteHeight");
	local absToolBarHeight_2 = g_MoveCtl.toolbar2:GetProperty("AbsoluteHeight");
	local absToolBarHeight = absToolBarHeight_1 + absToolBarHeight_2
	local absSpeakerHeight = g_MoveCtl.speaker:GetProperty("AbsoluteHeight")


	--frame
	g_MoveCtl.frame:SetProperty("AbsoluteHeight", absFrameHeight - absFenpingHeight - g_Spin );
	local udimStr_frame= string.format("{%f,%f}", 1.000000, -(absFrameHeight - absFenpingHeight - g_Spin + g_MoveUpHeight));
	g_MoveCtl.frame:SetProperty("UnifiedYPosition", udimStr_frame);
	--History
	local other_Height = absSpeakerHeight + absCheckHeight + absToolBarHeight
	local udimStr_history = string.format("{%f,%f}", 1.000000, -other_Height);
	g_MoveCtl.history:SetProperty("UnifiedHeight" ,udimStr_history)

	Talk:ClearTab(g_channel_fenping);

	-- 更新ChatHistory里的内容
	Talk:ClearFenpingHisQue();
	Chat_Frame_History:ScrollToEnd();

	local minHeight = tonumber(Chat_Chat_ScaleBtn:GetProperty("MiniHeight"))
	Chat_Chat_ScaleBtn:SetProperty("MiniHeight" , tostring(minHeight - g_FenpingMinHeight - g_Spin) )
end

--改变分屏显示设置
function ChatFrame_ConfigFenping(tabCfg)
	if(tabCfg == nil ) then
		return;
	end
	local old_channel = channel_seltab;
	channel_seltab = g_channel_fenping --分屏ID
	ChatFrame_ChangeTabConfig(tabCfg);

	--保存配置
	Talk:SaveTab(channel_seltab, channel_config[channel_seltab][1], tabCfg);
	ChatFrame_SetTabConfig(channel_seltab);

	channel_seltab = old_channel;
end

function ChatFrame_OpenFenpingDlg(isFenpingOpen)
	if tonumber(isFenpingOpen) == 0 then
		Talk:OpenFenpingConfigDlg("");
	else
		-- 获得当前配置
		local i = 2;
		local strConfig = "";
		while channel_config[g_channel_fenping][i] ~= nil do
			strConfig = strConfig .. tostring(channel_config[g_channel_fenping][i]);
			i = i+1;
		end
		Talk:OpenFenpingConfigDlg(strConfig);
	end
end

function ChatFrame_PrepareBtnCtl()
	g_ChatBtn = {
					ime		= Chat_Chat_IME,
					color	= Chat_Chat_LetterColor,
					face	= Chat_Chat_Face,
					action	= Chat_Chat_Action,
					pingbi	= Chat_Chat_Screen,
					create	= Chat_Chat_User,
					config	= Chat_Chat_Config,
					select	= Chat_ChannelSelecter,
				};
end

function ChatFrame_GetBtnScreenPosX(btn)
	ChatFrame_PrepareBtnCtl();
	if btn == "ime" or btn == "color" or btn == "face" or btn == "action" then
		local barxpos = Chat_Frame:GetProperty("AbsoluteXPosition");
		local barmxpos = Chat_ToolBar:GetProperty("AbsoluteXPosition");
		local barmmxpos	= Chat_Button_LeftFrame:GetProperty("AbsoluteXPosition")
		local btnxpos = g_ChatBtn[btn]:GetProperty("AbsoluteXPosition");
		return barxpos + btnxpos + barmxpos + barmmxpos;
	else
		local barxpos = Chat_Frame:GetProperty("AbsoluteXPosition");
		local barmxpos = Chat_Button_ChatFrame:GetProperty("AbsoluteXPosition");
		local barmmxpos	= Chat_Button_Chat:GetProperty("AbsoluteXPosition")
		local btnxpos = g_ChatBtn[btn]:GetProperty("AbsoluteXPosition");
		return barxpos + btnxpos + barmxpos + barmmxpos;
	end
end
--点击保存聊天记录
function ChatFrame_SaveTabTalkHistory()
	Talk:SaveChatHistory(channel_seltab);
end
--点击屏蔽按钮
function ChatFrame_PingBi()
	Talk:ShowPingBi(ChatFrame_GetBtnScreenPosX("pingbi"));
end
--点击用户自定义频道
function ChatFrame_CreateTab()
	if(channel_tab_total+1 > CHANNEL_TAB_MAX) then
		PushDebugMessage("不能创建更多频道");
	else
		Talk:CreateTab(ChatFrame_GetBtnScreenPosX("create"));
	end
end
--点击设置
function ChatFrame_ConfigTab()
	if(channel_seltab == 0 or channel_seltab == 1 ) then
		PushDebugMessage("此频道不能配置");
		return;
	end
	if ( channel_seltab == 4 ) then
		PushDebugMessage("#{ZZDY_130131_51}");
		return;
	end
	-- 获得当前配置
	local i = 2;
	local strConfig = "";
	while channel_config[channel_seltab][i] ~= nil do
		strConfig = strConfig .. tostring(channel_config[channel_seltab][i]);
		i = i+1;
	end
	ChatFrame_PrintTabConfig(channel_seltab);
	-- 通知程序开始配置
	Talk:ConfigTab( channel_config[channel_seltab][1],strConfig,ChatFrame_GetBtnScreenPosX("config"));
end

--点击分屏
function ChatFrame_Open_Fenping_Config()
	local isFenpingOpen = Talk:IsFenpingOpen()
	if tonumber(isFenpingOpen) == 0 then
		Talk:OpenFenpingConfigDlg("");
	else
		-- 获得当前配置
		local i = 2;
		local strConfig = "";
		while channel_config[g_channel_fenping][i] ~= nil do
			strConfig = strConfig .. tostring(channel_config[g_channel_fenping][i]);
			i = i+1;
		end
		Talk:OpenFenpingConfigDlg(strConfig);
	end
end
--点击增加高度
function ChatFrame_AskFrameSizeUP()
	ChatFrame_MoveCtl(1);
end
--点击减少高度
function ChatFrame_AskFrameSizeDown()
	ChatFrame_MoveCtl(-1);
end
--点击增加宽度
function ChatFrame_AskFrameWidthUP()
	ChatFrame_WidthCtl(1);
end
--点击减少宽度
function ChatFrame_AskFrameWidthDown()
	ChatFrame_WidthCtl(-1);
end
--点击什么玩意
function ChatFrame_extendRegionTest()
	Chat_Frame_History:ExtendClearRegion();
end
--点击字体颜色
function ChatFrame_SelectTextColor()
	local yPos = Chat_Frame:GetProperty("AbsoluteYPosition")
	yPos = yPos + Chat_ToolBar:GetProperty("AbsoluteYPosition")
	yPos = yPos + Chat_Button_LeftFrame:GetProperty("AbsoluteYPosition")
	yPos = yPos - 120
	Talk:SelectTextColor("select", ChatFrame_GetBtnScreenPosX("color") , yPos);
end
--点击表情
function ChatFrame_SelectFaceMotion()
	local yPos = Chat_Frame:GetProperty("AbsoluteYPosition")
	yPos = yPos + Chat_ToolBar:GetProperty("AbsoluteYPosition")
	yPos = yPos + Chat_Button_LeftFrame:GetProperty("AbsoluteYPosition")
	yPos = yPos - 310
	Talk:SelectFaceMotion("select", ChatFrame_GetBtnScreenPosX("face") , yPos);
end
--点击动作
function ChatFrame_ChatMood()
	Talk:ShowChatMood(ChatFrame_GetBtnScreenPosX("action"));
end
--点击频道选择
function ChatFrame_ChannelSelect()
	ChatFrame_ChannelSelect_ChangePosition(ChatFrame_GetBtnScreenPosX("select"));
	Chat_Frame_ChannelFrame:Show();
	
	local nChannelNum = Talk:GetChannelNumber();
	Chat_Frame_Channel:ClearAllChannel();
	
	m_UserIndex[1] = 0
	m_UserIndex[2] = 0
	m_UserIndex[3] = 0
	local channelIndex = 0
	local i=1;
	local FoundPrv=-1;
	while i<=nChannelNum do
		local strChannelType, strChannelName = Talk:GetChannel(i-1);
		if(strChannelType == "-" or CHANNEL_DATA[strChannelType] == nil) then
			return;
		end

		if(strChannelType ~= "private") then
			Chat_Frame_Channel:AddChannel(strChannelType, CHANNEL_DATA[strChannelType][1], strChannelName,false);
			channelIndex = channelIndex + 1
		else
			FoundPrv = i-1;
		end

		i = i+1;
	end
	-- 私聊对象列表加入，todo_yangjun
	if(-1 ~= FoundPrv) then
		local strPrvType, strPrvName1, strPrvName2, strPrvName3 = Talk:GetChannel(FoundPrv);
		if(CHANNEL_DATA[strPrvType] == nil) then
			return;
		end
		if(strPrvName1 ~= "" and strPrvName1 ~= nil) then
			channelIndex = channelIndex + 1
			m_UserIndex[1] = channelIndex
			Chat_Frame_Channel:AddChannel(strPrvType, CHANNEL_DATA[strPrvType][1], strPrvName1,true);
		end
		if(strPrvName2 ~= "" and strPrvName2 ~= nil) then
			channelIndex = channelIndex + 1
			m_UserIndex[2] = channelIndex
			Chat_Frame_Channel:AddChannel(strPrvType, CHANNEL_DATA[strPrvType][1], strPrvName2,true);
		end
		if(strPrvName3 ~= "" and strPrvName3 ~= nil) then
			channelIndex = channelIndex + 1
			m_UserIndex[3] = channelIndex
			Chat_Frame_Channel:AddChannel(strPrvType, CHANNEL_DATA[strPrvType][1], strPrvName3,true);
		end
	end
end
--设置选择的频道
function ChatFrame_SetChannelSel(channel, channelname)
	if(CHANNEL_DATA[channel] == nil) then
		return;
	end
	Chat_ChannelSelecter:SetProperty("NormalImage", CHANNEL_DATA[channel][1]);
	Chat_ChannelSelecter:SetProperty("HoverImage", CHANNEL_DATA[channel][2]);
	Chat_ChannelSelecter:SetProperty("PushedImage", CHANNEL_DATA[channel][3]);
end

function ChatFrame_ChannelListDel()

	local sPos,ePos = string.find(arg0, "_delbtn_")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	
	if nIndex > 0 then
	
		for i = 1 ,3 do
			
			if nIndex == m_UserIndex[i] then
				local bChange , newtype, newname = Talk:DelUserByIndex(g_theCurrentChannel, g_theCurrentChannelName ,i - 1)	
				Chat_Frame_ChannelFrame:Hide()
				
				if bChange == 1 then				
					ChatFrame_ChannelListChange(newtype, newname)
				end
			end
			
		end
	end

end

-- 发送双人聊天动作信息
function ChatFrame_DoubleChatActionMessageSend(bEnable, talker)
	-- 找不到说话者
	if (talker == "") then
		return
	end

	-- 说话的不是自己
	local myName = Player:GetName()
	if (myName ~= talker) then
		return
	end

	-- 对方开启了聊天动作设置
	if (bEnable == 1) then
		local prvname,perColor = Talk : SendChatMessage(g_theCurrentChannel, g_ChatActionTxt);
		g_ChatActionTxt = "";

		if (nil == prvname ) then prvname = ""; end
		if( nil == perColor ) then perColor = ""; end
		local str = "";
		if (prvname == "")then
			str = str..perColor;
		else
			str = str.."/"..prvname.." "..perColor;
		end

		if("" ~= str) then
			ChatFrame_SetEditBoxTxt(str);		-- 私聊
		else
			ChatFrame_SetEditBoxTxt("");			-- 非私聊
		end
	end

end
--空
function ChatFrame_TextAccepted()

	-- 得到输入的字符串
	local txt = Chat_EditBox:GetItemElementsString();

	-- 预先判断输入字符串是不是有效的双人聊天动作
	local bChatAction = Talk : IsValidChatActionString(g_theCurrentChannel, txt);
	local bChatActionSingle = Talk : IsValidChatActionString_Single(g_theCurrentChannel, txt);

	-- 有效的双人聊天动作
	if (bChatAction == 1) then
		-- 询问对方是否可以做动作（暂不发送聊天信息字符串，也不记录历史聊天记录）
		g_ChatActionTxt = txt							-- 先把聊天动作字符串记录下来
		ChatFrame_SetEditBoxTxt("")			-- 清空编辑框
		Talk : CanDoDoubleAction_Bar()

	-- 无效的双人聊天动作
	elseif (bChatAction == 2) then
		-- 不发送聊天信息字符串，也不记录历史聊天记录，只弹提示信息
		g_ChatActionTxt = ""			-- 清空聊天动作字符串
		ChatFrame_SetEditBoxTxt("")			-- 清空编辑框

	-- 单人聊天动作或者普通聊天消息
	elseif (bChatAction == 0) then
	
		if bChatActionSingle == 1 or bChatActionSingle == 0 then --有效的单人

			-- 发送普通聊天信息
			local prvname,perColor = Talk : SendChatMessage(g_theCurrentChannel, txt);
			if(nil == prvname ) then prvname = ""; end
			if(nil == perColor ) then perColor = ""; end
			local str = "";
			if(prvname == "")then
				str = str..perColor;
			else
				str = str.."/"..prvname.." "..perColor;
			end

			if("" ~= str) then
				ChatFrame_SetEditBoxTxt(str);		-- 私聊
			else
				ChatFrame_SetEditBoxTxt("");			-- 非私聊
			end
		else
			-- 不发送聊天信息字符串，也不记录历史聊天记录，只弹提示信息
			g_ChatActionTxt = ""			-- 清空聊天动作字符串
			ChatFrame_SetEditBoxTxt("")		
		end
	end
end

function ChatFrame_SetEditBoxTxt(txt)
	Chat_EditBox:SetProperty("ClearOffset", "True");
	Chat_EditBox:SetItemElementsString(txt);
	Chat_EditBox:SetProperty("CaratIndex", 1024);
end

function ChatFrame_InputLanguage_Changed()

	local langId = Talk:GetCurInputLanguage();

	if(g_InputLanguageIcon[langId] == nil)then
		Chat_Chat_IME:SetProperty("NormalImage", g_InputLanguageIcon[1]);
		Chat_Chat_IME:SetProperty("HoverImage", g_InputLanguageIcon[1]);
		Chat_Chat_IME:SetProperty("PushedImage", g_InputLanguageIcon[1]);
	else
		Chat_Chat_IME:SetProperty("NormalImage", g_InputLanguageIcon[langId]);
		Chat_Chat_IME:SetProperty("HoverImage", g_InputLanguageIcon[langId]);
		Chat_Chat_IME:SetProperty("PushedImage", g_InputLanguageIcon[langId]);
	end
end

function ChatFrame_SelectColorFaceFinish(act, strResult)
	if(act == "sucess") then
		local txt = Chat_EditBox:GetItemElementsString();
		local facetxt = txt .. strResult;
		ChatFrame_SetEditBoxTxt(facetxt);
	end
end

function ChatFrame_JoinItemElementFailure()
	PushDebugMessage("添加物品信息失败。");
end

function ChatFrame_ItemElementFull()
	PushDebugMessage("不能添加更多物品信息。");
end

function ChatFrame_OpenSpeakerBox()
	local sceneLogicID = GetSceneID()
	if sceneLogicID == 842 or sceneLogicID == 868 or sceneLogicID == 937 then
		PushDebugMessage("#{WWSJ_230213_101}");
		return
	end
	Talk:OpenSpeakerDlg(0)
end

function ChatFrame_MouseEnter()
	Chat_CheckBox_Frame:Show()
	local _,_,_,_,_,_,_,_,_,f10,_,_,_,_,_,_,_,_,_,_,_,_,_,_ = SystemSetup:GameGetData();
	local alphaStr = string.format("%f" , f10 )
	Chat_Frame_HistoryFrame:SetProperty("Alpha" , alphaStr)
	Chat_Frame_FenpingFrame:SetProperty("Alpha" , alphaStr)
end

function ChatFrame_MouseLeave()
	Chat_CheckBox_Frame:Hide()
	local _,_,_,_,_,_,_,_,_,f10,_,_,_,_,_,_,_,_,_,_,_,_,_,_ = SystemSetup:GameGetData();
	local alphaStr = string.format("%f" , f10 / 2 )
	Chat_Frame_HistoryFrame:SetProperty("Alpha" , alphaStr)
	Chat_Frame_FenpingFrame:SetProperty("Alpha" , alphaStr)
end
