
--ThreeCity_JZTH
local g_ThreeCity_JZTH_UnifiedPosition;

local ThreeCity_JZTH_CostBing = 0
local ThreeCity_JZTH_HaveGetAwards = {0, 0, 0, 0, 0, 0}
local ThreeCity_JZTH_RewardList = {}
local ThreeCity_JZTH_AnimateTick = 0

local ThreeCity_JZTH_NeedBing = 0
local ThreeCity_JZTH_NeedJiang = 0
local ThreeCity_JZTH_HaveBing = 0
local ThreeCity_JZTH_HaveJiang = 0
local ThreeCity_JZTH_NextTimes = 0
local ThreeCity_JZTH_CurPage = 1
local ThreeCity_JZTH_PageList = {}
local ThreeCity_JZTH_PageSubList = {}
local ThreeCity_JZTH_Result = ""
local ThreeCity_JZTH_ResultItemId = 0
local ThreeCity_JZTH_ResultItemNum = 0
local ThreeCity_JZTH_ResultItembind = 0
local ThreeCity_JZTH_ResultLevelUp = 0
local ThreeCity_JZTH_ResultNextTimes = 0

local ThreeCity_JZTH_Displacement = {
	[1] = {startpos = {65.0, 63.0}, endpos = {65.0, 63.0}},
	[2] = {startpos = {65.0, 63.0}, endpos = {164.0, 102.0}},
	[3] = {startpos = {219.0, 129.0}, endpos = {128.0, 181.0}},
	[4] = {startpos = {142.0, 230.0}, endpos = {299.0, 195.0}},
	[5] = {startpos = {355.0, 158.0}, endpos = {434.0, 106.0}},
	[6] = {startpos = {504.0, 71.0}, endpos = {625.0, 73.0}},
	[7] = {startpos = {622.0, 120.0}, endpos = {425.0, 170.0}},
	[8] = {startpos = {472.0, 219.0}, endpos = {613.0, 212.0}},
}

local ThreeCity_JZTH_ShowUI = {
	1,1,0,1,1,1,0,1
}

local ThreeCity_JZTH_AwardCostNeed = {
	[1] = {40, "#{DBXH_220811_18}", "#{DBXH_220811_29}"},
	[2] = {80, "#{DBXH_220811_20}", "#{DBXH_220811_30}"},
	[3] = {160, "#{DBXH_220811_21}", "#{DBXH_220811_31}"},
	[4] = {240, "#{DBXH_220811_22}", "#{DBXH_220811_32}"},
	[5] = {360, "#{DBXH_220811_23}", "#{DBXH_220811_33}"},
	[6] = {480, "#{DBXH_220811_82}", "#{DBXH_220811_84}"},
}

local ThreeCity_JZTH_CityList = {}

function ThreeCity_JZTH_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
end

