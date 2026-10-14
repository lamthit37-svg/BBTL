-- WorldBoss_List

local g_WorldBoss_List_Frame_UnifiedPosition = nil 
local g_WorldBoss_List_Player_Rank = {}
local g_WorldBoss_List_Player_Name = {}
local g_WorldBoss_List_Player_Server = {}
local g_WorldBoss_List_Player_Level = {}
local g_WorldBoss_List_Player_Menpai = {}
local g_WorldBoss_List_Player_Value = {}
local g_WorldBoss_List_Player = {}

local g_PerPageCount = 10
local g_CurPage = 0

local g_NpcId =-1;
local objCared = -1
local g_RankingList_Type = 19
local g_nType = 0;
local g_State = 0;
local g_ButtonLastTime =0
local g_ButtonCDTime = 2

function WorldBoss_List_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OPEN_WORLDBOSS_RANKINGLIST",true)
	this:RegisterEvent("UPDATE_WORLDBOSS_RANKINGLIST",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)

end

function WorldBoss_List_OnLoad()
	for i = 1, 10 do
		g_WorldBoss_List_Player_Rank[i] = "WorldBoss_List_Player"..i.."Rank"
		g_WorldBoss_List_Player_Name[i] = "WorldBoss_List_Player"..i.."Name"
		g_WorldBoss_List_Player_Server[i] = "WorldBoss_List_Player"..i.."Server"
		g_WorldBoss_List_Player_Level[i] = "WorldBoss_List_Player"..i.."Level"
		g_WorldBoss_List_Player_Menpai[i] = "WorldBoss_List_Player"..i.."Career"
		g_WorldBoss_List_Player_Value[i] = "WorldBoss_List_Player"..i.."Point"
	end
	
	for i = 1, 10 do
		g_WorldBoss_List_Player[i] = {
			rank = _G[g_WorldBoss_List_Player_Rank[i]],
			name = _G[g_WorldBoss_List_Player_Name[i]],
			server = _G[g_WorldBoss_List_Player_Server[i]],
			level = _G[g_WorldBoss_List_Player_Level[i]],
			menpai = _G[g_WorldBoss_List_Player_Menpai[i]],
			value = _G[g_WorldBoss_List_Player_Value[i]],
		}
	end
	g_WorldBoss_List_Frame_UnifiedPosition = WorldBoss_List_Frame:GetProperty("UnifiedPosition")
end

function WorldBoss_List_OnEvent(event)

	if event == "OPEN_WORLDBOSS_RANKINGLIST" then
		--if this:IsVisible() then
		--	return
		--end
		--PushDebugMessage("open")
		g_nType = tonumber(arg0);
		g_NpcId = tonumber(arg1);
		
		objCared = DataPool:GetNPCIDByServerID(g_NpcId);

		if objCared == -1 then
		--	return
		end
		WorldBoss_List_BeginCareObject(objCared)
		g_CurPage = 0
		WorldBoss_List_OnShow()
		WorldBoss_List_MyInfo()
	elseif event == "UPDATE_WORLDBOSS_RANKINGLIST" and this:IsVisible() then
		g_nType = tonumber(arg0);

		WorldBoss_List_OnShow()
	elseif(event == "ADJEST_UI_POS") then
		WorldBoss_List_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		WorldBoss_List_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		WorldBoss_List_OnClose()	
	end

end

function WorldBoss_List_On_ResetPos()
	WorldBoss_List_Frame:SetProperty("UnifiedPosition", g_WorldBoss_List_Frame_UnifiedPosition)
end

function WorldBoss_List_Clear()
	for i = 1, 10 do
		g_WorldBoss_List_Player[i].rank:SetText("")
		g_WorldBoss_List_Player[i].name:SetText("")
		g_WorldBoss_List_Player[i].server:SetText("")
		g_WorldBoss_List_Player[i].level:SetText("")
		g_WorldBoss_List_Player[i].menpai:SetText("")
		g_WorldBoss_List_Player[i].value:SetText("")
	end
	WorldBoss_List_Flip_Flip_UpPage:Disable()
	WorldBoss_List_Flip_Flip_DownPage:Disable()
	WorldBoss_List_Flip_Flip_CurrentlyPage:SetText(ScriptGlobal_Format("#{SJBS_240124_81}", 0, 0))
end

