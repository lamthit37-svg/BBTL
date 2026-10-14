--WuhunQuest.lua

local g_FrameInfo = -1				--当前窗口确认的类型
local g_FrameEvent = -1       --当前使用哪个窗口事件
local g_StrParam1 = ""
local g_StrParam2 = ""
local FrameInfoList = {
	YBMARKET_UP_ITEM_COMFIRM 			= 1,			--元宝市场上架物品
	YBMARKET_UP_PET_COMFIRM 			= 2,			--元宝市场上架珍兽
	YBMARKET_BUY_COMFIRM 				= 3,			--元宝市场买东西
	YBMARKET_TAKE_BACK_COMFIRM 			= 4,			--商品下架
	SELL_ITEM_CONFIRM					= 5,			--zhanglei 卖出物品再次确认
	PET_EQUIP_SUITUP_CONFIRM			= 6,
	FRIEND_PRESENT_CONFIRM				= 7,			--好友升级送好礼二次确认
	DEMAIL_PRESENT_CONFIRM				= 8,			--附件邮箱二次确认框
	TAUCTION_BUY_COMFIRM 				= 9,			--T市场买东西
	TAUCTION_UP_COMFIRM 				= 10,			--T市场上架
	TAUCTION_TAKEBACK_COMFIRM 			= 11,			--T市场下架
	CONVENIENT_BUY_CONFIRM	= 13, 	--消费优化，二次确认

	SUPERWEAPONSOULLESS_CONFIRM			= 15,			--神器蜕灵二次确认
	DELETE_COMBOBOOK_CONFIRM			= 16,			--删除武林秘籍二次确认
	--FORBIDIT_CONFIRM							= 17,			--人肉封停二次确认
	QUICKUP_PET_CONFIRM						= 18,			--珍兽快速提升二次确认
	NEW_DAKONG_CONFIRM						= 19,			--新打孔
	NEW_XIANGQIAN_CONFIRM					= 20,			--新镶嵌
	NEW_ZHAICHU_CONFIRM						= 21,			--新摘除
	EQUIP_DECOMPOSE_CONFIRM					= 22,			--装备拆解二次确认
	EQUIP_TEMPER_CONFIRM					= 23,			--装备淬炼二次确认
	EQUIP_TRANSFER_CONFIRM					= 24,			--装备转移二次确认
	EQUIP_UPDATE_CONFIRM					= 25,			--装备升级二次确认
	EQUIP_UPDATE_CONFIRMEX					= 26,			--装备升级用特殊道具确认
	--FORBIDIT_CONFIRMBYNAMEANDFIND		=27,			--人肉封停二次确认
	INFANT_CARD_COMPOSE_CONFIRM = 28,		--卡牌合成确认框
	INFANT_CARD_STRENGTH_CONFIRM = 29,		--卡牌强化确认框
	INFANT_CARD_TRANSFER_CONFIRM = 30,		--卡牌强化转移确认框
	EQUIPLINGPAI_OP_CLOSE_CONFIRM = 31,		--令牌DIY界面关闭确认框
	ZHIZUNHAOLI_CONFIRM				= 32,		--至尊好礼二次确认
	BAOSHI_YI_CONFIRM				= 33,		--宝石乾坤移购买
	EQUIPATTR_CHANGEEQUIP_CONFIRM = 34, --手工装备洗属性更换武器二次确认
	EQUIPATTR_BIND_CONFIRM = 35,	--洗属性将改变装备绑定状态
	SHENDING_RESET_CONFIRM  = 37,	--神木王鼎 重置潜能点 二次确认
	DARK_SKILL_RECOIN_CONFIRM = 38, --暗器技能重洗二次确认
	LW_ATTR_RECOIN_CONFIRM = 39, --龙纹属性重洗二次确认
	SUPER_ATTR_RECOIN_CONFIRM =40,
	HXY_ACTIVE_EFFECT_CONFIRM = 41,
	HXY_RESET_EFFECT_CONFIRM = 42,
	EQUIP_ZIZHI_RECOIN_CONFIRM = 43, --重新鉴定装备资质的二次确认
	WUHUN_SKILL_RECOIN_CONFIRM = 44, --重洗武魂技能的二次确认
	INFANT_SKILL_RECOIN_CONFIRM = 45, --重洗子女技能的二次确认
	PETHUANSE_CONFIRM				= 46,			--附体幻色
	PNEUMA_SWITCHGOLD_CONFIRM	= 47,			--橙元铸金
	DOUBLE_SECKILL_CONFIRM	= 48,
	YBMARKET_CONFIRM_MULTIBUY	= 49,			--元宝交易市场批量购买确认
	TMARKET_CONFIRM_MULTIBUY	= 50,		--G古镜寄售行批量购买确认
	BROTHERSPIRIT_CONFIRM = 52,
	MAKEZONGZI_CONFIRM = 53,	--包粽子还弄什么二次确认，搞毛线
	FORBIDIT_KICKOUT_CONFIRM = 54,			--人肉封停之踢线二次确认
	PLAYERSHOP_CONFIRM_MULTIBUY	= 55,			--九州商会批量购买确认
	USEZHENFA_CONFIRM = 56,					--使用阵法二次确认
	DELETEGXH_CONFIRM  = 57,	--个性化删除二次确认
	SWEAR_CONFIRM = 58,
	CHIXUEQYD_CONFIRM = 59,	--赤血情义丹 二次确认
	ZHIZUN_EQUIP_LEVELUP_CONFIRM = 61 , 	--升灵确认
	ZHIZUN_EQUIP_VIP_TRANSFER_CONFIRM = 62 , --VIP升灵转移确认
	ZHIZUN_EQUIP_TRANSFER_CONFIRM = 63 , 	--升灵转移确认
	CARRIAGE_CANCELIMPACT_CONFIRM = 64,	--取消拉矿变身 二次确认
	FIVE_ELEMENTS_SWITCHTYPE_CONFIRM = 66 ,  --五行宝玉切换属性二次确认
	CLOSE_FIVE_ELEMENTS_WASH_COMFIRM = 67 ,  --关闭五行宝玉淬洗界面二次确认
	FIVE_ELEMENTS_WASH_SWITCH_CONFIRM = 69 ,  --五行淬洗 低值 确认
	--CONFIRM_QUIT_ALLIANCE = 70,	--退出战盟二次确认
	CONFIRM_ACTINGGUILD_KICK = 71, --弹出逐出信息给队伍里的长老帮会
	CARRIAGE_SENDIMPACT_CONFIRM = 72,	--拉矿变身 二次确认
	ALLIANCEKICK_GUILD = 73, --逐出战盟二次确认
	FIVE_ELEMENTS_WASH_NOTSWITCH_CONFIRM = 74 , --淬洗的源气加持百分比大于淬洗前的效果
	FIVE_ELEMENTS_AUTOWASH_CONFIRM = 75 ,  --自动淬洗启动前确认
	PET_HUANTONT_CONFIRM						= 76,			--宠物还童元宝确认 add:lby2015
	PET_RHD_CONFIRM 	= 	77,		--宠物融合元宝确认 add:lby2015
	PET_LINGXING_CONFIRM = 78,	--宠物提灵元宝确认 add:lby2015 
	SECKILL_GIVEUP_CONFIRM = 79, --扫荡丢弃确认
	EQUIP_ATTRFUKE_CONFIRM					= 80,			--装备复刻二次确认 
	ZHENFA_FORGET_CONFIRM = 81,		--遗忘结拜阵法二次确认 
	YINGJIE_EXCHANGE_CONFIRM  = 82,	--百战英杰铸精通
	DRESSGEM_STILETTO_CONFIRM  = 83,
	DRESSGEM_ENCHASE_CONFIRM  = 84,
	JIEHUNHUIKUI_PRIZE_CONFIRM  = 85,--结婚系统奖励回馈设计
	GSEVALUATE_CONFIRM = 86,
	DECOWEAPON_CONVER_CONFIRM = 87,
	DECOWEAPON_LEVELUP_CONFIRM = 88,
	BILLINGAWARD_CONFIRM = 89,		--Billing领取奖励二次提示
	DRESS_TRANSFER_BIND_CONFIRM = 90,
	DRESS_TRANSFER_BUYITEM_CONFIRM = 91,
	AQLY_FLASH_COMFIRM = 92,
	EQUIP_TEMPER_QUERENCONFIRM = 93,
	CONFIRM_IMMIGRATION  = 94,				 -- 移民
	CONFIRM_CANCEL_IMMIGRATION  = 95,				 -- 取消移民
	--APPLYALLIANCE_TEAMCONFIRM = 96,
	--SELECTALLIANCE_CONFIRM = 97,
	SHOULAN_OPERATION_CONFIRM = 98,	--家园兽栏玩法设计 取回珍兽 二次确认
	BIEYEMATERIALOUTPUT_GARDENER_CONFIRM = 99,	--家园养成材料产出玩法设计 付费园丁 二次确认
	BIEYEREMOVE_FURNITURE = 100,
	BIEYE_CREATE_CONFIRM = 101, --开启家园二次确认
	BIEYE_ENTER_WAITING = 102,	--进入家园等待（弃用）
	SHOULAN_PROMOTE_CONFIRM = 103,	--家园兽栏玩法设计 放入珍兽 二次确认
	DIAOWEN_HECHENG_YUANBAO_CONFIRM = 104, --雕纹合成材料快捷购买
	DIAOWEN_BINDYUANBAO_CONFIRM = 105,  --雕纹绑定元宝二次确认
	DIAOWEN_YUANBAO_PAY_CONFIRM = 106, --雕纹拆除快捷购买
	BIEYEMATERIALOUTPUT_COSTYB_CONFIRM = 107,	--家园养成材料产出玩法设计 元宝消费 二次确认
	EQUIP_REPAIRTIMES_CONFIRM						= 108,			--装备修理次数元宝确认 add:lby2016
	SHOPBUY_FURNITURE_CONFIRM	= 109, --买家具去香河 二次确认
	WUHUN_CONVENIENTBUYITEM_CONFIRM						= 110,			--每周十新 消费点 武魂优化 快捷购买确认
	WUHUN_QUICKUP_CONFIRM						= 111,			--每周十新 消费点 武魂优化 快捷提升确认
	RONGHUNDAN_USE_CONFIRM = 112,	--融魂丹使用确认
	RONGHUNDAN_BUY_CONFIRM = 113, --融魂丹购买确认
	PETSKILL_LEVELUP_CONFIRM = 114, --珍兽技能升级快捷确认
	PETSKILL_SHOULANUSE_CONFIRM = 115,	--珍兽兽栏自动使用
	PETSKILL_SHOULANUP_CONFIRM = 116,	--珍兽兽栏自动购买
	CONFIRM_DRESSCLOTH = 117, 					--时装镶嵌
	CONFIRM_SPLITEGEM = 118, 					--时装镶嵌
	BIEYE_FURNITURE_DESTROY_CONFIRM = 119,  --家园销毁家具确认 
	PETEQUIPREFRESH_BUY_CONFIRM  = 120,--珍兽幻化消费优化，二次确认
	PETSINGLEPROCREATE_BUY_CONFIRM  = 121,--珍兽繁殖，二次确认
	PETEQUIP_ZIZHI_RECOIN_CONFIRM = 122, --重新鉴定装备资质的二次确认
	PETYANSHOU_BUY_CONFIRM	= 123, 	--珍兽延寿消费优化，二次确认
	PETXIDIAN_BUY_CONFIRM  = 124,--珍兽洗点消费优化，二次确认
	PETHUANHUA_BUY_CONFIRM  = 125,--珍兽幻化消费优化，二次确认 
	PET_HUANHUA_CONFIRM  	= 126,--珍兽幻化消费优化，二次确认
	DOUBLE_DAILYSECKILL_CONFIRM = 127, --减负副本扫荡
	PETSKILL_LINGSHOUDAN_CONFIRM = 128, --珍兽技能升级灵兽丹快捷购买确认
	BIEYEMATERIALOUTPUT_CANCEL_CONFIRM = 129,	--家园养成材料产出玩法设计 取消 二次确认
	COMMON_CONFIRM = 130, --购买确认
	MARTIAIL_RECYCLEATTRPOINT_CONFIRM = 131,
--	SUPERWEAPON9_CONFIRM = 132, --九星神器
--	SUPERWEAPON9_PIECEEXCHANGE = 133, --升阶道具兑换 确认
	SUPERWEAPONDIYSKILL_CONFIRM  = 134,	--【2017Q3】九星神器升星设计--神器DIY技能效果玩法规则
	SHELIZI_HECHENG_CONFIRM = 135,		--舍利子合成二次确认
	MARTIAL_MULTIITEM_CONFIRM = 136,
	MARTIAL_FREEZE_EXP_CONFIRM = 137,
	BIEYESTYLE_CONFIRM  = 138,	--家园换装二次确认
	MARTAIL_RLEARN_TALENT_CONFIRM = 139, --武意天赋洗点二次确认
	BIEYEPETSINGLEPROCREATE_BUY_CONFIRM  = 140,--家园珍兽繁殖，二次确认
	BIEYEPETPAINT_BUY_CONFIRM  = 141,--家园珍兽染色，二次确认
	SUPERWEAPONDIYSKILL_EXCHANGE  = 142,	--【2017Q3】九星神器升星设计--神器DIY技能效果玩法规则
	WuYi_BUY_CONFIRM  = 143,--武意，二次确认
	SHENQI_JIEMENG_CONFIRM  = 144,--神器解蒙，二次确认
	SECKILL_GIVEUP_CONFIRM_ZHAOHUI = 145, --扫荡丢弃确认
	ZHAOHUI_EXP_CONFIRM = 146, --找回经验 二次确认
	WEIXINQIANDAO_LIBAO_CONFIRM = 147, --微信签到礼包 二次确认
	CONFIRM_ANNIVERSARY  = 148,				 -- 周年庆--消耗元宝
	CONFIRM_CANCEL_ANNIVERSARY  = 149,				 -- 取消消耗元宝
	FANGDENG_CONFIRM = 150, --灯如昼确认
	BALLOON_CONFIRM = 151, --吹气球领奖确认
	BALLOON_GETLIBAO_CONFIRM = 152, --吹气球礼包兑换确认
	APPLY_SNAKING_NUM_SECOND_CONFIRM = 153, --申请摇号二次确认
	SWITCHMENPAI_CONFIRM = 154,--转门派二次确认
	SWITCHMENPAI_RESTART = 155,--转门派最终确认
	SWITCHMENPAI_REGRET = 156,--转门派最终确认
    SWITCHMENPAI_REGRETRESTART = 157,--转门派最终确认
    JINFENGHAODU_CONFIRM = 158,
    JINFENGHAODU_REWARD_CONFIRM = 159,
	PET_LIANHUA_CONFIRM = 160,					--珍兽炼化确认
	USE_PET_HUANLING_ITEM_CONFIRM = 161,		--使用幻灵道具确认
	DROP_ALL_ITEM_INTEMBANK = 162,		--使用幻灵道具确认
	SJ_CAILIAOQIANGHUA_CONFIRM = 163,
	MENU_UPGRADE_CONFIRM = 164,  --食谱升级		
	MENU_UPANDGO_CONFIRM = 165,  --食谱鉴定升级		
	CONFIRM_CCSHOP_REFRESH = 166,	--猜拳商店刷新二次确认
	CONFIRM_CCSHOP_CAIQUAN = 167,	--猜拳商店出拳二次确认	
	CONFIRM_CCSHOP_BUYITEM = 168,	--猜拳商店购买二次确认	
	CONFIRM_CCSHOP_CAIQUAN2 = 169,	--猜拳商店出拳二次确认
	NIANSHOU_NINGYU_CONFIRM = 170,	--年兽凝玉确认
	NIANSHOU_HUANYU_RARE_CONFIRM = 171,	--年兽幻玉稀有确认
	NIANSHOU_HUANYU_BIND_CONFIRM = 172,	--年兽幻玉绑定确认					
	CONFIRM_CCSHOP_CAIQUAN3 = 173,	--猜拳商店出拳二次确认
	CONFIRM_CCSHOP_CAIQUAN4 = 174,	--猜拳商店出拳二次确认			
	CONFIRM_CCSHOP_CAIQUAN5 = 175,	--猜拳商店出拳二次确认
	NIANSHOU_HUANYUUP_BIND_CONFIRM = 176,		--年兽幻玉浣颜绑定确认
	CONFIRM_BS_GUESSING = 177,--比武季后赛竞猜二次确认
	CONFIRM_LEAVEUPMATCH = 180,	--离开上阵比赛界面		
	CHONGZHU_CAILIAO_UP_COMFIRM = 181,	--手工装备重铸材料升级确认		
	CONFIRM_ZNQFUDAI_SELECT = 182,	--周年庆福袋选择道具
	ZHIBU_EXCHANGE_CONFIRM = 183, --京华梦韵兑换二次确认
	ZNQ_BUY_TOKENS_CONFIRM = 184,	--2019周年庆购买代币确认
	FASHION_DEPOT_CONFIRM = 185,	--时装仓库二次确认
	CONFIRM_DUANWULOTTERY = 186,--2019端午抽奖
	CONFIRM_DUANWULOTTERY_CHANGEFRAME = 187,--2019端午抽奖
	GQHYCHOUJIANG_BUY_TOKENS_CONFIRM = 188,	--2019国庆稳活跃抽奖--元宝购买二次确认
	GQHYCHOUJIANG_CONFIRM = 189,	--2019国庆稳活跃抽奖--选择道具未保存确认
	CONFIRM_SZLH = 190,   --2019Q3预充值礼包放出时装礼盒
	CONFIRM_DFS_LEAVEUPMATCH = 191,	--巅峰赛 离开上阵比赛界面
	CONFIRM_YUSHOU = 192,	--预售时装
	CONFIRM_BUYFASHION = 193,	--购买第一件时装
	CONFIRM_BUYSECFASHION = 194,	--购买第二件时装
	CONFIRM_EXCHONGLONG_ITEM = 195, -- 兑换真重楼二次确认
	CONFIRM_FOND = 196,	--基金界面 兑换金珠
    SYJYH_CONFIRM= 197,
    LSS_CONFIRM= 198,
    WGSHOP_CONFIRM= 199,
	ZHIZUN_EQUIP_UPGRADE_CONFIRM=200,
	ZHIZUN_EQUIP_EXCHANGE_CONFIRM=202,
	JINLING_SPECIALITEM = 203,		-- 金陵特殊分发物品
	HEADFRAME_XUQI_CONFIRM = 204,	--头像框续期后超过365天的确认
	GUILD_SAOLEI_CONFIRM = 206, --帮会扫雷二次确认
	FHSXBUY_CONFIRM = 207, --2021双旦集五福
	CHIHUOGUO_CONFIRM = 208, --吃火锅领小奖
	CONFIRM_XINGXIASHOP_BUY = 209,
	DECOWEAPON_LEVELDOWN_CONFIRM = 210,	--幻饰武器熔炼
	CONFIRM_ORNAMENTS_CONFIRM = 211,	--头背挂
	CONFIRM_MRHL = 212,	--墨染华莲礼包
	ERTONGJIEDAIBI_CONFIRM = 213, --【2022Q2】儿童节代币转换
	CONFIRM_PETZHUANXING_PAY = 214, --珍兽转性
	CONFIRM_QIANKUNPOT_SAVE = 215, --乾坤壶存盘二次确认
	CONFIRM_USE_ITEM_ZS = 216,--付费道具
	CONFIRM_USE_ITEM_BR = 217,--付费道具
	CONFIRM_USE_ITEM_FH = 218,--付费道具
	CONFIRM_USE_ITEM_CS = 219,--付费道具
	SAVETREE_CONFIRM = 220,  --拯救树灵
	UNDERARMOUR_WASH_BUY_CONFIRM = 221,	--内甲洗炼元宝购买确认
	UNDERARMOUR_STARUP_BUY_CONFIRM = 222, --内甲升星元宝购买确认
	CONFIRM_CANCEL_ODER_IMMIGRATION = 224, -- 取消定制移民
	DAFUWENG_CONFIRM = 225,
	DAFUWENG_BIND_YUANBAO_CONFIRM = 226,	--绑定元宝
	DAFUWENG_CREATE_GROUP = 227,	--大富翁创建小队 
	DAFUWENG_JOIN_GROUP = 228,		--大富翁加入小队
	DAFUWENG_GROUP_CONFIRM = 229, --锁定小队确定
	CONFIRM_YCLB = 230, --
	CONFIRM_DUANWU_BOAT_MBUY = 231,
	PETNEIDAN_HUAQI_CONFIRM = 232,
	CONFIRM_BUY_ZIWEILINGPO = 233, --紫薇灵魄元宝购买
	CONFIRM_EXCHONGLONG_ITEM_LLMZ = 224, -- 兑换真重楼二次确认
	ZBS_CONFIRM_LEAVEUPMATCH = 235,	--离开上阵比赛界面	
	CONFIRM_RESETTALENTPOINT = 236, --重置宗门天赋点
	CONFIRM_NEWMONTHCARD = 237, --新月卡服月卡购买二次确认
	CONFIRM_BUILD_SNOWMAN = 238, --堆雪人领小奖
	CONFIRM_TLG = 239, --春节应景舔栏杆
	CONFIRM_XLQY = 240, --星火燎原礼盒

	CONFIRM_DRESSJIEQI = 241, --jieqi
	CONFIRM_NAMEBOARDEX_CONFIRM = 242,

	CONFIRM_CHIJIDROPITEM_CONFIRM = 243,
	DAHUA_DAIBI_CONFIRM =244,
	DAHUA_DAIBI_SHOP_CONFIRM=245,
	WENHUOMISSION_CONFIRM = 246, -- 2024Q3版本稳活活动
	XINFUYUCHONG_SHIZHUANGLIHE_CONFIRM = 247, -- 新服预充时装礼盒
	COLSE_CONFIRM_BXDBZ = 248, 
	CONFIRM_FACEAUTH_JIANDAN = 249,
	CONFIRM_FACEAUTH_USEPRIVILIGE = 250,
	CONFIRM_NSHB_DAIBI_MBUY = 251,
	CONFIRM_ZNSZLH = 252,
	MINGSHENGTAOXI_SHIZHUANGLIHE_CONFIRM = 253, -- 新服预充时装礼盒
	EUS_ABANDON_RESULT_CONFIRM = 254,
	EQUIP_UPSTAGE_BIND_CONFIRM = 255,
	EQUIP_UPSTAGE_SAVE_CONFIRM = 256,
	EQUIP_UPSTAGE_NOSAVE_CONFIRM = 257,
	EQUIP_UPSTAGE_REMOVE_CONFIRM = 258,
	PET_STALL_LIST_YUANBAO_CONFIRM			= 259,	--贵重珍兽元宝摊位上架二次确认
	CONFIRM_SEC_KILL_USE_ITEM		= 260,
	CONFIRM_CMLH = 261,
	NEWBAOTU_ENTERFUBEN_CONFIRM			= 262,	--2026Q1藏品藏宝图玩法设计--进副本二次确认
	NEWBAOTU_LEAVEFUBEN1_CONFIRM			= 263,	--2026Q1藏品藏宝图玩法设计--离开副本二次确认
	NEWBAOTU_LEAVEFUBEN2_CONFIRM			= 264,	--2026Q1藏品藏宝图玩法设计--离开副本二次确认
	CONFIRM_MSQXLH = 265,
	CONFIRM_BUY_NEWBAOTU = 266,
	CANGPIN_RANK_BUFF_CONFIRM = 267,

}
--确认框缓存变量，用于点击确定和取消时做处理, 每个变量的意义，根据界面不同各不相同，请使用者用到时自己注释
local g_FrameVar = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

local g_proDes = {"#{AQJJ_160127_147}", "#{AQJJ_160127_148}", "#{AQJJ_160127_149}", "#{AQJJ_160127_150}", "#{ZZZB_150811_182}"}

local g_ReqQualText = 
{
	"#{ZSHP_180814_149}",	--无	品质1
	"#{ZSHP_180814_146}",	--5级	品质2
	"#{ZSHP_180814_145}",	--4级	品质3
	"#{ZSHP_180814_144}",	--4级	品质4
	"#{ZSHP_180814_143}",	--2级	品质5
	"#{ZSHP_180814_142}",	--1级	品质6
	"#{ZSHP_180814_148}",	--至尊	品质7
}

local g_JiuLingStr =
{
	[2] ="#{ZHHD1_181128_60}",
	[3] ="#{ZHHD1_181128_61}",
	[4] ="#{ZHHD1_181128_62}",
	[5] ="#{ZHHD1_181128_63}",
	[6] ="#{ZHHD1_181128_64}",
	[7] ="#{ZHHD1_181128_65}",
	[8] ="#{ZHHD1_181128_66}",
	[9] ="#{ZHHD1_181128_67}",
	[10] ="#{ZHHD1_181128_68}",
}

local g_ChuQuanStr =
{
	[1] ="#{ZHHD1_181128_71}",
	[2] ="#{ZHHD1_181128_72}",
	[3] ="#{ZHHD1_181128_73}",
	[4] ="#{ZHHD1_181128_74}",
	[5] ="#{ZHHD1_181128_75}",
}


local g_PetQualityText = {
	"#{ZSHP_180814_156}",
	"#{ZSHP_180814_155}",
	"#{ZSHP_180814_154}",
	"#{ZSHP_180814_153}",
	"#{ZSHP_180814_152}",
	"#{ZSHP_180814_151}",
	"#{ZSHP_180814_150}",
}

function WuhunQuest_PreLoad()
	this:RegisterEvent("GAME_NOTIFY_INFO_OK");
	this:RegisterEvent("GAME_NOTIFY_INFO_CLOSE");
	this:RegisterEvent("GAME_NOTIFY_INFO_YESNO");
	this:RegisterEvent("UI_COMMAND");
	
		--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);

	this:RegisterEvent("YBMARKET_UP_ITEM_COMFIRM")
	this:RegisterEvent("YBMARKET_UP_PET_COMFIRM")
	this:RegisterEvent("YBMARKET_BUY_COMFIRM")
	this:RegisterEvent("PLAYERSHOP_CONFIRM_MULTIBUY")
	this:RegisterEvent("YBMARKET_CONFIRM_MULTIBUY")
	this:RegisterEvent("TMARKET_CONFIRM_MULTIBUY")
	this:RegisterEvent("YBMARKET_TAKE_BACK_COMFIRM")

	this:RegisterEvent("SELL_ITEM_CONFIRM")
	this:RegisterEvent("PET_EQUIP_SUITUP_CONFIRM")
	this:RegisterEvent("FRIEND_PRESENT_CONFIRM")
	this:RegisterEvent("DEMAIL_PRESENT_CONFIRM")

	this:RegisterEvent("TAUCTION_BUY_COMFIRM")
	this:RegisterEvent("TAUCTION_UP_ITEM_COMFIRM")
	this:RegisterEvent("TAUCTION_TAKE_BACK_COMFIRM")

	this:RegisterEvent("CONVENIENT_BUY_CONFIRM_CLOSE")

	this:RegisterEvent("PLAYER_LEAVE_WORLD")
	this:RegisterEvent("CLOSE_CONFIRM_MULTIBUY")
	this:RegisterEvent("SUPERWEAPONSOULLESS_CONFIRM")
	this:RegisterEvent("DELETE_COMBOBOOK_CONFIRM")
	--this:RegisterEvent("FORBIDIT_CONFIRM")
	this:RegisterEvent("QUICKUP_PET_CONFIRM")
	this:RegisterEvent("EQUIP_DECOMPOSE_CONFIRM")
	this:RegisterEvent("EQUIP_TEMPER_CONFIRM")
	this:RegisterEvent("EQUIP_TEMPER_QUERENCONFIRM")
	this:RegisterEvent("EQUIP_TRANSFER_CONFIRM")
	this:RegisterEvent("EQUIP_UPDATE_CONFIRM")

	--this:RegisterEvent("FORBIDIT_CONFIRMBYNAMEANDFIND")

	this:RegisterEvent("INFANT_CARD_COMPOSE_CONFIRM");
  	this:RegisterEvent("INFANT_CARD_STRENGTH_CONFIRM");
  	this:RegisterEvent("INFANT_CARD_TRANSFER_CONFIRM");
	this:RegisterEvent("EQUIPLINGPAI_OP_CLOSE_CONFIRM")
	this:RegisterEvent("ZHIZUNHAOLI_CONFIRM")
	this:RegisterEvent("EQUIPATTR_CHANGEEQUIP_CONFIRM")
	this:RegisterEvent("EQUIPATTR_BIND_CONFIRM")
	this:RegisterEvent("SHENDING_RESET_CONFIRM")
	this:RegisterEvent("DARK_SKILL_RECOIN_CONFIRM")
	this:RegisterEvent("LW_ATTR_RECOIN_CONFIRM")
	this:RegisterEvent("SUPER_ATTR_RECOIN_CONFIRM")
	this:RegisterEvent("HXY_ACTIVE_EFFECT_CONFIRM")
	this:RegisterEvent("HXY_RESET_EFFECT_CONFIRM")
	this:RegisterEvent("EQUIP_ZIZHI_RECOIN_CONFIRM")
	this:RegisterEvent("WUHUN_SKILL_RECOIN_CONFIRM")
	this:RegisterEvent("INFANT_SKILL_RECOIN_CONFIRM")
	this:RegisterEvent("SECKILL_GIVEUP_CONFIRM")
	this:RegisterEvent("DOUBLE_SECKILL_CONFIRM")
	this:RegisterEvent("PNEUMA_SWITCHGOLD_CONFIRM")	
	this:RegisterEvent("BROTHERSPIRIT_CONFIRM")
	this:RegisterEvent("MAKEZONGZI_CONFIRM")
	this:RegisterEvent("FORBIDIT_KICKOUT_CONFIRM")
	this:RegisterEvent("USEZHENFA_CONFIRM")
	this:RegisterEvent("SWEAR_CONFIRM")
	this:RegisterEvent("CHIXUEQYD_CLOSE")
	this:RegisterEvent("BXDBZ_HIDE_CONFIRM")
	this:RegisterEvent("ZHIZUN_EQUIP_LEVELUP_CONFIRM")
	this:RegisterEvent("ZHIZUN_EQUIP_VIP_TRANSFER_CONFIRM")
	this:RegisterEvent("ZHIZUN_EQUIP_TRANSFER_CONFIRM")
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("FIVE_ELEMENTS_SWITCHTYPE_CONFIRM")
	this:RegisterEvent("CLOSE_FIVE_ELEMENTS_WASH_COMFIRM")
	this:RegisterEvent("FIVE_ELEMENTS_WASH_SWITCH_CONFIRM")
	this:RegisterEvent("ALLIANCEKICK_GUILD")
	this:RegisterEvent("CONFIRM_ACTINGGUILD_KICK")
	this:RegisterEvent("FIVE_ELEMENTS_WASH_NOTSWITCH_CONFIRM")
	this:RegisterEvent("FIVE_ELEMENTS_AUTOWASH_CONFIRM")
	--this:RegisterEvent("EQUIP_ATTRFUKE_CONFIRM")
	this:RegisterEvent("ZHENFA_FORGET_CONFIRM")
	this:RegisterEvent("DRESSGEM_STILETTO_CONFIRM")
	this:RegisterEvent("DRESSGEM_ENCHASE_CONFIRM") 
	this:RegisterEvent("FATIE_SECCONFIRM") 
	this:RegisterEvent("DECOWEAPON_CONVER_CONFIRM")
	this:RegisterEvent("DECOWEAPON_LEVELUP_CONFIRM")
	this:RegisterEvent("BILLINGAWARD_CONFIRM");
	this:RegisterEvent("DRESS_TRANSFER_BIND_CONFIRM")
	this:RegisterEvent("DRESS_TRANSFER_BUYITEM_CONFIRM")
	this:RegisterEvent("AQLY_FLASH_COMFIRM")


	this:RegisterEvent("SHOPBUY_FURNITURE_CONFIRM")
	this:RegisterEvent("PETSKILLLEVELUP_CONFIRM")
	this:RegisterEvent("PET_SHOULAN_AUTOUSE")
	this:RegisterEvent("PET_SHOULAN_AUTOUP")
	this:RegisterEvent("PETEQUIP_ZIZHI_RECOIN_CONFIRM")
	this:RegisterEvent("PET_HUANHUA_CONFIRM")
  this:RegisterEvent("CONFIRM_SPLITEGEM");
  this:RegisterEvent("DOUBLE_DAILYSECKILL_CONFIRM");
  this:RegisterEvent("COMMON_CONFIRM");
  this:RegisterEvent("MARTIAIL_RECYCLEATTRPOINT_CONFIRM")
	this:RegisterEvent("SUPERWEAPON9_MAKESURE");
	this:RegisterEvent("SHELIZI_HECHENG_CONFIRM")
	this:RegisterEvent("MARTIAL_FREEZE_EXP_CONFIRM")
	this:RegisterEvent("MARTAIL_RLEARN_TALENT_CONFIRM")
	this:RegisterEvent("SECKILL_GIVEUP_CONFIRM_ZHAOHUI")
	this:RegisterEvent("APPLY_SNAKING_NUM_SECOND_CONFIRM")
    this:RegisterEvent("JINFENGHAODU_CONFIRM")
    this:RegisterEvent("JINFENGHAODU_REWARD_CONFIRM")
	this:RegisterEvent("PET_LIANHUA_CONFIRM")
	this:RegisterEvent("DROP_ALL_ITEM_IN_TEMBANK")
	this:RegisterEvent("MENU_UPGRADE_CONFIRM",true);
	this:RegisterEvent("MENU_UPANDGO_CONFIRM",true);
	this:RegisterEvent("CCSHOP_CHUQUANCONFIRM",true);
	this:RegisterEvent("NIANSHOU_NINGYU_CONFIRM")
	this:RegisterEvent("NIANSHOU_HUANYU_RARE_CONFIRM")
	this:RegisterEvent("NIANSHOU_HUANYU_BIND_CONFIRM")
	this:RegisterEvent("NIANSHOU_HUANYUUP_BIND_CONFIRM")
	this:RegisterEvent("CONFIRM_ZNQFUDAI_SELECT")
	this:RegisterEvent("GQHYCHOUJIANG_CONFIRM") --2019国庆稳活跃抽奖--选择道具未保存确认
	this:RegisterEvent("FASHION_DEPOT_UPDATE")
	this:RegisterEvent("EXCHONGLONG_ITEM")
	this:RegisterEvent("EXCHONGLONG_ITEM_LLMZ")
	this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_CONFIRM")
	this:RegisterEvent("ZHIZUN_EQUIP_EXCHANGE_CONFIRM")
	this:RegisterEvent("DECOWEAPON_LEVELDOWN_CONFIRM")
	this:RegisterEvent("QIANKUNPOT_CONFIG")
	this:RegisterEvent("DAFUWENG_GROUP_CONFIRM")
	this:RegisterEvent("BXDBZ_COLSE_CONFIRM")
	this:RegisterEvent("EUS_ABANDON_RESULT_CONFIRM")
	this:RegisterEvent("PET_STALL_LIST_YUANBAO_CONFIRM")
	this:RegisterEvent("CLOSE_UNIDENT",false)
end

function WuhunQuest_OnLoad()
	WuhunQuest_Frame_sub:SetProperty("AlwaysOnTop", "True");
end

