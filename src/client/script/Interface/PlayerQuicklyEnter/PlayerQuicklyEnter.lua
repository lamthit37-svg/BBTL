-- 快捷功能入口  dujm
-----------------------------------------------------------------------------
--Notice
--客户端接口
--Lua_IsShowQuickEnterPointTip,Lua_ShowQuickEnterPointTip     动态小红点显隐
--Lua_IsShowQuickEnterPointFresh,Lua_ShowQuickEnterPointFresh 动态浮动tips显隐
--Lua_IsShowQuickEnter,Lua_ShowQuickEnter                     动态button显隐 ！！！这个默认是显示的，只有在活动时间内，有需求动态隐藏的功能才调用，不然不需要调用
--服务器接口
--LuaFnUpdateQuickEnter 		button显隐
--LuaFnUpdateQuickEnterTips 	红点显隐
--LuaFnUpdateQuickEnterFresh 	浮动tips显隐

--表动态支持多区间浮动tips(含浮动tips显隐时长)、多区间tips；支持卡级、89卡级特殊服务器的动态显隐和tips等以及Tserver显隐均不需要程序控制。
--增加新功能需要做什么？
--程序只需要在 PlayerQuicklyEnter_Clicked 函数中显示click事件即可，时间和等级不需要判断，浮动tips，按钮tips都是配表实现，如果是涉及卡级表的功能则需要告知策划卡级ID。
--如果有表不能实现的情况，那么在PlayerQuicklyEnter_Update_Self 实现即可,注意不要在update_self函数里调用上面的客户端接口函数，会造成死循环。
--Click事件的index为表中ID( ID也是XML文件里的控件后缀) 
--表ID不需要连续，目的是支持功能先后上外网的情况。
--数据定义尽量放在g_huodong中，因为后续定义多了lua会报错。
-----------------------------------------------------------------------------
local playerQuicklyEnterUI          = {}	-- UI名称
local playerQuicklyEnterAnimateBtn  = {}	-- 动态提示按钮 
local g_RedPoint                    = {}

local BkSize = {
	[1] = {39.4,47},	-- 1024x768分辨率下的frame尺寸
	[2] = {51,61},	    -- 非1024x768分辨率以上的frame尺寸
} 
local ArraySize = {
	[1] = {19.5,42},--{15.4,33.1},  -- 1024x768分辨率下的frame尺寸
	[2] = {19.5,42},--{20,43},  -- 非1024x768分辨率以上的frame尺寸
}

local nChangeSceneCount = 0
local nChangeSceneCheck = 0
local g_nScreenWidthLimit = 1024 
local g_nButtonCount = 0
local g_bIsFlex = 0 
local g_FlexTips = {} 
local g_nScreenWidth =0
local g_nScreenHeight = 0 
local g_HuoDong = {
	--周年庆
	[1] = {		
		--子功能 紫电赠英豪 
		g_ZiDianLottery_Ctrl = {}, 			--控件列表
		g_ZiDianLottery_IsStart = 0,
		g_ZiDianLottery_DownTick = 0,
		g_ZiDianLottery_IsShowTick = 0,
		g_ZiDianLottery_UpdateDownTick = 0,
		g_ZiDianLottery_FloatTips = 0,
		g_ZiDianLottery_Limit = 0,
	}, 
	--签到福利
	[2] = {		
		nCharCreateDate = 0,				-- 角色创建日期
		g_bIsNewServerGiftsForLevelUpValid = 0,
		g_bIsNewServerGiftsForLevelUpValid_2023 = 0,
	},
	--秀场
	[3] = 
	{ 
		g_xiuchang_ask_server = 0,
		g_xiuchang_ask_serverret = 0,
		g_show_tip = 0,
		g_show_tip2 = 0,
		g_xiuchang_huodong_tips = 0,
		g_zbszhibo_2016_play = 0,
		g_zbszhibo_2016_timerID = 0,
		g_MonthlySign_Tips = 0,
		g_show_tip3_1 = 0,
		g_show_tip3_2 = 0,
		g_show_tip3_timepro = 0,
		g_show_tip4_1 = 0,
		g_show_tip4_2 = 0,
		g_show_tip4_3 = 0,
		g_show_tip4_4 = 0,
		g_show_tip4_5 = 0,
		g_show_tip4_6 = 0,
		g_show_tip4_timepro = 0,
		g_show_tip5_1 = 0,
		g_show_tip5_2 = 0,
		g_show_tip5_3 = 0,
		g_show_tip5_timepro = 0, 
		g_xiuchangtips_data = {},
	},
	[4] ={
		g_YingXiong_Rp = 0,
	},
}
local g_Arrive_ServerTime_Points = {
	{day=20250908, hour=185000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 280},
	{day=20250908, hour=190000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 281},
	{day=20250911, hour=185000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 280},
	{day=20250911, hour=190000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 281},
	{day=20250915, hour=185000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 280},
	{day=20250915, hour=190000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 281},
	{day=20250919, hour=185000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 280},
	{day=20250919, hour=190000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 281},
	{day=20250922, hour=185000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 280},
	{day=20250922, hour=190000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 281},
	{day=20251017, hour=185000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 280},
	{day=20251017, hour=190000, Type='FreshManGuide', nCtlidx = 80, nGuideIdx = 281},
}
--**********************************
-- PRELOAD
--**********************************
function PlayerQuicklyEnter_PreLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD" );	-- 进入world
	this:RegisterEvent("UNIT_LEVEL");				-- 升级   
	this:RegisterEvent("HIDE_THIS_UI")				-- 隐藏界面
	this:RegisterEvent("RESET_ALLUI")				-- 返回登录界面, 重置所有UI 
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	-- 游戏分辨率发生了变化
	this:RegisterEvent("UI_COMMAND")				-- 界面 
	this:RegisterEvent("UPDATE_QUICK")				-- 按钮 
	this:RegisterEvent("UPDATE_QUICKTIPS")			-- 红点
	this:RegisterEvent("UPDATE_QUICKFRESH")			-- freshtips 
	--星阵
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("XINGZHEN_UPDATE")
	this:RegisterEvent("XINGZHEN_REMOVE_NEW")
	this:RegisterEvent("YINGXIONG_CHANGE")
	this:RegisterEvent("YINGXIONG_UPDATE")
	this:RegisterEvent("BIN_PLAYER_UPDATE_UI")
	this:RegisterEvent("GUISHI_CLUE_UPDATE")
    this:RegisterEvent("UPDATE_MISSION_TRACK");
    this:RegisterEvent("UPDATE_REDPOINT_IN_UI");
    this:RegisterEvent("UPDATE_SERVER_TIME_UI");
    this:RegisterEvent("ARRIVE_SERVER_TIMEPOINT");
    this:RegisterEvent("NOTIFY_2606S");
end

--**********************************
-- ONLOAD
--**********************************
function PlayerQuicklyEnter_OnLoad()
	--所有先重置，但是只能读到表中配置项
	local tablecount = GetPlayerQuickEnterCount()
	for i=1,tablecount do
		local ctlname = _G["PlayerQuicklyEnter_Bk"..i]
		if ctlname ~= nil then
			ctlname:Hide()
		end
	end
	--重新加载控件，因为T和原服切场景会有变化
	g_nButtonCount 	= 0 
	local g_Flex	= GetPlayerQuickEnterHide() 

	if type(g_Flex)  ~= "table" then
		return
	end
	
	g_nButtonCount = table.getn(g_Flex)
	-- BK 
	for i=1,g_nButtonCount do
		local nCtlidx = g_Flex[i].ID  

		if g_Flex[i].IsOpen == 0 and _G["PlayerQuicklyEnter_Bk"..nCtlidx] == nil then
			continue;
		end
        playerQuicklyEnterUI[nCtlidx]         =  _G["PlayerQuicklyEnter_Bk"..nCtlidx]
        playerQuicklyEnterAnimateBtn[nCtlidx] =  _G["PlayerQuicklyEnter_Image"..nCtlidx]
		g_RedPoint[nCtlidx] 				  =  _G[string.format("PlayerQuicklyEnter_Image%d_Tips",nCtlidx)]   
		assert(playerQuicklyEnterUI[nCtlidx] ~= nil)
		assert(playerQuicklyEnterAnimateBtn[nCtlidx] ~= nil)
		assert(g_RedPoint[nCtlidx] ~= nil) 
		playerQuicklyEnterUI[nCtlidx]:Hide()
	end  
	
	--紫电赠英豪
	g_HuoDong[1].g_ZiDianLottery_Ctrl = {
		m_DownTickWatch = PlayerQuicklyEnter_Image5_Time_Text, 
		m_DownTickText = PlayerQuicklyEnter_Image5_Text, 
	}
	DataPool:Lua_ArriveServerTime_Clear()
	for i, v in g_Arrive_ServerTime_Points do
		DataPool:Lua_ArriveServerTime_Add(v.day, v.hour, "")
	end
end

