local g_CurMap = "Minimap";
local TimeDot = {}
local strNetDelayMessage = nil
local g_bNewMailTip=0
local bIsMailHaveAppend=0
local g_myAsk = 0;
local g_diaochaAsk = 0;
local g_flash=0
local g_OpenServiceCenter = 0			-- 是否打开客服中心
local g_AccVipLevel = 0					-- VIP等级
local g_MiniMap_NowDot = 1 --时辰点

local g_BBSFlashdown = 10*1000; --10s闪烁
local g_BBSInPlayWarning = 1			--是否在闪烁冷却

local MiniMapMFShouKaiKaStep = {		-- 首开卡阶段
	[1] = 1,
	[2] = 1,
	[3] = 1,
	[4] = 1,
}
local YuanBaoCostAdnExch = {			-- 元宝消耗,元宝兑换
	{0, 200},
	{2200, 2200},
	{4000, 4000},
}
local MD_KAIKACHONGZHI3_EXCH = 726		-- 开卡充值送好礼，累计兑换的元宝
local MD_KAIKACHONGZHI3_COST = 727		-- 开卡充值送好礼，累计消费的元宝

local g_ButtonLastTime= 0;
local g_ButtonCDTime 	= 2; --按钮冷却时间

local g_Questionnaire = 0
local g_QuestionnaireTickCount = 0

local g_JDTS_SceneMapFile = {
	["dali_new_320"]="dali_new_320_SJ",
	["dali_new_320_SP"]="dali_new_320_SP_SJ",
	["petisland_new"]="petisland_new_SJ",
	["suzhou_new"]="suzhou_new_SJ",
	["suzhou_new_SP"]="suzhou_new_SP_SJ",
	["PCity"]="PCity_SJ",
	["xihuscene"]="xihuscene_SJ",
	["jiangescene"]="jiangescene_SJ",
	["yannanscene"]="yannanscene_SJ",
	["luoyang_new_SP"]="luoyang_new_SP_SJ",
	["luoyang_new"]="luoyang_new_SJ",
	["luoyang_new_snow"]="luoyang_new_snow_SJ",
}

local g_2606S_SceneMapFile = { 
	["dali_new_320_SP"]="dali_new_320_SP_QX",
	["dali_new_320"]="dali_new_320_QX",
	["luoyang_new"]="luoyang_new_QX",
	["luoyang_new_snow"]="luoyang_new_snow_QX",
	["luoyang_new_SP"]="luoyang_new_SP_QX",
	["suzhou_new"]="suzhou_new_QX",
	["suzhou_new_SP"]="suzhou_new_SP_QX",
	["PCity"]="PCity_QX",
	["petisland_new"]="petisland_QX",
	["qinhuanggong_4"]="qinhuanggong_4_QX",
	["shuhe"]="shuhe_QX",
}

