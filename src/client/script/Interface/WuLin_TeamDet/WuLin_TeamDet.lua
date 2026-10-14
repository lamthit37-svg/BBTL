-- 武林之巅
local g_WuLin_TeamDet_Member = {}
local g_WuLin_TeamDet_Frame_UnifiedPosition = nil 
function WuLin_TeamDet_PreLoad()
	this:RegisterEvent("JZWLZD_OPEN_TEAMDETAIL",true)
	this:RegisterEvent("OPEN_WLZDRANKLIST_TEAM",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("CLOSE_WULIN_TEAMDET",false)
end

function WuLin_TeamDet_OnLoad()

	g_WuLin_TeamDet_Member[1] = {
		name = WuLin_TeamDet_BK1Name,
		menpai = WuLin_TeamDet_BK1MenPai,
		level = WuLin_TeamDet_BK1Level,
		score = WuLin_TeamDet_BK1Num,
	}
	g_WuLin_TeamDet_Member[2] = {
		name = WuLin_TeamDet_BK2Name,
		menpai = WuLin_TeamDet_BK2MenPai,
		level = WuLin_TeamDet_BK2Level,
		score = WuLin_TeamDet_BK2Num,
	}
	g_WuLin_TeamDet_Member[3] = {
		name = WuLin_TeamDet_BK3Name,
		menpai = WuLin_TeamDet_BK3MenPai,
		level = WuLin_TeamDet_BK3Level,
		score = WuLin_TeamDet_BK3Num,
	}
	g_WuLin_TeamDet_Member[4] = {
		name = WuLin_TeamDet_BK4Name,
		menpai = WuLin_TeamDet_BK4MenPai,
		level = WuLin_TeamDet_BK4Level,
		score = WuLin_TeamDet_BK4Num,
	}
	g_WuLin_TeamDet_Member[5] = {
		name = WuLin_TeamDet_BK5Name,
		menpai = WuLin_TeamDet_BK5MenPai,
		level = WuLin_TeamDet_BK5Level,
		score = WuLin_TeamDet_BK5Num,
	}
	g_WuLin_TeamDet_Member[6] = {
		name = WuLin_TeamDet_BK6Name,
		menpai = WuLin_TeamDet_BK6MenPai,
		level = WuLin_TeamDet_BK6Level,
		score = WuLin_TeamDet_BK6Num,
	}


	g_WuLin_TeamDet_Frame_UnifiedPosition = WuLin_TeamDet_Frame:GetProperty("UnifiedPosition")
end

function WuLin_TeamDet_OnEvent(event)
	if( event == "OPEN_WLZDRANKLIST_TEAM") then
		local nIndex = tonumber(arg0)
		WuLin_TeamDet_Init()
		WuLin_TeamDet_FillInfo(nIndex)
		if this:IsVisible() then
			this:Hide()
		end
		this:Show()
	elseif (event == "JZWLZD_OPEN_TEAMDETAIL") then
		WuLin_TeamDet_Init()
		WuLin_TeamDet_UpdateJZWLZDRankListTeamInfo(tonumber(arg0))
		if this:IsVisible() then
			this:Hide()
		end
		this:Show()
	elseif(event == "ADJEST_UI_POS") then
		WuLin_TeamDet_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_TeamDet_On_ResetPos()
	elseif event == "CLOSE_WULIN_TEAMDET" then
		WuLin_TeamDet_Close()
	end
end

function WuLin_TeamDet_On_ResetPos()
	WuLin_TeamDet_Frame:SetProperty("UnifiedPosition", g_WuLin_TeamDet_Frame_UnifiedPosition)
end

function WuLin_TeamDet_Init()
	for i = 1,6 do
		g_WuLin_TeamDet_Member[i].name:SetText("")
		g_WuLin_TeamDet_Member[i].menpai:SetText("")
		g_WuLin_TeamDet_Member[i].level:SetText("")
		g_WuLin_TeamDet_Member[i].score:SetText("")
	end
end

function WuLin_TeamDet_FillInfo(nIndex)
	for i = 1,6 do
		local bValid,name,menpai,level,score = DataPool:GetMLZDRankingListMemberInfo(nIndex,i-1);
		if bValid == 1 then
			g_WuLin_TeamDet_Member[i].name:SetText(name)
			g_WuLin_TeamDet_Member[i].menpai:SetText(GetMenpaiByID(menpai))
			g_WuLin_TeamDet_Member[i].level:SetText(level)
			g_WuLin_TeamDet_Member[i].score:SetText(score)
		end
	end
end


function WuLin_TeamDet_Close()
	this:Hide()
end

-- 决战武林之巅 决战武林之巅排行榜队伍详细信息
function WuLin_TeamDet_UpdateJZWLZDRankListTeamInfo(rank)
	local bossMenPai, useTime, memberCount, leaderName = JueZhanWuLinZhiDian:GetRankListInfo(rank)
	for i=1, memberCount, 1 do
		local menpai, level, score, head, name = JueZhanWuLinZhiDian:GetRankListMemberInfo(rank, i)
		g_WuLin_TeamDet_Member[i].name:SetText(name)
		g_WuLin_TeamDet_Member[i].menpai:SetText(GetMenpaiByID(menpai))
		g_WuLin_TeamDet_Member[i].level:SetText(level)
		g_WuLin_TeamDet_Member[i].score:SetText(score)
	end -- end for
end -- end func WuLin_TeamDet_UpdateJZWLZDRankListTeamInfo()