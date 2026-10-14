local g_ZM_Boss_Dps_Frame_UnifiedPosition = nil 

local g_ZM_Boss_Dps_nType = 0
local g_ZM_Boss_Dps_NpcId = -1
local g_ZM_Boss_Dps_objCared = -1

local g_ZM_Boss_Dps_RankingList_Type = 1
local g_ZM_Boss_Dps_State = 0

local g_ZM_Boss_Dps_MaxMenPaiID = 15--menpai15 mptodo

local g_ZM_Boss_Dps_MenPaiList = {}

local g_ZM_Boss_Dps_List_SelectRow = -1

local g_ZM_Boss_Dps_MenPaiStr = {
	[1] = "#{ZMB_230124_121}",	-- menpaiid = 0
	[2] = "#{ZMB_230124_122}",	-- menpaiid = 1
	[3] = "#{ZMB_230124_123}",	-- menpaiid = 2
	[4] = "#{ZMB_230124_124}",	-- menpaiid = 3
	[5] = "#{ZMB_230124_125}",	-- menpaiid = 4
	[6] = "#{ZMB_230124_126}",	-- menpaiid = 5
	[7] = "#{ZMB_230124_127}",	-- menpaiid = 6
	[8] = "#{ZMB_230124_128}",	-- menpaiid = 7
	[9] = "#{ZMB_230124_129}",	-- menpaiid = 8
	[10] = "#{ZMB_230124_130}",	-- menpaiid = 10
	[11] = "#{ZMB_230124_131}",	-- menpaiid = 11
	[12] = "#{ZMB_230124_132}",	-- menpaiid = 12
	[13] = "#{ZMB_230124_133}",	-- menpaiid = 13
	[14] = "#{ZMB_230124_134}",	-- menpaiid = 14
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",	-- menpaiid = 15 menpai15 mptodo
}

local g_ZM_Boss_Dps_RankingIDToMenPai = {
	[5] = 0,
	[6] = 1,
	[7] = 2,
	[8] = 3,
	[9] = 4,
	[10] = 5,
	[11] = 6,
	[12] = 7,
	[13] = 8,
	[14] = 10,
	[15] = 11,
	[16] = 12,
	[17] = 13,
	[18] = 14,
	[20] = 0,
	[21] = 1,
	[22] = 2,
	[23] = 3,
	[24] = 4,
	[25] = 5,
	[26] = 6,
	[27] = 7,
	[28] = 8,
	[29] = 10,
	[30] = 11,
	[31] = 12,
	[32] = 13,
	[33] = 14,
	[34] = 15,
	[35] = 15,
}

local g_ZM_Boss_Dps_TabToRankingList_Mon = {
	[1] = 5,
	[2] = 6,
	[3] = 7,
	[4] = 8,
	[5] = 9,
	[6] = 10,
	[7] = 11,
	[8] = 12,
	[9] = 13,
	[10] = 14,
	[11] = 15,
	[12] = 16,
	[13] = 17,
	[14] = 18,
	[15] = 34,
}

local g_ZM_Boss_Dps_TabToRankingList_Wed = {
	[1] = 20,
	[2] = 21,
	[3] = 22,
	[4] = 23,
	[5] = 24,
	[6] = 25,
	[7] = 26,
	[8] = 27,
	[9] = 28,
	[10] = 29,
	[11] = 30,
	[12] = 31,
	[13] = 32,
	[14] = 33,
	[15] = 35,
}

