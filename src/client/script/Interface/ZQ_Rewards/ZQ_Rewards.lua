local g_Frame_UnifiedPosition


local g_LevelLimit = 30

-- 活动奖励
local g_HuoDongJiangLi = {}
local g_HuoDongJiangLi_Normal = 
{
		[1] = {	name = "#{ZQZH_200715_16}", starttime = 20240916, endtime = 20240929, item1 = 39924790, item2 = 39920329, item3 = 39920463, item4 = 39920565, item5 = 39920566,},
		[2] = {	name = "#{ZQZH_200715_17}", starttime = 20240916, endtime = 20240929, item1 = 39923963, item2 = 39924407, item3 = 39920311, item4 = 39921139, item5 = 39921051,},
		[3] = {	name = "#{ZQZH_200715_18}", starttime = 20240916, endtime = 20240929, item1 = 39923513, item2 = 39923963, item3 = 39923514, item4 = 39920396, item5 = 39920397,},
		-- [4] = {	name = "#{GQZH_200714_29}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = 399227010,},
		-- [5] = {	name = "#{GQZH_200714_30}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = -1, item5 = -1,},
		-- [6] = {	name = "#{GQZH_200714_31}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
		-- [7] = {	name = "#{GQZH_200714_32}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = -1, item5 = -1,},
		-- [8] = {	name = "#{GQZH_200714_33}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
		--[9] = {	name = "#{GQZH_200714_34}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = -1, item5 = -1,},
		--[10] = {	name = "#{GQZH_200714_35}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
}

-- 活动奖励
local g_HuoDongJiangLi_KJ = 
{
		[1] = {	name = "#{ZQZH_200715_16}", starttime = 20240916, endtime = 20240929, item1 = 39924790, item2 = 39920329, item3 = 39920463, item4 = 39920565, item5 = 39920566,},
		[2] = {	name = "#{ZQZH_200715_17}", starttime = 20240916, endtime = 20240929, item1 = 39923963, item2 = 39924407, item3 = 39920311, item4 = 39921139, item5 = 39921051,},
		[3] = {	name = "#{ZQZH_200715_18}", starttime = 20240916, endtime = 20240929, item1 = 39923971, item2 = 39923963, item3 = 39923514, item4 = 39920396, item5 = 39920397,},
		-- [4] = {	name = "#{GQZH_200714_29}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = 399227010,},
		-- [5] = {	name = "#{GQZH_200714_30}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = -1, item5 = -1,},
		-- [6] = {	name = "#{GQZH_200714_31}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
		-- [7] = {	name = "#{GQZH_200714_32}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = -1, item5 = -1,},
		-- [8] = {	name = "#{GQZH_200714_33}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
		--[9] = {	name = "#{GQZH_200714_34}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = -1, item5 = -1,},
		--[10] = {	name = "#{GQZH_200714_35}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
}

local g_ZQ_nContentButton = {}
local g_ZQ_Reward = {
"ZQ_Reward_RewardItem1",
"ZQ_Reward_RewardItem2",
"ZQ_Reward_RewardItem3",
"ZQ_Reward_RewardItem4",
"ZQ_Reward_RewardItem5",
}

--=========
-- PreLoad()
--=========
function ZQ_Rewards_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("2020ZQ_CLOSE",false)

end

--=========
-- OnLoad()
--=========
function ZQ_Rewards_OnLoad()

	
	g_Frame_UnifiedPosition = ZQ_Reward_Frame:GetProperty("UnifiedPosition")
	ZQ_Rewards_LoadControl()

end

--=========
-- Event
--=========
function ZQ_Rewards_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88813101) then
	
		ZQ_Rewards_Open()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZQ_Rewards_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ZQ_Rewards_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		ZQ_Rewards_On_ResetPos()
	elseif event == "2020ZQ_CLOSE" then
		ZQ_Rewards_Close()


	end

end

function ZQ_Rewards_Close()
	for i = 1, table.getn(g_ZQ_nContentButton) do
		for j = 1, table.getn(g_ZQ_Reward) do
			g_ZQ_nContentButton[i]:GetSubItem(g_ZQ_Reward[j]):SetActionItem(-1)
		end
	end			
	ZQ_Reward_PageList:Clear()		
	g_ZQ_nContentButton = {}
	this:Hide()
end

--=========
-- 重置
--=========
function ZQ_Rewards_On_ResetPos()

	ZQ_Reward_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function ZQ_Rewards_LoadControl()

	

end

--=========
-- 点击前往
--=========
function ZQ_Rewards_Clicked( clickId )
	
end

--=========
-- 问号帮助
--=========
function ZQ_Rewards_Help_Clicked()
	
end


--=========
-- 分页切换
--=========
function ZQ_Rewards_PageClick(index)

end

--=========
-- 填充活动奖励界面
--=========
function ZQ_Rewards_Open()

	for i = 1, table.getn(g_ZQ_nContentButton) do
		for j = 1, table.getn(g_ZQ_Reward) do
			g_ZQ_nContentButton[i]:GetSubItem(g_ZQ_Reward[j]):SetActionItem(-1)
		end
	end			
	ZQ_Reward_PageList:Clear()		
	g_ZQ_nContentButton = {}

	local kjtype   = KaJi:LuaFnGetKaJiType(104)
	if kjtype == 1 then
		g_HuoDongJiangLi = g_HuoDongJiangLi_KJ
	else
		g_HuoDongJiangLi = g_HuoDongJiangLi_Normal
	end

	for nIndex=1,table.getn(g_HuoDongJiangLi) do
		local bar = ZQ_Reward_PageList:AddChild("ZQ_Reward_PageList_Content")
		if nil ~= bar then
			bar:GetSubItem("ZQ_Reward_RewardText"):SetText(g_HuoDongJiangLi[nIndex].name)
			if g_HuoDongJiangLi[nIndex].item1 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item1, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_ZQ_Reward[1]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_ZQ_Reward[1]):Show()
				end
			else
				bar:GetSubItem(g_ZQ_Reward[1]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item2 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item2, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_ZQ_Reward[2]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_ZQ_Reward[2]):Show()
				end
			else
				bar:GetSubItem(g_ZQ_Reward[2]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item3 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item3, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_ZQ_Reward[3]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_ZQ_Reward[3]):Show()
				end
			else
				bar:GetSubItem(g_ZQ_Reward[3]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item4 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item4, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_ZQ_Reward[4]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_ZQ_Reward[4]):Show()
				end
			else
				bar:GetSubItem(g_ZQ_Reward[4]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item5 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item5, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_ZQ_Reward[5]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_ZQ_Reward[5]):Show()
				end
			else
				bar:GetSubItem(g_ZQ_Reward[5]):Hide()
			end
			g_ZQ_nContentButton[nIndex] = bar
		end
	end
	this:Show()
end