function ThreeCity_JZTH_OnLoad()	

	g_ThreeCity_JZTH_UnifiedPosition = ThreeCity_JZTH_Frame:GetProperty("UnifiedPosition")
	
	ThreeCity_JZTH_RewardList = {
		[1] = {ThreeCity_JZTH_Client2_Reward_Lace1Item_Mask, ThreeCity_JZTH_Client2_Reward_Lace1Item_RedDot, ThreeCity_JZTH_Client2_Reward_Lace1Item_Tip, ThreeCity_JZTH_Client2_Reward_Lace1Item},
		[2] = {ThreeCity_JZTH_Client2_Reward_Lace2Item_Mask, ThreeCity_JZTH_Client2_Reward_Lace2Item_RedDot, ThreeCity_JZTH_Client2_Reward_Lace2Item_Tip, ThreeCity_JZTH_Client2_Reward_Lace2Item},
		[3] = {ThreeCity_JZTH_Client2_Reward_Lace3Item_Mask, ThreeCity_JZTH_Client2_Reward_Lace3Item_RedDot, ThreeCity_JZTH_Client2_Reward_Lace3Item_Tip, ThreeCity_JZTH_Client2_Reward_Lace3Item},
		[4] = {ThreeCity_JZTH_Client2_Reward_Lace4Item_Mask, ThreeCity_JZTH_Client2_Reward_Lace4Item_RedDot, ThreeCity_JZTH_Client2_Reward_Lace4Item_Tip, ThreeCity_JZTH_Client2_Reward_Lace4Item},
		[5] = {ThreeCity_JZTH_Client2_Reward_Lace5Item_Mask, ThreeCity_JZTH_Client2_Reward_Lace5Item_RedDot, ThreeCity_JZTH_Client2_Reward_Lace5Item_Tip, ThreeCity_JZTH_Client2_Reward_Lace5Item},
		[6] = {ThreeCity_JZTH_Client2_Reward_Lace6Item_Mask, ThreeCity_JZTH_Client2_Reward_Lace6Item_RedDot, ThreeCity_JZTH_Client2_Reward_Lace6Item_Tip, ThreeCity_JZTH_Client2_Reward_Lace6Item},
	}
	
	ThreeCity_JZTH_PageList = {
		[1] = ThreeCity_JZTH_level1_Reward, 
		[2] = ThreeCity_JZTH_level2_Reward, 
		[3] = ThreeCity_JZTH_level3_Reward, 
		[4] = ThreeCity_JZTH_level4_Reward, 
		[5] = ThreeCity_JZTH_level5_Reward, 
		[6] = ThreeCity_JZTH_level6_Reward, 
		[7] = ThreeCity_JZTH_level7_Reward, 
		[8] = ThreeCity_JZTH_level8_Reward, 
	}
	
	ThreeCity_JZTH_CityList = {
		[2] = ThreeCity_JZTH_Animation_City2,
		[3] = ThreeCity_JZTH_Animation_City3,
		[4] = ThreeCity_JZTH_Animation_City4,
		[5] = ThreeCity_JZTH_Animation_City5,
		[6] = ThreeCity_JZTH_Animation_City6,
		[7] = ThreeCity_JZTH_Animation_City7,
		[8] = ThreeCity_JZTH_Animation_City8,
	}
	
	ThreeCity_JZTH_PageSubList = {
		[1] = { 
				[1] = {ThreeCity_JZTH_level1_Reward1_Item, ThreeCity_JZTH_level1_Reward1_ItemAnimate, ThreeCity_JZTH_level1_Reward1_ItemText},
				[2] = {ThreeCity_JZTH_level1_Reward2_Item, ThreeCity_JZTH_level1_Reward2_ItemAnimate, ThreeCity_JZTH_level1_Reward2_ItemText}, 
				[3] = {ThreeCity_JZTH_level1_Reward3_Item, ThreeCity_JZTH_level1_Reward3_ItemAnimate, ThreeCity_JZTH_level1_Reward3_ItemText}, 
				[4] = {ThreeCity_JZTH_level1_Reward4_Item, ThreeCity_JZTH_level1_Reward4_ItemAnimate, ThreeCity_JZTH_level1_Reward4_ItemText}, 
				[5] = {ThreeCity_JZTH_level1_Reward5_Item, ThreeCity_JZTH_level1_Reward5_ItemAnimate, ThreeCity_JZTH_level1_Reward5_ItemText},
			},
		[2] = { 
				[1] = {ThreeCity_JZTH_level2_Reward1_Item, ThreeCity_JZTH_level2_Reward1_ItemAnimate, ThreeCity_JZTH_level2_Reward1_ItemText},
				[2] = {ThreeCity_JZTH_level2_Reward2_Item, ThreeCity_JZTH_level2_Reward2_ItemAnimate, ThreeCity_JZTH_level2_Reward2_ItemText},
				[3] = {ThreeCity_JZTH_level2_Reward3_Item, ThreeCity_JZTH_level2_Reward3_ItemAnimate, ThreeCity_JZTH_level2_Reward3_ItemText},
				[4] = {ThreeCity_JZTH_level2_Reward4_Item, ThreeCity_JZTH_level2_Reward4_ItemAnimate, ThreeCity_JZTH_level2_Reward4_ItemText},
				[5] = {ThreeCity_JZTH_level2_Reward5_Item, ThreeCity_JZTH_level2_Reward5_ItemAnimate, ThreeCity_JZTH_level2_Reward5_ItemText},
				[6] = {ThreeCity_JZTH_level2_Reward6_Item, ThreeCity_JZTH_level2_Reward6_ItemAnimate, ThreeCity_JZTH_level2_Reward6_ItemText},
			},
		[3] = { 
				[1] = {ThreeCity_JZTH_level3_Reward1_Item, ThreeCity_JZTH_level3_Reward1_ItemAnimate, ThreeCity_JZTH_level3_Reward1_ItemText},
				[2] = {ThreeCity_JZTH_level3_Reward2_Item, ThreeCity_JZTH_level3_Reward2_ItemAnimate, ThreeCity_JZTH_level3_Reward2_ItemText},
				[3] = {ThreeCity_JZTH_level3_Reward3_Item, ThreeCity_JZTH_level3_Reward3_ItemAnimate, ThreeCity_JZTH_level3_Reward3_ItemText},
				[4] = {ThreeCity_JZTH_level3_Reward4_Item, ThreeCity_JZTH_level3_Reward4_ItemAnimate, ThreeCity_JZTH_level3_Reward4_ItemText},
				[5] = {ThreeCity_JZTH_level3_Reward5_Item, ThreeCity_JZTH_level3_Reward5_ItemAnimate, ThreeCity_JZTH_level3_Reward5_ItemText},
				[6] = {ThreeCity_JZTH_level3_Reward6_Item, ThreeCity_JZTH_level3_Reward6_ItemAnimate, ThreeCity_JZTH_level3_Reward6_ItemText},
			},
		[4] = { 
				[1] = {ThreeCity_JZTH_level4_Reward1_Item, ThreeCity_JZTH_level4_Reward1_ItemAnimate, ThreeCity_JZTH_level4_Reward1_ItemText}, 
				[2] = {ThreeCity_JZTH_level4_Reward2_Item, ThreeCity_JZTH_level4_Reward2_ItemAnimate, ThreeCity_JZTH_level4_Reward2_ItemText}, 
				[3] = {ThreeCity_JZTH_level4_Reward3_Item, ThreeCity_JZTH_level4_Reward3_ItemAnimate, ThreeCity_JZTH_level4_Reward3_ItemText}, 
				[4] = {ThreeCity_JZTH_level4_Reward4_Item, ThreeCity_JZTH_level4_Reward4_ItemAnimate, ThreeCity_JZTH_level4_Reward4_ItemText}, 
				[5] = {ThreeCity_JZTH_level4_Reward5_Item, ThreeCity_JZTH_level4_Reward5_ItemAnimate, ThreeCity_JZTH_level4_Reward5_ItemText}, 
				[6] = {ThreeCity_JZTH_level4_Reward6_Item, ThreeCity_JZTH_level4_Reward6_ItemAnimate, ThreeCity_JZTH_level4_Reward6_ItemText}, 
				[7] = {ThreeCity_JZTH_level4_Reward7_Item, ThreeCity_JZTH_level4_Reward7_ItemAnimate, ThreeCity_JZTH_level4_Reward7_ItemText}, 
			},
		[5] = { 
				[1] = {ThreeCity_JZTH_level5_Reward1_Item, ThreeCity_JZTH_level5_Reward1_ItemAnimate, ThreeCity_JZTH_level5_Reward1_ItemText}, 
				[2] = {ThreeCity_JZTH_level5_Reward2_Item, ThreeCity_JZTH_level5_Reward2_ItemAnimate, ThreeCity_JZTH_level5_Reward2_ItemText},
				[3] = {ThreeCity_JZTH_level5_Reward3_Item, ThreeCity_JZTH_level5_Reward3_ItemAnimate, ThreeCity_JZTH_level5_Reward3_ItemText},
				[4] = {ThreeCity_JZTH_level5_Reward4_Item, ThreeCity_JZTH_level5_Reward4_ItemAnimate, ThreeCity_JZTH_level5_Reward4_ItemText},
				[5] = {ThreeCity_JZTH_level5_Reward5_Item, ThreeCity_JZTH_level5_Reward5_ItemAnimate, ThreeCity_JZTH_level5_Reward5_ItemText},
				[6] = {ThreeCity_JZTH_level5_Reward6_Item, ThreeCity_JZTH_level5_Reward6_ItemAnimate, ThreeCity_JZTH_level5_Reward6_ItemText},
				[7] = {ThreeCity_JZTH_level5_Reward7_Item, ThreeCity_JZTH_level5_Reward7_ItemAnimate, ThreeCity_JZTH_level5_Reward7_ItemText},
			},
		[6] = { 
				[1] = {ThreeCity_JZTH_level6_Reward1_Item, ThreeCity_JZTH_level6_Reward1_ItemAnimate, ThreeCity_JZTH_level6_Reward1_ItemText}, 
				[2] = {ThreeCity_JZTH_level6_Reward2_Item, ThreeCity_JZTH_level6_Reward2_ItemAnimate, ThreeCity_JZTH_level6_Reward2_ItemText}, 
				[3] = {ThreeCity_JZTH_level6_Reward3_Item, ThreeCity_JZTH_level6_Reward3_ItemAnimate, ThreeCity_JZTH_level6_Reward3_ItemText}, 
				[4] = {ThreeCity_JZTH_level6_Reward4_Item, ThreeCity_JZTH_level6_Reward4_ItemAnimate, ThreeCity_JZTH_level6_Reward4_ItemText}, 
				[5] = {ThreeCity_JZTH_level6_Reward5_Item, ThreeCity_JZTH_level6_Reward5_ItemAnimate, ThreeCity_JZTH_level6_Reward5_ItemText}, 
				[6] = {ThreeCity_JZTH_level6_Reward6_Item, ThreeCity_JZTH_level6_Reward6_ItemAnimate, ThreeCity_JZTH_level6_Reward6_ItemText}, 
				[7] = {ThreeCity_JZTH_level6_Reward7_Item, ThreeCity_JZTH_level6_Reward7_ItemAnimate, ThreeCity_JZTH_level6_Reward7_ItemText}, 
			},
		[7] = { 
				[1] = {ThreeCity_JZTH_level7_Reward1_Item, ThreeCity_JZTH_level7_Reward1_ItemAnimate, ThreeCity_JZTH_level7_Reward1_ItemText}, 
				[2] = {ThreeCity_JZTH_level7_Reward2_Item, ThreeCity_JZTH_level7_Reward2_ItemAnimate, ThreeCity_JZTH_level7_Reward2_ItemText}, 
				[3] = {ThreeCity_JZTH_level7_Reward3_Item, ThreeCity_JZTH_level7_Reward3_ItemAnimate, ThreeCity_JZTH_level7_Reward3_ItemText}, 
				[4] = {ThreeCity_JZTH_level7_Reward4_Item, ThreeCity_JZTH_level7_Reward4_ItemAnimate, ThreeCity_JZTH_level7_Reward4_ItemText}, 
				[5] = {ThreeCity_JZTH_level7_Reward5_Item, ThreeCity_JZTH_level7_Reward5_ItemAnimate, ThreeCity_JZTH_level7_Reward5_ItemText}, 
				[6] = {ThreeCity_JZTH_level7_Reward6_Item, ThreeCity_JZTH_level7_Reward6_ItemAnimate, ThreeCity_JZTH_level7_Reward6_ItemText}, 
				[7] = {ThreeCity_JZTH_level7_Reward7_Item, ThreeCity_JZTH_level7_Reward7_ItemAnimate, ThreeCity_JZTH_level7_Reward7_ItemText}, 
			},
		[8] = { 
				[1] = {ThreeCity_JZTH_level8_Reward1_Item, ThreeCity_JZTH_level8_Reward1_ItemAnimate, ThreeCity_JZTH_level8_Reward1_ItemText}, 
				[2] = {ThreeCity_JZTH_level8_Reward2_Item, ThreeCity_JZTH_level8_Reward2_ItemAnimate, ThreeCity_JZTH_level8_Reward2_ItemText},
				[3] = {ThreeCity_JZTH_level8_Reward3_Item, ThreeCity_JZTH_level8_Reward3_ItemAnimate, ThreeCity_JZTH_level8_Reward3_ItemText},
				[4] = {ThreeCity_JZTH_level8_Reward4_Item, ThreeCity_JZTH_level8_Reward4_ItemAnimate, ThreeCity_JZTH_level8_Reward4_ItemText},
				[5] = {ThreeCity_JZTH_level8_Reward5_Item, ThreeCity_JZTH_level8_Reward5_ItemAnimate, ThreeCity_JZTH_level8_Reward5_ItemText},
				[6] = {ThreeCity_JZTH_level8_Reward6_Item, ThreeCity_JZTH_level8_Reward6_ItemAnimate, ThreeCity_JZTH_level8_Reward6_ItemText},
				[7] = {ThreeCity_JZTH_level8_Reward7_Item, ThreeCity_JZTH_level8_Reward7_ItemAnimate, ThreeCity_JZTH_level8_Reward7_ItemText},
				[8] = {ThreeCity_JZTH_level8_Reward8_Item, ThreeCity_JZTH_level8_Reward8_ItemAnimate, ThreeCity_JZTH_level8_Reward8_ItemText},
				[9] = {ThreeCity_JZTH_level8_Reward9_Item, ThreeCity_JZTH_level8_Reward9_ItemAnimate, ThreeCity_JZTH_level8_Reward9_ItemText},
			},
	}
	
