--  周年庆刷新集市 主界面客户端脚本
-- !!!reloadscript =Anniversary_ExMarket

local g_nMyScriptId = 998437
local g_nCoinTotalCostNum =0 --消耗a的数量
local g_nCoinNum_A = 0 --代币A的数量
local g_nCoinNum_B = 0 --代币B的数量
local g_nCoinTotalCostNum_b =0 --消耗b的数量
local g_nHuoWuNum = 0 --货物的数量
local g_nPriceToday = 0 --今天的售卖价格
local g_nHuoDongStep = 0 		-- 1 货物获取阶段； 1 + 2 + 3 代币A获取使用阶段；3，开放购买代币A； 4 + 5 代币B获取使用阶段； 5 开放购买代币B
local g_nRewardFlagMD = 0
local g_nRefreshTimes = 0 
local g_nRefreshMaxTimes = 25		--最大刷新次数

local g_nMaxCanSellGoodsNum		= 120-- 最大可收货数量
local g_nRewardItemData = {}   --12个奖励的信息
local g_nRewardItemRecordFlag = {}
local g_nRewardItemRecordNum = 0 --已领取过的奖励的数量
local g_nLeiJiRewardRecordFlag = {}
local g_nProfileRedPoint = 0 
local g_NPCCallLimitTimes = 5
local g_nCurNPCCreateTimes = 0
local g_nCanSellGoodsNum = 0
-- 随机奖励的奖励tableID的存储MD，这里整个传给客户端自己解析
-- 从低位开始 大奖池1、2 中奖池 1、2、3、4
-- MD_2023Q1_JISHI_REWARD_INDEX01	=2707	-- 随机到的奖励Index 每5个bit为一个奖励存储 奖池最大32 每个MD存6个奖励 
-- 从低位开始 小奖池 1、2、3、4、5、6
-- MD_2023Q1_JISHI_REWARD_INDEX02	=2708	-- 随机到的奖励Index 每5个bit为一个奖励存储 奖池最大32 每个MD存6个奖励
local g_nRefreshRewardMD1 = 0
local g_nRefreshRewardMD2 = 0
local g_DaiBiALimit = 140 
local g_DaiBiAPrice = 100
local g_DaiBiBLimit = 60
local g_DaiBiBPrice = 100

local g_ShareCD = 10 * 1000  --ms
local g_LastShareTime_1 = 0
local g_LastShareTime_2 = 0
local g_LastShareTime_3 = 0
local g_LastShareTime_4 = 0
	
local g_ChoseFlag={}
local g_Icon_Tips = {}
local g_Button = {}
local g_Anniversary_ExMarket_Frame_UnifiedPosition
local g_nUICommandID		= 79009001  
local g_nComfirmUICommandID = 79009005  
local g_nBuyDaibiComfirmUICommandID = 79009006
local g_nCallNPCComfirmUICommandID = 79009007
local g_nBuyDaiBiNum = 0
local g_nBuyDaiBiType = 0
local g_Lace_Icon = {}
local g_Lace_IconNum = {}
local g_Lace_IconCheck = {}
local g_Lace_EyeSign = {}
local g_Lace_IconLimit = {}
local g_Lace_Animate = {}
local g_nRewardLevel = 0 
local g_nRewardIndex = 0 
-- local g_tabRefreshCost = {100,100,50}
-- 总消耗固定奖励信息
local g_tTotalCostRewardInfo		= 
{
	-- -- 消耗代币数	奖励
	-- -- 20310168	400	金蚕丝*2
	-- -- 20501003	800	3级棉布
	-- -- 38000807	1200	典籍注解*2
	-- -- 38006293	1800	主题时装碎片
	-- -- 20502003	2400	3级秘银
	-- -- 10102976	3000	翻新武器：棒棒糖
	
	-- [1] = {nItemID = 20310168, nItemNum = 2, bBind = 1, nBagSpace = 0, nMatSpace = 1, nNeedCostDaiBiNum = 400, },
	-- [2] = {nItemID = 20501003, nItemNum = 1, bBind = 1, nBagSpace = 0, nMatSpace = 1, nNeedCostDaiBiNum = 800, },
	-- [3] = {nItemID = 38000807, nItemNum = 2, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 1200, },
	-- [4] = {nItemID = 38006293, nItemNum = 1, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 1800, },
	-- [5] = {nItemID = 20502003, nItemNum = 1, bBind = 1, nBagSpace = 0, nMatSpace = 1, nNeedCostDaiBiNum = 2400, },
	-- [6] = {nItemID = 10102976, nItemNum = 1, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 3000, },

	-- 消耗代币数	奖励
	-- 20310168	400	金蚕丝*2
	-- 20501003	800	3级棉布
	-- 38000807	1200	典籍注解*2
	-- 38006293	1800	主题时装碎片		缀梦灵石*2 38001595
	-- 20502003	2400	3级秘银
	-- 10102976	3000	翻新武器：棒棒糖 	新主题时装碎片*1 38006739
	
	[1] = {nItemID = 20310168, nItemNum = 2, bBind = 1, nBagSpace = 0, nMatSpace = 1, nNeedCostDaiBiNum = 10, },
	[2] = {nItemID = 20501003, nItemNum = 1, bBind = 1, nBagSpace = 0, nMatSpace = 1, nNeedCostDaiBiNum = 20, },
	[3] = {nItemID = 38000807, nItemNum = 2, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 30, },
	[4] = {nItemID = 38001595, nItemNum = 2, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 40, },
	[5] = {nItemID = 20502003, nItemNum = 1, bBind = 1, nBagSpace = 0, nMatSpace = 1, nNeedCostDaiBiNum = 60, },
	-- [6] = {nItemID = 38006739, nItemNum = 1, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 80, },
	-- [6] = {nItemID = 38007983, nItemNum = 1, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 80, },
	[6] = {nItemID = 38008355, nItemNum = 1, bBind = 1, nBagSpace = 1, nMatSpace = 0, nNeedCostDaiBiNum = 80, },
}


