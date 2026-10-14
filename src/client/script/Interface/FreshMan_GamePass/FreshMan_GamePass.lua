--新手战令
--!!!reloadscript =FreshMan_GamePass

local g_FreshMan_GamePass_UnifiedPosition;
--滚动条的位置
local g_Position_Scroll = 0;

--0到9艺术字
local g_FreshMan_GamePass_NumberImg = {
	[0] = "set:Freshman_GamePass01 image:Level_0",
	[1] = "set:Freshman_GamePass01 image:Level_1",
	[2] = "set:Freshman_GamePass01 image:Level_2",
	[3] = "set:Freshman_GamePass01 image:Level_3",
	[4] = "set:Freshman_GamePass01 image:Level_4",
	[5] = "set:Freshman_GamePass01 image:Level_5",
	[6] = "set:Freshman_GamePass01 image:Level_6",
	[7] = "set:Freshman_GamePass01 image:Level_7",
	[8] = "set:Freshman_GamePass01 image:Level_8",
	[9] = "set:Freshman_GamePass01 image:Level_9",
}

local g_FreshMan_GamePass_MissionBtn={};
local g_FreshMan_GamePass_MissionBtnRedpoint={};
local g_FreshMan_GamePass_MissionLeiJiBtn={};
local g_FreshMan_GamePass_MissionLeiJiBtnRedpoint={};

--任务左侧配置
local g_FreshMan_GamePass_MissionConfig = {
	[1] = { szText="#{XSZL_220511_53}", misType=0, check=0, redpoint=0 },
	[2] = { szText="#{XSZL_220511_71}", misType=-1, check=0, redpoint=0, fold=1,
		Child={
			[1] = { szText = "#{XSZL_220511_72}", misType=1, check=0, redpoint=0 },
			[2] = { szText = "#{XSZL_220511_73}", misType=2, check=0, redpoint=0 },
			[3] = { szText = "#{XSZL_220511_74}", misType=3, check=0, redpoint=0 },
			[4] = { szText = "#{XSZL_220511_90}", misType=4, check=0, redpoint=0 },
			},
		ChildKaJi={
			[1] = { szText = "#{XSZL_220511_72}", misType=1, check=0, redpoint=0 },
			[2] = { szText = "#{XSZL_220511_102}", misType=2, check=0, redpoint=0 },
			[3] = { szText = "#{XSZL_220511_74}", misType=3, check=0, redpoint=0 },
			[4] = { szText = "#{XSZL_220511_90}", misType=4, check=0, redpoint=0 },
			}
		},
}

local g_FreshMan_GamePass_ShowInterface = 1
local g_FreshMan_GamePass_ShowMisType = 0
local g_FreshMan_GamePass_TaskShow_TagBtnIndex = 1

--战令等级
local g_FreshMan_GamePass_Level = 0
--战令经验
local g_FreshMan_GamePass_Exp = 0

local g_FreshMan_GamePass_AwardItemUp = 0
local g_FreshMan_GamePass_AwardItemDown = 0
local g_FreshMan_GamePass_AwardItemList = {}

local g_FreshMan_GamePass_FirstLoad = 0
--===============================================
-- PreLoad()
--===============================================
function FreshMan_GamePass_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化

	this:RegisterEvent("XINSHOUZHANLING_OPEN") --打开界面事件
	this:RegisterEvent("XINSHOUZHANLING_UPDATE")
	this:RegisterEvent("XINSHOUZHANLING_BUY")
end

--===============================================
-- OnLoad()
--===============================================
function FreshMan_GamePass_OnLoad()	
	g_FreshMan_GamePass_UnifiedPosition = FreshMan_GamePass_Frame:GetProperty("UnifiedPosition")

end

--===============================================
-- OnEvent()
--===============================================
function FreshMan_GamePass_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		FreshMan_GamePass_OnClosed()
	elseif event == "ADJEST_UI_POS" then
		FreshMan_GamePass_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FreshMan_GamePass_OnResetPos()	
	elseif event == "XINSHOUZHANLING_OPEN" then --界面打开事件
		if(this:IsVisible())then
			FreshMan_GamePass_OnClosed()
		else
			FreshMan_GamePass_Open()
		end
	elseif event == "XINSHOUZHANLING_UPDATE" and this:IsVisible() then
			
		FreshMan_GamePass_Update_Level();--等级信息刷新
		FreshMan_GamePass_Update_AwardList()--奖励领取刷新
		
		-- 战令奖励页签
		if g_FreshMan_GamePass_ShowInterface == 1 then
			FreshMan_GamePass_ChangeInterface( g_FreshMan_GamePass_ShowInterface );
			
		else  --任务页签
			FreshMan_GamePass_Mission_OpenMisList( g_FreshMan_GamePass_ShowMisType )
						
		end
	elseif event == "XINSHOUZHANLING_BUY" and this:IsVisible() then

		--界面正在加载中
		if(g_FreshMan_GamePass_AwardItemUp > 1 or g_FreshMan_GamePass_AwardItemDown < 100)then
			PushDebugMessage("#{XSZL_220511_103}")
			return
		end

		if(tonumber(arg0) == 1)then
			FreshMan_GamePass_Buy_Level(tonumber(arg1))
		elseif(tonumber(arg0) == 2)then
			FreshMan_GamePass_Buy_JingYing()
		end

	elseif event == "UI_COMMAND" and (tonumber(arg0) == 99811201) then	--购买等级，刷新界面
		FreshMan_GamePass_Update_BuyLevel(Get_XParam_INT(0))
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 99811202) and this:IsVisible() then	--领取等级奖励，刷新界面
		FreshMan_GamePass_Update_GetAward(Get_XParam_INT(0),Get_XParam_INT(1))
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 99811203) then	--解锁精英，刷新界面
		FreshMan_GamePass_Update_UnlockJingYing()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 99811207) then --红点刷新
		FreshMan_GamePass_Update_RedPoint(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5),Get_XParam_INT(6))
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 99811208) then --打开购买等级界面
		OpenWindow("FreshMan_GamePass_GradeBuy")
	end
end

