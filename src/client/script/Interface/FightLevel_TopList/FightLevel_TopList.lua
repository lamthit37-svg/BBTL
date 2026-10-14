local g_FightLevel_TopList_UnifiedPosition
local g_FightLevel_TopList_Type = 0
local g_FightLevel_TopList_ButtonLastTime = 0

local g_FightLevel_TopList_MenPai

function FightLevel_TopList_PreLoad()
	this:RegisterEvent( "UI_COMMAND", true )
	this:RegisterEvent( "UPDATE_FIGHTLEVEL_RANKLIST", true )
	this:RegisterEvent( "VIEW_RESOLUTION_CHANGED", false )
	this:RegisterEvent( "ADJEST_UI_POS", false )
	this:RegisterEvent( "HIDE_ON_SCENE_TRANSED", true )
end

function FightLevel_TopList_OnLoad()
	g_FightLevel_TopList_UnifiedPosition = FightLevel_TopList_Frame:GetProperty("UnifiedPosition")
end

function FightLevel_TopList_OnEvent(event)
	if ( event == "UPDATE_FIGHTLEVEL_RANKLIST" ) then
		g_FightLevel_TopList_Type = tonumber(arg0)
		FightLevel_TopList_OnShow()
	elseif(event == "ADJEST_UI_POS") then
		FightLevel_TopList_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		FightLevel_TopList_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		FightLevel_TopList_OnHidden()
	end
end

function FightLevel_TopList_On_ResetPos()
	FightLevel_TopList_Frame:SetProperty( "UnifiedPosition", g_FightLevel_TopList_UnifiedPosition )
end

function FightLevel_TopList_SetCheckBox(idx)
	if idx == 1 then
		DataPool:lua_GetNormalRankingListInfo(6)
	elseif idx == 2 then
		DataPool:lua_GetNormalRankingListInfo(1)
	end
end

function FightLevel_TopList_Fenye2_Click(idx)
	DataPool:lua_GetNormalRankingListInfo(idx)
end

