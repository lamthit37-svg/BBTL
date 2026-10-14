
local currentSearchMode = 0;
local currentPosition;

local temp_id;
local temp_bOnline;
local temp_name;
local temp_bPrecise;
local temp_str,temp_index;
local temp_bBigWorld;

local temp_nMenpai;
local temp_nSex;
local temp_LevelDown;
local temp_LevelUp;
local temp_banghui;
local temp_shizu;
local currentFilter = 0
local g_FriendSearch_Frame_UnifiedPosition;
local temp_allliance;
--===============================================
-- OnLoad()
--===============================================
function FriendSearch_PreLoad()

	this:RegisterEvent("OPEN_FRIEND_SEARCH");
	this:RegisterEvent("SEARCH_FRIEND_OK");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SEARCH_FRIEND_CLOSE")
end
function FriendSearch_OnLoad()


	FriendSearch_SearchMode:ComboBoxAddItem("名字",0);
	FriendSearch_SearchMode:ComboBoxAddItem("ID",1);
	FriendSearch_SearchMode:SetCurrentSelect( 0 );
	local str,index = FriendSearch_SearchMode:GetCurrentSelect();

	FriendSearch_Module2_CheckBox1:SetCheck( 0 );
	FriendSearch_Module2_CheckBox2:SetCheck( 0 );
	--FriendSearch_Module2_CheckBox3:SetCheck( 0 );
	--FriendSearch_Module1_CheckBox33:SetCheck( 0 );



	FriendSearch_Confraternity:ComboBoxAddItem("全部",-3 );
	FriendSearch_Confraternity:ComboBoxAddItem("任意",-2 );
	FriendSearch_Confraternity:ComboBoxAddItem("无帮派",-1 );
	FriendSearch_Confraternity:SetCurrentSelect( 0 );
	
	FriendSearch_ConfraternityKVK:ComboBoxAddItem("全部",-3 );
	FriendSearch_ConfraternityKVK:ComboBoxAddItem("任意",-2 );
	FriendSearch_ConfraternityKVK:ComboBoxAddItem("无帮派",-1 );
	FriendSearch_ConfraternityKVK:SetCurrentSelect( 0 );

	FriendSearch_Sexy:ComboBoxAddItem("不限",-1 );
	FriendSearch_Sexy:ComboBoxAddItem( "女", 0 );
	FriendSearch_Sexy:ComboBoxAddItem( "男", 1 );
	FriendSearch_Sexy:SetCurrentSelect( 0 );
	


	FriendSearch_Level:ComboBoxAddItem("任意",-1 );
	FriendSearch_Level:ComboBoxAddItem( "1 - 10", 0 );
	FriendSearch_Level:ComboBoxAddItem( "11 - 20", 1 );
	FriendSearch_Level:ComboBoxAddItem( "21 - 30", 2 );
	FriendSearch_Level:ComboBoxAddItem( "31 - 40", 3 );
	FriendSearch_Level:ComboBoxAddItem( "41 - 50", 4 );
	FriendSearch_Level:ComboBoxAddItem( "51 - 60", 5 );
	FriendSearch_Level:ComboBoxAddItem( "61 - 70", 6 );
	FriendSearch_Level:ComboBoxAddItem( "71 - 80", 7 );
	FriendSearch_Level:ComboBoxAddItem( "81 - 90", 8 );
	FriendSearch_Level:ComboBoxAddItem( "91 - 100", 9 );
	FriendSearch_Level:ComboBoxAddItem( "101 - 110", 10 );
	FriendSearch_Level:ComboBoxAddItem( "111 - 120", 11 );
	FriendSearch_Level:ComboBoxAddItem( "121 - 130", 12 );

	FriendSearch_Level:SetCurrentSelect( 0 );
	currentFilter = 1
	 g_FriendSearch_Frame_UnifiedPosition=FriendSearch_Frame:GetProperty("UnifiedPosition");

end

--===============================================
-- OnEvent()
--===============================================
function FriendSearch_OnEvent( event )

	if ( event == "OPEN_FRIEND_SEARCH" ) then
		FriendSearch_Info:RemoveAllItem();
		this:Show();
		FrinedSearch_UpdataMenPai();
		FrinedSearch_UpdataFilter();
		FriendSearch_DiableButton();
	elseif( event =="SEARCH_FRIEND_OK" ) then
		FriendSearch_UpdateCurrentPage();
		
	elseif (event == "ADJEST_UI_POS" ) then
		FriendSearch_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FriendSearch_Frame_On_ResetPos()
	elseif (event == "SEARCH_FRIEND_CLOSE") then
		FriendSearch_Close()
	end

