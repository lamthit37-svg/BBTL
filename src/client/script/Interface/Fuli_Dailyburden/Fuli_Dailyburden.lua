-- 界面的默认相对位置
local Fuli_Dailyburden_UnifiedXPosition;
local Fuli_Dailyburden_UnifiedYPosition;

local Fuli_Dailyburden_week = -1
local Fuli_Dailyburden_curFubenId = -1
local Fuli_Dailyburden_curDay_Count = -1

--格子及其编号
local Fuli_Dailyburden_ITEM_NUM = 12;
local Fuli_Dailyburden_ITEMS = {};

local Fuli_Dailyburden_Info;
local Fuli_Dailyburden_Info_text1;
local Fuli_Dailyburden_Info_text2;
local Fuli_Dailyburden_Double_Info;
local Fuli_Dailyburden_Double_Check;
local Fuli_Dailyburden_Abandon;
local Fuli_Dailyburden_BossIcon = {}
local Fuli_Dailyburden_BossButton = {}
local Fuli_Dailyburden_BossingAnimate = {}
local Fuli_Dailyburden_BossDieIcon = {}
local Fuli_Dailyburden_BossName = {}
local Fuli_Dailyburden_Timer = {}
local Fuli_Dailyburden_CheckButton1;
local Fuli_Dailyburden_CheckButton2;
local Fuli_Dailyburden_CheckButton3;
local Fuli_Dailyburden_CheckButton5;
local Fuli_Dailyburden_CheckButton6;
local Fuli_Dailyburden_tips1;
local Fuli_Dailyburden_tips2;
local Fuli_Dailyburden_tips3;
local Fuli_Dailyburden_tips5;
local Fuli_Dailyburden_tips6;

local Fuli_Dailyburden_MaxBoss = 6
local Fuli_Dailyburden_GiveUpCheckButton = 1
local Fuli_Dailyburden_CheckButton = 0
local Fuli_Dailyburden_curPassIndex = 0

--周一到周五对应的副本ID
Fuli_Dailyburden_FubenId = { [1] = 1, [2] = 3, [3] = 8, [4] = 0, [5] = 1}

Fuli_Dailyburden_FubenCount = {3,2,3,3,3}
local CreateDate = 904691712			-- 2013年08月22日08:00:00

local nCharCreateDate = 0;
local g_bIsNewServerGiftsForLevelUpValid = 0

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},									
										}

function Fuli_Dailyburden_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REFRESH_DAILYSECKILL_PAGE")
	this:RegisterEvent("REFRESH_SECKILL_ITEM")
	this:RegisterEvent("SEND_DAILYSECKILL")
end

