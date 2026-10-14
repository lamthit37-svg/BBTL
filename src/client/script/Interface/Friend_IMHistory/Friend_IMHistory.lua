--gloable
-- 界面的默认位置
local g_UnifiedXPosition;
local g_UnifiedYPosition;

local MAX_GROUP = 20;
local GROUP_CHAT_INDEX = 19;

local curHistroyPointer = 0;
local maxHistroyNumber = 0;
local curFriendGroup = 0;
local curFriendIndex = 0;
local numberPerPage = 10;
local maxHistroyPage = 0;
local g_IsTeamOutLine={};
local g_TeamOutLineStr={};
local g_IsGroupShow = false;
local curChatGroupID = 0;
local g_curFirstPos = -1;    --记录位置 防止刷新list 位置回滚

local g_SpecialFriendOutLine = {}

--===============================================
-- OnLoad()
--===============================================
function Friend_IMHistory_PreLoad()
	this:RegisterEvent("OPEN_IM_CHAT_HISTORY");
	this:RegisterEvent("OPEN_IM_GROUP_HISTORY");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 刷新界面
	this:RegisterEvent("UPDATE_CHAT_HISTORY")
end

function Friend_IMHistory_OnLoad()
	-- 保存界面的默认相对位置
	g_UnifiedXPosition	= Friend_IMHistory_Frame:GetProperty("UnifiedXPosition");
	g_UnifiedYPosition	= Friend_IMHistory_Frame:GetProperty("UnifiedYPosition");
	
	g_IsTeamOutLine = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	g_TeamOutLineStr = {
							"我的好友"	,
							"分组一"	,
							"分组二" 	,
							"分组三"	,
							"黑名单"	,
							"仇人"		,
							[8] = "天外好友一" 	,
							[9] = "天外好友二"	,
							[10] = "天外黑名单"	,
							[11] = "天外仇人"		,
							[13] = "临时好友",
							[14] = "天外临时好友",
							[19] = "我的群",
						}
	g_curFirstPos = -1;
	
	g_SpecialFriendOutLine = {0,0,0,0}
	
end

--===============================================
-- OnEvent()
--===============================================
function Friend_IMHistory_OnEvent( event )

	if ( event == "OPEN_IM_CHAT_HISTORY" ) then --私聊
		g_IsTeamOutLine = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		local nGroup = tonumber(arg0);
		local nIndex = tonumber(arg1);

		if(nGroup == 0 and nIndex == 0) then
			Friend_IMHistory_ListUpdate();
			Friend_IMHistory_Chat_Show( 0, 0 );
			return;
		elseif(nGroup<0 or nIndex<0) then
			PushDebugMessage("#{LTQH_XML_83}");
			Friend_IMHistory_ListUpdate();
			Friend_IMHistory_Chat_Show( 0, 0 );
			return;
		else
			g_IsTeamOutLine[nGroup] = 1;
			Friend_IMHistory_ListUpdate();
			--if nGroup >= 8 and nGroup ~= 13 then
			--	PushDebugMessage("#{YBFQ_XML_10}")
			--	return
			--end
			-- 这里需要+1，因为最上面还有一行是联系人
			if nGroup == 13 then				
				Friend_IMHistory_FriendList:SetItemSelect(7+nIndex+1);  --临时好友特殊处理
			else
				Friend_IMHistory_FriendList:SetItemSelect(nGroup+nIndex+1);
			end
			Friend_IMHistory_Chat_Show( nGroup, nIndex );
		end
	end
	if (event == "OPEN_IM_GROUP_HISTORY") then
		local nChatGroupID = tonumber(arg0);
		--PushDebugMessage("nChatGroupID" .. nChatGroupID);
		g_IsTeamOutLine = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		g_IsTeamOutLine[GROUP_CHAT_INDEX] = 1;
		Friend_IMHistory_ListUpdate();
		local i;
		local j = 0;
		for i = 0,MAX_GROUP-1 do
			local id , name ,count ,ownerid = DataPool:GetChatGroupInfoByIndex(i);
			if(id == nChatGroupID)then
				Friend_IMHistory_FriendList:SetItemSelect(9); 
				Friend_IMHistory_Group_Show(nChatGroupID);
				break;
			end
			if(id ~= -1) then
				j=j+1
			end
		end
	elseif( event == "ADJEST_UI_POS" ) then
		Friend_IMHistory_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Friend_IMHistory_ResetPos()
	elseif( event == "UPDATE_CHAT_HISTORY" ) then
		if(IsWindowShow("Friend_IMHistory")) then
			PushEvent("OPEN_IM_CHAT_HISTORY",0,0);
		end
	end