function FightLevel_TopList_OnShow()
	FightLevel_TopList_Tab1_Tips:Hide()
	FightLevel_TopList_Tab2_Tips:Hide()

	FightLevel_TopListLevel_Tab1_Tips:Hide()
	FightLevel_TopListLevel_Tab2_Tips:Hide()
	FightLevel_TopListLevel_Tab3_Tips:Hide()
	FightLevel_TopListLevel_Tab4_Tips:Hide()
	FightLevel_TopListLevel_Tab5_Tips:Hide()

	local tip1, tip2, tip3, tip4, tip5, tip6 = DataPool:lua_GetNormalRankingListRedPoint()

	if g_FightLevel_TopList_Type == 6 then
		FightLevel_TopList_Tab1:SetCheck(1)
		FightLevel_TopList_Tab2:SetCheck(0)
		FightLevel_TopListFightFrame:Show()
		FightLevel_TopListLevelFrame:Hide()

		if tip6 == 0 then
			FightLevel_TopList_Tab1_Tips:Show()
		end

		if tip1 == 0 or tip2 == 0 or tip3 == 0 or tip4 == 0 or tip5 == 0 then
			FightLevel_TopList_Tab2_Tips:Show()
		end

		local nStartTime, nEndTime,nRewardEnd, nClostTime = DataPool:lua_GetNormalRankGetRankTime(g_FightLevel_TopList_Type)
		local nStartData =  math.mod(nStartTime,10000)
		local nStartYear =  math.floor(nStartTime/10000)
		local nStartMonth = math.floor(nStartData/100)
		local nStartDay = math.mod(nStartData,100)

		local nCloseData =  math.mod(nClostTime,10000)
		local nCloseMonth = math.floor(nCloseData/100)
		local nClosedDay = math.mod(nCloseData,100)

		if newserver == 0 then
			local strInfo =	ScriptGlobal_Format("#{TXLY_240904_53}", nStartMonth, nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
			FightLevel_TopListFight_Intro:SetText(strInfo)
		else
			local strInfo =	ScriptGlobal_Format("#{TXLY_240906_10}", nStartMonth, nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
			FightLevel_TopListFight_Intro:SetText(strInfo)
		end

		FightLevel_TopListFight_List:Clear()

		local nCount, getReward, mytime, myrank, myvalue = DataPool:lua_GetNormalRankingListBaseData(g_FightLevel_TopList_Type)
		if nCount ~= 0 then
			for i = 0, nCount-1 do
				local nGuid, nCharname, nMenPai, nScore = DataPool:lua_GetNormalRankingListCharData( g_FightLevel_TopList_Type, i )

				local ItemBar = FightLevel_TopListFight_List:AddChild("FightLevel_TopListFight_List_Item")
				
				if i == 0 then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList1")
				elseif i == 1 then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList2")
				elseif i == 2 then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList3")
				else
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):SetText(i+1)
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Show()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):Hide()
				end

				ItemBar:GetSubItem("FightLevel_TopListFight_List_NameText"):SetText(nCharname)
				ItemBar:GetSubItem("FightLevel_TopListFight_List_SchoolText"):SetText(FightLevel_TopListLevel_GetMenPai(nMenPai))
				ItemBar:GetSubItem("FightLevel_TopListFight_List_ZhanLiText"):SetText(nScore)

				local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,i+1)
				
				local theAction1 = DataPool:CreateBindActionItemForShow( aid1, bidn1 )
				if theAction1 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_Award_Icon1"):SetActionItem(theAction1:GetID())
				end

				local theAction2 = DataPool:CreateBindActionItemForShow( aid2, bidn2 )
				if theAction2 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_Award_Icon2"):SetActionItem(theAction2:GetID())
				end

				ItemBar:GetSubItem("FightLevel_TopListFight_List_AwardInfo"):SetEvent( "MouseLClick", "FightLevel_TopListFight_List_OnClick("..i..")" )
			end
		end

		if nCount < 20 then
			for i = nCount, 19 do
				local ItemBar = FightLevel_TopListFight_List:AddChild("FightLevel_TopListFight_List_Item")
				
				if i == 0 then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList1")
				elseif i == 1 then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList2")
				elseif i == 2 then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList3")
				else
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):SetText(i+1)
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankText"):Show()
					ItemBar:GetSubItem("FightLevel_TopListFight_List_RankImage"):Hide()
				end

				ItemBar:GetSubItem("FightLevel_TopListFight_List_NameText"):SetText("#{TXLY_240904_11}")
				ItemBar:GetSubItem("FightLevel_TopListFight_List_SchoolText"):SetText("#{TXLY_240904_11}")
				ItemBar:GetSubItem("FightLevel_TopListFight_List_ZhanLiText"):SetText("")

				local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,i+1)
				
				local theAction1 = DataPool:CreateBindActionItemForShow( aid1, bidn1 )
				if theAction1 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_Award_Icon1"):SetActionItem(theAction1:GetID())
				else
					ItemBar:GetSubItem("FightLevel_TopListFight_List_Award_Icon1"):SetActionItem(-1)
				end

				local theAction2 = DataPool:CreateBindActionItemForShow( aid2, bidn2 )
				if theAction2 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListFight_List_Award_Icon2"):SetActionItem(theAction2:GetID())
				else
					ItemBar:GetSubItem("FightLevel_TopListFight_List_Award_Icon2"):SetActionItem(-1)
				end

				ItemBar:GetSubItem("FightLevel_TopListFight_List_AwardInfo"):Hide()
			end
		end

		FightLevel_TopListFight_Self_NameText:SetText(Player:GetName())
		FightLevel_TopListFight_Self_SchoolText:SetText(FightLevel_TopListLevel_GetMenPai(Player:GetData("MEMPAI")))
		FightLevel_TopListFight_Self_ZhanLiText:SetText(myvalue)

		if myrank > 0 then
			FightLevel_TopListFight_Self_RankText:SetText(myrank)

			local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,myrank)

			local theAction1 = DataPool:CreateBindActionItemForShow( aid1, bidn1 )
			if theAction1 ~= nil then
				FightLevel_TopListFight_Self_Award_Icon1:SetActionItem(theAction1:GetID())
			else
				FightLevel_TopListFight_Self_Award_Icon1:SetActionItem(-1)
			end

			local theAction2 = DataPool:CreateBindActionItemForShow( aid2, bidn2 )
			if theAction2 ~= nil then
				FightLevel_TopListFight_Self_Award_Icon2:SetActionItem(theAction2:GetID())
			else
				FightLevel_TopListFight_Self_Award_Icon2:SetActionItem(-1)
			end
		else
			FightLevel_TopListFight_Self_RankText:SetText("#{TXLY_240906_11}")

			FightLevel_TopListFight_Self_Award_Icon1:SetActionItem(-1)
			FightLevel_TopListFight_Self_Award_Icon2:SetActionItem(-1)
		end

		local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,1)
		
		local day = math.mod( stime, 100 )
		local month = math.mod( math.floor( stime/100 ), 100 )

		FightLevel_TopListFight_Time:SetText(ScriptGlobal_Format("#{TXLY_240904_59}", month, day))
	elseif g_FightLevel_TopList_Type >= 1 and g_FightLevel_TopList_Type <= 5 then
		FightLevel_TopList_Tab1:SetCheck(0)
		FightLevel_TopList_Tab2:SetCheck(1)
		FightLevel_TopListFightFrame:Hide()
		FightLevel_TopListLevelFrame:Show()

		if tip6 == 0 then
			FightLevel_TopList_Tab1_Tips:Show()
		end

		if tip1 == 0 or tip2 == 0 or tip3 == 0 or tip4 == 0 or tip5 == 0 then
			FightLevel_TopList_Tab2_Tips:Show()
		end

		if tip1 == 0 then
			FightLevel_TopListLevel_Tab1_Tips:Show()
		end

		if tip2 == 0 then
			FightLevel_TopListLevel_Tab2_Tips:Show()
		end

		if tip3 == 0 then
			FightLevel_TopListLevel_Tab3_Tips:Show()
		end

		if tip4 == 0 then
			FightLevel_TopListLevel_Tab4_Tips:Show()
		end

		if tip5 == 0 then
			FightLevel_TopListLevel_Tab5_Tips:Show()
		end

		if g_FightLevel_TopList_Type == 1 then
			FightLevel_TopListLevel_Tab1:SetCheck(1)
			FightLevel_TopListLevel_Tab2:SetCheck(0)
			FightLevel_TopListLevel_Tab3:SetCheck(0)
			FightLevel_TopListLevel_Tab4:SetCheck(0)
			FightLevel_TopListLevel_Tab5:SetCheck(0)
		elseif g_FightLevel_TopList_Type == 2 then
			FightLevel_TopListLevel_Tab1:SetCheck(0)
			FightLevel_TopListLevel_Tab2:SetCheck(1)
			FightLevel_TopListLevel_Tab3:SetCheck(0)
			FightLevel_TopListLevel_Tab4:SetCheck(0)
			FightLevel_TopListLevel_Tab5:SetCheck(0)
		elseif g_FightLevel_TopList_Type == 3 then
			FightLevel_TopListLevel_Tab1:SetCheck(0)
			FightLevel_TopListLevel_Tab2:SetCheck(0)
			FightLevel_TopListLevel_Tab3:SetCheck(1)
			FightLevel_TopListLevel_Tab4:SetCheck(0)
			FightLevel_TopListLevel_Tab5:SetCheck(0)
		elseif g_FightLevel_TopList_Type == 4 then
			FightLevel_TopListLevel_Tab1:SetCheck(0)
			FightLevel_TopListLevel_Tab2:SetCheck(0)
			FightLevel_TopListLevel_Tab3:SetCheck(0)
			FightLevel_TopListLevel_Tab4:SetCheck(1)
			FightLevel_TopListLevel_Tab5:SetCheck(0)
		elseif g_FightLevel_TopList_Type == 5 then
			FightLevel_TopListLevel_Tab1:SetCheck(0)
			FightLevel_TopListLevel_Tab2:SetCheck(0)
			FightLevel_TopListLevel_Tab3:SetCheck(0)
			FightLevel_TopListLevel_Tab4:SetCheck(0)
			FightLevel_TopListLevel_Tab5:SetCheck(1)
		end

		local MaxLevel = Player:GetDefineHumanMaxLevel()
		local nSpecKaJi89 = Player:GetData("SPECKAJI89")
		if KaJi:LuaFnIsKaJiServer() == 1 then
			MaxLevel = KaJi:LuaFnGetKaJiLeveL()
		elseif nSpecKaJi89 == 1 or nSpecKaJi89 == 2 then
			MaxLevel = 89
		end

		if MaxLevel == 69 then
			FightLevel_TopListLevel_Tab2:Hide()
			FightLevel_TopListLevel_Tab3:Hide()
			FightLevel_TopListLevel_Tab4:Hide()
			FightLevel_TopListLevel_Tab5:Hide()
		elseif MaxLevel == 89 then
			FightLevel_TopListLevel_Tab4:Hide()
			FightLevel_TopListLevel_Tab5:Hide()
		end

		local nStartTime, nEndTime,nRewardEnd, nClostTime,nclientStart, nclientEnd = DataPool:lua_GetNormalRankGetRankTime(g_FightLevel_TopList_Type)
		local nStartData =  math.mod(nStartTime,10000)
		local nStartYear =  math.floor(nStartTime/10000)
		local nStartMonth = math.floor(nStartData/100)
		local nStartDay = math.mod(nStartData,100)
	
	
		local nEndData =  math.mod(nEndTime,10000)
		local nEndYear = math.floor(nEndTime/10000)
		local nEndMonth = math.floor(nEndData/100)
		local nEndDay = math.mod(nEndData,100)

		local newserver = DataPool:lua_GetNormalRankingListTableServerType()
		if g_FightLevel_TopList_Type == 1 then
			if newserver == 0 then
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_14}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			else
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_15}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			end
		elseif g_FightLevel_TopList_Type == 2 then
			if newserver == 0 then
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_33}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			else
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_34}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			end
		elseif g_FightLevel_TopList_Type == 3 then
			if newserver == 0 then
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_35}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			else
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_36}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			end
		elseif g_FightLevel_TopList_Type == 4 then
			if newserver == 0 then
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_37}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			else
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_38}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			end
		elseif g_FightLevel_TopList_Type == 5 then
			if newserver == 0 then
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_39}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			else
				local strInfo = ScriptGlobal_Format( "#{TXLY_240906_40}",nStartMonth,nStartDay,nEndMonth,nEndDay,nEndMonth,nEndDay)
				FightLevel_TopListLevel_Intro:SetText(strInfo)
			end
		end

		FightLevel_TopListLevel_List:Clear()

		local nCount, getReward, mytime, myrank, myvalue = DataPool:lua_GetNormalRankingListBaseData(g_FightLevel_TopList_Type)
		if nCount ~= 0 then
			for i = 0, nCount-1 do
				local nGuid, nCharname, nMenPai, nTime = DataPool:lua_GetNormalRankingListCharData( g_FightLevel_TopList_Type, i )

				local ItemBar = FightLevel_TopListLevel_List:AddChild("FightLevel_TopListLevel_List_Item")

				if i == 0 then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList1")
				elseif i == 1 then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList2")
				elseif i == 2 then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList3")
				else
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):SetText(i+1)
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Show()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):Hide()
				end

				ItemBar:GetSubItem("FightLevel_TopListLevel_List_NameText"):SetText(nCharname)
				ItemBar:GetSubItem("FightLevel_TopListLevel_List_SchoolText"):SetText(FightLevel_TopListLevel_GetMenPai(nMenPai))
				local sec = math.mod( nTime, 100 )
				local min = math.mod( math.floor( nTime/100 ), 100 )
				local hour = math.mod( math.floor( nTime/10000 ), 100 )
				local day = math.mod( math.floor( nTime/1000000 ), 100 )
				local month = math.mod( math.floor( nTime/100000000 ), 100 )
				ItemBar:GetSubItem("FightLevel_TopListLevel_List_ZhanLiText"):SetText(ScriptGlobal_Format("#{TXLY_240904_57}", month, day,hour,min,sec))

				local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,i+1)
				
				local theAction1 = DataPool:CreateBindActionItemForShow( aid1, bidn1 )
				if theAction1 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_Award_Icon1"):SetActionItem(theAction1:GetID())
				end

				local theAction2 = DataPool:CreateBindActionItemForShow( aid2, bidn2 )
				if theAction2 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_Award_Icon2"):SetActionItem(theAction2:GetID())
				end

				ItemBar:GetSubItem("FightLevel_TopListLevel_List_AwardInfo"):SetEvent( "MouseLClick", "FightLevel_TopListLevel_List_OnClick("..i..")" )
			end
		end

		if nCount < 20 then
			for i = nCount, 19 do
				local ItemBar = FightLevel_TopListLevel_List:AddChild("FightLevel_TopListLevel_List_Item")

				if i == 0 then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList1")
				elseif i == 1 then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList2")
				elseif i == 2 then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Hide()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):SetImage("FightLevel_TopList","Levelup_TopList3")
				else
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):SetText(i+1)
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankText"):Show()
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_RankImage"):Hide()
				end

				ItemBar:GetSubItem("FightLevel_TopListLevel_List_NameText"):SetText("#{TXLY_240904_11}")
				ItemBar:GetSubItem("FightLevel_TopListLevel_List_SchoolText"):SetText("#{TXLY_240904_11}")
				ItemBar:GetSubItem("FightLevel_TopListLevel_List_ZhanLiText"):SetText("")

				local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,i+1)
				
				local theAction1 = DataPool:CreateBindActionItemForShow( aid1, bidn1 )
				if theAction1 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_Award_Icon1"):SetActionItem(theAction1:GetID())
				else
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_Award_Icon1"):SetActionItem(-1)
				end

				local theAction2 = DataPool:CreateBindActionItemForShow( aid2, bidn2 )
				if theAction2 ~= nil then
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_Award_Icon2"):SetActionItem(theAction2:GetID())
				else
					ItemBar:GetSubItem("FightLevel_TopListLevel_List_Award_Icon2"):SetActionItem(-1)
				end

				ItemBar:GetSubItem("FightLevel_TopListLevel_List_AwardInfo"):Hide()
			end
		end

		FightLevel_TopListLevel_Self_NameText:SetText(Player:GetName())
		FightLevel_TopListLevel_Self_SchoolText:SetText(FightLevel_TopListLevel_GetMenPai(Player:GetData("MEMPAI")))
		if mytime == 0 then
			FightLevel_TopListLevel_Self_ZhanLiText:SetText("")
		else
			local sec = math.mod( mytime, 100 )
			local min = math.mod( math.floor( mytime/100 ), 100 )
			local hour = math.mod( math.floor( mytime/10000 ), 100 )
			local day = math.mod( math.floor( mytime/1000000 ), 100 )
			local month = math.mod( math.floor( mytime/100000000 ), 100 )
			FightLevel_TopListLevel_Self_ZhanLiText:SetText(ScriptGlobal_Format("#{TXLY_240904_57}", month, day,hour,min,sec))
		end

		if myrank > 0 then
			FightLevel_TopListLevel_Self_RankText:SetText(myrank)

			local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,myrank)

			local theAction1 = DataPool:CreateBindActionItemForShow( aid1, bidn1 )
			if theAction1 ~= nil then
				FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(theAction1:GetID())
			else
				FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(-1)
			end

			local theAction2 = DataPool:CreateBindActionItemForShow( aid2, bidn2 )
			if theAction2 ~= nil then
				FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(theAction2:GetID())
			else
				FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(-1)
			end
		else
			local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,1)

			if Player:GetData("LEVEL") >= con1 then
				local isall = 1
				for i = 1, 6 do
					local  theAction = EnumAction( i - 1, "xinfa" )

					if theAction:GetID() ~= 0 then
						local nXinfaId = LifeAbility:GetLifeAbility_Number( theAction:GetID() )
						local nXinfa_level = Player:GetXinfaInfo( nXinfaId, "level" )
						if nXinfa_level < con2 then
							isall = 0
						end
					end
				end

				if isall == 1 then
					if newserver == 1 then
						FightLevel_TopListLevel_Self_RankText:SetText("#{TXLY_240906_12}")

						local theAction1 = DataPool:CreateBindActionItemForShow( did1, didn1 )
						if theAction1 ~= nil then
							FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(theAction1:GetID())
						else
							FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(-1)
						end

						local theAction2 = DataPool:CreateBindActionItemForShow( did2, didn2 )
						if theAction2 ~= nil then
							FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(theAction2:GetID())
						else
							FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(-1)
						end
					else
						if Player:GetData("MEMPAI") == 15 then
							FightLevel_TopListLevel_Self_RankText:SetText("#{TXLY_240906_12}")

							local theAction1 = DataPool:CreateBindActionItemForShow( did1, didn1 )
							if theAction1 ~= nil then
								FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(theAction1:GetID())
							else
								FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(-1)
							end

							local theAction2 = DataPool:CreateBindActionItemForShow( did2, didn2 )
							if theAction2 ~= nil then
								FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(theAction2:GetID())
							else
								FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(-1)
							end
						else
							FightLevel_TopListLevel_Self_RankText:SetText("#{TXLY_240906_13}")

							FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(-1)
							FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(-1)
						end
					end
				else
					FightLevel_TopListLevel_Self_RankText:SetText("#{TXLY_240906_13}")

					FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(-1)
					FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(-1)
				end
			else
				FightLevel_TopListLevel_Self_RankText:SetText("#{TXLY_240906_13}")

				FightLevel_TopListLevel_Self_Award_Icon1:SetActionItem(-1)
				FightLevel_TopListLevel_Self_Award_Icon2:SetActionItem(-1)
			end
		end

		local otime, stime, ctime, bid1, bidn1, aid1, bid2, bidn2, aid2, con1, con2, did1, didn1, did2, didn2 = DataPool:lua_GetNormalRankingListTableInfo(g_FightLevel_TopList_Type,1)
		local day = math.mod( stime, 100 )
		local month = math.mod( math.floor( stime/100 ), 100 )
		FightLevel_TopListLevel_Time:SetText(ScriptGlobal_Format("#{TXLY_240904_59}", month, day))

		if g_FightLevel_TopList_Type == 1 then
			FightLevel_TopListLevel_AwardGet:SetToolTip(ScriptGlobal_Format( "#{TXLY_240904_18}", "#{TXLY_240904_2}" ))
		elseif g_FightLevel_TopList_Type == 2 then
			FightLevel_TopListLevel_AwardGet:SetToolTip(ScriptGlobal_Format( "#{TXLY_240904_18}", "#{TXLY_240904_3}" ))
		elseif g_FightLevel_TopList_Type == 3 then
			FightLevel_TopListLevel_AwardGet:SetToolTip(ScriptGlobal_Format( "#{TXLY_240904_18}", "#{TXLY_240904_4}" ))
		elseif g_FightLevel_TopList_Type == 4 then
			FightLevel_TopListLevel_AwardGet:SetToolTip(ScriptGlobal_Format( "#{TXLY_240904_18}", "#{TXLY_240904_5}" ))
		elseif g_FightLevel_TopList_Type == 5 then
			FightLevel_TopListLevel_AwardGet:SetToolTip(ScriptGlobal_Format( "#{TXLY_240904_18}", "#{TXLY_240904_6}" ))
		end
	else
		return
	end

	this:Show()
