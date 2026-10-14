-- 结伴任务


local g_JieBan_Partner_Frame_UnifiedPosition
local g_JieBan_IsHave = 0;
local g_JieBan_daytime = 0;
local g_JieBan_process = 0;
local g_JieBan_daytime_reward = 0;
local g_JieBan_mission_reward = 0;
local g_JieBan_itemcount = 0;
local g_JieBan_PartnerName = "";
local g_JieBan_type = 0;
local g_JieBan_IsHuiliu = 0;
local g_JieBan_IsCanJiaoguan = 0;
local g_JieBan_pagebuttonleft1 = {}
local g_JieBan_pagebuttonleft2 = {}
local g_JieBan_pagebuttonleft3 = {}

local g_JieBan_curdaibiA = 0;
local g_JieBan_curdaibiB = 0;
local g_JieBan_hisdaibiA = 0;
local g_JieBan_hisdaibiB = 0;

local g_JieBan_Tips1 = {}
local g_JieBan_Tips2 = {}
local g_JieBan_Tips3 = {}

local g_JieBan_viplevel = 0;

local g_JieBan_button_state = {0,0,0,0}
--任务总次数
local g_JieBan_MissionA = {
	[1] = {process = 1, rewardnum = 10}, 
	[2] = {process = 2, rewardnum = 20},
	[3] = {process = 3, rewardnum = 30},
	[4] = {process = 4, rewardnum = 40},
	[5] = {process = 5, rewardnum = 50},
	[6] = {process = 6, rewardnum = 60},
	[7] = {process = 7, rewardnum = 70},
	[8] = {process = 8, rewardnum = 70},
	[9] = {process = 9, rewardnum = 70},
	[10] = {process = 10, rewardnum = 70},
	[11] = {process = 11, rewardnum = 70},
	[12] = {process = 12, rewardnum = 70},
	[13] = {process = 13, rewardnum = 70},
	[14] = {process = 14, rewardnum = 70},
}
local g_JieBan_MissionB = {
	[1] = {process = 1, rewardnum = 70},
	[2] = {process = 2, rewardnum = 80},
	[3] = {process = 3, rewardnum = 90},
	[4] = {process = 4, rewardnum = 100},
	[5] = {process = 5, rewardnum = 110},
	[6] = {process = 6, rewardnum = 120},
	[7] = {process = 7, rewardnum = 130},
	[8] = {process = 8, rewardnum = 130},
	[9] = {process = 9, rewardnum = 130},
	[10] = {process = 10, rewardnum = 130},
	[11] = {process = 11, rewardnum = 130},
	[12] = {process = 12, rewardnum = 130},
	[13] = {process = 13, rewardnum = 130},
	[14] = {process = 14, rewardnum = 130},
}

local g_JieBan_percent = {0, 0, 0, 0, 0.05, 0.1, 0.3, 0.5, 0.7, 1} --vip0-vip9

--灌溉道具
local g_JieBan_MissionItem = 38002904
local g_JieBan_DoJiaoGuan = 0

function JieBan_Partner_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function JieBan_Partner_OnLoad()
	g_JieBan_pagebuttonleft1[1] = JieBan_Partner_Left1_Buttontab01
	g_JieBan_pagebuttonleft1[2] = JieBan_Partner_Left1_Buttontab02

	g_JieBan_pagebuttonleft2[1] = JieBan_Partner_Left2_Buttontab01
	g_JieBan_pagebuttonleft2[2] = JieBan_Partner_Left2_Buttontab02
	g_JieBan_pagebuttonleft2[3] = JieBan_Partner_Left2_Buttontab03
	g_JieBan_pagebuttonleft2[4] = JieBan_Partner_Left_Buttontab04
	
	g_JieBan_Tips1[1] = JieBan_Partner_Left1_Buttontab01_Tips
	g_JieBan_Tips1[2] = JieBan_Partner_Left1_Buttontab02_Tips

	g_JieBan_Tips2[1] = JieBan_Partner_Left2_Buttontab01_Tips
	g_JieBan_Tips2[2] = JieBan_Partner_Left2_Buttontab02_Tips
	g_JieBan_Tips2[3] = JieBan_Partner_Left2_Buttontab03_Tips
	g_JieBan_Tips2[4] = JieBan_Partner_Left_Buttontab04_Tips
	
	g_JieBan_pagebuttonleft3[1] = JieBan_Partner_Left3_Buttontab01
	g_JieBan_pagebuttonleft3[2] = JieBan_Partner_Left3_Buttontab02
	g_JieBan_pagebuttonleft3[3] = JieBan_Partner_Left3_Buttontab04
	
	g_JieBan_Tips3[1] = JieBan_Partner_Left3_Buttontab01_Tips
	g_JieBan_Tips3[2] = JieBan_Partner_Left3_Buttontab02_Tips
	g_JieBan_Tips3[3] = JieBan_Partner_Left3_Buttontab04_Tips
	
    g_JieBan_Partner_Frame_UnifiedPosition = JieBan_Partner:GetProperty("UnifiedPosition")

