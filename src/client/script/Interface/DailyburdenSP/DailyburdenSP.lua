-- 界面的默认相对位置
local DailyburdenSP_UnifiedXPosition;
local DailyburdenSP_UnifiedYPosition;

local DailyburdenSP_week = -1
local DailyburdenSP_curFubenId = -1
local DailyburdenSP_curDay_Count = -1

--格子及其编号
local DailyburdenSP_ITEM_NUM = 12;
local DailyburdenSP_ITEMS = {};

local DailyburdenSP_Info;
local DailyburdenSP_Info_text1;
local DailyburdenSP_Info_text2;
local DailyburdenSP_Double_Info;
local DailyburdenSP_Double_Check;
local DailyburdenSP_Abandon;
local DailyburdenSP_BossIcon = {}
local DailyburdenSP_BossButton = {}
local DailyburdenSP_BossingAnimate = {}
local DailyburdenSP_BossDieIcon = {}
local DailyburdenSP_BossName = {}
local DailyburdenSP_Timer = {}
local DailyburdenSP_CheckButton1;
local DailyburdenSP_CheckButton2;
local DailyburdenSP_CheckButton3;
local DailyburdenSP_CheckButton5;
local DailyburdenSP_CheckButton6;
local DailyburdenSP_tips1;
local DailyburdenSP_tips2;
local DailyburdenSP_tips3;
local DailyburdenSP_tips5;
local DailyburdenSP_tips6;

local DailyburdenSP_MaxBoss = 6
local DailyburdenSP_GiveUpCheckButton = 1
local DailyburdenSP_CheckButton = 0
local DailyburdenSP_curPassIndex = 0

--周一到周五对应的副本ID
DailyburdenSP_FubenId = { [1] = 1, [2] = 3, [3] = 8, [4] = 0, [5] = 1}

DailyburdenSP_FubenCount = {3,2,3,3,3}
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

function DailyburdenSP_PreLoad()
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