end

--显示私聊信息
function Friend_IMHistory_Chat_Show( nChannel, nIndex )
	g_IsGroupShow = false;
	curFriendGroup = tonumber(nChannel);
	curFriendIndex = tonumber(nIndex);
	maxHistroyNumber = Friend:GetIMChatNumber( curFriendGroup, curFriendIndex );
	curHistroyPointer = maxHistroyNumber;

	Friend_IMHistory_ContentUpdate();
	this:Show();
end

--显示群聊信息
function Friend_IMHistory_Group_Show( nGroupID)
	g_IsGroupShow = true;
	curChatGroupID = tonumber(nGroupID);
	maxHistroyNumber = DataPool:GetIMGroupChatNumber(curChatGroupID);
	curHistroyPointer = maxHistroyNumber;

	Friend_IMHistory_ContentUpdate();
	this:Show();
end

--===============================================
-- OnUpdate()
--===============================================
function Friend_IMHistory_ContentUpdate()
	local i = curHistroyPointer -1 ;
	local minHistroyPointer = curHistroyPointer - numberPerPage;
	if( minHistroyPointer < 0 ) then
		minHistroyPointer = 0;
	end

	if( minHistroyPointer == 0 ) then
		Friend_IMHistory_GotoNextPage:Disable();
	else
		Friend_IMHistory_GotoNextPage:Enable();
	end
	if( curHistroyPointer == maxHistroyNumber ) then
		Friend_IMHistory_GotofrontPage:Disable();
	else
		Friend_IMHistory_GotofrontPage:Enable();
	end

	Friend_IMHistory_HistoryContent:ClearListBox();

	if(g_IsGroupShow == false) then --私聊
		local str = "";
		while i >= minHistroyPointer do
			str = Friend:GetIMChatData( tonumber( curFriendGroup ), tonumber( curFriendIndex ), tonumber(i), "TIME" );
			str = str.." "..Friend:GetIMChatData( tonumber( curFriendGroup ), tonumber( curFriendIndex ), tonumber(i), "SENDER" );
			str = str.."#r";
			str = str..Friend:GetIMChatData( tonumber( curFriendGroup ), tonumber( curFriendIndex ), tonumber(i), "CONTEX" )
			Friend_IMHistory_HistoryContent:AddItem( str, i, "FFFFFFFF", 4 );
			i = i - 1;
		end
	elseif (g_IsGroupShow == true) then --群聊
		local str = "";
		while i >= minHistroyPointer do
			str = DataPool:GetIMGroupChatData( tonumber( curChatGroupID ), tonumber(i), "TIME" );
			str = str.." "..DataPool:GetIMGroupChatData( tonumber( curChatGroupID ), tonumber(i), "SENDER" );
			str = str.."#r";
			str = str..DataPool:GetIMGroupChatData( tonumber( curChatGroupID ), tonumber(i), "CONTEX" )
			Friend_IMHistory_HistoryContent:AddItem( str, i, "FFFFFFFF", 4 );
			i = i - 1;
		end
	end
	--设置页数显示
	local curpage = tonumber((maxHistroyNumber - curHistroyPointer) / numberPerPage);
	curpage = math.floor( curpage ) + 1;
	if(maxHistroyNumber == 0) then
		curpage = 0;
	end
	maxHistroyPage = math.ceil(tonumber(maxHistroyNumber / numberPerPage ));
	Friend_IMHistory_CurPageNumber:SetText(tostring(curpage .. "/" .. maxHistroyPage));

end

