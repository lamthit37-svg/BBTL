--  周年庆刷新集市 客户端脚本
--奖池预览 仅仅打开展示，别的啥也不做

local g_Anniversary_ExMarket_Reward_Frame_UnifiedPosition
local g_RewardPool_1={}
local g_RewardPool_2={}
local g_RewardPool_3={}
local g_nUICommandID = 99843701
-- 奖励总信息
local g_tRewardInfo	
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


--=========================================================
-- PreLoad
--=========================================================
function Anniversary_ExMarket_Reward_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
end


--=========================================================
-- OnLoad
--=========================================================
function Anniversary_ExMarket_Reward_OnLoad()
	g_Anniversary_ExMarket_Reward_Frame_UnifiedPosition =  Anniversary_ExMarket_Reward_Frame:GetProperty("UnifiedPosition")
	
	--这部分是倒序 策划要求逆向展示道具
	g_RewardPool_1[1] = Anniversary_ExMarket_Reward_List1_RewardItem14
	g_RewardPool_1[2] = Anniversary_ExMarket_Reward_List1_RewardItem13
	g_RewardPool_1[3] = Anniversary_ExMarket_Reward_List1_RewardItem12 
	g_RewardPool_1[4] = Anniversary_ExMarket_Reward_List1_RewardItem11 
	g_RewardPool_1[5] = Anniversary_ExMarket_Reward_List1_RewardItem10 
	g_RewardPool_1[6] = Anniversary_ExMarket_Reward_List1_RewardItem9 
	g_RewardPool_1[7] = Anniversary_ExMarket_Reward_List1_RewardItem8 
	g_RewardPool_1[8] = Anniversary_ExMarket_Reward_List1_RewardItem7 
	g_RewardPool_1[9] = Anniversary_ExMarket_Reward_List1_RewardItem6 
	g_RewardPool_1[10] = Anniversary_ExMarket_Reward_List1_RewardItem5 
	g_RewardPool_1[11] = Anniversary_ExMarket_Reward_List1_RewardItem4 
	g_RewardPool_1[12] = Anniversary_ExMarket_Reward_List1_RewardItem3
	g_RewardPool_1[13] = Anniversary_ExMarket_Reward_List1_RewardItem2 
	g_RewardPool_1[14] = Anniversary_ExMarket_Reward_List1_RewardItem1 
	
	g_RewardPool_2[1] = Anniversary_ExMarket_Reward_List2_RewardItem13
	g_RewardPool_2[2] = Anniversary_ExMarket_Reward_List2_RewardItem12
	g_RewardPool_2[3] = Anniversary_ExMarket_Reward_List2_RewardItem11
	g_RewardPool_2[4] = Anniversary_ExMarket_Reward_List2_RewardItem10
	g_RewardPool_2[5] = Anniversary_ExMarket_Reward_List2_RewardItem9 
	g_RewardPool_2[6] = Anniversary_ExMarket_Reward_List2_RewardItem8 
	g_RewardPool_2[7] = Anniversary_ExMarket_Reward_List2_RewardItem7
	g_RewardPool_2[8] = Anniversary_ExMarket_Reward_List2_RewardItem6 
	g_RewardPool_2[9] = Anniversary_ExMarket_Reward_List2_RewardItem5 
	g_RewardPool_2[10] = Anniversary_ExMarket_Reward_List2_RewardItem4 
	g_RewardPool_2[11] = Anniversary_ExMarket_Reward_List2_RewardItem3 
	g_RewardPool_2[12] = Anniversary_ExMarket_Reward_List2_RewardItem2 
	g_RewardPool_2[13] = Anniversary_ExMarket_Reward_List2_RewardItem1 
	
	g_RewardPool_3[1] = Anniversary_ExMarket_Reward_List3_RewardItem11
	g_RewardPool_3[2] = Anniversary_ExMarket_Reward_List3_RewardItem10
	g_RewardPool_3[3] = Anniversary_ExMarket_Reward_List3_RewardItem9
	g_RewardPool_3[4] = Anniversary_ExMarket_Reward_List3_RewardItem8 
	g_RewardPool_3[5] = Anniversary_ExMarket_Reward_List3_RewardItem7 
	g_RewardPool_3[6] = Anniversary_ExMarket_Reward_List3_RewardItem6 
	g_RewardPool_3[7] = Anniversary_ExMarket_Reward_List3_RewardItem5 
	g_RewardPool_3[8] = Anniversary_ExMarket_Reward_List3_RewardItem1    --特地调整到第一个
	g_RewardPool_3[9] = Anniversary_ExMarket_Reward_List3_RewardItem4 
	g_RewardPool_3[10] = Anniversary_ExMarket_Reward_List3_RewardItem3 
	g_RewardPool_3[11] = Anniversary_ExMarket_Reward_List3_RewardItem2            
	
