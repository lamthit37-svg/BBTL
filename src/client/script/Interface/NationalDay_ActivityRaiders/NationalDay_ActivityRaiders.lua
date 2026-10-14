local g_Frame_UnifiedPosition


local g_LevelLimit = 30

local g_HuoDongJiangLi = {}
-- 活动奖励
local g_HuoDongJiangLi_Normal = 
{
		[1] = {	name = "#{GQZH_200714_26}", starttime = 20240926, endtime = 20241016, item1 = 39923976, item2 = 39925038, item3 = 39922866, item4 = 39920397, item5 = 39920396,},
		[2] = {	name = "#{GQZH_200714_27}", starttime = 20240926, endtime = 20241016, item1 = 39920535, item2 = 39925037, item3 = 39920311, item4 = 39920089, item5 = 39921141,},
		[3] = {	name = "#{GQZH_200714_28}", starttime = 20240926, endtime = 20241016, item1 = 39921539, item2 = 39920329, item3 = 39920298, item4 = 39923234, item5 = 39920999,},
		--[4] = {	name = "#{GQZH_200714_29}", starttime = 20240926, endtime = 20241016, item1 = 39921818, item2 = 39921844, item3 = 39921817, item4 = -1, item5 = -1,},
		--[5] = {	name = "#{GQZH_200714_30}", starttime = 20240926, endtime = 20241016, item1 = 39924450, item2 = 39924441, item3 = 39923976, item4 = 39924369, item5 = 39924368,},
		[4] = {	name = "#{GQZH_200714_31}", starttime = 20240926, endtime = 20241016, item1 = 39922155, item2 = 39920959, item3 = 39920298, item4 = 39920396, item5 = 39920397,},
		[5] = {	name = "#{GQZH_200714_32}", starttime = 20240926, endtime = 20241016, item1 = 39920085, item2 = 39920334, item3 = 39920180, item4 = 39921915, item5 = -1,},
		[6] = {	name = "#{GQZH_200714_33}", starttime = 20240926, endtime = 20241016, item1 = 39920491, item2 = 39920492, item3 = 39921920, item4 = -1, item5 = -1,},
		--[9] = {	name = "#{GQZH_200714_34}", starttime = 20240926, endtime = 20241016, item1 = 39923234, item2 = 39920945, item3 = 39920397, item4 = 39920396, item5 = 39920394,},
		--[10] = {	name = "#{GQZH_200714_35}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
}

local g_HuoDongJiangLi_KJ = 
{
		[1] = {	name = "#{GQZH_200714_26}", starttime = 20240926, endtime = 20241016, item1 = 39923976, item2 = 39925038, item3 = 39922866, item4 = 39920397, item5 = 39920396,},
		[2] = {	name = "#{GQZH_200714_27}", starttime = 20240926, endtime = 20241016, item1 = 39920535, item2 = 39925037, item3 = 39920311, item4 = 39920089, item5 = 39921141,},
		[3] = {	name = "#{GQZH_200714_28}", starttime = 20240926, endtime = 20241016, item1 = 39920945, item2 = 39920329, item3 = 39920999, item4 = 39920397, item5 = 39920396,},
		--[4] = {	name = "#{GQZH_200714_29}", starttime = 20240926, endtime = 20241016, item1 = 39921818, item2 = 39921844, item3 = 39921817, item4 = -1, item5 = -1,},
		--[5] = {	name = "#{GQZH_200714_30}", starttime = 20240926, endtime = 20241016, item1 = 39924450, item2 = 39924441, item3 = 39923976, item4 = 39924369, item5 = 39924368,},
		[4] = {	name = "#{GQZH_200714_31}", starttime = 20240926, endtime = 20241016, item1 = 39920842, item2 = 39920235, item3 = 39920267, item4 = 39921139, item5 = 39920089,},
		[5] = {	name = "#{GQZH_200714_32}", starttime = 20240926, endtime = 20241016, item1 = 39920085, item2 = 39920334, item3 = 39920180, item4 = 39921915, item5 = -1,},
		[6] = {	name = "#{GQZH_200714_33}", starttime = 20240926, endtime = 20241016, item1 = 39920491, item2 = 39920492, item3 = -1, item4 = -1, item5 = -1,},
		--[9] = {	name = "#{GQZH_200714_34}", starttime = 20240926, endtime = 20241016, item1 = 39923234, item2 = 39920945, item3 = 39920397, item4 = 39920396, item5 = 39920394,},
		--[10] = {	name = "#{GQZH_200714_35}", starttime = 20200924, endtime = 20201018, item1 = 39922706, item2 = 39922707, item3 = 39922708, item4 = 39922709, item5 = -1,},
}

local g_NationalDay_nContentButton = {}
local g_NationalDay_Reward = {
"NationalDay_ActivityRaiders_RewardItem1",
"NationalDay_ActivityRaiders_RewardItem2",
"NationalDay_ActivityRaiders_RewardItem3",
"NationalDay_ActivityRaiders_RewardItem4",
"NationalDay_ActivityRaiders_RewardItem5",
}

--=========
-- PreLoad()
--=========
function NationalDay_ActivityRaiders_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function NationalDay_ActivityRaiders_OnLoad()

	
	g_Frame_UnifiedPosition = NationalDay_ActivityRaiders_Frame:GetProperty("UnifiedPosition")
	NationalDay_ActivityRaiders_LoadControl()

end

--=========
-- Event
--=========
function NationalDay_ActivityRaiders_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88811601) then
	
		NationalDay_ActivityRaiders_Open()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		NationalDay_ActivityRaiders_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		NationalDay_ActivityRaiders_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		NationalDay_ActivityRaiders_On_ResetPos()

	end

