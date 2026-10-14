-- TianBoFu_TeamInfo

local g_TianBoFu_TeamInfo_Member = {}
local g_TianBoFu_TeamInfo_Pic = {}
local g_TianBoFu_TeamInfo_Name = {}
local g_TianBoFu_TeamInfo_Menpai = {}
local g_TianBoFu_TeamInfo_Level = {}
local g_TianBoFu_TeamInfo_Score = {}
local g_TianBoFu_TeamInfo_Frame_UnifiedPosition = nil 
local g_RankingList_Type = 1
local g_NpcId =-1;
local objCared = -1

function TianBoFu_TeamInfo_PreLoad()
	this:RegisterEvent("OPEN_TIANBOFU_RANKINGLIST_TEAM",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function TianBoFu_TeamInfo_OnLoad()
	for i = 1, 6 do 
		--g_TianBoFu_TeamInfo_Pic[i] = "TianBoFu_TeamInfo_Team1_List"..i.."_Pic"
		g_TianBoFu_TeamInfo_Name[i] = "TianBoFu_TeamInfo_Team1_List"..i.."_1"
		g_TianBoFu_TeamInfo_Menpai[i] = "TianBoFu_TeamInfo_Team1_List"..i.."_2"
		g_TianBoFu_TeamInfo_Level[i] = "TianBoFu_TeamInfo_Team1_List"..i.."_3"
		g_TianBoFu_TeamInfo_Score[i] = "TianBoFu_TeamInfo_Team1_List"..i.."_4"
	end

	for i = 7, 12 do
		local j = i-6
		--g_TianBoFu_TeamInfo_Pic[i] = "TianBoFu_TeamInfo_Team2_List"..j.."_Pic"
		g_TianBoFu_TeamInfo_Name[i] = "TianBoFu_TeamInfo_Team2_List"..j.."_1"
		g_TianBoFu_TeamInfo_Menpai[i] = "TianBoFu_TeamInfo_Team2_List"..j.."_2"
		g_TianBoFu_TeamInfo_Level[i] = "TianBoFu_TeamInfo_Team2_List"..j.."_3"
		g_TianBoFu_TeamInfo_Score[i] = "TianBoFu_TeamInfo_Team2_List"..j.."_4"
	end
	
	for i = 1, 12 do 
		g_TianBoFu_TeamInfo_Member[i] = {
			--pic = _G[g_TianBoFu_TeamInfo_Pic[i]],
			name = _G[g_TianBoFu_TeamInfo_Name[i]],
			menpai = _G[g_TianBoFu_TeamInfo_Menpai[i]],
			level = _G[g_TianBoFu_TeamInfo_Level[i]],
			score = _G[g_TianBoFu_TeamInfo_Score[i]],
		}
	end
	
	g_TianBoFu_TeamInfo_Frame_UnifiedPosition = TianBoFu_TeamInfo_Frame:GetProperty("UnifiedPosition")
end

function TianBoFu_TeamInfo_OnEvent(event)
	if( event == "OPEN_TIANBOFU_RANKINGLIST_TEAM") then
		local nIndex = tonumber(arg0)
		g_NpcId = tonumber(arg1);
		objCared = DataPool:GetNPCIDByServerID(g_NpcId);
		
		TianBoFu_TeamInfo_BeginCareObject(objCared)
		
		TianBoFu_TeamInfo_Init()
		TianBoFu_TeamInfo_FillInfo(nIndex)
		if this:IsVisible() then
			this:Hide()
		end
		this:Show()
	elseif(event == "ADJEST_UI_POS") then
		TianBoFu_TeamInfo_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		TianBoFu_TeamInfo_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		TianBoFu_TeamInfo_CloseClicked()	
	end
end

function TianBoFu_TeamInfo_On_ResetPos()
	TianBoFu_TeamInfo_Frame:SetProperty("UnifiedPosition", g_TianBoFu_TeamInfo_Frame_UnifiedPosition)
end

function TianBoFu_TeamInfo_Init()
	for i = 1,12 do
		--g_TianBoFu_TeamInfo_Member[i].pic:Hide()
		g_TianBoFu_TeamInfo_Member[i].name:SetText("")
		g_TianBoFu_TeamInfo_Member[i].menpai:SetText("")
		g_TianBoFu_TeamInfo_Member[i].level:SetText("")
		g_TianBoFu_TeamInfo_Member[i].score:SetText("")
	end
end

function TianBoFu_TeamInfo_FillInfo(nIndex)
	for i = 1,12 do
		local bValid,memguid,name,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_Type,nIndex,i-1);
	
		if bValid == 1 then
			--g_TianBoFu_TeamInfo_Member[i].pic:Show()
			g_TianBoFu_TeamInfo_Member[i].name:SetText(name)
			g_TianBoFu_TeamInfo_Member[i].menpai:SetText(GetMenpaiByID(menpai))
			g_TianBoFu_TeamInfo_Member[i].level:SetText(level)
			g_TianBoFu_TeamInfo_Member[i].score:SetText(score)
		end
	end
end

function TianBoFu_TeamInfo_CloseClicked()
	TianBoFu_TeamInfo_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function TianBoFu_TeamInfo_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "TianBoFu_TeamInfo");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "TianBoFu_TeamInfo")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function TianBoFu_TeamInfo_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "TianBoFu_TeamInfo");
		objCared = -1;
	end
end