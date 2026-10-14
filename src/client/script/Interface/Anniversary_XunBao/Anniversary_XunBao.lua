local g_Anniversary_XunBao_Frame_UnifiedPosition;

local g_Anniversary_XunBao_DaiBi = {}
local g_Anniversary_XunBao_PoolList = {}
local g_Anniversary_XunBao_ItemList = {}
local g_Anniversary_XunBao_ReturnList = {}
local g_Anniversary_XunBao_ButtontabList = {}
local g_Anniversary_XunBao_ClientList = {}
local g_Anniversary_XunBao_RightFrameBKList = {}

local g_Anniversary_XunBao_TimeClick = 0 --上次点击时间

local g_Anniversary_XunBao_ShowPageRP = 0

local g_Anniversary_XunBao_ShowId = 0
local g_Anniversary_XunBao_CanGetXJL = 0

--周年庆预热
local g_Anniversary_XunBao_CurPage = 1
local g_Anniversary_XunBao_CurSubPage = 1
local g_Anniversary_XunBao_CurTicket = 0
local g_Anniversary_XunBao_CurForFree = 0
local g_Anniversary_XunBao_CurDaiBiValue = {0,0,0,0}
local g_Anniversary_XunBao_nTimes = 1

local g_Anniversary_XunBao_PoolInfo = { 
[1] = {-1, -1, -1, -1},
[2] = {-1, -1, -1, -1},
[3] = {-1, -1, -1, -1},
}

local g_Anniversary_XunBao_Cost = { {1, 10}, {3, 30}, {10, 100} }

local g_Anniversary_XunBao_DaiBiStr = {
[1] = "#{ZNYR_200302_96}",	-- 青鳞
[2] = "#{ZNYR_200302_97}",
[3] = "#{ZNYR_200302_98}",
[4] = "#{ZNYR_200302_99}",
}

local g_Anniversary_XunBao_DaiBiTips = {
[1] = "#{ZNYR_200302_09}",	-- 青鳞
[2] = "#{ZNYR_200302_10}",
[3] = "#{ZNYR_200302_11}",
[4] = "#{ZNYR_200302_12}",
}

local g_Anniversary_XunBao_DaiBiImage = {
[1] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_BCup1",
[2] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_BCup2",
[3] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_BCup3",
[4] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_BCup4",
}

local g_Anniversary_XunBao_DaiBiImageSmall = {
[1] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup1",
[2] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup2",
[3] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup3",
[4] = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup4",
}

local g_Anniversary_XunBao_CurItemPage = 1

local g_Anniversary_XunBao_ItemPoolInfo = {
[4] = { [1] = {itemid = 39922650, itemnum = 1, exchangemax = 1, costnum = 130, havebuy = 0, },
		[2] = {itemid = 39922097, itemnum = 1, exchangemax = 4, costnum = 30, havebuy = 0, },
		--[3] = {itemid = 39920562, itemnum = 1, exchangemax = 1, costnum = 15, havebuy = 0, },
		[3] = {itemid = 39922700, itemnum = 1, exchangemax = 27, costnum = 3, havebuy = 0, },
		[4] = {itemid = 39921545, itemnum = 2, exchangemax = 10, costnum = 1, havebuy = 0, },
		}, -- 兑换奖池1
[3] = { [1] = {itemid = 39923479, itemnum = 1, exchangemax = 1, costnum = 120, havebuy = 0, },
		[2] = {itemid = 39920301, itemnum = 1, exchangemax = 1, costnum = 50, havebuy = 0, },
		--[3] = {itemid = 39923477, itemnum = 1, exchangemax = 1, costnum = 50, havebuy = 0, },
		[3] = {itemid = 39924020, itemnum = 1, exchangemax = 1, costnum = 50, havebuy = 0, },
		[4] = {itemid = 39921377, itemnum = 1, exchangemax = 1, costnum = 40, havebuy = 0, },
		[5] = {itemid = 39921303, itemnum = 80, exchangemax = 2, costnum = 8, havebuy = 0, },
		[6] = {itemid = 39920987, itemnum = 125, exchangemax = 2, costnum = 8, havebuy = 0, },
		[7] = {itemid = 39921301, itemnum = 40, exchangemax = 2, costnum = 8, havebuy = 0, },
		[8] = {itemid = 39923480, itemnum = 1, exchangemax = 21, costnum = 4, havebuy = 0, },
		[9] = {itemid = 39922686, itemnum = 1, exchangemax = 100, costnum = 1, havebuy = 0, },
		}, -- 兑换奖池2
[2] = { [1] = {itemid = 39923362, itemnum = 1, exchangemax = 1, costnum = 130, havebuy = 0, },
		--[2] = {itemid = 39923478, itemnum = 1, exchangemax = 1, costnum = 70, havebuy = 0, },
		[2] = {itemid = 39924021, itemnum = 1, exchangemax = 1, costnum = 70, havebuy = 0, },
		[3] = {itemid = 39920085, itemnum = 100, exchangemax = 2, costnum = 45, havebuy = 0, },
		[4] = {itemid = 39920181, itemnum = 5, exchangemax = 1, costnum = 37, havebuy = 0, },
		[5] = {itemid = 39920396, itemnum = 1, exchangemax = 10, costnum = 12, havebuy = 0, },
		[6] = {itemid = 39920397, itemnum = 1, exchangemax = 10, costnum = 12, havebuy = 0, },
		[7] = {itemid = 39920490, itemnum = 1, exchangemax = 20, costnum = 5, havebuy = 0, },
		[8] = {itemid = 39923481, itemnum = 1, exchangemax = 18, costnum = 4, havebuy = 0, },
		[9] = {itemid = 39922685, itemnum = 1, exchangemax = 200, costnum = 1, havebuy = 0, },
		--[10] = {itemid = 39922166, itemnum = 1, exchangemax = 20, costnum = 1, havebuy = 0, },
		}, -- 兑换奖池3
[1] = { [1] = {itemid = 39920085, itemnum = 30, exchangemax = 2, costnum = 52, havebuy = 0, },
		[2] = {itemid = 39920959, itemnum = 5, exchangemax = 2, costnum = 50, havebuy = 0, },
		[3] = {itemid = 39922568, itemnum = 1, exchangemax = 2, costnum = 44, havebuy = 0, },
		[4] = {itemid = 39920298, itemnum = 1, exchangemax = 5, costnum = 13, havebuy = 0, },
		--[5] = {itemid = 39922167, itemnum = 1, exchangemax = 100, costnum = 1, havebuy = 0, },
		--[6] = {itemid = 39922195, itemnum = 1, exchangemax = 100, costnum = 1, havebuy = 0, },
		--[7] = {itemid = 39922194, itemnum = 1, exchangemax = 100, costnum = 1, havebuy = 0, },
		[5] = {itemid = 39920163, itemnum = 2, exchangemax = -1, costnum = 1, havebuy = 0, },
		[6] = {itemid = 39922684, itemnum = 1, exchangemax = 300, costnum = 1, havebuy = 0, },
		}, -- 兑换奖池4
}