function DailyburdenSP_OnLoad()
	DailyburdenSP_UnifiedXPosition	= DailyburdenSP_Frame : GetProperty("UnifiedXPosition");
	DailyburdenSP_UnifiedYPosition	= DailyburdenSP_Frame : GetProperty("UnifiedYPosition");


	DailyburdenSP_ITEMS[1] = DailyburdenSP_Item1
	DailyburdenSP_ITEMS[2] = DailyburdenSP_Item2
	DailyburdenSP_ITEMS[3] = DailyburdenSP_Item3
	DailyburdenSP_ITEMS[4] = DailyburdenSP_Item4
	DailyburdenSP_ITEMS[5] = DailyburdenSP_Item5
	DailyburdenSP_ITEMS[6] = DailyburdenSP_Item6
	DailyburdenSP_ITEMS[7] = DailyburdenSP_Item7
	DailyburdenSP_ITEMS[8] = DailyburdenSP_Item8
	DailyburdenSP_ITEMS[9] = DailyburdenSP_Item9
	DailyburdenSP_ITEMS[10] = DailyburdenSP_Item10
	DailyburdenSP_ITEMS[11] = DailyburdenSP_Item11
	DailyburdenSP_ITEMS[12] = DailyburdenSP_Item12

	DailyburdenSP_BossIcon[1] = DailyburdenSP_Boss1
	DailyburdenSP_BossIcon[2] = DailyburdenSP_Boss2
	DailyburdenSP_BossIcon[3] = DailyburdenSP_Boss3
	DailyburdenSP_BossIcon[4] = DailyburdenSP_Boss4
	DailyburdenSP_BossIcon[5] = DailyburdenSP_Boss5
	DailyburdenSP_BossIcon[6] = DailyburdenSP_Boss6

	DailyburdenSP_BossButton[1] = DailyburdenSP_Boss1AnimateImage
	DailyburdenSP_BossButton[2] = DailyburdenSP_Boss2AnimateImage
	DailyburdenSP_BossButton[3] = DailyburdenSP_Boss3AnimateImage
	DailyburdenSP_BossButton[4] = DailyburdenSP_Boss4AnimateImage
	DailyburdenSP_BossButton[5] = DailyburdenSP_Boss5AnimateImage
	DailyburdenSP_BossButton[6] = DailyburdenSP_Boss6AnimateImage

	DailyburdenSP_BossingAnimate[1] = DailyburdenSP_Boss1doing
	DailyburdenSP_BossingAnimate[2] = DailyburdenSP_Boss2doing
	DailyburdenSP_BossingAnimate[3] = DailyburdenSP_Boss3doing
	DailyburdenSP_BossingAnimate[4] = DailyburdenSP_Boss4doing
	DailyburdenSP_BossingAnimate[5] = DailyburdenSP_Boss5doing
	DailyburdenSP_BossingAnimate[6] = DailyburdenSP_Boss6doing

	DailyburdenSP_BossDieIcon[1] = DailyburdenSP_Boss1finish
	DailyburdenSP_BossDieIcon[2] = DailyburdenSP_Boss2finish
	DailyburdenSP_BossDieIcon[3] = DailyburdenSP_Boss3finish
	DailyburdenSP_BossDieIcon[4] = DailyburdenSP_Boss4finish
	DailyburdenSP_BossDieIcon[5] = DailyburdenSP_Boss5finish
	DailyburdenSP_BossDieIcon[6] = DailyburdenSP_Boss6finish

	DailyburdenSP_BossName[1] = DailyburdenSP_Boss1Name
	DailyburdenSP_BossName[2] = DailyburdenSP_Boss2Name
	DailyburdenSP_BossName[3] = DailyburdenSP_Boss3Name
	DailyburdenSP_BossName[4] = DailyburdenSP_Boss4Name
	DailyburdenSP_BossName[5] = DailyburdenSP_Boss5Name
	DailyburdenSP_BossName[6] = DailyburdenSP_Boss6Name

	DailyburdenSP_Timer[1] = DailyburdenSP_Boss1_StopWatch
	DailyburdenSP_Timer[2] = DailyburdenSP_Boss2_StopWatch
	DailyburdenSP_Timer[3] = DailyburdenSP_Boss3_StopWatch
	DailyburdenSP_Timer[4] = DailyburdenSP_Boss4_StopWatch
	DailyburdenSP_Timer[5] = DailyburdenSP_Boss5_StopWatch
	DailyburdenSP_Timer[6] = DailyburdenSP_Boss6_StopWatch

	DailyburdenSP_Info = DailyburdenSP_Explain1
	DailyburdenSP_Info_text1 = DailyburdenSP_Explain1_1
	DailyburdenSP_Info_text2 = DailyburdenSP_Explain_times
	DailyburdenSP_Double_Info = DailyburdenSP_Double
	DailyburdenSP_Double_Check = DailyburdenSP_DoubleCheck
	DailyburdenSP_Abandon = DailyburdenSP_AbandonCheckButton

	DailyburdenSP_CheckButton1 = DailyburdenSP_Button1
	DailyburdenSP_CheckButton2 = DailyburdenSP_Button2
	DailyburdenSP_CheckButton3 = DailyburdenSP_Button3
	DailyburdenSP_CheckButton5 = DailyburdenSP_Button5
	DailyburdenSP_CheckButton6 = DailyburdenSP_Button6

	DailyburdenSP_tips1 = DailyburdenSP_Button1tips
	DailyburdenSP_tips2 = DailyburdenSP_Button2tips
	DailyburdenSP_tips3 = DailyburdenSP_Button3tips
	DailyburdenSP_tips5 = DailyburdenSP_Button5tips
	DailyburdenSP_tips6 = DailyburdenSP_Button6tips



	g_ButtonPos[1].x	= DailyburdenSP_CheckButton3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= DailyburdenSP_CheckButton3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= DailyburdenSP_tips3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= DailyburdenSP_tips3:GetProperty("UnifiedYPosition");

	g_ButtonPos[2].x	= DailyburdenSP_CheckButton6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= DailyburdenSP_CheckButton6:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= DailyburdenSP_tips6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= DailyburdenSP_tips6:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= DailyburdenSP_CheckButton5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= DailyburdenSP_CheckButton5:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= DailyburdenSP_tips5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= DailyburdenSP_tips5:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= DailyburdenSP_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= DailyburdenSP_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= DailyburdenSP_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= DailyburdenSP_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[5].x	= DailyburdenSP_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= DailyburdenSP_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= DailyburdenSP_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= DailyburdenSP_Button8tips:GetProperty("UnifiedYPosition");
