--查看已组建战队

local g_IndexWTeamID = {}

--npcid
local g_TargetId = -1

function BS_CheckPromotedShow_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("TXBW_UPDATE_RANKLIST_PROMOTION")
end

function BS_CheckPromotedShow_OnLoad()
    
end

function BS_CheckPromotedShow_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8928453 then
	        return
	    end

		local stage = Get_XParam_INT(1)
		if stage ~= 2 then
			return
		end
		
		if (IsInTServer()  == 0) then
			return
		end
		
		BS_CheckPromotedShow_ResetControl()

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)

	elseif event == "TXBW_UPDATE_RANKLIST_PROMOTION" then
		if (IsInTServer()  == 0) then
			return
		end
		
	    BS_CheckPromotedShow_Update()
		this:Show()
	end
end


function BS_CheckPromotedShow_Update()

    BS_CheckPromotedShow_ResetControl()
    
    g_IndexWTeamID = {}
	local count = BWDH2018:GetRankNodeCount()

    local j = 0 
	for i = 0, count-1 do
	    local nWTeamID, szWTeamName, nZoneWorldId, szLeaderName, nProRank, nRoundResult, nCount, nSumDw3 = BWDH2018:GetRankNodeProInfo(i)
	    if nWTeamID and nWTeamID ~= -1 then
	        --战队Id 战队名字 战队队长 战队人数
			local rankdText = ""
			if nProRank >= 1 then
				rankdText = tostring(nProRank)
			end
			
			local nServerName = DataPool:GetServerName(nZoneWorldId)
			if nServerName == nil then
				nServerName = ""
			end
			
			local stateText = ""
			if nProRank >= 1 then
				stateText = "#{BWJH_181102_390}"
			elseif nRoundResult == 1 then
				stateText = "#{BWJH_181102_356}"
			elseif nRoundResult == 0 then
				stateText = "#{BWJH_181102_357}"
			else
				stateText = ""
			end
		
			local cntText = ScriptGlobal_Format("#{BWJH_181102_154}", tostring(nCount) );
			BS_CheckPromotedShow_ListInfo:AddNewItem(rankdText, 0, j)
    		BS_CheckPromotedShow_ListInfo:AddNewItem(szWTeamName, 1, j)
			BS_CheckPromotedShow_ListInfo:AddNewItem(szLeaderName, 2, j)
			BS_CheckPromotedShow_ListInfo:AddNewItem(stateText, 3, j)
			
            g_IndexWTeamID[j] = nWTeamID
            j = j + 1
        end
	end

end


function BS_CheckPromotedShow_ResetControl()
	BS_CheckPromotedShow_ListInfo:RemoveAllItem()
    BS_CheckPromotedShow_TeamInfo:Disable()
	
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nPromotionDate0 = BWDH2018:GetTXbwPromotionDate(curDay, 0)
	local nPromotionDate7 = BWDH2018:GetTXbwPromotionDate(curDay, 7)
	local nFinalDate0 = BWDH2018:GetTXbwFinalDate(curDay, 0)
	if nPromotionDate0 == nil or nPromotionDate7 == nil or nFinalDate0 == nil then
		return
	end
			
	local strPromotionDate0  = BWDH2018:Format_YMD2Str( nPromotionDate0 )	
	local strPromotionDate7  = BWDH2018:Format_YMD2Str( nPromotionDate7 )	
	local strFinalDate0  = BWDH2018:Format_YMD2Str( nFinalDate0 )	
	
	local toptext = ScriptGlobal_Format("#{BWJH_181102_351}", strPromotionDate0, strPromotionDate7, strFinalDate0 );
	BS_CheckPromotedShow_ExplainText:SetText(toptext)
end

function BS_CheckPromotedShow_ListInfo_On_SelectionChanged()
    BS_CheckPromotedShow_TeamInfo:Enable()
end

function BS_CheckPromotedShow_TeamInfo_Clicked()
	local index = BS_CheckPromotedShow_ListInfo:GetSelectItem()
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

function BS_CheckPromotedShow_CloseClicked()
    this:Hide()
    g_TargetId = -1
end