end

function ThreeCity_JZTH_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99824401 ) then
	
		local operator = Get_XParam_INT(0)
		if operator == 1 then
		
			ThreeCity_JZTH_HaveBing = Get_XParam_INT(1)
			ThreeCity_JZTH_HaveJiang = Get_XParam_INT(2)	
			ThreeCity_JZTH_CurPage = Get_XParam_INT(3)
			ThreeCity_JZTH_CostBing = Get_XParam_INT(4)
			ThreeCity_JZTH_NeedBing = Get_XParam_INT(5)
			ThreeCity_JZTH_NeedJiang = Get_XParam_INT(6)
			ThreeCity_JZTH_NextTimes = Get_XParam_INT(7)
			ThreeCity_JZTH_Result = Get_XParam_STR(0)
			
			for i = 1, table.getn(ThreeCity_JZTH_HaveGetAwards) do
				ThreeCity_JZTH_HaveGetAwards[i] = Get_XParam_INT(7+i)
			end
			
			ThreeCity_JZTH_Open()
		else
			ThreeCity_JZTH_Close()
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99824403 and this:IsVisible() ) then
	
		ThreeCity_JZTH_HaveBing = Get_XParam_INT(0) 
		ThreeCity_JZTH_HaveJiang = Get_XParam_INT(1) 
		
		ThreeCity_JZTH_UpdateDaiBi()
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99824404 and this:IsVisible() ) then
	
		ThreeCity_JZTH_CostBing = Get_XParam_INT(0)
		for i = 1, table.getn(ThreeCity_JZTH_HaveGetAwards) do
			ThreeCity_JZTH_HaveGetAwards[i] = Get_XParam_INT(i)
		end
		
		ThreeCity_JZTH_UpdateAwards()
		
	elseif (event == "ADJEST_UI_POS" ) then
		ThreeCity_JZTH_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCity_JZTH_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ThreeCity_JZTH_Close()
		
	end