function Fuli_Dailyburden_OnLoad()
	Fuli_Dailyburden_UnifiedXPosition	= Fuli_Dailyburden_Frame : GetProperty("UnifiedXPosition");
	Fuli_Dailyburden_UnifiedYPosition	= Fuli_Dailyburden_Frame : GetProperty("UnifiedYPosition");
	
	
	Fuli_Dailyburden_ITEMS[1] = Fuli_Dailyburden_Item1
	Fuli_Dailyburden_ITEMS[2] = Fuli_Dailyburden_Item2
	Fuli_Dailyburden_ITEMS[3] = Fuli_Dailyburden_Item3
	Fuli_Dailyburden_ITEMS[4] = Fuli_Dailyburden_Item4
	Fuli_Dailyburden_ITEMS[5] = Fuli_Dailyburden_Item5
	Fuli_Dailyburden_ITEMS[6] = Fuli_Dailyburden_Item6
	Fuli_Dailyburden_ITEMS[7] = Fuli_Dailyburden_Item7
	Fuli_Dailyburden_ITEMS[8] = Fuli_Dailyburden_Item8
	Fuli_Dailyburden_ITEMS[9] = Fuli_Dailyburden_Item9
	Fuli_Dailyburden_ITEMS[10] = Fuli_Dailyburden_Item10
	Fuli_Dailyburden_ITEMS[11] = Fuli_Dailyburden_Item11
	Fuli_Dailyburden_ITEMS[12] = Fuli_Dailyburden_Item12
	
	Fuli_Dailyburden_BossIcon[1] = Fuli_Dailyburden_Boss1
	Fuli_Dailyburden_BossIcon[2] = Fuli_Dailyburden_Boss2
	Fuli_Dailyburden_BossIcon[3] = Fuli_Dailyburden_Boss3
	Fuli_Dailyburden_BossIcon[4] = Fuli_Dailyburden_Boss4
	Fuli_Dailyburden_BossIcon[5] = Fuli_Dailyburden_Boss5
	Fuli_Dailyburden_BossIcon[6] = Fuli_Dailyburden_Boss6
	
	Fuli_Dailyburden_BossButton[1] = Fuli_Dailyburden_Boss1AnimateImage
	Fuli_Dailyburden_BossButton[2] = Fuli_Dailyburden_Boss2AnimateImage
	Fuli_Dailyburden_BossButton[3] = Fuli_Dailyburden_Boss3AnimateImage
	Fuli_Dailyburden_BossButton[4] = Fuli_Dailyburden_Boss4AnimateImage
	Fuli_Dailyburden_BossButton[5] = Fuli_Dailyburden_Boss5AnimateImage
	Fuli_Dailyburden_BossButton[6] = Fuli_Dailyburden_Boss6AnimateImage
	
	Fuli_Dailyburden_BossingAnimate[1] = Fuli_Dailyburden_Boss1doing
	Fuli_Dailyburden_BossingAnimate[2] = Fuli_Dailyburden_Boss2doing
	Fuli_Dailyburden_BossingAnimate[3] = Fuli_Dailyburden_Boss3doing
	Fuli_Dailyburden_BossingAnimate[4] = Fuli_Dailyburden_Boss4doing
	Fuli_Dailyburden_BossingAnimate[5] = Fuli_Dailyburden_Boss5doing
	Fuli_Dailyburden_BossingAnimate[6] = Fuli_Dailyburden_Boss6doing
	
	Fuli_Dailyburden_BossDieIcon[1] = Fuli_Dailyburden_Boss1finish
	Fuli_Dailyburden_BossDieIcon[2] = Fuli_Dailyburden_Boss2finish
	Fuli_Dailyburden_BossDieIcon[3] = Fuli_Dailyburden_Boss3finish
	Fuli_Dailyburden_BossDieIcon[4] = Fuli_Dailyburden_Boss4finish
	Fuli_Dailyburden_BossDieIcon[5] = Fuli_Dailyburden_Boss5finish
	Fuli_Dailyburden_BossDieIcon[6] = Fuli_Dailyburden_Boss6finish
	
	Fuli_Dailyburden_BossName[1] = Fuli_Dailyburden_Boss1Name
	Fuli_Dailyburden_BossName[2] = Fuli_Dailyburden_Boss2Name
	Fuli_Dailyburden_BossName[3] = Fuli_Dailyburden_Boss3Name
	Fuli_Dailyburden_BossName[4] = Fuli_Dailyburden_Boss4Name
	Fuli_Dailyburden_BossName[5] = Fuli_Dailyburden_Boss5Name
	Fuli_Dailyburden_BossName[6] = Fuli_Dailyburden_Boss6Name
	
	Fuli_Dailyburden_Timer[1] = Fuli_Dailyburden_Boss1_StopWatch
	Fuli_Dailyburden_Timer[2] = Fuli_Dailyburden_Boss2_StopWatch
	Fuli_Dailyburden_Timer[3] = Fuli_Dailyburden_Boss3_StopWatch
	Fuli_Dailyburden_Timer[4] = Fuli_Dailyburden_Boss4_StopWatch
	Fuli_Dailyburden_Timer[5] = Fuli_Dailyburden_Boss5_StopWatch
	Fuli_Dailyburden_Timer[6] = Fuli_Dailyburden_Boss6_StopWatch
	
	Fuli_Dailyburden_Info = Fuli_Dailyburden_Explain1
	Fuli_Dailyburden_Info_text1 = Fuli_Dailyburden_Explain1_1
	Fuli_Dailyburden_Info_text2 = Fuli_Dailyburden_Explain_times
	Fuli_Dailyburden_Double_Info = Fuli_Dailyburden_Double
	Fuli_Dailyburden_Double_Check = Fuli_Dailyburden_DoubleCheck
	Fuli_Dailyburden_Abandon = Fuli_Dailyburden_AbandonCheckButton
	
	Fuli_Dailyburden_CheckButton1 = Fuli_Dailyburden_Button1
	Fuli_Dailyburden_CheckButton2 = Fuli_Dailyburden_Button2
	Fuli_Dailyburden_CheckButton3 = Fuli_Dailyburden_Button3
	Fuli_Dailyburden_CheckButton5 = Fuli_Dailyburden_Button5
	Fuli_Dailyburden_CheckButton6 = Fuli_Dailyburden_Button6
	
	Fuli_Dailyburden_tips1 = Fuli_Dailyburden_Button1tips
	Fuli_Dailyburden_tips2 = Fuli_Dailyburden_Button2tips
	Fuli_Dailyburden_tips3 = Fuli_Dailyburden_Button3tips
	Fuli_Dailyburden_tips5 = Fuli_Dailyburden_Button5tips
	Fuli_Dailyburden_tips6 = Fuli_Dailyburden_Button6tips
	
	g_ButtonPos[1].x	= Fuli_Dailyburden_CheckButton3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_Dailyburden_CheckButton3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_Dailyburden_tips3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_Dailyburden_tips3:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[2].x	= Fuli_Dailyburden_CheckButton6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_Dailyburden_CheckButton6:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_Dailyburden_tips6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_Dailyburden_tips6:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[3].x	= Fuli_Dailyburden_CheckButton5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_Dailyburden_CheckButton5:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_Dailyburden_tips5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_Dailyburden_tips5:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[4].x	= Fuli_Dailyburden_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_Dailyburden_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_Dailyburden_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_Dailyburden_Button7tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[5].x	= Fuli_Dailyburden_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_Dailyburden_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_Dailyburden_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_Dailyburden_Button8tips:GetProperty("UnifiedYPosition");