function WuhunQuestUpdateRect()
	local nWidth, nHeight = WuhunQuest_InfoWindow:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	WuhunQuest_Frame_sub:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

-- OnEvent
function WuhunQuest_OnEvent(event)
	--******************************
	--建议：处理不同的event，请在读出参数后，将逻辑自己写在一个函数内
	--这样可以尽可能的使OnEvent函数能简洁一些不至于像MessageBox界面一样
	--注意：一定要先将参数读出来再传给自己写的函数
	--参考：event == "YBMARKET_UP_ITEM_COMFIRM"
	--*******************************
	if event == "SCENE_TRANSED" then
		if this:IsVisible() and ( g_FrameInfo == FrameInfoList.SWEAR_CONFIRM 
			or g_FrameInfo == FrameInfoList.DIAOWEN_YUANBAO_PAY_CONFIRM 
			or g_FrameInfo == FrameInfoList.CONFIRM_DRESSCLOTH
			or g_FrameInfo == FrameInfoList.BIEYESTYLE_CONFIRM
			or g_FrameInfo == FrameInfoList.MENU_UPGRADE_CONFIRM
			or g_FrameInfo == FrameInfoList.MENU_UPANDGO_CONFIRM			
			or g_FrameInfo == FrameInfoList.CONFIRM_DRESSJIEQI		
			or g_FrameInfo == FrameInfoList.DROP_ALL_ITEM_INTEMBANK			
			or g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_EXCHANGE_CONFIRM
			or g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_UPGRADE_CONFIRM) then
			this:Hide()
		end
		return
	end
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		if this:IsVisible() and (g_FrameInfo == FrameInfoList.MENU_UPGRADE_CONFIRM
								or g_FrameInfo == FrameInfoList.MENU_UPANDGO_CONFIRM		
								or g_FrameInfo == FrameInfoList.CONFIRM_DRESSJIEQI			
								or g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_EXCHANGE_CONFIRM
								or g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_UPGRADE_CONFIRM) then
			this:Hide()	
		end
	end					
	
	if ( event == "GAME_NOTIFY_INFO_OK" ) then
		local str = arg0
		WuhunQuest_Open_Window_OK(str)		--点击后不需要有处理的提示框，只有一个确认按钮，显示信息由参数传入
	
	
	elseif ( event == "GAME_NOTIFY_INFO_CLOSE") then
		local str = arg0
		WuhunQuest_Open_Window_CLOSE(str)
	elseif ( event == "GAME_NOTIFY_INFO_YESNO") then
		local str = arg0
		WuhunQuest_Open_Window_YESNO(str)
	elseif ( event == "YBMARKET_UP_ITEM_COMFIRM" ) then
		local nIndex = tonumber(arg0)
		local nPrice = tonumber(arg1)
		WuhunQuest_Open_Window_YBM_UpItem(nIndex , nPrice)
	elseif ( event == "YBMARKET_UP_PET_COMFIRM" ) then
		local nIndex = tonumber(arg0)
		local nPrice = tonumber(arg1)
		WuhunQuest_Open_Window_YBM_UpPet(nIndex , nPrice)
	elseif ( event == "YBMARKET_BUY_COMFIRM" ) then
		local nType = tonumber(arg0)
		local nIndex =tonumber(arg1)
		local nPrice = tonumber(arg2)
		WuhunQuest_Open_Window_YBM_Buy(nType ,nIndex ,nPrice)
	elseif ( event == "PLAYERSHOP_CONFIRM_MULTIBUY" ) then
		WuhunQuest_Open_Window_PSM_MultiBuy(arg0, arg1, arg2, arg3)
	elseif ( event == "YBMARKET_CONFIRM_MULTIBUY" ) then
		WuhunQuest_Open_Window_YBM_MultiBuy(arg0, arg1, arg2, arg3)
	elseif ( event == "TMARKET_CONFIRM_MULTIBUY" ) then
		WuhunQuest_Open_Window_YBM_TMultiBuy(arg0, arg1, arg2, arg3)
	elseif ( event == "YBMARKET_TAKE_BACK_COMFIRM" ) then
		local nType = tonumber(arg0)
		local nIndex = tonumber(arg1)
		WuhunQuest_Open_Window_YBM_TakeBack(nType , nIndex)
	elseif ( event == "SELL_ITEM_CONFIRM" ) then
		local nItemPos = tonumber(arg0)
		local situation = tonumber(arg1)
		if situation == 1 then
			WuhunQuest_Open_Window_SellItemConfirm(nItemPos);
		elseif situation == 2 or situation == 3 then
			local equipQual = tonumber(arg2)
			if equipQual then
				WuhunQuest_Open_Window_SellItemConfirmQ8(nItemPos,equipQual,situation);
			end
		else
			PlayerPackage:SellCurrItem( nItemPos)
		end
	elseif (event == "PET_EQUIP_SUITUP_CONFIRM") then
		local nType 	= tonumber(arg0)
		local nEquipPos = tonumber(arg1)
		local nItemNum	= tonumber(arg2)
		local nPercent	= tonumber(arg3)
		local nObjCareId= tonumber(arg4)
		WuhunQuest_Open_Window_PetEquipSuitUp(nType, nEquipPos, nItemNum, nPercent, nObjCareId)
	elseif (event == "FRIEND_PRESENT_CONFIRM") then
		local str = arg0
		WuhunQuest_Open_Window_FriendPresentConfirm(str)
	elseif (event == "DEMAIL_PRESENT_CONFIRM") then
		WuhunQuest_Open_Window_MailPresentConfirm(tonumber(arg0))
	elseif (event == "TAUCTION_BUY_COMFIRM") then
		local nType = tonumber(arg0)
		local nIndex =tonumber(arg1)
		local nPrice = tonumber(arg2)
		WuhunQuest_Open_Window_KAuctionBuyConfirm(nType, nIndex, nPrice)
	elseif (event == "TAUCTION_UP_ITEM_COMFIRM") then
		local nType = tonumber(arg0)
		local nIndex =tonumber(arg1)
		local nPrice = tonumber(arg2)
		WuhunQuest_Open_Window_KAuctionUpItemConfirm(nType, nIndex, nPrice)
	--elseif (event == "FORBIDIT_CONFIRMBYNAMEANDFIND") then
	--	local strText = tostring(arg0);
	--	local nName = tostring(arg1)
	--	WuhunQuest_ForbidIt_ConfirmByNameAndID(strText,nName)
	elseif (event == "TAUCTION_TAKE_BACK_COMFIRM") then
		local nType = tonumber(arg0)
		local nIndex =tonumber(arg1)
		WuhunQuest_Open_Window_KAuctionTakeBackConfirm(nType, nIndex)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2015081111 ) then
		local type = Get_XParam_INT(0)
		local buffid = Get_XParam_INT(1)
		WuhunQuest_Open_Window_CarriageCancelImpactConfirm(type, buffid)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 807012 ) then
		WuhunQuest_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0)
		g_FrameVar[2]  = Get_XParam_INT(1)
		g_FrameVar[3]  = Get_XParam_INT(2)
		local targetName = Get_XParam_STR(0);
		local targetServerName = Get_XParam_STR(1)	;		
		local msg =ScriptGlobal_Format( "#{FWQYM_160531_240}", targetName,targetServerName)
		WuhunQuest_InfoWindow:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_IMMIGRATION ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20260120 ) then
		WuhunQuest_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0) --月
		g_FrameVar[2]  = Get_XParam_INT(1) --日
		local msg =ScriptGlobal_Format( "#{SDJF_260113_43}", g_FrameVar[1],g_FrameVar[2])
		WuhunQuest_InfoWindow:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_SEC_KILL_USE_ITEM ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{SDJF_260113_44}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{SDJF_260113_45}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20180407 ) then
		WuhunQuest_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0)
		g_FrameVar[2]  = Get_XParam_INT(1)
		g_FrameVar[3]  = Get_XParam_INT(2)		
		g_FrameVar[4]  = Get_XParam_INT(3)	
		g_FrameVar[5]  = Get_XParam_INT(4)
		g_FrameVar[6]  = Get_XParam_INT(5)
		local strName = PlayerPackage:GetItemName(tonumber(g_FrameVar[5]))
		local msg =ScriptGlobal_Format( "#{BZNMR_170216_09}",g_FrameVar[4], strName, g_FrameVar[6] )
		WuhunQuest_InfoWindow:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_ANNIVERSARY ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20160601 ) then
		WuhunQuest_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0)
		g_FrameVar[2]  = Get_XParam_INT(1)
		g_FrameVar[3]  = Get_XParam_INT(2)
		g_FrameVar[4]  = Get_XParam_INT(3)
		local targetName = Get_XParam_STR(0);
		local targetServerName = Get_XParam_STR(1)	;		
		local msg =ScriptGlobal_Format( "#{FWQYM_160601_252}", targetName,targetServerName)
		WuhunQuest_InfoWindow:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_CANCEL_IMMIGRATION ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2023031401 ) then
		WuhunQuest_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0)
		g_FrameVar[2]  = Get_XParam_INT(1)
		g_FrameVar[3]  = Get_XParam_INT(2)
		g_FrameVar[4]  = Get_XParam_INT(3)
		local targetName = Get_XParam_STR(0);
		local targetServerName = Get_XParam_STR(1)	;		
		local msg =ScriptGlobal_Format( "#{DZYM_20230302_196}", targetName,targetServerName)
		WuhunQuest_InfoWindow:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_CANCEL_ODER_IMMIGRATION ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2022913 ) then
		WuhunQuest_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0)
		g_FrameVar[2]  = Get_XParam_INT(1)
		g_FrameVar[3]  = Get_XParam_INT(2)
		g_FrameVar[4]  = Get_XParam_INT(3)
		local targetName = Get_XParam_STR(0);
		local targetServerName = Get_XParam_STR(1)	;		
		local msg =ScriptGlobal_Format( "#{FWQYM_160601_252}", targetName,targetServerName)
		WuhunQuest_InfoWindow:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_CANCEL_IMMIGRATION ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20170210 ) then
		WuhunQuest_Clear_Var()

		g_FrameVar[1]  = Get_XParam_INT(0)
		if g_FrameVar[1] == 0 then --时装镶嵌
			g_FrameVar[2]  = Get_XParam_INT(1)
			g_FrameVar[3]  = Get_XParam_INT(2)
			WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format( "#{SZZH_170111_68}",g_FrameVar[2],g_FrameVar[2],g_FrameVar[3]*60,g_FrameVar[3]) );
		elseif g_FrameVar[1] == 1 then --时装打孔
			WuhunQuest_InfoWindow:SetText( "#{SZZH_170111_42}" );
		elseif g_FrameVar[1] == 2 then --时装镶嵌绑定
			g_FrameVar[2]  = Get_XParam_INT(1)
			g_FrameVar[3]  = Get_XParam_INT(2)
			g_FrameVar[4]  = Get_XParam_INT(3)
			g_FrameVar[5]  = Get_XParam_INT(4)
			g_FrameVar[6]  = Get_XParam_INT(5)
			WuhunQuest_InfoWindow:SetText( "#{SZZH_170306_146}" );			
		end
		g_FrameInfo = FrameInfoList.CONFIRM_DRESSCLOTH ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2015092911 ) then
		local allianceId = Get_XParam_INT(0)
		local index = Get_XParam_INT(1)
		WuhunQuest_Open_Window_CarriageSendImpactConfirm(allianceId, index)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2015112404 ) then
		local index = Get_XParam_INT(0)
		local itemid = Get_XParam_INT(1)
		local value = Get_XParam_INT(2)
		if index >= 1 and index <= 3 then
			WuhunQuest_Open_Window_YingJieExchangeConfirm(index, itemid, value)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89247102 ) then
		local nType = Get_XParam_INT(0)
		local npcId = Get_XParam_INT(1)
		local bagIndex = Get_XParam_INT(2)
		local slotIndex = Get_XParam_INT(3)
		local impactIndex = Get_XParam_INT(4)		
		local strMsg = Get_XParam_STR(0)
		if nType >= 1 and nType <= 5 then
			WuhunQuest_Open_Window_SuperWeaponDIYSkillConfirm( strMsg, nType, npcId, bagIndex, slotIndex, impactIndex )
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89247201 ) then
		local npcId = Get_XParam_INT(0)
		local nIndex = Get_XParam_INT(1)
		local strMsg = Get_XParam_STR(0)
		WuhunQuest_Open_Window_SuperWeaponDIYSkillExchange( strMsg, npcId, nIndex )
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88880110 ) then--2021双旦集五福
		local nIndex = Get_XParam_INT(0)
		local strMsg = Get_XParam_STR(0)
		WuhunQuest_Open_Window_FHSXBuyConfirm( nIndex, strMsg )
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2023052401 ) then--紫薇灵魄购买
		local nIndex = Get_XParam_INT(0)
		local nTargetId = Get_XParam_INT(1)
		local strMsg = Get_XParam_STR(0)
		WuhunQuest_Open_Window_ZWLPBuyConfirm( nIndex, nTargetId, strMsg )
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99802503 ) then--【2022Q2】儿童节代币转换
		local nItemId = Get_XParam_INT(0)
		local nNum = Get_XParam_INT(1)
		local strMsg = Get_XParam_STR(0)
		WuhunQuest_Open_Window_ErTongJieDaiBiConfirm( nItemId, nNum, strMsg )
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88881101 ) then--吃火锅
		local targetid = Get_XParam_INT(0)
		local score = Get_XParam_INT(1)
		WuhunQuest_Open_Window_CHGConfirm(targetid, score)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99896405 ) then--堆雪人
		local targetid = Get_XParam_INT(0)
		local score = Get_XParam_INT(1)
		WuhunQuest_Open_Window_BSnConfirm(targetid, score)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99898201 ) then--春节应景舔栏杆二次确认
		local targetid = Get_XParam_INT(0)
		WuhunQuest_Open_Window_TLGConfirm(targetid)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99822701 ) then--拯救树灵
		local targetid = Get_XParam_INT(0)
		local score = Get_XParam_INT(1)
		WuhunQuest_Open_Window_STConfirm(targetid, score)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2016051913 ) then
		local npcid = Get_XParam_INT(0)
		local index = Get_XParam_INT(1)
		local strMsg = Get_XParam_STR(0)
		if index >= 1 and index <= 3 then
			WuhunQuest_Open_Window_ShouLanOperationConfirm(npcid, index, strMsg)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99890802) then	--新月卡服月卡
		local newMonthcardType = Get_XParam_INT(0)
		local buyMonthcardType = Get_XParam_INT(1)
		WuhunQuest_New_MonthCard_OperationConfirm(newMonthcardType,buyMonthcardType)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2016051915 ) then
		local nSelectLevel = Get_XParam_INT(0)
		local nOperType = Get_XParam_INT(1)
		local petGuidH = Get_XParam_INT(2)
		local petGuidL = Get_XParam_INT(3)
		local timeLevel = Get_XParam_INT(4)
		local strMsg = Get_XParam_STR(0)
		if nOperType >= 1 and nOperType <= 2 then
			WuhunQuest_Open_Window_ShouLanPromoteConfirm(nSelectLevel, nOperType, petGuidH, petGuidL, timeLevel, strMsg)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2016062112 ) then
		local npcid = Get_XParam_INT(0)
		local nMissionType = Get_XParam_INT(1)
		local nBuildIndex = Get_XParam_INT(2)
		local nOutputID = Get_XParam_INT(3)
		local strMsg = Get_XParam_STR(0)
		if nMissionType >= 1 and nMissionType <= 9 then
			WuhunQuest_Open_Window_BieYeMaterialOutputGardenerConfirm(npcid, nMissionType, nBuildIndex, nOutputID, strMsg)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2016062113 ) then
		local npcid = Get_XParam_INT(0)
		local nMissionType = Get_XParam_INT(1)
		local nBuildIndex = Get_XParam_INT(2)
		local nOutputID = Get_XParam_INT(3)
		local strMsg = Get_XParam_STR(0)
		if nMissionType >= 1 and nMissionType <= 3 then
			WuhunQuest_Open_Window_BieYeMaterialOutputCostYBConfirm(npcid, nMissionType, nBuildIndex, nOutputID, strMsg)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017070311 ) then
		local npcid = Get_XParam_INT(0)
		local nMissionType = Get_XParam_INT(1)
		local nBuildIndex = Get_XParam_INT(2)
		local strMsg = Get_XParam_STR(0)
		if nMissionType >= 1 and nMissionType <= 3 then
			WuhunQuest_Open_Window_BieYeMaterialOutputCancelConfirm(npcid, nMissionType, nBuildIndex, strMsg)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89173902 ) then
		local strMsg = Get_XParam_STR(0)
		local tabIndex = Get_XParam_INT(0)
		local selectIndex = Get_XParam_INT(1)
		WuhunQuest_Open_Window_JieHunHuiKuiPrizeConfirm( strMsg, tabIndex, selectIndex  )
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20150706 ) then
		local strMsg = Get_XParam_STR(0);
		local nType = Get_XParam_INT(0);
		local nIndex = Get_XParam_INT(1);
		WuhunQuest_Open_Window_DeleteGXHConfirm(strMsg, nType, nIndex);
		--取消鼠标特殊状态
		SetDefaultMouse()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20120222 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		local nBuyCount = Get_XParam_INT(7);
		if nBuyCount == nil or nBuyCount < 1 then
			nBuyCount = 1
		end
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID, nBuyCount );
		else
			WuhunQuest_Open_Window_ConvenintBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID, nBuyCount );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017011301 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_PetSkillStudy_YanShou = 1
		else
			WuhunQuest_Open_Window_PetYanShouBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017011701 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_PetSkillStudy_XiDian = 1
		else
			WuhunQuest_Open_Window_PetXiDianBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017020701 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_PetSkillStudy_HuanHua = 1
		else
			WuhunQuest_Open_Window_PetHuanHuaBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017021501 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_PetEquip_Refresh = 1
		else
			WuhunQuest_Open_Window_PetEquipRefreshBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017021502 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_PetEquip_SignleProcreate_Buy = 1
		else
			WuhunQuest_Open_Window_PetSignleProcreateBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017092001 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_BieYePet_SignleProcreate_Buy = 1
		else
			WuhunQuest_Open_Window_BieYePetSignleProcreateBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017111601 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		else
			WuhunQuest_Open_Window_WuYiBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 920171117 ) then
		local strMsg = Get_XParam_STR(0)
		WuhunQuest_Open_Window_ShenqiJiemengConfirm(strMsg)
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017112101 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2017092601 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local nType = Get_XParam_INT(0);
		local nCurrencyUnit = Get_XParam_INT(1);
		local nPrice = Get_XParam_INT(2);
		local nItemIndex = Get_XParam_INT(3);
		local nSerialNum = Get_XParam_INT(4);
		local nScriptID = Get_XParam_INT(5);
		local nYuanbaoPay = Get_XParam_INT(6);
		if nYuanbaoPay == nil or nYuanbaoPay ~= 1 then
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_BieYePet_Paint_Buy = 1
		else
			WuhunQuest_Open_Window_BieYePetPaintBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2013060604 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_DakongConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_StilettoEx_Material_Buy = 1
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2016112510 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_WuHunConvenientBuyItemConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_WuHun_Material_Buy = 1
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2016120110 ) then
		local nType = Get_XParam_INT(0);
		local nIndex = Get_XParam_INT(1);
		local nParam = Get_XParam_INT(2);
		local strMsg = Get_XParam_STR(0);
		WuhunQuest_Open_Window_WuHunQuickUpConfirm( nType, nIndex, nParam, strMsg );
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2015101414 ) then  --add:lby2015还童
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_HuantongConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20161108 ) then  --add:lby2016装备修理次数
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_EquipRepairConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2015101511 ) then  --add:lby2015融合
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_RHDConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99814402 ) then --珍兽转性 这个notify 01 真是奇葩 
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 0 then
			WuhunQuest_Open_Window_ZXConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2015101514 ) then  --add:lby2015提灵
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_LingxingConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2013060605 ) then

		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_XiangqianConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_EnchaseEx_Material_Buy = 1
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2013060606 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_ZhaichuConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
			g_SplitGemEx_Material_Buy = 1
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20150122 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_PetHuanSeConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 80927201 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		local nNum = Get_XParam_INT(6);
		if notify == 1 then
			WuhunQuest_Open_Window_DWBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID,nNum );
		else
			ConvenientBulkBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID,nNum);
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 80927202 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_DWBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, 1 );
		else
			ConvenientBulkBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID,1);
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 80927203 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		if notify == 1 then
			WuhunQuest_Open_Window_DWBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, 1 );
		else
			ConvenientBulkBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID,1);
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89306002 ) then--2018比武季后赛竞猜
		WuhunQuest_Clear_Var()
		
		g_FrameVar[1]  = tostring(arg1)
		g_FrameVar[2]  = tonumber(arg2)--阶段索引
		g_FrameVar[3]  = tonumber(arg3)--场次索引
		g_FrameVar[4]  = tonumber(arg4)--支持的左边还是右边 1 左 2 右
		g_FrameVar[5]  = tonumber(arg5)--teamId
		local msg = ScriptGlobal_Format( "#{JHSJC_190120_29}", g_FrameVar[1])
		WuhunQuest_InfoWindow:SetText(msg);	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_BS_GUESSING ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{JHSJC_190120_30}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{JHSJC_190120_31}");  --取消
		WuhunQuestUpdateRect();
		this:Show();

	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50508703 ) then--2019端午抽奖CONFIRM_DUANWULOTTERY_CHANGEFRAME
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = tonumber(arg1)--奖池
		g_FrameVar[2]  = tonumber(arg2)--
		g_FrameVar[3]  = tonumber(arg3)--
		g_FrameVar[4]  = tonumber(arg4)--
		g_FrameVar[5]  = tonumber(arg5)--

		local msg
		if g_FrameVar[1] == 1 then
			msg = ScriptGlobal_Format( "#{DWKC_190502_36}", 4)
		elseif g_FrameVar[1] == 2 then
			msg = ScriptGlobal_Format( "#{DWKC_190502_36}", 3)
		elseif g_FrameVar[1] == 3 then
			msg = ScriptGlobal_Format( "#{DWKC_190502_36}", 2)
		elseif g_FrameVar[1] == 4 then
			msg = ScriptGlobal_Format( "#{DWKC_190502_36}", 2)
		elseif g_FrameVar[1] == 5 then
			msg = ScriptGlobal_Format( "#{DWKC_190502_36}", 1)
		else
			return
		end
		WuhunQuest_InfoWindow:SetText(msg);	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_DUANWULOTTERY ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{JHSJC_190120_30}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{JHSJC_190120_31}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99955202 ) then--社区规则限制服购买剑胆
		WuhunQuest_SocialRuleLimit_BuyJianDan_OperationConfirm()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50508704 ) then--2019端午抽奖
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = tonumber(arg1)--奖池
		WuhunQuest_InfoWindow:SetText("#{DWKC_190502_37}");	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_DUANWULOTTERY_CHANGEFRAME ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{JHSJC_190120_30}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{JHSJC_190120_31}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99820001 ) then--付费道具
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = Get_XParam_INT(0)--nBagIndex
		WuhunQuest_InfoWindow:SetText("#{FFZQ_220803_06}");	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_USE_ITEM_ZS ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{FFZQ_220803_07}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{FFZQ_220803_08}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99820101 ) then--付费道具
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = Get_XParam_INT(0)--nBagIndex
		WuhunQuest_InfoWindow:SetText("#{FFZQ_220803_42}");	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_USE_ITEM_BR ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{FFZQ_220803_07}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{FFZQ_220803_08}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99820201 ) then--付费道具
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = Get_XParam_INT(0)--nBagIndex
		WuhunQuest_InfoWindow:SetText("#{FFZQ_220803_16}");	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_USE_ITEM_FH ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{FFZQ_220803_07}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{FFZQ_220803_08}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99820301 ) then--付费道具
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = tonumber(arg1)--nBagIndex
		WuhunQuest_InfoWindow:SetText("#{FFZQ_220803_26}");	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_USE_ITEM_CS ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{FFZQ_220803_07}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{FFZQ_220803_08}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50508710 ) then
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = Get_XParam_INT(0)
		g_FrameVar[2]  = Get_XParam_INT(1)
		WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format( "#{DWKC_20210508_18}", g_FrameVar[2], g_FrameVar[1]));	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_DUANWU_BOAT_MBUY ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{FFZQ_220803_07}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{FFZQ_220803_08}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50101602 ) then
		WuhunQuest_Clear_Var()
		local strMsg = Get_XParam_STR(0);
		g_FrameVar[1]  = Get_XParam_INT(0) 
		WuhunQuest_InfoWindow:SetText(strMsg);	--
		g_FrameInfo = FrameInfoList.CONFIRM_NSHB_DAIBI_MBUY ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{FFZQ_220803_07}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{FFZQ_220803_08}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
