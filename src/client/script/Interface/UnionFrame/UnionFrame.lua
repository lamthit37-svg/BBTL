local g_UnifiedPosition = ""

local g_RaidLeaderIcon1 = "set:Union1 image:Union_LeaderIcon_L"
local g_RaidAssistantIcon1 = "set:Union1 image:Union_MemberIcon_L"

local g_RaidLeaderIcon2 = "set:Union1 image:Union_LeaderIcon_S"
local g_RaidAssistantIcon2 = "set:Union1 image:Union_MemberIcon_S"

local g_MenPaiCount = 15--menpai15 mptodo
local g_SquadButtonNames = {"#{TDGZ_XML_05}", "#{TDGZ_XML_06}", "#{TDGZ_XML_07}", "#{TDGZ_XML_08}", "#{TDGZ_XML_09}"}
local g_MenpaiNames = {"少林","明教","丐帮","武当","峨嵋","星宿","天龙","天山","逍遥","无门派","慕容", "#{XMPTM_130123_02}","鬼谷","#{XQ_MP_15}","#{XMPHM_210604_01}","#{GMGameInterface_Script_DataPool_Info_ERenGu}"}--桃花岛 menpai15 
local g_TextColors = {"#cff6600", "#cffcc00", "#c00ff00", "#c0000ff", "#cff99cc", "#c007700", "#cffff00", "#cffffff", "#c7700ff", "#c999999", "#c007fff", "#ccc00ff", "#c24dec6", "#ca1d6da", "#cd61313", "#c656ab4"}--menpai15 

local g_CurSelMemSquad = -1
local g_CurSelMemIndex = -1

local g_IsSquadWindowShow = {0, 0, 0, 0, 0}
local g_IsShowAllSquad = 0

local g_DragTargetNames = {}
g_DragTargetNames[1] = {"Union_Team1_1_All", "Union_Team1_2_All", "Union_Team1_3_All", "Union_Team1_4_All", "Union_Team1_5_All", "Union_Team1_6_All"}
g_DragTargetNames[2] = {"Union_Team2_1_All", "Union_Team2_2_All", "Union_Team2_3_All", "Union_Team2_4_All", "Union_Team2_5_All", "Union_Team2_6_All"}
g_DragTargetNames[3] = {"Union_Team3_1_All", "Union_Team3_2_All", "Union_Team3_3_All", "Union_Team3_4_All", "Union_Team3_5_All", "Union_Team3_6_All"}
g_DragTargetNames[4] = {"Union_Team4_1_All", "Union_Team4_2_All", "Union_Team4_3_All", "Union_Team4_4_All", "Union_Team4_5_All", "Union_Team4_6_All"}
g_DragTargetNames[5] = {"Union_Team5_1_All", "Union_Team5_2_All", "Union_Team5_3_All", "Union_Team5_4_All", "Union_Team5_5_All", "Union_Team5_6_All"}

local g_DragItemNames = {}
g_DragItemNames[1] = {"Union_Team1_1_Drag", "Union_Team1_2_Drag", "Union_Team1_3_Drag", "Union_Team1_4_Drag", "Union_Team1_5_Drag", "Union_Team1_6_Drag"}
g_DragItemNames[2] = {"Union_Team2_1_Drag", "Union_Team2_2_Drag", "Union_Team2_3_Drag", "Union_Team2_4_Drag", "Union_Team2_5_Drag", "Union_Team2_6_Drag"}
g_DragItemNames[3] = {"Union_Team3_1_Drag", "Union_Team3_2_Drag", "Union_Team3_3_Drag", "Union_Team3_4_Drag", "Union_Team3_5_Drag", "Union_Team3_6_Drag"}
g_DragItemNames[4] = {"Union_Team4_1_Drag", "Union_Team4_2_Drag", "Union_Team4_3_Drag", "Union_Team4_4_Drag", "Union_Team4_5_Drag", "Union_Team4_6_Drag"}
g_DragItemNames[5] = {"Union_Team5_1_Drag", "Union_Team5_2_Drag", "Union_Team5_3_Drag", "Union_Team5_4_Drag", "Union_Team5_5_Drag", "Union_Team5_6_Drag"}

local g_SquadButtons = {}
local g_SquadButtonsHover = {}
local g_MemberDragTargets = {}
local g_MemberDragItems = {}
local g_MemberNames = {}
local g_MemberIcons = {}
local g_MemberCareers = {}
local g_MemberLevels = {}

--Add By YPL, 2011-12-05
local g_RaidList_ShowOrHide = {}
g_RaidList_ShowOrHide[0] = -1	--Modify By YPL, 2011-12-13
g_RaidList_ShowOrHide[1] = -1	--Modify By YPL, 2011-12-13
g_RaidList_ShowOrHide[2] = -1	--Modify By YPL, 2011-12-13
g_RaidList_ShowOrHide[3] = -1	--Modify By YPL, 2011-12-13
g_RaidList_ShowOrHide[4] = -1	--Modify By YPL, 2011-12-13
--End