end

function JieBan_Partner_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		JieBan_Partner_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		JieBan_Partner_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JieBan_Partner_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319502) then
		g_JieBan_IsHave = Get_XParam_INT( 0 )
		g_JieBan_daytime = Get_XParam_INT( 1 )
		g_JieBan_process = Get_XParam_INT( 2 )
		g_JieBan_daytime_reward = Get_XParam_INT( 3 )
		g_JieBan_mission_reward = Get_XParam_INT( 4 )
		g_JieBan_itemcount = Get_XParam_INT( 5 )
		g_JieBan_IsHuiliu = Get_XParam_INT( 6 )

		g_JieBan_IsCanJiaoguan = Get_XParam_INT( 7 )
		if g_JieBan_IsHuiliu > 0 then
			g_JieBan_curdaibiA = Get_XParam_INT( 8 )
			g_JieBan_hisdaibiA = Get_XParam_INT( 9 )
		else
			g_JieBan_curdaibiB = Get_XParam_INT( 8 )
			g_JieBan_hisdaibiB = Get_XParam_INT( 9 )
		end
		g_JieBan_viplevel = Get_XParam_INT( 10 )
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 11 )
		g_JieBan_button_state[2] = Get_XParam_INT( 12 )
		g_JieBan_button_state[3] = Get_XParam_INT( 13 )
		g_JieBan_button_state[4] = Get_XParam_INT( 14 )
		
		g_JieBan_PartnerName = Get_XParam_STR( 0 )

		JieBan_Partner_On_SetLastPos()
				
		JieBan_Partner_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319503 and this:IsVisible()) then
		g_JieBan_type = Get_XParam_INT( 0 )
		if g_JieBan_type == 1 then
			g_JieBan_daytime_reward = Get_XParam_INT( 1 )
		elseif g_JieBan_type == 2 then
			g_JieBan_mission_reward = Get_XParam_INT( 1 )
		end

		g_JieBan_curdaibiA = Get_XParam_INT( 2 )
		g_JieBan_curdaibiB = Get_XParam_INT( 3 )
		g_JieBan_hisdaibiA = Get_XParam_INT( 4 )
		g_JieBan_hisdaibiB = Get_XParam_INT( 5 )
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 6 )
		g_JieBan_button_state[2] = Get_XParam_INT( 7 )
		g_JieBan_button_state[3] = Get_XParam_INT( 8 )
		g_JieBan_button_state[4] = Get_XParam_INT( 9 )
		
		JieBan_Partner_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319504 and this:IsVisible()) then
		g_JieBan_process = Get_XParam_INT( 0 )
		g_JieBan_itemcount = Get_XParam_INT( 1 )
		g_JieBan_DoJiaoGuan = Get_XParam_INT( 2 )
		g_JieBan_IsCanJiaoguan = Get_XParam_INT( 3 )
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 4 )
		g_JieBan_button_state[2] = Get_XParam_INT( 5 )
		g_JieBan_button_state[3] = Get_XParam_INT( 6 )
		g_JieBan_button_state[4] = Get_XParam_INT( 7 )
		
		JieBan_Partner_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319507 and this:IsVisible()) then
		JieBan_Partner_OnClosed()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319510 and this:IsVisible()) then
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 0 )
		g_JieBan_button_state[2] = Get_XParam_INT( 1 )
		g_JieBan_button_state[3] = Get_XParam_INT( 2 )
		g_JieBan_button_state[4] = Get_XParam_INT( 3 )	
		--刷新红点
		JieBan_Partner_ShowButtonTips()
	end
