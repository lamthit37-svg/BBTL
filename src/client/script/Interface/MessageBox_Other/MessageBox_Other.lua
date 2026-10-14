--说明，在这个lua里头，只能添加来自其他玩家的消息会直接在
--      玩家的界面中直接弹出要求确认对话框的情况

--1、系统提示
--2、拉人技能
--3、队员邀请某人加入队伍请你（队长）同意
--4、队长邀请进入组队跟随模式



local g_InitiativeClose = 0;

local g_FrameInfo
local STALL_RENT_FRAME			= 1;
local DISCARD_ITEM_FRAME		= 2;
local CANNT_DISCARD_ITEM		= 3;
local TEAM_ASKJOIN					= 4;	--有人邀请你加入队伍
local TEAM_MEMBERINVERT			= 5;	--队员邀请某人加入队伍请求你同意
local TEAM_SOMEASK					= 6;	--某人申请加入队伍
local TEAM_FOLLOW		 				= 7;	--进入组队跟随模式
local FRAME_AFFIRM_SHOW 		= 8;	--进入放弃任务确认模式
local GUILD_CREATE_CONFIRM	= 9; 	--帮会创建确认模式
local SYSTEM_TIP_INFO 			= 10; --系统提示对话框模式
local GUILD_QUIT_CONFIRM 		= 11; --帮会退出确认模式
local GUILD_DESTORY_CONFIRM = 12; --帮会删除确认模式
local CALL_OF								= 13;	--拉人
local INVITE_RIDE						= 14;  --邀请多骑
local GROUP_INVITE					=15;	--有人邀请你加入群
local APPLY_RIDE						= 16;  --申请多骑
local IMDRESS_NOTPAY_CONFIRM					= 17;  --炫装未付款确认
local IMFITTING_DEL_CONFIRM					= 18;  --炫装删除确认
local CHANGE_CHATWINDOW_CONFIRM					= 19;  --修改聊天窗口大小确认
--local XUNYOU_INSTALL_SURE = 20;             --迅游安装确认

local Quest_Number;
local g_MessageBox_Other_Frame_UnifiedPosition;
local g_IMFitting_Del_Item =
{
	name = "",
	index = -1,
}

--加入炫装赠品商城之后，g_IMShop_Table_Index表示要打开的新的窗口，
-- 0，1表示元宝商店 和 绑定元宝商店
-- PresentShop 表示炫装赠品商城 XuanShop表示炫装商城
-- XuanPresent_ChooseFriend表示 赠送炫装的好友选择界面
local g_IMShop_Table_Index = ""
local g_IMShop_Position_X = ""
local g_IMShop_Position_Y = ""
-- g_NotPayType 表示已经打开的界面
local g_NotPayType = ""
local g_friendid_old = ""
local g_friendid_new = -1
local g_Is_Mini_Window = 0

