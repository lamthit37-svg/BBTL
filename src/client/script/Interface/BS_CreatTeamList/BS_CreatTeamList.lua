--查看已组建战队

local g_IndexWTeamID = {}

--npcid
local g_TargetId = -1

function BS_CreatTeamList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("TXBW_UPDATE_RANKLIST_BUILD")
end

function BS_CreatTeamList_OnLoad()
    
end

function BS_CreatTeamList_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8928453 then
	        return
	    end

		local stage = Get_XParam_INT(1)
		if stage ~= 1 then
			return
		end
		
		BS_CreatTeamList_ResetControl()

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)

	elseif event == "TXBW_UPDATE_RANKLIST_BUILD" then
	    BS_CreatTeamList_Update()
		this:Show()
	end
end


function BS_CreatTeamList_Update()

    BS_CreatTeamList_ResetControl()
    
    g_IndexWTeamID = {}
	
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nCreateWTeamBegin, nCreateWTeamEnd = BWDH2018:GetTXbwCreateWTeamDate(curDay)
	if nCreateWTeamBegin == nil or nCreateWTeamEnd == nil then
		return
	end
			
	local strCreateWTeamEnd  = BWDH2018:Format_YMD2Str( nCreateWTeamEnd )			
	local count = BWDH2018:GetRankNodeCount()
	local toptext = ScriptGlobal_Format("#{BWJH_181102_146}", strCreateWTeamEnd, tostring(count) );
	BS_CreatTeamList_ExplainText:SetText(toptext)

    local j = 0 
	for i = 0, count-1 do
	    local nWTeamID, szWTeamName, nZoneWorldId, szLeaderName, nHumCount, nSumDw3 = BWDH2018:GetRankNodeBuildInfo(i)
	    if nWTeamID and nWTeamID ~= -1 then
	        --战队Id 战队名字 战队队长 战队人数
			local WTeamIdText = string.format("%03d", nWTeamID)
			local nServerName = DataPool:GetServerName(nZoneWorldId)
			if nServerName == nil then
				nServerName = ""
			end
		
			BS_CreatTeamList_ListInfo:AddNewItem(WTeamIdText, 0, j)
    		BS_CreatTeamList_ListInfo:AddNewItem(szWTeamName, 1, j)
			BS_CreatTeamList_ListInfo:AddNewItem(nServerName, 2, j)
    		BS_CreatTeamList_ListInfo:AddNewItem(szLeaderName, 3, j)
    		BS_CreatTeamList_ListInfo:AddNewItem(nHumCount, 4, j)
			BS_CreatTeamList_ListInfo:AddNewItem(nSumDw3, 5, j)
  
            g_IndexWTeamID[j] = nWTeamID
            j = j + 1
        end
	end

end


function BS_CreatTeamList_ResetControl()
	BS_CreatTeamList_ListInfo:RemoveAllItem()
    BS_CreatTeamList_TeamInfo:Disable()
end

function BS_CreatTeamList_ListInfo_On_SelectionChanged()
    BS_CreatTeamList_TeamInfo:Enable()
end

function BS_CreatTeamList_TeamInfo_Clicked()
	local index = BS_CreatTeamList_ListInfo:GetSelectItem()
	if index < 0 then
		PushDebugMessage("#{ZBS_BC_120507_16}")
		return
	end

	if BWDH2018:CanQueryRankingAgain() ~= 1 then
	    PushDebugMessage("#{ZBS_YXS_120301_86}")
	    return
	end
	
    local WTeamID = g_IndexWTeamID[index]
	if WTeamID and tonumber(WTeamID) > 0 then
		PushEvent("UI_COMMAND", 8928452, g_TargetId)
		BWDH2018:RequsetWTeamInfo(tonumber(WTeamID))
	end
end

function BS_CreatTeamList_CloseClicked()
    this:Hide()
    g_TargetId = -1
end

function BS_CreatTeamList_ExplainText_Help_Clicked()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientAskNpcTalk")
		Set_XSCRIPT_ScriptID(892694)
		Set_XSCRIPT_Parameter(0,tonumber(g_TargetId));
		Set_XSCRIPT_Parameter(1,tonumber(6));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT()
end