--主界面打开
function FreshMan_GamePass_Open()
	FreshMan_GamePass_Left_Buttontab01:SetCheck(1);
	
	FreshMan_GamePass_Update_Level() --等级信息刷新
	FreshMan_GamePass_ChangeInterface(1)
	this:Show()
	FreshMan_GamePass_OpenAward() --刷新奖励界面数据

	--界面介绍刷新
	local nEndYear,nEndMonth,nEndDay = LuaFnXinShouZhanLing_GetEndTime();
	FreshMan_GamePass_Reward_Info:SetText(ScriptGlobal_Format("#{XSZL_220511_04}", tostring(nEndYear),tostring(nEndMonth),tostring(nEndDay)))
end

--界面切换
function FreshMan_GamePass_ChangeInterface(index)
		
	g_FreshMan_GamePass_ShowInterface = index
	
	FreshMan_GamePass_Mission_ClearButtonBar()	
	
	if(index == 1)then
		FreshMan_GamePass_ShowMisssion(0)
		FreshMan_GamePass_RewardClient:Show()
		
	elseif(index == 2)then	
		FreshMan_GamePass_RewardClient:Hide()
		FreshMan_GamePass_ShowMisssion(1)
		
	end
end
--奖励界面打开 只有第一次打开该界面的时候进行奖励列表的刷新，每次切换刷新的话会卡
function FreshMan_GamePass_OpenAward()

	if(LuaFnXinShouZhanLing_GetHaveJingying() > 0)then
		FreshMan_GamePass_Reward_EliteBlock:Hide()--精英奖励的蒙版刷新
		FreshMan_GamePass_Reward_BuyEliteButton:Hide()--解锁精英按钮刷新
	else
		FreshMan_GamePass_Reward_EliteBlock:Show()
		FreshMan_GamePass_Reward_BuyEliteButton:Show()
	end

	--先导奖励刷新
	--FreshMan_GamePass_Update_PreAwared()

	local nPutongFlag = LuaFnXinShouZhanLing_GetAwardProgressPutong()
	local nJingyingFlag = LuaFnXinShouZhanLing_GetAwardProgressJingying()

	--定位可领
	local temLevel = 0 --该领取的等级
	if(LuaFnXinShouZhanLing_GetHaveJingying() < 1)then
		temLevel = nPutongFlag
	else
		if(nPutongFlag <= nJingyingFlag)then
			temLevel = nPutongFlag
		elseif(nPutongFlag > nJingyingFlag)then
			temLevel = nJingyingFlag
		end
	end
	
	--奖励列表初始化
	if(g_FreshMan_GamePass_AwardItemUp <= 1 and g_FreshMan_GamePass_AwardItemDown >= 100)then
		FreshMan_GamePass_Update_AwardList()
		FreshMan_GamePass_RewardList:SetScrollPosition4Index(temLevel - 1)
	else
		KillTimer("FreshMan_GamePass_Timer_AddAwardList()")
		FreshMan_GamePass_RewardList:Clear()
		g_FreshMan_GamePass_AwardItemList = {}
		if(g_FreshMan_GamePass_FirstLoad == 0)then
			for i = 1 , 10 do 
				FreshMan_GamePass_AddAWard(temLevel+i,nPutongFlag,nJingyingFlag,-1)
			end
			g_FreshMan_GamePass_AwardItemUp = temLevel
			g_FreshMan_GamePass_AwardItemDown = temLevel+10+1
			SetTimer("FreshMan_GamePass","FreshMan_GamePass_Timer_AddAwardList()", 200)
			g_FreshMan_GamePass_FirstLoad = 1
		else
			for i = 1 , 100 do 
				FreshMan_GamePass_AddAWard(i,nPutongFlag,nJingyingFlag,-1)
			end
			g_FreshMan_GamePass_AwardItemUp = 0
			g_FreshMan_GamePass_AwardItemDown = 101
		end
	end
end

function FreshMan_GamePass_Timer_AddAwardList()

	KillTimer("FreshMan_GamePass_Timer_AddAwardList()")

	--PushDebugMessage(tostring("timer "..g_FreshMan_GamePass_AwardItemUp).."  "..tostring(g_FreshMan_GamePass_AwardItemDown))
	
	local nPutongFlag = LuaFnXinShouZhanLing_GetAwardProgressPutong()
	local nJingyingFlag = LuaFnXinShouZhanLing_GetAwardProgressJingying()
	
	local nPos = FreshMan_GamePass_RewardList:GetScrollPosition()

	if(g_FreshMan_GamePass_AwardItemUp >= 1 )then
		local nAddCount = 0
		for i=1, 10 do
			if g_FreshMan_GamePass_AwardItemUp < 1 then
				break
			end
			FreshMan_GamePass_AddAWard( g_FreshMan_GamePass_AwardItemUp, nPutongFlag,nJingyingFlag,0)
			g_FreshMan_GamePass_AwardItemUp = g_FreshMan_GamePass_AwardItemUp - 1;			
			nAddCount = nAddCount + 1
		end
		FreshMan_GamePass_RewardList:SetScrollPosition(nPos + nAddCount * 52)
	end
	
	if(g_FreshMan_GamePass_AwardItemDown < 100)then
		for i=1, 10 do
			if(g_FreshMan_GamePass_AwardItemDown > 100)then
				break
			end
			FreshMan_GamePass_AddAWard(g_FreshMan_GamePass_AwardItemDown,nPutongFlag,nJingyingFlag,FreshMan_GamePass_RewardList:GetListItemCount())
			g_FreshMan_GamePass_AwardItemDown = g_FreshMan_GamePass_AwardItemDown + 1;			
		end
	end

	if(g_FreshMan_GamePass_AwardItemDown <= 100 or g_FreshMan_GamePass_AwardItemUp >= 1)then
		SetTimer("FreshMan_GamePass","FreshMan_GamePass_Timer_AddAwardList()", 200)
	end
	
end

