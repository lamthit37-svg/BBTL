
--当对象消失的时候，自动关闭这个窗口
local objCared = -1;

local g_MenuType = "";

--战盟成员菜单
local currentKAlliancListIndex = 0
local currentKAlliancListType = 0

--同盟成员菜单
local g_LeagueMemberID = -1;

local currentSelectChannal = "1";
local currentIndex;
local currentGuildListIndex;
local currentRankListIndex;
local currentSelectMember = 0;
local g_showType = "";
local g_Voteinfo_index = 1;

local g_Menu_ObjName = "";
local g_Menu_ObjId = "";

local g_TeamBoard_Guid = "";

--群列表右键菜单
local g_GroupID = -1
local g_Guid = ""

local g_MoveToMenuItem = {}
local g_BGMoveToMenuItem = {}
local g_GroupingName = {}

local g_bDRideFlag = 0; --当前“同骑”显示的标识

local g_bClanInviteApplyFlag = 0    ---当前“势力邀请/申请”显示的标识

---------------------------------------
--团队
local g_CurSelRaidMember = ""
local g_RaidSquadIndex = -1
---------------------------------------

local currentClanListIndex
local currentClanOfficerListIndex   --- 势力官员列表

--	K世界重连相关
local g_KvkRebuildLimitBeginDate = 20140414;
local g_KvkRebuildLimitEndDate = 20140417;
local g_KvkRebuildLimitBeginHour = 900;
local g_KvkRebuildLimitEndHour = 900;

local MailListItem = {}

local g_LEITAI_VIEWER_BUFF = 2711  --- 擂台观战者buff,如果有这个BUFF,屏蔽右键菜单
--孩子 喂水 喂饭什么的
local g_TreatBadStatusAction_btn = {
	"#{ZNJCS_130825_36}",
	"#{ZNJCS_130825_38}",
	"#{ZNJCS_130825_40}",
	"#{ZNJCS_130825_42}"
}
g_FoeListRefresh_Clicked = 0;
local g_KMMemIndex = -1;
local g_FurnitureObj = -1;
local g_CorpsMemIndex = -1;
local g_CorpsMemIndex_2018 = -1;
local g_bztxselectname = ""
local g_guildZhanTuanSelectName = ""
local g_challengeIndex = -1;

--OnLoad
function ContexMenu_PreLoad()
	this:RegisterEvent("SHOW_CONTEXMENU", true);
	this:RegisterEvent("OBJECT_CARED_EVENT", false);
	this:RegisterEvent("HIDE_CONTEXMENU_SPEAKER", false);
	this:RegisterEvent("SCENE_TRANSED", false)
	this:RegisterEvent("UPDATE_FRIEND_INFO", false);
	this:RegisterEvent("UI_COMMAND")
end

function ContexMenu_OnLoad()
    local strTip = GetDictionaryString( "Tip_PVP_Peace" )
    PVP_Peace:SetToolTip( strTip )

    strTip = GetDictionaryString( "Tip_PVP_Moral" )
    PVP_Moral:SetToolTip( strTip )

    strTip = GetDictionaryString( "Tip_PVP_FreeForAll" )
    PVP_FreeforAll:SetToolTip( strTip )

    strTip = GetDictionaryString( "Tip_PVP_FreeForTeam" )
    PVP_FreeforTeam:SetToolTip( strTip )

    --strTip = GetDictionaryString( "Tip_PVP_FreeForGuild" )

	--if KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		--strTip = GetDictionaryString( "KVKBH_140124_58" )
	--else
		--strTip = GetDictionaryString( "TM_20080311_16" )
	--end
	--PVP_FreeforGuild:SetToolTip( strTip )

	--strTip = GetDictionaryString("KVKBH_140124_48")
	--PVP_FreeforKGuild:SetToolTip( strTip );

    strTip = GetDictionaryString( "Tip_PVP_Peace" )
    PVP_Peace_Before21:SetToolTip( strTip )

	g_MoveToMenuItem = {
			ContexMenu_GroupingMoveTo1,
			ContexMenu_GroupingMoveTo2,
			ContexMenu_GroupingMoveTo3,
			ContexMenu_GroupingMoveTo4,
	}
	g_BGMoveToMenuItem = {
			ContexMenu_GroupingMoveTo6,
			ContexMenu_GroupingMoveTo7,
	}
	g_GroupingName = {
							"#{LTQH_XML_79}"	,
							"#{LTQH_XML_80}"	,
							"#{LTQH_XML_81}" 	,
							"#{LTQH_XML_82}"	,
	}

	MailListItem = {
		ContexMenu_MailList_1,
		ContexMenu_MailList_2,
		ContexMenu_MailList_3,
		ContexMenu_MailList_4,
		ContexMenu_MailList_5,
	}
end