local g_tRewardInfo = {}
-- 随机奖励刷新信息
local g_tRefreshRewardInfo		= 
{
	[1] = 
	{
		nCostDaiBiNum = 2,
		tRewardPool = 
		{
			[1]		= {nItemID = 38000992, nItemNum = 3, bUnique = 0,  nRare = 0,  isShizhuang = 0,},
			[2]		= {nItemID = 38001595, nItemNum = 5, bUnique = 0,  nRare = 0,   isShizhuang = 0 ,},
			[3]		= {nItemID = 38005288, nItemNum = 5, bUnique = 0,  nRare = 0,   isShizhuang = 0,},
			[4]		= {nItemID = 10127233, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[5]		= {nItemID = 10126699, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[6]		= {nItemID = 10126802, nItemNum = 1, bUnique = 1,   nRare = 1,  isShizhuang = 1,},
			[7]		= {nItemID = 10127234, nItemNum = 1, bUnique = 1,  nRare = 1,   isShizhuang = 1,},
			[8]		= {nItemID = 10126700, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[9]		= {nItemID = 10126803, nItemNum = 1, bUnique = 1,   nRare = 1,    isShizhuang = 1,},
			[10]	= {nItemID = 10127236, nItemNum = 1, bUnique = 1,   nRare = 2,   isShizhuang = 1 ,},
			[11]	= {nItemID = 10126702, nItemNum = 1, bUnique = 1,   nRare = 2,   isShizhuang = 1 ,},
			[12]	= {nItemID = 10126805, nItemNum = 1, bUnique = 1,  nRare = 2,   isShizhuang = 1 ,},
			[13]	= {nItemID = 10127897, nItemNum = 1, bUnique = 1,   nRare = 2, isShizhuang = 1 ,},
			[14]	= {nItemID = 10127145, nItemNum = 1, bUnique = 1,   nRare = 2,  isShizhuang = 1 ,},
		},
	},
	[2] = 
	{
		nCostDaiBiNum = 2,
		tRewardPool = 
		{
			[1]		= {nItemID = 38000992, nItemNum = 3,bUnique = 0, nRare = 0, },
			[2]		= {nItemID = 38001595, nItemNum = 5,  bUnique = 0,  nRare = 0, },
			[3]		= {nItemID = 38005288, nItemNum = 5,  bUnique = 0,   nRare = 0,   },
			[4]		= {nItemID = 10102941, nItemNum = 1,  bUnique = 1,  nRare = 1,   },
			[5]		= {nItemID = 10102829, nItemNum = 1, bUnique = 1,  nRare = 1, },
			[6]		= {nItemID = 10104126, nItemNum = 1, bUnique = 1,  nRare = 1,},
			[7]		= {nItemID = 10102606, nItemNum = 1,  bUnique = 1,   nRare = 2, },
			[8]		= {nItemID = 10192044, nItemNum = 1,  bUnique = 1,   nRare = 2,  },
			[9]		= {nItemID = 10102843, nItemNum = 1,  bUnique = 1,nRare = 1,  },
			[10]	= {nItemID = 10106102, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[11]	= {nItemID = 10102787, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[12]	= {nItemID = 10102906, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[13]	= {nItemID = 10101052, nItemNum = 1, bUnique = 1,   nRare = 2,  },
		},
	},
	[3] = 
	{
		nCostDaiBiNum = 1,
		tRewardPool = 
		{
			[1]		= {nItemID = 20310168, nItemNum = 10, 	 bUnique = 0, nRare = 0, },
			[2]		= {nItemID = 20700055, nItemNum = 15, 	 bUnique = 0, nRare = 0, },
			[3]		= {nItemID = 38000807, nItemNum = 3, 	 bUnique = 0, nRare = 0,   },
			[4]		= {nItemID = 38000378, nItemNum = 6, 	 bUnique = 0,  nRare = 0,   },
			[5]		= {nItemID = 20800033, nItemNum = 10, 	 bUnique = 0, nRare = 0,  },
			[6]		= {nItemID = 38004354, nItemNum = 10, 	 bUnique = 0,nRare = 0,   },
			[7]		= {nItemID = 38002041, nItemNum = 10, 	 bUnique = 0,   nRare = 0,   },
			[8]		= {nItemID = 38004359, nItemNum = 1, 	 bUnique = 0,  nRare = 0,   },
			[9]		= {nItemID = 20800031, nItemNum = 2, 	 bUnique = 0,  nRare = 0,  },
			[10]	= {nItemID = 20310179, nItemNum = 1,	 bUnique = 0,   nRare = 0,   },
			[11]	= {nItemID = 38004358, nItemNum = 2, 	 bUnique = 0,  nRare = 0,  },
		},
	},
}

-- 随机奖励刷新信息
local g_tRefreshRewardInfoOfKaJiServer = 
{
	[1] = 
	{
		nCostDaiBiNum = 2,
		tRewardPool = 
		{
			[1]		= {nItemID = 38000992, nItemNum = 3, bUnique = 0,  nRare = 0,  isShizhuang = 0,},
			[2]		= {nItemID = 38001595, nItemNum = 5, bUnique = 0,  nRare = 0,   isShizhuang = 0 ,},
			[3]		= {nItemID = 38005288, nItemNum = 5, bUnique = 0,  nRare = 0,   isShizhuang = 0,},
			[4]		= {nItemID = 10127233, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[5]		= {nItemID = 10126699, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[6]		= {nItemID = 10126802, nItemNum = 1, bUnique = 1,   nRare = 1,  isShizhuang = 1,},
			[7]		= {nItemID = 10127234, nItemNum = 1, bUnique = 1,  nRare = 1,   isShizhuang = 1,},
			[8]		= {nItemID = 10126700, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[9]		= {nItemID = 10126803, nItemNum = 1, bUnique = 1,   nRare = 1,    isShizhuang = 1,},
			[10]	= {nItemID = 10127236, nItemNum = 1, bUnique = 1,   nRare = 2,   isShizhuang = 1 ,},
			[11]	= {nItemID = 10126702, nItemNum = 1, bUnique = 1,   nRare = 2,   isShizhuang = 1 ,},
			[12]	= {nItemID = 10126805, nItemNum = 1, bUnique = 1,  nRare = 2,   isShizhuang = 1 ,},
			[13]	= {nItemID = 10127897, nItemNum = 1, bUnique = 1,   nRare = 2, isShizhuang = 1 ,},
			[14]	= {nItemID = 10127145, nItemNum = 1, bUnique = 1,   nRare = 2,  isShizhuang = 1 ,},
		},
	},
	[2] = 
	{
		nCostDaiBiNum = 2,
		tRewardPool = 
		{
			[1]		= {nItemID = 38000992, nItemNum = 3,bUnique = 0, nRare = 0, },
			[2]		= {nItemID = 38001595, nItemNum = 5,  bUnique = 0,  nRare = 0, },
			[3]		= {nItemID = 38005288, nItemNum = 5,  bUnique = 0,   nRare = 0,   },
			[4]		= {nItemID = 10102941, nItemNum = 1,  bUnique = 1,  nRare = 1,   },
			[5]		= {nItemID = 10102829, nItemNum = 1, bUnique = 1,  nRare = 1, },
			[6]		= {nItemID = 10104126, nItemNum = 1, bUnique = 1,  nRare = 1,},
			[7]		= {nItemID = 10102606, nItemNum = 1,  bUnique = 1,   nRare = 2, },
			[8]		= {nItemID = 10192044, nItemNum = 1,  bUnique = 1,   nRare = 2,  },
			[9]		= {nItemID = 10102843, nItemNum = 1,  bUnique = 1,nRare = 1,  },
			[10]	= {nItemID = 10106102, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[11]	= {nItemID = 10102787, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[12]	= {nItemID = 10102906, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[13]	= {nItemID = 10101052, nItemNum = 1, bUnique = 1,   nRare = 2,  },
		},
	},
	[3] = 
	{
		nCostDaiBiNum = 1,
		tRewardPool = 
		{
			[1]		= {nItemID = 20310168, nItemNum = 10, 	 bUnique = 0, 	nRare = 0, },
			[2]		= {nItemID = 30700241, nItemNum = 2, 	 bUnique = 0,	nRare = 0, },
			[3]		= {nItemID = 38000807, nItemNum = 3, 	 bUnique = 0, 	nRare = 0, },
			[4]		= {nItemID = 30503133, nItemNum = 2, 	 bUnique = 0,	nRare = 0, },
			[5]		= {nItemID = 38000656, nItemNum = 3, 	 bUnique = 0,	nRare = 0, },
			[6]		= {nItemID = 38000658, nItemNum = 1, 	 bUnique = 0,	nRare = 0, },
			[7]		= {nItemID = 38005733, nItemNum = 4, 	 bUnique = 0,   nRare = 0, },
			[8]		= {nItemID = 30503188, nItemNum = 10, 	 bUnique = 0, 	nRare = 0, },
			[9]		= {nItemID = 38000837, nItemNum = 10, 	 bUnique = 0,	nRare = 0, },
			[10]	= {nItemID = 38001553, nItemNum = 4,	 bUnique = 0,   nRare = 0, },
			[11]	= {nItemID = 38000571, nItemNum = 2, 	 bUnique = 0,	nRare = 0, },
		},
	},
}

-- 随机奖励刷新信息
local g_tRefreshRewardInfoOfOriginalServer = 
{
	[1] = 
	{
		nCostDaiBiNum = 2,
		tRewardPool = 
		{
			[1]		= {nItemID = 38000992, nItemNum = 3, bUnique = 0,  nRare = 0,  isShizhuang = 0,},
			[2]		= {nItemID = 38001595, nItemNum = 5, bUnique = 0,  nRare = 0,   isShizhuang = 0 ,},
			[3]		= {nItemID = 38005288, nItemNum = 5, bUnique = 0,  nRare = 0,   isShizhuang = 0,},
			[4]		= {nItemID = 10127233, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[5]		= {nItemID = 10126699, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[6]		= {nItemID = 10126802, nItemNum = 1, bUnique = 1,   nRare = 1,  isShizhuang = 1,},
			[7]		= {nItemID = 10127234, nItemNum = 1, bUnique = 1,  nRare = 1,   isShizhuang = 1,},
			[8]		= {nItemID = 10126700, nItemNum = 1, bUnique = 1,   nRare = 1,   isShizhuang = 1,},
			[9]		= {nItemID = 10126803, nItemNum = 1, bUnique = 1,   nRare = 1,    isShizhuang = 1,},
			[10]	= {nItemID = 10127236, nItemNum = 1, bUnique = 1,   nRare = 2,   isShizhuang = 1 ,},
			[11]	= {nItemID = 10126702, nItemNum = 1, bUnique = 1,   nRare = 2,   isShizhuang = 1 ,},
			[12]	= {nItemID = 10126805, nItemNum = 1, bUnique = 1,  nRare = 2,   isShizhuang = 1 ,},
			[13]	= {nItemID = 10127897, nItemNum = 1, bUnique = 1,   nRare = 2, isShizhuang = 1 ,},
			[14]	= {nItemID = 10127145, nItemNum = 1, bUnique = 1,   nRare = 2,  isShizhuang = 1 ,},
		},
	},
	[2] = 
	{
		nCostDaiBiNum = 2,
		tRewardPool = 
		{
			[1]		= {nItemID = 38000992, nItemNum = 3,bUnique = 0, nRare = 0, },
			[2]		= {nItemID = 38001595, nItemNum = 5,  bUnique = 0,  nRare = 0, },
			[3]		= {nItemID = 38005288, nItemNum = 5,  bUnique = 0,   nRare = 0,   },
			[4]		= {nItemID = 10102941, nItemNum = 1,  bUnique = 1,  nRare = 1,   },
			[5]		= {nItemID = 10102829, nItemNum = 1, bUnique = 1,  nRare = 1, },
			[6]		= {nItemID = 10104126, nItemNum = 1, bUnique = 1,  nRare = 1,},
			[7]		= {nItemID = 10102606, nItemNum = 1,  bUnique = 1,   nRare = 2, },
			[8]		= {nItemID = 10192044, nItemNum = 1,  bUnique = 1,   nRare = 2,  },
			[9]		= {nItemID = 10102843, nItemNum = 1,  bUnique = 1,nRare = 1,  },
			[10]	= {nItemID = 10106102, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[11]	= {nItemID = 10102787, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[12]	= {nItemID = 10102906, nItemNum = 1,  bUnique = 1, nRare = 2,   },
			[13]	= {nItemID = 10101052, nItemNum = 1, bUnique = 1,   nRare = 2,  },
		},
	},
	[3] = 
	{
		nCostDaiBiNum = 1,
		tRewardPool = 
		{
			[1]		= {nItemID = 20310168, nItemNum = 10, 	 bUnique = 0, 	nRare = 0, },
			[2]		= {nItemID = 20700055, nItemNum = 15, 	 bUnique = 0, 	nRare = 0, },
			[3]		= {nItemID = 38000807, nItemNum = 3, 	 bUnique = 0, 	nRare = 0, },
			[4]		= {nItemID = 38000378, nItemNum = 6, 	 bUnique = 0, 	nRare = 0, },
			[5]		= {nItemID = 38000656, nItemNum = 3, 	 bUnique = 0,	nRare = 0, },
			[6]		= {nItemID = 38000658, nItemNum = 1, 	 bUnique = 0,	nRare = 0, },
			[7]		= {nItemID = 38005733, nItemNum = 4, 	 bUnique = 0,   nRare = 0, },
			[8]		= {nItemID = 30503188, nItemNum = 10, 	 bUnique = 0, 	nRare = 0, },
			[9]		= {nItemID = 38000837, nItemNum = 10, 	 bUnique = 0,	nRare = 0, },
			[10]	= {nItemID = 38001553, nItemNum = 4,	 bUnique = 0,   nRare = 0, },
			[11]	= {nItemID = 38000571, nItemNum = 2, 	 bUnique = 0,	nRare = 0, },
		},
	},
}

-- 每次消耗B的数量
local g_tCostDaiBiBNumPerTime		= 
{
	-- 掏奖次数	掏奖代币
	-- 1-8次	3
	-- 9-12次	4
	-- 12-16次	5
	[1] 	= 3,
	[2] 	= 3,
	[3] 	= 3,
	[4] 	= 3,
	[5] 	= 3,
	[6] 	= 3,
	[7] 	= 3,
	[8] 	= 3,
	[9] 	= 4,
	[10] 	= 4,
	[11] 	= 4,
	[12] 	= 4,
	[13] 	= 5,
	[14] 	= 5,
	[15] 	= 5,
	[16] 	= 5,
}

local g_tRandomRewardSaveInfo		= 
{
	-- 大奖
	[1] = 
	{
		[1] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 0, 	nIndexSaveLen = 4, nDefaultIndex = 1,  nFlagSavePos = 0, },
		[2] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 4, 	nIndexSaveLen = 4, nDefaultIndex = 1,  nFlagSavePos = 1, },
		[3] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 8, 	nIndexSaveLen = 4, nDefaultIndex = 2,  nFlagSavePos = 2, }, 
		[4] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 12, 	nIndexSaveLen = 4, nDefaultIndex = 2,  nFlagSavePos = 3, }, 
	},

	-- 中奖
	[2] = 
	{
		[1] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 16, 	nIndexSaveLen = 4, nDefaultIndex = 1,  nFlagSavePos = 4, },
		[2] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 20, 	nIndexSaveLen = 4, nDefaultIndex = 1,  nFlagSavePos = 5, },
		[3] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 24, 	nIndexSaveLen = 4, nDefaultIndex = 2,  nFlagSavePos = 6, },
		[4] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX01, nIndexSavePos = 28, 	nIndexSaveLen = 4, nDefaultIndex = 2,  nFlagSavePos = 7, },
	},

	-- 小奖
	[3] = 
	{
		[1] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 0,  	nIndexSaveLen = 4, nDefaultIndex = 2,  nFlagSavePos = 8, },
		[2] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 4,  	nIndexSaveLen = 4, nDefaultIndex = 2,  nFlagSavePos = 9, },
		[3] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 8, 	nIndexSaveLen = 4, nDefaultIndex = 3,  nFlagSavePos = 10, },
		[4] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 12,	nIndexSaveLen = 4, nDefaultIndex = 3,  nFlagSavePos = 11, },
		[5] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 16,	nIndexSaveLen = 4, nDefaultIndex = 5,  nFlagSavePos = 12, },
		[6] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 20,	nIndexSaveLen = 4, nDefaultIndex = 5,  nFlagSavePos = 13, },
		[7] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 24,	nIndexSaveLen = 4, nDefaultIndex = 6,  nFlagSavePos = 14, },
		[8] = {nIndexSaveMD = MD_2023Q1_JISHI_REWARD_INDEX02, nIndexSavePos = 28,	nIndexSaveLen = 4, nDefaultIndex = 6,  nFlagSavePos = 15, },
	},
}


--=========================================================
-- PreLoad
--=========================================================
function Anniversary_ExMarket_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
		
end


--=========================================================
-- OnLoad
--=========================================================
function Anniversary_ExMarket_OnLoad()
	g_Anniversary_ExMarket_Frame_UnifiedPosition =  Anniversary_ExMarket:GetProperty("UnifiedPosition")
	--累计奖励红点
	g_Icon_Tips[1]= Anniversary_ExMarket_Leiji_Icon1Tips
	g_Icon_Tips[2]= Anniversary_ExMarket_Leiji_Icon2Tips
	g_Icon_Tips[3]= Anniversary_ExMarket_Leiji_Icon3Tips
	g_Icon_Tips[4]= Anniversary_ExMarket_Leiji_Icon4Tips
	g_Icon_Tips[5]= Anniversary_ExMarket_Leiji_Icon5Tips
	g_Icon_Tips[6]= Anniversary_ExMarket_Leiji_Icon6Tips
	
	--累计奖励图标
	g_Button[1] = Anniversary_ExMarket_Leiji_Icon1
	g_Button[2] = Anniversary_ExMarket_Leiji_Icon2
	g_Button[3] = Anniversary_ExMarket_Leiji_Icon3
	g_Button[4] = Anniversary_ExMarket_Leiji_Icon4
	g_Button[5] = Anniversary_ExMarket_Leiji_Icon5
	g_Button[6] = Anniversary_ExMarket_Leiji_Icon6
	
	--奖池图标
	g_Lace_Icon[1] = 	Anniversary_ExMarket_Lace1_Icon1
	g_Lace_Icon[2] =	Anniversary_ExMarket_Lace1_Icon2
	g_Lace_Icon[3] =	Anniversary_ExMarket_Lace1_Icon3
	g_Lace_Icon[4] =	Anniversary_ExMarket_Lace1_Icon4
	
	g_Lace_Icon[5] = 	Anniversary_ExMarket_Lace2_Icon1
	g_Lace_Icon[6] = 	Anniversary_ExMarket_Lace2_Icon2
	g_Lace_Icon[7] = 	Anniversary_ExMarket_Lace2_Icon3
	g_Lace_Icon[8] =	Anniversary_ExMarket_Lace2_Icon4
	
	g_Lace_Icon[9] = 	Anniversary_ExMarket_Lace3_Icon1
	g_Lace_Icon[10] = 	Anniversary_ExMarket_Lace3_Icon2
	g_Lace_Icon[11] = 	Anniversary_ExMarket_Lace3_Icon3
	g_Lace_Icon[12] = 	Anniversary_ExMarket_Lace3_Icon4
	g_Lace_Icon[13] =	Anniversary_ExMarket_Lace3_Icon5
	g_Lace_Icon[14] =	Anniversary_ExMarket_Lace3_Icon6
	g_Lace_Icon[15] =	Anniversary_ExMarket_Lace3_Icon7
	g_Lace_Icon[16] =	Anniversary_ExMarket_Lace3_Icon8
	--数量角标
	g_Lace_IconNum[1]=	Anniversary_ExMarket_Lace1_Icon1Num
	g_Lace_IconNum[2]=	Anniversary_ExMarket_Lace1_Icon2Num
	g_Lace_IconNum[3]=	Anniversary_ExMarket_Lace1_Icon3Num
	g_Lace_IconNum[4]=	Anniversary_ExMarket_Lace1_Icon4Num
	
	
	g_Lace_IconNum[5]=	Anniversary_ExMarket_Lace2_Icon1Num
	g_Lace_IconNum[6]=	Anniversary_ExMarket_Lace2_Icon2Num
	g_Lace_IconNum[7]=	Anniversary_ExMarket_Lace2_Icon3Num
	g_Lace_IconNum[8]=	Anniversary_ExMarket_Lace2_Icon4Num
	
	g_Lace_IconNum[9]=	Anniversary_ExMarket_Lace3_Icon1Num
	g_Lace_IconNum[10]=	Anniversary_ExMarket_Lace3_Icon2Num
	g_Lace_IconNum[11]=	Anniversary_ExMarket_Lace3_Icon3Num
	g_Lace_IconNum[12]=	Anniversary_ExMarket_Lace3_Icon4Num
	g_Lace_IconNum[13]=	Anniversary_ExMarket_Lace3_Icon5Num
	g_Lace_IconNum[14]=	Anniversary_ExMarket_Lace3_Icon6Num
	g_Lace_IconNum[15]=	Anniversary_ExMarket_Lace3_Icon7Num
	g_Lace_IconNum[16]=	Anniversary_ExMarket_Lace3_Icon8Num
	
	--已兑换角标
	g_Lace_IconCheck[1]=	Anniversary_ExMarket_Lace1_Icon1Check
	g_Lace_IconCheck[2]=	Anniversary_ExMarket_Lace1_Icon2Check
	g_Lace_IconCheck[3]=	Anniversary_ExMarket_Lace1_Icon3Check
	g_Lace_IconCheck[4]=	Anniversary_ExMarket_Lace1_Icon4Check
	
	
	g_Lace_IconCheck[5]=	Anniversary_ExMarket_Lace2_Icon1Check
	g_Lace_IconCheck[6]=	Anniversary_ExMarket_Lace2_Icon2Check
	g_Lace_IconCheck[7]=	Anniversary_ExMarket_Lace2_Icon3Check
	g_Lace_IconCheck[8]=	Anniversary_ExMarket_Lace2_Icon4Check
	
	g_Lace_IconCheck[9]=	Anniversary_ExMarket_Lace3_Icon1Check
	g_Lace_IconCheck[10]=	Anniversary_ExMarket_Lace3_Icon2Check
	g_Lace_IconCheck[11]=	Anniversary_ExMarket_Lace3_Icon3Check
	g_Lace_IconCheck[12]=	Anniversary_ExMarket_Lace3_Icon4Check
	g_Lace_IconCheck[13]=	Anniversary_ExMarket_Lace3_Icon5Check
	g_Lace_IconCheck[14]=	Anniversary_ExMarket_Lace3_Icon6Check
	g_Lace_IconCheck[15]=	Anniversary_ExMarket_Lace3_Icon7Check
	g_Lace_IconCheck[16]=	Anniversary_ExMarket_Lace3_Icon8Check

	--刷新时选中的对勾
	g_ChoseFlag[1] =  Anniversary_ExMarket_Lace1_Icon1Select
	g_ChoseFlag[2] =  Anniversary_ExMarket_Lace1_Icon2Select
	g_ChoseFlag[3] =  Anniversary_ExMarket_Lace1_Icon3Select
	g_ChoseFlag[4] =  Anniversary_ExMarket_Lace1_Icon4Select
	
	g_ChoseFlag[5] =  Anniversary_ExMarket_Lace2_Icon1Select
	g_ChoseFlag[6] =  Anniversary_ExMarket_Lace2_Icon2Select
	g_ChoseFlag[7] =  Anniversary_ExMarket_Lace2_Icon3Select
	g_ChoseFlag[8] =  Anniversary_ExMarket_Lace2_Icon4Select
	
	g_ChoseFlag[9] =  Anniversary_ExMarket_Lace3_Icon1Select
	g_ChoseFlag[10] =  Anniversary_ExMarket_Lace3_Icon2Select
	g_ChoseFlag[11] =  Anniversary_ExMarket_Lace3_Icon3Select
	g_ChoseFlag[12] =  Anniversary_ExMarket_Lace3_Icon4Select
	g_ChoseFlag[13] =  Anniversary_ExMarket_Lace3_Icon5Select
	g_ChoseFlag[14] =  Anniversary_ExMarket_Lace3_Icon6Select
	g_ChoseFlag[15] =  Anniversary_ExMarket_Lace3_Icon7Select
	g_ChoseFlag[16] =  Anniversary_ExMarket_Lace3_Icon8Select
	--时装预览小眼睛
	
	g_Lace_EyeSign[1]= Anniversary_ExMarket_Lace1_Icon1_Icon1EyeSign
	g_Lace_EyeSign[2]= Anniversary_ExMarket_Lace1_Icon1_Icon2EyeSign
	g_Lace_EyeSign[3]= Anniversary_ExMarket_Lace1_Icon1_Icon3EyeSign
	g_Lace_EyeSign[4]= Anniversary_ExMarket_Lace1_Icon1_Icon4EyeSign	
	
	--限量角标
	g_Lace_IconLimit[1]=	Anniversary_ExMarket_Lace1_Icon1Mark
	g_Lace_IconLimit[2]=	Anniversary_ExMarket_Lace1_Icon2Mark
	g_Lace_IconLimit[3]=	Anniversary_ExMarket_Lace1_Icon3Mark
	g_Lace_IconLimit[4]=	Anniversary_ExMarket_Lace1_Icon4Mark
	
	
	g_Lace_IconLimit[5]=	Anniversary_ExMarket_Lace2_Icon1Mark
	g_Lace_IconLimit[6]=	Anniversary_ExMarket_Lace2_Icon2Mark
	g_Lace_IconLimit[7]=	Anniversary_ExMarket_Lace2_Icon3Mark
	g_Lace_IconLimit[8]=	Anniversary_ExMarket_Lace2_Icon4Mark
	
	g_Lace_IconLimit[9]=	Anniversary_ExMarket_Lace3_Icon1Mark
	g_Lace_IconLimit[10]=	Anniversary_ExMarket_Lace3_Icon2Mark
	g_Lace_IconLimit[11]=	Anniversary_ExMarket_Lace3_Icon3Mark
	g_Lace_IconLimit[12]=	Anniversary_ExMarket_Lace3_Icon4Mark
	g_Lace_IconLimit[13]=	Anniversary_ExMarket_Lace3_Icon5Mark
	g_Lace_IconLimit[14]=	Anniversary_ExMarket_Lace3_Icon6Mark
	g_Lace_IconLimit[15]=	Anniversary_ExMarket_Lace3_Icon7Mark
	g_Lace_IconLimit[16]=	Anniversary_ExMarket_Lace3_Icon8Mark
	
	Anniversary_ExMarket_ShareAddItem()--设置分享下拉列表

	
	--稀有金边动画
	
	g_Lace_Animate[1] = Anniversary_ExMarket_Lace1_Icon1Animate
	g_Lace_Animate[2] = Anniversary_ExMarket_Lace1_Icon2Animate
	g_Lace_Animate[3] = Anniversary_ExMarket_Lace1_Icon3Animate
	g_Lace_Animate[4] = Anniversary_ExMarket_Lace1_Icon4Animate	
	g_Lace_Animate[5] = Anniversary_ExMarket_Lace2_Icon1Animate
	g_Lace_Animate[6] = Anniversary_ExMarket_Lace2_Icon2Animate
	g_Lace_Animate[7] = Anniversary_ExMarket_Lace2_Icon3Animate
	g_Lace_Animate[8] = Anniversary_ExMarket_Lace2_Icon4Animate	

	
	g_nCoinTotalCostNum = 0
	g_nCoinTotalCostNum_b = 0
	g_nCoinNum_A = 0 
	g_nCoinNum_B = 0 
	g_nHuoWuNum = 0 
	g_nPriceToday = 0 
	g_nRefreshRewardMD1 = 0
	g_nRefreshRewardMD2 = 0
	g_nHuoDongStep = 0
	g_nRewardFlagMD = 0
	g_nRefreshTimes = 0
	g_nRewardLevel = 0 
	g_nRewardIndex = 0 
    g_nRewardItemRecordNum = 0
	g_nCurNPCCreateTimes = 0
	g_nProfileRedPoint = 0 
	g_nCanSellGoodsNum = 0
	g_nRewardItemData = {}
	g_nRewardItemRecordFlag = {}
	g_nLeiJiRewardRecordFlag = {}
	for i=1,16 do
		g_ChoseFlag[i]:Hide()
	end
end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_ExMarket_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新
		local nOpType 	= Get_XParam_INT(0)

		--PushDebugMessage("UI_COMMAND nOpType"..nOpType)
		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				 Anniversary_ExMarket_Close()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			--PushDebugMessage("打开界面")
			
			Anniversary_ExMarket_Reset()
			Anniversary_ExMarket_ParamInit()
			Anniversary_ExMarket_Update()
			this:Show()
			Anniversary_ExMarket_DaibiBuyClient:Hide()
		end
		
		if 2 == nOpType then
			Anniversary_ExMarket_ParamInit()
			Anniversary_ExMarket_Update()
		end

	elseif ( event == "UI_COMMAND" and tonumber(arg0) == g_nComfirmUICommandID ) then
		-- 二次确认框
		local strMsg = Get_XParam_STR(0)
		local nComfirmParam1 = Get_XParam_INT(0)
		--PushDebugMessage("主界面点击nComfirmParam1="..nComfirmParam1)
		if nComfirmParam1 == 1 then  --确认的是主界面点击替换稀有物品的按钮
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("Anniversary_ExMarket_OnComfirmedBack_1", {["Content"] = strMsg,["Type"] = "YesNo", })
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == g_nBuyDaibiComfirmUICommandID ) then
		-- 买代币的二次确认框
		local strMsg = Get_XParam_STR(0)
		
		local nComfirmParam1 = Get_XParam_INT(0)
		g_nBuyDaiBiType = Get_XParam_INT(1)
		g_nBuyDaiBiNum = Get_XParam_INT(2)
		if nComfirmParam1 == 3 then  
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("Anniversary_ExMarket_OnBuyDaibiComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == g_nCallNPCComfirmUICommandID ) then
		-- 召唤npc的二次确认框
		local strMsg = Get_XParam_STR(0)	
		MessageBoxSelf3("Anniversary_ExMarket_OnCallNPCComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
	elseif event == "UPDATE_YUANBAO" then
		--小界面元宝改变
		Anniversary_ExMarket_Refresh1_DaibiBuy_HaveYuanbaoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_138}", tostring(Player:GetData("YUANBAO")) )) 
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		--切换场景关闭界面
		Anniversary_ExMarket_Close()	
	
	elseif (event == "ADJEST_UI_POS" ) then
		Anniversary_ExMarket_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_ExMarket_Frame_On_ResetPos()
		
	end

end
--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
-- for 主界面 点击替换稀有物品的按钮
--=========================================================
function Anniversary_ExMarket_OnComfirmedBack_1(strRet)
	
	--PushDebugMessage(" for 主界面 点击替换稀有物品的按钮")
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Anniversary_ExMarket_ConfirmClick()	
	end

	if "No" == strRet then
		-- 关闭二次确认框就行，返回主界面
	end
end

--=========================================================
-- 确认想要刷新稀有奖励  
--=========================================================
function Anniversary_ExMarket_ConfirmClick()	
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)	
			Set_XSCRIPT_Parameter(0, 30) --ntype		
			Set_XSCRIPT_Parameter(1, g_nRewardLevel)
			Set_XSCRIPT_Parameter(2, g_nRewardIndex)	
			Set_XSCRIPT_Parameter(3, 1)	--comfirm
			Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Anniversary_ExMarket_ParamInit()
	g_nHuoWuNum 			= Get_XParam_INT(1)
	g_nCoinNum_A			= Get_XParam_INT(2)
	g_nCoinNum_B			= Get_XParam_INT(3)
	g_nCoinTotalCostNum		= Get_XParam_INT(4)
	g_nRefreshRewardMD1 	= Get_XParam_INT(5)
	g_nRefreshRewardMD2 	= Get_XParam_INT(6)
	g_nPriceToday			= Get_XParam_INT(7)
	g_nHuoDongStep			= Get_XParam_INT(8)
	g_nRewardFlagMD 		= Get_XParam_INT(9)
	g_nCurNPCCreateTimes 	= Get_XParam_INT(10)
	g_nCanSellGoodsNum 		= Get_XParam_INT(11)
	g_nProfileRedPoint 	    = Get_XParam_INT(12)
	--随机出的奖励池内容
	-- 高级奖励
	for i=1, 4 do  
		local index = 0
		_,index = GetBitValueInUINT(g_nRefreshRewardMD1, (i-1)*4, 4)
		g_nRewardItemData[i] = index   				--在奖励表里的位置 1-9
	end
	-- 中级奖励
	for i=5, 8 do
		local index = 0
		_,index = GetBitValueInUINT(g_nRefreshRewardMD1, (i-1)*4, 4)
		g_nRewardItemData[i] = index     			--在奖励表里的位置 1-9
	end
	-- 低级奖励
	for i=9, 16 do
		local index = 0
		_,index = GetBitValueInUINT(g_nRefreshRewardMD2, (i-9)*4, 4)
		g_nRewardItemData[i] = index   				--在奖励表里的位置 1-9
	end
	
	--计算下消耗b的数量
	g_nCoinTotalCostNum_b =  0
	g_nRewardItemRecordNum = 0	
	--奖池领奖记录
	for i=1, 16 do
		_, g_nRewardItemRecordFlag[i] = GetBitValueInUINT(g_nRewardFlagMD, i-1, 1)
		if g_nRewardItemRecordFlag[i] ~= 0 then
			g_nRewardItemRecordNum = g_nRewardItemRecordNum + 1
			g_nCoinTotalCostNum_b = g_nCoinTotalCostNum_b + g_tCostDaiBiBNumPerTime[g_nRewardItemRecordNum]
		end
	end
			
	--累计奖励领奖记录
	for i=17, 22 do
		_, g_nLeiJiRewardRecordFlag[i-16] = GetBitValueInUINT(g_nRewardFlagMD, i-1, 1)
	end
