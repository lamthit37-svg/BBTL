local MAINMENUBAR_BUTTON_NUM = 30
local index_mainbar = -1 --20150701-七夕交互任务-by yuanpeilong
local MAINMENUBAR_PAGENUM = 0;	-- 0, 1, 2
local MAINMENUBAR_BUTTONS = {};
local COMBOSKILL_FLASH_JUNIOR = {};
local COMBOSKILL_FLASH_SENIOR = {};
local g_switchmenpaiIdx = 0;

local bExchangeFlash = 0;
local iTeamInfoType = 0;	-- -1 : 表示没有队伍信息
													-- 0  : 表示打开队伍信息
													-- 1  : 表示有人申请加入队伍,   打开申请列表.
													-- 2  : 表示有人邀请你加入队伍, 打开邀请你的队伍列表.


local bTogleSelfEquip = 0;	-- 0 ：当前状态是关闭界面
														-- 1 ：当前状态是打开界面
														-- 1 : 当前状态是打开界面

local bTogleTeam			= 0;  -- 0 : 当前状态是关闭界面
														-- 1 : 当前状态是打开界面

local bIsTeamBnFlash	= 0;	-- 0 : 组队按钮没闪烁.
														-- 1 : 组队按钮闪烁.

local bIsPacketOpened = 0 --背包状态（0关闭，1打开）

local bMainMenuBar_2Open = 0--MainMenuBar_2是否在打开状态

local nMenpaiSkillId = {};
nMenpaiSkillId[1] = {281,291,295,282,302};
nMenpaiSkillId[2] = {311,321,325,312,332};
nMenpaiSkillId[3] = {341,351,355,342,362};
nMenpaiSkillId[4] = {371,381,385,392};
nMenpaiSkillId[5] = {401,404,415,402,422,411};
nMenpaiSkillId[6] = {431,441,445,432,452};
nMenpaiSkillId[7] = {461,471,475,462,482};
nMenpaiSkillId[8] = {491,501,505,492,512};
nMenpaiSkillId[9] = {521,522,535,542};
--10是无门派
nMenpaiSkillId[11] = {760,771,775,761,762};
nMenpaiSkillId[12] = {2900,2901,2902,2911,2915};
nMenpaiSkillId[13] = {3430,3431,3432,3441,3445};
nMenpaiSkillId[14] = {3800,3801,3802,3811,3815,3804}; --桃花岛
nMenpaiSkillId[15] = {4515,4517,4538}; --从刃
nMenpaiSkillId[16] = {4622,4633,4637,4623,4624}; --menpai15

local MAINMENUBAR_ACCKEY = {};
local g_CharcaterFlash = falas;
-- 经验满提示标记 是否第一次登陆
local g_bFirstLogin = true;

local g_ShowCharSelf = 0
local g_ShowCharSelf2 = 0
local g_NeedTipID = -1

function MainMenuBar_PreLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true);
	this:RegisterEvent("CHANGE_BAR",true);
	this:RegisterEvent("RECEIVE_EXCHANGE_APPLY",true);
	this:RegisterEvent("TEAM_NOTIFY_APPLY",true);					-- 注册有人申请加入队伍事件.

	this:RegisterEvent("HAVE_MAIL",true);
	this:RegisterEvent("HAVE_IM_MSG",true);

	this:RegisterEvent("UNIT_EXP",true);
	this:RegisterEvent("UNIT_LEVEL",true);
	this:RegisterEvent("UNIT_MAX_EXP",true);
	this:RegisterEvent("ACCELERATE_KEYSEND",true);
	this:RegisterEvent("CHAT_ADJUST_MOVE_CTL",true);

	this:RegisterEvent("UPDATE_DUR",true);
	this:RegisterEvent("JOIN_NEW_MENPAI",true);
	this:RegisterEvent("ACTION_UPDATE",true);

	this:RegisterEvent("NEW_MISSION",true);

	this:RegisterEvent("UPDATESTATE_SUBMENUBAR",true);

	this:RegisterEvent("SHOW_GUILDWAR_ANIMI",true);
	this:RegisterEvent("UPDATE_GUILD_APPLY",true);
	this:RegisterEvent("BATTLE_SCOREFLASH",true);
	this:RegisterEvent("NOTIFY_NEW_SKILLS",true);

	--[xh 2009-07-09]只有在帮派征讨时才显示帮派征讨积分按钮
	this:RegisterEvent("SCENE_TRANSED",true);
	this:RegisterEvent("FLASH_PACKET_BUTTON",true);
	this:RegisterEvent("PACKET_OPENED",true);

	this:RegisterEvent("UNINSTALL_CHAT_ACTION_BAR",true);					-- 卸载主菜单上的双人聊天动作按钮
	this:RegisterEvent("CLEAR_CHAT_ACTION_BAR",true);							-- 清理主菜单上过期的双人聊天动作按钮
	this:RegisterEvent("SKILL_UPDATE",true)									--停闪组队按钮
	this:RegisterEvent("SWITCHMENPAI",true)									--停闪组队按钮

	this:RegisterEvent("UNFLASH_TEAM_BUTTON",true)									--停闪组队按钮
	this:RegisterEvent("RAID_UPDATE_INVITATION",true)
	--变身系统增加
	--this:RegisterEvent("SWITCH_MENU_BUTTON")
	this:RegisterEvent("SHOW_TRANSFIGURATION_SKILL",true);
    --- 势力相关

    --- 战盟相关
	this:RegisterEvent("UPDATE_UNION_INVITE_APPLY",true);
	this:RegisterEvent("NOTIFY_POP_UITIP",true);
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("FINISH_MISSION",true)

	this:RegisterEvent("RESET_ALLUI",true)
	this:RegisterEvent("OPEN_UP_BAR_2",true)
	this:RegisterEvent("COMBO_SKILL",true)
	this:RegisterEvent("FLASH_COMBOSKILL",true)
	this:RegisterEvent("HIDE_THIS_UI",true)
	this:RegisterEvent("HAVE_GSIM_MSG",true)
	this:RegisterEvent("HAVE_GSIM_MSG_NEW",true)
	this:RegisterEvent("UPDATE_DOUBLE_EXP",true)
	this:RegisterEvent("ADJEST_UI_POS",false) 
	--角色出售挽留通知设计
	this:RegisterEvent("PHONY_INFOBROWSER_OPEN",true);
	this:RegisterEvent("MARTIAL_UPDATE",true)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",true)
    this:RegisterEvent("UPDATE_REDPOINT_IN_UI",false)
	this:RegisterEvent("UPDATE_EXTERIOR_TIP", true)
	this:RegisterEvent("UPDATE_TOY_TIP", true)
	this:RegisterEvent("CANGPIN_UPDATE", true)
	this:RegisterEvent("DYZCOMBO_SKILL",true)
	this:RegisterEvent("LMSJCOMBO_SKILL",true)
	this:RegisterEvent("JYJYCOMBO_SKILL",true)
	this:RegisterEvent("WJQFCOMBO_SKILL",true)
	this:RegisterEvent("MPCOMBO_SKILL",true)
	
	this:RegisterEvent("NEIDAN_CHIP_UPDATE", true)

	this:RegisterEvent("CHAT_SIGN_RED_POINT", true)
	this:RegisterEvent("HIDE_CHATSIGN_REDPOINT", true)
	this:RegisterEvent("TLCJ_BASEATTRUPDATE", true)
end