function Friend_IMHistory_ListUpdate()

	Friend_IMHistory_FriendList:ClearListBox();
	--一共7组 ，临时好友单独处理
	Friend_IMHistory_FriendList:AddItem( "#gFE7E82".."#{LTQH_XML_11}", 0 )
	
	Friend_IMHistory_SpecialFriendUpdate()	
	
	for i = 1 , 7 do
		local j = i
		if i == 7 then
			j = 13
		end

		local strOutlineName = ""
		local strTitle = ""
		if(j>=1 and j<=4) then
			strTitle = DataPool:GetGroupingNameByIndex(i-1);
		else
			strTitle = g_TeamOutLineStr[j];
		end

		if g_IsTeamOutLine[j] == 1 then
			strOutlineName = "#gFE7E82- " .. strTitle;
		else
			strOutlineName = "#gFE7E82+ " .. strTitle;
		end

		if( strOutlineName ~= "" or strOutlineName ~= 0 ) then
			local iStart = j*10000;
			local friendnumber = DataPool:GetFriendNumberCommon( tonumber( j ) )
			local relealFriendNumber = DataPool:GetFriendNumber( tonumber( j ) )

			if friendnumber < 1 then
				strOutlineName = "#gFE7E82- " .. strTitle;
			end
			Friend_IMHistory_FriendList:AddItem( "    " .. strOutlineName, iStart )
			if( 1 == g_IsTeamOutLine[ j ] and friendnumber >= 1) then
				local index=0;
				while index < relealFriendNumber  do
					if Friend_IMHistory_ShowInCommonFriendGroup( j, index ) == 1 then			--  7:师傅 8：徒弟 3：结婚 2：结拜
						local name = DataPool:GetFriend( j, index, "NAME" )
						Friend_IMHistory_FriendList:AddItem( "        " .. name, iStart + index + 1, "FFFFFFFF", 4 )
					end
					index = index + 1
				end
			end
		end
	end
	--群列表
	local strOutlineGroup;
	if g_IsTeamOutLine[GROUP_CHAT_INDEX] == 1 then
			strOutlineGroup = "#gFE7E82- " .. g_TeamOutLineStr[GROUP_CHAT_INDEX]
	else
		strOutlineGroup = "#gFE7E82+ " .. g_TeamOutLineStr[GROUP_CHAT_INDEX]
	end
	if( strOutlineGroup ~= "" or strOutlineGroup ~= 0 ) then
		local iStart = 190000;
		local groupNumber = tonumber(DataPool:GetChatGroupNumber( ));
		if groupNumber < 1 then
			strOutlineGroup = "#gFE7E82- " .. g_TeamOutLineStr[GROUP_CHAT_INDEX];
		end
		Friend_IMHistory_FriendList:AddItem( "    " .. strOutlineGroup, iStart )
		if( 1 == g_IsTeamOutLine[ GROUP_CHAT_INDEX ] ) then
			for i = 0 ,MAX_GROUP - 1 do
				local id , name ,count ,ownerid = DataPool:GetChatGroupInfoByIndex(i)
				if id ~= -1 then
					Friend_IMHistory_FriendList:AddItem(  "        " .. name.."["..tostring(count).."]",iStart + i+1 ,"FFFFFFFF", 4);
				end
			end
		end
	end
	Friend_IMHistory_FriendList:AddItem( "#gFE7E82".."天外联系人", 0 )
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	--天外一共5组 ，天外临时好友单独处理
	for i = 8 , 12 do
		local j = i
		if i == 12 then
			j = 14
		end

		local strOutlineName = ""
		local strTitle = ""
		--if(j>=8 and j<=9) then
		--	strTitle = DataPool:GetGroupingNameByIndex(i-1);
		--else
		strTitle = g_TeamOutLineStr[j];
		--end

		if g_IsTeamOutLine[j] == 1 then
			strOutlineName = "#gFE7E82- " .. strTitle;
		else
			strOutlineName = "#gFE7E82+ " .. strTitle;
		end

		if( strOutlineName ~= "" or strOutlineName ~= 0 ) then
			local iStart = j*10000;
			local friendnumber = DataPool:GetFriendNumber( tonumber( j ) );
			if friendnumber < 1 then
				strOutlineName = "#gFE7E82- " .. strTitle;
			end
			Friend_IMHistory_FriendList:AddItem( "    " .. strOutlineName, iStart )
			if( 1 == g_IsTeamOutLine[ j ] and friendnumber >= 1) then
				local index=0;
				while index < friendnumber  do
					local name = DataPool:GetFriend( j, index, "NAME" );
					--PushDebugMessage(name);
					local zoneWorldID = DataPool:GetFriend(j, index, "ZONEWORLDID" )
					if zoneWorldID ~= -1 and zoneWorldID ~= selfZoneWorldID then
						name = name .. "@" .. DataPool:GetServerName(zoneWorldID)
					end
					Friend_IMHistory_FriendList:AddItem( "        " .. name, iStart + index + 1, "FFFFFFFF", 4 );
					index = index + 1;
				end
			end
		end
	end
	if g_curFirstPos ~= -1 then
		Friend_IMHistory_FriendList:SetCurrentFirstItem(g_curFirstPos);
		g_curFirstPos = -1
	end