--**********************************
-- ONEvent
--**********************************
function PlayerQuicklyEnter_OnEvent( event )
 
	if IsZbs2018SpeicalServer() >= 1 then
		this:Hide()
		return
	end

	if IsDfsSpeicalServer() >= 1 then
		this:Hide()
		return
	end

	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end

	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end

	-- 切换场景特殊处理
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		PlayerQuicklyEnter_OnLoad()
		-- 解决按钮切场景闪烁问题
		nChangeSceneCount = nChangeSceneCount + 1
		if ( nChangeSceneCount <= 1 ) then
			g_bIsFlex = 0  
			PlayerQuicklyEnter_UpdateUI()
		end
	elseif ( event == "HIDE_THIS_UI" ) then
		if this:IsVisible() then
			this:Hide() 
		end 
	elseif ( event == "RESET_ALLUI" ) then 
		CloseFreshManGuide_PlayerQuick()  
		-- 关闭所有按钮的闪烁
		for	i = 1, table.getn( g_RedPoint ) do
			g_RedPoint[i]:Hide()
		end 
		for i,value in pairs(playerQuicklyEnterUI) do
			if value ~= nil then 
				value:Hide() 
			end
		end
		this:Hide() 
	elseif event == "UNIT_LEVEL" then  
		PlayerQuicklyEnter_UpdateUI()
	elseif event == "UPDATE_QUICK" then  
		PlayerQuicklyEnter_UpdateUI()
	elseif event == "UPDATE_QUICKTIPS" then 
		PlayerQuicklyEnter_UpdateUI()
	elseif event == "UPDATE_QUICKFRESH" then 
		PlayerQuicklyEnter_UpdateUI()
	elseif ( event == "UPDATE_SERVER_TIME_UI" ) then
		PlayerQuicklyEnter_UpdateUI() 
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then  
		g_nScreenWidth = tonumber(arg1)/10000;					--width为游戏屏幕宽度
		g_nScreenHeight = math.mod( tonumber(arg1), 10000 );		--height为游戏屏幕宽度
		g_nScreenWidth = math.floor( g_nScreenWidth );
		g_nScreenHeight = math.floor( g_nScreenHeight );
		PlayerQuicklyEnter_UpdateUI() 
	elseif event == "XINGZHEN_UPDATE" or event == "XINGZHEN_REMOVE_NEW" or event == "YINGXIONG_CHANGE" or event == "YINGXIONG_UPDATE" then
		PlayerQuicklyEnter_UpdateXingZhen()
	elseif event == "YINGXIONG_REDPOINT" then 
		if tonumber(arg0)==1 or tonumber(arg1)==1 or tonumber(arg2) == 1 then 
			g_HuoDong[4].g_YingXiong_Rp = 1 
		else  
			g_HuoDong[4].g_YingXiong_Rp = 0
		end
		PlayerQuicklyEnter_UpdateXingZhen()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 50603605 ) then
		g_HuoDong[1].g_ZiDianLottery_IsStart = Get_XParam_INT( 0 );		--是否开始的标志
		g_HuoDong[1].g_ZiDianLottery_DownTick = Get_XParam_INT( 1 );		--倒计时时间
		g_HuoDong[1].g_ZiDianLottery_IsShowTick = Get_XParam_INT( 2 );
		g_HuoDong[1].g_ZiDianLottery_Limit = Get_XParam_INT( 3 );
		g_HuoDong[1].g_ZiDianLottery_UpdateDownTick = 1;	
		PlayerQuicklyEnter_UpdateZhounianqing()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 20260107 ) then
		PlayerQuicklyEnter_VIP()
	elseif (event == "GUISHI_CLUE_UPDATE" ) then
		PlayerQuicklyEnter_GuiShiButtonRedPoint()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89319401 ) then
		local opType = Get_XParam_INT(0)
		local animDayData = Get_XParam_INT(1)
		if opType == 1 and (this:IsVisible()) then
			PlayerQuicklyEnter_UpdateGuiShiButtonAnimation(1)
			PlayerQuicklyEnter_GuiShiButtonRedPoint()
		elseif opType == 2 and (this:IsVisible()) then
			PlayerQuicklyEnter_MenKeAnimate_GetData(animDayData)
		end 
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then 
		g_HuoDong[2].nCharCreateDate = Get_XParam_INT( 8 );
		g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
		g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid_2023 = 0
		PlayerQuicklyEnter_UpdateUI()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) ==  99847904 ) then 
		g_HuoDong[2].nCharCreateDate = Get_XParam_INT( 0 );
		g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid = 0
		g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid_2023 = Get_XParam_INT( 1 );  
		PlayerQuicklyEnter_UpdateUI()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 50603603 ) then 
		g_HuoDong[1].g_ZiDianLottery_FloatTips = Get_XParam_INT( 0 );
		PlayerQuicklyEnter_UpdateFresh()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89319405 ) then 
		PlayerQuicklyEnter_GuiShiButtonRedPoint()
	elseif ( event == "UPDATE_MISSION_TRACK" ) then 
		PlayerQuicklyEnter_UpdateGuiShiButtonAnimation(2)
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 889962) then
		g_HuoDong[3].g_xiuchang_ask_server = 1
		g_HuoDong[3].g_xiuchang_ask_serverret = Get_XParam_INT(0)
		g_HuoDong[3].g_show_tip = Get_XParam_INT(1)
		g_HuoDong[3].g_show_tip2 = Get_XParam_INT(2)
		PlayerQuicklyEnter_UpdateXiuChang()   
	elseif event == "UPDATE_REDPOINT_IN_UI" then 
		PlayerQuicklyEnter_Update_MonthSign()   
	elseif event == "ARRIVE_SERVER_TIMEPOINT" then 
		PlayerQuicklyEnter_ArriveTimePoint(arg0, arg2, arg3)
	elseif event == "NOTIFY_2606S" then    
		PlayerQuicklyEnter_UpdateUI() 
	end
end
  
--**********************************
-- UI布局更新
--**********************************
function PlayerQuicklyEnter_UpdateUI() 
	
	--先判定一下游戏是否在主流程，并且自己是否有效
	if(Player:IsVaild() ~= 1 ) then
		return
	end 
	PlayerQuicklyEnter_OnLoad()

	if g_bIsFlex == 1 then
		PlayerQuicklyEnter_Open:Show()
		PlayerQuicklyEnter_Close:Hide()
	else
		PlayerQuicklyEnter_Open:Hide()
		PlayerQuicklyEnter_Close:Show()
	end 

	--打开按钮Tips
	PlayerQuicklyEnter_OpenButton_Tips:Hide() 
	

	local g_Flex	= GetPlayerQuickEnterHide()
	if type(g_Flex) ~= "table" then
		return
	end  
	g_nButtonCount = table.getn(g_Flex)

	for i = 1,g_nButtonCount do
		g_FlexTips[i] = ""
	end 
	for index, value in ipairs(g_Flex) do
		local nCtlidx = value.ID 
		if g_bIsFlex == 1 and value.IsOpen == 1 and value.CanHide == 1 and value.FlashOnHide == 1 and Lua_IsShowQuickEnterPointTip(nCtlidx) == 1 and
			value.IsShow == 1 and Lua_IsShowQuickEnter(nCtlidx) == 1 then
			PlayerQuicklyEnter_OpenButton_Tips:Show() 
			if value.TipsOnHide == 1 and value.TipsPriority > 0 then
				g_FlexTips[value.TipsPriority] = value.HideTipsStr
			end 
		end
	end 
	local OpenTips = "" 
	for i = 1,g_nButtonCount do
		if g_FlexTips[i] ~= "" then
			OpenTips = OpenTips..g_FlexTips[i]
			break
		end
	end 

	if string.len(OpenTips) <= 0 then
		OpenTips = "#{YCAN_150114_2}"
	end

	PlayerQuicklyEnter_OpenButton:SetToolTip(OpenTips) 

	--设置各个功能坐标
	PlayerQuicklyEnter_UpdateUIPos()
	
	--如果表不满足，那么在自定义中添加
	PlayerQuicklyEnter_Update_Self()
	
	if g_nButtonCount > 0 then
		this:Show();
	end
	
end
 