local g_XunBao_nDuiHuanContentButton = {}

local g_Anniversary_XunBao_IsGetFanLi = {0, 0, 0, 0}
local g_Anniversary_XunBao_GetFanLiIdx = {0, 0, 0, 0}
local g_Anniversary_XunBao_CanGetFanLi = {0, 0, 0, 0}
local g_Anniversary_XunBao_PoolCur = {0, 0, 0, 0}
local g_Anniversary_XunBao_FanLi = {
[1] = {showstr = "#{ZNYR_200302_137}", allNum = 200},
[2] = {showstr = "#{ZNYR_200302_138}", allNum = 200},
[3] = {showstr = "#{ZNYR_200302_139}", allNum = 180},
[4] = {showstr = "#{ZNYR_200302_140}", allNum = 580},
}

local g_XunBao_nContentButton = {}
local g_XunBao_Reward = {
"Anniversary_XunBao_Reward_Item1",
"Anniversary_XunBao_Reward_Item2",
"Anniversary_XunBao_Reward_Item4",
"Anniversary_XunBao_Reward_Item5",
"Anniversary_XunBao_Reward_Item6",
}

local g_XunBao_RewardBK = {
"Anniversary_XunBao_Reward_Item1BK",
"Anniversary_XunBao_Reward_Item2BK",
"Anniversary_XunBao_Reward_Item4BK",
"Anniversary_XunBao_Reward_Item5BK",
"Anniversary_XunBao_Reward_Item6BK",
}

local g_XunBao_RewardMask = {
[4] = "Anniversary_XunBao_Reward_Item5_Mask",
[5] = "Anniversary_XunBao_Reward_Item6_Mask",
}

local g_XunBao_ReturnGift = {
[1] = { {cnt = 1, showid = 39922213}, 	-- 固定奖励 秘技：飞燕轻姿（技能书）
		{cnt = 0, showid = 0},  		-- 固定奖励
		{cnt = 0, showid = 0}, 			-- 固定奖励
		{cnt = 0, showid = 0},			-- 可选 1
		{cnt = 0, showid = 0}, 			-- 可选 2
	},
[2] = { {cnt = 50, showid = 39922163},  	-- 固定奖励 祈福币
		{cnt = 10, showid = 39923481},  	-- 固定奖励 心决：誓江（碎片）*10
		{cnt = 0, showid = 0}, 			-- 固定奖励
		{cnt = 5, showid = 39920311}, 	-- 可选 1 幻魂丹*5
		{cnt = 5, showid = 39920538},  	-- 可选 2 虹耀石*5
	},
[3] = { {cnt = 100, showid = 39922163},  	-- 固定奖励 祈福币
		{cnt = 10, showid = 39923480},  	-- 固定奖励 心决：灵韵（碎片）*10
		{cnt = 0, showid = 0}, 			-- 固定奖励
		{cnt = 3, showid = 39920093}, 	-- 可选 1 高级勾天彩*3
		{cnt = 3, showid = 39921689},  	-- 可选 2 真元符集（橙）*3
	},
[4] = { {cnt = 250, showid = 39922163}, 	-- 固定奖励 祈福币
		{cnt = 5, showid = 39922700},  	-- 固定奖励 心决：心眼（碎片）*5
		{cnt = 1, showid = 39922220}, 	-- 固定奖励 布袜生尘
		{cnt = 3, showid = 39921023}, 	-- 可选 1 龙泉铁英*3
		{cnt = 10, showid = 39920329}, 	-- 可选 2 至尊强化精华*10
	},
}

--===============================================
-- PreLoad()
--===============================================
function Anniversary_XunBao_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	-- 离开场景
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)			
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	    
	-- 进入游戏世界
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)	

	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
end

