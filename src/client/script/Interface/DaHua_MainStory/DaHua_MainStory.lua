--DaHua_MainStory.lua

-- 界面的默认相对位置
local g_DaHua_MainStory_UnifiedXPosition
local g_DaHua_MainStory_UnifiedYPosition

local g_DaHua_MainStory_Param1
local g_DaHua_MainStory_Param2
local g_DaHua_MainStory_Param3

local g_DaHua_MainStory_StepInfo = {
 [1] = {nStart=20240801,nEnd=20240915,nMF=MF_2024_DH_PRIZE_1,nItemId=38006855,nItemNum=1,
		mission={
		 [1]={name="#{DHGS_240521_22}",misionid=3042,sceneId=0,x=263,z=253,npcname="菩提老祖"}, 
		 [2]={name="#{DHGS_240521_23}",misionid=3043,sceneId=976,x=52,z=188,npcname="悟空残念"}, 
		 [3]={name="#{DHGS_240521_24}",misionid=3044,sceneId=976,x=52,z=188,npcname="悟空残念"}, 
		 [4]={name="#{DHGS_240521_25}",misionid=3045,sceneId=977,x=156,z=45,npcname="沉思的至尊宝"}, 
		 [5]={name="#{DHGS_240521_26}",misionid=3046,sceneId=977,x=156,z=45,npcname="沉思的至尊宝"}, 
		 [6]={name="#{DHGS_240521_27}",misionid=3047,sceneId=976,x=52,z=188,npcname="悟空残念"},
		},
 },
 [2] = {nStart=20240815,nEnd=20240915,nMF=MF_2024_DH_PRIZE_2,nItemId=38006856,nItemNum=1,
		mission={
		 [1]={name="#{DHGS_240521_28}",misionid=3049,sceneId=0,x=263,z=253,npcname="菩提老祖"},
		 [2]={name="#{DHGS_240521_29}",misionid=3050,sceneId=977,x=55,z=38,npcname="唐僧"},
		 [3]={name="#{DHGS_240521_30}",misionid=3051,sceneId=977,x=82,z=97,npcname="唐僧·移魂后"},
		 [4]={name="#{DHGS_240521_31}",misionid=3052,sceneId=977,x=82,z=97,npcname="唐僧·移魂后"},
		 [5]={name="#{DHGS_240521_32}",misionid=3053,sceneId=977,x=75,z=94,npcname="孙悟空·移魂后"},
		 [6]={name="#{DHGS_240521_33}",misionid=3054,sceneId=977,x=75,z=94,npcname="孙悟空·移魂后"},
		},
 },
 [3] = {nStart=20240829,nEnd=20240915,nMF=MF_2024_DH_PRIZE_3,nItemId=38006857,nItemNum=1,
		mission={
		 [1]={name="#{DHGS_240521_34}",misionid=3034,sceneId=0,x=263,z=253,npcname="菩提老祖"}, 
		 [2]={name="#{DHGS_240521_35}",misionid=3035,sceneId=0,x=263,z=253,npcname="菩提老祖"}, 
		 [3]={name="#{DHGS_240521_36}",misionid=3036,sceneId=977,x=107,z=103,npcname="至尊宝"}, 
		 [4]={name="#{DHGS_240521_37}",misionid=3037,sceneId=977,x=107,z=103,npcname="至尊宝"}, 
		 [5]={name="#{DHGS_240521_38}",misionid=3038,sceneId=977,x=107,z=103,npcname="至尊宝"}, 
		 [6]={name="#{DHGS_240521_39}",misionid=3039,sceneId=978,x=109,z=184,npcname="紫霞"},
		 [7]={name="#{DHGS_240521_40}",misionid=3040,sceneId=978,x=109,z=186,npcname="至尊宝"},
		},
 },
}

