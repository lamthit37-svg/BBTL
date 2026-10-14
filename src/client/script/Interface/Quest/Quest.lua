local QUEST_STATE_EVENTLIST 				= 1;
local QUEST_STATE_MISSON_INFO 			= 2;
local QUEST_STATE_CONTINUE_DONE 		= 3;
local QUEST_STATE_CONTINUE_NOTDONE 	= 4;
local QUEST_STATE_AFTER_CONTINUE		= 5;
local g_nQuestState = 0;
local g_nRewardItemID = 0;
local g_nLastClickTime = 0;

local bBeingRadio = 0;
local bRadioSelect = 0;

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

local g_Object = -1;

--添加图标index到19时需要修改程序AddOptionElement::AddOptionElement
local Icon_Preference = {}
local g_Quest_Frame_UnifiedXPosition;
local g_Quest_Frame_UnifiedYPosition;
local g_CurActFlashType = 0
local g_ShowRect = 0;
local g_SHowNewNPCchat = 0;

local g_FuQi_Item={
[1]={id = 38001303},
[2]={id = 38001304},
[3]={id = 38001305},
[4]={id = 38001306},
}

--门派装备类型定义
--少林0   明教1   丐帮2   武当3   峨眉4   星宿5   天龙6  天山7  逍遥8   慕容10 唐门11 恶人谷15
local MEIPAI_WAIGONG = {0,1,2,7,13,14}											--外攻门派：少林、明教、丐帮、天山、桃花岛 menpai15 mptodo
local MEIPAI_NEIGONG = {3,4,5,6,8,10,11,12,15}									--内攻门派：武当、慕容、逍遥、峨眉、星宿、天龙、唐门、鬼谷
local MEIPAI_DAOFUQIANGBANG = {0,1,2}							--刀斧、枪棒门派：少林、明教、丐帮
local MEIPAI_DANDUANSHUANGDUAN = {3,4,5,10}			--单短、双短门派：武当、慕容、峨眉、星宿
local MEIPAI_SHANHUAN = {6,7,8}											--扇、环门派：天山、逍遥、天龙
local MEIPAI_NU = {11}	 --还跟跟着任务添加逻辑
local MEIPAI_ZHANG = {12}	 --还跟跟着任务添加逻辑 --guigu
local MEIPAI_XIAOJIAN = {13} --还跟跟着任务添加逻辑 --桃花岛 
local MEIPAI_2HUAN = {14} 
local MEIPAI_ERENGUWUQI = {15} --恶人谷会新增一个武器类型



function Quest_PreLoad()
	this:RegisterEvent("QUEST_EVENTLIST",true);
	this:RegisterEvent("QUEST_INFO",true);
	this:RegisterEvent("QUEST_CONTINUE_DONE",true);
	this:RegisterEvent("QUEST_CONTINUE_NOTDONE",true);
	this:RegisterEvent("QUEST_AFTER_CONTINUE",true);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("TOGLE_SKILLSTUDY",false);
	this:RegisterEvent("TOGLE_BANK",false);
	this:RegisterEvent("TOGLE_BIGBANK",false);
	this:RegisterEvent("REPLY_MISSION",false);
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_ACCOUNT_SAFE",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PS_SHOP_CLOSE",false)
	this:RegisterEvent("NOTIFY_POP_UITIP",false)
	this:RegisterEvent("OPEN_FUQICHENGHAO",true)
	this:RegisterEvent("OPEN_LEAGUEINFO_HELP",true)
	this:RegisterEvent("OPEN_BIEYEALLHELP",true)
	this:RegisterEvent("OPEN_ELECTION_HELP",true)
	this:RegisterEvent("CORPS_INVITE_NPCTALK_2018",true)
	this:RegisterEvent("CORPS_INVITE_NPCTALK2_2018",true)
	this:RegisterEvent("OPEN_ZHOUNIANYUAN_HELP",true)
	this:RegisterEvent("OPEN_XUANZHANCD_HELP",true)
	this:RegisterEvent("OPEN_JFMZ_HELP",true)
	this:RegisterEvent("OPEN_SHANGFENG_HELP",true)
	this:RegisterEvent("OPEN_HUODONGTEXT_HELP",true)
	this:RegisterEvent("OPEN_NATIONAL_TREE_HELP",true)
	this:RegisterEvent("OPEN_NATIONAL_FUND_HELP",true)
	this:RegisterEvent("LAYUE_SIRILI_HELP",true)
	this:RegisterEvent("LAYUE_BZSS_HELP",true)
	this:RegisterEvent("GUISHI_NPCSHOP_HELP",true)
	this:RegisterEvent("CCSHOP_HELP",true)	
	this:RegisterEvent("SPRINGGUIDEMISSION_JIXIANGFUHELP",true)	-- 2018Q4春节引导任务
	this:RegisterEvent("SPRINGGUIDEMISSION_CAIDANHELP",true)	-- 2018Q4春节引导任务
	this:RegisterEvent("DUANWU_DUIHUAN_HELP",true)	
	this:RegisterEvent("ZNQ_DRAW_HELP",true)	
	this:RegisterEvent("GQHYCHOUJIANG_HELP",true)	-- 2019国庆稳活跃抽奖--祈福界面帮助
	this:RegisterEvent("DUANWU_BIDDING_HELP_I",true)
	this:RegisterEvent("DUANWU_BIDDING_HELP_II",true)
	this:RegisterEvent("DUANWU_BIDDING_HELP_III",true)
	this:RegisterEvent("SRPING_FESTIVAL_BIDDING_HELP",true)
	this:RegisterEvent("SRPING_FESTIVAL_BIDDINGLIST_HELP",true)
	this:RegisterEvent("QUEST_HELP_MSG",true)
	this:RegisterEvent("BIANJING_BIDDINGLIST_HELP",true)
	this:RegisterEvent("BIANJING_BIDDING_TIME_HELP",true)
	this:RegisterEvent("BIANJING_BIDDINGLIST_HELP_TOKEN",true)
	this:RegisterEvent("LONGSIGNIN_OPEN_HELP",true)
	this:RegisterEvent("CAIQIUENTER_OPEN_HELP",true)
	this:RegisterEvent("ETJFUBEN_2022_HELP",true)
	this:RegisterEvent("ETJFUBEN_2022_RESULT",true)
	this:RegisterEvent("XRZPVP_UI_OPENGOTOHELP",true)
	this:RegisterEvent("QUEST_HELPINFO",true)
	this:RegisterEvent("OPEN_2606S_HELP",true)
end

function Quest_OnLoad()

	Icon_Preference[30] = 2
	Icon_Preference[26] = 3
	Icon_Preference[24] = 4
	Icon_Preference[4] = 5
	Icon_Preference[2] = 6
	Icon_Preference[29] = 7
	Icon_Preference[28] = 8
	Icon_Preference[22] = 9
	Icon_Preference[3] = 10
	Icon_Preference[25] = 11
	Icon_Preference[1] = 13
	Icon_Preference[20] = 14
	Icon_Preference[27] = 15
	Icon_Preference[23] = 16
	Icon_Preference[21] = 17   --15-17不是对话框绑定的图标，优先级置为最后
	Icon_Preference[19] = 18
	Icon_Preference[5] = 19
	Icon_Preference[14] = 24
	Icon_Preference[6] = 20
	Icon_Preference[7] = 21
	Icon_Preference[12] = 22
	Icon_Preference[10] = 23
	Icon_Preference[18] = 25
	Icon_Preference[9] = 26
	Icon_Preference[11] = 27
	Icon_Preference[8] = 28
	Icon_Preference[15] = 32
	Icon_Preference[13] = 1
	Icon_Preference[16] = 32
	Icon_Preference[17] = 32
	Icon_Preference[31] = 12
	Icon_Preference[32] = -1
	Icon_Preference[33] = -2
	Icon_Preference[34] = 0
	g_Quest_Frame_UnifiedXPosition	= Quest_Frame:GetProperty("UnifiedXPosition");
	g_Quest_Frame_UnifiedYPosition	= Quest_Frame:GetProperty("UnifiedYPosition");

end