end

--=========================================================
--更新界面
--=========================================================
function ThreeCity_JZTH_Open()
		
	ThreeCity_JZTH_CleanUp()
	
	ThreeCity_JZTH_UpdateDaiBi()
	
	ThreeCity_JZTH_UpdateResult()
	
	ThreeCity_JZTH_UpdatePage()
	
	ThreeCity_JZTH_UpdateAwards()

	this:Show()
	
end	

--=========================================================
-- 刷新代币
--=========================================================
function ThreeCity_JZTH_UpdateDaiBi()
	
	-- 兵符
	local str = ScriptGlobal_Format("#{DBXH_220811_49}", ThreeCity_JZTH_HaveBing)
	ThreeCity_JZTH_Bing:SetText(str)
	
	-- 将令
	str = ScriptGlobal_Format("#{DBXH_220811_50}", ThreeCity_JZTH_HaveJiang)
	ThreeCity_JZTH_Jiang:SetText(str)
	
end

function ThreeCity_JZTH_UpdateResult()
			
	if ThreeCity_JZTH_Result ~= "" then
		local strItem = ThreeCity_JZTH_Result
		local iPos = string.find( strItem, "*" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)	
			ThreeCity_JZTH_ResultItemId = tonumber(tempstr)
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end
		iPos = string.find( strItem, "*" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)	
			ThreeCity_JZTH_ResultItemNum = tonumber(tempstr)
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end
		iPos = string.find( strItem, "*" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)	
			ThreeCity_JZTH_ResultItembind = tonumber(tempstr)
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end		
		iPos = string.find( strItem, "*" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)	
			ThreeCity_JZTH_ResultLevelUp = tonumber(tempstr)
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end
		iPos = string.find( strItem, "*" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)	
			ThreeCity_JZTH_ResultNextTimes = tonumber(tempstr)
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end		
	else
		ThreeCity_JZTH_ResultItemId = 0
		ThreeCity_JZTH_ResultItemNum = 0
		ThreeCity_JZTH_ResultItembind = 0
		ThreeCity_JZTH_ResultLevelUp = 0
		ThreeCity_JZTH_ResultNextTimes = 0
	end
	
