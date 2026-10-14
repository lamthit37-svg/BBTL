--*--------------------------------------------------------------------------------------------------------------------
--* 组队相关的lua脚本
--* 1, 邀请界面.
--* 2, 队员打开队伍信息界面.
--* 3, 队长打开队伍信息界面.
--* 4, 队长打开申请者界面.
--*
--*---------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------
-- 全局需要用到的变量.
--
local g_iTeamInfoType = 4;				-- 操作类型
																	-- 0 : 打开队友信息对话框
																	-- 1 : 打开申请对话框
																	-- 2 : 打开邀请对话框.
																	-- 3 : 队长打开队友信息对话框.
																	-- 4 : 非组队玩家打开界面
																	-- -1: 关闭界面

-----------------------------------------------------------------------------------------------------------------------
-- 邀请界面
--
local g_iTeamCount_Invite   = 0;	-- 邀请队伍的个数.
local g_iCurShowTeam_Invite = 0;	-- 在界面上显示的队伍
																	-- -1 : 没有显示的队伍.


------------------------------------------------------------------------------------------------------------------------
-- 队员打开队伍信息界面
--



------------------------------------------------------------------------------------------------------------------------
-- 队长打开队伍信息界面
--
local g_iTeamMemberCount_Team = 0;	-- 当前队伍中队员的个数.
local g_iCurSel_Team = -1;						-- 当前选择的队员.


------------------------------------------------------------------------------------------------------------------------
-- 队长打开申请者界面
--
local g_iSel = -1;									-- 在界面上选择的队员
																	-- -1 : 没有选择队员.


local g_iCurPageShowCount  = 6; 	-- 当前页面显示的申请人的个数.
local g_iMemberCount_Apply = 0;		-- 界面打开时, 队员的个数.
local g_iCurSel_Apply      = 0;   -- 当前选择的申请者.(当前页面的索引)
local g_iCurShowPage_Apply = 0;   -- 当前选择的页面.
local g_iCurSelApply_Apply = 0;   -- 当前选择的索引, (从头开始)


local g_iRealSelApplyIndex      = 0;	-- 当前实际选择的申请者的索引
local g_iRealSelInvitorIndex    = 0;	-- 当前实际选择的邀请队伍索引
local g_iRealSelTeamMemberIndex = 0;  -- 当前实际选择的邀请队伍的索引
local g_iRealSelInvitorIndexPingbi = 0;	-- 当前实际选择的邀请队伍索引,屏蔽按钮用到

------------------------------------------------------------------------------------------------------------------------
-- 界面控件
--
local g_Team_PlayerInfo_Name   = {};
local g_Team_PlayerInfo_School = {};
local g_Team_PlayerInfo_Level  = {};

local g_Team_PlayerInfo_Dead = {};
local g_Team_PlayerInfo_Deadlink = {};

local g_Team_Ui_Model_Disable = {};

local g_Team_PlayerInfo_Server = {};    --- 玩家所在的服务器名

local g_Team_PlayerInfo_FightScore = {};
local g_Team_PlayerInfo_GuildName = {};
-------------------------------------------------------------------------------------------------------------------------
-- 模型界面
--
local g_TeamFrame_FakeObject = {};
local g_bUpdateTeamFakeObj = 1;

function Team_Frame_PreLoad()

	-- 打开窗口界面
	this:RegisterEvent("TEAM_OPEN_TEAMINFO_DLG",true);

	-- 刷新队员信息
	this:RegisterEvent("TEAM_REFRESH_MEMBER",false);

	-- 主角离开场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- 有队伍事件, 邀请, 申请
	this:RegisterEvent("TEAM_NOTIFY_APPLY",true);

	--重置
	this:RegisterEvent("RESET_ALLUI",true);

	-- 确认解散队伍
	this:RegisterEvent("CONFIRM_DISMISS_TEAM",true);

	this:RegisterEvent("ACC_CHANGE_TIPS",false)

	this:RegisterEvent("ONOPENBIEYEFURCREATE",false)

end

function Team_Frame_OnLoad()
	-- 保存
	g_Team_PlayerInfo_Name[0] = Team_PlayerInfo1_Name;
	g_Team_PlayerInfo_Name[1] = Team_PlayerInfo2_Name;
	g_Team_PlayerInfo_Name[2] = Team_PlayerInfo3_Name;
	g_Team_PlayerInfo_Name[3] = Team_PlayerInfo4_Name;
	g_Team_PlayerInfo_Name[4] = Team_PlayerInfo5_Name;
	g_Team_PlayerInfo_Name[5] = Team_PlayerInfo6_Name;

	g_Team_PlayerInfo_School[0] = Team_PlayerInfo1_School;
	g_Team_PlayerInfo_School[1] = Team_PlayerInfo2_School;
	g_Team_PlayerInfo_School[2] = Team_PlayerInfo3_School;
	g_Team_PlayerInfo_School[3] = Team_PlayerInfo4_School;
	g_Team_PlayerInfo_School[4] = Team_PlayerInfo5_School;
	g_Team_PlayerInfo_School[5] = Team_PlayerInfo6_School;

	g_Team_PlayerInfo_Level[0] = Team_PlayerInfo1_Level;
	g_Team_PlayerInfo_Level[1] = Team_PlayerInfo2_Level;
	g_Team_PlayerInfo_Level[2] = Team_PlayerInfo3_Level;
	g_Team_PlayerInfo_Level[3] = Team_PlayerInfo4_Level;
	g_Team_PlayerInfo_Level[4] = Team_PlayerInfo5_Level;
	g_Team_PlayerInfo_Level[5] = Team_PlayerInfo6_Level;

	g_TeamFrame_FakeObject[0] = TeamFrame_FakeObject1;
	g_TeamFrame_FakeObject[1] = TeamFrame_FakeObject2;
	g_TeamFrame_FakeObject[2] = TeamFrame_FakeObject3;
	g_TeamFrame_FakeObject[3] = TeamFrame_FakeObject4;
	g_TeamFrame_FakeObject[4] = TeamFrame_FakeObject5;
	g_TeamFrame_FakeObject[5] = TeamFrame_FakeObject6;

	-- 死亡标记
	g_Team_PlayerInfo_Dead[0] = Team_Die_Icon1;
	g_Team_PlayerInfo_Dead[1] = Team_Die_Icon2;
	g_Team_PlayerInfo_Dead[2] = Team_Die_Icon3;
	g_Team_PlayerInfo_Dead[3] = Team_Die_Icon4;
	g_Team_PlayerInfo_Dead[4] = Team_Die_Icon5;
	g_Team_PlayerInfo_Dead[5] = Team_Die_Icon6;

	-- 掉线标记
	g_Team_PlayerInfo_Deadlink[0] = Team_Downline_Icon1;
	g_Team_PlayerInfo_Deadlink[1] = Team_Downline_Icon2;
	g_Team_PlayerInfo_Deadlink[2] = Team_Downline_Icon3;
	g_Team_PlayerInfo_Deadlink[3] = Team_Downline_Icon4;
	g_Team_PlayerInfo_Deadlink[4] = Team_Downline_Icon5;
	g_Team_PlayerInfo_Deadlink[5] = Team_Downline_Icon6;


	-- ui 隐藏模型
	g_Team_Ui_Model_Disable[0] = Team_Model1_Disable;
	g_Team_Ui_Model_Disable[1] = Team_Model2_Disable;
	g_Team_Ui_Model_Disable[2] = Team_Model3_Disable;
	g_Team_Ui_Model_Disable[3] = Team_Model4_Disable;
	g_Team_Ui_Model_Disable[4] = Team_Model5_Disable;
	g_Team_Ui_Model_Disable[5] = Team_Model6_Disable;

    --- 玩家所在的服务器名
    g_Team_PlayerInfo_Server[0] = Team_PlayerFuWuQiInfo1;
    g_Team_PlayerInfo_Server[1] = Team_PlayerFuWuQiInfo2;
    g_Team_PlayerInfo_Server[2] = Team_PlayerFuWuQiInfo3;
    g_Team_PlayerInfo_Server[3] = Team_PlayerFuWuQiInfo4;
    g_Team_PlayerInfo_Server[4] = Team_PlayerFuWuQiInfo5;
    g_Team_PlayerInfo_Server[5] = Team_PlayerFuWuQiInfo6;

	g_Team_PlayerInfo_FightScore[0] = Team_Model1_PingFen
	g_Team_PlayerInfo_FightScore[1] = Team_Model2_PingFen
	g_Team_PlayerInfo_FightScore[2] = Team_Model3_PingFen
	g_Team_PlayerInfo_FightScore[3] = Team_Model4_PingFen
	g_Team_PlayerInfo_FightScore[4] = Team_Model5_PingFen
	g_Team_PlayerInfo_FightScore[5] = Team_Model6_PingFen

	g_Team_PlayerInfo_GuildName[0] = Team_PlayerInfo1_Banghui
	g_Team_PlayerInfo_GuildName[1] = Team_PlayerInfo2_Banghui
	g_Team_PlayerInfo_GuildName[2] = Team_PlayerInfo3_Banghui
	g_Team_PlayerInfo_GuildName[3] = Team_PlayerInfo4_Banghui
	g_Team_PlayerInfo_GuildName[4] = Team_PlayerInfo5_Banghui
	g_Team_PlayerInfo_GuildName[5] = Team_PlayerInfo6_Banghui

	Team_Die_Icon1:Hide();
	Team_Die_Icon2:Hide();
	Team_Die_Icon3:Hide();
	Team_Die_Icon4:Hide();
	Team_Die_Icon5:Hide();
	Team_Die_Icon6:Hide();


	Team_Downline_Icon1:Hide();
	Team_Downline_Icon2:Hide();
	Team_Downline_Icon3:Hide();
	Team_Downline_Icon4:Hide();
	Team_Downline_Icon5:Hide();
	Team_Downline_Icon6:Hide();

	Team_Exp_Mode:ComboBoxAddItem( "平均分配", 0 );
	Team_Exp_Mode:ComboBoxAddItem( "驯兽模式", 1 );

end

