--战令
--Prize用到的常量
local g_MAX_LEVEL = 11 --最da阶位
local g_MAX_TODAY_GET_POINT = 200

--其他页面变量
local g_bIsNewServerGiftsForLevelUpValid = 0
local g_bIsNewServerGiftsForLevelUpValid_2023 = 0
local nCharCreateDate = -1
local CreateDate = 904691712			-- 2013年08月22日08:00:00

--Prize用的全局变量
local g_Fuli_ZhanLing2_Frame_UnifiedPosition;
local g_MonthActivePoint = 0
local g_ServerYearMonth = 0
local g_LevelPoint = {	-- 日活-阶级 
	[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0,[6] = 0,[7] = 0,[8] = 0,[9] = 0,[10] = 0,[11] = 0
}
local g_Fuli_ZhanLing2_ActionBtn = {}
local g_PrizeStateAdvance = {}
local g_PrizeStateBasic = {}
local g_PrizeStateHigh = {}
local g_IsArousedAdvance = 0
local g_IsArousedHigh = 0
local g_TodayGetPoint = 0
local g_SeasonLeftDays = 0
local g_PointLevel = 0 --玩家当前的阶位
local g_IsShowRedPoint = 0

local nFullLevel = 0 --是否满分了

local g_LevelPrizeinfo = {}
--左边btn
local g_ButtonPos = {
	[1] = {x =0, y = 0, tipx =0, tipy =0},
	[2] = {x =0, y = 0, tipx =0, tipy =0},
	[3] = {x =0, y = 0, tipx =0, tipy =0},
	[4] = {x =0, y = 0, tipx =0, tipy =0},
	[5] = {x =0, y = 0, tipx =0, tipy =0},
	[6] = {x =0, y = 0, tipx =0, tipy =0},
	[7] = {x =0, y = 0, tipx =0, tipy =0},
}

--滚动条的位置
local g_Position_Scroll = 0;



--当前选择的奖励 0:不用选 1:选第一个 2:选第二个
local g_MyChoose = 0

local g_CurMonthDay = 0

--===============================================
-- PreLoad()
--===============================================
function Fuli_ZhanLing2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("OPEN_ZHANLING")
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
	this:RegisterEvent("UPDATE_DOUBLE_EXP",false)
end

--===============================================
-- OnEvent()
--===============================================
function Fuli_ZhanLing2_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		Fuli_ZhanLing2_OnClose()
	elseif event == "ADJEST_UI_POS" then
		Fuli_ZhanLing2_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Fuli_ZhanLing2_OnResetPos()	
	elseif event == "OPEN_ZHANLING" then
		if (tonumber(arg0) == 0) then
			Fuli_ZhanLing2_OnResetPos()
		else
			Fuli_ZhanLing2_OnSetLastPos()
		end
		--通知服务端脚本传数据
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskOpenMainUI" )
		Set_XSCRIPT_ScriptID( 790029 )
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

	elseif event == "UI_COMMAND" and (tonumber(arg0) == 79002901) then	--服务端传数据
		local nOper = Get_XParam_INT(0)	--界面操作类型（0 关闭，1打开， 2刷新）
		local nTime  = Get_XParam_INT(1) --服务器当前天数时间
		g_CurMonthDay = math.mod(nTime , 100)
		g_MonthActivePoint = Get_XParam_INT(2) --玩家当月战令点数
		g_TodayGetPoint = Get_XParam_INT(3) --玩家当日战令点数

		local prizeB_MD = Get_XParam_INT(4) --普通奖励MD  Basic
		local prizeA_MD = Get_XParam_INT(5) --付费奖励1MD Advance
		local prizeH_MD = Get_XParam_INT(6) --付费奖励2MD High
		g_PrizeStateAdvance = Fuli_ZhanLing2_GetBitTable(prizeA_MD)
		g_PrizeStateBasic = Fuli_ZhanLing2_GetBitTable(prizeB_MD)
		g_PrizeStateHigh = Fuli_ZhanLing2_GetBitTable(prizeH_MD)
		g_IsArousedAdvance = Get_XParam_INT(7) --是否激活RMB
		g_IsArousedHigh = Get_XParam_INT(8) --是否激活RMB
		g_IsShowRedPoint = Get_XParam_INT(9) --是否显示红点
		g_ServerYearMonth = math.floor(nTime / 100)
		g_SeasonLeftDays = Fuli_ZhanLing2_GetMonthLeftDays(nTime)
		g_Position_Scroll = 0
		--红点
		if 1 == g_IsShowRedPoint then
			DataPool:Lua_SetUpdateTipsFlag(5,1)
		else
			DataPool:Lua_SetUpdateTipsFlag(5,0)
		end
		if 0 == nOper then
			Fuli_ZhanLing2_OnClose()
			return 
		elseif 2 == nOper then
			if not this:IsVisible() then	
				return 
			end
			-- 只有打开页面时刷新页面才记录上一次的滚动条
			g_Position_Scroll = Fuli_ZhanLing2_UpFrame_RewardList:GetScrollPosition()	--保存上一次滚动条位置
		end
		Fuli_ZhanLing2_ShowXuanLingDanTips()
		Fuli_ZhanLing2_PrizePageOpen()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = 0
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 99847904 ) then
		nCharCreateDate = Get_XParam_INT( 0 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = Get_XParam_INT( 1 );
		g_bIsNewServerGiftsForLevelUpValid = 0
	elseif event == "UPDATE_REDPOINT_IN_UI" then 
		Fuli_ZhanLing2_UpdateRedPointUI()
	elseif event == "UPDATE_DOUBLE_EXP" and this:IsVisible() then
		Fuli_ZhanLing2_ShowXuanLingDanTips();
	end
end



function Fuli_ZhanLing2_OnLoad()
	g_Fuli_ZhanLing2_Frame_UnifiedPosition = Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition")
	--左边按钮
	g_ButtonPos[1].x	= Fuli_ZhanLing2_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_ZhanLing2_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_ZhanLing2_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_ZhanLing2_Button3tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[2].x	= Fuli_ZhanLing2_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_ZhanLing2_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_ZhanLing2_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_ZhanLing2_Button5tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[3].x	= Fuli_ZhanLing2_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_ZhanLing2_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_ZhanLing2_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_ZhanLing2_Button7tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[4].x	= Fuli_ZhanLing2_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_ZhanLing2_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_ZhanLing2_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_ZhanLing2_Button8tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[5].x	= Fuli_ZhanLing2_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_ZhanLing2_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_ZhanLing2_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_ZhanLing2_Button9tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[6].x	= Fuli_ZhanLing2_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_ZhanLing2_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_ZhanLing2_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_ZhanLing2_Button10tips:GetProperty("UnifiedYPosition");
end
function Fuli_ZhanLing2_Debug(str)
	Lua_TDU_Log("Fuli_MonthlySign_Debug : "..str)
	--PushDebugMessage("Fuli_MonthlySign_Debug : "..str)
end

--处理左边按钮
function Fuli_ZhanLing2_LeftButton()
	--处理左边btn
		local nShaoDang = 2
		local nOneDay = 3
		local nHuiGui 			= 4
		local nSuperSave		= 5
		local nZhanLing			= 6
			-- 角色创建日期
		if ( nCharCreateDate < CreateDate ) or  ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)  then
			Fuli_ZhanLing2_Button3 : Hide();
			nShaoDang = nShaoDang-1
			nOneDay = nOneDay-1
			nHuiGui   = nHuiGui - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
			
		--	return
		else
			Fuli_ZhanLing2_Button3 : Show();
		
		end
		
		local nLevel = Player:GetLevel();
		
		Fuli_ZhanLing2_Button5:Show()
		if ( nLevel < 60 ) then
			Fuli_ZhanLing2_Button5:Hide()
			nShaoDang = -1
			nOneDay = nOneDay-1			
			nHuiGui   = nHuiGui - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
		end

		nOneDay = -1
		if nOneDay == -1  then
			nHuiGui   = nHuiGui - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
			Fuli_ZhanLing2_Button7:Hide()
		end
		
	    if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
	    	Fuli_ZhanLing2_Button8 : Show()
	    elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
	    	Fuli_ZhanLing2_Button8 : Hide()
	    	nHuiGui   = - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
	    end
	    
	    if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
	    	Fuli_ZhanLing2_Button9 : Show()
	    elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
	    	Fuli_ZhanLing2_Button9 : Hide()
			nSuperSave =-1; 
			nZhanLing = nZhanLing -1
		end
		Fuli_ZhanLing2_Button10:Show()
		if ( nLevel < 30 ) then
			Fuli_ZhanLing2_Button10:Hide()
			nZhanLing = nZhanLing -1
		end
		
		
		if nShaoDang ~= -1 then
			Fuli_ZhanLing2_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
			Fuli_ZhanLing2_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
			Fuli_ZhanLing2_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
			Fuli_ZhanLing2_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);
		
		end
		
		if nOneDay ~= -1 then
			Fuli_ZhanLing2_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
			Fuli_ZhanLing2_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
			Fuli_ZhanLing2_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
			Fuli_ZhanLing2_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
			
		end		
		
		if nHuiGui ~= -1 then
			Fuli_ZhanLing2_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
			Fuli_ZhanLing2_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
			Fuli_ZhanLing2_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
			Fuli_ZhanLing2_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
		end
	
	
		if nSuperSave ~= -1 then
			Fuli_ZhanLing2_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].x);
			Fuli_ZhanLing2_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].y);
			Fuli_ZhanLing2_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].tipx);
			Fuli_ZhanLing2_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].tipy);
		end	

		if nZhanLing ~= -1 then
			Fuli_ZhanLing2_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
			Fuli_ZhanLing2_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
			Fuli_ZhanLing2_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
			Fuli_ZhanLing2_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
		end