function DaHua_MainStory_PreLoad()
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("UPDATE_MAP",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end

function DaHua_MainStory_OnLoad()
	-- 保存界面的默认相对位置
	g_DaHua_MainStory_UnifiedXPosition	= DaHua_MainStory_Frame : GetProperty("UnifiedXPosition");
	g_DaHua_MainStory_UnifiedYPosition	= DaHua_MainStory_Frame : GetProperty("UnifiedYPosition");
	
	g_DaHua_MainStory_Param1 = 0
	g_DaHua_MainStory_Param2 = 0
	g_DaHua_MainStory_Param3 = 0
end

function DaHua_MainStory_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99913201 ) then
		
		local nFuncType = Get_XParam_INT(0)
		if nFuncType == 0 then
			DaHua_MainStory_Frame_Cancel_Clicked()
		elseif nFuncType == 1 then
			g_DaHua_MainStory_Param1 = Get_XParam_INT(1)
			g_DaHua_MainStory_Param2 = Get_XParam_INT(2)
			g_DaHua_MainStory_Param3 = Get_XParam_INT(3)
			DaHua_MainStory_Update()
			this:Show()
		elseif nFuncType == 2 then
			if( this:IsVisible() ) then
				g_DaHua_MainStory_Param1 = Get_XParam_INT(1)
				g_DaHua_MainStory_Param2 = Get_XParam_INT(2)
				g_DaHua_MainStory_Param3 = Get_XParam_INT(3)			
				DaHua_MainStory_Update()
			end
		end
						
	-- 游戏窗口尺寸发生了变化	
	elseif (event == "ADJEST_UI_POS" ) then
		DaHua_MainStory_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DaHua_MainStory_On_ResetPos()
	
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
	elseif ( event == "UPDATE_MAP") then 
		if( this:IsVisible() ) then
			DaHua_MainStory_Update()
		end
		
	end
end

function DaHua_MainStory_Update()