--===============================================
-- OnLoad()
--===============================================
function MessageBox_Other_PreLoad()

	this:RegisterEvent("OPEN_SYSTEM_TIP_INFO_DLG",true);
	--this:RegisterEvent("OPEN_CALLOF_PLAYER");

	-- 有人邀请你加入队伍
	this:RegisterEvent("SHOW_TEAM_YES_NO",true);
	-- 队员邀请某人加入队伍请你同意.
	--this:RegisterEvent("TEAM_MEMBER_INVITE");
	-- 某人申请加入队伍.
	this:RegisterEvent("TEAM_APPLY",true);
	-- 队长邀请进入组队跟随模式
	this:RegisterEvent("TEAM_FOLLOW_INVITE",true);

	this:RegisterEvent("RECIVE_RIDE_INVITE",true); --多人骑乘的邀请
	this:RegisterEvent("RECIVE_RIDE_APPLY",true); --多人骑乘的申请

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("GROUP_INVITE",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("IMSHOP_NOTPAY_CONFIRM",true);
	this:RegisterEvent("IMFITTING_DELETE_CONFIRM",true);
	this:RegisterEvent("CHANGE_IMWINDOWMODE",true);

end

function MessageBox_Other_OnLoad()
	-- 隐藏中间的按钮
	MessageBox_Other_Info_Button:Hide();
  g_MessageBox_Other_Frame_UnifiedPosition=MessageBox_Other_Frame:GetProperty("UnifiedPosition");
end

--===============================================
-- OnEvent()
--===============================================
function MessageBox_Other_OnEvent(event)

	-- 人有邀请你加入队伍
	if ( event == "SHOW_TEAM_YES_NO" ) then

		g_FrameInfo = TEAM_ASKJOIN;
		MessageBox_Other_Text:SetText(arg0.."邀请你加入队伍");
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;

	-- 队员邀请某人加入队伍请你同意
	elseif ( event == "TEAM_MEMBER_INVITE" ) then

		g_FrameInfo = TEAM_MEMBERINVERT;
		MessageBox_Other_Text:SetText(arg0.."邀请" .. arg1 .. "加入队伍, 同意吗?");
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;

	-- 某人申请加入队伍
	elseif ( event == "TEAM_APPLY" ) then

		g_FrameInfo = TEAM_SOMEASK;
		MessageBox_Other_Text:SetText(arg0.."申请加入队伍, 同意吗?");
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;

	-- 队长邀请进入组队跟随模式
	elseif ( event == "TEAM_FOLLOW_INVITE" ) then

		g_FrameInfo = TEAM_FOLLOW;

		MessageBox_Other_Text:SetText(arg0.."希望你跟随队伍, 同意吗?");
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;

	-- 提示系统信息。
	elseif( event == "OPEN_SYSTEM_TIP_INFO_DLG" ) then

		-- 显示系统信息。
		MessageBox_Other_Show_single_Info(1);
		MessageBox_Other_Text:SetText(tostring(arg0));
		this:Show();

	elseif( event == "OPEN_CALLOF_PLAYER" )   then
		g_FrameInfo = CALL_OF;
		local szName = arg0;

		MessageBox_Other_Text:SetText(szName .. "拉你，同意不？");
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;
	-- ===========================================
	-- czf modify begin 2010/8
	elseif( event == "RECIVE_RIDE_INVITE" ) then
		g_FrameInfo = INVITE_RIDE;
		local szName = arg0;
		local szMountName = arg1
		local canFly = tonumber(arg2)
		if canFly == 1 then
			MessageBox_Other_Text:SetText(szName .. "#{DRCQ_100804_10}"..szMountName.."#{FLY_110406_06}");
		else
			MessageBox_Other_Text:SetText(szName .. "#{DRCQ_100804_10}"..szMountName.."#{DRCQ_100804_56}");
		end

		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;

	elseif( event == "RECIVE_RIDE_APPLY" ) then
		g_FrameInfo = APPLY_RIDE;
		local szName = arg0;
		MessageBox_Other_Text:SetText(szName .. "申请与你同骑");
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;
	-- czf modify end
	-- ============================================
	elseif( event == "GROUP_INVITE" ) then
		g_FrameInfo = GROUP_INVITE;
		MessageBox_Other_Text:SetText(arg0);
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;
	elseif( event == "IMSHOP_NOTPAY_CONFIRM" ) then
		if (IsWindowShow("XuanShop") == false) then
			--IMDressCleanUpPayBox();
			--return
		end

		local ret = IMDressLoadPayBox();
		if (ret == nil or ret <= 0 ) then
			return
		end

		g_IMShop_Table_Index = ""
		g_IMShop_Position_X = ""
		g_IMShop_Position_Y = ""

		g_NotPayType = ""
		g_friendid_old = ""
		g_friendid_new = -1

		--消息参数格式 arg0 = 标识旧窗口， arg1 = 标识新窗口，其他消息参数不固定，根据arg0和arg1的值来确定

		--如果原来的窗口为"XuanShop"，新要打开的窗口为"PresentShop"
		--arg2 = "PresentShop"窗口需要的friend的guid
		if (arg0 and arg1 and arg0 == "XuanShop" and arg1 == "PresentShop") then
			g_NotPayType = arg0;
			g_IMShop_Table_Index = arg1;
			g_friendid_new = tonumber(arg2);
		end

		--如果原来的窗口为"PresentShop"，新要打开的窗口为"XuanShop"
		--arg2 = "xuanpayed"窗口需要的friend的guid
		if (arg0 and arg1 and arg0 == "PresentShop" and arg1 == "XuanShop") then
			g_NotPayType = arg0;
			g_IMShop_Table_Index = arg1;
			g_friendid_old = arg2;
		end

		--如果原来的窗口为"PresentShop"，新要打开的窗口为"PresentShop"
		--arg2 = 旧"PresentShop"窗口需要的friend的guid
		--arg3 = 新"PresentShop"窗口需要的friend的guid
		if (arg0 and arg1 and arg0 == "PresentShop" and arg1 == "PresentShop") then
			g_NotPayType = arg0;
			g_IMShop_Table_Index = arg1;
			g_friendid_old = arg2;
			g_friendid_new = tonumber(arg3);
		end

		--如果原来的窗口为"XuanShop"，新要打开的窗口为 元宝商城 和 绑定元宝商城 和 返券商店
		--arg2 = X坐标，arg3 =  Z坐标
		if (arg0 and arg1 and arg0 == "XuanShop" and (arg1 == "0" or arg1 == "1" or arg1 == "2" or arg1 == "4") ) then
			g_NotPayType = arg0;
			g_IMShop_Table_Index = arg1;
			g_IMShop_Position_X = arg2;
			g_IMShop_Position_Y = arg3;
		end

		--如果原来的窗口为"XuanShop"，新要打开的窗口为"XuanPresent_ChooseFriend"
		if (arg0 and arg1 and arg0 == "XuanShop" and arg1 == "XuanPresent_ChooseFriend" ) then
			g_NotPayType = arg0;
			g_IMShop_Table_Index = arg1;
		end

		--表示原来的窗口为"XuanShop"，没有新要打开的窗口
		if (arg0 and arg1 and arg0 == "XuanShop" and arg1 == "-1") then
			g_NotPayType = arg0;
			g_IMShop_Table_Index = arg1;
		end

		--表示原来的窗口为"PresentShop"，没有新要打开的窗口
		--arg2 = "xuanpayed"窗口需要的friend的guid
		if (arg0 and arg1 and arg0 == "PresentShop" and arg1 == "-1") then
			g_NotPayType = arg0;
			g_IMShop_Table_Index = arg1;
			g_friendid_old = arg2;
		end

		g_FrameInfo = IMDRESS_NOTPAY_CONFIRM;
		MessageBox_Other_Text:SetText("#{IMXZ_20100813_03}");
		this:Show();
		MessageBox_Other_Show_single_Info( 2 );
		g_InitiativeClose = 0;
	elseif ( event == "IMFITTING_DELETE_CONFIRM" ) then
		if (IsWindowShow("XuanFitting") == false) then
			return
		end
		g_IMFitting_Del_Item.index = tonumber(arg0);
		g_IMFitting_Del_Item.name = arg1;

		g_FrameInfo = IMFITTING_DEL_CONFIRM;
		MessageBox_Other_Text:SetText("#{IMXZ_20100813_52}"..g_IMFitting_Del_Item.name);
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;
	elseif ( event == "CHANGE_IMWINDOWMODE" ) then

		g_Is_Mini_Window = tonumber(arg0);

		g_FrameInfo = CHANGE_CHATWINDOW_CONFIRM;
		MessageBox_Other_Text:SetText("#{IMXZ_20101108_01}");
		this:Show();
		MessageBox_Other_Show_single_Info( 0 );
		g_InitiativeClose = 0;
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		MessageBox_Other_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MessageBox_Other_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (g_FrameInfo ==INVITE_RIDE or g_FrameInfo == APPLY_RIDE) then
			this:Hide()
		end
	end
	

	MessageBox_Other_UpdateFrame()

end

--===============================================
-- UpdateFrame
--===============================================
function MessageBox_Other_UpdateFrame()

	local nWidth, nHeight = MessageBox_Other_Text:GetWindowSize();
	local nTitleHeight = 36;
	local nBottomHeight = 75;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	MessageBox_Other_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );

	--TT81937 cys
	if SystemSetup:IsClassic() == 0 then
		MessageBox_Other_Frame:SetProperty( "AbsoluteWidth", 300 );
	else
		MessageBox_Other_Frame:SetProperty( "AbsoluteWidth", 256 );
	end