end

--=========================================================
-- 界面更新
--=========================================================
function Anniversary_ExMarket_Update()
		--PushDebugMessage("界面更新")
	
	-- 1 货物获取阶段； 1 + 2 + 3 代币A获取使用阶段；3，开放购买代币A； 4 + 5 代币B获取使用阶段； 5 开放购买代币B
	if g_nHuoDongStep == 1 or g_nHuoDongStep == 2 or g_nHuoDongStep == 3  then
		Anniversary_ExMarket_Refresh1_DaibiAText:SetText(ScriptGlobal_Format("#{ZNJS_230220_32}", g_nCoinNum_A)) --代币a：%个
		Anniversary_ExMarket_Refresh1_DaibiAText:Show()
		Anniversary_ExMarket_Refresh1_DaibiAImage:Show()
		
		Anniversary_ExMarket_Refresh1_DaibiBImage:Hide()
		Anniversary_ExMarket_Refresh1_DaibiBText:Hide()
		
		Anniversary_ExMarket_ReFreshBtn:Show()

		
		Anniversary_ExMarket_GetBtn:Hide()
		Anniversary_ExMarket_Refresh1_InfoText:Hide()
		
		
		if g_nRewardLevel == 1 then 
			Anniversary_ExMarket_Lace1_Choose(g_nRewardIndex)
		end
		if g_nRewardLevel == 2 then 
			Anniversary_ExMarket_Lace2_Choose(g_nRewardIndex)
		end
		if g_nRewardLevel == 3 then 
			Anniversary_ExMarket_Lace3_Choose(g_nRewardIndex)
		end
		
	elseif   g_nHuoDongStep == 4 then
		Anniversary_ExMarket_Refresh1_DaibiAImage:Hide()
		Anniversary_ExMarket_Refresh1_DaibiAText:Hide()
		Anniversary_ExMarket_Refresh1_DaibiBText:SetText(ScriptGlobal_Format("#{ZNJS_230220_34}", g_nCoinNum_B))--代币b：%个
		Anniversary_ExMarket_Refresh1_DaibiBText:Show()
		Anniversary_ExMarket_Refresh1_DaibiBImage:Show()

		
		Anniversary_ExMarket_ReFreshBtn:Hide() 
		Anniversary_ExMarket_Refresh1_InfoText:Show()
		Anniversary_ExMarket_GetBtn:Show()		
		if g_nRewardItemRecordNum >= 16 then 
			Anniversary_ExMarket_Refresh1_InfoText:Hide()
		else
			Anniversary_ExMarket_Refresh1_InfoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_50}", g_tCostDaiBiBNumPerTime[g_nRewardItemRecordNum+1])) -- #L每次抽取消耗S0个点书柬  ----todo    
		end
		Anniversary_ExMarket_HideAllChoseFlag() 	--隐藏所有对勾
	elseif   g_nHuoDongStep == 5 then
		Anniversary_ExMarket_Refresh1_DaibiAImage:Hide()
		Anniversary_ExMarket_Refresh1_DaibiAText:Hide()
		Anniversary_ExMarket_Refresh1_DaibiBText:SetText(ScriptGlobal_Format("#{ZNJS_230220_34}", g_nCoinNum_B))--代币b：%个
		Anniversary_ExMarket_Refresh1_DaibiBText:Show()
		Anniversary_ExMarket_Refresh1_DaibiBImage:Show()

		Anniversary_ExMarket_ReFreshBtn:Hide() 
		Anniversary_ExMarket_Refresh1_InfoText:Show()
		Anniversary_ExMarket_GetBtn:Show()		
		if g_nRewardItemRecordNum >= 16 then 
			Anniversary_ExMarket_Refresh1_InfoText:Hide()
		else
			Anniversary_ExMarket_Refresh1_InfoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_50}", g_tCostDaiBiBNumPerTime[g_nRewardItemRecordNum+1])) -- #L每次抽取消耗S0个点书柬  ----todo    
		end
		Anniversary_ExMarket_HideAllChoseFlag() --隐藏所有对勾
	end

	Anniversary_ExMarket_ShuqianClient:Hide()
	Anniversary_ExMarket_DaibiCshare_Tips:Hide()
	if g_nHuoDongStep == 1  then
		if g_nProfileRedPoint == 0 then
			Anniversary_ExMarket_DaibiCshare_Tips:Show()
		end
		Anniversary_ExMarket_Refresh1_GoodsText:SetText(ScriptGlobal_Format("#{ZNJS_230220_33}", g_nHuoWuNum))--代币货物：%个
		Anniversary_ExMarket_Refresh1_GoodsText:Show()
		Anniversary_ExMarket_DaibiCshareBtn:Show() --概况小界面按钮

		Anniversary_ExMarket_Shuqian_PriceText:SetText(ScriptGlobal_Format("#{ZNJS_230220_75}", g_nPriceToday))  -- 今日汇编比率：%s0评书集
		Anniversary_ExMarket_Shuqian_Submit_Text:SetText(ScriptGlobal_Format("#{ZNJS_230220_76}", g_nMaxCanSellGoodsNum - g_nCanSellGoodsNum)) -- 今日已汇编数量：%s0个
		Anniversary_ExMarket_Shuqian_SubmitLeft_Text:SetText(ScriptGlobal_Format("#{ZNJS_230220_77}", g_nCanSellGoodsNum)) -- 今日剩余可汇编数量：%s0个
		Anniversary_ExMarket_Shuqian_SubmitTimes_Text:SetText(ScriptGlobal_Format("#{ZNJS_230220_192}",g_NPCCallLimitTimes -  g_nCurNPCCreateTimes)) 

		--Anniversary_ExMarket_ShareBtn:Show() -- 分享
		--Anniversary_ExMarket_ShareChannelBtn:Show() 
	else
		Anniversary_ExMarket_Refresh1_GoodsImage:Hide()
		Anniversary_ExMarket_Refresh1_GoodsText:Hide()
		Anniversary_ExMarket_DaibiCshareBtn:Hide() --概况小界面按钮
	end
		-- 1 货物获取阶段； 1 + 2 + 3 代币A获取使用阶段；3，开放购买代币A； 4 + 5 代币B获取使用阶段； 5 开放购买代币B
	--花钱买代币
	--三阶段也要在主界面显示代币b的数量和图标，这是一个新的控件，仅在3阶段使用
	if g_nHuoDongStep == 3 then
		Anniversary_ExMarket_Refresh1_DaibiBImage_2:Hide()
		Anniversary_ExMarket_Refresh1_DaibiBText_2:SetText(ScriptGlobal_Format("#{ZNJS_230220_34}", g_nCoinNum_B))--代币b：%个
		Anniversary_ExMarket_Refresh1_DaibiBText_2:Hide()
		Anniversary_ExMarket_DaibiABuyBtn:Show()
	else
		Anniversary_ExMarket_Refresh1_DaibiBImage_2:Hide()
		Anniversary_ExMarket_Refresh1_DaibiBText_2:Hide()
		Anniversary_ExMarket_DaibiABuyBtn:Hide()
	end
	if g_nHuoDongStep == 5 then
		Anniversary_ExMarket_DaibiBBuyBtn:Show()
	else
		Anniversary_ExMarket_DaibiBBuyBtn:Hide()
	end
	Anniversary_ExMarket_LeijiNumbText:SetText(ScriptGlobal_Format("#{ZNJS_230220_194}", g_nCoinTotalCostNum))
			--PushDebugMessage("界面更新2")
	--填充随机出来的奖池
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(133) > 0  then
		g_tRewardInfo = g_tRefreshRewardInfoOfKaJiServer
	elseif 1 == Player:GetData("IsOriginalJD") then
		g_tRewardInfo = g_tRefreshRewardInfoOfOriginalServer
	else
		g_tRewardInfo = g_tRefreshRewardInfo
	end
	
	
	
	-- 大奖池刷新次数
	--PushDebugMessage("大奖池刷新次数 = "..g_nRefreshTimes)
	--if g_nRefreshTimes < g_nRefreshMaxTimes - 1 then
	--		Anniversary_ExMarket_Lace1_LimitBText:SetText(ScriptGlobal_Format("#{ZNJS_230220_185}", g_nRefreshTimes))
	--		Anniversary_ExMarket_Lace1_LimitBText:SetToolTip("#{ZNJS_230220_186}")
	--elseif g_nRefreshTimes == g_nRefreshMaxTimes -1 then

	--		Anniversary_ExMarket_Lace1_LimitBText:SetText("#{ZNJS_230220_187}")
	--		Anniversary_ExMarket_Lace1_LimitBText:SetToolTip("#{ZNJS_230220_188}")
	--elseif g_nRefreshTimes >= g_nRefreshMaxTimes then
	--		Anniversary_ExMarket_Lace1_LimitBText:SetText("#{ZNJS_230220_189}")
	--		Anniversary_ExMarket_Lace1_LimitBText:SetToolTip("")
	--end
	Anniversary_ExMarket_Lace1_LimitBText:Hide() --低保次数  暂时不要了
	
	
	for i=1,4 do
		local tableIndex = g_nRewardItemData[i] --在奖励表里的位置 1-9
		if tableIndex < 1 then
			tableIndex = g_tRandomRewardSaveInfo[1][i].nDefaultIndex
		end
		local ItemId = g_tRewardInfo[1].tRewardPool[tableIndex].nItemID
		local ItemNum = g_tRewardInfo[1].tRewardPool[tableIndex].nItemNum
		local nRare = g_tRewardInfo[1].tRewardPool[tableIndex].nRare
		local bXianLiang= g_tRewardInfo[1].tRewardPool[tableIndex].bUnique 
		local isShizhuang = g_tRewardInfo[1].tRewardPool[tableIndex].isShizhuang
		local itemAction 
		if g_tRewardInfo[1].tRewardPool[tableIndex].bBind == 0 then
			itemAction = DataPool:CreateActionItemForShow(ItemId,ItemNum)
		else
			itemAction = DataPool:CreateBindActionItemForShow(ItemId,ItemNum)
		end
		
		--PushDebugMessage("界面更新GetID="..itemAction:GetID() )
		if itemAction:GetID() ~= 0 then
			g_Lace_Icon[i]:SetActionItem(itemAction:GetID())	
			g_Lace_Icon[i]:Show()
		end
		

		--是否已经随机领取过这个奖品了
		local IsGeted = g_nRewardItemRecordFlag[i]  
		if IsGeted == 0 then
			g_Lace_IconCheck[i]:Hide()
		else
			g_Lace_IconCheck[i]:Show()
		end
	
		--图标右下角显示道具堆叠数量
		g_Lace_IconNum[i]:Hide()
		--g_Lace_IconNum[i]:SetText(ItemNum)	 

		--限量 角标
		--只有第一个池子有时装预览小眼睛
		if bXianLiang ~= 0 then
			--当该奖励为限量道具时，道具图标右上角显示“限”字角标
			g_Lace_IconLimit[i]:Show()
			
		else 
			g_Lace_IconLimit[i]:Hide()
			
		end

		
		if isShizhuang == 1 then
			g_Lace_EyeSign[i]:Show()
		else
			g_Lace_EyeSign[i]:Hide()
		end
		
		--金色流光
		if nRare ~= 0 then
			g_Lace_Animate[i]:Show()
		else
			g_Lace_Animate[i]:Hide()
		end
		
	end
	for i=5,8 do
		local tableIndex = g_nRewardItemData[i] --在奖励表里的位置 1-9
		if tableIndex < 1 then
			tableIndex = g_tRandomRewardSaveInfo[2][i-4].nDefaultIndex
		end
		local ItemId = g_tRewardInfo[2].tRewardPool[tableIndex].nItemID
		local ItemNum = g_tRewardInfo[2].tRewardPool[tableIndex].nItemNum
		local nRare = g_tRewardInfo[2].tRewardPool[tableIndex].nRare
		local bXianLiang= g_tRewardInfo[2].tRewardPool[tableIndex].bUnique 
		local itemAction 
		if g_tRewardInfo[2].tRewardPool[tableIndex].bBind == 0 then
			itemAction = DataPool:CreateActionItemForShow(ItemId,ItemNum)
		else
			itemAction = DataPool:CreateBindActionItemForShow(ItemId,ItemNum)
		end
		
		if itemAction:GetID() ~= 0 then
			g_Lace_Icon[i]:SetActionItem(itemAction:GetID())
			g_Lace_Icon[i]:Show()
		end
		
		--是否已经随机领取过这个奖品了
		local IsGeted = g_nRewardItemRecordFlag[i]  
		if IsGeted == 0 then
			g_Lace_IconCheck[i]:Hide()
		else
			g_Lace_IconCheck[i]:Show()
		end
	
		--图标右下角显示道具堆叠数量
		g_Lace_IconNum[i]:Hide()
		--g_Lace_IconNum[i]:SetText(ItemNum)
		
		--限量 角标
		if bXianLiang ~= 0 then
			--当该奖励为限量道具时，道具图标右上角显示“限”字角标
			g_Lace_IconLimit[i]:Show()
		else 
			g_Lace_IconLimit[i]:Hide()
		end
		
		--金色流光
		if nRare ~= 0 then
			g_Lace_Animate[i]:Show()
		else
			g_Lace_Animate[i]:Hide()
		end
		
	end
	for i=9,16 do
		local tableIndex = g_nRewardItemData[i] --在奖励表里的位置 1-9
		if tableIndex < 1 then
			tableIndex = g_tRandomRewardSaveInfo[3][i-8].nDefaultIndex
		end
		local ItemId = g_tRewardInfo[3].tRewardPool[tableIndex].nItemID
		local ItemNum = g_tRewardInfo[3].tRewardPool[tableIndex].nItemNum
		local bXianLiang= g_tRewardInfo[3].tRewardPool[tableIndex].bUnique 
		local itemAction 
		if g_tRewardInfo[3].tRewardPool[tableIndex].bBind == 0 then
			itemAction = DataPool:CreateActionItemForShow(ItemId,ItemNum)
		else
			itemAction = DataPool:CreateBindActionItemForShow(ItemId,ItemNum)
		end
		
		if itemAction:GetID() ~= 0 then
			g_Lace_Icon[i]:SetActionItem(itemAction:GetID())
			g_Lace_Icon[i]:Show()
		end
		
		--是否已经随机领取过这个奖品了
		local IsGeted = g_nRewardItemRecordFlag[i]  
		if IsGeted == 0 then
			g_Lace_IconCheck[i]:Hide()
		else
			g_Lace_IconCheck[i]:Show()
		end
	
		--图标右下角显示道具堆叠数量
		g_Lace_IconNum[i]:Hide()
		--g_Lace_IconNum[i]:SetText(ItemNum)	
		
		--限量 角标
		if bXianLiang ~= 0 then
			--当该奖励为限量道具时，道具图标右上角显示“限”字角标
			g_Lace_IconLimit[i]:Show()
		else 
			g_Lace_IconLimit[i]:Hide()
		end
	end
	
	--累计领奖部分
		g_Button[1]: SetToolTip("#{ZNJS_230220_52}")
		g_Button[2]: SetToolTip("#{ZNJS_230220_53}")
		g_Button[3]: SetToolTip("#{ZNJS_230220_54}")
		g_Button[4]: SetToolTip("#{ZNJS_230220_55}")
		g_Button[5]: SetToolTip("#{ZNJS_230220_56}")
		g_Button[6]: SetToolTip("#{ZNJS_230220_139}")
		Anniversary_ExMarket_IconText1:SetText("#M"..g_tTotalCostRewardInfo[1].nNeedCostDaiBiNum)	
		Anniversary_ExMarket_IconText2:SetText("#M"..g_tTotalCostRewardInfo[2].nNeedCostDaiBiNum)	
		Anniversary_ExMarket_IconText3:SetText("#M"..g_tTotalCostRewardInfo[3].nNeedCostDaiBiNum)	
		Anniversary_ExMarket_IconText4:SetText("#M"..g_tTotalCostRewardInfo[4].nNeedCostDaiBiNum)	
		Anniversary_ExMarket_IconText5:SetText("#M"..g_tTotalCostRewardInfo[5].nNeedCostDaiBiNum)
		Anniversary_ExMarket_IconText6:SetText("#M"..g_tTotalCostRewardInfo[6].nNeedCostDaiBiNum)		
		


	for i = 1, 6 do   
		if g_nCoinTotalCostNum < g_tTotalCostRewardInfo[i].nNeedCostDaiBiNum and g_nLeiJiRewardRecordFlag[i] == 0 then
			--不够领
			
			g_Button[i]: SetProperty("NormalImage", "set:Anniversary_Exmarket01 image:BoxS_Normal")
			g_Button[i]: SetProperty("HoverImage", "set:Anniversary_Exmarket01 image:BoxS_Hover")
			g_Button[i]: SetProperty("PushedImage", "set:Anniversary_Exmarket01 image:BoxS_Pushed")
			g_Button[i]: SetProperty("DisabledImage", "set:Anniversary_Exmarket01 image:BoxS_Disabled")
			g_Icon_Tips[i]:Hide()
			
		end
		if g_nCoinTotalCostNum >= g_tTotalCostRewardInfo[i].nNeedCostDaiBiNum and g_nLeiJiRewardRecordFlag[i] == 0 then
			--可以领 红点+宝箱打开
			g_Button[i]: SetProperty("NormalImage", "set:Anniversary_Exmarket01 image:BoxS_Normal")
			g_Button[i]: SetProperty("HoverImage", "set:Anniversary_Exmarket01 image:BoxS_Hover")
			g_Button[i]: SetProperty("PushedImage", "set:Anniversary_Exmarket01 image:BoxS_Pushed")
			g_Button[i]: Enable()
			g_Icon_Tips[i]:Show()

		end
		if g_nLeiJiRewardRecordFlag[i] ~= 0  then
			--领过了
			g_Button[i]:SetToolTip("")
			g_Button[i]: SetProperty("NormalImage", "set:Anniversary_Exmarket01 image:BoxS_Disabled")
			g_Button[i]: SetProperty("HoverImage", "set:Anniversary_Exmarket01 image:BoxS_Disabled")
			g_Button[i]: SetProperty("PushedImage", "set:Anniversary_Exmarket01 image:BoxS_Disabled")
			g_Button[i]: SetProperty("DisabledImage", "set:Anniversary_Exmarket01 image:BoxS_Disabled")
			--g_Button[i]: Disable()
			g_Icon_Tips[i]:Hide()
		end

	end
	
	--进度条相关
	Anniversary_ExMarket_ProgressBar:SetProgress(tonumber(g_nCoinTotalCostNum), 80)
	
	
	
	PushEvent( "MESSAGE_BOX_SELF3_CLOSE" )
	Anniversary_ExMarket_DaibiBuyClient:Hide()