local g_NeedUpdateFakeObj = 1;
--===============================================
-- OnLoad()
--===============================================
function UnionFrame_PreLoad()
	this:RegisterEvent("DRAG_DROP_ITEM")
	this:RegisterEvent("RAID_UPDATE_RAID_FRAME")
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("RAID_CLOSE_RAID_FRAME")
	this:RegisterEvent("RAID_SQUAD_WINDOW_HIDE")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("RAID_SELECT_MEMBER")
	this:RegisterEvent("RAID_SHOWALLSQUAD")
	this:RegisterEvent("DRAG_DROP_LOST_CAPTURE")
end

function UnionFrame_OnLoad()

	g_SquadButtons[1] = Union_Team1_0
	g_SquadButtons[2] = Union_Team2_0
	g_SquadButtons[3] = Union_Team3_0
	g_SquadButtons[4] = Union_Team4_0
	g_SquadButtons[5] = Union_Team5_0

	g_SquadButtonsHover[1] = Union_Team1_0_Hover
	g_SquadButtonsHover[2] = Union_Team2_0_Hover
	g_SquadButtonsHover[3] = Union_Team3_0_Hover
	g_SquadButtonsHover[4] = Union_Team4_0_Hover
	g_SquadButtonsHover[5] = Union_Team5_0_Hover

	g_MemberDragTargets = {
													Union_Team1_1_All, Union_Team1_2_All, Union_Team1_3_All, Union_Team1_4_All, Union_Team1_5_All, Union_Team1_6_All,
													Union_Team2_1_All, Union_Team2_2_All, Union_Team2_3_All, Union_Team2_4_All, Union_Team2_5_All, Union_Team2_6_All,
													Union_Team3_1_All, Union_Team3_2_All, Union_Team3_3_All, Union_Team3_4_All, Union_Team3_5_All, Union_Team3_6_All,
													Union_Team4_1_All, Union_Team4_2_All, Union_Team4_3_All, Union_Team4_4_All, Union_Team4_5_All, Union_Team4_6_All,
													Union_Team5_1_All, Union_Team5_2_All, Union_Team5_3_All, Union_Team5_4_All, Union_Team5_5_All, Union_Team5_6_All
												}

	g_MemberDragItems[1] = {Union_Team1_1_Drag, Union_Team1_2_Drag, Union_Team1_3_Drag, Union_Team1_4_Drag, Union_Team1_5_Drag, Union_Team1_6_Drag}
	g_MemberDragItems[2] = {Union_Team2_1_Drag, Union_Team2_2_Drag, Union_Team2_3_Drag, Union_Team2_4_Drag, Union_Team2_5_Drag, Union_Team2_6_Drag}
	g_MemberDragItems[3] = {Union_Team3_1_Drag, Union_Team3_2_Drag, Union_Team3_3_Drag, Union_Team3_4_Drag, Union_Team3_5_Drag, Union_Team3_6_Drag}
	g_MemberDragItems[4] = {Union_Team4_1_Drag, Union_Team4_2_Drag, Union_Team4_3_Drag, Union_Team4_4_Drag, Union_Team4_5_Drag, Union_Team4_6_Drag}
	g_MemberDragItems[5] = {Union_Team5_1_Drag, Union_Team5_2_Drag, Union_Team5_3_Drag, Union_Team5_4_Drag, Union_Team5_5_Drag, Union_Team5_6_Drag}

	g_MemberNames[1] = {Union_Team1_1_name, Union_Team1_2_name, Union_Team1_3_name, Union_Team1_4_name, Union_Team1_5_name, Union_Team1_6_name}
	g_MemberNames[2] = {Union_Team2_1_name, Union_Team2_2_name, Union_Team2_3_name, Union_Team2_4_name, Union_Team2_5_name, Union_Team2_6_name}
	g_MemberNames[3] = {Union_Team3_1_name, Union_Team3_2_name, Union_Team3_3_name, Union_Team3_4_name, Union_Team3_5_name, Union_Team3_6_name}
	g_MemberNames[4] = {Union_Team4_1_name, Union_Team4_2_name, Union_Team4_3_name, Union_Team4_4_name, Union_Team4_5_name, Union_Team4_6_name}
	g_MemberNames[5] = {Union_Team5_1_name, Union_Team5_2_name, Union_Team5_3_name, Union_Team5_4_name, Union_Team5_5_name, Union_Team5_6_name}

	g_MemberIcons[1] = {Union_Team1_1_Icon, Union_Team1_2_Icon, Union_Team1_3_Icon, Union_Team1_4_Icon, Union_Team1_5_Icon, Union_Team1_6_Icon}
	g_MemberIcons[2] = {Union_Team2_1_Icon, Union_Team2_2_Icon, Union_Team2_3_Icon, Union_Team2_4_Icon, Union_Team2_5_Icon, Union_Team2_6_Icon}
	g_MemberIcons[3] = {Union_Team3_1_Icon, Union_Team3_2_Icon, Union_Team3_3_Icon, Union_Team3_4_Icon, Union_Team3_5_Icon, Union_Team3_6_Icon}
	g_MemberIcons[4] = {Union_Team4_1_Icon, Union_Team4_2_Icon, Union_Team4_3_Icon, Union_Team4_4_Icon, Union_Team4_5_Icon, Union_Team4_6_Icon}
	g_MemberIcons[5] = {Union_Team5_1_Icon, Union_Team5_2_Icon, Union_Team5_3_Icon, Union_Team5_4_Icon, Union_Team5_5_Icon, Union_Team5_6_Icon}

	g_MemberCareers[1] = {Union_Team1_1_Career, Union_Team1_2_Career, Union_Team1_3_Career, Union_Team1_4_Career, Union_Team1_5_Career, Union_Team1_6_Career}
	g_MemberCareers[2] = {Union_Team2_1_Career, Union_Team2_2_Career, Union_Team2_3_Career, Union_Team2_4_Career, Union_Team2_5_Career, Union_Team2_6_Career}
	g_MemberCareers[3] = {Union_Team3_1_Career, Union_Team3_2_Career, Union_Team3_3_Career, Union_Team3_4_Career, Union_Team3_5_Career, Union_Team3_6_Career}
	g_MemberCareers[4] = {Union_Team4_1_Career, Union_Team4_2_Career, Union_Team4_3_Career, Union_Team4_4_Career, Union_Team4_5_Career, Union_Team4_6_Career}
	g_MemberCareers[5] = {Union_Team5_1_Career, Union_Team5_2_Career, Union_Team5_3_Career, Union_Team5_4_Career, Union_Team5_5_Career, Union_Team5_6_Career}

	g_MemberLevels[1] = {Union_Team1_1_Level, Union_Team1_2_Level, Union_Team1_3_Level, Union_Team1_4_Level, Union_Team1_5_Level, Union_Team1_6_Level}
	g_MemberLevels[2] = {Union_Team2_1_Level, Union_Team2_2_Level, Union_Team2_3_Level, Union_Team2_4_Level, Union_Team2_5_Level, Union_Team2_6_Level}
	g_MemberLevels[3] = {Union_Team3_1_Level, Union_Team3_2_Level, Union_Team3_3_Level, Union_Team3_4_Level, Union_Team3_5_Level, Union_Team3_6_Level}
	g_MemberLevels[4] = {Union_Team4_1_Level, Union_Team4_2_Level, Union_Team4_3_Level, Union_Team4_4_Level, Union_Team4_5_Level, Union_Team4_6_Level}
	g_MemberLevels[5] = {Union_Team5_1_Level, Union_Team5_2_Level, Union_Team5_3_Level, Union_Team5_4_Level, Union_Team5_5_Level, Union_Team5_6_Level}

	g_UnifiedPosition = Union_Frame:GetProperty("UnifiedPosition")

	for i = 1, 5 do
		for j = 1, 6 do
			if g_MemberDragItems[i][j] ~= nil then
				g_MemberDragItems[i][j]:SetProperty("DragAlpha", 1)
			end
		end
	end
