
local g_XunZongCurrentChannel = "near";
local g_XunZongPrivate = "";
--===============================================
-- OnLoad()
--===============================================
function XunZong_PreLoad()

	this:RegisterEvent("TOGLE_XUN_ZONG",true);
	this:RegisterEvent("UPDATE_XUN_ZONG",false);
	this:RegisterEvent("XUNZONG_CHANGE_CURRENTCHANNEL",true)
	this:RegisterEvent("XUNZONG_CHANGE_PRIVATE",true);
end

function XunZong_OnLoad()

end

--===============================================
-- OnEvent()
--===============================================
function XunZong_OnEvent( event )
	if ( event == "TOGLE_XUN_ZONG" ) then	
		XunZong_Show( -1, -1 );
	elseif( event == "UPDATE_XUN_ZONG" ) then
		XunZong_Update( arg0, arg1 );
	elseif( event == "XUNZONG_CHANGE_CURRENTCHANNEL") then
		g_XunZongCurrentChannel = arg0;
	elseif (event == "XUNZONG_CHANGE_PRIVATE") then
		g_XunZongPrivate = arg0;
	end

end


--===============================================
-- UpdateFrame()
--===============================================
function XunZong_Update( nResult, nIndex )
	
	if( tonumber(nResult) == 0 ) then
        XunZong_Explain:Show();
        XunZong_Agname:Show();
        XunZong_Locus:Show();
        XunZong_fettle:Show();
        XunZong_TeamInfo:Show()
        local strFaceImage = DataPool:GetLookUpPartInfo( "PORTRAIT" );
        XunZong_PlayerHead:SetProperty("Image", tostring(strFaceImage));
	local PartnerGUID = DataPool:GetLookUpPartInfo( "ID_TEXT" )
	local PartnerGUIDText = ConvertGuidToShow( PartnerGUID )
        XunZong_ID:SetText( "ID:"..PartnerGUIDText );
        XunZong_Level:SetText( "级别:"..tostring( DataPool:GetLookUpPartInfo( "LEVEL" ) ) );
        XunZong_MenPai:SetText( "门派:"..DataPool:GetLookUpPartInfo( "MENPAI_TEXT" ) );
        
        local zoneWorldID     = DataPool:GetLookUpPartInfo( "ZONEWORLDID" )
        local selfZoneWorldID = DataPool:GetSelfZoneWorldID( )
        local targetName      = DataPool:GetLookUpPartInfo("NAME")

        if zoneWorldID ~= selfZoneWorldID and zoneWorldID ~= -1 and selfZoneWorldID ~= -1 then
            targetName = targetName.."@"..DataPool:GetServerName( tonumber( zoneWorldID ) )
        end

        XunZong_Name:SetText( "姓名:"..targetName );


        local serverID = DataPool:GetLookUpPartInfo( "SERVERID" );
        --- 如果是在K服那么要显示势力名称
        if 9 == serverID then

			local strGuidName = tostring(DataPool:GetLookUpPartInfo(  "GUID_NAME" ))
			if zoneWorldID ~= selfZoneWorldID and zoneWorldID ~= -1 and selfZoneWorldID ~= -1 and strGuidName ~="" then
				strGuidName = strGuidName .. "@" .. DataPool:GetServerName( tonumber( zoneWorldID ) )
			end
            XunZong_Confraternity:SetText( "#{TM_20080318_12}".. strGuidName );
            XunZong_GuildLeague:SetText( "心情:"..DataPool:GetLookUpPartInfo(  "MOOD" ) );
            XunZong_Explain:SetText( "称号:"..DataPool:GetLookUpPartInfo( "TITLE" ) );
            XunZong_Agname:SetText( "位置:"..DataPool:GetLookUpPartInfo( "POS" ) );
            XunZong_Locus:SetText( "状态:"..DataPool:GetLookUpPartInfo( "STATE" ) );
            XunZong_fettle:SetText( "队伍:"..DataPool:GetLookUpPartInfo( "TEAM_NUMBER" ) );
            XunZong_TeamInfo:Hide()

            this:Show();
        --- 如果是在原服，那么要显示帮会
        else
            XunZong_Confraternity:SetText( "帮会名称:"..DataPool:GetLookUpPartInfo(  "GUID_NAME" ) );
            XunZong_GuildLeague:SetText( "#{TM_20080311_30}"..DataPool:GetLookUpPartInfo("GUILD_LEAGUE_NAME") );
            XunZong_Explain:SetText( "心情:"..DataPool:GetLookUpPartInfo(  "MOOD" ) );
            XunZong_Agname:SetText( "称号:"..DataPool:GetLookUpPartInfo( "TITLE" ) );
            XunZong_Locus:SetText( "位置:"..DataPool:GetLookUpPartInfo( "POS" ) );
            --DataPool:GetLookUpPartInfo( "POS" );
            XunZong_fettle:SetText( "状态:"..DataPool:GetLookUpPartInfo( "STATE" ) );
            XunZong_TeamInfo:SetText( "队伍:"..DataPool:GetLookUpPartInfo( "TEAM_NUMBER" ) );
            XunZong_TeamInfo:Show()
            this:Show();
        end
    	XunZong_Fasongzuobiao:Enable();
	else
		XunZong_OnHide();
		--PushDebugMessage(tostring(nResult));
	end
