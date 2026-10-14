local isShow = 0

function ChatInfo_PreLoad()
	this:RegisterEvent("CHAT_SHOWUSERINFO",true);
	
	this:RegisterEvent("TOGGLE_CHATINFO",true);
end

function ChatInfo_OnLoad()
end

--===============================================
-- OnEvent()
--===============================================
function ChatInfo_OnEvent( event )
	if ( event == "TOGGLE_CHATINFO" ) then
			ChatInfo_PreShow( );
	elseif(event == "CHAT_SHOWUSERINFO") then
		if arg0 ~= nil and tonumber(arg0) == 1 then --K服
			ChatInfo_ShowKVK()
		else
		ChatInfo_Show();
		end
	end
end


function ChatInfo_PreShow()
	isShow = 1
end
--===============================================
-- UpdateFrame()
-- 第几个频道的第几个人
--===============================================
function ChatInfo_Update()
	--AxTrace( 0,0,"char PORTRAIT" );
	local strFaceImage = DataPool:GetFriend( "chat", "PORTRAIT" );
	ChatInfo_PlayerHead:SetProperty("Image", tostring(strFaceImage));
	--AxTrace( 0,0,"char ID" );
	local FriendGuid = DataPool:GetFriend("chat","ID_TEXT");
	local FriendGuidText = ConvertGuidToShow(FriendGuid)
	ChatInfo_ID:SetText( "ID:"..FriendGuidText );
	--AxTrace( 0,0,"char NAME" );
	ChatInfo_Name:SetText( "姓名:"..DataPool:GetFriend( "chat", "NAME"  ) );
	--AxTrace( 0,0,"char LEVEL" );
	ChatInfo_Level:SetText( "级别:"..tostring( DataPool:GetFriend( "chat", "LEVEL" ) ) );
	--AxTrace( 0,0,"char MENPAI_TEXT" );
	ChatInfo_MenPai:SetText( "门派:"..DataPool:GetFriend( "chat", "MENPAI_TEXT" ) );
	--AxTrace( 0,0,"char GUID_NAME" );
	ChatInfo_Confraternity:SetText( "帮会名称:"..DataPool:GetFriend( "chat", "GUID_NAME" ) );
	ChatInfo_GuildLeague:SetText( "#{TM_20080311_30}"..DataPool:GetFriend( "chat", "GUILD_LEAGUE_NAME" ) );
	--AxTrace( 0,0,"char MOOD" );
	ChatInfo_Explain:SetText( "心情:"..DataPool:GetFriend( "chat", "MOOD" ) );
	--AxTrace( 0,0,"char TITLE" );
	ChatInfo_Agname:SetText( "称号:"..DataPool:GetFriend( "chat", "TITLE" ) );
	

	
	-- add 头像边框
	local iHeadFrameType = DataPool:GetFriend("chat", "HEADFRAMETYPE")
	if iHeadFrameType == 1 then
		ChatInfo_PlayerHead_Frame:SetProperty("Image", "")
		ChatInfo_PlayerHead_Frame:Hide()
		
		ChatInfo_PlayerHead_Animate:Show()
		local strHeadFrameAnimate = DataPool:GetFriend("chat", "HEADFRAMEANIMATE")
		ChatInfo_PlayerHead_Animate:SetProperty("Animate", tostring(strHeadFrameAnimate))
	else
		ChatInfo_PlayerHead_Animate:SetProperty("Animate", "")
		ChatInfo_PlayerHead_Animate:Hide()
		
		ChatInfo_PlayerHead_Frame:Show()
		local strHeadFrameImage = DataPool:GetFriend("chat", "HEADFRAME")
		local IconFile = GetIconFullName(strHeadFrameImage)
		ChatInfo_PlayerHead_Frame:SetProperty("Image", IconFile)
	end
end