end

-- OnEvent
function Fuli_Dailyburden_OnEvent(event)
	Fuli_Dailyburden_tips5:Hide()
	if (event == "UI_COMMAND" ) then
		if tonumber(arg0) == 892428 then
			Fuli_Dailyburden_week = Get_XParam_INT(0)
			Fuli_Dailyburden_curDay_Count = Get_XParam_INT(1)
			
			if Get_XParam_INT(2) ~= 0 then
				return
			end
			
			OpenWindow("Packet")
	
			local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
			if( SelfFuliUnionIPos ~= nil) then
				Fuli_Dailyburden_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
			end
	
			this:Show()
			Fuli_Dailyburden_Frame_UpdateCheckButton()
			Fuli_Dailyburden_Update(0)
			
		elseif tonumber(arg0) == 20170301 then
			if this:IsVisible() then
				Fuli_Dailyburden_Update(0)
			end
			
		elseif tonumber(arg0) == 20170302 then
			--local isShow = Get_XParam_INT(0)
			--DataPool:Lua_SetDailySeckillFlag( Get_XParam_INT( 0 ))
			
			--if isShow == 1 then
				--Fuli_Dailyburden_tips5:Show()
			--else
				--Fuli_Dailyburden_tips5:Hide()
			--end
			
		elseif tonumber(arg0) == 8889072 then
			nCharCreateDate = Get_XParam_INT( 8 );
			g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
		elseif tonumber(arg0) == 89242837 then
			Fuli_Dailyburden_curDay_Count = Get_XParam_INT(0)
			local remainCount = Fuli_Dailyburden_FubenCount[Fuli_Dailyburden_week] - Fuli_Dailyburden_curDay_Count
			local strTemp = ScriptGlobal_Format("#{JFRW_170217_7}",remainCount,Fuli_Dailyburden_FubenCount[Fuli_Dailyburden_week])
			if remainCount == 0 then
					strTemp = ScriptGlobal_Format("#{JFRW_170217_7}","#cff0000"..remainCount,Fuli_Dailyburden_FubenCount[Fuli_Dailyburden_week])
			end
			Fuli_Dailyburden_Info_text2:SetText(strTemp)
		end
		
	elseif (event == "REFRESH_DAILYSECKILL_PAGE") then
		if this:IsVisible() then
			Fuli_Dailyburden_Update(1)
		end
		
	elseif (event == "REFRESH_SECKILL_ITEM") then
		if this:IsVisible() then
			Fuli_Dailyburden_Item_Update()
		end
	
	elseif (event == "SEND_DAILYSECKILL") then
		if this:IsVisible() then
			Fuli_Dailyburden_SendSecKill(tonumber(arg1))
		end

	
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Fuli_Dailyburden_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Fuli_Dailyburden_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Fuli_Dailyburden_OnClosed()
	end
	
	if Fuli_Dailyburden_curFubenId ~= -1 then 
		local BossIcon = {}
		local BossName = {}
		local BossMaxNum = 0
		local FubenName
		local CanDoubleExp
		FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = GetSecKillBossIconByIndex(Fuli_Dailyburden_curFubenId)
		
		local strExplainTxt = ""
		if Player:GetData("Is2606S") == 1 then
			strExplainTxt = ScriptGlobal_Format("#{QXFSG_260622_18}",FubenName)
		else
			strExplainTxt = ScriptGlobal_Format("#{JFRW_170217_5}",FubenName)
		end
		Fuli_Dailyburden_Explain:SetText(strExplainTxt)
	end