end

--=========================================================
-- 刷新奖池
--=========================================================
function ThreeCity_JZTH_UpdatePage()

	for i = 1, table.getn(ThreeCity_JZTH_PageList) do
		if ThreeCity_JZTH_CurPage == i then
			ThreeCity_JZTH_PageList[i]:Show()
		else
			ThreeCity_JZTH_PageList[i]:Hide()
		end
	end
	
	if ThreeCity_JZTH_CurPage == Lua_GetJianZhiTianHuangInfoCount() then
		ThreeCity_JZTH_Exchange:Show()
		ThreeCity_JZTH_Exchange:Enable()
		ThreeCity_JZTH_LevelUp:Hide()
		ThreeCity_JZTH_LevelUp:Disable()
		ThreeCity_JZTH_LevelUpText:Hide()
		ThreeCity_JZTH_LevelUpText2:Hide()
				
		ThreeCity_JZTH_Start:SetProperty("UnifiedPosition", "{{0.500000,-37.500000},{0.000000,365.000000}}")
		ThreeCity_JZTH_StartText:SetProperty("UnifiedPosition", "{{0.500000,-44.500000},{0.000000,400.000000}}")
	else
		ThreeCity_JZTH_Exchange:Hide()
		ThreeCity_JZTH_Exchange:Disable()
		ThreeCity_JZTH_LevelUp:Show()
		ThreeCity_JZTH_LevelUp:Enable()
		ThreeCity_JZTH_LevelUpText:Show()
		ThreeCity_JZTH_LevelUpText2:Show()
		
		ThreeCity_JZTH_Start:SetProperty("UnifiedPosition", "{{0.500000,-148.000000},{0.000000,366.000000}}")
		ThreeCity_JZTH_StartText:SetProperty("UnifiedPosition", "{{0.500000,-148.000000},{0.000000,400.000000}}")
	end
	
	ThreeCity_JZTH_MainFrame_VFX1:Hide()
	ThreeCity_JZTH_MainFrame_VFX2:Hide()
	ThreeCity_JZTH_MainFrame_VFX3:Hide()
	
	if ThreeCity_JZTH_PageList[ThreeCity_JZTH_CurPage] ~= nil and ThreeCity_JZTH_PageSubList[ThreeCity_JZTH_CurPage] ~=nil then
		for i = 1, table.getn(ThreeCity_JZTH_PageSubList[ThreeCity_JZTH_CurPage]) do
			local nItemId, nItemCnt, nItemShowId, nItemBind = Lua_GetJianZhiTianHuangItemInfo(ThreeCity_JZTH_CurPage, i)	
			if nItemId > 0 and nItemCnt > 0 then				
				local theAction = DataPool:CreateActionItemForShow(nItemShowId, nItemCnt)
				if theAction:GetID() ~= 0 then
					ThreeCity_JZTH_PageSubList[ThreeCity_JZTH_CurPage][i][1]:Show()
					ThreeCity_JZTH_PageSubList[ThreeCity_JZTH_CurPage][i][1]:SetActionItem( theAction:GetID() )
					
					local strName = ScriptGlobal_Format("#{DBXH_220811_130}", DataPool:Lua_GetItemNameByIndex(nItemId))
					ThreeCity_JZTH_PageSubList[ThreeCity_JZTH_CurPage][i][3]:SetText(strName)
				else
					ThreeCity_JZTH_PageSubList[ThreeCity_JZTH_CurPage][i][1]:Hide()
					ThreeCity_JZTH_PageSubList[ThreeCity_JZTH_CurPage][i][1]:SetActionItem( -1 )
				end
			end			
		end
			
		-- 消耗兵符
		local str = ScriptGlobal_Format("#{DBXH_220811_79}", ThreeCity_JZTH_NeedBing)
		ThreeCity_JZTH_StartText:SetText(str)
		
		str = ScriptGlobal_Format("#{DBXH_220811_16}", ThreeCity_JZTH_NeedBing)
		ThreeCity_JZTH_Start:SetToolTip(str)
		-- 消耗兵符将令
		str = ScriptGlobal_Format("#{DBXH_220811_80}", ThreeCity_JZTH_NeedBing, ThreeCity_JZTH_NeedJiang)
		ThreeCity_JZTH_LevelUpText:SetText(str)
		
		if ThreeCity_JZTH_NextTimes <= 1 then
			str = ScriptGlobal_Format("#{DBXH_220811_120}", ThreeCity_JZTH_NeedBing, ThreeCity_JZTH_NeedJiang)
			ThreeCity_JZTH_LevelUp:SetToolTip(str)
		else
			str = ScriptGlobal_Format("#{DBXH_220811_17}", ThreeCity_JZTH_NeedBing, ThreeCity_JZTH_NeedJiang, ThreeCity_JZTH_NextTimes)
			ThreeCity_JZTH_LevelUp:SetToolTip(str)
		end
		
		if ThreeCity_JZTH_NextTimes <= 1 then
			ThreeCity_JZTH_LevelUpText2:SetText("#{DBXH_220811_125}")
		else
			str = ScriptGlobal_Format("#{DBXH_220811_124}", ThreeCity_JZTH_NextTimes)
			ThreeCity_JZTH_LevelUpText2:SetText(str)
		end
	end

	ThreeCity_JZTH_MainFrame2:Show()
	ThreeCity_JZTH_Animation_Frame:Hide()
	if ThreeCity_JZTH_ResultItemId ~= 0 and ThreeCity_JZTH_ResultItemNum ~= 0 then
		ThreeCity_JZTH_Return_Frame:Show()
		ThreeCity_JZTH_MainFrame2:Hide()
		
		local theAction = nil 
		if ThreeCity_JZTH_ResultItembind == 1 then
			theAction = DataPool:CreateBindActionItemForShow(ThreeCity_JZTH_ResultItemId, 1)
		else
			theAction = DataPool:CreateActionItemForShow(ThreeCity_JZTH_ResultItemId, 1)
		end
		if theAction ~=nil and theAction:GetID() ~= 0 then
			ThreeCity_JZTH_OnceReturn_Item2:SetActionItem( theAction:GetID() )
			local str = DataPool:Lua_GetItemNameByIndex(ThreeCity_JZTH_ResultItemId)
			local strName = ScriptGlobal_Format("#{DBXH_220811_130}", str)
			ThreeCity_JZTH_OnceReturn_Item2_Text:SetText( strName )
			
			if ThreeCity_JZTH_ResultItemNum > 1 then
				ThreeCity_JZTH_OnceReturn_Item2_Num:Show()
				ThreeCity_JZTH_OnceReturn_Item2_Num:SetText( "#e010101#cFFFFFF"..ThreeCity_JZTH_ResultItemNum )
			else
				ThreeCity_JZTH_OnceReturn_Item2_Num:Hide()
			end
			
			ThreeCity_JZTH_AnimateTick = 0
			ThreeCity_JZTH_OnceReturn_Item2_Frame:SetProperty("Alpha", 0)
			
			ThreeCity_JZTH_StopAllTimer()
			SetTimer("ThreeCity_JZTH", "ThreeCity_JZTH_OnceReturn_AnimateTimer()", 200)--计时器
		else
			ThreeCity_JZTH_OnceReturn_Item2:SetActionItem( -1 )
		end
		
		ThreeCity_JZTH_OnceReturn_Text:Hide()
		ThreeCity_JZTH_OnceReturn_Result:Hide()
		ThreeCity_JZTH_OnceReturn_Result2:Hide()
				
		if ThreeCity_JZTH_ResultLevelUp == 1 then
			ThreeCity_JZTH_OnceReturn_Text:Show()
			ThreeCity_JZTH_OnceReturn_Text:SetText( "#{DBXH_220811_106}" )
			
			ThreeCity_JZTH_OnceReturn_Result:Show()
			ThreeCity_JZTH_OnceReturn_Result:Play(true)	
			
			SetTimer("ThreeCity_JZTH", "ThreeCity_JZTH_OnceReturn_ResultTimer()", 1800)
		else
			if ThreeCity_JZTH_ResultNextTimes > 0 then
				ThreeCity_JZTH_OnceReturn_Text:Show()
				ThreeCity_JZTH_OnceReturn_Text:SetText( ScriptGlobal_Format("#{DBXH_220811_107}", ThreeCity_JZTH_ResultNextTimes) )				
			end
		end
	else
		ThreeCity_JZTH_Return_Frame:Hide()
		ThreeCity_JZTH_MainFrame2:Show()
	end
	