end

function NationalDay_ActivityRaiders_Close()
	for i = 1, table.getn(g_NationalDay_nContentButton) do
		for j = 1, table.getn(g_NationalDay_Reward) do
			g_NationalDay_nContentButton[i]:GetSubItem(g_NationalDay_Reward[j]):SetActionItem(-1)
		end
	end			
	NationalDay_ActivityRaiders_Page2List:Clear()		
	g_NationalDay_nContentButton = {}
	this:Hide()
end

--=========
-- 重置
--=========
function NationalDay_ActivityRaiders_On_ResetPos()

	NationalDay_ActivityRaiders_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function NationalDay_ActivityRaiders_LoadControl()

	

end

--=========
-- 点击前往
--=========
function NationalDay_ActivityRaiders_Clicked( clickId )
	
end

--=========
-- 问号帮助
--=========
function NationalDay_ActivityRaiders_Help_Clicked()
	
end


--=========
-- 分页切换
--=========
function NationalDay_ActivityRaiders_PageClick(index)

end

--=========
-- 填充活动奖励界面
--=========
function NationalDay_ActivityRaiders_Open()

	for i = 1, table.getn(g_NationalDay_nContentButton) do
		for j = 1, table.getn(g_NationalDay_Reward) do
			g_NationalDay_nContentButton[i]:GetSubItem(g_NationalDay_Reward[j]):SetActionItem(-1)
		end
	end			
	NationalDay_ActivityRaiders_Page2List:Clear()		
	g_NationalDay_nContentButton = {}
	
	local kjtype   = KaJi:LuaFnGetKaJiType(111)
	if kjtype == 1 then
		g_HuoDongJiangLi = g_HuoDongJiangLi_KJ
	else
		g_HuoDongJiangLi = g_HuoDongJiangLi_Normal
	end
	
	for nIndex=1,table.getn(g_HuoDongJiangLi) do
		local bar = NationalDay_ActivityRaiders_Page2List:AddChild("NationalDay_ActivityRaiders_Page2List_Content")
		if nil ~= bar then
			bar:GetSubItem("NationalDay_ActivityRaiders_RewardText"):SetText(g_HuoDongJiangLi[nIndex].name)
			if g_HuoDongJiangLi[nIndex].item1 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item1, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_NationalDay_Reward[1]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_NationalDay_Reward[1]):Show();
				end
			else
				bar:GetSubItem(g_NationalDay_Reward[1]):Hide();
			end
			if g_HuoDongJiangLi[nIndex].item2 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item2, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_NationalDay_Reward[2]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_NationalDay_Reward[2]):Show();
				end
			else
				bar:GetSubItem(g_NationalDay_Reward[2]):Hide();
			end
			if g_HuoDongJiangLi[nIndex].item3 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item3, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_NationalDay_Reward[3]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_NationalDay_Reward[3]):Show();
				end
			else
				bar:GetSubItem(g_NationalDay_Reward[3]):Hide();
			end
			if g_HuoDongJiangLi[nIndex].item4 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item4, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_NationalDay_Reward[4]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_NationalDay_Reward[4]):Show();
				end
			else
				bar:GetSubItem(g_NationalDay_Reward[4]):Hide();
			end
			if g_HuoDongJiangLi[nIndex].item5 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item5, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_NationalDay_Reward[5]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_NationalDay_Reward[5]):Show();
				end
			else
				bar:GetSubItem(g_NationalDay_Reward[5]):Hide();
			end
			g_NationalDay_nContentButton[nIndex] = bar
		end
	end
	this:Show()
end