end

function FrinedSearch_UpdataMenPai()

	local nMenPailist = { 
		{"少林", 0}, {"明教", 1}, 
		{"丐帮", 2}, {"武当", 3}, 
		{"峨嵋", 4}, {"星宿", 5}, 
		{"天龙", 6}, {"天山", 7}, 
		{"逍遥", 8}, {"慕容", 10}, 
		{"唐门", 11}, {"鬼谷", 12},
		{"桃花岛", 13}, {"绝情谷", 14}, {"恶人谷", 15},
	}
	FriendSearch_MenPai:ResetList()
	FriendSearch_MenPai:ComboBoxAddItem("全部",-3 );
	FriendSearch_MenPai:ComboBoxAddItem("任意",-2 );
	FriendSearch_MenPai:ComboBoxAddItem("无门派", -1 );
	
	local selfzoneid = DataPool:GetSelfZoneWorldID()
	for nIndex = 1, table.getn(nMenPailist) do		
		if Lua_IsCJDingZhiMenPaiOpen(selfzoneid, nMenPailist[nIndex][2]) == 1 then
			FriendSearch_MenPai:ComboBoxAddItem( nMenPailist[nIndex][1], nMenPailist[nIndex][2] );
		end
	end
 
	--FriendSearch_MenPai:ComboBoxAddItem("少林", 0 );
	--FriendSearch_MenPai:ComboBoxAddItem("明教", 1 );
	--FriendSearch_MenPai:ComboBoxAddItem("丐帮", 2 );
	--FriendSearch_MenPai:ComboBoxAddItem("武当", 3 );
	--FriendSearch_MenPai:ComboBoxAddItem("峨嵋", 4 );
	--FriendSearch_MenPai:ComboBoxAddItem("星宿", 5 );
	--FriendSearch_MenPai:ComboBoxAddItem("天龙", 6 );
	--FriendSearch_MenPai:ComboBoxAddItem("天山", 7 );
	--FriendSearch_MenPai:ComboBoxAddItem("逍遥", 8 );
	--FriendSearch_MenPai:ComboBoxAddItem("慕容", 10);
	--FriendSearch_MenPai:ComboBoxAddItem("唐门", 11);
	--FriendSearch_MenPai:ComboBoxAddItem("鬼谷", 12);	
	--FriendSearch_MenPai:ComboBoxAddItem("桃花岛", 13);
	--FriendSearch_MenPai:ComboBoxAddItem("绝情谷", 14);
	--FriendSearch_MenPai:ComboBoxAddItem("恶人谷", 15);--menpai15 mptodo
	
	FriendSearch_MenPai:SetCurrentSelect( 0 );
	
end

