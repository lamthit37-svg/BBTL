local IsShow = 0;
local g_name = "";
local g_FriendInfo_KVK_zoneworldid = -1

local g_FriendInfo_UnifiedPosition
local FriendInfo_Frame_Original_Size
local FriendInfo_Frame_DiffWorldFriend_Hight = "{0.000000,343.000000}"
local FriendInfo_PlayerHead_Position
local FriendInfo_PlayerHead_DiffWorldFriend_YPosition = "{0.000000,0.000000}"
local FriendInfo_PlayerHead_Position_Animate

--===============================================
-- OnLoad()
--===============================================
function FriendInfo_KVK_PreLoad()

	this:RegisterEvent("TOGLE_FRIEND_INFO");
	this:RegisterEvent("UPDATE_FRIEND_INFO");
end

function FriendInfo_KVK_OnLoad()
	g_FriendInfo_UnifiedPosition = FriendInfo_KVK_Frame:GetProperty("UnifiedPosition")
	FriendInfo_Frame_Original_Size = FriendInfo_KVK_Frame:GetProperty("UnifiedSize")
	FriendInfo_PlayerHead_Position = FriendInfo_KVK_PlayerHead_Frame:GetProperty("UnifiedPosition")
	FriendInfo_PlayerHead_Position_Animate = FriendInfo_KVK_PlayerHead_Animate:GetProperty("UnifiedPosition")
	if SystemSetup:IsClassic() == 0 then
		FriendInfo_Frame_DiffWorldFriend_Hight = "{0.000000,385.000000}"
	end
end

function FriendInfo_KVKSiLiao_Clicked(itemname)
	 Talk:ContexMenuTalk(g_name, g_FriendInfo_KVK_zoneworldid);
end
--===============================================
-- OnEvent()
--===============================================
function FriendInfo_KVK_OnEvent( event )

	if ( event == "TOGLE_FRIEND_INFO" ) then
			if( tonumber(arg0) == -1 ) then
				FriendInfo_KVK_OnHide();
				return;
			end
			FriendInfo_KVK_Show( -1, -1 );

	elseif( event == "UPDATE_FRIEND_INFO" ) then
		if arg2 ~= nil and tonumber(arg2) == 0 then
			--K服上的玩家
			if IsShow == 1 then
				IsShow = 0
			end

			if this:IsVisible() then
				this:Hide()
			end

			return
		end

		FriendInfo_KVK_Update( arg0, arg1 );
	end
end