--===============================================
-- OnEvent()
--===============================================
function Anniversary_XunBao_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 89340103) then
	
		local IsShow = Get_XParam_INT(0)		
		if IsShow <= 0 then
			Anniversary_XunBao_Close() 	
			return
		end
		
		if IsWindowShow("Anniversary_XunBaoMBuy") then
			CloseWindow("Anniversary_XunBaoMBuy", true)
		end
			
		if IsWindowShow("Anniversary_XunBaoChange") then
			CloseWindow("Anniversary_XunBaoChange", true)
		end
		
		if IsWindowShow("Anniversary_ThreeChoices") then
			CloseWindow("Anniversary_ThreeChoices", true)
		end
		
		if IsShow == 2 then
			Anniversary_XunBao_Buttontab01:Hide()
		else
			Anniversary_XunBao_Buttontab01:Show()
		end
		
		g_Anniversary_XunBao_CurPage = Get_XParam_INT(1)
		
		if g_Anniversary_XunBao_CurPage == 1 then		
			Anniversary_XunBao_SplitStr( Get_XParam_STR(0), 0 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(1), 1 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(2), 2 )
					
			g_Anniversary_XunBao_CurSubPage = Get_XParam_INT(2)	
			g_Anniversary_XunBao_CurTicket = Get_XParam_INT(3)	
			g_Anniversary_XunBao_CurForFree = Get_XParam_INT(4)	
			
			g_Anniversary_XunBao_CanGetXJL = Get_XParam_INT(5)	
			g_Anniversary_XunBao_ShowPageRP = Get_XParam_INT(6)	
			
		elseif g_Anniversary_XunBao_CurPage == 2 then
					
			g_Anniversary_XunBao_CurSubPage = Get_XParam_INT(2)	
			g_Anniversary_XunBao_CanGetXJL = Get_XParam_INT(3)	
			g_Anniversary_XunBao_ShowPageRP = Get_XParam_INT(4)	
			
			Anniversary_XunBao_SplitStr( Get_XParam_STR(0), 0 )	
			Anniversary_XunBao_SplitStr( Get_XParam_STR(1), 2 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(2), 3 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(3), 4 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(4), 5 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(5), 6 )
			
		elseif g_Anniversary_XunBao_CurPage == 3 then	
		
			Anniversary_XunBao_SplitStr( Get_XParam_STR(0), 2 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(1), 7 )
			
			g_Anniversary_XunBao_CanGetXJL = Get_XParam_INT(2)	
			g_Anniversary_XunBao_ShowPageRP = Get_XParam_INT(3)	
			
		else
			Anniversary_XunBao_Close() 	
			return
		end
		
		this:Show();
		
		Anniversary_XunBao_Init()
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89340113) then
	
		if this:IsVisible() then
		
			g_Anniversary_XunBao_CanGetXJL = Get_XParam_INT(0)
			-- 刷新领取行酒令小红点
			Anniversary_XunBao_RefreshTips()
			
		end
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89340102) then
	
		if this:IsVisible() then
		
			if g_Anniversary_XunBao_CurSubPage ~= Get_XParam_INT(0)	then
				return
			end
		
			if g_Anniversary_XunBao_nTimes ~= Get_XParam_INT(1)	then
				return
			end
			
			g_Anniversary_XunBao_CurTicket = Get_XParam_INT(2)	
			g_Anniversary_XunBao_CurForFree = Get_XParam_INT(3)	
			
			local nCurQiFu = Get_XParam_INT(4)	
			local nFreeQiFu = Get_XParam_INT(5)	
			
			g_Anniversary_XunBao_ShowPageRP = Get_XParam_INT(6)	
			
			Anniversary_XunBao_SplitStr( Get_XParam_STR(0), 0 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(1), 1 )
			Anniversary_XunBao_SplitStr( Get_XParam_STR(2), 2 )
			
			if g_Anniversary_XunBao_nTimes == 1 then
				g_Anniversary_XunBao_nReturn = Get_XParam_INT(7)
			else
				g_Anniversary_XunBao_nReturn = Get_XParam_STR(3) 
			end
			
			for i = 1, table.getn(g_Anniversary_XunBao_RightFrameBKList) do
				g_Anniversary_XunBao_RightFrameBKList[i][3]:Hide()
			end
			
			if g_Anniversary_XunBao_nTimes == 1 then
				Anniversary_XunBao_OneDrawFrame:Show()
				Anniversary_XunBao_TenDrawFrame:Hide()
			else
				Anniversary_XunBao_OneDrawFrame:Hide()
				Anniversary_XunBao_TenDrawFrame:Show()							
			end
			
			Anniversary_XunBao_InitXunBaoReturn(nCurQiFu, nFreeQiFu)	
		end
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89340105) then
	
		g_Anniversary_XunBao_CurTicket = Get_XParam_INT(0)	
		g_Anniversary_XunBao_CurForFree = Get_XParam_INT(1)	
		g_Anniversary_XunBao_CurDaiBiValue[1] = Get_XParam_INT(2)	
		g_Anniversary_XunBao_CurDaiBiValue[2] = Get_XParam_INT(3)	
		g_Anniversary_XunBao_CurDaiBiValue[3] = Get_XParam_INT(4)	
		g_Anniversary_XunBao_CurDaiBiValue[4] = Get_XParam_INT(5)	

		Anniversary_XunBao_RefreshData()
		 
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89340112) then
	
		g_Anniversary_XunBao_CurPage = Get_XParam_INT(0)		
		g_Anniversary_XunBao_CurSubPage = Get_XParam_INT(1)	
		
		Anniversary_XunBao_Init()
		
	elseif(event == "PACKAGE_ITEM_CHANGED_EX") then	
		--if arg0 ~= nil and tonumber(arg0) == 38006092 then
		--	PushDebugMessage(arg0)
			g_Anniversary_XunBao_CurTicket = PlayerPackage:CountAvailableItemByIDTable(38006092)
			Anniversary_XunBao_RightFrame_Ticket_Text:SetText("#L"..tostring(g_Anniversary_XunBao_CurTicket))
		--end
	
	elseif (event == "HIDE_ON_SCENE_TRANSED") or (event == "PLAYER_LEAVE_WORLD") or (event == "PLAYER_ENTERING_WORLD" ) then
	
		Anniversary_XunBao_Close()
		
	elseif (event == "ADJEST_UI_POS") or (event == "VIEW_RESOLUTION_CHANGED") then
	
		Anniversary_XunBao_On_ResetPos()
		
	end

end

--===============================================
-- OnLoad()
--===============================================
function Anniversary_XunBao_OnLoad()

	g_Anniversary_XunBao_Frame_UnifiedPosition = Anniversary_XunBao_Frame:GetProperty("UnifiedPosition")
	
	g_Anniversary_XunBao_DaiBi = {  
		{Anniversary_XunBao_Client1TopFrame_Currency_A_Number, Anniversary_XunBao_Client2TopFrame_Currency_A_Number},
		{Anniversary_XunBao_Client1TopFrame_Currency_B_Number, Anniversary_XunBao_Client2TopFrame_Currency_B_Number},
		{Anniversary_XunBao_Client1TopFrame_Currency_C_Number, Anniversary_XunBao_Client2TopFrame_Currency_C_Number},
		{Anniversary_XunBao_Client1TopFrame_Currency_D_Number, Anniversary_XunBao_Client2TopFrame_Currency_D_Number},
	}
	
	g_Anniversary_XunBao_PoolList = {	
		[1] = {		
			[1] = {Anniversary_XunBao_RightFrame_AntiqueD_Frame, Anniversary_XunBao_RightFrame_AntiqueD_Text},		
			[2] = {Anniversary_XunBao_RightFrame_AntiqueC_Frame, Anniversary_XunBao_RightFrame_AntiqueC_Text},	
			[3] = {Anniversary_XunBao_RightFrame_AntiqueB_Frame, Anniversary_XunBao_RightFrame_AntiqueB_Text},
			[4] = {Anniversary_XunBao_RightFrame_AntiqueA_Frame, Anniversary_XunBao_RightFrame_AntiqueA_Text},	
		},	
		[2] = {	
			[2] = {Anniversary_XunBao_RightFrame_2_AntiqueC_Frame, Anniversary_XunBao_RightFrame_2_AntiqueC_Text},	
			[3] = {Anniversary_XunBao_RightFrame_2_AntiqueB_Frame, Anniversary_XunBao_RightFrame_2_AntiqueB_Text},	
			[4] = {Anniversary_XunBao_RightFrame_2_AntiqueA_Frame, Anniversary_XunBao_RightFrame_2_AntiqueA_Text},	
		},	
		[3] = {			
			[3] = {Anniversary_XunBao_RightFrame_3_AntiqueB_Frame, Anniversary_XunBao_RightFrame_3_AntiqueB_Text},
			[4] = {Anniversary_XunBao_RightFrame_3_AntiqueA_Frame, Anniversary_XunBao_RightFrame_3_AntiqueA_Text},
		},
	}
	
	g_Anniversary_XunBao_RightFrameBKList = {
		{Anniversary_XunBao_RightFrameBK, Anniversary_XunBao_RightFrameBK_Scenes, Anniversary_XunBao_RightFrame_AntiqueFrame},
		{Anniversary_XunBao_RightFrameBK_2, Anniversary_XunBao_RightFrameBK_2_Scenes, Anniversary_XunBao_RightFrame_2_AntiqueFrame},
		{Anniversary_XunBao_RightFrameBK_3, Anniversary_XunBao_RightFrameBK_3_Scenes, Anniversary_XunBao_RightFrame_3_AntiqueFrame},
	}
	
	g_Anniversary_XunBao_PoolCheckButton = {	
		Anniversary_XunBao_LeftLace_BonusPoolA_Btn, 
		Anniversary_XunBao_LeftLace_BonusPoolB_Btn, 
		Anniversary_XunBao_LeftLace_BonusPoolC_Btn
	}
	
	g_Anniversary_XunBao_PoolFinish = {	
		Anniversary_XunBao_LeftLace_BonusPoolA_Finish,
		Anniversary_XunBao_LeftLace_BonusPoolB_Finish,
		Anniversary_XunBao_LeftLace_BonusPoolC_Finish
	}
	
	g_Anniversary_XunBao_ButtontabList = {
		Anniversary_XunBao_Buttontab01, 
		Anniversary_XunBao_Buttontab02, 
		Anniversary_XunBao_Buttontab03,
	}
	
	g_Anniversary_XunBao_ClientList = {
		Anniversary_XunBao_Client1, 
		Anniversary_XunBao_Client2, 
		Anniversary_XunBao_Client3,
	}
	
	g_Anniversary_XunBao_ReturnList = {
		[1] = {Anniversary_XunBao_TenDraw_Item1Fudai, Anniversary_XunBao_TenDraw_Item1, Anniversary_XunBao_TenDraw_Item1Text},
		[2] = {Anniversary_XunBao_TenDraw_Item2Fudai, Anniversary_XunBao_TenDraw_Item2, Anniversary_XunBao_TenDraw_Item2Text},
		[3] = {Anniversary_XunBao_TenDraw_Item3Fudai, Anniversary_XunBao_TenDraw_Item3, Anniversary_XunBao_TenDraw_Item3Text},
		[4] = {Anniversary_XunBao_TenDraw_Item4Fudai, Anniversary_XunBao_TenDraw_Item4, Anniversary_XunBao_TenDraw_Item4Text},
		[5] = {Anniversary_XunBao_TenDraw_Item5Fudai, Anniversary_XunBao_TenDraw_Item5, Anniversary_XunBao_TenDraw_Item5Text},
		[6] = {Anniversary_XunBao_TenDraw_Item6Fudai, Anniversary_XunBao_TenDraw_Item6, Anniversary_XunBao_TenDraw_Item6Text},
		[7] = {Anniversary_XunBao_TenDraw_Item7Fudai, Anniversary_XunBao_TenDraw_Item7, Anniversary_XunBao_TenDraw_Item7Text},
		[8] = {Anniversary_XunBao_TenDraw_Item8Fudai, Anniversary_XunBao_TenDraw_Item8, Anniversary_XunBao_TenDraw_Item8Text},
		[9] = {Anniversary_XunBao_TenDraw_Item9Fudai, Anniversary_XunBao_TenDraw_Item9, Anniversary_XunBao_TenDraw_Item9Text},
		[10] = {Anniversary_XunBao_TenDraw_Item10Fudai, Anniversary_XunBao_TenDraw_Item10, Anniversary_XunBao_TenDraw_Item10Text},
	}
	
	g_Anniversary_XunBao_ItemList = {
		[1] = Anniversary_XunBao_LeftLace_ShopA_Btn, 
		[2] = Anniversary_XunBao_LeftLace_ShopB_Btn, 
		[3] = Anniversary_XunBao_LeftLace_ShopC_Btn, 
		[4] = Anniversary_XunBao_LeftLace_ShopD_Btn, 
	}
	