-------------------------------------------------------------------------
--阶段1
	local temp = math.mod(g_DaHua_MainStory_Param1,10000)
	local nData_A = math.floor(temp/1000)
	local nData_B = math.floor((math.mod(temp,1000))/100)
	local nData_C = math.floor((math.mod(temp,100))/10)
	local nData_D = math.mod(temp,10)
	
	--未解锁
	if nData_A == 0 then
		DaHua_MainStory_Client1_Letter1_RewardItem_Client:Show()
		DaHua_MainStory_Client1_Letter1_MissionGuide:Hide()
		DaHua_MainStory_Client1_Letter1_Begin:Hide()
		DaHua_MainStory_Client1_Letter1BK_Lock:Show()
		DaHua_MainStory_Client1_Letter1_Finished:Hide()
		--添加奖励
		DaHua_MainStory_Client1_Letter1_RewardItem_Info1:Show()
		local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[1].nItemId, g_DaHua_MainStory_StepInfo[1].nItemNum)
		if theAction:GetID() ~= 0 then
			DaHua_MainStory_Client1_Letter1_RewardItem:SetActionItem(theAction:GetID())
		end		
		DaHua_MainStory_Client1_Letter1_RewardItem_Mask:Hide()
		DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Hide()			
	elseif nData_A == 1 then
		--已解锁：已完成全部任务
		if nData_B == 2 then
			DaHua_MainStory_Client1_Letter1_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter1_MissionGuide:Hide()
			DaHua_MainStory_Client1_Letter1_Begin:Hide()
			DaHua_MainStory_Client1_Letter1BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter1_Finished:Show()	
			--DaHua_MainStory_Client1_Letter1BK_FinishedInfo1:SetText("#{DHGS_240521_13}")
			--DaHua_MainStory_Client1_Letter1BK_FinishedInfo2:SetText("#{DHGS_240521_10}")
			--奖励部分
				DaHua_MainStory_Client1_Letter1_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter1_RewardItem_Mask:Show()
					--小红点：隐藏
					DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Hide()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter1_RewardItem_Mask:Hide()
					--小红点
					if nData_D == 1 then
						--达到领奖条件：显示
						DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Show()
					else
						--未达到领奖条件：隐藏
						DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Hide()
					end
				end
				--添加奖励
				local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[1].nItemId, g_DaHua_MainStory_StepInfo[1].nItemNum)
				if theAction:GetID() ~= 0 then
					DaHua_MainStory_Client1_Letter1_RewardItem:SetActionItem(theAction:GetID())
				end				
		--已解锁：未完成全部任务，但是已接取或完成第1个任务
		elseif nData_B == 1 then
			DaHua_MainStory_Client1_Letter1_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter1_MissionGuide:Show()		
			DaHua_MainStory_Client1_Letter1_Begin:Show()
			DaHua_MainStory_Client1_Letter1BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter1_Finished:Hide()	
			DaHua_MainStory_Client1_Letter1_BeginInfo1:Hide()
			DaHua_MainStory_Client1_Letter1_UnderWayBK:Show()
			if g_DaHua_MainStory_StepInfo[1].mission[nData_C] ~= nil then
				DaHua_MainStory_Client1_Letter1_MissionGuide_Info1:SetText(ScriptGlobal_Format("#{DHGS_240521_18}", g_DaHua_MainStory_StepInfo[1].mission[nData_C].name))
				if DataPool:Lua_IsHaveMission(g_DaHua_MainStory_StepInfo[1].mission[nData_C].misionid) > 0 then
					DaHua_MainStory_Client1_Letter1_MissionGuide_GotoBtn:Hide()
				else
					DaHua_MainStory_Client1_Letter1_MissionGuide_GotoBtn:Show()	
				end
			end
			
			--奖励部分
				DaHua_MainStory_Client1_Letter1_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter1_RewardItem_Mask:Show()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter1_RewardItem_Mask:Hide()
					--达到领奖条件
					if nData_D == 1 then
						DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Show()
					else
						DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Hide()
					end
					--添加奖励
					local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[1].nItemId, g_DaHua_MainStory_StepInfo[1].nItemNum)
					if theAction:GetID() ~= 0 then
						DaHua_MainStory_Client1_Letter1_RewardItem:SetActionItem(theAction:GetID())
					end
				end		
		--已解锁：未接取或完成任何任务
		else
			DaHua_MainStory_Client1_Letter1_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter1_MissionGuide:Show()		
			DaHua_MainStory_Client1_Letter1_Begin:Show()
			DaHua_MainStory_Client1_Letter1BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter1_Finished:Hide()	
			DaHua_MainStory_Client1_Letter1_BeginInfo1:Show()
			DaHua_MainStory_Client1_Letter1_UnderWayBK:Hide()
			if g_DaHua_MainStory_StepInfo[1].mission[nData_C] ~= nil then
				DaHua_MainStory_Client1_Letter1_MissionGuide_Info1:SetText(ScriptGlobal_Format("#{DHGS_240521_18}", g_DaHua_MainStory_StepInfo[1].mission[nData_C].name))
				if DataPool:Lua_IsHaveMission(g_DaHua_MainStory_StepInfo[1].mission[nData_C].misionid) > 0 then
					DaHua_MainStory_Client1_Letter1_MissionGuide_GotoBtn:Hide()
				else
					DaHua_MainStory_Client1_Letter1_MissionGuide_GotoBtn:Show()	
				end			
			end
			--DaHua_MainStory_Client1_Letter1_MissionGuide_GotoBtn:Show()
			--奖励部分
				DaHua_MainStory_Client1_Letter1_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter1_RewardItem_Mask:Show()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter1_RewardItem_Mask:Hide()
					--达到领奖条件
					if nData_D == 1 then
						DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Show()
					else
						DaHua_MainStory_Client1_Letter1_RewardItem_Tips:Hide()
					end
					--添加奖励
					local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[1].nItemId, g_DaHua_MainStory_StepInfo[1].nItemNum)
					if theAction:GetID() ~= 0 then
						DaHua_MainStory_Client1_Letter1_RewardItem:SetActionItem(theAction:GetID())
					end
				end
		end
	end