end

--===============================================
-- OnEvent
--===============================================
function UnionFrame_OnEvent(event)
	if (event == "OPEN_WINDOW") then
		if arg0 == "UnionFrame" then
			g_CurSelMemSquad, g_CurSelMemIndex = Player:GetMyRaidIndex()
			g_CurSelMemSquad = g_CurSelMemSquad + 1
			g_CurSelMemIndex = g_CurSelMemIndex + 1
			UnionFrame_ClearUIInfo()
			UnionFrame_UpdateFrame()
			Union_Button_Frame0:SetText("#{TDGZ_XML_14}")
			g_IsShowAllSquad = 0
			this:Show()
		end
	elseif (event == "DRAG_DROP_ITEM" and this:IsVisible() == true) then
		local sSquad = 0
		local sMem =0
		local dSquad = 0
		local dMem = 0

		local isFind = 0
		for i = 1, 5 do
			for j = 1, 6 do
				if arg0 == g_DragItemNames[i][j] then
					sSquad = i
					sMem = j
					isFind = 1
					break
				end
			end
			if isFind == 1 then
				break
			end
		end
		if isFind == 1 then
			if arg0 == arg1 then
				Raid:OpenSquadMemWindowByIdx(sSquad - 1, sMem - 1, tonumber(arg2),tonumber(arg3))
			else
				isFind = 0
				for i = 1, 5 do
					for j = 1, 6 do
						if arg1 == g_DragTargetNames[i][j] then
							dSquad = i
							dMem = j
							isFind = 1
							break
						end
					end
					if isFind == 1 then
						break
					end
				end
				if isFind == 1 then
					Raid:ExchangeMemberPosition(sSquad - 1, sMem - 1, dSquad - 1, dMem - 1)
				end
			end
		end
	elseif (event == "RAID_UPDATE_RAID_FRAME") then
		if this:IsVisible() then
			g_NeedUpdateFakeObj = tonumber(arg2);
			if tonumber(arg0) == -1 and tonumber(arg1) == -1 then
				UnionFrame_ClearUIInfo()
				UnionFrame_UpdateFrame()
			else
				UnionFrame_UpdateMember(tonumber(arg0), tonumber(arg1))
			end
			g_NeedUpdateFakeObj = 1;
		end
	elseif (event == "RAID_CLOSE_RAID_FRAME") then
		if this:IsVisible() then
			UnionFrame_CloseWindow()
		end
	elseif (event == "RAID_SQUAD_WINDOW_HIDE") then
		local cloaseIdx = tonumber(arg0)
		if cloaseIdx < -1 or cloaseIdx > 4 then
			return
		end
		if cloaseIdx == -1 then
			for i = 1, 5 do
				g_IsSquadWindowShow[i] = 0
				--Add By YPL, 2011-12-14
				SetShowState(i-1, -1)
				--End
				g_SquadButtons[i]:SetToolTip("#{TDGZ_100809_27}")
			end
			Union_Button_Frame0:SetText("#{TDGZ_XML_14}")
			g_IsShowAllSquad = 0
		else
			cloaseIdx = cloaseIdx + 1
			--Add By YPL, 2011-12-13
			if GetShowState(cloaseIdx-1) ~= -1 and g_IsSquadWindowShow[cloaseIdx] ~= 0 then
				g_IsSquadWindowShow[cloaseIdx] = 1
				return
			end
			--End
			g_IsSquadWindowShow[cloaseIdx] = 0
			if this:IsVisible() then
				g_SquadButtons[cloaseIdx]:SetToolTip("#{TDGZ_100809_27}")
			end
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		if this:IsVisible() then
			Union_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		UnionFrame_CloseWindow()
	elseif (event == "RAID_SELECT_MEMBER") then
		local squad,mem = Raid:GetMemberIndexByGUID(arg0)
		Raid:SelectAsTargetByIdx(squad, mem)
	elseif (event == "RAID_SHOWALLSQUAD") then
		UnionFrame_ShowAllSquad()
	elseif (event == "DRAG_DROP_LOST_CAPTURE") then
		if this:IsVisible() then
			for i = 1, table.getn(g_MemberDragTargets) do
				g_MemberDragTargets[i]:SetProperty("HoverState", "False")
			end
		end
	end