function ContexMenu_OnEvent(event)

	local gmType = DataPool:LuaFnGetGMVisibleType()
	if gmType == 1 or gmType == 2  then --观战号和录像号
		return
	end

	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end
	local checkHaveMaskBuff = Lua_CheckMainTargetHaveMaskBuff()	
	if(event == "SCENE_TRANSED" and KVKInterface : IsInKVKServer() == 1) then
		--K服赠送炫装功能屏蔽
		ContexMenu_Present:Disable()
		OtherPlayer_Present:Disable()
		Member_Present:Disable()
		ContexMenu_TeamFollowMember_Present:Disable()
		ContexMenu_TeamLeader_Present:Disable()
		ContexMenu_TeamFollowLeader_Present:Disable()
		OtherPlayer_Model_Open_Other_Present:Disable()
		OtherPlayer_Model_Open_Other_Not_teammer_Present:Disable()
		OtherPlayer_Model_Open_Other_teammer_me_not_teammer_Present:Disable()
		Union1_Menu_Present:Disable()
		Union2_Menu_Present:Disable()
		Union3_Menu_Present:Disable()
		Union4_Menu_Present:Disable()
		Union5_Menu_Present:Disable()
		Raider_NotTeamerNotRaider_Present:Disable()
		NotTeamerNotRaider_Raider_Present:Disable()
		ContexMenu_RaidMember1_Present:Disable()
		ContexMenu_RaidMember2_Present:Disable()
		ContexMenu_RaidMember3_Present:Disable()
		ContexMenu_RaidMember4_Present:Disable()

		--送玫瑰花功能屏蔽
		OtherPlayer_GiveRose_1:Disable()
		OtherPlayer_GiveRose_2:Disable()
		OtherPlayer_GiveRose_3:Disable()
		Raider_NotTeamerNotRaider_Raider_GiveRose:Disable()
		NotTeamerNotRaider_Raider_GiveRose:Disable()

		ContexMenu_ChatBoard_Toushu:Disable()


		OtherPlayer_InviteToGuild:Disable()
		ContexMenu_Model_Open_Other_InviteToGuild:Disable()
		ContexMenu_Model_Open_Other_Not_teammer_InviteToGuild:Disable()
		ContexMenu_Model_Open_Other_teammer_me_InviteToGuild:Disable()
		NotTeamerNotRaider_Raider_InviteToGuild:Disable()


 

	elseif (event == "SCENE_TRANSED" and KVKInterface : IsInKVKServer() == 0) then
		ContexMenu_Present:Enable()
		OtherPlayer_Present:Enable()
		Member_Present:Enable()
		ContexMenu_TeamFollowMember_Present:Enable()
		ContexMenu_TeamLeader_Present:Enable()
		ContexMenu_TeamFollowLeader_Present:Enable()
		OtherPlayer_Model_Open_Other_Present:Enable()
		OtherPlayer_Model_Open_Other_Not_teammer_Present:Enable()
		OtherPlayer_Model_Open_Other_teammer_me_not_teammer_Present:Enable()
		Union1_Menu_Present:Enable()
		Union2_Menu_Present:Enable()
		Union3_Menu_Present:Enable()
		Union4_Menu_Present:Enable()
		Union5_Menu_Present:Enable()
		Raider_NotTeamerNotRaider_Present:Enable()
		NotTeamerNotRaider_Raider_Present:Enable()
		ContexMenu_RaidMember1_Present:Enable()
		ContexMenu_RaidMember2_Present:Enable()
		ContexMenu_RaidMember3_Present:Enable()
		ContexMenu_RaidMember4_Present:Enable()

		--送玫瑰花功能屏蔽
		OtherPlayer_GiveRose_1:Enable()
		OtherPlayer_GiveRose_2:Enable()
		OtherPlayer_GiveRose_3:Enable()
		Raider_NotTeamerNotRaider_Raider_GiveRose:Enable()
		NotTeamerNotRaider_Raider_GiveRose:Enable()

		ContexMenu_ChatBoard_Toushu:Enable()


		OtherPlayer_InviteToGuild:Enable()
		ContexMenu_Model_Open_Other_InviteToGuild:Enable()
		ContexMenu_Model_Open_Other_Not_teammer_InviteToGuild:Enable()
		ContexMenu_Model_Open_Other_teammer_me_InviteToGuild:Enable()
		NotTeamerNotRaider_Raider_InviteToGuild:Enable()




		
		
		ContexMenuFrame_Close()
	end

	if ( event == "SHOW_CONTEXMENU" ) then
		
		g_showType = arg0;
		local isChalView = DataPool:IfHaveBuffByID(g_LEITAI_VIEWER_BUFF)
	    if isChalView == 1 then
	        -- 如果正在观战,不能弹出右键菜单
	        return
	    end
		
		g_FoeListRefresh_Clicked = 0

		if(arg0 == "other_player") then

			local isYF = Lua_CheckMainTargetAndMyselfFromYF()
			if isYF == 1 then
				return
			end	
			local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
			if isZBS == 1 then
				return
			end	
			local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
			if isACS == 1 then
				return
			end	
			--if checkHaveMaskBuff ==  1 then
			--	return 
			--end
			if TLCJ:IsInTLCJScene() > 0 then
				return 
			end
			this:TransAllWindowText();
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");


			ContexMenu_OtherPlayer:SetPopMenuPos(arg2, arg3);
			if Player : GetData( "GUILD" ) == -1 then
				OtherPlayer_InviteToGuild : Disable()
			elseif KVKInterface : IsInKVKServer() == 0 then
				OtherPlayer_InviteToGuild : Enable()
			end

		--	local menuItem = "邀请入帮    "
		--	if Player : GetData( "GUILD" ) == -1 then
		--		menuItem = "#cefefef邀请入帮    "
		--	end

		--	OtherPlayer_InviteToGuild : SetText( menuItem )
			--踢线
			if DataPool:IsSuperman() == false then
				ContexMenu_OtherPlayer_KickGamePlayer:Disable();
			else
				ContexMenu_OtherPlayer_KickGamePlayer:Enable();
			end
	
			nLevel = Target:GetLevel()
			
			ContexMenu_OtherPlayer:Show();

			return;
		end

		-------------------------------------------------------------------------------------------------------------------------
		--
		--  如果是队长打开的菜单
		--
		if(arg0 == "Team_Leader") then
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			if( Player:InTeamFollowMode() ) then
				ContexMenu_TeamFollowLeader:SetPopMenuPos(arg2, arg3);
				ContexMenu_TeamFollowLeader:Show();
			else
				ContexMenu_TeamLeader:SetPopMenuPos(arg2, arg3);
				ContexMenu_TeamLeader:Show();
			end


			currentSelectMember = tonumber( arg4 );

			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 如果是其他队员打开的菜单.
		--
		if(arg0 == "Team_Member") then
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			if( Player:InTeamFollowMode() ) then
				ContexMenu_TeamFollowMember:SetPopMenuPos(arg2, arg3);
				ContexMenu_TeamFollowMember:Show();
			else
				ContexMenu_TeamMember:SetPopMenuPos(arg2, arg3);
				ContexMenu_TeamMember:Show();
			end
			currentSelectMember = arg4;
			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 如果是队员出战珍兽的右键弹出菜单
		-- add by WTT
		--
		if(arg0 == "Team_Member_Pet") then
			ContexMenuFrame_Close();
			this:Show();

			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			-- 设置位置并显示
			ContexMenu_MemberPetMenu:SetPopMenuPos(arg2, arg3);
			ContexMenu_MemberPetMenu:Show();

			return;
		end;


		if(arg0 == "BZTXLIST") then
			ContexMenuFrame_Close();
			this:Show();

			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");
			g_bztxselectname = tostring(arg5)
			-- 设置位置并显示
			ContexMenu_BZTXList:SetPopMenuPos(arg2, arg3);
			ContexMenu_BZTXList:Show();


			return
		end
		if(arg0 == "GUILDZHANTUAN") then
			ContexMenuFrame_Close();
			this:Show();

			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");
			g_guildZhanTuanSelectName = tostring(arg5)
			-- 设置位置并显示
			ContexMenu_FightGroup_Compare:SetPopMenuPos(arg2, arg3);
			ContexMenu_FightGroup_Compare:Show();


			return
		end
		--------------------------------------------------------------------------------------------------------------------------
		--==============================================================
		-- czf modify begin 2010/8/6
		--/****************************************\
		--* 多人坐骑系统
		--* @返回值:
		--*            0	:	啥也不显示
		--*            1	:	显示 “邀请同骑”
		--*            2	:	显示 “取消同骑”（司机点击乘客）
		--*		    3  :   显示 “申请同骑”
		--*			4  :   显示 “解散同骑”
		--*			5  :   显示 “取消同骑”（乘客点击自己）
		--* @param值：
		--*           1：点击自己啦
		--*           0：点击别人啦
		--\****************************************/
		--
		-- 打开自己队伍界面
		--
		
		if(arg0 == "player") then
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			local horse =  GetRideStatic( 1 );
			if( tonumber( horse ) == 0 ) then
				Myself_DisbondRide:Disable();
				g_bDRideFlag = 0;
			elseif( tonumber( horse ) == 1 ) then
				Myself_DisbondRide:Enable();
				Myself_DisbondRide:SetText("邀请同骑");
				g_bDRideFlag = 1;
			elseif( tonumber( horse ) == 2 ) then
				Myself_DisbondRide:Enable();
				Myself_DisbondRide:SetText("取消同骑");
				g_bDRideFlag = 2;
			elseif( tonumber( horse ) == 3 ) then
				Myself_DisbondRide:Enable();
				Myself_DisbondRide:SetText("申请同骑");
				g_bDRideFlag = 3;
			elseif( tonumber( horse ) == 4 ) then
				Myself_DisbondRide:Enable();
				Myself_DisbondRide:SetText("解散同骑");
				g_bDRideFlag = 4;
			elseif( tonumber( horse ) == 5 ) then
				Myself_DisbondRide:Enable();
				Myself_DisbondRide:SetText("取消同骑");
				g_bDRideFlag = 5;
			end

			local Level = Player:GetData( "LEVEL" );

			if( Level > 20 ) then
				--如果玩家在K服,且服务器设置不保留玩家本服的帮会同盟信息,则显示"帮会模式"的K服PK模式
				if KVKInterface:IsEnableGuildLeagueInKServer()<=0 then
					if KVKInterface:IsInKVKServer() == 1 then
						ContexMenu_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode_K" );
					else
						ContexMenu_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode_KGuildLeague" );
					end
				else
					ContexMenu_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode" );
					Menu_PVPMode_T300Set()
				end

				--if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
					--ContexMenu_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode_K" );
				--else
					--ContexMenu_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode" );
				--end

			else
				ContexMenu_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode_Before21" );
			end

			ContexMenu_Self:Show();
			ContexMenu_Self:SetPopMenuPos(arg2, arg3);
			return;
		end;


	  --------------------------------------------------------------------------------------------------------------------------
		--
		-- 自己有队伍, 只打开摆摊按钮界面
		--
		if(arg0 == "player_in_team") then
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");
			local horse =  GetRideStatic( 1 );
			if( tonumber( horse ) == 0 ) then
				Myself_InTeam_DisbondRide:Disable();
				g_bDRideFlag = 0;
			elseif( tonumber( horse ) == 1 ) then
				Myself_InTeam_DisbondRide:Enable();
				Myself_InTeam_DisbondRide:SetText("邀请同骑");
				g_bDRideFlag = 1;
			elseif( tonumber( horse ) == 2 ) then
				Myself_InTeam_DisbondRide:Enable();
				Myself_InTeam_DisbondRide:SetText("取消同骑");
				g_bDRideFlag = 2;
			elseif( tonumber( horse ) == 3 ) then
				Myself_InTeam_DisbondRide:Enable();
				Myself_InTeam_DisbondRide:SetText("申请同骑");
				g_bDRideFlag = 3;
			elseif( tonumber( horse ) == 4 ) then
				Myself_InTeam_DisbondRide:Enable();
				Myself_InTeam_DisbondRide:SetText("解散同骑");
				g_bDRideFlag = 4;
			elseif( tonumber( horse ) == 5 ) then
				Myself_InTeam_DisbondRide:Enable();
				Myself_InTeam_DisbondRide:SetText("取消同骑");
				g_bDRideFlag = 5;
			end

			local Level = Player:GetData( "LEVEL" );

			if( Level > 20 ) then
				--如果玩家在K服,且服务器设置不保留玩家本服的帮会同盟信息,则显示"帮会模式"的K服PK模式
				if KVKInterface:IsEnableGuildLeagueInKServer()<=0 then
					if KVKInterface:IsInKVKServer() == 1 then
						ContexMenu_Self_InTeam_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode_K" );
					else
						ContexMenu_Self_InTeam_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode_KGuildLeague" );
					end
				else
					ContexMenu_Self_InTeam_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode" )
					Menu_PVPMode_T300Set()
				end
			else
				ContexMenu_Self_InTeam_ChangePVPMode:SetProperty( "PopMenu", "Menu_PVPMode_Before21" );
			end

			if Player:IsInTeam() == 1 then
				Myself_QuitTeam:SetText("#{INTERFACE_XML_704}")
			elseif Player:IsInRaid() == 1 then
				Myself_QuitTeam:SetText("#{TDGZ_XML_24}")
			end

			ContexMenu_Self_In_Team:Show();
			ContexMenu_Self_In_Team:SetPopMenuPos(arg2, arg3);
			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 点击其他队友模型, 弹出的对话框
		--
		if(arg0 == "other_team_member") then
			local isYF = Lua_CheckMainTargetAndMyselfFromYF()
			if isYF == 1 then
				return
			end	
			local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
			if isZBS == 1 then
				return
			end	
			local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
			if isACS == 1 then
				return
			end	
			if TLCJ:IsInTLCJScene() > 0 then
				return 
			end
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");


			local horse =  GetRideStatic( 0 );
			--PushDebugMessage("GetRideStatic( 0 ) ="..horse)

			if( tonumber( horse ) == 0 ) then
				ContexMenu_Model_Open_Other_Invite_Ride:Disable();
			elseif( tonumber( horse ) == 1 ) then
				ContexMenu_Model_Open_Other_Invite_Ride:Enable();
				ContexMenu_Model_Open_Other_Invite_Ride:SetText("邀请同骑");
				g_bDRideFlag = 1;
			elseif( tonumber( horse ) == 2 ) then
				ContexMenu_Model_Open_Other_Invite_Ride:Enable();
				ContexMenu_Model_Open_Other_Invite_Ride:SetText("取消同骑");
				g_bDRideFlag = 2;
			elseif( tonumber( horse ) == 3 ) then
				ContexMenu_Model_Open_Other_Invite_Ride:Enable();
				ContexMenu_Model_Open_Other_Invite_Ride:SetText("申请同骑");
				g_bDRideFlag = 3;
			elseif( tonumber( horse ) == 4 ) then
				ContexMenu_Model_Open_Other_Invite_Ride:Enable();
				ContexMenu_Model_Open_Other_Invite_Ride:SetText("解散同骑");
				g_bDRideFlag = 4;
			elseif( tonumber( horse ) == 5 ) then
				ContexMenu_Model_Open_Other_Invite_Ride:Enable();
				ContexMenu_Model_Open_Other_Invite_Ride:SetText("取消同骑");
				g_bDRideFlag = 5;
			end



			if Player : GetData( "GUILD" ) == -1 then
				ContexMenu_Model_Open_Other_InviteToGuild : Disable()
			elseif KVKInterface : IsInKVKServer() == 0 then
				ContexMenu_Model_Open_Other_InviteToGuild : Enable()
			end

			--踢线
			if DataPool:IsSuperman() == false then
				ContexMenu_Model_Open_Other_KickGamePlayer:Disable();
			else
				ContexMenu_Model_Open_Other_KickGamePlayer:Enable();
			end
			
			nLevel = Target:GetLevel()
			
			--举报外挂
			if ContexMenu_IsShowDisclosure() == 1 then
				OtherPlayer_Model_Open_Other_Report:Enable();
			else
				OtherPlayer_Model_Open_Other_Report:Disable();
			end

			ContexMenu_Model_Open_Other:Show();
			ContexMenu_Model_Open_Other:SetPopMenuPos(arg2, arg3);
			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 点击非组队玩家弹出来的界面
		--
		if(arg0 == "other_not_team_member") then
			
			local isYF = Lua_CheckMainTargetAndMyselfFromYF()
			if isYF == 1 then
				return
			end	
			local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
			if isZBS == 1 then
				return
			end	
			local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
			if isACS == 1 then
				return
			end	

			if TLCJ:IsInTLCJScene() > 0 then
				return 
			end
			--if checkHaveMaskBuff ==  1 then
			--	return 
			--end
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			--是否在离线摆摊状态
			local bIsSoState = Target:GetSOState()
			if(bIsSoState == nil or bIsSoState == 0) then
				local horse =  GetRideStatic( 0 );

				--PushDebugMessage("GetRideStatic( 0 ) ="..horse)

				if( tonumber( horse ) == 0 ) then
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:Disable();
					g_bDRideFlag = 0;
				elseif( tonumber( horse ) == 1 ) then
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:Enable();
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:SetText("邀请同骑");
					g_bDRideFlag = 1;
				elseif( tonumber( horse ) == 2 ) then
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:Enable();
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:SetText("取消同骑");
					g_bDRideFlag = 2;
				elseif( tonumber( horse ) == 3 ) then
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:Enable();
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:SetText("申请同骑");
					g_bDRideFlag = 3;
				elseif( tonumber( horse ) == 4 ) then
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:Enable();
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:SetText("解散同骑");
					g_bDRideFlag = 4;
				elseif( tonumber( horse ) == 5 ) then
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:Enable();
					ContexMenu_Model_Open_Other_Not_teammer_Invite_Ride:SetText("取消同骑");
					g_bDRideFlag = 5;
				end


				if Player : GetData( "GUILD" ) == -1 then
					ContexMenu_Model_Open_Other_Not_teammer_InviteToGuild : Disable()
				elseif KVKInterface : IsInKVKServer() == 0 then
					ContexMenu_Model_Open_Other_Not_teammer_InviteToGuild : Enable()
				end

				--踢线
				if DataPool:IsSuperman() == false then
					OtherPlayer_Model_Open_Other_Not_teammer_KickGamePlayer:Disable();
				else
					OtherPlayer_Model_Open_Other_Not_teammer_KickGamePlayer:Enable();
				end

				nLevel = Target:GetLevel()
			
				--举报外挂
				if ContexMenu_IsShowDisclosure() == 1 then
					OtherPlayer_Model_Open_Other_Not_teammer_Report:Enable();
				else
					OtherPlayer_Model_Open_Other_Not_teammer_Report:Disable();
				end

				ContexMenu_Model_Open_Other_Not_teammer:Show();
				ContexMenu_Model_Open_Other_Not_teammer:SetPopMenuPos(arg2, arg3);
			else
				--在离线摆摊状态
				ContexMenu_OffLineSaleItem:Enable()
				ContexMenu_OffLineSale:Show();
				ContexMenu_OffLineSale:SetPopMenuPos(arg2, arg3)
			end

			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 非组队玩家, 点击组队玩家, 弹出的菜单
		--
		if(arg0 == "other_team_member_me_not_teamer") then
			local isYF = Lua_CheckMainTargetAndMyselfFromYF()
			if isYF == 1 then
				return
			end	
			local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
			if isZBS == 1 then
				return
			end	
			local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
			if isACS == 1 then
				return
			end	
			if TLCJ:IsInTLCJScene() > 0 then
				return 
			end
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");
			local horse =  GetRideStatic( 0 );

			if( tonumber( horse ) == 0 ) then
				ContexMenu_Model_Open_Other_teammer_me_Ride:Disable();
				g_bDRideFlag = 0;
			elseif( tonumber( horse ) == 1 ) then
				ContexMenu_Model_Open_Other_teammer_me_Ride:Enable();
				ContexMenu_Model_Open_Other_teammer_me_Ride:SetText("邀请同骑");
				g_bDRideFlag = 1;
			elseif( tonumber( horse ) == 2 ) then
				ContexMenu_Model_Open_Other_teammer_me_Ride:Enable();
				ContexMenu_Model_Open_Other_teammer_me_Ride:SetText("取消同骑");
				g_bDRideFlag = 2;
			elseif( tonumber( horse ) == 3 ) then
				ContexMenu_Model_Open_Other_teammer_me_Ride:Enable();
				ContexMenu_Model_Open_Other_teammer_me_Ride:SetText("申请同骑");
				g_bDRideFlag = 3;
			elseif( tonumber( horse ) == 4 ) then
				ContexMenu_Model_Open_Other_teammer_me_Ride:Enable();
				ContexMenu_Model_Open_Other_teammer_me_Ride:SetText("解散同骑");
				g_bDRideFlag = 4;
			elseif( tonumber( horse ) == 5 ) then
				ContexMenu_Model_Open_Other_teammer_me_Ride:Enable();
				ContexMenu_Model_Open_Other_teammer_me_Ride:SetText("取消同骑");
				g_bDRideFlag = 5;
			end




			if Player : GetData( "GUILD" ) == -1 then
				ContexMenu_Model_Open_Other_teammer_me_InviteToGuild : Disable()
			elseif KVKInterface : IsInKVKServer() == 0 then
				ContexMenu_Model_Open_Other_teammer_me_InviteToGuild : Enable()
			end

			--踢线
			if DataPool:IsSuperman() == false then
				ContexMenu_Model_Open_Other_teammer_me_not_teammer_KickGamePlayer:Disable();
			else
				ContexMenu_Model_Open_Other_teammer_me_not_teammer_KickGamePlayer:Enable();
			end

			nLevel = Target:GetLevel()
			
			--举报外挂
			if ContexMenu_IsShowDisclosure() == 1 then
				OtherPlayer_Model_Open_Other_teammer_me_not_teammer_Report:Enable();
			else
				OtherPlayer_Model_Open_Other_teammer_me_not_teammer_Report:Disable();
			end

			ContexMenu_Model_Open_Other_teammer_me_not_teammer:Show();
			ContexMenu_Model_Open_Other_teammer_me_not_teammer:SetPopMenuPos(arg2, arg3);
			return;
		end;
		-- czf modify end
		--==============================================================
		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 点击聊天里的人物名, 弹出的菜单
		--
		if(arg0 == "chat_private") then
			if checkHaveMaskBuff ==  1 then
				return 
			end
			ContexMenu_HideAll();
			this:Show();
			--关心NPC
			g_MenuType = arg1;
			if tonumber(arg4) == 2 then
				--原服出现大世界超链接，弹出新的菜单
				ContexMenu_ChatBoard_NoToushu_KVK:Show()
				ContexMenu_ChatBoard_NoToushu_KVK:SetPopMenuPos(arg2,arg3);
			elseif (tonumber(arg4)==1)then
				if Player:IsInTeam() == 1 then
					ContexMenu_ChatBoard_RaidInvite:Disable()
					ContexMenu_ChatBoard_RaidApply:Disable()
				elseif Player:IsInRaid() == 1 then
					if Player:IsRaidLeader() == 1 or Player:IsRaidAssitant() == 1 then
						ContexMenu_ChatBoard_RaidInvite:Enable()
					else
						ContexMenu_ChatBoard_RaidInvite:Disable()
					end
					ContexMenu_ChatBoard_RaidApply:Disable()
				else
					ContexMenu_ChatBoard_RaidInvite:Disable()
					ContexMenu_ChatBoard_RaidApply:Enable()
				end

				ContexMenu_ChatBoard:Show();
				ContexMenu_ChatBoard:SetPopMenuPos(arg2,arg3);
			elseif (tonumber(arg4)==3) then
				if (KVKInterface : IsInKVKServer() == 0) then
					ContexMenu_SecretChatBoard:Show();
					ContexMenu_SecretChatBoard:SetPopMenuPos(arg2,arg3);
				end
			else
				if Player:IsInTeam() == 1 then
					ContexMenu_ChatBoard_RaidInvite_NoToushu:Disable()
					ContexMenu_ChatBoard_RaidApply_NoToushu:Disable()
				elseif Player:IsInRaid() == 1 then
					ContexMenu_ChatBoard_RaidInvite_NoToushu:Enable()
					ContexMenu_ChatBoard_RaidApply_NoToushu:Disable()
				else
					ContexMenu_ChatBoard_RaidInvite_NoToushu:Disable()
					ContexMenu_ChatBoard_RaidApply_NoToushu:Enable()
				end

				ContexMenu_ChatBoard_NoToushu:Show();
				ContexMenu_ChatBoard_NoToushu:SetPopMenuPos(arg2,arg3);
			end

			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 点击组队平台里的人物名, 弹出的菜单
		--
		if(arg0 == "teamboard_info") then
			ContexMenu_HideAll();
			this:Show();
			ContexMenu_TeamBoard:Show();
			ContexMenu_TeamBoard:SetPopMenuPos(arg1,arg2);
			g_TeamBoard_Guid = arg3;
			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 点击征友投票人后 , 弹出的菜单
		--
		if(arg0 == "findfrind_vote") then
			ContexMenu_HideAll();
			this:Show();
			g_MenuType = arg1;
			g_Voteinfo_index = tonumber(arg4);   --现在是第几条
			ContexMenu_FindFriend_VoteInfo:Show();
			ContexMenu_FindFriend_VoteInfo:SetPopMenuPos(arg2,arg3);

			return;
		end;

		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 点击好友列表理
		--
		if( arg0 == "friendmenu" ) then
			local isYF = Lua_CheckMainTargetAndMyselfFromYF()
			if isYF == 1 then
				return
			end	
			local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
			if isZBS == 1 then
				return
			end	
			local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
			if isACS == 1 then
				return
			end	
			if TLCJ:IsInTLCJScene() > 0 then
				return 
			end

			--if checkHaveMaskBuff ==  1 then
			--	return 
			--end
			currentSelectChannal = arg2;
			currentIndex = arg3;
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			if( tonumber( arg2 ) == 5 ) or (tonumber( arg2 ) == 10 )then
				ContexMenu_BlackListMenu:Show();
				ContexMenu_BlackListMenu:SetPopMenuPos(arg4,arg5);
			elseif( tonumber( arg2 ) == 6 )then
				ContexMenu_EnmeyListMenu:Show();
				ContexMenu_EnmeyListMenu:SetPopMenuPos(arg4,arg5);
				ContexMenu_EnemyGroupingFoe:Enable()
				ContexMenu_EnmeyListGroupChange:SetProperty( "PopMenu", "ContexMenu_EnemyGroupingMenu" );
			elseif(tonumber(arg2) == 7) then
				ContexMenu_FoeListMenu:Show();
				ContexMenu_FoeListMenu:SetPopMenuPos(arg4, arg5);
			elseif( tonumber( arg2 ) == 10 ) then
				ContexMenu_BlackListMenu:Show();
				ContexMenu_BlackListMenu:SetPopMenuPos(arg4,arg5);
			elseif( tonumber( arg2 ) == 11 ) then
				ContexMenu_EnmeyListMenu:Show();
				ContexMenu_EnmeyListMenu:SetPopMenuPos(arg4,arg5);
				ContexMenu_EnmeyListGroupChange:SetProperty( "PopMenu", "ContexMenu_BGGroupingMenu" );
				ContexMenu_EnemyGroupingFoe:Disable()
			elseif( tonumber( arg2 ) == 9 or tonumber( arg2 ) == 8 or tonumber( arg2 ) == 14 ) then
				ContexMenu_FriendHistroy:Disable()
				ContexMenu_SendMail:Disable()
				if Player:IsInTeam() == 1 then
					ContexMenu_Friend_RaidInvite:Disable()
					ContexMenu_Friend_RaidApply:Disable()
				elseif Player:IsInRaid() == 1 then
					ContexMenu_Friend_RaidInvite:Enable()
					ContexMenu_Friend_RaidApply:Disable()
				else
					ContexMenu_Friend_RaidInvite:Disable()
					ContexMenu_Friend_RaidApply:Enable()
				end
				ContexMenu_Present:Disable()
				ContexMenu_FriendMenu:Show();
				ContexMenu_FriendMenu:SetPopMenuPos(arg4,arg5);
				ContexMenu_GroupChange:SetProperty( "PopMenu", "ContexMenu_BGGroupingMenu" );
				--ContexMenu_GroupChange:Disable()
				local strGroupName = ""
				for i = 0 , 1 do
					strGroupName = DataPool:GetGroupingName(i + 7)
					if strGroupName ~= "" then
						g_BGMoveToMenuItem[i+1]:SetText("移动到"..strGroupName)
					else
						g_BGMoveToMenuItem[i+1]:SetText("移动到"..g_GroupingName[i+1])
					end
				end
			else
				ContexMenu_FriendHistroy:Enable()
				ContexMenu_SendMail:Enable()
				if Player:IsInTeam() == 1 then
					ContexMenu_Friend_RaidInvite:Disable()
					ContexMenu_Friend_RaidApply:Disable()
				elseif Player:IsInRaid() == 1 then
					ContexMenu_Friend_RaidInvite:Enable()
					ContexMenu_Friend_RaidApply:Disable()
				else
					ContexMenu_Friend_RaidInvite:Disable()
					ContexMenu_Friend_RaidApply:Enable()
				end


				local relationtype = DataPool:GetFriend( tonumber( arg2 ), tonumber( arg3 ), "RELATION_TYPE" )
				local guid =  DataPool:GetFriend( tonumber( arg2 ), tonumber( arg3 ), "ID" )

				if relationtype == 2 or relationtype == 3 or
					(relationtype == 7 and Friend:Lua_IsShimenMemberInfoValid() == 1) or relationtype == 8  then
					ContexMenu_Beizhu:Disable()
					ContexMenu_GroupChange:Disable()
					ContexMenu_DelFriend:Disable()
				elseif Friend:Lua_IsShimenMemberInfoValid() == 1 and Friend:Lua_IsSameMasterWithMe(guid) == 1 then
					ContexMenu_Beizhu:Disable()
					ContexMenu_GroupChange:Disable()
					ContexMenu_DelFriend:Enable()
				else
					ContexMenu_Beizhu:Enable()
					ContexMenu_GroupChange:Enable()
					ContexMenu_DelFriend:Enable()
					ContexMenu_GroupChange:SetProperty( "PopMenu", "ContexMenu_GroupingMenu" );
					local strGroupName = ""
					for i = 0 , 3 do
						strGroupName = DataPool:GetGroupingName(i)
						if strGroupName ~= "" then
							g_MoveToMenuItem[i+1]:SetText("移动到"..strGroupName)
						else
							g_MoveToMenuItem[i+1]:SetText("移动到"..g_GroupingName[i+1])
						end
					end
				end

				ContexMenu_FriendMenu:Show();
				ContexMenu_FriendMenu:SetPopMenuPos(arg4,arg5);

			end
			return;
		end