--OnLoad
--  0 Animy
--  1 ExpNPC
--  2 Teamate
--  3 OtherPlayer
--  4 ExpObj
function MiniMap_PreLoad()

	this:RegisterEvent("GAMELOGIN_OPEN_COUNT_INPUT",true);
	this:RegisterEvent("SCENE_TRANSED",true);
	this:RegisterEvent("UPDATE_MAP",true);
	this:RegisterEvent("OPEN_MINIMAP",true );   --
	this:RegisterEvent("ACCELERATE_KEYSEND",true);
	this:RegisterEvent("UPDATE_NETSTATUS",true);
	this:RegisterEvent("PKMODE_CHANGE",true);  --
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("SHOW_NEEDREPAIR",true)
	this:RegisterEvent("LEFTPROTECTTIME_CHANGE",true) --
    --安全中心，将老的账号安全界面注销 Manda 2013 7 30
	--this:RegisterEvent("OPEN_MINIMAPEXP",false);

	this:RegisterEvent("FLAH_MINIMAP",true);

	this:RegisterEvent("STOP_FLAH_MINIMAP",true);

	--add by fangyuan
	    --安全中心，将老的账号安全界面注销 Manda 2013 7 30
		--this:RegisterEvent("SHOW_ACCOUNT_SAFE_ICON",false);

	this:RegisterEvent("SHOW_SHIMINGRENZHENG_ANIMATA",false);

	this:RegisterEvent("MINIMAP_SHOW_SHIMINGRENZHENG_BTN",false);  --实名更正

	this:RegisterEvent("PLAYERASK_INGAME",true);

	this:RegisterEvent("MINMAP_PLAYERLIST_SHOW",true);

	this:RegisterEvent("UPDATE_SKY_TIME",false);
	this:RegisterEvent("NOTIFY_PKPLAYER",false);

	this:RegisterEvent("SHOW_BUGFBBTN",true);

	--this:RegisterEvent("TODAY_ACTIVE_POINT",false);
	--this:RegisterEvent("WEEK_ACTIVE_POINT",false);

	this:RegisterEvent("MAILNEW_TIPS",false)

	this:RegisterEvent("HIDE_TLBB_MAIN",true)
	this:RegisterEvent("OPEN_MINMAP",true)
	this:RegisterEvent("SHOW_EQUIPMASTER_INVALID",false)
	this:RegisterEvent("HIDE_THIS_UI",true)
	this:RegisterEvent("ACC_CHANGE_TIPS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false );	-- 进入world
	this:RegisterEvent("UNIT_LEVEL",false);				-- 升级
	this:RegisterEvent("UPDATE_POINT",false)
	this:RegisterEvent("SHOW_GUILDWARRANK_ANIMI",false)
	this:RegisterEvent("QUESTIONNAIRE",false)
	this:RegisterEvent("ON_SCENE_UPDATED",false)
	this:RegisterEvent("BATTLE_ASSIST_EVENT",false)
	this:RegisterEvent("NEIGUA_FUBEN_EVENT",true)
	this:RegisterEvent("OPEN_DAHUA_MINITIPS",true);
	
	this:RegisterEvent("OPEN_MULTILINE_GUIDE",true)
	this:RegisterEvent("UPDATE_MINIMAP_FENXIAN_STATE",true)

	this:RegisterEvent("NOTIFY_ORIGINALJD");
	this:RegisterEvent("NOTIFY_2606S");
	
end

function MiniMap_PK_Mode_Show_Menu_Func()

	 Player:PVP_ShowMenu();
end;

function MiniMap_OnLoad()
	TimeDot[1] = MiniMap_TimeDot1
	TimeDot[2] = MiniMap_TimeDot2
	TimeDot[3] = MiniMap_TimeDot3
	TimeDot[4] = MiniMap_TimeDot4
	TimeDot[5] = MiniMap_TimeDot5
	TimeDot[6] = MiniMap_TimeDot6
	TimeDot[7] = MiniMap_TimeDot7
	TimeDot[8] = MiniMap_TimeDot8
	TimeDot[9] = MiniMap_TimeDot9
	TimeDot[10] = MiniMap_TimeDot10
	TimeDot[11] = MiniMap_TimeDot11
	TimeDot[12] = MiniMap_TimeDot12
	for i=1,12 do--默认都hide
		TimeDot[i]:Hide()
	end
	g_MiniMap_NowDot = GetCurrentTime() + 1
	if g_MiniMap_NowDot <= 1 or g_MiniMap_NowDot >= 12 then
		g_MiniMap_NowDot = 1
	end
	--PushDebugMessage("OnLoadWorldTime:"..tostring(g_MiniMap_NowDot))
	if TimeDot[g_MiniMap_NowDot] ~= nil then
		TimeDot[g_MiniMap_NowDot]:Show()--默认显示一个时辰点
	end

	MiniMap_EquipEndurance:Hide();
	MiniMap_BaiBingJingTong:Hide()

--	MiniMap_AccountSafeBack:Hide();  老的安全中心注销 Manda 2013-7-30

	Minimap_Max();
	MiniMap_Yuanbao:SetToolTip("元宝商店");
	MiniMap_AutoSearch:SetToolTip("#{INTERFACE_XML_983}");
	MiniMap_NetStatus_Flash:Play( false );
	--MiniMap_Huoyuehaoli_Ani:Play( false );
	--MiniMap_WeekhuoyuehaoliAnimate:Play( false );

	MiniMap_Fangchengmi_Btn	: Hide()
	MiniMap_Fangchengmi_Flash : Hide();

	-- 邮件提示
	MiniMap_Mail:Hide()
	MiniMap_MailAnimate:Play( false )

	MiniMap_Xinfu:Hide()		-- 现在时新手欢乐月
	MiniMap_Shouchong:Hide()
	MiniMap_Kefu:Hide()
	MiniMap_XuanZhan:Hide()
	MiniMap_XinShouNew:Hide()
	MiniMap_XinShouNew_Over:Hide()
	MiniMap_XinShouNew_Over_tips:Hide()
	MiniMap_Fenxian:Hide()
	MiniMap_FenxianFlashUpdata(false)

	--关闭录制 需要开启的话 注释掉这行 然后重启
	--MiniMap_Luzhi_Button:Hide()
end
function MiniMap_UpdateSceneName()
	local scenename;
	scenename = GetCurrentSceneName();
	local len = string.len(scenename);
	if( len < 10 ) then
		MiniMap_Placename:SetProperty( "Font", "YouYuan9.75" );
	else
		MiniMap_Placename:SetProperty( "Font", "SongTiBmp12" );
	end
	MiniMap_Placename:SetText("#gFF0FA0".. scenename );
end

function MiniMap_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end
	
	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end
	
	if ( event == "GAMELOGIN_OPEN_COUNT_INPUT") then
		g_flash=0
		return
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 1238 ) then
			local sceneId = Get_XParam_INT(0)
			return
	end
	--if ( event == "UI_COMMAND" and tonumber(arg0) == 20110524 ) then
	--		MiniMap_OnShown()
	--		return
	--end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20141203 ) then
			local srvTime = Get_XParam_INT(0)
			MiniMap_OpenForumTips(srvTime)
			return
	end
	
	if ( event == "SCENE_TRANSED" ) then
		MiniMap_Update( arg0 );
		MiniMap_UpdateSceneName();
		UpdateMinimapState();
		UpdateFenxianState()
	elseif( event == "ON_SCENE_UPDATED" ) then
		local scenename,sceneID;
		sceneID = GetSceneID();
		scenename = GetSceneMapByID(tonumber(sceneID));
		MiniMap_Update( scenename );
		MiniMap_UpdateSceneName();
		UpdateFenxianState()
		UpdateMinimapState();
	elseif ( event == "UPDATE_MAP" ) then
		if( tonumber( arg0 ) == 1 ) then
			MiniMap_UpdateSceneName();
			UpdateFenxianState()
		end
		MiniMap_PosModify();
		Minimap_CoordinateUpdate();
	elseif( event == "OPEN_MINIMAP" ) then
		Variable:SetVariable( "MinimapState","mini", 1 );
		UpdateMinimapState();
	elseif( event == "ACCELERATE_KEYSEND" ) then
		MiniMap_HandleAccKey(arg0);
	elseif event == "NEIGUA_FUBEN_EVENT" then
		if arg0 == "update" then
			if this:IsVisible() then
				MiniMap_ZDZD_UpdateZdzdState()
			end
		end
	elseif( event =="UPDATE_NETSTATUS") then
	  local strNetState = ""
	  local strOnlineTime = ""
		if arg0 ~= nil and tonumber(arg0) < 250 then
			MiniMap_MiniMap_NetStatus : SetProperty("SetCurrentImage","NetState1")
			strNetState = "网络状况:空闲".."("..tostring(arg0).."ms)"
		elseif arg0 ~= nil and tonumber(arg0) < 500 then
			MiniMap_MiniMap_NetStatus : SetProperty("SetCurrentImage","NetState2")
			strNetState = "网络状况:正常".."("..tostring(arg0).."ms)"
		elseif arg0 ~= nil and tonumber(arg0) < 2000 then
			MiniMap_MiniMap_NetStatus : SetProperty("SetCurrentImage","NetState3")
			strNetState = "网络状况:拥挤".."("..tostring(arg0).."ms)"
		elseif arg0 ~= nil and tonumber(arg0) < 3000 then
		    MiniMap_MiniMap_NetStatus : SetProperty("SetCurrentImage","NetState4")
			strNetState = "网络状况:堵塞".."("..tostring(arg0).."ms)"
		else
			MiniMap_MiniMap_NetStatus : SetProperty("SetCurrentImage","NetState4")
			strNetState = "网络状况:堵塞(超过3000ms)"
		end

		local nFatigueState = tonumber( arg1 )
		local IsNeedFatigue = tonumber( arg2 );
		local OnlineTime = tonumber( arg3 )
		local strOnlineState = "(健康)"

		if( IsNeedFatigue == 1 ) then --如果需要计算防沉迷
			if( nFatigueState == 1 ) then
				strOnlineState = "(疲劳)"
			elseif( nFatigueState == 2 ) then
				strOnlineState = "(不健康)"
			end
			strOnlineTime = "#r累计在线时间:"..tostring( OnlineTime ).."小时"..strOnlineState
		else
			strOnlineState = "";
		end

		strNetDelayMessage = strNetState .. strOnlineTime
		MiniMap_MiniMap_NetStatus : SetToolTip( strNetDelayMessage )
	elseif( event =="SHOW_NEEDREPAIR") then
		if tonumber(arg0) == 1 then
			MiniMap_EquipEndurance:Show();
			if Player:GetData("Is2606S") == 1 then
				MiniMap_EquipEndurance:SetToolTip("#{QXF_260623_09}");
			else
				MiniMap_EquipEndurance:SetToolTip("#{ZBXL_081009_01}");
			end
		else
			MiniMap_EquipEndurance:Hide();
		end;
	elseif( event =="SHOW_EQUIPMASTER_INVALID") then
		if tonumber(arg0) == 1 then
			MiniMap_BaiBingJingTong:Show();
			MiniMap_BaiBingJingTong:SetToolTip("#{GJYLK_120517_71}");
		else
			MiniMap_BaiBingJingTong:Hide();
		end;
	elseif( event == "PKMODE_CHANGE" ) then
		Minimap_UpdatePKMode();
	elseif(event == "LEFTPROTECTTIME_CHANGE")then
		--被盗判定和永久安全时间
		local DT = 0
		if arg0 ~= nil then
			DT = math.floor( tonumber(arg0)/1000);
		end

		local ret = DataPool:GetForeverLock()
		if ret == true then
			MiniMap_SafeTime_Frame:Show();
			MiniMap_SafeTimeAnimate:Show();
			MiniMap_SafeTime_StopWatch:SetProperty("Timer","");
			MiniMap_SafeTime_Frame:SetText("#{BDPD_110107_2}");
			if DT <= 0 then
				CloseFangDaohao();--关闭疑似被盗提示窗口
			end
		else
			MiniMap_SafeTime_Frame:SetText("#{INTERFACE_XML_MINI_02}");
			if(DT>0)then
				MiniMap_SafeTime_Frame:Show();
				MiniMap_SafeTimeAnimate:Show();
				MiniMap_SafeTime_StopWatch:SetProperty("Timer",tostring(DT));
			else
				MiniMap_SafeTime_Frame:Hide();
				MiniMap_SafeTimeAnimate:Hide();
				CloseFangDaohao();--关闭疑似被盗提示窗口
			end
		end
	elseif( event == "OPEN_MINIMAPEXP" ) then
		MiniMap_UpdateLockFlag();
	elseif( event == "FLAH_MINIMAP" ) then
		MiniMap_FlashHuodong();
	elseif( event == "STOP_FLAH_MINIMAP" ) then
		MiniMap_StopFlashHuodong();

	--elseif( event == "SHOW_ACCOUNT_SAFE_ICON") then
	--  老的账号安全体系
	--	MiniMap_AccountSafeBack:Show();
	--	MiniMap_AccountSafe:SetProperty( "SetCurrentImage","red" );
	--	MiniMap_AccountSafeState:SetProperty( "SetCurrentImage","SafeIcon" );
	--	SetTimer("MiniMap","MiniMap_TimerProc()",60000);		--设置定时器一分钟后关闭窗口
	--	MiniMap_AccountSafeFlash : Show();		--确保会闪烁
	
	elseif( event == "NOTIFY_PKPLAYER" ) then
		if tonumber(arg0) > 0 then
			MiniMap_FindExp:Show();
		else
			MiniMap_FindExp:Hide();
		end
	elseif event == "UPDATE_SKY_TIME" then
		local skyTime = tonumber(arg0)
		local skyHour = math.floor(skyTime / 3600)
		local skyMinute = math.floor(math.mod(skyTime, 3600) / 60)
		local skySecond = math.mod(skyTime, 60)
		local skyTimeString = "当前时间: "
		if skyHour < 10 then
			skyTimeString = skyTimeString .. "0"
		end
		skyTimeString = skyTimeString .. tostring(skyHour) .. ":"
		if skyMinute < 10 then
			skyTimeString = skyTimeString .. "0"
		end
		skyTimeString = skyTimeString .. tostring(skyMinute) .. ":"
		if skySecond < 10 then
			skyTimeString = skyTimeString .. "0"
		end
		skyTimeString = skyTimeString .. tostring(skySecond)
		if strNetDelayMessage ~= nil then
			MiniMap_MiniMap_NetStatus:SetToolTip(strNetDelayMessage .. "#r" .. skyTimeString)
		else
			MiniMap_MiniMap_NetStatus:SetToolTip(skyTimeString)
		end
	elseif event == "NOTIFY_ORIGINALJD" and  tonumber(arg0) == 1 then -- 第一次MiniMap_Update时候 不知道是否是超特 所以这里再次执行
		local scenename,sceneID;
		sceneID = GetSceneID();
		scenename = GetSceneMapByID(tonumber(sceneID));
		MiniMap_Update( scenename )
	elseif event == "NOTIFY_2606S" and  tonumber(arg0) == 1 then
		local scenename,sceneID;
		sceneID = GetSceneID();
		scenename = GetSceneMapByID(tonumber(sceneID));
		MiniMap_Update( scenename )
	end

	if( event == "SHOW_SHIMINGRENZHENG_ANIMATA" ) then
		if((not this:IsVisible())) then
			return;
		end

		if(tonumber(arg0) == 1)then
		  if(Variable:GetVariable("System_CodePage") ~= "1258") then
				MiniMap_Fangchengmi_Flash : Show();
				MiniMap_Fangchengmi_Btn :SetToolTip("#{FCMX_90609_2}");
			end
			MiniMap_Fangchengmi_Flash1 : Hide()
			MiniMap_Fangchengmi_Flash1 :SetProperty( "AlwaysOnTop","False" );
			MiniMap_Fangchengmi_Flash : SetProperty( "AlwaysOnTop","True" );
		elseif(tonumber(arg0) == 2)then
		  if(Variable:GetVariable("System_CodePage") ~= "1258") then
				MiniMap_Fangchengmi_Flash1 : Show();
				MiniMap_Fangchengmi_Btn :SetToolTip("#{FCMX_90609_3}");
			end
			MiniMap_Fangchengmi_Flash : Hide();
			MiniMap_Fangchengmi_Flash :SetProperty( "AlwaysOnTop","False" );
			MiniMap_Fangchengmi_Flash1 : SetProperty( "AlwaysOnTop","True" );
		else
			MiniMap_Fangchengmi_Btn :SetToolTip("#{FCMX_90609_1}");
			MiniMap_Fangchengmi_Flash1 : Hide();
			MiniMap_Fangchengmi_Flash : Hide();
		end
	end
	if( event == "MINIMAP_SHOW_SHIMINGRENZHENG_BTN" ) then
		if(not this:IsVisible() ) then
			return;
		end
		if(tonumber(arg0) == 1)then
		  if(Variable:GetVariable("System_CodePage") ~= "1258") then
				MiniMap_Fangchengmi_Btn : Show();
			end
		else
			MiniMap_Fangchengmi_Btn : Hide();
		end
	end

	if (event == "PLAYERASK_INGAME" )  then
		--MiniMap_SuperHelp2:Hide();
		MiniMap_PlayerAsk_Bn:Show();
		MiniMap_PlayerAsk:Show();
		g_myAsk = tonumber(arg0)
	end

	if (event == "MINMAP_PLAYERLIST_SHOW") then
		MiniMap_LiebiaoFunc();
	end

	if (event == "SHOW_BUGFBBTN") then
		if(tonumber(arg0) == 1) then
			MiniMap_BugUpdate:Show();
		elseif(tonumber(arg0) == 0) then
			MiniMap_BugUpdate:Hide();
		end
	end

	if event == "UPDATE_MINIMAP_FENXIAN_STATE" then
		if this:IsVisible() then
			UpdateFenxianState()
			MiniMap_UpdateSceneName()
		end
	end

	if (event == "TODAY_ACTIVE_POINT") then
		--MiniMap_Huoyuehaoli_Ani:Play( true )
	end
	if (event == "WEEK_ACTIVE_POINT") then
		--MiniMap_WeekhuoyuehaoliAnimate:Play( true )
		--local fX = 0
		--local fY = 0
		--fX, fY = this:GetChildOffset("MiniMap_Weekhuoyuehaoli")

		--fX = fX + MiniMap_Weekhuoyuehaoli:GetProperty("AbsoluteWidth") / 2
		--fY = fY + 20
		--local nBoxID = tonumber(arg0)
		--if(nBoxID > 0 and nBoxID < 4) then
			--OpenFreshManGuide(1, 38+nBoxID, fX, fY, "MiniMap", "southwest")
		--end
	end

	if event == "OPEN_MULTILINE_GUIDE" then
		MiniMap_FenxianFlashUpdata(true)
	end

	if (event == "MAILNEW_TIPS" and tonumber(arg0) == 0) then --附件邮箱提示
		g_bNewMailTip = tonumber(arg1)
		if g_bNewMailTip == 0 then
			MiniMap_Mail:Hide()
			MiniMap_MailAnimate:Play( false )
		else
			MiniMap_Mail:Show()
			MiniMap_MailAnimate:Play( true )
		end
	end
	if(event == "MAILNEW_TIPS" and tonumber(arg0) == 1) then
		MiniMap_MailAnimate:Play( false )
	end

	if ( event == "HIDE_TLBB_MAIN" ) then

		this:Hide()
	end
	if ( event == "OPEN_MINMAP" ) then
		if GameProduceLogin:IsWeGameServer() > 0 then
			MiniMap_Forum:Hide();
		end
		this:Show()
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 890020 ) then
		OpenFlash()
	end
	--fjs
	--if ( event == "UI_COMMAND" and tonumber(arg0) == 20121011 ) then
		--开启tips
		--local fX = 0
		--local fY = 0

		--fX, fY = this:GetChildOffset("MiniMap_Jiayuan_OK")

		--fX = fX + MiniMap_Jiayuan_OK:GetProperty("AbsoluteWidth") / 2
		--fY = fY + 20
		--OpenFreshManGuide(1, 38, fX, fY, "MiniMap", "northeast")
		--return
	--end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 8911071) then   -- 现在时新手欢乐月
		-- 位置调整 新服换新手  新服欢乐月按钮闪烁
		local isShow = Get_XParam_INT(0)
		if isShow == 1 then
			MiniMap_XinfuPlayWarning();
		end
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 2018020202) then   -- 现在时新手嘉年华
		MiniMap_XinShouNew : PlayWarning( 1 );
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89267504) then   -- 现在时新手嘉年华版首充
			MiniMap_XinShouNew_Over:Hide()
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89267505) then   -- 现在时新手嘉年华版首充
		local isShow = Get_XParam_INT(0)
		if isShow == 1 then
			MiniMap_XinShouNew_Over_tips:Show()
		else
			MiniMap_XinShouNew_Over_tips:Hide()
		end
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89269007) then   -- 现在时新手嘉年华版首充 
		if DataPool:Lua_IsRedPointInUIShow( 38 ) == 1 then
			MiniMap_Shouchongtips:Show()
		else
			MiniMap_Shouchongtips:Hide()
		end
	end
	
	if ( event == "UI_COMMAND" and tonumber(arg0) == 2018012901) then
		-- 位置调整 新服换新手  新服欢乐月按钮闪烁
		local isShowIndex = Get_XParam_INT(0)
		if isShowIndex == 1 then	--新手嘉年华
			MiniMap_XinShouNew:Show()
			MiniMap_Xinfu:Hide()
			MiniMap_Shouchong:Hide()
			MiniMap_XinShouNew_Over:Hide()
		elseif isShowIndex == 2 then
			MiniMap_XinShouNew:Hide()--新手欢乐月
			MiniMap_Xinfu:Show()
			MiniMap_Shouchong:Hide()
			MiniMap_XinShouNew_Over:Hide()
		elseif isShowIndex == 3 then--新手嘉年华版 首充
			MiniMap_XinShouNew:Hide()
			MiniMap_Xinfu:Hide()
			MiniMap_Shouchong:Hide()
			MiniMap_XinShouNew_Over:Show()
		elseif isShowIndex == 4 then--新手欢乐月 首充
			MiniMap_XinShouNew:Hide()
			MiniMap_Xinfu:Hide()
			MiniMap_XinShouNew_Over:Hide()
			MiniMap_UpdateShouKaiButtonStateAck()
		elseif isShowIndex == 5 then--所有都隐藏
			MiniMap_XinShouNew:Hide()
			MiniMap_XinShouNew_tips:Hide()
			MiniMap_Xinfu:Hide()
			MiniMap_Xinfutips:Hide()
			MiniMap_Shouchong:Hide()
			MiniMap_Shouchongtips:Hide()
			MiniMap_XinShouNew_Over:Hide()
			MiniMap_XinShouNew_Over_tips:Hide()
		end
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 2018012902) then
		MiniMap_ShouKaiKa()
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 2018013001) then
		local isShow = Get_XParam_INT(0)
		if isShow == 1 then
			MiniMap_XinShouNew_tips:Show()
		else
			MiniMap_XinShouNew_tips:Hide()
		end
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 2018013002) then
		if arg1 ~= nil  then
			if tonumber(arg1) == 1 then
					MiniMap_XinShouNew_tips:Show()
			elseif tonumber(arg1) == 0 then
					MiniMap_XinShouNew_tips:Hide()
			end
		end

	end

	if event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		else
			if GameProduceLogin:IsWeGameServer() > 0 then
				MiniMap_Forum:Hide();
			end
			this:Show()
		end
	end

	if event == "ACC_CHANGE_TIPS" then
		MiniMap_ChangeButtonTip()
	end

	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 8898531 ) then
		MiniMapMFShouKaiKaStep[ 1 ] = Get_XParam_INT( 0 );
		MiniMapMFShouKaiKaStep[ 2 ] = Get_XParam_INT( 1 );
		MiniMapMFShouKaiKaStep[ 3 ] = Get_XParam_INT( 2 );
		MiniMapMFShouKaiKaStep[ 4 ] = Get_XParam_INT( 3 );
		nShouChongLimitTime = Get_XParam_INT( 4 );
		-- 更新Btn状态
		MiniMap_UpdateShouKaiButtonStateAck();
	end

	if ( event == "UNIT_LEVEL" ) then
		local nLevel = Player:GetLevel();
		if ( nLevel == 15 ) then
			-- 首开卡按钮状态
			MiniMap_UpdateShouKaiButtonStateReq();
		end
	end

	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 20141007 ) then
		g_OpenServiceCenter = Get_XParam_INT( 0 );
		g_AccVipLevel = Get_XParam_INT( 1 );
		if 1 ~= g_OpenServiceCenter and GameProduceLogin:IsWeGameClient() <= 0 then
			MiniMap_Kefu:Hide()
		else
			MiniMap_Kefu:Show()
		end
	end

	if event == "UPDATE_POINT" then
		--MiniMap_UpdateShouKaiButtonStateAck()
	end

	if ( event == "SHOW_GUILDWARRANK_ANIMI" ) then
		local type = arg0;
		if(arg0=="show")then
			if  KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1	then
				MiniMap_XuanZhan:SetProperty("WarningAnimation","Bang_Xuanzhan_FlashK");
			else
				MiniMap_XuanZhan:SetProperty("WarningAnimation","Bang_Xuanzhan_Flash");
			end

			MiniMap_XuanZhan:Show()
			MiniMap_XuanZhan : PlayWarning( 1 )
		else
			MiniMap_XuanZhan:Show()
			MiniMap_XuanZhan : PlayWarning( 0 )
		end
	end

	if event == "QUESTIONNAIRE" then

		if tonumber(arg0) == 0 then
			if tonumber(arg1) ~= nil and tonumber(arg2) ~= nil then
				MiniMap_Questionnaire(tonumber(arg1) ,tonumber(arg2) )
			end
		elseif tonumber(arg0) == 1 then
			MiniMap_Questionnaire_OpenURL()
		end
		return
	end

	if event == "BATTLE_ASSIST_EVENT" then
		MiniMap_ZDZD_UpdateZdzdState()
	end
	if event == "HIDE_ON_SCENE_TRANSED" then
		local curSceneID = GetSceneID(); --
		if curSceneID == 999 then
			MiniMap_Placename:Hide()
			MiniMap_Coordinate:Hide()
			MiniMap_Placename2:Show()
			MiniMap_Placename2:SetText("#{FHCL_240708_381}")
			
		else
			MiniMap_Placename:Show()
			MiniMap_Coordinate:Show()
			MiniMap_Placename2:Hide()
		end
	end