end

--===============================================
-- Init()
--===============================================
function Anniversary_XunBao_Init()

	if g_Anniversary_XunBao_CurPage == 1 then
			
		--打开背包
		--if( IsWindowShow("Packet") == false ) then
		--	ToggleContainer()
		--end
		
		Anniversary_XunBao_SetSelect()
		
		Anniversary_XunBao_InitXunBao()
	elseif g_Anniversary_XunBao_CurPage == 2 then
		
		Anniversary_XunBao_SetSelect()
		
		Anniversary_XunBao_InitDuiHuan()
	elseif g_Anniversary_XunBao_CurPage == 3 then
		
		Anniversary_XunBao_SetSelect()
		
		Anniversary_XunBao_InitFanLi()
	else
		Anniversary_XunBao_Close() 	
	end

	Anniversary_XunBao_RefreshTips()
	
end

function Anniversary_XunBao_RefreshTips()

	-- 页签1小红点
	if g_Anniversary_XunBao_CanGetXJL == 1 then
		Anniversary_XunBao_RightFrame_Ticket_Btn_Tips:Show()
		Anniversary_XunBao_Buttontab01_Tips:Show()
	else
		Anniversary_XunBao_RightFrame_Ticket_Btn_Tips:Hide()
		Anniversary_XunBao_Buttontab01_Tips:Hide()
	end
	
	local nDaiBiValue = 0
	for i = 1, 4 do
		if g_Anniversary_XunBao_CurDaiBiValue[i] > 0 then
			nDaiBiValue = 1
		end
	end
	
	if g_Anniversary_XunBao_ShowPageRP == 0 and nDaiBiValue > 0 then
		-- 页签2显示小红点
		Anniversary_XunBao_Buttontab02_Tips:Show()
	else
		Anniversary_XunBao_Buttontab02_Tips:Hide()
	end
		
	-- 页签3小红点
	local IsShow = 0
	for i = 1, table.getn(g_Anniversary_XunBao_IsGetFanLi) do
		if g_Anniversary_XunBao_IsGetFanLi[i] == 0 and g_Anniversary_XunBao_CanGetFanLi[i] > 0 then
			IsShow = 1
		end
	end
	if IsShow == 1 then
		Anniversary_XunBao_Buttontab03_Tips:Show()
	else
		Anniversary_XunBao_Buttontab03_Tips:Hide()
	end
	
end

function Anniversary_XunBao_RefreshData()
	
	-- 四种代币数量
	local str = ""
	for i = 1, table.getn(g_Anniversary_XunBao_DaiBi) do
		str = ScriptGlobal_Format("#{ZNYR_200302_20}", g_Anniversary_XunBao_CurDaiBiValue[i])
		g_Anniversary_XunBao_DaiBi[i][1]:SetText( str )
		g_Anniversary_XunBao_DaiBi[i][2]:SetText( str )
	end
	
	-- 残卷数量
	Anniversary_XunBao_RightFrame_Ticket_Text:SetText("#L"..tostring(g_Anniversary_XunBao_CurTicket))
	-- 免费资格
	--Anniversary_XunBao_RightFrame_ForFree_Text:SetText(tostring(g_Anniversary_XunBao_CurForFree))
	
end

function Anniversary_XunBao_InitXunBao()

	Anniversary_XunBao_RefreshData()
	
	for i = 1, table.getn(g_Anniversary_XunBao_PoolInfo) do
		local CurPoolAll = 0
		for j = 1, table.getn(g_Anniversary_XunBao_PoolInfo[i]) do
			CurPoolAll = CurPoolAll + g_Anniversary_XunBao_PoolInfo[i][j]
		end
		if CurPoolAll == 0 then	
			g_Anniversary_XunBao_PoolFinish[i]:Show()
		else
			g_Anniversary_XunBao_PoolFinish[i]:Hide()
		end
	end
	
	-- 初始化池子
	Anniversary_XunBao_Pool_Clicked( g_Anniversary_XunBao_CurSubPage )