--------------------------------------------------------------------------------------------------------------------------
		--
		-- 点击好友列表理
		--
		if( arg0 == "groupingmenu" ) then

			currentSelectChannal = arg2;
			currentIndex = arg3;
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");
			if (tonumber(arg2) >= 8 and tonumber(arg2) <= 11) or (tonumber(arg2) == 14) then
				ContexMenu_BGGroupingMenu:Show();
				ContexMenu_BGGroupingMenu:SetPopMenuPos(arg4,arg5);
				local strGroupName = ""
				for i = 0 , 1 do
					strGroupName = DataPool:GetGroupingName(i + 7)
					if strGroupName ~= "" then
						g_BGMoveToMenuItem[i+1]:SetText("移动到"..strGroupName)
					else
						g_BGMoveToMenuItem[i+1]:SetText("移动到"..g_GroupingName[i+1])
					end
				end
			else
				ContexMenu_GroupingMenu:Show();
				ContexMenu_GroupingMenu:SetPopMenuPos(arg4,arg5);

				local strGroupName = ""
				for i = 0 , 3 do
					strGroupName = DataPool:GetGroupingName(i)
					if strGroupName ~= "" then
						g_MoveToMenuItem[i+1]:SetText("移动到"..strGroupName)
					else
						g_MoveToMenuItem[i+1]:SetText("移动到"..g_GroupingName[i+1])
					end
				end
			end
			return;
		end
--------------------------------------------------------------------------------------------------------------------------
		--
		-- 地图上自己宠物的菜单
		--
		if( arg0 == "my_pet" ) then
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			ContexMenu_MyPetMenu:Show();
			ContexMenu_MyPetMenu:SetPopMenuPos(arg2,arg3);
			return;
		end

		if( arg0 == "my_pet_from_petframe" ) then
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			ContexMenu_MyPetMenuFromPetFrame:Show();
			ContexMenu_MyPetMenuFromPetFrame:SetPopMenuPos(arg2,arg3);
			return;
		end
--------------------------------------------------------------------------------------------------------------------------
		--
		-- 地图上其他宠物的菜单
		--
		if( arg0 == "other_pet" ) then
			local isYF = Lua_CheckMainTargetAndMyselfFromYF()
			if isYF == 1 then
				return
			end	
			local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
			if isZBS == 1 then
				return
			end	
			local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
			if isACS == 1 then
				return
			end	
			if TLCJ:IsInTLCJScene() > 0 then
				return 
			end

			if checkHaveMaskBuff ==  1 then
				return 
			end
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			ContexMenu_OtherPetMenu:Show();
			ContexMenu_OtherPetMenu:SetPopMenuPos(arg2,arg3);
			return;
		end
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
         --
         -- 地图上自己萌宠的菜单
		 --
		-- if( arg0 == "my_cutepet" ) then
			--ContexMenuFrame_Close();
		--	this:Show();
			--关心NPC
			--objCared = tonumber(arg1);
			--this:CareObject(objCared, 1, "ContexMenu");

			--ContexMenu_BieYeCutePet:Show();
			--ContexMenu_BieYeCutePet:SetPopMenuPos(arg2,arg3);
			--return;
		--end
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
		--
		-- 地图上其他孩子的菜单
		--
		if( arg0 == "other_infant" ) then
			local isYF = Lua_CheckMainTargetAndMyselfFromYF()
			if isYF == 1 then
				return
			end	
			local isZBS = Lua_CheckMainTargetAndMyselfFromZBS()
			if isZBS == 1 then
			    return
			end	
			local isACS = ANS:Lua_CheckMainTargetAndMyselfFromAnonymousCommon()
			if isACS == 1 then
			    return
			end	
			if TLCJ:IsInTLCJScene() > 0 then
				return 
			end
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			ContexMenu_OtherInfant:Show();
			ContexMenu_OtherInfant:SetPopMenuPos(arg2,arg3);
			return;
		end
		--
		-- 地图上自己孩子的菜单
		--
		if( arg0 == "my_infant" ) then
			ContexMenuFrame_Close();
			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");
			--就一个孩子就直接写0了
			--如果以后有多个孩子可以写一个接口，获取当前出战孩子的index
			local badStatus = 0--Infant:GetStatus(0)
--~ 			if badStatus == 0 then
--~ 				ContexMenu_SelfInfant_Hudong:Disable();
--~ 			else
--~ 				ContexMenu_SelfInfant_Eat:Enable();
--~ 				ContexMenu_SelfInfant_Drink:Enable()
--~ 				ContexMenu_SelfInfant_Wash:Enable()
--~ 			end

			ContexMenu_SelfInfant:Show();
			ContexMenu_SelfInfant:SetPopMenuPos(arg2,arg3);
			return;
		end
--------------------------------------------------------------------------------------------------------------------------
		--
		-- pk模式菜单
		--
		if( arg0 == "PKmode" ) then
			ContexMenuFrame_Close();
			this:Show();
			if(tonumber(arg1)==0)then

				Menu_PVPMode_Before21:Show();
				Menu_PVPMode_Before21:SetPopMenuPos(arg2,arg3);
			else
				--如果玩家在K服,且服务器设置不保留玩家本服的帮会同盟信息,则显示"帮会模式"的K服PK模式
				if KVKInterface:IsEnableGuildLeagueInKServer()<=0 then
					if KVKInterface:IsInKVKServer() == 1 then
						Menu_PVPMode_K:Show();
						Menu_PVPMode_K:SetPopMenuPos(arg2,arg3);
					else
						Menu_PVPMode_KGuildLeague:Show();
						Menu_PVPMode_KGuildLeague:SetPopMenuPos(arg2,arg3);
					end
				else
					Menu_PVPMode:Show();
					Menu_PVPMode:SetPopMenuPos(arg2,arg3)
					Menu_PVPMode_T300Set()					
				end

				--if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
					--Menu_PVPMode_K:Show();
					--Menu_PVPMode_K:SetPopMenuPos(arg2,arg3);
				--else
					--Menu_PVPMode:Show();
					--Menu_PVPMode:SetPopMenuPos(arg2,arg3);
				--end
			end
			return;
		end
--------------------------------------------------------------------------------------------------------------------------
		--
		-- 帮会成员
		--
		if( arg0 == "GUILDLIST" ) then
			currentGuildListIndex = arg2;
			if(tonumber(arg5)==0)  then
				return;
			elseif(tonumber(arg5)==1) then
				ContexMenuFrame_Close();
				this:Show();
				if Player:IsInTeam() == 1 then
					ContexMenu_GuildList_RaidInvite:Disable()
					ContexMenu_GuildList_RaidApply:Disable()
				elseif Player:IsInRaid() == 1 then
					ContexMenu_GuildList_RaidInvite:Enable()
					ContexMenu_GuildList_RaidApply:Disable()
				else
					ContexMenu_GuildList_RaidInvite:Disable()
					ContexMenu_GuildList_RaidApply:Enable()
				end
				ContexMenu_GuildList:Show();
				ContexMenu_GuildList:SetPopMenuPos(arg3,arg4);
			elseif(tonumber(arg5)==2) then
				return;
			end

			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			return;
		end


		--同盟成员
		if arg0 == "GuildLeagueMember" then
				g_LeagueMemberID = tonumber(arg1);
				ContexMenuFrame_Close();
				this:Show();
				ContexMenu_GuildLeagueMember:Show();
				ContexMenu_GuildLeagueMember:SetPopMenuPos(arg2,arg3);
		end
--------------------------------------------------------------------------------------------------------------------------
		--弹出右键菜单For"官员列表"
		--add by xindefeng
		if( arg0 == "OfficialPopMenu" ) then
			currentGuildListIndex = arg2
			local type = tonumber(arg5)--选择类型
			if(type == 0)  then	--自己
				return;
			elseif(type == 1) then	--在线
				ContexMenuFrame_Close();
				this:Show();
				ContexMenu_OfficialPopMenu:Show();
				ContexMenu_OfficialPopMenu:SetPopMenuPos(arg3,arg4);
			elseif(type == 2) then	--不在线
				return
			end

			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu")

			return
		end
		if( arg0 == "TrustFriend" ) then

			ContexMenuFrame_Close();
			this:Show();
			ContexMenu_TrustFriendMenu:Show();
			ContexMenu_TrustFriendMenu:SetPopMenuPos(arg1,arg2);

			g_Menu_ObjName	= arg3;
			g_Menu_ObjId	= arg4;

			return
		end
		--群列表的右键菜单
		if (arg0 == "ChatGroupMenu") then
			ContexMenuFrame_Close();
			this:Show();
			g_GroupID = tonumber(arg1);

			local ownerid = DataPool:GetChatGroupChiefIDByGroupID(g_GroupID)
			local myGuid = Player:GetGUID();
			--群主
			if myGuid == ownerid then
				if DataPool:IsGroupMute(g_GroupID) == 1 then
					MyGroup_OwnerMenu_SetHide:SetText("#{LTQH_XML_56}")
				else
					MyGroup_OwnerMenu_SetHide:SetText("#{LTQH_XML_5}")
				end
				MyGroup_OwnerMenu:Show();
				MyGroup_OwnerMenu:SetPopMenuPos(arg2,arg3);
			else
			--非群主
				if DataPool:IsGroupMute(g_GroupID) == 1 then
					MyGroup_Menu_SetHide:SetText("#{LTQH_XML_56}")
				else
					MyGroup_Menu_SetHide:SetText("#{LTQH_XML_5}")
				end
				MyGroup_Menu:Show();
				MyGroup_Menu:SetPopMenuPos(arg2,arg3);
			end
			return;
		end

		if (arg0 == "GroupUserMenu") then
			ContexMenuFrame_Close();
			this:Show();
			g_GroupID = tonumber(arg1);
			g_Guid = arg2;
			local ownerid = DataPool:GetChatGroupChiefIDByGroupID(g_GroupID)
			local myGuid = Player:GetGUID();
			local bLeader = 0;
			local bInTorR = 0;

			if Player:IsInTeam() == 1 then
				bInTorR = 1;
			end
			if Player:IsInRaid() == 1 then
				bInTorR = 1;
			end


			--根据是否为团长来显示团队选项
			if Player:IsRaidLeader() == 1 or Player:IsRaidAssitant() == 1 then
				bLeader = 1;
			end
			--群主
			if myGuid == ownerid then
				ChatGroup_OwnerMenu:Show();
				if bLeader == 1 then
					ChatGroup_OwnerMenu_GWRaidInvite:Enable();
				else
					ChatGroup_OwnerMenu_GWRaidInvite:Disable();
				end

				if bInTorR == 1 then
					ChatGroup_OwnerMenu_GWRaidApply:Disable()
				else
					ChatGroup_OwnerMenu_GWRaidApply:Enable()
				end
				ChatGroup_OwnerMenu:SetPopMenuPos(arg3,arg4);
			else
			--非群主
				ChatGroup_Menu:Show();
				if bLeader == 1 then
					ChatGroup_Menu_GWRaidInvite:Enable();
				else
					ChatGroup_Menu_GWRaidInvite:Disable()
				end

				if bInTorR == 1 then
					ChatGroup_Menu_GWRaidApply:Disable()
				else
					ChatGroup_Menu_GWRaidApply:Enable()
				end
				ChatGroup_Menu:SetPopMenuPos(arg3,arg4);
			end
			return;
		end

------------------------------------------------------------------------------------
--团队
		if(arg0 == "Raider_NotTeamerNotRaider") then
			ContexMenuFrame_Close();

			local horse =  GetRideStatic( 0 );
			if( tonumber( horse ) == 0 ) then
				Raider_NotTeamerNotRaider_InviteToRide:Disable();
				g_bDRideFlag = 0
			elseif( tonumber( horse ) == 1 ) then
				Raider_NotTeamerNotRaider_InviteToRide:Enable();
				Raider_NotTeamerNotRaider_InviteToRide:SetText("邀请同骑");
				g_bDRideFlag = 1;
			elseif( tonumber( horse ) == 2 ) then
				Raider_NotTeamerNotRaider_InviteToRide:Enable();
				Raider_NotTeamerNotRaider_InviteToRide:SetText("取消同骑");
				g_bDRideFlag = 2;
			elseif( tonumber( horse ) == 3 ) then
				Raider_NotTeamerNotRaider_InviteToRide:Enable();
				Raider_NotTeamerNotRaider_InviteToRide:SetText("申请同骑");
				g_bDRideFlag = 3;
			elseif( tonumber( horse ) == 4 ) then
				Raider_NotTeamerNotRaider_InviteToRide:Enable();
				Raider_NotTeamerNotRaider_InviteToRide:SetText("解散同骑");
				g_bDRideFlag = 4;
			elseif( tonumber( horse ) == 5 ) then
				Raider_NotTeamerNotRaider_InviteToRide:Enable();
				Raider_NotTeamerNotRaider_InviteToRide:SetText("取消同骑");
				g_bDRideFlag = 5;
			end



			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");
			--踢线
			if DataPool:IsSuperman() == false then
				Raider_NotTeamerNotRaider_KickGamePlayer:Disable();
			else
				Raider_NotTeamerNotRaider_KickGamePlayer:Enable();
			end

			--举报外挂
			if ContexMenu_IsShowDisclosure() == 1 then
				Raider_NotTeamerNotRaider_Report:Enable();
			else
				Raider_NotTeamerNotRaider_Report:Disable();
			end

			Raider_NotTeamerNotRaider:Show()
			Raider_NotTeamerNotRaider:SetPopMenuPos(arg2, arg3)

			nLevel = Target:GetLevel()
			
			return
		end

		if(arg0 == "NotTeamerNotRaider_Raider") then
			ContexMenuFrame_Close()

			if Player:GetData("GUILD") == -1 then
				NotTeamerNotRaider_Raider_InviteToGuild:Disable()
			elseif KVKInterface : IsInKVKServer() == 0 then
				NotTeamerNotRaider_Raider_InviteToGuild:Enable()
			end

			local horse =  GetRideStatic( 0 );
			if( tonumber( horse ) == 0 ) then
				NotTeamerNotRaider_Raider_InviteToRide:Disable();
				g_bDRideFlag = 0
			elseif( tonumber( horse ) == 1 ) then
				NotTeamerNotRaider_Raider_InviteToRide:Enable();
				NotTeamerNotRaider_Raider_InviteToRide:SetText("邀请同骑");
				g_bDRideFlag = 1;
			elseif( tonumber( horse ) == 2 ) then
				NotTeamerNotRaider_Raider_InviteToRide:Enable();
				NotTeamerNotRaider_Raider_InviteToRide:SetText("取消同骑");
				g_bDRideFlag = 2;
			elseif( tonumber( horse ) == 3 ) then
				NotTeamerNotRaider_Raider_InviteToRide:Enable();
				NotTeamerNotRaider_Raider_InviteToRide:SetText("申请同骑");
				g_bDRideFlag = 3;
			elseif( tonumber( horse ) == 4 ) then
				NotTeamerNotRaider_Raider_InviteToRide:Enable();
				NotTeamerNotRaider_Raider_InviteToRide:SetText("解散同骑");
				g_bDRideFlag = 4;
			elseif( tonumber( horse ) == 5 ) then
				NotTeamerNotRaider_Raider_InviteToRide:Enable();
				NotTeamerNotRaider_Raider_InviteToRide:SetText("取消同骑");
				g_bDRideFlag = 5;
			end



			this:Show();
			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			--踢线
			if DataPool:IsSuperman() == false then
				NotTeamerNotRaider_Raider_KickGamePlayer:Disable();
			else
				NotTeamerNotRaider_Raider_KickGamePlayer:Enable();
			end

			--举报外挂
			if ContexMenu_IsShowDisclosure() == 1 then
				NotTeamerNotRaider_Raider_Report:Enable();
			else
				NotTeamerNotRaider_Raider_Report:Disable();
			end

			NotTeamerNotRaider_Raider:Show()
			NotTeamerNotRaider_Raider:SetPopMenuPos(arg2, arg3)

			nLevel = Target:GetLevel()
			
			return
		end

		if(arg0 == "RaidFrame_Menu") then
			ContexMenuFrame_Close()

			local menuType = tonumber(arg1)
			g_CurSelRaidMember = arg2
			if menuType == 1 then
				Union1_Menu:Show()
				Union1_Menu:SetPopMenuPos(arg3, arg4)
			elseif menuType == 2 then
				Union2_Menu:Show()
				Union2_Menu:SetPopMenuPos(arg3, arg4)
			elseif menuType == 3 then
				Union3_Menu:Show()
				Union3_Menu:SetPopMenuPos(arg3, arg4)
			elseif menuType == 4 then
				Union4_Menu:Show()
				Union4_Menu:SetPopMenuPos(arg3, arg4)
			elseif menuType == 5 then
				Union5_Menu:Show()
				Union5_Menu:SetPopMenuPos(arg3, arg4)
			elseif menuType == 6 then
				Union6_Menu:Show()
				Union6_Menu:SetPopMenuPos(arg3, arg4)
			end

			this:Show()
			return
		end
		if(arg0 == "squadmemwindow") then
			ContexMenuFrame_Close()

			g_CurSelRaidMember = arg1
			local squad,mem = Raid:GetMemberIndexByGUID(g_CurSelRaidMember)
			Raid:SelectAsTargetByIdx(squad, mem)
			UISquadMemWindow_Menu:SetPopMenuPos(arg2, arg3)
			UISquadMemWindow_Menu:Show()
			this:Show()
			return
		end

		if(arg0 == "raidsquadwindow") then
			ContexMenuFrame_Close()
			g_RaidSquadIndex = tonumber(arg1)
			UIRaidSquadWindow_Menu:SetPopMenuPos(arg2, arg3)
			UIRaidSquadWindow_Menu:Show()
			this:Show()
			return
		end

		--Add By YPL, 2011-12-05
		if(arg0 == "groupwindow_show") then
			--读取参数
			g_RaidSquadIndex = tonumber(arg1)
			--关闭旧窗口
			if (g_RaidSquadIndex == 0) or (g_RaidSquadIndex == 1) or (g_RaidSquadIndex == 2) or (g_RaidSquadIndex == 3) or (g_RaidSquadIndex == 4) then
			else
				return
			end
			Raid:CloseRaidSquadWindowByIdx(g_RaidSquadIndex)
			local state = GetShowState(g_RaidSquadIndex)
			--Add By YPL, 2011-12-14
			local pos_x = tonumber(arg2)
			local pos_y = tonumber(arg3)
			--End
			--Modify By YPL, 2011-12-14
			--local ret = Raid:OpenRaidSquadWindowByIdx(g_RaidSquadIndex, state)
			local ret = 0
			if state == 0 then
				ret = Raid:OpenRaidSquadWindowByIdx(g_RaidSquadIndex, 1, pos_x, pos_y)
			else
				ret = Raid:OpenRaidSquadWindowByIdx(g_RaidSquadIndex, 0, pos_x, pos_y)
			end
			--End
			if ret ~= 1 then
				return
			end
			if state == 0 then
				SetShowState(g_RaidSquadIndex, 1)
			elseif state == 1 then
				SetShowState(g_RaidSquadIndex, 0)
			else
				return
			end
		end
		--End

		if (arg0 == "PartyFrame_RaidMenu") then
			ContexMenuFrame_Close()

			local menuType = tonumber(arg1)
			g_CurSelRaidMember = arg2
			if menuType == 1 then
				ContexMenu_RaidMember2:Show()
				ContexMenu_RaidMember2:SetPopMenuPos(arg3, arg4)
				this:Show()
			elseif menuType == 2 then
				ContexMenu_RaidMember1:Show()
				ContexMenu_RaidMember1:SetPopMenuPos(arg3, arg4)
				this:Show()
			elseif menuType == 3 then
				ContexMenu_RaidMember3:Show()
				ContexMenu_RaidMember3:SetPopMenuPos(arg3, arg4)
				this:Show()
			elseif menuType == 4 then
				ContexMenu_RaidMember4:Show()
				ContexMenu_RaidMember4:SetPopMenuPos(arg3, arg4)
				this:Show()
			elseif menuType == 5 then
				ContexMenu_RaidMember3:Show()
				ContexMenu_RaidMember3:SetPopMenuPos(arg3, arg4)
				this:Show()
			end

			return
		end
