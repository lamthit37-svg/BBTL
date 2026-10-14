--查看已组建战队

local g_IndexCorpsID = {}
local g_StateName = 
{
[0] = "",
[1] = "#{WCBZ_180128_512}",
[2] = "#{WCBZ_180128_511}",
[3] = "#{WCBZ_180128_513}",
}
--npcid
local g_TargetId = -1

function NoDiffMatch_ShowStateOne_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CORPS_UPDATE_RANKLIST2_2018")
	this:RegisterEvent("CORPS_SHOW_RANKLIST2_2018")
end

function NoDiffMatch_ShowStateOne_OnLoad()
    NoDiffMatch_ShowStateOne_ResetControl()
end

function NoDiffMatch_ShowStateOne_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8927013 then
	        return
	    end

		local stage = Get_XParam_INT(1)
		if stage ~= 4 then
			return
		end
		
		NoDiffMatch_ShowStateOne_ResetControl()

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)
		this:Show()

	elseif event == "CORPS_UPDATE_RANKLIST2_2018" then
	    if not this:IsVisible() then
	        return
	    end
	    NoDiffMatch_ShowStateOne_Update()
		
	elseif event == "CORPS_SHOW_RANKLIST2_2018" then
		g_TargetId = tonumber(arg0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)
		NoDiffMatch_ShowStateOne_ResetControl()
		NoDiffMatch_ShowStateOne_Update()
		this:Show()
	end
end


function NoDiffMatch_ShowStateOne_Update()

    NoDiffMatch_ShowStateOne_ResetControl()
    
    g_IndexCorpsID = {}
	local count = CorpsUI_2018:GetRankNodeCount()

    local j = 0 
	for i = 0, count-1 do
	    local nCorpsID, nRank, szCorpsName, szLeaderName, advState,
			finalState, ResultPh0,ResultPh1,ResultPh2,ResultPh3,ResultPh4,ResultPh5 = CorpsUI_2018:GetRankNode2Info(i)
	    if nCorpsID and nCorpsID ~= -1 then
	        --战队Id 战队名字 战队队长 战队人数
			if nRank > 0 then
				NoDiffMatch_ShowStateOne_ListInfo:AddNewItem(tostring(nRank), 0, j)
			else
				NoDiffMatch_ShowStateOne_ListInfo:AddNewItem("", 0, j)
			end
    		NoDiffMatch_ShowStateOne_ListInfo:AddNewItem(szCorpsName, 1, j)
    		NoDiffMatch_ShowStateOne_ListInfo:AddNewItem(szLeaderName, 2, j)
    		NoDiffMatch_ShowStateOne_ListInfo:AddNewItem(g_StateName[advState], 3, j)
  
            g_IndexCorpsID[j] = nCorpsID
            j = j + 1
        end
	end

end


function NoDiffMatch_ShowStateOne_ResetControl()
	NoDiffMatch_ShowStateOne_ListInfo:RemoveAllItem()
    NoDiffMatch_ShowStateOne_TeamInfo:Disable()

	NoDiffMatch_ShowStateOne_YXSJJ :SetCheck(1)
	NoDiffMatch_ShowStateOne_YXSJS :SetCheck(0)
end

function NoDiffMatch_ShowStateOne_ListInfo_On_SelectionChanged()
    NoDiffMatch_ShowStateOne_TeamInfo:Enable()
end

function NoDiffMatch_ShowStateOne_TeamInfo_Clicked()
	local index = NoDiffMatch_ShowStateOne_ListInfo:GetSelectItem()
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

function NoDiffMatch_ShowStateOne_CloseClicked()
    this:Hide()
    g_TargetId = -1
end

function NoDiffMatch_ShowStateOne_YXSJJ_Clicked()
	
end

function NoDiffMatch_ShowStateOne_YXSJS_Clicked()
	PushEvent("CORPS_SHOW_RANKLIST3_2018", g_TargetId)
	NoDiffMatch_ShowStateOne_CloseClicked()
end