-------------------------------------------------------------------------	
--阶段2
	temp = math.mod(g_DaHua_MainStory_Param2,10000)
	nData_A = math.floor(temp/1000)
	nData_B = math.floor((math.mod(temp,1000))/100)
	nData_C = math.floor((math.mod(temp,100))/10)
	nData_D = math.mod(temp,10)

	--未解锁
	if nData_A == 0 then
		DaHua_MainStory_Client1_Letter2_RewardItem_Client:Show()
		DaHua_MainStory_Client1_Letter2_MissionGuide:Hide()
		DaHua_MainStory_Client1_Letter2_Begin:Hide()
		DaHua_MainStory_Client1_Letter2BK_Lock:Show()
		DaHua_MainStory_Client1_Letter2_Finished:Hide()
		--添加奖励
		DaHua_MainStory_Client1_Letter2_RewardItem_Info1:Show()
		local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[2].nItemId, g_DaHua_MainStory_StepInfo[2].nItemNum)
		if theAction:GetID() ~= 0 then
			DaHua_MainStory_Client1_Letter2_RewardItem:SetActionItem(theAction:GetID())
		end		
		DaHua_MainStory_Client1_Letter2_RewardItem_Mask:Hide()
		DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Hide()			
	elseif nData_A == 1 then
		--已解锁：已完成全部任务
		if nData_B == 2 then
			DaHua_MainStory_Client1_Letter2_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter2_MissionGuide:Hide()
			DaHua_MainStory_Client1_Letter2_Begin:Hide()
			DaHua_MainStory_Client1_Letter2BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter2_Finished:Show()	
			--DaHua_MainStory_Client1_Letter2BK_FinishedInfo1:SetText("#{DHGS_240521_14}")
			--DaHua_MainStory_Client1_Letter2BK_FinishedInfo2:SetText("#{DHGS_240521_11}")
			--奖励部分
				DaHua_MainStory_Client1_Letter2_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter2_RewardItem_Mask:Show()
					--小红点：隐藏
					DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Hide()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter2_RewardItem_Mask:Hide()
					--小红点
					if nData_D == 1 then
						--达到领奖条件：显示
						DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Show()
					else
						--未达到领奖条件：隐藏
						DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Hide()
					end
				end
				--添加奖励
				local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[2].nItemId, g_DaHua_MainStory_StepInfo[2].nItemNum)
				if theAction:GetID() ~= 0 then
					DaHua_MainStory_Client1_Letter2_RewardItem:SetActionItem(theAction:GetID())
				end				
		--已解锁：未完成全部任务，但是已接取或完成第1个任务
		elseif nData_B == 1 then
			DaHua_MainStory_Client1_Letter2_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter2_MissionGuide:Show()		
			DaHua_MainStory_Client1_Letter2_Begin:Show()
			DaHua_MainStory_Client1_Letter2BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter2_Finished:Hide()	
			DaHua_MainStory_Client1_Letter2_BeginInfo1:Hide()
			DaHua_MainStory_Client1_Letter2_UnderWayBK:Show()
			if g_DaHua_MainStory_StepInfo[2].mission[nData_C] ~= nil then
				DaHua_MainStory_Client1_Letter2_MissionGuide_Info1:SetText(ScriptGlobal_Format("#{DHGS_240521_18}", g_DaHua_MainStory_StepInfo[2].mission[nData_C].name))
				if DataPool:Lua_IsHaveMission(g_DaHua_MainStory_StepInfo[2].mission[nData_C].misionid) > 0 then
					DaHua_MainStory_Client1_Letter2_MissionGuide_GotoBtn:Hide()
				else
					DaHua_MainStory_Client1_Letter2_MissionGuide_GotoBtn:Show()	
				end				
			end
			--奖励部分
				DaHua_MainStory_Client1_Letter2_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter2_RewardItem_Mask:Show()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter2_RewardItem_Mask:Hide()
					--达到领奖条件
					if nData_D == 1 then
						DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Show()
					else
						DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Hide()
					end
					--添加奖励
					local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[2].nItemId, g_DaHua_MainStory_StepInfo[2].nItemNum)
					if theAction:GetID() ~= 0 then
						DaHua_MainStory_Client1_Letter2_RewardItem:SetActionItem(theAction:GetID())
					end
				end		
		--已解锁：未接取或完成任何任务
		else
			DaHua_MainStory_Client1_Letter2_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter2_MissionGuide:Show()		
			DaHua_MainStory_Client1_Letter2_Begin:Show()
			DaHua_MainStory_Client1_Letter2BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter2_Finished:Hide()	
			DaHua_MainStory_Client1_Letter2_BeginInfo1:Show()
			DaHua_MainStory_Client1_Letter2_UnderWayBK:Hide()
			if g_DaHua_MainStory_StepInfo[2].mission[nData_C] ~= nil then
				DaHua_MainStory_Client1_Letter2_MissionGuide_Info1:SetText(ScriptGlobal_Format("#{DHGS_240521_18}", g_DaHua_MainStory_StepInfo[2].mission[nData_C].name))
				if DataPool:Lua_IsHaveMission(g_DaHua_MainStory_StepInfo[2].mission[nData_C].misionid) > 0 then
					DaHua_MainStory_Client1_Letter2_MissionGuide_GotoBtn:Hide()
				else
					DaHua_MainStory_Client1_Letter2_MissionGuide_GotoBtn:Show()	
				end				
			end
			--奖励部分
				DaHua_MainStory_Client1_Letter2_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter2_RewardItem_Mask:Show()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter2_RewardItem_Mask:Hide()
					--达到领奖条件
					if nData_D == 1 then
						DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Show()
					else
						DaHua_MainStory_Client1_Letter2_RewardItem_Tips:Hide()
					end
					--添加奖励
					local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[2].nItemId, g_DaHua_MainStory_StepInfo[2].nItemNum)
					if theAction:GetID() ~= 0 then
						DaHua_MainStory_Client1_Letter2_RewardItem:SetActionItem(theAction:GetID())
					end
				end
		end
	end	