end

function Anniversary_XunBao_SplitStr( nStr, nIsPool )
	local strItem = nStr.."*"
	local splitTimes = 4
	local poolid = 1
	local dbid = 1
	if nIsPool == 1 then
		splitTimes = 12
	elseif nIsPool == 2 then
		splitTimes = 16
	elseif nIsPool >= 3 and nIsPool <= 6 then
		local idx = nIsPool-2
		if g_Anniversary_XunBao_ItemPoolInfo[idx] ~= nil then
			splitTimes = table.getn(g_Anniversary_XunBao_ItemPoolInfo[idx])
		end
	end
	
	for i = 1, splitTimes do
		local iPos = string.find( strItem, "*" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)
			
			if nIsPool == 2 then
				if i <= 4 then
					g_Anniversary_XunBao_IsGetFanLi[i] = tonumber(tempstr)
				elseif i <= 8 then
					g_Anniversary_XunBao_GetFanLiIdx[i-4] = tonumber(tempstr)
				else
					g_Anniversary_XunBao_CanGetFanLi[i-8] = tonumber(tempstr)
				end
			elseif nIsPool == 1 then
				g_Anniversary_XunBao_PoolInfo[poolid][dbid] = tonumber(tempstr)
				if math.mod(dbid, 4) == 0 then
					poolid = poolid + 1
					dbid = 1
				else
					dbid = dbid + 1
				end
			elseif nIsPool >= 3 and nIsPool <= 6 then
				if g_Anniversary_XunBao_ItemPoolInfo[nIsPool-2] ~= nil then
					g_Anniversary_XunBao_ItemPoolInfo[nIsPool-2][i].havebuy = tonumber(tempstr)
				end
			elseif nIsPool == 7 then
				g_Anniversary_XunBao_PoolCur[i] = tonumber(tempstr)
			else
				g_Anniversary_XunBao_CurDaiBiValue[i] = tonumber(tempstr)				
			end
			
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end
	end
end

function Anniversary_XunBao_TimerProc()
	KillTimer("Anniversary_XunBao_TimerProc()");
	
	if g_Anniversary_XunBao_nTimes == 1 then
		Anniversary_XunBao_OneDraw_Item1Fudai:Show()
	else
		if g_Anniversary_XunBao_ReturnList[g_Anniversary_XunBao_ShowId] ~= nil then
			g_Anniversary_XunBao_ReturnList[g_Anniversary_XunBao_ShowId][1]:Show()
			if g_Anniversary_XunBao_ShowId < g_Anniversary_XunBao_nTimes then
				SetTimer("Anniversary_XunBao","Anniversary_XunBao_TimerProc()", 200)
			end
			g_Anniversary_XunBao_ShowId = g_Anniversary_XunBao_ShowId + 1
		end
	end
end

function Anniversary_XunBao_InitXunBaoReturn(nCurQiFu, nFreeQiFu)

	local nPool = g_Anniversary_XunBao_CurSubPage
	local nReturn = g_Anniversary_XunBao_nReturn
	
	if g_Anniversary_XunBao_PoolInfo[nPool] == nil then
		return
	end	
	
	Anniversary_XunBao_RefreshData()
	
	for i = 1, table.getn(g_Anniversary_XunBao_PoolInfo) do
		local CurPoolAll = 0
		for j = 1, table.getn(g_Anniversary_XunBao_PoolInfo[i]) do
			CurPoolAll = CurPoolAll + g_Anniversary_XunBao_PoolInfo[i][j]
		end
		if CurPoolAll == 0 then	
			g_Anniversary_XunBao_PoolFinish[i]:Show()
		else
			g_Anniversary_XunBao_PoolFinish[i]:Hide()
		end
	end
	
	local dbType = 0
	local str = ""
	if g_Anniversary_XunBao_nTimes == 1 then
	
		Anniversary_XunBao_OneDraw_Item1Fudai:Hide()
		
		dbType = tonumber(nReturn)	
		if g_Anniversary_XunBao_DaiBiStr[dbType] == nil or g_Anniversary_XunBao_DaiBiImage[dbType] == nil then
			Anniversary_XunBao_ShowSelectFrame()
			return
		end		
		
		Anniversary_XunBao_OneDraw_Item1:SetProperty("Image", g_Anniversary_XunBao_DaiBiImage[dbType])
		Anniversary_XunBao_OneDraw_Item1Text:SetText("#L"..g_Anniversary_XunBao_DaiBiStr[dbType])
		
		if nCurQiFu <= 0 then
			Anniversary_XunBao_OneDraw_ExtraTips:Hide()
		else
			Anniversary_XunBao_OneDraw_ExtraTips:Show()
			if nFreeQiFu > 0 then
				str = ScriptGlobal_Format("#{ZNYR_200302_154}", nCurQiFu, nFreeQiFu)
			else
				str = ScriptGlobal_Format("#{ZNYR_200302_153}", nCurQiFu)
			end
			Anniversary_XunBao_OneDraw_ExtraTips:SetText( str )
		end		
	
		-- 定时器 开启
		SetTimer("Anniversary_XunBao","Anniversary_XunBao_TimerProc()", 100)
		g_Anniversary_XunBao_ShowId = 1
		
	else		
		for i =1, table.getn(g_Anniversary_XunBao_ReturnList) do
			g_Anniversary_XunBao_ReturnList[i][1]:Hide()
		end
		
		local strItem = nReturn.."*"
		for i = 1, g_Anniversary_XunBao_nTimes do
			local iPos = string.find( strItem, "*" );
			if ( iPos ~= nil ) then
				local tempstr = string.sub(strItem, 1, iPos-1)
				dbType = tonumber(tempstr)	
				
				if g_Anniversary_XunBao_DaiBiStr[dbType] == nil or g_Anniversary_XunBao_DaiBiImage[dbType] == nil then
					Anniversary_XunBao_ShowSelectFrame()
					return
				end		
				--g_Anniversary_XunBao_ReturnList[i][1]:Show()
				g_Anniversary_XunBao_ReturnList[i][2]:SetProperty("Image", g_Anniversary_XunBao_DaiBiImage[dbType])
				g_Anniversary_XunBao_ReturnList[i][3]:SetText("#L"..g_Anniversary_XunBao_DaiBiStr[dbType])
						
				strItem = string.sub(strItem, iPos+1, string.len(strItem))
			end
		end
		
		if nCurQiFu <= 0 then
			Anniversary_XunBao_TenDraw_ExtraTips:Hide()
		else
			if nFreeQiFu > 0 then
				str = ScriptGlobal_Format("#{ZNYR_200302_154}", nCurQiFu, nFreeQiFu)
			else
				str = ScriptGlobal_Format("#{ZNYR_200302_153}", nCurQiFu)
			end
			Anniversary_XunBao_TenDraw_ExtraTips:SetText( str )
		end
	
		-- 定时器 开启
		SetTimer("Anniversary_XunBao","Anniversary_XunBao_TimerProc()", 500)
		g_Anniversary_XunBao_ShowId = 1
	end
	
	Anniversary_XunBao_RefreshTips()
	