end

--===============================================
-- 点击确定（IDOK）
--===============================================
function MessageBox_Other_OK_Clicked()
	if(g_FrameInfo == TEAM_ASKJOIN) then
		--0 人有邀请你加入队伍
		Player:AgreeJoinTeam();
		g_InitiativeClose = 1;
		this:Hide();

	elseif(g_FrameInfo == TEAM_MEMBERINVERT) then
		--1 某人申请加入队伍
		Player:SendAgreeJoinTeam_TeamMemberInvite();
		g_InitiativeClose = 1;
		this:Hide();

	elseif(g_FrameInfo == TEAM_SOMEASK) then
		--处理申请加入队伍
		Player:SendAgreeJoinTeam_Apply();
		g_InitiativeClose = 1;
		this:Hide();

	elseif(g_FrameInfo == TEAM_FOLLOW) then
		--队长邀请进入组队跟随模式
		Player:SendAgreeTeamFollow();
		g_InitiativeClose = 1;
		this:Hide();

	elseif(g_FrameInfo == CALL_OF)  then
		Friend:CallOf("ok");
		this:Hide();

	-- czf modify begin
	elseif( g_FrameInfo == INVITE_RIDE ) then
		AcceptInviteRide(1);
		g_InitiativeClose = 1;
		this:Hide();

	elseif( g_FrameInfo == APPLY_RIDE ) then
		AcceptApplyRide(1);
		g_InitiativeClose = 1;
		this:Hide();

	-- czf modify end

	elseif( g_FrameInfo == GROUP_INVITE ) then
		Player:SendAgreeJoinGroup()
		this:Hide();
	elseif( g_FrameInfo == IMDRESS_NOTPAY_CONFIRM ) then
		local ret = IMDressLoadPayBox();
		if (ret == nil or ret <= 0) then
			PushDebugMessage("#{IMXZ_20100813_37}")
			this:Hide();
			return
		end
		if g_NotPayType == "XuanShop" then
			PushEvent("OPEN_IMDRESS_PAYED","XuanShop")
		elseif g_NotPayType == "PresentShop" then

			if g_friendid_old == "" then
				PushDebugMessage("#{ZSGN_101129_24}");
				this:Hide();
				return
			end

			local Friendgroup, Friendindex = DataPool:GetFriendByGUID(g_friendid_old);
			if Friendgroup == 0 or Friendindex == -1 then
				PushDebugMessage("#{ZSGN_101129_24}");
				this:Hide();
				return
			end

			--如果不是好友
			local friendRelationType = DataPool:GetFriend( Friendgroup, Friendindex, "RELATION_TYPE"  )
			if friendRelationType == 0  or friendRelationType == 4  or friendRelationType == 5 or
			   friendRelationType == 6  or friendRelationType == 9 then
				PushDebugMessage("#{ZSGN_101129_24}");
				this:Hide();
				return
			end

			PushEvent("OPEN_IMDRESS_PAYED","PresentShop", g_friendid_old)
		end
		this:Hide();
	elseif( g_FrameInfo == IMFITTING_DEL_CONFIRM ) then
		IMSendDeleteMsg(g_IMFitting_Del_Item.index)
		g_IMFitting_Del_Item.name = ""
		g_IMFitting_Del_Item.index = -1
		this:Hide();
	elseif( g_FrameInfo == CHANGE_CHATWINDOW_CONFIRM ) then
		ChangeChatWindowMode(g_Is_Mini_Window)
		g_Is_Mini_Window = 0
		this:Hide();
	end

	this:Hide();
	g_FrameInfo = 0;