end

function XunZong_Show( arg_0, arg_1 )
	XunZong_PlayerHead:SetProperty("Image", "");
	XunZong_ID:SetText( "ID:");
	XunZong_Name:SetText( "姓名:" );
	XunZong_Level:SetText( "级别:" );
	XunZong_MenPai:SetText( "门派:");
		--XunZong_Confraternity:SetText( "帮会名称:");
	XunZong_Confraternity:SetText( "#R正在查询,请稍候..." );
	XunZong_GuildLeague:SetText( "#{TM_20080311_30}");
		--XunZong_Explain:SetText( "心情:" );
	XunZong_Explain:Hide();
		--XunZong_Agname:SetText( "称号:" );
	XunZong_Agname:Hide();
		--XunZong_Locus:SetText( "位置:" );
	XunZong_Locus:Hide();
		--XunZong_fettle:SetText( "状态:");
	XunZong_fettle:Hide();
		--XunZong_TeamInfo:SetText( "队伍:" );
	XunZong_TeamInfo:Hide();
	PushEvent( "XUNZONG_GET_CURRENTCHANNEL" )
	this : Show();
end

function XunZong_OnHide()
	this:Hide();
end

function XunZong_AddFriend()
	local szName = DataPool:GetLookUpPartInfo("NAME");
	if(nil ~= szName and "" ~= szName) then
        local zoneWorldID = DataPool:GetLookUpPartInfo( "ZONEWORLDID" )
		DataPool:AddFriendAndGrouping( szName, zoneWorldID );
	end
end

function XunZong_SetPrivateName()
	local szName = DataPool:GetLookUpPartInfo("NAME");
	if(nil ~= szName and "" ~= szName) then
        local zoneWorldID = DataPool:GetLookUpPartInfo( "ZONEWORLDID" )
		Talk:ContexMenuTalk( szName, zoneWorldID );
	end
end

function XunZong_ShengQingTeam()
	local szName = DataPool:GetLookUpPartInfo("NAME");
	local zoneWorldID = DataPool:GetLookUpPartInfo( "ZONEWORLDID" )
	if(zoneWorldID ~= DataPool:GetSelfZoneWorldID()) then
		szName = szName.."@"..DataPool:GetServerName( tonumber( zoneWorldID ) )
	end
	
	if(nil ~= szName and "" ~= szName) then
		Target:SendTeamApply(szName);
	end
end


function XunZong_YaoQingTeam()
	local szName = DataPool:GetLookUpPartInfo("NAME");
	local zoneWorldID = DataPool:GetLookUpPartInfo( "ZONEWORLDID" )
	if(zoneWorldID ~= DataPool:GetSelfZoneWorldID()) then
		szName = szName.."@"..DataPool:GetServerName( tonumber( zoneWorldID ) )
	end
	
	if(nil ~= szName and "" ~= szName) then
		Target:SendTeamRequest(szName)
	end
end

function XunZong_Review()
	local friendguid = DataPool:GetLookUpPartInfo( "ID_TEXT" ) 
	local zoneWorldID = DataPool:GetLookUpPartInfo( "ZONEWORLDID" )
	local szName = DataPool:GetLookUpPartInfo("NAME")
	DataPool:LookupOtherParticularInfo( friendguid, zoneWorldID, szName );	
end

function XunZong_SendPos()
	local szSceneName, szX, szZ = DataPool:GetLookUpPartInfo( "STRINGPOS" );
	
    local zoneWorldID     = DataPool:GetLookUpPartInfo( "ZONEWORLDID" )
    local selfZoneWorldID = DataPool:GetSelfZoneWorldID( )
     local targetName      = DataPool:GetLookUpPartInfo("NAME")
	local strGuidName = tostring(DataPool:GetLookUpPartInfo(  "GUID_NAME" ))
		
     if zoneWorldID ~= selfZoneWorldID and zoneWorldID ~= -1 and selfZoneWorldID ~= -1 then
         targetName = targetName.."@"..DataPool:GetServerName( tonumber( zoneWorldID ) )
     end
    local strPos = "";
    if (strGuidName~=nil and strGuidName ~= "") then
    	strPos = string.format( "#G%s#W帮会的#G%s#W位置坐标：#G%s（%s，%s）#W", strGuidName, targetName, szSceneName, szX,  szZ )
	else
		strPos = string.format( "#G%s#W的位置坐标：#G%s（%s，%s）#W",  targetName, szSceneName, szX,  szZ )
	end
	
	Talk : SendChatMessage(g_XunZongCurrentChannel, g_XunZongPrivate..strPos );
	XunZong_Fasongzuobiao:Disable();
end




