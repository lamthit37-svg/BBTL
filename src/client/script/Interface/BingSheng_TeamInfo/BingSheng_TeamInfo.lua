-- BingSheng_TeamInfo

local g_BingSheng_TeamInfo_Member = {}
local g_BingSheng_TeamInfo_Pic = {}
local g_BingSheng_TeamInfo_Name = {}
local g_BingSheng_TeamInfo_Menpai = {}
local g_BingSheng_TeamInfo_Level = {}
local g_BingSheng_TeamInfo_Score = {}
local g_BingSheng_TeamInfo_Frame_UnifiedPosition = nil 
local g_RankingList_Type = 2
local g_NpcId =-1;
local objCared = -1

function BingSheng_TeamInfo_PreLoad()
	this:RegisterEvent("OPEN_BINGSHENG_RANKINGLIST_TEAM",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BingSheng_TeamInfo_OnLoad()
	for i = 1, 6 do
		--g_BingSheng_TeamInfo_Pic[i] = "BingSheng_TeamInfo_Team1_List"..i.."_Pic"
		g_BingSheng_TeamInfo_Name[i] = "BingSheng_TeamInfo_Team1_List"..i.."_1"
		g_BingSheng_TeamInfo_Menpai[i] = "BingSheng_TeamInfo_Team1_List"..i.."_2"
		g_BingSheng_TeamInfo_Level[i] = "BingSheng_TeamInfo_Team1_List"..i.."_3"
		g_BingSheng_TeamInfo_Score[i] = "BingSheng_TeamInfo_Team1_List"..i.."_4"
	end

	for i = 7, 12 do
		local j = i-6
		--g_BingSheng_TeamInfo_Pic[i] = "BingSheng_TeamInfo_Team2_List"..j.."_Pic"
		g_BingSheng_TeamInfo_Name[i] = "BingSheng_TeamInfo_Team2_List"..j.."_1"
		g_BingSheng_TeamInfo_Menpai[i] = "BingSheng_TeamInfo_Team2_List"..j.."_2"
		g_BingSheng_TeamInfo_Level[i] = "BingSheng_TeamInfo_Team2_List"..j.."_3"
		g_BingSheng_TeamInfo_Score[i] = "BingSheng_TeamInfo_Team2_List"..j.."_4"
	end
	
	for i = 1, 12 do 
		g_BingSheng_TeamInfo_Member[i] = {
			--pic = _G[g_BingSheng_TeamInfo_Pic[i]],
			name = _G[g_BingSheng_TeamInfo_Name[i]],
			menpai = _G[g_BingSheng_TeamInfo_Menpai[i]],
			level = _G[g_BingSheng_TeamInfo_Level[i]],
			score = _G[g_BingSheng_TeamInfo_Score[i]],
		}
	end
	
	g_BingSheng_TeamInfo_Frame_UnifiedPosition = BingSheng_TeamInfo_Frame:GetProperty("UnifiedPosition")
end

function BingSheng_TeamInfo_OnEvent(event)
	if( event == "OPEN_BINGSHENG_RANKINGLIST_TEAM") then
		local nIndex = tonumber(arg0)
		g_NpcId = tonumber(arg1);
		
		objCared = DataPool:GetNPCIDByServerID(g_NpcId);
		
		BingSheng_TeamInfo_BeginCareObject(objCared)
		
		BingSheng_TeamInfo_Init()
		BingSheng_TeamInfo_FillInfo(nIndex)
		if this:IsVisible() then
			this:Hide()
		end
		this:Show()
	elseif(event == "ADJEST_UI_POS") then
		BingSheng_TeamInfo_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		BingSheng_TeamInfo_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		BingSheng_TeamInfo_CloseClicked()
	end
end

function BingSheng_TeamInfo_On_ResetPos()
	BingSheng_TeamInfo_Frame:SetProperty("UnifiedPosition", g_BingSheng_TeamInfo_Frame_UnifiedPosition)
end

function BingSheng_TeamInfo_Init()
	for i = 1,12 do
		--g_BingSheng_TeamInfo_Member[i].pic:Hide()
		g_BingSheng_TeamInfo_Member[i].name:SetText("")
		g_BingSheng_TeamInfo_Member[i].menpai:SetText("")
		g_BingSheng_TeamInfo_Member[i].level:SetText("")
		g_BingSheng_TeamInfo_Member[i].score:SetText("")
	end
end

function BingSheng_TeamInfo_FillInfo(nIndex)
	for i = 1,12 do
		local bValid,memguid,name,menpai,level,score = DataPool:lua_GetJSRankingListMemberInfo(g_RankingList_Type,nIndex,i-1);

		if bValid == 1 then
			--g_BingSheng_TeamInfo_Member[i].pic:Show()
			g_BingSheng_TeamInfo_Member[i].name:SetText(name)
			g_BingSheng_TeamInfo_Member[i].menpai:SetText(GetMenpaiByID(menpai))
			g_BingSheng_TeamInfo_Member[i].level:SetText(level)
			g_BingSheng_TeamInfo_Member[i].score:SetText(score)
		end
	end
end

function BingSheng_TeamInfo_CloseClicked()
	BingSheng_TeamInfo_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function BingSheng_TeamInfo_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "BingSheng_TeamInfo");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "BingSheng_TeamInfo")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function BingSheng_TeamInfo_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "BingSheng_TeamInfo");
		objCared = -1;
	end
end