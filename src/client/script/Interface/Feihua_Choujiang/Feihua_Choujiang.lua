
local g_Feihua_Choujiang_UnifiedPosition

--普通奖池的奖励 (临时)
local g_NormalRewardItem = 
{
	[1] = {itemId = 38005574, num = 1, highLight = 0},
	[2] = {itemId = 38005579, num = 1, highLight = 1},
	[3] = {itemId = 38005574, num = 1, highLight = 0},
	[4] = {itemId = 38005574, num = 3, highLight = 0},
	[5] = {itemId = 38005574, num = 5, highLight = 0},
	[6] = {itemId = 38005574, num = 5, highLight = 0},
	[7] = {itemId = 38005574, num = 3, highLight = 0},
}

--升级后的奖池奖励 (临时)
local g_LevelUpRewardItem = 
{
	[1] = {itemId = 38005574, num = 5, highLight = 0},
	[2] = {itemId = 10146779, num = 1, highLight = 1},
	[3] = {itemId = 38005574, num = 5, highLight = 0},
	[4] = {itemId = 38005579, num = 1, highLight = 1},
	[5] = {itemId = 38005574, num = 10, highLight = 0},
	[6] = {itemId = 38005574, num = 10, highLight = 0},
	[7] = {itemId = 38005502, num = 1, highLight = 1},
}
local g_RewardItemId = -1
local g_RewardNum = 0
local g_isLevelUpReward = 0
local g_rewardIndex = 1
local g_RewardItemUITalbe = {}
local g_AnimateStep = 1
local g_AnimateCircleCount = 1
local g_AnimateCirCleMax = 3
local g_IsAnimateCircleEnd = 0
local g_AnimateSpeed = {80,50,85,60,78,50,65}
function Feihua_Choujiang_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function Feihua_Choujiang_OnLoad()
	g_Feihua_Choujiang_UnifiedPosition = Feihua_Choujiang_FrameNULL:GetProperty("UnifiedPosition")
	g_RewardItemUITalbe = 
	{
		[1]=
		{
			ItemAction = Feihua_Choujiang_Reward1_Item,
			ItemAnimate = Feihua_Choujiang_Reward1_ItemAnimate,
			BK1 = Feihua_Choujiang_Reward1_BK1,
			BK2 = Feihua_Choujiang_Reward1_BK2,
			JinKuang = Feihua_Choujiang_Reward1_ItemBack,
		},
		[2]=
		{
			ItemAction = Feihua_Choujiang_Reward2_Item,
			ItemAnimate = Feihua_Choujiang_Reward2_ItemAnimate,
			BK1 = Feihua_Choujiang_Reward2_BK1,
			BK2 = Feihua_Choujiang_Reward2_BK2,
			JinKuang = Feihua_Choujiang_Reward2_ItemBack,
		},
		[3]=
		{
			ItemAction = Feihua_Choujiang_Reward3_Item,
			ItemAnimate = Feihua_Choujiang_Reward3_ItemAnimate,
			BK1 = Feihua_Choujiang_Reward3_BK1,
			BK2 = Feihua_Choujiang_Reward3_BK2,
			JinKuang = Feihua_Choujiang_Reward3_ItemBack,
		},
		[4]=
		{
			ItemAction = Feihua_Choujiang_Reward4_Item,
			ItemAnimate = Feihua_Choujiang_Reward4_ItemAnimate,
			BK1 = Feihua_Choujiang_Reward4_BK1,
			BK2 = Feihua_Choujiang_Reward4_BK2,
			JinKuang = Feihua_Choujiang_Reward4_ItemBack,
		},
		[5]=
		{
			ItemAction = Feihua_Choujiang_Reward5_Item,
			ItemAnimate = Feihua_Choujiang_Reward5_ItemAnimate,
			BK1 = Feihua_Choujiang_Reward5_BK1,
			BK2 = Feihua_Choujiang_Reward5_BK2,
			JinKuang = Feihua_Choujiang_Reward5_ItemBack,
		},
		[6]=
		{
			ItemAction = Feihua_Choujiang_Reward6_Item,
			ItemAnimate = Feihua_Choujiang_Reward6_ItemAnimate,
			BK1 = Feihua_Choujiang_Reward6_BK1,
			BK2 = Feihua_Choujiang_Reward6_BK2,
			JinKuang = Feihua_Choujiang_Reward6_ItemBack,
		},
		[7]=
		{
			ItemAction = Feihua_Choujiang_Reward7_Item,
			ItemAnimate = Feihua_Choujiang_Reward7_ItemAnimate,
			BK1 = Feihua_Choujiang_Reward7_BK1,
			BK2 = Feihua_Choujiang_Reward7_BK2,
			JinKuang = Feihua_Choujiang_Reward7_ItemBack,
		},
	}