-------------------------------------------------------------------------
	
--阶段3
	temp = math.mod(g_DaHua_MainStory_Param3,10000)
	nData_A = math.floor(temp/1000)
	nData_B = math.floor((math.mod(temp,1000))/100)
	nData_C = math.floor((math.mod(temp,100))/10)
	nData_D = math.mod(temp,10)

	--未解锁
	if nData_A == 0 then
		DaHua_MainStory_Client1_Letter3_RewardItem_Client:Show()
		DaHua_MainStory_Client1_Letter3_MissionGuide:Hide()
		DaHua_MainStory_Client1_Letter3_Begin:Hide()
		DaHua_MainStory_Client1_Letter3BK_Lock:Show()
		DaHua_MainStory_Client1_Letter3_Finished:Hide()
		--添加奖励
		DaHua_MainStory_Client1_Letter3_RewardItem_Info1:Show()
		local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[3].nItemId, g_DaHua_MainStory_StepInfo[3].nItemNum)
		if theAction:GetID() ~= 0 then
			DaHua_MainStory_Client1_Letter3_RewardItem:SetActionItem(theAction:GetID())
		end		
		DaHua_MainStory_Client1_Letter3_RewardItem_Mask:Hide()
		DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Hide()		
	elseif nData_A == 1 then
		--已解锁：已完成全部任务
		if nData_B == 2 then
			DaHua_MainStory_Client1_Letter3_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter3_MissionGuide:Hide()
			DaHua_MainStory_Client1_Letter3_Begin:Hide()
			DaHua_MainStory_Client1_Letter3BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter3_Finished:Show()	
			--DaHua_MainStory_Client1_Letter3BK_FinishedInfo1:SetText("#{DHGS_240521_15}")
			--DaHua_MainStory_Client1_Letter3BK_FinishedInfo2:SetText("#{DHGS_240521_12}")
			--奖励部分
				DaHua_MainStory_Client1_Letter3_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter3_RewardItem_Mask:Show()
					--小红点：隐藏
					DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Hide()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter3_RewardItem_Mask:Hide()
					--小红点
					if nData_D == 1 then
						--达到领奖条件：显示
						DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Show()
					else
						--未达到领奖条件：隐藏
						DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Hide()
					end
				end
				--添加奖励
				local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[3].nItemId, g_DaHua_MainStory_StepInfo[3].nItemNum)
				if theAction:GetID() ~= 0 then
					DaHua_MainStory_Client1_Letter3_RewardItem:SetActionItem(theAction:GetID())
				end				
		--已解锁：未完成全部任务，但是已接取或完成第1个任务
		elseif nData_B == 1 then
			DaHua_MainStory_Client1_Letter3_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter3_MissionGuide:Show()		
			DaHua_MainStory_Client1_Letter3_Begin:Show()
			DaHua_MainStory_Client1_Letter3BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter3_Finished:Hide()	
			DaHua_MainStory_Client1_Letter3_BeginInfo1:Hide()
			DaHua_MainStory_Client1_Letter3_UnderWayBK:Show()
			if g_DaHua_MainStory_StepInfo[3].mission[nData_C] ~= nil then
				DaHua_MainStory_Client1_Letter3_MissionGuide_Info1:SetText(ScriptGlobal_Format("#{DHGS_240521_18}", g_DaHua_MainStory_StepInfo[3].mission[nData_C].name))
				if DataPool:Lua_IsHaveMission(g_DaHua_MainStory_StepInfo[3].mission[nData_C].misionid) > 0 then
					DaHua_MainStory_Client1_Letter3_MissionGuide_GotoBtn:Hide()
				else
					DaHua_MainStory_Client1_Letter3_MissionGuide_GotoBtn:Show()	
				end				
			end
			--奖励部分
				DaHua_MainStory_Client1_Letter3_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter3_RewardItem_Mask:Show()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter3_RewardItem_Mask:Hide()
					--达到领奖条件
					if nData_D == 1 then
						DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Show()
					else
						DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Hide()
					end
					--添加奖励
					local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[3].nItemId, g_DaHua_MainStory_StepInfo[3].nItemNum)
					if theAction:GetID() ~= 0 then
						DaHua_MainStory_Client1_Letter3_RewardItem:SetActionItem(theAction:GetID())
					end
				end		
		--已解锁：未接取或完成任何任务
		else
			DaHua_MainStory_Client1_Letter3_RewardItem_Client:Show()
			DaHua_MainStory_Client1_Letter3_MissionGuide:Show()		
			DaHua_MainStory_Client1_Letter3_Begin:Show()
			DaHua_MainStory_Client1_Letter3BK_Lock:Hide()
			DaHua_MainStory_Client1_Letter3_Finished:Hide()	
			DaHua_MainStory_Client1_Letter3_BeginInfo1:Show()
			DaHua_MainStory_Client1_Letter3_UnderWayBK:Hide()
			if g_DaHua_MainStory_StepInfo[3].mission[nData_C] ~= nil then
				DaHua_MainStory_Client1_Letter3_MissionGuide_Info1:SetText(ScriptGlobal_Format("#{DHGS_240521_18}", g_DaHua_MainStory_StepInfo[3].mission[nData_C].name))
				if DataPool:Lua_IsHaveMission(g_DaHua_MainStory_StepInfo[3].mission[nData_C].misionid) > 0 then
					DaHua_MainStory_Client1_Letter3_MissionGuide_GotoBtn:Hide()
				else
					DaHua_MainStory_Client1_Letter3_MissionGuide_GotoBtn:Show()	
				end				
			end
			--奖励部分
				DaHua_MainStory_Client1_Letter3_RewardItem_Info1:Show()
				--已领奖
				if nData_D == 2 then
					--已领奖：对勾，显示
					DaHua_MainStory_Client1_Letter3_RewardItem_Mask:Show()
				--未领奖
				else
					--已领奖：对勾，隐藏
					DaHua_MainStory_Client1_Letter3_RewardItem_Mask:Hide()
					--达到领奖条件
					if nData_D == 1 then
						DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Show()
					else
						DaHua_MainStory_Client1_Letter3_RewardItem_Tips:Hide()
					end
					--添加奖励
					local theAction = DataPool:CreateActionItemForShow(g_DaHua_MainStory_StepInfo[3].nItemId, g_DaHua_MainStory_StepInfo[3].nItemNum)
					if theAction:GetID() ~= 0 then
						DaHua_MainStory_Client1_Letter3_RewardItem:SetActionItem(theAction:GetID())
					end
				end
		end
	end	
	
