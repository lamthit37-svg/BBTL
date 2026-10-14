local IsShow = 0;

local g_name = "";
local g_FriendInfo_zoneworldid = -1
--===============================================
-- OnLoad()
--===============================================
function FriendInfo_PreLoad()

	this:RegisterEvent("TOGLE_FRIEND_INFO",true);
	this:RegisterEvent("UPDATE_FRIEND_INFO",true);
end

function FriendInfo_OnLoad()

end

function FriendInfoSiLiao_Clicked(itemname)
	 Talk:ContexMenuTalk(g_name, g_FriendInfo_zoneworldid);
end
--===============================================
-- OnEvent()
--===============================================
function FriendInfo_OnEvent( event )

	if ( event == "TOGLE_FRIEND_INFO" ) then
			if( tonumber(arg0) == -1 ) then
				FriendInfo_OnHide();
				return;
			end
			FriendInfo_Show( -1, -1 );

	elseif( event == "UPDATE_FRIEND_INFO" ) then
		if arg2 ~= nil and tonumber(arg2) == 1 then
			--K服上的玩家
			if IsShow == 1 then
				IsShow = 0
			end

			if this:IsVisible() then
				this:Hide()
			end

			return
		end

		FriendInfo_Update( arg0, arg1 );
	end
end


--===============================================
-- UpdateFrame()
-- 第几个频道的第几个人
--===============================================
function FriendInfo_Update( nChannel, nIndex )
	g_name = "";
	g_FriendInfo_zoneworldid = -1
	if(IsShow == 1)then

		local strFaceImage = DataPool:GetFriend( nChannel, nIndex, "PORTRAIT" );
		if( nChannel== -1 ) then
			FriendInfo_PlayerHead:SetProperty("Image", "");
			FriendInfo_ID:SetText( "ID:");
			FriendInfo_Name:SetText( "姓名:" );
			FriendInfo_Beizhu:SetText( "#{BZXX_140915_1}" );
			FriendInfo_Level:SetText( "级别:" );
			FriendInfo_MenPai:SetText( "门派:");
			FriendInfo_FriendlyGrade:SetText( "友好度:" );
			FriendInfo_Confraternity:SetText( "帮会名称:");
			FriendInfo_GuildLeague:SetText( "#{TM_20080311_30}");
			FriendInfo_Explain:SetText( "心情:" );
			FriendInfo_Relation:SetText( "关系:" );
			FriendInfo_Agname:SetText( "称号:" );
			FriendInfo_Locus:SetText( "位置:" );
			FriendInfo_TeamInfo:SetText( "队伍:" );

			FriendInfo_Join:SetText( "邀请加队" );
			FriendInfo_Join:Disable();

			FriendInfo_PlayerHead_Frame:SetProperty("Image", "")
			FriendInfo_PlayerHead_Frame_Animate:SetProperty("Animate", "")
			FriendInfo_PlayerHead_Frame_Animate:Hide()
		else

			local imOnlineTime = DataPool:GetFriend( nChannel, nIndex, "IM_ONLINE_TIME" );
			local level , sunNum ,moonNum , starNum = DataPool:GetIMIconNum(tonumber(imOnlineTime))
			local iconStr = ""
			if imOnlineTime ~= nil and imOnlineTime >=0 then

				iconStr = "#{LTQH_XML_98}"..tostring(level).."#r"
				for i = 1 , sunNum + moonNum + starNum do
					if i <= sunNum then
						iconStr = iconStr.."#-37"
					elseif i <= sunNum + moonNum then
						iconStr = iconStr.."#-36"
					elseif i <= sunNum + moonNum + starNum then
						iconStr = iconStr.."#-35"
					end
				end
			end
			g_name = DataPool:GetFriend( nChannel, nIndex, "NAME"  ) ;
			g_FriendInfo_zoneworldid = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID")
			FriendInfo_PlayerHead:SetProperty("Image", tostring(strFaceImage));
			local selfZoneWorldID = DataPool:GetSelfZoneWorldID()

			if DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) then
				FriendInfo_PlayerHead:SetToolTip(tostring(iconStr));
			else
				FriendInfo_PlayerHead:SetToolTip("");
			end
			
			-- add 头像边框
			local iHeadFrameType = DataPool:GetFriend(nChannel, nIndex, "HEADFRAMETYPE")
			if iHeadFrameType == 1 then
				FriendInfo_PlayerHead_Frame:SetProperty("Image", "")
				FriendInfo_PlayerHead_Frame:Hide()
				
				FriendInfo_PlayerHead_Frame_Animate:Show()
				local strHeadFrameAnimate = DataPool:GetFriend(nChannel, nIndex, "HEADFRAMEANIMATE")
				FriendInfo_PlayerHead_Frame_Animate:SetProperty("Animate", tostring(strHeadFrameAnimate))
			
			else			
				FriendInfo_PlayerHead_Frame_Animate:SetProperty("Animate", "")
				FriendInfo_PlayerHead_Frame_Animate:Hide()
			
				FriendInfo_PlayerHead_Frame:Show()
				local strHeadFrameImage = DataPool:GetFriend(nChannel, nIndex, "HEADFRAME")
				local IconFile = GetIconFullName(strHeadFrameImage)
				FriendInfo_PlayerHead_Frame:SetProperty("Image", IconFile)
			end
			
			local FriendGuid = DataPool:GetFriend( nChannel, nIndex, "ID_TEXT" )
			local FriendGuidText = ConvertGuidToShow(FriendGuid)
			FriendInfo_ID:SetText( "ID:"..FriendGuidText );
			local friendName = DataPool:GetFriend( nChannel, nIndex, "NAME"  )
			--local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
			if g_FriendInfo_zoneworldid ~= -1 and g_FriendInfo_zoneworldid ~= selfZoneWorldID then
				friendName = friendName .. "@" .. DataPool:GetServerName(g_FriendInfo_zoneworldid)
			end
			local friendremark = DataPool:GetFriend( nChannel, nIndex, "REMARK" );
			FriendInfo_Name:SetText( "姓名:"..friendName );
			FriendInfo_Beizhu:SetText( "#{BZXX_140915_1}"..friendremark );
			FriendInfo_Level:SetText( "级别:"..tostring( DataPool:GetFriend( nChannel, nIndex, "LEVEL" ) ) );
			FriendInfo_MenPai:SetText( "门派:"..DataPool:GetFriend( nChannel, nIndex, "MENPAI_TEXT" ) );
			if( tonumber( nChannel ) == 6 ) then
				FriendInfo_FriendlyGrade:SetText( "友好度:" );
			elseif( tonumber( nChannel ) == 7 ) then
				FriendInfo_FriendlyGrade:SetText( "友好度:" );
			else
				FriendInfo_FriendlyGrade:SetText( "友好度:"..tostring( DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" ) ) );
			end
			FriendInfo_Confraternity:SetText( "帮会名称:"..DataPool:GetFriend( nChannel, nIndex, "GUID_NAME" ) );
			FriendInfo_GuildLeague:SetText( "#{TM_20080311_30}"..DataPool:GetFriend( nChannel, nIndex, "GUILD_LEAGUE_NAME" ) );
			FriendInfo_Explain:SetText( "心情:"..DataPool:GetFriend( nChannel, nIndex, "MOOD" ) );

			if( tonumber( nChannel ) == 6 ) then
				FriendInfo_Relation:SetText( "关系:交恶" );
			elseif (tonumber( nChannel) == 7) then
				FriendInfo_Relation:SetText( "关系:交恶" );
			else
				FriendInfo_Relation:SetText( "关系:"..DataPool:GetFriend( nChannel, nIndex, "RELATION_TEXT" ) );
			end


			FriendInfo_Agname:SetText( "称号:"..DataPool:GetFriend( nChannel, nIndex, "TITLE" ) );
			FriendInfo_Locus:SetText( "位置:"..DataPool:GetFriend( nChannel, nIndex, "SCENE" ) );
			FriendInfo_TeamInfo:SetText( "队伍:"..DataPool:GetFriend( nChannel, nIndex, "TEAM_NUMBER" ) );
			local TeamNumber = DataPool:GetFriend( nChannel, nIndex, "TEAM_NUMBER" );
			FriendInfo_Join:Enable();
			if( TeamNumber == "未组队" ) then
				FriendInfo_Join:SetText( "邀请加队" );
			else
				FriendInfo_Join:SetText( "申请入队" );
			end
		end
		if( tonumber( nChannel ) == 5 ) then
			FriendInfo_Join:Hide();
			FriendInfo_Groupinge:Hide();
			FriendInfo_Correspondence:Hide();
		else
			FriendInfo_Join:Show()
			FriendInfo_Correspondence:Show()	
			
			local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" )	
			local guid =  DataPool:GetFriend( nChannel, nIndex, "ID" )		
			
			if relationtype == 2 or relationtype == 3 or 
				(relationtype == 7 and Friend:Lua_IsShimenMemberInfoValid() == 1) or relationtype == 8  then
				FriendInfo_DEL:Hide()
				FriendInfo_Groupinge:Hide()
			elseif Friend:Lua_IsShimenMemberInfoValid() == 1 and Friend:Lua_IsSameMasterWithMe(guid) == 1 then
				FriendInfo_DEL:Show()
				FriendInfo_Groupinge:Hide()
			else
				FriendInfo_DEL:Show()
				FriendInfo_Groupinge:Show()	
			end
		end
		
		IsShow = 0;
		-- 如果已经是打开状态，则先关了再开，保证每次打开都置顶 TT79576
		if this:IsVisible() then
			this:Hide();
		end
		this:Show();
	end;

end

function FriendInfo_Show( arg_0, arg_1 )

	--FriendInfo_Update( Friend:GetCurrentTeam() ,Friend:GetCurrentSelect());
	--this:Show();
	IsShow = 1;
end

function FriendInfo_OnHide()
	if this : IsVisible() then
		this:Hide();
	end
	IsShow = 0;
end

function FriendInfo_WriteMail()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		DataPool:OpenMail( g_name );
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_OnHide();
	end
end

function FriendInfo_OnHelp()
end

function FriendInfo_OnHistroy()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		DataPool:OpenHistroy(tonumber(group) ,tonumber(index) );
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_OnHide();
	end

end

function FriendInfo_OnJoin()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		local TeamNumber = DataPool:GetFriend(tonumber(group) ,tonumber(index), "TEAM_NUMBER" );
		if( TeamNumber == "未组队" ) then
			Friend:InviteTeam( DataPool:GetFriend(tonumber(group) ,tonumber(index), "NAME"  ) );
		else
			Friend:AskTeam( DataPool:GetFriend(tonumber(group) ,tonumber(index), "NAME"  ) );
		end
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_OnHide();
	end


end

function FriendInfo_OnGroup()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		Friend:OpenGrouping(tonumber(group) ,tonumber(index)  );
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_OnHide();
	end

end

function FriendInfo_OnDelete()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		DataPool:AskDelFriend( tonumber(group) ,tonumber(index) );
	else
		PushDebugMessage("操作失败，此好友不存在。")
	end

	FriendInfo_OnHide();
end