end

--===============================================
-- 放弃摆摊(IDCONCEL)
--===============================================
function MessageBox_Other_Cancel_Clicked(fromButton)

	-- 隐藏消息按钮2006－3－27
	MessageBox_Other_Show_single_Info(0);

	if(g_InitiativeClose == 1)  then
		return;
	end

	if ( g_FrameInfo == TEAM_ASKJOIN ) then
		--通知解除锁定
		Player:RejectJoinTeam();

	elseif ( g_FrameInfo == TEAM_MEMBERINVERT ) then
		--处理有人邀请你加入队伍
		Player:SendRejectJoinTeam_TeamMemberInvite();

	elseif ( g_FrameInfo == TEAM_SOMEASK ) then
		--处理申请加入队伍
		Player:SendRejectJoinTeam_Apply();

	elseif ( g_FrameInfo == TEAM_FOLLOW ) then
		--队长邀请进入组队跟随模式
		Player:SendRefuseTeamFollow();
		g_FrameInfo = 0;
	elseif(g_FrameInfo == CALL_OF)  then
		Friend:CallOf("cancel");

	-- czf modify begin
	elseif( g_FrameInfo == INVITE_RIDE ) then
		AcceptInviteRide(0);
		this:Hide();

	elseif( g_FrameInfo == APPLY_RIDE ) then
		AcceptApplyRide(0);
		this:Hide();
	-- czf modify end

	elseif( g_FrameInfo == GROUP_INVITE ) then
		Player:SendRefuseJoinGroup()
		this:Hide();
	elseif( g_FrameInfo == IMDRESS_NOTPAY_CONFIRM ) then
		if (fromButton and fromButton == 1) then
			if(IsWindowShow("XuanPayed") == true) then
				CloseWindow("XuanPayed",true)
			end
			if (g_IMShop_Table_Index and (g_IMShop_Table_Index == "0" or g_IMShop_Table_Index == "1" or g_IMShop_Table_Index == "2" or g_IMShop_Table_Index == "4")) then
				PushEvent("TOGGLE_YUANBAOSHOP", g_IMShop_Table_Index, g_IMShop_Position_X, g_IMShop_Position_Y, -1 ,-1);
			elseif (g_IMShop_Table_Index and g_IMShop_Table_Index == "XuanShop" ) then
				if IsWindowShow("XuanShop") == true then
					CloseWindow("XuanShop", true)
				end
				PushEvent("OPEN_IMDRESS_YUANBAOSHOP");
			elseif (g_IMShop_Table_Index and g_IMShop_Table_Index == "PresentShop" ) then
				if IsWindowShow("XuanShop") == true then
					CloseWindow("XuanShop", true)
				end
				PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", g_friendid_new);
			elseif (g_IMShop_Table_Index and g_IMShop_Table_Index == "XuanPresent_ChooseFriend" ) then
				if IsWindowShow("XuanShop") == true then
					CloseWindow("XuanShop", true)
				end
				PushEvent("OPEN_XUANPRESENT_CHOOSEFRIEND", "XuanGift" );
			elseif(IsWindowShow("XuanShop") == true) then
				CloseWindow("XuanShop", true)
			end
			IMDressCleanUpPayBox();
		end
		this:Hide();
	elseif( g_FrameInfo == IMFITTING_DEL_CONFIRM ) then
		g_IMFitting_Del_Item.name = ""
		g_IMFitting_Del_Item.index = -1
		this:Hide();
	elseif( g_FrameInfo == CHANGE_CHATWINDOW_CONFIRM ) then
		g_Is_Mini_Window = 0;
		this:Hide();
	end

	this:Hide();
	g_FrameInfo = 0;