end

--=========================================================
-- 刷新累计奖励界面
--=========================================================
function ThreeCity_JZTH_UpdateAwards()

	if table.getn(ThreeCity_JZTH_AwardCostNeed) ~= table.getn(ThreeCity_JZTH_HaveGetAwards) then
		ThreeCity_JZTH_Client2_Reward:Hide()
		return
	else
		ThreeCity_JZTH_Client2_Reward:Show()
	end
	
	ThreeCity_JZTH_TimeText:SetText(ScriptGlobal_Format("#{DBXH_220811_110}", ThreeCity_JZTH_CostBing))
	
	for i = 1, table.getn(ThreeCity_JZTH_AwardCostNeed) do
	
		ThreeCity_JZTH_RewardList[i][3]:SetText(ScriptGlobal_Format("#{DBXH_220811_39}", ThreeCity_JZTH_AwardCostNeed[i][1]))
		ThreeCity_JZTH_RewardList[i][4]:SetToolTip(ThreeCity_JZTH_AwardCostNeed[i][3])
				
		if ThreeCity_JZTH_HaveGetAwards[i] == 1 then
			-- 已领取
			ThreeCity_JZTH_RewardList[i][1]:Show()		--已领取
			ThreeCity_JZTH_RewardList[i][2]:Hide()		--红点
			--ThreeCity_JZTH_RewardList[i][3]:Hide()		--文字说明
			ThreeCity_JZTH_RewardList[i][4]:Disable()	-- 按钮
			ThreeCity_JZTH_RewardList[i][4]:SetToolTip("")
		else
			ThreeCity_JZTH_RewardList[i][1]:Hide()
			ThreeCity_JZTH_RewardList[i][4]:Enable()
			
			ThreeCity_JZTH_RewardList[i][2]:Hide()
			--ThreeCity_JZTH_RewardList[i][3]:Show()
			if ThreeCity_JZTH_CostBing >= ThreeCity_JZTH_AwardCostNeed[i][1] then
				-- 可领取
				if ThreeCity_JZTH_HaveGetAwards[i] ~= 1 then
					ThreeCity_JZTH_RewardList[i][2]:Show()
				end
				--ThreeCity_JZTH_RewardList[i][3]:SetText(ScriptGlobal_Format("#{DBXH_220811_39}", ThreeCity_JZTH_AwardCostNeed[i][1]))
				--ThreeCity_JZTH_RewardList[i][4]:SetToolTip(ThreeCity_JZTH_AwardCostNeed[i][3])
			else
				--ThreeCity_JZTH_RewardList[i][3]:SetText(ScriptGlobal_Format("#{DBXH_220811_40}", ThreeCity_JZTH_CostBing, ThreeCity_JZTH_AwardCostNeed[i][1]))
				--ThreeCity_JZTH_RewardList[i][4]:SetToolTip(ThreeCity_JZTH_AwardCostNeed[i][3])
			end
		end
		
	end
	