function FreshMan_GamePass_AddAWard(nLevel,nPutongFlag,nJingyingFlag,nInsert)
	if(nLevel < 1 or nLevel > 100)then
		return
	end
	local i = nLevel
	local putong_award1,putong_award1bind,putong_award2,putong_award2bind,jingying_award1,jingying_award1bind,jingying_award2,jingying_award2bind,number1,number2,number3,number4 = LuaFnXinShouZhanLing_GetAwardInfo(i)
		local item = g_FreshMan_GamePass_AwardItemList[i]
		if(g_FreshMan_GamePass_AwardItemList[i] == nil)then
			if(nInsert > -1 )then
				item =  FreshMan_GamePass_RewardList:AddChild2Item("FreshMan_GamePass_RewardContent",nInsert)	
			else
				item =  FreshMan_GamePass_RewardList:AddChild("FreshMan_GamePass_RewardContent")	
			end
			g_FreshMan_GamePass_AwardItemList[i] = item

			item:SetSubItemEvent("FreshMan_GamePass_Reward_BasicGetButton", "Clicked", "FreshMan_GamePass_Award_GetAward("..i..",1"..")")
			item:SetSubItemEvent("FreshMan_GamePass_Reward_AdvancedGetButton", "Clicked", "FreshMan_GamePass_Award_GetAward("..i..",2"..")")
		end
		item:GetSubItem("FreshMan_GamePass_RewardLevel"):SetText(i);

		item:GetSubItem("FreshMan_GamePass_Reward_BasicGetMark"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_BasicDisableMark"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_BasicGetButton"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetButton"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetMark"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_AdvancedDisableMark"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_EliteItem1_LockImg"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_LockImg"):Hide();
		item:GetSubItem("FreshMan_GamePass_Reward_SPLine"):Hide()
		item:GetSubItem("FreshMan_GamePass_Reward_NormalItem1_Animate"):Hide()
		item:GetSubItem("FreshMan_GamePass_Reward_NormalItem2_Animate"):Hide()
		item:GetSubItem("FreshMan_GamePass_Reward_EliteItem1_Animate"):Hide()
		item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_Animate"):Hide()

		--特殊等级展示处理
		if(i == 20 or i == 40 or i == 60 or i == 80)then
			item:GetSubItem("FreshMan_GamePass_Reward_SPLine"):Show()
			item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_Animate"):Show()
		end



		if(g_FreshMan_GamePass_Level >= i)then
			if(nPutongFlag >= i)then
				item:GetSubItem("FreshMan_GamePass_Reward_BasicGetMark"):Show();
			else
				item:GetSubItem("FreshMan_GamePass_Reward_BasicGetButton"):Show();
			end

			if(LuaFnXinShouZhanLing_GetHaveJingying() < 1)then
				item:GetSubItem("FreshMan_GamePass_Reward_EliteItem1_LockImg"):Show();
				item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_LockImg"):Show();
			else
				if(nJingyingFlag >= i)then
					item:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetMark"):Show();
				else
					item:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetButton"):Show();
				end
			end
		else
			item:GetSubItem("FreshMan_GamePass_Reward_BasicDisableMark"):Show();
			if(LuaFnXinShouZhanLing_GetHaveJingying() < 1)then
				item:GetSubItem("FreshMan_GamePass_Reward_EliteItem1_LockImg"):Show();
				item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_LockImg"):Show();
			else
				item:GetSubItem("FreshMan_GamePass_Reward_AdvancedDisableMark"):Show();
			end
		end

		item:GetSubItem("FreshMan_GamePass_Reward_NormalItem1"):Hide()
		item:GetSubItem("FreshMan_GamePass_Reward_NormalItem2"):Hide()
		item:GetSubItem("FreshMan_GamePass_Reward_EliteItem1"):Hide()
		item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2"):Hide()
		local theAction1 = nil
		local theAction2 = nil
		local theAction3 = nil
		local theAction4 = nil
		if(putong_award1bind == 1)then
			theAction1 = DataPool:CreateBindActionItemForShow(putong_award1, number1)
		elseif(putong_award1bind == 0)then
			theAction1 = DataPool:CreateActionItemForShow(putong_award1, number1)
		end

		if(putong_award2bind == 1)then
			theAction2 = DataPool:CreateBindActionItemForShow(putong_award2, number2)
		elseif(putong_award2bind == 0)then
			theAction2 = DataPool:CreateActionItemForShow(putong_award2, number2)
		end

		if(jingying_award1bind == 1)then
			theAction3 = DataPool:CreateBindActionItemForShow(jingying_award1, number3)
		elseif(jingying_award1bind == 0)then
			theAction3 = DataPool:CreateActionItemForShow(jingying_award1, number3)
		end

		if(jingying_award2bind == 1)then
			theAction4 = DataPool:CreateBindActionItemForShow(jingying_award2, number4)
		elseif(jingying_award2bind == 0)then
			theAction4 = DataPool:CreateActionItemForShow(jingying_award2, number4)
		end

		if(theAction1 ~= nil and theAction1:GetID() ~= 0)then
			item:GetSubItem("FreshMan_GamePass_Reward_NormalItem1"):SetActionItem(theAction1:GetID())
			item:GetSubItem("FreshMan_GamePass_Reward_NormalItem1"):Show()
		end

		if(theAction2 ~= nil and theAction2:GetID() ~= 0)then
			item:GetSubItem("FreshMan_GamePass_Reward_NormalItem2"):SetActionItem(theAction2:GetID())
			item:GetSubItem("FreshMan_GamePass_Reward_NormalItem2"):Show()
		end

		if(theAction3 ~= nil and theAction3:GetID() ~= 0)then
			item:GetSubItem("FreshMan_GamePass_Reward_EliteItem1"):SetActionItem(theAction3:GetID())
			item:GetSubItem("FreshMan_GamePass_Reward_EliteItem1"):Show()
		end

		if(theAction4 ~= nil and theAction4:GetID() ~= 0)then
			item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2"):SetActionItem(theAction4:GetID())
			item:GetSubItem("FreshMan_GamePass_Reward_EliteItem2"):Show()
		end
end

--先导奖励刷新
function FreshMan_GamePass_Update_PreAwared()
	g_FreshMan_GamePass_Level = LuaFnXinShouZhanLing_GetLevel()
	FreshMan_GamePass_Reward_TenthLevel_NormalItem1:Hide()
	FreshMan_GamePass_Reward_TenthLevel_NormalItem1_Animate:Hide()
	FreshMan_GamePass_Reward_TenthLevel_NormalItem2:Hide()
	FreshMan_GamePass_Reward_TenthLevel_NormalItem2_Animate:Hide()
	FreshMan_GamePass_Reward_TenthLevel_EliteItem1:Hide()
	FreshMan_GamePass_Reward_TenthLevel_EliteItem1_Animate:Hide()
	FreshMan_GamePass_Reward_TenthLevel_EliteItem2:Hide()
	local tLevel = 20
	if(g_FreshMan_GamePass_Level < 20)then
		tLevel = 20
	elseif(g_FreshMan_GamePass_Level < 40)then
		tLevel = 40
	elseif(g_FreshMan_GamePass_Level < 60)then
		tLevel = 60
	elseif(g_FreshMan_GamePass_Level < 80)then
		tLevel = 80
	else
		tLevel = 100
	end
	
	local tputong_award1,tputong_award1bind,tputong_award2,tputong_award2bind,tjingying_award1,tjingying_award1bind,tjingying_award2,tjingying_award2bind,tnumber1,tnumber2,tnumber3,tnumber4 = LuaFnXinShouZhanLing_GetAwardInfo(tLevel)
	FreshMan_GamePass_Reward_TenthLevel:SetText(ScriptGlobal_Format("#{XSZL_220511_78}", tLevel))
	local Action1 = nil
	local Action2 = nil
	local Action3 = nil
	local Action4 = nil
	if(tputong_award1bind == 1)then
		Action1 = DataPool:CreateBindActionItemForShow(tputong_award1, tnumber1)
	elseif(tputong_award1bind == 0)then
		Action1 = DataPool:CreateActionItemForShow(tputong_award1, tnumber1)
	end

	if(tputong_award2bind == 1)then
		Action2 = DataPool:CreateBindActionItemForShow(tputong_award2, tnumber2)
	elseif(tputong_award2bind == 0)then
		Action2 = DataPool:CreateActionItemForShow(tputong_award2, tnumber2)
	end

	if(tjingying_award1bind == 1)then
		Action3 = DataPool:CreateBindActionItemForShow(tjingying_award1, tnumber3)
	elseif(tjingying_award1bind == 0)then
		Action3 = DataPool:CreateActionItemForShow(tjingying_award1, tnumber3)
	end

	if(tjingying_award2bind == 1)then
		Action4 = DataPool:CreateBindActionItemForShow(tjingying_award2, tnumber4)
	elseif(tjingying_award2bind == 0)then
		Action4 = DataPool:CreateActionItemForShow(tjingying_award2, tnumber4)
	end

	if(Action1 ~= nil and Action1:GetID() ~= 0)then
		FreshMan_GamePass_Reward_TenthLevel_NormalItem1:SetActionItem(Action1:GetID())
		FreshMan_GamePass_Reward_TenthLevel_NormalItem1:Show()
	end

	if(Action2 ~= nil and Action2:GetID() ~= 0)then
		FreshMan_GamePass_Reward_TenthLevel_NormalItem2:SetActionItem(Action2:GetID())
		FreshMan_GamePass_Reward_TenthLevel_NormalItem2:Show()
	end

	if(Action3 ~= nil and Action3:GetID() ~= 0)then
		FreshMan_GamePass_Reward_TenthLevel_EliteItem1:SetActionItem(Action3:GetID())
		FreshMan_GamePass_Reward_TenthLevel_EliteItem1:Show()
	end

	if(Action4 ~= nil and Action4:GetID() ~= 0)then
		FreshMan_GamePass_Reward_TenthLevel_EliteItem2:SetActionItem(Action4:GetID())
		FreshMan_GamePass_Reward_TenthLevel_EliteItem2:Show()
	end
end
--奖励列表刷新
function FreshMan_GamePass_Update_AwardList()
	g_FreshMan_GamePass_Level = LuaFnXinShouZhanLing_GetLevel()
	local nPutongFlag = LuaFnXinShouZhanLing_GetAwardProgressPutong()
	local nJingyingFlag = LuaFnXinShouZhanLing_GetAwardProgressJingying()
	--刷新奖励列表
	for i = 1, 100 do
		if(g_FreshMan_GamePass_AwardItemList[i] == nil)then
			return
		end

		local putong_award1,putong_award1bind,putong_award2,putong_award2bind,jingying_award1,jingying_award1bind,jingying_award2,jingying_award2bind,number1,number2,number3,number4 = LuaFnXinShouZhanLing_GetAwardInfo(i)

		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_BasicGetMark"):Hide();
		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_BasicDisableMark"):Hide();
		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_BasicGetButton"):Hide();
		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetButton"):Hide();
		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetMark"):Hide();
		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_AdvancedDisableMark"):Hide();
		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem1_LockImg"):Hide();
		g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_LockImg"):Hide();

		if(g_FreshMan_GamePass_Level >= i)then
			if(nPutongFlag >= i)then
				g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_BasicGetMark"):Show();
			else
				g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_BasicGetButton"):Show();
			end

			if(LuaFnXinShouZhanLing_GetHaveJingying() < 1)then
				g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem1_LockImg"):Show();
				g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_LockImg"):Show();
			else
				if(nJingyingFlag >= i)then
					g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetMark"):Show();
				else
					g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetButton"):Show();
				end
			end
		else
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_BasicDisableMark"):Show();
			if(LuaFnXinShouZhanLing_GetHaveJingying() < 1)then
				g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem1_LockImg"):Show();
				g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem2_LockImg"):Show();
			else
				g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_AdvancedDisableMark"):Show();
			end
		end

		local theAction1 = nil
		local theAction2 = nil
		local theAction3 = nil
		local theAction4 = nil
		if(putong_award1bind == 1)then
			theAction1 = DataPool:CreateBindActionItemForShow(putong_award1, number1)
		elseif(putong_award1bind == 0)then
			theAction1 = DataPool:CreateActionItemForShow(putong_award1, number1)
		end

		if(putong_award2bind == 1)then
			theAction2 = DataPool:CreateBindActionItemForShow(putong_award2, number2)
		elseif(putong_award2bind == 0)then
			theAction2 = DataPool:CreateActionItemForShow(putong_award2, number2)
		end

		if(jingying_award1bind == 1)then
			theAction3 = DataPool:CreateBindActionItemForShow(jingying_award1, number3)
		elseif(jingying_award1bind == 0)then
			theAction3 = DataPool:CreateActionItemForShow(jingying_award1, number3)
		end

		if(jingying_award2bind == 1)then
			theAction4 = DataPool:CreateBindActionItemForShow(jingying_award2, number4)
		elseif(jingying_award2bind == 0)then
			theAction4 = DataPool:CreateActionItemForShow(jingying_award2, number4)
		end

		if(theAction1 ~= nil and theAction1:GetID() ~= 0)then
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_NormalItem1"):SetActionItem(theAction1:GetID())
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_NormalItem1"):Show()
		end

		if(theAction2 ~= nil and theAction2:GetID() ~= 0)then
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_NormalItem2"):SetActionItem(theAction2:GetID())
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_NormalItem2"):Show()
		end

		if(theAction3 ~= nil and theAction3:GetID() ~= 0)then
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem1"):SetActionItem(theAction3:GetID())
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem1"):Show()
		end

		if(theAction4 ~= nil and theAction4:GetID() ~= 0)then
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem2"):SetActionItem(theAction4:GetID())
			g_FreshMan_GamePass_AwardItemList[i]:GetSubItem("FreshMan_GamePass_Reward_EliteItem2"):Show()
		end
	end
end

--战令等级刷新 
function FreshMan_GamePass_Update_Level()
	--战令等级显示
	g_FreshMan_GamePass_Level = LuaFnXinShouZhanLing_GetLevel()

	FreshMan_GamePass_LevelProgress_LevelText:SetText(ScriptGlobal_Format("#{XSZL_220511_110}", g_FreshMan_GamePass_Level))
	--FreshMan_GamePass_LevelProgress_LevelNum_OneDigit:Hide()
	--FreshMan_GamePass_LevelProgress_LevelNum_DoubleDigit:Hide()
	--FreshMan_GamePass_LevelProgress_LevelNum_ThreeDigit:Hide()

	--if(g_FreshMan_GamePass_Level < 10)then
		--FreshMan_GamePass_LevelProgress_LevelNum1 : SetProperty("Image", g_FreshMan_GamePass_NumberImg[g_FreshMan_GamePass_Level])
		--FreshMan_GamePass_LevelProgress_LevelNum_OneDigit:Show()
	--elseif(g_FreshMan_GamePass_Level < 100 and g_FreshMan_GamePass_Level >= 10)then
		--local gewei = math.mod( g_FreshMan_GamePass_Level, 10);
		--local shiwei = math.mod( math.floor(g_FreshMan_GamePass_Level/10), 10);
		--FreshMan_GamePass_LevelProgress_LevelNum2 : SetProperty("Image", g_FreshMan_GamePass_NumberImg[shiwei])
		--FreshMan_GamePass_LevelProgress_LevelNum3 : SetProperty("Image", g_FreshMan_GamePass_NumberImg[gewei])
		--FreshMan_GamePass_LevelProgress_LevelNum_DoubleDigit:Show()
	--elseif(g_FreshMan_GamePass_Level == 100)then
		--FreshMan_GamePass_LevelProgress_LevelNum_ThreeDigit:Show()
	--end

	--战令经验显示
	if(g_FreshMan_GamePass_Level < 100)then
		g_FreshMan_GamePass_Exp = LuaFnXinShouZhanLing_GetExp()
		FreshMan_GamePass_LevelProgress_Jindu:SetText(ScriptGlobal_Format("#{XSZL_220511_06}", g_FreshMan_GamePass_Exp))
		--FreshMan_GamePass_LevelProgress:SetProgress(g_FreshMan_GamePass_Exp, 500);
	else
		FreshMan_GamePass_LevelProgress_Jindu:SetText("#{XSZL_220511_08}")
		--FreshMan_GamePass_LevelProgress:SetProgress(500, 500);
	end

	--每周经验刷新
	if(g_FreshMan_GamePass_Level < 100)then
		local WeekExp = LuaFnXinShouZhanLing_GetWeekExp()
		FreshMan_GamePass_LevelProgress_WeeklyJindu:Show()
		FreshMan_GamePass_LevelProgress_WeeklyJindu:SetText(ScriptGlobal_Format("#{XSZL_220511_09}", WeekExp))
		FreshMan_GamePass_LevelProgress_WeeklyJindu:SetToolTip(ScriptGlobal_Format("#{XSZL_220511_10}", WeekExp))
	else
		FreshMan_GamePass_LevelProgress_WeeklyJindu:Hide()
	end

	--购买等级按钮刷新
	local bCanBuyLevel,nBuyLevelYear,nBuyLevelMonth,nBuyLevelDay = LuaFnXinShouZhanLing_GetBuyTime();
	if(bCanBuyLevel == 1)then
		FreshMan_GamePass_LevelProgress_LevelBuy:SetToolTip("#{XSZL_220511_77}")
	else
		FreshMan_GamePass_LevelProgress_LevelBuy:SetToolTip(ScriptGlobal_Format("#{XSZL_220511_76}", nBuyLevelYear,nBuyLevelMonth,nBuyLevelDay))
	end
end

--任务界面打开
function FreshMan_GamePass_ShowMisssion(isShow)
	if(isShow == 1)then
		FreshMan_GamePass_MissionClient:Show()
		
		FreshMan_GamePass_MissionShow();
		FreshMan_GamePass_Mission_OnWeekClicked()
		
	elseif(isShow == 0)then
		FreshMan_GamePass_MissionClient:Hide()
	end
end
--购买等级后刷新界面
function FreshMan_GamePass_Update_BuyLevel(newLevel)
	--战令等级刷新
	LuaFnXinShouZhanLing_SetLevel(newLevel)
	FreshMan_GamePass_Update_Level()
	--先导奖励刷新
	--FreshMan_GamePass_Update_PreAwared()
	--奖励列表刷新
	FreshMan_GamePass_Update_AwardList()
	
	--购买成功，关闭购买界面
	CloseWindow("FreshMan_GamePass_GradeBuy")
end

--解锁精英奖励后刷新界面
function FreshMan_GamePass_Update_UnlockJingYing()
	--精英奖励的蒙版隐藏
	FreshMan_GamePass_Reward_EliteBlock:Hide()
	--数据刷新
	LuaFnXinShouZhanLing_SetHaveJingying(1)
	FreshMan_GamePass_Update_AwardList()

	--解锁成功 关闭解锁界面
	CloseWindow("FreshMan_GamePass_UnlockElite")
	--解锁成功 隐藏解锁按钮
	FreshMan_GamePass_Reward_BuyEliteButton:Hide()
	--定位可领
	FreshMan_GamePass_RewardList:SetScrollPosition4Index(0)
end	
--领取等级奖励后刷新界面
function FreshMan_GamePass_Update_GetAward(ntype,nLevel)
	if(ntype == 1)then
		LuaFnXinShouZhanLing_SetAwardProgressPutong(nLevel)
		g_FreshMan_GamePass_AwardItemList[nLevel]:GetSubItem("FreshMan_GamePass_Reward_BasicDisableMark"):Hide();
		g_FreshMan_GamePass_AwardItemList[nLevel]:GetSubItem("FreshMan_GamePass_Reward_BasicGetButton"):Hide();
		g_FreshMan_GamePass_AwardItemList[nLevel]:GetSubItem("FreshMan_GamePass_Reward_BasicGetMark"):Show();
	elseif(ntype == 2)then
		LuaFnXinShouZhanLing_SetAwardProgressJingying(nLevel)
		g_FreshMan_GamePass_AwardItemList[nLevel]:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetButton"):Hide();
		g_FreshMan_GamePass_AwardItemList[nLevel]:GetSubItem("FreshMan_GamePass_Reward_AdvancedDisableMark"):Hide();
		g_FreshMan_GamePass_AwardItemList[nLevel]:GetSubItem("FreshMan_GamePass_Reward_AdvancedGetMark"):Show();
	end

end

--红点刷新
function FreshMan_GamePass_Update_RedPoint(arg1,arg2,arg3,arg4,arg5,arg6,arg7)
	--奖励界面
	if(arg1 == 1)then
		FreshMan_GamePass_Left_Buttontab01_Tips:Show()
	else
		FreshMan_GamePass_Left_Buttontab01_Tips:Hide()
	end

	if arg2 + arg3 + arg4 + arg5 + arg6 + arg7 > 0 then
		FreshMan_GamePass_Left_Buttontab02_Tips:Show()
	else
		FreshMan_GamePass_Left_Buttontab02_Tips:Hide()
	end
	--本周任务
	g_FreshMan_GamePass_MissionConfig[1].redpoint = arg2;
	
	--累积任务
	if( arg3 + arg4 + arg5 + arg6 + arg7 > 0 )then
		g_FreshMan_GamePass_MissionConfig[2].redpoint = 1;
	else
		g_FreshMan_GamePass_MissionConfig[2].redpoint = 0;
	end
	
	for i=1, 2 do
		if g_FreshMan_GamePass_MissionBtnRedpoint[i] ~= nil then
			if g_FreshMan_GamePass_MissionConfig[i].redpoint > 0 then
				g_FreshMan_GamePass_MissionBtnRedpoint[i]:Show();
			else
				g_FreshMan_GamePass_MissionBtnRedpoint[i]:Hide();
			end
		end
	end
		
	local CfgChild=g_FreshMan_GamePass_MissionConfig[2].Child;
	local kjtype   = KaJi:LuaFnGetKaJiType(90)
	if kjtype == 1 then
		CfgChild=g_FreshMan_GamePass_MissionConfig[2].ChildKaJi;
	end
	CfgChild[1].redpoint = arg3;
	CfgChild[2].redpoint = arg4;
	CfgChild[3].redpoint = arg5;
	CfgChild[4].redpoint = arg6;
	
	for i=1, 4 do
		if g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[i] ~= nil then
			if CfgChild[i].redpoint > 0 then
				g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[i]:Show();
			else
				g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[i]:Hide();
			end
		end
	end
	
end

function FreshMan_GamePass_OnHiden()
	CloseWindow("FreshMan_GamePass_GradeBuy")
	CloseWindow("FreshMan_GamePass_UnlockElite")
	this:Hide()
end

function FreshMan_GamePass_OnClosed()
	FreshMan_GamePass_OnHiden()
end

--左边界面选择按钮 点击
function FreshMan_GamePass_Project_Clicked(index)

	if(index == 1)then
		FreshMan_GamePass_Left_Buttontab01:SetCheck(1);
		FreshMan_GamePass_Left_Buttontab02:SetCheck(0);
		FreshMan_GamePass_ChangeInterface(1)
	elseif(index == 2)then
		FreshMan_GamePass_Left_Buttontab01:SetCheck(0);
		FreshMan_GamePass_Left_Buttontab02:SetCheck(1);
		FreshMan_GamePass_ChangeInterface(2)
	end
end

--奖励界面 领取奖励点击
function FreshMan_GamePass_Award_GetAward(level,type)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLevelAward" )
		Set_XSCRIPT_ScriptID( 998112 )
		Set_XSCRIPT_Parameter(0, level)							
		Set_XSCRIPT_Parameter(1, type)				
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--购买等级 点击
function FreshMan_GamePass_LevelProgress_Level_ClickBuy(index)

	g_FreshMan_GamePass_Level = LuaFnXinShouZhanLing_GetLevel()
	if(g_FreshMan_GamePass_Level >= 100)then
		PushDebugMessage("#{XSZL_220511_68}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenBuyLevel" )
		Set_XSCRIPT_ScriptID( 998112 )				
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--解锁精英 点击
function FreshMan_GamePass_Reward_ElitePass_ClickBuy(index)

	OpenWindow("FreshMan_GamePass_UnlockElite")
end

--帮助问号点击调用
function FreshMan_GamePass_Help_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelp" )
		Set_XSCRIPT_ScriptID( 998112 )
		Set_XSCRIPT_Parameter(0, 1)				
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--时装展示按钮点击
function FreshMan_GamePass_Reward_EyeSign_Click()
	OpenWindow("FreshMan_GamePass_DoubleLook")
end

--开始界面关闭按钮点击
function FreshMan_GamePass_Start_CloseClick()
	FreshMan_GamePass_OnClosed()
end

function FreshMan_GamePass_OnResetPos()
	FreshMan_GamePass_Frame:SetProperty("UnifiedPosition", g_FreshMan_GamePass_UnifiedPosition)
end

function FreshMan_GamePass_Mission_ClearButtonState()

	-- 周任务
	g_FreshMan_GamePass_MissionConfig[1].check = 0
	if g_FreshMan_GamePass_MissionBtn[1] ~= nil then
		g_FreshMan_GamePass_MissionBtn[1]:SetCheck( g_FreshMan_GamePass_MissionConfig[1].check )
	end
	
	-- 累计任务
	g_FreshMan_GamePass_TaskShow_TagBtnIndex = 1;
	local MissionChildConfig = g_FreshMan_GamePass_MissionConfig[2].Child;
	local kjtype   = KaJi:LuaFnGetKaJiType(90)
	if kjtype == 1 then
		MissionChildConfig=g_FreshMan_GamePass_MissionConfig[2].ChildKaJi;
	end
		
	if MissionChildConfig == nil then
		return
	end
	
	for i=1, table.getn(MissionChildConfig) do
		MissionChildConfig[i].check = 0
		g_FreshMan_GamePass_MissionLeiJiBtn[i]:SetCheck( MissionChildConfig[i].check );
	end
	
end

function FreshMan_GamePass_Mission_ClearButtonBar()
	g_FreshMan_GamePass_MissionConfig[2].fold = 1;
end

function FreshMan_GamePass_MissionShow()
	FreshMan_GamePass_Mission_ClearButtonBar()
	
	-- 第一层按钮
	g_FreshMan_GamePass_MissionBtn[1] = FreshMan_GamePass_Mission_LeftFrame_BtnL1;
	g_FreshMan_GamePass_MissionBtn[2] = FreshMan_GamePass_Mission_LeftFrame_BtnL2;
	g_FreshMan_GamePass_MissionBtnRedpoint[1] = FreshMan_GamePass_Mission_LeftFrame_BtnL1_Tips;
	g_FreshMan_GamePass_MissionBtnRedpoint[2] = FreshMan_GamePass_Mission_LeftFrame_BtnL2_Tips;
	
	for i=1, 2 do
		g_FreshMan_GamePass_MissionBtn[i]:SetCheck( g_FreshMan_GamePass_MissionConfig[i].check )
		
		--小红点
		if g_FreshMan_GamePass_MissionConfig[i].redpoint > 0 then
			g_FreshMan_GamePass_MissionBtnRedpoint[i]:Show();
		else
			g_FreshMan_GamePass_MissionBtnRedpoint[i]:Hide();
		end
	end
	
	-- 第一层按钮: 累计任务
	local MissionChildConfig = nil
	local kjtype   = KaJi:LuaFnGetKaJiType(90)
	if kjtype == 1 then
		MissionChildConfig = g_FreshMan_GamePass_MissionConfig[2].ChildKaJi;
	else
		MissionChildConfig = g_FreshMan_GamePass_MissionConfig[2].Child;
	end	
	if MissionChildConfig == nil then
		return
	end
	
	g_FreshMan_GamePass_MissionLeiJiBtn[1] = FreshMan_GamePass_Mission_LeftFrame_BtnS1;
	g_FreshMan_GamePass_MissionLeiJiBtn[2] = FreshMan_GamePass_Mission_LeftFrame_BtnS2;
	g_FreshMan_GamePass_MissionLeiJiBtn[3] = FreshMan_GamePass_Mission_LeftFrame_BtnS3;
	g_FreshMan_GamePass_MissionLeiJiBtn[4] = FreshMan_GamePass_Mission_LeftFrame_BtnS4;
	
	g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[1] = FreshMan_GamePass_Mission_LeftFrame_BtnS1_Tips;
	g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[2] = FreshMan_GamePass_Mission_LeftFrame_BtnS2_Tips;
	g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[3] = FreshMan_GamePass_Mission_LeftFrame_BtnS3_Tips;
	g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[4] = FreshMan_GamePass_Mission_LeftFrame_BtnS4_Tips;
			
	for i=1, 4 do
		g_FreshMan_GamePass_MissionLeiJiBtn[i]:SetCheck( MissionChildConfig[i].check );
		g_FreshMan_GamePass_MissionLeiJiBtn[i]:SetText( MissionChildConfig[i].szText );
		
		--小红点
		if MissionChildConfig[i].redpoint > 0 then
			g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[i]:Show();
		else
			g_FreshMan_GamePass_MissionLeiJiBtnRedpoint[i]:Hide();
		end
	end
	
	if g_FreshMan_GamePass_MissionConfig[2].fold == 1 then
		FreshMan_GamePass_Mission_LeftFrame_BtnS:Hide();
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("PushedImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_UP_Hover" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("NormalImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_UP_Normal" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("HoverImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_UP_Hover" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetCheck(0)
	end
			
end

function FreshMan_GamePass_Mission_OnWeekClicked()
	
	FreshMan_GamePass_Mission_ClearButtonState();
	FreshMan_GamePass_Mission_OpenMisList( g_FreshMan_GamePass_MissionConfig[1].misType )
	g_FreshMan_GamePass_MissionConfig[1].check = 1
	
	--按钮状态	
	if g_FreshMan_GamePass_MissionBtn[1] ~= nil then
		g_FreshMan_GamePass_MissionBtn[1]:SetCheck( g_FreshMan_GamePass_MissionConfig[1].check )
	end
	
end

function FreshMan_GamePass_Mission_OnLeiJiClicked()

	if g_FreshMan_GamePass_MissionConfig[2].fold == 1 then
		FreshMan_GamePass_Mission_LeftFrame_BtnS:Show();
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("PushedImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_Down_Hover" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("NormalImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_Down_Normal" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("HoverImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_Down_Hover" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetCheck(0)
		g_FreshMan_GamePass_MissionConfig[2].fold = 0
		
		--点击累计任务
		if g_FreshMan_GamePass_MissionConfig[2].redpoint > 0 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnUpdateRedPoint" )
				Set_XSCRIPT_ScriptID( 998112 )
				Set_XSCRIPT_Parameter( 0, 1 )
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()	
		end
	else
		FreshMan_GamePass_Mission_LeftFrame_BtnS:Hide();
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("PushedImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_UP_Hover" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("NormalImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_UP_Normal" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetProperty("HoverImage", "set:Freshman_GamePass01 image:Mission_AccumulatedBtn_UP_Hover" )
		FreshMan_GamePass_Mission_LeftFrame_BtnL2:SetCheck(0)
		g_FreshMan_GamePass_MissionConfig[2].fold = 1
	end
end


function FreshMan_GamePass_Mission_OnMisClicked( index )
	
	if g_FreshMan_GamePass_MissionConfig[2] == nil then
		return
	end
	
	local MissionChildConfig = g_FreshMan_GamePass_MissionConfig[2].Child;
	local kjtype   = KaJi:LuaFnGetKaJiType(90)
	if kjtype == 1 then
		MissionChildConfig=g_FreshMan_GamePass_MissionConfig[2].ChildKaJi;
	end
	
	if MissionChildConfig == nil or MissionChildConfig[index] == nil then
		return
	end

	FreshMan_GamePass_Mission_OpenMisList( MissionChildConfig[index].misType )
	
	--按钮状态
	FreshMan_GamePass_Mission_ClearButtonState();
	g_FreshMan_GamePass_TaskShow_TagBtnIndex = index;
	
	MissionChildConfig[index].check = 1
	if g_FreshMan_GamePass_MissionLeiJiBtn[index] ~= nil then
		g_FreshMan_GamePass_MissionLeiJiBtn[index]:SetCheck( MissionChildConfig[index].check );
	end
	
end

function FreshMan_GamePass_Mission_OpenMisList( misType )

	-- 读取数据
	local tblDataNormal={};
	local tblDataAward={};
	local tblDataFinish={};
	local nNormalCount = 0;
	local nAwardtblCount = 0;
	local nFinishCount = 0;
	
	g_FreshMan_GamePass_ShowMisType = misType;
	
	local nStartIndex = 0;
	for i=1, 100 do		--最多100个任务，保证不出现死循环
		local nIndex, nTaskID, szDesc, nAwardCount, nNeedCount = LuaFnXinShouZhanLing_GetMissionConfig( nStartIndex, misType );
		if nIndex == nil then
			break;
		end
		
		nStartIndex = nIndex+1;
		
		--得到任务数据
		local nFinishCnt, bIsGetPrize = LuaFnXinShouZhanLing_GetMissionData( nTaskID );
		if nFinishCnt == nil or bIsGetPrize == nil then
			break;
		end
		
		if nFinishCnt >= nNeedCount then
			if bIsGetPrize > 0 then
				nFinishCount = nFinishCount + 1;
				tblDataFinish[nFinishCount]={nIndex=nIndex, nTaskID=nTaskID, szDesc=szDesc, nAwardCount=nAwardCount, nNeedCount=nNeedCount, nFinishCnt=nFinishCnt, bIsGetPrize=bIsGetPrize};
			else
				nAwardtblCount = nAwardtblCount + 1;
				tblDataAward[nAwardtblCount]={nIndex=nIndex, nTaskID=nTaskID, szDesc=szDesc, nAwardCount=nAwardCount, nNeedCount=nNeedCount, nFinishCnt=nFinishCnt, bIsGetPrize=bIsGetPrize};
			end
		else			
			nNormalCount = nNormalCount + 1;
			tblDataNormal[nNormalCount]={nIndex=nIndex, nTaskID=nTaskID, szDesc=szDesc, nAwardCount=nAwardCount, nNeedCount=nNeedCount, nFinishCnt=nFinishCnt, bIsGetPrize=bIsGetPrize};
		end
	end
	
	local tblData={}
	local nShowCount = 0
	for i=1, nAwardtblCount do
		nShowCount = nShowCount + 1;
		tblData[nShowCount] = tblDataAward[i];
	end
	for i=1, nNormalCount do
		nShowCount = nShowCount + 1;
		tblData[nShowCount] = tblDataNormal[i];
	end
	for i=1, nFinishCount do
		nShowCount = nShowCount + 1;
		tblData[nShowCount] = tblDataFinish[i];
	end
	
	FreshMan_GamePass_MissionList:Clear();
	for i=1, nShowCount do
	
		local bar = FreshMan_GamePass_MissionList:AddChild("FreshMan_GamePass_MissionList_RewardContent");
		if not bar then
    	break
		end
		
		bar:GetSubItem("FreshMan_GamePass_UpFrame_MissionRequest"):SetText( tblData[i].szDesc );
		
		bar:GetSubItem("FreshMan_GamePass_Mission_EXPText"):SetText( tostring(tblData[i].nAwardCount) );
		
		if tblData[i].nFinishCnt > tblData[i].nNeedCount then
			bar:GetSubItem("FreshMan_GamePass_MissionLimit"):SetText( tostring(tblData[i].nNeedCount).."/"..tostring(tblData[i].nNeedCount) );
		else
			bar:GetSubItem("FreshMan_GamePass_MissionLimit"):SetText( tostring(tblData[i].nFinishCnt).."/"..tostring(tblData[i].nNeedCount) );
		end
				
		if tblData[i].nFinishCnt >= tblData[i].nNeedCount then
			if tblData[i].bIsGetPrize > 0 then
				bar:GetSubItem("FreshMan_GamePass_Mission_GetButton"):Hide();
				bar:GetSubItem("FreshMan_GamePass_Mission_GetMark"):Show();
			else
				bar:GetSubItem("FreshMan_GamePass_Mission_GetButton"):Show();
				bar:SetSubItemEvent("FreshMan_GamePass_Mission_GetButton", "Clicked", string.format("FreshMan_GamePass_Mission_GetPrize(%d, %d)", misType, tblData[i].nTaskID) )
				bar:GetSubItem("FreshMan_GamePass_Mission_GetMark"):Hide();
			end						
			bar:GetSubItem("FreshMan_GamePass_Mission_DisableMark"):Hide();
			
		else
			bar:GetSubItem("FreshMan_GamePass_Mission_GetButton"):Hide();
			bar:GetSubItem("FreshMan_GamePass_Mission_GetMark"):Hide();
			bar:GetSubItem("FreshMan_GamePass_Mission_DisableMark"):Show();
		end
		
	end
	
	--点击周任务
	if misType == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnUpdateRedPoint" )
			Set_XSCRIPT_ScriptID( 998112 )
			Set_XSCRIPT_Parameter( 0, 0 )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	end
	
end

function FreshMan_GamePass_Mission_GetPrize( nMisType, nTaskId )

	if(g_FreshMan_GamePass_AwardItemUp > 1 or g_FreshMan_GamePass_AwardItemDown < 100)then
		PushDebugMessage("#{XSZL_220511_103}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetTaskPrize" )
		Set_XSCRIPT_ScriptID( 998112 )
		Set_XSCRIPT_Parameter( 0, nMisType )
		Set_XSCRIPT_Parameter( 1, nTaskId )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()		
	
end

function FreshMan_GamePass_Buy_Level(level)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyLevel" )
		Set_XSCRIPT_ScriptID( 998112 )
		Set_XSCRIPT_Parameter(0, level)							
		Set_XSCRIPT_Parameter(1, 0)				
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function FreshMan_GamePass_Buy_JingYing()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyJingYing" )
		Set_XSCRIPT_ScriptID( 998112 )
		Set_XSCRIPT_Parameter(0, 0)				
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end