end

-- OnEvent
function DailyburdenSP_OnEvent(event)
	DailyburdenSP_tips5 : Hide()
	if (event == "UI_COMMAND" ) then
		if tonumber(arg0) == 892428 then
			DailyburdenSP_week = Get_XParam_INT(0)
			DailyburdenSP_curDay_Count = Get_XParam_INT(1)

			if Get_XParam_INT(2) ~= 1 then
				return
			end

			OpenWindow("Packet")

			local SelfFuliUnionIPos = Variable:GetVariable("SPSelfFuliUIPos")
			if( SelfFuliUnionIPos ~= nil) then
				DailyburdenSP_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
			end

			this:Show()
			DailyburdenSP_Frame_UpdateCheckButton()
			DailyburdenSP_Update(0)

		elseif tonumber(arg0) == 20170301 then
			if this:IsVisible() then
				DailyburdenSP_Update(0)
			end

		elseif tonumber(arg0) == 20170302 then
			--local isShow = Get_XParam_INT(0)
			--DataPool:Lua_SetDailySeckillFlag( Get_XParam_INT( 0 ))

			--if isShow == 1 then
				--DailyburdenSP_tips5:Show()
			--else
				--DailyburdenSP_tips5:Hide()
			--end

		elseif tonumber(arg0) == 8889072 then
			nCharCreateDate = Get_XParam_INT( 8 );
			g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );

		elseif tonumber(arg0) == 89242837 then
			DailyburdenSP_curDay_Count = Get_XParam_INT(0)
			local remainCount = DailyburdenSP_FubenCount[DailyburdenSP_week] - DailyburdenSP_curDay_Count
			local strTemp = ScriptGlobal_Format("#{JFRW_170217_7}",remainCount,DailyburdenSP_FubenCount[DailyburdenSP_week])
			if remainCount == 0 then
				strTemp = ScriptGlobal_Format("#{JFRW_170217_7}","#cff0000"..remainCount,DailyburdenSP_FubenCount[DailyburdenSP_week])
			end
			DailyburdenSP_Info_text2:SetText(strTemp)
		end


	elseif (event == "REFRESH_DAILYSECKILL_PAGE") then
		if this:IsVisible() then
			DailyburdenSP_Update(1)
		end

	elseif (event == "REFRESH_SECKILL_ITEM") then
		if this:IsVisible() then
			DailyburdenSP_Item_Update()
		end

	elseif (event == "SEND_DAILYSECKILL") then
		if this:IsVisible() then
			DailyburdenSP_SendSecKill(tonumber(arg1))
		end


	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		DailyburdenSP_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		DailyburdenSP_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		DailyburdenSP_OnClosed()
	end


	if DailyburdenSP_curFubenId ~= -1 then
		local BossIcon = {}
		local BossName = {}
		local BossMaxNum = 0
		local FubenName
		local CanDoubleExp
		FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = GetSecKillBossIconByIndex(DailyburdenSP_curFubenId)

		local strExplainTxt = ""
		if Player:GetData("Is2606S") == 1 then
			strExplainTxt = ScriptGlobal_Format("#{QXFSG_260622_18}",FubenName)
		else
			strExplainTxt = ScriptGlobal_Format("#{JFRW_170217_5}",FubenName)
		end
		DailyburdenSP_Explain:SetText(strExplainTxt)
	end