--	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 7020064 ) then
--		local chipcnt = Get_XParam_INT(0);
--		WuhunQuest_PieceExchange(chipcnt)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88896303 ) then
		WuhunQuest_Clear_Var()
		local nYuanBao = Get_XParam_INT(0)
		g_FrameVar[1]  = Get_XParam_INT(1)
		local opt  = Get_XParam_INT(2)--num
		if opt == 1 then
			WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format( "#{XXSD_220209_69}", nYuanBao, g_FrameVar[1]));	-- 设置内容
		else
			WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format( "#{XXSD_220209_70}", nYuanBao, g_FrameVar[1]));	-- 设置内容
		end
		
		g_FrameInfo = FrameInfoList.CONFIRM_XINGXIASHOP_BUY ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{XXSD_220209_61}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{XXSD_220209_62}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88899301 ) then
		WuhunQuest_Clear_Var()
		local nType = Get_XParam_INT(0);
		local nName = Get_XParam_STR(0);
		WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCLB_190819_87}",nName ))
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_MRHL
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50102001 ) then
		WuhunQuest_Clear_Var()
		local nType = Get_XParam_INT(0);
		local nName = Get_XParam_STR(0);
		WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCLB_250321_3}",nName ))
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_ZNSZLH
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50102101 ) then
		WuhunQuest_Clear_Var()
		local nType = Get_XParam_INT(0);
		local nName = Get_XParam_STR(0);
		WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCLB_240911_18}",nName ))
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_MSQXLH
		this:Show();
	elseif ( event == "CONFIRM_SPLITEGEM" ) then
		WuhunQuest_Clear_Var()
		g_FrameVar[1]  = tonumber( arg1 )
		g_FrameVar[2]  = tonumber( arg0 )
		WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format( "#{SZZH_170111_87}",g_FrameVar[2],g_FrameVar[1]*15,g_FrameVar[1]) );
		g_FrameInfo = FrameInfoList.CONFIRM_SPLITEGEM ;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif ( event == "CONVENIENT_BUY_CONFIRM_CLOSE" ) then
		WuhunQuest_Bn2Click();

	elseif ( event == "SUPERWEAPONSOULLESS_CONFIRM") then
		local nParam = tonumber(arg0)
		if nParam >= 0 then
			WuhunQuest_SuperWeaponSoulless_Confirm(nParam);
		end
	elseif ( event == "DELETE_COMBOBOOK_CONFIRM") then
		 local nParam = tonumber(arg0)
		 if nParam >= 0 then
			 WuhunQuest_DeleteComboBook_Confirm(nParam);
		 end
	elseif ( event == "PLAYER_LEAVE_WORLD") then
		if (g_FrameInfo == FrameInfoList.PLAYERSHOP_CONFIRM_MULTIBUY
		or g_FrameInfo == FrameInfoList.YBMARKET_CONFIRM_MULTIBUY
		or g_FrameInfo == FrameInfoList.TMARKET_CONFIRM_MULTIBUY
		or g_FrameInfo == FrameInfoList.CARRIAGE_CANCELIMPACT_CONFIRM
		or g_FrameInfo == FrameInfoList.CARRIAGE_SENDIMPACT_CONFIRM
		or g_FrameInfo == FrameInfoList.SHOULAN_OPERATION_CONFIRM
		or g_FrameInfo == FrameInfoList.SHOULAN_PROMOTE_CONFIRM
		or g_FrameInfo == FrameInfoList.BIEYEMATERIALOUTPUT_GARDENER_CONFIRM
		or g_FrameInfo == FrameInfoList.BIEYEMATERIALOUTPUT_COSTYB_CONFIRM
		or g_FrameInfo == FrameInfoList.BIEYEMATERIALOUTPUT_CANCEL_CONFIRM
		or g_FrameInfo == FrameInfoList.ZHENFA_FORGET_CONFIRM
		or g_FrameInfo == FrameInfoList.DOUBLE_SECKILL_CONFIRM
		or g_FrameInfo == FrameInfoList.SECKILL_GIVEUP_CONFIRM
		or g_FrameInfo == FrameInfoList.SECKILL_GIVEUP_CONFIRM_ZHAOHUI
		or g_FrameInfo == FrameInfoList.DECOWEAPON_CONVER_CONFIRM
		or g_FrameInfo == FrameInfoList.DECOWEAPON_LEVELUP_CONFIRM
		or g_FrameInfo == FrameInfoList.SECKILL_GIVEUP_CONFIRM_ZHAOHUI
		or g_FrameInfo == FrameInfoList.ZHAOHUI_EXP_CONFIRM
		or g_FrameInfo == FrameInfoList.SHOPBUY_FURNITURE_CONFIRM)  
		or g_FrameInfo == FrameInfoList.DOUBLE_DAILYSECKILL_CONFIRM then 
			this:Hide();
		end
	elseif ( event == "CLOSE_CONFIRM_MULTIBUY") then
		if (g_FrameInfo == FrameInfoList.PLAYERSHOP_CONFIRM_MULTIBUY 
		or g_FrameInfo == FrameInfoList.YBMARKET_CONFIRM_MULTIBUY
		or g_FrameInfo == FrameInfoList.TMARKET_CONFIRM_MULTIBUY) then
			this:Hide();
		end
	--elseif ( event == "FORBIDIT_CONFIRM" ) then	--人肉封停二次确认
	--	local strText = tostring(arg0);
	--	WuhunQuest_ForbidIt_Confirm( strText );
	elseif ( event == "QUICKUP_PET_CONFIRM") then
		 local nType = tonumber(arg0); 			--1是悟性，2是灵性，3是融合度，4是成长率
		 local nCurData --= tonumber(arg1); 	--当前悟性、灵性、融合度、成长率
		 if nType == 4 then
		 	 nCurData = tostring(arg1);
		 else
		 	 nCurData = tonumber(arg1);
		 end
		 local nPrice = tonumber(arg2);			--元宝数
		 local nUplimit = tonumber(arg3);		--成长率上限
		 local strMsg = tostring(arg4); 		--宠物名字
		 WuhunQuest_QuickUpPet_Confirm(nType,nCurData,nPrice,nUplimit,strMsg);
	elseif ( event == "EQUIP_DECOMPOSE_CONFIRM") then
		 local equiplock = tonumber(arg0);
		 local GetStrengthenLevel = tonumber(arg1);
		 local IsHaveAttaProperty = tonumber(arg2);
		 local bHaveSL = tonumber(arg3);
		 WuhunQuest_EquipDecompose_Confirm(equiplock,GetStrengthenLevel,IsHaveAttaProperty,bHaveSL);
	elseif ( event == "EQUIP_TEMPER_CONFIRM") then
		WuhunQuest_EquipTemper_Confirm()
	elseif (event == "EQUIP_TEMPER_QUERENCONFIRM") then
		WuhunQuest_EquipTemper_QueRenConfirm(arg0,tonumber(arg1),tonumber(arg2))
	elseif ( event == "EQUIP_TRANSFER_CONFIRM") then
		WuhunQuest_EquipTransfer_Confirm(tonumber(arg0))
	elseif ( event == "EQUIP_UPDATE_CONFIRM") then
		if(tonumber(arg0) == 0) then
			WuhunQuest_EquipUpdate_Confirm()
		elseif(tonumber(arg0) == 1) then
			WuhunQuest_EquipUpdate_ConfirmEx(tonumber(arg1))
		end
	elseif (event == "INFANT_CARD_COMPOSE_CONFIRM") then
		WuhunQuest_InfantCardCompose_Confirm()

	elseif (event == "INFANT_CARD_STRENGTH_CONFIRM") then
		WuhunQuest_InfantCardStrength_Confirm()

	elseif (event == "INFANT_CARD_TRANSFER_CONFIRM") then
		WuhunQuest_InfantCardTransfer_Confirm()

	elseif event == "EQUIPLINGPAI_OP_CLOSE_CONFIRM" then
		WuhunQuest_EquipLingPai_OpClose_Confirm()
	elseif event == "ZHIZUNHAOLI_CONFIRM" then
		 local ybcost = tonumber(arg0);
		 local itemcount = tonumber(arg1);
		 local freecount = tonumber(arg2);
		 local nType = tonumber(arg3);
		WuhunQuest_Zhizunhaoli_Confirm(ybcost,itemcount,freecount,nType)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2014061704 ) then
		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(1);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		local nNum	= Get_XParam_INT(6);
		if notify == 1 then
			WuhunQuest_Open_Window_BaoShiyiConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID,nNum );
		else
			ConvenientBulkBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID,nNum);

		end
	elseif event == "EQUIPATTR_CHANGEEQUIP_CONFIRM" then
		local npocketIndex = tonumber(arg0);
		local keepopen = tonumber(arg1);
		WuhunQuest_Equipattr_confirm(npocketIndex,keepopen)
	elseif event == "EQUIPATTR_BIND_CONFIRM" then
		local itemid = tonumber(arg0)
		WuhunQuest_Equipattr_bindconfirm(itemid)
	elseif tostring(event) == "DOUBLE_SECKILL_CONFIRM" then
		WuhunQuest_Clear_Var()
		g_FrameVar[1] = tonumber(arg0) --操作类型 1消耗元宝 2消耗元宝+消耗低级和高级扫荡点 3消耗低级和高级扫荡点
		g_FrameVar[2]= tonumber(arg1) --BossIndex
		g_FrameVar[3] = tonumber(arg2) --元宝
		g_FrameVar[4] = tonumber(arg3) --副本ID
		WuhunQuest_DoubleSeckill_confirm()
		return
	elseif event == "DECOWEAPON_CONVER_CONFIRM" then
		local BagPos = tonumber(arg0)
		WhunQuest_DecoWeaponConver_confirm(BagPos)
	elseif event == "DECOWEAPON_LEVELUP_CONFIRM" then
		local WeaponBagPos = tonumber(arg0)
		WhunQuest_DecoWeaponLevelup_confirm(WeaponBagPos)
	elseif event == "SECKILL_GIVEUP_CONFIRM" then
		WuhunQuest_SeckillGiveUp_confirm()
	elseif event == "SECKILL_GIVEUP_CONFIRM_ZHAOHUI" then
		WuhunQuest_SeckillGiveUp_ZhaoHui_confirm()
	elseif event == "SHENDING_RESET_CONFIRM" then
		local nScriptId = tonumber(arg0)
		WuhunQuest_ShenDing_Reset_confirm( nScriptId )
	elseif event == "DARK_SKILL_RECOIN_CONFIRM" then
		local npocketIndex = tonumber(arg0);
		local keepopen = tonumber(arg1);
		WuhunQuest_DarkSkill_confirm(npocketIndex,keepopen)
	elseif event == "LW_ATTR_RECOIN_CONFIRM" then
		local npocketIndex = tonumber(arg0);
		local keepopen = tonumber(arg1);
		WuhunQuest_LW_ATTR_confirm(npocketIndex,keepopen)

	elseif event == "SUPER_ATTR_RECOIN_CONFIRM" then
		local npocketIndex = tonumber(arg0);
		local keepopen = tonumber(arg1);
		WuhunQuest_Super_ATTR_confirm(npocketIndex,keepopen)

	elseif event == "HXY_ACTIVE_EFFECT_CONFIRM" then
		local nEffectIndex = tonumber(arg0)
		WuhunQuest_HxyEffectActiveConfirm(nEffectIndex )
	elseif event == "HXY_RESET_EFFECT_CONFIRM" then
		local nBagIndex = tonumber(arg0)
		WuhunQuest_HxyEffectResetConfirm(nBagIndex)
	elseif event == "EQUIP_ZIZHI_RECOIN_CONFIRM" then
		local npocketIndex = tonumber(arg0);
		local keepopen = tonumber(arg1);
		WuhunQuest_EquipZiZhi_confirm(npocketIndex,keepopen)
	elseif event == "PETEQUIP_ZIZHI_RECOIN_CONFIRM" then
		local npocketIndex = tonumber(arg0);
		local keepopen = tonumber(arg1);
		WuhunQuest_PetEquipZiZhi_confirm(npocketIndex,keepopen)
	elseif event == "WUHUN_SKILL_RECOIN_CONFIRM" then
		local npocketIndex = tonumber(arg0);
		local keepopen = tonumber(arg1);
		WuhunQuest_WuhunSkill_confirm(npocketIndex,keepopen)
	elseif event == "INFANT_SKILL_RECOIN_CONFIRM" then

		WuhunQuest_InfantSkill_confirm(npocketIndex,keepopen)
	elseif event == "PNEUMA_SWITCHGOLD_CONFIRM" then
		local strName = tostring(arg0)
		local strType = tostring(arg1)
		WuhunQuest_Pneuma_SwitchGold_confirm( strName, strType )
	elseif event == "BROTHERSPIRIT_CONFIRM" then
		local index = tostring(arg0)
		WuhunQuest_BROTHERSPIRIT_CONFIRM(index)
	elseif event == "MAKEZONGZI_CONFIRM" then
		local index = tonumber(arg0)
		WuhunQuest_MAKEZONGZI_CONFIRM(index)
	elseif ( event == "FORBIDIT_KICKOUT_CONFIRM" ) then	--人肉封停之踢线二次确认
		local strText = tostring(arg0);
		WuhunQuest_ForbidIt_KickOut_Confirm( strText );
	elseif (event == "USEZHENFA_CONFIRM") then
			-- 检测安全时间
		if tonumber(DataPool:GetLeftProtectTime()) > 0 then
			PushDebugMessage("#{JBGXW_150526_34}")     						-- "安全时间内不能卸载休闲动作包"
			return
		end

		local skillid = tonumber(arg0)
		WuhunQuest_UseZhenfa_Confirm(skillid)
	elseif (event == "SHOPBUY_FURNITURE_CONFIRM") then

		local nSelect = tonumber(arg0)
		WuhunQuest_ShopBuy_Furniture_Confirm(nSelect)
	elseif (event =="SWEAR_CONFIRM") then
		if tonumber(arg0) == 0 or  tonumber(arg0) == 1 then
			WuhunQuest_Swear_Confirm( tostring(arg1) , tonumber(arg0) )
		elseif tonumber(arg0) == 2 then
			if g_FrameInfo == FrameInfoList.SWEAR_CONFIRM then
				this:Hide()
			end
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20150717 ) then
		WuhunQuest_ChiXueQYD_Confirm()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89183702 ) then
		WuhunQuest_DestroyFurniture_Confirm()
	elseif  (event =="CHIXUEQYD_CLOSE") then
		if(this:IsVisible() and  g_FrameInfo == FrameInfoList.CHIXUEQYD_CONFIRM) then
			this:Hide();
		end
		return;
	elseif  (event =="BXDBZ_HIDE_CONFIRM") then
		if(this:IsVisible() and  g_FrameInfo == FrameInfoList.COLSE_CONFIRM_BXDBZ) then
			this:Hide()
		end
		return
	elseif event == "ZHIZUN_EQUIP_LEVELUP_CONFIRM" then
		WuhunQuest_ZZELevelup_Confirm( tonumber(arg0), tonumber(arg1)  )	
		return
	elseif event == "ZHIZUN_EQUIP_VIP_TRANSFER_CONFIRM" then
		WuhunQuest_ZZEVipTransfer_Confirm( tonumber(arg0)  ,tonumber(arg1) ,tonumber(arg2))	
		return
	elseif event == "ZHIZUN_EQUIP_TRANSFER_CONFIRM" then
		WuhunQuest_ZZETransfer_Confirm( tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3) )	
		return

	elseif event == "FIVE_ELEMENTS_SWITCHTYPE_CONFIRM" then
		WuhunQuest_FiveElementsSwitchType_Confirm( tonumber(arg0) ,tonumber(arg1) , tonumber(arg2)  )	
		return
	elseif event == "CLOSE_FIVE_ELEMENTS_WASH_COMFIRM"	then
		WuhunQuest_FiveElementsWashClose_Confirm()
		return
	elseif event == "FIVE_ELEMENTS_WASH_SWITCH_CONFIRM"	then
		WuhunQuest_FiveElementsWashSwitch_Confirm(tonumber(arg0) )
		return	
	elseif event == "ALLIANCEKICK_GUILD" then
		WuhunQuest_Alliancekick_guild(tostring(arg0),tonumber(arg1),tonumber(arg2));
		return
	elseif event == "CONFIRM_ACTINGGUILD_KICK" then
		WuhunQuest_Confirm_ActingGuildKick(tostring(arg0))
		return
	elseif event == "FIVE_ELEMENTS_WASH_NOTSWITCH_CONFIRM"	then
		WuhunQuest_FiveElementsWashNotSwitch_Confirm(tonumber(arg0) )
		return
	elseif event == "FIVE_ELEMENTS_AUTOWASH_CONFIRM"	then
		WuhunQuest_FiveElementsWashAutoStart_Confirm()
		return	
	elseif ( event == "EQUIP_ATTRFUKE_CONFIRM") then
		WuhunQuest_EquipFuKe_Confirm()
	elseif event == "ZHENFA_FORGET_CONFIRM" then
		WuhunQuest_ZhenfaForget_Confirm(tonumber(arg0) )
		return	
	elseif event == "DRESSGEM_STILETTO_CONFIRM"	then
		--WuhunQuest_DressGem_Stiletto_Confirm(tonumber(arg0),tonumber(arg1),tonumber(arg2))
		WuhunQuest_DressGem_Stiletto_Confirm(tonumber(arg0),tostring(arg1))
		return
	elseif event == "DRESSGEM_ENCHASE_CONFIRM"	then
		WuhunQuest_DressGem_Enchase_Confirm(tonumber(arg0),tonumber(arg1),tonumber(arg2),
																			  tonumber(arg3),tonumber(arg4),tonumber(arg5),
																			  tonumber(arg6),tonumber(arg7),tonumber(arg8),tonumber(arg9))
		return	
	elseif event == "FATIE_SECCONFIRM" and arg0 == "confirm"then
		WuhunQuest_GSEvaluate_Confirm()
		return
	elseif (event == "BILLINGAWARD_CONFIRM") then
		local nIndex = tonumber(arg0);
		if nIndex == -1 then
			this:Hide();
		else
			local strText = tostring(arg1)
			WuhunQuest_BillingAward_Confirm( strText, nIndex )
		end
		return
	elseif event == "DRESS_TRANSFER_BIND_CONFIRM" then
		WuhunQuest_Dress_Transfer_Bind_Confirm()
		return
	elseif event == "DRESS_TRANSFER_BUYITEM_CONFIRM" then
		local nBuyType = tonumber(arg4)
		local nCurrencyUnit = tonumber(arg5)
		local nPrice = tonumber(arg3)
		local nItemIndex = tonumber(arg6)
		local nSerialNum = tonumber(arg7)
		local nUniqueID = tostring(arg0)
		local nBuyNum = tonumber(arg2)
		local nNeedItemNum = tonumber(arg1)
		local bBuyConfirm = tonumber(arg8)
				
		if bBuyConfirm == 1 then
			WuhunQuest_Dress_Transfer_BuyItem_Confirm(nUniqueID,nNeedItemNum,nBuyNum,nPrice,nBuyType,nCurrencyUnit,nItemIndex,nSerialNum)
		else
			ConvenientBulkBuyItem(nBuyType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID,nBuyNum)
		end
		
		return
	elseif event == "AQLY_FLASH_COMFIRM" then
		WuhunQuest_AQLY_AutoFlash_Confirm(tonumber(arg0))
		return
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89187002 ) then
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText( "#{JYGZ_160804_243}" )
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{LJSJ_160308_10}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{LJSJ_160308_11}");  --取消
		g_FrameInfo = FrameInfoList.BIEYE_CREATE_CONFIRM
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2018101302 ) then --材料强化
		WuhunQuest_Clear_Var()
		g_FrameVar[1] = Get_XParam_INT(0)
		g_FrameVar[2] = Get_XParam_INT(1)
		g_FrameVar[3] = Get_XParam_INT(2)
		WuhunQuest_InfoWindow:SetText(Get_XParam_STR(0))
		WuhunQuest_Button1:Hide()
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		g_FrameInfo = FrameInfoList.SJ_CAILIAOQIANGHUA_CONFIRM
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 920190216 ) then --材料强化
		WuhunQuest_Clear_Var()
		g_FrameVar[1] = Get_XParam_INT(0)
		g_FrameVar[2] = Get_XParam_INT(1)
		g_FrameVar[3] = Get_XParam_INT(2)
		WuhunQuest_InfoWindow:SetText(Get_XParam_STR(0))
		WuhunQuest_Button1:Hide()
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		g_FrameInfo = FrameInfoList.CHONGZHU_CAILIAO_UP_COMFIRM
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 889389 ) then--融魂丹购买
--		local strMsg = Get_XParam_STR(0);
		local nUniqueID = Get_XParam_STR(0);
		local notify = Get_XParam_INT(0);
		local nType = Get_XParam_INT(1);
		local nCurrencyUnit = Get_XParam_INT(2);
		local nPrice = Get_XParam_INT(3);
		local nItemIndex = Get_XParam_INT(4);
		local nSerialNum = Get_XParam_INT(5);
		local nItemID = Get_XParam_INT(6);
		local possname = Get_XParam_STR(1);
		if notify == 1 then
			WuhunQuest_Open_Window_PetRongHunDanBuy(nItemID, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, possname );
		else
			ConvenientBuyItem(nType,nCurrencyUnit,nPrice,nItemIndex,nSerialNum,nUniqueID );
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 889388 ) then--融魂丹使用
		local nItemID = Get_XParam_INT(0);
		local possname = Get_XParam_STR(0);
		WuhunQuest_Open_Window_PetRongHunDanUse( nItemID, possname );
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2021020101 ) then
		local nExteriorHeadFrameID = Get_XParam_INT(0)
		local posItem = Get_XParam_INT(1)
		local headframename = Get_XParam_STR(0)
		WuhunQuest_Open_Window_Head_Frame_XuQi(nExteriorHeadFrameID,posItem,headframename)
	elseif ( event == "PETSKILLLEVELUP_CONFIRM" ) then
		if tostring(arg0)=="quick" then
			--PushEvent("PETSKILLLEVELUP_CONFIRM","quick",hid,lid,g_selectskill,g_selectgood,skillID,HighestSkillID,WantHighestYB)
			local hid = tonumber(arg1);
			local lid = tonumber(arg2);
			local selectskill = tonumber(arg3);
			local selectgood = tonumber(arg4);
			local skillID = tonumber(arg5);
			local HighestSkillID = tonumber(arg6);
			local WantHighestYB = tonumber(arg7);
			WuhunQuest_Open_Window_PetSkillLevelupConfirm(hid,lid,selectskill,selectgood,skillID,HighestSkillID,WantHighestYB);
		else
			local skillID = tonumber(arg1);
			local WantGoodsID = tonumber(arg2);
			local WantYB = tonumber(arg3);
			WuhunQuest_Open_Window_PetSkillItemBuyConfirm(skillID,WantGoodsID,WantYB);
		end
	elseif (event == "PET_SHOULAN_AUTOUSE") then
		local nShouLanCnt = tonumber(arg0);
		local nRequireItem = tonumber(arg1);
		WuhunQuest_Open_Window_PetShouLan_AutoUse(nShouLanCnt,nRequireItem);
	elseif (event == "PET_SHOULAN_AUTOUP") then
		local nShouLanCnt = tonumber(arg0);
		local nRequireItem = tonumber(arg1);
		local nRequireYB = tonumber(arg2);
		WuhunQuest_Open_Window_PetShouLan_AutoUp(nShouLanCnt,nRequireItem,nRequireYB);
	elseif event == "DOUBLE_DAILYSECKILL_CONFIRM" then
		local BossIndex = tonumber(arg0)
		local needYuanBao = tostring(arg1)
		WuhunQuest_DoubleDailySeckill_confirm(BossIndex,needYuanBao)
	elseif (event == "PET_HUANHUA_CONFIRM") then
		local nShouLanCnt = tostring(arg0);  
		WuhunQuest_Open_Window_Pet_HuanHua_Confirm(nShouLanCnt); 
	elseif (event == "COMMON_CONFIRM") then
		local nShouLanCnt = tostring(arg0);  
		local nType = tonumber(arg1);  
		local nParam = tostring(arg2);  
		WuhunQuest_Open_Window_Common_Confirm(nShouLanCnt,nType,nParam);
	elseif (event == "MARTIAIL_RECYCLEATTRPOINT_CONFIRM") then
		local nIndex = tonumber(arg0); 
		local strTip = arg1;
		local Martial_WuYi_YuanbaoPay = tonumber(arg2);
		WuhunQuest_Open_Martail_Confirm(nIndex,strTip,Martial_WuYi_YuanbaoPay)
--	elseif (event == "SUPERWEAPON9_MAKESURE") then
--		local pos=tonumber(arg0)
--		WuhunQuest_Open_Window_SuperWeapon9_Confirm(pos);

	--18Q4感恩节食谱点击升级
	elseif ( event == "MENU_UPGRADE_CONFIRM" ) then
		if arg0 == nil or arg1 == nil or arg2 == nil or arg3 == nil or arg4 == nil then return end
		if tonumber( arg3 ) == 1 then 
			Menu_Bagpos = tonumber( arg0 )		--食谱bagpos
			New_Menu_Name = arg1  --下一级食谱名字
			Cooking_Num =  arg2   --消耗厨艺点
			Old_Menu_Name = arg4  --当前食谱名字
			local maintext = ScriptGlobal_Format("#{GEJY_181027_60}", Cooking_Num ,Old_Menu_Name, New_Menu_Name)
			WuhunQuest_Clear_Var()
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.MENU_UPGRADE_CONFIRM
			this:Show();
		else
			this:Hide();
		end
	--18Q4感恩节食谱升级跳转
	elseif ( event == "MENU_UPANDGO_CONFIRM" ) then
		if arg0 == nil or arg1 == nil or arg2 == nil then return end
		if tonumber( arg2 ) == 1 then 
			New_Menu_Name = arg0  --下一级食谱名字	
			New_Cook_Name = arg1  --下一级厨师名字			
			local maintext = ScriptGlobal_Format("#{GEJY_181027_100}", New_Menu_Name , New_Cook_Name)
			WuhunQuest_Clear_Var()
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_101}");  --前往
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.MENU_UPANDGO_CONFIRM
			this:Show();
		else
			this:Hide();
		end
	elseif (event == "SHELIZI_HECHENG_CONFIRM") then
		local ntype = tonumber(arg0)
		if ntype == 1 then
			WuhunQuest_shelizi_hecheng_confirm()
		elseif ntype == 2 then
			WuhunQuest_shelizi_hecheng_confirm_2(tonumber(arg1))
		elseif ntype == 3 then
			WuhunQuest_shelizi_hecheng_confirm_3(tonumber(arg1))
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 507012) then
		local nCur = Get_XParam_INT(0)
		local nMax = Get_XParam_INT(1)
		local nItem = Get_XParam_INT(2)
		WuhunQuest_MartialMultiItem_Confirm(nCur,nMax,nItem)
	elseif (event == "UI_COMMAND") and (arg0 == "20260121") then

		WuhunQuest_BuyNewbaotu_Confirm(tonumber(arg1))
	
	elseif(event == "MARTIAL_FREEZE_EXP_CONFIRM") then
		local nMax = tonumber(arg0)
		local nCur = tonumber(arg1)
		local nMul = tonumber(arg2)
		WhunQuest_MartialFreezeExp_Confirm(nMax,nCur,nMul)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201708263 ) then
		local strMsg = Get_XParam_STR(0);
		local nType = Get_XParam_INT(0);
		local nIndex = Get_XParam_INT(1);
		local nItemPos = Get_XParam_INT(2);
		WuhunQuest_Open_Window_BieYeStyleConfirm(strMsg, nType, nIndex, nItemPos);
	elseif (event == "MARTAIL_RLEARN_TALENT_CONFIRM") then
		local nLayer = tonumber(arg0)
		local nLevel = tonumber(arg1)
		local nCost = tonumber(arg2)
		local nLayerName = tostring(arg3)
		WuhunQuest_Martial_RLearnTalent_Confirm(nLayer,nLevel,nCost,nLayerName)
	
	elseif  (event == "UI_COMMAND") and (arg0 == "2017122101") then		 
		local thisMsg 			 = Get_XParam_STR(0); 
		local Type				   = Get_XParam_INT(0) 
		WuhunQuest_ZhaoHuiExp_Confirm(thisMsg,Type)	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201802011 ) then
		local strMsg = Get_XParam_STR(0);
		WuhunQuest_WeiXinQianDao_LiBao_Confirm(strMsg);
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89272302 ) then
		WuhunQuest_Clear_Var()
		local nFlag1 = Get_XParam_INT(0);
		local nFlag2 = Get_XParam_INT(1);
		g_FrameVar[1] = Get_XParam_INT(2);
		WuhunQuest_FangDeng_Confirm(nFlag1, nFlag2);	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88847801 ) then
		WuhunQuest_GuildSaoLeiConfirm();	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 8928007 ) then
		WuhunQuest_Clear_Var()
		g_FrameVar[1] = Get_XParam_INT(0);
		WuhunQuest_Balloon_Confirm(g_FrameVar[1]);	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 8928009 ) then
		WuhunQuest_Clear_Var()
		g_FrameVar[1] = Get_XParam_INT(0);
		local count = Get_XParam_INT(1);
		g_FrameVar[2] = Get_XParam_INT(2);
		local name = Get_XParam_STR(0);
		WuhunQuest_Balloon_GetLibao_Confirm(count, name);	
	elseif (event == "APPLY_SNAKING_NUM_SECOND_CONFIRM") then
		local targetId = tonumber(arg0)
		g_FrameVar[1] = targetId
		--local strMsg = tostring(arg0)
		Apply_Snaking_Num_Second_Confirm()
   elseif(event =="JINFENGHAODU_CONFIRM") then
        WHQ_JF_Confirm(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3))
    elseif(event == "JINFENGHAODU_REWARD_CONFIRM") then
        WHQ_JF_Reward_Confirm(tonumber(arg0), tonumber(arg1))

	elseif event == "PET_LIANHUA_CONFIRM" then
		local petIndex = tonumber(arg0)
		WuhunQuest_Pet_LianHua_Confirm(petIndex)		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 880054001 then
		local bagIndex = Get_XParam_INT(0)
		local itemID = Get_XParam_INT(1)
		local bHuanYu = Get_XParam_INT(2)
		WuhunQuest_Use_Pet_HuanLingItem_Confirm(bagIndex,itemID,bHuanYu)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018121801 then
			local maintext = "#{ZHHD1_181128_31}"
			WuhunQuest_Clear_Var()
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.CONFIRM_CCSHOP_REFRESH
			this:Show();		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018121802 then
			local maintext = ScriptGlobal_Format("#{ZHHD1_181128_58}",1)
			WuhunQuest_Clear_Var()
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.CONFIRM_CCSHOP_CAIQUAN
			this:Show();				
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018121803 then		
			WuhunQuest_Clear_Var()
			local nTipsType = Get_XParam_INT(0);
			g_FrameVar[1] = Get_XParam_INT(1);
			local nItemId,nType,nCostMoney,nIsBuy,nGiveCnt = DataPool:Lua_GetCCShopItemPro(g_FrameVar[1]-1)
			nCostMoney = Get_XParam_INT(2);
			local maintext ="";
			local name = DataPool:Lua_GetItemNameByIndex( nItemId )
			if nTipsType == 1 and nType == 1 then
				maintext = ScriptGlobal_Format("#{ZHHD1_181128_101}",nCostMoney,nGiveCnt,name)
			elseif nTipsType == 1 and nType == 2 then
				maintext = ScriptGlobal_Format("#{ZHHD1_181128_102}",nCostMoney,nGiveCnt,name)			
			elseif nTipsType == 2 and nType == 1 then
				maintext = ScriptGlobal_Format("#{ZHHD1_181128_104}",nCostMoney,nGiveCnt,name)			
			elseif nTipsType == 2 and nType == 2 then
				maintext = ScriptGlobal_Format("#{ZHHD1_181128_105}",nCostMoney,nGiveCnt,name)			
			end
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.CONFIRM_CCSHOP_BUYITEM
			this:Show();				
	elseif event == "CCSHOP_CHUQUANCONFIRM" then		
			WuhunQuest_Clear_Var()
			local maintext = "#{ZHHD1_181128_90}";
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Hide()
			WuhunQuest_Button2:SetText("#{INTERFACE_XML_1173}");  --确定
			WuhunQuest_Button2:Show()
			g_FrameInfo = FrameInfoList.CONFIRM_CCSHOP_CAIQUAN2
			this:Show();				
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018122801 then
			local maintext = "#{ZHHD1_181128_164}"
			WuhunQuest_Clear_Var()
			g_FrameVar[1] = Get_XParam_INT(0);
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.CONFIRM_CCSHOP_CAIQUAN3
			this:Show();			
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018122802 then
			local maintext = "#{ZHHD1_181128_165}"
			WuhunQuest_Clear_Var()
			g_FrameVar[1] = Get_XParam_INT(0);
			WuhunQuest_InfoWindow:SetText( maintext )
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.CONFIRM_CCSHOP_CAIQUAN4
			this:Show();		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018122803 then
			WuhunQuest_Clear_Var()
			local nType = Get_XParam_INT(0);
			local nName = Get_XParam_STR(0);
			if nType == 0 then
				WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{ZHHD1_181128_136}",nName ))
			elseif nType == 1 then
				WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{ZHHD1_181128_137}",nName ))
			end
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
			g_FrameInfo = FrameInfoList.CONFIRM_CCSHOP_CAIQUAN5
			this:Show();
	elseif event == "UI_COMMAND" and tonumber(arg0) == 91020911 then
			WuhunQuest_Clear_Var()
			local nType = Get_XParam_INT(0);
			local nName = Get_XParam_STR(0);
			if nType == 0 then
				WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCLB_190819_66}",nName ))
			elseif nType == 1 then
				WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCLB_190819_69}",nName ))
			end
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
			g_FrameInfo = FrameInfoList.CONFIRM_SZLH
			this:Show();		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89333701 then
			WuhunQuest_Clear_Var()
			local nType = Get_XParam_INT(0);
			local nName = Get_XParam_STR(0);
			WuhunQuest_InfoWindow:SetText(nName)
			WuhunQuestUpdateRect();
			WuhunQuest_Button1:Show()
			WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
			WuhunQuest_Button2:Show()
			WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
			g_FrameInfo = FrameInfoList.SYJYH_CONFIRM
			this:Show();		
    elseif event == "UI_COMMAND" and tonumber(arg0) == 89337902 then
            WuhunQuest_Clear_Var()

            local nType = Get_XParam_INT(0);
            g_FrameVar[1] = Get_XParam_INT(1)
            local nName = Get_XParam_STR(0);
            if nType == 0 then
                WuhunQuest_InfoWindow:SetText( nName )
            elseif nType == 1 then
                WuhunQuest_InfoWindow:SetText( nName )
            end
            WuhunQuestUpdateRect();
            WuhunQuest_Button1:Show()
            WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
            WuhunQuest_Button2:Show()
            WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
            g_FrameInfo = FrameInfoList.LSS_CONFIRM
            this:Show();		
    elseif event == "UI_COMMAND" and tonumber(arg0) == 88805102 then
            WuhunQuest_Clear_Var()

            g_FrameVar[1] = Get_XParam_INT(0)
            local msg = Get_XParam_STR(0)
            WuhunQuest_InfoWindow:SetText(msg)
            WuhunQuestUpdateRect();
            WuhunQuest_Button1:Show()
            WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
            WuhunQuest_Button2:Show()
            WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
            g_FrameInfo = FrameInfoList.WGSHOP_CONFIRM
            this:Show();		
    elseif event == "DROP_ALL_ITEM_IN_TEMBANK" then
            WuhunQuest_Drop_All_Item_In_TemBank_Confirm()
    elseif event == "NIANSHOU_NINGYU_CONFIRM" then
		local petIndex = tonumber(arg0)
		WuhunQuest_NianShou_NingYu_Confirm(petIndex)
	elseif event == "NIANSHOU_HUANYU_RARE_CONFIRM" then
		local nBagIndex = tonumber(arg0)
		WuhunQuest_NianShou_HuanYu_Rare_Confirm(nBagIndex)
	elseif event == "NIANSHOU_HUANYU_BIND_CONFIRM" then
		WuhunQuest_NianShou_HuanYu_Bind_Confirm()
	elseif event == "NIANSHOU_HUANYUUP_BIND_CONFIRM" then
		WuhunQuest_NianShou_HuanYuUp_Bind_Confirm()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89284402 then --取消上阵二次确认
		local round = Get_XParam_INT(0)		
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText("#{JHS32_181117_92}")
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_LEAVEUPMATCH
		this:Show();
	elseif event == "CONFIRM_ZNQFUDAI_SELECT" and (tonumber(arg0) == 0 or tonumber(arg0) == 2) then
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText(arg1)
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
		g_FrameVar[1] = tonumber(arg0);
		g_FrameInfo = FrameInfoList.CONFIRM_ZNQFUDAI_SELECT
		DataPool:SetCanUseHotKey(0)
		this:Show();		
	elseif event == "GQHYCHOUJIANG_CONFIRM" and (tonumber(arg0) == 0 or tonumber(arg0) == 2) then--2019国庆稳活跃抽奖--选择道具未保存确认
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText(arg1)
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{GQHY_190723_49}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{GQHY_190723_74}");  --取消
		g_FrameVar[1] = tonumber(arg0);
		g_FrameInfo = FrameInfoList.GQHYCHOUJIANG_CONFIRM
		DataPool:SetCanUseHotKey(0)
		this:Show();		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 8930704 ) then
		local strMsg = Get_XParam_STR(0)		
		WuhunQuest_ZhiBuConfirm(strMsg)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 44000004 then
		local nType = Get_XParam_INT(0)
		WuhunQuest_ZNQBuyTokens_Confirm(nType)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99942401 ) then-- 2024Q3版本稳活活动
		local nObjId = Get_XParam_INT(0)		
		local strMsg = Get_XParam_STR(0)		
		WuhunQuest_WenHuoMissionConfirm(nObjId,strMsg)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89316704 then-- 2019国庆稳活跃抽奖--元宝购买二次确认
		local nType = Get_XParam_INT(0)
		WuhunQuest_GQHYChouJiangBuyTokens_Confirm(nType)
	elseif event == "FASHION_DEPOT_UPDATE" and tonumber(arg0) == 1000 then --背包物品到时装仓库的二次确认
		WuhunQuest_Clear_Var()
		g_FrameVar[1] = tonumber(arg1);
		g_FrameVar[2] = tonumber(arg2);
		g_FrameVar[3] = tonumber(arg3);
		g_FrameVar[4] = tonumber(arg4);
		g_FrameVar[5] = tonumber(arg5);
		if g_FrameVar[1] == 1 then
			WuhunQuest_InfoWindow:SetText("#{HCG_190117_38}")
		elseif g_FrameVar[1] == 2 then
			WuhunQuest_InfoWindow:SetText("#{HCG_190117_41}")
		end
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{HCG_190117_39}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{HCG_190117_40}");  --取消
		g_FrameInfo = FrameInfoList.FASHION_DEPOT_CONFIRM
		DataPool:SetCanUseHotKey(0)
		this:Show();	
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 29151602 then --取消上阵二次确认
		local round = Get_XParam_INT(0)		
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText("#{JHS32_181117_92}")
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_DFS_LEAVEUPMATCH
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89332404 ) then
		local strMsg = Get_XParam_STR(0);
		local state = Get_XParam_INT(0)		
		WuhunQuest_YuShou_Confirm(strMsg, state);
	elseif event == "EXCHONGLONG_ITEM_LLMZ" then --兑换真重楼二次确认
		WuhunQuest_Clear_Var()  
		g_FrameVar[1] = tonumber(arg1);
		WuhunQuest_InfoWindow:SetText("#{CLJSJ_150511_23}")
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{HCG_190117_39}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{HCG_190117_40}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_EXCHONGLONG_ITEM_LLMZ
		DataPool:SetCanUseHotKey(0)
		this:Show();	

	elseif event == "ZHIZUN_EQUIP_UPGRADE_CONFIRM" then
		WuhunQuest_ZZEUpGrade_Confirm( tonumber(arg0), tonumber(arg1), tonumber(arg2) )	
		return			
	elseif (event == "BXDBZ_COLSE_CONFIRM") then
		WuhunQuest_Close_DBZ_Confirm()
		return
	elseif event == "ZHIZUN_EQUIP_EXCHANGE_CONFIRM" then
		WuhunQuest_ZZEExchange_Confirm( tonumber(arg0) )	
		return
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2021012201) then
		WuhunQuest_Clear_Var()
		local item = Get_XParam_INT(0)
		local num = Get_XParam_INT(1)
		local script = Get_XParam_INT(2)
		local targetName = Get_XParam_STR(0)
		g_FrameVar[1] = script
		g_FrameInfo = FrameInfoList.JINLING_SPECIALITEM

		local itemName = nil
		if (item > 30000000) then
			itemName = PlayerPackage:GetItemName(item)
		else
			itemName = DataPool:Lua_GetItemNameByIndex(item)
		end
		
		local msg = ScriptGlobal_Format("#{JLDQZ_200814_203}", num, itemName, targetName)
		WuhunQuest_InfoWindow:SetText(msg)
		WuhunQuestUpdateRect()
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{JLDQZ_200814_204}")  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{JLDQZ_200814_205}")  --取消
		this:Show()
	elseif event == "DECOWEAPON_LEVELDOWN_CONFIRM" then
		WuhunQuest_Decoweapon_LevelDown_Confirm(tonumber(arg0),tonumber(arg1),tonumber(arg2),tonumber(arg3),tonumber(arg4))
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88896110 then
		WuhunQuest_Ornaments_Confirm(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2))
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99911310 then
		WuhunQuest_NameBoardEx_Confirm(Get_XParam_INT(0),Get_XParam_INT(1))
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99934001 then
		WuhunQuest_ChiJiDropItem_Confirm(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3))
	elseif event == "QIANKUNPOT_CONFIG" and arg0 == "config" then
		WuhunQuest_QianKunPot_Confirm(arg1, arg2)
	elseif event == "DAFUWENG_GROUP_CONFIRM" then
		WuhunQuest_DaFuWeng_Lock_Confirm(tonumber(arg0),arg1)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 55500119 then
		local nUniqueID = Get_XParam_STR(0)
		local nNeedItemNum = Get_XParam_INT(0)
		local nBuyNum = Get_XParam_INT(1)
		local nPrice = Get_XParam_INT(2)
		local nBuyType = Get_XParam_INT(3)
		local nCurrencyUnit = Get_XParam_INT(4)
		local nItemIndex = Get_XParam_INT(5)
		local nSerialNum = Get_XParam_INT(6)
		local bBuyConfirm = Get_XParam_INT(7)
		if bBuyConfirm == 1 then
			WuhunQuest_UnderArmourWash_BuyItem_Confirm(nUniqueID, nNeedItemNum, nBuyNum, nPrice, nBuyType, nCurrencyUnit, nItemIndex, nSerialNum)
		else
			ConvenientBulkBuyItem(nBuyType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nBuyNum)
		end		
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 55500120 then
		local nUniqueID = Get_XParam_STR(0)
		local nNeedItemNum = Get_XParam_INT(0)
		local nBuyNum = Get_XParam_INT(1)
		local nPrice = Get_XParam_INT(2)
		local nBuyType = Get_XParam_INT(3)
		local nCurrencyUnit = Get_XParam_INT(4)
		local nItemIndex = Get_XParam_INT(5)
		local nSerialNum = Get_XParam_INT(6)
		local bBuyConfirm = Get_XParam_INT(7)
		local nNeedItemIndex = Get_XParam_INT(8)
		if bBuyConfirm == 1 then
			WuhunQuest_UnderArmourStarUp_BuyItem_Confirm(nUniqueID, nNeedItemNum, nBuyNum, nPrice, nBuyType, nCurrencyUnit, nItemIndex, nSerialNum, nNeedItemIndex)
		else
			ConvenientBulkBuyItem(nBuyType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nBuyNum)
		end		
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88856201 then
		local posIndex = Get_XParam_INT(0)
		WuhunQuest_PetNeiDan_HuaQi_Confirm(posIndex)
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20230315 then
		WuhunQuest_Clear_Var()

		
		local cost = Get_XParam_INT(0)
		local count = Get_XParam_INT(1)
		local type = Get_XParam_INT(2)
		g_FrameVar[1] = cost
		g_FrameVar[2] = count
		g_FrameVar[3] = type
		local msg = ScriptGlobal_Format("#{ZNLSG_230215_45}", cost, count)
		WuhunQuest_InfoWindow:SetText(msg)
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.DAFUWENG_CONFIRM
		this:Show();
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20230316 then
		WuhunQuest_Clear_Var()

		
		local count = Get_XParam_INT(0)
		local back = Get_XParam_INT(1)

		g_FrameVar[1] = count
		g_FrameVar[2] = back

		local msg = ScriptGlobal_Format("#{ZNLSG_230215_63}", count, back)
		WuhunQuest_InfoWindow:SetText(msg)
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.DAFUWENG_BIND_YUANBAO_CONFIRM
		this:Show();
		return	
	elseif	event == "UI_COMMAND" and tonumber(arg0) == 20230507 then
		
		WuhunQuest_Clear_Var()			

		local str = Get_XParam_STR(0)
		local targetId = Get_XParam_INT(0)

		g_FrameVar[1] = targetId
		WuhunQuest_InfoWindow:SetText(str)
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{ZNLSG_230215_226}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{ZNLSG_230215_227}");  --取消
		g_FrameInfo = FrameInfoList.DAFUWENG_CREATE_GROUP
		this:Show();
		return
		elseif	event == "UI_COMMAND" and tonumber(arg0) == 20230508 then
			
		WuhunQuest_Clear_Var()			

		local str = Get_XParam_STR(0)
		local targetId = Get_XParam_INT(0)

		g_FrameVar[1] = targetId
		WuhunQuest_InfoWindow:SetText(str)
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{ZNLSG_230215_226}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{ZNLSG_230215_227}");  --取消
		g_FrameInfo = FrameInfoList.DAFUWENG_JOIN_GROUP
		this:Show();
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 50100302 then
		WuhunQuest_Clear_Var()
		g_FrameInfo = FrameInfoList.DAHUA_DAIBI_CONFIRM
		g_FrameVar[1] = Get_XParam_INT(0)
		WuhunQuest_InfoWindow:SetText( Get_XParam_STR(0) )
		WuhunQuest_Button1:Show();
		WuhunQuest_Button1:SetText("#{ZNLSG_230215_226}");
		WuhunQuest_Button2:Show();
		WuhunQuest_Button2:SetText("#{ZNLSG_230215_227}");
		WuhunQuestUpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 50100401 then
		WuhunQuest_Clear_Var()
		g_FrameInfo = FrameInfoList.DAHUA_DAIBI_SHOP_CONFIRM
		g_FrameVar[1] = Get_XParam_INT(0)
		WuhunQuest_InfoWindow:SetText( Get_XParam_STR(0) )
		WuhunQuest_Button1:Show();
		WuhunQuest_Button1:SetText("#{ZNLSG_230215_226}");
		WuhunQuest_Button2:Show();
		WuhunQuest_Button2:SetText("#{ZNLSG_230215_227}");
		WuhunQuestUpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20230510 then
		if g_FrameInfo == FrameInfoList.DAFUWENG_CREATE_GROUP or
			 g_FrameInfo == FrameInfoList.DAFUWENG_JOIN_GROUP then
			this:Hide()

			return	
		end	
	elseif event == "UI_COMMAND" and tonumber(arg0) == 50100802 then
		WuhunQuest_Clear_Var()
		g_FrameInfo = FrameInfoList.XINFUYUCHONG_SHIZHUANGLIHE_CONFIRM
		g_FrameVar[1] = Get_XParam_INT(0)
		WuhunQuest_InfoWindow:SetText( Get_XParam_STR(0) )
		WuhunQuest_Button1:Show();
		WuhunQuest_Button1:SetText("#{ZNLSG_230215_226}");
		WuhunQuest_Button2:Show();
		WuhunQuest_Button2:SetText("#{ZNLSG_230215_227}");
		WuhunQuestUpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
		return 
	elseif event == "UI_COMMAND" and tonumber(arg0) == 50102102 then
		WuhunQuest_Clear_Var()
		g_FrameInfo = FrameInfoList.MINGSHENGTAOXI_SHIZHUANGLIHE_CONFIRM
		g_FrameVar[1] = Get_XParam_INT(0)
		WuhunQuest_InfoWindow:SetText( Get_XParam_STR(0) )
		WuhunQuest_Button1:Show();
		WuhunQuest_Button1:SetText("#{ZNLSG_230215_226}");
		WuhunQuest_Button2:Show();
		WuhunQuest_Button2:SetText("#{ZNLSG_230215_227}");
		WuhunQuestUpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
		return 
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99821101 ) then
		WuhunQuest_Clear_Var()
		local nType = Get_XParam_INT(0);
		local nName = Get_XParam_STR(0);
		WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCLB_20230410_12}",nName ))
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_YCLB
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99827901 ) then
		WuhunQuest_Clear_Var()
		local nType = Get_XParam_INT(0);
		local nName = Get_XParam_STR(0);
		WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCLB_20230410_20}",nName ))
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_XLQY
		this:Show();	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99985301 ) then
		WuhunQuest_Clear_Var()
		local nType = Get_XParam_INT(0);
		local nName = Get_XParam_STR(0);
		WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{YCZJJ_260127_01}",nName ))
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_CMLH
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99908602 ) then
		WuhunQuest_Clear_Var()
		g_FrameVar[1] = Get_XParam_INT(0);
		g_FrameVar[2] = Get_XParam_INT(1);
		local nMsgStr = Get_XParam_STR(0);
		WuhunQuest_InfoWindow:SetText( nMsgStr )
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{YCLB_190819_67}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{YCLB_190819_68}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_DRESSJIEQI
		this:Show();
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99859102 then --取消上阵二次确认
		local round = Get_XParam_INT(0)		
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText("#{JHS32_181117_92}")
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
		g_FrameInfo = FrameInfoList.ZBS_CONFIRM_LEAVEUPMATCH
		this:Show();
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2023080201 then --重置宗门天赋
		local normalPoint = Get_XParam_INT(0)		
		local corePoint = Get_XParam_INT(1)		
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZMTF_230628_142}", normalPoint, corePoint))
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_RESETTALENTPOINT
		this:Show();
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99909903 then --重置宗门天赋
		WuhunQuest_Clear_Var()
		WuhunQuest_InfoWindow:SetText("#{RLYZ_20240516_65}")
		WuhunQuestUpdateRect();
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{GEJY_181027_61}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{GEJY_181027_62}");  --取消
		g_FrameInfo = FrameInfoList.CONFIRM_FACEAUTH_USEPRIVILIGE
		this:Show();
	elseif event == "EUS_ABANDON_RESULT_CONFIRM" then
		WuhunQuest_EquipUpstageAbandonResultConfirm()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88220003 then
		local targetId = Get_XParam_INT(0)
		local equip_bag_index = Get_XParam_INT(1)
		local mat_bag_index = Get_XParam_INT(2)
		local save_confirmed = Get_XParam_INT(3)
		WuhunQuest_EquipUpstageBindConfirm(targetId, equip_bag_index, mat_bag_index, save_confirmed)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88220006 then
		local targetId = Get_XParam_INT(0)
		local equip_bag_index = Get_XParam_INT(1)
		local mat_bag_index = Get_XParam_INT(2)
		local bind_confirmed = Get_XParam_INT(3)
		local save_confirmed = Get_XParam_INT(4)
		WuhunQuest_EquipUpstageNoSaveConfirm(targetId, equip_bag_index, mat_bag_index, bind_confirmed, save_confirmed)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88220005 then
		local targetId = Get_XParam_INT(0)
		local equip_bag_index = Get_XParam_INT(1)
		local high_rate_count = Get_XParam_INT(2)
		WuhunQuest_EquipUpstageSaveConfirm(targetId, equip_bag_index, high_rate_count)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88220007 then
		local targetId = Get_XParam_INT(0)
		local equip_bag_index = Get_XParam_INT(1)
		WuhunQuest_EquipUpstageRemoveConfirm(targetId, equip_bag_index)
	elseif event == "PET_STALL_LIST_YUANBAO_CONFIRM" then
		WuhunQuest_PetYuanBaoStallListResultConfirm(tonumber(arg0),arg1)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 51010802 then--2026Q1藏品藏宝图玩法设计--进副本二次确认
		local targetId = Get_XParam_INT(0)
		local itemid = Get_XParam_INT(1)
		WuhunQuest_NewBaoTuEnterFubenConfirm(targetId, itemid)
	elseif event == "UI_COMMAND" and tonumber(arg0) == 51010801 then--2026Q1藏品藏宝图玩法设计--离开副本二次确认
		WuhunQuest_NewBaoTuLeaveFuben1Confirm()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 51010901 then--2026Q1藏品藏宝图玩法设计--离开副本二次确认
		WuhunQuest_NewBaoTuLeaveFuben2Confirm()
	elseif event == "CLOSE_UNIDENT" and tonumber(arg0) == 2 then
		if g_FrameInfo == FrameInfoList.CONFIRM_BUY_NEWBAOTU then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88555402 then
		local rank_type = Get_XParam_INT(0)
		local bonus_level = Get_XParam_INT(1)
		local buff_idx = Get_XParam_INT(2)
		WuhunQuest_CangPinRankBuffConfirm(rank_type, bonus_level, buff_idx)
	end