end

function ThreeCity_JZTH_CleanUp()
	
	for i = 1, table.getn(ThreeCity_JZTH_PageSubList) do
		for j = 1, table.getn(ThreeCity_JZTH_PageSubList[i]) do
			ThreeCity_JZTH_PageSubList[i][j][1]:SetActionItem( -1 )
		end
	end
	
	ThreeCity_JZTH_StopAllTimer()
	
end

function ThreeCity_JZTH_StopAllTimer()
	
	KillTimer("ThreeCity_JZTH_TimerProc()")
	
	KillTimer("ThreeCity_JZTH_OnceReturn_AnimateTimer()")
	
	KillTimer("ThreeCity_JZTH_OnceReturn_ResultTimer()")	
	
end

--=========================================================
-- 驰兵
--=========================================================
function ThreeCity_JZTH_ChiBing()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnJZTHWinLottery" )
		Set_XSCRIPT_ScriptID( 998244 )
		Set_XSCRIPT_Parameter(0, ThreeCity_JZTH_CurPage) 
		Set_XSCRIPT_Parameter(1, 0) 
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

--=========================================================
-- 遣将驰兵
--=========================================================
function ThreeCity_JZTH_QianJiangChiBing()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnJZTHWinLottery" )
		Set_XSCRIPT_ScriptID( 998244 )
		Set_XSCRIPT_Parameter(0, ThreeCity_JZTH_CurPage) 
		Set_XSCRIPT_Parameter(1, 1) 
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