--=========================================================
-- 事件处理
--=========================================================
function Quest_OnEvent(event)
	local objCared = tonumber(arg0);

	--第一次和npc对话，得到npc所能激活的操作
	if(event == "QUEST_EVENTLIST") then
		--关心NPC
		BeginCareObject_Quest(objCared)
		Quest_Open();
		QuestGreeting_Desc:ClearAllElement();
		Quest_EventListUpdate();


	--在接任务时，看到的任务信息
	elseif(event == "QUEST_INFO") then
		--关心NPC
		BeginCareObject_Quest(objCared)
		Quest_Open();
		QuestGreeting_Desc:ClearAllElement();
		Quest_QuestInfoUpdate()


	--接受任务后，再次和npc对话，所得到的任务需求信息，(任务完成)
	elseif(event == "QUEST_CONTINUE_DONE") then
		QuestGreeting_Desc:ClearAllElement();
		Quest_MissionContinueUpdate(1);

	--接受任务后，再次和npc对话，所得到的任务需求信息，(任务未完成)
	elseif(event == "QUEST_CONTINUE_NOTDONE") then
		QuestGreeting_Desc:ClearAllElement();
		Quest_MissionContinueUpdate(0);

		--关心NPC
		BeginCareObject_Quest(objCared)

	--点击“继续之后”，奖品选择界面
	elseif(event == "QUEST_AFTER_CONTINUE") then
		--关心NPC
		Quest_Open();
		QuestGreeting_Desc:ClearAllElement();
		Quest_MissionRewardUpdate();

	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Quest_Close();

			--取消关心
			StopCareObject_Quest(objCared);
		end

	elseif (event == "TOGLE_SKILLSTUDY") then

		Quest_Close();

		--取消关心
		StopCareObject_Quest(objCared);

	elseif (event == "TOGLE_BANK") then

		Quest_Close();

		--取消关心
		StopCareObject_Quest(objCared);
	elseif (event == "TOGLE_BIGBANK") then
		Quest_Close();

		--取消关心
		StopCareObject_Quest(objCared);
	elseif ( event == "REPLY_MISSION" ) then
		Quest_Close();

	-- 播放音效
	elseif ( event == "UI_COMMAND" ) then
		local nUIIdx = tonumber(arg0)
		if tonumber(arg0) == 123 then
			PlaySoundEffect();
		elseif tonumber(arg0) == 124 then
			PlayBackSound()
		elseif tonumber(arg0) == 1000 then
			Quest_Close();
		elseif tonumber(arg0) == 8893837 then
			Quest_Close();
		elseif tonumber(arg0) == 0147005 then
			Quest_Close();
		elseif tonumber(arg0) == 0147006 then
			Quest_Close();
        elseif tonumber(arg0) == 89324102 then
            local npcid = Get_XParam_INT(0)
            local which = Get_XParam_INT(1)
            OpenUrl_JNH(which);
        elseif tonumber(arg0) == 89329902 then
            local npcid = Get_XParam_INT(0)
            OpenUrl_dfsjc();
        elseif tonumber(arg0) == 89329903 then
            local npcid = Get_XParam_INT(0)
            OpenUrl_dfsjc_always();
        elseif tonumber(arg0) == 89331202 then
            local npcid = Get_XParam_INT(0)
            OpenUrl_DFSZB();
        elseif tonumber(arg0) == 20090715 then
            OpenUrl();
		elseif tonumber(arg0) == 20091019 then
			OpenUrl_BBHJ();
		elseif tonumber(arg0) == 2015081112 then--拉矿帮助
			local msg = Get_XParam_STR( 0 )
			QuestGreeting_Desc:ClearAllElement()
			Quest_ShowCarriageHelp(msg)
		elseif tonumber(arg0) == 20100728 then--侠义之心显示加的代码
			Quest_ShowMonsterInfo();--Get_XParam_INT(0)

		elseif tonumber(arg0) == 20101024 then--用于打开链接 lichengjie
			OpenUrl_WJHL_GUANWANG();
		elseif tonumber(arg0) == 20130418 then
			OpenUrl_ChongLouBuChang();
		elseif tonumber(arg0) == 20121227 then -- [URL]畅游VIP年末回馈领玄灵丹
			OpenURL_ChangYouVIPHuiKui();
		elseif tonumber(arg0) == 502011 then
			QuestGreeting_Desc:ClearAllElement()
			Quest_OpenSongliaoStatistic()
		elseif tonumber(arg0) == 5020102  then
			QuestGreeting_Desc:ClearAllElement()
			Quest_OpenSongliaoTips()
		elseif tonumber(arg0) == 20100929 then --【易容百变赢豪礼】
			OpenUrl_YRBBYHL();
		elseif tonumber(arg0) == 339096 then--用于打开网银活动官网
			OpenUrl_WANGYINCHONGZHI()
		elseif tonumber(arg0) == 20101110 then	--【by cys】打开金卡专题网站
			OpenUrl_CYJINKA();
		elseif tonumber(arg0) == 20101121 then--2011新年钟声
			PlayEffectSound();
		elseif tonumber(arg0) == 20110118 then--龙门客栈官网论坛.网通
			OpenUrl_FOR_GWLT()
		elseif tonumber(arg0) == 20110122 then--龙门客栈官网论坛.电信
			OpenUrl_FOR_GWLT_DX()
		elseif tonumber(arg0) == 20110607 then	--打开星级用户连接网站 VIP感恩回馈
			OpenUrl_FOR_VIPGNHK();
		elseif tonumber(arg0) == 20110801 then --打开争霸赛官网
			OpenUrl_ZBS_GWLT()
		elseif tonumber(arg0) == 20120209 then --打开2012争霸赛官网
			OpenUrl_2012ZBS_GWLT()
		elseif tonumber(arg0) == 20140528 then --打开17173直播间
			Helper:GotoHelper("Vedio17173" );
		elseif nUIIdx == 20111208 then         --携手<大魔术师>活动官网
        	GameProduceLogin:OpenURL(GetWeblink("WEB_WTLBMS"))
		elseif nUIIdx == 20120106 then			--打开天龙五周年活动页面
			GameProduceLogin:OpenURL(GetWeblink("WEB_FIVEYEAR_HUODONG"))
		elseif nUIIdx == 20120214 then
			OpenUrl_ROSE_VD()
		elseif tonumber(arg0) == 20120324 then
		    GameProduceLogin:OpenURL(GetWeblink("WEB_ZZGB"))
		elseif tonumber(arg0) == 20120424 then--用于打开链接
			--网页系统升级,旧.jsp结尾的网址需要换新
			--GameProduceLogin:OpenURL(GetWeblink("WEB_GWHLHD"))
		elseif tonumber(arg0) == 20120816 then
            GameProduceLogin:OpenURL(GetWeblink("WEB_QIXI"))
		elseif tonumber(arg0) == 20120909 then
			local weblink = DataPool : Lua_GetHMWeblink()
			GameProduceLogin:OpenURL(weblink)
		elseif tonumber(arg0) == 890047 then
			local weblink = DataPool : Lua_GetMSWebLink()
			GameProduceLogin:OpenURL(weblink)
		elseif tonumber(arg0) == 20130305 then	--了解官网活动详情
			GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANYUE_1"))
		elseif tonumber(arg0) == 20130306 then	--淘宝直购贴身密保
			GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANYUE_2"))
		elseif tonumber(arg0) == 20130626 then --微信达人活动
			OpenUrl_WEIXINDAREN()
		elseif tonumber(arg0) == 890186 then  --手机认证礼包
			--网页系统升级,旧.jsp结尾的网址需要换新
			--GameProduceLogin:OpenURL(GetWeblink("WEB_PHONEGIFT"))
		elseif tonumber(arg0) == 20130814 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_LOSER_SATISFACTION"))
		elseif tonumber(arg0) == 890688 then  --天龙期权股
			GameProduceLogin:OpenURL(GetWeblink("WEB_QQGFHL"))
		elseif tonumber(arg0) == 20131025 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_QQGFHL"))
		elseif tonumber(arg0) == 890607 then --老玩家到新服礼包设计 打开网页
			GameProduceLogin:OpenURL(GetWeblink("WEB_OLDPLAYERGIFT"))
		elseif tonumber(arg0) == 20140425 then--用于打开GM获奖网页的链接
			GameProduceLogin:OpenURL(GetWeblink("WEB_HUIHUISTORY"))
		elseif tonumber(arg0) == 20150316 then--用于打开美女活动网页的链接
			GameProduceLogin:OpenURL(GetWeblink("WEB_MEINVHUODONG"))
		elseif tonumber(arg0) == 20150518 then--打开雄霸天下总决赛介绍界面
			GameProduceLogin:OpenURL(GetWeblink("WEB_XBTX_ZJS"))	
		elseif tonumber(arg0) == 20190422 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_XBTX_ZJS"))	
		elseif tonumber(arg0) == 201507141 then --提示
			PushDebugMessage("#{SQBP_150626_132}");
		elseif tonumber(arg0) == 201507142 then --提示
			PushDebugMessage("#{SQBP_150626_133}");
		elseif tonumber(arg0) == 20150825 then --打开王者挑战赛官网
			--网页系统升级,旧.jsp结尾的网址需要换新
			--GameProduceLogin:OpenURL(GetWeblink("WEB_ZBSQMX"))
		elseif tonumber(arg0) == 891835 then --关于江湖名人榜
			--网页系统升级,旧.jsp结尾的网址需要换新
			--GameProduceLogin:OpenURL(GetWeblink("WEB_XINFUYURE"))	
		elseif tonumber(arg0) == 201611011 then --家园引导任务反馈信息
			local ntype = Get_XParam_INT(0)
			Quest_JiaYuanMissionReturn(ntype)
		elseif tonumber(arg0) == 50908101 then
			local msg = Get_XParam_STR( 0 )
			QuestGreeting_Desc:ClearAllElement()
			Quest_Frame_ResetPos()
			Quest_ShowEngageSucInfo(msg)
		elseif tonumber(arg0) == 5061003 then			
			Quest_Frame_ResetPos()
			Quest_ShowBountyMsg()
		elseif tonumber(arg0) == 8926941 then --打开2018争霸赛官网
			OpenUrl_2018ZBS_GWLT()
		elseif tonumber(arg0) == 8926943 then --打开2018竞猜活动地址
			OpenUrl_2018ZBS_JingCai()
		elseif tonumber(arg0) == 89272305 then
			local nCount = Get_XParam_INT(0)
			QuestGreeting_Desc:ClearAllElement()
			Quest_Frame_ResetPos()
			Quest_ShowZhouNianYuanMsg(nCount)
		elseif tonumber(arg0) == 20180803 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_QXFFF_LINK"))
		elseif tonumber(arg0) == 89305702 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_ZNFCTP"))
		elseif tonumber(arg0) == 893067100 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_SSZNLB"))
		elseif tonumber(arg0) == 89312202 then--用于打开链接
			GameProduceLogin:OpenURL(GetWeblink("WEB_HSSM"))
		elseif tonumber(arg0) == 920200330 then--打开勇攀高峰活动链接的UICommand
			GameProduceLogin:OpenURL(GetWeblink("WEB_YPGF"))
		elseif tonumber(arg0) == 4490001 then--打开购买嘉年华礼包链接
		--	PushDebugMessage("打开嘉年华礼包购买，超链接待添加")
			GameProduceLogin:OpenURL(GetWeblink("WEB_TLJIANIANHUA"))
		elseif tonumber(arg0) == 89322701 then--打开购买嘉年华礼包链接
			GameProduceLogin:OpenURL(GetWeblink("WEB_XINFUYUYUE"))
		elseif tonumber(arg0) == 44000399 then--拍卖分红
			GameProduceLogin:OpenURL(GetWeblink("WEB_GSPMFH"))
		elseif tonumber(arg0) == 88838001 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_JINLINGMATCH"))
		elseif tonumber(arg0) == 88834702 then
			local msg = Get_XParam_STR( 0 )
			QuestGreeting_Desc:ClearAllElement()
			Quest_Frame_ResetPos()
			Quest_ShowNewServerBoxInfo(msg)
		elseif tonumber(arg0) == 50509801 then
			-- GameProduceLogin:OpenURL(Quest_GetJiuTouShenDiaoYanUrl())
			GameProduceLogin:OpenURL(GetWeblink("WEB_JTSDY"))
		elseif tonumber(arg0) == 61002302 then
      GameProduceLogin:OpenURL(GetWeblink("WEB_KJFDYR"))
		elseif tonumber(arg0) == 61002402 then
	  GameProduceLogin:OpenURL(GetWeblink("WEB_KJFBHZT"))
		elseif tonumber(arg0) == 88898501 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_SCXMYR"))
		elseif tonumber(arg0) == 99857656 then
			OpenZBSUrl_MatchWeb()
		elseif tonumber(arg0) == 99857657 then
			OpenZBSUrl_GuessWeb()
		elseif tonumber(arg0) == 99899401 then -- 龙抬头活动
			OpenLongTaiTou_WXWeb()
		elseif tonumber(arg0) == 99975202 then -- 争霸赛直播
			OpenZBS_WXWeb()
		end
	-- 切换场景
	elseif(event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()) then
		Quest_Close();
		if objCared then
			StopCareObject_Quest(objCared);
		end
	elseif( event == "OPEN_ACCOUNT_SAFE") then
		Quest_Close();
	elseif (event == "ADJEST_UI_POS" ) then
		Quest_Frame_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Quest_Frame_ResetPos()
	elseif (event == "PS_SHOP_CLOSE") then
		g_nLastClickTime = 0
	elseif (event == "NOTIFY_POP_UITIP") then
        if "Quest" == arg0 and this:IsVisible() then
            Quest_FreshManGuide(1, tonumber(arg1), tonumber(arg2))
        end
	elseif (event == "OPEN_FUQICHENGHAO") then
        Quest_OpenFuQiDesc(arg0)
	elseif (event == "OPEN_BIEYEALLHELP") then
        Quest_OpenBieYeDesc(arg0)
	elseif (event == "OPEN_LEAGUEINFO_HELP") then
        Quest_OpenLeagueInfoDesc(arg0)
	elseif (event == "OPEN_ELECTION_HELP") then
		Quest_OpenElectionHelp(arg0)
	elseif (event == "CORPS_INVITE_NPCTALK_2018") then
		Quest_OpenCorpsHelp_2018(arg0)
	elseif (event == "CORPS_INVITE_NPCTALK2_2018") then
		Quest_OpenCorpsHelp2_2018(arg0)
	elseif (event == "OPEN_ZHOUNIANYUAN_HELP") then
		Quest_OpenZhounianyuan_Help()
	elseif (event == "OPEN_XUANZHANCD_HELP") then
		Quest_OpenXuanZhanCD_Help()
	elseif (event == "OPEN_JFMZ_HELP") then
		Quest_OpenJFMZ_Help()
	elseif (event == "OPEN_SHANGFENG_HELP") then
		Quest_OpenShangFeng_Help()
	elseif (event == "OPEN_HUODONGTEXT_HELP") then
		Quest_HuodongText_Help(arg0, arg1)
	elseif (event == "OPEN_NATIONAL_TREE_HELP") then
		Quest_OpenNational_Tree_Help()
	elseif (event == "OPEN_NATIONAL_FUND_HELP") then
		Quest_OpenNational_Fund_Help()
	elseif (event == "LAYUE_SIRILI_HELP") then
		Quest_OpenSiRiLi_Help()
	elseif (event == "LAYUE_BZSS_HELP") then
		Quest_OpenBZSS_Help()
	elseif (event == "GUISHI_NPCSHOP_HELP") then
		Quest_OpenGSNPCShop_Help(tonumber(arg0))
	elseif (event == "CCSHOP_HELP") then
		Quest_CCSHP_Help(arg0)		
	elseif (event == "SPRINGGUIDEMISSION_JIXIANGFUHELP") then-- 2018Q4春节引导任务
		Quest_SpringGuideMission_JiXiangFuHelp(arg0)		
	elseif (event == "DUANWU_DUIHUAN_HELP") then--端午兑换
		Quest_DuanWu_DuiHuan_Help()
	elseif event == "ZNQ_DRAW_HELP" then
		Quest_OpenZNQDraw_Help()
	elseif event == "GQHYCHOUJIANG_HELP" then	-- 2019国庆稳活跃抽奖--祈福界面帮助
		Quest_OpenGQHYChouJiang_Help()
	elseif event == "DUANWU_BIDDING_HELP_I" then
		Quest_OpenDuanWuBidding_Help_I()
	elseif event == "DUANWU_BIDDING_HELP_II" then
		Quest_OpenDuanWuBidding_Help_II()
	elseif event == "SPRINGGUIDEMISSION_CAIDANHELP" then
		Quest_SpringGuideMission_CaiDanHelp()
	elseif event == "SRPING_FESTIVAL_BIDDING_HELP" then
		Quest_SpringFestivalBidding_Help()
	elseif event == "SRPING_FESTIVAL_BIDDINGLIST_HELP" then
		Quest_SpringFestivalBiddingList_Help()	
	elseif event == "DUANWU_BIDDING_HELP_III" then
		Quest_OpenDuanWuBidding_Help_III()
	elseif event == "QUEST_HELP_MSG" then
		Quest_Open_Help_Msg( arg0 )
	elseif event == "BIANJING_BIDDINGLIST_HELP" then
		Quest_BianJingBiddingList_Help(0)
	elseif event == "BIANJING_BIDDING_TIME_HELP" then
		Quest_BianJingBiddingTime_Help()
	elseif event == "BIANJING_BIDDINGLIST_HELP_TOKEN" then
		Quest_BianJingBiddingList_Help(1)
	elseif (event == "LONGSIGNIN_OPEN_HELP") then
		Quest_OpenLongSignIn_Help()
	elseif (event == "CAIQIUENTER_OPEN_HELP") then
		Quest_OpenCaiQiuEnter_Help()
	elseif (event == "ETJFUBEN_2022_HELP") then
		Quest_OpenLuHeXieXiang_Help()
	elseif (event == "ETJFUBEN_2022_RESULT") then
		Quest_ShowLuHeXieXiang_Result(arg0, arg1)
	elseif (event == "XRZPVP_UI_OPENGOTOHELP") then
		Quest_ShowXRZPVPGoto_Help()
	elseif (event == "QUEST_HELPINFO") then
		Quest_HelpMsg(arg0)
	elseif (event == "OPEN_2606S_HELP") then
		Quest_Open2606S_Help()
	end

end

--=========================================================
-- 关闭相应
--=========================================================
function Quest_Close()
	--取消关心
	StopCareObject_Quest(objCared);
end

--=========================================================
-- 显示任务列表
--=========================================================
function Quest_EventListUpdate()
	local nLevel = Player:GetData("LEVEL")
	if nLevel <= 10 then
		Icon_Preference[1] = 6
		Icon_Preference[2] = 12
	else
		Icon_Preference[1] = 13
		Icon_Preference[2] = 6
	end

	local nEventListNum = DataPool:GetNPCEventList_Num();
	local i;
	local j =1;
	local k =1;
	local yy = 1;

	local canacceptArr ={}
	local cansubmitArr = {}
	local Sequence_OnefoldGenre = {}
	local Constitutes = {}
	local nTitleType = 0;
	local nNeedUITip = 0
	for i=1, nEventListNum do
	local strType,strState,strScriptId,strExtra,strTemp = DataPool:GetNPCEventList_Item(i-1);

		if(strType == "text") then
			QuestGreeting_Desc:AddTextElement(strTemp);
		elseif(strType == "id") then
			if strState <= 0 or strState > 34 then
				strState = 8
			end
			if( tonumber( strScriptId ) == 808007 ) then
				if( strTemp == "我想临时解锁" ) then
					nTitleType = 1
				elseif( strTemp == "我想单个解锁" ) then
					nTitleType = 1
				elseif( strTemp == "全部加锁" ) then
					nTitleType = 2
				elseif( strTemp == "单个加锁" ) then
					nTitleType = 2
				elseif( strTemp == "确认" ) then
					nTitleType = 2
				end
			end
			
			local resState = strState
			if resState == 32 then
				resState = 1
			elseif resState == 33 then
				resState = 2
			elseif resState == 34 then
				resState = 19
			end

			strTemp = strTemp .. "&"
			strTemp = strTemp .. strScriptId
			strTemp = strTemp .. ","
			strTemp = strTemp .. strExtra
			strTemp = strTemp .. "$"
			strTemp = strTemp .. resState
			
			Constitutes = {strTemp,Icon_Preference[strState]}
			if table.getn(Sequence_OnefoldGenre) > 0 then
				local Inserted = 0
				for yy,eachConstitute in Sequence_OnefoldGenre do

					if not CompareTable_Quest(eachConstitute,Constitutes) then
						table.insert(Sequence_OnefoldGenre,yy,Constitutes)
						Inserted = 1
						break
					end
				end
				if Inserted == 0 then
					table.insert(Sequence_OnefoldGenre,Constitutes)
				end
			else
				table.insert(Sequence_OnefoldGenre,Constitutes)
			end

            if 210262 == tonumber(strScriptId) and Player:GetData("LEVEL") < 3 then
                nNeedUITip = 1 --只有“初涉江湖”需要引导ui
				g_ShowRect = 1
            end

			if 890251 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
               	nNeedUITip = 1 -- 缘起无量
				g_ShowRect = 2
            end
			if 890252 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
				if strState == 2 then
               		nNeedUITip = 3  --路见不平
               	else
               		nNeedUITip = 0
               	end
            end
			if 890254 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
				if strState == 2 then
               		nNeedUITip = 4  --武功招式
            	else
            		nNeedUITip = 0
            	end
            end
			if 890255 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
               	if strState == 2 then
               		nNeedUITip = 5  --并肩作战
				--g_ShowRect = 2
            	else
            		nNeedUITip = 0  --路见不平
            	end
            end
			if 890256 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
               	if strState == 2 then
               		nNeedUITip = 6  --寡不敌众
				--g_ShowRect = 2
				else
            		nNeedUITip = 0  --路见不平
            	end
            end
			if 890257 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
               	if strState == 2 then
              	 	nNeedUITip = 7  --无量玉璧
				--g_ShowRect = 2
				else
					nNeedUITip = 0
				end
            end
			if 890258 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
               	if strState == 2 then
              	 	nNeedUITip = 8  --尔虞我诈
				--g_ShowRect = 2
				else
					nNeedUITip = 0
				end
            end
			if 890261 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
				if strState == 2 then
               		nNeedUITip = 9  --城外相会
				--g_ShowRect = 2
				else
					nNeedUITip = 0
				end
            end
			if 890262 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
				if strState == 2 then
               		nNeedUITip = 10  --珍兽商店
				--g_ShowRect = 2
				else
					nNeedUITip = 0
				end
            end
			if 890264 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
               	if strState == 2 then
              	 	nNeedUITip = 11  --防具商店
				--g_ShowRect = 2
				else
					nNeedUITip = 0
				end
            end
			if 890265 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
				if strState == 2 then
               		nNeedUITip = 12  --拜访天师
				--g_ShowRect = 2
				else
					nNeedUITip = 0
				end
            end
			if 890263 == tonumber(strScriptId) and Player:GetData("LEVEL") < 15 then		--新手任务修改
				g_SHowNewNPCchat = 1
              	if strState == 2 then
               		nNeedUITip = 13  --武器商店
				--g_ShowRect = 2
				else
					nNeedUITip = 0
				end
            end
			local nMisNum = DataPool:GetPlayerMission_Num()
	   		if 210270 == tonumber(strScriptId) then
				for i = 0, nMisNum do
					local strMisName = DataPool:GetPlayerMission_Name(i)
					if strMisName == "Mission:1424" then
						if Player:GetData("LEVEL") > 9 then
							nNeedUITip = 2
						end
					end
				end

       		end
		end
	end


	for i,PerOption in ipairs(Sequence_OnefoldGenre) do
		QuestGreeting_Desc:AddOptionElement(PerOption[1]);
	end
	Sequence_OnefoldGenre = {};


	g_nQuestState = QUEST_STATE_EVENTLIST;
	local ret = string.find(Target:GetDialogNpcName(),"诱兔萝卜堆")
	if ret ~= nil then
		Quest_Frame_Debug:SetText("#gFF0FA0".."诱兔萝卜堆")
	else
		Quest_Frame_Debug:SetText("#gFF0FA0"..Target:GetDialogNpcName());--get npc的name
	end
	if( nTitleType == 1 ) then
		Quest_Frame_Debug:SetText("#gFF0FA0解锁" );
	elseif( nTitleType == 2 ) then
		Quest_Frame_Debug:SetText("#gFF0FA0加锁" );
	end

	Quest_Button_Continue:SetText("继续");--继续
	Quest_Button_Continue:Disable();
	Quest_Button_Continue:SetProperty("EnableAnimation", "0")
	Quest_Button_Accept:Disable();
	Quest_Button_Accept:SetProperty( "Flash", "0" );
	Quest_Button_Refuse:SetText("再见");--再见

	if 1 == nNeedUITip then
		if g_SHowNewNPCchat == 1 then
			Quest_FreshManNpcChat(0)
			Quest_FreshManGuide(1, 2, 5)
		else
			Quest_FreshManGuide(1, 2, 1)
		end
	elseif 2 == nNeedUITip then
	    Quest_FreshManGuide(1, 2, 4)
	elseif 3 == nNeedUITip then
		if  SystemSetup:IsClassic() == 0 then  --唯美
	    	Quest_FreshManGuide(1, 2, 7)
	    else
	    	Quest_FreshManGuide(1, 2, 18)       --经典
	    end
	elseif 4 == nNeedUITip then  --武功招式
	    Quest_FreshManGuide(1, 2, 8)
	elseif 5 == nNeedUITip then  --并肩作战
	    Quest_FreshManGuide(1, 2, 9)
	elseif 6 == nNeedUITip then  --寡不敌众
	    Quest_FreshManGuide(1, 2, 10)
	elseif 7 == nNeedUITip then  --无量玉璧
		    Quest_FreshManGuide(1, 2, 11)
	elseif 8 == nNeedUITip then  --尔虞我诈
		if  SystemSetup:IsClassic() == 0 then  --唯美
	   		 Quest_FreshManGuide(1, 2, 12)
		else
			 Quest_FreshManGuide(1, 2, 19)     --经典
		end
	elseif 9 == nNeedUITip then  --城外相会
	    Quest_FreshManGuide(1, 2, 13)
	elseif 10 == nNeedUITip then  --珍兽商店
		if  SystemSetup:IsClassic() == 0 then  --唯美
	   		Quest_FreshManGuide(1, 2, 14)
		else
			Quest_FreshManGuide(1, 2, 20)
		end
	elseif 11 == nNeedUITip then  --防具商店
		if  SystemSetup:IsClassic() == 0 then  --唯美
	   	    Quest_FreshManGuide(1, 2, 15)
	   	else
	   		Quest_FreshManGuide(1, 2, 21)
	   	end
	elseif 12 == nNeedUITip then  --拜访天师
	    Quest_FreshManGuide(1, 2, 16)
	elseif 13 == nNeedUITip then  --武器商店
	    Quest_FreshManGuide(1, 2, 17)
	end

	if 1 == g_ShowRect then
		Quest_ShowFreshManRect(1)
	elseif 2 == g_ShowRect then
		Quest_NewShowFreshManRect(1)
	end
