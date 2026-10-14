--查看已组建战队

local g_IndexCorpsID1 = {}
local g_IndexCorpsID2 = {}
local g_IndexCorpsID3 = {}

local g_StateName = 
{
[0] = "--",
[1] = "#{WCBZ_180128_520}",
[2] = "#{WCBZ_180128_521}",
}

local g_Round1Name = {}
local g_Round1Text = {}

local g_Round2Name = {}
local g_Round2Text = {}

local g_Round3Name = {}

--npcid
local g_TargetId = -1

function NoDiffMatch_ShowStateTwo_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CORPS_UPDATE_RANKLIST3_2018")
	this:RegisterEvent("CORPS_SHOW_RANKLIST3_2018")
end

function NoDiffMatch_ShowStateTwo_OnLoad()
    g_Round1Name[1] = NoDiffMatch_ShowStateTwo_TeamR1_A --1
	g_Round1Name[2] = NoDiffMatch_ShowStateTwo_TeamR1_E --2
	g_Round1Name[3] = NoDiffMatch_ShowStateTwo_TeamR1_G --3
	g_Round1Name[4] = NoDiffMatch_ShowStateTwo_TeamR1_C --4
	g_Round1Name[5] = NoDiffMatch_ShowStateTwo_TeamR1_D --5
	g_Round1Name[6] = NoDiffMatch_ShowStateTwo_TeamR1_H --6
	g_Round1Name[7] = NoDiffMatch_ShowStateTwo_TeamR1_F --7
	g_Round1Name[8] = NoDiffMatch_ShowStateTwo_TeamR1_B --8
	
    g_Round1Text[1] = NoDiffMatch_ShowStateTwo_TeamR1_AText
	g_Round1Text[2] = NoDiffMatch_ShowStateTwo_TeamR1_EText
	g_Round1Text[3] = NoDiffMatch_ShowStateTwo_TeamR1_GText
	g_Round1Text[4] = NoDiffMatch_ShowStateTwo_TeamR1_CText
	g_Round1Text[5] = NoDiffMatch_ShowStateTwo_TeamR1_DText
	g_Round1Text[6] = NoDiffMatch_ShowStateTwo_TeamR1_HText
	g_Round1Text[7] = NoDiffMatch_ShowStateTwo_TeamR1_FText
	g_Round1Text[8] = NoDiffMatch_ShowStateTwo_TeamR1_BText
	
	g_Round2Name[1] = NoDiffMatch_ShowStateTwo_TeamR2_A
	g_Round2Name[2] = NoDiffMatch_ShowStateTwo_TeamR2_C
	g_Round2Name[3] = NoDiffMatch_ShowStateTwo_TeamR2_D
	g_Round2Name[4] = NoDiffMatch_ShowStateTwo_TeamR2_B
	
	g_Round2Text[1] = NoDiffMatch_ShowStateTwo_TeamR2_AText
	g_Round2Text[2] = NoDiffMatch_ShowStateTwo_TeamR2_CText
	g_Round2Text[3] = NoDiffMatch_ShowStateTwo_TeamR2_DText
	g_Round2Text[4] = NoDiffMatch_ShowStateTwo_TeamR2_BText
	
	g_Round3Name[1] = NoDiffMatch_ShowStateTwo_TeamR3_A
	g_Round3Name[2] = NoDiffMatch_ShowStateTwo_TeamR3_B
end

function NoDiffMatch_ShowStateTwo_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8927013 then
	        return
	    end

		local stage = Get_XParam_INT(1)
		if stage ~= 5 then
			return
		end
		
		NoDiffMatch_ShowStateTwo_ResetControl()

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)
		this:Show()

	elseif event == "CORPS_UPDATE_RANKLIST3_2018" then
	    if not this:IsVisible() then
	        return
	    end
	    NoDiffMatch_ShowStateTwo_Update()
	elseif event == "CORPS_SHOW_RANKLIST3_2018" then
		g_TargetId = tonumber(arg0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)
		NoDiffMatch_ShowStateTwo_ResetControl()
		NoDiffMatch_ShowStateTwo_Update()
		this:Show()
	end
end


