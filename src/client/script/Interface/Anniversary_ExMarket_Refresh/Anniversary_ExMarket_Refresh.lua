--  周年庆刷新集市 客户端脚本
--刷新奖励交换界面

local g_nMyScriptId = 998437
local g_nRewardLevel = 0 
local g_nRewardIndex = 0 
local g_nCurRewardTableID = 0 
local g_nNewRewardTableID =0 
local g_Anniversary_ExMarket_Refresh_Frame_UnifiedPosition
local g_nUICommandID		= 79009002  
local g_nComfirmUICommandID		= 79009005  


-- 奖励总信息
local g_tRewardInfo	={}
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
function Anniversary_ExMarket_Refresh_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("RELIVE_SHOW",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	
end


--=========================================================
-- OnLoad
--=========================================================
function Anniversary_ExMarket_Refresh_OnLoad()
	g_Anniversary_ExMarket_Refresh_Frame_UnifiedPosition =  Anniversary_ExMarket_Refresh_Frame_BK:GetProperty("UnifiedPosition")
	
	g_nRewardLevel = 0 
	g_nRewardIndex = 0 
	g_nCurRewardTableID = 0 
	g_nNewRewardTableID =0 
end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_ExMarket_Refresh_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开
		local nOpType 	= Get_XParam_INT(0)

		--PushDebugMessage("UI_COMMAND nOpType"..nOpType)
		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				Anniversary_ExMarket_Refresh_OnHide()	
			end
		end
		-- 打开界面
		if 1 == nOpType then
			--PushDebugMessage("打开界面")

			Anniversary_ExMarket_Refresh_Reset()
			Anniversary_ExMarket_Refresh_ParamInit()
			
			if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(133) > 0 then 
				g_tRewardInfo = g_tRefreshRewardInfoOfKaJiServer
			elseif 1 == Player:GetData("IsOriginalJD") then
				g_tRewardInfo = g_tRefreshRewardInfoOfOriginalServer
			else
				g_tRewardInfo = g_tRefreshRewardInfo
			end

			--原来的道具
			local ItemIndex = g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nCurRewardTableID].nItemID
			local ItemNum =  g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nCurRewardTableID].nItemNum
			local nRare = g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nCurRewardTableID].nRare
			local bXianLiang = g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nCurRewardTableID].bUnique
			local isShizhuang =  g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nCurRewardTableID].isShizhuang
			local itemAction 
			if g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nCurRewardTableID].bBind then
				itemAction = DataPool:CreateBindActionItemForShow(ItemIndex, ItemNum)
			else
				itemAction = DataPool:CreateActionItemForShow(ItemIndex, ItemNum)
			end
			
			if itemAction:GetID() ~= 0 then
				Anniversary_ExMarket_Refresh_Item1:SetActionItem(itemAction:GetID())
			end
			--道具名字
			-- Anniversary_ExMarket_Refresh_Page_Item1_Tip:SetText("#cfff263"..itemAction:GetName())
			Anniversary_ExMarket_Refresh_Page_Item1_Tip:SetText(itemAction:GetName())


			--稀有金色流光
			if nRare ~= 0 then
				--当该奖励为表格中的稀有奖励时，道具周边出现金色流光
				Anniversary_ExMarket_Refresh_Item1_Animate:Show()
			else
				Anniversary_ExMarket_Refresh_Item1_Animate:Hide()
			end
			--图标右下角显示道具堆叠数量
			--Anniversary_ExMarket_Refresh_Item1_Num:SetText(ItemNum)

				
			--限量 角标 +时装预览小眼睛
			Anniversary_ExMarket_Refresh_Item1_EyeSign:Hide()
			Anniversary_ExMarket_Refresh_Item1Mark:Hide()
			if bXianLiang ~= 0 then
				--当该奖励为限量道具时，道具图标右上角显示“限”字角标
				Anniversary_ExMarket_Refresh_Item1Mark:Show()
			end
			
			if isShizhuang == 1 then
				if g_nRewardLevel == 1 then
					--只有第一个池子有时装预览小眼睛
					Anniversary_ExMarket_Refresh_Item1_EyeSign:Show()
				end
			else
				Anniversary_ExMarket_Refresh_Item1_EyeSign:Hide()
			end
		
		
			
			--新刷的道具
			local ItemIndex2 = g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nNewRewardTableID].nItemID
			local ItemNum2 	 = g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nNewRewardTableID].nItemNum
			local nRare2 = g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nNewRewardTableID].nRare
			local bXianLiang2 = g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nNewRewardTableID].bUnique
			local isShizhuang2=g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nNewRewardTableID].isShizhuang
			local itemAction2 
			if g_tRewardInfo[g_nRewardLevel].tRewardPool[g_nNewRewardTableID].bBind ~= 0  then
				itemAction2 = DataPool:CreateBindActionItemForShow(ItemIndex2, ItemNum2)
			else
				itemAction2 = DataPool:CreateActionItemForShow(ItemIndex2, ItemNum2)
			end
			if itemAction2:GetID() ~= 0 then
				Anniversary_ExMarket_Refresh_Item2:SetActionItem(itemAction2:GetID())
			end
			--道具名字
			-- Anniversary_ExMarket_Refresh_Page_Item2_Tip:SetText("#cfff263"..itemAction2:GetName())
			Anniversary_ExMarket_Refresh_Page_Item2_Tip:SetText(itemAction2:GetName())
			--稀有金色流光
			if  nRare2 ~= 0 then
				--当该奖励为表格中的稀有奖励时，道具周边出现金色流光
				Anniversary_ExMarket_Refresh_Item2_Animate:Show()
			else
				Anniversary_ExMarket_Refresh_Item2_Animate:Hide()
			end
			--图标右下角显示道具堆叠数量
			--Anniversary_ExMarket_Refresh_Item2_Num:SetText(ItemNum2)

			--限量 角标 +时装预览小眼睛
			Anniversary_ExMarket_Refresh_Item2_EyeSign:Hide()
			Anniversary_ExMarket_Refresh_Item2Mark:Hide()
			if bXianLiang2 ~= 0 then
				--当该奖励为限量道具时，道具图标右上角显示“限”字角标

				Anniversary_ExMarket_Refresh_Item2Mark:Show()
			end
				
			if isShizhuang2 == 1 then
				if g_nRewardLevel == 1 then
					--只有第一个池子有时装预览小眼睛
					Anniversary_ExMarket_Refresh_Item2_EyeSign:Show()
				end
			else
				Anniversary_ExMarket_Refresh_Item2_EyeSign:Hide()
			end
			
			
			this:Show()
		end
	end
		
	-- 二次确认框
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nComfirmUICommandID ) then
		local strMsg = Get_XParam_STR(0)
		local nComfirmParam1 = Get_XParam_INT(0)
		--PushDebugMessage("nComfirmParam1="..nComfirmParam1)
		if nComfirmParam1 == 2 then --确认的是奖励替换界面放弃替换稀有物品的按钮
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("Anniversary_ExMarket_Refresh_OnComfirmedBack_2", {["Content"] = strMsg,["Type"] = "YesNo", })
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		--切换场景关闭界面
		Anniversary_ExMarket_Refresh_OnHide()	
	end
	
	if (event == "RELIVE_SHOW") then
		--死亡直接放弃奖励关闭界面
		--PushDebugMessage("RELIVE_SHOW=")
		Anniversary_ExMarket_Refresh_OnHide();
	end	
	
			
	if (event == "ADJEST_UI_POS" ) then
		Anniversary_ExMarket_Refresh_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_ExMarket_Refresh_Frame_On_ResetPos()
	end
		
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
-- for 奖励替换界面 放弃替换稀有物品的按钮
--=========================================================
function Anniversary_ExMarket_Refresh_OnComfirmedBack_2(strRet)

	--PushDebugMessage(" for 奖励替换界面 放弃替换稀有物品的按钮strRet="..strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		--放弃替换
		Anniversary_ExMarket_Refresh_ComfirmeCancelClick()	
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Anniversary_ExMarket_Refresh_ParamInit()

	g_nRewardLevel 		= Get_XParam_INT(1)
	g_nRewardIndex		= Get_XParam_INT(2)
	g_nCurRewardTableID = Get_XParam_INT(3)   	-- 1-8
	g_nNewRewardTableID = Get_XParam_INT(4) 	-- 1-8
end
--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Anniversary_ExMarket_Refresh_Reset()
		
	g_nRewardLevel = 0 
	g_nRewardIndex = 0 
	g_nCurRewardTableID = 0 
	g_nNewRewardTableID =0 
	
end

--=========================================================
-- 确认想要刷新稀有奖励  
--=========================================================
function Anniversary_ExMarket_Refresh_ConfirmClick()	

	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)	
			Set_XSCRIPT_Parameter(0, 30) --ntype		
			Set_XSCRIPT_Parameter(1, g_nRewardLevel)	---prob
			Set_XSCRIPT_Parameter(2, g_nRewardIndex)	
			Set_XSCRIPT_Parameter(3, 1)	--第二次
			Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end