end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Anniversary_ExMarket_Reset()
	for i = 1, 5 do
		g_nLeiJiRewardRecord[i] = 0
	end
	g_nCoinTotalCostNum = 0
	g_nCoinTotalCostNum_b = 0
	g_nCoinNum_A = 0 
	g_nCoinNum_B = 0 
	g_nHuoWuNum = 0 
	g_nPriceToday = 0 
	g_nRefreshRewardMD1 = 0
	g_nRefreshRewardMD2 = 0
	g_nHuoDongStep = 0
	g_nRewardItemRecordNum = 0
	g_nCurNPCCreateTimes = 0
	g_nProfileRedPoint = 0
	g_nCanSellGoodsNum = 0
	g_nBuyDaiBiNum = 0
	g_nBuyDaiBiType = 0
	g_nRewardItemData = {}
	g_nRewardItemRecordFlag = {}
	g_nLeiJiRewardRecordFlag = {}
	for i=1,16 do
		g_ChoseFlag[i]:Hide()
	end
	
	PushEvent( "MESSAGE_BOX_SELF3_CLOSE" )
	Anniversary_ExMarket_DaibiBuyClient:Hide()
end


--=========================================================
-- 领取令牌
--=========================================================
function Anniversary_ExMarket_GotoClick()	
	--寻路到npc处
	AutoRuntoTargetExWithName(270,260, 0, "季闲云")