end

function Anniversary_XunBao_InitDuiHuan()
	
	-- 四种代币数量	
	Anniversary_XunBao_RefreshData()
	
	-- 初始化物品兑换池子
	Anniversary_XunBao_ItemPool_Clicked( g_Anniversary_XunBao_CurSubPage )
	
end

function Anniversary_XunBao_InitFanLi()
	
	for i = 1, table.getn(g_XunBao_nContentButton) do
		for j = 1, table.getn(g_XunBao_Reward) do
			g_XunBao_nContentButton[i]:GetSubItem(g_XunBao_Reward[j]):SetActionItem(-1)
		end
	end			
	Anniversary_XunBao_UpFrame_RewardList:Clear()		
	g_XunBao_nContentButton = {}

	for i = 1, table.getn(g_Anniversary_XunBao_FanLi) do
		local bar = Anniversary_XunBao_UpFrame_RewardList:AddChild("Anniversary_XunBao_UpFrame_RewardContent")
		if nil ~= bar then
			local strmsg = ""
			-- 达成条件
			bar:GetSubItem("Anniversary_XunBao_UpFrame_Reward_PointText"):SetText(g_Anniversary_XunBao_FanLi[i].showstr)
			
			if g_Anniversary_XunBao_PoolCur[i] >= g_Anniversary_XunBao_FanLi[i].allNum then
				-- 已达成
				strmsg = ScriptGlobal_Format("#{ZNYR_200302_160}", g_Anniversary_XunBao_FanLi[i].allNum, g_Anniversary_XunBao_FanLi[i].allNum)
			else
				-- 未达成
				strmsg = ScriptGlobal_Format("#{ZNYR_200302_159}", g_Anniversary_XunBao_PoolCur[i], g_Anniversary_XunBao_FanLi[i].allNum)
			end
			bar:GetSubItem("Anniversary_XunBao_UpFrame_Reward_PointText2"):SetText( strmsg )
			
			-- 奖励显示			
			for idx = 1, table.getn(g_XunBao_RewardBK) do
				bar:GetSubItem(g_XunBao_RewardBK[idx]):Hide()
			end		
			for idx = 4, 5 do
				bar:GetSubItem(g_XunBao_RewardMask[idx]):Hide()
			end
			if g_XunBao_ReturnGift[i] ~= nil then
				for itemidx = 1, table.getn(g_XunBao_ReturnGift[i]) do
					local itemid = g_XunBao_ReturnGift[i][itemidx].showid
					local itemnum = g_XunBao_ReturnGift[i][itemidx].cnt
					if itemid > 0 and itemnum > 0 then
						local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
						if theAction:GetID() ~= 0 then
							bar:GetSubItem(g_XunBao_RewardBK[itemidx]):Show()
							bar:GetSubItem(g_XunBao_Reward[itemidx]):SetActionItem(theAction:GetID());
						end
					end
			
					if g_XunBao_RewardMask[itemidx] ~= nil then
						if g_Anniversary_XunBao_GetFanLiIdx[i] ~= nil and g_Anniversary_XunBao_GetFanLiIdx[i] == itemidx then
							bar:GetSubItem(g_XunBao_RewardMask[itemidx]):Show()
						else
							bar:GetSubItem(g_XunBao_RewardMask[itemidx]):Hide()
						end
					end
				end
			end
			
			--按钮
			bar:GetSubItem("Anniversary_XunBao_Reward_Button"):Hide()
			bar:GetSubItem("Anniversary_XunBao_Reward_BasicItemReceived"):Hide()
			bar:GetSubItem("Anniversary_XunBao_Reward_BasicItemNotReach"):Hide()
			if g_Anniversary_XunBao_IsGetFanLi[i] ~= nil then
				if g_Anniversary_XunBao_IsGetFanLi[i] == 1 then	-- 已领取
					bar:GetSubItem("Anniversary_XunBao_Reward_BasicItemReceived"):Show()
				else
					if g_Anniversary_XunBao_CanGetFanLi[i] ~= nil then
						if g_Anniversary_XunBao_CanGetFanLi[i] == 0 then	-- 未达成
							bar:GetSubItem("Anniversary_XunBao_Reward_BasicItemNotReach"):Show()
						else
							bar:GetSubItem("Anniversary_XunBao_Reward_Button"):Show()
						end
					end
				end				
			end
			bar:SetSubItemEvent("Anniversary_XunBao_Reward_Button", "Clicked", "Anniversary_XunBao_Reward_Click("..i..")")	
			
			g_XunBao_nContentButton[i] = bar
			
		end
	end
	
end

--===============================================
-- Close()
--===============================================
function Anniversary_XunBao_Close()
 
	for i = 1, table.getn(g_XunBao_nDuiHuanContentButton) do
		g_XunBao_nDuiHuanContentButton[i]:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon"):SetActionItem(-1)
	end			
	Anniversary_XunBao_Client2_RightFrameBK_List:Clear()		
	g_XunBao_nDuiHuanContentButton = {}
	
	for i = 1, table.getn(g_XunBao_nContentButton) do
		for j = 1, table.getn(g_XunBao_Reward) do
			g_XunBao_nContentButton[i]:GetSubItem(g_XunBao_Reward[j]):SetActionItem(-1)
		end
	end			
	Anniversary_XunBao_UpFrame_RewardList:Clear()		
	g_XunBao_nContentButton = {}
		
	if IsWindowShow("Anniversary_XunBaoMBuy") then
		CloseWindow("Anniversary_XunBaoMBuy", true)
	end
		
	if IsWindowShow("Anniversary_XunBaoChange") then
		CloseWindow("Anniversary_XunBaoChange", true)
	end
		
	if IsWindowShow("Anniversary_ThreeChoices") then
		CloseWindow("Anniversary_ThreeChoices", true)
	end
	
	this:Hide();
	
end

--===============================================
-- ResetPos()
--===============================================
function Anniversary_XunBao_On_ResetPos()

	Anniversary_XunBao_Frame:SetProperty("UnifiedPosition", g_Anniversary_XunBao_Frame_UnifiedPosition)
	
end

function Anniversary_XunBao_PassTime()
   local iCur = OSAPI:GetTickCount()
   if( iCur - g_Anniversary_XunBao_TimeClick) < 500 then
       return false;
   else
       g_Anniversary_XunBao_TimeClick = iCur;
       return true;
   end
end