end
--===============================================
-- OnButtonClick()
--===============================================
--下一页
function Friend_IMHistory_OnPageDown()
	curHistroyPointer = curHistroyPointer - numberPerPage;
	if( curHistroyPointer < 0 ) then
		curHistroyPointer = 0;
	end
	Friend_IMHistory_ContentUpdate();
end
--上一页
function Friend_IMHistory_OnPageUp()
	curHistroyPointer = curHistroyPointer + numberPerPage;
	if( curHistroyPointer > maxHistroyNumber ) then
		curHistroyPointer = maxHistroyNumber;
	end
	Friend_IMHistory_ContentUpdate();
end
--转到
function Friend_IMHistory_GotoPage()
	local nPage = tonumber(Friend_IMHistory_GotoPageNumber:GetText());
	if(nPage == nil) then
		return;
	end
	if( nPage > maxHistroyPage)then
		nPage = maxHistroyPage;
	elseif( nPage <= 0 ) then
		nPage = 1;
	end
	Friend_IMHistory_GotoPageNumber:SetText(nPage);
	curHistroyPointer = maxHistroyNumber - (nPage - 1) * numberPerPage;
	if( curHistroyPointer < 0 ) then
		curHistroyPointer = 0;
	elseif 	( curHistroyPointer > maxHistroyNumber ) then
		curHistroyPointer = maxHistroyNumber;
	end

	Friend_IMHistory_ContentUpdate();
end

--选中列表
function Friend_IMHistory_ListSelectChanged()
	local nSelIndex = Friend_IMHistory_FriendList:GetFirstSelectItem();

	local ItemIndex = math.mod( nSelIndex, 10000 )
	local TitleIndex = math.floor( nSelIndex / 10000 );

	if( 0 == ItemIndex ) then --选中大项
		
		if TitleIndex > 100 then
		
			local iFloorMode = math.mod( TitleIndex, 100 ) 
				
			if( 0 == g_SpecialFriendOutLine[ iFloorMode ] ) then
				g_SpecialFriendOutLine[ iFloorMode ] = 1
			else
				g_SpecialFriendOutLine[ iFloorMode ] = 0
			end
			
		else
		
			if( 0 == g_IsTeamOutLine[ TitleIndex ] ) then
				g_IsTeamOutLine[ TitleIndex ] = 1
			else
				g_IsTeamOutLine[ TitleIndex ] = 0
			end
			
		end
		
		g_curFirstPos = Friend_IMHistory_FriendList:GetCurrentFirstItem();
		Friend_IMHistory_ListUpdate();
		if(TitleIndex == GROUP_CHAT_INDEX) then

		else
			Friend_IMHistory_Chat_Show(0,0);
		end
	else   --选中小项
		if(TitleIndex == GROUP_CHAT_INDEX) then
			local id , name ,count ,ownerid = DataPool:GetChatGroupInfoByIndex(ItemIndex - 1);
			Friend_IMHistory_Group_Show(id);
		else
			Friend_IMHistory_Chat_Show(TitleIndex,ItemIndex - 1);
		end
	end
end

--双击
function Friend_IMHistory_ListDoubleClick()
	local nSelIndex = Friend_IMHistory_FriendList:GetFirstSelectItem();

	local ItemIndex = math.mod( nSelIndex, 10000 )
	local TitleIndex = math.floor( nSelIndex / 10000 );

	if( 0 ~= ItemIndex ) then --选中小项
		if(TitleIndex == GROUP_CHAT_INDEX) then
			local id , name ,count ,ownerid = DataPool:GetChatGroupInfoByIndex(ItemIndex - 1);
			if(id > -1) then
				DataPool:OpenGroupChat(id)
			end
		else
			--Friend_IMHistory_Chat_Show(TitleIndex,ItemIndex - 1);
			if( TitleIndex == 5 ) then
				return;
			end
			if( TitleIndex == 6 ) then
				PushDebugMessage("与对方为仇人关系，仅可以使用右键菜单。")
				return;
			end
			Friend:SetCurrentSelect( ItemIndex - 1);
			Friend:SetCurrentTeam( TitleIndex );
			DataPool:Open1On1Chat(TitleIndex , ItemIndex - 1)
		end
	end