end
function MiniMap_OnShown()

	if g_Questionnaire == 1 then
		return
	end

	local UI_ID = Get_XParam_INT(0)
	if UI_ID == 1 then
		local  iscansee = Get_XParam_INT(1);
		if iscansee == 1 then
			--MiniMap_JiangHu:Hide();
			MiniMap_PlayerAsk2_Bn:Show();
			MiniMap_PlayerAsk2:Show();
			MiniMap_PlayerAsk2:SetToolTip("#{TLDC_110512_02}")
			g_diaochaAsk = tonumber(arg0)
		else
			MiniMap_PlayerAsk2_Bn:Hide();
			MiniMap_PlayerAsk2:Hide();
			MiniMap_JiangHu:Show();
		end
	end
end
function MiniMap_TimerProc()
	KillTimer("MiniMap_TimerProc()");		--关闭定时器
	--MiniMap_AccountSafeBack:Hide();
	MiniMap_AccountSafeFlash :Hide();

end

function MiniMap_FlashHuodong()

	--MiniMap_NetStatus_Flash:Play( true );
end

function MiniMap_StopFlashHuodong()
	--MiniMap_NetStatus_Flash:Play( false );
end

function MiniMap_UpdateLockFlag()
	local level = Player:GetData( "LEVEL" );
	if( Player:IsHavePassword() == nil ) then
		return
	elseif( Player:IsHavePassword() == 0 ) then --如果有没有密码呢，就闪烁
		MiniMap_SafeLock:SetProperty( "SetCurrentImage","red" );
		MiniMap_SafeLockState:SetProperty( "SetCurrentImage","Unlock" );
		if g_flash == 0 then
			MiniMap_SafeLockFlash:Show();
		end
	else
		MiniMap_SafeLock:SetProperty( "SetCurrentImage","green" );
		MiniMap_SafeLockFlash:Hide();

		--没有锁定就显示开开的锁的图片
		if ( Player:IsLocked() == nil ) then
			return
		elseif ( Player:IsLocked() == 0 ) then
			MiniMap_SafeLockState:SetProperty( "SetCurrentImage","Lock" );
		else
			MiniMap_SafeLockState:SetProperty( "SetCurrentImage","Unlock" );
		end
	end
	--蒙子控制
	if( tonumber( level ) <= 15 ) then
		MiniMap_SafeLock:SetProperty( "SetCurrentImage","gray" );
		MiniMap_SafeLockState:SetProperty( "SetCurrentImage","Unlock" );
		MiniMap_SafeLockFlash:Hide();
	end

	if( tonumber( IsInStall() ) == 1 ) then
		MiniMap_SafeLock:SetProperty( "SetCurrentImage","gray" );
		MiniMap_SafeLockFlash:Hide();
	end