end

function JieBan_Partner_Update()
	--页签button
	JieBan_Partner_ButtonPage(1)
	--刷新红点
	JieBan_Partner_ShowButtonTips()
	
	JieBan_Partner_MissionNoneClient:Hide()
	
	JieBan_Partner_MissionInfoClient:Show()
	JieBan_Partner_MissionInfo_FinishClient:Hide()
	JieBan_Partner_GoBtn:Hide()
		
	JieBan_Partner_Description_Text:SetText("#{JBHL_220120_71}")
	--伴君令
	if g_JieBan_IsHuiliu > 0 then
		JieBan_Partner_MissionInfo_Text:SetText(ScriptGlobal_Format("#{JBHL_190803_113}", g_JieBan_curdaibiA, g_JieBan_hisdaibiA, 5500))
		JieBan_Partner_MissionInfo_Text:SetToolTip("#{JBHL_190803_388}")
	else
		local curDay = tonumber(DataPool:GetServerDayTime());
		local year,month,day = GetHuoyueDaibiCleanTime(curDay)
		JieBan_Partner_MissionInfo_Text:SetText(ScriptGlobal_Format("#{JBHL_190803_253}", g_JieBan_curdaibiB, g_JieBan_hisdaibiB, 5000))
		JieBan_Partner_MissionInfo_Text:SetToolTip(ScriptGlobal_Format("#{JBHL_190803_390}", year,month,day))
	end
	--任务A
	local indexA = 0
	local isFinishA = 0
	if g_JieBan_daytime_reward == table.getn(g_JieBan_MissionA) then --A完成
		indexA = g_JieBan_daytime_reward
		JieBan_Partner_Mission1Item:Hide()
		JieBan_Partner_Mission1ItemFinish:Show()
		JieBan_Partner_Mission1Finish:Show()
		JieBan_Partner_Mission1Text1:Hide()
		JieBan_Partner_Mission1Text2:Hide()
		isFinishA = 1
	else
		indexA = g_JieBan_daytime_reward+1
		JieBan_Partner_Mission1Item:Show()
		JieBan_Partner_Mission1ItemFinish:Hide()
		JieBan_Partner_Mission1Finish:Hide()
		JieBan_Partner_Mission1Text1:Show()
		JieBan_Partner_Mission1Text2:Show()
		if g_JieBan_IsHuiliu > 0 then
			JieBan_Partner_Mission1Text1:SetText("#{JBHL_190803_269}")
		else
			JieBan_Partner_Mission1Text1:SetText("#{JBHL_190803_174}")
		end
		local DaibiCnt = math.floor(g_JieBan_MissionA[indexA].rewardnum*(g_JieBan_percent[g_JieBan_viplevel+1]+1))
		JieBan_Partner_Mission1Text2:SetText(ScriptGlobal_Format("#{JBHL_190803_175}", DaibiCnt))
	end

	--进度
	local curProcess = g_JieBan_daytime
	local maxIndex = table.getn(g_JieBan_MissionA)
	if curProcess >= g_JieBan_MissionA[maxIndex].process then
		curProcess = g_JieBan_MissionA[maxIndex].process
	end
	local str = ScriptGlobal_Format("#{JBHL_190803_222}", g_JieBan_MissionA[indexA].process, curProcess, g_JieBan_MissionA[indexA].process)
	JieBan_Partner_Mission1Name:SetText(str)
	if curProcess >= g_JieBan_MissionA[indexA].process and isFinishA == 0 then
		JieBan_Partner_Mission1ItemAnimate:Show()
	else
		JieBan_Partner_Mission1ItemAnimate:Hide()
	end
		
	--任务B
	local indexB = 0
	local isFinishB = 0
	if g_JieBan_mission_reward == table.getn(g_JieBan_MissionB) then --B完成
		indexB = g_JieBan_mission_reward
		JieBan_Partner_Mission2Item:Hide()
		JieBan_Partner_Mission2ItemFinish:Show()
		JieBan_Partner_Mission2Finish:Show()
		JieBan_Partner_Mission2Text1:Hide()
		JieBan_Partner_Mission2Text2:Hide()
		isFinishB = 1
	else
		indexB = g_JieBan_mission_reward+1
		JieBan_Partner_Mission2Item:Show()
		JieBan_Partner_Mission2ItemFinish:Hide()
		JieBan_Partner_Mission2Finish:Hide()
		JieBan_Partner_Mission2Text1:Show()
		JieBan_Partner_Mission2Text2:Show()
		if g_JieBan_IsHuiliu > 0 then
			JieBan_Partner_Mission2Text1:SetText("#{JBHL_190803_269}")
		else
			JieBan_Partner_Mission2Text1:SetText("#{JBHL_190803_174}")
		end

		local DaibiCnt = math.ceil(g_JieBan_MissionB[indexB].rewardnum*(g_JieBan_percent[g_JieBan_viplevel+1]+1))
		JieBan_Partner_Mission2Text2:SetText(ScriptGlobal_Format("#{JBHL_190803_175}", DaibiCnt))
	end
	--进度
	local curProcess = g_JieBan_process
	local maxIndex = table.getn(g_JieBan_MissionB)
	if curProcess >= g_JieBan_MissionB[maxIndex].process then
		curProcess = g_JieBan_MissionB[maxIndex].process
	end
	local str = ScriptGlobal_Format("#{JBHL_190803_223}", g_JieBan_MissionB[indexB].process, curProcess, g_JieBan_MissionB[indexB].process)
	JieBan_Partner_Mission2Name:SetText(str)
	if curProcess >= g_JieBan_MissionB[indexB].process and isFinishB == 0 then
		JieBan_Partner_Mission2ItemAnimate:Show()
	else
		JieBan_Partner_Mission2ItemAnimate:Hide()
	end
	--小树特效
	if g_JieBan_DoJiaoGuan == 1 then
		JieBan_Partner_TreePicAnimate:Show()
		JieBan_Partner_TreePicAnimate:Play(true)
		g_JieBan_DoJiaoGuan = 0
	else
		JieBan_Partner_TreePicAnimate:Hide()
	end
		
	if g_JieBan_IsCanJiaoguan == 1 then
		JieBan_Partner_TreeBtn_Tips:Show()
	else
		JieBan_Partner_TreeBtn_Tips:Hide()
	end
	--结伴好友
	if g_JieBan_IsHave == 0 then
		JieBan_Partner_MissionInfo_Partner:SetText("#{JBHL_190803_255}")
		JieBan_Partner_Btn:Show()
		JieBan_Partner_MissionInfo_RelieveBtn:Hide()
	else	
		JieBan_Partner_MissionInfo_Partner:SetText(ScriptGlobal_Format("#{JBHL_190803_59}", g_JieBan_PartnerName))
		JieBan_Partner_Btn:Hide()
		JieBan_Partner_MissionInfo_RelieveBtn:Show()
	end
	local szItemName = DataPool:Lua_GetItemNameByIndex(g_JieBan_MissionItem)
	JieBan_Partner_TreeHaveText:SetText(ScriptGlobal_Format("#{JBHL_190803_176}", szItemName, g_JieBan_itemcount, 1))
	JieBan_Partner_TreeHelpText:SetText(ScriptGlobal_Format("#{JBHL_190803_177}", 150, szItemName))

	this:Show()