end

function DailyburdenSP_Frame_UpdateCheckButton()
	--更新选中位置
	DailyburdenSP_CheckButton1:SetCheck(0)
	DailyburdenSP_CheckButton2:SetCheck(0)
	DailyburdenSP_CheckButton3:SetCheck(0)
	DailyburdenSP_CheckButton5:SetCheck(1)
	DailyburdenSP_CheckButton6:SetCheck(0)

	local nSalaryTask = 2
	local nShaoDang = 3
	local nOneDay = 4

	--更新按钮位置
	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 ) then
		DailyburdenSP_CheckButton3 : Hide();

		nSalaryTask = nSalaryTask - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1

	else
		DailyburdenSP_CheckButton3 : Show();
	end

	local nLevel = Player:GetLevel();
	if ( nLevel < 35 or DataPool:GetServerDayTime() > 20211016) then
		DailyburdenSP_CheckButton6:Hide()
		nSalaryTask = - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
	else
		DailyburdenSP_CheckButton6:Show()
	end


	if nSalaryTask ~= -1 then
		DailyburdenSP_CheckButton6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].x);
		DailyburdenSP_CheckButton6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].y);
		DailyburdenSP_tips6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].tipx);
		DailyburdenSP_tips6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].tipy);
	end

	DailyburdenSP_CheckButton5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
	DailyburdenSP_CheckButton5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
	DailyburdenSP_tips5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
	DailyburdenSP_tips5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);

	if nOneDay ~= -1 then
		DailyburdenSP_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		DailyburdenSP_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		DailyburdenSP_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		DailyburdenSP_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);

		DailyburdenSP_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].x);
		DailyburdenSP_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].y);
		DailyburdenSP_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].tipx);
		DailyburdenSP_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].tipy);
	end

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		DailyburdenSP_Button7tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		DailyburdenSP_Button7tips : Hide()
	end

	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		DailyburdenSP_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		DailyburdenSP_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		DailyburdenSP_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		DailyburdenSP_Button8 : Hide()
	end

	--刷新红点
	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		DailyburdenSP_tips1 : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		DailyburdenSP_tips1 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		DailyburdenSP_tips2 : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		DailyburdenSP_tips2 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 )then
			DailyburdenSP_tips3 : Hide() 
			DataPool:Lua_SetRedPointInUIShow(39, 0)
		else
			DailyburdenSP_tips3 : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		DailyburdenSP_tips3 : Hide()
	end


	--if DataPool:Lua_GetDailySeckillFlag() == 1 then
		--DailyburdenSP_tips5 : Show()
	--else
		--DailyburdenSP_tips5 : Hide()
	--end

	DailyburdenSP_tips6 : Hide()



	--DailyburdenSP_DragTitle:SetText("#{MYQD_150513_43}")


end

function DailyburdenSP_Frame_On_ResetPos()
	DailyburdenSP_Frame : SetProperty("UnifiedXPosition", DailyburdenSP_UnifiedXPosition);
	DailyburdenSP_Frame : SetProperty("UnifiedYPosition", DailyburdenSP_UnifiedYPosition);
end

function DailyburdenSP_OnClosed()
	this:Hide();

	for i=1, DailyburdenSP_MaxBoss do
		DailyburdenSP_Timer[i]:SetProperty("Timer", "-1");
	end
end

function DailyburdenSP_Item_Update()
	--显示物品栏的物品
	for i=1, DailyburdenSP_ITEM_NUM do
		DailyburdenSP_ITEMS[i]:SetActionItem(-1);
		DailyburdenSP_ITEMS[i]:Enable();
	end

	--从数据池中使用数据填入背包内的物品
	local nActIndex = 0

	for i=1, DailyburdenSP_ITEM_NUM  do
		local theAction = SecKillEnumItem(nActIndex);
		nActIndex = nActIndex+1;

		if theAction:GetID() ~= 0 then
			DailyburdenSP_ITEMS[i]:SetActionItem(theAction:GetID());
		else
			DailyburdenSP_ITEMS[i]:SetActionItem(-1);
		end
	end
