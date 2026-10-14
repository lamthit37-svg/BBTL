local g_WorldBoss_RoomList_UnifiedPosition;
local g_UICOMMAND = 89039003
local g_ExeScript = 890390
local g_State = 0
local g_UI_Items = {}
local g_PageItemNum = 10
local g_CurPage = 1
function WorldBoss_RoomList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	
end
function WorldBoss_RoomList_OnLoad()	
	g_WorldBoss_RoomList_UnifiedPosition  =WorldBoss_RoomList_Frame:GetProperty("UnifiedPosition");
	g_UI_Items.pageItems = {}
	for i = 1, g_PageItemNum do
		g_UI_Items.pageItems[i] = {
			rIndex = _G[string.format( "WorldBoss_RoomList_Player%dRank",i)],
			leadName = _G[string.format( "WorldBoss_RoomList_Player%dName",i)],
			serverName = _G[string.format( "WorldBoss_RoomList_Player%dServer",i)],
			mempai = _G[string.format( "WorldBoss_RoomList_Player%dCareer",i)],
			level = _G[string.format( "WorldBoss_RoomList_Player%dLevel",i)],
			point = _G[string.format( "WorldBoss_RoomList_Player%dPoint",i)],
			bk = _G[string.format( "WorldBoss_RoomList_Player%d_Client",i)],
		}
	end
	g_UI_Items.MyRankInfo = {
		rIndex = WorldBoss_RoomList_MyselfRank,
		leadName = WorldBoss_RoomList_MyselfName,
		serverName = WorldBoss_RoomList_MyselfServer,
		mempai = WorldBoss_RoomList_MyselfCareer,
		level = WorldBoss_RoomList_MyselfLevel,
		point = WorldBoss_RoomList_MyselfPoint,
	} 
	g_UI_Items.pageUpBtn = WorldBoss_RoomList_Flip_Flip_UpPage
	g_UI_Items.pageDownBtn = WorldBoss_RoomList_Flip_Flip_DownPage
	g_UI_Items.curPageNum = WorldBoss_RoomList_Flip_Flip_CurrentlyPage
end

function WorldBoss_RoomList_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
		local refresh =  Get_XParam_INT( 0 );
		if refresh == 1 then
			WorldBoss_RoomList_OpenPage(g_CurPage)
			PushDebugMessage("#{SJBS_240124_72}")
		else
			WorldBoss_RoomList_OpenPage(1)
		end
		WorldBoss_RoomList_SetMyTeamInfo()
		this:Show()
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		WorldBoss_RoomList_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WorldBoss_RoomList_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
end


function WorldBoss_RoomList_On_ResetPos()
	WorldBoss_RoomList_Frame:SetProperty("UnifiedPosition", g_WorldBoss_RoomList_UnifiedPosition);
end