end

function Fuli_ZhanLing2_GetPrizeInfo()
		--获取奖励信息 计算阶位 获取领奖MD
		for i = 1,g_MAX_LEVEL do
			local bRet,nPoint,
				nShowB1,nItemNumB1,
				nShowB2,nItemNumB2,
				nShowB3,nItemNumB3,
				nShowB4,nItemNumB4,
				nShowB5,nItemNumB5,
				nShowA1,nItemNumA1,
				nShowA2,nItemNumA2,
				nShowA3,nItemNumA3,
				nShowA4,nItemNumA4,
				nShowA5,nItemNumA5,
				nShowA6,nItemNumA6,
				nShowH1,nItemNumH1,
				nShowH2,nItemNumH2,
				nShowH3,nItemNumH3,
				nShowH4,nItemNumH4,
				nShowH5,nItemNumH5,
				nShowH6,nItemNumH6
				=GetZhanLingPrizeInfo(g_ServerYearMonth,i)
			if nil == bRet or 0 == bRet then
				return 0 
			end
			g_LevelPoint[i] = nPoint
			g_LevelPrizeinfo[i] = {}
			g_LevelPrizeinfo[i].ShowA1 = nShowA1
			g_LevelPrizeinfo[i].itemNumA1 = nItemNumA1
			g_LevelPrizeinfo[i].ShowA2 = nShowA2
			g_LevelPrizeinfo[i].itemNumA2 = nItemNumA2
			g_LevelPrizeinfo[i].ShowA3 = nShowA3
			g_LevelPrizeinfo[i].itemNumA3 = nItemNumA3
			g_LevelPrizeinfo[i].ShowA4 = nShowA4
			g_LevelPrizeinfo[i].itemNumA4 = nItemNumA4
			g_LevelPrizeinfo[i].ShowA5 = nShowA5
			g_LevelPrizeinfo[i].itemNumA5 = nItemNumA5
			g_LevelPrizeinfo[i].ShowA6 = nShowA6
			g_LevelPrizeinfo[i].itemNumA6 = nItemNumA6
			g_LevelPrizeinfo[i].ShowB1 = nShowB1
			g_LevelPrizeinfo[i].itemNumB1 = nItemNumB1
			g_LevelPrizeinfo[i].ShowB2 = nShowB2
			g_LevelPrizeinfo[i].itemNumB2 = nItemNumB2
			g_LevelPrizeinfo[i].ShowB3 = nShowB3
			g_LevelPrizeinfo[i].itemNumB3 = nItemNumB3
			g_LevelPrizeinfo[i].ShowB4 = nShowB4
			g_LevelPrizeinfo[i].itemNumB4 = nItemNumB4
			g_LevelPrizeinfo[i].ShowB5 = nShowB5
			g_LevelPrizeinfo[i].itemNumB5 = nItemNumB5
			g_LevelPrizeinfo[i].ShowH1 = nShowH1
			g_LevelPrizeinfo[i].itemNumH1 = nItemNumH1
			g_LevelPrizeinfo[i].ShowH2 = nShowH2
			g_LevelPrizeinfo[i].itemNumH2 = nItemNumH2
			g_LevelPrizeinfo[i].ShowH3 = nShowH3
			g_LevelPrizeinfo[i].itemNumH3 = nItemNumH3
			g_LevelPrizeinfo[i].ShowH4 = nShowH4
			g_LevelPrizeinfo[i].itemNumH4 = nItemNumH4
			g_LevelPrizeinfo[i].ShowH5 = nShowH5
			g_LevelPrizeinfo[i].itemNumH5 = nItemNumH5
			g_LevelPrizeinfo[i].ShowH6 = nShowH6
			g_LevelPrizeinfo[i].itemNumH6 = nItemNumH6
		end
		--end for
		--积分计算阶位
		if g_MonthActivePoint < 0 then
			return 0 
		end
		g_PointLevel = g_MAX_LEVEL
		for i = 1, g_MAX_LEVEL do
			if g_MonthActivePoint < g_LevelPoint[i] then
				g_PointLevel = i
				break
			end
		end

		if g_MonthActivePoint >= g_LevelPoint[g_MAX_LEVEL] then
			nFullLevel = 1
		else
			nFullLevel = 0
		end



		return 1