end

function Fuli_Dailyburden_Frame_UpdateCheckButton()
	--更新选中位置
	Fuli_Dailyburden_CheckButton1:SetCheck(0)
	Fuli_Dailyburden_CheckButton2:SetCheck(0)
	Fuli_Dailyburden_CheckButton3:SetCheck(0)
	Fuli_Dailyburden_CheckButton5:SetCheck(1)
	Fuli_Dailyburden_CheckButton6:SetCheck(0)
	
	local nSalaryTask = 2
	local nShaoDang = 3
	local nOneDay = 4
	
	--更新按钮位置
	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 ) then
		Fuli_Dailyburden_CheckButton3 : Hide();
		nSalaryTask = nSalaryTask - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		
	else
		Fuli_Dailyburden_CheckButton3 : Show();
		
		
	end
		
	local nLevel = Player:GetLevel();
	if ( nLevel < 35 or DataPool:GetServerDayTime() > 20211016) then
		Fuli_Dailyburden_CheckButton6:Hide()
		nSalaryTask = - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
	else
		Fuli_Dailyburden_CheckButton6:Show()
	end	
	
	if nSalaryTask ~= -1 then
		Fuli_Dailyburden_CheckButton6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].x);
		Fuli_Dailyburden_CheckButton6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].y);
		Fuli_Dailyburden_tips6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].tipx);
		Fuli_Dailyburden_tips6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].tipy);
	end
	
	Fuli_Dailyburden_CheckButton5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
	Fuli_Dailyburden_CheckButton5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
	Fuli_Dailyburden_tips5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
	Fuli_Dailyburden_tips5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);
	
	if nOneDay ~= -1 then
		Fuli_Dailyburden_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		Fuli_Dailyburden_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		Fuli_Dailyburden_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		Fuli_Dailyburden_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
		
		Fuli_Dailyburden_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].x);
		Fuli_Dailyburden_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].y);
		Fuli_Dailyburden_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].tipx);
		Fuli_Dailyburden_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].tipy);
	end
	
	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_Dailyburden_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_Dailyburden_Button7tips : Hide()
	end
	
	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_Dailyburden_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_Dailyburden_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_Dailyburden_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_Dailyburden_Button8 : Hide()
	end

	--刷新红点
	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_Dailyburden_tips1 : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_Dailyburden_tips1 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_Dailyburden_tips2 : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_Dailyburden_tips2 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 )then
			Fuli_Dailyburden_tips3 : Hide() 
			DataPool:Lua_SetRedPointInUIShow(39, 0)
		else
			Fuli_Dailyburden_tips3 : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_Dailyburden_tips3 : Hide()
	end

	
	--if DataPool:Lua_GetDailySeckillFlag() == 1 then
		--Fuli_Dailyburden_tips5 : Show()
	--else
		--Fuli_Dailyburden_tips5 : Hide()
	--end
	Fuli_Dailyburden_tips6 : Hide()
end

function Fuli_Dailyburden_Frame_On_ResetPos()
	Fuli_Dailyburden_Frame : SetProperty("UnifiedXPosition", Fuli_Dailyburden_UnifiedXPosition);
	Fuli_Dailyburden_Frame : SetProperty("UnifiedYPosition", Fuli_Dailyburden_UnifiedYPosition);
end

