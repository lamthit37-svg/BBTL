--!!!reloadscript =DaHua_List
local g_DaHua_List_UnifiedPosition;
local g_UICOMMAND = 05112803
local g_ExeScript = 051128
local g_State = 0
local g_UI_Items = {}
local g_PageItemNum = 10
local g_CurPage = 1
function DaHua_List_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REFRESH_QIXIPVEWAR_SCORE")
	
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	
end
function DaHua_List_OnLoad()	
	g_DaHua_List_UnifiedPosition  =DaHua_List_Frame:GetProperty("UnifiedPosition");
	g_UI_Items.pageItems = {}
	for i = 1, g_PageItemNum do
		g_UI_Items.pageItems[i] = {
			rIndex = _G[string.format( "DaHua_List_Player%dRank",i)],
			leadName = _G[string.format( "DaHua_List_Player%dName",i)],
			serverName = _G[string.format( "DaHua_List_Player%dServer",i)],
			mempai = _G[string.format( "DaHua_List_Player%dCareer",i)],
			level = _G[string.format( "DaHua_List_Player%dLevel",i)],
			point = _G[string.format( "DaHua_List_Player%dPoint",i)],
			bk = _G[string.format( "DaHua_List_Player%d_Client",i)],
		}
	end
	g_UI_Items.MyRankInfo = {
		rIndex = DaHua_List_MyselfRank,
		leadName = DaHua_List_MyselfName,
		serverName = DaHua_List_MyselfServer,
		mempai = DaHua_List_MyselfCareer,
		level = DaHua_List_MyselfLevel,
		point = DaHua_List_MyselfPoint,
	} 
	g_UI_Items.pageUpBtn = DaHua_List_Flip_Flip_UpPage
	g_UI_Items.pageDownBtn = DaHua_List_Flip_Flip_DownPage
	g_UI_Items.curPageNum = DaHua_List_Flip_Flip_CurrentlyPage
end

function DaHua_List_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
		local refresh =  Get_XParam_INT( 0 );
		if refresh == 2 then
			DaHua_List_OpenPage(g_CurPage)
			--PushDebugMessage("#{SJBS_240124_72}")
		else
			DaHua_List_OpenPage(1)
		end
		DaHua_List_SetMyTeamInfo()

		this:Show()
	end
	if event ==  "REFRESH_QIXIPVEWAR_SCORE" then
		if tonumber(arg0) == 2 then
			--刷新
			if (this:IsVisible()) then
				DaHua_List_OpenPage(g_CurPage)
				DaHua_List_SetMyTeamInfo()
			end
		elseif  tonumber(arg0) == 1 then
			--打开
			DaHua_List_OpenPage(1)
			DaHua_List_SetMyTeamInfo()
			this:Show()
			PushDebugMessage("#{QXPVE_240628_31}")
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		DaHua_List_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DaHua_List_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
end


function DaHua_List_On_ResetPos()
	DaHua_List_Frame:SetProperty("UnifiedPosition", g_DaHua_List_UnifiedPosition);
end

function DaHua_List_OpenPage(pageIndex)
	if pageIndex < 1 then
		return 
	end
	local rIndexBegin = (pageIndex-1)*g_PageItemNum+1
	local rIndexEnd = pageIndex*g_PageItemNum
	local totalNum = CQIXIPVEWarData:Lua_GetQIXIPVESceneRankNum()

	if totalNum > 0 and rIndexBegin > totalNum then
		return 
	end

	g_CurPage = pageIndex

	local curIndex = rIndexBegin
	for i = 1, g_PageItemNum do
		local tableRankTeamInfo = CQIXIPVEWarData:Lua_GetQIXIPVESceneRankInfo(curIndex)
		if tableRankTeamInfo then
			g_UI_Items.pageItems[i].rIndex:SetText(tostring(curIndex))
			g_UI_Items.pageItems[i].leadName:SetText(tableRankTeamInfo.memName1)
			g_UI_Items.pageItems[i].serverName:SetText(tableRankTeamInfo.serverName)
			g_UI_Items.pageItems[i].mempai:SetText(GetMenpaiByID(tableRankTeamInfo.mempai))
			g_UI_Items.pageItems[i].level:SetText(tostring(tableRankTeamInfo.level))
			g_UI_Items.pageItems[i].point:SetText(tostring(tableRankTeamInfo.point))
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

		DaHua_List_DragTitle:SetText("#{DZSY_250611_53}")
	
end

function DaHua_List_SetMyTeamInfo()
	local tableRankTeamInfo = CQIXIPVEWarData:Lua_GetQIXIPVESceneMyRankInfo()
	if tableRankTeamInfo then
			g_UI_Items.MyRankInfo.rIndex:SetText(tostring(tableRankTeamInfo.rank))
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

function DaHua_List_Flip_Flip_UpPage_Clicked()
	DaHua_List_OpenPage(g_CurPage-1)
end

function DaHua_List_Flip_Flip_DownPage_Clicked()
	DaHua_List_OpenPage(g_CurPage+1)
end

-- function DaHua_List_Flip_LastPage_Clicked()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name( "AskOpenSceneRankList" )
-- 		Set_XSCRIPT_ScriptID(g_ExeScript)
-- 		Set_XSCRIPT_Parameter(0,1)
-- 		Set_XSCRIPT_ParamCount(1)
-- 	Send_XSCRIPT()
-- end


function DaHua_List_OnClose()
	this:Hide()
	-- Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name( "ShowMiniUI" )
	-- 	Set_XSCRIPT_ScriptID(g_ExeScript)
	-- 	Set_XSCRIPT_ParamCount(0)
	-- Send_XSCRIPT()
end