end

--=========================================================
-- 显示任务信息
--=========================================================
function Quest_QuestInfoUpdate()
	local nTextNum, nBonusNum = DataPool:GetMissionInfo_Num();

	for i=1, nTextNum do
		local strInfo = DataPool:GetMissionInfo_Text(i-1);
		QuestGreeting_Desc:AddTextElement(strInfo);
	end

--	QuestGreeting_Desc:AddTextElement("#Y奖励：#W");
	local nRadio = 1;
	local nRadio_Necessary = 1;
	local nItemID;
	local ActionID;

	for i=1, nBonusNum do
		--    奖励的类型，奖励物品ID，奖励多少个
		local strType, nItemID, nNum = DataPool:GetMissionInfo_Bonus(i-1);

		if(strType == "money" and nNum > 0) then
			if(nRadio_Necessary == 1) then
				QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				nRadio_Necessary = 0;
			end

			QuestGreeting_Desc:AddMoneyElement(nNum);
		elseif(strType == "moneyjz" and nNum > 0) then
			if(nRadio_Necessary == 1) then
				QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				nRadio_Necessary = 0;
			end
			QuestGreeting_Desc:AddJiaoZiElement(nNum);
		elseif(strType == "item") then
			if(nRadio_Necessary == 1) then
				QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				nRadio_Necessary = 0;
			end
--			QuestGreeting_Desc:AddItemElement(nItemID, nNum, 0);
			nItemID = LifeAbility : GetQuestUI_Reward(i-1);

			if nItemID ~= -1 then
				ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
				QuestGreeting_Desc:AddActionElement(ActionID, nNum, 0);

			end
		elseif(strType == "itemrand") then
			if(nRadio_Necessary == 1) then
				QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				nRadio_Necessary = 0;
			end
			QuestGreeting_Desc:AddItemElement(-1, nNum, 0);
		elseif(strType == "itemradio") then
			if (nRadio == 1) then
				nRadio = 0;
				QuestGreeting_Desc:AddTextElement("#Y完成任务后可选一个作为奖品:#W");
			end
--			QuestGreeting_Desc:AddItemElement(nItemID, nNum, 0);
			nItemID = LifeAbility : GetQuestUI_Reward(i-1);

			if nItemID ~= -1 then
				local ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
				QuestGreeting_Desc:AddActionElement(ActionID, nNum, 0);

			end
		end
	end

	g_nQuestState = QUEST_STATE_MISSON_INFO
--	Quest_Frame_Debug:SetText("QUEST_STATE_MISSON_INFO");--get npc的name
	if( Target:IsPresent()) then
		--Quest_Frame_Debug:SetText(Target:GetDialogNpcName());--get npc的name
	end

	Quest_Button_Continue:Disable();
	Quest_Button_Continue:SetProperty("EnableAnimation", "0")
	Quest_Button_Accept:SetProperty( "Flash", "1" );
	Quest_Button_Accept:Enable();
	Quest_Button_Continue:SetText("继续");--继续
	Quest_Button_Refuse:SetText("取消");--取消

	local nMissionScriptID = DataPool:GetMissionInfo_ScriptID()
	if 210262 == nMissionScriptID or 210255 == nMissionScriptID or 210256 == nMissionScriptID or 210257 == nMissionScriptID or
           210258 == nMissionScriptID or 210263 == nMissionScriptID or 210259 == nMissionScriptID or 210273 == nMissionScriptID or
           210274 == nMissionScriptID or 210280 == nMissionScriptID or 210275 == nMissionScriptID or 210276 == nMissionScriptID or
           210264 == nMissionScriptID or 210265 == nMissionScriptID or 210277 == nMissionScriptID or 210266 == nMissionScriptID or
           210278 == nMissionScriptID or 210267 == nMissionScriptID or 210269 == nMissionScriptID or 210268 == nMissionScriptID or
		   890252 == nMissionScriptID or 890253 == nMissionScriptID or 890254 == nMissionScriptID or 890255 == nMissionScriptID or
		   890256 == nMissionScriptID or 890257 == nMissionScriptID or 890258 == nMissionScriptID or 890259 == nMissionScriptID or
		   890260 == nMissionScriptID or 890261 == nMissionScriptID or 890262 == nMissionScriptID or 890263 == nMissionScriptID or
		   890264 == nMissionScriptID or 890265 == nMissionScriptID then

	   --初涉江湖、第一把武器、第一件防具、第一次杀怪
	   --回访天师、初级技能、灵丹妙药、剑阁猴患
	   ----大理怪人、何谓行善、再访天师、珍兽家族
	   ----第一只珍兽、抓珍兽、三访天师、喜庆烟火（大理美景）
	   ----大善人、江湖问答、最后的试炼、十一大门派
	   ----2013Q3新手任务修改
	    Quest_FreshManGuide(1, 4, 3)
	end
end

--=========================================================
--Continue任务的对话框
--=========================================================
function Quest_MissionContinueUpdate(bDone)
	local nTextNum, nBonusNum = DataPool:GetMissionDemand_Num();
	local ActionID;
	for i=1, nTextNum do
		local strInfo = DataPool:GetMissionDemand_Text(i-1);
		QuestGreeting_Desc:AddTextElement(strInfo);
	end

	if( nBonusNum>1 ) then
		QuestGreeting_Desc:AddTextElement("#Y需要物品:#W");
	end

	for i=1, nBonusNum do
		--    需要的类型，需要物品ID，需要多少个
		local nItemID, nNum = DataPool:GetMissionDemand_Item(i-1);
--		QuestGreeting_Desc:AddItemElement(nItemID, nNum, 0);
			nItemID = LifeAbility : GetQuestUI_Demand(i-1);

			if nItemID ~= -1 then
				ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
				QuestGreeting_Desc:AddActionElement(ActionID, nNum, 0);

			end

	end

	if (bDone == 1) then
		g_nQuestState = QUEST_STATE_CONTINUE_DONE;
--		Quest_Frame_Debug:SetText("CONTINUE_DONE");--get npc name
		Quest_Button_Continue:Enable();
	else
		g_nQuestState = QUEST_STATE_CONTINUE_NOTDONE;
--		Quest_Frame_Debug:SetText("CONTINUE_NOTDONE");--get npc name
		Quest_Button_Continue:Disable();
	end

	if( Target:IsPresent()) then
		--Quest_Frame_Debug:SetText(Target:GetDialogNpcName());--get npc的name
	end

	Quest_Button_Accept:Disable();
	Quest_Button_Accept:SetProperty( "Flash", "0" );
	Quest_Button_Refuse:SetText("取消");--取消
	Quest_Button_Continue:SetText("继续");--继续
	Quest_Button_Continue:SetProperty("EnableAnimation", "0")
end

--=========================================================
--收取奖励物品的对话框
--=========================================================
function Quest_MissionRewardUpdate()
	g_nQuestState = QUEST_STATE_AFTER_CONTINUE;
	if( Target:IsPresent()) then
		--Quest_Frame_Debug:SetText(Target:GetDialogNpcName());--get npc的name
	end
--	Quest_Frame_Debug:SetText("AFTER_CONTINUE");--get npc name

	Quest_Button_Continue:Enable();
	Quest_Button_Accept:Disable();
	Quest_Button_Accept:SetProperty( "Flash", "0" );
	Quest_Button_Refuse:SetText("取消");--取消
	Quest_Button_Continue:SetText("完成");--完成

	local nTextNum, nBonusNum = DataPool:GetMissionContinue_Num();

	for i=1, nTextNum do
		local strInfo = DataPool:GetMissionContinue_Text(i-1);
		QuestGreeting_Desc:AddTextElement(strInfo);
	end

	local nRadio = 1;
	local nRadio_Necessary = 1;
	local nItemID;
	local ActionID;

	bBeingRadio = 0;
	bRadioSelect = 0;
	for i=1, nBonusNum do
		--    奖励的类型，奖励物品ID，奖励多少个
		local strType, nItemID, nNum = DataPool:GetMissionInfo_Bonus(i-1);

		if(strType == "money"  and nNum > 0) then
			if(nRadio_Necessary == 1) then
				QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				nRadio_Necessary = 0;
			end
			QuestGreeting_Desc:AddMoneyElement(nNum);
		elseif(strType == "moneyjz" and nNum > 0) then
			if(nRadio_Necessary == 1) then
				QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				nRadio_Necessary = 0;
			end
			QuestGreeting_Desc:AddJiaoZiElement(nNum);
		elseif(strType == "item") then
			local nIssueScriptID = DataPool : GetMissionContinue_IssueScriptID();
			if(nRadio_Necessary == 1) then
				if ( nIssueScriptID == 250056 ) then
					QuestGreeting_Desc:AddTextElement("#Y固定奖励：（随机奖励其中一种）#W")
				else
					QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				end
				nRadio_Necessary = 0;
			end
--			QuestGreeting_Desc:AddItemElement(nItemID, nNum, 0);
			nItemID = LifeAbility : GetQuestUI_Reward(i-1);

			if nItemID ~= -1 then
				ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
				QuestGreeting_Desc:AddActionElement(ActionID, nNum, 0);

			end
		elseif(strType == "itemrand") then
			if(nRadio_Necessary == 1) then
				QuestGreeting_Desc:AddTextElement("#Y固定奖励:#W")
				nRadio_Necessary = 0;
			end
			QuestGreeting_Desc:AddItemElement(-1, nNum, 0);
		elseif(strType == "itemradio") then
			bBeingRadio = 1;
			if (nRadio == 1) then
				nRadio = 0;
				if nRadio_Necessary == 1 then
					QuestGreeting_Desc:AddTextElement("#Y你可以从以下奖励中选择一项:#W");
				else
					QuestGreeting_Desc:AddTextElement("#Y还可以从以下奖励中选择一项:#W");
				end

			end
--			QuestGreeting_Desc:AddItemElement(nItemID, nNum, 1);
			nItemID = LifeAbility : GetQuestUI_Reward(i-1);

			if nItemID ~= -1 then
				ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
				QuestGreeting_Desc:AddActionElement(ActionID, nNum, 1);
			end

			--只有一个的话，就默认选上
			if nBonusNum == 1 then
				g_nRewardItemID = 0
				bRadioSelect = 1;
			end
		end
	end

	--如果加入的是单选物品，添加默认选中项
	if(bBeingRadio == 1) then

		local nMissionScriptID = DataPool:GetMissionContinue_MissionID()
		local nmenpai = tonumber(Player:GetData("MEMPAI"))		--略坑~
		local ncheckIndex = 0;

		local MenpaiType_neiwaigong = Quest_GetMenpaiType_neiwaigong(nmenpai)
		local MenpaiType_wuqi = Quest_GetMenpaiType_wuqi(nmenpai)

		bRadioSelect = 1

		if( nMissionScriptID == 1401 ) then				--第一把武器
			ncheckIndex = math.abs( math.mod( Player:GetGUID() , 4 ) )

		elseif( nMissionScriptID == 648 ) then			--苏飞的世界
			if( MenpaiType_wuqi == 1 ) then
				ncheckIndex = 1
			else
				ncheckIndex = 0
			end

		elseif( nMissionScriptID == 907 )	 then			--驱逐铜人
			ncheckIndex = 0

		elseif( nMissionScriptID == 910 )	 then			--龙井水贼
			ncheckIndex = 0

		elseif( nMissionScriptID == 587 )	 then			--收复茶马道
			ncheckIndex = 1

		elseif( nMissionScriptID == 515 )	 then			--夹击
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			else
				ncheckIndex = 0
			end

		elseif( nMissionScriptID == 466 )	 then			--蛛丝马迹
			if( MenpaiType_wuqi == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType_wuqi == 1 ) then
				ncheckIndex = 2
			else
				ncheckIndex = 2
			end

		elseif( nMissionScriptID == 469 ) then			--嵩阳断肠草
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 0
			else
				ncheckIndex = 1
			end

		elseif( nMissionScriptID == 647 )	 then			--归风庄
			if( MenpaiType_wuqi == 0 ) then
				ncheckIndex = 2
			elseif( MenpaiType_wuqi == 1 ) then
				ncheckIndex = 0
			else
				ncheckIndex = 1
			end

		elseif( nMissionScriptID == 588 ) then			--被缚的萨宁
			if( MenpaiType_wuqi == 0 ) then
				ncheckIndex = 0
			elseif( MenpaiType_wuqi == 1 ) then
				ncheckIndex = 2
			else
				ncheckIndex = 2
			end

		elseif( nMissionScriptID == 516 ) then			--回归
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 0
			else
				ncheckIndex = 1
			end

		elseif( nMissionScriptID == 518 ) then			--战火
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 0
			else
				ncheckIndex = 1
			end

		elseif( nMissionScriptID == 463 )	 then			--来龙去脉
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 0
			else
				ncheckIndex = 1
			end

		elseif( nMissionScriptID == 915 ) then			--智慧的试炼
			ncheckIndex = 0

		elseif( nMissionScriptID == 917 ) then			--信用的试炼
			if( MenpaiType_wuqi == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType_wuqi == 1 ) then
				ncheckIndex = 0
			else
				ncheckIndex = 2
			end
		elseif nMissionScriptID == 1768 then
			if MenpaiType_wuqi == 1 then
				ncheckIndex = 0
			elseif MenpaiType_wuqi == 2 then
				ncheckIndex = 1
			elseif MenpaiType_wuqi == 0 then
				ncheckIndex = 3
			elseif MenpaiType_wuqi == 3 then
				ncheckIndex = 2
			elseif MenpaiType_wuqi == 4 then
				ncheckIndex = 4
			elseif MenpaiType_wuqi == 5 then
				ncheckIndex = 5
			elseif MenpaiType_wuqi == 6 then
				ncheckIndex = 6
			elseif MenpaiType_wuqi == 7 then
				ncheckIndex = 7
			end
		elseif nMissionScriptID == 1772 or nMissionScriptID == 1773 then
			if MenpaiType_neiwaigong == 0 then
				ncheckIndex = 1
			else
				ncheckIndex = 0
			end
		elseif nMissionScriptID == 1659 or nMissionScriptID == 1660 or nMissionScriptID == 1663 or nMissionScriptID == 1665 then
			if MenpaiType_neiwaigong == 0 then
				ncheckIndex = 1
			else
				ncheckIndex = 0
			end
		elseif( nMissionScriptID == 1753 ) then	--敦煌场景任务群:驱逐群狼
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType_neiwaigong == 1 ) then
				ncheckIndex = 0
			end

		elseif( nMissionScriptID == 1756 ) then	--敦煌场景任务:乔装准备
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType_neiwaigong == 1 ) then
				ncheckIndex = 0
			end

		elseif( nMissionScriptID == 1758 ) then	--敦煌场景任务群:虎口夺药
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType_neiwaigong == 1 ) then
				ncheckIndex = 0
			end

		elseif( nMissionScriptID == 1761 ) then	--敦煌场景任务群:破坏弩车
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType == 1 ) then
				ncheckIndex = 0
			end

		elseif( nMissionScriptID == 1762 ) then	--敦煌场景任务群:刺杀大将
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType == 1 ) then
				ncheckIndex = 0
			end
		elseif( nMissionScriptID == 1671) then --嵩山任务，采集草药
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType == 1 ) then
				ncheckIndex = 0
			end
		elseif( nMissionScriptID == 1672 ) then --嵩山任务，收集狼血
			if( MenpaiType_neiwaigong == 0 ) then
				ncheckIndex = 1
			elseif( MenpaiType == 1 ) then
				ncheckIndex = 0
			end
		elseif( nMissionScriptID == 1679 ) then
			if( MenpaiType_wuqi == 0 ) then
				ncheckIndex = 1--刀
			elseif( MenpaiType_wuqi == 1 ) then
				ncheckIndex = 3--单短双短
			elseif( MenpaiType_wuqi == 2 ) then
				ncheckIndex = 2--环扇
			elseif( MenpaiType_wuqi == 3 ) then
				ncheckIndex = 0--弩
			elseif( MenpaiType_wuqi == 4 ) then
				ncheckIndex = 4--弩
			elseif( MenpaiType_wuqi == 5 ) then
				ncheckIndex = 5--弩
			elseif( MenpaiType_wuqi == 6 ) then
				ncheckIndex = 6
			elseif( MenpaiType_wuqi == 7 ) then
				ncheckIndex = 7
			end
		elseif (nMissionScriptID == 1811) then	--	子女成长立宏愿	奖励典籍
			local nheroType = Infant:GetHeroType(0)
			if(nheroType == 2) then
				ncheckIndex = 1	--	段誉
			elseif(nheroType == 3) then
				ncheckIndex = 2	--	虚竹
			elseif(nheroType == 4) then
				ncheckIndex = 3	--	王语嫣
			else
				ncheckIndex = 0	--	乔峰
			end
		else
			bRadioSelect = 0												--上述任务之外的任务不自动推荐装备
		end

		if( bRadioSelect == 1 ) then
			QuestGreeting_Desc:SetActionElementCheck( ncheckIndex )
			g_nRewardItemID = ncheckIndex
		end

	end

    --	娘的。完成任务页游好多。。。。
    local nMisScriptID = DataPool:GetMissionContinue_ScriptID()
    if 210262 == nMisScriptID or 210255 == nMisScriptID or 210256 == nMisScriptID or 210257 == nMisScriptID or --初涉江湖、第一把武器、第一件防具、第一次杀怪
       210258 == nMisScriptID or 210263 == nMisScriptID or 210259 == nMisScriptID or 210273 == nMisScriptID or --回访天师、初级技能、灵丹妙药、剑阁猴患
       210274 == nMisScriptID or 210280 == nMisScriptID or 210275 == nMisScriptID or 210276 == nMisScriptID or --大理怪人、何谓行善、再访天师、珍兽家族
       210264 == nMisScriptID or 210265 == nMisScriptID or 210277 == nMisScriptID or 210266 == nMisScriptID or --第一只珍兽、抓珍兽、三访天师、喜庆烟火（大理美景）
       210278 == nMisScriptID or 210267 == nMisScriptID or 210269 == nMisScriptID or 210268 == nMisScriptID or --大善人、江湖问答、最后的试炼、十一大门派
	   890251 == nMisScriptID or 890252 == nMisScriptID or 890253 == nMisScriptID or 890254 == nMisScriptID or
	   890256 == nMisScriptID or 890257 == nMisScriptID or 890258 == nMisScriptID or 890259 == nMisScriptID or
	   890260 == nMisScriptID or 890261 == nMisScriptID or 890262 == nMisScriptID or 890263 == nMisScriptID or
	   890264 == nMisScriptID or 890265 == nMisScriptID or 890255 == nMisScriptID then
	--	现在变了。。。。。不仅仅是初涉江湖了。。。简直就是个大坑。。。。位置需要一点一点调整的。。。。。啊~~~~~
        Quest_FreshManGuide(1, 3, 2)
        --按钮加动画
        Quest_Button_Continue:SetProperty("BtnAnimation", "BtnlightupAni2")
        Quest_Button_Continue:SetProperty("EnableAnimation", "1")
    else
	    Quest_Button_Continue:SetProperty("EnableAnimation", "0")
    end