function NoDiffMatch_ShowStateTwo_Update()

    NoDiffMatch_ShowStateTwo_ResetControl()
    
    g_IndexCorpsID1 = {}
	g_IndexCorpsID2 = {}
	g_IndexCorpsID3 = {}
	local count = CorpsUI_2018:GetRankNodeCount()
	
	for i = 0, count-1 do
	    local nCorpsID, nRank, szCorpsName, szLeaderName, advState,
			finalState, ResultPh0,ResultPh1,ResultPh2,ResultPh3,ResultPh4,ResultPh5 = CorpsUI_2018:GetRankNode2Info(i)
	    if nCorpsID and nCorpsID ~= -1 and nRank > 0 then
	        --战队Id 战队名字 战队队长 战队人数
			g_Round1Name[nRank]:SetText("#G"..szCorpsName)
			local result = ScriptGlobal_Format("#{WCBZ_180128_518}",g_StateName[ResultPh0], g_StateName[ResultPh1], g_StateName[ResultPh2])
			g_Round1Text[nRank]:SetText(result)
			g_IndexCorpsID1[nRank] = nCorpsID
			
			local temprank = nRank
			if finalState >= 1 then
				if temprank > 4 then
					temprank = 9 - temprank
				end	
				g_Round2Name[temprank]:SetText("#G"..szCorpsName)
				local result2 = ScriptGlobal_Format("#{WCBZ_180128_518}",g_StateName[ResultPh3], g_StateName[ResultPh4], g_StateName[ResultPh5])
				g_Round2Text[temprank]:SetText(result2)
				g_IndexCorpsID2[temprank] = nCorpsID
			end
			
			if finalState >= 2 then
				if temprank == 1 or temprank == 4 or temprank == 5 or temprank == 8 then
					if g_IndexCorpsID3[1] == nil then
						g_Round3Name[1]:SetText("#G"..szCorpsName)
						g_IndexCorpsID3[1] = nCorpsID
					else
						g_Round3Name[2]:SetText("#G"..szCorpsName)
						g_IndexCorpsID3[2] = nCorpsID
					end
				else
					if g_IndexCorpsID3[2] == nil then
						g_Round3Name[2]:SetText("#G"..szCorpsName)
						g_IndexCorpsID3[2] = nCorpsID
					else
						g_Round3Name[1]:SetText("#G"..szCorpsName)
						g_IndexCorpsID3[1] = nCorpsID
					end
				end
			end
			
        end
	end

end


function NoDiffMatch_ShowStateTwo_ResetControl()
	for i=1,8 do
		g_Round1Name[i]:SetText("#{WCBZ_180128_517}")
		g_Round1Text[i]:SetText("#{WCBZ_180128_519}")
	end
	
	for i=1,4 do
		g_Round2Name[i]:SetText("#{WCBZ_180128_517}")
		g_Round2Text[i]:SetText("#{WCBZ_180128_519}")
	end
	
	for i=1,2 do
		g_Round3Name[i]:SetText("#{WCBZ_180128_517}")
	end
	
	NoDiffMatch_ShowStateTwo_YXSJJ :SetCheck(0)
	NoDiffMatch_ShowStateTwo_YXSJS :SetCheck(1)
end

function NoDiffMatch_ShowStateTwo_TeamInfo_Clicked1(index)
	if index < 1 or index > 8 then
		PushDebugMessage("#{ZBS_BC_120507_16}")
		return
	end
	
	if CorpsUI_2018:CanQueryRankingAgain() ~= 1 then
	    PushDebugMessage("#{ZBS_YXS_120301_86}")
	    return
	end
	
    local CorpsID = g_IndexCorpsID1[index]
	if CorpsID and tonumber(CorpsID) > 0 then
		PushEvent("UI_COMMAND", 8927012, g_TargetId)
		CorpsUI_2018:RequsetCorpsInfo(tonumber(CorpsID))
	end
end

function NoDiffMatch_ShowStateTwo_TeamInfo_Clicked2(index)
	if index < 1 or index > 4 then
		PushDebugMessage("#{ZBS_BC_120507_16}")
		return
	end

	if CorpsUI_2018:CanQueryRankingAgain() ~= 1 then
	    PushDebugMessage("#{ZBS_YXS_120301_86}")
	    return
	end
	
    local CorpsID = g_IndexCorpsID2[index]
	if CorpsID and tonumber(CorpsID) > 0 then
		PushEvent("UI_COMMAND", 8927012, g_TargetId)
		CorpsUI_2018:RequsetCorpsInfo(tonumber(CorpsID))
	end
end

function NoDiffMatch_ShowStateTwo_TeamInfo_Clicked3(index)
	if index < 1 or index > 2 then
		PushDebugMessage("#{ZBS_BC_120507_16}")
		return
	end

	if CorpsUI_2018:CanQueryRankingAgain() ~= 1 then
	    PushDebugMessage("#{ZBS_YXS_120301_86}")
	    return
	end
	
    local CorpsID = g_IndexCorpsID3[index]
	if CorpsID and tonumber(CorpsID) > 0 then
		PushEvent("UI_COMMAND", 8927012, g_TargetId)
		CorpsUI_2018:RequsetCorpsInfo(tonumber(CorpsID))
	end
end

function NoDiffMatch_ShowStateTwo_CloseClicked()
    this:Hide()
    g_TargetId = -1
end

function NoDiffMatch_ShowStateTwo_YXSJJ_Clicked()
	PushEvent("CORPS_SHOW_RANKLIST2_2018", g_TargetId)
	NoDiffMatch_ShowStateTwo_CloseClicked()
end

function NoDiffMatch_ShowStateTwo_YXSJS_Clicked()
	
end
