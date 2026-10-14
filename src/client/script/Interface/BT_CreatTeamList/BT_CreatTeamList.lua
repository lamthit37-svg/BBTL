--巅峰赛 查看战队

local g_IndexWTeamID = {}
local g_TimersQuery = 0;

--npcid
local g_TargetId = -1

function BT_CreatTeamList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("DFS_UPDATE_RANKLIST")
end

function BT_CreatTeamList_OnLoad()
    
end

function BT_CreatTeamList_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 2915101 then
	        return
	    end

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)

	elseif event == "DFS_UPDATE_RANKLIST" then
	    BT_CreatTeamList_Update()
		this:Show()
	end
end


function BT_CreatTeamList_Update()

    BT_CreatTeamList_Init()
    
    g_IndexWTeamID = {}
	local count = DFS:GetRankNodeCount()

    local j = 0 
	for i = 0, count-1 do
	    local nWTeamID, szWTeamName, nZoneWorldId, szLeaderName, nHumCount, nSumEqhh = DFS:GetRankNodeInfo(i)
	    if nWTeamID and nWTeamID ~= -1 then
	        --战队Id 战队名字 战队队长 战队人数
			local WTeamIdText = string.format("%03d", nWTeamID)
			local nServerName = DataPool:GetServerName(nZoneWorldId)
			if nServerName == nil then
				nServerName = ""
			end
		
			BT_CreatTeamList_ListInfo:AddNewItem(WTeamIdText, 0, j)
    		BT_CreatTeamList_ListInfo:AddNewItem(szWTeamName, 1, j)
			BT_CreatTeamList_ListInfo:AddNewItem(nServerName, 2, j)
    		BT_CreatTeamList_ListInfo:AddNewItem(szLeaderName, 3, j)
    		BT_CreatTeamList_ListInfo:AddNewItem(nHumCount, 4, j)
			BT_CreatTeamList_ListInfo:AddNewItem(nSumEqhh, 5, j)
  
            g_IndexWTeamID[j] = nWTeamID
            j = j + 1
        end
	end

end


function BT_CreatTeamList_Init()
	BT_CreatTeamList_ListInfo:RemoveAllItem()
    BT_CreatTeamList_TeamInfo:Disable()
end

function BT_CreatTeamList_ListInfo_On_SelectionChanged()
    BT_CreatTeamList_TeamInfo:Enable()
end

function BT_CreatTeamList_TeamInfo_Clicked()
	local index = BT_CreatTeamList_ListInfo:GetSelectItem()
	if index < 0 then
		PushDebugMessage("#{ZBS_BC_120507_16}")
		return
	end

	local iCur = FindFriendDataPool:GetTickCount(  )
	local pass = iCur - g_TimersQuery
	if pass <= 1*1000 then
		PushDebugMessage("#{ZBS_YXS_120301_86}");
		return
	end

	g_TimersQuery = iCur
	
    local WTeamID = g_IndexWTeamID[index]
	if WTeamID and tonumber(WTeamID) > 0 then
		PushEvent("UI_COMMAND", 2915232, g_TargetId)
		DFS:RequsetWTeamInfo(tonumber(WTeamID))
	end
end

function BT_CreatTeamList_CloseClicked()
    this:Hide()
    g_TargetId = -1
end