end


function Feihua_Choujiang_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2021110501) then
		if this:IsVisible() then
			Feihua_Choujiang_Close()
		end
		-- Feihua_RankingList_On_ResetPos()
		g_isLevelUpReward = Get_XParam_INT(0)
		g_rewardIndex = Get_XParam_INT(1)
		Feihua_Choujiang_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2021111801) then
		Feihua_Choujiang_Close()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Feihua_Choujiang_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Feihua_Choujiang_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Feihua_Choujiang_Close()
	end

end

function Feihua_Choujiang_On_ResetPos()
	Feihua_Choujiang_FrameNULL:SetProperty("UnifiedPosition", g_Feihua_Choujiang_UnifiedPosition)

end

--界面点击关闭按钮
function Feihua_Choujiang_Close()
	this:Hide()
end

function Feihua_Choujiang_OnHide()
	KillTimer("Feihua_Choujiang_Tick()") 
	g_AnimateStep = 1
	g_AnimateCircleCount = 1
	g_IsAnimateCircleEnd = 0
	g_RewardItemId = -1
	g_RewardNum = 0
end

function Feihua_Choujiang_Open()
	this:Show()
	CloseWindow("Packet", true)
	local tempRewardItemTable = g_NormalRewardItem
	if g_isLevelUpReward == 1 then
		tempRewardItemTable = g_LevelUpRewardItem
	end

	for  i = 1, 7 do
		local ItemID = tempRewardItemTable[i].itemId
		local theAction = DataPool:CreateActionItemForShow(ItemID, tempRewardItemTable[i].num)
   		if theAction:GetID() ~= 0 then
			g_RewardItemUITalbe[i].ItemAction:SetActionItem(theAction:GetID())
			g_RewardItemUITalbe[i].ItemAction:Show()
		end
		g_RewardItemUITalbe[i].ItemAnimate:Hide()
		if tempRewardItemTable[i].highLight == 1 then
			g_RewardItemUITalbe[i].BK2:Show()
			g_RewardItemUITalbe[i].BK1:Hide()
			g_RewardItemUITalbe[i].JinKuang:Show()
		else
			g_RewardItemUITalbe[i].BK2:Hide()
			g_RewardItemUITalbe[i].BK1:Show()
			g_RewardItemUITalbe[i].JinKuang:Hide()
		end
	end
	if g_rewardIndex>0 then  --g_rewardIndex小于0时抽奖界面仅作为查看奖励的展示
		g_RewardItemId = tempRewardItemTable[g_rewardIndex].itemId
		g_RewardNum = tempRewardItemTable[g_rewardIndex].num
		g_RewardItemUITalbe[g_AnimateStep].ItemAnimate:Show()
		SetTimer("Feihua_Choujiang","Feihua_Choujiang_Tick()", g_AnimateSpeed[g_AnimateStep])
	end

end

--转三圈之后 走到抽中的位置
function Feihua_Choujiang_Tick()
	-- PushDebugMessage("g_rewardIndex:"..tostring(g_rewardIndex))
	g_RewardItemUITalbe[g_AnimateStep].ItemAnimate:Hide()
	if g_AnimateStep >= 7 then
		g_AnimateStep = 1
		if g_AnimateCircleCount < g_AnimateCirCleMax and g_IsAnimateCircleEnd == 0 then
			g_AnimateCircleCount = g_AnimateCircleCount + 1 
		else
			-- PushDebugMessage("g_rewardIndex:"..tostring(g_rewardIndex))
			g_IsAnimateCircleEnd = 1
		end
	else
		g_AnimateStep = g_AnimateStep + 1 
	end
	g_RewardItemUITalbe[g_AnimateStep].ItemAnimate:Show()
	KillTimer("Feihua_Choujiang_Tick()") 
	if g_AnimateStep == g_rewardIndex and g_IsAnimateCircleEnd == 1 then
		-- g_RewardItemUITalbe[g_AnimateStep].BK2:Show()
		PushDebugMessage( ScriptGlobal_Format("#{FHJY_211025_48}", g_RewardNum, DataPool:Lua_GetItemNameByIndex(g_RewardItemId)) )
	else
		SetTimer("Feihua_Choujiang","Feihua_Choujiang_Tick()", g_AnimateSpeed[g_AnimateStep])
	end
	
end