end


function Minimap_UpdatePKMode()
	local nPKMode = Player:GetPKMode();
	if( tonumber( nPKMode ) == 0 ) then
		MiniMap_PK_Mode:SetProperty( "SetCurrentImage", "Peace" );
	else
		MiniMap_PK_Mode:SetProperty( "SetCurrentImage", "War" );
	end

	local strPKMode = ""
	if( tonumber( nPKMode ) == 0 ) then
		--MiniMap_PK_Mode:SetToolTip( "和平" );
		strPKMode = "和平\n此模式下只能反击攻击自己的玩家，不能主动攻击其他玩家。"
	elseif( tonumber( nPKMode ) == 1 ) then
		--MiniMap_PK_Mode:SetToolTip( "PK_FREE_FOR_ALL" );
		strPKMode = "个人混战"

	elseif( tonumber( nPKMode ) == 2 ) then
		--MiniMap_PK_Mode:SetToolTip( "PK_FREE_FOR_MORAL" );
		strPKMode = "善恶模式\n此模式下可以攻击杀气大于0的玩家。"

	elseif( tonumber( nPKMode ) == 3 ) then
		--MiniMap_PK_Mode:SetToolTip( "PK_FREE_FOR_TEAM" );
		strPKMode = "组队混战"

	elseif( tonumber( nPKMode ) == 4 ) then
		--MiniMap_PK_Mode:SetToolTip( "PK_FREE_FOR_GUILD" );
		strPKMode = "帮派同盟混战"
		--if IsInTServer() == 1 then
			--strPKMode = "#{TFJCGZ_20200817_22}"
		--end

	elseif( tonumber( nPKMode ) == 5 ) then
		strPKMode = "#{TDGZ_XML_19}"
	elseif( tonumber( nPKMode ) == 7 ) then
		strPKMode = "#{KVKBH_140124_48}"
	elseif( tonumber( nPKMode ) == 9) then
		strPKMode = "#{SLJC_150811_581}"
	end

	local strTime = ""
	local iTime = Player:GetTimeToPeace()

	if( -1 ~= iTime ) then
	    iTime = math.floor( iTime / 1000 )
	    local iSec = math.mod( iTime, 60 )
	    local iMin = math.floor( iTime / 60 )

	    --strTime = "#r("..( tonumber(iTime) ).."秒后切换到和平或善恶模式)"
	    if( iMin > 0 ) then
	        strTime = "#r"..(iMin).."分"..( tonumber(iSec) ).."秒后切换到和平或善恶模式"
	    else
	        strTime = "#r"..( tonumber(iSec) ).."秒后切换到和平或善恶模式"
	    end

	end

	MiniMap_PK_Mode:SetToolTip( strPKMode..strTime )