end


--=========================================================
-- 判断门派内功外功
-- 外功门派 0			内功门派 1
--=========================================================
function Quest_GetMenpaiType_neiwaigong(menpai)

	for i , index in MEIPAI_WAIGONG do
		if( menpai ==  index ) then
			return 0
		end
	end

	for i , index in MEIPAI_NEIGONG do
		if( menpai ==  index ) then
			return 1
		end
	end

	return -1

end

--=========================================================
-- 判断门派武器类型
-- 刀斧、枪棒门派 0			单短、双短门派 1			扇、环门派 2    弩 3 杖 4
--=========================================================
function Quest_GetMenpaiType_wuqi(menpai)

	for i , index in MEIPAI_DAOFUQIANGBANG do
		if( menpai ==  index ) then
			return 0
		end
	end

	for i , index in MEIPAI_DANDUANSHUANGDUAN do
		if( menpai ==  index ) then
			return 1
		end
	end

	for i , index in MEIPAI_SHANHUAN do
		if( menpai ==  index ) then
			return 2
		end
	end

	for i , index in MEIPAI_NU do
		if( menpai ==  index ) then
			return 3
		end
	end
	
	for i , index in MEIPAI_ZHANG do
		if( menpai ==  index ) then
			return 4
		end
	end
	
	for i , index in MEIPAI_XIAOJIAN do
		if( menpai ==  index ) then
			return 5
		end
	end
	
	for i , index in MEIPAI_2HUAN do
		if( menpai ==  index ) then
			return 6
		end
	end

	--menpai15 mptodo 新门派如果是新增武器类型就类似MEIPAI_2HUAN加个新的，如果不是就在上面的表里面加门派id
	for i , index in MEIPAI_ERENGUWUQI do
		if( menpai ==  index ) then
			return 7
		end
	end

	return -1

end

--=========================================================
-- 选择一个任务
--=========================================================
function QuestOption_Clicked()

	--文字的格式是
	--QuestGreeting_option_03#211207,0
	pos1,pos2 = string.find(arg0,"#");
	pos3,pos4 = string.find(arg0,",");

	local strOptionID = -1;
	local strOptionExtra1 = string.sub(arg0, pos2+1,pos3-1 );
	local strOptionExtra2 = string.sub(arg0, pos4+1);

	--TT76454
	if( (Player:InTeamFollowMode() == true) and
			(Player:IsLeader() ~= 1) and
			(tonumber(strOptionExtra2) ~= -1) and
			(tonumber(strOptionExtra1) == 806008)) then
			PushDebugMessage("#{GMAI_MySelf_27}");
		return
	end

	local Data1 = tonumber( strOptionExtra1 )      --Data1为表的编号
  local Data2 = tonumber( strOptionExtra2 )      --Data2为表中内容的index
  if ( Data1 == 210 ) then--侠义之心特殊处理
  	if ( Data2 == 10358) then--上一步处理
  	elseif ( Data2 == 10360 ) then--怪物分布上一步处理
  		Quest_ShowMonsterInfo( )--tonumber( WRGetCurColLevel() )
  	else
  		Quest_DispatchContex(Data2)
  	end
  	return
  end

	if Data1 == 109 and Data2 == 2 then  --查看所有商店，防止频繁刷列表
		local nCurTime = OSAPI:GetTickCount()
		if 	nCurTime - g_nLastClickTime < 4*1000 then
			return
		end
		g_nLastClickTime = nCurTime
	end

	if( Data1 == 890017 ) and (Data2 == 4001)then
		GameProduceLogin:OpenURL(GetWeblink("WEB_CHONGLONG"))
		return
	end

	if( Data1 == 890131 ) and (Data2 == 2014)then  --我要购买角色
		if GameProduceLogin:IsWeGameClient() > 0 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_CYGJY"))
		else
			GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGYIGE_GOUMAIJUESE"))
		end
		return
	end

	if( Data1 == 890131 ) and (Data2 == 2015)then  --查看公示期角色
		if GameProduceLogin:IsWeGameClient() > 0 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_CYGGS"))
		else
			GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGYIGE_GONGSHIQI"))
		end
		return
	end

	if( Data1 == 890131 ) and (Data2 == 2018)then  --关于角色购买流程
		GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGYIGE_GOUMAI"))
		return
	end

	QuestFrameOptionClicked(tonumber(strOptionID),tonumber(strOptionExtra1),tonumber(strOptionExtra2));
	if "Quest" == GetFreshManGuideOwner() then
		CloseFreshManGuide()	--	关闭UI引导
	end

end

--=========================================================
-- 选择一个多选一的奖励物品
--=========================================================
function RewardItem_Clicked()

	local strRewardItemID = string.sub(arg0, -2, -1);
	g_nRewardItemID = tonumber(strRewardItemID);
	bRadioSelect = 1;
end

--=========================================================
-- Continue & Complete
--=========================================================
function MissionContinue_Clicked()
	if ( g_nQuestState == QUEST_STATE_CONTINUE_DONE ) then
		QuestFrameMissionContinue();
--		Quest_Close();
		--取消关心
--		StopCareObject_Quest(objCared);

	elseif( g_nQuestState == QUEST_STATE_AFTER_CONTINUE )then

		if(bBeingRadio == 1) then
			if(bRadioSelect == 1)then
				QuestFrameMissionComplete(g_nRewardItemID);
				bBeingRadio = 0;
				bRadioSelect = 0;
				Quest_Close();
				--取消关心
				StopCareObject_Quest(objCared);

			--	if 210255 == DataPool:GetMissionContinue_ScriptID() then --第一把武器给奖励
			--	    NotifyPopUITip("Packet", 6, DataPool:GetMissionContinue_ItemID(g_nRewardItemID, 4), 210255)  --通知包裹界面：弹出ui引导
			--	end
			else
				if (889941 == DataPool:GetMissionContinue_ScriptID()) then
					PushDebugMessage("请选择您所需要打造的玄兵石")
				elseif (892707 == DataPool:GetMissionContinue_ScriptID()) then
					PushDebugMessage("#{WCBS_180307_121}")
				elseif (892708 == DataPool:GetMissionContinue_ScriptID()) then
					PushDebugMessage("#{WCBS_180307_39}")
				elseif (892709 == DataPool:GetMissionContinue_ScriptID()) then
					PushDebugMessage("#{WCBS_180307_75}")
				elseif (892711 == DataPool:GetMissionContinue_ScriptID()) then
					PushDebugMessage("#{WCBS_180307_113}")
				elseif (892712 == DataPool:GetMissionContinue_ScriptID()) then
					PushDebugMessage("#{WCBS_180307_160}")
				else
					PushDebugMessage("请选择奖励物品！");
				end
			end
		else
			QuestFrameMissionComplete(g_nRewardItemID);
			bBeingRadio = 0;
			bRadioSelect = 0;
			Quest_Close();
			--取消关心
			StopCareObject_Quest(objCared);

			local nScriptId = DataPool:GetMissionContinue_ScriptID()
			if 210256 == nScriptId then --第一件防具给奖励
			    NotifyPopUITip("Packet", 6, DataPool:GetMissionContinue_ItemID(0, 2), 210256)  --通知包裹界面：弹出ui引导
			    FlashPacketButton()
			elseif 210259 == nScriptId then  --灵丹妙药
			--  NotifyPopUITip("Packet", 20, DataPool:GetMissionContinue_ItemID(0, 2), 210259)  --通知包裹界面：弹出ui引导
			    FlashPacketButton()
			end
		end
		if Quest_Button_Continue then
			Quest_Button_Continue:SetProperty("EnableAnimation", "0")
		end
	end
end

--=========================================================
-- 接受任务
--=========================================================
function QuestAccept_Clicked()
	if(g_nQuestState == QUEST_STATE_MISSON_INFO) then
		QuestFrameAcceptClicked()
	end

	Quest_Close();
	--取消关心
	StopCareObject_Quest(objCared);
end

--=========================================================
--拒绝任务
--=========================================================
function QuestRefuse_Clicked()
	if(g_nQuestState == QUEST_STATE_MISSON_INFO) then
		QuestFrameRefuseClicked()
	end

	Quest_Close();
	--取消关心
	StopCareObject_Quest(objCared);

	NpcShop:Close();

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_Quest(objCaredId)

	g_Object = objCaredId;

	this:CareObject(g_Object, 1, "Quest");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_Quest(objCaredId)
	this:CareObject(objCaredId, 0, "Quest");
	g_Object = -1;

end

--=========================================================
--播放音效
--=========================================================
function PlaySoundEffect()
	Sound:PlaySound( Get_XParam_INT(0), false );
end

--=========================================================
--播放背景音乐
--=========================================================
function PlayBackSound()
	Sound:PlaySound( Get_XParam_INT(0),false );
end

--=========================================================
--播放技能音乐
--=========================================================
function PlayEffectSound()
	Sound:PlaySoundEffect( Get_XParam_INT(0),false );
end


function CompareTable_Quest(table_a,table_b)
	if table_a[2] <= table_b[2] then
		return true
	else
		return false
	end
end

function Quest_Open()

	if IsWindowShow("Valentine") or IsWindowShow("ValentineConfirm") then
		this:Hide()
		return
	end

	this:Show();
	--CloseFreshManGuide()      --打开的时候关闭引导
	if(IsWindowShow("ChangyigeZigeCheck")) then
		 CloseWindow("ChangyigeZigeCheck", true);
	end
	
	if(IsWindowShow("Shop_Dresser")) then
		 CloseWindow("Shop_Dresser", true);
	end
end

function Quest_Close()
	this:Hide();
end

function OpenUrl( )
	GameProduceLogin:OpenURL(GetWeblink("WEB_INVITE"))
end

function OpenUrl_dfsjc()
    GameProduceLogin:OpenURL(GetWeblink("WEB_DFJC"))
end

function OpenUrl_dfsjc_always()
    GameProduceLogin:OpenURL(GetWeblink("WEB_DFJC_ALWAYS"))
end

function OpenUrl_DFSZB()
    OpenDFSZB(GetWeblink("WEB_DFSZB"))
end

function OpenUrl_JNH(which)
    if not which then return end
    if which < 1 or which > 2 then
        return
    end

    if which == 1 then
	    GameProduceLogin:OpenURL(GetWeblink("WEB_JIANIANHUAZB"))
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_JIANIANHUAZB2"))
        --OpenJNHZB(GetWeblink("WEB_JIANIANHUAZB2"))
    end
end

--点击宝贝回家计划链接
function OpenUrl_BBHJ()
	GameProduceLogin:OpenURL(GetWeblink("WEB_BAOBEIHUIJIA"))
end

--点击进入官网活动主页
function OpenUrl_WJHL_GUANWANG()
	GameProduceLogin:OpenURL(GetWeblink("WEB_WANJIAZHAOHUI"))
end

--点击进入官网活动主页
function OpenUrl_ChongLouBuChang()
	GameProduceLogin:OpenURL(GetWeblink("WEB_CLBCLJ"))
end

-- [URL]畅游VIP年末回馈领玄灵丹
function OpenURL_ChangYouVIPHuiKui()
	GameProduceLogin:OpenURL(GetWeblink("WEB_VIPHK"))
end

-- 【易容百变赢豪礼】
function OpenUrl_YRBBYHL()
	GameProduceLogin:OpenURL(GetWeblink("WEB_YRBBYHL"))
end


--网银充值活动官网
function OpenUrl_WANGYINCHONGZHI()
	GameProduceLogin:OpenURL(GetWeblink("WEB_WANGYINLINK"))
end

--【畅游金卡专题网站 by cys】
function OpenUrl_CYJINKA()
	GameProduceLogin:OpenURL(GetWeblink("WEB_JINKALINK"))
end

function OpenUrl_FOR_VIPGNHK()
	GameProduceLogin:OpenURL(GetWeblink("WEB_RENZHENGLINK"))
end


--龙门客栈官网论坛.网通
function OpenUrl_FOR_GWLT()
	GameProduceLogin:OpenURL(GetWeblink("WEB_GWLTLINK"))
end

--龙门客栈官网论坛.电信
function OpenUrl_FOR_GWLT_DX()
	GameProduceLogin:OpenURL(GetWeblink("WEB_GWLTLINK_DX"))
end

function Quest_Frame_ResetPos()
	Quest_Frame:SetProperty("UnifiedXPosition", g_Quest_Frame_UnifiedXPosition);
	Quest_Frame:SetProperty("UnifiedYPosition", g_Quest_Frame_UnifiedYPosition);
end

--争霸赛官网论坛
function OpenUrl_ZBS_GWLT()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ZBS_LINK"))
end

function OpenUrl_ROSE_VD()
	GameProduceLogin:OpenURL(GetWeblink("WEB_QIXI"))
end

--2012争霸赛官网论坛
function OpenUrl_2012ZBS_GWLT()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ZBS_LINK"))
end

--2018争霸赛官网论坛
function OpenUrl_2018ZBS_GWLT()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ZBS_LINK_2018"))
end

--2018争霸赛竞猜活动
function OpenUrl_2018ZBS_JingCai()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ZBSJC"))
end

function OpenUrl_WEIXINDAREN()
	GameProduceLogin:OpenURL(GetWeblink("WEB_WEIXINDAREN"))
end