end

-- 按钮1 点击事件
function WuhunQuest_Bn1Click()

	if (g_FrameInfo == FrameInfoList.YBMARKET_UP_ITEM_COMFIRM ) then
		Auction:PacketSend_SellItem(g_FrameVar[1] , tonumber(g_FrameVar[2]) , 1)
	elseif (g_FrameInfo == FrameInfoList.YBMARKET_UP_PET_COMFIRM  ) then
		Auction:PacketSend_SellPet(g_FrameVar[1] , tonumber(g_FrameVar[2]) ,1)
	elseif (g_FrameInfo == FrameInfoList.YBMARKET_BUY_COMFIRM  ) then
		Auction:PacketSend_Buy(g_FrameVar[1] , g_FrameVar[2] , 1)
	elseif (g_FrameInfo == FrameInfoList.PLAYERSHOP_CONFIRM_MULTIBUY  ) then
		PlayerShop:SearchPageMultiBuyItem(1)
	elseif (g_FrameInfo == FrameInfoList.YBMARKET_CONFIRM_MULTIBUY  ) then
		Auction:PacketSend_MultiBuy(1)
	elseif (g_FrameInfo == FrameInfoList.TMARKET_CONFIRM_MULTIBUY  ) then
		TAuction:PacketSend_MultiBuy(1)
	elseif (g_FrameInfo == FrameInfoList.YBMARKET_TAKE_BACK_COMFIRM  ) then
		Auction:GetBackWhatOnSale(g_FrameVar[1] , g_FrameVar[2] ,1 )
	elseif (g_FrameInfo == FrameInfoList.SELL_ITEM_CONFIRM) then
		PlayerPackage:SellCurrItem(tonumber(g_FrameVar[1]) )
	elseif (g_FrameInfo == FrameInfoList.PET_EQUIP_SUITUP_CONFIRM) then
		WuhunQuest_Window_PetEquipSuitUp_Confirm()
	elseif (g_FrameInfo == FrameInfoList.FRIEND_PRESENT_CONFIRM) then
		PushEvent("FRIEND_PRESENT_SENDNOW")
	elseif (g_FrameInfo == FrameInfoList.DEMAIL_PRESENT_CONFIRM) then
		if g_FrameEvent == -1 then
			return
		end
		PushEvent("OKSENDMAIL_CONFIRM",g_FrameEvent)
	elseif (g_FrameInfo == FrameInfoList.TAUCTION_BUY_COMFIRM) then
		TAuction:PacketSend_Buy(g_FrameVar[1] , g_FrameVar[2] , 1)
	elseif (g_FrameInfo == FrameInfoList.TAUCTION_UP_COMFIRM) then
		TAuction:PacketSend_SellItem(g_FrameVar[1] , g_FrameVar[2], g_FrameVar[3] , 1)
	elseif (g_FrameInfo == FrameInfoList.TAUCTION_TAKEBACK_COMFIRM) then
		TAuction:GetBackWhatOnSale(g_FrameVar[1] , g_FrameVar[2], 1)
	elseif (g_FrameInfo == FrameInfoList.CARRIAGE_CANCELIMPACT_CONFIRM) then
	  local type = g_FrameVar[1]
	  local buffid = g_FrameVar[2]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("CarriageCancelImpactConfirm")
			Set_XSCRIPT_ScriptID(891526)
			Set_XSCRIPT_Parameter(0,buffid)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_BS_GUESSING) then--893060
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SupportTeam")
			Set_XSCRIPT_ScriptID(893060)
			Set_XSCRIPT_Parameter(0, g_FrameVar[2])
			Set_XSCRIPT_Parameter(1, g_FrameVar[3])
			Set_XSCRIPT_Parameter(2, g_FrameVar[4])
			Set_XSCRIPT_Parameter(3, g_FrameVar[5])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT();	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_DUANWULOTTERY) then--2019端午抽奖
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AddAward")
			Set_XSCRIPT_ScriptID(505087)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, g_FrameVar[3])
			Set_XSCRIPT_Parameter(3, g_FrameVar[4])
			Set_XSCRIPT_Parameter(4, g_FrameVar[5])
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT();	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_DUANWULOTTERY_CHANGEFRAME) then--2019端午抽奖
		PushEvent("DUANWU_BOAT_CHANGEFRAME", g_FrameVar[1])
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_USE_ITEM_ZS) then--付费道具
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnItemUse")
			Set_XSCRIPT_ScriptID(998200)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_USE_ITEM_BR) then--付费道具
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnItemUse")
			Set_XSCRIPT_ScriptID(998201)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_USE_ITEM_FH) then--付费道具
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnItemUse")
			Set_XSCRIPT_ScriptID(998202)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_USE_ITEM_CS) then--付费道具
		PlayerPackage:UseItem(g_FrameVar[1])
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_DUANWU_BOAT_MBUY) then
		Clear_XSCRIPT()
        	Set_XSCRIPT_Function_Name("BuyItem") 				
        	Set_XSCRIPT_ScriptID(505087)									  
       	 	Set_XSCRIPT_Parameter(0, g_FrameVar[1])
       	 	Set_XSCRIPT_Parameter(1, 1)	 	 
        	Set_XSCRIPT_ParamCount(2)  
			Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_NSHB_DAIBI_MBUY) then
		Clear_XSCRIPT()
        	Set_XSCRIPT_Function_Name("BuyDaiBi") 				
        	Set_XSCRIPT_ScriptID(501016)									  
       	 	Set_XSCRIPT_Parameter(0, g_FrameVar[1])
       	 	Set_XSCRIPT_Parameter(1, 1)	 	 
        	Set_XSCRIPT_ParamCount(2)  
   	 	Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_XINGXIASHOP_BUY) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoBuyDaiBi")
		Set_XSCRIPT_ScriptID(888963)
		Set_XSCRIPT_Parameter(0,g_FrameVar[1])
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_IMMIGRATION) then
	
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpouseImmigrationCallBack")
		Set_XSCRIPT_ScriptID(807012)
		Set_XSCRIPT_Parameter(0,g_FrameVar[2])
		Set_XSCRIPT_Parameter(1,g_FrameVar[3])
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()

	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CANCEL_IMMIGRATION) then
	
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpuoseCancelImmg_confirm")
		Set_XSCRIPT_ScriptID(807012)
		Set_XSCRIPT_Parameter(0,g_FrameVar[2])
		Set_XSCRIPT_Parameter(1,g_FrameVar[3])
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_Parameter(3,g_FrameVar[4])
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()		
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CANCEL_ODER_IMMIGRATION) then
	
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpuoseCancelImmg_confirm")
		Set_XSCRIPT_ScriptID(807014)
		Set_XSCRIPT_Parameter(0,g_FrameVar[2])
		Set_XSCRIPT_Parameter(1,g_FrameVar[3])
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_Parameter(3,g_FrameVar[4])
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()		
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_SEC_KILL_USE_ITEM) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UseItem")
		Set_XSCRIPT_ScriptID(100002)
		Set_XSCRIPT_Parameter(0,g_FrameVar[1])
		Set_XSCRIPT_Parameter(1,g_FrameVar[2])
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()				
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_ANNIVERSARY) then
	
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("7HITDayGetBonus")
		Set_XSCRIPT_ScriptID(232005)
		Set_XSCRIPT_Parameter(0,g_FrameVar[1])
		Set_XSCRIPT_Parameter(1,g_FrameVar[2])
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_DRESSCLOTH) then
		if g_FrameVar[1] == 0 then --时装镶嵌
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("BuyDressFu");
				Set_XSCRIPT_ScriptID(830013);
				Set_XSCRIPT_Parameter(0,g_FrameVar[3]);
				Set_XSCRIPT_ParamCount(1);
			Send_XSCRIPT();
		elseif g_FrameVar[1] == 1 then --时装打孔
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("BuyFu");
				Set_XSCRIPT_ScriptID(830011);
				Set_XSCRIPT_ParamCount(0);
			Send_XSCRIPT();
		elseif g_FrameVar[1] == 2 then --时装镶嵌绑定
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("OnDress_Enchase");
				Set_XSCRIPT_ScriptID(830013);
				Set_XSCRIPT_Parameter(0,g_FrameVar[2]);
				Set_XSCRIPT_Parameter(1,g_FrameVar[3]);
				Set_XSCRIPT_Parameter(2,g_FrameVar[4]);
				Set_XSCRIPT_Parameter(3,g_FrameVar[5]);	
				Set_XSCRIPT_Parameter(4,g_FrameVar[6]);				
				Set_XSCRIPT_Parameter(5,1);				
				Set_XSCRIPT_ParamCount(6);
			Send_XSCRIPT();		
		end
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_SPLITEGEM) then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("BuySplitFu");
				Set_XSCRIPT_ScriptID(830011);
				Set_XSCRIPT_Parameter(0,g_FrameVar[1]);
				Set_XSCRIPT_ParamCount(1);
			Send_XSCRIPT();
	elseif (g_FrameInfo == FrameInfoList.CARRIAGE_SENDIMPACT_CONFIRM) then
	  local allianceId = g_FrameVar[1]
	  local index = g_FrameVar[2]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("CarriageSendImpactConfirm")
			Set_XSCRIPT_ScriptID(891523)
			Set_XSCRIPT_Parameter(0,allianceId)
			Set_XSCRIPT_Parameter(1,index)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.SHOULAN_OPERATION_CONFIRM) then
	  local npcid = g_FrameVar[1]
	  local index = g_FrameVar[2]
	  if index >= 1 and index <= 3 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ClientAskShoulanOperationEnd" )
				Set_XSCRIPT_ScriptID(891939)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,index)
				Set_XSCRIPT_Parameter(2,1)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()	
		end
	elseif (g_FrameInfo == FrameInfoList.SHOULAN_PROMOTE_CONFIRM) then
		local nSelectLevel = g_FrameVar[1]
		local nOperType = g_FrameVar[2]
		local petGuidH = g_FrameVar[3]
		local petGuidL = g_FrameVar[4]
		local timeLevel = g_FrameVar[5]
		if nOperType >= 1 and nOperType <= 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ClientAskShoulanOperationConfirm" )
				Set_XSCRIPT_ScriptID(891939)
				Set_XSCRIPT_Parameter(0,nOperType)
				Set_XSCRIPT_Parameter(1,petGuidH)
				Set_XSCRIPT_Parameter(2,petGuidL)
				Set_XSCRIPT_Parameter(3,nSelectLevel)
				Set_XSCRIPT_Parameter(4,timeLevel)
				Set_XSCRIPT_Parameter(5,1)
				Set_XSCRIPT_ParamCount(6)
			Send_XSCRIPT()
		end
	elseif (g_FrameInfo == FrameInfoList.BIEYEMATERIALOUTPUT_GARDENER_CONFIRM) then
	  local npcid = g_FrameVar[1]
	  local nMissionType = g_FrameVar[2]
	  local nBuildIndex = g_FrameVar[3]
	  local nOutputID = g_FrameVar[4]
		if nMissionType == 1 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
				Set_XSCRIPT_ScriptID(891943)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,nOutputID)
				Set_XSCRIPT_Parameter(3,0)-- 0元宝购买不需要确认 1元宝购买需要确认
				Set_XSCRIPT_Parameter(4,1)-- 0雇佣园丁未确认 1雇佣园丁确认
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()
		elseif nMissionType == 2 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
				Set_XSCRIPT_ScriptID(891944)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,nOutputID)
				Set_XSCRIPT_Parameter(3,0)-- 0元宝购买确认过 1元宝购买需要确认
				Set_XSCRIPT_Parameter(4,1)-- 0雇佣园丁未确认 1雇佣园丁确认
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()
		elseif nMissionType == 3 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
				Set_XSCRIPT_ScriptID(891945)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,nOutputID)
				Set_XSCRIPT_Parameter(3,0)-- 0元宝购买不需要确认 1元宝购买需要确认
				Set_XSCRIPT_Parameter(4,1)-- 0雇佣园丁未确认 1雇佣园丁确认
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()
		elseif nMissionType > 3 and nMissionType < 10 then
			BieYeUI:BuildingLevelUpWithBuildType(nBuildIndex,nOutputID, npcid, 1)
		end	
	elseif (g_FrameInfo == FrameInfoList.BIEYEMATERIALOUTPUT_COSTYB_CONFIRM) then
	  local npcid = g_FrameVar[1]
	  local nMissionType = g_FrameVar[2]
	  local nBuildIndex = g_FrameVar[3]
	  local nOutputID = g_FrameVar[4]
		if nMissionType == 1 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
				Set_XSCRIPT_ScriptID(891943)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,nOutputID)
				Set_XSCRIPT_Parameter(3,0)-- 0元宝购买不需要确认 1元宝购买需要确认
				Set_XSCRIPT_Parameter(4,0)-- 0雇佣园丁未确认 1雇佣园丁确认
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()
		elseif nMissionType == 2 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
				Set_XSCRIPT_ScriptID(891944)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,nOutputID)
				Set_XSCRIPT_Parameter(3,0)-- 0元宝购买不需要确认 1元宝购买需要确认
				Set_XSCRIPT_Parameter(4,0)-- 0雇佣园丁未确认 1雇佣园丁确认
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()
		elseif nMissionType == 3 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
				Set_XSCRIPT_ScriptID(891945)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,nOutputID)
				Set_XSCRIPT_Parameter(3,0)-- 0元宝购买不需要确认 1元宝购买需要确认
				Set_XSCRIPT_Parameter(4,0)-- 0雇佣园丁未确认 1雇佣园丁确认
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()
		end	
	elseif (g_FrameInfo == FrameInfoList.BIEYEMATERIALOUTPUT_CANCEL_CONFIRM) then
	  local npcid = g_FrameVar[1]
	  local nMissionType = g_FrameVar[2]
	  local nBuildIndex = g_FrameVar[3]
		if nMissionType == 1 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionCancelConfirm" )
				Set_XSCRIPT_ScriptID(891943)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,1)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		elseif nMissionType == 2 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionCancelConfirm" )
				Set_XSCRIPT_ScriptID(891944)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,1)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		elseif nMissionType == 3 then
			--确认操作
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnMissionCancelConfirm" )
				Set_XSCRIPT_ScriptID(891945)
				Set_XSCRIPT_Parameter(0,npcid)
				Set_XSCRIPT_Parameter(1,nBuildIndex)
				Set_XSCRIPT_Parameter(2,1)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end	
	elseif (g_FrameInfo == FrameInfoList.YINGJIE_EXCHANGE_CONFIRM) then
	  local index = g_FrameVar[1]
	  if index >= 1 and index <= 3 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ExchangeYingJiePrize" )
				Set_XSCRIPT_ScriptID(891723)
				Set_XSCRIPT_Parameter(0,index)
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
		end
	elseif (g_FrameInfo == FrameInfoList.CHIHUOGUO_CONFIRM) then--吃火锅
		local targetid = g_FrameVar[1]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetLowReward")
			Set_XSCRIPT_ScriptID(888811)
			Set_XSCRIPT_Parameter(0,targetid)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_BUILD_SNOWMAN) then--堆雪人
		local targetid = g_FrameVar[1]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetLowReward")
			Set_XSCRIPT_ScriptID(998964)
			Set_XSCRIPT_Parameter(0,targetid)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_TLG) then--舔栏杆二次确认
		local targetid = g_FrameVar[1]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(998982)
			Set_XSCRIPT_Parameter(0,targetid)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.SAVETREE_CONFIRM) then--树灵
		local targetid = g_FrameVar[1]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetLowReward")
			Set_XSCRIPT_ScriptID(998227)
			Set_XSCRIPT_Parameter(0,targetid)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.FHSXBUY_CONFIRM) then--2021双旦集五福
		local nIndex = g_FrameVar[1]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnBuy")
			Set_XSCRIPT_ScriptID(888836)
			Set_XSCRIPT_Parameter( 0, nIndex )
			Set_XSCRIPT_Parameter( 1, 1 )
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_BUY_ZIWEILINGPO) then--紫薇灵魄元宝购买
		local nIndex = g_FrameVar[1]
		local nTargetId = g_FrameVar[2]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyLingPoLihe")
			Set_XSCRIPT_ScriptID(998558)
			Set_XSCRIPT_Parameter( 0, nIndex )
			Set_XSCRIPT_Parameter( 1, 1 )
			Set_XSCRIPT_Parameter( 2, nTargetId )
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.ERTONGJIEDAIBI_CONFIRM) then--【2022Q2】儿童节代币转换
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDuiHuan" )
			Set_XSCRIPT_ScriptID( 998025 )
			Set_XSCRIPT_Parameter( 0, g_FrameVar[1] )
			Set_XSCRIPT_Parameter( 1, g_FrameVar[2] )
			Set_XSCRIPT_Parameter( 2, 1 )
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.SUPERWEAPONDIYSKILL_EXCHANGE) then
		local npcId = g_FrameVar[1]
		local nIndex = g_FrameVar[2]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_Exchange" )
			Set_XSCRIPT_ScriptID(892472)
			Set_XSCRIPT_Parameter(0,npcId)
			Set_XSCRIPT_Parameter(1,nIndex)
			Set_XSCRIPT_Parameter(2,1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.SUPERWEAPONDIYSKILL_CONFIRM) then
		local nType = g_FrameVar[1]
		local npcId = g_FrameVar[2]
		local bagIndex = g_FrameVar[3]
		local slotIndex = g_FrameVar[4]
		local impactIndex = g_FrameVar[5]
	  if nType == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_AddImpact" )
				Set_XSCRIPT_ScriptID(892471)
				Set_XSCRIPT_Parameter(0,npcId)
				Set_XSCRIPT_Parameter(1,bagIndex)
				Set_XSCRIPT_Parameter(2,slotIndex)
				Set_XSCRIPT_Parameter(3,impactIndex)
				Set_XSCRIPT_Parameter(4,1)
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()	
	  elseif nType == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_DelImpact" )
				Set_XSCRIPT_ScriptID(892471)
				Set_XSCRIPT_Parameter(0,npcId)
				Set_XSCRIPT_Parameter(1,bagIndex)
				Set_XSCRIPT_Parameter(2,slotIndex)
				Set_XSCRIPT_Parameter(3,impactIndex)
				Set_XSCRIPT_Parameter(4,1)
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()	
	  elseif nType == 3 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_EmbedSlot" )
				Set_XSCRIPT_ScriptID(892471)
				Set_XSCRIPT_Parameter(0,npcId)
				Set_XSCRIPT_Parameter(1,bagIndex)
				Set_XSCRIPT_Parameter(2,slotIndex)
				Set_XSCRIPT_Parameter(3,impactIndex)
				Set_XSCRIPT_Parameter(4,1)
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()	
	  elseif nType == 4 then
			--Clear_XSCRIPT()
			--	Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_DelImpact" )
			--	Set_XSCRIPT_ScriptID(892471)
			--	Set_XSCRIPT_Parameter(0,npcId)
			--	Set_XSCRIPT_Parameter(1,bagIndex)
			--	Set_XSCRIPT_Parameter(2,slotIndex)
			--	Set_XSCRIPT_Parameter(3,impactIndex)
			--	Set_XSCRIPT_Parameter(4,1)
			--	Set_XSCRIPT_ParamCount(5)
			--Send_XSCRIPT()	
	  elseif nType == 5 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_LevelupSlot" )
				Set_XSCRIPT_ScriptID(892471)
				Set_XSCRIPT_Parameter(0,npcId)
				Set_XSCRIPT_Parameter(1,bagIndex)
				Set_XSCRIPT_Parameter(2,slotIndex)
				Set_XSCRIPT_Parameter(3,1)
				Set_XSCRIPT_ParamCount(4)
			Send_XSCRIPT()	
		end
	elseif (g_FrameInfo == FrameInfoList.JIEHUNHUIKUI_PRIZE_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
			Set_XSCRIPT_ScriptID(891739)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1])
			Set_XSCRIPT_Parameter(1,g_FrameVar[2])
			Set_XSCRIPT_Parameter(2,1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.DELETEGXH_CONFIRM) then
	  local type = g_FrameVar[1]
	  if type == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("DelFaceStyle")
				Set_XSCRIPT_ScriptID(805029)
				Set_XSCRIPT_Parameter(0,g_FrameVar[2])
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
		elseif type == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("DelHairStyle")
				Set_XSCRIPT_ScriptID(801010)
				Set_XSCRIPT_Parameter(0,g_FrameVar[2])
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
		elseif type == 3 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("DelHairColor")
				Set_XSCRIPT_ScriptID(801011)
				Set_XSCRIPT_Parameter(0,g_FrameVar[2])
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
		elseif type == 4 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("DelHeadStyle")
				Set_XSCRIPT_ScriptID(805030)
				Set_XSCRIPT_Parameter(0,g_FrameVar[2])
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
		elseif type == 5 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("DelHeadFrame")
				Set_XSCRIPT_ScriptID(892425)
				Set_XSCRIPT_Parameter(0,g_FrameVar[2])
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
		end

	elseif (g_FrameInfo == FrameInfoList.CONVENIENT_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6],g_FrameVar[8] );
	elseif (g_FrameInfo == FrameInfoList.NEW_DAKONG_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_StilettoEx_Material_Buy = 1
	elseif (g_FrameInfo == FrameInfoList.WUHUN_CONVENIENTBUYITEM_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_WuHun_Material_Buy = 1
	elseif (g_FrameInfo == FrameInfoList.WUHUN_QUICKUP_CONFIRM) then
	  local nType = g_FrameVar[1]
	  local nIndex = g_FrameVar[2]
	  local nParam = g_FrameVar[3]
	  if nType == 1 then--武魂扩展属性升级
			PlayerPackage:Kfs_Op_Do(1, nIndex, -1, nParam, 2)-- 0 普通 1 快捷 2 快捷确认
	  elseif nType == 7 then--武魂技能升级
			PlayerPackage:Kfs_Op_Do(7, nIndex, -1, nParam, 2)-- 0 普通 1 快捷 2 快捷确认
		end	
	elseif (g_FrameInfo == FrameInfoList.PET_HUANTONT_CONFIRM) then--add:lby
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
	elseif (g_FrameInfo == FrameInfoList.EQUIP_REPAIRTIMES_CONFIRM) then--add:lby
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );		
	elseif (g_FrameInfo == FrameInfoList.PET_RHD_CONFIRM) then--add:lby 
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_PETZHUANXING_PAY) then--转性
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
	elseif (g_FrameInfo == FrameInfoList.PET_LINGXING_CONFIRM) then--add:lby
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
	elseif (g_FrameInfo == FrameInfoList.NEW_XIANGQIAN_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_EnchaseEx_Material_Buy = 1
	elseif (g_FrameInfo == FrameInfoList.NEW_ZHAICHU_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_SplitGemEx_Material_Buy = 1
	elseif (g_FrameInfo == FrameInfoList.PETHUANSE_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
	elseif (g_FrameInfo == FrameInfoList.CORPSRELIVE_VOTECERTAIN) then
		CorpsUI:VoteToCorpBeSure();
	elseif (g_FrameInfo == FrameInfoList.DELETE_COMBOBOOK_CONFIRM) then
		PushEvent("DELETE_COMBOBOOK_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.QUICKUP_PET_CONFIRM) then
		PushEvent("QUICKUP_PET_SENDMSG",g_FrameVar[1])
	--elseif (g_FrameInfo == FrameInfoList.FORBIDIT_CONFIRM) then
	--	Target:ForbidIt( 1 );
	elseif (g_FrameInfo == FrameInfoList.EQUIP_DECOMPOSE_CONFIRM) then
		PushEvent("EQUIP_DECOMPOSE_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.EQUIP_TEMPER_CONFIRM) then
		PushEvent("EQUIP_TEMPER_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.EQUIP_TRANSFER_CONFIRM) then
		PushEvent("EQUIP_TRANSFER_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.EQUIP_UPDATE_CONFIRM) then
		PushEvent("EQUIP_UPDATE_SENDMSG",0)
	elseif (g_FrameInfo == FrameInfoList.EQUIP_UPDATE_CONFIRMEX ) then
		PushEvent("EQUIP_UPDATE_SENDMSG",1)
	--elseif (g_FrameInfo == FrameInfoList.FORBIDIT_CONFIRMBYNAMEANDFIND) then
	--	FriendSearcher:ForbidItByNameAndGuid(1,g_FrameVar[1])
	elseif (g_FrameInfo == FrameInfoList.INFANT_CARD_COMPOSE_CONFIRM) then
		PushEvent("INFANT_CARD_COMPOSE_CONFIRM_OK")
	elseif (g_FrameInfo == FrameInfoList.INFANT_CARD_STRENGTH_CONFIRM) then
		PushEvent("INFANT_CARD_STRENGTH_CONFIRM_OK")
	elseif (g_FrameInfo == FrameInfoList.INFANT_CARD_TRANSFER_CONFIRM) then
		PushEvent("INFANT_CARD_TRANSFER_CONFIRM_OK")
	elseif g_FrameInfo == FrameInfoList.EQUIPLINGPAI_OP_CLOSE_CONFIRM then
		CloseWindow("EquipLingPai_Operating" , true)
	elseif g_FrameInfo == FrameInfoList.ZHIZUNHAOLI_CONFIRM then
		WuhunQuest_Zhizun_Confired(g_FrameVar[1])
	elseif (g_FrameInfo == FrameInfoList.BAOSHI_YI_CONFIRM) then
		ConvenientBulkBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6],g_FrameVar[7] );

	elseif g_FrameInfo == FrameInfoList.EQUIPATTR_CHANGEEQUIP_CONFIRM then
		PushEvent("EQUIPATTR_CHANGEEQUIP_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])

	elseif g_FrameInfo == FrameInfoList.EQUIP_ZIZHI_RECOIN_CONFIRM then
		PushEvent("EQUIP_ZIZHI_RECOIN_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])
	elseif g_FrameInfo == FrameInfoList.PETEQUIP_ZIZHI_RECOIN_CONFIRM then
		PushEvent("PETEQUIP_ZIZHI_RECOIN_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])
	elseif g_FrameInfo == FrameInfoList.WUHUN_SKILL_RECOIN_CONFIRM then
		PushEvent("WUHUN_SKILL_RECOIN_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])
	elseif g_FrameInfo == FrameInfoList.DARK_SKILL_RECOIN_CONFIRM then
		PushEvent("DARK_SKILL_RECOIN_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])
	elseif g_FrameInfo == FrameInfoList.INFANT_SKILL_RECOIN_CONFIRM then
		PushEvent("INFANT_SKILL_RECOIN_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])

	elseif g_FrameInfo == FrameInfoList.LW_ATTR_RECOIN_CONFIRM then
		PushEvent("LW_ATTR_RECOIN_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])

	elseif g_FrameInfo == FrameInfoList.SUPER_ATTR_RECOIN_CONFIRM then
		PushEvent("SUPER_ATTR_RECOIN_CONFIRM_OK",g_FrameVar[1],g_FrameVar[2])
	elseif g_FrameInfo == FrameInfoList.DECOWEAPON_LEVELUP_CONFIRM then
		if g_FrameVar[1] ~= -1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnDecoWeaponLevelUp")
				Set_XSCRIPT_ScriptID(891788)
				Set_XSCRIPT_Parameter(0, g_FrameVar[1])
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
		
	elseif g_FrameInfo == FrameInfoList.DECOWEAPON_CONVER_CONFIRM then 
		PushEvent("DECOWEAPON_CONVER_CONFIRM_OK")
		
	elseif g_FrameInfo == FrameInfoList.DOUBLE_SECKILL_CONFIRM then
		PushEvent("SEND_SECKILL", 0, g_FrameVar[2], g_FrameVar[5])
		
	elseif g_FrameInfo == FrameInfoList.DOUBLE_DAILYSECKILL_CONFIRM then
		PushEvent("SEND_DAILYSECKILL", 0, g_FrameVar[1])
	elseif g_FrameInfo == FrameInfoList.SECKILL_GIVEUP_CONFIRM then
		SecKillGiveUpItem()
	elseif g_FrameInfo == FrameInfoList.SECKILL_GIVEUP_CONFIRM_ZHAOHUI then
		SecKillGiveUpItem()	
	elseif g_FrameInfo == FrameInfoList.EQUIPATTR_BIND_CONFIRM then
		PushEvent("EQUIPATTR_BIND_CONFIRM_OK")
	elseif g_FrameInfo == FrameInfoList.SHENDING_RESET_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnLianDanLuQianNengReset");
			Set_XSCRIPT_ScriptID( g_FrameVar[1] );
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.HXY_ACTIVE_EFFECT_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("HXY_EffectLevelUp");
			Set_XSCRIPT_ScriptID( 880006);
			Set_XSCRIPT_Parameter(0, g_FrameVar[1] );
			Set_XSCRIPT_Parameter(1 , 0)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.HXY_RESET_EFFECT_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ResetHXYEffect");
			Set_XSCRIPT_ScriptID( 880008 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1] );
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.PNEUMA_SWITCHGOLD_CONFIRM then
		PushEvent("PNEUMA_SWITCHGOLD_CONFIRM_OK")
	elseif g_FrameInfo == FrameInfoList.BROTHERSPIRIT_CONFIRM then
		DataPool:Lua_SendBrotherRetSpirit(g_FrameVar[1],1)
	elseif g_FrameInfo == FrameInfoList.MAKEZONGZI_CONFIRM then		
		--PushDebugMessage("FrameInfoList.MAKEZONGZI_CONFIRM  "..g_FrameVar[1])
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("MakeZongzi");
			Set_XSCRIPT_ScriptID(891150);
			Set_XSCRIPT_Parameter(0,tonumber(g_FrameVar[1]));
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	elseif (g_FrameInfo == FrameInfoList.FORBIDIT_KICKOUT_CONFIRM) then
		Target:KickItOut( 1 );
	elseif (g_FrameInfo == FrameInfoList.USEZHENFA_CONFIRM) then
		Player:UseSkillnew(tonumber(g_FrameVar[1]))
	elseif (g_FrameInfo == FrameInfoList.SHOPBUY_FURNITURE_CONFIRM) then
		PlayerShop:SearchPageBuyItem(g_FrameVar[1] - 1, "item")
	elseif (g_FrameInfo == FrameInfoList.SWEAR_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AgreeSwear" )
			Set_XSCRIPT_ScriptID( 880025 )
			Set_XSCRIPT_Parameter(0,tonumber(g_FrameVar[1]))
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CHIXUEQYD_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateOnce" )
			Set_XSCRIPT_ScriptID( 891366 )
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_LEVELUP_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "LevelUp" )
			Set_XSCRIPT_ScriptID( 880036 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[2]) )
			Set_XSCRIPT_Parameter( 1, tonumber(g_FrameVar[1]) )       	--- 物品背包索引
			Set_XSCRIPT_Parameter( 2, 0 )       						--- 是否需要绑定确认
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_VIP_TRANSFER_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "VipTransfer" )
			Set_XSCRIPT_ScriptID( 880036 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[1]) )       --- 物品背包索引
			Set_XSCRIPT_Parameter( 1, tonumber(g_FrameVar[2]) )       --- 物品背包索引
			Set_XSCRIPT_Parameter( 2, 0 )       												--- 是否需要绑定确认
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_TRANSFER_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Transfer" )
			Set_XSCRIPT_ScriptID( 880036 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[3]) )
			Set_XSCRIPT_Parameter( 1, tonumber(g_FrameVar[1]) )       --- 物品背包索引
			Set_XSCRIPT_Parameter( 2, tonumber(g_FrameVar[2]) )       --- 物品背包索引
			Set_XSCRIPT_Parameter( 3, 0 )       											--- 是否需要绑定确认
			Set_XSCRIPT_ParamCount( 4 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.FIVE_ELEMENTS_SWITCHTYPE_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FiveElementsTypeSwitch" )
			Set_XSCRIPT_ScriptID( 880039 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[1]) )      --ElementsIndex
			Set_XSCRIPT_Parameter( 1, tonumber(g_FrameVar[2]) ) 		--NewType
			Set_XSCRIPT_Parameter( 2, 0 ) 
			Set_XSCRIPT_Parameter( 3, 1 ) 
			Set_XSCRIPT_ParamCount( 4 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CLOSE_FIVE_ELEMENTS_WASH_COMFIRM) then
		PushEvent("FIVE_ELEMENTS_WASH_CLOSE")
	elseif (g_FrameInfo == FrameInfoList.FIVE_ELEMENTS_WASH_SWITCH_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FiveElementsJadeSwitch" )
			Set_XSCRIPT_ScriptID( 880039 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[1]) ) 
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.ALLIANCEKICK_GUILD) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientKickAllianceGuild");
			Set_XSCRIPT_ScriptID(891564);
			Set_XSCRIPT_Parameter(0,tonumber(g_FrameVar[1]));
			Set_XSCRIPT_Parameter(1,tonumber(g_FrameVar[2]));
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();		
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_ACTINGGUILD_KICK) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnNewAgreeKick" )
			Set_XSCRIPT_ScriptID( 891564 )
			Set_XSCRIPT_Parameter( 0, -1 ) 
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.FIVE_ELEMENTS_WASH_NOTSWITCH_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FiveElementsJadeSwitch" )
			Set_XSCRIPT_ScriptID( 880039 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[1]) ) 
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.FIVE_ELEMENTS_AUTOWASH_CONFIRM) then
		Lua_FiveElementsAutoWashStart()	
	elseif (g_FrameInfo == FrameInfoList.EQUIP_ATTRFUKE_CONFIRM) then
		PushEvent("EQUIP_ATTRFUKE_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.ZHENFA_FORGET_CONFIRM) then
		
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ForgetZF");
			Set_XSCRIPT_ScriptID(891175);
			Set_XSCRIPT_Parameter(0,tonumber(g_FrameVar[1]));
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();			
	elseif (g_FrameInfo == FrameInfoList.DRESSGEM_STILETTO_CONFIRM) then
		PushEvent("DRESSGEM_STILETTO_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.DRESSGEM_ENCHASE_CONFIRM) then
		PushEvent("DRESSGEM_ENCHASE_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.GSEVALUATE_CONFIRM) then
		PushEvent("FATIE_SECCONFIRM","close")		
	elseif (g_FrameInfo == FrameInfoList.BILLINGAWARD_CONFIRM) then
		PushEvent("BILLINGAWARD_CONFIRM_OK", g_FrameVar[1]);
	elseif g_FrameInfo == FrameInfoList.DRESS_TRANSFER_BUYITEM_CONFIRM then
		ConvenientBulkBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[7],g_FrameVar[6])
	elseif g_FrameInfo == FrameInfoList.AQLY_FLASH_COMFIRM then
		PushEvent("AQLY_FLASH_COMFIRMOK")
	elseif (g_FrameInfo == FrameInfoList.BIEYEREMOVE_FURNITURE) then
		BieYeFurniture:RemoveFuniture(g_FrameVar[1],g_FrameVar[3])
	elseif (g_FrameInfo == FrameInfoList.BIEYE_CREATE_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnConfirmCreate")
			Set_XSCRIPT_ScriptID(891870)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	--18Q4感恩节食谱鉴定-升级		
	elseif ( g_FrameInfo == FrameInfoList.MENU_UPGRADE_CONFIRM ) then
		-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpGradeItemFC" ); 		-- 脚本号
			Set_XSCRIPT_ScriptID( 892979 );						-- 脚本编号
			Set_XSCRIPT_Parameter( 0, Menu_Bagpos );		    -- 参数一
			Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
		Send_XSCRIPT()		
	--18Q4感恩节食谱升级跳转		
	elseif ( g_FrameInfo == FrameInfoList.MENU_UPANDGO_CONFIRM ) then
		-- 执行脚本
		PushEvent( "MENU_UPANDGO_CMD", 1);  --点击确定，切换

	elseif (g_FrameInfo == FrameInfoList.DIAOWEN_YUANBAO_PAY_CONFIRM) then
		ConvenientBulkBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6],g_FrameVar[7] );

	elseif (g_FrameInfo == FrameInfoList.PETYANSHOU_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_PetSkillStudy_YanShou = 1
	elseif (g_FrameInfo == FrameInfoList.PETXIDIAN_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_PetSkillStudy_XiDian = 1
	elseif (g_FrameInfo == FrameInfoList.PETHUANHUA_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_PetSkillStudy_HuanHua = 1
	elseif (g_FrameInfo == FrameInfoList.PET_HUANHUA_CONFIRM) then  
		PushEvent("PET_HUANHUA_CONFIRM_OK")
	elseif (g_FrameInfo == FrameInfoList.COMMON_CONFIRM) then  
		PushEvent("COMMON_CONFIRM_RET", g_FrameVar[1],g_FrameVar[2])
	elseif (g_FrameInfo == FrameInfoList.PETEQUIPREFRESH_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_PetEquip_Refresh = 1
	elseif (g_FrameInfo == FrameInfoList.PETSINGLEPROCREATE_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_PetEquip_SignleProcreate_Buy = 1
	elseif (g_FrameInfo == FrameInfoList.BIEYEPETSINGLEPROCREATE_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_BieYePet_SignleProcreate_Buy = 1
	elseif (g_FrameInfo == FrameInfoList.WuYi_BUY_CONFIRM) then
		if IsTBFinalServer() >= 1 then
			--总决赛特殊服务器不允许进行该操作
			PushDebugMessage("#{BHKF_150323_61}")
			return
		end	
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
	elseif (g_FrameInfo == FrameInfoList.BIEYEPETPAINT_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
		g_BieYePet_Paint_Buy = 1
	elseif ( g_FrameInfo == FrameInfoList.RONGHUNDAN_USE_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnActivateOnceSimulate")
			Set_XSCRIPT_ScriptID(889822)
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[1]) ) 
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif ( g_FrameInfo == FrameInfoList.HEADFRAME_XUQI_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("XuQiExteriorHeadFrame");
			Set_XSCRIPT_ScriptID(892425);
			Set_XSCRIPT_Parameter(0, g_FrameVar[1]);
			Set_XSCRIPT_Parameter(1, g_FrameVar[2]);
			Set_XSCRIPT_Parameter(2, 0);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
	elseif (g_FrameInfo == FrameInfoList.RONGHUNDAN_BUY_CONFIRM) then
		ConvenientBuyItem(g_FrameVar[1],g_FrameVar[2],g_FrameVar[3],g_FrameVar[4],g_FrameVar[5],g_FrameVar[6] );
	elseif ( g_FrameInfo == FrameInfoList.PETSKILL_LEVELUP_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("PetSkillLevelup");
			Set_XSCRIPT_ScriptID(311112);
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]);
			Set_XSCRIPT_Parameter(1,g_FrameVar[2]);
			Set_XSCRIPT_Parameter(2,g_FrameVar[3]);
			Set_XSCRIPT_Parameter(3,g_FrameVar[4]);
			Set_XSCRIPT_Parameter(4,1);
			Set_XSCRIPT_ParamCount(5);
		Send_XSCRIPT();
	elseif (g_FrameInfo == FrameInfoList.PETSKILL_SHOULANUSE_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnActivateOnceSimulate");
			Set_XSCRIPT_ScriptID(335805);
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]);--nRequireItem
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	elseif (g_FrameInfo == FrameInfoList.PETSKILL_SHOULANUP_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("PetShouLanAutoUp");
			Set_XSCRIPT_ScriptID(335805);
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]);
			Set_XSCRIPT_Parameter(1,g_FrameVar[2]);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (g_FrameInfo == FrameInfoList.BIEYE_FURNITURE_DESTROY_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DestroyFurniture")
			Set_XSCRIPT_ScriptID(891837)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1])
			Set_XSCRIPT_Parameter(1,g_FrameVar[2])
			Set_XSCRIPT_Parameter(2,1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif ( g_FrameInfo == FrameInfoList.PETSKILL_LINGSHOUDAN_CONFIRM) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("PetSkillLevelupItemBuy");
			Set_XSCRIPT_ScriptID(311112);
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]);
			Set_XSCRIPT_Parameter(1,g_FrameVar[2]);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (g_FrameInfo == FrameInfoList.MARTIAIL_RECYCLEATTRPOINT_CONFIRM) then
		if(g_FrameVar[1] == 15) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "RecycleAllAttrPoint" )
				Set_XSCRIPT_ScriptID( 507010 )
			Send_XSCRIPT()
		else
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("RecycleAttrPoint");
				Set_XSCRIPT_ScriptID(507010);
				Set_XSCRIPT_Parameter(0,g_FrameVar[1]);
				Set_XSCRIPT_Parameter(1,g_FrameVar[3]);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
		end

--	elseif (g_FrameInfo == FrameInfoList.SUPERWEAPON9_CONFIRM) then
--		Clear_XSCRIPT()
--			Set_XSCRIPT_Function_Name("DoSuperWeapon9Up")
--			Set_XSCRIPT_ScriptID(702006)
--			Set_XSCRIPT_Parameter(0, 1)
--			Set_XSCRIPT_Parameter(1, g_FrameVar[1])
--			Set_XSCRIPT_ParamCount(2)
--		Send_XSCRIPT()
--	elseif (g_FrameInfo == FrameInfoList.SUPERWEAPON9_PIECEEXCHANGE) then
--		Clear_XSCRIPT()
--			Set_XSCRIPT_Function_Name("DoSuperWeapon9Up")
--			Set_XSCRIPT_ScriptID(702006)
--			Set_XSCRIPT_Parameter(0, 4)
--			Set_XSCRIPT_Parameter(1, 1)
--			Set_XSCRIPT_ParamCount(2)
--		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.SHELIZI_HECHENG_CONFIRM) then
	
		PushEvent("SHELIZI_HECHENG_CONFIRM",g_FrameVar[1]);
	elseif (g_FrameInfo == FrameInfoList.MARTIAL_MULTIITEM_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmOk" )
			Set_XSCRIPT_ScriptID(507012)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.MARTIAL_FREEZE_EXP_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FreezeMartialExp" )
			Set_XSCRIPT_ScriptID( 507010 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_BUY_NEWBAOTU) then
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(510113)
		Set_XSCRIPT_Function_Name("ClientAskident")
		Set_XSCRIPT_Parameter(0, g_FrameVar[1])
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	this:Hide()

	PushEvent("CLOSE_UNIDENT",1)
	elseif (g_FrameInfo == FrameInfoList.BIEYESTYLE_CONFIRM) then
		local type = g_FrameVar[1]
		if type == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ActiveBieYeStyle")
				Set_XSCRIPT_ScriptID(892505)
				Set_XSCRIPT_Parameter(0,g_FrameVar[2])
				Set_XSCRIPT_Parameter(1,g_FrameVar[3])
				Set_XSCRIPT_Parameter(2,1)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()	
		elseif type == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ExtendBieYeStyle")
				Set_XSCRIPT_ScriptID(892505)
				Set_XSCRIPT_Parameter(0,g_FrameVar[2])
				Set_XSCRIPT_Parameter(1,g_FrameVar[3])
				Set_XSCRIPT_Parameter(2,1)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end
		CloseWindow("BieYeHuanZhuang_Activation",true)
	elseif (g_FrameInfo == FrameInfoList.MARTAIL_RLEARN_TALENT_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "RecycleTalent" )
			Set_XSCRIPT_ScriptID( 507011 )
			Set_XSCRIPT_Parameter(0,g_FrameVar[1])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.ZHAOHUI_EXP_CONFIRM) then
		local type = g_FrameVar[1]
		if type == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "GetExp_ByMoney" )
				Set_XSCRIPT_ScriptID(892659)
				Set_XSCRIPT_Parameter(0,1) 
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif type == 2 then	--元宝
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "GetExp_ByYuanBao" )
				Set_XSCRIPT_ScriptID(892659)
				Set_XSCRIPT_Parameter(0,1) 
				Set_XSCRIPT_Parameter(1,0) 
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		elseif type == 3 then	--元宝道具
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "GetExp_ByYuanBao" )
				Set_XSCRIPT_ScriptID(892659)
				Set_XSCRIPT_Parameter(0,0) 
				Set_XSCRIPT_Parameter(1,1) 
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
	elseif (g_FrameInfo == FrameInfoList.WEIXINQIANDAO_LIBAO_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateOnce" )
			Set_XSCRIPT_ScriptID( 892682 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.FANGDENG_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CheckStepOne" )
			Set_XSCRIPT_ScriptID( 892723 )
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]) 
			Set_XSCRIPT_Parameter(1,1) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()

	elseif (g_FrameInfo == FrameInfoList.GUILD_SAOLEI_CONFIRM) then
		Player:UseSkillnew(4711) --4711 1769
	elseif (g_FrameInfo == FrameInfoList.BALLOON_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetReward" )
			Set_XSCRIPT_ScriptID( 892800 )
			Set_XSCRIPT_Parameter(0,1) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.BALLOON_GETLIBAO_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetLibao" )
			Set_XSCRIPT_ScriptID( 892797 )
			Set_XSCRIPT_Parameter(0,g_FrameVar[2]) 
			Set_XSCRIPT_Parameter(1,g_FrameVar[1]) 
			Set_XSCRIPT_Parameter(2,1) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.APPLY_SNAKING_NUM_SECOND_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OkApplySnakingNum" )
			Set_XSCRIPT_ScriptID( 250558 )
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
    elseif (g_FrameInfo == FrameInfoList.JINFENGHAODU_CONFIRM) then
        PushEvent("JINFENGHAODU_SELECT_UI")
    elseif (g_FrameInfo  == FrameInfoList.JINFENGHAODU_REWARD_CONFIRM) then
        PushEvent("JINFENGHAODU_REWARD_RESP", 1)
	elseif g_FrameInfo == FrameInfoList.USE_PET_HUANLING_ITEM_CONFIRM then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnConfirm" )
			Set_XSCRIPT_ScriptID( 880054 )
			Set_XSCRIPT_Parameter(0,g_FrameVar[1])
			Set_XSCRIPT_Parameter(1,g_FrameVar[2]) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.DROP_ALL_ITEM_INTEMBANK then
		Bank:CleanAllItemInTemBank()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CCSHOP_REFRESH ) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("RefreshBuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,0) 			
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CCSHOP_CAIQUAN ) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("CheckCaiQuanBegin")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,0) 			
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CCSHOP_BUYITEM ) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]) 
			Set_XSCRIPT_Parameter(1,0) 			
			Set_XSCRIPT_Parameter(2,0) 			
			Set_XSCRIPT_ParamCount(3)			
		Send_XSCRIPT()			
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CCSHOP_CAIQUAN2 ) then	
		this:Hide()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CCSHOP_CAIQUAN3 ) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]) 
			Set_XSCRIPT_Parameter(1,0) 			
			Set_XSCRIPT_Parameter(2,1) 			
			Set_XSCRIPT_ParamCount(3)			
		Send_XSCRIPT()				
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CCSHOP_CAIQUAN4 ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]) 
			Set_XSCRIPT_Parameter(1,0) 			
			Set_XSCRIPT_Parameter(2,2) 			
			Set_XSCRIPT_ParamCount(3)			
		Send_XSCRIPT()			
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CCSHOP_CAIQUAN5 ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(893027)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.SYJYH_CONFIRM) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("cost_in_luoyang")
			Set_XSCRIPT_ScriptID(893337)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()						
	elseif (g_FrameInfo == FrameInfoList.LSS_CONFIRM) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("confirm")
			Set_XSCRIPT_ScriptID(893379)
            Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()						
	elseif (g_FrameInfo == FrameInfoList.WGSHOP_CONFIRM) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("confirm")
			Set_XSCRIPT_ScriptID(888051)
            Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()						

	elseif (g_FrameInfo == FrameInfoList.CONFIRM_SZLH ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(893248)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()						
	elseif g_FrameInfo == FrameInfoList.CONFIRM_LEAVEUPMATCH then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientLeaveUpMatch")
			Set_XSCRIPT_ScriptID( 892844 )
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_ZNQFUDAI_SELECT then
		PushEvent("CONFIRM_ZNQFUDAI_SELECT", g_FrameVar[1]+1)
		-- PushDebugMessage("fffffffffff")		
	elseif g_FrameInfo == FrameInfoList.GQHYCHOUJIANG_CONFIRM then--2019国庆稳活跃抽奖--选择道具未保存确认
		PushEvent("GQHYCHOUJIANG_CONFIRM", g_FrameVar[1]+1)
	elseif (g_FrameInfo == FrameInfoList.ZHIBU_EXCHANGE_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeReward" )
			Set_XSCRIPT_ScriptID( 893070 )
			Set_XSCRIPT_Parameter(0, 1)			
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.ZNQ_BUY_TOKENS_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyTokens" )
			Set_XSCRIPT_ScriptID(440000)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.GQHYCHOUJIANG_BUY_TOKENS_CONFIRM then--2019国庆稳活跃抽奖--元宝购买二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyTokens" )
			Set_XSCRIPT_ScriptID(893167)
			Set_XSCRIPT_Parameter(0,g_FrameVar[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.FASHION_DEPOT_CONFIRM then
		if(IsWindowShow("DressClosetFrame")) then
			FashionDepot:LuaFnSendFashionDepotOperation(g_FrameVar[1], g_FrameVar[2], g_FrameVar[3], g_FrameVar[4], g_FrameVar[5])
		end
	elseif g_FrameInfo == FrameInfoList.CONFIRM_DFS_LEAVEUPMATCH then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientLeaveUpMatch")
			Set_XSCRIPT_ScriptID( 291516 )
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_YUSHOU then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnFashionPrePay")
			Set_XSCRIPT_ScriptID(893324)
			Set_XSCRIPT_Parameter(0, 0);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif g_FrameInfo == FrameInfoList.CONFIRM_BUYFASHION then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnFashionFinalPay")
			Set_XSCRIPT_ScriptID(893324)
			Set_XSCRIPT_Parameter(0, 0);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	elseif g_FrameInfo == FrameInfoList.CONFIRM_BUYSECFASHION then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnFashionSecondBuy")
			Set_XSCRIPT_ScriptID(893324)
			Set_XSCRIPT_Parameter(0, 0);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	elseif g_FrameInfo == FrameInfoList.CONFIRM_FOND then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnFondExchange")
			Set_XSCRIPT_ScriptID(893324)
			Set_XSCRIPT_Parameter(0, 0);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	elseif g_FrameInfo == FrameInfoList.CONFIRM_EXCHONGLONG_ITEM then
		-- statements 
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientChange");
			Set_XSCRIPT_ScriptID(890921);
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();			
	elseif g_FrameInfo == FrameInfoList.CONFIRM_EXCHONGLONG_ITEM_LLMZ then
		-- statements 
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientChange");
			Set_XSCRIPT_ScriptID(998608);
			Set_XSCRIPT_Parameter(0,g_FrameVar[1]);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
	elseif (g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_UPGRADE_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CommonUpGrade" )
			Set_XSCRIPT_ScriptID( 880036 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[3]) )
			Set_XSCRIPT_Parameter( 1, tonumber(g_FrameVar[1]) )    --- 物品背包索引
			Set_XSCRIPT_Parameter( 2, tonumber(g_FrameVar[2]) )    --- 是否王权1 天道2
			Set_XSCRIPT_Parameter( 3, 0 )       					--- 是否需要绑定确认
			Set_XSCRIPT_ParamCount( 4 )
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.ZHIZUN_EQUIP_EXCHANGE_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeItem" )
			Set_XSCRIPT_ScriptID( 880036 )
			Set_XSCRIPT_Parameter( 0, tonumber(g_FrameVar[1]) )
			Set_XSCRIPT_Parameter( 1, 0 )       					--- 是否需要绑定确认
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.JINLING_SPECIALITEM) then
		local scriptId = g_FrameVar[1]
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("UseItem")
			Set_XSCRIPT_ScriptID(scriptId)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.DECOWEAPON_LEVELDOWN_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnExteriorWeaponLevelDown")
			Set_XSCRIPT_ScriptID(891788)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, g_FrameVar[3])
			Set_XSCRIPT_Parameter(3, g_FrameVar[4])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_ORNAMENTS_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UnlockOrnaments" )
			Set_XSCRIPT_ScriptID( 888961 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, g_FrameVar[3])
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount( 4 )
		Send_XSCRIPT()
	
	elseif g_FrameInfo == FrameInfoList.DAHUA_DAIBI_CONFIRM then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyDaiBi")
			Set_XSCRIPT_ScriptID(501003)
			Set_XSCRIPT_Parameter( 0, g_FrameVar[1] )
			Set_XSCRIPT_Parameter( 1, 1 ) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.DAHUA_DAIBI_SHOP_CONFIRM then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(501004)
			Set_XSCRIPT_Parameter( 0, g_FrameVar[1] )
			Set_XSCRIPT_Parameter( 1, 1 ) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.XINFUYUCHONG_SHIZHUANGLIHE_CONFIRM then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyLiHe")
			Set_XSCRIPT_ScriptID(501008)
			Set_XSCRIPT_Parameter( 0, g_FrameVar[1] )
			Set_XSCRIPT_Parameter( 1, 1 ) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif g_FrameInfo == FrameInfoList.MINGSHENGTAOXI_SHIZHUANGLIHE_CONFIRM then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyLiHe")
			Set_XSCRIPT_ScriptID(501021)
			Set_XSCRIPT_Parameter( 0, g_FrameVar[1] )
			Set_XSCRIPT_Parameter( 1, 1 ) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_NAMEBOARDEX_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UnlockNameBoardEx" )
			Set_XSCRIPT_ScriptID( 999113 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_CHIJIDROPITEM_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DestoryBagItem" )
			Set_XSCRIPT_ScriptID( 999340 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, g_FrameVar[3])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount( 4 )
		Send_XSCRIPT()
		
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_MRHL ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(888993)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_ZNSZLH ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(501020)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_MSQXLH ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(501021)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_YCLB ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(998211)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_XLQY ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(998279)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CMLH ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUseItem")
			Set_XSCRIPT_ScriptID(999853)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()		
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_DRESSJIEQI ) then			
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("NumberingFashionJieQi")
			Set_XSCRIPT_ScriptID(999086)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_ParamCount(3)			
		Send_XSCRIPT()	
	elseif g_FrameInfo == FrameInfoList.CONFIRM_QIANKUNPOT_SAVE then
		PushEvent("QIANKUNPOT_CONFIG", "ok", g_FrameVar[1], g_FrameVar[2])
	elseif g_FrameInfo == FrameInfoList.UNDERARMOUR_WASH_BUY_CONFIRM then
		ConvenientBulkBuyItem(g_FrameVar[1], g_FrameVar[2], g_FrameVar[3], g_FrameVar[4], g_FrameVar[5], g_FrameVar[6], g_FrameVar[7])
	elseif g_FrameInfo == FrameInfoList.UNDERARMOUR_STARUP_BUY_CONFIRM then
		ConvenientBulkBuyItem(g_FrameVar[1], g_FrameVar[2], g_FrameVar[3], g_FrameVar[4], g_FrameVar[5], g_FrameVar[6], g_FrameVar[7])
	elseif g_FrameInfo == FrameInfoList.PETNEIDAN_HUAQI_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("PetNeiDan_HuaQi")
			Set_XSCRIPT_ScriptID(888562)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.DAFUWENG_CONFIRM then
		if(g_FrameVar[3] == 0) then
			DaFuWeng:BuyDice(g_FrameVar[2],1)

		end
	elseif g_FrameInfo == FrameInfoList.DAFUWENG_BIND_YUANBAO_CONFIRM then

			DaFuWeng:ExchangeYB(1)
	elseif g_FrameInfo == FrameInfoList.DAFUWENG_CREATE_GROUP then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TeamMemberConfim" )
			Set_XSCRIPT_ScriptID( 290400 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.DAFUWENG_JOIN_GROUP then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TeamMemberConfim" )
			Set_XSCRIPT_ScriptID( 290400 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, 2)
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()	
	elseif g_FrameInfo == FrameInfoList.DAFUWENG_GROUP_CONFIRM then
		if g_FrameVar[1] == 18 then
			DaFuWeng:LockTeam(1)
		elseif g_FrameVar[1] == 19 then
			DaFuWeng:DissMissTeam(1)
		elseif g_FrameVar[1] == 22 then
			DaFuWeng:KickTeamMemberGUID(g_FrameVar[2],1)
		elseif g_FrameVar[1] == 23 or g_FrameVar[1] == 24 then
			DaFuWeng:LeaveTeam(1)
		end
	elseif g_FrameInfo == FrameInfoList.ZBS_CONFIRM_LEAVEUPMATCH then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientLeaveUpMatch")
			Set_XSCRIPT_ScriptID( 998591 )
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_RESETTALENTPOINT then
		Player:Lua_AskSectOper(2,1) 
	elseif g_FrameInfo == FrameInfoList.CONFIRM_NEWMONTHCARD then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BuyNewMonthcard")
		Set_XSCRIPT_ScriptID( 998908 )
		Set_XSCRIPT_Parameter(0, g_FrameVar[1])
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.WENHUOMISSION_CONFIRM then-- 2024Q3版本稳活活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnHelpOK" )
			Set_XSCRIPT_ScriptID( 999424 )			
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.COLSE_CONFIRM_BXDBZ then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ReadyToMatchFinish")
			Set_XSCRIPT_ScriptID( 999463 )
			Set_XSCRIPT_Parameter(0, 9)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_FACEAUTH_JIANDAN then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyJianDan")
			Set_XSCRIPT_ScriptID( 999552 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CONFIRM_FACEAUTH_USEPRIVILIGE then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("IsConfirmRequestMonthcardReward")
			Set_XSCRIPT_ScriptID( 999099 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.EUS_ABANDON_RESULT_CONFIRM then
		CloseWindow("EquipEducation_Upstage", true)
	elseif g_FrameInfo == FrameInfoList.EQUIP_UPSTAGE_BIND_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(882200)
			Set_XSCRIPT_Function_Name("EquipUpstage")
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, g_FrameVar[3])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_Parameter(4, g_FrameVar[4])
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.EQUIP_UPSTAGE_NOSAVE_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(882200)
			Set_XSCRIPT_Function_Name("EquipUpstage")
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, g_FrameVar[3])
			Set_XSCRIPT_Parameter(3, g_FrameVar[4])
			Set_XSCRIPT_Parameter(4, 0)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.EQUIP_UPSTAGE_SAVE_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(882200)
			Set_XSCRIPT_Function_Name("SaveUpstageResult")
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.EQUIP_UPSTAGE_REMOVE_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(882200)
			Set_XSCRIPT_Function_Name("UpstageRemove")
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.PET_STALL_LIST_YUANBAO_CONFIRM then
		StallSale:PetUpStall(g_FrameVar[1]);
	elseif g_FrameInfo == FrameInfoList.NEWBAOTU_ENTERFUBEN_CONFIRM then--2026Q1藏品藏宝图玩法设计--进副本二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(510108)
			Set_XSCRIPT_Function_Name("EnterFuben")
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.NEWBAOTU_LEAVEFUBEN1_CONFIRM then--2026Q1藏品藏宝图玩法设计--离开副本二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(510108)
			Set_XSCRIPT_Function_Name("LeaveFuben")
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.NEWBAOTU_LEAVEFUBEN2_CONFIRM then--2026Q1藏品藏宝图玩法设计--离开副本二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(510109)
			Set_XSCRIPT_Function_Name("LeaveFuben")
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.CANGPIN_RANK_BUFF_CONFIRM then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TakeCangPinRankBuff")
			Set_XSCRIPT_ScriptID(885554)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_FrameVar[2])
			Set_XSCRIPT_Parameter(2, g_FrameVar[3])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end
	
	this:Hide()

end
-- 按钮2 点击事件
function WuhunQuest_Bn2Click()
	--由服务器记统计日志
	if (g_FrameInfo == FrameInfoList.CONVENIENT_BUY_CONFIRM and g_FrameVar[7] ~= nil and tonumber(g_FrameVar[7]) > 0) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ConvenientBuyAuditLog");
			Set_XSCRIPT_ScriptID(tonumber(g_FrameVar[7]));
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();

	elseif (g_FrameInfo == FrameInfoList.BROTHERSPIRIT_CONFIRM) then
		DataPool:Lua_SendBrotherRetSpirit(g_FrameVar[1],0)
	elseif (g_FrameInfo == FrameInfoList.MAKEZONGZI_CONFIRM) then
		--不需要处理
	elseif (g_FrameInfo == FrameInfoList.SWEAR_CONFIRM) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "QuitSwear" )
			Set_XSCRIPT_ScriptID( 880025 )
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_IMMIGRATION) then
		--移民取消
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SpouseImmigrationCallBack")
			Set_XSCRIPT_ScriptID(807012)
			Set_XSCRIPT_Parameter(0,g_FrameVar[2] )
			Set_XSCRIPT_Parameter(1,g_FrameVar[3] )
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CANCEL_IMMIGRATION) then
		--移民取消
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SpuoseCancelImmg_confirm")
			Set_XSCRIPT_ScriptID(807012)
			Set_XSCRIPT_Parameter(0,g_FrameVar[2] )
			Set_XSCRIPT_Parameter(1,g_FrameVar[3] )
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_Parameter(3,g_FrameVar[4])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_CANCEL_ODER_IMMIGRATION) then
		--移民取消
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SpuoseCancelImmg_confirm")
			Set_XSCRIPT_ScriptID(807014)
			Set_XSCRIPT_Parameter(0,g_FrameVar[2])
			Set_XSCRIPT_Parameter(1,g_FrameVar[3])
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_Parameter(3,g_FrameVar[4])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (g_FrameInfo == FrameInfoList.CHIXUEQYD_CONFIRM) then
		--不需要处理
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_ACTINGGUILD_KICK) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnNewDisAgreeKick" )
			Set_XSCRIPT_ScriptID( 891564 )
			Set_XSCRIPT_Parameter( 0, -1 ) 
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()	
	elseif g_FrameInfo == FrameInfoList.DRESS_TRANSFER_BIND_CONFIRM then
		DressEnchasing:Lua_DressTransferBindConfirmed()
	elseif (g_FrameInfo == FrameInfoList.EQUIP_TEMPER_QUERENCONFIRM) then
		PushEvent("EQUIP_TEMPER_QUERENSENDMSG")
	elseif (g_FrameInfo == FrameInfoList.SUPERWEAPONSOULLESS_CONFIRM) then
		PushEvent("SUPERWEAPONSOULLESS_SENDMSG")
	elseif (g_FrameInfo == FrameInfoList.SHENQI_JIEMENG_CONFIRM) then
		PushEvent("SUPERWEAPON9_JM_CONFIRM_RET")
    elseif (g_FrameInfo == FrameInfoList.JINFENGHAODU_REWARD_CONFIRM) then
        PushEvent("JINFENGHAODU_REWARD_RESP", 2)
	elseif g_FrameInfo == FrameInfoList.PET_LIANHUA_CONFIRM then		--珍兽炼化确认
		Pet:Lua_LianHuaConfirmRet()
	elseif (g_FrameInfo == FrameInfoList.SJ_CAILIAOQIANGHUA_CONFIRM) then--材料强化二次确认
		PushEvent("UPDATE_CAILIAOQIANGHUA_CONFIRM")

	elseif (g_FrameInfo == FrameInfoList.CHONGZHU_CAILIAO_UP_COMFIRM) then
		-- 手工装备重铸材料升级确认
		PushEvent("CHONGZHU_CAILIAO_UP_COMFIRM_RET")
		-- Clear_XSCRIPT()
		-- 	Set_XSCRIPT_Function_Name( "OnUpdateMaterial" )
		-- 	Set_XSCRIPT_ScriptID(890990)
		-- 	Set_XSCRIPT_Parameter(0, g_FrameVar[1])					
		-- 	Set_XSCRIPT_Parameter(1, g_FrameVar[2])		
		-- 	Set_XSCRIPT_Parameter(2, g_FrameVar[3])		
		-- 	Set_XSCRIPT_Parameter(3, 1)		
		-- 	Set_XSCRIPT_ParamCount(4)
		-- Send_XSCRIPT()

	elseif (g_FrameInfo == FrameInfoList.MENU_UPANDGO_CONFIRM ) then
		-- 执行脚本
		PushEvent( "MENU_UPANDGO_CMD", 0);  --点击取消，不切换
	elseif g_FrameInfo == FrameInfoList.NIANSHOU_HUANYU_RARE_CONFIRM then
		Pet:Lua_NianShouHuanYuRareConfirmed(g_FrameVar[1])
	elseif g_FrameInfo == FrameInfoList.NIANSHOU_HUANYU_BIND_CONFIRM then
		Pet:Lua_NianShouHuanYuBindConfirmed()
	elseif g_FrameInfo == FrameInfoList.NIANSHOU_HUANYUUP_BIND_CONFIRM then
		Pet:Lua_NianShouHuanYuUpBindConfirmed()
    elseif g_FrameInfo == FrameInfoList.SYJYH_CONFIRM then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("cancel")
        Set_XSCRIPT_ScriptID(893337)
        Set_XSCRIPT_ParamCount(0)			
        Send_XSCRIPT()						
	elseif g_FrameInfo == FrameInfoList.CONFIRM_QIANKUNPOT_SAVE then
		PushEvent("QIANKUNPOT_CONFIG", "canel", g_FrameVar[1], g_FrameVar[2])
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_USE_ITEM_CS) then--付费道具
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Cancel")
			Set_XSCRIPT_ScriptID(998203)
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT();	
	elseif g_FrameInfo == FrameInfoList.DAFUWENG_CREATE_GROUP then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TeamMemberConfim" )
			Set_XSCRIPT_ScriptID( 290400 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	elseif g_FrameInfo == FrameInfoList.DAFUWENG_JOIN_GROUP then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TeamMemberConfim" )
			Set_XSCRIPT_ScriptID( 290400 )
			Set_XSCRIPT_Parameter(0, g_FrameVar[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, 2)
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()	

	end

	this:Hide();
end

function WuhunQuest_Frame_OnHiden()
	if(IsWindowShow("AntiJDY")) then    --简单游互斥界面显示时，不激活快捷键 for 69994
	else
		DataPool:SetCanUseHotKey(1)
	end
	WuhunQuest_Clear_Var()
end

function WuhunQuest_CleanUp()
	WuhunQuest_Frame_sub:SetProperty( "UnifiedPosition", "{{0.500000,-173.000000},{0.500000,-118.000000}}" )
	WuhunQuest_Button2:Hide();
	WuhunQuest_Button1:Hide();
end

function WuhunQuest_Clear_Var()
	for i = 1,8 do
		g_FrameVar[i] = 0
	end
	g_FrameInfo = -1
end
-- event == "GAME_NOTIFY_INFO_OK"
function WuhunQuest_Open_Window_OK(str)
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText(str);
	WuhunQuestUpdateRect();
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Hide()
	DataPool:SetCanUseHotKey(0)
	this:Show();
end



-- event == "GAME_NOTIFY_INFO_CLOSE"
function WuhunQuest_Open_Window_CLOSE(str)
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText(str);
	WuhunQuestUpdateRect();
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_1173}");  --关闭
	WuhunQuest_Button2:Hide()
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "GAME_NOTIFY_INFO_YESNO"
function WuhunQuest_Open_Window_YESNO(str)
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText(str);
	WuhunQuestUpdateRect();
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "YBMARKET_UP_ITEM_COMFIRM"
function WuhunQuest_Open_Window_YBM_UpItem(nIndex , nPrice)
	WuhunQuest_Clear_Var()
	g_FrameVar[1]  = tonumber(nIndex)
	g_FrameVar[2]  = tonumber(nPrice)
	local itemName = PlayerPackage:GetBagItemName(g_FrameVar[1])
--	local nNum 	= PlayerPackage:GetBagItemNum(g_FrameVar[1])
	local needMoney = Auction:GetNeedMoneyForSell(g_FrameVar[2])
--	local totalPrice = g_FrameVar[2] * nNum
--	local totalNeedMoney = needMoney * nNum
	WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_65}"..itemName.."#{YBSC_XML_66}"..tostring(g_FrameVar[2]).."#{YBSC_XML_67}".."#{_EXCHG"..tostring(needMoney).."}".."#{YBSC_XML_68}");	-- 设置内容
	g_FrameInfo = FrameInfoList.YBMARKET_UP_ITEM_COMFIRM ;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "YBMARKET_UP_PET_COMFIRM"