function MainMenuBar_OnLoad()
	MAINMENUBAR_BUTTONS[1] = Button_Action1;
	MAINMENUBAR_BUTTONS[2] = Button_Action2;
	MAINMENUBAR_BUTTONS[3] = Button_Action3;
	MAINMENUBAR_BUTTONS[4] = Button_Action4;
	MAINMENUBAR_BUTTONS[5] = Button_Action5;
	MAINMENUBAR_BUTTONS[6] = Button_Action6;
	MAINMENUBAR_BUTTONS[7] = Button_Action7;
	MAINMENUBAR_BUTTONS[8] = Button_Action8;
	MAINMENUBAR_BUTTONS[9] = Button_Action9;
	MAINMENUBAR_BUTTONS[10] = Button_Action10;

	MAINMENUBAR_BUTTONS[11] = Button_Action11;
	MAINMENUBAR_BUTTONS[12] = Button_Action12;
	MAINMENUBAR_BUTTONS[13] = Button_Action13;
	MAINMENUBAR_BUTTONS[14] = Button_Action14;
	MAINMENUBAR_BUTTONS[15] = Button_Action15;
	MAINMENUBAR_BUTTONS[16] = Button_Action16;
	MAINMENUBAR_BUTTONS[17] = Button_Action17;
	MAINMENUBAR_BUTTONS[18] = Button_Action18;
	MAINMENUBAR_BUTTONS[19] = Button_Action19;
	MAINMENUBAR_BUTTONS[20] = Button_Action20;

	MAINMENUBAR_BUTTONS[21] = Button_Action21;
	MAINMENUBAR_BUTTONS[22] = Button_Action22;
	MAINMENUBAR_BUTTONS[23] = Button_Action23;
	MAINMENUBAR_BUTTONS[24] = Button_Action24;
	MAINMENUBAR_BUTTONS[25] = Button_Action25;
	MAINMENUBAR_BUTTONS[26] = Button_Action26;
	MAINMENUBAR_BUTTONS[27] = Button_Action27;
	MAINMENUBAR_BUTTONS[28] = Button_Action28;
	MAINMENUBAR_BUTTONS[29] = Button_Action29;
	MAINMENUBAR_BUTTONS[30] = Button_Action30;

	MAINMENUBAR_BUTTONS[51] = Button_Action51;
	MAINMENUBAR_BUTTONS[52] = Button_Action52;
	MAINMENUBAR_BUTTONS[53] = Button_Action53;
	MAINMENUBAR_BUTTONS[54] = Button_Action54;
	MAINMENUBAR_BUTTONS[55] = Button_Action55;
	MAINMENUBAR_BUTTONS[56] = Button_Action56;
	MAINMENUBAR_BUTTONS[57] = Button_Action57;
	MAINMENUBAR_BUTTONS[58] = Button_Action58;
	MAINMENUBAR_BUTTONS[59] = Button_Action59;
	MAINMENUBAR_BUTTONS[60] = Button_Action60;

	COMBOSKILL_FLASH_JUNIOR[1] = MainMenuBar_Button1_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[2] = MainMenuBar_Button2_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[3] = MainMenuBar_Button3_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[4] = MainMenuBar_Button4_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[5] = MainMenuBar_Button5_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[6] = MainMenuBar_Button6_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[7] = MainMenuBar_Button7_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[8] = MainMenuBar_Button8_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[9] = MainMenuBar_Button9_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[10] = MainMenuBar_Button10_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[11] = MainMenuBar_Button1_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[12] = MainMenuBar_Button2_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[13] = MainMenuBar_Button3_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[14] = MainMenuBar_Button4_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[15] = MainMenuBar_Button5_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[16] = MainMenuBar_Button6_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[17] = MainMenuBar_Button7_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[18] = MainMenuBar_Button8_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[19] = MainMenuBar_Button9_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[20] = MainMenuBar_Button10_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[21] = MainMenuBar_Button1_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[22] = MainMenuBar_Button2_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[23] = MainMenuBar_Button3_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[24] = MainMenuBar_Button4_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[25] = MainMenuBar_Button5_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[26] = MainMenuBar_Button6_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[27] = MainMenuBar_Button7_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[28] = MainMenuBar_Button8_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[29] = MainMenuBar_Button9_junior_Flash
	COMBOSKILL_FLASH_JUNIOR[30] = MainMenuBar_Button10_junior_Flash

	COMBOSKILL_FLASH_SENIOR[1] = MainMenuBar_Button1_senior_Flash
	COMBOSKILL_FLASH_SENIOR[2] = MainMenuBar_Button2_senior_Flash
	COMBOSKILL_FLASH_SENIOR[3] = MainMenuBar_Button3_senior_Flash
	COMBOSKILL_FLASH_SENIOR[4] = MainMenuBar_Button4_senior_Flash
	COMBOSKILL_FLASH_SENIOR[5] = MainMenuBar_Button5_senior_Flash
	COMBOSKILL_FLASH_SENIOR[6] = MainMenuBar_Button6_senior_Flash
	COMBOSKILL_FLASH_SENIOR[7] = MainMenuBar_Button7_senior_Flash
	COMBOSKILL_FLASH_SENIOR[8] = MainMenuBar_Button8_senior_Flash
	COMBOSKILL_FLASH_SENIOR[9] = MainMenuBar_Button9_senior_Flash
	COMBOSKILL_FLASH_SENIOR[10] = MainMenuBar_Button10_senior_Flash
	COMBOSKILL_FLASH_SENIOR[11] = MainMenuBar_Button1_senior_Flash
	COMBOSKILL_FLASH_SENIOR[12] = MainMenuBar_Button2_senior_Flash
	COMBOSKILL_FLASH_SENIOR[13] = MainMenuBar_Button3_senior_Flash
	COMBOSKILL_FLASH_SENIOR[14] = MainMenuBar_Button4_senior_Flash
	COMBOSKILL_FLASH_SENIOR[15] = MainMenuBar_Button5_senior_Flash
	COMBOSKILL_FLASH_SENIOR[16] = MainMenuBar_Button6_senior_Flash
	COMBOSKILL_FLASH_SENIOR[17] = MainMenuBar_Button7_senior_Flash
	COMBOSKILL_FLASH_SENIOR[18] = MainMenuBar_Button8_senior_Flash
	COMBOSKILL_FLASH_SENIOR[19] = MainMenuBar_Button9_senior_Flash
	COMBOSKILL_FLASH_SENIOR[20] = MainMenuBar_Button10_senior_Flash
	COMBOSKILL_FLASH_SENIOR[21] = MainMenuBar_Button1_senior_Flash
	COMBOSKILL_FLASH_SENIOR[22] = MainMenuBar_Button2_senior_Flash
	COMBOSKILL_FLASH_SENIOR[23] = MainMenuBar_Button3_senior_Flash
	COMBOSKILL_FLASH_SENIOR[24] = MainMenuBar_Button4_senior_Flash
	COMBOSKILL_FLASH_SENIOR[25] = MainMenuBar_Button5_senior_Flash
	COMBOSKILL_FLASH_SENIOR[26] = MainMenuBar_Button6_senior_Flash
	COMBOSKILL_FLASH_SENIOR[27] = MainMenuBar_Button7_senior_Flash
	COMBOSKILL_FLASH_SENIOR[28] = MainMenuBar_Button8_senior_Flash
	COMBOSKILL_FLASH_SENIOR[29] = MainMenuBar_Button9_senior_Flash
	COMBOSKILL_FLASH_SENIOR[30] = MainMenuBar_Button10_senior_Flash


	MAINMENUBAR_ACCKEY["acc_selfequip"] = MainMenuBar_SelfEquip_Clicked;
	MAINMENUBAR_ACCKEY["acc_packet"] = MainMenuBar_Packet_Clicked;
	MAINMENUBAR_ACCKEY["acc_skill"] = MainMenuBar_Skill_Clicked;
	MAINMENUBAR_ACCKEY["acc_pet"] = MainMenuBar_Pet_Acced;
	MAINMENUBAR_ACCKEY["acc_quest"] = MainMenuBar_Mission_Clicked;
	MAINMENUBAR_ACCKEY["acc_friend"] = MainMenuBar_Friend_Clicked;
	MAINMENUBAR_ACCKEY["acc_team"] = MainMenuBar_Team_Clicked;
	MAINMENUBAR_ACCKEY["acc_exchange"] = MainMenuBar_Exchange_Clicked;
	MAINMENUBAR_ACCKEY["acc_guild"] = nil;	-- 角色帮会

	MAINMENUBAR_ACCKEY["acc_MainMenuBarpageup"] = MainmenuBar_PageUp;	--快捷栏向上翻页
	MAINMENUBAR_ACCKEY["acc_MainMenuBarpagedown"] = MainmenuBar_PageDown;	--快捷栏向下翻页
	MAINMENUBAR_ACCKEY["acc_MainMenuBarPageOne"] = MainmenuBar_PageOne;	--快捷栏第一页
	MAINMENUBAR_ACCKEY["acc_MainMenuBarPageTwo"] = MainmenuBar_PageTwo;	--快捷栏第二页
	MAINMENUBAR_ACCKEY["acc_MainMenuBarPageThree"] = MainmenuBar_PageThree;	--快捷栏第三页

	MainMenuBar_MainMenuBar_On:Show()
	MainMenuBar_MainMenuBar_Off:Hide()

	Button_ConfraternityPK_Ani:Hide();
	Button_GuildBattleScoreFlash:Hide();
	Button_Friend_Image:Hide()
	Button_Friend_Image2:Hide()
	Button_CharacterImage:Hide()
end