--=========================================================
-- 确认放弃替换稀有奖励  
--=========================================================
function Anniversary_ExMarket_Refresh_ComfirmeCancelClick()	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRecMessage" )
		Set_XSCRIPT_ScriptID(g_nMyScriptId)
		Set_XSCRIPT_Parameter(0, 31) --ntype	
		Set_XSCRIPT_Parameter(1, 1)	--第二次
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
	Anniversary_ExMarket_Refresh_OnHide()
end


--=========================================================
-- 替换奖励界面 确认点击替换 不需要confirm
--=========================================================
function Anniversary_ExMarket_Refresh_ChangeClick()	
	--PushDebugMessage("替换奖励界面 确认点击替换 不需要confirm")
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)	
			Set_XSCRIPT_Parameter(0, 32) --ntype
			Set_XSCRIPT_Parameter(1, g_nRewardLevel)	
			Set_XSCRIPT_Parameter(2, g_nRewardIndex)	
			Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	this:Hide()
end
--=========================================================
-- 取消交换奖励
--=========================================================
function Anniversary_ExMarket_Refresh_CancelClick()	

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRecMessage" )
		Set_XSCRIPT_ScriptID(g_nMyScriptId)
		Set_XSCRIPT_Parameter(0, 33) --ntype
		Set_XSCRIPT_Parameter(1, g_nRewardLevel)					
		Set_XSCRIPT_Parameter(2, g_nRewardIndex)
		Set_XSCRIPT_Parameter(3, 0)	--第一次
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end