function WorldBoss_List_OnShow()
	WorldBoss_List_Clear()

	local startpos = g_CurPage*g_PerPageCount
	local endpos = startpos + g_PerPageCount
	local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_RankingList_Type)
	if startpos > nDataCount then
		return
	end		

	if startpos > 0 then
		WorldBoss_List_Flip_Flip_UpPage:Enable()
	else
		WorldBoss_List_Flip_Flip_UpPage:Disable()
	end
	
	if endpos < nDataCount then
		WorldBoss_List_Flip_Flip_DownPage:Enable()
	else
		WorldBoss_List_Flip_Flip_DownPage:Disable()
	end
	
	if nDataCount > 0 then
		local maxpages = math.ceil( tonumber(nDataCount/g_PerPageCount) )
		WorldBoss_List_Flip_Flip_CurrentlyPage:SetText(tostring(g_CurPage+1).."/"..tostring(maxpages))
	end
	
	local WorldBoss_List_Index = 1

	for i = startpos, endpos-1 do
		local nRank,name,value,state = DataPool:lua_GetJSRankingListInfo(g_RankingList_Type,i);
		local bValid,memguid,membname,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_Type,i,0);

		if nRank >= 0 and bValid == 1 then
			if WorldBoss_List_Index > 0 and WorldBoss_List_Index <= g_PerPageCount then
				g_WorldBoss_List_Player[WorldBoss_List_Index].rank:SetText(tostring(nRank+1))
				g_WorldBoss_List_Player[WorldBoss_List_Index].name:SetText(tostring(name))
				g_WorldBoss_List_Player[WorldBoss_List_Index].level:SetText(tostring(level))
				g_WorldBoss_List_Player[WorldBoss_List_Index].menpai:SetText(GetMenpaiByID(menpai))
				g_WorldBoss_List_Player[WorldBoss_List_Index].value:SetText(tostring(value))
				
				local nZoneWorldId = DataPool:lua_GetJSRankingListParam(g_RankingList_Type, i, 2)
				local world_name = DataPool:GetServerName(tonumber(nZoneWorldId))
				g_WorldBoss_List_Player[WorldBoss_List_Index].server:SetText(world_name)
				WorldBoss_List_Index = WorldBoss_List_Index + 1
			end
		end
		
	end		
		
	this:Show()
end

function WorldBoss_List_MyInfo()
	local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_RankingList_Type)
	if nDataCount <= 0 then
		WorldBoss_List_FillMyInfoNone()
		return
	end

	local myRank = -1
	local myRankValue = 0
	for i = 0, nDataCount-1 do	
		local nRank,name,value,state = DataPool:lua_GetJSRankingListInfo(g_RankingList_Type,i);
		local bValid,memguid,membname,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_Type,i,0);
		if nRank >= 0 and bValid == 1 then
			if memguid == Player:GetGUID() then
				myRank = nRank
				myRankValue = value
			end			
		end
	end
	if myRank >= 0 then --上榜
		WorldBoss_List_FillMyInfo(myRank,myRankValue)
	else --未上榜
		WorldBoss_List_FillMyInfoNone()
	end
end

function WorldBoss_List_FillMyInfoNone()
	WorldBoss_List_MyselfRank:SetText("#{PTFB_191228_166}")
	WorldBoss_List_MyselfName:SetText(Player:GetName())
	
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	if selfZoneWorldID ~= -1 then
		local serverName = DataPool:GetServerName( selfZoneWorldID )
		WorldBoss_List_MyselfServer:SetText(serverName)
	end
	local menpai = Player:GetData("MEMPAI")
	WorldBoss_List_MyselfCareer:SetText(GetMenpaiByID(menpai))
	local level = Player:GetData("LEVEL")	
	WorldBoss_List_MyselfLevel:SetText(tostring(level))
	local myvalue = DataPool:lua_GetWorldBossRankingListMyvalue()
	WorldBoss_List_MyselfPoint:SetText(myvalue)

end

function WorldBoss_List_FillMyInfo(myRank,myRankValue)
	WorldBoss_List_MyselfRank:SetText(myRank+1)
	WorldBoss_List_MyselfName:SetText(Player:GetName())
	WorldBoss_List_MyselfPoint:SetText(tostring(myRankValue))
	
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	if selfZoneWorldID ~= -1 then
		local serverName = DataPool:GetServerName( selfZoneWorldID )
		WorldBoss_List_MyselfServer:SetText(serverName)
	end
	local menpai = Player:GetData("MEMPAI")
	WorldBoss_List_MyselfCareer:SetText(GetMenpaiByID(menpai))
	local level = Player:GetData("LEVEL")	
	WorldBoss_List_MyselfLevel:SetText(tostring(level))
	local myvalue = DataPool:lua_GetWorldBossRankingListMyvalue()
end

function WorldBoss_List_Flip_Flip_DownPage_Clicked()
	local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_RankingList_Type)
	if g_CurPage * g_PerPageCount + g_PerPageCount >= nDataCount then
		return
	end
	g_CurPage = g_CurPage + 1
	WorldBoss_List_OnShow()
end

function WorldBoss_List_Flip_Flip_UpPage_Clicked()
	if g_CurPage <= 0 then
		return
	end
	g_CurPage = g_CurPage - 1
	WorldBoss_List_OnShow()
end

function WorldBoss_List_OnClose()
	WorldBoss_List_StopCareObject()
	this:Hide()
end

function WorldBoss_List_Refresh_Clicked()
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
 	 	PushDebugMessage("#{SJBS_240124_71}"); --不可连续点击，请稍等片刻后再点击
   		return;
   	end
   	g_ButtonLastTime = curTime;
	   
	DataPool:lua_GetJSRankingList(g_RankingList_Type, g_NpcId)
end
--=========================================================
--开始关心NPC
--=========================================================
function WorldBoss_List_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "WorldBoss_List");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "WorldBoss_List")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function WorldBoss_List_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "WorldBoss_List");
		objCared = -1;
	end
end