-- OnEvent
function MainMenuBar_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end
	
	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end
	
	--if arg0~=nil then
		--PushDebugMessage(event..arg0)
	--else
		--PushDebugMessage(event)
	--end
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		local nWidth ,nHeight = GetCurClientSize()
		MainMenuBar_AdjustMoveCtl(nWidth,nHeight);
		this:Show();
		MainmenuBar_UpdateAll();
		-- 显示经验
		MainMenuBar_ShowExperience();
		-- 切换场景后停止闪烁组队按钮
		MainMenuBar_Stop_Flash_Team_Button();
	elseif( event == "UPDATESTATE_SUBMENUBAR" ) then
		local SubToolbarState = SystemSetup:GetSubMenubarState()
		if 0 == SubToolbarState then
			MainMenuBar_MainMenuBar_Off_Clk()
		else
			MainMenuBar_MainMenuBar_On_Clk()
		end
	elseif ( event == "SWITCHMENPAI" ) then
		g_switchmenpaiIdx = 1
	elseif ( event == "SKILL_UPDATE" and g_switchmenpaiIdx==1) then
		g_switchmenpaiIdx = 0
		local menpai = Player:GetData("MEMPAI") + 1;
		if menpai == 10 or menpai < 1 or menpai > 16 then--menpai15
			return
		end
		PutSkillToMainmenuBar( nMenpaiSkillId[ menpai ][ 1 ],-1,-1,-1,-1,-1 );
	elseif( event == "CHANGE_BAR" and arg0 == "mainreset") then			
		local count=tonumber(arg1)+2;
		for i=3,count do
			local nIndex=tonumber(eventTable[i]);			
			if (nIndex > 0 and  nIndex <= 30) or (nIndex > 50 and  nIndex <= 60) then
				MAINMENUBAR_BUTTONS[nIndex]:SetActionItem(-1);
				MAINMENUBAR_BUTTONS[nIndex]:Bright();
			end
					
			if nIndex > 0 and  nIndex <= 30 and MAINMENUBAR_BUTTONS[nIndex]:IsVisible() then
				if 	COMBOSKILL_FLASH_JUNIOR[nIndex]:IsVisible() then
					COMBOSKILL_FLASH_JUNIOR[nIndex]:Hide()
				end
				if 	COMBOSKILL_FLASH_SENIOR[nIndex]:IsVisible() then
					COMBOSKILL_FLASH_SENIOR[nIndex]:Hide()
				end
			end
		end
	elseif( event == "CHANGE_BAR" and arg0 == "main") then		
		local nIndex = tonumber(arg1);
		Target:UpdateActionButton()
		if nIndex <=0 or (nIndex >30 and nIndex <= 50) or nIndex > 60 then	
			return
		end

		MAINMENUBAR_BUTTONS[nIndex]:SetActionItem(tonumber(arg2));
		MAINMENUBAR_BUTTONS[nIndex]:Bright();
		--吃鸡技能还得刷
		--雪人大战
		if  (nIndex > 50 and  nIndex <= 60)  then
			local actionId =MAINMENUBAR_BUTTONS[nIndex]:GetActionItem()
			if actionId > 0 then
				Lua_CheckChiJiSkillLevel(actionId)		
				Lua_CheckSnowManPVPAction(actionId)
			end
		end
		if arg3~=nil then
				local pet_num = tonumber(arg3);
				if pet_num >= 0 and pet_num < 6 then
					local isPresent = Pet : IsPresent(pet_num)
					local isFighting = Pet : GetIsFighting(pet_num)
					if isPresent == true and isFighting == true then
							MAINMENUBAR_BUTTONS[nIndex] : Bright();
					else
							MAINMENUBAR_BUTTONS[nIndex] : Gloom();
					end
				end
		end

		if nIndex > 0 and  nIndex <= 30 and MAINMENUBAR_BUTTONS[nIndex]:IsVisible() then
			if 	COMBOSKILL_FLASH_JUNIOR[nIndex]:IsVisible() then
				COMBOSKILL_FLASH_JUNIOR[nIndex]:Hide()
			end
			if 	COMBOSKILL_FLASH_SENIOR[nIndex]:IsVisible() then
				COMBOSKILL_FLASH_SENIOR[nIndex]:Hide()
			end
		end


	elseif( event == "CHANGE_BAR" and arg0 == "tip") then
	  --改变tip
	  local ButtonId = tonumber(arg1)
	  local key = tostring( arg2 )

	  MAINMENUBAR_BUTTONS[ButtonId]:SetProperty("CornerChar", key);
	  MAINMENUBAR_BUTTONS[ButtonId+10]:SetProperty("CornerChar", key);
	  MAINMENUBAR_BUTTONS[ButtonId+20]:SetProperty("CornerChar", key);
	elseif( event == "CHANGE_BAR" and arg0 == "ut") then
	--改变tip
	  MainMenuBar_UpdateButtonTip();

	elseif ( event == "RECEIVE_EXCHANGE_APPLY" )  then
		-- 闪烁交易按钮, 通知有人申请交易
		MainMenuBar_Flash_Exchange();

	elseif( event == "TEAM_NOTIFY_APPLY" ) then

		iTeamInfoType = tonumber(arg0);
		if(iTeamInfoType == 1 or iTeamInfoType == 2 or iTeamInfoType == 5) then

			-- 闪烁队伍按钮, 通知有人申请加入队伍.
			MainMenuBar_Flash_Team_Button();

		end

	elseif( event == "UNIT_EXP" ) then
			local MaxLevel = Player:GetDefineHumanMaxLevel()
			if Player:GetData("IsExpandLevelPlayer") > 0 then
				MaxLevel = Player:GetDefineHumanMaxLevel()
			else
				MaxLevel = Player:GetDefineHumanMaxLevelSub()
			end
			local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
			if KaJi:LuaFnIsKaJiServer() == 1 then
				MaxLevel = KaJi:LuaFnGetKaJiLeveL()
			elseif nSpecKaJi89 == 1 or nSpecKaJi89 == 2 then
				MaxLevel = 89			
			end
			-- 显示经验
			MainMenuBar_ShowExperience();
			-- 经验满 闪烁提示
			local nlevel = Player:GetData("LEVEL_CompatPKLV")
			if arg0 == "ExpIsFull" and nlevel ~= nil and nlevel > 0 and nlevel < MaxLevel then
				if arg1 == "LoginOrChangeScene" then
					if(g_bFirstLogin == true) then --只在第一次登陆闪烁 切场景不闪烁
						Button_Character:PlayWarning( 1 );
						g_bFirstLogin = false;
					end
				else
					Button_Character:PlayWarning( 1 );
				end
				if nlevel >= 10 and nlevel <= 29 then
				    local nTimes = math.floor(Player:GetHumanExpRatioToNeedExp())
				    if nTimes == 1 or nTimes == 2 then
					    MainMenuBar_FreshManGuide(1, 18, 9)
					    g_ShowCharSelf = 1
				    end
				    --MainMenuBar_FreshManGuide(1, 18, 2)
				    --NotifyPopUITip("SelfEquip", 19, 1)  --通知属性界面,点按钮升级
				end
			end
	elseif( event == "UNIT_LEVEL" ) then

			-- 显示经验
			MainMenuBar_ShowExperience();
	elseif( event == "UNIT_MAX_EXP" ) then

			-- 显示经验
			MainMenuBar_ShowExperience();
	elseif( event =="HAVE_MAIL" ) then
		Sound:PlayUISound(27);
		if( DataPool:GetMailNumber() == 0 and DataPool:GetImMsgNumber() == 0 and DataPool:GetSaleUserNumber() == 0) then
				Button_Friend:PlayWarning( 0 );
		else
				Button_Friend:PlayWarning( 1 );
		end
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 20160101) then
		Sound:PlayUISound(27);
		Button_Friend:PlayWarning(1);
		local nDate = Get_XParam_INT(0);
		local nGUIDH = Get_XParam_INT(1);
		local nGUIDL = Get_XParam_INT(2);
		local nName = Get_XParam_STR(0);
		--PushDebugMessage(nDate..","..nGUIDH..","..nGUIDL..","..nName);
		DataPool:AddSaleUserNotificationList(nDate,nGUIDH,nGUIDL,nName);
	elseif( event =="HAVE_IM_MSG" ) then
		local isPlaySound = tonumber(arg0)
		if isPlaySound == 1 then
			Sound:PlayUISound(27);
		end
		if( DataPool:GetMailNumber() == 0 and DataPool:GetImMsgNumber() == 0 and DataPool:GetSaleUserNumber() == 0) then
				Button_Friend:PlayWarning( 0 );
		else
				Button_Friend:PlayWarning( 1 );
		end
	elseif(event == "UPDATE_GUILD_APPLY") then
		local type = arg0;
		if type == "show" then
			Button_Reputation : PlayWarning(1);
		else
			Button_Reputation : PlayWarning(0);
		end
	elseif( event == "BATTLE_SCOREFLASH") then
		local type = arg0;
		if(type == "show") then
			Button_GuildBattleScoreFlash:Show();
		else
			Button_GuildBattleScoreFlash:Hide();
		end
	elseif( event =="NEW_MISSION" ) then
		if Player:GetData("LEVEL") > 10 then
			Button_Mission:PlayWarning( 1 );
			local missname = DataPool:GetPlayerMission_Name(tonumber(arg0))
			if missname == "Mission:1414" then  --第一只珍兽
				Button_Pet:PlayWarning(1)
				MainMenuBar_FreshManGuide(1, -1, 4)
			elseif missname == "Mission:1424" or  --十年
				missname == "Mission:1400" then   --初涉江湖
				Button_Mission:PlayWarning(0)
			end
		end

		local missname = DataPool:GetPlayerMission_Name(tonumber(arg0))
		if missname == "Mission:1414" then  --第一只珍兽
			MainMenuBar_FreshManGuide(1, -1, 4)
		elseif missname == "Mission:1401" then
			MainMenuBar_FreshManGuide(1, -1, 6)
		elseif missname == "Mission:1683" then
			PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",  1)	--接任务的指引
			MainMenuBar_FreshManGuide(1, -1, 6)
		end
	elseif( event == "ACCELERATE_KEYSEND" ) then

		-- 处理键盘快捷键
		MainMenuBar_HandleAccKey(arg0);
	elseif (event == "CHAT_ADJUST_MOVE_CTL") then
		MainMenuBar_AdjustMoveCtl(arg0, arg1);

	--elseif ( event == "UPDATE_DUR" ) then
		--MainmenuBar_UpdateDur();

	--新手改造，暂时去掉了把任务扔到技能栏的逻辑
	--elseif( event == "JOIN_NEW_MENPAI" ) then
		--MainmenuBar_JoinMenpai();

	elseif( event == "ACTION_UPDATE" ) then
		MainmenuBar_ActionUpate();

	elseif(event == "SHOW_GUILDWAR_ANIMI") then
		local type = arg0;
		if(arg0=="show")then
			local szEnemyGuildID	= City:GetKServerEnemyInfo("xuanzhan", "GuildID");
			local szIntrudeGuildID	= City:GetKServerEnemyInfo("yingzhan", "GuildID");
			--这个在K服和在本服需要设置不同的显示效果
			if (( KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1) and ( szIntrudeGuildID ~= -1 or szEnemyGuildID ~= -1 ) )	then
				Button_ConfraternityPK_Ani:SetProperty("Animate","BangHui_XZ");
			else
				Button_ConfraternityPK_Ani:SetProperty("Animate","Animate_ConfraternityPK");
			end
			Button_ConfraternityPK_Ani:Show()
		else
			if(Button_ConfraternityPK_Ani:IsVisible())then
				Button_ConfraternityPK_Ani:Hide();
			end
		end
	 

	elseif(event == "NOTIFY_NEW_SKILLS") then
		MainMenuBar_NotifyNewSkills(1);

	elseif(event == "SCENE_TRANSED") then
		Button_GuildBattleScore : Hide();
		local curSceneID = GetSceneID();
		if (curSceneID == 270) then
			Button_GuildBattleScore : Show();
		end

	elseif(event == "FLASH_PACKET_BUTTON") then
		if bIsPacketOpened == 0 then
			Button_Pack:PlayWarning( 1);
		end

	elseif(event == "PACKET_OPENED") then
		bIsPacketOpened = tonumber(arg0);

	-- 卸载双人休闲动作包时，同时删除拖动到MainMenuBar上的按钮信息
	elseif (event == "UNINSTALL_CHAT_ACTION_BAR") then
		MainMenuBar_UnInstallChatActionButton(tonumber(arg0));

	-- 清理过期的双人休闲动作包在主菜单上的按钮
	elseif (event == "CLEAR_CHAT_ACTION_BAR") and (tostring(arg0)== "MainMenuBar") then
		MainMenuBar_ClearChatActionButton(tonumber(arg1), tonumber(arg2), tonumber(arg3));

	elseif event == "UNFLASH_TEAM_BUTTON" then  --停闪组队按钮
		MainMenuBar_Stop_Flash_Team_Button()
	elseif event == "RAID_UPDATE_INVITATION" then
		MainMenuBar_Flash_Team_Button()
	elseif event == "SHOW_TRANSFIGURATION_SKILL" then
		if arg0 == "2" then
			MainmenuBar_ShowTransfigureSkill( 1 )
			if SystemSetup:GetSubMenubarState() == 1 then
				MainMenuBar_MainMenuBar_Off:Disable()
				bMainMenuBar_2Open = 1
				TurnMenuBar("off")
			else
				MainMenuBar_MainMenuBar_On:Disable()
			end
			--MainMenuBar_MainMenuBar_On:Disable()
			--MainMenuBar_MainMenuBar_Off:Disable()
			MainMenuBar_ScrollBar_Up:Disable()
			MainMenuBar_ScrollBar_Down:Disable()
		elseif arg0 == "0" then
			MainmenuBar_ShowTransfigureSkill( 0 )
			if bMainMenuBar_2Open == 1 then
				MainMenuBar_MainMenuBar_Off:Enable()
				TurnMenuBar("on")
				bMainMenuBar_2Open = 0
			else
				MainMenuBar_MainMenuBar_On:Enable()
			end
			MainMenuBar_ScrollBar_Up:Enable()
			MainMenuBar_ScrollBar_Down:Enable()
		end

    elseif(event == "UPDATE_UNION_INVITE_APPLY") then
		local type = arg0;
		if type == "flash" then
			Button_Reputation : PlayWarning(1);
		else
			Button_Reputation : PlayWarning(0);
		end
    elseif event == "NOTIFY_POP_UITIP" then
        if "MainMenuBar" == arg0 and this:IsVisible() and Player:GetData("LEVEL") <= 10 then
            MainMenuBar_FreshManGuide(1, tonumber(arg1), tonumber(arg2))
        end
    elseif "UI_COMMAND" == event and tonumber(arg0) == 44 then
        if not this:IsVisible() then
            return
        end
        if 210273 == Get_XParam_INT(0) and Player:GetData("LEVEL") <= 10 then  --剑阁猴患
            g_NeedTipID = Get_XParam_INT(1)
            MainMenuBar_FreshManGuide(1, Get_XParam_INT(2), 3)
            local action = EnumMainMenuBarAction(g_NeedTipID)
            if action ~= nil and action:GetID() ~= 0 then
                action:SetActionFlash(1)
                MAINMENUBAR_BUTTONS[g_NeedTipID + 1]:SetProperty("FlashAnimate", "BtnlightupAni")
                MAINMENUBAR_BUTTONS[g_NeedTipID + 1]:SetNewFlash()
            end
        elseif "JoinMenpai" == Get_XParam_STR(0) then  --刚加入门派
            g_NeedTipID = Get_XParam_INT(0)
            MainMenuBar_FreshManGuide(1, 17, 3)
            local action = EnumMainMenuBarAction(g_NeedTipID)
            if action ~= nil and action:GetID() ~= 0 then
                action:SetActionFlash(1)
                MAINMENUBAR_BUTTONS[g_NeedTipID + 1]:SetProperty("FlashAnimate", "BtnlightupAni")
                MAINMENUBAR_BUTTONS[g_NeedTipID + 1]:SetNewFlash()
            end
        end
	elseif "UI_COMMAND" == event and tonumber(arg0) == 20130902 then
		NewFreshManPutSkillToMainmenuBar(244,248)
		PushEvent("OPEN_FRESHMAN_NEWNPCCHAT", 2)
	elseif "UI_COMMAND" == event and tonumber(arg0) == 20130911 then
		PushEvent("OPEN_FRESHMAN_NEWNPCCHAT", 3)
		MainMenuBar_FreshManGuide(1, -1, 4)
    elseif "FINISH_MISSION" == event then
        if "1415" == arg0 then  --"抓珍兽"
            Button_Pet:PlayWarning(1)
            NotifyPopUITip("Pet", 14, 3)  --通知珍兽界面,tip”放生“
		elseif tonumber(arg0) >= 1717 and tonumber(arg0) <= 1727 then	--2013Q3新手指引,玩家完成任务"武学奥秘"，门派技能落入技能框
			MainmenuBar_JoinMenpai()
		elseif tonumber(arg0) == 1842 or  tonumber(arg0) == 1912  or tonumber(arg0) == 1962 or tonumber(arg0) == 3074 then --newmenpai,加上武学奥秘任务id menpai15
			MainmenuBar_JoinMenpai()
		end
	elseif "UI_COMMAND" == event and tonumber(arg0) == 2015063001 then
		--结拜引导任务好友按钮闪烁10s

		if DataPool:Lua_IsHaveMission(1361) > 0 and DataPool:Lua_IsMissionHaveDone(1361) <= 0 then
			local fX, fY = this:GetChildOffset("Button_Friend")
	    OpenFreshManGuide(1, 74, fX, fY, "MainMenuBar", "northwest")
			--Button_Friend:PlayWarning( 1 );
			SetTimer("MainMenuBar", "MainMenuBar_Button_Friend_Close()", 10000)
		end
	elseif "RESET_ALLUI" == event then
		Button_Character	:PlayWarning(0)
		Button_Skills		:PlayWarning(0)
		Button_Pet			:PlayWarning(0)
		Button_Mission		:PlayWarning(0)
		Button_Exchange		:PlayWarning(0)
		Button_Pack			:PlayWarning(0)
		Button_Friend		:PlayWarning(0)
		Button_Team			:PlayWarning(0)
		Button_Reputation	:PlayWarning(0)
		Button_System		:PlayWarning(0)
	elseif "OPEN_UP_BAR_2" == event then
		if arg0 == "1" and arg1 == "MainBar" then
			MainMenuBar_MainMenuBar_On_Clk()
		end
	elseif event == "COMBO_SKILL" then
		local bookIndex = tonumber(arg0)
		local tempnum = tonumber(arg1)
		if tempnum == 1 then
			local skill1, skill2, skill3 = Player:GetComboBookInfo(bookIndex, "comboskill");
			local CurCombo = tostring(arg2)
			if(CurCombo == "1") then
				ActiveComboSkillToMainmenuBar(skill1,skill2,1);
			elseif (CurCombo == "2") then
				ActiveComboSkillToMainmenuBar(skill2,skill3,2);
			end
		elseif tempnum == -1  then
			local skill1, skill2, skill3 = Player:GetComboBookInfo(bookIndex, "comboskill");
			ActiveComboSkillToMainmenuBar(skill2,skill1,0);
			ActiveComboSkillToMainmenuBar(skill3,skill1,0);
		end
	elseif event == "MPCOMBO_SKILL" then
		local bookIndex = tonumber(arg0)
		local tempnum = tonumber(arg1)
		if tempnum == 1 then
			local skill1, skill2, skill3  = Player:GetMPComboBookInfo(bookIndex, "mpcomboskill");
			local CurCombo = tostring(arg2)
			if(CurCombo == "1") then
				ActiveComboSkillToMainmenuBar(skill1,skill2,1);
			elseif (CurCombo == "2") then
				ActiveComboSkillToMainmenuBar(skill2,skill3,2);
			elseif (CurCombo == "3") then
				ActiveComboSkillToMainmenuBar(skill3,skill3,2);
			end
		elseif tempnum == -1  then
			local skill1, skill2, skill3= Player:GetMPComboBookInfo(bookIndex, "mpcomboskill");
			ActiveComboSkillToMainmenuBar(skill2,skill1,0);
			ActiveComboSkillToMainmenuBar(skill3,skill1,0);
		end
	elseif event == "FLASH_COMBOSKILL" then
		local Index = tonumber(arg0)
		local flash = tonumber(arg1)

		if Index > 0 and Index <= 10 then  --1~10第一页
			if MAINMENUBAR_PAGENUM == 0 then
				MainmenuBar_UpdateComboFlash(Index, flash)
			end
		elseif Index > 10 and Index <= 20 then
			if MAINMENUBAR_PAGENUM == 1 then
				MainmenuBar_UpdateComboFlash(Index, flash)
			end
		elseif Index > 20 and Index <= 30 then
			if MAINMENUBAR_PAGENUM == 2 then
				MainmenuBar_UpdateComboFlash(Index, flash)
			end
		end
	elseif event == "DYZCOMBO_SKILL" then
		local bookIndex = tonumber(arg0)
		local tempnum = tonumber(arg1)

		if tempnum == 1 then
			local skill1, skill2= Player:GetDYZComboBookInfo(bookIndex, "dyzcomboskill");
			local CurCombo = tostring(arg2)
			if(CurCombo == "1") then
				ActiveCongRenComboSkillToMainmenuBar(skill1,skill2,1);
			end
		elseif tempnum == -1  then

			local skill1, skill2= Player:GetDYZComboBookInfo(bookIndex, "dyzcomboskill");
			ActiveCongRenComboSkillToMainmenuBar(skill2,skill1,0);
		end
	elseif event == "LMSJCOMBO_SKILL" then
		local bookIndex = tonumber(arg0)
		local tempnum = tonumber(arg1)

		if tempnum == 1 then
			local skill1, skill2= Player:GetLMSJComboBookInfo(bookIndex)
			ActiveCongRenComboSkillToMainmenuBar(skill1,skill2,1);
		elseif tempnum == -1  then

			local skill1, skill2= Player:GetLMSJComboBookInfo(bookIndex)
			ActiveCongRenComboSkillToMainmenuBar(skill2,skill1,0);
		end
	elseif event == "JYJYCOMBO_SKILL" then
		local bookIndex = tonumber(arg0)
		local tempnum = tonumber(arg1)

		if tempnum == 1 then
			local skill1, skill2= Player:GetJYJYComboBookInfo(bookIndex)
			ActiveCongRenComboSkillToMainmenuBar(skill1,skill2,1);
		elseif tempnum == -1  then

			local skill1, skill2= Player:GetJYJYComboBookInfo(bookIndex)
			ActiveCongRenComboSkillToMainmenuBar(skill2,skill1,0);
		end
	elseif event == "WJQFCOMBO_SKILL" then
		local bookIndex = tonumber(arg0)
		local tempnum = tonumber(arg1)
		
		if tempnum == 1 then
			local skill1, skill2, skill3 = Player:GetWJQFComboBookInfo(bookIndex);
			local CurCombo = tostring(arg2)
			if(CurCombo == "1") then
				ActiveComboSkillToMainmenuBar(skill1,skill2,1);
			elseif (CurCombo == "2") then
				ActiveComboSkillToMainmenuBar(skill2,skill3,2);
			end
		elseif tempnum == -1  then
			local skill1, skill2, skill3 = Player:GetWJQFComboBookInfo(bookIndex);
			ActiveComboSkillToMainmenuBar(skill2,skill1,0);
			ActiveComboSkillToMainmenuBar(skill3,skill1,0);
		end		
	elseif event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		else
			this:Show()
		end
	elseif event == "HAVE_GSIM_MSG" then
		local isPlaySound = tonumber(arg0)
		if isPlaySound == 1 then
			Sound:PlayUISound(27);
			Button_Friend:PlayWarning( 1 );
		else
			Button_Friend:PlayWarning( 0 );
		end
	elseif event == "HAVE_GSIM_MSG_NEW" then
		local isPlaySound = tonumber(arg0)
		if isPlaySound == 1 then
			Sound:PlayUISound(27);
			Button_Friend:PlayWarning( 1 );
		else
			Button_Friend:PlayWarning( 0 );
		end
	elseif(event == "UPDATE_DOUBLE_EXP" ) then

        local DT = SystemSetup : GetDoubleExp("remaintime");
		if DT > 0 then
			--MainMenuBar_Doub_Text:Show()
			MainMenuBar_Doub_Watch:Show()
			MainMenuBar_Doub:Show()
			MainMenuBar_Doub_Watch:SetProperty("Timer",DT);
			MainMenuBar_EXP2:Hide()
			MainMenuBar_EXP3:Show()
			MainMenuBar_DoubleExp_Flash:Show()
			--MainMenuBar_Doub_Text:SetText("#{IM2BEI_141114_01}")
		else
			--MainMenuBar_Doub_Text:Hide()
			MainMenuBar_Doub:Hide()
			MainMenuBar_Doub_Watch:Hide()
			MainMenuBar_EXP2:Show()
			MainMenuBar_EXP3:Hide()
			MainMenuBar_DoubleExp_Flash:Hide()
			--MainMenuBar_Doub_Text:SetText("")
		end
		
		local nXuanLingTime = SystemSetup : GetDoubleExp("remainxuanlingtime");
		if nXuanLingTime > 0 then
			if Player:GetData("Is2606S") == 1 then
				MainMenuBar_Button_Peak_DoubleEXP2_TimeBK:SetToolTip("");
				MainMenuBar_Button_Peak_DoubleEXP2_Time:SetToolTip("");
			else
				MainMenuBar_Button_Peak_DoubleEXP2_TimeBK:SetToolTip("#{TLZL_231107_67}");
				MainMenuBar_Button_Peak_DoubleEXP2_Time:SetToolTip("#{TLZL_231107_67}");
			end
			MainMenuBar_Button_Peak_DoubleEXP2_Time:Show()
			MainMenuBar_Button_Peak_DoubleEXP2_TimeBK:Show()
			MainMenuBar_DoubleExp2_ShowTime();
			KillTimer("MainMenuBar_DoubleExp2_ShowTime()")
			SetTimer("MainMenuBar","MainMenuBar_DoubleExp2_ShowTime()", 1000)
		else
			MainMenuBar_Button_Peak_DoubleEXP2_TimeBK:Hide()
		end
		
	elseif (event == "ADJEST_UI_POS") then
		PushEvent("UNIT_MAX_EXP")
	--20150701-七夕交互任务-by yuanpeilong：start
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 8913671 or tonumber(arg0) == 8913681 
		or tonumber(arg0) == 8913361 or tonumber(arg0) == 8913371 or tonumber(arg0) == 8913391 or tonumber(arg0) == 8913401) then	

			local JieMina = Get_XParam_INT(0)
			index_mainbar = Get_XParam_INT(1)
			if JieMina == 99 then
				if index_mainbar == 51 or index_mainbar == 52 or index_mainbar == 53 then
					local action = EnumMainMenuBarAction(index_mainbar)
					if action ~= nil and action:GetID() ~= 0 then
						action:SetActionFlash(1)		
						MAINMENUBAR_BUTTONS[index_mainbar+1]:SetProperty("FlashAnimate", "BtnlightupAni")
						MAINMENUBAR_BUTTONS[index_mainbar+1]:SetFlash(1)
						SetTimer("MainMenuBar", "Button_Action_ShopGuide()", 5000)
					end
				end
			end

	--20150701-七夕交互任务-by yuanpeilong：end
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 8922941) then
		local flash = Get_XParam_INT(0);
		local nIndex = Get_XParam_INT(1);
		for i = 1,5 do
			COMBOSKILL_FLASH_JUNIOR[i]:Hide()
		end
		if flash == 1 then
			COMBOSKILL_FLASH_JUNIOR[nIndex]:Show()
		else
			COMBOSKILL_FLASH_JUNIOR[nIndex]:Hide()
		end
	elseif event == "CHAT_SIGN_RED_POINT" then
		Button_Friend_Image2:Show()
	elseif event == "HIDE_CHATSIGN_REDPOINT" then
		Button_Friend_Image2:Hide()
	elseif(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		MainMenuBar_RefreshCharTip()
    elseif event == "UPDATE_REDPOINT_IN_UI" then
        MainMenuBar_RefreshCharTip()
	elseif event == "UPDATE_EXTERIOR_TIP" then
		MainMenuBar_RefreshCharTip()	
	elseif event == "UPDATE_TOY_TIP" then
		MainMenuBar_RefreshCharTip()
	elseif event == "CANGPIN_UPDATE" then
		MainMenuBar_RefreshCharTip()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 99887901) then
		MainMenuBar_RefreshCharTip()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 25082801) then
		local nParam = Get_XParam_INT(0)	
		MainMenuBar_FreshManGuide(1, -1, nParam)
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			Button_Skills_Tips:Show()	
		else
			Button_Skills_Tips:Hide()		
		end
	elseif event == "TLCJ_BASEATTRUPDATE" then
		MainMenuBar_ShowExperience()
		if arg0 == "level" then
			MainmenuBar_CheckChiJiSkillLevel()
		end
	end
	
	if event == "NEIDAN_CHIP_UPDATE" then
		MainMenuBar_RefreshPetTip()
	end