function WorldBoss_RoomList_OpenPage(pageIndex)
	if pageIndex < 1 then
		return 
	end
	local rIndexBegin = (pageIndex-1)*g_PageItemNum+1
	local rIndexEnd = pageIndex*g_PageItemNum
	local totalNum = Lua_GetTWBSceneRankNum()

	if totalNum > 0 and rIndexBegin > totalNum then
		return 
	end

	g_CurPage = pageIndex

	local curIndex = rIndexBegin
	for i = 1, g_PageItemNum do
		local tableRankTeamInfo = Lua_GetTWBSceneRankTeamInfo(curIndex)
		if tableRankTeamInfo then
			g_UI_Items.pageItems[i].rIndex:SetText(tostring(curIndex))
			g_UI_Items.pageItems[i].leadName:SetText(tableRankTeamInfo.memName1)
			g_UI_Items.pageItems[i].serverName:SetText(tableRankTeamInfo.serverName)
			g_UI_Items.pageItems[i].mempai:SetText(GetMenpaiByID(tableRankTeamInfo.mempai))
			g_UI_Items.pageItems[i].level:SetText(tostring(tableRankTeamInfo.level))
			g_UI_Items.pageItems[i].point:SetText(tostring(tableRankTeamInfo.point))
			local teamMemName = "队伍成员：\n"
			for i = 1, 6 do
				local str = tableRankTeamInfo["memName"..i]
				if not str or str == "" then
					break
				end
				if i > 1 then
					teamMemName = teamMemName.."\n"
				end
				teamMemName = teamMemName..str
			end
			g_UI_Items.pageItems[i].bk:SetToolTip(teamMemName)
			g_UI_Items.pageItems[i].bk:SetCheck(0)
		else
			g_UI_Items.pageItems[i].rIndex:SetText("")
			g_UI_Items.pageItems[i].leadName:SetText("")
			g_UI_Items.pageItems[i].serverName:SetText("")
			g_UI_Items.pageItems[i].mempai:SetText("")
			g_UI_Items.pageItems[i].level:SetText("")
			g_UI_Items.pageItems[i].point:SetText("")
			g_UI_Items.pageItems[i].bk:SetToolTip("")
			g_UI_Items.pageItems[i].bk:SetCheck(0)
		end
		curIndex = curIndex + 1
	end

	g_UI_Items.curPageNum:SetText(tostring(g_CurPage))
	if rIndexEnd >= totalNum then
		g_UI_Items.pageDownBtn:Disable()
	else
		g_UI_Items.pageDownBtn:Enable()
	end
	if rIndexBegin == 1 then
		g_UI_Items.pageUpBtn:Disable()
	else
		g_UI_Items.pageUpBtn:Enable()
	end

end

function WorldBoss_RoomList_SetMyTeamInfo()
	local tableRankTeamInfo = Lua_GetTWBMySceneRankTeamInfo()
	local myrIndex = Lua_GetTWBMySceneRankIndex()
	if tableRankTeamInfo then
			if myrIndex > 0 then
				g_UI_Items.MyRankInfo.rIndex:SetText(tostring(myrIndex))
			elseif g_UI_Items.MyRankInfo.level == 0 then
				g_UI_Items.MyRankInfo.rIndex:SetText("不在小队中")
			else
				g_UI_Items.MyRankInfo.rIndex:SetText("#{SJBS_240124_198}")
			end
			if tableRankTeamInfo.level == 0 then
				g_UI_Items.MyRankInfo.leadName:SetText("")
				g_UI_Items.MyRankInfo.serverName:SetText("")
				g_UI_Items.MyRankInfo.mempai:SetText("")
				g_UI_Items.MyRankInfo.level:SetText("")
				g_UI_Items.MyRankInfo.point:SetText("")
			else
				g_UI_Items.MyRankInfo.leadName:SetText(tableRankTeamInfo.memName1)
				g_UI_Items.MyRankInfo.serverName:SetText(tableRankTeamInfo.serverName)
				g_UI_Items.MyRankInfo.mempai:SetText(GetMenpaiByID(tableRankTeamInfo.mempai))
				g_UI_Items.MyRankInfo.level:SetText(tostring(tableRankTeamInfo.level))
				g_UI_Items.MyRankInfo.point:SetText(tostring(tableRankTeamInfo.point))
			end
	else
		g_UI_Items.MyRankInfo.rIndex:SetText("")
		g_UI_Items.MyRankInfo.leadName:SetText("")
		g_UI_Items.MyRankInfo.serverName:SetText("")
		g_UI_Items.MyRankInfo.mempai:SetText("")
		g_UI_Items.MyRankInfo.level:SetText("")
		g_UI_Items.MyRankInfo.point:SetText("")
	end
end

function WorldBoss_RoomList_Flip_Flip_UpPage_Clicked()
	WorldBoss_RoomList_OpenPage(g_CurPage-1)
end

function WorldBoss_RoomList_Flip_Flip_DownPage_Clicked()
	WorldBoss_RoomList_OpenPage(g_CurPage+1)
end

function WorldBoss_RoomList_Flip_LastPage_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskOpenSceneRankList" )
		Set_XSCRIPT_ScriptID(g_ExeScript)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


function WorldBoss_RoomList_OnClose()
	this:Hide()
end