function WuhunQuest_Open_Window_YBM_UpPet(nIndex , nPrice)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(nPrice)
	local petName,szOn = Pet:GetPetList_Appoint(g_FrameVar[1]);
	local needMoney = Auction:GetNeedMoneyForSell(g_FrameVar[2])
	--珍兽进阶
	local szStr = ScriptGlobal_Format( "#{JJKHD_120808_12}", petName, tostring(g_FrameVar[2]), tostring(needMoney))
	WuhunQuest_InfoWindow:SetText( szStr );	-- 设置内容
	g_FrameInfo = FrameInfoList.YBMARKET_UP_PET_COMFIRM ;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "YBMARKET_BUY_COMFIRM"
function WuhunQuest_Open_Window_YBM_Buy(nType ,nIndex ,nPrice)
	g_FrameVar[1] = tonumber(nType)
	g_FrameVar[2] = tonumber(nIndex)
	g_FrameVar[3] = tonumber(nPrice)
	local unitName = ""
	if g_FrameVar[1] == 2 or g_FrameVar[1] == 3 then
		local pName , pSeller ,pCount ,pYB = Auction:GetItemAuctionInfo( g_FrameVar[2] )
		unitName =  pName
		WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_73}"..tostring(pYB).."#{YBSC_XML_74}"..tostring(pCount).."#{YBSC_XML_79}"..unitName.."#{YBSC_XML_75}");	-- 设置内容
	elseif g_FrameVar[1] == 1 then
		local pName , pSeller ,pYB = Auction:GetPetAuctionInfo( g_FrameVar[2] )
		unitName = pName
		WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_73}"..g_FrameVar[3].."#{YBSC_XML_74}"..unitName.."#{YBSC_XML_75}");	-- 设置内容
	end
	g_FrameInfo = FrameInfoList.YBMARKET_BUY_COMFIRM  ;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "PLAYERSHOP_CONFIRM_MULTIBUY"