end

--打开战令奖励界面
function Fuli_ZhanLing2_PrizePageOpen()	
	if 1 ~= Fuli_ZhanLing2_GetPrizeInfo() then  --加载奖励表信息
		PushDebugMessage("页面数据加载失败，请重新打开页面。")
		return
	end
	Fuli_ZhanLing2_LeftButton() --左边按钮
	Fuli_ZhanLing2_UpdateRedPointUI()  --左边tips
	Fuli_ZhanLing2_Button10:SetCheck(1)
	Fuli_ZhanLing2_Reward_Info:SetText("#{TLZL_190802_100}")
	
	if Player:GetData("Is2606S") == 1 then
		Fuli_ZhanLing2_Banner:SetProperty("Image", "set:XinShou_QX image:Banner")
		Fuli_ZhanLing2_Banner_Info:SetText("#{QXFXG_260703_11}")
		Fuli_ZhanLing2_Banner_Info:Show()
	else
		Fuli_ZhanLing2_Banner:SetProperty("Image", "set:Zhanling5 image:Zhanling_Bannner")
		Fuli_ZhanLing2_Banner_Info:Hide()
	end
	
	--界面数据
	--阶位赛季信息
	local strTemp = nil
	if g_MonthActivePoint >= g_LevelPoint[g_MAX_LEVEL] then
		strTemp = "#{TLZL_190802_93}"
	else
		strTemp = ScriptGlobal_Format("#{TLZL_190802_32}",g_TodayGetPoint,g_MAX_TODAY_GET_POINT)
	end
	Fuli_ZhanLing2_Reward_Down_Get:SetText(strTemp)
	if g_SeasonLeftDays <= 1 then
		Fuli_ZhanLing2_Reward_Down_Remain:SetText("#{TLZL_190802_20}")
	elseif g_SeasonLeftDays <= 7 then
		strTemp = ScriptGlobal_Format("#{TLZL_190802_92}",g_SeasonLeftDays)
		Fuli_ZhanLing2_Reward_Down_Remain:SetText(strTemp)
	else
		strTemp = ScriptGlobal_Format("#{TLZL_190802_21}",g_SeasonLeftDays)
		Fuli_ZhanLing2_Reward_Down_Remain:SetText(strTemp)
	end
	Fuli_ZhanLing2_Reward_Down_Remain:SetToolTip("#{TLZL_190802_115}")

	--List
	Fuli_ZhanLing2_ClearRewardList()
	this:Show()
	for i = 1 , g_MAX_LEVEL do

		if nil == g_LevelPrizeinfo[i] or nil == g_PrizeStateAdvance[i] or nil ==g_PrizeStateBasic[i] then
			PushDebugMessage("页面数据加载失败，请重新打开页面。")
			return 
		end

		local bar = Fuli_ZhanLing2_UpFrame_RewardList:AddChild("Fuli_ZhanLing2_UpFrame_RewardContent")
		if not bar then 
			break
		end
		--阶段积分
		local pointText = bar:GetSubItem("Fuli_ZhanLing2_UpFrame_Reward_PointText")
		if g_MonthActivePoint < g_LevelPoint[i] then
			pointText:SetText(ScriptGlobal_Format("#{TLZL_190802_31}",g_MonthActivePoint,g_LevelPoint[i]))
		else
			pointText:SetText(ScriptGlobal_Format("#{TLZL_190802_17}",g_LevelPoint[i]))
		end

		--ActionItem
		local barItem = nil
		local theAction = nil
		----Basic 3个
		barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_BasicItem1")
		theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowB1,g_LevelPrizeinfo[i].itemNumB1)
		if theAction:GetID() ~= 0 and barItem ~= nil then
			barItem:SetActionItem(theAction:GetID())
			table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		else
			barItem:Hide()
		end
		
		barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_BasicItem2")
		theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowB2,g_LevelPrizeinfo[i].itemNumB2)
		if theAction:GetID() ~= 0 and barItem ~= nil then
			barItem:SetActionItem(theAction:GetID())
			table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		else
			barItem:Hide() 
		end

		-- barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_BasicItem3")
		-- theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowB3,g_LevelPrizeinfo[i].itemNumB3)
		-- if theAction:GetID() ~= 0 and barItem ~= nil then
		-- 	barItem:SetActionItem(theAction:GetID())
		-- 	table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		-- else
		-- 	barItem:Hide() 
		-- end

		----Advanced 3个
		barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedItem1")
		theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowA1,g_LevelPrizeinfo[i].itemNumA1)
		if theAction:GetID() ~= 0 and barItem ~= nil then
			barItem:SetActionItem(theAction:GetID())
			table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		else
			barItem:Hide() 
		end

		barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedItem2")
		theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowA2,g_LevelPrizeinfo[i].itemNumA2)
		if theAction:GetID() ~= 0 and barItem ~= nil then
			barItem:SetActionItem(theAction:GetID())
			table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		else
			barItem:Hide() 
		end

		-- barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedItem3")
		-- theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowA3,g_LevelPrizeinfo[i].itemNumA3)
		-- if theAction:GetID() ~= 0 and barItem ~= nil then
		-- 	barItem:SetActionItem(theAction:GetID())
		-- 	table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		-- else
		-- 	barItem:Hide() 
		-- end

		--High 3个
		barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedItem5")
		theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowH1,g_LevelPrizeinfo[i].itemNumH1)
		if theAction:GetID() ~= 0 and barItem ~= nil then
			barItem:SetActionItem(theAction:GetID())
			table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		else
			barItem:Hide() 
		end

		barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedItem6")
		theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowH2,g_LevelPrizeinfo[i].itemNumH2)
		if theAction:GetID() ~= 0 and barItem ~= nil then
			barItem:SetActionItem(theAction:GetID())
			table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		else
			barItem:Hide() 
		end

		-- barItem= bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedItem7")
		-- theAction = DataPool:CreateActionItemForShow(g_LevelPrizeinfo[i].ShowH3,g_LevelPrizeinfo[i].itemNumH3)
		-- if theAction:GetID() ~= 0 and barItem ~= nil then
		-- 	barItem:SetActionItem(theAction:GetID())
		-- 	table.insert( g_Fuli_ZhanLing2_ActionBtn,barItem)
		-- else
		-- 	barItem:Hide() 
		-- end

		--按钮
		local basicButton = bar:GetSubItem("Fuli_ZhanLing2_Reward_BasicGetButton")
		local basicHaveGetImg = bar:GetSubItem("Fuli_ZhanLing2_Reward_BasicGetMark")
		local basicCannotGetImg = bar:GetSubItem("Fuli_ZhanLing2_Reward_BasicDisableMark")

		local arouseAdvancedButton = bar:GetSubItem("Fuli_ZhanLing2_SecondaryButton")
		local advancedButton = bar:GetSubItem("Fuli_ZhanLing2_Reward_SecondaryGetButton")
		local advancedHaveGetImg = bar:GetSubItem("Fuli_ZhanLing2_Reward_SecondaryGetMark")
		local advancedCannotGetImg = bar:GetSubItem("Fuli_ZhanLing2_Reward_SecondaryDisableMark")

		local arouseHighButton = bar:GetSubItem("Fuli_ZhanLing2_ArouseButton")
		local highButton = bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedGetButton")
		local highHaveGetImg = bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedGetMark")
		local highCannotGetImg = bar:GetSubItem("Fuli_ZhanLing2_Reward_AdvancedDisableMark")

		if basicButton and basicHaveGetImg and basicCannotGetImg 
		and 
		arouseAdvancedButton and advancedButton and advancedHaveGetImg and advancedCannotGetImg 
		and  
		arouseHighButton and highButton and highHaveGetImg and highCannotGetImg 
		then
			--button绑定事件
			basicButton:SetEvent("Clicked",string.format( "Fuli_ZhanLing2_GetPrize(%d,%d)",i,0 ))
			advancedButton:SetEvent("Clicked",string.format( "Fuli_ZhanLing2_GetPrize(%d,%d)",i,1 ))
			highButton:SetEvent("Clicked",string.format( "Fuli_ZhanLing2_GetPrize(%d,%d)",i,2 ))
			arouseAdvancedButton:SetEvent("Clicked","Fuli_ZhanLing2_ArouseAdvance()")
			arouseHighButton:SetEvent("Clicked","Fuli_ZhanLing2_ArouseHigh()")

			if i >= g_PointLevel and 0 == nFullLevel then
				--未达到的阶级
				--basic
				basicButton:Hide()
				basicHaveGetImg:Hide()
				basicCannotGetImg:Show()

				--advanced
				if 0 == g_IsArousedAdvance then
					if 1 == i then
						arouseAdvancedButton:Show()
						advancedButton:Hide()
						advancedHaveGetImg:Hide()
						advancedCannotGetImg:Hide()
					else
						arouseAdvancedButton:Hide()
						advancedButton:Hide()
						advancedHaveGetImg:Hide()
						advancedCannotGetImg:Hide()
					end
				else
					arouseAdvancedButton:Hide()
					advancedButton:Hide()
					advancedHaveGetImg:Hide()
					advancedCannotGetImg:Show()
				end
				--high
				if 0 == g_IsArousedHigh then
					if 1 == i then
						arouseHighButton:Show()
						highButton:Hide()
						highHaveGetImg:Hide()
						highCannotGetImg:Hide()
					else
						arouseHighButton:Hide()
						highButton:Hide()
						highHaveGetImg:Hide()
						highCannotGetImg:Hide()
					end
				else
					arouseHighButton:Hide()
					highButton:Hide()
					highHaveGetImg:Hide()
					highCannotGetImg:Show()
				end
			else
				--已达到的阶级
				--Basic
				if 0 == g_PrizeStateBasic[i] then
					basicButton:Show()
					basicHaveGetImg:Hide()
					basicCannotGetImg:Hide()
				else
					basicButton:Hide()
					basicHaveGetImg:Show()
					basicCannotGetImg:Hide()
				end

				--Advanced
				if 0 == g_IsArousedAdvance then
					--未解锁
					if 1 == i then
						arouseAdvancedButton:Show()
						advancedButton:Hide()
						advancedHaveGetImg:Hide()
						advancedCannotGetImg:Hide()
					else
						arouseAdvancedButton:Hide()
						advancedButton:Hide()
						advancedHaveGetImg:Hide()
						advancedCannotGetImg:Hide()
					end
				else
					--已解锁
					if 1 == g_PrizeStateAdvance[i] then
						--已领取
						arouseAdvancedButton:Hide()
						advancedButton:Hide()
						advancedHaveGetImg:Show()
						advancedCannotGetImg:Hide()
					else
						--未领取
						arouseAdvancedButton:Hide()
						advancedButton:Show()
						advancedHaveGetImg:Hide()
						advancedCannotGetImg:Hide()
					end
				end

				--High
				if 0 == g_IsArousedHigh then
					--未解锁
					if 1 == i then
						arouseHighButton:Show()
						highButton:Hide()
						highHaveGetImg:Hide()
						highCannotGetImg:Hide()
					else
						arouseHighButton:Hide()
						highButton:Hide()
						highHaveGetImg:Hide()
						highCannotGetImg:Hide()
					end
				else
					--已解锁
					if 1 == g_PrizeStateHigh[i] then
						--已领取
						arouseHighButton:Hide()
						highButton:Hide()
						highHaveGetImg:Show()
						highCannotGetImg:Hide()
					else
						--未领取
						arouseHighButton:Hide()
						highButton:Show()
						highHaveGetImg:Hide()
						highCannotGetImg:Hide()
					end
				end
			end
		end
	end
	Fuli_ZhanLing2_UpFrame_RewardList:SetScrollPosition(g_Position_Scroll)
	this:Show()