end

--右键
function Friend_IMHistory_OpenMenu()

	local nSelIndex = Friend_IMHistory_FriendList:GetFirstSelectItem();

	local ItemIndex = math.mod( nSelIndex, 10000 )
	local TitleIndex = math.floor( nSelIndex / 10000 );

	if( 0 ~= ItemIndex ) then --选中小项
		if(TitleIndex == GROUP_CHAT_INDEX) then
			local id , name ,count ,ownerid = DataPool:GetChatGroupInfoByIndex(ItemIndex - 1);
			if(id > -1) then
				Friend:OpenGroupListMenu( tostring( id) );
			end
		else
			Friend:SetCurrentSelect( ItemIndex - 1);
			Friend:SetCurrentTeam( TitleIndex );
			if( nSelIndex > -1 ) then
				Friend:OpenMenu( tostring( TitleIndex), tostring( ItemIndex - 1 ) );
			end
		end
	end

end


--刷新
function Friend_IMHistory_Refresh()
	if(g_IsGroupShow == false) then
		Friend_IMHistory_Chat_Show(curFriendGroup,curFriendIndex);
	else
		Friend_IMHistory_Group_Show(curChatGroupID);
	end
end

--导出
function Friend_IMHistory_Export()
	local result,fileName;
	if(g_IsGroupShow == false) then
		result,fileName = Talk:SaveIMChatHistory(1,curFriendGroup,curFriendIndex);
	else
		result,fileName = Talk:SaveIMChatHistory(2,curChatGroupID,0);
	end
	if(result == nil or tonumber(result) == -2 )then
		PushDebugMessage("#{LTQH_XML_66}");
	elseif(tonumber(result) == -1) then
		PushDebugMessage("#{LTQH_XML_67}");
	else
		PushDebugMessage("#{LTQH_XML_68} " .. fileName);
	end
end


function Friend_IMHistory_OnHidden()

end

function Friend_IMHistory_ResetPos()
	Friend_IMHistory_Frame:SetProperty("UnifiedXPosition", g_UnifiedXPosition);
	Friend_IMHistory_Frame:SetProperty("UnifiedYPosition", g_UnifiedYPosition);
end