end
	
function DaHua_MainStory_MissionGuide_GotoBtn(nIndex)

	if nIndex == 1 then
		--阶段1
		local temp = math.mod(g_DaHua_MainStory_Param1,10000)
		local nData_A = math.floor(temp/1000)
		local nData_B = math.floor((math.mod(temp,1000))/100)
		local nData_C = math.floor((math.mod(temp,100))/10)
		local nData_D = math.mod(temp,10)	
		
		--寻路
		if g_DaHua_MainStory_StepInfo[1].mission[nData_C] ~= nil then
			local resId = g_DaHua_MainStory_StepInfo[1].mission[nData_C].sceneId
			local posx = g_DaHua_MainStory_StepInfo[1].mission[nData_C].x
			local posz = g_DaHua_MainStory_StepInfo[1].mission[nData_C].z
			local name = g_DaHua_MainStory_StepInfo[1].mission[nData_C].npcname
			AutoRuntoTargetExWithName(posx, posz, resId, name)
		end
		
	elseif nIndex == 2 then
		--阶段2
		local temp = math.mod(g_DaHua_MainStory_Param2,10000)
		local nData_A = math.floor(temp/1000)
		local nData_B = math.floor((math.mod(temp,1000))/100)
		local nData_C = math.floor((math.mod(temp,100))/10)
		local nData_D = math.mod(temp,10)

		--寻路
		if g_DaHua_MainStory_StepInfo[2].mission[nData_C] ~= nil then
			local resId = g_DaHua_MainStory_StepInfo[2].mission[nData_C].sceneId
			local posx = g_DaHua_MainStory_StepInfo[2].mission[nData_C].x
			local posz = g_DaHua_MainStory_StepInfo[2].mission[nData_C].z
			local name = g_DaHua_MainStory_StepInfo[2].mission[nData_C].npcname
			AutoRuntoTargetExWithName(posx, posz, resId, name)
		end
		
	elseif nIndex == 3 then
		--阶段3
		local temp = math.mod(g_DaHua_MainStory_Param3,10000)
		local nData_A = math.floor(temp/1000)
		local nData_B = math.floor((math.mod(temp,1000))/100)
		local nData_C = math.floor((math.mod(temp,100))/10)
		local nData_D = math.mod(temp,10)

		--寻路
		if g_DaHua_MainStory_StepInfo[3].mission[nData_C] ~= nil then
			local resId = g_DaHua_MainStory_StepInfo[3].mission[nData_C].sceneId
			local posx = g_DaHua_MainStory_StepInfo[3].mission[nData_C].x
			local posz = g_DaHua_MainStory_StepInfo[3].mission[nData_C].z
			local name = g_DaHua_MainStory_StepInfo[3].mission[nData_C].npcname
			AutoRuntoTargetExWithName(posx, posz, resId, name)
		end
		
	end