function WuhunQuest_Open_Window_PSM_MultiBuy(arg0, arg1, arg2, arg3)
	local msg = ScriptGlobal_Format( "#{SHPLGM_150428_19}", arg0, arg1, arg2, arg3)
	WuhunQuest_InfoWindow:SetText(msg)
	g_FrameInfo = FrameInfoList.PLAYERSHOP_CONFIRM_MULTIBUY;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "YBMARKET_CONFIRM_MULTIBUY"
function WuhunQuest_Open_Window_YBM_MultiBuy(arg0, arg1, arg2, arg3)
	local msg = ScriptGlobal_Format( "#{SHPLGM_150428_27}", arg0, arg1, arg2, arg3)
	WuhunQuest_InfoWindow:SetText(msg)
	g_FrameInfo = FrameInfoList.YBMARKET_CONFIRM_MULTIBUY;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "TMARKET_CONFIRM_MULTIBUY"
function WuhunQuest_Open_Window_YBM_TMultiBuy(arg0, arg1, arg2, arg3)
	local msg = ScriptGlobal_Format( "#{SHPLGM_150428_27}", arg0, arg1, arg2, arg3)
	WuhunQuest_InfoWindow:SetText(msg)
	g_FrameInfo = FrameInfoList.TMARKET_CONFIRM_MULTIBUY;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
-- event == "YBMARKET_TAKE_BACK_COMFIRM"
function WuhunQuest_Open_Window_YBM_TakeBack(nType , nIndex)
	g_FrameVar[1] = tonumber(nType)
	g_FrameVar[2] = tonumber(nIndex)
	local pName = Auction:GetMySellBoxItemName(g_FrameVar[1] , g_FrameVar[2])
	WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_76}"..pName.."#{YBSC_XML_77}");	-- 设置内容
	g_FrameInfo = FrameInfoList.YBMARKET_TAKE_BACK_COMFIRM
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_SellItemConfirm(nItemPos)
	g_FrameVar[1] = tonumber(nItemPos)
	WuhunQuest_InfoWindow:SetText("#{ZBBH_100505_1}");	-- 设置内容
	g_FrameInfo = FrameInfoList.SELL_ITEM_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_SellItemConfirmQ8(nItemPos,equipQual,situation)
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
		local strMsg = "#{BXZBQR_210623_01}"
		if situation == 2 then
			strMsg = "#{BXZBQR_210623_03}"
		end
		g_FrameVar[1] = tonumber(nItemPos)
		WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format(strMsg,equipStar));	-- 设置内容
		g_FrameInfo = FrameInfoList.SELL_ITEM_CONFIRM;
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
		WuhunQuestUpdateRect();
		DataPool:SetCanUseHotKey(0)
		this:Show();
	else
		--如果不为8星以上 还是直接卖了
		PlayerPackage:SellCurrItem( tonumber(nItemPos))
	end
end

-- event == "PET_EQUIP_SUITUP_CONFIRM"
function WuhunQuest_Open_Window_PetEquipSuitUp(nType, nEquipPos, nItemNum, nPercent, nObjCareId)
	g_FrameVar[1] = nType
	g_FrameVar[2] = nEquipPos
	g_FrameVar[3] = nItemNum
	g_FrameVar[4] = nPercent
	g_FrameVar[5] = nObjCareId
	--需要换字典号（暂时使用自己配置的）
	if (nPercent == 100) then
		WuhunQuest_InfoWindow:SetText("#{ZSZB_SJ_01}" ..nItemNum .."#{ZSZB_SJ_02}"..nPercent.."%#{ZSZB_SJ_03}#G")
	else
		WuhunQuest_InfoWindow:SetText("#{ZSZB_SJ_01}" ..nItemNum .."#{ZSZB_SJ_02}#cff0000"..nPercent.."%#{ZSZB_SJ_03}#G")
	end

	g_FrameInfo = FrameInfoList.PET_EQUIP_SUITUP_CONFIRM
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

-- event == "PET_EQUIP_SUITUP_CONFIRM"
function WuhunQuest_Window_PetEquipSuitUp_Confirm()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnPetEquipSuitUp")
		Set_XSCRIPT_ScriptID(800109)
		Set_XSCRIPT_Parameter(0,tonumber(g_FrameVar[2]))
		Set_XSCRIPT_Parameter(1,tonumber(g_FrameVar[5]))
		Set_XSCRIPT_Parameter(2,tonumber(g_FrameVar[3]))
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT();
	Player:CommonClientMessage(20100524,0,0,0,0,0)
end

-- event == "FRIEND_PRESENT_CONFIRM"
function WuhunQuest_Open_Window_FriendPresentConfirm(str)
	WuhunQuest_Clear_Var();
	WuhunQuest_InfoWindow:SetText(str);
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.FRIEND_PRESENT_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

-- event == "DEMAIL_PRESENT_CONFIRM"
function WuhunQuest_Open_Window_MailPresentConfirm(nIndex)


	g_FrameEvent = nIndex;

	WuhunQuest_Clear_Var();

	local playerName = MailSystem:ReadSendMail("MailName")
	local guid = MailSystem:ReadSendMail("MailGUID")
	local money = MailSystem:ReadSendMail("MailMoney")
	local reqMoney = MailSystem:ReadSendMail("ReqMoney")

	--local szTime =string.format("%X",guid)
	local szTime = guid

	local moneytext = ""
	if money == 0 then
		moneytext = "无"
	else
		moneytext = string.format("#{_MONEY%d}", money)
	end
	local petname = MailSystem:ReadSendMail("MailPetName")
	local Pettext = ""
	if petname == "" then
		Pettext ="无"
	else
		Pettext = petname
	end


	local itemName =""
	for i = 0,4 do
		local Name = MailSystem:ReadBagIndex(i)
		if Name ~= nil and Name ~= "" then
			if itemName~= ""then
				itemName = itemName..","
			end
			itemName = itemName..Name
		end
	end

	if itemName == "" then
		itemName = "无"
	end

	--收费
	local reqText =""
	if reqMoney > 0 then
		reqText = string.format("#{_MONEY%d}", reqMoney)
	else
		reqText ="无"
	end

	--手续费用
	local level = Player:GetData("LEVEL")
	local charge = MailSystem:MailCharge(level)
	local chargetext = string.format("#{_EXCHG%d}", charge)

	if nIndex == 1 then  -- 发送框
		szTime = szTime.."#r".."#{FJYX_110426_95}"..moneytext.."#r"
		szTime = szTime.."#{FJYX_110426_96}"..Pettext.."#r"
		szTime = szTime.."#{FJYX_110426_97}"..itemName.."#r"
		szTime = szTime.."#{FJYX_110426_98}"..reqText.."#r#r"
		szTime = szTime.."#{FJYX_110426_100}" .. chargetext .. "#{FJYX_110426_205}"
		WuhunQuest_InfoWindow:SetText("#{FJYX_110426_123}"..tostring(playerName).."#r".."#{FJYX_110426_124}"..tostring(szTime))
	elseif nIndex == 2 then  --收取附件框
		szTime = szTime.."#r".."#{FJYX_110426_95}"..moneytext.."#r"
		szTime = szTime.."#{FJYX_110426_96}"..Pettext.."#r"
		szTime = szTime.."#{FJYX_110426_97}"..itemName.."#r"
		szTime = szTime.."#{FJYX_110426_98}"..reqText.."#r#r"
		szTime = szTime.."#{FJYX_110426_126}".."#r"
		WuhunQuest_InfoWindow:SetText("#{FJYX_110426_93}"..tostring(playerName).."#r".."#{FJYX_110426_94}"..tostring(szTime))
	elseif nIndex == 3 then  --删除与回退附件框
		if reqMoney > 0 then
			WuhunQuest_InfoWindow:SetText("#{FJYX_110426_129}");
		else
			WuhunQuest_InfoWindow:SetText("#{FJYX_110426_128}");
		end
	elseif nIndex == 4 then  --邮件提示
		WuhunQuest_InfoWindow:SetText("#{FJYX_110426_43}");
	end



	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.DEMAIL_PRESENT_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	DataPool:SetCanUseHotKey(0)
	this:Show();
end


function WuhunQuest_Open_Window_KAuctionBuyConfirm(nType, nIndex, nPrice)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nType)
	g_FrameVar[2] = tonumber(nIndex)
	g_FrameVar[3] = tonumber(nPrice)
	local unitName = ""
	if g_FrameVar[1] == 1 then
		local pName , pSeller ,pCount ,pYB = TAuction:GetItemAuctionInfo( nType, nIndex )
		unitName =  pName
		WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_73}"..tostring(pYB).."#{YBSC_XML_74}"..tostring(pCount).."#{YBSC_XML_79}"..unitName.."#{YBSC_XML_75}");	-- 设置内容
	elseif g_FrameVar[1] == 2 then
		local pName , pSeller ,pCount ,pMoney = TAuction:GetItemAuctionInfo( nType, nIndex )
		unitName = pName
		WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_73}".."#{_MONEY"..tostring(pMoney).."}#{KVKGZ_110620_103}"..unitName.."#{YBSC_XML_75}");	-- 设置内容
	end
	g_FrameInfo = FrameInfoList.TAUCTION_BUY_COMFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_KAuctionUpItemConfirm(nType, nIndex, nPrice)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = nType
	g_FrameVar[2] = nIndex
	g_FrameVar[3] = nPrice
	local itemName = PlayerPackage:GetBagItemName(nIndex)
	local needMoney = TAuction:GetNeedMoneyForSell(nPrice, nType)
	if nType == 1 then --元宝市场
		WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_65}"..itemName.."#{YBSC_XML_66}"..tostring(nPrice).."#{YBSC_XML_67}".."#{_EXCHG"..tostring(needMoney).."}".."#{YBSC_XML_68}");	-- 设置内容
	elseif nType == 2 then
		WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_65}"..itemName.."#{YBSC_XML_66}#{_MONEY"..tostring(nPrice).."}#{KVKGZ_110620_58}".."#{_EXCHG"..tostring(needMoney).."}".."#{YBSC_XML_68}");	-- 设置内容
	end
	g_FrameInfo = FrameInfoList.TAUCTION_UP_COMFIRM ;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_KAuctionTakeBackConfirm(nType, nIndex)
	g_FrameVar[1] = nType
	g_FrameVar[2] = nIndex
	local pName = TAuction:GetMySellBoxItemAuctionInfo(g_FrameVar[1] , g_FrameVar[2])
	WuhunQuest_InfoWindow:SetText( "#{YBSC_XML_76}"..pName.."#{YBSC_XML_77}");	-- 设置内容
	g_FrameInfo = FrameInfoList.TAUCTION_TAKEBACK_COMFIRM
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_CarriageCancelImpactConfirm(type, buffid)
	g_FrameVar[1] = type
	g_FrameVar[2] = buffid
	if type == 1 then
		WuhunQuest_InfoWindow:SetText( "#{TWLK_150804_170}");
	elseif type == 2 then
		WuhunQuest_InfoWindow:SetText( "#{TWLK_150804_67}");
	end	
	g_FrameInfo = FrameInfoList.CARRIAGE_CANCELIMPACT_CONFIRM
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_CarriageSendImpactConfirm(allianceId, index)
	g_FrameVar[1] = allianceId
	g_FrameVar[2] = index
	WuhunQuest_InfoWindow:SetText( "#{TWLK_150804_211}");
	g_FrameInfo = FrameInfoList.CARRIAGE_SENDIMPACT_CONFIRM
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_ShouLanOperationConfirm( npcid, index, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(npcid)
	g_FrameVar[2] = tonumber(index)

	WuhunQuest_InfoWindow:SetText( strMsg )

	g_FrameInfo = FrameInfoList.SHOULAN_OPERATION_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BZYJ_151123_69}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BZYJ_151123_70}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_ShouLanPromoteConfirm( nSelectLevel, nOperType, petGuidH, petGuidL, timeLevel, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nSelectLevel)
	g_FrameVar[2] = tonumber(nOperType)
	g_FrameVar[3] = tonumber(petGuidH)
	g_FrameVar[4] = tonumber(petGuidL)
	g_FrameVar[5] = tonumber(timeLevel)

	WuhunQuest_InfoWindow:SetText( strMsg )

	g_FrameInfo = FrameInfoList.SHOULAN_PROMOTE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BZYJ_151123_69}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BZYJ_151123_70}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_BieYeMaterialOutputGardenerConfirm( npcid, nMissionType, nBuildIndex, nOutputID, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(npcid)
	g_FrameVar[2] = tonumber(nMissionType)
	g_FrameVar[3] = tonumber(nBuildIndex)
	g_FrameVar[4] = tonumber(nOutputID)

	WuhunQuest_InfoWindow:SetText( strMsg )

	g_FrameInfo = FrameInfoList.BIEYEMATERIALOUTPUT_GARDENER_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BZYJ_151123_69}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BZYJ_151123_70}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_BieYeMaterialOutputCostYBConfirm( npcid, nMissionType, nBuildIndex, nOutputID, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(npcid)
	g_FrameVar[2] = tonumber(nMissionType)
	g_FrameVar[3] = tonumber(nBuildIndex)
	g_FrameVar[4] = tonumber(nOutputID)

	WuhunQuest_InfoWindow:SetText( strMsg )

	g_FrameInfo = FrameInfoList.BIEYEMATERIALOUTPUT_COSTYB_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BZYJ_151123_69}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BZYJ_151123_70}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_BieYeMaterialOutputCancelConfirm( npcid, nMissionType, nBuildIndex, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(npcid)
	g_FrameVar[2] = tonumber(nMissionType)
	g_FrameVar[3] = tonumber(nBuildIndex)

	WuhunQuest_InfoWindow:SetText( strMsg )

	g_FrameInfo = FrameInfoList.BIEYEMATERIALOUTPUT_CANCEL_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BZYJ_151123_69}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BZYJ_151123_70}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_YingJieExchangeConfirm( index, itemid, value )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(index)

	local strName = PlayerPackage:GetItemName(tonumber(itemid))
	local strMsg = ScriptGlobal_Format("#{BZYJ_151123_68}", strName, tonumber(value))

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.YINGJIE_EXCHANGE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BZYJ_151123_69}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BZYJ_151123_70}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_SuperWeaponDIYSkillConfirm( strMsg, nType, npcId, bagIndex, slotIndex, impactIndex )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType)
	g_FrameVar[2] = tonumber(npcId)
	g_FrameVar[3] = tonumber(bagIndex)
	g_FrameVar[4] = tonumber(slotIndex)
	g_FrameVar[5] = tonumber(impactIndex)

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.SUPERWEAPONDIYSKILL_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{JXSQ_170804_28}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{JXSQ_170804_16}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_SuperWeaponDIYSkillExchange( strMsg, npcId, nIndex )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(npcId)
	g_FrameVar[2] = tonumber(nIndex)

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.SUPERWEAPONDIYSKILL_EXCHANGE;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{JXSQ_170804_28}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{JXSQ_170804_16}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

--2021双旦集五福
function WuhunQuest_Open_Window_FHSXBuyConfirm( nIndex, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nIndex)

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.FHSXBUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{JXSQ_170804_28}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{JXSQ_170804_16}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

--紫薇灵魄购买
function WuhunQuest_Open_Window_ZWLPBuyConfirm( nIndex, nTargetId, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(nTargetId)

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.CONFIRM_BUY_ZIWEILINGPO;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{GMZWLP_230524_13}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{GMZWLP_230524_14}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

--【2022Q2】儿童节代币转换
function WuhunQuest_Open_Window_ErTongJieDaiBiConfirm( nItemId, nNum, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nItemId)
	g_FrameVar[2] = tonumber(nNum)

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.ERTONGJIEDAIBI_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{DBZH_220419_54}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{DBZH_220419_55}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_CHGConfirm(targetid, score)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetid)
	local str = ScriptGlobal_Format("#{BWQH_211027_103}", tostring(score))
	WuhunQuest_InfoWindow:SetText( str );
	g_FrameInfo = FrameInfoList.CHIHUOGUO_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BWQH_211027_104}");  --是
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BWQH_211027_105}");  --否
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function WuhunQuest_Open_Window_BSnConfirm(targetid, score)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetid)
	local str = ScriptGlobal_Format("#{XXJQ_20231130_91}", tostring(score))
	WuhunQuest_InfoWindow:SetText( str );
	g_FrameInfo = FrameInfoList.CONFIRM_BUILD_SNOWMAN;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XXJQ_20231130_92}");  --是
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{XXJQ_20231130_93}");  --否
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function WuhunQuest_Open_Window_TLGConfirm(targetid)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetid)
	WuhunQuest_InfoWindow:SetText( "#{XXJQ_20231130_110}" );
	g_FrameInfo = FrameInfoList.CONFIRM_TLG;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XXJQ_20231130_92}");  --是
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{XXJQ_20231130_93}");  --否
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function WuhunQuest_Open_Window_STConfirm(targetid, score)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetid)
	local tipstr = "#{ZJSS_220803_108}" 
	WuhunQuest_InfoWindow:SetText( tipstr );
	g_FrameInfo = FrameInfoList.SAVETREE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZJSS_220803_110}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZJSS_220803_111}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function WuhunQuest_Open_Window_JieHunHuiKuiPrizeConfirm( strMsg, tabIndex, selectIndex )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(tabIndex)
	g_FrameVar[2] = tonumber(selectIndex)

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.JIEHUNHUIKUI_PRIZE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{JHJL_160106_35}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{JHJL_160106_36}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_DeleteGXHConfirm( strMsg, nType, nIndex )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nIndex);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.DELETEGXH_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_ConvenintBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID, nBuyCount )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);
	g_FrameVar[8] = tonumber(nBuyCount);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.CONVENIENT_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_PetYanShouBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETYANSHOU_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_PetXiDianBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETXIDIAN_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
function WuhunQuest_Open_Window_PetHuanHuaBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETHUANHUA_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_PetEquipRefreshBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETEQUIPREFRESH_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_PetSignleProcreateBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETSINGLEPROCREATE_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_BieYePetSignleProcreateBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.BIEYEPETSINGLEPROCREATE_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_WuYiBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.WuYi_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_ShenqiJiemengConfirm( strMsg )
	WuhunQuest_Clear_Var()

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.SHENQI_JIEMENG_CONFIRM;
	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_BieYePetPaintBuyConfirm( strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nScriptID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nScriptID);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.BIEYEPETPAINT_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
function WuhunQuest_Open_Window_DakongConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.NEW_DAKONG_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_WuHunConvenientBuyItemConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.WUHUN_CONVENIENTBUYITEM_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_WuHunQuickUpConfirm( nType, nIndex, nParam, strMsg )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nIndex);
	g_FrameVar[3] = tonumber(nParam);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.WUHUN_QUICKUP_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_HuantongConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )--add:lby2015还童
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PET_HUANTONT_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_EquipRepairConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )--add:lby2015还童
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.EQUIP_REPAIRTIMES_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CZDYH_161107_09}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CZDYH_161107_10}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_DWBuyConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, nNum )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nNum)
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.DIAOWEN_YUANBAO_PAY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_RHDConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )--add:lby2015融合
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PET_RHD_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_ZXConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )--珍兽转性
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.CONFIRM_PETZHUANXING_PAY;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSZHD_220620_29}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSZHD_220620_30}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end


function WuhunQuest_Open_Window_LingxingConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )--add:lby2015提灵
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PET_LINGXING_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_XiangqianConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.NEW_XIANGQIAN_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end
function WuhunQuest_Open_Window_ZhaichuConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.NEW_ZHAICHU_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end


function WuhunQuest_SuperWeaponSoulless_Confirm(nParam)
	local strText = "#{SQSX_171211_93}"
	if nParam > 0 then
		strText = ScriptGlobal_Format("#{SQSX_171211_92}", nParam)
	end
	-- local strText = "#{SQSX_120806_81}";
	-- strText = strText .. "" .. nParam .. "#{SQSX_120806_86}"
	WuhunQuest_InfoWindow:SetText( strText );

	g_FrameInfo = FrameInfoList.SUPERWEAPONSOULLESS_CONFIRM
	WuhunQuest_Button1:Hide()
	WuhunQuest_Button1:SetText("");  --不显示
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{SQSX_120806_73}");  --确定

	WuhunQuestUpdateRect();
	this:Show();
end
function WuhunQuest_DeleteComboBook_Confirm(nParam)
	local bookname = Player:GetComboBookInfo(nParam, "bookname");
	local bookitemid = Player:GetComboBookInfo(nParam, "bookitemId");
	local strText = ScriptGlobal_Format("#{WLMJ_130121_48}", bookname )
	if( bookitemid == 30311205 or bookitemid == 30311210 ) then
		strText = strText.."#{WLMJ_130121_77}"
	end
	g_FrameInfo = FrameInfoList.DELETE_COMBOBOOK_CONFIRM
	WuhunQuest_InfoWindow:SetText( strText );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
end

--function WuhunQuest_ForbidIt_Confirm( strText )

--	WuhunQuest_InfoWindow:SetText( strText );

--	g_FrameInfo = FrameInfoList.FORBIDIT_CONFIRM;
--	WuhunQuest_Button1:Show()
--	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
--	WuhunQuest_Button2:Show()
--	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
--	WuhunQuestUpdateRect();
--	DataPool:SetCanUseHotKey(0)
--	this:Show();
--end

--function WuhunQuest_ForbidIt_ConfirmByNameAndID( strText,nName )
--	WuhunQuest_Clear_Var()
--	g_FrameVar[1] = nName
--	WuhunQuest_InfoWindow:SetText( strText );
--	g_FrameInfo = FrameInfoList.FORBIDIT_CONFIRMBYNAMEANDFIND;
--	WuhunQuest_Button1:Show()
--	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
--	WuhunQuest_Button2:Show()
--	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
--	WuhunQuestUpdateRect();
--	DataPool:SetCanUseHotKey(0)
--	this:Show();
--end

function WuhunQuest_QuickUpPet_Confirm(nType,nCurData,nPrice,nUplimit,strMsg)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nType);

	local strText

	if nType == 1 then
		-- 悟性
		strText = ScriptGlobal_Format("#{ZSKJT_130428_5}",strMsg,nCurData,nPrice)
	elseif nType == 2 then
		-- 灵性
		strText = ScriptGlobal_Format("#{ZSKJT_130428_10}",strMsg,nCurData,nPrice);
	elseif nType == 3 then
		-- 融合度
		strText = ScriptGlobal_Format("#{ZSKJT_130428_17}",strMsg,nCurData,nPrice);
	elseif nType == 4 then
		-- 成长率
		strText = ScriptGlobal_Format("#{ZSKJT_130428_26}",strMsg,nCurData,nUplimit,nPrice);
		

	end

	g_FrameInfo = FrameInfoList.QUICKUP_PET_CONFIRM
	WuhunQuest_InfoWindow:SetText( strText );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
end

function WuhunQuest_EquipDecompose_Confirm(equiplock,GetStrengthenLevel,IsHaveAttaProperty,bHaveSL)
	local strText = "#{ZBSX_171106_01}"
	if equiplock > 0 then
		strText = strText.."#{ZBSX_171106_02}"
	end
	
	if GetStrengthenLevel > 0 then
		strText = strText.."#{ZBSX_171106_03}"
	end
	
	if IsHaveAttaProperty > 0 then
		strText = strText.."#{ZBSX_171106_04}"
	end
	
	if bHaveSL > 0 then
		strText = strText.."#{ZBSX_171106_05}"
	end

	strText = strText.."#{ZBSX_171106_06}"
	
	g_FrameInfo = FrameInfoList.EQUIP_DECOMPOSE_CONFIRM
	WuhunQuest_InfoWindow:SetText( strText );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_EquipTemper_Confirm()
	g_FrameInfo = FrameInfoList.EQUIP_TEMPER_CONFIRM
	local itemname = PlayerPackage:GetItemName(20700063);
	local strInfo = ScriptGlobal_Format("#{ZBSX_130625_90}", itemname,itemname)
	WuhunQuest_InfoWindow:SetText( strInfo );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBSX_130625_70}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
end

function WuhunQuest_EquipTemper_QueRenConfirm(ProName,nCount,nSameCount)
	g_FrameInfo = FrameInfoList.EQUIP_TEMPER_QUERENCONFIRM
	--local strInfo = string.format("您的装备已存在相同的精通属性：%s，且没有被锁定，继续淬炼精通属性将会被替换。提示：您可以锁定需要的精通属性后，再继续淬炼。点击“关闭”按钮关闭本界面。",ProName)
	local strInfo = ""
	if(nCount ~= nSameCount) then
		strInfo = ScriptGlobal_Format("#{CLYH_160607_03}",nSameCount,ProName,nCount)
	else
		strInfo = ScriptGlobal_Format("#{CLYH_160620_04}",nSameCount,ProName)
	end
	WuhunQuest_InfoWindow:SetText( strInfo );
	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_1173}");  --关闭
	WuhunQuestUpdateRect();
	this:Show();
end

function WuhunQuest_EquipFuKe_Confirm()
	g_FrameInfo = FrameInfoList.EQUIP_ATTRFUKE_CONFIRM 
	WuhunQuest_InfoWindow:SetText( "#{JTFK_1117_31}" );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{JTFK_1117_32}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{JTFK_1117_33}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
end

function WuhunQuest_EquipTransfer_Confirm(messagetype)
	local str =""
	if(messagetype == 0) then
		str = "#{ZBSX_130625_120}"
	elseif (messagetype == 1) then
		str = "#{ZBSX_130625_121}"
	elseif (messagetype == 2) then
		str = "#{ZBSX_180502_133}" --"精通属性转移成功后，接受转移的装备将与您绑定。#r如果确认继续进行转移，点击确定后，再次点击转移按钮即可完成。"

	end

	g_FrameInfo = FrameInfoList.EQUIP_TRANSFER_CONFIRM
	WuhunQuest_InfoWindow:SetText( str );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
end

function WuhunQuest_EquipUpdate_Confirm()
	local strInfo = ScriptGlobal_Format("#{ZBSX_130625_102}", PlayerPackage:GetItemName(20700055),PlayerPackage:GetItemName(20700055))
		-- str = "#{ZBSX_130625_102}"
	g_FrameInfo = FrameInfoList.EQUIP_UPDATE_CONFIRM
	WuhunQuest_InfoWindow:SetText( strInfo );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
end

function WuhunQuest_EquipUpdate_ConfirmEx(itemindex)
	local strInfo = ScriptGlobal_Format("#{ZBSX_130625_103}", PlayerPackage:GetItemName(itemindex))
	g_FrameInfo = FrameInfoList.EQUIP_UPDATE_CONFIRMEX
	WuhunQuest_InfoWindow:SetText( strInfo );
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
end

function WuhunQuest_InfantCardCompose_Confirm()
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(arg0)
	g_FrameVar[2] = tonumber(arg1)
	-- ObjCaredID = tonumber(arg2); --这里不需要在使用GetNPCIDByServerID了
	-- if ObjCaredID ~= -1 then
	-- 	--开始关心NPC
	-- 	this:CareObject(ObjCaredID, 1, "MsgBox");
	-- end
	WuhunQuest_InfoWindow:SetText("#{KPWFS_131112_27}" )
	WuhunQuestUpdateRect();
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	g_FrameInfo = FrameInfoList.INFANT_CARD_COMPOSE_CONFIRM
	this:Show();
end