function Anniversary_XunBao_SetSelect()

	local nListCount = table.getn(g_Anniversary_XunBao_ButtontabList)
	if nListCount ~= table.getn(g_Anniversary_XunBao_ClientList) then
		return
	end

	for i = 1, nListCount do
		if g_Anniversary_XunBao_CurPage == i then
			g_Anniversary_XunBao_ButtontabList[i]:SetCheck(1)
			g_Anniversary_XunBao_ClientList[i]:Show()
		else
			g_Anniversary_XunBao_ButtontabList[i]:SetCheck(0)
			g_Anniversary_XunBao_ClientList[i]:Hide()
		end
	end
	
end

--===============================================
-- change page
--===============================================
function Anniversary_XunBao_Project_Clicked( nPage )

	if nPage == g_Anniversary_XunBao_CurPage then
		return
	end
	
	--检查CD 
	if not Anniversary_XunBao_PassTime() then 
		PushDebugMessage("#{ZQGZ_110512_23}")  --"#H请不要操作太快！";
		
		for i = 1, table.getn(g_Anniversary_XunBao_ButtontabList) do
		if g_Anniversary_XunBao_CurPage == i then
			g_Anniversary_XunBao_ButtontabList[i]:SetCheck(1)
		else
			g_Anniversary_XunBao_ButtontabList[i]:SetCheck(0)
		end
	end
		return
	end 

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreChangePage" )
		Set_XSCRIPT_ScriptID( 893401 )
		Set_XSCRIPT_Parameter(0, nPage)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_Parameter(2, g_Anniversary_XunBao_CurPage)
		Set_XSCRIPT_Parameter(3, g_Anniversary_XunBao_CurSubPage)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	
	
end