--===============================================
-- UpdateFrame()
-- 第几个频道的第几个人
--===============================================
function FriendInfo_KVK_Update( nChannel, nIndex )
	g_name = "";
	g_FriendInfo_KVK_zoneworldid = -1
	if(IsShow == 1)then

		local strFaceImage = DataPool:GetFriend( nChannel, nIndex, "PORTRAIT" );
		if( nChannel== -1 ) then
			FriendInfo_KVK_PlayerHead:SetProperty("Image", "");
			FriendInfo_KVK_ID:SetText( "ID:");
			FriendInfo_KVK_Name:SetText( "姓名:" );
			FriendInfo_KVK_Beizhu:SetText( "#{BZXX_140915_1}" );
			FriendInfo_KVK_Level:SetText( "级别:" );
			FriendInfo_KVK_MenPai:SetText( "门派:");
			FriendInfo_KVK_FriendlyGrade:SetText( "友好度:" );
			FriendInfo_KVK_Confraternity:SetText( "#{TM_20080318_12}");
			FriendInfo_KVK_Explain:SetText( "心情:" );
			FriendInfo_KVK_Relation:SetText( "关系:" );
			FriendInfo_KVK_Agname:SetText( "称号:" );
			FriendInfo_KVK_Locus:SetText( "位置:" );
			FriendInfo_KVK_TeamInfo:SetText( "队伍:" );

			FriendInfo_KVK_Join:SetText( "邀请加队" );
			FriendInfo_KVK_Join:Disable();

			FriendInfo_KVK_PlayerHead_Frame:SetProperty("Image", "")
			FriendInfo_KVK_PlayerHead_Animate:SetProperty("Animate", "")
			FriendInfo_KVK_AjustLayout(0)

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
			g_FriendInfo_KVK_zoneworldid = DataPool:GetFriend(nChannel, nIndex, "ZONEWORLDID")
			local selfZoneWorldID = DataPool:GetSelfZoneWorldID()

			FriendInfo_KVK_PlayerHead:SetProperty("Image", tostring(strFaceImage));
			
			-- add 头像边框
			local nHeadFrameType = DataPool:GetFriend(nChannel, nIndex, "HEADFRAMETYPE")
			if nHeadFrameType == 1 then
				FriendInfo_KVK_PlayerHead_Frame:SetProperty("Image", "")
				FriendInfo_KVK_PlayerHead_Frame:Hide()
				
				FriendInfo_KVK_PlayerHead_Animate:Show()
				local strHeadFrameAnimate = DataPool:GetFriend(nChannel, nIndex, "HEADFRAMEANIMATE")
				FriendInfo_KVK_PlayerHead_Animate:SetProperty("Animate", tostring(strHeadFrameAnimate))
			else
				FriendInfo_KVK_PlayerHead_Animate:SetProperty("Animate", "")
				FriendInfo_KVK_PlayerHead_Animate:Hide()
				
				FriendInfo_KVK_PlayerHead_Frame:Show()
				local strHeadFrameImage = DataPool:GetFriend(nChannel, nIndex, "HEADFRAME")
				local IconFile = GetIconFullName(strHeadFrameImage)
				FriendInfo_KVK_PlayerHead_Frame:SetProperty("Image", tostring(IconFile))
			end
			
			if DataPool:GetFriend( nChannel, nIndex, "ONLINE" ) then
				FriendInfo_KVK_PlayerHead:SetToolTip(tostring(iconStr));
			else
				FriendInfo_KVK_PlayerHead:SetToolTip("");
			end
			local FriendGuid = DataPool:GetFriend( nChannel, nIndex, "ID_TEXT" )
			local FriendGuidText = ConvertGuidToShow( FriendGuid )
			FriendInfo_KVK_ID:SetText( "ID:".. FriendGuidText );
			local friendName = DataPool:GetFriend( nChannel, nIndex, "NAME"  )
			--local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
			if g_FriendInfo_KVK_zoneworldid ~= -1 and g_FriendInfo_KVK_zoneworldid ~= selfZoneWorldID then
				friendName = friendName .. "@" .. DataPool:GetServerName(g_FriendInfo_KVK_zoneworldid)
			end
			local friendremark = DataPool:GetFriend( nChannel, nIndex, "REMARK" );
			FriendInfo_KVK_Name:SetText( "姓名:"..friendName );
			FriendInfo_KVK_Beizhu:SetText( "#{BZXX_140915_1}"..friendremark );
			FriendInfo_KVK_Level:SetText( "级别:"..tostring( DataPool:GetFriend( nChannel, nIndex, "LEVEL" ) ) );
			FriendInfo_KVK_MenPai:SetText( "门派:"..DataPool:GetFriend( nChannel, nIndex, "MENPAI_TEXT" ) );
			if( tonumber( nChannel ) == 6 ) then
				FriendInfo_KVK_FriendlyGrade:SetText( "友好度:" );
			elseif( tonumber( nChannel ) == 7 ) then
				FriendInfo_KVK_FriendlyGrade:SetText( "友好度:" );
			else
				FriendInfo_KVK_FriendlyGrade:SetText( "友好度:"..tostring( DataPool:GetFriend( nChannel, nIndex, "FRIENDSHIP" ) ) );
			end
			local strGuidName = tostring(DataPool:GetFriend( nChannel, nIndex, "GUID_NAME" ))
			if g_FriendInfo_KVK_zoneworldid ~= -1 and g_FriendInfo_KVK_zoneworldid ~= selfZoneWorldID and strGuidName~="" then
				strGuidName = strGuidName .. "@" .. DataPool:GetServerName(g_FriendInfo_KVK_zoneworldid)
			end
			FriendInfo_KVK_Confraternity:SetText( "#{TM_20080318_12}".. strGuidName);
			FriendInfo_KVK_Explain:SetText( "心情:"..DataPool:GetFriend( nChannel, nIndex, "MOOD" ) );

			if( tonumber( nChannel ) == 6 or tonumber( nChannel ) == 11) then
				FriendInfo_KVK_Relation:SetText( "关系:交恶" );
			elseif (tonumber( nChannel) == 7) then
				FriendInfo_KVK_Relation:SetText( "关系:交恶" );
			else
				FriendInfo_KVK_Relation:SetText( "关系:"..DataPool:GetFriend( nChannel, nIndex, "RELATION_TEXT" ) );
			end
			




			FriendInfo_KVK_Agname:SetText( "称号:"..DataPool:GetFriend( nChannel, nIndex, "TITLE" ) );
			FriendInfo_KVK_Locus:SetText( "位置:"..DataPool:GetFriend( nChannel, nIndex, "SCENE" ) );
			FriendInfo_KVK_TeamInfo:SetText( "队伍:"..DataPool:GetFriend( nChannel, nIndex, "TEAM_NUMBER" ) );
			local TeamNumber = DataPool:GetFriend( nChannel, nIndex, "TEAM_NUMBER" );
			FriendInfo_KVK_Join:Enable();
			if( TeamNumber == "未组队" ) then
				FriendInfo_KVK_Join:SetText( "邀请加队" );
			else
				FriendInfo_KVK_Join:SetText( "申请入队" );
			end

			if g_FriendInfo_KVK_zoneworldid ~= -1 and g_FriendInfo_KVK_zoneworldid ~= selfZoneWorldID then
				FriendInfo_KVK_AjustLayout(1)
			else
				FriendInfo_KVK_AjustLayout(0)
			end
		end
		if( tonumber( nChannel ) == 5 ) or ( tonumber( nChannel ) == 10 ) then
			FriendInfo_KVK_Join:Hide();
			FriendInfo_KVK_Groupinge:Hide();
			FriendInfo_KVK_Correspondence:Hide();
		else
			FriendInfo_KVK_Join:Show();
			FriendInfo_KVK_Groupinge:Show();
			FriendInfo_KVK_Correspondence:Show();
		end
		
		IsShow = 0;
		-- 如果已经是打开状态，则先关了再开，保证每次打开都置顶 TT79576
		if this:IsVisible() then
			this:Hide();
		end

		this:Show();
	end;