--**********************************
-- UI位置
--**********************************
function PlayerQuicklyEnter_UpdateUIPos() 
	PlayerQuicklyEnter_OnLoad()
	
	local g_Flex	= GetPlayerQuickEnterHide()
	if type(g_Flex) ~= "table" then
		return
	end  

	g_nButtonCount = table.getn(g_Flex)
	local nNextIndex = g_nButtonCount 
	local nSizeIndex = 1
	if ( g_nScreenWidth <= g_nScreenWidthLimit ) then
		nSizeIndex = 1
	else
		nSizeIndex = 2
	end

	local nMinimapWidth
	if 1 == SystemSetup:IsClassic() then
    	nMinimapWidth = 251
    else
    	nMinimapWidth = 278
    end

	-- Frame
	PlayerQuicklyEnter_Frame:SetProperty( "UnifiedPosition", "{{1.000000, "..tostring(-1 * ( nNextIndex + 1 ) * BkSize[nSizeIndex][1] - nMinimapWidth).."},{0.000000,3}}" )
	PlayerQuicklyEnter_Frame:SetProperty( "AbsoluteSize", "w:"..( nNextIndex + 1 ) * BkSize[nSizeIndex][1].." h:"..BkSize[nSizeIndex][2].."" )

	PlayerQuicklyEnter_Open:SetProperty( "UnifiedPosition", "{{0.000000,"..nNextIndex * BkSize[nSizeIndex][1].."},{0.000000,0}}" )
	PlayerQuicklyEnter_Open:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )
	PlayerQuicklyEnter_OpenButton:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )
	PlayerQuicklyEnter_Close:SetProperty( "UnifiedPosition", "{{0.000000,"..nNextIndex * BkSize[nSizeIndex][1].."},{0.000000,0}}" )
	PlayerQuicklyEnter_Close:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )
	PlayerQuicklyEnter_CloseButton:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )

	
	for i = 1, g_nButtonCount do
		local nCtlidx = g_Flex[i].ID 
		if g_Flex[i].IsOpen == 0 then
			if playerQuicklyEnterUI[nCtlidx] ~= nil then
				playerQuicklyEnterUI[nCtlidx]:Hide()
			end
			continue
		end 
		
		local isshow = 	g_Flex[i].IsShow	
		local IsShowQuickEnter =  Lua_IsShowQuickEnter(nCtlidx) 

		--控件显隐
		if g_Flex[i].IsShow == 1 and (g_bIsFlex == 0 or (g_bIsFlex == 1 and (g_Flex[i].CanHide == 0))) and Lua_IsShowQuickEnter(nCtlidx) == 1 then
			nNextIndex = nNextIndex - 1
			-- BK
			playerQuicklyEnterUI[nCtlidx]:Show()
			local fx, fy = this:GetChildOffset("PlayerQuicklyEnter_Bk"..nCtlidx); 
			Lua_SetQuickEnterOffSet(nCtlidx, fx + 12, fy + 45)
			playerQuicklyEnterUI[nCtlidx]:SetProperty( "UnifiedPosition", "{{0.000000,"..nNextIndex * BkSize[nSizeIndex][1].."},{0.000000,0}}" )
			playerQuicklyEnterUI[nCtlidx]:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )
			
			-- Image
			playerQuicklyEnterAnimateBtn[nCtlidx]:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )
			playerQuicklyEnterAnimateBtn[nCtlidx]:SetToolTip(g_Flex[i].TipsStr) 
			
		else
			playerQuicklyEnterUI[nCtlidx]:Hide()
		end  
		--红点显隐
		if Lua_IsShowQuickEnterPointTip(nCtlidx) >= 1 and playerQuicklyEnterUI[nCtlidx]:IsVisible() then
			g_RedPoint[nCtlidx]:Show()
		elseif Lua_IsShowQuickEnterPointTip(nCtlidx) == 0 then
			g_RedPoint[nCtlidx]:Hide()
		end  
		--fresh显隐
		if Lua_IsShowQuickEnterPointFresh(nCtlidx) >= 1 and playerQuicklyEnterUI[nCtlidx]:IsVisible() then  
			local fx, fy = this:GetChildOffset("PlayerQuicklyEnter_Bk"..nCtlidx);  
			if g_Flex[i].FreshFlash > 0 then 
				OpenFreshManGuide_PlayerQuick( 3, nCtlidx, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			end			
			Lua_ShowQuickEnterPointFresh(nCtlidx, 0)
		end 

	end	 
end 

function PlayerQuicklyEnter_Open_Clicked()
	g_bIsFlex = 0 
	PushEvent( "CLOSE_FRESHMAN_GUIDE_PLAYERQUICK" );
	PlayerQuicklyEnter_UpdateUI()  --所有按钮都在此处更新
end

function PlayerQuicklyEnter_Close_Clicked() 
	g_bIsFlex = 1
	PushEvent( "CLOSE_FRESHMAN_GUIDE_PLAYERQUICK" );
	PlayerQuicklyEnter_UpdateUI()  
end


--如果有需要自定义刷新的地方
function PlayerQuicklyEnter_Update_Self()
	PlayerQuicklyEnter_GuiShiButtonRedPoint()

	-- 嘉年华直播
	PlayerQuicklyEnter_JNHZHIBOMouseEnter()
	-- 嘉年华直播
	PlayerQuicklyEnter_Update_ActivityShedule()
end

--**********************************
-- 按钮事件
--**********************************
function PlayerQuicklyEnter_Clicked( nIndex )
	local nChk = PlayerQuickEnterClickCheck(nIndex)
	if  nChk == nil or nChk == 0 then
		PlayerQuicklyEnter_UpdateUI()
		return
	end	

	--活动日程
	if ( nIndex == 1 ) then 
		PlayerQuicklyEnter_ActivityShedule() 
	--vip特权
	elseif( nIndex == 2) then
		PlayerQuicklyEnter_VIP()
	--武林风云录
	elseif( nIndex == 3) then
		PlayerQuicklyEnter_WuLinFengYunLu()
	--扫荡
	elseif( nIndex == 4) then
		PlayerQuicklyEnter_OpenSecKillBox()
	--周年庆
	elseif( nIndex == 5) then
		PlayerQuicklyEnter_OpenZhounianqing()
	--新服欢乐月
	elseif( nIndex == 6) then
		PlayerQuicklyEnter_OpenXinFuYue() 
	--签到福利
	elseif( nIndex == 7) then
		PlayerQuicklyEnter_OpenQianDaoFuLi()
	elseif( nIndex == 8) then
		PlayerQuicklyEnter_OpenSummerVacation()
	--秀场直播
	-- elseif( nIndex == 9) then
	-- 	PlayerQuicklyEnter_OpenXiuchang()
	--九九消寒
	elseif( nIndex == 10) then
		PlayerQuicklyEnter_OpenJiuJiuXiaoHan()
	--清凉盛夏
	elseif( nIndex == 11) then
		PlayerQuicklyEnter_OpenJiuJiuXiaoHan_Summer()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AddYongYanLog" )
			Set_XSCRIPT_ScriptID( 892473)
			Set_XSCRIPT_Parameter( 0, 4 )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	--节日活动
	elseif( nIndex == 12) then
		PlayerQuicklyEnter_OpenJieRiHuoDong()
	--贺新春
	elseif( nIndex == 13) then
		PlayerQuicklyEnter_OpenHeXinChun()
	--感恩节抽奖
	elseif( nIndex == 14) then
		PlayerQuicklyEnter_OpenThanks()
	--感恩节抽奖
	elseif( nIndex == 15) then
		PlayerQuicklyEnter_OpenSpringGuideMission()
	--感恩节抽奖
	elseif ( nIndex == 16) then
		PlayerQuicklyEnter_OpenDuanWu()	
	--七夕整合界面
	elseif ( nIndex == 17) then
		PlayerQuicklyEnter_OpenQiXi()	
	--中秋整合界面
	elseif ( nIndex == 18) then
		PlayerQuicklyEnter_OpenZhongQiu()	
	--国庆整合界面
	elseif ( nIndex == 19) then
		PlayerQuicklyEnter_Open2019National()	
	--结伴同行
	elseif ( nIndex == 20) then
		PlayerQuicklyEnter_OpenJiebanHuiliu()	
	--鬼市
	elseif ( nIndex == 21) then
		PlayerQuicklyEnter_OpenGuiShi()
	--嘉年华直播
	elseif ( nIndex == 22) then
		PlayerQuicklyEnter_OpenJNHZB()	
	--无字谱
	elseif ( nIndex == 23) then
        PlayerQuicklyEnter_OpenXingZhen() 
	--西瓜节
	elseif ( nIndex == 24) then 
		PlayerQuicklyEnter_OpenXiGuaJie()	
	--金枫季
	elseif ( nIndex == 25) then  
		PlayerQuicklyEnter_Open2020JinFeng()
	--琼珍阁
	elseif ( nIndex == 26) then   
		PlayerQuicklyEnter_LaShouShop()
	--双旦整合
	elseif ( nIndex == 27) then   
		PlayerQuicklyEnter_ShuangDanCliked()
	--春节预热
	elseif ( nIndex == 28) then    
		PlayerQuicklyEnter_Open2021SpringWarmUp()
	--花朝节预热
	elseif ( nIndex == 29) then
		PlayerQuicklyEnter_HZJCliked()
	--绝情谷扶持
	elseif ( nIndex == 30) then
		PlayerQuicklyEnter_GuanHuaiJueQingGuCliked() 
	--花朝节整合
	elseif ( nIndex == 31) then 
		PlayerQuicklyEnter_HuaZhaoJieCliked()
	--周年预热签到
	elseif ( nIndex == 32) then 
		PlayerQuicklyEnter_ZNSignCliked()
	--节奏服
	elseif ( nIndex == 33) then 
		PlayerQuicklyEnter_TeSeServerCliked()
	--清明节抽奖2022
	elseif ( nIndex == 34) then 
		PlayerQuicklyEnter_Open2019Qingming()
	--风曳清荷
	elseif ( nIndex == 35) then 
		PlayerQuicklyEnter_ChildrensDayMainCliked()
	--新手战令
	elseif ( nIndex == 36) then 
		PlayerQuicklyEnter_XinShouZhanLingCliked()
	--七日签到
	elseif ( nIndex == 37) then 
		PlayerQuicklyEnter_7DaysSignCliked()
	--繁花会宴
	elseif ( nIndex == 38) then 
		PlayerQuicklyEnter_202208FGHYCliked()
	--新天外活动整合
	elseif ( nIndex == 39) then 
		PlayerQuicklyEnter_NewTianWaiCliked()
	--新天外预热
	elseif ( nIndex == 40) then 
		PlayerQuicklyEnter_2022Q3NewTWYRCliked()	
	--情人节
	elseif ( nIndex == 41) then 
		PlayerQuicklyEnter_2023ValentineCliked()
	--春风送暖	
	elseif ( nIndex == 42) then 
		PlayerQuicklyEnter_JJXHSpringCliked()	
	--新服整合
	elseif ( nIndex == 43) then 
		PlayerQuicklyEnter_XinFuZhengHeCliked()
	--帮会活跃
	elseif ( nIndex == 44) then 
		PlayerQuicklyEnter_BangHuiHuoYueCliked()
	--青梅煮酒
	elseif ( nIndex == 45) then
		PlayerQuicklyEnter_QingMeiZhuJiuCliked()
	--备忘录
	elseif ( nIndex == 46) then
		Lua_OpenMemo()
	--周年情怀任务
	elseif ( nIndex == 47) then
		PlayerQuicklyEnter_2023Anniversary_Cliked()
	elseif ( nIndex == 48) then
		PlayerQuicklyEnter_2023ShengJingFanHui_Cliked()
	elseif (nIndex == 49) then
		-- 城战奖励升级
		PlayerQuicklyEnter_ChengZhanJiangLiShengJi_Cliked()
	elseif ( nIndex == 50) then--宗门预热活动
		PlayerQuicklyEnter_ZongMenYuRe_Cliked()
	elseif (nIndex == 51) then
		PlayerQuicklyEnter_ZongMenActivity_Cliked()
	elseif (nIndex == 52) then
		PlayerQuicklyEnter_QuanMin8Xing_Cliked()
	elseif (nIndex == 53) then
		PlayerQuicklyEnter_2023XiGuaShop_Cliked()
	elseif (nIndex == 54) then
		PlayerQuicklyEnter_New_Monthcard_Cliked()
	elseif (nIndex == 55) then
		PlayerQuicklyEnter_WinterShop_Cliked()
	--2024周年庆预热活动设计
	elseif (nIndex == 56) then
		PlayerQuicklyEnter_2024ZNQYR_Cliked()		
	elseif (nIndex == 57) then	
		--大话预热
		PlayerQuicklyEnter_24Q2DHXY_YURE_Cliked()		
	elseif (nIndex == 58) then
		PlayerQuicklyEnter_2024PreActivity_Cliked()
	elseif (nIndex == 59) then--24Q2大话西游整合
		PlayerQuicklyEnter_24Q2DHXY_Cliked()	
	elseif (nIndex == 60) then
		PlayerQuicklyEnter_ShuangYe_Cliked()
	elseif (nIndex == 61) then
		PlayerQuicklyEnter_SBHZ_Cliked()
	elseif (nIndex == 62) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUI")
		Set_XSCRIPT_ScriptID(999391)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (nIndex == 63) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenDailyShop")
			Set_XSCRIPT_ScriptID(999360)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (nIndex == 64) then-- 2024Q3版本稳活活动
		PlayerQuicklyEnter_24Q3WenHuo_Cliked()
	elseif (nIndex == 65) then
		PlayerQuicklyEnter_ForceLevel_Click()
	elseif (nIndex == 66) then -- 2024Q4冰雪节预热
		PlayerQuicklyEnter_BingXueJie_Yr_Click()
	elseif (nIndex == 67) then -- 2024Q4冰雪节整合
		PlayerQuicklyEnter_BingXueJie_Guide_Click()
	elseif (nIndex == 68) then -- 人脸验证防沉迷界面
		PlayerQuicklyEnter_FaceAuth_FangChengMi_Click()
	elseif (nIndex == 69) then -- 冬季开船
		PlayerQuicklyEnter_DongJiChouJiang_Click()
	elseif (nIndex == 70) then -- 红包服
		PlayerQuicklyEnter_NewServerHongBao_Click()
	elseif (nIndex == 71) then -- 侠客行
		PlayerQuicklyEnter_XiaKeXing_Click()
	elseif (nIndex == 72) then --2025周年庆预热活动
		PlayerQuicklyEnter_2025ZNQYR_Click()		
	elseif (nIndex == 73) then
		PlayerQuicklyEnter_DaFuWeng_Click()
	elseif (nIndex == 74) then --2025时装返场
		PlayerQuicklyEnter_2025ZNSZ_Click()	
	elseif (nIndex == 75) then --2025端午预热
		PlayerQuicklyEnter_2025DuanWuYuRe_Click()
	elseif (nIndex == 76) then --2025新服社交
		PlayerQuicklyEnter_2025XinFuSheJiao_Click()
	elseif (nIndex == 77 )  then	--七夕画卷
		PlayerQuicklyEnter_2025QiXiHuaJuan_Click()
	elseif (nIndex == 78 )  then	--宗门版本活动
		PlayerQuicklyEnter_LevelEx_Yindao_Click()	
	elseif (nIndex == 79 )  then	--宗门版本活动
		PlayerQuicklyEnter_ZongMenActivity_Click()
	elseif (nIndex == 80 )  then	--争霸赛直播
		PlayerQuicklyEnter_OpenZBS_Click()
	elseif (nIndex == 81 )  then
		PlayerQuicklyEnter_OpenStealSkillGuide()
	elseif (nIndex == 82 )  then	
		PlayerQuicklyEnter_NewYuanDan_Click()	
	elseif (nIndex == 83 )  then	-- 夏日拉收战令系统
		PlayerQuicklyEnter_OpenSummerZhanLing()
	elseif (nIndex == 84 )  then	-- 新月卡---季卡
		PlayerQuicklyEnter_New_Monthcard_Cliked()
	elseif (nIndex == 85 )  then	-- 2026年风云预热
		PlayerQuicklyEnter_FY_YuRe_Cliked()
	elseif (nIndex == 86 )  then
		PlayerQuicklyEnter_WindAndCloudGuide_Cliked()
	elseif (nIndex == 87 )  then --2026砸金蛋
		PlayerQuicklyEnter_ZaJinDanCliked()	
	elseif (nIndex == 88 ) then		--2026武神坛整合界面
		PlayerQuicklyEnter_WSTG_Cliked()
	elseif (nIndex == 89 ) then		--七夕整合界面
		PlayerQuicklyEnter_QiXi_Cliked()
	elseif (nIndex == 90 )  then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenQiXiYuReUI")
			Set_XSCRIPT_ScriptID(900052)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (nIndex == 91 )  then	
		PlayerQuicklyEnter_2026_QiXi_Cliked() --2026七夕剧情副本任务					
	else
		return
	end
end

function PlayerQuicklyEnter_ActivityShedule()
	-- 打开UI
	OpenTodayCampaignList();
end

--**********************************
-- 打开VIP特权
--**********************************
function PlayerQuicklyEnter_VIP() 
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end 
	-- 地府不能打开
	local isInHell = IsInHell()
	if isInHell == 1 then
		return
	end 
	-- VIP等级
	local vipLevel = DataPool:GetAccVipLevel();
	if ( vipLevel >= 1 ) then 
		--打开Shop
		PushEvent( "OPEN_VIP_SHOP", vipLevel, 1 );
	elseif ( vipLevel == 0 ) then 
		local bReAsk = DataPool:SendAskVipInfoMsg();
		if bReAsk == nil or bReAsk == 0 then
			-- 打开引导界面
			PushEvent( "OPEN_VIP_NEXTLEVEL" );
		end
		return
	end  
end

--**********************************
-- 打开武林风云录
--**********************************
function PlayerQuicklyEnter_WuLinFengYunLu()

	-- 打开UI
	local menpai = Player : GetData( "MEMPAI" );		--获取玩家门派ID
	if ( menpai < 0 or menpai > 15 or menpai == 9 ) then--menpai15 mptodo
		PushDebugMessage( "#{JDZY_120806_875}" );
		return
	end
	Lua_ToggleFengyunlu();
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnClientBnClicked" );	-- 脚本入口
		Set_XSCRIPT_ScriptID( 290099 )						-- 脚本ID
		Set_XSCRIPT_ParamCount( 0 )							-- 参数个数
	Send_XSCRIPT()

end

--**********************************
-- 打开副本扫荡钮
--**********************************
function PlayerQuicklyEnter_OpenSecKillBox()

	if ( IsWindowShow( "SweepAll" ) ) then
		CloseWindow( "SweepAll", true );
		return
	end 
	-- 打开UI
	OpenSecKillList();
end

--**********************************
-- 周年庆UI
--**********************************
function PlayerQuicklyEnter_UpdateZhounianqing() 

	if 1~=1 and g_HuoDong[1].g_ZiDianLottery_UpdateDownTick == 1 then
		g_HuoDong[1].g_ZiDianLottery_UpdateDownTick = 0
		g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickText:Show()
		g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickWatch:Hide();
		if g_HuoDong[1].g_ZiDianLottery_IsStart == 0 then	--未开始
			--g_ZiDianLottery_Ctrl.m_DownTickText:SetText("#{ZDZYH_151012_27}");
			g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickText:Hide();
			g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickWatch:Hide();
		elseif g_HuoDong[1].g_ZiDianLottery_IsStart == 1 then	--时间数字
			g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickWatch:Show();
			g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickText:Hide();
			g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickWatch:Hide(); --SetProperty("Timer",tostring(g_HuoDong[1].g_ZiDianLottery_DownTick));
		elseif g_HuoDong[1].g_ZiDianLottery_IsStart == 2 then	--倒计时结束
			if g_HuoDong[1].g_ZiDianLottery_DownTick >= g_HuoDong[1].g_ZiDianLottery_Limit then	--可领奖
				g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickText:SetText( "#{ZDZYH_151012_29}");
			else	--已过期
				g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickText:SetText( "#{ZDZYH_151012_28}");
			end
		elseif g_HuoDong[1].g_ZiDianLottery_IsStart == 3 then	--已领奖 
			g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickText:Hide();
			g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickWatch:Hide();
		end
	end

	if g_HuoDong[1].g_ZiDianLottery_IsShowTick == 0 then
		g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickText:Hide();
		g_HuoDong[1].g_ZiDianLottery_Ctrl.m_DownTickWatch:Hide();
	end
end

--**********************************
-- 打开周年庆界面
--**********************************
function PlayerQuicklyEnter_OpenZhounianqing( nIndex )
	if(IsWindowShow("Anniversary")) then
		CloseWindow("Anniversary", true)
	end
	if(IsWindowShow("Anniversary")) then
		CloseWindow("Anniversary", true)
	end
	local level = Player:GetData("LEVEL");
	if level < 30 then
		PushDebugMessage("#{SEZN_190326_8}");
		return;
	end
	PushEvent( "OPEN_ANNIVERSARY_BEFORE" )
end

--**********************************
-- 打开新服欢乐月
--**********************************
function PlayerQuicklyEnter_OpenXinFuYue( )
	if(IsWindowShow("ServerNew")) then
		CloseWindow("ServerNew", true)
		return
	end

	--在K服不显示新服欢乐月界面
	if KVKInterface:IsInKVKServer() == 1 then
		PushDebugMessage("#{XFHD_140919_16}")
		return
	end

	--在T服也不显示新服欢乐月界面
	if IsInTServer() == 1 then
		PushDebugMessage("#{XFHD_140919_17}")
		return
	end
	-- 打开引导界面
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenXinFuHuanLeYue" )
		Set_XSCRIPT_ScriptID( 890933 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--**********************************
-- 签到福利打开
--**********************************
function PlayerQuicklyEnter_OpenQianDaoFuLi()

	--如果界面打开了 就关闭界面
	if(IsWindowShow("Fuli_MonthlySign")) then
		CloseWindow("Fuli_MonthlySign", true);
		return
	end

	if(IsWindowShow("Fuli_QiankunBag")) then
		CloseWindow("Fuli_QiankunBag", true);
		return
	end

	if(IsWindowShow("Fuli_StrongRoad_DiaoWen")) then
		CloseWindow("Fuli_StrongRoad_DiaoWen", true);
		return
	end

	if(IsWindowShow("MonthlySignSP")) then
		CloseWindow("MonthlySignSP", true);
		return
	end

	if(IsWindowShow("StrongRoadSP_DiaoWen")) then
		CloseWindow("StrongRoadSP_DiaoWen", true);
		return
	end

	if(IsWindowShow("QiankunBagSP")) then
		CloseWindow("QiankunBagSP", true);
		return
	end

	if(IsWindowShow("Fuli_Dailyburden")) then
		CloseWindow("Fuli_Dailyburden", true);
		return
	end

	if(IsWindowShow("DailyburdenSP")) then
		CloseWindow("DailyburdenSP", true);
		return
	end

	if(IsWindowShow("Fuli_ZhanLing")) then
		CloseWindow("Fuli_ZhanLing", true);
		return
	end

	local curDay = tonumber(DataPool:GetServerDayTime());
	-- 等级
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		--打开升级界面
		if ( g_HuoDong[2].nCharCreateDate < 904691712 ) or (g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid == 1 or g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid_2023 == 1) then
			PushDebugMessage("#{FLRK_160608_11}") 
			return
		end 
		OpenQianKunDai(0) 
	elseif ( nLevel >= 15 ) then
		--打开每月签到界面
		if(IsWindowShow("MonthlySign")) then
			CloseWindow("MonthlySign", true)
			return
		end 
		OpenMonthlySign(0)
	end  
end
--**********************************
-- 打开春暖迎新活动界面
--**********************************
function PlayerQuicklyEnter_OpenSummerVacation()

	if(IsWindowShow("SummerVacation")) then
		CloseWindow("SummerVacation", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskPrizeUI")
		Set_XSCRIPT_ScriptID(891205)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	PushEvent("CLOSE_FRESHMAN_GUIDE");

end

--**********************************
-- 打开秀场直播界面
--**********************************
-- function PlayerQuicklyEnter_OpenXiuchang()

-- 	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
-- 		CloseFreshManGuide() 
-- 	end
-- 	CloseFreshManGuide_PlayerQuick()
-- 	if Player:GetLevel() < 15 then
-- 		PushDebugMessage("#{XCZB_160105_1}");
-- 		return
-- 	end
	
-- 	-- 打开秀场
-- 	OpenXiuChang()
-- end

function PlayerQuicklyEnter_OpenJiuJiuXiaoHan()

	if KaJi:LuaFnIsKaJiServer() == 1 then
		return
	end

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide() 
	end 

	CloseFreshManGuide_PlayerQuick()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(892394)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


function PlayerQuicklyEnter_OpenJiuJiuXiaoHan_Summer()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
	if(IsWindowShow("JiuJiuXiaoHan_Summer")) then
		CloseWindow("JiuJiuXiaoHan_Summer", true)
		return
	end 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(892456)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function PlayerQuicklyEnter_OpenJieRiHuoDong()
	if(IsWindowShow("JieRiHuoDong")) then
		CloseWindow("JieRiHuoDong", true)
		return
	end
	PushEvent("JIERIHUODONG_OPEN", 1)
end

function PlayerQuicklyEnter_OpenHeXinChun()
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel(); 
	if(curDay >= 20260216 and curDay <= 20260223) then
		PushEvent("OPEN_HEXINCHUN",1,-1,-1)
		return
	end
	if(curDay >= 20260224 and curDay <= 20260303) then
		PushEvent("OPEN_ZHANJIANGHU",1,-1,-1)
		return
	end
	PushDebugMessage("#{CJYJ_180104_87}") 
end

--2018感恩节抽奖
function PlayerQuicklyEnter_OpenThanks()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(892831)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--2018Q4春节引导任务总界面
function PlayerQuicklyEnter_OpenSpringGuideMission()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
	if(IsWindowShow("SpringFestival_Get")) then
		CloseWindow("SpringFestival_Get", true)
		return
	end
	if(IsWindowShow("SpringFestival_Guide")) then
		CloseWindow("SpringFestival_Guide", true)
		return
	end
	if(IsWindowShow("SpringFestival2_Guide")) then
		CloseWindow("SpringFestival2_Guide", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenSpringGuideMission" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0,0) --默认根据当前时间打开对应分页
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

--2019 端午节
function PlayerQuicklyEnter_OpenDuanWu()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenDuanWu")
		Set_XSCRIPT_ScriptID(893117)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


--2019七夕
function PlayerQuicklyEnter_OpenQiXi()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenQiXi")
		Set_XSCRIPT_ScriptID(893128)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end


--2019 中秋
function PlayerQuicklyEnter_OpenZhongQiu()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnOpenMainUI")
	Set_XSCRIPT_ScriptID(790015)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--2019国庆系列
function PlayerQuicklyEnter_Open2019National()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenNatiaonal2019")
		Set_XSCRIPT_ScriptID(893157)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--2019Q3 回流
function PlayerQuicklyEnter_OpenJiebanHuiliu()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	if(IsWindowShow("JieBan_Partner")) then
		CloseWindow("JieBan_Partner", true);
		return
	end

	if(IsWindowShow("ReturnPrivilege")) then
		CloseWindow("ReturnPrivilege", true);
		return
	end

	if(IsWindowShow("JieBan_Mission")) then
		CloseWindow("JieBan_Mission", true);
		return
	end

	if(IsWindowShow("JieBan_Shop")) then
		CloseWindow("JieBan_Shop", true);
		return
	end
	 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenHuiliuUI")
		Set_XSCRIPT_ScriptID(893195)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end
 
--嘉年华直播 鼠标划入
function PlayerQuicklyEnter_JNHZHIBOMouseEnter()
	local curDay = tonumber(DataPool:GetServerDayTime());
	local serverMinute = tonumber(DataPool:GetServerMinuteTime())
	local curHour = math.floor(serverMinute/10000)
	if curDay == 20251018 and serverMinute < 183000 then
		PlayerQuicklyEnter_Image22:SetToolTip("#{JLHZB_230915_01}")
	elseif curDay == 20251018 and serverMinute >= 183000 and serverMinute <= 213000 then
		PlayerQuicklyEnter_Image22:SetToolTip("#{JLHZB_230915_02}")
	elseif curDay == 20251018 and serverMinute > 213000 then
		PlayerQuicklyEnter_Image22:SetToolTip("#{JLHZB_230915_03}")
	else
	end
end

--争霸赛直播 鼠标划入
function PlayerQuicklyEnter_JBSLiveMouseEnter()
	local curDay = tonumber(DataPool:GetServerDayTime());
	local serverMinute = tonumber(DataPool:GetServerMinuteTime())
	local curHour = math.floor(serverMinute/10000)
	if curDay < 20250904 or curDay > 20251017 then
		-- 不在活动时间范围内
		return 
	end
	for _, day in {20250908, 20250911, 20250915, 20250919, 20250922, 20251017} do
		if curDay == day then
			if serverMinute >= 185000 and serverMinute < 190000 then
				-- 争霸赛比赛即将开始，请点击按钮观看赛事直播。
				PlayerQuicklyEnter_Image80:SetToolTip("#{ZBZB_250902_02}")
				return
			elseif serverMinute >= 190000 then
				-- 点击前往观看天龙全球争霸赛现场直播。
				PlayerQuicklyEnter_Image80:SetToolTip("#{ZBZB_250902_03}")
				return
			end
		end
	end
	-- 点击前往天龙全球争霸赛赛事主页。
	PlayerQuicklyEnter_Image80:SetToolTip("#{ZBZB_250902_01}")
	return
end

function PlayerQuicklyEnter_OpenJNHZB()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
	if IsInTServer() == 1 then
		PushDebugMessage("#{XCCJ_230915_01}")
		return
	end
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("open")
    Set_XSCRIPT_ScriptID(893241)
    Set_XSCRIPT_Parameter(0,0)
    Set_XSCRIPT_Parameter(1,2) -- QE
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

function PlayerQuicklyEnter_OpenZBS_Click()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("open")
    Set_XSCRIPT_ScriptID(999752)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function PlayerQuicklyEnter_UpdateXingZhen()   
	Lua_ShowQuickEnterPointTip(23, 0)
	
	if g_HuoDong[4].g_YingXiong_Rp == 1 then  
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end

	--有星卷可以上阵
	local nHaveXingJuanToSlot = DataPool:LuaFnHaveXingJuanToSlot()
	if nHaveXingJuanToSlot == 1 then  
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end

	--有技能可以上阵
	local bHaveSkillCardToSlot = 0
	for i = 1, 4 do
		if DataPool:LuaFnHaveSkillCardToSlot(i) == 1 then
			bHaveSkillCardToSlot = 1
			break
		end
	end

	if bHaveSkillCardToSlot == 1 then
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end

	--有新的星卷
	local nHaveNewXingJuan = DataPool:LuaFnHaveNewXingJuan()
	if nHaveNewXingJuan == 1 then
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end

	--有新的技能
	local nHaveNewSkillCard = DataPool:LuaFnHaveNewSkillCard()
	if nHaveNewSkillCard == 1 then
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end

	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end

	if DataPool:LuaFnHaveXingJuanToUnLock() == 1 then
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end

	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		Lua_ShowQuickEnterPointTip(23, 1)
		return
	end 
end

function PlayerQuicklyEnter_OpenXingZhen()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	
	CloseFreshManGuide_PlayerQuick()
	local curDay 	= tonumber(DataPool:GetServerDayTime());
	local opentime  = Lua_GetTeSeServerOpenTime(8)
	if opentime>=0 and opentime > curDay then
		PushDebugMessage(ScriptGlobal_Format("#{TSFCL_220210_01}", math.floor(math.mod(opentime,10000)/100), math.mod(opentime,100)))
		return
	end 

	if DataPool:Lua_IsMissionHaveDone(1926) ~= 1 then
		PushDebugMessage("#{XZJC_200309_112}")
		return
	end

	LuaFnOpenXingZhen(true, 0, 1)
end

function PlayerQuicklyEnter_OpenXiGuaJie()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenXiGuaJie")
		Set_XSCRIPT_ScriptID(888081)
		Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()

end


function PlayerQuicklyEnter_OpenStealSkillGuide()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnClickOpenGuideInterface")
		Set_XSCRIPT_ScriptID(999755)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function PlayerQuicklyEnter_FY_YuRe_Cliked()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenFYYuReUI")
		Set_XSCRIPT_ScriptID(999820)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

-- 夏日拉收战令系统
function PlayerQuicklyEnter_OpenSummerZhanLing()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()

	if(IsWindowShow("XiariZhanling")) then
		CloseWindow("XiariZhanling", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskOpenMainUI" )
		Set_XSCRIPT_ScriptID( 791150 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end


--2020金枫开界面
function PlayerQuicklyEnter_Open2020JinFeng()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenJinFeng")
		Set_XSCRIPT_ScriptID(888127)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--2020日常拉收
function PlayerQuicklyEnter_LaShouShop()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end 

	CloseFreshManGuide_PlayerQuick()
	if IsInTServer() == 1 then
		PushDebugMessage("#{RCLS_200731_68}")
		return
	end
 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenLibaoShop")
		Set_XSCRIPT_ScriptID(888143)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT() 
end

-- 双旦活动整合界面
function PlayerQuicklyEnter_ShuangDanCliked()

	if(IsWindowShow("ShuangDan_Guide")) then
		CloseWindow("ShuangDan_Guide", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskOpenShuangDan_Guide")
		Set_XSCRIPT_ScriptID(888820)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function PlayerQuicklyEnter_Open2021SpringWarmUp()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	CloseFreshManGuide_PlayerQuick()
	if(IsWindowShow("CJyure")) then
		CloseWindow("CJyure", true)
		return
	end
	if(IsWindowShow("CJyure_Gift")) then
		CloseWindow("CJyure_Gift", true)
		return
	end 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenSpringWarmUpUI")
		Set_XSCRIPT_ScriptID(505103)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

-- 花朝节预热
function PlayerQuicklyEnter_HZJCliked()

	if(IsWindowShow("HuaZhaoJie_YuRe")) then
		CloseWindow("HuaZhaoJie_YuRe", true)
		return
	end

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenMainUI")
		Set_XSCRIPT_ScriptID(888886)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--关怀绝情谷
function PlayerQuicklyEnter_GuanHuaiJueQingGuCliked()
	if(IsWindowShow("Jueqing_Fuchi")) then
		CloseWindow("Jueqing_Fuchi", true)
		return
	end

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenGuanHuaiButton")
		Set_XSCRIPT_ScriptID(888921)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--花朝节
function PlayerQuicklyEnter_HuaZhaoJieCliked()
	if(IsWindowShow("HuaZhaoJie_Guide")) then
		CloseWindow("HuaZhaoJie_Guide", true)
		return
	end

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenHuaZhaoJie")
		Set_XSCRIPT_ScriptID(888885)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--周年预热签到
function PlayerQuicklyEnter_ZNSignCliked() 
	
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenZhouNianQingSign")
		Set_XSCRIPT_ScriptID(888964)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--节奏服
function PlayerQuicklyEnter_TeSeServerCliked()
	if(IsWindowShow("JiangHuShiJi")) then
		CloseWindow("JiangHuShiJi", true)
		return
	end

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenTeSeUI")
		Set_XSCRIPT_ScriptID(888928)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--清明节抽奖活动
function PlayerQuicklyEnter_Open2019Qingming()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(505080)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--风曳清荷
function PlayerQuicklyEnter_ChildrensDayMainCliked() 
	
	if(IsWindowShow("Ertongjie_Guide")) then
		CloseWindow("Ertongjie_Guide", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenChildrensDay")
		Set_XSCRIPT_ScriptID(232007)
		--Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--新手战令
function PlayerQuicklyEnter_XinShouZhanLingCliked() 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenMain")
		Set_XSCRIPT_ScriptID(998112)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--繁光会宴
function PlayerQuicklyEnter_202208FGHYCliked() 
	
	if IsWindowShow( "CRWarmUp_Shop" ) then
		CloseWindow( "CRWarmUp_Shop", true )
		return
	end 

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenUI" )
		Set_XSCRIPT_ScriptID( 888765 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end


--2019清明节抽奖活动
function PlayerQuicklyEnter_Open2019Qingming()
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(505080)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end 

--七日签到
function PlayerQuicklyEnter_7DaysSignCliked() 
	
	if(IsWindowShow("LianXuQiRi")) then
		CloseWindow("LianXuQiRi", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(998172)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

--新天外活动整合
function PlayerQuicklyEnter_NewTianWaiCliked()

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	if(IsWindowShow("ThreeCity_Guide")) then
		CloseWindow("ThreeCity_Guide", true)
		return
	end
 	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenNewTianWai")
		Set_XSCRIPT_ScriptID(998204)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--2022Q3新天外预热活动-ypl 
function PlayerQuicklyEnter_2022Q3NewTWYRCliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenMyUI")
		Set_XSCRIPT_ScriptID(998197)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end


local m_isPlay = 0
--活跃值达到450的时候 给予的提示 g_bIsFlex
function PlayerQuicklyEnter_UpdateGuiShiButtonAnimation(opType)
	-- 等级
	local nLevel = Player:GetData("LEVEL")
	if ( nLevel < 30 ) then
		return
	end 
	if opType == 1 then
		m_isPlay = 1 
		PlayerQuicklyEnter_MenKeAnimate_Animate:Show() 
		PlayerQuicklyEnter_MenKeAnimate_Animate:Play(true)
		PlayerQuicklyEnter_MenKeAnimate_StopWatch:SetProperty("Timer",1)
	else
		PlayerQuicklyEnter_MenKeAnimate_RequestAnimData()
	end
end

function PlayerQuicklyEnter_MenKeAnimate_GetData(animDayData)
	local animDayState = math.mod(animDayData, 10)
	if animDayState <= 0 then 
		PlayerQuicklyEnter_MenKeAnimate_Animate:Hide()
		PlayerQuicklyEnter_MenKeAnimate_Animate:Play(false)
	else
		if 1 == m_isPlay then
			return
		end 
		PlayerQuicklyEnter_MenKeAnimate_Animate:Show()
		PlayerQuicklyEnter_MenKeAnimate_Animate:Play(true)
	end
end
function PlayerQuicklyEnter_MenKeAnimate_RequestAnimData()
	if 1 == m_isPlay then
		return
	end
	--鬼市活跃足够 最后1位为客户端是否点击过活跃按钮
	local animDayData = DataPool:GetPlayerMission_DataRound(1932)	--
	local animDay = math.floor(animDayData/10)
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay ~= animDay then
		animDayData = 0
	end
	PlayerQuicklyEnter_MenKeAnimate_GetData(animDayData)
end
function PlayerQuicklyEnter_MenKeAnimate_TimeEnd()
	m_isPlay = 0 
	PlayerQuicklyEnter_MenKeAnimate_Animate:Show()
	PlayerQuicklyEnter_MenKeAnimate_Animate:Play(true)
end
function PlayerQuicklyEnter_GuiShiButtonRedPoint()
	PlayerQuicklyEnter_Image21_Tips:Hide()
end 

--鬼市
function PlayerQuicklyEnter_OpenGuiShi()
	--if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
	---	CloseFreshManGuide()
	---end
	---Clear_XSCRIPT()
	---	Set_XSCRIPT_Function_Name("ClickGuiShiButton")
	---	Set_XSCRIPT_ScriptID( 893194 )
	---	Set_XSCRIPT_ParamCount(0)
	---Send_XSCRIPT()
 
end

function PlayerQuicklyEnter_Update_MonthSign()  

	if 	DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 or  
		DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 or
		DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 or
		DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 or
		DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 or
		DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 or
		DataPool:Lua_IsRedPointInUIShow( 42 )  == 1
		then
			Lua_ShowQuickEnterPointTip(7, 1)
	else
		Lua_ShowQuickEnterPointTip(7, 0)
	end
end


function PlayerQuicklyEnter_UpdateFresh() 

	--紫电赠英豪tips
	if ( g_HuoDong[1].g_ZiDianLottery_FloatTips >= 1 and g_HuoDong[1].g_ZiDianLottery_FloatTips <= 3 and playerQuicklyEnterUI[ 5 ] : IsVisible() ) then
		local fx, fy = this:GetChildOffset( "PlayerQuicklyEnter_Bk5" );
		if g_HuoDong[1].g_ZiDianLottery_FloatTips == 1 then
			if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(73) > 0 then  --卡级
				OpenFreshManGuide( 1, 275, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			else
				OpenFreshManGuide( 1, 272, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			end
		elseif g_HuoDong[1].g_ZiDianLottery_FloatTips == 2 then
			if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(73) > 0 then  --卡级
				OpenFreshManGuide( 1, 276, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			else
				OpenFreshManGuide( 1, 273, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			end
		elseif g_HuoDong[1].g_ZiDianLottery_FloatTips == 3 then
			if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(73) > 0 then  --卡级
				OpenFreshManGuide( 1, 277, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			else
				OpenFreshManGuide( 1, 274, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			end
		else
			if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(73) > 0 then  --卡级
				OpenFreshManGuide( 1, 278, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			else
				OpenFreshManGuide( 1, 88, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
			end
		end
		g_HuoDong[1].g_ZiDianLottery_FloatTips = 0;
	end

	--秀场tip
	if ( g_HuoDong[3].g_show_tip == 1 and playerQuicklyEnterUI[ 9 ] : IsVisible() ) then

		playerQuicklyEnterAnimateBtn[ 9 ] : SetFlash(1)
		local fx, fy = this:GetChildOffset( "PlayerQuicklyEnter_Bk9" );
		OpenFreshManGuide( 1, 101, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" )
		g_HuoDong[3].g_show_tip = 0 
		SetTimer("PlayerQuicklyEnter","PlayerQuicklyEnter_StopFlash()", 10000)
	end

	if ( g_HuoDong[3].g_show_tip2 == 1 and playerQuicklyEnterUI[ 9 ] : IsVisible() ) then

		PlayerQuicklyEnter_Animate9 : Show()
		local fx, fy = this:GetChildOffset( "PlayerQuicklyEnter_Bk9" );
		OpenFreshManGuide( 1, 102, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" )
		g_HuoDong[3].g_show_tip2 = 0 
		SetTimer("PlayerQuicklyEnter","PlayerQuicklyEnter_StopFlash2()", 10000)
	end

end


--**********************************
-- 秀场直播界面更新
--**********************************
function PlayerQuicklyEnter_UpdateXiuChang()
 
	-- 服务器条件检测
	if g_HuoDong[3].g_xiuchang_ask_server == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "XiuShowConditionCheck" )
			Set_XSCRIPT_ScriptID( 889962 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		return
	end

	if g_HuoDong[3].g_xiuchang_ask_serverret == 1 then 
		local curDay = tonumber(DataPool:GetServerDayTime())  
		--秀场tips读表
		g_HuoDong[3].g_xiuchangtips_data = GetXiuChangParams()
		if g_HuoDong[3].g_show_tip4_timepro == 0  and GetTime2Day() == g_HuoDong[3].g_xiuchangtips_data.day then
			g_HuoDong[3].g_show_tip4_timepro = 1
			SetTimer("PlayerQuicklyEnter","PlayerQuicklyEnter_StartTips4()", 5000)
		end 
	end

end 
--**********************************
--秀场tips
--**********************************
function PlayerQuicklyEnter_StartTips4()
	if Player:GetLevel() < 15 then
		return 0
	end

	local curDay = tonumber(GetTime2Day()) 
	if curDay ~= g_HuoDong[3].g_xiuchangtips_data.day then
		return 0
	end

	local curMinute = tonumber(GetTime2Minite())
	--开始前 清一清数据
	if curMinute < g_HuoDong[3].g_xiuchangtips_data.starttm1 then
		if g_HuoDong[3].g_show_tip4_1 == 1 then
			g_HuoDong[3].g_show_tip4_1 = 0
			g_HuoDong[3].g_show_tip4_2 = 0
			g_HuoDong[3].g_show_tip4_3 = 0
		end
		return 1
	end

	if g_HuoDong[3].g_xiuchangtips_data.textid1 ~= nil then
		if curMinute >= g_HuoDong[3].g_xiuchangtips_data.starttm1 and curMinute <= g_HuoDong[3].g_xiuchangtips_data.endtm1 then
			if g_HuoDong[3].g_show_tip4_1 == 0 then
				g_HuoDong[3].g_show_tip4_1 = 1
				local fX, fY = this:GetChildOffset("PlayerQuicklyEnter_Bk9")
				OpenFreshManGuide(1, 238, fX+12,  fY + 45 , "PlayerQuicklyEnter", "northeast")
			end
			return 1
		end
	end

	if g_HuoDong[3].g_xiuchangtips_data.textid2 ~= nil then
		if curMinute >= g_HuoDong[3].g_xiuchangtips_data.starttm2 and curMinute <= g_HuoDong[3].g_xiuchangtips_data.endtm2 then
			if g_HuoDong[3].g_show_tip4_2 == 0 then
				g_HuoDong[3].g_show_tip4_2 = 1
				local fX, fY = this:GetChildOffset("PlayerQuicklyEnter_Bk9")
				OpenFreshManGuide(1, 239, fX+12,  fY + 45 , "PlayerQuicklyEnter", "northeast")
			end
			return 1
		end
	end

	if g_HuoDong[3].g_xiuchangtips_data.textid3 ~= nil then
		if curMinute >= g_HuoDong[3].g_xiuchangtips_data.starttm3 and curMinute <= g_HuoDong[3].g_xiuchangtips_data.endtm3 then
			if g_HuoDong[3].g_show_tip4_3 == 0 then
				g_HuoDong[3].g_show_tip4_3 = 1
				local fX, fY = this:GetChildOffset("PlayerQuicklyEnter_Bk9")
				OpenFreshManGuide(1, 240, fX+12,  fY + 45 , "PlayerQuicklyEnter", "northeast")
			end
			return 1
		end
	end
	--结束后 清数据
	if curMinute >= 2359 then
		if g_HuoDong[3].g_show_tip4_1 == 1 then
			g_HuoDong[3].g_show_tip4_1 = 0
			g_HuoDong[3].g_show_tip4_2 = 0
			g_HuoDong[3].g_show_tip4_3 = 0
		end
		return 1
	end
end
 
--2023情人节整合界面
function PlayerQuicklyEnter_2023ValentineCliked() 
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenMyUI")
		Set_XSCRIPT_ScriptID(998345)
		--Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function PlayerQuicklyEnter_JJXHSpringCliked()

	if(IsWindowShow("JiuJiuXiaoHan_Spring")) then
		CloseWindow("JiuJiuXiaoHan_Spring", true)
		return
	end
	
	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay > 20230301 and curDay <= 20230305 then
		PushEvent("OPEN_JIUJIUXIAOHAN_SPRING_EXCHANGEPRIZE")
		return
	end
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(888971)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

--新服整合
function PlayerQuicklyEnter_XinFuZhengHeCliked() 

	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();
	local nIsOpen = DataPool:Lua_XinFuZhengHeIsOpen()
	local BeginDay,EndDay = DataPool:Lua_XinFuZhengHeTime()
	--总开关
	if nIsOpen ~= 1 then
		PushDebugMessage("#{XFZQ_220120_19}")
		return
	end
	--时间判断
	if BeginDay < 0 or EndDay < 0 or curDay < BeginDay or curDay > EndDay then
		PushDebugMessage("#{ZJWF_201231_02}")
		return
	end
	--等级判断
	if nLevel < 30 then
		PushDebugMessage("#{ZJWF_201231_03}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnClientOpenXinFuZhengHe")
		Set_XSCRIPT_ScriptID(888341)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--青梅煮酒
function PlayerQuicklyEnter_QingMeiZhuJiuCliked()
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();


	--时间判断
	if 20230330 > curDay  or 20230419 < curDay then
		PushDebugMessage("#{QMZJ_180308_24}")
		return
	end
	--等级判断
	if nLevel < 30 then
		PushDebugMessage("#{QMZJ_180308_25}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(892719)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end
function PlayerQuicklyEnter_BangHuiHuoYueCliked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenFrame")
		Set_XSCRIPT_ScriptID(998455)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--周年情怀任务
function PlayerQuicklyEnter_2023Anniversary_Cliked()

	if(IsWindowShow("Sixteen_anniversary_Letter")) then
		CloseWindow("Sixteen_anniversary_Letter", true)
		return
	end

	if "PlayerQuicklyEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end

	CloseFreshManGuide_PlayerQuick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(998472)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--盛景繁绘
function PlayerQuicklyEnter_2023ShengJingFanHui_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenActivityUI")
		Set_XSCRIPT_ScriptID(998544)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

-- 城战奖励升级
function PlayerQuicklyEnter_ChengZhanJiangLiShengJi_Cliked()
	-- 城战奖励升级
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenRewardActUI")
		Set_XSCRIPT_ScriptID(998213)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func PlayerQuicklyEnter_ChengZhanJiangLiShengJi_Cliked()

-- 2024Q3版本稳活活动
function PlayerQuicklyEnter_24Q3WenHuo_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(999428)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--宗门预热活动
function PlayerQuicklyEnter_ZongMenYuRe_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(998840)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--宗门活动整合
function PlayerQuicklyEnter_ZongMenActivity_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenZongMenActivity")
		Set_XSCRIPT_ScriptID(998842)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--全民8星入口
function PlayerQuicklyEnter_QuanMin8Xing_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenQuanMin8XingMainUI")
		Set_XSCRIPT_ScriptID(998847)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--2023西瓜商店
function PlayerQuicklyEnter_2023XiGuaShop_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUI")
		Set_XSCRIPT_ScriptID(998574)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end


function PlayerQuicklyEnter_KaiChuan_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowClientUI")
		Set_XSCRIPT_ScriptID(505087)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--新月卡服
function PlayerQuicklyEnter_New_Monthcard_Cliked()
	if(IsWindowShow("New_Monthcard")) then
		CloseWindow("New_Monthcard", true)
		return
	end
	if(IsWindowShow("New_SeasonCard")) then
		CloseWindow("New_SeasonCard", true)
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUI")
		Set_XSCRIPT_ScriptID(998908)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function PlayerQuicklyEnter_WindAndCloudGuide_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenGuideUI")
		Set_XSCRIPT_ScriptID(300150)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--冬季稳活商店
function PlayerQuicklyEnter_WinterShop_Cliked()
	local curDay = tonumber(DataPool:GetServerDayTime());
	if(curDay >= 20240125 and curDay <= 20240324) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenHuoyueUI")
			Set_XSCRIPT_ScriptID(998968)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (curDay > 20240324 and curDay <= 20240327) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenDuiHuanItem")
			Set_XSCRIPT_ScriptID(998968)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--2024周年庆预热活动设计
function PlayerQuicklyEnter_2024ZNQYR_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenFlushOrCloseUI")
		Set_XSCRIPT_ScriptID(999039)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--【2024Q2】Q2版本预热活动 
function PlayerQuicklyEnter_2024PreActivity_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(999185)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--2024q2大话西游整合界面
function PlayerQuicklyEnter_24Q2DHXY_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenDaHuaXiYouActivity")
		Set_XSCRIPT_ScriptID(800818)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--2024q2大话西游预热界面
function PlayerQuicklyEnter_24Q2DHXY_YURE_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenDaHuaXiYouYuReActivity")
		Set_XSCRIPT_ScriptID(999112)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--秋枫共赏
function PlayerQuicklyEnter_ShuangYe_Cliked()
	if(IsWindowShow("ShuangYe")) then
		CloseWindow("ShuangYe", true)
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenFrostReWard")
		Set_XSCRIPT_ScriptID(891414)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--捡粑粑
function PlayerQuicklyEnter_SBHZ_Cliked()
	if(IsWindowShow("ShiBaoHuanZhu")) then
		CloseWindow("ShiBaoHuanZhu", true)
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HotPointClick")
		Set_XSCRIPT_ScriptID(892889)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenGameUI")
		Set_XSCRIPT_ScriptID(892889)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
-- 冰雪节预热
function PlayerQuicklyEnter_BingXueJie_Yr_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(999485)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function PlayerQuicklyEnter_ForceLevel_Click()
	DataPool:lua_GetNormalRankingListInfo(6)
end

function PlayerQuicklyEnter_DongJiChouJiang_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowClientUI")
		Set_XSCRIPT_ScriptID(505087)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
-- 冰雪节
function PlayerQuicklyEnter_BingXueJie_Guide_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenBingXueJieGuide")
		Set_XSCRIPT_ScriptID(501009)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function PlayerQuicklyEnter_FaceAuth_FangChengMi_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(999552)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function PlayerQuicklyEnter_NewServerHongBao_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowClientUI")
		Set_XSCRIPT_ScriptID(501016)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function PlayerQuicklyEnter_XiaKeXing_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(999630)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function PlayerQuicklyEnter_Update_ActivityShedule()
	if playerQuicklyEnterAnimateBtn[1] == nil then
		return
	end
	local nXiaKe = Player:GetData("IsXiaKe") 
	if nXiaKe == 1 then
		playerQuicklyEnterAnimateBtn[1]:SetProperty("PushedImage","set:KJRK_28 image:JCHD_Push")
		playerQuicklyEnterAnimateBtn[1]:SetProperty("NormalImage","set:KJRK_28 image:JCHD_Normal")
		playerQuicklyEnterAnimateBtn[1]:SetProperty("HoverImage","set:KJRK_28 image:JCHD_Hover") 
	else
		playerQuicklyEnterAnimateBtn[1]:SetProperty("PushedImage","set:KJRK_2 image:KJRK_JCHD_Pushed")
		playerQuicklyEnterAnimateBtn[1]:SetProperty("NormalImage","set:KJRK_2 image:KJRK_JCHD_Normal")
		playerQuicklyEnterAnimateBtn[1]:SetProperty("HoverImage","set:KJRK_2 image:KJRK_JCHD_Hover") 
	end
	
end

--2025周年庆预热活动
function PlayerQuicklyEnter_2025ZNQYR_Click()
	local nShow = 1
	if(IsWindowShow("Anniversary2025_Yure")) then
		nShow = 0
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenOrFlushUI")
		Set_XSCRIPT_ScriptID(999655)
		Set_XSCRIPT_Parameter(0,nShow)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function PlayerQuicklyEnter_DaFuWeng_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenMainUI")
		Set_XSCRIPT_ScriptID(290400) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--2025时装返场
function PlayerQuicklyEnter_2025ZNSZ_Click()
	local nShow = 1
	if(IsWindowShow("Anniversary_2024ClothBack")) then
		nShow = 0
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnPlayerQuicklyEnterOpenUI")
		Set_XSCRIPT_ScriptID(998460)
		Set_XSCRIPT_Parameter(0, nShow)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function PlayerQuicklyEnter_2025DuanWuYuRe_Click()
	if(IsWindowShow("DuanWu2025_Yure")) then
		CloseWindow("DuanWu2025_Yure", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenDuanWuYuRe")
		Set_XSCRIPT_ScriptID(999683)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function PlayerQuicklyEnter_2025XinFuSheJiao_Click()
	if(IsWindowShow("ServerNew_XFSJ_Rewards")) then
		CloseWindow("ServerNew_XFSJ_Rewards", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UpdateUI")
		Set_XSCRIPT_ScriptID(888185)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function PlayerQuicklyEnter_2025QiXiHuaJuan_Click()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenUI")
		Set_XSCRIPT_ScriptID(999727)
		Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function PlayerQuicklyEnter_LevelEx_Yindao_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenLevelExYinDaoUI")
		Set_XSCRIPT_ScriptID(999744)
		Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function PlayerQuicklyEnter_ZongMenActivity_Click()
	if(IsWindowShow("ZongMen_Activity")) then
		CloseWindow("ZongMen_Activity", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(998830)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function PlayerQuicklyEnter_NewYuanDan_Click()
	if(IsWindowShow("NewYearisDay")) then
		CloseWindow("NewYearisDay", true)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenNewYearisDay")
		Set_XSCRIPT_ScriptID(892637)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--争霸赛直播 固定时间点浮动tips
function PlayerQuicklyEnter_ArriveTimePoint(strNotify, day, time)
	local findIndex = 0
	for i, v in g_Arrive_ServerTime_Points do
		if v.day == tonumber(day) and v.hour == tonumber(time) then 
			findIndex = i
			break
		end
	end
	if findIndex == 0 then 
		return 
	end
	local operType = g_Arrive_ServerTime_Points[findIndex].Type
	if operType == 'FreshManGuide' then 
		local nCtlidx = g_Arrive_ServerTime_Points[findIndex].nCtlidx
		if not playerQuicklyEnterUI[nCtlidx]:IsVisible() then
			return 
		end
		local fx, fy = this:GetChildOffset( "PlayerQuicklyEnter_Bk"..nCtlidx );
		local nGuideIdx = g_Arrive_ServerTime_Points[findIndex].nGuideIdx
		OpenFreshManGuide( 1, nGuideIdx, fx + 12, fy + 45, "PlayerQuicklyEnter", "northeast" );
	end
end

--2026砸金蛋
function PlayerQuicklyEnter_ZaJinDanCliked() 
	local curDay = tonumber(DataPool:GetServerDayTime())
	local nLevel = Player:GetLevel()
	local nIsOpen = DataPool:Lua_2026ZaJinDanIsOpen()
	local BeginDay,EndDay = DataPool:Lua_2026ZaJinDanTime()
	--总开关
	if nIsOpen ~= 1 then
		return
	end
	--时间判断
	if BeginDay < 0 or EndDay < 0 or curDay < BeginDay or curDay > EndDay then
		PushDebugMessage("#{DKZJ_260521_04}")
		return
	end
	--等级判断
	if nLevel < 30 then
		PushDebugMessage("#{DKZJ_260521_03}")
		return
	end

	if IsWindowShow("Xichunchi_Prize2") then
		CloseWindow("Xichunchi_Prize2", true)
	else	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenXiChunChiUI")
			Set_XSCRIPT_ScriptID(885577)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

function PlayerQuicklyEnter_QiXi_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenQiXiGuideUI")
		Set_XSCRIPT_ScriptID(893776)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function PlayerQuicklyEnter_WSTG_Cliked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenGuideUI")
		Set_XSCRIPT_ScriptID(212256)
		Set_XSCRIPT_Parameter(0, 1)--显示整合界面的页签1
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--2026七夕剧情副本任务
function PlayerQuicklyEnter_2026_QiXi_Cliked()
	if(IsWindowShow("QiXi_StoryLetter")) then
		return
	end 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UpdateLetterUI")
		Set_XSCRIPT_ScriptID(505201)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end