end

function UnionFrame_UpdateFrame()
	local memCount = Raid:GetMemCount()
	if memCount > 0 then
		for idx = 1, 5 do
			if Raid:IsRaidSquadWindowShow(idx - 1) == 1 then
				g_SquadButtons[idx]:SetToolTip("#{TDGZ_100809_28}")
				g_IsSquadWindowShow[idx] = 1
			else
				g_SquadButtons[idx]:SetToolTip("#{TDGZ_100809_27}")
				g_IsSquadWindowShow[idx] = 0
			end
		end

		for i = 1, 5 do
			for j = 1, 6 do
				local name, menpai, level, dead, offline, scene = Raid:GetMemberInfoByIdx(i - 1, j - 1)
				if level > 0 then
					g_MemberDragItems[i][j]:SetProperty("DraggingEnabled", "True")

					if menpai < 0 or menpai > g_MenPaiCount then
						menpai = 8
					end
					menpai = menpai + 1

					local textColor = ""
					if dead == 1 then
						textColor = "#cff0000"
					elseif offline == 1 then
						textColor = "#ccccccc"
					else
						textColor = g_TextColors[menpai]
					end

					g_MemberNames[i][j]:SetText(textColor .. name)
					g_MemberCareers[i][j]:SetText(textColor .. g_MenpaiNames[menpai])
					g_MemberLevels[i][j]:SetText(textColor .. tostring(level))

					local position = Raid:IsLeaderByIdx(i - 1, j - 1)
					if 1 == position then
						--团长
						g_MemberDragItems[i][j]:SetToolTip("#{TDGZ_100809_85}" .. "#{TDGZ_XML_11}" .. scene)		--Tip：【团长】所在地：XXX
						g_MemberIcons[i][j]:SetProperty("Image", g_RaidLeaderIcon2)
						g_MemberIcons[i][j]:Show()
					elseif 2 == position then
						--助理
						g_MemberDragItems[i][j]:SetToolTip("#{TDGZ_100809_86}" .. "#{TDGZ_XML_11}" .. scene)		--Tip：【助理】所在地：XXX
						g_MemberIcons[i][j]:SetProperty("Image", g_RaidAssistantIcon2)
						g_MemberIcons[i][j]:Show()
					else
						g_MemberDragItems[i][j]:SetToolTip("#{TDGZ_XML_11}" .. scene)														--Tip：所在地：XXX
						g_MemberIcons[i][j]:Hide()
					end
					memCount = memCount - 1
				end

				if memCount == 0 then
					break
				end
			end
			if memCount == 0 then
					break
			end
		end

		if Player:IsRaidLeader() == 1 then
			Union_Button_Frame1:Show()	--“申请列表”按钮
			if Raid:GetApplicantCount() > 0 then
				Union_Button_Frame1:Enable()
			end
		elseif Player:IsRaidAssitant() == 1 then
		else
		end
		if (g_NeedUpdateFakeObj == 1) then
			--选中成员的外观窗口
			local strModelName = Raid:SetModelLookByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
			UnionFrame_FakeObject1:SetFakeObject(strModelName)
		end
		Union_Model_Disable:Hide()
		if strModelName ~= "" then
			local _, smenpai, slevel, seldead, seloffline, _, zoneWorldID,_,_,FightScore,GuildName = Raid:GetMemberInfoByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
			if smenpai < 0 or smenpai > g_MenPaiCount then
				smenpai = 8
			end
			smenpai = smenpai + 1

			local sColor = ""
			if seldead == 1 then
				sColor = "#cff0000"
			elseif seloffline == 1 then
				sColor = "#ccccccc"
			else
				sColor = g_TextColors[smenpai]
			end

			Union_Model_Career:SetText(sColor .. g_MenpaiNames[smenpai])
			Union_Model_Level:SetText(sColor .. tostring(slevel))
            --- 显示服务器名
            UnionFrame_ShowServerName( zoneWorldID )
			UnionFrame_ShowPingFen(FightScore)
			UnionFrame_ShowBanghui(GuildName)

			--外观窗口上的死亡/掉线图标
			Union_Die_Icon:Hide()
			Union_Downline_Icon:Hide()
			if seldead == 1 then
				Union_Die_Icon:Show()
			elseif seloffline == 1 then
				Union_Downline_Icon:Show()
			end

			--外观窗口上的团长图标
			Union_Captain_Icon:Hide()
			-- if Raid:IsLeaderByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1) == 1 then
				-- --团长
				-- -- Union_Captain_Icon:SetProperty("Image", g_RaidLeaderIcon1)
				-- -- Union_Captain_Icon:Show()
			-- elseif Raid:IsLeaderByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1) == 2 then
				-- --助理
				-- -- Union_Captain_Icon:SetProperty("Image", g_RaidAssistantIcon1)
				-- -- Union_Captain_Icon:Show()
			-- else
				-- Union_Captain_Icon:Hide()
			-- end

			local realIdx = (g_CurSelMemSquad - 1) * 6 + g_CurSelMemIndex
			if realIdx > 0 and realIdx <= table.getn(g_MemberDragTargets) then
				g_MemberDragTargets[realIdx]:SetProperty("HoverState", "True")
			end

			local sameScene = Raid:IsMemberInSceneByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
			if sameScene == 1 then
				Union_Model_Disable:Hide()
			else
				Union_Model_Disable:Show()
			end
		end

		for i = 1, 5 do
			g_SquadButtons[i]:Show()
			g_SquadButtonsHover[i]:Hide()
		end
		local mySquad, _ = Player:GetMyRaidIndex()
		mySquad = mySquad + 1
		if mySquad >= 1 and mySquad <= 5 then
			g_SquadButtons[mySquad]:Hide()
			g_SquadButtonsHover[mySquad]:Show()
		end
	end