--=========================================================
-- 侠义之心相关
--=========================================================
function Quest_ShowMonsterInfo()
	local leader = Player:IsLeader();
	local validLevel = 0
	if( leader == 1 ) then
		local iTeamCount = DataPool:GetTeamMemberCount();
		if iTeamCount < 0 or iTeamCount > 6 then
			return
		end
		local level = Player:GetData("LEVEL")

		local szNick;		-- 昵称
		local iFamily;	-- 门派
		local iLevel;	  -- 等级
		local bDeadlink;
		local bDead;
		local bSex;
		for i=0, iTeamCount-1 do
			-- 得到队员的详细信息
			szNick
			,iFamily
			,iLevel
			,bDead
			,bDeadlink
			,bSex
			= DataPool:GetTeamMemInfoByIndex( i );
			if iLevel >= 20 and iLevel <= 79 and
				 level >= iLevel + 20	then
				if iLevel > validLevel then
					validLevel = iLevel
				end
			end
		end
		if validLevel == 0 then--不存在有效玩家
			PushDebugMessage("#{LDX_100729_03}");
			return
		end
	else
		PushDebugMessage("#{LDX_100729_02}");
		return
	end
	--存在有效能贡献经验的玩家
	QuestGreeting_Desc:ClearAllElement()
	WRCollectVisiableContex( 2, tonumber(validLevel) )   --收集可见怪物信息
	local NumVisiable = tonumber( WRGetVisiableContexCount() )
	for i=0, NumVisiable-1 do
		local VisiableID = WRGetVisiableContexID( i )
		if( -1 ~= VisiableID ) then
			local strTitle = WRGetTitle( 2, VisiableID )

			local strTemp = strTitle.."&210,"..(VisiableID).."$0"--侠义之心特殊处理，将其设为210，防止冲突
	    QuestGreeting_Desc:AddOptionElement( strTemp );
		end
	end

end

--侠义之心
function Quest_DispatchContex( ContexIndex )
	if( ContexIndex < 0 ) then
		return
	end
	QuestGreeting_Desc:ClearAllElement()
	local strContex = WRGetVisiableContex( 2, ContexIndex )--获取怪物信息
	QuestGreeting_Desc:AddTextElement( strContex )

	local strBack = "#{INTERFACE_XML_602}".."&210,10360".."$0"--相当于点击我要去那里打怪
	QuestGreeting_Desc:AddOptionElement( strBack );
end

function Quest_Format(szFormat, ... )
	if string.sub( szFormat, 1, 2 ) ~= "#{" then
		return szFormat
	end

	if string.sub( szFormat, string.len( szFormat ) ) ~= "}" then
		return szFormat
	end

	if arg == nil then
		return szFormat
	end

 	local argLen = 0
	local szArg =""
	for i = 1, arg.n do
		argLen = string.len(arg[i])
		szArg = szArg .. "*" ..string.char(argLen) .. tostring(arg[i])
	end

	local szTemp = string.sub( szFormat, 1, string.len( szFormat ) - 1 )
	argLen = string.len(szArg)+3
	szTemp = szTemp.."*" ..string.char(arg.n)..string.char(argLen)..szArg.."}"

	if string.len(szTemp) > 255 then
	  return szFormat
	end
	return szTemp
end

function Quest_OpenSongliaoStatistic()
	local winner = Get_XParam_INT(0)
	local songLeaderName = Get_XParam_STR(0)
	local liaoLeaderName = Get_XParam_STR(1)
	if winner == nil or winner == -1 then--非正常结束不显示战场统计
		return
	end
	this:Show()
	if(IsWindowShow("ChangyigeZigeCheck")) then
		CloseWindow("ChangyigeZigeCheck", true);
	end
	Quest_Frame_Debug:SetText(" ")
	QuestGreeting_Desc:AddTextElement("#{SLDZ_100805_130}")--战场统计

	local strWinner = ""
	if winner == 0 then
		strWinner = "#{SLDZ_100805_118}"
	elseif winner == 1 then
		strWinner = "#{SLDZ_100805_119}"
	elseif winner == 2 then
		strWinner = "#{SLDZ_100805_118}".."、".. "#{SLDZ_100805_119}"
	else
		return
	end
	local msgWinner = Quest_Format("#{SLDZ_100805_184}",strWinner)
	QuestGreeting_Desc:AddTextElement(msgWinner)--胜利方：宋/辽

	local songScore,liaoScore=CSongliaoWarData:GetCampScore()
	if songLeaderName~=nil and songScore ~= nil then
		local msgSongScore = Quest_Format("#{SLDZ_100805_131}", tostring(songScore))
		QuestGreeting_Desc:AddTextElement(msgSongScore)--宋方积分
	end

	if liaoLeaderName~=nil and liaoScore~=nil then
		local msgLiaoScore = Quest_Format("#{SLDZ_100805_132}", tostring(liaoScore))
		QuestGreeting_Desc:AddTextElement(msgLiaoScore)--辽方积分
	end

	local ret1, charname1, camp1, score1 = CSongliaoWarData:GetScoreByIndex(0)
	local ret2, charname2, camp2, score2 = CSongliaoWarData:GetScoreByIndex(1)
	local ret3, charname3, camp3, score3 = CSongliaoWarData:GetScoreByIndex(2)

	if ret1~=nil and ret1==1 then
		local msgNo1 = Quest_Format("#{SLDZ_100805_133}",charname1.."  "..tostring(score1))
		QuestGreeting_Desc:AddTextElement(msgNo1)--第一名
	end
	if ret2~=nil and ret2==1 then
		local msgNo2 = Quest_Format("#{SLDZ_100805_134}",charname2.."  "..tostring(score2))
		QuestGreeting_Desc:AddTextElement(msgNo2)--第二名
	end
	if ret3~=nil and ret3==1 then
		local msgNo3 = Quest_Format("#{SLDZ_100805_135}",charname3.."  "..tostring(score3))
		QuestGreeting_Desc:AddTextElement(msgNo3)--第三名
	end

	local maxkillerName, maxkillCount = CSongliaoWarData:GetMaxKillNumData()
	if maxkillerName ~= nil and maxkillCount ~= nil then
		local msgMaxKillCount = Quest_Format("#{SLDZ_100805_137}",maxkillerName, tostring(maxkillCount))
		--QuestGreeting_Desc:AddTextElement(msgMaxKillCount)--战场最多击败
	end

	QuestGreeting_Desc:AddTextElement("#{SLDZ_100805_138}")--个人统计

	local myRet, myName, myCamp, myScore, mykillNum= CSongliaoWarData:GetMyScore()
	if myRet ~= nil and myRet == 1 then
		local msgMyScore = Quest_Format("#{SLDZ_100805_185}", tostring(myScore))
		QuestGreeting_Desc:AddTextElement(msgMyScore)--个人积分
		local msgMyKillNum = Quest_Format("#{SLDZ_100805_187}", tostring(mykillNum))
		--QuestGreeting_Desc:AddTextElement(msgMyKillNum)
	end

	QuestGreeting_Desc:AddTextElement("#{SLDZ_100805_228}")--小提示
	QuestGreeting_Desc:AddTextElement("#{SLDZ_100805_229}")-- 
	
end

function Quest_OpenSongliaoTips()
	this:Show()
	if(IsWindowShow("ChangyigeZigeCheck")) then
		CloseWindow("ChangyigeZigeCheck", true);
	end
	Quest_Button_Accept:Disable()
	Quest_Button_Continue:Disable();
	Quest_Button_Refuse:SetText("再见")
	Quest_Frame_Debug:SetText(" ")
	local tipmsg = Get_XParam_STR(0)
	QuestGreeting_Desc:AddTextElement(tipmsg)
end

function Quest_ShowCarriageHelp(msg)
	this:Show()
	Quest_Button_Accept:Disable()
	Quest_Button_Continue:Disable()
	Quest_Button_Refuse:SetText("关闭")
	Quest_Frame_Debug:SetText("#{TWLK_150804_167}")
	QuestGreeting_Desc:AddTextElement(msg)
end

--!!!reloadscript =Quest
function Quest_FreshManGuide(nType, nTextID, nPosID)
    if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end
    if Player:GetData("LEVEL") > 15 then
        return
    end

    local fX = 0
    local fY = 0
    local fW = 0
    local fH = 0
    local PosX = Quest_Frame:GetProperty("AbsoluteXPosition")
    local PosY = Quest_Frame:GetProperty("AbsoluteYPosition")
    g_CurActFlashType = nPosID
    if 1 == nPosID then      --1 is option item			初涉江湖
	fX, fY = this:GetChildOffset("QuestGreeting_Desc")
	fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
	fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
	fX = math.floor(fX + PosX + (fW * 0.5))
	fY = math.floor(fY + PosY + 168)
	g_CurActFlashType = nPosID
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
    elseif 2 == nPosID then  --2 is continue button
        fX, fY = this:GetChildOffset("Quest_Button_Continue")
        fW = tonumber(Quest_Button_Continue:GetProperty("AbsoluteWidth"))
	fH = tonumber(Quest_Button_Continue:GetProperty("AbsoluteHeight"))
	fX = fX + PosX + fW
	fY = math.floor(fY + PosY + (fH * 0.5))
	g_CurActFlashType = nPosID
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 18, 3, "Quest")
--      fX = fX + Quest_Button_Continue:GetProperty("AbsoluteWidth") / 2
    elseif 3 == nPosID then  --3 is accept button
        fX, fY = this:GetChildOffset("Quest_Button_Accept")
        fW = tonumber(Quest_Button_Accept:GetProperty("AbsoluteWidth"))
	fH = tonumber(Quest_Button_Accept:GetProperty("AbsoluteHeight"))
	fX = fX + PosX + fW
	fY = math.floor(fY + PosY + (fH * 0.5))
	g_CurActFlashType = nPosID
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 15, 3, "Quest")
--      fX = fX + Quest_Button_Accept:GetProperty("AbsoluteWidth") / 2
    elseif 4 == nPosID then  --3 is accept button		十年
        fX, fY = this:GetChildOffset("QuestGreeting_Desc")
	fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
	fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
	fX = math.floor(fX + PosX + (fW * 0.5))
	fY = math.floor(fY + PosY + 168)
	g_CurActFlashType = nPosID
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 5 == nPosID then --缘起无量
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5))
		fY = math.floor(fY + PosY + 100)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 6 == nPosID then
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5))
		fY = math.floor(fY + PosY + 80)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 23, 3, "Quest")
	elseif 7 == nPosID then  --路见不平
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) +20)
		fY = math.floor(fY + PosY + 115)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 8 == nPosID then  --武功招式
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) +20)
		fY = math.floor(fY + PosY + 100)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 9 == nPosID then  --并肩作战
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) +20)
		fY = math.floor(fY + PosY + 100)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 10 == nPosID then  --寡不敌众
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) +20)
		fY = math.floor(fY + PosY + 100)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 11 == nPosID then  --无量玉璧
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) +20)
		fY = math.floor(fY + PosY + 100)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 12 == nPosID then  --尔虞我诈
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) +20)
		fY = math.floor(fY + PosY + 100)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 13 == nPosID then  --城外相会
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) +20)
		fY = math.floor(fY + PosY + 100)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 14 == nPosID then  --珍兽商店
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 115)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 15 == nPosID then  --防具商店
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 45)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 16 == nPosID then  --拜访天师
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 165)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 17 == nPosID then  --武器商店
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 80)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 18 == nPosID then  --路见不平 经典版箭头指引坐标 -Manda
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 130)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 19 == nPosID then  --尔虞我诈 经典版箭头指引坐标 -Manda
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 115)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 20 == nPosID then  --珍兽商店 经典版箭头指引坐标 -Manda
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 130)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
	elseif 21 == nPosID then  --防具商店 经典版箭头指引坐标 -Manda
		fX, fY = this:GetChildOffset("QuestGreeting_Desc")
		fW = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteWidth"))
		fH = tonumber(QuestGreeting_Desc:GetProperty("AbsoluteHeight"))
		fX = math.floor(fX + PosX + (fW * 0.5) )
		fY = math.floor(fY + PosY + 60)
		g_CurActFlashType = nPosID
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 17, 3, "Quest")
    else
	    g_CurActFlashType = 0
        return               --unkown position
    end

    --OpenFreshManGuide(nType, nTextID, fX, fY, "Quest", "northeast")
    --PushDebugMessage("type:" .. nType .. ",x:" .. fX .. ",y:" .. fY .. ",w:" .. fW .. ",h:" .. fH .. ",QPX:" .. PosX .. ",QPY:" .. PosY)

end


--夫妻关系 by wangbin
function Quest_OpenFuQiDesc(infotype)
	--PushDebugMessage("type:"..infotype);
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	if infotype == "1" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{HYGX_150515_162}");
		QuestGreeting_Desc:AddTextElement( "#{HYGX_150515_163}")
	elseif infotype == "2" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{HYGX_150515_164}");
		QuestGreeting_Desc:AddTextElement( "#{HYGX_150515_165}")
		for i=1, 4 do
			local theAction = DataPool:CreateActionItemForShow(g_FuQi_Item[i].id, 1)
			--PushDebugMessage("theAction:"..theAction:GetID());
			if theAction:GetID() ~= 0 then
				QuestGreeting_Desc:AddActionElement(theAction:GetID(), 1, 0);
			end
		end
	elseif infotype == "3" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{DECOW_160126_5}");
		QuestGreeting_Desc:AddTextElement( "#{DECOW_160126_6}")
	end
	this:Show();
end
--家具银行
function Quest_OpenBieYeDesc(infotype)
	--PushDebugMessage("type:"..infotype);
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	if infotype ==  "1" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{BYFUR_160531_199}")
	elseif infotype == "2" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{BYFUR_160531_202}")	
		
	elseif infotype == "3" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{BYFUR_160531_209}")	
		
	elseif infotype == "4" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{BYFUR_160531_202}")	
	elseif infotype == "5" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{BFYH_170209_21}")	
	elseif infotype == "6" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{MCJC_170727_18}")	
	elseif infotype == "7" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{MCJC_170727_29}")	
	elseif infotype == "8" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{MCJC_170727_48}")		
	elseif infotype == "9" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."");
		QuestGreeting_Desc:AddTextElement( "#{MCJC_170727_132}")			
	end


	this:Show();
end

function Quest_OpenElectionHelp(infotype)
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	this:Show()
	if infotype == "0" then
		QuestGreeting_Desc:AddTextElement( "#{BHXJ_170606_39}")
	elseif infotype == "1" then
		QuestGreeting_Desc:AddTextElement( "#{BHXJ_170606_60}")		
	else
		this:Hide()
	end
	
end

function Quest_OpenCorpsHelp_2018(leadername)
	if leadername == nil or leadername == "" then
		return
	end
	
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	local tips = Quest_Format("#{WCBZ_180128_129}", leadername)
	QuestGreeting_Desc:AddTextElement( tips )
	this:Show()
	
end

function Quest_OpenCorpsHelp2_2018(memname)
	if memname == nil or memname == "" then
		return
	end
	
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	local myname = Player:GetName()
	local tips = Quest_Format("#{WCBZ_180128_134}", myname, memname)
	QuestGreeting_Desc:AddTextElement( tips )
	this:Show()
	
end

function Quest_OpenZhounianyuan_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(57) > 0 then
		QuestGreeting_Desc:AddTextElement( "#{HDRZ_220121_02}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{HDRZ_180322_149}" )
	end
	
	this:Show()
end


function Quest_OpenXuanZhanCD_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	local kajiType = KaJi:LuaFnGetKaJiType(1)
	local kaji_type = 0
	if nil~=kajiType then
		kaji_type = kajiType
	end
	if kaji_type == 0 then
		QuestGreeting_Desc:AddTextElement( "#{KVKBH_180531_69}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{KJFTS_210818_01}" )
	end


	this:Show()
end


function Quest_OpenJFMZ_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	local kajiType = KaJi:LuaFnGetKaJiType(101)
	if kajiType == 1 then
		QuestGreeting_Desc:AddTextElement( "#{JFMZ_220728_08}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{JFMZ_180801_16}" )
	end
	this:Show()
end

function Quest_OpenNational_Tree_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	local kajiType = KaJi:LuaFnGetKaJiType(110)
	if kajiType == 0 then 
        QuestGreeting_Desc:AddTextElement( "#{GQYJ_180818_38}" )
	else
        QuestGreeting_Desc:AddTextElement( "#{GQYJ_220817_28}" )
	end
	
	this:Show()
end

function Quest_OpenNational_Fund_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	QuestGreeting_Desc:AddTextElement( "#{GQJJ_190723_08}" )
	this:Show()
end

function Quest_OpenSiRiLi_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(52) > 0 then
		QuestGreeting_Desc:AddTextElement( "#{LYYJKJ_211210_1}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{LYYJ_181206_4}" )
	end
	this:Show()
end
function Quest_OpenBZSS_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(52) > 0 then
		QuestGreeting_Desc:AddTextElement( "#{LYYJKJ_211210_3}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{LYYJ_181206_2}" )
	end
	this:Show()
end

function Quest_OpenGSNPCShop_Help( shopindex )
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("#{GSHB_190801_90}");
	if shopindex == 8 then
		QuestGreeting_Desc:AddTextElement( "#{GXDJ_200323_51}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{GSHB_190801_23}" )
	end
	this:Show()
