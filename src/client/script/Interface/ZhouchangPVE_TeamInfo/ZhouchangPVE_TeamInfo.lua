-- ZhouchangPVE_TeamInfo

local g_ZhouchangPVE_TeamInfo_Member = {}
local g_ZhouchangPVE_TeamInfo_Pic = {}
local g_ZhouchangPVE_TeamInfo_Name = {}
local g_ZhouchangPVE_TeamInfo_Menpai = {}
local g_ZhouchangPVE_TeamInfo_Level = {}
local g_ZhouchangPVE_TeamInfo_Score = {}
local g_ZhouchangPVE_TeamInfo_Frame_UnifiedPosition = nil 
local g_RankingList_Type = -1
local g_NpcId =-1
local objCared = -1

function ZhouchangPVE_TeamInfo_PreLoad()
	this:RegisterEvent("OPEN_FHLM_RANKINGLIST_TEAM", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function ZhouchangPVE_TeamInfo_OnLoad()
	for i = 1, 6 do 
		--g_ZhouchangPVE_TeamInfo_Pic[i] = "ZhouchangPVE_TeamInfo_Team_List"..i.."_Pic"
		g_ZhouchangPVE_TeamInfo_Name[i] = "ZhouchangPVE_TeamInfo_Team_List"..i.."_1"
		g_ZhouchangPVE_TeamInfo_Menpai[i] = "ZhouchangPVE_TeamInfo_Team_List"..i.."_2"
		g_ZhouchangPVE_TeamInfo_Level[i] = "ZhouchangPVE_TeamInfo_Team_List"..i.."_3"
		g_ZhouchangPVE_TeamInfo_Score[i] = "ZhouchangPVE_TeamInfo_Team_List"..i.."_4"
	end

	for i = 1, 6 do 
		g_ZhouchangPVE_TeamInfo_Member[i] = {
			--pic = _G[g_ZhouchangPVE_TeamInfo_Pic[i]],
			name = _G[g_ZhouchangPVE_TeamInfo_Name[i]],
			menpai = _G[g_ZhouchangPVE_TeamInfo_Menpai[i]],
			level = _G[g_ZhouchangPVE_TeamInfo_Level[i]],
			score = _G[g_ZhouchangPVE_TeamInfo_Score[i]],
		}
	end
	
	g_ZhouchangPVE_TeamInfo_Frame_UnifiedPosition = ZhouchangPVE_TeamInfo_Frame:GetProperty("UnifiedPosition")
end

function ZhouchangPVE_TeamInfo_OnEvent(event)
	if( event == "OPEN_FHLM_RANKINGLIST_TEAM" ) then
		local nIndex = tonumber(arg0)
		g_NpcId = tonumber(arg1)
		g_RankingList_Type = tonumber(arg2)
		
		objCared = DataPool:GetNPCIDByServerID(g_NpcId)
		ZhouchangPVE_TeamInfo_BeginCareObject(objCared)
		ZhouchangPVE_TeamInfo_Init()
		ZhouchangPVE_TeamInfo_FillInfo(nIndex)
		if this:IsVisible() then
			this:Hide()
		end
		this:Show()
	elseif(event == "ADJEST_UI_POS") then
		ZhouchangPVE_TeamInfo_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		ZhouchangPVE_TeamInfo_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		ZhouchangPVE_TeamInfo_CloseClicked()	
	end
end

function ZhouchangPVE_TeamInfo_On_ResetPos()
	ZhouchangPVE_TeamInfo_Frame:SetProperty("UnifiedPosition", g_ZhouchangPVE_TeamInfo_Frame_UnifiedPosition)
end

function ZhouchangPVE_TeamInfo_Init()
	for i = 1, 6 do
		--g_ZhouchangPVE_TeamInfo_Member[i].pic:Hide()
		g_ZhouchangPVE_TeamInfo_Member[i].name:SetText("")
		g_ZhouchangPVE_TeamInfo_Member[i].menpai:SetText("")
		g_ZhouchangPVE_TeamInfo_Member[i].level:SetText("")
		g_ZhouchangPVE_TeamInfo_Member[i].score:SetText("")
	end
end

function ZhouchangPVE_TeamInfo_FillInfo(nIndex)
	for i = 1, 6 do
		local bValid,memguid,name,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_Type,nIndex,i-1)
	
		if bValid == 1 then
			--g_ZhouchangPVE_TeamInfo_Member[i].pic:Show()
			g_ZhouchangPVE_TeamInfo_Member[i].name:SetText(name)
			g_ZhouchangPVE_TeamInfo_Member[i].menpai:SetText(GetMenpaiByID(menpai))
			g_ZhouchangPVE_TeamInfo_Member[i].level:SetText(level)
			g_ZhouchangPVE_TeamInfo_Member[i].score:SetText(score)
		end
	end
end

function ZhouchangPVE_TeamInfo_CloseClicked()
	ZhouchangPVE_TeamInfo_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function ZhouchangPVE_TeamInfo_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "ZhouchangPVE_TeamInfo")
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "ZhouchangPVE_TeamInfo")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ZhouchangPVE_TeamInfo_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "ZhouchangPVE_TeamInfo")
		objCared = -1
	end
end