end

function UnionFrame_ClearUIInfo()
	if (g_NeedUpdateFakeObj == 1) then
		UnionFrame_FakeObject1:SetFakeObject("")
	end
	Union_Die_Icon:Hide()
	Union_Downline_Icon:Hide()
	Union_Captain_Icon:Hide()
	Union_Model_Disable:Hide()
	for i = 1, 5 do
		for j = 1, 6 do
			g_MemberDragItems[i][j]:SetProperty("DraggingEnabled", "False")
			g_MemberDragItems[i][j]:SetToolTip("")
			g_MemberNames[i][j]:SetText("")
			g_MemberIcons[i][j]:Hide()
			g_MemberCareers[i][j]:SetText("")
			g_MemberLevels[i][j]:SetText("")
		end
	end
	Union_Button_Frame1:Disable()
	Union_Button_Frame1:Hide()
	Union_Model_Career:SetText("")
	Union_Model_Level:SetText("")
    Union_Model_FuWuQi:SetText("")
	Union_Model_PingFen:SetText("")
	Union_Model_Banghui:SetText("")
	for i = 1, table.getn(g_MemberDragTargets) do
		g_MemberDragTargets[i]:SetProperty("HoverState", "False")
	end
end

function UnionFrame_CloseWindow()
	UnionFrame_ClearUIInfo()
	this:Hide()