function Team_StateUpdate()
	-- 隐藏跟随按钮
	Team_Button_Frame8:Hide()

	Team_Follow_Button:Hide();

	if( Player:InTeamFollowMode() ) then
		Team_AbortTeamFollow_Button:Show();
	else
		Team_AbortTeamFollow_Button:Hide();
	end
	--由于删掉了3的类型，所有3的类型都变成0
	if( g_iTeamInfoType == 3 ) then
		g_iTeamInfoType = 0;
	end
	if( 0 == g_iTeamInfoType) then
	-- 打开队伍信息
		-- 填充自己的信息
		DataPool:SetSelfInfo();
		-- 显示界面
		local leader = Player:IsLeader();

		if( leader == 1 ) then

			TeamFrame_OpenLeaderTeamInfo();
		else

			TeamFrame_OpenTeamInfo();
		end
		-- 选择第一个
		SelectPos(0);


	elseif(1 == g_iTeamInfoType) then
	-- 队长打开申请加入队伍列表

		-- 显示界面
		ShwoLeaderFlat(0);
		TeamFrame_OpenApplyList();
		Team_Update_ExpMode( -1 );
			-- 选择第一个
		SelectPos(0);

	elseif(2 == g_iTeamInfoType) then
	-- 打开邀请对话框.

		ClearInfo();
		-- 显示界面
		TeamFrame_OpenInvite();
		Team_Update_ExpMode( -1 );
			-- 选择第一个
		SelectPos(0);

	elseif(3 == g_iTeamInfoType) then
	-- 队长打队伍列表

		-- 填充自己的信息
		DataPool:SetSelfInfo();
		-- 显示界面

		-- 选择第一个
		SelectPos(0);

	elseif(4 == g_iTeamInfoType) then
	-- 非组队玩家打开界面
		TeamFrame_OpenCreateTeamSelf();
		Team_Update_ExpMode( -1 );

	elseif(5 == g_iTeamInfoType) then
	-- 团长长打开申请入团列表

		TeamFrame_OpenRaidApplyList()
		Team_Update_ExpMode( -1 )
			-- 选择第一个
		SelectPos(0)
	end
end

function Team_Frame_OnEvent(event)

	---------------------------------------------------------------------------------------------
	--
	-- 打开界面事件.
	--
	if ( event == "TEAM_OPEN_TEAMINFO_DLG" ) then

		--隐藏ui模型蒙子.
		HideUIModelDisable();
		-- 得到打开的对话框的显示类型.
		local iShow = tonumber(arg0);

		if(-1 == iShow) then

			Team_Close();
			return;
		elseif( 4 == iShow ) then
			if(this:IsVisible()) then
			else
				return;
			end
		elseif( 3 == iShow ) then

		elseif(6 == iShow) then
			if(this:IsVisible()) then
				if Player:IsRaidLeader() == 1 and Raid:GetApplicantCount() > 0 then
					g_iTeamInfoType = 5
					Team_StateUpdate()
				end
				return
			end

		else
			-- 如果按钮不闪烁.
			-- 如果当前界面是打开的. 则关闭界面
			if(this:IsVisible()) then
				Team_Close();
				return;
			end;
		end;

		if Player:IsInRaid() == 1 then
			if Player:IsRaidLeader() == 1 and Raid:GetApplicantCount() > 0 then
				CloseWindow("UnionFrame", true)
				g_iTeamInfoType = 5
				Team_StateUpdate();
			end
			return;
		end

		if DataPool:GetApplyMemberCount() > 0 then
			g_iTeamInfoType = 1;
		end
		if Player:IsInTeam() == 0 and DataPool:GetInviteTeamCount() == 0 then
			g_iTeamInfoType = 4
		end
		Team_StateUpdate();
		return;

	end

	------------------------------------------------------------------------------------
	--
	-- 刷新队员信息事件
	--
	if(event == "TEAM_REFRESH_MEMBER") then

		if (this:IsVisible()) then
			if( tonumber( arg0 ) == 100 ) then
				Team_Update_ExpMode( 0 );
				return;
			end;
		end;

		if(this:IsVisible()) then

			-- 只要窗口打开时, 才刷新界面数据
			-- 假如当前界面打开队员信息.
			if(g_iTeamInfoType == 0) then
				-- 得到要刷新队员的位置
				g_bUpdateTeamFakeObj = tonumber( arg1 )
				local iMemberIndex = tonumber(arg0);
				if((iMemberIndex >= 0) and (iMemberIndex < 6)) then
					ShwoLeaderFlat(1);
					-- 刷新队员信息.
					TeamFrame_RefreshTeamMember_Team(iMemberIndex);
				end;
				if( g_bUpdateTeamFakeObj == 1 ) then
					-- 清空界面
					ClearUIModel();
					-- 刷新ui模型
					RefreshUIModel();
				end
				g_bUpdateTeamFakeObj = 1
			end
			return;
		end;-- if(this:IsVisible()) then
	end;


	------------------------------------------------------------------------------------------
	--
	-- 离开场景事件
	--
	if( event == "HIDE_ON_SCENE_TRANSED") then
		Team_Close();
		return;
	end


	-------------------------------------------------------------------------------------------
	--
	-- 有队伍事件, 邀请, 申请
	--
	if( event == "TEAM_NOTIFY_APPLY") then
		g_iTeamInfoType = tonumber(arg0);

		if( this:IsVisible() ) then
			--隐藏ui模型蒙子.
			-- 0 : 打开队友信息对话框
			-- 1 : 打开申请对话框
			-- 2 : 打开邀请对话框.
			-- 3 : 队长打开队友信息对话框.
			-- -1: 关闭界面
			if Player:IsRaidLeader() == 1 then
					g_iTeamInfoType = 5
					Team_StateUpdate()
			else
				if DataPool:GetApplyMemberCount() > 0 then
					g_iTeamInfoType = 1;
				end
				Team_StateUpdate();
			end
		end
		return;
	end
	if( event == "RESET_ALLUI") then
		g_iTeamInfoType = 4;
		return;
	end


	----------------------------------------------------------------------------------------------
	--
	-- 确认解散队伍
	--
	if ( event == "CONFIRM_DISMISS_TEAM" )	then
		Team_Confirm_Dismiss_Team();
		return;
	end

	if ( event == "ACC_CHANGE_TIPS" )	then
		Team_ChangeButtonTip()
		return;
	end
	-----------------界面互斥---------------
	if (event == "ONOPENBIEYEFURCREATE") then
		if(this:IsVisible()) then
			Team_Close()
		end
	end
end



------------------------------------------------------------------------------------------------------------------
-- 点击人物事件
--
function TeamFrame_Select1()

	g_iSel = 0;


	--FlashTeamButton(0);
	if(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);


	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);
		-- g_iRealSelInvitorIndex = g_iSel;

		g_iRealSelInvitorIndexPingbi = g_iSel;

	elseif(0 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

		if(0 == g_iTeamMemberCount_Team) then

			-- 如果队伍个数是0, 返回.
			return;
		end
		local leader = Player:IsLeader();
		if(leader == 1)then
			Team_Button_Frame3:Disable();
			-- 禁止队长任命按钮
			Team_Button_Frame4:Disable();
		end
		-- 记录当前选中的人物
		--SetCurSelMember(g_iSel);
		g_iRealSelTeamMemberIndex = g_iSel;

	elseif(5 == g_iTeamInfoType) then
		-- 团长打开申请入团列表
		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);
	end

end

------------------------------------------------------------------------------------------------------------------
-- 点击人物事件
--
function TeamFrame_Select2()

	g_iSel = 1;


	--FlashTeamButton(1);
	if(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);

		g_iRealSelInvitorIndexPingbi = g_iSel;

	elseif(0 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);
		g_iRealSelTeamMemberIndex = g_iSel;

		local leader = Player:IsLeader();
		if(leader == 1)then
			Team_Button_Frame3:Enable();
			-- 禁止队长任命按钮
			Team_Button_Frame4:Enable();
		end

	elseif(5 == g_iTeamInfoType) then
		-- 团长打开申请入团列表
		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);
	end

end

------------------------------------------------------------------------------------------------------------------
-- 点击人物事件
--
function TeamFrame_Select3()

	g_iSel = 2;
	--FlashTeamButton(2);

	if(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);

		g_iRealSelInvitorIndexPingbi = g_iSel;

	elseif(0 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);
		g_iRealSelTeamMemberIndex = g_iSel;

		local leader = Player:IsLeader();
		if(leader == 1)then
			Team_Button_Frame3:Enable();
			-- 禁止队长任命按钮
			Team_Button_Frame4:Enable();
		end

	elseif(5 == g_iTeamInfoType) then
		-- 团长打开申请入团列表
		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);
	end

end




------------------------------------------------------------------------------------------------------------------
-- 点击人物事件
--
function TeamFrame_Select4()

	g_iSel = 3;
	--FlashTeamButton(3);

	if(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);

		g_iRealSelInvitorIndexPingbi = g_iSel;

	elseif(0 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);
		g_iRealSelTeamMemberIndex = g_iSel;

		local leader = Player:IsLeader();
		if(leader == 1)then
			Team_Button_Frame3:Enable();
			-- 禁止队长任命按钮
			Team_Button_Frame4:Enable();
		end

	elseif(5 == g_iTeamInfoType) then
		-- 团长打开申请入团列表
		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);
	end

end

------------------------------------------------------------------------------------------------------------------
-- 点击人物事件
--
function TeamFrame_Select5()

	g_iSel = 4;
	--FlashTeamButton(0);

	if(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);

		g_iRealSelInvitorIndexPingbi = g_iSel;

	elseif(0 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);
		g_iRealSelTeamMemberIndex = g_iSel;

		local leader = Player:IsLeader();
		if(leader == 1)then
			Team_Button_Frame3:Enable();
			-- 禁止队长任命按钮
			Team_Button_Frame4:Enable();
		end

	elseif(5 == g_iTeamInfoType) then
		-- 团长打开申请入团列表
		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);
	end

end