--------------------------------------------------------------------------------------------------------------------------
		--
		-- 势力成员
		--
		if( arg0 == "CLANLIST" ) then
            currentClanListIndex = arg2

			if(tonumber(arg5)==0)  then         --- 自己
				return;
   			elseif(tonumber(arg5)==2) then      --- 不在线
				return
			elseif(tonumber(arg5)==1) then      --- 别人，而且别人在线
				ContexMenuFrame_Close()
				this:Show()

				if Player:IsInTeam() == 1 then
					ContexMenu_ShiLi_ShiZu_RaidInvite:Disable()
					ContexMenu_ShiLi_ShiZu_RaidApply:Disable()
				elseif Player:IsInRaid() == 1 then
					ContexMenu_ShiLi_ShiZu_RaidInvite:Enable()
					ContexMenu_ShiLi_ShiZu_RaidApply:Disable()
				else
					ContexMenu_ShiLi_ShiZu_RaidInvite:Disable()
					ContexMenu_ShiLi_ShiZu_RaidApply:Enable()
				end

			end

			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			return;
		end
--------------------------------------------------------------------------------------------------------------------------


		if( arg0 == "MAIL_LIST" ) then
			ContexMenuFrame_Close()
			if tostring(arg1) ~= "" then
				this:Show()
				ContexMenu_MailList:Show();
			end
			ContexMenu_MailList_1:SetText(tostring(arg1).."")
			ContexMenu_MailList_2:SetText(tostring(arg1).."@qq.com")
			ContexMenu_MailList_3:SetText(tostring(arg1).."@163.com")
			ContexMenu_MailList_4:SetText(tostring(arg1).."@126.com")
			ContexMenu_MailList_5:SetText(tostring(arg1).."@sina.com")
			ContexMenu_MailList_6:SetText(tostring(arg1).."@yahoo.com")
			ContexMenu_MailList_7:SetText(tostring(arg1).."@game.sohu.com")
			ContexMenu_MailList_8:SetText(tostring(arg1).."@changyou.com")
			ContexMenu_MailList:SetPopMenuPos(arg2,arg3);
		end

		if( arg0 == "WangzheChallange" ) then
			ContexMenuFrame_Close()
			g_KMMemIndex = tonumber(arg2)
			ContexMenu_WangZheSet:SetPopMenuPos(arg3,arg4);
			this:Show()
			ContexMenu_WangZheSet:Show()
			return
		end

		if( arg0 == "Furniture" ) then
			ContexMenuFrame_Close()
			if BieYeUI:IsBieYeTemplate()  then
				return
			end
			g_FurnitureObj = tonumber(arg1)
			ContexMenu_BieYeFurniture:SetPopMenuPos(arg2,arg3);
			this:Show()
			ContexMenu_BieYeFurniture:Show()

			if tonumber(arg4) == 0 then
				ContexMenu_BieYeFurniture_Show:Disable()
				ContexMenu_BieYeFurniture_Move:Disable()
				ContexMenu_BieYeFurniture_Turn:Disable()
				ContexMenu_BieYeFurniture_Destroy:Disable()
				ContexMenu_BieYeFurniture_Back:Disable()
				ContexMenu_BieYeFurniture_ReserveAll:Disable()
			else
				ContexMenu_BieYeFurniture_Show:Enable()
				ContexMenu_BieYeFurniture_Move:Enable()
				ContexMenu_BieYeFurniture_Turn:Enable()
				ContexMenu_BieYeFurniture_Destroy:Enable()
				ContexMenu_BieYeFurniture_Back:Enable()
				ContexMenu_BieYeFurniture_ReserveAll:Enable()
			end

			if BieYeUI:GetFurPlayerIsCanAnim(g_FurnitureObj) == 0 then
				ContexMenu_BieYeFurniture_Mood:Disable()
			else
				ContexMenu_BieYeFurniture_Mood:Enable()
				local AnimNum = BieYeUI:GetFurPlayerAnimNum(g_FurnitureObj)
				if AnimNum == 1 then
					ContexMenu_BieYeFurniture_Mood:SetProperty( "PopMenu", "" );
				else
					ContexMenu_BieYeFurniture_Mood:SetProperty( "PopMenu", "ContexMenu_BieYeFurniture_Mood2" );
					local names = BieYeUI:GetFurPlayerAnimName(g_FurnitureObj)
					local menuItems = {}
					for i=1,table.getn(names) do
						local menuItem = _G["ContexMenu_BieYeFurniture_Mood2_"..i]
						if menuItem then
							if AnimNum >= i then
								menuItem:Enable()
								menuItem:SetText(names[i])
							else
								menuItem:Disable()
							end
						end
					end
				end
			end
			PushEvent("BIEYEFURNITURETRUESHOW",0)
			return
		end
------------------------------------------------------------------------------------
-- 家园萌宠
		if( arg0 == "my_cutepet" ) then
			ContexMenuFrame_Close()
			if BieYeUI:IsBieYeTemplate()  then
				return
			end
			local ObjId = BieYeMengChong: GetMengChongObjID()
			Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AddBuff");
			Set_XSCRIPT_ScriptID(891900);
			Set_XSCRIPT_Parameter(0,ObjId);
			--Set_XSCRIPT_Parameter(1,g_ValidEquipPos[actionidx]);
			--Set_XSCRIPT_Parameter(2,g_Enchange_Item2);
			Set_XSCRIPT_ParamCount(1);
			Send_XSCRIPT();
			--PushDebugMessage(ObjId)
			--if BieYeUI:IsBieYeTemplate()  then
				--return
			--end
			ContexMenu_BieYeCutePet:SetPopMenuPos(arg2,arg3);
			local isMaster = BieYeMengChong:IsMaster()
			if isMaster == 1 then
				ContexMenu_BieYeCutePet_food:Enable()
				ContexMenu_BieYeCutePet_Back:Enable()
			else
				ContexMenu_BieYeCutePet_food:Disable()
				ContexMenu_BieYeCutePet_Back:Disable()
			end
			this:Show()
			--local MengChongIndex = BieYeMengChong:GetMengChongXiaoWoIndex();
			--if MengChongIndex ==nil then 
			--	return 
			--end
			--local ModelId = BieYeMengChong:GetMengChongModleID()
			--PushDebugMessage(ModelId)
			--local isOut = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",MengChongIndex+1)
			--local styleId =BieYeMengChong:GetBieYeMengChongInfo(isOut,14)
			--PushDebugMessage(isOut)
			--if ModelId ~= 5469 then 
			------------------------------------------------------------------------------
			--------直接右键收回背包功能，可爱的策划小姐姐又说不要了----------------------
			------------------------------------------------------------------------------
			local menuItem = _G["ContexMenu_BieYeCutePet_Bag"]
			menuItem:Disable()
		--	else
			--local menuItem = _G["ContexMenu_BieYeCutePet_Bag"]
			--menuItem:Enable()
			--end
			ContexMenu_BieYeCutePet:Show()
           -- local IsMaster =  BieYeMengChong:IsMaster()
			--if IsMaster == nil then
				--return
			--end
			--if IsMaster == 1 then
			--	ContexMenu_BieYeCutePet_Back : Enable()
			--else 
			--	ContexMenu_BieYeCutePet_Back : Disable()
			--end

			--if tonumber(arg4) == 0 then
				--ContexMenu_BieYeCutePet_Show:Disable()
				--ContexMenu_BieYeCutePet_Interaction:Disable()
				--ContexMenu_BieYeCutePet_InteractionSP:Disable()
				--ContexMenu_BieYeCutePet_Back:Disable()
				--ContexMenu_BieYeFurniture_Back:Disable()
				--ContexMenu_BieYeFurniture_ReserveAll:Disable()
			--else
				--ContexMenu_BieYeCutePet_Show:Enable()
				--ContexMenu_BieYeCutePet_Interaction:Enable()
				--ContexMenu_BieYeCutePet_InteractionSP:Enable()
				--ContexMenu_BieYeCutePet_Back:Enable()
				--ContexMenu_BieYeFurniture_Back:Enable()
				--ContexMenu_BieYeFurniture_ReserveAll:Enable()
			--end

			--if BieYeUI:GetFurPlayerIsCanAnim(g_FurnitureObj) == 0 then
				--ContexMenu_BieYeCutePet_Mood:Disable()
			--else
				--ContexMenu_BieYeCutePet_Mood:Enable()
				--local AnimNum = BieYeUI:GetFurPlayerAnimNum(g_FurnitureObj)
				--if AnimNum == 1 then
					--ContexMenu_BieYeCutePet_Mood:SetProperty( "PopMenu", "" );
				--else
					ContexMenu_BieYeCutePet_Interaction:SetProperty( "PopMenu", "ContexMenu_BieYeCutePet_Mood2" );
					--local names = BieYeUI:GetFurPlayerAnimName(g_FurnitureObj)
					
					--local index = BieYeMengChong:GetMengChongXiaoWoIndex()
					--if index ==nil then
					--return 
					--end
					--index = index + 1
					--local nIndex = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",index)
					local names = {}
					names[1] = BieYeMengChong:GetMengChongActionName1()
					--PushDebugMessage(names[1])
					names[2] = BieYeMengChong:GetMengChongActionName2()
					names[3] = BieYeMengChong:GetMengChongActionName3()
					names[4] = BieYeMengChong:GetMengChongActionName4()
					names[5] = BieYeMengChong:GetMengChongActionName5()
					for i=1,5 do
						local menuItem = _G["ContexMenu_BieYeCutePet_Mood2_"..i]
						menuItem:Disable()
					end
					local nMengChongTransferID
				--	if nIndex > 0 then 
						 nMengChongTransferID =  BieYeMengChong:GetMengChongIsChengNian()
					--	PushDebugMessage(nMengChongTransferID.."ID")
	              --  end
					--PushDebugMessage(names[5])
					local menuItems = {}

					for i=1,5 do
					--	PushDebugMessage("0 names = "..names[i])
						if names[i] ~= "-1" then	
											--	PushDebugMessage("nMengChongTransferID="..nMengChongTransferID)
							if nMengChongTransferID > 0 and i>2 then
								--PushDebugMessage("1 names = ")
								local menuItem =  _G["ContexMenu_BieYeCutePet_Mood2_"..i]
								menuItem:Enable()
								menuItem:SetText(names[i].."[成年解锁]")
							else
								--PushDebugMessage("2 names = ")
								local menuItem = _G["ContexMenu_BieYeCutePet_Mood2_"..i]			
								menuItem:Enable()
								menuItem:SetText(names[i])
							end
									
													
						end	
					end
				--end
			--end
			--PushEvent("BIEYEFURNITURETRUESHOW",0)
			return
		end
------------------------------------------------------------------------------------
		
		if( arg0 == "CorpsMatch_TeamView" ) then
			ContexMenuFrame_Close()
			g_CorpsMemIndex = tonumber(arg2)
			ContexMenu_Zhengbasai:SetPopMenuPos(arg3,arg4)

			ContexMenu_Zhengbasai_1:Enable()
			ContexMenu_Zhengbasai_2:Enable()
			ContexMenu_Zhengbasai_3:Enable()
			ContexMenu_Zhengbasai_4:Enable()
			local memCount = CorpsUI_2016:GetCorpsMemberCount()
			if g_CorpsMemIndex == 1 then
				ContexMenu_Zhengbasai_1:Disable()
				ContexMenu_Zhengbasai_3:Disable()
			elseif g_CorpsMemIndex == memCount then
				ContexMenu_Zhengbasai_2:Disable()
				ContexMenu_Zhengbasai_4:Disable()
			end

			this:Show()
			ContexMenu_Zhengbasai:Show()
			return
		end
		
		if( arg0 == "NoDiffMatch" ) then
			ContexMenuFrame_Close()
			g_CorpsMemIndex_2018 = tonumber(arg2)
			ContexMenu_NoDiffMatch:SetPopMenuPos(arg3,arg4)

			ContexMenu_NoDiffMatch_1:Enable()
			ContexMenu_NoDiffMatch_2:Enable()
			ContexMenu_NoDiffMatch_3:Enable()
			ContexMenu_NoDiffMatch_4:Enable()
			local memCount = CorpsUI_2018:GetCorpsMemberCount()
			if g_CorpsMemIndex_2018 == 1 then
				ContexMenu_NoDiffMatch_1:Disable()
				ContexMenu_NoDiffMatch_3:Disable()
			elseif g_CorpsMemIndex_2018 == memCount then
				ContexMenu_NoDiffMatch_2:Disable()
				ContexMenu_NoDiffMatch_4:Disable()
			end

			this:Show()
			ContexMenu_NoDiffMatch:Show()
			return
		end
		--------------------------------------------------------------------------------------------------------------------------
		--
		-- 比武大会2018排行榜右键查看
		--
		if( arg0 == "RANKLIST" ) then
			currentRankListIndex = arg2;
			if(tonumber(arg5)==0)  then
				return;
			elseif(tonumber(arg5)==1) then
				ContexMenuFrame_Close();
				this:Show();
				ContexMenu_BWRankingList:Show();
				ContexMenu_BWRankingList:SetPopMenuPos(arg3,arg4);
			end

			--关心NPC
			objCared = tonumber(arg1);
			this:CareObject(objCared, 1, "ContexMenu");

			return;
		end
		
		if( arg0 == "ChallengeMember" ) then
			ContexMenuFrame_Close();
			g_challengeIndex = tonumber(arg2);
			ContexMenu_TJiaoChang:SetPopMenuPos(arg3,arg4)
			ContexMenu_TJiaoChang:Show();
			this:Show();

			return;
		end