end
			--IMAGE_TYPE_Animy	= 0, // 敌人
			--IMAGE_TYPE_ExpNpc	= 1, // 特殊npc
			--IMAGE_TYPE_Team		= 2, // 队友
			--IMAGE_TYPE_Player	= 3, // 别的玩家
			--IMAGE_TYPE_ExpObj	= 4, // 生长点
			--IMAGE_TYPE_Active	= 5, // 激活方向点
			--IMAGE_TYPE_ScenePos = 6, // 场景跳转点
			--IMAGE_TYPE_Flash	= 7, // 闪光点
			--IMAGE_TYPE_Pet		= 8, // 宠物
			--IMAGE_TYPE_Direction = 9,// 方向箭头
function UpdateMinimapState()

		if GameProduceLogin:IsWeGameServer() > 0 then
			MiniMap_Forum:Hide();
		end
		this:Show();
		MiniMap_PosModify();
		Minimap_CoordinateUpdate();
		Minimap_UpdatePKMode();
		MiniMap_ZDZD_UpdateZdzdState()
end

--更新分线按钮显示
function UpdateFenxianState()
	-- 小服以及分线数量小于1
	local  bBigWorld= DataPool:Lua_GetIsBigWorld()
	if bBigWorld ~= 0 then
		MiniMap_Fenxian:Show()
	else
		MiniMap_Fenxian:Hide()
	end
end

function MiniMap_Update( parfilename )
	local sceneX, sceneY;
	local filename = parfilename
	if Player:GetData("IsOriginalJD") == 1 and g_JDTS_SceneMapFile[filename] then
		filename = g_JDTS_SceneMapFile[filename]
	end
	if Player:GetData("Is2606S") == 1 and g_2606S_SceneMapFile[filename] then
		filename = g_2606S_SceneMapFile[filename]
	end
	sceneX,sceneY = GetSceneSize();
	MiniMap_MapArea:SetSceneFileName( sceneX,sceneY,filename,1); 	--跨场景寻路修改，是否显示人物箭头
	MiniMap_Frame:SetForce();
end

function MiniMap_PosModify()
	if( this:IsVisible() ) then
		MiniMap_MapArea:UpdateFlag();
	end
end

function  MiniMap_OpenMinimapExp()

	OpenMinimap( "MinimapExp" );
	this:Hide();


end

function Minimap_Max()
	MiniMap_CloseButtons:Show()
	MiniMap_OpenButtons:Hide()
	MiniMap_Background_Frame:Show();
end

function Minimap_Min()
	MiniMap_CloseButtons:Hide()
	MiniMap_OpenButtons:Show()
	MiniMap_Background_Frame:Hide();
end

function Minimap_CoordinateUpdate()

	local coordinatex,coordinatey,direct;
	coordinatex, coordinatey = MiniMap_MapArea:GetMouseScenePos();
	MiniMap_Coordinate:SetText( "#cFDFF73"..tostring( coordinatex ).."  "..tostring( coordinatey ) );

	local hour = GetCurrentTime() + 1;
	MiniMap_ChineseTime:SetProperty("SetCurrentImage", "Time"..tostring( hour ) );

	if hour ~= g_MiniMap_NowDot and TimeDot[g_MiniMap_NowDot] ~= nil and TimeDot[hour] ~= nil then--时辰发生改变了才进行显隐切换
		--local oldTIme = g_MiniMap_NowDot
		TimeDot[g_MiniMap_NowDot]:Hide()
		TimeDot[hour]:Show();
		g_MiniMap_NowDot = hour--记录新的时辰点
		--PushDebugMessage("Minimap_CoordinateUpdateChangeHour:Old"..tostring(oldTIme).."newTime:"..tostring(g_MiniMap_NowDot))
	end
end

function MiniMap_HandleAccKey( op )
	if(op == "acc_zoommap" and this:IsVisible()) then
		MiniMap_OpenMinimapExp();
	elseif(op == "acc_resetcamera") then
		ResetCamera();
	elseif(op == "acc_worldmap") then
		ToggleLargeMap();
	end
end

function Do_OpenAutoSearch()
	OpenAutoSearch();
end

--function MiniMap_JiaYuanClick()
	--Clear_XSCRIPT()
		--Set_XSCRIPT_Function_Name( "OnOpenTLBBHome" )
		--Set_XSCRIPT_ScriptID( 890020 )
		--Set_XSCRIPT_ParamCount(0)
	--Send_XSCRIPT()

	--if "MiniMap" == GetFreshManGuideOwner() then
       -- CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
  -- end

