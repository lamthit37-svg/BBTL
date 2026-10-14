--查看已组建战队

local g_IndexCorpsID = {}

--npcid
local g_TargetId = -1

function NoDiffMatch_CreatTeamList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CORPS_UPDATE_RANKLIST1_2018")
end

function NoDiffMatch_CreatTeamList_OnLoad()
    NoDiffMatch_CreatTeamList_ResetControl()
end

function NoDiffMatch_CreatTeamList_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8927013 then
	        return
	    end

		local stage = Get_XParam_INT(1)
		if stage ~= 1 then
			return
		end
		
		NoDiffMatch_CreatTeamList_ResetControl()

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)
		this:Show()

	elseif event == "CORPS_UPDATE_RANKLIST1_2018" then
	    if not this:IsVisible() then
	        return
	    end
	    NoDiffMatch_CreatTeamList_Update()
	end
end


function NoDiffMatch_CreatTeamList_Update()

    NoDiffMatch_CreatTeamList_ResetControl()
    
    g_IndexCorpsID = {}
	local count = CorpsUI_2018:GetRankNodeCount()
	local toptext = ScriptGlobal_Format("#{WCBZ_180128_550}", tostring(count) );
	NoDiffMatch_CreatTeamList_ExplainText:SetText(toptext)

    local j = 0 
	for i = 0, count-1 do
	    local nCorpsID, szCorpsName, szLeaderName, nHumCount = CorpsUI_2018:GetRankNode1Info(i)
	    if nCorpsID and nCorpsID ~= -1 then
	        --战队Id 战队名字 战队队长 战队人数
			local corpsIdText = string.format("%03d", nCorpsID)
			NoDiffMatch_CreatTeamList_ListInfo:AddNewItem(corpsIdText, 0, j)
    		NoDiffMatch_CreatTeamList_ListInfo:AddNewItem(szCorpsName, 1, j)
    		NoDiffMatch_CreatTeamList_ListInfo:AddNewItem(szLeaderName, 2, j)
    		NoDiffMatch_CreatTeamList_ListInfo:AddNewItem(nHumCount, 3, j)
  
            g_IndexCorpsID[j] = nCorpsID
            j = j + 1
        end
	end

end


function NoDiffMatch_CreatTeamList_ResetControl()
	NoDiffMatch_CreatTeamList_ListInfo:RemoveAllItem()
    NoDiffMatch_CreatTeamList_TeamInfo:Disable()
	local toptext = ScriptGlobal_Format("#{WCBZ_180128_550}" , "0" );
	NoDiffMatch_CreatTeamList_ExplainText:SetText(toptext)
end

function NoDiffMatch_CreatTeamList_ListInfo_On_SelectionChanged()
    NoDiffMatch_CreatTeamList_TeamInfo:Enable()
end

function NoDiffMatch_CreatTeamList_TeamInfo_Clicked()
	local index = NoDiffMatch_CreatTeamList_ListInfo:GetSelectItem()
	if index < 0 then
		PushDebugMessage("#{ZBS_BC_120507_16}")
		return
	end

	if CorpsUI_2018:CanQueryRankingAgain() ~= 1 then
	    PushDebugMessage("#{ZBS_YXS_120301_86}")
	    return
	end
	
    local CorpsID = g_IndexCorpsID[index]
	if CorpsID and tonumber(CorpsID) > 0 then
		PushEvent("UI_COMMAND", 8927012, g_TargetId)
		CorpsUI_2018:RequsetCorpsInfo(tonumber(CorpsID))
	end
end

function NoDiffMatch_CreatTeamList_CloseClicked()
    this:Hide()
    g_TargetId = -1
end

function NoDiffMatch_CreatTeamList_ExplainText_Help_Clicked()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientAskNpcTalk")
		Set_XSCRIPT_ScriptID(892694)
		Set_XSCRIPT_Parameter(0,tonumber(g_TargetId));
		Set_XSCRIPT_Parameter(1,tonumber(5));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT()
end