end

function JieBan_Partner_Get_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FindJiebanPartner" )
		Set_XSCRIPT_ScriptID( 893195 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function JieBan_Partner_Relieve_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "JieBanRelieve" )
		Set_XSCRIPT_ScriptID( 893195 )
		Set_XSCRIPT_Parameter( 0, 0 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()		
end

function JieBan_Partner_Mission1Item_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_ScriptID( 893195 )
		Set_XSCRIPT_Parameter( 0, 1 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function JieBan_Partner_Mission2Item_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_ScriptID( 893195 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--前往
function JieBan_Partner_Go_Click()
	local nLevel = Player:GetLevel();
	if nLevel < 50 then
		PushDebugMessage("#{JBHL_190803_179}")
		return
	end
	local bRet = AutoRuntoTargetExWithName(175, 143, 2, "孙八爷")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	PushDebugMessage("#{JBHL_190803_180}")
end
--浇灌
function JieBan_Partner_JiaoGuan_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoJiaoGuan" )
		Set_XSCRIPT_ScriptID( 893195 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()		
end

--页面切换 1、结伴任务 2、商店 3、回流任务 4、回流特权
function JieBan_Partner_Project_Clicked(index)
	if index == 1 then
		return
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanShop" )
			Set_XSCRIPT_ScriptID( 893196 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 3 then

		if g_JieBan_IsHuiliu ~= 1 then
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHuiliuMission" )
			Set_XSCRIPT_ScriptID( 893229 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif index == 4 then
		if g_JieBan_IsHuiliu == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ShowHuiGuiUIDefaultPage")
				Set_XSCRIPT_ScriptID(808110)
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_JieBan_IsHuiliu == 2 then --2022新回流
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ShowHuiGuiUIDefaultPage")
				Set_XSCRIPT_ScriptID(808112)
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
		
	end
	
	Variable:SetVariable("JieBanUIPos", JieBan_Partner:GetProperty("UnifiedPosition"), 1)
end

--选中页签
function JieBan_Partner_ButtonPage(index)
	if g_JieBan_IsHuiliu == 1 then
		JieBan_Partner_ButtonLeft1:Hide()
		JieBan_Partner_ButtonLeft2:Show()
		JieBan_Partner_ButtonLeft3:Hide()
		
		for i = 1, 4 do
			if index == i then
				g_JieBan_pagebuttonleft2[i]:SetProperty("Selected", "True")
			else
				g_JieBan_pagebuttonleft2[i]:SetProperty("Selected", "False")
			end
		end
	elseif g_JieBan_IsHuiliu == 2 then --2022新回流
		JieBan_Partner_ButtonLeft1:Hide()
		JieBan_Partner_ButtonLeft2:Hide()
		JieBan_Partner_ButtonLeft3:Show()
		for i = 1, 3 do
			if index == i then
				g_JieBan_pagebuttonleft3[i]:SetProperty("Selected", "True")
			else
				g_JieBan_pagebuttonleft3[i]:SetProperty("Selected", "False")
			end
		end		
		
	else
		JieBan_Partner_ButtonLeft1:Show()
		JieBan_Partner_ButtonLeft2:Hide()
		JieBan_Partner_ButtonLeft3:Hide()
		
		for i = 1, 2 do
			if index == i then
				g_JieBan_pagebuttonleft1[i]:SetProperty("Selected", "True")
			else
				g_JieBan_pagebuttonleft1[i]:SetProperty("Selected", "False")
			end
		end
	end
end

--刷新红点
function JieBan_Partner_ShowButtonTips()
	if g_JieBan_IsHuiliu == 1 then
		for i = 1, 4 do
			if g_JieBan_button_state[i] == 1 then
				g_JieBan_Tips2[i]:Show()
			else
				g_JieBan_Tips2[i]:Hide()
			end
		end
	elseif g_JieBan_IsHuiliu == 2 then --2022新回流
		g_JieBan_button_state[3] = g_JieBan_button_state[4]
		for i = 1, 3 do
			if g_JieBan_button_state[i] == 1 then
				g_JieBan_Tips3[i]:Show()
			else
				g_JieBan_Tips3[i]:Hide()
			end
		end							
	else
		for i = 1, 2 do
			if g_JieBan_button_state[i] == 1 then
				g_JieBan_Tips1[i]:Show()
			else
				g_JieBan_Tips1[i]:Hide()
			end
		end		
	end
end
--关闭
function JieBan_Partner_OnClosed()
	this:Hide()
end

function JieBan_Partner_On_ResetPos()
    JieBan_Partner:SetProperty("UnifiedPosition", g_JieBan_Partner_Frame_UnifiedPosition)
end

--===============================================
-- 设置共享位置信息
--===============================================
function JieBan_Partner_On_SetLastPos()
	local CurUIPos = Variable:GetVariable("JieBanUIPos")
	if( CurUIPos ~= nil) then
	    JieBan_Partner:SetProperty("UnifiedPosition", CurUIPos )
	end
end

function JieBan_Partner_Description_Clicked()
	--if g_JieBan_IsHave == 0 then
	--	PushEvent("CCSHOP_HELP", 104)
	--else
		PushEvent("CCSHOP_HELP", 106)
	--end
end

function JieBan_Partner_Mission1_Help_Clicked()
	PushEvent("CCSHOP_HELP", 107)
end
function JieBan_Partner_Mission2_Help_Clicked()
	PushEvent("CCSHOP_HELP", 108)
end