--===============================================
-- help
--===============================================
function Anniversary_XunBao_Help_Click()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreShowHelp" )
		Set_XSCRIPT_ScriptID( 893401 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
	
end

--===============================================
-- TransButton
--===============================================
function Anniversary_XunBao_TransButton_Clicked()
	PushEvent( "UI_COMMAND", 89340106, 1, g_Anniversary_XunBao_CurDaiBiValue[1], g_Anniversary_XunBao_CurDaiBiValue[2], g_Anniversary_XunBao_CurDaiBiValue[3], g_Anniversary_XunBao_CurDaiBiValue[4] )
end

function Anniversary_XunBao_ShowSelectFrame()

	if g_Anniversary_XunBao_PoolInfo[g_Anniversary_XunBao_CurSubPage] == nil then
		return
	end		
	
	Anniversary_XunBao_Pool_Clicked( g_Anniversary_XunBao_CurSubPage )
	
end

--===============================================
-- 页签1 选择代币池子
--===============================================
function Anniversary_XunBao_Pool_Clicked( nPool )
	
	if g_Anniversary_XunBao_PoolInfo[nPool] == nil then
		return
	end		
	
	if g_Anniversary_XunBao_PoolCheckButton[nPool] == nil then
		return
	end
	
	if g_Anniversary_XunBao_Cost[nPool] == nil then
		return
	end
	
	if g_Anniversary_XunBao_RightFrameBKList[nPool] == nil then
		return
	end
	
	if g_Anniversary_XunBao_PoolList[nPool] == nil then
		return
	end
		
	if IsWindowShow("Anniversary_XunBaoMBuy") then
		CloseWindow("Anniversary_XunBaoMBuy", true)
	end
			
	if IsWindowShow("Anniversary_XunBaoChange") then
		CloseWindow("Anniversary_XunBaoChange", true)
	end
		
	if IsWindowShow("Anniversary_ThreeChoices") then
		CloseWindow("Anniversary_ThreeChoices", true)
	end
	
	for i = 1, table.getn(g_Anniversary_XunBao_RightFrameBKList) do
		if i == nPool then
			g_Anniversary_XunBao_RightFrameBKList[i][1]:Show()
			g_Anniversary_XunBao_RightFrameBKList[i][3]:Show()
		else
			g_Anniversary_XunBao_RightFrameBKList[i][1]:Hide()
			g_Anniversary_XunBao_RightFrameBKList[i][3]:Hide()
		end
	end
	
	-- 返回结果展示界面
	Anniversary_XunBao_OneDrawFrame:Hide()
	Anniversary_XunBao_TenDrawFrame:Hide()
	
	g_Anniversary_XunBao_CurSubPage = nPool
	
	for i = 1, table.getn(g_Anniversary_XunBao_PoolCheckButton) do
		if i == nPool then
			g_Anniversary_XunBao_PoolCheckButton[i]:SetCheck(1)
		else
			g_Anniversary_XunBao_PoolCheckButton[i]:SetCheck(0)
		end
	end
		
	for j = 1, table.getn(g_Anniversary_XunBao_PoolInfo[nPool]) do
		if g_Anniversary_XunBao_PoolList[nPool][j] ~= nil then
			if g_Anniversary_XunBao_PoolInfo[nPool][j] >= 0 then
				g_Anniversary_XunBao_PoolList[nPool][j][1]:Show()
				if g_Anniversary_XunBao_PoolInfo[nPool][j] == 0 then
					g_Anniversary_XunBao_PoolList[nPool][j][2]:SetText("#cff0000"..tostring(g_Anniversary_XunBao_PoolInfo[nPool][j]))
				else
					g_Anniversary_XunBao_PoolList[nPool][j][2]:SetText("#e4b280a"..tostring(g_Anniversary_XunBao_PoolInfo[nPool][j]))
				end
			else
				g_Anniversary_XunBao_PoolList[nPool][j][1]:Hide()
			end
		end
	end
	
	Anniversary_XunBao_RightFrame_XunBaoOnce_ButtonTips:Hide()
	Anniversary_XunBao_RightFrame_XunBao10Times_ButtonTips:Hide()
	
	local str = ScriptGlobal_Format("#{ZNYR_200302_118}", g_Anniversary_XunBao_Cost[nPool][1])
	Anniversary_XunBao_RightFrame_XunBaoOnce_Text:SetText( str )
	str = ScriptGlobal_Format("#{ZNYR_200302_118}", g_Anniversary_XunBao_Cost[nPool][2])
	Anniversary_XunBao_RightFrame_XunBao10Times_Text:SetText( str )	
	
end

--===============================================
-- 页签1 寻宝
--===============================================
function Anniversary_XunBao_XBClicked( nTimes )

	g_Anniversary_XunBao_nTimes = nTimes

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreXunBao" )
		Set_XSCRIPT_ScriptID( 893401 )
		Set_XSCRIPT_Parameter(0, g_Anniversary_XunBao_CurSubPage)
		Set_XSCRIPT_Parameter(1, nTimes)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
	
end

--===============================================
-- 页签2 批量购买
--===============================================
function Anniversary_XunBao_MbuyClick()

	PrepearBuyMult()

end

--===============================================
-- 页签2 点击道具
--===============================================
function Anniversary_XunBao_Item_Clicked( nItemIdx )

	if g_Anniversary_XunBao_ItemPoolInfo[g_Anniversary_XunBao_CurItemPage] == nil then
		g_Anniversary_XunBao_CurItemPage = 1
	end
	
	if g_Anniversary_XunBao_ItemPoolInfo[g_Anniversary_XunBao_CurItemPage][nItemIdx] == nil then
		return
	end

	--if CheckBuyMult() == 1 then		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AnniPreExchangeItemMbuy" )
			Set_XSCRIPT_ScriptID( 893401 )
			Set_XSCRIPT_Parameter(0, g_Anniversary_XunBao_CurItemPage)
			Set_XSCRIPT_Parameter(1, nItemIdx)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	--else	
	--	Clear_XSCRIPT()
	--		Set_XSCRIPT_Function_Name( "AnniPreExchangeItem" )
	--		Set_XSCRIPT_ScriptID( 893401 )
	--		Set_XSCRIPT_Parameter(0, g_Anniversary_XunBao_CurItemPage)
	--		Set_XSCRIPT_Parameter(1, nItemIdx)
	--		Set_XSCRIPT_Parameter(2, 1)
	--		Set_XSCRIPT_Parameter(3, 1)
	--		Set_XSCRIPT_ParamCount(4)
	--	Send_XSCRIPT()	
	--end
	
end

--===============================================
-- 页签2 选择兑换池子
--===============================================
function Anniversary_XunBao_ItemPool_Clicked( nItemPool )
	if g_Anniversary_XunBao_ItemPoolInfo[nItemPool] == nil then
		return
	end
		
	if IsWindowShow("Anniversary_XunBaoMBuy") then
		CloseWindow("Anniversary_XunBaoMBuy", true)
	end
			
	if IsWindowShow("Anniversary_XunBaoChange") then
		CloseWindow("Anniversary_XunBaoChange", true)
	end
		
	if IsWindowShow("Anniversary_ThreeChoices") then
		CloseWindow("Anniversary_ThreeChoices", true)
	end
	
	g_Anniversary_XunBao_CurItemPage = nItemPool
	
	for i = 1, table.getn(g_Anniversary_XunBao_ItemList) do		
		if i == nItemPool then
			g_Anniversary_XunBao_ItemList[i]:SetCheck(1)
		else
			g_Anniversary_XunBao_ItemList[i]:SetCheck(0)
		end
	end
	
	--if nItemPool == 1 or nItemPool == 4 then
		Anniversary_XunBao_Client2_RightFrameBK_List:SetProperty("VScrollMode", "Hide")
	--else
	--	Anniversary_XunBao_Client2_RightFrameBK_List:SetProperty("VScrollMode", "Show")
	--end
	
	for i = 1, table.getn(g_XunBao_nDuiHuanContentButton) do
		g_XunBao_nDuiHuanContentButton[i]:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon"):SetActionItem(-1)
	end			
	Anniversary_XunBao_Client2_RightFrameBK_List:Clear()		
	g_XunBao_nDuiHuanContentButton = {}
	
	for i = 1, table.getn(g_Anniversary_XunBao_ItemPoolInfo[nItemPool]) do
		local bar = Anniversary_XunBao_Client2_RightFrameBK_List:AddChild("Anniversary_XunBao_Client2_Shop_ItemBK")
		if nil ~= bar then
			local str = ""
			if g_Anniversary_XunBao_ItemPoolInfo[nItemPool][i] ~= nil then
				-- 物品信息
				local GiftItemID = g_Anniversary_XunBao_ItemPoolInfo[nItemPool][i].itemid
				local GiftCount = g_Anniversary_XunBao_ItemPoolInfo[nItemPool][i].itemnum
				local GiftMaxCount = g_Anniversary_XunBao_ItemPoolInfo[nItemPool][i].exchangemax
				local GiftCost = g_Anniversary_XunBao_ItemPoolInfo[nItemPool][i].costnum
				local GiftBuyCount = g_Anniversary_XunBao_ItemPoolInfo[nItemPool][i].havebuy
				-- icon
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon"):Show()
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon"):SetActionItem(theAction:GetID());
				end
				bar:SetSubItemEvent("Anniversary_XunBao_Client2_Shop_Item_Icon", "Clicked", "Anniversary_XunBao_Item_Clicked("..i..")")	
				
				-- 名字
				str = DataPool:Lua_GetItemNameByIndex(GiftItemID)
				bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_ItemName"):Show()
				bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_ItemName"):SetText("#L"..str)
				
				-- 代币值
				bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_MoneyText"):Show()
				bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_MoneyText"):SetText("#L"..tostring(GiftCost))
				bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_MoneyIcon"):SetProperty("Image", g_Anniversary_XunBao_DaiBiImageSmall[nItemPool])				
				
				if GiftMaxCount > 0 then
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_BuyLimit"):Show()	
					
					-- 限购数量
					if GiftBuyCount >= GiftMaxCount then
						bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_BuyLimitNumBK"):Hide()
						bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_SellOut"):Show()
						bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_Mask"):Show()
					else
						bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_BuyLimitNumBK"):Show()
						bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_BuyLimitNum"):SetText(tostring(GiftMaxCount-GiftBuyCount))
						bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_SellOut"):Hide()
						bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_Mask"):Hide()
					end
				else
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_BuyLimit"):Hide()	
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_SellOut"):Hide()
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_Mask"):Hide()
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_Item_Icon_BuyLimitNumBK"):Hide()
				end
				
				--时装显示大眼睛
				bar:GetSubItem("Anniversary_XunBao_Client2_Shop_EyeSign"):Hide()
				if GiftItemID == 39924020 then
					bar:GetSubItem("Anniversary_XunBao_Client2_Shop_EyeSign"):Show()
					bar:SetSubItemEvent("Anniversary_XunBao_Client2_Shop_EyeSign", "Clicked", "Anniversary_XunBao_EyeSign_Clicked()")	
				end				
				
				g_XunBao_nDuiHuanContentButton[i] = bar
			end
		end
	end
	
end

--===============================================
-- 页签3 领取返利
--===============================================
function Anniversary_XunBao_Reward_Click( nFanLiIdx )
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreGetFanLi" )
		Set_XSCRIPT_ScriptID(893401)
		Set_XSCRIPT_Parameter(0, nFanLiIdx)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_Parameter(2, 1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	
end

function Anniversary_XunBao_Blessing_BtnClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenQiFuUI")
		Set_XSCRIPT_ScriptID(893403)
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
		
end

function Anniversary_XunBao_RightFrame_Ticket_BtnClick()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetXingJiuLing")
		Set_XSCRIPT_ScriptID(893401)
		Set_XSCRIPT_Parameter(0, g_Anniversary_XunBao_CurSubPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
		
end

function Anniversary_XunBao_EyeSign_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10126957)
		Set_XSCRIPT_Parameter(1, 162)	-- hairId
		Set_XSCRIPT_Parameter(2, 128)	-- faceId
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	
end