function Fuli_Dailyburden_OnClosed()
	this:Hide();
	
	for i=1, Fuli_Dailyburden_MaxBoss do
		Fuli_Dailyburden_Timer[i]:SetProperty("Timer", "-1");
	end
end

function Fuli_Dailyburden_Item_Update()
	--显示物品栏的物品
	for i=1, Fuli_Dailyburden_ITEM_NUM do
		Fuli_Dailyburden_ITEMS[i]:SetActionItem(-1);
		Fuli_Dailyburden_ITEMS[i]:Enable();
	end
	
	--从数据池中使用数据填入背包内的物品
	local nActIndex = 0
	
	for i=1, Fuli_Dailyburden_ITEM_NUM  do
		local theAction = SecKillEnumItem(nActIndex);
		nActIndex = nActIndex+1;

		if theAction:GetID() ~= 0 then
			Fuli_Dailyburden_ITEMS[i]:SetActionItem(theAction:GetID());
		else
			Fuli_Dailyburden_ITEMS[i]:SetActionItem(-1);
		end
	end
end

function Fuli_Dailyburden_Weekend(isIn)
	if isIn == 1 then
		Fuli_Dailyburden_Info:Hide()
		Fuli_Dailyburden_Double_Info:Hide()
		for i=1, Fuli_Dailyburden_MaxBoss do
			Fuli_Dailyburden_BossIcon[i]:Hide()
			Fuli_Dailyburden_BossName[i]:Hide()
		end
		
	else
		Fuli_Dailyburden_Info:Show()
		Fuli_Dailyburden_Double_Info:Show()
		for i=1, Fuli_Dailyburden_MaxBoss do
			Fuli_Dailyburden_BossIcon[i]:Show()
			Fuli_Dailyburden_BossName[i]:Show()
		end
	end
end

function Fuli_Dailyburden_state()
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()
	if isInSecKill == 2 then
		return 1     --处于减负扫荡中
		
	elseif Fuli_Dailyburden_week < 1 or Fuli_Dailyburden_week > 5 then
		return 2     --处于双休日
		
	elseif 	Fuli_Dailyburden_curDay_Count >= Fuli_Dailyburden_FubenCount[Fuli_Dailyburden_week] then
		return 3     --今天已经扫荡过了
		
	else
		return 4		 --当天还未扫荡
	end
end