end


function Fuli_ZhanLing2_ArouseAdvance()
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskActRMBReward")  --脚本接口
			Set_XSCRIPT_ScriptID(790029) --脚本编号 
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end
function Fuli_ZhanLing2_ArouseHigh()
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskActRMBReward")  --脚本接口
			Set_XSCRIPT_ScriptID(790029) --脚本编号 
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--领取 nType：青龙-0 朱雀-1
function Fuli_ZhanLing2_GetPrize(nIndex,nType)
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskGetReward")  --脚本接口
			Set_XSCRIPT_ScriptID(790029) --脚本编号 
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_Parameter(1,nType)
			Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function Fuli_ZhanLing2_Help_Clicked()
	-- 借用一下别人的通道
	PushEvent("OPEN_SWEEPPAGE_QUEST", "Fuli_ZhanLing2")
end

--小红点
function Fuli_ZhanLing2_UpdateRedPointUI()

	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_ZhanLing2_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_ZhanLing2_Button7tips : Hide()
	end

	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_ZhanLing2_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_ZhanLing2_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_ZhanLing2_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_ZhanLing2_Button8 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_ZhanLing2_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_ZhanLing2_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_ZhanLing2_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_ZhanLing2_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if nCharCreateDate ~= -1 and ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)then
			DataPool:Lua_SetRedPointInUIShow(39, 0)
			Fuli_ZhanLing2_Button3tips : Hide()
		else
			Fuli_ZhanLing2_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_ZhanLing2_Button3tips : Hide()
	end


	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_ZhanLing2_Button5tips : Show()
	else
		Fuli_ZhanLing2_Button5tips : Hide()
	end


	
	-- 福利 累充 
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_ZhanLing2_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_ZhanLing2_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_ZhanLing2_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_ZhanLing2_Button10tips : Hide()
	end
	