end

function MainMenuBar_DoubleExp2_ShowTime()
	local nXuanLingTime = SystemSetup : GetDoubleExp("remainxuanlingtime");
	if nXuanLingTime <= 0 then
		MainMenuBar_Peak_DoubleEXP2_TimeReach();
		KillTimer("MainMenuBar_DoubleExp2_ShowTime()");
		return
	end
	
	local nMin = math.floor(nXuanLingTime / 60);
	local nSec = math.mod(nXuanLingTime, 60)
	local nTimeText = string.format("%02d:%02d", nMin, nSec );
	MainMenuBar_Button_Peak_DoubleEXP2_Time:SetText( nTimeText )
end

--20150701-七夕交互任务-by yuanpeilong
function Button_Action_ShopGuide()
	--图标闪烁消失
	if index_mainbar == 51 or index_mainbar == 52 or index_mainbar == 53 then
		local action = EnumMainMenuBarAction(index_mainbar)
		if action ~= nil and action:GetID() ~= 0 then
			action:SetActionFlash(0)
			MAINMENUBAR_BUTTONS[index_mainbar+1]:SetProperty("FlashAnimate", "BtnlightupAni")
			MAINMENUBAR_BUTTONS[index_mainbar+1]:SetFlash(0)		
		end
		--闪烁计时停止
		KillTimer("Button_Action_ShopGuide()")
	end
