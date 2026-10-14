
--大富翁活动预览奖励界面
local g_Anniversary_Rich_Detail_Frame_UnifiedPosition
local g_Anniversary_Rich_Detail_RewardActionButList1 = {}
local g_Anniversary_Rich_Detail_RewardActionButList2 = {}
local g_Anniversary_Rich_Detail_RewardActionButList3 = {}

local g_Anniversary_Rich_Detail_RewardData1=
{
	[0] =
	{
		[1]={itemId=39920490, num=1, requiredCircleNum = 0},
		[2]={itemId=39923315, num=2, requiredCircleNum = 0},
		[3]={itemId=39920574, num=6, requiredCircleNum = 0},
		[4]={itemId=39920987, num=10, requiredCircleNum = 0},
		[5]={itemId=39922684, num=15, requiredCircleNum = 0},
		[6]={itemId=39920163, num=20, requiredCircleNum = 0},
	},
	[1] =
	{
		[1]={itemId=39920490, num=1, requiredCircleNum = 0},
		[2]={itemId=39920267, num=1, requiredCircleNum = 0},
		[3]={itemId=39923315, num=2, requiredCircleNum = 0},
		[4]={itemId=39920334, num=2, requiredCircleNum = 0},
		[5]={itemId=39920332, num=2, requiredCircleNum = 0},
		[6]={itemId=39920574, num=6, requiredCircleNum = 0},
	},
	--删减服自定义为1000
	[1000] = 
	{
		[1]={itemId=39920490, num=1, requiredCircleNum = 0},
		[2]={itemId=39920267, num=1, requiredCircleNum = 0},
		[3]={itemId=39923315, num=2, requiredCircleNum = 0},
		[4]={itemId=39920163, num=20, requiredCircleNum = 0},
		[5]={itemId=39920987, num=10, requiredCircleNum = 0},
		[6]={itemId=39920574, num=6, requiredCircleNum = 0},
	}
}

local g_Anniversary_Rich_Detail_RewardData2=
{
	[0] =
	{
		[1]={itemId=39920352, num=1, requiredCircleNum = 0},
		[2]={itemId=39923315, num=3, requiredCircleNum = 0},
		[3]={itemId=39920574, num=8, requiredCircleNum = 0},
		[4]={itemId=39922685, num=10, requiredCircleNum = 0},
		[5]={itemId=39920987, num=15, requiredCircleNum = 0},
		[6]={itemId=39920163, num=30, requiredCircleNum = 0},
	},
	[1] =
	{
		[1]={itemId=39920352, num=1, requiredCircleNum = 0},
		[2]={itemId=39920235, num=2, requiredCircleNum = 0},
		[3]={itemId=39923315, num=3, requiredCircleNum = 0},
		[4]={itemId=39920332, num=3, requiredCircleNum = 0},
		[5]={itemId=39920334, num=3, requiredCircleNum = 0},
		[6]={itemId=39920574, num=8, requiredCircleNum = 0},
	},
	[1000] = 
	{
		[1]={itemId=39920352, num=1, requiredCircleNum = 0},
		[2]={itemId=39920235, num=2, requiredCircleNum = 0},
		[3]={itemId=39923315, num=3, requiredCircleNum = 0},
		[4]={itemId=39920163, num=30, requiredCircleNum = 0},
		[5]={itemId=39920987, num=15, requiredCircleNum = 0},
		[6]={itemId=39920574, num=8, requiredCircleNum = 0},
	}
}

local g_Anniversary_Rich_Detail_RewardData3=
{
	[0] =
	{
		[2]={itemId=39923315, num=4, requiredCircleNum = 0},
		[4]={itemId=39920353, num=1, requiredCircleNum = 0},
		[3]={itemId=39920329, num=2, requiredCircleNum = 0},
		[1]={itemId=39925318, num=1, requiredCircleNum = 0},
		[5]={itemId=39922686, num=5, requiredCircleNum = 0},
		[6]={itemId=39920574, num=10, requiredCircleNum = 0},
		[7]={itemId=39920987, num=20, requiredCircleNum = 0},
		[8]={itemId=39922750, num=2, requiredCircleNum = 20},
	},
	[1] =
	{
		[2]={itemId=39923315, num=4, requiredCircleNum = 0},
		[4]={itemId=39920353, num=1, requiredCircleNum = 0},
		[3]={itemId=39920311, num=2, requiredCircleNum = 0},
		[1]={itemId=39925318, num=1, requiredCircleNum = 0},
		[5]={itemId=39920334, num=4, requiredCircleNum = 0},
		[6]={itemId=39920332, num=4, requiredCircleNum = 0},
		[7]={itemId=39920574, num=10, requiredCircleNum = 0},
		[8]={itemId=39920329, num=2, requiredCircleNum = 20},
	},
	[1000] =
	{
		[2]={itemId=39923315, num=4, requiredCircleNum = 0},
		[4]={itemId=39920353, num=1, requiredCircleNum = 0},
		[3]={itemId=39920311, num=2, requiredCircleNum = 0},
		[1]={itemId=39925318, num=1, requiredCircleNum = 0},
		[5]={itemId=39920987, num=20, requiredCircleNum = 0},
		[6]={itemId=38000378, num=7, requiredCircleNum = 0},
		[7]={itemId=39920574, num=10, requiredCircleNum = 0},
		[8]={itemId=39920329, num=2, requiredCircleNum = 20},
	},

}