end

function Fuli_ZhanLing2_ClearRewardList()
	for i = 1, table.getn(g_Fuli_ZhanLing2_ActionBtn) do 
		if g_Fuli_ZhanLing2_ActionBtn[i] ~= nil then
			g_Fuli_ZhanLing2_ActionBtn[i]:SetActionItem(-1)
			g_Fuli_ZhanLing2_ActionBtn[i] = nil
		end
	end
	Fuli_ZhanLing2_UpFrame_RewardList:Clear()	
end

function Fuli_ZhanLing2_OnHide()
	Fuli_ZhanLing2_ClearRewardList()
end

function Fuli_ZhanLing2_OnClose()
	this:Hide()
end


function Fuli_ZhanLing2_CloseClicked()
	Fuli_ZhanLing2_OnClose()
end

function Fuli_ZhanLing2_OnResetPos()
	Fuli_ZhanLing2_Frame:SetProperty("UnifiedPosition", g_Fuli_ZhanLing2_Frame_UnifiedPosition)
end

function Fuli_ZhanLing2_OnSetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
		Fuli_ZhanLing2_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

function Fuli_ZhanLing2_GetBitTable(nOct)
	local BitTable = {}
	local oct = nOct
	for i = 1 , g_MAX_LEVEL do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	return BitTable