local g_ZM_Boss_Dps_MenPaiName = {
	[1] = "#{ZMB_230124_92}",	-- menpaiid = 0
	[2] = "#{ZMB_230124_93}",	-- menpaiid = 1
	[3] = "#{ZMB_230124_94}",	-- menpaiid = 2
	[4] = "#{ZMB_230124_95}",	-- menpaiid = 3
	[5] = "#{ZMB_230124_96}",	-- menpaiid = 4
	[6] = "#{ZMB_230124_97}",	-- menpaiid = 5
	[7] = "#{ZMB_230124_98}",	-- menpaiid = 6
	[8] = "#{ZMB_230124_99}",	-- menpaiid = 7
	[9] = "#{ZMB_230124_100}",	-- menpaiid = 8
	[10] = "#{ZMB_230124_101}",	-- menpaiid = 10
	[11] = "#{ZMB_230124_102}",	-- menpaiid = 11
	[12] = "#{ZMB_230124_103}",	-- menpaiid = 12
	[13] = "#{ZMB_230124_104}",	-- menpaiid = 13
	[14] = "#{ZMB_230124_105}",	-- menpaiid = 14
	[15] = "#{ZMB_230124_269}",	-- menpaiid = 15 menpai15 mptodo
}

function ZM_Boss_Dps_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ZONGMENBOSS_RANKINGLIST",true)
	this:RegisterEvent("ZONGMENBOSS_UPDATERANKINGLIST",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function ZM_Boss_Dps_OnLoad()
	g_ZM_Boss_Dps_Frame_UnifiedPosition = ZM_Boss_Dps_Frame:GetProperty("UnifiedPosition")
end

function ZM_Boss_Dps_OnEvent(event)
	if event == "ZONGMENBOSS_RANKINGLIST" then
		if this:IsVisible() then
			return
		end

		g_ZM_Boss_Dps_List_SelectRow = -1

		g_ZM_Boss_Dps_nType = tonumber(arg0);
		g_ZM_Boss_Dps_NpcId = tonumber(arg1);

		g_ZM_Boss_Dps_objCared = DataPool:GetNPCIDByServerID(g_ZM_Boss_Dps_NpcId)

		if g_ZM_Boss_Dps_objCared == -1 then
			return
		end

		ZM_Boss_Dps_BeginCareObject(g_ZM_Boss_Dps_objCared)

		this:Show()

		ZM_Boss_Dps_OnShow()
	elseif event == "ZONGMENBOSS_UPDATERANKINGLIST" then
		if this:IsVisible() then
			g_ZM_Boss_Dps_nType = tonumber(arg0)
			g_ZM_Boss_Dps_List_SelectRow = -1
			ZM_Boss_Dps_ReFresh()
		end
	elseif ( event == "ADJEST_UI_POS" ) then
		ZM_Boss_Dps_On_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		ZM_Boss_Dps_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		return
	end

end

function ZM_Boss_Dps_On_ResetPos()
	ZM_Boss_Dps_Frame:SetProperty( "UnifiedPosition", g_ZM_Boss_Dps_Frame_UnifiedPosition )
end

function ZM_Boss_Dps_OnShow()
	ZM_Boss_Dps_MPList:Clear()

	for i = 1, g_ZM_Boss_Dps_MaxMenPaiID do
		local mpbar = ZM_Boss_Dps_MPList:AddChild("AutoPickUpSet_TitListItem")
		g_ZM_Boss_Dps_MenPaiList[i] = mpbar
		mpbar:GetSubItem("AutoPickUpSet_Tit"):SetText(g_ZM_Boss_Dps_MenPaiStr[i])
		mpbar:GetSubItem("AutoPickUpSet_Tit"):SetEvent( "Clicked", string.format( "ZM_Boss_Dps_ItemClicked(%d)", i) )
	end

	local menpai = Player:GetData("MEMPAI")
	if g_ZM_Boss_Dps_RankingIDToMenPai[g_ZM_Boss_Dps_nType] ~= nil then
		menpai = g_ZM_Boss_Dps_RankingIDToMenPai[g_ZM_Boss_Dps_nType]
	end

	if menpai < 9 then
		menpai = menpai + 1
	elseif menpai == 9 then
		menpai = 1
	end

	ZM_Boss_Dps_MPList:SetScrollPosition4Index(menpai-1)

	for idx = 1, g_ZM_Boss_Dps_MaxMenPaiID do
		if idx ~= menpai then
			g_ZM_Boss_Dps_MenPaiList[idx]:GetSubItem("AutoPickUpSet_Tit"):SetProperty( "Selected", "False" )
		else
			g_ZM_Boss_Dps_MenPaiList[idx]:GetSubItem("AutoPickUpSet_Tit"):SetProperty( "Selected", "True" )
		end
	end

	local myRank = -1
	local myRankTime = DataPool:lua_GetJSRankingListMyInfo(g_ZM_Boss_Dps_nType)
	local rankcount = DataPool:lua_GetJSRankingListDataCount(g_ZM_Boss_Dps_nType)
	ZM_Boss_Dps_ListInfo:RemoveAllItem()

	if rankcount > 0 then
		for i = 0, rankcount-1 do
			local nRank, name, usetime, state = DataPool:lua_GetJSRankingListInfo( g_ZM_Boss_Dps_nType, i )
			local bValid, memguid, membname, mempai, level, score = DataPool:lua_GetJSRankingListMemberInfo( g_ZM_Boss_Dps_nType, i, 0 )

			if bValid == 1 then
				ZM_Boss_Dps_ListInfo:AddNewItem( i+1, 0, i )
				ZM_Boss_Dps_ListInfo:AddNewItem( membname, 1, i )
				ZM_Boss_Dps_ListInfo:AddNewItem( level, 2, i )
				ZM_Boss_Dps_ListInfo:AddNewItem( usetime, 3, i )

				if memguid == Player:GetGUID() then
					myRank = nRank+1
				end
			end
		end
	end
	
	ZM_Boss_Dps_MyDpsInfo:SetText( ScriptGlobal_Format("#{ZMB_230124_89}", myRankTime ) )
	if myRank == -1 then
		ZM_Boss_Dps_NumInfo:SetText( "#{ZMB_230124_91}" )
	else
		local mpstr = ScriptGlobal_Format(g_ZM_Boss_Dps_MenPaiName[menpai], myRank )
		ZM_Boss_Dps_NumInfo:SetText( ScriptGlobal_Format("#{ZMB_230124_90}", mpstr ) )
	end
end

function ZM_Boss_Dps_ReFresh()
	local menpai = Player:GetData("MEMPAI")
	if g_ZM_Boss_Dps_RankingIDToMenPai[g_ZM_Boss_Dps_nType] ~= nil then
		menpai = g_ZM_Boss_Dps_RankingIDToMenPai[g_ZM_Boss_Dps_nType]
	end

	if menpai < 9 then
		menpai = menpai + 1
	elseif menpai == 9 then
		menpai = 1
	end

	for idx = 1, g_ZM_Boss_Dps_MaxMenPaiID do
		if idx ~= menpai then
			g_ZM_Boss_Dps_MenPaiList[idx]:GetSubItem("AutoPickUpSet_Tit"):SetProperty( "Selected", "False" )
		else
			g_ZM_Boss_Dps_MenPaiList[idx]:GetSubItem("AutoPickUpSet_Tit"):SetProperty( "Selected", "True" )
		end
	end

	local myRank = -1
	local myRankTime = DataPool:lua_GetJSRankingListMyInfo(g_ZM_Boss_Dps_nType)
	local rankcount = DataPool:lua_GetJSRankingListDataCount(g_ZM_Boss_Dps_nType)
	ZM_Boss_Dps_ListInfo:RemoveAllItem()

	if rankcount > 0 then
		for i = 0, rankcount-1 do
			local nRank, name, usetime, state = DataPool:lua_GetJSRankingListInfo( g_ZM_Boss_Dps_nType, i )
			local bValid, memguid, membname, mempai, level, score = DataPool:lua_GetJSRankingListMemberInfo( g_ZM_Boss_Dps_nType, i, 0 )

			if bValid == 1 then
				ZM_Boss_Dps_ListInfo:AddNewItem( i+1, 0, i )
				ZM_Boss_Dps_ListInfo:AddNewItem( membname, 1, i )
				ZM_Boss_Dps_ListInfo:AddNewItem( level, 2, i )
				ZM_Boss_Dps_ListInfo:AddNewItem( usetime, 3, i )
			end

			if memguid == Player:GetGUID() then
				myRank = nRank+1
			end
		end
	end

	menpai = Player:GetData("MEMPAI")

	if g_ZM_Boss_Dps_RankingIDToMenPai[g_ZM_Boss_Dps_nType] ~= nil then
		if menpai == g_ZM_Boss_Dps_RankingIDToMenPai[g_ZM_Boss_Dps_nType] then
			if menpai < 9 then
				menpai = menpai + 1
			elseif menpai == 9 then
				menpai = 1
			end

			ZM_Boss_Dps_MyDpsInfo:SetText( ScriptGlobal_Format("#{ZMB_230124_89}", myRankTime ) )
			if myRank == -1 then
				ZM_Boss_Dps_NumInfo:SetText( "#{ZMB_230124_91}" )
			else
				local mpstr = ScriptGlobal_Format(g_ZM_Boss_Dps_MenPaiName[menpai], myRank )
				ZM_Boss_Dps_NumInfo:SetText( ScriptGlobal_Format("#{ZMB_230124_90}", mpstr ) )
			end
		end
	end
end

function ZM_Boss_Dps_ItemClicked(i)
	local nNowWeek = Lua_EnumTempMemo( i, "NOWWEEK" )
	if nNowWeek == 1 or nNowWeek == 2 then
		if g_ZM_Boss_Dps_TabToRankingList_Mon[i] ~= nil then
			DataPool:lua_GetZMBossRankingList(g_ZM_Boss_Dps_TabToRankingList_Mon[i])
		end
	else
		if g_ZM_Boss_Dps_TabToRankingList_Wed[i] ~= nil then
			DataPool:lua_GetZMBossRankingList(g_ZM_Boss_Dps_TabToRankingList_Wed[i])
		end
	end
end

--=========================================================
--开始关心NPC
--=========================================================
function ZM_Boss_Dps_BeginCareObject(objCaredId)
	if g_ZM_Boss_Dps_objCared ~= -1 then
		this:CareObject( g_ZM_Boss_Dps_objCared, 0, "ZM_Boss_Dps" )
	end

	g_ZM_Boss_Dps_objCared = objCaredId
	this:CareObject( g_ZM_Boss_Dps_objCared, 1, "ZM_Boss_Dps" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ZM_Boss_Dps_StopCareObject()
	if g_ZM_Boss_Dps_objCared ~= -1 then
		this:CareObject( g_ZM_Boss_Dps_objCared, 0, "ZM_Boss_Dps" )
		objCared = -1;
	end
end

function ZM_Boss_Dps_ExplainText_Help_Clicked()
	PushEvent("QUEST_HELP_MSG", "#{ZMB_230124_165}")
end

function ZM_Boss_Dps_TeamInfo_Clicked()
	DataPool:lua_GetZMBossRankingList(g_ZM_Boss_Dps_nType)
end

function ZM_Boss_Dps_CloseClicked()
	this:Hide()
end

function ZM_Boss_Dps_ListInfo_On_SelectionChanged()
	local index = ZM_Boss_Dps_ListInfo:GetSelectItem()
	if index < 0 then
		g_ZM_Boss_Dps_List_SelectRow = -1
		return
	end

	g_ZM_Boss_Dps_List_SelectRow = index
end

function ZM_Boss_Dps_PlayerInfo_Clicked()
	if g_ZM_Boss_Dps_List_SelectRow < 0 then
		g_ZM_Boss_Dps_List_SelectRow = -1
		PushDebugMessage("#{ZMB_230124_243}")
		return
	end

	local bValid, memguid, membname, mempai, level, score = DataPool:lua_GetJSRankingListMemberInfo( g_ZM_Boss_Dps_nType, g_ZM_Boss_Dps_List_SelectRow, 0 )

	if ( nil ~= membname ) then
		if( Friend:IsPlayerIsFriend( membname ) == 1 ) then
			DataPool:ShowFriendInfo( membname )
		else
			DataPool:ShowChatInfo( membname )
		end
	end
end