end

--=========================================================
-- 选中奖池中的一个奖励 准备刷新
--=========================================================
function Anniversary_ExMarket_Lace1_Choose(param)
	--PushDebugMessage("准备刷新="..param)
	if g_nHuoDongStep ~= 1 and g_nHuoDongStep ~= 2 and g_nHuoDongStep ~= 3 then
		return 
	end
	Anniversary_ExMarket_HideAllChoseFlag()
	g_ChoseFlag[param]:Show()
	g_nRewardLevel = 1
	g_nRewardIndex = param
	Anniversary_ExMarket_Refresh1_InfoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_48}", g_tRefreshRewardInfo[1].nCostDaiBiNum)) -- #L每次刷新消耗%s0评书集 
	Anniversary_ExMarket_Refresh1_InfoText:Show()
end
function Anniversary_ExMarket_Lace2_Choose(param)
	if g_nHuoDongStep ~= 1 and g_nHuoDongStep ~= 2 and g_nHuoDongStep ~= 3 then
		return 
	end
	Anniversary_ExMarket_HideAllChoseFlag()
	g_ChoseFlag[param + 4]:Show()
	g_nRewardLevel = 2
	g_nRewardIndex = param
	Anniversary_ExMarket_Refresh1_InfoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_48}", g_tRefreshRewardInfo[2].nCostDaiBiNum)) -- #L每次刷新消耗%s0评书集 
	Anniversary_ExMarket_Refresh1_InfoText:Show()
