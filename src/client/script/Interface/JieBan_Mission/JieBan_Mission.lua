-- 2019回流任务


local g_JieBan_Mission_Frame_UnifiedPosition

--任务列表
local g_JieBan_Huiliu_MissionA = {
	[1] = {process = 90, Bonus= { 6,12,30,60 }},     
	[2] = {process = 180, Bonus={12,24,60,120 }},
	[3] = {process = 270, Bonus={18,36,90,180 }},
	[4] = {process = 360, Bonus={24,48,120,240}},
	[5] = {process = 450, Bonus={30,60,150,300}},
	[6] = {process = 540, Bonus={36,72,180,360}},
	[7] = {process = 630, Bonus={42,84,210,420}},
}

local g_JieBan_Huiliu_MissionB = {
	[1] = {process = 300, Bonus= {6,12,30,60 }},     
	[2] = {process = 600,  Bonus={12,24,60,120 }},
	[3] = {process = 900,  Bonus={18,36,90,180 }},
	[4] = {process = 1200, Bonus={24,48,120,240}},
	[5] = {process = 1500, Bonus={30,60,150,300}},
	[6] = {process = 1800, Bonus={36,72,180,360}},
	[7] = {process = 2100, Bonus={42,84,210,420}},
}

local g_JieBan_Huiliu_MissionC = {
	[1] = {process = 1, Bonus={0,0,0,0}},
}
local g_JieBan_MissionList = {
	[1] = g_JieBan_Huiliu_MissionA,
	[2] = g_JieBan_Huiliu_MissionB,
	[3] = g_JieBan_Huiliu_MissionC,
}

local g_JieBan_Mission_itembutton = {}
local g_JieBan_Mission_reward1_1 = {}
local g_JieBan_Mission_reward1_2 = {}
local g_JieBan_Mission_reward1_3 = {}
local g_JieBan_Mission_reward2_1 = {}
local g_JieBan_Mission_reward2_2 = {}
local g_JieBan_Mission_reward3_1 = {}

local g_JieBan_Mission_name = {}
local g_JieBan_Mission_Process = {}
local g_JieBan_Mission_Animate = {}
local g_JieBan_Mission_Finish = {}
local g_JieBan_Mission_FinishImage = {}
local g_JieBan_Mission_rewardBK1 = {}
local g_JieBan_Mission_rewardBK2 = {}
local g_JieBan_Mission_rewardBK3 = {}
local g_JieBan_Mission_FinishText = {}
local g_JieBan_Mission_BonusText = {}
local g_JieBan_Mission_ShowMissionInfo = {}

local g_JieBan_Huiliu_Name = {
	[1] = "#{JBHL_190803_242}",
	[2] = "#{JBHL_190803_243}",
	[3] = "#{JBHL_190803_244}",
}
local g_JieBan_Huiliu_LevelImage = {
	[1] = "set:JieBan6 image:jie1", -- 1级
	[2] = "set:JieBan6 image:jie2", -- 2级
	[3] = "set:JieBan6 image:jie3", -- 3级
	[4] = "set:JieBan6 image:jie4", -- 4级
}

local g_JieBan_MissionData_CurProcess = {}
local g_JieBan_MissionData_nextProcessIndex = {}
local g_JieBan_IsFinish = {0,0,0}
local g_JieBan_Tips = {}

local g_JieBan_button_state = {0,0,0,0}

local g_JieBan_pagebuttonleft1 = {}

local g_JieBan_curdaibiA = 0;
local g_JieBan_hisdaibiA = 0;

local g_JieBan_lefttime = 0;

local g_JieBan_huiliu_level = 0;