-- update current page info
function FriendSearch_UpdateCurrentPage()


	FriendSearch_Info:RemoveAllItem();
	FriendSearch_KVK_Info:RemoveAllItem();
	FriendSearch_UpdateButton();
	local nNumber = FriendSearcher:GetFriendNumberInPage( currentPosition );

	if (KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 ) and currentFilter == 2 then
		local i = 0;
		while( i < nNumber ) do
			local name = FriendSearcher:GetFriendFromPage( currentPosition, i, "NAME" );
			local id = FriendSearcher:GetFriendFromPage( currentPosition, i, "ID_TEXT" );
			local bOnline = FriendSearcher:GetFriendFromPage( currentPosition, i, "ONLINE" );
			local nLevel = FriendSearcher:GetFriendFromPage( currentPosition, i, "LEVEL" );
			local nSex = FriendSearcher:GetFriendFromPage( currentPosition, i, "SEX" );
			local strMenpai= FriendSearcher:GetFriendFromPage( currentPosition, i, "MENPAI_TEXT" );
			local strBangpai = FriendSearcher:GetFriendFromPage( currentPosition, i, "GUID_NAME" );
			local zoneWorld = FriendSearcher:GetFriendFromPage( currentPosition, i, "ZONEWORLDID" );
			local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
			if tonumber(zoneWorld) ~= -1 and tonumber(zoneWorld) ~= selfZoneWorldID then
				name = name .. "@" .. DataPool:GetServerName(zoneWorld)
				if strBangpai ~= "" then
					strBangpai = strBangpai .. "@" .. DataPool:GetServerName(zoneWorld)
				end
			end
			local namecolor = "#cC4B299";
			if( bOnline ) then
				namecolor = "#cFFFFFF";
			end
	
			FriendSearch_KVK_Info:AddNewItem( namecolor..name, 0, i );
			id = ConvertGuidToShow(id)
			FriendSearch_KVK_Info:AddNewItem( namecolor..id, 1, i );
			if( bOnline ) then
				FriendSearch_KVK_Info:AddNewItem( namecolor.."在线", 2, i );
			else
				FriendSearch_KVK_Info:AddNewItem( namecolor.."离线", 2, i );
			end
			FriendSearch_KVK_Info:AddNewItem( namecolor..tostring( nLevel ), 3, i );
	
			if( tonumber( nSex ) == 0 ) then
				FriendSearch_KVK_Info:AddNewItem( namecolor.."女", 4, i );
			else
				FriendSearch_KVK_Info:AddNewItem( namecolor.."男", 4, i );
			end
			FriendSearch_KVK_Info:AddNewItem( namecolor..strMenpai, 5, i );
			if tonumber(currentFilter) == 2 then
				FriendSearch_KVK_Info:AddNewItem( namecolor..strBangpai, 6, i );
			end
			i = i + 1;
		end
	else
		local i = 0;
		while( i < nNumber ) do
			local name = FriendSearcher:GetFriendFromPage( currentPosition, i, "NAME" );
			local id = FriendSearcher:GetFriendFromPage( currentPosition, i, "ID_TEXT" );
			local bOnline = FriendSearcher:GetFriendFromPage( currentPosition, i, "ONLINE" );
			local nLevel = FriendSearcher:GetFriendFromPage( currentPosition, i, "LEVEL" );
			local nSex = FriendSearcher:GetFriendFromPage( currentPosition, i, "SEX" );
			local strMenpai= FriendSearcher:GetFriendFromPage( currentPosition, i, "MENPAI_TEXT" );
			local strBangpai = FriendSearcher:GetFriendFromPage( currentPosition, i, "GUID_NAME" );
	
			local namecolor = "#cC4B299";
			if( bOnline ) then
				namecolor = "#cFFFFFF";
			end
	
			FriendSearch_Info:AddNewItem( namecolor..name, 0, i );
			id = ConvertGuidToShow(id)	
			FriendSearch_Info:AddNewItem( namecolor..id, 1, i );
			if( bOnline ) then
				FriendSearch_Info:AddNewItem( namecolor.."在线", 2, i );
			else
				FriendSearch_Info:AddNewItem( namecolor.."离线", 2, i );
			end
			FriendSearch_Info:AddNewItem( namecolor..tostring( nLevel ), 3, i );
	
			if( tonumber( nSex ) == 0 ) then
				FriendSearch_Info:AddNewItem( namecolor.."女", 4, i );
			else
				FriendSearch_Info:AddNewItem( namecolor.."男", 4, i );
			end
			FriendSearch_Info:AddNewItem( namecolor..strMenpai, 5, i );
			FriendSearch_Info:AddNewItem( namecolor..strBangpai, 6, i );
	
			i = i + 1;
		end
	end
end


function FriendSearch_Close()
	this:Hide();
end
function FriendSearch_BeginSearch()
	FriendSearch_DiableButton();
	temp_id = FriendSearch_Condition_Name:GetText();
	temp_bOnline = FriendSearch_Module2_CheckBox2:GetCheck();
	if currentFilter == 1 then
		temp_bBigWorld = 0--FriendSearch_Module2_CheckBox3:GetCheck();
	elseif currentFilter == 2 then
		temp_bBigWorld = 1--FriendSearch_Module1_CheckBox33:GetCheck();
	end
	temp_name = FriendSearch_Condition_Name:GetText();
	temp_bPrecise = FriendSearch_Module2_CheckBox1:GetCheck();
	temp_str,temp_index = FriendSearch_SearchMode:GetCurrentSelect();

	temp_str,temp_nMenpai = FriendSearch_MenPai:GetCurrentSelect();
	temp_str,temp_banghui = FriendSearch_Confraternity:GetCurrentSelect();
	temp_str,temp_nSex = FriendSearch_Sexy:GetCurrentSelect();
	temp_str,temp_shizu = FriendSearch_ConfraternityKVK:GetCurrentSelect();

	local str,nLevelDown = FriendSearch_Level:GetCurrentSelect();

	if( nLevelDown == -1 ) then
		temp_LevelDown = -1;
		temp_LevelUp = -1;
	else
		temp_LevelDown = nLevelDown * 10 + 1;
		temp_LevelUp = temp_LevelDown + 9;
	end

	temp_str,temp_searchtype = FriendSearch_SearchMode:GetCurrentSelect();

	currentPosition = 0;
	FriendSearch_Info:RemoveAllItem();
	FriendSearch_KVK_Info:RemoveAllItem();
	FriendSearcher:ClearFingerList();
	FriendSearch_Search( currentPosition );