end
function Anniversary_ExMarket_Lace3_Choose(param)
	if g_nHuoDongStep ~= 1 and g_nHuoDongStep ~= 2 and g_nHuoDongStep ~= 3  then
		return 
	end
	Anniversary_ExMarket_HideAllChoseFlag()
	g_ChoseFlag[param + 4 + 4]:Show()
	g_nRewardLevel = 3
	g_nRewardIndex = param
	Anniversary_ExMarket_Refresh1_InfoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_48}", g_tRefreshRewardInfo[3].nCostDaiBiNum)) -- #L每次刷新消耗%s0评书集 
	Anniversary_ExMarket_Refresh1_InfoText:Show()
end

--=========================================================
-- 隐藏对勾
--=========================================================
function Anniversary_ExMarket_HideAllChoseFlag()
	for i=1,16 do
		g_ChoseFlag[i]:Hide()
	end
end


--=========================================================
-- 奖励刷新 主界面点第一下
--=========================================================
function Anniversary_ExMarket_ReFreshClick(param)	

	if(IsWindowShow("Anniversary_ExMarket_Refresh")) then 
		--请先进行替换界面的操作后再进行刷新。
		PushDebugMessage("#{ZNJS_230220_196}")  
		return
	end
	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRecMessage" )
		Set_XSCRIPT_ScriptID(g_nMyScriptId)	
		Set_XSCRIPT_Parameter(0, 11) --ntype
		Set_XSCRIPT_Parameter(1, g_nRewardLevel)
		Set_XSCRIPT_Parameter(2, g_nRewardIndex)	
		Set_XSCRIPT_Parameter(3, 1)	--现在的逻辑是这个地方不走二次确认了			
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()