--=========================================================
-- 兑换代币
--=========================================================
function ThreeCity_JZTH_DoExchange()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnJZTHExchange" )
		Set_XSCRIPT_ScriptID( 998244 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
	
end

--=========================================================
--小问号
--=========================================================
function ThreeCity_JZTH_ShowHelp()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnJZTHHelp" )
		Set_XSCRIPT_ScriptID( 998244 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
	
end

--=========================================================
--奖励预览
--=========================================================
function ThreeCity_JZTH_ShowAwards()

	PushEvent("UI_COMMAND", 99824402, 1)
	
end

--=========================================================
-- 累计消耗兵符返利
--=========================================================
function ThreeCity_JZTH_GetAwards(nIdx)

	if ThreeCity_JZTH_AwardCostNeed[nIdx] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetJZTHGift" )
		Set_XSCRIPT_ScriptID( 998244 )
		Set_XSCRIPT_Parameter(0, nIdx) 
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

function ThreeCity_JZTH_OnceReturn_AnimateTimer()

	ThreeCity_JZTH_AnimateTick = ThreeCity_JZTH_AnimateTick + 1
	if ThreeCity_JZTH_AnimateTick >= 10 then
		ThreeCity_JZTH_AnimateTick = 0
		ThreeCity_JZTH_OnceReturn_Item2_Frame:SetProperty("Alpha", 1)
		KillTimer("ThreeCity_JZTH_OnceReturn_AnimateTimer()")
	else
		ThreeCity_JZTH_OnceReturn_Item2_Frame:SetProperty("Alpha", ThreeCity_JZTH_AnimateTick*0.1)
	end
		
end

function ThreeCity_JZTH_OnceReturn_ResultTimer()

	ThreeCity_JZTH_StopAllTimer()
	
	ThreeCity_JZTH_OnceReturn_Result:Play(false)
	
	ThreeCity_JZTH_OnceReturn_Result2:Show()
	
end

function ThreeCity_JZTH_OnceReturn_Clicked()

	ThreeCity_JZTH_StopAllTimer()
	
	ThreeCity_JZTH_OnceReturn_Item2:SetActionItem(-1)
	ThreeCity_JZTH_Return_Frame:Hide()
	ThreeCity_JZTH_MainFrame2:Show()
		
	if ThreeCity_JZTH_ResultLevelUp == 1 then
		ThreeCity_JZTH_Animation_Frame:Show()
		ThreeCity_JZTH_MainFrame2:Hide()
		-- 定时器 开启
		ThreeCity_JZTH_Move()
		SetTimer("ThreeCity_JZTH", "ThreeCity_JZTH_TimerProc()", 4000)
	end
end

function ThreeCity_JZTH_TimerProc()

	ThreeCity_JZTH_StopAllTimer()
	
	ThreeCity_JZTH_Animation_Frame:Hide()
	ThreeCity_JZTH_MainFrame2:Show()
	
	ThreeCity_JZTH_MainFrame_VFX1:Show()
	ThreeCity_JZTH_MainFrame_VFX2:Show()
	ThreeCity_JZTH_MainFrame_VFX3:Show()
	ThreeCity_JZTH_MainFrame_VFX1:Play(true)
	ThreeCity_JZTH_MainFrame_VFX2:Play(true)
	ThreeCity_JZTH_MainFrame_VFX3:Play(true)
	
end

function ThreeCity_JZTH_Move()
	
	if ThreeCity_JZTH_CurPage <= 1 or ThreeCity_JZTH_CurPage > table.getn(ThreeCity_JZTH_Displacement) then
		return
	end
	
	if ThreeCity_JZTH_ShowUI[ThreeCity_JZTH_CurPage] ~= nil and ThreeCity_JZTH_ShowUI[ThreeCity_JZTH_CurPage] == 0 then
		ThreeCity_JZTH_Animation_Running:SetProperty("Animate", "ThreeCity_JZTH_MoveLeft")
	else
		ThreeCity_JZTH_Animation_Running:SetProperty("Animate", "ThreeCity_JZTH_Move")
	end
	
    local XDisplacementCur = ThreeCity_JZTH_Displacement[ThreeCity_JZTH_CurPage].startpos[1]
	local YDisplacementCur = ThreeCity_JZTH_Displacement[ThreeCity_JZTH_CurPage].startpos[2]
	ThreeCity_JZTH_Animation_Running:SetProperty("UnifiedPosition", "{{0.0,"..tostring(XDisplacementCur).."},{0.000000,"..tostring(YDisplacementCur).."}}")
	
    local XDisplacementNext = ThreeCity_JZTH_Displacement[ThreeCity_JZTH_CurPage].endpos[1]
    local YDisplacementNext = ThreeCity_JZTH_Displacement[ThreeCity_JZTH_CurPage].endpos[2]

    local XMove = XDisplacementNext - XDisplacementCur
    local YMove = YDisplacementNext - YDisplacementCur
    local velocity = 1.8
    local from_to_info = string.format( "curve:Liner mode:Once duration:%.1f startx:0 starty:0 endx:%d endy:%d", velocity, XMove, YMove )
    ThreeCity_JZTH_Animation_Running:Tween_SetInfo("Position", from_to_info)
    ThreeCity_JZTH_Animation_Running:Tween_Play("Position", true, false)
	
end

function ThreeCity_JZTH_TweenEnd()
	
	if ThreeCity_JZTH_CurPage <= 1 or ThreeCity_JZTH_CityList[ThreeCity_JZTH_CurPage] == nil then
		return
	end
	
	ThreeCity_JZTH_CityList[ThreeCity_JZTH_CurPage]:Play(true)
	
end

--=========================================================
-- 关闭
--=========================================================
function ThreeCity_JZTH_Close()

	ThreeCity_JZTH_CleanUp()
	
	this:Hide()
	
	if IsWindowShow("ThreeCity_JZTH_AllReward") then
		CloseWindow("ThreeCity_JZTH_AllReward", true)
	end
	
end

function ThreeCity_JZTH_OnHiden()

	ThreeCity_JZTH_Close()
	
end

--=========================================================
--刷新位置
--=========================================================
function ThreeCity_JZTH_On_ResetPos()

	ThreeCity_JZTH_Frame:SetProperty("UnifiedPosition", g_ThreeCity_JZTH_UnifiedPosition);
	
end

--=========================================================
-- 左翻页
--=========================================================
function ThreeCity_JZTH_ClickLeftArrow()
	
end

--=========================================================
-- 右翻页
--=========================================================
function ThreeCity_JZTH_ClickRightArrow()
	
end