end

function DaHua_MainStory_LockClicked(nIndex)

	if nIndex == 1 then
		local temp = math.mod(g_DaHua_MainStory_Param1,10000)
		local nData_A = math.floor(temp/1000)	
		if nData_A == 0 then
			temp = math.floor( math.mod(g_DaHua_MainStory_Param1,100000 ) / 10000)
			if temp == 1 then
				PushDebugMessage("#{DHGS_240521_21}")
			elseif temp == 2 then
				PushDebugMessage("#{DHGS_240521_06}")
			end
		end
	elseif nIndex == 2 then
		local temp = math.mod(g_DaHua_MainStory_Param2,10000)
		local nData_A = math.floor(temp/1000)	
		if nData_A == 0 then
			temp = math.floor( math.mod(g_DaHua_MainStory_Param2,100000 ) / 10000)
			if temp == 1 then
				PushDebugMessage("#{DHGS_240521_05}")
			elseif temp == 2 then
				PushDebugMessage("#{DHGS_240521_06}")
			elseif temp == 3 then
				PushDebugMessage("#{DHGS_240521_07}")
			end
		end	
	elseif nIndex == 3 then
		local temp = math.mod(g_DaHua_MainStory_Param3,10000)
		local nData_A = math.floor(temp/1000)	
		if nData_A == 0 then
			temp = math.floor( math.mod(g_DaHua_MainStory_Param3,100000 ) / 10000)
			if temp == 1 then
				PushDebugMessage("#{DHGS_240521_09}")
			elseif temp == 2 then
				PushDebugMessage("#{DHGS_240521_06}")
			elseif temp == 3 then
				PushDebugMessage("#{DHGS_240521_08}")
			end
		end		
	end
	
end

function DaHua_MainStory_GetPrize_Clicked(nIndex)

	if nIndex~=1 and nIndex~=2 and nIndex~=3 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 999132 )
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

--================================================
-- 关闭界面
--================================================
function DaHua_MainStory_Frame_Cancel_Clicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaHua_MainStory_On_ResetPos()

	DaHua_MainStory_Frame : SetProperty("UnifiedXPosition", g_DaHua_MainStory_UnifiedXPosition);
	DaHua_MainStory_Frame : SetProperty("UnifiedYPosition", g_DaHua_MainStory_UnifiedYPosition);

end