function WuhunQuest_InfantCardStrength_Confirm()
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(arg0)
	-- ObjCaredID = tonumber(arg1); --这里不需要在使用GetNPCIDByServerID了
	-- if ObjCaredID ~= -1 then
	-- 	--开始关心NPC
	-- 	this:CareObject(ObjCaredID, 1, "MsgBox");
	-- end
	WuhunQuest_InfoWindow:SetText("#{KPWFS_131112_49}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.INFANT_CARD_STRENGTH_CONFIRM
	this:Show();
end

function WuhunQuest_InfantCardTransfer_Confirm()
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(arg0)
	g_FrameVar[2] = tonumber(arg1)
	-- ObjCaredID = tonumber(arg2); --这里不需要在使用GetNPCIDByServerID了
	-- if ObjCaredID ~= -1 then
	-- 	--开始关心NPC
	-- 	this:CareObject(ObjCaredID, 1, "MsgBox");
	-- end
	WuhunQuest_InfoWindow:SetText("#{KPWFS_131112_70}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.INFANT_CARD_TRANSFER_CONFIRM
	this:Show();
end

function WuhunQuest_New_MonthCard_OperationConfirm(newMonthcardType,buyMonthcardType)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = buyMonthcardType
	if newMonthcardType == 1 then
		WuhunQuest_InfoWindow:SetText("#{YKJY_231113_30}")
	elseif newMonthcardType == 2 then
		local diffPriceContent = {
			[1] = "#{JKYL_260106_02}",
			[2] = "#{JKYL_251211_21}"
		}
		WuhunQuest_InfoWindow:SetText(diffPriceContent[buyMonthcardType])
	else
		WuhunQuest_InfoWindow:SetText("#{YKJY_231113_30}")
	end
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{YKJY_231113_31}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{YKJY_231113_32}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.CONFIRM_NEWMONTHCARD
	this:Show();
end

function WuhunQuest_EquipLingPai_OpClose_Confirm()
	WuhunQuest_Clear_Var()
--	g_FrameVar[1] = tonumber(arg0)
--	g_FrameVar[2] = tonumber(arg1)

	WuhunQuest_InfoWindow:SetText("#{BHZB_140521_96}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.EQUIPLINGPAI_OP_CLOSE_CONFIRM
	this:Show();
end

function WuhunQuest_Zhizunhaoli_Confirm(ybcost,itemcount,freecount,nType)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nType)
--	g_FrameVar[2] = tonumber(arg1)
	local strInfo = ScriptGlobal_Format("#{ZZQH_140606_71}", ybcost,itemcount,freecount,freecount*200)
	if nType == 7 then
		strInfo = "#{ZZQH_140606_121}"
	end
	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.ZHIZUNHAOLI_CONFIRM
	this:Show();
end

function WuhunQuest_Open_Window_BaoShiyiConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID,nNum)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;
	g_FrameVar[7] = tonumber(nNum);
	g_FrameInfo = FrameInfoList.BAOSHI_YI_CONFIRM;

	WuhunQuest_InfoWindow:SetText(strMsg)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();

	this:Show();
end


function WuhunQuest_Zhizun_Confired(nType)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClientAskAward");
		Set_XSCRIPT_ScriptID(890890);
		Set_XSCRIPT_Parameter(0,nType);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end

function WuhunQuest_Equipattr_confirm(nIndex,keepopen)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(keepopen)
	local strInfo = "#{ZBCZ_140618_09}"
	if keepopen == 0 then
		strInfo = "#{ZBCZ_140618_16}"
	elseif keepopen == 1 then
		strInfo = "#{ZBCZ_140618_09}"
	elseif  keepopen == 2 then
		strInfo = "#{ZBCZ_140618_06}"
	end

	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.EQUIPATTR_CHANGEEQUIP_CONFIRM
	this:Show();
end

function WuhunQuest_DarkSkill_confirm(nIndex,keepopen)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(keepopen)
	local strInfo = "#{CXYH_140813_4}"
	if keepopen == 0 then
		strInfo = "#{CXYH_140813_3}"
	elseif keepopen == 1 then
		strInfo = "#{CXYH_140813_4}"
	elseif  keepopen == 2 then
		strInfo = "#{CXYH_140813_2}"
	elseif keepopen == 3 then
		strInfo = "#{AQJJ_160127_46}"
	end

	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.DARK_SKILL_RECOIN_CONFIRM
	this:Show();
end

function WuhunQuest_EquipZiZhi_confirm(nIndex,keepopen)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(keepopen)
	local strInfo = "#{ZZCX_11119_09}"
	if keepopen == 0 then
		strInfo = "#{ZZCX_11119_13}"
	elseif keepopen == 1 then
		strInfo = "#{ZZCX_11119_09}"
	elseif  keepopen == 2 then
		strInfo = "#{ZZCX_11119_12}"
	end

	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.EQUIP_ZIZHI_RECOIN_CONFIRM
	this:Show();
end
function WuhunQuest_PetEquipZiZhi_confirm(nIndex,keepopen)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(keepopen)
	local strInfo = "#{ZZCX_11119_09}"
	if keepopen == 0 then
		strInfo = "#{ZZCX_11119_13}"
	elseif keepopen == 1 then
		strInfo = "#{ZZCX_11119_09}"
	elseif  keepopen == 2 then
		strInfo = "#{ZZCX_11119_12}"
	end

	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.PETEQUIP_ZIZHI_RECOIN_CONFIRM
	this:Show();
end

function WuhunQuest_WuhunSkill_confirm(nIndex,keepopen)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(keepopen)
	local strInfo = "#{WHZN_141216_17}"
--	PushDebugMessage(keepopen)
	if keepopen == 0 then --关闭
		strInfo = "#{WHZN_141216_5}"
	elseif keepopen == 1 then  --更换
		strInfo = "#{WHZN_141216_17}"
	elseif  keepopen == 2 then  --取消放入
		strInfo = "#{WHZN_141216_2}"
	end

	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.WUHUN_SKILL_RECOIN_CONFIRM
	this:Show();
end
function WuhunQuest_InfantSkill_confirm()
	WuhunQuest_Clear_Var()

	local strInfo = "#{WHZN_141216_42}"


	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.INFANT_SKILL_RECOIN_CONFIRM
	this:Show();
end



function WuhunQuest_LW_ATTR_confirm(nIndex,keepopen)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(keepopen)
	local strInfo = "#{CXYH_140813_52}"
	if keepopen == 0 then
		strInfo = "#{CXYH_140813_51}"
	elseif keepopen == 1 then
		strInfo = "#{CXYH_140813_52}"
	elseif  keepopen == 2 then
		strInfo = "#{CXYH_140813_50}"
	end

	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.LW_ATTR_RECOIN_CONFIRM
	this:Show();
end

function WuhunQuest_Super_ATTR_confirm(nIndex,keepopen)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nIndex)
	g_FrameVar[2] = tonumber(keepopen)
	local strInfo = "#{CXYH_140813_31}"
	if keepopen == 0 then
		strInfo = "#{CXYH_140813_30}"
	elseif keepopen == 1 then
		strInfo = "#{CXYH_140813_31}"
	elseif  keepopen == 2 then
		strInfo = "#{CXYH_140813_29}"
	end

	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.SUPER_ATTR_RECOIN_CONFIRM
	this:Show();
end



function WuhunQuest_Equipattr_bindconfirm(itemid)
	WuhunQuest_Clear_Var()
	local itemname = PlayerPackage:GetItemName(tonumber(itemid))
	local strInfo = ScriptGlobal_Format("#{ZBCZ_140618_32}", itemname,itemname)
	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZBCZ_140618_07}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZBCZ_140618_08}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.EQUIPATTR_BIND_CONFIRM
	this:Show()
end

function WuhunQuest_DoubleSeckill_confirm()
	-- g_FrameVar[1] = tonumber(arg0) --操作类型 1消耗元宝 2消耗元宝+消耗低级和高级扫荡点 3消耗低级和高级扫荡点
	-- g_FrameVar[2]= tonumber(arg1) --BossIndex
	-- g_FrameVar[3] = tonumber(arg2) --元宝
	-- g_FrameVar[4] = tonumber(arg2) --SweepPage_open_fubenIndexId
	local opType = g_FrameVar[1]
	local IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao = Lua_GetSecKillInfoByFuBenIndexID(g_FrameVar[4])
	if nil == IconName then
		this:Hide()
		return
	end
	local itemID, itemNum = LuaFnGetSecKillInfoByFuBenIndexIDEx(g_FrameVar[4], "Item")
	if nil == itemID or nil == itemNum then
		this:Hide()
		return
	end
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(itemID)
	
	if SecKillNeedNumType == 2 and 
		(opType == 2 or opType == 3 or opType == 5) then
		return
	end
	local doubleOp  = 0 --双倍操作 1元宝 2道具
	if opType == 1 or opType == 2 then
		if itemID > 0 and itemNum > 0 and itemcount >= itemNum then
			doubleOp = 2
		else
			doubleOp = 1
		end
	end
	if opType == 4 or opType == 5 then
		doubleOp = 1
	end
	local needHightSeckill = 0
	if SecKillNeedNumType == 1 then
		if LowSecKillNum  + HightSecKillNum < SecKillNeedNum then
			this:Hide()
			return
		end
		needHightSeckill = SecKillNeedNum - LowSecKillNum
		if LowSecKillNum >= SecKillNeedNum then
			needHightSeckill = 0
		end
	end
	if LowSecKillNum < 0 then
		LowSecKillNum = 0
	end

	local strInfo = ""
	if doubleOp == 2 then
		if opType == 1 then
			strInfo = ScriptGlobal_Format("#{FBSD_150126_53}", itemNum )
		elseif opType == 2 then
			strInfo = ScriptGlobal_Format("#{SDXG_20210624_18}", itemNum, needHightSeckill, LowSecKillNum )
		end
	elseif doubleOp == 1 then
		if opType == 1 then
			strInfo = ScriptGlobal_Format("#{FBSD_201119_03}", g_FrameVar[3] )
		elseif opType == 2 then
			strInfo = ScriptGlobal_Format("#{FBSD_201119_04}", g_FrameVar[3], needHightSeckill, LowSecKillNum )
		elseif opType == 4 then
			strInfo = ScriptGlobal_Format("#{GXB_220929_4}", g_FrameVar[3] )
		elseif opType == 5 then
			strInfo = ScriptGlobal_Format("#{GXB_220929_5}", g_FrameVar[3], needHightSeckill, LowSecKillNum )
		end
	else
		strInfo = ScriptGlobal_Format("#{SDXG_20210624_19}", needHightSeckill, LowSecKillNum )
	end

	g_FrameVar[5] = doubleOp
	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LS78_140819_55}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LS78_140819_56}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.DOUBLE_SECKILL_CONFIRM
	this:Show()
end

function WuhunQuest_DoubleDailySeckill_confirm(BossIndex, needYuanbao)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(BossIndex)

	--local strInfo = ScriptGlobal_Format("#{FBSD_150126_53}", needYuanbao )
	WuhunQuest_InfoWindow:SetText("#{JFRW_170217_46}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LS78_140819_55}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LS78_140819_56}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.DOUBLE_DAILYSECKILL_CONFIRM
	this:Show()
end

function WuhunQuest_SeckillGiveUp_confirm()
	WuhunQuest_Clear_Var()

	WuhunQuest_InfoWindow:SetText("#{FBSD_151123_07}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LS78_140819_55}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LS78_140819_56}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.SECKILL_GIVEUP_CONFIRM
	this:Show()
end

function WuhunQuest_SeckillGiveUp_ZhaoHui_confirm()
	WuhunQuest_Clear_Var()

	WuhunQuest_InfoWindow:SetText("#{XTZY_171213_50}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LS78_140819_55}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LS78_140819_56}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.SECKILL_GIVEUP_CONFIRM_ZHAOHUI
	this:Show()
end

function WhunQuest_DecoWeaponConver_confirm(bagPos)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = bagPos
	local strInfo = ScriptGlobal_Format("#{DECOW_160126_34}", PlayerPackage:GetBagItemName(bagPos) )
	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LS78_140819_55}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LS78_140819_56}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.DECOWEAPON_CONVER_CONFIRM
	this:Show()
end

function WhunQuest_DecoWeaponLevelup_confirm(WeaponBagPos)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = WeaponBagPos
	local strInfo = ScriptGlobal_Format("#{DECOW_160126_57}", PlayerPackage:GetBagItemName(WeaponBagPos) )
	WuhunQuest_InfoWindow:SetText(strInfo)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LS78_140819_55}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LS78_140819_56}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.DECOWEAPON_LEVELUP_CONFIRM
	this:Show()
end

function WuhunQuest_ShenDing_Reset_confirm( nScriptId )
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nScriptId)

	WuhunQuest_InfoWindow:SetText( "#{XLDL_140606_150}" )
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XLDL_140606_121}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{XLDL_140606_151}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.SHENDING_RESET_CONFIRM
	this:Show()
end

function WuhunQuest_HxyEffectActiveConfirm(nIndex )

	local strVar = ""
	if nIndex == 1 then
		strVar = ScriptGlobal_Format("#{HXYSJ_141031_151}", "#{HXYSJ_141031_79}")
	elseif nIndex == 2 then
		strVar = ScriptGlobal_Format("#{HXYSJ_141031_151}", "#{HXYSJ_141031_80}")
	elseif nIndex == 3 then
		strVar = ScriptGlobal_Format("#{HXYSJ_141031_151}", "#{HXYSJ_141031_81}")
	elseif nIndex == 4 then
		strVar = ScriptGlobal_Format("#{HXYSJ_141031_151}", "#{HXYSJ_141031_82}")
	elseif nIndex == 5 then
		strVar = ScriptGlobal_Format("#{HXYSJ_141031_151}", "#{HXYSJ_141031_83}")
	elseif nIndex == 6 then
		strVar = ScriptGlobal_Format("#{HXYSJ_141031_151}", "#{HXYSJ_141031_84}")
	elseif nIndex == 7 then
		strVar = ScriptGlobal_Format("#{HXYSJ_141031_151}", "#{HXYSJ_141031_85}")
	end

	WuhunQuest_Open_Window_YESNO(tostring(strVar))
	g_FrameVar[1] = tonumber(nIndex)
	g_FrameInfo = FrameInfoList.HXY_ACTIVE_EFFECT_CONFIRM
end

function WuhunQuest_HxyEffectResetConfirm(nBagIndex)

	WuhunQuest_Open_Window_YESNO("#{HXYSJ_141031_127}")
	g_FrameVar[1] = tonumber(nBagIndex)
	g_FrameInfo = FrameInfoList.HXY_RESET_EFFECT_CONFIRM
end

function WuhunQuest_Open_Window_PetHuanSeConfirm(strMsg, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETHUANSE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_PetRongHunDanBuy(nItemID, nType, nCurrencyUnit, nPrice, nItemIndex, nSerialNum, nUniqueID, possname )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nCurrencyUnit);
	g_FrameVar[3] = tonumber(nPrice);
	g_FrameVar[4] = tonumber(nItemIndex);
	g_FrameVar[5] = tonumber(nSerialNum);
	g_FrameVar[6] = nUniqueID;

	local strName = PlayerPackage:GetItemName(tonumber(nItemID))
--	PushDebugMessage("strName="..strName)
	local strMsg = ScriptGlobal_Format("#{ZSYH_170111_43}", possname,strName,possname,strName,nPrice,strName)
	--您尚未激活附体：%s0。您可以使用%s1，获得附体：%s2的默认风格。#r    您的背包道具栏中没有未锁定的%s3。点击确定按钮后，将花费%s4元宝从元宝商店中快速购买1个%s5。点击取消时，将放弃本次购买。
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.RONGHUNDAN_BUY_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Open_Window_PetRongHunDanUse(nItemID, possname)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nItemID);
	local strName = PlayerPackage:GetItemName(tonumber(nItemID))
	local strMsg = ScriptGlobal_Format("#{ZSYH_170111_42}", possname,strName,possname,strName)
	-- 您尚未激活附体：%s0。现在您的背包道具栏中有未锁定的%s1，您可以使用%s2，获得附体：%s3的默认风格。您是否确认使用%s4？#r    确认使用请点击确定按钮；点击取消时，将放弃本次操作。
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.RONGHUNDAN_USE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();

	this:Show();
end

function WuhunQuest_Open_Window_Head_Frame_XuQi(nExteriorHeadFrameID,posItem,headframename)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(nExteriorHeadFrameID);
	g_FrameVar[2] = tonumber(posItem);

	local strMsg = ScriptGlobal_Format("#{WGTJ_201222_117}", headframename)
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.HEADFRAME_XUQI_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();

	this:Show();
end

function WuhunQuest_Open_Window_PetSkillLevelupConfirm(hid,lid,selectskill,selectgood,skillID,HighestSkillID,WantHighestYB)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(hid);
	g_FrameVar[2] = tonumber(lid);
	g_FrameVar[3] = tonumber(selectskill);
	g_FrameVar[4] = tonumber(selectgood);

	local skillName = Pet:GetSkillName(tonumber(skillID))
	local HighestSkillName = Pet:GetSkillName(tonumber(HighestSkillID))
	local strMsg = ScriptGlobal_Format("#{ZSYH_170111_111}", skillName,HighestSkillName,WantHighestYB)
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETSKILL_LEVELUP_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();

	this:Show();
end

function WuhunQuest_Open_Window_PetSkillItemBuyConfirm(skillID,WantGoodsID,WantYB)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(skillID);
	g_FrameVar[2] = tonumber(WantGoodsID);

	local itemName = PlayerPackage:GetItemName(tonumber(WantGoodsID))
	local strMsg = ScriptGlobal_Format("#{ZSYH_170111_64}", itemName, WantYB, itemName)
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETSKILL_LINGSHOUDAN_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();

	this:Show();
end

function WuhunQuest_Open_Window_PetShouLan_AutoUse(nShouLanCnt,nRequireItem)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nRequireItem);
	local itemName = PlayerPackage:GetItemName(tonumber(nRequireItem))
	local nMaxPetCount = GetMyCurMaxPetCount()
	--#cfff263您可消耗1个#G%s0#cfff263，激活1个非免费珍兽栏位，激活后您所拥有的#G珍兽栏位总数#cfff263增加至#G%s1#cfff263个，角色最多可拥有#G4#cfff263个非免费珍兽栏位。#r    点击#G确认#cfff263按钮后，将完成本次激活，若点击#G取消#cfff263按钮，则放弃本次操作。
	local strMsg = ScriptGlobal_Format("#{ZSYH_170111_98}",itemName,nMaxPetCount+1)
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETSKILL_SHOULANUSE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();

	this:Show();
end

function WuhunQuest_Open_Window_PetShouLan_AutoUp(nShouLanCnt,nRequireItem,nRequireYB)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nShouLanCnt);
	g_FrameVar[2] = tonumber(nRequireYB);
	
	local levelList = {21, 41, 61, 81};
	local freeLanWeiList = {3, 4, 5, 6, 6};
	
	--判断等级阶段
	local playerLevel =  Player:GetData("LEVEL");
	local levelPos = 1;
	for i = 1, 4 do
	           if(playerLevel >= levelList[i]) then
			 levelPos = i + 1;
	          end
	end
	
	local strMsg = "";
	local nMaxPetCount = GetMyCurMaxPetCount()--当前最大容器
	
	--当前免费珍兽栏
	local curFreePetCount = 0;
	if(playerLevel < levelList[4]) then
	           curFreePetCount = freeLanWeiList[levelPos] -1;
	 else
		 curFreePetCount = 6;
	end
	
	--当前额外珍兽栏
	local curExPetCount = nMaxPetCount - curFreePetCount;
	if(playerLevel < levelList[4]) then
	          strMsg = ScriptGlobal_Format("#{ZSYH_170111_101}", levelList[levelPos], freeLanWeiList[levelPos], nRequireYB, curExPetCount+1, nMaxPetCount+1);
	else
	           strMsg = ScriptGlobal_Format("#{ZSYH_170904_121}", nRequireYB, curExPetCount+1, nMaxPetCount+1);
	end

          --local itemName = PlayerPackage:GetItemName(tonumber(nRequireItem))
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.PETSKILL_SHOULANUP_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();

	this:Show();
end

function WuhunQuest_Pneuma_SwitchGold_confirm( strName, strType )
	WuhunQuest_Clear_Var()

	local strText = ScriptGlobal_Format("#{CYZJ_150212_24}", strName, strType)
	WuhunQuest_InfoWindow:SetText( strText )
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.PNEUMA_SWITCHGOLD_CONFIRM
	this:Show()
end

function WuhunQuest_BROTHERSPIRIT_CONFIRM(index)
	WuhunQuest_Clear_Var()
	local strName = DataPool:Lua_GetQueryBrotherSpiritInfo(tonumber(index))
	local str = ScriptGlobal_Format("#{JBGXW_150526_46}",strName)
	WuhunQuest_InfoWindow:SetText(str)
	g_FrameVar[1] = tonumber(index);
		WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
		WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.BROTHERSPIRIT_CONFIRM
	this:Show()
end

function WuhunQuest_DecoZhenFaDesc(info)
	advance  = math.floor(tonumber(info)/1000)
	level	 = math.mod(tonumber(info),1000)
	if level == 100 then
		return "#{JBGXW_150526_145}"
	else
		return advance.."阶"..(level-advance*10).."级"
	end
end

function WuhunQuest_UseZhenfa_Confirm(skillid)
	WuhunQuest_Clear_Var()
	local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")

	if skillid == 3229 then
		local nmin,nmax =  Player:GetZhenfaAttr(0)
		local str = ScriptGlobal_Format("#{JBGXW_150526_222}",WuhunQuest_DecoZhenFaDesc(temp1),nmin,nmax)
		WuhunQuest_InfoWindow:SetText(str)
	elseif skillid == 3250 then
		local nmin,nmax =  Player:GetZhenfaAttr(1)
		local str = ScriptGlobal_Format("#{JBGXW_150526_223}",WuhunQuest_DecoZhenFaDesc(temp2),nmin,nmax)
		WuhunQuest_InfoWindow:SetText(str)	
	elseif skillid == 3251 then
		local nmin,nmax =  Player:GetZhenfaAttr(2)
		local str = ScriptGlobal_Format("#{JBGXW_150526_224}",WuhunQuest_DecoZhenFaDesc(temp3),nmin,nmax)
		WuhunQuest_InfoWindow:SetText(str)
	elseif skillid == 3252 then
		local nmin,nmax,nmin1 =  Player:GetZhenfaAttr(3)
		local str = ScriptGlobal_Format("#{JBGXW_150526_225}",WuhunQuest_DecoZhenFaDesc(temp4),nmin,nmax,nmin1)
		WuhunQuest_InfoWindow:SetText(str)		
	end
	
	g_FrameVar[1] = tonumber(skillid);
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.USEZHENFA_CONFIRM
	this:Show()	
end



function WuhunQuest_ShopBuy_Furniture_Confirm(nSelect)

	local pName , pShopName, pShopID ,pCount ,pYB = PlayerShop:GetItemPSInfo( nSelect - 1 )	
	
		local perPrice = pYB / pCount
		if perPrice < 1 then
			perPrice = 1
		elseif perPrice > 200000000 then
			perPrice = 200000000
		end
		local itemPerYB = string.format("%d" , perPrice)
		
		
	local str = ScriptGlobal_Format("#{JZFUR_061101_20}", pYB, pCount,pName, itemPerYB)
	WuhunQuest_InfoWindow:SetText(str)
	
	
	g_FrameVar[1] = tonumber(nSelect);
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.SHOPBUY_FURNITURE_CONFIRM
	this:Show()	

end
function WuhunQuest_MAKEZONGZI_CONFIRM(index)
	--PushDebugMessage("WuhunQuest_MAKEZONGZI_CONFIRM")
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText("#{LZZZ_150526_57}")
	g_FrameVar[1] = tonumber(index);
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.MAKEZONGZI_CONFIRM
	this:Show()
end

function WuhunQuest_ForbidIt_KickOut_Confirm( strText )

	WuhunQuest_InfoWindow:SetText( strText );

	g_FrameInfo = FrameInfoList.FORBIDIT_KICKOUT_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Swear_Confirm( name , flag )

	WuhunQuest_Clear_Var()
	
	if flag == 0 then
		local strText = ScriptGlobal_Format("#{JBLC_150528_28}" , tostring(name) ,tostring(name))
		WuhunQuest_InfoWindow:SetText(strText)
		g_FrameVar[ 1 ] = 0
	elseif flag == 1 then
		local strText = ScriptGlobal_Format("#{JBLC_150528_328}" , tostring(name))
		WuhunQuest_InfoWindow:SetText(strText)
		g_FrameVar[ 1 ] = 1
	end
	
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.SWEAR_CONFIRM
	this:Show()
end

function WuhunQuest_ChiXueQYD_Confirm( )

	WuhunQuest_Clear_Var()
	
	local strText = "#{JBZY_150629_152}"
	WuhunQuest_InfoWindow:SetText(strText)
	
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.CHIXUEQYD_CONFIRM
	this:Show()
end

function WuhunQuest_DestroyFurniture_Confirm()
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = Get_XParam_INT(0)
	g_FrameVar[2] = Get_XParam_INT(1)

	local strText = ScriptGlobal_Format("#{BFYH_170209_37}" , Get_XParam_STR(0), Get_XParam_INT(2) )
	WuhunQuest_InfoWindow:SetText(strText)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CYZJ_150212_25}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CYZJ_150212_22}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.BIEYE_FURNITURE_DESTROY_CONFIRM
	this:Show()
end

function WuhunQuest_ZZELevelup_Confirm( nBagIndex, ntargetId )

	WuhunQuest_Clear_Var()

	WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_18}")
	g_FrameVar[ 1 ] = nBagIndex
	g_FrameVar[ 2 ] = ntargetId

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.ZHIZUN_EQUIP_LEVELUP_CONFIRM
	this:Show()
end

function WuhunQuest_ZZEExchange_Confirm( ntargetId )

	WuhunQuest_Clear_Var()
	
	WuhunQuest_InfoWindow:SetText("#{ZZZB_200805_27}")
	g_FrameVar[ 1 ] = ntargetId

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.ZHIZUN_EQUIP_EXCHANGE_CONFIRM
	this:Show()
end

function WuhunQuest_ZZEUpGrade_Confirm( nBagIndex, nFlag, ntargetId )

	WuhunQuest_Clear_Var()

	if nFlag == 2 then
		WuhunQuest_InfoWindow:SetText("#{ZZZB_200805_21}")
	else
		local zwsp_count = PlayerPackage:Lua_GetUnLockItemCount(38005387)
		if zwsp_count == 0 then
			WuhunQuest_InfoWindow:SetText("#{ZZZB_200805_8}")
		else
			WuhunQuest_InfoWindow:SetText("#{ZWSP_210722_01}")
		end
	end
	
	g_FrameVar[ 1 ] = nBagIndex
	g_FrameVar[ 2 ] = nFlag
	g_FrameVar[ 3 ] = ntargetId

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.ZHIZUN_EQUIP_UPGRADE_CONFIRM
	this:Show()
end

function WuhunQuest_ZZEVipTransfer_Confirm( nBagIndex_A , nBagIndex_B , nType )

	WuhunQuest_Clear_Var()
	
	if nType == 0 then
		WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_328}")
	elseif nType == 1  then
		WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_326}")
	elseif nType == 2  then
		WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_329}")
	end

	g_FrameVar[ 1 ] = nBagIndex_A
	g_FrameVar[ 2 ] = nBagIndex_B

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.ZHIZUN_EQUIP_VIP_TRANSFER_CONFIRM
	this:Show()
	
end

function WuhunQuest_ZZETransfer_Confirm( nBagIndex_A , nBagIndex_B , nType, ntargetId )

	WuhunQuest_Clear_Var()
	
	if nType == 0 then
		WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_328}")
	elseif nType == 1  then
		WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_326}")
	elseif nType == 2  then
		WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_329}")
	end

	g_FrameVar[ 1 ] = nBagIndex_A
	g_FrameVar[ 2 ] = nBagIndex_B
	g_FrameVar[ 3 ] = ntargetId

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.ZHIZUN_EQUIP_TRANSFER_CONFIRM
	this:Show()
end


function WuhunQuest_FiveElementsSwitchType_Confirm( nElementsIndex  , nOldType , nNewType)
	
	WuhunQuest_Clear_Var()
	
	local strElementsName = { 
			"#{ZZZB_150811_190}",
			"#{ZZZB_150811_192}",
			"#{ZZZB_150811_191}",
			"#{ZZZB_150811_193}",
			"#{ZZZB_150811_194}",
	}

	local strElementsTypeName = {

			[ 1 ] = {
				"#{ZZZB_150811_166}",	--冰攻击
				"#{ZZZB_150811_167}",	--火攻击
				"#{ZZZB_150811_168}",	--玄攻击
				"#{ZZZB_150811_169}",	--毒攻击
			},
	
			[ 2 ] = {
				"#{ZZZB_150811_172}",	--冰减抗
				"#{ZZZB_150811_173}",	--火减抗
				"#{ZZZB_150811_174}",	--玄减抗
				"#{ZZZB_150811_175}",	--毒减抗
				"#{ZZZB_150811_176}",	--冰抗
				"#{ZZZB_150811_177}",	--火抗
				"#{ZZZB_150811_178}",	--玄抗
				"#{ZZZB_150811_179}",	--毒抗
			},
	
			[ 4 ] = {
				"#{ZZZB_150811_182}",	--穿刺攻击
				"#{ZZZB_150811_183}",	--穿刺防御
			},
	}
	
	if strElementsName[ nElementsIndex + 1 ] == nil or strElementsTypeName[ nElementsIndex + 1 ] == nil then
		return
	end
	
	if strElementsTypeName[ nElementsIndex + 1 ][ nOldType ] == nil or strElementsTypeName[ nElementsIndex + 1 ][ nNewType ] == nil  then
		return
	end
	
	local strText = ScriptGlobal_Format("#{ZZZB_150811_207}" , strElementsName[ nElementsIndex + 1 ] ,
			strElementsTypeName[ nElementsIndex + 1 ][ nOldType ] , strElementsTypeName[ nElementsIndex + 1 ][ nNewType ])
	WuhunQuest_InfoWindow:SetText(strText)
	
	g_FrameVar[ 1 ] = nElementsIndex
	g_FrameVar[ 2 ] = nNewType

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.FIVE_ELEMENTS_SWITCHTYPE_CONFIRM
	this:Show()	
end

function WuhunQuest_FiveElementsWashClose_Confirm()

	WuhunQuest_Clear_Var()
	
	WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_222}")
	
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.CLOSE_FIVE_ELEMENTS_WASH_COMFIRM
	this:Show()	
end



function WuhunQuest_FiveElementsWashSwitch_Confirm( nIndex )

	WuhunQuest_Clear_Var()
	
	g_FrameVar[1] = tonumber(nIndex)
	
	WuhunQuest_InfoWindow:SetText("#{ZZZB_150811_292}")
	
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.FIVE_ELEMENTS_WASH_SWITCH_CONFIRM
	this:Show()	
end





function WuhunQuest_Alliancekick_guild(guildname, guildid, zoneworldid,guildtype)
	if guildtype == 1 then
		WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format("#{SLJC_150811_694}",guildname))		
	else	
		WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format("#{SLJC_150811_692}",guildname))			
	end
	
		WuhunQuest_Clear_Var()
				--成员帮会
		g_FrameVar[1] = tonumber(guildid)
		g_FrameVar[2] = tonumber(zoneworldid)
		WuhunQuest_Button1:Show()
		WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
		WuhunQuest_Button2:Show()
		WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
		WuhunQuestUpdateRect();
		g_FrameInfo = FrameInfoList.ALLIANCEKICK_GUILD
		this:Show()		
	
end
function WuhunQuest_Confirm_ActingGuildKick(strinfo)
	WuhunQuest_InfoWindow:SetText(strinfo)	
	WuhunQuest_Clear_Var()
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.CONFIRM_ACTINGGUILD_KICK
	this:Show()	
end




function WuhunQuest_FiveElementsWashNotSwitch_Confirm( nIndex )

	WuhunQuest_Clear_Var()
	
	g_FrameVar[1] = tonumber(nIndex)
	
	WuhunQuest_InfoWindow:SetText("#{ZZZB_151105_03}")
	
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.FIVE_ELEMENTS_WASH_NOTSWITCH_CONFIRM
	this:Show()	
end

function WuhunQuest_FiveElementsWashAutoStart_Confirm( )

	WuhunQuest_Clear_Var()
	
	WuhunQuest_InfoWindow:SetText("#{ZZZB_151105_06}")
	
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.FIVE_ELEMENTS_AUTOWASH_CONFIRM
	this:Show()	
end

function WuhunQuest_ZhenfaForget_Confirm(nIndex)
	WuhunQuest_Clear_Var()
	
	local skillname = {"#{JBGXW_150526_138}","#{JBGXW_150526_139}","#{JBGXW_150526_140}","#{JBGXW_150526_141}"}
	local backup = Player:GetZhenfareturnback(nIndex)
	local strText = ScriptGlobal_Format("#{JLZFYW_151123_8}" , skillname[nIndex+1],backup,backup)	
	
	local bsNum = Player:GetBrotherShip()
	local maxnum = 150000
	if bsNum + backup >= maxnum then
		local realback = maxnum - bsNum;
		strText = ScriptGlobal_Format("#{JLZFYW_151123_16}" , skillname[nIndex+1],backup,realback)	
	
	end
	
	
	WuhunQuest_InfoWindow:SetText(strText)
	
	g_FrameVar[1] = tonumber(nIndex)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.ZHENFA_FORGET_CONFIRM
	this:Show()
end

function WuhunQuest_GSEvaluate_Confirm()
	WuhunQuest_Clear_Var()
		
	WuhunQuest_InfoWindow:SetText("是否放弃本次评价？")
	
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZZZB_150811_19}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.GSEVALUATE_CONFIRM
	this:Show()
end

--function WuhunQuest_DressGem_Stiletto_Confirm( needmoney , GemID , LevelGemID )
function WuhunQuest_DressGem_Stiletto_Confirm( nNeedYuanbao, strMsg )
	g_FrameInfo = FrameInfoList.DRESSGEM_STILETTO_CONFIRM;  
     
	--WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format("#{SZBSYL_150327_102}",DressGem:GetGemName(GemID),DressGem:GetGemName(LevelGemID),needmoney));
	WuhunQuest_InfoWindow:SetText(ScriptGlobal_Format("#{SZZH_170111_111}", strMsg, nNeedYuanbao ));
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{SZBSYL_150327_20}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	this:Show();																			 
																			 
end

function WuhunQuest_BillingAward_Confirm( strText, nIndex )
	WuhunQuest_Clear_Var()
	g_FrameVar[1]  = tonumber(nIndex)

	WuhunQuest_InfoWindow:SetText( strText )
	WuhunQuestUpdateRect();
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LJSJ_160308_10}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LJSJ_160308_11}");  --取消
	g_FrameInfo = FrameInfoList.BILLINGAWARD_CONFIRM
	this:Show();
end