function Anniversary_Rich_Detail_PreLoad()
	this:RegisterEvent("DAFUWENG_OPEN_REWARD_DETAIL",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
	this:RegisterEvent("DAFUWENG_CLOSE_REWARD_DETAIL",false)	
end

function Anniversary_Rich_Detail_OnLoad()
	g_Anniversary_Rich_Detail_Frame_UnifiedPosition = Anniversary_Rich_Detail_Frame:GetProperty("UnifiedPosition")

	g_Anniversary_Rich_Detail_RewardActionButList1=
	{
		Anniversary_Rich_Detail_List1_RewardItem1,
		Anniversary_Rich_Detail_List1_RewardItem2,
		Anniversary_Rich_Detail_List1_RewardItem3,
		Anniversary_Rich_Detail_List1_RewardItem4,
		Anniversary_Rich_Detail_List1_RewardItem5,
		Anniversary_Rich_Detail_List1_RewardItem6,
		Anniversary_Rich_Detail_List1_RewardItem7,
		Anniversary_Rich_Detail_List1_RewardItem8,
	}

	g_Anniversary_Rich_Detail_RewardActionButList2=
	{
		Anniversary_Rich_Detail_List2_RewardItem1,
		Anniversary_Rich_Detail_List2_RewardItem2,
		Anniversary_Rich_Detail_List2_RewardItem3,
		Anniversary_Rich_Detail_List2_RewardItem4,
		Anniversary_Rich_Detail_List2_RewardItem5,
		Anniversary_Rich_Detail_List2_RewardItem6,
		Anniversary_Rich_Detail_List2_RewardItem7,
		Anniversary_Rich_Detail_List2_RewardItem8,
	}

	g_Anniversary_Rich_Detail_RewardActionButList3=
	{
		Anniversary_Rich_Detail_List3_RewardItem1,
		Anniversary_Rich_Detail_List3_RewardItem2,
		Anniversary_Rich_Detail_List3_RewardItem3,
		Anniversary_Rich_Detail_List3_RewardItem4,
		Anniversary_Rich_Detail_List3_RewardItem5,
		Anniversary_Rich_Detail_List3_RewardItem6,
		Anniversary_Rich_Detail_List3_RewardItem7,
		Anniversary_Rich_Detail_List3_RewardItem8,
	}



end

function Anniversary_Rich_Detail_OnEvent(event)
	if event == "DAFUWENG_OPEN_REWARD_DETAIL" then
		if this:IsVisible() then
			Anniversary_Rich_Detail_Close_Clicked()
			return
		end
		this:Show()
		Anniversary_Rich_Detail_Open()
	elseif event == "DAFUWENG_CLOSE_REWARD_DETAIL" then
		Anniversary_Rich_Detail_Close_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
			Anniversary_Rich_Detail_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_Rich_Detail_Close_Clicked()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Rich_Detail_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Rich_Detail_Close_Clicked()
	end
	
end

function Anniversary_Rich_Detail_Open()

	local kjtype   = KaJi:LuaFnGetKaJiType(127)

	local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")

	if Player:GetData("IsOriginalJD") == 1 then
		kjtype = 1000
	end
	local rewardDataTable =  g_Anniversary_Rich_Detail_RewardData1[kjtype]
	if rewardDataTable == nil then
		return
	end
	local nActionButList1Count = table.getn(g_Anniversary_Rich_Detail_RewardActionButList1)

	for i = 1, nActionButList1Count do
		if nil ~= rewardDataTable[i] then
			local theAction = DataPool:CreateActionItemForShow(rewardDataTable[i].itemId, rewardDataTable[i].num)
			if theAction:GetID() ~= 0 then
				g_Anniversary_Rich_Detail_RewardActionButList1[i]:SetActionItem(theAction:GetID())
			end
		else
			g_Anniversary_Rich_Detail_RewardActionButList1[i]:Hide()
		end
	end

	rewardDataTable =  g_Anniversary_Rich_Detail_RewardData2[kjtype]
	if rewardDataTable == nil then
		return
	end
	local nActionButList2Count = table.getn(g_Anniversary_Rich_Detail_RewardActionButList2)

	for i = 1, nActionButList2Count do
		if nil ~= rewardDataTable[i] then
			local theAction = DataPool:CreateActionItemForShow(rewardDataTable[i].itemId, rewardDataTable[i].num)
			if theAction:GetID() ~= 0 then
				g_Anniversary_Rich_Detail_RewardActionButList2[i]:SetActionItem(theAction:GetID())
			end
		else
			g_Anniversary_Rich_Detail_RewardActionButList2[i]:Hide()
		end
	end

	rewardDataTable =  g_Anniversary_Rich_Detail_RewardData3[kjtype]
	if rewardDataTable == nil then
		return
	end
	local nActionButList3Count = table.getn(g_Anniversary_Rich_Detail_RewardActionButList3)

	for i = 1, nActionButList3Count do
		if nil ~= rewardDataTable[i] and Round >= rewardDataTable[i].requiredCircleNum then
			g_Anniversary_Rich_Detail_RewardActionButList3[i]:Show()
			local theAction = DataPool:CreateActionItemForShow(rewardDataTable[i].itemId, rewardDataTable[i].num)
			if theAction:GetID() ~= 0 then
				g_Anniversary_Rich_Detail_RewardActionButList3[i]:SetActionItem(theAction:GetID())
			end
		else
			g_Anniversary_Rich_Detail_RewardActionButList3[i]:Hide()
		end
	end



end


function Anniversary_Rich_Detail_On_ResetPos()
	Anniversary_Rich_Detail_Frame:SetProperty("UnifiedPosition", g_Anniversary_Rich_Detail_Frame_UnifiedPosition)

end

--hidden事件
function Anniversary_Rich_Detail_Close()
end

function Anniversary_Rich_Detail_Close_Clicked()
	this:Hide()
end