--end

--function MiniMap_JiaYuanOpen()
	--OpenFlash()
--end

function MiniMap_YuanBaoFunc()
	if (IsWindowShow("XuanShop")) then
		--CloseWindow("XuanShop", true);
		ToggleXuanShop()
	elseif (IsWindowShow("ShowShop")) then
		PushEvent("TOGGLE_SHOWSHOP")
	else
		ToggleYuanbaoShop()
	end
end

-- 活跃玩家送好礼 by cys
function MiniMap_HuoyuehaoliFunc()
	OpenHuoYueHaoLi()
	--MiniMap_Huoyuehaoli_Ani:Play( false );
end

--周活跃好礼  by liubo
function MiniMap_WeekHuoyuehaoliFunc()
	OpenWeekHuoyuehaoli()
	--MiniMap_WeekhuoyuehaoliAnimate:Play( false );
end
function MiniMap_OpenSafeTimeDlg()
	OpenSafeTime();
end

function MiniMap_LockFunc()
	g_flash = 1
MiniMap_SafeLockFlash:Hide()
	local leader = Player:IsLeader();
  if(leader == 1) then
  else
		if(Player:InTeamFollowMode()) then
			PushDebugMessage("#{GMAI_Base_Info_Team_Follow_Staus}")
			PushDebugMessage("#{GMAI_Base_Info_Not_Allow_Operate}")
			return
		end
	end


	if( tonumber( IsInStall() ) == 0 ) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnDefaultEvent");
			Set_XSCRIPT_ScriptID(808007);
			Set_XSCRIPT_Parameter(0,808007);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end
end

function MiniMap_GotoDirectly()
	local coordinatex,coordinatey;
	coordinatex, coordinatey = MiniMap_MapArea:GetMouseScenePos();
	AutoRunToTarget(coordinatex, coordinatey);
end

function MiniMap_NetStatus_MouseEnter()
end

function MiniMap_NetStatus_MouseLeave()

end

function MiniMap_NetStatus_MouseLButtonDown()
	--OpenTodayCampaignList();
	--MiniMap_NetStatus_Flash:Play( false );
end

function MiniMap_AccountSafeFunc()
	--MiniMap_AccountSafeBack:Hide();
	MiniMap_AccountSafeFlash : Hide();
	OpenWordrefence("AccountSafe");
end

function MiniMap_Fangchengmi_Click()
	OpenFangChenMiInfoDlg();
end

function MiniMap_PlayerAsk_Bn_Clicked()
	local menpai = Player:GetData("MEMPAI");
	local strName = "";

	-- 得到门派名称.
	if(0 == menpai) then
		strName = "少林";

	elseif(1 == menpai) then
		strName = "明教";

	elseif(2 == menpai) then
		strName = "丐帮";

	elseif(3 == menpai) then
		strName = "武当";

	elseif(4 == menpai) then
		strName = "峨嵋";

	elseif(5 == menpai) then
		strName = "星宿";

	elseif(6 == menpai) then
		strName = "天龙";

	elseif(7 == menpai) then
		strName = "天山";

	elseif(8 == menpai) then
		strName = "逍遥";

	elseif(9 == menpai) then
		strName = "无门派";

	elseif(10== menpai) then
		strName = "慕容";

	elseif(11== menpai) then
		strName = "唐门";

	elseif(12== menpai) then
		strName = "鬼谷";
	elseif(13== menpai) then
		strName = "桃花岛"; --桃花岛
	elseif(14== menpai) then
		strName = "绝情谷"; 
	elseif(15== menpai) then--menpai15 mptodo
		strName = "恶人谷"; 
	end

	local urlStr = "{gameName:tlbb";
	urlStr = urlStr..",accountId:"..Player:GetData("ACCOUNTNAME");

	local idWorld = Variable:GetVariable("Login_World")
	if idWorld ~= nil then
		urlStr = urlStr..",serverId:"..idWorld
	end

	urlStr = urlStr..",roleName:"..Player:GetName()

	local szGuid = GetSelfGUID();
	urlStr = urlStr..",roleId:"..ConvertGuidToShow( szGuid )
	urlStr = urlStr..",roleGrade:"..Player:GetData("LEVEL")
	urlStr = urlStr..",vipGrade:"..DataPool:GetAccVipLevel()
	urlStr = urlStr..",Profession:"..strName	--门派
	urlStr = urlStr..",gameVersion:"..GetGameVersion();
	urlStr = urlStr.."}";

	local vcode = CalciDiaoYanVCode(urlStr.."345341234567353534/Vo48a31bd=");   --后面是SECRET_KEY
	urlStr = ConvertStringToURLCoding(urlStr)
	GameProduceLogin:OpenURL( GetWeblink("WEB_ACTIVITY_SEARCH")..tostring(g_myAsk).."/?appdata="..urlStr.."&vcode="..vcode );
	MiniMap_PlayerAsk_Bn:Hide();
	MiniMap_PlayerAsk:Hide();
	--MiniMap_SuperHelp2:Show();
end

function MiniMap_LiebiaoFunc()
	Guild:AskGuildNameList();
end

function MiniMap_KeFu()
	--local vipLevel = DataPool:GetVipLevel()
	--if g_AccVipLevel < 1 then
	--	PushDebugMessage( "#{FWNQ_141013_03}" )
	--	return
	--end
	if 1 ~= g_OpenServiceCenter then
		PushDebugMessage( "#{FWNQ_141013_02}" )
		return
	end
	if GameProduceLogin:IsWeGameClient() <= 0 then
		OpenCustomerService( 0 )
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_ANQUANZHONGXIN_KFZX"))
	end
	
end
--bug反馈
function MiniMap_BugFeedBack()
	OpenBugFeedBack();
end
function MiniMap_PlayerAsk2_Bn_Clicked()

	if g_Questionnaire == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClickQuestionnaire")
			Set_XSCRIPT_ScriptID(880048)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
--	else
--		Clear_XSCRIPT();
--			Set_XSCRIPT_Function_Name("AskQuestion");
--			Set_XSCRIPT_ScriptID(889396);
--			Set_XSCRIPT_ParamCount(0);
--		Send_XSCRIPT();
	end

	--MiniMap_PlayerAsk2_Bn:Hide();
	--MiniMap_PlayerAsk2:Hide();
	--MiniMap_JiangHu:Show();
end

--邮件提示
function MinMap_Mail_ClickFlash()
	PushEvent("UPDATE_MESSAGEMAIL",g_bNewMailTip)
	--MiniMap_MailAnimate:Play( false )
end


function MiniMap_ChangeButtonTip()
	local noChatActiveMode = Variable:GetVariable("NonChatActive");
	if noChatActiveMode == "1" then
		MiniMap_North				:SetToolTip("#{JPYD_130822_12}")
		MiniMap_Liebiao			:SetToolTip("#{JPYD_130822_18}")
		MiniMap_AutoSearch	:SetToolTip("#{JPYD_130822_13}")
		MiniMap_WorldMap		:SetToolTip("#{JPYD_130822_16}")
		MiniMap_Plot				:SetToolTip("#{JPYD_130822_14}")
	else
		MiniMap_North				:SetToolTip("#{INTERFACE_XML_869}")
		MiniMap_Liebiao			:SetToolTip("#{FJWJ_081106_01}")
		MiniMap_AutoSearch	:SetToolTip("#{INTERFACE_XML_983}")
		MiniMap_WorldMap		:SetToolTip("#{INTERFACE_XML_645}")
		MiniMap_Plot				:SetToolTip("#{INTERFACE_XML_233}")
	end
end

--拙计的新安全中心
function MiniMap_OpenSafeCenterDlg()
	--OpenSafeCenter();
	if IsTBFinalServer() >= 1 then
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end

    PushEvent("OPEN_SAFECENTER_SAFESCORE");
