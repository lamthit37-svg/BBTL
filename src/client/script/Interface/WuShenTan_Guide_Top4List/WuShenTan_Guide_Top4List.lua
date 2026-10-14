--WuShenTan_Guide_Top4List.lua
local g_WuShenTan_Guide_Top4List_Frame_UnifiedPosition
local g_WuShenTan_Guide_Top4List_ShowStage = 0
local g_WuShenTan_Guide_Top4List_Count = 4
local g_WuShenTan_Guide_Top4List_MemberCount = 6
local g_WuShenTan_Guide_Top4List_Widget = {}

function WuShenTan_Guide_Top4List_PreLoad()
	--第二个参数代表界面隐藏时事件是否有效,默认为true
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("OPEN_WSTGUIDE_ALLZONETEAM", true)
end

function WuShenTan_Guide_Top4List_OnLoad()
	g_WuShenTan_Guide_Top4List_Frame_UnifiedPosition = WuShenTan_Guide_Top4List_Frame:GetProperty("UnifiedPosition")
	for i = 1, g_WuShenTan_Guide_Top4List_Count do
		g_WuShenTan_Guide_Top4List_Widget[i] = {
			winTeamName = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i],
			memberName1 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member1"],
			memberName2 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member2"],
			memberName3 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member3"],
			memberName4 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member4"],
			memberName5 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member5"],
			memberName6 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member6"],
			memberMenpai1 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member1_MP"],
			memberMenpai2 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member2_MP"],
			memberMenpai3 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member3_MP"],
			memberMenpai4 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member4_MP"],
			memberMenpai5 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member5_MP"],
			memberMenpai6 = _G["WuShenTan_Guide_Top4List_WinTeamName" .. i .. "_Member6_MP"],
		}
	end
	local indexStr = ScriptGlobal_Format("#{WSZH_260408_101}","1")
	WuShenTan_Guide_Top4List_WinTeam1_IndexNum:SetText(indexStr)
	indexStr = ScriptGlobal_Format("#{WSZH_260408_101}","2")
	WuShenTan_Guide_Top4List_WinTeam2_IndexNum:SetText(indexStr)
	indexStr = ScriptGlobal_Format("#{WSZH_260408_101}","3")
	WuShenTan_Guide_Top4List_WinTeam3and4_IndexNum:SetText(indexStr)
end

-- Event
function WuShenTan_Guide_Top4List_OnEvent(event)
	if event == "OPEN_WSTGUIDE_ALLZONETEAM" then
		g_WuShenTan_Guide_Top4List_ShowStage = tonumber(arg0)
		WuShenTan_Guide_Top4List_Update()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		WuShenTan_Guide_Top4List_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WuShenTan_Guide_Top4List_Close()
	elseif event == "ADJEST_UI_POS" then
		WuShenTan_Guide_Top4List_On_ResetPos()
	end
end

-- 重置界面位置
function WuShenTan_Guide_Top4List_On_ResetPos()
	WuShenTan_Guide_Top4List_Frame:SetProperty("UnifiedPosition", g_WuShenTan_Guide_Top4List_Frame_UnifiedPosition)
end

function WuShenTan_Guide_Top4List_InitialData()
	g_WuShenTan_Guide_Top4List_ShowStage = 0
end

-- 关闭
function WuShenTan_Guide_Top4List_Close()
	WuShenTan_Guide_Top4List_InitialData()
	this:Hide()
end