function WuhunQuest_DressGem_Enchase_Confirm(Dresspos, SelectGemCount ,SelectGemID1,SelectGemID2,SelectGemID3
																			 ,nSameIndex,DressSameGemID1,DressSameGemID2,DressSameGemID3,NeedMoney)
																			 
	g_FrameInfo = FrameInfoList.DRESSGEM_ENCHASE_CONFIRM; 
  local itemName = PlayerPackage:GetBagItemName( Dresspos )
  if itemName == nil then
      return
  end
  local Msg;  
  local SelectGemID = {-1,-1,-1}
  local SameGemID 	= {-1,-1,-1}
  
  SelectGemID[1] = SelectGemID1;
  SelectGemID[2] = SelectGemID2;
  SelectGemID[3] = SelectGemID3;
  
  SameGemID[1] = DressSameGemID1;
  SameGemID[2] = DressSameGemID2;
  SameGemID[3] = DressSameGemID3; 
  
  --如果没有冲突的
  if nSameIndex == 0 then  
  	Msg = ScriptGlobal_Format("#{SZBSYL_150327_24}" ,itemName);
  	for i =1 ,SelectGemCount do 
  		Msg = Msg..ScriptGlobal_Format("#{SZBSYL_150327_33}" ,DressGem:GetGemName(SelectGemID[i]) );
  		Msg = Msg.."#{SZBSYL_150327_34}";
  	end
  	  Msg = Msg..ScriptGlobal_Format("#{SZBSYL_150327_35}" ,NeedMoney ) ;
  else
  	--有冲突的
  	Msg = ScriptGlobal_Format("#{SZBSYL_150327_25}" ,itemName);
  	for i =1 ,SelectGemCount do 
  		Msg = Msg..ScriptGlobal_Format("#{SZBSYL_150327_33}" ,DressGem:GetGemName(SelectGemID[i]) );
  		Msg = Msg.."#{SZBSYL_150327_34}";
  	end
  	Msg = Msg.."#{SZBSYL_150327_26}";
  	 for i =1 ,nSameIndex do 
  	 local gemname = DressGem:GetGemName(SameGemID[i]);  
  		Msg = Msg..gemname;
  		Msg = Msg.."#{SZBSYL_150327_34}";
  	end
  	Msg = Msg..ScriptGlobal_Format("#{SZBSYL_150327_36}" ,NeedMoney,nSameIndex) ;
  end 
  
	WuhunQuest_InfoWindow:SetText(Msg);
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{SZBSYL_150327_20}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZZZB_150811_20}");  --取消
	WuhunQuestUpdateRect();
	this:Show();																			 
																			 
end

function WuhunQuest_Dress_Transfer_Bind_Confirm()
	
	g_FrameInfo = FrameInfoList.DRESS_TRANSFER_BIND_CONFIRM
	
	WuhunQuest_InfoWindow:SetText("#{SZPSZY_160314_30}")
	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_1173}")  --关闭
	WuhunQuestUpdateRect()
	this:Show()
end

function WuhunQuest_Dress_Transfer_BuyItem_Confirm(nUniqueID,nNeedItemCount,nItemCount,nYB,nBuyType,nCurrencyUnit,nItemIndex,nSerialNum)
	
	g_FrameInfo = FrameInfoList.DRESS_TRANSFER_BUYITEM_CONFIRM
	g_FrameVar[1] = tonumber(nBuyType)
	g_FrameVar[2] = tonumber(nCurrencyUnit)
	g_FrameVar[3] = tonumber(nYB)
	g_FrameVar[4] = tonumber(nItemIndex)
	g_FrameVar[5] = tonumber(nSerialNum)
	g_FrameVar[6] = tonumber(nItemCount)
	g_FrameVar[7] = tostring(nUniqueID)

	local strTemp = ScriptGlobal_Format("#{SZPSZY_160314_19}" ,tostring(nNeedItemCount),tostring(nNeedItemCount-nItemCount),tostring(nItemCount),tostring(nYB))
	
	WuhunQuest_InfoWindow:SetText(strTemp)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定 
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
	WuhunQuestUpdateRect()
	this:Show()
end

function WuhunQuest_AQLY_AutoFlash_Confirm(Ind)
	g_FrameInfo = FrameInfoList.AQLY_FLASH_COMFIRM
	
	local strTemp = ScriptGlobal_Format("#{AQJJ_160127_204}",g_proDes[Ind + 1],g_proDes[Ind + 1],g_proDes[Ind + 1])
	WuhunQuest_InfoWindow:SetText(strTemp)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定 
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
	WuhunQuestUpdateRect()
	this:Show()
	
end
function WuhunQuest_Open_Window_Pet_HuanHua_Confirm(Str)
	g_FrameInfo = FrameInfoList.PET_HUANHUA_CONFIRM
 
	WuhunQuest_InfoWindow:SetText(Str)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end

function WuhunQuest_Open_Window_Common_Confirm(Str,nType,nParam)
	g_FrameInfo = FrameInfoList.COMMON_CONFIRM
 
	g_FrameVar[1]  = nType
	g_FrameVar[2]  = nParam
	WuhunQuest_InfoWindow:SetText(Str)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end

function WuhunQuest_Open_Martail_Confirm(nIndex,strTip,Yuanbao)
	g_FrameInfo = FrameInfoList.MARTIAIL_RECYCLEATTRPOINT_CONFIRM
	g_FrameVar[1]  = nIndex
	g_FrameVar[2]  = strTip
	g_FrameVar[3]  = Yuanbao
	local str = ""
	if(nIndex == 15) then
		str = ScriptGlobal_Format("#{WYXT_20170831_260}",tostring(strTip),tostring(strTip))
	else
		str = strTip
	end
	WuhunQuest_InfoWindow:SetText(str)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{WYXT_20170803_52}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{WYXT_20170803_53}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end

--function WuhunQuest_Open_Window_SuperWeapon9_Confirm(pos)
--	g_FrameInfo = FrameInfoList.SUPERWEAPON9_CONFIRM
-- 
--	g_FrameVar[1]  = pos
--	local nItemID = PlayerPackage:GetItemTableIndex(pos)
--	local szItemName = DataPool:Lua_GetItemNameByIndex(nItemID)
--	local thisMsg = ScriptGlobal_Format("#{JXSQ_170804_27}", szItemName)
--	
--	WuhunQuest_InfoWindow:SetText(thisMsg)
--	WuhunQuest_Button1:Show()
--	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定
--	WuhunQuest_Button2:Show()
--	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
--	WuhunQuestUpdateRect()
--	this:Show() 
--end
--function WuhunQuest_PieceExchange(chipcnt)
--	g_FrameInfo = FrameInfoList.SUPERWEAPON9_PIECEEXCHANGE
--	local nGiveCnt=math.floor(chipcnt/10)
--	local thisMsg = ScriptGlobal_Format("#{JXSQ_170804_61}", chipcnt, nGiveCnt)
--	WuhunQuest_InfoWindow:SetText(thisMsg)
--	WuhunQuest_Button1:Show()
--	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定
--	WuhunQuest_Button2:Show()
--	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
--	WuhunQuestUpdateRect()
--	this:Show() 
--end


function WuhunQuest_shelizi_hecheng_confirm()
	g_FrameInfo = FrameInfoList.SHELIZI_HECHENG_CONFIRM
	g_FrameVar[1] = 100
	WuhunQuest_InfoWindow:SetText("#{ZSDHC_170828_20}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSDHC_170828_21}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSDHC_170828_16}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 	

end


function WuhunQuest_shelizi_hecheng_confirm_2(nexp)
	g_FrameInfo = FrameInfoList.SHELIZI_HECHENG_CONFIRM
	g_FrameVar[1] = 200

	local thisMsg = ScriptGlobal_Format("#{ZSDHC_170828_22}", nexp)
	
	WuhunQuest_InfoWindow:SetText(thisMsg)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSDHC_170828_21}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSDHC_170828_16}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end

function WuhunQuest_shelizi_hecheng_confirm_3(nexp)
	g_FrameInfo = FrameInfoList.SHELIZI_HECHENG_CONFIRM
	g_FrameVar[1] = 300

	local thisMsg = ScriptGlobal_Format("#{ZSDHC_170831_31}", nexp)
	
	WuhunQuest_InfoWindow:SetText(thisMsg)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSDHC_170828_21}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSDHC_170828_16}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end

function WuhunQuest_MartialMultiItem_Confirm(CurValue, MaxValue,nItemId)
	g_FrameInfo = FrameInfoList.MARTIAL_MULTIITEM_CONFIRM
	g_FrameVar[1] = nItemId
	local thisMsg = ScriptGlobal_Format("#{WYXT_20170828_236}", CurValue,MaxValue)
	WuhunQuest_InfoWindow:SetText(thisMsg)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSDHC_170828_21}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSDHC_170828_16}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end

function WhunQuest_MartialFreezeExp_Confirm(nMaxMonster,CurMonster,MultiMonster)
	g_FrameInfo = FrameInfoList.MARTIAL_FREEZE_EXP_CONFIRM
	local strTip = ""
	local nLeft = nMaxMonster - CurMonster
	if(MultiMonster > 0) then
		strTip = ScriptGlobal_Format("#{WYXT_20170901_263}",nMaxMonster,nLeft,MultiMonster)
	else
		strTip = ScriptGlobal_Format("#{WYXT_20170811_182}",nMaxMonster,nLeft)
	end
	WuhunQuest_InfoWindow:SetText(strTip)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{WYXT_20170803_52}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{WYXT_20170803_53}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end


function WuhunQuest_BuyNewbaotu_Confirm(bagpos)
	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.CONFIRM_BUY_NEWBAOTU

	g_FrameVar[1] = tonumber(bagpos);
	WuhunQuest_InfoWindow:SetText("#{CPBT_260115_129}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{WYXT_20170803_52}") 	--确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{WYXT_20170803_53}") 	--取消
	WuhunQuestUpdateRect()
	this:Show() 
end

function WuhunQuest_Open_Window_BieYeStyleConfirm( strMsg, nType, nIndex, nItemPos )
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = tonumber(nType);
	g_FrameVar[2] = tonumber(nIndex);
	g_FrameVar[3] = tonumber(nItemPos);

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.BIEYESTYLE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{JYHZ_170824_31}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{JYHZ_170824_32}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_Martial_RLearnTalent_Confirm(nLayer,nLevel,nCost,LayerName)
	g_FrameInfo = FrameInfoList.MARTAIL_RLEARN_TALENT_CONFIRM
	g_FrameVar[1] = tonumber(nLayer)
	
	
	local strTip = ScriptGlobal_Format("#{WYXT_20170803_80}",nCost,LayerName,LayerName,LayerName)
	WuhunQuest_InfoWindow:SetText( strTip );

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{WYXT_20170803_52}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{WYXT_20170803_53}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
	
end
function WuhunQuest_ZhaoHuiExp_Confirm(Msg,Type)
	g_FrameInfo = FrameInfoList.ZHAOHUI_EXP_CONFIRM
	g_FrameVar[1] = tonumber(Type)
	 
	WuhunQuest_InfoWindow:SetText( Msg );

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{WYXT_20170803_52}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{WYXT_20170803_53}");  --取消
	WuhunQuestUpdateRect();
	this:Show();
	
end

function WuhunQuest_WeiXinQianDao_LiBao_Confirm( strMsg)
	WuhunQuest_Clear_Var()

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.WEIXINQIANDAO_LIBAO_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XCWX_180122_20}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{XCWX_180122_21}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_FangDeng_Confirm(nFlag1, nFlag2)

	local strMsg = ""
	--if nFlag1 == 1 then
	--	strMsg = "#{HDRZ_180322_209}"
	--end
	
	if nFlag2 == 1 then
		strMsg = strMsg.."#{HDRZ_180322_210}"
	end
	
	strMsg = strMsg.."#{HDRZ_180322_211}"
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.FANGDENG_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XCWX_180122_20}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{XCWX_180122_21}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function WuhunQuest_GuildSaoLeiConfirm(str)

	WuhunQuest_InfoWindow:SetText( "#{BHSL_210715_67}" );

	g_FrameInfo = FrameInfoList.GUILD_SAOLEI_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BHSL_210715_68}");  
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BHSL_210715_69}");  
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show()

end

function WuhunQuest_Balloon_Confirm(nFlag)

	local strMsg = ""
	if nFlag == 1 then
		strMsg = "#{ETJHD_180503_171}"
	elseif nFlag == 2 then
		strMsg = "#{ETJHD_180503_161}"
	end
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.BALLOON_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XCWX_180122_20}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{XCWX_180122_21}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function WuhunQuest_Balloon_GetLibao_Confirm(count, name)
	local strMsg = ScriptGlobal_Format("#{ETJHD_180514_1}", count, name)

	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.BALLOON_GETLIBAO_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XCWX_180122_20}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{XCWX_180122_21}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();

end


function Apply_Snaking_Num_Second_Confirm()
	--WuhunQuest_Clear_Var()

	WuhunQuest_InfoWindow:SetText( "#{RCYH_180522_53}" );

	g_FrameInfo = FrameInfoList.APPLY_SNAKING_NUM_SECOND_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{RCYH_180522_54}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{RCYH_180522_55}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WHQ_JF_Confirm(fengyebi, win, lose, remain_times)
    g_FrameInfo = FrameInfoList.JINFENGHAODU_CONFIRM

    local msg = ""
    if remain_times then
        if remain_times >= 3 then
            msg = ScriptGlobal_Format("#{JFHD_180803_55}", fengyebi, win)
        elseif remain_times == 2 then
            msg = ScriptGlobal_Format("#{JFHD_180803_33}", fengyebi, win, lose)
        else
            msg = ScriptGlobal_Format("#{JFHD_180803_56}", fengyebi, win, lose)
        end
    end

    WuhunQuest_InfoWindow:SetText(msg)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XCWX_180122_20}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{RCYH_180522_55}")  --取消
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

function WHQ_JF_Reward_Confirm(fengyebi, remain_times)
    g_FrameInfo = FrameInfoList.JINFENGHAODU_REWARD_CONFIRM

    local msg
    if remain_times and remain_times >= 3 then
        msg = ScriptGlobal_Format("#{JFHD_180803_40}", fengyebi)
    else
        msg = ScriptGlobal_Format("#{JFHD_180803_41}", remain_times, fengyebi)
    end
    WuhunQuest_InfoWindow:SetText(msg)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{XCWX_180122_20}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{RCYH_180522_55}")  --取消
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end



function WuhunQuest_Pet_LianHua_Confirm(petIndex)
	
	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.PET_LIANHUA_CONFIRM	
	
	local petname,status = Pet:GetPetList_Appoint(petIndex)
	
	local strVLevel = ""
	local nType = Pet:GetPetType(petIndex)	
	if nType == 0 then
		strVLevel = "#{ZSHP_180814_60}"
	elseif nType == 1 then	
		local nVLevel = Pet:Lua_GetPetVarLevel(petIndex)
		strVLevel = tostring(nVLevel)		
	end
	
	local productId = Pet:Lua_GetLianHuaProduct(petIndex)
	local nHuanLingId = Pet:Lua_GetPetHuanLingIdByItem(productId)
	local strProductName = DataPool:Lua_GetItemNameByIndex(productId)
	local petQuality = Pet:GetPetQuality(petIndex)	
	local strQuality = g_PetQualityText[petQuality]
	local strExText = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"ExText")
	
	
	local str = ScriptGlobal_Format("#{ZSHP_180814_81}",tostring(petname),tostring(strQuality),
				strVLevel,tostring(strProductName),tostring(strExText),tostring(petname))
	
	WuhunQuest_InfoWindow:SetText( str )

	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_82}");  --关闭
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

function WuhunQuest_Use_Pet_HuanLingItem_Confirm(bagIndex,itemID,bHuanYu)

	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.USE_PET_HUANLING_ITEM_CONFIRM	
	
	g_FrameVar[1] = tonumber(bagIndex)
	g_FrameVar[2] = tonumber(itemID)
	
	local nHuanLingId = Pet:Lua_GetPetHuanLingIdByItem(itemID)
	local strName = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"Name")
	local nQuality = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"Quality")
	local strExText = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"ExText")
	
	local strReqQual = ""
	if g_ReqQualText[nQuality] then
		strReqQual = g_ReqQualText[nQuality]
	end
	
	local str = ""
	
	if nQuality == 1 then
		str = ScriptGlobal_Format("#{ZSHP_180814_157}",tostring(strName),tostring(strExText))
	else
		str = ScriptGlobal_Format("#{ZSHP_180814_89}",tostring(strName),tostring(strExText),tostring(strReqQual) )
	end
	
	if bHuanYu == 1 then
		WuhunQuest_InfoWindow:SetText("#{ZSWG_181211_121}"..str)
	else
		WuhunQuest_InfoWindow:SetText( str )
	end

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSHP_180814_90}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_91}");  --取消
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()

end

function WuhunQuest_Drop_All_Item_In_TemBank_Confirm()
	g_FrameInfo = FrameInfoList.DROP_ALL_ITEM_INTEMBANK
	WuhunQuest_InfoWindow:SetText( "#{SSCK_180821_17}" )
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSHP_180814_90}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_91}");  --取消
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

function WuhunQuest_NianShou_NingYu_Confirm(petIndex)
	
	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.NIANSHOU_NINGYU_CONFIRM	
	
	local petname,status = Pet:GetPetList_Appoint(petIndex)
	local nVLevel = Pet:Lua_GetPetVarLevel(petIndex)
	local nSavvy = Pet:GetSavvy(petIndex)
	local nLing = Pet:GetLixing(petIndex)
	
	local nTakeLevel = Pet:GetTakeLevel(petIndex)
	local nJinJieGrade = Pet:GetJinJieGrade(petIndex)
	local nJinJieLevel = Pet:GetJinJieLvl(petIndex)
	if nTakeLevel < 55 then
		
		local str = ScriptGlobal_Format("#{ZSWG_181211_112}",tostring(petname),tostring(nVLevel),tostring(nSavvy),tostring(nLing))	
		WuhunQuest_InfoWindow:SetText( str )
	
	elseif nJinJieGrade == 10 then
	
		local str = ScriptGlobal_Format("#{ZSWG_181211_113}",tostring(petname),tostring(nVLevel),tostring(nSavvy),tostring(nLing))	
		WuhunQuest_InfoWindow:SetText( str )
		
	elseif nJinJieGrade < 10 then
	
		local str = ScriptGlobal_Format("#{ZSWG_181211_29}",tostring(petname),tostring(nVLevel),tostring(nSavvy),tostring(nLing),tostring(nJinJieGrade),tostring(nJinJieLevel))	
		WuhunQuest_InfoWindow:SetText( str )		
	end

	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_82}");  --关闭
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

function WuhunQuest_NianShou_HuanYu_Rare_Confirm(nBagIndex)
	
	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.NIANSHOU_HUANYU_RARE_CONFIRM	
	
	g_FrameVar[1] = nBagIndex
	
	local nItemTableIndex = PlayerPackage:GetItemTableIndex(nBagIndex)
--	local strName = PlayerPackage:GetItemName(nItemTableIndex)
	
	local nHuanLingId = Pet:Lua_GetPetHuanLingIdByItem(nItemTableIndex)
	local strExText = Pet:Lua_GetPetHuanLingInfo(nHuanLingId,"ExText")
	local str = ScriptGlobal_Format("#{ZSWG_181211_64}",strExText)
	
	WuhunQuest_InfoWindow:SetText( str )

	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_82}");  	--关闭
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

function WuhunQuest_NianShou_HuanYu_Bind_Confirm()
	
	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.NIANSHOU_HUANYU_BIND_CONFIRM	
	
	WuhunQuest_InfoWindow:SetText( "#{ZSWG_181211_65}" )

	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_302}")  	--关闭
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

function WuhunQuest_NianShou_HuanYuUp_Bind_Confirm()
	
	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.NIANSHOU_HUANYUUP_BIND_CONFIRM	
	
	WuhunQuest_InfoWindow:SetText("#{ZSWG_181211_89}")

	WuhunQuest_Button1:Hide()
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_302}")  	--关闭
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

function WuhunQuest_ZhiBuConfirm( strMsg )
	WuhunQuest_Clear_Var()	
	WuhunQuest_InfoWindow:SetText( strMsg );

	g_FrameInfo = FrameInfoList.ZHIBU_EXCHANGE_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSHP_180814_90}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_91}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_YuShou_Confirm( strMsg, state )
	WuhunQuest_Clear_Var()	
	WuhunQuest_InfoWindow:SetText( strMsg );

	if state == 2 then
		g_FrameInfo = FrameInfoList.CONFIRM_BUYFASHION;
	elseif state == 3 then
		g_FrameInfo = FrameInfoList.CONFIRM_BUYSECFASHION;
	elseif state == 4 then
		g_FrameInfo = FrameInfoList.CONFIRM_FOND;
	else
		g_FrameInfo = FrameInfoList.CONFIRM_YUSHOU;
	end
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSHP_180814_90}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_91}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

function WuhunQuest_ZNQBuyTokens_Confirm(nType)
	
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = nType
	g_FrameInfo = FrameInfoList.ZNQ_BUY_TOKENS_CONFIRM	
	
	if nType == 10 then
		local str = ScriptGlobal_Format("#{HDSW_190322_24}" , "10" , "10")
		WuhunQuest_InfoWindow:SetText(str)
	elseif nType == 100 then
		local str = ScriptGlobal_Format("#{HDSW_190322_24}" , "95" , "100")
		WuhunQuest_InfoWindow:SetText(str)
	else
		WuhunQuest_InfoWindow:SetText("")
	end

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}")  --取消
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end
		
-- 2024Q3版本稳活活动
function WuhunQuest_WenHuoMissionConfirm( nObjId, strMsg )
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = nObjId
	WuhunQuest_InfoWindow:SetText( strMsg );
	g_FrameInfo = FrameInfoList.WENHUOMISSION_CONFIRM;
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{ZSHP_180814_90}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{ZSHP_180814_91}");  --取消
	WuhunQuestUpdateRect();
	DataPool:SetCanUseHotKey(0)
	this:Show();
end

--2019国庆稳活跃抽奖--元宝购买二次确认
function WuhunQuest_GQHYChouJiangBuyTokens_Confirm(nType)
	
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = nType
	g_FrameInfo = FrameInfoList.GQHYCHOUJIANG_BUY_TOKENS_CONFIRM	
	
	if nType == 10 then
		local str = ScriptGlobal_Format("#{GQHY_190723_73}" , "10" , "10")
		WuhunQuest_InfoWindow:SetText(str)
	elseif nType == 100 then
		local str = ScriptGlobal_Format("#{GQHY_190723_73}" , "95" , "100")
		WuhunQuest_InfoWindow:SetText(str)
	else
		WuhunQuest_InfoWindow:SetText("")
	end

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}")  --取消
	WuhunQuestUpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show()
end

-- 金陵战场特殊分发物品二次确认
function WuhunQuest_JinLingSpecialItem_Confirm(item, num, targetName)
end -- end func WuhunQuest_JinLingSpecialItem_Confirm()

function WuhunQuest_Decoweapon_LevelDown_Confirm(targetId,weaponid,weapongroupid,weaponlevel,itemcount)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = targetId
	g_FrameVar[2] = weaponid
	g_FrameVar[3] = weapongroupid
	g_FrameVar[4] = weaponlevel

	WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{HSRL_220214_19}",itemcount,weaponlevel) )

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{LS78_140819_55}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{LS78_140819_56}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.DECOWEAPON_LEVELDOWN_CONFIRM
	this:Show()
end

function WuhunQuest_Ornaments_Confirm(optype,bagIndex,tableIndex)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = bagIndex
	g_FrameVar[2] = tableIndex
	g_FrameVar[3] = optype

	local szname = DataPool:Lua_GetItemNameByIndex(tableIndex)
	local itemtype, idx, lifetime = OrnamentsScript:GetOrnamentsItemInfo(tableIndex)
	local szornamentsame = OrnamentsScript:GetOrnamentsInfo(itemtype, idx, "Name")
	WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{BGTS_220125_25}",szname,szornamentsame) )

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BGTS_220125_26}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BGTS_220125_27}")  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.CONFIRM_ORNAMENTS_CONFIRM
	this:Show()
end 


function WuhunQuest_NameBoardEx_Confirm(bagIndex,tableIndex)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = bagIndex
	g_FrameVar[2] = tableIndex

	--local szname = DataPool:Lua_GetItemNameByIndex(tableIndex)
	local idx, lifetime = XunzhangSysScript:GetNameBoardExItemInfo(tableIndex)
	local szornamentsame = XunzhangSysScript:GetNameBoardExInfo(idx, "Name")
	WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{XZXT_240517_08}",szornamentsame) )

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BGTS_220125_26}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BGTS_220125_27}")  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.CONFIRM_NAMEBOARDEX_CONFIRM
	this:Show()
end 

function WuhunQuest_ChiJiDropItem_Confirm(sourceBagType,sourceBagPos,chijiId,tableIndex)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = sourceBagType
	g_FrameVar[2] = sourceBagPos
	g_FrameVar[3] = chijiId
	g_FrameVar[4] = tableIndex

	local szname =""
	if sourceBagType == 5 or sourceBagType == 2 then
		local _,tszname = Lua_GetSkillInfo(tableIndex)
		szname = tszname
	else
		szname = DataPool:Lua_GetItemNameByIndex(tableIndex)
	end
	WuhunQuest_InfoWindow:SetText( ScriptGlobal_Format("#{TLCJ_20240709_139}",szname) )

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BGTS_220125_26}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BGTS_220125_27}")  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.CONFIRM_CHIJIDROPITEM_CONFIRM
	this:Show()
end

function WuhunQuest_Close_DBZ_Confirm(arg0,arg1)
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText( "#{BXDK_240909_47}" )
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BXDK_240909_48}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BXDK_240909_49}")  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.COLSE_CONFIRM_BXDBZ
	this:Show()
end

function WuhunQuest_DaFuWeng_Lock_Confirm(arg0,arg1)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = arg0
	g_FrameVar[2] = arg1

	if arg0 == 18 then
		WuhunQuest_InfoWindow:SetText( "#{ZNLSG_230215_292}" )
	elseif arg0 == 19 then
		WuhunQuest_InfoWindow:SetText( "#{ZNLSG_230215_296}" )
	elseif arg0 == 22 then
		WuhunQuest_InfoWindow:SetText( "#{ZNLSG_230215_305}" )
	elseif arg0 == 23 then
		WuhunQuest_InfoWindow:SetText( "#{ZNLSG_230215_315}" )
	elseif arg0 == 24 then
		WuhunQuest_InfoWindow:SetText( "#{ZNLSG_230215_313}" )
	else
		return
	end

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BGTS_220125_26}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BGTS_220125_27}")  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.DAFUWENG_GROUP_CONFIRM
	this:Show()
end

function WuhunQuest_QianKunPot_Confirm(optype, param)
	WuhunQuest_Clear_Var()

	g_FrameVar[1] = optype
	g_FrameVar[2] = param

	WuhunQuest_InfoWindow:SetText( "#{QKH_20220802_01}" )

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{BGTS_220125_26}")  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{BGTS_220125_27}")  --取消
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.CONFIRM_QIANKUNPOT_SAVE
	this:Show()
end 

function WuhunQuest_UnderArmourWash_BuyItem_Confirm(nUniqueID, nNeedItemCount, nItemCount, nYB, nBuyType, nCurrencyUnit, nItemIndex, nSerialNum)

	g_FrameInfo = FrameInfoList.UNDERARMOUR_WASH_BUY_CONFIRM
	g_FrameVar[1] = tonumber(nBuyType)
	g_FrameVar[2] = tonumber(nCurrencyUnit)
	g_FrameVar[3] = tonumber(nYB)
	g_FrameVar[4] = tonumber(nItemIndex)
	g_FrameVar[5] = tonumber(nSerialNum)
	g_FrameVar[6] = tostring(nUniqueID)
	g_FrameVar[7] = tonumber(nItemCount)	

	local strTemp = ScriptGlobal_Format("#{NJBZ_220816_449}" ,tostring(nYB))
	
	WuhunQuest_InfoWindow:SetText(strTemp)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定 
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
	WuhunQuestUpdateRect()
	this:Show()
end

function WuhunQuest_UnderArmourStarUp_BuyItem_Confirm(nUniqueID, nNeedItemCount, nItemCount, nYB, nBuyType, nCurrencyUnit, nItemIndex, nSerialNum, nNeedItemIndex)

	g_FrameInfo = FrameInfoList.UNDERARMOUR_STARUP_BUY_CONFIRM
	g_FrameVar[1] = tonumber(nBuyType)
	g_FrameVar[2] = tonumber(nCurrencyUnit)
	g_FrameVar[3] = tonumber(nYB)
	g_FrameVar[4] = tonumber(nItemIndex)
	g_FrameVar[5] = tonumber(nSerialNum)
	g_FrameVar[6] = tostring(nUniqueID)
	g_FrameVar[7] = tonumber(nItemCount)	
	
	local item_name = DataPool:Lua_GetItemNameByIndex(nNeedItemIndex)
	local strTemp = ScriptGlobal_Format("#{NJBZ_221122_03}" ,tostring(nNeedItemCount), item_name, tostring(nYB), tostring(nItemCount))
	
	WuhunQuest_InfoWindow:SetText(strTemp)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定 
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
	WuhunQuestUpdateRect()
	this:Show()
end

function WuhunQuest_PetNeiDan_HuaQi_Confirm(posIndex)

	g_FrameInfo = FrameInfoList.PETNEIDAN_HUAQI_CONFIRM
	g_FrameVar[1] = tonumber(posIndex)
	
	local pnd_level = DataPool:LuaFnGetPetNeiDanLevel(posIndex)
	local pnd_name = DataPool:LuaFnGetPetNeiDanName(posIndex)
	local strTemp = ScriptGlobal_Format("#{ZSND_230428_84}" ,tostring(pnd_level), tostring(pnd_name))
	
	WuhunQuest_InfoWindow:SetText(strTemp)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}") 	--确定 
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}") 	--取消
	WuhunQuestUpdateRect()
	this:Show()
end
function WuhunQuest_SocialRuleLimit_BuyJianDan_OperationConfirm()
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText("#{RLXZ_241106_18}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{RLXZ_241106_20}");  --确定
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{RLXZ_241106_21}");  --取消
	WuhunQuestUpdateRect();
	g_FrameInfo = FrameInfoList.CONFIRM_FACEAUTH_JIANDAN
	this:Show();
end

function WuhunQuest_EquipUpstageAbandonResultConfirm()
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText("#{SZJJ_250801_104}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{RLXZ_241106_20}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{RLXZ_241106_21}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.EUS_ABANDON_RESULT_CONFIRM
	this:Show()
end

function WuhunQuest_EquipUpstageBindConfirm(targetId, equip_bag_index, mat_bag_index, save_confirmed)

	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetId)
	g_FrameVar[2] = tonumber(equip_bag_index)
	g_FrameVar[3] = tonumber(mat_bag_index)
	g_FrameVar[4] = tonumber(save_confirmed)
	
	WuhunQuest_InfoWindow:SetText("#{SZJJ_250801_32}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.EQUIP_UPSTAGE_BIND_CONFIRM
	this:Show()
end

function WuhunQuest_EquipUpstageSaveConfirm(targetId, equip_bag_index, high_rate_count)
	
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetId)
	g_FrameVar[2] = tonumber(equip_bag_index)
	
	local strTemp = ScriptGlobal_Format("#{SZJJ_250801_107}", tostring(high_rate_count))
	WuhunQuest_InfoWindow:SetText(strTemp)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.EQUIP_UPSTAGE_SAVE_CONFIRM
	this:Show()
end

function WuhunQuest_EquipUpstageNoSaveConfirm(targetId, equip_bag_index, mat_bag_index, bind_confirmed, save_confirmed)

	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetId)
	g_FrameVar[2] = tonumber(equip_bag_index)
	g_FrameVar[3] = tonumber(mat_bag_index)
	g_FrameVar[4] = tonumber(bind_confirmed)
	g_FrameVar[5] = tonumber(save_confirmed)
	
	local attr_count = PlayerPackage:LuaFnGetBagEquipExtAttrCount(equip_bag_index)
	if save_confirmed > attr_count then
		local strTemp = ScriptGlobal_Format("#{SZJJ_250801_117}", "全部")
		WuhunQuest_InfoWindow:SetText(strTemp)
	elseif save_confirmed > 0 then
		local attr_type, _ = PlayerPackage:LuaFnGetBagEquipExtAttr(equip_bag_index, save_confirmed - 1)
		local attr_name = ""
		if tonumber(attr_type) ~= nil then 
			attr_name = PlayerPackage:LuaFnGetEquipAttrName(attr_type)
		end	
		local strTemp = ScriptGlobal_Format("#{SZJJ_250801_117}", tostring(attr_name))
		WuhunQuest_InfoWindow:SetText(strTemp)
	else
		WuhunQuest_InfoWindow:SetText("")
	end

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.EQUIP_UPSTAGE_NOSAVE_CONFIRM
	this:Show()
end

function WuhunQuest_EquipUpstageRemoveConfirm(targetId, equip_bag_index)

	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetId)
	g_FrameVar[2] = tonumber(equip_bag_index)
	
	WuhunQuest_InfoWindow:SetText("#{SZJJ_250801_158}")

	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.EQUIP_UPSTAGE_REMOVE_CONFIRM
	this:Show()
end
function WuhunQuest_PetYuanBaoStallListResultConfirm(nYuanbao,petName)
	WuhunQuest_Clear_Var()
	local msg =ScriptGlobal_Format( "#{YBBT_251103_2}", nYuanbao,petName)

	WuhunQuest_InfoWindow:SetText(msg)
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{YBBT_251103_3}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{YBBT_251103_4}")
	g_FrameVar[1] = nYuanbao
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.PET_STALL_LIST_YUANBAO_CONFIRM
	this:Show()
end
--2026Q1藏品藏宝图玩法设计--进副本二次确认
function WuhunQuest_NewBaoTuEnterFubenConfirm(targetId,itemid)
	WuhunQuest_Clear_Var()
	g_FrameVar[1] = tonumber(targetId)
	g_FrameVar[2] = tonumber(itemid)
	WuhunQuest_InfoWindow:SetText("#{CPBT_260115_69}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CPBT_260115_21}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CPBT_260115_22}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.NEWBAOTU_ENTERFUBEN_CONFIRM
	this:Show()
end
--2026Q1藏品藏宝图玩法设计--离开副本二次确认
function WuhunQuest_NewBaoTuLeaveFuben1Confirm()
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText("#{CPBT_260115_73}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CPBT_260115_21}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CPBT_260115_22}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.NEWBAOTU_LEAVEFUBEN1_CONFIRM
	this:Show()
end
--2026Q1藏品藏宝图玩法设计--离开副本二次确认
function WuhunQuest_NewBaoTuLeaveFuben2Confirm()
	WuhunQuest_Clear_Var()
	WuhunQuest_InfoWindow:SetText("#{CPBT_260115_73}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{CPBT_260115_21}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{CPBT_260115_22}")
	WuhunQuestUpdateRect()
	g_FrameInfo = FrameInfoList.NEWBAOTU_LEAVEFUBEN2_CONFIRM
	this:Show()
end

function WuhunQuest_CangPinRankBuffConfirm(rank_type, bonus_level, buff_idx)
	
	WuhunQuest_Clear_Var()
	g_FrameInfo = FrameInfoList.CANGPIN_RANK_BUFF_CONFIRM	
	g_FrameVar[1] = tonumber(rank_type)
	g_FrameVar[2] = tonumber(bonus_level)
	g_FrameVar[3] = tonumber(buff_idx)
	
	WuhunQuest_InfoWindow:SetText("#{CPPH_20260417_57}")
	WuhunQuest_Button1:Show()
	WuhunQuest_Button1:SetText("#{INTERFACE_XML_557}")
	WuhunQuest_Button2:Show()
	WuhunQuest_Button2:SetText("#{INTERFACE_XML_542}")
	WuhunQuestUpdateRect()
	
	this:Show()
end