end

function UnionFrame_SquadButton_Clicked(stridx)
	local idx = tonumber(stridx)
	if g_IsSquadWindowShow[idx] == 0 then
		local ret = Raid:OpenRaidSquadWindowByIdx(idx - 1, 1, -1, -1) -- Modify By YPL, 2011-12-19
		--SetShowState(idx - 1, 0) --Add By YPL, 2011-12-05
		if ret == 1 then
			g_SquadButtons[idx]:SetToolTip("#{TDGZ_100809_28}")
			g_IsSquadWindowShow[idx] = 1
			SetShowState(idx - 1, 1) --Add By YPL, 2011-12-19
		end
	elseif g_IsSquadWindowShow[idx] == 1 then
		SetShowState(idx - 1, -1) --Add By YPL, 2011-12-13
		local ret = Raid:CloseRaidSquadWindowByIdx(idx - 1)
		--Add By YPL, 2011-12-13
		if ret == 1 then
			g_IsSquadWindowShow[idx] = 0
		end
		--End
--		if ret == 1 then
--			g_SquadButtons[idx]:SetToolTip("#{TDGZ_100809_27}")
--			g_IsSquadWindowShow[idx] = 0
--		end
	end
end

function UnionFrame_Member_Clicked(squadIdx, memIdx)
	g_CurSelMemSquad = tonumber(squadIdx)
	g_CurSelMemIndex = tonumber(memIdx)

	Union_Model_Career:SetText("")
	Union_Model_Level:SetText("")
	Union_Die_Icon:Hide()
	Union_Downline_Icon:Hide()
	Union_Captain_Icon:Hide()
    Union_Model_FuWuQi:SetText("")
	Union_Model_PingFen:SetText("")
	Union_Model_Banghui:SetText("")
	for i = 1, table.getn(g_MemberDragTargets) do
		g_MemberDragTargets[i]:SetProperty("HoverState", "False")
	end

	--选中成员的外观窗口
	Raid:SelectAsTargetByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
	local strModelName = Raid:SetModelLookByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
	UnionFrame_FakeObject1:SetFakeObject(strModelName)

	Union_Model_Disable:Hide()
	if strModelName ~= "" then
		local _, smenpai, slevel, seldead, seloffline, _, zoneWorldID,_,_,FightScore,GuildName = Raid:GetMemberInfoByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
		if smenpai < 0 or smenpai > g_MenPaiCount then
			smenpai = 8
		end
		smenpai = smenpai + 1

		local sColor = ""
		if seldead == 1 then
			sColor = "#cff0000"
		elseif offline == 1 then
			sColor = "#ccccccc"
		else
			sColor = g_TextColors[smenpai]
		end

		Union_Model_Career:SetText(sColor .. g_MenpaiNames[smenpai])
		Union_Model_Level:SetText(sColor .. tostring(slevel))
        --- 显示服务器名
        UnionFrame_ShowServerName( zoneWorldID )
			UnionFrame_ShowPingFen(FightScore)
			UnionFrame_ShowBanghui(GuildName)
		--外观窗口上的死亡/掉线图标
		if seldead == 1 then
			Union_Die_Icon:Show()
		elseif seloffline == 1 then
			Union_Downline_Icon:Show()
		end

		--外观窗口上的团长图标
		Union_Captain_Icon:Hide()
		-- if Raid:IsLeaderByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1) == 1 then
			-- --团长
			-- Union_Captain_Icon:SetProperty("Image", g_RaidLeaderIcon1)
			-- Union_Captain_Icon:Show()
		-- elseif Raid:IsLeaderByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1) == 2 then
			-- --助理
			-- Union_Captain_Icon:SetProperty("Image", g_RaidAssistantIcon1)
			-- Union_Captain_Icon:Show()
		-- else
			-- Union_Captain_Icon:Hide()
		-- end

		local realIdx = (g_CurSelMemSquad - 1) * 6 + g_CurSelMemIndex
		if realIdx > 0 and realIdx <= table.getn(g_MemberDragTargets) then
			g_MemberDragTargets[realIdx]:SetProperty("HoverState", "True")
		end

		local sameScene = Raid:IsMemberInSceneByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
		if sameScene == 1 then
			Union_Model_Disable:Hide()
		else
			Union_Model_Disable:Show()
		end
	end