end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_ExMarket_Reward_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(133) > 0 then 
			g_tRewardInfo = g_tRefreshRewardInfoOfKaJiServer
		elseif 1 == Player:GetData("IsOriginalJD") then
			g_tRewardInfo = g_tRefreshRewardInfoOfOriginalServer
		else
			g_tRewardInfo = g_tRefreshRewardInfo
		end

		for i=1 , 14 do
			local itemAction
			if g_tRewardInfo[1].tRewardPool[i].bBind == 0 then
				--展示未绑定的图标
				itemAction = DataPool:CreateActionItemForShow(g_tRewardInfo[1].tRewardPool[i].nItemID,g_tRewardInfo[1].tRewardPool[i].nItemNum)
			else
				--展示绑定的图标
				itemAction = DataPool:CreateBindActionItemForShow(g_tRewardInfo[1].tRewardPool[i].nItemID,g_tRewardInfo[1].tRewardPool[i].nItemNum)
			end

			if itemAction:GetID() ~= 0 then
				g_RewardPool_1[i]:SetActionItem(itemAction:GetID())
				g_RewardPool_1[i]:Show()
			end
		end
		
		for i=1 , 13 do
			local itemAction
			if g_tRewardInfo[2].tRewardPool[i].bBind == 0 then
				--展示未绑定的图标
				itemAction = DataPool:CreateActionItemForShow(g_tRewardInfo[2].tRewardPool[i].nItemID,g_tRewardInfo[2].tRewardPool[i].nItemNum)
			else
				--展示绑定的图标
				itemAction = DataPool:CreateBindActionItemForShow(g_tRewardInfo[2].tRewardPool[i].nItemID,g_tRewardInfo[2].tRewardPool[i].nItemNum)
			end
			if itemAction:GetID() ~= 0 then
				g_RewardPool_2[i]:SetActionItem(itemAction:GetID())
				g_RewardPool_2[i]:Show()
			end
		end
		
		for i=1 , 11 do
			local itemAction
			if g_tRewardInfo[3].tRewardPool[i].bBind == 0 then
				--展示未绑定的图标
				itemAction = DataPool:CreateActionItemForShow(g_tRewardInfo[3].tRewardPool[i].nItemID,g_tRewardInfo[3].tRewardPool[i].nItemNum)
			else
				--展示绑定的图标
				itemAction = DataPool:CreateBindActionItemForShow(g_tRewardInfo[3].tRewardPool[i].nItemID,g_tRewardInfo[3].tRewardPool[i].nItemNum)
			end
			if itemAction:GetID() ~= 0 then
				g_RewardPool_3[i]:SetActionItem(itemAction:GetID())
				g_RewardPool_3[i]:Show()
			end
		end

		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		--切换场景关闭界面
		Anniversary_ExMarket_Reward_Close()	
		
	elseif (event == "ADJEST_UI_POS" ) then
		Anniversary_ExMarket_Reward_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_ExMarket_Reward_Frame_On_ResetPos()
	end

end

--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_ExMarket_Reward_Close()
	this:Hide()
end

--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_ExMarket_Reward_OnHiden()
	this:Hide()
end


--=========================================================
-- 界面位置
--=========================================================
function Anniversary_ExMarket_Reward_Frame_On_ResetPos()
	Anniversary_ExMarket_Reward_Frame:SetProperty("UnifiedPosition", g_Anniversary_ExMarket_Reward_Frame_UnifiedPosition)
end