end

function Quest_OpenShangFeng_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	if KaJi:LuaFnGetKaJiType(97) == 1 then
		QuestGreeting_Desc:AddTextElement( "#{QFGS_220725_01}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{QFGS_180807_11}" )
	end
	this:Show()
end

function Quest_OpenLeagueInfoDesc(infotype)
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	if infotype == "0" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{SLJC_150811_772}");
		QuestGreeting_Desc:AddTextElement( "#{SLJC_150811_748}")
	elseif infotype == "1" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{SLJC_150811_773}");
		QuestGreeting_Desc:AddTextElement( "#{SLJC_150811_750}")
	elseif infotype == "2" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{SLJC_150811_774}");
		QuestGreeting_Desc:AddTextElement( "#{SLJC_150811_752}")
	elseif infotype == "3" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{MZBUILD_150817_436}");
		QuestGreeting_Desc:AddTextElement( "#{MZBUILD_150817_377}")
	elseif infotype == "4" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{MZBUILD_150817_437}");
		QuestGreeting_Desc:AddTextElement( "#{MZBUILD_150817_378}")
	elseif infotype == "5" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{MZBUILD_150817_438}");
		QuestGreeting_Desc:AddTextElement( "#{MZBUILD_150817_379}")
	elseif infotype == "6" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{MZBUILD_150817_439}");
		QuestGreeting_Desc:AddTextElement( "#{MZBUILD_150817_380}")
	elseif infotype == "7" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{SLJC_150811_789}");
		QuestGreeting_Desc:AddTextElement( "#{SLJC_150811_790}")
	elseif infotype == "8" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{SLJC_150811_786}");
		QuestGreeting_Desc:AddTextElement( "#{SLJC_150811_787}")
	elseif infotype == "9" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{SLJC_150811_798}");
		QuestGreeting_Desc:AddTextElement( "#{SLJC_150811_799}")
	elseif infotype == "10" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{SLJC_150811_853}");
		QuestGreeting_Desc:AddTextElement( "#{SLJC_150811_854}")	
	elseif infotype == "11" then
		Quest_Frame_Debug:SetText("#gFF0FA0".."#{ZMMXZ_160603_3}");
		QuestGreeting_Desc:AddTextElement( "#{ZMMXZ_160603_4}")	
	end
	this:Show();
end

function Quest_FreshManNpcChat(nType)
	PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",  nType)
end

function Quest_ShowFreshManRect(nType)
	if g_ShowRect < 1 then
		return
	end

	if nType > 0 and nType < 3 then
		local nPosX = tonumber(Quest_Frame:GetProperty("AbsoluteXPosition"))
		local nPosY = tonumber(Quest_Frame:GetProperty("AbsoluteYPosition"))

		local fX, fY = this:GetChildOffset("QuestGreeting_Desc")

		fX = tonumber(fX + nPosX)
		fY = tonumber(fY + nPosY) + 150
		PushEvent("OPEN_FRESHMANGUIDE_QUESTPOINT", "Quest", nType, fX, fY)
	end
end


function Quest_NewShowFreshManRect(nType)
	if g_ShowRect < 1 then
		return
	end

	if nType > 0 and nType < 4 then
		local nPosX = tonumber(Quest_Frame:GetProperty("AbsoluteXPosition"))
		local nPosY = tonumber(Quest_Frame:GetProperty("AbsoluteYPosition"))

		local fX, fY = this:GetChildOffset("QuestGreeting_Desc")

		fX = tonumber(fX + nPosX)
		fY = tonumber(fY + nPosY) + 80
		PushEvent("OPEN_FRESHMANGUIDE_QUESTPOINT", "Quest", nType, fX, fY)
	end
end

function Quest_OnMoved()
    if "Quest" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
	Quest_FreshManGuide(2, -1, g_CurActFlashType)
	if g_ShowRect > 0 then
		Quest_ShowFreshManRect(2)
	end
        --OpenFreshManGuide(2, -1, -1, -1)
    end
end
function Quest_OnHidden()
    if "Quest" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
	g_ShowRect = 0
    end
end

--家园引导任务反馈信息
function Quest_JiaYuanMissionReturn(ntype)
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:SetText("关闭")
	QuestGreeting_Desc:ClearAllElement();
	if ntype ==  1 then
		Quest_Frame_Debug:SetText("#Y".."何闲庭");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_323}")
	elseif ntype == 2 then
		Quest_Frame_Debug:SetText("#Y".."1号采石场");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_325}")	
	elseif ntype == 3 then
		Quest_Frame_Debug:SetText("#Y".."1号苗圃");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_329}")	
	elseif ntype == 4 then
		Quest_Frame_Debug:SetText("#Y".."何翁");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_334}")	
	elseif ntype == 5 then
		Quest_Frame_Debug:SetText("#Y".."贾满达");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_337}")	
	elseif ntype == 6 then
		Quest_Frame_Debug:SetText("#Y".."鲁家财");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_341}")
	elseif ntype == 71 then
		Quest_Frame_Debug:SetText("#Y".."鲁家财");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_345}")
	elseif ntype == 72 then
		Quest_Frame_Debug:SetText("#Y".."苓香");
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_346}")
	elseif ntype == 8 then
		Quest_Frame_Debug:SetText("#Y".."何闲庭")
		QuestGreeting_Desc:AddTextElement( "#{JYWYD_161024_353}")
	end

	this:Show();
end

function Quest_ShowEngageSucInfo(msg)
	this:Show()
	Quest_Button_Accept:Disable()
	Quest_Button_Continue:Disable()
	Quest_Button_Refuse:SetText("再见")

	local msgShow = Quest_Format("#{BWZQ_160623_384}", msg, msg, msg, msg)
	Quest_Frame_Debug:SetText("#{BWZQ_160623_393}")
	QuestGreeting_Desc:AddTextElement(msgShow)
end

function Quest_ShowNewServerBoxInfo(msg)
	this:Show()
	Quest_Button_Accept:Disable()
	Quest_Button_Continue:Disable()
	Quest_Button_Refuse:SetText("再见")
	Quest_Frame_Debug:SetText("#{SXZ_210106_03}")
	QuestGreeting_Desc:AddTextElement(msg)
end

function Quest_ShowZhouNianYuanMsg(nCount)
	this:Show()
	Quest_Button_Accept:Disable()
	Quest_Button_Continue:Disable()
	Quest_Button_Refuse:SetText("关闭")
	Quest_Frame_Debug:SetText("")
		
	local msgShow =""
	if nCount == 1000 then
		msgShow = "#{HDRZ_180322_111}"	
	end
	QuestGreeting_Desc:AddTextElement(msgShow)
end

function Quest_HuodongText_Help(ntype, strTips)
	if not ntype or not strTips then 
		PushDebugMessage("Quest_HuodongText_Help Param No nil  ntype:"..(ntype or "nil").." strTips:"..(strTips or "nil"));
	end
	--if this:IsVisible() then return end
	if strTips == "" then this:Hide() return end
	this:Show()
	Quest_Button_Accept:Disable()
	Quest_Button_Continue:Disable()
	Quest_Frame_Debug:SetText("")
	Quest_Button_Refuse:SetText("关闭")

	QuestGreeting_Desc:ClearAllElement();
	QuestGreeting_Desc:AddTextElement(strTips)
end

