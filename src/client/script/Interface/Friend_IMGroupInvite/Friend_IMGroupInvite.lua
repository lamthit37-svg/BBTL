-- 界面的默认位置
local g_UnifiedXPosition;
local g_UnifiedYPosition;

local g_IsTeamOutLine = {}
local g_TeamOutLineStr = {}
local g_GroupID = -1

local g_imgStatus = {}

local g_SpecialFriendOutLine = {}

function Friend_IMGroupInvite_PreLoad()
	this:RegisterEvent("OPEN_IMGROUP_INVITE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function Friend_IMGroupInvite_OnLoad()
	-- 保存界面的默认相对位置
	g_UnifiedXPosition	= Friend_IMGroupInvite_Frame:GetProperty("UnifiedXPosition");
	g_UnifiedYPosition	= Friend_IMGroupInvite_Frame:GetProperty("UnifiedYPosition");
	
	
	g_IsTeamOutLine = {0,0,0,0}
	g_TeamOutLineStr = {
							"#{LTQH_XML_79}"	,
							"#{LTQH_XML_80}"	,
							"#{LTQH_XML_81}" 	,
							"#{LTQH_XML_82}"	,
						}
	g_imgStatus = {
			[0] = { [0] = "#-27" ,[1] = "#-29" ,[2] = "#-30"} ,
			[1] = { [0] = "#-23" ,[1] = "#-25" ,[2] = "#-26"} ,
		}
		
	g_SpecialFriendOutLine = {0,0,0,0}
end


function Friend_IMGroupInvite_OnEvent(event)
	if ( event == "OPEN_IMGROUP_INVITE" ) then
		g_GroupID = tonumber(arg0)
		Friend_IMGroupInvite_Show()
	elseif( event == "ADJEST_UI_POS" ) then
		Friend_IMGroupInvite_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Friend_IMGroupInvite_ResetPos()
	end
end


function Friend_IMGroupInvite_Hide()
	this:Hide()
end
function Friend_IMGroupInvite_Show()
	Friend_IMGroupInvite_FriendList:ClearListBox()
	Friend_IMGroupInvite_InvitedList:ClearListBox()
	local strGroupName = ""
	for i = 0 , 3 do
		strGroupName = DataPool:GetGroupingName(i)
		if strGroupName ~= "" then
			g_TeamOutLineStr[i+1] = strGroupName
		end
	end
	Friend_IMGroupInvite_FriendList_Update()
	this:Show()
end

function Friend_IMGroupInvite_FriendList_Update()
	Friend_IMGroupInvite_FriendList:ClearListBox()
	
	Friend_IMGroupInvite_SpecialFriendUpdate()
	
--一4组好友 ，不包括黑名单、仇人、临时好友
	for i = 1 , 4 do
		local strOutlineName = ""
		if g_IsTeamOutLine[i] == 1 then
			strOutlineName = "#gFE7E82- " .. g_TeamOutLineStr[i]
		else
			strOutlineName = "#gFE7E82+ " .. g_TeamOutLineStr[i]
		end
		
		if( strOutlineName ~= "" or strOutlineName ~= 0 ) then
			local iStart = i*10000;
			local friendnumber = DataPool:GetFriendNumberCommon( tonumber( i ) )
			local relealFriendNumber = DataPool:GetFriendNumber( tonumber( i ) )
			if friendnumber < 1 then 
				strOutlineName = "#gFE7E82- " .. g_TeamOutLineStr[i]
			end
			Friend_IMGroupInvite_FriendList:AddItem( strOutlineName, iStart )
			if( 1 == g_IsTeamOutLine[ i ] ) then
				local index=0;
				while index < relealFriendNumber  do
				
					if Friend_IMGroupInvite_ShowInCommonFriendGroup( i, index ) == 1 then
						local name = DataPool:GetFriend( i, index, "NAME" );
						local friendship = DataPool:GetFriend( i, index, "FRIENDSHIP" );
						local relationtype = DataPool:GetFriend( i, index, "RELATION_TYPE" );
					
						local namecolor = "#cC4B299";

						local IMst = DataPool:GetFriend( i, index, "IM_STATUS" );
						local Sex = DataPool:GetFriend( i, index, "SEX" );
						local playerIcon = "    "	
						
						if( DataPool:GetFriend( i, index, "ONLINE" ) ) then

							if( relationtype == 7 or relationtype == 8) then
								namecolor = "#cFF6600";	
							elseif( relationtype == 3 ) then
								namecolor = "#cF246F0";		
							elseif( relationtype == 2 ) then
								namecolor = "#c007EFF";		
							elseif( friendship >= 10 ) then 
									namecolor = "#c00FF00";		
							elseif( friendship >= 1 ) then	
									namecolor = "#c00C800";		
							elseif( friendship == 0 ) then	
									namecolor = "#cFFFFFF";		
							end

							if tonumber(IMst) >= 0 and tonumber(IMst) <=2  and tonumber(Sex) >=0 and tonumber(Sex) <= 1 then
								playerIcon = g_imgStatus[Sex][IMst]
							end
							Friend_IMGroupInvite_FriendList:AddItem("  "..playerIcon..namecolor..name , iStart + index + 1)
						else
							Friend_IMGroupInvite_FriendList:AddItem("  "..playerIcon..namecolor..name , iStart + index + 1)
						end
					end
					
					index = index + 1;
				end
			end
		end
	end
end

function Friend_IMGroupInvite_FriendList_SelectChanged()
	local nSelIndex = Friend_IMGroupInvite_FriendList:GetFirstSelectItem();
	local iMod = math.mod( nSelIndex, 10000 )
	local iFloor = math.floor( nSelIndex / 10000 );
	if( 0 == iMod ) then
		
		if iFloor > 100 then
			
			local iFloorMode = math.mod( iFloor, 100 ) 
				
			if( 0 == g_SpecialFriendOutLine[ iFloorMode ] ) then
				g_SpecialFriendOutLine[ iFloorMode ] = 1
			else
				g_SpecialFriendOutLine[ iFloorMode ] = 0
			end
			
		else
		
			if( 0 == g_IsTeamOutLine[ iFloor ] ) then
				g_IsTeamOutLine[ iFloor ] = 1
			else
				g_IsTeamOutLine[ iFloor ] = 0
			end
			
		end
		
		Friend_IMGroupInvite_FriendList_Update()
		return
	end	
end


function Friend_IMGroupInvite_Add_One()
	local index = Friend_IMGroupInvite_FriendList:GetFirstSelectItem();
	if index < 0 then
		return
	end
	local iMod = math.mod( index, 10000 )
	local iFloor = math.floor( index / 10000 );

	local name = DataPool:GetFriend( iFloor, iMod - 1, "NAME" );
	
	local isHave = Friend_IMGroupInvite_InvitedList:GetItemNumByItemId(index)
	if isHave == -1 then
		Friend_IMGroupInvite_InvitedList:AddItem(name ,	index );	
	end

end


function Friend_IMGroupInvite_Del_One()
	local itemID = Friend_IMGroupInvite_InvitedList:GetFirstSelectItem();
	if itemID < 0 then
		return
	end
	local index = Friend_IMGroupInvite_InvitedList:GetItemNumByItemId(itemID)
	if index >= 0 then
		Friend_IMGroupInvite_InvitedList:DelItem(index);
	end
		
end


function Friend_IMGroupInvite_Invite()
	
	local ownerid = DataPool:GetChatGroupChiefIDByGroupID(g_GroupID)
	local myGuid = Player:GetGUID();
	if ownerid ~= myGuid then
		local ret = DataPool:IsChatGroupAllowMemberInvite(g_GroupID)
		if ret == 0 then
			PushDebugMessage("#{JLQH_101026_06}")
			return
		end	
	end
	
	local num = Friend_IMGroupInvite_InvitedList:GetItemNumber()
	if num < 1 then
		return
	end

	PushDebugMessage("#{JLQH_101026_21}")
	for i = 1 , num  do
		local str , itemID = Friend_IMGroupInvite_InvitedList:GetItem(i)
		
		local iMod = math.mod( itemID, 10000 )
		local iFloor = math.floor( itemID / 10000 );

		DataPool:InviteFriendJoinGroup(iFloor, iMod - 1 , g_GroupID);
	end
	Friend_IMGroupInvite_Hide()
end


function Friend_IMGroupInvite_FriendList_DClicked()
	local index = Friend_IMGroupInvite_FriendList:GetFirstSelectItem();
	if index < 0 then
		return
	end
	local iMod = math.mod( index, 10000 )
	local iFloor = math.floor( index / 10000 );

	local name = DataPool:GetFriend( iFloor, iMod - 1, "NAME" );
	
	local isHave = Friend_IMGroupInvite_InvitedList:GetItemNumByItemId(index)
	if isHave == -1 then
		Friend_IMGroupInvite_InvitedList:AddItem(name ,	index );	
	end
end

function Friend_IMGroupInvite_InvitedList_DClicked()
	local itemID = Friend_IMGroupInvite_InvitedList:GetFirstSelectItem();
	if itemID < 0 then
		return
	end
	local index = Friend_IMGroupInvite_InvitedList:GetItemNumByItemId(itemID)
	if index >= 0 then
		Friend_IMGroupInvite_InvitedList:DelItem(index);
	end
end

function Friend_IMGroupInvite_ResetPos()
	Friend_IMGroupInvite_Frame:SetProperty("UnifiedXPosition", g_UnifiedXPosition);
	Friend_IMGroupInvite_Frame:SetProperty("UnifiedYPosition", g_UnifiedYPosition);
end


function Friend_IMGroupInvite_SpecialFriendUpdate()
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
		Friend_IMGroupInvite_FriendList:AddItem( strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 1 ] == 1 then
			local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(spouseGuid)
			if nGroup ~= nil and nIndex ~= nil then
				if nGroup >= 0 and nIndex >= 0 then
					Friend_IMGroupInvite_AddSpecialFriendItem( nGroup, nIndex )
				end
			end
		end
	end
	
	--结拜组 ，不包括已经出现在婚姻组的成员
	local nBrotherCount = DataPool:GetBrotherCount()
	local nBrotherListNum = Friend:Lua_GetBrotherNumExceptSpouse()
	local nOnlineBrotherListNum = Friend:Lua_GetOnlineBrotherNumExceptSpouse()
	
	if nBrotherListNum > 0 then
	
		local strOutlineName = "我的结拜"
		if g_SpecialFriendOutLine[ 2 ] == 1 then
			strOutlineName = "#gFE7E82- " .. strOutlineName
		else
			strOutlineName = "#gFE7E82+ " .. strOutlineName
		end
		
		local iStart = 102*10000
		Friend_IMGroupInvite_FriendList:AddItem( strOutlineName, iStart )
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
								if( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) then
									Friend_IMGroupInvite_AddSpecialFriendItem( nGroup, nIndex )
								end
							end
						end
					end
				end
			end

			for ind = 1, nBrotherCount do
				local charPos = DataPool:GetBrotherInfoByInd(ind - 1, "CharPos")
				local nBrotherGuid = DataPool:GetBrotherInfoByInd(ind - 1, "CharGuid")
				if charPos >= 0 and charPos <= 5 and charPos ~= selfPos then
					if nBrotherGuid ~= nil and nBrotherGuid ~= spouseGuid then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nBrotherGuid)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								if( not ( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) ) then
									Friend_IMGroupInvite_AddSpecialFriendItem( nGroup, nIndex )
								end
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
		Friend_IMGroupInvite_FriendList:AddItem( strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 3 ] == 1 then
			for i=0,8 do
				local nGUID,	szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,1)
				if nGUID ~= nil and nGUID ~= spouseGuid then	--不是配偶
					local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
					if nGroup ~= nil and nIndex ~= nil then
						if nGroup >= 1 and nGroup <= 4 and nIndex >= 0 then
							if DataPool:GetFriend( nGroup, nIndex, "RELATION_TYPE" ) ~= 2 then -- 不是结拜
								if( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) then
									Friend_IMGroupInvite_AddSpecialFriendItem( nGroup, nIndex )
								end
							end
						end
					end
				end
			end

			for i=0,8 do
				local nGUID,	szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,1)
				if nGUID ~= nil and nGUID ~= spouseGuid then
					local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
					if nGroup ~= nil and nIndex ~= nil then
						if nGroup >= 1 and nGroup <= 4 and nIndex >= 0 then
							if DataPool:GetFriend( nGroup, nIndex, "RELATION_TYPE" ) ~= 2 then -- 不是结拜
								if( not (DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) ) then
									Friend_IMGroupInvite_AddSpecialFriendItem( nGroup, nIndex )
								end
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
		Friend_IMGroupInvite_FriendList:AddItem( strOutlineName, iStart )
		if g_SpecialFriendOutLine[ 4 ] == 1 then

			for i=0,8 do
				local nGUID,szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,2)

				if nType == 2 and szCharName ~= "" then
					if nGUID ~= nil then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								if( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) then
									Friend_IMGroupInvite_AddSpecialFriendItem( nGroup, nIndex )
								end
							end
						end
					end
				end
			end

			for i=0,8 do
				local nGUID,szCharName,nType,nSex,nLevel,szGuildName,nQinmi,nGongfeng,nStartDay,nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,2)
				if nType == 2 and szCharName ~= "" then
					if nGUID ~= nil then
						local nGroup , nIndex = Friend:Lua_GetRelationPositionWithTempFriend(nGUID)
						if nGroup ~= nil and nIndex ~= nil then
							if nGroup >= 0 and nIndex >= 0 then
								if( not ( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) ) then
									Friend_IMGroupInvite_AddSpecialFriendItem( nGroup, nIndex  )
								end
							end
						end
					end
				end
			end			
		end
	end
	