function ChatInfo_UpdateKVK()
	local strFaceImage = DataPool:GetFriend( "chat", "PORTRAIT" );
	ChatInfo_PlayerHead:SetProperty("Image", tostring(strFaceImage));
	--AxTrace( 0,0,"char ID" );
	local FriendGuid = DataPool:GetFriend("chat","ID_TEXT");
	local FriendGuidText = ConvertGuidToShow(FriendGuid)
	ChatInfo_ID:SetText( "ID:"..FriendGuidText );
	--AxTrace( 0,0,"char NAME" );
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	local zoneWorldId = DataPool:GetFriend( "chat", "ZONEWORLDID" )
	local chatname = DataPool:GetFriend( "chat", "NAME" )
	if zoneWorldId ~= -1 and zoneWorldId ~= selfZoneWorldID then
		chatname = chatname .. "@" .. DataPool:GetServerName(zoneWorldId)
	end

	ChatInfo_Name:SetText( "姓名:"..chatname );
	--AxTrace( 0,0,"char LEVEL" );
	ChatInfo_Level:SetText( "级别:"..tostring( DataPool:GetFriend( "chat", "LEVEL" ) ) );
	--AxTrace( 0,0,"char MENPAI_TEXT" );
	ChatInfo_MenPai:SetText( "门派:"..DataPool:GetFriend( "chat", "MENPAI_TEXT" ) );
	--AxTrace( 0,0,"char GUID_NAME" );
	local guildname = DataPool:GetFriend( "chat", "GUID_NAME" )
	if zoneWorldId ~= -1 and zoneWorldId ~= selfZoneWorldID and guildname ~= "" then
		guildname = guildname .. "@" .. DataPool:GetServerName(zoneWorldId)
	end
	

	ChatInfo_Confraternity:SetText( "#{TM_20080318_12}".. guildname);
	--AxTrace( 0,0,"char MOOD" );
	ChatInfo_GuildLeague:SetText( "心情:"..DataPool:GetFriend( "chat", "MOOD" ) );
	--AxTrace( 0,0,"char TITLE" );
	ChatInfo_Explain:SetText( "称号:"..DataPool:GetFriend( "chat", "TITLE" ) );
	ChatInfo_Agname:SetText( "");
	
	-- add 头像边框
	local iHeadFrameType = DataPool:GetFriend("chat", "HEADFRAMETYPE")
	if iHeadFrameType == 1 then
		ChatInfo_PlayerHead_Frame:SetProperty("Image", "")
		ChatInfo_PlayerHead_Frame:Hide()
		
		ChatInfo_PlayerHead_Animate:Show()
		local strHeadFrameAnimate = DataPool:GetFriend("chat", "HEADFRAMEANIMATE")
		ChatInfo_PlayerHead_Animate:SetProperty("Animate", tostring(strHeadFrameAnimate))
	else
		ChatInfo_PlayerHead_Animate:SetProperty("Animate", "")
		ChatInfo_PlayerHead_Animate:Hide()
		
		ChatInfo_PlayerHead_Frame:Show()
		local strHeadFrameImage = DataPool:GetFriend("chat", "HEADFRAME")
		local IconFile = GetIconFullName(strHeadFrameImage)
		ChatInfo_PlayerHead_Frame:SetProperty("Image", IconFile)
	end
end



function ChatInfo_Show()
	if isShow == 1 then
		ChatInfo_Update();
		isShow = 0
		this:Show();	
	end

end
function ChatInfo_ShowKVK()
	if isShow == 1 then
		ChatInfo_UpdateKVK();
		isShow = 0
		this:Show();
	end
end

function ChatInfo_OnHide()
	isShow = 0
	this:Hide();
end

function ChatInfo_OnHelp()
end

function ChatInfo_AddFriend()
	local szName = DataPool:GetFriend( "chat", "NAME"  );
	local zoneWorldId = DataPool:GetFriend( "chat", "ZONEWORLDID"  );
	local strCharName =  Player:GetName();
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()

	if strCharName == szName and (tonumber(zoneWorldId) == -1 or (zoneWorldId == selfZoneWorldID)) then
		PushDebugMessage("#{TDGZ_100809_83}")
		return
	end
	if(nil ~= szName and "" ~= szName) then
		DataPool:AddFriendAndGrouping( szName, zoneWorldId);
	end
end

function ChatInfo_SetPrivateName()
	local szName = DataPool:GetFriend( "chat", "NAME"  );
	local zoneworldid = DataPool:GetFriend("chat", "ZONEWORLDID")
	if(nil ~= szName and "" ~= szName) then
		Talk:ContexMenuTalk(szName, zoneworldid);
	end
end

function ChatInfo_ShengQingTeam()
	local szName = DataPool:GetFriend( "chat", "NAME"  );
	local zoneworldid = DataPool:GetFriend("chat", "ZONEWORLDID")
	if(nil ~= szName and "" ~= szName) then
		Friend:AskTeam( szName, tonumber(zoneworldid));
	end
end


function ChatInfo_YaoQingTeam()
	local szName = DataPool:GetFriend( "chat", "NAME"  );
	local zoneworldid = DataPool:GetFriend("chat", "ZONEWORLDID")
	if(nil ~= szName and "" ~= szName) then
		Friend:InviteTeam( szName, tonumber(zoneworldid));
	end
end