------------------------------------------------------------------------------------------------------------------
-- 点击人物事件
--
function TeamFrame_Select6()

	g_iSel = 5;
	--FlashTeamButton(1);

	if(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);

		g_iRealSelInvitorIndexPingbi = g_iSel;

	elseif(0 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

		-- 记录当前选中的人物
		-- SetCurSelMember(g_iSel);
		g_iRealSelTeamMemberIndex = g_iSel;

		local leader = Player:IsLeader();
		if(leader == 1)then
			Team_Button_Frame3:Enable();
			-- 禁止队长任命按钮
			Team_Button_Frame4:Enable();
		end

	elseif(5 == g_iTeamInfoType) then
		-- 团长打开申请入团列表
		-- 设置当前选中的申请者
		TeamFrame_SetCurSelectedApply_Apply(g_iSel);
	end
end


------------------------------------------------------------------------------------------------------------------
-- 按钮 Team_Follow 点击事件
--
function Team_Button_Team_Follow_Click()

	if( 0 == g_iTeamInfoType) then
		-- 打开队伍信息
		-- 队长打开队友信息对话框.
		local leader = Player:IsLeader();
		if( leader == 1 ) then
			Player:TeamFrame_AskTeamFollow();
			Team_Close();
		end

	elseif(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

	elseif(3 == g_iTeamInfoType) then


	end

end




------------------------------------------------------------------------------------------------------------------
-- 按钮0点击事件
--
function Team_Button_Frame0_Click()

	if( 0 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表
		local leader = Player:IsLeader();
		if( leader == 1 ) then
				-- 得到申请人的个数.
			iMemberCount_Apply = DataPool:GetApplyMemberCount();
			if(0 == iMemberCount_Apply) then
				return;
			end
			TeamFrame_OpenApplyList();
		end
	elseif(1 == g_iTeamInfoType) then
		-- 队长组队列表

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.
	end
end



------------------------------------------------------------------------------------------------------------------
-- 按钮1点击事件
--
function Team_Button_Frame1_Click()

	if( 0 == g_iTeamInfoType) then
		-- 打开队伍信息
		local leader = Player:IsLeader();
		if( leader == 1 ) then
			Player:OpenDismissTeamMsgbox();			-- 打开解散队伍的二次确认窗口			add by WTT	20090212
		end
	elseif(1 == g_iTeamInfoType) then
		-- 队长打开队伍列表
		DataPool:SetSelfInfo();
		TeamFrame_OpenLeaderTeamInfo();

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

	elseif(5 == g_iTeamInfoType) then
		-- 团长打开团队信息
		OpenWindow("UnionFrame")
		Team_Close()
	end

end

------------------------------------------------------------------------------------------------------------------
-- 按钮2点击事件
--
function Team_Button_Frame2_Click()

	if( 0 == g_iTeamInfoType) then
		-- 打开队伍信息
		local leader = Player:IsLeader();
		if( leader == 1 ) then
			Player:LeaveTeam();
			Team_Close();
		end
	elseif(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 前翻页
		TeamFrame_PageUp_Apply();

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

	elseif(5 == g_iTeamInfoType) then
		-- 前翻页
		TeamFrame_PageUp_Apply();
	end

end


------------------------------------------------------------------------------------------------------------------
-- 按钮3点击事件
--
function Team_Button_Frame3_Click()

	if( 0 == g_iTeamInfoType) then
		-- 打开队伍信息
		local leader = Player:IsLeader();
		if( leader == 1 ) then
			if((-1 == g_iSel) or (0 == g_iSel))then

			-- 如果在界面上没有选择一个队员就返回
			-- 或者选中的是自己(队长), 也返回.
			return;
			end

			-- 踢出一个队员.
			--Player:KickTeamMember();

			local iTeamCount = DataPool:GetTeamMemberCount();

			if(iTeamCount <= g_iSel) then

				return;
			end;
			Player:KickTeamMember(g_iRealSelTeamMemberIndex);

			Team_Close();
		end
	elseif(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 向后翻页
		TeamFrame_PageDown_Apply();

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 向前翻页
		TeamFrame_PageUp();

	elseif(3 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.



	elseif(5 == g_iTeamInfoType) then
		-- 向后翻页
		TeamFrame_PageDown_Apply();
	end


end

------------------------------------------------------------------------------------------------------------------
-- 按钮4点击事件
--
function Team_Button_Frame4_Click()


	if( 0 == g_iTeamInfoType) then
		-- 打开队伍信息
		local leader = Player:IsLeader();
		if( leader == 1 ) then
			local iTeamCount = DataPool:GetTeamMemberCount();

			if((-1 == g_iSel) or (0 == g_iSel))then


				-- 如果在界面上没有选择一个队员就返回
				-- 或者选中的是自己(队长), 也返回.

				return;
			end


			if( iTeamCount <= g_iSel) then


				return;
			end;


			-- 提升队长.
			-- Player:AppointLeader();
			Player:AppointLeader(g_iRealSelTeamMemberIndex);
			Team_Close();

		else
			Player:LeaveTeam();
			Team_Close();
		end

	elseif(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		DataPool:ClearAllApply();
		-- 设置下一次队长打开界面是查看队伍信息
		--DataPool:SetTeamFrameOpenFlag(3);
		g_iTeamInfoType = 0;
		Team_Close();


	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 向后翻页
		TeamFrame_PageDown();

	elseif(5 == g_iTeamInfoType) then
		Raid:ClearApplicant();
		Team_Close();
	end



end

------------------------------------------------------------------------------------------------------------------
-- 按钮5点击事件
--
function Team_Button_Frame5_Click()


	--if( 0 == g_iTeamInfoType or 3 == g_iTeamInfoType or 4 == g_iTeamInfoType ) then
		-- 打开组队平台
	--	OpenWindow("TeamPTWindow");
	--	this:Hide();

	--else
	if(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		if((-1 == g_iSel))then

			-- 如果在界面上没有选择一个队员就返回
			-- 或者选中的是自己(队长), 也返回.
			return;
		end

		-- 同意申请者加入队伍
		TeamFrame_AgreeJoinTeam_Apply();


	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 同意加入队伍
		TeamFrame_AgreeJoinTeam_Invite();
		Team_Close();

	elseif(3 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

	elseif(5 == g_iTeamInfoType) then
		if((-1 == g_iSel))then
			return;
		end
		TeamFrame_AgreeJoinRaid_Apply();
	end


end

------------------------------------------------------------------------------------------------------------------
-- 按钮6点击事件
--
function Team_Button_Frame6_Click()

	if( 0 == g_iTeamInfoType) then
		InviteTeamRide()
	elseif(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		-- 拒绝申请者加入队伍.
		TeamFrame_RejectJoinTeam_Apply();
		--DataPool:SetTeamFrameOpenFlag(3);
		if(g_iMemberCount_Apply <= 0) then

			g_iTeamInfoType = 0;
			Team_Close();
		end;

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		-- 拒绝加入队伍.
		TeamFrame_RejectJoinTeam_Invite();
		--DataPool:SetTeamFrameOpenFlag(0);
		if(g_iTeamCount_Invite <= 0) then

			g_iTeamInfoType = 4;
			Team_Close();
		end

	elseif(3 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.
		InviteTeamRide()
	elseif(4 == g_iTeamInfoType) then
		-- 非组队玩家打开界面
		Player:CreateTeamSelf();
		Team_Close();

	elseif(5 == g_iTeamInfoType) then
		-- 拒绝申请者加入团队.
		TeamFrame_RejectJoinRaid_Apply();
		if(g_iMemberCount_Apply <= 0) then
			Team_Close();
		end;
	end

end


------------------------------------------------------------------------------------------------------------------
-- 按钮7点击事件
--
function Team_Button_Frame7_Click()

	if( 0 == g_iTeamInfoType) then
		-- 0 : 打开队友信息对话框
		SendAddFriendMsg();

	elseif(1 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表

		DataPool:InviteApplyAddPingbi(1,g_iRealSelApplyIndex,1)--最后这个1为了凑够参数

	elseif(2 == g_iTeamInfoType) then
		-- 打开邀请对话框.

		DataPool:InviteApplyAddPingbi(2,g_iCurShowTeam_Invite,g_iRealSelInvitorIndexPingbi)

	elseif(3 == g_iTeamInfoType) then
		-- 队长打开队友信息对话框.

	elseif(4 == g_iTeamInfoType) then
		-- 非组队玩家打开界面

	elseif(5 == g_iTeamInfoType) then
		-- 队长打开申请加入队伍列表
		DataPool:InviteApplyAddPingbi(3,g_iRealSelApplyIndex,1)--最后这个1为了凑够参数
	end
end


------------------------------------------------------------------------------------------------------------------
-- 打开队伍信息
--
function TeamFrame_OpenTeamInfo()

		-- 清空ui界面
		ClearUIModel();

		-- 隐藏死亡标记
		HideDeadFlag();

		-- 隐藏掉线标记
		HideDeadLinkFlag();

		-- 隐藏队长标记
		ShwoLeaderFlat(0);


		g_iSel = -1;

		-- 设置对话框的操作类型
		g_iTeamInfoType = 0;
		g_iTeamInfoType  = 0;

		-- 显示正确的显示界面
		Team_Button_Frame0:Hide();
		Team_Button_Frame1:Hide();
		Team_Button_Frame2:Hide();
		Team_Button_Frame3:Hide();
		Team_Button_Frame4:Hide();
		Team_Button_Frame5:Hide();
		Team_Button_Frame6:Hide();
		Team_Button_Frame7:Hide();

		-- 设置按钮文字
		Team_Button_Frame4:Show();
		Team_Button_Frame7:Show();
		Team_Button_Frame6:Show();
		Team_Button_Frame4:Enable();
		Team_Button_Frame7:Enable();
		Team_Button_Frame6:Enable();
		Team_Button_Frame4:SetText("离开队伍");
		Team_Button_Frame7:SetText("加为好友");
		Team_Button_Frame6:SetText("#{DRCQ_100804_57}");
		Team_Button_Frame7:SetToolTip("");--这个界面不显示tooltips
		Team_Name:SetText("#gFF0FA0队伍信息");

		 --- KvK. K服里面屏蔽“组队平台”的显示
     --   if KVKInterface:IsInKVKServer() == 1 then
		 --   Team_Button_Frame5:Hide()
     --   else
    --		if (TeamFrame_CanOpenTeamBoard() == 1) then
	    --		Team_Button_Frame5:Show();
		  --  	Team_Button_Frame5:Enable();
    	--	    Team_Button_Frame5:SetText("#{ZDPT_XML_1}");
	    --	else
		  --  	Team_Button_Frame5:Show();
			--	Team_Button_Frame5:Disable();
			--	Team_Button_Frame5:SetText("#{ZDPT_XML_1}");
			--end
		--end
		if(CanInvite() == 1) then
			Team_Button_Frame6:Enable();
		else
            Team_Button_Frame6:Disable();
		end

		Team_Update_ExpMode( 0 );
		-- 当前队伍中队员的个数.
		g_iTeamMemberCount_Team = DataPool:GetTeamMemberCount();

		-- 如果队伍个数是零, 不显示界面.
		if(g_iTeamMemberCount_Team <= 0) then
			this:Hide();
			--Team_Close();

		end;

		-- 设置当前选择,
		g_iCurSel_Team = 0;

		-- 清空界面
		for i = 0, 5 do
			g_Team_PlayerInfo_Name[i]:SetText("");
			g_Team_PlayerInfo_School[i]:SetText("");
			g_Team_PlayerInfo_Level[i]:SetText("");
            g_Team_PlayerInfo_Server[i]:SetText("");
			g_Team_PlayerInfo_FightScore[i]:SetText("");

			g_Team_PlayerInfo_GuildName[i]:SetText("");
		end;

		-- 刷新每个队员.

		-- 显示队长标记
		if(g_iTeamMemberCount_Team > 0) then
			ShwoLeaderFlat(1);
		end;

		for i = 0, g_iTeamMemberCount_Team - 1 do

			TeamFrame_RefreshTeamMember_Team(i);

		end;
		Team_Show();
end


------------------------------------------------------------------------------------------------------------------
--
-- 非组队玩家打开界面
--
function TeamFrame_OpenCreateTeamSelf()

		-- 清空ui界面
		ClearUIModel();

		-- 隐藏死亡标记
		HideDeadFlag();

		-- 隐藏掉线标记
		HideDeadLinkFlag();

		-- 隐藏队长标记
		ShwoLeaderFlat(0);

		-- 显示正确的显示界面
		Team_Button_Frame0:Hide();
		Team_Button_Frame1:Hide();
		Team_Button_Frame2:Hide();
		Team_Button_Frame3:Hide();
		Team_Button_Frame4:Hide();
		Team_Button_Frame5:Hide()
		Team_Button_Frame6:Hide();
		Team_Button_Frame7:Hide();

		-- 设置按钮文字
		Team_Button_Frame6:Show();
		Team_Button_Frame6:Enable();
		Team_Button_Frame6:SetText("自建队伍");
		Team_Name:SetText("#gFF0FA0自建队伍");


		--- KvK. K服里面屏蔽“组队平台”的显示
    --    if KVKInterface:IsInKVKServer() == 1 then
		--    Team_Button_Frame5:Hide()
    --    else
		--    if (TeamFrame_CanOpenTeamBoard() == 1) then
		--	    Team_Button_Frame5:Show()
    --			Team_Button_Frame5:Enable();
	  --  		Team_Button_Frame5:SetText("#{ZDPT_XML_1}");
		--    else
		--		Team_Button_Frame5:Show();
    --			Team_Button_Frame5:Disable();
		--		Team_Button_Frame5:SetText("#{ZDPT_XML_1}");
		--	end
		--end
		-- 清空界面
		for i = 0, 5 do
			g_Team_PlayerInfo_Name[i]:SetText("");
			g_Team_PlayerInfo_School[i]:SetText("");
			g_Team_PlayerInfo_Level[i]:SetText("");
            g_Team_PlayerInfo_Server[i]:SetText("");
			g_Team_PlayerInfo_FightScore[i]:SetText("");

			g_Team_PlayerInfo_GuildName[i]:SetText("");
		end;

		SelectPos(0);
		Team_Show();
end


------------------------------------------------------------------------------------------------------------------
-- 打开申请列表
--
function TeamFrame_OpenApplyList()

	ShwoLeaderFlat(0);
	-- 清空ui界面
	ClearUIModel();
	-- 清空界面
	for i = 0, 5 do
		g_Team_PlayerInfo_Name[i]:SetText("");
		g_Team_PlayerInfo_School[i]:SetText("");
		g_Team_PlayerInfo_Level[i]:SetText("");
        g_Team_PlayerInfo_Server[i]:SetText("");
			g_Team_PlayerInfo_FightScore[i]:SetText("");

			g_Team_PlayerInfo_GuildName[i]:SetText("");
	end;

	HideDeadFlag();
	HideDeadLinkFlag();

	-- 设置对话框的操作类型
	g_iTeamInfoType  = 1;
	g_iTeamInfoType = 1;


	-- 显示正确的显示界面
	Team_Button_Frame0:Hide();
	Team_Button_Frame1:Hide();
	Team_Button_Frame2:Hide();
	Team_Button_Frame3:Hide();
	Team_Button_Frame4:Hide();
	Team_Button_Frame5:Hide();
	Team_Button_Frame6:Hide();
	Team_Button_Frame7:Hide();

	Team_Button_Frame1:Show();
	Team_Button_Frame2:Show();
	Team_Button_Frame3:Show();
	Team_Button_Frame4:Show();
	Team_Button_Frame5:Show();
	Team_Button_Frame6:Show();
	Team_Button_Frame7:Show();

	Team_Button_Frame2:Enable();
	Team_Button_Frame2:Disable();
	Team_Button_Frame3:Disable();
	Team_Button_Frame4:Disable();
	Team_Button_Frame5:Disable();
	Team_Button_Frame6:Disable();
	Team_Button_Frame7:Disable();

	Team_Button_Frame1:SetText("队伍信息");
	Team_Button_Frame2:SetText("上一页");
	Team_Button_Frame3:SetText("下一页");
	Team_Button_Frame4:SetText("清空列表");
	Team_Button_Frame5:SetText("同意申请");
	Team_Button_Frame6:SetText("拒绝申请");
	Team_Button_Frame7:SetText("屏蔽玩家");
	Team_Button_Frame7:SetToolTip("屏蔽该玩家");
	Team_Name:SetText("#gFF0FA0申请列表");


	-- 得到申请人的个数.
	g_iMemberCount_Apply = DataPool:GetApplyMemberCount();


	if(0 == g_iMemberCount_Apply) then
		this:Hide();
		return;
	end

	-- 设置当前显示的页面.
	g_iCurShowPage_Apply = 0;

	-- 设置当前选择的人物.
	g_iCurSel_Apply = 0;

	-- 刷新当前页面.
	TeamFrame_RefreshCurShowApplyPage_Apply(g_iCurShowPage_Apply);

	-- 从第0页开始.
	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);


	-- 禁止向后翻页
	if(g_iCurShowPage_Apply < iPageCount) then
		Team_Button_Frame3:Enable();
	end

	Team_Button_Frame4:Enable();
	Team_Button_Frame5:Enable();
	Team_Button_Frame6:Enable();
	Team_Button_Frame7:Enable();

	Team_Show();


end


------------------------------------------------------------------------------------------------------------------
-- 打开邀请信息
--
function TeamFrame_OpenInvite()

	--清空ui界面
	ClearUIModel();

	g_iSel = -1;

	-- 设置对话框的操作类型
	g_iTeamInfoType = 2;
	g_iTeamInfoType  = 2;

	-- 显示正确的显示界面
	Team_Button_Frame0:Hide();
	Team_Button_Frame1:Hide();
	Team_Button_Frame2:Hide();
	Team_Button_Frame3:Hide();
	Team_Button_Frame4:Hide();
	Team_Button_Frame5:Hide();
	Team_Button_Frame6:Hide();
	Team_Button_Frame7:Hide();

	Team_Button_Frame3:Show();
	Team_Button_Frame4:Show();
	Team_Button_Frame5:Show();
	Team_Button_Frame6:Show();
	Team_Button_Frame7:Show();

	Team_Button_Frame3:Enable();
	Team_Button_Frame4:Enable();
	Team_Button_Frame5:Enable();
	Team_Button_Frame6:Enable();
	Team_Button_Frame7:Enable();

	Team_Button_Frame3:SetText("上一页");
	Team_Button_Frame4:SetText("下一页");
	Team_Button_Frame5:SetText("同意邀请");
	Team_Button_Frame6:SetText("拒绝邀请");
	Team_Button_Frame7:SetText("#{ZDJB_161013_01}");
	Team_Button_Frame7:SetToolTip("#{ZDJB_161013_03}");
	Team_Name:SetText("#gFF0FA0邀请对话框");

	-- 得到邀请队伍的个数.
	g_iTeamCount_Invite   = DataPool:GetInviteTeamCount();
	if( g_iTeamCount_Invite == 0 ) then
		this:Hide();
		return;
	end
	-- 当前选择的人物
	g_iCurShowTeam_Invite = 0;

	-- 禁止向前翻页
	if(0 == g_iCurShowTeam_Invite) then
		Team_Button_Frame3:Disable();
	end

	-- 禁止向后翻页
	if(g_iCurShowTeam_Invite >= (g_iTeamCount_Invite - 1)) then
		Team_Button_Frame4:Disable();
	end

	-- 显示队伍信息
	TeamFrame_RefreshTeamInfo_Invite();

	if(0 == g_iTeamCount_Invite) then

		Team_Button_Frame5:Disable();
		Team_Button_Frame6:Disable();
	end;

	-- 隐藏队长标记
	ShwoLeaderFlat(1);
	Team_Show();
end


------------------------------------------------------------------------------------------------------------------
-- 打开队长队伍信息
--
function TeamFrame_OpenLeaderTeamInfo()

	-- 清空ui界面
	ClearUIModel();

	-- 隐藏死亡标记
	HideDeadFlag();

	-- 隐藏掉线标记
	HideDeadLinkFlag();

	-- 隐藏队长标记
	ShwoLeaderFlat(0);

	g_iSel = -1;

	-- 设置对话框的操作类型
	g_iTeamInfoType = 0;

	Team_Follow_Button:Show();

	-- 显示正确的显示界面
	Team_Button_Frame0:Show();
	Team_Button_Frame1:Show();
	Team_Button_Frame2:Show();
	Team_Button_Frame3:Show();
	Team_Button_Frame4:Show();
	Team_Button_Frame6:Show();
	Team_Button_Frame7:Show();

	Team_Button_Frame8:Show() --转为团队

	--这里一定要用GetApplyMemberCount而不能用g_iMemberCount_Apply做判断。清理列表之后 或者 接到申请不应答然后解散队伍在成立队伍 或者 接到申请不应答然后任命其他人为队长然后队长又任命回本人g_iMemberCount_Apply都不为0。
	if(DataPool:GetApplyMemberCount() > 0) then --by hukai#46895
		Team_Button_Frame0:Enable();
	else
		Team_Button_Frame0:Disable();
	end
	Team_Button_Frame1:Enable();
	Team_Button_Frame2:Enable();
	if( g_iSel == -1 ) then
		Team_Button_Frame3:Disable();
	else
		Team_Button_Frame3:Enable();
	end
	Team_Button_Frame4:Enable();
	Team_Button_Frame7:Enable();

	Team_Button_Frame0:SetText("申请列表");
	Team_Button_Frame1:SetText("解散队伍");
	Team_Button_Frame2:SetText("离开队伍");
	Team_Button_Frame3:SetText("请离队伍");
	Team_Button_Frame4:SetText("任命队长");
	Team_Button_Frame6:SetText("#{DRCQ_100804_57}");
	Team_Button_Frame7:SetText("加为好友");
	Team_Button_Frame7:SetToolTip("");--这个界面不显示tooltips
	Team_Name:SetText("#gFF0FA0队伍信息");

	--- KvK. K服里面屏蔽“组队平台”的显示
  --  if KVKInterface:IsInKVKServer() == 1 then
	    Team_Button_Frame5:Hide()
  --  else
  --  	if(TeamFrame_CanOpenTeamBoard() == 1) then
	--    	Team_Button_Frame5:Show();
	--	    Team_Button_Frame5:Enable();
  --  		Team_Button_Frame5:SetText("#{ZDPT_XML_1}");
	--    else
	--	    Team_Button_Frame5:Show();
	--		Team_Button_Frame5:Disable();
	--		Team_Button_Frame5:SetText("#{ZDPT_XML_1}");
	--	end
	--end
	--如果拥有坐骑且还没有坐满
	if(CanInvite() == 1) then
		Team_Button_Frame6:Enable();
	else
		Team_Button_Frame6:Disable();
	end

	Team_Update_ExpMode( 1 );
	-- 当前队伍中队员的个数.
	g_iTeamMemberCount_Team = DataPool:GetTeamMemberCount();
	if( g_iTeamMemberCount_Team <= 0 ) then
		this:Hide();
		return;
	end;
	-- 设置当前选择,
	g_iCurSel_Team = 0;

	-- 清空界面
	for i = 0, 5 do
		g_Team_PlayerInfo_Name[i]:SetText("");
		g_Team_PlayerInfo_School[i]:SetText("");
		g_Team_PlayerInfo_Level[i]:SetText("");
        g_Team_PlayerInfo_Server[i]:SetText("");
			g_Team_PlayerInfo_FightScore[i]:SetText("");

			g_Team_PlayerInfo_GuildName[i]:SetText("");
	end;

	-- 显示队长标记
	if(g_iTeamMemberCount_Team > 0) then
		ShwoLeaderFlat(1);
	end;

	-- 刷新每个队员.
	for i = 0, g_iTeamMemberCount_Team - 1 do

		TeamFrame_RefreshTeamMember_Team(i);

	end;

	-- 选择第一个
	SelectPos(0);
	Team_Show();
end



------------------------------------------------------------------------------------------------------------------
-- 打开邀请队伍信息
--
function TeamFrame_RefreshTeamInfo_Invite()

	for i = 0, 5 do
			g_Team_PlayerInfo_Name[i]:SetText("");
			g_Team_PlayerInfo_School[i]:SetText("");
			g_Team_PlayerInfo_Level[i]:SetText("");
            g_Team_PlayerInfo_Server[i]:SetText("");
			g_Team_PlayerInfo_FightScore[i]:SetText("");

			g_Team_PlayerInfo_GuildName[i]:SetText("");
	end

	-- 得到队友的个数
	if(-1 == g_iCurShowTeam_Invite) then

		return;
	end

	local iTeamMemberCount = DataPool:GetInviteTeamMemberCount(g_iCurShowTeam_Invite);

	for MemberIndex = 0, iTeamMemberCount - 1 do
		-- 显示一个队员
		--ShwoLeaderFlat(1);
		TeamFrame_RefreshTeamMember_Invite(MemberIndex);
	end


end



-------------------------------------------------------------------------------------------------------------------
-- 刷新某一个队员的信息, 打开界面.
--
function TeamFrame_RefreshTeamMember_Invite(index)

		local szNick;		-- 昵称
		local iFamily;	-- 门派
		local iLevel;	  -- 等级
		local iCapID;		-- 帽子
		local iHead;		-- 头
		local iArmourID;-- 身子
		local iCuffID;  -- 护腕
		local iFootID;	-- 腿
		local iWeaponID;-- 武器
        local sZoneWorldID          --- 服务器ID
		local iFightScore
		local szGuildName

		-- 得到队员的详细信息
		szNick
		,iFamily
		,iLevel
		,iCapID
		,iHead
		,iArmourID
		,iCuffID
		,iFootID
		,iWeaponID
        ,_                  --- 这里是性别，不需要，所以不获取
        ,sZoneWorldID
		,iFightScore
		,szGuildName
		= DataPool:GetInviteTeamMemberInfo( g_iCurShowTeam_Invite, index );


		g_Team_PlayerInfo_Name[index]:SetText(tostring(szNick));
		g_Team_PlayerInfo_School[index]:SetText(tostring(iFamily));
		g_Team_PlayerInfo_Level[index]:SetText(tostring(iLevel));

		g_Team_PlayerInfo_FightScore[index]:SetText("#{BHXX_160531_3}"..tostring(iFightScore));

		if szGuildName == nil or szGuildName == "" then
			g_Team_PlayerInfo_GuildName[index]:SetText("#{BHXX_160531_1}".."#{GMGameInterface_Script_DataPool_Info_None}")
		else
			g_Team_PlayerInfo_GuildName[index]:SetText("#{BHXX_160531_1}"..tostring(szGuildName))
		end


		local strModelName = DataPool:GetInviteTeamMemberUIModelName( g_iCurShowTeam_Invite, index);

		-- 显示门派信息
		ShowFamily(index, iFamily);

        --- 显示服务器名
        TeamFrame_ShowServerName( index, sZoneWorldID )

		-- 显示模型

		g_TeamFrame_FakeObject[index]:SetFakeObject("");
		g_TeamFrame_FakeObject[index]:SetFakeObject(strModelName);

end



-------------------------------------------------------------------------------------------------------------------
-- 打开队伍邀请界面向前翻页
--
function TeamFrame_PageUp()

	-- 向前翻一页
	g_iCurShowTeam_Invite = g_iCurShowTeam_Invite - 1;
	if(g_iCurShowTeam_Invite < 0) then
		g_iCurShowTeam_Invite = 0;
	end



	-- 禁止向前翻页
	if(0 == g_iCurShowTeam_Invite) then
		Team_Button_Frame3:Disable();
	end

	-- 禁止向后翻页
	if(g_iCurShowTeam_Invite < (g_iTeamCount_Invite - 1)) then
		Team_Button_Frame4:Enable();
	end


	-- 设置当前选中的队伍.
	g_iRealSelInvitorIndex = g_iCurShowTeam_Invite;

	ClearUIModel();
	-- 刷新当前界面
	TeamFrame_RefreshTeamInfo_Invite();

end



-------------------------------------------------------------------------------------------------------------------
-- 打开队伍邀请界面向后翻页
--
function TeamFrame_PageDown()

	-- 向后翻一页
	g_iCurShowTeam_Invite = g_iCurShowTeam_Invite + 1;
	if(g_iCurShowTeam_Invite >=  (g_iTeamCount_Invite - 1)) then
		g_iCurShowTeam_Invite = g_iCurShowTeam_Invite;
	end

	-- 禁止向后翻页
	if(g_iCurShowTeam_Invite >= (g_iTeamCount_Invite - 1)) then
		Team_Button_Frame4:Disable();
	end

	-- 允许前翻
	if(g_iCurShowTeam_Invite > 0) then
		Team_Button_Frame3:Enable();
	end

	-- 设置当前选中的队伍索引.
	g_iRealSelInvitorIndex = g_iCurShowTeam_Invite;
	ClearUIModel();
	-- 刷新当前界面
	TeamFrame_RefreshTeamInfo_Invite();

end



-------------------------------------------------------------------------------------------------------------------
-- 队伍邀请拒绝加入队伍
--
function TeamFrame_RejectJoinTeam_Invite()


		-- 没有邀请队伍返回
		if(0 == g_iTeamCount_Invite) then

			return;
		end;

		-- 发送拒绝加入队伍消息.
		-- Player:RejectJoinTeam();

		Player:RejectJoinTeam(g_iRealSelInvitorIndex);

		g_iTeamCount_Invite = g_iTeamCount_Invite - 1;

		if(g_iTeamCount_Invite <= 0) then

			-- 关闭界面
			Team_Close();
			return;
		end

		--
		if(g_iCurShowTeam_Invite >= (g_iTeamCount_Invite - 1)) then

			g_iCurShowTeam_Invite = g_iTeamCount_Invite - 1;
		end

		-- 设置当前选择的队伍。
		g_iRealSelInvitorIndex = g_iCurShowTeam_Invite;
		-- 禁止向前翻页
		if(0 == g_iCurShowTeam_Invite) then

			Team_Button_Frame3:Disable();

		else

			Team_Button_Frame3:Enable();

		end


		-- 禁止向后翻页
		if(g_iCurShowTeam_Invite >= (g_iTeamCount_Invite - 1)) then

			Team_Button_Frame4:Disable();

		else

			Team_Button_Frame4:Enable();

		end

		-- 显示队伍信息
		TeamFrame_RefreshTeamInfo_Invite();


end


-------------------------------------------------------------------------------------------------------------------
-- 队伍邀请界面同意加入队伍
--
function TeamFrame_AgreeJoinTeam_Invite()


		-- 没有邀请队伍返回

		if(0 == g_iTeamCount_Invite) then

			return;
		end;

		-- 同意加入队伍
		-- Player:AgreeJoinTeam();

		Player:AgreeJoinTeam(g_iRealSelInvitorIndex);

		-- 关闭界面, 下一次打开是自建队伍.
		g_iTeamInfoType = 4;

		-- 隐藏界面
		Team_Close();
		CloseWindow("UnionChoose", true)
end



--------------------------------------------------------------------------------------------------------------------
-- 关闭窗口事件
--
function TeamFrame_CloseWindow()

	if( g_iTeamInfoType == 1 ) then
		TeamFrame_RejectJoinTeam_Apply();
	elseif(g_iTeamInfoType == 2) then
		TeamFrame_RejectJoinTeam_Invite();
	elseif(5 == g_iTeamInfoType) then
		TeamFrame_RejectJoinRaid_Apply()
	end

	Team_Close();


end



--------------------------------------------------------------------------------------------------------------------
-- 刷新队员信息, 打开普通界面信息
--
function TeamFrame_RefreshTeamMember_Team(index)

	local szNick;		-- 昵称
	local iFamily;	-- 门派
	local iLevel;	  -- 等级
	--local iCapID;		-- 帽子
	--local iHead;		-- 头
	--local iArmourID;-- 身子
	--local iCuffID;  -- 护腕
	--local iFootID;	-- 腿
	--local iWeaponID;-- 武器
	local bDeadlink;
	local bDead;
	local bSex;
    local sZoneWorldID  --- 服务器名
	local iFightScore
	local szGuildName

	-- 得到队员的详细信息
	szNick
	,iFamily
	,iLevel
	--,iCapID
	--,iHead
	--,iArmourID
	--,iCuffID
	--,iFootID
	--,iWeaponID
	,bDead
	,bDeadlink
	,bSex
    ,sZoneWorldID
	,iFightScore
	,szGuildName
	= DataPool:GetTeamMemInfoByIndex( index );


	g_Team_PlayerInfo_Name[index]:SetText(tostring(szNick));
	g_Team_PlayerInfo_School[index]:SetText(tostring(iFamily));
	g_Team_PlayerInfo_Level[index]:SetText(tostring(iLevel));
	g_Team_PlayerInfo_FightScore[index]:SetText("#{BHXX_160531_3}"..tostring(iFightScore));

		if szGuildName == nil or szGuildName == "" then
			g_Team_PlayerInfo_GuildName[index]:SetText("#{BHXX_160531_1}".."#{GMGameInterface_Script_DataPool_Info_None}")
		else
			g_Team_PlayerInfo_GuildName[index]:SetText("#{BHXX_160531_1}"..tostring(szGuildName))
		end



	if(bDead > 0) then
		g_Team_PlayerInfo_Dead[index]:Show();
	end;

	if(bDeadlink > 0) then
		-- 掉线标记
		g_Team_PlayerInfo_Deadlink[index]:Show();
	end;

	-- 显示门派信息
	ShowFamily(index, iFamily);

    --- 显示服务器名
    TeamFrame_ShowServerName( index, sZoneWorldID )

	if (g_bUpdateTeamFakeObj == 1) then
		-- 得到ui模型信息
		local strModelName = DataPool:GetTeamMemUIModelName(index);


		-- 显示模型
		g_TeamFrame_FakeObject[index]:SetFakeObject(strModelName);

	end

	local bIsInScene = DataPool:IsTeamMemberInScene(index);
	if(0 == bIsInScene) then


		g_Team_Ui_Model_Disable[index]:Show();
	else


		g_Team_Ui_Model_Disable[index]:Hide();
	end;

end



--------------------------------------------------------------------------------------------------------------------
-- 刷新当前页面信息, 打开申请界面
--
function TeamFrame_RefreshCurShowApplyPage_Apply(index)

	ClearUIModel();

	ShwoLeaderFlat(0);
	-- 清空旧的界面.
	for iUI = 0, 5 do
			g_Team_PlayerInfo_Name[iUI]:SetText("");
			g_Team_PlayerInfo_School[iUI]:SetText("");
			g_Team_PlayerInfo_Level[iUI]:SetText("");
            g_Team_PlayerInfo_Server[iUI]:SetText("");
			g_Team_PlayerInfo_FightScore[iUI]:SetText("");

			g_Team_PlayerInfo_GuildName[iUI]:SetText("");
	end

	if(g_iMemberCount_Apply <= 0) then

		-- 加入申请者的个数小于等于0 , 不刷新界卖弄
		return;

	end


	-- 队员信息.
	local szNick;		-- 昵称
	local iFamily;	-- 门派
	local iLevel;	  -- 等级
	local iCapID;		-- 帽子
	local iHead;		-- 头
	local iArmourID;-- 身子
	local iCuffID;  -- 护腕
	local iFootID;	-- 腿
	local iWeaponID;-- 武器
    local sZoneWorldID      --- 服务器ID
	local iFightScore
	local szGuildName


	local iCurShowStart = index * g_iCurPageShowCount;
	local iCurShowEnd   = iCurShowStart + g_iCurPageShowCount;
	local iUIIndex = 0;

	if(iCurShowEnd > g_iMemberCount_Apply) then

		iCurShowEnd = g_iMemberCount_Apply;
	end;

	for i = iCurShowStart, iCurShowEnd - 1 do

		-- 刷新当前界面的每一个申请者信息.

		-- 得到队员的详细信息
		szNick
		,iFamily
		,iLevel
		,iCapID
		,iHead
		,iArmourID
		,iCuffID
		,iFootID
		,iWeaponID
        ,_
        ,sZoneWorldID
		,iFightScore
		,szGuildName
		= DataPool:GetApplyMemberInfo(i);

		g_Team_PlayerInfo_Name[iUIIndex]:SetText(tostring(szNick));
		g_Team_PlayerInfo_School[iUIIndex]:SetText(tostring(iFamily));
		g_Team_PlayerInfo_Level[iUIIndex]:SetText(tostring(iLevel));
		g_Team_PlayerInfo_FightScore[iUIIndex]:SetText("#{BHXX_160531_3}"..tostring(iFightScore));

		if szGuildName == nil or szGuildName == "" then
			g_Team_PlayerInfo_GuildName[iUIIndex]:SetText("#{BHXX_160531_1}".."#{GMGameInterface_Script_DataPool_Info_None}")
		else
			g_Team_PlayerInfo_GuildName[iUIIndex]:SetText("#{BHXX_160531_1}"..tostring(szGuildName))
		end
		-- 显示门派信息
		ShowFamily(iUIIndex, iFamily);

        --- 显示服务器信息
        TeamFrame_ShowServerName( iUIIndex, sZoneWorldID )

		-- 得到ui模型信息
		local strModelName = DataPool:GetApplyMemberUIModelName(i);

		-- 显示模型
		g_TeamFrame_FakeObject[iUIIndex]:SetFakeObject(strModelName);

		iUIIndex = iUIIndex + 1;

	end

	SelectPos(0);

end



--------------------------------------------------------------------------------------------------------------------
-- 打开申请界面, 选择一个申请者
--
function TeamFrame_SetCurSelectedApply_Apply(index)

	if(0 == g_iMemberCount_Apply) then

		--如果没有申请者, 返回.
		return;
	end

	-- 转换当前实际选择的申请者.
	local iCurSelApply = g_iCurShowPage_Apply * g_iCurPageShowCount + index;

	-- 索引超过队员个数返回.
	--if(iCurSelApply >= g_iMemberCount_Apply) then

	--	return;
	--end;

	-- 设置选中申请者
	-- 实际索引, 不是界面索引
	g_iRealSelApplyIndex = iCurSelApply;
	--DataPool:SetCurSelApply(iCurSelApply);
	g_iCurSelApply_Apply = iCurSelApply;

end


--------------------------------------------------------------------------------------------------------------------
-- 打开申请界面, 同意加入队伍
--
function TeamFrame_AgreeJoinTeam_Apply(index)

	if(g_iCurSelApply_Apply >= g_iMemberCount_Apply) then

		return;
	end
	-- 同意加入队伍
	--Player:SendAgreeJoinTeam_Apply();
	Player:SendAgreeJoinTeam_Apply(g_iRealSelApplyIndex);

	g_iMemberCount_Apply = g_iMemberCount_Apply - 1;

	if(g_iMemberCount_Apply <= 0) then

		Team_Close();
		-- 下次打开界面是队长看到的队伍信息
		--DataPool:SetTeamFrameOpenFlag(3);
		g_iTeamInfoType = 0;
	end

	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);

	if(g_iCurShowPage_Apply >= iPageCount) then

		-- 设置新的显示页
		g_iCurShowPage_Apply = iPageCount;

	end;

	-- 删除一个申请者
	DataPool:EraseApply(g_iCurSelApply_Apply);
	-- 刷新新的申请界面
	TeamFrame_RefreshCurShowApplyPage_Apply(g_iCurShowPage_Apply);

end


--------------------------------------------------------------------------------------------------------------------
-- 打开申请界面, 拒绝加入队伍
--
function TeamFrame_RejectJoinTeam_Apply(index)

	if(g_iCurSelApply_Apply >= g_iMemberCount_Apply) then

		return;
	end
	-- 发送拒绝加入队伍消息.
	--Player:SendRejectJoinTeam_Apply();
	Player:SendRejectJoinTeam_Apply(g_iRealSelApplyIndex);

	g_iMemberCount_Apply = g_iMemberCount_Apply - 1;

	if(g_iMemberCount_Apply <= 0) then

		Team_Close();
		-- 下次打开界面是队长看到的队伍信息
		--DataPool:SetTeamFrameOpenFlag(3);
		g_iTeamInfoType = 0;
	end

	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);

	if(g_iCurShowPage_Apply >= iPageCount) then

		-- 设置新的显示页
		g_iCurShowPage_Apply = iPageCount;

	end;

	-- 删除一个申请者
	DataPool:EraseApply(g_iCurSelApply_Apply);
	-- 刷新新的申请界面
	TeamFrame_RefreshCurShowApplyPage_Apply(g_iCurShowPage_Apply);
	Team_Show();
end



-------------------------------------------------------------------------------------------------------------------
-- 打开队伍邀请界面向前翻页
--
function TeamFrame_PageUp_Apply()

	-- 从第0页开始.
	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);


	-- 向前翻一页
	g_iCurShowPage_Apply = g_iCurShowPage_Apply - 1;
	if(g_iCurShowPage_Apply < 0) then
		g_iCurShowPage_Apply = 0;
	end

	-- 禁止向前翻页
	--if(0 == g_iCurShowTeam_Invite) then
	if(0 == g_iCurShowPage_Apply) then
		Team_Button_Frame2:Disable();
	end

	-- 禁止向后翻页
	if(g_iCurShowPage_Apply < iPageCount) then
		Team_Button_Frame3:Enable();
	end


	ClearUIModel();
	-- 刷新当前界面
	if Player:IsInRaid() == 1 then
		TeamFrame_RefreshCurShowApplyPage_RaidApply(g_iCurShowPage_Apply)
	else
		TeamFrame_RefreshCurShowApplyPage_Apply(g_iCurShowPage_Apply);
	end

end



-------------------------------------------------------------------------------------------------------------------
-- 打开队伍邀请界面向后翻页
--
function TeamFrame_PageDown_Apply()

	-- 从第0页开始.
	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);


	-- 向后翻一页
	g_iCurShowPage_Apply = g_iCurShowPage_Apply + 1;
	if(g_iCurShowPage_Apply >=  iPageCount ) then

		g_iCurShowPage_Apply = iPageCount;
	end

	-- 禁止向后翻页
	if(g_iCurShowPage_Apply >= iPageCount) then
		Team_Button_Frame3:Disable();
	end

	-- 允许前翻
	if(g_iCurShowPage_Apply > 0) then
		Team_Button_Frame2:Enable();
	end

	ClearUIModel();
	-- 刷新当前界面
	if Player:IsInRaid() == 1 then
		TeamFrame_RefreshCurShowApplyPage_RaidApply(g_iCurShowPage_Apply)
	else
		TeamFrame_RefreshCurShowApplyPage_Apply(g_iCurShowPage_Apply);
	end

end


--------------------------------------------------------------------------------------------------------------------
--
-- 清空ui界面
--
function ClearUIModel()

	g_TeamFrame_FakeObject[0]:SetFakeObject("");
	g_TeamFrame_FakeObject[1]:SetFakeObject("");
	g_TeamFrame_FakeObject[2]:SetFakeObject("");
	g_TeamFrame_FakeObject[3]:SetFakeObject("");
	g_TeamFrame_FakeObject[4]:SetFakeObject("");
	g_TeamFrame_FakeObject[5]:SetFakeObject("");

	HideUIModelDisable();
end;


--------------------------------------------------------------------------------------------------------------------
--
-- 显示门派
--
function ShowFamily(MemIndex, Family)

	local strName = "无门派";

	-- 得到门派名称.
	if(0 == Family) then
		strName = "少林";

	elseif(1 == Family) then
		strName = "明教";

	elseif(2 == Family) then
		strName = "丐帮";

	elseif(3 == Family) then
		strName = "武当";

	elseif(4 == Family) then
		strName = "峨嵋";

	elseif(5 == Family) then
		strName = "星宿";

	elseif(6 == Family) then
		strName = "天龙";

	elseif(7 == Family) then
		strName = "天山";

	elseif(8 == Family) then
		strName = "逍遥";

	elseif(9 == Family) then
		strName = "无门派";

	elseif(10== Family) then
		strName = "慕容";

	elseif(11== Family) then
		strName = "唐门";

	elseif(12== Family) then
		strName = "鬼谷";
		
	elseif(13== Family) then
		strName = "桃花岛";
		
	elseif(14== Family) then
		strName = "绝情谷";
	
	elseif(15== Family) then--menpai15 mptodo
		strName = "恶人谷";
	end

	-- 设置显示的门派.
	g_Team_PlayerInfo_School[MemIndex]:SetText(strName);

end;

--------------------------------------------------------------------------------------------------------------------
--
-- 显示服务器名
--
function TeamFrame_ShowServerName(MemIndex, ZoneWorldID )

    local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
    local strName = ""
    --- 只有自己的ZoneWorldID与传进来的参数不一致的时候，才需要显示服务器名
    if selfZoneWorldID ~= nil and selfZoneWorldID ~= -1 and ZoneWorldID ~=0 and ZoneWorldID ~= -1 and selfZoneWorldID ~= ZoneWorldID then
        --- 得到服务器名称
        strName = "#{KVKGZ_110620_06} "..DataPool:GetServerName( ZoneWorldID )
    end

	--- 设置显示的服务器名.
    g_Team_PlayerInfo_Server[MemIndex]:SetText( strName )

end

function HideDeadFlag()

	-- 死亡标记
	g_Team_PlayerInfo_Dead[0]:Hide();
	g_Team_PlayerInfo_Dead[1]:Hide();
	g_Team_PlayerInfo_Dead[2]:Hide();
	g_Team_PlayerInfo_Dead[3]:Hide();
	g_Team_PlayerInfo_Dead[4]:Hide();
	g_Team_PlayerInfo_Dead[5]:Hide();

end;

function HideDeadLinkFlag()

	-- 掉线标记
	g_Team_PlayerInfo_Deadlink[0]:Hide();
	g_Team_PlayerInfo_Deadlink[1]:Hide();
	g_Team_PlayerInfo_Deadlink[2]:Hide();
	g_Team_PlayerInfo_Deadlink[3]:Hide();
	g_Team_PlayerInfo_Deadlink[4]:Hide();
	g_Team_PlayerInfo_Deadlink[5]:Hide();

end;

function ShwoLeaderFlat(bShow)

	if(0 == bShow) then

		Team_Captain_Icon:Hide();
	else

		Team_Captain_Icon:Show();
	end;

end;

function Team_Button_Abort_Team_Follow_Click()
	Player:StopFollow();
	Team_AbortTeamFollow_Button:Hide();
end

--每次打开界面选中
function SelectPos(index)

		if(0 == index) then
			TeamFrame_Select1();
			Team_Model_1:SetCheck(1);
			Team_Model_2:SetCheck(0);
			Team_Model_3:SetCheck(0);
			Team_Model_4:SetCheck(0);
			Team_Model_5:SetCheck(0);
			Team_Model_6:SetCheck(0);
			return
		end;

		if(1 == index) then
			TeamFrame_Select2();
			Team_Model_1:SetCheck(0);
			Team_Model_2:SetCheck(1);
			Team_Model_3:SetCheck(0);
			Team_Model_4:SetCheck(0);
			Team_Model_5:SetCheck(0);
			Team_Model_6:SetCheck(0);
			return
		end;

		if(2 == index) then
			TeamFrame_Select3();
			Team_Model_1:SetCheck(0);
			Team_Model_2:SetCheck(0);
			Team_Model_3:SetCheck(1);
			Team_Model_4:SetCheck(0);
			Team_Model_5:SetCheck(0);
			Team_Model_6:SetCheck(0);
			return
		end;

		if(3 == index) then
			TeamFrame_Select4();
			Team_Model_1:SetCheck(0);
			Team_Model_2:SetCheck(0);
			Team_Model_3:SetCheck(0);
			Team_Model_4:SetCheck(3);
			Team_Model_5:SetCheck(0);
			Team_Model_6:SetCheck(0);
			return
		end;

		if(4 == index) then
			TeamFrame_Select5();
			Team_Model_1:SetCheck(0);
			Team_Model_2:SetCheck(0);
			Team_Model_3:SetCheck(0);
			Team_Model_4:SetCheck(0);
			Team_Model_5:SetCheck(1);
			Team_Model_6:SetCheck(0);
			return
		end;

		if(5 == index) then
			TeamFrame_Select6();
			Team_Model_1:SetCheck(0);
			Team_Model_2:SetCheck(0);
			Team_Model_3:SetCheck(0);
			Team_Model_4:SetCheck(0);
			Team_Model_5:SetCheck(0);
			Team_Model_6:SetCheck(1);
			return
		end;


end


function ClearInfo()

	ShwoLeaderFlat(0);
	HideDeadFlag();
	HideDeadLinkFlag();

	-- 清空旧的界面.
	for iUI = 0, 5 do
			g_Team_PlayerInfo_Name[iUI]:SetText("");
			g_Team_PlayerInfo_School[iUI]:SetText("");
			g_Team_PlayerInfo_Level[iUI]:SetText("");
            g_Team_PlayerInfo_Server[iUI]:SetText("")
			g_Team_PlayerInfo_FightScore[iUI]:SetText("");

			g_Team_PlayerInfo_GuildName[iUI]:SetText("");
	end

end;

function RefreshUIModel()
	-- 当前队伍中队员的个数.
	g_iTeamMemberCount_Team = DataPool:GetTeamMemberCount();
	if( g_iTeamMemberCount_Team <= 0 ) then
		return;
	end
	ClearUIModel();
	-- 刷新每个队员.
	for i = 0, g_iTeamMemberCount_Team - 1 do

		-- 得到ui模型信息
		local strModelName = DataPool:GetTeamMemUIModelName(i);

		-- 显示模型
		g_TeamFrame_FakeObject[i]:SetFakeObject(strModelName);
	end;

end;


----------------------------------------------------------------------------------------
--
-- 隐藏模型.
--
function HideUIModelDisable()

	g_Team_Ui_Model_Disable[0]:Hide();
	g_Team_Ui_Model_Disable[1]:Hide();
	g_Team_Ui_Model_Disable[2]:Hide();
	g_Team_Ui_Model_Disable[3]:Hide();
	g_Team_Ui_Model_Disable[4]:Hide();
	g_Team_Ui_Model_Disable[5]:Hide();

end;


-----------------------------------------------------------------------------------------
--
-- 发送加为好友消息
--
function SendAddFriendMsg()

		local iName,zoneworldid = Player:GetTeamMemberName(g_iSel);

		if(iName == "") then
			return;
		end

		DataPool:AddFriendAndGrouping(iName,zoneworldid);
end;

function Team_ExpMode_change()
	local mode, nIndex = Team_Exp_Mode:GetCurrentSelect();
	DataPool:SetTeamExpMode(nIndex);
end


function Team_Update_ExpMode( isTeam )
	if( tonumber( isTeam ) == -1 ) then
		Team_Exp_Mode:Hide();
		Team_Exp_Mode_Text:Hide();
		return
	end
	local expMode = DataPool:GetTeamExpMode();

	local isLeader = Player:IsLeader();

	if( tonumber( isLeader ) == 0 ) then --不是队长
		if( expMode == 0 ) then
			Team_Exp_Mode_Text:SetText( "平均分配" );
		else
			Team_Exp_Mode_Text:SetText( "驯兽模式" );
		end
		Team_Exp_Mode_Text:Show();
		Team_Exp_Mode:Hide();
	else
		Team_Exp_Mode:SetCurrentSelect( expMode );
		Team_Exp_Mode_Text:Hide();
		Team_Exp_Mode:Show();
	end
end


function Team_Close()

	if( g_iTeamInfoType == 1 ) then
		g_iTeamInfoType = 0;
	elseif (g_iTeamInfoType == 2) then
		if(g_iTeamCount_Invite <= 0) then                 --这样写是为了避免同时接到多个邀请。
			g_iTeamInfoType = 4;
		end
	end

	this:Hide();
end

function Team_Show()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	this:Show();
end

-- 确认解散队伍
-- add by WTT		20090212
function Team_Confirm_Dismiss_Team ()

	Player:DismissTeam();						-- 解散队伍
	Team_Close();										-- 关闭组队窗口

end

--是否能使用组队平台
function TeamFrame_CanOpenTeamBoard()
	local level = Player:GetData("LEVEL");
	if level < 10 then
		return 0;
	end
	return 1;
end


function TeamFrame_OpenRaidApplyList()

	ShwoLeaderFlat(0);
	-- 清空ui界面
	ClearUIModel();
	-- 清空界面
	for i = 0, 5 do
		g_Team_PlayerInfo_Name[i]:SetText("");
		g_Team_PlayerInfo_School[i]:SetText("");
		g_Team_PlayerInfo_Level[i]:SetText("");
        g_Team_PlayerInfo_Server[i]:SetText("")
			g_Team_PlayerInfo_FightScore[i]:SetText("");

			g_Team_PlayerInfo_GuildName[i]:SetText("");
	end;

	-- 设置对话框的操作类型
	g_iTeamInfoType  = 5;

	-- 显示正确的显示界面
	Team_Button_Frame0:Hide();
	Team_Button_Frame1:Hide();
	Team_Button_Frame2:Hide();
	Team_Button_Frame3:Hide();
	Team_Button_Frame4:Hide();
	Team_Button_Frame5:Hide();
	Team_Button_Frame6:Hide();
	Team_Button_Frame7:Hide();
	Team_Button_Frame8:Hide();

	Team_Button_Frame1:Show();
	Team_Button_Frame2:Show();
	Team_Button_Frame3:Show();
	Team_Button_Frame4:Show();
	Team_Button_Frame5:Show();
	Team_Button_Frame6:Show();
	Team_Button_Frame7:Show();

	Team_Button_Frame2:Enable();
	Team_Button_Frame2:Disable();
	Team_Button_Frame3:Disable();
	Team_Button_Frame4:Disable();
	Team_Button_Frame5:Disable();
	Team_Button_Frame6:Disable();
	Team_Button_Frame7:Disable();

	Team_Button_Frame1:SetText("团队信息");
	Team_Button_Frame2:SetText("上一页");
	Team_Button_Frame3:SetText("下一页");
	Team_Button_Frame4:SetText("清空列表");
	Team_Button_Frame5:SetText("同意申请");
	Team_Button_Frame6:SetText("拒绝申请");
	Team_Button_Frame7:SetText("屏蔽玩家");
	Team_Button_Frame7:SetToolTip("屏蔽该玩家");
	Team_Name:SetText("#gFF0FA0申请列表");


	-- 得到申请人的个数.
	g_iMemberCount_Apply = Raid:GetApplicantCount();

	if(0 == g_iMemberCount_Apply) then
		this:Hide();
		return;
	end

	-- 设置当前显示的页面.
	g_iCurShowPage_Apply = 0;

	-- 设置当前选择的人物.
	g_iCurSel_Apply = 0;

	TeamFrame_RefreshCurShowApplyPage_RaidApply(g_iCurShowPage_Apply);

	-- 从第0页开始.
	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);


	-- 禁止向后翻页
	if(g_iCurShowPage_Apply < iPageCount) then
		Team_Button_Frame3:Enable();
	end

	Team_Button_Frame4:Enable();
	Team_Button_Frame5:Enable();
	Team_Button_Frame6:Enable();
	Team_Button_Frame7:Enable();

	Team_Show();
end


function TeamFrame_AgreeJoinRaid_Apply()

	if(g_iCurSelApply_Apply >= g_iMemberCount_Apply) then

		return;
	end

	Player:SendAgreeRaidApplication(g_iRealSelApplyIndex);

	g_iMemberCount_Apply = g_iMemberCount_Apply - 1;

	if(g_iMemberCount_Apply <= 0) then
		Team_Close();
		g_iTeamInfoType = 4;
	end

	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);

	if(g_iCurShowPage_Apply >= iPageCount) then

		-- 设置新的显示页
		g_iCurShowPage_Apply = iPageCount;

	end;

	-- 删除一个申请者
	--Raid:EraseApplicantByIdx(g_iCurSelApply_Apply);
	TeamFrame_RefreshCurShowApplyPage_RaidApply(g_iCurShowPage_Apply);

end

function TeamFrame_RejectJoinRaid_Apply()
	if(g_iCurSelApply_Apply >= g_iMemberCount_Apply) then
		return;
	end
	Player:SendOpposeRaidApplication(g_iRealSelApplyIndex);

	g_iMemberCount_Apply = g_iMemberCount_Apply - 1;
	if(g_iMemberCount_Apply <= 0) then
		Team_Close();
		g_iTeamInfoType = 4;
	end

	local iPageCount = 0;
	iPageCount = (g_iMemberCount_Apply - 1) / g_iCurPageShowCount;
	iPageCount = math.floor(iPageCount);

	if(g_iCurShowPage_Apply >= iPageCount) then
		-- 设置新的显示页
		g_iCurShowPage_Apply = iPageCount;
	end;

	-- 删除一个申请者
	--Raid:EraseApplicantByIdx(g_iCurSelApply_Apply);
	-- 刷新新的申请界面
	TeamFrame_RefreshCurShowApplyPage_RaidApply(g_iCurShowPage_Apply);
	Team_Show();
end

function TeamFrame_RefreshCurShowApplyPage_RaidApply(index)
	-- 刷新新的申请界面
	ClearUIModel();
	ShwoLeaderFlat(0);
	-- 清空旧的界面.
	for iUI = 0, 5 do
			g_Team_PlayerInfo_Name[iUI]:SetText("");
			g_Team_PlayerInfo_School[iUI]:SetText("");
			g_Team_PlayerInfo_Level[iUI]:SetText("");
            g_Team_PlayerInfo_Server[iUI]:SetText("")
			g_Team_PlayerInfo_FightScore[iUI]:SetText("");

			g_Team_PlayerInfo_GuildName[iUI]:SetText("");

	end
	HideDeadFlag()
	HideDeadLinkFlag()

	if(g_iMemberCount_Apply <= 0) then
		return;
	end

	local szNick;		-- 昵称
	local iFamily;	-- 门派
	local iLevel;	  -- 等级
	local iCapID;		-- 帽子
	local iHead;		-- 头
	local iArmourID;-- 身子
	local iCuffID;  -- 护腕
	local iFootID;	-- 腿
	local iWeaponID;-- 武器
    local sZoneWorldID  --- 服务器ID
	local iFightScore
	local szGuildName

	local iCurShowStart = index * g_iCurPageShowCount;
	local iCurShowEnd   = iCurShowStart + g_iCurPageShowCount;
	local iUIIndex = 0;

	if(iCurShowEnd > g_iMemberCount_Apply) then
		iCurShowEnd = g_iMemberCount_Apply;
	end

	for i = iCurShowStart, iCurShowEnd - 1 do
		-- 刷新当前界面的每一个申请者信息.
		-- 得到队员的详细信息
		szNick
		,iFamily
		,iLevel
		,iCapID
		,iHead
		,iArmourID
		,iCuffID
		,iFootID
		,iWeaponID
        ,_              --- 这里是性别，我不需要，所以不用读取
        ,sZoneWorldID
		,iFightScore
		,szGuildName
		= Raid:GetApplyMemberInfoByIdx(i);

		g_Team_PlayerInfo_Name[iUIIndex]:SetText(tostring(szNick));
		g_Team_PlayerInfo_School[iUIIndex]:SetText(tostring(iFamily));
		g_Team_PlayerInfo_Level[iUIIndex]:SetText(tostring(iLevel));
		g_Team_PlayerInfo_FightScore[iUIIndex]:SetText("#{BHXX_160531_3}"..tostring(iFightScore));
		if szGuildName == nil or szGuildName == "" then
			g_Team_PlayerInfo_GuildName[iUIIndex]:SetText("#{BHXX_160531_1}".."#{GMGameInterface_Script_DataPool_Info_None}")
		else
			g_Team_PlayerInfo_GuildName[iUIIndex]:SetText("#{BHXX_160531_1}"..tostring(szGuildName))
		end
		-- 显示门派信息
		ShowFamily(iUIIndex, iFamily);
        --- 显示服务器名
        TeamFrame_ShowServerName( iUIIndex, sZoneWorldID )
		-- 得到ui模型信息
		local strModelName = Raid:GetApplicantUIModelNameByIdx(i);
		-- 显示模型
		g_TeamFrame_FakeObject[iUIIndex]:SetFakeObject(strModelName);
		iUIIndex = iUIIndex + 1;
	end
	SelectPos(0);
end

function Team_Button_Frame8_Click()
	Player:OpenCreateRaidConfirmWindow()
end

function Team_ChangeButtonTip()
	local noChatActiveMode = Variable:GetVariable("NonChatActive");
	if noChatActiveMode == "1" then
		Team_Follow_Button						:SetToolTip("#{JPYD_130822_10}")
		Team_AbortTeamFollow_Button	:SetToolTip("#{JPYD_130822_11}")
	else
		Team_Follow_Button						:SetToolTip("#{ZDGS_Tips_90602_01}")
		Team_AbortTeamFollow_Button	:SetToolTip("#{ZDGS_Tips_90602_02}")
	end
end