end

function Friend_IMGroupInvite_AddSpecialFriendItem(nGroup, nIndex)

	local name = DataPool:GetFriend( nGroup, nIndex, "NAME" )
	local friendship = DataPool:GetFriend( nGroup, nIndex, "FRIENDSHIP" )
	local relationtype = DataPool:GetFriend( nGroup, nIndex, "RELATION_TYPE" )
				
	local namecolor = "#cC4B299"

	local IMst = DataPool:GetFriend( nGroup, nIndex, "IM_STATUS" )
	local Sex = DataPool:GetFriend( nGroup, nIndex, "SEX" )
	
	local playerIcon = "    "	
					
	if( DataPool:GetFriend( nGroup, nIndex, "ONLINE" ) ) then

		if( relationtype == 7 or relationtype == 8) then	--  7:师傅 8：徒弟
			namecolor = "#cFF6600"
		elseif( relationtype == 3 ) then			-- 3：结婚
			namecolor = "#cF246F0"
		elseif( relationtype == 2 ) then			-- 2：结拜
			namecolor = "#c007EFF"	
			local isSpouse = DataPool:GetFriend( nGroup, nIndex, "IS_SPOUSE" )
			if isSpouse == 1 then
				namecolor = "#cF246F0"					--结拜 并且在配偶列
			end
		elseif( friendship >= 10 ) then 
				namecolor = "#c00FF00"	
		elseif( friendship >= 1 ) then	
				namecolor = "#c00C800"	
		elseif( friendship == 0 ) then	
				namecolor = "#cFFFFFF"
		end
		
		if tonumber(IMst) >= 0 and tonumber(IMst) <=2  and tonumber(Sex) >=0 and tonumber(Sex) <= 1 then
			playerIcon = g_imgStatus[Sex][IMst]
		end
		
		Friend_IMGroupInvite_FriendList:AddItem("  "..playerIcon..namecolor..name , nGroup * 10000 + nIndex + 1)
	
	else

		Friend_IMGroupInvite_FriendList:AddItem("  "..playerIcon..namecolor..name , nGroup * 10000 + nIndex + 1)
	
	end

end

function Friend_IMGroupInvite_ShowInCommonFriendGroup(  nChannel, nIndex )
	
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