end

function MainmenuBar_UpdateComboFlash(Index,flash)
	--PushDebugMessage("MainmenuBar_UpdateComboFlash"..Index.."flash"..flash)
	local nIndex = tonumber(Index)
	local nflash = tonumber(flash)
	if MAINMENUBAR_BUTTONS[Index]:IsVisible() then
			if(nflash == 1) then
				if not COMBOSKILL_FLASH_JUNIOR[Index]:IsVisible() then
					COMBOSKILL_FLASH_JUNIOR[Index]:Show()
					COMBOSKILL_FLASH_SENIOR[Index]:Hide()
				end
			elseif (nflash == 2) then
				if not COMBOSKILL_FLASH_SENIOR[Index]:IsVisible() then
					COMBOSKILL_FLASH_JUNIOR[Index]:Hide()
					COMBOSKILL_FLASH_SENIOR[Index]:Show()
				end
			else
				COMBOSKILL_FLASH_JUNIOR[Index]:Hide()
				COMBOSKILL_FLASH_SENIOR[Index]:Hide()
			end
	end
end

function MainmenuBar_ActionUpate()
	for i=1,10 do
		MAINMENUBAR_BUTTONS[i]:SetNewFlash();
	end
end
--当加入门派后，需要将技能加到快捷栏
function MainmenuBar_JoinMenpai()
	local nLevel = Player:GetData("LEVEL")
	if nLevel > 30 then		--如果玩家等级大于30级，那么就不给他将技能拖到快捷栏里了
		return
	end

	local menpai = Player:GetData("MEMPAI") + 1;
	if menpai == 10 or menpai < 1 or menpai > 16 then--menpai15
		return
	end
	--判断要放到哪个栏里
	if menpai == 5 or menpai == 14 then			--峨眉有6个技能  桃花岛有6个技能
		PutSkillToMainmenuBar( nMenpaiSkillId[ menpai ][ 1 ],nMenpaiSkillId[ menpai ][ 2 ],nMenpaiSkillId[ menpai ][ 3 ],nMenpaiSkillId[ menpai ][ 4 ],nMenpaiSkillId[ menpai ][ 5 ],nMenpaiSkillId[ menpai ][ 6 ] );
	elseif menpai == 4 or menpai == 9 then	--武当和逍遥是4个技能
		PutSkillToMainmenuBar( nMenpaiSkillId[ menpai ][ 1 ],nMenpaiSkillId[ menpai ][ 2 ],nMenpaiSkillId[ menpai ][ 3 ],nMenpaiSkillId[ menpai ][ 4 ] )
	else		--其他门派都为5个技能
		PutSkillToMainmenuBar( nMenpaiSkillId[ menpai ][ 1 ],nMenpaiSkillId[ menpai ][ 2 ],nMenpaiSkillId[ menpai ][ 3 ],nMenpaiSkillId[ menpai ][ 4 ],nMenpaiSkillId[ menpai ][ 5 ] )
	end
end

function MainMenuBar_SelfEquip_Clicked()

	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	-- 打开装备界面
	if(0 == bTogleSelfEquip) then

		bTogleSelfEquip = 1;
		OpenEquip(bTogleSelfEquip);
		if "MainMenuBar" == GetFreshManGuideOwner() then
			CloseFreshManGuide()
		end

	elseif(1 == bTogleSelfEquip) then
		if "MainMenuBar" == GetFreshManGuideOwner() then
			CloseFreshManGuide()
		end
		bTogleSelfEquip = 0;
		OpenEquip(bTogleSelfEquip);
	end

	if g_ShowCharSelf > 0 then
		NotifyPopUITip("SelfEquip", 1, 2)
		g_ShowCharSelf = 0
	end
	if g_ShowCharSelf2 > 0 then
		NotifyPopUITip("SelfEquip", -1, g_ShowCharSelf2)
		g_ShowCharSelf2 = 0
	end
	-- 点击按钮后 取消闪烁提示
	Button_Character:PlayWarning( 0 );
	-- 升级二次确认框数据置一下
	AskLevelUpAfterSec(1);
end

function MainMenuBar_Skill_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	MainMenuBar_NotifyNewSkills(0);
	ToggleSkillBook();

		local LastSKilltap = GetLastSkill_UI()
		local nProcess = DataPool:GetCurrentFreshManGuideItemValue();
		if nProcess ==22  then
			if LastSKilltap == 1 then
				NotifyPopUITip("CommonSkill", -1, 1)
			elseif LastSKilltap == 2 then
				PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",8)

			end
			DataPool:SetCurrentFreshManGuideItemValue(0);
		end

end

function MainMenuBar_Packet_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	Button_Pack:PlayWarning( 0 );
	local nProcess = DataPool:GetCurrentFreshManGuideItemValue();
	if nProcess == 1 then
		DataPool:SetCurrentFreshManGuideItemValue(2)
	end
	CloseFreshManGuide()
	ToggleContainer();
end

function MainMenuBar_Mission_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	Button_Mission:PlayWarning( 0 );
	CloseFreshManGuide()
	ToggleMission();
end

function MainMenuBar_Pet_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	Button_Pet:PlayWarning( 0 );
	TogglePetPage();

	if "MainMenuBar" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
		local nProcess = DataPool:GetCurrentFreshManGuideItemValue();
		if nProcess ~=21 then
			NotifyPopUITip("Pet", -1, 1)
		else
			PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",7)
			DataPool:SetCurrentFreshManGuideItemValue(0);
		end
	end
end

function MainMenuBar_Pet_Acced()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	Button_Pet:PlayWarning( 0 );
end

function MainMenuBar_Button_Friend_Close()
	if DataPool:Lua_IsHaveMission(1361) > 0 and DataPool:Lua_IsMissionHaveDone(1361) <= 0 then
		CloseFreshManGuide()
		--Button_Friend:PlayWarning( 0 );
	end	
end

function MainMenuBar_Friend_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	if( DataPool:GetMailNumber() == 0 )then
		if DataPool:GetSaleUserNumber() ~= 0 then
			local nSize,nDate,nGUIDH,nGUIDL,szName = DataPool:GetSaleUserNotification();
			PushEvent("PHONY_INFOBROWSER_OPEN",nDate,nGUIDH,nGUIDL,szName)
			if( DataPool:GetMailNumber() == 0 and DataPool:GetImMsgNumber() == 0 and 
				DataPool:GetSaleUserNumber() == 0) then
					Button_Friend:PlayWarning( 0 );
			else
					Button_Friend:PlayWarning( 1 );
			end
		elseif DataPool:GetImMsgNumber() ~= 0 then
			DataPool:OpenNotReadImMsg()
		elseif Talk:IshaveGSIMMsg() ~= 0 then
			PushEvent("OPEN_GSIM",1)
		elseif Talk:IshaveGSIMMsgNew() ~= 0 then
			PushEvent("OPEN_GSIM_NEW",1)			
		else
			MainMenuBar_Button_Friend_Close()
			DataPool:OpenFriendList();
		end
	else
		if( Variable:GetVariable( "IsInfoBrowerShow" ) == "False" ) then
			DataPool:OpenMailRead();
		else
			if DataPool:GetSaleUserNumber() ~= 0 then
				local nSize,nDate,nGUIDH,nGUIDL,szName = DataPool:GetSaleUserNotification();
				PushEvent("PHONY_INFOBROWSER_OPEN",nDate,nGUIDH,nGUIDL,szName)
			elseif DataPool:GetImMsgNumber() ~= 0 then
				DataPool:OpenNotReadImMsg()
			else
				MainMenuBar_Button_Friend_Close()
				DataPool:OpenFriendList();
			end
		end
	end
end

function MainMenuBar_Friend_RBClicked()

	DataPool:OpenFriendList();

end

function MainMenuBar_Exchange_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	if( bExchangeFlash == 0 ) then
		PrepearExchange();
		return;
	else
		Exchange:OpenExchangeFrame();
	end

	if ( Exchange:IsStillAnyAppInList() == false ) then
		MainMenuBar_Stop_Flash_Exchange()
	end
end

function PlayerExp_Update()
	PlayerExp, PlayerMaxExp = Player:GetExp();
	PlayerExp_Exp:SetProgress(PlayerExp, PlayerMaxExp);
end

function PlayerExp_Exp_Text_MouseEnter()
	PlayerExp_Exp_Text:SetText(PlayerExp .. "/" .. PlayerMaxExp);
end

function PlayerExp_Exp_Text_MouseLeave()
	PlayerExp_Exp_Text:SetText("");
end

function MainMenuBar_Team_Clicked()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	if Player:IsInRaid() == 1 then
		if Raid:GetApplicantCount() > 0 then
			ShowTeamInfoDlg(bIsTeamBnFlash)
		elseif IsWindowShow("UnionFrame") == true then
			CloseWindow("UnionFrame", true)
		else
			OpenWindow("UnionFrame")
		end
	elseif Raid:GetInvitationCount() > 0 or DataPool:GetInviteTeamCount() > 0 then
		if DataPool:GetInviteTeamCount() > 0 then
			ShowTeamInfoDlg(bIsTeamBnFlash)
		end
		if Raid:GetInvitationCount() > 0 then
			OpenWindow("UnionChoose")
		end
	else
		ShowTeamInfoDlg(bIsTeamBnFlash);
	end

	-- 停止闪烁
	if(bIsTeamBnFlash) then

		MainMenuBar_Stop_Flash_Team_Button();
	end;

end

---------------------------------------------------------------------------------------------
-- 闪烁队伍按钮
function MainMenuBar_Flash_Team_Button()
	Button_Team:PlayWarning( 1 );
	bIsTeamBnFlash = 1;
end

---------------------------------------------------------------------------------------------
-- 停止闪烁队伍按钮
function MainMenuBar_Stop_Flash_Team_Button()
	Button_Team:PlayWarning( 0 );
	bIsTeamBnFlash = 0;
end

---------------------------------------------------------------------------------------------
-- 闪烁交易请求
function MainMenuBar_Flash_Exchange()
	Button_Exchange:PlayWarning( 1 );
	bExchangeFlash = 1;

end

---------------------------------------------------------------------------------------------
-- 停止闪烁交易请求
function MainMenuBar_Stop_Flash_Exchange()
	Button_Exchange:PlayWarning( 0 );
	bExchangeFlash = 0;
end

---------------------------------------------------------------------------------------------
-- 显示经验
function MainMenuBar_ShowExperience()
	if this:IsVisible()  then
	else
		return
	end
	local CurExperience, RequireExperience = 0, 1
	if TLCJ:IsInTLCJScene() > 0 then
		CurExperience = TLCJ:GetData("EXP")
		RequireExperience = TLCJ:GetData("NEEDEXP")
		
		-- 显示进度
		MainMenuBar_EXP2:SetProgress(CurExperience / RequireExperience, 1.0);
		MainMenuBar_EXP3:SetProgress(CurExperience / RequireExperience, 1.0);
		local Width = MainMenuBar_EXP3:GetProperty("AbsoluteWidth")
		local Percent = tonumber(CurExperience / RequireExperience)
		if Percent > 1 then
			Percent = 1
		end
		if SystemSetup:IsClassic() == 1  then
			MainMenuBar_DoubleExp_Flash:SetProperty("AbsoluteXPosition",Width*Percent+30)
		else
			MainMenuBar_DoubleExp_Flash:SetProperty("AbsoluteXPosition",Width*Percent-10)
		end
	else
		-- 显示进度
		MainMenuBar_EXP2:SetProgress(Player:GetHumanExpRatioToNeedExp(), 1.0);
		MainMenuBar_EXP3:SetProgress(Player:GetHumanExpRatioToNeedExp(), 1.0);
		local Width = MainMenuBar_EXP3:GetProperty("AbsoluteWidth")
		local Percent = tonumber(Player:GetHumanExpRatioToNeedExp())
		if Percent > 1 then
			Percent = 1
		end
		if SystemSetup:IsClassic() == 1  then
			MainMenuBar_DoubleExp_Flash:SetProperty("AbsoluteXPosition",Width*Percent+30)
		else
			MainMenuBar_DoubleExp_Flash:SetProperty("AbsoluteXPosition",Width*Percent-10)
		end
	end

	