end
function FriendSearch_Search( nPosition )


	if( currentSearchMode == 0 ) then
		if( temp_searchtype == 1 ) then
				if( temp_id == "" ) then
					return;
				end
				FriendSearcher:FriendSearchByID( tostring( temp_id ), tonumber( temp_bOnline ), tonumber( temp_bBigWorld ) );
		elseif( temp_searchtype == 0 ) then
				FriendSearcher:FriendSearchByName( temp_name, temp_bPrecise, temp_bOnline, nPosition, temp_bBigWorld );
		end
	else
		if tonumber(currentFilter) == 1 then
			FriendSearcher:FriendSearchAdvance( nPosition, tonumber( temp_nMenpai ), temp_banghui, tonumber( temp_nSex ), tonumber(temp_LevelDown), tonumber(temp_LevelUp), tonumber(temp_bBigWorld) );
		elseif tonumber(currentFilter) == 2 then
			FriendSearcher:FriendSearchAdvance( nPosition, tonumber( temp_nMenpai ), temp_shizu, tonumber( temp_nSex ), tonumber(temp_LevelDown), tonumber(temp_LevelUp), tonumber(temp_bBigWorld) );
		end
	end


end
function FriendSearch_NextPage()
	currentPosition = currentPosition + 1;
	FriendSearch_DiableButton();
	FriendSearch_Search( currentPosition );
end
function FriendSearch_ChangeTabIndex(index)
	
	if tonumber(index) == 1 then
		currentFilter = 1
		FriendSearch_FenYeBenfu:SetProperty("Selected", "True" );
		FriendSearch_FenYeyuanfu:SetProperty("Selected", "False" );
		FrinedSearch_UpdataFilter()
	elseif index == 2 then
		currentFilter = 2
		FriendSearch_FenYeBenfu:SetProperty("Selected", "False" );
		FriendSearch_FenYeyuanfu:SetProperty("Selected", "True" );
		FrinedSearch_UpdataFilter()
	end
end
function FriendSearch_LastPage()
	currentPosition = currentPosition - 1;
	FriendSearch_DiableButton();
	FriendSearch_Search( currentPosition );
end

function FriendSearch_ViewInfo()
		local nCurrentSelect = FriendSearch_Info:GetSelectItem();
		if (KVKInterface:IsInKVKServer() == 1  or IsInTServer() == 1 ) and currentFilter == 2 then
			nCurrentSelect = FriendSearch_KVK_Info:GetSelectItem();
		end
		if nCurrentSelect == -1 then
			return
		end
		local name = FriendSearcher:GetFriendFromPage( currentPosition, nCurrentSelect, "NAME" );
		local zoneworldid = FriendSearcher:GetFriendFromPage( currentPosition, nCurrentSelect, "ZONEWORLDID" );
		if name == nil or zoneworldid == nil then
			return
		end
		if( Friend:IsPlayerIsFriend( name, zoneworldid) == 1 ) then
			local nGroup,nIndex;
			nGroup,nIndex = DataPool:GetFriendByName( name );
			--Friend:SetCurrentSelect( nIndex );
			DataPool:ShowFriendInfo( name, zoneworldid );
		else

			DataPool:ShowChatInfoByZWId( name, tonumber(zoneworldid ));
		end
end

function FriendSearch_HighSearch()
	currentSearchMode = 1;
	FrinedSearch_UpdataFilter();
end

function FriendSearch_BaseSearch()
	currentSearchMode = 0;
	FrinedSearch_UpdataFilter();
end

function FrinedSearch_UpdataFilter()
	if KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 then
		FriendSearch_FenYeBenfu:Show()
		FriendSearch_FenYeyuanfu:Show()
		FriendSearch_Info:Hide()
		if currentFilter == 2 then
			FriendSearch_KVK_Info:Show()
			FriendSearch_Info:Hide()
			FriendSearch_ConfraternityKVK:Show()
			FriendSearch_Confraternity:Hide()
			FriendSearch_Text3KVK:Show()
			FriendSearch_Text3:Hide()
		else
			FriendSearch_Info:Show()
			FriendSearch_KVK_Info:Hide()
			FriendSearch_Confraternity:Show()
			FriendSearch_ConfraternityKVK:Hide()
			FriendSearch_Text3KVK:Hide()
			FriendSearch_Text3:Show()
		end
  else
  	currentFilter = 1
		FriendSearch_DiableButton();
		FriendSearch_FenYeBenfu:Hide()
		FriendSearch_FenYeyuanfu:Hide()
		FriendSearch_Text3KVK:Hide()
		FriendSearch_Text3:Show()
		FriendSearch_Info:Show()
		FriendSearch_KVK_Info:Hide()
		FriendSearch_Confraternity:Show()
		FriendSearch_ConfraternityKVK:Hide()
	end
	if( currentSearchMode == 0 ) then
		FriendSearch_Module2:Show();
		FriendSearch_Module1:Hide();
	else
		FriendSearch_Module1:Show();
		FriendSearch_Module2:Hide();
	end
	FriendSearch_Info:RemoveAllItem();
	FriendSearch_KVK_Info:RemoveAllItem()
	FriendSearcher:ClearFingerList();
	FriendSearch_examine:Disable()