--Anniversary_ExMarket_Refresh_ViewClicked(1)"/

--=========================================================
--
--=========================================================
function Anniversary_ExMarket_Refresh_ViewClicked()
	
	-- 重置
	this:Hide()
	Anniversary_ExMarket_Refresh_Reset()
	
end


--=========================================================
-- 右上角x关闭界面+取消替换关闭 
--=========================================================
function Anniversary_ExMarket_Refresh_Close()
		--PushDebugMessage("关闭界面")
	Anniversary_ExMarket_Refresh_CancelClick()	
end

--=========================================================
--  关闭界面
--=========================================================
function	Anniversary_ExMarket_Refresh_OnHide()
	--PushDebugMessage("Anniversary_ExMarket_Refresh_OnHide")
	--清除缓存
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRecMessage" )
		Set_XSCRIPT_ScriptID(g_nMyScriptId)
		Set_XSCRIPT_Parameter(0, 34) --ntype
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	Anniversary_ExMarket_Refresh_Reset()
	this:Hide()
end


--=========================================================
-- 时装预览
--=========================================================
function Anniversary_ExMarket_Refresh_ViewClicked(param)
	if param == 1  then
		--原来的道具
		if g_nCurRewardTableID <= 0 then
			return 
		end
		local itemId = g_tRewardInfo[1].tRewardPool[g_nCurRewardTableID].nItemID
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)
			Set_XSCRIPT_Parameter(0, 19)		
			Set_XSCRIPT_Parameter(1, itemId)			
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif param == 2  then
		--刷出来的道具
		if g_nNewRewardTableID <= 0 then
			return 
		end
		local itemId = g_tRewardInfo[1].tRewardPool[g_nNewRewardTableID].nItemID
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)
			Set_XSCRIPT_Parameter(0, 19)		
			Set_XSCRIPT_Parameter(1, itemId)			
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	
	end

end


--=========================================================
-- 界面位置
--=========================================================
function Anniversary_ExMarket_Refresh_Frame_On_ResetPos()
	Anniversary_ExMarket_Refresh_Frame_BK:SetProperty("UnifiedPosition", g_Anniversary_ExMarket_Refresh_Frame_UnifiedPosition)
end