end

function MainMenuBar_ShowExpTooltip()
	local exp, maxexp = 0, 1
	if TLCJ:IsInTLCJScene() > 0 then
		exp = TLCJ:GetData("EXP")
		maxexp = TLCJ:GetData("NEEDEXP")
	else
		exp = Player:GetData( "EXP" );
		maxexp = Player:GetData( "NEEDEXP" );
	end

	MainMenuBar_EXP2:SetToolTip( tostring( exp ).."/"..tostring( maxexp ) );
	MainMenuBar_EXP3:SetToolTip( tostring( exp ).."/"..tostring( maxexp ) );
end

function MainMenuBar_HideExpTooltip()
end

function MainMenuBar_Peak_DoubleEXP2_TimeShowWatchTooltip()
end

function MainMenuBar_Peak_DoubleEXP2_TimeReach()
	MainMenuBar_Button_Peak_DoubleEXP2_TimeBK:Hide()
end


function MainMenuBar_Setup_Clicked()
	SystemSetup:OpenSetup();
end

function MainMenuBar_HandleAccKey( op )
	if(MAINMENUBAR_ACCKEY[op] ~= nil) then
		MAINMENUBAR_ACCKEY[op]();
	end
end

function MainMenuBar_Clicked(nIndex)

	local isCanDo = DataPool:IsCanDoAction()
	if isCanDo == true then
		MAINMENUBAR_BUTTONS[nIndex]:DoAction();

	    --一旦点击,清除引导ui
    	if nIndex == g_NeedTipID + 1 then
        	g_NeedTipID = -1
        	if "MainMenuBar" == GetFreshManGuideOwner() then
                CloseFreshManGuide()
            end
        end
	else
		PushDebugMessage("你不能这么做。")
		return;
	end

	if nIndex == 6 then	--	关闭骑乘引导
		if "MainMenuBar" == GetFreshManGuideOwner() then
			CloseFreshManGuide()
		end
	end
end

function MainMenuBar_AdjustMoveCtl( screenWidth, screenHeight )
    --- 如果是唯美版
    if 0 == SystemSetup:IsClassic() then
        if(tonumber(screenWidth) > 1370) then
            MainMenuBar_BK:SetProperty("UnifiedPosition", "{{0.000000,0.000000},{1.000000,-38.000000}");
            MainMenuBar_BK:SetProperty("UnifiedSize", "{{1.000000,0.000000},{0.000000,38.000000}");
        else
            MainMenuBar_BK:SetProperty("UnifiedPosition", "{{0.500000,-715.000000},{1.000000,-38.000000}");
            MainMenuBar_BK:SetProperty("UnifiedSize", "{{0.000000,1400.000000},{0.000000,38.000000}");
        end
    --- 如果是经典版
    else
        if(tonumber(screenWidth) >= 1020) then
		      MainMenuBar:SetProperty("UnifiedPosition", "{{0.500000,-481.000000},{1.000000,-84.000000}");
              MainMenuBar:SetProperty("UnifiedSize", "{{0.000000,962.000000},{0.000000,84.000000}");
              Button_Character:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Character:SetProperty("UnifiedPosition", "{{0.000000,31.000000},{0.000000,20.000000}}");
              Button_Skills:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Skills:SetProperty("UnifiedPosition", "{{0.000000,81.000000},{0.000000,20.000000}}");
              Button_Pet:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Pet:SetProperty("UnifiedPosition", "{{0.000000,131.000000},{0.000000,20.000000}}");
              Button_Mission:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Mission:SetProperty("UnifiedPosition", "{{0.000000,181.000000},{0.000000,20.000000}}");
              Button_Exchange:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Exchange:SetProperty("UnifiedPosition", "{{0.000000,231.000000},{0.000000,20.000000}}");
              Button_Pack:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Pack:SetProperty("UnifiedPosition", "{{1.000000,-281.000000},{0.000000,20.000000}}");
              Button_Friend:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Friend:SetProperty("UnifiedPosition", "{{1.000000,-231.000000},{0.000000,20.000000}}");
              Button_Team:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Team:SetProperty("UnifiedPosition", "{{1.000000,-181.000000},{0.000000,20.000000}}");
              Button_Reputation:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_Reputation:SetProperty("UnifiedPosition", "{{1.000000,-131.000000},{0.000000,20.000000}}");
              Button_System:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_System:SetProperty("UnifiedPosition", "{{1.000000,-81.000000},{0.000000,20.000000}}");
              Button_GuildBattleScore:SetProperty("UnifiedPosition", "{{1.000000,-188.000000},{0.000000,0.000000}}");
              Button_ConfraternityPK_Ani:SetProperty("UnifiedSize", "{{0.000000,50.000000},{0.000000,50.000000}}");
              Button_ConfraternityPK_Ani:SetProperty("UnifiedPosition", "{{1.000000,-131.000000},{0.000000,20.000000}}");
              MainMenuBar_Button_Peak_DoubleEXP2_TimeBK:SetProperty("UnifiedPosition", "{{0.000000,810.000000},{0.000000,0.000000}}");
	    else
	       	  MainMenuBar:SetProperty("UnifiedPosition", "{{0.500000,-431.000000},{1.000000,-84.000000}");
              MainMenuBar:SetProperty("UnifiedSize", "{{0.000000,862.000000},{0.000000,84.000000}");
              Button_Character:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Character:SetProperty("UnifiedPosition", "{{0.000000,31.000000},{0.000000,20.000000}}");
              Button_Skills:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Skills:SetProperty("UnifiedPosition", "{{0.000000,71.000000},{0.000000,20.000000}}");
              Button_Pet:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Pet:SetProperty("UnifiedPosition", "{{0.000000,111.000000},{0.000000,20.000000}}");
              Button_Mission:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Mission:SetProperty("UnifiedPosition", "{{0.000000,151.000000},{0.000000,20.000000}}");
              Button_Exchange:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Exchange:SetProperty("UnifiedPosition", "{{0.000000,191.000000},{0.000000,20.000000}}");
              Button_Pack:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Pack:SetProperty("UnifiedPosition", "{{1.000000,-231.000000},{0.000000,20.000000}}");
              Button_Friend:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Friend:SetProperty("UnifiedPosition", "{{1.000000,-191.000000},{0.000000,20.000000}}");
              Button_Team:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Team:SetProperty("UnifiedPosition", "{{1.000000,-151.000000},{0.000000,20.000000}}");
              Button_Reputation:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_Reputation:SetProperty("UnifiedPosition", "{{1.000000,-111.000000},{0.000000,20.000000}}");
              Button_System:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_System:SetProperty("UnifiedPosition", "{{1.000000,-71.000000},{0.000000,20.000000}}");
              Button_GuildBattleScore:SetProperty("UnifiedPosition", "{{1.000000,-161.000000},{0.000000,0.000000}}");
              Button_ConfraternityPK_Ani:SetProperty("UnifiedSize", "{{0.000000,40.000000},{0.000000,40.000000}}");
              Button_ConfraternityPK_Ani:SetProperty("UnifiedPosition", "{{1.000000,-111.000000},{0.000000,20.000000}}");
              MainMenuBar_Button_Peak_DoubleEXP2_TimeBK:SetProperty("UnifiedPosition", "{{0.000000,760.000000},{0.000000,0.000000}}");
	    end
    end
end

--打开第二个工具条
function MainMenuBar_MainMenuBar_On_Clk()
	TurnMenuBar("on")

	local Upbar2State = SystemSetup:GetUpBar2State()
	if 1 == Upbar2State then
		PushEvent( "OPEN_UP_BAR_2", 1, "UpBar2" )
	end

	PushEvent( "SWITCH_MENU_BUTTON", 1 )

	MainMenuBar_MainMenuBar_On:Hide()
	MainMenuBar_MainMenuBar_Off:Show()
	SystemSetup:SetSubMenubarState( 1 )
end

--关闭第二个工具条
function MainMenuBar_MainMenuBar_Off_Clk()
	TurnMenuBar("off")

	PushEvent( "OPEN_UP_BAR_2", 0, "UpBar2" )

	PushEvent( "SWITCH_MENU_BUTTON", 0 )

	MainMenuBar_MainMenuBar_On:Show()
	MainMenuBar_MainMenuBar_Off:Hide()
	SystemSetup:SetSubMenubarState( 0 )
end

function MainmenuBar_UpdateDur()
	local i = 1;
	local bFlash = false;
	for i=1,9 do
		local ActionIndex = EnumAction( i, "equip");
		if( ActionIndex:GetEquipDur() < 0.1 ) then
			bFlash = true;
		end
	end
	if( g_Character == bFlash ) then
		return;
	else
		if( bFlash ) then
			Button_Character:PlayWarning( 1 );
		else
			Button_Character:PlayWarning( 0 );
		end
	end
	g_Character = bFlash;

end

function MainmenuBar_PageUp()

	if MAINMENUBAR_PAGENUM == 0 then
		MAINMENUBAR_PAGENUM = 2;
	elseif MAINMENUBAR_PAGENUM == 1 then
		MAINMENUBAR_PAGENUM = 0;
	elseif MAINMENUBAR_PAGENUM == 2 then
		MAINMENUBAR_PAGENUM = 1;
	end

	MainmenuBar_UpdateAll();
end

function MainmenuBar_PageDown()

	if MAINMENUBAR_PAGENUM == 0 then
		MAINMENUBAR_PAGENUM = 1;
	elseif MAINMENUBAR_PAGENUM == 1 then
		MAINMENUBAR_PAGENUM = 2;
	elseif MAINMENUBAR_PAGENUM == 2 then
		MAINMENUBAR_PAGENUM = 0;
	end

	MainmenuBar_UpdateAll();
	MainMenuBar_CleanComboFlash();
end

function MainmenuBar_UpdateAll()
	MainMenuBar_ScrollBar_Number:SetText(tostring(MAINMENUBAR_PAGENUM+1));

	for i=0,2 do
		local bShow = (i==MAINMENUBAR_PAGENUM);
		for j=1,10 do
			if i==MAINMENUBAR_PAGENUM then
				MAINMENUBAR_BUTTONS[i*10+j]:Show();
			else
				MAINMENUBAR_BUTTONS[i*10+j]:Hide();
			end
		end
	end
	for k=1,10 do
		MAINMENUBAR_BUTTONS[50+k]:Hide();
	end

	SetMenuBarPageNumber(MAINMENUBAR_PAGENUM);

	MainMenuBar_UpdateButtonTip();
	MainMenuBar_CleanComboFlash();

end

function MainMenuBar_CleanComboFlash()
	for i=1,30 do
	   	COMBOSKILL_FLASH_JUNIOR[i]:Hide()
		COMBOSKILL_FLASH_SENIOR[i]:Hide()
	end
end

function MainmenuBar_EnableTransfigureSkillDrag(flag)

	local PropertyValue = "False"
	if flag == 1 then
		PropertyValue = "True"
	end
	for j=1,10 do
		MAINMENUBAR_BUTTONS[50+j]:SetProperty("DraggingEnabled", PropertyValue)
	end

end

function MainmenuBar_CheckChiJiSkillLevel()
	for j=1,10 do
		local actionbtn = MAINMENUBAR_BUTTONS[50+j]
		local actionId =actionbtn:GetActionItem()
		if  actionbtn:IsVisible() and  actionId > 0 then
			 Lua_CheckChiJiSkillLevel(actionId) 
		end
	end