end

function DailyburdenSP_Weekend(isIn)
	if isIn == 1 then
		DailyburdenSP_Info:Hide()
		DailyburdenSP_Double_Info:Hide()
		for i=1, DailyburdenSP_MaxBoss do
			DailyburdenSP_BossIcon[i]:Hide()
			DailyburdenSP_BossName[i]:Hide()
		end

	else
		DailyburdenSP_Info:Show()
		DailyburdenSP_Double_Info:Show()
		for i=1, DailyburdenSP_MaxBoss do
			DailyburdenSP_BossIcon[i]:Show()
			DailyburdenSP_BossName[i]:Show()
		end
	end
end

function DailyburdenSP_state()
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()
	if isInSecKill == 2 then
		return 1     --处于减负扫荡中

	elseif DailyburdenSP_week < 1 or DailyburdenSP_week > 5 then
		return 2     --处于双休日

	elseif 	DailyburdenSP_curDay_Count >= DailyburdenSP_FubenCount[DailyburdenSP_week]  then
		return 3     --今天已经扫荡过了

	else
		return 4		 --当天还未扫荡
	end
end

function DailyburdenSP_Update(isRefresh)
	DailyburdenSP_Again:Disable()
	DailyburdenSP_Againtips:Show()

	DailyburdenSP_Item_Update()

	if DailyburdenSP_week == -1 or DailyburdenSP_curDay_Count == -1 then
		return
	end

	local state = DailyburdenSP_state()
	--只有每次新打开界面，才判断
	if state == 2 and isRefresh == 0 then
		DailyburdenSP_Weekend(1)
		return
	else
		DailyburdenSP_Weekend(0)
	end

	--显示Boss图标
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()

	local BossIcon = {}
	local BossName = {}
	local BossMaxNum = 0

	if isInSecKill == 2 and DoubleExp == 1 then
		DailyburdenSP_CheckButton = 1
	end

	--最后一个boss扫荡完，fubenID记录上次的
	if isInSecKill ~= 0 or isRefresh ~= 1 then
		DailyburdenSP_curFubenId = DailyburdenSP_FubenId[DailyburdenSP_week]
		if state == 1 then
			DailyburdenSP_curFubenId = FubenID
		end
	end


	if state == 4 then
		isInSecKill = 0
		DoubleExp = 0
		BossIndex = 0
	end

	if DailyburdenSP_curFubenId ~= -1 then
		FubenName,BossMaxNum,BossIcon[1],BossName[1],BossIcon[2],BossName[2],BossIcon[3],BossName[3],BossIcon[4],BossName[4],BossIcon[5],BossName[5],BossIcon[6],BossName[6], CanDoubleExp = GetSecKillBossIconByIndex(DailyburdenSP_curFubenId)
	end
		--local strTemp = ScriptGlobal_Format("#{JFRW_170217_6}",FubenName)
		--DailyburdenSP_Info_text1:SetText(strTemp)
	--end

	--PushDebugMessage("isRefresh="..isRefresh.."BossMaxNum="..BossMaxNum.."BossIndex="..BossIndex)
	if isRefresh == 1 and 0==BossIndex then
		DailyburdenSP_Again:Enable()
		DailyburdenSP_Againtips:Hide()
	end

	--为了兼容周六日打开界面的情况，周六日打开时按周五数值计算
	local weekCountD = DailyburdenSP_week
	if weekCountD > 5 or weekCountD < 1 then
		weekCountD = 5
	end

	if DailyburdenSP_curDay_Count <= DailyburdenSP_FubenCount[weekCountD] and
		DailyburdenSP_curDay_Count >= 0 then

		local remainCount = DailyburdenSP_FubenCount[weekCountD] - DailyburdenSP_curDay_Count
		local strTemp = ScriptGlobal_Format("#{JFRW_170217_7}",remainCount,DailyburdenSP_FubenCount[weekCountD])
		if remainCount == 0 then
				strTemp = ScriptGlobal_Format("#{JFRW_170217_7}","#cff0000"..remainCount,DailyburdenSP_FubenCount[weekCountD])
		end
		DailyburdenSP_Info_text2:SetText(strTemp)
	end


	local KillBossIndex = 1
	if state == 1 then
		KillBossIndex = BossIndex + 1
	elseif (isInSecKill == 0 and isRefresh == 1) or state == 3 then --表示最后一个boss也扫荡完成
		KillBossIndex = BossMaxNum + 1
		DailyburdenSP_Info_text1:SetText("#{JFRW_170217_8}")

	end