end
--=========================================================
-- 最后阶段随机领取一个奖励
--=========================================================
function Anniversary_ExMarket_ReFresh_GetClick()	
	--if g_nCoinNum_B > 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)
			Set_XSCRIPT_Parameter(0, 12) --ntype			
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	--end 
end


--=========================================================
-- 奖池预览
--=========================================================
function Anniversary_ExMarket_IntroClick(param)	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)
			Set_XSCRIPT_Parameter(0, 15) --ntype			
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
end

--=========================================================
-- 累计消耗领奖
--=========================================================
function Anniversary_ExMarket_Leiji_GetAward(param)	
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)
			Set_XSCRIPT_Parameter(0, 14) --ntype			
			Set_XSCRIPT_Parameter(1, param)			
			Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
--=========================================================
-- 帮助
--=========================================================
function Anniversary_ExMarket_Intro_ShowHelp()

	-- 借用一下别人的通道
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(133) > 0 then 
		PushEvent("CCSHOP_HELP", 185)
	else
		PushEvent("CCSHOP_HELP", 184)
	end
end

--=========================================================
-- 主界面购买按钮
--=========================================================
function Anniversary_ExMarket_ReFresh_DaibiBuyClick()
	--买代币a
	if g_nHuoDongStep == 3 then
		Anniversary_ExMarket_Refresh1_DaibiBuy_HaveText:SetText(ScriptGlobal_Format("#{ZNJS_230220_132}", g_nCoinTotalCostNum + g_nCoinNum_A ))  -- 已获得：%s0
		local num = g_DaiBiALimit - g_nCoinTotalCostNum - g_nCoinNum_A
		if num < 0 then
			num = 0
		end
		Anniversary_ExMarket_Refresh1_DaibiBuy_LeftText:SetText(ScriptGlobal_Format("#{ZNJS_230220_133}", num)) -- 还可购买：%s0
		Anniversary_ExMarket_Refresh1_DaibiBuy_PriceText:SetText(ScriptGlobal_Format("#{ZNJS_230220_134}", g_DaiBiAPrice ))  -- 价格：%s0
		Anniversary_ExMarket_Refresh1_DaibiBuy_NeedYuanbaoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_137}", g_DaiBiAPrice*1 ))  -- 需要元宝：%s0
		
		--展示道具
		local theAction_Fashion = DataPool:CreateActionItemForShow(39924250, 1)
		if theAction_Fashion:GetID() ~= 0 then
			Anniversary_ExMarket_DaibiBuy_Item:SetActionItem(theAction_Fashion:GetID());  
			Anniversary_ExMarket_DaibiBuy_Item:Show(); 										
			Anniversary_ExMarket_Refresh1_DaibiBuy_ItemName:SetText("#cfff263"..theAction_Fashion:GetName())
			--Anniversary_ExMarket_Refresh1_DaibiBuy_ItemName:SetText(theAction_Fashion:GetName())
		end
	
	end
	--买代币b
	if g_nHuoDongStep == 5 then
		Anniversary_ExMarket_Refresh1_DaibiBuy_HaveText:SetText(ScriptGlobal_Format("#{ZNJS_230220_132}", g_nCoinTotalCostNum_b + g_nCoinNum_B ))  -- 已获得：%s0
		local num = g_DaiBiBLimit - g_nCoinTotalCostNum_b - g_nCoinNum_B 
		if num < 0 then
			num = 0
		end
		Anniversary_ExMarket_Refresh1_DaibiBuy_LeftText:SetText(ScriptGlobal_Format("#{ZNJS_230220_133}",num )) -- 还可购买：%s0
		Anniversary_ExMarket_Refresh1_DaibiBuy_PriceText:SetText(ScriptGlobal_Format("#{ZNJS_230220_134}", g_DaiBiBPrice ))  -- 价格：%s0
		Anniversary_ExMarket_Refresh1_DaibiBuy_NeedYuanbaoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_137}", g_DaiBiBPrice*1 ))  -- 需要元宝：%s0
	
		--展示道具
		local theAction_Fashion = DataPool:CreateActionItemForShow(39924251, 1)
		if theAction_Fashion:GetID() ~= 0 then
			Anniversary_ExMarket_DaibiBuy_Item:SetActionItem(theAction_Fashion:GetID());  
			Anniversary_ExMarket_DaibiBuy_Item:Show(); 										 
			Anniversary_ExMarket_Refresh1_DaibiBuy_ItemName:SetText("#cfff263"..theAction_Fashion:GetName())
			--Anniversary_ExMarket_Refresh1_DaibiBuy_ItemName:SetText(theAction_Fashion:GetName())
		end	
	end
	Anniversary_ExMarket_Refresh1_DaibiBuy_HaveYuanbaoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_138}", tostring(Player:GetData("YUANBAO")) ))  -- 拥有元宝：%s0	
	
	Anniversary_ExMarket_DaibiBuy_InputNum:SetProperty("DefaultEditBox", "True");--设置输入框为默认输入框
	Anniversary_ExMarket_DaibiBuy_InputNum:SetText(tostring(1))	--默认输入为1
	Anniversary_ExMarket_DaibiBuy_InputNum:SetSelected( 0, -1 );
	Anniversary_ExMarket_DaibiBuyClient:Show()