end

function MainmenuBar_ShowTransfigureSkill( flag )
	local  isCJScene = TLCJ:IsInTLCJScene() 
	if flag == 1 then
		for j=1,10 do
			MAINMENUBAR_BUTTONS[50+j]:Show();
			MAINMENUBAR_BUTTONS[50+j]:SetActionItem(-1);
			for i=0,2 do
				MAINMENUBAR_BUTTONS[i*10+j]:Hide();
			end
		end
		local count =Transfiguration:GetTransfigeActionItemCount()
		local canbeCancel = Transfiguration:TransfigeActionCanbeCancel()
		if canbeCancel == 1 then
			if count >= 2 then --肯定需要大于2，因为有一个取消变身BUFF的技能
				local lastAction = count
				count = count - 1--最后一个固定在MAINMENUBAR_BUTTONS[60]位置，为取消变身技能action
				if(count > 9)then
					count = 9
				end
				local idx = 1;
				for i=0,count-1 do
					local act = Transfiguration:EnumTransfigeAction(tonumber(i));
					if act and act:GetID() ~= 0 then
						MAINMENUBAR_BUTTONS[idx + 50]:SetActionItem(act:GetID());
						MAINMENUBAR_BUTTONS[idx + 50]:Bright()
						Lua_CheckSnowManPVPAction(act:GetID())
						PutActionToMainmenuBar( idx + 50 - 1, act:GetID(), 1 )
						idx = idx +1;
						if(idx>9)then
							break;
						end
					end
				end
				--MAIN_4_BUTTONS[60]位置特殊处理
				if lastAction > 10 then
					lastAction = 10
				end
				local action = Transfiguration:EnumTransfigeAction(tonumber(lastAction) - 1);
				if action and action:GetID() ~= 0 then
					MAINMENUBAR_BUTTONS[60]:SetActionItem(action:GetID());
					MAINMENUBAR_BUTTONS[60]:Bright()
					PutActionToMainmenuBar( 59, action:GetID(), 1 )
				end
				SetMenuBarPageNumber(5);--特写
			end
		else
			if (count <=0) then
				--
			else
				if(count > 10)then
						count = 10
				end
				local nSelfZoneWorldID = DataPool:GetSelfZoneWorldID();
				local idx = 1;
				for i=0,count-1 do
					local act = Transfiguration:EnumTransfigeAction(tonumber(i));
					if act and act:GetID() ~= 0 then
						if ( nSelfZoneWorldID == 9031 or nSelfZoneWorldID == 9015 ) then
							-- 龙门特写 [聚宝盆:变身矿工BUFF的取消变身技能放到F10的位置]
							if ( act:GetDefineID() == 3109 ) then
								MAINMENUBAR_BUTTONS[60]:SetActionItem(act:GetID());
								MAINMENUBAR_BUTTONS[60]:Bright()
								PutActionToMainmenuBar( 59, act:GetID(), 1 )
							else
								MAINMENUBAR_BUTTONS[idx + 50]:SetActionItem(act:GetID());
								MAINMENUBAR_BUTTONS[idx + 50]:Bright()
								PutActionToMainmenuBar( idx + 50 - 1, act:GetID(), 1 )
								idx = idx +1;
								if(idx>10)then
									break;
								end
							end
						else
							MAINMENUBAR_BUTTONS[idx + 50]:SetActionItem(act:GetID());
							if isCJScene~=1 then
								MAINMENUBAR_BUTTONS[idx + 50]:Bright()
							end
							PutActionToMainmenuBar( idx + 50 - 1, act:GetID(), 1 )
							idx = idx +1;
							if(idx>10)then
								break;
							end
						end
					end
					SetMenuBarPageNumber(5);--特写
				end
			end
		end
		if isCJScene > 0 then
			MainmenuBar_EnableTransfigureSkillDrag(1)
			--MainmenuBar_CheckChiJiSkillLevel()
		else
			MainmenuBar_EnableTransfigureSkillDrag(0)
		end
	else
		for j=1,10 do
			PutActionToMainmenuBar( 50 + j - 1, 0, 0 )
			--MAINMENUBAR_BUTTONS[50+j]:Hide();
		end
		MainmenuBar_UpdateAll();
	end
	
	MainMenuBar_UpdateButtonTip();
	MainMenuBar_CleanComboFlash();
end

-- 处理Ctrl+1快捷键
function MainmenuBar_PageOne()
	MAINMENUBAR_PAGENUM = 0;
	MainmenuBar_UpdateAll();
end

-- 处理Ctrl+2快捷键
function MainmenuBar_PageTwo()
	MAINMENUBAR_PAGENUM = 1;
	MainmenuBar_UpdateAll();
end

-- 处理Ctrl+3快捷键
function MainmenuBar_PageThree()
	MAINMENUBAR_PAGENUM = 2;
	MainmenuBar_UpdateAll();
end

function MainMenuBar_UpdateButtonTip()
	local tip,str
	local AcceArryEx = 10   --自定义快捷键数组中前11个元素不允许玩家自定义
	for i=1,10 do
	   str = SystemSetup:GetAcceTip(i + AcceArryEx);
	   tip = string.format( "TopRight %s", str )
	   MAINMENUBAR_BUTTONS[i]:SetProperty("CornerChar", tip);
	   MAINMENUBAR_BUTTONS[i+10]:SetProperty("CornerChar", tip);
	   MAINMENUBAR_BUTTONS[i+20]:SetProperty("CornerChar", tip);
	   MAINMENUBAR_BUTTONS[i+50]:SetProperty("CornerChar", tip);
	end

		local noChatActiveMode = Variable:GetVariable("NonChatActive");
	if noChatActiveMode == "1" then
		Button_Character	:SetToolTip("#{JPYD_130822_1}")
		Button_Pet				:SetToolTip("#{JPYD_130822_3}")
		Button_Mission		:SetToolTip("#{JPYD_130822_4}")
		Button_Exchange	:SetToolTip("#{JPYD_130822_5}")
		Button_Friend		:SetToolTip("#{JPYD_130822_7}")
		Button_Team			:SetToolTip("#{JPYD_130822_8}")
		Button_Reputation:SetToolTip("#{JPYD_130822_9}")
		if ( SystemSetup : IsClassic() == 0 ) then	-- 唯美
			Button_Skills		:SetToolTip("#{JPYD_130822_19}")
			Button_Pack			:SetToolTip("#{JPYD_130822_20}" )
		else
			Button_Skills		:SetToolTip("#{JPYD_130822_2}")
			Button_Pack			:SetToolTip("#{JPYD_130822_6}")
		end
	else
		Button_Character	:SetToolTip("#{INTERFACE_XML_566}")
		Button_Skills			:SetToolTip("#{INTERFACE_XML_346}")
		Button_Pet				:SetToolTip("#{INTERFACE_XML_855}")
		Button_Mission		:SetToolTip("#{INTERFACE_XML_572}" )
		Button_Exchange	:SetToolTip("#{INTERFACE_XML_368}")
		Button_Pack			:SetToolTip("#{INTERFACE_XML_725}" )
		Button_Friend		:SetToolTip("#{INTERFACE_XML_313}")
		Button_Team			:SetToolTip("#{XSYH_XML_44}")
		Button_Reputation:SetToolTip("#{INTERFACE_XML_125}")
	end
end

function MainMenuBar_BattleScore_Clicked()
	City:AskGuildBattleScore();
end

function MainMenuBar_NotifyNewSkills( flag )
	if (flag == 1 ) then
		local nProcess = DataPool:GetCurrentFreshManGuideItemValue();
		if ( nProcess == 22 ) then		--2013Q3新手指引，门派心法指引
			MainMenuBar_FreshManGuide( 1 , -1 , 11 )
		end
		Button_Skills:PlayWarning( 1 );
	else
		Button_Skills:PlayWarning( 0 );
	end
end

function MainMenuBar_UnInstallChatActionButton(index)

	if (index < 0) or (index > 10) then
		return
	end

	-- 得到要卸载的动作包信息
	local actionID, actionValidDate, actionCount, actionMinIndex, actionType = DataPool : Get_RMB_ChatActionInfo(index);
	local realActionID = DataPool : Get_RMB_ChatActionRealID(actionID);

	if realActionID > 0 and actionCount > 0 and actionMinIndex > 0 and actionType > 0 then
		local tmpItem = -1
		-- 清空快捷栏上每一个包含动作包按钮的信息
		for i = 1, MAINMENUBAR_BUTTON_NUM do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = MAINMENUBAR_BUTTONS[i]:GetActionItem();
		  if (tmpItem ~= -1) then
		  	-- 遍历当前动作包中的每一个ActionItem，看看是否有和当前ActionItem的ID相等的。
		  	for j = 1, actionCount do
					local theAction = nil
					if actionType == 2 then
						theAction = Talk : EnumDoubleChatMood(actionMinIndex + j - 2);
					else 
						theAction = Talk : EnumChatMood(actionMinIndex + j - 2);
					end
					if (theAction:GetID() ~= 0) and (theAction:GetID() == tmpItem) then
						MAINMENUBAR_BUTTONS[i] : SetActionItem(-1);						-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i-1);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end
		for i = 51, 60 do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = MAINMENUBAR_BUTTONS[i]:GetActionItem();
		  if (tmpItem ~= -1) then
		  	-- 遍历当前动作包中的每一个ActionItem，看看是否有和当前ActionItem的ID相等的。
		  	for j = 1, actionCount do
					local theAction = nil
					if actionType == 2 then
						theAction = Talk : EnumDoubleChatMood(actionMinIndex + j - 2);
					else 
						theAction = Talk : EnumChatMood(actionMinIndex + j - 2);
					end
					if (theAction:GetID() ~= 0) and (theAction:GetID() == tmpItem) then
						MAINMENUBAR_BUTTONS[i] : SetActionItem(-1);						-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i-1);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end		
	end

	-- 接着删除 MainMenuBar_2 界面上的控件
	DataPool : UnInstall_RMB_ChatAction(index , 2)

end

function MainMenuBar_ClearChatActionButton(index, nID, nData)

	if (index < 0) or (index > 10) then
		return
	end

	-- 得到要卸载的动作包信息
	local actionID, actionValidDate, actionCount, actionMinIndex, actionType = DataPool : Get_RMB_ChatActionInfo(index);
	local realActionID = DataPool : Get_RMB_ChatActionRealID(actionID);

	if realActionID > 0 and actionCount > 0 and actionMinIndex > 0 and actionType > 0 then
		local tmpItem = -1
		-- 清空快捷栏上每一个包含动作包按钮的信息
		for i = 1, MAINMENUBAR_BUTTON_NUM do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = MAINMENUBAR_BUTTONS[i]:GetActionItem();
		  if (tmpItem ~= -1) then
		  	-- 遍历当前动作包中的每一个ActionItem，看看是否有和当前ActionItem的ID相等的。
		  	for j = 1, actionCount do
					local theAction = nil
					if actionType == 2 then
						theAction = Talk : EnumDoubleChatMood(actionMinIndex + j - 2);
					else 
						theAction = Talk : EnumChatMood(actionMinIndex + j - 2);
					end
					local theActionID = theAction:GetID()
					if (theAction:GetID() ~= 0) and (theAction:GetID() == tmpItem) then
						MAINMENUBAR_BUTTONS[i] : SetActionItem(-1);						-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i-1);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end
		for i = 51, 60 do
			-- 得到当前ActionItem在ActionItem总表中的编号
		  tmpItem = MAINMENUBAR_BUTTONS[i]:GetActionItem();
		  if (tmpItem ~= -1) then
		  	-- 遍历当前动作包中的每一个ActionItem，看看是否有和当前ActionItem的ID相等的。
		  	for j = 1, actionCount do
					local theAction = nil
					if actionType == 2 then
						theAction = Talk : EnumDoubleChatMood(actionMinIndex + j - 2);
					else 
						theAction = Talk : EnumChatMood(actionMinIndex + j - 2);
					end
					local theActionID = theAction:GetID()
					if (theAction:GetID() ~= 0) and (theAction:GetID() == tmpItem) then
						MAINMENUBAR_BUTTONS[i] : SetActionItem(-1);						-- 取消按钮上的ActionItem
						DataPool : UnInstall_RMB_ChatAction_BarItem(i-1);			-- 删除MainMenuBar中保存的ActionItem对应记录（编号对应DragName）
					end
				end
		  end
		end		
	end

	-- 继续清理 MainMenuBar_2 界面上的动作包按钮
	DataPool : Clear_ChatAction_Bar("MainMenuBar_2", index, nID, nData);