function Fuli_Dailyburden_Update(isRefresh)
	Fuli_Dailyburden_Again:Disable()
	Fuli_Dailyburden_Againtips:Show()

	Fuli_Dailyburden_Item_Update()
	
	if Fuli_Dailyburden_week == -1 or Fuli_Dailyburden_curDay_Count == -1 then
		return
	end
	
	local state = Fuli_Dailyburden_state()
	--只有每次新打开界面，才判断
	if state == 2 and isRefresh == 0 then
		Fuli_Dailyburden_Weekend(1)
		return
	else
		Fuli_Dailyburden_Weekend(0)
	end
	
	--显示Boss图标
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()
	
	local BossIcon = {}
	local BossName = {}
	local BossMaxNum = 0
	
	if isInSecKill == 2 and DoubleExp == 1 then
		Fuli_Dailyburden_CheckButton = 1
	end
	
	--最后一个boss扫荡完，fubenID记录上次的
	if isInSecKill ~= 0 or isRefresh ~= 1 then
		Fuli_Dailyburden_curFubenId = Fuli_Dailyburden_FubenId[Fuli_Dailyburden_week]
		if state == 1 then
			Fuli_Dailyburden_curFubenId = FubenID
		end

	end
	
	
	if state == 4 then
		isInSecKill = 0
		DoubleExp = 0
		BossIndex = 0
	end
	
	if Fuli_Dailyburden_curFubenId ~= -1 then 
		FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = GetSecKillBossIconByIndex(Fuli_Dailyburden_curFubenId)
	end
		--local strTemp = ScriptGlobal_Format("#{JFRW_170217_6}",FubenName)
		--Fuli_Dailyburden_Info_text1:SetText(strTemp)
	--end
	
	if isRefresh == 1 and 0==BossIndex then
		Fuli_Dailyburden_Again:Enable()
		Fuli_Dailyburden_Againtips:Hide()
	end

	--为了兼容周六日打开界面的情况，周六日打开时按周五数值计算
	local weekCountD = Fuli_Dailyburden_week
	if weekCountD > 5 or weekCountD < 1 then
		weekCountD = 5
	end
	if Fuli_Dailyburden_curDay_Count <= Fuli_Dailyburden_FubenCount[weekCountD] and
		Fuli_Dailyburden_curDay_Count >= 0 then
		
		local remainCount = Fuli_Dailyburden_FubenCount[weekCountD] - Fuli_Dailyburden_curDay_Count
		local strTemp = ScriptGlobal_Format("#{JFRW_170217_7}",remainCount,Fuli_Dailyburden_FubenCount[weekCountD])
		if remainCount == 0 then
				strTemp = ScriptGlobal_Format("#{JFRW_170217_7}","#cff0000"..remainCount,Fuli_Dailyburden_FubenCount[weekCountD])
		end
		
		Fuli_Dailyburden_Info_text2:SetText(strTemp)
	end

	local KillBossIndex = 1
	if state == 1 then
		KillBossIndex = BossIndex + 1
	elseif (isInSecKill == 0 and isRefresh == 1) or state == 3 then --表示最后一个boss也扫荡完成
		KillBossIndex = BossMaxNum + 1
		Fuli_Dailyburden_Info_text1:SetText("#{JFRW_170217_8}")
	end
	
	for i=1, BossMaxNum do
		Fuli_Dailyburden_BossIcon[i]:Show()
		Fuli_Dailyburden_BossName[i]:Show()
		Fuli_Dailyburden_BossName[i]:SetText("#cfff263"..BossName[i])
		
		if BossIcon[i] ~= nil and BossIcon[i] ~= "" then
				local sPos,_ = string.find(BossIcon[i]," ");
				local IconImageSet = string.sub(BossIcon[i],5,sPos-1);
				local IconIamge = string.sub(BossIcon[i],sPos+7)
				if nil ~= IconImageSet and nil ~= IconIamge then
					Fuli_Dailyburden_BossIcon[i]:SetImage(IconImageSet,IconIamge)
				end
		end
		
		if i < KillBossIndex then
			if KillBossIndex == i + 1 and isRefresh == 1 and Fuli_Dailyburden_curPassIndex ~= KillBossIndex then
				Fuli_Dailyburden_BossingAnimate[i]:Show()
				Fuli_Dailyburden_BossingAnimate[i]:SetToolTip("#{FBSD_150126_30}")
				Fuli_Dailyburden_BossDieIcon[i]:Hide()
				Fuli_Dailyburden_Timer[i]:SetProperty("Timer", "1.8");
			else
				Fuli_Dailyburden_BossingAnimate[i]:Hide()
				Fuli_Dailyburden_BossDieIcon[i]:Show()
				Fuli_Dailyburden_BossDieIcon[i]:SetToolTip("#{FBSD_150126_30}")
			end
			
			Fuli_Dailyburden_BossButton[i]:Hide()
		elseif i == KillBossIndex then
			Fuli_Dailyburden_BossDieIcon[i]:Hide()
			Fuli_Dailyburden_BossButton[i]:Show()
			Fuli_Dailyburden_BossButton[i]:Enable()
			Fuli_Dailyburden_BossButton[i]:SetToolTip("#{FBSD_150126_29}")
			Fuli_Dailyburden_BossButton[i]:PlayWarning(1)
			Fuli_Dailyburden_BossingAnimate[i]:Hide()
			local strTemp = ScriptGlobal_Format("#{JFRW_170217_6}",BossName[i])
			Fuli_Dailyburden_Info_text1:SetText(strTemp)
		else
			Fuli_Dailyburden_BossDieIcon[i]:Hide()
			Fuli_Dailyburden_BossButton[i]:Hide()
			Fuli_Dailyburden_BossIcon[i]:SetToolTip("#{FBSD_150126_28}")
			Fuli_Dailyburden_BossingAnimate[i]:Hide()
		end
	end
	
	for i = BossMaxNum + 1, Fuli_Dailyburden_MaxBoss do
		Fuli_Dailyburden_BossIcon[i]:Hide()
		Fuli_Dailyburden_BossName[i]:Hide()
	end
	
	if Fuli_Dailyburden_CheckButton == 1 then
		Fuli_Dailyburden_Double_Check:SetCheck(1)
	else
		Fuli_Dailyburden_Double_Check:SetCheck(0)
	end
	
	if Fuli_Dailyburden_GiveUpCheckButton == 1 then
		Fuli_Dailyburden_Abandon:SetCheck(1)
	else
		Fuli_Dailyburden_Abandon:SetCheck(0)
	end
	
	if CanDoubleExp == 1 then
		Fuli_Dailyburden_Double_Info:Show()
	else
		Fuli_Dailyburden_Double_Info:Hide()
	end
	
	if isRefresh == 1 or isInSecKill == 2 then
		Fuli_Dailyburden_Double_Check:Disable()
	else
		Fuli_Dailyburden_Double_Check:Enable()
	end
