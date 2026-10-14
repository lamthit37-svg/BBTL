local g_InitiativeClose = 0;
local g_currentList = 0;
local g_currentIndex = 0;
-- 摆摊地租提示窗口，在这里有发送给服务器的确定开始摆摊的消息
local Recycle_Type = -1;
local Recycle_CurSelectItem = -1
local g_FrameInfo = -1;
local g_CurUintType = {
	YuanBao 	= 0,
	Bind		= 1,
	GiftToken	= 2,
	LiJin		= 3,
	BWHonourValue =4,
	ShowCredit = 5,--秀场积分
	LiJin_DisCount		= 6,
}

local g_CurUint = g_CurUintType.YuanBao;
local g_MessageBox_Self_Frame_UnifiedPosition;

local FrameInfoList = {
	STALL_RENT_FRAME			= 1,
	DISCARD_ITEM_FRAME			= 2,
	CANNT_DISCARD_ITEM			= 3,
	TEAM_ASKJOIN				= 4,	--有人邀请你加入队伍
    TEAM_MEMBERINVERT			= 5,	--队员邀请某人加入队伍请求你同意
    TEAM_SOMEASK				= 6,	--某人申请加入队伍
    TEAM_FOLLOW		 			= 7,	--进入组队跟随模式
    FRAME_AFFIRM_SHOW 			= 8,	--进入放弃任务确认模式
    GUILD_CREATE_CONFIRM		= 9, 	--帮会创建确认模式
    SYSTEM_TIP_INFO 			= 10,	--系统提示对话框模式
    GUILD_QUIT_CONFIRM 			= 11,	--帮会退出确认模式
    GUILD_DESTORY_CONFIRM		= 12,	--帮会删除确认模式
    CALL_OF						= 13,	--拉人
    NET_CLOSE_MESSAGE			= 14,	--断开网络
    PET_FREE_CONFIRM			= 15,	--珍兽放生确认
    CITY_CONFIRM				= 16,	--城市相关确认
    SAVE_STALL_INFO				= 17,	--保存摆摊信息
    PET_SYNC_CONFIRM			= 18,	--珍兽繁殖确认
    QUIT_GAME					= 19,	--退出游戏的确认
    EQUIP_ITEM					= 20,	--装备物品
    YUANBAO_BUY_ITEM		= 21, --元宝商店购买物品确认
    CONFIRM_REMOVE_STALL	= 22,--确认撤滩 add by zchw
    PET_PROCREATE_PROMPT			= 23, -- 珍兽繁殖提示 zchw

	--这个24一定不能改，改了出错的！！！！！Chris
	SERVER_CONTROL				= 24,	--Server控制弹出的提示框
	DELETE_FRIEND_MESSAGE		= 25,	--确定删除好友的提示框

		GUILD_DIS_FIRSTMAN    =87,  --确认删除第一继承人
    GEM_COMBINED_CONFIRM		= 88,	-- 确认宝石合成
   	ENCHASE_CONFIRM					= 99,	-- 确认镶嵌
   	ENCHASE_FOUR_CONFIRM		= 100,	-- add:lby20080527确认4镶嵌

   	--CARVE_CONFIRM				= 102,	-- 确认雕琢



    PS_RENAME_MESSAGE			= 116,	--更改玩家商店店名
    PS_READ_MESSAGE				= 117,	--更改玩家商店介绍（广告）
    PS_ADD_BASE_MONEY			= 118,	--充入本金
    PS_ADD_GAIN_MONEY			= 119,	--充入盈利金
    PS_DEC_GAIN_MONEY			= 120,	--取出盈利金
    PS_ADD_STALL				= 121,	--增加柜台
    PS_DEL_STALL				= 122,	--减少柜台
    PS_INFO_PANCHU				= 123,	--商店盘出
    PS_INFO_PANRU				= 124,	--商店盘入
    PS_INFO_MODIFY_TYPE			= 125,	--更改商店类型
    PS_INFO_PANCHU_YB				= 126,	--商店盘出类型为元宝盘出
    FREEFORALL					= 201,	--FREEFORALL: 个人混战
    FREEFORTEAM					= 202,	--FREEFORTEAM： 组队混战
    FREEFORGUILD				= 203,	-- FREEFORGUILD：帮派混战
    MAKESUREPVPCHALLENGE		= 204,
    EXCHANGE_MONEY_OVERFLOW			= 205, --交易后增加玩家是否到达钱上限的判定

    GUILD_DEMIS_CONFIRM		= 206, 			--禅让确认

    CHANGEPROTECTTIME		= 207, 				--安全时间
    COMMISION_BUY = 208, 							--寄售商店购买确认

    Player_Give_Rose		= 209,
    RECYCLE_DEL_ITEM		=210, 				--取消收购确认

    OPEN_IS_SELL_TO_RECSHOP	= 211, 		--出售物品确认

    CONFIRM_STENGTH = 212,

    CHAR_RANAME_CONFIRM = 213,				--改名 合服

    CITY_RANAME_CONFIRM = 214,

    CONFIRM_RE_IDENTIFY = 215,

    KICK_MEMBER_MSGBOX = 216,

		SAFEBOX_LOCK_CONFIRM = 217,						--保险箱锁定确认框
		SAFEBOX_UNLOCK_CONFIRM = 218,					--保险箱解锁确认框

		LOCK_ITEM_CONFIRM_FRAME = 219,        --	加锁确认
    GUILD_LEAGUE_QUIT_CONFIRM = 220,			--	退出帮会同盟确认
    GUILD_LEAGUE_CREATE_CONFIRM = 221,		--	创建帮会同盟确认
		PET_SKILL_STUDY_CONFIRM = 222,				--	宠物学习技能确认
		EXCHANGE_BANGGONG = 223,							--	兑换帮贡牌确认
		PUT_GUILDMONEY = 224,									--	帮会资金捐助
		TLZ_CONFIRM_SETPOS = 225,							--	确认土灵珠重新定位

		DISMISS_TEAM = 226,										--	解散队伍
		DART_ADJUST = 227,										--	暗器属性调整   Vega 20090422
		TRUST_FRIEND = 228,
		NEED_USE_CONFIRM_ITEM = 229,
		GONGLIDAN_USE_CONFIRM = 230, 					--	功力丹使用确认 fsy 20091027
		KFS_RESET_GROWRATE = 231,
		UNINSTALL_CHAT_FACE = 232 ,						--	卸载收费表情包
		TEAMBOARD_OPEN_DEL_CHECK = 233,
		UNINSTALL_CHAT_ACTION = 234 ,					--	卸载收费休闲动作包
		SERVER_CONTROL_EXT		= 255,  				--	Server控制弹出的提示框的扩展版
		QUIT_CHATGROUP_CONFIRM		= 256,					--退出群
		DISMISS_CHATGROUP_CONFIRM	= 257 ,					--解散群
		CHANGE_NAME_CONFIRM = 258,						-- 角色改名
		FREEFORRAID = 259,
		CONFIRM_USE_CHESS = 260,--确认使用棋子(宋辽大战)
		CHANGE_NAME_RETOK = 261,						-- 角色改名成功
		SONGLIAOWAR_XXS_CANCELBUF_CONFIRM = 262, --宋辽休息室取消buf确认
		SONGLIAOWAR_REST_EXIT_CONFIRM = 263, --宋辽休息室退出确认
		IMDressBuyToOther = 264,             --赠送炫装商城购买确认
        FREE_FOR_CLAN = 265,                    --- 势力频道PK

		--遁甲书采用自己的确认框界面
		--[[DJTS_CONFIRM_SETPOS = 265,							--	确认遁甲天书重新定位
		DJQS_CONFIRM_SETPOS = 266,							--	确认遁甲奇书重新定位
		DJTS_CONFIRM_CHUANSONG = 267,							--	确认遁甲天书传送
		DJQS_CONFIRM_CHUANSONG = 268,							--	确认遁甲奇书传送
		DJTS_CONFIRM_BUCHONG = 269,							--	确认遁甲天书补充符咒
		DJQS_CONFIRM_BUCHONG = 270,							--	确认遁甲奇书补充符咒
		--]]
		ZBS_ETNER_CONFIRM = 271,             --争霸赛进入确认

        --- 势力和战盟相关


        ---

		CONFIRM_USE_MIFA = 285,        --确认使用秘法

		STALYEXP_CONFIRM = 286,        --徒弟给师父贡献经验确认

		CONFIRM_USE_SDCZ = 287,				 -- 确认使用宿敌残章

		CONFIRM_UPDATE_VIP 			= 289,	--确认激活VIP特权

        CONFIRM_SAVE_GAME_SETUP          = 290,      --- 确认是否保存游戏设置


		STALL_OFFLINE_CANCLE = 291, --设置离线摆摊后的成功界面
		STALL_OFFLINE_ERRSTATE =292, --离线摆摊2次确认错误状态

		CONFIRM_LEAVE_CORPS_COPYSCENE	 = 299,	--确认离开战队副本
		AUTOMOVE_CONFIRM_NOPKVALUE	   = 300,		--自动寻路确认-不加杀气场景
		AUTOMOVE_CONFIRM_UPPKVALUE     = 301,       --自动寻路确认-加杀气场景
		PNEUMA_LOCK_CONFIRM						 = 302,
		AUTOMOVE_CONFIRM_FENGMING     = 303,		--自动寻路确认-凤鸣镇
		PNEUMA_JUYUAN_CONFIRM				 = 304,
		CONFIRM_LEAVE_CORPS_FINAL_SCENE	 = 305,	--确认离开战队副本
		FITTINGROOM_BUY_ITEM_CONFIRM		= 306,	--预览间购买确认
		JIYUANSHOP_BUY_ITEM_CONFIRM		= 307,	---机缘秘宝购买确认
		STUDY_XINFA						= 308,	-- 学习心法
		STUDY_XIULIAN					= 309,	-- 修炼
		PLAYER_GIVE_BLUEROSE			= 310,	--送999支蓝色妖姬
		-- HUDONG_SANLIANHUA					= 311, --活动三连环
		CONFIRM_DISSOLUTIONOFCONTRACT	= 312,	-- 解除合作关系

		ATHORSECFRAME						=315, --安全中心-授权模式

		-- INFANT_CARD_COMPOSE_CONFIRM = 316,		--卡牌合成确认框
		-- INFANT_CARD_STRENGTH_CONFIRM = 317,		--卡牌强化确认框
		-- INFANT_CARD_TRANSFER_CONFIRM = 318,		--卡牌强化转移确认框
		INFANT_HERO_CHOICE_CONFIRM = 319,		--英雄选择确认框
		INFANT_CARD_EQUIP_CONFIRM = 320,		--卡牌装备绑定确认框

		ONCE_ALL_LOCK = 321,			--一键加锁

		FREE_FOR_KGUILD			  = 322,		--2014Q1大世界帮会功能改造,添加K服新的PK模式:"帮会模式"
		BUDGETPLANINFO_DOWNPAY	  = 323, --分期付款首付
		BUDGETPLANINFO_REPAY	  = 324, --分期付款还款

		GUILDSHOP_ITEM_SURE		= 325,		--帮会商城购买确认
		SHOUGONG_BUY = 326, 						--7、8星手工装备重洗相关道具购买确认
		--SHENGMINGXIANHE_CONFIRM = 327, --声名显赫二次确认
		INFANT_DRESS_CUT_PAINT_CONFIRM = 329,	--子女时装剪裁
		MILITARYRANKSHOPBUYCONFIRM = 330,	-- 军衔商店购买确认
		NOBILITYSHOPBUYCONFIRM = 331,	-- 爵位商店购买确认
		DISMISS_ZHANTUAN_CONFIRM = 332,		--解散战团确定
		DLZ_CONFIRM_SETPOS = 333,							--	确认地灵珠重新定位
		--ROSEGIFTBOX_USE_CONFIRM = 334, 					--	2015情人节排行榜礼盒使用二次确认
		ROSERANK_EXCHANGE_CONFIRM = 335, 					--	2015情人节排行榜兑换二次确认

		HUITIANDAN_USE_CONFIRM	 = 337,	--回天丹确认

		--CONFIRM_MULTIBUY				= 338,	--批量购买
		TIANJIANGQIFU_CONFIRM	 = 339,	--天降祈福 确认
		RESIGN_YUANBAO_CONFIRM	= 340,  --签到元宝确认
		SHIDESHOPBUYCONFIRM = 341,	-- 师德商店购买确认
		QIXIRANK_EXCHANGE_CONFIRM = 342, --2015七夕情人节兑换确认
		QIXIRANK_USE_CONFIRM = 343,      --2015七夕情人节使用礼盒二次确认
		SANSHEN_FUBEN_CONFIRM = 344,      --三神副本退出确认
		CONFIRM_LEAVE_KM_SCENE	 = 345,	--确认离开王者挑战赛副本
		PVP_ALLIANCE = 346,		--战盟PK确认
		ALLIANCESHOP_BUY_CONFIRM = 347,	--战盟商店购买确认

		KWLZ_CONFIRM_SETPOS = 349,							--	确认昆吾灵珠重新定位
		CHRISTMAS_ZUNXIANG_USE_CONFIRM = 350, 					--	2015圣诞尊享礼盒使用二次确认
    --PET_EQUIPSUITDEPART_CONFIRM			= 351,	--珍兽套装拆解确认
		CONFIRM_IMMIGRATION  = 352,				 -- 移民
		CONFIRM_CANCEL_IMMIGRATION  = 353,				 -- 取消移民
		CONFIRM_SUMMERVACATION = 354,							 -- 暑假放利登陆奖励元宝续签
		CONFIRM_ZHENGBASAI_PET = 355,							--争霸珍兽奖励
		CONFIRM_ROSEWEAPON = 356,							--玫瑰礼盒确认
		CONFIRM_GAOBAILIHE = 357, 					--告白礼盒
		CONFIRM_ZHOUNIANQING_PRIZE = 358, --周年庆补领确认
		CONFIRM_BIN_COMMON = 359, --购买确认
		CONFIRM_JIUCENGYAOTA = 360, --确认进入九层妖塔
		CONFIRM_MENGCHONG_COMMON = 361, --mengchong  收回仓库 二次确认
		CONFIRM_MENGCHONG_REMOVE_COMMON = 362, --mengchong  收回仓库 二次确认
		CONFIRM_LEAVE_SANSHENJIALAN = 363,     --离开九星副本确认
		CONFIRM_JIUCENGYAOTA_RELIVE = 364,    --九层妖塔复活确认
		CONFIRM_JIUXING_FUBEN = 365, --确认进入九星副本
		CONFIRM_HAOXIA_PET = 366,							--豪侠路
		CONFIRM_HAOXIA_EXCHANGE_BOUNS = 367,							--豪侠值兑奖励
		CONFIRM_LIJINDISCOUNT = 368,
		CONFIRM_LEAVE_CORPS_COPYSCENE_2018	 = 369,	--确认离开战队副本 2018版
		CONFIRM_LEAVE_CORPS_FINALSCENE_2018	 = 370,	--确认离开总决赛场景 2018版 
		CONFIRM_MSDSHOP_BUY_CONFIRM = 371,	--名仕点商店		
		CONFIRM_YUSUI_CONFIRM = 372,	--玉碎合成确认
		BUY_PLAYERSHOP_SECOND_CONFIRM = 373, --购买玩家商店二次确认
		MOUNT_PROLONG_CONFIRM = 374,  --坐骑续时		
		CONFIRM_BWDB_CONFIRM = 375,	--比武代币商店二次确认	
		CONFIRM_DUANWU_ZONGZI_CONFIRM = 376,	--端午包粽子 二次确认	
		CONFIRM_BASE_SHANHAIBI_CONFIRM = 377,	
		CONFIRM_CHANGE_NEW_ZIWEI = 378,			--新的兑换紫微玉二次确认
		T3SHOP_BUY_ITEM_CONFIRM = 379,
		ZYPX_BULING_ITEM_CONFIRM = 380,
		BianJin_WeiBingJia_CONFIRM = 381,--金陵卫兵甲二次确认xjc
		BianJin_WeiBingYi_CONFIRM = 382,--金陵卫兵乙二次确认xjc
		BIANJING_HORSERENT = 383, --汴京马匹租借
		
		EXTERIOR_RIDE_EQUIP_CONFIRM = 384,
		EXTERIOR_RIDE_ITEM_CONFIRM = 385,
		EXTERIOR_DECOWEAPON_EQUIP_CONFIRM = 386,
		EXTERIOR_DECOWEAPON_ITEM_CONFIRM = 387,
		
		EXTERIOR_TOY_ITEM_CONFIRM = 389,
		CHONGLOU_SHOP_CONFIRM = 391,--重楼商店二次确认xjc

		MAOHUABI_BUY_CONFIRMS  = 394,

		DISCARD_QUAL8ITEM_FRAME = 395,

		VIPNIANDI_CONFIRM = 396, --幻玉礼盒 二次确认

		DIGONGSHOP_CONFIRM = 397,
		MINGZHENJIANGHU_CONFIRM = 398,
		RMB_EMO_INSTALL_CONFIRM = 399,
		LUHEXIEXIANG_CONFIRM = 400,
		LUHEXIEXIANG_SINGLEENTERCONFIRM = 401,
		XINSHOUZHANLING_BUYLEVEL = 402, --新手战令 购买等级二次确认
		XINSHOUZHANLING_JINGYING = 403, --新手战令 解锁精英档二次确认
		
		XINTIANWAI_YURE_2022_1= 404, --2022Q3新天外预热活动-ypl to洛阳
		XINTIANWAI_YURE_2022_2= 405, --2022Q3新天外预热活动-ypl to四城
		
		XINTIANWAI_YURE_2022_3= 407, --2022Q3新天外预热活动-ypl 批量购买
		
		CITYWAR_CHANGE_PK_MODE= 408, --城战修改pk模式
		SEND_SHUIYUEDONGTIAN = 409, --传送水月洞天二次确认
		BEIJIUJINJIANGHU_2022_1= 410, --2022Q4杯酒尽江湖-ypl 福缘刷新
		BEIJIUJINJIANGHU_2022_2= 411, --2022Q4杯酒尽江湖-ypl 福缘领奖
		CONFIRM_MAOTUNAOCHUN_REDPACKET = 412, --卯兔闹春送红包 二次确认
		ZHONGQINGMEIGUI_CONFIRM = 413,	--钟情玫瑰
		QIMIAOEXPDAN_CONFIRM = 414,	--经验丹
		CONFIRM_ENTERDIGONG		= 416,
		CAISEDISHU_SINGLE_CONFIRM = 417,--打地鼠二次确认
		LUHEXIEXIANG_REWARDCONFIRM = 418,	-- 露荷撷香2023Q2重开 新增奖励领奖确认
		CONFIRM_BAIYINMAAN = 420, --白银马鞍二次确认
		CONFIRM_QINGTONGMAAN = 421, --青铜马鞍二次确认
		CONFIRM_ENTERTIANJICHENG		= 423, 
		GUILDCITY_FLAG_EXCHANGE= 424, --帮会城市战旗兑换
		ZHONGQINGMEIGUI_NEW_CONFIRM = 426,	--新一朵玫瑰
		WUYIZHUANHUAN_CONFIRM = 427,	--武意潜能转换
		OPEN_PAID_WORLD_CONFIRM = 428,	--武意潜能转换
		BUY_SUPERASS_FASHION_CONFIRM = 429,		--买超牛B时装确认
		FENGHUANG_INVITE_CONFIRM = 430, --凤凰古城邀请赛确认
		TCITYWAR_GROUP_RAID = 432,			--一键组团申请
		CHONGLOU_EFFECT_ACTIVE_CONFIRM = 433,			--重楼特效变更确认
		XIAKE_GUAIWU_ZHAOJILING_CONFIRM = 434,			-- 侠客- 怪物召集令使用 确认
		EXPBALL_USE_CONFIRM = 435,			-- 经验球使用 确认
		COMMONGIFT_TITLE_CONFIRM = 436,			-- 礼包称号 确认
		STEALSKILL_CONFIRM = 437,				-- 偷学技能确认
		RESET_STEALSKILL_CONFIRM =438,	-- 重置偷学技能确认
		CONFIRM_SUMMER_ZHANLING_ACT = 439,	-- 夏日拉收战令系统 激活人民币奖励的二次确认
		CONFIRM_SUMMER_ZHANLING_BUY = 440,	-- 夏日拉收战令系统 购买外观的二次确认
		CONFIRM_SHAXINGGIVEUP		= 441,	-- 新杀星放弃二次确认
		CONFIRM_BUY_NEWBAOTU = 442, --新宝图二次确认
		CONFIRM_SHAXINGCHANGE = 443, --新杀星兑换二次确认
		CONFIRM_ROUGEPATACHANGE = 444, --剑破明王境兑换二次确认
		CONFIRM_BUY_NEWBAOTU_FREE = 445, --新宝图免费二次确认
		CONFIR_FYPVE_BAG_CONFIRM = 446, --风云PVE
		CONFIRM_WEEKPVEAWARD = 447,--周常pve领奖
		CONFIRM_BUY_ORIBAOTU_FREE = 448, --购买藏宝图二次确认
		
		CONFIRM_RECV_BOUNTYMISSION = 449,

		CONFIR_QUNCHUANRUCHANGFU_CONFIRM = 450, --群传入场符
		
}

local PVPFLAG = { FREEFORALL = 201, FREEFORTEAM = 202, FREEFORGUILD = 203, MAKESUREPVPCHALLENGE = 204, ACCEPTDUEL = 205, DuelGUID = 0, DuelName = "", FREEFORRAID = 259,
    FREE_FOR_CLAN = 265, FREE_FOR_KGUILD = 322}
--FREEFORALL: 个人混战 FREEFORTEAM： 组队混战 FREEFORGUILD：帮派混战

local g_TransScript = {400999, 400980, 400123, 400027, 400018, 400121, 889431, 806012, 805021}
--
local g_szData;
local g_nData;
local g_nData1
--

local Quest_Number;
local Pet_Number;
local Server_Script_Function_Set = {};
local Server_Script_ID = "";
local Server_Return_1 = 0;
local Server_Return_2 = 0;
local Server_Return_3 = 0;

local g_CityData = {};						--由于upvalue的限制，城市和珍兽合成共用这个数据区

local strMessageString = "";		--对话框字符
local strMessageData   = 0;			--对话框类型，用于提示什么得对话框
local strMessageArgs = 0;				--按钮参数
local strMessageType = "Normal";--按钮风格
local strMessageArgs_2 = 0			--按钮参数2

local GemCombinedData = {}

local EnchaseData = {}

local SplitData = {}

local CarveData = {}

local CommisionBuyData = {}  --寄售商店购买确认框的数据

local IMDressBuyToOtherData = {}  --炫装赠送商城购买确认框的数据

local ShituRelation = {}     --徒弟供奉经验给师父确认

local MAX_OBJ_DISTANCE = 10.0;

local Client_ItemIndex = -1
local DJS_SelIndex = -1

local Dart_Data = {0,0,0}			--暗器数据
local KFS_Data = {}         --武魂数据

local NeedUseConfirmItemData = {}	--需要使用确认的物品数据
local UseConfirmItemShowTxt = {
	{idx = 30900074, txt = "#{QNDLB_1305030_11}"}, --潜能果
	{idx = 38000009, txt = "#{LYGL_090810_01}"}, --老友的祝福
	{idx = 30900078, txt = "#{QNG_XML_9}"}, -- 潜能真丹
	{idx = 38000362, txt = "#{LYGL_ZBS_120516_10}"}, --霸者的护佑
	{idx = 38001202, txt = "#{VLQJL_150323_08}"}, --2015vip领奖功能设计
	{idx = 38001782, txt = "#{HQTXLB_160628_09}"}, --道具：情缘天下
}

--新手战令 
local g_xinshouzhanling_addlevel = 0 --购买的等级

local g_TeamBoardWindow = -1; --确认删除的窗口，组队平台
local POS_GUILD_CHIEF = 9

--add by FengLiang 需要返回给服务器端的整形参数列表
--顺序是 targetId, param1, param2.....
local Server_Return_Params = {}
local g_LastEvent = ""--运维事故秒上报

local g_qiziParam = {}--宋辽大战棋子参数，回传服务器

--added by guochenshu 2010-08-25 改名后的新名字
local g_newName = ""

local g_ZBS_CurRnd = -1 --这个东西还是在客服端验证一下
local g_ZBS_NPCID = -1 --这个东西还是在客服端验证一下
local g_MSG_Box_Clan_Invite_ClanID       = -1    --- 邀请加入势力的势力ID
local g_MSG_Box_Clan_Invite_ClanName     = -1    --- 势力名称
local g_MSG_Box_Clan_Invite_InviterGUID  = ""    --- 邀请人的GUID
local g_MSG_Box_Clan_Invite_InviterName  = -1    --- 邀请人的姓名
local g_MSG_Box_Clan_Invite_TargetGUID   = ""    --- 被邀请人的GUID
local g_MSG_Box_Clan_Invite_TargetName   = -1    --- 被邀请人的姓名
local g_MSG_Box_Clan_Invite_ZoneWorldID  = -1    --- 邀请人的ZoneWorldID

local g_MSG_Box_Clan_Expel_MemIdx   = -1    --- 被逐出世族的人的Index
local g_MSG_Box_Clan_Demise_MemIdx  = -1    --- 禅让世族给某个人，找个人的Index
local g_MSG_Box_Union_Starter_ID    = -1    --- 发起建立战盟申请的势力I

local g_MSG_Box_Union_Invite_Apply_Starter_ClanID       = -1    --- 发起邀请/申请的势力ID
local g_MSG_Box_Union_Invite_Apply_Self_ClanID          = -1    --- 接受邀请/申请的人的势力ID，实际上就是自己的势力ID
local g_MSG_Box_Union_Invite_Apply_Starter_ClanName     = -1    --- 发起邀请/申请的人的势力名称
local g_MSG_Box_Union_Invite_Apply_Starter_Name         = -1    --- 发起邀请/申请的人的名字
local g_MSG_Box_Union_Invite_Apply_Starter_ZoneWorldID  = -1    --- 发起邀请/申请的人的ZoneWorldID

--add by kaibin for 门派进阶
local g_table_ItemGuid = {}

local g_SDCZ_ItemIdx = -1
local g_SDCZ_ItemTableIdx = -1
local g_SDCZ_HaveQuestItem = 0
--奖励物品
local g_SDCZ_GainItemID_List =
{
	{idx = 38000167, itemid = 20700031},
	{idx = 38000168, itemid = 20700032},
	{idx = 38000169, itemid = 20700033},
	{idx = 38000170, itemid = 20700034},
	{idx = 38000171, itemid = 20700035},
	{idx = 38000172, itemid = 20700036},
}

--- 保存游戏设置时，要打开哪个窗口, -1 -全部关闭；0 - 显示设置；1 - 声音设置；2 - 游戏性设置；3 - 自定义快捷键
local g_MSG_Box_GameSetup_curt_Window_TagIndex = -1    --- 当前打开的窗口
local g_MSG_Box_GameSetup_next_Window_TagIndex = -1    --- 下一个要打开的窗口

--注意upvalue；明白upvalue意思？
local g_GTC_Exc_Data ={}
g_GTC_Exc_Data[0] = 0 --代表第X次兑换，显示的时候+1
g_GTC_Exc_Data[1] = 0 --代表需要的贡献度数
g_GTC_Exc_Data[2] = 0 --代表场景号，决定回调那个脚本接口
--由于upvalue的限制，以后的变量请都共用此变量，设置之前MessageBox_Self_ClearVar一次
local g_msgFrameVar = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}
-- 0 进攻 1 防守
--local g_alliance_RP_ID =0

--进镜湖和秦皇地宫4层给予PK不加杀气场景提示
local pkSceneTipId = {
	400980, 400018, 400027,400999
}

local g_AllTransScriptId = {400158,400123,400982,400963,400121,25113,2026,15010,10008,9036,125013,1100,128,82,11003,
														9009,77001,1081,1028,13005,17005,12009,14007,16006,400900,889332,400980, 400018, 400027,400999,400986}
function CancelLastOp(str)
	if(this:IsVisible() and str ~= g_FrameInfo) then
		MessageBox_Self_Cancel_Clicked(0);
	end
end
--===============================================
-- OnLoad()
--===============================================
function MessageBox_Self_PreLoad()
	--this:RegisterEvent("MSGBOX_ACCEPTDUEL");

	this:RegisterEvent("MSGBOX_MAKESUREPVPCHALLENGE",true);
    this:RegisterEvent("MENU_SHOWACCEPTCHANGEPVP",true);
	this:RegisterEvent("OPEN_STALL_RENT_FRAME",true);
	this:RegisterEvent("OPEN_DISCARD_ITEM_FRAME",true);
	this:RegisterEvent("OPEN_CANNT_DISCARD_ITEM",true);
	this:RegisterEvent("AFFIRM_SHOW",true);
	this:RegisterEvent("NET_CLOSE",true);
	this:RegisterEvent("DELETE_FRIEND",true);
	this:RegisterEvent("TIME_UPDATE",true);
	this:RegisterEvent("PET_PROCREATE_PROMPT",true); -- zchw pet procreate

	-- zchw fix Transfer bug
	this:RegisterEvent("OBJECT_CARED_EVENT",true);
	---- 有人邀请你加入队伍
	--this:RegisterEvent("SHOW_TEAM_YES_NO",true);
	---- 队员邀请某人加入队伍请你同意.
	--this:RegisterEvent("TEAM_MEMBER_INVITE",true);
	---- 某人申请加入队伍.
	--this:RegisterEvent("TEAM_APPLY",true);
	---- 队长邀请进入组队跟随模式
	--this:RegisterEvent("TEAM_FOLLOW_INVITE",true);

	-- 创建帮会确认
	this:RegisterEvent("GUILD_CREATE_CONFIRM",true);
	-- 删除帮会确认
	this:RegisterEvent("GUILD_DESTORY_CONFIRM",true);
	-- 退出帮会确认
	this:RegisterEvent("GUILD_QUIT_CONFIRM",true);
	this:RegisterEvent("GUILD_LEAGUE_QUIT_CONFIRM",true);
	this:RegisterEvent("GUILD_LEAGUE_CREATE_CONFIRM",true);

	this:RegisterEvent("PET_FREE_CONFIRM",true);

	this:RegisterEvent("OPEN_PS_MESSAGE_FRAME",true);

	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("CITY_CONFIRM",true);
	--add by zchw
	this:RegisterEvent("OPEN_REMOVE_STALL",true);
	this:RegisterEvent("OPEN_SAVE_STALL_INFO",true);

	this:RegisterEvent("PET_SYNC_CONFIRM",true);

	--不在这里进行退出流程 by cys
	--this:RegisterEvent("QUEST_QUIT_GAME",true);

	this:RegisterEvent( "MESSAGE_BOX",true);

	this:RegisterEvent( "GEM_COMBINED_CONFIRM",true);
	--this:RegisterEvent( "CONFIRM_MULTIBUY",true);
	this:RegisterEvent( "ENCHASE_CONFIRM",true);
	this:RegisterEvent( "ENCHASE_FOUR_CONFIRM",true);-- add:lby20080527确认4镶嵌

	--this:RegisterEvent( "CARVE_CONFIRM",true);
	this:RegisterEvent( "EXCHANGE_MONEY_OVERFLOW",true);
	this:RegisterEvent( "GUILD_DEMIS_CONFIRM",true);
	this:RegisterEvent("YUANBAO_BUY_ITEM_CONFIRM",true);
	--付费商店改造
	this:RegisterEvent("FITTINGROOM_BUY_ITEM_CONFIRM",true);
	this:RegisterEvent("JIYUANSHOP_BUY_ITEM_CONFIRM",true);
	this:RegisterEvent("CHANGEPROTECTTIME",true);

	this:RegisterEvent("CONFIRM_COMMISION_BUY",true); --寄售商店购买确认

	this:RegisterEvent("PLAYER_GIVE_ROSE",true);
	this:RegisterEvent("PLAYER_GIVE_BLUEROSE",true);


	this:RegisterEvent( "RECYCLE_DEL_ITEM",true);

	this:RegisterEvent( "OPEN_IS_SELL_TO_RECSHOP",true);

	this:RegisterEvent( "CLOSE_PS_CHANGETYPE_MSG",true);

	this:RegisterEvent( "CONFIRM_STENGTH",true);

	this:RegisterEvent( "EXCHANGE_BANGGONG",true);

	this:RegisterEvent( "PUT_GUILDMONEY",true);

	this:RegisterEvent( "CLOSE_STRENGTH_MSGBOX",true);

	this:RegisterEvent( "CLOSE_RECYCLESHOP_MSG",true);

	this:RegisterEvent( "ENCHASE_CLOSE_MSGBOX",true);

	this:RegisterEvent( "CITY_RANAME_CONFIRM",true);

	this:RegisterEvent( "CHAR_RANAME_CONFIRM",true);

	--当logon打开的时候，关闭所有MessageBox
	this:RegisterEvent( "GAMELOGIN_OPEN_COUNT_INPUT",true);

	this:RegisterEvent( "CONFIRM_RE_IDENTIFY",true);

	this:RegisterEvent( "CLOSE_RE_IDENTIFY_MSGBOX",true);

	this:RegisterEvent( "KICK_MEMBER_MSGBOX",true);

	this:RegisterEvent( "CLOSE_KICK_MEMBER_MSGBOX",true);

	--保险箱锁定确认框
	this:RegisterEvent( "SAFEBOX_LOCK_CONFIRM",true);

	--保险箱解锁确认框
	this:RegisterEvent( "SAFEBOX_UNLOCK_CONFIRM",true);

	this:RegisterEvent( "CLOSE_SAFEBOX_CONFIRM",true);

	--加锁确认
	this:RegisterEvent( "LOCK_ITEM_CONFIRM",true);
	this:RegisterEvent( "OPEN_PETSKILLSTUDY_MSGBOX",true);
	this:RegisterEvent( "CLOSE_PETSKILLSTUDY_MSGBOX",true);
	--土灵珠定位确认
	this:RegisterEvent( "CONFIRM_SETPOS_TLZ",true);
	this:RegisterEvent( "CONFIRM_SETPOS_DLZ",true);
	this:RegisterEvent( "CONFIRM_SETPOS_KWLZ",true);

	-- 弹出解散队伍的二次确认窗口			add by WTT	20090212
	this:RegisterEvent( "OPNE_DISMISS_TEAM_MSGBOX",true);

	this:RegisterEvent("PACKAGE_ITEM_CHANGED",true);

	-- 信任伙伴删除确认
	this:RegisterEvent("TRUST_FRIEND_OPEN_DEL_CHECK",true);

	this:RegisterEvent("SET_GUILD_FIRSTMAN_NAME",true);

	-- 弹出物品使用确认窗口
	this:RegisterEvent("NEED_USE_CONFIRM_ITEM",true);

	--卸载收费表情确认
	this:RegisterEvent("UNINSTALL_CHAT_FACE_CONFIRM",true);

	this:RegisterEvent("QUIT_CHATGROUP_CONFIRM",true);
	this:RegisterEvent("DISMISS_CHATGROUP_CONFIRM",true);

	--卸载收费休闲动作确认
	this:RegisterEvent("UNINSTALL_CHAT_ACTION_CONFIRM",true);

	this:RegisterEvent("TEAMBOARD_OPEN_DEL_CHECK",true);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 交易成功
	this:RegisterEvent("SUCCEED_EXCHANGE_CLOSE",true);
	-- 角色改名
	this:RegisterEvent("CHANGE_NAME_CONFIRM",true);
	--与衣柜界面互斥
	this:RegisterEvent("YIGUI_OPEN",true);
	--炫装赠送商城购买确认
	this:RegisterEvent("CONFIRM_IMDRESS_BUYTOOTHER",true);

	--遁甲书采用新的确认框逻辑
	--[[
	--遁甲天书定位确认
	this:RegisterEvent( "CONFIRM_SETPOS_DJTS",true);
	--遁甲奇书定位确认
	this:RegisterEvent( "CONFIRM_SETPOS_DJQS",true);
	--遁甲天书传送确认
	this:RegisterEvent( "CONFIRM_CHUANSONG_DJTS",true);
	--遁甲奇书传送确认
	this:RegisterEvent( "CONFIRM_CHUANSONG_DJQS",true);
	--遁甲天书补充符咒确认
	this:RegisterEvent( "CONFIRM_BUCHONG_DJTS",true);
	--遁甲奇书补充符咒确认
	this:RegisterEvent( "CONFIRM_BUCHONG_DJQS",true);
	--]]


  --


  this:RegisterEvent( "CONFIRM_USE_SDCZ",true);
  this:RegisterEvent("OPEN_VIP_SHOP",true);
  this:RegisterEvent("DISSOLUTIONOFCONTRACT",true);	-- 解散合作关系

  this:RegisterEvent( "CONFIRM_SAVE_GAME_SETUP",true);
  this:RegisterEvent("AUTOMOVE_CONFIRM_NOPKVALUE",true);
  this:RegisterEvent("AUTOMOVE_CONFIRM_UPPKVALUE",true);
  this:RegisterEvent("PNEUMA_LOCK_CONFIRM",true);
  this:RegisterEvent("AUTOMOVE_CONFIRM_FENGMING",true);
  this:RegisterEvent("PNEUMA_JUYUAN_CONFIRM",true);
  this:RegisterEvent("STUDY_XINFA",true);
  this:RegisterEvent("STUDY_XIULIAN",true);
  this:RegisterEvent("PLAYER_LEAVE_WORLD",true);

  this:RegisterEvent("UINT_YHCHECK",true);

  this:RegisterEvent("ATHORSECFRAME",true);
  this:RegisterEvent("ONCE_ALL_LOCK",true);


  -- this:RegisterEvent("INFANT_CARD_COMPOSE_CONFIRM",true);
  -- this:RegisterEvent("INFANT_CARD_STRENGTH_CONFIRM",true);
  -- this:RegisterEvent("INFANT_CARD_TRANSFER_CONFIRM",true);
  this:RegisterEvent("INFANT_HERO_CHOICE_CONFIRM",true);
  this:RegisterEvent("INFANT_CARD_EQUIP_CONFIRM",true);
  this:RegisterEvent("GUILDSHOP_ITEM_SURE",true);
  this:RegisterEvent("BUDGETPLANINFO_DOWNPAY",true);
  this:RegisterEvent("BUDGETPLANINFO_REPAY",true);
  --this:RegisterEvent("SHENGMINGXIANHE_CONFIRM",true);
  this:RegisterEvent("INFANT_DRESS_CUT_CONFIRM",true);
  this:RegisterEvent("MILITARYRANKSHOPBUYCONFIRM",true);	-- 军衔商店购买确认
  this:RegisterEvent("NOBILITYSHOPBUYCONFIRM",true);		-- 爵位商店购买确认
  this:RegisterEvent("SHIDESHOPBUYCONFIRM",true);		-- 师德商店购买确认
  this:RegisterEvent("DISMISS_ZHANTUAN_CONFIRM",true);
  this:RegisterEvent("ROSERANK_EXCHANGE_CONFIRM",true);
	this:RegisterEvent("CLOSE_HUITIANDAN_MSGBOX",true);
  this:RegisterEvent("TIANJIANGQIFU_CONFIRM",true);	-- 天降祈福 确认
	this:RegisterEvent("RESIGN_CONFIRM",true);
  this:RegisterEvent("QIXIRANK_EXCHANGE_CONFIRM",true);
  this:RegisterEvent("QIXIRANK_USE_CONFIRM",true);
  this:RegisterEvent("ALLIANCESHOP_BUY_CONFIRM",true);
	this:RegisterEvent("RESIGN_SUMMERVACATION",true);			--暑假放利登陆奖励元宝续签
  --this:RegisterEvent("PET_EQUIP_DEPART_CONFIRM",true);
  this:RegisterEvent("ZHENGBASAI_PET_CONFIRM",true);
  this:RegisterEvent("CONFIRM_ROSEWEAPON",true);
  this:RegisterEvent("ZHOUNIANQING_PRIZE_CONFIRM",true);
  this:RegisterEvent("BIN_COMMON_CONFIRM",true);
  this:RegisterEvent("BIN_MENGCHONG_CONFIRM",true);
  this:RegisterEvent("BIN_MENGCHONG_REMOVE_CONFIRM",true);
	this:RegisterEvent( "HAOXIA_PET_CONFIRM",true);
	this:RegisterEvent( "HAOXIA_EXCHANGE_BOUNS_CONFIRM",true);
	this:RegisterEvent( "LIJIN_DISCNT_CONFIRM",true);	
  this:RegisterEvent("MSDSHOP_BUY_CONFIRM",true);
  this:RegisterEvent("MOUNT_PROLONG_CONFIRM",true);
  this:RegisterEvent("GUILD_TIANDAO_RET",true);
	this:RegisterEvent("T3SHOP_BUY_ITEM_CONFIRM")
	this:RegisterEvent("CHONGLOU_SHOP_CONFIRM")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")
	this:RegisterEvent("VIPNIANDI_CONFIRM")
	this:RegisterEvent("DIGONGSHOP_CONFIRM")
	this:RegisterEvent("CLOSE_MINGZHENJIANGHU_CONFIRM")
	this:RegisterEvent("CAISEDISHU_SINGLE_CONFIRM")
	this:RegisterEvent("WUYIZHUANHUAN_CONFIRM",true);
	this:RegisterEvent("OPEN_PAID_WORLD_CONFIRM",true);