--	PushDebugMessage("KillBossIndex="..KillBossIndex.."BossMaxNum="..BossMaxNum.."DailyburdenSP_curPassIndex="..DailyburdenSP_curPassIndex.."state="..state)
	for i=1, BossMaxNum do
		DailyburdenSP_BossIcon[i]:Show()
		DailyburdenSP_BossName[i]:Show()
		DailyburdenSP_BossName[i]:SetText("#cfff263"..BossName[i])

		if BossIcon[i] ~= nil and BossIcon[i] ~= "" then
				local sPos,_ = string.find(BossIcon[i]," ");
				local IconImageSet = string.sub(BossIcon[i],5,sPos-1);
				local IconIamge = string.sub(BossIcon[i],sPos+7)
				if nil ~= IconImageSet and nil ~= IconIamge then
					DailyburdenSP_BossIcon[i]:SetImage(IconImageSet,IconIamge)
				end
		end

		if i < KillBossIndex then
			if KillBossIndex == i + 1 and isRefresh == 1 and DailyburdenSP_curPassIndex ~= KillBossIndex then
				DailyburdenSP_BossingAnimate[i]:Show()
				DailyburdenSP_BossingAnimate[i]:SetToolTip("#{FBSD_150126_30}")
				DailyburdenSP_BossDieIcon[i]:Hide()
				DailyburdenSP_Timer[i]:SetProperty("Timer", "1.8");
			else
				DailyburdenSP_BossingAnimate[i]:Hide()
				DailyburdenSP_BossDieIcon[i]:Show()
				DailyburdenSP_BossDieIcon[i]:SetToolTip("#{FBSD_150126_30}")
			end

			DailyburdenSP_BossButton[i]:Hide()
		elseif i == KillBossIndex then
			DailyburdenSP_BossDieIcon[i]:Hide()
			DailyburdenSP_BossButton[i]:Show()
			DailyburdenSP_BossButton[i]:Enable()
			DailyburdenSP_BossButton[i]:SetToolTip("#{FBSD_150126_29}")
			DailyburdenSP_BossButton[i]:PlayWarning(1)
			DailyburdenSP_BossingAnimate[i]:Hide()
			local strTemp = ScriptGlobal_Format("#{JFRW_170217_6}",BossName[i])
			DailyburdenSP_Info_text1:SetText(strTemp)
		else
			DailyburdenSP_BossDieIcon[i]:Hide()
			DailyburdenSP_BossButton[i]:Hide()
			DailyburdenSP_BossIcon[i]:SetToolTip("#{FBSD_150126_28}")
			DailyburdenSP_BossingAnimate[i]:Hide()
		end
	end

	for i = BossMaxNum + 1, DailyburdenSP_MaxBoss do
		DailyburdenSP_BossIcon[i]:Hide()
		DailyburdenSP_BossName[i]:Hide()
	end

	if DailyburdenSP_CheckButton == 1 then
		DailyburdenSP_Double_Check:SetCheck(1)
	else
		DailyburdenSP_Double_Check:SetCheck(0)
	end

	if DailyburdenSP_GiveUpCheckButton == 1 then
		DailyburdenSP_Abandon:SetCheck(1)
	else
		DailyburdenSP_Abandon:SetCheck(0)
	end

	if CanDoubleExp == 1 then
		DailyburdenSP_Double_Info:Show()
	else
		DailyburdenSP_Double_Info:Hide()
	end

	if isRefresh == 1 or isInSecKill == 2 then
		DailyburdenSP_Double_Check:Disable()
	else
		DailyburdenSP_Double_Check:Enable()
	end