end

function Fuli_Dailyburden_SendSecKill(index) 
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFuBenSecKill");
		Set_XSCRIPT_ScriptID(892428);
		Set_XSCRIPT_Parameter(0,Fuli_Dailyburden_curFubenId);
		Set_XSCRIPT_Parameter(1,index);
		Set_XSCRIPT_Parameter(2,Fuli_Dailyburden_Double_Check:GetCheck());
		Set_XSCRIPT_Parameter(3,1);
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();
	
	Fuli_Dailyburden_BossButton[index]:Disable()
end

function Fuli_Dailyburden_OnOkClicked()
	SecKillRemoveItem()
end

function Fuli_Dailyburden_OnCheckClick()	
	if Fuli_Dailyburden_CheckButton == 1 then
		Fuli_Dailyburden_CheckButton = 0
	else
		Fuli_Dailyburden_CheckButton = 1
	end
end

function Fuli_Dailyburden_OnGiveUpCheckClick()
	if Fuli_Dailyburden_GiveUpCheckButton == 1 then
		Fuli_Dailyburden_GiveUpCheckButton = 0
	else
		Fuli_Dailyburden_GiveUpCheckButton = 1
	end
end

function Fuli_Dailyburden_OnTimer(index)
	Fuli_Dailyburden_BossingAnimate[index]:Hide()
	Fuli_Dailyburden_BossDieIcon[index]:Show()

	Fuli_Dailyburden_BossDieIcon[index]:SetToolTip("#{FBSD_150126_30}")
	Fuli_Dailyburden_Timer[index]:SetProperty("Timer", "-1")
end

function Fuli_Dailyburden_OnGiveUp()
	if SecKillItemListEmpty() ==1 then
		return
	end
	
	if Fuli_Dailyburden_GiveUpCheckButton == 1  then
		PushEvent( "SECKILL_GIVEUP_CONFIRM" )
	else
		SecKillGiveUpItem()
	end
end

function Fuli_Dailyburden_OnBossButton(index)
	if SecKillItemListEmpty() ~=1 then
		PushDebugMessage("#{JFRW_170217_40}")
		return
	end
	
	local IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao = GetSecKillInfoByIndex(Fuli_Dailyburden_curFubenId)
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()	
		
	if Fuli_Dailyburden_Double_Check:GetCheck() == 1 and index == 1 and CanDoubleExp == 1 and isInSecKill == 0 then
		PushEvent( "DOUBLE_DAILYSECKILL_CONFIRM",index, numYuanbao )
	else
		Fuli_Dailyburden_SendSecKill(index)
	end
	
	Fuli_Dailyburden_curPassIndex = index
end

function Fuli_Dailyburden_Button1_Click()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Dailyburden_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Dailyburden_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end
	
	OpenStrongRoadDiaoWen(1)
	
	Variable:SetVariable("SelfFuliUIPos", Fuli_Dailyburden_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Dailyburden_Button3_Click()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Dailyburden_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Dailyburden_Button4_Click()
	
end

function Fuli_Dailyburden_Button5_Click()
end

function Fuli_Dailyburden_Button6_Click()

end

function Fuli_Dailyburden_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	Variable:SetVariable("SelfFuliUIPos", Fuli_Dailyburden_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Dailyburden_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Dailyburden_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Dailyburden_AgainClicked()
	Fuli_Dailyburden_curPassIndex = 0
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenDailyFuBen")
		Set_XSCRIPT_ScriptID(892428)
		Set_XSCRIPT_Parameter(0,0);
		Set_XSCRIPT_Parameter(1,1);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