--------------------------------------------------------------------------------------------------------------------------
	elseif (event == "OBJECT_CARED_EVENT") then

		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1=="destroy") then
			ContexMenuFrame_Close();

			--取消关心
			this:CareObject(objCared, 0, "ContexMenu");
		end
	elseif(event == "HIDE_CONTEXMENU_SPEAKER")then
		if(this:IsVisible() and g_showType == "chat_private" and g_MenuType == "speaker") then
			ContexMenuFrame_Close();
		end

	elseif(event == "UPDATE_FRIEND_INFO" and g_FoeListRefresh_Clicked==1)then
		ContexMenu_FoeListRefreshTitleSec()
	end
	if (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then
		--PushDebugMessage("gjy20171213")
		local nType = tonumber(Get_XParam_INT(0))
		if nType == 30 then 
			ContexMenu_BieYeCutePet:ClosePopMenu()
			ContexMenu_BieYeFurniture:ClosePopMenu()
		end
	end
end
function ContexMenuFrame_Close()
	ContexMenu_HideAll();
	this:Hide();
	this:CareObject(objCared, 0, "ContexMenu");
	g_GroupID = -1
	g_Guid = ""
end

function ContexMenuFrame_Clicked()
	ContexMenuFrame_Close();

end

function ContexMenu_HideAll()

	Menu_PVPMode:ClosePopMenu();
	Menu_PVPMode_Before21:ClosePopMenu();
	Menu_PVPMode_K:ClosePopMenu();
	Menu_PVPMode_KGuildLeague:ClosePopMenu();

	-- 隐藏其他玩家
	ContexMenu_OtherPlayer:ClosePopMenu();

	-- 隐藏npc
	ContexMenu_NPC:ClosePopMenu();

	-- 隐藏队长菜单
	ContexMenu_TeamLeader:ClosePopMenu();

	-- 隐藏队友
	ContexMenu_TeamMember:ClosePopMenu();

	-- 隐藏自建队伍菜单
	ContexMenu_Self:ClosePopMenu();

	-- 隐藏自己已经在队伍中, 打开摆摊菜单
	ContexMenu_Self_In_Team:ClosePopMenu();

	-- 隐藏其他, 已经组队玩家菜单.
	ContexMenu_Model_Open_Other:ClosePopMenu();

	-- 隐藏非组队玩家菜单
	ContexMenu_Model_Open_Other_Not_teammer:ClosePopMenu();
	ContexMenu_OffLineSale:ClosePopMenu();

	-- 隐藏非组队玩家申请菜单
	ContexMenu_Model_Open_Other_teammer_me_not_teammer:ClosePopMenu();

	-- 隐藏聊天窗口菜单
	ContexMenu_ChatBoard:ClosePopMenu();

	ContexMenu_FriendMenu:ClosePopMenu();
	ContexMenu_EnmeyListMenu:ClosePopMenu();

	-- 隐藏组队界面上的队友珍兽按钮右键菜单
	ContexMenu_MemberPetMenu:ClosePopMenu();

	-- 隐藏自己宠物窗口菜单
	ContexMenu_MyPetMenu:ClosePopMenu();
	
	-- 隐藏萌宠窗口菜单
	ContexMenu_BieYeCutePet:ClosePopMenu();

	-- 隐藏其他宠物窗口菜单
	ContexMenu_OtherPetMenu:ClosePopMenu();

	-- 隐藏组队跟随菜单。
	ContexMenu_TeamFollowLeader:ClosePopMenu();

	-- 隐藏队友.
	ContexMenu_TeamFollowMember:ClosePopMenu();

	ContexMenu_BlackListMenu:ClosePopMenu();

	--隐藏仇敌
	ContexMenu_FoeListMenu:ClosePopMenu();

	ContexMenu_GroupingMenu:ClosePopMenu();

	ContexMenu_BGGroupingMenu:ClosePopMenu();
	--帮派
	ContexMenu_GuildList:ClosePopMenu();
	--同盟成员
	ContexMenu_GuildLeagueMember:ClosePopMenu();

	--官员列表右键菜单--add by xindefeng
	ContexMenu_OfficialPopMenu:ClosePopMenu();

	--new
	ContexMenu_MyPetMenuFromPetFrame:ClosePopMenu();

	--
	ContexMenu_ChatBoard_NoToushu:ClosePopMenu();
	--FindFriend_Voteinfo
	ContexMenu_FindFriend_VoteInfo:ClosePopMenu();

	ContexMenu_TrustFriendMenu : ClosePopMenu();
	ContexMenu_TeamBoard: ClosePopMenu();
--IM功能
	ChatGroup_Menu:ClosePopMenu()
	ChatGroup_OwnerMenu:ClosePopMenu()
	MyGroup_Menu:ClosePopMenu()
	MyGroup_OwnerMenu:ClosePopMenu()

	NotTeamerNotRaider_Raider:ClosePopMenu()
	Raider_NotTeamerNotRaider:ClosePopMenu()
	Union1_Menu:ClosePopMenu()
	Union2_Menu:ClosePopMenu()
	Union3_Menu:ClosePopMenu()
	Union4_Menu:ClosePopMenu()
	Union5_Menu:ClosePopMenu()
	Union6_Menu:ClosePopMenu()
	UIRaidSquadWindow_Menu:ClosePopMenu()
	UISquadMemWindow_Menu:ClosePopMenu()
	ContexMenu_RaidMember1:ClosePopMenu()
	ContexMenu_RaidMember2:ClosePopMenu()
	ContexMenu_RaidMember3:ClosePopMenu()
	ContexMenu_RaidMember4:ClosePopMenu()


    	--原服大世界超链菜单
	ContexMenu_ChatBoard_NoToushu_KVK:ClosePopMenu()

	ContexMenu_MailList:ClosePopMenu()
	--隐藏自己孩子右键菜单
	ContexMenu_SelfInfant:ClosePopMenu()
	--隐藏他人孩子右键菜单
	ContexMenu_OtherInfant:ClosePopMenu()
	ContexMenu_SecretChatBoard:ClosePopMenu()
	ContexMenu_WangZheSet:ClosePopMenu()
	ContexMenu_Zhengbasai:ClosePopMenu()
	ContexMenu_NoDiffMatch:ClosePopMenu()


	ContexMenu_BieYeFurniture:ClosePopMenu()
	ContexMenu_BieYeCutePet:ClosePopMenu()
	ContexMenu_BWRankingList:ClosePopMenu()
	ContexMenu_BZTXList:ClosePopMenu()
	ContexMenu_FightGroup_Compare:ClosePopMenu()
	ContexMenu_TJiaoChang:ClosePopMenu()
end

function ContexMenu_OtherPlayer_Clicked(itemname)


	if(itemname == "zudui") then
		if(Target:IsPresent()) then
			Target:SendTeamRequest();
		end
	elseif(itemname == "tanwei") then
		StallBuy:OpenStall();
	elseif(itemname == "siliao") then
		--

	-- ================================
	-- czf modify begin 2010/8
	-- 根据g_bDRideFlag的值来处理不同情况(看哪个被选中了)
	--* @返回值:
		--*            0	:	啥也不显示
		--*            1	:	显示 “邀请同骑”
		--*            2	:	显示 “取消同骑”
		--*		    3  :   显示 “申请同骑”
		--*			4  :   显示 “解散同骑”
	elseif( itemname == "Ride" ) then
		if(1 == g_bDRideFlag) then
			InviteRide();
		elseif ( 2 == g_bDRideFlag) then
			-- “司机取消某个乘客的同骑”，
			CancelRide(1);
		elseif ( 3 == g_bDRideFlag) then
			ApplyRide();
		elseif ( 4 == g_bDRideFlag) then
			DisbandRide();
		elseif ( 5 == g_bDRideFlag) then
			-- “乘客取消自己的同骑”
			CancelRide(0);
		end
    --elseif( itemname == "Clan" ) then
        --if ( 1 == g_bClanInviteApplyFlag ) then
		--	K世界重建
	    --if ContexMenu_IsKvkRebuildLimit() > 0 then
		    --PushDebugMessage("#{KSJCL_130318_08}")
		    --return
	    --end
            --- 邀请加入势力
            --Clan:InviteOtherToJoinClan()
        --elseif ( 2 == g_bClanInviteApplyFlag ) then
		--	K世界重建
	    --if ContexMenu_IsKvkRebuildLimit() > 0 then
		    --PushDebugMessage("#{KSJCL_130318_07}")
		   -- return
	   -- end
            --- 申请加入势力
            --Clan:ApplyToJoinClan()
        --end
	end

	--czf modify end
	-- =================================

	ContexMenuFrame_Close();
end

--交易
function ContexMenu_Exchange_Clicked()
	Exchange:SendExchangeApply();
	ContexMenuFrame_Close();
end

--跟随
function ContexMenu_OtherPlayer_Follow_Clicked()
	Target:Follow();
	ContexMenuFrame_Close();
end

-- 邀请入帮
function ContexMenu_InviteToGuild_Clicked()
	if Player : GetData( "GUILD" ) == -1 then
		return
	end

	Guild : InviteToGuild()
	ContexMenuFrame_Close()
end

--送玫瑰花
function ContexMenu_GiveRose_Clicked()
	 ContexMenuFrame_Clicked();

	local nGUID = GetTargetPlayerGUID();



	if( nGUID  == "" ) then
	--	return;
	end

	--系统提示邮件，公告，SNS，Server处理
	--请注意,如果需要在参数中传64位的角色GUID,请按照下面的方式先将GUID拆分为
	--32位的高低两位,再在服务器脚本中通过LuaFnCombine2GUID64接口拼接
	local nGUIDH, nGUIDL = SplitGUID64(nGUID);
	if (IsInTServer() == 1) then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GiveRose" )
		Set_XSCRIPT_ScriptID( 006673 )
		Set_XSCRIPT_Parameter( 0, nGUIDH )
		Set_XSCRIPT_Parameter( 1, nGUIDL )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()


	ContexMenuFrame_Close()
end

--*******************************************************************************************************************************
--
-- 申请加入队伍
--
--*******************************************************************************************************************************
function ContexMenu_OtherPlayer_Apply_Clicked()

		if(Target:IsPresent()) then
			Target:SendTeamApply();
		end

		ContexMenuFrame_Close();

end



--*******************************************************************************************************************************
--
-- 离开队伍
--
--*******************************************************************************************************************************
function ContexMenu_LeaveTeam_Clicked()
	if Player:IsInTeam() == 1 then
		Player:LeaveTeam()
	elseif Player:IsInRaid() == 1 then
		Player:LeaveRiad()
	end
	ContexMenuFrame_Close()
end

--*******************************************************************************************************************************
--
-- 解散队伍
--
--*******************************************************************************************************************************
function ContexMenu_DismissTeam_Clicked()

	Player:OpenDismissTeamMsgbox();			-- 打开解散队伍的二次确认窗口			add by WTT	20090218
	ContexMenuFrame_Close();
end


--*******************************************************************************************************************************
--
-- 踢出当前选中的队员.
--
--*******************************************************************************************************************************
function ContexMenu_KickTeamMember_Clicked()

	Player:KickTeamMember(currentSelectMember);
	ContexMenuFrame_Close();
end


--*******************************************************************************************************************************
--
-- 自己创建队伍
--
--*******************************************************************************************************************************
function ContexMenu_SelfCreateTeam_Clicked()
	Player:CreateTeamSelf();
	ContexMenuFrame_Close();

end

--*******************************************************************************************************************************
--
-- 提升为队长
--
--*******************************************************************************************************************************
function ContexMenu_AppointLeader_Clicked()

	Player:AppointLeader(currentSelectMember);
	ContexMenuFrame_Close();
end

--*******************************************************************************************************************************
--
-- 取消跟随
--
--*******************************************************************************************************************************
function ContexMenu_StopFollow_Clicked()
	Player:StopFollow();
	ContexMenuFrame_Close();
end

--*******************************************************************************************************************************
--
-- 摆摊
--
--*******************************************************************************************************************************
function ContexMenu_StallSale_Clicked()
	PlayerPackage:OpenStallSaleFrame();
	ContexMenuFrame_Close();
end

--*******************************************************************************************************************************
--
-- 私聊
--
--*******************************************************************************************************************************

function ContexMenu_ChatBoard_Private_Talk_Clicked()
	 ContexMenuFrame_Clicked();
	 Talk:ContexMenuTalk();
	 ContexMenuFrame_Close();
end
function ContexMenu_ChatBoard_CheckInfo_Clicked()
	ContexMenuFrame_Clicked();
	local szName,szSingleName,tZoneWorldId = Talk:HandleMenuAction("Name");
	if(nil ~= szName) then
		if( Friend:IsPlayerIsFriend( szSingleName, tZoneWorldId ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( szSingleName, tZoneWorldId );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( szSingleName, tZoneWorldId );
		else
			--DataPool:ShowChatInfo( szName );
			DataPool:ShowChatInfoByZWId( szSingleName, tZoneWorldId );
		end
	end
	ContexMenuFrame_Close();
end
function ContexMenu_ChatBoard_Invite_Clicked()
	ContexMenuFrame_Clicked();
	local szName = Talk:HandleMenuAction("Name")
	if(nil ~= szName) then
		Target:SendTeamRequest(szName);
	end
	ContexMenuFrame_Close();
end
function ContexMenu_ChatBoard_Apply_Clicked()
	ContexMenuFrame_Clicked();
	local szName = Talk:HandleMenuAction("Name")
	if(nil ~= szName) then
		Target:SendTeamApply(szName);
	end
	ContexMenuFrame_Close();
end
function ContexMenu_ChatBoard_ApplyTeam_KVK_Clicked()
	ContexMenuFrame_Clicked();
	 Talk:HandleMenuAction("Toushu");
	 ContexMenuFrame_Close();
end


function ContexMenu_GetCurrentFriendTeam()
	local nCurrentTeam = Friend:GetCurrentTeam();
	if( nCurrentTeam == 5 or nCurrentTeam == 6 ) then
		nCurrentTeam = 0;
	end
	return nCurrentTeam;

end
function ContexMenu_ChatBoard_AddFriend_Clicked()
	 ContexMenuFrame_Clicked();
	 --DataPool:AddFriendAndGrouping( Talk:HandleMenuAction("Name") );
	 local szName,szSingleName,zoneworldid = Talk:HandleMenuAction("Name")
	 DataPool:AddFriendAndGrouping( szSingleName,zoneworldid )
	 ContexMenuFrame_Close();
end
function ContexMenu_ChatBoard_PingBi_Clicked()
	ContexMenuFrame_Clicked();
	Talk:HandleMenuAction("PingBi");
	ContexMenuFrame_Close();
end

function ContexMenu_ChatBoard_Toushu_Clicked()
	ContexMenuFrame_Clicked();
	Talk:HandleMenuAction("Toushu");
	ContexMenuFrame_Close();
end

function ContexMenu_SecretChatBoard_Toushu_Clicked()
	ContexMenuFrame_Clicked();
	Talk:HandleMenuAction("ToushuSecret");
	ContexMenuFrame_Close();
end

function send_detail()
	Target:Close_Before_TargetEquip_UI();
	Target:SendAskDetail();
	ContexMenuFrame_Close();

	--缓存主目标信息
	CacheMainTarget();
end
--*******************************************************************************************************************************
--
--好友
--*******************************************************************************************************************************
function ContexMenu_OnDelFriend()
	DataPool:AskDelFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ) );
	Friend:Close();
	ContexMenuFrame_Close();
end

function ContexMenu_OpenBeiZhu()
	PushEvent("OPEN_REMARK",tonumber(currentSelectChannal),tonumber(currentIndex))
	ContexMenuFrame_Close();
end

function ContexMenu_OnDelFoe()
	DataPool:AskDelFriend(tonumber(currentSelectChannal), tonumber(currentIndex));
	Friend:Close();
	ContexMenuFrame_Close();
end

function ContexMenu_FriendChat_Clicked()
		DataPool:Open1On1Chat(tonumber( currentSelectChannal ) , tonumber( currentIndex ))
		ContexMenuFrame_Close();
end

function ContexMenu_OnPresent()

	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end	
	local friendguid = DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ID"  )
	local friendRelationType = DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "RELATION_TYPE"  )

	--只有好友可以赠送
	if friendRelationType == 0  or friendRelationType == 4  or friendRelationType == 5 or
	   friendRelationType == 6  or friendRelationType == 9 then
		PushDebugMessage("#{ZSGN_101129_24}")
		ContexMenuFrame_Close();
		return
	end

	--如果xuanshop界面已经显示
	local IsShow_XS = IsWindowShow("XuanShop")
	if ( IsShow_XS == true ) then
		--如果对应该好友的赠送界面已显示，那么什么都不做
		if NpcShop:GetIsXuanShopType() ~= 1 then
			local oldfriendguid = NpcShop:GetFriendID_PS()
			if oldfriendguid == friendguid then
				ContexMenuFrame_Close();
				return
			end
		end

		--如果提示框已经显示，则清除购物车同时关闭
		local IsShow_MBO = IsWindowShow("MessageBox_Other")
		if ( IsShow_MBO == true ) then
			IMDressCleanUpPayBox();
			CloseWindow("MessageBox_Other",true)
			CloseWindow("XuanShop",true)
			PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", friendguid)
			ContexMenuFrame_Close();
			return
		end

		local ret = IMDressLoadPayBox();
		if (ret and ret > 0) then
			--如果购物车里有东西，并且需要提示
			if (NpcShop:GetNotPayNotice() == 1) then
				if NpcShop:GetIsXuanShopType() == 1 then
					PushEvent("IMSHOP_NOTPAY_CONFIRM", "XuanShop", "PresentShop", friendguid);
				else
					local friendguid_old  = NpcShop:GetFriendID_PS();
					PushEvent("IMSHOP_NOTPAY_CONFIRM", "PresentShop", "PresentShop", friendguid_old, friendguid);
				end
				ContexMenuFrame_Close();
				return
			end
		end
		CloseWindow("XuanShop",true)
		PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", friendguid)
	else
		PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", friendguid)
	end
	ContexMenuFrame_Close();
