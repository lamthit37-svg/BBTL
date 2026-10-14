-- 新6v6 查看已组建战队

local g_UnifiedPosition = nil

local g_TargetObjId = -1
local g_TargetSvrId = 0
local g_TeamCount = 0
local g_CurPage = 0
local g_MaxPage = 0
local g_MaxTeam = 0

local g_OpCD = 2000				-- 操作CD
local g_LastOpTime = 1			-- 最后操作的时间
local g_TeamCountPerPage = 10	-- 每页展示战队数量



function BW_CreatTeamList_PreLoad()
	this:RegisterEvent("XBW_TEAMINFOLIST_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end -- end func BW_CreatTeamList_PreLoad()

function BW_CreatTeamList_OnEvent(event)
	if event == "XBW_TEAMINFOLIST_SHOW" then
		local targetId = tonumber(arg0)
		local teamCount = tonumber(arg1)
		local teamMaxCount = tonumber(arg2)
		local startPage = tonumber(arg3)
		BW_CreatTeamList_OnShow(targetId, teamCount, teamMaxCount, startPage)
	elseif event == "ADJEST_UI_POS" then
		BW_CreatTeamList_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		BW_CreatTeamList_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		BW_CreatTeamList_CloseClicked()
	end
end -- end func BW_CreatTeamList_OnEvent()

function BW_CreatTeamList_OnLoad()
	BW_CreatTeamList_ResetControl()
	g_UnifiedPosition = BW_CreatTeamList_Frame:GetProperty("UnifiedPosition")
end -- end func BW_CreatTeamList_OnLoad()

function BW_CreatTeamList_ResetPos()
	BW_CreatTeamList_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
end -- end func BW_CreatTeamList_ResetPos()

function BW_CreatTeamList_ResetControl()
	BW_CreatTeamList_ListInfo:RemoveAllItem()
    BW_CreatTeamList_TeamInfo:Disable()
	local toptext = ScriptGlobal_Format("#{BWDH_241114_171}" , "0")
	BW_CreatTeamList_ExplainText:SetText(toptext)
	local szpage = ScriptGlobal_Format("#{BWDH_241114_179}", "0", "0")	-- 这个字典没给 暂时用争霸赛的
	BW_CreatTeamList_CurrentlyPage:SetText(szpage)

	BW_CreatTeamList_NumPage:SetText("")

	BW_CreatTeamList_UpPage:Disable()
	BW_CreatTeamList_DownPage:Disable()
end -- end func BW_CreatTeamList_ResetControl()

-- 战队列表控件选择点击事件
function BW_CreatTeamList_ListInfo_On_SelectionChanged()
    BW_CreatTeamList_TeamInfo:Enable()
end -- end func BW_CreatTeamList_ListInfo_On_SelectionChanged()

-- 战队详情按钮点击事件
function BW_CreatTeamList_TeamInfo_Clicked()
	local index = BW_CreatTeamList_ListInfo:GetSelectItem()
	if index < 0 then
		return
	end
	
	PushEvent("XBW_VIEWTEAMINFO_SHOW", index, 0)
end -- end func BW_CreatTeamList_TeamInfo_Clicked()

-- 上一页
function BW_CreatTeamList_Pre_Click()
	if BW_CreatTeamList_CheckOpCD() < 1 then
		return
	end

	NewXBW:AskTeamListInfo(g_TargetSvrId, g_CurPage-1)
end -- end func BW_CreatTeamList_Pre_Click()

-- 下一页
function BW_CreatTeamList_Next_Click()
	if BW_CreatTeamList_CheckOpCD() < 1 then
		return
	end

	NewXBW:AskTeamListInfo(g_TargetSvrId, g_CurPage+1)
end -- end func BW_CreatTeamList_Next_Click()

-- 跳转
function BW_CreatTeamList_GotoPageClicked()
	if BW_CreatTeamList_CheckOpCD() < 1 then
		return
	end

	local pageText = BW_CreatTeamList_NumPage:GetText()
	if (pageText == nil) then
		return
	end
	local pageNum = tonumber(pageText)
	if (pageNum == nil) then
		return
	end
	if (pageNum <= 0) then
		return
	end
	if (pageNum > g_MaxPage) then
		return
	end

	NewXBW:AskTeamListInfo(g_TargetSvrId, pageNum-1)
end -- end func BW_CreatTeamList_GotoPageClicked()

-- 关闭按钮事件
function BW_CreatTeamList_CloseClicked()
    this:Hide()
	if g_TargetObjId ~= -1 then
		this:CareObject(g_TargetObjId, 0, "BW_CreatTeamList")
	end
	g_TargetObjId = -1
	g_TargetSvrId = -1

	CloseWindow("BW_TeamInfo",true)
end -- end func BW_CreatTeamList_CloseClicked()

-- 说明帮助按钮事件
function BW_CreatTeamList_ExplainText_Help_Clicked()
	PushEvent("QUEST_HELP_MSG","#{BWDH_241114_172}")
end -- end func BW_CreatTeamList_ExplainText_Help_Clicked()

function BW_CreatTeamList_CheckOpCD()
	local curTime = FindFriendDataPool:GetTickCount()
	if curTime - g_LastOpTime < g_OpCD then
		PushDebugMessage("#{WCBZ_220809_49}")
		return 0
	else
		g_LastOpTime = curTime
	end

	return 1
end -- end func BW_CreatTeamList_CheckOpCD()

--*************************************************************************************************
-- 显示 刷新UI
--*************************************************************************************************
function BW_CreatTeamList_OnShow(nTargetId, nTeamCount, nTeamTotal, nStartPage)
	g_TeamCount = nTeamCount
	g_MaxTeam = nTeamTotal
	g_CurPage = nStartPage
	local maxPage = math.floor(nTeamTotal / g_TeamCountPerPage)
	if (math.mod(nTeamTotal, g_TeamCountPerPage) ~= 0) then
		maxPage = maxPage + 1
	end
	g_MaxPage = maxPage

	if nTargetId > 0 then
		g_TargetSvrId = nTargetId
		g_TargetObjId = DataPool:GetNPCIDByServerID(nTargetId)
		this:CareObject(g_TargetObjId, 1, "BW_CreatTeamList")
	end

	if IsWindowShow("BW_TeamInfo")  then
		CloseWindow("BW_TeamInfo", true)
	end
	
	-- local debugMsg = string.format("debug(1), create team list, team count: %d|%d, team max: %d|%d, cur page: %d|%d, max page: %d",
	-- 							g_TeamCount, nTeamCount,
	-- 							g_MaxTeam, nTeamTotal,
	-- 							g_CurPage, nStartPage,
	-- 							g_MaxPage)
	-- PushDebugMessage(debugMsg)

	BW_CreatTeamList_Update()

	this:Show()
end -- end func BW_CreatTeamList_OnShow()

function BW_CreatTeamList_Update()
    BW_CreatTeamList_ResetControl()

	local szDesc = ScriptGlobal_Format("#{BWDH_241114_171}", tostring(g_MaxTeam))
	BW_CreatTeamList_ExplainText:SetText(szDesc)

	local cnt = 0
	for i = 0, g_TeamCountPerPage-1 do
		local teamid, memcnt, worldId, teamname, teamleadername = NewXBW:GetTeamListInfo(i)
		if teamid ~= nil and teamid > 0 then
			local szTeamId = string.format("%03d", teamid)
			--local szmemcnt = ScriptGlobal_Format("#{BWDH_241114_197}", tostring(memcnt))
			BW_CreatTeamList_ListInfo:AddNewItem("#cfff263" .. szTeamId, 0, cnt)
    		BW_CreatTeamList_ListInfo:AddNewItem("#cfff263" .. teamname, 1, cnt)
			BW_CreatTeamList_ListInfo:AddNewItem("#cfff263" .. teamleadername, 2, cnt)
    		BW_CreatTeamList_ListInfo:AddNewItem("#cfff263" .. memcnt, 3, cnt)
			cnt = cnt + 1
        end
	end -- end for

	-- 这个字典没给 暂时用争霸赛的
	local curPageShow = g_CurPage+1
	if g_MaxPage == 0 then
		curPageShow = 0
	end	
	local szpage = ScriptGlobal_Format("#{BWDH_241114_179}", tostring(curPageShow), tostring(g_MaxPage))
	BW_CreatTeamList_CurrentlyPage:SetText(szpage)

	-- local debugMsg = string.format("debug(2), create team list, count: %d, cur page: %d, max page: %d",
	-- 							g_TeamCount,
	-- 							g_CurPage,
	-- 							g_MaxPage)
	-- PushDebugMessage(debugMsg)

	-- 有页可翻
	if (g_MaxPage > 1) then
		if (g_CurPage < 1) then
			BW_CreatTeamList_UpPage:Disable()
			BW_CreatTeamList_DownPage:Enable()
		elseif (g_CurPage == (g_MaxPage-1)) then
			BW_CreatTeamList_UpPage:Enable()
			BW_CreatTeamList_DownPage:Disable()
		else
			BW_CreatTeamList_UpPage:Enable()
			BW_CreatTeamList_DownPage:Enable()
		end
	else
		BW_CreatTeamList_UpPage:Disable()
		BW_CreatTeamList_DownPage:Disable()
	end 
end -- end func BW_CreatTeamList_Update()
