local g_HuaShanCompetition_PersonalTopList_Frame_UnifiedPosition = nil 

local g_HuaShanCompetition_PersonalTopList_RankList = {}
function HuaShanCompetition_PersonalTopList_PreLoad()

	this:RegisterEvent("NEWHUASHAN_GEREN_RANK")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end 

-- HuaShanCompetition_PersonalTopList_Client => DefaultWindow
-- HuaShanCompetition_PersonalTopList_FrameBK => TLBB_StaticImageNULL
-- HuaShanCompetition_PersonalTopList_DragTitle => TLBB_DragTitle
-- HuaShanCompetition_PersonalTopList_Close => TLBB_ButtonNULL
-- HuaShanCompetition_PersonalTopList_Help => TLBB_ButtonNULL
function HuaShanCompetition_PersonalTopList_OnLoad()
	g_HuaShanCompetition_PersonalTopList_Frame_UnifiedPosition = HuaShanCompetition_PersonalTopList_Frame:GetProperty("UnifiedPosition");
end

function HuaShanCompetition_PersonalTopList_OnEvent(event)

	if event == "NEWHUASHAN_GEREN_RANK" then
		HuaShanCompetition_PersonalTopList_InitData()
		this:Show()
	end
	if(event == "ADJEST_UI_POS") then
		HuaShanCompetition_PersonalTopList_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanCompetition_PersonalTopList_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanCompetition_PersonalTopList_On_Hide()
	end
end


function HuaShanCompetition_PersonalTopList_GetRank(bar)
	return bar:GetSubItem("HuaShanCompetition_PersonalTopList_AItem_Rank")
end

function HuaShanCompetition_PersonalTopList_GetName(bar)
	return bar:GetSubItem("HuaShanCompetition_PersonalTopList_AItem_Name")
end

function HuaShanCompetition_PersonalTopList_GetLevel(bar)
	return bar:GetSubItem("HuaShanCompetition_PersonalTopList_AItem_Level")
end


function HuaShanCompetition_PersonalTopList_GetKillNum(bar)
	return bar:GetSubItem("HuaShanCompetition_PersonalTopList_AItem_KillNUM")
end


function HuaShanCompetition_PersonalTopList_GetKillScore(bar)
	return bar:GetSubItem("HuaShanCompetition_PersonalTopList_AItem_KillScore")	
end


function HuaShanCompetition_PersonalTopList_GetStandScore(bar)
	return bar:GetSubItem("HuaShanCompetition_PersonalTopList_AItem_OccupyScore")	
end

function HuaShanCompetition_PersonalTopList_GetAllScore(bar)
	return bar:GetSubItem("HuaShanCompetition_PersonalTopList_AItem_AllScore")	
end

function HuaShanCompetition_PersonalTopList_On_ResetPos()
	HuaShanCompetition_PersonalTopList_Frame:SetProperty("UnifiedPosition", g_HuaShanCompetition_PersonalTopList_Frame_UnifiedPosition)
end

function HuaShanCompetition_PersonalTopList_On_Hide()
	this:Hide()
end

function HuaShanCompetition_PersonalTopList_Close_Click()
end

function HuaShanCompetition_PersonalTopList_Help_Click()
end

function HuaShanCompetition_PersonalTopList_InitData()
	local list = HuaShanCompetition_PersonalTopList_ListFrame;
	list:Clear()



	local rankdata = DataPool:GetNewHuaShanGeRenRank()
	for i,v in ipairs(rankdata.m_player) do
		if string.len(v.m_szName) > 0 then
			local bar  = list:AddChild("HuaShanCompetition_PersonalTopList_AItem")

			g_HuaShanCompetition_PersonalTopList_RankList[i] = bar;
			HuaShanCompetition_PersonalTopList_GetRank(bar):SetText(i)
			HuaShanCompetition_PersonalTopList_GetName(bar):SetText(v.m_szName)
			HuaShanCompetition_PersonalTopList_GetLevel(bar):SetText(v.m_Level)
			HuaShanCompetition_PersonalTopList_GetKillNum(bar):SetText(v.m_killnum)
			HuaShanCompetition_PersonalTopList_GetKillScore(bar):SetText(v.m_killscore)
			HuaShanCompetition_PersonalTopList_GetStandScore(bar):SetText(v.m_standscore)
			HuaShanCompetition_PersonalTopList_GetAllScore(bar):SetText(v.m_standscore+v.m_killscore)

			if v.m_szName == Player:GetName() then
				HuaShanCompetition_PersonalTopList_My_Rank:SetText(i)
				HuaShanCompetition_PersonalTopList_My_Name:SetText(v.m_szName)
				HuaShanCompetition_PersonalTopList_My_Level:SetText(v.m_Level)
				HuaShanCompetition_PersonalTopList_My_KillNUM:SetText(v.m_killnum)
				HuaShanCompetition_PersonalTopList_My_KillScore:SetText(v.m_killscore)
				HuaShanCompetition_PersonalTopList_My_OccupyScore:SetText(v.m_standscore)
				HuaShanCompetition_PersonalTopList_My_AllScore:SetText(v.m_standscore+v.m_killscore)
			end
		end

	end

end

function HuaShanCompetition_PersonalTopList_Hide()

end

function HuaShanCompetition_PersonalTopList_Help_Clicked()
	PushEvent("CCSHOP_HELP",203)
end

function HuaShanCompetition_PersonalTopList_Close_Clicked()
	this:Hide()
end