function Friend_IMHistory_SpecialFriendUpdate()
	--婚姻组
	local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()
	if isHaveSpouse == 1 then
	
		local strOutlineName = "我的婚姻"
		if g_SpecialFriendOutLine[ 1 ] == 1 then
			strOutlineName = "#gFE7E82- " .. strOutlineName
		else
			strOutlineName = "#gFE7E82+ " .. strOutlineName
		end
		
		local iStart = 101*10000
		Friend_IMHistory_FriendList:AddItem( "    " ..strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 1 ] == 1 then
			local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(spouseGuid)
			if nGroup ~= nil and nIndex ~= nil then
				if nGroup >= 0 and nIndex >= 0 then
					local name = DataPool:GetFriend( nGroup, nIndex, "NAME" )
					Friend_IMHistory_FriendList:AddItem( "        " .. name, nGroup * 10000 + nIndex + 1, "FFFFFFFF", 4 )
				end
			end
		end
	end
	
	--结拜组 ，不包括已经出现在婚姻组的成员
	local nBrotherCount = DataPool:GetBrotherCount()
	local nBrotherListNum = Friend:Lua_GetBrotherNumExceptSpouse()
	
	if nBrotherListNum > 0 then
	
		local strOutlineName = "我的结拜"
		if g_SpecialFriendOutLine[ 2 ] == 1 then
			strOutlineName = "#gFE7E82- " .. strOutlineName
		else
			strOutlineName = "#gFE7E82+ " .. strOutlineName
		end
		
		local iStart = 102*10000
		Friend_IMHistory_FriendList:AddItem( "    " ..strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 2 ] == 1 then
			local selfPos = DataPool:GetSelfBrotherInfo("CharPos")
			for ind = 1, nBrotherCount do
				local charPos = DataPool:GetBrotherInfoByInd(ind - 1, "CharPos")
				local nBrotherGuid = DataPool:GetBrotherInfoByInd(ind - 1, "CharGuid")
				if charPos >= 0 and charPos <= 5 and charPos ~= selfPos then
					if nBrotherGuid ~= nil and nBrotherGuid ~= spouseGuid then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nBrotherGuid)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								local name = DataPool:GetFriend( nGroup, nIndex, "NAME" )
								Friend_IMHistory_FriendList:AddItem( "        " .. name, nGroup * 10000 + nIndex + 1, "FFFFFFFF", 4 )
							end
						end
					end
				end
			end

		end
	end
	
	--师门组 ，不包括已经出现在婚姻组和结拜组的成员
	local nShimenMemberNumExceptSpouseAndBrother= Friend:Lua_GetShimenMemberNumExceptSpouseAndBrother()
	local nOnlineShimenMemberNumExceptSpouseAndBrother= Friend:Lua_GetOnlineShimenMemberNumExceptSpouseAndBrother()
	if nShimenMemberNumExceptSpouseAndBrother > 0 then
	
		local strOutlineName = "我的师门"
		if g_SpecialFriendOutLine[ 3 ] == 1 then
			strOutlineName = "#gFE7E82- " .. strOutlineName
		else
			strOutlineName = "#gFE7E82+ " .. strOutlineName
		end
		
		local iStart = 103*10000
		Friend_IMHistory_FriendList:AddItem( "    " ..strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 3 ] == 1 then

			local myrank = 8
			for i=0,8 do
				local nGUID,	szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,1)

				if nGUID ~= nil and nGUID ~= spouseGuid then	--不是配偶
					local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
					if nGroup ~= nil and nIndex ~= nil then
						if nGroup >= 1 and nGroup <= 4 and nIndex >= 0 then
							if DataPool:GetFriend( nGroup, nIndex, "RELATION_TYPE" ) ~= 2 then -- 不是结拜
								local name = DataPool:GetFriend( nGroup, nIndex, "NAME" )
								Friend_IMHistory_FriendList:AddItem( "        " .. name, nGroup * 10000 + nIndex + 1, "FFFFFFFF", 4 )	
							end
						end
					end
				end
			end
		end
	end
	
	--徒弟组
	local nRecruitNum = Friend:Lua_GetRecruitNum()
	if nRecruitNum > 0 then
	
		local strOutlineName = "我的徒弟"
		if g_SpecialFriendOutLine[ 4 ] == 1 then
			strOutlineName = "#gFE7E82- " .. strOutlineName
		else
			strOutlineName = "#gFE7E82+ " .. strOutlineName
		end
		
		local iStart = 104*10000
		Friend_IMHistory_FriendList:AddItem( "    " ..strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 4 ] == 1 then

			for i=0,8 do
				local nGUID,szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,2)
				if nType == 2 and szCharName ~= "" then
					if nGUID ~= nil then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								local name = DataPool:GetFriend( nGroup, nIndex, "NAME" )
								Friend_IMHistory_FriendList:AddItem( "        " .. name, nGroup * 10000 + nIndex + 1, "FFFFFFFF", 4 )
							end
						end
					end
				end
			end
		end
	end
	
end


function Friend_IMHistory_ShowInCommonFriendGroup(  nChannel, nIndex )
	
	if nChannel < 1 or nChannel > 4 then
		return 1
	end
	
	local nRelationType = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" )
	local guid =  DataPool:GetFriend( nChannel, nIndex, "ID" )
	
	if nRelationType == 7 and Friend:Lua_IsShimenMemberInfoValid() == 1 then		--师傅
		return 0
	end
	
	if nRelationType == 8 then		--徒弟
		return 0
	end
	
	if nRelationType == 3 then		--配偶
		return 0
	end 
	
	if nRelationType == 2 then		--结拜
		return 0
	end 
	
	if Friend:Lua_IsShimenMemberInfoValid() == 1 and Friend:Lua_IsSameMasterWithMe(guid) == 1 then
		return 0
	end
	
	return 1

end