end



function ContexMenu_OnPresent_OpenOther_Team()
	local guid = DataPool:GetTeamMemGUIDByUIIndex( tonumber( currentSelectMember ) );
	if(  guid  == "" ) then
		return;
	end
	ContexMenu_OnPresent_OpenOther(guid)
end

function ContexMenu_OnPresent_OpenOther_Model()

	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	
	local guid = GetTargetPlayerGUID();
	if(  guid  == "" ) then
		return;
	end
	ContexMenu_OnPresent_OpenOther(guid)
end

function ContexMenu_OnPresent_OpenOther_Raid()
	local guid = g_CurSelRaidMember;
	if(  guid  == "" ) then
		return;
	end
	ContexMenu_OnPresent_OpenOther(guid)
end

function ContexMenu_OnPresent_OpenOther(friendguid_toPresent)

	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end

	local checkHaveMaskBuff = Lua_CheckMainTargetHaveMaskBuff()	
	if checkHaveMaskBuff == 1 then
		PushDebugMessage("#{SFDJ_240117_124}")
		return
	end

	--local friendguid = GetTargetPlayerGUID();
	--local friendguid = g_CurSelRaidMember
	local friendguid = friendguid_toPresent
	local friendgroup
	local friendindex
	friendgroup, friendindex = DataPool:GetFriendByGUID( friendguid );
	if friendgroup == 0 and friendindex == -1 then
		PushDebugMessage("#{ZSGN_101129_24}")
		ContexMenuFrame_Close();
		return
	end

	local friendRelationType = DataPool:GetFriend( friendgroup, friendindex, "RELATION_TYPE"  )

	--只有好友可以赠送
	if friendRelationType == 4  or friendRelationType == 5 or
	   friendRelationType == 6  or friendRelationType == 9 then
		PushDebugMessage("#{ZSGN_101129_24}")
		ContexMenuFrame_Close();
		return
	end

	--如果xuanshop界面已经显示
	local IsShow_XS = IsWindowShow("XuanShop")
	if (IsShow_XS == true) then
		--如果对应该好友的赠送界面已显示，那么什么都不做
		if NpcShop:GetIsXuanShopType() ~= 1 then
			local oldfriendguid = NpcShop:GetFriendID_PS()
			if oldfriendguid == friendguid then
				ContexMenuFrame_Close();
				return
			end
		end

		--如果提示框已经显示，则清除购物车同时关闭
		local IsShow_MBO = IsWindowShow("MessageBox_Other")
		if ( IsShow_MBO == true ) then
			IMDressCleanUpPayBox();
			CloseWindow("MessageBox_Other",true)
			CloseWindow("XuanShop",true)
			PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", friendguid)
			ContexMenuFrame_Close();
			return
		end

		local ret = IMDressLoadPayBox();
		if (ret and ret > 0) then
			--如果购物车里有东西，并且需要提示
			if (NpcShop:GetNotPayNotice() == 1) then
				if NpcShop:GetIsXuanShopType() == 1 then
					PushEvent("IMSHOP_NOTPAY_CONFIRM", "XuanShop", "PresentShop", friendguid);
				else
					local friendguid_old  = NpcShop:GetFriendID_PS();
					PushEvent("IMSHOP_NOTPAY_CONFIRM", "PresentShop", "PresentShop", friendguid_old, friendguid);
				end
				ContexMenuFrame_Close();
				return
			end
		end
		CloseWindow("XuanShop",true)
		PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", friendguid)
	else
		PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", friendguid)
	end
	ContexMenuFrame_Close();
end

function ContexMenu_OnSendMail()

	local name =  DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "NAME" );
	DataPool:OpenMail( name );

	ContexMenuFrame_Close();

end

function ContexMenu_AddFriend()

	DataPool:AddFriendAndGrouping(  );
	ContexMenuFrame_Close();
end

--function ContexMenu_InviteAddFriend()
	--DataPool:InviteAddFriend();
	--ContexMenuFrame_Close();
--end
--function ContexMenu_InviteAddFriendByFriendList()
	--DataPool:InviteAddFriendByFriendList(Friend:GetCurrentTeam(), Friend:GetCurrentSelect());
	--ContexMenuFrame_Close();
--end

--function ContexMenu_InviteAddFriendByteam()
	--local guid = DataPool:GetTeamMemGUIDByUIIndex( tonumber( currentSelectMember ) );
	--if(  guid  == "" ) then
		--return;
	--end
	--DataPool:InviteAddFriendByteam(guid);
	--ContexMenuFrame_Close();
--end

function ContexMenu_AddFriendTeamate()

	local name,zoneworldid = DataPool:GetTeamMemNameByUIIndex( tonumber( currentSelectMember ) );
	if( name == nil or tostring( name ) == "") then
		return;
	end
	DataPool:AddFriendAndGrouping(  tostring( name ),zoneworldid );
	ContexMenuFrame_Close();

end
function ContexMenu_ThrowBlackList()
	DataPool:ThrowToBlackList( tonumber( currentSelectChannal ), tonumber( currentIndex ) );
	Friend:Close();
	ContexMenuFrame_Close();
end

function ContexMenu_ThrowList( nGroup )

	if( tonumber( currentSelectChannal )  == 13 or tonumber( currentSelectChannal )  == 14 ) then
		local name =  DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "NAME" );
		local zoneworldid =  DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "ZONEWORLDID" );
		DataPool:AddFriend( nGroup, name, zoneworldid);

		if( tonumber( nGroup )  == 5 or tonumber( nGroup )  == 10 ) then
		    PushDebugMessage("暂时无法加入黑名单");
		end
	else
		DataPool:ThrowToList( tonumber( currentSelectChannal ), tonumber( currentIndex ), tonumber( nGroup ), -1 );
	end
	Friend:Close();
	ContexMenuFrame_Close();
end

function ContexMenu_OnPrivate()
	--local name =  DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "NAME" );
	local name = Target:GetName();
	local zoneworldid = Target:GetZoneWorldId()
	Talk:ContexMenuTalk( name, zoneworldid );
	ContexMenuFrame_Close();
end

------好友界面与聊天板中选择该玩家-----
function ContexMenu_OnSelectThePlayer()
  --local szName = Talk:HandleMenuAction("Name");
  local szName,szSingleName,tZoneWorldId = Talk:HandleMenuAction("Name");
  if(nil == szName) then
    szSingleName=DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "NAME" );
    tZoneWorldId=DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "ZONEWORLDID" );
  end

	if(nil ~= szSingleName) then
		Target:SelectThePlayer(szSingleName,tZoneWorldId);
	end

	ContexMenuFrame_Close();
end

---帮派管理中选择该玩家----
function ContexMenu_GuildList_OnSelectThePlayer()
  local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name");

	if(nil ~= szName) then
		Target:SelectThePlayer(szName);
	end
	ContexMenuFrame_Close();
end

function ContexMenu_GuildList_Private_Talk_Clicked()
	ContexMenuFrame_Clicked();
	--local index = Guild:GetShowMembersIdx(tonumber(currentGuildListIndex));
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name");
	Talk:ContexMenuTalk( szName );
	ContexMenuFrame_Close();
end;
function ContexMenu_GuildList_CheckInfo_Clicked()
	ContexMenuFrame_Clicked();
	--local index = Guild:GetShowMembersIdx(tonumber(currentGuildListIndex));
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name");

	if(nil ~= szName) then
		if( Friend:IsPlayerIsFriend( szName ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( szName );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( szName );
		else
			DataPool:ShowChatInfo( szName );
		end
	end
	ContexMenuFrame_Close();
end;
function ContexMenu_GuildList_AddFriend_Clicked()
	ContexMenuFrame_Clicked();
	--local index = Guild:GetShowMembersIdx(tonumber(currentGuildListIndex));
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name");
	 DataPool:AddFriendAndGrouping(  szName );
	 ContexMenuFrame_Close();
end
function ContexMenu_GuildList_Invite_Clicked()
	ContexMenuFrame_Clicked();
	--local index = Guild:GetShowMembersIdx(tonumber(currentGuildListIndex));
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name");
	if(nil ~= szName) then
		Target:SendTeamRequest(szName);
	end
	ContexMenuFrame_Close();
end

function ContexMenu_GuildList_Apply_Clicked()

	ContexMenuFrame_Clicked();
	--local index = Guild:GetShowMembersIdx(tonumber(currentGuildListIndex));
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name");
	if(nil ~= szName) then
		Target:SendTeamApply(szName);
	end
	ContexMenuFrame_Close();

end
function ContexMenu_GuildList_OnSendMail()
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name");
	DataPool:OpenMail( szName );

	ContexMenuFrame_Close();
end

--同盟成员帮会详细信息处理
function ContexMenu_GuildLeagueMember_DetailInfo_Clicked()
	Guild:AskAnyGuildDetailInfo(g_LeagueMemberID) --查询指定ID帮会详细信息
	Guild:CloseKickGuildBox()

	ContexMenuFrame_Close();
end

function ContexFriend_OnPrivate()
	local name =  DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "NAME" );
	local zoneworldid =  DataPool:GetFriend( tonumber( currentSelectChannal ), tonumber( currentIndex ), "ZONEWORLDID" );
	Talk:ContexMenuTalk( name, zoneworldid );
	ContexMenuFrame_Close();
end

function ContexMenu_PetHandle( order )
	if( order == nil ) then
		return;
	end

	local action = {};
	action[1] = "feed";
	action[2] = "dome";
	action[3] = "relax";
	action[4] = "detail";

	Pet:HandlePetMenuItem(action[order]);

	ContexMenuFrame_Close();
end

function ContexMenu_PetHandleSelf(order)
	if( order == nil ) then
		return;
	end

	local action = {};
	action[1] = "feed";
	action[2] = "dome";
	action[3] = "relax";
	action[4] = "detail";

	Pet:HandlePetMenuItemSelf(action[order]);

	ContexMenuFrame_Close();
end

function ContexMenu_OtherPlayer_Challenge()
	DataPool:Challenge();
end

function ContexMenu_OtherPlayer_MoneyChallenge()
	DataPool:MoneyChallenge();
end


function ContexMenu_ShowFriendInfo()
	DataPool:ShowFriendInfo( Friend:GetCurrentTeam(), Friend:GetCurrentSelect() );
	ContexMenuFrame_Close();
end

function ContexMenu_OnGroupChange()
	Friend:OpenGrouping( tostring( Friend:GetCurrentTeam() ), tostring( Friend:GetCurrentSelect() ) );
	ContexMenuFrame_Close();
end

function ContexMenu_OnFriendInfo()
	DataPool:ShowFriendInfo( Friend:GetCurrentTeam(), Friend:GetCurrentSelect() );
	ContexMenuFrame_Close();
end

function ContexMenu_OnFriendHistroy()
	DataPool:OpenHistroy( Friend:GetCurrentTeam(), Friend:GetCurrentSelect() );
	ContexMenuFrame_Close();
end

function ContexMenu_OnAskTeam()
	local zoneworldid =  DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ZONEWORLDID" );
	local guid = DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ID" );
	Friend:AskTeam( DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "NAME"  ), zoneworldid ,guid);
end


function ContexMenu_OnInviteTeam()
	local zoneworldid =  DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ZONEWORLDID" );
	local guid = DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ID" );
	Friend:InviteTeam( DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "NAME"  ), zoneworldid ,guid);

end









function ContexMenu_PVP_Peace_Clicked()
	Player:ChangePVPMode( 0 );
	ContexMenuFrame_Close();
end

function ContexMenu_PVP_Moral_Clicked()
	Player:ChangePVPMode( 2 );
	ContexMenuFrame_Close();
end
function ContexMenu_PVP_FreeforAll_Clicked()
	ShowAcceptChangePVPMode( 1 );
	ContexMenuFrame_Close();
end
function ContexMenu_PVP_FreeforTeam_Clicked()
	ShowAcceptChangePVPMode( 3 );
	ContexMenuFrame_Close();
end
function ContexMenu_PVP_FreeforGuild_Clicked()
	--2014Q1大世界帮会功能改造
	--该模式只有服务器设置在K服保留玩家原服的"帮会同盟"信息时才能在K服开启
	if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		ContexMenuFrame_Close();
		return
	end
	ShowAcceptChangePVPMode( 4 );
	ContexMenuFrame_Close();
end

function ContexMenu_PVP_ShiLi_ShiZu_PK_Clicked()
	--2014Q1大世界帮会功能改造,世族模式去除
    --ShowAcceptChangePVPMode( 7 );
	--ContexMenuFrame_Close();
end

function ContexMenu_AboutPK_Clicked()
	ShowAcceptChangePVPMode( 5 );
	ContexMenuFrame_Close();
end

function ContexMenu_AboutHostile_Clicked()
	PushEvent("CCSHOP_HELP", 168)
	ContexMenuFrame_Close();
end


function ContexMenu_PVP_KGuild_All_PK_Clicked()
	--2014Q1大世界帮会功能改造,"帮会模式"只有满足:1.玩家在K服 2.服务器设置在K服不保留玩家原服"帮会同盟"信息,才能开启
	if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		ShowAcceptChangePVPMode( 8 );
	end
	ContexMenuFrame_Close();
end

function ContexMenu_PVP_Duel_Clicked()
	Player:PVP_Duel();
	ContexMenuFrame_Close();
end
function ContexMenu_PVP_Challenge_Clicked()
	if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() == 0 then	--非授权安全模式下才需要安全验证 [7/25/2013 shh][TT]
		ContexMenuFrame_Close();
		return
	end
	Player:PVP_Challenge( 1 );     --1为弹出宣战确认对话框
	ContexMenuFrame_Close();
end


function ContexMenu_ChangePVPMode_Clicked()
    ShowChangePVPMode();
    --ContexMenuFrame_Close();
end


function ContexMenu_OnPrivate_FromInc()
	--local name = DataPool:GetTeamMemberInfo(tonumber( currentSelectMember ));
	local name,zoneworldid = DataPool:GetTeamMemNameByUIIndex(tonumber( currentSelectMember ))
	Talk:ContexMenuTalk( name, zoneworldid );
	ContexMenuFrame_Close();
end