end



--------------------------------------------------------------------------------------------------------
--
-- 单一提示信息
--
function MessageBox_Other_Info_Clicked()

	-- 关闭信息对话框。
	MessageBox_Other_Show_single_Info(0);
	this:Hide();
end


function MessageBox_Other_Show_single_Info(bShow)

	if(1 == bShow) then
		MessageBox_Other_OK_Button:SetText( "确定" );
		MessageBox_Other_Cancel_Button:SetText( "取消" );
		MessageBox_Other_OK_Button:Hide();
		MessageBox_Other_Info_Button:Show();
		MessageBox_Other_Cancel_Button:Hide();

	elseif(0 == bShow) then
		MessageBox_Other_OK_Button:SetText( "同意" );
		MessageBox_Other_Cancel_Button:SetText( "拒绝" );
		MessageBox_Other_OK_Button:Show();
		MessageBox_Other_Info_Button:Hide();
		MessageBox_Other_Cancel_Button:Show();

	elseif(2 == bShow) then
		MessageBox_Other_OK_Button:SetText( "是" );
		MessageBox_Other_Cancel_Button:SetText( "否" );
		MessageBox_Other_OK_Button:Show();
		MessageBox_Other_Info_Button:Hide();
		MessageBox_Other_Cancel_Button:Show();
	end;


end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MessageBox_Other_Frame_On_ResetPos()
  MessageBox_Other_Frame:SetProperty("UnifiedPosition", g_MessageBox_Other_Frame_UnifiedPosition);
end