end

function DailyburdenSP_SendSecKill(index)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFuBenSecKill");
		Set_XSCRIPT_ScriptID(892428);
		Set_XSCRIPT_Parameter(0,DailyburdenSP_curFubenId);
		Set_XSCRIPT_Parameter(1,index);
		Set_XSCRIPT_Parameter(2,DailyburdenSP_Double_Check:GetCheck());
		Set_XSCRIPT_Parameter(3,1);
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();

	DailyburdenSP_BossButton[index]:Disable()
end

function DailyburdenSP_OnOkClicked()
	SecKillRemoveItem()
end

function DailyburdenSP_OnCheckClick()
	if DailyburdenSP_CheckButton == 1 then
		DailyburdenSP_CheckButton = 0
	else
		DailyburdenSP_CheckButton = 1
	end
end

function DailyburdenSP_OnGiveUpCheckClick()
	if DailyburdenSP_GiveUpCheckButton == 1 then
		DailyburdenSP_GiveUpCheckButton = 0
	else
		DailyburdenSP_GiveUpCheckButton = 1
	end
end

function DailyburdenSP_OnTimer(index)
	DailyburdenSP_BossingAnimate[index]:Hide()
	DailyburdenSP_BossDieIcon[index]:Show()

	DailyburdenSP_BossDieIcon[index]:SetToolTip("#{FBSD_150126_30}")
	DailyburdenSP_Timer[index]:SetProperty("Timer", "-1")
end

function DailyburdenSP_OnGiveUp()
	if SecKillItemListEmpty() ==1 then
		return
	end

	if DailyburdenSP_GiveUpCheckButton == 1  then
		PushEvent( "SECKILL_GIVEUP_CONFIRM" )
	else
		SecKillGiveUpItem()
	end
end

function DailyburdenSP_OnBossButton(index)
	if SecKillItemListEmpty() ~=1 then
		PushDebugMessage("#{JFRW_170217_40}")
		return
	end

	local IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao = GetSecKillInfoByIndex(DailyburdenSP_curFubenId)
	local isInSecKill,FubenID,BossIndex,DoubleExp = GetSecKillData()

	if DailyburdenSP_Double_Check:GetCheck() == 1 and index == 1 and CanDoubleExp == 1 and isInSecKill == 0 then
		PushEvent( "DOUBLE_DAILYSECKILL_CONFIRM",index, numYuanbao )
	else
		DailyburdenSP_SendSecKill(index)
	end

	DailyburdenSP_curPassIndex = index
end

function DailyburdenSP_Button1_Click()
	OpenMonthlySignSP(1)

	Variable:SetVariable("SPSelfFuliUIPos", DailyburdenSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function DailyburdenSP_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end

	OpenStrongRoadDiaoWenSP(1)

	Variable:SetVariable("SPSelfFuliUIPos", DailyburdenSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function DailyburdenSP_Button3_Click()
	OpenQianKunDaiSP(1)

	Variable:SetVariable("SPSelfFuliUIPos", DailyburdenSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function DailyburdenSP_Button4_Click()

end

function DailyburdenSP_Button5_Click()
end

function DailyburdenSP_Button6_Click()
end

function DailyburdenSP_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	Variable:SetVariable("SPSelfFuliUIPos", DailyburdenSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function DailyburdenSP_Button8_Click()
	OpenHuiGuiSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", DailyburdenSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function DailyburdenSP_AgainClicked()
	DailyburdenSP_curPassIndex = 0
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenDailyFuBen")
		Set_XSCRIPT_ScriptID(892428)
		Set_XSCRIPT_Parameter(0,1);
		Set_XSCRIPT_Parameter(1,1);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end