function JieBan_Mission_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function JieBan_Mission_OnLoad()

	for i = 1, 3 do
		g_JieBan_Mission_itembutton[i] = "JieBan_Mission"..i.."Icon"
		g_JieBan_Mission_reward1_1[i] = "JieBan_Mission"..i.."Item1"
		g_JieBan_Mission_reward1_2[i] = "JieBan_Mission"..i.."Item2"
		g_JieBan_Mission_reward1_3[i] = "JieBan_Mission"..i.."Item3"
		g_JieBan_Mission_reward2_1[i] = "JieBan_Mission"..i.."Item1_1"
		g_JieBan_Mission_reward2_2[i] = "JieBan_Mission"..i.."Item2_1"
		g_JieBan_Mission_reward3_1[i] = "JieBan_Mission"..i.."Item3_1"

		g_JieBan_Mission_name[i] = "JieBan_Mission_Mission"..i.."Name"
		g_JieBan_Mission_Process[i] = "JieBan_Mission_Mission"..i.."Num"
		g_JieBan_Mission_Animate[i] = "JieBan_Mission"..i.."IconAnimate"
		g_JieBan_Mission_Finish[i] = "JieBan_Mission"..i.."IconFinish"
		g_JieBan_Mission_FinishImage[i] = "JieBan_Mission_Mission"..i.."Finish"
		g_JieBan_Mission_rewardBK1[i] = "JieBan_Mission"..i.."Item1_Bk"
		g_JieBan_Mission_rewardBK2[i] = "JieBan_Mission"..i.."Item1_1_Bk"
		g_JieBan_Mission_rewardBK3[i] = "JieBan_Mission"..i.."Item1_2_Bk"
		g_JieBan_Mission_FinishText[i] = "JieBan_Mission_Reward"..i.."Text"
		g_JieBan_Mission_BonusText[i] = "JieBan_Mission"..i.."_BonusText"
	end
	
	for i = 1, 3 do
		g_JieBan_Mission_ShowMissionInfo[i] = {
			itemIcon = _G[g_JieBan_Mission_itembutton[i]],
			reward1_1 = _G[g_JieBan_Mission_reward1_1[i]],
			reward1_2 = _G[g_JieBan_Mission_reward1_2[i]],
			reward1_3 = _G[g_JieBan_Mission_reward1_3[i]],
			reward2_1 = _G[g_JieBan_Mission_reward2_1[i]],
			reward2_2 = _G[g_JieBan_Mission_reward2_2[i]],
			reward3_1 = _G[g_JieBan_Mission_reward3_1[i]],
			
			name = _G[g_JieBan_Mission_name[i]],
			process = _G[g_JieBan_Mission_Process[i]],
			animate = _G[g_JieBan_Mission_Animate[i]],
			finish = _G[g_JieBan_Mission_Finish[i]],
			finishimage = _G[g_JieBan_Mission_FinishImage[i]],
			rewardBK1 = _G[g_JieBan_Mission_rewardBK1[i]],
			rewardBK2 = _G[g_JieBan_Mission_rewardBK2[i]],
			rewardBK3 = _G[g_JieBan_Mission_rewardBK3[i]],
			finishtext = _G[g_JieBan_Mission_FinishText[i]],
			bonusText = _G[g_JieBan_Mission_BonusText[i]],
		}
	end
	
	g_JieBan_pagebuttonleft1[1] = JieBan_Mission_Left_Buttontab01
	g_JieBan_pagebuttonleft1[2] = JieBan_Mission_Left_Buttontab02
	g_JieBan_pagebuttonleft1[3] = JieBan_Mission_Left_Buttontab03
	g_JieBan_pagebuttonleft1[4] = JieBan_Mission_Left_Buttontab04
	
	g_JieBan_Tips[1] = JieBan_Mission_Left_Buttontab01_Tips
	g_JieBan_Tips[2] = JieBan_Mission_Left_Buttontab02_Tips
	g_JieBan_Tips[3] = JieBan_Mission_Left_Buttontab03_Tips
	g_JieBan_Tips[4] = JieBan_Mission_Left_Buttontab04_Tips
	
    g_JieBan_Mission_Frame_UnifiedPosition = JieBan_Mission:GetProperty("UnifiedPosition")

end

function JieBan_Mission_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		JieBan_Mission_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		JieBan_Mission_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JieBan_Mission_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89322901) then
		g_JieBan_MissionData_CurProcess[1] = Get_XParam_INT( 0 )
		g_JieBan_MissionData_CurProcess[2] = Get_XParam_INT( 1 )
		g_JieBan_MissionData_CurProcess[3] = Get_XParam_INT( 2 )
		g_JieBan_MissionData_nextProcessIndex[1] = Get_XParam_INT( 3 )
		g_JieBan_MissionData_nextProcessIndex[2] = Get_XParam_INT( 4 )
		g_JieBan_MissionData_nextProcessIndex[3] = Get_XParam_INT( 5 )
		g_JieBan_curdaibiA = Get_XParam_INT( 6 )
		g_JieBan_lefttime = Get_XParam_INT( 7 )
		g_JieBan_huiliu_level = Get_XParam_INT( 8 )
		g_JieBan_hisdaibiA = Get_XParam_INT( 9 )
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 10 )
		g_JieBan_button_state[2] = Get_XParam_INT( 11 )
		g_JieBan_button_state[3] = Get_XParam_INT( 12 )
		g_JieBan_button_state[4] = Get_XParam_INT( 13 )
		
		JieBan_Mission_On_SetLastPos()
		
		JieBan_Mission_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89322902 and this:IsVisible()) then
		local index = Get_XParam_INT( 0 )
		local nextProcessIndex = Get_XParam_INT( 1 )
		
		g_JieBan_MissionData_nextProcessIndex[index] = nextProcessIndex
		g_JieBan_curdaibiA = Get_XParam_INT( 2 )
		g_JieBan_hisdaibiA = Get_XParam_INT( 3 )
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 4 )
		g_JieBan_button_state[2] = Get_XParam_INT( 5 )
		g_JieBan_button_state[3] = Get_XParam_INT( 6 )
		g_JieBan_button_state[4] = Get_XParam_INT( 7 )
		
		JieBan_Mission_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89322903 and this:IsVisible()) then
		local index = Get_XParam_INT( 0 )
		local data = Get_XParam_INT( 1 )
		g_JieBan_MissionData_CurProcess[index] = data
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 2 )
		g_JieBan_button_state[2] = Get_XParam_INT( 3 )
		g_JieBan_button_state[3] = Get_XParam_INT( 4 )
		g_JieBan_button_state[4] = Get_XParam_INT( 5 )
				
		JieBan_Mission_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319510 and this:IsVisible()) then
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 0 )
		g_JieBan_button_state[2] = Get_XParam_INT( 1 )
		g_JieBan_button_state[3] = Get_XParam_INT( 2 )
		g_JieBan_button_state[4] = Get_XParam_INT( 3 )
		--刷新红点
		JieBan_Mission_ShowButtonTips()
	end