end

function UnionFrame_ToggleMemberMenu(squadIdx, memIdx)
	Raid:SelectAsTargetByIdx(tonumber(squadIdx) - 1, tonumber(memIdx) - 1)
	Raid:ShowMemberContMenu("RaidFrame", tonumber(squadIdx) - 1, tonumber(memIdx) - 1)
end

function UnionFrame_QuitRaid_Click()
	Player:LeaveRiad()
end

function UnionFrame_ShowAll_Click()
	if g_IsShowAllSquad == 0 then
		OpenWindow("Union_Ensure")
	else
		Raid:CloseRaidSquadWindowByIdx(-2)
		Union_Button_Frame0:SetText("#{TDGZ_XML_14}")
		g_IsShowAllSquad = 0
	end
end

function UnionFrame_ApplicationList_Click()
	Player:ShowRaidApplicationList()
	UnionFrame_CloseWindow()
end

function UnionFrame_ShowAllSquad()
	for i = 0,5 do
		local ret = Raid:OpenRaidSquadWindowByIdx(i - 1, 1, -1, -1) --Modify By YPL, 2011-12-19
		--SetShowState(i - 1, 0) --Add By YPL, 2011-12-05
		if ret == 1 then
			g_SquadButtons[i]:SetToolTip("#{TDGZ_100809_28}")
			SetShowState(i - 1, 1) --Add By YPL, 2011-12-19
			g_IsSquadWindowShow[i] = 1 --Add By YPL, 2011-12-13
		end
	end
	Union_Button_Frame0:SetText("#{TDGZ_XML_25}")
	g_IsShowAllSquad = 1
end

--function UnionFrame_Select1()
--	Raid:SelectAsTargetByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
--end

function Union_Button_Frame3_Click()
	--加好友
	local memGUID = Raid:GetMemberGUIDByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
	if memGUID ~= "" then
		if memGUID ~= Player:GetGUID() then
			local memName,zoneworldid = Raid:GetMemberNameByGUID(memGUID)
			if( memName == nil or memName == "") then
				return
			end
			DataPool:AddFriendAndGrouping(memName,zoneworldid)
		else
			PushDebugMessage("#{TDGZ_100809_83}")
		end
	end
end

function UnionFrame_UpdateMember(squadIdx, memIdx)
	local name, menpai, level, dead, offline, scene, zoneWorldID,_,_,FightScore,GuildName = Raid:GetMemberInfoByIdx(squadIdx - 1, memIdx - 1)
	if level > 0 then
		g_MemberDragItems[squadIdx][memIdx]:SetProperty("DraggingEnabled", "True")

		if menpai < 0 or menpai > g_MenPaiCount then
			menpai = 8
		end
		menpai = menpai + 1

		local textColor = ""
		if dead == 1 then
			textColor = "#cff0000"
		elseif offline == 1 then
			textColor = "#ccccccc"
		else
			textColor = g_TextColors[menpai]
		end

		g_MemberNames[squadIdx][memIdx]:SetText(textColor .. name)
		g_MemberCareers[squadIdx][memIdx]:SetText(textColor .. g_MenpaiNames[menpai])
		g_MemberLevels[squadIdx][memIdx]:SetText(textColor .. tostring(level))

		local position = Raid:IsLeaderByIdx(squadIdx - 1, memIdx - 1)
		if 1 == position then
			--团长
			g_MemberDragItems[squadIdx][memIdx]:SetToolTip("#{TDGZ_100809_85}" .. "#{TDGZ_XML_11}" .. scene)
			g_MemberIcons[squadIdx][memIdx]:SetProperty("Image", g_RaidLeaderIcon2)
			g_MemberIcons[squadIdx][memIdx]:Show()
		elseif 2 == position then
			--助理
			g_MemberDragItems[squadIdx][memIdx]:SetToolTip("#{TDGZ_100809_86}" .. "#{TDGZ_XML_11}" .. scene)
			g_MemberIcons[squadIdx][memIdx]:SetProperty("Image", g_RaidAssistantIcon2)
			g_MemberIcons[squadIdx][memIdx]:Show()
		else
			g_MemberDragItems[squadIdx][memIdx]:SetToolTip("#{TDGZ_XML_11}" .. scene)
			g_MemberIcons[squadIdx][memIdx]:Hide()
		end

		Union_Button_Frame1:Hide()
		if Player:IsRaidLeader() == 1 then
			Union_Button_Frame1:Show()	--“申请列表”按钮
			if Raid:GetApplicantCount() > 0 then
				Union_Button_Frame1:Enable()
			end
		elseif Player:IsRaidAssitant() == 1 then
		else
		end

		if squadIdx == g_CurSelMemSquad and memIdx == g_CurSelMemIndex then
			if (g_NeedUpdateFakeObj == 1) then
				--选中成员的外观窗口
				local strModelName = Raid:SetModelLookByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
				UnionFrame_FakeObject1:SetFakeObject(strModelName)
			end

			local textColor = ""
			if dead == 1 then
				textColor = "#cff0000"
			elseif offline == 1 then
				textColor = "#ccccccc"
			else
				textColor = g_TextColors[menpai]
			end

			Union_Model_Career:SetText(textColor .. g_MenpaiNames[menpai])
			Union_Model_Level:SetText(textColor .. tostring(level))
            --- 显示服务器名
            UnionFrame_ShowServerName( zoneWorldID )
			UnionFrame_ShowPingFen(FightScore)
			UnionFrame_ShowBanghui(GuildName)
			--外观窗口上的死亡/掉线图标
			Union_Die_Icon:Hide()
			Union_Downline_Icon:Hide()
			if dead == 1 then
				Union_Die_Icon:Show()
			elseif offline == 1 then
				Union_Downline_Icon:Show()
			end

			--外观窗口上的团长图标
			Union_Captain_Icon:Hide()
			-- if 1 == position then
				-- -- 团长
				-- Union_Captain_Icon:SetProperty("Image", g_RaidLeaderIcon1)
				-- Union_Captain_Icon:Show()
			-- elseif 2 == position then
				-- -- 助理
				-- Union_Captain_Icon:SetProperty("Image", g_RaidAssistantIcon1)
				-- Union_Captain_Icon:Show()
			-- else
				-- Union_Captain_Icon:Hide()
			-- end

			local sameScene = Raid:IsMemberInSceneByIdx(g_CurSelMemSquad - 1, g_CurSelMemIndex - 1)
			if sameScene == 1 then
				Union_Model_Disable:Hide()
			else
				Union_Model_Disable:Show()
			end
		end
	end