end

--===============================================
-- OnLoad()
--===============================================
function MessageBox_Self_OnLoad()
  g_MessageBox_Self_Frame_UnifiedPosition=MessageBox_Self_Frame:GetProperty("UnifiedPosition");
end

function  MessageBox_Self_UpdateRect()

	local nWidth, nHeight = MessageBox_Self_Text:GetWindowSize();
	local nTitleHeight = 36;
	local nBottomHeight = 75;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	MessageBox_Self_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end
--===============================================
-- OnEvent()
--===============================================
function MessageBox_Self_OnEventEx(event)

		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		MessageBox_Self_Frame_On_ResetPos()
		return 0
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MessageBox_Self_Frame_On_ResetPos()
		return 0
	end

	local objCaredID = -1; -- zchw fix Transfer bug
	if(event == "QUEST_QUIT_GAME") then
		this:Show();
		g_FrameInfo = FrameInfoList.QUIT_GAME;
	-- add by zchw
	elseif event == "OPEN_REMOVE_STALL" then
		CancelLastOp(FrameInfoList.CONFIRM_REMOVE_STALL);
		g_FrameInfo = FrameInfoList.CONFIRM_REMOVE_STALL;
	-- zchw for pet procreate
	elseif event == "PET_PROCREATE_PROMPT" then
		CancelLastOp(FrameInfoList.PET_PROCREATE_PROMPT);
		g_FrameInfo = FrameInfoList.PET_PROCREATE_PROMPT;
	elseif event == "OPEN_SAVE_STALL_INFO"    then
		CancelLastOp(FrameInfoList.SAVE_STALL_INFO);
		g_FrameInfo = FrameInfoList.SAVE_STALL_INFO;
	elseif event == "YUANBAO_BUY_ITEM_CONFIRM" then
		if arg0 == "close" then
			if g_FrameInfo == FrameInfoList.YUANBAO_BUY_ITEM and this:IsVisible() then
			--如果是关于购物弹出的窗口，才关闭
				g_CityData = {}
				this:Hide()
			end
			return -1
		elseif arg0 == "open" then
			if IsWindowShow("Shop_MBuy") then
				CloseWindow("Shop_MBuy", true)
			end
			if IsWindowShow("Shop_MGift") then
				CloseWindow("Shop_MGift", true)
			end
			if IsWindowShow("ShowShop_MBuy") then
				CloseWindow("ShowShop_MBuy", true)
			end
			CancelLastOp(FrameInfoList.YUANBAO_BUY_ITEM)
			g_CityData = {}
			g_CityData[1] = tonumber(arg2)	--在货架的位置
			g_CityData[2] = tonumber(arg3)	--在商店的售价
			g_CityData[3] = arg1			--货物名称
			g_CityData[4] = tonumber(arg4)	--是否从最近购买列表购买
			g_CityData[5] = tonumber(arg6)	--货物数量
			if arg5 == "bind" then
				g_CurUint = g_CurUintType.Bind
			elseif arg5 == "giftToken" then
				g_CurUint = g_CurUintType.GiftToken
			elseif arg5 == "lijin" then
				g_CurUint = g_CurUintType.LiJin
			elseif arg5 == "BWHonourValue" then
				g_CurUint = g_CurUintType.BWHonourValue
			elseif arg5 == "showshop" then
				g_CurUint = g_CurUintType.ShowCredit
			elseif arg5 == "lijin_discount" then
				g_CurUint = g_CurUintType.LiJin_DisCount
			else
				g_CurUint = g_CurUintType.YuanBao
			end
			g_FrameInfo = FrameInfoList.YUANBAO_BUY_ITEM
		end
	elseif event == "T3SHOP_BUY_ITEM_CONFIRM" then
		if arg0 == "close" then
			if g_FrameInfo == FrameInfoList.T3SHOP_BUY_ITEM_CONFIRM and this:IsVisible() then
				g_CityData = {}
				this:Hide()
			end
			return -1
		elseif arg0 == "open" then
			
			if IsWindowShow("T3DaibiShop_MBuy") then
				CloseWindow("T3DaibiShop_MBuy", true)
			end
			
			CancelLastOp(FrameInfoList.T3SHOP_BUY_ITEM_CONFIRM)
			
			g_CityData = {}
			g_CityData[1] = arg1			--货物名称
			g_CityData[2] = tonumber(arg2)	--在货架的位置
			g_FrameInfo = FrameInfoList.T3SHOP_BUY_ITEM_CONFIRM
		end
	elseif event == "CHONGLOU_SHOP_CONFIRM" then
		if arg0 == "close" then
			if g_FrameInfo == FrameInfoList.CHONGLOU_SHOP_CONFIRM and this:IsVisible() then
				this:Hide()
			end
			return -1
		end
	elseif event == "CAISEDISHU_SINGLE_CONFIRM" then
		if arg0 == "close" then
			if g_FrameInfo == FrameInfoList.CAISEDISHU_SINGLE_CONFIRM and this:IsVisible() then
				this:Hide()
			end
			return -1
		end
	elseif event == "VIPNIANDI_CONFIRM" then
		if arg0 == "close" then
			if g_FrameInfo == FrameInfoList.VIPNIANDI_CONFIRM and this:IsVisible() then
				this:Hide()
			end
			return -1
		end
	elseif ( event == "FITTINGROOM_BUY_ITEM_CONFIRM" ) then
		if(arg0 == "close") then
			if(g_FrameInfo == FrameInfoList.FITTINGROOM_BUY_ITEM_CONFIRM and this:IsVisible())then
			--如果是关于购物弹出的窗口，才关闭
				g_CityData = {};
				this:Hide();
			end
			return -1;
		elseif(arg0 == "open") then
			if(IsWindowShow("Shop_MBuy")) then
				CloseWindow("Shop_MBuy", true);
			end
			if(IsWindowShow("Shop_MGift")) then
				CloseWindow("Shop_MGift", true);
			end
			if(IsWindowShow("ShowShop_MBuy")) then
				CloseWindow("ShowShop_MBuy", true);
			end
			CancelLastOp(FrameInfoList.FITTINGROOM_BUY_ITEM_CONFIRM);
			g_CityData = {};
			g_CityData[1] = tonumber(arg1);	--在货架的位置
			g_CityData[2] = arg2;	--物品名字
			g_CityData[3] = tonumber(arg3);	--货物售价
			g_CurUint = tonumber(arg4);
			g_FrameInfo = FrameInfoList.FITTINGROOM_BUY_ITEM_CONFIRM;
		end

	
	elseif ( event == "JIYUANSHOP_BUY_ITEM_CONFIRM" ) then
		if(arg0 == "close") then
			if(g_FrameInfo == FrameInfoList.JIYUANSHOP_BUY_ITEM_CONFIRM and this:IsVisible())then
			--如果是关于购物弹出的窗口，才关闭
				g_CityData = {};
				this:Hide();
			end
			return -1;
		elseif(arg0 == "open") then
			if(IsWindowShow("Shop_MBuy")) then
				CloseWindow("Shop_MBuy", true);
			end
			if(IsWindowShow("Shop_MGift")) then
				CloseWindow("Shop_MGift", true);
			end
			if(IsWindowShow("ShowShop_MBuy")) then
				CloseWindow("ShowShop_MBuy", true);
			end
			CancelLastOp(FrameInfoList.JIYUANSHOP_BUY_ITEM_CONFIRM);
			g_CityData = {};
			g_CityData[1] = tonumber(arg1);	--index
			g_FrameInfo = FrameInfoList.JIYUANSHOP_BUY_ITEM_CONFIRM;
		end
	elseif( event == "PET_SYNC_CONFIRM" ) then
		g_CityData[1] = tonumber(arg0);
		g_CityData[2] = tonumber(arg1);
		CancelLastOp(FrameInfoList.PET_SYNC_CONFIRM);
		g_FrameInfo = FrameInfoList.PET_SYNC_CONFIRM;
	elseif( event == "CONFIRM_USE_SDCZ" ) then
		g_SDCZ_ItemIdx = tonumber(arg0);
		g_SDCZ_ItemTableIdx = tonumber(arg1);
		g_SDCZ_HaveQuestItem = tonumber(arg2);
		CancelLastOp(FrameInfoList.CONFIRM_USE_SDCZ);
		g_FrameInfo = FrameInfoList.CONFIRM_USE_SDCZ;
	elseif( event == "CONFIRM_STRELATION_ALYEXP" ) then
		g_ShituRelation[1] = tonumber(arg0);
		g_ShituRelation[2] = tonumber(arg1);
		g_ShituRelation[3] = tonumber(arg2);
		g_ShituRelation[4] = tonumber(arg3);
		--CancelLastOp(FrameInfoList.STALYEXP_CONFIRM);
		g_FrameInfo = FrameInfoList.STALYEXP_CONFIRM;
	--寄售商店购买确认消息
	elseif event == "CONFIRM_COMMISION_BUY" then
		if(arg0 == "close") then
			if(g_FrameInfo == FrameInfoList.COMMISION_BUY and this:IsVisible())then
			--如果是寄售商店确认框，才关闭
				CommisionBuyData = {};
				this:Hide();
			end
			return -1;
		elseif(arg0 == "open") then
			CommisionBuyData = {};
			CommisionBuyData[1] = arg1;	--物品名称
			CommisionBuyData[2] = arg2;	--价格
			CancelLastOp(FrameInfoList.COMMISION_BUY);
			g_FrameInfo = FrameInfoList.COMMISION_BUY;
		end
	--炫装赠送商城购买确认
	elseif event == "CONFIRM_IMDRESS_BUYTOOTHER" then
		if(arg0 == "close") then
			if(g_FrameInfo == FrameInfoList.IMDressBuyToOther and this:IsVisible())then
			--如果是炫装赠送商城确认框，才关闭
				IMDressBuyToOtherData = {};
				this:Hide();
			end
			return -1;
		elseif(arg0 == "open") then
			IMDressBuyToOtherData = {};
			IMDressBuyToOtherData[1] = arg1;
			IMDressBuyToOtherData[2] = arg2;
			local Friendguid = arg2;
			CancelLastOp(FrameInfoList.IMDressBuyToOther);
			g_FrameInfo = FrameInfoList.IMDressBuyToOther;
		end
		
	elseif event == "CLOSE_MINGZHENJIANGHU_CONFIRM" then
		if g_FrameInfo == FrameInfoList.MINGZHENJIANGHU_CONFIRM and this:IsVisible() then
			this:Hide()
		end
		return -1
	elseif event == "TIME_UPDATE" then
		if(this:IsVisible() and g_FrameInfo == FrameInfoList.STALL_RENT_FRAME ) then
			local xNow, yNow;
			xNow, yNow = Player:GetPos();

			local askPosX = Variable:GetVariable("AskBaiTanPosX");
			local askPosY = Variable:GetVariable("AskBaiTanPosY");

			if(tostring(xNow) ~= askPosX or tostring(yNow) ~= askPosY) then
				MessageBox_Self_Cancel_Clicked(1);
			end
		end

		return -1;
	end
	if g_FrameInfo == FrameInfoList.QUIT_GAME   then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "您确定要离开天龙八部游戏世界吗？";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end

	if ( event == "RECYCLE_DEL_ITEM" ) then
		Recycle_Type = tonumber(arg0);
		Recycle_CurSelectItem = tonumber(arg1);
		CancelLastOp(FrameInfoList.RECYCLE_DEL_ITEM);
		g_FrameInfo = FrameInfoList.RECYCLE_DEL_ITEM;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "您确定要取消此次收购吗？";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end

	if ( event == "OPEN_IS_SELL_TO_RECSHOP" ) then
		Recycle_Bag_idx = tonumber(arg0);
		Recycle_Shop_idx = tonumber(arg1);
		Recycle_Shop_Num =  tonumber(arg2);
		Recycle_Shop_AllPrice =  tonumber(arg3);
		CancelLastOp(FrameInfoList.OPEN_IS_SELL_TO_RECSHOP);
		g_FrameInfo = FrameInfoList.OPEN_IS_SELL_TO_RECSHOP;
		local name = PlayerShop:GetRecycleItem(Recycle_Shop_idx,3,"name");
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "#W您要出售的材料为#G"..name.."#W，数量为"..Recycle_Shop_Num.."#W,所获金钱为#Y#{_MONEY"..Recycle_Shop_AllPrice.."}";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end
	if ( event == "CONFIRM_STENGTH" ) then
		Stength_Equip_Idx = tonumber(arg0);
		Stength_Item_Idx = tonumber(arg1);
		CancelLastOp(FrameInfoList.CONFIRM_STENGTH);
		g_FrameInfo = FrameInfoList.CONFIRM_STENGTH;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "#{CLJY_140225_03}";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end

	if ( event == "EXCHANGE_BANGGONG" ) then
		BangGong_Value = tonumber(arg0);
		ObjCaredID = tonumber(arg1); --这里不需要在使用GetNPCIDByServerID了
		if ObjCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MsgBox");
		end
		local extravalue = math.floor(BangGong_Value*0.1)
		CancelLastOp(FrameInfoList.EXCHANGE_BANGGONG);
		g_FrameInfo = FrameInfoList.EXCHANGE_BANGGONG;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "#{BGCH_8922_28}"..BangGong_Value.."#{BGCH_8922_29}"..extravalue.."#{BGCH_8922_30}";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end

	if ( event == "PUT_GUILDMONEY" ) then
		GuildMoney_Value = tonumber(arg0);
		ObjCaredID = tonumber(arg1); --这里不需要在使用GetNPCIDByServerID了
		if ObjCaredID ~= -1 then
		--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MsgBox");
		end
		local value = math.floor(GuildMoney_Value*0.9)
		CancelLastOp(FrameInfoList.PUT_GUILDMONEY);
		g_FrameInfo = FrameInfoList.PUT_GUILDMONEY;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "#{BPZJ_0801014_008}#{_MONEY"..GuildMoney_Value.."}#{BPZJ_0801014_009}#{_MONEY"..value.."}#{BPZJ_0801014_013}";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end

	if ( event == "CONFIRM_RE_IDENTIFY" ) then
		RID_Equip_Idx = tonumber(arg0);
		--Stength_Item_Idx = tonumber(arg1);
		CancelLastOp(FrameInfoList.CONFIRM_RE_IDENTIFY);
		g_FrameInfo = FrameInfoList.CONFIRM_RE_IDENTIFY;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "重新鉴定装备资质时将优先扣除物品栏中已绑定的金刚砂或金刚锉，重新鉴定资质后的装备也将与您绑定，确定要继续鉴定吗？#r#G提示：如果不想鉴定后的装备绑定，请将背包中已绑定的金刚砂和金刚锉放入仓库再来鉴定。#W";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end

	if ( event == "KICK_MEMBER_MSGBOX" ) then
		Member_Idx = tonumber(arg0);
		Member_Name = arg1;
		CancelLastOp(FrameInfoList.KICK_MEMBER_MSGBOX);
		g_FrameInfo = FrameInfoList.KICK_MEMBER_MSGBOX;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0");
		local msg = "#cfff263你确定要将玩家#G"..Member_Name.."#cfff263开除出帮会吗？";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end

	--退出群确认
	if ( event == "QUIT_CHATGROUP_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("");	--标题
		g_currentIndex = tonumber( arg0 );
		MessageBox_Self_Text:SetText( tostring(arg1)); -- 要退出？
		g_FrameInfo = FrameInfoList.QUIT_CHATGROUP_CONFIRM;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
	end
	--解散群确认
	if ( event == "DISMISS_CHATGROUP_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("");			-- 设置标题
		g_currentIndex = tonumber( arg0 );
		MessageBox_Self_Text:SetText(tostring(arg1)); --要解散？
		g_FrameInfo = FrameInfoList.DISMISS_CHATGROUP_CONFIRM;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
	end

	--2015情人节排行榜兑换二次确认
	if ( event == "ROSERANK_EXCHANGE_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("");			-- 设置标题
		g_msgFrameVar[1] = tonumber( arg0 );
		g_msgFrameVar[2] = tonumber( arg1 );
		g_msgFrameVar[3] = tostring( arg2 );
		MessageBox_Self_Text:SetText(g_msgFrameVar[3]);
		g_FrameInfo = FrameInfoList.ROSERANK_EXCHANGE_CONFIRM;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
	end

	--2015七夕情人节排行榜兑换二次确认
	if ( event == "QIXIRANK_EXCHANGE_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("");			-- 设置标题
		g_msgFrameVar[1] = tonumber( arg0 );
		g_msgFrameVar[2] = tonumber( arg1 );
		g_msgFrameVar[3] = tostring( arg2 );
		MessageBox_Self_Text:SetText(g_msgFrameVar[3]);
		g_FrameInfo = FrameInfoList.QIXIRANK_EXCHANGE_CONFIRM;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
	end
	
	if ( event == "OPEN_PAID_WORLD_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("");			-- 设置标题
		g_msgFrameVar[1] = tostring( arg0 );
		MessageBox_Self_Text:SetText("#{XZLT_240228_5}");
		g_FrameInfo = FrameInfoList.OPEN_PAID_WORLD_CONFIRM;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
	end
	
	--解散战团确定
	if ( event == "DISMISS_ZHANTUAN_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("");			-- 设置标题
		g_currentIndex = tonumber( arg0 );
		MessageBox_Self_Text:SetText("#{BHKF_140909_330}");
		g_FrameInfo = FrameInfoList.DISMISS_ZHANTUAN_CONFIRM;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
	end











    --- End of 势力

    --- 有未保存的游戏设置，是否保存？
    if( event == "CONFIRM_SAVE_GAME_SETUP" )then
        g_MSG_Box_GameSetup_curt_Window_TagIndex = tonumber( arg0 )
        g_MSG_Box_GameSetup_next_Window_TagIndex = tonumber( arg1 )
        local windowName = tostring( arg2 )

		CancelLastOp( FrameInfoList.CONFIRM_SAVE_GAME_SETUP )
		g_FrameInfo = FrameInfoList.CONFIRM_SAVE_GAME_SETUP

        local strText = ScriptGlobal_Format( "#{XTSZYH_111220_02}", windowName )
        MessageBox_Self_Text:SetText( strText )

		MessageBox_Self_UpdateRect();
		this:Show();
        return 1
    end

	---确定开始自动寻路么？
	if ( event == "AUTOMOVE_CONFIRM_NOPKVALUE" ) then
	    MessageBox_Self_Text:SetText( tostring(arg0) )
        MessageBox_Self_DragTitle:SetText("#{INTERFACE_XML_94}");
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.AUTOMOVE_CONFIRM_NOPKVALUE
		this:Show();
	end

	---确定开始自动寻路么？
	if( event == "AUTOMOVE_CONFIRM_UPPKVALUE") then
	    MessageBox_Self_Text:SetText( tostring(arg0) )
        MessageBox_Self_DragTitle:SetText("#{INTERFACE_XML_94}");
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.AUTOMOVE_CONFIRM_UPPKVALUE
	end

	if(event=="PNEUMA_LOCK_CONFIRM") then
		MessageBox_Self_Text:SetText( "#{ZYXT_120528_116}" )
		MessageBox_Self_UpdateRect()
		g_FrameInfo = FrameInfoList.PNEUMA_LOCK_CONFIRM
		MessageBox_Self_ClearVar()
		--PushDebugMessage(arg0)
		g_msgFrameVar[1] = tonumber(arg0)
		--客户端锁
		Pneuma:SetClientLock(g_msgFrameVar[1], "lock")
		this:Show()
	elseif (event=="PNEUMA_JUYUAN_CONFIRM") then
		MessageBox_Self_Text:SetText( "#{ZYXT_120528_175}" )
		MessageBox_Self_UpdateRect()
		g_FrameInfo = FrameInfoList.PNEUMA_JUYUAN_CONFIRM
		MessageBox_Self_ClearVar()
		--PushDebugMessage(arg0)
		--g_msgFrameVar[1] = tonumber(arg0)
		this:Show()
	end

	if(event == "AUTOMOVE_CONFIRM_FENGMING") then
		MessageBox_Self_Text:SetText( tostring(arg0) )
      		MessageBox_Self_DragTitle:SetText("#{INTERFACE_XML_94}");
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.AUTOMOVE_CONFIRM_FENGMING
	end

	-- if (event == "INFANT_CARD_COMPOSE_CONFIRM") then
	-- 	MessageBox_Self_ClearVar()
	-- 	g_msgFrameVar[1] = tonumber(arg0)
	-- 	g_msgFrameVar[2] = tonumber(arg1)
	-- 	ObjCaredID = tonumber(arg2); --这里不需要在使用GetNPCIDByServerID了
	-- 	if ObjCaredID ~= -1 then
	-- 		--开始关心NPC
	-- 		this:CareObject(ObjCaredID, 1, "MsgBox");
	-- 	end
	-- 	MessageBox_Self_Text:SetText("#{KPWFS_131112_27}" )
 --        MessageBox_Self_DragTitle:SetText("");
	-- 	MessageBox_Self_UpdateRect();
	-- 	g_FrameInfo = FrameInfoList.INFANT_CARD_COMPOSE_CONFIRM
	-- 	this:Show();
	-- end
	-- if (event == "INFANT_CARD_STRENGTH_CONFIRM") then
	-- 	MessageBox_Self_ClearVar()
	-- 	g_msgFrameVar[1] = tonumber(arg0)
	-- 	ObjCaredID = tonumber(arg1); --这里不需要在使用GetNPCIDByServerID了
	-- 	if ObjCaredID ~= -1 then
	-- 		--开始关心NPC
	-- 		this:CareObject(ObjCaredID, 1, "MsgBox");
	-- 	end
	-- 	MessageBox_Self_Text:SetText("#{KPWFS_131112_49}")
 --        MessageBox_Self_DragTitle:SetText("");
	-- 	MessageBox_Self_UpdateRect();
	-- 	g_FrameInfo = FrameInfoList.INFANT_CARD_STRENGTH_CONFIRM
	-- 	this:Show();
	-- end
	-- if (event == "INFANT_CARD_TRANSFER_CONFIRM") then
	-- 	MessageBox_Self_ClearVar()
	-- 	g_msgFrameVar[1] = tonumber(arg0)
	-- 	g_msgFrameVar[2] = tonumber(arg1)
	-- 	ObjCaredID = tonumber(arg2); --这里不需要在使用GetNPCIDByServerID了
	-- 	if ObjCaredID ~= -1 then
	-- 		--开始关心NPC
	-- 		this:CareObject(ObjCaredID, 1, "MsgBox");
	-- 	end
	-- 	MessageBox_Self_Text:SetText("#{KPWFS_131112_70}")
 --        MessageBox_Self_DragTitle:SetText("");
	-- 	MessageBox_Self_UpdateRect();
	-- 	g_FrameInfo = FrameInfoList.INFANT_CARD_TRANSFER_CONFIRM
	-- 	this:Show();
	-- end
	if (event == "INFANT_HERO_CHOICE_CONFIRM") then
		MessageBox_Self_ClearVar()
		g_msgFrameVar[1] = tonumber(arg0)
		g_msgFrameVar[2] = tonumber(arg1)
		ObjCaredID = tonumber(arg2); --这里不需要在使用GetNPCIDByServerID了
		if ObjCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MsgBox");
		end
		local heroName = {
			[1] = "乔峰",
			[2] = "段誉",
			[3] = "虚竹",
			[4] = "王语嫣",
		}
		local heroType = Infant:GetHeroType(0)--直接写上0了，罪过
		if tonumber(arg1) == 0 then
			local str = ScriptGlobal_Format("#{YXPY_20131118_37}", heroName[g_msgFrameVar[1]])
			MessageBox_Self_Text:SetText(str)
		elseif tonumber(arg1) == 1 then
			local str = ScriptGlobal_Format("#{YXPY_20131118_42}", heroName[heroType], heroName[g_msgFrameVar[1]])
			MessageBox_Self_Text:SetText(str)
		end


        MessageBox_Self_DragTitle:SetText("");
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.INFANT_HERO_CHOICE_CONFIRM
		this:Show();
	end

	if (event == "INFANT_CARD_EQUIP_CONFIRM") then
		MessageBox_Self_ClearVar()
		g_msgFrameVar[1] = tonumber(arg0)
		MessageBox_Self_DragTitle:SetText("#{ZSLZ_XML_1}")
		if tonumber(arg1) == 0 then
			MessageBox_Self_Text:SetText("#{YXPY_20131118_94}")
		else
			MessageBox_Self_Text:SetText("#{XNGX_120815_5}")
		end
		MessageBox_Self_DragTitle:SetText("#{ZSLZ_XML_1}")
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.INFANT_CARD_EQUIP_CONFIRM
		this:Show();
	elseif (event=="GUILDSHOP_ITEM_SURE") then
		MessageBox_Self_ClearVar()
		objCaredID = tonumber(arg3); --这里不需要在使用GetNPCIDByServerID了
		if objCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(objCaredID, 1, "MsgBox")
		end
		g_msgFrameVar[1] = tonumber(arg0)--索引
		g_msgFrameVar[2] = tonumber(arg1)--帮贡
		g_msgFrameVar[3] = tostring(arg2)--道具名字
		local strText = ScriptGlobal_Format( "#{BHSC_140509_49}", g_msgFrameVar[3],g_msgFrameVar[2] )
		MessageBox_Self_Text:SetText(strText)
		MessageBox_Self_DragTitle:SetText("")
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.GUILDSHOP_ITEM_SURE
		this:Show();
	end

	if (event == "BUDGETPLANINFO_DOWNPAY") then

		MessageBox_Self_ClearVar()
		g_msgFrameVar[1] = tonumber(arg0)

		local nGemID = tonumber(arg1)
		local DownPayPrice = tonumber(arg2)
		if g_msgFrameVar[1]<1 or g_msgFrameVar[1]>5 then
			return
		end
		local GemName = DoubleGem:GetGemNamebyID(nGemID)
		--为了显示这个时间。。。。。。
		local	nServerDayTime = BudgetPlanGem:GetServerDayTime() + 29
		if math.mod(nServerDayTime,1000)>=365 then
			local nYer = (math.floor(nServerDayTime/1000) + 1)*1000
			local nDate = (math.mod(nServerDayTime,1000)-365)
			nServerDayTime =  nYer + nDate

		end
		local year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(nServerDayTime)
		local strYMD = year.."年"..month.."月"..day.."日"
		local strText=ScriptGlobal_Format( "#{FQBS_140508_42}",GemName,DownPayPrice, strYMD)

		MessageBox_Self_DragTitle:SetText("");
		MessageBox_Self_Text:SetText( strText )

		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.BUDGETPLANINFO_DOWNPAY
		this:Show();
	end

	if (event == "BUDGETPLANINFO_REPAY") then

		MessageBox_Self_ClearVar()
		g_msgFrameVar[1] = tonumber(arg0)

		local nGemID = tonumber(arg1)
		local nPayingYuanBao = tonumber(arg2)
		local nSelcetStage = tonumber(arg3)
		local nPayingDueTime = tonumber(arg4)
		local nCompleteGem = tonumber(arg5)
		local nStage = tonumber(arg6)
		local strText =""
		if g_msgFrameVar[1]<0 or g_msgFrameVar[1]>4 then
			return
		end

		local GemName = DoubleGem:GetGemNamebyID(nGemID)
		if nStage == 100 then
			local CompleteGemName = DoubleGem:GetGemNamebyID(nCompleteGem)
			strText=ScriptGlobal_Format( "#{FQBS_140508_50}", GemName,nPayingYuanBao,nSelcetStage)
		else
			local year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(nPayingDueTime)
			local	strYMD = year.."年"..month.."月"..day.."日"
			strText=ScriptGlobal_Format( "#{FQBS_140508_49}", GemName,nPayingYuanBao,nSelcetStage,strYMD)
		end
		MessageBox_Self_DragTitle:SetText("");
		MessageBox_Self_Text:SetText( strText )

		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.BUDGETPLANINFO_REPAY
		this:Show();
	end

	--if event == "SHENGMINGXIANHE_CONFIRM" then
	--		MessageBox_Self_ClearVar()
	--	MessageBox_Self_DragTitle:SetText("#{MDJH_140303_12}")
	--	local nType = tonumber(arg0)
	--	local num1 = tonumber(arg1)
	--	local num2 = tonumber(arg2)
	--	local num3 = tonumber(arg3)
	--	MessageBox_Self_Shengmingxianhe_confirm(nType,num1,num2,num3)

	--end

	if event == "INFANT_DRESS_CUT_CONFIRM" then
		if arg0 and tonumber(arg0) == 47 then
			MessageBox_Self_ClearVar()
			CancelLastOp(FrameInfoList.INFANT_DRESS_CUT_PAINT_CONFIRM)

			MessageBox_Self_DragTitle:SetText("#{ZNSZ_140718_126}")
			MessageBox_Self_Text:SetText("#{ZNSZ_140718_89}")
			g_FrameInfo = FrameInfoList.INFANT_DRESS_CUT_PAINT_CONFIRM

			this:Show()
		end
	end

	if ( event == "MILITARYRANKSHOPBUYCONFIRM" ) then
		MessageBox_Self_ClearVar();
		g_msgFrameVar[ 1 ] = tonumber( arg0 );	-- 表格索引
		g_msgFrameVar[ 2 ] = tostring( arg1 );	-- 物品名称
		g_msgFrameVar[ 3 ] = tonumber( arg2 );	-- 军功兑换值
		ObjCaredID = tonumber( arg3 );			-- NpcId
		this:CareObject( ObjCaredID, 1, "MsgBox" );
		MilitaryShopTableIndex = g_msgFrameVar[ 1 ];
		local strText = ScriptGlobal_Format( "#{JWSD_140821_31}", g_msgFrameVar[ 2 ], g_msgFrameVar[ 3 ] );
		MessageBox_Self_Text:SetText( strText );
		MessageBox_Self_DragTitle:SetText( "#{JWSD_140821_30}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.MILITARYRANKSHOPBUYCONFIRM;
		this:Show();
	elseif ( event == "NOBILITYSHOPBUYCONFIRM" ) then
		MessageBox_Self_ClearVar();
		g_msgFrameVar[ 1 ] = tonumber( arg0 );	-- 表格索引
		g_msgFrameVar[ 2 ] = tostring( arg1 );	-- 物品名称
		g_msgFrameVar[ 3 ] = tonumber( arg2 );	-- 军功兑换值
		ObjCaredID = tonumber( arg3 );			-- NpcId
		this:CareObject( ObjCaredID, 1, "MsgBox" );
		NobilityShopTableIndex = g_msgFrameVar[ 1 ];
		local strText = ScriptGlobal_Format( "#{JWSD_140821_48}", g_msgFrameVar[ 2 ], g_msgFrameVar[ 3 ] );
		MessageBox_Self_Text:SetText( strText );
		MessageBox_Self_DragTitle:SetText( "#{JWSD_140821_30}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.NOBILITYSHOPBUYCONFIRM;
		this:Show();
	elseif ( event == "SHIDESHOPBUYCONFIRM" ) then
		MessageBox_Self_ClearVar();
		g_msgFrameVar[ 1 ] = tonumber( arg0 );	-- 表格索引
		g_msgFrameVar[ 2 ] = tostring( arg1 );	-- 物品名称
		g_msgFrameVar[ 3 ] = tonumber( arg2 );	-- 师德兑换值
		ObjCaredID = tonumber( arg3 );			-- NpcId
		this:CareObject( ObjCaredID, 1, "MsgBox" );
		ShideShopTableIndex = g_msgFrameVar[ 1 ];
		local strText = ScriptGlobal_Format( "#{SDSD_150514_23}", 1,g_msgFrameVar[ 2 ], g_msgFrameVar[ 3 ] );
		MessageBox_Self_Text:SetText( strText );
		MessageBox_Self_DragTitle:SetText( "#{SDSD_150514_22}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.SHIDESHOPBUYCONFIRM;
		this:Show();
	--elseif ( event == "CONFIRM_MULTIBUY" ) then
		--local msg = ScriptGlobal_Format( "#{SHPLGM_150428_19}", arg0, arg1, arg2, arg3)
		--MessageBox_Self_Text:SetText(msg)
		--MessageBox_Self_UpdateRect();
		--this : Show()
		--CancelLastOp(FrameInfoList.CONFIRM_MULTIBUY);
		--g_FrameInfo = FrameInfoList.CONFIRM_MULTIBUY
	elseif ( event == "TIANJIANGQIFU_CONFIRM" ) then
		MessageBox_Self_ClearVar();
		FuJiangTLUIType = tonumber( arg0 );		-- 0:非活动界面 1:活动界面
		if FuJiangTLUIType == 100 then   --2019福降令
			MessageBox_Self_Text:SetText( "#{FJTL_140305_25}" );
		else
			MessageBox_Self_Text:SetText( "#{FJTL_140305_22}" );
		end
			MessageBox_Self_DragTitle:SetText( "" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.TIANJIANGQIFU_CONFIRM;
		this:Show();
	--坐骑续时
	elseif ( event == "MOUNT_PROLONG_CONFIRM" ) then

		MessageBox_Self_ClearVar();
		Zuoqi_Bagpos = tonumber( arg0 );		--坐骑bagpos
		ProlongDays = tonumber( arg1 );		--续期天数
		MessageBox_Self_Text:SetText( "#{XQZJ_180831_17}" );
		MessageBox_Self_DragTitle:SetText( "" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.MOUNT_PROLONG_CONFIRM;
		this:Show();
	elseif ( event == "RESIGN_CONFIRM" ) then
		MessageBox_Self_ClearVar();
		g_msgFrameVar[ 1 ] = tonumber( arg0 );
		ResignIndex = g_msgFrameVar[ 1 ]
		MessageBox_Self_Text:SetText( "#{MYQD_150513_32}" );
		MessageBox_Self_DragTitle:SetText( "#{MYQD_150513_29}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.RESIGN_YUANBAO_CONFIRM;
		this:Show();

	elseif ( event == "ZHENGBASAI_PET_CONFIRM" ) then
		MessageBox_Self_ClearVar();
		MessageBox_Self_Text:SetText( arg0);
		--MessageBox_Self_DragTitle:SetText( "#{SJFL_150608_44}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_ZHENGBASAI_PET;
		this:Show();
	elseif ( event == "HAOXIA_PET_CONFIRM" ) then
		MessageBox_Self_ClearVar();
		MessageBox_Self_Text:SetText( arg0);
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_HAOXIA_PET;
		this:Show();

	elseif ( event == "HAOXIA_EXCHANGE_BOUNS_CONFIRM" ) then
		MessageBox_Self_ClearVar();
		MessageBox_Self_Text:SetText( arg0);
		MessageBox_Self_UpdateRect();
		g_HXL_nIndex = tonumber(arg1)
		g_HXL_version = tonumber(arg2)
		g_FrameInfo = FrameInfoList.CONFIRM_HAOXIA_EXCHANGE_BOUNS;
		this:Show();
	elseif ( event == "LIJIN_DISCNT_CONFIRM") then
		MessageBox_Self_ClearVar();
		g_HXL_nIndex = tonumber(arg0)
		local nMD = tonumber(arg1)
		MessageBox_Self_Text:SetText( ScriptGlobal_Format("#{LJSD_180312_10}",2-nMD));
		MessageBox_Self_UpdateRect();
		
		g_FrameInfo = FrameInfoList.CONFIRM_LIJINDISCOUNT;
		this:Show();		
	elseif ( event == "CONFIRM_ROSEWEAPON" ) then
		g_RoseWeaponIndex = tonumber( arg1 );
		g_RoseScriptID = tonumber( arg2 );
		g_RoseWeaponID = tonumber( arg3 );
		MessageBox_Self_ClearVar();
		MessageBox_Self_Text:SetText( arg0);
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_ROSEWEAPON;
		this:Show();
	elseif ( event == "RESIGN_SUMMERVACATION" ) then
		MessageBox_Self_ClearVar();
		g_msgFrameVar[ 1 ] = tonumber( arg0 );
		ClickId = g_msgFrameVar[ 1 ]
		MessageBox_Self_Text:SetText( arg1);
		MessageBox_Self_DragTitle:SetText( "#{SJFL_150608_44}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_SUMMERVACATION;
		this:Show();
	elseif ( event == "ZHOUNIANQING_PRIZE_CONFIRM" ) then
		MessageBox_Self_ClearVar();
		g_msgFrameVar[ 1 ] = tonumber( arg0 );
		dayIndex = g_msgFrameVar[ 1 ]
		local strText = ScriptGlobal_Format("#{BZNMR_170216_09}",tonumber( arg1 ),PlayerPackage:GetItemName( tonumber( arg2 ) ),tonumber( arg3 ))
		MessageBox_Self_Text:SetText( strText );
		MessageBox_Self_DragTitle:SetText( "#{BZNMR_170216_08}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_ZHOUNIANQING_PRIZE;
		this:Show();
	elseif ( event == "BIN_COMMON_CONFIRM" ) then
		g_Common_Type = tonumber( arg1 );
		g_Common_Param = tonumber( arg2 );
		g_Common_Title = tostring( arg3 );
		MessageBox_Self_ClearVar();
		MessageBox_Self_Text:SetText( arg0);
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_BIN_COMMON;
		this:Show();
	elseif	(event == "ALLIANCESHOP_BUY_CONFIRM") then
		MessageBox_Self_ClearVar()
		g_msgFrameVar[1] = tonumber(arg0)
		g_msgFrameVar[2] = tonumber(arg1)
		ShideShopTableIndex = g_msgFrameVar[1]
		local	ObjCaredID	=	DataPool:GetNPCIDByServerID(g_msgFrameVar[2])
		this:CareObject( ObjCaredID, 1, "MsgBox" );
		local	nItemType, nMaxNum, nPrize, CommodityName = KAllianceShop:EnumKAllianceShopCommodityInfo(g_msgFrameVar[1])
		local	strText	= ScriptGlobal_Format("#{ZMSD_150811_59}",CommodityName,nPrize)
		MessageBox_Self_Text:SetText( strText );
		MessageBox_Self_DragTitle:SetText( "#{ZMSD_150811_58}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.ALLIANCESHOP_BUY_CONFIRM;
		this:Show();
	elseif	(event == "MSDSHOP_BUY_CONFIRM") then
		MessageBox_Self_ClearVar()
		g_msgFrameVar[1] = tonumber(arg0)
		g_msgFrameVar[2] = tonumber(arg1)
		ShideShopTableIndex = g_msgFrameVar[1]
		local	ObjCaredID	=	DataPool:GetNPCIDByServerID(g_msgFrameVar[2])
		this:CareObject( ObjCaredID, 1, "MsgBox" );
		local	nItemType, nMaxNum, nPrize, CommodityName = KMSDShop:EnumKMSDShopCommodityInfo(g_msgFrameVar[1])
		local	strText	= ScriptGlobal_Format("#{MSSD_180529_13}",CommodityName,nPrize)
		MessageBox_Self_Text:SetText( strText );
		--MessageBox_Self_DragTitle:SetText( "#{ZMSD_150811_58}" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_MSDSHOP_BUY_CONFIRM;
		this:Show();		
	elseif ( event == "BIN_MENGCHONG_CONFIRM" ) then
		g_newMengChongtype = tonumber( arg0 );
		g_newMengChongvalue = tonumber( arg1 );
		g_newMengChongtitle = tostring( arg2 );
		MessageBox_Self_ClearVar();
		local szHS = ScriptGlobal_Format("#{MCJC_170727_41}", g_newMengChongtitle)
		MessageBox_Self_Text:SetText( szHS);
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_MENGCHONG_COMMON;
		this:Show();
	elseif ( event == "BIN_MENGCHONG_REMOVE_CONFIRM" ) then
		g_newMengChongTableIndex = tonumber( arg0 );
		g_newMengChongtype = tonumber( arg1 );
		g_newMengChongvalue = tonumber( arg2 );
		MessageBox_Self_ClearVar();
		local szHS = ""
		if PlayerPackage:IsProtectGoodsByItemTableIndex(g_newMengChongTableIndex) == 1 then
			szHS = ScriptGlobal_Format("#{MCJC_170727_155}", g_newMengChongtype )	
		else
			szHS = ScriptGlobal_Format("#{MCJC_170727_67}", g_newMengChongtype )
		end

		MessageBox_Self_Text:SetText( szHS);
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.CONFIRM_MENGCHONG_REMOVE_COMMON;
		this:Show();
	elseif (event == "WUYIZHUANHUAN_CONFIRM") then
		MessageBox_Self_ClearVar();
		g_msgFrameVar[1] = tonumber( arg1 );
		g_msgFrameVar[2] = tonumber( arg2 );
		g_msgFrameVar[3] = tonumber( arg3 );
		MessageBox_Self_Text:SetText( arg0 );
		MessageBox_Self_DragTitle:SetText( "" );
		MessageBox_Self_UpdateRect();
		g_FrameInfo = FrameInfoList.WUYIZHUANHUAN_CONFIRM;
		this:Show();
	elseif (event == "GUILD_TIANDAO_RET") then
			MessageBox_Self_ClearVar();
			g_msgFrameVar[1] = tonumber( arg0 );	--当前天道
			g_msgFrameVar[2] = tonumber( arg1 );	--要提交的数量
			g_msgFrameVar[3] = tonumber( arg2 );	--已提交的数量
			g_msgFrameVar[4] = tonumber( arg3 );	--npcid
			
			
			local maxtiandao = 7500
			local maxgeren = 100
			--紫微玉：天道值 = 1:1
			local str1 = ""
			if g_msgFrameVar[1] >= maxtiandao then
				str1 = "#{ZWLP_200812_27}"
			elseif g_msgFrameVar[1]+g_msgFrameVar[2] <= maxtiandao then
				str1 = ScriptGlobal_Format("#{ZWLP_200812_26}",g_msgFrameVar[2])
			else
				local value = g_msgFrameVar[1]+g_msgFrameVar[2]-maxtiandao
				str1 = ScriptGlobal_Format("#{ZWLP_200812_33}",value)
			end	
			
			local str2 = ""
			
			if g_msgFrameVar[3] >= maxgeren then
				str2 = "#{ZWLP_200812_29}"
			elseif g_msgFrameVar[3]+g_msgFrameVar[2] <= maxgeren then
				str2 = ScriptGlobal_Format("#{ZWLP_200812_28}",g_msgFrameVar[2])
			else
				local value = g_msgFrameVar[3]+g_msgFrameVar[2]-maxgeren
				str2 = ScriptGlobal_Format("#{ZWLP_200812_34}",value)			
			end
			
			local str = str1..str2.."#{ZWLP_200812_30}"
			

			MessageBox_Self_Text:SetText( str );
			MessageBox_Self_DragTitle:SetText( "" );
			MessageBox_Self_UpdateRect();
			g_FrameInfo = FrameInfoList.CONFIRM_CHANGE_NEW_ZIWEI;
			this:Show();		
	end

	return 1;
end

--===============================================
-- OnEvent()
--===============================================
function MessageBox_Self_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
		if g_FrameInfo == FrameInfoList.MAOHUABI_BUY_CONFIRMS then
			if this:IsVisible() then
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.SEND_SHUIYUEDONGTIAN then
			if this:IsVisible() then
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.LUHEXIEXIANG_CONFIRM then
			if this:IsVisible() then
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.LUHEXIEXIANG_SINGLEENTERCONFIRM then
			if this:IsVisible() then
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.LUHEXIEXIANG_REWARDCONFIRM then
			if this:IsVisible() then
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.OPEN_PAID_WORLD_CONFIRM then
			if this:IsVisible() then
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.COMMONGIFT_TITLE_CONFIRM then
			if this:IsVisible() then
				-- 解除背包格子蒙红锁定
				LifeAbility : Lock_Packet_Item( g_msgFrameVar[1], 0 )		
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.STEALSKILL_CONFIRM then
			if this:IsVisible() then
				this:Hide()
			end
		end
		if g_FrameInfo == FrameInfoList.RESET_STEALSKILL_CONFIRM then
			if this:IsVisible() then
				this:Hide()
			end
		end

		return 0
	end
	if event == "GEM_COMBINED_CONFIRM" then

		GemCombinedData[1] = tonumber( arg0 )
		GemCombinedData[2] = tonumber( arg1 )
		GemCombinedData[3] = tonumber( arg2 )
		GemCombinedData[4] = tonumber( arg3 )
		GemCombinedData[5] = tonumber( arg4 )
		GemCombinedData[6] = tonumber( arg5 )
		GemCombinedData[7] = arg6
		CancelLastOp(FrameInfoList.GEM_COMBINED_CONFIRM);
		g_FrameInfo = FrameInfoList.GEM_COMBINED_CONFIRM
		MessageBox_Self_UpdateFrame()
		return
	end
	if event == "EXCHANGE_MONEY_OVERFLOW" then
		MessageBox_Self_Text:SetText( "#Y您的钱已经到达上限，请尽快处理，在此期间不要做#R下线或者转移场景的操作，#Y否则会使得超出上限的金钱消失。" );

		MessageBox_Self_UpdateRect();
		CancelLastOp(FrameInfoList.EXCHANGE_MONEY_OVERFLOW);
		g_FrameInfo = FrameInfoList.EXCHANGE_MONEY_OVERFLOW

		this:Show();
	end
	if event == "GUILD_DEMIS_CONFIRM" then
		local TargetName = tostring( arg0 );
		local bType = tonumber(arg1);
		if bType == 0 then
			PushDebugMessage("#{BHCR_090727_01}")
			this:Hide();
			return
		elseif bType == 1 then
			MessageBox_Self_Text:SetText( "#{BHCR_090713_09}"..TargetName.."#{BHCR_090713_10}" );
		elseif bType == 2 then
			MessageBox_Self_Text:SetText( "你确定要将帮主的职位禅让给"..TargetName.."吗？禅后你的职位将为副帮主。" );
		end
		MessageBox_Self_UpdateRect();
		CancelLastOp(FrameInfoList.GUILD_DEMIS_CONFIRM);
		g_FrameInfo = FrameInfoList.GUILD_DEMIS_CONFIRM
		this:Show();
	end

	if event == "ENCHASE_CONFIRM" then
		MessageBox_Self_Text:SetText( "没有特殊材料会导致镶嵌失败之后宝石消失。您确定要继续镶嵌吗？" );
		EnchaseData[1] = tonumber( arg0 )
		EnchaseData[2] = tonumber( arg1 )
		EnchaseData[3] = tonumber( arg2 )
		EnchaseData[4] = tonumber( arg3 )
		CancelLastOp(FrameInfoList.ENCHASE_CONFIRM);
		g_FrameInfo = FrameInfoList.ENCHASE_CONFIRM
		this:Show();
	end

	if ( event == "SET_GUILD_FIRSTMAN_NAME" ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0#{BHCR_xml_XX(01)}");													-- 设置标题
		local szMsg = Guild:GetMyGuildInfo("FirstManName");
		if szMsg ~= "" then
			MessageBox_Self_Text:SetText( "#{BHCR_090713_08}"..szMsg);	-- 设置内容
		else
			MessageBox_Self_Text:SetText( "#{BHCR_090713_07}");
		end
		--MessageBox_Self_Text:SetText(szMsg);
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		CancelLastOp(FrameInfoList.SET_GUILD_FIRSTMAN_NAME);
		g_FrameInfo = FrameInfoList.SET_GUILD_FIRSTMAN_NAME;
		this:Show();
		--g_currentIndex = tonumber( arg0 );
		return;
	end

	if event == "ENCHASE_FOUR_CONFIRM" then  -- add:lby20080527确认4镶嵌
		MessageBox_Self_Text:SetText( "没有特殊材料会导致镶嵌失败之后宝石消失。您确定要继续镶嵌吗？" );
		EnchaseData[1] = tonumber( arg0 )
		EnchaseData[2] = tonumber( arg1 )
		EnchaseData[3] = tonumber( arg2 )
		EnchaseData[4] = tonumber( arg3 )
		CancelLastOp(FrameInfoList.ENCHASE_FOUR_CONFIRM);
		g_FrameInfo = FrameInfoList.ENCHASE_FOUR_CONFIRM
		this:Show();
	end

	-- 打开珍兽技能学习的二次确认界面
	if event == "OPEN_PETSKILLSTUDY_MSGBOX" then
		MessageBox_Self_Text:SetText( "你的珍兽即将获得两个手动技能，这个操作需要花费#{_EXCHG990000}，你确定吗？" );
		CancelLastOp(FrameInfoList.PET_SKILL_STUDY_CONFIRM);
		g_FrameInfo = FrameInfoList.PET_SKILL_STUDY_CONFIRM
		this:Show();
	end

	-- 关闭珍兽技能学习的二次确认界面
	if(event == "CLOSE_PETSKILLSTUDY_MSGBOX" ) then
		if(this:IsVisible() and  g_FrameInfo == FrameInfoList.PET_SKILL_STUDY_CONFIRM) then
			CancelLastOp(-1);
			this:Hide();
		end
		return;
	end
	-- 关闭回天丹二次确认界面
	if(event == "CLOSE_HUITIANDAN_MSGBOX" ) then
		if(this:IsVisible() and  g_FrameInfo == FrameInfoList.HUITIANDAN_USE_CONFIRM) then
			CancelLastOp(-1);
			this:Hide();
		end
		return;
	end
--	if event == "CARVE_CONFIRM" then
--		MessageBox_Self_Text:SetText( "注意！#您要雕琢的宝石或雕琢符为已绑定物品，雕琢后的宝石也将与您绑定，确认要继续雕琢的话请再次点击雕琢按钮。" );
--		CarveData[1] = tostring( arg0 )
--		CarveData[2] = tonumber( arg1 )
--		CarveData[3] = tonumber( arg2 )
--		CarveData[4] = tonumber( arg3 )
--		CarveData[5] = tonumber( arg4 )
--		CancelLastOp(FrameInfoList.CARVE_CONFIRM);
--		g_FrameInfo = FrameInfoList.CARVE_CONFIRM
--		this:Show();
--	end

	if(event == "OPEN_STALL_RENT_FRAME") then
		CancelLastOp(FrameInfoList.STALL_RENT_FRAME);
		--记录当前位置
		local xPos, yPos;
		xPos, yPos = Player:GetPos();
		Variable:SetVariable("AskBaiTanPosX", tostring(xPos), 1);
		Variable:SetVariable("AskBaiTanPosY", tostring(yPos), 1);

		this:Show();
		g_InitiativeClose = 0;
		g_FrameInfo = FrameInfoList.STALL_RENT_FRAME;

	elseif ( event == "MSGBOX_MAKESUREPVPCHALLENGE" ) then
	    local TargetName = tostring( arg0 )

		CancelLastOp(FrameInfoList.MAKESUREPVPCHALLENGE);
		g_FrameInfo = FrameInfoList.MAKESUREPVPCHALLENGE;
	    MessageBox_Self_Text:SetText( "您确认向"..TargetName.."提出宣战么？击败对方之后会增加您的杀气值，杀气高了人物死亡时会导致额外损失" );
		MessageBox_Self_UpdateRect();
		this:Show();

	elseif ( event == "MENU_SHOWACCEPTCHANGEPVP" ) then
		local Mode = tonumber( arg0 )
		local ModeText = ""
		if( 1 == Mode ) then
			CancelLastOp(FrameInfoList.FREEFORALL);

		    g_FrameInfo = FrameInfoList.FREEFORALL;
		    ModeText = "此模式下将会攻击除自己之外的所有玩家，请确认开启"
		end
		if( 2 == Mode ) then
			CancelLastOp(FrameInfoList.FREEFORTEAM);

		    g_FrameInfo = FrameInfoList.FREEFORTEAM;
		    ModeText = "此模式下将会攻击除队友之外的所有玩家，请确认开启"
		end
		if( 3 == Mode ) then
			--2014Q1大世界帮会功能改造,只有服务器配置在K服保留"帮会同盟"信息时,才能在K服开启帮会同盟混战PK模式
			if KVKInterface:IsInKVKServer() ==  1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
				return
			end
			CancelLastOp(FrameInfoList.FREEFORGUILD)

		    g_FrameInfo = FrameInfoList.FREEFORGUILD;
		    ModeText = "#{TM_20080311_18}"
		    --if IsInTServer() == 1 then
		    	--ModeText = "#{TFJCGZ_20200817_24}"
		    --end
		end
		if( 6 == Mode ) then
			CancelLastOp(FrameInfoList.FREEFORRAID)
		   g_FrameInfo = FrameInfoList.FREEFORRAID;
		   ModeText = "#{TDGZ_100809_70}"
		end


		--	只有1.在K服 2.服务器设置在K服不保留"帮会同盟"信息,才能开启"帮会模式"的PK模式
		if( 8 == Mode ) then
			if KVKInterface:IsInKVKServer() <= 0 or KVKInterface:IsEnableGuildLeagueInKServer() > 0 then
				return
			end
			CancelLastOp(FrameInfoList.FREE_FOR_KGUILD)
			g_FrameInfo = FrameInfoList.FREE_FOR_KGUILD
			ModeText = "#{KVKBH_140124_56}"
		end


		if( (Mode >= 1 and Mode <= 3) or 6 == Mode or 7 == Mode or 8 == Mode) then
		    MessageBox_Self_Text:SetText( ModeText );
			MessageBox_Self_UpdateRect();
		    this:Show();
		end

	elseif ( event == "MSGBOX_ACCEPTDUEL" ) then
	    local Name = tostring( arg0 )
	    local GUID = tostring( arg1 )
	    PVPFLAG.DuelName = Name
	    PVPFLAG.DuelGUID = GUID
	    g_FrameInfo = PVPFLAG.ACCEPTDUEL;
	    local MsgText = Name.."向您提出决斗，您是否同意？注意：在决斗中死亡将会有惩罚。"
	    MessageBox_Self_Text:SetText( MsgText )
		MessageBox_Self_UpdateRect();
	    this:Show();

	elseif(event == "OPEN_DISCARD_ITEM_FRAME") then
		argDISCARD_ITEM_FRAME0 = arg0;
		CancelLastOp(FrameInfoList.DISCARD_ITEM_FRAME);
		-- 增加界面互斥关闭逻辑Item_MultiUse
		if(IsWindowShow("Item_MultiUse")) then
			CloseWindow("Item_MultiUse", true)
		end
		-- 增加界面互斥关闭逻辑GuiShi_Exchange
		if(IsWindowShow("GuiShi_Exchange")) then
			CloseWindow("GuiShi_Exchange", true)
		end
		this:Show();
		g_InitiativeClose = 0;
		g_FrameInfo = FrameInfoList.DISCARD_ITEM_FRAME;

	elseif(event == "OPEN_CANNT_DISCARD_ITEM") then
		argCANNT_DISCARD_ITEM0 = arg0
		CancelLastOp(FrameInfoList.CANNT_DISCARD_ITEM);
		-- 增加界面互斥关闭逻辑Item_MultiUse
		if(IsWindowShow("Item_MultiUse")) then
			CloseWindow("Item_MultiUse", true)
		end
		-- 增加界面互斥关闭逻辑GuiShi_Exchange
		if(IsWindowShow("GuiShi_Exchange")) then
			CloseWindow("GuiShi_Exchange", true)
		end
		this:Show();
		g_InitiativeClose = 0;
		g_FrameInfo = FrameInfoList.CANNT_DISCARD_ITEM;

	elseif(event == "LOCK_ITEM_CONFIRM") then
		argLOCK_ITEM_FRAME0 = arg0;
		local g_LockItemInfo = tostring(arg1);
		CancelLastOp(FrameInfoList.LOCK_ITEM_CONFIRM_FRAME);
		MessageBox_Self_Text:SetText( g_LockItemInfo )
		MessageBox_Self_UpdateRect();
		this:Show();
		g_InitiativeClose = 0;
		g_FrameInfo = FrameInfoList.LOCK_ITEM_CONFIRM_FRAME;

	elseif(event == "AFFIRM_SHOW") then
		this:Show();
		g_InitiativeClose = 0;
		Quest_Number = tonumber(arg2);
		argFRAME_AFFIRM_SHOW0 = arg0;
		CancelLastOp(FrameInfoList.FRAME_AFFIRM_SHOW);
		g_FrameInfo = FrameInfoList.FRAME_AFFIRM_SHOW;


	-- 帮会成立需玩家确认
	elseif ( event == "GUILD_CREATE_CONFIRM" ) then
		argCREATE_CONFIRM0 = arg0
		CancelLastOp(FrameInfoList.GUILD_CREATE_CONFIRM);
		g_FrameInfo = FrameInfoList.GUILD_CREATE_CONFIRM;
		MessageBox_Self_Text:SetText("是要创建" .. argCREATE_CONFIRM0 .. "吗?");
		MessageBox_Self_UpdateRect();
		this:Show();

	-- 帮会删除需玩家确认
	elseif ( event == "GUILD_DESTORY_CONFIRM" ) then
		argDESTORY_CONFIRM0 = arg0
		CancelLastOp(FrameInfoList.GUILD_DESTORY_CONFIRM);
		g_FrameInfo = FrameInfoList.GUILD_DESTORY_CONFIRM;
		MessageBox_Self_Text:SetText("是要删除" .. argDESTORY_CONFIRM0 .. "吗?");
		MessageBox_Self_UpdateRect();
		this:Show();

	-- 帮会退出需玩家确认
	elseif ( event == "GUILD_QUIT_CONFIRM" ) then
		argQUIT_CONFIRM0 = arg0
		CancelLastOp(FrameInfoList.GUILD_QUIT_CONFIRM);
		g_FrameInfo = FrameInfoList.GUILD_QUIT_CONFIRM;
		MessageBox_Self_Text:SetText("是要退出" .. argQUIT_CONFIRM0 .. "吗?");
		MessageBox_Self_UpdateRect();
		this:Show();

	--帮会同盟退出确认
	elseif event == "GUILD_LEAGUE_QUIT_CONFIRM" then
		argQUIT_LEAGUE_CONFIRM0 = arg0;
		CancelLastOp(FrameInfoList.GUILD_LEAGUE_QUIT_CONFIRM);
		g_FrameInfo = FrameInfoList.GUILD_LEAGUE_QUIT_CONFIRM
		MessageBox_Self_Text:SetText( "你确定要退出"..argQUIT_LEAGUE_CONFIRM0.."同盟吗？" );
		MessageBox_Self_UpdateRect();
		this:Show();

	--帮会同盟创建确认
	elseif event == "GUILD_LEAGUE_CREATE_CONFIRM" then
		argCREATE_LEAGUE_CONFIRM0 = arg0;
		argCREATE_LEAGUE_CONFIRM1 = arg1;
		CancelLastOp(FrameInfoList.GUILD_LEAGUE_CREATE_CONFIRM);
		g_FrameInfo = FrameInfoList.GUILD_LEAGUE_CREATE_CONFIRM
		MessageBox_Self_Text:SetText( "#{TM_20080331_09}#{_EXCHG1000000}#{TM_20080331_02}" );
		local strText
		if IsInTServer() == 1 then
			MessageBox_Self_Text:SetText("#{TWTM_210506_42}")
		end
		
		MessageBox_Self_UpdateRect();
		this:Show();


	-- 服务器断了
	elseif ( event == "NET_CLOSE" ) then
		argNET_CLOSE0 = arg0
		CancelLastOp(FrameInfoList.NET_CLOSE_MESSAGE);
		g_FrameInfo = FrameInfoList.NET_CLOSE_MESSAGE;
		g_LastEvent = event
		this:Show();

	elseif ( event == "PET_FREE_CONFIRM") then
		Pet_Number = tonumber(arg0);
		CancelLastOp(FrameInfoList.PET_FREE_CONFIRM);
		g_FrameInfo = FrameInfoList.PET_FREE_CONFIRM;
		this:Show();

	elseif ( event == "OPEN_PS_MESSAGE_FRAME" )  then





		if( arg0 == "name" )    then
			g_szData = arg1;
			g_nData = tonumber(arg2);
			CancelLastOp(FrameInfoList.PS_RENAME_MESSAGE);
			g_FrameInfo = FrameInfoList.PS_RENAME_MESSAGE;

		elseif( arg0 == "ad" )  then
			g_szData = arg1;
			g_nData = tonumber(arg2);
			CancelLastOp(FrameInfoList.PS_READ_MESSAGE);
			g_FrameInfo = FrameInfoList.PS_READ_MESSAGE;

		elseif( arg0 == "immitbase" )		then -- 本金
			g_szData = arg1;
			g_nData  = tonumber(arg2);
			g_nData1 = tonumber(arg3);
			CancelLastOp(FrameInfoList.PS_ADD_BASE_MONEY);
			g_FrameInfo = FrameInfoList.PS_ADD_BASE_MONEY;

		elseif( arg0 == "immit" )				then -- 盈利金存入
			g_szData = arg1;
			g_nData  = tonumber(arg2);
			g_nData1 = tonumber(arg3);
			CancelLastOp(FrameInfoList.PS_ADD_GAIN_MONEY);
			g_FrameInfo = FrameInfoList.PS_ADD_GAIN_MONEY;

		elseif( arg0 == "draw" )				then -- 盈利金取出
			g_szData = arg1;
			g_nData  = tonumber(arg2);
			g_nData1 = tonumber(arg3);
			CancelLastOp(FrameInfoList.PS_DEC_GAIN_MONEY);
			g_FrameInfo = FrameInfoList.PS_DEC_GAIN_MONEY;

		elseif( arg0 == "add_stall" )		then --
			g_szData = arg1;
			g_nData  = tonumber(arg2);
			CancelLastOp(FrameInfoList.PS_ADD_STALL);
			g_FrameInfo = FrameInfoList.PS_ADD_STALL;


		elseif( arg0 == "del_stall" )		then --
			g_szData = arg1;
			g_nData  = tonumber(arg2);
			CancelLastOp(FrameInfoList.PS_DEL_STALL);
			g_FrameInfo = FrameInfoList.PS_DEL_STALL;


		elseif( arg0 == "sale" )     	then 	-- 盘出
			g_szData = tonumber(arg2);
			g_nData  = tonumber(arg3);
			CancelLastOp(FrameInfoList.PS_INFO_PANCHU);
			g_FrameInfo = FrameInfoList.PS_INFO_PANCHU;

		elseif( arg0 == "saleYB" )     	then 	-- 元宝盘出
			g_szData = tonumber(arg2);
			g_nData  = tonumber(arg3);
			CancelLastOp(FrameInfoList.PS_INFO_PANCHU_YB);
			g_FrameInfo = FrameInfoList.PS_INFO_PANCHU_YB;

		elseif( arg0 == "back" )     	then	-- 取消盘出
			g_szData = tonumber(arg2);
			g_nData  = tonumber(arg3);
			CancelLastOp(FrameInfoList.PS_INFO_PANRU);
			g_FrameInfo = FrameInfoList.PS_INFO_PANRU;

		elseif( arg0 == "ps_type" )		then	-- 更改玩家商店的子类提示信息
			g_szData = tonumber(arg2);
			g_nData  = tonumber(arg3);
			CancelLastOp(FrameInfoList.PS_INFO_MODIFY_TYPE);
			g_FrameInfo = FrameInfoList.PS_INFO_MODIFY_TYPE;
		elseif (arg0 == "ps_buy") then
			g_FrameInfo = FrameInfoList.BUY_PLAYERSHOP_SECOND_CONFIRM	
			local bSaleType = tonumber(arg1)
			local nSaleOutMoney = tonumber(arg2)
			local szName = tostring(arg3)
			local shopIndex = tonumber(arg4)
			local str1 = ""
			if bSaleType == 0 then --金币
				local gold = math.floor(nSaleOutMoney / 10000)
				local copper = math.mod(nSaleOutMoney, 100)
				local silver = math.mod(math.floor(nSaleOutMoney/100), 100)
				str1 = ScriptGlobal_Format("#{RCYH_180606_120}", gold, silver, copper, szName, shopIndex)
			elseif bSaleType == 1 then --元宝
				str1 = ScriptGlobal_Format("#{RCYH_180606_119}",nSaleOutMoney, szName, shopIndex)
			end
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText(str1)
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
		elseif (arg0 == "rest_stealSkill") then
			MessageBox_Self_Rest_StealSkill_Confirm()	
		elseif (arg0 == "stealSkill") then	
			MessageBox_Self_StealSkill_Confirm(tonumber(arg1),tonumber(arg2),tonumber(arg3),tonumber(arg4))
		end
			
	elseif ( event == "UI_COMMAND" ) then

		if tonumber(arg0) == FrameInfoList.SERVER_CONTROL then
				CancelLastOp(FrameInfoList.SERVER_CONTROL);
				g_FrameInfo = FrameInfoList.SERVER_CONTROL;
				if ( Get_XParam_INT_Count() > 1 ) then  --TT65894
					-- zchw fix Transfer bug
					local xx = Get_XParam_INT(1);
					ObjCaredID = DataPool : GetNPCIDByServerID(xx);
					if ObjCaredID ~= -1 then
						--开始关心NPC
						this:CareObject(ObjCaredID, 1, "MsgBox");
					end
				end
				--跨场景寻路已经处理过弹窗了
				for i=1, table.getn(g_TransScript) do
					if( Get_XParam_INT(0) == g_TransScript[i] and IsAcrossSceneMoveto() == 1) then
						Clear_XSCRIPT();
							Set_XSCRIPT_ScriptID(Get_XParam_INT(0));
							Set_XSCRIPT_Function_Name(Get_XParam_STR(0));
							Set_XSCRIPT_Parameter(0,Get_XParam_INT(1));
							Set_XSCRIPT_Parameter(1,Get_XParam_INT(2));
							Set_XSCRIPT_ParamCount(2);
						Send_XSCRIPT();
						return
					end
				end
				--小于20级，非镜湖和秦皇地宫4层不给于pk加杀气不加杀气的提示
				if MessageBox_Self_IsWillToTip() == 1 then
					return
				end
		elseif (tonumber(arg0) == 300039 ) then   --物品UI_COMMAND
			CancelLastOp(FrameInfoList.SERVER_CONTROL);
			g_FrameInfo = FrameInfoList.SERVER_CONTROL;
		elseif (tonumber(arg0) == 888447) then


			local str = Get_XParam_STR(0)
			Dart_Data[1] = Get_XParam_INT(0)
			Dart_Data[2] = Get_XParam_INT(1)
		 
			MessageBox_Self_Text:SetText(str)
			MessageBox_Self_DragTitle:SetText("");

			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.MAOHUABI_BUY_CONFIRMS

			local cardiID = DataPool:GetNPCIDByServerID(Dart_Data[2])
			this:CareObject(cardiID, 1, "MsgBox")

		elseif tonumber(arg0) == 332207 then
			g_FrameInfo = FrameInfoList.DART_ADJUST
			Dart_Data = {}
			Dart_Data[1] = Get_XParam_INT(0)
			Dart_Data[2] = Get_XParam_INT(1)
			Dart_Data[3] = 1
			MessageBox_Self_ShowDart()
			return
		elseif (tonumber(arg0) == 33110666 ) then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()		
			MessageBox_Self_Text:SetText("#{RGPT_240703_59}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_WEEKPVEAWARD
			this:Show();
			return;
		elseif (tonumber(arg0) == 89347110 ) then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			local ObjCaredID = DataPool : GetNPCIDByServerID(g_msgFrameVar[1]);
			
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end	
			
			g_msgFrameVar[2] = Get_XParam_INT(1)
			g_msgFrameVar[3] = Get_XParam_INT(2)
			g_msgFrameVar[4] = Get_XParam_INT(3)
			g_msgFrameVar[5] = Get_XParam_INT(4)
			g_msgFrameVar[6] = Get_XParam_INT(5)
			g_msgFrameVar[7] = Get_XParam_INT(6)
			MessageBox_Self_DragTitle:SetText("");
			local strText = ScriptGlobal_Format( "#{XSX_240326_137}", g_msgFrameVar[2], g_msgFrameVar[3],g_msgFrameVar[4],g_msgFrameVar[5] );
			-- if g_msgFrameVar[6] == 1 then
				-- --pvp低级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_130}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_129}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_128}"
				-- end
			-- elseif g_msgFrameVar[6] == 2 then
				-- --pvp高级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_136}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_135}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_134}"
				-- end
			-- elseif g_msgFrameVar[6] == 3 then
				-- --pve低级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_127}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_126}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_125}"
				-- end
			-- elseif g_msgFrameVar[6] == 4 then
				-- --pve高级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_133}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_132}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_131}"
				-- end
			-- end
			MessageBox_Self_Text:SetText(strText)
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_SHAXINGCHANGE
			this:Show();
			return;
		elseif (tonumber(arg0) == 99894720 ) then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			local ObjCaredID = DataPool : GetNPCIDByServerID(g_msgFrameVar[1]);
			
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end	
			
			g_msgFrameVar[2] = Get_XParam_INT(1)
			g_msgFrameVar[3] = Get_XParam_INT(2)
			g_msgFrameVar[4] = Get_XParam_INT(3)
			g_msgFrameVar[5] = Get_XParam_INT(4)
			g_msgFrameVar[6] = Get_XParam_INT(5)
			g_msgFrameVar[7] = Get_XParam_INT(6)
			MessageBox_Self_DragTitle:SetText("");
			local strText = ScriptGlobal_Format( "#{RGPT_240703_59}", g_msgFrameVar[2], g_msgFrameVar[3],g_msgFrameVar[4],g_msgFrameVar[5] );
			-- if g_msgFrameVar[6] == 1 then
				-- --pvp低级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_130}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_129}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_128}"
				-- end
			-- elseif g_msgFrameVar[6] == 2 then
				-- --pvp高级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_136}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_135}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_134}"
				-- end
			-- elseif g_msgFrameVar[6] == 3 then
				-- --pve低级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_127}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_126}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_125}"
				-- end
			-- elseif g_msgFrameVar[6] == 4 then
				-- --pve高级
				-- if g_msgFrameVar[7] == 1 then
					-- --日上限
					-- strText = strText.."#{XSX_240326_133}"
				-- elseif g_msgFrameVar[7] == 2 then
					-- --周上限
					-- strText = strText.."#{XSX_240326_132}"
				-- elseif g_msgFrameVar[7] == 3 then
					-- --总上限
					-- strText = strText.."#{XSX_240326_131}"
				-- end
			-- end
			MessageBox_Self_Text:SetText(strText)
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_ROUGEPATACHANGE
			this:Show();
			return;
		elseif (tonumber(arg0) == 805047 ) then
			Guild:AskGuildFirstManName();
			this:Hide();
			return;
		elseif (tonumber(arg0) == 805048 ) then
			local myPos = Guild:GetMyPosition();
			if POS_GUILD_CHIEF ~= myPos	then
				PushDebugMessage("#{BHCR_090713_06}") --非帮主不能撤销第一继承人
				this:Hide();
				return
			else
				argGUILD_DIS_FIRSTMAN0 = arg0
				CancelLastOp(FrameInfoList.GUILD_DIS_FIRSTMAN);
				g_FrameInfo = FrameInfoList.GUILD_DIS_FIRSTMAN;
				MessageBox_Self_Text:SetText("你确定要撤销第一继承人吗?");
				MessageBox_Self_UpdateRect();
				this:Show()
			end
		elseif (tonumber(arg0) == 335815 ) then
			CancelLastOp(FrameInfoList.GONGLIDAN_USE_CONFIRM);
			g_FrameInfo = FrameInfoList.GONGLIDAN_USE_CONFIRM;
			local szText = Get_XParam_STR(0)
			MessageBox_Self_Text:SetText(szText);
			MessageBox_Self_DragTitle:SetText("#{QNG_XML_10}");
			MessageBox_Self_UpdateRect();
			this:Show();
			return;
		--elseif (tonumber(arg0) == 891050 ) then--2015情人节排行榜礼盒使用二次确认
			--CancelLastOp(FrameInfoList.ROSEGIFTBOX_USE_CONFIRM);
			--g_FrameInfo = FrameInfoList.ROSEGIFTBOX_USE_CONFIRM;
			--local targetName = Get_XParam_STR(0)
			--local itemName = Get_XParam_STR(1)
			--local msg = ScriptGlobal_Format( "#{QRPHB_150113_177}", targetName, itemName )
			--MessageBox_Self_Text:SetText(msg);
			--MessageBox_Self_DragTitle:SetText("");
			--MessageBox_Self_UpdateRect();
			--this:Show();
			--return
		elseif (tonumber(arg0) == 892421 ) then
			CancelLastOp(FrameInfoList.CONFIRM_GAOBAILIHE);
			g_FrameInfo = FrameInfoList.CONFIRM_GAOBAILIHE;
			local targetName = Get_XParam_STR(0)
			local index = Get_XParam_INT(0)
			local msg = ""
			if index == 1 then
				msg =ScriptGlobal_Format( "#{GBLB_170113_09}", targetName)
			else
				msg =ScriptGlobal_Format( "#{GBLB_170113_14}", targetName)
			end
			MessageBox_Self_Text:SetText(msg);
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_UpdateRect();
			this:Show();
			return;
		elseif (tonumber(arg0) == 891720 ) then--2015圣诞尊享礼盒礼盒使用二次确认
			CancelLastOp(FrameInfoList.CHRISTMAS_ZUNXIANG_USE_CONFIRM);
			g_FrameInfo = FrameInfoList.CHRISTMAS_ZUNXIANG_USE_CONFIRM;
			local targetName = Get_XParam_STR(0)
			local msg =ScriptGlobal_Format( "#{SDLH_151123_22}", targetName)
			MessageBox_Self_Text:SetText(msg);
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_UpdateRect();
			this:Show();
			return
		elseif (tonumber(arg0) == 809270 ) then--武魂洗成长率
			g_FrameInfo = FrameInfoList.KFS_RESET_GROWRATE
			KFS_Data = {}
			KFS_Data[1] = Get_XParam_INT(0)
			KFS_Data[2] = Get_XParam_INT(1)
			if KFS_Data[1] == 1 then
				MessageBox_Self_Text:SetText( "#{WHXCZL_091026_09}" );--回天精石
			elseif KFS_Data[1] == 2 then
				MessageBox_Self_Text:SetText( "#{WHXCZL_091026_10}" );--回天神石
			end
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_UpdateRect();

			this:Show();
			MessageBox_Self_OK_Button:Show();
			MessageBox_Self_Cancel_Button:Show();
			return
		elseif tonumber(arg0) == FrameInfoList.SERVER_CONTROL_EXT then
			CancelLastOp(FrameInfoList.SERVER_CONTROL_EXT);
			g_FrameInfo = FrameInfoList.SERVER_CONTROL_EXT;
			--如果有第二个整形参数，表明有需要关心的NPC
			if  Get_XParam_INT_Count() > 1  then
				local npcId = Get_XParam_INT(1);
				local ObjCaredID = DataPool : GetNPCIDByServerID(npcId);
				if ObjCaredID ~= -1 then
					this:CareObject(ObjCaredID, 1, "MsgBox");
				end
			end
		elseif tonumber(arg0) == 502017 then
			g_qiziParam[1] = Get_XParam_INT(0)
			g_qiziParam[2] = Get_XParam_INT(1)
			g_qiziParam[3] = Get_XParam_INT(2)
			g_FrameInfo = FrameInfoList.CONFIRM_USE_CHESS
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("该棋子将会被放入棋盒，确认放入吗？")
			MessageBox_Self_UpdateRect()
			this:Show()
			return
		elseif tonumber(arg0) == 5426 then
			g_FrameInfo = FrameInfoList.CHANGE_NAME_RETOK;
			g_newName = Get_XParam_STR(0)
			MessageBox_Self_UpdateFrame()
			return
		elseif tonumber(arg0) == 502019 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("#{SLDZ_100805_79}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:SetText("#{IMXZ_20100813_04}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{IMXZ_20100813_05}")
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.SONGLIAOWAR_XXS_CANCELBUF_CONFIRM
		elseif tonumber(arg0) == 99802201 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{ETDDS_220406_60}")
			MessageBox_Self_UpdateRect()

			MessageBox_Self_OK_Button:SetText("#{ETDDS_220406_15}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{ETDDS_220406_16}")
			MessageBox_Self_Cancel_Button:Show()

			g_FrameInfo = FrameInfoList.LUHEXIEXIANG_CONFIRM
		elseif tonumber(arg0) == 99802202 then
			Server_Script_Function_Set={}
			Server_Script_Function_Set[1] = Get_XParam_INT(0);

			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{ETDDS_220406_14}")
			MessageBox_Self_UpdateRect()

			MessageBox_Self_OK_Button:SetText("#{ETDDS_220406_15}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{ETDDS_220406_16}")
			MessageBox_Self_Cancel_Button:Show()

			g_FrameInfo = FrameInfoList.LUHEXIEXIANG_SINGLEENTERCONFIRM
		elseif tonumber(arg0) == 99811204 then

			g_xinshouzhanling_addlevel = Get_XParam_INT(1)

			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format( "#{XSZL_220511_26}", Get_XParam_INT(0),Get_XParam_INT(1)))
			MessageBox_Self_UpdateRect()

			MessageBox_Self_OK_Button:SetText("#{ETDDS_220406_131}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{ETDDS_220406_132}")
			MessageBox_Self_Cancel_Button:Show()

			g_FrameInfo = FrameInfoList.XINSHOUZHANLING_BUYLEVEL
		elseif tonumber(arg0) == 99811205 then

			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format( "#{XSZL_220511_39}", Get_XParam_INT(0)))
			MessageBox_Self_UpdateRect()

			MessageBox_Self_OK_Button:SetText("#{ETDDS_220406_15}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{ETDDS_220406_16}")
			MessageBox_Self_Cancel_Button:Show()

			g_FrameInfo = FrameInfoList.XINSHOUZHANLING_JINGYING
		
		--2022Q3新天外预热活动-ypl to洛阳
		elseif tonumber(arg0) == 99819701 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{XTWYR_220729_265}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:SetText("#{XTWYR_220729_263}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{XTWYR_220729_264}")
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.XINTIANWAI_YURE_2022_1
				
		--2022Q3新天外预热活动-ypl to四城
		elseif tonumber(arg0) == 99819704 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			local g_xintianwai_yure_2022_Str = Get_XParam_STR(0)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{XTWYR_220729_262}", g_xintianwai_yure_2022_Str))
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:SetText("#{XTWYR_220729_263}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{XTWYR_220729_264}")
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.XINTIANWAI_YURE_2022_2

		--2022Q3新天外预热活动-ypl 批量购买
		elseif tonumber(arg0) == 99819707 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{XTWYR_220729_302}", g_msgFrameVar[1], g_msgFrameVar[2]))
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:SetText("#{XTWYR_220729_263}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{XTWYR_220729_264}")
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.XINTIANWAI_YURE_2022_3

		--2022Q4杯酒尽江湖-ypl 福缘刷新
		elseif tonumber(arg0) == 99832501 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{BJJH_221024_48}", g_msgFrameVar[2]))
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.BEIJIUJINJIANGHU_2022_1
		
		--2022Q4杯酒尽江湖-ypl 福缘领奖
		elseif tonumber(arg0) == 99832502 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{BJJH_221024_51}", g_msgFrameVar[1]))
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.BEIJIUJINJIANGHU_2022_2			
		--卯兔闹春二次确认
		elseif tonumber(arg0) == 99837501 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_STR(0)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{MTNC_221101_95}", g_msgFrameVar[1])) 
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_MAOTUNAOCHUN_REDPACKET			
		elseif tonumber(arg0) == 99851201 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_FrameInfo = FrameInfoList.CONFIRM_BAIYINMAAN
			g_msgFrameVar[1] = Get_XParam_INT(0)
			local ObjCaredID = DataPool : GetNPCIDByServerID(g_msgFrameVar[1]);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end	
			MessageBox_Self_Text:SetText("#{HJMAYH_230228_9}")		
			--MessageBox_Self_DragTitle:SetText("#{HJMAYH_230228_8}")			
			MessageBox_Self_OK_Button:Show();
			MessageBox_Self_Cancel_Button:Show()
			MessageBox_Self_UpdateRect()
			this:Show()
		elseif tonumber(arg0) == 99851202 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_FrameInfo = FrameInfoList.CONFIRM_QINGTONGMAAN
			g_msgFrameVar[1] = Get_XParam_INT(0)
			local ObjCaredID = DataPool : GetNPCIDByServerID(g_msgFrameVar[1]);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end	
			MessageBox_Self_Text:SetText("#{HJMAYH_230505_8}")		
			--MessageBox_Self_DragTitle:SetText("#{HJMAYH_230228_8}")			
			MessageBox_Self_OK_Button:Show();
			MessageBox_Self_Cancel_Button:Show()
			MessageBox_Self_UpdateRect()
			this:Show()
		elseif tonumber(arg0) == 99816366 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(Get_XParam_STR(0))
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:SetText("#{BZTX_220705_309}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{BZTX_220705_310}")
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CITYWAR_CHANGE_PK_MODE
		elseif tonumber(arg0) == 88998201 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("#{HDYD_120822_182}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.SEND_SHUIYUEDONGTIAN
		elseif tonumber(arg0) == 502010 then
			this:Hide()
			return
		elseif tonumber(arg0) == 5020192 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("#{SLDZ_100805_35}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.SONGLIAOWAR_REST_EXIT_CONFIRM
		--xjc
		elseif tonumber(arg0) == 70250201 then
			Server_Script_Function_Set={}
			Server_Script_Function_Set[1] = Get_XParam_INT(0);
			ObjCaredID = DataPool : GetNPCIDByServerID(Server_Script_Function_Set[1]);
			--PushDebugMessage(ObjCaredID)
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end

			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("#{TWWJ_201104_05}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.BianJin_WeiBingJia_CONFIRM
		--xjc
		--xjc
		elseif tonumber(arg0) == 70250301 then
				Server_Script_Function_Set={}
				Server_Script_Function_Set[1] = Get_XParam_INT(0);
				ObjCaredID = DataPool : GetNPCIDByServerID(Server_Script_Function_Set[1]);
				--PushDebugMessage(ObjCaredID)
				if ObjCaredID ~= -1 then
					--开始关心NPC
					this:CareObject(ObjCaredID, 1, "MsgBox");
				end
	
				CancelLastOp(-1)
				MessageBox_Self_DragTitle:SetText("");
				MessageBox_Self_Text:SetText("#{TWWJ_201104_27}")
				MessageBox_Self_UpdateRect()
				MessageBox_Self_OK_Button:Show()
				MessageBox_Self_Cancel_Button:Show()
				g_FrameInfo = FrameInfoList.BianJin_WeiBingYi_CONFIRM
		--xjc
		--chongloushop
		elseif tonumber(arg0) == 88843102 then
			Server_Script_Function_Set={}
			Server_Script_Function_Set[1] = Get_XParam_INT(0);--targetId
			Server_Script_Function_Set[2] = Get_XParam_INT(1);--货币类型
			Server_Script_Function_Set[3] = Get_XParam_INT(2);--价格
			Server_Script_Function_Set[4] = Get_XParam_INT(3);--itemIndex
			Server_Script_Function_Set[5] = Get_XParam_INT(4);--itemID
			Server_Script_Function_Set[6] = Get_XParam_INT(5);--level
			Server_Script_Function_Set[7] = Get_XParam_INT(6);--group_count
			Server_Script_Function_Set[8] = Get_XParam_STR(0);--GetItemName
			ObjCaredID = DataPool : GetNPCIDByServerID(Server_Script_Function_Set[1]);
			--PushDebugMessage(ObjCaredID)
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end

			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("#{CLDHDB_210510_59}"); --CLDHDB_210510_59

			local strPrice = ""
			if Server_Script_Function_Set[2] == 1 then
				strPrice = ScriptGlobal_Format("#{CLDHDB_210510_36}", tostring(Server_Script_Function_Set[3]))
			else
				strPrice = ScriptGlobal_Format("#{CLDHDB_210510_37}", tostring(Server_Script_Function_Set[3]))
			end

			local strName = ScriptGlobal_Format("#{CLDHDB_210510_38}", tostring(Server_Script_Function_Set[7]), Server_Script_Function_Set[8])	

			MessageBox_Self_Text:SetText(strPrice..strName)
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CHONGLOU_SHOP_CONFIRM
		--chongloushop
		--彩色地鼠
		elseif tonumber(arg0) == 99844801 then
			Server_Script_Function_Set={}
			Server_Script_Function_Set[1] = Get_XParam_INT(0);--targetId

			ObjCaredID = DataPool : GetNPCIDByServerID(Server_Script_Function_Set[1]);
			--PushDebugMessage(ObjCaredID)
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end

			CancelLastOp(-1)

			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("#{CSDS_230216_71}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CAISEDISHU_SINGLE_CONFIRM
		-- VIP幻玉
		elseif tonumber(arg0) == 88885402 then
			Server_Script_Function_Set={}
			Server_Script_Function_Set[1] = Get_XParam_INT(0);--bagIndex
			Server_Script_Function_Set[2] = Get_XParam_INT(1);--nIndex
			Server_Script_Function_Set[3] = Get_XParam_STR(0);--itemName

			CancelLastOp(-1)
			--MessageBox_Self_DragTitle:SetText("#{CLDHDB_210510_59}"); --CLDHDB_210510_59

			local strName = ScriptGlobal_Format("#{VIPBS_211130_8}", Server_Script_Function_Set[3])	

			MessageBox_Self_Text:SetText(strName)
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.VIPNIANDI_CONFIRM
		-- VIP幻玉
		elseif tonumber(arg0) == 20110815 then
			CancelLastOp(-1)
			g_ZBS_CurRnd = Get_XParam_INT(0)
			g_ZBS_NPCID = Get_XParam_INT(1)

			if g_ZBS_CurRnd == nil or g_ZBS_CurRnd <0 or g_ZBS_CurRnd > 6 then
				return
			end
			if g_ZBS_NPCID == nil or g_ZBS_NPCID < 0 then
				return
			end
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("#{KFZB_110628_252}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.ZBS_ETNER_CONFIRM
		elseif	tonumber(arg0) == 20120317 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("比赛尚未结束，您确定要离开么？")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_LEAVE_CORPS_COPYSCENE
		elseif	tonumber(arg0) == 20120731 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("比赛尚未结束，您确定要离开么？")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_LEAVE_CORPS_FINAL_SCENE
		elseif tonumber(arg0) == 89105702 then
			this:Hide();
			return;
		elseif (tonumber(arg0) == 891092 ) then
			CancelLastOp(FrameInfoList.HUITIANDAN_USE_CONFIRM);
			g_FrameInfo = FrameInfoList.HUITIANDAN_USE_CONFIRM;
			local szText = Get_XParam_STR(0)
			MessageBox_Self_Text:SetText(szText);
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			this:Show();
			return;
		elseif	tonumber(arg0) == 89144801 then
			CancelLastOp(-1)
			g_FrameInfo = FrameInfoList.SANSHEN_FUBEN_CONFIRM
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{MZFB_150810_50}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
		
		elseif	tonumber(arg0) == 20150803 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("比赛尚未结束，您确定要离开么？")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_LEAVE_KM_SCENE
		elseif (tonumber(arg0) == 807012 ) then--移民
			g_FrameInfo = FrameInfoList.CONFIRM_IMMIGRATION;
			ImmigArg0 = Get_XParam_INT(0)
			ImmigArg1 = Get_XParam_INT(1)
			ImmigArg2 = Get_XParam_INT(2)
			local targetName = Get_XParam_STR(0);
			local targetServerName = Get_XParam_STR(1)	;
			local msg =ScriptGlobal_Format( "#{FWQYM_160531_240}", targetName,targetServerName)
			MessageBox_Self_Text:SetText(msg);
			MessageBox_Self_DragTitle:SetText("夫妻移民");
			MessageBox_Self_UpdateRect();
		elseif (tonumber(arg0) == 20160601 ) then--取消移民

			g_FrameInfo = FrameInfoList.CONFIRM_CANCEL_IMMIGRATION;
			ImmigArg0  = Get_XParam_INT(0)
			ImmigArg1  = Get_XParam_INT(1)
			ImmigArg2  = Get_XParam_INT(2)
			local targetName = Get_XParam_STR(0)
			local targetServerName = Get_XParam_STR(1)
			local msg =ScriptGlobal_Format( "#{FWQYM_160601_252}", targetName,targetServerName)
			MessageBox_Self_Text:SetText(msg);
			MessageBox_Self_DragTitle:SetText("夫妻移民");
			MessageBox_Self_UpdateRect();
		elseif (tonumber(arg0) == 20170818 ) then   --九层妖塔
			local nStr=
			{
				[1] = "#{JXPVP_170814_134}",
				[2] = "#{JXPVP_170814_135}",
				[3] = "#{JXPVP_170814_136}",
				[4] = "#{JXPVP_170814_137}",
				[5] = "#{JXPVP_170814_138}",
			}
			CancelLastOp(-1)
			g_FrameInfo = FrameInfoList.CONFIRM_JIUCENGYAOTA
			g_nData  = Get_XParam_INT(0)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format( "#{JXPVP_170814_40}",nStr[g_nData]))
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
		elseif (tonumber(arg0) == 20171009 ) then   --九层妖塔
			CancelLastOp(-1)
			g_FrameInfo = FrameInfoList.CONFIRM_JIUCENGYAOTA_RELIVE
			g_nData  = Get_XParam_INT(0)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{JXPVP_170814_124}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
		elseif (tonumber(arg0) == 8925210 ) then   --三身伽蓝 副本离开
			CancelLastOp(-1)
			g_FrameInfo = FrameInfoList.CONFIRM_LEAVE_SANSHENJIALAN
			g_nData  = Get_XParam_INT(0)
			MessageBox_Self_DragTitle:SetText("")
			if g_nData == 1 then
				MessageBox_Self_Text:SetText( "#{JXRW_170905_82}" )
			elseif g_nData == 2 then
				MessageBox_Self_Text:SetText( "#{JXRW_170905_85}" )
			elseif g_nData == 3 then
				MessageBox_Self_Text:SetText( "#{JXRW_170905_86}" )
			end
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
		elseif (tonumber(arg0) == 8925201 ) then   --九星副本进入
			CancelLastOp(-1)
			g_FrameInfo = FrameInfoList.CONFIRM_JIUXING_FUBEN
			g_nData  = Get_XParam_INT(0)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{JXRW_170905_160}")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
		elseif	tonumber(arg0) == 89269501 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("比赛尚未结束，您确定要离开么？")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_LEAVE_CORPS_COPYSCENE_2018
		elseif	tonumber(arg0) == 89269801 then
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_Text:SetText("比赛尚未结束，您确定要离开么？")
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_LEAVE_CORPS_FINALSCENE_2018
		elseif	tonumber(arg0) == 20180705 then
			CancelLastOp(-1)
			g_FrameInfo = FrameInfoList.CONFIRM_YUSUI_CONFIRM					
			g_CityData[1] = Get_XParam_INT(0)
			g_CityData[2] = Get_XParam_INT(1)
			MessageBox_Self_DragTitle:SetText("");
			if g_CityData[1] == 0 then --先扣绑定的
				MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{JXSQ_170829_295}",g_CityData[2],10-g_CityData[2]))
			elseif g_CityData[1] == 1 then --先扣非绑定的
				MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{JXSQ_170829_296}",g_CityData[2],10-g_CityData[2]))
			end
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()				
		elseif	tonumber(arg0) == 20180829 then
			CancelLastOp(-1)
			g_FrameInfo = FrameInfoList.CONFIRM_BWDB_CONFIRM					
			g_CityData[1] = Get_XParam_INT(0)
			g_CityData[2] = Get_XParam_INT(1)
			g_CityData[3] = Get_XParam_INT(2)			
			g_CityData[4] = Get_XParam_INT(3)			
			local szItemName = DataPool:Lua_GetItemNameByIndex(g_CityData[2])
			MessageBox_Self_DragTitle:SetText("");
			if g_CityData[4] <= 0 then --没有元宝，纯代币
				MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{DWSD_180817_34}",szItemName,g_CityData[3],g_CityData[4]))
			else  --元宝+代币
				MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{DWSD_180817_37}",szItemName,g_CityData[3],g_CityData[4]))
			end
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()	
			
		elseif	tonumber(arg0) == 50508803 then
			local bKaJi = Get_XParam_INT(0);
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("");
			if bKaJi == 1 then
				MessageBox_Self_Text:SetText("#{DWPF_220420_20}")
			elseif 1 == Player:GetData("IsOriginalJD") then
				MessageBox_Self_Text:SetText("#{DWPF_260429_04}")
			else
				MessageBox_Self_Text:SetText("#{DWPF_190428_36}")
			end
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_DUANWU_ZONGZI_CONFIRM	
		elseif tonumber(arg0) == 20200628 then 
			g_FrameInfo = FrameInfoList.CONFIRM_BASE_SHANHAIBI_CONFIRM;
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			MessageBox_Self_Text:SetText("#{LLCB_200628_13}");
			--MessageBox_Self_DragTitle:SetText("");
			MessageBox_Self_UpdateRect();
		elseif	tonumber(arg0) == 91020902 then
			MessageBox_Self_ClearVar();
			MessageBox_Self_Text:SetText( "#{FJTL_140305_25}" );
			MessageBox_Self_DragTitle:SetText( "" );
			MessageBox_Self_UpdateRect();
			g_FrameInfo = FrameInfoList.TIANJIANGQIFU_CONFIRM;
			FuJiangTLUIType = 100
			this:Show();	
		elseif	tonumber(arg0) == 88820903 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar();
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			local str = ScriptGlobal_Format("#{ZYPX_200829_132}", g_msgFrameVar[1])
			MessageBox_Self_Text:SetText( str );
			MessageBox_Self_DragTitle:SetText( "#{ZYPX_200829_131}" );
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.ZYPX_BULING_ITEM_CONFIRM
		elseif 	tonumber(arg0) == 88825301 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar();
			g_msgFrameVar[1] = Get_XParam_INT(0) --key
			g_msgFrameVar[2] = Get_XParam_INT(1) --TargetID
			local str = "#{TWWJ_201104_37}"
			if g_msgFrameVar[1] == 2 then
				str = "#{TWWJ_201104_70}"
			end
			MessageBox_Self_Text:SetText( str )
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			--关心NPC
			local ObjCaredID = DataPool : GetNPCIDByServerID(g_msgFrameVar[2]);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end
			g_FrameInfo = FrameInfoList.BIANJING_HORSERENT
		elseif tonumber(arg0) == 99980101 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --itemid
			g_msgFrameVar[3] = Get_XParam_INT(2) --ExteriorID
			g_msgFrameVar[4] = Get_XParam_INT(3) --oriTime
			g_msgFrameVar[5] = Get_XParam_INT(4) --addTime 
			MessageBox_Self_ExteriorRide_Confirm(0)
		elseif tonumber(arg0) == 99990101 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --itemid
			g_msgFrameVar[3] = Get_XParam_INT(2) --ExteriorID
			g_msgFrameVar[4] = Get_XParam_INT(3) --oriTime
			g_msgFrameVar[5] = Get_XParam_INT(4) --addTime 
			MessageBox_Self_ExteriorRide_Confirm(1)
		elseif tonumber(arg0) == 99980201 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --itemid
			g_msgFrameVar[3] = Get_XParam_INT(2) --ExteriorID
			g_msgFrameVar[4] = Get_XParam_INT(3) --oriTime
			g_msgFrameVar[5] = Get_XParam_INT(4) --addTime 
			MessageBox_Self_ExteriorWeapon_Confirm(0)
		elseif tonumber(arg0) == 99990201 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --itemid
			g_msgFrameVar[3] = Get_XParam_INT(2) --ExteriorID
			g_msgFrameVar[4] = Get_XParam_INT(3) --oriTime
			g_msgFrameVar[5] = Get_XParam_INT(4) --addTime 
			MessageBox_Self_ExteriorWeapon_Confirm(1)
		elseif 	tonumber(arg0) == 5061002 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar();
			g_msgFrameVar[1] = Get_XParam_INT(0) --idx
			g_msgFrameVar[2] = Get_XParam_INT(1) --targetId
			local strRank = {"#{XFXS_201231_231}","#{XFXS_201231_232}","#{XFXS_201231_233}","#{XFXS_201231_234}"}
			local str = ScriptGlobal_Format("#{XFXS_201231_55}",strRank[g_msgFrameVar[1]])
			
			MessageBox_Self_Text:SetText( str )
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			--关心NPC
			local ObjCaredID = DataPool : GetNPCIDByServerID(g_msgFrameVar[2]);
			if ObjCaredID ~= -1 then
				this:CareObject(ObjCaredID, 1, "MsgBox");
			end
			g_FrameInfo = FrameInfoList.CONFIRM_RECV_BOUNTYMISSION
		elseif tonumber(arg0) == 99990501 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --itemid
			g_msgFrameVar[3] = Get_XParam_INT(2) --ExteriorID
			g_msgFrameVar[4] = Get_XParam_INT(3) --oriTime
			g_msgFrameVar[5] = Get_XParam_INT(4) --addTime 
			MessageBox_Self_ToyItem_Confirm()
		elseif tonumber(arg0) == 88886403 then
			MessageBox_Self_DiGongShop_Confirm()
		elseif tonumber(arg0) == 89122901 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			local strText = Get_XParam_STR(0);
			g_msgFrameVar[1] = Get_XParam_INT(0) --cItemPos
			g_msgFrameVar[2] = Get_XParam_INT(1) --nIndex
			MessageBox_Self_MingZhenTianXia_Confirm( strText )
			return
		elseif tonumber(arg0) == 89000601 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --itemid
			g_msgFrameVar[3] = Get_XParam_INT(2) --emoid
			g_msgFrameVar[4] = Get_XParam_INT(3) --isHave
			g_msgFrameVar[5] = Get_XParam_INT(4) --lefttime
			g_msgFrameVar[6] = Get_XParam_INT(5) --addHour
			
			MessageBox_Self_UseRmbEmo_Confirm()
			
			return
		elseif tonumber(arg0) == 89276401 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			MessageBox_Self_ZhongQingMeiGui_Confirm()
			return
		elseif tonumber(arg0) == 89276801 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --scriptId
			local szText = Get_XParam_STR(0)
			MessageBox_Self_ZhongQingMeiGuiNew_Confirm( szText )
			return
		elseif tonumber(arg0) == 34003401 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --Script
			MessageBox_Self_QiMiaoExp_Confirm()
			return
		elseif tonumber(arg0) == 99848701 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1]  = Get_XParam_INT(0)
			g_msgFrameVar[2]  = Get_XParam_INT(1)
			g_msgFrameVar[3]  = Get_XParam_INT(2)
			g_msgFrameVar[4]  = Get_XParam_INT(3)
			MessageBox_Self_DiGongEnter_Confirm()
			return
		elseif tonumber(arg0) == 99856901 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1]  = Get_XParam_INT(0)
			g_msgFrameVar[2]  = Get_XParam_INT(1)
			MessageBox_Self_TianJiChengEnter_Confirm()
			return
		elseif (tonumber(arg0) == 99802301) then
			Server_Script_Function_Set={}
			Server_Script_Function_Set[1] = Get_XParam_INT(0);

			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{ETDDS_220406_126}")
			MessageBox_Self_UpdateRect()

			MessageBox_Self_OK_Button:SetText("#{ETDDS_220406_131}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{ETDDS_220406_132}")
			MessageBox_Self_Cancel_Button:Show()

			g_FrameInfo = FrameInfoList.LUHEXIEXIANG_REWARDCONFIRM

		--帮会城市兑换战旗
		elseif tonumber(arg0) == 99856101 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			g_msgFrameVar[3] = Get_XParam_INT(2)
			g_msgFrameVar[4] = Get_XParam_INT(3)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{ZQYH_230523_15}", g_msgFrameVar[3], DataPool:Lua_GetItemNameByIndex(g_msgFrameVar[4])))
			MessageBox_Self_UpdateRect()
			MessageBox_Self_OK_Button:SetText("#{XTWYR_220729_263}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{XTWYR_220729_264}")
			MessageBox_Self_Cancel_Button:Show()
			g_FrameInfo = FrameInfoList.GUILDCITY_FLAG_EXCHANGE
		elseif tonumber(arg0) == 77788805 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			MessageBox_Self_BuyFashionCloth_Confirm()
		elseif tonumber(arg0) == 88110103 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			g_msgFrameVar[3] = Get_XParam_INT(2)
	
			MessageBox_Self_ChongLouEffectActive_Confirm()

		elseif tonumber(arg0) == 20260324 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			g_msgFrameVar[3] = Get_XParam_INT(2)

			MessageBox_Self_BuyNewbaotu_Confirm_free()		
		elseif tonumber(arg0) == 20260505 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			g_msgFrameVar[3] = Get_XParam_INT(2)

			MessageBox_Self_Oribaotu_Confirm_free()			
		elseif tonumber(arg0) == 79115003 then
			MessageBox_Self_DragTitle:SetText("")
			CancelLastOp(FrameInfoList.CONFIRM_SUMMER_ZHANLING_ACT)
			g_FrameInfo = FrameInfoList.CONFIRM_SUMMER_ZHANLING_ACT
			local strMsg = Get_XParam_STR(0)
			MessageBox_Self_Text:SetText(strMsg)
			MessageBox_Self_ClearVar()
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			MessageBox_Self_UpdateRect()
			this:Show()
		elseif tonumber(arg0) == 79115005 then
			MessageBox_Self_DragTitle:SetText("")
			CancelLastOp(FrameInfoList.CONFIRM_SUMMER_ZHANLING_BUY)
			g_FrameInfo = FrameInfoList.CONFIRM_SUMMER_ZHANLING_BUY
			local strMsg = Get_XParam_STR(0)
			MessageBox_Self_Text:SetText(strMsg)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:Show()
			MessageBox_Self_UpdateRect()
			this:Show()

		elseif tonumber(arg0) == 99909601 then
			g_msgFrameVar[1] = Get_XParam_INT(0)
			
			CancelLastOp(-1)
			MessageBox_Self_DragTitle:SetText("")
			MessageBox_Self_Text:SetText("#{FHYQ_240428_87}")
			MessageBox_Self_UpdateRect()		
			MessageBox_Self_OK_Button:SetText("#{XTWYR_220729_263}")
			MessageBox_Self_OK_Button:Show()
			MessageBox_Self_Cancel_Button:SetText("#{XTWYR_220729_264}")
			MessageBox_Self_Cancel_Button:Show()
			
			g_FrameInfo = FrameInfoList.FENGHUANG_INVITE_CONFIRM	
		elseif tonumber(arg0) == 20240826 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = arg1
			MessageBox_Self_TcityWar_GroupRaid_Confirm(g_msgFrameVar[1])
		elseif tonumber(arg0) == 99965100 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0)
			MessageBox_Self_Xiake_MonsterToken()
		elseif tonumber(arg0) == 88890901 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			g_msgFrameVar[2] = Get_XParam_INT(1) --Script
			local szItemName = Get_XParam_STR(0)
			local szText = Get_XParam_STR(1)
			MessageBox_Self_ExpBallUse_Confirm( szItemName, szText )
			return
		elseif tonumber(arg0) == 99825500 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = Get_XParam_INT(0) --BagIndex
			-- 背包格子蒙红锁定
			LifeAbility : Lock_Packet_Item( g_msgFrameVar[1], 1 )
			MessageBox_Self_CommonGift_Title_Confirm()
			return
		elseif tonumber(arg0) == 89347301 then-- 新杀星放弃二次确认
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1]  = Get_XParam_INT(0)
			g_FrameInfo = FrameInfoList.CONFIRM_SHAXINGGIVEUP 
			MessageBox_Self_Text:SetText("#{XSX_220705_109}");	-- 设置内容
			MessageBox_Self_DragTitle:SetText("")			
			MessageBox_Self_OK_Button:Show();
			MessageBox_Self_Cancel_Button:Show()
			MessageBox_Self_UpdateRect()
			this:Show()
		
		elseif tonumber(arg0) == 33592701 then-- 新杀星放弃二次确认
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_FrameInfo = FrameInfoList.CONFIR_FYPVE_BAG_CONFIRM
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			local strMsg = Get_XParam_STR(0)
			MessageBox_Self_Text:SetText(strMsg);	-- 设置内容
			MessageBox_Self_DragTitle:SetText("")			
			MessageBox_Self_OK_Button:Show();
			MessageBox_Self_Cancel_Button:Show()
			MessageBox_Self_UpdateRect()
			this:Show()
		elseif tonumber(arg0) == 900025002 then
			CancelLastOp(-1)
			MessageBox_Self_ClearVar()
			g_FrameInfo = FrameInfoList.CONFIR_QUNCHUANRUCHANGFU_CONFIRM
			g_msgFrameVar[1] = Get_XParam_INT(0)
			g_msgFrameVar[2] = Get_XParam_INT(1)
			local strMsg = Get_XParam_STR(0)
			MessageBox_Self_Text:SetText(strMsg);	-- 设置内容
			MessageBox_Self_DragTitle:SetText("#{ZTPVP_260515_117}")			
			MessageBox_Self_OK_Button:Show();
			MessageBox_Self_Cancel_Button:Show()
			MessageBox_Self_UpdateRect()
			this:Show()
		end
	elseif (event == "PACKAGE_ITEM_CHANGED") then
		if g_FrameInfo == FrameInfoList.DART_ADJUST then
			if not IsWindowShow("AnqiShuxing") or Dart_Data[3]==nil or Dart_Data[3]~=1 then
				Dart_Data = {}
				Dart_Data[3]=0
				this:Hide()
				return
			end
		elseif g_FrameInfo == FrameInfoList.KFS_RESET_GROWRATE then
			KFS_Data = {}
			this:Hide()
			return
		else
			return
		end
	-- zchw fix Transfer bug
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		-- PushDebugMessage("#OBJECT_CARED_EVENT#")
		
		if(tonumber(arg0) ~= ObjCaredID) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			if ObjCaredID ~= -1 then
				this:CareObject(ObjCaredID, 0, "MsgBox");
			end
			this:Hide();
		end
	elseif( event == "DELETE_FRIEND" ) then
		g_currentList = tonumber(arg0);
		g_currentIndex = tonumber(arg1);
		CancelLastOp(FrameInfoList.DELETE_FRIEND_MESSAGE);
		g_FrameInfo = FrameInfoList.DELETE_FRIEND_MESSAGE;
	elseif( event == "CITY_CONFIRM" ) then
		g_CityData[1] = tonumber(arg0);	-- 帮会城市操作类型
		g_CityData[2] = tonumber(arg1);	-- 帮会城市建筑物索引
		g_CityData[3] = arg2;
		g_CityData[4] = arg3;
		g_CityData[5] = arg4;
		g_CityData[6] = arg5;
		g_CityData[7] = arg6;
		g_CityData[8] = arg7;
		CancelLastOp(FrameInfoList.CITY_CONFIRM);
		g_FrameInfo = FrameInfoList.CITY_CONFIRM;
	elseif( event == "MESSAGE_BOX" ) then
		MeesageBox_Init();
		return;
	elseif( event == "CHANGEPROTECTTIME" ) then
		g_ChangeTiemArg0 = tonumber(arg0);
		g_ChangeTiemArg1 = tonumber(arg1);
		CancelLastOp(FrameInfoList.CHANGEPROTECTTIME);
		g_FrameInfo = FrameInfoList.CHANGEPROTECTTIME;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0安全时间");
		if(g_ChangeTiemArg0 == 0)then
			MessageBox_Self_Text:SetText("一旦设置安全时间，下次上线时在安全时间内无法进行很多操作，因此请您合理设置您的安全时间。确定要设置吗？");
		else
			MessageBox_Self_Text:SetText("增加安全时间能使您的账号更安全，但您下次上线时在安全时间内也无法进行很多操作，因此请您合理设置您的安全时间。您确认要继续增加安全时间吗？");
			--帐号  to  账号
		end
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	elseif( event == "ATHORSECFRAME" ) then
		if(tonumber(arg0) == 1) then--安全模式界面二次确认框
			CancelLastOp(FrameInfoList.ATHORSECFRAME);
			g_FrameInfo = FrameInfoList.ATHORSECFRAME;
			MessageBox_Self_DragTitle:SetText("#{AQZX_130812_145}");
			MessageBox_Self_Text:SetText("#{AQZX_130812_31}");
			MessageBox_Self_UpdateRect();
			this:Show();
		elseif(tonumber(arg0) == 0) then--安全评分_安全模式 二次确认框
			CancelLastOp(FrameInfoList.ATHORSECFRAME);
			g_FrameInfo = FrameInfoList.ATHORSECFRAME;
			MessageBox_Self_DragTitle:SetText("#gFF0FA0安全模式");
			MessageBox_Self_Text:SetText("#{AQZX_130812_09}");
			MessageBox_Self_UpdateRect();
			this:Show();
		end
		return
	elseif( event == "ONCE_ALL_LOCK" ) then


			CancelLastOp(FrameInfoList.ONCE_ALL_LOCK);
			g_FrameInfo = FrameInfoList.ONCE_ALL_LOCK;
			MessageBox_Self_DragTitle:SetText("#{AQZX_130812_180}");
			MessageBox_Self_Text:SetText("#{ZYXT_120528_114}");
			MessageBox_Self_UpdateRect();
			this:Show();
			return
	elseif(event == "PLAYER_GIVE_ROSE")then
                                        MessageBox_Self_DragTitle:SetText("");
		g_RoseArg0 = arg0;
		g_RoseArg1 = arg1;
		g_RoseArg2 = arg2;
		g_RoseArg3 = arg3;
		g_RoseArg4 = arg4;
		local g_RoseArg5 = tonumber(arg5);
		if(g_RoseArg0==nil or g_RoseArg1 == nil )then
			return;
		end
		CancelLastOp(FrameInfoList.Player_Give_Rose);
		g_FrameInfo = FrameInfoList.Player_Give_Rose;
		local itemname = PlayerPackage:GetItemName( g_RoseArg5 )
		local strTips = ScriptGlobal_Format("#{QRPHB_150113_198}", itemname, g_RoseArg0)
		MessageBox_Self_Text:SetText( strTips )

		MessageBox_Self_UpdateRect();
		this:Show();
		return;
 	elseif(event == "PLAYER_GIVE_BLUEROSE")then
        MessageBox_Self_DragTitle:SetText("");
		g_RoseArg0 = arg0;
		g_RoseArg1 = arg1;
		g_RoseArg2 = arg2;
		g_RoseArg3 = arg3;
		g_RoseArg4 = arg4;
		if(g_RoseArg0==nil or g_RoseArg1 == nil )then
			return;
		end
		CancelLastOp(FrameInfoList.PLAYER_GIVE_BLUEROSE);
		g_FrameInfo = FrameInfoList.PLAYER_GIVE_BLUEROSE;
		MessageBox_Self_Text:SetText("#cFFF263是否送#c00ff00999朵蓝色妖姬#cFFF263给#c00ff00"..g_RoseArg0.."#cFFF263?");
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	elseif( event == "NEED_USE_CONFIRM_ITEM" ) then
		NeedUseConfirmItemData[1] = arg0; --目标objID
		NeedUseConfirmItemData[2] = arg1; --目标x坐标
		NeedUseConfirmItemData[3] = arg2; --目标y坐标
		NeedUseConfirmItemData[4] = arg3; --物品包内索引
		NeedUseConfirmItemData[5] = arg4; --物品表内索引
		if(NeedUseConfirmItemData[1] == nil)then
			return;
		end

		local itemTableIdx = tonumber(NeedUseConfirmItemData[5]);
		--获取显示内容
		local txt = MessageBox_GetNeedUseConfirmItemShowTxt( itemTableIdx );
		if (txt == nil) then
			return;
		end
		CancelLastOp(FrameInfoList.NEED_USE_CONFIRM_ITEM);
		g_FrameInfo = FrameInfoList.NEED_USE_CONFIRM_ITEM;
		MessageBox_Self_Text:SetText(txt);
		MessageBox_Self_DragTitle:SetText("#{QNG_XML_10}");
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	end

	if(event == "CLOSE_PS_CHANGETYPE_MSG" ) then
		if(this:IsVisible() and g_FrameInfo == FrameInfoList.PS_INFO_MODIFY_TYPE)then
			this:Hide();
		end
		return;
	end
	if(event == "CLOSE_STRENGTH_MSGBOX" ) then
		if(this:IsVisible()) then
			if g_FrameInfo == FrameInfoList.CONFIRM_STENGTH  then
				this:Hide();
			elseif g_FrameInfo == FrameInfoList.SERVER_CONTROL or g_FrameInfo == FrameInfoList.SERVER_CONTROL_EXT then
				this:Hide();
			end
		end
		return;
	end

	if(event == "CLOSE_RE_IDENTIFY_MSGBOX" ) then
		if(this:IsVisible()) then
			if g_FrameInfo == FrameInfoList.CONFIRM_RE_IDENTIFY  then
				this:Hide();
			end
		end
		return;
	end

	if(event == "CLOSE_KICK_MEMBER_MSGBOX" ) then
		if(this:IsVisible()) then
			if g_FrameInfo == FrameInfoList.KICK_MEMBER_MSGBOX  then
				this:Hide();
			end
		end
		return;
	end

	if(event == "CLOSE_SAFEBOX_CONFIRM" ) then
		if(this:IsVisible()) then
			if (g_FrameInfo == FrameInfoList.SAFEBOX_LOCK_CONFIRM or g_FrameInfo == FrameInfoList.SAFEBOX_UNLOCK_CONFIRM) then
				this:Hide();
			end
		end
		return;
	end


	if(event == "CLOSE_RECYCLESHOP_MSG" ) then
		if(this:IsVisible()) then

			if g_FrameInfo == FrameInfoList.RECYCLE_DEL_ITEM  then
				CancelLastOp(-1);
				this:Hide();
			elseif g_FrameInfo == FrameInfoList.OPEN_IS_SELL_TO_RECSHOP then
				CancelLastOp(-1);
				this:Hide();
			end
		end
		return;
	end

	if(event == "ENCHASE_CLOSE_MSGBOX" ) then
		if(this:IsVisible() and  g_FrameInfo == FrameInfoList.ENCHASE_CONFIRM) then
			CancelLastOp(-1);
			this:Hide();
		end
		return;
	end



	-- add:lby20080527确认4镶嵌ENCHASE_FOUR_CONFIRM
	if(event == "ENCHASE_CLOSE_MSGBOX" ) then
		if(this:IsVisible() and  g_FrameInfo == FrameInfoList.ENCHASE_FOUR_CONFIRM) then
			CancelLastOp(-1);
			this:Hide();
		end
		return;
	end

	if(event == "CHAR_RANAME_CONFIRM" ) then
		g_arg_chrc = arg0;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0角色改名");
		MessageBox_Self_Text:SetText("注意，您只有一次改名的机会。#r您确认要修改名字为#G"..g_arg_chrc.."#cFFF263么？");
		CancelLastOp(FrameInfoList.CHAR_RANAME_CONFIRM);
		g_FrameInfo = FrameInfoList.CHAR_RANAME_CONFIRM
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	end

	if(event == "CITY_RANAME_CONFIRM" ) then
		g_arg_circ = arg0;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0帮会改名");
		MessageBox_Self_Text:SetText("注意，您只有一次改名的机会。#r您确认要修改帮会名为#G"..g_arg_circ.."#cFFF263么？");
		CancelLastOp(FrameInfoList.CITY_RANAME_CONFIRM);
		g_FrameInfo = FrameInfoList.CITY_RANAME_CONFIRM
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	end

	if(event == "CHANGE_NAME_CONFIRM" ) then
		ObjCaredID = tonumber(arg2);
		if ObjCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MsgBox");
		end

		g_arg_chrc = arg0;
		MessageBox_Self_DragTitle:SetText("#{GMT_20100811_3}"); -- #gFF0FA0角色改名
		local textStr = string.format("#{GMT_20100811_19}%s#{GMT_20100811_20}",g_arg_chrc)
		MessageBox_Self_Text:SetText(textStr);
		CancelLastOp(FrameInfoList.CHANGE_NAME_CONFIRM);
		g_FrameInfo = FrameInfoList.CHANGE_NAME_CONFIRM
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	end

	if(event == "GAMELOGIN_OPEN_COUNT_INPUT") then
		if(this:IsVisible()) then
			CancelLastOp(-1);
			this:Hide();
		end
		return;
	end

	if(event == "SAFEBOX_LOCK_CONFIRM") then
		CancelLastOp(FrameInfoList.SAFEBOX_LOCK_CONFIRM);
		g_FrameInfo = FrameInfoList.SAFEBOX_LOCK_CONFIRM;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0保险箱锁定");
		MessageBox_Self_Text:SetText("#{YHBXX_20071220_10}");
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	end

	if(event == "SAFEBOX_UNLOCK_CONFIRM") then
		CancelLastOp(FrameInfoList.SAFEBOX_UNLOCK_CONFIRM);
		g_FrameInfo = FrameInfoList.SAFEBOX_UNLOCK_CONFIRM;
		MessageBox_Self_DragTitle:SetText("#gFF0FA0保险箱解锁");
		MessageBox_Self_Text:SetText("#{YHBXX_20071220_07}");
		MessageBox_Self_UpdateRect();
		this:Show();
		return;
	end

	if (event == "CONFIRM_SETPOS_TLZ") then
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iPosX = tonumber(arg2);
		local iPosZ = tonumber(arg3);

		CancelLastOp(FrameInfoList.TLZ_CONFIRM_SETPOS);
		g_FrameInfo = FrameInfoList.TLZ_CONFIRM_SETPOS;

		Client_ItemIndex = itemIdx

		if (szSceneName ~= "") then
			MessageBox_Self_Text:SetText("#{TLZ_081114_1}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."#{TLZ_081114_2}")
			MessageBox_Self_UpdateRect();
			this:Show();
		else
			MessageBox_Self_OK_Clicked()
			this:Hide()
			return
		end

	end

	if (event == "CONFIRM_SETPOS_DLZ") then
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iPosX = tonumber(arg2);
		local iPosZ = tonumber(arg3);

		CancelLastOp(FrameInfoList.DLZ_CONFIRM_SETPOS);
		g_FrameInfo = FrameInfoList.DLZ_CONFIRM_SETPOS;

		Client_ItemIndex = itemIdx

		if (szSceneName ~= "") then
			MessageBox_Self_Text:SetText("#{WPKC_141107_14}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."#{TLZ_081114_2}")
			MessageBox_Self_UpdateRect();
			this:Show();
		else
			MessageBox_Self_OK_Clicked()
			this:Hide()
			return
		end

	end

	if (event == "CONFIRM_SETPOS_KWLZ") then
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iPosX = tonumber(arg2);
		local iPosZ = tonumber(arg3);

		CancelLastOp(FrameInfoList.KWLZ_CONFIRM_SETPOS);
		g_FrameInfo = FrameInfoList.KWLZ_CONFIRM_SETPOS;

		Client_ItemIndex = itemIdx

		if (szSceneName ~= "") then
			MessageBox_Self_Text:SetText("#{KWLZ_151013_7}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."#{TLZ_081114_2}")
			MessageBox_Self_UpdateRect();
			this:Show();
		else
			MessageBox_Self_OK_Clicked()
			this:Hide()
			return
		end

	end

	-- 弹出解散队伍的二次确认窗口			add by WTT	20090212
	if (event == "OPNE_DISMISS_TEAM_MSGBOX")	then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0解散队伍");			-- 设置标题
		MessageBox_Self_Text:SetText( "#{TeamDismiss_090912_1}" );	-- 设置内容
		CancelLastOp(FrameInfoList.DISMISS_TEAM);
		g_FrameInfo = FrameInfoList.DISMISS_TEAM;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
		return;
	end

	if ( event == "TRUST_FRIEND_OPEN_DEL_CHECK" ) then
		MessageBox_Self_DragTitle:SetText("#{XRHB_09515_14}");													-- 设置标题
		MessageBox_Self_Text:SetText( "#{XRHB_09515_15}"..arg1.."#{XRHB_09515_16}");	-- 设置内容
		CancelLastOp(FrameInfoList.TRUST_FRIEND);
		g_FrameInfo = FrameInfoList.TRUST_FRIEND;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
		g_currentIndex = tonumber( arg0 );
		return;
	end

	-- 卸载收费表情确认
	if ( event == "UNINSTALL_CHAT_FACE_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("#{BQB_XML_10}");					-- 设置标题：卸载确认
		g_currentIndex = tonumber( arg0 );
		local faceID , faceValidDate , faceCount = DataPool:GetRMB_FaceInfo(g_currentIndex )
		local faceName = DataPool:GetRMB_FaceName(faceID)
		MessageBox_Self_Text:SetText( "#{BQB_091026_8}"..tostring(faceName).."#{BQB_091026_9}"); -- 您确认要卸载&U表情包吗？
		g_FrameInfo = FrameInfoList.UNINSTALL_CHAT_FACE;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
		return;
	end

	-- 卸载收费休闲动作确认
	if ( event == "UNINSTALL_CHAT_ACTION_CONFIRM" ) then
		MessageBox_Self_DragTitle:SetText("#{BQB_XML_10}");					-- 设置标题：卸载确认
		g_currentIndex = tonumber( arg0 );
		local actionID , actionValidDate , actionCount, actionMinIndex, actionType = DataPool:Get_RMB_ChatActionInfo(g_currentIndex )
		local actionName = DataPool : Get_RMB_ChatActionName(actionID)
		MessageBox_Self_Text : SetText( "#{SRDZ_XML_7}"..tostring(actionName).."#{SRDZ_XML_8}" );		-- 您确认要卸载XXX动作包吗？#G（卸载后将不能继续使用此表情包）
		g_FrameInfo = FrameInfoList.UNINSTALL_CHAT_ACTION;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
		return;
	end

	if ( event == "TEAMBOARD_OPEN_DEL_CHECK" ) then
		g_TeamBoardWindow = tonumber(arg0);
		MessageBox_Self_DragTitle:SetText("#{ZDPT_XML_24}");													-- 设置标题
		MessageBox_Self_Text:SetText( "#{ZDPT_XML_25}");	-- 设置内容
		g_FrameInfo = FrameInfoList.TEAMBOARD_OPEN_DEL_CHECK;
		MessageBox_Self_UpdateRect();																-- 恢复窗口大小到初始大小
		this:Show();
		return;
	end

	if ( event == "SUCCEED_EXCHANGE_CLOSE" ) then	--for TT:70792
		if(this:IsVisible() and  g_FrameInfo == FrameInfoList.PET_FREE_CONFIRM) then
			CancelLastOp(-1);
			this:Hide();
		end
		return;
	end

	if(event =="YIGUI_OPEN") then
		if (g_FrameInfo == FrameInfoList.SERVER_CONTROL) and  (Server_Script_ID == 161)  then
			this:Hide();
		end
		return;
	end


	--[[
	if (event == "CONFIRM_SETPOS_DJTS") then
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iPos = tonumber(arg2);
                local iSelIdx = tonumber(arg3);

                local iTemp = 65536;
                local iPosX = math.floor(iPos/iTemp )
                local iPosZ = iPos- math.floor(iPos/iTemp )*iTemp

		CancelLastOp(FrameInfoList.DJTS_CONFIRM_SETPOS)

		g_FrameInfo = FrameInfoList.DJTS_CONFIRM_SETPOS

		Client_ItemIndex = itemIdx
		DJS_SelIndex = iSelIdx

		local curSceneName = GetCurrentSceneName()
		local curPosX, curPosZ, _ = Target:GetMyPos()
		curPosX = math.floor(curPosX)
                curPosZ = math.floor(curPosZ)

		local str = "#{DJTS_110509_12}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."#r".."#{DJTS_110509_13}"..curSceneName.."（"..curPosX.."，"..curPosZ.."）"

		if (szSceneName ~= "") then
			MessageBox_Self_Text:SetText(str);
			MessageBox_Self_UpdateRect();
			this:Show();
		else
			MessageBox_Self_OK_Clicked()
			this:Hide()
			return
		end

	end

	if (event == "CONFIRM_SETPOS_DJQS") then
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iPos = tonumber(arg2);
                local iSelIdx = tonumber(arg3);
		local iTemp = 65536;
                local iPosX = math.floor(iPos/iTemp )
                local iPosZ = iPos- math.floor(iPos/iTemp )*iTemp

		CancelLastOp(FrameInfoList.DJQS_CONFIRM_SETPOS);
		g_FrameInfo = FrameInfoList.DJQS_CONFIRM_SETPOS;

		Client_ItemIndex = itemIdx
                DJS_SelIndex = iSelIdx

		local curSceneName = GetCurrentSceneName()
		local curPosX, curPosZ, _ = Target:GetMyPos()
		curPosX = math.floor(curPosX)
                curPosZ = math.floor(curPosZ)

		local str = "#{DJTS_110509_12}".."\n"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."\n".."#{DJTS_110509_13}"..curSceneName.."（"..curPosX.."，"..curPosZ.."）"

		if (szSceneName ~= "") then
			MessageBox_Self_Text:SetText(str)
			MessageBox_Self_UpdateRect();
			this:Show();
		else
			MessageBox_Self_OK_Clicked()
			this:Hide()
			return
		end

	end

	if(event == "CONFIRM_CHUANSONG_DJTS") then
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iPos = tonumber(arg2);
                local iSelIdx = tonumber(arg3);
		local iTemp = 65536;
                local iPosX = math.floor(iPos/iTemp )
                local iPosZ = iPos- math.floor(iPos/iTemp )*iTemp

		CancelLastOp(FrameInfoList.DJTS_CONFIRM_CHUANSONG);
		g_FrameInfo = FrameInfoList.DJTS_CONFIRM_CHUANSONG;

		Client_ItemIndex = itemIdx
                DJS_SelIndex = iSelIdx

		local str = "#{DJTS_110509_14}".."\n"..szSceneName.."（"..iPosX.."，"..iPosZ.."）";
		if (szSceneName ~= "") then
			MessageBox_Self_Text:SetText(str)
			MessageBox_Self_UpdateRect();
			this:Show();
		else
		   PushDebugMessage("#{DJTS_110509_31}")
		   this:Hide()
		   return
		end
	end

	if(event == "CONFIRM_CHUANSONG_DJQS") then
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iPos = tonumber(arg2);
                local iSelIdx = tonumber(arg3);
		local iTemp = 65536;
                local iPosX = math.floor(iPos/iTemp )
                local iPosZ = iPos- math.floor(iPos/iTemp )*iTemp

		CancelLastOp(FrameInfoList.DJQS_CONFIRM_CHUANSONG);
		g_FrameInfo = FrameInfoList.DJQS_CONFIRM_CHUANSONG;

		Client_ItemIndex = itemIdx
                DJS_SelIndex = iSelIdx


		local str;
		local iIsLeader = Player:IsLeader()
		if (1 == iIsLeader) then
			str= "#{DJTS_110509_27}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）"
		else
			str= "#{DJTS_110509_14}".."\n"..szSceneName.."（"..iPosX.."，"..iPosZ.."）"
		end


		if (szSceneName ~= "") then
			MessageBox_Self_Text:SetText(str)
			MessageBox_Self_UpdateRect();
			this:Show();
		else
		   PushDebugMessage("#{DJTS_110509_31}")
		   this:Hide()
		   return

		end
	end

	if(event == "CONFIRM_BUCHONG_DJTS") then
		local itemIdx = tonumber(arg0)
		local iNum = tonumber(arg1);
    		Client_ItemIndex = itemIdx

		CancelLastOp(FrameInfoList.DJTS_CONFIRM_BUCHONG);
		g_FrameInfo = FrameInfoList.DJTS_CONFIRM_BUCHONG;

		local str;
		if (iNum>10) then
			str= "#{DJTS_110509_11}"
		else
			str= "#{DJTS_110509_10}"
		end

		MessageBox_Self_Text:SetText(str)
		MessageBox_Self_UpdateRect();
		this:Show()
	end

	if(event == "CONFIRM_BUCHONG_DJQS") then
		local itemIdx = tonumber(arg0)
		local iNum = tonumber(arg1);
    		Client_ItemIndex = itemIdx

		CancelLastOp(FrameInfoList.DJQS_CONFIRM_BUCHONG);
		g_FrameInfo = FrameInfoList.DJQS_CONFIRM_BUCHONG;

		local str;
		if (iNum>10) then
			str= "#{DJTS_110509_11}"
		else
			str= "#{DJTS_110509_10}"
		end

		MessageBox_Self_Text:SetText(str)
		MessageBox_Self_UpdateRect()
		this:Show()
	end
	--]]

	--VIP特权激活确认框
	if (event == "OPEN_VIP_SHOP") then
		if tonumber(arg0) == -1 then
			MessageBox_Self_DragTitle:SetText("#{VIPTQ_110908_02}")
			MessageBox_Self_Text:SetText("#{VIPTQ_110908_03}")
			CancelLastOp(FrameInfoList.CONFIRM_UPDATE_VIP)
			g_FrameInfo = FrameInfoList.CONFIRM_UPDATE_VIP
			MessageBox_Self_UpdateRect()
			this:Show()
		end
		return
	end

	-- 解散合作关系
	if ( event == "DISSOLUTIONOFCONTRACT" ) then
		if ( tonumber( arg0 ) ~= -1 ) then
			MessageBox_Self_DragTitle:SetText( "#{HZHB_130712_10}" )
			MessageBox_Self_Text:SetText( ScriptGlobal_Format( "#{HZHB_130712_03}", PlayerShop:GetShopInfo("self","shopname") ) )
			MessageBox_Self_UpdateRect();

			g_DissolutionIndex = tonumber( arg0 )
			CancelLastOp( FrameInfoList.CONFIRM_DISSOLUTIONOFCONTRACT )
			g_FrameInfo = FrameInfoList.CONFIRM_DISSOLUTIONOFCONTRACT

			-- 关心NPC
			ObjCaredID = PlayerShop:GetNpcId();
			this:CareObject(ObjCaredID, 1, "MsgBox")
		end
	end
  
	-- 学习心法
	if ( event == "STUDY_XINFA" ) then
		argStudyXinFaNowLevel = tonumber( arg0 );	-- 等级
		argStudyXinFaID = tonumber( arg1 );			-- ID
		argStudyXinFaMenPai = tonumber( arg2 );		-- 门派

		CancelLastOp( FrameInfoList.STUDY_XINFA );
		g_FrameInfo = FrameInfoList.STUDY_XINFA;

		MessageBox_Self_DragTitle:SetText("");
		MessageBox_Self_Text : SetText( "本次升级需要使用角色自身经验，是否确定完成本次操作？" );
		MessageBox_Self_UpdateRect();
		this:Show();
		return
	end

	-- 修炼
	if ( event == "STUDY_XIULIAN" ) then
		argXiuLianFuncName = tostring( arg0 );		-- 函数名称
		argXiuLianScriptID = tonumber( arg1 );		-- 脚本ID
		argXiuLianNpcID = tonumber( arg2 );			-- NPCID
		argXiuLianMiJiSelect = tonumber( arg3 ); 	-- 选择项

		CancelLastOp( FrameInfoList.STUDY_XIULIAN );
		g_FrameInfo = FrameInfoList.STUDY_XIULIAN;

		MessageBox_Self_DragTitle:SetText("");
		MessageBox_Self_Text : SetText( "本次升级需要使用角色自身经验，是否确定完成本次操作？" );
		MessageBox_Self_UpdateRect();
		this:Show();
		return
	end

	--珍兽套装拆解确认
	--if( event == "PET_EQUIP_DEPART_CONFIRM" ) then
		--MessageBox_Self_Text:SetText(tostring(arg0))
		--MessageBox_Self_DragTitle:SetText("#{ZSCJ_160218_3}")
		--MessageBox_Self_UpdateRect();
		--g_FrameInfo = FrameInfoList.PET_EQUIPSUITDEPART_CONFIRM
		--this:Show()
		--return
	--end

	if ( event == "PLAYER_LEAVE_WORLD" ) then
		if (g_FrameInfo == FrameInfoList.AUTOMOVE_CONFIRM_NOPKVALUE or
			g_FrameInfo == FrameInfoList.AUTOMOVE_CONFIRM_UPPKVALUE or
			g_FrameInfo == FrameInfoList.AUTOMOVE_CONFIRM_FENGMING)	or
			g_FrameInfo == FrameInfoList.CONFIRM_DISSOLUTIONOFCONTRACT or
			g_FrameInfo == FrameInfoList.CONFIRM_UPDATE_VIP or
			g_FrameInfo == FrameInfoList.SERVER_CONTROL  or 
			g_FrameInfo == FrameInfoList.CONFIRM_BASE_SHANHAIBI_CONFIRM or
			g_FrameInfo == FrameInfoList.BUY_SUPERASS_FASHION_CONFIRM or
			g_FrameInfo == FrameInfoList.CHONGLOU_EFFECT_ACTIVE_CONFIRM or
			g_FrameInfo == FrameInfoList.XIAKE_GUAIWU_ZHAOJILING_CONFIRM then
			this:Hide();
		end

		return
	end

	if(event == "UINT_YHCHECK") then
		CancelLastOp(-1);
		g_FrameInfo = FrameInfoList.SERVER_CONTROL;if(this:IsVisible() and  g_FrameInfo == FrameInfoList.SERVER_CONTROL) then
			CancelLastOp(-1);
			this:Hide();
		end
		return
	end

	if event == "DIGONGSHOP_CONFIRM" then
		if g_FrameInfo == FrameInfoList.DIGONGSHOP_CONFIRM and this:IsVisible() then
			this:Hide()
		end
		return -1
	end
	
	if(MessageBox_Self_OnEventEx(event) > 0) then
		MessageBox_Self_UpdateFrame();
	end

end

function MeesageBox_Init()
	strMessageString = tostring( arg0 );
	strMessageData	= tostring( arg1 );
	strMessageArgs = tostring(arg2);
	strMessageType	= tostring(arg3);
	strMessageArgs_2 = tostring(arg4)
	CancelLastOp(FrameInfoList.EQUIP_ITEM);
	g_FrameInfo = FrameInfoList.EQUIP_ITEM;

	if strMessageData == "YiGuiDressBind" or strMessageData == "InfantYiGuiDressBind" or strMessageData == "YiGuiWeaponBind" or strMessageData == "YiGuiAllBind" then     --衣柜需要NPC关心
		ObjCaredID = tonumber(strMessageArgs_2)
		if ObjCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MsgBox")
		end
	end

	if(strMessageData == "UseMiFa") then
		CancelLastOp(FrameInfoList.CONFIRM_USE_MIFA);
		g_FrameInfo = FrameInfoList.CONFIRM_USE_MIFA;
		g_table_ItemGuid[1] = tostring(arg5);	--使用道具64位GUID的高32位
		g_table_ItemGuid[2] = tostring(arg6);	--使用道具64位GUID的低32位
	end

	if(strMessageData == "StallOffline") then
		CancelLastOp(FrameInfoList.STALL_OFFLINE_CANCLE);
		g_FrameInfo = FrameInfoList.STALL_OFFLINE_CANCLE;
	end

	if(strMessageData == "StallOffline_ERRState") then
		CancelLastOp(FrameInfoList.STALL_OFFLINE_ERRSTATE);
		g_FrameInfo = FrameInfoList.STALL_OFFLINE_ERRSTATE;
	end


	MessageBox_Update();

end

function MessageBox_Update()
	this:Show();
	MessageBox_Self_OK_Button:Hide();
	MessageBox_Self_Cancel_Button:Hide();
	MessageBox_Self_Text:SetText( strMessageString );
	MessageBox_Self_DragTitle:SetText("#gFF0FA0#gFF0FA0确 认")
	MessageBox_Self_Cancel_Button:SetText("#{INTERFACE_XML_542}")--取消
    if SystemSetup:IsClassic() == 1 then
    	MessageBox_Self_Blank:SetProperty("UnifiedSize", "{{1.000000,-85.000000},{0.000000,20.000000}}")
    end
	if( strMessageType == "Normal" ) then
		MessageBox_Self_OK_Button:Show();
		MessageBox_Self_Cancel_Button:Show();
	elseif( strMessageType == "OK" ) then
		MessageBox_Self_OK_Button:Show();
	elseif( strMessageType == "Cancel" ) then
		MessageBox_Self_Cancel_Button:Show();
	elseif( strMessageType == "NoButton" ) then
	elseif( strMessageType == "Hide" ) then
		this:Hide();
	elseif( strMessageType == "GuanBi") then
		MessageBox_Self_Cancel_Button:Show();
		MessageBox_Self_Cancel_Button:SetText("#{INTERFACE_XML_1173}") --关闭
        if SystemSetup:IsClassic() == 1 then
		    MessageBox_Self_Blank:SetProperty("UnifiedSize", "{{1.000000,-43.000000},{0.000000,20.000000}}")
        end
	end
	MessageBox_Self_UpdateRect();
end
function MessageBox_Self_City_UpdateFrame()

	--申请领地确认信息
	if(g_CityData[1] == 1) then
		local szPortName = City:GetPortInfo(g_CityData[2], "Name");
		MessageBox_Self_DragTitle:SetText("#gFF0FA0申请领地");
		--你确定要申请所在于AA的“BB”领地吗？这项行为需要消耗1000个金币。
		local msg = "#cFFF263你确定要申请所在于#cFE7E82"..tostring(szPortName).."#cFFF263的#H"..g_CityData[3].."#cFFF263";
		msg = msg.."领地吗？这项行为需要消耗1000#-14或者一块建城令牌。";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	--修建或升级建筑物
	elseif(g_CityData[1] == 2 or g_CityData[1] == 3) then
		local szName, bLevel, bId = City:GetCityManageInfo("CurBuilding");
		if(bLevel == -1 or bId == -1) then
			local szExist = "";
			if(g_CityData[1] == 2) then
				MessageBox_Self_DragTitle:SetText("#gFF0FA0建设新建筑");
				szExist = "修建";
			else
				MessageBox_Self_DragTitle:SetText("#gFF0FA0升级建筑");
				szExist = "升级";
			end

			local szName = (City:GetBuildingInfo(g_CityData[2], "name"));
			--建设条件
			local cd = {City:GetBuildingInfo(g_CityData[2], "condition")};
			--0.金钱
			local money = cd[1];
			local txt = "";
			--2.任务数
			local mn =City:GetBuildingInfo(g_CityData[2], "BuildingTime");

			--local msg = szExist..szName.."需要消耗"..money.."帮会资金，并自动发布"..mn.."环建设任务，当所有任务完成时，"..szName.."修建完成,您确认进行修建操作吗?";
			local msg = "";
			if ( g_CityData[ 1 ] == 2 ) then
				msg = ScriptGlobal_Format( "#{BHJS_140515_13}", szName, money, mn, szName );
			elseif ( g_CityData[ 1 ] == 3 ) then
				msg = ScriptGlobal_Format( "#{BHJS_140515_28}", szName, money, mn, szName );
			end
			MessageBox_Self_Text:SetText(msg);
			MessageBox_Self_UpdateRect();
			this:Show();
		else
			City:DoConfirm(0);	--取消当前建筑的确认信息
		end
	--创建商业路线的确认信息
	elseif(g_CityData[1] == 9) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0创建商业路线");
		local msg = "此操作将与编号为"..tostring(g_CityData[2]).."的帮会建立商线，只有双方互建商线，商线才会生效，你确定要建立吗?";
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	--取消商业路线的确认信息
	elseif(g_CityData[1] == 10) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0取消商业路线");
		local dt = {City:GetCityRoadInfo("RoadDetail", g_CityData[2])};
		local msg = "";
		if(dt[4]) then
			msg = "此操作将使本帮与对方帮会的商业行为单方面终止，你确定要继续进行操作吗?";
		else
			msg = "此操作将使本帮与对方帮会不会再有互建商线的可能，你确定要继续进行操作吗?";
		end
		MessageBox_Self_Text:SetText(msg);
		MessageBox_Self_UpdateRect();
		this:Show();
	end
end

function MessageBox_Self_City_OK_Clicked()
	if(g_CityData[1] == 1) then
		City:CreateCity(g_CityData[2],g_CityData[3]);
	elseif(g_CityData[1] == 2) then
		City:DoBuilding(g_CityData[2], "create");
	elseif(g_CityData[1] == 3) then
		City:DoBuilding(g_CityData[2], "up");
	elseif(g_CityData[1] == 9) then
		City:DoCityRoad("create", g_CityData[2]);
	elseif(g_CityData[1] == 10) then
		City:DoCityRoad("cancel", g_CityData[2]);
	end
	g_CityData = {};
end

function MessageBox_Self_City_Cancel_Clicked()
	g_CityData = {};
end


--===============================================
-- UpdateFrame
--===============================================
function MessageBox_Self_UpdateFrameEx()

	if( g_FrameInfo==FrameInfoList.SAVE_STALL_INFO) then

		MessageBox_Self_DragTitle:SetText("#gFF0FA0保存摊位设置");
		local szInfo;
		szInfo = "#{INTERFACE_XML_681}";
		MessageBox_Self_Text:SetText(szInfo);
		this:Show();
	-- add by zchw
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_REMOVE_STALL) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0收摊");
		local szInfo;
		szInfo = "你真的要收摊吗？";
		MessageBox_Self_Text:SetText(szInfo);
		this:Show();
	-- zchw for pet procreate
	elseif (g_FrameInfo == FrameInfoList.PET_PROCREATE_PROMPT) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0注意");
		MessageBox_Self_Text:SetText("#{JJKHD_120808_16}"); --珍兽进阶
		this:Show();
	elseif(g_FrameInfo == FrameInfoList.YUANBAO_BUY_ITEM) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0购买商品")
		local szInfo
		if g_CurUint == g_CurUintType.YuanBao then
			szInfo = "购买"..g_CityData[3].."需要花费"..tostring(g_CityData[2]).."个元宝，你确认吗？"
		elseif g_CurUint == g_CurUintType.Bind then
			szInfo = "#{BDYB_090720_01}"..g_CityData[3].."#{BDYB_090720_02}"..tostring(g_CityData[2]).."#{BDYB_090720_03}"
		elseif g_CurUint == g_CurUintType.GiftToken then
			szInfo = "#{YBFQ_XML_6}"..g_CityData[3].."#{YBFQ_XML_7}"..tostring(g_CityData[2]).."#{YBFQ_XML_8}"
		elseif g_CurUint == g_CurUintType.LiJin then
			szInfo = "#{BDYB_090720_01}"..g_CityData[3].."#{BDYB_090720_02}"..tostring(g_CityData[2]).."#{LJSD_120508_25}"
		elseif g_CurUint == g_CurUintType.LiJin_DisCount then
			local nMD = math.mod(DataPool:GetPlayerMission_DataRound(1561),10)
			if nMD < 2 then
				szInfo = ScriptGlobal_Format("#{LJSD_180312_07}",g_CityData[3],g_CityData[2],2-nMD)
			else
				PushDebugMessage("#{LJSD_180312_05}")
				return 0
			end
		elseif g_CurUint == g_CurUintType.BWHonourValue then
			szInfo=ScriptGlobal_Format("#{XBWDH_130521_29}", g_CityData[3], tostring(g_CityData[2]))
		elseif g_CurUint == g_CurUintType.ShowCredit then
			szInfo=ScriptGlobal_Format("#{XCZB_160105_42}", g_CityData[3], tostring(g_CityData[2]))
		end
		MessageBox_Self_Text:SetText(szInfo);
		this:Show();
	elseif g_FrameInfo == FrameInfoList.T3SHOP_BUY_ITEM_CONFIRM then	
		MessageBox_Self_T3Shop_Confirm()
	elseif ( g_FrameInfo == FrameInfoList.FITTINGROOM_BUY_ITEM_CONFIRM ) then
		MessageBox_Self_DragTitle:SetText("#{FFSDGZ_120615_13}");
		local szInfo;
		if ( g_CurUint == 5 ) then
			szInfo = ScriptGlobal_Format("#{FFSDGZ_120615_59}",g_CityData[2], tostring(g_CityData[3]))
			--szInfo = "购买"..g_CityData[2].."需要花费"..tostring(g_CityData[3]).."个元宝，你确认吗？";
		elseif ( g_CurUint == 10 ) then
			szInfo = "#{YBFQ_XML_6}"..g_CityData[2].."#{YBFQ_XML_7}"..tostring(g_CityData[3]).."#{YBFQ_XML_8}";
		elseif ( g_CurUint == 9 ) then
			szInfo = "#{BDYB_090720_01}"..g_CityData[2].."#{BDYB_090720_02}"..tostring(g_CityData[3]).."#{BDYB_090720_03}";
		elseif ( g_CurUint == 14 ) then
			szInfo = ScriptGlobal_Format("#{XCZB_160105_42}", g_CityData[2], tostring(g_CityData[3]))
		end
		MessageBox_Self_Text:SetText(szInfo);
		this:Show();

	
	elseif ( g_FrameInfo == FrameInfoList.JIYUANSHOP_BUY_ITEM_CONFIRM ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0购买商品");
		local szInfo;
		local theAction = EnumAction(g_CityData[1], "boothjiyuanitem");
		local	nPrice	= NpcShop:EnumItemPriceJiYuanBooth( g_CityData[1] )
		szInfo = ScriptGlobal_Format("#{FFSDGZ_120615_62}",theAction:GetName(), tostring(nPrice))
		--szInfo = "购买#G"..theAction:GetName().."#cfff263需要花费#G"..nPrice.."#cfff263个元宝，您确定吗？#r#G小提示：秘宝商店中的商品购买后绑定。";
		MessageBox_Self_Text:SetText(szInfo);
		this:Show();
	elseif(g_FrameInfo == FrameInfoList.COMMISION_BUY) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0购买商品");
		local szInfo;
		szInfo = "购买"..CommisionBuyData[1].."需要花费"..CommisionBuyData[2].."，你确认吗？";
		MessageBox_Self_Text:SetText(szInfo);
		this:Show();
	elseif(g_FrameInfo == FrameInfoList.IMDressBuyToOther) then
		MessageBox_Self_DragTitle:SetText("#{ZSGN_101129_09}");
		--计算总价
		local totalPrice = 0
		for i = 1, 12 do
			local theAction = EnumAction(i-1, "paybox");
			if theAction:GetID() ~= 0 then
				local nPrice = IMDressGetPayBoxPrice( i-1 )
				totalPrice = totalPrice + nPrice;
			end
		end
		local Friendgroup, Friendindex = DataPool:GetFriendByGUID(IMDressBuyToOtherData[2]);
		local FriendName = DataPool:GetFriend( Friendgroup, Friendindex, "NAME"  )
		local msg = "#{ZSGN_101129_12}"..totalPrice.."#{ZSGN_101129_30}"..FriendName.."#{ZSGN_101129_31}";
		MessageBox_Self_Text:SetText(msg);
		this:Show();
	elseif(g_FrameInfo == FrameInfoList.CHONGLOU_SHOP_CONFIRM) then
		MessageBox_Self_DragTitle:SetText("#{CLDHDB_210510_59}");
		this:Show();
	end

	return 1
end

--===============================================
-- UpdateTitle
--===============================================
function UpdateTitle()
    --因为在MessageBox_Self_UpdateFrame函数中,"upvalue"严重超员,增加了这个函数用来更改msgbox的标题
    if ( PVPFLAG.FREEFORALL == g_FrameInfo ) then
        MessageBox_Self_DragTitle:SetText("#gFF0FA0更改PK模式");
    elseif ( PVPFLAG.FREEFORTEAM == g_FrameInfo ) then
        MessageBox_Self_DragTitle:SetText("#gFF0FA0更改PK模式");
    elseif ( PVPFLAG.FREEFORGUILD == g_FrameInfo ) then
        MessageBox_Self_DragTitle:SetText("#gFF0FA0更改PK模式");
    elseif ( PVPFLAG.MAKESUREPVPCHALLENGE == g_FrameInfo ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0宣战确认");
	elseif ( PVPFLAG.FREEFORRAID == g_FrameInfo ) then
    	MessageBox_Self_DragTitle:SetText("#gFF0FA0更改PK模式");
	elseif ( FrameInfoList.PNEUMA_LOCK_CONFIRM == g_FrameInfo ) then
        	MessageBox_Self_DragTitle:SetText("#gFF0FA0#{INTERFACE_XML_355}");
	elseif (FrameInfoList.PNEUMA_JUYUAN_CONFIRM==g_FrameInfo) then
		MessageBox_Self_DragTitle:SetText("#{ZYXT_120528_174}");
	elseif ( PVPFLAG.FREE_FOR_KGUILD == g_FrameInfo ) then				-- 更改PK模式(K服帮会混战模式)
		MessageBox_Self_DragTitle:SetText("#gFF0FA0更改PK模式");
	elseif ( FrameInfoList.BUDGETPLANINFO_DOWNPAY == g_FrameInfo ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0首付");
	elseif ( FrameInfoList.BUDGETPLANINFO_REPAY == g_FrameInfo ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0还款");
	elseif (FrameInfoList.GUILDSHOP_ITEM_SURE ==g_FrameInfo) then
		MessageBox_Self_DragTitle:SetText("#{BHSC_140509_46}");
	elseif FrameInfoList.INFANT_DRESS_CUT_PAINT_CONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText("#{ZNSZ_140718_126}")
	elseif FrameInfoList.INFANT_CARD_EQUIP_CONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText("#{ZSLZ_XML_1}")
	elseif FrameInfoList.MILITARYRANKSHOPBUYCONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( "#{JWSD_140821_30}" );
	elseif FrameInfoList.NOBILITYSHOPBUYCONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( "#{JWSD_140821_30}" );
	elseif FrameInfoList.SHIDESHOPBUYCONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( "#{SDSD_150514_22}" );
	elseif FrameInfoList.DISMISS_ZHANTUAN_CONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText("")
	elseif ( FrameInfoList.TIANJIANGQIFU_CONFIRM == g_FrameInfo ) then
		MessageBox_Self_DragTitle:SetText( "" );
	elseif FrameInfoList.RESIGN_YUANBAO_CONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( "#{MYQD_150513_29}" );
	elseif FrameInfoList.CONFIRM_SUMMERVACATION == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( "#{SJFL_150608_44}" );
	elseif FrameInfoList.CONFIRM_ZHOUNIANQING_PRIZE == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( "#{BZNMR_170216_08}" );
	elseif FrameInfoList.PVP_ALLIANCE == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0更改PK模式");
	elseif FrameInfoList.CONFIRM_BIN_COMMON == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( g_Common_Title );
	elseif FrameInfoList.MOUNT_PROLONG_CONFIRM == g_FrameInfo then
		MessageBox_Self_DragTitle:SetText( "#{XQZJ_180831_16}" );
	end
	MessageBox_Self_UpdateRect();

end

--===============================================
-- UpdateFrame
--===============================================
function MessageBox_Self_UpdateFrame()

	MessageBox_Self_DragTitle:SetText("#gFF0FA0");
	UpdateTitle()

	if g_FrameInfo == FrameInfoList.GEM_COMBINED_CONFIRM then
		this : Show()
		MessageBox_Self_Text : SetText( GemCombinedData[7] )
		MessageBox_Self_UpdateRect();
		return
	end

	if(g_FrameInfo == FrameInfoList.STALL_RENT_FRAME) then
		--提示本的费用
		local nPosTax = StallSale:GetPosTax();
		local nTradeTax = StallSale:GetTradeTax();

		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(nPosTax);

		local szMoneyPosTax = "";
		if(nGoldCoin ~= 0)   then
		 	szMoneyPosTax = tostring(nGoldCoin) .. "#-14";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoneyPosTax = szMoneyPosTax .. tostring(nSilverCoin) .. "#-15";
		end
		if(nCopperCoin ~= 0)   then
			szMoneyPosTax = szMoneyPosTax .. tostring(nCopperCoin) .. "#-16";
		end
		local serverType = StallSale:GetStallServerType()
		local nCoinType = StallSale:GetStallType()
		if (nCoinType == 1) then --元宝摆摊
			if serverType == 1 then
				MessageBox_Self_Text:SetText("#{FMQZ_221110_16}");
			else
				local szInfo = "#{YBBT_081031_1}".. szMoneyPosTax .."#{YBBT_081031_2}1#{JJKHD_120808_14}"; --珍兽进阶
				MessageBox_Self_Text:SetText(szInfo);
			end
		else
			local szInfo = ""
			local kajiType = KaJi:LuaFnGetKaJiType(26)
			if KaJi:LuaFnIsKaJiServer() == 1 and kajiType ~=nil and kajiType ~=0 then
				szInfo = "#{YBBT_081031_4}".. szMoneyPosTax .."#{YBBT_081031_5}".. tostring(nTradeTax) .."#{BTXZ_211111_05}";  --卡级服
			else
				szInfo = "#{YBBT_081031_4}".. szMoneyPosTax .."#{YBBT_081031_5}".. tostring(nTradeTax) .."#{JJKHD_120808_13}";  --珍兽进阶
			end
			MessageBox_Self_Text:SetText(szInfo);
		end

	elseif(g_FrameInfo == FrameInfoList.DISCARD_ITEM_FRAME) then
		--通知解除锁定
		MessageBox_Self_DragTitle:SetText("#gFF0FA0销毁物品");
		local szStr = "你真的要销毁".. argDISCARD_ITEM_FRAME0 .."?"
		MessageBox_Self_Text:SetText(szStr);
	elseif(g_FrameInfo == FrameInfoList.DISCARD_QUAL8ITEM_FRAME) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0销毁物品");
		MessageBox_Self_Text:SetText(ScriptGlobal_Format("#{BXZBQR_210623_02}",g_msgFrameVar[1]))

	elseif(g_FrameInfo == FrameInfoList.CANNT_DISCARD_ITEM) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0销毁物品");
		local szStr = argCANNT_DISCARD_ITEM0.."是任务物品，不能销毁";
		MessageBox_Self_Text:SetText(szStr);

	elseif(g_FrameInfo == FrameInfoList.LOCK_ITEM_CONFIRM_FRAME) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0加锁");
		local szStr = "".."#cff0000注意！#r#Y为了保护您的财产安全，一旦物品或珍兽成功被加锁，再次解锁则需要等待#G3天#Y，您确定要继续加锁么？";
		--MessageBox_Self_Text:SetText(g_szLockItem_Info);

	elseif(g_FrameInfo == FrameInfoList.FRAME_AFFIRM_SHOW) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0放弃任务");
		local szStr = "#cFFF263你真的要放弃#R任务:"..argFRAME_AFFIRM_SHOW0.."#cFFF263吗？";
		if (Quest_Number == 998267) or (Quest_Number == 998268) then
			szStr = "#{PHRW_220905_128}"
		elseif Quest_Number >= 336121 and Quest_Number <= 336123 then
			szStr = "#{JYTP_250731_32}"
		elseif Quest_Number == 336124 then
			szStr = "#{JYTP_250731_48}"
		elseif Quest_Number == 336125 then
			szStr = "#{JYTP_250731_59}"
		elseif Quest_Number == 336126 then
			szStr = "#{JYTP_250731_70}"
		end		
		MessageBox_Self_Text:SetText(szStr);

	elseif(g_FrameInfo == FrameInfoList.GUILD_CREATE_CONFIRM) then
		-- 帮会成立需玩家确认
		MessageBox_Self_DragTitle:SetText("#gFF0FA0帮会成立");
		local szStr = "你确认创建" .. argCREATE_CONFIRM0 .. "帮会吗？";
		MessageBox_Self_Text:SetText(szStr);
	elseif(g_FrameInfo == FrameInfoList.GUILD_DESTORY_CONFIRM) then
	  MessageBox_Self_DragTitle:SetText("#gFF0FA0帮会解散");
		local szStr = "你确认删除" .. argDESTORY_CONFIRM0 .. "帮会吗？";
		MessageBox_Self_Text:SetText(szStr);
	elseif(g_FrameInfo == FrameInfoList.GUILD_DIS_FIRSTMAN) then
	  MessageBox_Self_DragTitle:SetText("#gFF0FA0#{BHCR_xml_XX(04)}");
		local szStr = "你确定要撤销第一继承人吗?";
		MessageBox_Self_Text:SetText(szStr);
	elseif(g_FrameInfo == FrameInfoList.GUILD_QUIT_CONFIRM) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0帮会退出");
		local szStr = "你确认退出" .. argQUIT_CONFIRM0 .. "帮会吗？";
		MessageBox_Self_Text:SetText(szStr);
	elseif(g_FrameInfo == FrameInfoList.GUILD_LEAGUE_QUIT_CONFIRM) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0同盟退出");
		local szStr = "你确认退出" .. argQUIT_LEAGUE_CONFIRM0 .. "同盟吗？";
		MessageBox_Self_Text:SetText(szStr);
	elseif(g_FrameInfo == FrameInfoList.GUILD_LEAGUE_CREATE_CONFIRM) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0同盟创建");
		local szStr = "#{TM_20080331_09}#{_EXCHG1000000}#{TM_20080331_02}";
		MessageBox_Self_Text:SetText(szStr);
		if IsInTServer() == 1 then
			MessageBox_Self_Text:SetText("#{TWTM_210506_42}")
		end
	elseif(g_FrameInfo == FrameInfoList.NET_CLOSE_MESSAGE) then
		MessageBox_Self_Text:SetText(argNET_CLOSE0);
	elseif(g_FrameInfo == FrameInfoList.PET_FREE_CONFIRM) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0珍兽放生");
		local petname = Pet:GetPetList_Appoint(Pet_Number) ;
		local strname, pettype = Pet:GetName(Pet_Number);
		local strShowName="["..petname.."]("..pettype..")"
		local szStr = ScriptGlobal_Format( "#{JJKHD_120808_57}", strShowName)
		MessageBox_Self_Text:SetText(szStr);

	elseif(g_FrameInfo == FrameInfoList.PS_RENAME_MESSAGE)  then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0修改店名");
		--玩家商店更名需要的金钱数字
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_nData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "修改店名需要支付牌匾金字费2".."#-02".. "×商业指数，当前的商业指数为".. PlayerShop:GetCommercialFactor().."需要支付"..szMoney.."，你确定要修改吗？"
		MessageBox_Self_Text:SetText(szInfo);

		this:Show()

	elseif(g_FrameInfo == FrameInfoList.PS_READ_MESSAGE)    then
		--玩家商店更更改商店说明需要的金钱数字
		MessageBox_Self_DragTitle:SetText("#gFF0FA0修改店铺描述");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_nData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "修改店描述需要支付笔墨费".."50#-03".. "×商业指数，当前的商业指数为".. PlayerShop:GetCommercialFactor().."需要支付"..szMoney.."，你确定要修改吗？"
		MessageBox_Self_Text:SetText(szInfo);

		this:Show()

	elseif(g_FrameInfo == FrameInfoList.PS_ADD_BASE_MONEY)    then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0充入本金");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_nData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_nData1);

		local szMoney1 = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney1 = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney1 = szMoney1 .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney1 = szMoney1 .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "你将充入" .. szMoney .. "，系统还将收取你3%的投资税，你将需要额外支付" .. szMoney1 .. "，你确定要充入吗？";

		MessageBox_Self_Text:SetText(szInfo);

	elseif(g_FrameInfo == FrameInfoList.PS_ADD_GAIN_MONEY)    then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0充入盈利金");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_nData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_nData1);

		local szMoney1 = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney1 = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney1 = szMoney1 .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney1 = szMoney1 .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "你将充入" .. szMoney .. "，系统还将收取你3%的投资税，你将需要额外支付" .. szMoney1 .. "，你确定要充入吗？";

		MessageBox_Self_Text:SetText(szInfo);



	elseif(g_FrameInfo == FrameInfoList.PS_DEC_GAIN_MONEY)    then

	elseif(g_FrameInfo == FrameInfoList.SERVER_CONTROL)    then
		---Server_Script_Function_Set[1] = Get_XParam_STR(0)
		
		if Get_XParam_STR(0) ~= "" then
			Server_Script_Function_Set[1] = Get_XParam_STR(0)
		else
			Server_Script_Function_Set[1] = nil
		end		
		
		Server_Script_ID = Get_XParam_INT(0);
		Server_Return_1 = Get_XParam_INT(1);
		Server_Return_2 = Get_XParam_INT(2);

		MessageBox_Self_Text:SetText(Get_XParam_STR(1));

		if Get_XParam_STR(2) ~= "" then
			Server_Script_Function_Set[2] = Get_XParam_STR(2)
		else
			Server_Script_Function_Set[2] = nil
		end

		if Server_Script_ID == 890983 then
			MessageBox_Self_DragTitle:SetText("#{JSXL_140821_58}")
		end

	elseif g_FrameInfo == FrameInfoList.SERVER_CONTROL_EXT then

		--设置服务器传过来的字符串参数
		Server_Script_Function_Set[1] = Get_XParam_STR(0)
		Server_Script_Function_Set[2] = nil
		MessageBox_Self_Text:SetText(Get_XParam_STR(1))

		--设置服务器传过来的整形参数，这些参数会被传回服务器
		Server_Script_ID = Get_XParam_INT(0)
		local count = Get_XParam_INT_Count()
		Server_Return_Params[0]=count
		for i=1, count do
			Server_Return_Params[i] = Get_XParam_INT(i)
		end

	elseif(g_FrameInfo == FrameInfoList.PS_ADD_STALL)   then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0扩张柜台");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_nData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "扩张柜台需要支付30#-02×商业指数×2×103%，当前的商业指数为".. PlayerShop:GetCommercialFactor() .."，需要支付" .. szMoney .. "，你确定要扩张吗？"

		MessageBox_Self_Text:SetText(szInfo);

	elseif(g_FrameInfo == FrameInfoList.PS_DEL_STALL)   then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0缩减柜台");
		MessageBox_Self_Text:SetText("#{SJGT_090825_01}");

	elseif(g_FrameInfo == FrameInfoList.PS_INFO_PANCHU)  then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0盘出店铺");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_szData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "盘出店铺需要支付15#-02×商业指数，当前的商业指数为".. PlayerShop:GetCommercialFactor() .."，需要支付" .. szMoney .. "，你确定要盘出店铺吗？"
		MessageBox_Self_Text:SetText(szInfo);

	elseif(g_FrameInfo == FrameInfoList.PS_INFO_PANCHU_YB)  then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0盘出店铺");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_szData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "盘出店铺需要支付15#-02×商业指数，当前的商业指数为".. PlayerShop:GetCommercialFactor() .."，需要支付" .. szMoney .. "，你确定要盘出店铺吗？"
		MessageBox_Self_Text:SetText(szInfo);

	elseif(g_FrameInfo == FrameInfoList.PS_INFO_PANRU)  then   --盘入

		MessageBox_Self_DragTitle:SetText("#gFF0FA0盘入店铺");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_szData);

		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "取消盘出柜台需要支付5#-02×商业指数，当前的商业指数为".. PlayerShop:GetCommercialFactor() .."，需要支付" .. szMoney .. "，你确定要盘入店铺吗？"

		MessageBox_Self_Text:SetText(szInfo);

	elseif( g_FrameInfo == FrameInfoList.PS_INFO_MODIFY_TYPE ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0修改店铺类型");
		local nGoldCoin;
		local nSilverCoin;
		local nCopperCoin;

		nGoldCoin, nSilverCoin, nCopperCoin = Bank:TransformCoin(g_szData);
		local szMoney = "";
		if(nGoldCoin ~= 0)   then
		 	szMoney = tostring(nGoldCoin) .. "#-02";
		end
		if(nSilverCoin ~= 0)   then
		 	szMoney = szMoney .. tostring(nSilverCoin) .. "#-03";
		end
		if(nCopperCoin ~= 0)   then
			szMoney = szMoney .. tostring(nCopperCoin) .. "#-04";
		end

		local szInfo = "修改店类型需要支付搬运费：5#-02 ×商业指数，当前的商业指数为".. PlayerShop:GetCommercialFactor() .."，需要支付" .. szMoney .. "，你确定要修改吗？"

		MessageBox_Self_Text:SetText(szInfo);
	elseif( g_FrameInfo == FrameInfoList.DELETE_FRIEND_MESSAGE ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0删除确认");
		local szInfo;
		local relationtype = DataPool:GetFriend(g_currentList,g_currentIndex, "RELATION_TYPE" )
		if relationtype == 7 then
			szInfo = "#cFFF263你确定要删除".."#R"..DataPool:GetFriend(g_currentList,g_currentIndex, "NAME"  ) .."#cFFF263".."吗？删除后将不能与对方进行任何师徒相关的活动。";
		elseif relationtype == 10 then
			szInfo = "#{CDXT_110503_45}"
		else
			szInfo = "#cFFF263你确定要删除".."#R"..DataPool:GetFriend(g_currentList,g_currentIndex, "NAME"  ) .."#cFFF263".."吗？";
		end
		MessageBox_Self_Text:SetText(szInfo);
	elseif( g_FrameInfo == FrameInfoList.CITY_CONFIRM ) then
		MessageBox_Self_City_UpdateFrame();
	elseif( g_FrameInfo == FrameInfoList.PET_SYNC_CONFIRM ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0珍兽合成");
		local msg = "你确定将这两只珍兽合成为一只吗?";
		MessageBox_Self_Text:SetText(msg);
	elseif( g_FrameInfo == FrameInfoList.CONFIRM_USE_SDCZ ) then
		MessageBox_Self_DragTitle:SetText("#{XZXQ_110921_39}");
		local nGainItemID = MessageBox_GetGainItemIDSDCZ(g_SDCZ_ItemTableIdx)
		if nGainItemID == nil then
			return
		else
			if g_SDCZ_HaveQuestItem == 1 then
				local strText = ScriptGlobal_Format( "#{XZXQ_110921_19}", "#{_ITEM"..g_SDCZ_ItemTableIdx.."}", "#{_ITEM"..nGainItemID.."}" )
				MessageBox_Self_Text:SetText(strText);
			else
				local strText = ScriptGlobal_Format( "#{XZXQ_110921_17}", "#{_ITEM"..g_SDCZ_ItemTableIdx.."}" )
				MessageBox_Self_Text:SetText(strText);
			end
		end
	elseif( g_FrameInfo == FrameInfoList.EXCHANGE_BANGGONG ) then
		MessageBox_Self_DragTitle:SetText("#gFF0FA0帮贡牌兑换");
	elseif( g_FrameInfo == FrameInfoList.PUT_GUILDMONEY ) then
		MessageBox_Self_DragTitle:SetText("#{BPZJ_0801014_020}");
	elseif( g_FrameInfo == FrameInfoList.CHANGE_NAME_RETOK ) then
		MessageBox_Self_DragTitle:SetText("#{GMT_20100811_3}");
		local changenameMsg = string.format("#{GMT_20100811_29}%s#{GMT_20100811_30}",g_newName)
		MessageBox_Self_Text:SetText(changenameMsg);
	elseif( g_FrameInfo == FrameInfoList.STALYEXP_CONFIRM ) then
		MessageBox_Self_DragTitle:SetText("");
		local TodayExp = tostring(g_ShituRelation[1])
		local ExpLimit = tostring(g_ShituRelation[2])
		local TodayActPoint = tostring(g_ShituRelation[3])
		local AlyHYLimit = tostring(g_ShituRelation[4])
		local AlyExpMsg

		local str1 = string.format("#{XST_110831_110}".."%s/%s",TodayExp,ExpLimit)
		local str2 = string.format("#{XST_110831_111}".."%s/%s",TodayActPoint,AlyHYLimit)
		if tonumber(TodayActPoint) >= tonumber(AlyHYLimit) then
			AlyExpMsg = str1.."#r"..str2.."#r".."#{XST_110831_113}"
		else
			AlyExpMsg = str1.."#r"..str2.."#r".."#{XST_110831_112}"
		end
		MessageBox_Self_Text:SetText(AlyExpMsg);
	end

	local nRet = MessageBox_Self_UpdateFrameEx();
	MessageBox_Self_UpdateRect();
	if nRet == 1 then
		this:Show();
	end
end

--===============================================
-- 点击确定（IDOK）
--===============================================
function MessageBox_Self_OK_Clicked_Ex()
	if g_FrameInfo == FrameInfoList.DART_ADJUST then
		if IsWindowShow("AnqiShuxing") or IsWindowShow("AnqiShuxingNEW") then
			MessageBox_Self_AdjustDart()
			Dart_Data[3] = 0
		end
		this:Hide()
		return
	end

	if(g_FrameInfo == FrameInfoList.MAOHUABI_BUY_CONFIRMS) then --MaoHuaBi 购买确定

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DuiHuanConfirm")
			Set_XSCRIPT_ScriptID(888447)
			Set_XSCRIPT_Parameter(0, Dart_Data[1])
			Set_XSCRIPT_Parameter(1, Dart_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

	if( g_FrameInfo == FrameInfoList.FREEFORALL ) then --同意开启个人混战

        Player:ChangePVPMode( 1 );
    end
    if( g_FrameInfo == FrameInfoList.FREEFORTEAM ) then --同意开启队伍混战

        Player:ChangePVPMode( 3 );
    end
    if( g_FrameInfo == FrameInfoList.FREEFORGUILD ) then  --同意开启帮派混战
		--2014Q1大世界帮会功能改造,"帮会同盟混战"模式只有服务器设置在K服保留帮会同盟信息时才能在K服启动
		if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
			this:Hide()
			return
		end
        Player:ChangePVPMode( 4 );
    end
    if( g_FrameInfo == FrameInfoList.FREEFORRAID ) then  --同意开启团队混战
        Player:ChangePVPMode( 5 );
    end
    if( g_FrameInfo == FrameInfoList.MAKESUREPVPCHALLENGE ) then  --确认宣战

        Player:PVP_Challenge( 2 );     --2为宣战确认对话框确认
    end
    if( g_FrameInfo == FrameInfoList.FREE_FOR_CLAN ) then  --- 同意开启势力混战

        Player:ChangePVPMode( 6 );
    end
	if( g_FrameInfo == FrameInfoList.FREE_FOR_KGUILD ) then -- 同意开启K服的"帮会模式"
		--2014Q1大世界帮会功能改造,"帮会模式"只能在K服且服务器设置在K服不保留原服"帮会同盟"信息时才能开启
		if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
			Player:ChangePVPMode( 7 );
		else
			this:Hide();
			return
		end
	end



    --------------安全时间二次确认框--------------
    if(g_FrameInfo == FrameInfoList.CHANGEPROTECTTIME)then
	    if(g_ChangeTiemArg1 ~= nil)then
			--第二次判断
			local iTime = math.floor( g_ChangeTiemArg1 / 1000 )
			local Min = math.floor( iTime / 60 )
			local dblefttime =DataPool:GetLeftProtectTime();
			-- 判断是否为安全时间内
			if(tonumber(dblefttime)>0) then
				PushDebugMessage("安全时间内不允许重设安全时间！")
				return
			end
			--判断是否为空J
			str = tostring(Min);
			ret = string.len(str)
			if(ret <= 0) then
				PushDebugMessage("安全时间不能为空，请重新设置")
  				return
			end
			--判断是否为纯数字
    		if( Min~=nil and tonumber(Min)==nil ) then
 				PushDebugMessage("安全时间分钟数只能为两位数字")
        		return
    		end
    		--输入的数字是否在规定范围内
    		if(Min~=nil and tonumber(Min)~=nil) then
				if(tonumber(Min)>60) then
					PushDebugMessage("您输入的分钟数不能大于60分钟，请重新输入。")
					return
				elseif (tonumber(Min)<1) then
			        PushDebugMessage("安全时间最少为1分钟，请重新输入。")
					return
				end
			end
				SendSetProtectTimeMsg(g_ChangeTiemArg1);
				g_ChangeTiemArg1 =nil;
		end
    end
    --------------------------------------------------------
    if(g_FrameInfo == FrameInfoList.ATHORSECFRAME)then
				SetAuthorizedSafeFlag(1);
    end
    if(g_FrameInfo == FrameInfoList.ONCE_ALL_LOCK)then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnLockAllObj");
			Set_XSCRIPT_ScriptID(890643);
			Set_XSCRIPT_Parameter(0,890643);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
    end
    if( PVPFLAG.ACCEPTDUEL == g_FrameInfo ) then
        DuelAccept( tostring( PVPFLAG.DuelName ),tostring( PVPFLAG.DuelGUID ), 1 )
    end


	if( g_FrameInfo == FrameInfoList.SAVE_STALL_INFO ) then
		StallSale:CloseStall("ok");
	-- add by zchw
		StallSale:CloseStallMessage();
	elseif g_FrameInfo == FrameInfoList.CONFIRM_REMOVE_STALL then
		StallSale:CloseStall("ask");
	-- zchw for pet procreate
	elseif g_FrameInfo == FrameInfoList.PET_PROCREATE_PROMPT then
		PushEvent(462, 0); --PETPROCREATE_KEY_STATE
		Pet:ConfirmPetProcreate(1);

	elseif  g_FrameInfo == FrameInfoList.QUIT_GAME  then
		EnterQuitWait(0);
		--QuitApplication("quit");
	elseif(g_FrameInfo == FrameInfoList.PS_DEL_STALL)    then
		PlayerShop:ChangeShopNum("del_ok");
	elseif(g_FrameInfo == FrameInfoList.PS_INFO_PANCHU)    then
		PlayerShop:Transfer("apply", "sale", g_nData, 0);--0为金币盘出
	elseif(g_FrameInfo == FrameInfoList.PS_INFO_PANCHU_YB)    then
		PlayerShop:Transfer("apply", "sale", g_nData, 1);--1为元宝盘出
	elseif(g_FrameInfo == FrameInfoList.PS_INFO_PANRU)    then
		PlayerShop:Transfer("apply", "back", g_nData);
	elseif( g_FrameInfo == FrameInfoList.PS_INFO_MODIFY_TYPE ) then
		PlayerShop:ModifySubType("ps_type_ok", tonumber(g_nData));
	elseif( g_FrameInfo == FrameInfoList.DELETE_FRIEND_MESSAGE ) then
		DataPool:DelFriend( g_currentList, g_currentIndex );
	elseif( g_FrameInfo == FrameInfoList.CITY_CONFIRM ) then
		MessageBox_Self_City_OK_Clicked();
	elseif( g_FrameInfo == FrameInfoList.PET_SYNC_CONFIRM ) then
		MessageBox_Self_PetSyn_OK_Clicked();
	elseif( g_FrameInfo == FrameInfoList.CONFIRM_USE_SDCZ ) then
		MessageBox_Self_SDCZ_OK_Clicked();
	elseif( g_FrameInfo == FrameInfoList.STALYEXP_CONFIRM ) then
		MessageBox_Self_STALYEXP_OK_Clicked();
	elseif(g_FrameInfo ==FrameInfoList.GUILD_DEMIS_CONFIRM) then
		Guild:DemisGuildOK();
	elseif(g_FrameInfo ==FrameInfoList.GUILD_LEAGUE_QUIT_CONFIRM) then
		GuildLeague:Quit();
	elseif(g_FrameInfo ==FrameInfoList.GUILD_LEAGUE_CREATE_CONFIRM) then
		local r=GuildLeague:Create(argCREATE_LEAGUE_CONFIRM0,argCREATE_LEAGUE_CONFIRM1)
		if r==-1 then
			PushDebugMessage("#{TM_20080311_05}")
		elseif r==-2 then
			PushDebugMessage("#{TM_20080311_07}")
		end
	elseif(g_FrameInfo == FrameInfoList.YUANBAO_BUY_ITEM) then
		NpcShop:BulkBuyItem(g_CityData[1],1, g_CityData[4]);
	elseif g_FrameInfo == FrameInfoList.T3SHOP_BUY_ITEM_CONFIRM then
		NpcShop:LuaFnT3ShopBuyItem(g_CityData[2], 1)
	elseif (g_FrameInfo == FrameInfoList.FITTINGROOM_BUY_ITEM_CONFIRM ) then
		NpcShop:BuyItemFromFittingRoom(g_CityData[1], 1)

	elseif (g_FrameInfo == FrameInfoList.JIYUANSHOP_BUY_ITEM_CONFIRM ) then
		NpcShop:BuyItemFromJiYuanShop(g_CityData[1], 1)
	elseif(g_FrameInfo == FrameInfoList.COMMISION_BUY) then
		CommisionShop:OnBuyConfrimed();
	elseif g_FrameInfo == FrameInfoList.IMDressBuyToOther then
		--if (IsWindowShow("XuanPayed")) then
		--		CloseWindow("XuanPayed", true);
		--end

		local Friendguid = IMDressBuyToOtherData[2]
		if Friendguid == "" then
			PushDebugMessage("#{ZSGN_101129_24}");
			return
		end

		local Friendgroup, Friendindex = DataPool:GetFriendByGUID(Friendguid);
		if Friendgroup == 0 or Friendindex == -1 then
			PushDebugMessage("#{ZSGN_101129_24}");
			return
		end

		--如果不是好友
		local friendRelationType = DataPool:GetFriend( Friendgroup, Friendindex, "RELATION_TYPE"  )
		if friendRelationType == 0  or friendRelationType == 4  or friendRelationType == 5 or
			 friendRelationType == 6  or friendRelationType == 9 then
			PushDebugMessage("#{ZSGN_101129_24}");
			return
		end

		PushEvent("OPEN_IMDRESS_PAYED", IMDressBuyToOtherData[1], IMDressBuyToOtherData[2])
	end
	if( FrameInfoList.Player_Give_Rose == g_FrameInfo or FrameInfoList.PLAYER_GIVE_BLUEROSE == g_FrameInfo) then
		Player:UseRose(tonumber(g_RoseArg1),tonumber(g_RoseArg2),tonumber(g_RoseArg3),tonumber(g_RoseArg4))
	end

	if( FrameInfoList.NEED_USE_CONFIRM_ITEM == g_FrameInfo ) then
		Player:UseItem(
		tonumber(NeedUseConfirmItemData[1]), --目标objID
		tonumber(NeedUseConfirmItemData[2]), --目标x坐标
		tonumber(NeedUseConfirmItemData[3]), --目标y坐标
		tonumber(NeedUseConfirmItemData[4]), --物品包内索引
		tonumber(NeedUseConfirmItemData[5])  --物品表内索引
		);
	end

	if(g_FrameInfo == FrameInfoList.RECYCLE_DEL_ITEM) then
		if(Recycle_Type<0 or Recycle_CurSelectItem<0) then
			return
		end
		PlayerShop:SendCancelRecItemMsg(Recycle_Type,Recycle_CurSelectItem);
		Recycle_Type =-1;
		Recycle_CurSelectItem = -1;
		PushDebugMessage("#{SGBC_101026_02}")
	end

	if(g_FrameInfo == FrameInfoList.OPEN_IS_SELL_TO_RECSHOP) then
		if(Recycle_Bag_idx<0 or Recycle_Shop_idx<0) then
			return
		end
		PlayerShop:SendSellItem2RecycleShopMsg(Recycle_Bag_idx,Recycle_Shop_idx);
		Recycle_Bag_idx =-1;
		Recycle_Shop_idx = -1;
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_STENGTH) then
		if(Stength_Equip_Idx<0 or Stength_Item_Idx<0) then
			return
		end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("FinishEnhance");
			Set_XSCRIPT_ScriptID(809262);
			Set_XSCRIPT_Parameter(0,tonumber(Stength_Equip_Idx));
			Set_XSCRIPT_Parameter(1,tonumber(Stength_Item_Idx));
			Set_XSCRIPT_Parameter(2,-1);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
		Stength_Equip_Idx =-1;
		Stength_Item_Idx = -1;
	end
	if(g_FrameInfo == FrameInfoList.EXCHANGE_BANGGONG) then
		if(BangGong_Value < 0) then
			return
		end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("BanggongExchange");
			Set_XSCRIPT_ScriptID(805009);
			Set_XSCRIPT_Parameter(0,BangGong_Value);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		BangGong_Value =-1;
	end
	if(g_FrameInfo == FrameInfoList.PUT_GUILDMONEY) then
		if(GuildMoney_Value < 0) then
			return
		end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("PutGuildMoney");
			Set_XSCRIPT_ScriptID(805012);
			Set_XSCRIPT_Parameter(0,GuildMoney_Value);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		GuildMoney_Value =-1;
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_RE_IDENTIFY) then
		if(RID_Equip_Idx<0) then
			return
		end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("FinishReAdjust");
			Set_XSCRIPT_ScriptID(809261);
			Set_XSCRIPT_Parameter(0,tonumber(RID_Equip_Idx));
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		RID_Equip_Idx =-1;
	end
	if(g_FrameInfo == FrameInfoList.KICK_MEMBER_MSGBOX) then
		if(Member_Idx < 0) then
			return
		end
		Guild:SureKickGuild(tonumber(Member_Idx));
		Member_Idx =-1;
		Member_Name = "";
	end

	if (g_FrameInfo == FrameInfoList.TLZ_CONFIRM_SETPOS or g_FrameInfo == FrameInfoList.DLZ_CONFIRM_SETPOS or g_FrameInfo == FrameInfoList.KWLZ_CONFIRM_SETPOS) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetPosition");
			Set_XSCRIPT_ScriptID(330001);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

	if( g_FrameInfo == FrameInfoList.GONGLIDAN_USE_CONFIRM ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnSetPower");
			Set_XSCRIPT_ScriptID(335815);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end

	if( g_FrameInfo == FrameInfoList.CONFIRM_GAOBAILIHE ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientActivateOnce");
			Set_XSCRIPT_ScriptID(892421);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end
	--2015情人节排行榜礼盒使用二次确认
	--if( g_FrameInfo == FrameInfoList.ROSEGIFTBOX_USE_CONFIRM ) then
		--Clear_XSCRIPT();
			--Set_XSCRIPT_Function_Name("ClientActivateOnce");
			--Set_XSCRIPT_ScriptID(891050);
			--Set_XSCRIPT_ParamCount(0);
		--Send_XSCRIPT();
	--end
		--2015圣诞尊享礼盒使用二次确认
	if( g_FrameInfo == FrameInfoList.CHRISTMAS_ZUNXIANG_USE_CONFIRM ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientOnActivateOnce");
			Set_XSCRIPT_ScriptID(891720);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end

	--珍兽套装拆解确认
	--if( g_FrameInfo == FrameInfoList.PET_EQUIPSUITDEPART_CONFIRM ) then
		--PetEquipSuitDepart:ConfirmDepart()
	--end

	--2015情人节排行榜兑换二次确认
	if( g_FrameInfo == FrameInfoList.ROSERANK_EXCHANGE_CONFIRM ) then
		if g_msgFrameVar[1] == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "Qingrenjie_Exchange" )
				Set_XSCRIPT_ScriptID( 891056 )
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[2])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_msgFrameVar[1] == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "Chiqingyu_Exchange" )
				Set_XSCRIPT_ScriptID( 891056 )
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[2])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_msgFrameVar[1] == 3 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "Qingyuanjie_Exchange" )
				Set_XSCRIPT_ScriptID( 891056 )
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[2])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
	end

	--2015七夕情人节排行榜兑换二次确认
	if( g_FrameInfo == FrameInfoList.QIXIRANK_EXCHANGE_CONFIRM ) then
		if g_msgFrameVar[1] == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "Qingrenjie_Exchange" )
				Set_XSCRIPT_ScriptID( 891396 )
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[2])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_msgFrameVar[1] == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "Chiqingyu_Exchange" )
				Set_XSCRIPT_ScriptID( 891396 )
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[2])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_msgFrameVar[1] == 3 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "XiangSiJie_Exchange" )
				Set_XSCRIPT_ScriptID( 891396 )
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[2])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
	end
	
	if( g_FrameInfo == FrameInfoList.OPEN_PAID_WORLD_CONFIRM ) then
		Talk : SendPaidWorldMessage(g_msgFrameVar[1])
	end

	--删除收费表情
	if (g_FrameInfo == FrameInfoList.UNINSTALL_CHAT_FACE) then
		DataPool : UnInstallRMBFace(g_currentIndex  , 1)
		g_currentIndex = 0
		return
	end

	--删除收费休闲动作包
	if (g_FrameInfo == FrameInfoList.UNINSTALL_CHAT_ACTION) then
		DataPool : UnInstall_RMB_ChatAction(g_currentIndex , 1)
		g_currentIndex = 0
		return
	end

	if (g_FrameInfo == FrameInfoList.QUIT_CHATGROUP_CONFIRM) then
		DataPool:QuitGroup(tonumber(g_currentIndex) ,1)
		g_currentIndex = 0
		return
	end

	if (g_FrameInfo == FrameInfoList.DISMISS_CHATGROUP_CONFIRM) then
		DataPool:DismissGroup(tonumber(g_currentIndex) ,1)
		g_currentIndex = 0
		return
	end

	if (g_FrameInfo == FrameInfoList.CHANGE_NAME_RETOK ) then
		EnterQuitWait(1);
		return
	end

	if g_FrameInfo == FrameInfoList.EXTERIOR_RIDE_EQUIP_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnConfirm")
			Set_XSCRIPT_ScriptID(999801)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
	end
	
	if g_FrameInfo == FrameInfoList.EXTERIOR_RIDE_ITEM_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnConfirm")
			Set_XSCRIPT_ScriptID(999901)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
	end
	
	if g_FrameInfo == FrameInfoList.EXTERIOR_DECOWEAPON_EQUIP_CONFIRM then
		Exterior:LuaFnSetShowShowWeaponChatMoodTips(true)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnConfirm")
			Set_XSCRIPT_ScriptID(999802)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
	end
	
	if g_FrameInfo == FrameInfoList.EXTERIOR_DECOWEAPON_ITEM_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnConfirm")
			Set_XSCRIPT_ScriptID(999902)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
	end

	if g_FrameInfo == FrameInfoList.EXTERIOR_TOY_ITEM_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnConfirm")
			Set_XSCRIPT_ScriptID(999905)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
	end

	--[[
	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_SETPOS) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetPosition");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end

	if (g_FrameInfo == FrameInfoList.DJQS_CONFIRM_SETPOS) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetPosition");
			Set_XSCRIPT_ScriptID(330060);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end


	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_CHUANSONG) then

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetUISelIdx");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();

		PlayerPackage:UseItem(Client_ItemIndex)	--遁甲天书的默认使用逻辑为传送....

	end

	if (g_FrameInfo == FrameInfoList.DJQS_CONFIRM_CHUANSONG) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetUISelIdx");
			Set_XSCRIPT_ScriptID(330060);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		PlayerPackage:UseItem(Client_ItemIndex)	--遁甲奇书的默认使用逻辑为传送....
	end

	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_BUCHONG) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AddFuZhou");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

	if (g_FrameInfo == FrameInfoList.DJQS_CONFIRM_BUCHONG) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AddFuZhou");
			Set_XSCRIPT_ScriptID(330060);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

	if (g_FrameInfo == FrameInfoList.ZBS_ETNER_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnPlyJoin");
			Set_XSCRIPT_ScriptID(889416);
			Set_XSCRIPT_Parameter(0, g_ZBS_NPCID)
			Set_XSCRIPT_Parameter(1, g_ZBS_CurRnd)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end
	--]]


	if ( g_FrameInfo == FrameInfoList.CONFIRM_LEAVE_CORPS_COPYSCENE ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("TransferToRestRoom")
			Set_XSCRIPT_ScriptID(891906)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
	end
	if ( g_FrameInfo == FrameInfoList.CONFIRM_LEAVE_CORPS_FINAL_SCENE ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("TransferToCity")
			Set_XSCRIPT_ScriptID(891909)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
	end

	--确认开始自动寻路
	if(g_FrameInfo == FrameInfoList.AUTOMOVE_CONFIRM_NOPKVALUE) then
		StartAutoMove()
		this:Hide()
	end


	--确认开始自动寻路
	if(g_FrameInfo == FrameInfoList.AUTOMOVE_CONFIRM_UPPKVALUE) then
		StartAutoMove()
		this:Hide()
	end

		--确认开始自动寻路
	if(g_FrameInfo == FrameInfoList.AUTOMOVE_CONFIRM_FENGMING) then
		StartAutoMove()
		this:Hide()
	end
	if (g_FrameInfo == FrameInfoList.PNEUMA_JUYUAN_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ActivationBtnClk");
			Set_XSCRIPT_ScriptID(889902);
	--		Set_XSCRIPT_Parameter(0,tonumber(nClk));
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
		this:Hide()
	end
	-- if (g_FrameInfo == FrameInfoList.INFANT_CARD_COMPOSE_CONFIRM) then
	-- 	Clear_XSCRIPT();
	-- 	Set_XSCRIPT_Function_Name("CompositeBooks");
	-- 	Set_XSCRIPT_ScriptID(890630);
	-- 	Set_XSCRIPT_Parameter(0,g_msgFrameVar[1]);
	-- 	Set_XSCRIPT_Parameter(1,g_msgFrameVar[2]);
	-- 	Set_XSCRIPT_ParamCount(2);
	-- 	Send_XSCRIPT();
	-- end
	-- if (g_FrameInfo == FrameInfoList.INFANT_CARD_STRENGTH_CONFIRM) then
	-- 	Clear_XSCRIPT();
	-- 	Set_XSCRIPT_Function_Name("StudyBooks");
	-- 	Set_XSCRIPT_ScriptID(890630);
	-- 	Set_XSCRIPT_Parameter(0,g_msgFrameVar[1]);
	-- 	Set_XSCRIPT_ParamCount(1);
	-- 	Send_XSCRIPT();
	-- end
	-- if (g_FrameInfo == FrameInfoList.INFANT_CARD_TRANSFER_CONFIRM) then
	-- 	Clear_XSCRIPT();
	-- 	Set_XSCRIPT_Function_Name("TransYandu");
	-- 	Set_XSCRIPT_ScriptID(890630);
	-- 	Set_XSCRIPT_Parameter(0,g_msgFrameVar[1]);
	-- 	Set_XSCRIPT_Parameter(1,g_msgFrameVar[2]);
	-- 	Set_XSCRIPT_ParamCount(2);
	-- 	Send_XSCRIPT();
	-- end
	if (g_FrameInfo == FrameInfoList.INFANT_HERO_CHOICE_CONFIRM) then
		if g_msgFrameVar[2] == 1 then
			local selfMoney = Player : GetData( "MONEY" ) + Player : GetData( "MONEY_JZ" )
			local moneyCost = 1000000
			if selfMoney < moneyCost then
				PushDebugMessage("#{YXPY_20131118_43}")
				return
			end
		end
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ChoseInfantHeroType");
		Set_XSCRIPT_ScriptID(890630);
		Set_XSCRIPT_Parameter(0,g_msgFrameVar[1]);
		Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

	if (g_FrameInfo == FrameInfoList.INFANT_CARD_EQUIP_CONFIRM) then
		Infant:UseInfantCard(tonumber(g_msgFrameVar[1]))
	elseif (g_FrameInfo == FrameInfoList.GUILDSHOP_ITEM_SURE) then
		City:DoGuildShopBuy(tonumber(g_msgFrameVar[1]),1)
	end

	if (g_FrameInfo == FrameInfoList.BUDGETPLANINFO_DOWNPAY) then
		PushEvent( "BUDGETPLANINFO_DOWNPAYOKORCANCEL", 1, tonumber(g_msgFrameVar[1]))
	end

	if (g_FrameInfo == FrameInfoList.BUDGETPLANINFO_REPAY) then
		PushEvent( "BUDGETPLANINFO_REPAYOKORCANCEL", 1, tonumber(g_msgFrameVar[1]))
	end

	--if(g_FrameInfo == FrameInfoList.SHENGMINGXIANHE_CONFIRM) then
	--	local nType = g_msgFrameVar[1];
	--	if nType < 0 or  nType > 1 then
	--		return
	--	end
	--	Clear_XSCRIPT()
	--		Set_XSCRIPT_Function_Name( "ClientPrize" )
	--		Set_XSCRIPT_ScriptID( 890084 )
	--		Set_XSCRIPT_Parameter(0,3);
	--		Set_XSCRIPT_Parameter(1,nType);
	--		Set_XSCRIPT_ParamCount(2)
	--	Send_XSCRIPT()
	--end

	if (g_FrameInfo == FrameInfoList.DISMISS_ZHANTUAN_CONFIRM) then
		ZhanTuanInterface:ModifyZhanTuan(2,"","",0);
		g_currentIndex = 0
		return
	end

	if( g_FrameInfo == FrameInfoList.HUITIANDAN_USE_CONFIRM ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnSetPower_HuiTianDan");
			Set_XSCRIPT_ScriptID(891092);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end

	if ( g_FrameInfo == FrameInfoList.CONFIRM_LEAVE_KM_SCENE ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("GotoCity")
			Set_XSCRIPT_ScriptID(050314)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
	end

	if ( g_FrameInfo == FrameInfoList.CONFIRM_LEAVE_CORPS_COPYSCENE_2018 ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("LeaveCopyScene")
			Set_XSCRIPT_ScriptID(892695)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
	end
	
	if ( g_FrameInfo == FrameInfoList.CONFIRM_LEAVE_CORPS_FINALSCENE_2018 ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("TransferToCity")
			Set_XSCRIPT_ScriptID(892698)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
	end

	if ( g_FrameInfo == FrameInfoList.CONFIRM_YUSUI_CONFIRM ) then
		if g_CityData[1] == 0 then --先扣绑定的
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("OnDelBindFirst")
				Set_XSCRIPT_ScriptID(892626)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT();
		elseif g_CityData[1] == 1 then --先扣非绑定的
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("OnDelUNBindFirst")
				Set_XSCRIPT_ScriptID(892626)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT();
		end	
	end

	if ( g_FrameInfo == FrameInfoList.CONFIRM_BWDB_CONFIRM ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("BuyInBWShop")
			Set_XSCRIPT_ScriptID(892899)
			Set_XSCRIPT_Parameter(0,g_CityData[1]);			
			Set_XSCRIPT_Parameter(1,0);					
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end
	if ( g_FrameInfo == FrameInfoList.CONFIRM_BASE_SHANHAIBI_CONFIRM ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnActivateOnce")
			Set_XSCRIPT_ScriptID(888098)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[1]);			
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[2]);					
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end
		
	if g_FrameInfo == FrameInfoList.CONFIRM_DUANWU_ZONGZI_CONFIRM then
		--DUANWU_ZONGZI_CONFIRM
		PushEvent("DUANWU_ZONGZI_CONFIRM")
	end
	if g_FrameInfo == FrameInfoList.WUYIZHUANHUAN_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("WYZHConfirm")
			Set_XSCRIPT_ScriptID(715057)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(2,g_msgFrameVar[3])
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	if g_FrameInfo == FrameInfoList.CONFIRM_CHANGE_NEW_ZIWEI then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AfterConfirm")
			Set_XSCRIPT_ScriptID(510000)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[4])	--targetId
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[2])	--兑换数量
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	end
	
	if g_FrameInfo == FrameInfoList.ZYPX_BULING_ITEM_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetBuLingGift")
			Set_XSCRIPT_ScriptID(888209)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()			
	end

		
	if g_FrameInfo == FrameInfoList.BIANJING_HORSERENT then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("RentHorse")
			Set_XSCRIPT_ScriptID(888253)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()			
	end
		
		
	if g_FrameInfo == FrameInfoList.CONFIRM_RECV_BOUNTYMISSION then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetMission")
			Set_XSCRIPT_ScriptID(506100)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()			
		PushEvent("UI_COMMAND", 5061011, 7)
	end

	if g_FrameInfo == FrameInfoList.RMB_EMO_INSTALL_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("InstallOnConfirm")
			Set_XSCRIPT_ScriptID(890006)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
		
	if g_FrameInfo == FrameInfoList.ZHONGQINGMEIGUI_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_ScriptID(892764)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.ZHONGQINGMEIGUI_NEW_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_ScriptID(g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.QIMIAOEXPDAN_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_ScriptID(g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	if g_FrameInfo == FrameInfoList.CONFIRM_ENTERDIGONG then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("EnterScene")
			Set_XSCRIPT_ScriptID(998487)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[2] )
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[3] )
			Set_XSCRIPT_Parameter(2,g_msgFrameVar[4] )
			Set_XSCRIPT_Parameter(3,0 )
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
		this:Hide()
	end
	if g_FrameInfo == FrameInfoList.CONFIRM_ENTERTIANJICHENG then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("EnterScene")
			Set_XSCRIPT_ScriptID(998569)
			Set_XSCRIPT_Parameter(0,g_msgFrameVar[2] )
			Set_XSCRIPT_Parameter(1,0 )
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
	end
	
	if g_FrameInfo == FrameInfoList.BUY_SUPERASS_FASHION_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyFashionCloth")
			Set_XSCRIPT_ScriptID(777888)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		this:Hide()
	end
	
	if g_FrameInfo == FrameInfoList.CHONGLOU_EFFECT_ACTIVE_CONFIRM then
		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(881101)
			Set_XSCRIPT_Function_Name("CL_EffectActive")
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(2, g_msgFrameVar[3])
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
		this:Hide()
	end

	if g_FrameInfo == FrameInfoList.XIAKE_GUAIWU_ZHAOJILING_CONFIRM then
		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(999652)
			Set_XSCRIPT_Function_Name("UseMonsterToken")
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		this:Hide()
	end



	if g_FrameInfo == FrameInfoList.CONFIRM_BUY_NEWBAOTU_FREE then
		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(510100)
			Set_XSCRIPT_Function_Name("AfterConfirm")
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[3])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()	
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_BUY_ORIBAOTU_FREE then
		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(510100)
			Set_XSCRIPT_Function_Name("AfterConfirm")
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[3])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()		
	end	
	if g_FrameInfo == FrameInfoList.CONFIR_FYPVE_BAG_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DestoryBagItem" )
			Set_XSCRIPT_ScriptID(335927)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()	
	end
	if g_FrameInfo == FrameInfoList.CONFIR_QUNCHUANRUCHANGFU_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "SetUISelIdx" )
			Set_XSCRIPT_ScriptID(900025)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		
		PlayerPackage:UseItem(g_msgFrameVar[1])	--默认使用逻辑为传送..

		this:Hide()	
	end
	
	if g_FrameInfo == FrameInfoList.EXPBALL_USE_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_ScriptID(g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.COMMONGIFT_TITLE_CONFIRM then
		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(998255)
			Set_XSCRIPT_Function_Name("OpenGiftBox")	
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, 1)  --确认过了
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.STEALSKILL_CONFIRM then
		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(999755)
			Set_XSCRIPT_Function_Name("OnStudyTouShiSkill")	 
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(2, g_msgFrameVar[3])
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.RESET_STEALSKILL_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(999755)
			Set_XSCRIPT_Function_Name("OnResetTouShiSkill")	 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.TCITYWAR_GROUP_RAID then
		Guild:InviteBZTXMember(0)
		this:Hide()
	end
	if g_FrameInfo == FrameInfoList.CONFIRM_SHAXINGGIVEUP then
		-- 新杀星放弃二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GiveUpTheBoss" )
			Set_XSCRIPT_ScriptID( 893471)
			Set_XSCRIPT_Parameter( 0 ,g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_FrameInfo == FrameInfoList.CONFIRM_SHAXINGCHANGE then
		-- 新杀星兑换二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CheckChangePoint" )
			Set_XSCRIPT_ScriptID( 893471)
			Set_XSCRIPT_Parameter( 0 ,g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_FrameInfo == FrameInfoList.CONFIRM_WEEKPVEAWARD then
		-- 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetOnlyDaiBiAward" )
			Set_XSCRIPT_ScriptID(331106)
			Set_XSCRIPT_Parameter( 0 ,1)
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.CONFIRM_ROUGEPATACHANGE then
		-- 剑破明王境兑换二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CheckChangePoint" )
			Set_XSCRIPT_ScriptID(998947)
			Set_XSCRIPT_Parameter( 0 ,g_msgFrameVar[1])
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	
end

function MessageBox_OnOKClick()

	if( strMessageData == "EquipBind" ) then -- 绑定
		EquipItem( tonumber( strMessageArgs ),tonumber(strMessageArgs_2) );
	end

	if( strMessageData == "DressProtected" ) then -- 绑定
		EquipItem( tonumber( strMessageArgs ),tonumber(strMessageArgs_2) );
	end
	
	if(strMessageData == "YiGuiDressBind" ) then
	    YiGui:EquipDressWithoutAskBind(tonumber( strMessageArgs ))
	end

	if strMessageData == "InfantYiGuiDressBind" then
	    Infant:SendInfantYiguiDressUp( tonumber( strMessageArgs ), 0 )
	end

	if( strMessageData == "Infant_DressProtected" ) then -- 绑定
		EquipItem( tonumber( strMessageArgs ), tonumber(strMessageArgs_2) );
	end

	if(strMessageData == "YiGuiWeaponBind" ) then
	    YiGui:WeaponDressWithoutAskBind(tonumber( strMessageArgs ))
	end

	if(strMessageData == "YiGuiAllBind" ) then
		local tempnum = tonumber( strMessageArgs )
		local indexDress = math.floor(tempnum/100)
		local indexWeapon = math.floor(math.mod(tempnum,100))
	    YiGui:DressAllWithoutAskBind(indexDress,indexWeapon)
	end

	this:Hide();
end
--===============================================
-- 点击确定（IDOK）
--===============================================
function MessageBox_Self_OK_Clicked()

	if g_FrameInfo == FrameInfoList.STALL_OFFLINE_ERRSTATE then
		EnterQuitWait(tonumber(strMessageArgs))
		this:Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_USE_MIFA then
		UseMiFaAfterSure( tonumber( strMessageArgs ),tonumber(strMessageArgs_2), tonumber(g_table_ItemGuid[1]),tonumber(g_table_ItemGuid[2]) )
		this : Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.SAFEBOX_LOCK_CONFIRM then
		SafeBox("reallock");
		this : Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.SAFEBOX_UNLOCK_CONFIRM then
		SafeBox("realunlock");
		this : Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.CITY_RANAME_CONFIRM then
		Guild : SendCityRnameMsg( g_arg_circ )
		this : Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.CHAR_RANAME_CONFIRM then
		Target : SendCharRnameMsg( g_arg_chrc )
		this : Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.CHANGE_NAME_CONFIRM then
		Target : SendChangeNameMsg( g_arg_chrc )
		this : Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.GEM_COMBINED_CONFIRM then
		LifeAbility : Do_Combine( GemCombinedData[1], GemCombinedData[2],
			GemCombinedData[3], GemCombinedData[4],
			GemCombinedData[5], GemCombinedData[6], 1 )
		this : Hide()
		return
	end

	--if g_FrameInfo == FrameInfoList.CONFIRM_MULTIBUY then
		--PlayerShop:SearchPageMultiBuyItem(1)
		--this : Hide()
		--return
	--end

	if g_FrameInfo == FrameInfoList.ENCHASE_CONFIRM then
		LifeAbility : Do_Enchase( EnchaseData[1], EnchaseData[2],EnchaseData[3], EnchaseData[4])
		this:Hide()
		return
	end

-- add:lby20080527确认4镶嵌ENCHASE_FOUR_CONFIRM
	if g_FrameInfo == FrameInfoList.ENCHASE_FOUR_CONFIRM then
		LifeAbility : Do_Enchase_Four( EnchaseData[1], EnchaseData[2],EnchaseData[3], EnchaseData[4])
		this:Hide()
		return
	end

	-- 宠物学习技能确认：两个手动技能学习
	if g_FrameInfo == FrameInfoList.PET_SKILL_STUDY_CONFIRM then
		Pet:ConfirmPetSkillStudy()
		this:Hide()
		return
	end

--	if g_FrameInfo == FrameInfoList.CARVE_CONFIRM then
--	  Clear_XSCRIPT();
--		Set_XSCRIPT_Function_Name(CarveData[1]);
--		Set_XSCRIPT_ScriptID(CarveData[2]);
--		Set_XSCRIPT_Parameter(0,CarveData[3]);
--		Set_XSCRIPT_Parameter(1,CarveData[4]);
--		Set_XSCRIPT_ParamCount(CarveData[5]);
--	  Send_XSCRIPT();
--		this:Hide()
--		return
--	end


	if(g_FrameInfo == FrameInfoList.STALL_RENT_FRAME) then
		--通知服务器决定开始在这里摆摊
		StallSale:AgreeBeginStall();

	elseif(g_FrameInfo == FrameInfoList.DISCARD_ITEM_FRAME) then
		--通知销毁物品
		local equipQual = DiscardEquipQual() --装备品质 非装备返回0
		local equipStar = 0
		--计算装备的星级 和SuperToolTips里显示装备星星的方法一样
		if equipQual > 100 then
			equipStar = 8
		elseif equipQual > 10 then
			equipStar = math.floor(equipQual / 10)
		else
			equipStar = equipQual
		end
		if equipStar >= 8 then
			MessageBox_Self_ClearVar()
			g_msgFrameVar[1] = equipStar
			g_FrameInfo=FrameInfoList.DISCARD_QUAL8ITEM_FRAME
			MessageBox_Self_UpdateFrame()
			return
		else
			DiscardItem();
		end
	elseif(g_FrameInfo == FrameInfoList.DISCARD_QUAL8ITEM_FRAME) then
		DiscardItem();

	elseif(g_FrameInfo == FrameInfoList.CANNT_DISCARD_ITEM) then
		--任务物品不能销毁
		g_InitiativeClose = 1;
		this:Hide();

	elseif(g_FrameInfo == FrameInfoList.LOCK_ITEM_CONFIRM_FRAME) then
		--通知加锁物品
		LockAfterConfirm();

	elseif(g_FrameInfo == FrameInfoList.FRAME_AFFIRM_SHOW) then
		--放弃任务
		if(Quest_Number > -1) then
			QuestFrameMissionAbnegate(Quest_Number);
		end
		g_InitiativeClose = 1;
		this:Hide();


	elseif(g_FrameInfo == FrameInfoList.GUILD_CREATE_CONFIRM) then
		-- 帮会成立需玩家确认
		Guild:CreateGuildConfirm(1);
		this:Hide();
	elseif(g_FrameInfo == FrameInfoList.GUILD_DESTORY_CONFIRM) then
		-- 帮会成立需玩家确认
		Guild:CreateGuildConfirm(2);
		this:Hide();
	elseif(g_FrameInfo == FrameInfoList.GUILD_DIS_FIRSTMAN) then
		-- 撤销第一继承人确认
		Guild:UnSetFirstMan();
		this:Hide();
	elseif(g_FrameInfo == FrameInfoList.GUILD_QUIT_CONFIRM) then
		-- 帮会成立需玩家确认
		Guild:CreateGuildConfirm(3);
		this:Hide();

	elseif(g_FrameInfo == FrameInfoList.NET_CLOSE_MESSAGE) then
		QuitApplication("quit");
		this:Hide();

	elseif(g_FrameInfo == FrameInfoList.PET_FREE_CONFIRM) then
		Pet : Go_Free(Pet_Number);
		this:Hide();

	elseif(g_FrameInfo == FrameInfoList.PS_RENAME_MESSAGE)  then
		--玩家商店更名需要的金钱数字
		PlayerShop:Modify("name_ok",g_szData);

	elseif(g_FrameInfo == FrameInfoList.PS_READ_MESSAGE)    then
		--玩家商店更更改商店说明需要的金钱数字
		PlayerShop:Modify("ad_ok",g_szData);

	elseif(g_FrameInfo == FrameInfoList.PS_ADD_BASE_MONEY)    then
		PlayerShop:ApplyMoney("immitbase_ok", g_nData);

	elseif(g_FrameInfo == FrameInfoList.PS_ADD_GAIN_MONEY)    then
		PlayerShop:ApplyMoney("immit_ok", g_nData);

	elseif(g_FrameInfo == FrameInfoList.SERVER_CONTROL)    then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(Server_Script_Function_Set[1])
			Set_XSCRIPT_ScriptID(Server_Script_ID);
			Set_XSCRIPT_Parameter(0,Server_Return_1);
			Set_XSCRIPT_Parameter(1,Server_Return_2);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();

	elseif(g_FrameInfo == FrameInfoList.SERVER_CONTROL_EXT)    then
		local count = Server_Return_Params[0]
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(Server_Script_ID)
			Set_XSCRIPT_Function_Name(Server_Script_Function_Set[1])
			Set_XSCRIPT_ParamCount(count)
			for i=1, count do
				Set_XSCRIPT_Parameter(i-1,Server_Return_Params[i])
			end
		Send_XSCRIPT()

	elseif(g_FrameInfo == FrameInfoList.PS_ADD_STALL)    then
		PlayerShop:ChangeShopNum("add_ok");
	end

	if( g_FrameInfo == FrameInfoList.EQUIP_ITEM ) then
		MessageBox_OnOKClick();
		return;
	end

	-- 确认解散队伍			add by WTT	20090212
	if g_FrameInfo == FrameInfoList.DISMISS_TEAM then
		Player:ConfirmDismissTeam()
		this:Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.TRUST_FRIEND then
		DataPool : DelTrustFriend( g_currentIndex );
		this:Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.TEAMBOARD_OPEN_DEL_CHECK then
		if g_TeamBoardWindow ~= -1 then
			TeamBoardDataPool:DelInfo(g_TeamBoardWindow);
			if g_TeamBoardWindow == 1 then
				CloseWindow("TeamPTZhaomuWindow")
			else
				CloseWindow("TeamPTFindWindow")
			end
		end
		this:Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.KFS_RESET_GROWRATE then
		if IsWindowShow("WuhunSkillStudy") then
			if KFS_Data[1] == 1 then
				PlayerPackage:Kfs_Op_Do(11 , KFS_Data[2],0,1)
			elseif KFS_Data[1] == 2 then
				PlayerPackage:Kfs_Op_Do(12 , KFS_Data[2],0,1,0)
			end
		end
		this:Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_USE_CHESS then
		if g_qiziParam[1]==nil or g_qiziParam[2]==nil or g_qiziParam[3]==nil then
			this:Hide()
			return
		end

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnUseItem");
			Set_XSCRIPT_ScriptID(502017);
			Set_XSCRIPT_Parameter(0,g_qiziParam[3]);
			Set_XSCRIPT_Parameter(1,g_qiziParam[2]);--后面俩没有用
			Set_XSCRIPT_Parameter(2,g_qiziParam[1]);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
		g_qiziParam={}
		this:Hide()
		return
	end

	if g_FrameInfo == FrameInfoList.SONGLIAOWAR_XXS_CANCELBUF_CONFIRM then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("CancelImpact");
			Set_XSCRIPT_ScriptID(502019);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
		this:Hide()
		return
	end

	if (g_FrameInfo == FrameInfoList.LUHEXIEXIANG_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("LeaveConfirm");
			Set_XSCRIPT_ScriptID(998022);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
		this:Hide()
		return
	end

	if (g_FrameInfo == FrameInfoList.LUHEXIEXIANG_SINGLEENTERCONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SingleEnterScene");
			Set_XSCRIPT_ScriptID(998023);
			Set_XSCRIPT_Parameter(0, Server_Script_Function_Set[1])	--targetId
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		this:Hide()
		return
	end

	if (g_FrameInfo == FrameInfoList.LUHEXIEXIANG_REWARDCONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("TryGetAwardConfirm");
			Set_XSCRIPT_ScriptID(998023);
			Set_XSCRIPT_Parameter(0, Server_Script_Function_Set[1])	--targetId
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		this:Hide()
		return
	end

	if (g_FrameInfo == FrameInfoList.XINSHOUZHANLING_BUYLEVEL) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLevel" )
			Set_XSCRIPT_ScriptID( 998112 )
			Set_XSCRIPT_Parameter(0, g_xinshouzhanling_addlevel)							
			Set_XSCRIPT_Parameter(1, 1)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
		return
	end

	if (g_FrameInfo == FrameInfoList.XINSHOUZHANLING_JINGYING) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyJingYing" )
			Set_XSCRIPT_ScriptID( 998112 )
			Set_XSCRIPT_Parameter(0, 1)				
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		this:Hide()
		return
	end

	--2022Q3新天外预热活动-ypl to洛阳
	if (g_FrameInfo == FrameInfoList.XINTIANWAI_YURE_2022_1) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GoBackLuoYang" )
			Set_XSCRIPT_ScriptID( 998197 )
			Set_XSCRIPT_Parameter(0, 2)				
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		this:Hide()
		return
	end	
	--2022Q3新天外预热活动-ypl to四城
	if (g_FrameInfo == FrameInfoList.XINTIANWAI_YURE_2022_2) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GoToFourCity" )
			Set_XSCRIPT_ScriptID( 998197 )
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])	
			Set_XSCRIPT_Parameter(1, 2)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
		return
	end	

	--2022Q3新天外预热活动-ypl 批量购买
	if (g_FrameInfo == FrameInfoList.XINTIANWAI_YURE_2022_3) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoExchange" )
			Set_XSCRIPT_ScriptID( 998197 )
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[2])	
			Set_XSCRIPT_Parameter(1, 2)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
		return
	end	

	--2022Q4杯酒尽江湖-ypl 福缘刷新
	if (g_FrameInfo == FrameInfoList.BEIJIUJINJIANGHU_2022_1) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FlushFuYuan" )
			Set_XSCRIPT_ScriptID( 998325 )
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, 1)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
		return
	end	
	
	--2022Q4杯酒尽江湖-ypl 福缘领奖
	if (g_FrameInfo == FrameInfoList.BEIJIUJINJIANGHU_2022_2) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetFuYuanPrize" )
			Set_XSCRIPT_ScriptID( 998325 )
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, 1)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		this:Hide()
		return
	end		
	
	--卯兔闹春送红包 二次确认
	if (g_FrameInfo == FrameInfoList.CONFIRM_MAOTUNAOCHUN_REDPACKET) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnConfirm" )
			Set_XSCRIPT_ScriptID( 998375 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		this:Hide()
		return
	end	
	--白银马鞍 二次确认
	if (g_FrameInfo == FrameInfoList.CONFIRM_BAIYINMAAN) then
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnConfirmGet_BaiYin")
				Set_XSCRIPT_ScriptID(998512)
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[1])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		this:Hide()
		return
	end
	--青铜马鞍 二次确认
	if (g_FrameInfo == FrameInfoList.CONFIRM_QINGTONGMAAN) then
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnConfirmGet_QingTong")
				Set_XSCRIPT_ScriptID(998512)
				Set_XSCRIPT_Parameter(0,g_msgFrameVar[1])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		this:Hide()
		return
	end
	
	if (g_FrameInfo == FrameInfoList.CITYWAR_CHANGE_PK_MODE) then
		--2014Q1大世界帮会功能改造,"帮会同盟混战"模式只有服务器设置在K服保留帮会同盟信息时才能在K服启动
		if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
			this:Hide()
			return
		end
        Player:ChangePVPMode( 4 );
		this:Hide()
		return
	end	
	if g_FrameInfo == FrameInfoList.SEND_SHUIYUEDONGTIAN then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SendToShuiyue")
			Set_XSCRIPT_ScriptID(889982)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])	
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		this:Hide()
		return
	end	
	
	if g_FrameInfo == FrameInfoList.SONGLIAOWAR_REST_EXIT_CONFIRM then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ExitRest")
			Set_XSCRIPT_ScriptID(502019)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
		this:Hide()
		return
	end
	--xjc
	if g_FrameInfo == FrameInfoList.BianJin_WeiBingJia_CONFIRM then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("POSD")
			Set_XSCRIPT_ScriptID(702502)
			Set_XSCRIPT_Parameter(0,Server_Script_Function_Set[1])	--targetId
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();
		this:Hide()
		return
	end
	--xjc
	--xjc
	if g_FrameInfo == FrameInfoList.BianJin_WeiBingYi_CONFIRM then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("POSD")
			Set_XSCRIPT_ScriptID(702503)
			Set_XSCRIPT_Parameter(0,Server_Script_Function_Set[1])	--targetId
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();
		this:Hide()
		return
	end
	--xjc
	--chongloushop
	if g_FrameInfo == FrameInfoList.CHONGLOU_SHOP_CONFIRM then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("BuyConfirm")
			Set_XSCRIPT_ScriptID(888431)
			Set_XSCRIPT_Parameter(0,Server_Script_Function_Set[1])	--targetId
			Set_XSCRIPT_Parameter(1,Server_Script_Function_Set[4])	--itemIndex
			Set_XSCRIPT_Parameter(2,Server_Script_Function_Set[5])	--itemID
			Set_XSCRIPT_Parameter(3,Server_Script_Function_Set[6])	--shopID
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT();
		this:Hide()
		return
	end
	--chongloushop
	--彩色地鼠
	if g_FrameInfo == FrameInfoList.CAISEDISHU_SINGLE_CONFIRM then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SingleConfirm")
			Set_XSCRIPT_ScriptID(998448)
			Set_XSCRIPT_Parameter(0,Server_Script_Function_Set[1])	--targetId
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();
		this:Hide()
		return
	end
	--VIP幻玉
	if g_FrameInfo == FrameInfoList.VIPNIANDI_CONFIRM then
		PushEvent("VIPNIANDI_TURE")
		this:Hide()
		return
	end
	--VIP幻玉
	if (g_FrameInfo == FrameInfoList.CONFIRM_UPDATE_VIP) then
		Target:SendUpdateVipInfoMsg()
		this:Hide()
		return
	end

	-- 解除合作关系
	if ( g_FrameInfo == FrameInfoList.CONFIRM_DISSOLUTIONOFCONTRACT ) then
		-- 安全时间
		if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
			PushDebugMessage( "#{OR_PILFER_LOCK_FLAG}" );
			return
		end

		-- 电话密保验证
		if ( CheckPhoneMibaoAndMinorPassword() ~= 1 ) then
			return
		end

		-- 掌柜的
		local position = PlayerShop:GetSelfPlace();
		if ( position == "boss" )then
			PushDebugMessage( "#{HZHB_130712_01}" );
			return
		end

		-- 合作伙伴
		if ( position ~= "friend" ) then
			PushDebugMessage( "#{HZHB_130712_09}" );
			return
		end

		-- 将玩家从对应店铺的合作伙伴中移除
		if ( g_DissolutionIndex ~= -1 ) then
			PlayerShop:DealFriend( "dissolution", g_DissolutionIndex );
		end
	end

    --- 确认保存游戏设置，只需要打开相应的设置界面就可以了。
    if(g_FrameInfo == FrameInfoList.CONFIRM_SAVE_GAME_SETUP ) then
        --- 保存当前的设置
        local curWindowIdx = tonumber( g_MSG_Box_GameSetup_curt_Window_TagIndex )
        if curWindowIdx == 0 then
            PushEvent( "CHANGE_VIEW_SETUP", 0 )
        elseif curWindowIdx == 1 then
            PushEvent( "CHANGE_SOUND_SETUP", 0 )
        elseif curWindowIdx == 2 then
            PushEvent( "CHANGE_GAME_SETUP", 0 )
        elseif curWindowIdx == 3 then
            PushEvent( "CHANGE_ACCE_SETUP", 0 )
		-- 唯美版显示配置
		elseif curWindowIdx == 4 then
			PushEvent( "CHANGE_VIEW_WM_SETUP", 0 )
		elseif curWindowIdx == 5 then
			PushEvent( "CHANGE_ACCE_WM_SETUP", 0 )
		elseif curWindowIdx == 6 then
			PushEvent( "CHANGE_CONTROLMODE_SETUP", 0 )
        end

        --- 打开下一个窗口
        local nextWindowIdx = tonumber( g_MSG_Box_GameSetup_next_Window_TagIndex )
        if nextWindowIdx == -1 then
            --- 关闭自己
            PushEvent( "CLOSE_SETUP_WINDOW" )
            this:Hide()
        elseif nextWindowIdx == 0 then
            SystemSetup:ViewSetup()
        elseif nextWindowIdx == 1 then
            SystemSetup:SoundSetup()
        elseif nextWindowIdx == 2 then
            SystemSetup:GameSetup()
        elseif nextWindowIdx == 3 then
            SystemSetup:InputSetup()
		elseif nextWindowIdx == 4 then
			SystemSetup:ControlModeSetup()
        end

        this:Hide()
        return
    end

		-- 学习心法
	if ( g_FrameInfo == FrameInfoList.STUDY_XINFA ) then
		SendAskStudyXinfa( argStudyXinFaNowLevel, argStudyXinFaID, argStudyXinFaMenPai );

		this:Hide();
		return
	end

	-- 修炼
	if ( g_FrameInfo == FrameInfoList.STUDY_XIULIAN ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(argXiuLianFuncName);
			Set_XSCRIPT_ScriptID(argXiuLianScriptID);
			Set_XSCRIPT_Parameter(0,argXiuLianNpcID);
			Set_XSCRIPT_Parameter(1,argXiuLianMiJiSelect);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		XiulianStudy_SetSelectState();

        this:Hide()
        return
	end

	if ( g_FrameInfo == FrameInfoList.SANSHEN_FUBEN_CONFIRM ) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TransferToRestRoom")
			Set_XSCRIPT_ScriptID(891448)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end

	if g_FrameInfo == FrameInfoList.INFANT_DRESS_CUT_PAINT_CONFIRM then
		PushEvent( "INFANT_DRESS_CUT_CONFIRM_RESULT", 47, 1 )
	end

	if ( g_FrameInfo == FrameInfoList.MILITARYRANKSHOPBUYCONFIRM ) then
		-- 消息
		City:DoHonourShopBuy( MilitaryShopTableIndex, 1 );
	elseif ( g_FrameInfo == FrameInfoList.NOBILITYSHOPBUYCONFIRM ) then
		-- 消息
		City:DoYuanBaoShopBuy( NobilityShopTableIndex, 1 );
	end

	if	g_FrameInfo	== FrameInfoList.ALLIANCESHOP_BUY_CONFIRM then
		KAllianceShop:BuyItem(ShideShopTableIndex, 1)
	end

	if	g_FrameInfo	== FrameInfoList.CONFIRM_MSDSHOP_BUY_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(892850)
			Set_XSCRIPT_Parameter(0,ShideShopTableIndex);
			Set_XSCRIPT_Parameter(1,1);				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	end
	
	if g_FrameInfo == FrameInfoList.SHIDESHOPBUYCONFIRM then
		WenDingUI:DoShideShopBuy( ShideShopTableIndex, 1 );
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_MENGCHONG_COMMON then
		BieYeMengChong:Lua_MinuXiaoWo(g_newMengChongvalue,1)
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_MENGCHONG_REMOVE_COMMON then
		BieYeMengChong:Lua_RemoveMengChong(g_newMengChongvalue,1)
	end
	
	--坐骑续期
	if ( g_FrameInfo == FrameInfoList.MOUNT_PROLONG_CONFIRM ) then
		-- 执行脚本
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name( "DoProlong" );	-- 函数名
			Set_XSCRIPT_ScriptID( 892941 );			-- 脚本号
			Set_XSCRIPT_Parameter(0, Zuoqi_Bagpos);-- 坐骑bagpos
			Set_XSCRIPT_Parameter(1, ProlongDays);	-- 续期天数		
			Set_XSCRIPT_ParamCount(2);			-- 参数个数
		Send_XSCRIPT();
	end	

	-- 祈福天龙
	if ( g_FrameInfo == FrameInfoList.TIANJIANGQIFU_CONFIRM ) then
		-- 执行脚本
		if FuJiangTLUIType == 100 then
			Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name( "DoBless_WithFJL" );	-- 函数名
			Set_XSCRIPT_ScriptID( 890509 );			-- 脚本号
			Set_XSCRIPT_Parameter( 0, 1 );			-- 0:非活动界面 1:活动界面
			Set_XSCRIPT_ParamCount( 1 );			-- 参数个数
			Send_XSCRIPT();
		else
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoBless" ); 			-- 脚本号
			Set_XSCRIPT_ScriptID( 890509 );						-- 脚本编号
			Set_XSCRIPT_Parameter( 0, FuJiangTLUIType );		-- 0:非活动界面 1:活动界面
			Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
			Send_XSCRIPT()
		end
	end
	if ( g_FrameInfo == FrameInfoList.RESIGN_YUANBAO_CONFIRM ) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CheckResign")
		Set_XSCRIPT_ScriptID(891106)
		Set_XSCRIPT_Parameter(0,ResignIndex)
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_IMMIGRATION)    then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpouseImmigrationCallBack")
		Set_XSCRIPT_ScriptID(807012)
		Set_XSCRIPT_Parameter(0,ImmigArg1)
		Set_XSCRIPT_Parameter(1,ImmigArg2)
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_CANCEL_IMMIGRATION)    then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpuoseCancelImmg_confirm")
		Set_XSCRIPT_ScriptID(807012)
		Set_XSCRIPT_Parameter(0,ImmigArg1)
		Set_XSCRIPT_Parameter(1,ImmigArg2)
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end

	if(g_FrameInfo == FrameInfoList.CONFIRM_JIUCENGYAOTA)    then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnEnterYaoTa" )
			Set_XSCRIPT_ScriptID( 892506)
			Set_XSCRIPT_Parameter( 0, g_nData )
			Set_XSCRIPT_Parameter( 1, 0 )
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	end

	if(g_FrameInfo == FrameInfoList.CONFIRM_JIUCENGYAOTA_RELIVE)    then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnYuanBaoRelive" )
			Set_XSCRIPT_ScriptID( 892507)
			Set_XSCRIPT_Parameter( 0, g_nData )
			Set_XSCRIPT_Parameter( 1, 0 )
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	end

	if(g_FrameInfo == FrameInfoList.CONFIRM_SUMMERVACATION)    then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetPrize")
			Set_XSCRIPT_ScriptID(891205)
			Set_XSCRIPT_Parameter(0,ClickId);
			Set_XSCRIPT_Parameter(1,1);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

	if(g_FrameInfo == FrameInfoList.CONFIRM_LEAVE_SANSHENJIALAN)    then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TransferToRestRoom")
			Set_XSCRIPT_ScriptID(892521)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_JIUXING_FUBEN)    then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnEnterJiuXingFuben" )
			Set_XSCRIPT_ScriptID( 892520)
			Set_XSCRIPT_Parameter( 0, g_nData )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if FrameInfoList.CONFIRM_ZHENGBASAI_PET == g_FrameInfo then
		PushEvent("ZHENGBASAI_PET_CONFIRM_OK")
	end
	if FrameInfoList.CONFIRM_HAOXIA_PET == g_FrameInfo then
		PushEvent("HAOXIA_PET_CONFIRM_OK")
	end

	if FrameInfoList.CONFIRM_HAOXIA_EXCHANGE_BOUNS == g_FrameInfo then
		PushEvent("HAOXIA_EXCHANGE_BOUNS_CONFIRM_OK",g_HXL_nIndex,g_HXL_version)
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_ROSEWEAPON)    then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_ScriptID(g_RoseScriptID)
			Set_XSCRIPT_Parameter(0,g_RoseWeaponIndex)
			Set_XSCRIPT_Parameter(1,g_RoseWeaponID)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_ZHOUNIANQING_PRIZE)    then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetPrizeUseYuanbao")
			Set_XSCRIPT_ScriptID(891057)
			Set_XSCRIPT_Parameter(0,dayIndex);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	if(g_FrameInfo == FrameInfoList.CONFIRM_BIN_COMMON)    then
		PushEvent("COMMON_CONFIRM_RET", g_Common_Type, g_Common_Param)
	end
	
	if(g_FrameInfo == FrameInfoList.CONFIRM_LIJINDISCOUNT)    then
		PushEvent("LIJIN_DISCNT_CONFIRMRES", 1, g_HXL_nIndex)
	end

	if g_FrameInfo == FrameInfoList.BUY_PLAYERSHOP_SECOND_CONFIRM then
		PlayerShop:BuyShop()
	end

	if g_FrameInfo == FrameInfoList.DIGONGSHOP_CONFIRM then
		Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(888864)
        Set_XSCRIPT_Function_Name("BuyItem")
        Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
        Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
        Set_XSCRIPT_Parameter(2, g_msgFrameVar[3])
        Set_XSCRIPT_Parameter(3, g_msgFrameVar[4])
        Set_XSCRIPT_Parameter(4, 0)
        Set_XSCRIPT_ParamCount(5)
        Send_XSCRIPT()
	end
	
	if g_FrameInfo == FrameInfoList.MINGZHENJIANGHU_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_ScriptID(891229)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end


	if g_FrameInfo == FrameInfoList.GUILDCITY_FLAG_EXCHANGE then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnExchangeConfim")
			Set_XSCRIPT_ScriptID(998561)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_SUMMER_ZHANLING_ACT   then
		-- 1 请求打开购买经验界面
		-- 2 请求解锁高级战令
		-- 3 请求领奖
		-- 4 请求购买外观 1-4
		-- 5 请求购买点数
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUIEvent") 
			Set_XSCRIPT_ScriptID(791150)
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_Parameter(3,0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_SUMMER_ZHANLING_BUY   then
		-- 1 请求打开购买经验界面
		-- 2 请求解锁高级战令
		-- 3 请求领奖
		-- 4 请求购买外观 1-4
		-- 5 请求购买点数
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUIEvent") 
			Set_XSCRIPT_ScriptID(791150)
			Set_XSCRIPT_Parameter(0,4)
			Set_XSCRIPT_Parameter(1,g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(2,1)
			Set_XSCRIPT_Parameter(3,g_msgFrameVar[2])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end

	if g_FrameInfo == FrameInfoList.FENGHUANG_INVITE_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnBaoMing")
			Set_XSCRIPT_ScriptID(999096)
			Set_XSCRIPT_Parameter(0, g_msgFrameVar[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
	
	MessageBox_Self_OK_Clicked_Ex();
	MessageBox_Self_ClickLockPneuma()

	this:Hide();
end

function MessageBox_Self_PetSyn_OK_Clicked()
	Pet:Syn_Do(g_CityData[1], g_CityData[2]);
	g_CityData = {};
end

function MessageBox_Self_SDCZ_OK_Clicked()

	if g_SDCZ_ItemIdx >= 0 then
		PlayerPackage:UseItem(g_SDCZ_ItemIdx)
	end

	g_SDCZ_ItemIdx = -1
	g_SDCZ_ItemTableIdx = -1
	g_SDCZ_HaveQuestItem = 0
end

function MessageBox_Self_STALYEXP_OK_Clicked()
	--向服务器发送数据请求,供奉经验给师父
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAlyExpToMaster")
		Set_XSCRIPT_ScriptID(806023)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	--向服务器发送数据请求,需要更新的数据
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskJHShituInfo")
		Set_XSCRIPT_ScriptID(806023)
		Set_XSCRIPT_Parameter(0,0);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	g_ShituRelation = {};
end

--===============================================
-- 放弃摆摊(IDCONCEL)
--===============================================
function MessageBox_Self_Cancel_Clicked(bClick)
	if( 1 == bClick ) then

		if( PVPFLAG.ACCEPTDUEL == g_FrameInfo ) then
			DuelAccept( tostring( PVPFLAG.DuelName ), tostring( PVPFLAG.DuelGUID ), 0 )
		end
    end

	if ( g_FrameInfo == FrameInfoList.DISCARD_ITEM_FRAME ) then
		--通知解除锁定
		DiscardItemCancelLocked();
	elseif ( g_FrameInfo == FrameInfoList.DISCARD_QUAL8ITEM_FRAME ) then
		DiscardItemCancelLocked();

    elseif ( g_FrameInfo == FrameInfoList.LOCK_ITEM_CONFIRM_FRAME ) then
		--通知解除加锁
		CancelLockAfterConfirm();

	elseif ( g_FrameInfo == FrameInfoList.GUILD_CREATE_CONFIRM ) then
		Guild:CreateGuildConfirm(0);
	elseif ( g_FrameInfo == FrameInfoList.GUILD_DESTORY_CONFIRM ) then
		Guild:CreateGuildConfirm(0);
	elseif ( g_FrameInfo == FrameInfoList.GUILD_DIS_FIRSTMAN ) then
		this:Hide();
	elseif ( g_FrameInfo == FrameInfoList.GUILD_QUIT_CONFIRM ) then
		Guild:CreateGuildConfirm(0);

	elseif(g_FrameInfo == FrameInfoList.NET_CLOSE_MESSAGE) then
		QuitApplication("quit");
	elseif( g_FrameInfo == FrameInfoList.CITY_CONFIRM ) then
		MessageBox_Self_City_Cancel_Clicked();
	elseif(g_FrameInfo == FrameInfoList.YUANBAO_BUY_ITEM) then
		g_CityData = {};
	-- add by zchw
	elseif (g_FrameInfo == FrameInfoList.FITTINGROOM_BUY_ITEM_CONFIRM ) then
		g_CityData = {};
	elseif (g_FrameInfo == FrameInfoList.JIYUANSHOP_BUY_ITEM_CONFIRM ) then
		g_CityData = {};
	elseif g_FrameInfo == FrameInfoList.CONFIRM_REMOVE_STALL then
		this:Hide();
	-- zchw for pet procreate
	elseif g_FrameInfo == FrameInfoList.PET_PROCREATE_PROMPT then
		if bClick == 1 then
			PushEvent(462, 1); --PETPROCREATE_KEY_STATE
		end
		this:Hide();
	elseif( g_FrameInfo == FrameInfoList.SAVE_STALL_INFO ) then
		if bClick == 1 then
			StallSale:CloseStall("cancel");
			-- add by zchw
			StallSale:CloseStallMessage();
		end
		-- add by zchw
		StallSale:CloseStallMessage();
	elseif( g_FrameInfo == FrameInfoList.PET_SYNC_CONFIRM ) then
		g_CityData = {};

	elseif( g_FrameInfo == FrameInfoList.STALYEXP_CONFIRM ) then
		g_ShituRelation = {};

	elseif(g_FrameInfo == FrameInfoList.OPEN_IS_SELL_TO_RECSHOP) then
		if(Recycle_Bag_idx ~=nil and tonumber(Recycle_Bag_idx)>0) then
			PlayerShop:CancelSellItem2RecycleShop(Recycle_Bag_idx);
		end
	elseif(g_FrameInfo == FrameInfoList.CONFIRM_USE_CHESS) then
		g_qiziParam={}
	elseif(g_FrameInfo == FrameInfoList.IMDressBuyToOther) then
		IMDressBuyToOtherData = {}
	end

	--取消删除收费表情
	if (g_FrameInfo == FrameInfoList.UNINSTALL_CHAT_FACE) then
		g_currentIndex = 0
	end

	--取消删除收费休闲动作
	if (g_FrameInfo == FrameInfoList.UNINSTALL_CHAT_ACTION) then
		g_currentIndex = 0
	end

	if (g_FrameInfo == FrameInfoList.QUIT_CHATGROUP_CONFIRM) then
		g_currentIndex = 0
	end

	if (g_FrameInfo == FrameInfoList.DISMISS_CHATGROUP_CONFIRM) then
		g_currentIndex = 0
	end



	--add by kaibin for 门派进阶
	if(g_FrameInfo == FrameInfoList.CONFIRM_USE_MIFA) then
		CancleMifaLock()
	end

	if g_FrameInfo == FrameInfoList.CONFIRM_IMMIGRATION   and bClick == 1 then
		--移民取消
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpouseImmigrationCallBack")
		Set_XSCRIPT_ScriptID(807012)

		Set_XSCRIPT_Parameter(0,ImmigArg1)
		Set_XSCRIPT_Parameter(1,ImmigArg2)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	if g_FrameInfo == FrameInfoList.CONFIRM_CANCEL_IMMIGRATION   and bClick == 1 then
		--移民取消
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpuoseCancelImmg_confirm")
		Set_XSCRIPT_ScriptID(807012)
		Set_XSCRIPT_Parameter(0,ImmigArg1)
		Set_XSCRIPT_Parameter(1,ImmigArg2)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
    --- 不保存游戏设置
    if ( g_FrameInfo == FrameInfoList.CONFIRM_SAVE_GAME_SETUP ) then
        if bClick == 1 then
            --- 恢复之前的设置
            local curWindowIdx = tonumber( g_MSG_Box_GameSetup_curt_Window_TagIndex )
            if curWindowIdx == 0 then
                PushEvent( "CHANGE_VIEW_SETUP", 1 )
            elseif curWindowIdx == 1 then
                PushEvent( "CHANGE_SOUND_SETUP", 1 )
            elseif curWindowIdx == 2 then
                PushEvent( "CHANGE_GAME_SETUP", 1 )
            elseif curWindowIdx == 3 then
                PushEvent( "CHANGE_ACCE_SETUP", 1 )
			-- 唯美版显示配置
			elseif curWindowIdx == 4 then
				PushEvent( "CHANGE_VIEW_WM_SETUP", 1 )
			elseif curWindowIdx == 5 then
				PushEvent( "CHANGE_ACCE_WM_SETUP", 1 )
			elseif curWindowIdx == 6 then
				PushEvent( "CHANGE_CONTROLMODE_SETUP", 1 )
            end

            --- 打开下一个窗口
            local nextWindowIdx = tonumber( g_MSG_Box_GameSetup_next_Window_TagIndex )
            if nextWindowIdx == -1 then
                --- 关闭自己
                this:Hide()
                PushEvent( "CLOSE_SETUP_WINDOW" )
            elseif nextWindowIdx == 0 then
                SystemSetup:ViewSetup()
            elseif nextWindowIdx == 1 then
                SystemSetup:SoundSetup()
            elseif nextWindowIdx == 2 then
                SystemSetup:GameSetup()
            elseif nextWindowIdx == 3 then
                SystemSetup:InputSetup()
			elseif nextWindowIdx == 4 then
				SystemSetup:ControlModeSetup()
            end
        end
    end


    if(g_FrameInfo == FrameInfoList.STALL_OFFLINE_CANCLE) then
	--确认了离线摆摊，后续的可能按钮没显示
	MessageBox_Self_OK_Button:Show();
	MessageBox_Self_Cancel_Button:Show();
	MessageBox_Self_Cancel_Button:SetText("#{INTERFACE_XML_542}")--取消
    if SystemSetup:IsClassic() == 1 then
	    MessageBox_Self_Blank:SetProperty("UnifiedSize", "{{1.000000,-85.000000},{0.000000,20.000000}}")
    end
    end

    if(g_FrameInfo == FrameInfoList.STALL_OFFLINE_ERRSTATE) then
    --不处理
    end
    if(g_FrameInfo == FrameInfoList.DART_ADJUST) then
		Dart_Data[3] = 0
    end
    if ( FrameInfoList.PNEUMA_LOCK_CONFIRM == g_FrameInfo ) then
  	 	Pneuma:SetClientLock(g_msgFrameVar[1], "unlock")
	elseif ( FrameInfoList.PNEUMA_JUYUAN_CONFIRM == g_FrameInfo ) then
  	 	--不处理
    end

	if("NET_CLOSE" == g_LastEvent) then
		local ServerName=Variable:GetVariable("Login_ServerName")
		local SceneId = GetSceneID()
		if(SceneId~=nil and ServerName~= nil) then
			local keyValue = Player:SendReportMsg(ServerName,tostring(SceneId))
			g_LastEvent = ""
		end
	end

	if ( g_FrameInfo == FrameInfoList.STUDY_XINFA ) then
		-- 不处理
	end

	if ( g_FrameInfo == FrameInfoList.STUDY_XIULIAN ) then
		-- 不处理
	end

	if g_FrameInfo == FrameInfoList.INFANT_DRESS_CUT_PAINT_CONFIRM and bClick == 1 then
		PushEvent( "INFANT_DRESS_CUT_CONFIRM_RESULT", 47, 0 )
	end
	if (g_FrameInfo == FrameInfoList.DISMISS_ZHANTUAN_CONFIRM) then
		g_currentIndex = 0
	end

	if g_FrameInfo == FrameInfoList.SERVER_CONTROL and bClick == 1 then
		--点取消的rpc
		if Server_Script_Function_Set[2] and Server_Script_Function_Set[2] ~= "" then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name(Server_Script_Function_Set[2])
				Set_XSCRIPT_ScriptID(Server_Script_ID);
				Set_XSCRIPT_Parameter(0,Server_Return_1);
				Set_XSCRIPT_Parameter(1,Server_Return_2);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
		end
	end

	--珍兽套装拆解确认
	--if( g_FrameInfo == FrameInfoList.PET_EQUIPSUITDEPART_CONFIRM ) then
		--PushEvent("PET_EQUIP_DEPART_CANCEL")
	--end

	if(g_FrameInfo == FrameInfoList.CONFIRM_LIJINDISCOUNT and bClick == 1)    then
		--PushEvent("LIJIN_DISCNT_CONFIRMRES", 2)
	end

	if ( g_FrameInfo == FrameInfoList.CHAR_RANAME_CONFIRM ) and bClick == 1 then
		PushEvent("CITY_SHOW_INPUT_NAME", "close")
	end
	
	if ( g_FrameInfo == FrameInfoList.COMMONGIFT_TITLE_CONFIRM ) then
		-- 解除背包格子蒙红锁定
		LifeAbility : Lock_Packet_Item( g_msgFrameVar[1], 0 )
	end
	
	
	this:Hide();

end

function MessageBox_Self_Help()
	if( g_FrameInfo == FrameInfoList.NET_CLOSE_MESSAGE ) then
		Helper:GotoHelper( "61" );
	else
		Helper:GotoHelper("*MessageBox_Self");
	end
end


function MessageBox_Self_ShowDart()
	if (Dart_Data[1] >=1 and Dart_Data[1] <= 5) then
		MessageBox_Self_Text:SetText( "#{FBSJ_090421_2}" ); --神亦石
	elseif (Dart_Data[1] == 6) then
		MessageBox_Self_Text:SetText( "#{FBSJ_090421_1}" ); --忘无石
	elseif (Dart_Data[1] == 7) then
		MessageBox_Self_Text:SetText( "#{FBSJ_090421_5}" ); --百淬神玉
	elseif (Dart_Data[1] == 8) then
		MessageBox_Self_Text:SetText( "#{FBSJ_090421_4}" ); --千淬神玉
	elseif (Dart_Data[1] == 9) then
		MessageBox_Self_Text:SetText( "#{FBSJ_090421_3}" ); --浴火石
	end

	MessageBox_Self_DragTitle:SetText("");
	MessageBox_Self_UpdateRect();

	this:Show();
	MessageBox_Self_OK_Button:Show();
	MessageBox_Self_Cancel_Button:Show();
end


function MessageBox_Self_AdjustDart()
	if (Dart_Data[1] >=1 and Dart_Data[1] <= 5) then
		DataPool:DarkAdjustAttr(Dart_Data[2], Dart_Data[1], 1);	--神亦石
	elseif (Dart_Data[1] == 6) then
	--	DataPool:DarkAdjustSkill(Dart_Data[2] , 1);		--忘无石
		--洗技能
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("DarkSkillAdjustForBagItem");
			Set_XSCRIPT_ScriptID(332207);
			Set_XSCRIPT_Parameter(0,Dart_Data[2]);
			Set_XSCRIPT_Parameter(1,1);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (Dart_Data[1] == 7) then
		DataPool:DarkResetQuality(Dart_Data[2], 1, 1, 0);    --百淬神玉
	elseif (Dart_Data[1] == 8) then
		DataPool:DarkResetQuality(Dart_Data[2], 2, 1, 0);    --千淬神玉
	elseif (Dart_Data[1] == 9) then
		DataPool:DarkReset(Dart_Data[2], 1);		--浴火石
	end
end

function MessageBox_GetNeedUseConfirmItemShowTxt( itemTblIdx )
	--获取显示内容
	for _, item in UseConfirmItemShowTxt do
		if ( itemTblIdx == item.idx ) then
			return item.txt;
		end
	end
	return nil;
end

function MessageBox_GetGainItemIDSDCZ( itemTblIdx )
	--获取显示内容
	for _, item in g_SDCZ_GainItemID_List do
		if ( itemTblIdx == item.idx ) then
			return item.itemid;
		end
	end
	return nil;
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MessageBox_Self_Frame_On_ResetPos()
  MessageBox_Self_Frame:SetProperty("UnifiedPosition", g_MessageBox_Self_Frame_UnifiedPosition);
end

function MessageBox_Self_SetTargetName( targetName, targetZoneWorldID )
    local showName = targetName
    local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
    if selfZoneWorldID ~= targetZoneWorldID and targetZoneWorldID ~= -1 then
        showName = targetName.."@"..DataPool:GetServerName( tonumber( targetZoneWorldID ) )
    end

    return showName
end

function MessageBox_Self_ClickLockPneuma()
	if(g_FrameInfo == FrameInfoList.PNEUMA_LOCK_CONFIRM) then
		--PushDebugMessage(g_msgFrameVar[1])
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", g_msgFrameVar[1])
		if(theAction:GetID() == 0 ) then
			PushDebugMessage("#{ZYXT_120528_115}")
			this:Hide()
			return
		end
		Pneuma:PnuemaLock(g_msgFrameVar[1], "lock")--Pneuma:PnuemaLock(g_msgFrameVar[1])
		Pneuma:SetClientLock(g_msgFrameVar[1], "unlock")
		this:Hide()
	end
end

function MessageBox_Self_ClearVar()
	for i = 1,8 do
		g_msgFrameVar[i] = 0
	end
end

function MessageBox_Self_TransterDirect()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name(Get_XParam_STR(0));
		Set_XSCRIPT_ScriptID(Get_XParam_INT(0));
		Set_XSCRIPT_Parameter(0,Get_XParam_INT(1));
		Set_XSCRIPT_Parameter(1,Get_XParam_INT(2));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

function MessageBox_Self_IsWillToTip()
	local nLevel = Player:GetData("LEVEL")
	local nSceneId = Get_XParam_INT(0)
	local inTransScene = 0
	for _, sceneId in g_AllTransScriptId do
		if ( sceneId == nSceneId ) then
			inTransScene = 1
			break
		end
	end

	if inTransScene == 0 then
		return 0
	end

	for _, sceneId in pkSceneTipId do
		if ( sceneId == nSceneId ) then
			return 0
		end
	end
	if nLevel < 20 then
		MessageBox_Self_TransterDirect()
		return 1
	end
	return 0
end

--function MessageBox_Self_Shengmingxianhe_confirm(nType,num1,num2,num3)
--	MessageBox_Self_ClearVar()
--	local strInfo = ""
--	if nType == 0 then
--		strInfo = ScriptGlobal_Format("#{MDJH_140303_13}",num1,num2,num3)
--	elseif nType == 1 then
--		strInfo = ScriptGlobal_Format("#{MDJH_140303_14}",num1,num2,num3)
--	end

--	MessageBox_Self_Text:SetText(strInfo)
--	MessageBox_Self_UpdateRect();
--	g_FrameInfo = FrameInfoList.SHENGMINGXIANHE_CONFIRM
--	g_msgFrameVar[1] = nType
--	this:Show();
--end

function MessageBox_Self_T3Shop_Confirm()

	MessageBox_Self_DragTitle:SetText("#gFF0FA0购买商品")
	
	local price = DataPool:LuaFnGetT3ShopItemInfo(g_CityData[2], "PRICE")
	local currency = DataPool:LuaFnGetT3ShopItemInfo(g_CityData[2], "CURRENCY")
	
	local strPrice = ""
	if currency == 0 then
		strPrice = ScriptGlobal_Format("#{LDSD_200805_52}", tostring(price))
	else
		strPrice = ScriptGlobal_Format("#{LDSD_200805_53}", tostring(price))
	end
	
	local strName = ScriptGlobal_Format("#{LDSD_200805_54}", g_CityData[1])		

	MessageBox_Self_Text:SetText(strPrice..strName)
	this:Show()
end

function MessageBox_Self_ExteriorRide_Confirm(flag)
	
	if flag == 0 then
		g_FrameInfo = FrameInfoList.EXTERIOR_RIDE_EQUIP_CONFIRM
	else
		g_FrameInfo = FrameInfoList.EXTERIOR_RIDE_ITEM_CONFIRM
	end
	
	MessageBox_Self_DragTitle:SetText("")
	
	local nExteriorID = g_msgFrameVar[3]
	local nLeftTime = g_msgFrameVar[4]
	local nAddLimitTime = g_msgFrameVar[5]
	
	local strName = Exterior:LuaFnGetExteriorRideInfo(nExteriorID, "Name")
	
	local strTemp = ""
	if nLeftTime > 0 then
		--永久坐骑
		if nAddLimitTime < 0 then
			--道具使用成功后，可将AAA变更为永久坐骑，您确定要使用吗
			strTemp = ScriptGlobal_Format("#{WGTJ_200617_67}", strName)
		else
			if nLeftTime + nAddLimitTime*60 > 365*24*60*60 then			
				strTemp = ScriptGlobal_Format("#{WGTJ_201222_115}", strName)
			else
				local strAddTime = ""
				if nAddLimitTime >= 1440 then
					local nAddDay = math.floor(nAddLimitTime / 1440)
					strAddTime = ScriptGlobal_Format("#{WGTJ_201222_94}", tostring(nAddDay))
				elseif nAddLimitTime >= 60 then
					local nAddHour = math.floor(nAddLimitTime / 60)
					strAddTime = ScriptGlobal_Format("#{WGTJ_201222_95}", tostring(nAddHour))
				else
					strAddTime = "#{WGTJ_201222_96}"
				end
				strTemp = ScriptGlobal_Format("#{WGTJ_201222_36}", strName, strAddTime)
			end
		end
	else
		--永久坐骑
		if nAddLimitTime < 0 then
			--道具使用成功后，可将AAA变更为永久坐骑，您确定要使用吗
			strTemp = ScriptGlobal_Format("#{WGTJ_200617_67}", strName)
		else
			local strAddTime = ""
			if nAddLimitTime >= 1440 then
				local nAddDay = math.floor(nAddLimitTime / 1440)
				strAddTime = ScriptGlobal_Format("#{WGTJ_201222_94}", tostring(nAddDay))
			elseif nAddLimitTime >= 60 then
				local nAddHour = math.floor(nAddLimitTime / 60)
				strAddTime = ScriptGlobal_Format("#{WGTJ_201222_95}", tostring(nAddHour))
			else
				strAddTime = "#{WGTJ_201222_96}"
			end
			strTemp = ScriptGlobal_Format("#{WGTJ_201222_38}", strName, strAddTime)
		end
	end	
	
	MessageBox_Self_Text:SetText(strTemp)
	
	this:Show()
end

function MessageBox_Self_ExteriorWeapon_Confirm(flag)

	if flag == 0 then
		g_FrameInfo = FrameInfoList.EXTERIOR_DECOWEAPON_EQUIP_CONFIRM
	else
		g_FrameInfo = FrameInfoList.EXTERIOR_DECOWEAPON_ITEM_CONFIRM
	end
	
	MessageBox_Self_DragTitle:SetText("")
	
	local nExteriorID = g_msgFrameVar[3]
	local nLeftTime = g_msgFrameVar[4]
	local nAddLimitTime = g_msgFrameVar[5]
	
	local strName = Exterior:LuaFnGetExteriorWeaponInfo(nExteriorID, "Name")
	
	local strTemp = ""
	if nLeftTime > 0 then
		--永久坐骑
		if nAddLimitTime < 0 then
			strTemp = ScriptGlobal_Format("#{WGTJ_201222_40}", strName)
		else
			if nLeftTime + nAddLimitTime*60 > 365*24*60*60 then			
				strTemp = ScriptGlobal_Format("#{WGTJ_201222_116}", strName)
			else
				local strAddTime = ""			
				if nAddLimitTime >= 1440 then
					local nAddDay = math.floor(nAddLimitTime / 1440)
					strAddTime = ScriptGlobal_Format("#{WGTJ_201222_94}", tostring(nAddDay))
				elseif nAddLimitTime >= 60 then
					local nAddHour = math.floor(nAddLimitTime / 60)
					strAddTime = ScriptGlobal_Format("#{WGTJ_201222_95}", tostring(nAddHour))
				else
					strAddTime = "#{WGTJ_201222_96}"
				end
				strTemp = ScriptGlobal_Format("#{WGTJ_201222_43}", strName, strAddTime)
			end			
		end
	else
		--永久坐骑
		if nAddLimitTime < 0 then
			strTemp = ScriptGlobal_Format("#{WGTJ_201222_45}", strName)
		else
			local strAddTime = ""
			if nAddLimitTime >= 1440 then
				local nAddDay = math.floor(nAddLimitTime / 1440)
				strAddTime = ScriptGlobal_Format("#{WGTJ_201222_94}", tostring(nAddDay))
			elseif nAddLimitTime >= 60 then
				local nAddHour = math.floor(nAddLimitTime / 60)
				strAddTime = ScriptGlobal_Format("#{WGTJ_201222_95}", tostring(nAddHour))
			else
				strAddTime = "#{WGTJ_201222_96}"
			end
			strTemp = ScriptGlobal_Format("#{WGTJ_201222_47}", strName, strAddTime)
		end
	end	
	
	MessageBox_Self_Text:SetText(strTemp)
	
	this:Show()
end

function MessageBox_Self_ToyItem_Confirm()

	g_FrameInfo = FrameInfoList.EXTERIOR_TOY_ITEM_CONFIRM

	MessageBox_Self_DragTitle:SetText("")
	
	local nToy = g_msgFrameVar[3]
	local nLeftTime = g_msgFrameVar[4]
	local nAddLimitTime = g_msgFrameVar[5]
	
	local strName = Exterior:LuaFnGetToyInfo(nToy, "Name")
	local strTemp = ScriptGlobal_Format("#{FWYJ_210318_25}", strName)
	
	MessageBox_Self_Text:SetText(strTemp)
	
	this:Show()
end

function MessageBox_Self_DiGongShop_Confirm()
	g_FrameInfo = FrameInfoList.DIGONGSHOP_CONFIRM
	CancelLastOp(-1)
	MessageBox_Self_ClearVar()
	g_msgFrameVar[1] = Get_XParam_INT(0) --itemIndex
	g_msgFrameVar[2] = Get_XParam_INT(1) --itemID
	g_msgFrameVar[3] = Get_XParam_INT(2) --shopID
	g_msgFrameVar[4] = Get_XParam_INT(3) --targetID
	-- g_msgFrameVar[5] = Get_XParam_INT(4) --onceNum
	-- g_msgFrameVar[6] = Get_XParam_INT(5) --needNum
	-- g_msgFrameVar[7] = Get_XParam_INT(6) --daibiitem

	MessageBox_Self_DragTitle:SetText("")
	local strTemp = ScriptGlobal_Format("#{JLQX_211206_152}", 
	Get_XParam_INT(5),
	DataPool:Lua_GetItemNameByIndex(Get_XParam_INT(6)),
	Get_XParam_INT(4),
	DataPool:Lua_GetItemNameByIndex(g_msgFrameVar[2])
	)
	MessageBox_Self_Text:SetText(strTemp)
	--关闭批量购买界面
	if IsWindowShow("DiGong_Shop_BulkBuying") then
        CloseWindow("DiGong_Shop_BulkBuying", true)
    end
	this:Show()
end

function MessageBox_Self_MingZhenTianXia_Confirm( strText )
	g_FrameInfo = FrameInfoList.MINGZHENJIANGHU_CONFIRM

	MessageBox_Self_DragTitle:SetText("#gFF0FA0#gFF0FA0确 认")
	MessageBox_Self_Text:SetText(strText)
	MessageBox_Self_UpdateRect();
	this:Show()
end

function MessageBox_Self_UseRmbEmo_Confirm()
	g_FrameInfo = FrameInfoList.RMB_EMO_INSTALL_CONFIRM
	
	local emoid = g_msgFrameVar[3] --emoid
	local isHaveEmo = g_msgFrameVar[4] --isHave
	local LeftTimeMin = g_msgFrameVar[5] --lefttime
	local addTimeHour = g_msgFrameVar[6] --addHour
	
	local faceName = DataPool:GetRMB_FaceName(emoid)
	
	if isHaveEmo == 1 then
		if addTimeHour < 0 then
			local strTemp = ScriptGlobal_Format("#{BQB_220329_09}", tostring(faceName))
			MessageBox_Self_Text:SetText(strTemp)
		else
			if addTimeHour * 60 + LeftTimeMin > 525600 then
				MessageBox_Self_Text:SetText("#{BQB_220329_07}")
			else
				local addTimeDay = math.floor(addTimeHour / 24)
				local strTemp = ScriptGlobal_Format("#{BQB_220329_10}", tostring(faceName), tostring(addTimeDay))
				MessageBox_Self_Text:SetText(strTemp)
			end
		end
	else
		if addTimeHour < 0 then
			local strTemp = ScriptGlobal_Format("#{BQB_220329_12}", tostring(faceName))
			MessageBox_Self_Text:SetText(strTemp)
		else
			local addTimeDay = math.floor(addTimeHour / 24)
			local strTemp = ScriptGlobal_Format("#{BQB_220329_11}", tostring(faceName), tostring(addTimeDay))
			MessageBox_Self_Text:SetText(strTemp)
		end
	end

	MessageBox_Self_UpdateRect()
	this:Show()
end

function MessageBox_Self_ZhongQingMeiGui_Confirm()
	g_FrameInfo = FrameInfoList.ZHONGQINGMEIGUI_CONFIRM

	MessageBox_Self_DragTitle:SetText("#gFF0FA0#gFF0FA0确 认")
	MessageBox_Self_Text:SetText( "#{MGCQ_220128_33}" )
	MessageBox_Self_UpdateRect();
	this:Show()
end

function MessageBox_Self_ZhongQingMeiGuiNew_Confirm( szText )
	g_FrameInfo = FrameInfoList.ZHONGQINGMEIGUI_NEW_CONFIRM

	MessageBox_Self_DragTitle:SetText("#gFF0FA0#gFF0FA0确 认")
	MessageBox_Self_Text:SetText( szText )
	MessageBox_Self_UpdateRect();
	this:Show()
end

function MessageBox_Self_QiMiaoExp_Confirm()
	g_FrameInfo = FrameInfoList.QIMIAOEXPDAN_CONFIRM

	MessageBox_Self_DragTitle:SetText("#gFF0FA0#gFF0FA0确 认")
	MessageBox_Self_Text:SetText( "#{DBJY_20230310_7}" )
	MessageBox_Self_UpdateRect();
	this:Show()
end

function MessageBox_Self_DiGongEnter_Confirm()
	g_FrameInfo = FrameInfoList.CONFIRM_ENTERDIGONG

	MessageBox_Self_Text:SetText( "#{JDQL_230322_61}" );	-- 设置内容
	MessageBox_Self_DragTitle:SetText("")
	
	MessageBox_Self_OK_Button:Show();
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()
end

function MessageBox_Self_TianJiChengEnter_Confirm()
	g_FrameInfo = FrameInfoList.CONFIRM_ENTERTIANJICHENG

	MessageBox_Self_Text:SetText( "#{TJZF_230525_45}" );	-- 设置内容
	MessageBox_Self_DragTitle:SetText("")
	
	MessageBox_Self_OK_Button:Show();
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()
end

local g_EquipTypeText = {
"#{CLTX_241119_30}",
"#{CLTX_241119_31}",
"#{CLTX_241119_32}",
"#{CLTX_241119_33}",
"#{CLTX_241119_34}",
"#{CLTX_241119_35}",
"#{CLTX_241119_36}",
"#{CLTX_241119_37}",
"#{CLTX_241119_38}",
"#{CLTX_241119_39}",
"#{CLTX_241119_40}",
"#{CLTX_241119_41}",
"#{CLTX_241119_42}",
"#{MDJH_250530_9}",
"#{MDJH_250530_10}",
}



function MessageBox_Self_Oribaotu_Confirm_free()
	g_FrameInfo = FrameInfoList.CONFIRM_BUY_ORIBAOTU_FREE
	local money = g_msgFrameVar[1]
	local itemid = g_msgFrameVar[2]
	local item_name = DataPool:Lua_GetItemNameByIndex(itemid)
	local str = ScriptGlobal_Format("#{XCBT_260506_14}",money,item_name)
	MessageBox_Self_Text:SetText(str)
	MessageBox_Self_DragTitle:SetText("")

	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()	


	ObjCaredID  = DataPool:GetNPCIDByServerID(g_msgFrameVar[3])
	if ObjCaredID ~= -1 then
		--开始关心NPC
		this:CareObject(ObjCaredID, 1, "MsgBox");
	end	
end

function MessageBox_Self_BuyNewbaotu_Confirm_free()
	g_FrameInfo = FrameInfoList.CONFIRM_BUY_NEWBAOTU_FREE
	local jiaozi = g_msgFrameVar[1]
	local itemid = g_msgFrameVar[2]
	local item_name = DataPool:Lua_GetItemNameByIndex(itemid)
	local str = ScriptGlobal_Format("#{CPBT_260115_114}",jiaozi,item_name)
	MessageBox_Self_Text:SetText(str)
	MessageBox_Self_DragTitle:SetText("")

	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()	


	ObjCaredID  = DataPool:GetNPCIDByServerID(g_msgFrameVar[3])
	if ObjCaredID ~= -1 then
		--开始关心NPC
		this:CareObject(ObjCaredID, 1, "MsgBox");
	end	
end

function MessageBox_Self_ChongLouEffectActive_Confirm()
	g_FrameInfo = FrameInfoList.CHONGLOU_EFFECT_ACTIVE_CONFIRM
	
	local equip_type = g_msgFrameVar[2]
	local effect_id = g_msgFrameVar[3]
	local effect_name = DataPool:LuaFnGetChongLouEffectName(effect_id)
	
	local need_item, need_item_count, _ = DataPool:LuaFnGetChongLouEffectActiveNeed(effect_id)
	local item_name = DataPool:Lua_GetItemNameByIndex(need_item)
	local strTemp = ScriptGlobal_Format("#{CLTX_241119_22}", tostring(g_EquipTypeText[equip_type + 1]), tostring(effect_name), tostring(need_item_count), tostring(item_name))
	MessageBox_Self_Text:SetText(strTemp)
	MessageBox_Self_DragTitle:SetText("")

	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()
end

function MessageBox_Self_BuyFashionCloth_Confirm()
	g_FrameInfo = FrameInfoList.BUY_SUPERASS_FASHION_CONFIRM

	MessageBox_Self_Text:SetText("#{WHTJ_240117_105}")
	MessageBox_Self_DragTitle:SetText("")

	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()
end

function MessageBox_Self_TcityWar_GroupRaid_Confirm(groupid)

	g_FrameInfo = FrameInfoList.TCITYWAR_GROUP_RAID

	local str = ScriptGlobal_Format("#{GCQH_240429_225}",groupid)
	MessageBox_Self_Text:SetText(str)
	MessageBox_Self_DragTitle:SetText("")

	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()
end

function MessageBox_Self_Xiake_MonsterToken()
	g_FrameInfo = FrameInfoList.XIAKE_GUAIWU_ZHAOJILING_CONFIRM

	local itemid = PlayerPackage:GetItemTableIndex(g_msgFrameVar[1])
	if itemid == 38007864 then
		MessageBox_Self_Text:SetText("#{GWZJ_250219_07}")
	elseif itemid == 38007865 then
		MessageBox_Self_Text:SetText("#{XKSD_250613_14}")
	elseif itemid == 38007933 then
		MessageBox_Self_Text:SetText("#{GWZJ_250219_23}")
	else
		return
	end
	MessageBox_Self_DragTitle:SetText("")

	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	MessageBox_Self_UpdateRect()
	this:Show()
end

function MessageBox_Self_ExpBallUse_Confirm( szItemName, szText )
	g_FrameInfo = FrameInfoList.EXPBALL_USE_CONFIRM

	MessageBox_Self_DragTitle:SetText("#gFF0FA0#gFF0FA0"..szItemName)
	MessageBox_Self_Text:SetText( szText )
	MessageBox_Self_UpdateRect();
	this:Show()
end

function MessageBox_Self_CommonGift_Title_Confirm()
	g_FrameInfo = FrameInfoList.COMMONGIFT_TITLE_CONFIRM
	MessageBox_Self_DragTitle:SetText("")
	MessageBox_Self_Text:SetText( "#{TYLB_250728_3}" )
	MessageBox_Self_UpdateRect();
	this:Show()
end

function MessageBox_Self_StealSkill_Confirm(skillid1, skillid2, skillid3, num)
	local strText
	if num == 1 then
		strText = ScriptGlobal_Format( "#{TXJN_250903_35}", GetSSName(skillid1) )
	elseif num == 2 then
		strText = ScriptGlobal_Format( "#{TXJN_250903_36}", GetSSName(skillid1), GetSSName(skillid2))	
	elseif num == 3 then
		strText = ScriptGlobal_Format( "#{TXJN_250903_37}", GetSSName(skillid1), GetSSName(skillid2), GetSSName(skillid3))	
	end
	
	g_msgFrameVar[1] = skillid1
	g_msgFrameVar[2] = skillid2
	g_msgFrameVar[3] = skillid3
	
	g_FrameInfo = FrameInfoList.STEALSKILL_CONFIRM
	MessageBox_Self_DragTitle:SetText("")
	MessageBox_Self_Text:SetText( strText )
	MessageBox_Self_UpdateRect();
	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	this:Show()	
			
end

function MessageBox_Self_Rest_StealSkill_Confirm()
	local strText = ScriptGlobal_Format( "#{TXJN_250903_41}", GetLastRestStealNum() )
	g_FrameInfo = FrameInfoList.RESET_STEALSKILL_CONFIRM
	MessageBox_Self_DragTitle:SetText("")
	MessageBox_Self_Text:SetText( strText )
	MessageBox_Self_UpdateRect();
	MessageBox_Self_OK_Button:Show()
	MessageBox_Self_Cancel_Button:Show()
	this:Show()
end