--add:lby20071207迷影跟踪聊天信息中查找28818
function ContexMenu_ChatBoard_LookPos_Clicked()
	ContexMenuFrame_Clicked();
	local szName, szSingleName, tZoneWorldId = Talk:HandleMenuAction("Name");
	if(nil ~= szName) then
		if( Friend:IsPlayerIsFriend( szSingleName, tZoneWorldId ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( szSingleName, tZoneWorldId );
	        local friendguid  = DataPool:GetFriend( nGroup, nIndex, "ID"  )
			--- Friend:SetCurrentSelect( nIndex );
			DataPool:LookupOtherParticularInfo( friendguid, tZoneWorldId, szSingleName);
		else
			DataPool:LookupOtherParticularInfo( "", tZoneWorldId, szSingleName );
		end
	end
	ContexMenuFrame_Close();
end

----add:lby20071207迷影跟踪关系信息中查找28818
function ContexMenu_OnFriendInfoEx()
    local szName      = DataPool:GetFriend(Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "NAME")
	local zoneWorldID = DataPool:GetFriend(Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ZONEWORLDID")
	local friendguid  = DataPool:GetFriend( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ID"  )

	DataPool:LookupOtherParticularInfo( friendguid, zoneWorldID, szName );
	ContexMenuFrame_Close();
end

--"官员列表":发送邮件--add by xindefeng
function ContexMenu_OfficialPopMenu_SendMail_Clicked()
	ContexMenuFrame_Close()	--关掉菜单

	local szName = Guild:GetAnyGuildMembersInfo(tonumber(currentGuildListIndex), "Name")	--获取对方名字
	if(nil ~= szName) then
		DataPool:OpenMail(szName)
	end
end

--"官员列表":私聊--add by xindefeng
function ContexMenu_OfficialPopMenu_PrivateTalk_Clicked()
	ContexMenuFrame_Close()	--关掉菜单

	local szName = Guild:GetAnyGuildMembersInfo(tonumber(currentGuildListIndex), "Name")	--获取对方名字
	Talk:ContexMenuTalk(szName)
end

--"官员列表":查看详细--add by xindefeng
function ContexMenu_OfficialPopMenu_CheckInfo_Clicked()
	ContexMenuFrame_Close()	--关掉菜单

	local szName = Guild:GetAnyGuildMembersInfo(tonumber(currentGuildListIndex), "Name")	--获取对方名字
	if(nil ~= szName) then
		if(Friend:IsPlayerIsFriend(szName) == 1) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( szName );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( szName );
		else
			DataPool:ShowChatInfo( szName );
		end
	end
end

--"官员列表":加为好友--add by xindefeng
function ContexMenu_OfficialPopMenu_AddFriend_Clicked()
	ContexMenuFrame_Close()	--关掉菜单

	local szName = Guild:GetAnyGuildMembersInfo(tonumber(currentGuildListIndex), "Name")	--获取对方名字
	DataPool:AddFriendAndGrouping( szName)	--加为好友
end

--"官员列表":邀请入队--add by xindefeng
function ContexMenu_OfficialPopMenu_Invite_Clicked()
	ContexMenuFrame_Close()	--关掉菜单

	local szName = Guild:GetAnyGuildMembersInfo(tonumber(currentGuildListIndex), "Name")	--获取对方名字
	if(nil ~= szName) then
		Target:SendTeamRequest(szName);
	end
end

--"官员列表":申请入队--add by xindefeng
function ContexMenu_OfficialPopMenu_Apply_Clicked()
	ContexMenuFrame_Close()	--关掉菜单

	local szName = Guild:GetAnyGuildMembersInfo(tonumber(currentGuildListIndex), "Name")	--获取对方名字
	if(nil ~= szName) then
		Target:SendTeamApply(szName)
	end
end

function ContexMenu_FindFriend_VoteInfo_Talk_Clicked()
	ContexMenuFrame_Clicked();
	local szName, nOnlineFlag = FindFriendDataPool:GetVoteInfoByPos(g_Voteinfo_index);
	Talk:ContexMenuTalk( szName );
	ContexMenuFrame_Close();
end

function ContexMenu_FindFriend_VoteInfo_CheckInfo_Clicked()
	ContexMenuFrame_Clicked();
	local szName, nOnlineFlag = FindFriendDataPool:GetVoteInfoByPos(g_Voteinfo_index);
	if(nil ~= szName) then
		if( Friend:IsPlayerIsFriend( szName ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( szName );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( szName );
		else
			DataPool:ShowChatInfo( szName );
		end
	end
	ContexMenuFrame_Close();
end

function ContexMenu_FindFriend_VoteInfo_AddFriend_Clicked()
	ContexMenuFrame_Clicked();
	local szName, nOnlineFlag = FindFriendDataPool:GetVoteInfoByPos(g_Voteinfo_index);
	 DataPool:AddFriendAndGrouping(szName );
	 ContexMenuFrame_Close();
end

function ContexMenu_FindFriend_VoteInfo_Invite_Clicked()
	ContexMenuFrame_Clicked();
	local szName, nOnlineFlag = FindFriendDataPool:GetVoteInfoByPos(g_Voteinfo_index);
	if(nil ~= szName) then
		Target:SendTeamRequest(szName);
	end
	ContexMenuFrame_Close();
end

function ContexMenu_FindFriend_VoteInfo_Apply_Clicked()
	ContexMenuFrame_Clicked();
	local szName, nOnlineFlag = FindFriendDataPool:GetVoteInfoByPos(g_Voteinfo_index);
	if(nil ~= szName) then
		Target:SendTeamApply(szName);
	end
	ContexMenuFrame_Close();
end

function ContexMenu_CFindFriend_VoteInfo_PingBi_Clicked()
	ContexMenuFrame_Clicked();
	local szName, nOnlineFlag = FindFriendDataPool:GetVoteInfoByPos(g_Voteinfo_index);
	FindFriendDataPool:ContexMenuPingbiOrTousu("PINGBI", szName);
	ContexMenuFrame_Close();
end

function ContexMenu_FindFriend_VoteInfo_Toushu_Clicked()
end

-- 在投票界面使用雾影寻踪功能这里走原有的逻辑，因为这里必然是同服的人。Added By David Gao. 2011.09.12
function ContexMenu_FindFriend_VoteInfo_LookPos_Clicked()
	ContexMenuFrame_Clicked();
	local szName, nOnlineFlag = FindFriendDataPool:GetVoteInfoByPos(g_Voteinfo_index);

	if(nil ~= szName) then

		if( Friend:IsPlayerIsFriend( szName ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( szName );
			Friend:SetCurrentSelect( nIndex );
			DataPool:LookupOtherParticularInfo( "", -1, szName );
		else
			DataPool:LookupOtherParticularInfo( "", -1, szName );
		end
	end
	ContexMenuFrame_Close();
end


-- xiehong 2009-5-20 TrustFriend Begin---------------------------------

function ContexMenu_InviteToMyTeam()

	Friend : InviteTeam( g_Menu_ObjName );
	ContexMenuFrame_Close();

end

function ContextMenu_AddFriend()

	DataPool :AddFriendAndGrouping( g_Menu_ObjName );
	ContexMenuFrame_Close();

end

--function ContextMenu_WantToBeFriend()

	--DataPool : InviteAddFriendByteam( g_Menu_ObjId );
	--ContexMenuFrame_Close();

--end

function ContexMenu_SetChatTarget()

	Talk:ContexMenuTalk( g_Menu_ObjName );
	ContexMenuFrame_Close();

end

function ContexMenu_SendMail1()

	DataPool : OpenMail( g_Menu_ObjName );
	ContexMenuFrame_Close();

end

function ContexMenu_ShowInfo()

	if( Friend:IsPlayerIsFriend( g_Menu_ObjName ) == 1 ) then
		DataPool:ShowFriendInfo( g_Menu_ObjName );
	else
		DataPool:ShowChatInfo( g_Menu_ObjName );
	end

	ContexMenuFrame_Close();

end

-- xiehong 2009-5-20 TrustFriend End---------------------------------

--function ContexMenu_TeamBoard_InviteAddFriend()
	--if( g_TeamBoard_Guid == "" ) then
		--return;
	--end
	--DataPool:InviteAddFriendByteam(g_TeamBoard_Guid);
	--ContexMenuFrame_Close();
--end

function ContexMenu_TeamBoard_SendMail()
	local name = Talk:HandleMenuAction("Name") ;
	DataPool:OpenMail( name );

	ContexMenuFrame_Close();
end

--IM By Vega 20100601----------
--聊天群中 非群主身份--
--发送消息
function ChatGroup_Menu_SendMsg_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if( Friend:IsPlayerIsGoodFriendByGuid( g_Guid ) == 1 ) then
		if szName ~= nil then
			local nGroup , nIndex = DataPool:GetFriendByName(szName)
			if nGroup ~= -1 and nIndex ~= -1 then
				DataPool:Open1On1Chat(nGroup , nIndex)
			end
		end
	else
		PushDebugMessage("对方不是你的好友不能发送消息");
	end
	ContexMenuFrame_Close()
end
--加为好友
function ChatGroup_Menu_AddFriend_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		DataPool:AddFriendAndGrouping( szName );
	end
	ContexMenuFrame_Close()
end
--查看信息
function ChatGroup_Menu_ViewInfo_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if( Friend:IsPlayerIsFriendByGuid( g_Guid ) == 1 ) then
		if szName ~= nil then
			DataPool:ShowFriendInfo( szName );
		end
	else
		DataPool:ShowChatInfo( szName );
	end
	ContexMenuFrame_Close();
end
--申请入队
function ChatGroup_Menu_OnAskTeam()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		Friend:AskTeam( szName ,-1,g_Guid );
	end

end

--邀请加队
function ChatGroup_Menu_OnInviteTeam()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		Friend:InviteTeam( szName ,-1,g_Guid);
	end
end

--聊天群中 群主身份--
--发送消息
function ChatGroup_OwnerMenu_SendMsg_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if( Friend:IsPlayerIsGoodFriendByGuid( g_Guid ) == 1 ) then
		if szName ~= nil then
			local nGroup , nIndex = DataPool:GetFriendByName(szName)
			if nGroup ~= -1 and nIndex ~= -1 then
				DataPool:Open1On1Chat(nGroup , nIndex)
			end
		end
	else
		PushDebugMessage("对方不是你的好友不能发送消息");
	end
	ContexMenuFrame_Close()
end
--加好友
function ChatGroup_OwnerMenu_AddFriend_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		DataPool:AddFriendAndGrouping( szName );
	end
	ContexMenuFrame_Close()
end
--查看信息
function ChatGroup_OwnerMenu_ViewInfo_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if( Friend:IsPlayerIsFriendByGuid( g_Guid ) == 1 ) then
		if szName ~= nil then
			DataPool:ShowFriendInfo( szName );
		end
	else
		DataPool:ShowChatInfo( szName );
	end
	ContexMenuFrame_Close();
end
--申请入队
function ChatGroup_OwnerMenu_OnAskTeam()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		Friend:AskTeam( szName ,-1,g_Guid);
	end

end

--邀请加队
function ChatGroup_OwnerMenu_OnInviteTeam()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		Friend:InviteTeam( szName ,-1,g_Guid);
	end
end
--踢人
function ChatGroup_OwnerMenu_KickOut_Clicked()
	DataPool:GroupKickOut(tonumber(g_GroupID),g_Guid)
	ContexMenuFrame_Close()
end


--Friend界面中我的群下 非群主身份
--发消息
function MyGroup_Menu_SendMsg_Clicked()
	DataPool:OpenGroupChat(tonumber(g_GroupID))
	ContexMenuFrame_Close()
end
--退出群
function MyGroup_Menu_QuitGroup_Clicked()
	DataPool:QuitGroup(tonumber(g_GroupID) , 0)
	ContexMenuFrame_Close()
end
--历史消息
function MyGroup_Menu_History_Clicked()
	PushEvent("OPEN_IM_GROUP_HISTORY",tonumber(g_GroupID));
	ContexMenuFrame_Close()
end
--屏蔽
function MyGroup_Menu_SetHide_Clicked()
	DataPool:MuteGroup(tonumber(g_GroupID))
	ContexMenuFrame_Close()
end
--举报
function MyGroup_Menu_JvbaoGroup_Clicked()
	PushDebugMessage("举报功能还没开启")
	ContexMenuFrame_Close()
end

--Friend界面中我的群下 群主身份
--解散群
function MyGroup_OwnerMenu_DissolveGroup_Clicked()
	DataPool:DismissGroup(tonumber(g_GroupID) , 0)
	ContexMenuFrame_Close()
end
--发消息
function MyGroup_OwnerMenu_SendMsg_Clicked()
	DataPool:OpenGroupChat(tonumber(g_GroupID))
	ContexMenuFrame_Close()
end
--修改公告
function MyGroup_OwnerMenu_ModifyInfo_Clicked()
	DataPool:OpenModifyGroupNotice(tonumber(g_GroupID))
	ContexMenuFrame_Close()
end
--历史消息
function MyGroup_OwnerMenu_History_Clicked()
	PushEvent("OPEN_IM_GROUP_HISTORY",tonumber(g_GroupID))
	ContexMenuFrame_Close()
end
--屏蔽消息
function MyGroup_OwnerMenu_SetHide_Clicked()
	DataPool:MuteGroup(tonumber(g_GroupID))
	ContexMenuFrame_Close()
end
--举报该群
function MyGroup_OwnerMenu_JvbaoGroup_Clicked()
	PushDebugMessage("举报功能还没开启")
	ContexMenuFrame_Close()
end

--ChangeGroupMaster

-------------------------------------------------------------------
--团队

function Union_Appoint_Clicked(appType)
	local squadIdx, memIdx = Raid:GetMemberIndexByGUID(g_CurSelRaidMember)
	if squadIdx ~= -1 and memIdx ~= -1 then
		Player:RaidAppointByIdx(appType, squadIdx, memIdx)
	end
	ContexMenuFrame_Close()
	g_CurSelRaidMember = ""
end

function Union_Leave_Clicked()
		Player:LeaveRiad()
		ContexMenuFrame_Close()
end

function Union_Kick_Clicked()
	local squadIdx, memIdx = Raid:GetMemberIndexByGUID(g_CurSelRaidMember)
	if squadIdx ~= -1 and memIdx ~= -1 then
		Player:KickRaidMemberByIdx(squadIdx, memIdx)
	end
	ContexMenuFrame_Close()
	g_CurSelRaidMember = ""
end

function ContexMenu_ApplyToRaid_Clicked()
	Target:SendRaidApplication()
	ContexMenuFrame_Close()
end

function ContexMenu_InviteToRaid_Clicked()
	Target:SendRaidInvitation()
	ContexMenuFrame_Close()
end

function ContexMenu_PVP_FreeforRaid_Clicked()
	ShowAcceptChangePVPMode(6)
	ContexMenuFrame_Close()
end

function UIRaidSquadWindow_CloseSquad_Clicked()
	--Add By YPL, 2011-12-14
	SetShowState(g_RaidSquadIndex, -1)
	--End
	Raid:CloseRaidSquadWindowByIdx(g_RaidSquadIndex)
	ContexMenuFrame_Close()
end

function UIRaidSquadWindow_CloseAll_Clicked()
	Raid:CloseRaidSquadWindowByIdx(-1)
	ContexMenuFrame_Close()
end

function UISquadMemWindow_CloseMember_Clicked()
	Raid:CloseSquadMemWindowByGUID(g_CurSelRaidMember)
	ContexMenuFrame_Close()
	g_CurSelRaidMember = ""
end

function ContexMenu_OnPrivate_FromRaid()
	local name, zoneworldid = Raid:GetMemberNameByGUID(g_CurSelRaidMember)
	if( name == nil or name == "") then
		return
	end
	Talk:ContexMenuTalk(name, zoneworldid)
	ContexMenuFrame_Close()
	g_CurSelRaidMember = ""
end

function ContexMenu_AddFriend_FromRaid()
	local name, zoneworldid = Raid:GetMemberNameByGUID(g_CurSelRaidMember)
	if( name == nil or name == "") then
		return
	end
	DataPool:AddFriendAndGrouping(name, zoneworldid)
	ContexMenuFrame_Close()
	g_CurSelRaidMember = ""
end

function Union4_7_Clicked()
	Union_Kick_Clicked()
end

--function ContexMenu_AskAddFriend_FromRaid()
	--DataPool:InviteAddFriendByteam(g_CurSelRaidMember)
	--ContexMenuFrame_Close()
--end

function ContexMenu_ChatBoard_RiadInvite_Clicked()
	local szName = Talk:HandleMenuAction("Name")
	if(nil ~= szName) then
		Target:SendRaidInvitation(szName)
	end
	ContexMenuFrame_Close()
end

function ContexMenu_ChatBoard_RaidApply_Clicked()
	local szName = Talk:HandleMenuAction("Name")
	if(nil ~= szName) then
		Target:SendRaidApplication(szName)
	end
	ContexMenuFrame_Close()
end


function ContexMenu_Friend_RiadInvite_Clicked()
	local szName = DataPool:GetFriend(Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "NAME")
	local zoneWorldID = DataPool:GetFriend(Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ZONEWORLDID")
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	if(nil ~= szName) then
		if tonumber(zoneWorldID) ~= -1 and  zoneWorldID ~= selfZoneWorldID then
			Target:SendRaidInvitation(szName .. "@" .. DataPool:GetServerName( zoneWorldID ))
		else
			Target:SendRaidInvitation(szName)
		end
	end
	ContexMenuFrame_Close()
end

function ContexMenu_Friend_RaidApply_Clicked()
	local szName = DataPool:GetFriend(Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "NAME")
	local zoneWorldID = DataPool:GetFriend(Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), "ZONEWORLDID")
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	if(nil ~= szName) then
		if tonumber(zoneWorldID) ~= -1 and  zoneWorldID ~= selfZoneWorldID then
			Target:SendRaidApplication(szName .. "@" .. DataPool:GetServerName( zoneWorldID ))
		else
			Target:SendRaidApplication(szName)
		end
	end
	ContexMenuFrame_Close()
end

function ContexMenu_GuildList_RiadInvite_Clicked()
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name")
	if(nil ~= szName) then
		Target:SendRaidInvitation(szName)
	end
	ContexMenuFrame_Close()
end

function ContexMenu_GuildList_RaidApply_Clicked()
	local szName = Guild:GetMembersInfo(tonumber(currentGuildListIndex), "Name")
	if(nil ~= szName) then
		Target:SendRaidApplication(szName)
	end
	ContexMenuFrame_Close()
end

------------------------------------------------------------

function ContexMenu_CompareAchv_Clicked()
	Achievement:SelectCompareTarget()
	ContexMenuFrame_Close()
end

-------------------------------------------------------------
--	Added	by	lx	2011-5-24
function ContexMenu_ShowFoeInfo()
	DataPool:ShowFoeRelation();
	ContexMenuFrame_Close();
end
-------------------------------------------------------------

function ContexMenu_FoeListRefreshTitle()
	g_FoeListRefresh_Clicked = 1
	DataPool:ShowFriendInfo( Friend:GetCurrentTeam(), Friend:GetCurrentSelect(), 0 );
end

function ContexMenu_FoeListRefreshTitleSec()
	g_FoeListRefresh_Clicked = 0
	DataPool:RefreshFoeTitle(tonumber( currentSelectChannal ), tonumber( currentIndex ));
	ContexMenuFrame_Close();
end
-------------------------------------------------------------


















-------------------------------------------------------------
--
-- 势力官员右键菜单。Added By David Gao. 2011.10.28
--














function ContexMenu_MailList_Clicked(idx)
	MailListClicked(idx)
end

function ContexMenu_IsKvkRebuildLimit()
	if KVKInterface:IsKvKRebuildLimitServer() == 0 then
		return 0
	end

	local today = tonumber(GetTime2Day())
	local curHour = GetTime2Minite()


	if today == g_KvkRebuildLimitBeginDate then
		if curHour >= g_KvkRebuildLimitBeginHour then
			return 1
		end
	end

	if today == g_KvkRebuildLimitEndDate then
		if curHour < g_KvkRebuildLimitEndHour then
			return 1
		end
	end

	if today > g_KvkRebuildLimitBeginDate and today < g_KvkRebuildLimitEndDate then
		return 1
	end

	return 0
end

function ContexMenu_Forbidit_Clicked()
	ContexMenuFrame_Clicked();
	ContexMenuFrame_Close();
end

function ContexMenu_KickGamePlayer_Clicked()
	ContexMenuFrame_Clicked();
	Target:KickItOut( 0 );
	ContexMenuFrame_Close();
end

function ContexMenu_ChatForbidit_Clicked()
	ContexMenuFrame_Clicked();
	ContexMenuFrame_Close();
end

function ContexMenu_MengChonngHandle( order)
    if( order ==nil ) then
	return;
	end

	local action ={};
	action[1] = "1"
	action[2] = "2"
	action[3] = "3"
	action[4] = "4"
	action[5] = "s1"
	action[6] = "show"
	if order < 6 then
		--local index = BieYeMengChong:GetMengChongXiaoWoIndex()
		--if index == nil then
		--	return
		--end
		--index = index +1
		--if index <1 or index >6 then
		--	return
		--end
		--local nIndex = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",index)
		local nMengChongTransferID
		
		--local nName
		--if nIndex > 0 then 
		nMengChongTransferID =  BieYeMengChong:GetMengChongIsChengNian()
		--PushDebugMessage(nMengChongTransferID)
		if nMengChongTransferID == nil then
			return 
		end
		--	nName = BieYeMengChong:GetBieYeMengChongInfo(nIndex,2)
	   -- end
		if nMengChongTransferID > 0 then
			if order == 3 or order == 4 then

				PushDebugMessage("还没有学会这个动作！")
				return 
			end
		end
	--	PushDebugMessage(nMengChongTransferID)
		BieYeMengChong:HandleMengChongMenuItem(action[order]);
	elseif order == 6 then
		BieYeMengChong:HandleMengChongMenuItem(action[order]);  
	end
	if order == 7 then 
		local IsMaster = BieYeMengChong : IsMaster();
		if IsMaster == nil then
		    PushDebugMessage("#{MCJC_170727_02}")
			return
		end
		if IsMaster ~= 1 then
		PushDebugMessage("#{MCJC_170727_02}")
			return
		end
		local g_XiaoWoindex = BieYeMengChong:GetMengChongXiaoWoIndex();
		if g_XiaoWoindex == nil then
		--PushDebugMessage("#{MCJC_170727_28}")
			return
		end
		g_XiaoWoindex = g_XiaoWoindex + 1
		if g_XiaoWoindex >0 and g_XiaoWoindex <= 6 then
			BieYeMengChong:Lua_MinuXiaoWo(g_XiaoWoindex,0)	
		end
    end
	
	ContexMenuFrame_Close();
end

function ContexMenu_InfantHandle( order )
	if( order == nil ) then
		return;
	end

	local action = {};
	action[1] = "recall";
	action[2] = "cure";
	action[3] = "feel";
	action[4] = "kiss";
	action[5] = "hold";
	action[6] = "otherdetail";
	action[7] = "eat";
	action[8] = "drink";
	action[9] = "wash";
 

	Infant:HandleInfantMenuItem(action[order]);

	ContexMenuFrame_Close();
end

function ContexMenu_WangZheSet_Clicked( order )
	local myGuid = Player:GetGUID();
	local isLeader = KMCorps:IsKMCorpsLeader(myGuid);
	if isLeader == 0 then
		PushDebugMessage("#{WZTZS_150722_24}")
		return
	end

	if( order == nil or order < 1 or order > 4) then
		return;
	end

	local position = {};
	position[1] = g_KMMemIndex - 2
	position[2] = g_KMMemIndex
	position[3] = 0
	position[4] = 9

	local value = tonumber(position[order])
	if value < 0 or value > 9 then
		PushDebugMessage("不能这样移动")
		return
	end

	KMCorps:AdjustMemberPosition(g_KMMemIndex - 1, value)
	ContexMenuFrame_Close();
end

--争霸赛 2016版
function ContexMenu_Corps_Clicked( sequ )

	local IsLeader = CorpsUI_2016:IsCorpsLeader()
	local IsAssitant = CorpsUI_2016:IsCorpsAssist()
	if (IsLeader == nil or IsLeader <=0) and (IsAssitant==nil or IsAssitant<=0) then
		PushDebugMessage("#{ZBS16_160511_114}")
		return
	end

	if( sequ == nil or sequ<1 or sequ>4) then
		return
	end

	local memCount = CorpsUI_2016:GetCorpsMemberCount()
	local position = {};
	position[1] = g_CorpsMemIndex - 1
	position[2] = g_CorpsMemIndex + 1
	position[3] = 1
	position[4] = memCount

	if position[sequ] < 1 or position[sequ] > memCount then
		PushDebugMessage("不能这样移动")
		return
	end

	if position[sequ] == g_CorpsMemIndex then
		PushDebugMessage("不需要移动")
		return
	end

	local post, name, level, menpai, guid, battlesequ = CorpsUI_2016:GetCorpsMemberInfoByIdx(g_CorpsMemIndex - 1)
	if guid ~= nil then
		CorpsUI_2016:ChangeMemBatterSequ(guid, position[sequ])
	end
	ContexMenuFrame_Close();
end

--争霸赛 2018版
function ContexMenu_NoDiffMatch_Clicked( sequ )

end

function ContexMenu_Alliance_Clicked()
	local alliancemark =0
end























function ContexMenu_Other_CompareFightScore_Clicked()
	Target:Close_Before_TargetEquip_UI();
	Target:SendAskDetail(nil,"compare");
	ContexMenuFrame_Close();

	--缓存主目标信息
	CacheMainTarget();
end



function ChatGroup_Menu_GWRaidInvite_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		Target:SendRaidInvitation(szName)
	end
	ContexMenuFrame_Close()

end
function ChatGroup_OwnerMenu_GWRaidInvite_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if szName ~= nil then
		Target:SendRaidInvitation(szName)
	end
	ContexMenuFrame_Close()
end


function ChatGroup_Menu_GWRaidApply_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if(nil ~= szName) then
		Target:SendRaidApplication(szName)
	end
	ContexMenuFrame_Close()
end

function ChatGroup_OwnerMenu_GWRaidApply_Clicked()
	local szName = DataPool:GetGroupUserNameByGuid(tonumber(g_GroupID), g_Guid )
	if(nil ~= szName) then
		Target:SendRaidApplication(szName)
	end
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_Show_Clicked()
	BieYeUI:ViewFurniture(g_FurnitureObj)
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_Move_Clicked()
	PushDebugMessage("#{BYFUR_160531_282}")
	PushDebugMessage("#{BYFUR_160531_283}")

	BieYeUI:MoveFurnitureForObjId(g_FurnitureObj, 1)
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_DestroyIt_Clicked()
	local idx, itemId = BieYeUI:GetServerIdByObjId(g_FurnitureObj)
	if idx then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DestroyFurniture")
			Set_XSCRIPT_ScriptID(891837)
			Set_XSCRIPT_Parameter(0,idx)
			Set_XSCRIPT_Parameter(1,itemId)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_ReserveAll_Clicked()
	PushEvent( "BIEYE_RESERVE_TYPE_CONFIRM", g_FurnitureObj, BieYeUI:GetFurObjName(g_FurnitureObj) )
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_Turn_Clicked()
	PushDebugMessage("#{BYFUR_160531_284}")

	--PushEvent("BIEYEFURNITURETRUESHOW",1,g_FurnitureObj)
	BieYeUI:MoveFurnitureForObjId(g_FurnitureObj, 0)
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_Back_Clicked()
	BieYeUI:ReleaseFurniture(g_FurnitureObj)
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_Mood_Clicked()
	if BieYeUI:GetFurPlayerAnimNum(g_FurnitureObj) > 1 then
		return
	end
	BieYeUI:FurnitureAttachPlayer(g_FurnitureObj, 0)
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_BieYeFurniture_Mood2_Clicked(indx)
	BieYeUI:FurnitureAttachPlayer(g_FurnitureObj, indx)
	g_FurnitureObj = -1
	ContexMenuFrame_Close()
end

function ContexMenu_IsShowDisclosure()
	--if KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 then
		--return 0
	--end
	if IsInTServer() == 1 then
		return 0
	end
	return 1
end

function ContexMenu_Disclosure_Clicked()
	ContexMenuFrame_Clicked();
	Target:ReportWaiguaForInfo();
	ContexMenuFrame_Close();
end
function ContexMenu_WeiYang()
	local isMaster = BieYeMengChong:IsMaster()
	if isMaster ~= 1 then
		PushDebugMessage("#{MCJC_170727_02}")
		return 
	end
	local g_XiaoWoindex = BieYeMengChong:GetMengChongXiaoWoIndex();
		if g_XiaoWoindex == nil then
			PushDebugMessage("#{MCJC_170727_28}")
			return
		end
	g_XiaoWoindex = g_XiaoWoindex+1
	if g_XiaoWoindex >0 and g_XiaoWoindex <= 6 then
		BieYeMengChong:Lua_WeiYang(g_XiaoWoindex)
	else
		PushDebugMessage("#{MCJC_170727_24}")
	end

end

function ContexMenu_BackBag()
	local isMaster = BieYeMengChong:IsMaster()
	if isMaster ~= 1 then
		PushDebugMessage("#{MCJC_170727_02}")
		return
	end
	local g_XiaoWoindex = BieYeMengChong:GetMengChongXiaoWoIndex();
		if g_XiaoWoindex == nil then
			--PushDebugMessage("#{MCJC_170727_28}")
			--PushDebugMessage("1")
			return
		end
	g_XiaoWoindex = g_XiaoWoindex+1
	local nIndex = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",g_XiaoWoindex)
	if g_XiaoWoindex >0 and g_XiaoWoindex <= 6 then
		BieYeMengChong:MengChongBackBag(nIndex,g_XiaoWoindex-1)
	else
		PushDebugMessage("#{MCJC_170727_24}")
	end

end

function ContexMenu_BWRankingList_CheckInfo_Clicked()
	ContexMenuFrame_Clicked();
	--local index = Guild:GetShowMembersIdx(tonumber(currentGuildListIndex));
	local szName = BWDH2018:GetMembersInfo(tonumber(currentRankListIndex));

	if(nil ~= szName) then
		if( Friend:IsPlayerIsFriend( szName ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( szName );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( szName );
		else
			DataPool:ShowChatInfo( szName );
		end
	end
	ContexMenuFrame_Close();
end;


function Menu_PVPMode_T300Set()
	--if IsInTServer() == 1 then
		--Menu_PVP_FreeforKGuild:SetText("#{TFJCGZ_20200817_22}") 
		--Menu_PVP_FreeforKGuild:SetToolTip( "#{TFJCGZ_20200817_23}" )
	--else
		Menu_PVP_FreeforKGuild:SetText("#{INTERFACE_XML_133}") 
		Menu_PVP_FreeforKGuild:SetToolTip( "#{TM_20080311_16}" )
	--end
end

function ContexMenu_BZTXList_select_Clicked()
	if string.len(g_bztxselectname) > 0 then
		Target:SelectThePlayer(g_bztxselectname);
	end
	ContexMenuFrame_Close();
end


function ContexMenu_BZTXList_mail_Clicked()
	if string.len(g_bztxselectname) > 0 then
		DataPool:OpenMail( g_bztxselectname );
	end
	ContexMenuFrame_Close();
end

function ContexMenu_BZTXList_msg_Clicked()
	if string.len(g_bztxselectname) > 0 then
		Talk:ContexMenuTalk( g_bztxselectname );
	end
	ContexMenuFrame_Close();

end


function ContexMenu_BZTXList_see_Clicked()
	if string.len(g_bztxselectname) > 0 then
		if( Friend:IsPlayerIsFriend( g_bztxselectname ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( g_bztxselectname );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( g_bztxselectname );
		else
			DataPool:ShowChatInfo( g_bztxselectname );
		end
	end
	ContexMenuFrame_Close();

end

function ContexMenu_BZTXList_addfriend_Clicked()
	if string.len(g_bztxselectname) > 0 then
		DataPool:AddFriendAndGrouping(  g_bztxselectname );
	end
	ContexMenuFrame_Close();
end

function ContexMenu_BZTXList_InviteTeam_Clicked()

	if string.len(g_bztxselectname) > 0 then
		Target:SendTeamRequest(g_bztxselectname);
	end
	ContexMenuFrame_Close();
end


function ContexMenu_BZTXList_ApplyTeam_Clicked()

	if string.len(g_bztxselectname) > 0 then
		Target:SendTeamApply(g_bztxselectname);
	end
	ContexMenuFrame_Close();
end


function ContexMenu_BZTXList_InviteRaid_Clicked()
	if string.len(g_bztxselectname) > 0 then
		Target:SendRaidApplication(g_bztxselectname);
	end
	ContexMenuFrame_Close();
end



function ContexMenu_FightGroup_Compare_Selected_Clicked()
	if string.len(g_guildZhanTuanSelectName) > 0 then
		Target:SelectThePlayer(g_guildZhanTuanSelectName);
	end
	ContexMenuFrame_Close();
end


function ContexMenu_FightGroup_Compare_SendMail_Clicked()
	if string.len(g_guildZhanTuanSelectName) > 0 then
		DataPool:OpenMail( g_guildZhanTuanSelectName );
	end
	ContexMenuFrame_Close();
end

function ContexMenu_FightGroup_Compare_DM_Clicked()
	if string.len(g_guildZhanTuanSelectName) > 0 then
		Talk:ContexMenuTalk( g_guildZhanTuanSelectName );
	end
	ContexMenuFrame_Close();

end


function ContexMenu_FightGroup_Compare_Data_Clicked()
	if string.len(g_guildZhanTuanSelectName) > 0 then
		if( Friend:IsPlayerIsFriend( g_guildZhanTuanSelectName ) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( g_guildZhanTuanSelectName );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( g_guildZhanTuanSelectName );
		else
			DataPool:ShowChatInfo( g_guildZhanTuanSelectName );
		end
	end
	ContexMenuFrame_Close();

end

function ContexMenu_FightGroup_Compare_AddFriend_Clicked()
	if string.len(g_guildZhanTuanSelectName) > 0 then
		DataPool:AddFriendAndGrouping(  g_guildZhanTuanSelectName );
	end
	ContexMenuFrame_Close();
end

function ContexMenu_FightGroup_Compare_Invitation_Clicked()

	if string.len(g_guildZhanTuanSelectName) > 0 then
		Target:SendTeamRequest(g_guildZhanTuanSelectName);
	end
	ContexMenuFrame_Close();
end


function ContexMenu_FightGroup_Compare_JoinTeam_Clicked()

	if string.len(g_guildZhanTuanSelectName) > 0 then
		Target:SendTeamApply(g_guildZhanTuanSelectName);
	end
	ContexMenuFrame_Close();
end


function ContexMenu_FightGroup_Compare_JoinGroup_Clicked()
	if string.len(g_guildZhanTuanSelectName) > 0 then
		Target:SendRaidApplication(g_guildZhanTuanSelectName);
	end
	ContexMenuFrame_Close();
end

-----选择该玩家-----
function ContexMenu_Challenge_SelectThePlayer()
	ContexMenuFrame_Close()
	
	if g_challengeIndex < 0 then
		return
	end
	
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(g_challengeIndex)	
	if ret == 0 then
		return
	end

	if(nil ~= name) then
		Target:SelectThePlayer(name, zoneWorldId)
	end
end


function ContexMenu_Challenge_Clicked()
	ContexMenuFrame_Close()
	
	if g_challengeIndex < 0 then
		return
	end
	
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(g_challengeIndex)	
	if ret == 0 then
		return
	end

	if(nil ~= objId) then
		DataPool:Challenge(objId);
	end
end

function ContexMenu_Challenge_Private_Talk_Clicked()
	ContexMenuFrame_Close()
	
	if g_challengeIndex < 0 then
		return
	end
	
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(g_challengeIndex)	
	if ret == 0 then
		return
	end

	if name ~= nil and name ~= "" then
		Talk:ContexMenuTalk( name, zoneWorldId )
	end
end

function ContexMenu_Challenge_CheckInfo_Clicked()
	ContexMenuFrame_Close()
	
	if g_challengeIndex < 0 then
		return
	end
	
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(g_challengeIndex)	
	if ret == 0 then
		return
	end

	if(nil ~= name) then
		if( Friend:IsPlayerIsFriend( name, zoneWorldId ) == 1 ) then
			DataPool:ShowFriendInfo( name, zoneWorldId );
		else
			DataPool:ShowChatInfoByZWId( name, zoneWorldId );
		end
	end
end


function ContexMenu_Challenge_AddFriend_Clicked()
	ContexMenuFrame_Close()
	
	if g_challengeIndex < 0 then
		return
	end
	
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(g_challengeIndex)	
	if ret == 0 then
		return
	end

	if(nil ~= name) then
		DataPool:AddFriendAndGrouping( name,zoneWorldId )
	end
end

function ContexMenu_Challenge_Invite_Clicked()
	ContexMenuFrame_Close()
	
	if g_challengeIndex < 0 then
		return
	end
	
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(g_challengeIndex)	
	if ret == 0 then
		return
	end

	if(nil ~= name) then
		Friend:InviteTeam( name, tonumber(zoneWorldId));
	end
end

function ContexMenu_Challenge_Apply_Clicked()
	ContexMenuFrame_Close()
	
	if g_challengeIndex < 0 then
		return
	end
	
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(g_challengeIndex)	
	if ret == 0 then
		return
	end

	if(nil ~= name) then
		Friend:AskTeam( name, tonumber(zoneWorldId));
	end
end