end

function Fuli_ZhanLing2_GetMonthLeftDays(nTime)
	local days = math.mod(nTime , 100)
	nTime = math.floor(nTime / 100)
	local month = math.mod(nTime , 100)
	local year = math.floor(nTime / 100)
	if days < 1 or days >31 or month < 1 or month > 12 then
		return 0
	end
	if 4 == month or 6 == month or 9 == month or 11 == month  then
		return (30 - days + 1)
	elseif 2 == month then
		if ( 0 == math.mod(year , 4) and 0 ~= math.mod(year,100) ) or 0 == math.mod(year , 400) then
			--闰年
			return (29 - days + 1)
		else
			return (28 - days + 1)
		end
	else
		return (31 - days + 1)
	end

	return 0
end

function Fuli_ZhanLing2_ClickBuy()
	--通知服务端脚本传数据
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name( "AskOpenAddProgressUI" )
	Set_XSCRIPT_ScriptID( 790029 )
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Fuli_ZhanLing2_ShowXuanLingDanTips()
	if Player:GetData("Is2606S") == 1 then
		Fuli_ZhanLing2_StopBtnBK:Hide();
		return
	end
	
	Fuli_ZhanLing2_StopBtnBK:Show();
	local sSubTitle = "#{TLZL_231107_55}"
	local nXuanLingLockTime = SystemSetup : GetDoubleExp("xuanlinglocktime");
	nXuanLingLockTime = math.floor( nXuanLingLockTime / 60 );
	if nXuanLingLockTime > 0 then
		sSubTitle = sSubTitle..ScriptGlobal_Format("#{TLZL_260409_01}", nXuanLingLockTime)
		Fuli_ZhanLing2_StopBtn:Disable();
		Fuli_ZhanLing2_StartBtn:Enable();
	else
		Fuli_ZhanLing2_StartBtn:Disable();
		Fuli_ZhanLing2_StopBtn:Enable();
	end
	Fuli_ZhanLing2_StopBtn:SetToolTip(sSubTitle)
	Fuli_ZhanLing2_StartBtn:SetToolTip(sSubTitle)
end

function Fuli_ZhanLing2_XuanLingDan_OnStopClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUseVIP")
		Set_XSCRIPT_ScriptID(889644)
		Set_XSCRIPT_Parameter(0, 23)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Fuli_ZhanLing2_XuanLingDan_OnStartClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUseVIP")
		Set_XSCRIPT_ScriptID(889644)
		Set_XSCRIPT_Parameter(0, 23)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--------------其他页面------------
function Fuli_ZhanLing2_Button1_Click()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhanLing2_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end

	OpenStrongRoadDiaoWen(1)

	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhanLing2_Button3_Click()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhanLing2_Button4_Click()
	
end

function Fuli_ZhanLing2_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end
	
	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,0);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
	
	OpenZhaoHui(1)
	
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition"), 1)
end


function Fuli_ZhanLing2_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end 
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhanLing2_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhanLing2_Button9_Click()
	OpenSuperSaveUp(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhanLing2_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhanLing2_Button10_Click()
end
----------------------------------