end


function MainMenuBar_OnOpenGruidClick()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	if IsTBFinalServer() > 0 then
	--如果玩家当前在跨服总决赛特殊服务器,则直接打开雄霸天下界面,不用走其他判断,因为玩家肯定有帮会
		Guild:AskGuildMembersInfo();		--请求帮会数据信息
		ZhanTuanInterface:GetZhanTuanInfo();
		return
	end
  	local guildID, clanID = DataPool:GetGuildClanID()
	local nAllianceID = Player:GetData("AllianceID")




    --- 既没有势力，也没有帮会
    if guildID < 0 and clanID < 0 then
        PushDebugMessage( "你当前尚未加入帮会。请到洛阳（237，236）范纯仁处申请加入帮会，更好地体味江湖。" )
        --- 如果是在K服，还要再谈一条醒目提示
        --if KVKInterface:IsInKVKServer() == 1 then
          --  PushDebugMessage( "#{KVKSL_110628_72}" )
        --end
        return
    end

    --- 如果玩家既有势力，又有帮会
    if guildID >= 0 and (clanID >= 0 or nAllianceID>=0) then
        --- 如果是在K服，打开势力面板
        if KVKInterface:IsInKVKServer() == 1 then
        	if nAllianceID>=0 then --打开战盟界面
        		--如果玩家拥有战盟，其在天外点击帮会按钮时，默认弹出战盟界面
			local alliancemark =0;
          end
        --- 如果是在原服，打开帮会面板
        else
            Guild:ToggleGuildDetailInfo()
        end
        return
    end

    --- 如果玩家没有势力，只有帮会, 无论如何，都打开帮会界面
    if guildID >= 0 and clanID < 0 then
        Guild:ToggleGuildDetailInfo()
        return
    end


    
end




--!!!reloadscript =MainMenuBar
function MainMenuBar_FreshManGuide(nType, nTextID, nPosID)
    if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end

    local fX = 0
    local fY = 0
    if 1 == nPosID then      --1 is Button_Pack
        fX, fY = this:GetChildOffset("Button_Pack")
        fX = fX + Button_Pack:GetProperty("AbsoluteWidth") / 2
    elseif 2 == nPosID then  --2 is Button_Character
        fX, fY = this:GetChildOffset("Button_Character")
        fX = fX + Button_Character:GetProperty("AbsoluteWidth") / 2
    elseif 3 == nPosID then  --3 is Button_Action
        if g_NeedTipID < 0 then
            return
        end
        fX, fY = this:GetChildOffset("MainMenuBar_Button_ActionFrame")
        fX = fX + MAINMENUBAR_BUTTONS[1]:GetProperty("AbsoluteWidth") * (g_NeedTipID + 0.5)
    elseif 4 == nPosID then  --4 is Button_Pet
 --       fX, fY = this:GetChildOffset("Button_Pet")
 --       fX = fX + Button_Pet:GetProperty("AbsoluteWidth") / 2
	local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
	local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Button_Pet")
	local fH = tonumber(Button_Pet:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Button_Pet:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
	fY = math.floor(tonumber(fY + PosY ))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 6, 0, "MainMenuBar")
	if nTextID == 21 then	--2013Q3新修改
		DataPool:SetCurrentFreshManGuideItemValue(21);
	end
	return
    elseif 5 == nPosID then  --5 is Button_Mission
        fX, fY = this:GetChildOffset("Button_Mission")
        fX = fX + Button_Mission:GetProperty("AbsoluteWidth") / 2
        --来点额外工作
        Button_Mission:PlayWarning(1)
    elseif 6 == nPosID then
	local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
	local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Button_Mission")
	local fH = tonumber(Button_Mission:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Button_Mission:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
	fY = math.floor(tonumber(fY + PosY ))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 5, 0, "MainMenuBar")
	return
    elseif 7 == nPosID then
	local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
	local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Button_Pack")
	local fH = tonumber(Button_Pack:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Button_Pack:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
	fY = math.floor(tonumber(fY + PosY ))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 7, 0, "MainMenuBar")
	return
    elseif 8 == nPosID then
	local Action = EnumMainMenuBarAction(6)
	if Action ~= nil and Action:GetID() ~= 0 then
		--2013Q3新手任务指引，如果玩家移动了坐骑的快捷键，或者玩家对技能栏翻页了，就不显示指引箭头了
		if Action:GetDefineID() == 21 and MAINMENUBAR_PAGENUM == 0 then
			local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
			local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
			fX, fY = this:GetChildOffset("Button_Action7")
			local fH = tonumber(Button_Action7:GetProperty("AbsoluteHeight"))
			local fW = tonumber(Button_Action7:GetProperty("AbsoluteWidth"))
			fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
			fY = math.floor(tonumber(fY + PosY ))
			OpenFreshManGuideNew(nType, fX, fY, fW, fH, 9, 0, "MainMenuBar")
		end
	end
	PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",5)
	return
    elseif 9 == nPosID then	--	升级经验满时
	local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
	local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Button_Character")
	local fH = tonumber(Button_Character:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Button_Character:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
	fY = math.floor(tonumber(fY + PosY ))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 4, 0, "MainMenuBar")
	local nLevel = Player:GetData("LEVEL")
	if nLevel == 10 then	--2013Q3新手手动升级指引，只有在10级升11级时出现对话气泡
		PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",12)
	end
	g_ShowCharSelf = 1
	return
	elseif 10 == nPosID then	--新的坐骑指引
	local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
	local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Button_Character")
	local fH = tonumber(Button_Character:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Button_Character:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
	fY = math.floor(tonumber(fY + PosY ))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 8, 0, "MainMenuBar")
	DataPool:SetCurrentFreshManGuideItemValue(20)		--新的坐骑指引界面
	elseif 11 == nPosID then
	local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
	local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Button_Skills")
	local fH = tonumber(Button_Skills:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Button_Skills:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
	fY = math.floor(tonumber(fY + PosY ))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 24, 0, "MainMenuBar")
	return
	elseif 12 == nPosID then
		local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
		local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
		fX, fY = this:GetChildOffset("Button_System")
		local fH = tonumber(Button_System:GetProperty("AbsoluteHeight"))
		local fW = tonumber(Button_System:GetProperty("AbsoluteWidth"))
		fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
		fY = math.floor(tonumber(fY + PosY ))
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 27, 0, "MainMenuBar")
		return
	elseif 13 == nPosID or 14 == nPosID then
		local PosX = tonumber(MainMenuBar:GetProperty("AbsoluteXPosition"))
		local PosY = tonumber(MainMenuBar:GetProperty("AbsoluteYPosition"))
		fX, fY = this:GetChildOffset("Button_Character")
		local fH = tonumber(Button_Character:GetProperty("AbsoluteHeight"))
		local fW = tonumber(Button_Character:GetProperty("AbsoluteWidth"))
		fX = math.floor(tonumber(fX + PosX + (fW * 0.5)))
		fY = math.floor(tonumber(fY + PosY ))
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 31, 0, "MainMenuBar")
		g_ShowCharSelf2 = nPosID
		return
    else
        return               --unkown position
    end
    OpenFreshManGuide(nType, nTextID, fX, fY, "MainMenuBar", "northeast")
end

function MainMenuBar_TimeReach()
	--MainMenuBar_Doub_Text:Hide()
	MainMenuBar_Doub:Hide()
	MainMenuBar_Doub_Watch:Hide()
	MainMenuBar_EXP2:Show()
	MainMenuBar_EXP3:Hide()
	MainMenuBar_DoubleExp_Flash:Hide()
	--MainMenuBar_Doub_Text:SetText("")
end

function MainMenuBar_ShowWatchTooltip()
	local timetips = ""
	local timewatch = MainMenuBar_Doub_Watch:GetProperty("Timer");
	local timecurrent = tonumber(timewatch)
	if(timecurrent == 0 or timecurrent < -1) then
		return
	end

	local  hour;
	local  minute;
	local  second;
	local  day;
	day = math.floor(timecurrent/86400);
	hour =  math.floor(timecurrent/3600);
	minute = math.floor(math.mod(timecurrent, 3600)/60);
	second = math.mod(math.mod(timecurrent, 3600), 60); -- - (60 * minute)//精确校正值 +1
	
	if day == 0 then
		if hour == 0  then
			if second < 10 then
				timetips = minute..":".."0"..second;
			else
				timetips = minute..":"..second;
			end
		else
			timetips = hour.."h"
		end
	else
		timetips = day.."天"
	end
	--local tipsShow = ScriptGlobal_Format("#{IM2BEI_141114_02}", timetips)
	MainMenuBar_Doub_Watch:SetToolTip( "#{IM2BEI_141114_02}" );
end

function MainMenuBar_RefreshCharTip()
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()

	local flag_1 = 0
	if MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1 then
		flag_1 = 1
	end
	
	local flag_2 = 0
	if Exterior:LuaFnIsHaveExteriorShowTip(-1) == 1 then
		flag_2 = 1
	end
	
	local flag_3 = 0
	if Exterior:LuaFnIsHaveHairColorShowTip() == 1 then
		flag_3 = 1
	end

	local flag_4 = 0
	if Exterior:LuaFnIsHaveInfantHairColorShowTip() == 1 then
		flag_4 = 1
    end
	
	local flag_5 = 0
	-- 人物图鉴第一次上线小红点+子女图鉴第一次上线小红点
	if Pneuma:GetMF(2958)==1 or Pneuma:GetMF(2959)== 1 then 
		flag_5 = 1
	end
	
	local flag_6 = 0
	if DataPool:Lua_IsRedPointInUIShow(26) == 1 then
		flag_6 = 1
	end

	local flag_7 = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag_7 = 1
	end

	local flag_8 = 0
	if OrnamentsScript:IsHaveOrnamentsShowTip(-1) == 1 then
		flag_8 = 1
	end
	
	local flag_9 = 0
	local fixRate, expAdd, curState = LuaFnGetCurZongmenTitleInfo()	
	if curState == 1 then
		flag_9 = 1
	end	

	local flag_10 = 0
	if LuaFnGetZongMenSkillRedPoint() == 1 then
		flag_10 = 1
	end	
	
	local flag_11 = MainMenuBar_RefreshCangPinTip()
	
	if flag_1 == 1 or flag_2 == 1 or flag_3 == 1 or flag_4 == 1 or flag_5 == 1 or flag_6 == 1 or flag_7 == 1 or flag_8 == 1 or flag_9 == 1 or flag_10 == 1 or flag_11 == 1 then
		Button_CharacterImage:Show()
	else
		Button_CharacterImage:Hide()
	end
end

function MainMenuBar_RefreshCangPinTip()
	local CangPinClassCount = 4
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	local bTip = 0
	for i = 1, CangPinClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		return 1
	else
		return 0
	end
	
	return 0
end

function MainMenuBar_RefreshPetTip()
	local bShowTip = DataPool:LuaFnHavePetNeiDanChipCanCompound()
	if bShowTip == 1 then
		Button_Pet_Tips:Show()
	else
		Button_Pet_Tips:Hide()
	end
end