end

function JieBan_Mission_Update()
	JieBan_Mission_FinishClient:Hide()
	JieBan_Mission_Description_Help:Show()
	--JieBan_Mission1_Help:Show()
	--JieBan_Mission2_Help:Show()
	--JieBan_Mission3_Help:Hide()
	JieBan_Mission_ButtonPage(3)
	--刷新红点
	JieBan_Mission_ShowButtonTips()
	--DataPool:ClearActionItemForShow()
	JieBan_Mission_Coin_Text:SetText(ScriptGlobal_Format("#{JBHL_190803_387}", g_JieBan_curdaibiA, g_JieBan_hisdaibiA, 4500))
	JieBan_Mission_Coin_Text:SetToolTip("#{JBHL_190803_388}")
	
	local day = math.floor(g_JieBan_lefttime/(3600*24))
	local hour = math.ceil(math.mod(g_JieBan_lefttime, (3600*24))/3600)
	JieBan_Mission_TimeLeft_Text1:SetText(ScriptGlobal_Format("#{JBHL_190803_389}", day, hour))
	 
	 -- 图片	
	if g_JieBan_Huiliu_LevelImage[g_JieBan_huiliu_level] ~= nil then
		JieBan_Mission_but:SetProperty("Image", g_JieBan_Huiliu_LevelImage[g_JieBan_huiliu_level])
	end
	JieBan_Mission_but:SetToolTip(ScriptGlobal_Format("#{JBHL_190803_417}",g_JieBan_huiliu_level))
	for i = 1, 3 do
		--当前目标进度
		local Index = g_JieBan_MissionData_nextProcessIndex[i]
		local missiontbl = g_JieBan_MissionList[i]
		if Index == table.getn(g_JieBan_MissionList[i])+1 then --已领完
			g_JieBan_Mission_ShowMissionInfo[i].finish:Show()
			g_JieBan_Mission_ShowMissionInfo[i].itemIcon:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].finishimage:Show()
			g_JieBan_Mission_ShowMissionInfo[i].finishtext:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].rewardBK1:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].rewardBK2:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].rewardBK3:Hide()
			Index = table.getn(g_JieBan_MissionList[i])
			g_JieBan_IsFinish[i] = 1
			g_JieBan_Mission_ShowMissionInfo[i].bonusText:Hide()
		else
			g_JieBan_Mission_ShowMissionInfo[i].finish:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].itemIcon:Show()
			g_JieBan_Mission_ShowMissionInfo[i].finishimage:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].finishtext:Show()

			g_JieBan_Mission_ShowMissionInfo[i].rewardBK1:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].rewardBK2:Hide()
			g_JieBan_Mission_ShowMissionInfo[i].rewardBK3:Hide()
			--if item2 == -1 then	
			--	g_JieBan_Mission_ShowMissionInfo[i].rewardBK3:Show()
			--	local theAction1 = DataPool:CreateActionItemForShow(item1, cnt1)
			--	if theAction1:GetID() ~= 0 then
			--		g_JieBan_Mission_ShowMissionInfo[i].reward3_1:SetActionItem(theAction1:GetID());
			--	end
			--elseif item3 == -1 then	
			--	g_JieBan_Mission_ShowMissionInfo[i].rewardBK2:Show()
			--	local theAction1 = DataPool:CreateActionItemForShow(item1, cnt1)
			--	if theAction1:GetID() ~= 0 then
			--		g_JieBan_Mission_ShowMissionInfo[i].reward2_1:SetActionItem(theAction1:GetID());
			--	end
			--	local theAction2 = DataPool:CreateActionItemForShow(item2, cnt2)
			--	if theAction2:GetID() ~= 0 then
			--		g_JieBan_Mission_ShowMissionInfo[i].reward2_2:SetActionItem(theAction2:GetID());
			--	end			
			--else
			--	g_JieBan_Mission_ShowMissionInfo[i].rewardBK1:Show()
			--	local theAction1 = DataPool:CreateActionItemForShow(item1, cnt1)
			--	if theAction1:GetID() ~= 0 then
			--		g_JieBan_Mission_ShowMissionInfo[i].reward1_1:SetActionItem(theAction1:GetID());
			--	end
			--	local theAction2 = DataPool:CreateActionItemForShow(item2, cnt2)
			--	if theAction2:GetID() ~= 0 then
			--		g_JieBan_Mission_ShowMissionInfo[i].reward1_2:SetActionItem(theAction2:GetID());
			--	end	
			--	local theAction3 = DataPool:CreateActionItemForShow(item3, cnt3)
			--	if theAction3:GetID() ~= 0 then
			--		g_JieBan_Mission_ShowMissionInfo[i].reward1_3:SetActionItem(theAction3:GetID());
			--	end					
			--end
			local nBonus = 0
			if g_JieBan_huiliu_level >= 1 and g_JieBan_huiliu_level <= 4 then
				nBonus = missiontbl[Index].Bonus[g_JieBan_huiliu_level]
			end
			g_JieBan_Mission_ShowMissionInfo[i].bonusText:Show()
			g_JieBan_Mission_ShowMissionInfo[i].bonusText:SetText(ScriptGlobal_Format("#{JBHL_190803_271}", nBonus))
			g_JieBan_IsFinish[i] = 0
		end
		
		if Index < 1 or Index > table.getn(g_JieBan_MissionList[i]) then
			return
		end
		
		--进度
		local curProcess = g_JieBan_MissionData_CurProcess[i]
		local curMaxProcessData = missiontbl[Index].process			
		--任务名
		g_JieBan_Mission_ShowMissionInfo[i].name:SetText(ScriptGlobal_Format(g_JieBan_Huiliu_Name[i], curProcess,curMaxProcessData))
		g_JieBan_Mission_ShowMissionInfo[i].process:SetText(ScriptGlobal_Format("#{JBHL_190803_146}", curProcess,curMaxProcessData))
		
		if curProcess >= curMaxProcessData and g_JieBan_IsFinish[i] == 0 then
			g_JieBan_Mission_ShowMissionInfo[i].animate:Show()
		else
			g_JieBan_Mission_ShowMissionInfo[i].animate:Hide()
		end
		
	end
	
	this:Show()