-- 刷新界面
function WuShenTan_Guide_Top4List_Update()
	if g_WuShenTan_Guide_Top4List_ShowStage == 0 then
		this:Hide()
	elseif g_WuShenTan_Guide_Top4List_ShowStage == 1 then

		local SourceData = {
			[1] = { teamZwid = -1, isGuidValid = {}, memberName = {}, memberMenpai = {}, matchRound = 0, matchResult = 0,},
			[2] = { teamZwid = -1, isGuidValid = {}, memberName = {}, memberMenpai = {}, matchRound = 0, matchResult = 0,},
			[3] = { teamZwid = -1, isGuidValid = {}, memberName = {}, memberMenpai = {}, matchRound = 0, matchResult = 0,},
			[4] = { teamZwid = -1, isGuidValid = {}, memberName = {}, memberMenpai = {}, matchRound = 0, matchResult = 0,},
		}
		for i = 0, g_WuShenTan_Guide_Top4List_Count-1 do
			SourceData[i+1].teamZwid ,
			_,
			_,
			_,
			SourceData[i+1].matchRound ,
			SourceData[i+1].matchResult 
			= DataPool:LuaFnWSTGetAllZoneTeamInfoByIndex(i,0)
			for j = 0, g_WuShenTan_Guide_Top4List_MemberCount-1 do
				_,
				SourceData[i+1].isGuidValid[j+1],
				SourceData[i+1].memberName[j+1],
				SourceData[i+1].memberMenpai[j+1],
				_,
				_
				= DataPool:LuaFnWSTGetAllZoneTeamInfoByIndex(i,j)
			end
		end
		table.sort(SourceData, function(a, b)
			if a.matchRound ~= b.matchRound then
				return a.matchRound > b.matchRound
			else
				local aPriority = a.matchResult == 2 and 1 or 0
				local bPriority = b.matchResult == 2 and 1 or 0
				return aPriority > bPriority
			end
		end)
		for i = 0, g_WuShenTan_Guide_Top4List_Count-1 do
			if SourceData[i+1] ~= nil and g_WuShenTan_Guide_Top4List_Widget[i+1] ~= nil then
				local teamzwid = SourceData[i+1].teamZwid
				local isEmpty = 0
				local worldName = "#{WSZH_260408_137}"
				if teamzwid == nil or teamzwid <= 0 then
					isEmpty = 1
					g_WuShenTan_Guide_Top4List_Widget[i+1].winTeamName:SetText(worldName)
				else
					isEmpty = 0
					worldName = DataPool:GetServerName(tonumber(teamzwid))
					if worldName ~= nil and worldName ~= "" then
						local worldNameStr = ScriptGlobal_Format("#{WSZH_260408_102}",worldName)
						g_WuShenTan_Guide_Top4List_Widget[i+1].winTeamName:SetText(worldNameStr)
					else
						g_WuShenTan_Guide_Top4List_Widget[i+1].winTeamName:SetText(worldName)
					end
					--debug
					--g_WuShenTan_Guide_Top4List_Widget[i+1].winTeamName:SetText("" .. ":" .. tostring(SourceData[i+1].matchRound)..":"..tostring(SourceData[i+1].matchResult))
				end
				local memberNameWidget = {}
				memberNameWidget[1] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName1
				memberNameWidget[2] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName2
				memberNameWidget[3] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName3
				memberNameWidget[4] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName4
				memberNameWidget[5] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName5
				memberNameWidget[6] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName6
				local memberMenpaiWidget = {}
				memberMenpaiWidget[1] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai1
				memberMenpaiWidget[2] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai2
				memberMenpaiWidget[3] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai3
				memberMenpaiWidget[4] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai4
				memberMenpaiWidget[5] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai5
				memberMenpaiWidget[6] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai6
				for j = 0, g_WuShenTan_Guide_Top4List_MemberCount-1 do
					if memberNameWidget[j+1] ~= nil and memberMenpaiWidget[j+1] ~= nil then
						memberMenpaiWidget[j+1]:Show()
						if isEmpty == 1 or (SourceData[i+1].isGuidValid[j+1] ~= nil and SourceData[i+1].isGuidValid[j+1] == 0) then
							memberNameWidget[j+1]:SetText("#{WSZH_260408_137}")
							memberMenpaiWidget[j+1]:Hide()
						else
							if SourceData[i+1].memberName[j+1] ~= nil then
								local memberNameStr = ScriptGlobal_Format("#{WSZH_260408_103}",SourceData[i+1].memberName[j+1])
								memberNameWidget[j+1]:SetText(memberNameStr)
							end
							if SourceData[i+1].memberMenpai[j+1] ~= nil then
								local mempaiName = GetMenpaiByID(SourceData[i+1].memberMenpai[j+1])
								local memberMenpaiStr = ScriptGlobal_Format("#{WSZH_260408_121}",mempaiName)
								memberMenpaiWidget[j+1]:SetText(memberMenpaiStr)
							end
						end
					end
				end 
			end 
		end
		this:Show()
	elseif g_WuShenTan_Guide_Top4List_ShowStage == 2 then
		--直接虚位以待
		for i = 0, g_WuShenTan_Guide_Top4List_Count-1 do
			local worldName = "#{WSZH_260408_137}"
			g_WuShenTan_Guide_Top4List_Widget[i+1].winTeamName:SetText(worldName)
			local memberNameWidget = {}
			memberNameWidget[1] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName1
			memberNameWidget[2] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName2
			memberNameWidget[3] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName3
			memberNameWidget[4] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName4
			memberNameWidget[5] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName5
			memberNameWidget[6] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberName6
			local memberMenpaiWidget = {}
			memberMenpaiWidget[1] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai1
			memberMenpaiWidget[2] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai2
			memberMenpaiWidget[3] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai3
			memberMenpaiWidget[4] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai4
			memberMenpaiWidget[5] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai5
			memberMenpaiWidget[6] = g_WuShenTan_Guide_Top4List_Widget[i+1].memberMenpai6
			for j = 0, g_WuShenTan_Guide_Top4List_MemberCount-1 do
				memberNameWidget[j+1]:SetText("#{WSZH_260408_137}")
				memberMenpaiWidget[j+1]:Hide()
			end
		end
		this:Show()
	end
end