end

function FightLevel_TopList_OnHidden()
	this:Hide()
end

function FightLevel_TopList_OnHelp()
	
	local nStartTime, nEndTime,nRewardEnd, nClostTime,nclientStart, nclientEnd = DataPool:lua_GetNormalRankGetRankTime(g_FightLevel_TopList_Type)
	local nStartData =  math.mod(nStartTime,10000)
	local nStartYear =  math.floor(nStartTime/10000)
	local nStartMonth = math.floor(nStartData/100)
	local nStartDay = math.mod(nStartData,100)


	local nEndData =  math.mod(nEndTime,10000)
	local nEndYear = math.floor(nEndTime/10000)
	local nEndMonth = math.floor(nEndData/100)
	local nEndDay = math.mod(nEndData,100)


	local nCloseData =  math.mod(nClostTime,10000)
	local nCloseMonth = math.floor(nCloseData/100)
	local nClosedDay = math.mod(nCloseData,100)

	local nEndRewardData =  math.mod(nRewardEnd,10000)
	local nEndRewardYear =  math.floor(nRewardEnd/10000)
	local nEndRewardMonth = math.floor(nEndRewardData/100)
	local nEndRewardDay = math.mod(nEndRewardData,100)


	local nClientStartData =  math.mod(nclientStart,10000)
	local nClientStartMonth = math.floor(nClientStartData/100)
	local nClientStartDay = math.mod(nClientStartData,100)


	local nClientEndData =  math.mod(nclientEnd,10000)
	local nClientEndMonth = math.floor(nClientEndData/100)
	local nClientEndDay = math.mod(nClientEndData,100)

	local newserver = DataPool:lua_GetNormalRankingListTableServerType()
	local strInfo = ""
	if newserver == 0 then
		strInfo = ScriptGlobal_Format( "#{TXLY_241112_1}",nClientStartMonth,nClientStartDay,nClientEndMonth,nClientEndDay,
		nStartMonth,nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
	else
		strInfo = ScriptGlobal_Format( "#{TXLY_241112_2}",nClientStartMonth,nClientStartDay,nClientEndMonth,nClientEndDay,
		nStartMonth,nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
	end

	local strInfo1 = ScriptGlobal_Format( "#{TXLY_240906_46}", nEndRewardYear,nEndRewardMonth,nEndRewardDay,nStartMonth,nStartDay,nEndMonth,nEndDay)

	local strInfo2 = ScriptGlobal_Format( "#{TXLY_240904_54}",nEndRewardYear,nEndRewardMonth,nEndRewardDay,nEndYear,nEndMonth,nEndDay)

	PushEvent("QUEST_HELP_MSG", strInfo..strInfo1..strInfo2)
end

function FightLevel_TopList_OnClose()
	this:Hide()
end

function FightLevel_TopListFight_Help()
	local nStartTime, nEndTime,nRewardEnd, nClostTime,nclientStart, nclientEnd = DataPool:lua_GetNormalRankGetRankTime(g_FightLevel_TopList_Type)
	local nStartData =  math.mod(nStartTime,10000)
	local nStartYear =  math.floor(nStartTime/10000)
	local nStartMonth = math.floor(nStartData/100)
	local nStartDay = math.mod(nStartData,100)


	local nEndData =  math.mod(nEndTime,10000)
	local nEndYear = math.floor(nEndTime/10000)
	local nEndMonth = math.floor(nEndData/100)
	local nEndDay = math.mod(nEndData,100)


	local nCloseData =  math.mod(nClostTime,10000)
	local nCloseMonth = math.floor(nCloseData/100)
	local nClosedDay = math.mod(nCloseData,100)

	local nEndRewardData =  math.mod(nRewardEnd,10000)
	local nEndRewardYear =  math.floor(nRewardEnd/10000)
	local nEndRewardMonth = math.floor(nEndRewardData/100)
	local nEndRewardDay = math.mod(nEndRewardData,100)


	local nClientStartData =  math.mod(nclientStart,10000)
	local nClientStartMonth = math.floor(nClientStartData/100)
	local nClientStartDay = math.mod(nClientStartData,100)


	local nClientEndData =  math.mod(nclientEnd,10000)
	local nClientEndMonth = math.floor(nClientEndData/100)
	local nClientEndDay = math.mod(nClientEndData,100)

	local newserver = DataPool:lua_GetNormalRankingListTableServerType()
	local strInfo = ""
	if newserver == 0 then
		strInfo = ScriptGlobal_Format( "#{TXLY_241112_1}",nClientStartMonth,nClientStartDay,nClientEndMonth,nClientEndDay,
		nStartMonth,nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
	else
		strInfo = ScriptGlobal_Format( "#{TXLY_241112_2}",nClientStartMonth,nClientStartDay,nClientEndMonth,nClientEndDay,
		nStartMonth,nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
	end

	local strInfo1 = ScriptGlobal_Format( "#{TXLY_240906_46}", nEndRewardYear,nEndRewardMonth,nEndRewardDay,nStartMonth,nStartDay,nEndMonth,nEndDay)

	local strInfo2 = ScriptGlobal_Format( "#{TXLY_240904_54}",nEndRewardYear,nEndRewardMonth,nEndRewardDay,nEndYear,nEndMonth,nEndDay)

	PushEvent("QUEST_HELP_MSG", strInfo..strInfo1..strInfo2)
end

function FightLevel_TopList_Award_Clicked()
	DataPool:lua_GetNormalRankingListReward(g_FightLevel_TopList_Type)
end

function FightLevel_TopList_Fight_RF()
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_FightLevel_TopList_ButtonLastTime < 3 * 1000) then 
   	    PushDebugMessage("#{TXLY_240904_14}"); --不可连续点击，请稍等片刻后再点击
		return
	end

	g_FightLevel_TopList_ButtonLastTime = curTime;

	DataPool:lua_GetNormalRankingListInfo(g_FightLevel_TopList_Type)
end

function FightLevel_TopListLevel_Help()
	local nStartTime, nEndTime,nRewardEnd, nClostTime,nclientStart, nclientEnd = DataPool:lua_GetNormalRankGetRankTime(g_FightLevel_TopList_Type)
	local nStartData =  math.mod(nStartTime,10000)
	local nStartYear =  math.floor(nStartTime/10000)
	local nStartMonth = math.floor(nStartData/100)
	local nStartDay = math.mod(nStartData,100)


	local nEndData =  math.mod(nEndTime,10000)
	local nEndYear = math.floor(nEndTime/10000)
	local nEndMonth = math.floor(nEndData/100)
	local nEndDay = math.mod(nEndData,100)


	local nCloseData =  math.mod(nClostTime,10000)
	local nCloseMonth = math.floor(nCloseData/100)
	local nClosedDay = math.mod(nCloseData,100)

	local nEndRewardData =  math.mod(nRewardEnd,10000)
	local nEndRewardYear =  math.floor(nRewardEnd/10000)
	local nEndRewardMonth = math.floor(nEndRewardData/100)
	local nEndRewardDay = math.mod(nEndRewardData,100)


	local nClientStartData =  math.mod(nclientStart,10000)
	local nClientStartMonth = math.floor(nClientStartData/100)
	local nClientStartDay = math.mod(nClientStartData,100)


	local nClientEndData =  math.mod(nclientEnd,10000)
	local nClientEndMonth = math.floor(nClientEndData/100)
	local nClientEndDay = math.mod(nClientEndData,100)

	local newserver = DataPool:lua_GetNormalRankingListTableServerType()
	local strInfo = ""
	if newserver == 0 then
		strInfo = ScriptGlobal_Format( "#{TXLY_241112_1}",nClientStartMonth,nClientStartDay,nClientEndMonth,nClientEndDay,
		nStartMonth,nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
	else
		strInfo = ScriptGlobal_Format( "#{TXLY_241112_2}",nClientStartMonth,nClientStartDay,nClientEndMonth,nClientEndDay,
		nStartMonth,nStartDay,nCloseMonth,nClosedDay,nCloseMonth,nClosedDay)
	end

	local strInfo1 = ScriptGlobal_Format( "#{TXLY_240906_46}", nEndRewardYear,nEndRewardMonth,nEndRewardDay,nStartMonth,nStartDay,nEndMonth,nEndDay)

	local strInfo2 = ScriptGlobal_Format( "#{TXLY_240904_54}",nEndRewardYear,nEndRewardMonth,nEndRewardDay,nEndYear,nEndMonth,nEndDay)

	PushEvent("QUEST_HELP_MSG", strInfo..strInfo1..strInfo2)
end

function FightLevel_TopListLevel_GetMenPai( menpai )
	local strName = ""
	
	if (0 == menpai) then
		strName = "少林"
	elseif (1 == menpai) then
		strName = "明教"
	elseif (2 == menpai) then
		strName = "丐帮"
	elseif (3 == menpai) then
		strName = "武当"
	elseif (4 == menpai) then
		strName = "峨嵋"
	elseif (5 == menpai) then
		strName = "星宿"
	elseif (6 == menpai) then
		strName = "天龙"
	elseif (7 == menpai) then
		strName = "天山"
	elseif (8 == menpai) then
		strName = "逍遥"
	elseif (9 == menpai) then
		strName = "无门派"
	elseif (10== menpai) then
		strName = "慕容"
	elseif (11== menpai) then
		strName = "唐门"
	elseif (12== menpai) then
		strName = "鬼谷"
	elseif (13== menpai) then 
		strName = "#{XQ_MP_15}"
	elseif (14== menpai) then 
		strName = "#{XMPHM_210604_01}"
	elseif (15== menpai) then
		strName = "#{GMGameInterface_Script_DataPool_Info_ERenGu}"
	end
		
	return strName
end

function FightLevel_TopListFight_List_OnClick(idx)
	local nGuid, nCharname, nMenPai, nScore = DataPool:lua_GetNormalRankingListCharData( g_FightLevel_TopList_Type, idx )
	if nil ~= nCharname then
		if Friend:IsPlayerIsFriend(nCharname) == 1  then
			DataPool:ShowFriendInfo(nCharname)
		else
			DataPool:ShowChatInfo(nCharname)
		end
	end
end

function FightLevel_TopListLevel_List_OnClick(idx)
	local nGuid, nCharname, nMenPai, nScore = DataPool:lua_GetNormalRankingListCharData( g_FightLevel_TopList_Type, idx )
	if nil ~= nCharname then
		if Friend:IsPlayerIsFriend(nCharname) == 1  then
			DataPool:ShowFriendInfo(nCharname)
		else
			DataPool:ShowChatInfo(nCharname)
		end
	end
end