end


function FriendSearch_UpdateButton()

	if( currentPosition >= FriendSearcher:GetFriendPageNumber() - 1 ) then
		FriendSearch_DownPage:Disable();
	else
		FriendSearch_DownPage:Enable();

	end

	if( currentPosition == 0 )then
		FriendSearch_UpPage:Disable();
	else
		FriendSearch_UpPage:Enable();
	end

	if( FriendSearch_Info:GetSelectItem() == -1 ) then
		FriendSearch_examine:Disable();
	else
		FriendSearch_examine:Enable();
	end
	if (KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 ) and currentFilter == 2 and FriendSearch_KVK_Info:GetSelectItem() == -1 then
		FriendSearch_examine:Disable()
	elseif currentFilter == 1 and FriendSearch_Info:GetSelectItem() == -1 then
		FriendSearch_examine:Disable();
	else
		FriendSearch_examine:Enable();
	end
end

function FriendSearch_DiableButton()

	FriendSearch_DownPage:Disable();
	FriendSearch_UpPage:Disable();
	FriendSearch_examine:Disable();
	
	if DataPool:IsSuperman() == false then
				FriendSearch_ForbiditButton:Hide();
				FriendSearch_PosButton:Hide();
				FriendSearch_GotoButton:Hide();
				FriendSearch_TeamButton:Hide();
				if SystemSetup:IsClassic() == 1 then
					FriendSearch_Blank:Show();
				end
	else
			if SystemSetup:IsClassic() == 1 then
				FriendSearch_Blank:Hide();
			end
			FriendSearch_ForbiditButton:Show();
			FriendSearch_PosButton:Show();
			FriendSearch_GotoButton:Show();
			FriendSearch_TeamButton:Show();
	end

end

function FriendSearch_Frame_On_ResetPos()
  FriendSearch_Frame:SetProperty("UnifiedPosition", g_FriendSearch_Frame_UnifiedPosition);
end

function FriendSearch_Forbidit_Clicked()
	local nCurrentSelect = FriendSearch_Info:GetSelectItem();
	if (KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 ) and currentFilter == 2 then
		nCurrentSelect = FriendSearch_KVK_Info:GetSelectItem();
	end
	if nCurrentSelect == -1 then
		return
	end
	local name = FriendSearcher:GetFriendFromPage( currentPosition, nCurrentSelect, "NAME" );
	FriendSearcher:ForbidItByNameAndGuid(name, currentPosition, nCurrentSelect);
	this:Hide();
end

function FriendSearch_PosButton_Clicked()
	local nCurrentSelect = FriendSearch_Info:GetSelectItem();
	if (KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 ) and currentFilter == 2 then
		nCurrentSelect = FriendSearch_KVK_Info:GetSelectItem();
	end
	if nCurrentSelect == -1 then
		return
	end
	
	FriendSearcher:ViewPlayerPosInfo( currentPosition, nCurrentSelect );
	
end

function FriendSearch_GotoButton_Clicked()
	local nCurrentSelect = FriendSearch_Info:GetSelectItem();
	if (KVKInterface:IsInKVKServer() == 1 or IsInTServer() == 1 ) and currentFilter == 2 then
		nCurrentSelect = FriendSearch_KVK_Info:GetSelectItem();
	end
	if nCurrentSelect == -1 then
		return
	end
	
	FriendSearcher:ViewPlayerPosGoTo( currentPosition, nCurrentSelect );
	
end

function FriendSearch_TeamButton_Clicked()
	local nCurrentSelect = FriendSearch_Info:GetSelectItem();
	if (KVKInterface:IsInKVKServer() == 1  or IsInTServer() == 1 ) and currentFilter == 2 then
		nCurrentSelect = FriendSearch_KVK_Info:GetSelectItem();
	end
	if nCurrentSelect == -1 then
		return
	end
	
	FriendSearcher:ViewPlayerTeamInfo( currentPosition, nCurrentSelect );
	
end