end

function FriendInfo_KVK_Show( arg_0, arg_1 )

	--FriendInfo_KVK_Update( Friend:GetCurrentTeam() ,Friend:GetCurrentSelect());
	--this:Show();
	IsShow = 1;
end

function FriendInfo_KVK_OnHide()
	if this : IsVisible() then
		this:Hide();
	end
	IsShow = 0;
end

function FriendInfo_KVK_WriteMail()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		DataPool:OpenMail( g_name );
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_KVK_OnHide();
	end
end

function FriendInfo_KVK_OnHelp()
end

function FriendInfo_KVK_OnHistroy()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		DataPool:OpenHistroy(tonumber(group) ,tonumber(index) );
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_KVK_OnHide();
	end

end

function FriendInfo_KVK_OnJoin()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name, tonumber(g_FriendInfo_KVK_zoneworldid));
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		local TeamNumber = DataPool:GetFriend(tonumber(group) ,tonumber(index), "TEAM_NUMBER" );
		if( TeamNumber == "未组队" ) then
			Friend:InviteTeam( DataPool:GetFriend(tonumber(group) ,tonumber(index), "NAME"  ), tonumber(g_FriendInfo_KVK_zoneworldid ));
		else
			Friend:AskTeam( DataPool:GetFriend(tonumber(group) ,tonumber(index), "NAME"  ), tonumber(g_FriendInfo_KVK_zoneworldid ));
		end
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_KVK_OnHide();
	end


end

function FriendInfo_KVK_OnGroup()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		Friend:OpenGrouping(tonumber(group) ,tonumber(index)  );
	else
		PushDebugMessage("操作失败，此好友不存在。")
		FriendInfo_KVK_OnHide();
	end

end

function FriendInfo_KVK_OnDelete()
	if(g_name == "") then
		return;
	end
	local group,index = DataPool:GetFriendByName(g_name);
	if(tonumber(group) ~=-1 and tonumber(index)~=-1)then
		DataPool:AskDelFriend( tonumber(group) ,tonumber(index) );
	else
		PushDebugMessage("操作失败，此好友不存在。")
	end

	FriendInfo_KVK_OnHide();
end

function FriendInfo_KVK_AjustLayout(IsDiffWorldFrind)
	if IsDiffWorldFrind == 1 then
		FriendInfo_KVK_Frame:SetProperty("UnifiedHeight", FriendInfo_Frame_DiffWorldFriend_Hight)
		--FriendInfo_KVK_PlayerHead_Frame:SetProperty("YPosition", FriendInfo_PlayerHead_DiffWorldFriend_YPosition)
		FriendInfo_KVK_FriendlyGrade:Hide()

		--屏蔽发送邮
		FriendInfo_KVK_Correspondence:Disable()
		FriendInfo_KVK_HistoryMessage:Disable()
	else
		FriendInfo_KVK_Frame:SetProperty("UnifiedSize", FriendInfo_Frame_Original_Size)
		FriendInfo_KVK_PlayerHead_Frame:SetProperty("UnifiedPosition", FriendInfo_PlayerHead_Position)
		FriendInfo_KVK_PlayerHead_Animate:SetProperty("UnifiedPosition", FriendInfo_PlayerHead_Position_Animate)
		FriendInfo_KVK_FriendlyGrade:Show()

		FriendInfo_KVK_Correspondence:Enable()
		FriendInfo_KVK_HistoryMessage:Enable()
	end
end