end
--=========================================================
-- 购买界面 确认 取消
--=========================================================
function Anniversary_ExMarket_DaibiBBuy_GetClick(param)
	if param == 1 then
		--确认
		local count = tonumber(Anniversary_ExMarket_DaibiBuy_InputNum:GetText())
		if  count == nil or count <= 0 then
			return
		end 
		if  g_nHuoDongStep ~= 3 and  g_nHuoDongStep ~= 5 then
			PushDebugMessage("#{ZNJS_230220_142}")
			return
		end
		--买代币a
		if g_nHuoDongStep == 3 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnRecMessage" )
				Set_XSCRIPT_ScriptID(g_nMyScriptId)
				Set_XSCRIPT_Parameter(0, 16)		
				Set_XSCRIPT_Parameter(1, count)			
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
		--买代币b
		if g_nHuoDongStep == 5 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnRecMessage" )
				Set_XSCRIPT_ScriptID(g_nMyScriptId)
				Set_XSCRIPT_Parameter(0, 17)		
				Set_XSCRIPT_Parameter(1, count)			
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
	end 
	--取消
	Anniversary_ExMarket_DaibiBuyClient:Hide()
end
--=========================================================
-- 购买界面 x
--=========================================================
function Anniversary_ExMarket_DaibiBuy_Close_Clicked() 
	Anniversary_ExMarket_DaibiBuyClient:Hide()
end


--=========================================================
-- 买代币的 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function Anniversary_ExMarket_OnBuyDaibiComfirmedBack(strRet)
	--PushDebugMessage(" for 主界面 点击替换稀有物品的按钮")
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnRecMessage")
			Set_XSCRIPT_ScriptID(998437)
			Set_XSCRIPT_Parameter(0,18)
			Set_XSCRIPT_Parameter(1,g_nBuyDaiBiType)
			Set_XSCRIPT_Parameter(2,g_nBuyDaiBiNum)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		-- 关闭二次确认框就行，返回主界面
	end
end

--=========================================================
-- 召唤NPC 的 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function Anniversary_ExMarket_OnCallNPCComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)	
			Set_XSCRIPT_Parameter(0, 10) --ntype
			Set_XSCRIPT_Parameter(1, 1) --不是首次点击，二次确认
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		-- 关闭二次确认框就行，返回主界面
	end
end



--=========================================================
-- 购买界面 最大
--=========================================================
function Anniversary_ExMarket_DaibiBBuy_MaxClick()
	local num = 0 
	local haveYuanBao = Player:GetData("YUANBAO")
	if g_nHuoDongStep == 3 then 
		num = g_DaiBiALimit - g_nCoinTotalCostNum - g_nCoinNum_A
		if g_DaiBiAPrice <= 0 then
			return 
		end
		local canBuyNum = math.floor(haveYuanBao / g_DaiBiAPrice)
		if canBuyNum < num then
			num = canBuyNum
		end
	end
	if g_nHuoDongStep == 5 then 
		num = g_DaiBiBLimit - g_nCoinTotalCostNum_b - g_nCoinNum_B
		if g_DaiBiBPrice <= 0 then
			return 
		end
		local canBuyNum = math.floor(haveYuanBao / g_DaiBiBPrice)
		if canBuyNum < num then
			num = canBuyNum
		end
	end
	
	if num > 0  then
		Anniversary_ExMarket_DaibiBuy_InputNum:SetText(tostring(num))
	end
		
end

--=========================================================
-- TextChange 
--=========================================================
function Anniversary_ExMarket_DaibiBuy_TextChanged()
	local count = tonumber(Anniversary_ExMarket_DaibiBuy_InputNum:GetText())

	if count == nil then
		count = 0 
	end
	local haveYuanBao = Player:GetData("YUANBAO")

	if g_nHuoDongStep == 3 then  
		Anniversary_ExMarket_Refresh1_DaibiBuy_NeedYuanbaoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_137}", g_DaiBiAPrice * count ))  -- 需要元宝：%s0
	end
	if g_nHuoDongStep == 5 then  
		Anniversary_ExMarket_Refresh1_DaibiBuy_NeedYuanbaoText:SetText(ScriptGlobal_Format("#{ZNJS_230220_137}", g_DaiBiBPrice * count ))  -- 需要元宝：%s0
	end
	Anniversary_ExMarket_Refresh1_DaibiBuy_NeedYuanbaoText:Show()
	
	--Anniversary_ExMarket_DaibiBuy_InputNum:SetProperty("DefaultEditBox", "True");--设置输入框为默认输入框
end




--=========================================================
-- 时装预览
--=========================================================
function Anniversary_ExMarket_Lace1_ViewClick(param)
	if param > 4 or param < 1 then
		return 
	end
	local itemIndex = g_nRewardItemData[param]
	if itemIndex == 0 then
		itemIndex = g_tRandomRewardSaveInfo[1][param].nDefaultIndex
	end
	local itemId = g_tRewardInfo[1].tRewardPool[itemIndex].nItemID
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRecMessage" )
		Set_XSCRIPT_ScriptID(g_nMyScriptId)
		Set_XSCRIPT_Parameter(0, 19)		
		Set_XSCRIPT_Parameter(1, itemId)			
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

--=========================================================
-- 分享click
--=========================================================
function Anniversary_ExMarket_ShareClick()	
	local __txt, id = Anniversary_ExMarket_ShareBtn:GetCurrentSelect();
	--10s冷却时间 每个分享渠道单独计时
	local curTime = OSAPI:GetTickCount();
	if id == 0 then
		if ( curTime - g_LastShareTime_1 < g_ShareCD ) then
			PushDebugMessage("#{ZNJS_230220_184}"); 
			return;
		end
		g_LastShareTime_1 = curTime
	elseif id == 1 then
		if ( curTime - g_LastShareTime_2 < g_ShareCD ) then
			PushDebugMessage("#{ZNJS_230220_184}"); 
			return;
		end
		g_LastShareTime_2 = curTime
	elseif id == 2 then
		if ( curTime - g_LastShareTime_3 < g_ShareCD ) then
			PushDebugMessage("#{ZNJS_230220_184}"); 
			return;
		end
		g_LastShareTime_3 = curTime
	elseif id == 3 then
		if ( curTime - g_LastShareTime_4 < g_ShareCD ) then
			PushDebugMessage("#{ZNJS_230220_184}"); 
			return;
		end
		g_LastShareTime_4 = curTime
	end


	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)	
			Set_XSCRIPT_Parameter(0, 13) --ntype
			Set_XSCRIPT_Parameter(1, id)			
			Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end


--=========================================================
-- 分享选择
--=========================================================
function Anniversary_ExMarket_ShareChanged()	

end

--=========================================================
-- 分享add选择
--=========================================================
function Anniversary_ExMarket_ShareAddItem()
		Anniversary_ExMarket_ShareBtn:ComboBoxAddItem( "附近", 0);--附近
		Anniversary_ExMarket_ShareBtn:ComboBoxAddItem( "世界", 1);--世界
		Anniversary_ExMarket_ShareBtn:ComboBoxAddItem( "帮会", 2);--帮会
		Anniversary_ExMarket_ShareBtn:SetCurrentSelect(0) --默认附近
end



--=========================================================
-- 概况界面
--=========================================================
function Anniversary_ExMarket_OpenProfile()	
	Anniversary_ExMarket_ShuqianClient:Show()
	Anniversary_ExMarket_DaibiCshare_Tips:Hide()
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)	
			Set_XSCRIPT_Parameter(0, 35) --ntype			
			Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--=========================================================
-- 召唤售卖npc
--=========================================================
function Anniversary_ExMarket_Shuqian_SummonClick(param)
	if param == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)	
			Set_XSCRIPT_Parameter(0, 10) --ntype
			Set_XSCRIPT_Parameter(1, 0) --首次点击
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
	if param == 2 then
		Anniversary_ExMarket_ShuqianClient:Hide()
	end
end

--=========================================================
-- 概况界面 x
--=========================================================
function Anniversary_ExMarket_Shuqian_Close_Clicked()
	Anniversary_ExMarket_ShuqianClient:Hide()
end
--=========================================================
-- 概况界面的 问号
--=========================================================
function Anniversary_ExMarket_DaibiCshare_ShowHelp()	
	PushEvent("CCSHOP_HELP", 192) --卡级服常规服用一个
end



--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_ExMarket_Close()	

	-- 重置
	this:Hide()
	Anniversary_ExMarket_Reset()
	
end

--=========================================================
-- 界面位置
--=========================================================
function Anniversary_ExMarket_Frame_On_ResetPos()
	Anniversary_ExMarket:SetProperty("UnifiedPosition", g_Anniversary_ExMarket_Frame_UnifiedPosition)
end