function Quest_CCSHP_Help(nIndex)
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");

	if nIndex == "1" then
		QuestGreeting_Desc:AddTextElement( "#{ZHHD1_181128_181}" )
	elseif nIndex == "2" then
		QuestGreeting_Desc:AddTextElement( "#{ZHHD1_181128_175}" )
	elseif nIndex == "3" then
		QuestGreeting_Desc:AddTextElement( "#{ZHHD1_181128_192}" )	
	elseif nIndex == "70" then
		-- 借一下地方用 祈愿 新活跃 
		QuestGreeting_Desc:AddTextElement( "#{MRQD_210708_12}" )
	elseif nIndex == "71" then
		-- 借一下地方用 巅峰赛锦鲤 阶段1
		QuestGreeting_Desc:AddTextElement( "#{ZQJL_190725_28}" )
	elseif nIndex == "72" then
		-- 借一下地方用 巅峰赛锦鲤 阶段2
		QuestGreeting_Desc:AddTextElement( "#{ZQJL_190725_124}" )
	elseif nIndex == "73" then
		-- 借一下地方用 巅峰赛锦鲤 阶段一的右下角说明
		QuestGreeting_Desc:AddTextElement( "#{ZQJL_190725_53}" )
	elseif nIndex == "74" then
		-- 借一下地方用 中秋锦鲤 阶段2 奖励2 问号
		-- QuestGreeting_Desc:AddTextElement( "#{ZQJL_190725_275}" )
	elseif nIndex == "75" then
		-- 借一下地方用 中秋锦鲤 阶段2 奖励3 问号
		-- QuestGreeting_Desc:AddTextElement( "#{ZQJL_190725_276}" )
	elseif nIndex == "97" then
		-- 借一下地方用 七夕瓜分活动 激活界面
		QuestGreeting_Desc:AddTextElement( "#{QQFW_190620_90}" )	
	elseif nIndex == "98" then 
		-- 借一下地方用 七夕瓜分活动 展示界面
		QuestGreeting_Desc:AddTextElement( "#{QQFW_190620_42}" )	
	elseif nIndex == "99" then
		-- 借一下地方用 周年庆预热访仙活动 
		QuestGreeting_Desc:AddTextElement( "#{ZNTZ_190318_04}" )	
	elseif nIndex == "100" then
		QuestGreeting_Desc:AddTextElement( "#{MSZJ_190325_32}" )	
	elseif nIndex == "101" then
		if KaJi:LuaFnGetKaJiType(56) == 1 then
			QuestGreeting_Desc:AddTextElement( "#{SWZB_220119_01}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{SWZB_190322_08}" )
		end
	elseif nIndex == "102" then
		QuestGreeting_Desc:AddTextElement( "#{QHNF_190429_107}" )
	elseif nIndex == "103" then
		local kajiType = KaJi:LuaFnGetKaJiType(108)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{GQHY_220818_01}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{GQHY_190723_29}" )
		end
	elseif nIndex == "104" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_205}" )
	elseif nIndex == "105" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_206}" )
	elseif nIndex == "106" then
		local curDay = tonumber(DataPool:GetServerDayTime());
		local year,month,day = GetHuoyueDaibiCleanTime(curDay)	
		QuestGreeting_Desc:AddTextElement( ScriptGlobal_Format("#{JBHL_190803_208}", year,month,day) )
	elseif nIndex == "107" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_209}" )
	elseif nIndex == "108" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_210}" )
	elseif nIndex == "109" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_211}" )
	elseif nIndex == "110" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_212}" )
	elseif nIndex == "111" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_227}" )
	elseif nIndex == "112" then
		QuestGreeting_Desc:AddTextElement( "#{JBHL_190803_256}" )
	elseif nIndex == "113" then
		QuestGreeting_Desc:AddTextElement( "#{XGSZ_200317_38}" )
	elseif nIndex == "114" then
		local curDay = tonumber(DataPool:GetServerDayTime());
		local year,month,day = GetHuoyueDaibiCleanTime(curDay)	
		QuestGreeting_Desc:AddTextElement( ScriptGlobal_Format("#{JBHL_190803_421}", year,month,day) )
	elseif nIndex == "115" then --2020西瓜节活动攻略
		QuestGreeting_Desc:AddTextElement( "#{XGZH_200628_69}" )
	elseif nIndex == "116" then --2020西瓜节活动攻略
		QuestGreeting_Desc:AddTextElement( "#{QXZH_200708_27}" )
	elseif nIndex == "117" then
		QuestGreeting_Desc:AddTextElement( "#{ZQQF_190724_24}" )
	elseif nIndex == "118" then 
		QuestGreeting_Desc:AddTextElement( "#{RCLS_200731_23}" )
	elseif nIndex == "119" then 
		QuestGreeting_Desc:AddTextElement( "#{RCLS_200731_79}" )
	elseif nIndex == "120" then 
		local kjtype   = KaJi:LuaFnGetKaJiType(96)
		if kjtype == 1 then
			QuestGreeting_Desc:AddTextElement( "#{JFZH_220615_11}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{JFZH_200708_86}" )
		end
	elseif nIndex == "121" then 
		QuestGreeting_Desc:AddTextElement( "#{PTLS_200902_14}" )
	elseif nIndex == "122" then 
		QuestGreeting_Desc:AddTextElement( "#{PTLS_200902_14}" )
	elseif nIndex == "123" then
		QuestGreeting_Desc:AddTextElement( "#{YRBS_200902_22}" )
	elseif nIndex == "124" then
		QuestGreeting_Desc:AddTextElement( "#{ZGMW_201009_71}" )
	elseif nIndex == "125" then
		QuestGreeting_Desc:AddTextElement( "#{ZGMW_201009_72}" )
	elseif nIndex == "126" then
		QuestGreeting_Desc:AddTextElement( "#{JJXH_201207_12}" )
	elseif nIndex == "127" then
		QuestGreeting_Desc:AddTextElement( "#{CJTS_200104_05}" )
	elseif nIndex == "128" then--【2020Q4】春节-兑换千里江山时装活动--兑换千里江山时装礼盒
		QuestGreeting_Desc:AddTextElement( "#{DHSZ_201218_10}" )
	elseif nIndex == "129" then
		QuestGreeting_Desc:AddTextElement( "#{SYCY_201225_18}" )
	elseif nIndex == "130" then
		QuestGreeting_Desc:AddTextElement( "#{FWQJD_210114_04}" )
	elseif nIndex == "131" then
		QuestGreeting_Desc:AddTextElement( "#{ZJWF_201231_10}" )
	elseif nIndex == "132" then
		QuestGreeting_Desc:AddTextElement( "#{ZNYR_20210318_14}" )
	elseif nIndex == "133" then
		QuestGreeting_Desc:AddTextElement( "#{YMTB_210520_12}" )
	elseif nIndex == "134" then
		QuestGreeting_Desc:AddTextElement( "#{XMPYRFF_210826_10}" )
	elseif nIndex == "135" then--2021双旦集五福
		if KaJi:LuaFnGetKaJiType(33) == 1 then
			QuestGreeting_Desc:AddTextElement( "#{FHSX_211019_111}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{FHSX_211019_17}" )
		end
	elseif nIndex == "136" then--2021双旦集五福
		if KaJi:LuaFnGetKaJiType(33) == 1 then
			QuestGreeting_Desc:AddTextElement( "#{FHSX_211019_116}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{FHSX_211019_105}" )
		end
	elseif nIndex == "137" then--2021双旦飞花解意
		QuestGreeting_Desc:AddTextElement( "#{FHJY_211025_07}" )
	elseif nIndex == "138" then --2024春节时装获取
		QuestGreeting_Desc:AddTextElement( "#{CJSZ_231030_04}" )	
	elseif nIndex == "139" then--2021踏雪
		local kajiType = KaJi:LuaFnGetKaJiType(118)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement("#{SDQY_211126_01}")
		else
			QuestGreeting_Desc:AddTextElement("#{SDQY_211101_04}")
		end	
	elseif nIndex == "140" then
		local kajiType = KaJi:LuaFnGetKaJiType(31)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{YDHD_211126_01}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{YDHD_171206_05}" )
		end
	elseif nIndex == "141" then
		if KaJi:LuaFnGetKaJiType(53) == 1 then
			QuestGreeting_Desc:AddTextElement( "#{JZZH_211125_62}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{JZZH_211125_22}" )
		end
	elseif nIndex == "142" then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			QuestGreeting_Desc:AddTextElement( "#{CJYJ_211203_221}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{CJYJ_211203_170}" )
		end
	elseif nIndex == "143" then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			QuestGreeting_Desc:AddTextElement( "#{CJYJ_211203_220}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{CJYJ_211203_139}" )
		end
	elseif nIndex == "144" then
		QuestGreeting_Desc:AddTextElement( "#{CJYJ_211203_205}" )
	elseif nIndex == "145" then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			QuestGreeting_Desc:AddTextElement( "#{HZYR_211222_82}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{HZYR_211222_7}" )
		end
	elseif nIndex == "146" then
		QuestGreeting_Desc:AddTextElement( "#{CJWH_211125_10}" )
	elseif nIndex == "147" then
		QuestGreeting_Desc:AddTextElement( "#{CJWH_211125_33}" )
	elseif nIndex == "148" then	
		if KaJi:LuaFnIsKaJiServer() == 1 then
			QuestGreeting_Desc:AddTextElement( "#{YXSJ_251205_03}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{YXSJ_181204_4}" )
		end
	elseif nIndex == "149" then
		--2025元宵节猜灯谜-ypl
		local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(171) > 0 then  --卡级		
			QuestGreeting_Desc:AddTextElement( "#{YXCDM_251210_03}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{YXCDM_161114_5}" )
		end
	elseif nIndex == "150" then
		local pEndTime = Lua_GetGuanHuaiJueQingGuDate()
		local dpEndYear= math.floor(pEndTime/100000000)
		local EndMonth = math.mod(math.floor(pEndTime/1000000),100)
		local EndDay   = math.mod(math.floor(pEndTime/10000),100) 
		local EndHour  = math.mod(math.floor(pEndTime/100),100)  
		QuestGreeting_Desc:AddTextElement(ScriptGlobal_Format("#{JQGFC_220115_127}", dpEndYear, EndMonth, EndDay, EndHour))	
	elseif nIndex == "151" then
		local pEndTime = Lua_GetGuanHuaiJueQingGuDate()
		local dpEndYear= math.floor(pEndTime/100000000)
		local EndMonth = math.mod(math.floor(pEndTime/1000000),100)
		local EndDay   = math.mod(math.floor(pEndTime/10000),100) 
		local EndHour  = math.mod(math.floor(pEndTime/100),100) 
		QuestGreeting_Desc:AddTextElement(ScriptGlobal_Format("#{JQGFC_220115_128}", dpEndYear,EndMonth, EndDay, EndHour))	
	elseif nIndex == "152" then
		QuestGreeting_Desc:AddTextElement( "#{SHH_211221_08}" )
	elseif nIndex == "153" then
		local kajiType = KaJi:LuaFnGetKaJiType(62)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{XMJH_220121_51}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{XMJH_220121_50}" )
		end
	elseif nIndex == "154" then--2022熊猫外观
		QuestGreeting_Desc:AddTextElement( "#{XMZH_20220120_09}" )
	elseif nIndex == "155" then
		QuestGreeting_Desc:AddTextElement( "#{SHH_211221_83}" )
	elseif nIndex == "156" then
		QuestGreeting_Desc:AddTextElement( "#{ZHGJ_211227_09}" )
	elseif nIndex == "157" then
		QuestGreeting_Desc:AddTextElement( "#{ZHGJ_211227_10}" )
	elseif nIndex == "158" then
		QuestGreeting_Desc:AddTextElement( "#{XXSD_220209_12}" )
	elseif nIndex == "159" then --2022熊猫外观--时装获得方式
		QuestGreeting_Desc:AddTextElement( "#{XMZH_20220120_48}" )	
	elseif nIndex == "160" then --
		QuestGreeting_Desc:AddTextElement( "#{XKKSC_220112_246}" )	
	elseif nIndex == "161" then --【2022Q2】儿童节代币转换--代币获取途径
		if Player:GetData("IsOriginalJD") == 1 then
			QuestGreeting_Desc:AddTextElement( "#{DBZH_260507_1}" )
		else
			local g_KJ_ERTONGJIEDAIBI = 84--卡级服
			if KaJi:LuaFnGetKaJiType(g_KJ_ERTONGJIEDAIBI) == 1 then--卡级服
				QuestGreeting_Desc:AddTextElement( "#{DBZH_220419_75}" )
			else
				QuestGreeting_Desc:AddTextElement( "#{DBZH_220419_29}" )
			end
		end
	elseif nIndex == "162" then
		local kajiType = KaJi:LuaFnGetKaJiType(83)
		if Player:GetData("IsOriginalJD") == 1 then
			kajiType = 1
		end
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{XGJHD_220427_03}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{XGJHD_220427_02}" )
		end	
	elseif nIndex == "163" then
		local kajiType = KaJi:LuaFnGetKaJiType(83)
		if Player:GetData("IsOriginalJD") == 1 then
			kajiType = 1
		end
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{XGJHD_220427_31}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{XGJHD_220427_30}" )
		end	
	elseif nIndex == "164" then --七夕送信
		QuestGreeting_Desc:AddTextElement( "#{QXJSX_20220525_09}" )	
	elseif nIndex == "165" then
		local kajiType = KaJi:LuaFnGetKaJiType(89)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{FBQY_220601_07}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{FBQY_220601_06}" )
		end
	elseif nIndex == "166" then
		QuestGreeting_Desc:AddTextElement( "#{QXTB_220610_11}" )
	elseif nIndex == "167" then
		Quest_LianXuQiRi_Help()
	elseif nIndex == "168" then
		QuestGreeting_Desc:AddTextElement( "#{ZYDL_20220711_10}" )
	elseif nIndex == "169" then
		local specKaJi89 = Player : GetData("SPECKAJI89") 
		if specKaJi89 == 0 then
			local misData = DataPool:GetPlayerMission_DataRound(3216)
			if misData ~= 2 then
				QuestGreeting_Desc:AddTextElement( "#{GCQH_240429_158}" )
			else
				QuestGreeting_Desc:AddTextElement( "#{BZTX_250507_12}" )
			end
		else
			QuestGreeting_Desc:AddTextElement( "#{TYCZ_240513_17}" )
		end
	elseif nIndex == "170" then--2022Q3新天外服务器进度活动--进度界面
		QuestGreeting_Desc:AddTextElement( "#{TWFW_220802_09}" )
	elseif nIndex == "171" then --2022Q3新天外预热活动-ypl
		QuestGreeting_Desc:AddTextElement( "#{XTWYR_220729_11}" )		
	elseif nIndex == "172" then
		QuestGreeting_Desc:AddTextElement( "#{FMPM_220815_09}" )
	elseif nIndex == "173" then
		QuestGreeting_Desc:AddTextElement( "#{SCBHPM_20220815_07}" )
	elseif nIndex == "174" then
		QuestGreeting_Desc:AddTextElement( "#{BZTX_220705_46}" )
	elseif nIndex == "175" then
		QuestGreeting_Desc:AddTextElement( "#{QRJJN_221118_10}" )
	elseif nIndex == "176" then --卯兔闹春
		QuestGreeting_Desc:AddTextElement( "#{MTNC_221101_12}" )
	elseif nIndex == "177" then --萌兔闹西京
		QuestGreeting_Desc:AddTextElement( "#{YTZ_20221107_150}" )
	elseif nIndex == "178" then --萌兔闹西京
		QuestGreeting_Desc:AddTextElement( "#{QRJH_20221109_11}" )
	elseif nIndex == "179" then --卯兔闹春
		QuestGreeting_Desc:AddTextElement( "#{MTNC_221101_86}" )
	elseif nIndex == "180" then --新服悬赏任务
		QuestGreeting_Desc:AddTextElement( "#{XFXS_201231_28}" )
	elseif nIndex == "181" then --zypvp
		QuestGreeting_Desc:AddTextElement( "#{ZYZC_220213_49}" )
	elseif nIndex == "182" then --2023Q1新服欢乐月-喜迎财神到
		QuestGreeting_Desc:AddTextElement( "#{XYCSD_230203_7}" )
	elseif nIndex == "183" then --周年庆拉收 大富翁
		QuestGreeting_Desc:AddTextElement( "#{ZNLSG_230215_20}" )
	elseif nIndex == "184" then --周年庆刷新集市
		if 1 == Player:GetData("IsOriginalJD") then
			QuestGreeting_Desc:AddTextElement( "#{ZNJS_260330_1}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{ZNJS_230220_28}" )
		end
	elseif nIndex == "185" then --周年庆刷新集市kaji
		QuestGreeting_Desc:AddTextElement( "#{ZNJS_230220_29}" )
	elseif nIndex == "186" then	-- 2023Q1城战奖励升级
		QuestGreeting_Desc:AddTextElement( "#{CZSJ_230301_09}" )
	elseif nIndex == "187" then	-- 帮会活跃
		local kajiType = KaJi:LuaFnGetKaJiType(124)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{BHHYRW_230301_20}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{BHHYRW_230301_19}" )
		end
	elseif nIndex == "188" then	-- 周年庆降鸿福
		local kajiType = KaJi:LuaFnGetKaJiType(67)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{TJHF_180310_14}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{TJHF_140226_06}" )
		end
	elseif nIndex == "189" then	--金蚕丝
		QuestGreeting_Desc:AddTextElement( "#{JSXL_230224_1}" )
	elseif nIndex == "190" then
		Quest_LianXuQiRi_Help_New()
	elseif nIndex == "191" then	-- 2023Q1城战奖励升级
		QuestGreeting_Desc:AddTextElement( "#{ZNXY_150202_11}" )
	elseif nIndex == "192" then	-- 周年庆刷新集市 概况小问号
		QuestGreeting_Desc:AddTextElement( "#{ZNJS_230220_199}" )
	elseif nIndex == "193" then	-- 特权商店帮助
		QuestGreeting_Desc:AddTextElement( "#{TQSD_230201_74}" )
	elseif nIndex == "194" then	-- 2023Q2非遗签到活动
		QuestGreeting_Desc:AddTextElement( "#{FYHD_230414_20}" )
	elseif nIndex == "195" then --盛景繁绘
		local kajiType = KaJi:LuaFnGetKaJiType(135)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{SJFH_230425_11}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{SJFH_230425_10}" )
		end
	elseif nIndex == "196" then	-- 2023西瓜商店
		local kajiType = KaJi:LuaFnGetKaJiType(137)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{XGJSD_230526_52}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{XGJSD_230526_09}" )
		end
	elseif nIndex == "197" then	-- 天机城
		QuestGreeting_Desc:AddTextElement( "#{TJZF_230525_33}" )
	elseif nIndex == "198" then	-- 内丹商店
		QuestGreeting_Desc:AddTextElement( "#{NDSD_20230510_6}" )
	elseif nIndex == "199" then	-- 宗门预热活动		
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(140) > 0 then  --卡级
			QuestGreeting_Desc:AddTextElement( "#{ZMYR_230803_25}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{ZMYR_230803_24}" )
		end
	elseif nIndex == "200" then	-- 宗门拜访
		QuestGreeting_Desc:AddTextElement( "#{ZMHD_230801_26}" )
	elseif nIndex == "201" then	-- 
		QuestGreeting_Desc:AddTextElement( "#{ZMPT_230629_05}" )
	elseif nIndex == "202" then
		if 1 == Player:GetData("Is2606S") then
			QuestGreeting_Desc:AddTextElement( "#{QXDZJY_260707_12}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{HSLX_230720_49}" )
		end
	elseif nIndex == "203" then
		if 1 == Player:GetData("Is2606S") then
			QuestGreeting_Desc:AddTextElement( "#{QXDZJY_260707_12}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{HSLX_230720_62}" )
		end
	elseif nIndex == "204" then
		QuestGreeting_Desc:AddTextElement( "#{ZMDZ_230703_26}" )
	elseif nIndex == "205" then
		QuestGreeting_Desc:AddTextElement( "#{DJWH_231201_18}" )
	elseif nIndex == "206" then
		if 1 == Player:GetData("Is2606S") then
			QuestGreeting_Desc:AddTextElement( "#{QXFZMB_260622_4}" )
		else
			local kjtype   = KaJi:LuaFnGetKaJiType(147)
			if kjtype == 1 then
				QuestGreeting_Desc:AddTextElement( "#{ZMB_230124_168}" )
			else
				QuestGreeting_Desc:AddTextElement( "#{ZMB_230124_167}" )
			end
		end
		
		
	--2024周年庆预热活动设计
	elseif nIndex == "207" then
		QuestGreeting_Desc:AddTextElement( "#{LYJB_240222_13}" )		
	elseif nIndex == "209" then
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(149) > 0 then
			QuestGreeting_Desc:AddTextElement( "#{YZWXS_240319_39}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{YZWXS_240319_19}" )
		end
	elseif nIndex == "210" then
			QuestGreeting_Desc:AddTextElement( "#{DFFX_20240515_6}" )
	elseif nIndex == "211" then
		QuestGreeting_Desc:AddTextElement( "#{DHSD_20240522_65}" )	
	elseif nIndex == "212" then
		QuestGreeting_Desc:AddTextElement( "#{DHYR_240515_26}" )	
	elseif nIndex == "213" then
		QuestGreeting_Desc:AddTextElement( "#{XZXT_240517_13}" )	
	elseif nIndex == "214" then

		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(98) > 0 then
			QuestGreeting_Desc:AddTextElement( "#{JFLZ_220713_1}" )	
		else
			QuestGreeting_Desc:AddTextElement( "#{JFLZ_180806_4}" )	
		end
	elseif nIndex == "215" then
		if KaJi:LuaFnIsKaJiServer() == 1 then
			QuestGreeting_Desc:AddTextElement( "#{FHCL_260116_04}" )	
		elseif Player:GetData("Is2606S") == 1 then
			QuestGreeting_Desc:AddTextElement( "#{FHCL_260626_01}" )	
		else
			QuestGreeting_Desc:AddTextElement( "#{FHCL_240708_9}" )	
		end
		
	elseif nIndex == "216" then
		QuestGreeting_Desc:AddTextElement( "#{FHCL_240708_334}" )	
	elseif nIndex == "217" then
		QuestGreeting_Desc:AddTextElement( "#{RXLB_240709_05}" )	
	elseif nIndex == "218" then
		QuestGreeting_Desc:AddTextElement( "#{DHLS_240611_06}" )	
	elseif nIndex == "219" then-- 2024Q3版本稳活活动
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(156) > 0 then
			QuestGreeting_Desc:AddTextElement( "#{ERWH_240719_428}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{ERWH_240719_09}" )
		end
	elseif nIndex == "220" then--  
		QuestGreeting_Desc:AddTextElement( "#{DHLS_240611_107}" )
	elseif nIndex == "221" then--  
		local pEndTime = Lua_GetGuanHuaiJueQingGuDate()
		local dpEndYear= math.floor(pEndTime/100000000)
		local EndMonth = math.mod(math.floor(pEndTime/1000000),100)
		local EndDay   = math.mod(math.floor(pEndTime/10000),100) 
		local EndHour  = math.mod(math.floor(pEndTime/100),100)  
		QuestGreeting_Desc:AddTextElement(ScriptGlobal_Format("#{JQGFC_240926_02}", dpEndYear, EndMonth, EndDay, EndHour))	
	elseif nIndex == "222" then--  
		local pEndTime = Lua_GetGuanHuaiJueQingGuDate()
		local dpEndYear= math.floor(pEndTime/100000000)
		local EndMonth = math.mod(math.floor(pEndTime/1000000),100)
		local EndDay   = math.mod(math.floor(pEndTime/10000),100) 
		local EndHour  = math.mod(math.floor(pEndTime/100),100)  
		QuestGreeting_Desc:AddTextElement(ScriptGlobal_Format("#{JQGFC_240926_03}", dpEndYear,EndMonth, EndDay, EndHour))	
	elseif nIndex == "223" then--  
		local pEndTime = Lua_GetGuanHuaiJueQingGuDate()
		local dpEndYear= math.floor(pEndTime/100000000)
		local EndMonth = math.mod(math.floor(pEndTime/1000000),100)
		local EndDay   = math.mod(math.floor(pEndTime/10000),100) 
		local EndHour  = math.mod(math.floor(pEndTime/100),100)  
		QuestGreeting_Desc:AddTextElement(ScriptGlobal_Format("#{JQGFC_240926_04}", dpEndYear,EndMonth, EndDay, EndHour))	
	elseif nIndex == "224" then
		QuestGreeting_Desc:AddTextElement( "#{FPLS_240715_14}" )
	elseif nIndex == "225" then-- 2024Q4冰雪节答题活动
		QuestGreeting_Desc:AddTextElement( "#{DXDT_240920_06}" )
	elseif nIndex == "226" then -- 
		local kajiType = KaJi:LuaFnGetKaJiType(162)
		if kajiType == 1 then
			QuestGreeting_Desc:AddTextElement( "#{BXDK_240909_103}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{BXDK_240909_06}" )
		end
	elseif nIndex == "227" then-- 2024Q4冰雪节答题活动
		QuestGreeting_Desc:AddTextElement( "#{DXDT_240920_08}" )
	elseif nIndex == "228" then-- 
		QuestGreeting_Desc:AddTextElement( "#{BXDR_20240920_78}" )
	elseif nIndex == "229" then
		QuestGreeting_Desc:AddTextElement( "#{BXZP_240911_113}" )
	elseif nIndex == "230" then
		QuestGreeting_Desc:AddTextElement( "#{BXJD_241118_37}" )
	elseif nIndex == "231" then
		QuestGreeting_Desc:AddTextElement( "#{BXJD_241118_41}" )
	elseif nIndex == "232" then
		if Player:GetData("IsOriginalJD") == 1 then
			local myZoneWorld = DataPool:GetSelfZoneWorldID()
			if myZoneWorld == 5176 then
				QuestGreeting_Desc:AddTextElement( "#{HBF_260515_28}" ) 
			else
				QuestGreeting_Desc:AddTextElement( "#{HBF_250126_01}" )
			end
			
		else			
			QuestGreeting_Desc:AddTextElement( "#{HBF_241219_122}" )
		end
	elseif nIndex == "233" then
		QuestGreeting_Desc:AddTextElement( "#{HBF_241219_123}" )
	--2025周年庆预热活动
	elseif nIndex == "234" then
		QuestGreeting_Desc:AddTextElement( "#{XKYR_250310_10}" )
	elseif nIndex == "235" then
		local nOpenBoss,beginTime,EndTime = DataPool:Lua_OpenNewServerBoss()

		local nBeginYear =  math.floor(beginTime/10000)
		local nBeginTemp = math.mod(beginTime,10000)
		local nBeginMonth =  math.floor(nBeginTemp/100)
		local nBeginDay = math.mod(beginTime,100)
	
	
		local nEndYear =  math.floor(EndTime/10000)
		local nEndTemp = math.mod(EndTime,10000)
		local nEndMonth =  math.floor(nEndTemp/100)
		local nEndDay = math.mod(EndTime,100)

		QuestGreeting_Desc:AddTextElement( ScriptGlobal_Format("#{CJZH_250313_26}",nBeginYear,nBeginMonth,nBeginDay,nEndYear,nEndMonth,nEndDay))
	elseif nIndex == "236" then
		QuestGreeting_Desc:AddTextElement( "#{SCBHPM_20220815_224}" )				
	elseif nIndex == "237" then
		QuestGreeting_Desc:AddTextElement( "#{DFWF_250728_12}" )
	elseif nIndex == "238" then
		QuestGreeting_Desc:AddTextElement( "#{WHCJ_251018_08}" )
	elseif nIndex == "239" then
		QuestGreeting_Desc:AddTextElement( "#{MTNC_221101_01}" )					
	elseif nIndex == "240" then
		QuestGreeting_Desc:AddTextElement( "#{QCBF_161122_05}" )
	elseif nIndex == "241" then
		QuestGreeting_Desc:AddTextElement( "#{FYYR_260108_06}" )
	elseif nIndex == "242" then
		QuestGreeting_Desc:AddTextElement( "#{ZHGJ_260226_01}" )
	elseif nIndex == "243" then
		QuestGreeting_Desc:AddTextElement( "#{SHH_260226_1}" )
	elseif nIndex == "244" then
		QuestGreeting_Desc:AddTextElement( "#{FYDK_260129_09}" )
	elseif nIndex == "245" then
		QuestGreeting_Desc:AddTextElement( "#{TLHX_260518_34}" )
	elseif nIndex == "246" then --2026砸金蛋
		local BeginDay,EndDay = DataPool:Lua_2026ZaJinDanTime() 
		local temp = math.mod(BeginDay, 10000)
		local month_1 = math.floor(temp/100)
		local day_1 = math.mod(temp, 100)
		temp = math.mod(EndDay, 10000)
		local month_2 = math.floor(temp/100)
		local day_2 = math.mod(temp, 100)	
		QuestGreeting_Desc:AddTextElement(ScriptGlobal_Format("#{DKZJ_260521_06}", month_1, day_1, month_2, day_2))			
	elseif nIndex == "247" then  --2026Q2武神坛打卡
		QuestGreeting_Desc:AddTextElement( "#{WSDK_260327_10}" )
	elseif nIndex == "248" then 
		if Player:GetData("IsOriginalJD") == 1 then
			QuestGreeting_Desc:AddTextElement( "#{QXYR_260601_185}" )
		else
			QuestGreeting_Desc:AddTextElement( "#{QXYR_260601_06}" )		
		end
	elseif nIndex == "249" then
		QuestGreeting_Desc:AddTextElement( "#{XQPVP_260526_07}" )
	elseif nIndex == "250" then
		local isKaJi = KaJi:LuaFnIsKaJiServer()
		local isOri = Player:GetData("IsOriginalJD") 

		if (isKaJi == 1) then
			QuestGreeting_Desc:AddTextElement("#{XQPVP_260526_188}")
		else
			if(Player:GetData("Is2606S")  == 1 ) then
				QuestGreeting_Desc:AddTextElement("#{XQPVP_260526_189}")
			elseif (isOri == 1) then
				QuestGreeting_Desc:AddTextElement("#{XQPVP_260526_187}")
			else
				QuestGreeting_Desc:AddTextElement("#{XQPVP_260526_07}")
			end
		end
	end
	
	this:Show()