end

--**********************************
--打开新服欢乐月  -- 现在时新手欢乐月
--**********************************
function MiniMap_XinfuOpen()
--	if(IsWindowShow("ServerNew")) then
--		CloseWindow("ServerNew", true)
--		return
--	end
--
--	--在K服不显示新服欢乐月界面
--	if KVKInterface:IsInKVKServer() == 1 then
--		PushDebugMessage("#{XFHD_140919_16}")
--		return
--	end
--
--	--在T服也不显示新服欢乐月界面
--	if IsInTServer() == 1 then
--		PushDebugMessage("#{XFHD_140919_17}")
--		return
--	end
--
--	-- 动态提示
--	MiniMap_Xinfu : PlayWarning( 0 );
--	-- 打开引导界面
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name( "OnOpenXinFuHuanLeYue" )
--		Set_XSCRIPT_ScriptID( 890933 )
--		Set_XSCRIPT_ParamCount(0)
--	Send_XSCRIPT()
	if(IsWindowShow("XinShouYue")) then
		CloseWindow("XinShouYue", true)
		return
	end

	--在K服不显示新手欢乐月界面
	--if KVKInterface:IsInKVKServer() == 1 then
	--	PushDebugMessage("#{XFHD_140919_16}")
	--	return
	--end

	--在T服也不显示新服欢乐月界面
	-- if IsInTServer() == 1 then
	-- 	PushDebugMessage("#{XSHLY_150522_2}")
	-- 	return
	-- end

	--争霸赛服务器不显示
	if IsZbs2018SpeicalServer() >= 1 then
		PushDebugMessage("#{WCBS_180307_20}")
		return
	end

	if IsDfsSpeicalServer() >= 1 then
		PushDebugMessage("#{SJDF_190603_01}")
		return
	end
	
	-- 动态提示
	MiniMap_Xinfu : PlayWarning( 0 );
	-- 打开引导界面
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenXinShouHuanLeYue" )
		Set_XSCRIPT_ScriptID( 891107 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--**********************************
--新服欢乐月按钮闪烁 -- 现在时新手欢乐月
--**********************************
function MiniMap_XinfuPlayWarning( )
	MiniMap_Xinfu : PlayWarning( 1 );
end

function MiniMap_RedPointShow( IsShow )
	if MiniMap_Xinfutips == nil then
		return
	end
	if IsShow == 1 then
		MiniMap_Xinfutips:Show()
	else
		MiniMap_Xinfutips:Hide()
	end
end

--**********************************
-- 首开卡UI
--**********************************
function MiniMap_UpdateShouKaiKaUI( nIndex )

	-- 等级
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		MiniMap_Shouchong : Hide();
		return
	end

	-- 三档奖励 和 限时奖励
	local Count = 0;
	for i = 1, table.getn( MiniMapMFShouKaiKaStep ) do
		if ( MiniMapMFShouKaiKaStep[ i ] == 1 ) then
			Count = Count + 1;
		end
	end
	if ( Count >= table.getn( MiniMapMFShouKaiKaStep ) ) then
		
		MiniMap_Shouchong : Hide();
		return
	end

	-- 前三档奖励领取完毕, 限时奖励超时
	if ( Count >= table.getn( MiniMapMFShouKaiKaStep ) - 1 and nShouChongLimitTime == -2 ) then
		
		MiniMap_Shouchong : Hide();
		return
	end
	-- 前三档奖励领取完毕, 限时奖励未达成
	if ( Count >= table.getn( MiniMapMFShouKaiKaStep ) - 1 and nShouChongLimitTime == 0 ) then
		MiniMap_Shouchong : Hide();
		return
	end

	-- 显示/隐藏
	MiniMap_Xinfu:Hide()  --现在新手欢乐月

	if IsTBFinalServer() <= 0 then
		MiniMap_Shouchong : Show();

		if DataPool:Lua_GetUpdateTipsFlag( 38 ) == 1 then
			MiniMap_Shouchongtips:Show()
		else
			MiniMap_Shouchongtips:Hide()
		end
	end

end

--**********************************
-- 请求首开卡按钮状态
--**********************************
function MiniMap_UpdateShouKaiButtonStateReq()

	-- 等级
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		return
	end

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 889853 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()

end

--**********************************
-- 反馈首开卡按钮状态
--**********************************
function MiniMap_UpdateShouKaiButtonStateAck()

	-- 更新UI
	MiniMap_UpdateShouKaiKaUI()
end

--**********************************
-- 首开卡
--**********************************
function MiniMap_ShouKaiKa( )

	if IsInTServer() == 1 then
--		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	-- 打开UI
	OpenShouKaiKaUI();

end

--**********************************
-- 请求打开
--**********************************
function MiniMap_ClickFourLuckyBoy( )
	if(IsWindowShow("XinShouYue")) then
		CloseWindow("XinShouYue", true)
		return
	end
	if(IsWindowShow("XinShouNew")) then
		CloseWindow("XinShouNew", true)
		return
	end
	if(IsWindowShow("XinShouNew_Over")) then
		CloseWindow("XinShouNew_Over", true)
		return
	end
	if(IsWindowShow("PayReward")) then
		CloseWindow("PayReward", true)
		return
	end

	MiniMap_Xinfu:PlayWarning( 0 );
	MiniMap_XinShouNew:PlayWarning( 0 );
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClickFourLuckyBoy" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 891107 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()

end
--**********************************
--	打开论坛
--**********************************
function MiniMap_OpenForum()
    GameProduceLogin:OpenURL(GetWeblink("WEB_TLLUNTAN"))
	CloseFreshManGuide();
	MiniMap_Forum : PlayWarning( 0 )
	MiniMap_Forum : SetToolTip("#{NQLT_141118_01}")
end

--**********************************
--	打开论坛按钮的浮动tips
--**********************************
function MiniMap_OpenForumTips(srvTime)

	--if srvTime < 20141225 or srvTime > 20141231 then
	--	return
	--end

	local fX = 0
	local fY = 0

	fX, fY = this:GetChildOffset("MiniMap_Forum")

	fX = fX
	fY = fY + 10
	OpenFreshManGuide(1, 62, fX, fY, "MiniMap", "southwest")
	--图标闪烁
	MiniMap_Forum : PlayWarning( 1 )

	MiniMap_Forum : SetToolTip("")

	--设置闪烁冷却时间
	SetTimer("MiniMap", "MiniMap_PlayWarning()",g_BBSFlashdown)

end

--===============================================
-- 闪烁计时结束()
--===============================================
function MiniMap_PlayWarning()
	--图标闪烁消失
	MiniMap_Forum : PlayWarning( 0 )
	MiniMap_Forum : SetToolTip("#{NQLT_141118_01}")
	--浮动tips消失
	CloseFreshManGuide()
	--闪烁计时停止
	KillTimer("MiniMap_PlayWarning()")
end

function MiniMap_XuanZhanList()
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
  	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end

	local guildID, clanID = DataPool:GetGuildClanID();
	if guildID < 0 then
		PushDebugMessage("#{BHXZ_150831_44}");
		return;
	end

--	local nRankListNum  = City:GetBattleRankListNum();
--	local nRankListNumK = City:GetBattleRankListNum_K();
--
--	if nRankListNum <= 0 and nRankListNumK <= 0 then
--		PushDebugMessage("#{BHXZ_150831_45}");
--		return;
--	end
	City:OpenGuildBattleListDlg();
	g_ButtonLastTime = curTime;
end

--分线
function MiniMap_FenxianClicked()
	DataPool:OpenFenxianDlg()
	MiniMap_FenxianFlashUpdata(false)
end

function MiniMap_Questionnaire(nShow , nFlash)

	if nShow == 1 then
		MiniMap_PlayerAsk2_Bn:Show()

		if nFlash == 0 then
			MiniMap_PlayerAsk2:Show()
			MiniMap_PlayerAsk2:SetToolTip("#{TLDC_110512_02}")
			KillTimer("MiniMap_QuestionnaireTick()")
			SetTimer("MiniMap","MiniMap_QuestionnaireTick()", 10000)
			g_QuestionnaireTickCount = 0
		else
			MiniMap_PlayerAsk2:Hide()
		end
		g_Questionnaire = 1
	else
		MiniMap_PlayerAsk2_Bn:Hide()
		MiniMap_PlayerAsk2:Hide()
		g_Questionnaire = 0
	end
end

function MiniMap_QuestionnaireTick()

	g_QuestionnaireTickCount = g_QuestionnaireTickCount + 1
	if g_QuestionnaireTickCount >= 3 then
		MiniMap_PlayerAsk2:Hide()
		KillTimer("MiniMap_QuestionnaireTick()")

	end
end

function MiniMap_Questionnaire_OpenURL()
	MiniMap_PlayerAsk2:Hide()
	GameProduceLogin:OpenURL( GetWeblink("WEB_TLDIAOYAN") )
end

--武器 防具 武具 龙纹 令牌 豪侠印 武魂 珍兽
function MiniMap_EquipEnduranceToolTip(wuqi,fangju,wuju,longwen,lingpai,haoxiayin,wuhun,zhenshou)
	local tooltip=""
	local equipStr=""
	if wuqi>0 then
		equipStr="#{XHRYH_170608_03}"--武器
	end
	if fangju>0 then
		if equipStr~="" then
			equipStr=equipStr.."#{XHRYH_170608_02}"
		end
		equipStr=equipStr..fangju.."#{XHRYH_170608_04}"
	end
	if wuju>0 then
		if equipStr~="" then
			equipStr=equipStr.."#{XHRYH_170608_02}"
		end
		equipStr=equipStr..wuju.."#{XHRYH_170608_05}"
	end
	if longwen>0 then
		if equipStr~="" then
			equipStr=equipStr.."#{XHRYH_170608_02}"
		end
		equipStr=equipStr.."#{XHRYH_170608_06}"
	end
	if lingpai>0 then
		if equipStr~="" then
			equipStr=equipStr.."#{XHRYH_170608_02}"
		end
		equipStr=equipStr.."#{XHRYH_170608_07}"
	end
	if equipStr~="" then
		tooltip=ScriptGlobal_Format("#{XHRYH_170608_01}",equipStr)
	end
	if haoxiayin>0 then
		if tooltip~="" then
			tooltip=tooltip.."#r"
		end
		tooltip=tooltip.."#{XHRYH_170608_08}"
	end
	if wuhun>0 then
		if tooltip~="" then
			tooltip=tooltip.."#r"
		end
		tooltip=tooltip.."#{XHRYH_170608_09}"
	end
	if zhenshou>0 then
		if tooltip~="" then
			tooltip=tooltip.."#r"
		end
		tooltip=tooltip.."#{XHRYH_170608_10}"
	end
	MiniMap_EquipEndurance:SetToolTip(tooltip);
end

function MiniMap_EquipRepair_MouseEnter()
	if((not this:IsVisible())) then
		return;
	end
	local wuqi,fangju,wuju,longwen,lingpai,haoxiayin,wuhun,zhenshou=LifeAbility:GetEquipRepairInfo()
	MiniMap_EquipEnduranceToolTip(wuqi,fangju,wuju,longwen,lingpai,haoxiayin,wuhun,zhenshou)
end

function MiniMap_MapName_MouseEnter()
	MiniMap_Placename : SetToolTip("")
	local curSceneID = GetSceneServerID()
	local t300SceneType = DataPool:GetT300SceneIDManagerTSceneTypeID(curSceneID)
	if t300SceneType < 0 then
		return
	end
	if t300SceneType == 4511 then
		--汴京
		MiniMap_Placename : SetToolTip("#{TWFX_200814_14}")
	elseif t300SceneType == 5006 then
		--金陵
		MiniMap_Placename : SetToolTip("#{TWFX_200814_13}")
	end
end

function MiniMap_ZDZD_UpdateZdzdState()
	local ret = BattleAssist:IsWorking()
	if ret == "true" or (AutoAttack_Button_GetAutoFBKey(ret) and AutoAttack_Button_GetFBKeyAndBranchName()) then
		local key1,key2 = SystemSetup:GetInputSetup(10 + 56)
		local keystr = ScriptGlobal_Format("#{ZDZD_200724_04}", key2)
		MiniMap_AutoAttack_Button:SetToolTip("#{ZDZD_200724_03}".."#r"..keystr)
		MiniMap_AutoAttack_Button:Show()
		MiniMap_AutoAttack_Button_Off:Hide()
	else
		local key1,key2 = SystemSetup:GetInputSetup(10 + 56)
		local keystr = ScriptGlobal_Format("#{ZDZD_200724_02}",key2)
		MiniMap_AutoAttack_Button_Off:SetToolTip("#{ZDZD_200724_01}".."#r"..keystr)
		MiniMap_AutoAttack_Button_Off:Show()
		MiniMap_AutoAttack_Button:Hide()
	end
end

-- 开启自动战斗
function MiniMap_ZDZD_OnClick()
	local fb_key, branch = AutoAttack_Button_GetFBKeyAndBranchName()
	local ng_run = BattleAssist:IsWorking()

	-- 在副本场景中，且服务器允许开启内挂
	if fb_key and BattleAssist:AskIsNeiGuaOpen("FB") then
		if branch ~= ng_run then
			-- 开启自动副本
			if MiniMap_CheckOpenAutoFB() == 1 then
				BattleAssist:Start("FB", fb_key)
			end
		else
			-- 关闭自动副本
			BattleAssist:Stop()
		end
		return
	end

	if ng_run == "true" then
		-- 开启自动战斗
		PushEvent("TRIGGER_ZIDONGZHANDOU","stop")
	else
		-- 关闭自动战斗
		PushEvent("TRIGGER_ZIDONGZHANDOU","start")
	end
end

--开启录制
function MiniMap_LuzhiFunc()
	StartTLBBRecorderByMain()
	PushDebugMessage("#{KHD_220826_56}")
end

-- 检查开启自动打副本的条件
function MiniMap_CheckOpenAutoFB()
	if not BattleAssist:CheckConditions("FB") then
		return 0
	end
	
	return AutoAttack_Button_CheckOpenAutoFB()
end

-- 弹窗回调
function MiniMap_OnComfirmed_QianKun(strRet)
	if nil == strRet then
		return
	end
	if "Yes" == strRet or "Ok" == strRet then
		local fb_key, _ = AutoAttack_Button_GetFBKeyAndBranchName()
		if fb_key ~= nil then
			BattleAssist:Start("FB", fb_key)
		end
	end
end

function MiniMap_FenxianFlashUpdata(bshow)
	if bshow and  MiniMap_OpenButtons:IsVisible() then
		Minimap_Max()
	end

	if bshow then
		MiniMap_Fenxian_Flash:Show()	

		local fX = 0
		local fY = 0
		local nPosX = tonumber(MiniMap_Frame:GetProperty("AbsoluteXPosition"))
		local nPosY = tonumber(MiniMap_Frame:GetProperty("AbsoluteYPosition"))
		fX, fY = this:GetChildOffset("MiniMap_Fenxian")
		local fH = tonumber(MiniMap_Fenxian:GetProperty("AbsoluteHeight"))
		local fW = tonumber(MiniMap_Fenxian:GetProperty("AbsoluteWidth"))

		fX = math.floor(tonumber(fX + nPosX + fW / 2))
		fY = math.floor(tonumber(fY + nPosY + fH + 119))
		OpenFreshManGuideNew(1, fX, fY, fW, fH, 30, 0, "MiniMap")

	else
		MiniMap_Fenxian_Flash:Hide()
	end
end

function MiniMap_OnFindExp()
	PushEvent("PKEXP_REGAIN_OPEN", 0);
end