end

function JieBan_Mission_MissionItem_Click(index)
	if index < 1 or index > 3 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_ScriptID( 893229 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--页面切换 1、结伴任务 2、商店 3、回流任务 4、回流特权 
function JieBan_Mission_Project_Clicked(index)
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanMission" )
			Set_XSCRIPT_ScriptID( 893195 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanShop" )
			Set_XSCRIPT_ScriptID( 893196 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 3 then
		return
	elseif index == 4 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIDefaultPage")
			Set_XSCRIPT_ScriptID(808110)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	Variable:SetVariable("JieBanUIPos", JieBan_Mission:GetProperty("UnifiedPosition"), 1)
end

--选中页签
function JieBan_Mission_ButtonPage(index)
	for i = 1, 4 do
		if index == i then
			g_JieBan_pagebuttonleft1[i]:SetProperty("Selected", "True")
		else
			g_JieBan_pagebuttonleft1[i]:SetProperty("Selected", "False")
		end
	end
end
--刷新红点
function JieBan_Mission_ShowButtonTips()
	for i = 1, 4 do
		if g_JieBan_button_state[i] == 1 then
			g_JieBan_Tips[i]:Show()
		else
			g_JieBan_Tips[i]:Hide()
		end
	end						
end
--关闭
function JieBan_Mission_OnClosed()
	this:Hide()
end

function JieBan_Mission_On_ResetPos()
    JieBan_Mission:SetProperty("UnifiedPosition", g_JieBan_Mission_Frame_UnifiedPosition)
end

--===============================================
-- 设置共享位置信息
--===============================================
function JieBan_Mission_On_SetLastPos()
	local CurUIPos = Variable:GetVariable("JieBanUIPos")
	if( CurUIPos ~= nil) then
	    JieBan_Mission:SetProperty("UnifiedPosition", CurUIPos )
	end
end

function JieBan_Mission1_Help_Clicked()
	PushEvent("CCSHOP_HELP", 109)
end

function JieBan_Mission2_Help_Clicked()
	PushEvent("CCSHOP_HELP", 110)
end

function JieBan_Mission3_Help_Clicked()
	PushEvent("CCSHOP_HELP", 111)
end

function JieBan_Mission_Description_Clicked()
	PushEvent("CCSHOP_HELP", 112)
end