end

function UnionFrame_Member_DragStarted()
	g_CurSelMemSquad = -1
	g_CurSelMemIndex = -1

	Union_Model_Career:SetText("")
	Union_Model_Level:SetText("")
	Union_Die_Icon:Hide()
	Union_Downline_Icon:Hide()
	Union_Captain_Icon:Hide()
    Union_Model_FuWuQi:SetText("")
	for i = 1, table.getn(g_MemberDragTargets) do
		g_MemberDragTargets[i]:SetProperty("HoverState", "False")
	end

	UnionFrame_FakeObject1:SetFakeObject("")
	Union_Model_PingFen:SetText("")
	Union_Model_Banghui:SetText("")
	Union_Model_Disable:Hide()
end

--------------------------------------------------------------------------------------------------------------------
--
-- 显示服务器名
--
function UnionFrame_ShowServerName( ZoneWorldID )
    local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
    local strName = ""
    --- 只有自己的ZoneWorldID与传进来的参数不一致的时候，才需要显示服务器名
    if selfZoneWorldID ~= nil and selfZoneWorldID ~= -1 and ZoneWorldID ~= 0 and ZoneWorldID ~= -1 and selfZoneWorldID ~= ZoneWorldID then
        --- 得到服务器名称
        strName = DataPool:GetServerName( ZoneWorldID )
    end

	--- 设置显示的服务器名.
    if strName ~= nil then
       Union_Model_FuWuQi:SetText( tostring(strName) )
    end
end


--显示评分
function UnionFrame_ShowPingFen(szPingfen)
	if szPingfen ~= nil then
		Union_Model_PingFen:SetText("#{BHXX_160531_3}"..tostring(szPingfen))
	else
		Union_Model_PingFen:SetText("");
	end
end

--显示帮会
function UnionFrame_ShowBanghui(szBanghui)

	if szBanghui == nil then
		Union_Model_Banghui:SetText("");
		return
	end
		
	if szBanghui == nil or szBanghui == "" then
		Union_Model_Banghui:SetText("#{BHXX_160531_1}".."#{GMGameInterface_Script_DataPool_Info_None}")
	else
		Union_Model_Banghui:SetText("#{BHXX_160531_1}"..tostring(szBanghui))
	end
	
end

--Add By YPL, 2011-12-05
function GetShowState(index)
	if (index == nil) or (index < 0) or (index > 4) then
		return 2
	else
		return g_RaidList_ShowOrHide[index]
	end

end

function SetShowState(index, value)
	if (index ~= nil) and (index >= 0) and (index <= 4) and (g_RaidList_ShowOrHide[index] ~= nil) and ((value == 0) or (value == 1)or (value == -1)) then --Modify By YPL, 2011-12-14
		g_RaidList_ShowOrHide[index] = value
	end
end
--end