end

-- 2018Q4春节引导任务--吉祥符介绍
function Quest_SpringGuideMission_JiXiangFuHelp(nIndex)
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");

	if nIndex == "1" then
		QuestGreeting_Desc:AddTextElement( "#{RACL_181206_609}" )
	elseif nIndex == "2" then
		QuestGreeting_Desc:AddTextElement( "#{RACL_181206_610}" )
	elseif nIndex == "3" then
		QuestGreeting_Desc:AddTextElement( "#{RACL_181206_611}" )
	end
	this:Show()
end

function Quest_DuanWu_DuiHuan_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");

	QuestGreeting_Desc:AddTextElement( "#{DWDH_190502_11}" )
	this:Show()
end

-- 2018Q4春节引导任务--彩蛋介绍
function Quest_SpringGuideMission_CaiDanHelp()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");

	QuestGreeting_Desc:AddTextElement( "#{RACL_181206_570}" )
	this:Show()
end

function Quest_OpenZNQDraw_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(56) > 0 then  --卡级
		QuestGreeting_Desc:AddTextElement( "#{HDSW_220118_02}" )
	else
		QuestGreeting_Desc:AddTextElement( "#{HDSW_190322_3}" )
	end	

	this:Show()
end

-- 2019国庆稳活跃抽奖--祈福界面帮助
function Quest_OpenGQHYChouJiang_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	QuestGreeting_Desc:AddTextElement( "#{GQHY_190723_33}" )
	this:Show()
end

function Quest_OpenLongSignIn_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	
	QuestGreeting_Desc:AddTextElement( "#{CQD_210806_11}" )
	this:Show()
end

function Quest_OpenDuanWuBidding_Help_I()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	QuestGreeting_Desc:AddTextElement("#{MHZD_190501_13}")
	this:Show()
end

function Quest_OpenDuanWuBidding_Help_II()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	QuestGreeting_Desc:AddTextElement("#{MHZD_190501_43}")
	this:Show()
end

function Quest_SpringFestivalBidding_Help()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	QuestGreeting_Desc:AddTextElement("#{CJPM_191126_77}")
	this:Show()
end

function Quest_SpringFestivalBiddingList_Help()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	local isJD = Player:GetData("IsOriginalJD")
	if isJD == 1 then
		QuestGreeting_Desc:AddTextElement("#{CJPMKJ_211210_3}")
	else	
		if KaJi:LuaFnGetKaJiType(46) == 0 then
			QuestGreeting_Desc:AddTextElement("#{CJPM_191126_138}")
		else
			QuestGreeting_Desc:AddTextElement("#{CJPMKJ_211210_3}")
		end
	end
	this:Show()
end

function Quest_OpenDuanWuBidding_Help_III()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	QuestGreeting_Desc:AddTextElement("#{MHZD_190501_125}")
	this:Show()
end

function Quest_Open_Help_Msg(msg)
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	QuestGreeting_Desc:AddTextElement(msg)
	this:Show()
end

function Quest_BianJingBiddingList_Help(flag)
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	if flag == 0 then
	QuestGreeting_Desc:AddTextElement("#{BJPM_200804_45}")
	else
		QuestGreeting_Desc:AddTextElement("#{BJPM_210511_10}")
	end
	this:Show()
end

function Quest_BianJingBiddingTime_Help()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	QuestGreeting_Desc:AddTextElement("#{BJPM_200804_117}")
	this:Show()
end

function Quest_OpenCaiQiuEnter_Help()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(172) > 0 then
		QuestGreeting_Desc:AddTextElement("#{KWCQ_251224_03}")
	else
		QuestGreeting_Desc:AddTextElement("#{KWCQ_181201_3}")
	end
	this:Show()
end

function Quest_OpenLuHeXieXiang_Help(kaji)
	local isKaJi = KaJi:LuaFnIsKaJiServer()
	local isOri = Player:GetData("IsOriginalJD") 

	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	if (isKaJi == 1) then
		-- 卡级服
		QuestGreeting_Desc:AddTextElement("#{ETDDS_220406_72}")
	else
		if (isOri == 1) then
			-- 删减服
			QuestGreeting_Desc:AddTextElement("#{ETDDS_260417_01}")
		else
			-- 常规服
			QuestGreeting_Desc:AddTextElement("#{ETDDS_220406_71}")
		end
	end
	this:Show()
end

function Quest_ShowLuHeXieXiang_Result(result, num)
	if (result == nil or num == nil) then
		return
	end

	local gameResult = tonumber(result)
	local collectNum = tonumber(num)

	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")

	local msg = ""
	if (gameResult == 1) then
		msg = ScriptGlobal_Format("#{ETDDS_220406_110}", collectNum)
	elseif (gameResult == 2) then
		msg = ScriptGlobal_Format("#{ETDDS_220406_125}", collectNum)
	else
		msg = ScriptGlobal_Format("#{ETDDS_220406_111}", collectNum)
	end
	
	QuestGreeting_Desc:AddTextElement(msg)
	this:Show()
end

function Quest_ShowXRZPVPGoto_Help()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	Quest_Button_Refuse:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("")
	
	if (KaJi:LuaFnIsKaJiServer() ~= 1) then
		QuestGreeting_Desc:AddTextElement("#{BXDZ_240918_04}")
	else
		QuestGreeting_Desc:AddTextElement("#{BXDZ_240918_240}")
	end
	this:Show()
end -- end func Quest_ShowXRZPVPGoto_Help()

function Quest_ShowBountyMsg()
	Quest_Button_Continue:Disable()
	Quest_Button_Accept:Disable()
	QuestGreeting_Desc:ClearAllElement()
	Quest_Frame_Debug:SetText("#{XFXS_201231_10}")
	
	local missionIndex = DataPool:GetPlayerMissionIndexByID(1957)
	if missionIndex < 0 then
		return
	end
	local missId = DataPool : GetPlayerMission_Variable( missionIndex, 1 )
	local tq,taskType,uiDesc,accDesc,p1,p2,p3,p4,p5,p6,taskDesc,compDesc = ZhanTuanInterface:GetBountyTaskDesc(missId)
	QuestGreeting_Desc:AddTextElement(accDesc)
	this:Show()

end
	
function Quest_GetDayTime(nDayTime)
	local day = math.mod(nDayTime, 100)
	local month = math.mod(math.floor(nDayTime/100), 100)
	return month, day
end

function Quest_LianXuQiRi_Help()
	--local _, nStartDayTime, _, _ = DataPool:LuaFnGetDaysSignInfo(1, 0)
	--local smonth,sday = Quest_GetDayTime(nStartDayTime)
		
	--local nFinalTime = 0
	--local nWeek = 0
	--for i = 1, 4 do
	--	local IsOpen, nEndDayTime, _, _ = DataPool:LuaFnGetDaysSignInfo(i, 6)
	--	if IsOpen == 1 then
	--		nFinalTime = nEndDayTime
	--		nWeek = nWeek+1
	--	end
	--end
	--local emonth,eday = Quest_GetDayTime(nFinalTime)
	local text = ""
	local kajiType = KaJi:LuaFnGetKaJiType(99)
	if kajiType == 1 then
		text = "#{LXQD_220719_16}"--ScriptGlobal_Format("#{LXQD_220719_16}", smonth,sday,emonth,eday)
	else
		text = "#{LXQD_220719_13}"--ScriptGlobal_Format("#{LXQD_220719_13}", smonth,sday,emonth,eday)
	end
	
	QuestGreeting_Desc:AddTextElement( text )

end

function Quest_LianXuQiRi_Help_New()
	local text = ""
	local kajiType = KaJi:LuaFnGetKaJiType(99)
	if kajiType == 1 then
		text = "#{LXQD_220719_16}" --.. "#{LXQD_220719_14}"--ScriptGlobal_Format("#{LXQD_220719_16}", smonth,sday,emonth,eday)
	else
		text = "#{LXQD_220719_13}" --.. "#{LXQD_220719_14}"--ScriptGlobal_Format("#{LXQD_220719_13}", smonth,sday,emonth,eday)
	end

	QuestGreeting_Desc:AddTextElement( text )

end
-- 该方法已废弃，改用静态链接。
-- 照搬MiniMap_PlayerAsk_Bn_Clicked中的写法：
function Quest_GetJiuTouShenDiaoYanUrl()
	local menpai = Player:GetData("MEMPAI")
	local strName = ""
	if(0 == menpai) then
		strName = "少林"
	elseif(1 == menpai) then
		strName = "明教"
	elseif(2 == menpai) then
		strName = "丐帮"
	elseif(3 == menpai) then
		strName = "武当"
	elseif(4 == menpai) then
		strName = "峨嵋"
	elseif(5 == menpai) then
		strName = "星宿"
	elseif(6 == menpai) then
		strName = "天龙"
	elseif(7 == menpai) then
		strName = "天山"
	elseif(8 == menpai) then
		strName = "逍遥"
	elseif(9 == menpai) then
		strName = "无门派"
	elseif(10== menpai) then
		strName = "慕容"
	elseif(11== menpai) then
		strName = "唐门"
	elseif(12== menpai) then
		strName = "鬼谷"
	elseif(13== menpai) then
		strName = "桃花岛"
	elseif(14== menpai) then
		strName = "绝情谷"
	elseif(15== menpai) then--menpai15 mptodo
		strName = "恶人谷"
	end

	local idWorld = Variable:GetVariable("Login_World")
	if idWorld == nil then
		idWorld = 0
	end

	local urlStr = "{gameName:tlbb,accountId:"..Player:GetData("ACCOUNTNAME")
	urlStr = urlStr..",serverId:"..idWorld
	urlStr = urlStr..",roleName:"..Player:GetName()
	urlStr = urlStr..",roleId:"..ConvertGuidToShow( GetSelfGUID() )
	urlStr = urlStr..",roleGrade:"..Player:GetData("LEVEL")
	urlStr = urlStr..",vipGrade:"..DataPool:GetAccVipLevel()
	urlStr = urlStr..",Profession:"..strName
	urlStr = urlStr..",gameVersion:"..GetGameVersion().."}"

	local vcode = CalciDiaoYanVCode(urlStr.."345341234567353534/Vo48a31bd=")
	urlStr = ConvertStringToURLCoding(urlStr)
	local url = GetWeblink("WEB_JTSDY").."/?appdata="..urlStr.."&vcode="..vcode

	-- PushDebugMessage(url)
	return url
end

function OpenZBSUrl_MatchWeb()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ZBSZT"))
end

function OpenZBSUrl_GuessWeb()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ZBSNEWJC"))
end

-- 龙抬头活动
function OpenLongTaiTou_WXWeb()
	GameProduceLogin:OpenURL(GetWeblink("WEB_LTT"))
end

--客户端直接调用help说明
function Quest_HelpMsg(msg)
	Quest_Button_Continue:Disable();
	Quest_Button_Continue:SetProperty("EnableAnimation", "0")
	Quest_Button_Accept:Disable();
	Quest_Button_Accept:SetProperty( "Flash", "0" );
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	Quest_Frame_Debug:SetText("");
	QuestGreeting_Desc:AddTextElement( msg )
	this:Show()
end

-- 争霸赛直播
function OpenZBS_WXWeb()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ZBSLIVE"))
end

function Quest_Open2606S_Help()
	Quest_Button_Continue:Disable();
	Quest_Button_Accept:Disable();
	Quest_Button_Refuse:Disable();
	QuestGreeting_Desc:ClearAllElement();
	
	if Player:GetData("Is2606S") == 0 then	
		return
	end
	
	Quest_Frame_Debug:SetText("#{QXFJYXG_260618_6}");

	local nMaxLevel = Lua_GetMyMaxLevelLimit()
		
	local nDate = Lua_Get2606SNextPhaseDate();
	if nDate > 0 then
		local nOpenDate, nDayCount = Lua_Get2606SOpenDayCount()
		if nOpenDate ~= nil and nDayCount ~= nil then
			
			local bShow=0
			local nIndex = 0;
			local nFCnt = Lua_Get2606SLevelInfoCount();
			while( nIndex < nFCnt ) do
				
				local nTblDayCount, nTblLevel, nYear, nMonth, nDay = Lua_Get2606SLevelPhaseInfo( nOpenDate, nIndex )
				if nTblDayCount == nil then
					break;
				end
					
				if nDayCount < nTblDayCount then
					if bShow == 0 then
						QuestGreeting_Desc:AddTextElement( ScriptGlobal_Format("#{QXFJYXG_260618_7}", nMaxLevel, nTblDayCount-nDayCount, nTblLevel) )
						bShow = 1
					end		
					QuestGreeting_Desc:AddTextElement( ScriptGlobal_Format("#{QXFJYXG_260618_8}", nYear, nMonth, nDay, nTblLevel) )
				end				
				
				nIndex = nIndex + 1;
			end
		
			QuestGreeting_Desc:AddTextElement( "#{QXFJYXG_260618_9}" )			
		end
	else
		QuestGreeting_Desc:AddTextElement( ScriptGlobal_Format("#{QXFJYXG_260618_10}", nMaxLevel) )
		QuestGreeting_Desc:AddTextElement( "#{QXFJYXG_260618_9}" )
	end

	this:Show()
end
